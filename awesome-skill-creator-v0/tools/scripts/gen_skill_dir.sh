#!/usr/bin/env bash
# gen_skill_dir.sh — Generate a Skill directory skeleton per scaffold.md
# Usage: gen_skill_dir.sh <name> <version> [output-dir]
# Example: gen_skill_dir.sh my-skill v0
# Example: gen_skill_dir.sh my-skill v0 .tmp/    # place inside .tmp/ (gitignored)

set -euo pipefail

NAME="${1:?Usage: gen_skill_dir.sh <name> <version> [output-dir]}"
VERSION="${2:?Usage: gen_skill_dir.sh <name> <version> [output-dir]}"
OUTPUT_DIR="${3:-.}"   # default: current directory

# Validate inputs
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: name must be lowercase alphanumeric with hyphens (e.g., 'my-skill')"
  exit 1
fi

if [[ ! "$VERSION" =~ ^v[0-9]+$ ]]; then
  echo "Error: version must match v{N} pattern (e.g., 'v0')"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
DIR="${OUTPUT_DIR%/}/${NAME}-${VERSION}"
VER_NUM="${VERSION#v}"

if [[ -d "$DIR" ]]; then
  echo "Error: directory '$DIR' already exists"
  exit 1
fi

echo "Creating Skill skeleton: $DIR/"

# Create directories
mkdir -p "$DIR/evals/eval_research"
mkdir -p "$DIR/evolve_history/${VERSION}/attempts/attempt-001"
mkdir -p "$DIR/evolve_history/${VERSION}/assets/references"
mkdir -p "$DIR/locks"
mkdir -p "$DIR/tools/gate"
mkdir -p "$DIR/tools/scripts"

# Lock files (whitepaper §2.5 — modified during promotion flow)
touch "$DIR/locks/evolve.lock"
touch "$DIR/locks/promote.lock"
touch "$DIR/locks/register.lock"

# .skillignore — defines distribution exclusions (scaffold.md §Distribution)
cat > "$DIR/.skillignore" << 'SKILLIGNORE_EOF'
# .skillignore — files excluded from distribution packages (gen_dist.sh respects this)
#
# Distribution tiers (tools/gen_dist.sh):
#   runtime  → SKILL.md, process.md, manifest.yaml, .step0.yaml,
#               self-bootstrap.md, scaffold.md, locks/ (reset)
#   quality  → runtime + evals/, tools/
#
# Build artifacts: research history, attempts, articles — NOT for distribution
evolve_history/
version_history/
.tmp/
SKILLIGNORE_EOF

# Eval research JSON stubs (filled by Step 2 sub-agents)
# Each file has required schema: generated_at, skill_domain, agent_type, findings, top_insights, suggested_eval_cases
for json_file in literature_review frontier_impls tool_analysis edge_cases user_scenarios; do
  case "$json_file" in
    literature_review) atype="literature-research" ;;
    frontier_impls)    atype="frontier-impl-analysis" ;;
    tool_analysis)     atype="tool-analysis" ;;
    edge_cases)        atype="edge-cases" ;;
    user_scenarios)    atype="user-scenarios" ;;
  esac
  cat > "$DIR/evals/eval_research/${json_file}.json" << EOF
{
  "generated_at": "$(date +%Y-%m-%d)",
  "skill_domain": "TODO: ${NAME} domain description",
  "agent_type": "${atype}",
  "findings": [
    {
      "title": "TODO: Finding title",
      "source": "TODO: URL or Conference/Journal name",
      "year": "TODO",
      "key_finding": "TODO: 1-3 sentence core conclusion",
      "design_impact": "TODO: Specific impact on this Skill design, or context_only"
    }
  ],
  "top_insights": [
    "TODO: Key insight 1",
    "TODO: Key insight 2",
    "TODO: Key insight 3"
  ],
  "suggested_eval_cases": [
    {
      "description": "TODO: Suggested eval case based on findings",
      "source_title": "TODO: Source paper/document title",
      "dimension": "correctness",
      "expected_result": "pass"
    }
  ]
}
EOF
done

