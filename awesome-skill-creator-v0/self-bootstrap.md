# awesome-skill-creator 自举协议 v0

> **内置约束**（七代积累，v0 原生）：
> 1. **judge_calibration 断言必须**：每次自举产出的 eval 中必须包含 ≥1 条 `judge_calibration` 断言（含 good_example + bad_example）
> 2. **P2 归档规范**：P2 case 必须有 `superseded_by` 字段；validate_evals.sh 校验引用完整性
> 3. **终极检验含 judge_calibration**：Phase 6（见 terminal_test.md）产出的 skill eval 必须包含 judge_calibration 断言
> 4. **invoke_skill_judge 断言 ≥1 条**（LLM-as-judge 语义评判）
> 5. **invoke_skill 断言 ≥1 条**
> 6. **run_script 断言 ≥1 条**
> 7. **.step0.yaml 强制**
> 8. **单一数据源**（evals/objective_cases.yaml）

## 触发条件

当满足以下任一条件时，执行自举：
- 当前版本的 eval 通过率 ≥ 85%，且有 ≥2 条 fail case 指向明确改进方向
- 用户明确要求升级到 v1
- 发现系统性设计缺陷，需架构级修复

## 自举前准备

```bash
# 确认当前版本和目标版本
CURRENT_VERSION=v0
TARGET_VERSION=v1
CURRENT_DIR="awesome-skill-creator-v0"
TARGET_DIR="awesome-skill-creator-v1"
```

---

## Phase 1: 自我评估

**目标**：客观测量当前版本能力边界

### 1.1 运行全量 eval

```bash
tools/validate.sh awesome-skill-creator-v0/ --ship
```

记录：
- 总 eval 数
- pass 数 / fail 数
- 每条 fail case 的 `evolution_direction`

### 1.2 收集 fail→pass 候选

列出所有 `expected_result: fail` 的 case：
- 评估每条 case 的可修复性（1-5 分）
- 确定本次自举的目标 case 集合（建议 2-4 条）

### 1.3 定义本次进化方向

基于 fail case 的 `evolution_direction`，明确：
1. **核心问题**：当前版本最根本的能力缺口是什么？
2. **进化假设**：「如果我们做 X，则 case Y 会从 fail 变 pass」
3. **成功标准**：本次自举完成后，eval 通过率应从 N% 提升到 M%

---

## Phase 2: 前沿调研（每次自举必须执行，模式二选一）

**核心原则：先判断调研模式，再执行对应流程。混用两种模式会导致探索型调研带预设方案、问题型调研脱离目标。**

---

### 2.0 判断调研模式

| 触发来源 | 模式 | 目标 |
|---------|------|------|
| Phase 1 发现 eval fail case，有具体失败原因 | **问题型（P）** | 找前沿是否已解决该具体问题；前沿有解用前沿，无解才自研 |
| 当前版本稳定，想探索 v{N+1} 的可能方向 | **探索型（E）** | 发现领域机会，拓宽视野，识别 gap |

在 genesis.md 中记录本次模式选择：`research_mode: P | E`

---

### 2.P 问题型调研流程（eval fail 驱动）

> 参考：Kitchenham & Charters (2007) PICOC 框架——搜索之前先把问题陈述标准化，否则无法评估搜索结果的相关性。

#### 2.P.1 问题陈述（PICOC，强制，搜索之前完成）

```yaml
problem_statement:
  population: "本 Skill 处理的对象是什么"
  intervention: "eval 失败的具体行为是什么（不是方案，是现象）"
  comparison: "裸 LLM 或旧版本的行为是什么"
  outcome: "我们期望的可量化改善是什么"
  context: "这个问题在什么场景下出现（不是所有场景）"
  problem_type: "分类问题 / 序列生成问题 / 评估偏差 / 覆盖不足 / 其他"
```

**禁止**：在填写 problem_statement 之前开始搜索。带预设方案搜索等于文献验证，不是调研。

#### 2.P.2 精准搜索（基于 problem_statement）

从 `intervention` 和 `problem_type` 提取搜索词，每次搜索必须与 problem_statement 直接相关：

```
WebSearch: "{problem_type 关键词} solution arxiv"
WebSearch: "{intervention 现象} failure mode LLM"
WebSearch: "{outcome 关键词} benchmark 2023 2024"
```

#### 2.P.3 前沿可用性判定（写入 genesis.md）

对每篇搜索结果，评估：`frontier_coverage: solved | partial | none`

