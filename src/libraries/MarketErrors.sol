pragma solidity ^0.8.20;

uint256 constant MaxSupplyExceeded_ErrorSelector = 0x8a164f63;

/// @dev Equivalent to `revert MaxSupplyExceeded()`
function revert_MaxSupplyExceeded() pure {
  assembly {
    mstore(0, 0x8a164f63)
    revert(0x1c, 0x04)
  }
}

uint256 constant CapacityChangeOnClosedMarket_ErrorSelector = 0x81b21078;

/// @dev Equivalent to `revert CapacityChangeOnClosedMarket()`
function revert_CapacityChangeOnClosedMarket() pure {
  assembly {
    mstore(0, 0x81b21078)
    revert(0x1c, 0x04)
  }
}

uint256 constant AprChangeOnClosedMarket_ErrorSelector = 0xb9de88a2;

/// @dev Equivalent to `revert AprChangeOnClosedMarket()`
function revert_AprChangeOnClosedMarket() pure {
  assembly {
    mstore(0, 0xb9de88a2)
    revert(0x1c, 0x04)
  }
}

uint256 constant MarketAlreadyClosed_ErrorSelector = 0x449e5f50;

/// @dev Equivalent to `revert MarketAlreadyClosed()`
function revert_MarketAlreadyClosed() pure {
  assembly {
    mstore(0, 0x449e5f50)
    revert(0x1c, 0x04)
  }
}

uint256 constant NotApprovedBorrower_ErrorSelector = 0x02171e6a;

/// @dev Equivalent to `revert NotApprovedBorrower()`
function revert_NotApprovedBorrower() pure {
  assembly {
    mstore(0, 0x02171e6a)
    revert(0x1c, 0x04)
  }
}

uint256 constant NotApprovedLender_ErrorSelector = 0xe50a45ce;

/// @dev Equivalent to `revert NotApprovedLender()`
function revert_NotApprovedLender() pure {
  assembly {
    mstore(0, 0xe50a45ce)
    revert(0x1c, 0x04)
  }
}

uint256 constant BadLaunchCode_ErrorSelector = 0xa97ab167;

/// @dev Equivalent to `revert BadLaunchCode()`
function revert_BadLaunchCode() pure {
  assembly {
    mstore(0, 0xa97ab167)
    revert(0x1c, 0x04)
  }
}

uint256 constant ReserveRatioBipsTooHigh_ErrorSelector = 0x8ec83073;

/// @dev Equivalent to `revert ReserveRatioBipsTooHigh()`
function revert_ReserveRatioBipsTooHigh() pure {
  assembly {
    mstore(0, 0x8ec83073)
    revert(0x1c, 0x04)
  }
}

/* 
code size: 25634
initcode size: 28024

errors: -48 runtime, -48 initcode
*/
uint256 constant AnnualInterestBipsTooHigh_ErrorSelector = 0xcf1f916f;

/// @dev Equivalent to `revert ReserveRatioBipsTooHigh()`
function revert_AnnualInterestBipsTooHigh() pure {
  assembly {
    mstore(0, 0xcf1f916f)
    revert(0x1c, 0x04)
  }
}

uint256 constant AccountBlocked_ErrorSelector = 0x6bc671fd;

/// @dev Equivalent to `revert AccountBlocked()`
function revert_AccountBlocked() pure {
  assembly {
    mstore(0, 0x6bc671fd)
    revert(0x1c, 0x04)
  }
}

uint256 constant BorrowAmountTooHigh_ErrorSelector = 0x119fe6e3;

/// @dev Equivalent to `revert BorrowAmountTooHigh()`
function revert_BorrowAmountTooHigh() pure {
  assembly {
    mstore(0, 0x119fe6e3)
    revert(0x1c, 0x04)
  }
}

uint256 constant BadRescueAsset_ErrorSelector = 0x11530cde;

/// @dev Equivalent to `revert BadRescueAsset()`
function revert_BadRescueAsset() pure {
  assembly {
    mstore(0, 0x11530cde)
    revert(0x1c, 0x04)
  }
}

uint256 constant InsufficientReservesForFeeWithdrawal_ErrorSelector = 0xf784cfa4;

/// @dev Equivalent to `revert InsufficientReservesForFeeWithdrawal()`
function revert_InsufficientReservesForFeeWithdrawal() pure {
  assembly {
    mstore(0, 0xf784cfa4)
    revert(0x1c, 0x04)
  }
}

uint256 constant WithdrawalBatchNotExpired_ErrorSelector = 0x2561b880;

/// @dev Equivalent to `revert WithdrawalBatchNotExpired()`
function revert_WithdrawalBatchNotExpired() pure {
  assembly {
    mstore(0, 0x2561b880)
    revert(0x1c, 0x04)
  }
}

uint256 constant NullMintAmount_ErrorSelector = 0xe4aa5055;

/// @dev Equivalent to `revert NullMintAmount()`
function revert_NullMintAmount() pure {
  assembly {
    mstore(0, 0xe4aa5055)
    revert(0x1c, 0x04)
  }
}

uint256 constant NullBurnAmount_ErrorSelector = 0xd61c50f8;

/// @dev Equivalent to `revert NullBurnAmount()`
function revert_NullBurnAmount() pure {
  assembly {
    mstore(0, 0xd61c50f8)
    revert(0x1c, 0x04)
  }
}

