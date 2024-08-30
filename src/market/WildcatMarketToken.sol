// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './WildcatMarketBase.sol';

contract WildcatMarketToken is WildcatMarketBase {
  using SafeCastLib for uint256;
  using FunctionTypeCasts for *;

  // ========================================================================== //
  //                                ERC20 Queries                               //
  // ========================================================================== //

  mapping(address => mapping(address => uint256)) public allowance;

  /// @notice Returns the normalized balance of `account` with interest.
  function balanceOf(address account) public view virtual nonReentrantView returns (uint256) {
    return
      _calculateCurrentStatePointers.asReturnsMarketState()().normalizeAmount(
        _accounts[account].scaledBalance
      );
  }

  /// @notice Returns the normalized total supply with interest.
  function totalSupply() external view virtual nonReentrantView returns (uint256) {
    return _calculateCurrentStatePointers.asReturnsMarketState()().totalSupply();
  }

  // ========================================================================== //
  //                                ERC20 Actions                               //
  // ========================================================================== //

  function approve(
    address spender,
    uint256 amount
  ) external virtual nonReentrant sphereXGuardExternal returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transfer(
    address to,
    uint256 amount
  ) external virtual nonReentrant sphereXGuardExternal returns (bool) {
    _transfer(msg.sender, to, amount, 0x44);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external virtual nonReentrant sphereXGuardExternal returns (bool) {
    uint256 allowed = allowance[from][msg.sender];

    // Saves gas for unlimited approvals.
    if (allowed != type(uint256).max) {
      uint256 newAllowance = allowed - amount;
      _approve(from, msg.sender, newAllowance);
    }

    _transfer(from, to, amount, 0x64);

    return true;
  }

  function _approve(address approver, address spender, uint256 amount) internal virtual {
    allowance[approver][spender] = amount;
    emit_Approval(approver, spender, amount);
  }

  function _transfer(address from, address to, uint256 amount, uint baseCalldataSize) internal virtual {
    MarketState memory state = _getUpdatedState();
    uint104 scaledAmount = state.scaleAmount(amount).toUint104();

    if (scaledAmount == 0) revert_NullTransferAmount();

    hooks.onTransfer(from, to, scaledAmount, state, baseCalldataSize);

    Account memory fromAccount = _getAccount(from);
    fromAccount.scaledBalance -= scaledAmount;
    _accounts[from] = fromAccount;

    Account memory toAccount = _getAccount(to);
    toAccount.scaledBalance += scaledAmount;
    _accounts[to] = toAccount;

    _writeState(state);
    emit_Transfer(from, to, amount);
  }
}
