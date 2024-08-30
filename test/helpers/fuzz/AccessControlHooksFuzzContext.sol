// SPDX-License-Identifier; MIT
pragma solidity >=0.8.20;

import 'src/libraries/BoolUtils.sol';
import 'src/access/AccessControlHooks.sol';

import 'sol-utils/ir-only/MemoryPointer.sol';
import { ArrayHelpers } from 'sol-utils/ir-only/ArrayHelpers.sol';
import { Vm, VmSafe } from 'forge-std/Vm.sol';

import '../../shared/mocks/MockRoleProvider.sol';
import { warp, safeStartPrank, safeStopPrank } from '../../helpers/VmUtils.sol';

using BoolUtils for bool;

using LibAccessControlHooksFuzzContext for AccessControlHooksFuzzContext global;

/*

bytes memory hooksData;
if (
  credential.credentialExists &&
  !credential.expired &&
  credential.providerApproved
) {
  // Returns true, no update, no calls made
}
// Hooks stage
if (hooksData.giveHooksData) {
  if (hooksData.giveDataToValidate) {
    hooksData = hex"aabbccddeeff";
    provider.approveCredentialData()
  }
}

    Scenarios to test:
    1. User has existing credential
      - Pass conditions:
        - !expired & providerApproved
        - expired & providerApproved & isPullProvider & willRefresh
      - Fail conditions:
        - !expired + !providerApproved  
        - expired + providerApproved + !isPullProvider
        - expired + providerApproved + isPullProvider + !willRefresh
    2. User has expired credential
      - Provider does not exist
      - Provider exists but is not a pull provider
      - Provider is a pull provider and will refresh credential
      - Provider is a pull provider and will not refresh credential
    3. User has no credential:
      - No pull providers will grant credential
      - There is a pull provider that will grant a credential
  */

enum FunctionKind {
  HooksFunction,
  DepositFunction,
  QueueWithdrawal,
  IncomingTransferFunction
}

struct AccessControlHooksFuzzContext {
  FunctionKind functionKind;
  bool willCheckCredentials;
  address market;
  AccessControlHooks hooks;
  address borrower;
  address account;
  bytes hooksData;
  MarketHooksConfigContext config;
  ExistingCredentialFuzzInputs existingCredentialOptions;
  AccessControlHooksDataFuzzInputs dataOptions;
  MarketHooksConfigFuzzInputs configOptions;
  AccessControlValidationExpectations expectations;
  MockRoleProvider previousProvider;
  MockRoleProvider providerToGiveData;
  // Function for the test invoking this library to handle acquiring the `isKnownLender` status
  // and updating its state expectations
  function(AccessControlHooksFuzzContext memory /* context */) internal getKnownLenderStatus;
  // Arbitrary parameter for the invoking test to use, most likely a pointer to some struct
  uint256 getKnownLenderInputParameter;
}

struct AccessControlValidationExpectations {
  // Whether the account will end up with a valid credential
  bool hasValidCredential;
  // Whether the account's credential will be updated (added, refreshed or revoked)
  bool wasUpdated;
  // Expected calls to occur between the hooks instance and role providers
  ExpectedCall[] expectedCalls;
  // Error the hooks instance should throw
  bytes4 expectedError;
  // The `lastProvider` of the account after the call
  address lastProvider;
  // The `lastApprovalTimestamp` of the account after the call
  uint32 lastApprovalTimestamp;
}

struct AccessControlHooksFuzzInputs {
  ExistingCredentialFuzzInputs existingCredentialInputs;
  AccessControlHooksDataFuzzInputs dataInputs;
  MarketHooksConfigFuzzInputs configInputs;
}

struct MarketHooksConfigContext {
  bool useOnDeposit;
  bool useOnQueueWithdrawal;
  bool useOnExecuteWithdrawal;
  bool useOnTransfer;
  bool transferRequiresAccess;
  bool depositRequiresAccess;
}

struct MarketHooksConfigFuzzInputs {
  bool useOnDeposit;
  bool useOnQueueWithdrawal;
  bool useOnExecuteWithdrawal;
  bool useOnTransfer;
}

