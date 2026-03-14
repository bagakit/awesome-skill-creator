# Diff: Day 6 变更清单

## 新增断言类型

- `invoke_skill` — 在 fixture 上完整执行 skill，捕获输出用于后续断言
- `invoke_skill_judge` — 调用 LLM judge 对 skill 输出做质量评估
  - `judge_prompt`: 评估维度描述（必须具体，不能只写"评估质量"）
  - `pass_criteria`: judge 返回什么算通过
  - `pass_rate_threshold`: 多次运行的通过率阈值（0.8 默认）

## 关键设计决策

### LLM-as-judge 的稳定性问题

LLM 的非确定性导致单次 judge 结果不可靠。
→ 引入 pass_rate_threshold：同一 case 运行 N 次，通过次数/总次数 ≥ threshold 才算通过

### judge_prompt 质量的未解问题（Day 6 遗留）

过严的 judge_prompt：把好输出判为 FAIL
过宽的 judge_prompt：把坏输出判为 PASS
Day 6 没有解决 judge_prompt 质量验证问题——judge 的好坏靠创建者自己判断，这是一个重大盲区。
→ 留待 Day 7 解决

## 与 Day 5 的对比

| 指标 | Day 5 | Day 6 |
|------|-------|-------|
| 断言类型 | run_script | + invoke_skill + invoke_skill_judge |
| 主观质量覆盖 | 无 | 有（LLM judge） |
| judge 质量验证 | 无 | 无（遗留问题） |
