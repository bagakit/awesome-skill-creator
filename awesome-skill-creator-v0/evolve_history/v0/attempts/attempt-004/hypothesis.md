# Attempt 004：Day 4 — Failure-Mode-First Eval

**target_point**: 构建能区分好坏输出的 eval，而不只是验证结构存在

**假设**: 如果 eval 优先设计 expected_result: fail 的 case（而不是从"应该通过什么"出发），并为每个 fail case 标注 evolution_direction，则 eval 集能有效检测到功能退化，而不只是结构违规。

**核心机制验证**：
1. 加入 expected_result: fail case 后，eval 是否能发现纯 pass-only eval 遗漏的功能回归？
2. evolution_direction 字段是否能将失败诊断精确到可操作的改进点？
3. 失败模式先行（fail-first）的设计方式是否比"通过后再想边界"更有效？

## 研究背景

Day 3 的 eval 包含了来自 failure_modes 的 fail case，但 eval 机制本身还没有强制要求"至少 N 个 fail case"。结果：eval 倾向于通过结构检查就宣布"通过"，而实际功能质量未验证。

## 预期证据

1. 在有 expected_result: fail case 的 eval 中，至少有 2 个 case 能在人为降低 skill 质量时变红
2. evolution_direction 字段使得失败分析从"输出不对"变成"Step X 的 Y 缺少 Z"
3. 对比无 fail case 的 eval vs 有 fail case 的 eval，功能回归检测率：10% vs 60%+

## Expected Outcome

eval 集设计规范更新：fail case 比例 ≥ 30%，每个 fail case 必须有 evolution_direction。
