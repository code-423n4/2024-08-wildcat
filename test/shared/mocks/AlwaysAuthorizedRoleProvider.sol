// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'src/access/IRoleProvider.sol';

contract AlwaysAuthorizedRoleProvider is IRoleProvider {
  function isPullProvider() external pure override returns (bool) {
    return true;
  }

  function getCredential(address) external view override returns (uint32 timestamp) {
    return uint32(block.timestamp);
  }

  function validateCredential(
    address,
    bytes calldata
  ) external view override returns (uint32 timestamp) {
    return uint32(block.timestamp);
  }
}
