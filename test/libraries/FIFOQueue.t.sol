// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'forge-std/Test.sol';
import 'src/libraries/FIFOQueue.sol';
import './wrappers/FIFOQueueLibExternal.sol';

// Uses an external wrapper library to make forge coverage work for FIFOQueueLib.
// Forge is currently incapable of mapping MemberAccess function calls with
// expressions other than library identifiers (e.g. value.x() vs XLib.x(value))
// to the correct FunctionDefinition nodes.
contract FIFOQueueTest is Test {
  FIFOQueue internal arr;

  using FIFOQueueLibExternal for FIFOQueue;

  function test_empty() external {
    assertEq(arr.$empty(), true);
    arr.$push(1);
    assertEq(arr.$empty(), false);
    arr.$shift();
    assertEq(arr.$empty(), true);
  }

  function test() external {
    arr.$push(1);
    arr.$push(2);
    arr.$push(3);
    arr.$shift();
    arr.$push(4);
    arr.$shiftN(2);
    assertEq(arr.$length(), 1);
    assertEq(arr.$first(), 4);
    assertEq(arr.$at(0), 4);
  }

  function test_push() external {
    assertEq(arr.$length(), 0);
    arr.$push(1);
    assertEq(arr.$length(), 1);
    assertEq(arr.$first(), 1);
    assertEq(arr.$at(0), 1);
    assertEq(arr.startIndex, 0);
    assertEq(arr.nextIndex, 1);
  }

  function test_shift() external {
    arr.$push(1);
    arr.$shift();
    assertEq(arr.startIndex, 1);
    assertEq(arr.nextIndex, 1);
  }

  function test_shift_OutOfBounds() external {
    arr.$push(1);
    arr.$shift();
    assertEq(arr.startIndex, 1);
    assertEq(arr.nextIndex, 1);
    vm.expectRevert(FIFOQueueLibExternal.FIFOQueueOutOfBounds.selector);
    arr.$shift();
  }

  function test_shiftN() external {
    arr.$push(1);
    arr.$push(1);
    arr.$push(1);
    arr.$shiftN(2);
    assertEq(arr.$length(), 1);
    assertEq(arr.startIndex, 2);
    assertEq(arr.nextIndex, 3);
  }

  function test_shiftN_OutOfBounds() external {
    arr.$push(1);
    vm.expectRevert(FIFOQueueLibExternal.FIFOQueueOutOfBounds.selector);
    arr.$shiftN(2);
  }

  function test_first() external {
    arr.$push(1);
    assertEq(arr.$first(), 1);
  }

  function test_first_OutOfBounds() external {
    vm.expectRevert(FIFOQueueLibExternal.FIFOQueueOutOfBounds.selector);
    arr.$first();
  }

  function test_at() external {
    arr.$push(1);
    assertEq(arr.$at(0), 1);
    arr.$push(2);
    arr.$shift();
    assertEq(arr.$at(0), 2);
  }

  function test_at_OutOfBounds() external {
    vm.expectRevert(FIFOQueueLibExternal.FIFOQueueOutOfBounds.selector);
    arr.$at(0);
  }

  function test_values() external {
    assertEq(arr.$values().length, 0);
    uint32[] memory _arr = new uint32[](3);
    _arr[0] = 1;
    _arr[1] = 2;
    _arr[2] = 3;
    arr.$push(1);
    arr.$push(2);
    arr.$push(3);
    assertEq(arr.$values(), _arr);
  }

  function assertEq(uint32[] memory a, uint32[] memory b) internal {
    assertEq(a.length, b.length, 'length');
    for (uint256 i = 0; i < a.length; i++) {
      assertEq(a[i], b[i]);
    }
  }
}
