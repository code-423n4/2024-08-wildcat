pragma solidity >=0.8.20;

import 'src/interfaces/IERC20.sol';
import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import './BaseHandler.sol';

uint256 constant INIT_SUPPLY = 1_000_000_000e18;

contract ERC20Handler is BaseHandler {
  using LibAddressSet for AddressSet;

  IERC20 token;
  uint256 public ghost_mintSum;
  uint256 public ghost_burnSum;

  uint256 public ghost_zeroMints;
  uint256 public ghost_zeroBurns;
  uint256 public ghost_zeroTransfers;
  uint256 public ghost_zeroTransferFroms;

  constructor(
    IERC20 _token,
    string memory _label,
    uint256 _maxActors
  ) BaseHandler(_label, _maxActors) {
    token = _token;
    _mint(address(this), INIT_SUPPLY);
  }

  function mint(
    uint256 actorSeed,
    uint256 amount
  ) external virtual useActor(actorSeed, msg.sender) countCall('mint') {
    _mint(currentActor, amount);
  }

  function _mint(address to, uint256 amount) internal virtual {
    if (amount == 0) {
      ghost_zeroMints++;
      _countCall('mint.zero');
    }
    ghost_mintSum += amount;
    MockERC20(address(token)).mint(to, amount);
  }

  function burn(
    uint256 actorSeed,
    uint256 amount
  ) external virtual useActor(actorSeed, msg.sender) countCall('burn') {
    vm.stopPrank();
    amount = bound(amount, 0, token.balanceOf(address(this)));
    token.transfer(currentActor, amount);
    if (amount == 0) {
      ghost_zeroBurns++;
      _countCall('burn.zero');
    }
    ghost_burnSum += amount;
    vm.prank(currentActor);
    MockERC20(address(token)).burn(currentActor, amount);
  }

  function approve(
    uint256 actorSeed,
    uint256 spenderSeed,
    uint256 amount
  ) public useActor(actorSeed, msg.sender) countCall('approve') {
    address spender = _actors.rand(spenderSeed);
    token.approve(spender, amount);
  }

  function transfer(
    uint256 actorSeed,
    uint256 toSeed,
    uint256 amount
  ) public useActor(actorSeed, msg.sender) countCall('transfer') {
    address to = _actors.rand(toSeed);

    amount = bound(amount, 0, token.balanceOf(currentActor));
    if (amount == 0) {
      ghost_zeroTransfers++;
      _countCall('transfer.zero');
    }

    if (amount > 0) {
      token.transfer(to, amount);
    }
  }

  function transferFrom(
    uint256 actorSeed,
    uint256 fromSeed,
    uint256 toSeed,
    bool _approve,
    uint256 amount
  ) public selectActor(actorSeed) countCall('transferFrom') {
    address from = _actors.rand(fromSeed);
    address to = _actors.rand(toSeed);

    amount = bound(amount, 0, token.balanceOf(from));

    if (_approve) {
      vm.prank(from);
      token.approve(currentActor, amount);
    } else {
      amount = bound(amount, 0, token.allowance(currentActor, from));
    }
    if (amount == 0) {
      ghost_zeroTransferFroms++;
      _countCall('transferFrom.zero');
    }

    vm.prank(currentActor);
    token.transferFrom(from, to, amount);
  }

  function callSummary() public view virtual override {
    super.callSummary();
    console.log('-------------------');

    console.log('Zero mints:', ghost_zeroMints);
    console.log('Zero burns:', ghost_zeroBurns);
    console.log('Zero transferFroms:', ghost_zeroTransferFroms);
    console.log('Zero transfers:', ghost_zeroTransfers);
  }
}