# .step0.yaml stub (filled by Step 0)
cat > "$DIR/.step0.yaml" << STEP0_EOF
skill_name: ${NAME}-${VERSION}
created_at: $(date +%Y-%m-%d)
success_definition: "TODO: Define what success looks like for this Skill"
failure_modes:
  - id: "{TODO: failure-mode-A}"
    description: "{TODO: Common failure mode 1}"
    eval_detection: "{TODO: which eval case id catches this failure}"
  - id: "{TODO: failure-mode-B}"
    description: "{TODO: Common failure mode 2}"
    eval_detection: "{TODO: which eval case id catches this failure}"
  - id: "{TODO: failure-mode-C}"
    description: "{TODO: Common failure mode 3}"
    eval_detection: "{TODO: which eval case id catches this failure}"
domain_vocab:
  - "TODO: domain-specific term 1"
  - "TODO: domain-specific term 2"
STEP0_EOF

# attempt-001 execution artifacts (filled during Step 7 evaluation)
cat > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/hypothesis.md" << 'HYP_EOF'
# Attempt-001 Hypothesis

**target_point**: {TODO: single optimization point this attempt validates}

**假设 (Hypothesis)**: {TODO: if we do X, then Y will happen because Z}

**预期证据 (Expected Evidence)**: {TODO: which eval case(s) should pass/fail to confirm this}

## Expected Outcome

{TODO: What do we expect to happen, and how will we measure it?}
HYP_EOF

cat > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/diff.md" << 'DIFF_EOF'
# Attempt-001 Diff

## 与基线的具体改动

{TODO: 相比「裸 LLM 直接创建」，本次使用 skill-creator 做了哪些具体改进？}

### 新增 / 修改

- {TODO: 列出每项关键设计决策和对应文件修改}

### 未做（及理由）

- {TODO: 考虑过但放弃的方案，说明原因}
DIFF_EOF

echo '{"attempt_id": "attempt-001", "timestamp": "TODO", "execution_status": "pending", "sanity_cases_run": [], "results": {}, "verdict": "pending", "abort_reason": null}' \
  > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/preflight.json"
echo '{"execution_status": "pending", "TODO": "Replace with actual run_eval.sh output"}' \
  > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/eval_report.json"
echo '{"execution_status": "pending", "TODO": "Replace with actual run_blind_eval.sh output"}' \
  > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/blind_eval_report.json"
echo '{"attempt": "001", "execution_status": "pending", "run_date": "TODO", "status": "pending", "stress_scenarios": []}' \
  > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/stress_report.json"
echo '{"attempt_id": "attempt-001", "verdict": "pending", "evidence": {"TODO": "Fill in after evaluation — reference preflight.json/eval_report.json/blind_eval_report.json/stress_report.json results"}}' \
  > "$DIR/evolve_history/${VERSION}/attempts/attempt-001/verdict.json"

# Evolve history doc stubs
cat > "$DIR/evolve_history/${VERSION}/summary.md" << 'SUM_EOF'
# {skill-name} {version} 版本摘要

- **状态**：draft
- **攻克的优化点**：{TODO: single optimization point this version targets}
- **eval 通过率**：{TODO: N/M}
- **相比上版本的提升**：{TODO: key improvements}
- **已知局限**：{TODO: known limitations}
SUM_EOF

cat > "$DIR/evolve_history/${VERSION}/target_point.md" << 'TP_EOF'
# Target Point

## Core Problem

{TODO: What problem does this Skill solve?}

## Success Criteria

{TODO: How will we know the Skill is working well?}

## Key Design Decisions

{TODO: Major design choices and rationale}
TP_EOF

cat > "$DIR/evolve_history/${VERSION}/comparison.md" << 'CMP_EOF'
# Comparison: Before vs After

## Without this Skill

{TODO: How was this task done before? What were the pain points?}

