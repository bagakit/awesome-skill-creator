# 评测执行规范

> 定义 skill-creator 客观层评测的执行方式、判断标准和记录格式。

## 评测范围

评测对象：skill-creator 的**创建能力**和**自举能力**。
评测依据：`objective_cases.yaml` 中定义的用例。

## 执行方式

### 单条用例执行

1. 读取用例的 `input` 和 `context`
2. 将 `input` 作为 prompt 提交给 skill-creator（即触发 SKILL.md）
3. 收集 skill-creator 的完整输出（生成的文件和目录）
4. 逐条检查 `assertions` 中的断言

### 断言格式

每条断言必须包含 `type` 字段。根据类型，还需包含以下字段：

| type | 必须字段 | 可选字段 | 含义 | 验证方式 |
|------|----------|----------|------|----------|
| `file_exists` | `value`（文件路径） | — | 指定文件存在 | 文件系统检查 |
| `contains` | `value`（期望字符串） | `target`（文件路径） | 输出或指定文件包含该字符串 | 字符串匹配 |
| `not_contains` | `value`（排除字符串） | `target`（文件路径） | 输出或指定文件不包含该字符串 | 字符串匹配 |
| `yaml_valid` | `target`（文件路径） | — | YAML 格式合法 | YAML 解析 |
| `yaml_field_equals` | `target`（文件路径）, `field`, `value` | — | YAML 特定字段等于期望值 | 解析后字段比较 |
| `min_count` | `target`（文件路径）, `element`（计数目标描述）, `value`（最小数量） | — | 某类元素数量不少于 N | 内容分析计数 |
| `structure_match` | `value`（期望目录结构描述） | — | 目录结构匹配预期 | 递归目录比较 |
| `run_script` | `script`（bash 脚本） | `target`, `expected_exit`, `timeout_seconds`, `sandbox` | 执行 shell 脚本验证行为 | exit code 检查（⭐v4）|
| `invoke_skill` | `target`（skill 目录名）, `skill_file`（相对于 target 的 SKILL.md 路径）, `input`, `expected_contains` | `pass_rate_threshold`, `runs`, `timeout_seconds` | 调用 LLM 验证 Skill 输出语义 | LLM 调用（⭐v5）|
| `invoke_skill_judge` | `target`（skill 目录名）, `skill_file`（相对于 target 的 SKILL.md 路径）, `input`, `judge_prompt` | `pass_rate_threshold`, `runs`, `timeout_seconds` | LLM-as-judge 语义质量评判 | LLM 双阶段调用（⭐v6）|
| `judge_calibration` | `judge_prompt`, `good_example`, `bad_example` | `skill_file`, `timeout_seconds` | meta-oracle：验证 judge_prompt 区分力 | 双向 LLM 校验（⭐v7）|

**LLM 类断言降级规则**（`invoke_skill` / `invoke_skill_judge` / `judge_calibration`）：若检测到嵌套 Claude session 或 claude CLI 不可用，自动返回 `:skip`（不计入 pass/fail 统计）。

**P0/P1/P2 tier 字段**（⭐v7）：
- `tier: P0` — 核心约束，不可删，不可减弱
- `tier: P1` — 当前活跃（默认值，可省略）
- `tier: P2` — 已归档，run_eval.sh 默认过滤（需 `superseded_by` 字段）

**`gsb_baseline` 字段**（⭐v7，每条 case 可选，eval suite 中 ≥3 条必须有此字段）：
```yaml
gsb_baseline:
  bare_llm_expected: "裸 LLM 对同一 input 的预期输出行为（无 SKILL.md 指导时）"
  skill_advantage:   "本 Skill 相对于裸 LLM 应在哪个具体方面表现更好"
```
用途：为 GSB 基线对比提供预期依据（validate_evals.sh 强制检查 ≥3 条）。`bare_llm_expected` 和 `skill_advantage` 两个子字段均不可为空。

**`target` 字段说明**：当断言针对特定文件（而非 skill-creator 的文本输出）时使用。路径相对于 skill-creator 的工作目录。

