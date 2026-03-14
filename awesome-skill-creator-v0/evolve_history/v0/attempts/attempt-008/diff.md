---
attempt: "008"
target_point: "P2 智能归档推荐 — suggest_p2_candidates.sh 改进"
date: "2026-03-15"
---

# Attempt 008 — Diff

## 变更概述

本轮只改了一个文件（主体），加了一个新 ref card，增加了 5 条 eval case，更新了 article。

---

## 1. `tools/scripts/suggest_p2_candidates.sh`（核心改动）

### 改动 1：路径归一化（Path Normalization）

**Before**：精确字符串匹配，`hello-world-v0/evals/foo.yaml` 与 `code-reviewer-v0/evals/foo.yaml` 视为不同路径。

**After**：`normalize()` 函数将 `<skill-name>-v<N>/` 前缀替换为 `<skill>/`，使得跨不同 skill fixture 的同构断言能被识别为等价。

```ruby
# Before (implicit, no normalization):
fps << "#{a["type"]}:#{k}=#{v}" unless k == "type"

# After:
def normalize(v)
  return v unless v.is_a?(String)
  v.gsub(/\A[a-z][a-zA-Z0-9_-]+-v\d+\//, "<skill>/")
end
fps << "#{a["type"]}:#{k}=#{normalize(v)}" unless k == "type"
```

**发现的 candidate**：`eval_has_content_assertions` ⊆ `eval_file_exists_ratio`

### 改动 2：字符串包含语义检测（String-Containment Subsumption）

**Before**：只做精确 token 匹配，`contains:value=合格` ≠ `contains:value=**合格**: 是`，关系不被发现。

**After**：新增 `contains_token_subsumed_by?()` 方法，当 weak 的 `contains:value=X` 被 strong 的 `contains:value=Y` 包含（X 是 Y 的子字符串），且两者的 normalized target 相同时，判定为 semantic subsumption。

语义正确性：若文件包含 Y，则必然包含 X（因为 X ⊆_str Y）。因此 X 的断言比 Y 的断言更弱。

**发现的 candidate**：`ultimate_test_created_unknown_skill` ⊆ `v4_terminal_test_unfamiliar_domain`（`"合格"` ⊆_str `"**合格**: 是"`）

### 改动 3：新增 `--json` 输出模式

支持 `--json` flag，输出机器可读的 JSON 数组，包含 `candidate`、`superseded_by`、`weak_tokens`、`strong_tokens` 字段，便于未来集成到 CI/CD 或自动化工具。

### 改动 4：候选去重

当同一弱 case 被多个强 case 包含时，自动选取 token 最多（最强）的候选作为 `superseded_by` 建议，避免歧义。

---

## 2. 新增：`evolve_history/v0/assets/references/ref_yoo_harman_2012_test_minimization.md`

P2 归档的理论基础文献卡片。关键贡献：
- 形式化定义了 subsumption-based test suite minimization
- "Rothermel 危险"解释了为什么要归档而非删除（可逆性）
- Essential test cases 概念对应 P0 tier

---

## 3. `evals/objective_cases.yaml`（新增 5 条 case）

| case id | 验证内容 |
|---------|---------|
| `suggest_p2_finds_min_two_candidates` | 改进后脚本输出 ≥2 条建议 (P1, regression_level P0) |
| `suggest_p2_path_normalization` | 路径归一化找到 `eval_has_content_assertions` 候选 |
| `suggest_p2_string_containment` | 字符串包含语义找到 `ultimate_test_created_unknown_skill` 候选 |
| `suggest_p2_json_mode_valid` | `--json` 输出合法 JSON 含 4 个必须字段 |
| `suggest_p2_skips_existing_p2` | 已归档 P2 case 不重复出现 |

所有 5 条均通过 validate.sh（run_script 静态分析），新增 46 个 validate checks。

---

## 4. Article 更新（`evolve_history/v0/article/awesome_skill_creator_v0_genesis_the_seven_days.md`）

- **Section 2.4** 新增 Yoo & Harman (2012) [17] 段落（约 200 字），解释 P2 归档的形式化基础
- **Section 6 Conclusion** 修正 "Weyuker 1982 for test set optimization"（Weyuker 的论文实际上是 oracle 问题，不是 test set optimization）→ "Yoo & Harman 2012 [17] for P2 archiving via subsumption analysis"
- **Structured Reference Cards** 新增 `ref_yoo_harman_2012_test_minimization` 条目
- **References** 新增 [17] 引用条目

---

## 未改动的设计决策

1. **脚本语言保持 Ruby**：与现有 validate_evals.sh 等工具一致，不引入新依赖
2. **只建议不自动归档**：人工审查是 P2 归档的必要步骤，工具只提供建议
3. **不做 NLP 相似度**：embedding 相似度在精确断言比较中噪音太大
