// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title NeoXCommitReveal
/// @notice Tamper-proof commit-reveal randomness base contract.
///         Business contracts (lottery, card games, FundMe, etc.) should inherit this
///         contract rather than calling it externally.
///
/// ## How it works
/// Two phases spanning at least two blocks:
///
/// 1. Commit phase (block N):
///    The user initiates an action (e.g. placing a bet), and the contract records
///    commitBlock = N. At this point blockhash(N) returns 0 (the current block's
///    hash has not been computed yet), so nobody can predict the outcome.
///
/// 2. Reveal phase (block N+1 or later):
///    The user calls reveal, and the contract uses blockhash(N) as the randomness source.
///    By now blockhash(N) exists, but the user already committed at block N and cannot
///    back out.
///
/// ## NeoX advantage
/// NeoX uses dBFT consensus; its blockhash includes a BLS aggregate signature
/// (96 bytes, stored in the block header's extraData field).
/// BLS aggregate signatures require 2/3+ validators to participate; no single validator
/// can manipulate the result, making NeoX's blockhash stronger than ordinary chains.
///
/// ## Limitations
/// - `blockhash` only retains the most recent 256 blocks.
///   Must reveal within 256 blocks after commit, otherwise the request expires.
///
/// ## Usage
/// Inherit this contract and call _commit() / _reveal() in your business functions:
///
/// ```solidity
/// contract CardGame is NeoXCommitReveal {
///     function placeBet() external payable {
///         uint256 requestId = _commit();
///         // record the bet...
///     }
///     function settle(uint256 requestId) external {
///         uint256 random = _reveal(requestId);
///         // determine winner using random...
///     }
/// }
/// ```
abstract contract NeoXCommitReveal {
    /// @notice Randomness request data.
    /// @param requester Address that initiated the request; mixed into the random
    ///        calculation to ensure different users get different results.
    /// @param commitBlock Block number at commit time; blockhash(commitBlock) is used
    ///        as the randomness source during reveal.
    /// @param revealed Whether the request has been revealed; prevents double-reveal.
    struct Request {
        address requester;
        uint256 commitBlock;
        bool revealed;
    }

    /// @notice Auto-incrementing request ID counter.
    uint256 public nextRequestId;

    /// @notice Mapping from requestId to Request.
    mapping(uint256 => Request) public requests;

    /// @notice Emitted on commit.
    event Committed(uint256 indexed requestId, address indexed requester, uint256 commitBlock);

    /// @notice Emitted on reveal.
    event Revealed(uint256 indexed requestId, uint256 randomness);

    /// @notice Submit a randomness request and record the current block number.
    /// @dev Called by child contracts within business functions (e.g. placing a bet).
    /// @return requestId Request ID for the subsequent _reveal call.
    function _commit() internal returns (uint256 requestId) {
        requestId = nextRequestId++;
        requests[requestId] = Request({
            requester: msg.sender,
            commitBlock: block.number,
            revealed: false
        });
        emit Committed(requestId, msg.sender, block.number);
    }

    /// @notice Reveal the random number. Must wait at least 1 block after commit.
    /// @dev At commit time (block N), blockhash(N) returns 0 (hash not yet computed).
    ///      From block N+1 onward, blockhash(N) becomes available and reveal can proceed.
    /// @param requestId The request ID returned by _commit.
    /// @return Pseudo-random uint256.
    function _reveal(uint256 requestId) internal returns (uint256) {
        Request storage req = requests[requestId];
        require(req.requester != address(0), "request not found");
        require(!req.revealed, "already revealed");
        require(block.number > req.commitBlock, "wait at least 1 block");

        // blockhash only retains the most recent 256 blocks; returns 0 if expired.
        bytes32 hash = blockhash(req.commitBlock);
        require(hash != bytes32(0), "blockhash expired, request void");

        req.revealed = true;

        // Mix blockhash (containing BLS signature entropy) with requestId and requester
        // to ensure different requests and different users get different random numbers.
        uint256 randomness = uint256(
            keccak256(abi.encodePacked(hash, requestId, req.requester))
        );

        emit Revealed(requestId, randomness);
        return randomness;
    }

    /// @notice Query request status.
    function getRequest(uint256 requestId) external view returns (address requester, uint256 commitBlock, bool revealed) {
        Request storage req = requests[requestId];
        return (req.requester, req.commitBlock, req.revealed);
    }
}
