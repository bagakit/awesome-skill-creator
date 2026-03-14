# Skill 创建标准流程

> Skill 的价值 = 能解决领域问题。eval 的价值 = 能区分好输出和坏输出。judge 的价值 = 能区分好坏判断。
> 本文件由 SKILL.md 在运行时读取并执行，不应被直接触发。

## 前置条件

- 已读取 `scaffold.md`（目录结构模板）
- 已读取 `../meta_whitepaper.md`（设计原则）
- 用户提供：skill 名称 + 功能描述 + 初始 case（如有）

---

## 流程步骤

### Step 0: 定义技能目标（Goal-First）⭐强制，所有步骤的北极星
**输入**：用户想法
**输出**：`.step0.yaml`（写入 skill 目录根，使目标定义可追溯可验证）

在执行任何其他步骤之前，先完成以下三项定义，**并写入 `.step0.yaml`**：

1. **成功定义**（`success_definition`）：「这个 Skill 成功执行时，用户得到______」（用领域词汇描述具体输出，validate_structure.sh 强制检查是否含领域词汇，通用描述为 **fail**）
2. **失败模式**（`failure_modes`，列表，至少 3 项）：「当 Skill 失败时，用户会得到______」
3. **领域词汇表**（`domain_vocab`，列表，至少 5 项）：该领域不可绕过的专有术语

`.step0.yaml` 格式（`skill_name` 与目录名一致；`created_at` 必须是 YYYY-MM-DD 格式，缺失为 **fail**）：
```yaml
skill_name: <name>     # 必须与 skill 目录名一致（validate_structure.sh 强制）
created_at: <ISO date> # YYYY-MM-DD 格式（validate_structure.sh 强制）
success_definition: "<用领域词汇描述的具体成功输出>"
failure_modes:
  - id: A
    description: "<失败描述>"
    eval_detection: "<eval 如何检测此失败>"
  - id: B
    ...
domain_vocab:
  - <term1>
  - <term2>
  ...
```

**Step 0 是整个流程的北极星**：后续每个步骤的设计决策都应回答「这能让 Skill 更好地实现目标吗？」

---

### Step 1: 需求分析
**输入**：用户的 skill 想法描述 + Step 0 目标定义
**输出**：结构化需求摘要（直接输出给用户确认，不写文件）

1. 从 `$ARGUMENTS` 中提取：skill 名称、功能描述、初始 case（如有）
2. 明确 skill 的能力边界——它做什么、不做什么
3. 确定 skill 类型：`meta` | `infrastructure` | `domain` | `utility`
4. 识别与联邦中已有 Skill 的依赖/互补关系（用 Glob `**/manifest.yaml` 扫描同级目录）
5. 确定 2-3 个可量化的进化维度（为 Step 3.5 做准备）
6. 确定本次创建的 `target_point`（本版本攻克的单一核心优化点）
7. **输出需求摘要，等待用户确认后继续**

---

### Step 2: Sub-agent 并行调研（每次创建必须执行）
**输入**：经用户确认的需求 + Step 0 词汇表
**输出**：`evals/eval_research/` 下 5 个结构化 JSON + 参考卡片 + genesis.md 调研影响矩阵

#### 2.1 启动 5 类 Sub-agent 并行调研

同时拉起以下 5 类 sub-agent：

**Agent 1: literature-research**
任务：搜集该领域最重要的学术论文和方法脉络
搜索词：`"{skill领域} arxiv"` / `"{skill领域} survey 2023 2024"` / `"{skill领域} benchmark"`
产出：`evals/eval_research/literature_review.json`

**Agent 2: frontier-impl-analysis**
任务：调研该领域最前沿的工程实现和开源工具
搜索词：`"{skill领域} github"` / `"{skill领域} best practices"` / `"{skill领域} state of the art"`
产出：`evals/eval_research/frontier_impls.json`

**Agent 3: tool-analysis**
任务：分析竞品和邻近系统的优劣势
搜索词：`"{skill领域} comparison"` / `"{skill领域} vs"` / `"{skill领域} alternatives"`
产出：`evals/eval_research/tool_analysis.json`

