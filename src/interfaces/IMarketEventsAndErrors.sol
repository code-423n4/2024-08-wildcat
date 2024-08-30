// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import { MarketState } from '../libraries/MarketState.sol';

interface IMarketEventsAndErrors {
  /// @notice Error thrown when deposit exceeds maxTotalSupply
  error MaxSupplyExceeded();

  /// @notice Error thrown when non-borrower tries accessing borrower-only actions
  error NotApprovedBorrower();

  /// @notice Error thrown when non-approved lender tries lending to the market
  error NotApprovedLender();

  /// @notice Error thrown when caller other than factory tries changing protocol fee
  error NotFactory();

  /// @notice Error thrown when non-sentinel tries to use nukeFromOrbit
  error BadLaunchCode();

  /// @notice Error thrown when transfer target is blacklisted
  error AccountBlocked();

  error BadRescueAsset();

  error BorrowAmountTooHigh();

  error InsufficientReservesForFeeWithdrawal();

  error WithdrawalBatchNotExpired();

  error NullMintAmount();

  error NullBurnAmount();

  error NullFeeAmount();

  error NullTransferAmount();

  error NullWithdrawalAmount();

  error NullRepayAmount();

  error MarketAlreadyClosed();

  error DepositToClosedMarket();

  error RepayToClosedMarket();

  error BorrowWhileSanctioned();

  error BorrowFromClosedMarket();

  error AprChangeOnClosedMarket();

  error CapacityChangeOnClosedMarket();

  error ProtocolFeeChangeOnClosedMarket();

  error ProtocolFeeNotChanged();

  error CloseMarketWithUnpaidWithdrawals();

  error AnnualInterestBipsTooHigh();

  error ReserveRatioBipsTooHigh();

  error ProtocolFeeTooHigh();

  /// @dev Error thrown when reserve ratio is set to a value
  ///      that would make the market delinquent.
  error InsufficientReservesForNewLiquidityRatio();

  error InsufficientReservesForOldLiquidityRatio();

  error InvalidArrayLength();

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  event MaxTotalSupplyUpdated(uint256 assets);

  event ProtocolFeeBipsUpdated(uint256 protocolFeeBips);

  event AnnualInterestBipsUpdated(uint256 annualInterestBipsUpdated);

  event ReserveRatioBipsUpdated(uint256 reserveRatioBipsUpdated);

  event SanctionedAccountAssetsSentToEscrow(
    address indexed account,
    address escrow,
    uint256 amount
  );

  event SanctionedAccountAssetsQueuedForWithdrawal(
    address indexed account,
    uint256 expiry,
    uint256 scaledAmount,
    uint256 normalizedAmount
  );

  event Deposit(address indexed account, uint256 assetAmount, uint256 scaledAmount);

  event Borrow(uint256 assetAmount);

  event DebtRepaid(address indexed from, uint256 assetAmount);

  event MarketClosed(uint256 timestamp);

  event FeesCollected(uint256 assets);

  event StateUpdated(uint256 scaleFactor, bool isDelinquent);

  event InterestAndFeesAccrued(
    uint256 fromTimestamp,
    uint256 toTimestamp,
    uint256 scaleFactor,
    uint256 baseInterestRay,
    uint256 delinquencyFeeRay,
    uint256 protocolFees
  );

  event AccountSanctioned(address indexed account);

  // =====================================================================//
  //                          Withdrawl Events                            //
  // =====================================================================//

  event WithdrawalBatchExpired(
    uint256 indexed expiry,
    uint256 scaledTotalAmount,
    uint256 scaledAmountBurned,
    uint256 normalizedAmountPaid
  );

  /// @dev Emitted when a new withdrawal batch is created.
  event WithdrawalBatchCreated(uint256 indexed expiry);

  /// @dev Emitted when a withdrawal batch is paid off.
  event WithdrawalBatchClosed(uint256 indexed expiry);

  event WithdrawalBatchPayment(
    uint256 indexed expiry,
    uint256 scaledAmountBurned,
    uint256 normalizedAmountPaid
  );

  event WithdrawalQueued(
    uint256 indexed expiry,
    address indexed account,
    uint256 scaledAmount,
    uint256 normalizedAmount
  );

  event WithdrawalExecuted(
    uint256 indexed expiry,
    address indexed account,
    uint256 normalizedAmount
  );

  event SanctionedAccountWithdrawalSentToEscrow(
    address indexed account,
    address escrow,
    uint32 expiry,
    uint256 amount
  );
}