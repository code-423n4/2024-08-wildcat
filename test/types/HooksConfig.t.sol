// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'src/types/HooksConfig.sol';
import { Test, console2 } from 'forge-std/Test.sol';
import '../helpers/Assertions.sol';
import '../helpers/fuzz/MarketStateFuzzInputs.sol';
import '../shared/mocks/MockHooks.sol';
import '../shared/mocks/MockHookCaller.sol';

contract HooksConfigTest is Test, Assertions {
  MockHooks internal hooks = new MockHooks(address(this), '');
  MockHookCaller internal mockHookCaller = new MockHookCaller();

  function _callMockHookCaller(bytes memory _calldata) internal {
    assembly {
      let success := call(
        gas(),
        sload(mockHookCaller.slot),
        0,
        add(_calldata, 0x20),
        mload(_calldata),
        0,
        0
      )
      if iszero(success) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function testEncode(StandardHooksConfig memory input) external {
    HooksConfig hooks = input.toHooksConfig();
    assertEq(hooks, input);
  }

  function test_mergeSharedFlags(
    StandardHooksConfig memory _a,
    StandardHooksConfig memory _b
  ) external {
    StandardHooksConfig memory expectedMergeResult = _a.mergeSharedFlags(_b);
    HooksConfig a = _a.toHooksConfig();
    HooksConfig b = _b.toHooksConfig();
    HooksConfig actualMergeResult = a.mergeSharedFlags(b);
    assertEq(actualMergeResult, expectedMergeResult, 'mergeSharedFlags');
  }

  function test_encodeHooksDeploymentConfig(
    StandardHooksDeploymentConfig memory _deploymentFlags
  ) external {
    _deploymentFlags.optional.hooksAddress = address(0);
    _deploymentFlags.required.hooksAddress = address(0);
    HooksConfig _optional = _deploymentFlags.optional.toHooksConfig();
    HooksConfig _required = _deploymentFlags.required.toHooksConfig();
    HooksDeploymentConfig flags = encodeHooksDeploymentConfig(_optional, _required);
    assertEq(flags.optionalFlags(), _optional, 'optionalFlags');
    assertEq(flags.requiredFlags(), _required, 'requiredFlags');
  }

  function test_mergeFlags(
    StandardHooksConfig memory _config,
    StandardHooksDeploymentConfig memory _deploymentFlags
  ) external {
    StandardHooksConfig memory expectedMergeResult = _config.mergeFlags(_deploymentFlags);
    HooksConfig config = _config.toHooksConfig();
    HooksDeploymentConfig flags = encodeHooksDeploymentConfig(
      _deploymentFlags.optional.toHooksConfig(),
      _deploymentFlags.required.toHooksConfig()
    );

    HooksConfig actualMergeResult = config.mergeFlags(flags);
    assertEq(actualMergeResult, expectedMergeResult, 'mergeSharedFlags');
  }

  function test_onDeposit(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.deposit.selector, 100),
      extraData
    );
    if (config.useOnDeposit()) {
      vm.expectEmit();
      emit OnDepositCalled(address(this), 100, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnDeposit()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onQueueWithdrawal(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    uint scaledAmount,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    uint32 expiry = uint32(block.timestamp + 1 days);

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.queueWithdrawal.selector, expiry, scaledAmount),
      extraData
    );
    if (config.useOnQueueWithdrawal()) {
      vm.expectEmit();
      emit OnQueueWithdrawalCalled(address(this), expiry, scaledAmount, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnQueueWithdrawal()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onExecuteWithdrawal(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    address lender,
    uint128 normalizedAmountWithdrawn,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(
        mockHookCaller.executeWithdrawal.selector,
        lender,
        normalizedAmountWithdrawn
      ),
      extraData
    );
    if (config.useOnExecuteWithdrawal()) {
      vm.expectEmit();
      emit OnExecuteWithdrawalCalled(lender, normalizedAmountWithdrawn, state, extraData);
    }
    _callMockHookCaller(_calldata);

    if (!config.useOnExecuteWithdrawal()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onTransfer(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    address to,
    uint256 scaledAmount,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);

    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.transfer.selector, to, scaledAmount),
      extraData
    );

    if (config.useOnTransfer()) {
      vm.expectEmit();
      emit OnTransferCalled(address(this), address(this), to, scaledAmount, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnTransfer()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onBorrow(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.borrow.selector, 100),
      extraData
    );
    if (config.useOnBorrow()) {
      vm.expectEmit();
      emit OnBorrowCalled(100, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnBorrow()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onRepay(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.repay.selector, 100),
      extraData
    );
    if (config.useOnRepay()) {
      vm.expectEmit();
      emit OnRepayCalled(100, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnRepay()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onCloseMarket(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.closeMarket.selector),
      extraData
    );
    if (config.useOnCloseMarket()) {
      vm.expectEmit();
      emit OnCloseMarketCalled(state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnCloseMarket()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onNukeFromOrbit(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData,
    address lender
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(
        mockHookCaller.nukeFromOrbit.selector,
        lender
      ),
      extraData
    );
    if (config.useOnNukeFromOrbit()) {
      vm.expectEmit();
      emit OnNukeFromOrbitCalled(lender, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnNukeFromOrbit()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onSetMaxTotalSupply(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.setMaxTotalSupply.selector, 100),
      extraData
    );
    if (config.useOnSetMaxTotalSupply()) {
      vm.expectEmit();
      emit OnSetMaxTotalSupplyCalled(100, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnSetMaxTotalSupply()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onSetAnnualInterestAndReserveRatioBips(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData,
    uint16 annualInterestBips,
    uint16 reserveRatioBips,
    uint16 annualInterestBipsToReturn,
    uint16 reserveRatioBipsToReturn
  ) external {
    hooks.setAnnualInterestAndReserveRatioBips(
      annualInterestBipsToReturn,
      reserveRatioBipsToReturn
    );
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(
        mockHookCaller.setAnnualInterestAndReserveRatioBips.selector,
        annualInterestBips,
        reserveRatioBips
      ),
      extraData
    );

    if (config.useOnSetAnnualInterestAndReserveRatioBips()) {
      vm.expectEmit();
      emit OnSetAnnualInterestAndReserveRatioBipsCalled(
        annualInterestBips,
        reserveRatioBips,
        state,
        extraData
      );
    }
    _callMockHookCaller(_calldata);
    if (config.useOnSetAnnualInterestAndReserveRatioBips()) {
      uint16 returnedAnnualInterestBips;
      uint16 returnedReserveRatioBips;
      assembly {
        returndatacopy(0, 0, 0x40)
        returnedAnnualInterestBips := mload(0)
        returnedReserveRatioBips := mload(0x20)
      }
      assertEq(returnedAnnualInterestBips, annualInterestBipsToReturn, 'updatedAnnualInterestBips');
      assertEq(returnedReserveRatioBips, reserveRatioBipsToReturn, 'updatedReserveRatioBips');
    } else {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }

  function test_onSetProtocolFeeBips(
    MarketStateFuzzInputs memory stateInput,
    StandardHooksConfig memory configInput,
    bytes memory extraData
  ) external {
    MarketState memory state = stateInput.toState();
    mockHookCaller.setState(state);
    configInput.hooksAddress = address(hooks);
    HooksConfig config = configInput.toHooksConfig();
    mockHookCaller.setConfig(config);
    bytes memory _calldata = abi.encodePacked(
      abi.encodeWithSelector(mockHookCaller.setProtocolFeeBips.selector, 100),
      extraData
    );
    if (config.useOnSetProtocolFeeBips()) {
      vm.expectEmit();
      emit OnSetProtocolFeeBipsCalled(100, state, extraData);
    }
    _callMockHookCaller(_calldata);
    if (!config.useOnSetProtocolFeeBips()) {
      assertEq(hooks.lastCalldataHash(), 0);
    }
  }
}
