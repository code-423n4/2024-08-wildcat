// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import { BaseERC20Test } from '../helpers/BaseERC20Test.sol';
import '../shared/TestConstants.sol';
import '../BaseMarketTest.sol';

bytes32 constant DaiSalt = bytes32(uint256(1));

contract WildcatMarketTokenTest is BaseERC20Test, BaseMarketTest {
  using MarketStateLib for MarketState;

  function bound(
    uint x,
    uint min,
    uint max
  ) internal pure virtual override(StdUtils, Test) returns (uint256 result) {
    return Test.bound(x, min, max);
  }

  function _maxAmount() internal pure override returns (uint256) {
    return uint256(type(uint104).max);
  }

  function _minAmount() internal view override returns (uint256 min) {
    min = divUp(WildcatMarket(address(token)).scaleFactor(), RAY);
  }

  function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
    /// @solidity memory-safe-assembly
    assembly {
      if iszero(d) {
        // Store the function selector of `DivFailed()`.
        mstore(0x00, 0x65244e4e)
        // Revert with (offset, size).
        revert(0x1c, 0x04)
      }
      z := add(iszero(iszero(mod(x, d))), div(x, d))
    }
  }

  function setUp() public override(BaseERC20Test, BaseMarketTest) {
    parameters.maxTotalSupply = uint128(_maxAmount());
    parameters.annualInterestBips = 0;
    parameters.withdrawalBatchDuration = 0;
    parameters.hooksConfig = parameters.hooksConfig.clearFlag(Bit_Enabled_Transfer);
    BaseMarketTest.setUpContracts(true);
    token = IERC20(address(market));
    _name = 'Wildcat Token';
    _symbol = 'WCTKN';
    _decimals = 18;
  }

  function _mint(address to, uint256 amount) internal override {
    require(amount <= _maxAmount(), 'amount too large');
    vm.startPrank(to);
    asset.mint(to, amount);
    asset.mint(to, amount);
    // vm.startPrank(to);
    asset.approve(address(token), amount);
    WildcatMarket(address(token)).depositUpTo(amount);
    WildcatMarket(address(token)).transfer(to, amount);
    vm.stopPrank();
  }

  function _burn(address from, uint256 amount) internal override {
    vm.prank(from);
    WildcatMarket(address(token)).queueWithdrawal(amount);
    VmUtils.fastForward(1);
    WildcatMarket(address(token)).executeWithdrawal(from, uint32(block.timestamp - 1));
  }

  function testTransferNullAmount() external {
    vm.expectRevert(IMarketEventsAndErrors.NullTransferAmount.selector);
    token.transfer(address(1), 0);
  }

  function testTransferFromNullAmount() external {
    vm.expectRevert(IMarketEventsAndErrors.NullTransferAmount.selector);
    token.transferFrom(address(0), address(1), 0);
  }

  function testTransferToBlockedAccount() external {
    parameters.hooksConfig = parameters.hooksConfig.setFlag(Bit_Enabled_Transfer);
    BaseMarketTest.setUpContracts(true);
    _mint(alice, 1);
    _blockLender(bob);
    vm.expectRevert(IMarketEventsAndErrors.NotApprovedLender.selector);
    vm.prank(alice);
    market.transfer(bob, 1);
  }
}
