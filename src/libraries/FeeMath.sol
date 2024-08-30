// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './MathUtils.sol';
import './SafeCastLib.sol';
import './MarketState.sol';

using SafeCastLib for uint256;
using MathUtils for uint256;

library FeeMath {
  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   *
   * @param rateBip The interest rate, in bips
   * @param timeDelta The time elapsed since the last interest accrual
   * @return result The interest rate linearly accumulated during the timeDelta, in ray
   */
  function calculateLinearInterestFromBips(
    uint256 rateBip,
    uint256 timeDelta
  ) internal pure returns (uint256 result) {
    uint256 rate = rateBip.bipToRay();
    uint256 accumulatedInterestRay = rate * timeDelta;
    unchecked {
      return accumulatedInterestRay / SECONDS_IN_365_DAYS;
    }
  }

  function calculateBaseInterest(
    MarketState memory state,
    uint256 timestamp
  ) internal pure returns (uint256 baseInterestRay) {
    baseInterestRay = MathUtils.calculateLinearInterestFromBips(
      state.annualInterestBips,
      timestamp - state.lastInterestAccruedTimestamp
    );
  }

  function applyProtocolFee(
    MarketState memory state,
    uint256 baseInterestRay
  ) internal pure returns (uint256 protocolFee) {
    // Protocol fee is charged in addition to the interest paid to lenders.
    uint256 protocolFeeRay = uint(state.protocolFeeBips).bipMul(baseInterestRay);
    protocolFee = uint256(state.scaledTotalSupply).rayMul(
      uint256(state.scaleFactor).rayMul(protocolFeeRay)
    );
    state.accruedProtocolFees = (state.accruedProtocolFees + protocolFee).toUint128();
  }

  function updateDelinquency(
    MarketState memory state,
    uint256 timestamp,
    uint256 delinquencyFeeBips,
    uint256 delinquencyGracePeriod
  ) internal pure returns (uint256 delinquencyFeeRay) {
    // Calculate the number of seconds the borrower spent in penalized
    // delinquency since the last update.
    uint256 timeWithPenalty = updateTimeDelinquentAndGetPenaltyTime(
      state,
      delinquencyGracePeriod,
      timestamp - state.lastInterestAccruedTimestamp
    );

    if (timeWithPenalty > 0) {
      // Calculate penalty fees on the interest accrued.
      delinquencyFeeRay = calculateLinearInterestFromBips(delinquencyFeeBips, timeWithPenalty);
    }
  }

  /**
   * @notice  Calculate the number of seconds that the market has been in
   *          penalized delinquency since the last update, and update
   *          `timeDelinquent` in state.
   *
   * @dev When `isDelinquent`, equivalent to:
   *        max(0, timeDelta - max(0, delinquencyGracePeriod - previousTimeDelinquent))
   *      When `!isDelinquent`, equivalent to:
   *        min(timeDelta, max(0, previousTimeDelinquent - delinquencyGracePeriod))
   *
   * @param state Encoded state parameters
   * @param delinquencyGracePeriod Seconds in delinquency before penalties apply
   * @param timeDelta Seconds since the last update
   * @param `timeWithPenalty` Number of seconds since the last update where
   *        the market was in delinquency outside of the grace period.
   */
  function updateTimeDelinquentAndGetPenaltyTime(
    MarketState memory state,
    uint256 delinquencyGracePeriod,
    uint256 timeDelta
  ) internal pure returns (uint256 /* timeWithPenalty */) {
    // Seconds in delinquency at last update
    uint256 previousTimeDelinquent = state.timeDelinquent;

    if (state.isDelinquent) {
      // Since the borrower is still delinquent, increase the total
      // time in delinquency by the time elapsed.
      state.timeDelinquent = (previousTimeDelinquent + timeDelta).toUint32();

      // Calculate the number of seconds the borrower had remaining
      // in the grace period.
      uint256 secondsRemainingWithoutPenalty = delinquencyGracePeriod.satSub(
        previousTimeDelinquent
      );

      // Penalties apply for the number of seconds the market spent in
      // delinquency outside of the grace period since the last update.
      return timeDelta.satSub(secondsRemainingWithoutPenalty);
    }

    // Reduce the total time in delinquency by the time elapsed, stopping
    // when it reaches zero.
    state.timeDelinquent = previousTimeDelinquent.satSub(timeDelta).toUint32();

    // Calculate the number of seconds the old timeDelinquent had remaining
    // outside the grace period, or zero if it was already in the grace period.
    uint256 secondsRemainingWithPenalty = previousTimeDelinquent.satSub(delinquencyGracePeriod);

    // Only apply penalties for the remaining time outside of the grace period.
    return MathUtils.min(secondsRemainingWithPenalty, timeDelta);
  }

  /**
   * @dev Calculates interest and delinquency/protocol fees accrued since last state update
   *      and applies it to cached state, returning the rates for base interest and delinquency
   *      fees and the normalized amount of protocol fees accrued.
   *
   *      Takes `timestamp` as input to allow separate calculation of interest
   *      before and after withdrawal batch expiry.
   *
   * @param state Market scale parameters
   * @param delinquencyFeeBips Delinquency fee rate (in bips)
   * @param delinquencyGracePeriod Grace period (in seconds) before delinquency fees apply
   * @param timestamp Time to calculate interest and fees accrued until
   * @return baseInterestRay Interest accrued to lenders (ray)
   * @return delinquencyFeeRay Penalty fee incurred by borrower for delinquency (ray).
   * @return protocolFee Protocol fee charged on interest (normalized token amount).
   */
  function updateScaleFactorAndFees(
    MarketState memory state,
    uint256 delinquencyFeeBips,
    uint256 delinquencyGracePeriod,
    uint256 timestamp
  )
    internal
    pure
    returns (uint256 baseInterestRay, uint256 delinquencyFeeRay, uint256 protocolFee)
  {
    baseInterestRay = state.calculateBaseInterest(timestamp);

    if (state.protocolFeeBips > 0) {
      protocolFee = state.applyProtocolFee(baseInterestRay);
    }

    if (delinquencyFeeBips > 0) {
      delinquencyFeeRay = state.updateDelinquency(
        timestamp,
        delinquencyFeeBips,
        delinquencyGracePeriod
      );
    }

    // Calculate new scaleFactor
    uint256 prevScaleFactor = state.scaleFactor;
    uint256 scaleFactorDelta = prevScaleFactor.rayMul(baseInterestRay + delinquencyFeeRay);

    state.scaleFactor = (prevScaleFactor + scaleFactorDelta).toUint112();
    state.lastInterestAccruedTimestamp = uint32(timestamp);
  }
}
