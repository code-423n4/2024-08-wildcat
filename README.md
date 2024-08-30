
# Repo setup

## ⭐️ Sponsor: Add code to this repo

- [ ] Create a PR to this repo with the below changes:
- [ ] Confirm that this repo is a self-contained repository with working commands that will build (at least) all in-scope contracts, and commands that will run tests producing gas reports for the relevant contracts.
- [ ] Please have final versions of contracts and documentation added/updated in this repo **no less than 48 business hours prior to audit start time.**
- [ ] Be prepared for a 🚨code freeze🚨 for the duration of the audit — important because it establishes a level playing field. We want to ensure everyone's looking at the same code, no matter when they look during the audit. (Note: this includes your own repo, since a PR can leak alpha to our wardens!)

## ⭐️ Sponsor: Repo checklist

- [ ] Modify the [Overview](#overview) section of this `README.md` file. Describe how your code is supposed to work with links to any relevent documentation and any other criteria/details that the auditors should keep in mind when reviewing. (Here are two well-constructed examples: [Ajna Protocol](https://github.com/code-423n4/2023-05-ajna) and [Maia DAO Ecosystem](https://github.com/code-423n4/2023-05-maia))
- [ ] Review the Gas award pool amount, if applicable. This can be adjusted up or down, based on your preference - just flag it for Code4rena staff so we can update the pool totals across all comms channels.
- [ ] Optional: pre-record a high-level overview of your protocol (not just specific smart contract functions). This saves wardens a lot of time wading through documentation.
- [ ] [This checklist in Notion](https://code4rena.notion.site/Key-info-for-Code4rena-sponsors-f60764c4c4574bbf8e7a6dbd72cc49b4#0cafa01e6201462e9f78677a39e09746) provides some best practices for Code4rena audit repos.

## ⭐️ Sponsor: Final touches
- [ ] Review and confirm the pull request created by the Scout (technical reviewer) who was assigned to your contest. *Note: any files not listed as "in scope" will be considered out of scope for the purposes of judging, even if the file will be part of the deployed contracts.*
- [ ] Check that images and other files used in this README have been uploaded to the repo as a file and then linked in the README using absolute path (e.g. `https://github.com/code-423n4/yourrepo-url/filepath.png`)
- [ ] Ensure that *all* links and image/file paths in this README use absolute paths, not relative paths
- [ ] Check that all README information is in markdown format (HTML does not render on Code4rena.com)
- [ ] Delete this checklist and all text above the line below when you're ready.

---


# Wildcat audit details
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

**Zenith Side Pool**
- Two [Zenith](https://code4rena.com/zenith) Researchers (ZRs) are designated as leads for the audit ("LZRs"), with teams counting as one.
- Z pool is split 60/40 among LZRs based on their Gatherer score.
- LZRs also compete for a portion of HM awards and are eligible for Hunter/Gatherer bonuses.

**Dark Horse Bonus Pool**
Dark Horse is (1) a non-LZR who (2) finishes in the top 5, and (3) outperforms (or ties) the top-ranked LZR auditor based on [Gatherer score](https://docs.code4rena.com/awarding/incentive-model-and-awards#bonuses-for-top-competitors). Dark Horse awards come out of the Z pool.

- If an LZR ranks outside the top 2 (by [Top Gatherer score](https://docs.code4rena.com/awarding/incentive-model-and-awards#bonuses-for-top-competitors)):
    - 50% of their share of the Z pool goes to the Dark Horse bonus pool
- If an LZR ranks outside the top 5 (by [Top Gatherer score](https://docs.code4rena.com/awarding/incentive-model-and-awards#bonuses-for-top-competitors)):
    - The LZR forfeits their share of the Z pool (but are still eligible for HM / QA awards)
    - 50% of their share of the Z pool goes to the Dark Horse bonus pool
    - 50% of their share of the Z pool is refunded to sponsor
- Dark Horse awards are distributed using C4’s ranked curve. 

Specific edge cases:
- If no lead ranks outside the top 2, no Dark Horse bonus is awarded.
- In the event that no LZRs rank in the top 5, the Dark Horse pool will be distributed, but only the top 5 ranked competitors will earn the Dark Horse achievement for the competition.
- Any unused portion of the Z pool is returned to the Sponsor

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-08-wildcat/blob/main/4naly3er-report.md).



_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

- Please see: https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues

- If you file a finding about the Sherlock `CREATE2` collision malarkey we will sell pinatas with your Discord handle on them as merchandise.


# Overview

[ ⭐️ SPONSORS: add info here ]

## Links

- **Previous audits:**  [Previous review of V2 codebase](https://hackmd.io/@geistermeister/BJk4Ekt90)

The fundamental core of the protocol (V1) has previously been audited by Code4rena:
* https://code4rena.com/contests/2023-10-the-wildcat-protocol
* https://hackmd.io/@geistermeister/r15gj_y1p

- **Documentation:** https://docs.wildcat.finance/
- **Website:** https://wildcat.finance/
- **X/Twitter:** [@WildcatFi](https://x.com/WildcatFi)
- **Telegram:** https://t.me/+DcgjEiWaDpVkNTE8

---

# Scope

*See [scope.txt](https://github.com/code-423n4/2024-08-wildcat/blob/main/scope.txt)*

### Files in scope


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


### Files out of scope

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

### General questions


| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| ERC20 used by the protocol              |       Any non-rebasing ERC20 is valid. Creating markets for rebasing tokens breaks the underlying model.             |
| Test coverage                           | Lines: 79.64% - Funcions: 84.05%                          |
| ERC721 used  by the protocol            |            None              |
| ERC777 used by the protocol             |           None                |
| ERC1155 used by the protocol            |              None             |
| Chains the protocol will be deployed on | Ethereum, Base, Arbitrum, Polygon |

### ERC20 token behaviors in scope

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
| [Multiple token addresses](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#revert-on-zero-value-transfers)                                          | Out of scope    |
| [Low decimals ( < 6)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#low-decimals)                                                                 |   Out of scope  |
| [High decimals ( > 18)](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#high-decimals)                                                              | Out of scope    |
| [Blocklists](https://github.com/d-xo/weird-erc20?tab=readme-ov-file#tokens-with-blocklists)                                                                | In scope    |

### External integrations (e.g., Uniswap) behavior in scope:


| Question                                                  | Answer |
| --------------------------------------------------------- | ------ |
| Enabling/disabling fees (e.g. Blur disables/enables fees) | No   |
| Pausability (e.g. Uniswap pool gets paused)               |  No   |
| Upgradeability (e.g. Uniswap gets upgraded)               |   No  |


### EIP compliance 
N/A


# Additional context

## Main invariants

- Properties that should NEVER be broken under any circumstance:


- Market parameters should never be able to exit the bounds defined by the factory which deployed it.



- The supply of the market token and assets owed by the borrower should always match.



- The assets of a market should never be able to be withdrawn by anyone that is not the borrower or a lender [PENDING Dillon on detail here]. [Exceptions: balances being transferred to a blocked account's escrow contract and collection of protocol fees.]



- Asset deposits not made via deposit should not impact internal accounting (they only increase totalAssets and are effectively treated as a payment by the borrower).



- Addresses without [REDACTED: Pending Dillon] should never be able to adjust market token supply.



- Borrowers can only be registered with the archcontroller by the archcontroller owner.



- Markets and hook instances can only be deployed by borrowers currently registered with the archcontroller.



- Withdrawal execution can only transfer assets that have been counted as paid assets in the corresponding batch, i.e. lenders with withdrawal requests can not withdraw more than their pro-rata share of the batch's paid assets.



- Once claimable withdrawals have been set aside for a withdrawal batch (counted toward normalizedUnclaimedWithdrawals and batch.normalizedAmountPaid), they can only be used for that purpose (i.e. the market will always maintain at least that amount in underlying assets until lenders with a request from that batch have withdrawn the assets).



- In any non-static function which touches a market's state:

* Prior to executing the function's logic, if time has elapsed since the last update, interest, protocol fees and delinquency fees should be accrued to the market state and pending/expired withdrawal batches should be processed.

* At the end of the function, the updated state is written to storage and the market's delinquency status is updated.

* Assets are only paid to newer withdrawal batches if the market has sufficient assets to close older batches.



## Attack ideas (where to focus for bugs)
- Our largest areas of concern involve the interactions and exploits that can arise from the interaction between markets and their hooks. We are aware of some aspects of this already [see: https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues], but fundamentally if there is a way for a hook to revert in an unexpected way it can potentially brick access to the function that it gatekeeps.

- More generally, we have removed the controller role and moved all market constraining mechanisms into the hooks: this is a non-trivial change if you previously audited Wildcat V1.

[PENDING: Dillon, anything else either hooks related or below that needs adjusting to reflect codebase changes?]

- Beyond these, the areas of concern remain the same as they were for Wildcat V1 (as there's always a non-zero chance something was missed last time!):

#### Access Controls and Permissions

- Consider ways in which borrower addresses, hooks templates or markets can be added to the archcontroller either without the specific approval of its owner or as a result of contract deployment.

- Consider ways in which lenders can be authorised for a market without passing through (in good faith) the process specified by the borrower that deployed it.

- Consider ways in which access to market interactions can be maliciously altered to either block or elevate parties outside of the defined flow.

- Consider ways in which removing access (borrowers from the archcontroller, lender credentials from hook providers) can lead to the inability to interact correctly with markets.



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



## All trusted roles in the protocol


| Role                                | Description                       |
| --------------------------------------- | ---------------------------- |
| Archcontroller Operator                          |  Dictates which addresses are allowed to deploy markets and hooks instances (i.e. act as borrowers).  Can deploy new market factories and hooks templates to extend protocol functionality, as well as adjusting fee parameters.               |
| Borrowers                             |  Capable of deploying markets parameterised as they wish, and determine the conditions/policies under which an address can engage with the market as a lender. Has the ability to adjust APR, capacity and certain parameters of hooks (e.g. providers) once deployed. Can terminate/close markets at will.                         |
| Lenders                             |  Authorised via a hook (either third-party KYC/KYB or explicit whitelisting) to deposit/withdraw from markets. Unauthorised addresses are unable to deposit in a way that triggers supply changes.                       |

## Any novel or unique curve logic or mathematical models implemented in the contracts:

N/A



## Running tests


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






