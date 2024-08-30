// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './interfaces/IERC20.sol';
import './interfaces/IWildcatSanctionsEscrow.sol';
import './interfaces/IWildcatSanctionsSentinel.sol';
import './libraries/LibERC20.sol';

contract WildcatSanctionsEscrow is IWildcatSanctionsEscrow {
  using LibERC20 for address;

  address public immutable override sentinel;
  address public immutable override borrower;
  address public immutable override account;
  address internal immutable asset;

  constructor() {
    sentinel = msg.sender;
    (borrower, account, asset) = IWildcatSanctionsSentinel(sentinel).tmpEscrowParams();
  }

  function balance() public view override returns (uint256) {
    return IERC20(asset).balanceOf(address(this));
  }

  function canReleaseEscrow() public view override returns (bool) {
    return !IWildcatSanctionsSentinel(sentinel).isSanctioned(borrower, account);
  }

  function escrowedAsset() public view override returns (address, uint256) {
    return (asset, balance());
  }

  function releaseEscrow() public override {
    if (!canReleaseEscrow()) revert CanNotReleaseEscrow();

    uint256 amount = balance();
    address _account = account;
    address _asset = asset;

    asset.safeTransfer(_account, amount);

    emit EscrowReleased(_account, _asset, amount);
  }
}
