pragma solidity ^0.8.20;

import 'src/libraries/MarketState.sol';
import { StdAssertions } from 'forge-std/StdAssertions.sol';
import 'forge-std/console2.sol';
import { LibString } from 'solady/utils/LibString.sol';
import 'src/types/HooksConfig.sol';
import 'src/types/LenderStatus.sol';
import './StandardStructs.sol';
import 'src/IHooksFactory.sol';

using LibString for uint256;

contract Assertions is StdAssertions {
  function assertEq(
    MarketState memory actual,
    MarketState memory expected,
    string memory key
  ) internal {
    assertEq(actual.maxTotalSupply, expected.maxTotalSupply, string.concat(key, '.maxTotalSupply'));
    assertEq(
      actual.accruedProtocolFees,
      expected.accruedProtocolFees,
      string.concat(key, '.accruedProtocolFees')
    );
    assertEq(
      actual.normalizedUnclaimedWithdrawals,
      expected.normalizedUnclaimedWithdrawals,
      string.concat(key, '.normalizedUnclaimedWithdrawals')
    );
    assertEq(
      actual.scaledTotalSupply,
      expected.scaledTotalSupply,
      string.concat(key, '.scaledTotalSupply')
    );
    assertEq(
      actual.scaledPendingWithdrawals,
      expected.scaledPendingWithdrawals,
      string.concat(key, '.scaledPendingWithdrawals')
    );
    assertEq(
      actual.pendingWithdrawalExpiry,
      expected.pendingWithdrawalExpiry,
      string.concat(key, '.pendingWithdrawalExpiry')
    );
    assertEq(actual.isDelinquent, expected.isDelinquent, string.concat(key, '.isDelinquent'));
    assertEq(actual.timeDelinquent, expected.timeDelinquent, string.concat(key, '.timeDelinquent'));
    assertEq(
      actual.annualInterestBips,
      expected.annualInterestBips,
      string.concat(key, '.annualInterestBips')
    );
    assertEq(
      actual.reserveRatioBips,
      expected.reserveRatioBips,
      string.concat(key, '.reserveRatioBips')
    );
    assertEq(actual.scaleFactor, expected.scaleFactor, string.concat(key, '.scaleFactor'));
    assertEq(
      actual.lastInterestAccruedTimestamp,
      expected.lastInterestAccruedTimestamp,
      string.concat(key, '.lastInterestAccruedTimestamp')
    );
    assertEq(
      actual.protocolFeeBips,
      expected.protocolFeeBips,
      string.concat(key, '.protocolFeeBips')
    );
  }

  function assertEq(MarketState memory actual, MarketState memory expected) internal {
    assertEq(actual, expected, 'MarketState');
  }

  function assertEq(uint32[] memory actual, uint32[] memory expected, string memory key) internal {
    assertEq(actual.length, expected.length, string.concat(key, '.length'));
    for (uint256 i = 0; i < actual.length; i++) {
      assertEq(actual[i], expected[i], string.concat(key, '[', i.toString(), ']'));
    }
  }

  function assertEq(uint32[] memory actual, uint32[] memory expected) internal {
    assertEq(actual, expected, 'uint32[]');
  }

  function assertEq(
    RoleProvider actual,
    StandardRoleProvider memory expected,
    string memory labelPrefix
  ) internal {
    assertEq(
      actual.providerAddress(),
      expected.providerAddress,
      string.concat(labelPrefix, 'providerAddress')
    );
    assertEq(actual.timeToLive(), expected.timeToLive, string.concat(labelPrefix, 'timeToLive'));
    assertEq(
      actual.pullProviderIndex(),
      expected.pullProviderIndex,
      string.concat(labelPrefix, 'pullProviderIndex')
    );
  }

  function assertEq(RoleProvider actual, StandardRoleProvider memory expected) internal {
    assertEq(actual, expected, 'RoleProvider.');
  }

  function assertEq(
    HooksDeploymentConfig actual,
    HooksDeploymentConfig expected,
    string memory labelPrefix
  ) internal {
    assertEq(
      actual.optionalFlags(),
      expected.optionalFlags(),
      string.concat(labelPrefix, 'optionalFlags')
    );
    assertEq(
      actual.requiredFlags(),
      expected.requiredFlags(),
      string.concat(labelPrefix, 'requiredFlags')
    );
  }

  function assertEq(HooksDeploymentConfig actual, HooksDeploymentConfig expected) internal {
    assertEq(actual, expected, 'HooksDeploymentConfig.');
  }

  function assertEq(
    HooksDeploymentConfig actual,
    StandardHooksDeploymentConfig memory expected,
    string memory labelPrefix
  ) internal {
    assertEq(
      actual.optionalFlags(),
      expected.optional,
      string.concat(labelPrefix, 'optionalFlags')
    );
    assertEq(
      actual.requiredFlags(),
      expected.required,
      string.concat(labelPrefix, 'requiredFlags')
    );
  }

  function assertEq(
    HooksDeploymentConfig actual,
    StandardHooksDeploymentConfig memory expected
  ) internal {
    assertEq(actual, expected, 'HooksDeploymentConfig.');
  }

  function assertEq(HooksConfig actual, HooksConfig expected, string memory labelPrefix) internal {
    assertEq(
      actual.hooksAddress(),
      expected.hooksAddress(),
      string.concat(labelPrefix, 'hooksAddress')
    );
    assertEq(
      actual.useOnDeposit(),
      expected.useOnDeposit(),
      string.concat(labelPrefix, 'useOnDeposit')
    );
    assertEq(
      actual.useOnQueueWithdrawal(),
      expected.useOnQueueWithdrawal(),
      string.concat(labelPrefix, 'useOnQueueWithdrawal')
    );
    assertEq(
      actual.useOnExecuteWithdrawal(),
      expected.useOnExecuteWithdrawal(),
      string.concat(labelPrefix, 'useOnExecuteWithdrawal')
    );
    assertEq(
      actual.useOnTransfer(),
      expected.useOnTransfer(),
      string.concat(labelPrefix, 'useOnTransfer')
    );
    assertEq(
      actual.useOnBorrow(),
      expected.useOnBorrow(),
      string.concat(labelPrefix, 'useOnBorrow')
    );
    assertEq(actual.useOnRepay(), expected.useOnRepay(), string.concat(labelPrefix, 'useOnRepay'));
    assertEq(
      actual.useOnCloseMarket(),
      expected.useOnCloseMarket(),
      string.concat(labelPrefix, 'useOnCloseMarket')
    );
    assertEq(
      actual.useOnNukeFromOrbit(),
      expected.useOnNukeFromOrbit(),
      string.concat(labelPrefix, 'useOnNukeFromOrbit')
    );
    assertEq(
      actual.useOnSetMaxTotalSupply(),
      expected.useOnSetMaxTotalSupply(),
      string.concat(labelPrefix, 'useOnSetMaxTotalSupply')
    );
    assertEq(
      actual.useOnSetAnnualInterestAndReserveRatioBips(),
      expected.useOnSetAnnualInterestAndReserveRatioBips(),
      string.concat(labelPrefix, 'useOnSetAnnualInterestAndReserveRatioBips')
    );
    assertEq(
      actual.useOnSetProtocolFeeBips(),
      expected.useOnSetProtocolFeeBips(),
      string.concat(labelPrefix, 'useOnSetProtocolFeeBips')
    );
  }

  function assertEq(HooksConfig actual, HooksConfig expected) internal {
    assertEq(actual, expected, 'HooksConfig.');
  }

  function assertEq(
    HooksConfig actual,
    StandardHooksConfig memory expected,
    string memory labelPrefix
  ) internal {
    assertEq(
      actual.hooksAddress(),
      expected.hooksAddress,
      string.concat(labelPrefix, 'hooksAddress')
    );
    assertEq(
      actual.useOnDeposit(),
      expected.useOnDeposit,
      string.concat(labelPrefix, 'useOnDeposit')
    );
    assertEq(
      actual.useOnQueueWithdrawal(),
      expected.useOnQueueWithdrawal,
      string.concat(labelPrefix, 'useOnQueueWithdrawal')
    );
    assertEq(
      actual.useOnExecuteWithdrawal(),
      expected.useOnExecuteWithdrawal,
      string.concat(labelPrefix, 'useOnExecuteWithdrawal')
    );
    assertEq(
      actual.useOnTransfer(),
      expected.useOnTransfer,
      string.concat(labelPrefix, 'useOnTransfer')
    );
    assertEq(actual.useOnBorrow(), expected.useOnBorrow, string.concat(labelPrefix, 'useOnBorrow'));
    assertEq(actual.useOnRepay(), expected.useOnRepay, string.concat(labelPrefix, 'useOnRepay'));
    assertEq(
      actual.useOnCloseMarket(),
      expected.useOnCloseMarket,
      string.concat(labelPrefix, 'useOnCloseMarket')
    );
    assertEq(
      actual.useOnNukeFromOrbit(),
      expected.useOnNukeFromOrbit,
      string.concat(labelPrefix, 'useOnNukeFromOrbit')
    );
    assertEq(
      actual.useOnSetMaxTotalSupply(),
      expected.useOnSetMaxTotalSupply,
      string.concat(labelPrefix, 'useOnSetMaxTotalSupply')
    );
    assertEq(
      actual.useOnSetAnnualInterestAndReserveRatioBips(),
      expected.useOnSetAnnualInterestAndReserveRatioBips,
      string.concat(labelPrefix, 'useOnSetAnnualInterestAndReserveRatioBips')
    );
    assertEq(
      actual.useOnSetProtocolFeeBips(),
      expected.useOnSetProtocolFeeBips,
      string.concat(labelPrefix, 'useOnSetProtocolFeeBips')
    );
  }

  function assertEq(HooksConfig actual, StandardHooksConfig memory expected) internal {
    assertEq(actual, expected, 'HooksConfig.');
  }

  function assertEq(
    LenderStatus memory actual,
    LenderStatus memory expected,
    string memory key
  ) internal {
    assertEq(
      actual.isBlockedFromDeposits,
      expected.isBlockedFromDeposits,
      string.concat(key, '.isBlockedFromDeposits')
    );
    assertEq(actual.lastProvider, expected.lastProvider, string.concat(key, '.lastProvider'));
    assertEq(actual.canRefresh, expected.canRefresh, string.concat(key, '.canRefresh'));
    assertEq(
      actual.lastApprovalTimestamp,
      expected.lastApprovalTimestamp,
      string.concat(key, '.lastApprovalTimestamp')
    );
  }

  function assertEq(LenderStatus memory actual, LenderStatus memory expected) internal {
    assertEq(actual, expected, 'LenderStatus');
  }

  function assertEq(
    HooksTemplate memory actual,
    HooksTemplate memory expected,
    string memory key
  ) internal {
    assertEq(actual.name, expected.name, string.concat(key, '.name'));
    assertEq(actual.feeRecipient, expected.feeRecipient, string.concat(key, '.feeRecipient'));
    assertEq(
      actual.originationFeeAsset,
      expected.originationFeeAsset,
      string.concat(key, '.originationFeeAsset')
    );
    assertEq(
      actual.originationFeeAmount,
      expected.originationFeeAmount,
      string.concat(key, '.originationFeeAmount')
    );
    assertEq(
      actual.protocolFeeBips,
      expected.protocolFeeBips,
      string.concat(key, '.protocolFeeBips')
    );
  }

  function assertEq(HooksTemplate memory actual, HooksTemplate memory expected) internal {
    assertEq(actual, expected, 'HooksTemplate');
  }

  function assertEq(
    DeployMarketInputs memory actual,
    DeployMarketInputs memory expected,
    string memory key
  ) internal {
    assertEq(actual.asset, expected.asset, string.concat(key, '.asset'));
    assertEq(actual.namePrefix, expected.namePrefix, string.concat(key, '.namePrefix'));
    assertEq(actual.symbolPrefix, expected.symbolPrefix, string.concat(key, '.symbolPrefix'));
    assertEq(actual.maxTotalSupply, expected.maxTotalSupply, string.concat(key, '.maxTotalSupply'));
    assertEq(
      actual.annualInterestBips,
      expected.annualInterestBips,
      string.concat(key, '.annualInterestBips')
    );
    assertEq(
      actual.delinquencyFeeBips,
      expected.delinquencyFeeBips,
      string.concat(key, '.delinquencyFeeBips')
    );
    assertEq(
      actual.withdrawalBatchDuration,
      expected.withdrawalBatchDuration,
      string.concat(key, '.withdrawalBatchDuration')
    );
    assertEq(
      actual.reserveRatioBips,
      expected.reserveRatioBips,
      string.concat(key, '.reserveRatioBips')
    );
    assertEq(
      actual.delinquencyGracePeriod,
      expected.delinquencyGracePeriod,
      string.concat(key, '.delinquencyGracePeriod')
    );
    assertEq(actual.hooks, expected.hooks, string.concat(key, '.hooks'));
  }

  function assertEq(DeployMarketInputs memory actual, DeployMarketInputs memory expected) internal {
    assertEq(actual, expected, 'DeployMarketInput');
  }

  function assertBytesEq(
    bytes memory actual,
    bytes memory expected,
    string memory label,
    bool hasSelector
  ) internal {
    if (keccak256(actual) != keccak256(expected)) {
      if (bytes(label).length != 0) {
        label = string.concat(' (', label, ')');
      }
      string memory errorMessage = string.concat('Error: actual != expected', label);
      emit log(errorMessage);
      console2.log('Error: actual != expected', label);
      printWordsInBytes(actual, '  actual', hasSelector);
      printWordsInBytes(expected, '  expected', hasSelector);
      revert(errorMessage);
    }
  }

  function assertBytesEq(bytes memory actual, bytes memory expected, string memory label) internal {
    assertBytesEq(actual, expected, label, false);
  }

  function printWordsInBytes(
    bytes memory data,
    string memory linePrefix,
    bool hasSelector
  ) internal pure {
    uint i;
    if (hasSelector) {
      i = 4;
      uint selector;
      assembly {
        selector := shr(224, mload(add(data, 0x20)))
      }
      console2.log(string.concat(linePrefix, '[0:4]:'), selector.toHexString());
    }
    for (; i < data.length; i += 32) {
      uint word;
      assembly {
        word := mload(add(data, add(i, 0x20)))
      }
      uint end = i + 32;
      if (end > data.length) {
        end = data.length;
      }
      string memory prefix = string.concat(
        linePrefix,
        '[',
        i.toString(),
        ':',
        end.toString(),
        ']: '
      );

      console2.log(prefix, word.toHexString());
    }
  }

  function printWordsInBytes(bytes memory data, bool hasSelector) internal pure {
    printWordsInBytes(data, '', hasSelector);
  }
}