**Agent 4: edge-cases**
任务：专门挖掘边界失败场景和反例
搜索词：`"{skill领域} failure cases"` / `"{skill领域} limitations"` / `"{skill领域} edge cases"`
产出：`evals/eval_research/edge_cases.json`

**Agent 5: user-scenarios**
任务：补充真实使用场景和任务形态
搜索词：`"{skill领域} use cases"` / `"{skill领域} workflows"` / `"{skill领域} real world"`
产出：`evals/eval_research/user_scenarios.json`

#### 2.2 JSON schema（所有 eval_research 文件遵循）

```json
{
  "generated_at": "YYYY-MM-DD",
  "skill_domain": "...",
  "agent_type": "literature-research | frontier-impl-analysis | tool-analysis | edge-cases | user-scenarios",
  "findings": [
    {
      "title": "具体标题",
      "source": "URL 或 会议/期刊名",
      "year": "YYYY",
      "key_finding": "1-3 句核心结论",
      "design_impact": "对本 Skill 设计的具体影响，或 'context_only'"
    }
  ],
  "top_insights": ["洞察1", "洞察2", "洞察3"],
  "suggested_eval_cases": [
    {
      "description": "建议的 eval case 描述",
      "source_title": "来源论文/文档标题",
      "dimension": "correctness | coverage | consistency",
      "expected_result": "pass | fail"
    }
  ]
}
```

#### 2.3 调研引用质量要求

每条调研发现必须有具体来源，包含以下之一：
- 论文标题（如 "DSPy: Compiling Declarative Language Model Calls..."）
- URL（如 arxiv.org/abs/2310.03714）
- 会议/期刊名（ICLR 2024、NeurIPS 2023 等）

「参考了相关研究」不算有效来源。

每个 eval_research JSON 文件必须包含 **≥2 条真实发现**（非 TODO 占位，不足为 **fail**）。

#### 2.4 调研影响矩阵（写入 genesis.md）

| 调研发现 | 来源（具体标题/URL） | 影响的设计决策 |
|---------|---------|--------------|
| [发现1] | [具体标题/URL] | [影响了Step X/架构选择Y] |

至少 5 行，每行来源必须具体可查；其中 ≥3 行须含 URL/年份/会议名。

#### 2.5 参考卡片生成（强制，准出标准）

**所有 eval_research findings 中 `design_impact ≠ context_only` 的文献**必须使用 `tools/gen_ref_card.sh` 生成结构化参考卡片，存入 `evolve_history/v0/assets/references/`。
此外，eval_research 中 `design_impact = context_only` 但被 genesis.md 调研影响矩阵引用的文献也必须生成参考卡片。

**最低要求（validate_structure.sh 强制检查）**：
- `assets/references/` 下参考卡片数 ≥ 所有 eval_research JSON 中 `design_impact ≠ context_only` 的 findings 总数
- 绝对数量 ≥ 3 张
- 每张卡片命名规范：`ref_{作者姓}_{年份}_{关键词}.md`（大小写不限）
- 每张卡片必须包含 frontmatter：`summary`、`type`、`relevance` 字段，以及 `**Verified**: yyyy-mm-dd`

Step 7 和 Step 9 的准出验收均需检查此目录是否满足上述要求。跳过参考卡片生成视为 **fail**，不允许进入 ship 阶段。

---

### Step 3: 设计 SKILL.md
**输入**：需求 + 调研结果 + Step 0 目标定义
**输出**：`{skill-name}-v0/SKILL.md`

**首先运行目录骨架生成器**（创建所有必需的占位文件）：

```bash
bash tools/scripts/gen_skill_dir.sh <skill-name> v0
```

