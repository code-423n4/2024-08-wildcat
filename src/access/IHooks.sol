// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import '../types/HooksConfig.sol';
import '../libraries/MarketState.sol';
import '../interfaces/WildcatStructsAndEnums.sol';

abstract contract IHooks {
  error CallerNotFactory();

  address public immutable factory;

  constructor() {
    factory = msg.sender;
  }

  /// @dev Returns the version string of the hooks contract.
  ///      Used to determine what the contract does and how `extraData` is interpreted.
  function version() external view virtual returns (string memory);

  /// @dev Returns the HooksDeploymentConfig type which contains the sets
  ///      of optional and required hooks that this contract implements.
  function config() external view virtual returns (HooksDeploymentConfig);

  function onCreateMarket(
    address deployer,
    address marketAddress,
    DeployMarketInputs calldata parameters,
    bytes calldata extraData
  ) external returns (HooksConfig) {
    if (msg.sender != factory) revert CallerNotFactory();
    return _onCreateMarket(deployer, marketAddress, parameters, extraData);
  }

  function _onCreateMarket(
    address deployer,
    address marketAddress,
    DeployMarketInputs calldata parameters,
    bytes calldata extraData
  ) internal virtual returns (HooksConfig);

  function onDeposit(
    address lender,
    uint256 scaledAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onQueueWithdrawal(
    address lender,
    uint32 expiry,
    uint scaledAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onExecuteWithdrawal(
    address lender,
    uint128 normalizedAmountWithdrawn,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onTransfer(
    address caller,
    address from,
    address to,
    uint scaledAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onBorrow(
    uint normalizedAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onRepay(
    uint normalizedAmount,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onCloseMarket(
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onNukeFromOrbit(
    address lender,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onSetMaxTotalSupply(
    uint256 maxTotalSupply,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual;

  function onSetAnnualInterestAndReserveRatioBips(
    uint16 annualInterestBips,
    uint16 reserveRatioBips,
    MarketState calldata intermediateState,
    bytes calldata extraData
  ) external virtual returns (uint16 updatedAnnualInterestBips, uint16 updatedReserveRatioBips);

  function onSetProtocolFeeBips(
    uint16 protocolFeeBips,
    MarketState memory intermediateState,
    bytes calldata extraData
  ) external virtual;
}
