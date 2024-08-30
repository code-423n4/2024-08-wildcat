// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import 'src/libraries/MathUtils.sol';
import { MarketState } from 'src/libraries/MarketState.sol';
import '../../shared/TestConstants.sol';
import { bound } from '../VmUtils.sol';

using LibMarketStateFuzzInputs for MarketStateFuzzInputs global;

// Used for fuzzing initial state for libraries
struct MarketStateFuzzInputs {
  uint128 maxTotalSupply;
  uint128 accruedProtocolFees;
  uint128 normalizedUnclaimedWithdrawals;
  uint104 scaledTotalSupply;
  uint32 pendingWithdrawalExpiry;
  bool isDelinquent;
  uint32 timeDelinquent;
  uint16 protocolFeeBips;
  uint16 annualInterestBips;
  uint16 reserveRatioBips;
  uint112 scaleFactor;
  uint32 lastInterestAccruedTimestamp;
}

library LibMarketStateFuzzInputs {
  using MathUtils for uint256;

  function constrain(MarketStateFuzzInputs memory inputs) internal view {
    inputs.scaleFactor = uint112(bound(inputs.scaleFactor, RAY, type(uint112).max));
    inputs.scaledTotalSupply = uint104(bound(inputs.scaledTotalSupply, 0, type(uint104).max));
    inputs.maxTotalSupply = uint128(
      bound(
        inputs.maxTotalSupply,
        uint256(inputs.scaledTotalSupply).rayMul(inputs.scaleFactor),
        type(uint128).max
      )
    );
    inputs.protocolFeeBips = uint16(
      bound(inputs.protocolFeeBips, MinimumProtocolFeeBips, MaximumProtocolFeeBips)
    );
    inputs.annualInterestBips = uint16(
      bound(inputs.annualInterestBips, MinimumAnnualInterestBips, MaximumAnnualInterestBips)
    );
    inputs.reserveRatioBips = uint16(
      bound(inputs.reserveRatioBips, MinimumReserveRatioBips, MaximumReserveRatioBips)
    );
    inputs.lastInterestAccruedTimestamp = uint32(
      bound(inputs.lastInterestAccruedTimestamp, 1, block.timestamp)
    );
    inputs.timeDelinquent = uint32(
      bound(inputs.timeDelinquent, 0, inputs.lastInterestAccruedTimestamp)
    );
  }

  function toState(
    MarketStateFuzzInputs memory inputs
  ) internal view returns (MarketState memory state) {
    inputs.constrain();
    state.maxTotalSupply = inputs.maxTotalSupply;
    state.accruedProtocolFees = inputs.accruedProtocolFees;
    state.normalizedUnclaimedWithdrawals = inputs.normalizedUnclaimedWithdrawals;
    state.scaledTotalSupply = inputs.scaledTotalSupply;
    state.pendingWithdrawalExpiry = inputs.pendingWithdrawalExpiry;
    state.isDelinquent = inputs.isDelinquent;
    state.timeDelinquent = inputs.timeDelinquent;
    state.protocolFeeBips = inputs.protocolFeeBips;
    state.annualInterestBips = inputs.annualInterestBips;
    state.reserveRatioBips = inputs.reserveRatioBips;
    state.scaleFactor = inputs.scaleFactor;
    state.lastInterestAccruedTimestamp = inputs.lastInterestAccruedTimestamp;
  }
}
