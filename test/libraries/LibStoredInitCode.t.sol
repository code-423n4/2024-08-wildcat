// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.19;

import { Test } from 'forge-std/Test.sol';
import './wrappers/LibStoredInitCodeExternal.sol';

contract Undeployable {
  constructor() {
    assembly {
      revert(0, 0)
    }
  }
}

contract LibStoredInitCodeTest is Test {
  LibStoredInitCodeExternal internal immutable lib = new LibStoredInitCodeExternal();

  uint256 public immutable getContractParameters = 123;

  // ===================================================================== //
  //                         deployInitCode(bytes)                         //
  // ===================================================================== //

  function test_deployInitCode(bytes memory data) external {
    vm.assume(data.length < 30_000);
    address deployed = lib.deployInitCode(data);
    assertEq(deployed.codehash, keccak256(abi.encodePacked(uint8(0x00), data)));
  }

  function test_deployInitCode() external {
    bytes memory data = hex'aabbccddeeff';
    address deployed = lib.deployInitCode(data);
    assertEq(deployed.codehash, keccak256(abi.encodePacked(uint8(0x00), data)));
  }

  function test_deployInitCode_InitCodeDeploymentFailed() external {
    bytes memory data = new bytes(24_576);
    vm.expectRevert(LibStoredInitCode.InitCodeDeploymentFailed.selector);
    lib.deployInitCode{ gas: 24_576 * 200 }(data);
  }

  // ===================================================================== //
  //                       getCreate2Prefix(address)                       //
  // ===================================================================== //

  function test_getCreate2Prefix(address deployer) external {
    assertEq(lib.getCreate2Prefix(deployer), uint256(uint160(deployer)) | (0xff << 160));
  }

  function test_getCreate2Prefix() external {
    address deployer = 0x1111111111111111111111111111111111111111;
    assertEq(lib.getCreate2Prefix(deployer), 0xff1111111111111111111111111111111111111111);
  }

  // ===================================================================== //
  //           calculateCreate2Address(uint256,bytes32,uint256)            //
  // ===================================================================== //

  function test_calculateCreate2Address(
    uint256 create2Prefix,
    bytes32 salt,
    uint256 initCodeHash
  ) external {
    assertEq(
      lib.calculateCreate2Address(create2Prefix, salt, initCodeHash),
      address(
        uint160(uint256(keccak256(abi.encodePacked(uint168(create2Prefix), salt, initCodeHash))))
      )
    );
  }

  function test_calculateCreate2Address() external {
    uint256 create2Prefix = lib.getCreate2Prefix(address(this));
    bytes32 salt = keccak256('salt');
    uint256 initCodeHash = uint256(keccak256(type(TestContract).creationCode));
    address actual = address(new TestContract{ salt: salt }());
    assertEq(lib.calculateCreate2Address(create2Prefix, salt, initCodeHash), actual);
  }

  // ===================================================================== //
  //                   createWithStoredInitCode(address)                   //
  // ===================================================================== //

  function test_createWithStoredInitCode() external {
    address initCodeStorage = lib.deployInitCode(type(TestContract).creationCode);
    address deployed = lib.createWithStoredInitCode(initCodeStorage, 0);
    assertEq(deployed.codehash, address(new TestContract()).codehash);
  }

  // ===================================================================== //
  //               createWithStoredInitCode(address,uint256)               //
  // ===================================================================== //

  function test_createWithStoredInitCode_WithValue() external {
    vm.deal(address(lib), 1e18);
    address initCodeStorage = lib.deployInitCode(type(TestContract).creationCode);
    address deployed = lib.createWithStoredInitCode(initCodeStorage, 1e18);
    assertEq(deployed.codehash, address(new TestContract()).codehash);
    assertEq(deployed.balance, 1e18);
  }

  function test_createWithStoredInitCode_DeploymentFailed(bytes32 salt) external {
    address initCodeStorage = lib.deployInitCode(type(Undeployable).creationCode);

    vm.expectRevert(LibStoredInitCode.DeploymentFailed.selector);
    lib.createWithStoredInitCode(initCodeStorage);
  }

  // ===================================================================== //
  //              create2WithStoredInitCode(address,bytes32)               //
  // ===================================================================== //

  function test_create2WithStoredInitCode(bytes32 salt) external {
    uint256 create2Prefix = lib.getCreate2Prefix(address(lib));
    address initCodeStorage = lib.deployInitCode(type(TestContract).creationCode);
    uint256 initCodeHash = uint256(keccak256(type(TestContract).creationCode));

    address deployed = lib.create2WithStoredInitCode(initCodeStorage, salt);
    assertEq(deployed.codehash, address(new TestContract()).codehash, 'codehash');
    assertEq(deployed.balance, 0, 'balance');
    assertEq(
      deployed,
      address(
        uint160(uint256(keccak256(abi.encodePacked(uint168(create2Prefix), salt, initCodeHash))))
      )
    );
  }

  function test_create2WithStoredInitCode_DeploymentFailed(bytes32 salt) external {
    uint256 create2Prefix = lib.getCreate2Prefix(address(lib));
    address initCodeStorage = lib.deployInitCode(type(TestContract).creationCode);
    uint256 initCodeHash = uint256(keccak256(type(TestContract).creationCode));

    lib.create2WithStoredInitCode(initCodeStorage, salt);
    vm.expectRevert(LibStoredInitCode.DeploymentFailed.selector);
    lib.create2WithStoredInitCode(initCodeStorage, salt);
  }

  // ===================================================================== //
  //          create2WithStoredInitCode(address,bytes32,uint256)           //
  // ===================================================================== //

  function test_create2WithStoredInitCode_WithValue(bytes32 salt) external {
    vm.deal(address(lib), 1e18);
    uint256 create2Prefix = lib.getCreate2Prefix(address(lib));
    address initCodeStorage = lib.deployInitCode(type(TestContract).creationCode);
    uint256 initCodeHash = uint256(keccak256(type(TestContract).creationCode));

    address deployed = lib.create2WithStoredInitCode(initCodeStorage, salt, 1e18);
    assertEq(deployed.codehash, address(new TestContract()).codehash, 'codehash');
    assertEq(deployed.balance, 1e18, 'balance');
    assertEq(
      deployed,
      address(
        uint160(uint256(keccak256(abi.encodePacked(uint168(create2Prefix), salt, initCodeHash))))
      )
    );
  }
}
