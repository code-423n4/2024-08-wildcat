// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;
import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import 'src/market/WildcatMarket.sol';
import 'src/WildcatArchController.sol';
import 'src/WildcatSanctionsEscrow.sol';
import '../../helpers/VmUtils.sol' as VmUtils;
import { Account as MarketAccount } from 'src/libraries/MarketState.sol';

contract MockEngine {
  WildcatArchController internal archController;
  CallFrameCache[] internal cachedCalls;

  struct CallFrameCache {
    address account;
    bytes32[] storageSlots;
    bytes32[] expectedPreviousValues;
  }

  constructor(WildcatArchController _archController) {
    archController = _archController;
  }

  function slotsFor(address account) internal view returns (bytes32[] memory arr) {
    if (archController.isRegisteredMarket(account)) {
      arr = new bytes32[](7);
      for (uint i; i < 7; i++) {
        arr[i] = bytes32(uint256(i));
      }
    } else if (archController.isRegisteredController(account)) {
      arr = new bytes32[](6);
      for (uint i; i < 6; i++) {
        arr[i] = bytes32(uint256(i + 4));
      }
    } else if (archController.isRegisteredControllerFactory(account)) {
      arr = new bytes32[](3);
      arr[0] = bytes32(uint(0));
      arr[1] = bytes32(uint(1));
      arr[2] = bytes32(uint(4));
    }
  }

  function sphereXValidatePre(
    int256 num,
    address sender,
    bytes calldata data
  ) external returns (bytes32[] memory storageSlots) {
    VmUtils.vm.pauseGasMetering();
    CallFrameCache memory cache;
    cache.account = msg.sender;
    storageSlots = slotsFor(msg.sender);
    cache.storageSlots = storageSlots;
    if (storageSlots.length > 0) {
      cache.expectedPreviousValues = new bytes32[](storageSlots.length);
      for (uint i; i < storageSlots.length; i++) {
        cache.expectedPreviousValues[i] = VmUtils.vm.load(msg.sender, storageSlots[i]);
      }
    }
    cachedCalls.push(cache);
    VmUtils.vm.resumeGasMetering();
  }

  function sphereXValidatePost(
    int256 num,
    uint256 gas,
    bytes32[] calldata valuesBefore,
    bytes32[] calldata valuesAfter
  ) external {
    VmUtils.vm.pauseGasMetering();
    require(cachedCalls.length > 0, 'MockEngine: unexpected cachedCalls length');
    CallFrameCache memory cache = cachedCalls[cachedCalls.length - 1];
    bytes32[] memory storageSlots = cache.storageSlots;
    require(cache.account == msg.sender, 'MockEngine: unexpected sender');
    require(
      storageSlots.length == valuesBefore.length,
      'MockEngine: unexpected storageSlots length'
    );
    require(
      storageSlots.length == valuesAfter.length,
      'MockEngine: unexpected storageSlots length'
    );
    for (uint i; i < storageSlots.length; i++) {
      require(
        cache.expectedPreviousValues[i] == valuesBefore[i],
        'MockEngine: unexpected value before'
      );
      require(
        VmUtils.vm.load(msg.sender, storageSlots[i]) == valuesAfter[i],
        'MockEngine: unexpected value after'
      );
    }
    cachedCalls.pop();
    VmUtils.vm.resumeGasMetering();
  }

  event NewSenderOnEngine(address sender);

  function addAllowedSenderOnChain(address sender) external {
    require(sender != address(0), 'MockEngine: sender is zero');
    emit NewSenderOnEngine(sender);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return true;
  }
}
