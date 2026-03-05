# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NeoX BLS Randomness — on-chain randomness service contracts powered by NeoX dBFT consensus BLS aggregate signatures. Foundry project (Solidity ^0.8.13), designed specifically for the NeoX chain.

## Build & Test Commands

```bash
forge build                # compile
forge test -vvv            # local tests (Anvil)
forge test --fork-url https://mainnet-1.rpc.banelabs.org -vvv  # NeoX mainnet fork tests
forge test --match-test test_commitAndReveal -vvv              # run a single test
forge test --match-contract NeoXCommitRevealTest -vvv          # run a single test file
```

## Architecture

Two contracts targeting different security levels:

- **`NeoXRandomness`** (`src/NeoXRandomness.sol`) — Single-call basic randomness using `blockhash(block.number - 1)` mixed with keccak256. Not tamper-proof; only for non-financial scenarios (NFT traits, etc.).
- **`NeoXCommitReveal`** (`src/NeoXCommitReveal.sol`) — `abstract` contract implementing two-step commit-reveal randomness. Business contracts (lottery, card games, FundMe) inherit it and call `_commit()` / `_reveal(requestId)`. Tests use a `MockGame` wrapper to test the abstract contract.

## NeoX Chain Specifics

- NeoX's `blockhash` contains BLS aggregate signature entropy (96 bytes, stored in the trailing portion of the block header's `extraData`), different every block — this is the primary randomness source.
- `block.prevrandao` (mixHash) on NeoX only changes on validator set rotations (not per block) — **not used** in this project.
- RPC endpoints are configured in `foundry.toml` under `[rpc_endpoints]`.
- NeoX system contracts at `0x1212000000000000000000000000000000000000` through `0006` are governance/bridge contracts, unrelated to randomness.
