# Report


## Gas Optimizations


| |Issue|Instances|
|-|:-|:-:|
| [GAS-1](#GAS-1) | `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings) | 13 |
| [GAS-2](#GAS-2) | Using bools for storage incurs overhead | 3 |
| [GAS-3](#GAS-3) | Cache array length outside of loop | 4 |
| [GAS-4](#GAS-4) | For Operations that will not overflow, you could use unchecked | 216 |
| [GAS-5](#GAS-5) | Avoid contract existence checks by using low level calls | 2 |
| [GAS-6](#GAS-6) | Functions guaranteed to revert when called by normal users can be marked `payable` | 25 |
| [GAS-7](#GAS-7) | `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`) | 16 |
| [GAS-8](#GAS-8) | Using `private` rather than `public` for constants, saves gas | 2 |
| [GAS-9](#GAS-9) | Increments/decrements can be unchecked in for-loops | 15 |
| [GAS-10](#GAS-10) | Use != 0 instead of > 0 for unsigned integer comparison | 32 |
### <a name="GAS-1"></a>[GAS-1] `a = a + b` is more gas effective than `a += b` for state variables (excluding arrays and mappings)
This saves **16 gas per instance.**

*Instances (13)*:
```solidity
File: ./src/market/WildcatMarket.sol

78:     account.scaledBalance += scaledAmount;

85:     state.scaledTotalSupply += scaledAmount;

237:       currentlyHeld += remainingDebt;

```

```solidity
File: ./src/market/WildcatMarketBase.sol

682:     batch.scaledAmountBurned += scaledAmountBurned;

683:     batch.normalizedAmountPaid += normalizedAmountPaid;

687:     state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

716:     batch.scaledAmountBurned += scaledAmountBurned;

717:     batch.normalizedAmountPaid += normalizedAmountPaid;

721:     state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

```

```solidity
File: ./src/market/WildcatMarketToken.sol

85:     toAccount.scaledBalance += scaledAmount;

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

113:     _withdrawalData.accountStatuses[expiry][accountAddress].scaledAmount += scaledAmount;

114:     batch.scaledTotalAmount += scaledAmount;

115:     state.scaledPendingWithdrawals += scaledAmount;

```

### <a name="GAS-2"></a>[GAS-2] Using bools for storage incurs overhead
Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

*Instances (3)*:
```solidity
File: ./src/WildcatSanctionsSentinel.sol

26:   mapping(address borrower => mapping(address account => bool sanctionOverride))

```

```solidity
File: ./src/access/AccessControlHooks.sol

91:   mapping(address lender => mapping(address market => bool)) public isKnownLenderOnMarket;

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

102:   mapping(address lender => mapping(address market => bool)) public isKnownLenderOnMarket;

```

### <a name="GAS-3"></a>[GAS-3] Cache array length outside of loop
If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

*Instances (4)*:
```solidity
File: ./src/WildcatArchController.sol

124:     for (uint256 i = 0; i < contracts.length; i++) {

```

```solidity
File: ./src/access/AccessControlHooks.sol

399:     for (uint256 i = 0; i < accounts.length; i++) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

436:     for (uint256 i = 0; i < accounts.length; i++) {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

222:     for (uint256 i = 0; i < accountAddresses.length; i++) {

```

### <a name="GAS-4"></a>[GAS-4] For Operations that will not overflow, you could use unchecked

*Instances (216)*:
```solidity
File: ./src/HooksFactory.sol

4: import './libraries/LibERC20.sol';

5: import './interfaces/IWildcatArchController.sol';

6: import './libraries/LibStoredInitCode.sol';

7: import './libraries/MathUtils.sol';

8: import './ReentrancyGuard.sol';

9: import './interfaces/WildcatStructsAndEnums.sol';

10: import './access/IHooks.sol';

11: import './IHooksFactory.sol';

12: import './types/TransientBytesArray.sol';

13: import './spherex/SphereXProtectedRegisteredBase.sol';

38:     TransientBytesArray.wrap(uint256(keccak256('Transient:TmpMarketParametersStorage')) - 1);

230:     uint256 count = end - start;

232:     for (uint256 i = 0; i < count; i++) {

233:       arr[i] = _hooksTemplates[start + i];

255:     uint256 count = end - start;

257:     for (uint256 i = 0; i < count; i++) {

258:       arr[i] = markets[start + i];

321:         mstore(0x00, 0x30116425) // DeploymentFailed()

563:     uint256 count = marketEndIndex - marketStartIndex;

577:     for (uint256 i = 0; i < count; i++) {

578:       address market = markets[marketStartIndex + i];

```

```solidity
File: ./src/WildcatArchController.sol

4: import { EnumerableSet } from 'openzeppelin/contracts/utils/structs/EnumerableSet.sol';

5: import 'solady/auth/Ownable.sol';

6: import './spherex/SphereXConfig.sol';

7: import './libraries/MathUtils.sol';

8: import './interfaces/ISphereXProtectedRegisteredBase.sol';

124:     for (uint256 i = 0; i < contracts.length; i++) {

185:     uint256 count = end - start;

187:     for (uint256 i = 0; i < count; i++) {

188:       arr[i] = _borrowers.at(start + i);

228:     uint256 count = end - start;

230:     for (uint256 i = 0; i < count; i++) {

231:       arr[i] = _assetBlacklist.at(start + i);

274:     uint256 count = end - start;

276:     for (uint256 i = 0; i < count; i++) {

277:       arr[i] = _controllerFactories.at(start + i);

325:     uint256 count = end - start;

327:     for (uint256 i = 0; i < count; i++) {

328:       arr[i] = _controllers.at(start + i);

376:     uint256 count = end - start;

378:     for (uint256 i = 0; i < count; i++) {

379:       arr[i] = _markets.at(start + i);

```

```solidity
File: ./src/WildcatSanctionsEscrow.sol

4: import './interfaces/IERC20.sol';

5: import './interfaces/IWildcatSanctionsEscrow.sol';

6: import './interfaces/IWildcatSanctionsSentinel.sol';

7: import './libraries/LibERC20.sol';

```

```solidity
File: ./src/WildcatSanctionsSentinel.sol

4: import { IChainalysisSanctionsList } from './interfaces/IChainalysisSanctionsList.sol';

5: import { IWildcatSanctionsSentinel } from './interfaces/IWildcatSanctionsSentinel.sol';

6: import { WildcatSanctionsEscrow } from './WildcatSanctionsEscrow.sol';

```

```solidity
File: ./src/access/AccessControlHooks.sol

4: import '../libraries/BoolUtils.sol';

5: import '../libraries/MathUtils.sol';

6: import '../types/RoleProvider.sol';

7: import '../types/LenderStatus.sol';

8: import './IRoleProvider.sol';

9: import './MarketConstraintHooks.sol';

10: import '../libraries/SafeCastLib.sol';

121:   constructor(address _deployer, bytes memory /* args */) IHooks() {

269:     uint256 lastIndex = _pullProviders.length - 1;

399:     for (uint256 i = 0; i < accounts.length; i++) {

594:     for (uint256 i = 0; i < providerCount; i++) {

814:     uint32 /* expiry */,

815:     uint /* scaledAmount */,

816:     MarketState calldata /* state */,

832:     uint128 /* normalizedAmountWithdrawn */,

833:     MarketState calldata /* state */,

851:     address /* caller */,

852:     address /* from */,

854:     uint /* scaledAmount */,

855:     MarketState calldata /* state */,

886:     uint /* normalizedAmount */,

887:     MarketState calldata /* state */,

888:     bytes calldata /* extraData */

901:     MarketState calldata /* state */,

902:     bytes calldata /* hooksData */

906:     address /* lender */,

907:     MarketState calldata /* state */,

908:     bytes calldata /* hooksData */

912:     uint256 /* maxTotalSupply */,

913:     MarketState calldata /* state */,

914:     bytes calldata /* hooksData */

938:     uint16 /* protocolFeeBips */,

939:     MarketState memory /* intermediateState */,

940:     bytes calldata /* extraData */

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

4: import '../libraries/BoolUtils.sol';

5: import '../libraries/MathUtils.sol';

6: import '../types/RoleProvider.sol';

7: import '../types/LenderStatus.sol';

8: import './IRoleProvider.sol';

9: import './MarketConstraintHooks.sol';

10: import '../libraries/SafeCastLib.sol';

132:   constructor(address _deployer, bytes memory /* args */) IHooks() {

189:       fixedTermEndTime < block.timestamp || (fixedTermEndTime - block.timestamp) > MaximumLoanTerm

306:     uint256 lastIndex = _pullProviders.length - 1;

436:     for (uint256 i = 0; i < accounts.length; i++) {

631:     for (uint256 i = 0; i < providerCount; i++) {

850:     uint32 /* expiry */,

851:     uint /* scaledAmount */,

852:     MarketState calldata /* state */,

875:     uint128 /* normalizedAmountWithdrawn */,

876:     MarketState calldata /* state */,

894:     address /* caller */,

895:     address /* from */,

897:     uint /* scaledAmount */,

898:     MarketState calldata /* state */,

929:     uint /* normalizedAmount */,

930:     MarketState calldata /* state */,

931:     bytes calldata /* extraData */

944:     MarketState calldata /* state */,

945:     bytes calldata /* hooksData */

949:     address /* lender */,

950:     MarketState calldata /* state */,

951:     bytes calldata /* hooksData */

955:     uint256 /* maxTotalSupply */,

956:     MarketState calldata /* state */,

957:     bytes calldata /* hooksData */

981:     uint16 /* protocolFeeBips */,

982:     MarketState memory /* intermediateState */,

983:     bytes calldata /* extraData */

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

4: import './IHooks.sol';

5: import '../libraries/BoolUtils.sol';

138:     address /* deployer */,

139:     address /* marketAddress */,

141:     bytes calldata /* extraData */

169:       originalAnnualInterestBips - annualInterestBips,

179:       uint256 boundRelativeDiff = MathUtils.min(10000, 2 * relativeDiff);

206:     uint16 /* reserveRatioBips */,

208:     bytes calldata /* extraData */

259:       uint32 expiry = uint32(block.timestamp + 2 weeks);

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

95:         mstore(0x00, 0x30116425) // DeploymentFailed()

119:         mstore(0x00, 0x30116425) // DeploymentFailed()

142:         mstore(0x00, 0x30116425) // DeploymentFailed()

173:         mstore(0x00, 0x30116425) // DeploymentFailed()

```

```solidity
File: ./src/libraries/MarketState.sol

4: import './MathUtils.sol';

5: import './SafeCastLib.sol';

6: import './FeeMath.sol';

91:     uint256 scaledRequiredReserves = (state.scaledTotalSupply - scaledWithdrawals).bipMul(

93:     ) + scaledWithdrawals;

95:       state.normalizeAmount(scaledRequiredReserves) +

96:       state.accruedProtocolFees +

109:     uint256 totalAvailableAssets = totalAssets - state.normalizedUnclaimedWithdrawals;

140:       state.normalizeAmount(state.scaledTotalSupply) +

141:       state.normalizedUnclaimedWithdrawals +

```

```solidity
File: ./src/market/WildcatMarket.sol

4: import './WildcatMarketBase.sol';

5: import './WildcatMarketConfig.sol';

6: import './WildcatMarketToken.sol';

7: import './WildcatMarketWithdrawals.sol';

8: import '../WildcatSanctionsSentinel.sol';

57:   ) internal virtual nonReentrant returns (uint256 /* actualAmount */) {

78:     account.scaledBalance += scaledAmount;

85:     state.scaledTotalSupply += scaledAmount;

106:   ) external virtual sphereXGuardExternal returns (uint256 /* actualAmount */) {

132:     state.accruedProtocolFees -= withdrawableFees;

235:       uint256 remainingDebt = totalDebts - currentlyHeld;

237:       currentlyHeld += remainingDebt;

239:       uint256 excessDebt = currentlyHeld - totalDebts;

242:       currentlyHeld -= excessDebt;

253:     uint256 availableLiquidity = currentlyHeld -

254:       (state.normalizedUnclaimedWithdrawals + state.accruedProtocolFees);

268:         availableLiquidity -= normalizedAmountPaid;

274:     for (uint256 i; i < numBatches; i++) {

278:       availableLiquidity -= normalizedAmountPaid;

```

```solidity
File: ./src/market/WildcatMarketBase.sol

4: import '../ReentrancyGuard.sol';

5: import '../spherex/SphereXProtectedRegisteredBase.sol';

6: import '../interfaces/IMarketEventsAndErrors.sol';

7: import '../interfaces/IERC20.sol';

8: import '../IHooksFactory.sol';

9: import '../libraries/FeeMath.sol';

10: import '../libraries/MarketErrors.sol';

11: import '../libraries/MarketEvents.sol';

12: import '../libraries/Withdrawal.sol';

13: import '../libraries/FunctionTypeCasts.sol';

14: import '../libraries/LibERC20.sol';

15: import '../types/HooksConfig.sol';

24:   using FunctionTypeCasts for *;

671:     uint104 scaledAmountOwed = batch.scaledTotalAmount - batch.scaledAmountBurned;

682:     batch.scaledAmountBurned += scaledAmountBurned;

683:     batch.normalizedAmountPaid += normalizedAmountPaid;

684:     state.scaledPendingWithdrawals -= scaledAmountBurned;

687:     state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

690:     state.scaledTotalSupply -= scaledAmountBurned;

702:     uint104 scaledAmountOwed = batch.scaledTotalAmount - batch.scaledAmountBurned;

716:     batch.scaledAmountBurned += scaledAmountBurned;

717:     batch.normalizedAmountPaid += normalizedAmountPaid;

718:     state.scaledPendingWithdrawals -= scaledAmountBurned;

721:     state.normalizedUnclaimedWithdrawals += normalizedAmountPaid;

724:     state.scaledTotalSupply -= scaledAmountBurned;

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

4: import './WildcatMarketBase.sol';

5: import '../libraries/FeeMath.sol';

6: import '../libraries/SafeCastLib.sol';

10:   using FunctionTypeCasts for *;

```

```solidity
File: ./src/market/WildcatMarketToken.sol

4: import './WildcatMarketBase.sol';

8:   using FunctionTypeCasts for *;

58:       uint256 newAllowance = allowed - amount;

81:     fromAccount.scaledBalance -= scaledAmount;

85:     toAccount.scaledBalance += scaledAmount;

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

4: import './WildcatMarketBase.sol';

5: import '../libraries/LibERC20.sol';

6: import '../libraries/BoolUtils.sol';

73:     return newTotalWithdrawn - previousTotalWithdrawn;

96:       expiry = uint32(block.timestamp + duration);

105:     account.scaledBalance -= scaledAmount;

113:     _withdrawalData.accountStatuses[expiry][accountAddress].scaledAmount += scaledAmount;

114:     batch.scaledTotalAmount += scaledAmount;

115:     state.scaledPendingWithdrawals += scaledAmount;

222:     for (uint256 i = 0; i < accountAddresses.length; i++) {

251:     uint128 normalizedAmountWithdrawn = newTotalWithdrawn - status.normalizedAmountWithdrawn;

258:     state.normalizedUnclaimedWithdrawals -= normalizedAmountWithdrawn;

302:     uint256 availableLiquidity = totalAssets() -

303:       (state.normalizedUnclaimedWithdrawals + state.accruedProtocolFees);

310:     while (i++ < numBatches && availableLiquidity > 0) {

```

```solidity
File: ./src/types/HooksConfig.sol

4: import '../access/IHooks.sol';

5: import '../libraries/MarketState.sol';

```

```solidity
File: ./src/types/LenderStatus.sol

3: import './RoleProvider.sol';

```

```solidity
File: ./src/types/RoleProvider.sol

4: import '../libraries/MathUtils.sol';

```

```solidity
File: ./src/types/TransientBytesArray.sol

3: import { Panic_ErrorSelector, Panic_ErrorCodePointer, Panic_InvalidStorageByteArray, Error_SelectorPointer, Panic_ErrorLength } from '../libraries/Errors.sol';

21:       function extractByteArrayLength(data) -> length {

```

### <a name="GAS-5"></a>[GAS-5] Avoid contract existence checks by using low level calls
Prior to 0.8.10 the compiler inserted extra code, including `EXTCODESIZE` (**100 gas**), to check for contract existence for external function calls. In more recent solidity versions, the compiler will not insert these checks if the external call has a return value. Similar behavior can be achieved in earlier versions by using low-level calls, since low level calls never check for contract existence

*Instances (2)*:
```solidity
File: ./src/WildcatSanctionsEscrow.sol

23:     return IERC20(asset).balanceOf(address(this));

```

```solidity
File: ./src/market/WildcatMarketBase.sol

299:     return asset.balanceOf(address(this));

```

### <a name="GAS-6"></a>[GAS-6] Functions guaranteed to revert when called by normal users can be marked `payable`
If a function modifier such as `onlyOwner` is used, the function will revert if a normal user tries to pay the function. Marking the function as `payable` will lower the gas cost for legitimate callers because the compiler will not include checks for whether a payment was provided.

*Instances (25)*:
```solidity
File: ./src/HooksFactory.sol

201:   function disableHooksTemplate(address hooksTemplate) external override onlyArchControllerOwner {

```

```solidity
File: ./src/WildcatArchController.sol

157:   function registerBorrower(address borrower) external onlyOwner {

164:   function removeBorrower(address borrower) external onlyOwner {

200:   function addBlacklist(address asset) external onlyOwner {

207:   function removeBlacklist(address asset) external onlyOwner {

245:   function registerControllerFactory(address factory) external onlyOwner {

253:   function removeControllerFactory(address factory) external onlyOwner {

296:   function registerController(address controller) external onlyControllerFactory {

304:   function removeController(address controller) external onlyOwner {

347:   function registerMarket(address market) external onlyController {

355:   function removeMarket(address market) external onlyOwner {

```

```solidity
File: ./src/access/AccessControlHooks.sol

200:   function setMinimumDeposit(address market, uint128 newMinimumDeposit) external onlyBorrower {

217:   function addRoleProvider(address providerAddress, uint32 timeToLive) external onlyBorrower {

249:   function removeRoleProvider(address providerAddress) external onlyBorrower {

445:   function blockFromDeposits(address account) external onlyBorrower {

456:   function unblockFromDeposits(address account) external onlyBorrower {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

229:   function setMinimumDeposit(address market, uint128 newMinimumDeposit) external onlyBorrower {

236:   function setFixedTermEndTime(address market, uint32 newFixedTermEndTime) external onlyBorrower {

254:   function addRoleProvider(address providerAddress, uint32 timeToLive) external onlyBorrower {

286:   function removeRoleProvider(address providerAddress) external onlyBorrower {

482:   function blockFromDeposits(address account) external onlyBorrower {

493:   function unblockFromDeposits(address account) external onlyBorrower {

```

```solidity
File: ./src/market/WildcatMarket.sol

37:   function rescueTokens(address token) external onlyBorrower {

146:   function borrow(uint256 amount) external onlyBorrower nonReentrant sphereXGuardExternal {

226:   function closeMarket() external onlyBorrower nonReentrant sphereXGuardExternal {

```

### <a name="GAS-7"></a>[GAS-7] `++i` costs less gas compared to `i++` or `i += 1` (same for `--i` vs `i--` or `i -= 1`)
Pre-increments and pre-decrements are cheaper.

For a `uint256 i` variable, the following is true with the Optimizer enabled at 10k:

**Increment:**

- `i += 1` is the most expensive form
- `i++` costs 6 gas less than `i += 1`
- `++i` costs 5 gas less than `i++` (11 gas less than `i += 1`)

**Decrement:**

- `i -= 1` is the most expensive form
- `i--` costs 11 gas less than `i -= 1`
- `--i` costs 5 gas less than `i--` (16 gas less than `i -= 1`)

Note that post-increments (or post-decrements) return the old value before incrementing or decrementing, hence the name *post-increment*:

```solidity
uint i = 1;  
uint j = 2;
require(j == i++, "This will be false as i is incremented after the comparison");
```
  
However, pre-increments (or pre-decrements) return the new value:
  
```solidity
uint i = 1;  
uint j = 2;
require(j == ++i, "This will be true as i is incremented before the comparison");
```

In the pre-increment case, the compiler has to create a temporary variable (when used) for returning `1` instead of `2`.

Consider using pre-increments and pre-decrements where they are relevant (meaning: not where post-increments/decrements logic are relevant).

*Saves 5 gas per instance*

*Instances (16)*:
```solidity
File: ./src/HooksFactory.sol

232:     for (uint256 i = 0; i < count; i++) {

257:     for (uint256 i = 0; i < count; i++) {

577:     for (uint256 i = 0; i < count; i++) {

```

```solidity
File: ./src/WildcatArchController.sol

124:     for (uint256 i = 0; i < contracts.length; i++) {

187:     for (uint256 i = 0; i < count; i++) {

230:     for (uint256 i = 0; i < count; i++) {

276:     for (uint256 i = 0; i < count; i++) {

327:     for (uint256 i = 0; i < count; i++) {

378:     for (uint256 i = 0; i < count; i++) {

```

```solidity
File: ./src/access/AccessControlHooks.sol

399:     for (uint256 i = 0; i < accounts.length; i++) {

594:     for (uint256 i = 0; i < providerCount; i++) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

436:     for (uint256 i = 0; i < accounts.length; i++) {

631:     for (uint256 i = 0; i < providerCount; i++) {

```

```solidity
File: ./src/market/WildcatMarket.sol

274:     for (uint256 i; i < numBatches; i++) {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

222:     for (uint256 i = 0; i < accountAddresses.length; i++) {

310:     while (i++ < numBatches && availableLiquidity > 0) {

```

### <a name="GAS-8"></a>[GAS-8] Using `private` rather than `public` for constants, saves gas
If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

*Instances (2)*:
```solidity
File: ./src/WildcatSanctionsSentinel.sol

13:   bytes32 public constant override WildcatSanctionsEscrowInitcodeHash =

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

97:   uint32 public constant MaximumLoanTerm = 365 days;

```

### <a name="GAS-9"></a>[GAS-9] Increments/decrements can be unchecked in for-loops
In Solidity 0.8+, there's a default overflow check on unsigned integers. It's possible to uncheck this in for-loops and save some gas at each iteration, but at the cost of some code readability, as this uncheck cannot be made inline.

[ethereum/solidity#10695](https://github.com/ethereum/solidity/issues/10695)

The change would be:

```diff
- for (uint256 i; i < numIterations; i++) {
+ for (uint256 i; i < numIterations;) {
 // ...  
+   unchecked { ++i; }
}  
```

These save around **25 gas saved** per instance.

The same can be applied with decrements (which should use `break` when `i == 0`).

The risk of overflow is non-existent for `uint256`.

*Instances (15)*:
```solidity
File: ./src/HooksFactory.sol

232:     for (uint256 i = 0; i < count; i++) {

257:     for (uint256 i = 0; i < count; i++) {

577:     for (uint256 i = 0; i < count; i++) {

```

```solidity
File: ./src/WildcatArchController.sol

124:     for (uint256 i = 0; i < contracts.length; i++) {

187:     for (uint256 i = 0; i < count; i++) {

230:     for (uint256 i = 0; i < count; i++) {

276:     for (uint256 i = 0; i < count; i++) {

327:     for (uint256 i = 0; i < count; i++) {

378:     for (uint256 i = 0; i < count; i++) {

```

```solidity
File: ./src/access/AccessControlHooks.sol

399:     for (uint256 i = 0; i < accounts.length; i++) {

594:     for (uint256 i = 0; i < providerCount; i++) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

436:     for (uint256 i = 0; i < accounts.length; i++) {

631:     for (uint256 i = 0; i < providerCount; i++) {

```

```solidity
File: ./src/market/WildcatMarket.sol

274:     for (uint256 i; i < numBatches; i++) {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

222:     for (uint256 i = 0; i < accountAddresses.length; i++) {

```

### <a name="GAS-10"></a>[GAS-10] Use != 0 instead of > 0 for unsigned integer comparison

*Instances (32)*:
```solidity
File: ./src/HooksFactory.sol

2: pragma solidity >=0.8.20;

159:     bool hasOriginationFee = originationFeeAmount > 0;

163:       (protocolFeeBips > 0 && nullFeeRecipient) ||

```

```solidity
File: ./src/ReentrancyGuard.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/WildcatArchController.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/WildcatSanctionsEscrow.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/WildcatSanctionsSentinel.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/access/AccessControlHooks.sol

335:     if (status.lastApprovalTimestamp > 0) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

372:     if (status.lastApprovalTimestamp > 0) {

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

2: pragma solidity >=0.8.20;

226:     if (tmp.expiry > 0) {

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

2: pragma solidity >=0.8.24;

```

```solidity
File: ./src/libraries/MarketState.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarket.sol

2: pragma solidity >=0.8.20;

294:     if (account.scaledBalance > 0) {

```

```solidity
File: ./src/market/WildcatMarketBase.sol

2: pragma solidity >=0.8.20;

459:         if (availableLiquidity > 0) {

504:       if (availableLiquidity > 0) {

529:         if (availableLiquidity > 0) {

638:       if (availableLiquidity > 0) {

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarketToken.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

2: pragma solidity >=0.8.20;

30:     if ((expiry == pendingBatchExpiry).and(expiry > 0)) {

121:     if (availableLiquidity > 0) {

289:     if (repayAmount > 0) {

299:     if (repayAmount > 0) hooks.onRepay(repayAmount, state, _runtimeConstant(0x44));

310:     while (i++ < numBatches && availableLiquidity > 0) {

```

```solidity
File: ./src/types/HooksConfig.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/types/LenderStatus.sol

2: pragma solidity >=0.8.20;

37:     return status.lastApprovalTimestamp > 0;

```

```solidity
File: ./src/types/TransientBytesArray.sol

2: pragma solidity >=0.8.25;

```


## Non Critical Issues


| |Issue|Instances|
|-|:-|:-:|
| [NC-1](#NC-1) | Replace `abi.encodeWithSignature` and `abi.encodeWithSelector` with `abi.encodeCall` which keeps the code typo/type safe | 2 |
| [NC-2](#NC-2) | Constants should be in CONSTANT_CASE | 98 |
| [NC-3](#NC-3) | `constant`s should be defined rather than using magic numbers | 20 |
| [NC-4](#NC-4) | Control structures do not follow the Solidity Style Guide | 88 |
| [NC-5](#NC-5) | Default Visibility for constants | 17 |
| [NC-6](#NC-6) | Consider disabling `renounceOwnership()` | 1 |
| [NC-7](#NC-7) | Functions should not be longer than 50 lines | 156 |
| [NC-8](#NC-8) | Change uint to uint256 | 47 |
| [NC-9](#NC-9) | Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor | 16 |
| [NC-10](#NC-10) | Consider using named mappings | 9 |
| [NC-11](#NC-11) | `address`s shouldn't be hard-coded | 2 |
| [NC-12](#NC-12) | Take advantage of Custom Error's return value property | 122 |
| [NC-13](#NC-13) | Avoid the use of sensitive terms | 22 |
| [NC-14](#NC-14) | Strings should use double quotes rather than single quotes | 3 |
| [NC-15](#NC-15) | Use Underscores for Number Literals (add an underscore every 3 digits) | 3 |
| [NC-16](#NC-16) | Constants should be defined rather than using magic numbers | 8 |
| [NC-17](#NC-17) | Variables need not be initialized to zero | 14 |
### <a name="NC-1"></a>[NC-1] Replace `abi.encodeWithSignature` and `abi.encodeWithSelector` with `abi.encodeCall` which keeps the code typo/type safe
When using `abi.encodeWithSignature`, it is possible to include a typo for the correct function signature.
When using `abi.encodeWithSignature` or `abi.encodeWithSelector`, it is also possible to provide parameters that are not of the correct type for the function.

To avoid these pitfalls, it would be best to use [`abi.encodeCall`](https://solidity-by-example.org/abi-encode/) instead.

*Instances (2)*:
```solidity
File: ./src/WildcatArchController.sol

79:     bytes memory changeSphereXEngineCalldata = abi.encodeWithSelector(

85:       addAllowedSenderOnChainCalldata = abi.encodeWithSelector(

```

### <a name="NC-2"></a>[NC-2] Constants should be in CONSTANT_CASE
For `constant` variable names, each word should use all capital letters, with underscores separating each word (CONSTANT_CASE)

*Instances (98)*:
```solidity
File: ./src/HooksFactory.sol

37:   TransientBytesArray internal constant _tmpMarketParameters =

40:   uint256 internal immutable ownCreate2Prefix = LibStoredInitCode.getCreate2Prefix(address(this));

```

```solidity
File: ./src/ReentrancyGuard.sol

5: uint256 constant NoReentrantCalls_ErrorSelector = 0x7fa8a987;

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

97:   uint32 public constant MaximumLoanTerm = 365 days;

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

40:   uint32 internal constant MinimumDelinquencyGracePeriod = 0;

41:   uint32 internal constant MaximumDelinquencyGracePeriod = 90 days;

43:   uint16 internal constant MinimumReserveRatioBips = 0;

44:   uint16 internal constant MaximumReserveRatioBips = 10_000;

46:   uint16 internal constant MinimumDelinquencyFeeBips = 0;

47:   uint16 internal constant MaximumDelinquencyFeeBips = 10_000;

49:   uint32 internal constant MinimumWithdrawalBatchDuration = 0;

50:   uint32 internal constant MaximumWithdrawalBatchDuration = 365 days;

52:   uint16 internal constant MinimumAnnualInterestBips = 0;

53:   uint16 internal constant MaximumAnnualInterestBips = 10_000;

```

```solidity
File: ./src/types/HooksConfig.sol

9: HooksConfig constant EmptyHooksConfig = HooksConfig.wrap(0);

33: uint256 constant Bit_Enabled_Deposit = 95;

34: uint256 constant Bit_Enabled_QueueWithdrawal = 94;

35: uint256 constant Bit_Enabled_ExecuteWithdrawal = 93;

36: uint256 constant Bit_Enabled_Transfer = 92;

37: uint256 constant Bit_Enabled_Borrow = 91;

38: uint256 constant Bit_Enabled_Repay = 90;

39: uint256 constant Bit_Enabled_CloseMarket = 89;

40: uint256 constant Bit_Enabled_NukeFromOrbit = 88;

41: uint256 constant Bit_Enabled_SetMaxTotalSupply = 87;

42: uint256 constant Bit_Enabled_SetAnnualInterestAndReserveRatioBips = 86;

43: uint256 constant Bit_Enabled_SetProtocolFeeBips = 85;

45: uint256 constant MarketStateSize = 0x01c0;

254:   uint256 internal constant DepositCalldataSize = 0x24;

256:   uint256 internal constant DepositHook_Base_Size = 0x0244;

257:   uint256 internal constant DepositHook_ScaledAmount_Offset = 0x20;

258:   uint256 internal constant DepositHook_State_Offset = 0x40;

259:   uint256 internal constant DepositHook_ExtraData_Head_Offset = 0x200;

260:   uint256 internal constant DepositHook_ExtraData_Length_Offset = 0x0220;

261:   uint256 internal constant DepositHook_ExtraData_TailOffset = 0x0240;

313:   uint256 internal constant QueueWithdrawalHook_Base_Size = 0x0264;

314:   uint256 internal constant QueueWithdrawalHook_Expiry_Offset = 0x20;

315:   uint256 internal constant QueueWithdrawalHook_ScaledAmount_Offset = 0x40;

316:   uint256 internal constant QueueWithdrawalHook_State_Offset = 0x60;

317:   uint256 internal constant QueueWithdrawalHook_ExtraData_Head_Offset = 0x220;

318:   uint256 internal constant QueueWithdrawalHook_ExtraData_Length_Offset = 0x0240;

319:   uint256 internal constant QueueWithdrawalHook_ExtraData_TailOffset = 0x0260;

375:   uint256 internal constant ExecuteWithdrawalHook_Base_Size = 0x0244;

376:   uint256 internal constant ExecuteWithdrawalHook_ScaledAmount_Offset = 0x20;

377:   uint256 internal constant ExecuteWithdrawalHook_State_Offset = 0x40;

378:   uint256 internal constant ExecuteWithdrawalHook_ExtraData_Head_Offset = 0x0200;

379:   uint256 internal constant ExecuteWithdrawalHook_ExtraData_Length_Offset = 0x0220;

380:   uint256 internal constant ExecuteWithdrawalHook_ExtraData_TailOffset = 0x0240;

433:   uint256 internal constant TransferHook_Base_Size = 0x0284;

434:   uint256 internal constant TransferHook_From_Offset = 0x20;

435:   uint256 internal constant TransferHook_To_Offset = 0x40;

436:   uint256 internal constant TransferHook_ScaledAmount_Offset = 0x60;

437:   uint256 internal constant TransferHook_State_Offset = 0x80;

438:   uint256 internal constant TransferHook_ExtraData_Head_Offset = 0x240;

439:   uint256 internal constant TransferHook_ExtraData_Length_Offset = 0x0260;

440:   uint256 internal constant TransferHook_ExtraData_TailOffset = 0x0280;

497:   uint256 internal constant BorrowCalldataSize = 0x24;

499:   uint256 internal constant BorrowHook_Base_Size = 0x0224;

500:   uint256 internal constant BorrowHook_State_Offset = 0x20;

501:   uint256 internal constant BorrowHook_ExtraData_Head_Offset = 0x01e0;

502:   uint256 internal constant BorrowHook_ExtraData_Length_Offset = 0x0200;

503:   uint256 internal constant BorrowHook_ExtraData_TailOffset = 0x0220;

547:   uint256 internal constant RepayHook_Base_Size = 0x0224;

548:   uint256 internal constant RepayHook_State_Offset = 0x20;

549:   uint256 internal constant RepayHook_ExtraData_Head_Offset = 0x01e0;

550:   uint256 internal constant RepayHook_ExtraData_Length_Offset = 0x0200;

551:   uint256 internal constant RepayHook_ExtraData_TailOffset = 0x0220;

597:   uint256 internal constant CloseMarketCalldataSize = 0x04;

600:   uint256 internal constant CloseMarketHook_Base_Size = 0x0204;

601:   uint256 internal constant CloseMarketHook_ExtraData_Head_Offset = MarketStateSize;

602:   uint256 internal constant CloseMarketHook_ExtraData_Length_Offset = 0x01e0;

603:   uint256 internal constant CloseMarketHook_ExtraData_TailOffset = 0x0200;

645:   uint256 internal constant SetMaxTotalSupplyCalldataSize = 0x24;

647:   uint256 internal constant SetMaxTotalSupplyHook_Base_Size = 0x0224;

648:   uint256 internal constant SetMaxTotalSupplyHook_State_Offset = 0x20;

649:   uint256 internal constant SetMaxTotalSupplyHook_ExtraData_Head_Offset = 0x01e0;

650:   uint256 internal constant SetMaxTotalSupplyHook_ExtraData_Length_Offset = 0x0200;

651:   uint256 internal constant SetMaxTotalSupplyHook_ExtraData_TailOffset = 0x0220;

699:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsCalldataSize = 0x44;

701:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_Base_Size = 0x0244;

702:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ReserveRatioBits_Offset = 0x20;

703:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_State_Offset = 0x40;

704:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Head_Offset = 0x0200;

705:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ExtraData_Length_Offset =

707:   uint256 internal constant SetAnnualInterestAndReserveRatioBipsHook_ExtraData_TailOffset = 0x0240;

779:   uint256 internal constant SetProtocolFeeBipsCalldataSize = 0x24;

781:   uint256 internal constant SetProtocolFeeBips_Base_Size = 0x0224;

782:   uint256 internal constant SetProtocolFeeBips_State_Offset = 0x20;

783:   uint256 internal constant SetProtocolFeeBips_ExtraData_Head_Offset = 0x01e0;

784:   uint256 internal constant SetProtocolFeeBips_ExtraData_Length_Offset = 0x0200;

785:   uint256 internal constant SetProtocolFeeBips_ExtraData_TailOffset = 0x0220;

829:   uint256 internal constant NukeFromOrbitCalldataSize = 0x24;

831:   uint256 internal constant NukeFromOrbit_Base_Size = 0x0224;

832:   uint256 internal constant NukeFromOrbit_State_Offset = 0x20;

833:   uint256 internal constant NukeFromOrbit_ExtraData_Head_Offset = 0x01e0;

834:   uint256 internal constant NukeFromOrbit_ExtraData_Length_Offset = 0x0200;

835:   uint256 internal constant NukeFromOrbit_ExtraData_TailOffset = 0x0220;

```

```solidity
File: ./src/types/RoleProvider.sol

7: uint24 constant NotPullProviderIndex = type(uint24).max;

8: RoleProvider constant EmptyRoleProvider = RoleProvider.wrap(0);

```

### <a name="NC-3"></a>[NC-3] `constant`s should be defined rather than using magic numbers
Even [assembly](https://github.com/code-423n4/2022-05-opensea-seaport/blob/9d7ce4d08bf3c3010304a0476a785c70c0e90ae7/contracts/lib/TokenTransferrer.sol#L35-L39) can benefit from using readable constants instead of hex/numeric literals

*Instances (20)*:
```solidity
File: ./src/access/AccessControlHooks.sol

170:     if (hooksData.length == 32) {

623:     if (hooksData.length == 20) {

631:     } else if (hooksData.length > 20) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

179:     if (hooksData.length < 32) revert FixedTermNotProvided();

196:     if (hooksData.length == 64) {

660:     if (hooksData.length == 20) {

668:     } else if (hooksData.length > 20) {

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

66:         revert(0, 4)

168:       10000,

174:     if (relativeDiff <= 2500) {

179:       uint256 boundRelativeDiff = MathUtils.min(10000, 2 * relativeDiff);

259:       uint32 expiry = uint32(block.timestamp + 2 weeks);

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

34:       initCodeStorage := create(0, add(data, 21), createSize)

```

```solidity
File: ./src/market/WildcatMarket.sol

247:     state.reserveRatioBips = 10000;

```

```solidity
File: ./src/market/WildcatMarketBase.sol

203:         sstore(add(_state.slot, 3), slot3)

583:         sstore(add(_state.slot, 2), slot2)

614:         sstore(add(_state.slot, 3), slot3)

```

```solidity
File: ./src/types/TransientBytesArray.sol

22:         length := div(data, 2)

28:         if eq(outOfPlaceEncoding, lt(length, 32)) {

89:       switch lt(length, 32)

```

### <a name="NC-4"></a>[NC-4] Control structures do not follow the Solidity Style Guide
See the [control structures](https://docs.soliditylang.org/en/latest/style-guide.html#control-structures) section of the Solidity Style Guide

*Instances (88)*:
```solidity
File: ./src/HooksFactory.sol

162:     if (

411:     if (

559:     if (!details.exists) revert HooksTemplateNotFound();

```

```solidity
File: ./src/WildcatSanctionsEscrow.sol

35:     if (!canReleaseEscrow()) revert CanNotReleaseEscrow();

```

```solidity
File: ./src/WildcatSanctionsSentinel.sol

129:     if (escrowContract.code.length != 0) return escrowContract;

```

```solidity
File: ./src/access/AccessControlHooks.sol

107:     if (msg.sender != borrower) revert CallerNotBorrower();

167:     if (deployer != borrower) revert CallerNotBorrower();

202:     if (!hookedMarket.isHooked) revert NotHookedMarket();

251:     if (provider.isNull()) revert ProviderNotFound();

340:         if (status.credentialNotExpired(provider)) return status;

379:     if (callingProvider.isNull()) revert ProviderNotFound();

396:     if (callingProvider.isNull()) revert ProviderNotFound();

398:     if (accounts.length != roleGrantedTimestamps.length) revert InvalidArrayLength();

414:     if (newExpiry < block.timestamp) revert GrantedCredentialExpired();

533:     if (provider.isNull()) return false;

553:       if call(

595:       if (i == pullProviderIndexToSkip) continue;

597:       if (_tryGetCredential(status, provider, accountAddress)) return (true);

733:     if (

743:     if (wasUpdated) _lenderStatus[accountAddress] = status;

776:     if (!market.isHooked) revert NotHookedMarket();

782:     if (status.isBlockedFromDeposits) revert NotApprovedLender();

820:     if (

860:     if (!market.isHooked) revert NotHookedMarket();

866:       if (toStatus.isBlockedFromDeposits) revert NotApprovedLender();

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

118:     if (msg.sender != borrower) revert CallerNotBorrower();

178:     if (deployer != borrower) revert CallerNotBorrower();

179:     if (hooksData.length < 32) revert FixedTermNotProvided();

188:     if (

231:     if (!hookedMarket.isHooked) revert NotHookedMarket();

238:     if (!hookedMarket.isHooked) revert NotHookedMarket();

239:     if (newFixedTermEndTime > hookedMarket.fixedTermEndTime) revert IncreaseFixedTerm();

288:     if (provider.isNull()) revert ProviderNotFound();

377:         if (status.credentialNotExpired(provider)) return status;

416:     if (callingProvider.isNull()) revert ProviderNotFound();

433:     if (callingProvider.isNull()) revert ProviderNotFound();

435:     if (accounts.length != roleGrantedTimestamps.length) revert InvalidArrayLength();

451:     if (newExpiry < block.timestamp) revert GrantedCredentialExpired();

570:     if (provider.isNull()) return false;

590:       if call(

632:       if (i == pullProviderIndexToSkip) continue;

634:       if (_tryGetCredential(status, provider, accountAddress)) return (true);

770:     if (

780:     if (wasUpdated) _lenderStatus[accountAddress] = status;

812:     if (!market.isHooked) revert NotHookedMarket();

818:     if (status.isBlockedFromDeposits) revert NotApprovedLender();

856:     if (!market.isHooked) revert NotHookedMarket();

862:       if (

903:     if (!market.isHooked) revert NotHookedMarket();

909:       if (toStatus.isBlockedFromDeposits) revert NotApprovedLender();

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

167:     uint256 relativeDiff = MathUtils.mulDiv(

179:       uint256 boundRelativeDiff = MathUtils.min(10000, 2 * relativeDiff);

183:         MathUtils.max(boundRelativeDiff, originalReserveRatioBips)

```

```solidity
File: ./src/market/WildcatMarket.sol

61:     if (state.isClosed) revert_DepositToClosedMarket();

68:     if (scaledAmount == 0) revert_NullMintAmount();

119:     if (amount != actualAmount) revert_MaxSupplyExceeded();

127:     if (state.accruedProtocolFees == 0) revert_NullFeeAmount();

130:     if (withdrawableFees == 0) revert_InsufficientReservesForFeeWithdrawal();

155:     if (state.isClosed) revert_BorrowFromClosedMarket();

158:     if (amount > borrowable) revert_BorrowAmountTooHigh();

169:     if (amount == 0) revert_NullRepayAmount();

170:     if (state.isClosed) revert_RepayToClosedMarket();

203:     if (amount == 0) revert_NullRepayAmount();

209:     if (state.isClosed) revert_RepayToClosedMarket();

229:     if (state.isClosed) revert_MarketAlreadyClosed();

```

```solidity
File: ./src/market/WildcatMarketBase.sol

146:       if iszero(

246:     if (_isSanctioned(accountAddress)) revert_AccountBlocked();

264:       if iszero(

674:     if (scaledAmountOwed == 0) return (0, 0);

704:     if (scaledAmountOwed == 0) return;

759:       if iszero(

782:       if iszero(

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

83:     if (!_isSanctioned(accountAddress)) revert_BadLaunchCode();

105:     if (state.isClosed) revert_CapacityChangeOnClosedMarket();

128:     if (state.isClosed) revert_AprChangeOnClosedMarket();

167:     if (msg.sender != factory) revert_NotFactory();

168:     if (_protocolFeeBips > 1_000) revert_ProtocolFeeTooHigh();

170:     if (state.isClosed) revert_ProtocolFeeChangeOnClosedMarket();

171:     if (_protocolFeeBips == state.protocolFeeBips) revert_ProtocolFeeNotChanged();

```

```solidity
File: ./src/market/WildcatMarketToken.sol

76:     if (scaledAmount == 0) revert_NullTransferAmount();

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

141:     if (scaledAmount == 0) revert_NullBurnAmount();

165:     if (scaledAmount == 0) revert_NullBurnAmount();

216:     if (accountAddresses.length != expiries.length) revert_InvalidArrayLength();

253:     if (normalizedAmountWithdrawn == 0) revert_NullWithdrawalAmount();

295:     if (state.isClosed) revert_RepayToClosedMarket();

299:     if (repayAmount > 0) hooks.onRepay(repayAmount, state, _runtimeConstant(0x44));

342:       _withdrawalData.unpaidBatches.shift();

```

```solidity
File: ./src/types/HooksConfig.sol

759:         if or(

```

### <a name="NC-5"></a>[NC-5] Default Visibility for constants
Some constants are using the default visibility. For readability, consider explicitly declaring them as `internal`.

*Instances (17)*:
```solidity
File: ./src/ReentrancyGuard.sol

5: uint256 constant NoReentrantCalls_ErrorSelector = 0x7fa8a987;

7: uint256 constant _REENTRANCY_GUARD_SLOT = 0x929eee14;

```

```solidity
File: ./src/types/HooksConfig.sol

9: HooksConfig constant EmptyHooksConfig = HooksConfig.wrap(0);

33: uint256 constant Bit_Enabled_Deposit = 95;

34: uint256 constant Bit_Enabled_QueueWithdrawal = 94;

35: uint256 constant Bit_Enabled_ExecuteWithdrawal = 93;

36: uint256 constant Bit_Enabled_Transfer = 92;

37: uint256 constant Bit_Enabled_Borrow = 91;

38: uint256 constant Bit_Enabled_Repay = 90;

39: uint256 constant Bit_Enabled_CloseMarket = 89;

40: uint256 constant Bit_Enabled_NukeFromOrbit = 88;

41: uint256 constant Bit_Enabled_SetMaxTotalSupply = 87;

42: uint256 constant Bit_Enabled_SetAnnualInterestAndReserveRatioBips = 86;

43: uint256 constant Bit_Enabled_SetProtocolFeeBips = 85;

45: uint256 constant MarketStateSize = 0x01c0;

```

```solidity
File: ./src/types/RoleProvider.sol

7: uint24 constant NotPullProviderIndex = type(uint24).max;

8: RoleProvider constant EmptyRoleProvider = RoleProvider.wrap(0);

```

### <a name="NC-6"></a>[NC-6] Consider disabling `renounceOwnership()`
If the plan for your project does not include eventually giving up all ownership control, consider overwriting OpenZeppelin's `Ownable`'s `renounceOwnership()` function in order to disable it.

*Instances (1)*:
```solidity
File: ./src/WildcatArchController.sol

10: contract WildcatArchController is SphereXConfig, Ownable {

```

### <a name="NC-7"></a>[NC-7] Functions should not be longer than 50 lines
Overly complex code can make understanding functionality more difficult, try to further modularize your code to ensure readability 

*Instances (156)*:
```solidity
File: ./src/HooksFactory.sol

75:   function registerWithArchController() external override {

79:   function archController() external view override returns (address) {

101:   function _setTmpMarketParameters(TmpMarketParameterStorage memory parameters) internal {

201:   function disableHooksTemplate(address hooksTemplate) external override onlyArchControllerOwner {

216:   function isHooksTemplate(address hooksTemplate) external view override returns (bool) {

220:   function getHooksTemplates() external view override returns (address[] memory) {

237:   function getHooksTemplatesCount() external view override returns (uint256) {

285:   function isHooksInstance(address hooksInstance) external view override returns (bool) {

367:   function computeMarketAddress(bytes32 salt) external view override returns (address) {

376:   function _packString(string memory str) internal pure returns (bytes32 word0, bytes32 word1) {

594:   function pushProtocolFeeBipsUpdates(address hooksTemplate) external {

```

```solidity
File: ./src/WildcatArchController.sol

73:   function updateSphereXEngineOnRegisteredContracts(

116:   function _updateSphereXEngineOnRegisteredContractsInSet(

144:   function _callWith(address target, bytes memory data) internal {

157:   function registerBorrower(address borrower) external onlyOwner {

164:   function removeBorrower(address borrower) external onlyOwner {

171:   function isRegisteredBorrower(address borrower) external view returns (bool) {

175:   function getRegisteredBorrowers() external view returns (address[] memory) {

192:   function getRegisteredBorrowersCount() external view returns (uint256) {

200:   function addBlacklist(address asset) external onlyOwner {

207:   function removeBlacklist(address asset) external onlyOwner {

214:   function isBlacklistedAsset(address asset) external view returns (bool) {

218:   function getBlacklistedAssets() external view returns (address[] memory) {

235:   function getBlacklistedAssetsCount() external view returns (uint256) {

245:   function registerControllerFactory(address factory) external onlyOwner {

253:   function removeControllerFactory(address factory) external onlyOwner {

260:   function isRegisteredControllerFactory(address factory) external view returns (bool) {

264:   function getRegisteredControllerFactories() external view returns (address[] memory) {

281:   function getRegisteredControllerFactoriesCount() external view returns (uint256) {

296:   function registerController(address controller) external onlyControllerFactory {

304:   function removeController(address controller) external onlyOwner {

311:   function isRegisteredController(address controller) external view returns (bool) {

315:   function getRegisteredControllers() external view returns (address[] memory) {

332:   function getRegisteredControllersCount() external view returns (uint256) {

347:   function registerMarket(address market) external onlyController {

355:   function removeMarket(address market) external onlyOwner {

362:   function isRegisteredMarket(address market) external view returns (bool) {

366:   function getRegisteredMarkets() external view returns (address[] memory) {

383:   function getRegisteredMarketsCount() external view returns (uint256) {

```

```solidity
File: ./src/WildcatSanctionsEscrow.sol

22:   function balance() public view override returns (uint256) {

26:   function canReleaseEscrow() public view override returns (bool) {

30:   function escrowedAsset() public view override returns (address, uint256) {

```

```solidity
File: ./src/WildcatSanctionsSentinel.sol

77:   function isFlaggedByChainalysis(address account) public view override returns (bool) {

85:   function isSanctioned(address borrower, address account) public view override returns (bool) {

96:   function overrideSanction(address account) public override {

104:   function removeSanctionOverride(address account) public override {

```

```solidity
File: ./src/access/AccessControlHooks.sol

149:   function version() external pure override returns (string memory) {

200:   function setMinimumDeposit(address market, uint128 newMinimumDeposit) external onlyBorrower {

217:   function addRoleProvider(address providerAddress, uint32 timeToLive) external onlyBorrower {

249:   function removeRoleProvider(address providerAddress) external onlyBorrower {

267:   function _removePullProvider(uint24 indexToRemove) internal {

290:   function getRoleProvider(address providerAddress) external view returns (RoleProvider) {

294:   function getPullProviders() external view returns (RoleProvider[] memory) {

302:   function getHookedMarket(address marketAddress) external view returns (HookedMarket memory) {

376:   function grantRole(address account, uint32 roleGrantedTimestamp) external {

393:   function grantRoles(address[] memory accounts, uint32[] memory roleGrantedTimestamps) external {

445:   function blockFromDeposits(address account) external onlyBorrower {

456:   function unblockFromDeposits(address account) external onlyBorrower {

504:   function _readAddress(bytes calldata hooksData) internal pure returns (address providerAddress) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

160:   function version() external pure override returns (string memory) {

229:   function setMinimumDeposit(address market, uint128 newMinimumDeposit) external onlyBorrower {

236:   function setFixedTermEndTime(address market, uint32 newFixedTermEndTime) external onlyBorrower {

254:   function addRoleProvider(address providerAddress, uint32 timeToLive) external onlyBorrower {

286:   function removeRoleProvider(address providerAddress) external onlyBorrower {

304:   function _removePullProvider(uint24 indexToRemove) internal {

327:   function getRoleProvider(address providerAddress) external view returns (RoleProvider) {

331:   function getPullProviders() external view returns (RoleProvider[] memory) {

339:   function getHookedMarket(address marketAddress) external view returns (HookedMarket memory) {

413:   function grantRole(address account, uint32 roleGrantedTimestamp) external {

430:   function grantRoles(address[] memory accounts, uint32[] memory roleGrantedTimestamps) external {

482:   function blockFromDeposits(address account) external onlyBorrower {

493:   function unblockFromDeposits(address account) external onlyBorrower {

541:   function _readAddress(bytes calldata hooksData) internal pure returns (address providerAddress) {

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

8:   function deployInitCode(bytes memory data) internal returns (address initCodeStorage) {

49:   function getCreate2Prefix(address deployer) internal pure returns (uint256 create2Prefix) {

81:   function createWithStoredInitCode(address initCodeStorage) internal returns (address deployment) {

```

```solidity
File: ./src/libraries/MarketState.sol

51:   function totalSupply(MarketState memory state) internal pure returns (uint256) {

59:   function maximumDeposit(MarketState memory state) internal pure returns (uint256) {

76:   function scaleAmount(MarketState memory state, uint256 amount) internal pure returns (uint256) {

130:   function hasPendingExpiredBatch(MarketState memory state) internal view returns (bool result) {

138:   function totalDebts(MarketState memory state) internal pure returns (uint256) {

```

```solidity
File: ./src/market/WildcatMarket.sol

27:   function updateState() external nonReentrant sphereXGuardExternal {

37:   function rescueTokens(address token) external onlyBorrower {

117:   function deposit(uint256 amount) external virtual sphereXGuardExternal {

125:   function collectFees() external nonReentrant sphereXGuardExternal {

146:   function borrow(uint256 amount) external onlyBorrower nonReentrant sphereXGuardExternal {

168:   function _repay(MarketState memory state, uint256 amount, uint256 baseCalldataSize) internal {

179:   function repayOutstandingDebt() external nonReentrant sphereXGuardExternal {

186:   function repayDelinquentDebt() external nonReentrant sphereXGuardExternal {

202:   function repay(uint256 amount) external nonReentrant sphereXGuardExternal {

226:   function closeMarket() external onlyBorrower nonReentrant sphereXGuardExternal {

292:   function _blockAccount(MarketState memory state, address accountAddress) internal override {

```

```solidity
File: ./src/market/WildcatMarketBase.sol

34:   function version() external pure returns (string memory) {

77:   function symbol() external view returns (string memory) {

97:   function name() external view returns (string memory) {

118:   function archController() external view returns (address) {

136:   function _getMarketParameters() internal view returns (uint256 marketParametersPointer) {

244:   function _getAccount(address accountAddress) internal view returns (Account memory account) {

254:   function _isSanctioned(address account) internal view returns (bool result) {

283:   function coverageLiquidity() external view nonReentrantView returns (uint256) {

291:   function scaleFactor() external view nonReentrantView returns (uint256) {

298:   function totalAssets() public view returns (uint256) {

312:   function borrowableAssets() external view nonReentrantView returns (uint256) {

320:   function accruedProtocolFees() external view nonReentrantView returns (uint256) {

324:   function totalDebts() external view nonReentrantView returns (uint256) {

331:   function previousState() external view returns (MarketState memory) {

344:   function currentState() external view nonReentrantView returns (MarketState memory state) {

358:   function _calculateCurrentStatePointers() internal view returns (uint256 state) {

367:   function scaledTotalSupply() external view nonReentrantView returns (uint256) {

374:   function scaledBalanceOf(address account) external view nonReentrantView returns (uint256) {

382:   function withdrawableProtocolFees() external view returns (uint128) {

393:   function _blockAccount(MarketState memory state, address accountAddress) internal virtual {}

406:   function _getUpdatedState() internal returns (MarketState memory state) {

540:   function _writeState(MarketState memory state) internal {

631:   function _processExpiredWithdrawalBatch(MarketState memory state) internal {

754:   function _isFlaggedByChainalysis(address account) internal view returns (bool isFlagged) {

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

19:   function isClosed() external view returns (bool) {

29:   function maximumDeposit() external view returns (uint256) {

38:   function maxTotalSupply() external view returns (uint256) {

46:   function annualInterestBips() external view returns (uint256) {

50:   function reserveRatioBips() external view returns (uint256) {

82:   function nukeFromOrbit(address accountAddress) external nonReentrant sphereXGuardExternal {

```

```solidity
File: ./src/market/WildcatMarketToken.sol

17:   function balanceOf(address account) public view virtual nonReentrantView returns (uint256) {

25:   function totalSupply() external view virtual nonReentrantView returns (uint256) {

67:   function _approve(address approver, address spender, uint256 amount) internal virtual {

72:   function _transfer(address from, address to, uint256 amount, uint baseCalldataSize) internal virtual {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

22:   function getUnpaidBatchExpiries() external view nonReentrantView returns (uint32[] memory) {

```

```solidity
File: ./src/types/HooksConfig.sol

117:   function mergeAllFlags(HooksConfig a, HooksConfig b) internal pure returns (HooksConfig merged) {

146:   function optionalFlags(HooksDeploymentConfig flags) internal pure returns (HooksConfig config) {

152:   function requiredFlags(HooksDeploymentConfig flags) internal pure returns (HooksConfig config) {

162:   function readFlag(HooksConfig hooks, uint256 bitsAfter) internal pure returns (bool flagged) {

187:   function hooksAddress(HooksConfig hooks) internal pure returns (address _hooks) {

194:   function useOnDeposit(HooksConfig hooks) internal pure returns (bool) {

199:   function useOnQueueWithdrawal(HooksConfig hooks) internal pure returns (bool) {

204:   function useOnExecuteWithdrawal(HooksConfig hooks) internal pure returns (bool) {

209:   function useOnTransfer(HooksConfig hooks) internal pure returns (bool) {

214:   function useOnBorrow(HooksConfig hooks) internal pure returns (bool) {

219:   function useOnRepay(HooksConfig hooks) internal pure returns (bool) {

224:   function useOnCloseMarket(HooksConfig hooks) internal pure returns (bool) {

229:   function useOnNukeFromOrbit(HooksConfig hooks) internal pure returns (bool) {

234:   function useOnSetMaxTotalSupply(HooksConfig hooks) internal pure returns (bool) {

239:   function useOnSetAnnualInterestAndReserveRatioBips(

246:   function useOnSetProtocolFeeBips(HooksConfig hooks) internal pure returns (bool) {

505:   function onBorrow(HooksConfig self, uint256 normalizedAmount, MarketState memory state) internal {

605:   function onCloseMarket(HooksConfig self, MarketState memory state) internal {

787:   function onSetProtocolFeeBips(HooksConfig self, uint protocolFeeBips, MarketState memory state) internal {

837:   function onNukeFromOrbit(HooksConfig self, address lender, MarketState memory state) internal {

```

```solidity
File: ./src/types/LenderStatus.sol

36:   function hasCredential(LenderStatus memory status) internal pure returns (bool) {

66:   function unsetCredential(LenderStatus memory status) internal pure {

```

```solidity
File: ./src/types/RoleProvider.sol

60:   function timeToLive(RoleProvider provider) internal pure returns (uint32 _timeToLive) {

81:   function providerAddress(RoleProvider provider) internal pure returns (address _providerAddress) {

141:   function isNull(RoleProvider provider) internal pure returns (bool _null) {

151:   function isPullProvider(RoleProvider provider) internal pure returns (bool) {

```

```solidity
File: ./src/types/TransientBytesArray.sol

67:   function read(TransientBytesArray transientSlot) internal view returns (bytes memory data) {

85:   function write(TransientBytesArray transientSlot, bytes memory memoryPointer) internal {

115:   function setEmpty(TransientBytesArray transientSlot) internal {

```

### <a name="NC-8"></a>[NC-8] Change uint to uint256
Throughout the code base, some variables are declared as `uint`. To favor explicitness, consider changing all instances of `uint` to `uint256`

*Instances (47)*:
```solidity
File: ./src/HooksFactory.sol

555:     uint marketStartIndex,

556:     uint marketEndIndex

```

```solidity
File: ./src/access/AccessControlHooks.sol

479:     uint getCredentialSelector = uint32(IRoleProvider.getCredential.selector);

530:     uint validateSelector = uint32(IRoleProvider.validateCredential.selector);

534:     uint credentialTimestamp;

535:     uint invalidCredentialReturnedSelector = uint32(InvalidCredentialReturned.selector);

771:     uint scaledAmount,

785:     uint normalizedAmount = scaledAmount.rayMul(state.scaleFactor);

815:     uint /* scaledAmount */,

854:     uint /* scaledAmount */,

886:     uint /* normalizedAmount */,

895:     uint normalizedAmount,

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

516:     uint getCredentialSelector = uint32(IRoleProvider.getCredential.selector);

567:     uint validateSelector = uint32(IRoleProvider.validateCredential.selector);

571:     uint credentialTimestamp;

572:     uint invalidCredentialReturnedSelector = uint32(InvalidCredentialReturned.selector);

807:     uint scaledAmount,

821:     uint normalizedAmount = scaledAmount.rayMul(state.scaleFactor);

851:     uint /* scaledAmount */,

897:     uint /* scaledAmount */,

929:     uint /* normalizedAmount */,

938:     uint normalizedAmount,

```

```solidity
File: ./src/market/WildcatMarketBase.sol

58:   uint public immutable delinquencyFeeBips;

61:   uint public immutable delinquencyGracePeriod;

64:   uint public immutable withdrawalBatchDuration;

177:       uint maxTotalSupply = parameters.maxTotalSupply;

178:       uint reserveRatioBips = parameters.reserveRatioBips;

179:       uint annualInterestBips = parameters.annualInterestBips;

180:       uint protocolFeeBips = parameters.protocolFeeBips;

546:       uint maxTotalSupply = state.maxTotalSupply;

556:       uint accruedProtocolFees = state.accruedProtocolFees;

557:       uint normalizedUnclaimedWithdrawals = state.normalizedUnclaimedWithdrawals;

567:       uint scaledTotalSupply = state.scaledTotalSupply;

568:       uint scaledPendingWithdrawals = state.scaledPendingWithdrawals;

569:       uint pendingWithdrawalExpiry = state.pendingWithdrawalExpiry;

587:       uint timeDelinquent = state.timeDelinquent;

588:       uint protocolFeeBips = state.protocolFeeBips;

589:       uint annualInterestBips = state.annualInterestBips;

590:       uint reserveRatioBips = state.reserveRatioBips;

591:       uint scaleFactor = state.scaleFactor;

592:       uint lastInterestAccruedTimestamp = state.lastInterestAccruedTimestamp;

```

```solidity
File: ./src/market/WildcatMarketToken.sol

72:   function _transfer(address from, address to, uint256 amount, uint baseCalldataSize) internal virtual {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

85:     uint normalizedAmount,

86:     uint baseCalldataSize

95:       uint duration = state.isClosed.ternary(0, withdrawalBatchDuration);

235:     uint baseCalldataSize

```

```solidity
File: ./src/types/HooksConfig.sol

787:   function onSetProtocolFeeBips(HooksConfig self, uint protocolFeeBips, MarketState memory state) internal {

```

### <a name="NC-9"></a>[NC-9] Use a `modifier` instead of a `require/if` statement for a special `msg.sender` actor
If a function is supposed to be access-controlled, a `modifier` should be used instead of a `require/if` statement for more readability.

*Instances (16)*:
```solidity
File: ./src/HooksFactory.sol

110:     if (msg.sender != IWildcatArchController(_archController).owner()) {

279:     if (!IWildcatArchController(_archController).isRegisteredBorrower(msg.sender)) {

407:     if (!(address(bytes20(salt)) == msg.sender || bytes20(salt) == bytes20(0))) {

498:     if (!IWildcatArchController(_archController).isRegisteredBorrower(msg.sender)) {

527:     if (!IWildcatArchController(_archController).isRegisteredBorrower(msg.sender)) {

```

```solidity
File: ./src/WildcatArchController.sol

290:     if (!_controllerFactories.contains(msg.sender)) {

341:     if (!_controllers.contains(msg.sender)) {

```

```solidity
File: ./src/access/AccessControlHooks.sol

107:     if (msg.sender != borrower) revert CallerNotBorrower();

426:         if (!((status.lastProvider == msg.sender).or(newExpiry > oldExpiry))) {

437:     if (status.lastProvider != msg.sender) {

863:     if (!isKnownLenderOnMarket[to][msg.sender]) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

118:     if (msg.sender != borrower) revert CallerNotBorrower();

463:         if (!((status.lastProvider == msg.sender).or(newExpiry > oldExpiry))) {

474:     if (status.lastProvider != msg.sender) {

906:     if (!isKnownLenderOnMarket[to][msg.sender]) {

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

167:     if (msg.sender != factory) revert_NotFactory();

```

### <a name="NC-10"></a>[NC-10] Consider using named mappings
Consider moving to solidity version 0.8.18 or later, and using [named mappings](https://ethereum.stackexchange.com/questions/51629/how-to-name-the-arguments-in-mapping/145555#145555) to make it easier to understand the purpose of each mapping

*Instances (9)*:
```solidity
File: ./src/access/AccessControlHooks.sol

89:   mapping(address => LenderStatus) internal _lenderStatus;

96:   mapping(address => RoleProvider) internal _roleProviders;

100:   mapping(address => HookedMarket) internal _hookedMarkets;

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

100:   mapping(address => LenderStatus) internal _lenderStatus;

107:   mapping(address => RoleProvider) internal _roleProviders;

111:   mapping(address => HookedMarket) internal _hookedMarkets;

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

55:   mapping(address => TemporaryReserveRatio) public temporaryExcessReserveRatio;

```

```solidity
File: ./src/market/WildcatMarketBase.sol

128:   mapping(address => Account) internal _accounts;

```

```solidity
File: ./src/market/WildcatMarketToken.sol

14:   mapping(address => mapping(address => uint256)) public allowance;

```

### <a name="NC-11"></a>[NC-11] `address`s shouldn't be hard-coded
It is often better to declare `address`es as `immutable`, and assign them via constructor arguments. This allows the code to remain the same across deployments on different networks, and avoids recompilation when addresses need to change.

*Instances (2)*:
```solidity
File: ./src/WildcatSanctionsSentinel.sol

169:       escrowAddress := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

74:       create2Address := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

```

### <a name="NC-12"></a>[NC-12] Take advantage of Custom Error's return value property
An important feature of Custom Error is that values such as address, tokenID, msg.value can be written inside the () sign, this kind of approach provides a serious advantage in debugging and examining the revert details of dapps such as tenderly.

*Instances (122)*:
```solidity
File: ./src/HooksFactory.sol

111:       revert CallerNotArchControllerOwner();

129:       revert HooksTemplateAlreadyExists();

168:       revert InvalidFeeConfiguration();

184:       revert HooksTemplateNotFound();

203:       revert HooksTemplateNotFound();

280:       revert NotApprovedBorrower();

295:       revert HooksTemplateNotFound();

298:       revert HooksTemplateNotAvailable();

403:       revert AssetBlacklisted();

408:       revert SaltDoesNotContainSender();

415:       revert FeeMismatch();

465:       revert MarketAlreadyExists();

499:       revert NotApprovedBorrower();

504:       revert HooksInstanceNotFound();

528:       revert NotApprovedBorrower();

532:       revert HooksTemplateNotFound();

559:     if (!details.exists) revert HooksTemplateNotFound();

```

```solidity
File: ./src/WildcatArchController.sol

148:         revert(0, returndatasize())

159:       revert BorrowerAlreadyExists();

166:       revert BorrowerDoesNotExist();

202:       revert AssetAlreadyBlacklisted();

209:       revert AssetNotBlacklisted();

247:       revert ControllerFactoryAlreadyExists();

255:       revert ControllerFactoryDoesNotExist();

291:       revert NotControllerFactory();

298:       revert ControllerAlreadyExists();

306:       revert ControllerDoesNotExist();

342:       revert NotController();

349:       revert MarketAlreadyExists();

357:       revert MarketDoesNotExist();

```

```solidity
File: ./src/WildcatSanctionsEscrow.sol

35:     if (!canReleaseEscrow()) revert CanNotReleaseEscrow();

```

```solidity
File: ./src/access/AccessControlHooks.sol

107:     if (msg.sender != borrower) revert CallerNotBorrower();

167:     if (deployer != borrower) revert CallerNotBorrower();

202:     if (!hookedMarket.isHooked) revert NotHookedMarket();

251:     if (provider.isNull()) revert ProviderNotFound();

379:     if (callingProvider.isNull()) revert ProviderNotFound();

396:     if (callingProvider.isNull()) revert ProviderNotFound();

398:     if (accounts.length != roleGrantedTimestamps.length) revert InvalidArrayLength();

414:     if (newExpiry < block.timestamp) revert GrantedCredentialExpired();

427:           revert ProviderCanNotReplaceCredential();

438:       revert ProviderCanNotRevokeCredential();

776:     if (!market.isHooked) revert NotHookedMarket();

782:     if (status.isBlockedFromDeposits) revert NotApprovedLender();

787:       revert DepositBelowMinimum();

800:       revert NotApprovedLender();

823:       revert NotApprovedLender();

860:     if (!market.isHooked) revert NotHookedMarket();

866:       if (toStatus.isBlockedFromDeposits) revert NotApprovedLender();

875:         revert NotApprovedLender();

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

118:     if (msg.sender != borrower) revert CallerNotBorrower();

178:     if (deployer != borrower) revert CallerNotBorrower();

179:     if (hooksData.length < 32) revert FixedTermNotProvided();

191:       revert InvalidFixedTerm();

231:     if (!hookedMarket.isHooked) revert NotHookedMarket();

238:     if (!hookedMarket.isHooked) revert NotHookedMarket();

239:     if (newFixedTermEndTime > hookedMarket.fixedTermEndTime) revert IncreaseFixedTerm();

288:     if (provider.isNull()) revert ProviderNotFound();

416:     if (callingProvider.isNull()) revert ProviderNotFound();

433:     if (callingProvider.isNull()) revert ProviderNotFound();

435:     if (accounts.length != roleGrantedTimestamps.length) revert InvalidArrayLength();

451:     if (newExpiry < block.timestamp) revert GrantedCredentialExpired();

464:           revert ProviderCanNotReplaceCredential();

475:       revert ProviderCanNotRevokeCredential();

812:     if (!market.isHooked) revert NotHookedMarket();

818:     if (status.isBlockedFromDeposits) revert NotApprovedLender();

823:       revert DepositBelowMinimum();

836:       revert NotApprovedLender();

856:     if (!market.isHooked) revert NotHookedMarket();

858:       revert WithdrawBeforeTermEnd();

865:         revert NotApprovedLender();

903:     if (!market.isHooked) revert NotHookedMarket();

909:       if (toStatus.isBlockedFromDeposits) revert NotApprovedLender();

918:         revert NotApprovedLender();

```

```solidity
File: ./src/market/WildcatMarket.sol

39:       revert_BadRescueAsset();

61:     if (state.isClosed) revert_DepositToClosedMarket();

68:     if (scaledAmount == 0) revert_NullMintAmount();

119:     if (amount != actualAmount) revert_MaxSupplyExceeded();

127:     if (state.accruedProtocolFees == 0) revert_NullFeeAmount();

130:     if (withdrawableFees == 0) revert_InsufficientReservesForFeeWithdrawal();

151:       revert_BorrowWhileSanctioned();

155:     if (state.isClosed) revert_BorrowFromClosedMarket();

158:     if (amount > borrowable) revert_BorrowAmountTooHigh();

169:     if (amount == 0) revert_NullRepayAmount();

170:     if (state.isClosed) revert_RepayToClosedMarket();

203:     if (amount == 0) revert_NullRepayAmount();

209:     if (state.isClosed) revert_RepayToClosedMarket();

229:     if (state.isClosed) revert_MarketAlreadyClosed();

282:       revert_CloseMarketWithUnpaidWithdrawals();

```

```solidity
File: ./src/market/WildcatMarketBase.sol

246:     if (_isSanctioned(accountAddress)) revert_AccountBlocked();

268:         revert(0, returndatasize())

763:         revert(0, returndatasize())

786:         revert(0, returndatasize())

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

83:     if (!_isSanctioned(accountAddress)) revert_BadLaunchCode();

105:     if (state.isClosed) revert_CapacityChangeOnClosedMarket();

128:     if (state.isClosed) revert_AprChangeOnClosedMarket();

139:       revert_AnnualInterestBipsTooHigh();

143:       revert_ReserveRatioBipsTooHigh();

148:         revert_InsufficientReservesForOldLiquidityRatio();

155:         revert_InsufficientReservesForNewLiquidityRatio();

167:     if (msg.sender != factory) revert_NotFactory();

168:     if (_protocolFeeBips > 1_000) revert_ProtocolFeeTooHigh();

170:     if (state.isClosed) revert_ProtocolFeeChangeOnClosedMarket();

171:     if (_protocolFeeBips == state.protocolFeeBips) revert_ProtocolFeeNotChanged();

```

```solidity
File: ./src/market/WildcatMarketToken.sol

76:     if (scaledAmount == 0) revert_NullTransferAmount();

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

56:       revert_WithdrawalBatchNotExpired();

141:     if (scaledAmount == 0) revert_NullBurnAmount();

165:     if (scaledAmount == 0) revert_NullBurnAmount();

216:     if (accountAddresses.length != expiries.length) revert_InvalidArrayLength();

240:       revert_WithdrawalBatchNotExpired();

253:     if (normalizedAmountWithdrawn == 0) revert_NullWithdrawalAmount();

295:     if (state.isClosed) revert_RepayToClosedMarket();

```

```solidity
File: ./src/types/HooksConfig.sol

302:           revert(0, returndatasize())

364:           revert(0, returndatasize())

422:           revert(0, returndatasize())

487:           revert(0, returndatasize())

536:           revert(0, returndatasize())

586:           revert(0, returndatasize())

635:           revert(0, returndatasize())

689:           revert(0, returndatasize())

764:           revert(0, returndatasize())

819:           revert(0, returndatasize())

869:           revert(0, returndatasize())

```

### <a name="NC-13"></a>[NC-13] Avoid the use of sensitive terms
Use [alternative variants](https://www.zdnet.com/article/mysql-drops-master-slave-and-blacklist-whitelist-terminology/), e.g. allowlist/denylist instead of whitelist/blacklist

*Instances (22)*:
```solidity
File: ./src/HooksFactory.sol

402:     if (IWildcatArchController(_archController).isBlacklistedAsset(parameters.asset)) {

403:       revert AssetBlacklisted();

```

```solidity
File: ./src/WildcatArchController.sol

21:   EnumerableSet.AddressSet internal _assetBlacklist;

36:   error AssetAlreadyBlacklisted();

39:   error AssetNotBlacklisted();

51:   event AssetBlacklisted(address asset);

200:   function addBlacklist(address asset) external onlyOwner {

201:     if (!_assetBlacklist.add(asset)) {

202:       revert AssetAlreadyBlacklisted();

204:     emit AssetBlacklisted(asset);

207:   function removeBlacklist(address asset) external onlyOwner {

208:     if (!_assetBlacklist.remove(asset)) {

209:       revert AssetNotBlacklisted();

214:   function isBlacklistedAsset(address asset) external view returns (bool) {

215:     return _assetBlacklist.contains(asset);

218:   function getBlacklistedAssets() external view returns (address[] memory) {

219:     return _assetBlacklist.values();

222:   function getBlacklistedAssets(

226:     uint256 len = _assetBlacklist.length();

231:       arr[i] = _assetBlacklist.at(start + i);

235:   function getBlacklistedAssetsCount() external view returns (uint256) {

236:     return _assetBlacklist.length();

```

### <a name="NC-14"></a>[NC-14] Strings should use double quotes rather than single quotes
See the Solidity Style Guide: https://docs.soliditylang.org/en/v0.8.20/style-guide.html#other-recommendations

*Instances (3)*:
```solidity
File: ./src/HooksFactory.sol

38:     TransientBytesArray.wrap(uint256(keccak256('Transient:TmpMarketParametersStorage')) - 1);

```

```solidity
File: ./src/access/AccessControlHooks.sol

150:     return 'SingleBorrowerAccessControlHooks';

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

161:     return 'FixedTermLoanHooks';

```

### <a name="NC-15"></a>[NC-15] Use Underscores for Number Literals (add an underscore every 3 digits)

*Instances (3)*:
```solidity
File: ./src/access/MarketConstraintHooks.sol

168:       10000,

174:     if (relativeDiff <= 2500) {

```

```solidity
File: ./src/market/WildcatMarket.sol

247:     state.reserveRatioBips = 10000;

```

### <a name="NC-16"></a>[NC-16] Constants should be defined rather than using magic numbers

*Instances (8)*:
```solidity
File: ./src/access/AccessControlHooks.sol

506:       providerAddress := shr(96, calldataload(hooksData.offset))

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

543:       providerAddress := shr(96, calldataload(hooksData.offset))

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

32:       mstore(data, or(shl(64, add(size, 1)), 0x6100005f81600a5f39f300))

```

```solidity
File: ./src/types/HooksConfig.sol

62:     hooks := shl(96, hooksAddress)

90:       updatedHooks := shr(96, shl(96, hooks))

92:       updatedHooks := or(updatedHooks, shl(96, _hooksAddress))

132:       let _hooksAddress := shl(96, shr(96, config))

189:       _hooks := shr(96, hooks)

```

### <a name="NC-17"></a>[NC-17] Variables need not be initialized to zero
The default value for variables is zero, so initializing them to zero is superfluous.

*Instances (14)*:
```solidity
File: ./src/HooksFactory.sol

232:     for (uint256 i = 0; i < count; i++) {

257:     for (uint256 i = 0; i < count; i++) {

577:     for (uint256 i = 0; i < count; i++) {

```

```solidity
File: ./src/WildcatArchController.sol

124:     for (uint256 i = 0; i < contracts.length; i++) {

187:     for (uint256 i = 0; i < count; i++) {

230:     for (uint256 i = 0; i < count; i++) {

276:     for (uint256 i = 0; i < count; i++) {

327:     for (uint256 i = 0; i < count; i++) {

378:     for (uint256 i = 0; i < count; i++) {

```

```solidity
File: ./src/access/AccessControlHooks.sol

399:     for (uint256 i = 0; i < accounts.length; i++) {

594:     for (uint256 i = 0; i < providerCount; i++) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

436:     for (uint256 i = 0; i < accounts.length; i++) {

631:     for (uint256 i = 0; i < providerCount; i++) {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

222:     for (uint256 i = 0; i < accountAddresses.length; i++) {

```


## Low Issues


| |Issue|Instances|
|-|:-|:-:|
| [L-1](#L-1) | Use a 2-step ownership transfer pattern | 1 |
| [L-2](#L-2) | `decimals()` is not a part of the ERC-20 standard | 1 |
| [L-3](#L-3) | Initializers could be front-run | 2 |
| [L-4](#L-4) | Signature use at deadlines should be allowed | 16 |
| [L-5](#L-5) | Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership` | 1 |
| [L-6](#L-6) | Sweeping may break accounting if tokens with multiple addresses are used | 1 |
| [L-7](#L-7) | `symbol()` is not a part of the ERC-20 standard | 1 |
| [L-8](#L-8) | Unspecific compiler version pragma | 16 |
| [L-9](#L-9) | Upgradeable contract not initialized | 3 |
### <a name="L-1"></a>[L-1] Use a 2-step ownership transfer pattern
Recommend considering implementing a two step process where the owner or admin nominates an account and the nominated account needs to call an `acceptOwnership()` function for the transfer of ownership to fully succeed. This ensures the nominated EOA account is a valid and active account. Lack of two-step procedure for critical operations leaves them error-prone. Consider adding two step procedure on the critical functions.

*Instances (1)*:
```solidity
File: ./src/WildcatArchController.sol

10: contract WildcatArchController is SphereXConfig, Ownable {

```

### <a name="L-2"></a>[L-2] `decimals()` is not a part of the ERC-20 standard
The `decimals()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (1)*:
```solidity
File: ./src/HooksFactory.sol

434:     uint8 decimals = parameters.asset.decimals();

```

### <a name="L-3"></a>[L-3] Initializers could be front-run
Initializers could be front-run, allowing an attacker to either set their own values, take ownership of the contract, and in the best case forcing a re-deployment

*Instances (2)*:
```solidity
File: ./src/HooksFactory.sol

65:     __SphereXProtectedRegisteredBase_init(IWildcatArchController(archController_).sphereXEngine());

```

```solidity
File: ./src/market/WildcatMarketBase.sol

215:     __SphereXProtectedRegisteredBase_init(parameters.sphereXEngine);

```

### <a name="L-4"></a>[L-4] Signature use at deadlines should be allowed
According to [EIP-2612](https://github.com/ethereum/EIPs/blob/71dc97318013bf2ac572ab63fab530ac9ef419ca/EIPS/eip-2612.md?plain=1#L58), signatures used on exactly the deadline timestamp are supposed to be allowed. While the signature may or may not be used for the exact EIP-2612 use case (transfer approvals), for consistency's sake, all deadlines should follow this semantic. If the timestamp is an expiration rather than a deadline, consider whether it makes more sense to include the expiration timestamp as a valid timestamp, as is done for deadlines.

*Instances (16)*:
```solidity
File: ./src/access/AccessControlHooks.sol

414:     if (newExpiry < block.timestamp) revert GrantedCredentialExpired();

492:     if (credentialTimestamp == 0 || credentialTimestamp > block.timestamp) {

497:     if (provider.calculateExpiry(credentialTimestamp) >= block.timestamp) {

577:     if (credentialTimestamp == 0 || credentialTimestamp > block.timestamp) {

581:     if (provider.calculateExpiry(credentialTimestamp) >= block.timestamp) {

```

```solidity
File: ./src/access/FixedTermLoanHooks.sol

189:       fixedTermEndTime < block.timestamp || (fixedTermEndTime - block.timestamp) > MaximumLoanTerm

451:     if (newExpiry < block.timestamp) revert GrantedCredentialExpired();

529:     if (credentialTimestamp == 0 || credentialTimestamp > block.timestamp) {

534:     if (provider.calculateExpiry(credentialTimestamp) >= block.timestamp) {

614:     if (credentialTimestamp == 0 || credentialTimestamp > block.timestamp) {

618:     if (provider.calculateExpiry(credentialTimestamp) >= block.timestamp) {

857:     if (market.fixedTermEndTime > block.timestamp) {

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

55:     if (expiry >= block.timestamp) {

239:     if (expiry >= block.timestamp && !state.isClosed) {

```

```solidity
File: ./src/types/LenderStatus.sol

33:     return provider.calculateExpiry(status.lastApprovalTimestamp) < block.timestamp;

52:     return provider.calculateExpiry(status.lastApprovalTimestamp) >= block.timestamp;

```

### <a name="L-5"></a>[L-5] Use `Ownable2Step.transferOwnership` instead of `Ownable.transferOwnership`
Use [Ownable2Step.transferOwnership](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol) which is safer. Use it as it is more secure due to 2-stage ownership transfer.

**Recommended Mitigation Steps**

Use <a href="https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol">Ownable2Step.sol</a>
  
  ```solidity
      function acceptOwnership() external {
          address sender = _msgSender();
          require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
          _transferOwnership(sender);
      }
```

*Instances (1)*:
```solidity
File: ./src/WildcatArchController.sol

5: import 'solady/auth/Ownable.sol';

```

### <a name="L-6"></a>[L-6] Sweeping may break accounting if tokens with multiple addresses are used
There have been [cases](https://blog.openzeppelin.com/compound-tusd-integration-issue-retrospective/) in the past where a token mistakenly had two addresses that could control its balance, and transfers using one address impacted the balance of the other. To protect against this potential scenario, sweep functions should ensure that the balance of the non-sweepable token does not change after the transfer of the swept tokens.

*Instances (1)*:
```solidity
File: ./src/market/WildcatMarket.sol

37:   function rescueTokens(address token) external onlyBorrower {

```

### <a name="L-7"></a>[L-7] `symbol()` is not a part of the ERC-20 standard
The `symbol()` function is not a part of the [ERC-20 standard](https://eips.ethereum.org/EIPS/eip-20), and was added later as an [optional extension](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol). As such, some valid ERC20 tokens do not support this interface, so it is unsafe to blindly cast all tokens to this interface, and then call this function.

*Instances (1)*:
```solidity
File: ./src/HooksFactory.sol

437:     string memory symbol = string.concat(parameters.symbolPrefix, parameters.asset.symbol());

```

### <a name="L-8"></a>[L-8] Unspecific compiler version pragma

*Instances (16)*:
```solidity
File: ./src/HooksFactory.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/ReentrancyGuard.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/WildcatArchController.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/WildcatSanctionsEscrow.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/WildcatSanctionsSentinel.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/access/MarketConstraintHooks.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/libraries/LibStoredInitCode.sol

2: pragma solidity >=0.8.24;

```

```solidity
File: ./src/libraries/MarketState.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarket.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarketBase.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarketConfig.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarketToken.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/market/WildcatMarketWithdrawals.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/types/HooksConfig.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/types/LenderStatus.sol

2: pragma solidity >=0.8.20;

```

```solidity
File: ./src/types/TransientBytesArray.sol

2: pragma solidity >=0.8.25;

```

### <a name="L-9"></a>[L-9] Upgradeable contract not initialized
Upgradeable contracts are initialized via an initializer function rather than by a constructor. Leaving such a contract uninitialized may lead to it being taken over by a malicious user

*Instances (3)*:
```solidity
File: ./src/HooksFactory.sol

65:     __SphereXProtectedRegisteredBase_init(IWildcatArchController(archController_).sphereXEngine());

```

```solidity
File: ./src/WildcatArchController.sol

62:     _initializeOwner(msg.sender);

```

```solidity
File: ./src/market/WildcatMarketBase.sol

215:     __SphereXProtectedRegisteredBase_init(parameters.sphereXEngine);

```


## Medium Issues


| |Issue|Instances|
|-|:-|:-:|
| [M-1](#M-1) | Centralization Risk for trusted owners | 9 |
### <a name="M-1"></a>[M-1] Centralization Risk for trusted owners

#### Impact:
Contracts have owners with privileged rights to perform admin tasks and need to be trusted to not perform malicious updates or drain funds.

*Instances (9)*:
```solidity
File: ./src/WildcatArchController.sol

10: contract WildcatArchController is SphereXConfig, Ownable {

157:   function registerBorrower(address borrower) external onlyOwner {

164:   function removeBorrower(address borrower) external onlyOwner {

200:   function addBlacklist(address asset) external onlyOwner {

207:   function removeBlacklist(address asset) external onlyOwner {

245:   function registerControllerFactory(address factory) external onlyOwner {

253:   function removeControllerFactory(address factory) external onlyOwner {

304:   function removeController(address controller) external onlyOwner {

355:   function removeMarket(address market) external onlyOwner {

```
