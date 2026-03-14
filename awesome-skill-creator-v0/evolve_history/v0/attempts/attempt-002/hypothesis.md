# Attempt 002：Day 2 — Sub-Agent 并行调研

**target_point**: 提升文献调研的深度与覆盖广度

**假设**: 如果用 5 个并行 sub-agent 分别专注不同研究维度（文献/前沿实现/工具分析/边界用例/用户场景），则单次调研的覆盖广度和质量显著优于单线程顺序调研。

**核心机制验证**：
1. 5 路并行调研能否在单次 session 内完成，而不因上下文长度爆炸而退化？
2. 各 agent 输出能否汇聚为统一的 eval_research/ schema？
3. 并行调研发现的 edge cases 是否比顺序调研更多？

## 研究背景

Day 1 的调研是单线程的：依次读文献、查工具、想边界用例。这种方式效率低，容易遗漏整个研究方向。

## 预期证据

1. 同一个领域 skill，并行调研 vs 顺序调研，eval case 数量更多
2. `edge_cases.json` 包含单线程难以发现的反例
3. `user_scenarios.json` 覆盖更多真实使用场景

## Expected Outcome

5 个专向 agent 并行启动，输出汇聚至 eval_research/ 的 5 个 JSON 文件。调研深度量化提升。
