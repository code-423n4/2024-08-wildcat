// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import { SanctionsList } from '../TestConstants.sol';
import '../../helpers/VmUtils.sol' as VmUtils;

contract MockChainalysis {
  mapping(address => bool) public isSanctioned;

  function sanction(address account) external {
    isSanctioned[account] = true;
  }

  function unsanction(address account) external {
    isSanctioned[account] = false;
  }
}

function deployMockChainalysis() {
  VmUtils.vm.etch(address(SanctionsList), type(MockChainalysis).runtimeCode);
}
