---
attempt: "008"
target_point: "P2 智能归档推荐 — suggest_p2_candidates.sh 改进"
date: "2026-03-15"
status: "in_progress"
---

# Attempt 008 — Hypothesis

## 单点定义

**本轮只攻一个优化点**：让 `suggest_p2_candidates.sh` 在 v0 自身的 51 条 eval case 上输出 ≥2 条合理 P2 归档建议。

当前状态：脚本运行返回 "No P2 candidates found"，尽管 eval suite 中存在可被检测的冗余关系。

---

## 为什么这个点是当前最值得攻破的瓶颈

1. **验收指标明确失败**：evolution.md 中 Direction 2 的验收标准是"输出至少 2 条合理归档建议"，但当前完全无输出。
2. **工具已存在但无效**：基础框架在 v0 中已存在，修复成本远低于新建，符合"精简是进化的合法方向"原则。
3. **不依赖其他方向**：Direction 1（Step-Level Judge）复杂度高，Direction 3 依赖 Direction 1。Direction 2 可以独立完成。

---

## 根因分析（诊断）

### 问题 1：精确字符串匹配无法跨 skill 名

当前脚本对每个断言生成 token `type:key=value`，例如：
- `eval_has_content_assertions`: `{contains:value=contains, contains:target=refactoring-guide-v0/evals/objective_cases.yaml}`
- `eval_file_exists_ratio`: `{min_count:target=sql-optimizer-v0/evals/objective_cases.yaml, ..., contains:value=contains, contains:target=sql-optimizer-v0/evals/objective_cases.yaml}`

这两个 case 实际上是 subsumption 关系（前者 ⊆ 后者），但因为 target 路径包含不同 skill 名（`refactoring-guide-v0` vs `sql-optimizer-v0`），精确匹配无法发现。

**修复**：归一化 target 路径，去除 skill 特定前缀（`<skill-name>-v0/` → `<skill>/`）。

### 问题 2：字符串包含语义未被识别

`ultimate_test_created_unknown_skill` 的断言 `contains: "合格"` 是 `v4_terminal_test_unfamiliar_domain` 的断言 `contains: "**合格**: 是"` 的弱版本——任何通过强版本的文件必然也通过弱版本（因为 "合格" 是 "**合格**: 是" 的子字符串）。但当前脚本将这两者视为完全不同的 token，无法发现此关系。

**修复**：对 `contains` 断言实施字符串包含检测：若 token A 的 value 是 token B 的 value 的子字符串，且两者 target 相同，则 A 被 B 语义包含。

---

## 假设（Hypothesis）

**H1**：路径归一化 + 字符串包含语义检测，将使 `suggest_p2_candidates.sh` 在当前 v0 eval suite 上找到至少 2 条合理 P2 候选：

1. `eval_has_content_assertions` → superseded by `eval_file_exists_ratio`（路径归一化解锁）
2. `ultimate_test_created_unknown_skill` → superseded by `v4_terminal_test_unfamiliar_domain`（字符串包含语义解锁）

**H2**：改进后的脚本在当前已归档的 P2 case（`eval_quality_meets_threshold`）上不会产生错误报告（已有 `tier: P2` 标注，应被过滤）。

**H3**：改进不会破坏任何现有 validate.sh 验证。

---

## 验证计划

1. 改进 `suggest_p2_candidates.sh`（路径归一化 + 字符串包含）
2. 运行改进后脚本，确认输出 ≥2 条建议
3. 人工审查建议的合理性
4. 新增 eval case 测试改进后脚本行为
5. 运行 `validate.sh` 确认无回归
6. 写入 diff.md + preflight.json + eval_report.json + verdict.json

---

## 放弃的替代方向

1. **增加新的 eval case 使 subsumption 关系成立**：gaming the eval，违反 only-increase 原则精神。
2. **引入 semantic embedding 相似度**：过度工程化，NLP 相似度不适合精确的 P2 归档决策，误判率高。
3. **只做路径归一化，不做字符串包含**：仅找到 1 个候选，不满足验收指标。
