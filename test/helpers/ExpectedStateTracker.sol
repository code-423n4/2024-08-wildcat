// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;
import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import 'src/market/WildcatMarket.sol';
import 'src/WildcatSanctionsEscrow.sol';
import '../shared/TestConstants.sol';
import './Assertions.sol';
import '../shared/Test.sol';
import { Account as MarketAccount } from 'src/libraries/MarketState.sol';

contract ExpectedStateTracker is Test, IMarketEventsAndErrors {
  using FeeMath for MarketState;
  using SafeCastLib for uint256;
  using MathUtils for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  bytes32 public constant WildcatSanctionsEscrowInitcodeHash =
    keccak256(type(WildcatSanctionsEscrow).creationCode);

  MarketInputParameters internal parameters;

  MarketState internal previousState;
  WithdrawalData internal _withdrawalData;
  uint256 internal lastTotalAssets;
  EnumerableSet.AddressSet internal touchedAccounts;
  EnumerableSet.UintSet internal touchedBatches;
  mapping(uint32 => EnumerableSet.AddressSet) internal touchedAccountsByBatch;

  mapping(address => MarketAccount) private accounts;

  constructor() Test() {
    parameters = MarketInputParameters({
      asset: address(0),
      namePrefix: 'Wildcat ',
      symbolPrefix: 'WC',
      borrower: borrower,
      feeRecipient: feeRecipient,
      sentinel: address(sanctionsSentinel),
      maxTotalSupply: uint128(DefaultMaximumSupply),
      protocolFeeBips: DefaultProtocolFeeBips,
      annualInterestBips: DefaultInterest,
      delinquencyFeeBips: DefaultDelinquencyFee,
      withdrawalBatchDuration: DefaultWithdrawalBatchDuration,
      reserveRatioBips: DefaultReserveRatio,
      delinquencyGracePeriod: DefaultGracePeriod,
      hooksTemplate: hooksTemplate,
      deployHooksConstructorArgs: '',
      deployMarketHooksData: '',
      hooksConfig: HooksConfig.wrap(0),
      sphereXEngine: address(0),
      minimumDeposit: 0
    });
  }

  function calculateEscrowAddress(
    address accountAddress,
    address asset
  ) internal view returns (address) {
    return
      address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                parameters.sentinel,
                keccak256(abi.encode(parameters.borrower, accountAddress, asset)),
                WildcatSanctionsEscrowInitcodeHash
              )
            )
          )
        )
      );
  }

  function pendingState() internal returns (MarketState memory state) {
    return pendingState(false);
  }

  function pendingState(bool expectEvents) internal returns (MarketState memory state) {
    state = previousState;
    if (block.timestamp > state.pendingWithdrawalExpiry && state.pendingWithdrawalExpiry != 0) {
      uint256 expiry = state.pendingWithdrawalExpiry;
      if (expiry != state.lastInterestAccruedTimestamp) {
        uint prevTimestamp = state.lastInterestAccruedTimestamp;
        (uint256 baseInterestRay, uint256 delinquencyFeeRay, uint256 protocolFee) = state
          .updateScaleFactorAndFees(
            parameters.delinquencyFeeBips,
            parameters.delinquencyGracePeriod,
            expiry
          );
        if (expectEvents) {
          vm.expectEmit(address(market));
          emit InterestAndFeesAccrued(
            prevTimestamp,
            expiry,
            state.scaleFactor,
            baseInterestRay,
            delinquencyFeeRay,
            protocolFee
          );
        }
      }
      _processExpiredWithdrawalBatch(state, expectEvents);
    }
    uint timestamp = block.timestamp;

    if (block.timestamp != state.lastInterestAccruedTimestamp) {
      uint prevTimestamp = state.lastInterestAccruedTimestamp;
      (uint256 baseInterestRay, uint256 delinquencyFeeRay, uint256 protocolFee) = state
        .updateScaleFactorAndFees(
          parameters.delinquencyFeeBips,
          parameters.delinquencyGracePeriod,
          timestamp
        );
      if (expectEvents) {
        vm.expectEmit(address(market));
        emit InterestAndFeesAccrued(
          prevTimestamp,
          block.timestamp,
          state.scaleFactor,
          baseInterestRay,
          delinquencyFeeRay,
          protocolFee
        );
      }
    }
    if (state.pendingWithdrawalExpiry != 0) {
      uint32 pendingBatchExpiry = state.pendingWithdrawalExpiry;
      WithdrawalBatch storage pendingBatch = _withdrawalData.batches[pendingBatchExpiry];
      if (pendingBatch.scaledAmountBurned < pendingBatch.scaledTotalAmount) {
        // Burn as much of the withdrawal batch as possible with available liquidity.
        uint256 availableLiquidity = pendingBatch.availableLiquidityForPendingBatch(
          state,
          lastTotalAssets
        );
        if (availableLiquidity > 0) {
          _applyWithdrawalBatchPayment(
            pendingBatch,
            state,
            pendingBatchExpiry,
            availableLiquidity,
            expectEvents
          );
        }
      }
    }
  }

  function updateState(MarketState memory state) internal {
    state.isDelinquent = state.liquidityRequired() > lastTotalAssets;
    previousState = state;
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Checks                                   */
  /* -------------------------------------------------------------------------- */

  function _checkAccount(MarketState memory state, address accountAddress) internal {
    (uint104 scaledBalance, uint256 normalizedBalance) = _getBalance(state, accountAddress);
    assertEq(market.scaledBalanceOf(accountAddress), scaledBalance, 'scaledBalance');
    assertEq(market.balanceOf(accountAddress), normalizedBalance, 'normalizedBalance');
  }

  function _checkWithdrawalBatch(uint32 expiry) internal {
    WithdrawalBatch storage expectedBatch = _getWithdrawalBatch(expiry);
    WithdrawalBatch memory actualBatch = market.getWithdrawalBatch(expiry);
    string memory key = string.concat('Batch ', LibString.toString(expiry), ': ');
    assertEq(
      actualBatch.scaledTotalAmount,
      expectedBatch.scaledTotalAmount,
      string.concat(key, 'scaledTotalAmount')
    );
    assertEq(
      actualBatch.scaledAmountBurned,
      expectedBatch.scaledAmountBurned,
      string.concat(key, 'scaledAmountBurned')
    );
    assertEq(
      actualBatch.normalizedAmountPaid,
      expectedBatch.normalizedAmountPaid,
      string.concat(key, 'normalizedAmountPaid')
    );
  }

  function _checkWithdrawalStatus(uint32 expiry, address accountAddress) internal {
    AccountWithdrawalStatus storage expectedStatus = _getWithdrawalStatus(expiry, accountAddress);
    AccountWithdrawalStatus memory actualStatus = market.getAccountWithdrawalStatus(
      accountAddress,
      expiry
    );
    assertEq(actualStatus.scaledAmount, expectedStatus.scaledAmount, 'scaledAmount');
    assertEq(
      actualStatus.normalizedAmountWithdrawn,
      expectedStatus.normalizedAmountWithdrawn,
      'normalizedAmountWithdrawn'
    );
  }

  function _checkState(string memory key) internal {
    assertEq(market.previousState(), previousState, string.concat(key, 'previousState'));
    uint snapshotId = vm.snapshot();
    this.checkCurrentState(string.concat(key, 'state.'));
    vm.revertTo(snapshotId);
  }

  function checkCurrentState(string memory key) external {
    MarketState memory state = pendingState();
    updateState(state);
    assertEq(market.currentState(), state, string.concat(key, 'currentState'));
    assertEq(market.totalAssets(), lastTotalAssets, string.concat(key, 'totalAssets'));

    address[] memory accountsTouched = touchedAccounts.values();
    for (uint256 i = 0; i < accountsTouched.length; i++) {
      _checkAccount(state, accountsTouched[i]);
    }
    uint256[] memory batchesTouched = touchedBatches.values();
    for (uint256 i = 0; i < batchesTouched.length; i++) {
      uint32 expiry = uint32(batchesTouched[i]);
      _checkWithdrawalBatch(expiry);
      address[] memory accountsTouchedByBatch = touchedAccountsByBatch[expiry].values();
      for (uint256 j = 0; j < accountsTouchedByBatch.length; j++) {
        _checkWithdrawalStatus(expiry, accountsTouchedByBatch[j]);
      }
    }
    uint32[] memory unpaidBatches = _withdrawalData.unpaidBatches.values();
    assertEq(market.getUnpaidBatchExpiries(), unpaidBatches, string.concat(key, 'unpaidBatches'));
  }

  function _checkState(MarketState memory state) internal {
    assertEq(market.previousState(), previousState, 'previousState');
    updateState(state);

    uint snapshotId = vm.snapshot();
    this.checkCurrentState('state.');
    vm.revertTo(snapshotId);
  }

  function _checkState() internal {
    _checkState('');
  }

  /* -------------------------------------------------------------------------- */
  /*                               Tracked Getters                              */
  /* -------------------------------------------------------------------------- */

  function _getAccount(address accountAddress) internal returns (MarketAccount storage) {
    touchedAccounts.add(accountAddress);
    return accounts[accountAddress];
  }

  function _getWithdrawalBatch(uint32 expiry) internal returns (WithdrawalBatch storage) {
    touchedBatches.add(uint256(expiry));
    return _withdrawalData.batches[expiry];
  }

  function _getWithdrawalStatus(
    uint32 expiry,
    address accountAddress
  ) internal returns (AccountWithdrawalStatus storage) {
    touchedAccountsByBatch[expiry].add(accountAddress);
    return _withdrawalData.accountStatuses[expiry][accountAddress];
  }

  function _getBalance(
    MarketState memory state,
    address accountAddress
  ) internal returns (uint104 scaledBalance, uint256 normalizedBalance) {
    MarketAccount storage account = _getAccount(accountAddress);
    scaledBalance = account.scaledBalance;
    if (scaledBalance == 0) {
      return (0, 0);
    }
    normalizedBalance = state.normalizeAmount(scaledBalance);
  }

  /* -------------------------------------------------------------------------- */
  /*                               Action Trackers                              */
  /* -------------------------------------------------------------------------- */

  function _trackBlockAccount(MarketState memory state, address accountAddress) internal {
    vm.expectEmit(address(market));
    emit AccountSanctioned(accountAddress);

    MarketAccount storage account = _getAccount(accountAddress);

    uint104 scaledBalance = account.scaledBalance;
    if (scaledBalance > 0) {
      uint256 normalizedBalance = state.normalizeAmount(scaledBalance);
      account.scaledBalance = 0;
      address escrowAddress = calculateEscrowAddress(accountAddress, address(market));
      _getAccount(escrowAddress).scaledBalance += scaledBalance;
      vm.expectEmit(address(market));
      emit Transfer(accountAddress, escrowAddress, normalizedBalance);
      vm.expectEmit(address(market));
      emit SanctionedAccountAssetsSentToEscrow(accountAddress, escrowAddress, normalizedBalance);
    }
  }

  function _trackDeposit(
    MarketState memory state,
    address accountAddress,
    uint256 normalizedAmount
  ) internal returns (uint104 scaledAmount, uint256 actualNormalizedAmount) {
    actualNormalizedAmount = MathUtils.min(normalizedAmount, state.maximumDeposit());

    scaledAmount = state.scaleAmount(actualNormalizedAmount).toUint104();
    MarketAccount storage account = _getAccount(accountAddress);

    account.scaledBalance += scaledAmount;
    state.scaledTotalSupply += scaledAmount;
    lastTotalAssets += actualNormalizedAmount;

    updateState(state);
  }

  function registerExpectationsStandin(uint, bool) internal {}

  function _trackQueueWithdrawal(
    MarketState memory state,
    address accountAddress,
    uint256 normalizedAmount
  ) internal returns (uint32 expiry, uint104 scaledAmount) {
    return _trackQueueWithdrawal(
      state,
      accountAddress,
      normalizedAmount,
      registerExpectationsStandin,
      0
    );
  }

  function _trackQueueWithdrawal(
    MarketState memory state,
    address accountAddress,
    uint256 normalizedAmount,
    function (uint, bool) internal registerHookExpectations,
    uint registerHookExpectationsInput
  ) internal returns (uint32 expiry, uint104 scaledAmount) {
    scaledAmount = state.scaleAmount(normalizedAmount).toUint104();
    _getAccount(accountAddress).scaledBalance -= scaledAmount;

    if (state.pendingWithdrawalExpiry == 0) {
      state.pendingWithdrawalExpiry = uint32(
        block.timestamp + (state.isClosed ? 0 : parameters.withdrawalBatchDuration)
      );
      vm.expectEmit(address(market));
      emit WithdrawalBatchCreated(state.pendingWithdrawalExpiry);
    }
    expiry = state.pendingWithdrawalExpiry;
    if (registerHookExpectationsInput != 0) {
      registerHookExpectations(registerHookExpectationsInput, true);
    }

    vm.expectEmit(address(market));
    emit Transfer(accountAddress, address(market), normalizedAmount);

    _getWithdrawalStatus(expiry, accountAddress).scaledAmount += scaledAmount;
    WithdrawalBatch storage batch = _getWithdrawalBatch(expiry);
    batch.scaledTotalAmount += scaledAmount;
    state.scaledPendingWithdrawals += scaledAmount;

    vm.expectEmit(address(market));
    emit WithdrawalQueued(expiry, accountAddress, scaledAmount, normalizedAmount);

    uint256 availableLiquidity = _availableLiquidityForPendingBatch(batch, state);
    if (availableLiquidity > 0) {
      _applyWithdrawalBatchPayment(batch, state, expiry, availableLiquidity, true);
    }

    updateState(state);
  }

  function _trackExecuteWithdrawal(
    MarketState memory state,
    uint32 expiry,
    address accountAddress,
    uint256 withdrawalAmount,
    bool willBeEscrowed
  ) internal {
    // @todo
    // bool isSanctioned = sanctionsSentinel.isSanctioned(borrower, accountAddress);
    // bool willBeBlocked = isSanctioned && market.getAccountRole(accountAddress) != AuthRole.Blocked;

    if (willBeEscrowed) {
      address escrow = calculateEscrowAddress(accountAddress, parameters.asset);
      vm.expectEmit(parameters.asset);
      emit Transfer(address(market), escrow, withdrawalAmount);
      vm.expectEmit(address(market));
      emit SanctionedAccountWithdrawalSentToEscrow(
        accountAddress,
        escrow,
        expiry,
        withdrawalAmount
      );
    } else {
      vm.expectEmit(parameters.asset);
      emit Transfer(address(market), accountAddress, withdrawalAmount);
    }

    lastTotalAssets -= withdrawalAmount;
    _getWithdrawalStatus(expiry, accountAddress).normalizedAmountWithdrawn += uint128(
      withdrawalAmount
    );
    state.normalizedUnclaimedWithdrawals -= uint128(withdrawalAmount);

    vm.expectEmit(address(market));
    emit WithdrawalExecuted(expiry, accountAddress, withdrawalAmount);
  }

  function _trackExecuteWithdrawal(
    MarketState memory state,
    uint32 expiry,
    address accountAddress
  ) internal {
    WithdrawalBatch memory batch = _getWithdrawalBatch(expiry);
    AccountWithdrawalStatus storage status = _getWithdrawalStatus(expiry, accountAddress);

    uint128 newTotalWithdrawn = uint128(
      MathUtils.mulDiv(batch.normalizedAmountPaid, status.scaledAmount, batch.scaledTotalAmount)
    );

    uint128 normalizedAmountWithdrawn = newTotalWithdrawn - status.normalizedAmountWithdrawn;
    MarketAccount storage account = _getAccount(accountAddress);
    bool isSanctioned = sanctionsSentinel.isSanctioned(borrower, accountAddress);
    _trackExecuteWithdrawal(state, expiry, accountAddress, normalizedAmountWithdrawn, isSanctioned);
  }

  function _trackRepay(
    MarketState memory state,
    address accountAddress,
    uint256 normalizedAmount
  ) internal {
    vm.expectEmit(parameters.asset);
    emit Transfer(accountAddress, address(market), normalizedAmount);
    vm.expectEmit(address(market));
    emit DebtRepaid(accountAddress, normalizedAmount);
    lastTotalAssets += normalizedAmount;
  }

  function _trackCloseMarket(MarketState memory state, bool expectEvents) internal {
    uint256 currentlyHeld = lastTotalAssets;
    uint totalDebts = state.totalDebts();
    if (currentlyHeld < totalDebts) {
      uint256 remainingDebt = totalDebts - currentlyHeld;
      _trackRepay(state, borrower, remainingDebt);
      currentlyHeld += remainingDebt;
    } else if (currentlyHeld > totalDebts) {
      uint256 excessDebt = currentlyHeld - totalDebts;
      if (expectEvents) {
        vm.expectEmit(parameters.asset);
        emit Transfer(address(market), borrower, excessDebt);
      }
      currentlyHeld -= excessDebt;
    }

    state.annualInterestBips = 0;
    state.isClosed = true;
    state.reserveRatioBips = 10000;
    state.timeDelinquent = 0;
    uint256 availableLiquidity = currentlyHeld -
      (state.normalizedUnclaimedWithdrawals + state.accruedProtocolFees);

    if (state.pendingWithdrawalExpiry != 0) {
      uint32 expiry = state.pendingWithdrawalExpiry;
      WithdrawalBatch storage batch = _withdrawalData.batches[expiry];
      if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
        uint128 normalizedAmountPaid = _applyWithdrawalBatchPayment(
          batch,
          state,
          expiry,
          availableLiquidity,
          expectEvents
        );
        availableLiquidity -= normalizedAmountPaid;
        _withdrawalData.batches[expiry] = batch;
      }
    }

    uint256 numBatches = _withdrawalData.unpaidBatches.length();
    for (uint256 i; i < numBatches; i++) {
      // Process the next unpaid batch using available liquidity
      uint256 normalizedAmountPaid = _trackProcessUnpaidWithdrawalBatch(state, availableLiquidity);
      // Reduce liquidity available to next batch
      availableLiquidity -= normalizedAmountPaid;
    }

    if (state.scaledPendingWithdrawals != 0) {
      revert_CloseMarketWithUnpaidWithdrawals();
    }
    if (expectEvents) {
      vm.expectEmit(address(market));
      emit MarketClosed(block.timestamp);
    }
    updateState(state);
  }

  function _trackBorrow(uint256 normalizedAmount) internal {
    vm.expectEmit(parameters.asset);
    emit Transfer(address(market), parameters.borrower, normalizedAmount);
    vm.expectEmit(address(market));
    emit Borrow(normalizedAmount);
    lastTotalAssets -= normalizedAmount;
  }

  function _trackProcessUnpaidWithdrawalBatch(
    MarketState memory state,
    uint256 availableLiquidity
  ) internal returns (uint128 normalizedAmountPaid) {
    uint32 expiry = _withdrawalData.unpaidBatches.first();
    WithdrawalBatch storage batch = _getWithdrawalBatch(expiry);
    if (availableLiquidity > 0) {
      normalizedAmountPaid = _applyWithdrawalBatchPayment(
        batch,
        state,
        expiry,
        availableLiquidity,
        true
      );
    }
    if (batch.scaledTotalAmount == batch.scaledAmountBurned) {
      _withdrawalData.unpaidBatches.shift();
      vm.expectEmit(address(market));
      emit WithdrawalBatchClosed(expiry);
    }
  }

  function _trackProcessUnpaidWithdrawalBatch(
    MarketState memory state
  ) internal returns (uint128 normalizedAmountPaid) {
    uint256 availableLiquidity = lastTotalAssets -
      (state.normalizedUnclaimedWithdrawals + state.accruedProtocolFees);
    return _trackProcessUnpaidWithdrawalBatch(state, availableLiquidity);
  }

  /**
   * @dev When a withdrawal batch expires, the market will checkpoint the scale factor
   *      as of the time of expiry and retrieve the current liquid assets in the market
   * (assets which are not already owed to protocol fees or prior withdrawal batches).
   */
  function _processExpiredWithdrawalBatch(MarketState memory state, bool expectEvents) internal {
    WithdrawalBatch storage batch = _getWithdrawalBatch(state.pendingWithdrawalExpiry);

    if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
      // Get the liquidity which is not already reserved for prior withdrawal batches
      // or owed to protocol fees.
      uint256 availableLiquidity = _availableLiquidityForPendingBatch(batch, state);
      if (availableLiquidity > 0) {
        _applyWithdrawalBatchPayment(
          batch,
          state,
          state.pendingWithdrawalExpiry,
          availableLiquidity,
          expectEvents
        );
      }
    }
    if (expectEvents) {
      vm.expectEmit(address(market));
      emit WithdrawalBatchExpired(
        state.pendingWithdrawalExpiry,
        batch.scaledTotalAmount,
        batch.scaledAmountBurned,
        batch.normalizedAmountPaid
      );
    }

    if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
      _withdrawalData.unpaidBatches.push(state.pendingWithdrawalExpiry);
    } else if (expectEvents) {
      vm.expectEmit(address(market));
      emit WithdrawalBatchClosed(state.pendingWithdrawalExpiry);
    }

    state.pendingWithdrawalExpiry = 0;
  }

  function _availableLiquidityForPendingBatch(
    WithdrawalBatch storage batch,
    MarketState memory state
  ) internal view returns (uint256) {
    uint104 scaledAmountOwed = batch.scaledTotalAmount - batch.scaledAmountBurned;
    uint256 unavailableAssets = state.normalizedUnclaimedWithdrawals +
      state.accruedProtocolFees +
      state.normalizeAmount(state.scaledPendingWithdrawals - scaledAmountOwed);

    return lastTotalAssets.satSub(unavailableAssets);
  }

  /**
   * @dev Process withdrawal payment, burning market tokens and reserving
   *      underlying assets so they are only available for withdrawals.
   */
  function _applyWithdrawalBatchPayment(
    WithdrawalBatch storage batch,
    MarketState memory state,
    uint32 expiry,
    uint256 availableLiquidity,
    bool expectEvents
  ) internal returns (uint128 normalizedAmountPaid) {
    uint104 scaledAvailableLiquidity = state.scaleAmount(availableLiquidity).toUint104();
    uint104 scaledAmountOwed = batch.scaledTotalAmount - batch.scaledAmountBurned;
    if (scaledAmountOwed == 0) {
      return 0;
    }
    uint104 scaledAmountBurned = uint104(MathUtils.min(scaledAvailableLiquidity, scaledAmountOwed));
    normalizedAmountPaid =  MathUtils.mulDiv(scaledAmountBurned, state.scaleFactor, RAY).toUint128();

    batch.scaledAmountBurned += scaledAmountBurned;
    batch.normalizedAmountPaid += normalizedAmountPaid;
    state.scaledPendingWithdrawals -= scaledAmountBurned;

    // Update normalizedUnclaimedWithdrawals so the tokens are only accessible for withdrawals.
    state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

    // Burn market tokens to stop interest accrual upon withdrawal payment.
    state.scaledTotalSupply -= scaledAmountBurned;

    // Emit transfer for external trackers to indicate burn.
    if (expectEvents) {
      vm.expectEmit(address(market));
      emit Transfer(address(market), address(0), normalizedAmountPaid);
      vm.expectEmit(address(market));
      emit WithdrawalBatchPayment(expiry, scaledAmountBurned, normalizedAmountPaid);
    }
  }
}
