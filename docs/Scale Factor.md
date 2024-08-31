# Scaling

### tl;dr

This page is fairly long as we get a lot of questions about the scaling mechanics and wanted to be thorough, but here's the condensed version:

- Wildcat markets have _scaled token amounts_ and _market token amounts_, where scaled tokens represent shares in the market that only change upon deposit or withdrawal, and market tokens represent debt owed by the borrower in units of the base asset.
- The _scale factor_ is the ratio between scaled and market token amounts.
   - For market WTKN with underlying asset TKN, 1 scaledWTKN is worth `1 * scaleFactor` WTKN, and 1 WTKN is worth 1 TKN in debt from the borrower.
- The scale factor constantly grows with interest, causing the market token to rebase as debt accrues.
- All the standard market functions (`balanceOf`, `totalSupply`, `transfer`, `deposit`, `withdraw`, etc.) use _market token amounts_.
- The scaled query functions (`scaledBalanceOf`, `scaledTotalSupply`) return _scaled token amounts_, equivalent to market shares.

### Relevant Code

In the codebase, the scale factor is stored as a ray value, meaning it has a base unit of 1e27, so 1.1e27 is 1.1. A scale factor of 1.1 in a market would mean one token deposited when the market was first created is now worth 1.1 tokens due to interest.

The [MathUtils](https://github.com/code-423n4/2024-08-wildcat/blob/main/src/libraries/MathUtils.sol) library contains the math functions for dividing / multiplying ray values.

## Scaled Tokens

A key component of the Wildcat contracts is the scale factor and scaled token amounts - it's crucial to all of the protocol's behavior and should be understood before diving into the codebase. If you're already familiar with Aave, our scaling works the same way as aTokens, so you can skip this page; otherwise, there are a few ways to think of scaling, but the best is probably by analogy to token vaults.

### Typical Token Vaults

Suppose we have an [ERC4626](https://eips.ethereum.org/EIPS/eip-4626#methods) vault called VUSDC which holds USDC. The vault is itself a token where 1 VUSDC is 1 share of ownership in the USDC held by the vault. The vault has 100 shares (`VUSDC.totalSupply() = 100`) and holds 200 USDC (`VUSDC.totalAssets() = 200`), so every 1 VUSDC is convertible to 2 USDC.

Alice owns 10 VUSDC `VUSDC.balanceOf(alice) = 10`. To get the amount of USDC her shares can be converted to, we'd call `VUSDC.convertToAssets(10) = 20`. If the vault receives another 100 USDC, Alice still has 10 shares, but now `convertToAssets(10)` will return 30, because the ratio of USDC to VUSDC has increased by 50%.

So in a typical vault, you have shares which are your balance in the vault and you have assets which your shares are convertible to, where the "assets" are always the actual assets held by the vault at a given point in time (or the convertible value of assets held by the vault, if they're wrapped in a secondary token). Pretty simple.

### Wildcat Markets

Wildcat's scaling mechanism works in a similar way, except that wildcat market tokens represent the _value_ of shares rather than the _number_ of shares, and wildcat markets constantly rebase with interest.

**Scaled Token Amounts**

The first important distinction is that in Wildcat markets, _market tokens_ (the values reported when using the ERC20 functions `balanceOf`, `totalSupply` on a market) represent the _value_ of shares rather than the number of shares, and _scaled tokens_ represent the number of shares.

We also refer to market token amounts as "normalized" amounts, as they have been converted to units that always relate 1:1 to amounts of underlying assets.

Using numbers from the previous example and swapping VUSDC for WUSDC, when the market has 100 shares and 200 USDC:

Alice has 10 out of 100 scaled tokens (shares):

```solidity
WUSDC.scaledBalanceOf(alice) = 10
WUSDC.scaledTotalSupply() = 100
```

but she has 20 out of 200 normalized tokens (asset value):

```solidity
WUSDC.balanceOf(alice) = 20
WUSDC.totalSupply() = 200
```

> Notice that so far, `WUSDC.balanceOf(alice)` for a Wildcat market is equivalent to `VUSDC.convertToAssets(VUSDC.balanceOf(account))` for an ERC4626.

**Rebasing with interest**

The second important distinction is that Wildcat markets constantly rebase with interest, and markets do not always hold all of the assets that shares are worth.

An ERC4626 would typically hold all of its underlying assets in some liquid form, meaning Alice can always burn her 1 VUSDC and immediately receive 2 USDC back. `VUSDC.totalAssets()` will always report the amount of USDC that the vault is worth, and that is always equivalent to the amount of USDC that it has immediate access to (for the sake of this comparison). `ERC4626.convertToAssets(shares)` is just `shares * totalAssets / totalShares`.

Wildcat markets are uncollateralized lending markets, which adds two other factors to this equation:

- Interest is always accruing from the borrower. 1 WUSDC in block `n` is worth more than 1 WUSDC in block `n - 1`, even though the market contract has not received any more USDC.
- The market may not always have the assets that shares are worth in a liquid form, both because the underlying assets can be borrowed and because the constant interest accrual is always increasing the borrower's debt. This makes `totalAssets` useless for determining the value of 1 WUSDC.

The way this is handled is with the `scaleFactor` - the ratio between the number of shares and the amount of underlying assets that shares are worth (but not necessarily instantly redeemable for). Every time the market is updated for the first time in a block, the scale factor is multiplied by the amount of interest that has accrued since the last update (Wildcat interest rates are auto-compounding).

To mint market tokens, lenders use the deposit function, which takes a normalized (underlying) token amount that the lender wants to transfer. This is divided by the `scaleFactor`, yielding the number of scaled tokens / shares they have minted.

Similarly, when a lender withdraws an amount of their market tokens, they must burn `scaledAmountToBurn = normalizedAmount / scaleFactor`.

The result of all of this is that the market token represents _the amount of debt owed by the borrower at a given point in time_, and is thus a measure of an eventual amount of underlying tokens assuming the borrower repays their debts. It does not measure the shares owned by an account or the amount of underlying assets those shares are instantly redeemable for.

Just to reiterate the terminology here:

- the scale factor is the ratio of debt owed by the borrower to shares in the market. If the scaleFactor is 2, 1 scaled token equals 2 market tokens.
- "normalized amount" is any amount denominated in units of the base asset (e.g. USDC). All market functions that use token amounts (other than `scaledBalanceOf, scaledTotalSupply`) use normalized amounts.
- "market tokens" are normalized amounts of scaled tokens, and represent the underlying assets the borrower is obligated to eventually repay
- `scaleAmount(x)` divides a normalized amount `x` by the scale factor
- `normalizeAmount(x)` multiplies a scaled amount `x` by the scale factor

**Basic Example**

1. Bob deposits 100 TKN into the wildcat market wTKN which has an annual interest rate of 10% as soon as the market is created ($T_1$):

   $T_1$

   - scaleFactor = 1
   - scaledBalanceOf(bob) = 100
   - balanceOf(bob) = scaledBalanceOf(bob) \* scaleFactor = 100
   - scaledTotalSupply = 100
   - totalSupply = (scaledTotalSupply \* scaleFactor) = 100

2. We update the market after half a year ($T_{2}$):

   $T_2$

   - scaleFactor = previousScaleFactor \* (1 + APR \* timeElapsed / oneYear) = 1.05
   - scaledBalanceOf(bob) = 100
   - balanceOf(bob) = scaledBalanceOf(bob) \* scaleFactor = 105
   - scaledTotalSupply = 100
   - totalSupply = (scaledTotalSupply \* scaleFactor) = 105

3. In the same block, Alice deposits 210 TKN ($T_{3}$):

   $T_{3}$

   - scaleFactor = 1.05
   - scaledBalanceOf(bob) = 100
   - balanceOf(bob) = 105
   - scaledBalanceOf(alice) = deposit / scaleFactor = 210 / 1.05 = 200
   - balanceOf(alice) = scaledBalanceOf(alice) \* scaleFactor = 210
   - scaledTotalSupply = 300
   - totalSupply = (scaledTotalSupply \* scaleFactor) = 315

4. After another half a year, we update the market again ($T_4$)

   $T_4$

   - scaleFactor = previousScaleFactor \* (1 + APR \* timeElapsed / oneYear) = 1.1025
   - scaledBalanceOf(bob) = 100
   - balanceOf(bob) = scaledBalanceOf(bob) \* scaleFactor = 110.25
   - scaledBalanceOf(alice) = 200
   - balanceOf(alice) = scaledBalanceOf(alice) \* scaleFactor = 220.50
   - scaledTotalSupply = 300
   - totalSupply = (scaledTotalSupply \* scaleFactor) = 330.75
