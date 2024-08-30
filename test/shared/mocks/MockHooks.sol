// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'src/access/IHooks.sol';

event OnDepositCalled(
  address lender,
  uint256 scaledAmount,
  MarketState intermediateState,
  bytes extraData
);
event OnQueueWithdrawalCalled(
  address lender,
  uint32 expiry,
  uint scaledAmount,
  MarketState intermediateState,
  bytes extraData
);
event OnExecuteWithdrawalCalled(
  address lender,
  uint128 normalizedAmountWithdrawn,
  MarketState intermediateState,
  bytes extraData
);
event OnTransferCalled(
  address caller,
  address from,
  address to,
  uint scaledAmount,
  MarketState intermediateState,
  bytes extraData
);
event OnBorrowCalled(uint normalizedAmount, MarketState intermediateState, bytes extraData);
event OnRepayCalled(uint normalizedAmount, MarketState intermediateState, bytes extraData);
event OnCloseMarketCalled(MarketState intermediateState, bytes extraData);
event OnNukeFromOrbitCalled(
  address lender,
  MarketState intermediateState,
  bytes extraData
);
event OnSetMaxTotalSupplyCalled(
  uint256 maxTotalSupply,
  MarketState intermediateState,
  bytes extraData
);
event OnSetAnnualInterestAndReserveRatioBipsCalled(
  uint16 annualInterestBips,
  uint16 reserveRatioBips,
  MarketState intermediateState,
  bytes extraData
);
event OnSetProtocolFeeBipsCalled(
  uint protocolFeeBips,
  MarketState intermediateState,
  bytes extraData
);
contract MockHooks is IHooks {
  bytes32 public lastCalldataHash;
  address public deployer;
  bytes public constructorArgs;
  bytes32 public immutable constructorArgsHash;
  HooksDeploymentConfig public override config =
    encodeHooksDeploymentConfig({
      optionalFlags: encodeHooksConfig({
        useOnDeposit: true,
        useOnQueueWithdrawal: true,
        useOnExecuteWithdrawal: true,
        useOnTransfer: true,
        useOnBorrow: true,
        useOnRepay: true,
        useOnCloseMarket: true,
        useOnNukeFromOrbit: true,
        useOnSetMaxTotalSupply: true,
        useOnSetAnnualInterestAndReserveRatioBips: true,
        useOnSetProtocolFeeBips: true,
        hooksAddress: address(this)
      }),
      requiredFlags: EmptyHooksConfig
    });
  address public lastDeployer;
  DeployMarketInputs internal _lastDeployMarketInputs;
  bytes public lastCreateMarketHooksData;
  bool updateAnnualInterestAndReserveRatioBips;
  uint16 public annualInterestBipsToReturn;
  uint16 public reserveRatioBipsToReturn;
  bytes public lastExtraData;

  function reset() external {
    lastCalldataHash = 0;
    DeployMarketInputs memory inputs;
    _lastDeployMarketInputs = inputs;
    lastCreateMarketHooksData = '';
    lastExtraData = '';
  }

  function lastDeployMarketInputs() external view returns (DeployMarketInputs memory) {
    return _lastDeployMarketInputs;
  }

  function setAnnualInterestAndReserveRatioBips(
    uint16 _annualInterestBips,
    uint16 _reserveRatioBips
  ) external {
    updateAnnualInterestAndReserveRatioBips = true;
    annualInterestBipsToReturn = _annualInterestBips;
    reserveRatioBipsToReturn = _reserveRatioBips;
  }

  constructor(address _caller, bytes memory _constructorArgs) {
    deployer = _caller;
    if (_constructorArgs.length > 0) constructorArgs = _constructorArgs;
    constructorArgsHash = keccak256(_constructorArgs);
  }

  /// @dev Returns the version string of the hooks contract.
  ///      Used to determine what the contract does and how `extraData` is interpreted.
  function version() external view override returns (string memory) {
    return 'mock-hooks';
  }

  function setConfig(HooksDeploymentConfig _config) external {
    config = _config;
  }

  event RoleProviderAdded(
    address indexed providerAddress,
    uint32 timeToLive,
    uint24 pullProviderIndex
  );
  event AccountAccessGranted(
    address indexed providerAddress,
    address indexed accountAddress,
    uint32 credentialTimestamp
  );
  // Shim function to work with BaseMarketTest
  function grantRole(address account, uint32 roleGrantedTimestamp) external {
    emit AccountAccessGranted(msg.sender, account, roleGrantedTimestamp);
  }
  // Shim function to work with BaseMarketTest
  function addRoleProvider(address providerAddress, uint32 timeToLive) external {
    emit RoleProviderAdded(providerAddress, timeToLive, 0);
  }

  function _onCreateMarket(
    address _deployer,
    address _marketAddress,
    DeployMarketInputs calldata parameters,
    bytes calldata extraData
  ) internal virtual override returns (HooksConfig) {
    lastDeployer = _deployer;
    _lastDeployMarketInputs = parameters;
    lastCreateMarketHooksData = extraData;
    return parameters.hooks.mergeFlags(config);
  }

  function onDeposit(
    address lender,
    uint256 scaledAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastExtraData = extraData;
    lastCalldataHash = keccak256(msg.data);
    emit OnDepositCalled(lender, scaledAmount, intermediateState, extraData);
  }

  function onQueueWithdrawal(
    address lender,
    uint32 expiry,
    uint scaledAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnQueueWithdrawalCalled(lender, expiry, scaledAmount, intermediateState, extraData);
  }

  function onExecuteWithdrawal(
    address lender,
    uint128 normalizedAmountWithdrawn,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnExecuteWithdrawalCalled(lender, normalizedAmountWithdrawn, intermediateState, extraData);
  }

  function onTransfer(
    address caller,
    address from,
    address to,
    uint scaledAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnTransferCalled(caller, from, to, scaledAmount, intermediateState, extraData);
  }

  function onBorrow(
    uint normalizedAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnBorrowCalled(normalizedAmount, intermediateState, extraData);
  }

  function onRepay(
    uint normalizedAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnRepayCalled(normalizedAmount, intermediateState, extraData);
  }

  function onCloseMarket(
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnCloseMarketCalled(intermediateState, extraData);
  }

  function onNukeFromOrbit(
    address lender,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnNukeFromOrbitCalled(
      lender,
      intermediateState,
      extraData
    );
  }

  function onSetMaxTotalSupply(
    uint256 maxTotalSupply,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnSetMaxTotalSupplyCalled(maxTotalSupply, intermediateState, extraData);
  }

  function onSetAnnualInterestAndReserveRatioBips(
    uint16 annualInterestBips,
    uint16 reserveRatioBips,
    MarketState calldata intermediateState,
    bytes calldata extraData
  )
    external
    virtual
    override
    returns (uint16 updatedAnnualInterestBips, uint16 updatedReserveRatioBips)
  {
    lastCalldataHash = keccak256(msg.data);
    emit OnSetAnnualInterestAndReserveRatioBipsCalled(
      annualInterestBips,
      reserveRatioBips,
      intermediateState,
      extraData
    );
    (updatedAnnualInterestBips, updatedReserveRatioBips) = updateAnnualInterestAndReserveRatioBips
      ? (annualInterestBipsToReturn, reserveRatioBipsToReturn)
      : (annualInterestBips, reserveRatioBips);
  }

  function onSetProtocolFeeBips(
    uint16 protocolFeeBips,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual override {
    lastCalldataHash = keccak256(msg.data);
    emit OnSetProtocolFeeBipsCalled(protocolFeeBips, intermediateState, extraData);
  }
}

contract MockHooksWithConfig is MockHooks {
  constructor(address _caller, bytes memory _constructorArgs) MockHooks(_caller, _constructorArgs) {
    config = abi.decode(_constructorArgs, (HooksDeploymentConfig));
  }
}
