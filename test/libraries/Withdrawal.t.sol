// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'forge-std/Test.sol';
import 'src/libraries/Withdrawal.sol';
import './wrappers/WithdrawalLibExternal.sol';

// Uses an external wrapper library to make forge coverage work for WithdrawalLib.
// Forge is currently incapable of mapping MemberAccess function calls with
// expressions other than library identifiers (e.g. value.x() vs XLib.x(value))
// to the correct FunctionDefinition nodes.
contract WithdrawalTest is Test {
  WithdrawalData internal _withdrawalData;

  using WithdrawalLibExternal for WithdrawalBatch;

  function test_availableLiquidityForPendingBatch(
    uint128 totalAssets,
    uint104 scaledTotalPendingWithdrawals,
    uint104 scaledBatchAmount,
    uint128 normalizedUnclaimedWithdrawals,
    uint96 scaleFactor,
    uint128 accruedProtocolFees
  ) external {
    scaledTotalPendingWithdrawals = uint104(
      bound(scaledTotalPendingWithdrawals, 1, type(uint104).max)
    );
    scaledBatchAmount = uint104(bound(scaledBatchAmount, 1, scaledTotalPendingWithdrawals));
    MarketState memory state;
    state.normalizedUnclaimedWithdrawals = normalizedUnclaimedWithdrawals;
    state.accruedProtocolFees = accruedProtocolFees;
    state.scaleFactor = scaleFactor;
    state.scaledPendingWithdrawals = scaledTotalPendingWithdrawals;
    WithdrawalBatch memory batch;
    batch.scaledTotalAmount = scaledBatchAmount;
    uint256 totalReserved = uint256(normalizedUnclaimedWithdrawals) +
      uint256(accruedProtocolFees) +
      state.normalizeAmount(scaledTotalPendingWithdrawals - scaledBatchAmount);
    uint256 expected = totalAssets > totalReserved ? totalAssets - totalReserved : 0;
    assertEq(batch.$availableLiquidityForPendingBatch(state, totalAssets), expected);
  }
}
