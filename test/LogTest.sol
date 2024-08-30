pragma solidity >=0.8.20;

import 'forge-std/Test.sol';
import 'forge-std/console2.sol';
import 'solady/utils/FixedPointMathLib.sol';
import 'solady/utils/LibString.sol';

contract LogTest is Test {
  using FixedPointMathLib for int256;

  function doLog(uint256 n, bool isLast) internal pure returns (string memory output) {
    output = string.concat(
      '{"n": ',
      LibString.toString(n),
      'n, "result": ',
      LibString.toString(int256(n).lnWad()),
      'n}'
    );
    if (isLast) {
      output = string.concat(output, ',');
    }
  }

  function testLog() external {
    string memory output = '\n[\n';
    for (uint256 i = 10; i < 100; i += 15) {
      uint256 n = (i * 1e18) / 100;
      output = string.concat(output, doLog(n, false), '\n');
    }
    for (uint256 i = 0; i <= 100; i += 20) {
      uint256 n = (i ** 3) + 1;
      n *= 1e18;
      output = string.concat(output, doLog(n, i == 100), '\n');
    }
    output = string.concat(output, ']\n');
    console2.log(output);
  }
}
