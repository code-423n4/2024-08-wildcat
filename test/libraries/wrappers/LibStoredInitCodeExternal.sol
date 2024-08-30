// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import { LibStoredInitCode } from 'src/libraries/LibStoredInitCode.sol';

contract LibStoredInitCodeExternal {
  uint256 public immutable getContractParameters = 123;

  function deployInitCode(bytes memory data) external returns (address initCodeStorage) {
    return LibStoredInitCode.deployInitCode(data);
  }

  /// @dev Returns the create2 prefix for a given deployer address.
  /// Equivalent to `uint256(uint160(deployer)) | (0xff << 160)`
  function getCreate2Prefix(address deployer) external pure returns (uint256 create2Prefix) {
    return LibStoredInitCode.getCreate2Prefix(deployer);
  }

  function calculateCreate2Address(
    uint256 create2Prefix,
    bytes32 salt,
    uint256 initCodeHash
  ) external pure returns (address create2Address) {
    return LibStoredInitCode.calculateCreate2Address(create2Prefix, salt, initCodeHash);
  }

  function createWithStoredInitCode(address initCodeStorage) external returns (address deployment) {
    return LibStoredInitCode.createWithStoredInitCode(initCodeStorage);
  }

  function createWithStoredInitCode(
    address initCodeStorage,
    uint256 value
  ) external returns (address deployment) {
    return LibStoredInitCode.createWithStoredInitCode(initCodeStorage, value);
  }

  function create2WithStoredInitCode(
    address initCodeStorage,
    bytes32 salt
  ) external returns (address deployment) {
    return LibStoredInitCode.create2WithStoredInitCode(initCodeStorage, salt);
  }

  function create2WithStoredInitCode(
    address initCodeStorage,
    bytes32 salt,
    uint256 value
  ) external returns (address deployment) {
    return LibStoredInitCode.create2WithStoredInitCode(initCodeStorage, salt, value);
  }
}

interface ITestDeployer {
  function getContractParameters() external view returns (uint256);
}

contract TestContract {
  uint256 internal immutable x;

  constructor() payable {
    x = ITestDeployer(msg.sender).getContractParameters();
  }

  function getValue() external view returns (uint256) {
    return x;
  }
}