### 批量执行

1. 按 `objective_cases.yaml` 中的顺序逐条执行
2. 每条用例独立执行（清理上一条用例生成的文件后再执行下一条）
3. 记录每条用例的通过/失败状态和详细信息

## 判断标准

### 单条用例
- **通过**：所有 assertions 均满足
- **失败**：任一 assertion 不满足

### 整体评估
- **expected_result: pass** 的用例全部通过 → 基线达标
- **expected_result: fail** 的用例确实失败 → 进化方向确认
- **expected_result: pass** 的用例有失败 → 存在退化，需修复
- **expected_result: fail** 的用例意外通过 → 能力突破，记录并更新

## 记录格式

每次评测执行后，生成评测报告：

```yaml
eval_run:
  timestamp: "ISO-8601"
  version_under_test: "v0"
  total_cases: N
  results:
    - case_id: "case_id"
      expected_result: pass | fail
      actual_result: pass | fail
      assertions_detail:
        - type: "file_exists"
          value: "hello-world-v0/SKILL.md"
          actual: true
      notes: "可选备注"
  summary:
    expected_pass_actual_pass: N
    expected_pass_actual_fail: N  # 退化，需修复
    expected_fail_actual_fail: N  # 进化方向确认
    expected_fail_actual_pass: N  # 能力突破
```

## Preflight 快速验证协议

全量 eval 执行前，先运行 2-3 条核心 P0 用例作为快速验证（sanity check）：

1. 选取 `regression_level: P0` 且 `expected_result: pass` 的用例各 1 条
2. 执行这些用例的所有断言
3. 若任一 P0 用例失败 → 终止后续全量 eval，优先修复
4. 全部通过 → 继续执行完整 eval suite

Preflight 结果记录在 `attempt-001/preflight.json`（`execution_status: "actual"`）。

## only-increase 合规检查

在版本升级场景下（如 v0→v1），额外执行：

1. 将 v0 的 `objective_cases.yaml` 全部用例在新版本上执行
2. v0 中 `expected_result: pass` 的用例在新版本上必须全部通过
3. 任何退化（原通过现失败）→ 升级不合格
4. v0 中 `expected_result: fail` 的用例在新版本上如果通过 → 记录为能力突破

## GSB 基线对比协议

GSB（Good / Same / Bad）对比用于量化 Skill 相对于裸 LLM 的增值性。

### 执行方式

每条 eval case 执行两次：
1. **Skill 执行**：完整走 SKILL.md → process.md 流程
2. **裸 LLM 执行**：相同 input，不提供 SKILL.md / process.md / scaffold.md 等任何 Skill 指导

### 判定维度

| 判定 | 含义 |
|------|------|
| **Good** | Skill 输出在断言覆盖、结构完整性或内容质量上显著优于裸 LLM |
| **Same** | 无显著差异 |
| **Bad** | Skill 输出劣于裸 LLM（流程引入噪音或约束过死） |

- 客观层：通过断言通过率自动判定
- 主观层：需人工标注

### 汇总指标

- **Skill 增值率** = Good / (Good + Same + Bad)
- 增值率 < 30% 持续 N 个心跳周期 → 触发退休流程（参见 whitepaper §4.6）

### GSB 归因分析

当 GSB = Bad 或 Same 时，需定位到 process.md 的具体步骤：
1. **差异定位**：哪个步骤的输出与裸 LLM 差异最大？
2. **增值判定**：差异是正向（Skill 增值）还是负向（Skill 引入噪音）？
3. **归因**：负向差异的根因是步骤设计问题还是 eval 覆盖盲区？

### 复杂度变化记录

每次版本升级时记录 `complexity_delta`：

```yaml
complexity_delta:
  token_count: -15%    # Skill prompt 总 token 变化
  step_count: -1        # process.md 步骤数变化
  file_count: 0         # 输出文件数变化
```

精简（complexity_delta 为负）在不降低 eval 通过率的前提下，视为合法进化方向。
