# V2 Changelog

### Lens

Removed the lens contracts from the core protocol repository.

### Market deployment

**Create2 restrictions**

Borrowers are no longer restricted to deploying one market per combination of (asset, name, symbol), which was an issue when a borrower needed to close and recreate an existing market. When deploying a market, the borrower can now provide an arbitrary salt in the style of 0age's ImmutableCreate2Factory, where the first 20 bytes must either be zero or match the borrower's address, and the remaining 12 bytes can be any value so long as the full salt has not already been used.

**Name/symbol length**

Increased maximum supported name/symbol length for underlying contract from 32 to `63 - prefix.length`.
The name/symbol queries now support arbitrary length strings; once combined with their prefixes, each must fit into two slots, with one byte reserved for the string length.

### Market

**Accounts**
- Accounts no longer have a `role` field, their ability to access various functions (other than borrower-only ones) is not restricted within the market itself, this is delegated to the market's hooks.

**Handling of sanctioned accounts**

- Removed `stunningReversal` because accounts no longer have roles marking them as sanctioned
- Market tokens are forced into a withdrawal batch rather than being transferred to an escrow when an account is marked as sanctioned. Withdrawal execution on a sanctioned account still transfers the underlying assets to the corresponding escrow.
- Functions which are not accessible to sanctioned entities no longer fail gracefully (in V1 they would block the account rather than revert). They now revert with an `AccountBlocked` error when the account is sanctioned.

**Withdrawal batch rounding**

Normalized values for withdrawal batch payments are now rounded down rather than up to prevent a bug where closed markets could have their last withdrawal batch become unclosable due to underpayment by a few wei.

**Token rescue function**

For assets other than the market token itself or the underlying asset, ERC20 tokens sent to the contract can be recovered by the borrower.

**Market closure**

- When a borrower closes a market that has pending withdrawals or unpaid withdrawal batches, rather than reverting, the market now steps through the list of unpaid batches and closes them after transferring all remaining debt from the borrower.
- `closeMarket` now callable by borrower rather than controller.

**ReentrancyGuard**

The ReentrancyGuard now uses transient storage, using a modified version of 0age's ReentrancyGuard from Seaport.

**APR/reserve ratio setters**

- Removed `setAnnualInterestBips` and `setReserveRatioBips`
- Added `setAnnualInterestAndReserveRatioBips`
- Now callable by borrower rather than controller

**Misc.**

Replaced most of the remaining ABI decoders/encoders for calls and large structs with manual assembly coder functions.

- Custom encoder for writing MarketState to storage.
- Custom decoder for constructor parameters and factory call.
- Custom encoders for all sentinel calls in market.
- Custom name/symbol query functions
- Custom state initialization in constructor, only touching slots that are actually initialized.

### Market Control

Market controllers have been removed in favor of borrower-controlled markets with hooks that can impose their own restrictions. By default, the market itself does not restrict basic access to the market.

