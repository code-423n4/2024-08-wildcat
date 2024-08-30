// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './Errors.sol';

library SafeCastLib {
  function _assertNonOverflow(bool didNotOverflow) private pure {
    assembly {
      if iszero(didNotOverflow) {
        mstore(0, Panic_ErrorSelector)
        mstore(Panic_ErrorCodePointer, Panic_Arithmetic)
        revert(Error_SelectorPointer, Panic_ErrorLength)
      }
    }
  }

  function toUint8(uint256 x) internal pure returns (uint8 y) {
    _assertNonOverflow(x == (y = uint8(x)));
  }

  function toUint16(uint256 x) internal pure returns (uint16 y) {
    _assertNonOverflow(x == (y = uint16(x)));
  }

  function toUint24(uint256 x) internal pure returns (uint24 y) {
    _assertNonOverflow(x == (y = uint24(x)));
  }

  function toUint32(uint256 x) internal pure returns (uint32 y) {
    _assertNonOverflow(x == (y = uint32(x)));
  }

  function toUint40(uint256 x) internal pure returns (uint40 y) {
    _assertNonOverflow(x == (y = uint40(x)));
  }

  function toUint48(uint256 x) internal pure returns (uint48 y) {
    _assertNonOverflow(x == (y = uint48(x)));
  }

  function toUint56(uint256 x) internal pure returns (uint56 y) {
    _assertNonOverflow(x == (y = uint56(x)));
  }

  function toUint64(uint256 x) internal pure returns (uint64 y) {
    _assertNonOverflow(x == (y = uint64(x)));
  }

  function toUint72(uint256 x) internal pure returns (uint72 y) {
    _assertNonOverflow(x == (y = uint72(x)));
  }

  function toUint80(uint256 x) internal pure returns (uint80 y) {
    _assertNonOverflow(x == (y = uint80(x)));
  }

  function toUint88(uint256 x) internal pure returns (uint88 y) {
    _assertNonOverflow(x == (y = uint88(x)));
  }

  function toUint96(uint256 x) internal pure returns (uint96 y) {
    _assertNonOverflow(x == (y = uint96(x)));
  }

  function toUint104(uint256 x) internal pure returns (uint104 y) {
    _assertNonOverflow(x == (y = uint104(x)));
  }

  function toUint112(uint256 x) internal pure returns (uint112 y) {
    _assertNonOverflow(x == (y = uint112(x)));
  }

  function toUint120(uint256 x) internal pure returns (uint120 y) {
    _assertNonOverflow(x == (y = uint120(x)));
  }

  function toUint128(uint256 x) internal pure returns (uint128 y) {
    _assertNonOverflow(x == (y = uint128(x)));
  }

  function toUint136(uint256 x) internal pure returns (uint136 y) {
    _assertNonOverflow(x == (y = uint136(x)));
  }

  function toUint144(uint256 x) internal pure returns (uint144 y) {
    _assertNonOverflow(x == (y = uint144(x)));
  }

  function toUint152(uint256 x) internal pure returns (uint152 y) {
    _assertNonOverflow(x == (y = uint152(x)));
  }

  function toUint160(uint256 x) internal pure returns (uint160 y) {
    _assertNonOverflow(x == (y = uint160(x)));
  }

  function toUint168(uint256 x) internal pure returns (uint168 y) {
    _assertNonOverflow(x == (y = uint168(x)));
  }

  function toUint176(uint256 x) internal pure returns (uint176 y) {
    _assertNonOverflow(x == (y = uint176(x)));
  }

  function toUint184(uint256 x) internal pure returns (uint184 y) {
    _assertNonOverflow(x == (y = uint184(x)));
  }

  function toUint192(uint256 x) internal pure returns (uint192 y) {
    _assertNonOverflow(x == (y = uint192(x)));
  }

  function toUint200(uint256 x) internal pure returns (uint200 y) {
    _assertNonOverflow(x == (y = uint200(x)));
  }

  function toUint208(uint256 x) internal pure returns (uint208 y) {
    _assertNonOverflow(x == (y = uint208(x)));
  }

  function toUint216(uint256 x) internal pure returns (uint216 y) {
    _assertNonOverflow(x == (y = uint216(x)));
  }

  function toUint224(uint256 x) internal pure returns (uint224 y) {
    _assertNonOverflow(x == (y = uint224(x)));
  }

  function toUint232(uint256 x) internal pure returns (uint232 y) {
    _assertNonOverflow(x == (y = uint232(x)));
  }

  function toUint240(uint256 x) internal pure returns (uint240 y) {
    _assertNonOverflow(x == (y = uint240(x)));
  }

  function toUint248(uint256 x) internal pure returns (uint248 y) {
    _assertNonOverflow(x == (y = uint248(x)));
  }
}
