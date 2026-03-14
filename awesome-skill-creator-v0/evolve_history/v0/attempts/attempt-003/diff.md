# Diff: Day 3 变更清单

## 新增文件 / 字段

- `.step0.yaml` — Step 0 的强制产物：
  - `success_definition`: 可验证的成功定义（必须含领域词汇，不能是"产出高质量 skill"）
  - `domain_vocab`: 领域核心词汇列表（用于验证 SKILL.md description）
  - `failure_modes`: 预定义失败模式列表（每条对应一个 expected_result: fail case）
- `process.md` Step 0 — 更新为强制填写 .step0.yaml

## 关键设计决策

### 目标前置（Goal-First）

传统流程：先写 SKILL.md → 再写 eval。问题：eval 倾向于验证已有的结构，而不是目标。
Goal-First 流程：先写 .step0.yaml → SKILL.md description 必须含 domain_vocab → eval 必须覆盖 failure_modes。

### 失败模式预定义

failure_modes 在 .step0.yaml 中预定义，强制创建者在开始前想清楚"这个 skill 会怎么失败"。
→ 每个 failure_mode 对应一条 expected_result: fail 的 eval case

## 与 Day 2 的对比

| 指标 | Day 2 | Day 3 |
|------|-------|-------|
| 目标显式化 | 无 | .step0.yaml 强制 |
| eval 与目标对齐 | 弱 | 通过 failure_modes 回溯 |
| domain_vocab 验证 | 无 | validator 检查 |
