// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import 'forge-std/Test.sol';
import 'src/access/IRoleProvider.sol';
import 'solady/utils/ECDSA.sol';

contract MockRoleProvider is IRoleProvider {
  error BadCredential();

  bool public callShouldRevert;
  bool public override isPullProvider;
  bool public callShouldReturnCorruptedData;
  address public requiredSigner;

  mapping(address => uint32) public credentialsByAccount;
  mapping(bytes32 => uint32) public credentialsByHash;

  function setIsPullProvider(bool value) external {
    isPullProvider = value;
  }

  function setCallShouldRevert(bool value) external {
    callShouldRevert = value;
  }

  function setCallShouldReturnCorruptedData(bool value) external {
    callShouldReturnCorruptedData = value;
  }

  function setCredential(address account, uint32 timestamp) external {
    credentialsByAccount[account] = timestamp;
  }

  function setRequiredSigner(address signer) external {
    requiredSigner = signer;
  }

  function approveCredentialData(bytes32 dataHash, uint32 timestamp) external {
    credentialsByHash[dataHash] = timestamp;
  }

  function getCredential(address account) external view override returns (uint32 timestamp) {
    if (callShouldRevert) revert BadCredential();
    if (callShouldReturnCorruptedData) {
      assembly {
        return(0, 0)
      }
    }
    return credentialsByAccount[account];
  }

  function validateCredential(
    address account,
    bytes calldata data
  ) external override returns (uint32) {
    if (callShouldRevert) revert BadCredential();
    if (callShouldReturnCorruptedData) {
      assembly {
        return(0, 0)
      }
    }
    if (requiredSigner != address(0)) {
      // Ensure the data is signed by the required signer
      (uint32 timestamp, bytes memory signature) = abi.decode(data, (uint32, bytes));
      bytes32 digest = keccak256(abi.encode(account, timestamp));
      address signer = ECDSA.recover(digest, signature);
      require(signer == requiredSigner, 'MockRoleProvider: invalid signature');
      return timestamp;
    }
    bytes32 dataHash = keccak256(data);
    return credentialsByHash[dataHash];
  }
}
