// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import '../access/IHooks.sol';
import '../libraries/MarketState.sol';

type HooksConfig is uint256;

HooksConfig constant EmptyHooksConfig = HooksConfig.wrap(0);

using LibHooksConfig for HooksConfig global;
using LibHooksConfig for HooksDeploymentConfig global;

// Type that contains only the flags for a specific hooks contract, with one
// set of flags for optional hooks and one set of flags for required hooks.
type HooksDeploymentConfig is uint256;

function encodeHooksDeploymentConfig(
  HooksConfig optionalFlags,
  HooksConfig requiredFlags
) pure returns (HooksDeploymentConfig flags) {
  assembly {
    let cleanedOptionalFlags := and(0xffff, shr(0x50, optionalFlags))
    let cleanedRequiredFlags := and(0xffff0000, shr(0x40, requiredFlags))
    flags := or(cleanedOptionalFlags, cleanedRequiredFlags)
  }
}

// --------------------- Bits after hook activation flag -------------------- //

// Offsets are from the right

uint256 constant Bit_Enabled_Deposit = 95;
uint256 constant Bit_Enabled_QueueWithdrawal = 94;
uint256 constant Bit_Enabled_ExecuteWithdrawal = 93;
uint256 constant Bit_Enabled_Transfer = 92;
uint256 constant Bit_Enabled_Borrow = 91;
uint256 constant Bit_Enabled_Repay = 90;
uint256 constant Bit_Enabled_CloseMarket = 89;
uint256 constant Bit_Enabled_NukeFromOrbit = 88;
uint256 constant Bit_Enabled_SetMaxTotalSupply = 87;
uint256 constant Bit_Enabled_SetAnnualInterestAndReserveRatioBips = 86;
uint256 constant Bit_Enabled_SetProtocolFeeBips = 85;

uint256 constant MarketStateSize = 0x01c0;

function encodeHooksConfig(
  address hooksAddress,
  bool useOnDeposit,
  bool useOnQueueWithdrawal,
  bool useOnExecuteWithdrawal,
  bool useOnTransfer,
  bool useOnBorrow,
  bool useOnRepay,
  bool useOnCloseMarket,
  bool useOnNukeFromOrbit,
  bool useOnSetMaxTotalSupply,
  bool useOnSetAnnualInterestAndReserveRatioBips,
  bool useOnSetProtocolFeeBips
) pure returns (HooksConfig hooks) {
  assembly {
    hooks := shl(96, hooksAddress)
    hooks := or(hooks, shl(Bit_Enabled_Deposit, useOnDeposit))
    hooks := or(hooks, shl(Bit_Enabled_QueueWithdrawal, useOnQueueWithdrawal))
    hooks := or(hooks, shl(Bit_Enabled_ExecuteWithdrawal, useOnExecuteWithdrawal))
    hooks := or(hooks, shl(Bit_Enabled_Transfer, useOnTransfer))
    hooks := or(hooks, shl(Bit_Enabled_Borrow, useOnBorrow))
    hooks := or(hooks, shl(Bit_Enabled_Repay, useOnRepay))
    hooks := or(hooks, shl(Bit_Enabled_CloseMarket, useOnCloseMarket))
    hooks := or(hooks, shl(Bit_Enabled_NukeFromOrbit, useOnNukeFromOrbit))
    hooks := or(hooks, shl(Bit_Enabled_SetMaxTotalSupply, useOnSetMaxTotalSupply))
    hooks := or(
      hooks,
      shl(
        Bit_Enabled_SetAnnualInterestAndReserveRatioBips,
        useOnSetAnnualInterestAndReserveRatioBips
      )
    )
    hooks := or(hooks, shl(Bit_Enabled_SetProtocolFeeBips, useOnSetProtocolFeeBips))
  }
}

