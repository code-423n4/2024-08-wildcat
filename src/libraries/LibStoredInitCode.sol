// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.24;

library LibStoredInitCode {
  error InitCodeDeploymentFailed();
  error DeploymentFailed();

  function deployInitCode(bytes memory data) internal returns (address initCodeStorage) {
    assembly {
      let size := mload(data)
      let createSize := add(size, 0x0b)
      // Prefix Code
      //
      // Has trailing STOP instruction so the deployed data
      // can not be executed as a smart contract.
      //
      // Instruction                | Stack
      // ----------------------------------------------------
      // PUSH2 size                 | size                  |
      // PUSH0                      | 0, size               |
      // DUP2                       | size, 0, size         |
      // PUSH1 10 (offset to STOP)  | 10, size, 0, size     |
      // PUSH0                      | 0, 10, size, 0, size  |
      // CODECOPY                   | 0, size               |
      // RETURN                     |                       |
      // STOP                       |                       |
      // ----------------------------------------------------

      // Shift (size + 1) to position it in front of the PUSH2 instruction.
      // Reuse `data.length` memory for the create prefix to avoid
      // unnecessary memory allocation.
      mstore(data, or(shl(64, add(size, 1)), 0x6100005f81600a5f39f300))
      // Deploy the code storage
      initCodeStorage := create(0, add(data, 21), createSize)
      // if (initCodeStorage == address(0)) revert InitCodeDeploymentFailed();
      if iszero(initCodeStorage) {
        mstore(0, 0x11c8c3c0)
        revert(0x1c, 0x04)
      }
      // Restore `data.length`
      mstore(data, size)
    }
  }

  /**
   * @dev Returns the create2 prefix for a given deployer address.
   *      Equivalent to `uint256(uint160(deployer)) | (0xff << 160)`
   */
  function getCreate2Prefix(address deployer) internal pure returns (uint256 create2Prefix) {
    assembly {
      create2Prefix := or(deployer, 0xff0000000000000000000000000000000000000000)
    }
  }

  function calculateCreate2Address(
    uint256 create2Prefix,
    bytes32 salt,
    uint256 initCodeHash
  ) internal pure returns (address create2Address) {
    assembly {
      // Cache the free memory pointer so it can be restored at the end
      let freeMemoryPointer := mload(0x40)

      // Write 0xff + address to bytes 11:32
      mstore(0x00, create2Prefix)

      // Write salt to bytes 32:64
      mstore(0x20, salt)

      // Write initcode hash to bytes 64:96
      mstore(0x40, initCodeHash)

      // Calculate create2 address
      create2Address := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

      // Restore the free memory pointer
      mstore(0x40, freeMemoryPointer)
    }
  }

  function createWithStoredInitCode(address initCodeStorage) internal returns (address deployment) {
    deployment = createWithStoredInitCode(initCodeStorage, 0);
  }

  function createWithStoredInitCode(
    address initCodeStorage,
    uint256 value
  ) internal returns (address deployment) {
    assembly {
      let initCodePointer := mload(0x40)
      let initCodeSize := sub(extcodesize(initCodeStorage), 1)
      extcodecopy(initCodeStorage, initCodePointer, 1, initCodeSize)
      deployment := create(value, initCodePointer, initCodeSize)
      if iszero(deployment) {
        mstore(0x00, 0x30116425) // DeploymentFailed()
        revert(0x1c, 0x04)
      }
    }
  }

  function create2WithStoredInitCode(
    address initCodeStorage,
    bytes32 salt
  ) internal returns (address deployment) {
    deployment = create2WithStoredInitCode(initCodeStorage, salt, 0);
  }

  function create2WithStoredInitCode(
    address initCodeStorage,
    bytes32 salt,
    uint256 value
  ) internal returns (address deployment) {
    assembly {
      let initCodePointer := mload(0x40)
      let initCodeSize := sub(extcodesize(initCodeStorage), 1)
      extcodecopy(initCodeStorage, initCodePointer, 1, initCodeSize)
      deployment := create2(value, initCodePointer, initCodeSize, salt)
      if iszero(deployment) {
        mstore(0x00, 0x30116425) // DeploymentFailed()
        revert(0x1c, 0x04)
      }
    }
  }

  function create2WithStoredInitCode(
    address initCodeStorage,
    bytes32 salt,
    uint256 value,
    bytes memory constructorArgs
  ) internal returns (address deployment) {
    assembly {
      let initCodePointer := mload(0x40)
      let initCodeSize := sub(extcodesize(initCodeStorage), 1)
      // Copy code from target address to memory starting at byte 1
      extcodecopy(initCodeStorage, initCodePointer, 1, initCodeSize)
      // Copy constructor args from memory to initcode
      let constructorArgsSize := mload(constructorArgs)
      mcopy(add(initCodePointer, initCodeSize), add(constructorArgs, 0x20), constructorArgsSize)
      let initCodeSizeWithArgs := add(initCodeSize, constructorArgsSize)
      deployment := create2(value, initCodePointer, initCodeSizeWithArgs, salt)
      if iszero(deployment) {
        mstore(0x00, 0x30116425) // DeploymentFailed()
        revert(0x1c, 0x04)
      }
    }
  }

  function create2WithStoredInitCode(
    address initCodeStorage,
    bytes32 salt,
    bytes memory constructorArgs
  ) internal returns (address deployment) {
    return create2WithStoredInitCode(initCodeStorage, salt, 0, constructorArgs);
  }

  function create2WithStoredInitCodeCD(
    address initCodeStorage,
    bytes32 salt,
    uint256 value,
    bytes calldata constructorArgs
  ) internal returns (address deployment) {
    assembly {
      let initCodePointer := mload(0x40)
      let initCodeSize := sub(extcodesize(initCodeStorage), 1)
      // Copy code from target address to memory starting at byte 1
      extcodecopy(initCodeStorage, initCodePointer, 1, initCodeSize)
      // Copy constructor args from calldata to end of initcode
      let constructorArgsSize := constructorArgs.length
      calldatacopy(add(initCodePointer, initCodeSize), constructorArgs.offset, constructorArgsSize)
      let initCodeSizeWithArgs := add(initCodeSize, constructorArgsSize)
      deployment := create2(value, initCodePointer, initCodeSizeWithArgs, salt)
      if iszero(deployment) {
        mstore(0x00, 0x30116425) // DeploymentFailed()
        revert(0x1c, 0x04)
      }
    }
  }

  function create2WithStoredInitCodeCD(
    address initCodeStorage,
    bytes32 salt,
    bytes calldata constructorArgs
  ) internal returns (address deployment) {
    return create2WithStoredInitCodeCD(initCodeStorage, salt, 0, constructorArgs);
  }
}
