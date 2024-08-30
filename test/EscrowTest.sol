// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;
import { Test } from 'forge-std/Test.sol';
import { WildcatSanctionsSentinel, IChainalysisSanctionsList } from 'src/WildcatSanctionsSentinel.sol';
import { WildcatSanctionsEscrow, IWildcatSanctionsEscrow } from 'src/WildcatSanctionsEscrow.sol';
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

contract EscrowTest is Test {
  event EscrowReleased(address indexed account, address indexed asset, uint256 amount);

  MockWildcatArchController internal archController;
  WildcatSanctionsSentinel internal sentinel;

  function setUp() public {
    deployMockChainalysis();
    archController = new MockWildcatArchController();
    sentinel = new WildcatSanctionsSentinel(address(archController), address(SanctionsList));
    archController.setIsRegsiteredMarket(address(this), true);
  }

  function testImmutables() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());

    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    (address escrowedAsset, uint256 escrowedAmount) = escrow.escrowedAsset();

    assertEq(escrow.borrower(), borrower);
    assertEq(escrow.account(), account);
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, 0);
  }

  function testFuzzImmutables(address borrower, address account, bytes32 assetSalt) public {
    address asset = address(new MockERC20{ salt: assetSalt }());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    (address escrowedAsset, uint256 escrowedAmount) = escrow.escrowedAsset();

    assertEq(escrow.borrower(), borrower);
    assertEq(escrow.account(), account);
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, 0);
  }

  function testBalance() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    assertEq(escrow.balance(), 0);
    MockERC20(asset).mint(address(escrow), 1);
    assertEq(escrow.balance(), 1);
  }

  function testFuzzBalance(
    address borrower,
    address account,
    bytes32 assetSalt,
    uint256 amount
  ) public {
    address asset = address(new MockERC20{ salt: assetSalt }());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    assertEq(escrow.balance(), 0);
    MockERC20(asset).mint(address(escrow), amount);
    assertEq(escrow.balance(), amount);
  }

  function testCanReleaseEscrow() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    assertEq(escrow.canReleaseEscrow(), true);
    MockChainalysis(address(SanctionsList)).sanction(account);
    assertEq(escrow.canReleaseEscrow(), false);
  }

  function testFuzzCanReleaseEscrow(
    address borrower,
    address account,
    address asset,
    bool sanctioned
  ) public {
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    if (sanctioned) MockChainalysis(address(SanctionsList)).sanction(account);

    assertEq(
      escrow.canReleaseEscrow(),
      !MockChainalysis(address(SanctionsList)).isSanctioned(account)
    );
  }

  function testEscrowedAsset() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    (address escrowedAsset, uint256 escrowedAmount) = escrow.escrowedAsset();
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, 0);

    MockERC20(asset).mint(address(escrow), 1);

    (escrowedAsset, escrowedAmount) = escrow.escrowedAsset();
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, 1);
  }

  function testFuzzEscrowedAsset(
    address borrower,
    address account,
    bytes32 assetSalt,
    uint256 amount
  ) public {
    address asset = address(new MockERC20{ salt: assetSalt }());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    (address escrowedAsset, uint256 escrowedAmount) = escrow.escrowedAsset();
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, 0);

    MockERC20(asset).mint(address(escrow), amount);

    (escrowedAsset, escrowedAmount) = escrow.escrowedAsset();
    assertEq(escrowedAsset, asset);
    assertEq(escrowedAmount, amount);
  }

  function testReleaseEscrowNotSanctioned() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    MockERC20(asset).mint(address(escrow), 1);
    assertEq(escrow.balance(), 1);

    vm.expectEmit(true, true, true, true, address(escrow));
    emit EscrowReleased(account, asset, 1);

    escrow.releaseEscrow();

    assertEq(escrow.balance(), 0);
  }

  function testReleaseEscrowWithOverride() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    MockChainalysis(address(SanctionsList)).sanction(account);

    MockERC20(asset).mint(address(escrow), 1);
    assertEq(escrow.balance(), 1);

    vm.prank(borrower);
    sentinel.overrideSanction(account);

    vm.expectEmit(true, true, true, true, address(escrow));
    emit EscrowReleased(account, asset, 1);

    escrow.releaseEscrow();

    assertEq(escrow.balance(), 0);
  }

  function testReleaseEscrowCanNotReleaseEscrow() public {
    address borrower = address(1);
    address account = address(2);
    address asset = address(new MockERC20());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    MockChainalysis(address(SanctionsList)).sanction(account);

    vm.expectRevert(IWildcatSanctionsEscrow.CanNotReleaseEscrow.selector);
    escrow.releaseEscrow();
  }

  function testFuzzReleaseEscrow(
    address caller,
    address borrower,
    address account,
    bytes32 assetSalt,
    uint256 amount,
    bool sanctioned
  ) public {
    address asset = address(new MockERC20{ salt: assetSalt }());
    WildcatSanctionsEscrow escrow = WildcatSanctionsEscrow(
      sentinel.createEscrow(borrower, account, asset)
    );

    if (sanctioned) MockChainalysis(address(SanctionsList)).sanction(account);

    MockERC20(asset).mint(address(escrow), amount);
    assertEq(escrow.balance(), amount);

    if (sanctioned) {
      vm.expectRevert(IWildcatSanctionsEscrow.CanNotReleaseEscrow.selector);
      escrow.releaseEscrow();
    } else {
      vm.expectEmit(true, true, true, true, address(escrow));
      emit EscrowReleased(account, asset, amount);

      vm.prank(caller);
      escrow.releaseEscrow();

      assertEq(escrow.balance(), 0);
    }
  }
}