library LibHooksConfig {
  function setHooksAddress(
    HooksConfig hooks,
    address _hooksAddress
  ) internal pure returns (HooksConfig updatedHooks) {
    assembly {
      // Shift twice to clear the address
      updatedHooks := shr(96, shl(96, hooks))
      // Set the new address
      updatedHooks := or(updatedHooks, shl(96, _hooksAddress))
    }
  }

  /**
   * @dev Create a merged HooksConfig with the shared flags of `a` and `b`
   *      and the address of `a`.
   */
  function mergeSharedFlags(
    HooksConfig a,
    HooksConfig b
  ) internal pure returns (HooksConfig merged) {
    assembly {
      let addressA := shl(0x60, shr(0x60, a))
      let flagsA := shl(0xa0, a)
      let flagsB := shl(0xa0, b)
      let mergedFlags := shr(0xa0, and(flagsA, flagsB))
      merged := or(addressA, mergedFlags)
    }
  }

  /**
   * @dev Create a merged HooksConfig with the shared flags of `a` and `b`
   *      and the address of `a`.
   */
  function mergeAllFlags(HooksConfig a, HooksConfig b) internal pure returns (HooksConfig merged) {
    assembly {
      let addressA := shl(0x60, shr(0x60, a))
      let flagsA := shl(0xa0, a)
      let flagsB := shl(0xa0, b)
      let mergedFlags := shr(0xa0, or(flagsA, flagsB))
      merged := or(addressA, mergedFlags)
    }
  }

  function mergeFlags(
    HooksConfig config,
    HooksDeploymentConfig flags
  ) internal pure returns (HooksConfig merged) {
    assembly {
      let _hooksAddress := shl(96, shr(96, config))
      // Position flags at the end of the word
      let configFlags := shr(0x50, config)
      // Optional flags are already in the right position, required flags must be
      // shifted to align with the other flags. The leading and trailing bits for all 3
      // words will be masked out at the end
      let _optionalFlags := flags
      let _requiredFlags := shr(0x10, flags)
      let mergedFlags := and(0xffff, or(and(configFlags, _optionalFlags), _requiredFlags))

      merged := or(_hooksAddress, shl(0x50, mergedFlags))
    }
  }

  function optionalFlags(HooksDeploymentConfig flags) internal pure returns (HooksConfig config) {
    assembly {
      config := shl(0x50, and(flags, 0xffff))
    }
  }

  function requiredFlags(HooksDeploymentConfig flags) internal pure returns (HooksConfig config) {
    assembly {
      config := shl(0x40, and(flags, 0xffff0000))
    }
  }

  // ========================================================================== //
  //                              Parameter Readers                             //
  // ========================================================================== //

  function readFlag(HooksConfig hooks, uint256 bitsAfter) internal pure returns (bool flagged) {
    assembly {
      flagged := and(shr(bitsAfter, hooks), 1)
    }
  }

  function setFlag(
    HooksConfig hooks,
    uint256 bitsAfter
  ) internal pure returns (HooksConfig updatedHooks) {
    assembly {
      updatedHooks := or(hooks, shl(bitsAfter, 1))
    }
  }

  function clearFlag(
    HooksConfig hooks,
    uint256 bitsAfter
  ) internal pure returns (HooksConfig updatedHooks) {
    assembly {
      updatedHooks := and(hooks, not(shl(bitsAfter, 1)))
    }
  }

  /// @dev Address of the hooks contract
  function hooksAddress(HooksConfig hooks) internal pure returns (address _hooks) {
    assembly {
      _hooks := shr(96, hooks)
    }
  }

  /// @dev Whether to call hook contract for deposit
  function useOnDeposit(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_Deposit);
  }

  /// @dev Whether to call hook contract for queueWithdrawal
  function useOnQueueWithdrawal(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_QueueWithdrawal);
  }

  /// @dev Whether to call hook contract for executeWithdrawal
  function useOnExecuteWithdrawal(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_ExecuteWithdrawal);
  }

  /// @dev Whether to call hook contract for transfer
  function useOnTransfer(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_Transfer);
  }

  /// @dev Whether to call hook contract for borrow
  function useOnBorrow(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_Borrow);
  }

  /// @dev Whether to call hook contract for repay
  function useOnRepay(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_Repay);
  }

  /// @dev Whether to call hook contract for closeMarket
  function useOnCloseMarket(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_CloseMarket);
  }

  /// @dev Whether to call hook contract when account sanctioned
  function useOnNukeFromOrbit(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_NukeFromOrbit);
  }

  /// @dev Whether to call hook contract for setMaxTotalSupply
  function useOnSetMaxTotalSupply(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_SetMaxTotalSupply);
  }

  /// @dev Whether to call hook contract for setAnnualInterestAndReserveRatioBips
  function useOnSetAnnualInterestAndReserveRatioBips(
    HooksConfig hooks
  ) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_SetAnnualInterestAndReserveRatioBips);
  }

  /// @dev Whether to call hook contract for setProtocolFeeBips
  function useOnSetProtocolFeeBips(HooksConfig hooks) internal pure returns (bool) {
    return hooks.readFlag(Bit_Enabled_SetProtocolFeeBips);
  }

  // ========================================================================== //
  //                              Hook for deposit                              //
  // ========================================================================== //

  uint256 internal constant DepositCalldataSize = 0x24;
  // Size of lender + scaledAmount + state + extraData.offset + extraData.length
  uint256 internal constant DepositHook_Base_Size = 0x0244;
  uint256 internal constant DepositHook_ScaledAmount_Offset = 0x20;
  uint256 internal constant DepositHook_State_Offset = 0x40;
  uint256 internal constant DepositHook_ExtraData_Head_Offset = 0x200;
  uint256 internal constant DepositHook_ExtraData_Length_Offset = 0x0220;
  uint256 internal constant DepositHook_ExtraData_TailOffset = 0x0240;

  function onDeposit(
    HooksConfig self,
    address lender,
    uint256 scaledAmount,
    MarketState memory state
  ) internal {
    address target = self.hooksAddress();
    uint32 onDepositSelector = uint32(IHooks.onDeposit.selector);
    if (self.useOnDeposit()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), DepositCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onDeposit`
        mstore(cdPointer, onDepositSelector)
        // Write `lender` to hook calldata
        mstore(headPointer, lender)
        // Write `scaledAmount` to hook calldata
        mstore(add(headPointer, DepositHook_ScaledAmount_Offset), scaledAmount)
        // Copy market state to hook calldata
        mcopy(add(headPointer, DepositHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, DepositHook_ExtraData_Head_Offset),
          DepositHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, DepositHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, DepositHook_ExtraData_TailOffset),
          DepositCalldataSize,
          extraCalldataBytes
        )

        let size := add(DepositHook_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                          Hook for queueWithdrawal                          //
  // ========================================================================== //

  // Size of lender + scaledAmount + state + extraData.offset + extraData.length
  uint256 internal constant QueueWithdrawalHook_Base_Size = 0x0264;
  uint256 internal constant QueueWithdrawalHook_Expiry_Offset = 0x20;
  uint256 internal constant QueueWithdrawalHook_ScaledAmount_Offset = 0x40;
  uint256 internal constant QueueWithdrawalHook_State_Offset = 0x60;
  uint256 internal constant QueueWithdrawalHook_ExtraData_Head_Offset = 0x220;
  uint256 internal constant QueueWithdrawalHook_ExtraData_Length_Offset = 0x0240;
  uint256 internal constant QueueWithdrawalHook_ExtraData_TailOffset = 0x0260;

  function onQueueWithdrawal(
    HooksConfig self,
    address lender,
    uint32 expiry,
    uint256 scaledAmount,
    MarketState memory state,
    uint256 baseCalldataSize
  ) internal {
    address target = self.hooksAddress();
    uint32 onQueueWithdrawalSelector = uint32(IHooks.onQueueWithdrawal.selector);
    if (self.useOnQueueWithdrawal()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), baseCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onQueueWithdrawal`
        mstore(cdPointer, onQueueWithdrawalSelector)
        // Write `lender` to hook calldata
        mstore(headPointer, lender)
        // Write `expiry` to hook calldata
        mstore(add(headPointer, QueueWithdrawalHook_Expiry_Offset), expiry)
        // Write `scaledAmount` to hook calldata
        mstore(add(headPointer, QueueWithdrawalHook_ScaledAmount_Offset), scaledAmount)
        // Copy market state to hook calldata
        mcopy(add(headPointer, QueueWithdrawalHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, QueueWithdrawalHook_ExtraData_Head_Offset),
          QueueWithdrawalHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, QueueWithdrawalHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, QueueWithdrawalHook_ExtraData_TailOffset),
          baseCalldataSize,
          extraCalldataBytes
        )

        let size := add(QueueWithdrawalHook_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                         Hook for executeWithdrawal                         //
  // ========================================================================== //

  // Size of lender + scaledAmount + state + extraData.offset + extraData.length
  uint256 internal constant ExecuteWithdrawalHook_Base_Size = 0x0244;
  uint256 internal constant ExecuteWithdrawalHook_ScaledAmount_Offset = 0x20;
  uint256 internal constant ExecuteWithdrawalHook_State_Offset = 0x40;
  uint256 internal constant ExecuteWithdrawalHook_ExtraData_Head_Offset = 0x0200;
  uint256 internal constant ExecuteWithdrawalHook_ExtraData_Length_Offset = 0x0220;
  uint256 internal constant ExecuteWithdrawalHook_ExtraData_TailOffset = 0x0240;

  function onExecuteWithdrawal(
    HooksConfig self,
    address lender,
    uint256 scaledAmount,
    MarketState memory state,
    uint256 baseCalldataSize
  ) internal {
    address target = self.hooksAddress();
    uint32 onExecuteWithdrawalSelector = uint32(IHooks.onExecuteWithdrawal.selector);
    if (self.useOnExecuteWithdrawal()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), baseCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onExecuteWithdrawal`
        mstore(cdPointer, onExecuteWithdrawalSelector)
        // Write `lender` to hook calldata
        mstore(headPointer, lender)
        // Write `scaledAmount` to hook calldata
        mstore(add(headPointer, ExecuteWithdrawalHook_ScaledAmount_Offset), scaledAmount)
        // Copy market state to hook calldata
        mcopy(add(headPointer, ExecuteWithdrawalHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, ExecuteWithdrawalHook_ExtraData_Head_Offset),
          ExecuteWithdrawalHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, ExecuteWithdrawalHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, ExecuteWithdrawalHook_ExtraData_TailOffset),
          baseCalldataSize,
          extraCalldataBytes
        )

        let size := add(ExecuteWithdrawalHook_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                              Hook for transfer                             //
  // ========================================================================== //

  // Size of caller + from + to + scaledAmount + state + extraData.offset + extraData.length
  uint256 internal constant TransferHook_Base_Size = 0x0284;
  uint256 internal constant TransferHook_From_Offset = 0x20;
  uint256 internal constant TransferHook_To_Offset = 0x40;
  uint256 internal constant TransferHook_ScaledAmount_Offset = 0x60;
  uint256 internal constant TransferHook_State_Offset = 0x80;
  uint256 internal constant TransferHook_ExtraData_Head_Offset = 0x240;
  uint256 internal constant TransferHook_ExtraData_Length_Offset = 0x0260;
  uint256 internal constant TransferHook_ExtraData_TailOffset = 0x0280;

  function onTransfer(
    HooksConfig self,
    address from,
    address to,
    uint256 scaledAmount,
    MarketState memory state,
    uint256 baseCalldataSize
  ) internal {
    address target = self.hooksAddress();
    uint32 onTransferSelector = uint32(IHooks.onTransfer.selector);
    if (self.useOnTransfer()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), baseCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onTransfer`
        mstore(cdPointer, onTransferSelector)
        // Write `caller` to hook calldata
        mstore(headPointer, caller())
        // Write `from` to hook calldata
        mstore(add(headPointer, TransferHook_From_Offset), from)
        // Write `to` to hook calldata
        mstore(add(headPointer, TransferHook_To_Offset), to)
        // Write `scaledAmount` to hook calldata
        mstore(add(headPointer, TransferHook_ScaledAmount_Offset), scaledAmount)
        // Copy market state to hook calldata
        mcopy(add(headPointer, TransferHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, TransferHook_ExtraData_Head_Offset),
          TransferHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, TransferHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, TransferHook_ExtraData_TailOffset),
          baseCalldataSize,
          extraCalldataBytes
        )

        let size := add(TransferHook_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                               Hook for borrow                              //
  // ========================================================================== //

  uint256 internal constant BorrowCalldataSize = 0x24;
  // Size of normalizedAmount + state + extraData.offset + extraData.length
  uint256 internal constant BorrowHook_Base_Size = 0x0224;
  uint256 internal constant BorrowHook_State_Offset = 0x20;
  uint256 internal constant BorrowHook_ExtraData_Head_Offset = 0x01e0;
  uint256 internal constant BorrowHook_ExtraData_Length_Offset = 0x0200;
  uint256 internal constant BorrowHook_ExtraData_TailOffset = 0x0220;

  function onBorrow(HooksConfig self, uint256 normalizedAmount, MarketState memory state) internal {
    address target = self.hooksAddress();
    uint32 onBorrowSelector = uint32(IHooks.onBorrow.selector);
    if (self.useOnBorrow()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), BorrowCalldataSize)
        let ptr := mload(0x40)
        let headPointer := add(ptr, 0x20)

        mstore(ptr, onBorrowSelector)
        // Copy `normalizedAmount` to hook calldata
        mstore(headPointer, normalizedAmount)
        // Copy market state to hook calldata
        mcopy(add(headPointer, BorrowHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, BorrowHook_ExtraData_Head_Offset),
          BorrowHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, BorrowHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, BorrowHook_ExtraData_TailOffset),
          BorrowCalldataSize,
          extraCalldataBytes
        )

        let size := add(RepayHook_Base_Size, extraCalldataBytes)
        if iszero(call(gas(), target, 0, add(ptr, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                               Hook for repay                               //
  // ========================================================================== //

  // Size of normalizedAmount + state + extraData.offset + extraData.length
  uint256 internal constant RepayHook_Base_Size = 0x0224;
  uint256 internal constant RepayHook_State_Offset = 0x20;
  uint256 internal constant RepayHook_ExtraData_Head_Offset = 0x01e0;
  uint256 internal constant RepayHook_ExtraData_Length_Offset = 0x0200;
  uint256 internal constant RepayHook_ExtraData_TailOffset = 0x0220;

  function onRepay(
    HooksConfig self,
    uint256 normalizedAmount,
    MarketState memory state,
    uint256 baseCalldataSize
  ) internal {
    address target = self.hooksAddress();
    uint32 onRepaySelector = uint32(IHooks.onRepay.selector);
    if (self.useOnRepay()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), baseCalldataSize)
        let ptr := mload(0x40)
        let headPointer := add(ptr, 0x20)

        mstore(ptr, onRepaySelector)
        // Copy `normalizedAmount` to hook calldata
        mstore(headPointer, normalizedAmount)
        // Copy market state to hook calldata
        mcopy(add(headPointer, RepayHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(add(headPointer, RepayHook_ExtraData_Head_Offset), RepayHook_ExtraData_Length_Offset)
        // Write length for `extraData`
        mstore(add(headPointer, RepayHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, RepayHook_ExtraData_TailOffset),
          baseCalldataSize,
          extraCalldataBytes
        )

        let size := add(RepayHook_Base_Size, extraCalldataBytes)
        if iszero(call(gas(), target, 0, add(ptr, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                            Hook for closeMarket                            //
  // ========================================================================== //

  // Size of calldata to `market.closeMarket`
  uint256 internal constant CloseMarketCalldataSize = 0x04;

  // Base size of calldata for `hooks.onCloseMarket()`
  uint256 internal constant CloseMarketHook_Base_Size = 0x0204;
  uint256 internal constant CloseMarketHook_ExtraData_Head_Offset = MarketStateSize;
  uint256 internal constant CloseMarketHook_ExtraData_Length_Offset = 0x01e0;
  uint256 internal constant CloseMarketHook_ExtraData_TailOffset = 0x0200;

  function onCloseMarket(HooksConfig self, MarketState memory state) internal {
    address target = self.hooksAddress();
    uint32 onCloseMarketSelector = uint32(IHooks.onCloseMarket.selector);
    if (self.useOnCloseMarket()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), CloseMarketCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onCloseMarket`
        mstore(cdPointer, onCloseMarketSelector)
        // Copy market state to hook calldata
        mcopy(headPointer, state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, CloseMarketHook_ExtraData_Head_Offset),
          CloseMarketHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, CloseMarketHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, CloseMarketHook_ExtraData_TailOffset),
          CloseMarketCalldataSize,
          extraCalldataBytes
        )

        let size := add(CloseMarketHook_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                         Hook for setMaxTotalSupply                         //
  // ========================================================================== //

  uint256 internal constant SetMaxTotalSupplyCalldataSize = 0x24;
  // Size of maxTotalSupply + state + extraData.offset + extraData.length
  uint256 internal constant SetMaxTotalSupplyHook_Base_Size = 0x0224;
  uint256 internal constant SetMaxTotalSupplyHook_State_Offset = 0x20;
  uint256 internal constant SetMaxTotalSupplyHook_ExtraData_Head_Offset = 0x01e0;
  uint256 internal constant SetMaxTotalSupplyHook_ExtraData_Length_Offset = 0x0200;
  uint256 internal constant SetMaxTotalSupplyHook_ExtraData_TailOffset = 0x0220;

  function onSetMaxTotalSupply(
    HooksConfig self,
    uint256 maxTotalSupply,
    MarketState memory state
  ) internal {
    address target = self.hooksAddress();
    uint32 onSetMaxTotalSupplySelector = uint32(IHooks.onSetMaxTotalSupply.selector);
    if (self.useOnSetMaxTotalSupply()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), SetMaxTotalSupplyCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onSetMaxTotalSupply`
        mstore(cdPointer, onSetMaxTotalSupplySelector)
        // Write `maxTotalSupply` to hook calldata
        mstore(headPointer, maxTotalSupply)
        // Copy market state to hook calldata
        mcopy(add(headPointer, SetMaxTotalSupplyHook_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, SetMaxTotalSupplyHook_ExtraData_Head_Offset),
          SetMaxTotalSupplyHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, SetMaxTotalSupplyHook_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, SetMaxTotalSupplyHook_ExtraData_TailOffset),
          SetMaxTotalSupplyCalldataSize,
          extraCalldataBytes
        )

        let size := add(SetMaxTotalSupplyHook_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                       Hook for setAnnualInterestBips                       //
  // ========================================================================== //

  uint256 internal constant SetAnnualInterestAndReserveRatioBipsCalldataSize = 0x44;
  // Size of annualInterestBips + state + extraData.offset + extraData.length
  uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_Base_Size = 0x0244;
  uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ReserveRatioBits_Offset = 0x20;
  uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_State_Offset = 0x40;
  uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Head_Offset = 0x0200;
  uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Length_Offset =
    0x0220;
  uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ExtraData_TailOffset = 0x0240;

  function onSetAnnualInterestAndReserveRatioBips(
    HooksConfig self,
    uint16 annualInterestBips,
    uint16 reserveRatioBips,
    MarketState memory state
  ) internal returns (uint16 newAnnualInterestBips, uint16 newReserveRatioBips) {
    address target = self.hooksAddress();
    uint32 onSetAnnualInterestBipsSelector = uint32(
      IHooks.onSetAnnualInterestAndReserveRatioBips.selector
    );
    if (self.useOnSetAnnualInterestAndReserveRatioBips()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), SetAnnualInterestAndReserveRatioBipsCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onSetAnnualInterestBips`
        mstore(cdPointer, onSetAnnualInterestBipsSelector)
        // Write `annualInterestBips` to hook calldata
        mstore(headPointer, annualInterestBips)
        // Write `reserveRatioBips` to hook calldata
        mstore(
          add(headPointer, SetAnnualInterestAndReserveRatioBipsHook_ReserveRatioBits_Offset),
          reserveRatioBips
        )
        // Copy market state to hook calldata
        mcopy(
          add(headPointer, SetAnnualInterestAndReserveRatioBipsHook_State_Offset),
          state,
          MarketStateSize
        )
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Head_Offset),
          SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(
          add(headPointer, SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Length_Offset),
          extraCalldataBytes
        )
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, SetAnnualInterestAndReserveRatioBipsHook_ExtraData_TailOffset),
          SetAnnualInterestAndReserveRatioBipsCalldataSize,
          extraCalldataBytes
        )

        let size := add(SetAnnualInterestAndReserveRatioBipsHook_Base_Size, extraCalldataBytes)

        // Returndata is expected to have the new values for `annualInterestBips` and `reserveRatioBips`
        if or(
          lt(returndatasize(), 0x40),
          iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0x40))
        ) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }

        newAnnualInterestBips := and(mload(0), 0xffff)
        newReserveRatioBips := and(mload(0x20), 0xffff)
      }
    } else {
      (newAnnualInterestBips, newReserveRatioBips) = (annualInterestBips, reserveRatioBips);
    }
  }

  // ========================================================================== //
  //                     Hook for protocol fee bips updated                     //
  // ========================================================================== //

  uint256 internal constant SetProtocolFeeBipsCalldataSize = 0x24;
  // Size of protocolFeeBips + state + extraData.offset + extraData.length
  uint256 internal constant SetProtocolFeeBips_Base_Size = 0x0224;
  uint256 internal constant SetProtocolFeeBips_State_Offset = 0x20;
  uint256 internal constant SetProtocolFeeBips_ExtraData_Head_Offset = 0x01e0;
  uint256 internal constant SetProtocolFeeBips_ExtraData_Length_Offset = 0x0200;
  uint256 internal constant SetProtocolFeeBips_ExtraData_TailOffset = 0x0220;

  function onSetProtocolFeeBips(HooksConfig self, uint protocolFeeBips, MarketState memory state) internal {
    address target = self.hooksAddress();
    uint32 onSetProtocolFeeBipsSelector = uint32(IHooks.onSetProtocolFeeBips.selector);
    if (self.useOnSetProtocolFeeBips()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), SetProtocolFeeBipsCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onSetProtocolFeeBips`
        mstore(cdPointer, onSetProtocolFeeBipsSelector)
        // Write `protocolFeeBips` to hook calldata
        mstore(headPointer, protocolFeeBips)
        // Copy market state to hook calldata
        mcopy(add(headPointer, SetProtocolFeeBips_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, SetProtocolFeeBips_ExtraData_Head_Offset),
          SetProtocolFeeBips_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, SetProtocolFeeBips_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, SetProtocolFeeBips_ExtraData_TailOffset),
          SetProtocolFeeBipsCalldataSize,
          extraCalldataBytes
        )

        let size := add(SetProtocolFeeBips_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }

  // ========================================================================== //
  //                       Hook for assets sent to escrow                       //
  // ========================================================================== //

  uint256 internal constant NukeFromOrbitCalldataSize = 0x24;
  // Size of lender + state + extraData.offset + extraData.length
  uint256 internal constant NukeFromOrbit_Base_Size = 0x0224;
  uint256 internal constant NukeFromOrbit_State_Offset = 0x20;
  uint256 internal constant NukeFromOrbit_ExtraData_Head_Offset = 0x01e0;
  uint256 internal constant NukeFromOrbit_ExtraData_Length_Offset = 0x0200;
  uint256 internal constant NukeFromOrbit_ExtraData_TailOffset = 0x0220;

  function onNukeFromOrbit(HooksConfig self, address lender, MarketState memory state) internal {
    address target = self.hooksAddress();
    uint32 onNukeFromOrbitSelector = uint32(IHooks.onNukeFromOrbit.selector);
    if (self.useOnNukeFromOrbit()) {
      assembly {
        let extraCalldataBytes := sub(calldatasize(), NukeFromOrbitCalldataSize)
        let cdPointer := mload(0x40)
        let headPointer := add(cdPointer, 0x20)
        // Write selector for `onNukeFromOrbit`
        mstore(cdPointer, onNukeFromOrbitSelector)
        // Write `lender` to hook calldata
        mstore(headPointer, lender)
        // Copy market state to hook calldata
        mcopy(add(headPointer, NukeFromOrbit_State_Offset), state, MarketStateSize)
        // Write bytes offset for `extraData`
        mstore(
          add(headPointer, NukeFromOrbit_ExtraData_Head_Offset),
          NukeFromOrbit_ExtraData_Length_Offset
        )
        // Write length for `extraData`
        mstore(add(headPointer, NukeFromOrbit_ExtraData_Length_Offset), extraCalldataBytes)
        // Copy `extraData` from end of calldata to hook calldata
        calldatacopy(
          add(headPointer, NukeFromOrbit_ExtraData_TailOffset),
          NukeFromOrbitCalldataSize,
          extraCalldataBytes
        )

        let size := add(NukeFromOrbit_Base_Size, extraCalldataBytes)

        if iszero(call(gas(), target, 0, add(cdPointer, 0x1c), size, 0, 0)) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }
    }
  }
}
