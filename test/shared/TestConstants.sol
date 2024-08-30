// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'src/interfaces/IChainalysisSanctionsList.sol';

address constant alice = address(0xa11ce);
address constant bob = address(0xb0b);
address constant feeRecipient = address(0xfee);
address constant borrower = address(0xb04405e4);

uint128 constant DefaultMaximumSupply = type(uint104).max;
uint16 constant DefaultInterest = 1000;
uint16 constant DefaultDelinquencyFee = 1000;
uint16 constant DefaultReserveRatio = 2000;
uint32 constant DefaultGracePeriod = 2000;
uint16 constant DefaultProtocolFeeBips = 1000;
uint32 constant DefaultWithdrawalBatchDuration = 86400;

uint32 constant MinimumDelinquencyGracePeriod = 0;
uint32 constant MaximumDelinquencyGracePeriod = 86_400;

uint16 constant MinimumReserveRatioBips = 1_000;
uint16 constant MaximumReserveRatioBips = 10_000;

uint16 constant MinimumDelinquencyFeeBips = 1_000;
uint16 constant MaximumDelinquencyFeeBips = 10_000;

uint32 constant MinimumWithdrawalBatchDuration = 0;
uint32 constant MaximumWithdrawalBatchDuration = 365 days;

uint16 constant MinimumAnnualInterestBips = 0;
uint16 constant MaximumAnnualInterestBips = 10_000;

uint16 constant MinimumProtocolFeeBips = 0;
uint16 constant MaximumProtocolFeeBips = 1_000;

IChainalysisSanctionsList constant SanctionsList = IChainalysisSanctionsList(
  0x40C57923924B5c5c5455c48D93317139ADDaC8fb
);