1. SKILL.md frontmatter **只允许两个字段**：`name` 和 `description`
2. SKILL.md frontmatter 的 `description` 必须包含领域核心词汇（来自 Step 0 词汇表）
3. 正文是给 Claude 的可执行指令，不是给人类读的文档
4. 指令中引用同目录的 process.md，不要把流程内联
5. 明确告诉 Claude 用什么工具（Read/Write/Bash/Glob 等）完成任务
6. SKILL.md 包含「目标上下文」段落——引用 Step 0 的成功定义和领域词汇表
7. SKILL.md 包含「失败模式」段落——引用 Step 0 的 2-3 个失败场景
8. SKILL.md 包含「**能力边界**」段落
9. SKILL.md 包含「**核心约束**」段落
10. SKILL.md 必须包含触发指令和 `$ARGUMENTS` 处理

---

### Step 3.5: 设计进化路径
**输入**：需求分析（Step 1）+ 调研结果（Step 2）+ Step 0 失败模式
**输出**：`{skill-name}-v0/self-bootstrap.md` + `evolve_history/v0/target_point.md`

1. **定义"更好"**：基于 Step 1 的进化维度，写出 ≥2 个可量化的改进方向
2. **填写 `evolve_history/v0/target_point.md`**（validate_structure.sh 强制）：
   - **目标/Goal**：本轮攻克的核心问题
   - **瓶颈/Bottleneck**：为什么现有方案（裸 LLM）不够好
   - **放弃的替代点**：被否决的设计替代方案（≥1 条，不可留空）
3. **设计 expected-fail eval cases**：Step 4 中的 fail cases 必须关联到上述改进方向
4. **生成 self-bootstrap.md**，包含：
   - 自举触发条件（何时应该尝试 v1）
   - Phase 1-7（自我评估 → 准出文档）
   - Phase 6（见 terminal_test.md）产出的 skill eval 必须含 `judge_calibration` 断言

---

### Step 4: 设计评测集（失败模式优先 + 领域特异性强制）
**输入**：SKILL.md + Step 0 的失败模式 + Step 1 的进化维度 + eval_research JSON 的建议 case
**输出**：`{skill-name}-v0/evals/objective_cases.yaml` + `eval_protocol.md`

这是最重要的步骤（白皮书 1.2：「评测集比 Skill 本身更有价值」）。

#### 从失败模式出发设计 eval

**eval 设计的正确顺序**：
1. 取出 Step 0 定义的 2-3 个失败模式
2. 对每个失败模式问：「什么断言能自动检测到这种失败？」
3. 设计 **fail case**：这个场景下 Skill 会失败，断言能检测到
4. 设计对应的 **pass case**：成功场景下，相同结构的断言通过

**断言类型及区分力**：

| 断言类型 | 区分力评估 |
|---------|-----------|
| 只检查文件存在（file_exists）| 无区分力 |
| contains 通用词 | 弱区分力 |
| contains 领域特有词汇 | 中等区分力 |
| `run_script`：执行 shell 脚本验证行为 | 强区分力 |
| `invoke_skill`：调用 LLM 验证输出语义 | 强区分力 |
| `invoke_skill_judge`：LLM-as-judge 评判语义质量 | 最强区分力 |
| `judge_calibration`：验证 judge_prompt 本身的区分力 | meta-oracle |

**评测集最低要求**：
- **至少 10 条用例（≥4 pass, ≥4 fail）**（validate_evals.sh 强制检查）
- **每个 `.step0.yaml` 失败模式（failure_mode）必须有 ≥1 专属 fail case + ≥1 对应 pass case**（validate_evals.sh 检查 `failure_mode_id` 字段覆盖率，缺失为 **fail**）
- 每条 fail case 附带 `evolution_direction`（≥15 字符）且关联 `failure_mode_id`（来自 `.step0.yaml`）
- ≥5 条 case 包含 `gsb_baseline` 字段
- **三个维度（correctness/coverage/consistency）各至少有 2 条 case**（validate_evals.sh 强制）
- 非 `human_designed` 的 case ≥ 5 条
- `source: frontier_paper` case ≥ 3 条
- **eval 中必须包含 ≥1 条 `run_script` 断言**
- **eval 中必须包含 ≥1 条 `invoke_skill` 断言**
- **eval 中必须包含 ≥1 条 `invoke_skill_judge` 断言**
- **eval 中必须包含 ≥1 条 `judge_calibration` 断言（含 good_example + bad_example）**

