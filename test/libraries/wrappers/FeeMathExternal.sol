pragma solidity ^0.8.20;

import { FeeMath } from 'src/libraries/FeeMath.sol';
import { MarketState } from 'src/libraries/MarketState.sol';

library FeeMathExternal {
  function $calculateLinearInterestFromBips(
    uint256 rateBip,
    uint256 timeDelta
  ) external pure returns (uint256 result) {
    return FeeMath.calculateLinearInterestFromBips(rateBip, timeDelta);
  }

  function $calculateBaseInterest(
    MarketState memory state,
    uint256 timestamp
  ) external pure returns (uint256 baseInterestRay) {
    return FeeMath.calculateBaseInterest(state, timestamp);
  }

  function $applyProtocolFee(
    MarketState memory state,
    uint256 baseInterestRay
  ) external pure returns (MarketState memory newState, uint256 protocolFee) {
    protocolFee = FeeMath.applyProtocolFee(state, baseInterestRay);
    newState = state;
  }

  function $updateDelinquency(
    MarketState memory state,
    uint256 timestamp,
    uint256 delinquencyFeeBips,
    uint256 delinquencyGracePeriod
  ) external pure returns (MarketState memory newState, uint256 delinquencyFeeRay) {
    newState = state;
    delinquencyFeeRay = FeeMath.updateDelinquency(
      state,
      timestamp,
      delinquencyFeeBips,
      delinquencyGracePeriod
    );
  }

  function $updateTimeDelinquentAndGetPenaltyTime(
    MarketState memory state,
    uint256 delinquencyGracePeriod,
    uint256 timeDelta
  ) external pure returns (MarketState memory newState, uint256 timeWithPenalty) {
    newState = state;
    timeWithPenalty = FeeMath.updateTimeDelinquentAndGetPenaltyTime(
      state,
      delinquencyGracePeriod,
      timeDelta
    );
  }

  function $updateScaleFactorAndFees(
    MarketState memory state,
    uint256 delinquencyFeeBips,
    uint256 delinquencyGracePeriod,
    uint256 timestamp
  )
    external
    pure
    returns (
      MarketState memory newState,
      uint256 baseInterestRay,
      uint256 delinquencyFeeRay,
      uint256 protocolFee
    )
  {
    newState = state;
    (baseInterestRay, delinquencyFeeRay, protocolFee) = FeeMath.updateScaleFactorAndFees(
      state,
      delinquencyFeeBips,
      delinquencyGracePeriod,
      timestamp
    );
  }
}
