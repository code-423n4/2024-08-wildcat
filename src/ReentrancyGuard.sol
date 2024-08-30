// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

/// @dev Selector for `error NoReentrantCalls()`
uint256 constant NoReentrantCalls_ErrorSelector = 0x7fa8a987;

uint256 constant _REENTRANCY_GUARD_SLOT = 0x929eee14;

/**
 * @title ReentrancyGuard
 * @author d1ll0n
 * @notice Changes from original:
 *   - Removed the checks for whether tstore is supported.
 * @author Modified from Seaport contract by 0age (https://github.com/ProjectOpenSea/seaport-1.6)
 *
 * @notice ReentrancyGuard contains a transient storage variable and related
 *         functionality for protecting against reentrancy.
 */
contract ReentrancyGuard {
  /**
   * @dev Revert with an error when a caller attempts to reenter a protected function.
   *
   *      Note: Only defined for the sake of the interface and readability - the
   *      definition is not directly referenced in the contract code.
   */
  error NoReentrantCalls();

  uint256 private constant _NOT_ENTERED = 0;
  uint256 private constant _ENTERED = 1;

  /**
   * @dev Reentrancy guard for state-changing functions.
   *      Reverts if the reentrancy guard is currently set; otherwise, sets
   *      the reentrancy guard, executes the function body, then clears the
   *      reentrancy guard.
   */
  modifier nonReentrant() {
    _setReentrancyGuard();
    _;
    _clearReentrancyGuard();
  }

  /**
   * @dev Reentrancy guard for view functions.
   *      Reverts if the reentrancy guard is currently set.
   */
  modifier nonReentrantView() {
    _assertNonReentrant();
    _;
  }

  /**
   * @dev Internal function to ensure that a sentinel value for the reentrancy
   *      guard is not currently set and, if not, to set a sentinel value for
   *      the reentrancy guard.
   */
  function _setReentrancyGuard() internal {
    assembly {
      // Retrieve the current value of the reentrancy guard slot.
      let _reentrancyGuard := tload(_REENTRANCY_GUARD_SLOT)

      // Ensure that the reentrancy guard is not already set.
      // Equivalent to `if (_reentrancyGuard != _NOT_ENTERED) revert NoReentrantCalls();`
      if _reentrancyGuard {
        mstore(0, NoReentrantCalls_ErrorSelector)
        revert(0x1c, 0x04)
      }

      // Set the reentrancy guard.
      // Equivalent to `_reentrancyGuard = _ENTERED;`
      tstore(_REENTRANCY_GUARD_SLOT, _ENTERED)
    }
  }

  /**
   * @dev Internal function to unset the reentrancy guard sentinel value.
   */
  function _clearReentrancyGuard() internal {
    assembly {
      // Equivalent to `_reentrancyGuard = _NOT_ENTERED;`
      tstore(_REENTRANCY_GUARD_SLOT, _NOT_ENTERED)
    }
  }

  /**
   * @dev Internal view function to ensure that a sentinel value for the
   *         reentrancy guard is not currently set.
   */
  function _assertNonReentrant() internal view {
    assembly {
      // Ensure that the reentrancy guard is not currently set.
      // Equivalent to `if (_reentrancyGuard != _NOT_ENTERED) revert NoReentrantCalls();`
      if tload(_REENTRANCY_GUARD_SLOT) {
        mstore(0, NoReentrantCalls_ErrorSelector)
        revert(0x1c, 0x04)
      }
    }
  }
}
