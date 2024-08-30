# ✨ So you want to run an audit

This `README.md` contains a set of checklists for our audit collaboration.

Your audit will use two repos: 
- **an _audit_ repo** (this one), which is used for scoping your audit and for providing information to wardens
- **a _findings_ repo**, where issues are submitted (shared with you after the audit) 

Ultimately, when we launch the audit, this repo will be made public and will contain the smart contracts to be reviewed and all the information needed for audit participants. The findings repo will be made public after the audit report is published and your team has mitigated the identified issues.

Some of the checklists in this doc are for **C4 (🐺)** and some of them are for **you as the audit sponsor (⭐️)**.

---

# Audit setup

## 🐺 C4: Set up repos
- [ ] Create a new private repo named `YYYY-MM-sponsorname` using this repo as a template.
- [ ] Rename this repo to reflect audit date (if applicable)
- [ ] Rename audit H1 below
- [ ] Update pot sizes
  - [ ] Remove the "Bot race findings opt out" section if there's no bot race.
- [ ] Fill in start and end times in audit bullets below
- [ ] Add link to submission form in audit details below
- [ ] Add the information from the scoping form to the "Scoping Details" section at the bottom of this readme.
- [ ] Add matching info to the Code4rena site
- [ ] Add sponsor to this private repo with 'maintain' level access.
- [ ] Send the sponsor contact the url for this repo to follow the instructions below and add contracts here. 
- [ ] Delete this checklist.

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

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-08-wildcat/blob/main/4naly3er-report.md).



_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._

Please see: https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues

If you file a finding about the Sherlock CREATE2 collision malarkey we will sell pinatas with your Discord handle on them as merchandise.

✅ SCOUTS: Please format the response above 👆 so its not a wall of text and its readable.

# Overview

[ ⭐️ SPONSORS: add info here ]

## Links

- **Previous audits:**  Previous review of V2 codebase:
* https://hackmd.io/@geistermeister/BJk4Ekt90

The fundamental core of the protocol (V1) has previously been audited by Code4rena:
* https://code4rena.com/contests/2023-10-the-wildcat-protocol
* https://hackmd.io/@geistermeister/r15gj_y1p
  - ✅ SCOUTS: If there are multiple report links, please format them in a list.
- **Documentation:** docs.wildcat.finance
- **Website:** 🐺 CA: add a link to the sponsor's website
- **X/Twitter:** 🐺 CA: add a link to the sponsor's Twitter
- **Discord:** 🐺 CA: add a link to the sponsor's Discord

---

# Scope

[ ✅ SCOUTS: add scoping and technical details here ]

### Files in scope
- ✅ This should be completed using the `metrics.md` file
- ✅ Last row of the table should be Total: SLOC
- ✅ SCOUTS: Have the sponsor review and and confirm in text the details in the section titled "Scoping Q amp; A"

*For sponsors that don't use the scoping tool: list all files in scope in the table below (along with hyperlinks) -- and feel free to add notes to emphasize areas of focus.*

| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [contracts/folder/sample.sol](https://github.com/code-423n4/repo-name/blob/contracts/folder/sample.sol) | 123 | This contract does XYZ | [`@openzeppelin/*`](https://openzeppelin.com/contracts/) |

### Files out of scope
✅ SCOUTS: List files/directories out of scope

## Scoping Q &amp; A

### General questions
### Are there any ERC20's in scope?: Yes

✅ SCOUTS: If the answer above 👆 is "Yes", please add the tokens below 👇 to the table. Otherwise, update the column with "None".

Specific tokens (please specify)
Any non-rebasing ERC20 is valid. Creating markets for rebasing tokens break the underlying model.

### Are there any ERC777's in scope?: No

✅ SCOUTS: If the answer above 👆 is "Yes", please add the tokens below 👇 to the table. Otherwise, update the column with "None".



### Are there any ERC721's in scope?: No

✅ SCOUTS: If the answer above 👆 is "Yes", please add the tokens below 👇 to the table. Otherwise, update the column with "None".



### Are there any ERC1155's in scope?: No

✅ SCOUTS: If the answer above 👆 is "Yes", please add the tokens below 👇 to the table. Otherwise, update the column with "None".



✅ SCOUTS: Once done populating the table below, please remove all the Q/A data above.

| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| ERC20 used by the protocol              |       🖊️             |
| Test coverage                           | ✅ SCOUTS: Please populate this after running the test coverage command                          |
| ERC721 used  by the protocol            |            🖊️              |
| ERC777 used by the protocol             |           🖊️                |
| ERC1155 used by the protocol            |              🖊️            |
| Chains the protocol will be deployed on | Ethereum,Base,Arbitrum,Polygon |

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


### EIP compliance checklist
N/A

✅ SCOUTS: Please format the response above 👆 using the template below👇

| Question                                | Answer                       |
| --------------------------------------- | ---------------------------- |
| src/Token.sol                           | ERC20, ERC721                |
| src/NFT.sol                             | ERC721                       |


# Additional context

## Main invariants

Properties that should NEVER be broken under any circumstance:

---

Market parameters should never be able to exit the bounds defined by the factory which deployed it.

---

The supply of the market token and assets owed by the borrower should always match.

---

The assets of a market should never be able to be withdrawn by anyone that is not the borrower or a lender [PENDING Dillon on detail here]. [Exceptions: balances being transferred to a blocked account's escrow contract and collection of protocol fees.]

---

Asset deposits not made via deposit should not impact internal accounting (they only increase totalAssets and are effectively treated as a payment by the borrower).

---

Addresses without [REDACTED: Pending Dillon] should never be able to adjust market token supply.

---

Borrowers can only be registered with the archcontroller by the archcontroller owner.

---

Markets and hook instances can only be deployed by borrowers currently registered with the archcontroller.

---

Withdrawal execution can only transfer assets that have been counted as paid assets in the corresponding batch, i.e. lenders with withdrawal requests can not withdraw more than their pro-rata share of the batch's paid assets.

---

Once claimable withdrawals have been set aside for a withdrawal batch (counted toward normalizedUnclaimedWithdrawals and batch.normalizedAmountPaid), they can only be used for that purpose (i.e. the market will always maintain at least that amount in underlying assets until lenders with a request from that batch have withdrawn the assets).

---

In any non-static function which touches a market's state:

* Prior to executing the function's logic, if time has elapsed since the last update, interest, protocol fees and delinquency fees should be accrued to the market state and pending/expired withdrawal batches should be processed.

* At the end of the function, the updated state is written to storage and the market's delinquency status is updated.

* Assets are only paid to newer withdrawal batches if the market has sufficient assets to close older batches.

✅ SCOUTS: Please format the response above 👆 so its not a wall of text and its readable.

## Attack ideas (where to focus for bugs)
Our largest areas of concern involve the interactions and exploits that can arise from the interaction between markets and their hooks. We are aware of some aspects of this already [see: https://docs.wildcat.finance/technical-overview/security-developer-dives/known-issues], but fundamentally if there is a way for a hook to revert in an unexpected way it can potentially brick access to the function that it gatekeeps.

More generally, we have removed the controller role and moved all market constraining mechanisms into the hooks: this is a non-trivial change if you previously audited Wildcat V1.

[PENDING: Dillon, anything else either hooks related or below that needs adjusting to reflect codebase changes?]

Beyond these, the areas of concern remain the same as they were for Wildcat V1 (as there's always a non-zero chance something was missed last time!):

Access Controls and Permissions

Consider ways in which borrower addresses, hooks templates or markets can be added to the archcontroller either without the specific approval of its owner or as a result of contract deployment.

Consider ways in which lenders can be authorised for a market without passing through (in good faith) the process specified by the borrower that deployed it.

Consider ways in which access to market interactions can be maliciously altered to either block or elevate parties outside of the defined flow.

Consider ways in which removing access (borrowers from the archcontroller, lender credentials from hook providers) can lead to the inability to interact correctly with markets.

---

Market Parameters

Consider ways in which market interest rates can be manipulated to produce results that are outside of specified limits.

Consider ways in which the required reserves of a market can be manipulated so as to lead to the borrower borrowing more than they should be permitted.

---

Penalty APR

Consider ways in which the borrower can manipulate reserves or base APRs in a way to avoid the penalty rate activating if delinquent for longer then the grace period (note: market termination is an exception here).

---

Deposits and Withdrawals

Consider ways in which deposits might cause trouble with internal market accounting.

Consider ways in which lenders making withdrawal requests might have them (be they either pending or expired) altered.

Consider ways in which market tokens can be burned but incorrect amounts of assets are claimable (this is very nuanced and circumstance specific).

Consider ways in which the order of expired batches can be manipulated to impact the withdrawal queue's FIFO nature.

Consider ways in which a party other than the borrower of a market can borrow assets.

Consider ways in which an address without the correct permissions can burn market tokens or otherwise make withdrawal requests.

---

Sentinel and Escrow Contracts

Consider ways (beyond a hostile Chainalysis oracle) in which lender addresses could be excised from a market via nukeFromOrbit.

Consider ways in which parties to an escrow contract might be locked out of it, or the escrow contract might otherwise be bricked.


✅ SCOUTS: Please format the response above 👆 so its not a wall of text and its readable.

## All trusted roles in the protocol

Archcontroller Operator: dictates which addresses are allowed to deploy markets and hooks instances (i.e. act as borrowers). Can deploy new market factories and hooks templates to extend protocol functionality, as well as adjusting fee parameters.

Borrowers: capable of deploying markets parameterised as they wish, and determine the conditions/policies under which an address can engage with the market as a lender. Has the ability to adjust APR, capacity and certain parameters of hooks (e.g. providers) once deployed. Can terminate/close markets at will.  

Lenders: authorised via a hook (either third-party KYC/KYB or explicit whitelisting) to deposit/withdraw from markets. Unauthorised addresses are unable to deposit in a way that triggers supply changes.

✅ SCOUTS: Please format the response above 👆 using the template below👇

| Role                                | Description                       |
| --------------------------------------- | ---------------------------- |
| Owner                          | Has superpowers                |
| Administrator                             | Can change fees                       |

## Describe any novel or unique curve logic or mathematical models implemented in the contracts:

N/A

✅ SCOUTS: Please format the response above 👆 so its not a wall of text and its readable.

## Running tests

git clone https://github.com/code-423n4/2024-08-wildcat && cd 2024-08-wildcat && forge install from a standing start.

forge test --gas-report for tests.

yarn coverage for coverage.

✅ SCOUTS: Please format the response above 👆 using the template below👇

```bash
git clone https://github.com/code-423n4/2023-08-arbitrum
git submodule update --init --recursive
cd governance
foundryup
make install
make build
make sc-election-test
```
To run code coverage
```bash
make coverage
```
To run gas benchmarks
```bash
make gas
```

✅ SCOUTS: Add a screenshot of your terminal showing the gas report
✅ SCOUTS: Add a screenshot of your terminal showing the test coverage


# Scope

*See [scope.txt](https://github.com/code-423n4/2024-08-wildcat/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/HooksFactory.sol | 1| **** | 391 | ||
| /src/ReentrancyGuard.sol | 1| **** | 40 | ||
| /src/WildcatArchController.sol | 1| **** | 271 | |openzeppelin/contracts/utils/structs/EnumerableSet.sol<br>solady/auth/Ownable.sol|
| /src/WildcatSanctionsEscrow.sol | 1| **** | 33 | ||
| /src/WildcatSanctionsSentinel.sol | 1| **** | 68 | ||
| /src/access/AccessControlHooks.sol | 1| **** | 450 | ||
| /src/access/FixedTermLoanHooks.sol | 1| **** | 485 | ||
| /src/access/MarketConstraintHooks.sol | 1| **** | 180 | ||
| /src/libraries/MarketState.sol | 1| **** | 71 | ||
| /src/libraries/LibStoredInitCode.sol | 1| **** | 99 | ||
| /src/market/WildcatMarket.sol | 1| **** | 169 | ||
| /src/market/WildcatMarketBase.sol | 1| **** | 454 | ||
| /src/market/WildcatMarketConfig.sol | 1| **** | 81 | ||
| /src/market/WildcatMarketToken.sol | 1| **** | 51 | ||
| /src/market/WildcatMarketWithdrawals.sol | 1| **** | 183 | ||
| /src/types/HooksConfig.sol | 1| **** | 560 | ||
| /src/types/LenderStatus.sol | 1| **** | 30 | ||
| /src/types/RoleProvider.sol | 1| **** | 81 | ||
| /src/types/TransientBytesArray.sol | 1| **** | 87 | ||
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

## Miscellaneous
Employees of The Wildcat Protocol and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.
