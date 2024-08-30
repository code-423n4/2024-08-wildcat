// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

interface IWildcatArchController {
  error NotMarketFactory();

  error NotControllerFactory();

  function owner() external view returns (address);

  // ========================================================================== //
  //                               SphereX Config                               //
  // ========================================================================== //

  event ChangedSpherexOperator(address oldSphereXAdmin, address newSphereXAdmin);

  event ChangedSpherexEngineAddress(address oldEngineAddress, address newEngineAddress);

  event SpherexAdminTransferStarted(address currentAdmin, address pendingAdmin);

  event SpherexAdminTransferCompleted(address oldAdmin, address newAdmin);

  event NewAllowedSenderOnchain(address sender);

  error SphereXOperatorRequired();

  error SphereXAdminRequired();

  error SphereXOperatorOrAdminRequired();

  error SphereXNotPendingAdmin();

  error SphereXNotEngine();

  function pendingSphereXAdmin() external view returns (address);

  function sphereXAdmin() external view returns (address);

  function sphereXOperator() external view returns (address);

  function sphereXEngine() external view returns (address);

  function transferSphereXAdminRole(address newAdmin) external virtual;

  function acceptSphereXAdminRole() external virtual;

  function changeSphereXOperator(address newSphereXOperator) external;

  function changeSphereXEngine(address newSphereXEngine) external;

  // ========================================================================== //
  //                         Controller Factory Registry                        //
  // ========================================================================== //

  event ControllerFactoryAdded(address);

  event ControllerFactoryRemoved(address);

  function getRegisteredControllerFactories() external view returns (address[] memory);

  function getRegisteredControllerFactories(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);

  function getRegisteredControllerFactoriesCount() external view returns (uint256);

  function isRegisteredControllerFactory(address factory) external view returns (bool);

  function registerControllerFactory(address factory) external;

  function removeControllerFactory(address factory) external;

  // ========================================================================== //
  //                             Controller Registry                            //
  // ========================================================================== //

  event ControllerAdded(address, address);

  event ControllerRemoved(address);

  function getRegisteredControllers() external view returns (address[] memory);

  function getRegisteredControllers(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);

  function getRegisteredControllersCount() external view returns (uint256);

  function isRegisteredController(address controller) external view returns (bool);

  function registerController(address controller) external;

  function removeController(address controller) external;

  // ========================================================================== //
  //                             Borrowers Registry                             //
  // ========================================================================== //

  event BorrowerAdded(address);

  event BorrowerRemoved(address);

  function getRegisteredBorrowers() external view returns (address[] memory);

  function getRegisteredBorrowers(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);

  function getRegisteredBorrowersCount() external view returns (uint256);

  function isRegisteredBorrower(address borrower) external view returns (bool);

  function registerBorrower(address borrower) external;

  function removeBorrower(address borrower) external;

  // ========================================================================== //
  //                          Asset Blacklist Registry                          //
  // ========================================================================== //

  event AssetPermitted();

  event AssetBlacklisted();

  function addBlacklist(address asset) external;

  function removeBlacklist(address asset) external;

  function isBlacklistedAsset(address asset) external view returns (bool);

  function getBlacklistedAssets() external view returns (address[] memory);

  function getBlacklistedAssets(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);

  function getBlacklistedAssetsCount() external view returns (uint256);

  // ========================================================================== //
  //                               Markets Registry                             //
  // ========================================================================== //

  event MarketAdded(address, address);

  event MarketRemoved(address);

  function getRegisteredMarkets() external view returns (address[] memory);

  function getRegisteredMarkets(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory);

  function getRegisteredMarketsCount() external view returns (uint256);

  function isRegisteredMarket(address market) external view returns (bool);

  function registerMarket(address market) external;

  function removeMarket(address market) external;
}
