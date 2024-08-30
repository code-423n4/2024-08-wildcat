// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './WildcatMarketBase.sol';
import './WildcatMarketConfig.sol';
import './WildcatMarketToken.sol';
import './WildcatMarketWithdrawals.sol';
import '../WildcatSanctionsSentinel.sol';

contract WildcatMarket is
  WildcatMarketBase,
  WildcatMarketConfig,
  WildcatMarketToken,
  WildcatMarketWithdrawals
{
  using MathUtils for uint256;
  using SafeCastLib for uint256;
  using LibERC20 for address;
  using BoolUtils for bool;

  /**
   * @dev Apply pending interest, delinquency fees and protocol fees
   *      to the state and process the pending withdrawal batch if
   *      one exists and has expired, then update the market's
   *      delinquency status.
   */
  function updateState() external nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();
    _writeState(state);
  }

  /**
   * @dev Token rescue function for recovering tokens sent to the market
   *      contract by mistake or otherwise outside of the normal course of
   *      operation.
   */
  function rescueTokens(address token) external onlyBorrower {
    if ((token == asset).or(token == address(this))) {
      revert_BadRescueAsset();
    }
    token.safeTransferAll(msg.sender);
  }

  /**
   * @dev Deposit up to `amount` underlying assets and mint market tokens
   *      for `msg.sender`.
   *
   *      The actual deposit amount is limited by the market's maximum deposit
   *      amount, which is the configured `maxTotalSupply` minus the current
   *      total supply.
   *
   *      Reverts if the market is closed or if the scaled token amount
   *      that would be minted for the deposit is zero.
   */
  function _depositUpTo(
    uint256 amount
  ) internal virtual nonReentrant returns (uint256 /* actualAmount */) {
    // Get current state
    MarketState memory state = _getUpdatedState();

    if (state.isClosed) revert_DepositToClosedMarket();

    // Reduce amount if it would exceed totalSupply
    amount = MathUtils.min(amount, state.maximumDeposit());

    // Scale the mint amount
    uint104 scaledAmount = state.scaleAmount(amount).toUint104();
    if (scaledAmount == 0) revert_NullMintAmount();

    // Cache account data and revert if not authorized to deposit.
    Account memory account = _getAccount(msg.sender);

    hooks.onDeposit(msg.sender, scaledAmount, state);

    // Transfer deposit from caller
    asset.safeTransferFrom(msg.sender, address(this), amount);

    account.scaledBalance += scaledAmount;
    _accounts[msg.sender] = account;

    emit_Transfer(_runtimeConstant(address(0)), msg.sender, amount);
    emit_Deposit(msg.sender, amount, scaledAmount);

    // Increase supply
    state.scaledTotalSupply += scaledAmount;

    // Update stored state
    _writeState(state);

    return amount;
  }

  /**
   * @dev Deposit up to `amount` underlying assets and mint market tokens
   *      for `msg.sender`.
   *
   *      The actual deposit amount is limited by the market's maximum deposit
   *      amount, which is the configured `maxTotalSupply` minus the current
   *      total supply.
   *
   *      Reverts if the market is closed or if the scaled token amount
   *      that would be minted for the deposit is zero.
   */
  function depositUpTo(
    uint256 amount
  ) external virtual sphereXGuardExternal returns (uint256 /* actualAmount */) {
    return _depositUpTo(amount);
  }

  /**
   * @dev Deposit exactly `amount` underlying assets and mint market tokens
   *      for `msg.sender`.
   *
   *     Reverts if the deposit amount would cause the market to exceed the
   *     configured `maxTotalSupply`.
   */
  function deposit(uint256 amount) external virtual sphereXGuardExternal {
    uint256 actualAmount = _depositUpTo(amount);
    if (amount != actualAmount) revert_MaxSupplyExceeded();
  }

  /**
   * @dev Withdraw available protocol fees to the fee recipient.
   */
  function collectFees() external nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();
    if (state.accruedProtocolFees == 0) revert_NullFeeAmount();

    uint128 withdrawableFees = state.withdrawableProtocolFees(totalAssets());
    if (withdrawableFees == 0) revert_InsufficientReservesForFeeWithdrawal();

    state.accruedProtocolFees -= withdrawableFees;
    asset.safeTransfer(feeRecipient, withdrawableFees);
    _writeState(state);
    emit_FeesCollected(withdrawableFees);
  }

  /**
   * @dev Withdraw funds from the market to the borrower.
   *
   *      Can only withdraw up to the assets that are not required
   *      to meet the borrower's collateral obligations.
   *
   *      Reverts if the market is closed.
   */
  function borrow(uint256 amount) external onlyBorrower nonReentrant sphereXGuardExternal {
    // Check if the borrower is flagged as a sanctioned entity on Chainalysis.
    // Uses `isFlaggedByChainalysis` instead of `isSanctioned` to prevent the borrower
    // overriding their sanction status.
    if (_isFlaggedByChainalysis(borrower)) {
      revert_BorrowWhileSanctioned();
    }

    MarketState memory state = _getUpdatedState();
    if (state.isClosed) revert_BorrowFromClosedMarket();

    uint256 borrowable = state.borrowableAssets(totalAssets());
    if (amount > borrowable) revert_BorrowAmountTooHigh();

    // Execute borrow hook if enabled
    hooks.onBorrow(amount, state);

    asset.safeTransfer(msg.sender, amount);
    _writeState(state);
    emit_Borrow(amount);
  }

  function _repay(MarketState memory state, uint256 amount, uint256 baseCalldataSize) internal {
    if (amount == 0) revert_NullRepayAmount();
    if (state.isClosed) revert_RepayToClosedMarket();

    asset.safeTransferFrom(msg.sender, address(this), amount);
    emit_DebtRepaid(msg.sender, amount);

    // Execute repay hook if enabled
    hooks.onRepay(amount, state, baseCalldataSize);
  }

  function repayOutstandingDebt() external nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();
    uint256 outstandingDebt = state.totalDebts().satSub(totalAssets());
    _repay(state, outstandingDebt, 0x04);
    _writeState(state);
  }

  function repayDelinquentDebt() external nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();
    uint256 delinquentDebt = state.liquidityRequired().satSub(totalAssets());
    _repay(state, delinquentDebt, 0x04);
    _writeState(state);
  }

  /**
   * @dev Transfers funds from the caller to the market.
   *
   *      Any payments made through this function are considered
   *      repayments from the borrower. Do *not* use this function
   *      if you are a lender or an unrelated third party.
   *
   *      Reverts if the market is closed or `amount` is 0.
   */
  function repay(uint256 amount) external nonReentrant sphereXGuardExternal {
    if (amount == 0) revert_NullRepayAmount();

    asset.safeTransferFrom(msg.sender, address(this), amount);
    emit_DebtRepaid(msg.sender, amount);

    MarketState memory state = _getUpdatedState();
    if (state.isClosed) revert_RepayToClosedMarket();

    // Execute repay hook if enabled
    hooks.onRepay(amount, state, _runtimeConstant(0x24));

    _writeState(state);
  }

  /**
   * @dev Sets the market APR to 0% and marks market as closed.
   *
   *      Can not be called if there are any unpaid withdrawal batches.
   *
   *      Transfers remaining debts from borrower if market is not fully
   *      collateralized; otherwise, transfers any assets in excess of
   *      debts to the borrower.
   */
  function closeMarket() external onlyBorrower nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();

    if (state.isClosed) revert_MarketAlreadyClosed();

    uint256 currentlyHeld = totalAssets();
    uint256 totalDebts = state.totalDebts();
    if (currentlyHeld < totalDebts) {
      // Transfer remaining debts from borrower
      uint256 remainingDebt = totalDebts - currentlyHeld;
      _repay(state, remainingDebt, 0x04);
      currentlyHeld += remainingDebt;
    } else if (currentlyHeld > totalDebts) {
      uint256 excessDebt = currentlyHeld - totalDebts;
      // Transfer excess assets to borrower
      asset.safeTransfer(borrower, excessDebt);
      currentlyHeld -= excessDebt;
    }
    hooks.onCloseMarket(state);
    state.annualInterestBips = 0;
    state.isClosed = true;
    state.reserveRatioBips = 10000;
    // Ensures that delinquency fee doesn't increase scale factor further
    // as doing so would mean last lender in market couldn't fully redeem
    state.timeDelinquent = 0;

    // Still track available liquidity in case of a rounding error
    uint256 availableLiquidity = currentlyHeld -
      (state.normalizedUnclaimedWithdrawals + state.accruedProtocolFees);

    // If there is a pending withdrawal batch which is not fully paid off, set aside
    // up to the available liquidity for that batch.
    if (state.pendingWithdrawalExpiry != 0) {
      uint32 expiry = state.pendingWithdrawalExpiry;
      WithdrawalBatch memory batch = _withdrawalData.batches[expiry];
      if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
        (, uint128 normalizedAmountPaid) = _applyWithdrawalBatchPayment(
          batch,
          state,
          expiry,
          availableLiquidity
        );
        availableLiquidity -= normalizedAmountPaid;
        _withdrawalData.batches[expiry] = batch;
      }
    }

    uint256 numBatches = _withdrawalData.unpaidBatches.length();
    for (uint256 i; i < numBatches; i++) {
      // Process the next unpaid batch using available liquidity
      uint256 normalizedAmountPaid = _processUnpaidWithdrawalBatch(state, availableLiquidity);
      // Reduce liquidity available to next batch
      availableLiquidity -= normalizedAmountPaid;
    }

    if (state.scaledPendingWithdrawals != 0) {
      revert_CloseMarketWithUnpaidWithdrawals();
    }

    _writeState(state);
    emit_MarketClosed(block.timestamp);
  }

  /**
   * @dev Queues a full withdrawal of a sanctioned account's assets.
   */
  function _blockAccount(MarketState memory state, address accountAddress) internal override {
    Account memory account = _accounts[accountAddress];
    if (account.scaledBalance > 0) {
      uint104 scaledAmount = account.scaledBalance;

      uint256 normalizedAmount = state.normalizeAmount(scaledAmount);

      uint32 expiry = _queueWithdrawal(
        state,
        account,
        accountAddress,
        scaledAmount,
        normalizedAmount,
        msg.data.length
      );

      emit_SanctionedAccountAssetsQueuedForWithdrawal(
        accountAddress,
        expiry,
        scaledAmount,
        normalizedAmount
      );
    }
  }
}