## With this Skill

{TODO: What does the Skill enable? What is easier/better?}

## Trade-offs

{TODO: What did we give up? What constraints did we accept?}
CMP_EOF

cat > "$DIR/evolve_history/${VERSION}/release_checklist.md" << 'CHKLIST_EOF'
# Release Checklist

## Objective Layer

- [ ] `validate.sh ${DIR}/ --ship` → 0 failures, 0 warnings
- [ ] `run_eval.sh ${DIR}/` → all executed cases pass

## Subjective Layer (Terminal Test)

- [ ] Created unfamiliar-domain Skill using this Skill
- [ ] User evaluated 4 dimensions, total score ≥14/20
- [ ] genesis.md updated with `**合格**: 是`
CHKLIST_EOF

# SKILL.md
cat > "$DIR/SKILL.md" << 'SKILL_EOF'
---
name: {TODO: skill-name-vN}
description: "{TODO: one-line description of this Skill}"
---

# {TODO: Skill Name}

You are a specialized Skill in the federation system.

## 目标上下文

- **成功定义**：{TODO: what does a successful output look like}
- **失败模式**：{TODO: common failure patterns this skill must avoid}
- **领域词汇表**：{TODO: 3-5 domain-specific terms that must appear in outputs}

## Mode Switching

- If `$ARGUMENTS` contains `--bootstrap` → read and execute `self-bootstrap.md`
- Otherwise → enter creation/execution mode

## Execution

1. Read `process.md` for workflow steps
2. Read `scaffold.md` (if exists) for structural standards
3. Read `../meta_whitepaper.md` for federation principles
4. Execute the defined workflow

## 能力边界

本 Skill 适用于：
- {TODO: primary use case}

本 Skill 不适用于：
- {TODO: explicit exclusions}

## 核心约束（不可绕过）

1. {TODO: hard constraint 1}
2. {TODO: hard constraint 2}

## Core Principles

1. v0 的价值 = "能启动进化"，而非"正确"
2. 评测集 > Skill 本身
3. Only-increase：历史用例永不删除/修改
4. 失败记录 > 成功记录
5. SSOT：引用代替抄写
SKILL_EOF

# process.md
cat > "$DIR/process.md" << 'PROCESS_EOF'
---
purpose: "Standardized workflow for {TODO: skill-name}"
---

# {TODO: Skill Name} Process

## Step 0: 目标定义（Goal-First）

**输入**：用户需求描述
**输出**：`.step0.yaml`（成功定义 + 失败模式 + 领域词汇）

{TODO: Define success, failure modes, and domain vocabulary for this Skill}

## Step 1: {TODO}

{TODO: Define first step with explicit input/output}

## Step 2: Sub-Agent 调研

**输入**：Step 0 目标定义（成功/失败/领域词汇）
**输出**：`evals/eval_research/*.json`（5 类结构化调研 JSON）

启动 5 类 sub-agent 并行调研：文献、前沿实现、工具分析、边界用例、用户场景。
每条发现必须有具体论文标题/URL/会议名，不接受「参考了相关研究」等模糊表述。

## Step 3: {TODO}

{TODO: Define third step with explicit input/output}

## Step 4: 设计评测用例

**输入**：Step 0 目标定义 + Step 2 调研结果
**输出**：`evals/objective_cases.yaml`（≥5 条；含 ≥2 fail、≥1 run_script、≥1 invoke_skill、≥1 invoke_skill_judge、≥1 judge_calibration）

{TODO: Design eval cases covering correctness/coverage/consistency dimensions}

## Step 5: 编写 Manifest

**输入**：设计完成的 Skill
**输出**：`manifest.yaml`（含所有必须字段）

{TODO: Fill manifest.yaml with name/family/version/status/capabilities etc.}

## Step 6: 编写创世记录

**输入**：设计过程和调研结果
**输出**：`evolve_history/v0/genesis.md`（含 假设/方法/被否决方案/已知局限/未来方向/调研影响矩阵）

