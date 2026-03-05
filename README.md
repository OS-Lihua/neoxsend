# NeoX BLS Randomness

[中文文档](./README_zh.md)

On-chain randomness service contracts powered by NeoX BLS aggregate signatures.

## Background

NeoX uses dBFT consensus where each block is signed by multiple validators via BLS aggregate signatures. The signature (96 bytes) is stored in the block header's `extraData` field and is included in the `blockhash` calculation. This makes NeoX's `blockhash` inherently stronger in randomness compared to traditional PoW/PoS chains.

> Note: `block.prevrandao` (mixHash) on NeoX only changes on validator set rotations, not per block. This project does not use it.

## Contracts

### NeoXRandomness.sol — Basic randomness

Single-call, one transaction to get a random number.

- **Not tamper-proof**: `blockhash(block.number - 1)` is publicly known at execution time; attackers can precompute the result.
- **Use cases**: NFT trait generation, cosmetic game randomness, and other non-financial scenarios.

```solidity
NeoXRandomness randomness = NeoXRandomness(address);
uint256 random = randomness.getRandomNumber(seed);
```

### NeoXCommitReveal.sol — Tamper-proof randomness

Two-step commit-reveal pattern, enforcing at least one block gap to prevent prediction and cheating.

- **Tamper-proof**: At commit time the randomness source (blockhash) does not yet exist; at reveal time the user has already committed and cannot back out.
- **Use cases**: Lottery, card games, FundMe, and other scenarios involving funds.
- **Limitation**: Must reveal within 256 blocks after commit, otherwise the blockhash expires and the request becomes void.
- **Abstract contract**: Business contracts inherit it and call `_commit()` / `_reveal()`.

```solidity
contract CardGame is NeoXCommitReveal {
    function placeBet() external payable {
        uint256 requestId = _commit();
        // record the bet...
    }
    function settle(uint256 requestId) external {
        uint256 random = _reveal(requestId);
        // determine winner using random...
    }
}
```

## Usage

### Build

```shell
forge build
```

### Test

```shell
# Local tests
forge test -vvv

# NeoX mainnet fork tests
forge test --fork-url https://mainnet-1.rpc.banelabs.org -vvv
```

### Deploy

```shell
forge script script/NeoXRandomness.s.sol:NeoXRandomnessScript --rpc-url https://mainnet-1.rpc.banelabs.org --private-key <your_private_key> --broadcast
```

## File Structure

```
src/
  NeoXRandomness.sol      # Basic randomness service (not tamper-proof)
  NeoXCommitReveal.sol    # Commit-reveal tamper-proof randomness (abstract)
test/
  NeoXRandomness.t.sol    # NeoXRandomness tests
  NeoXCommitReveal.t.sol  # NeoXCommitReveal tests
script/
  NeoXRandomness.s.sol    # Deployment script
```
