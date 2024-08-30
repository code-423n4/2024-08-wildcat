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
- Total Prize Pool: $100000 in USDC
  - HM awards: $66720 in USDC
  - (remove this line if there is no Analysis pool) Analysis awards: XXX XXX USDC (Notion: Analysis pool)
  - QA awards: $2780 in USDC
  - (remove this line if there is no Bot race) Bot Race awards: XXX XXX USDC (Notion: Bot Race pool)
 
  - Judge awards: $6000 in USDC
  - Validator awards: XXX XXX USDC (Notion: Triage fee - final)
  - Scout awards: $500 in USDC
  - (this line can be removed if there is no mitigation) Mitigation Review: XXX XXX USDC (*Opportunity goes to top 3 backstage wardens based on placement in this audit who RSVP.*)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts August 31, 2024 20:00 UTC
- Ends September 18, 2024 20:00 UTC

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2024-08-wildcat/blob/main/4naly3er-report.md).



_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._
## 🐺 C4: Begin Gist paste here (and delete this line)





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

