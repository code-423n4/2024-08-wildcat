// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;
import { Panic_ErrorSelector, Panic_ErrorCodePointer, Panic_InvalidStorageByteArray, Error_SelectorPointer, Panic_ErrorLength } from '../libraries/Errors.sol';

type TransientBytesArray is uint256;

using LibTransientBytesArray for TransientBytesArray global;

library LibTransientBytesArray {
  /**
   * @dev Decode a dynamic bytes array from transient storage.
   * @param transientSlot Slot for the dynamic bytes array in transient storage
   * @param memoryPointer Pointer to the memory location to write the decoded array to
   * @return endPointer Pointer to the end of the decoded array
   */
  function readToPointer(
    TransientBytesArray transientSlot,
    uint256 memoryPointer
  ) internal view returns (uint256 endPointer) {
    assembly {
      function extractByteArrayLength(data) -> length {
        length := div(data, 2)
        let outOfPlaceEncoding := and(data, 1)
        if iszero(outOfPlaceEncoding) {
          length := and(length, 0x7f)
        }

        if eq(outOfPlaceEncoding, lt(length, 32)) {
          // Store the Panic error signature.
          mstore(0, Panic_ErrorSelector)
          // Store the arithmetic (0x11) panic code.
          mstore(Panic_ErrorCodePointer, Panic_InvalidStorageByteArray)
          // revert(abi.encodeWithSignature("Panic(uint256)", 0x22))
          revert(Error_SelectorPointer, Panic_ErrorLength)
        }
      }
      let slotValue := tload(transientSlot)
      let length := extractByteArrayLength(slotValue)
      mstore(memoryPointer, length)
      memoryPointer := add(memoryPointer, 0x20)
      switch and(slotValue, 1)
      case 0 {
        // short byte array
        let value := and(slotValue, not(0xff))
        mstore(memoryPointer, value)
        endPointer := add(memoryPointer, 0x20)
      }
      case 1 {
        // long byte array
        mstore(0, transientSlot)
        // Calculate the slot of the data portion of the array
        let dataTSlot := keccak256(0, 0x20)
        let i := 0
        for {

        } lt(i, length) {
          i := add(i, 0x20)
        } {
          mstore(add(memoryPointer, i), tload(dataTSlot))
          dataTSlot := add(dataTSlot, 1)
        }
        endPointer := add(memoryPointer, i)
      }
    }
  }

  function read(TransientBytesArray transientSlot) internal view returns (bytes memory data) {
    uint256 dataPointer;
    assembly {
      dataPointer := mload(0x40)
      data := dataPointer
      mstore(data, 0)
    }
    uint256 endPointer = readToPointer(transientSlot, dataPointer);
    assembly {
      mstore(0x40, endPointer)
    }
  }

  /**
   * @dev Write a dynamic bytes array to transient storage.
   * @param transientSlot Slot for the dynamic bytes array in transient storage
   * @param memoryPointer Pointer to the memory location of the array to write
   */
  function write(TransientBytesArray transientSlot, bytes memory memoryPointer) internal {
    assembly {
      let length := mload(memoryPointer)
      memoryPointer := add(memoryPointer, 0x20)
      switch lt(length, 32)
      case 0 {
        // For long byte arrays, the length slot holds (length * 2 + 1)
        tstore(transientSlot, add(1, mul(2, length)))
        // Calculate the slot of the data portion of the array
        mstore(0, transientSlot)
        let dataTSlot := keccak256(0, 0x20)
        let i := 0
        for {

        } lt(i, length) {
          i := add(i, 0x20)
        } {
          tstore(dataTSlot, mload(add(memoryPointer, i)))
          dataTSlot := add(dataTSlot, 1)
        }
      }
      case 1 {
        // For short byte arrays, the first 31 bytes are the data and the last byte is (length * 2).
        let lengthByte := mul(2, length)
        let data := mload(memoryPointer)
        tstore(transientSlot, or(data, lengthByte))
      }
    }
  }

  function setEmpty(TransientBytesArray transientSlot) internal {
    assembly {
      tstore(transientSlot, 0)
    }
  }
}
