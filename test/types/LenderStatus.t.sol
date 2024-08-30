// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'src/types/RoleProvider.sol';
import 'forge-std/Test.sol';
import '../helpers/Assertions.sol';

contract LenderStatusTest is Test, Assertions {
  function test_credentialExpired(
    StandardRoleProvider memory input,
    bool anyCredential,
    uint32 timestamp,
    uint32 lastApprovalTimestamp
  ) external {
    RoleProvider provider = input.toRoleProvider();
    LenderStatus memory status;
    vm.warp(timestamp);
    if (anyCredential) {
      status.lastApprovalTimestamp = lastApprovalTimestamp;
    }
  }
}
