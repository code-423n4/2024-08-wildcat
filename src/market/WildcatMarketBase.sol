// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import '../ReentrancyGuard.sol';
import '../spherex/SphereXProtectedRegisteredBase.sol';
import '../interfaces/IMarketEventsAndErrors.sol';
import '../interfaces/IERC20.sol';
import '../IHooksFactory.sol';
import '../libraries/FeeMath.sol';
import '../libraries/MarketErrors.sol';
import '../libraries/MarketEvents.sol';
import '../libraries/Withdrawal.sol';
import '../libraries/FunctionTypeCasts.sol';
import '../libraries/LibERC20.sol';
import '../types/HooksConfig.sol';

contract WildcatMarketBase is
  SphereXProtectedRegisteredBase,
  ReentrancyGuard,
  IMarketEventsAndErrors
{
  using SafeCastLib for uint256;
  using MathUtils for uint256;
  using FunctionTypeCasts for *;
  using LibERC20 for address;

  // ==================================================================== //
  //                       Market Config (immutable)                       //
  // ==================================================================== //

  /**
   * @dev Return the contract version string "2".
   */
  function version() external pure returns (string memory) {
    assembly {
      mstore(0x40, 0)
      mstore(0x41, 0x0132)
      mstore(0x20, 0x20)
      return(0x20, 0x60)
    }
  }

  HooksConfig public immutable hooks;

  /// @dev Account with blacklist control, used for blocking sanctioned addresses.
  address public immutable sentinel;

  /// @dev Account with authority to borrow assets from the market.
  address public immutable borrower;

  /// @dev Factory that deployed the market. Has the ability to update the protocol fee.
  address public immutable factory;

  /// @dev Account that receives protocol fees.
  address public immutable feeRecipient;

  /// @dev Penalty fee added to interest earned by lenders, does not affect protocol fee.
  uint public immutable delinquencyFeeBips;

  /// @dev Time after which delinquency incurs penalty fee.
  uint public immutable delinquencyGracePeriod;

  /// @dev Time before withdrawal batches are processed.
  uint public immutable withdrawalBatchDuration;

  /// @dev Token decimals (same as underlying asset).
  uint8 public immutable decimals;

  /// @dev Address of the underlying asset.
  address public immutable asset;

  bytes32 internal immutable PACKED_NAME_WORD_0;
  bytes32 internal immutable PACKED_NAME_WORD_1;
  bytes32 internal immutable PACKED_SYMBOL_WORD_0;
  bytes32 internal immutable PACKED_SYMBOL_WORD_1;

  function symbol() external view returns (string memory) {
    bytes32 symbolWord0 = PACKED_SYMBOL_WORD_0;
    bytes32 symbolWord1 = PACKED_SYMBOL_WORD_1;

    assembly {
      // The layout here is:
      // 0x00: Offset to the string
      // 0x20: Length of the string
      // 0x40: First word of the string
      // 0x60: Second word of the string
      // The first word of the string that is kept in immutable storage also contains the
      // length byte, meaning the total size limit of the string is 63 bytes.
      mstore(0, 0x20)
      mstore(0x20, 0)
      mstore(0x3f, symbolWord0)
      mstore(0x5f, symbolWord1)
      return(0, 0x80)
    }
  }

  function name() external view returns (string memory) {
    bytes32 nameWord0 = PACKED_NAME_WORD_0;
    bytes32 nameWord1 = PACKED_NAME_WORD_1;

    assembly {
      // The layout here is:
      // 0x00: Offset to the string
      // 0x20: Length of the string
      // 0x40: First word of the string
      // 0x60: Second word of the string
      // The first word of the string that is kept in immutable storage also contains the
      // length byte, meaning the total size limit of the string is 63 bytes.
      mstore(0, 0x20)
      mstore(0x20, 0)
      mstore(0x3f, nameWord0)
      mstore(0x5f, nameWord1)
      return(0, 0x80)
    }
  }

  /// @dev Returns immutable arch-controller address.
  function archController() external view returns (address) {
    return _archController;
  }

  // ===================================================================== //
  //                             Market State                               //
  // ===================================================================== //

  MarketState internal _state;

  mapping(address => Account) internal _accounts;

  WithdrawalData internal _withdrawalData;

  // ===================================================================== //
  //                             Constructor                               //
  // ===================================================================== //

  function _getMarketParameters() internal view returns (uint256 marketParametersPointer) {
    assembly {
      marketParametersPointer := mload(0x40)
      mstore(0x40, add(marketParametersPointer, 0x260))
      // Write the selector for IHooksFactory.getMarketParameters
      mstore(0x00, 0x04032dbb)
      // Call `getMarketParameters` and copy the returned struct to the allocated memory
      // buffer, reverting if the call fails or does not return the correct amount of bytes.
      // This overrides all the ABI decoding safety checks, as the call is always made to
      // the factory contract which will only ever return the prepared market parameters.
      if iszero(
        and(
          eq(returndatasize(), 0x260),
          staticcall(gas(), caller(), 0x1c, 0x04, marketParametersPointer, 0x260)
        )
      ) {
        revert(0, 0)
      }
    }
  }

  constructor() {
    factory = msg.sender;
    // Cast the function signature of `_getMarketParameters` to get a valid reference to
    // a `MarketParameters` object without creating a duplicate allocation or unnecessarily
    // zeroing out the memory buffer.
    MarketParameters memory parameters = _getMarketParameters.asReturnsMarketParameters()();

    // Set asset metadata
    asset = parameters.asset;
    decimals = parameters.decimals;

    PACKED_NAME_WORD_0 = parameters.packedNameWord0;
    PACKED_NAME_WORD_1 = parameters.packedNameWord1;
    PACKED_SYMBOL_WORD_0 = parameters.packedSymbolWord0;
    PACKED_SYMBOL_WORD_1 = parameters.packedSymbolWord1;

    {
      // Initialize the market state - all values in slots 1 and 2 of the struct are
      // initialized to zero, so they are skipped.

      uint maxTotalSupply = parameters.maxTotalSupply;
      uint reserveRatioBips = parameters.reserveRatioBips;
      uint annualInterestBips = parameters.annualInterestBips;
      uint protocolFeeBips = parameters.protocolFeeBips;

      assembly {
        // MarketState Slot 0 Storage Layout:
        // [15:31] | state.maxTotalSupply
        // [31:32] | state.isClosed = false

        let slot0 := shl(8, maxTotalSupply)
        sstore(_state.slot, slot0)

        // MarketState Slot 3 Storage Layout:
        // [4:8] | lastInterestAccruedTimestamp
        // [8:22] | scaleFactor = 1e27
        // [22:24] | reserveRatioBips
        // [24:26] | annualInterestBips
        // [26:28] | protocolFeeBips
        // [28:32] | timeDelinquent = 0

        let slot3 := or(
          or(or(shl(0xc0, timestamp()), shl(0x50, RAY)), shl(0x40, reserveRatioBips)),
          or(shl(0x30, annualInterestBips), shl(0x20, protocolFeeBips))
        )

        sstore(add(_state.slot, 3), slot3)
      }
    }

    hooks = parameters.hooks;
    sentinel = parameters.sentinel;
    borrower = parameters.borrower;
    feeRecipient = parameters.feeRecipient;
    delinquencyFeeBips = parameters.delinquencyFeeBips;
    delinquencyGracePeriod = parameters.delinquencyGracePeriod;
    withdrawalBatchDuration = parameters.withdrawalBatchDuration;
    _archController = parameters.archController;
    __SphereXProtectedRegisteredBase_init(parameters.sphereXEngine);
  }

  // ===================================================================== //
  //                              Modifiers                                //
  // ===================================================================== //

  modifier onlyBorrower() {
    address _borrower = borrower;
    assembly {
      // Equivalent to
      // if (msg.sender != borrower) revert NotApprovedBorrower();
      if xor(caller(), _borrower) {
        mstore(0, 0x02171e6a)
        revert(0x1c, 0x04)
      }
    }
    _;
  }

  // ===================================================================== //
  //                       Internal State Getters                          //
  // ===================================================================== //

  /**
   * @dev Retrieve an account from storage.
   *
   *      Reverts if account is sanctioned.
   */
  function _getAccount(address accountAddress) internal view returns (Account memory account) {
    account = _accounts[accountAddress];
    if (_isSanctioned(accountAddress)) revert_AccountBlocked();
  }

  /**
   * @dev Checks if `account` is flagged as a sanctioned entity by Chainalysis.
   *      If an account is flagged mistakenly, the borrower can override their
   *      status on the sentinel and allow them to interact with the market.
   */
  function _isSanctioned(address account) internal view returns (bool result) {
    address _borrower = borrower;
    address _sentinel = address(sentinel);
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(0, 0x06e74444)
      mstore(0x20, _borrower)
      mstore(0x40, account)
      // Call `sentinel.isSanctioned(borrower, account)` and revert if the call fails
      // or does not return 32 bytes.
      if iszero(
        and(eq(returndatasize(), 0x20), staticcall(gas(), _sentinel, 0x1c, 0x44, 0, 0x20))
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      result := mload(0)
      mstore(0x40, freeMemoryPointer)
    }
  }

  // ===================================================================== //
  //                       External State Getters                          //
  // ===================================================================== //

  /**
   * @dev Returns the amount of underlying assets the borrower is obligated
   *      to maintain in the market to avoid delinquency.
   */
  function coverageLiquidity() external view nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().liquidityRequired();
  }

  /**
   * @dev Returns the scale factor (in ray) used to convert scaled balances
   *      to normalized balances.
   */
  function scaleFactor() external view nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().scaleFactor;
  }

  /**
   * @dev Total balance in underlying asset.
   */
  function totalAssets() public view returns (uint256) {
    return asset.balanceOf(address(this));
  }

  /**
   * @dev Returns the amount of underlying assets the borrower is allowed
   *      to borrow.
   *
   *      This is the balance of underlying assets minus:
   *      - pending (unpaid) withdrawals
   *      - paid withdrawals
   *      - reserve ratio times the portion of the supply not pending withdrawal
   *      - protocol fees
   */
  function borrowableAssets() external view nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().borrowableAssets(totalAssets());
  }

  /**
   * @dev Returns the amount of protocol fees (in underlying asset amount)
   *      that have accrued and are pending withdrawal.
   */
  function accruedProtocolFees() external view nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().accruedProtocolFees;
  }

  function totalDebts() external view nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().totalDebts();
  }

  /**
   * @dev Returns the state of the market as of the last update.
   */
  function previousState() external view returns (MarketState memory) {
    MarketState memory state = _state;

    assembly {
      return(state, 0x1c0)
    }
  }

  /**
   * @dev Return the state the market would have at the current block after applying
   *      interest and fees accrued since the last update and processing the pending
   *      withdrawal batch if it is expired.
   */
  function currentState() external view nonReentrantView returns (MarketState memory state) {
    state = _calculateCurrentStatePointers.asReturnsMarketState()();
    assembly {
      return(state, 0x1c0)
    }
  }

  /**
   * @dev Call `_calculateCurrentState()` and return only the `state` parameter.
   *
   *      Casting the function type prevents a duplicate declaration of the MarketState
   *      return parameter, which would cause unnecessary zeroing and allocation of memory.
   *      With `viaIR` enabled, the cast is a noop.
   */
  function _calculateCurrentStatePointers() internal view returns (uint256 state) {
    (state, , ) = _calculateCurrentState.asReturnsPointers()();
  }

  /**
   * @dev Returns the scaled total supply the vaut would have at the current block
   *      after applying interest and fees accrued since the last update and burning
   *      market tokens for the pending withdrawal batch if it is expired.
   */
  function scaledTotalSupply() external view nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().scaledTotalSupply;
  }

  /**
   * @dev Returns the scaled balance of `account`
   */
  function scaledBalanceOf(address account) external view nonReentrantView returns (uint256) {
    return _accounts[account].scaledBalance;
  }

  /**
   * @dev Returns the amount of protocol fees that are currently
   *      withdrawable by the fee recipient.
   */
  function withdrawableProtocolFees() external view returns (uint128) {
    return
      _calculateCurrentStatePointers.asReturnsMarketState()().withdrawableProtocolFees(
        totalAssets()
      );
  }

  // /*//////////////////////////////////////////////////////////////
  //                     Internal State Handlers
  // //////////////////////////////////////////////////////////////*/

  function _blockAccount(MarketState memory state, address accountAddress) internal virtual {}

  /**
   * @dev Returns cached MarketState after accruing interest and delinquency / protocol fees
   *      and processing expired withdrawal batch, if any.
   *
   *      Used by functions that make additional changes to `state`.
   *
   *      NOTE: Returned `state` does not match `_state` if interest is accrued
   *            Calling function must update `_state` or revert.
   *
   * @return state Market state after interest is accrued.
   */
  function _getUpdatedState() internal returns (MarketState memory state) {
    state = _state;
    // Handle expired withdrawal batch
    if (state.hasPendingExpiredBatch()) {
      uint256 expiry = state.pendingWithdrawalExpiry;
      // Only accrue interest if time has passed since last update.
      // This will only be false if withdrawalBatchDuration is 0.
      uint32 lastInterestAccruedTimestamp = state.lastInterestAccruedTimestamp;
      if (expiry != lastInterestAccruedTimestamp) {
        (uint256 baseInterestRay, uint256 delinquencyFeeRay, uint256 protocolFee) = state
          .updateScaleFactorAndFees(
            delinquencyFeeBips,
            delinquencyGracePeriod,
            expiry
          );
        emit_InterestAndFeesAccrued(
          lastInterestAccruedTimestamp,
          expiry,
          state.scaleFactor,
          baseInterestRay,
          delinquencyFeeRay,
          protocolFee
        );
      }
      _processExpiredWithdrawalBatch(state);
    }
    uint32 lastInterestAccruedTimestamp = state.lastInterestAccruedTimestamp;
    // Apply interest and fees accrued since last update (expiry or previous tx)
    if (block.timestamp != lastInterestAccruedTimestamp) {
      (uint256 baseInterestRay, uint256 delinquencyFeeRay, uint256 protocolFee) = state
        .updateScaleFactorAndFees(
          delinquencyFeeBips,
          delinquencyGracePeriod,
          block.timestamp
        );
      emit_InterestAndFeesAccrued(
        lastInterestAccruedTimestamp,
        block.timestamp,
        state.scaleFactor,
        baseInterestRay,
        delinquencyFeeRay,
        protocolFee
      );
    }

    // If there is a pending withdrawal batch which is not fully paid off, set aside
    // up to the available liquidity for that batch.
    if (state.pendingWithdrawalExpiry != 0) {
      uint32 expiry = state.pendingWithdrawalExpiry;
      WithdrawalBatch memory batch = _withdrawalData.batches[expiry];
      if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
        // Burn as much of the withdrawal batch as possible with available liquidity.
        uint256 availableLiquidity = batch.availableLiquidityForPendingBatch(state, totalAssets());
        if (availableLiquidity > 0) {
          _applyWithdrawalBatchPayment(batch, state, expiry, availableLiquidity);
          _withdrawalData.batches[expiry] = batch;
        }
      }
    }
  }

  /**
   * @dev Calculate the current state, applying fees and interest accrued since
   *      the last state update as well as the effects of withdrawal batch expiry
   *      on the market state.
   *      Identical to _getUpdatedState() except it does not modify storage or
   *      or emit events.
   *      Returns expired batch data, if any, so queries against batches have
   *      access to the most recent data.
   */
  function _calculateCurrentState()
    internal
    view
    returns (
      MarketState memory state,
      uint32 pendingBatchExpiry,
      WithdrawalBatch memory pendingBatch
    )
  {
    state = _state;
    // Handle expired withdrawal batch
    if (state.hasPendingExpiredBatch()) {
      pendingBatchExpiry = state.pendingWithdrawalExpiry;
      // Only accrue interest if time has passed since last update.
      // This will only be false if withdrawalBatchDuration is 0.
      if (pendingBatchExpiry != state.lastInterestAccruedTimestamp) {
        state.updateScaleFactorAndFees(
          delinquencyFeeBips,
          delinquencyGracePeriod,
          pendingBatchExpiry
        );
      }

      pendingBatch = _withdrawalData.batches[pendingBatchExpiry];
      uint256 availableLiquidity = pendingBatch.availableLiquidityForPendingBatch(
        state,
        totalAssets()
      );
      if (availableLiquidity > 0) {
        _applyWithdrawalBatchPaymentView(pendingBatch, state, availableLiquidity);
      }
      state.pendingWithdrawalExpiry = 0;
    }

    if (state.lastInterestAccruedTimestamp != block.timestamp) {
      state.updateScaleFactorAndFees(
        delinquencyFeeBips,
        delinquencyGracePeriod,
        block.timestamp
      );
    }

    // If there is a pending withdrawal batch which is not fully paid off, set aside
    // up to the available liquidity for that batch.
    if (state.pendingWithdrawalExpiry != 0) {
      pendingBatchExpiry = state.pendingWithdrawalExpiry;
      pendingBatch = _withdrawalData.batches[pendingBatchExpiry];
      if (pendingBatch.scaledAmountBurned < pendingBatch.scaledTotalAmount) {
        // Burn as much of the withdrawal batch as possible with available liquidity.
        uint256 availableLiquidity = pendingBatch.availableLiquidityForPendingBatch(
          state,
          totalAssets()
        );
        if (availableLiquidity > 0) {
          _applyWithdrawalBatchPaymentView(pendingBatch, state, availableLiquidity);
        }
      }
    }
  }

  /**
   * @dev Writes the cached MarketState to storage and emits an event.
   *      Used at the end of all functions which modify `state`.
   */
  function _writeState(MarketState memory state) internal {
    bool isDelinquent = state.liquidityRequired() > totalAssets();
    state.isDelinquent = isDelinquent;

    {
      bool isClosed = state.isClosed;
      uint maxTotalSupply = state.maxTotalSupply;
      assembly {
        // Slot 0 Storage Layout:
        // [15:31] | state.maxTotalSupply
        // [31:32] | state.isClosed
        let slot0 := or(isClosed, shl(0x08, maxTotalSupply))
        sstore(_state.slot, slot0)
      }
    }
    {
      uint accruedProtocolFees = state.accruedProtocolFees;
      uint normalizedUnclaimedWithdrawals = state.normalizedUnclaimedWithdrawals;
      assembly {
        // Slot 1 Storage Layout:
        // [0:16] | state.normalizedUnclaimedWithdrawals
        // [16:32] | state.accruedProtocolFees
        let slot1 := or(accruedProtocolFees, shl(0x80, normalizedUnclaimedWithdrawals))
        sstore(add(_state.slot, 1), slot1)
      }
    }
    {
      uint scaledTotalSupply = state.scaledTotalSupply;
      uint scaledPendingWithdrawals = state.scaledPendingWithdrawals;
      uint pendingWithdrawalExpiry = state.pendingWithdrawalExpiry;
      assembly {
        // Slot 2 Storage Layout:
        // [1:2] | state.isDelinquent
        // [2:6] | state.pendingWithdrawalExpiry
        // [6:19] | state.scaledPendingWithdrawals
        // [19:32] | state.scaledTotalSupply
        let slot2 := or(
          or(
            or(shl(0xf0, isDelinquent), shl(0xd0, pendingWithdrawalExpiry)),
            shl(0x68, scaledPendingWithdrawals)
          ),
          scaledTotalSupply
        )
        sstore(add(_state.slot, 2), slot2)
      }
    }
    {
      uint timeDelinquent = state.timeDelinquent;
      uint protocolFeeBips = state.protocolFeeBips;
      uint annualInterestBips = state.annualInterestBips;
      uint reserveRatioBips = state.reserveRatioBips;
      uint scaleFactor = state.scaleFactor;
      uint lastInterestAccruedTimestamp = state.lastInterestAccruedTimestamp;
      assembly {
        // Slot 3 Storage Layout:
        // [4:8] | state.lastInterestAccruedTimestamp
        // [8:22] | state.scaleFactor
        // [22:24] | state.reserveRatioBips
        // [24:26] | state.annualInterestBips
        // [26:28] | protocolFeeBips
        // [28:32] | state.timeDelinquent
        let slot3 := or(
          or(
            or(
              or(shl(0xc0, lastInterestAccruedTimestamp), shl(0x50, scaleFactor)),
              shl(0x40, reserveRatioBips)
            ),
            or(
              shl(0x30, annualInterestBips),
              shl(0x20, protocolFeeBips)
            )
          ),
          timeDelinquent
        )
        sstore(add(_state.slot, 3), slot3)
      }
    }
    emit_StateUpdated(state.scaleFactor, isDelinquent);
  }

  /**
   * @dev Handles an expired withdrawal batch:
   *      - Retrieves the amount of underlying assets that can be used to pay for the batch.
   *      - If the amount is sufficient to pay the full amount owed to the batch, the batch
   *        is closed and the total withdrawal amount is reserved.
   *      - If the amount is insufficient to pay the full amount owed to the batch, the batch
   *        is recorded as an unpaid batch and the available assets are reserved.
   *      - The assets reserved for the batch are scaled by the current scale factor and that
   *        amount of scaled tokens is burned, ensuring borrowers do not continue paying interest
   *        on withdrawn assets.
   */
  function _processExpiredWithdrawalBatch(MarketState memory state) internal {
    uint32 expiry = state.pendingWithdrawalExpiry;
    WithdrawalBatch memory batch = _withdrawalData.batches[expiry];

    if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
      // Burn as much of the withdrawal batch as possible with available liquidity.
      uint256 availableLiquidity = batch.availableLiquidityForPendingBatch(state, totalAssets());
      if (availableLiquidity > 0) {
        _applyWithdrawalBatchPayment(batch, state, expiry, availableLiquidity);
      }
    }

    emit_WithdrawalBatchExpired(
      expiry,
      batch.scaledTotalAmount,
      batch.scaledAmountBurned,
      batch.normalizedAmountPaid
    );

    if (batch.scaledAmountBurned < batch.scaledTotalAmount) {
      _withdrawalData.unpaidBatches.push(expiry);
    } else {
      emit_WithdrawalBatchClosed(expiry);
    }

    state.pendingWithdrawalExpiry = 0;

    _withdrawalData.batches[expiry] = batch;
  }

  /**
   * @dev Process withdrawal payment, burning market tokens and reserving
   *      underlying assets so they are only available for withdrawals.
   */
  function _applyWithdrawalBatchPayment(
    WithdrawalBatch memory batch,
    MarketState memory state,
    uint32 expiry,
    uint256 availableLiquidity
  ) internal returns (uint104 scaledAmountBurned, uint128 normalizedAmountPaid) {
    uint104 scaledAmountOwed = batch.scaledTotalAmount - batch.scaledAmountBurned;

    // Do nothing if batch is already paid
    if (scaledAmountOwed == 0) return (0, 0);

    uint256 scaledAvailableLiquidity = state.scaleAmount(availableLiquidity);
    scaledAmountBurned = MathUtils.min(scaledAvailableLiquidity, scaledAmountOwed).toUint104();
    // Use mulDiv instead of normalizeAmount to round `normalizedAmountPaid` down, ensuring
    // it is always possible to finish withdrawal batches on closed markets.
    normalizedAmountPaid = MathUtils.mulDiv(scaledAmountBurned, state.scaleFactor, RAY).toUint128();

    batch.scaledAmountBurned += scaledAmountBurned;
    batch.normalizedAmountPaid += normalizedAmountPaid;
    state.scaledPendingWithdrawals -= scaledAmountBurned;

    // Update normalizedUnclaimedWithdrawals so the tokens are only accessible for withdrawals.
    state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

    // Burn market tokens to stop interest accrual upon withdrawal payment.
    state.scaledTotalSupply -= scaledAmountBurned;

    // Emit transfer for external trackers to indicate burn.
    emit_Transfer(address(this), _runtimeConstant(address(0)), normalizedAmountPaid);
    emit_WithdrawalBatchPayment(expiry, scaledAmountBurned, normalizedAmountPaid);
  }

  function _applyWithdrawalBatchPaymentView(
    WithdrawalBatch memory batch,
    MarketState memory state,
    uint256 availableLiquidity
  ) internal pure {
    uint104 scaledAmountOwed = batch.scaledTotalAmount - batch.scaledAmountBurned;
    // Do nothing if batch is already paid
    if (scaledAmountOwed == 0) return;

    uint256 scaledAvailableLiquidity = state.scaleAmount(availableLiquidity);
    uint104 scaledAmountBurned = MathUtils
      .min(scaledAvailableLiquidity, scaledAmountOwed)
      .toUint104();
    // Use mulDiv instead of normalizeAmount to round `normalizedAmountPaid` down, ensuring
    // it is always possible to finish withdrawal batches on closed markets.
    uint128 normalizedAmountPaid = MathUtils
      .mulDiv(scaledAmountBurned, state.scaleFactor, RAY)
      .toUint128();

    batch.scaledAmountBurned += scaledAmountBurned;
    batch.normalizedAmountPaid += normalizedAmountPaid;
    state.scaledPendingWithdrawals -= scaledAmountBurned;

    // Update normalizedUnclaimedWithdrawals so the tokens are only accessible for withdrawals.
    state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

    // Burn market tokens to stop interest accrual upon withdrawal payment.
    state.scaledTotalSupply -= scaledAmountBurned;
  }

  /**
   * @dev Function to obfuscate the fact that a value is constant from solc's optimizer.
   *      This prevents function specialization for calls with a constant input parameter,
   *      which usually has very little benefit in terms of gas savings but can
   *      drastically increase contract size.
   *
   *      The value returned will always match the input value outside of the constructor,
   *      fallback and receive functions.
   */
  function _runtimeConstant(
    uint256 actualConstant
  ) internal pure returns (uint256 runtimeConstant) {
    assembly {
      mstore(0, actualConstant)
      runtimeConstant := mload(iszero(calldatasize()))
    }
  }

  function _runtimeConstant(
    address actualConstant
  ) internal pure returns (address runtimeConstant) {
    assembly {
      mstore(0, actualConstant)
      runtimeConstant := mload(iszero(calldatasize()))
    }
  }

  function _isFlaggedByChainalysis(address account) internal view returns (bool isFlagged) {
    address sentinelAddress = address(sentinel);
    assembly {
      mstore(0, 0x95c09839)
      mstore(0x20, account)
      if iszero(
        and(eq(returndatasize(), 0x20), staticcall(gas(), sentinelAddress, 0x1c, 0x24, 0, 0x20))
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      isFlagged := mload(0)
    }
  }

  function _createEscrowForUnderlyingAsset(
    address accountAddress
  ) internal returns (address escrow) {
    address tokenAddress = address(asset);
    address borrowerAddress = borrower;
    address sentinelAddress = address(sentinel);

    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(0, 0xa1054f6b)
      mstore(0x20, borrowerAddress)
      mstore(0x40, accountAddress)
      mstore(0x60, tokenAddress)
      if iszero(
        and(eq(returndatasize(), 0x20), call(gas(), sentinelAddress, 0, 0x1c, 0x64, 0, 0x20))
      ) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      escrow := mload(0)
      mstore(0x40, freeMemoryPointer)
      mstore(0x60, 0)
    }
  }
}
