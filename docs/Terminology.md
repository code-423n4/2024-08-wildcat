---
description: It's dangerous to go alone - learn these.
---

# Terminology

#### **Archcontroller**

* Smart contract which doubles up as a registry and permission gate. [Borrowers](Terminology.md#borrower) are added or removed from the archcontroller by the operators of the protocol itself (granting/rescinding the ability to deploy [hooks](Terminology.md#hooks-instance) and/or [markets](Terminology.md#market)), and the addresses of any factories, market controllers or markets that get deployed through the protocol are stored here.

#### **Base APR**

* The interest rate that lenders receive on [assets](Terminology.md#underlying-asset) that they have deposited into a particular [market](Terminology.md#market), in the absence of the [penalty APR](Terminology.md#penalty-apr) being enforced.

#### **Borrow**

* To withdraw [assets](Terminology.md#underlying-asset) from a [market](Terminology.md#market) that has a non-zero [supply](Terminology.md#supply) and [reserve ratio](Terminology.md#reserve-ratio) less than 100%, with the intent of repaying the assets (plus any accrued interest) to the market either when the required purpose of using the assets has concluded or as a response to [withdrawal requests](Terminology.md#withdrawal-request).

#### **Borrower**

* Both:
  * The counterparty that wishes to make use of a credit facility through a Wildcat [market](Terminology.md#market), and
  * The blockchain address that defines the parameters of a market and deploys [hooks instances](Terminology.md#hooks_instance) and market contracts that use them.

#### **Capacity**

* Parameter required of [borrower](Terminology.md#borrower) when creating a new [market](Terminology.md#market).
* The `maxTotalSupply` field in the state.
* The _maximum_ amount of an asset that a borrower is looking to source via a market - the threshold for `totalSupply` after which the market will stop accepting deposits on.
* Can be exceeded by the market's `totalSupply` due to interest accrual.

#### **Claim**

* Removing [assets](Terminology.md#underlying-asset) from the [unclaimed withdrawals pool](Terminology.md#unclaimed-withdrawals-pool) that were requested for withdrawal by a [lender](Terminology.md#lender).
* Can only occur after a [withdrawal cycle](Terminology.md#withdrawal-cycle) expires.
* Note that retrieving [deposits](Terminology.md#deposit) from a Wildcat market requires a [withdrawal request](Terminology.md#withdrawal-request) and _then_ a claim - it is a two transaction process with the conclusion of one withdrawal cycle in between.

#### **Collateral Obligation**

* The minimum amount of [assets](Terminology.md#underlying-asset) that the borrower is obligated to keep in the market in order to avoid delinquency.
* Is the sum of:
  * The [reserves](Terminology.md#required-reserves) needed to meet the reserve ratio for the [outstanding supply](Terminology.md#outstanding-supply)
  * The market's [unclaimed withdrawals pool](Terminology.md#unclaimed-withdrawals-pool)
  * The normalized value of the market's [pending](Terminology.md#pending-withdrawal) and [expired](Terminology.md#expired-withdrawal) withdrawals
  * The unclaimed [protocol fees](Terminology.md#protocol-apr)

#### **Controller**

* Smart contract deployed by a [borrower](Terminology.md#borrower) which contains the list of addresses which are authorised to [deposit](Terminology.md#deposit) to any [markets](Terminology.md#market) deployed through it.
* Contains logic concerning parameters of markets deployed through it (e.g. maximum [grace period](Terminology.md#grace-period), minimum [penalty APR](Terminology.md#penalty-apr)).
* Controls APR adjustments and enforces [reserve ratios](Terminology.md#reserve-ratio) of markets.
* Imposes protocol fees (either lump-sum origination or APR-based) on markets.

#### **Delinquency**

* A [market](Terminology.md#market) state wherein there are insufficient [assets](Terminology.md#underlying-asset) in the market to meet the market's [collateral obligations](Terminology.md#collateral-obligation).
* Arises via the passage of time through interest if the borrower borrows right up to their reserve ratio.
* Can also arise if a [lender](Terminology.md#lender) makes a [withdrawal request](Terminology.md#withdrawal-request) that exceeds the market's [available liquidity](Terminology.md#liquid-reserves).
* A market being delinquent for an extended period of time (as specified by the [grace period](Terminology.md#grace-period)) results in the [penalty APR](Terminology.md#penalty-apr) being enforced in addition to the [base APR](Terminology.md#base-apr) and any [protocol APR](Terminology.md#protocol-apr) that may apply.
* 'Cured' by [depositing](Terminology.md#deposit) sufficient assets into the market as to reattain the required collateral obligation.

#### **Deposit**

* Both:
  * The act of sending [assets](Terminology.md#underlying-asset) as a [lender](Terminology.md#lender) to a [market](Terminology.md#market) for the purposes of being [borrowed](Terminology.md#borrow) by the [borrower](Terminology.md#borrower),
  * The act of sending assets as a borrower to a market for the purposes of being [withdrawn](Terminology.md#withdrawal-request) by lenders,
  * A term for the lenders' assets themselves once in a market.

#### **Escrow Contract**

* An auxiliary smart contract that is deployed in the event that the [sentinel](Terminology.md#sentinel) detects that a [lender](Terminology.md#lender) address has been added to a sanctioned list such as the OFAC SDN: this check is performed through the [**Chainalysis oracle**](https://go.chainalysis.com/chainalysis-oracle-docs.html).
* Used to transfer the debt (for the [lender](Terminology.md#lender)) and obligation to repay (for the [borrower](Terminology.md#borrower)) away from the [market](Terminology.md#market) contract to avoid wider contamination through interaction. Interest ceases to accrue upon creation and transfer.
* Any [assets](Terminology.md#underlying-asset) relating to an attempted claim by the affected lender as well as any market tokens tied to their remaining [deposit](Terminology.md#deposit) are automatically transferred to the escrow contract when blocked (either through an attempt to withdraw or via a call to a 'nuke from orbit' function found within the market).
* Assets can only be released to the lender in the event that a) they are no longer tagged as sanctioned by the Chainalysis oracle, or b) the borrower specifically overrides the sanction.

#### Expired Withdrawal

* A [withdrawal request](Terminology.md#withdrawal-request) that could not be fully honoured by [assets](Terminology.md#underlying-asset) in the [unclaimed withdrawals pool](Terminology.md#unclaimed-withdrawals-pool) within a single [withdrawal cycle](Terminology.md#withdrawal-cycle).

#### **Grace Period**

* Parameter required of [borrower](Terminology.md#borrower) when creating a new [market](Terminology.md#market).
* Rolling period of time for which a market can be [delinquent](Terminology.md#delinquency) before the [penalty APR](Terminology.md#penalty-apr) of the market activates.
* Note that the grace period does not 'reset' to zero when delinquency is cured. See [grace tracker](Terminology.md#grace-tracker) below for details.

#### **Grace Tracker**

* Internal [market](Terminology.md#market) parameter associated with the [grace period](Terminology.md#grace-period)
* `timeDelinquent` in the market state.
* Once a market becomes [delinquent](Terminology.md#delinquency), begins counting seconds up from zero - when the value of the grace tracker exceeds the grace period, the [penalty APR](Terminology.md#penalty-apr) activates.
* Once a market is cured of delinquency, begins counting seconds down to zero - the penalty APR continues to apply _until the grace tracker value is below the grace period value_.
* Enforces the rolling nature of the grace period.

#### **Hook**
* A function on a [hooks instance](Terminology.md#hooks-instance) which is executed when a particular action occurs on a [market](Terminology.md#market).
* Corresponds to a specific market action, such as the `onCloseMarket` hook which is called when `closeMarket` is called on a market.

#### **Hooks Instance**
* Contract that defines the [hook functions](Terminology.md#hook) for a market.
* Deployed by an approved borrower as an instance of a particular [hooks template](Terminology.md#hooks-template).
* Configured in the market parameters at market deployment.

#### **Hooks Template**
* A base contract defining behavior for a kind of [hooks contract](Terminology.md#hooks-instance) approved by the factory operators.
* Copied when borrowers deploy hooks instances.

#### **Lender**

* Both:
  * A counterparty that wishes to provide a credit facility through a Wildcat [market](Terminology.md#market), and
  * The blockchain address associated with that counterparty which [deposits](Terminology.md#deposit) [assets](Terminology.md#underlying-asset) to a market for the purposes of being [borrowed](Terminology.md#borrow) by the [borrower](Terminology.md#borrower).

#### **Liquid Reserves**

* The amount of [underlying assets](Terminology.md#underlying-asset) currently counting towards the market's [required reserves](Terminology.md#required-reserves).
* Comprises the liquidity that can be made available for new withdrawals.
* Is equal to the total assets in the market minus the [unclaimed withdrawals](Terminology.md#unclaimed-withdrawals-pool), [pending withdrawals](Terminology.md#pending-withdrawal), [expired withdrawals](Terminology.md#expired-withdrawal) and [accrued protocol fees](Terminology.md#protocol-apr).

#### **Market**

* Smart contract that accepts [underlying assets](Terminology.md#underlying-asset), issuing [market tokens](Terminology.md#market-token) in return.
* Deployed by [borrower](Terminology.md#borrower) through the factory.
* Holds assets in escrow pending either being [borrowed](Terminology.md#borrow) by the borrower or [withdrawn](Terminology.md#withdrawal-request) by a [lender](Terminology.md#lender).

#### **Market Token**

* ERC-20 token indicating a [claim](Terminology.md#claim) on the [underlying assets](Terminology.md#underlying-asset) in a [market](Terminology.md#market).
* Issued to [lenders](Terminology.md#lender) after a [deposit](Terminology.md#deposit).
* [Supply](Terminology.md#supply) rebases after every non-static call to the market contract depending on the total current APR of the market.
* Can only be redeemed by authorised lender addresses (not necessarily the same one that received the market tokens initially).
* Name and symbol prefixes are customisable in market creation, prepending to the name and symbol of the underlying asset.

#### **Outstanding Supply**

* The amount of market tokens not currently queued for withdrawal.
* Equal to the market's [supply](Terminology.md#supply) minus its [pending](Terminology.md#pending-withdrawal) and [expired](Terminology.md#expired-withdrawal) withdrawals.

#### **Penalty APR**

* Parameter required of [borrower](Terminology.md#borrower) when creating a new [market](Terminology.md#market).
* Additional interest rate (above and beyond the [base APR](Terminology.md#base-apr) and any [protocol APR](Terminology.md#protocol-apr) imposed by a market [controller](Terminology.md#controller)) that is applied for as long as the [grace tracker](Terminology.md#grace-tracker) value for a market is in excess of the specified [grace period](Terminology.md#grace-period).
* Encourages borrower to responsibly monitor the [reserve ratio](Terminology.md#reserve-ratio) of a market.
* No part of the penalty APR is receivable by the Wildcat protocol itself (does not inflate the protocol APR if present).

#### **Pending Withdrawal**

* A [withdrawal request](Terminology.md#withdrawal-request) that has not yet [expired](Terminology.md#expired-withdrawal) (i.e. was created in the current [withdrawal cycle](../technical-deep-dive/component-overview/wildcat-market-overview/wildcatmarketwithdrawals.sol.md#processunpaidwithdrawalbatch)).

#### **Protocol APR**

* Percentage of [base APR](Terminology.md#base-apr) that accrues to the Wildcat protocol itself.
* Parameter configured by the factory operator for each [hooks template](Terminology.md#hooks-template), applying to all [markets](Terminology.md#market) deployed with an instance of said template.
* Can be zero.
* Does not increase in the presence of an active [penalty APR](Terminology.md#penalty-apr) (which only increases the APR accruing to [lenders](Terminology.md#lender)).
* Example: market with base APR of 10% and protocol APR of 20% results in borrower paying 12% when penalty APR is not active.


#### **Required Reserves**

* Amount of [underlying assets](Terminology.md#underlying-asset) that must be made available for new withdrawals according to the configured [reserve ratio](Terminology.md#reserve-ratio).
* Equal to the reserve ratio times the [outstanding supply](Terminology.md#outstanding-supply)

#### **Reserve Ratio**

* Parameter required of [borrower](Terminology.md#borrower) when creating a new [market](Terminology.md#market).
* Percentage of current [outstanding supply](Terminology.md#outstanding-supply) that must be kept in the market (but still accrue interest).
* Intended to provide a [liquid buffer](Terminology.md#liquid-reserves) for [lenders](Terminology.md#lender) to make [withdrawal requests](Terminology.md#withdrawal-request) against, partially 'collateralising' the credit facility through lenders' deposits.
* Increases temporarily when a borrower reduces the [base APR](Terminology.md#base-apr) of a [market](Terminology.md#market) (fixed-term increase)
* A market which has insufficient assets in the market to meet the reserve ratio is said to be [delinquent](Terminology.md#delinquency), with the [penalty APR](Terminology.md#penalty-apr) potentially being enforced if the delinquency is not cured before the [grace tracker](Terminology.md#grace-tracker) value exceeds that of the [grace period](Terminology.md#grace-period) for that particular market.


#### **Sentinel**

* Smart contract that ensures that addresses which interact with the protocol are not flagged by the [**Chainalysis oracle**](https://go.chainalysis.com/chainalysis-oracle-docs.html) for sanctions.
* Can deploy escrow contracts to excise a [lender](Terminology.md#lender) flagged by the oracle from a wider [market](Terminology.md#market).

#### **Supply**

* Current amount of [underlying asset](Terminology.md#underlying-asset) [deposited](Terminology.md#deposit) in a [market](Terminology.md#market).
* Tied 1:1 with the supply of [market tokens](Terminology.md#market-token) (rate of growth APR dependent).
* Can only be reduced by burning market tokens as part of a [withdrawal request](Terminology.md#withdrawal-request) or [claim](Terminology.md#claim).
* [Reserve ratios](Terminology.md#reserve-ratio) are enforced against the supply of a market, _not_ its [capacity](Terminology.md#capacity).
* [Capacity](Terminology.md#capacity) can be reduced below current supply by a [borrower](Terminology.md#borrower), but this only prevents the further deposit of assets until the supply is once again below capacity.



#### **Unclaimed Withdrawals Pool**

* A sequestered pool of [underlying assets](Terminology.md#underlying-asset) which are pending their [claim](Terminology.md#claim) by [lenders](Terminology.md#lender) following a [withdrawal request](Terminology.md#withdrawal-request).
* Assets are moved from market reserves to the unclaimed withdrawals pool by burning [market tokens](Terminology.md#market-token) at a 1:1 ratio (reducing the [supply](Terminology.md#supply) of the market).
* Assets within the unclaimed withdrawals pool do not accrue interest, but similarly cannot be [borrowed](Terminology.md#borrow) by the [borrower](Terminology.md#borrower) - they are considered out of reach.

#### **Underlying Asset**

* Parameter required of [borrower](onboarding.md#borrowers) when creating a new [market](Terminology.md#market).
* The asset which the borrower is seeking to [borrow](Terminology.md#borrow) by deploying a market - for example DAI (Dai Stablecoin) or WETH (Wrapped Ether).
* Can be _any_ ERC-20 token.

#### **Vault**

* See [market](Terminology.md#market).
* If you see this term anywhere, it's a mistake that we should have cleared up!

#### **Withdrawal Cycle**

* Parameter required of [borrower](Terminology.md#borrower) when creating a new [market](Terminology.md#market).
* Period of time that must elapse between the first [withdrawal request](Terminology.md#withdrawal-request) of a 'wave' of withdrawals and [assets](Terminology.md#underlying-asset) in the [unclaimed withdrawals pool](Terminology.md#unclaimed-withdrawals-pool) being made available to [claim](Terminology.md#claim).
* Withdrawal cycles do not work on a rolling basis - at the end of one withdrawal cycle, the next cycle will not start until the next withdrawal request.
* In the event that the amount being claimed in the same cycle across all lenders is in excess of the reserves currently within a market, all [lenders](Terminology.md#lender) requests within that cycle will be honoured _pro rata_ depending on overall amount requested.
* Intended to prevent a run on a given market (mass withdrawal requests) leading to slower lenders receiving nothing.
* Can have a value of zero, in which case each withdrawal request is processed - and potentially added to the [withdrawal queue](Terminology.md#withdrawal-queue) - as a standalone batch.

#### **Withdrawal Queue**

* Internal data structure of a [market](Terminology.md#market).
* All [withdrawal requests](Terminology.md#withdrawal-request) that could not be fully honoured at the end of their [withdrawal cycle](Terminology.md#withdrawal-cycle) are batched together, marked as [expired](Terminology.md#expired-withdrawal) and added to the withdrawal queue.
* Tracks the order and amounts of [lender](Terminology.md#lender) [claims](Terminology.md#claim).
* FIFO (First-In-First-Out): when [assets](day-to-day-usage/lenders.md) are returned to a market which has a non-zero withdrawal queue, assets are immediately routed to the [unclaimed withdrawals pool](Terminology.md#unclaimed-withdrawals-pool) and can subsequently be claimed by lenders with the oldest expired withdrawals first.

#### Withdrawal Request

* An instruction to a [market](Terminology.md#market) to transfer reserves within a market to the [unclaimed withdrawals pool](Terminology.md#unclaimed-withdrawals-pool), to be [claimed](Terminology.md#claim) at the end of a [withdrawal cycle](Terminology.md#withdrawal-cycle).
* A withdrawal request made of a market with non-zero reserves will burn as many [market tokens](Terminology.md#market-token) as possible 1:1 to fully honour the request.
* Any amount requested - whether or not it is in excess of the market reserves - is marked as a [pending withdrawal](Terminology.md#pending-withdrawal), either to be fully honoured at the end of the cycle, or marked as [expired](Terminology.md#expired-withdrawal) and added to the [withdrawal queue](Terminology.md#withdrawal-queue), depending on the actions of the [borrower](Terminology.md#borrower) during the cycle.


