# Attempt 007：Day 7 — judge_calibration + P0/P1/P2 分级

**target_point**: 解决 judge 质量无法自验证问题；解决 only-increase 的约束空间膨胀问题

**假设 A（judge_calibration）**: 如果引入 meta-oracle（judge_calibration 断言），用已知的好/坏样本对 judge_prompt 做双向校验，则能可靠检测 over-strict / over-lenient judge，消除 Day 6 遗留的 judge 质量风险。

**假设 B（P0/P1/P2）**: 如果引入三级保护机制（P0 核心不可删 / P1 日常活跃 / P2 归档但可追溯），则能缓解 only-increase 原则在长期版本积累后的约束空间膨胀问题（EWC 容量炸弹）。

## 核心机制验证

1. judge_calibration 的双向校验（good_example → PASS，bad_example → FAIL）是否能发现 over-strict/over-lenient judge？
2. P2 归档能否在保持历史可追溯性的同时，减少日常 eval 中的 case 负担？
3. P0 约束是否稳定（不受版本升级影响）？

## 预期证据

1. judge_calibration 成功检测出 Day 6 中因 judge_prompt 过严导致的 1 个误判 case
2. P2 归档后，日常 eval 通过率统计中不再包含已归档 case，但 --all-tiers 仍可完整回放
3. P0 case 在 3 个版本迭代中保持稳定

## Expected Outcome

judge_calibration 成为所有 invoke_skill_judge eval 套件的强制伴随断言；P0/P1/P2 分级成为 eval case 的标准字段。这是 seven days of genesis 的最终产物。
