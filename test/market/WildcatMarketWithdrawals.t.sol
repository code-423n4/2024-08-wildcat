// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import '../BaseMarketTest.sol';

contract WithdrawalsTest is BaseMarketTest {
  using MathUtils for uint256;
  using FeeMath for uint256;

  function _checkBatch(
    uint32 expiry,
    uint256 scaledTotalAmount,
    uint256 scaledAmountBurned,
    uint256 normalizedAmountPaid
  ) internal {
    WithdrawalBatch memory batch = market.getWithdrawalBatch(expiry);
    assertEq(batch.scaledTotalAmount, scaledTotalAmount, 'scaledAmountBurned');
    assertEq(batch.scaledAmountBurned, scaledAmountBurned, 'scaledAmountBurned');
    assertEq(batch.normalizedAmountPaid, normalizedAmountPaid, 'normalizedAmountPaid');
  }

  /* -------------------------------------------------------------------------- */
  /*                              queueWithdrawal()                             */
  /* -------------------------------------------------------------------------- */

  function test_queueWithdrawal_NotApprovedLender() external {
    _deposit(alice, 1e18);
    vm.prank(alice);
    market.transfer(bob, 1e18);
    vm.startPrank(bob);
    vm.expectRevert(IMarketEventsAndErrors.NotApprovedLender.selector);
    market.queueWithdrawal(1e18);
  }

  function test_queueWithdrawal_AuthorizedWithdrawOnly() public asAccount(bob) {
    _deposit(bob, 1e18);
    // startPrank(address(controller));
    // market.updateAccountAuthorization(bob, false);
    _deauthorizeLender(bob);
    stopPrank();
    _requestWithdrawal(bob, 1e18);
  }

  function test_queueWithdrawal_AuthorizedOnController() public {
    _deposit(alice, 1e18);
    vm.prank(alice);
    market.transfer(bob, 1e18);
    _authorizeLender(bob);
    vm.startPrank(bob);
    market.queueWithdrawal(1e18);
  }

  function test_queueWithdrawal_NullBurnAmount() external asAccount(alice) {
    vm.expectRevert(IMarketEventsAndErrors.NullBurnAmount.selector);
    market.queueWithdrawal(0);
  }

  function test_queueWithdrawal_InsufficientBalance() external asAccount(alice) {
    _deposit(alice, 1e18);
    vm.expectRevert(abi.encodePacked(uint32(Panic_ErrorSelector), Panic_Arithmetic));
    market.queueWithdrawal(1e18 + 1);
  }

  function test_queueWithdrawal_AddToExisting(
    uint256 userBalance1,
    uint256 withdrawalAmount1,
    uint256 userBalance2,
    uint256 withdrawalAmount2
  ) external asAccount(alice) {
    (userBalance1, withdrawalAmount1) = dbound(
      userBalance1,
      withdrawalAmount1,
      2,
      DefaultMaximumSupply / 2
    );
    (userBalance2, withdrawalAmount2) = dbound(
      userBalance2,
      withdrawalAmount2,
      2,
      DefaultMaximumSupply - userBalance1
    );
    _deposit(alice, userBalance1);
    _deposit(bob, userBalance2);
    _requestWithdrawal(alice, userBalance1);
    _requestWithdrawal(bob, userBalance2);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, false, 'isDelinquent');
    assertEq(state.timeDelinquent, 0, 'timeDelinquent');
    assertEq(state.scaledPendingWithdrawals, 0, 'scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, 0, 'scaledTotalSupply');
    assertEq(
      state.normalizedUnclaimedWithdrawals,
      userBalance1 + userBalance2,
      'normalizedUnclaimedWithdrawals'
    );
  }

  function test_queueWithdrawal_BurnAll(
    uint128 userBalance,
    uint128 withdrawalAmount
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    _deposit(alice, userBalance);
    _requestWithdrawal(alice, userBalance);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, false, 'isDelinquent');
    assertEq(state.timeDelinquent, 0, 'timeDelinquent');
    assertEq(state.scaledPendingWithdrawals, 0, 'scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, 0, 'scaledTotalSupply');
    assertEq(state.normalizedUnclaimedWithdrawals, userBalance, 'normalizedUnclaimedWithdrawals');
  }

  function test_queueWithdrawal_AfterMarketClosed(
    uint128 userBalance,
    uint128 withdrawalAmount
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    _deposit(alice, userBalance);
    _closeMarket();
    _requestWithdrawal(alice, userBalance);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, false, 'isDelinquent');
    assertEq(state.timeDelinquent, 0, 'timeDelinquent');
    assertEq(state.scaledPendingWithdrawals, 0, 'scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, 0, 'scaledTotalSupply');
    assertEq(state.normalizedUnclaimedWithdrawals, userBalance, 'normalizedUnclaimedWithdrawals');
  }

  function test_queueWithdrawal_BurnPartial(
    uint128 userBalance,
    uint128 borrowAmount
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    borrowAmount = uint128(
      bound(borrowAmount, 2, uint256(userBalance).bipMul(10000 - parameters.reserveRatioBips))
    );
    _deposit(alice, userBalance);
    _borrow(borrowAmount);
    _requestWithdrawal(alice, userBalance);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, true, 'state.isDelinquent');
    assertEq(state.timeDelinquent, 0, 'state.timeDelinquent');
    uint128 remainingAssets = userBalance - borrowAmount;

    assertEq(state.scaledPendingWithdrawals, borrowAmount, 'state.scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, borrowAmount, 'state.scaledTotalSupply');
    assertEq(
      state.normalizedUnclaimedWithdrawals,
      remainingAssets,
      'state.normalizedUnclaimedWithdrawals'
    );
  }

  function test_queueWithdrawal(
    uint128 userBalance,
    uint128 withdrawalAmount
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    withdrawalAmount = uint128(bound(withdrawalAmount, 2, userBalance));
    _deposit(alice, userBalance);
    _requestWithdrawal(alice, withdrawalAmount);
  }


  /* -------------------------------------------------------------------------- */
  /*                              queueFullWithdrawal()                             */
  /* -------------------------------------------------------------------------- */

  function test_queueFullWithdrawal_NotApprovedLender() external {
    _deposit(alice, 1e18);
    vm.prank(alice);
    market.transfer(bob, 1e18);
    vm.startPrank(bob);
    vm.expectRevert(IMarketEventsAndErrors.NotApprovedLender.selector);
    market.queueFullWithdrawal();
  }

  function test_queueFullWithdrawal_AuthorizedWithdrawOnly() public asAccount(bob) {
    _deposit(bob, 1e18);
    _deauthorizeLender(bob);
    stopPrank();
    _requestFullWithdrawal(bob);
  }

  function test_queueFullWithdrawal_AuthorizedOnHooks() public {
    _deposit(alice, 1e18);
    vm.prank(alice);
    market.transfer(bob, 1e18);
    _authorizeLender(bob);
    vm.startPrank(bob);
    market.queueFullWithdrawal();
  }

  function test_queueFullWithdrawal_NullBurnAmount() external asAccount(alice) {
    vm.expectRevert(IMarketEventsAndErrors.NullBurnAmount.selector);
    market.queueFullWithdrawal();
  }

  function test_queueFullWithdrawal_AddToExisting(
    uint256 userBalance1,
    uint256 userBalance2
  ) external asAccount(alice) {
    userBalance1 = bound(
      userBalance1,
      2,
      DefaultMaximumSupply / 2
    );
    userBalance2 = bound(
      userBalance2,
      2,
      DefaultMaximumSupply - userBalance1
    );
    _deposit(alice, userBalance1);
    _deposit(bob, userBalance2);
    _requestFullWithdrawal(alice);
    _requestFullWithdrawal(bob);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, false, 'isDelinquent');
    assertEq(state.timeDelinquent, 0, 'timeDelinquent');
    assertEq(state.scaledPendingWithdrawals, 0, 'scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, 0, 'scaledTotalSupply');
    assertEq(
      state.normalizedUnclaimedWithdrawals,
      userBalance1 + userBalance2,
      'normalizedUnclaimedWithdrawals'
    );
  }

  function test_queueFullWithdrawal_BurnAll(
    uint128 userBalance
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    _deposit(alice, userBalance);
    _requestFullWithdrawal(alice);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, false, 'isDelinquent');
    assertEq(state.timeDelinquent, 0, 'timeDelinquent');
    assertEq(state.scaledPendingWithdrawals, 0, 'scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, 0, 'scaledTotalSupply');
    assertEq(state.normalizedUnclaimedWithdrawals, userBalance, 'normalizedUnclaimedWithdrawals');
  }

  function test_queueFullWithdrawal_AfterMarketClosed(
    uint128 userBalance
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    _deposit(alice, userBalance);
    _closeMarket();
    _requestFullWithdrawal(alice);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, false, 'isDelinquent');
    assertEq(state.timeDelinquent, 0, 'timeDelinquent');
    assertEq(state.scaledPendingWithdrawals, 0, 'scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, 0, 'scaledTotalSupply');
    assertEq(state.normalizedUnclaimedWithdrawals, userBalance, 'normalizedUnclaimedWithdrawals');
  }

  function test_queueFullWithdrawal_BurnPartial(
    uint128 userBalance,
    uint128 borrowAmount
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    borrowAmount = uint128(
      bound(borrowAmount, 2, uint256(userBalance).bipMul(10000 - parameters.reserveRatioBips))
    );
    _deposit(alice, userBalance);
    _borrow(borrowAmount);
    _requestFullWithdrawal(alice);
    MarketState memory state = previousState;
    assertEq(state.isDelinquent, true, 'state.isDelinquent');
    assertEq(state.timeDelinquent, 0, 'state.timeDelinquent');
    uint128 remainingAssets = userBalance - borrowAmount;

    assertEq(state.scaledPendingWithdrawals, borrowAmount, 'state.scaledPendingWithdrawals');
    assertEq(state.scaledTotalSupply, borrowAmount, 'state.scaledTotalSupply');
    assertEq(
      state.normalizedUnclaimedWithdrawals,
      remainingAssets,
      'state.normalizedUnclaimedWithdrawals'
    );
  }

  function test_queueFullWithdrawal(
    uint128 userBalance
  ) external asAccount(alice) {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    _deposit(alice, userBalance);
    _requestFullWithdrawal(alice);
  }

  /* -------------------------------------------------------------------------- */
  /*                             executeWithdrawal()                            */
  /* -------------------------------------------------------------------------- */

  function test_executeWithdrawal_NotExpired(
    uint128 userBalance,
    uint128 withdrawalAmount
  ) external {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    withdrawalAmount = uint128(bound(withdrawalAmount, 2, userBalance));
    _deposit(alice, userBalance);
    _requestWithdrawal(alice, withdrawalAmount);
    vm.expectRevert(IMarketEventsAndErrors.WithdrawalBatchNotExpired.selector);
    market.executeWithdrawal(alice, uint32(block.timestamp + parameters.withdrawalBatchDuration));
  }

  function test_executeWithdrawal(uint128 userBalance, uint128 withdrawalAmount) external {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    withdrawalAmount = uint128(bound(withdrawalAmount, 2, userBalance));
    _deposit(alice, userBalance);
    _requestWithdrawal(alice, withdrawalAmount);
    uint256 expiry = block.timestamp + parameters.withdrawalBatchDuration;
    fastForward(parameters.withdrawalBatchDuration + 1);
    MarketState memory state = pendingState();
    updateState(state);
    uint256 previousBalance = asset.balanceOf(alice);
    uint256 withdrawalAmount = state.normalizedUnclaimedWithdrawals;
    vm.prank(alice);
    market.executeWithdrawal(alice, uint32(expiry));
    assertEq(asset.balanceOf(alice), previousBalance + withdrawalAmount);
  }

  function test_executeWithdrawal_NullWithdrawalAmount(
    uint128 userBalance,
    uint128 withdrawalAmount
  ) external {
    userBalance = uint128(bound(userBalance, 2, DefaultMaximumSupply));
    withdrawalAmount = uint128(bound(withdrawalAmount, 2, userBalance));
    _deposit(alice, userBalance);
    _requestWithdrawal(alice, withdrawalAmount);
    uint256 expiry = block.timestamp + parameters.withdrawalBatchDuration;
    fastForward(parameters.withdrawalBatchDuration + 1);
    MarketState memory state = pendingState();
    updateState(state);
    uint256 previousBalance = asset.balanceOf(alice);
    uint256 withdrawalAmount = state.normalizedUnclaimedWithdrawals;
    vm.prank(alice);
    market.executeWithdrawal(alice, uint32(expiry));
    assertEq(asset.balanceOf(alice), previousBalance + withdrawalAmount);
    vm.expectRevert(IMarketEventsAndErrors.NullWithdrawalAmount.selector);
    market.executeWithdrawal(alice, uint32(expiry));
  }

  function test_executeWithdrawal_MarketClosed() external {
    _deposit(alice, 1e18);
    _requestWithdrawal(alice, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    _closeMarket();
    fastForward(parameters.withdrawalBatchDuration + 1);
    _trackExecuteWithdrawal(pendingState(), expiry, alice, 1e18,  false);
    vm.prank(alice);
    market.executeWithdrawal(alice, expiry);
  }

  function test_executeWithdrawal_MarketClosed_BeforeExpiry() external {
    _deposit(alice, 1e18);
    _requestWithdrawal(alice, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    _closeMarket();
    _trackExecuteWithdrawal(pendingState(), expiry, alice, 1e18,  false);
    vm.prank(alice);
    market.executeWithdrawal(alice, expiry);
  }

  function test_executeWithdrawal_Sanctioned() external {
    _deposit(alice, 1e18);
    _requestWithdrawal(alice, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    sanctionsSentinel.sanction(alice);
    address escrow = sanctionsSentinel.getEscrowAddress(borrower, alice, address(asset));
    _trackExecuteWithdrawal(pendingState(), uint32(block.timestamp - 1), alice, 1e18, true);
    market.executeWithdrawal(alice, uint32(block.timestamp - 1));
  }

  /* -------------------------------------------------------------------------- */
  /*                            executeWithdrawals()                            */
  /* -------------------------------------------------------------------------- */

  function _prepareBatch(
    uint256 aliceAmount,
    uint256 bobAmount,
    bool skipToEnd
  ) internal returns (uint32 expiry) {
    if (aliceAmount > 0) _requestWithdrawal(alice, aliceAmount);
    if (bobAmount > 0) _requestWithdrawal(bob, bobAmount);
    expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    if (skipToEnd) {
      fastForward(parameters.withdrawalBatchDuration + 1);
    }
  }

  function test_executeWithdrawals() external {
    parameters.annualInterestBips = 0;
    setUp();
    _deposit(alice, 1e18);
    _deposit(bob, 1e18);
    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint32 expiry2 = uint32(expiry1 + parameters.withdrawalBatchDuration + 1);
    _prepareBatch(0.5e18, 0.5e18, true);
    _prepareBatch(0.5e18, 0.5e18, true);
    _checkBatch(expiry1, 1e18, 1e18, 1e18);
    _checkBatch(expiry2, 1e18, 1e18, 1e18);

    address[] memory accounts = new address[](4);
    accounts[0] = alice;
    accounts[1] = bob;
    accounts[2] = alice;
    accounts[3] = bob;
    uint32[] memory expiries = new uint32[](4);
    expiries[0] = expiry1;
    expiries[1] = expiry1;
    expiries[2] = expiry2;
    expiries[3] = expiry2;
    MarketState memory state = pendingState();
    _trackExecuteWithdrawal(state, expiry1, alice);
    _trackExecuteWithdrawal(state, expiry1, bob);
    _trackExecuteWithdrawal(state, expiry2, alice);
    _trackExecuteWithdrawal(state, expiry2, bob);
    market.executeWithdrawals(accounts, expiries);
  }

  function test_executeWithdrawals_InvalidArrayLength() external {
    vm.expectRevert(IMarketEventsAndErrors.InvalidArrayLength.selector);
    address[] memory accounts = new address[](1);
    uint32[] memory expiries = new uint32[](2);
    market.executeWithdrawals(accounts, expiries);
  }

  function test_executeWithdrawals_NullWithdrawalAmount() external {
    parameters.annualInterestBips = 0;
    setUp();
    _deposit(alice, 1e18);
    _deposit(bob, 1e18);

    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    _prepareBatch(0.5e18, 0.5e18, true);
    _checkBatch(expiry1, 1e18, 1e18, 1e18);

    address[] memory accounts = new address[](2);
    accounts[0] = alice;
    accounts[1] = alice;
    uint32[] memory expiries = new uint32[](2);
    expiries[0] = expiry1;
    expiries[1] = expiry1;
    vm.expectRevert(IMarketEventsAndErrors.NullWithdrawalAmount.selector);
    market.executeWithdrawals(accounts, expiries);
  }

  function test_executeWithdrawals_Sanctioned() external {
    parameters.annualInterestBips = 0;
    setUp();
    _deposit(alice, 1e18);
    _deposit(bob, 1e18);
    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint32 expiry2 = uint32(expiry1 + parameters.withdrawalBatchDuration + 1);
    _prepareBatch(0.5e18, 0.5e18, true);
    _prepareBatch(0.5e18, 0.5e18, true);
    _checkBatch(expiry1, 1e18, 1e18, 1e18);
    _checkBatch(expiry2, 1e18, 1e18, 1e18);

    sanctionsSentinel.sanction(alice);

    address[] memory accounts = new address[](4);
    accounts[0] = alice;
    accounts[1] = bob;
    accounts[2] = alice;
    accounts[3] = bob;
    uint32[] memory expiries = new uint32[](4);
    expiries[0] = expiry1;
    expiries[1] = expiry1;
    expiries[2] = expiry2;
    expiries[3] = expiry2;
    MarketState memory state = pendingState();
    _trackExecuteWithdrawal(state, expiry1, alice, 0.5e18, true);
    _trackExecuteWithdrawal(state, expiry1, bob);
    _trackExecuteWithdrawal(state, expiry2, alice, 0.5e18, true);
    _trackExecuteWithdrawal(state, expiry2, bob);
    market.executeWithdrawals(accounts, expiries);
  }

  /* -------------------------------------------------------------------------- */
  /*                       processUnpaidWithdrawalBatch()                       */
  /* -------------------------------------------------------------------------- */

  function test_processUnpaidWithdrawalBatch_NoUnpaidBatches() external {
    market.repayAndProcessUnpaidWithdrawalBatches(0, 1);
  }

  function test_processUnpaidWithdrawalBatch() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    assertEq(market.previousState().isDelinquent, true);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    fastForward(parameters.withdrawalBatchDuration * 2);
    _checkBatch(expiry, 1e18, 2e17, 2e17);
    market.updateState();
    updateState(pendingState());
    _checkState();
    uint32[] memory unpaidBatchExpiries = market.getUnpaidBatchExpiries();
    assertEq(unpaidBatchExpiries.length, 1);
    assertEq(unpaidBatchExpiries[0], expiry);
    _checkState();
    assertEq(market.previousState().timeDelinquent, parameters.withdrawalBatchDuration * 2);

    MarketState memory state = pendingState();
    _checkBatch(expiry, 1e18, 2e17, 2e17);

    asset.mint(address(market), 8e17 + state.accruedProtocolFees);
    lastTotalAssets += 8e17 + state.accruedProtocolFees;
    _trackProcessUnpaidWithdrawalBatch(state);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 1);

    uint256 delinquencyFeeRay = FeeMath.calculateLinearInterestFromBips(
      parameters.delinquencyFeeBips,
      uint256(parameters.withdrawalBatchDuration).satSub(parameters.delinquencyGracePeriod)
    );
    uint256 baseInterestRay = FeeMath.calculateLinearInterestFromBips(
      parameters.annualInterestBips,
      parameters.withdrawalBatchDuration
    );
    uint scaleFactor1 = RAY + delinquencyFeeRay + baseInterestRay;
    delinquencyFeeRay = FeeMath.calculateLinearInterestFromBips(
      parameters.delinquencyFeeBips,
      parameters.withdrawalBatchDuration
    );
    uint scaleFactor2 = scaleFactor1.rayMul(RAY + delinquencyFeeRay + baseInterestRay);
    uint256 feesAccruedOnWithdrawal = uint(8e17).mulDiv(scaleFactor2, RAY) - 8e17;

    asset.mint(address(market), feesAccruedOnWithdrawal);
    lastTotalAssets += feesAccruedOnWithdrawal;
    _trackProcessUnpaidWithdrawalBatch(state);
    updateState(state);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 1);

    uint scaledAvailableLiquidity = state.scaleAmount(feesAccruedOnWithdrawal);
    uint normalizedAmountPaid = MathUtils
    .mulDiv(scaledAvailableLiquidity, state.scaleFactor, RAY);
    _checkBatch(expiry, 1e18, 1e18, 1e18 + normalizedAmountPaid);
    assertEq(market.getUnpaidBatchExpiries().length, 0);
    _checkState();
  }

  /* -------------------------------------------------------------------------- */
  /*                      processUnpaidWithdrawalBatches()                      */
  /* -------------------------------------------------------------------------- */

  function test_repayAndProcessUnpaidWithdrawalBatches_NoBatches() external {
    market.repayAndProcessUnpaidWithdrawalBatches(0, 1);
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_NoAvailableLiquidity() external {
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 1);
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_Single() external {
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    fastForward(parameters.withdrawalBatchDuration * 2);
    updateState(pendingState(true));
    market.updateState();
    asset.mint(address(market), 1e18);
    lastTotalAssets += 1e18;
    MarketState memory state = pendingState(true);
    _trackProcessUnpaidWithdrawalBatch(state);
    updateState(state);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 1);
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_InsufficientAssetsForSecond() external {
    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint32 expiry2 = uint32(expiry1 + parameters.withdrawalBatchDuration);
    _depositBorrowWithdraw(alice, 2e18, 1.6e18, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    _requestWithdrawal(alice, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    market.updateState();
    updateState(pendingState());
    assertEq(market.getUnpaidBatchExpiries().length, 2);

    MarketState memory state = pendingState();
    asset.mint(address(market), 7e17);
    lastTotalAssets += 7e17;
    _trackProcessUnpaidWithdrawalBatch(state);
    _trackProcessUnpaidWithdrawalBatch(state);
    updateState(state);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 10);
    assertEq(market.getUnpaidBatchExpiries().length, 1);
    _checkState();
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_SufficientAssetsForBoth() external {
    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint32 expiry2 = uint32(expiry1 + parameters.withdrawalBatchDuration);
    _depositBorrowWithdraw(alice, 2e18, 1.6e18, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    _requestWithdrawal(alice, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    market.updateState();
    updateState(pendingState());
    assertEq(market.getUnpaidBatchExpiries().length, 2);

    MarketState memory state = pendingState();
    asset.mint(address(market), 1.7e18);
    lastTotalAssets += 1.7e18;
    _trackProcessUnpaidWithdrawalBatch(state);
    _trackProcessUnpaidWithdrawalBatch(state);
    updateState(state);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 10);
    assertEq(market.getUnpaidBatchExpiries().length, 0);
    _checkState();
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_MaxZero() external {
    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint32 expiry2 = uint32(expiry1 + parameters.withdrawalBatchDuration);
    _depositBorrowWithdraw(alice, 2e18, 1.6e18, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    _requestWithdrawal(alice, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    market.updateState();
    updateState(pendingState());
    assertEq(market.getUnpaidBatchExpiries().length, 2);

    MarketState memory state = pendingState();
    asset.mint(address(market), 1.7e18);
    lastTotalAssets += 1.7e18;
    updateState(state);
    market.repayAndProcessUnpaidWithdrawalBatches(0, 0);
    assertEq(market.getUnpaidBatchExpiries().length, 2);
    _checkState();
  }

  function test_repayAndProcessUnpaidWithdrawalBatches() external {
    uint32 expiry1 = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint32 expiry2 = uint32(expiry1 + parameters.withdrawalBatchDuration);
    _depositBorrowWithdraw(alice, 2e18, 1.6e18, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    _requestWithdrawal(alice, 1e18);
    fastForward(parameters.withdrawalBatchDuration + 1);
    market.updateState();
    updateState(pendingState());
    assertEq(market.getUnpaidBatchExpiries().length, 2);

    MarketState memory state = pendingState();
    asset.mint(address(this), 1.7e18);
    asset.approve(address(market), 1.7e18);

    lastTotalAssets += 1.7e18;
    vm.expectEmit(address(market));
    emit DebtRepaid(address(this), 1.7e18);
    _trackProcessUnpaidWithdrawalBatch(state);
    _trackProcessUnpaidWithdrawalBatch(state);
    updateState(state);
    market.repayAndProcessUnpaidWithdrawalBatches(1.7e18, 10);
    assertEq(market.getUnpaidBatchExpiries().length, 0);
    _checkState();
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_NullRepayAmount() external {
    market.repayAndProcessUnpaidWithdrawalBatches(0, 10);
  }

  function test_repayAndProcessUnpaidWithdrawalBatches_RepayToClosedMarket() external {
    asset.mint(address(this), 1e18);
    asset.approve(address(market), 1e18);
    vm.prank(borrower);
    market.closeMarket();
    vm.expectRevert(IMarketEventsAndErrors.RepayToClosedMarket.selector);
    market.repayAndProcessUnpaidWithdrawalBatches(1e18, 10);
  }

  /* -------------------------------------------------------------------------- */
  /*                            getWithdrawalBatch()                            */
  /* -------------------------------------------------------------------------- */

  function test_getWithdrawalBatch_DoesNotExist() external {
    WithdrawalBatch memory batch = market.getWithdrawalBatch(0);
    assertEq(batch.scaledTotalAmount, 0);
    assertEq(batch.scaledAmountBurned, 0);
    assertEq(batch.normalizedAmountPaid, 0);
  }

  function test_getWithdrawalBatch_Expired() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 3e17);
    assertEq(market.previousState().isDelinquent, true);
    fastForward(parameters.withdrawalBatchDuration);
    uint32 expiry = uint32(block.timestamp);
    _checkBatch(expiry, 3e17, 2e17, 2e17);
    assertEq(market.previousState().pendingWithdrawalExpiry, expiry);
    updateState(pendingState());
    _requestWithdrawal(alice, 7e17);
    fastForward(parameters.withdrawalBatchDuration);
    updateState(pendingState());
    _checkBatch(0, 0, 0, 0);
  }

  function test_getWithdrawalBatch_Paid() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _deposit(alice, 2e18);
    _requestWithdrawal(alice, 1e18);
    fastForward(parameters.withdrawalBatchDuration);
    uint32 expiry = uint32(block.timestamp);
    _checkBatch(expiry, 1e18, 1e18, 1e18);
    updateState(pendingState());
  }

  function test_getWithdrawalBatch_WithPendingPayment() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    asset.mint(address(market), 8e17);
    _checkBatch(expiry, 1e18, 1e18, 1e18);
  }

  /* -------------------------------------------------------------------------- */
  /*                        getAccountWithdrawalStatus()                        */
  /* -------------------------------------------------------------------------- */

  function test_getAccountWithdrawalStatus() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    AccountWithdrawalStatus memory status = market.getAccountWithdrawalStatus(alice, expiry);
    assertEq(status.scaledAmount, 1e18);
    assertEq(status.normalizedAmountWithdrawn, 0);
    fastForward(parameters.withdrawalBatchDuration + 1);
    market.updateState();
    market.executeWithdrawal(alice, expiry);
    status = market.getAccountWithdrawalStatus(alice, expiry);
    assertEq(status.scaledAmount, 1e18);
    assertEq(status.normalizedAmountWithdrawn, 2e17);
  }

  /* -------------------------------------------------------------------------- */
  /*                       getAvailableWithdrawalAmount()                       */
  /* -------------------------------------------------------------------------- */

  function test_getAvailableWithdrawalAmount() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    fastForward(parameters.withdrawalBatchDuration + 1);
    AccountWithdrawalStatus memory status = market.getAccountWithdrawalStatus(alice, expiry);
    uint256 withdrawableAmount = market.getAvailableWithdrawalAmount(alice, expiry);
    assertEq(withdrawableAmount, 2e17);
  }

  function test_getAvailableWithdrawalAmount_UnpaidBatch() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    fastForward(parameters.withdrawalBatchDuration + 1);
    market.updateState();
    AccountWithdrawalStatus memory status = market.getAccountWithdrawalStatus(alice, expiry);
    uint256 withdrawableAmount = market.getAvailableWithdrawalAmount(alice, expiry);
    assertEq(withdrawableAmount, 2e17);
  }

  function test_getAvailableWithdrawalAmount_NotExpired() external {
    vm.expectRevert(IMarketEventsAndErrors.WithdrawalBatchNotExpired.selector);
    market.getAvailableWithdrawalAmount(alice, uint32(block.timestamp + 1));
  }

  function test_getAvailableWithdrawalAmount_AtExpiry() external {
    // Borrow 80% of deposits then request withdrawal of 100% of deposits
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    fastForward(parameters.withdrawalBatchDuration + 1);
    AccountWithdrawalStatus memory status = market.getAccountWithdrawalStatus(alice, expiry);
    uint256 withdrawableAmount = market.getAvailableWithdrawalAmount(alice, expiry);
    assertEq(withdrawableAmount, 2e17);
  }

  function test_updateState_ReserveAssetsForUnexpiredBatch() external {
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    uint256 baseInterestRay = FeeMath.calculateLinearInterestFromBips(
      parameters.annualInterestBips,
      1
    );
    uint256 feesAccruedOnWithdrawal = baseInterestRay.rayMul(8e17);
    asset.mint(address(market), 8e17);
    // fastForward(1);
    // vm.expectEmit(address(market));
    // emit WithdrawalBatchPayment(expiry, 8e17, 8e17 + feesAccruedOnWithdrawal);
    market.updateState();
    _checkBatch(expiry, 1e18, 1e18, 1e18);
  }

  function test_liquidityAvailableBetweenWithdrawalAndExpiry() external {
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    asset.mint(address(market), 8e17);
    fastForward( parameters.withdrawalBatchDuration + 1);
    market.updateState();
  }
}