struct ExistingCredentialFuzzInputs {
  // Whether the user has an existing credential
  bool credentialExists;
  // Whether the provider that granted the credential is still approved
  bool providerApproved;
  // Whether the credential is expired
  bool expired;
  // Whether the provider is a pull provider
  bool isPullProvider;
  // Whether provider will return valid encoded timestamp
  bool willReturnUint;
  // Provider will grant credential, but credential is expired
  bool newCredentialExpired;
  // Provider will revert on getCredential
  bool callWillRevert;
  // Account is blocked from deposits
  bool isBlockedFromDeposits;
  // Account is a known lender
  bool isKnownLender;
}

// @todo handle cases where timestamp > block.timestamp
struct AccessControlHooksDataFuzzInputs {
  // Whether to give any hooks data
  bool giveHooksData;
  // Give data for validation rather than just the provider address
  bool giveDataToValidate;
  // Provider exists
  bool providerApproved;
  // Provider is a pull provider
  bool isPullProvider;
  // Whether provider will return valid encoded timestamp
  bool willReturnUint;
  // Provider will grant credential, but credential is expired
  bool credentialExpired;
  // Provider will revert on validateCredential / getCredential
  bool callWillRevert;
}

struct ExpectedCall {
  address target;
  bytes data;
}

address constant VM_ADDRESS = address(uint160(uint256(keccak256('hevm cheat code'))));
Vm constant vm = Vm(VM_ADDRESS);

function toMarketHooksConfigContext(
  MarketHooksConfigFuzzInputs memory inputs
) pure returns (MarketHooksConfigContext memory) {
  return
    MarketHooksConfigContext({
      useOnDeposit: inputs.useOnDeposit || inputs.useOnQueueWithdrawal,
      useOnQueueWithdrawal: inputs.useOnQueueWithdrawal,
      useOnExecuteWithdrawal: inputs.useOnExecuteWithdrawal,
      useOnTransfer: inputs.useOnTransfer || inputs.useOnQueueWithdrawal,
      transferRequiresAccess: inputs.useOnTransfer,
      depositRequiresAccess: inputs.useOnDeposit
    });
}

using { toMarketHooksConfigContext } for MarketHooksConfigFuzzInputs global;

function createAccessControlHooksFuzzContext(
  AccessControlHooksFuzzInputs memory fuzzInputs,
  address market,
  AccessControlHooks hooks,
  MockRoleProvider mockProvider1,
  MockRoleProvider mockProvider2,
  address account,
  FunctionKind functionKind,
  function(AccessControlHooksFuzzContext memory /* context */) internal getKnownLenderStatus,
  uint256 getKnownLenderInputParameter
) returns (AccessControlHooksFuzzContext memory context) {
  LenderStatus memory originalStatus = hooks.getLenderStatus(account);
  context.market = market;
  context.functionKind = functionKind;
  context.hooks = hooks;
  context.borrower = hooks.borrower();
  context.account = account;
  context.existingCredentialOptions = fuzzInputs.existingCredentialInputs;
  context.dataOptions = fuzzInputs.dataInputs;
  context.configOptions = fuzzInputs.configInputs;
  context.getKnownLenderStatus = getKnownLenderStatus;
  context.getKnownLenderInputParameter = getKnownLenderInputParameter;

  context.existingCredentialOptions.isKnownLender = context
    .existingCredentialOptions
    .isKnownLender
    .and(
      fuzzInputs.configInputs.useOnDeposit ||
        fuzzInputs.configInputs.useOnTransfer ||
        fuzzInputs.configInputs.useOnQueueWithdrawal
    )
    .or(hooks.isKnownLenderOnMarket(account, market));

  context.previousProvider = mockProvider1;
  context.providerToGiveData = mockProvider2;

  context.config = fuzzInputs.configInputs.toMarketHooksConfigContext();

  vm.label(address(mockProvider1), 'previousProvider');
  vm.label(address(mockProvider2), 'providerToGiveData');

  context.setUpExistingCredential();
  context.setUpBypassExpectations();
  context.setUpHooksData();
  context.setUpCredentialRefresh();
  context.setUpAccessDeniedErrorExpectation();

  // If a previous credential exists but the lender will not end up with a valid credential,
  // the last provider and approval timestamp should be reset if the call is not to a function
  // that reverts on failure.
  if (
    fuzzInputs.existingCredentialInputs.credentialExists &&
    !context.expectations.hasValidCredential &&
    context.expectations.expectedError == 0
  ) {
    context.expectations.wasUpdated = true;
    context.expectations.lastProvider = address(0);
    context.expectations.lastApprovalTimestamp = 0;
  }
}

