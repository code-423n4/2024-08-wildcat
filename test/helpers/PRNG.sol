// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

type PRNG is uint256;
using LibPRNG for PRNG global;

/// @dev Seeds the `prng` with `seed`.
function seedPRNG(uint256 seed) pure returns (PRNG prng) {
  assembly {
    prng := mload(0x40)
    mstore(prng, seed)
    mstore(0x40, add(prng, 0x20))
  }
}

/// @notice Library for generating pseudorandom numbers.
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibPRNG.sol)
library LibPRNG {
  /// @dev Returns the next pseudorandom uint256.
  /// All bits of the returned uint256 pass the NIST Statistical Test Suite.
  function next(PRNG self) internal pure returns (uint256 result) {
    // We simply use `keccak256` for a great balance between
    // runtime gas costs, bytecode size, and statistical properties.
    //
    // A high-quality LCG with a 32-byte state
    // is only about 30% more gas efficient during runtime,
    // but requires a 32-byte multiplier, which can cause bytecode bloat
    // when this function is inlined.
    //
    // Using this method is about 2x more efficient than
    // `nextRandomness = uint256(keccak256(abi.encode(randomness)))`.
    assembly {
      result := keccak256(self, 0x20)
      mstore(self, result)
    }
  }

  /// @dev Returns the next `length` bytes of pseudorandom data.
  function nextBytes(PRNG self, uint256 length) internal pure returns (bytes memory data) {
    assembly {
      data := mload(0x40)
      mstore(data, length)
      let pointer := add(data, 0x20)
      let i := 0
      for {

      } lt(i, length) {

      } {
        // Get the next word from the PRNG and update the PRNG state
        let result := keccak256(self, 0x20)
        mstore(self, result)
        // Store the next word in the data array
        mstore(add(pointer, i), result)
        i := add(i, 0x20)
      }
      // Remove any extra bytes from the end of the data array
      let extraBytes := sub(i, length)
      calldatacopy(add(pointer, length), calldatasize(), extraBytes)
      mstore(0x40, add(pointer, i))
    }
  }

  /// @dev Returns a pseudorandom uint256, uniformly distributed
  /// between 0 (inclusive) and `upper` (exclusive).
  /// If your modulus is big, this method is recommended
  /// for uniform sampling to avoid modulo bias.
  /// For uniform sampling across all uint256 values,
  /// or for small enough moduli such that the bias is neligible,
  /// use {next} instead.
  function uniform(PRNG self, uint256 upper) internal pure returns (uint256 result) {
    assembly {
      for {

      } 1 {

      } {
        result := keccak256(self, 0x20)
        mstore(self, result)
        if iszero(lt(result, mod(sub(0, upper), upper))) {
          break
        }
      }
      result := mod(result, upper)
    }
  }

  /// @dev Shuffles the array in-place with Fisher-Yates shuffle.
  function shuffle(PRNG self, uint256[] memory a) internal pure {
    assembly {
      let n := mload(a)
      let w := not(0)
      let mask := shr(128, w)
      if n {
        for {
          a := add(a, 0x20)
        } 1 {

        } {
          // We can just directly use `keccak256`, cuz
          // the other approaches don't save much.
          let r := keccak256(self, 0x20)
          mstore(self, r)

          // Note that there will be a very tiny modulo bias
          // if the length of the array is not a power of 2.
          // For all practical purposes, it is negligible
          // and will not be a fairness or security concern.
          {
            let j := add(a, shl(5, mod(shr(128, r), n)))
            n := add(n, w) // `sub(n, 1)`.
            if iszero(n) {
              break
            }

            let i := add(a, shl(5, n))
            let t := mload(i)
            mstore(i, mload(j))
            mstore(j, t)
          }

          {
            let j := add(a, shl(5, mod(and(r, mask), n)))
            n := add(n, w) // `sub(n, 1)`.
            if iszero(n) {
              break
            }

            let i := add(a, shl(5, n))
            let t := mload(i)
            mstore(i, mload(j))
            mstore(j, t)
          }
        }
      }
    }
  }

  /// @dev Shuffles the bytes in-place with Fisher-Yates shuffle.
  function shuffle(PRNG self, bytes memory a) internal pure {
    assembly {
      let n := mload(a)
      let w := not(0)
      let mask := shr(128, w)
      if n {
        let b := add(a, 0x01)
        for {
          a := add(a, 0x20)
        } 1 {

        } {
          // We can just directly use `keccak256`, cuz
          // the other approaches don't save much.
          let r := keccak256(self, 0x20)
          mstore(self, r)

          // Note that there will be a very tiny modulo bias
          // if the length of the array is not a power of 2.
          // For all practical purposes, it is negligible
          // and will not be a fairness or security concern.
          {
            let o := mod(shr(128, r), n)
            n := add(n, w) // `sub(n, 1)`.
            if iszero(n) {
              break
            }

            let t := mload(add(b, n))
            mstore8(add(a, n), mload(add(b, o)))
            mstore8(add(a, o), t)
          }

          {
            let o := mod(and(r, mask), n)
            n := add(n, w) // `sub(n, 1)`.
            if iszero(n) {
              break
            }

            let t := mload(add(b, n))
            mstore8(add(a, n), mload(add(b, o)))
            mstore8(add(a, o), t)
          }
        }
      }
    }
  }
}
