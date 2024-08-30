// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.20;

import { CommonBase } from 'forge-std/Base.sol';
import { StdCheats } from 'forge-std/StdCheats.sol';
import { StdUtils } from 'forge-std/StdUtils.sol';
import '../helpers/AddressSet.sol';
import 'src/libraries/StringQuery.sol';
import { console } from 'forge-std/console.sol';
import { logCall } from '../helpers/Metrics.sol';

abstract contract BaseHandler is CommonBase, StdCheats, StdUtils {
  using LibAddressSet for AddressSet;

  mapping(bytes32 => uint256) public calls;
  bytes32[] public callKeys;

  AddressSet internal _actors;
  uint256 internal immutable maxActors;
  address internal currentActor;
  address internal secondActor;
  string internal label;

  constructor(string memory _label, uint256 _maxActors) {
    label = _label;
    maxActors = _maxActors;
  }

  modifier createActor() {
    // If the max has been reached, don't add LP.
    currentActor = msg.sender;
    _actors.add(msg.sender);
    _;
  }

  function _addActor(address newActor, bool primary) internal {
    if (_actors.count() == maxActors) {
      _countCall('addActor.maxReached');
      newActor = _actors.rand(uint160(newActor));
    } else if (_actors.contains(newActor)) {
      _countCall('addActor.duplicate');
    } else {
      _countCall('addActor');
      _actors.add(newActor);
    }
    primary ? (currentActor = newActor) : (secondActor = newActor);
  }

  modifier useActor(uint256 actorIndexSeed, address defaultActor) {
    if (_actors.count() == maxActors || _actors.contains(defaultActor)) {
      currentActor = _actors.rand(actorIndexSeed);
    } else {
      _addActor(defaultActor, true);
    }
    vm.startPrank(currentActor);
    _;
    vm.stopPrank();
  }

  modifier selectActor(uint256 actorIndexSeed) {
    currentActor = _actors.rand(actorIndexSeed);
    _;
  }

  modifier useTwoActors(
    uint256 actorIndexSeed,
    address defaultSecondActor,
    uint256 secondActorIndexSeed
  ) {
    currentActor = _actors.rand(actorIndexSeed);
    if (_actors.count() == maxActors || _actors.contains(defaultSecondActor)) {
      secondActor = _actors.rand(secondActorIndexSeed);
    } else {
      _addActor(defaultSecondActor, false);
    }

    vm.startPrank(currentActor);
    _;
    vm.stopPrank();
  }

  modifier countCall(bytes32 key) {
    _countCall(key);
    _;
  }

  function _countCall(bytes32 key) internal {
    uint256 count = calls[key];
    if (count == 0) {
      callKeys.push(key);
    }
    // calls[key] = count + 1;
    logCall(bytes32ToString(key));
  }

  function actors() external view returns (address[] memory) {
    return _actors.addrs;
  }

  function forEachActor(function(address) external func) public {
    return _actors.forEach(func);
  }

  function reduceActors(
    uint256 acc,
    function(uint256, address) external returns (uint256) func
  ) public returns (uint256) {
    return _actors.reduce(acc, func);
  }

  function callSummary() public view virtual {
    console.log(string.concat('Call summary:', label));
    console.log('-------------------');
    uint256 length = callKeys.length;
    for (uint256 i; i < length; i++) {
      bytes32 key = callKeys[i];
      console.log(bytes32ToString(key), calls[key]);
    }
  }
}
