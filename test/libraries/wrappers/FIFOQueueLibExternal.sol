// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'src/libraries/FIFOQueue.sol';

library FIFOQueueLibExternal {
  error FIFOQueueOutOfBounds();

  function $empty(FIFOQueue storage arr) external view returns (bool) {
    return FIFOQueueLib.empty(arr);
  }

  function $push(FIFOQueue storage self, uint32 value) external {
    FIFOQueueLib.push(self, value);
  }

  function $first(FIFOQueue storage self) external view returns (uint32) {
    return FIFOQueueLib.first(self);
  }

  function $at(FIFOQueue storage self, uint256 index) external view returns (uint32) {
    return FIFOQueueLib.at(self, index);
  }

  function $shift(FIFOQueue storage self) external {
    FIFOQueueLib.shift(self);
  }

  function $shiftN(FIFOQueue storage self, uint128 n) external {
    FIFOQueueLib.shiftN(self, n);
  }

  function $length(FIFOQueue storage self) external view returns (uint256) {
    return FIFOQueueLib.length(self);
  }

  function $values(FIFOQueue storage self) external view returns (uint32[] memory) {
    return FIFOQueueLib.values(self);
  }
}
