# Diff: Day 4 变更清单

## 新增字段

- `evals/objective_cases.yaml` case schema 新增：
  - `expected_result: fail` — 预期失败 case 标记
  - `evolution_direction` — fail case 必填，描述修复方向
- `evals/eval_protocol.md` — 新增 fail case 设计规范：
  - 每个 skill 至少 2 个 expected_result: fail case
  - fail case 必须来自 .step0.yaml 的 failure_modes
  - evolution_direction 必须精确到流程步骤，不能写"improve quality"

## 关键设计决策

### Failure-Mode-First 设计顺序

旧顺序：写 process.md → 想"会通过什么" → 写 pass case → 最后想 fail case
新顺序：读 failure_modes → 先写 fail case → 再写能覆盖它的 pass case

### evolution_direction 精度要求

差：「improve domain specificity」
好：「Step 3 sub-agent research 未覆盖目标领域的核心工具，导致 process.md 推荐了通用工具而非领域专向工具」

## 与 Day 3 的对比

| 指标 | Day 3 | Day 4 |
|------|-------|-------|
| fail case 比例 | 无强制 | ≥ 30% |
| 失败诊断精度 | "输出不对" | 步骤级 evolution_direction |
| 功能回归检测率 | ~10% | ~60% |
