# The Wildcat Protocol

Mr Anderson, welcome back. We missed you.

[![The Wildcat Protocol](https://github.com/code-423n4/2024-08-wildcat/blob/overview-edits/images/wildcat_logo.png?raw=true)](https://github.com/code-423n4/2024-08-wildcat)

# Wildcat V2 Audit Details
- Total Prize Pool: $100,000 in USDC
  - HM awards: $66,720 in USDC
  - Z Pool (Zenith side pool): $20,000 in USDC
  - QA awards: $2,780 in USDC
  - Judge awards: $6,000 in USDC
  - Validator awards: 4,000 USDC 
  - Scout awards: $500 in USDC
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts August 31, 2024 20:00 UTC
- Ends September 18, 2024 20:00 UTC

**Z Pool and Dark Horse Bonus Pool**
- This audit includes two [Zenith](https://code4rena.com/zenith) Researchers (ZRs), who are designated as leads for the audit ("LZRs").
- Dark Horse wardens earn a portion of the Z pool by outperforming (or tying) the top-ranked LZR auditor based on [Gatherer score](https://docs.code4rena.com/awarding/incentive-model-and-awards#bonuses-for-top-competitors). 
- For more details, see [Z Pool / Dark Horse bonus pool distribution rules](https://docs.code4rena.com/roles/certified-contributors)

# Overview

### The Pitch

The Wildcat Protocol is an Ethereum protocol that addresses what we see as blockers in the sphere of on-chain fixed-rate private credit.

If you're interested in the _how_ and _why_ at a high-level, the following will be of interest to you:

- [Gitbook](https://docs.wildcat.finance)
- [Launch Manifesto](https://medium.com/@wildcatprotocol/the-wildcat-manifesto-db23d4b9484d)
- [Medium: Wildcat V2 - Wildcat But Better](https://medium.com/@wildcatprotocol/wildcat-v2-wildcat-but-better-156005da2c27)

The Gitbook contains several high-level explanations of how users are expected to make use of the protocol, so reading it is heavily recommended.

Wildcat's product is _markets_. They're credit escrow mechanisms where nearly every single parameter that you'd be interested in modifying can be modified at launch.

Moreover, certain other parameters (access control for lender self-onboarding, minimum deposit amounts, fixed duration markets etc) can be adjusted in V2 by way of constraining access through _pre-transaction hooks_. Some hooks - such as those relating to access control - permit borrowers to add or remove provider contracts after deployment in order to fine-tune ways for lenders to obtain access-granting credentials.

Wildcat inverts the typical on-chain credit model whereby borrowers appeal to an existing pool of lenders willing to loan their assets. Instead, a Wildcat borrower crafts their market/s the way that best suits them and would-be lenders engage thereafter.

We handle collateralisation differently to most credit protocols. The borrower is not required to put any collateral down themselves when deploying a market, but rather there is a configurable percentage of the outstanding supply, the reserve ratio, that _must_ remain within the market. The borrower cannot utilise these assets, but they still accrue interest. This is intended as a liquid buffer for lenders to place withdrawal requests against, and the failure of the borrower to maintain this ratio (by repaying assets to the market when the ratio is breached) ultimately results in an additional penalty interest rate being applied. If you're wondering, 'wait, does that mean that lenders are collateralising their own loans?', the answer is _yes, they absolutely are_. Moreover, the reserve ratio in Wildcat V2 can be zero, enabling truly uncollateralised markets (modulo the presence of any protocol fees or withdrawal requests).

The protocol itself is entirely hands-off when it comes to any given market. It has no ability to freeze or seize borrower collateral (since there isn't any), it can't force a borrower to repay assets to a market, and it can't stop the borrower from making APR/capacity changes provided that they're within the bounds set by the market constraint hooks. As an ideological choice, Wildcat does not make use of proxies, and markets are therefore non-upgradable. If keys are lost or if anything else goes wrong in the contracts, the protocol cannot help, and this requires us to take security extremely seriously. It's why you're reading this right now.

The protocol monitors for addresses that are flagged by the Chainalysis oracle as being placed on a sanctions list and bars them from interacting with markets.

### A More Technical Briefing

The Wildcat protocol itself coalesces around a single contract - the [archcontroller](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/WildcatArchController.sol). This contract determines which factories can be used, which markets have already been deployed and which addresses are permitted to deploy hook instances and market contracts from said factories.

Borrowers deploy V2 markets through the [hooks factory](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/HooksFactory.sol), either deploying a new hook instance parameterised the way they wish (cloning an authorised hooks template contract approved by the archcontroller owners) or referencing an existing hook instance. Lenders can obtain access by receiving a credential via an access control hook, which may have one or many providers (for more on this, see [here](https://github.com/code-423n4/2024-08-wildcat/blob/main/docs/hooks/templates/Access%20Control%20Hooks.md)).

Lenders can deposit assets to any markets they have a credential for so long as it has not expired, and lenders that have deposited or received market tokens while having a valid credential are always capable of filing withdrawal requests. In exchange for their deposits, they receive a _market token_ which has been parameterised by the borrower: you might receive Code4rena Dai Stablecoin - ticker c4DAI - for depositing DAI into a market run by Code4rena. Or C4 Wrapped Ether (code423n4WETH).

These market tokens are _rebasing_ so as to always be redeemable at parity for the underlying asset of a market (provided it has sufficient liquid reserves) - as time goes on, interest inflates the supply of market tokens to be consistent with the overall debt that is owed by the borrower. The interest rate compounds every time a non-static call is made to the market contract and the scale factor is updated.

The interest rate paid by the borrower can comprise of up to three distinct figures:

  - The base APR (accruing to the lender, expressed in bips when a market is deployed),
  - The protocol fee APR (accruing to the Wildcat protocol itself, expressed in bips as a fraction of the base APR), and
  - The penalty APR (accruing to the lender, expressed in bips when a market is deployed).

A borrower deploying a market with a base APR of 10%, a protocol APR of 5% and a penalty APR of 20% will pay a true APR of 10.5% (10% + (10% * 5%)) under normal circumstances, and 30.5% when the market has been delinquent for long enough for the penalty APR to activate. The protocol APR percentage doesn't factor in penalty APRs even while they're active.

The penalty APR is activated by updating the state of the market when the market has been delinquent (has insufficient reserves to meet its obligations) for a rolling period of time in excess of the _grace period_ - a value (in seconds) defined by the borrower on market deployment. Each market has an internal value called the _grace tracker_, which counts up from zero while a market is delinquent, and counts down to zero when it is not. When the grace tracker value exceeds the grace period, the penalty APR applies for as long as it takes for the former to drop back below the latter and the state to be updated again. This means that a borrower does _not_ have the amount of time indicated by the grace period to deposit assets back into the market every single time it goes delinquent: it is context dependent.

Borrowers can withdraw underlying assets from the market only so far as the minimum number of required reserves is maintained.

Subsequent to launch, base APR and capacities can be adjusted by the borrower at will, with some caveats on reducing the former that effectively constitutes a ragequit option for lenders if they disagree with the change. Base APRs (that which accrues to lenders) can be adjusted after market deployment, but there are constraints in place: borrowers must return a non-trivial amount of the outstanding supply to the market as required reserves if the APR is reduced by more than 25% in a two week period, and capacity can only be reduced to a maximum of the current outstanding supply.

Withdrawals are initiated by any authorised address (that holds a non-zero amount of the appropriate market token) placing a withdrawal request. If there are any assets in reserve, market tokens will be burned 1:1 to move them into a 'claimable withdrawals pool', at which point the assets transferred will cease accruing interest. At the conclusion of a withdrawal cycle (a market parameter set at deployment), assets in the claimable withdrawals pool can be claimed by the lender, subject to pro-rata dispersal if the amount requested for withdrawal by all lenders exceeds the amount in the pool. 

Withdrawal request amounts that could not be honoured in a given cycle because of insufficient reserves are batched together, marked as 'expired' and enter a FIFO withdrawal queue. Non-zero withdrawal queues impact the reserve ratio of a market: any assets subsequently deposited by the borrower will be immediately routed into the claimable withdrawals pool until there are sufficient assets to fully honour all expired withdrawals. Any amounts in the claimable withdrawals pool that lender/s did not burn market tokens for will need to have them burned before claiming from here. We track any discrepancies between how much was burned and how much should be claimable internally.

This is getting long and rambling, so instead we'll direct you to the [Gitbook](https://docs.wildcat.finance) which is even more so, but at least lays out the expected behaviour in prose. Again, we *strongly* recommend that you read it. We'll have a freeze in place for the [Known Issues](https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues) page so that we can't juke wardens by adding things retroactively.

Sorry for subjecting you to all of this. You can go look at the code now.

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-08-wildcat/blob/main/4naly3er-report.md).

_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

- Please see: `/docs/Known Issues.md` in this repo (also available on Gitbook [here](https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues)).

- If you file a finding about the Sherlock `CREATE2` collision malarkey we will sell piñatas with your Discord handle on them as merch.

- We are on our hands and knees begging you to read [this](https://github.com/code-423n4/2024-08-wildcat/blob/main/docs/Scale%20Factor.md) before you file a finding about the scale factor.
  - If you file one anyway, we will pay [Shizzy](https://x.com/ShizzyAizawa) to turn you into a wojak for our Telegram sticker pack. Trust us, this isn't a reward.

## Links

- **Previous Audits:**  [Previous Review of V2 Codebase](https://hackmd.io/@geistermeister/BJk4Ekt90)

[![The Wildcat Protocol](https://github.com/code-423n4/2024-08-wildcat/blob/overview-edits/images/wildcat_firsttime.jpeg?raw=true)](https://github.com/code-423n4/2024-08-wildcat)

The fundamental core of the protocol (V1) has previously been audited by Code4rena:
* https://code4rena.com/contests/2023-10-the-wildcat-protocol
* https://hackmd.io/@geistermeister/r15gj_y1p

- **Documentation:** https://docs.wildcat.finance/
- **Website:** https://wildcat.finance/
- **X/Twitter:** [@WildcatFi](https://x.com/WildcatFi)
---

# Scope

*See [scope.txt](https://github.com/code-423n4/2024-08-wildcat/blob/main/scope.txt)*

### Files In Scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| [/src/HooksFactory.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/HooksFactory.sol) | 1| **** | 391 | ||
| [/src/ReentrancyGuard.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/ReentrancyGuard.sol) | 1| **** | 40 | ||
| [/src/WildcatArchController.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/WildcatArchController.sol) | 1| **** | 271 | |openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>solady/auth/Ownable.sol|
| [/src/WildcatSanctionsEscrow.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/WildcatSanctionsEscrow.sol) | 1| **** | 33 | ||
| [/src/WildcatSanctionsSentinel.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/WildcatSanctionsSentinel.sol) | 1| **** | 68 | ||
| [/src/access/AccessControlHooks.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/access/AccessControlHooks.sol) | 1| **** | 450 | ||
| [/src/access/FixedTermLoanHooks.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/access/FixedTermLoanHooks.sol) | 1| **** | 485 | ||
| [/src/access/MarketConstraintHooks.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/access/MarketConstraintHooks.sol) | 1| **** | 180 | ||
| [/src/libraries/MarketState.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/libraries/MarketState.sol) | 1| **** | 71 | ||
| [/src/libraries/LibStoredInitCode.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/libraries/LibStoredInitCode.sol) | 1| **** | 99 | ||
| [/src/market/WildcatMarket.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/market/WildcatMarket.sol) | 1| **** | 169 | ||
| [/src/market/WildcatMarketBase.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/market/WildcatMarketBase.sol) | 1| **** | 454 | ||
| [/src/market/WildcatMarketConfig.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/market/WildcatMarketConfig.sol) | 1| **** | 81 | ||
| [/src/market/WildcatMarketToken.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/market/WildcatMarketToken.sol) | 1| **** | 51 | ||
| [/src/market/WildcatMarketWithdrawals.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/market/WildcatMarketWithdrawals.sol) | 1| **** | 183 | ||
| [/src/types/HooksConfig.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/types/HooksConfig.sol) | 1| **** | 560 | ||
| [/src/types/LenderStatus.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/types/LenderStatus.sol) | 1| **** | 30 | ||
| [/src/types/RoleProvider.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/types/RoleProvider.sol) | 1| **** | 81 | ||
| [/src/types/TransientBytesArray.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/types/TransientBytesArray.sol) | 1| **** | 87 | ||
| **Totals** | **19** | **** | **3784** | | |


### Files Out Of Scope

*See [out_of_scope.txt](https://github.com/code-423n4/2024-08-wildcat/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./script/LibDeployment.sol |
| ./src/IHooksFactory.sol |
| ./src/access/IHooks.sol |
| ./src/access/IRoleProvider.sol |
| ./src/interfaces/IChainalysisSanctionsList.sol |
| ./src/interfaces/IERC20.sol |
| ./src/interfaces/IMarketEventsAndErrors.sol |
| ./src/interfaces/ISphereXProtectedRegisteredBase.sol |
| ./src/interfaces/IWildcatArchController.sol |
| ./src/interfaces/IWildcatSanctionsEscrow.sol |
| ./src/interfaces/IWildcatSanctionsSentinel.sol |
| ./src/interfaces/WildcatStructsAndEnums.sol |
| ./src/libraries/BoolUtils.sol |
| ./src/libraries/Errors.sol |
| ./src/libraries/FIFOQueue.sol |
| ./src/libraries/FeeMath.sol |
| ./src/libraries/FunctionTypeCasts.sol |
| ./src/libraries/LibERC20.sol |
| ./src/libraries/MarketErrors.sol |
| ./src/libraries/MarketEvents.sol |
| ./src/libraries/MathUtils.sol |
| ./src/libraries/SafeCastLib.sol |
| ./src/libraries/StringQuery.sol |
| ./src/libraries/Withdrawal.sol |
| ./src/spherex/ISphereXEngine.sol |
| ./src/spherex/SphereXConfig.sol |
| ./src/spherex/SphereXProtectedErrors.sol |
| ./src/spherex/SphereXProtectedEvents.sol |
| ./src/spherex/SphereXProtectedRegisteredBase.sol |
| ./test/BaseMarketTest.sol |
| ./test/EscrowTest.sol |
| ./test/HooksFactory.t.sol |
| ./test/HooksIntegration.t.sol |
| ./test/InvariantTests.sol |
| ./test/LogTest.sol |
| ./test/ReentrancyGuard.t.sol |
| ./test/SentinelTest.sol |
| ./test/WildcatArchController.t.sol |
| ./test/WildcatArchControllerIntegration.t.sol |
| ./test/access/AccessControlHooks.t.sol |
| ./test/access/FixedTermLoanHooks.t.sol |
| ./test/handlers/BaseHandler.sol |
| ./test/handlers/ERC20Handler.sol |
| ./test/helpers/AddressSet.sol |
| ./test/helpers/Assertions.sol |
| ./test/helpers/BaseERC20Test.sol |
| ./test/helpers/ExpectedBalances.sol |
| ./test/helpers/ExpectedStateTracker.sol |
| ./test/helpers/Labeler.sol |
| ./test/helpers/Metrics.sol |
| ./test/helpers/PRNG.sol |
| ./test/helpers/StandardStructs.sol |
| ./test/helpers/VmUtils.sol |
| ./test/helpers/fuzz/AccessControlHooksFuzzContext.sol |
| ./test/helpers/fuzz/MarketConfigFuzzInputs.sol |
| ./test/helpers/fuzz/MarketStateFuzzInputs.sol |
| ./test/libraries/FIFOQueue.t.sol |
| ./test/libraries/FeeMath.t.sol |
| ./test/libraries/LibStoredInitCode.t.sol |
| ./test/libraries/MarketState.t.sol |
| ./test/libraries/MathUtils.t.sol |
| ./test/libraries/SafeCastLib.t.sol |
| ./test/libraries/StringQuery.t.sol |
| ./test/libraries/Withdrawal.t.sol |
| ./test/libraries/wrappers/FIFOQueueLibExternal.sol |
| ./test/libraries/wrappers/FeeMathExternal.sol |
| ./test/libraries/wrappers/LibStoredInitCodeExternal.sol |
| ./test/libraries/wrappers/MarketStateLibExternal.sol |
| ./test/libraries/wrappers/MathUtilsExternal.sol |
| ./test/libraries/wrappers/SafeCastLibExternal.sol |
| ./test/libraries/wrappers/WithdrawalLibExternal.sol |
| ./test/market/WildcatMarket.t.sol |
| ./test/market/WildcatMarketBase.t.sol |
| ./test/market/WildcatMarketConfig.t.sol |
| ./test/market/WildcatMarketToken.t.sol |
| ./test/market/WildcatMarketWithdrawals.t.sol |
| ./test/shared/Test.sol |
| ./test/shared/TestConstants.sol |
| ./test/shared/mocks/AlwaysAuthorizedRoleProvider.sol |
| ./test/shared/mocks/MockAccessControlHooks.sol |
| ./test/shared/mocks/MockChainalysis.sol |
| ./test/shared/mocks/MockERC20.sol |
| ./test/shared/mocks/MockEngine.sol |
| ./test/shared/mocks/MockFixedTermLoanHooks.sol |
| ./test/shared/mocks/MockHookCaller.sol |
| ./test/shared/mocks/MockHooks.sol |
| ./test/shared/mocks/MockRoleProvider.sol |
| ./test/shared/mocks/MockSanctionsSentinel.sol |
| ./test/spherex/SphereXConfig.t.sol |
| ./test/types/HooksConfig.t.sol |
| ./test/types/LenderStatus.t.sol |
| ./test/types/RoleProvider.t.sol |
| ./test/types/TransientBytesArray.t.sol |
| Totals: 93 |

## Scoping Q &amp; A

### General Questions


| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| ERC20 used by the protocol              | ERC-20s used as underlying assets for markets require no fee on transfer, `totalSupply` to be not at all close to 2^128, arbitrary mint/burn must not be possible, and `name`, `symbol` and `decimals` must all return valid results (for name and symbol, either bytes32 or a string). Creating markets for rebasing tokens breaks the underlying interest rate model.      |
| Test coverage                           | Lines: 79.64% - Functions: 84.05%                          |
| ERC721 used  by the protocol            |            None              |
| ERC777 used by the protocol             |           None                |
| ERC1155 used by the protocol            |              None             |
| Chains the protocol will be deployed on | Ethereum, Base, Arbitrum, Polygon |

### ERC20 Token Behaviors In Scope

| Question                                                                                                                                                   | Answer |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| [Missing return values](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#missing-return-values)                                                      |   In scope  |
| [Fee on transfer](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#fee-on-transfer)                                                                  |  Out of scope  |
| [Balance changes outside of transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops) | In scope    |
| [Upgradeability](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#upgradable-tokens)                                                                 |   In scope  |
| [Flash minting](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#flash-mintable-tokens)                                                              | Out of scope    |
| [Pausability](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens)                                                                      | Out of scope    |
| [Approval race protections](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#approval-race-protections)                                              | Out of scope    |
| [Revert on approval to zero address](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-approval-to-zero-address)                            | Out of scope    |
| [Revert on zero value approvals](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-approvals)                                    | Out of scope    |
| [Revert on zero value transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-transfers)                                    | Out of scope    |
| [Revert on transfer to the zero address](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-transfer-to-the-zero-address)                    | Out of scope    |
| [Revert on large approvals and/or transfers](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-large-approvals--transfers)                  | Out of scope    |
| [Doesn't revert on failure](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#no-revert-on-failure)                                                   |  Out of scope   |
| [Multiple token addresses](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#multiple-token-addresses)                                                | Out of scope    |
| [Low decimals ( < 6)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#low-decimals)                                                                 |   Out of scope  |
| [High decimals ( > 18)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#high-decimals)                                                              | Out of scope    |
| [Blocklists](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#tokens-with-blocklists)                                                                | In scope    |

### External Integrations (e.g., Uniswap) Behavior In Scope:


| Question                                                  | Answer |
| --------------------------------------------------------- | ------ |
| Enabling/disabling fees (e.g. Blur disables/enables fees) | No   |
| Pausability (e.g. Uniswap pool gets paused)               |  No   |
| Upgradeability (e.g. Uniswap gets upgraded)               |   No  |


### EIP Compliance 
N/A


# Additional Context

## Main Invariants

Properties that should NEVER be broken under any circumstance:

**Arch Controller**

- Borrowers can only be registered with the archcontroller by the archcontroller owner.

- Markets and hook instances can only be deployed by borrowers currently registered with the archcontroller.

**Markets using `AccessControlHooks`**

- The market parameters should never be able to exit the bounds defined in `MarketConstraintHooks`.

- Accounts which are blocked from deposits, or which do not have a credential on markets which require it for deposits, should never be able to mint market tokens.

- Accounts which are flagged as sanctioned on Chainalysis should never be able to successfully modify the state of the market unless the borrower specifically overrides their sanctioned status in the sentinel (other than token approvals, or through their tokens being withdrawn & escrowed in nukeFromOrbit and executeWithdrawal).

**All Markets**

- Underlying assets held by a market can only be transferred out through borrows, withdrawal execution or collection of protocol fees.
  - Does not apply to other assets, which can be recovered by the borrower.

- Underlying assets transferred to a market outside of a deposit are treated as a payment by the borrower, i.e. they do not mint new market tokens or otherwise affect internal accounting other than by increasing `totalAssets`.

- A deposit should never be able to cause a market's total supply to exceed its `maxTotalSupply` in the same transaction.
  - It can exceed it in the next block after interest is accrued.
  - This excludes negligible amounts from the rounding error involved in normalizing the new scaled supply.

- Withdrawal execution can only transfer assets that have been counted as paid assets in the corresponding batch.
  - The sum of all transfer amounts for withdrawal executions in a batch must be less than or equal to `batch.normalizedAmountPaid`

- Lenders in a withdrawal batch always receive a pro-rata share of the assets paid to the batch, proportional to the number of scaled tokens they locked in that withdrawal batch (rounding error dust must only reduce the amount paid to lenders).

- Once assets have been set aside for a withdrawal batch (counted toward `state.normalizedUnclaimedWithdrawals` and `batch.normalizedAmountPaid`), they can only be used for that purpose (i.e. the market will always maintain at least that amount in underlying assets until lenders with a request from that batch have withdrawn the assets).
  - Related: `state.normalizedUnclaimedWithdrawals` must always equal the sum of all withdrawal batches' `normalizedAmountPaid` minus the sum of all transfer amounts paid to batches (and the sum of all rounding errors accumulated when calculating pro-rata withdrawal amounts).

- In any non-static function which touches a market's state:

  * Prior to executing the function's logic, if time has elapsed since the last update, interest, protocol fees and delinquency fees should be accrued to the market state and pending/expired withdrawal batches should be processed.

  * At the end of the function, the updated state is written to storage and the market's delinquency status is updated.

  * Assets are only paid to newer withdrawal batches if the market has sufficient assets to close older batches.



## Attack Ideas (Where To Focus For Bugs)

[![The Wildcat Protocol](https://github.com/code-423n4/2024-08-wildcat/blob/overview-edits/images/wildcat_nolows.png?raw=true)](https://github.com/code-423n4/2024-08-wildcat)

Our largest areas of concern involve the interactions and exploits that can arise from the interaction between markets and their hooks.

We are aware of some aspects of this already [see: https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues], but fundamentally if there is a way for a hook to revert in an unexpected way it can potentially brick access to the function that it gatekeeps.

- More generally, we have removed the controller role and moved all market constraining mechanisms into the hooks: this is a non-trivial change if you previously audited Wildcat V1.

- Beyond these, the areas of concern remain the same as they were for Wildcat V1 (as there's always a non-zero chance something was missed last time!):

#### Access Controls and Permissions

- Consider ways in which lenders can receive a credential for a market without 'correctly' passing through the hook instance specified by the borrower that deployed it.

- Consider ways in which access to market interactions can be maliciously altered to either block or elevate parties outside of the defined flow.

- Consider ways in which removing access (borrowers from the archcontroller, borrowers playing with hooks) can lead to the inability to interact correctly with markets.

- Consider ways in which the access control hooks could be made to always revert.
  - Excluding the known issue that a borrower can add role providers that throw with OOG

#### Market Parameters

- Consider ways in which market interest rates can be manipulated to produce results that are outside of specified limits.

- Consider ways in which the required reserves of a market can be manipulated so as to lead to the borrower borrowing more than they should be permitted.

#### Penalty APR

- Consider ways in which the borrower can manipulate reserves or base APRs in a way to avoid the penalty rate activating if delinquent for longer then the grace period (note: market termination is an exception here).

#### Deposits and Withdrawals

- Consider ways in which deposits might cause trouble with internal market accounting.

- Consider ways in which lenders making withdrawal requests might have them (be they either pending or expired) altered.

- Consider ways in which market tokens can be burned but incorrect amounts of assets are claimable (this is very nuanced and circumstance specific).

- Consider ways in which the order of expired batches can be manipulated to impact the withdrawal queue's FIFO nature.

- Consider ways in which a party other than the borrower of a market can borrow assets.

- Consider ways in which an address without the correct permissions can burn market tokens or otherwise make withdrawal requests.

#### Sentinel and Escrow Contracts

- Consider ways (beyond a hostile Chainalysis oracle) in which lender addresses could be excised from a market via nukeFromOrbit.

- Consider ways in which parties to an escrow contract might be locked out of it, or the escrow contract might otherwise be bricked.

## All Trusted Roles In The Protocol

You should bear in mind that this is a pretty unusual set of contracts compared to your usual Solidity repo. There are a lot of trust assumptions baked in here given that underlying purpose of the protocol is undercollateralised credit, which necessarily reaches off-chain.

| Role                                | Description                       |
| --------------------------------------- | ---------------------------- |
| Archcontroller Operator                          |  Dictates which addresses are allowed to deploy markets and hooks instances (i.e. act as borrowers).  Can deploy new market factories and hooks templates to extend protocol functionality, as well as adjusting fee parameters. Can blacklist ERC-20s to prevent future markets being created for them. Can remove borrowers from archcontroller (preventing them from future deployments), and can deregister hooks instances and factories to prevent the deployment of any further markets. Can effectively pause the entire protocol by updating the associated SphereX transaction monitoring engine to one that rejects all transactions. Cannot manipulate, update or intervene in extant markets beyond aforementioned SphereX pause power.     |
| Borrowers                             |  Capable of deploying hook instances and markets parameterised as they wish, and determine the conditions/policies under which an address can engage with the market as a lender. Has the ability to adjust APR, capacity and certain parameters of hooks (e.g. providers) once deployed. Can terminate/close markets at will. _Fundamental_ assumption is that assets will be returned to markets to honour required reserves upon demand.                        |
| Lenders                             |  Authorised via hooks to deposit/withdraw from markets. Unauthorised addresses are unable to deposit in a way that triggers supply changes.                       |

## Any novel or unique curve logic or mathematical models implemented in the contracts:

N/A



## Running Tests


```bash
git clone --recurse https://github.com/code-423n4/2024-08-wildcat.git
cd 2024-08-wildcat
forge install
forge test
```
- To run code coverage:
```bash
yarn coverage
```
- To run gas benchmarks:
```bash
forge test --gas-report
```

- The output of code coverage:


| File                                                  | % Lines            | % Statements       | % Branches       | % Funcs          |
|-------------------------------------------------------|--------------------|--------------------|------------------|------------------|
| script/LibDeployment.sol                              | 0.00% (0/120)      | 0.00% (0/152)      | 0.00% (0/13)     | 0.00% (0/28)     |
| src/HooksFactory.sol                                  | 100.00% (169/169)  | 100.00% (192/192)  | 100.00% (21/21)  | 100.00% (29/29)  |
| src/ReentrancyGuard.sol                               | 100.00% (12/12)    | 100.00% (11/11)    | 100.00% (2/2)    | 100.00% (5/5)    |
| src/WildcatArchController.sol                         | 98.10% (103/105)   | 98.61% (142/144)   | 93.75% (15/16)   | 100.00% (36/36)  |
| src/WildcatSanctionsEscrow.sol                        | 100.00% (11/11)    | 100.00% (15/15)    | 100.00% (1/1)    | 100.00% (5/5)    |
| src/WildcatSanctionsSentinel.sol                      | 100.00% (32/32)    | 100.00% (37/37)    | 100.00% (0/0)    | 100.00% (9/9)    |
| src/access/AccessControlHooks.sol                     | 99.05% (208/210)   | 99.20% (249/251)   | 96.49% (55/57)   | 100.00% (39/39)  |
| src/access/FixedTermLoanHooks.sol                     | 81.50% (185/227)   | 84.56% (230/272)   | 71.88% (46/64)   | 72.50% (29/40)   |
| src/access/IHooks.sol                                 | 100.00% (3/3)      | 100.00% (5/5)      | 100.00% (1/1)    | 100.00% (2/2)    |
| src/access/MarketConstraintHooks.sol                  | 100.00% (51/51)    | 100.00% (56/56)    | 100.00% (11/11)  | 100.00% (6/6)    |
| src/libraries/BoolUtils.sol                           | 66.67% (2/3)       | 66.67% (2/3)       | 100.00% (0/0)    | 66.67% (2/3)     |
| src/libraries/FIFOQueue.sol                           | 100.00% (30/30)    | 100.00% (38/38)    | 100.00% (4/4)    | 100.00% (8/8)    |
| src/libraries/FeeMath.sol                             | 100.00% (27/27)    | 100.00% (36/36)    | 100.00% (4/4)    | 100.00% (6/6)    |
| src/libraries/FunctionTypeCasts.sol                   | 100.00% (3/3)      | 100.00% (3/3)      | 100.00% (0/0)    | 100.00% (3/3)    |
| src/libraries/LibERC20.sol                            | 76.19% (32/42)     | 77.27% (34/44)     | 16.67% (1/6)     | 100.00% (7/7)    |
| src/libraries/LibStoredInitCode.sol                   | 58.49% (31/53)     | 56.36% (31/55)     | 60.00% (3/5)     | 63.64% (7/11)    |
| src/libraries/MarketState.sol                         | 100.00% (15/15)    | 100.00% (27/27)    | 100.00% (0/0)    | 100.00% (9/9)    |
| src/libraries/MathUtils.sol                           | 100.00% (42/42)    | 100.00% (46/46)    | 100.00% (7/7)    | 100.00% (13/13)  |
| src/libraries/SafeCastLib.sol                         | 100.00% (35/35)    | 100.00% (35/35)    | 100.00% (1/1)    | 100.00% (32/32)  |
| src/libraries/Withdrawal.sol                          | 100.00% (5/5)      | 100.00% (9/9)      | 100.00% (0/0)    | 100.00% (2/2)    |
| src/market/WildcatMarket.sol                          | 94.00% (94/100)    | 95.56% (129/135)   | 71.43% (15/21)   | 100.00% (13/13)  |
| src/market/WildcatMarketBase.sol                      | 94.58% (192/203)   | 94.64% (212/224)   | 78.26% (18/23)   | 93.75% (30/32)   |
| src/market/WildcatMarketConfig.sol                    | 97.78% (44/45)     | 98.31% (58/59)     | 92.31% (12/13)   | 100.00% (9/9)    |
| src/market/WildcatMarketToken.sol                     | 100.00% (27/27)    | 100.00% (34/34)    | 100.00% (2/2)    | 100.00% (7/7)    |
| src/market/WildcatMarketWithdrawals.sol               | 100.00% (103/103)  | 100.00% (139/139)  | 100.00% (17/17)  | 100.00% (12/12)  |
| src/spherex/SphereXConfig.sol                         | 100.00% (41/41)    | 100.00% (55/55)    | 100.00% (6/6)    | 100.00% (16/16)  |
| src/spherex/SphereXProtectedRegisteredBase.sol        | 94.94% (75/79)     | 95.18% (79/83)     | 60.00% (3/5)     | 100.00% (18/18)  |
| src/types/HooksConfig.sol                             | 93.67% (207/221)   | 94.24% (229/243)   | 69.57% (16/23)   | 100.00% (32/32)  |
| src/types/LenderStatus.sol                            | 88.89% (8/9)       | 78.57% (11/14)     | 100.00% (0/0)    | 80.00% (4/5)     |
| src/types/RoleProvider.sol                            | 100.00% (14/14)    | 100.00% (17/17)    | 100.00% (0/0)    | 100.00% (12/12)  |
| src/types/TransientBytesArray.sol                     | 93.88% (46/49)     | 94.44% (51/54)     | 50.00% (1/2)     | 100.00% (5/5)    |
| test/BaseMarketTest.sol                               | 100.00% (73/73)    | 100.00% (89/89)    | 100.00% (2/2)    | 100.00% (14/14)  |
| test/EscrowTest.sol                                   | 100.00% (1/1)      | 100.00% (1/1)      | 100.00% (0/0)    | 100.00% (1/1)    |
| test/HooksFactory.t.sol                               | 100.00% (1/1)      | 100.00% (1/1)      | 100.00% (0/0)    | 100.00% (1/1)    |
| test/ReentrancyGuard.t.sol                            | 100.00% (8/8)      | 100.00% (11/11)    | 75.00% (3/4)     | 100.00% (4/4)    |
| test/SentinelTest.sol                                 | 0.00% (0/1)        | 0.00% (0/1)        | 100.00% (0/0)    | 0.00% (0/1)      |
| test/handlers/BaseHandler.sol                         | 31.58% (12/38)     | 32.65% (16/49)     | 44.44% (4/9)     | 41.67% (5/12)    |
| test/handlers/ERC20Handler.sol                        | 11.36% (5/44)      | 10.64% (5/47)      | 0.00% (0/7)      | 87.50% (7/8)     |
| test/helpers/AddressSet.sol                           | 30.77% (4/13)      | 23.53% (4/17)      | 0.00% (0/3)      | 50.00% (3/6)     |
| test/helpers/Assertions.sol                           | 69.31% (70/101)    | 68.52% (74/108)    | 0.00% (0/4)      | 62.50% (15/24)   |
| test/helpers/ExpectedBalances.sol                     | 0.00% (0/184)      | 0.00% (0/254)      | 0.00% (0/26)     | 0.00% (0/28)     |
| test/helpers/ExpectedStateTracker.sol                 | 85.59% (196/229)   | 86.12% (242/281)   | 66.67% (22/33)   | 90.32% (28/31)   |
| test/helpers/PRNG.sol                                 | 19.12% (13/68)     | 19.70% (13/66)     | 0.00% (0/7)      | 20.00% (1/5)     |
| test/helpers/VmUtils.sol                              | 66.67% (4/6)       | 66.67% (4/6)       | 100.00% (0/0)    | 66.67% (2/3)     |
| test/helpers/fuzz/AccessControlHooksFuzzContext.sol   | 91.08% (143/157)   | 92.16% (141/153)   | 81.63% (40/49)   | 100.00% (8/8)    |
| test/helpers/fuzz/MarketConfigFuzzInputs.sol          | 100.00% (9/9)      | 100.00% (9/9)      | 100.00% (1/1)    | 100.00% (2/2)    |
| test/helpers/fuzz/MarketStateFuzzInputs.sol           | 100.00% (21/21)    | 100.00% (21/21)    | 100.00% (0/0)    | 100.00% (2/2)    |
| test/libraries/LibStoredInitCode.t.sol                | 0.00% (0/1)        | 0.00% (0/1)        | 100.00% (0/0)    | 0.00% (0/1)      |
| test/libraries/StringQuery.t.sol                      | 100.00% (7/7)      | 100.00% (5/5)      | 100.00% (4/4)    | 100.00% (3/3)    |
| test/libraries/wrappers/FIFOQueueLibExternal.sol      | 100.00% (8/8)      | 100.00% (13/13)    | 100.00% (0/0)    | 100.00% (8/8)    |
| test/libraries/wrappers/FeeMathExternal.sol           | 40.00% (4/10)      | 33.33% (4/12)      | 100.00% (0/0)    | 33.33% (2/6)     |
| test/libraries/wrappers/LibStoredInitCodeExternal.sol | 88.89% (8/9)       | 93.75% (15/16)     | 100.00% (0/0)    | 88.89% (8/9)     |
| test/libraries/wrappers/MarketStateLibExternal.sol    | 100.00% (8/8)      | 100.00% (16/16)    | 100.00% (0/0)    | 100.00% (8/8)    |
| test/libraries/wrappers/MathUtilsExternal.sol         | 75.00% (9/12)      | 75.00% (18/24)     | 100.00% (0/0)    | 75.00% (9/12)    |
| test/libraries/wrappers/SafeCastLibExternal.sol       | 100.00% (31/31)    | 100.00% (62/62)    | 100.00% (0/0)    | 100.00% (31/31)  |
| test/libraries/wrappers/WithdrawalLibExternal.sol     | 50.00% (1/2)       | 50.00% (2/4)       | 100.00% (0/0)    | 50.00% (1/2)     |
| test/shared/Test.sol                                  | 74.03% (114/154)   | 74.43% (131/176)   | 72.22% (13/18)   | 66.67% (12/18)   |
| test/shared/mocks/AlwaysAuthorizedRoleProvider.sol    | 66.67% (2/3)       | 66.67% (2/3)       | 100.00% (0/0)    | 66.67% (2/3)     |
| test/shared/mocks/MockAccessControlHooks.sol          | 100.00% (9/9)      | 100.00% (7/7)      | 100.00% (3/3)    | 100.00% (3/3)    |
| test/shared/mocks/MockChainalysis.sol                 | 100.00% (2/2)      | 100.00% (2/2)      | 100.00% (0/0)    | 100.00% (2/2)    |
| test/shared/mocks/MockERC20.sol                       | 100.00% (1/1)      | 100.00% (1/1)      | 100.00% (0/0)    | 100.00% (2/2)    |
| test/shared/mocks/MockEngine.sol                      | 82.50% (33/40)     | 81.25% (39/48)     | 60.00% (12/20)   | 100.00% (6/6)    |
| test/shared/mocks/MockFixedTermLoanHooks.sol          | 100.00% (9/9)      | 100.00% (7/7)      | 100.00% (3/3)    | 100.00% (3/3)    |
| test/shared/mocks/MockHookCaller.sol                  | 93.75% (15/16)     | 93.75% (15/16)     | 100.00% (0/0)    | 92.86% (13/14)   |
| test/shared/mocks/MockHooks.sol                       | 100.00% (45/45)    | 100.00% (47/47)    | 100.00% (1/1)    | 100.00% (21/21)  |
| test/shared/mocks/MockRoleProvider.sol                | 80.95% (17/21)     | 73.91% (17/23)     | 71.43% (5/7)     | 100.00% (8/8)    |
| test/shared/mocks/MockSanctionsSentinel.sol           | 100.00% (1/1)      | 100.00% (1/1)      | 100.00% (0/0)    | 50.00% (1/2)     |
| test/spherex/SphereXConfig.t.sol                      | 75.00% (3/4)       | 75.00% (3/4)       | 100.00% (0/0)    | 100.00% (5/5)    |
| Total                                                 | 79.64% (2734/3433) | 79.46% (3250/4090) | 71.29% (375/526) | 84.05% (648/771) |

## Miscellaneous
Employees of The Wildcat Protocol and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.






