pragma solidity ^0.8.20;

import { WithdrawalBatch, WithdrawalLib, MarketState } from 'src/libraries/Withdrawal.sol';

library WithdrawalLibExternal {
  function $scaledOwedAmount(WithdrawalBatch memory batch) external pure returns (uint104) {
    return WithdrawalLib.scaledOwedAmount(batch);
  }

  /// @dev Get the amount of assets which are not already reserved
  /// for prior withdrawal batches. This must only be used on
  /// the latest withdrawal batch to expire.
  function $availableLiquidityForPendingBatch(
    WithdrawalBatch memory batch,
    MarketState memory state,
    uint256 totalAssets
  ) external pure returns (uint256) {
    return WithdrawalLib.availableLiquidityForPendingBatch(batch, state, totalAssets);
  }
}
