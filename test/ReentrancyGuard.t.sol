// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/ReentrancyGuard.sol";

contract Reentrant is ReentrancyGuard {
  uint private i;
  function callSelfWithGuard(bool _stateful) external nonReentrant returns (uint) {
    if (_stateful) {
      return this.increment();
    } else {
      return this.getIndex();
    }
  }

  function callSelf(bool _stateful) external returns (uint) {
    if (_stateful) {
      return this.increment();
    } else {
      return this.getIndex();
    }
  }

  function increment() external nonReentrant returns (uint) {
    return i++;
  }

  function getIndex() external view nonReentrantView returns (uint) {
    return i;
  }
}

contract ReentrancyGuardView is Test {
  Reentrant private reentrant = new Reentrant();

  function testFunctions() external {
    assertEq(reentrant.getIndex(), 0);
    assertEq(reentrant.increment(), 0);
    assertEq(reentrant.callSelf(true), 1);
    assertEq(reentrant.callSelf(false), 2);
  }

  function test_nonReentrant() external {
    vm.expectRevert(ReentrancyGuard.NoReentrantCalls.selector);
    reentrant.callSelfWithGuard(true);
  }

  function test_nonReentrantView() external {
    vm.expectRevert(ReentrancyGuard.NoReentrantCalls.selector);
    reentrant.callSelfWithGuard(false);
  }
}