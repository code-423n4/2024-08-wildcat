// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

library BoolUtils {
  function and(bool a, bool b) internal pure returns (bool c) {
    assembly {
      c := and(a, b)
    }
  }

  function or(bool a, bool b) internal pure returns (bool c) {
    assembly {
      c := or(a, b)
    }
  }

  function xor(bool a, bool b) internal pure returns (bool c) {
    assembly {
      c := xor(a, b)
    }
  }
}
