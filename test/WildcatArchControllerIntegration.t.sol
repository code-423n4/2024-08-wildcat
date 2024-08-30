// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './BaseMarketTest.sol';

contract WildcatArchControllerIntegrationTest is BaseMarketTest {
  function deployControllersAndMarkets(
    uint numControllers,
    uint numMarketsPerController
  ) internal returns (address[] memory controllers, address[] memory markets) {
    controllers = new address[](numControllers);
    markets = new address[](numControllers * numMarketsPerController);
    for (uint i = 0; i < numControllers; i++) {
      MarketInputParameters memory parameters;
      controllers[i] = address(deployHooksInstance(parameters, false));
      for (uint j = 0; j < numMarketsPerController; j++) {
        parameters.asset = address(asset = new MockERC20('Token', 'TKN', 18));
        markets[i * numMarketsPerController + j] = address(deployMarket(parameters));
      }
    }
  }

  function test_updateSphereXEngineOnRegisteredContracts() external asAccount(SphereXOperator) {
    address oldSphereXEngine = SphereXEngine;
    deploySphereXEngine();
    updateArchControllerEngine();
    address[] memory controllers = archController.getRegisteredControllers();
    address[] memory markets = archController.getRegisteredMarkets();
    address[] memory controllerFactories;

    vm.expectEmit(controllers[0]);
    emit ChangedSpherexEngineAddress(oldSphereXEngine, SphereXEngine);
    vm.expectEmit(SphereXEngine);
    emit NewSenderOnEngine(controllers[0]);
    vm.expectEmit(address(archController));
    emit NewAllowedSenderOnchain(controllers[0]);

    vm.expectEmit(markets[0]);
    emit ChangedSpherexEngineAddress(oldSphereXEngine, SphereXEngine);
    vm.expectEmit(SphereXEngine);
    emit NewSenderOnEngine(markets[0]);
    vm.expectEmit(address(archController));
    emit NewAllowedSenderOnchain(markets[0]);

    archController.updateSphereXEngineOnRegisteredContracts(
      controllerFactories,
      controllers,
      markets
    );
  }

  function test_updateSphereXEngineOnRegisteredContracts_NullEngine()
    external
    asAccount(SphereXOperator)
  {
    address oldSphereXEngine = SphereXEngine;
    SphereXEngine = address(0);
    updateArchControllerEngine();
    address[] memory controllers = archController.getRegisteredControllers();
    address[] memory markets = archController.getRegisteredMarkets();
    address[] memory controllerFactories;

    vm.expectEmit(controllers[0]);
    emit ChangedSpherexEngineAddress(oldSphereXEngine, address(0));

    vm.expectEmit(markets[0]);
    emit ChangedSpherexEngineAddress(oldSphereXEngine, address(0));

    archController.updateSphereXEngineOnRegisteredContracts(
      controllerFactories,
      controllers,
      markets
    );
  }

  function test_updateSphereXEngineOnRegisteredContracts_ControllerFactoryDoesNotExist()
    external
    asAccount(SphereXOperator)
  {
    address[] memory controllerFactories = new address[](1);
    controllerFactories[0] = address(0);
    address[] memory empty;
    vm.expectRevert(WildcatArchController.ControllerFactoryDoesNotExist.selector);
    archController.updateSphereXEngineOnRegisteredContracts(controllerFactories, empty, empty);
  }

  function test_updateSphereXEngineOnRegisteredContracts_ControllerDoesNotExist()
    external
    asAccount(SphereXOperator)
  {
    address[] memory controllers = new address[](1);
    controllers[0] = address(0);
    address[] memory empty;
    vm.expectRevert(WildcatArchController.ControllerDoesNotExist.selector);
    archController.updateSphereXEngineOnRegisteredContracts(empty, controllers, empty);
  }

  function test_updateSphereXEngineOnRegisteredContracts_MarketDoesNotExist()
    external
    asAccount(SphereXOperator)
  {
    address[] memory markets = new address[](1);
    markets[0] = address(0);
    address[] memory empty;
    vm.expectRevert(WildcatArchController.MarketDoesNotExist.selector);
    archController.updateSphereXEngineOnRegisteredContracts(empty, empty, markets);
  }

  error SphereXOperatorOrAdminRequired();

  function test_updateSphereXEngineOnRegisteredContracts_SphereXOperatorOrAdminRequired(
    address account
  ) external {
    vm.assume(account != SphereXOperator && account != SphereXAdmin);

    address[] memory empty;
    vm.expectRevert(SphereXOperatorOrAdminRequired.selector);
    vm.prank(account);
    archController.updateSphereXEngineOnRegisteredContracts(empty, empty, empty);
  }
}
