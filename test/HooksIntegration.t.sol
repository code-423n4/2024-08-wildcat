// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import './BaseMarketTest.sol';
import './shared/mocks/MockHooks.sol';

contract HooksIntegrationTest is BaseMarketTest {
  function _getHooksTemplate() internal virtual override returns (address) {
    return LibStoredInitCode.deployInitCode(type(MockHooks).creationCode);
  }

  function setUp() public virtual override {}

  function _callMarket(
    bytes memory _calldata,
    bytes memory _expectedReturndata,
    string memory label
  ) internal {
    (bool success, bytes memory returndata) = address(market).call(_calldata);
    if (!success) {
      assembly {
        revert(add(returndata, 0x20), mload(returndata))
      }
    }
    assertBytesEq(returndata, _expectedReturndata, label);
  }

  function _setUp(StandardHooksConfig memory configInput) internal {
    deployHooksInstance(parameters, false);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    MockHooks(address(hooks)).setConfig(
      encodeHooksDeploymentConfig({ optionalFlags: config, requiredFlags: EmptyHooksConfig })
    );
    parameters.hooksConfig = config;
    setUpContracts(false);
    MockHooks(address(hooks)).reset();
  }

  // ========================================================================== //
  //                                  onDeposit                                 //
  // ========================================================================== //

  function test_onDeposit(StandardHooksConfig memory config, bytes memory extraData) external {
    _setUp(config);
    MarketState memory state = pendingState();
    startPrank(alice);
    asset.mint(alice, 1e18);
    asset.approve(address(market), 1e18);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.deposit.selector, 100),
      extraData
    );
    if (config.useOnDeposit) {
      vm.expectEmit(address(hooks));
      emit OnDepositCalled(alice, 100, state, extraData);
    }
    _callMarket(_calldata, '', 'deposit');
    stopPrank();
    if (config.useOnDeposit) {
      assertBytesEq(
        MockHooks(address(hooks)).lastExtraData(),
        extraData,
        'extraData should be passed to onDeposit'
      );
    } else {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  function test_onDeposit_depositUpTo(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    MarketState memory state = pendingState();
    startPrank(alice);
    asset.mint(alice, 1e18);
    asset.approve(address(market), 1e18);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.depositUpTo.selector, 100),
      extraData
    );
    if (config.useOnDeposit) {
      vm.expectEmit(address(hooks));
      emit OnDepositCalled(alice, 100, state, extraData);
    }
    _callMarket(_calldata, abi.encode(100), 'depositUpTo returndata');
    stopPrank();
    if (config.useOnDeposit) {
      assertBytesEq(
        MockHooks(address(hooks)).lastExtraData(),
        extraData,
        'extraData should be passed to onDeposit'
      );
    } else {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                              onQueueWithdrawal                             //
  // ========================================================================== //

  function test_onQueueWithdrawal(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    _deposit(alice, 1e18);
    MockHooks(address(hooks)).reset();
    startPrank(alice);
    MarketState memory state = pendingState();
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.queueWithdrawal.selector, 100),
      extraData
    );
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    bytes memory _returndata = abi.encode(expiry);
    state.pendingWithdrawalExpiry = expiry;
    if (config.useOnQueueWithdrawal) {
      vm.expectEmit(address(hooks));
      emit OnQueueWithdrawalCalled(alice, expiry, 100, state, extraData);
    }
    _callMarket(_calldata, _returndata, 'queueWithdrawal');
    if (!config.useOnQueueWithdrawal) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  function test_onQueueWithdrawal_queueFullWithdrawal(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    _deposit(alice, 1e18);
    MockHooks(address(hooks)).reset();
    startPrank(alice);
    MarketState memory state = pendingState();
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.queueFullWithdrawal.selector),
      extraData
    );
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    bytes memory _returndata = abi.encode(expiry);
    state.pendingWithdrawalExpiry = expiry;
    if (config.useOnQueueWithdrawal) {
      vm.expectEmit(address(hooks));
      emit OnQueueWithdrawalCalled(alice, expiry, 1e18, state, extraData);
    }
    _callMarket(_calldata, _returndata, 'queueWithdrawal');
    if (!config.useOnQueueWithdrawal) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  function test_onQueueWithdrawal_nukeFromOrbit(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    _deposit(alice, 1e18);
    MockHooks(address(hooks)).reset();
    sanctionsSentinel.sanction(alice);
    startPrank(alice);
    MarketState memory state = pendingState();
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.nukeFromOrbit.selector, alice),
      extraData
    );
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    state.pendingWithdrawalExpiry = expiry;
    if (config.useOnQueueWithdrawal) {
      vm.expectEmit(address(hooks));
      emit OnQueueWithdrawalCalled(alice, expiry, 1e18, state, '');
    }
    _callMarket(_calldata, '', 'nukeFromOrbit');
    if (!config.useOnQueueWithdrawal && !config.useOnNukeFromOrbit) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                             onExecuteWithdrawal                            //
  // ========================================================================== //

  function test_onExecuteWithdrawal(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);

    _deposit(alice, 1e18);
    _requestWithdrawal(alice, 1e18);
    MockHooks(address(hooks)).reset();
    uint32 expiry = previousState.pendingWithdrawalExpiry;
    fastForward(parameters.withdrawalBatchDuration + 1);
    MarketState memory state = pendingState();
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.executeWithdrawal.selector, alice, expiry),
      extraData
    );
    if (config.useOnExecuteWithdrawal) {
      vm.expectEmit(address(hooks));
      emit OnExecuteWithdrawalCalled(alice, 1e18, state, extraData);
    }
    _callMarket(_calldata, abi.encode(1e18), 'executeWithdrawal');

    if (!config.useOnExecuteWithdrawal) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  function test_onExecuteWithdrawal_executeWithdrawals(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);

    _deposit(alice, 1e18);
    _deposit(bob, 1e18);
    _requestWithdrawal(alice, 1e18);
    _requestWithdrawal(bob, 1e18);
    MockHooks(address(hooks)).reset();
    uint32 expiry = previousState.pendingWithdrawalExpiry;
    fastForward(parameters.withdrawalBatchDuration + 1);
    MarketState memory state = pendingState();
    address[] memory accounts = new address[](2);
    accounts[0] = alice;
    accounts[1] = bob;
    uint32[] memory expiries = new uint32[](2);
    (expiries[0], expiries[1]) = (expiry, expiry);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.executeWithdrawals.selector, accounts, expiries),
      extraData
    );
    if (config.useOnExecuteWithdrawal) {
      vm.expectEmit(address(hooks));
      emit OnExecuteWithdrawalCalled(alice, 1e18, state, '');
      _trackExecuteWithdrawal(state, expiry, alice);
      vm.expectEmit(address(hooks));
      emit OnExecuteWithdrawalCalled(bob, 1e18, state, '');
      _trackExecuteWithdrawal(state, expiry, bob);
    }
    uint256[] memory amounts = new uint256[](2);
    (amounts[0], amounts[1]) = (1e18, 1e18);
    _callMarket(_calldata, abi.encode(amounts), 'executeWithdrawals');

    if (!config.useOnExecuteWithdrawal) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                                 onTransfer                                 //
  // ========================================================================== //

  function test_onTransfer(
    StandardHooksConfig memory config,
    address to,
    bytes memory extraData
  ) external {
    _setUp(config);
    _deposit(alice, 1e18);
    MockHooks(address(hooks)).reset();
    MarketState memory state = pendingState();

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.transfer.selector, to, 1e18),
      extraData
    );

    if (config.useOnTransfer) {
      vm.expectEmit(address(hooks));
      emit OnTransferCalled(alice, alice, to, 1e18, state, extraData);
    }
    vm.prank(alice);
    _callMarket(_calldata, abi.encode(true), 'transfer');
    if (!config.useOnTransfer) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  function test_onTransfer_TransferFrom(
    StandardHooksConfig memory config,
    address to,
    bytes memory extraData
  ) external {
    _setUp(config);
    _deposit(alice, 1e18);
    vm.prank(alice);
    market.approve(bob, 1e18);

    MockHooks(address(hooks)).reset();
    MarketState memory state = pendingState();

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.transferFrom.selector, alice, to, 1e18),
      extraData
    );

    if (config.useOnTransfer) {
      vm.expectEmit(address(hooks));
      emit OnTransferCalled(bob, alice, to, 1e18, state, extraData);
    }
    vm.prank(bob);
    _callMarket(_calldata, abi.encode(true), 'transferFrom');
    if (!config.useOnTransfer) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                                  onBorrow                                  //
  // ========================================================================== //

  function test_onBorrow(StandardHooksConfig memory config, bytes memory extraData) external {
    _setUp(config);
    _deposit(alice, 1e18);
    MockHooks(address(hooks)).reset();
    startPrank(borrower);
    MarketState memory state = pendingState();

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.borrow.selector, 100),
      extraData
    );
    if (config.useOnBorrow) {
      vm.expectEmit(address(hooks));
      emit OnBorrowCalled(100, state, extraData);
    }
    _callMarket(_calldata, '', 'borrow');
    if (!config.useOnBorrow) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                                   onRepay                                  //
  // ========================================================================== //

  function test_onRepay(StandardHooksConfig memory config, bytes memory extraData) external {
    _setUp(config);
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    MockHooks(address(hooks)).reset();
    startPrank(borrower);
    asset.mint(borrower, 1e18);
    asset.approve(address(market), 1e18);
    lastTotalAssets += 100;
    MarketState memory state = pendingState();

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.repay.selector, 100),
      extraData
    );
    if (config.useOnRepay) {
      vm.expectEmit(address(hooks));
      emit OnRepayCalled(100, state, extraData);
    }
    _callMarket(_calldata, '', 'repay');
    if (!config.useOnRepay) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  function test_onRepay_repayAndProcessUnpaidWithdrawalBatches(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    _depositBorrowWithdraw(alice, 1e18, 8e17, 1e18);
    MockHooks(address(hooks)).reset();
    startPrank(borrower);
    asset.mint(borrower, 1e18);
    asset.approve(address(market), 1e18);
    lastTotalAssets += 8e17;
    MarketState memory state = pendingState();

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.repayAndProcessUnpaidWithdrawalBatches.selector, 8e17, 1),
      extraData
    );
    if (config.useOnRepay) {
      vm.expectEmit(address(hooks));
      emit OnRepayCalled(8e17, state, extraData);
    }
    _callMarket(_calldata, '', 'repayAndProcessUnpaidWithdrawalBatches');
    if (!config.useOnRepay) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                                onCloseMarket                               //
  // ========================================================================== //

  function test_onCloseMarket(StandardHooksConfig memory config, bytes memory extraData) external {
    _setUp(config);
    MarketState memory state = pendingState();

    startPrank(borrower);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.closeMarket.selector),
      extraData
    );
    if (config.useOnCloseMarket) {
      vm.expectEmit(address(hooks));
      emit OnCloseMarketCalled(state, extraData);
    }
    _callMarket(_calldata, '', 'closeMarket');
    if (!config.useOnCloseMarket) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                             onSetMaxTotalSupply                            //
  // ========================================================================== //

  function test_onSetMaxTotalSupply(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    MarketState memory state = pendingState();

    startPrank(borrower);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.setMaxTotalSupply.selector, 100),
      extraData
    );
    if (config.useOnSetMaxTotalSupply) {
      vm.expectEmit(address(hooks));
      emit OnSetMaxTotalSupplyCalled(100, state, extraData);
    }
    _callMarket(_calldata, '', 'setMaxTotalSupply');
    if (!config.useOnSetMaxTotalSupply) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                               onNukeFromOrbit                              //
  // ========================================================================== //

  function test_onNukeFromOrbit(
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    _setUp(config);
    _deposit(alice, 1e18);
    MockHooks(address(hooks)).reset();
    sanctionsSentinel.sanction(alice);
    startPrank(alice);
    MarketState memory state = pendingState();
    if (config.useOnNukeFromOrbit) {
      vm.expectEmit(address(hooks));
      emit OnNukeFromOrbitCalled(alice, state, extraData);
    }
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.nukeFromOrbit.selector, alice),
      extraData
    );
    uint32 expiry = uint32(block.timestamp + parameters.withdrawalBatchDuration);
    state.pendingWithdrawalExpiry = expiry;
    if (config.useOnQueueWithdrawal) {
      vm.expectEmit(address(hooks));
      emit OnQueueWithdrawalCalled(alice, expiry, 1e18, state, '');
    }
    _callMarket(_calldata, '', 'nukeFromOrbit');
    if (!config.useOnQueueWithdrawal && !config.useOnNukeFromOrbit) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                            onSetProtocolFeeBips                            //
  // ========================================================================== //

  function test_onSetProtocolFeeBips(
    uint16 protocolFeeBips,
    StandardHooksConfig memory config,
    bytes memory extraData
  ) external {
    protocolFeeBips = uint16(bound(protocolFeeBips, 0, 999));
    _setUp(config);
    MarketState memory state = pendingState();
    if (config.useOnSetProtocolFeeBips) {
      vm.expectEmit(address(hooks));
      emit OnSetProtocolFeeBipsCalled(protocolFeeBips, state, extraData);
    }
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(market.setProtocolFeeBips.selector, protocolFeeBips),
      extraData
    );
    vm.prank(address(hooksFactory));
    _callMarket(_calldata, '', 'setProtocolFeeBips');
    if (!config.useOnSetProtocolFeeBips) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    }
  }

  // ========================================================================== //
  //                   onSetAnnualInterestAndReserveRatioBips                   //
  // ========================================================================== //

  function test_onSetAnnualInterestAndReserveRatioBips(
    StandardHooksConfig memory config,
    bytes memory extraData,
    uint16 annualInterestBips,
    uint16 reserveRatioBips,
    uint16 annualInterestBipsToReturn,
    uint16 reserveRatioBipsToReturn
  ) external {
    annualInterestBips = uint16(bound(annualInterestBips, 0, 10_000));
    annualInterestBipsToReturn = uint16(bound(annualInterestBipsToReturn, 0, 10_000));
    reserveRatioBips = uint16(bound(reserveRatioBips, 0, 10_000));
    reserveRatioBipsToReturn = uint16(bound(reserveRatioBipsToReturn, 0, 10_000));
    _setUp(config);
    MockHooks(address(hooks)).setAnnualInterestAndReserveRatioBips(
      annualInterestBipsToReturn,
      reserveRatioBipsToReturn
    );
    MarketState memory state = pendingState();
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(
        market.setAnnualInterestAndReserveRatioBips.selector,
        annualInterestBips,
        reserveRatioBips
      ),
      extraData
    );

    if (config.useOnSetAnnualInterestAndReserveRatioBips) {
      vm.expectEmit(address(hooks));
      emit OnSetAnnualInterestAndReserveRatioBipsCalled(
        annualInterestBips,
        reserveRatioBips,
        state,
        extraData
      );
    }
    vm.prank(borrower);
    _callMarket(_calldata, '', 'setAnnualInterestAndReserveRatioBips');
    if (!config.useOnSetAnnualInterestAndReserveRatioBips) {
      assertEq(MockHooks(address(hooks)).lastCalldataHash(), 0);
    } else {
      assertEq(market.annualInterestBips(), annualInterestBipsToReturn);
      assertEq(market.reserveRatioBips(), reserveRatioBipsToReturn);
    }
  }
}