> **覆盖率强制原则**：eval cases 数量 = 覆盖广度的下限，不是目标。每条 case 必须对应一个具体失败场景或领域边界，不接受「补数量」的通用 case。设计时先列出所有 Step 0 失败模式 + Step 3.5 进化方向，然后逐一配对 case，最后检查有无遗漏的领域边界场景。

---

### Step 4.5: Preflight 验证
**输入**：设计好的 eval cases + 初步的 SKILL.md/process.md
**输出**：`evolve_history/v0/attempts/attempt-001/preflight.json`

在进入完整 eval 之前，先用 1-3 条核心 sanity case 快速验证方案「至少奏效」：

```json
{
  "attempt_id": "attempt-001",
  "timestamp": "YYYY-MM-DD",
  "sanity_cases_run": ["case_id_1", "case_id_2"],
  "results": {
    "case_id_1": {"passed": true, "evidence": "..."},
    "case_id_2": {"passed": true, "evidence": "..."}
  },
  "verdict": "proceed | abort",
  "abort_reason": "如果 abort，说明为什么不值得继续完整 eval"
}
```

---

### Step 5: 编写 manifest.yaml
按白皮书 §2.2 + scaffold.md §manifest 规范，必须包含所有字段：
`name`, `family`, `version`, `status`, `bootstrap_completed`, `bootstrap_target`,
`creator_version`, `parent_version`, `auto_upgrade_policy`, `latest_alias`,
`type`, `bootstrap_status`, `capabilities`, `federation_protocol`, `whitepaper_ref`

---

### Step 6: 编写创世记录
**输出**：`{skill-name}-v0/evolve_history/v0/genesis.md`

必须包含（validate_structure.sh 强制，缺失为 **fail**）：
1. 假设；2. 方法；3. 被否决方案；4. 已知局限；5. 未来方向；6. **调研影响矩阵**（来自 Step 2.4）；7. **独立评估框架**

---

### Step 7: 验收
1. 运行 `tools/validate.sh <skill-dir>` 执行全量自动化检查
2. 审查所有 `✗ FAIL` 项必须修复
3. **手动检查 - 参考卡片**：核查 `evolve_history/v0/assets/references/` 下卡片数是否满足 Step 2.5 最低要求；若有遗漏，补齐后继续
4. **手动检查 - eval 覆盖率**：对照 `.step0.yaml` 中每个 `failure_mode.id`，确认 `objective_cases.yaml` 中有对应的 fail case + pass case；缺失则补充，不可跳过
5. **手动检查**：逐条检查 eval case 的 `contains` 断言值，确认包含领域特有词汇
6. **执行 eval（必须实际运行，不接受预测值）**：
   ```bash
   bash tools/scripts/run_eval.sh <skill-dir>
   ```
   将输出保存到 `evolve_history/v0/attempts/attempt-001/eval_report.json`
7. 执行 blind eval：
   ```bash
   bash tools/scripts/run_blind_eval.sh <skill-dir> <case-id> --record evolve_history/v0/attempts/attempt-001/
   ```
8. 填写 `verdict.json`，引用实际执行的输出文件
9. **eval fail 时的修复协议（禁止直接改代码）**：

   当 eval_report.json 中有 fail case 时，**必须**先执行以下步骤再修复：

   ```yaml
   # 必须先填写，再开始修复
   problem_statement:
     fail_case_id: "失败的 case id"
     observed_behavior: "实际输出是什么（现象，不是方案）"
     expected_behavior: "eval 期望的输出是什么"
     root_cause_hypothesis: "初步判断根本原因（≥15 字，不可是方案描述）"
     problem_type: "覆盖不足 / 结构错误 / 语义偏差 / 执行失败 / 其他"
   ```

   然后执行**问题型调研**（参见 self-bootstrap.md Phase 2.P）：
   - 用 `problem_type` 和 `root_cause_hypothesis` 生成搜索词
   - 搜索 ≥3 篇相关文献，评估 `frontier_coverage`
   - `frontier_coverage: solved / partial` → 采纳前沿方案修复
   - `frontier_coverage: none`（≥3 篇均 none）→ 才允许自研修复
   - 修复后在 genesis.md 调研影响矩阵中记录 `design_source` 字段

   **直接改 SKILL.md/process.md 而不经此步骤 = 闭门造车，视为流程违规。**