{TODO: Write genesis.md with all required sections}

## Step 7: 验收

**输入**：完整 Skill 目录
**输出**：`evolve_history/v0/attempts/attempt-001/*.json`（eval_report / blind_eval_report 等）

1. 运行 `tools/validate.sh <skill-dir>` 自动检查
2. 修复所有 FAIL 项
3. 执行 eval（`bash tools/scripts/run_eval.sh <skill-dir>`）并记录结果

## Preflight: 快速验证

**输入**：当前实现
**输出**：`evolve_history/v0/attempts/attempt-001/preflight.json`

Run 2-3 core eval cases before full eval to validate basic functionality works.

## Attempt 追踪

**输出**：`evolve_history/v0/attempts/attempt-001/`（7 个文件，均来自实际执行）

每次创建或修改后在 attempt-001/ 留下记录：
- `hypothesis.md` — 本次想验证什么
- `diff.md` — 与基线的具体改动
- `preflight.json` — Preflight sanity check（execution_status: "actual"）
- `eval_report.json` — run_eval.sh 产出（execution_status: "actual"）
- `blind_eval_report.json` — GSB 对比结果（execution_status: "actual"）
- `stress_report.json` — 压力测试结果（execution_status: "actual"）
- `verdict.json` — 综合判定，引用以上文件

## Acceptance

- Run `tools/validate.sh` for automated checks
- Verify all assertions pass
- Confirm with user before delivery
PROCESS_EOF

# manifest.yaml
cat > "$DIR/manifest.yaml" << MANIFEST_EOF
name: ${NAME}-${VERSION}
family: ${NAME}
version: ${VERSION}
status: draft
bootstrap_completed: false
bootstrap_target: v1
creator_version: v7
parent_version: null
auto_upgrade_policy: all_ge_old_and_one_gt
latest_alias: ${NAME}
type: domain
bootstrap_status: genesis
capabilities:
  - "TODO: primary_capability"
federation_protocol: "2.0"
whitepaper_ref: "../meta_whitepaper.md"
created_at: "$(date +%Y-%m-%d)"
description: >
  TODO: Multi-line description of this Skill's purpose and scope
known_limitations:
  - "TODO: Known limitation 1"
MANIFEST_EOF

# evals/eval_protocol.md
cat > "$DIR/evals/eval_protocol.md" << 'EVAL_PROTO_EOF'
---
purpose: "Defines objective-layer test execution and validation rules"
---

# Evaluation Protocol

## Assertion Types

| Type | Required Fields | Description |
|------|----------------|-------------|
| file_exists | value | Check file presence |
| contains | value, target | Check content in file |
| not_contains | value, target | Ensure content absent |
| yaml_valid | target | Validate YAML syntax |
| yaml_field_equals | target, field, value | Check YAML field value |
| min_count | target, element, value | Minimum count check |
| structure_match | value | Check directory/file structure matches expected |
| run_script | script | Execute shell script, check exit code (v4) |
| invoke_skill | target, skill_file, input, expected_contains | Invoke Skill via LLM, check output (v5) |
| invoke_skill_judge | target, skill_file, input, judge_prompt | LLM-as-judge semantic quality check (v6) |
| judge_calibration | judge_prompt, good_example, bad_example | Meta-oracle: verify judge_prompt discrimination (v7) |

## 判断标准

- **通过（pass）**：所有 assertions 均满足
- **失败（fail）**：任一 assertion 不满足
- `expected_result: pass` 全部通过 → 基线达标
- `expected_result: fail` 确实失败 → 进化方向确认

## Preflight 快速验证协议

全量 eval 前，先运行 2-3 条 P0 核心用例做 sanity check：
1. 选取 `regression_level: P0` + `expected_result: pass` 用例
2. 若任一失败 → 终止，优先修复
3. 全部通过 → 继续完整 eval suite

Preflight 结果记录在 `attempt-001/preflight.json`（`execution_status: "actual"`）。

