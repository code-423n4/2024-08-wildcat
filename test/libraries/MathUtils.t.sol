// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'forge-std/Test.sol';
import './wrappers/MathUtilsExternal.sol';

// Uses an external wrapper library to make forge coverage work for MathUtils.
// Forge is currently incapable of mapping MemberAccess function calls with
// expressions other than library identifiers (e.g. value.x() vs XLib.x(value))
// to the correct FunctionDefinition nodes.
contract MathUtilsExternalTest is Test {
  bytes4 constant Panic_ErrorSelector = 0x4e487b71;
  uint256 constant Panic_Arithmetic = 0x11;
  bytes internal ArithmeticError = abi.encodePacked(Panic_ErrorSelector, Panic_Arithmetic);

  function test_calculateLinearInterestFromBips(uint256 bips, uint256 delta) external {
    bips = bound(bips, 0, 10000);
    delta = bound(delta, 0, type(uint32).max);
    uint256 interest = delta == 0
      ? 0
      : (MathUtilsExternal.bipToRay(bips) * delta) / SECONDS_IN_365_DAYS;
    assertEq(MathUtilsExternal.calculateLinearInterestFromBips(bips, delta), interest);
  }

  function test_calculateLinearInterestFromBips() external {
    assertEq(MathUtilsExternal.calculateLinearInterestFromBips(1000, 365 days), 1e26);
  }

  function test_satSub(uint256 a, uint256 b) external {
    if (b > a) {
      assertEq(MathUtilsExternal.satSub(a, b), 0);
    } else {
      assertEq(MathUtilsExternal.satSub(a, b), a - b);
    }
  }

  function test_mulDiv(uint256 a, uint256 b, uint256 c) external {
    if (c == 0 || (b != 0 && a > (type(uint256).max / b))) {
      vm.expectRevert(MathUtilsExternal.MulDivFailed.selector);
      MathUtilsExternal.mulDiv(a, b, c);
    } else {
      assertEq(MathUtilsExternal.mulDiv(a, b, c), (a * b) / c);
    }
  }

  function test_mulDivUp(uint256 a, uint256 b, uint256 c) external {
    if (c != 0 && (b == 0 || a <= type(uint256).max / b)) {
      uint256 result = a == 0 || b == 0 ? 0 : (a * b - 1) / c + 1;
      assertEq(MathUtilsExternal.mulDivUp(a, b, c), result);
    } else {
      vm.expectRevert(MathUtilsExternal.MulDivFailed.selector);
      MathUtilsExternal.mulDivUp(a, b, c);
    }
  }

  function test_rayMul() external {
    assertEq(MathUtilsExternal.rayMul(RAY, RAY), RAY);
    assertEq(MathUtilsExternal.rayMul(100, 1.99e26), 20);
  }

  function test_rayMul(uint a, uint b) external {
    if (b == 0 || a <= (type(uint256).max - HALF_RAY) / b) {
      assertEq(MathUtilsExternal.rayMul(a, b), ((a * b) + HALF_RAY) / RAY);
    } else {
      vm.expectRevert(ArithmeticError);
      MathUtilsExternal.rayMul(a, b);
    }
  }

  function test_bipToRay() external {
    assertEq(MathUtilsExternal.bipToRay(BIP), RAY);
    vm.expectRevert(ArithmeticError);
    MathUtilsExternal.bipToRay((type(uint256).max / BIP_RAY_RATIO) + 1);
  }

  function test_bipToRay(uint256 a) external {
    unchecked {
      uint256 b;
      if ((b = a * BIP_RAY_RATIO) / BIP_RAY_RATIO == a) {
        assertEq(MathUtilsExternal.bipToRay(a), b);
      } else {
        vm.expectRevert(ArithmeticError);
        MathUtilsExternal.bipToRay(a);
      }
    }
  }

  function test_bipMul() external {
    assertEq(MathUtilsExternal.bipMul(BIP, BIP), BIP);
    assertEq(MathUtilsExternal.bipMul(100, 1999), 20);
  }

  function test_bipMul(uint a, uint b) external {
    if (b == 0 || a <= (type(uint256).max - HALF_BIP) / b) {
      assertEq(MathUtilsExternal.bipMul(a, b), ((a * b) + HALF_BIP) / BIP);
    } else {
      vm.expectRevert(ArithmeticError);
      MathUtilsExternal.bipMul(a, b);
    }
  }

  function test_bipDiv(uint256 a, uint256 b) external {
    if (b > 0 && a <= (type(uint256).max - (b / 2)) / BIP) {
      assertEq(MathUtilsExternal.bipDiv(a, b), ((a * BIP) + (b / 2)) / b);
    } else {
      vm.expectRevert(ArithmeticError);
      MathUtilsExternal.bipDiv(a, b);
    }
  }

  function test_max(uint256 a, uint256 b) external {
    assertEq(MathUtilsExternal.max(a, b), a > b ? a : b);
  }
}
