import './access/IHooks.sol';
import './interfaces/WildcatStructsAndEnums.sol';

struct HooksTemplate {
  /// @dev Asset used to pay origination fee
  address originationFeeAsset;
  /// @dev Amount of `originationFeeAsset` paid to deploy a new market using
  ///      an instance of this template.
  uint80 originationFeeAmount;
  /// @dev Basis points paid on interest for markets deployed using hooks
  ///      based on this template
  uint16 protocolFeeBips;
  /// @dev Whether the template exists
  bool exists;
  /// @dev Whether the template is enabled
  bool enabled;
  /// @dev Index of the template address in the array of hooks templates
  uint24 index;
  /// @dev Address to pay origination and interest fees
  address feeRecipient;
  /// @dev Name of the template
  string name;
}

interface IHooksFactoryEventsAndErrors {
  error FeeMismatch();
  error NotApprovedBorrower();
  error HooksTemplateNotFound();
  error HooksTemplateNotAvailable();
  error HooksTemplateAlreadyExists();
  error DeploymentFailed();
  error HooksInstanceNotFound();
  error CallerNotArchControllerOwner();
  error InvalidFeeConfiguration();
  error SaltDoesNotContainSender();
  error MarketAlreadyExists();
  error NameOrSymbolTooLong();
  error AssetBlacklisted();
  error SetProtocolFeeBipsFailed();

  event HooksInstanceDeployed(address hooksInstance, address hooksTemplate);
  event HooksTemplateAdded(
    address hooksTemplate,
    string name,
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  );
  event HooksTemplateDisabled(address hooksTemplate);
  event HooksTemplateFeesUpdated(
    address hooksTemplate,
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  );

  event MarketDeployed(
    address indexed hooksTemplate,
    address indexed market,
    string name,
    string symbol,
    address asset,
    uint256 maxTotalSupply,
    uint256 annualInterestBips,
    uint256 delinquencyFeeBips,
    uint256 withdrawalBatchDuration,
    uint256 reserveRatioBips,
    uint256 delinquencyGracePeriod,
    HooksConfig hooks
  );
}

interface IHooksFactory is IHooksFactoryEventsAndErrors {
  function archController() external view returns (address);

  function sanctionsSentinel() external view returns (address);

  function marketInitCodeStorage() external view returns (address);

  function marketInitCodeHash() external view returns (uint256);

  /// @dev Set-up function to register the factory as a controller with the arch-controller.
  ///      This enables the factory to register new markets.
  function registerWithArchController() external;

  // ========================================================================== //
  //                               Hooks Templates                              //
  // ========================================================================== //

  /// @dev Add a hooks template that stores the initcode for the template.
  ///
  ///      On success:
  ///      - Emits `HooksTemplateAdded` on success.
  ///      - Adds the template to the list of templates.
  ///      - Creates `HooksTemplate` struct with the given parameters mapped to the template address.
  ///
  ///      Reverts if:
  ///      - The caller is not the owner of the arch-controller.
  ///      - The template already exists.
  ///      - The fee settings are invalid.
  function addHooksTemplate(
    address hooksTemplate,
    string calldata name,
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  ) external;

  /// @dev Update the fees for a hooks template.
  ///
  ///      On success:
  ///      - Emits `HooksTemplateFeesUpdated` on success.
  ///      - Updates the fees for the `HooksTemplate` struct mapped to the template address.
  ///
  ///      Reverts if:
  ///      - The caller is not the owner of the arch-controller.
  ///      - The template does not exist.
  ///      - The fee settings are invalid.
  function updateHooksTemplateFees(
    address hooksTemplate,
    address feeRecipient,
    address originationFeeAsset,
    uint80 originationFeeAmount,
    uint16 protocolFeeBips
  ) external;

  /// @dev Disable a hooks template.
  ///
  ///      On success:
  ///      - Emits `HooksTemplateDisabled` on success.
  ///      - Disables the `HooksTemplate` struct mapped to the template address.
  ///
  ///      Reverts if:
  ///      - The caller is not the owner of the arch-controller.
  ///      - The template does not exist.
  function disableHooksTemplate(address hooksTemplate) external;

