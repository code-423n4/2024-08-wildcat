pragma solidity ^0.8.20;

uint256 constant InterestAndFeesAccrued_abi_head_size = 0xc0;
uint256 constant InterestAndFeesAccrued_toTimestamp_offset = 0x20;
uint256 constant InterestAndFeesAccrued_scaleFactor_offset = 0x40;
uint256 constant InterestAndFeesAccrued_baseInterestRay_offset = 0x60;
uint256 constant InterestAndFeesAccrued_delinquencyFeeRay_offset = 0x80;
uint256 constant InterestAndFeesAccrued_protocolFees_offset = 0xa0;

function emit_Transfer(address from, address to, uint256 value) {
  assembly {
    mstore(0, value)
    log3(0, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to)
  }
}

function emit_Approval(address owner, address spender, uint256 value) {
  assembly {
    mstore(0, value)
    log3(
      0,
      0x20,
      0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
      owner,
      spender
    )
  }
}

function emit_MaxTotalSupplyUpdated(uint256 assets) {
  assembly {
    mstore(0, assets)
    log1(0, 0x20, 0xf2672935fc79f5237559e2e2999dbe743bf65430894ac2b37666890e7c69e1af)
  }
}

function emit_ProtocolFeeBipsUpdated(uint256 protocolFeeBips) {
  assembly {
    mstore(0, protocolFeeBips)
    log1(0, 0x20, 0x4b34705283cdb9398d0e50b216b8fb424c6d4def5db9bfadc661ee3adc6076ee)
  }
}

function emit_AnnualInterestBipsUpdated(uint256 annualInterestBipsUpdated) {
  assembly {
    mstore(0, annualInterestBipsUpdated)
    log1(0, 0x20, 0xff7b6c8be373823323d3c5d99f5d027dd409dce5db54eae511bbdd5546b75037)
  }
}

function emit_ReserveRatioBipsUpdated(uint256 reserveRatioBipsUpdated) {
  assembly {
    mstore(0, reserveRatioBipsUpdated)
    log1(0, 0x20, 0x72877a153052500f5edbb2f9da96a0f45d671d4b4555fdf8628a709dc4eab43a)
  }
}

function emit_SanctionedAccountAssetsSentToEscrow(address account, address escrow, uint256 amount) {
  assembly {
    mstore(0, escrow)
    mstore(0x20, amount)
    log2(0, 0x40, 0x571e706c2f09ae0632313e5f3ae89fffdedfc370a2ea59a07fb0d8091147645b, account)
  }
}

function emit_SanctionedAccountAssetsQueuedForWithdrawal(
  address account,
  uint32 expiry,
  uint256 scaledAmount,
  uint256 normalizedAmount
) {
  assembly {
    let freePointer := mload(0x40)
    mstore(0, expiry)
    mstore(0x20, scaledAmount)
    mstore(0x40, normalizedAmount)
    log2(0, 0x60, 0xe12b220b92469ae28fb0d79de531f94161431be9f073b96b8aad3effb88be6fa, account)
    mstore(0x40, freePointer)
  }
}

function emit_Deposit(address account, uint256 assetAmount, uint256 scaledAmount) {
  assembly {
    mstore(0, assetAmount)
    mstore(0x20, scaledAmount)
    log2(0, 0x40, 0x90890809c654f11d6e72a28fa60149770a0d11ec6c92319d6ceb2bb0a4ea1a15, account)
  }
}

function emit_Borrow(uint256 assetAmount) {
  assembly {
    mstore(0, assetAmount)
    log1(0, 0x20, 0xb848ae6b1253b6cb77e81464128ce8bd94d3d524fea54e801e0da869784dca33)
  }
}

function emit_DebtRepaid(address from, uint256 assetAmount) {
  assembly {
    mstore(0, assetAmount)
    log2(0, 0x20, 0xe8b606ac1e5df7657db58d297ca8f41c090fc94c5fd2d6958f043e41736e9fa6, from)
  }
}

function emit_MarketClosed(uint256 _timestamp) {
  assembly {
    mstore(0, _timestamp)
    log1(0, 0x20, 0x9dc30b8eda31a6a144e092e5de600955523a6a925cc15cc1d1b9b4872cfa6155)
  }
}

function emit_FeesCollected(uint256 assets) {
  assembly {
    mstore(0, assets)
    log1(0, 0x20, 0x860c0aa5520013080c2f65981705fcdea474d9f7c3daf954656ed5e65d692d1f)
  }
}

