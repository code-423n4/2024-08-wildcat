// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './WildcatMarketBase.sol';
import '../libraries/LibERC20.sol';
import '../libraries/BoolUtils.sol';

contract WildcatMarketWithdrawals is WildcatMarketBase {
  using LibERC20 for address;
  using MathUtils for uint256;
  using MathUtils for bool;
  using SafeCastLib for uint256;
  using BoolUtils for bool;

  // ========================================================================== //
  //                             Withdrawal Queries                             //
  // ========================================================================== //

  /**
   * @dev Returns the expiry timestamp of every unpaid withdrawal batch.
   */
  function getUnpaidBatchExpiries() external view nonReentrantView returns (uint32[] memory) {
    return _withdrawalData.unpaidBatches.values();
  }

  function getWithdrawalBatch(
    uint32 expiry
  ) external view nonReentrantView returns (WithdrawalBatch memory batch) {
    (, uint32 pendingBatchExpiry, WithdrawalBatch memory pendingBatch) = _calculateCurrentState();
    if ((expiry == pendingBatchExpiry).and(expiry > 0)) {
      return pendingBatch;
    }

    WithdrawalBatch storage _batch = _withdrawalData.batches[expiry];
    batch.scaledTotalAmount = _batch.scaledTotalAmount;
    batch.scaledAmountBurned = _batch.scaledAmountBurned;
    batch.normalizedAmountPaid = _batch.normalizedAmountPaid;
  }

  function getAccountWithdrawalStatus(
    address accountAddress,
    uint32 expiry
  ) external view nonReentrantView returns (AccountWithdrawalStatus memory status) {
    AccountWithdrawalStatus storage _status = _withdrawalData.accountStatuses[expiry][
      accountAddress
    ];
    status.scaledAmount = _status.scaledAmount;
    status.normalizedAmountWithdrawn = _status.normalizedAmountWithdrawn;
  }

  function getAvailableWithdrawalAmount(
    address accountAddress,
    uint32 expiry
  ) external view nonReentrantView returns (uint256) {
    if (expiry >= block.timestamp) {
      revert_WithdrawalBatchNotExpired();
    }
    (, uint32 pendingBatchExpiry, WithdrawalBatch memory pendingBatch) = _calculateCurrentState();
    WithdrawalBatch memory batch;
    if (expiry == pendingBatchExpiry) {
      batch = pendingBatch;
    } else {
      batch = _withdrawalData.batches[expiry];
    }
    AccountWithdrawalStatus memory status = _withdrawalData.accountStatuses[expiry][accountAddress];
    // Rounding errors will lead to some dust accumulating in the batch, but the cost of
    // executing a withdrawal will be lower for users.
    uint256 previousTotalWithdrawn = status.normalizedAmountWithdrawn;
    uint256 newTotalWithdrawn = uint256(batch.normalizedAmountPaid).mulDiv(
      status.scaledAmount,
      batch.scaledTotalAmount
    );
    return newTotalWithdrawn - previousTotalWithdrawn;
  }

  // ========================================================================== //
  //                             Withdrawal Actions                             //
  // ========================================================================== //

  function _queueWithdrawal(
    MarketState memory state,
    Account memory account,
    address accountAddress,
    uint104 scaledAmount,
    uint normalizedAmount,
    uint baseCalldataSize
  ) internal returns (uint32 expiry) {

    // Cache batch expiry on the stack for gas savings
    expiry = state.pendingWithdrawalExpiry;

    // If there is no pending withdrawal batch, create a new one.
    if (state.pendingWithdrawalExpiry == 0) {
      // If the market is closed, use zero for withdrawal batch duration.
      uint duration = state.isClosed.ternary(0, withdrawalBatchDuration);
      expiry = uint32(block.timestamp + duration);
      emit_WithdrawalBatchCreated(expiry);
      state.pendingWithdrawalExpiry = expiry;
    }

    // Execute queueWithdrawal hook if enabled
    hooks.onQueueWithdrawal(accountAddress, expiry, scaledAmount, state, baseCalldataSize);

    // Reduce account's balance and emit transfer event
    account.scaledBalance -= scaledAmount;
    _accounts[accountAddress] = account;

    emit_Transfer(accountAddress, address(this), normalizedAmount);

    WithdrawalBatch memory batch = _withdrawalData.batches[expiry];

    // Add scaled withdrawal amount to account withdrawal status, withdrawal batch and market state.
    _withdrawalData.accountStatuses[expiry][accountAddress].scaledAmount += scaledAmount;
    batch.scaledTotalAmount += scaledAmount;
    state.scaledPendingWithdrawals += scaledAmount;

    emit_WithdrawalQueued(expiry, accountAddress, scaledAmount, normalizedAmount);

    // Burn as much of the withdrawal batch as possible with available liquidity.
    uint256 availableLiquidity = batch.availableLiquidityForPendingBatch(state, totalAssets());
    if (availableLiquidity > 0) {
      _applyWithdrawalBatchPayment(batch, state, expiry, availableLiquidity);
    }

    // Update stored batch data
    _withdrawalData.batches[expiry] = batch;

    // Update stored state
    _writeState(state);
  }

  /**
   * @dev Create a withdrawal request for a lender.
   */
  function queueWithdrawal(
    uint256 amount
  ) external nonReentrant sphereXGuardExternal returns (uint32 expiry) {
    MarketState memory state = _getUpdatedState();

    uint104 scaledAmount = state.scaleAmount(amount).toUint104();
    if (scaledAmount == 0) revert_NullBurnAmount();

    // Cache account data
    Account memory account = _getAccount(msg.sender);

    return
      _queueWithdrawal(state, account, msg.sender, scaledAmount, amount, _runtimeConstant(0x24));
  }

  /**
   * @dev Queue a withdrawal for all of the caller's balance.
   */
  function queueFullWithdrawal()
    external
    nonReentrant
    sphereXGuardExternal
    returns (uint32 expiry)
  {
    MarketState memory state = _getUpdatedState();

    // Cache account data
    Account memory account = _getAccount(msg.sender);

    uint104 scaledAmount = account.scaledBalance;
    if (scaledAmount == 0) revert_NullBurnAmount();

    uint256 normalizedAmount = state.normalizeAmount(scaledAmount);

    return
      _queueWithdrawal(
        state,
        account,
        msg.sender,
        scaledAmount,
        normalizedAmount,
        _runtimeConstant(0x04)
      );
  }

  /**
   * @dev Execute a pending withdrawal request for a batch that has expired.
   *
   *      Withdraws the proportional amount of the paid batch owed to
   *      `accountAddress` which has not already been withdrawn.
   *
   *      If `accountAddress` is sanctioned, transfers the owed amount to
   *      an escrow contract specific to the account and blocks the account.
   *
   *      Reverts if:
   *      - `expiry >= block.timestamp`
   *      -  `expiry` does not correspond to an existing withdrawal batch
   *      - `accountAddress` has already withdrawn the full amount owed
   */
  function executeWithdrawal(
    address accountAddress,
    uint32 expiry
  ) public nonReentrant sphereXGuardExternal returns (uint256) {
    MarketState memory state = _getUpdatedState();
    // Use an obfuscated constant for the base calldata size to prevent solc
    // function specialization.
    uint256 normalizedAmountWithdrawn = _executeWithdrawal(
      state,
      accountAddress,
      expiry,
      _runtimeConstant(0x44)
    );
    // Update stored state
    _writeState(state);
    return normalizedAmountWithdrawn;
  }

  function executeWithdrawals(
    address[] calldata accountAddresses,
    uint32[] calldata expiries
  ) external nonReentrant sphereXGuardExternal returns (uint256[] memory amounts) {
    if (accountAddresses.length != expiries.length) revert_InvalidArrayLength();

    amounts = new uint256[](accountAddresses.length);

    MarketState memory state = _getUpdatedState();

    for (uint256 i = 0; i < accountAddresses.length; i++) {
      // Use calldatasize() for baseCalldataSize to indicate no data should be passed as `extraData`
      amounts[i] = _executeWithdrawal(state, accountAddresses[i], expiries[i], msg.data.length);
    }
    // Update stored state
    _writeState(state);
    return amounts;
  }

  function _executeWithdrawal(
    MarketState memory state,
    address accountAddress,
    uint32 expiry,
    uint baseCalldataSize
  ) internal returns (uint256) {
    WithdrawalBatch memory batch = _withdrawalData.batches[expiry];
    // If the market is closed, allow withdrawal prior to expiry.
    if (expiry >= block.timestamp && !state.isClosed) {
      revert_WithdrawalBatchNotExpired();
    }

    AccountWithdrawalStatus storage status = _withdrawalData.accountStatuses[expiry][
      accountAddress
    ];

    uint128 newTotalWithdrawn = uint128(
      MathUtils.mulDiv(batch.normalizedAmountPaid, status.scaledAmount, batch.scaledTotalAmount)
    );

    uint128 normalizedAmountWithdrawn = newTotalWithdrawn - status.normalizedAmountWithdrawn;

    if (normalizedAmountWithdrawn == 0) revert_NullWithdrawalAmount();

    hooks.onExecuteWithdrawal(accountAddress, normalizedAmountWithdrawn, state, baseCalldataSize);

    status.normalizedAmountWithdrawn = newTotalWithdrawn;
    state.normalizedUnclaimedWithdrawals -= normalizedAmountWithdrawn;

    if (_isSanctioned(accountAddress)) {
      // Get or create an escrow contract for the lender and transfer the owed amount to it.
      // They will be unable to withdraw from the escrow until their sanctioned
      // status is lifted on Chainalysis, or until the borrower overrides it.
      address escrow = _createEscrowForUnderlyingAsset(accountAddress);
      asset.safeTransfer(escrow, normalizedAmountWithdrawn);

      // Emit `SanctionedAccountWithdrawalSentToEscrow` event using a custom emitter.
      emit_SanctionedAccountWithdrawalSentToEscrow(
        accountAddress,
        escrow,
        expiry,
        normalizedAmountWithdrawn
      );
    } else {
      asset.safeTransfer(accountAddress, normalizedAmountWithdrawn);
    }

    emit_WithdrawalExecuted(expiry, accountAddress, normalizedAmountWithdrawn);

    return normalizedAmountWithdrawn;
  }

  function repayAndProcessUnpaidWithdrawalBatches(
    uint256 repayAmount,
    uint256 maxBatches
  ) public nonReentrant sphereXGuardExternal {
    // Repay before updating state to ensure the paid amount is counted towards
    // any pending or unpaid withdrawals.
    if (repayAmount > 0) {
      asset.safeTransferFrom(msg.sender, address(this), repayAmount);
      emit_DebtRepaid(msg.sender, repayAmount);
    }

    MarketState memory state = _getUpdatedState();
    if (state.isClosed) revert_RepayToClosedMarket();

    // Use an obfuscated constant for the base calldata size to prevent solc
    // function specialization.
    if (repayAmount > 0) hooks.onRepay(repayAmount, state, _runtimeConstant(0x44));

    // Calculate assets available to process the first batch - will be updated after each batch
    uint256 availableLiquidity = totalAssets() -
      (state.normalizedUnclaimedWithdrawals + state.accruedProtocolFees);

    // Get the maximum number of batches to process
    uint256 numBatches = MathUtils.min(maxBatches, _withdrawalData.unpaidBatches.length());

    uint256 i;
    // Process up to `maxBatches` unpaid batches while there is available liquidity
    while (i++ < numBatches && availableLiquidity > 0) {
      // Process the next unpaid batch using available liquidity
      uint256 normalizedAmountPaid = _processUnpaidWithdrawalBatch(state, availableLiquidity);
      // Reduce liquidity available to next batch
      availableLiquidity = availableLiquidity.satSub(normalizedAmountPaid);
    }
    _writeState(state);
  }

  function _processUnpaidWithdrawalBatch(
    MarketState memory state,
    uint256 availableLiquidity
  ) internal returns (uint256 normalizedAmountPaid) {
    // Get the next unpaid batch timestamp from storage (reverts if none)
    uint32 expiry = _withdrawalData.unpaidBatches.first();

    // Cache batch data in memory
    WithdrawalBatch memory batch = _withdrawalData.batches[expiry];

    // Pay up to the available liquidity to the batch
    (, normalizedAmountPaid) = _applyWithdrawalBatchPayment(
      batch,
      state,
      expiry,
      availableLiquidity
    );

    // Update stored batch
    _withdrawalData.batches[expiry] = batch;

    // Remove batch from unpaid set if fully paid
    if (batch.scaledTotalAmount == batch.scaledAmountBurned) {
      _withdrawalData.unpaidBatches.shift();
      emit_WithdrawalBatchClosed(expiry);
    }
  }
}
