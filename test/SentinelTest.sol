// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import { Test } from 'forge-std/Test.sol';
import { IWildcatSanctionsSentinel, WildcatSanctionsSentinel, WildcatSanctionsEscrow, IChainalysisSanctionsList } from 'src/WildcatSanctionsSentinel.sol';
import 'src/interfaces/IWildcatArchController.sol';
import { SanctionsList } from './shared/TestConstants.sol';

import { MockChainalysis, deployMockChainalysis } from './shared/mocks/MockChainalysis.sol';
import { MockERC20 } from './shared/mocks/MockERC20.sol';

// -- TEMP START --
contract MockWildcatArchController {
  mapping(address market => bool) public isRegisteredMarket;

  function setIsRegsiteredMarket(address market, bool isRegistered) external {
    isRegisteredMarket[market] = isRegistered;
  }
}

// -- TEMP END --

contract SentinelTest is Test {
  event NewSanctionsEscrow(
    address indexed borrower,
    address indexed account,
    address indexed asset
  );
  event SanctionOverride(address indexed borrower, address indexed account);

  MockWildcatArchController internal archController;
  WildcatSanctionsSentinel internal sentinel;

  function setUp() public {
    deployMockChainalysis();
    archController = new MockWildcatArchController();
    sentinel = new WildcatSanctionsSentinel(address(archController), address(SanctionsList));
  }

  function testWildcatSanctionsEscrowInitcodeHash() public {
    assertEq(
      sentinel.WildcatSanctionsEscrowInitcodeHash(),
      keccak256(type(WildcatSanctionsEscrow).creationCode)
    );
  }

  function testChainalysisSanctionsList() public {
    assertEq(address(sentinel.chainalysisSanctionsList()), address(SanctionsList));
  }

  function testArchController() public {
    assertEq(address(sentinel.archController()), address(archController));
  }

  function testIsSanctioned() public {
    assertEq(sentinel.isSanctioned(address(0), address(1)), false);
    MockChainalysis(address(SanctionsList)).sanction(address(1));
    assertEq(sentinel.isSanctioned(address(0), address(1)), true);
    vm.prank(address(0));
    sentinel.overrideSanction(address(1));
    assertEq(sentinel.isSanctioned(address(0), address(1)), false);
  }

  function testFuzzIsSanctioned(
    address borrower,
    bool overrideSanctionStatus,
    address forWhomTheBellTolls,
    bool sanctioned
  ) public {
    assertEq(sentinel.isSanctioned(borrower, forWhomTheBellTolls), false);
    if (sanctioned) MockChainalysis(address(SanctionsList)).sanction(forWhomTheBellTolls);
    if (overrideSanctionStatus) {
      vm.prank(borrower);
      sentinel.overrideSanction(forWhomTheBellTolls);
    }
    assertEq(
      sentinel.isSanctioned(borrower, forWhomTheBellTolls),
      sanctioned && !overrideSanctionStatus
    );
  }

  function testSanctionOverride() external {
    address borrower = address(1);
    address account = address(2);

    assertEq(sentinel.sanctionOverrides(borrower, account), false);
    vm.prank(borrower);
    sentinel.overrideSanction(account);
    assertEq(sentinel.sanctionOverrides(borrower, account), true);
    assertFalse(sentinel.isSanctioned(borrower, account));
    MockChainalysis(address(SanctionsList)).sanction(account);
    assertFalse(sentinel.isSanctioned(borrower, account));
  }

  function testRemoveSanctionOverride() external {
    address borrower = address(1);
    address account = address(2);

    assertEq(sentinel.sanctionOverrides(borrower, account), false);
    vm.prank(borrower);
    sentinel.overrideSanction(account);
    assertEq(sentinel.sanctionOverrides(borrower, account), true);
    assertFalse(sentinel.isSanctioned(borrower, account));
    MockChainalysis(address(SanctionsList)).sanction(account);
    assertFalse(sentinel.isSanctioned(borrower, account));
    vm.prank(borrower);
    sentinel.removeSanctionOverride(account);
    assertEq(sentinel.sanctionOverrides(borrower, account), false);
    assertTrue(sentinel.isSanctioned(borrower, account));
  }

  function testGetEscrowAddress() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(3);

    assertEq(
      sentinel.getEscrowAddress(borrower, account, asset),
      address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                address(sentinel),
                keccak256(abi.encode(borrower, account, asset)),
                sentinel.WildcatSanctionsEscrowInitcodeHash()
              )
            )
          )
        )
      )
    );
  }

  function testFuzzGetEscrowAddress(address borrower, address account, address asset) public {
    assertEq(
      sentinel.getEscrowAddress(borrower, account, asset),
      address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                address(sentinel),
                keccak256(abi.encode(borrower, account, asset)),
                sentinel.WildcatSanctionsEscrowInitcodeHash()
              )
            )
          )
        )
      )
    );
  }

  function testCreateEscrow() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    uint256 amount = 1;

    archController.setIsRegsiteredMarket(address(this), true);
    address expectedEscrowAddress = sentinel.getEscrowAddress(borrower, account, asset);

    vm.expectEmit(true, true, true, true, address(sentinel));
    emit NewSanctionsEscrow(borrower, account, asset);

    vm.expectEmit(true, true, true, true, address(sentinel));
    emit SanctionOverride(borrower, expectedEscrowAddress);

    address escrow = sentinel.createEscrow(borrower, account, asset);
    MockERC20(asset).mint(escrow, amount);
    (address escrowedAsset, uint256 escrowedAmount) = WildcatSanctionsEscrow(escrow)
      .escrowedAsset();

    assertEq(escrow, expectedEscrowAddress);
    assertEq(escrow, sentinel.createEscrow(borrower, account, asset));
    assertEq(WildcatSanctionsEscrow(escrow).borrower(), borrower);
    assertEq(WildcatSanctionsEscrow(escrow).account(), account);
    assertEq(WildcatSanctionsEscrow(escrow).balance(), amount);
    assertEq(
      WildcatSanctionsEscrow(escrow).canReleaseEscrow(),
      !SanctionsList.isSanctioned(account)
    );
    assertTrue(
      sentinel.sanctionOverrides(borrower, escrow),
      'sanction override not set for escrow'
    );
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, amount);
  }

  function testFuzzCreateEscrow(
    address borrower,
    address account,
    bytes32 assetSalt,
    uint256 amount,
    bool sanctioned
  ) public {
    address asset = address(new MockERC20{ salt: assetSalt }());

    archController.setIsRegsiteredMarket(address(this), true);
    if (sanctioned) MockChainalysis(address(SanctionsList)).sanction(account);

    vm.expectEmit(true, true, true, true, address(sentinel));
    emit NewSanctionsEscrow(borrower, account, asset);

    address escrow = sentinel.createEscrow(borrower, account, asset);
    MockERC20(asset).mint(escrow, amount);
    (address escrowedAsset, uint256 escrowedAmount) = WildcatSanctionsEscrow(escrow)
      .escrowedAsset();

    assertEq(escrow, sentinel.getEscrowAddress(borrower, account, asset));
    assertEq(escrow, sentinel.createEscrow(borrower, account, asset));
    assertEq(WildcatSanctionsEscrow(escrow).borrower(), borrower);
    assertEq(WildcatSanctionsEscrow(escrow).account(), account);
    assertEq(WildcatSanctionsEscrow(escrow).balance(), amount);
    assertEq(
      WildcatSanctionsEscrow(escrow).canReleaseEscrow(),
      !SanctionsList.isSanctioned(account)
    );
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, amount);
  }
}
