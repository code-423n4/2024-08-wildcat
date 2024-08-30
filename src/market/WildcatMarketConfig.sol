// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import './WildcatMarketBase.sol';
import '../libraries/FeeMath.sol';
import '../libraries/SafeCastLib.sol';

contract WildcatMarketConfig is WildcatMarketBase {
  using SafeCastLib for uint256;
  using FunctionTypeCasts for *;

  // ===================================================================== //
  //                      External Config Getters                          //
  // ===================================================================== //

  /**
   * @dev Returns whether or not a market has been closed.
   */
  function isClosed() external view returns (bool) {
    // Use stored state because the state update can not affect whether
    // the market is closed.
    return _state.isClosed;
  }

  /**
   * @dev Returns the maximum amount of underlying asset that can
   *      currently be deposited to the market.
   */
  function maximumDeposit() external view returns (uint256) {
    MarketState memory state = _calculateCurrentStatePointers.asReturnsMarketState()();
    return state.maximumDeposit();
  }

  /**
   * @dev Returns the maximum supply the market can reach via
   *      deposits (does not apply to interest accrual).
   */
  function maxTotalSupply() external view returns (uint256) {
    return _state.maxTotalSupply;
  }

  /**
   * @dev Returns the annual interest rate earned by lenders
   *      in bips.
   */
  function annualInterestBips() external view returns (uint256) {
    return _state.annualInterestBips;
  }

  function reserveRatioBips() external view returns (uint256) {
    return _state.reserveRatioBips;
  }

  // ========================================================================== //
  //                                  Sanctions                                 //
  // ========================================================================== //

  /// @dev Block a sanctioned account from interacting with the market
  ///      and transfer its balance to an escrow contract.
  // ******************************************************************
  //          *  |\**/|  *          *                                *
  //          *  \ == /  *          *                                *
  //          *   | b|   *          *                                *
  //          *   | y|   *          *                                *
  //          *   \ e/   *          *                                *
  //          *    \/    *          *                                *
  //          *          *          *                                *
  //          *          *          *                                *
  //          *          *  |\**/|  *                                *
  //          *          *  \ == /  *         _.-^^---....,,--       *
  //          *          *   | b|   *    _--                  --_    *
  //          *          *   | y|   *   <                        >)  *
  //          *          *   \ e/   *   |         O-FAC!          |  *
  //          *          *    \/    *    \._                   _./   *
  //          *          *          *       ```--. . , ; .--'''      *
  //          *          *          *   💸        | |   |            *
  //          *          *          *          .-=||  | |=-.    💸   *
  //  💰🤑💰 *    😅   *    😐    *    💸    `-=#$%&%$#=-'         *
  //   \|/    *   /|\    *   /|\    *  🌪         | ;  :|    🌪       *
  //   /\     * 💰/\ 💰 * 💰/\ 💰 *    _____.,-#%&$@%#&#~,._____    *
  // ******************************************************************
  function nukeFromOrbit(address accountAddress) external nonReentrant sphereXGuardExternal {
    if (!_isSanctioned(accountAddress)) revert_BadLaunchCode();
    MarketState memory state = _getUpdatedState();
    hooks.onNukeFromOrbit(accountAddress, state);
    _blockAccount(state, accountAddress);
    _writeState(state);
  }

  // ========================================================================== //
  //                           External Config Setters                          //
  // ========================================================================== //

  /**
   * @dev Sets the maximum total supply - this only limits deposits and
   *      does not affect interest accrual.
   *
   *      The hooks contract may block the change but can not modify the
   *      value being set.
   */
  function setMaxTotalSupply(
    uint256 _maxTotalSupply
  ) external onlyBorrower nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();
    if (state.isClosed) revert_CapacityChangeOnClosedMarket();

    hooks.onSetMaxTotalSupply(_maxTotalSupply, state);
    state.maxTotalSupply = _maxTotalSupply.toUint128();
    _writeState(state);
    emit_MaxTotalSupplyUpdated(_maxTotalSupply);
  }

  /**
   * @dev Sets the annual interest rate earned by lenders in bips.
   *
   *      If the new reserve ratio is lower than the old ratio,
   *      asserts that the market is not currently delinquent.
   *
   *      If the new reserve ratio is higher than the old ratio,
   *      asserts that the market will not become delinquent
   *      because of the change.
   */
  function setAnnualInterestAndReserveRatioBips(
    uint16 _annualInterestBips,
    uint16 _reserveRatioBips
  ) external onlyBorrower nonReentrant sphereXGuardExternal {
    MarketState memory state = _getUpdatedState();
    if (state.isClosed) revert_AprChangeOnClosedMarket();

    uint256 initialReserveRatioBips = state.reserveRatioBips;

    (_annualInterestBips, _reserveRatioBips) = hooks.onSetAnnualInterestAndReserveRatioBips(
      _annualInterestBips,
      _reserveRatioBips,
      state
    );

    if (_annualInterestBips > BIP) {
      revert_AnnualInterestBipsTooHigh();
    }

    if (_reserveRatioBips > BIP) {
      revert_ReserveRatioBipsTooHigh();
    }

    if (_reserveRatioBips < initialReserveRatioBips) {
      if (state.liquidityRequired() > totalAssets()) {
        revert_InsufficientReservesForOldLiquidityRatio();
      }
    }
    state.reserveRatioBips = _reserveRatioBips;
    state.annualInterestBips = _annualInterestBips;
    if (_reserveRatioBips > initialReserveRatioBips) {
      if (state.liquidityRequired() > totalAssets()) {
        revert_InsufficientReservesForNewLiquidityRatio();
      }
    }

    _writeState(state);
    emit_AnnualInterestBipsUpdated(_annualInterestBips);
    emit_ReserveRatioBipsUpdated(_reserveRatioBips);
  }

  function setProtocolFeeBips(
    uint16 _protocolFeeBips
  ) external nonReentrant sphereXGuardExternal {
    if (msg.sender != factory) revert_NotFactory();
    if (_protocolFeeBips > 1_000) revert_ProtocolFeeTooHigh();
    MarketState memory state = _getUpdatedState();
    if (state.isClosed) revert_ProtocolFeeChangeOnClosedMarket();
    if (_protocolFeeBips == state.protocolFeeBips) revert_ProtocolFeeNotChanged();
    hooks.onSetProtocolFeeBips(_protocolFeeBips, state);
    state.protocolFeeBips = _protocolFeeBips;
    emit ProtocolFeeBipsUpdated(_protocolFeeBips);
    _writeState(state);
  }
    
}
