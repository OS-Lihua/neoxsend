// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {NeoXCommitReveal} from "../../src/NeoXCommitReveal.sol";

/// @title MockGame
/// @notice Minimal concrete contract exposing NeoXCommitReveal for testnet verification.
contract MockGame is NeoXCommitReveal {
    function commit() external returns (uint256) {
        return _commit();
    }

    function reveal(uint256 requestId) external returns (uint256) {
        return _reveal(requestId);
    }
}
