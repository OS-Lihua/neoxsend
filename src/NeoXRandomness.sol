// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title NeoXRandomness
/// @notice Basic randomness service leveraging NeoX BLS signatures. Not tamper-proof;
///         do NOT use for scenarios involving funds.
///
/// ## How it works
/// NeoX uses dBFT consensus where each block is signed by validators via BLS aggregate
/// signatures. The signature (96 bytes) is stored in the block header's `extraData` field
/// and is included in the block hash calculation:
///
///   blockhash = keccak256(RLP(block_header))   // block header contains extraData with BLS sig
///
/// Therefore `blockhash` inherently contains BLS signature entropy and differs every block.
///
/// Note: `block.prevrandao` (mixHash) on NeoX only changes on validator set rotations,
/// not per block, so this contract does not use it.
///
/// ## Security
/// - BLS aggregate signatures require multiple validators to participate; no single
///   validator can control the result, making NeoX's blockhash stronger than traditional
///   PoW/PoS chains.
/// - However, `blockhash(block.number - 1)` is publicly known at execution time,
///   so attackers can precompute the result. This is NOT tamper-proof.
/// - Suitable for NFT trait generation, cosmetic game randomness, and other non-financial uses.
/// - For scenarios involving funds (lottery, card games, FundMe), use NeoXCommitReveal instead.
contract NeoXRandomness {
    /// @notice Generate a pseudo-random uint256 based on the previous block hash.
    /// @dev Mixes blockhash(block.number - 1) with block.number, block.timestamp,
    ///      msg.sender, and user-provided seed via keccak256.
    /// @param seed User-provided extra seed; different seeds yield different results.
    /// @return Pseudo-random uint256.
    function getRandomNumber(uint256 seed) external view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    // Previous block hash — contains BLS aggregate signature entropy,
                    // serves as the primary randomness source.
                    // Note: blockhash(block.number) returns 0 because the current
                    // block's hash has not been computed yet during execution.
                    blockhash(block.number - 1),
                    // Current block number — ensures different blocks produce different results.
                    block.number,
                    // Current block timestamp — adds additional entropy.
                    block.timestamp,
                    // Caller address — ensures different callers get different results.
                    msg.sender,
                    // User seed — allows the same caller in the same block to get
                    // different results by varying the seed.
                    seed
                )
            )
        );
    }
}
