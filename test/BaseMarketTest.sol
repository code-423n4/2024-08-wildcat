// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';

import './shared/Test.sol';
import './helpers/VmUtils.sol';
import './helpers/ExpectedStateTracker.sol';

contract BaseMarketTest is Test, ExpectedStateTracker {
  using stdStorage for StdStorage;
  using FeeMath for MarketState;
  using SafeCastLib for uint256;

  MockERC20 internal asset;

  address internal wildcatController = address(0x69);
  address internal wlUser = address(0x42);
  address internal nonwlUser = address(0x43);

  function setUp() public virtual {
    setUpContracts(false);
  }

  function setUpContracts(bool authorizeAll) internal {
    MarketInputParameters memory inputs = parameters;
    if (address(hooks) == address(0)) {
      deployHooksInstance(inputs, authorizeAll);
    }

    inputs.asset = address(asset = new MockERC20('Token', 'TKN', 18));
    deployMarket(inputs);
    parameters = inputs;
    hooks = AccessControlHooks(parameters.hooksConfig.hooksAddress());
    _authorizeLender(alice);
    previousState = MarketState({
      isClosed: false,
      maxTotalSupply: inputs.maxTotalSupply,
      scaledTotalSupply: 0,
      isDelinquent: false,
      timeDelinquent: 0,
      reserveRatioBips: inputs.reserveRatioBips,
      annualInterestBips: inputs.annualInterestBips,
      protocolFeeBips: inputs.protocolFeeBips,
      scaleFactor: uint112(RAY),
      lastInterestAccruedTimestamp: uint32(block.timestamp),
      scaledPendingWithdrawals: 0,
      pendingWithdrawalExpiry: 0,
      normalizedUnclaimedWithdrawals: 0,
      accruedProtocolFees: 0
    });
    lastTotalAssets = 0;

    asset.mint(alice, type(uint128).max);
    asset.mint(bob, type(uint128).max);

    _approve(alice, address(market), type(uint256).max);
    _approve(bob, address(market), type(uint256).max);
  }

  function resetWithMockHooks() internal asSelf {
    parameters.hooksTemplate = LibStoredInitCode.deployInitCode(type(MockHooks).creationCode);
    hooksFactory.addHooksTemplate(
      parameters.hooksTemplate,
      'MockHooks',
      address(0),
      address(0),
      0,
      0
    );
    hooks = AccessControlHooks(address(0));
    parameters.deployHooksConstructorArgs = abi.encode(address(this), '');
    parameters.hooksConfig = EmptyHooksConfig;
    setUpContracts(false);
  }

  function _authorizeLender(address account) internal asAccount(parameters.borrower) {
    vm.expectEmit(address(hooks));
    emit AccessControlHooks.AccountAccessGranted(
      parameters.borrower,
      account,
      uint32(block.timestamp)
    );
    hooks.grantRole(account, uint32(block.timestamp));
  }

  function _deauthorizeLender(address account) internal asAccount(parameters.borrower) {
    vm.expectEmit(address(hooks));
    emit AccessControlHooks.AccountAccessRevoked(account);
    hooks.revokeRole(account);
  }

  function _blockLender(address account) internal asAccount(parameters.borrower) {
    vm.expectEmit(address(hooks));
    emit AccessControlHooks.AccountBlockedFromDeposits(account);
    hooks.blockFromDeposits(account);
  }

  function _depositBorrowWithdraw(
    address from,
    uint256 depositAmount,
    uint256 borrowAmount,
    uint256 withdrawalAmount
  ) internal asAccount(from) {
    _deposit(from, depositAmount);
    // Borrow 80% of market assets
    _borrow(borrowAmount);
    // Withdraw 100% of deposits
    _requestWithdrawal(from, withdrawalAmount);
  }

  function _deposit(
    address from,
    uint256 amount,
    bool preAuthorizeLender
  ) internal asAccount(from) returns (uint256) {
    if (preAuthorizeLender) _authorizeLender(from);
    MarketState memory state = pendingState();
    (uint256 currentScaledBalance, uint256 currentBalance) = _getBalance(state, from);
    asset.mint(from, amount);
    asset.approve(address(market), amount);
    (uint104 scaledAmount, uint256 expectedNormalizedAmount) = _trackDeposit(state, from, amount);
    uint256 actualNormalizedAmount = market.depositUpTo(amount);
    assertEq(actualNormalizedAmount, expectedNormalizedAmount, 'Actual amount deposited');
    _checkState(state);
    assertEq(market.balanceOf(from), currentBalance + amount);
    assertEq(market.scaledBalanceOf(from), currentScaledBalance + scaledAmount);
    return actualNormalizedAmount;
  }

  function _deposit(address from, uint256 amount) internal returns (uint256) {
    return _deposit(from, amount, true);
  }

  function _requestWithdrawal(address from, uint256 amount) internal asAccount(from) {
    MarketState memory state = pendingState();
    (uint256 currentScaledBalance, uint256 currentBalance) = _getBalance(state, from);
    (, uint104 scaledAmount) = _trackQueueWithdrawal(state, from, amount);
    market.queueWithdrawal(amount);
    _checkState(state);
    assertApproxEqAbs(
      market.balanceOf(from),
      currentBalance - amount,
      1,
      unicode'balance after withdrawal (± 1)'
    );
    assertEq(
      market.balanceOf(from),
      state.normalizeAmount(currentScaledBalance - scaledAmount),
      'balance after withdrawal (exact)'
    );
    assertEq(
      market.scaledBalanceOf(from),
      currentScaledBalance - scaledAmount,
      'scaledBalance after withdrawal'
    );
  }

  function _requestFullWithdrawal(address from) internal asAccount(from) {
    MarketState memory state = pendingState();
    (uint256 currentScaledBalance, uint256 currentBalance) = _getBalance(state, from);
    (, uint104 scaledAmount) = _trackQueueWithdrawal(state, from, currentBalance);
    market.queueFullWithdrawal();
    _checkState(state);
    assertEq(market.balanceOf(from), 0, 'balance after withdrawal (exact)');
    assertEq(market.scaledBalanceOf(from), 0, 'scaledBalance after withdrawal');
  }

  function _closeMarket() internal asAccount(borrower) {
    uint owed = market.totalDebts() - market.totalAssets();
    asset.mint(borrower, owed);
    asset.approve(address(market), owed);
    MarketState memory state = pendingState();
    _trackCloseMarket(state, true);
    market.closeMarket();
    _checkState(state);
  }

  function _borrow(uint256 amount) internal asAccount(borrower) {
    MarketState memory state = pendingState();

    _trackBorrow(amount);
    market.borrow(amount);
    _checkState(state);
  }

  function _approve(address from, address to, uint256 amount) internal asAccount(from) {
    asset.approve(to, amount);
  }
}
