# Wildcat Core Behavior

This section contains the most important aspects of how the Wildcat market operates.

Make sure you understand the [scale factor](./Scale%20Factor.md) before continuing.

## Market Configuration

Markets are configured with the following values:
- `asset` - The underlying asset for the market
- `name` - The name of the market (borrower-provided prefix + asset name)
- `symbol` - The symbol of the market (borrower-provided prefix + asset symbol)
- `borrower` - Address allowed to borrow from and make changes to the market
- `feeRecipient` - Recipient of protocol fees
- `sentinel` - Chainalysis wrapper determining whether accounts are sanctioned
- `maxTotalSupply` - The `totalSupply` at which the market will stop accepting withdrawals
- `protocolFeeBips` - A fraction of `annualInterestBips` which accrues to the protocol (in excess of the rate paid to lenders, not subtracted from it). This is not affected by delinquency fees.
- `annualInterestBips` - The base interest rate set by the borrower. Accrues solely to lenders.
- `delinquencyFeeBips` - Penalty fee added to the interest rate when the borrower is delinquent for too long. . Accrues solely to lenders.
- `withdrawalBatchDuration` - The length of a withdrawal cycle.
- `reserveRatioBips` - The fraction of outstanding debt which the borrower is obligated to keep in liquid reserves.
- `delinquencyGracePeriod` - The amount of time a borrower has before incurring penalties for a delinquent market.
- `archController` - Registry for factory/controller/market deployments.
- `sphereXEngine` - Engine for SphereX integration which does security checks on transactions.
- `hooks` - The market's hooks policy and the address of the hooks instance.

## Basic Market Behavior



### Collateral Obligation

Not all market tokens have the same collateral requirements attached. Tokens which are in pending withdrawals (current or unpaid expired batches) must be covered 100% by the borrower with underlying assets as soon as they enter a withdrawal batch, while tokens which are not pending withdrawal only need to be covered at the reserve ratio. We call the portion of the market's total supply which is not pending withdrawal the *outstanding supply*.

