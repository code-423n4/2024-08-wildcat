// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import 'src/spherex/SphereXConfig.sol';
import 'forge-std/Test.sol';
import { Prankster } from 'sol-utils/test/Prankster.sol';

contract BadEngine {
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return false;
  }
}

contract GoodEngine {
  event NewSenderOnEngine(address sender);

  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    return true;
  }

  function addAllowedSenderOnChain(address sender) external {
    emit NewSenderOnEngine(sender);
  }
}

contract MockConfig is SphereXConfig {
  constructor(
    address admin,
    address operator,
    address engine
  ) SphereXConfig(admin, operator, engine) {}

  function addSender(address sender) external spherexOnlyOperatorOrAdmin {
    _addAllowedSenderOnChain(sender);
  }
}

contract SphereXConfigTest is Test, Prankster {
  event ChangedSpherexOperator(address oldSphereXAdmin, address newSphereXAdmin);
  event ChangedSpherexEngineAddress(address oldEngineAddress, address newEngineAddress);
  event SpherexAdminTransferStarted(address currentAdmin, address pendingAdmin);
  event SpherexAdminTransferCompleted(address oldAdmin, address newAdmin);
  event NewAllowedSenderOnchain(address sender);
  event NewSenderOnEngine(address sender);

  error SphereXOperatorRequired();
  error SphereXAdminRequired();
  error SphereXOperatorOrAdminRequired();
  error SphereXNotPendingAdmin();
  error SphereXNotEngine();

  BadEngine internal immutable badEngine = new BadEngine();
  GoodEngine internal immutable goodEngine = new GoodEngine();
  MockConfig internal config;

  address internal admin = toAddr('admin');
  address internal operator = toAddr('operator');

  function setUp() external {
    config = new MockConfig(admin, operator, address(goodEngine));
  }

  function _checkConfig(
    address pendingSphereXAdmin,
    address sphereXAdmin,
    address sphereXOperator,
    address sphereXEngine
  ) internal {
    assertEq(pendingSphereXAdmin, config.pendingSphereXAdmin(), 'pendingSphereXAdmin');
    assertEq(sphereXAdmin, config.sphereXAdmin(), 'sphereXAdmin');
    assertEq(sphereXOperator, config.sphereXOperator(), 'sphereXOperator');
    assertEq(sphereXEngine, config.sphereXEngine(), 'sphereXEngine');
  }

  function test_AuthenticatedMethod(
    address target,
    address allowedSender,
    bytes memory data,
    bytes4 errorSelector
  ) internal {
    startPrank(address(uint160(allowedSender) + 1));
    (bool success, ) = target.call(data);
    assertTrue(success, 'call failed');
    stopPrank();
    startPrank(address(uint160(allowedSender) + 1));
    vm.expectRevert(errorSelector);
    target.call(data);
    stopPrank();
  }

  // ========================================================================== //
  //                          transferSphereXAdminRole                          //
  // ========================================================================== //

  function test_transferSphereXAdminRole(address newAdmin) external {
    vm.expectEmit(address(config));
    emit SpherexAdminTransferStarted(admin, newAdmin);
    vm.prank(admin);
    config.transferSphereXAdminRole(newAdmin);
    _checkConfig(newAdmin, admin, operator, address(goodEngine));
  }

  function test_transferSphereXAdminRole_SphereXAdminRequired(address newAdmin) external {
    vm.expectRevert(SphereXAdminRequired.selector);
    config.transferSphereXAdminRole(newAdmin);
  }

  // ========================================================================== //
  //                           acceptSphereXAdminRole                           //
  // ========================================================================== //

  function test_acceptSphereXAdminRole(address newAdmin) external {
    vm.expectEmit(address(config));
    emit SpherexAdminTransferStarted(admin, newAdmin);
    vm.prank(admin);
    config.transferSphereXAdminRole(newAdmin);

    vm.expectEmit(address(config));
    emit SpherexAdminTransferCompleted(admin, newAdmin);
    vm.prank(newAdmin);
    config.acceptSphereXAdminRole();

    _checkConfig(address(0), newAdmin, operator, address(goodEngine));
  }

  function test_acceptSphereXAdminRole_SphereXNotPendingAdmin(address newAdmin) external {
    vm.assume(newAdmin != address(1));
    vm.expectRevert(SphereXNotPendingAdmin.selector);
    config.acceptSphereXAdminRole();

    vm.expectEmit(address(config));
    emit SpherexAdminTransferStarted(admin, newAdmin);
    vm.prank(admin);
    config.transferSphereXAdminRole(newAdmin);

    vm.expectRevert(SphereXNotPendingAdmin.selector);
    vm.prank(address(1));
    config.acceptSphereXAdminRole();
  }

  // ========================================================================== //
  //                            changeSphereXOperator                           //
  // ========================================================================== //

  function test_changeSphereXOperator(address newOperator) external {
    vm.expectEmit(address(config));
    emit ChangedSpherexOperator(operator, newOperator);
    vm.prank(admin);
    config.changeSphereXOperator(newOperator);
    _checkConfig(address(0), admin, newOperator, address(goodEngine));
  }

  function test_changeSphereXOperator_SphereXAdminRequired(address newOperator) external {
    vm.expectRevert(SphereXAdminRequired.selector);
    config.changeSphereXOperator(newOperator);
  }

  // ========================================================================== //
  //                             changeSphereXEngine                            //
  // ========================================================================== //

  function test_changeSphereXEngine_NullEngine() external {
    vm.expectEmit(address(config));
    emit ChangedSpherexEngineAddress(address(goodEngine), address(0));
    vm.prank(operator);
    config.changeSphereXEngine(address(0));
    _checkConfig(address(0), admin, operator, address(0));
  }

  function test_changeSphereXEngine_NotEngine() external {
    vm.expectRevert(SphereXNotEngine.selector);
    vm.prank(operator);
    config.changeSphereXEngine(address(badEngine));
  }

  function test_changeSphereXEngine_GoodEngine() external {
    GoodEngine newEngine = new GoodEngine();
    vm.expectEmit(address(config));
    emit ChangedSpherexEngineAddress(address(goodEngine), address(newEngine));
    vm.prank(operator);
    config.changeSphereXEngine(address(newEngine));
    _checkConfig(address(0), admin, operator, address(newEngine));
  }

  // ========================================================================== //
  //                          _addAllowedSenderOnChain                          //
  // ========================================================================== //

  function test__addAllowedSenderOnChain(address sender) external {
    vm.expectEmit(address(goodEngine));
    emit NewSenderOnEngine(sender);
    vm.expectEmit(address(config));
    emit NewAllowedSenderOnchain(sender);
    vm.prank(admin);
    config.addSender(sender);
  }

  function test__addAllowedSenderOnChain_NullEngine(address sender) external {
    vm.prank(operator);
    config.changeSphereXEngine(address(0));

    vm.prank(admin);
    config.addSender(sender);
  }

  function toAddr(bytes memory label) internal pure returns (address addr) {
    addr = address(uint160(uint(keccak256(label))));
  }
}
