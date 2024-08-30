// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'src/interfaces/IMarketEventsAndErrors.sol';
import '../BaseMarketTest.sol';

contract WildcatMarketConfigTest is BaseMarketTest {
  using MathUtils for uint;

  function test_maximumDeposit(uint256 _depositAmount) external returns (uint256) {
    assertEq(market.maximumDeposit(), parameters.maxTotalSupply, 'maximumDeposit');
    _depositAmount = bound(_depositAmount, 1, DefaultMaximumSupply);
    _deposit(alice, _depositAmount);
    assertEq(market.maximumDeposit(), DefaultMaximumSupply - _depositAmount, 'new maximumDeposit');
  }

  function test_maximumDeposit_SupplyExceedsMaximum() external {
    _deposit(alice, parameters.maxTotalSupply);
    fastForward(365 days);
    _checkState('state after one year');
    assertEq(market.maximumDeposit(), 0, 'maximumDeposit after 1 year');
  }

  function test_maxTotalSupply() external asAccount(borrower) {
    assertEq(market.maxTotalSupply(), parameters.maxTotalSupply);
    market.setMaxTotalSupply(10000);
    assertEq(market.maxTotalSupply(), 10000);
  }

  function test_annualInterestBips() external asAccount(borrower) {
    assertEq(market.annualInterestBips(), parameters.annualInterestBips);
    market.setAnnualInterestAndReserveRatioBips(10000, 10000);
    assertEq(market.annualInterestBips(), 10000);
  }

  function test_reserveRatioBips() external asAccount(borrower) {
    assertEq(market.reserveRatioBips(), parameters.reserveRatioBips);
  }

  // ========================================================================== //
  //                                nukeFromOrbit                               //
  // ========================================================================== //

  function test_nukeFromOrbit(address _account) external {
    _deposit(_account, 1e18);
    sanctionsSentinel.sanction(_account);

    MarketState memory state = pendingState();
    (uint256 currentScaledBalance, uint256 currentBalance) = _getBalance(state, _account);
    (uint32 expiry, uint104 scaledAmount) = _trackQueueWithdrawal(state, _account, 1e18);
    vm.expectEmit(address(market));
    emit SanctionedAccountAssetsQueuedForWithdrawal(
      _account,
      expiry,
      currentScaledBalance,
      currentBalance
    );
    market.nukeFromOrbit(_account);
    fastForward(parameters.withdrawalBatchDuration + 1);
    state = pendingState();
    _trackExecuteWithdrawal(state, expiry, _account, 1e18, true);
    market.executeWithdrawal(_account, expiry);
  }

  function test_nukeFromOrbit_AlreadyNuked(address _account) external {
    sanctionsSentinel.sanction(_account);
    market.nukeFromOrbit(_account);
    market.nukeFromOrbit(_account);
  }

  function test_nukeFromOrbit_NullBalance(address _account) external {
    sanctionsSentinel.sanction(_account);
    address escrow = sanctionsSentinel.getEscrowAddress(borrower, _account, address(market));
    market.nukeFromOrbit(_account);
    assertEq(escrow.code.length, 0, 'escrow should not be deployed');
  }

  function test_nukeFromOrbit_WithBalance() external {
    _deposit(alice, 1e18);
    address escrow = sanctionsSentinel.getEscrowAddress(borrower, alice, address(asset));
    sanctionsSentinel.sanction(alice);
    MarketState memory state = pendingState();
    (uint256 currentScaledBalance, uint256 currentBalance) = _getBalance(state, alice);
    (uint32 expiry, uint104 scaledAmount) = _trackQueueWithdrawal(state, alice, 1e18);
    vm.expectEmit(address(market));
    emit SanctionedAccountAssetsQueuedForWithdrawal(
      alice,
      expiry,
      currentScaledBalance,
      currentBalance
    );
    market.nukeFromOrbit(alice);
  }

  function test_nukeFromOrbit_BadLaunchCode(address _account) external {
    vm.expectRevert(IMarketEventsAndErrors.BadLaunchCode.selector);
    market.nukeFromOrbit(_account);
  }

  // ========================================================================== //
  //                              setMaxTotalSupply                             //
  // ========================================================================== //

  function test_setMaxTotalSupply(
    uint256 _totalSupply,
    uint256 _maxTotalSupply
  ) external asAccount(borrower) {
    _totalSupply = bound(_totalSupply, 0, DefaultMaximumSupply);
    _maxTotalSupply = bound(_maxTotalSupply, _totalSupply, type(uint128).max);
    if (_totalSupply > 0) {
      _deposit(alice, _totalSupply);
    }
    market.setMaxTotalSupply(_maxTotalSupply);
    assertEq(market.maxTotalSupply(), _maxTotalSupply, 'maxTotalSupply should be _maxTotalSupply');
  }

  function test_setMaxTotalSupply_NotApprovedBorrower(uint128 _maxTotalSupply) external {
    vm.expectRevert(IMarketEventsAndErrors.NotApprovedBorrower.selector);
    market.setMaxTotalSupply(_maxTotalSupply);
  }

  function test_setMaxTotalSupply_BelowCurrentSupply(
    uint256 _totalSupply,
    uint256 _maxTotalSupply
  ) external asAccount(borrower) {
    _totalSupply = bound(_totalSupply, 1, DefaultMaximumSupply - 1);
    _maxTotalSupply = bound(_maxTotalSupply, 0, _totalSupply - 1);
    _deposit(alice, _totalSupply);
    market.setMaxTotalSupply(_maxTotalSupply);
    assertEq(market.maxTotalSupply(), _maxTotalSupply, 'maxTotalSupply should be _maxTotalSupply');
  }

  // ========================================================================== //
  //                    setAnnualInterestAndReserveRatioBips                    //
  // ========================================================================== //

  function test_setAnnualInterestAndReserveRatioBips(
    uint16 _annualInterestBips
  ) external asAccount(borrower) {
    _annualInterestBips = uint16(bound(_annualInterestBips, 1, 10000));
    uint reserveRatioBips;
    if (_annualInterestBips < 750) {
      uint256 relativeDiff = MathUtils.mulDiv(10000, 1_000 - uint(_annualInterestBips), 1_000);
      reserveRatioBips = MathUtils.min(10_000, 2 * relativeDiff);
    } else {
      reserveRatioBips = DefaultReserveRatio;
    }
    market.setAnnualInterestAndReserveRatioBips(_annualInterestBips, 0);
    assertEq(market.annualInterestBips(), _annualInterestBips);
    assertEq(market.reserveRatioBips(), reserveRatioBips);
  }

  function test_setAnnualInterestAndReserveRatioBips_AnnualInterestBipsOutOfBounds()
    external
    asAccount(borrower)
  {
    vm.expectRevert(MarketConstraintHooks.AnnualInterestBipsOutOfBounds.selector);
    market.setAnnualInterestAndReserveRatioBips(10001, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_AnnualInterestBipsTooHigh()
    external
    asAccount(borrower)
  {
    resetWithMockHooks();
    vm.expectRevert(IMarketEventsAndErrors.AnnualInterestBipsTooHigh.selector);
    market.setAnnualInterestAndReserveRatioBips(10001, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_ReserveRatioBipsTooHigh()
    external
    asAccount(borrower)
  {
    resetWithMockHooks();
    vm.expectRevert(IMarketEventsAndErrors.ReserveRatioBipsTooHigh.selector);
    market.setAnnualInterestAndReserveRatioBips(0, 10_001);
  }

  function test_setAnnualInterestAndReserveRatioBips_NotApprovedBorrower() external {
    vm.expectRevert(IMarketEventsAndErrors.NotApprovedBorrower.selector);
    market.setAnnualInterestAndReserveRatioBips(0, 0);
  }

  // Market already deliquent, LCR set to lower value
  function test_setAnnualInterestAndReserveRatioBips_InsufficientReservesForOldLiquidityRatio()
    external
    asAccount(borrower)
  {
    _deposit(alice, 1e18);
    _borrow(4e17);
    market.setAnnualInterestAndReserveRatioBips(700, 0);
    _checkTemporaryReserveRatioAndMarketBips(
      700,
      DefaultInterest,
      6_000,
      DefaultReserveRatio,
      block.timestamp + 2 weeks
    );
    previousState.annualInterestBips = 700;
    previousState.reserveRatioBips = 6_000;
    _requestWithdrawal(alice, 1e18);

    assertTrue(market.currentState().isDelinquent, 'market should be delinquent');

    vm.expectRevert(IMarketEventsAndErrors.InsufficientReservesForOldLiquidityRatio.selector);
    market.setAnnualInterestAndReserveRatioBips(800, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_InsufficientReservesForNewLiquidityRatio()
    external
    asAccount(borrower)
  {
    _depositBorrowWithdraw(alice, 1e18, 5e17, 1e18);
    vm.expectRevert(IMarketEventsAndErrors.InsufficientReservesForNewLiquidityRatio.selector);
    // The hooks contract will set the reserve ratio to 50.2% which would
    // make the market delinquent
    market.setAnnualInterestAndReserveRatioBips(749, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_OneQuarterReduction() public {
    vm.prank(borrower);
    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioActivated(
      address(market),
      2_000,
      2_000,
      block.timestamp + 2 weeks
    );
    market.setAnnualInterestAndReserveRatioBips(750, 0);
    _checkTemporaryReserveRatioAndMarketBips(
      750,
      DefaultInterest,
      2000,
      DefaultReserveRatio,
      block.timestamp + 2 weeks
    );
  }

  function test_setAnnualInterestAndReserveRatioBips_Decrease_Decrease() public {
    uint256 expiry = block.timestamp + 2 weeks;
    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioActivated(
      address(market),
      DefaultReserveRatio,
      6_000,
      expiry
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(700, 0);
    _checkTemporaryReserveRatioAndMarketBips(
      700,
      DefaultInterest,
      6_000,
      DefaultReserveRatio,
      expiry
    );

    fastForward(1 weeks);

    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioUpdated(
      address(market),
      DefaultReserveRatio,
      8_000,
      expiry + 1 weeks
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(600, 0);
    _checkTemporaryReserveRatioAndMarketBips(
      600,
      DefaultInterest,
      8_000,
      DefaultReserveRatio,
      expiry + 1 weeks
    );
  }

  function test_setAnnualInterestAndReserveRatioBips_Decrease_Increase() public {
    uint256 expiry = block.timestamp + 2 weeks;
    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioActivated(
      address(market),
      DefaultReserveRatio,
      5_020,
      expiry
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(749, 0);

    _checkTemporaryReserveRatioAndMarketBips(
      749,
      DefaultInterest,
      5_020,
      DefaultReserveRatio,
      expiry
    );

    fastForward(1 weeks);

    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioUpdated(
      address(market),
      DefaultReserveRatio,
      2_000,
      expiry
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(850, 0);
    _checkTemporaryReserveRatioAndMarketBips(
      850,
      DefaultInterest,
      DefaultReserveRatio,
      DefaultReserveRatio,
      expiry
    );
  }

  function test_setAnnualInterestAndReserveRatioBips_MaxReserveRatio() public {
    uint256 expiry = block.timestamp + 2 weeks;
    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioActivated(
      address(market),
      DefaultReserveRatio,
      10_000,
      expiry
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(400, 0);

    _checkTemporaryReserveRatioAndMarketBips(
      400,
      DefaultInterest,
      10_000,
      DefaultReserveRatio,
      expiry
    );
  }

  function test_setAnnualInterestAndReserveRatioBips_Decrease_Cancel() public {
    uint256 expiry = block.timestamp + 2 weeks;
    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioActivated(
      address(market),
      DefaultReserveRatio,
      6_000,
      expiry
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(700, 0);

    _checkTemporaryReserveRatioAndMarketBips(
      700,
      DefaultInterest,
      6_000,
      DefaultReserveRatio,
      expiry
    );

    fastForward(1 weeks);

    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioCanceled(address(market));
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(1_001, 0);
    _checkTemporaryReserveRatioAndMarketBips(1_001, 0, DefaultReserveRatio, 0, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_Decrease_Expire() public {
    uint256 expiry = block.timestamp + 2 weeks;
    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioActivated(
      address(market),
      DefaultReserveRatio,
      6_000,
      expiry
    );
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(700, 0);

    _checkTemporaryReserveRatioAndMarketBips(
      700,
      DefaultInterest,
      6_000,
      DefaultReserveRatio,
      expiry
    );

    fastForward(2 weeks);

    vm.expectEmit(address(hooks));
    emit MarketConstraintHooks.TemporaryExcessReserveRatioExpired(address(market));
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(700, 0);
    _checkTemporaryReserveRatioAndMarketBips(700, 0, DefaultReserveRatio, 0, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_Decrease_Undercollateralized() public {
    _deposit(alice, 50_000e18);
    vm.prank(borrower);
    market.borrow(5_000e18 + 1);

    vm.startPrank(borrower);
    vm.expectRevert(IMarketEventsAndErrors.InsufficientReservesForNewLiquidityRatio.selector);
    market.setAnnualInterestAndReserveRatioBips(550, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_AprChangeOnClosedMarket()
    public
    asAccount(borrower)
  {
    market.closeMarket();
    vm.expectRevert(AprChangeOnClosedMarket.selector);
    market.setAnnualInterestAndReserveRatioBips(550, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_Increase() public {
    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(DefaultInterest + 1, 0);

    _checkTemporaryReserveRatioAndMarketBips(DefaultInterest + 1, 0, DefaultReserveRatio, 0, 0);
  }

  function test_setAnnualInterestAndReserveRatioBips_Increase_Undercollateralized() public {
    _deposit(alice, 50_000e18);
    vm.prank(borrower);
    market.borrow(5_000e18 + 1);

    vm.prank(borrower);
    market.setAnnualInterestAndReserveRatioBips(DefaultInterest, 0 + 1);
  }

  function _checkTemporaryReserveRatioAndMarketBips(
    uint256 annualInterestBips,
    uint256 originalAnnualInterestBips,
    uint256 reserveRatioBips,
    uint256 originalReserveRatioBips,
    uint256 temporaryReserveRatioExpiry
  ) internal view {
    (uint256 _originalAnnualInterestBips, uint256 _originalReserveRatioBips, uint256 expiry) = hooks
      .temporaryExcessReserveRatio(address(market));

    assertEq(market.annualInterestBips(), annualInterestBips, 'annualInterestBips');
    assertEq(market.reserveRatioBips(), reserveRatioBips, 'reserveRatioBips');

    assertEq(_originalAnnualInterestBips, originalAnnualInterestBips, 'originalAnnualInterestBips');
    assertEq(_originalReserveRatioBips, originalReserveRatioBips, 'originalReserveRatioBips');
    assertEq(expiry, temporaryReserveRatioExpiry, 'temporaryReserveRatioExpiry');
  }

  // ========================================================================== //
  //                             setProtocolFeeBips                             //
  // ========================================================================== //

  function test_setProtocolFeeBips(
    uint16 _protocolFeeBips
  ) external asAccount(address(hooksFactory)) {
    // max = 999 because it must not match the current fee, which is 1000 by default
    _protocolFeeBips = uint16(bound(_protocolFeeBips, 0, 999));
    vm.expectEmit(address(market));
    emit IMarketEventsAndErrors.ProtocolFeeBipsUpdated(_protocolFeeBips);
    market.setProtocolFeeBips(_protocolFeeBips);
    assertEq(market.previousState().protocolFeeBips, _protocolFeeBips, 'protocolFeeBips');
  }

  function test_setProtocolFeeBips_NotFactory() external {
    // max = 999 because it must not match the current fee, which is 1000 by default
    vm.expectRevert(IMarketEventsAndErrors.NotFactory.selector);
    market.setProtocolFeeBips(0);
  }

  function test_setProtocolFeeBips_ProtocolFeeTooHigh() external asAccount(address(hooksFactory)) {
    // max = 1001 because it must not match the current fee, which is 1000 by default
    vm.expectRevert(IMarketEventsAndErrors.ProtocolFeeTooHigh.selector);
    market.setProtocolFeeBips(1001);
  }

  function test_setProtocolFeeBips_ProtocolFeeNotChanged()
    external
    asAccount(address(hooksFactory))
  {
    vm.expectRevert(IMarketEventsAndErrors.ProtocolFeeNotChanged.selector);
    market.setProtocolFeeBips(DefaultProtocolFeeBips);
  }

  function test_setProtocolFeeBips_ProtocolFeeChangeOnClosedMarket() external {
    vm.prank(borrower);
    market.closeMarket();
    vm.prank(address(hooksFactory));
    vm.expectRevert(IMarketEventsAndErrors.ProtocolFeeChangeOnClosedMarket.selector);
    market.setProtocolFeeBips(0);
  }
}
