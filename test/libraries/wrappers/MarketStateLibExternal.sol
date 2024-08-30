// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import { MarketState, MarketStateLib } from 'src/libraries/MarketState.sol';

library MarketStateLibExternal {
  /// @dev Returns the normalized total supply of the market.
  function $totalSupply(MarketState memory state) external pure returns (uint256) {
    return MarketStateLib.totalSupply(state);
  }

  /// @dev Returns the maximum amount of tokens that can be deposited without
  /// reaching the maximum total supply.
  function $maximumDeposit(MarketState memory state) external pure returns (uint256) {
    return MarketStateLib.maximumDeposit(state);
  }

  /// @dev Normalize an amount of scaled tokens using the current scale factor.
  function $normalizeAmount(
    MarketState memory state,
    uint256 amount
  ) external pure returns (uint256) {
    return MarketStateLib.normalizeAmount(state, amount);
  }

  /// @dev Scale an amount of normalized tokens using the current scale factor.
  function $scaleAmount(MarketState memory state, uint256 amount) external pure returns (uint256) {
    return MarketStateLib.scaleAmount(state, amount);
  }

  /// Collateralization requires all pending withdrawals be covered
  /// and reserve ratio for remaining liquidity.
  function $liquidityRequired(
    MarketState memory state
  ) external pure returns (uint256 _liquidityRequired) {
    return MarketStateLib.liquidityRequired(state);
  }

  function $borrowableAssets(
    MarketState memory state,
    uint256 totalAssets
  ) external pure returns (uint256) {
    return MarketStateLib.borrowableAssets(state, totalAssets);
  }

  function $hasPendingExpiredBatch(MarketState memory state) external view returns (bool result) {
    return MarketStateLib.hasPendingExpiredBatch(state);
  }

  function $withdrawableProtocolFees(
    MarketState memory state,
    uint256 totalAssets
  ) external pure returns (uint256) {
    return MarketStateLib.withdrawableProtocolFees(state, totalAssets);
  }
}
