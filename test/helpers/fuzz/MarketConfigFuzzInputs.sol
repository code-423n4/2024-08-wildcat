// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { MarketState } from 'src/libraries/MarketState.sol';
import '../../shared/TestConstants.sol';
import { bound } from '../../helpers/VmUtils.sol';
import { MarketInputParameters } from '../../shared/Test.sol';
import { HooksConfig } from 'src/types/HooksConfig.sol';

using LibMarketConfigFuzzInputs for MarketConfigFuzzInputs global;

// Used for fuzzing market deployment parameters
struct MarketConfigFuzzInputs {
  uint128 maxTotalSupply;
  uint16 protocolFeeBips;
  uint16 annualInterestBips;
  uint16 delinquencyFeeBips;
  uint32 withdrawalBatchDuration;
  uint16 reserveRatioBips;
  uint32 delinquencyGracePeriod;
  address feeRecipient;
}

library LibMarketConfigFuzzInputs {
  function constrain(MarketConfigFuzzInputs memory inputs) internal pure {
    inputs.annualInterestBips = uint16(
      bound(inputs.annualInterestBips, MinimumAnnualInterestBips, MaximumAnnualInterestBips)
    );
    inputs.delinquencyFeeBips = uint16(
      bound(inputs.delinquencyFeeBips, MinimumDelinquencyFeeBips, MaximumDelinquencyFeeBips)
    );
    inputs.withdrawalBatchDuration = uint32(
      bound(
        inputs.withdrawalBatchDuration,
        MinimumWithdrawalBatchDuration,
        MaximumWithdrawalBatchDuration
      )
    );
    inputs.reserveRatioBips = uint16(
      bound(inputs.reserveRatioBips, MinimumReserveRatioBips, MaximumReserveRatioBips)
    );
    inputs.delinquencyGracePeriod = uint32(
      bound(
        inputs.delinquencyGracePeriod,
        MinimumDelinquencyGracePeriod,
        MaximumDelinquencyGracePeriod
      )
    );
    if (inputs.protocolFeeBips > 0) {
      inputs.feeRecipient = address(
        uint160(bound(uint160(inputs.feeRecipient), 1, type(uint160).max))
      );
    }
  }

  function toParameters(
    MarketConfigFuzzInputs calldata inputs
  ) internal pure returns (MarketInputParameters memory parameters) {
    inputs.constrain();
    parameters = MarketInputParameters({
      asset: address(0),
      namePrefix: 'Wildcat ',
      symbolPrefix: 'WC',
      borrower: borrower,
      feeRecipient: inputs.feeRecipient,
      sentinel: address(0),
      maxTotalSupply: inputs.maxTotalSupply,
      protocolFeeBips: inputs.protocolFeeBips,
      annualInterestBips: inputs.annualInterestBips,
      delinquencyFeeBips: inputs.delinquencyFeeBips,
      withdrawalBatchDuration: inputs.withdrawalBatchDuration,
      reserveRatioBips: inputs.reserveRatioBips,
      delinquencyGracePeriod: inputs.delinquencyGracePeriod,
      sphereXEngine: address(0),
      hooksTemplate: address(0),
      deployHooksConstructorArgs: '',
      deployMarketHooksData: '',
      hooksConfig: HooksConfig.wrap(0),
      minimumDeposit: 0
    });
  }
}