  /// @dev Get the name and fee configuration for an approved hooks template.
  function getHooksTemplateDetails(
    address hooksTemplate
  ) external view returns (HooksTemplate memory);

  /// @dev Check if a hooks template is approved.
  function isHooksTemplate(address hooksTemplate) external view returns (bool);

  /// @dev Get the list of approved hooks templates.
  function getHooksTemplates() external view returns (address[] memory);

  function getHooksTemplates(
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr);

  function getHooksTemplatesCount() external view returns (uint256);

  function getMarketsForHooksTemplate(
    address hooksTemplate
  ) external view returns (address[] memory);

  function getMarketsForHooksTemplate(
    address hooksTemplate,
    uint256 start,
    uint256 end
  ) external view returns (address[] memory arr);

  function getMarketsForHooksTemplateCount(address hooksTemplate) external view returns (uint256);

  // ========================================================================== //
  //                               Hooks Instances                              //
  // ========================================================================== //

  /// @dev Deploy a hooks instance for an approved template with constructor args.
  ///
  ///      On success:
  ///      - Emits `HooksInstanceDeployed`.
  ///      - Deploys a new hooks instance with the given templates and constructor args.
  ///      - Maps the hooks instance to the template address.
  ///
  ///      Reverts if:
  ///      - The caller is not an approved borrower.
  ///      - The template does not exist.
  ///      - The template is not enabled.
  ///      - The deployment fails.
  function deployHooksInstance(
    address hooksTemplate,
    bytes calldata constructorArgs
  ) external returns (address hooksDeployment);

  /// @dev Check if a hooks instance was deployed by the factory.
  function isHooksInstance(address hooks) external view returns (bool);

  /// @dev Get the template that was used to deploy a hooks instance.
  function getHooksTemplateForInstance(address hooks) external view returns (address);

  // ========================================================================== //
  //                                   Markets                                  //
  // ========================================================================== //

  /// @dev Get the temporarily stored market parameters for a market that is
  ///      currently being deployed.
  function getMarketParameters() external view returns (MarketParameters memory parameters);

  /// @dev Deploy a market with an existing hooks deployment (in `parameters.hooks`)
  ///
  ///      On success:
  ///      - Pays the origination fee (if applicable).
  ///      - Calls `onDeployMarket` on the hooks contract.
  ///      - Deploys a new market with the given parameters.
  ///      - Emits `MarketDeployed`.
  ///
  ///      Reverts if:
  ///      - The caller is not an approved borrower.
  ///      - The hooks instance does not exist.
  ///      - Payment of origination fee fails.
  ///      - The deployment fails.
  ///      - The call to `onDeployMarket` fails.
  ///      - `originationFeeAsset` does not match the hook template's
  ///      - `originationFeeAmount` does not match the hook template's
  function deployMarket(
    DeployMarketInputs calldata parameters,
    bytes calldata hooksData,
    bytes32 salt,
    address originationFeeAsset,
    uint256 originationFeeAmount
  ) external returns (address market);

  /// @dev Deploy a hooks instance for an approved template,then deploy a new market with that
  ///      instance as its hooks contract.
  ///      Will call `onCreateMarket` on `parameters.hooks`.
  function deployMarketAndHooks(
    address hooksTemplate,
    bytes calldata hooksConstructorArgs,
    DeployMarketInputs calldata parameters,
    bytes calldata hooksData,
    bytes32 salt,
    address originationFeeAsset,
    uint256 originationFeeAmount
  ) external returns (address market, address hooks);

  function computeMarketAddress(bytes32 salt) external view returns (address);

  function pushProtocolFeeBipsUpdates(
    address hooksTemplate,
    uint marketStartIndex,
    uint marketEndIndex
  ) external;

  function pushProtocolFeeBipsUpdates(address hooksTemplate) external;
}
