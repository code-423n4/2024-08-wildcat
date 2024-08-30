// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IRoleProvider {
  function isPullProvider() external view returns (bool);

  function getCredential(address account) external view returns (uint32 timestamp);

  /**
   * @dev Validate a credential (e.g. a signature from an access token granter) for an account.
   * @param account The account to validate the credential for.
   * @param data The data to validate the credential with.
   * @return timestamp The timestamp at which the credential was granted.
   */
  function validateCredential(address account, bytes calldata data) external returns (uint32 timestamp);
}