10. **等待用户确认**

---

### Step 8: 编写 Article（arxiv 水准文档）⭐准出必须，不可省略
**输出**：`evolve_history/v0/article/`

按 scaffold.md §Article 规范执行。Article 必须可独立阅读。validate_article.sh + `article_arxiv_invoke_skill_judge` eval case 联合验收。

#### 8.1 结构要求（validate_article.sh 强制）

- 7 个强制节：Abstract / Introduction / Related Work / Design / Evaluation / Discussion / Conclusion
- Related Work ≥10 篇；**每篇必须有差异定位句**（"本工作与之的区别/继承是……"），只描述论文本身为 **fail**
- 总词数 8,000-12,000
- Discussion 必须包含 `### Limitations` 子节，每项局限含量化描述（%, case 数, 具体场景）

#### 8.2 贡献可检验性（三要素，每条 contribution 必须满足）

每条 contribution 必须包含：

1. **`failure_mode_prevented`**：不做这件事时会发生什么具体故障——现象级描述，不是"质量下降"
2. **`applicable_boundary`**：此贡献在什么条件下成立、在什么条件下失效（至少说明 1 个失效边界）
3. **`verifiable_instance`**：至少 1 个具体实例，说明它抓住了 baseline（裸 LLM 或缺少此机制的旧版本）会漏掉的真实问题

**示例**（judge_calibration 的正确写法）：
> - *failure_mode_prevented*：judge_prompt 过宽时，bad_example 被判为 PASS，导致所有 invoke_skill_judge 结论失真，改进方向全部基于错误信号——在无 calibration 版本中，过宽的 judge 被发现接受"genesis notes: built on general principles"为高质量 genesis，系统性误报 83% 的低质量输出为合格。
> - *applicable_boundary*：适用于单维度、有明确 good/bad 参考样本可以人工构造的判断任务；不适用于多维度权衡或无法事先定义 bad_example 的开放生成任务。
> - *verifiable_instance*：运行 `run_eval.sh --case judge_calibration_validates_code_reviewer_prompt`，对比加/不加 calibration 的 judge 在相同 bad_example 上的 verdict。

不接受只有主张、没有三要素的贡献描述。

#### 8.3 实验证据或 Planned Experiments（二选一，必须有其一）

**有真实实验时**：Evaluation 节提供对照结果表格，至少包含 full system vs. baseline（裸 LLM）两条，跨 ≥2 个 domain，每个条件 ≥5 次任务。

**无真实实验时**（如 v0 genesis）：Evaluation 节必须包含 `### Planned Experiments` 子节，格式要求：

```yaml
ablation_design:
  name: "描述实验名称"
  motivation: "为什么这个对照能证明贡献价值"
  domains:           # 至少 2 个，来自不同领域
    - name: "domain_A"
      rationale: "选择理由"
  tasks_per_condition: 5   # 最小值
  conditions:
    - label: "full system"
    - label: "ablate X"    # 去掉待验证贡献 X
    - label: "ablate Y"
    - label: "bare LLM baseline"
  metrics:
    - name: "pass_rate"
      measurement: "run_eval.sh 通过率"
    - name: "GSB_G_ratio"
      measurement: "blind eval Good 占比"
    - name: "evolution_direction_actionability"
      measurement: "fail case 的 evolution_direction 能否定位到具体 step（人工评分 1-5）"
  success_criterion: "full system 在所有 metrics 上 ≥ baseline，至少 1 项绝对差值 ≥10%"
  blocking_for_v1: true   # 此实验是 v1 准出的必要条件
```

Planned Experiments 必须写得足够具体，让第三方可以直接按此运行，不需要额外澄清。

#### 8.4 可复现性说明（必须包含）

Article 必须包含 `### Reproducibility` 子节（置于 Evaluation 或 Discussion），说明：