Aside from market tokens, there are two other contributors to the collateral obligation: unclaimed  protocol fees and unclaimed withdrawals. The latter are no longer associated with market tokens as they represent tokens that have already been paid for, burned and subtracted from the total supply; however, because lenders do not receive their withdrawals until they claim them via `executeWithdrawal`, the assets that have been set aside for withdrawals must remain in the market and so increase the collateral requirement for the market. This effectively just reduces the `totalAssets` the market sees as being available, as these assets do not cause the borrower to incur any additional interest payments or fees. See the [section on withdrawals](#withdrawals) for further details.

The total collateral obligation that a borrower is required to maintain in the market (`state.liquidityRequired()`) is the sum of:
- 100% of all pending (unpaid) withdrawals
- 100% of all unclaimed (paid) withdrawals
- reserve ratio times the outstanding supply
- accrued protocol fees

```solidity
state.normalizeAmount(state.scaledPendingWithdrawals)
+ state.normalizedUnclaimedWithdrawals
+ state.normalizeAmount(
    state.scaledTotalSupply - state.scaledPendingWithdrawals
).bipMul(state.reserveRatioBips)
+ state.accruedProtocolFees
```


#### Delinquency

Whenever a market has less total assets than its [minimum collateral obligation](#collateral-obligation), the borrower is considered delinquent (`state.isDelinquent`). For every second the borrower remains delinquent, a timer (`state.timeDelinquent`) increments. For every second the market is in a healthy state, the timer decrements.

For every second that the market spends with its delinquency timer above the grace period, the delinquency fee is applied to the interest rate.

This system results in the borrower being penalized for two seconds for every second they allow `timeDelinquent` to exceed the grace period: once on the way up while the market is delinquent, and once on the way down when the market is healthy.

### Interest rates

Borrowers pay interest based on three rates, all of which are denominated in annual bips (1 = 0.01%):
- `annualInterestBips` - The base interest rate set by the borrower. Accrues solely to lenders.
- `delinquencyFeeBips` - An additional fee added to the base interest rate whenever the borrower is in penalized delinquency. Accrues solely to lenders.
- `protocolFeeBips` - A fraction of `annualInterestBips` which accrues to the protocol (in excess of the rate paid to lenders, not extracted from it). This is not affected by delinquency fees.

Every state update, the sum of these rates is applied to the current `scaleFactor` (with the delinquency fee only being applied for the number of seconds the market was in penalized delinquency), compounding the market's interest.

### State Update

At the start of every stateful external function on a market which is the first such transaction in a block, a state update occurs to bring the market state up-to-date.

The basic state update sequence is:
1. Accrues the base interest rate and protocol fees, as well as the delinquency fee for any seconds since the last update during which the market was in [penalized delinquency](#delinquency)
2. Updates the delinquency timer, increasing if the previous state was delinquent and decreasing if it was not (to a minimum of zero).
3. Applies any available liquidity to the pending withdrawal batch if there is one.

If, at the start of the transaction, the current pending withdrawal batch has expired, the state update will be split into two iterations of the above sequence:
- The first will use the last update time as the start date and the withdrawal batch expiry as the end date, and it will handle [batch expiry](#withdrawal-expiry--priority) in the third step after reserving available liquidity.
    - This ensures that the borrower does not pay interest on withdrawals that can be retroactively paid off at the time of expiry.
- The second will use the expiry as the start date and the current time as the end date.

### Withdrawals

Withdrawal batches group together withdrawal requests from multiple lenders over a period of time (the `withdrawalBatchDuration` parameter) to ensure a fair distribution of available assets when a market is insufficiently liquid to fully honor all withdrawals in a batch.

When a lender requests a withdrawal, they will be entered into the current withdrawal batch if one exists; otherwise, a new one will be created. 

From the time a withdrawal batch is created until the time it expires, new lenders may enter the batch by creating a withdrawal request. At the time of the request, the lender is credited for the scaled token amount their withdrawal is equivalent to, giving them pro-rata ownership of the batch according to that scaled amount. These scaled tokens are removed from the lender's balance, but the total supply is [only reduced upon payment](#withdrawal-payment).

Withdrawal *execution*, or the claiming of paid withdrawals, is only possible after expiry. 

Withdrawal batches can be in one of three states:
- Current: The batch represented by `state.pendingWithdrawalExpiry`. Can be added to by lenders until it expires.
    - Note: The "current" batch can also be expired until the state update function is executed and converts it to an unpaid or paid batch.
- Unpaid: A batch which has expired without sufficient assets to cover all withdrawals.
- Paid: A batch which has been fully paid off.
    - Note: "paid off" means that assets are reserved and available for execution, not necessarily that all the withdrawals have been executed.

#### Withdrawal Expiry & Priority

If a batch expires without sufficient assets to cover all requests in it, it is moved into a first-in-first-out queue of "unpaid" batches. Earlier withdrawal batches receive priority over newer batches for payment, but lenders within the same batch have a pro-rata claim to the underlying assets allocated to it regardless of the order of their requests.

When a withdrawal batch expires, the liquidity which can immediately be reserved to pay it off is equal to the market's total assets minus the *unavailable* assets, which is the sum of:
- unclaimed (paid) withdrawals (`state.normalizedUnclaimedWithdrawals`)
- previous unpaid withdrawals (`state.scaledPendingWithdrawals - batch.scaledOwedAmount`)
- unclaimed protocol fees (`state.accruedProtocolFees`)

Note that while earlier batches receive priority, **this does not mean they always actually get paid first**. When a current batch expires, it can be fully paid off even if there are currently unpaid withdrawal batches in the queue, but only provided that the market has sufficient assets available to cover both. Once a batch is marked as unpaid, it can not have assets reserved for it until all previous unpaid batches are processed.

> Note: Skipping over unpaid batches is allowed for expiring batches because it is trivial to calculate the sum of previous withdrawals as the current batch expires, but doing so for a batch in the middle of the unpaid queue would be much more costly.

#### Withdrawal Payment

The scaled tokens associated with a withdrawal request are subtracted from a lender's balance immediately, but those tokens are not *burned* until they are honored, meaning they only stop accruing interest once underlying assets have been reserved to pay for them. The batch owns these scaled tokens and accrues their interest until they are burned by a payment, and the interest is distributed pro-rata to the lenders in the batch.

As assets become available, they can be paid to the withdrawal batch. A check for (and payment of) available assets occurs:
- when a lender adds a request to a batch,
- during the state update at the start of a transaction (for the current batch but not for unpaid (already expired) batches),
- upon a call to `repayAndProcessUnpaidWithdrawalBatches` (for unpaid batches).

Once an amount of underlying assets is paid to the batch, the corresponding scaled amount is actually burned: it is removed from the market's total supply, stops accruing interest and becomes available for withdrawal execution by lenders in the batch. These paid-for withdrawals are then moved into the pool of *unclaimed withdrawals* (`state.normalizedUnclaimedWithdrawals`) representing the amount of underlying assets that are still in the market but which can not be borrowed against and can not be counted toward the reserve ratio, protocol fees or new withdrawal payments.