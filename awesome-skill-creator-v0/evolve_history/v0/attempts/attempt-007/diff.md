# Diff: Day 7 变更清单

## 新增断言类型

- `judge_calibration` — meta-oracle，用已知好/坏样本双向校验 judge_prompt：
  - `good_example`: 已知应被判 PASS 的样本
  - `bad_example`: 已知应被判 FAIL 的样本
  - 双向任一失败 → 强制修正 judge_prompt，不允许绕过

## 新增 eval case 字段

- `tier: P0 | P1 | P2`
  - P0：核心约束，不可删、不可减弱
  - P1：日常活跃约束，参与通过率统计
  - P2：已归档约束，通过 `superseded_by` 指向取代者
- `superseded_by: eval_case_xxx`（仅 P2 使用）

## 强制约束

- 所有含 `invoke_skill_judge` 断言的 eval 套件，必须有至少 1 个 `judge_calibration` 断言
- P0 case 的 pass_rate 单独统计，不与 P1/P2 混合
- `--all-tiers` flag 使 P2 case 重新参与 eval（审计模式）

## 与 Day 6 的对比

| 指标 | Day 6 | Day 7 |
|------|-------|-------|
| judge 质量验证 | 无（遗留风险） | judge_calibration 双向验证 |
| eval 约束增长 | 无上限 | P2 归档缓解膨胀 |
| 历史可追溯性 | 完整 | 完整（--all-tiers） |
| P0 核心保护 | 无 | 有（P0 不可删） |
