// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.20;

import { Test } from 'forge-std/Test.sol';
import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import { ERC20Handler, IERC20 } from './handlers/ERC20Handler.sol';

// import {WETH9} from "../src/WETH9.sol";

// import {Handler, ETH_SUPPLY} from "./handlers/Handler.sol";

contract ERC20Invariant is Test {
  MockERC20 public token;
  ERC20Handler public handler;

  function setUp() public {
    token = new MockERC20('', '', 18);
    handler = new ERC20Handler(IERC20(address(token)), 'ERC20 Invariants', 10);

    bytes4[] memory selectors = new bytes4[](5);
    selectors[0] = ERC20Handler.mint.selector;
    selectors[1] = ERC20Handler.burn.selector;
    // selectors[2] = ERC20Handler.sendFallback.selector;
    selectors[2] = ERC20Handler.approve.selector;
    selectors[3] = ERC20Handler.transfer.selector;
    selectors[4] = ERC20Handler.transferFrom.selector;
    //selectors[6] = Handler.forcePush.selector;

    targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));

    targetContract(address(handler));
  }

  // ETH can only be wrapped into WETH, WETH can only
  // be unwrapped back into ETH. The sum of the Handler's
  // ETH balance plus the WETH totalSupply() should always
  // equal the total ETH_SUPPLY.
  function invariant_supply() public {
    assertEq(token.totalSupply(), handler.ghost_mintSum() - handler.ghost_burnSum());
  }

  // // The WETH contract's Ether balance should always be
  // // at least as much as the sum of individual deposits
  // function invariant_solvencyDeposits() public {
  //     assertEq(
  //         address(weth).balance,
  //         handler.ghost_depositSum() + handler.ghost_forcePushSum() - handler.ghost_withdrawSum()
  //     );
  // }

  // // The WETH contract's Ether balance should always be
  // // at least as much as the sum of individual balances
  // function invariant_solvencyBalances() public {
  //     uint256 sumOfBalances = handler.reduceActors(0, this.accumulateBalance);
  //     assertEq(address(weth).balance - handler.ghost_forcePushSum(), sumOfBalances);
  // }

  // function accumulateBalance(uint256 balance, address caller) external view returns (uint256) {
  //     return balance + token.balanceOf(caller);
  // }

  // No individual account balance can exceed the
  // WETH totalSupply().
  function invariant_depositorBalances() public {
    handler.forEachActor(this.assertAccountBalanceLteTotalSupply);
  }

  function assertAccountBalanceLteTotalSupply(address account) external {
    assertLe(token.balanceOf(account), token.totalSupply());
  }

  function invariant_callSummary() public view {
    handler.callSummary();
  }
}
