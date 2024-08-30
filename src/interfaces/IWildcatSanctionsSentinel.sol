// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

interface IWildcatSanctionsSentinel {
  event NewSanctionsEscrow(
    address indexed borrower,
    address indexed account,
    address indexed asset
  );

  event SanctionOverride(address indexed borrower, address indexed account);

  event SanctionOverrideRemoved(address indexed borrower, address indexed account);

  struct TmpEscrowParams {
    address borrower;
    address account;
    address asset;
  }

  function WildcatSanctionsEscrowInitcodeHash() external pure returns (bytes32);

  // Returns immutable sanctions list contract
  function chainalysisSanctionsList() external view returns (address);

  // Returns immutable arch-controller
  function archController() external view returns (address);

  // Returns temporary escrow params
  function tmpEscrowParams()
    external
    view
    returns (address borrower, address account, address asset);

  // Returns result of `chainalysisSanctionsList().isSanctioned(account)`
  function isFlaggedByChainalysis(address account) external view returns (bool);

  // Returns result of `chainalysisSanctionsList().isSanctioned(account)`
  // if borrower has not overridden the status of `account`
  function isSanctioned(address borrower, address account) external view returns (bool);

  // Returns boolean indicating whether `borrower` has overridden the
  // sanction status of `account`
  function sanctionOverrides(address borrower, address account) external view returns (bool);

  function overrideSanction(address account) external;

  function removeSanctionOverride(address account) external;

  // Returns create2 address of sanctions escrow contract for
  // combination of `borrower,account,asset`
  function getEscrowAddress(
    address borrower,
    address account,
    address asset
  ) external view returns (address escrowContract);

  /**
   * @dev Returns a create2 deployment of WildcatSanctionsEscrow unique to each
   *      combination of `account,borrower,asset`. If the contract is already
   *      deployed, returns the existing address.
   *
   *      Emits `NewSanctionsEscrow(borrower, account, asset)` if a new contract
   *      is deployed.
   *
   *      The sanctions escrow contract is used to hold assets until either the
   *      sanctioned status is lifted or the assets are released by the borrower.
   */
  function createEscrow(
    address borrower,
    address account,
    address asset
  ) external returns (address escrowContract);
}
