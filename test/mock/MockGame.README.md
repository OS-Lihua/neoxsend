# MockGame — NeoXCommitReveal 测试合约

继承 `NeoXCommitReveal` 抽象合约的最小化实现，用于在测试网上验证 commit-reveal 随机数机制。

## 合约地址（NeoX 测试网）

| 合约 | 地址 |
|------|------|
| MockGame | `0x1297428225adaFE7ad9a7481514026fCa452983B` |

- 链：NeoX Testnet（Chain ID: 12227332）
- RPC：`https://testnet.rpc.banelabs.org`

## 部署

```bash
forge create src/MockGame.sol:MockGame \
  --account dealer \
  --rpc-url neox_testnet \
  --broadcast --legacy --gas-price 40000000000
```

> 注意：NeoX 测试网不支持 EIP-1559 交易类型，需要加 `--legacy` 参数。

## 验证过程

进行了 3 轮 commit-reveal 测试：

### Commit 阶段

```bash
# requestId = 0
cast send <MockGame> "commit()" --account dealer --rpc-url neox_testnet --legacy --gas-price 40000000000
# requestId = 1
cast send <MockGame> "commit()" --account dealer --rpc-url neox_testnet --legacy --gas-price 40000000000
# requestId = 2
cast send <MockGame> "commit()" --account dealer --rpc-url neox_testnet --legacy --gas-price 40000000000
```

### Reveal 阶段

```bash
cast send <MockGame> "reveal(uint256)" 0 --account dealer --rpc-url neox_testnet --legacy --gas-price 40000000000
cast send <MockGame> "reveal(uint256)" 1 --account dealer --rpc-url neox_testnet --legacy --gas-price 40000000000
cast send <MockGame> "reveal(uint256)" 2 --account dealer --rpc-url neox_testnet --legacy --gas-price 40000000000
```

### 随机数结果

| requestId | commitBlock | 随机数 (hex) |
|-----------|-------------|-------------|
| 0 | 7024558 | `856ebbdb911083853a6b9e53644d8287ac9c2a4c49cf47984b570304f97e77f5` |
| 1 | 7024562 | `0c5ae4e64e354a6f3c6629fd20622db85856d735148b528486cda284cc57e859` |
| 2 | 7024575 | `91cfff37a2ef2c14449168c4cfa613aa2f2260722e2b59fc5c305fd217270f1f` |

### 防重放验证

对已 reveal 的 requestId 再次调用 `reveal(0)`，合约正确 revert：

```
execution reverted: already revealed
```

## 验证结论

- 3 个随机数完全不同，无规律可循
- 数值分布在整个 uint256 范围内，非连续/可预测
- 重复 reveal 同一个 requestId 被正确拒绝
- commit-reveal 随机数机制在 NeoX 测试网上运行正常
