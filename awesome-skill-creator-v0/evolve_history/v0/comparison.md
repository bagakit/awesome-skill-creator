# v0 vs 裸 LLM 对比

## GSB 分析：awesome-skill-creator v0 vs 裸 LLM

| 场景 | 裸 LLM | awesome-skill-creator v0 | 判定 |
|------|--------|--------------------------|------|
| eval 设计 | 会写 eval，但通常只有 contains 断言，无 judge_calibration | 强制 judge_calibration + run_script 行为验证 | G（Skill 更好）|
| 目标定义 | 通常跳过或写得泛化 | 强制 .step0.yaml 含领域词汇 | G |
| 进化路径 | 无结构化进化记录 | evolve_history + evolution.md + Top 3 方向 | G |
| 调研质量 | 单线程，容易遗漏 | 5 类 sub-agent 并行，JSON 格式输出 | G |
| 失败归因 | 通常不记录失败原因 | attempts/ + genesis.md 被否决方案 | G |
| 一次性输出 | 快速，低成本 | token 消耗约 3-5x（sub-agent + 多步验证）| B（裸 LLM 更好）|
| 灵活性 | 无约束，随意发挥 | 11 条强制约束 | S（各有优劣）|

**GSB 统计**：G=5, S=1, B=1
**增值率**：G/(G+S+B) = 5/7 ≈ 71%

**注**：增值率基于结构性能力差异，非盲评实测。实际增值率需通过 blind eval 测量。

## 已知代价/Trade-offs

1. **Token 消耗**：sub-agent 调研 + 多步验证 + judge_calibration 使每次创建消耗约 3-5x 裸 LLM 的 token。适用于需要长期维护的 skill，不适用于一次性输出场景。

2. **执行时间**：5 类 sub-agent 并行调研即使并行执行也需要较长时间（取决于 LLM 响应速度）。

3. **学习曲线**：11 条核心约束 + process.md 的 10 个步骤对使用者有一定学习成本。

4. **LLM 断言的嵌套限制**：judge_calibration、invoke_skill_judge 在 Claude Code 内嵌套执行时会自动 skip，需要独立环境才能真正验证。

5. **P2 归档手动维护**：随 eval suite 增长，P2 归档决策依赖人工判断，这个成本会逐步积累（v1 方向 2 将缓解此问题）。
