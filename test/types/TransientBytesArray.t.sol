// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import 'src/types/TransientBytesArray.sol';
import 'forge-std/Test.sol';
import '../helpers/PRNG.sol';

contract TransientBytesArrayTest is Test {
  TransientBytesArray internal array = TransientBytesArray.wrap(0);
  function test_smallBytes(uint seed, uint length) external {
    length = bound(length, 0, 31);
    PRNG prng = seedPRNG(seed);
    bytes memory data = prng.nextBytes(length);
    array.write(data);
    uint256 expectedLengthSlotValue;
    uint256 actualLengthSlotValue;
    assembly {
      let word := mload(add(data, 32))
      expectedLengthSlotValue := or(word, mul(2, length))
      actualLengthSlotValue := tload(0)
    }
    assertEq(actualLengthSlotValue, expectedLengthSlotValue, 'bad value for small bytes');
    assertEq(array.read(), data, 'bad read value for small bytes');
    array.setEmpty();
    assertEq(array.read().length, 0, 'bad read value after emptying');
  }

  function test_largeBytes(uint seed, uint length) external {
    length = bound(length, 32, 512);
    PRNG prng = seedPRNG(seed);
    bytes memory data = prng.nextBytes(length);
    array.write(data);
    uint256 expectedLengthSlotValue;
    uint256 actualLengthSlotValue;
    assembly {
      expectedLengthSlotValue := add(1, mul(2, length))
      actualLengthSlotValue := tload(0)
    }
    assertEq(actualLengthSlotValue, expectedLengthSlotValue, 'bad value for large bytes');
    assertEq(array.read(), data, 'bad read value for large bytes');
    array.setEmpty();
    assertEq(array.read().length, 0, 'bad read value after emptying');
  }

  function test_nextBytes(uint seed, uint length) external {
    length = bound(length, 0, 512);
    PRNG prng = seedPRNG(seed);
    uint freePointer;
    assembly {
      freePointer := mload(0x40)
    }
    bytes memory data = prng.nextBytes(length);
    uint newFreePointer;
    assembly {
      newFreePointer := mload(0x40)
    }
    uint expectedNewFreePointer = freePointer + ((length + 0x3f) & uint(int(~0x1f)));
    assertEq(newFreePointer, expectedNewFreePointer, 'bad free pointer after random bytes');
    assertEq(data.length, length, 'bad length for random bytes');
  }

  // function test(uint256 seed, uint256 length) external {
  //   length = bound(length, 0, 512);
  //   LibPRNG.PRNG memory prng = LibPRNG.PRNG(seed);
  //   // uint256 pointer;

  //   External ext = new External();
  //   ext.set(val);
  //   uint256 retVal = ext.get();
  //   assertEq(retVal, val, 'D:');
  // }
}