1. **复现核心声明的最小命令序列**——从克隆仓库到得到 eval report 的完整步骤
2. **Fixtures 位置与状态**——现有 fixture 在哪里；若尚未公开，标注 `status: planned` 并说明需要什么条件才能公开
3. **LLM 依赖说明**——哪些 eval cases 需要真实 LLM 调用（如 judge_calibration），建议的执行环境

```bash
# 最小复现示例格式
git clone <repo> && cd <skill-dir>
bash tools/validate.sh . --ship          # 结构验证
bash tools/scripts/run_eval.sh .         # eval（LLM cases 在嵌套 session 中 skip）
# standalone session 中运行以下获得完整 eval：
bash tools/scripts/run_eval.sh . --all-assertions
```

---

### Step 9: 编写准出文档⭐准出必须，不可省略
**输出**：`evolve_history/v0/evolution.md` + `evolve_history/v0/comparison.md` + `evolve_history/v0/summary.md`

1. **`evolution.md`**：必须包含四节：现状评估（量化）、不足分析、Top 3 优化建议（每条含四要素）、依赖分析
2. **`comparison.md`**：对比表格 + 已知代价/Trade-offs 节
3. **`summary.md`**：状态 / 攻克的优化点 / eval 通过率 / 相比上版本的提升 / 已知局限
4. **最终验收**：
   ```bash
   bash tools/validate.sh <skill-dir> --ship
   ```

---

### Step 10: 创建 attempt 追踪记录
**输出**：`evolve_history/v0/attempts/attempt-001/`

每次创建 v0 算作 attempt-001，需要留下 7 个文件：
```
attempts/attempt-001/
├── hypothesis.md           # 本次想验证什么（target_point / 假设 / 预期证据 三字段）
├── diff.md                 # 相对于「裸 LLM 直接创建」做了哪些具体改进
├── preflight.json          # Step 4.5 sanity check（execution_status: "actual"）
├── eval_report.json        # run_eval.sh 产出（execution_status: "actual"，非预测）
├── blind_eval_report.json  # run_blind_eval.sh 产出（execution_status: "actual"，非预测）
├── stress_report.json      # 压力测试实际执行结果
└── verdict.json            # 综合判定（verdict ∈ {pass, fail, pending}）
```

---

## 流程约束

- 步骤顺序不可跳过，但可根据 Skill 复杂度调整每步深度
- 用户确认点：Step 1 后（需求）、Step 7 后（验收）
- Step 0、Step 2、Step 3.5、Step 4.5 不可省略
- domain 类型必须有 Step 8 Article；utility/infrastructure 类型 Article 可简化但不可省略
- 每次创建都必须产出 `evals/eval_research/` 下的 5 个 JSON 文件
- 所有 case 必须有 `target_point` 和 `regression_level` 字段
- eval 中必须包含 ≥1 条 `invoke_skill_judge` 断言
- eval 中必须包含 ≥1 条 `judge_calibration` 断言（含 good_example + bad_example）
- P2 归档 case 必须有 `superseded_by` 字段

## ⚠️ 反奖励作弊原则（自举时必读）

**禁止行为**：
- 将 expected_fail 改为 expected_pass，除非提供实际执行输出作为 `evidence`
- 修改历史 fail case 的断言使其变宽松（违反 only-increase 精神）
- 新增 eval case 断言值只用通用词，回避真正的领域质量检验
- 跳过 preflight 直接宣称 eval 通过
- sub-agent 调研只列标题，不产出实质性 JSON 内容

**必须遵守**：
- 所有 fail→pass 变化必须在 genesis.md 中附带 `evidence` 字段
- 引入外部来源（`frontier_paper`）的 eval cases，降低自设评测比例（≥3 条）
- **终极检验**：自举后必须按 `terminal_test.md` 的要求，以 knowledge-crystallizer 为外部锚点推进落地，由用户独立评估
- **单点攻破**：每次自举只攻一个优化点，确保因果可解释
- **真实 eval**：eval_report.json 必须来自真实执行，不接受 mock 通过
