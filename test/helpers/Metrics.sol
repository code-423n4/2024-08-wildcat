// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import { vm } from './VmUtils.sol';

function logCall(string memory name) {
  logCounter('call', name, true);
}

function logAssume(string memory name) {
  logCounter('assume', name, true);
}

function logCounter(string memory file, string memory metric, bool enabled) {
  if (enabled /* && vm.envOr("COLLECT_METRICS", false) */) {
    string memory counter = string.concat(metric, ':1|c');
    vm.writeLine(string.concat(file, '-metrics.txt'), counter);
  }
}
