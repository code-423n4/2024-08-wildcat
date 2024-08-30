// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './Errors.sol';

uint256 constant BIP = 1e4;
uint256 constant HALF_BIP = 0.5e4;

uint256 constant RAY = 1e27;
uint256 constant HALF_RAY = 0.5e27;

uint256 constant BIP_RAY_RATIO = 1e23;

uint256 constant SECONDS_IN_365_DAYS = 365 days;

library MathUtils {
  /// @dev The multiply-divide operation failed, either due to a
  /// multiplication overflow, or a division by a zero.
  error MulDivFailed();

  using MathUtils for uint256;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   *
   * @param rateBip The interest rate, in bips
   * @param timeDelta The time elapsed since the last interest accrual
   * @return result The interest rate linearly accumulated during the timeDelta, in ray
   */
  function calculateLinearInterestFromBips(
    uint256 rateBip,
    uint256 timeDelta
  ) internal pure returns (uint256 result) {
    uint256 rate = rateBip.bipToRay();
    uint256 accumulatedInterestRay = rate * timeDelta;
    unchecked {
      return accumulatedInterestRay / SECONDS_IN_365_DAYS;
    }
  }

  /**
   * @dev Return the smaller of `a` and `b`
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = ternary(a < b, a, b);
  }

  /**
   * @dev Return the larger of `a` and `b`.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = ternary(a < b, b, a);
  }

  /**
   * @dev Saturation subtraction. Subtract `b` from `a` and return the result
   *      if it is positive or zero if it underflows.
   */
  function satSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    assembly {
      // (a > b) * (a - b)
      // If a-b underflows, the product will be zero
      c := mul(gt(a, b), sub(a, b))
    }
  }

  /**
   * @dev Saturation addition. Add `a` to `b` and return the result
   *      if it is less than `maxValue` or `maxValue` if it overflows.
   */
  function satAdd(uint256 a, uint256 b, uint256 maxValue) internal pure returns (uint256 c) {
    unchecked {
      c = a + b;
      return ternary(c < maxValue, c, maxValue);
    }
  }

  /**
   * @dev Return `valueIfTrue` if `condition` is true and `valueIfFalse` if it is false.
   *      Equivalent to `condition ? valueIfTrue : valueIfFalse`
   */
  function ternary(
    bool condition,
    uint256 valueIfTrue,
    uint256 valueIfFalse
  ) internal pure returns (uint256 c) {
    assembly {
      c := add(valueIfFalse, mul(condition, sub(valueIfTrue, valueIfFalse)))
    }
  }

  /**
   * @dev Multiplies two bip, rounding half up to the nearest bip
   *      see https://twitter.com/transmissions11/status/1451131036377571328
   */
  function bipMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    assembly {
      // equivalent to `require(b == 0 || a <= (type(uint256).max - HALF_BIP) / b)`
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_BIP), b))))) {
        // Store the Panic error signature.
        mstore(0, Panic_ErrorSelector)
        // Store the arithmetic (0x11) panic code.
        mstore(Panic_ErrorCodePointer, Panic_Arithmetic)
        // revert(abi.encodeWithSignature("Panic(uint256)", 0x11))
        revert(Error_SelectorPointer, Panic_ErrorLength)
      }

      c := div(add(mul(a, b), HALF_BIP), BIP)
    }
  }

  /**
   * @dev Divides two bip, rounding half up to the nearest bip
   *      see https://twitter.com/transmissions11/status/1451131036377571328
   */
  function bipDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    assembly {
      // equivalent to `require(b != 0 && a <= (type(uint256).max - b/2) / BIP)`
      if or(iszero(b), gt(a, div(sub(not(0), div(b, 2)), BIP))) {
        mstore(0, Panic_ErrorSelector)
        mstore(Panic_ErrorCodePointer, Panic_Arithmetic)
        revert(Error_SelectorPointer, Panic_ErrorLength)
      }

      c := div(add(mul(a, BIP), div(b, 2)), b)
    }
  }

  /**
   * @dev Converts bip up to ray
   */
  function bipToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/BIP_RAY_RATIO == a
    assembly {
      b := mul(a, BIP_RAY_RATIO)
      // equivalent to `require((b = a * BIP_RAY_RATIO) / BIP_RAY_RATIO == a )
      if iszero(eq(div(b, BIP_RAY_RATIO), a)) {
        mstore(0, Panic_ErrorSelector)
        mstore(Panic_ErrorCodePointer, Panic_Arithmetic)
        revert(Error_SelectorPointer, Panic_ErrorLength)
      }
    }
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   *      see https://twitter.com/transmissions11/status/1451131036377571328
   */
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    assembly {
      // equivalent to `require(b == 0 || a <= (type(uint256).max - HALF_RAY) / b)`
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        mstore(0, Panic_ErrorSelector)
        mstore(Panic_ErrorCodePointer, Panic_Arithmetic)
        revert(Error_SelectorPointer, Panic_ErrorLength)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @dev Divide two ray, rounding half up to the nearest ray
   *      see https://twitter.com/transmissions11/status/1451131036377571328
   */
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    assembly {
      // equivalent to `require(b != 0 && a <= (type(uint256).max - halfB) / RAY)`
      if or(iszero(b), gt(a, div(sub(not(0), div(b, 2)), RAY))) {
        mstore(0, Panic_ErrorSelector)
        mstore(Panic_ErrorCodePointer, Panic_Arithmetic)
        revert(Error_SelectorPointer, Panic_ErrorLength)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Returns `floor(x * y / d)`.
   *      Reverts if `x * y` overflows, or `d` is zero.
   * @custom:author solady/src/utils/FixedPointMathLib.sol
   */
  function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
    assembly {
      // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
      if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
        // Store the function selector of `MulDivFailed()`.
        mstore(0x00, 0xad251c27)
        // Revert with (offset, size).
        revert(0x1c, 0x04)
      }
      z := div(mul(x, y), d)
    }
  }

  /**
   * @dev Returns `ceil(x * y / d)`.
   *      Reverts if `x * y` overflows, or `d` is zero.
   * @custom:author solady/src/utils/FixedPointMathLib.sol
   */
  function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
    assembly {
      // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
      if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
        // Store the function selector of `MulDivFailed()`.
        mstore(0x00, 0xad251c27)
        // Revert with (offset, size).
        revert(0x1c, 0x04)
      }
      z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
    }
  }
}
