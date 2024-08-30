// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import { EnumerableSet } from 'openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import 'solady/auth/Ownable.sol';
import './spherex/SphereXConfig.sol';
import './libraries/MathUtils.sol';
import './interfaces/ISphereXProtectedRegisteredBase.sol';

contract WildcatArchController is SphereXConfig, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  // ========================================================================== //
  //                                   Storage                                  //
  // ========================================================================== //

  EnumerableSet.AddressSet internal _markets;
  EnumerableSet.AddressSet internal _controllerFactories;
  EnumerableSet.AddressSet internal _borrowers;
  EnumerableSet.AddressSet internal _controllers;
  EnumerableSet.AddressSet internal _assetBlacklist;

  // ========================================================================== //
  //                              Events and Errors                             //
  // ========================================================================== //

  error NotControllerFactory();
  error NotController();

  error BorrowerAlreadyExists();
  error ControllerFactoryAlreadyExists();
  error ControllerAlreadyExists();
  error MarketAlreadyExists();

  error BorrowerDoesNotExist();
  error AssetAlreadyBlacklisted();
  error ControllerFactoryDoesNotExist();
  error ControllerDoesNotExist();
  error AssetNotBlacklisted();
  error MarketDoesNotExist();

  event MarketAdded(address indexed controller, address market);
  event MarketRemoved(address market);

  event ControllerFactoryAdded(address controllerFactory);
  event ControllerFactoryRemoved(address controllerFactory);

  event BorrowerAdded(address borrower);
  event BorrowerRemoved(address borrower);

  event AssetBlacklisted(address asset);
  event AssetPermitted(address asset);

  event ControllerAdded(address indexed controllerFactory, address controller);
  event ControllerRemoved(address controller);

  // ========================================================================== //
  //                                 Constructor                                //
  // ========================================================================== //

  constructor() SphereXConfig(msg.sender, address(0), address(0)) {
    _initializeOwner(msg.sender);
  }

  // ========================================================================== //
  //                            SphereX Engine Update                           //
  // ========================================================================== //

  /**
   * @dev Update SphereX engine on registered contracts and add them as
   *      allowed senders on the engine contract.
   */
  function updateSphereXEngineOnRegisteredContracts(
    address[] calldata controllerFactories,
    address[] calldata controllers,
    address[] calldata markets
  ) external spherexOnlyOperatorOrAdmin {
    address engineAddress = sphereXEngine();
    bytes memory changeSphereXEngineCalldata = abi.encodeWithSelector(
      ISphereXProtectedRegisteredBase.changeSphereXEngine.selector,
      engineAddress
    );
    bytes memory addAllowedSenderOnChainCalldata;
    if (engineAddress != address(0)) {
      addAllowedSenderOnChainCalldata = abi.encodeWithSelector(
        ISphereXEngine.addAllowedSenderOnChain.selector,
        address(0)
      );
    }
    _updateSphereXEngineOnRegisteredContractsInSet(
      _controllerFactories,
      engineAddress,
      controllerFactories,
      changeSphereXEngineCalldata,
      addAllowedSenderOnChainCalldata,
      ControllerFactoryDoesNotExist.selector
    );
    _updateSphereXEngineOnRegisteredContractsInSet(
      _controllers,
      engineAddress,
      controllers,
      changeSphereXEngineCalldata,
      addAllowedSenderOnChainCalldata,
      ControllerDoesNotExist.selector
    );
    _updateSphereXEngineOnRegisteredContractsInSet(
      _markets,
      engineAddress,
      markets,
      changeSphereXEngineCalldata,
      addAllowedSenderOnChainCalldata,
      MarketDoesNotExist.selector
    );
  }

  function _updateSphereXEngineOnRegisteredContractsInSet(
    EnumerableSet.AddressSet storage set,
    address engineAddress,
    address[] memory contracts,
    bytes memory changeSphereXEngineCalldata,
    bytes memory addAllowedSenderOnChainCalldata,
    bytes4 notInSetErrorSelectorBytes
  ) internal {
    for (uint256 i = 0; i < contracts.length; i++) {
      address account = contracts[i];
      if (!set.contains(account)) {
        uint32 notInSetErrorSelector = uint32(notInSetErrorSelectorBytes);
        assembly {
          mstore(0, notInSetErrorSelector)
          revert(0x1c, 0x04)
        }
      }
      _callWith(account, changeSphereXEngineCalldata);
      if (engineAddress != address(0)) {
        assembly {
          mstore(add(addAllowedSenderOnChainCalldata, 0x24), account)
        }
        _callWith(engineAddress, addAllowedSenderOnChainCalldata);
        emit_NewAllowedSenderOnchain(account);
      }
    }
  }

  function _callWith(address target, bytes memory data) internal {
    assembly {
      if iszero(call(gas(), target, 0, add(data, 0x20), mload(data), 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  /* ========================================================================== */
  /*                                  Borrowers                                 */
  /* ========================================================================== */

  function registerBorrower(address borrower) external onlyOwner {
    if (!_borrowers.add(borrower)) {
      revert BorrowerAlreadyExists();
    }
    emit BorrowerAdded(borrower);
  }

  function removeBorrower(address borrower) external onlyOwner {
    if (!_borrowers.remove(borrower)) {
      revert BorrowerDoesNotExist();
    }
    emit BorrowerRemoved(borrower);
  }

  function isRegisteredBorrower(address borrower) external view returns (bool) {
    return _borrowers.contains(borrower);
  }

  function getRegisteredBorrowers() external view returns (address[] memory) {
    return _borrowers.values();
  }

  function getRegisteredBorrowers(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr) {
    uint256 len = _borrowers.length();
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = _borrowers.at(start + i);
    }
  }

  function getRegisteredBorrowersCount() external view returns (uint256) {
    return _borrowers.length();
  }

  // ========================================================================== //
  //                          Asset Blacklist Registry                          //
  // ========================================================================== //

  function addBlacklist(address asset) external onlyOwner {
    if (!_assetBlacklist.add(asset)) {
      revert AssetAlreadyBlacklisted();
    }
    emit AssetBlacklisted(asset);
  }

  function removeBlacklist(address asset) external onlyOwner {
    if (!_assetBlacklist.remove(asset)) {
      revert AssetNotBlacklisted();
    }
    emit AssetPermitted(asset);
  }

  function isBlacklistedAsset(address asset) external view returns (bool) {
    return _assetBlacklist.contains(asset);
  }

  function getBlacklistedAssets() external view returns (address[] memory) {
    return _assetBlacklist.values();
  }

  function getBlacklistedAssets(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr) {
    uint256 len = _assetBlacklist.length();
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = _assetBlacklist.at(start + i);
    }
  }

  function getBlacklistedAssetsCount() external view returns (uint256) {
    return _assetBlacklist.length();
  }



  /* ========================================================================== */
  /*                            Controller Factories                            */
  /* ========================================================================== */

  function registerControllerFactory(address factory) external onlyOwner {
    if (!_controllerFactories.add(factory)) {
      revert ControllerFactoryAlreadyExists();
    }
    _addAllowedSenderOnChain(factory);
    emit ControllerFactoryAdded(factory);
  }

  function removeControllerFactory(address factory) external onlyOwner {
    if (!_controllerFactories.remove(factory)) {
      revert ControllerFactoryDoesNotExist();
    }
    emit ControllerFactoryRemoved(factory);
  }

  function isRegisteredControllerFactory(address factory) external view returns (bool) {
    return _controllerFactories.contains(factory);
  }

  function getRegisteredControllerFactories() external view returns (address[] memory) {
    return _controllerFactories.values();
  }

  function getRegisteredControllerFactories(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr) {
    uint256 len = _controllerFactories.length();
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = _controllerFactories.at(start + i);
    }
  }

  function getRegisteredControllerFactoriesCount() external view returns (uint256) {
    return _controllerFactories.length();
  }

  /* ========================================================================== */
  /*                                 Controllers                                */
  /* ========================================================================== */

  modifier onlyControllerFactory() {
    if (!_controllerFactories.contains(msg.sender)) {
      revert NotControllerFactory();
    }
    _;
  }

  function registerController(address controller) external onlyControllerFactory {
    if (!_controllers.add(controller)) {
      revert ControllerAlreadyExists();
    }
    _addAllowedSenderOnChain(controller);
    emit ControllerAdded(msg.sender, controller);
  }

  function removeController(address controller) external onlyOwner {
    if (!_controllers.remove(controller)) {
      revert ControllerDoesNotExist();
    }
    emit ControllerRemoved(controller);
  }

  function isRegisteredController(address controller) external view returns (bool) {
    return _controllers.contains(controller);
  }

  function getRegisteredControllers() external view returns (address[] memory) {
    return _controllers.values();
  }

  function getRegisteredControllers(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr) {
    uint256 len = _controllers.length();
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = _controllers.at(start + i);
    }
  }

  function getRegisteredControllersCount() external view returns (uint256) {
    return _controllers.length();
  }

  /* ========================================================================== */
  /*                                   Markets                                   */
  /* ========================================================================== */

  modifier onlyController() {
    if (!_controllers.contains(msg.sender)) {
      revert NotController();
    }
    _;
  }

  function registerMarket(address market) external onlyController {
    if (!_markets.add(market)) {
      revert MarketAlreadyExists();
    }
    _addAllowedSenderOnChain(market);
    emit MarketAdded(msg.sender, market);
  }

  function removeMarket(address market) external onlyOwner {
    if (!_markets.remove(market)) {
      revert MarketDoesNotExist();
    }
    emit MarketRemoved(market);
  }

  function isRegisteredMarket(address market) external view returns (bool) {
    return _markets.contains(market);
  }

  function getRegisteredMarkets() external view returns (address[] memory) {
    return _markets.values();
  }

  function getRegisteredMarkets(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr) {
    uint256 len = _markets.length();
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = _markets.at(start + i);
    }
  }

  function getRegisteredMarketsCount() external view returns (uint256) {
    return _markets.length();
  }
}
