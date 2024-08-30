// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import '../libraries/MathUtils.sol';

type RoleProvider is uint256;
uint24 constant NotPullProviderIndex = type(uint24).max;
RoleProvider constant EmptyRoleProvider = RoleProvider.wrap(0);

using LibRoleProvider for RoleProvider global;

/**
 * @dev Create a `RoleProvider` from its members.
 */
function encodeRoleProvider(
  uint32 timeToLive,
  address providerAddress,
  uint24 pullProviderIndex
) pure returns (RoleProvider provider) {
  assembly {
    provider := or(
      or(shl(0xe0, timeToLive), shl(0x40, providerAddress)),
      shl(0x28, pullProviderIndex)
    )
  }
}


library LibRoleProvider {
  using MathUtils for uint256;

  /**
   * @dev Calculate the expiry for a credential granted at `timestamp` by `provider`,
   *      adding its time-to-live to the timestamp and maxing out at the max uint32,
   *      indicating indefinite access.
   */
  function calculateExpiry(
    RoleProvider provider,
    uint256 timestamp
  ) internal pure returns (uint256) {
    return timestamp.satAdd(provider.timeToLive(), type(uint32).max);
  }

  /// @dev Extract `timeToLive, providerAddress, pullProviderIndex` from a RoleProvider
  function decodeRoleProvider(
    RoleProvider provider
  )
    internal
    pure
    returns (uint32 _timeToLive, address _providerAddress, uint24 _pullProviderIndex)
  {
    assembly {
      _timeToLive := shr(0xe0, provider)
      _providerAddress := shr(0x60, shl(0x20, provider))
      _pullProviderIndex := shr(0xe8, shl(0xc0, provider))
    }
  }

  /// @dev Extract `timeToLive` from `provider`
  function timeToLive(RoleProvider provider) internal pure returns (uint32 _timeToLive) {
    assembly {
      _timeToLive := shr(0xe0, provider)
    }
  }

  /**
   * @dev Returns new RoleProvider with `timeToLive` set to `_timeToLive`
   *
   *      Note: This function does not modify the original RoleProvider
   */
  function setTimeToLive(
    RoleProvider provider,
    uint32 _timeToLive
  ) internal pure returns (RoleProvider newProvider) {
    assembly {
      newProvider := or(shr(0x20, shl(0x20, provider)), shl(0xe0, _timeToLive))
    }
  }

  /// @dev Extract `providerAddress` from `provider`
  function providerAddress(RoleProvider provider) internal pure returns (address _providerAddress) {
    assembly {
      _providerAddress := shr(0x60, shl(0x20, provider))
    }
  }

  /**
   * @dev Returns new RoleProvider with `providerAddress` set to `_providerAddress`
   *
   *      Note: This function does not modify the original RoleProvider
   */
  function setProviderAddress(
    RoleProvider provider,
    address _providerAddress
  ) internal pure returns (RoleProvider newProvider) {
    assembly {
      newProvider := or(
        and(provider, 0xffffffff0000000000000000000000000000000000000000ffffffffffffffff),
        shl(0x40, _providerAddress)
      )
    }
  }

  /// @dev Extract `pullProviderIndex` from `provider`
  function pullProviderIndex(
    RoleProvider provider
  ) internal pure returns (uint24 _pullProviderIndex) {
    assembly {
      _pullProviderIndex := shr(0xe8, shl(0xc0, provider))
    }
  }

  /**
   * @dev Returns new RoleProvider with `pullProviderIndex` set to `_pullProviderIndex`
   *
   *      Note: This function does not modify the original RoleProvider
   */
  function setPullProviderIndex(
    RoleProvider provider,
    uint24 _pullProviderIndex
  ) internal pure returns (RoleProvider newProvider) {
    assembly {
      newProvider := or(
        and(provider, 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff),
        shl(0x28, _pullProviderIndex)
      )
    }
  }

  /// @dev Checks if two RoleProviders are equal
  function eq(
    RoleProvider provider,
    RoleProvider otherRoleProvider
  ) internal pure returns (bool _eq) {
    assembly {
      _eq := eq(provider, otherRoleProvider)
    }
  }

  /// @dev Checks if `provider` is null
  function isNull(RoleProvider provider) internal pure returns (bool _null) {
    assembly {
      _null := iszero(provider)
    }
  }

  /**
   * @dev Returns whether `provider` is a pull provider by checking if
   *      `pullProviderIndex` is not equal to `NotPullProviderIndex`.
   */
  function isPullProvider(RoleProvider provider) internal pure returns (bool) {
    return provider.pullProviderIndex() != NotPullProviderIndex;
  }

  /**
   * @dev Set `pullProviderIndex` in `provider` to `NotPullProviderIndex`
   *      to mark it as not a pull provider.
   */
  function setNotPullProvider(
    RoleProvider provider
  ) internal pure returns (RoleProvider newProvider) {
    assembly {
      newProvider := or(provider, 0xffffff0000000000)
    }
  }
}
