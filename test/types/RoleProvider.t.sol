// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'src/types/RoleProvider.sol';
import 'forge-std/Test.sol';
import '../helpers/Assertions.sol';

contract RoleProviderTest is Test, Assertions {
  modifier setNullIndex(StandardRoleProvider memory input, bool isPullProvider) {
    if (!isPullProvider) input.pullProviderIndex = NotPullProviderIndex;
    _;
  }

  function test_encodeRoleProvider(
    StandardRoleProvider memory input,
    bool isPullProvider
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    assertEq(provider, input);
  }

  function test_decodeRoleProvider(
    StandardRoleProvider memory input,
    bool isPullProvider
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    assertEq(provider, input);
    (input.timeToLive, input.providerAddress, input.pullProviderIndex) = provider
      .decodeRoleProvider();
    assertEq(provider, input);
  }

  function test_calculateExpiry(
    StandardRoleProvider memory input,
    bool isPullProvider,
    uint32 timestamp
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    uint256 expiryTimestamp = uint(timestamp) + uint(input.timeToLive);
    if (expiryTimestamp > type(uint32).max) expiryTimestamp = type(uint32).max;
    assertEq(provider.calculateExpiry(timestamp), expiryTimestamp);
  }

  function test_setTimeToLive(
    StandardRoleProvider memory input,
    bool isPullProvider,
    uint32 newTimeToLive
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    provider = provider.setTimeToLive(newTimeToLive);
    assertEq(provider.timeToLive(), newTimeToLive);
    input.timeToLive = newTimeToLive;
    assertEq(provider, input, 'with new ttl');
  }

  function test_setProviderAddress(
    StandardRoleProvider memory input,
    bool isPullProvider,
    address newProviderAddress
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    provider = provider.setProviderAddress(newProviderAddress);
    assertEq(provider.providerAddress(), newProviderAddress);
    input.providerAddress = newProviderAddress;
    assertEq(provider, input, 'with new providerAddress');
  }

  function test_setPullProviderIndex(
    StandardRoleProvider memory input,
    bool isPullProvider,
    uint24 newPullProviderIndex
  ) external setNullIndex(input, isPullProvider) {
    if (!isPullProvider) {
      newPullProviderIndex = NotPullProviderIndex;
    }
    RoleProvider provider = input.toRoleProvider();
    provider = provider.setPullProviderIndex(newPullProviderIndex);
    assertEq(provider.pullProviderIndex(), newPullProviderIndex);
    input.pullProviderIndex = newPullProviderIndex;
    assertEq(provider, input, 'with new pullProviderIndex');
  }

  function test_eq(
    StandardRoleProvider memory input1,
    bool isPullProvider1,
    StandardRoleProvider memory input2,
    bool isPullProvider2
  ) external setNullIndex(input1, isPullProvider1) setNullIndex(input2, isPullProvider2) {
    RoleProvider provider1 = input1.toRoleProvider();
    RoleProvider provider2 = input2.toRoleProvider();
    assertEq(
      provider1.eq(provider2),
      input1.providerAddress == input2.providerAddress &&
        input1.pullProviderIndex == input2.pullProviderIndex &&
        input1.timeToLive == input2.timeToLive
    );
  }

  function test_isNull(
    StandardRoleProvider memory input,
    bool isPullProvider
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    assertEq(
      provider.isNull(),
      input.providerAddress == address(0) && input.timeToLive == 0 && input.pullProviderIndex == 0
    );
  }

  function test_isPullProvider(
    StandardRoleProvider memory input,
    bool isPullProvider
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    assertEq(provider.isPullProvider(), input.pullProviderIndex != NotPullProviderIndex);
  }

  function test_setNotPullProvider(
    StandardRoleProvider memory input,
    bool isPullProvider
  ) external setNullIndex(input, isPullProvider) {
    RoleProvider provider = input.toRoleProvider();
    provider = provider.setNotPullProvider();
    input.pullProviderIndex = NotPullProviderIndex;
    assertEq(provider, input);
  }
}
