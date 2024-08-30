// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './IHooks.sol';
import '../libraries/BoolUtils.sol';

struct TemporaryReserveRatio {
  uint16 originalAnnualInterestBips;
  uint16 originalReserveRatioBips;
  uint32 expiry;
}

abstract contract MarketConstraintHooks is IHooks {
  using BoolUtils for bool;

  error DelinquencyGracePeriodOutOfBounds();
  error ReserveRatioBipsOutOfBounds();
  error DelinquencyFeeBipsOutOfBounds();
  error WithdrawalBatchDurationOutOfBounds();
  error AnnualInterestBipsOutOfBounds();

  event TemporaryExcessReserveRatioActivated(
    address indexed market,
    uint256 originalReserveRatioBips,
    uint256 temporaryReserveRatioBips,
    uint256 temporaryReserveRatioExpiry
  );

  event TemporaryExcessReserveRatioUpdated(
    address indexed market,
    uint256 originalReserveRatioBips,
    uint256 temporaryReserveRatioBips,
    uint256 temporaryReserveRatioExpiry
  );

  event TemporaryExcessReserveRatioCanceled(address indexed market);

  event TemporaryExcessReserveRatioExpired(address indexed market);

  uint32 internal constant MinimumDelinquencyGracePeriod = 0;
  uint32 internal constant MaximumDelinquencyGracePeriod = 90 days;

  uint16 internal constant MinimumReserveRatioBips = 0;
  uint16 internal constant MaximumReserveRatioBips = 10_000;

  uint16 internal constant MinimumDelinquencyFeeBips = 0;
  uint16 internal constant MaximumDelinquencyFeeBips = 10_000;

  uint32 internal constant MinimumWithdrawalBatchDuration = 0;
  uint32 internal constant MaximumWithdrawalBatchDuration = 365 days;

  uint16 internal constant MinimumAnnualInterestBips = 0;
  uint16 internal constant MaximumAnnualInterestBips = 10_000;

  mapping(address => TemporaryReserveRatio) public temporaryExcessReserveRatio;

  function assertValueInRange(
    uint256 value,
    uint256 min,
    uint256 max,
    bytes4 errorSelector
  ) internal pure {
    assembly {
      if or(lt(value, min), gt(value, max)) {
        mstore(0, errorSelector)
        revert(0, 4)
      }
    }
  }

  /**
   * @dev Enforce constraints on market parameters, ensuring that
   *      `annualInterestBips`, `delinquencyFeeBips`, `withdrawalBatchDuration`,
   *      `reserveRatioBips` and `delinquencyGracePeriod` are within the
   *      allowed ranges and that `namePrefix` and `symbolPrefix` are not null.
   */
  function enforceParameterConstraints(
    uint16 annualInterestBips,
    uint16 delinquencyFeeBips,
    uint32 withdrawalBatchDuration,
    uint16 reserveRatioBips,
    uint32 delinquencyGracePeriod
  ) internal view virtual {
    assertValueInRange(
      annualInterestBips,
      MinimumAnnualInterestBips,
      MaximumAnnualInterestBips,
      AnnualInterestBipsOutOfBounds.selector
    );
    assertValueInRange(
      delinquencyFeeBips,
      MinimumDelinquencyFeeBips,
      MaximumDelinquencyFeeBips,
      DelinquencyFeeBipsOutOfBounds.selector
    );
    assertValueInRange(
      withdrawalBatchDuration,
      MinimumWithdrawalBatchDuration,
      MaximumWithdrawalBatchDuration,
      WithdrawalBatchDurationOutOfBounds.selector
    );
    assertValueInRange(
      reserveRatioBips,
      MinimumReserveRatioBips,
      MaximumReserveRatioBips,
      ReserveRatioBipsOutOfBounds.selector
    );
    assertValueInRange(
      delinquencyGracePeriod,
      MinimumDelinquencyGracePeriod,
      MaximumDelinquencyGracePeriod,
      DelinquencyGracePeriodOutOfBounds.selector
    );
  }

  /**
   * @dev Returns immutable constraints on market parameters that
   *      the controller variant will enforce.
   */
  function getParameterConstraints()
    external
    pure
    returns (MarketParameterConstraints memory constraints)
  {
    constraints.minimumDelinquencyGracePeriod = MinimumDelinquencyGracePeriod;
    constraints.maximumDelinquencyGracePeriod = MaximumDelinquencyGracePeriod;
    constraints.minimumReserveRatioBips = MinimumReserveRatioBips;
    constraints.maximumReserveRatioBips = MaximumReserveRatioBips;
    constraints.minimumDelinquencyFeeBips = MinimumDelinquencyFeeBips;
    constraints.maximumDelinquencyFeeBips = MaximumDelinquencyFeeBips;
    constraints.minimumWithdrawalBatchDuration = MinimumWithdrawalBatchDuration;
    constraints.maximumWithdrawalBatchDuration = MaximumWithdrawalBatchDuration;
    constraints.minimumAnnualInterestBips = MinimumAnnualInterestBips;
    constraints.maximumAnnualInterestBips = MaximumAnnualInterestBips;
  }

  function _onCreateMarket(
    address /* deployer */,
    address /* marketAddress */,
    DeployMarketInputs calldata parameters,
    bytes calldata /* extraData */
  ) internal virtual override returns (HooksConfig) {
    enforceParameterConstraints(
      parameters.annualInterestBips,
      parameters.delinquencyFeeBips,
      parameters.withdrawalBatchDuration,
      parameters.reserveRatioBips,
      parameters.delinquencyGracePeriod
    );
  }

  /**
   * @dev Returns the new temporary reserve ratio for a given interest rate
   *      change. This is calculated as no change if the rate change is LEQ
   *      a 25% decrease, otherwise double the relative difference between
   *      the old and new APR rates (in bips), bounded to a maximum of 100%.
   *      If this value is lower than the existing reserve ratio, the existing
   *      reserve ratio is returned instead.
   */
  function _calculateTemporaryReserveRatioBips(
    uint256 annualInterestBips,
    uint256 originalAnnualInterestBips,
    uint256 originalReserveRatioBips
  ) internal pure returns (uint16 temporaryReserveRatioBips) {
    // Calculate the relative reduction in the interest rate in bips,
    // bound to a maximum of 100%
    uint256 relativeDiff = MathUtils.mulDiv(
      10000,
      originalAnnualInterestBips - annualInterestBips,
      originalAnnualInterestBips
    );

    // If the reduction is 25% (2500 bips) or less, return the original reserve ratio
    if (relativeDiff <= 2500) {
      temporaryReserveRatioBips = uint16(originalReserveRatioBips);
    } else {
      // Calculate double the relative reduction in the interest rate in bips,
      // bound to a maximum of 100%
      uint256 boundRelativeDiff = MathUtils.min(10000, 2 * relativeDiff);

      // If the bound relative diff is lower than the existing reserve ratio, return the latter.
      temporaryReserveRatioBips = uint16(
        MathUtils.max(boundRelativeDiff, originalReserveRatioBips)
      );
    }
  }

  /**
   * @dev Hook to enforce constraints on changes to the annual interest rate
   *      and reserve ratio. Reducing the APR triggers an update period of two weeks,
   *      during which the market's reserve ratio is temporarily increased proportionally
   *      to the reduction. The original APR is pegged to the previous value during this
   *      time to prevent abuse of the allowed 25% unpenalized reduction.
   *
   * @param annualInterestBips The new annual interest rate in bips provided by the borrower.
   * @param {} Unused parameter for the reserve ratio bips provided by the borrower.
   * @param intermediateState The current state of the market.
   * @param {} Unused parameter for extra data.
   *
   * @return newAnnualInterestBips The new annual interest rate in bips to be set.
   *                               always equal to the input parameter.
   * @return newReserveRatioBips The new reserve ratio in bips to be set.
   */
  function onSetAnnualInterestAndReserveRatioBips(
    uint16 annualInterestBips,
    uint16 /* reserveRatioBips */,
    MarketState calldata intermediateState,
    bytes calldata /* extraData */
  ) public virtual override returns (uint16 newAnnualInterestBips, uint16 newReserveRatioBips) {
    (newAnnualInterestBips, newReserveRatioBips) = (
      annualInterestBips,
      intermediateState.reserveRatioBips
    );
    address market = msg.sender;

    assertValueInRange(
      annualInterestBips,
      MinimumAnnualInterestBips,
      MaximumAnnualInterestBips,
      AnnualInterestBipsOutOfBounds.selector
    );

    // Get the existing temporary reserve ratio from storage, if any
    TemporaryReserveRatio memory tmp = temporaryExcessReserveRatio[market];

    if (tmp.expiry > 0) {
      bool canExpire = (annualInterestBips >= intermediateState.annualInterestBips).and(
        block.timestamp >= tmp.expiry
      );
      bool canCancel = annualInterestBips >= tmp.originalAnnualInterestBips;
      if (canExpire.or(canCancel)) {
        // If the update period has expired and the provided value doesn't reduce it further,
        // or it is not expired but the new value undoes the reduction for the current update
        // period, reset the temporary reserve ratio.
        if (canExpire) {
          emit TemporaryExcessReserveRatioExpired(market);
        } else {
          emit TemporaryExcessReserveRatioCanceled(market);
        }
        delete temporaryExcessReserveRatio[market];
        return (newAnnualInterestBips, tmp.originalReserveRatioBips);
      }
    }

    // Get the original values for the ongoing or newly created update period.
    (uint16 originalAnnualInterestBips, uint16 originalReserveRatioBips) = tmp.expiry == 0
      ? (intermediateState.annualInterestBips, intermediateState.reserveRatioBips)
      : (tmp.originalAnnualInterestBips, tmp.originalReserveRatioBips);

    if (annualInterestBips < originalAnnualInterestBips) {
      // If the new interest rate is lower than the original, calculate a temporarily
      // increased reserve ratio as:
      // relativeReduction <= 0.25 ? originalReserveRatio : max(originalReserveRatio, min(2 * relativeReduction, 100%))
      uint16 temporaryReserveRatioBips = _calculateTemporaryReserveRatioBips(
        annualInterestBips,
        originalAnnualInterestBips,
        originalReserveRatioBips
      );
      uint32 expiry = uint32(block.timestamp + 2 weeks);
      if (tmp.expiry == 0) {
        // If there is no existing temporary reserve ratio, store the current
        // interest rate and reserve ratio as the original values.
        emit TemporaryExcessReserveRatioActivated(
          market,
          originalReserveRatioBips,
          temporaryReserveRatioBips,
          expiry
        );
        tmp.originalAnnualInterestBips = originalAnnualInterestBips;
        tmp.originalReserveRatioBips = originalReserveRatioBips;
      } else {
        // If the new APR is lower than the original but higher than the current rate,
        // update the reserve ratio but leave the previous expiry; otherwise, reset the timer.
        if (annualInterestBips >= intermediateState.annualInterestBips) {
          expiry = tmp.expiry;
        }
        emit TemporaryExcessReserveRatioUpdated(
          market,
          originalReserveRatioBips,
          temporaryReserveRatioBips,
          expiry
        );
      }
      tmp.expiry = expiry;
      temporaryExcessReserveRatio[market] = tmp;
      newReserveRatioBips = temporaryReserveRatioBips;
    }
  }
}
