# Hooks

Wildcat V2 markets support hooks which can add additional behavior to the markets, such as handling access control or adding new features.

The goal of the hooks feature is two-fold: to allow restrictions to be set for individual markets and to enable secondary actions that occur in reaction to market actions.

Some examples of the individualized restrictions hooks enable are:

- An access control scheme that allows lenders to access markets without manual approval by the borrower
- Minimum deposit requirements
- Time restrictions on withdrawals, i.e. no withdrawals for the first 3 months

An example of the additional behavior hooks enable is the ability to add a masterchef-style system that distributes rewards to lenders, which requires tracking token balances for the market on a separate contract.

This hooks system was chosen to make Wildcat V2 more modular than V1 and improve our ability to develop and deploy new features for Wildcat markets without changing the rest of our core infrastructure like factories or the base market contract, or needing to re-audit the static parts of the codebase.

## Hooks Templates

The Wildcat team will develop various templates for hooks contracts, with each intended for use with a separate kind of market. For example, our initial hooks template only provides access control for lenders and some basic restrictions on APR changes, whereas a future template might provide for withdrawal time limits on hooked markets or token rewards distribution.

Approved templates will be deployed as stored initcode (constructor code with a leading zero byte to prevent execution) and approved on the HooksFactory contract. Borrowers who are registered on the arch-controller can then select from the available templates when deploying new markets.

## Hooks Deployment

Hooks contracts can be deployed by borrowers registered on the arch controller. Borrowers can choose to deploy a new hooks instance for each market (which they might want to do if the markets need different requirements for access, or they want to use a different hooks template), or to re-use the same hooks instance for several markets (if they want the same kind of market and the hooks instance supports use with multiple markets).

Each hooks instance defines a set of optional hooks and a set of required hooks. When deploying a market, the borrower specifies which hooks the market should utilize, and the market will use the hooks which are marked as required by the hooks instance or marked optional and selected by the borrower.

Once a market is deployed, its hooks instance can not be edited, nor can the set of hooks it uses.

[HooksConfig](Hooks%20150b66c642c643f3927a464a9fe6b5d7/HooksConfig%205ebe318281ac4266bacb611b8656c2a8.md)

[Factory](Hooks%20150b66c642c643f3927a464a9fe6b5d7/Factory%20f48e841f20ea46a88d9c9e26a0220378.md)

[How hooks work](./How%20Hooks%20Work.md)