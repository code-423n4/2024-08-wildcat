pragma solidity ^0.8.20;

import 'src/libraries/MathUtils.sol';

library MathUtilsExternal {
  error MulDivFailed();

  function calculateLinearInterestFromBips(
    uint256 rateBip,
    uint256 timeDelta
  ) external pure returns (uint256 result) {
    return MathUtils.calculateLinearInterestFromBips(rateBip, timeDelta);
  }

  function min(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.min(a, b);
  }

  function max(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.max(a, b);
  }

  function satSub(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.satSub(a, b);
  }

  function ternary(
    bool condition,
    uint256 valueIfTrue,
    uint256 valueIfFalse
  ) external pure returns (uint256 c) {
    return MathUtils.ternary(condition, valueIfTrue, valueIfFalse);
  }

  function bipMul(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.bipMul(a, b);
  }

  function bipDiv(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.bipDiv(a, b);
  }

  function bipToRay(uint256 a) external pure returns (uint256 b) {
    return MathUtils.bipToRay(a);
  }

  function rayMul(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.rayMul(a, b);
  }

  function rayDiv(uint256 a, uint256 b) external pure returns (uint256 c) {
    return MathUtils.rayDiv(a, b);
  }

  function mulDiv(uint256 x, uint256 y, uint256 d) external pure returns (uint256 z) {
    return MathUtils.mulDiv(x, y, d);
  }

  function mulDivUp(uint256 x, uint256 y, uint256 d) external pure returns (uint256 z) {
    return MathUtils.mulDivUp(x, y, d);
  }
}
