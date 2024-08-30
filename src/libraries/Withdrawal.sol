// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './MarketState.sol';
import './FIFOQueue.sol';

using MathUtils for uint256;
using WithdrawalLib for WithdrawalBatch global;

/**
 * Withdrawals are grouped together in batches with a fixed expiry.
 * Until a withdrawal is paid out, the tokens are not burned from the market
 * and continue to accumulate interest.
 */
struct WithdrawalBatch {
  // Total scaled amount of tokens to be withdrawn
  uint104 scaledTotalAmount;
  // Amount of scaled tokens that have been paid by borrower
  uint104 scaledAmountBurned;
  // Amount of normalized tokens that have been paid by borrower
  uint128 normalizedAmountPaid;
}

struct AccountWithdrawalStatus {
  uint104 scaledAmount;
  uint128 normalizedAmountWithdrawn;
}

struct WithdrawalData {
  FIFOQueue unpaidBatches;
  mapping(uint32 => WithdrawalBatch) batches;
  mapping(uint256 => mapping(address => AccountWithdrawalStatus)) accountStatuses;
}

library WithdrawalLib {
  function scaledOwedAmount(WithdrawalBatch memory batch) internal pure returns (uint104) {
    return batch.scaledTotalAmount - batch.scaledAmountBurned;
  }

  /**
   * @dev Get the amount of assets which are not already reserved
   *      for prior withdrawal batches. This must only be used on
   *      the latest withdrawal batch to expire.
   */
  function availableLiquidityForPendingBatch(
    WithdrawalBatch memory batch,
    MarketState memory state,
    uint256 totalAssets
  ) internal pure returns (uint256) {
    // Subtract normalized value of pending scaled withdrawals, processed
    // withdrawals and protocol fees.
    uint256 priorScaledAmountPending = (state.scaledPendingWithdrawals - batch.scaledOwedAmount());
    uint256 unavailableAssets = state.normalizedUnclaimedWithdrawals +
      state.normalizeAmount(priorScaledAmountPending) +
      state.accruedProtocolFees;
    return totalAssets.satSub(unavailableAssets);
  }
}
