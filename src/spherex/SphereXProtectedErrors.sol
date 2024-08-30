// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

function revert_SphereXOperatorRequired() pure {
  assembly {
    mstore(0, 0x4ee0b8f8)
    revert(0x1c, 0x04)
  }
}

function revert_SphereXAdminRequired() pure {
  assembly {
    mstore(0, 0x6222a550)
    revert(0x1c, 0x04)
  }
}

function revert_SphereXOperatorOrAdminRequired() pure {
  assembly {
    mstore(0, 0xb2dbeb59)
    revert(0x1c, 0x04)
  }
}

function revert_SphereXNotPendingAdmin() pure {
  assembly {
    mstore(0, 0x4d28a58e)
    revert(0x1c, 0x04)
  }
}

function revert_SphereXNotEngine() pure {
  assembly {
    mstore(0, 0x7dcb7ada)
    revert(0x1c, 0x04)
  }
}