function emit_StateUpdated(uint256 scaleFactor, bool isDelinquent) {
  assembly {
    mstore(0, scaleFactor)
    mstore(0x20, isDelinquent)
    log1(0, 0x40, 0x9385f9ff65bcd2fb81cece54b27d4ec7376795fc4dcff686e370e347b0ed86c0)
  }
}

function emit_InterestAndFeesAccrued(
  uint256 fromTimestamp,
  uint256 toTimestamp,
  uint256 scaleFactor,
  uint256 baseInterestRay,
  uint256 delinquencyFeeRay,
  uint256 protocolFees
) {
  assembly {
    let dst := mload(0x40)
    /// Copy fromTimestamp
    mstore(dst, fromTimestamp)
    /// Copy toTimestamp
    mstore(add(dst, InterestAndFeesAccrued_toTimestamp_offset), toTimestamp)
    /// Copy scaleFactor
    mstore(add(dst, InterestAndFeesAccrued_scaleFactor_offset), scaleFactor)
    /// Copy baseInterestRay
    mstore(add(dst, InterestAndFeesAccrued_baseInterestRay_offset), baseInterestRay)
    /// Copy delinquencyFeeRay
    mstore(add(dst, InterestAndFeesAccrued_delinquencyFeeRay_offset), delinquencyFeeRay)
    /// Copy protocolFees
    mstore(add(dst, InterestAndFeesAccrued_protocolFees_offset), protocolFees)
    log1(
      dst,
      InterestAndFeesAccrued_abi_head_size,
      0x18247a393d0531b65fbd94f5e78bc5639801a4efda62ae7b43533c4442116c3a
    )
  }
}

function emit_WithdrawalBatchExpired(
  uint256 expiry,
  uint256 scaledTotalAmount,
  uint256 scaledAmountBurned,
  uint256 normalizedAmountPaid
) {
  assembly {
    let freePointer := mload(0x40)
    mstore(0, scaledTotalAmount)
    mstore(0x20, scaledAmountBurned)
    mstore(0x40, normalizedAmountPaid)
    log2(0, 0x60, 0x9262dc39b47cad3a0512e4c08dda248cb345e7163058f300bc63f56bda288b6e, expiry)
    mstore(0x40, freePointer)
  }
}

function emit_WithdrawalBatchCreated(uint256 expiry) {
  assembly {
    log2(0, 0x00, 0x5c9a946d3041134198ebefcd814de7748def6576efd3d1b48f48193e183e89ef, expiry)
  }
}

function emit_WithdrawalBatchClosed(uint256 expiry) {
  assembly {
    log2(0, 0x00, 0xcbdf25bf6e096dd9030d89bb2ba2e3e7adb82d25a233c3ca3d92e9f098b74e55, expiry)
  }
}

function emit_WithdrawalBatchPayment(
  uint256 expiry,
  uint256 scaledAmountBurned,
  uint256 normalizedAmountPaid
) {
  assembly {
    mstore(0, scaledAmountBurned)
    mstore(0x20, normalizedAmountPaid)
    log2(0, 0x40, 0x5272034725119f19d7236de4129fdb5093f0dcb80282ca5edbd587df91d2bd89, expiry)
  }
}

function emit_WithdrawalQueued(
  uint256 expiry,
  address account,
  uint256 scaledAmount,
  uint256 normalizedAmount
) {
  assembly {
    mstore(0, scaledAmount)
    mstore(0x20, normalizedAmount)
    log3(
      0,
      0x40,
      0xecc966b282a372469fa4d3e497c2ac17983c3eaed03f3f17c9acf4b15591663e,
      expiry,
      account
    )
  }
}

function emit_WithdrawalExecuted(uint256 expiry, address account, uint256 normalizedAmount) {
  assembly {
    mstore(0, normalizedAmount)
    log3(
      0,
      0x20,
      0xd6cddb3d69146e96ebc2c87b1b3dd0b20ee2d3b0eadf134e011afb434a3e56e6,
      expiry,
      account
    )
  }
}

function emit_SanctionedAccountWithdrawalSentToEscrow(
  address account,
  address escrow,
  uint32 expiry,
  uint256 amount
) {
  assembly {
    let freePointer := mload(0x40)
    mstore(0, escrow)
    mstore(0x20, expiry)
    mstore(0x40, amount)
    log2(0, 0x60, 0x0d0843a0fcb8b83f625aafb6e42f234ac48c6728b207d52d97cfa8fbd34d498f, account)
    mstore(0x40, freePointer)
  }
}
