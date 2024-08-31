# Access Control Hooks

The `AccessControlHooks` contract has three main features:
- Borrower can define a minimum deposit value.
- Borrower can configure a set of "role providers" - accounts which grant credentials to lenders, where these credentials can be required for deposits, transfer receipt and withdrawal.
- Reduction of a market's APR causes the market's reserve ratio to increase, so the borrower is forced to make it possible for more lenders to exit the market if they substantially reduce the interest rate.

Within the hooks contract, the borrower configures each provider with a TTL - the amount of time a credential granted by the provider is valid.

The provider itself defines whether it is a "pull provider", meaning whether the hooks contract can query the role provider to check if a lender has a credential, using only the lender's address.

## Enabled hooks

When a borrower deploys a market, they provide a `HooksConfig` specifying the flags they want to enable on the market; however, the final set of hooks that will be enabled on the market is decided by the hooks instance, not the borrower.

The following logic is applied:
- All hooks set by the borrower other than `useOnDeposit`, `useOnQueueWithdrawal` and `useOnTransfer` are unset, as this hooks contract does nothing with the other optional hooks.
- `useOnSetAnnualInterestAndReserveRatioBips` is always enabled, as it provides some protections for lenders when the borrower modifies a market's APR.
- If `useOnQueueWithdrawal` is enabled:
    - The market will save flags `depositRequiresAccess = useOnDeposit` and `transferRequiresAccess = useOnTransfer`
    - The deposit and transfer flags in the market's HooksConfig will be enabled

The withdrawal, transfer and deposit flags provided by the borrower determine whether these functions will be access-gated; however, if the withdrawal function is access-gated, the deposit and transfer hooks will always be enabled on the market. This is to ensure that if a market requires a credential for withdrawals, any account that ever makes a deposit or receives a transfer while at the same time having a valid credential will always be able to make a withdrawal in the future.

### Known Lenders

`AccessControlHooks` has a second kind of authorization besides the normal credentials, which is the "known lender" status. A known lender is any account that has ever deposited to a market or received market tokens, while at the same time having a valid credential. Known lenders do not require valid credentials at the time they go to queue a withdrawal or receive market tokens.

