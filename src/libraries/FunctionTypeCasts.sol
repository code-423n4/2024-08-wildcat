// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import { MarketParameters } from '../interfaces/WildcatStructsAndEnums.sol';
import { MarketState } from '../libraries/MarketState.sol';
import { WithdrawalBatch } from '../libraries/Withdrawal.sol';

/**
 * @dev Type-casts to convert functions returning raw (uint) pointers
 *      to functions returning memory pointers of specific types.
 *
 *      Used to get around solc's over-allocation of memory when
 *      dynamic return parameters are re-assigned.
 *
 *      With `viaIR` enabled, calling any of these functions is a noop.
 */
library FunctionTypeCasts {
  /**
   * @dev Function type cast to avoid duplicate declaration/allocation
   *      of MarketState return parameter.
   */
  function asReturnsMarketState(
    function() internal view returns (uint256) fnIn
  ) internal pure returns (function() internal view returns (MarketState memory) fnOut) {
    assembly {
      fnOut := fnIn
    }
  }

  /**
   * @dev Function type cast to avoid duplicate declaration/allocation
   *      of MarketState and WithdrawalBatch return parameters.
   */
  function asReturnsPointers(
    function() internal view returns (MarketState memory, uint32, WithdrawalBatch memory) fnIn
  ) internal pure returns (function() internal view returns (uint256, uint32, uint256) fnOut) {
    assembly {
      fnOut := fnIn
    }
  }

  /**
   * @dev Function type cast to avoid duplicate declaration/allocation
   *      of manually allocated MarketParameters in market constructor.
   */
  function asReturnsMarketParameters(
    function() internal view returns (uint256) fnIn
  ) internal pure returns (function() internal view returns (MarketParameters memory) fnOut) {
    assembly {
      fnOut := fnIn
    }
  }
}
