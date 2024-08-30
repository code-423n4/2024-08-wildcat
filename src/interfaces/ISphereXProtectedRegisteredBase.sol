// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

interface ISphereXProtectedRegisteredBase {
  error SphereXOperatorRequired();

  event ChangedSpherexOperator(address oldSphereXAdmin, address newSphereXAdmin);

  event ChangedSpherexEngineAddress(address oldEngineAddress, address newEngineAddress);

  function sphereXOperator() external view returns (address);

  function sphereXEngine() external view returns (address);

  function changeSphereXEngine(address newSphereXEngine) external;
}
