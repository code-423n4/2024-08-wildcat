// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

function emit_ChangedSpherexOperator(address oldSphereXAdmin, address newSphereXAdmin) {
  assembly {
    mstore(0, oldSphereXAdmin)
    mstore(0x20, newSphereXAdmin)
    log1(0, 0x40, 0x2ac55ae7ba47db34b5334622acafeb34a65daf143b47019273185d64c73a35a5)
  }
}

function emit_ChangedSpherexEngineAddress(address oldEngineAddress, address newEngineAddress) {
  assembly {
    mstore(0, oldEngineAddress)
    mstore(0x20, newEngineAddress)
    log1(0, 0x40, 0xf33499cccaa0611882086224cc48cd82ef54b66a4d2edf4ed67108dd516896d5)
  }
}

function emit_SpherexAdminTransferStarted(address currentAdmin, address pendingAdmin) {
  assembly {
    mstore(0, currentAdmin)
    mstore(0x20, pendingAdmin)
    log1(0, 0x40, 0x5778f1547abbbb86090a43c32aec38334b31df4beeb6f8f3fa063f593b53a526)
  }
}

function emit_SpherexAdminTransferCompleted(address oldAdmin, address newAdmin) {
  assembly {
    mstore(0, oldAdmin)
    mstore(0x20, newAdmin)
    log1(0, 0x40, 0x67ebaebcd2ca5a91a404e898110f221747e8d15567f2388a34794aab151cf3e6)
  }
}

function emit_NewAllowedSenderOnchain(address sender) {
  assembly {
    mstore(0, sender)
    log1(0, 0x20, 0x6de0a1fd3a59e5479e6480ba65ef28d4f3ab8143c2c631bbfd9969ab39074797)
  }
}
