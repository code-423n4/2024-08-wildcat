# How hooks work

For each market function which we may want a hooks contract to be able to track, impose restrictions on, or otherwise react to in some way, there is a corresponding hook that can be called on the configured hooks contract as well as a flag in the market's hooks configuration (`HooksConfig`) indicating whether the hook _should_ be called.

When one of these functions on a market is called, the market will check if the corresponding hook is enabled; if it is, it will call the hook function on the configured hooks contract, providing the intermediate state (prior to applying the full effects of the relevant action, but after accruing interest and fees), the relevant data for the action, the caller address (except for borrower-only functions) and an optional `extraData` buffer supplied by the caller.

Hooks can not modify internal behavior of the market and do not have any privileged access to its state; rather, they are designed to be _reactive to_ and _restrictive of_ market actions. This means, for example, that a hook can not change who receives a transfer or force a lender into a withdrawal, but it can prevent a transfer from occurring or keep some internal state about the withdrawal.

**Exceptions to the above**

There are some exceptions to the behavior described above:

- The rule about not modifying the market behavior is violated by `setAnnualInterestAndReserveRatioBips` - when a market's APR or reserve ratio are changed, the associated hook has the ability to modify those two values.
- Behavior is also modified by `onCreateMarket` which can modify the `HooksConfig` given by the borrower when a market is being deployed.
- The rule about only providing intermediate state (i.e. before execution of the action) is violated by the `queueWithdrawal` functions - when a withdrawal is queued, the intermediate state provided to the hooks call is the state _after_ the market's `pendingWithdrawalExpiry` is updated. This ensures the hook has access to the withdrawal expiry if that is ever needed.

## `extraData` buffer

In a call to one of the core functions listed below, the caller can append arbitrary bytes to the end of the function calldata. If they do, these bytes will be provided to the call to the hooks contract in the `bytes extraData` field. The primary use-case for this field is for the access control hooks, where the caller may need to provide a signature, merkle proof, or some other verification data in order to be authenticated to a particular market.

The `extraData` field is not part of the market's function signatures; the raw bytes must be appended to the end without ABI offset or length fields, and without padding to the closest word (otherwise the calculated length will be incorrect).

For calls to `executeWithdrawals` and `nukeFromOrbit`, the optional buffer can not be provided.

## Market Functions / Hooks Table

|Contract | Market Function(s) | Hook Function(s) Triggered |
|----------------|--------------------|---------------|
| HooksFactory | `deployMarket` | `onCreateMarket` |
| HooksFactory | `deployMarketAndHooks` | `onCreateMarket` |
| WildcatMarket | `deposit` | `onDeposit` |
| WildcatMarket | `depositUpTo` | `onDeposit` |
| WildcatMarket | `queueWithdrawal`|  `onQueueWithdrawal` |
| WildcatMarket | `queueFullWithdrawal` | `onQueueWithdrawal` |
| WildcatMarket | `executeWithdrawal` | `onExecuteWithdrawal` |
| WildcatMarket | `executeWithdrawals` | `onExecuteWithdrawal` |
| WildcatMarket | `transfer` | `onTransfer` |
| WildcatMarket | `transferFrom` | `onTransfer` |
| WildcatMarket | `borrow` | `onBorrow` |
| WildcatMarket | `repay`  | `onRepay` |
| WildcatMarket | `repayOutstandingDebt` | `onRepay` |
| WildcatMarket | `repayDelinquentDebt` | `onRepay` |
| WildcatMarket | `repayAndProcessUnpaidWithdrawalBatches` | `onRepay`* |
| WildcatMarket | `closeMarket` | `onRepay`*, `onCloseMarket` |
| WildcatMarket | `setMaxTotalSupply` | `onSetMaxTotalSupply` |
| WildcatMarket | `nukeFromOrbit` | `onQueueWithdrawal`*, `onNukeFromOrbit` |
| WildcatMarket | `setAnnualInterestAndReserveRatioBips` | `onSetAnnualInterestAndReserveRatioBips` |
| WildcatMarket | `setProtocolFeeBips` | `onSetProtocolFeeBips`  |

> \* indicates that hook invocation is not guaranteed