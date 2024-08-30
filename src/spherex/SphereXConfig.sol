// SPDX-License-Identifier: UNLICENSED
// (c) SphereX 2023 Terms&Conditions
pragma solidity ^0.8.20;

import { ISphereXEngine, ModifierLocals } from './ISphereXEngine.sol';
import './SphereXProtectedEvents.sol';
import './SphereXProtectedErrors.sol';

abstract contract SphereXConfig {
  // ========================================================================== //
  //                                Storage Slots                               //
  // ========================================================================== //

  bytes32 private constant SPHEREX_ADMIN_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.spherex.spherex')) - 1);
  bytes32 private constant SPHEREX_PENDING_ADMIN_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.spherex.pending')) - 1);
  bytes32 private constant SPHEREX_OPERATOR_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.spherex.operator')) - 1);
  bytes32 private constant SPHEREX_ENGINE_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.spherex.spherex_engine')) - 1);

  // ========================================================================== //
  //                                 Constructor                                //
  // ========================================================================== //

  constructor(address admin, address operator, address engine) {
    _setAddress(SPHEREX_ADMIN_STORAGE_SLOT, admin);
    emit_SpherexAdminTransferCompleted(address(0), admin);

    _setAddress(SPHEREX_OPERATOR_STORAGE_SLOT, operator);
    emit_ChangedSpherexOperator(address(0), operator);

    _setSphereXEngine(engine);
    emit_ChangedSpherexEngineAddress(address(0), engine);
  }

  // ========================================================================== //
  //                              Events and Errors                             //
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

  // ========================================================================== //
  //                                  Modifiers                                 //
  // ========================================================================== //

  modifier onlySphereXAdmin() {
    if (msg.sender != sphereXAdmin()) {
      revert_SphereXAdminRequired();
    }
    _;
  }

  modifier spherexOnlyOperator() {
    if (msg.sender != sphereXOperator()) {
      revert_SphereXOperatorRequired();
    }
    _;
  }

  modifier spherexOnlyOperatorOrAdmin() {
    if (msg.sender != sphereXOperator() && msg.sender != sphereXAdmin()) {
      revert_SphereXOperatorOrAdminRequired();
    }
    _;
  }

  // ========================================================================== //
  //                               Config Getters                               //
  // ========================================================================== //

  /**
   * @dev Returns the current pending admin address, which is able to call
   *      acceptSphereXAdminRole to become the admin.
   */
  function pendingSphereXAdmin() public view returns (address) {
    return _getAddress(SPHEREX_PENDING_ADMIN_STORAGE_SLOT);
  }

  /// @dev Returns the current admin address, which is able to change the operator.
  function sphereXAdmin() public view returns (address) {
    return _getAddress(SPHEREX_ADMIN_STORAGE_SLOT);
  }

  /// @dev Returns the current operator address.
  function sphereXOperator() public view returns (address) {
    return _getAddress(SPHEREX_OPERATOR_STORAGE_SLOT);
  }

  /// @dev Returns the current engine address.
  function sphereXEngine() public view returns (address) {
    return _getAddress(SPHEREX_ENGINE_STORAGE_SLOT);
  }

  // ========================================================================== //
  //                                 Management                                 //
  // ========================================================================== //

  /**
   * @dev Set pending admin to `newAdmin`, allowing it to call 
   *      `acceptSphereXAdminRole()` to receive the admin role.
   */
  function transferSphereXAdminRole(address newAdmin) public virtual onlySphereXAdmin {
    _setAddress(SPHEREX_PENDING_ADMIN_STORAGE_SLOT, newAdmin);
    emit_SpherexAdminTransferStarted(sphereXAdmin(), newAdmin);
  }

  /// @dev Accepts a pending admin transfer.
  function acceptSphereXAdminRole() public virtual {
    if (msg.sender != pendingSphereXAdmin()) {
      revert_SphereXNotPendingAdmin();
    }
    address oldAdmin = sphereXAdmin();
    _setAddress(SPHEREX_ADMIN_STORAGE_SLOT, msg.sender);
    _setAddress(SPHEREX_PENDING_ADMIN_STORAGE_SLOT, address(0));
    emit_SpherexAdminTransferCompleted(oldAdmin, msg.sender);
  }

  /// @dev Changes the address of the SphereX operator.
  function changeSphereXOperator(address newSphereXOperator) external onlySphereXAdmin {
    address oldSphereXOperator = _getAddress(SPHEREX_OPERATOR_STORAGE_SLOT);
    _setAddress(SPHEREX_OPERATOR_STORAGE_SLOT, newSphereXOperator);
    emit_ChangedSpherexOperator(oldSphereXOperator, newSphereXOperator);
  }

  /**
   * @dev  Changes the address of the SphereX engine.
   *
   *       This is also used to enable SphereX protection, which is disabled
   *       when the engine address is 0.
   */
  function changeSphereXEngine(address newSphereXEngine) external spherexOnlyOperator {
    address oldEngine = _getAddress(SPHEREX_ENGINE_STORAGE_SLOT);
    _setSphereXEngine(newSphereXEngine);
    emit_ChangedSpherexEngineAddress(oldEngine, newSphereXEngine);
  }

  /**
   * @dev Checks the given address implements ISphereXEngine or is address(0)
   * @param newSphereXEngine new address of the spherex engine
   */
  function _setSphereXEngine(address newSphereXEngine) internal {
    if (
      newSphereXEngine != address(0) &&
      !ISphereXEngine(newSphereXEngine).supportsInterface(type(ISphereXEngine).interfaceId)
    ) {
      revert_SphereXNotEngine();
    }
    _setAddress(SPHEREX_ENGINE_STORAGE_SLOT, newSphereXEngine);
  }

  // ========================================================================== //
  //                             Engine Interaction                             //
  // ========================================================================== //

  function _addAllowedSenderOnChain(address newSender) internal {
    ISphereXEngine engine = ISphereXEngine(sphereXEngine());
    if (address(engine) != address(0)) {
      engine.addAllowedSenderOnChain(newSender);
      emit_NewAllowedSenderOnchain(newSender);
    }
  }

  // ========================================================================== //
  //                          Internal Storage Helpers                          //
  // ========================================================================== //

  /// @dev Stores an address in an arbitrary slot
  function _setAddress(bytes32 slot, address newAddress) internal {
    assembly {
      sstore(slot, newAddress)
    }
  }

  /// @dev Returns an address from an arbitrary slot.
  function _getAddress(bytes32 slot) internal view returns (address addr) {
    assembly {
      addr := sload(slot)
    }
  }
}
