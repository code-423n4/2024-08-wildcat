// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import { Vm, VmSafe } from 'forge-std/Vm.sol';
import { logAssume } from './Metrics.sol';

address constant VM_ADDRESS = address(uint160(uint256(keccak256('hevm cheat code'))));
address constant CLOCK_ADDRESS = address(uint160(uint256(keccak256('.clock'))));

Vm constant vm = Vm(VM_ADDRESS);

contract Clock {
  function time() external view returns (uint256) {
    assembly {
      mstore(0, timestamp())
      return(0, 0x20)
    }
  }
}

function getTimestamp() returns (uint256) {
  if (CLOCK_ADDRESS.code.length == 0) {
    vm.etch(CLOCK_ADDRESS, type(Clock).runtimeCode);
  }
  return Clock(CLOCK_ADDRESS).time();
}

function recordLogs() {
  vm.recordLogs();
}

function getRecordedLogs() returns (VmSafe.Log[] memory logs) {
  return vm.getRecordedLogs();
}

function assume(bool condition, string memory name) {
  if (!condition) {
    logAssume(name);
  }
  vm.assume(condition);
}

contract FastForward {
  constructor(uint256 time) {
    vm.warp(block.timestamp + time);
    assembly {
      selfdestruct(caller())
    }
  }
}

contract Warp {
  constructor(uint256 time) {
    vm.warp(time);
    assembly {
      selfdestruct(caller())
    }
  }
}

// Utility functions to get around stack optimizations by ir pipeline
// causing timestamp after warp to match timestamp before
function fastForward(uint256 time) {
  new FastForward(time);
}

function warp(uint256 time) {
  new Warp(time);
}

// dependent bound - bound value1 to the range [min, max]
// and bound value2 to the range [min, value1]
function dbound(
  uint256 value1,
  uint256 value2,
  uint256 min,
  uint256 max
) pure returns (uint256, uint256) {
  value1 = bound(value1, min, max);
  value2 = bound(value2, min, value1);
  return (value1, value2);
}

/// @custom:author Taken from ProjectOpenSea/seaport/test/foundry/new/helpers/FuzzTestContextLib.sol
/// @dev Implementation cribbed from forge-std bound
function bound(uint256 x, uint256 min, uint256 max) pure returns (uint256 result) {
  require(min <= max, 'Max is less than min.');
  // If x is between min and max, return x directly. This is to ensure that
  // dictionary values do not get shifted if the min is nonzero.
  if (x >= min && x <= max) return x;

  uint256 size = max - min + 1;

  // If the value is 0, 1, 2, 3, warp that to min, min+1, min+2, min+3.
  // Similarly for the UINT256_MAX side. This helps ensure coverage of the
  // min/max values.
  if (x <= 3 && size > x) return min + x;
  if (x >= type(uint256).max - 3 && size > type(uint256).max - x) {
    return max - (type(uint256).max - x);
  }

  // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
  if (x > max) {
    uint256 diff = x - max;
    uint256 rem = diff % size;
    if (rem == 0) return max;
    result = min + rem - 1;
  } else if (x < min) {
    uint256 diff = min - x;
    uint256 rem = diff % size;
    if (rem == 0) return min;
    result = max - rem + 1;
  }
}

uint256 constant TMP_PRANK_ARR_SLOT = uint256(keccak256('prank cache'));

struct PrankCache {
  bool recurring;
  address prank;
}

function safeStartPrank(address prank) {
  (VmSafe.CallerMode callerMode, address msgSender, ) = vm.readCallers();
  PrankCache[] storage prankArray;
  uint prankArraySlot = TMP_PRANK_ARR_SLOT;
  assembly {
    prankArray.slot := prankArraySlot
  }
  if (callerMode == VmSafe.CallerMode.Prank || callerMode == VmSafe.CallerMode.RecurrentPrank) {
    vm.stopPrank();
    prankArray.push(
      PrankCache({ recurring: callerMode == VmSafe.CallerMode.RecurrentPrank, prank: msgSender })
    );
  }
  vm.stopPrank();
  vm.startPrank(prank);
}

function safeStopPrank() {
  vm.stopPrank();
  PrankCache[] storage prankArray;
  uint prankArraySlot = TMP_PRANK_ARR_SLOT;
  assembly {
    prankArray.slot := prankArraySlot
  }
  if (prankArray.length > 0) {
    PrankCache memory cache = prankArray[prankArray.length - 1];
    if (cache.recurring) vm.startPrank(cache.prank);
    else vm.prank(cache.prank);
    prankArray.pop();
  }
}
