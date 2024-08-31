[](#the-elevator-pitch)

The Elevator Pitch

---

Wildcat is a protocol that allows borrowers to deploy massively configurable, unopinionated, hands-off un(der)collateralised on-chain credit rails. That's it. Wildcat borrowers can dictate the terms of almost any parameter that they would care to adjust when crafting their credit line:

- underlying asset,
- interest rate,
- maximum capacity,
- penalties,
- withdrawal cycle lengths, and so on.

Markets can also impose various access constraints that they may require:

- disabling withdrawals for a certain period (corresponding to a fixed-duration agreement),
- disabling transfers for the tokenised debt that Wildcat issues,
- enforcing minimum deposit amounts to prevent dust from accumulating,
- requiring lenders to prove compliance with a given profile before self-onboarding, etc.

Wildcat markets are not controlled or upgradable by the protocol itself once deployed. A market and its goings-on are between the borrowers and lenders alone. Wildcat itself doesn't liquidate collateral, can't freeze markets, and can't access your funds.

Wildcat provides a template loan agreement between borrower and lender on a per-market basis, but you are free to decline to use this, or borrowers can opt to use their own.

Wildcat exists to create credit systems _by you_, _for you_.

---

###

[](#undefined)

​A Comment Before You Head Further In

This documentation is currently undergoing revision as the protocol shifts towards the deployment of V2 and the deprecation of V1. There may be some inconsistencies, which we are seeking out.

There is some repetition of terms and definitions in various sections.

There is some repetition of terms and definitions in various sections.

There is some repetition of terms and definitions in various sections.

You aren't going insane: this is intentional, as we don't want (or expect) people to have to read through the entire site in order to understand the section that they're interested in.

After the V2 launch, we will be fleshing various pages out more screenshots, illustrations, videos and so forth to help explain more concepts more clearly - waves of text can be difficult to parse, and we're walking a tightrope between explaining the protocol to would-be users and also acting as a source of truth for security researchers and developers who would make use of or extend our code.

Please forgive any arcane ramblings: if there's anything you'd like to see expanded upon or clarified further, we'd consider it a favour if you got in touch with us.

​​

[PreviousThe Wildcat Protocol](/)
[NextWhat Wildcat Enables](/overview/what-wildcat-enables)

Last updated 2 days ago

We do not expect this to happen to any users of the protocol, but we have accounted for the potential that a lender address is added to a national sanctions list such as the OFAC SDN in a repeat of the Tornado Cash incident of August 2022.

The strict liability nature of transfers to and from addresses that have been tagged in such a manner means that we need to account for the potential for them to poison a entire market.

Here's how we've handled it:

###

[](#lender-gets-sanctioned)

Lender Gets Sanctioned

In the event that a lender address is sanctioned, the sentinel contract can deploy escrow contracts between the borrower of a market and the lender in question.

Within each market contract itself, a `nukeFromOrbit` function exists that creates an escrow contract, transfers the market balance corresponding to the lender from the market to the escrow, erases the lenders market token balance, and blocks them from any further interaction with the market itself.

A second escrow contract is also created if a lender attempts to execute a withdrawal (i.e. claim) from a market while sanctioned - in this case, the assets within the unclaimed withdrawals pool that would have been claimable by the lender are similarly sent to that new escrow.

**NOTE**: T*his means that potentially two escrow contracts can be created for a single lender - one for their market token balance, and one for any assets that they were trying to withdraw!*

Assets within an escrow contract can be released to the lender via the `releaseEscrow` function in one of two cases:

- The lender address is no longer flagged as being sanctioned by the Chainalysis oracle, or
- The borrower involved in that particular escrow contract specifically overrides the sanction status via the `overrideSanction` function.

It's worth observing that any underlying assets that are within a market which cannot be redeemed by a sanctioned lender are still available for the borrower to utilise - market tokens being spirited away into an escrow contract do not impose any freezes on the underlying assets themselves. Of course, any underlying assets that were seized as part of an `executeWithdrawal` call by a sanctioned lender are out of the reach of both the borrower and the lender, as they are no longer part of the market.

Note that this power cannot be randomly used to erase lenders from markets: the Chainalysis oracle **must** return `true` when asked if the lender address is sanctioned in order for the escrow contract to be created.

We do not believe that Wildcat protocol users are at risk of a simultaneous exploit of the Chainalysis oracle and excision from a market as a result - in fact we do not _expect_ `nukeFromOrbit` to ever actually be _called_ - but better to be prepared.

###

[](#borrower-gets-sanctioned)

Borrower Gets Sanctioned

In the event that the _borrower_ of a market is added to the Chainalysis oracle, any markets that they have deployed are immediately considered irreparably poisoned: _all_ lenders will be affected by strict liability if they withdraw assets after the borrower deposits any back to the market after this point.

If this happens, the archcontroller is likely to sever the market - this means that while it will still operate normally, it will no longer show up on the UI (which queries the archcontroller for a list of which markets to display), and escrow contracts cannot be created for it.

You're going to want to speak to a lawyer in your jurisdiction if you're a lender to a market where this happens.

[PreviousMarket Access Via Policies/Hooks](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)
[NextProtocol Usage Fees](/using-wildcat/protocol-usage-fees)

Last updated 1 day ago

The Wildcat protocol contracts have been subjected to independent security reviews and crowdsourced review via Code4rena.

The results of these reviews (and associated reports) are available here:

[](#wildcat-v2-reviews)

Wildcat V2 Reviews

---

###

[](#alpeh_v-independent-security-review)

[alpeh_v](https://x.com/alpeh_v)
\[Independent Security Review\]

**Date**: 12 - 23rd August 2024

**Scope**: Entire protocol

**LOC**: ~4,700

**Results**:

- 2 medium
- 2 low
- 2 notes

**Report**: [https://hackmd.io/@geistermeister/BJk4Ekt90](https://hackmd.io/@geistermeister/BJk4Ekt90)

###

[](#code4rena-competitive-public-audit)

[Code4rena](https://code4rena.com/)
\[Competitive Public Audit\]

**Date**: 31 August - 18 September 2024

**Scope**: See README/Scope [here](https://github.com/code-423n4/2024-08-wildcat/tree/main?tab=readme-ov-file#scope)
.

**LOC**: 3,784

**Results**:

- Contest ongoing: [https://code4rena.com/audits/2024-08-the-wildcat-protocol](https://code4rena.com/audits/2024-08-the-wildcat-protocol)

**Report**: Pending

---

[](#wildcat-v1-reviews)

Wildcat V1 Reviews

---

###

[](#alpeh_v-independent-security-review-1)

[alpeh_v](https://x.com/alpeh_v)
\[Independent Security Review\]

**Date**: 13 - 29th September 2023

**Scope**: `src/markets/*`, `src/libraries/*`, `src/ReentrancyGuard.sol`

**LOC**: ~1,500

**Results**:

- 1 critical
- 2 high
- 4 medium
- 2 low
- Various notes

**Report**: [https://hackmd.io/@geistermeister/r15gj_y1p](https://hackmd.io/@geistermeister/r15gj_y1p)

###

[](#code4rena-competitive-audit)

[Code4rena](https://code4rena.com/)
\[Competitive Audit\]

**Date**: 16 - 25th October 2023

**Scope**: Everything except `src/interfaces/*`

**LOC**: 2,332

**Results**:

- 6 high
- 11 medium

**Report**: [https://code4rena.com/contests/2023-10-the-wildcat-protocol](https://code4rena.com/contests/2023-10-the-wildcat-protocol)

[PreviousContract Deployments](/technical-overview/contract-deployments)
[NextSphereX Protection](/security-measures/spherex-protection)

Last updated 5 hours ago

We get a lot of questions about the scaling mechanics and want to be thorough, but here's the condensed version:

- Wildcat markets have _scaled token amounts_ and _market token amounts_, where scaled tokens represent shares in the market that only change upon deposit or withdrawal, and market tokens represent debt owed by the borrower in units of the base asset.
- The _scale factor_ is the ratio between scaled and market token amounts. 1 wTKN is worth `1 * scaleFactor` TKN.
- The scale factor constantly grows with interest, causing the market token to rebase as debt accrues.
- All the standard market functions (`balanceOf`, `totalSupply`, `transfer`, `deposit`, `withdraw`, etc.) use _market token amounts_.
- The scaled query functions (`scaledBalanceOf`, `scaledTotalSupply`) return _scaled token amounts_, equivalent to market shares.

[](#relevant-code)

Relevant Code

---

In Wildcat, the scale factor is stored as a ray value, meaning it has a base unit of 1e27, so 1.1e27 is 1.1.

The [MathUtils](https://github.com/wildcat-finance/v2-protocol/blob/src/libraries/MathUtils.sol)
library contains the math functions for dividing/multiplying ray values.

[](#scaled-tokens)

Scaled Tokens

---

A key component of the Wildcat contracts is the scale factor and scaled token amounts - it's crucial to all of the protocol's behavior and should be understood before diving into the codebase. If you're already familiar with Aave, our scaling works the same way as aTokens, so you can skip this page; otherwise, there are a few ways to think of scaling, but the best is probably by analogy to token vaults.

###

[](#typical-token-vaults)

Typical Token Vaults

Suppose we have an [ERC4626](https://eips.ethereum.org/EIPS/eip-4626#methods)
vault called VUSDC which holds USDC. The vault is itself a token where 1 VUSDC is 1 share of ownership in the USDC held by the vault. The vault has 100 shares (`VUSDC.totalSupply() = 100`) and holds 200 USDC (`VUSDC.totalAssets() = 200`), so every 1 VUSDC is convertible to 2 USDC.

Alice owns 10 VUSDC `VUSDC.balanceOf(alice) = 10`. To get the amount of USDC her shares can be converted to, we'd call `VUSDC.convertToAssets(10) = 20`. If the vault receives another 100 USDC, Alice still has 10 shares, but now `convertToAssets(10)` will return 30, because the ratio of USDC to VUSDC has increased by 50%.

So in a typical vault, you have shares which are your balance in the vault and you have assets which your shares are convertible to, where the "assets" are always the actual assets held by the vault at a given point in time (or the convertible value of assets held by the vault, if they're wrapped in a secondary token). Pretty simple.

###

[](#wildcat-markets)

Wildcat Markets

Wildcat's scaling mechanism works in a similar way, except that Wildcat market tokens represent the _value_ of shares rather than the _number_ of shares, and Wildcat markets constantly rebase with interest.

####

[](#scaled-token-amounts)

**Scaled Token Amounts**

The first important distinction is that in Wildcat markets, _market tokens_ (the values reported when using the ERC20 functions `balanceOf`, `totalSupply` on a market) represent the _value_ of shares rather than the number of shares, and _scaled tokens_ represent the number of shares.

We also refer to market token amounts as "normalized" amounts, as they have been converted to units that always relate 1:1 to amounts of underlying assets.

Using numbers from the previous example and swapping VUSDC for WUSDC, when the market has 100 shares and 200 USDC:

Alice has 10 out of 100 scaled tokens (shares):

Copy

    WUSDC.scaledBalanceOf(alice) = 10
    WUSDC.scaledTotalSupply() = 100

But she has 20 out of 200 normalized tokens (asset value):

Copy

    WUSDC.balanceOf(alice) = 20
    WUSDC.totalSupply() = 200

> Notice that so far, `WUSDC.balanceOf(alice)` for a Wildcat market is equivalent to `VUSDC.convertToAssets(VUSDC.balanceOf(account))` for an ERC4626.

####

[](#rebasing-with-interest)

**Rebasing With Interest**

The second important distinction is that Wildcat markets constantly rebase with interest, and markets do not always hold all of the assets that shares are worth.

An ERC4626 would typically hold all of its underlying assets in some liquid form, meaning Alice can always burn her 1 VUSDC and immediately receive 2 USDC back. `VUSDC.totalAssets()` will always report the amount of USDC that the vault is worth, and that is always equivalent to the amount of USDC that it has immediate access to (for the sake of this comparison). `ERC4626.convertToAssets(shares)` is just `shares * totalAssets / totalShares`.

Wildcat markets are uncollateralised lending markets, which adds two other factors to this equation:

- Interest is always accruing from the borrower. 1 WUSDC in block `n` is worth more than 1 WUSDC in block `n - 1`, even though the market contract has not received any more USDC.
- The market may not always have the assets that shares are worth in a liquid form, both because the underlying assets can be borrowed and because the constant interest accrual is always increasing the borrower's debt. This makes `totalAssets` useless for determining the value of 1 WUSDC.

The way this is handled is with the `scaleFactor` - the ratio between the number of shares and the amount of underlying assets that shares are worth (but not necessarily instantly redeemable for). Every time the market is updated for the first time in a block, the scale factor is multiplied by the amount of interest that has accrued since the last update (Wildcat interest rates are auto-compounding).

To mint market tokens, lenders use the deposit function, which takes a normalized (underlying) token amount that the lender wants to transfer. This is divided by the `scaleFactor`, yielding the number of scaled tokens / shares they have minted.

Similarly, when a lender withdraws an amount of their market tokens, they must burn `scaledAmountToBurn = normalizedAmount / scaleFactor`.

The result of all of this is that the market token represents _the amount of debt owed by the borrower at a given point in time_, and is thus a measure of an eventual amount of underlying tokens assuming the borrower repays their debts. It does not measure the shares owned by an account or the amount of underlying assets those shares are instantly redeemable for.

Just to reiterate the terminology here:

- The scale factor is the ratio of debt owed by the borrower to shares in the market. If the scaleFactor is 2, 1 scaled token equals 2 market tokens.
- "Normalized amount" is any amount denominated in units of the base asset (e.g. USDC). All market functions that use token amounts (other than `scaledBalanceOf, scaledTotalSupply`) use normalized amounts.
- "Market tokens" are normalized amounts of scaled tokens, and represent the underlying assets the borrower is obligated to eventually repay
- `scaleAmount(x)` divides a normalized amount `x` by the scale factor
- `normalizeAmount(x)` multiplies a scaled amount `x` by the scale factor

[](#basic-example)

**Basic Example**

---

1.  Bob deposits 100 TKN into the Wildcat market wTKN which has an annual interest rate of 10% as soon as the market is created (T1):

    - scaleFactor = 1
    - scaledBalanceOf(bob) = 100
    - balanceOf(bob) = scaledBalanceOf(bob) \* scaleFactor = 100
    - scaledTotalSupply = 100
    - totalSupply = (scaledTotalSupply \* scaleFactor) = 100

2.  We update the market after half a year (T2):

    - scaleFactor = previousScaleFactor \_ (1 + APR \_ timeElapsed / oneYear) = 1.05
    - scaledBalanceOf(bob) = 100
    - balanceOf(bob) = scaledBalanceOf(bob) \* scaleFactor = 105
    - scaledTotalSupply = 100
    - totalSupply = (scaledTotalSupply \* scaleFactor) = 105

3.  In the same block, Alice deposits 210 TKN (T3):

    - scaleFactor = 1.05
    - scaledBalanceOf(bob) = 100
    - balanceOf(bob) = 105
    - scaledBalanceOf(alice) = deposit / scaleFactor = 210 / 1.05 = 200
    - balanceOf(alice) = scaledBalanceOf(alice) \* scaleFactor = 210
    - scaledTotalSupply = 300
    - totalSupply = (scaledTotalSupply \* scaleFactor) = 315

4.  After another half a year, we update the market again (T4):

    - scaleFactor = previousScaleFactor \_ (1 + APR \_ timeElapsed / oneYear) = 1.1025
    - scaledBalanceOf(bob) = 100
    - balanceOf(bob) = scaledBalanceOf(bob) \* scaleFactor = 110.25
    - scaledBalanceOf(alice) = 200
    - balanceOf(alice) = scaledBalanceOf(alice) \* scaleFactor = 220.50
    - scaledTotalSupply = 300
    - totalSupply = (scaledTotalSupply \* scaleFactor) = 330.75

[PreviousSecurity/Developer Dives](/technical-overview/security-developer-dives)
[NextCore Behaviour](/technical-overview/security-developer-dives/core-behaviour)

Last updated 9 days ago

The core premise of a Wildcat market is simple: enabling undercollateralised borrowing and lending.

You will have seen this use-case before, associated with other protocols. What's different here is the amount of freedom the borrower has in how their market is shaped and constrained, alongside a novel mechanism for scheduling redemptions on behalf of lenders. Borrowers are responsible for maintaining the health of their markets, but this comes with substantial power to dictate their terms. Conversely, Wildcat is designed so that lenders both know where they stand and can deploy capital in places that they perhaps did not expect.

###

[](#for-borrowers)

For Borrowers

A borrower may wish to create a completely uncollateralised market to borrow 4,000,000 USDC paying 15% to lenders that deposit into it, where they have seven days to repay any withdrawal request they receive before an additional penalty rate of 10% kicks in. They may also wish to set it up such that lenders cannot withdraw for the first six months that the market exists (thereafter switching to open-term), that they must deposit at least 100,000 USDC per transaction and they must provide a ZK proof that they have passed a third-party KYC check confirming they are not resident in the United States. The debt tokens issued by the resulting market can either be freely tradable, constrained to other approved lenders, or completely locked down.

Wildcat enables this and much more, depending on the selected market configuration, which is presented in an easy-to-understand user interface.

If you have admin costs associated with middle and back-office functionality because you're handling loans OTC via Telegram or the like, you're probably going to find using a Wildcat market useful, since you can track everything using associated events and other features provided through the protocol UI.

If you're trying to raise funds for operational purposes (i.e. you're a legal entity associated with a DAO that wants to pay salaries without selling a native token OTC or into on-chain liquidity to do so), a Wildcat market may prove convenient to you as well.

In crypto/DeFi we often speak at length about how one of the remaining holy grails is an effective reputation/credit risk metric tied to on-chain wallets. However, this suffers from a cold start problem: it's hard to infer any meaningful information when previous wallet interactions _typically_ involve overcollateralised mechanisms or those which offer no real insight into probability of default. We consider honest usage of Wildcat by borrowers an effective bootstrap mechanism upon which such reputations can be built.

###

[](#for-lenders)

For Lenders

From the lender perspective, the goal of Wildcat is to open up a number of competitive avenues for you to deploy capital: it may not have even dawned on you that some of the borrowers making use of Wildcat would be willing to accept your funds!

Wildcat provides you with a way to direct credit towards a specific counterparty that you may know and trust, rather than into a pool which is distributed across several borrowers.

Wildcat also makes use of fixed rates, which - while adjustable in circumstances where you can ragequit if the rate is no longer to your liking or you reckon you can get better rates elsewhere - provides a measure of certainty, compared to systems using dynamic rates wherein a borrower can drop your APR significantly simply by repaying a large chunk of their debt.

Wildcat V2 enables borrowers to set up structures such as Masterchef contracts on top of their markets: a borrower may offer you a given rate of interest, but also stream additional tokens to you as an additional incentive for you to provide credit. We can easily envisage this being used as a liquidity mining mechanism of sorts, should it be opted for.

Finally, Wildcat has drawn up and open-sourced a Master Loan Agreement that is cognisant of the fact that your engagement is in fact a credit agreement taking place on-chain between yourself and the borrower. We encourage lenders to make use of it if the borrower has opted to make use of it.

**Put simply, with Wildcat, you know what you're getting.**

Now, a bit that we need to include here so that we don't accidentally taunt a regulator:

Wildcat does not provide any assurances or underwriting regarding the financial health or creditworthiness of a borrower. Markets will - in the fullness of time - include reference to external reports or dashboards attesting to liquid assets where they exist, but lenders are expected to exercise their judgment as to whether Borrower X is likely going to be good on their word.

Counterparty risk is very real, and usage of this protocol requires trust in your borrower: Wildcat provides no insurance fund for defaults, and cannot help you if a borrower disappears with your assets.

###

[](#interested)

Interested?

It's not our place to proscribe what Wildcat _should_ and _shouldn't_ be used for - tokenised lending instruments have a wide scope, and we've intentionally designed the protocol to be as hands-off and abstract as possible.

As a settlement layer, consider the protocol itself to be an Uatu the Watcher figure: we're interested, and we're watching, but it will not and _cannot_ interfere.

We're looking forward to seeing how you make use of us!

[PreviousIntroduction](/overview/introduction)
[NextWhitepaper](/overview/whitepaper)

Last updated 3 days ago

We operate a bug bounty program, facilitated by [Immunefi](https://immunefi.com/)
.

At this stage, the total amount allocated to the program is US$50,000.

[![Logo](https://immunefi.com/apple-touch-icon.png)Wildcat Protocol Bug Bounties | ImmunefiImmunefi](https://immunefi.com/bounty/wildcatprotocol/)

The ranges of bounties available for various bug severities is:

- **Critical**: $7,500 - $10,000
- **High**: $5,000 - $7,500
- **Medium**: $3,000
- **Low**: $2,000

[PreviousSphereX Protection](/security-measures/spherex-protection)
[NextWildcat Service Agreement](/legal/wildcat-service-agreement)

Last updated 9 days ago

This section contains the most important aspects of how a Wildcat market operates.

Make sure you understand the [scale factor](/technical-overview/security-developer-dives/the-scale-factor)
before continuing.

[](#market-configuration)

Market Configuration

---

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

[](#basic-market-behavior)

Basic Market Behavior

---

###

[](#collateral-obligation)

Collateral Obligation

Not all market tokens have the same collateral requirements attached. Tokens which are in pending withdrawals (current or unpaid expired batches) must be covered 100% by the borrower with underlying assets as soon as they enter a withdrawal batch, while tokens which are not pending withdrawal only need to be covered at the reserve ratio. We call the portion of the market's total supply which is not pending withdrawal the _outstanding supply_.

Aside from market tokens, there are two other contributors to the collateral obligation: unclaimed protocol fees and unclaimed withdrawals. The latter are no longer associated with market tokens as they represent tokens that have already been paid for, burned and subtracted from the total supply; however, because lenders do not receive their withdrawals until they claim them via `executeWithdrawal`, the assets that have been set aside for withdrawals must remain in the market and so increase the collateral requirement for the market. This effectively just reduces the `totalAssets` the market sees as being available, as these assets do not cause the borrower to incur any additional interest payments or fees. See the section on withdrawals for further details.

The total collateral obligation that a borrower is required to maintain in the market (`state.liquidityRequired()`) is the sum of:

- 100% of all pending (unpaid) withdrawals
- 100% of all unclaimed (paid) withdrawals
- reserve ratio times the outstanding supply
- accrued protocol fees

Copy

    state.normalizeAmount(state.scaledPendingWithdrawals)
    + state.normalizedUnclaimedWithdrawals
    + state.normalizeAmount(
        state.scaledTotalSupply - state.scaledPendingWithdrawals
    ).bipMul(state.reserveRatioBips)
    + state.accruedProtocolFees

###

[](#delinquency)

**Delinquency**

Whenever a market has less total assets than its minimum collateral obligation, the borrower is considered delinquent (`state.isDelinquent`). For every second the borrower remains delinquent, a timer (`state.timeDelinquent`) increments. For every second the market is in a healthy state, the timer decrements.

For every second that the market spends with its delinquency timer above the grace period, the delinquency fee is applied to the interest rate.

This system results in the borrower being penalized for two seconds for every second they allow `timeDelinquent` to exceed the grace period: once on the way up while the market is delinquent, and once on the way down when the market is healthy.

###

[](#interest-rates)

Interest Rates

Borrowers pay interest based on three rates, all of which are denominated in annual bips (1 = 0.01%):

- `annualInterestBips` - The base interest rate set by the borrower. Accrues solely to lenders.
- `delinquencyFeeBips` - An additional fee added to the base interest rate whenever the borrower is in penalized delinquency. Accrues solely to lenders.
- `protocolFeeBips` - A fraction of `annualInterestBips` which accrues to the protocol (in excess of the rate paid to lenders, not extracted from it). This is not affected by delinquency fees.

Every state update, the sum of these rates is applied to the current `scaleFactor` (with the delinquency fee only being applied for the number of seconds the market was in penalized delinquency), compounding the market's interest.

###

[](#state-update)

State Update

At the start of every stateful external function on a market which is the first such transaction in a block, a state update occurs to bring the market state up-to-date.

The basic state update sequence is:

1.  Accrues the base interest rate and protocol fees, as well as the delinquency fee for any seconds since the last update during which the market was in [penalized delinquency](https://github.com/wildcat-finance/v2-protocol/blob/main/docs/Core%20Behavior.md#delinquency)
2.  Updates the delinquency timer, increasing if the previous state was delinquent and decreasing if it was not (to a minimum of zero).
3.  Applies any available liquidity to the pending withdrawal batch if there is one.

If, at the start of the transaction, the current pending withdrawal batch has expired, the state update will be split into two iterations of the above sequence:

- The first will use the last update time as the start date and the withdrawal batch expiry as the end date, and it will handle [batch expiry](https://github.com/wildcat-finance/v2-protocol/blob/main/docs/Core%20Behavior.md#withdrawal-expiry--priority)
  in the third step after reserving available liquidity.

  - This ensures that the borrower does not pay interest on withdrawals that can be retroactively paid off at the time of expiry.

- The second will use the expiry as the start date and the current time as the end date.

###

[](#withdrawals)

Withdrawals

Withdrawal batches group together withdrawal requests from multiple lenders over a period of time (the `withdrawalBatchDuration` parameter) to ensure a fair distribution of available assets when a market is insufficiently liquid to fully honor all withdrawals in a batch.

When a lender requests a withdrawal, they will be entered into the current withdrawal batch if one exists; otherwise, a new one will be created.

From the time a withdrawal batch is created until the time it expires, new lenders may enter the batch by creating a withdrawal request. At the time of the request, the lender is credited for the scaled token amount their withdrawal is equivalent to, giving them pro-rata ownership of the batch according to that scaled amount. These scaled tokens are removed from the lender's balance, but the total supply is only reduced upon payment.

Withdrawal _execution_, or the claiming of paid withdrawals, is only possible after expiry.

Withdrawal batches can be in one of three states:

- Current: The batch represented by `state.pendingWithdrawalExpiry`. Can be added to by lenders until it expires.

  - Note: The "current" batch can also be expired until the state update function is executed and converts it to an unpaid or paid batch.

- Unpaid: A batch which has expired without sufficient assets to cover all withdrawals.
- Paid: A batch which has been fully paid off.

  - Note: "paid off" means that assets are reserved and available for execution, not necessarily that all the withdrawals have been executed.

###

[](#withdrawal-expiry-and-priority)

**Withdrawal Expiry & Priority**

If a batch expires without sufficient assets to cover all requests in it, it is moved into a first-in-first-out queue of "unpaid" batches. Earlier withdrawal batches receive priority over newer batches for payment, but lenders within the same batch have a pro-rata claim to the underlying assets allocated to it regardless of the order of their requests.

When a withdrawal batch expires, the liquidity which can immediately be reserved to pay it off is equal to the market's total assets minus the _unavailable_ assets, which is the sum of:

- unclaimed (paid) withdrawals (`state.normalizedUnclaimedWithdrawals`)
- previous unpaid withdrawals (`state.scaledPendingWithdrawals - batch.scaledOwedAmount`)
- unclaimed protocol fees (`state.accruedProtocolFees`)

Note that while earlier batches receive priority, **this does not mean they always actually get paid first**. When a current batch expires, it can be fully paid off even if there are currently unpaid withdrawal batches in the queue, but only provided that the market has sufficient assets available to cover both. Once a batch is marked as unpaid, it can not have assets reserved for it until all previous unpaid batches are processed.

> Note: Skipping over unpaid batches is allowed for expiring batches because it is trivial to calculate the sum of previous withdrawals as the current batch expires, but doing so for a batch in the middle of the unpaid queue would be much more costly.

###

[](#withdrawal-payment)

**Withdrawal Payment**

The scaled tokens associated with a withdrawal request are subtracted from a lender's balance immediately, but those tokens are not _burned_ until they are honored, meaning they only stop accruing interest once underlying assets have been reserved to pay for them. The batch owns these scaled tokens and accrues their interest until they are burned by a payment, and the interest is distributed pro-rata to the lenders in the batch.

As assets become available, they can be paid to the withdrawal batch. A check for (and payment of) available assets occurs:

- when a lender adds a request to a batch,
- during the state update at the start of a transaction (for the current batch but not for unpaid (already expired) batches),
- upon a call to `repayAndProcessUnpaidWithdrawalBatches` (for unpaid batches).

Once an amount of underlying assets is paid to the batch, the corresponding scaled amount is actually burned: it is removed from the market's total supply, stops accruing interest and becomes available for withdrawal execution by lenders in the batch. These paid-for withdrawals are then moved into the pool of _unclaimed withdrawals_ (`state.normalizedUnclaimedWithdrawals`) representing the amount of underlying assets that are still in the market but which can not be borrowed against and can not be counted toward the reserve ratio, protocol fees or new withdrawal payments.

[PreviousThe Scale Factor](/technical-overview/security-developer-dives/the-scale-factor)
[NextV1 -> V2 Changelog](/technical-overview/security-developer-dives/v1-greater-than-v2-changelog)

Last updated 1 hour ago

Wildcat V2 markets support hooks which can add additional behaviour to the markets, such as handling access control or adding new features.

The goal of the hooks feature is two-fold: to allow restrictions to be set for individual markets and to enable secondary actions that occur in reaction to market actions.

Some examples of the individualized restrictions hooks enable are:

- An access control scheme that allows lenders to access markets without manual approval by the borrower,
- Minimum deposit requirements,
- Time restrictions on withdrawals, i.e. no withdrawals for the first 3 months.

An example of the additional behaviour hooks enable is the ability to add a Masterchef-style system that distributes rewards to lenders, which requires tracking token balances for the market on a separate contract.

This hooks system was chosen to make Wildcat V2 more modular than V1 and improve our ability to develop and deploy new features for Wildcat markets without changing the rest of our core infrastructure such as factories or the base market contract, or needing to re-audit the static parts of the codebase.

[](#hooks-templates)

Hooks Templates

---

The Wildcat Labs team will develop various templates for hooks contracts, with each intended for use with a separate kind of market. For example, our initial hooks template only provides access control for lenders and some basic restrictions on APR changes, whereas future templates might provide for withdrawal time limits on hooked markets or token rewards distribution.

Approved templates will be deployed as stored initcode (constructor code with a leading zero byte to prevent execution) and approved on the HooksFactory contract. Borrowers who are registered on the archcontroller can then select from the available templates when deploying new markets.

[](#hooks-deployment)

Hooks Deployment

---

Hooks contracts can be deployed by borrowers registered on the archcontroller. Borrowers can choose to deploy a new hooks instance for each market (which they might want to do if the markets need different requirements for access, or they want to use a different hooks template), or to re-use the same hooks instance for several markets (if they want the same kind of market and the hooks instance supports use with multiple markets).

Each hooks instance defines a set of optional hooks and a set of required hooks. When deploying a market, the borrower specifies which hooks the market should utilize, and the market will use the hooks which are marked as required by the hooks instance or marked optional and selected by the borrower.

Once a market is deployed, its hooks instance cannot be edited, nor can the set of hooks it uses.

[](#source-code-repo-not-yet-public)

Source Code \[repo not yet public\]

---

Links TBA

[](#further-reading)

Further Reading

---

How Hooks Work

Access Control Hooks

[PreviousKnown Issues](/technical-overview/security-developer-dives/known-issues)
[NextHow Hooks Work](/technical-overview/security-developer-dives/hooks/how-hooks-work)

Last updated 8 days ago

This is always the least interesting part of any protocol or website, truth be told.

The Wildcat protocol was conceived of and built by **Wildcat Labs**, which deployed and currently operates the archcontroller of the protocol referenced in [Contract Deployments](/technical-overview/contract-deployments)
.

As a potted history, Wildcat V1 was built between June 2022 - October 2023 and deployed in November 2023. Wildcat V2 was built in gradual iterations between February - August 2024.

Just saying 'Wildcat Labs' doesn't do justice to the number of people involved though, so if you want some actual names:

Developers:

- Solidity

  - **Dillon Kellar**

- Frontend Developer

  - **Eugene Allenov**
  - **Thom Withaar**

Operations

- **Laurence Day**

Product:

- **Andreas Fletcher**

UI/UX Design:

- **Anastasia Miagkova**
- **Pentacle and Alpha \[legacy webpage\]**

Artwork/Branding:

- **Shizzy Aizawa**

Support:

- **Evgeny Gaevoy**
- **Julian Debbag**
- **Wintermute Ventures**
- **West Ham Capital**

[PreviousProtocol UI Privacy Policy](/legal/protocol-ui-privacy-policy)
[NextContact Us](/miscellaneous/contact-us)

Last updated 8 days ago

**This Gitbook is currently undergoing active changes to reflect Wildcat V2.** Something you don't understand? Something missing? Fire a message to @functi0nZer0 on Twitter and watch him do Things That Don't Scale!

[](#hi)

Hi.

---

Welcome to the Wildcat protocol documentation.

We recognise that a protocol Gitbook is - as a rule - read by three distinct categories of people:

- _Potential users and researchers_ working out if something is actually useful,
- _Security auditors_ working out if something is actually broken, and
- _Lawyers and regulators_ working out if something is actually legal.

With that in mind, we'll keep this high-level page brief.

---

[](#users-researchers)

Users/Researchers

---

You might as well start at the beginning.

[Introduction](/overview/introduction)

---

[](#auditors-developers)

Auditors/Developers

---

Contract deployments, gas profiles etc can be found under the following section:

[Technical Overview](/technical-overview/security-developer-dives)

More specifically, if you're taking part in an audit or validating a potential bug, please refer to:

[Security/Developer Dives](/technical-overview/security-developer-dives)

If you're interested in reading about our on-chain protection or previous security reviews:

[Security Measures](/security-measures/code-security-reviews)

---

[](#lawyers-regulators)

Lawyers/Regulators:

---

[Legal](/legal/wildcat-service-agreement)

Beyond that, the documentation is yours to enjoy (or not) at your leisure.

Hic sunt dragones.

[NextIntroduction](/overview/introduction)

Last updated 2 days ago

Each of the following is considered a core function within the WildcatMarket contract which we may want a hooks contract to be able to track, impose restrictions on, or otherwise react to in some way:

- `deposit` (+ `depositUpTo`)
- `queueWithdrawal` (+ `queueFullWithdrawal`)
- `executeWithdrawal` (+ `executeWithdrawals`)
- `transfer` (+ `transferFrom`)
- `borrow`
- `repay` (+ `repayOutstandingDebt`, `repayDelinquentDebt`)
- `closeMarket`
- `setMaxTotalSupply`
- `nukeFromOrbit`
- `setAnnualInterestAndReserveRatioBips`

Each of these functions has a corresponding hook that can be called on the configured hooks contract, as well as a flag in the market's hooks configuration (`HooksConfig`) indicating whether the hook _should_ be called.

When one of these functions on a market is called, the market will check if the corresponding hook is enabled; if it is, it will call the hook function on the configured hooks contract, providing the intermediate state (prior to applying the full effects of the relevant action, but after accruing interest and fees), the relevant data for the action, the caller address (except for borrower-only functions) and an optional `extraData` buffer supplied by the caller.

Hooks can not modify internal behavior of the market and do not have any privileged access to its state; rather, they are designed to be _reactive to_ and _restrictive of_ market actions. This means, for example, that a hook can not change who receives a transfer or force a lender into a withdrawal, but it can prevent a transfer from occurring or keep some internal state about the withdrawal.

[](#exceptions-to-the-above)

**Exceptions To The Above**

---

There are two exceptions to the behavior described above.

1. The rule about not modifying the market behavior is violated by `setAnnualInterestAndReserveRatioBips` - when a market's APR or reserve ratio are changed, the associated hook has the ability to modify those two values.

2. The rule about only providing intermediate state (i.e. before execution of the action) is violated by the `queueWithdrawal` functions - when a withdrawal is queued, the intermediate state provided to the hooks call is the state _after_ the market's `pendingWithdrawalExpiry` is updated. This ensures the hook has access to the withdrawal expiry if that is ever needed.

[](#extradata-buffer)

`extraData` Buffer

---

In a call to one of the core functions listed above, the caller can append arbitrary bytes to the end of the function calldata. If they do, these bytes will be provided to the call to the hooks contract in the `bytes extraData` field. The primary use-case for this field is for the access control hooks, where the caller may need to provide a signature, merkle proof, or some other verification data in order to be authenticated to a particular market.

The `extraData` field is not part of the market's function signatures; the raw bytes must be appended to the end without ABI offset or length fields, and without padding to the closest word (otherwise the calculated length will be incorrect).

For calls to `executeWithdrawals` and `nukeFromOrbit`, the optional buffer cannot be provided.

[PreviousHooks](/technical-overview/security-developer-dives/hooks)
[NextAccess Control Hooks](/technical-overview/security-developer-dives/hooks/access-control-hooks)

Last updated 8 days ago

The Wildcat protocol is fundamentally permissioned in both roles that it is possible to fill while using it. The operators of the Wildcat protocol grant permission to borrower candidates to deploy markets, whilst borrowers are the ones that determine which categories of lenders are able to interact with the markets that they deploy.

[](#borrowers)

Borrowers

---

Borrowers who wish to make use of Wildcat are encouraged - on the landing page and the protocol UI itself - to get in touch via this [**form**](https://forms.gle/irca7KeC7ASmkRh16)
.

After first contact, what Wildcat is looking for is proof that the borrower is a legal entity in a jurisdiction that is a) not sanctioned, and b) we reasonably believe won't expose the protocol to legal or regulatory risk. Discretion is currently being exercised in that we seek to reach 'up', meaning that we are more likely to accept recognised market makers, trading desks, protocols and such as borrowers. That's not to say that your smaller, less-recognised entity has a more significant probability of default: it very likely doesn't!

We be asking what you intend to utilise Wildcat credit lines _for_, checking that you're a going concern, who your ultimate beneficiaries are and so on. We may request that you engage with a third-party KYB service (such as SumSub or the like) - we'll let you know if that's the case.

In short, this stage can be summarised as: play ball with us and be honest.

Following this, Wildcat requests an Ethereum address, which will be added as a borrower capable of deploying hooks instances and markets to the [**archcontroller**](/using-wildcat/terminology#archcontroller)
. Should you wish to make use of a third-party credential-granting service for your markets, Wildcat will refer you to the appropriate entity and ensure that relevant policies are cloned-and-owned by yourself so that you can make use of them.

After this point, Wildcat steps back.

[](#lenders)

Lenders

---

If you're a party that wishes to lend to a particular borrower, Wildcat itself cannot onboard you.

Rather, the process is determined by the [policies](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)
in place for a particular market, as these are what grant you a credential 'through' the market hook that gates deposit access.

It's hard to abstract the above into a 'this is how you onboard into market X' for this documentation, because one market may require you to reach out to the borrower and get explicitly whitelisted, another may require you to pass a third-party KYC check via an entity such as [Keyring Network](https://keyring.network)
to verify your jurisdiction and that you're accredited (or whatever other requirement the borrower has), and another still may be content to accept a [Coinbase Verification](https://www.coinbase.com/en-gb/onchain-verify)
or [Binance Account Bound Token](https://www.binance.com/en-GB/babt)
.

Wildcat does not decide what a particular borrower should demand in terms of lender onboarding, as we consider this a compliance/legal issue for each borrower depending on their location, risk appetite and purpose. However, the protocol UI provides contact points for borrowers (i.e. email, Telegram), and each market will also indicate the requirements that are in place for onboarding.

In a smooth case, you will be able to briefly head off-site, give some information to a provider, submit an on-chain transaction with a ZK proof that proves you've met the requirements and receive an onboarding credential without ever reaching out to the borrower directly.

Credentials may not last forever depending on borrower configuration, and may require periodic refreshing if you wish to deposit again in the future.

However, in Wildcat V2, addresses that have previously been authorised are always be able to make withdrawal requests, even if their credentials have expired. For this reason, we encourage that you make use of a hardware wallet or a multisig when engaging with Wildcat.

There's some more detail on this available [here](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)
, and we will provide a clearer walkthrough once live.

Note that addresses which are flagged as sanctioned by the [Chainalysis oracle contract](https://go.chainalysis.com/chainalysis-oracle-docs.html)
are prevented from interacting with the protocol at the code-level - although it's a _brave_ entity that tries either asking for or seeking to extend credit from any of these.

[PreviousTerminology](/using-wildcat/terminology)
[NextDay-To-Day Usage](/using-wildcat/day-to-day-usage)

Last updated 1 day ago

In the access control hooks, the borrower can configure a set of "role providers" - accounts which grant credentials to lenders.

Within the hooks contract, the borrower configures each provider with a TTL - the amount of time a credential granted by the provider is valid.

The provider itself defines whether it is a "pull provider", meaning whether the hooks contract can query the role provider to check if a lender has a credential, using only the lender's address.

[](#role-providers)

Role Providers

---

Role providers can "push" credentials to the hooks contract by calling `grantRole`:

- `grantRole(address account, uint32 roleGrantedTimestamp) external`

There are three functions that the hooks contract can call on role providers:

- `isPullProvider() external view returns (bool)`

  - Defines whether the hooks contract can retrieve credentials using `getCredential`

- `getCredential(address account) external view returns (uint32 timestamp)`

  - Looks up a credential for an account using only its address, so it must already be stored somewhere.

- `validateCredential(address account, bytes calldata data) external returns (uint32 timestamp)`

  - Attempts to validate a credential from some arbitrary data (e.g. ecdsa signature or merkle proof).

Role providers do not _have_ to implement any of these functions - a role provider can be an EOA.

---

[](#tryvalidateaccess-address-lender-bytes-hooksdata)

tryValidateAccess(address lender, bytes hooksData)

---

When a restricted function is called, the access control contract will attempt to validate the caller's access to the market in several ways.

1.  If lender has an unexpired credential from a provider that is still supported, return true.
2.  If the lender provided `hooksData`, run [`handleHooksData(lender, hooksData)`](https://github.com/wildcat-finance/v2-protocol/blob/main/docs/hooks/templates/Access%20Control%20Hooks.md#handleHooksDataaddress-lender-bytes-hooksData)

    - If it returns a valid credential, go to step 5

3.  If the lender has an expired credential from a pull provider that is still supported, try to refresh their credential with `getCredential` (see: [tryPullCredential](https://github.com/wildcat-finance/v2-protocol/blob/main/docs/hooks/templates/Access%20Control%20Hooks.md#tryPullCredentialaddress-provider-address-lender)
    )

    - If it returns a valid credential, go to step 5

4.  Loop over every pull provider in `pullProviders` (other than the existing provider and provider in `hooksData`, if they exist)

    - Run [tryPullCredential](https://github.com/wildcat-finance/v2-protocol/blob/main/docs/hooks/templates/Access%20Control%20Hooks.md#tryPullCredentialaddress-provider-address-lender)
      on each provider.
    - If any returns a valid credential, break the loop and go to step 5

5.  If any provider yielded a valid credential, update the lender's status in storage with the new credential and return.
6.  Otherwise, throw an error.

---

[](#trypullcredential-address-provider-address-lender)

tryPullCredential(address provider, address lender)

---

1.  If the provider is not approved, return with no valid credential
2.  Call `getCredential` on the provider

    - If it reverts, return with no valid credential

3.  Add the returned `timestamp` to the provider's TTL to get the expiry
4.  If the resulting credential is expired, return with no valid credential
5.  Return with valid credential

---

[](#handlehooksdata-address-lender-bytes-hooksdata)

handleHooksData(address lender, bytes hooksData)

---

1.  Is `hooksData` 20 bytes?

    - If not, go to 2
    - Set `provider` to `hooksData`
    - Return result of `tryPullCredential(provider, lender)`

2.  Is `hooksData` more than 20 bytes?

    - If not, return false

3.  Take first 20 bytes as `provider`, the rest is `validateData`
4.  If the provider is not approved, return false
5.  Call `validateCredential(lender, validateData)`

    - If it reverts, return false
    - If it returns invalid data, throw an error because the call could have side effects

6.  Add the returned timestamp to the provider's TTL to calculate the expiry
7.  If it is expired, return false
8.  Return true

[PreviousHow Hooks Work](/technical-overview/security-developer-dives/hooks/how-hooks-work)
[NextFunction/Event Signatures](/technical-overview/function-event-signatures)

Last updated 8 days ago

###

[](#im-a-lender-trying-to-deposit-into-a-market-from-a-fireblocks-vault-account-but-my-transactions-are)

I'm a lender trying to deposit into a market from a Fireblocks vault account, but my transactions are getting rejected?

This is very likely because your TAP (Transaction Authorization Policy) is set up to block interactions with DeFi protocols: the default mode is locked down quite heavily.

Add a new Contract Call TAP rule (you can find them in your Settings) with the Wildcat market you are attempting to interact with as the Destination which Allows the interaction, and move it up to the top of your rule-set, above any generic blocking rules. For an example of how to set up a rule: [https://support.fireblocks.io/hc/en-us/articles/7361651981468-TAP-examples](https://support.fireblocks.io/hc/en-us/articles/7361651981468-TAP-examples)
(account required).

---

###

[](#ive-placed-a-withdrawal-request-but-i-cant-claim-my-assets-yet)

I've placed a withdrawal request but I can't claim my assets yet?

This is because when you placed your withdrawal request, you either started a new withdrawal cycle or joined an existing one. That withdrawal cycle needs to conclude before any assets set aside within it can be claimed - the length of which is dependent on the market itself.

Check the Lender Withdrawal Requests tables within the market that you placed the withdrawal request from: you'll be able to see when the cycle ends and you can claim funds that have been made available for you from your request.

---

If you're encountering any difficulties, get in touch!

Two questions in the FAQ doesn't seem like much, but the point of an FAQ is to answer the questions we hear a lot!

[PreviousWhitepaper](/overview/whitepaper)
[NextTerminology](/using-wildcat/terminology)

Last updated 3 days ago

The Wildcat protocol contracts are protected on-chain by [SphereX](https://www.spherex.xyz/)
.

Without going into too much detail here, all external functions are wrapped in a modifier which sanity-checks any given transaction against a training set, reverting said transaction if it deviates too far from expected behaviour.

The net effect of this is that transactions which appear 'exploit-like' in shape (in that they take a novel path through function calls, interact strangely with contract storage, utilise an abnormal amount of gas and so on) are not permitted to execute, with a report of the transaction being sent to an off-chain analytics engine in order to determine the root cause of the rejection.

In the event that the transaction is legitimate (e.g. follows a path that had not been covered by training data), the Wildcat team are capable of updating the reference set to permit that transaction - and others like it - to succeed going forwards.

The nature of this protection means that access to Wildcat markets - and the wider protocol - is continuous even while under attack: deposits and withdrawals are be permitted as usual, whereas hostile transactions are rejected.

In the event that SphereX ceases to exist, the on-chain nature of the protection means that we would only lose access to the off-chain analytics engine and ability to update the reference set. In this (extreme) scenario, we can simply detach the engine and continue on as before, albeit with some wasted gas costs on existing contracts due to routing through a dead modifier.

It is worth noting however, that as with all security measures, the existence of SphereX within the Wildcat codebase does not _guarantee_ total safety. In the event that Wildcat's team is compromised, it is possible to update the reference set with a hostile transaction after it has first been identified and subsequently replay the transaction. More generally, it is possible for the engine to be replaced with a trivial variant that rejects _every_ transaction, effectively freezing the protocol in place.

[PreviousCode Security Reviews](/security-measures/code-security-reviews)
[NextBug Bounty Program](/security-measures/bug-bounty-program)

Last updated 5 hours ago

[](#definition)

Definition

---

Any given Wildcat market contains a _reserve ratio_ that dictates what percentage of the assets that are currently being loaned must be available to be withdrawn at any given moment by lenders.

This ratio applies to the current _supply_ of assets to the market. If a market exists that has a capacity of 10,000,000 USDC and a reserve ratio of 20%, the reserve ratio does not apply to that capacity figure unless the market is fully subscribed.

Rather, if the market has a supply of 4,000,000 USDC from lenders, then 800,000 USDC must be in reserve. The amount that a market requires in reserves inflates as interest accrues on a stable supply, since the market token and underlying asset are redeemable 1:1.

A market which has a zero percent reserve ratio need only worry about this to the extent that they need to monitor for withdrawal requests and keep sufficient assets available to cover the protocol fee, if the latter is active.

A market that goes below the reserve ratio - however it does so - is _delinquent_.

[](#related-market-parameters)

Related Market Parameters

---

As well as the reserve ratio, another two parameters are provided when creating a Wildcat market:

- **The grace period**: the time (measured in seconds) that a market is permitted to be delinquent for without adverse effects, and
- **The penalty APR**: the interest rate that applies over and above the base market APR and protocol fee (if present) in the event that a market stays delinquent for longer than the grace period.

[](#how-delinquency-triggers)

How Delinquency Triggers

---

Associated with each market is an internal number called the '_grace tracker_' - this is a number that starts counting up from zero after the block in which a market becomes delinquent, and back down towards zero after the block in which a market is cured of its delinquency.

The penalty APR associated with a market activates once the grace tracker exceeds the grace period, and remains active until it drops below the same. To illustrate:

- A market with a 5 day grace period becomes delinquent for the first time, and the grace tracker begins counting up from zero.
- The borrower takes 7 days to cure the market of its delinquency.
- Once the delinquency is cured, the market calculates that 2 days of penalty APR must be applied and adjusts the scaling factor of market tokens accordingly.
- The grace tracker counts back down to zero from this point - subsequent market state updates will detect when the tracker drops below the market grace period and adjust scaling factors appropriately.
- A total of **4** days of penalty APR will be applied in total: the failure of a market to update its state in a timely fashion as the tracker drops below the grace period does _not_ adversely impact the borrower.

[](#unclaimed-pending-withdrawals-and-delinquency)

Unclaimed/Pending Withdrawals & Delinquency

---

Tthe reserve ratio of a market can be temporarily raised depending on the amount of assets that are either earmarked for withdrawal by a lender, or are part of a pending withdrawal request.

When a lender burns market tokens in order to request a withdrawal of assets they have deposited in a market, any reserves that exist within the market are removed from the market supply. Consider the following:

- A market with a supply of 1,000,000 USDC has a reserve ratio of 20%, and currently holds 250,000 USDC in reserves (current reserve ratio 25%).
- A lender makes a request to withdraw 200,000 USDC, burning 200,000 market tokens to move 200,000 USDC of the reserves into the unclaimed withdrawals pool, and reducing the supply by the same amount.
- The market now has 50,000 USDC in reserves against a supply of 800,000 USDC. This means that the new reserve ratio is 6.25%, and the market is immediately delinquent.
- The borrower needs to return 110,000 USDC to the market reserves in order to cure the delinquency.

More particularly, any withdrawal request that exceeds the reserves currently in a market temporarily forces the reserve ratio upwards. To illustrate:

- A market with a supply of 1,000,000 USDC has a reserve ratio of 20%, and currently holds 250,000 USDC in reserves (current reserve ratio 25%).
- A lender makes a request to withdraw 400,000 USDC, burning 250,000 market tokens to move 250,000 USDC of the reserves into the unclaimed withdrawals pool and generating a pending withdrawal of the remaining 150,000 USDC. The reserve ratio of the market is immediately 0%.
- The supply of the market is reduced by the 250,000 that was moved into unclaimed withdrawals, rather than the full 400,000 requested.
- Pending withdrawals must be 100% collateralised by a market, with the standard reserve ratio of the market applying to the _remainder_ of the supply. In this case, then, the amount of reserves that the market must hold is (150,000 \* 1) + (600,000 \* 0.2) = 270,000 USDC.
- Against a supply of 750,000 USDC, this means that the temporary reserve ratio is 36% rather than the 20% we would 'expect' to see against the remaining supply: the market will remain delinquent until this 36% has been met.
- Pending withdrawals - and their impact on the reserve ratio of a market - remain in place until the lender is capable of burning market tokens in order to reclaim their loaned assets.

\[_The above includes one mild simplification: as stated in_ [_Protocol Usage Fees_](/using-wildcat/protocol-usage-fees)\
_, lenders are only capable of withdrawing reserves net of any protocol fees that have been accrued and not withdrawn. However, the overall point remains._\]

The astute borrower of a market will actively monitor withdrawal requests and current reserve ratios in order to minimise the time for which the grace tracker is active to avoid paying penalties.

[PreviousProtocol Usage Fees](/using-wildcat/protocol-usage-fees)
[NextSecurity/Developer Dives](/technical-overview/security-developer-dives)

Last updated 3 days ago

When you first encounter a Wildcat market, you will very likely be prevented from depositing unless you meet certain requirements specified by the borrower, to make sure that they're not making use of funds sourced from Lazarus.

The way that this worked in Wildcat V1 was that the borrower had to perform due diligence on each would-be lender that approached them and subsequently add their address to a controller contract via an on-chain transaction. This was a huge friction point, and one of the primary reasons we built V2.

Wildcat V2 abstracts this away by putting the `deposit` function behind a 'hook' (a piece of code that needs to succeed before access to the function is granted). We've built this in a way that borrowers can select arbitrary mechanisms tailored to their preferences, but the most common examples we expect to see are:

- Addresses that are members of a pre-determined set,
- Addresses that have some form of NFT or soulbound token testifying to their identity, and
- Addresses that have a credential testifying to off-chain circumstances.

The first example is effectively the V1 model, but we didn't want to throw it in the bin: we just also didn't want it to be the _only_ way that people could access Wildcat. We plan to evolve this slightly, however: if a borrower is an entity that has a significant number of OTC counterparties, Wildcat can deploy a market which is accessed by providing proof that your address is in the Merkle tree of that set (ensuring that addresses of counterparties aren't exposed).

The second example accounts for on-chain solutions such as [Coinbase Verifications](https://www.coinbase.com/en-gb/onchain-verify)
and [Binance Account Bound Tokens](https://www.binance.com/en-GB/babt)
, assuming that the borrower is comfortable piggybacking off of these. In this case, access credentials are granted by signing a transaction that verifies that your address is in fact in possession of whatever is being sought out (i.e. an NFT in your wallet with a certain timestamp).

The third example is one that extends off-chain. We make use of [Keyring Network](https://keyring.network)
to enable borrowers to specify rule-sets that they require lenders to adhere to. Depending on whether a Keyring Pro or Keyring Connect policy is used, lenders may be required to upload KYC/KYB data to a third-party platform such as ComplyCube or ShuftiPro to establish jurisdiction, extract evidence of accredited investor status and so on. Keyring enables proofs of such compliance to be submitted on-chain to receive Wildcat credentials without leaking any identifiable data on-chain.

There is substantially more detail on the flexibility offered here in the [Keyring docs](https://docs.keyring.network/docs/end-users/how-to-onboard/kyc-onboarding)
.

For borrowers making use of Keyring Pro policies to gate access, they must create a profile on Keyring and either clone a template Wildcat policy that we provide, or construct their own: in either event, the borrower must own the policy that they are making use of. Wildcat covers the costs. For lenders, you will need to create a Keyring profile and potentially install an extension that witnesses data you receive via HTTPS and constructs proofs of its validity.

We'll be able to illustrate this in far more detail once we have some live policies and markets available, but the TL;DR is: in most cases, we expect you to be able to onboard yourself to Wildcat markets without ever having to reach out to a borrower via Telegram or email!

[](#credential-durations)

Credential Durations

---

When you have acquired a credential granting you access to deposit into a Wildcat market, it's worth noting that it may eventually expire, depending on whether or not the borrower has set a 'Time-To-Live' limit on it. This is to reduce the risk of an address being compromised and funds being deposited from an entity that is not the party which initially received the credential (unlikely as this may be). Credentials can be refreshed, assuming that the provider/mechanism is still registered to the market.

Note also that any address that has historically received a credential and deposited permanently retains the ability to withdraw: it is for this reason that we encourage lenders to make use of hardware wallets or multisigs when depositing.

[PreviousLenders](/using-wildcat/day-to-day-usage/lenders)
[NextThe Sentinel](/using-wildcat/day-to-day-usage/the-sentinel)

Last updated 1 day ago

The bulk of the ideology, design decisions and high-level logic behind the protocol can be read in the Wildcat whitepaper. It's not highly technical, and intended to be a _fairly_ easy read barring some presented examples which you can skip over.

Most of the content is expanded on in this Gitbook, however, so if you've read this site top to bottom you're not going to be missing out by skipping it.

**v2.0 \[Release Date: Pending\]:**

[https://github.com/wildcat-finance/wildcat-whitepaper/blob/main/whitepaper_v2.0.pdf](https://github.com/wildcat-finance/wildcat-whitepaper/blob/main/whitepaper_v2.0.pdf)
\[placeholder link\]

**v1.0 \[Release Date: 13 November 2023\]:** [https://github.com/wildcat-finance/wildcat-whitepaper/blob/main/whitepaper_v1.0.pdf](https://github.com/wildcat-finance/wildcat-whitepaper/blob/main/whitepaper_v1.0.pdf)

[PreviousWhat Wildcat Enables](/overview/what-wildcat-enables)
[NextFAQs](/overview/faqs)

Last updated 3 days ago

This page contains a handful of explainers that we have produced for the sake of auditors describing the various components of Wildcat V2 and how they work.

You might find the contents useful if you're taking part in a Code4rena review or validating an issue for an Immunefi submission, but otherwise you might have A Bad Time.

Nonetheless, here you go:

[](#undefined)

[The Scale Factor](/technical-overview/security-developer-dives/the-scale-factor)

---

[](#undefined-1)

[Core Behaviour](/technical-overview/security-developer-dives/core-behaviour)

---

[](#undefined-2)

[V1 -> V2 Changelog](/technical-overview/security-developer-dives/v1-greater-than-v2-changelog)

---

[](#undefined-3)

[Known Issues](/technical-overview/security-developer-dives/known-issues)

---

[](#undefined-4)

[Hooks](/technical-overview/security-developer-dives/hooks)

---

###

[](#undefined-5)

[How Hooks Work](/technical-overview/security-developer-dives/hooks/how-hooks-work)

###

[](#undefined-6)

[Access Control Hooks](/technical-overview/security-developer-dives/hooks/access-control-hooks)

[PreviousDelinquency](/using-wildcat/delinquency)
[NextThe Scale Factor](/technical-overview/security-developer-dives/the-scale-factor)

Last updated 8 days ago

[](#making-deposits)

Making Deposits

---

Depositing assets to a Wildcat market is a fairly simple process, and we presume in this section that a [**lender**](/using-wildcat/terminology#lender)
wishing to lend to a [**borrower**](/using-wildcat/terminology#borrower)
through a market has obtained an access credential (either self-served via a [Keyring Network policy](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)
, an explicit whitelist or however the market is set up). We'll fill out some examples here as markets start spinning up and we can display some concrete examples.

If the borrower has specified that they want to make use of it, the lender will be asked whether or not they wish to countersign an associated Wildcat Master Loan Agreement (MLA) parametised for the specific market terms. Note that dependent on the borrower, this may not be in place, and rather there is a separate legal agreement that is offered to the lender which you may be asked to sign off-chain.

Either way, after countersigning or declining, the lender is able to access the market itself.

Provided that the lender holds some of the [**underlying asset**](/using-wildcat/terminology#underlying-asset)
, and there is [**capacity**](/using-wildcat/terminology#capacity)
in the market, the lender is able to deposit as much of the asset as they are willing to (or up to the capacity), receiving in exchange a 1:1 amount of the [**market token**](/using-wildcat/terminology#market-token)
associated with that particular market. The lender that deposits 133.7 XYZ tokens into a market will receive 133.7 market tokens - with the market token name depending on what was selected by the borrower when the market was launched: e.g. wildcatXYZ.

Market tokens are _rebasing_ - depositing 1,000 tokens of an underlying asset into a market offering 10% base APR will result in a wallet balance of 1,100 market tokens after a year, giving rise to a claim on 1,100 tokens of the underlying.

\[Wildcat market tokens differ somewhat from aTokens/eTokens from Aave and Euler in that do not have an internal exchange rate whereby 1 market token will be worth - for example - 1.05 of the underlying asset after a year. Rather, after every interaction with the market that changes the state, market token balances will be adjusted to maintain the 1:1 ratio between market tokens held and the claim of each lender.\]

Depending on the constraints placed upon the markets, lenders _may_ be able to transfer market tokens freely (you can send them to a cold wallet, you can LP them, you can build additional infrastructure around them). Borrowers are able to constrain transfers to only those addresses that have received an onboarding credential, or completely prevent transfers except for those to/from the market contract.

If your address has ever received a credential to deposit to a specific market, you will always be allowed to place withdrawal requests for that market. If the market permits it and Lender A sends their market tokens from their depositing wallet to a secondary one, they must either be sent back in order to claim, or the secondary wallet address must also acquire a credential.

[](#making-withdrawals)

Making Withdrawals

---

[**Withdrawals**](/using-wildcat/terminology#withdraw)
are handled slightly differently within Wildcat markets than in other DeFi protocols you might be used to interacting with.

To that end, this section provides a brief guide to how withdrawals are processed, and the ways in which you reclaim assets from a market that you have requested, either in full or _pro rata_ depending on both the reserves currently in the market and how many other lenders are simultaneously requesting a withdrawal.

Wildcat does not permit immediate withdrawals - rather, the borrower that you are lending to specified a [**withdrawal cycle**](/using-wildcat/terminology#withdrawal-cycle)
length when creating the market you are attempting to withdraw from.

A withdrawal involves:

- Transferring the total number of market tokens corresponding to your requested amount to the market, which are either burned immediately or held to be burned (which one happens depends on the amount of reserves currently in the market),
- Waiting for the withdrawal cycle period to elapse (either the full period if you were the request that kickstarted the cycle, or the remainder if you placed the request in the middle of a cycle), and then
- Claiming the assets that are available to you at the end of the cycle.

Please note that as of Wildcat V2, a borrower can explicitly force a lender into a withdrawal cycle at their discretion, bypassing any fixed duration hook that may be in place (please see [here](/using-wildcat/day-to-day-usage/borrowers#forced-withdrawals)
for details).

###

[](#the-unclaimed-withdrawals-pool)

The Unclaimed Withdrawals Pool

Within a given market, there is a unclaimed withdrawals pool \- a 'side-pot' containing reserves that are still technically 'within' the market, but have been earmarked for withdrawal by lenders via a _withdrawal request_. Assets that are placed within this pool are unavailable to the borrower (they are considered to be removed from the market supply), and the [**reserve ratio**](/using-wildcat/terminology#reserve-ratio)
of a market does not factor them in.

When you request a withdrawal, whether any of the market tokens you transfer to the market are burned or not depends on whether there are any reserves that are _not_ yet in the unclaimed withdrawals pool.

- If there are reserves in the pool that are not in the unclaimed withdrawals pool, then market tokens are burned at a 1:1 rate in order to move those reserves into the pool. If there is no current withdrawal cycle ongoing, this action begins the countdown for a new cycle.
- If all assets within the market are currently within the unclaimed withdrawals pool (or there are no reserves in the pool to speak of at present), then your withdrawal request is logged, but no market tokens are burned after you transfer them (as there is nothing to move into the pool). Instead, you tokens will burn as assets become available (see below).

###

[](#claiming)

Claiming

Once a withdrawal cycle completes, then lenders who made withdrawal requests during that cycle are able to _claim_ assets that they requested from the unclaimed withdrawals pool, subject to the following:

- If there are enough assets in the unclaimed withdrawals pool to cover the total amount requested for withdrawal in that cycle, then the lender can claim the full amount of their requested withdrawal.
- In the scenario where the total amount requested (across several lenders) exceedes the amount in the unclaimed withdrawals pool, then the lender is able to claim a _pro rata_ amount of the assets in the reserved pool proportional to the size of _their_ overall withdrawal amount compared to the total. To illustrate:

  - If Lender A requested a withdrawal of 10,000 tokens from a pool with 5,000 tokens in reserve, they would be able to withdraw all 5,000 if they were the only lender in that withdrawal cycle.
  - In the event that Lender B requests a withdrawal of 40,000 tokens in the same cycle, however, Lender A would only be able to claim 1,000 tokens while Lender B would be able to claim 4,000 (because 10,000 : 40,000 is a 1:4 ratio).
  - Note in this scenario that Lender A - if they requested the withdrawal first - would have had half of their market tokens burned to place these 5,000 assets in the unclaimed withdrawals pool, while Lender B had none burned. Rather, Lender B's market tokens will be burned later on as assets are repaid by the borrower.
  - The above situation leaves Lender A having burned 5,000 market tokens and only able to claim 1,000 - the discrepancy here is logged, and is resolved as the overall outstanding amount is paid off by the borrower.

###

[](#expired-claims-and-the-withdrawal-queue)

Expired Claims and The Withdrawal Queue

Any withdrawal amounts that cannot be honoured at the end of a withdrawal cycle (either due to the assets in market reserves being insufficient, or due to a _pro rata_ claim on assets within the unclaimed withdrawals pool) are batched together, marked as 'expired' and placed into a queue.

Subsequent repayments by the borrower to a market with a non-zero queue will route assets to the unclaimed withdrawals pool in the amounts required to fully honour _all_ expired claims _in the order that they were initiated_ \- only after this obligation is met do repaid assets start counting towards the reserve ratio of a market.

To illustrate in some depth (this is pretty picky stuff, no harm no foul if you don't read it):

- A market with capacity 50,000 has a supply of 40,000 tokens, and 10,000 tokens in reserve (for a reserve ratio of 25%).
- Lender A makes a withdrawal request for 15,000 tokens, moving 15,000 market tokens to the market and burning 10,000 of them to move the reserves to the unclaimed withdrawals pool (reserve ratio now 0%).
- The supply of the market is reduced to 30,000 tokens (10,000 burned).
- Lender B makes an additional withdrawal request in the same cycle for 5,000 tokens: there are no assets in reserve to move, so no market tokens are burned.
- The withdrawal cycle period elapses.
- There is a total of 10,000 tokens in the unclaimed withdrawals pool and an outstanding claim of 20,000 tokens from both lenders:

  - Lender A can claim 7,500 tokens,
  - Lender B can claim 2,500 tokens,

- Lender A now has an outstanding claim of 7,500 tokens (2,500 of which have been 'pre-paid' in the sense that an extra 2,500 market tokens were burned than they were able to access), and Lender B has an outstanding claim of 2,500 tokens.
- This claim of a total of 10,000 tokens is marked as expired and placed in the queue as **Batch A.**
- Lender C starts a new withdrawal cycle by requesting a withdrawal of 5,000 tokens. As with Lender B, no reserves means no market tokens are burned.
- This second withdrawal cycle elapses, and a second expired claim for 5,000 tokens is added to the queue as **Batch B.**
- At this point, the borrower returns 13,000 tokens to the market.
- These tokens are immediately placed into the unclaimed withdrawals pool, and since the amount returned is less than the total amount outstanding in the queue (15,000), the reserve ratio of the market remains at 0%.
- Since the unclaimed withdrawals pool now contains enough assets to fully honour Batch A, the remaining 10,000 market tokens held by the market and associated with this batch are burned.
- Both Lender A and Lender B can now claim the remainder of their withdrawal request amounts.
- After factoring in the assets to honour Batch A, Batch B has 3,000 assets against a 5,000 claim. 3,000 of the market tokens transferred by Lender C are burned, and so Lender C can claim 3,000.
- **Important:** even though the 13,000 tokens returned to the market were in excess of the 5,000 token claim of Lender C, they were only eligible to claim that part in excess of the amount owed to the previous batch in the queue .
- If all of these claims are processed, the Batch A is eliminated from the queue, leaving only a 2,000 token claim for Lender C.
- If the borrower subsequently returns an additional 11,000 tokens to the market at this point, then 2,000 are again assigned to the unclaimed withdrawals pool, burning the remaining 2,000 market tokens associated with Batch B.
- The remaining 9,000 are now considered 'true' reserves, bringing the reserve ratio of the market back up to 9,000 / 15,000 = 60%.

One final point: if there are multiple lenders in a batch, and the batch can only be partially honoured (via a return of less than the total amount due), then each individual lender in the batch can only claim a pro-rata amount of the assets isolated to that batch.

Phrased differently: if a batch has been 60% honoured with deposited assets, then each lender can only withdraw 60% of their outstanding claim, until such time as more assets arrive to completely honour the batch.

This logic can be _very_ confusing when first encountering it, so please ask us if there's any particular part you'd like us to expand on differently!

[PreviousBorrowers](/using-wildcat/day-to-day-usage/borrowers)
[NextMarket Access Via Policies/Hooks](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)

Last updated 1 day ago

[](#avoiding-delinquency-fees)

**Avoiding Delinquency Fees**

---

If the borrower closes a Wildcat market while it is still in penalized delinquency, they will not have to pay out the remaining time worth of penalized delinquency fees as the timer will be set to zero.

We decided that this is an acceptable trade-off enabling lenders to access their funds immediately, rather than waiting what could range from days to weeks for a borrower to come good on their word.

[](#malicious-delinquent-borrowers-can-lead-to-loss-of-funds)

**Malicious/Delinquent Borrowers Can Lead To Loss Of Funds**

---

This one is fairly obvious but worth stating - if a borrower fails to repay their debt for any reason, lenders will inevitably lose funds.

If the borrower is malicious, they can hurt lenders in a variety of ways, including but not limited to: not repaying debt; adding themselves as a lender in order to withdraw beyond the borrow limit on a market they intend to default on; slowly reducing the APR by 25% every two weeks to avoid the penalty of an increased reserve ratio, and several other things.

[](#newer-withdrawals-lose-some-of-their-accrued-interest-to-previous-withdrawals-in-the-same-batch)

**Newer Withdrawals Lose Some Of Their Accrued Interest To Previous Withdrawals In The Same Batch**

---

This one is intentional but may initially seem erroneous.

If Alice creates a withdrawal batch with a request to withdraw 100 tokens while the scale factor is 1, and then Bob later requests a withdrawal of 200 tokens when the scale factor is 2 and they are in the same batch, Alice and Bob will both receive 150 underlying tokens: they have each been credited for 100 scaled tokens given to the batch.

This is very much desired behavior, as it prevents earlier lenders from being penalized for creating a batch (which benefits the other lenders). All interest earned on scaled tokens entered into a batch is distributed evenly to the lenders in the batch, as if they had all created their withdrawal requests at the same time.

The example given is also an extreme one: in practice it'd much more likely be a fraction of a percent.

[](#bad-hook-implementations)

**Bad Hook Implementations**

---

If any of the hooks that are enabled for a market can revert unexpectedly, the corresponding market function may become permanently disabled. This is considered a known/unfixable issue with respect to the market, but if such an issue is actually discovered in a hooks template we have developed, this is a major vulnerability that should be reported.

[](#sanctioned-account-handling-can-lead-to-unexpected-behaviour-on-markets-with-withdrawal-restrictions)

**Sanctioned Account Handling Can Lead To Unexpected Behaviour On Markets With Withdrawal Restrictions**

---

If a market uses a hook with a withdrawal restriction, e.g. to prevent withdrawals before a specified date, sanctioned account handling may not work correctly as it will attempt to force the lender into a withdrawal, and those withdrawals are treated the same as any other.

This could lead to unavoidable interest payments to a sanctioned entity's escrow address (where the funds will go when withdrawals are eventually unrestricted).

[](#hooks-lack-some-specificity)

**Hooks Lack Some Specificity**

---

While one of the stated objectives of hooks is to enable auxiliary behavior based on the state of a Wildcat market (one example is a Masterchef-style contract), the hooks do not necessarily provide enough information to replicate the market state 1:1 in real time.

Specifically, because payment towards a withdrawal batch does not have its own hook, the hooks instance would need to query additional data and perform additional calculations to precisely track the balance of an account including its pending withdrawals in real time, or to know the exact state of a pending/unpaid withdrawal batch.

We anticipate that, for any features added in the future, considering an account to have burned their market tokens at the time a withdrawal is queued will be sufficient precision for the purposes we expect to need this for, and as such we consider the loss of 100% precision on the exact internal market state to be a reasonable sacrifice considering the additional cost such precision would impose.

Any other issues with the ability of a hooks instance to track the state of the market should be reported.

[](#conversion-between-scaled-and-normalised-amounts-have-some-rounding-error)

**Conversion Between Scaled And Normalised Amounts Have Some Rounding Error**

---

We are aware that deposits, withdrawals, and even transfers incur some inevitable rounding error. We will only accept findings that show either:

- This dust is sufficient to break something in the market, or
- The rounding error can realistically be more than dust

So for example, we would not accept a finding that says you could do ten million transfers to accumulate ten million wei worth of the market token. On the other hand, in V1 there was a finding where the dust could cause a market to be impossible to close, which is why we now round down for withdrawal payments to a batch.

[](#some-assembly-blocks-leave-dirty-bits-in-memory)

**Some Assembly Blocks Leave Dirty Bits In Memory**

---

For example, in `HooksConfig`, all of the calls from a market to the various hook functions are done in assembly, with the calldata written to unallocated memory that is left as is at the end of the call. We would only accept a finding on this subject if it demonstrated a specific attack showing this is unsafe or can lead to buggy behavior.

[](#markets-can-be-constructed-in-a-way-that-makes-it-impossible-for-anyone-to-request-a-withdrawal)

**Markets Can Be Constructed In A Way That Makes It Impossible For Anyone To Request A Withdrawal**

---

While we tried our best to ensure lenders who deposit to a market can not have their withdrawal rights revoked (by ensuring the deposit/transfer hooks are always enabled if the withdrawal hook is enabled), it is still possible for a borrower to maliciously prevent lenders from ever acquiring the necessary credential for withdrawals.

The way this would work is:

- Create a market with credentials required for withdrawal but not for deposit or transfers.
- Never add any role providers.
- Lenders can deposit, but since they'll never have a credential, they will never be given the `isKnownLender` flag, and thus can never withdraw.

Unfortunately it is not possible to remove this problem without eliminating certain kinds of market that are desirable, so we consider this in a similar vein to the issue with malicious borrowers simply not repaying their debt, in that it's up to lenders to be selective with who they lend to.

[](#reliance-on-chainalysis)

**Reliance On Chainalysis**

---

If the Chainalysis sanctions oracle were to be compromised or otherwise start flagging accounts as sanctioned that in reality are not, that would lead to those accounts being frozen on all Wildcat markets they lend to.

[PreviousV1 -> V2 Changelog](/technical-overview/security-developer-dives/v1-greater-than-v2-changelog)
[NextHooks](/technical-overview/security-developer-dives/hooks)

Last updated 4 hours ago

[](#lens)

Lens

---

Removed the lens contracts from the core protocol repository.

[](#market-deployment)

Market Deployment

---

###

[](#create2-restrictions)

**CREATE2 Restrictions**

Borrowers are no longer restricted to deploying one market per combination of (asset, name, symbol), which was an issue when a borrower needed to close and recreate an existing market.

When deploying a market, the borrower can now provide an arbitrary salt in the style of 0age's ImmutableCreate2Factory, where the first 20 bytes must either be zero or match the borrower's address, and the remaining 12 bytes can be any value so long as the full salt has not already been used.

###

[](#name-symbol-length)

**Name/Symbol Length**

Increased maximum supported name/symbol length for underlying contract from 32 to `63 - prefix.length`. The name/symbol queries now support arbitrary length strings; once combined with their prefixes, each must fit into two slots, with one byte reserved for the string length.

[](#markets)

Markets

---

###

[](#accounts)

**Accounts**

- Accounts no longer have a `role` field, their ability to access various functions (other than borrower-only ones) is not restricted within the market itself, this is delegated to the market's hooks.

###

[](#handling-of-sanctioned-accounts)

**Handling Of Sanctioned Accounts**

- Removed `stunningReversal` because accounts no longer have roles marking them as sanctioned.
- Market tokens are forced into a withdrawal batch rather than being transferred to an escrow when an account is marked as sanctioned. Withdrawal execution on a sanctioned account still transfers the underlying assets to the corresponding escrow.
- Functions which are not accessible to sanctioned entities no longer fail gracefully (in V1 they would block the account rather than revert). They now revert with an `AccountBlocked` error when the account is sanctioned.

###

[](#withdrawal-batch-rounding)

**Withdrawal Batch Rounding**

Normalised values for withdrawal batch payments are now rounded down rather than up to prevent a bug where closed markets could have their last withdrawal batch become uncloseable due to underpayment by a few wei.

###

[](#token-rescue-function)

**Token Rescue Function**

For assets other than the market token itself or the underlying asset, ERC20 tokens sent to the contract can be recovered by the borrower.

###

[](#market-closure)

**Market Closure**

- When a borrower closes a market that has pending withdrawals or unpaid withdrawal batches, rather than reverting, the market now steps through the list of unpaid batches and closes them after transferring all remaining debt from the borrower.
- `closeMarket` now callable by borrower rather than controller.

###

[](#reentrancyguard)

**ReentrancyGuard**

The ReentrancyGuard now uses transient storage, using a modified version of 0age's ReentrancyGuard from Seaport.

###

[](#apr-reserve-ratio-setters)

**APR/Reserve Ratio Setters**

- Removed `setAnnualInterestBips` and `setReserveRatioBips`
- Added `setAnnualInterestAndReserveRatioBips`
- Now callable by borrower rather than controller

###

[](#miscellaneous)

**Miscellaneous**

Replaced most of the remaining ABI decoders/encoders for calls and large structs with manual assembly coder functions.

- Custom encoder for writing MarketState to storage.
- Custom decoder for constructor parameters and factory call.
- Custom encoders for all sentinel calls in market.
- Custom name/symbol query functions
- Custom state initialisation in constructor, only touching slots that are actually initialised.

[](#market-control)

Market Control

---

Market controllers have been removed in favour of borrower-controlled markets with hooks that can impose their own restrictions. By default, the market itself does not restrict basic access to the market.

[PreviousCore Behaviour](/technical-overview/security-developer-dives/core-behaviour)
[NextKnown Issues](/technical-overview/security-developer-dives/known-issues)

Last updated 8 days ago

[Borrowers](/using-wildcat/day-to-day-usage/borrowers)
[Lenders](/using-wildcat/day-to-day-usage/lenders)
[Market Access Via Policies/Hooks](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)
[The Sentinel](/using-wildcat/day-to-day-usage/the-sentinel)

[PreviousOnboarding](/using-wildcat/onboarding)
[NextBorrowers](/using-wildcat/day-to-day-usage/borrowers)

[](#ethereum-mainnet-v1)

Ethereum Mainnet \[V1\]

---

| Contract Name                  | Contract Address                                                                                                      |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| MarketLens                     | [0xf1D516954f96c1363f8b0aE48D79c8ddE6237847](https://etherscan.io/address/0xf1D516954f96c1363f8b0aE48D79c8ddE6237847) |
| WildcatArchController          | [0xfEB516d9D946dD487A9346F6fee11f40C6945eE4](https://etherscan.io/address/0xfEB516d9D946dD487A9346F6fee11f40C6945eE4) |
| WildcatMarketControllerFactory | [0xFd31007613C9F671df6A8D4234901324986Bfd13](https://etherscan.io/address/0xFd31007613C9F671df6A8D4234901324986Bfd13) |
| WildcatSanctionsSentinel       | [0x437e0551892C2C9b06d3fFd248fe60572e08CD1A](https://etherscan.io/address/0x437e0551892C2C9b06d3fFd248fe60572e08CD1A) |

[](#sepolia-testnet-v1-components-of-pre-audited-v2)

Sepolia Testnet \[V1, components of pre-audited V2\]

---

Note: incomplete V2 deployment dated 5th August 2024 - only of archival interest to auditors.

| Contract Name                      | Contract Address                                                                                                              |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| AccessControlHooks_initCodeStorage | [0x42893972c752E731c3457d0d541a2BC6fAdFE751](https://sepolia.etherscan.io/address/0x42893972c752E731c3457d0d541a2BC6fAdFE751) |
| HooksFactory                       | [0x6Cb3512b541733d340Aa520b63105586588BD600](https://sepolia.etherscan.io/address/0x6Cb3512b541733d340Aa520b63105586588BD600) |
| MarketLens                         | [0xb3925B31A8AeDCE8CFc885e0D5DAa057A1EA8A72](https://sepolia.etherscan.io/address/0xb3925B31A8AeDCE8CFc885e0D5DAa057A1EA8A72) |
| MockArchControllerOwner            | [0xa476920af80B587f696734430227869795E2Ea78](https://sepolia.etherscan.io/address/0xa476920af80B587f696734430227869795E2Ea78) |
| MockChainalysis                    | [0x9d1060f8DEE8CBCf5eC772C51Ec671f70Cc7f8d9](https://sepolia.etherscan.io/address/0x9d1060f8DEE8CBCf5eC772C51Ec671f70Cc7f8d9) |
| MockERC20Factory                   | [0x54A3103904977DCb3C2fB782059F5431db90C96e](https://sepolia.etherscan.io/address/0x54A3103904977DCb3C2fB782059F5431db90C96e) |
| WildcatArchController              | [0xC003f20F2642c76B81e5e1620c6D8cdEE826408f](https://sepolia.etherscan.io/address/0xC003f20F2642c76B81e5e1620c6D8cdEE826408f) |
| WildcatMarketControllerFactory     | [0xEb97C8E52d7Fdf978a64a538F28271Fd8499b864](https://sepolia.etherscan.io/address/0xEb97C8E52d7Fdf978a64a538F28271Fd8499b864) |
| WildcatMarket_initCodeStorage      | [0xB666C1C67A20814E3eEE15A06780E0821Ae30dd1](https://sepolia.etherscan.io/address/0xB666C1C67A20814E3eEE15A06780E0821Ae30dd1) |
| WildcatSanctionsSentinel           | [0xFBCE262eC835be5e6A458cE1722EeCe0E453316B](https://sepolia.etherscan.io/address/0xFBCE262eC835be5e6A458cE1722EeCe0E453316B) |

[PreviousProtocol Structs](/technical-overview/protocol-structs)
[NextCode Security Reviews](/security-measures/code-security-reviews)

Last updated 5 hours ago

[](#launching-a-new-market)

Launching A New Market

---

For the purpose of this section, we assume that the borrower has already gotten in contact with Wildcat and been added as a whitelisted borrower on the [**archcontroller**](/using-wildcat/terminology#archcontroller)
(the registry that tracks permissions and deployments).

Once this is done, the borrower can go to the protocol UI, and having signed the [**Service Agreement**](/using-wildcat/terminology#service-agreement)
(if not done already), navigate to the Borrower section, and then click New Market.

There are a number of parameter fields that are presented here, and the screen may appear a bit overwhelming, but they fundamentally represent the degrees of freedom you have available to you. They are:

###

[](#underlying-asset)

**Underlying Asset**

This is the asset that you wish to borrow, such as LUSD or WETH.

###

[](#master-loan-agreement-type)

Master Loan Agreement Type

This is not directly relevant to the structure of the market which is deployed, but borrowers are presented with the option of whether or not to make use of a Wildcat-specific master loan agreement.

If selected, this agreement is presented to lenders via the front-end to sign before they first deposit.

###

[](#market-type)

**Market Type**

Following the deprecation of Wildcat V1, the only type of market currently supported is the V2 market 'base' type. However, the functionality of a V2 market can be widely configured.

Each market is fundamentally open access to start (anyone can deposit, debt is freely transferable etc.), however there are a number of choices to be made which constrain access in certain ways depending on borrower preference. Examples are:

- **Minimum deposit amounts**: what is the minimum amount of the underlying asset that will be accepted by the market in a single deposit transaction by an approved lender?
- **Minimum market-freeze duration** (enabling fixed duration markets): how many days after market launch before withdrawal requests will process?
- **Transferability restrictions**: should the debt token issued by your Wildcat market be freely transferable to any recipient, restricted only to addresses that have credentials/authorisation to engage with the market, or further constrained to only move to/from the market itself?
- **Onboarding policy**: what mechanism do you want to use to enable lenders to engage with your market? At present, the options are an explicit address whitelist operated by the borrower, or adopting a [Keyring Network](https://keyring.network)
  policy (substantially on this [here](/using-wildcat/day-to-day-usage/market-access-via-policies-hooks)
  ). If you have a more specific need, reach out to us, and we can very likely produce something for you that we can add to the toolbox for everyone else going forward.

###

[](#market-token-name-prefix)

**Market Token Name Prefix**

The prefix string that the **market token** issued to represent debt will use. For example, if you are borrowing _WETH_ (Wrapped Ether*)* and enter '_Market Maker X_' here, the name of the market token will be _Market Maker X Wrapped Ether_.

###

[](#market-token-symbol-prefix)

**Market Token Symbol Prefix**

The prefix string that the market token issued to represent debt will use. For example, if you are borrowing _WETH_ and enter 'mmx' here, the symbol of the market token will be _mmxWETH_.

###

[](#market-capacity)

**Market Capacity**

This represents the initial **capacity** of the market - the maximum amount of debt that you're willing to pay interest on at launch. Note that depending on what you set the **reserve ratio** as, this does _not_ correspond to the amount that you are able to **borrow** from the market when fully subscribed.

###

[](#reserve-ratio)

**Reserve Ratio (%)**

The percentage of the market **supply** that must remain _within_ the market available for redemption. For example, a market with a capacity of 100,000 tokens, a supply of 20,000 tokens and a reserve ratio of 25% must have 5,000 tokens within the market ready for lenders to withdraw. Wildcat V2 markets allow for this ratio to range between **0 - 100%.** This enables fully uncollateralised markets: however, a borrower will still be expected to maintain a small amount within the market in the event that a protocol fee is active or when withdrawal requests are made. Failing to maintain this level will result in the market becoming **delinquent**. Note that the capacity and the reserve ratio together dictate the _maximum_ that you are able to borrow from a market. A higher reserve ratio leads to a greater amount that you are paying interest on, but provides more of a cushion for lenders to easily exit their position, presuming that you fix delinquencies in a timely manner (lest you incur the _penalty rate_, see below).

###

[](#lender-apr)

**Lender APR (%)**

The amount of interest that you are willing to pay on deposits to _lenders_. This is the rate that will apply presuming that your market never stays delinquent for long enough for the **penalty rate** to activate.

Wildcat V2 markets allow for this value to range between **0 - 100%**. Note that this may not be the true APR that you pay - markets which utilise a [protocol fee](/using-wildcat/protocol-usage-fees)
will add that rate onto the base rate (e.g. selecting a base rate of 10% for a market that includes a 5% protocol fee produces a final rate for the borrower of 10% + (0.05 \* 10%) = 10.5%.

###

[](#penalty-rate)

**Penalty Rate (%)**

The amount of _additional_ APR that you agree to pay in the event that your market becomes [**delinquent**](/using-wildcat/terminology#delinquency)
(i.e. falls below the reserve ratio) and the delinquency is not resolved within the amount of time specified by the [**grace period**](/using-wildcat/terminology#grace-period)
, as observed by the [**grace tracker**](/using-wildcat/terminology#grace-tracker)
.

Wildcat V2 markets allow for this value to range between **0 - 100%**. Note that a penalty rate of zero means that the borrower does not incur a penalty for ignoring delinquency until such time as they are marked as having defaulted (either as defined in a master loan agreement or as might be declared during legal proceedings after an extended period of non-repayment). We encourage borrowers to select a non-zero value to illustrate the seriousness with which they intend to monitor their obligations. This penalty rate is added on to the base rate only for as long as the value of the grace tracker is above that of the grace period.

###

[](#grace-period-length-hours)

**Grace Period Length (Hours)**

The amount of time that a market is permitted to be delinquent for before the penalty APR activates. This parameter is measured in hours, and comes with a corresponding variable called the grace tracker, which measures the amount of time for which the market has been delinquent. The grace period is a _rolling limit_: once delinquency has been cured within a market, the grace tracker will count back down to zero from whatever value it had reached, and any penalty APR that is currently in force will only cease to do so after the grace tracker value is once again below the grace period.

Wildcat V2 markets allow for this value to range between **0 - 2160 hours** (90 days). Note: this means that if a markets grace period is 3 days, and it takes 5 days to cure delinquency, this means that **4** days of penalty APR are paid. **This is important**: a borrower does not necessarily have `grace_period` amount of time to cure each distinct instance of delinquency!

###

[](#withdrawal-cycle-length-hours)

**Withdrawal Cycle Length (Hours)**

The amount of time that a lender who has filed a withdrawal request must wait before they are permitted to claim their assets from the market.

Wildcat V2 markets allow for this value to range between **0 - 8760 hours (365 days)**. This parameter exists in order to fairly distribute assets across multiple lenders given the undercollateralised nature of Wildcat markets. In the event that a significant amount of the supply is recalled at once, a longer withdrawal cycle permits reserves to be handed out _pro rata_ depending on the reserves within the market. For more on how this looks from the lenders perspective, please see the [**Lenders**](/using-wildcat/day-to-day-usage/lenders)
page.

---

Provided that all of these parameters are within range for the market type you are deploying, you will then be asked to submit a transaction which deploys a hooks instance and market contract parameterised as you have directed.

If the template Master Loan Agreement has been selected, the borrower is required to pre-sign a [**Master Loan Agreement**](/using-wildcat/terminology#master-loan-agreement-mla)
. This document is then offered to lenders which seek to deposit to a market after onboarding, binding them to the borrower via contract. It defines certain warranties and covenants, accounts for the mutability of certain parameters and is intended to offer the lender protection via the legal system, as they shoulder the bulk of the risk in a trusted relationship.

[](#sourcing-deposits)

Sourcing Deposits

---

Once a given market is live, lenders can start onboarding to the market, depending on the hooks policy in place. For those markets which make use of an explicit address whitelist, the borrower must make use of the Market Details section of a market page to execute an on-chain transaction specifying one or multiple addresses.

If you wish to make use of a Keyring Network policy to enable lender self-onboarding, you will need to register with Keyring Network off-site and either clone the default Wildcat Keyring policy or create your own. Note: you cannot piggyback off of the Wildcat policy for your markets - you _must_ clone-and-own the policy which you make use of. This is both for compliance reasons and because if you own your policy, you're capable of editing it yourself. If you have any questions here, we're happy to help.

For those markets which make use of an such a Keyring policy, would-be lenders are directed off-site to Keyring to verify they meet the policy requirements, concluding in their submitting a transaction containing a zero-knowledge proof of adherence which will grant them an market access credential.

We defer the decision-making of who is allowed to be onboarded to borrowers, but require that they will not seek to approve lenders either resident in sanctioned nations or those that come with extant regulatory risk preventing interaction with the protocol.

If Wildcat notices that policies are breaching this, we are likely to [offboard](/using-wildcat/day-to-day-usage/borrowers#archcontroller-removal)
the offending borrower, and may opt to remove affected markets from the UI. Crypto is global, and Wildcat isn't going to stand by and watch a borrower reap the whirlwind by allowing non-accredited American retail trader Joe Bloggs to lend them ten thousand dollars.

[](#borrowing-from-a-market)

Borrowing From A Market

---

If we fast forward from here to the stage where lenders have onboarded and deposited assets, we can finally get to the _point_ of all of this: borrowing assets from the market that you have set up.

Remember that the _capacity_ you set for your market only dictates the maximum amount that you are able to source from lenders, and that your _reserve ratio_ will dictate the amount of the _supply_ that you cannot remove from a market.

If you have created a market with a maximum capacity of 1,000,000 USDC and a reserve ratio of 20%, this means you can borrow _up to_ 800,000 USDC provided that the market is 'full' (i.e. _supply_ is equal to _capacity_). In the event where the supply to this market is 600,000 USDC, you can only borrow up to 480,000 USDC.

The process of actually borrowing available assets from a market is simple: navigate to the market details page of your market, and you will be presented with the ability to withdraw assets up to the current reserve ratio. If you've used protocols such as Euler or Aave in the past, you'll be familiar with this.

We strongly advise not borrowing right up to the limit, as the result of this will be that your market becomes delinquent after the very next non-static call which updates the market state and rebases the market token supply.

[](#repaying-a-market)

Repaying A Market

---

The primary mechanic by which funds are recalled by lenders is through **withdrawal requests**, which isolate assets currently in reserve in a market for lenders to claim at the end of a withdrawal cycle (for more details on this, please refer to the [**Lenders**](/using-wildcat/day-to-day-usage/lenders)
page).

Withdrawal requests impact the liquid and required reserves of your market, and as such borrowers are minded to monitor their reserve ratios to determine when funds are being requested. Requests (including who has placed the request and for how much) are also logged within the Market Details page.

The act of repaying is simple in the sense that it just requires moving assets back to the market contract via a standard ERC-20 transfer. Further, _anyone_ can repay assets to the market in this way - we've permitted this in case the borrower address is compromised.

In the event of such an address compromise, all lenders can file withdrawal requests, assets can subsequently be repaid from a third party, and - due to the manner in which withdrawal requests sequester assets during a withdrawal - can be honoured through the market contract without the compromised borrower address being able to access any assets.

[](#reducing-apr)

Reducing APR

---

The interest rate on a market is fixed at any given point in time (i.e. markets do not make use of a utilisation-rate based curve), however the borrower is free to adjust this rate step-wise should they wish, under the following formula:

- Should a borrower wish to increase the APR of a market in order to encourage additional deposits, they are able to do so without constraint.
- Should they wish to decrease the APR, they are able to do so by up to 25% of the current APR in a given two week period: a decrease of more than this requires that twice the amount is returned to the market reserves for that two week period to permit lenders to opt out ('ragequit') if they choose. To illustrate:

  - A borrower can reduce a market APR from 10% to 7.5% with no penalty, and two weeks thereafter will be able to reduce it again to 5.625%, and so on.
  - However, should a borrower reduce a market APR from 10% to 7.4% (a 26% reduction), they will be required to return 52% of the outstanding supply to the market for two weeks. After that time has passed, the reserve ratio will drop back to the prior level and the assets can be borrowed again.

Note that the above only applies if your market is in an 'open-term' setting: i.e. there is no hook enabled which is preventing withdrawals at the time of the proposed change. If this is the case, you will not be able to reduce the APR while that hook is active (otherwise that enables a fairly obvious rug mechanic).

If you're confused by this, ask us directly!

[](#altering-capacity)

Altering Capacity

---

As a borrower, you are able to adjust the capacity up to whatever amount you wish, or down to the market's current outstanding supply of market tokens, however it should be noted that rebasing of market tokens can bring their total supply above such a capacity. Interest accrues on the outstanding supply until such time as lenders reduce the supply through withdrawal requests that burn market tokens. The required reserves of a market remain unchanged regardless of capacity changes.

[](#forced-withdrawals)

Forced Withdrawals

---

A new addition to Wildcat V2 is that a borrower has the ability to eject specific lenders into a withdrawal cycle. We are wary that this ability in effect enables a preferential repayment mechanism whereby they can evacuate a preferred counterparty if they know that they are likely to default in the near future, but this risk is offset by the fact that other lenders are free to join the same withdrawal cycle alongside them. This functionality has been introduced to account for the fact that lenders have the ability to onboard themselves by self-generating an access credential if a policy hook is in place: a borrower may decide that someone that has self-onboarded is not a counterparty they wish to be exposed to.

More generally, this ability resolves an issue within V1 markets where a borrower may have been forced to terminate a market before they were ready because a lender refused to exit their position in order to accrue further interest.

[](#terminating-a-market)

Terminating A Market

---

In the event that a borrower has finished utilising the funds for the purpose that the market was set up to facilitate, the borrower can _terminate_ (close) a market at will.

This is a special case of reducing the APR (with the associated increased reserve rate that accompanies it). When a market is closed, sufficient assets must be repaid to increase the reserve ratio to 100%, after which interest ceases to accrue and _no further parameter adjustment or borrowing is possible_. The only thing possible to do in a closed market is for the lenders to file withdrawal requests and exit via claiming.

Note that the withdrawal cycle period is erased in terminated markets: lenders still have to file two distinct transactions, but if the live market previously had a withdrawal cycle of a week, this duration is not enforced.

[](#archcontroller-removal)

Archcontroller Removal

---

For whatever reason, it may be the case that the Wildcat protocol itself no longer wishes to permit a given borrower to engage further with it. In this case, the address(es) of a borrower can be removed from the archcontroller by its owners. If this happens, the borrower can no longer deploy _new_ hooks instances or markets.

However, they are still capable of interacting with _existing_ markets as before - neither the protocol nor its operators can force these closed. This is because there are likely to be master loan agreements surrounding market usage, and Wildcat having the power to unilaterally step in and sever them would make it a key participant in the arrangement.

[PreviousDay-To-Day Usage](/using-wildcat/day-to-day-usage)
[NextLenders](/using-wildcat/day-to-day-usage/lenders)

Last updated 1 day ago

This page includes details of the structs used within Wildcat V2.

Note: you can generate this yourself via the `calculate_structs.py` Python script in the `/scripts` directory of the repository.

[](#file-src-hooksfactory.sol)

File: /src/HooksFactory.sol

---

###

[](#struct-tmpmarketparameterstorage)

Struct: TmpMarketParameterStorage

address borrower

address asset

address feeRecipient

uint16 protocolFeeBips

uint128 maxTotalSupply

uint16 annualInterestBips

uint16 delinquencyFeeBips

uint32 withdrawalBatchDuration

uint16 reserveRatioBips

uint32 delinquencyGracePeriod

bytes32 packedNameWord0

bytes32 packedNameWord1

bytes32 packedSymbolWord0

bytes32 packedSymbolWord1

uint8 decimals

HooksConfig hooks // note: type HooksConfig is uint256;

[](#file-src-ihooksfactory.sol)

File: /src/IHooksFactory.sol

---

###

[](#struct-hookstemplate)

Struct: HooksTemplate

/// @dev Asset used to pay origination fee

address originationFeeAsset

/// @dev Amount of \`originationFeeAsset\` paid to deploy a new market using

/// an instance of this template.

uint80 originationFeeAmount

/// @dev Basis points paid on interest for markets deployed using hooks

/// based on this template

uint16 protocolFeeBips

/// @dev Whether the template exists

bool exists

/// @dev Whether the template is enabled

bool enabled

/// @dev Index of the template address in the array of hooks templates

uint24 index

/// @dev Address to pay origination and interest fees

address feeRecipient

/// @dev Name of the template

string name

[](#file-src-types-lenderstatus.sol)

File: /src/types/LenderStatus.sol

---

###

[](#struct-lenderstatus)

Struct: LenderStatus

bool isBlockedFromDeposits

bool hasEverDeposited

address lastProvider

bool canRefresh

uint32 lastApprovalTimestamp

[](#file-src-access-marketconstrainthooks.sol)

File: /src/access/MarketConstraintHooks.sol

---

###

[](#struct-temporaryreserveratio)

Struct: TemporaryReserveRatio

uint16 originalAnnualInterestBips

uint16 originalReserveRatioBips

uint32 expiry

[](#file-src-libraries-marketstate.sol)

File: /src/libraries/MarketState.sol

---

###

[](#struct-marketstate)

Struct: MarketState

bool isClosed

uint128 maxTotalSupply

uint128 accruedProtocolFees

// Underlying assets reserved for withdrawals which have been paid

// by the borrower but not yet executed.

uint128 normalizedUnclaimedWithdrawals

// Scaled token supply (divided by scaleFactor)

uint104 scaledTotalSupply

// Scaled token amount in withdrawal batches that have not been

// paid by borrower yet.

uint104 scaledPendingWithdrawals

uint32 pendingWithdrawalExpiry

// Whether market is currently delinquent (liquidity under requirement)

bool isDelinquent

// Seconds borrower has been delinquent

uint32 timeDelinquent

// Annual interest rate accrued to lenders, in basis points

uint16 annualInterestBips

// Percentage of outstanding balance that must be held in liquid reserves

uint16 reserveRatioBips

// Ratio between internal balances and underlying token amounts

uint112 scaleFactor

uint32 lastInterestAccruedTimestamp

###

[](#struct-account)

Struct: Account

uint104 scaledBalance

[](#file-src-libraries-withdrawal.sol)

File: /src/libraries/Withdrawal.sol

---

###

[](#struct-withdrawalbatch)

Struct: WithdrawalBatch

// Total scaled amount of tokens to be withdrawn

uint104 scaledTotalAmount

// Amount of scaled tokens that have been paid by borrower

uint104 scaledAmountBurned

// Amount of normalized tokens that have been paid by borrower

uint128 normalizedAmountPaid

###

[](#struct-accountwithdrawalstatus)

Struct: AccountWithdrawalStatus

uint104 scaledAmount

uint128 normalizedAmountWithdrawn

###

[](#struct-withdrawaldata)

Struct: WithdrawalData

FIFOQueue unpaidBatches

mapping(uint32 => WithdrawalBatch) batches

mapping(uint256 => mapping(address => AccountWithdrawalStatus)) accountStatuses

[](#file-src-libraries-fifoqueue.sol)

File: /src/libraries/FIFOQueue.sol

---

###

[](#struct-fifoqueue)

Struct: FIFOQueue

uint128 startIndex

uint128 nextIndex

mapping(uint256 => uint32) data

[](#file-src-spherex-ispherexengine.sol)

File: /src/spherex/ISphereXEngine.sol

---

###

[](#struct-modifierlocals)

Struct: ModifierLocals

bytes32\[\] storageSlots

bytes32\[\] valuesBefore

uint256 gas

address engine

[](#file-src-interfaces-iwildcatsanctionssentinel.sol)

File: /src/interfaces/IWildcatSanctionsSentinel.sol

---

###

[](#struct-tmpescrowparams)

Struct: TmpEscrowParams

address borrower

address account

address asset

[](#file-src-interfaces-wildcatstructsandenums.sol)

File: /src/interfaces/WildcatStructsAndEnums.sol

---

###

[](#struct-marketparameters)

Struct: MarketParameters

address asset

uint8 decimals

bytes32 packedNameWord0

bytes32 packedNameWord1

bytes32 packedSymbolWord0

bytes32 packedSymbolWord1

address borrower

address feeRecipient

address sentinel

uint128 maxTotalSupply

uint16 protocolFeeBips

uint16 annualInterestBips

uint16 delinquencyFeeBips

uint32 withdrawalBatchDuration

uint16 reserveRatioBips

uint32 delinquencyGracePeriod

address archController

address sphereXEngine

HooksConfig hooks

###

[](#struct-deploymarketinputs)

Struct: DeployMarketInputs

address asset

string namePrefix

string symbolPrefix

uint128 maxTotalSupply

uint16 annualInterestBips

uint16 delinquencyFeeBips

uint32 withdrawalBatchDuration

uint16 reserveRatioBips

uint32 delinquencyGracePeriod

HooksConfig hooks

###

[](#struct-marketcontrollerparameters)

Struct: MarketControllerParameters

address archController

address borrower

address sentinel

address marketInitCodeStorage

uint256 marketInitCodeHash

uint32 minimumDelinquencyGracePeriod

uint32 maximumDelinquencyGracePeriod

uint16 minimumReserveRatioBips

uint16 maximumReserveRatioBips

uint16 minimumDelinquencyFeeBips

uint16 maximumDelinquencyFeeBips

uint32 minimumWithdrawalBatchDuration

uint32 maximumWithdrawalBatchDuration

uint16 minimumAnnualInterestBips

uint16 maximumAnnualInterestBips

address sphereXEngine

###

[](#struct-protocolfeeconfiguration)

Struct: ProtocolFeeConfiguration

address feeRecipient

address originationFeeAsset

uint80 originationFeeAmount

uint16 protocolFeeBips

###

[](#struct-marketparameterconstraints)

Struct: MarketParameterConstraints

uint32 minimumDelinquencyGracePeriod

uint32 maximumDelinquencyGracePeriod

uint16 minimumReserveRatioBips

uint16 maximumReserveRatioBips

uint16 minimumDelinquencyFeeBips

uint16 maximumDelinquencyFeeBips

uint32 minimumWithdrawalBatchDuration

uint32 maximumWithdrawalBatchDuration

uint16 minimumAnnualInterestBips

uint16 maximumAnnualInterestBips

[PreviousWildcatSanctionsSentinel.sol](/technical-overview/function-event-signatures/wildcatsanctionssentinel.sol)
[NextContract Deployments](/technical-overview/contract-deployments)

Last updated 1 day ago

Wildcat has the ability to charge a fee for the usage of its markets.

Once a borrower has been added to the global registry by the archcontroller, they have free reign to deploy markets however they see fit, both in market parameters themselves (e.g. capacity, withdrawal period) and which hooks are in place to gate access.

However, there is one parameter associated with a market that a borrower cannot change: the _protocol fee._ This manifests as a) an origination fee (which must be paid during the deployment of a market), b) a 'streaming' proportion of base APR (which accrues over the supply of assets rather than the capacity), or c) both.

The borrower that deploys a market with a base APR of 10% that has a 5% streaming protocol fee in place will find themselves paying 10.5% (the base APR receivable by lenders plus 5% of that rate). The lender will receive 10% as expected, the rest accrues to the protocol over time.

Decreasing or increasing that APR will similarly adjust the actual protocol fee APR: reducing the base APR to 8% will result in a borrower paying 8.4%.

Protocol fees do _not_ increase in the presence of a penalty APR if a market is delinquent and over the grace period: if a market has a base rate of 10% and is currently paying an additional penalty APR of 20%, the total market APR is 30.5% ((10% + 0.5%) + 20%), _not_ 31.5%.

Protocol fees accrued as part of a market APR are senior to lender claims within a market - a lender who attempts to withdraw all of the reserves within a market will only be capable of removing that amount net any protocol fees that have accrued over time and not been withdrawn. The fee configuration of an active market can be adjusted by the archcontroller owners, and changes are retroactive in V2 markets.

if your market launched with a 0% streaming protocol fee which is subsequently increased to 5%, that fee will start to take effect after the appropriate hook instance contract tied to a market is updated. Any origination fee update will be rendered void for existing markets (since the market exists already!).

In Wildcat V2, streaming protocol fees are **hard-capped at 10% of base APR**.

[PreviousThe Sentinel](/using-wildcat/day-to-day-usage/the-sentinel)
[NextDelinquency](/using-wildcat/delinquency)

Last updated 1 day ago

####

[](#archcontroller)

**Archcontroller**

- Smart contract which doubles up as a registry and permission gate. [Borrowers](/using-wildcat/terminology#borrower)
  are added or removed from the archcontroller by the operators of the protocol itself (granting/rescinding the ability to deploy [hooks](/using-wildcat/terminology#hook)
  and/or [markets](/using-wildcat/terminology#market)
  ), and the addresses of any factories, hooks instances or markets that get deployed through the protocol are stored here.

####

[](#base-apr)

**Base APR**

- The interest rate that lenders receive on [assets](/using-wildcat/terminology#underlying-asset)
  that they have deposited into a particular [market](/using-wildcat/terminology#market)
  , in the absence of the [penalty APR](/using-wildcat/terminology#penalty-apr)
  being enforced.

####

[](#borrow)

**Borrow**

- To withdraw [assets](/using-wildcat/terminology#underlying-asset)
  from a [market](/using-wildcat/terminology#market)
  that has a non-zero [supply](/using-wildcat/terminology#supply)
  and [reserve ratio](/using-wildcat/terminology#reserve-ratio)
  less than 100%, with the intent of repaying the assets (plus any accrued interest) to the market either when the required purpose of using the assets has concluded or as a response to [withdrawal requests](/using-wildcat/terminology#withdrawal-request)
  .

####

[](#borrower)

**Borrower**

- Both:

  - The counterparty that wishes to make use of a credit facility through a Wildcat [market](/using-wildcat/terminology#market)
    , and
  - The blockchain address that defines the parameters of a market and deploys the [hook instances](/using-wildcat/terminology#hooks-instance)
    and market contracts that use them.

####

[](#capacity)

**Capacity**

- Parameter required of [borrower](/using-wildcat/terminology#borrower)
  when creating a new [market](/using-wildcat/terminology#market)
  .
- The `maxTotalSupply` field in the state.
- The _maximum_ amount of an asset that a borrower is looking to source via a market - the threshold for `totalSupply` after which the market will stop accepting [deposits](/using-wildcat/terminology#deposit)
  .
- Can be exceeded by the market's `totalSupply` due to interest accrual.

####

[](#claim)

**Claim**

- Removing [assets](/using-wildcat/terminology#underlying-asset)
  from the [unclaimed withdrawals pool](/using-wildcat/terminology#unclaimed-withdrawals-pool)
  that were requested for withdrawal by a [lender](/using-wildcat/terminology#lender)
  .
- Can only occur after a [withdrawal cycle](/using-wildcat/terminology#withdrawal-cycle)
  expires.
- Note that retrieving your [deposits](/using-wildcat/terminology#deposit)
  from a Wildcat market requires a [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  and _then_ a claim - it is a two transaction process with the conclusion of one withdrawal cycle in between.

####

[](#collateral-obligation)

Collateral Obligation

- The minimum amount of [assets](/using-wildcat/terminology#underlying-asset)
  that the borrower is obligated to keep in the market in order to avoid [delinquency](/using-wildcat/terminology#delinquency)
  .
- The sum of:

  - The [reserves](/using-wildcat/terminology#required-reserves)
    needed to meet the [reserve ratio](/using-wildcat/terminology#reserve-ratio)
    for the [outstanding supply](/using-wildcat/terminology#outstanding-supply)
    ,
  - The market's [unclaimed withdrawals pool](/using-wildcat/terminology#unclaimed-withdrawals-pool)
    ,
  - The normalized value of the market's [pending](/using-wildcat/terminology#pending-withdrawal)
    and [expired](/using-wildcat/terminology#expired-withdrawal)
    withdrawals, and
  - The unclaimed [protocol fees](/using-wildcat/terminology#protocol-apr)
    .

####

[](#delinquency)

**Delinquency**

- A [market](/using-wildcat/terminology#market)
  state wherein there are insufficient [assets](/using-wildcat/terminology#underlying-asset)
  in the market to meet the market's [collateral obligations](/using-wildcat/terminology#collateral-obligation)
  .
- Arises via the passage of time through interest if the borrower borrows right up to their reserve ratio.
- Can also arise if a [lender](/using-wildcat/terminology#lender)
  makes a [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  that exceeds the market's available liquidity.
- A market being delinquent for an extended period of time (as specified by the [grace period](/using-wildcat/terminology#grace-period)
  ) results in the [penalty APR](/using-wildcat/terminology#penalty-apr)
  being enforced in addition to the [base APR](/using-wildcat/terminology#base-apr)
  and any [protocol APR](/using-wildcat/terminology#protocol-apr)
  that may apply.
- 'Cured' by [depositing](/using-wildcat/terminology#deposit)
  sufficient assets into the market as to reattain the required collateral obligation.

####

[](#deposit)

**Deposit**

- Both:

  - The act of sending [assets](/using-wildcat/terminology#underlying-asset)
    as a [lender](/using-wildcat/terminology#lender)
    to a [market](/using-wildcat/terminology#market)
    for the purposes of being [borrowed](/using-wildcat/terminology#borrow)
    by the [borrower](/using-wildcat/terminology#borrower)
    ,
  - The act of sending assets as a borrower to a market for the purposes of being [withdrawn](/using-wildcat/terminology#withdrawal-request)
    by lenders,
  - A term for the lenders' assets themselves once in a market.

####

[](#escrow-contract)

**Escrow Contract**

- An auxiliary smart contract that is deployed in the event that the [sentinel](/using-wildcat/terminology#sentinel)
  detects that a [lender](/using-wildcat/terminology#lender)
  address has been added to a sanctioned list such as the OFAC SDN: this check is performed through the [**Chainalysis oracle**](https://go.chainalysis.com/chainalysis-oracle-docs.html)
  .
- Used to transfer the debt (for the [lender](/using-wildcat/terminology#lender)
  ) and obligation to repay (for the [borrower](/using-wildcat/terminology#borrower)
  ) away from the [market](/using-wildcat/terminology#market)
  contract to avoid wider contamination through interaction. Interest ceases to accrue upon creation and transfer.
- Any [assets](/using-wildcat/terminology#underlying-asset)
  relating to an attempted claim by the affected lender as well as any market tokens tied to their remaining [deposit](/using-wildcat/terminology#deposit)
  are automatically transferred to the escrow contract when blocked (either through an attempt to withdraw or via a call to a 'nuke from orbit' function found within the market).
- Assets can only be released to the lender in the event that a) they are no longer tagged as sanctioned by the Chainalysis oracle, or b) the borrower specifically overrides the sanction.

####

[](#expired-withdrawal)

Expired Withdrawal

- A [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  that could not be fully honoured by [assets](/using-wildcat/terminology#underlying-asset)
  in the [unclaimed withdrawals pool](/using-wildcat/terminology#unclaimed-withdrawals-pool)
  within a single [withdrawal cycle](/using-wildcat/terminology#withdrawal-cycle)
  .

####

[](#grace-period)

**Grace Period**

- Parameter required of [borrower](/using-wildcat/terminology#borrower)
  when creating a new [market](/using-wildcat/terminology#market)
  .
- Rolling period of time for which a market can be [delinquent](/using-wildcat/terminology#delinquency)
  before the [penalty APR](/using-wildcat/terminology#penalty-apr)
  of the market activates.
- Note that the grace period does not 'reset' to zero when delinquency is cured. See [grace tracker](/using-wildcat/terminology#grace-tracker)
  below for details.

####

[](#grace-tracker)

**Grace Tracker**

- Internal [market](/using-wildcat/terminology#market)
  parameter associated with the [grace period](/using-wildcat/terminology#grace-period)
  .
- `timeDelinquent` in the market state.
- Once a market becomes [delinquent](/using-wildcat/terminology#delinquency)
  , begins counting seconds up from zero - when the value of the grace tracker exceeds the grace period, the [penalty APR](/using-wildcat/terminology#penalty-apr)
  activates.
- Once a market is cured of delinquency, begins counting seconds down to zero - the penalty APR continues to apply _until the grace tracker value is below the grace period value_.
- Enforces the rolling nature of the grace period.

####

[](#hook)

**Hook**

- A function on a [hook instance](/using-wildcat/terminology#hook-instance)
  which is executed when a particular action occurs on a [market](/using-wildcat/terminology#market)
  .
- Corresponds to a specific market action, such as the `onCloseMarket` hook which is called when `closeMarket` is called on a market during termination.

####

[](#hook-instance)

**Hook Instance**

- Contract that defines the [hook functions](/using-wildcat/terminology#hook)
  for a market.
- Deployed by an approved borrower as an instance of a particular [hooks template](/using-wildcat/terminology#hooks-template)
  .
- Configured in the market parameters at market deployment.

####

[](#hooks-template)

**Hooks Template**

- A base contract defining behaviour for a kind of [hook contract](/using-wildcat/terminology#hook-instance)
  approved by factory operators.
- Copied when borrowers deploy hook instances.

####

[](#lender)

**Lender**

- Both:

  - A counterparty that wishes to provide a credit facility through a Wildcat [market](/using-wildcat/terminology#market)
    , and
  - The blockchain address associated with that counterparty which [deposits](/using-wildcat/terminology#deposit)
    [assets](/using-wildcat/terminology#underlying-asset)
    to a market for the purposes of being [borrowed](/using-wildcat/terminology#borrow)
    by the [borrower](/using-wildcat/terminology#borrower)
    .

####

[](#liquid-reserves)

Liquid Reserves

- The amount of [underlying assets](/using-wildcat/terminology#underlying-asset)
  currently counting towards the [market](/using-wildcat/terminology#market)
  's [required reserves](/using-wildcat/terminology#required-reserves)
  .
- Comprises the liquidity that can be made available for new [withdrawals](/using-wildcat/terminology#withdrawal-request)
  .
- Is equal to the total assets in the market minus the [unclaimed withdrawals](/using-wildcat/terminology#unclaimed-withdrawals-pool)
  , [pending withdrawals](/using-wildcat/terminology#pending-withdrawal)
  , [expired withdrawals](/using-wildcat/terminology#expired-withdrawal)
  and accrued [protocol fees](/using-wildcat/terminology#protocol-apr)
  .

####

[](#market)

**Market**

- Smart contract that accepts [underlying assets](/using-wildcat/terminology#underlying-asset)
  , issuing [market tokens](/using-wildcat/terminology#market-token)
  in return.
- Deployed by [borrower](/using-wildcat/terminology#borrower)
  through the factory.
- Holds assets in escrow pending either being [borrowed](/using-wildcat/terminology#borrow)
  by the borrower or [withdrawn](/using-wildcat/terminology#withdrawal-request)
  by a [lender](/using-wildcat/terminology#lender)
  .
- Permissioned: only lenders that have been obtained a credential authorising them to deposit (either through explicit whitelisting or another access provider via hooks) can interact.

####

[](#market-token)

**Market Token**

- ERC-20 token indicating a [claim](/using-wildcat/terminology#claim)
  on the [underlying assets](/using-wildcat/terminology#underlying-asset)
  in a [market](/using-wildcat/terminology#market)
  .
- Issued to [lenders](/using-wildcat/terminology#lender)
  after a [deposit](/using-wildcat/terminology#deposit)
  .
- [Supply](/using-wildcat/terminology#supply)
  rebases after every non-static call to the market contract depending on the total current APR of the market.
- Can only be redeemed by authorised lender addresses (not necessarily the same one that received the market tokens initially).
- Name and symbol prefixes are customisable in market creation, prepending to the name and symbol of the underlying asset.

####

[](#outstanding-supply)

Outstanding Supply

- The amount of [market tokens](/using-wildcat/terminology#market-token)
  not currently queued for [withdrawal](/using-wildcat/terminology#withdrawal-request)
  .
- Equal to the market's [supply](/using-wildcat/terminology#supply)
  minus its [pending](/using-wildcat/terminology#pending-withdrawal)
  and [expired](/using-wildcat/terminology#expired-withdrawal)
  withdrawals.

####

[](#penalty-apr)

**Penalty APR**

- Parameter required of [borrower](/using-wildcat/terminology#borrower)
  when creating a new [market](/using-wildcat/terminology#market)
  .
- Additional interest rate (above and beyond the [base APR](/using-wildcat/terminology#base-apr)
  and any [protocol APR](/using-wildcat/terminology#protocol-apr)
  ) that is applied for as long as the [grace tracker](/using-wildcat/terminology#grace-tracker)
  value for a market is in excess of the specified [grace period](/using-wildcat/terminology#grace-period)
  .
- Encourages borrower to responsibly monitor the [reserve ratio](/using-wildcat/terminology#reserve-ratio)
  of a market.
- No part of the penalty APR is receivable by the Wildcat protocol itself (does not inflate the protocol APR if present).

####

[](#pending-withdrawal)

**Pending Withdrawal**

- A [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  that has not yet [expired](/using-wildcat/terminology#expired-withdrawal)
  (i.e. was created in the current [withdrawal cycle](/miscellaneous/deprecated-documentation/component-overview/wildcat-market-overview/wildcatmarketwithdrawals.sol#processunpaidwithdrawalbatch)
  ).

####

[](#protocol-apr)

Protocol APR

- Percentage of [base APR](/using-wildcat/terminology#base-apr)
  that accrues to the Wildcat protocol itself.
- Parameter configured by the factory operator for each [hooks template](/using-wildcat/terminology#hooks-template)
  , applying to all [markets](/using-wildcat/terminology#market)
  deployed with an instance of said template.
- Can be zero.
- Does not increase in the presence of an active [penalty APR](/using-wildcat/terminology#penalty-apr)
  (which only increases the APR accruing to [lenders](/using-wildcat/terminology#lender)
  ).
- Example: market with base APR of 10% and protocol APR of 20% results in borrower paying 12% when penalty APR is not active.

####

[](#required-reserves)

Required Reserves

- Amount of [underlying assets](/using-wildcat/terminology#underlying-asset)
  that must be made available for new withdrawals according to the configured [reserve ratio](/using-wildcat/terminology#reserve-ratio)
  .
- Equal to the reserve ratio times the [outstanding supply](/using-wildcat/terminology#outstanding-supply)
  .

####

[](#reserve-ratio)

**Reserve Ratio**

- Parameter required of [borrower](/using-wildcat/terminology#borrower)
  when creating a new [market](/using-wildcat/terminology#market)
  .
- Percentage of current [outstanding supply](/using-wildcat/terminology#outstanding-supply)
  that must be kept in the market (but still accrue interest).
- Intended to provide a liquid buffer for [lenders](/using-wildcat/terminology#lender)
  to make [withdrawal requests](/using-wildcat/terminology#withdrawal-request)
  against, partially 'collateralising' the credit facility through lenders' deposits.
- Increases temporarily when a borrower reduces the [base APR](/using-wildcat/terminology#base-apr)
  of a [market](/using-wildcat/terminology#market)
  (fixed-term increase).
- A market which has insufficient assets in the market to meet the reserve ratio is said to be [delinquent](/using-wildcat/terminology#delinquency)
  , with the [penalty APR](/using-wildcat/terminology#penalty-apr)
  potentially being enforced if the delinquency is not cured before the [grace tracker](/using-wildcat/terminology#grace-tracker)
  value exceeds that of the [grace period](/using-wildcat/terminology#grace-period)
  for that particular market.

####

[](#sentinel)

**Sentinel**

- Smart contract that ensures that addresses which interact with the protocol are not flagged by the [**Chainalysis oracle**](https://go.chainalysis.com/chainalysis-oracle-docs.html)
  for sanctions.
- Can deploy escrow contracts to excise a [lender](/using-wildcat/terminology#lender)
  flagged by the oracle from a wider [market](/using-wildcat/terminology#market)
  .

####

[](#supply)

**Supply**

- Current amount of [underlying asset](/using-wildcat/terminology#underlying-asset)
  [deposited](/using-wildcat/terminology#deposit)
  in a [market](/using-wildcat/terminology#market)
  .
- Tied 1:1 with the supply of [market tokens](/using-wildcat/terminology#market-token)
  (rate of growth APR dependent).
- Can only be reduced by burning market tokens as part of a [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  or [claim](/using-wildcat/terminology#claim)
  .
- [Reserve ratios](/using-wildcat/terminology#reserve-ratio)
  are enforced against the supply of a market, _not_ its [capacity](/using-wildcat/terminology#capacity)
  .
- Capacity can be reduced below current supply by a [borrower](/using-wildcat/terminology#borrower)
  , but this only prevents the further deposit of assets until the supply is once again below capacity.

####

[](#unclaimed-withdrawals-pool)

**Unclaimed Withdrawals Pool**

- A sequestered pool of [underlying assets](/using-wildcat/terminology#underlying-asset)
  which are pending their [claim](/using-wildcat/terminology#claim)
  by [lenders](/using-wildcat/terminology#lender)
  following a [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  .
- Assets are moved from market reserves to the unclaimed withdrawals pool by burning [market tokens](/using-wildcat/terminology#market-token)
  at a 1:1 ratio (reducing the [supply](/using-wildcat/terminology#supply)
  of the market).
- Assets within the unclaimed withdrawals pool do not accrue interest, but similarly cannot be [borrowed](/using-wildcat/terminology#borrow)
  by the [borrower](/using-wildcat/terminology#borrower)
  - they are considered out of reach.

####

[](#underlying-asset)

**Underlying Asset**

- Parameter required of [borrower](/using-wildcat/onboarding#borrowers)
  when creating a new [market](/using-wildcat/terminology#market)
  .
- The asset which the borrower is seeking to [borrow](/using-wildcat/terminology#borrow)
  by deploying a market - for example DAI (Dai Stablecoin) or WETH (Wrapped Ether).
- Can be _any_ ERC-20 token.

####

[](#withdrawal-cycle)

**Withdrawal Cycle**

- Parameter required of [borrower](/using-wildcat/terminology#borrower)
  when creating a new [market](/using-wildcat/terminology#market)
  .
- Period of time that must elapse between the first [withdrawal request](/using-wildcat/terminology#withdrawal-request)
  of a 'wave' of withdrawals and [assets](/using-wildcat/terminology#underlying-asset)
  in the [unclaimed withdrawals pool](/using-wildcat/terminology#unclaimed-withdrawals-pool)
  being made available to [claim](/using-wildcat/terminology#claim)
  .
- Withdrawal cycles do not work on a rolling basis - at the end of one withdrawal cycle, the next cycle will not start until the next withdrawal request.
- In the event that the amount being claimed in the same cycle across all lenders is in excess of the reserves currently within a market, all [lenders](/using-wildcat/terminology#lender)
  requests within that cycle will be honoured _pro rata_ depending on overall amount requested.
- Intended to prevent a run on a given market (mass withdrawal requests) leading to slower lenders receiving nothing.
- Can have a value of zero, in which case each withdrawal request is processed - and potentially added to the [withdrawal queue](/using-wildcat/terminology#withdrawal-queue)
  - as a standalone batch.

####

[](#withdrawal-queue)

**Withdrawal Queue**

- Internal data structure of a [market](/using-wildcat/terminology#market)
  .
- All [withdrawal requests](/using-wildcat/terminology#withdrawal-request)
  that could not be fully honoured at the end of their [withdrawal cycle](/using-wildcat/terminology#withdrawal-cycle)
  are batched together, marked as [expired](/using-wildcat/terminology#expired-withdrawal)
  and added to the withdrawal queue.
- Tracks the order and amounts of [lender](/using-wildcat/terminology#lender)
  [claims](/using-wildcat/terminology#claim)
  .
- FIFO (First-In-First-Out): when [assets](/using-wildcat/day-to-day-usage/lenders)
  are returned to a market which has a non-zero withdrawal queue, assets are immediately routed to the [unclaimed withdrawals pool](/using-wildcat/terminology#unclaimed-withdrawals-pool)
  and can subsequently be claimed by lenders with the oldest expired withdrawals first.

####

[](#withdrawal-request)

Withdrawal Request

- An instruction to a [market](/using-wildcat/terminology#market)
  to transfer reserves within a market to the [unclaimed withdrawals pool](/using-wildcat/terminology#unclaimed-withdrawals-pool)
  , to be [claimed](/using-wildcat/terminology#claim)
  at the end of a [withdrawal cycle](/using-wildcat/terminology#withdrawal-cycle)
  .
- A withdrawal request made of a market with non-zero reserves will burn as many [market tokens](/using-wildcat/terminology#market-token)
  as possible 1:1 to fully honour the request.
- Any amount requested - whether or not it is in excess of the market reserves - is marked as a [pending withdrawal](/using-wildcat/terminology#pending-withdrawal)
  , either to be fully honoured at the end of the cycle, or marked as [expired](/using-wildcat/terminology#expired-withdrawal)
  and added to the [withdrawal queue](/using-wildcat/terminology#withdrawal-queue)
  , depending on the actions of the [borrower](/using-wildcat/terminology#borrower)
  during the cycle.

[PreviousFAQs](/overview/faqs)
[NextOnboarding](/using-wildcat/onboarding)

Last updated 2 days ago
