// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.20;

import 'forge-std/Test.sol';
import 'src/libraries/StringQuery.sol';
import 'src/libraries/LibERC20.sol';

contract Bytes32Metadata {
  bytes32 public constant name = 'TestA';
  bytes32 public constant symbol = 'TestA';
}

contract StringMetadata {
  string public name = 'TestB';
  string public symbol = 'TestB';
}

contract LongStrings {
  string public name =
    'Wow this is such a long name you would never expect this to be used in a real token';
  string public symbol =
    'The symbol too? what is going on here? surely this is far too long for a ticker';
}

contract BadStrings {
  bool giveRevertData;

  function setGiveRevertData(bool _giveRevertData) external {
    giveRevertData = _giveRevertData;
  }

  function name() external {
    if (giveRevertData) {
      revert('name');
    } else {
      revert();
    }
  }

  function symbol() external {
    if (giveRevertData) {
      revert('symbol');
    } else {
      revert();
    }
  }
}

contract StringQueryTest is Test {
  using LibERC20 for address;
  Bytes32Metadata internal immutable bytes32Metadata = new Bytes32Metadata();
  StringMetadata internal immutable stringMetadata = new StringMetadata();
  LongStrings internal immutable longStrings = new LongStrings();
  BadStrings internal immutable badStrings = new BadStrings();

  function queryName(address token) external view returns (string memory) {
    return token.name();
  }

  function querySymbol(address token) external view returns (string memory) {
    return token.symbol();
  }

  function test_name() external {
    assertEq(address(bytes32Metadata).name(), 'TestA');
    assertEq(address(stringMetadata).name(), 'TestB');
    assertEq(
      address(longStrings).name(),
      'Wow this is such a long name you would never expect this to be used in a real token'
    );

    vm.expectRevert(LibERC20.NameFailed.selector);
    this.queryName(address(badStrings));

    badStrings.setGiveRevertData(true);
    vm.expectRevert(bytes('name'));
    this.queryName(address(badStrings));
  }

  function test_symbol() external {
    assertEq(address(bytes32Metadata).symbol(), 'TestA');
    assertEq(address(stringMetadata).symbol(), 'TestB');
    assertEq(
      address(longStrings).symbol(),
      'The symbol too? what is going on here? surely this is far too long for a ticker'
    );

    vm.expectRevert(LibERC20.SymbolFailed.selector);
    this.querySymbol(address(badStrings));

    badStrings.setGiveRevertData(true);
    vm.expectRevert(bytes('symbol'));
    this.querySymbol(address(badStrings));
  }
}