## Only-Increase Compliance

When upgrading versions: run previous version's full objective_cases.yaml against new version. 历史用例只增不删，zero regression allowed on previously passing cases.

## GSB Baseline Comparison

Each eval case should be executed twice (Skill vs bare LLM) to measure additionality — Good / Same / Bad 三级分类，增值率 = Good/(Good+Same+Bad)。增值率 < 30% 持续多个周期则触发退休流程（whitepaper §4.6）。
EVAL_PROTO_EOF

# evals/objective_cases.yaml
cat > "$DIR/evals/objective_cases.yaml" << 'CASES_EOF'
# Objective evaluation cases for {TODO: skill-name}
# Requirements: ≥5 cases, ≥2 expected-fail, ≥3 with gsb_baseline
# Required assertion types: run_script (v4), invoke_skill (v5),
#   invoke_skill_judge (v6), judge_calibration (v7)

cases:
  # --- Core structure checks (v0-era) ---

  - id: "TODO-output-file-exists"
    description: "{TODO: primary output file is created}"
    expected_result: pass
    dimension: correctness
    source: human_designed
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P0
    input: "{TODO: user request that triggers the skill}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: file_exists
        value: "{TODO: skill-name}-v0/{TODO: expected output file}"
    gsb_baseline:
      bare_llm_expected: "{TODO: bare LLM may produce output but without structured files}"
      skill_advantage: "{TODO: Skill ensures a properly structured output file exists}"

  - id: "TODO-output-contains-domain-content"
    description: "{TODO: output contains domain-specific terminology}"
    expected_result: pass
    dimension: correctness
    source: human_designed
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: contains
        target: "{TODO: skill-name}-v0/{TODO: file to check}"
        value: "{TODO: domain-specific term that should appear}"
    gsb_baseline:
      bare_llm_expected: "{TODO: bare LLM output may lack domain-specific structure}"
      skill_advantage: "{TODO: Skill enforces inclusion of domain terminology}"

  - id: "TODO-manifest-valid"
    description: "manifest.yaml is syntactically valid YAML"
    expected_result: pass
    dimension: correctness
    source: human_designed
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: yaml_valid
        target: "{TODO: skill-name}-v0/manifest.yaml"
    gsb_baseline:
      bare_llm_expected: "{TODO: bare LLM may not produce a valid manifest.yaml}"
      skill_advantage: "{TODO: Skill guarantees well-formed YAML metadata}"

  # --- Behavior check (⭐v4 run_script required) ---

  - id: "TODO-run-script-check"
    description: "{TODO: shell-verifiable behavior, e.g., output dir has expected files}"
    expected_result: pass
    dimension: correctness
    source: human_designed
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: run_script
        target: "{TODO: skill-name}-v0"
        script: |
          # {TODO: Replace with actual verification script}
          test -f "{TODO: expected file}" && echo "OK"
        expected_exit: 0
        timeout_seconds: 30

  # --- LLM output check (⭐v5 invoke_skill required) ---

  - id: "TODO-invoke-skill-check"
    description: "{TODO: LLM output contains domain-specific terms when skill is invoked}"
    expected_result: pass
    dimension: coverage
    source: frontier_paper
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request that exercises the skill}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: invoke_skill
        target: "{TODO: skill-name}-v0"
        skill_file: "{TODO: skill-name}-v0/SKILL.md"
        input: "{TODO: user input passed to the skill}"
        expected_contains:
          - "{TODO: domain-specific term 1}"
          - "{TODO: domain-specific term 2}"
        pass_rate_threshold: 0.8
        runs: 1

  # --- LLM-as-judge (⭐v6 invoke_skill_judge required) ---

  - id: "TODO-invoke-skill-judge-check"
    description: "{TODO: LLM judge confirms skill output meets quality bar}"
    expected_result: pass
    dimension: coverage
    source: frontier_paper
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: invoke_skill_judge
        target: "{TODO: skill-name}-v0"
        skill_file: "{TODO: skill-name}-v0/SKILL.md"
        input: "{TODO: user input}"
        judge_prompt: |
          Evaluate if the following output demonstrates TODO-domain-specific expertise.
          Reply PASS if it contains domain-specific knowledge, FAIL with reason if not.

          Output to evaluate:
        pass_rate_threshold: 0.8
        runs: 2
        timeout_seconds: 60

  # --- Judge calibration (⭐v7 judge_calibration required) ---

  - id: "TODO-judge-calibration-check"
    description: "{TODO: judge_prompt correctly distinguishes good vs bad domain outputs}"
    expected_result: pass
    dimension: consistency
    source: agent_generated
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: judge_calibration
        judge_prompt: |
          Evaluate if the following TODO-domain output demonstrates expert-level knowledge.
          Reply PASS if it shows clear domain expertise, FAIL with reason if it does not.

          Output to evaluate:
        good_example: |
          TODO: Write a concrete example of a HIGH-QUALITY domain output.
          Should contain domain terminology, specific knowledge, structured analysis.
          This must receive PASS from the judge_prompt above.
        bad_example: |
          TODO: Write a concrete example of a LOW-QUALITY domain output.
          Should be generic, vague, lacking domain knowledge.
          This must receive FAIL from the judge_prompt above.
        timeout_seconds: 60

  # --- Evolution directions (expected-fail cases — drive next version) ---

  - id: "TODO-evolution-fail-1"
    description: "{TODO: capability not yet implemented — evolution direction}"
    expected_result: fail
    dimension: coverage
    evolution_direction: "[fill in: what v1 should add or improve to make this pass]"
    source: human_designed
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request requiring advanced capability}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: contains
        target: "{TODO: skill-name}-v0/{TODO: file}"
        value: "{TODO: advanced content not yet produced}"

  - id: "TODO-evolution-fail-2"
    description: "{TODO: quality threshold not yet met — evolution direction}"
    expected_result: fail
    dimension: coverage
    evolution_direction: "[fill in: what v1 should add or improve for coverage]"
    source: human_designed
    added_in: v0
    target_point: "{TODO: single optimization point this case tests}"
    regression_level: P1
    input: "{TODO: user request}"
    context:
      whitepaper: meta_whitepaper.md
    assertions:
      - type: contains
        target: "{TODO: skill-name}-v0/{TODO: file}"
        value: "{TODO: content not yet produced}"
