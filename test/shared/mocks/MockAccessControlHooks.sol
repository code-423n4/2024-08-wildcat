// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import 'src/access/AccessControlHooks.sol';

contract MockAccessControlHooks is AccessControlHooks {
  constructor(address _deployer) AccessControlHooks(_deployer, '') {}

  function tryValidateAccess(
    address accountAddress,
    bytes calldata hooksData
  ) external returns (bool hasValidCredential, bool wasUpdated) {
    LenderStatus memory status = _lenderStatus[accountAddress];
    address lastProvider = status.lastProvider;
    (hasValidCredential, wasUpdated) = _tryValidateAccessInner(status, accountAddress, hooksData);
    if (wasUpdated) {
      _lenderStatus[accountAddress] = status;
      if (hasValidCredential) {
        emit AccountAccessGranted(
          status.lastProvider,
          accountAddress,
          status.lastApprovalTimestamp
        );
      } else {
        emit AccountAccessRevoked(accountAddress);
      }
    }
  }

  function setIsKnownLender(address accountAddress, address marketAddress, bool isKnownLender) external {
    isKnownLenderOnMarket[accountAddress][marketAddress] = isKnownLender;
  }
}