```yaml
frontier_findings:
  - title: "具体论文标题"
    url: "arxiv URL 或 DOI"
    frontier_coverage: solved | partial | none
    applicable_to: "与 problem_statement 中哪个字段对应"
    adoption_decision: "采纳 / 部分采纳 / 不采纳"
    adoption_reason: "原因（≥15 字）"
```

**决策规则（强制）**：
- `frontier_coverage: solved` → **必须采纳**，记录 `design_source: frontier_paper`
- `frontier_coverage: partial` → 采纳可用部分 + 自研补充，记录 `design_source: frontier_adapted`
- `frontier_coverage: none`（需 ≥3 篇结果均为 none）→ 允许自研，记录 `design_source: self_invented`，并注明"无先例"

**`design_source: self_invented` 是最后手段，不是默认选项。**

#### 2.P.4 最低调研数量
- ≥ 5 篇相关论文/文档（全部与 problem_statement 直接相关）
- 覆盖 ≥ 2 个不同研究机构/团队
- 允许无综述，但需包含 ≥ 1 篇引用量 > 50 的工作（防止只搜到边缘研究）

---

### 2.E 探索型调研流程（版本进化方向发现）

#### 2.E.1 确定调研范围

基于当前版本的已知局限（genesis.md `已知局限` 节），定义 ≥3 个候选方向关键词：

示例（v0 → v1 探索，方向：step-level judge）：
- `"step-level reward model LLM evaluation"`
- `"process reward model language model"`
- `"LLM evaluation granularity survey"`

#### 2.E.2 宽泛搜索

```
WebSearch: "{方向关键词} arxiv survey"
WebSearch: "{方向关键词} best practices 2024"
WebSearch: "{方向关键词} state of the art"
```

**最低调研数量**：
- ≥ 5 篇相关论文/文档
- 覆盖 ≥ 2 个不同研究机构/团队
- 包含 ≥ 1 篇综述性论文

#### 2.E.3 Gap Analysis（产出进化候选列表）

```yaml
gap_analysis:
  - direction: "方向名称"
    current_gap: "当前版本的不足"
    frontier_state: "学术前沿的解法现状"
    adoption_difficulty: low | medium | high
    expected_impact: "对 eval 通过率或领域质量的预期影响"
```

从中选出本次自举的 `target_point`（单点攻破原则）。

---

### 2.共 调研影响矩阵（两种模式均需，写入 genesis.md）

| 论文/来源 | 核心发现 | design_source | 对自举设计的影响 |
|---------|---------|--------------|----------------|
| [具体标题/URL] | [1-2 句] | frontier_paper \| frontier_adapted \| self_invented | [影响了 Phase X / 决策 Y] |

**至少 5 行，每行来源必须具体可查；`design_source` 字段必须填写。**

---

## Phase 3: 设计变更方案

**目标**：基于 Phase 2 调研，设计具体的改进措施

### 3.1 每个目标 case 的修复方案

```markdown
Case: {case_id}
当前失败原因：{具体分析}
修复方案：{process.md/SKILL.md/scaffold.md 的具体变更}
关联论文证据：{支持此方案的调研发现}
预期 evidence：{执行后可验证的具体输出描述}
```

### 3.2 副作用评估

- 此变更是否影响已有 pass case？（如果是，需要 only-increase 处理）
- 此变更是否引入新的复杂度？

---

## Phase 4: 实施变更

**目标**：执行 Phase 3 的方案

执行顺序（严格遵守）：
1. **先改 process.md**（核心流程变更）
2. **再改 SKILL.md**（入口引用更新）
3. **再改 scaffold.md**（结构标准更新）
4. **再更新 evals**（添加新 case，不修改已有 case）
5. **最后更新 manifest.yaml**（版本号、capabilities 等）

### 4.1 Only-Increase 约束

**绝对禁止**：
- 删除任何历史 eval case
- 修改历史 fail case 的断言使其变宽松
- 将 `expected_result: fail` 改为 `pass`，除非同时附 `evidence` 字段

---

## Phase 5: 验证变更（evidence 要求）

**目标**：证明 fail→pass 变化有实际执行证据支持

### 5.1 对每条 fail→pass 的 case

**必须提供 evidence 字段**：

```yaml
evidence:
  type: execution_output    # execution_output | file_content | test_result
  description: "执行了 X，得到 Y，证明 case 的断言现在满足"
  verified_at: "YYYY-MM-DD"
```