CASES_EOF

# evolve_history/vN/genesis.md
cat > "$DIR/evolve_history/${VERSION}/genesis.md" << 'GENESIS_EOF'
---
purpose: "Creation record for {TODO: skill-name} initial version"
---

# Genesis Record

## Design Assumptions

1. {TODO: Core assumption about the problem domain}
2. {TODO: Assumption about approach}

## Methods

{TODO: How was this version designed? What sources informed it?}

## Rejected Alternatives

- {TODO: Alternative approach considered and why it was rejected}

## Known Limitations

1. {TODO: Known limitation with impact assessment}
2. {TODO: Known limitation}

## Future Directions

- {TODO: Driven by expected-fail eval cases}

## 调研影响矩阵

| 研究来源 | 核心发现 | 对本 Skill 的具体影响 |
|----------|----------|----------------------|
| {TODO: Author et al. YEAR (Venue)} | {TODO: Key finding} | {TODO: How it shaped this Skill} |
| {TODO: Author et al. YEAR (Venue)} | {TODO: Key finding} | {TODO: How it shaped this Skill} |
| {TODO: Author et al. YEAR (Venue)} | {TODO: Key finding} | {TODO: How it shaped this Skill} |
| {TODO: Author et al. YEAR (Venue)} | {TODO: Key finding} | {TODO: How it shaped this Skill} |
| {TODO: Author et al. YEAR (Venue)} | {TODO: Key finding} | {TODO: How it shaped this Skill} |

