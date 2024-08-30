// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

uint256 constant Panic_CompilerPanic = 0x00;
uint256 constant Panic_AssertFalse = 0x01;
uint256 constant Panic_Arithmetic = 0x11;
uint256 constant Panic_DivideByZero = 0x12;
uint256 constant Panic_InvalidEnumValue = 0x21;
uint256 constant Panic_InvalidStorageByteArray = 0x22;
uint256 constant Panic_EmptyArrayPop = 0x31;
uint256 constant Panic_ArrayOutOfBounds = 0x32;
uint256 constant Panic_MemoryTooLarge = 0x41;
uint256 constant Panic_UninitializedFunctionPointer = 0x51;

uint256 constant Panic_ErrorSelector = 0x4e487b71;
uint256 constant Panic_ErrorCodePointer = 0x20;
uint256 constant Panic_ErrorLength = 0x24;
uint256 constant Error_SelectorPointer = 0x1c;

/**
 * @dev Reverts with the given error selector.
 * @param errorSelector The left-aligned error selector.
 */
function revertWithSelector(bytes4 errorSelector) pure {
  assembly {
    mstore(0, errorSelector)
    revert(0, 4)
  }
}

/**
 * @dev Reverts with the given error selector.
 * @param errorSelector The left-padded error selector.
 */
function revertWithSelector(uint256 errorSelector) pure {
  assembly {
    mstore(0, errorSelector)
    revert(Error_SelectorPointer, 4)
  }
}

/**
 * @dev Reverts with the given error selector and argument.
 * @param errorSelector The left-aligned error selector.
 * @param argument The argument to the error.
 */
function revertWithSelectorAndArgument(bytes4 errorSelector, uint256 argument) pure {
  assembly {
    mstore(0, errorSelector)
    mstore(4, argument)
    revert(0, 0x24)
  }
}

/**
 * @dev Reverts with the given error selector and argument.
 * @param errorSelector The left-padded error selector.
 * @param argument The argument to the error.
 */
function revertWithSelectorAndArgument(uint256 errorSelector, uint256 argument) pure {
  assembly {
    mstore(0, errorSelector)
    mstore(0x20, argument)
    revert(Error_SelectorPointer, 0x24)
  }
}
