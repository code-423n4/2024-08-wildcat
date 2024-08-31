# Fixed Term Loan Hooks

Code: [src/access/FixedTermLoanHooks.sol](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/access/FixedTermLoanHooks.sol)

The fixed term loan hooks template is identical to the [access control hooks](./Access%20Control%20Hooks.md) template with one additional feature - the borrower can define a timestamp before which the market is considered a "closed term" loan, where withdrawals are disallowed. This expiry time can be reduced but can not be set to a later date after deployment.

## `onCreateMarket`

When deploying a market, the borrower must provide an ABI encoded timestamp for the market's `fixedTermEndTime` in the `hooksData` field of `HooksFactory.deployMarket` or `HooksFactory.deployMarketAndHooks`. This time can not be in the past and can not be more than one year in the future. They can optionally provide a minimum deposit amount by setting `hooksData` to the ABI encoded tuple `(fixedTermEndTime, minimumDeposit)`.

The `onQueueWithdrawal` hook will always be enabled, but will only require access if the borrower's provided config had `useOnQueueWithdrawal` enabled, which will also affect the transfer and deposit hooks in the same way as `AccessControlHooks`.