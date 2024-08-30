// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;
import './RoleProvider.sol';

/**
 * @param isBlockedFromDeposits   Whether the lender is blocked from depositing
 * @param lastProvider            The address of the last provider to grant the lender a credential
 * @param canRefresh              Whether the last provider can refresh the lender's credential
 * @param lastApprovalTimestamp   The timestamp at which the lender's credential was granted
 */
struct LenderStatus {
  bool isBlockedFromDeposits;
  address lastProvider;
  bool canRefresh;
  uint32 lastApprovalTimestamp;
}

using LibLenderStatus for LenderStatus global;

library LibLenderStatus {
  /**
   * @dev Returns whether the lender's credential has expired.
   *
   *      Note: Does not check if the lender has a credential - if the
   *      provider's TTL is greater than the current block timestamp,
   *      this function will always return false. Should always be used
   *      in conjunction with `hasCredential`.
   */
  function credentialExpired(
    LenderStatus memory status,
    RoleProvider provider
  ) internal view returns (bool) {
    return provider.calculateExpiry(status.lastApprovalTimestamp) < block.timestamp;
  }

  function hasCredential(LenderStatus memory status) internal pure returns (bool) {
    return status.lastApprovalTimestamp > 0;
  }

  /**
    * @dev Returns whether the lender's credential has not expired.
   *
   *      Note: Does not check if the lender has a credential - if the
   *      provider's TTL is greater than the current block timestamp,
   *      this function will always return true. Should always be used
   *      in conjunction with `hasCredential`.
   */
  function credentialNotExpired(
    LenderStatus memory status,
    RoleProvider provider
  ) internal view returns (bool) {
    return provider.calculateExpiry(status.lastApprovalTimestamp) >= block.timestamp;
  }

  function setCredential(
    LenderStatus memory status,
    RoleProvider provider,
    uint256 timestamp
  ) internal pure {
    // User is approved, update status with new expiry and last provider
    status.lastApprovalTimestamp = uint32(timestamp);
    status.lastProvider = provider.providerAddress();
    status.canRefresh = provider.isPullProvider();
  }

  function unsetCredential(LenderStatus memory status) internal pure {
    status.canRefresh = false;
    status.lastApprovalTimestamp = 0;
    status.lastProvider = address(0);
  }
}