uint256 constant NullFeeAmount_ErrorSelector = 0x45c835cb;

/// @dev Equivalent to `revert NullFeeAmount()`
function revert_NullFeeAmount() pure {
  assembly {
    mstore(0, 0x45c835cb)
    revert(0x1c, 0x04)
  }
}

uint256 constant NullTransferAmount_ErrorSelector = 0xddee9b30;

/// @dev Equivalent to `revert NullTransferAmount()`
function revert_NullTransferAmount() pure {
  assembly {
    mstore(0, 0xddee9b30)
    revert(0x1c, 0x04)
  }
}

uint256 constant NullWithdrawalAmount_ErrorSelector = 0x186334fe;

/// @dev Equivalent to `revert NullWithdrawalAmount()`
function revert_NullWithdrawalAmount() pure {
  assembly {
    mstore(0, 0x186334fe)
    revert(0x1c, 0x04)
  }
}

uint256 constant NullRepayAmount_ErrorSelector = 0x7e082088;

/// @dev Equivalent to `revert NullRepayAmount()`
function revert_NullRepayAmount() pure {
  assembly {
    mstore(0, 0x7e082088)
    revert(0x1c, 0x04)
  }
}

uint256 constant DepositToClosedMarket_ErrorSelector = 0x22d7c043;

/// @dev Equivalent to `revert DepositToClosedMarket()`
function revert_DepositToClosedMarket() pure {
  assembly {
    mstore(0, 0x22d7c043)
    revert(0x1c, 0x04)
  }
}

uint256 constant RepayToClosedMarket_ErrorSelector = 0x61d1bc8f;

/// @dev Equivalent to `revert RepayToClosedMarket()`
function revert_RepayToClosedMarket() pure {
  assembly {
    mstore(0, 0x61d1bc8f)
    revert(0x1c, 0x04)
  }
}

uint256 constant BorrowWhileSanctioned_ErrorSelector = 0x4a1c13a9;

/// @dev Equivalent to `revert BorrowWhileSanctioned()`
function revert_BorrowWhileSanctioned() pure {
  assembly {
    mstore(0, 0x4a1c13a9)
    revert(0x1c, 0x04)
  }
}

uint256 constant BorrowFromClosedMarket_ErrorSelector = 0xd0242b28;

/// @dev Equivalent to `revert BorrowFromClosedMarket()`
function revert_BorrowFromClosedMarket() pure {
  assembly {
    mstore(0, 0xd0242b28)
    revert(0x1c, 0x04)
  }
}

uint256 constant CloseMarketWithUnpaidWithdrawals_ErrorSelector = 0x4d790997;

/// @dev Equivalent to `revert CloseMarketWithUnpaidWithdrawals()`
function revert_CloseMarketWithUnpaidWithdrawals() pure {
  assembly {
    mstore(0, 0x4d790997)
    revert(0x1c, 0x04)
  }
}

uint256 constant InsufficientReservesForNewLiquidityRatio_ErrorSelector = 0x253ecbb9;

/// @dev Equivalent to `revert InsufficientReservesForNewLiquidityRatio()`
function revert_InsufficientReservesForNewLiquidityRatio() pure {
  assembly {
    mstore(0, 0x253ecbb9)
    revert(0x1c, 0x04)
  }
}

uint256 constant InsufficientReservesForOldLiquidityRatio_ErrorSelector = 0x0a68e5bf;

/// @dev Equivalent to `revert InsufficientReservesForOldLiquidityRatio()`
function revert_InsufficientReservesForOldLiquidityRatio() pure {
  assembly {
    mstore(0, 0x0a68e5bf)
    revert(0x1c, 0x04)
  }
}

uint256 constant InvalidArrayLength_ErrorSelector = 0x9d89020a;

/// @dev Equivalent to `revert InvalidArrayLength()`
function revert_InvalidArrayLength() pure {
  assembly {
    mstore(0, 0x9d89020a)
    revert(0x1c, 0x04)
  }
}

uint256 constant ProtocolFeeTooHigh_ErrorSelector = 0x499fddb1;

/// @dev Equivalent to `revert ProtocolFeeTooHigh()`
function revert_ProtocolFeeTooHigh() pure {
  assembly {
    mstore(0, 0x499fddb1)
    revert(0x1c, 0x04)
  }
}

uint256 constant ProtocolFeeChangeOnClosedMarket_ErrorSelector = 0x37f1a75f;

/// @dev Equivalent to `revert ProtocolFeeChangeOnClosedMarket()`
function revert_ProtocolFeeChangeOnClosedMarket() pure {
  assembly {
    mstore(0, 0x37f1a75f)
    revert(0x1c, 0x04)
  }
}

uint256 constant ProtocolFeeNotChanged_ErrorSelector = 0xe0cf78fc;

/// @dev Equivalent to `revert ProtocolFeeNotChanged()`
function revert_ProtocolFeeNotChanged() pure {
  assembly {
    mstore(0, 0xe0cf78fc)
    revert(0x1c, 0x04)
  }
}

uint256 constant NotFactory_ErrorSelector = 0x32cc7236;

function revert_NotFactory() pure {
  assembly {
    mstore(0, 0x32cc7236)
    revert(0x1c, 0x04)
  }
}