**不可接受的 evidence**：
- 「已在 process.md 中描述了此能力」（文字宣称，非执行证据）
- 「logic seems correct」（推理，非执行证据）

### 5.2 运行验证脚本

```bash
tools/validate.sh awesome-skill-creator-v1/ --ship
```

所有 `✗ FAIL` 必须修复；`⚠ WARN` 不阻断准出，但需知晓并酌情处理。

---

## Phase 6: 终极检验（不可跳过）

**目标**：打破自举闭环——eval 和创建过程均由 skill-creator 自身设计，存在系统性偏差风险。终极检验是唯一的外部锚点。

### 6.1 选择终极检验对象（固定）

终极检验对象固定为：`terminal_test.md` 中定义的 knowledge-crystallizer。

**⭐ 要求**：最终产出的 knowledge-crystallizer skill 的 eval 中必须包含 `judge_calibration` 断言（含 good_example + bad_example）。验收时运行 `validate_evals.sh` 确认 judge_calibration ≥1 条（详见 terminal_test.md）。

### 6.2 用新版本推进/产出该 Skill

严格按该项目的 `project_plan` 约束 + 新版本的 process.md 执行，**不可提前预知用户如何评估**。

### 6.3 用户独立评估

| 维度 | 评估问题 | 分值（1-5） |
|------|---------|-----------|
| 目标导向 | process.md 的步骤是否明确指向解决领域问题，而非只产出文件？ | /5 |
| 领域特异性 | 生成的 Skill 内容是否包含该领域的专有知识，还是通用模板？ | /5 |
| Eval 区分力 | Eval cases 是否能区分好的该领域 Skill 和坏的？ | /5 |
| 可执行性 | 生成的 Skill 是否可立即被 Claude Code 执行？ | /5 |

**合格标准**：四个维度总分 ≥ 14/20，且无单维度 ≤ 2

### 6.4 记录终极检验结果

将评估结果记录在 `genesis.md` 的「独立评估」章节。

---

## Phase 7: 准出文档

**目标**：完成全部准出交付物

### 7.1 genesis.md（`evolve_history/v1/genesis.md`）

必须包含：假设、方法、被否决方案、已知局限、未来方向、调研影响矩阵、Evidence 字段、独立评估

### 7.2 Article（`evolve_history/v1/article/`）

按 scaffold.md 规范，8000-12000 词，包含：
- 完整的论文引用（来自 Phase 2 的调研）
- Evaluation 章节中的 GSB 分析
- Discussion 中的 Limitations 独立小节
- `evolve_history/v1/assets/references/` 中所有引用文献的参考卡片

### 7.3 Evolution 文档（`evolve_history/v1/evolution.md`）

包含量化评估和 Top 3 进化方向。

### 7.4 最终验收

```bash
tools/validate.sh awesome-skill-creator-v1/ --ship
```

全部通过后，更新 manifest.yaml 的 `bootstrap_status`。

---

## 反奖励作弊检查单

在 Phase 5 之前，对照以下清单自检：

- [ ] 没有删除任何历史 eval case
- [ ] 没有修改历史 fail case 使其变宽松
- [ ] 所有 fail→pass 都附有具体的 `evidence` 字段
- [ ] 新增的 eval case 断言值包含领域特有词汇（不是通用词）
- [ ] Phase 2 已判断调研模式（P / E），并在 genesis.md 记录 `research_mode`
- [ ] 问题型（P）：problem_statement（PICOC）在搜索之前完成，不含方案预设
- [ ] 问题型（P）：每篇搜索结果有 `frontier_coverage` 和 `adoption_decision` 字段
- [ ] 问题型（P）：`design_source: self_invented` 的决策有 ≥3 篇 frontier_coverage=none 的文献为据
- [ ] Phase 2 调研包含 ≥5 篇论文，且来源具体可查
- [ ] 调研影响矩阵每行含 `design_source` 字段
- [ ] Phase 6 终极检验已执行（不是跳过）
- [ ] genesis.md 中包含「独立评估」章节
- [ ] eval 包含 ≥1 条 `invoke_skill_judge` 断言
- [ ] eval 包含 ≥1 条 `judge_calibration` 断言（含 good_example + bad_example）
- [ ] Phase 6（见 terminal_test.md）产出的 skill eval 中含 `judge_calibration` 断言
- [ ] P2 归档 case 均有 `superseded_by` 字段
