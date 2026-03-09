# AGENTS.md — NeoX BLS Randomness

> On-chain randomness contracts powered by NeoX dBFT consensus BLS aggregate signatures.
> Foundry project · Solidity ^0.8.28 · NeoX chain only.

## Structure

```
src/
  NeoXRandomness.sol       # Single-call basic randomness (not tamper-proof)
  NeoXCommitReveal.sol     # Abstract commit-reveal tamper-proof randomness
test/
  NeoXRandomness.t.sol     # Unit tests for basic randomness
  NeoXCommitReveal.t.sol   # Unit tests for commit-reveal (uses MockGame wrapper)
script/
  Deploy.s.sol             # Deployment script (keystore auth)
```

## Build / Test / Deploy

```bash
forge build                                                     # compile
forge test -vvv                                                 # all tests (local Anvil)
forge test --match-test test_commitAndReveal -vvv               # single test by name
forge test --match-contract NeoXCommitRevealTest -vvv           # single test file
forge test --fork-url https://mainnet-1.rpc.banelabs.org -vvv   # NeoX mainnet fork
forge fmt --check                                               # format check (CI enforced)
forge fmt                                                       # auto-format
```

### CI Pipeline (.github/workflows/test.yml)

Runs on push + PR: `forge fmt --check` → `forge build --sizes` → `forge test -vvv`.
Uses `FOUNDRY_PROFILE=ci`. No fork-url tests in CI.

### Deploy

One-time keystore setup:

```bash
cast wallet import deployer --interactive
```

Deploy:

```bash
forge script script/Deploy.s.sol --account deployer --broadcast --rpc-url neox_mainnet
```

Foundry prompts for keystore password at runtime. Never pass `--private-key` directly.

### RPC Endpoints (foundry.toml)

- `neox_mainnet` = `https://mainnet-1.rpc.banelabs.org`
- `neox_testnet` = `https://neoxt4seed1.ngd.network`

## Architecture

Two contracts at different security tiers:

| Contract | Type | Tamper-proof | Use case |
|----------|------|-------------|----------|
| `NeoXRandomness` | Concrete | No | NFT traits, cosmetics |
| `NeoXCommitReveal` | Abstract | Yes | Lottery, card games, FundMe |

**NeoXRandomness**: `blockhash(block.number - 1)` + keccak256 mixing. Single call, publicly predictable.

**NeoXCommitReveal**: Two-phase (commit at block N → reveal at block N+1+). Business contracts inherit and call `_commit()` / `_reveal(requestId)`. Must reveal within 256 blocks or blockhash expires.

## NeoX Chain Specifics (CRITICAL)

- NeoX `blockhash` contains BLS aggregate signature entropy (96 bytes in `extraData`). This is the primary randomness source.
- `block.prevrandao` (mixHash) on NeoX changes ONLY on validator set rotations — **do NOT use it**.
- NeoX system contracts `0x1212000000000000000000000000000000000000` through `0006` are governance/bridge — unrelated to randomness.

## Code Style & Conventions

### Solidity

- **Pragma**: `^0.8.28` — all files must use this exact pragma.
- **License**: `// SPDX-License-Identifier: MIT` — first line of every file.
- **Formatter**: `forge fmt` — enforced in CI. Do not fight it.

### Imports

Named imports only. No wildcard or bare imports:

```solidity
import {Test} from "forge-std/Test.sol";                    // forge-std
import {NeoXRandomness} from "../src/NeoXRandomness.sol";   // project files (relative)
```

### Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Contracts | PascalCase | `NeoXCommitReveal` |
| Functions (external/public) | camelCase | `getRandomNumber`, `getRequest` |
| Functions (internal) | _prefixed camelCase | `_commit`, `_reveal` |
| Test functions | test_descriptiveName (snake_case after `test_`) | `test_commitAndReveal` |
| Events | PascalCase past tense | `Committed`, `Revealed` |
| Structs | PascalCase | `Request` |
| State variables | camelCase, no prefix | `nextRequestId`, `requests` |
| Local variables | camelCase | `requestId`, `hash` |

### NatSpec

Use `///` style (not `/** */`). Apply to contracts, public/external functions, structs, events, and state variables:

```solidity
/// @title NeoXRandomness
/// @notice Brief description.
/// @dev Implementation details.
/// @param seed Description of parameter.
/// @return Description of return value.
```

### Error Handling

Use `require` with string messages (not custom errors):

```solidity
require(req.requester != address(0), "request not found");
require(!req.revealed, "already revealed");
require(hash != bytes32(0), "blockhash expired, request void");
```

### Visibility Ordering in Contracts

1. State variables (public mappings/counters)
2. Events
3. Internal functions (`_commit`, `_reveal`)
4. External/public view functions (`getRequest`)

### Testing

- Test contract: `{ContractName}Test is Test`
- Setup: `function setUp() public` — deploy fresh instance.
- Abstract contracts: Create a `Mock*` wrapper (e.g., `MockGame is NeoXCommitReveal`) that exposes internal functions as external.
- Cheatcodes used: `vm.roll()`, `vm.warp()`, `vm.prank()`, `vm.expectRevert()`, `vm.expectEmit()`.
- Revert checks: `vm.expectRevert("exact string message")` — match the require string exactly.
- Assertions: `assertTrue`, `assertEq`, `assertFalse` — use descriptive message param for non-obvious checks.

### Deployment Scripts

- Inherit `Script` from forge-std.
- Import `console` for deploy logging.
- Wrap deploys in `vm.startBroadcast()` / `vm.stopBroadcast()`.

## Anti-Patterns (Do NOT)

- Do NOT use `block.prevrandao` — it doesn't rotate per block on NeoX.
- Do NOT use `blockhash(block.number)` — returns 0 during execution.
- Do NOT use custom errors — this project uses require strings consistently.
- Do NOT use wildcard imports (`import "forge-std/Test.sol"` without braces).
- Do NOT add `@ts-ignore`, `as any`, or equivalent type suppression.
- Do NOT commit `.env` files — they are gitignored.

## Dependencies

- `forge-std` (git submodule at `lib/forge-std`) — only external dependency.
- No OpenZeppelin, no other libraries. Keep it minimal.

## Commit Style

```
feat: NeoX BLS randomness service contracts
style: format NeoXCommitReveal contracts
```

Conventional commits: `feat:`, `fix:`, `style:`, `docs:`, `test:`, `chore:`.