For a longer explanation of why this is in place, you can review the "mitigation" section of [this PR](https://github.com/wildcat-finance/v2-protocol/pull/33). In short, if a lender has at some point had access to a market and passed the borrower's access requirements, that lender should always have the ability to withdraw from the market as there would be little reason the borrower could give for why they were willing to accept the lender's money but are unable to pay them back unless the lender is sanctioned, in which case the sanctions handling would make this feature moot regardless. 

### `setAnnualInterestAndReserveRatioBips`

Increases the reserve ratio when a market's APR is reduced by more than 25%.

### `onDeposit`

## Role providers

A role provider is an Ethereum account that is capable of granting credentials to lenders. It tells the market's access control hooks whether an account meets that provider's criteria and, if the criteria require regular updates, the last time it verified they meet those criteria. Example: a third party KYC provider would say whether an account has passed their KYC process and the last timestamp they did.

Role providers allow a borrower to define who they are willing to do business with and in what ways, using any arbitrary criteria they wish. They might only allow deposits from lenders who can pass some KYC process, or who hold a particular token, or any other check they might be interested in using as an access gate.

When deploying a market, the borrower can specify which functions out of `deposit`, `transfer` (for recipients), and `queueWithdrawal` require a credential. These functions will then only allow approved lenders to interact with those functions on the market (see: [Known Lenders](#known-lenders) for exceptions).

### Managing role providers

The borrower can add and remove role providers at will. When adding a role provider, the borrower specifies a "time to live" (TTL) - the amount of time that a credential granted by that provider will remain valid. For example, they might want to provide access to anyone who has ever met the criteria, in which case the TTL could be `type(uint32).max`, or they might always want to make sure the role provider would still grant the lender a credential in every block, in which case the TTL could be zero.

### Credentials

Code: [src/types/LenderStatus.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/types/LenderStatus.sol)

A credential for a particular lender saves a few things:
- `lastProvider` - The address of the last role provider that granted the lender a credential
- `timeToLive` - The duration in seconds a credential from that provider lasts.
- `canRefresh` - Whether the provider that granted the credential is a "pull provider", meaning the hooks instance can query the provider to try refreshing the credential.

The time to live defines how long credentials are cached, and thus how often they must be refreshed. If a lender has a valid credential when they execute a gated function -- meaning they have been granted a credential which has not expired by a provider that has not since been removed -- they will be granted access to that function. This can lead to situations where the original role provider might actually not be willing to grant the lender the same credential anymore, but because the cached version is being used, that won't be reflected until the credential is removed.

**Credential Revocation**

Credentials can be removed in a few ways:
- The credential can expire because the TTL has elapsed.
- The borrower can intervene to block a lender from depositing, which will revoke any credentials they have been granted.
- The provider can revoke credentials for accounts it previously granted.
- The borrower can remove the provider, which will cause all credentials it previously granted to become invalid.

### How role providers grant access

Role providers can "push" credentials to the hooks contract by calling `grantRole`:
- `grantRole(address account, uint32 roleGrantedTimestamp) external`

There are three functions that the hooks contract can call on role providers:
- `isPullProvider() external view returns (bool)`
  - Defines whether the hooks contract can retrieve credentials using `getCredential`
- `getCredential(address account) external view returns (uint32 timestamp)`
  - Looks up a credential for an account using only its address, so it must queryable in real time from on-chain data.
- `validateCredential(address account, bytes calldata data) external returns (uint32 timestamp)`
  - Attempts to validate a credential from some arbitrary data (e.g. ecdsa signature or merkle proof).

## tryValidateAccess(address lender, bytes hooksData)

When a restricted function is called, the access control contract will attempt to validate the caller's access to the market in several ways.

1. If lender has an unexpired credential from a provider that is still supported, return true.
2. If the lender provided `hooksData`, run [`handleHooksData(lender, hooksData)`](#handleHooksDataaddress-lender-bytes-hooksData)
    - If it returns a valid credential, go to step 5
3. If the lender has an expired credential from a pull provider that is still supported, try to refresh their credential with `getCredential` (see: [tryPullCredential](#tryPullCredentialaddress-provider-address-lender))
   - If it returns a valid credential, go to step 5
4. Loop over every pull provider in `pullProviders` (other than the existing provider and provider in `hooksData`, if they exist)
    - Run [tryPullCredential](#tryPullCredentialaddress-provider-address-lender) on each provider.
    - If any returns a valid credential, break the loop and go to step 5
5. If any provider yielded a valid credential, update the lender's status in storage with the new credential and return.
6. Otherwise, throw an error.

```mermaid
flowchart TD
    validateAccess[["tryValidateAccess(address lender, bytes hooksData)"]] --> hasUnexpiredCredential{Lender has\nunexpired credential?}
    hasUnexpiredCredential -- yes --> returnTrue([Access verified])
    hasUnexpiredCredential -- no --> providedHooksData{hooksData?}
    providedHooksData -- yes --> callHandleHooksData[["handleHooksData(lender, hooksData)"]]
    callHandleHooksData -- valid credential --> step5[(Write credential\nto storage)] --> returnTrue
    callHandleHooksData -- no valid credential --> expiredCredential{Lender has\nexpired credential?}
    providedHooksData -- no --> expiredCredential
    expiredCredential -- yes --> callTryPullCredential1[["tryPullCredential(existing provider, lender)"]]
    callTryPullCredential1 -- valid credential --> step5
    callTryPullCredential1 -- no valid credential --> loopStart
    expiredCredential -- no --> loopStart

    subgraph loopProviders [Loop over pull providers]
        loopStart{Next provider}
        loopStart -. next provider .-> callTryPullCredential2[["tryPullCredential(next provider, lender)"]]
        callTryPullCredential2 -. no valid credential .-> loopStart
        loopStart -- no more providers --> throwErrorHandle{{Throw}}
    end
    callTryPullCredential2 -- valid credential --> step5
```

## tryPullCredential(address provider, address lender)

1. If the provider is not approved, return with no valid credential
2. Call `getCredential` on the provider
     - If it reverts, return with no valid credential
3. Add the returned `timestamp` to the provider's TTL to get the expiry
4. If the resulting credential is expired, return with no valid credential
5. Return with valid credential


```mermaid
flowchart TD
    A[["tryPullCredential(address provider, address lender)"]] --> B{provider\n approved?}
    B -- yes --> X{"provider is\npull provider?"}
    B -- no --> C([No valid credential])
    X -- yes --> D["Call provider.getCredential(lender)"]
    X -- no --> C
    D -- revert --> C
    D -- invalid data --> C
    D -- timestamp --> T[+ provider's TTL = expiry] --> F{expired?}
    F -- yes --> C
    F -- no --> G([Valid credential])
```

## handleHooksData(address lender, bytes hooksData)

1. Is `hooksData` 20 bytes?
    - If not, go to 2
    - Set `provider` to `hooksData`
    - Return result of `tryPullCredential(provider, lender)`
2. Is `hooksData` more than 20 bytes?
     - If not, return false
3. Take first 20 bytes as `provider`, the rest is `validateData`
4. If the provider is not approved, return false
5. Call `validateCredential(lender, validateData)`
    - If it reverts, return false
    - If it returns invalid data, throw an error because the call could have side effects
6. Add the returned timestamp to the provider's TTL to calculate the expiry
7. If it is expired, return false
8. Return true
  
```mermaid
flowchart TD
    handleData[["handleHooksData(address lender, bytes hooksData)"]] --> check20Bytes{is hooksData\n20 bytes?}
    check20Bytes -- no --> checkMoreThan20Bytes{more than\n20 bytes?}
    checkMoreThan20Bytes -- no --> invalidCredential([No valid credential])
    checkMoreThan20Bytes -- yes --> extractProviderAndData["provider = hooksData[0:20]\nvalidateData = hooksData[20:]"]
    extractProviderAndData --> isProviderApproved{provider\n approved?}
    isProviderApproved -- no --> invalidCredential
    isProviderApproved -- yes --> callValidateCredential["Call provider.validateCredential(lender, validateData)"]
    callValidateCredential -- revert --> invalidCredential
    callValidateCredential -- timestamp --> calculateExpiry["+ provider's TTL = expiry"] --> checkExpiry{expired?}
    callValidateCredential -- invalid data --> throwError{{Throw}}
    checkExpiry -- yes --> invalidCredential
    checkExpiry -- no --> validCredential([Valid credential])
    check20Bytes -- yes --> extractProvider["provider = hooksData"] --> callPullCredential[["tryPullCredential(provider, lender)"]]
    callPullCredential -.-> invalidCredential
    callPullCredential -.-> validCredential
```