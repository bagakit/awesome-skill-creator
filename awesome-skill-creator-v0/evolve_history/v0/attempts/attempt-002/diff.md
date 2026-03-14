# Diff: Day 2 变更清单

## 新增能力

- `process.md` Step 3 — 拆分为 5 路并行 sub-agent：
  - literature-research：查论文与方法脉络
  - frontier-impl-analysis：查最前沿实现与工程手法
  - tool-analysis：查竞品和邻近系统
  - edge-cases：专门挖边界失败和反例
  - user-scenarios：补真实使用场景

## 关键设计决策

### 并行而非顺序

单线程调研时，agent 容易被某个方向吸引，忽略其他维度。5 路并行各有专注，互不干扰，最后汇总。
→ 汇总时必须统一 schema，否则研究热闹但无法进入 eval

### 被否决的方案

- **10+ agent 超并行**：被否决，context 汇总复杂度过高，收益递减
- **单线程但更多 steps**：被否决，容量有限且无法真正覆盖多个方向

## 与 Day 1 的对比

| 指标 | Day 1 | Day 2 |
|------|-------|-------|
| 调研方式 | 单线程 | 5 路并行 |
| eval_research/ 文件 | 无或手写 | 5 个标准 JSON |
| edge case 发现数 | ~2 | ~8（估计） |