## 独立评估框架

**陌生领域**：{TODO: 领域名称}
**创建的 Skill**：{TODO: skill-name}-v0/
**评估日期**：{TODO: YYYY-MM-DD}

| 维度 | 分数 | 用户评语 |
|------|------|---------|
| 目标导向 | /5 | {TODO} |
| 领域特异性 | /5 | {TODO} |
| Eval 区分力 | /5 | {TODO} |
| 可执行性 | /5 | {TODO} |

**总分**：/20
**合格**: 待执行
GENESIS_EOF

# self-bootstrap.md (process.md Step 3.5 output)
cat > "$DIR/self-bootstrap.md" << 'BOOTSTRAP_EOF'
# {TODO: skill-name} 自举协议 v0

> 本文件供 skill-creator 使用，不是给最终用户的。
> 按照 skill-creator 的 self-bootstrap.md 格式，描述此 Skill 如何演化到 v1。

## 触发条件

当满足以下任一条件时，执行自举：
- 当前版本的 eval 通过率 ≥ 85%，且有 ≥2 条 fail case 指向明确改进方向
- 用户明确要求升级到 v1
- 发现系统性设计缺陷，需架构级修复

## Phase 1: 自我评估

```bash
tools/validate.sh {TODO: skill-name}-v0/ --ship
```

记录：总 eval 数 / pass 数 / fail 数，以及每条 fail case 的 `evolution_direction`。

## Phase 2: 论文调研

针对 fail case 的 `evolution_direction` 执行 WebSearch，最低：
- ≥ 5 篇相关论文/标准文档
- genesis.md 中填写调研影响矩阵（≥5 行，来源具体可查）

## Phase 3: 设计变更方案

对每条 fail→pass 候选 case，记录：
- 当前失败原因
- 修复方案（具体变更哪个文件）
- 关联论文证据
- 预期 evidence

## Phase 4: 实施变更（顺序：process.md → SKILL.md → evals → manifest.yaml）

**Only-increase 约束**：不删除历史 case，不修改已有 fail case 的断言，fail→pass 必须附 evidence。

## Phase 5: 验证变更

```bash
tools/validate.sh {TODO: skill-name}-v1/ --ship
```

所有 ✗ FAIL 必须修复；⚠ WARN（execution_status 非 actual、ref card 命名等）不阻断准出，但需知晓并酌情处理。

## Phase 6: 终极检验

选择**陌生领域**，用 v1 创建该领域的 Skill，eval 必须包含：
- ≥1 条 `judge_calibration` 断言（v7 约束）
- ≥1 条 `invoke_skill_judge` 断言（v6 约束）

用户独立评估四维度（目标导向/领域特异性/Eval 区分力/可执行性），总分 ≥ 14/20。

## Phase 7: 准出文档

- evolve_history/v1/genesis.md（含调研影响矩阵 + 独立评估结果）
- evolve_history/v1/article/（8000-12000 词，含 GSB 分析）
- evolve_history/v1/evolution.md（量化对比 + Top 3 v2 方向）

```bash
tools/validate.sh {TODO: skill-name}-v1/ --ship  # 全部通过后更新 bootstrap_status
```
BOOTSTRAP_EOF

echo ""
echo "✓ Created $DIR/ with:"
echo "  [runtime]  SKILL.md, process.md, manifest.yaml, scaffold.md"
echo "  [runtime]  .step0.yaml, self-bootstrap.md, locks/"
echo "  [quality]  evals/eval_protocol.md"
echo "  [quality]  evals/objective_cases.yaml  (9 cases: run_script/invoke_skill/invoke_skill_judge/judge_calibration templates)"
echo "  [quality]  tools/"
echo "  [build]    evolve_history/${VERSION}/genesis.md  (includes 独立评估框架 section)"
echo "  [meta]     .skillignore  (distribution boundary)"
echo ""
echo "Next: Fill in {TODO} placeholders, then run tools/validate.sh $DIR/"
