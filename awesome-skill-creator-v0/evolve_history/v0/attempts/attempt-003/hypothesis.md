# Attempt 003：Day 3 — Goal-First Design / .step0.yaml

**target_point**: 防止「技术正确但领域错误」的 skill 输出

**假设**: 如果在 skill 创建第一步强制定义 success_definition + domain_vocab + failure_modes（.step0.yaml），则生成的 skill 的 eval 会更贴近领域目标，而不是通用技术正确性。

**核心机制验证**：
1. 有 .step0.yaml 约束的 skill 创建流程是否产生更多领域专向的 eval case？
2. success_definition 中的领域词汇是否能有效过滤"通用但无用"的输出？
3. failure_modes 预定义是否帮助 eval 设计避免了常见盲区？

## 研究背景

Day 2 的调研能发现大量材料，但创建流程缺少"为什么要创建这个 skill"的显式约定。结果是：
- eval 倾向于检查技术结构（文件存在、格式正确），而不是领域功能
- skill 的 SKILL.md description 经常是通用的，缺少领域核心词汇

## 预期证据

1. 有 .step0.yaml 的 skill 的 eval case 平均比无 .step0.yaml 的 skill 多 2 条领域特向 case
2. success_definition 非空且含领域词汇 → validator 强制检查
3. failure_mode 预定义催生了对应的 expected_result: fail case

## Expected Outcome

.step0.yaml 成为 Step 0 的强制准出物，eval 设计回溯到 failure_mode，而不是从通用 best practices 出发。
