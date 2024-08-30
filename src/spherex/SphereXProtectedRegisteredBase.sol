// SPDX-License-Identifier: UNLICENSED
// (c) SphereX 2023 Terms&Conditions
pragma solidity ^0.8.20;

import { ISphereXEngine, ModifierLocals } from './ISphereXEngine.sol';
import './SphereXProtectedEvents.sol';
import './SphereXProtectedErrors.sol';

/**
 * @title Modified version of SphereXProtectedBase for contracts registered
 *        on Wildcat's arch controller.
 *
 * @author Modified from https://github.com/spherex-xyz/spherex-protect-contracts/blob/main/src/SphereXProtectedBase.sol
 *
 * @dev In this version, the WildcatArchController deployment is the SphereX operator.
 *      There is no admin because the arch controller address can not be modified.
 *
 *      All admin functions/events/errors have been removed to reduce contract size.
 *
 *      SphereX engine address validation is delegated to the arch controller.
 */
abstract contract SphereXProtectedRegisteredBase {
  // ========================================================================== //
  //                                  Constants                                 //
  // ========================================================================== //

  /// @dev Storage slot with the address of the SphereX engine contract.
  bytes32 private constant SPHEREX_ENGINE_STORAGE_SLOT =
    bytes32(uint256(keccak256('eip1967.spherex.spherex_engine')) - 1);

  /**
   * @dev Address of the WildcatArchController deployment.
   *      The arch controller is able to set the SphereX engine address.
   *      The inheriting contract must assign this in the constructor.
   */
  address internal immutable _archController;

  // ========================================================================== //
  //                                 Initializer                                //
  // ========================================================================== //

  /**
   * @dev Initializes the SphereXEngine and emits events for the initial
   *      engine and operator (arch controller).
   */
  function __SphereXProtectedRegisteredBase_init(address engine) internal virtual {
    emit_ChangedSpherexOperator(address(0), _archController);
    _setAddress(SPHEREX_ENGINE_STORAGE_SLOT, engine);
    emit_ChangedSpherexEngineAddress(address(0), engine);
  }

  // ========================================================================== //
  //                              Events and Errors                             //
  // ========================================================================== //

  error SphereXOperatorRequired();

  event ChangedSpherexOperator(address oldSphereXAdmin, address newSphereXAdmin);
  event ChangedSpherexEngineAddress(address oldEngineAddress, address newEngineAddress);

  // ========================================================================== //
  //                               Local Modifiers                              //
  // ========================================================================== //

  modifier spherexOnlyOperator() {
    if (msg.sender != _archController) {
      revert_SphereXOperatorRequired();
    }
    _;
  }

  modifier returnsIfNotActivatedPre(ModifierLocals memory locals) {
    locals.engine = sphereXEngine();
    if (locals.engine == address(0)) {
      return;
    }

    _;
  }

  modifier returnsIfNotActivatedPost(ModifierLocals memory locals) {
    if (locals.engine == address(0)) {
      return;
    }

    _;
  }

  // ========================================================================== //
  //                                 Management                                 //
  // ========================================================================== //

  /// @dev Returns the current operator address.
  function sphereXOperator() public view returns (address) {
    return _archController;
  }

  /// @dev Returns the current engine address.
  function sphereXEngine() public view returns (address) {
    return _getAddress(SPHEREX_ENGINE_STORAGE_SLOT);
  }

  /**
   * @dev  Change the address of the SphereX engine.
   *
   *       This is also used to enable SphereX protection, which is disabled
   *       when the engine address is 0.
   *
   * Note: The new engine is not validated as it would be in `SphereXProtectedBase`
   *       because the operator is the arch controller, which validates the engine
   *       address prior to updating it here.
   */
  function changeSphereXEngine(address newSphereXEngine) external spherexOnlyOperator {
    address oldEngine = _getAddress(SPHEREX_ENGINE_STORAGE_SLOT);
    _setAddress(SPHEREX_ENGINE_STORAGE_SLOT, newSphereXEngine);
    emit_ChangedSpherexEngineAddress(oldEngine, newSphereXEngine);
  }

  // ========================================================================== //
  //                                    Hooks                                   //
  // ========================================================================== //

  /**
   * @dev Wrapper for `_getStorageSlotsAndPreparePostCalldata` that returns
   *      a `uint256` pointer to `locals` rather than the struct itself.
   *
   *      Declaring a return parameter for a struct will always zero and
   *      allocate memory for every field in the struct. If the parameter
   *      is always reassigned, the gas and memory used on this are wasted.
   *
   *      Using a `uint256` pointer instead of a struct declaration avoids
   *      this waste while being functionally identical.
   */
  function _sphereXValidateExternalPre() internal returns (uint256 localsPointer) {
    return _castFunctionToPointerOutput(_getStorageSlotsAndPreparePostCalldata)(_getSelector());
  }

  /**
   * @dev Internal function for engine communication. We use it to reduce contract size.
   *      Should be called before the code of an external function.
   *
   *      Queries `storageSlots` from `sphereXValidatePre` on the engine and writes
   *      the result to `locals.storageSlots`, then caches the current storage values
   *      for those slots in `locals.valuesBefore`.
   *
   *      Also allocates memory for the calldata of the future call to `sphereXValidatePost`
   *      and initializes every value in the calldata except for `gas` and `valuesAfter` data.
   *
   * @param num function identifier
   */
  function _getStorageSlotsAndPreparePostCalldata(
    int256 num
  ) internal returnsIfNotActivatedPre(locals) returns (ModifierLocals memory locals) {
    assembly {
      // Read engine from `locals.engine` - this is filled by `returnsIfNotActivatedPre`
      let engineAddress := mload(add(locals, 0x60))

      // Get free memory pointer - this will be used for the calldata
      // to `sphereXValidatePre` and then reused for both `storageSlots`
      // and the future calldata to `sphereXValidatePost`
      let pointer := mload(0x40)

      // Call `sphereXValidatePre(num, msg.sender, msg.data)`
      mstore(pointer, 0x8925ca5a)
      mstore(add(pointer, 0x20), num)
      mstore(add(pointer, 0x40), caller())
      mstore(add(pointer, 0x60), 0x60)
      mstore(add(pointer, 0x80), calldatasize())
      calldatacopy(add(pointer, 0xa0), 0, calldatasize())
      let size := add(0xc4, calldatasize())

      if iszero(
        and(eq(mload(0), 0x20), call(gas(), engineAddress, 0, add(pointer, 28), size, 0, 0x40))
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      let length := mload(0x20)

      // Set up the memory after the allocation `locals` struct as:
      // [0x00:0x20]: `storageSlots.length`
      // [0x20:0x20+(length * 0x20)]: `storageSlots` data
      // [0x20+(length*0x20):]: calldata for `sphereXValidatePost`

      // The layout for the `sphereXValidatePost` calldata is:
      // [0x00:0x20]: num
      // [0x20:0x40]: gas
      // [0x40:0x60]: valuesBefore offset (0x80)
      // [0x60:0x80]: valuesAfter offset (0xa0 + (0x20 * length))
      // [0x80:0xa0]: valuesBefore length (0xa0 + (0x20 * length))
      // [0xa0:0xa0+(0x20*length)]: valuesBefore data
      // [0xa0+(0x20*length):0xc0+(0x20*length)] valuesAfter length
      // [0xc0+(0x20*length):0xc0+(0x40*length)]: valuesAfter data
      //
      // size of calldata: 0xc0 + (0x40 * length)
      //
      // size of allocation: 0xe0 + (0x60 * length)

      // Calculate size of array data (excluding length): 32 * length
      let arrayDataSize := shl(5, length)

      // Finalize memory allocation with space for `storageSlots` and
      // the calldata for `sphereXValidatePost`.
      mstore(0x40, add(pointer, add(0xe0, mul(arrayDataSize, 3))))

      // Copy `storageSlots` from returndata to the start of the allocated
      // memory buffer and write the pointer to `locals.storageSlots`
      returndatacopy(pointer, 0x20, add(arrayDataSize, 0x20))
      mstore(locals, pointer)

      // Get pointer to future calldata.
      // Add `32 + arrayDataSize` to skip the allocation for `locals.storageSlots`
      // @todo *could* put `valuesBefore` before `storageSlots` and reuse
      // the `storageSlots` buffer for `valuesAfter`
      let calldataPointer := add(pointer, add(arrayDataSize, 0x20))

      // Write `-num` to calldata
      mstore(calldataPointer, sub(0, num))

      // Write `valuesBefore` offset to calldata
      mstore(add(calldataPointer, 0x40), 0x80)

      // Write `locals.valuesBefore` pointer
      mstore(add(locals, 0x20), add(calldataPointer, 0x80))

      // Write `valuesAfter` offset to calldata
      mstore(add(calldataPointer, 0x60), add(0xa0, arrayDataSize))

      // Write `gasleft()` to `locals.gas`
      mstore(add(locals, 0x40), gas())
    }
    _readStorageTo(locals.storageSlots, locals.valuesBefore);
  }

  /**
   * @dev Wrapper for `_callSphereXValidatePost` that takes a pointer
   *      instead of a struct.
   */
  function _sphereXValidateExternalPost(uint256 locals) internal {
    _castFunctionToPointerInput(_callSphereXValidatePost)(locals);
  }

  function _callSphereXValidatePost(
    ModifierLocals memory locals
  ) internal returnsIfNotActivatedPost(locals) {
    uint256 length;
    bytes32[] memory storageSlots;
    bytes32[] memory valuesAfter;
    assembly {
      storageSlots := mload(locals)
      length := mload(storageSlots)
      valuesAfter := add(storageSlots, add(0xc0, shl(6, length)))
    }
    _readStorageTo(storageSlots, valuesAfter);
    assembly {
      let sphereXEngineAddress := mload(add(locals, 0x60))
      let arrayDataSize := shl(5, length)
      let calldataSize := add(0xc4, shl(1, arrayDataSize))

      let calldataPointer := add(storageSlots, add(arrayDataSize, 0x20))
      let gasDiff := sub(mload(add(locals, 0x40)), gas())
      mstore(add(calldataPointer, 0x20), gasDiff)
      let slotBefore := sub(calldataPointer, 32)
      let slotBeforeCache := mload(slotBefore)
      mstore(slotBefore, 0xf0bd9468)
      if iszero(call(gas(), sphereXEngineAddress, 0, add(slotBefore, 28), calldataSize, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      mstore(slotBefore, slotBeforeCache)
    }
  }

  /// @dev Returns the function selector from the current calldata.
  function _getSelector() internal pure returns (int256 selector) {
    assembly {
      selector := shr(224, calldataload(0))
    }
  }

  /// @dev Modifier to be incorporated in all external protected non-view functions
  modifier sphereXGuardExternal() {
    uint256 localsPointer = _sphereXValidateExternalPre();
    _;
    _sphereXValidateExternalPost(localsPointer);
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

  /**
   * @dev Internal function that reads values from given storage slots
   *      and writes them to a particular memory location.
   *
   * @param storageSlots array of storage slots to read
   * @param values array of values to write values to
   */
  function _readStorageTo(bytes32[] memory storageSlots, bytes32[] memory values) internal view {
    assembly {
      let length := mload(storageSlots)
      let arrayDataSize := shl(5, length)
      mstore(values, length)
      let nextSlotPointer := add(storageSlots, 0x20)
      let nextElementPointer := add(values, 0x20)
      let endPointer := add(nextElementPointer, shl(5, length))
      for {

      } lt(nextElementPointer, endPointer) {

      } {
        mstore(nextElementPointer, sload(mload(nextSlotPointer)))
        nextElementPointer := add(nextElementPointer, 0x20)
        nextSlotPointer := add(nextSlotPointer, 0x20)
      }
    }
  }

  // ========================================================================== //
  //                             Function Type Casts                            //
  // ========================================================================== //

  function _castFunctionToPointerInput(
    function(ModifierLocals memory) internal fnIn
  ) internal pure returns (function(uint256) internal fnOut) {
    assembly {
      fnOut := fnIn
    }
  }

  function _castFunctionToPointerOutput(
    function(int256) internal returns (ModifierLocals memory) fnIn
  ) internal pure returns (function(int256) internal returns (uint256) fnOut) {
    assembly {
      fnOut := fnIn
    }
  }
}
