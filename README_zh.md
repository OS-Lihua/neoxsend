# NeoX BLS Randomness

[English](./README.md)

基于 NeoX BLS 聚合签名的链上随机数服务合约。

## 背景

NeoX 使用 dBFT 共识，每个区块由多个验证者进行 BLS 聚合签名。该签名（96 字节）存储在区块头的 `extraData` 字段中，并被纳入 `blockhash` 的计算。因此 NeoX 的 `blockhash` 天然包含 BLS 签名的熵，随机性比传统 PoW/PoS 链更强。

> 注意：`block.prevrandao`（mixHash）在 NeoX 上仅在验证者集合轮换时才变化，不适合作为逐块熵源，本项目不使用它。

## 合约

### NeoXRandomness.sol — 基础随机数

直接调用，一笔交易即可获取随机数。

- **不防作弊**：`blockhash(block.number - 1)` 在当前区块执行时已公开，攻击者可提前计算结果。
- **适用场景**：NFT 属性生成、游戏装饰性随机等不涉及资金的场景。

```solidity
NeoXRandomness randomness = NeoXRandomness(address);
uint256 random = randomness.getRandomNumber(seed);
```

### NeoXCommitReveal.sol — 防作弊随机数

两步走（commit-reveal），强制隔开至少一个区块，防止预测和作弊。

- **防作弊**：commit 时随机源（blockhash）尚未产生，无法预测；reveal 时用户已 commit，无法反悔。
- **适用场景**：抽奖、发牌比大小、FundMe 等涉及资金的场景。
- **限制**：commit 后须在 256 个区块内 reveal，否则 blockhash 过期，请求作废。
- **抽象合约**：业务合约继承它，调用 `_commit()` / `_reveal()`。

```solidity
contract CardGame is NeoXCommitReveal {
    function placeBet() external payable {
        uint256 requestId = _commit();
        // 记录赌注...
    }
    function settle(uint256 requestId) external {
        uint256 random = _reveal(requestId);
        // 用 random 决定输赢...
    }
}
```

## 使用

### 构建

```shell
forge build
```

### 测试

```shell
# 本地测试
forge test -vvv

# NeoX 主网 Fork 测试
forge test --fork-url https://mainnet-1.rpc.banelabs.org -vvv
```

### 部署

```shell
# 将私钥导入 Foundry keystore（仅需一次）
cast wallet import deployer --interactive

# 部署到 NeoX 主网
forge script script/Deploy.s.sol --account deployer --broadcast --rpc-url neox_mainnet

# 部署到 NeoX 测试网
forge script script/Deploy.s.sol --account deployer --broadcast --rpc-url neox_testnet
```

## 文件结构

```
src/
  NeoXRandomness.sol      # 基础随机数服务（不防作弊）
  NeoXCommitReveal.sol    # commit-reveal 防作弊随机数服务（抽象合约）
test/
  NeoXRandomness.t.sol    # NeoXRandomness 测试
  NeoXCommitReveal.t.sol  # NeoXCommitReveal 测试
script/
  Deploy.s.sol            # 部署脚本
```
