// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './libraries/LibERC20.sol';
import './interfaces/IWildcatArchController.sol';
import './libraries/LibStoredInitCode.sol';
import './libraries/MathUtils.sol';
import './ReentrancyGuard.sol';
import './interfaces/WildcatStructsAndEnums.sol';
import './access/IHooks.sol';
import './IHooksFactory.sol';
import './types/TransientBytesArray.sol';
import './spherex/SphereXProtectedRegisteredBase.sol';

struct TmpMarketParameterStorage {
  address borrower;
  address asset;
  address feeRecipient;
  uint16 protocolFeeBips;
  uint128 maxTotalSupply;
  uint16 annualInterestBips;
  uint16 delinquencyFeeBips;
  uint32 withdrawalBatchDuration;
  uint16 reserveRatioBips;
  uint32 delinquencyGracePeriod;
  bytes32 packedNameWord0;
  bytes32 packedNameWord1;
  bytes32 packedSymbolWord0;
  bytes32 packedSymbolWord1;
  uint8 decimals;
  HooksConfig hooks;
}

contract HooksFactory is SphereXProtectedRegisteredBase, ReentrancyGuard, IHooksFactory {
  using LibERC20 for address;

  TransientBytesArray internal constant _tmpMarketParameters =
    TransientBytesArray.wrap(uint256(keccak256('Transient:TmpMarketParametersStorage')) - 1);

  uint256 internal immutable ownCreate2Prefix = LibStoredInitCode.getCreate2Prefix(address(this));

  address public immutable override marketInitCodeStorage;

  uint256 public immutable override marketInitCodeHash;

  address public immutable override sanctionsSentinel;

  address[] internal _hooksTemplates;
  mapping(address hooksTemplate => address[] markets) internal _marketsByHooksTemplate;
  mapping(address hooksTemplate => HooksTemplate details) internal _templateDetails;
  mapping(address hooksInstance => address hooksTemplate)
    public
    override getHooksTemplateForInstance;

  constructor(
    address archController_,
    address _sanctionsSentinel,
    address _marketInitCodeStorage,
    uint256 _marketInitCodeHash
  ) {
    marketInitCodeStorage = _marketInitCodeStorage;
    marketInitCodeHash = _marketInitCodeHash;
    _archController = archController_;
    sanctionsSentinel = _sanctionsSentinel;
    __SphereXProtectedRegisteredBase_init(IWildcatArchController(archController_).sphereXEngine());
  }

  /**
   * @dev Registers the factory as a controller with the arch-controller, allowing
   *      it to register new markets.
   *      Needs to be executed once at deployment.
   *      Does not need checks for whether it has already been registered as the
   *      arch-controller will revert if it is already registered.
   */
  function registerWithArchController() external override {
    IWildcatArchController(_archController).registerController(address(this));
  }

  function archController() external view override returns (address) {
    return _archController;
  }

  // ========================================================================== //
  //                          Internal Storage Helpers                          //
  // ========================================================================== //

  /**
   * @dev Get the temporary market parameters from transient storage.
   */
  function _getTmpMarketParameters()
    internal
    view
    returns (TmpMarketParameterStorage memory parameters)
  {
    return abi.decode(_tmpMarketParameters.read(), (TmpMarketParameterStorage));
  }

  /**
   * @dev Set the temporary market parameters in transient storage.
   */
  function _setTmpMarketParameters(TmpMarketParameterStorage memory parameters) internal {
    _tmpMarketParameters.write(abi.encode(parameters));
  }

  // ========================================================================== //
  //                                  Modifiers                                 //
  // ========================================================================== //

  modifier onlyArchControllerOwner() {
    if (msg.sender != IWildcatArchController(_archController).owner()) {
      revert CallerNotArchControllerOwner();
    }
    _;
  }

  // ========================================================================== //
  //                               Hooks Templates                              //
  // ========================================================================== //

  function addHooksTemplate(
    address hooksTemplate,
    string calldata name,
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  ) external override onlyArchControllerOwner {
    if (_templateDetails[hooksTemplate].exists) {
      revert HooksTemplateAlreadyExists();
    }
    _validateFees(feeRecipient, originationFeeAsset, originationFeeAmount, protocolFeeBips);
    _templateDetails[hooksTemplate] = HooksTemplate({
      exists: true,
      name: name,
      feeRecipient: feeRecipient,
      originationFeeAsset: originationFeeAsset,
      originationFeeAmount: originationFeeAmount,
      protocolFeeBips: protocolFeeBips,
      enabled: true,
      index: uint24(_hooksTemplates.length)
    });
    _hooksTemplates.push(hooksTemplate);
    emit HooksTemplateAdded(
      hooksTemplate,
      name,
      feeRecipient,
      originationFeeAsset,
      originationFeeAmount,
      protocolFeeBips
    );
  }

  function _validateFees(
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  ) internal pure {
    bool hasOriginationFee = originationFeeAmount > 0;
    bool nullFeeRecipient = feeRecipient == address(0);
    bool nullOriginationFeeAsset = originationFeeAsset == address(0);
    if (
      (protocolFeeBips > 0 && nullFeeRecipient) ||
      (hasOriginationFee && nullFeeRecipient) ||
      (hasOriginationFee && nullOriginationFeeAsset) ||
      protocolFeeBips > 1_000
    ) {
      revert InvalidFeeConfiguration();
    }
  }

  /// @dev Update the fees for a hooks template
  /// Note: The new fee structure will apply to all NEW markets created with existing
  ///       or future instances of the hooks template, and the protocol fee can be pushed
  ///       to existing markets using `pushProtocolFeeBipsUpdates`.
  function updateHooksTemplateFees(
    address hooksTemplate,
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  ) external override onlyArchControllerOwner {
    if (!_templateDetails[hooksTemplate].exists) {
      revert HooksTemplateNotFound();
    }
    _validateFees(feeRecipient, originationFeeAsset, originationFeeAmount, protocolFeeBips);
    HooksTemplate storage template = _templateDetails[hooksTemplate];
    template.feeRecipient = feeRecipient;
    template.originationFeeAsset = originationFeeAsset;
    template.originationFeeAmount = originationFeeAmount;
    template.protocolFeeBips = protocolFeeBips;
    emit HooksTemplateFeesUpdated(
      hooksTemplate,
      feeRecipient,
      originationFeeAsset,
      originationFeeAmount,
      protocolFeeBips
    );
  }

  function disableHooksTemplate(address hooksTemplate) external override onlyArchControllerOwner {
    if (!_templateDetails[hooksTemplate].exists) {
      revert HooksTemplateNotFound();
    }
    _templateDetails[hooksTemplate].enabled = false;
    // Emit an event to indicate that the template has been removed
    emit HooksTemplateDisabled(hooksTemplate);
  }

  function getHooksTemplateDetails(
    address hooksTemplate
  ) external view override returns (HooksTemplate memory) {
    return _templateDetails[hooksTemplate];
  }

  function isHooksTemplate(address hooksTemplate) external view override returns (bool) {
    return _templateDetails[hooksTemplate].exists;
  }

  function getHooksTemplates() external view override returns (address[] memory) {
    return _hooksTemplates;
  }

  function getHooksTemplates(
    uint256 start,
    uint256 end
  ) external view override returns (address[] memory arr) {
    uint256 len = _hooksTemplates.length;
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = _hooksTemplates[start + i];
    }
  }

  function getHooksTemplatesCount() external view override returns (uint256) {
    return _hooksTemplates.length;
  }

  function getMarketsForHooksTemplate(
    address hooksTemplate
  ) external view override returns (address[] memory) {
    return _marketsByHooksTemplate[hooksTemplate];
  }

  function getMarketsForHooksTemplate(
    address hooksTemplate,
    uint256 start,
    uint256 end
  ) external view override returns (address[] memory arr) {
    address[] storage markets = _marketsByHooksTemplate[hooksTemplate];
    uint256 len = markets.length;
    end = MathUtils.min(end, len);
    uint256 count = end - start;
    arr = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      arr[i] = markets[start + i];
    }
  }

  function getMarketsForHooksTemplateCount(
    address hooksTemplate
  ) external view override returns (uint256) {
    return _marketsByHooksTemplate[hooksTemplate].length;
  }

  // ========================================================================== //
  //                               Hooks Instances                              //
  // ========================================================================== //

  /// @dev Deploy a hooks instance for an approved template with constructor args.
  ///      Callable by approved borrowers on the arch-controller.
  ///      May require payment of origination fees.
  function deployHooksInstance(
    address hooksTemplate,
    bytes calldata constructorArgs
  ) external override nonReentrant returns (address hooksInstance) {
    if (!IWildcatArchController(_archController).isRegisteredBorrower(msg.sender)) {
      revert NotApprovedBorrower();
    }
    hooksInstance = _deployHooksInstance(hooksTemplate, constructorArgs);
  }

  function isHooksInstance(address hooksInstance) external view override returns (bool) {
    return getHooksTemplateForInstance[hooksInstance] != address(0);
  }

  function _deployHooksInstance(
    address hooksTemplate,
    bytes calldata constructorArgs
  ) internal returns (address hooksInstance) {
    HooksTemplate storage template = _templateDetails[hooksTemplate];
    if (!template.exists) {
      revert HooksTemplateNotFound();
    }
    if (!template.enabled) {
      revert HooksTemplateNotAvailable();
    }

    assembly {
      let initCodePointer := mload(0x40)
      let initCodeSize := sub(extcodesize(hooksTemplate), 1)
      // Copy code from target address to memory starting at byte 1
      extcodecopy(hooksTemplate, initCodePointer, 1, initCodeSize)
      let endInitCodePointer := add(initCodePointer, initCodeSize)
      // Write the address of the caller as the first parameter
      mstore(endInitCodePointer, caller())
      // Write the offset to the encoded constructor args
      mstore(add(endInitCodePointer, 0x20), 0x40)
      // Write the length of the encoded constructor args
      let constructorArgsSize := constructorArgs.length
      mstore(add(endInitCodePointer, 0x40), constructorArgsSize)
      // Copy constructor args to initcode after the bytes length
      calldatacopy(add(endInitCodePointer, 0x60), constructorArgs.offset, constructorArgsSize)
      // Get the full size of the initcode with the constructor args
      let initCodeSizeWithArgs := add(add(initCodeSize, 0x60), constructorArgsSize)
      // Deploy the contract with the initcode
      hooksInstance := create(0, initCodePointer, initCodeSizeWithArgs)
      if iszero(hooksInstance) {
        mstore(0x00, 0x30116425) // DeploymentFailed()
        revert(0x1c, 0x04)
      }
    }

    emit HooksInstanceDeployed(hooksInstance, hooksTemplate);
    getHooksTemplateForInstance[hooksInstance] = hooksTemplate;
  }

  // ========================================================================== //
  //                                   Markets                                  //
  // ========================================================================== //

  /**
   * @dev Get the temporarily stored market parameters for a market that is
   *      currently being deployed.
   */
  function getMarketParameters()
    external
    view
    override
    returns (MarketParameters memory parameters)
  {
    TmpMarketParameterStorage memory tmp = _getTmpMarketParameters();

    parameters.asset = tmp.asset;
    parameters.packedNameWord0 = tmp.packedNameWord0;
    parameters.packedNameWord1 = tmp.packedNameWord1;
    parameters.packedSymbolWord0 = tmp.packedSymbolWord0;
    parameters.packedSymbolWord1 = tmp.packedSymbolWord1;
    parameters.decimals = tmp.decimals;
    parameters.borrower = tmp.borrower;
    parameters.feeRecipient = tmp.feeRecipient;
    parameters.sentinel = sanctionsSentinel;
    parameters.maxTotalSupply = tmp.maxTotalSupply;
    parameters.protocolFeeBips = tmp.protocolFeeBips;
    parameters.annualInterestBips = tmp.annualInterestBips;
    parameters.delinquencyFeeBips = tmp.delinquencyFeeBips;
    parameters.withdrawalBatchDuration = tmp.withdrawalBatchDuration;
    parameters.reserveRatioBips = tmp.reserveRatioBips;
    parameters.delinquencyGracePeriod = tmp.delinquencyGracePeriod;
    parameters.archController = _archController;
    parameters.sphereXEngine = sphereXEngine();
    parameters.hooks = tmp.hooks;
  }

  function computeMarketAddress(bytes32 salt) external view override returns (address) {
    return LibStoredInitCode.calculateCreate2Address(ownCreate2Prefix, salt, marketInitCodeHash);
  }

  /**
   * @dev Given a string of at most 63 bytes, produces a packed version with two words,
   *      where the first word contains the length byte and the first 31 bytes of the string,
   *      and the second word contains the second 32 bytes of the string.
   */
  function _packString(string memory str) internal pure returns (bytes32 word0, bytes32 word1) {
    assembly {
      let length := mload(str)
      // Equivalent to:
      // if (str.length > 63) revert NameOrSymbolTooLong();
      if gt(length, 0x3f) {
        mstore(0, 0x19a65cb6)
        revert(0x1c, 0x04)
      }
      // Load the length and first 31 bytes of the string into the first word
      // by reading from 31 bytes after the length pointer.
      word0 := mload(add(str, 0x1f))
      // If the string is less than 32 bytes, the second word will be zeroed out.
      word1 := mul(mload(add(str, 0x3f)), gt(mload(str), 0x1f))
    }
  }

  function _deployMarket(
    DeployMarketInputs memory parameters,
    bytes memory hooksData,
    address hooksTemplate,
    HooksTemplate memory templateDetails,
    bytes32 salt,
    address originationFeeAsset,
    uint256 originationFeeAmount
  ) internal returns (address market) {
    if (IWildcatArchController(_archController).isBlacklistedAsset(parameters.asset)) {
      revert AssetBlacklisted();
    }
    address hooksInstance = parameters.hooks.hooksAddress();

    if (!(address(bytes20(salt)) == msg.sender || bytes20(salt) == bytes20(0))) {
      revert SaltDoesNotContainSender();
    }

    if (
      originationFeeAsset != templateDetails.originationFeeAsset ||
      originationFeeAmount != templateDetails.originationFeeAmount
    ) {
      revert FeeMismatch();
    }

    if (originationFeeAsset != address(0)) {
      originationFeeAsset.safeTransferFrom(
        msg.sender,
        templateDetails.feeRecipient,
        originationFeeAmount
      );
    }

    market = LibStoredInitCode.calculateCreate2Address(ownCreate2Prefix, salt, marketInitCodeHash);

    parameters.hooks = IHooks(hooksInstance).onCreateMarket(
      msg.sender,
      market,
      parameters,
      hooksData
    );
    uint8 decimals = parameters.asset.decimals();

    string memory name = string.concat(parameters.namePrefix, parameters.asset.name());
    string memory symbol = string.concat(parameters.symbolPrefix, parameters.asset.symbol());

    TmpMarketParameterStorage memory tmp = TmpMarketParameterStorage({
      borrower: msg.sender,
      asset: parameters.asset,
      packedNameWord0: bytes32(0),
      packedNameWord1: bytes32(0),
      packedSymbolWord0: bytes32(0),
      packedSymbolWord1: bytes32(0),
      decimals: decimals,
      feeRecipient: templateDetails.feeRecipient,
      protocolFeeBips: templateDetails.protocolFeeBips,
      maxTotalSupply: parameters.maxTotalSupply,
      annualInterestBips: parameters.annualInterestBips,
      delinquencyFeeBips: parameters.delinquencyFeeBips,
      withdrawalBatchDuration: parameters.withdrawalBatchDuration,
      reserveRatioBips: parameters.reserveRatioBips,
      delinquencyGracePeriod: parameters.delinquencyGracePeriod,
      hooks: parameters.hooks
    });
    {
      (tmp.packedNameWord0, tmp.packedNameWord1) = _packString(name);
      (tmp.packedSymbolWord0, tmp.packedSymbolWord1) = _packString(symbol);
    }

    _setTmpMarketParameters(tmp);

    if (market.code.length != 0) {
      revert MarketAlreadyExists();
    }
    LibStoredInitCode.create2WithStoredInitCode(marketInitCodeStorage, salt);

    IWildcatArchController(_archController).registerMarket(market);

    _tmpMarketParameters.setEmpty();

    _marketsByHooksTemplate[hooksTemplate].push(market);

    emit MarketDeployed(
      hooksTemplate,
      market,
      name,
      symbol,
      tmp.asset,
      tmp.maxTotalSupply,
      tmp.annualInterestBips,
      tmp.delinquencyFeeBips,
      tmp.withdrawalBatchDuration,
      tmp.reserveRatioBips,
      tmp.delinquencyGracePeriod,
      tmp.hooks
    );
  }

  function deployMarket(
    DeployMarketInputs calldata parameters,
    bytes calldata hooksData,
    bytes32 salt,
    address originationFeeAsset,
    uint256 originationFeeAmount
  ) external override nonReentrant returns (address market) {
    if (!IWildcatArchController(_archController).isRegisteredBorrower(msg.sender)) {
      revert NotApprovedBorrower();
    }
    address hooksInstance = parameters.hooks.hooksAddress();
    address hooksTemplate = getHooksTemplateForInstance[hooksInstance];
    if (hooksTemplate == address(0)) {
      revert HooksInstanceNotFound();
    }
    HooksTemplate memory templateDetails = _templateDetails[hooksTemplate];
    market = _deployMarket(
      parameters,
      hooksData,
      hooksTemplate,
      templateDetails,
      salt,
      originationFeeAsset,
      originationFeeAmount
    );
  }

  function deployMarketAndHooks(
    address hooksTemplate,
    bytes calldata hooksTemplateArgs,
    DeployMarketInputs memory parameters,
    bytes calldata hooksData,
    bytes32 salt,
    address originationFeeAsset,
    uint256 originationFeeAmount
  ) external override nonReentrant returns (address market, address hooksInstance) {
    if (!IWildcatArchController(_archController).isRegisteredBorrower(msg.sender)) {
      revert NotApprovedBorrower();
    }
    HooksTemplate memory templateDetails = _templateDetails[hooksTemplate];
    if (!templateDetails.exists) {
      revert HooksTemplateNotFound();
    }
    hooksInstance = _deployHooksInstance(hooksTemplate, hooksTemplateArgs);
    parameters.hooks = parameters.hooks.setHooksAddress(hooksInstance);
    market = _deployMarket(
      parameters,
      hooksData,
      hooksTemplate,
      templateDetails,
      salt,
      originationFeeAsset,
      originationFeeAmount
    );
  }

  /**
   * @dev Push any changes to the fee configuration of `hooksTemplate` to markets
   *      using any instances of that template at `_marketsByHooksTemplate[hooksTemplate]`.
   *      Starts at `marketStartIndex` and ends one before `marketEndIndex`  or markets.length,
   *      whichever is lowest.
   */
  function pushProtocolFeeBipsUpdates(
    address hooksTemplate,
    uint marketStartIndex,
    uint marketEndIndex
  ) public override nonReentrant {
    HooksTemplate memory details = _templateDetails[hooksTemplate];
    if (!details.exists) revert HooksTemplateNotFound();

    address[] storage markets = _marketsByHooksTemplate[hooksTemplate];
    marketEndIndex = MathUtils.min(marketEndIndex, markets.length);
    uint256 count = marketEndIndex - marketStartIndex;
    uint256 setProtocolFeeBipsCalldataPointer;
    uint16 protocolFeeBips = details.protocolFeeBips;
    assembly {
      // Write the calldata for `market.setProtocolFeeBips(protocolFeeBips)`
      // this will be reused for every market
      setProtocolFeeBipsCalldataPointer := mload(0x40)
      mstore(0x40, add(setProtocolFeeBipsCalldataPointer, 0x40))
      // Write selector for `setProtocolFeeBips(uint16)`
      mstore(setProtocolFeeBipsCalldataPointer, 0xae6ea191)
      mstore(add(setProtocolFeeBipsCalldataPointer, 0x20), protocolFeeBips)
      // Add 28 bytes to get the exact pointer to the first byte of the selector
      setProtocolFeeBipsCalldataPointer := add(setProtocolFeeBipsCalldataPointer, 0x1c)
    }
    for (uint256 i = 0; i < count; i++) {
      address market = markets[marketStartIndex + i];
      assembly {
        if iszero(call(gas(), market, 0, setProtocolFeeBipsCalldataPointer, 0x24, 0, 0)) {
          // Equivalent to `revert SetProtocolFeeBipsFailed()`
          mstore(0, 0x4484a4a9)
          revert(0x1c, 0x04)
        }
      }
    }
  }


  /**
   * @dev Push any changes to the fee configuration of `hooksTemplate` to all markets
   *      using any instances of that template at `_marketsByHooksTemplate[hooksTemplate]`.
   */
  function pushProtocolFeeBipsUpdates(address hooksTemplate) external {
    pushProtocolFeeBipsUpdates(hooksTemplate, 0, type(uint256).max);
  }
}