library LibAccessControlHooksFuzzContext {
  using AccessControlTestTypeCasts for *;

  /**
   * @dev Register event, error and call expectations with the forge vm
   */
  function registerExpectations(
    AccessControlHooksFuzzContext memory context,
    bool skipRevokedEvent
  ) internal {
    for (uint i; i < context.expectations.expectedCalls.length; i++) {
      vm.expectCall(
        context.expectations.expectedCalls[i].target,
        context.expectations.expectedCalls[i].data
      );
    }
    if (context.expectations.wasUpdated) {
      if (context.expectations.hasValidCredential) {
        vm.expectEmit(address(context.hooks));
        emit AccessControlHooks.AccountAccessGranted(
          context.expectations.lastProvider,
          context.account,
          context.expectations.lastApprovalTimestamp
        );
      } else if (!skipRevokedEvent) {
        vm.expectEmit(address(context.hooks));
        emit AccessControlHooks.AccountAccessRevoked(context.account);
      }
    }
    if (
      !context.existingCredentialOptions.isKnownLender &&
      context.expectations.hasValidCredential &&
      context.willCheckCredentials
    ) {
      if (
        context.functionKind == FunctionKind.IncomingTransferFunction ||
        context.functionKind == FunctionKind.DepositFunction
      ) {
        vm.expectEmit(address(context.hooks));
        emit AccessControlHooks.AccountMadeFirstDeposit(context.account);
      }
    }
    if (context.expectations.expectedError != 0) {
      vm.expectRevert(context.expectations.expectedError);
    }
  }

  /**
   * @dev Validate state after execution
   */
  function validate(AccessControlHooksFuzzContext memory context) internal view {
    LenderStatus memory priorStatus = context.hooks.getPreviousLenderStatus(context.account);
    LenderStatus memory currentStatus = context.hooks.getLenderStatus(context.account);

    // If the account does not have a valid credential but that will not be reflected because the encapsulating
    // call failed, the new status should not match the previous one.
    if (
      !context.expectations.wasUpdated &&
      context.expectations.expectedError == 0 &&
      context.existingCredentialOptions.credentialExists &&
      !context.expectations.hasValidCredential
    ) {
      vm.assertEq(priorStatus.lastProvider, address(context.previousProvider), 'previous provider');
      vm.assertEq(currentStatus.lastProvider, address(0), 'current provider != 0');
      vm.assertEq(currentStatus.lastApprovalTimestamp, 0, 'current timestamp != 0');
    }

    // Should be known lender if they were already or if the call
    // succeeded and was a deposit or incoming transfer, and the hook was enabled
    vm.assertEq(
      context.hooks.isKnownLenderOnMarket(context.account, context.market),
      context.existingCredentialOptions.isKnownLender ||
        (context.willCheckCredentials &&
          context.expectations.expectedError == 0 &&
          (context.functionKind == FunctionKind.DepositFunction ||
            context.functionKind == FunctionKind.IncomingTransferFunction)),
      'priorStatus.isKnownLender'
    );

    // If the call was to the hooks contract directly, or to the market with a valid credential, the current
    // status should match the previous one.
    if (
      context.expectations.expectedError == 0 &&
      context.expectations.wasUpdated &&
      (context.functionKind != FunctionKind.HooksFunction ||
        context.expectations.hasValidCredential)
    ) {
      vm.assertEq(
        priorStatus.isBlockedFromDeposits,
        currentStatus.isBlockedFromDeposits,
        'status.isBlockedFromDeposits'
      );
      vm.assertEq(priorStatus.lastProvider, currentStatus.lastProvider, 'status.lastProvider');
      vm.assertEq(priorStatus.canRefresh, currentStatus.canRefresh, 'status.canRefresh');
      vm.assertEq(
        priorStatus.lastApprovalTimestamp,
        currentStatus.lastApprovalTimestamp,
        'status.lastApprovalTimestamp'
      );
      vm.assertEq(priorStatus.lastProvider, context.expectations.lastProvider, 'lastProvider');
      vm.assertEq(
        priorStatus.lastApprovalTimestamp,
        context.expectations.lastApprovalTimestamp,
        'lastApprovalTimestamp'
      );
    }

    /*  */
  }

  function setUpExistingCredential(AccessControlHooksFuzzContext memory context) internal {
    MockRoleProvider provider = context.previousProvider;
    ExistingCredentialFuzzInputs memory existingCredentialOptions = context
      .existingCredentialOptions;

    if (
      existingCredentialOptions.isKnownLender &&
      !context.hooks.isKnownLenderOnMarket(context.account, context.market)
    ) {
      // To get known lender status:
      // 1. set a temporary role using a temporarily whitelisted role provider
      //    - only necessary if market requires access for deposits / incoming transfers
      // 2. call the provided function for `getKnownLenderStatus`
      //    - this is defined by the specific test using the fuzz context as it will need to
      //      handle cleaning up its own expectations for the state of the market
      // 3. clean up hooks state for other expectations (revoke role & remove provider)
      //    - only necessary if market requires access for deposits / incoming transfers
      bool getTmpAccess = context.config.useOnDeposit || context.config.useOnTransfer;

      if (getTmpAccess) {
        provider.setIsPullProvider(false);
        safeStartPrank(context.borrower);
        context.hooks.addRoleProvider(address(provider), 1);
        safeStopPrank();

        safeStartPrank(address(provider));
        context.hooks.grantRole(context.account, uint32(block.timestamp));
        safeStopPrank();
      }

      context.getKnownLenderStatus(context);
      if (getTmpAccess) {
        safeStartPrank(address(provider));
        context.hooks.revokeRole(context.account);
        safeStopPrank();
        safeStartPrank(context.borrower);
        context.hooks.removeRoleProvider(address(provider));
        safeStopPrank();
      }
    }

    if (existingCredentialOptions.isBlockedFromDeposits) {
      vm.prank(context.borrower);
      context.hooks.blockFromDeposits(context.account);
    }

    if (existingCredentialOptions.credentialExists) {
      uint32 originalTimestamp = uint32(block.timestamp);
      // If the credential should exist, add the provider and grant the role
      uint32 credentialTimestamp = existingCredentialOptions.expired
        ? originalTimestamp - 2
        : originalTimestamp;

      if (existingCredentialOptions.isPullProvider) {
        provider.setIsPullProvider(true);
      }
      if (existingCredentialOptions.expired) {
        warp(credentialTimestamp);
      }

      vm.prank(context.borrower);
      // If the credential should exist, add the provider and grant the role
      context.hooks.addRoleProvider(address(provider), 1);
      vm.prank(address(provider));
      context.hooks.grantRole(context.account, credentialTimestamp);

      if (existingCredentialOptions.expired) {
        warp(originalTimestamp);
      }

      // If the provider should no longer be approved, remove it
      if (!existingCredentialOptions.providerApproved) {
        vm.prank(context.borrower);
        context.hooks.removeRoleProvider(address(provider));
      }

      // If the credential should be valid still, expect the account to have a valid credential
      // from the provider with no changes
      if (!existingCredentialOptions.expired && existingCredentialOptions.providerApproved) {
        context.expectations.hasValidCredential = true;
        context.expectations.wasUpdated = false;
        context.expectations.lastProvider = address(provider);
        context.expectations.lastApprovalTimestamp = credentialTimestamp;
      }
    }
  }

  function setUpBypassExpectations(AccessControlHooksFuzzContext memory context) internal pure {
    context.willCheckCredentials = true;
    if (context.functionKind == FunctionKind.IncomingTransferFunction) {
      if (!context.config.useOnTransfer) {
        // If hook is disabled, credentials will not be called
        context.willCheckCredentials = false;
      } else if (context.existingCredentialOptions.isKnownLender) {
        // If a transfer recipient is a known lender, their credentials will not be checked
        context.willCheckCredentials = false;
      } else if (context.existingCredentialOptions.isBlockedFromDeposits) {
        // If a transfer recipient is not a known lender and is blocked from depositing, the call will
        // revert before checking credentials
        context.expectations.expectedError = AccessControlHooks.NotApprovedLender.selector;
        context.willCheckCredentials = false;
      }
    } else if (context.functionKind == FunctionKind.DepositFunction) {
      if (!context.config.useOnDeposit) {
        context.willCheckCredentials = false;
      } else if (context.existingCredentialOptions.isBlockedFromDeposits) {
        // If a depositor is blocked from depositing, the call will revert before checking credentials
        context.expectations.expectedError = AccessControlHooks.NotApprovedLender.selector;
        context.willCheckCredentials = false;
      }
    } else if (context.functionKind == FunctionKind.QueueWithdrawal) {
      if (!context.config.useOnQueueWithdrawal) {
        context.willCheckCredentials = false;
      } else {
        // If the function is a withdrawal and the account is a known lender, the credential
        // check will be bypassed.
        context.willCheckCredentials = !context.existingCredentialOptions.isKnownLender;
      }
    }
  }

  function setUpAccessDeniedErrorExpectation(
    AccessControlHooksFuzzContext memory context
  ) internal pure {
    if (
      !context.willCheckCredentials ||
      context.expectations.expectedError != 0 ||
      context.expectations.hasValidCredential
    ) return;
    if (
      (context.functionKind == FunctionKind.QueueWithdrawal &&
        context.config.useOnQueueWithdrawal) ||
      (context.functionKind == FunctionKind.DepositFunction &&
        context.config.depositRequiresAccess) ||
      (context.functionKind == FunctionKind.IncomingTransferFunction &&
        context.config.transferRequiresAccess)
    ) {
      context.expectations.expectedError = AccessControlHooks.NotApprovedLender.selector;
    }
  }

  function setUpHooksData(AccessControlHooksFuzzContext memory context) internal {
    MockRoleProvider provider = context.providerToGiveData;
    AccessControlHooksDataFuzzInputs memory dataOptions = context.dataOptions;

    // The contract will call the provider if all of the following are true:
    // - The account does not already have a valid credential
    // - The call will not revert before checking credentials
    // - The credential check won't be bypassed
    // - Hooks data is given
    // - The provider is approved
    // - The provider is a pull provider or `validateCredential` is being called
    bool providerWillBeCalled = (!context.expectations.hasValidCredential)
      .and(context.expectations.expectedError == 0)
      .and(context.willCheckCredentials)
      .and(dataOptions.giveHooksData)
      .and(dataOptions.providerApproved)
      .and(dataOptions.isPullProvider || dataOptions.giveDataToValidate);

    // Regardless of whether the provider will be called, set up the provider for
    // the given fuzz inputs
    if (dataOptions.giveHooksData) {
      uint32 credentialTimestamp = dataOptions.credentialExpired
        ? uint32(block.timestamp - 2)
        : uint32(block.timestamp);

      provider.setIsPullProvider(dataOptions.isPullProvider);
      // If provider should be approved, add it to the list of role providers
      if (dataOptions.providerApproved) {
        vm.prank(context.borrower);
        context.hooks.addRoleProvider(address(provider), 1);
      }

      // If `willReturnUint` is false, make the provider return 0 bytes
      provider.setCallShouldReturnCorruptedData(!dataOptions.willReturnUint);
      // If `callWillRevert` is true, make the provider revert
      provider.setCallShouldRevert(dataOptions.callWillRevert);

      if (dataOptions.giveDataToValidate) {
        bytes memory validateData = hex'aabbccddeeff';
        if (dataOptions.willReturnUint) {
          provider.approveCredentialData(keccak256(validateData), credentialTimestamp);
        }
        context.hooksData = abi.encodePacked(provider, validateData);
      } else {
        context.hooksData = abi.encodePacked(provider);
        if (dataOptions.willReturnUint) {
          provider.setCredential(context.account, credentialTimestamp);
        }
      }

      // The call will return a valid credential if all of the following are true:
      // - The provider will return a valid uint
      // - The credential is not expired
      // - The call will not revert
      bool hooksWillYieldCredential = providerWillBeCalled
        .and(dataOptions.willReturnUint)
        .and(!dataOptions.credentialExpired)
        .and(!dataOptions.callWillRevert);

      if (hooksWillYieldCredential) {
        context.expectations.hasValidCredential = true;
        context.expectations.wasUpdated = true;
        context.expectations.lastProvider = address(provider);
        context.expectations.lastApprovalTimestamp = credentialTimestamp;
      }
    }

    // If the provider will be called, set up the expectations for the call to be made
    // and whether the call will revert
    if (providerWillBeCalled) {
      bytes memory expectedCalldata = dataOptions.giveDataToValidate
        ? abi.encodeWithSelector(
          IRoleProvider.validateCredential.selector,
          context.account,
          hex'aabbccddeeff'
        )
        : abi.encodeWithSelector(IRoleProvider.getCredential.selector, context.account);

      ArrayHelpers.cloneAndPush.asPushExpectedCall()(
        context.expectations.expectedCalls,
        ExpectedCall(address(provider), expectedCalldata)
      );
      if (
        (!dataOptions.callWillRevert).and(!dataOptions.willReturnUint).and(
          dataOptions.giveDataToValidate
        )
      ) {
        context.expectations.expectedError = AccessControlHooks.InvalidCredentialReturned.selector;
      }
    }
  }

  // Runs after _setUpExistingCredential and _setUpHooksData
  function setUpCredentialRefresh(AccessControlHooksFuzzContext memory context) internal {
    if (context.expectations.expectedError != bytes4(0)) {
      return;
    }
    MockRoleProvider provider = context.previousProvider;
    ExistingCredentialFuzzInputs memory existingCredentialOptions = context
      .existingCredentialOptions;

    // The contract will call the provider if all of the following are true:
    // - The account has an expired credential
    // - The credential check won't be bypassed
    // - The provider is a pull provider
    // - The provider is approved
    // - The hooks data step will not return a valid credential
    bool contractWillBeCalled = existingCredentialOptions
      .credentialExists
      .and(context.willCheckCredentials)
      .and(existingCredentialOptions.expired)
      .and(existingCredentialOptions.isPullProvider)
      .and(existingCredentialOptions.providerApproved)
      .and(!context.expectations.hasValidCredential);

    if (contractWillBeCalled) {
      uint32 credentialTimestamp = existingCredentialOptions.newCredentialExpired
        ? uint32(block.timestamp - 2)
        : uint32(block.timestamp);

      // If `willReturnUint` is false, make the provider return 0 bytes
      if (!existingCredentialOptions.willReturnUint) {
        provider.setCallShouldReturnCorruptedData(true);
      }
      if (existingCredentialOptions.callWillRevert) {
        provider.setCallShouldRevert(true);
      }
      provider.setCredential(context.account, credentialTimestamp);

      ArrayHelpers.cloneAndPush.asPushExpectedCall()(
        context.expectations.expectedCalls,
        ExpectedCall(
          address(provider),
          abi.encodeWithSelector(IRoleProvider.getCredential.selector, context.account)
        )
      );

      // The call will return a valid credential if all of the following are true:
      // - The provider will return a valid uint
      // - The credential is not expired
      // - The call will not revert
      bool hooksWillYieldCredential = contractWillBeCalled
        .and(existingCredentialOptions.willReturnUint)
        .and(!existingCredentialOptions.newCredentialExpired)
        .and(!existingCredentialOptions.callWillRevert);

      if (hooksWillYieldCredential) {
        context.expectations.hasValidCredential = true;
        context.expectations.wasUpdated = true;
        context.expectations.lastProvider = address(provider);
        context.expectations.lastApprovalTimestamp = credentialTimestamp;
      }
    }
  }
}

library AccessControlTestTypeCasts {
  function asPushExpectedCall(
    function(MemoryPointer, uint256) internal pure returns (MemoryPointer) _fn
  )
    internal
    pure
    returns (
      function(ExpectedCall[] memory, ExpectedCall memory)
        internal
        pure
        returns (ExpectedCall[] memory) fn
    )
  {
    assembly {
      fn := _fn
    }
  }
}
