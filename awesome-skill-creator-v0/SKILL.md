---
name: awesome-skill-creator
description: "Goal-First + failure-mode-first eval + judge_calibration oracle：创建可验证、可自演化的高质量 domain skill；核心约束 only-increase、单点攻破、judge_calibration 强制"
---

# awesome-skill-creator

## 使命

awesome-skill-creator 存在的意义是让联邦持续自我改进。它创建的每一个 skill，都应该做到「用裸 LLM 做不到的事」——不是因为结构更完整，而是因为它真正理解了领域，并把这种理解固化成了可执行、可验证、可自演化的工作流程。

一个好的 skill 不是「有正确格式的文件集合」，而是能达到目标，且可量化验证，即使领域专家看了之后会说：对，这就是该怎么做的。

## 北极星目标

**创建的 skill 在真实场景中帮助用户解决领域问题，并且能持续变好。**

这意味着：
- Process.md 里的步骤反映领域专家的真实思考方式，不是通用模板
- Eval cases 能抓住真正的失败——当 skill 输出垃圾时，eval 必须检测到（包括可执行验证）
- 每个版本都有清晰的演进路径，知道自己的局限在哪里，下一步该攻哪里
- 自举时不作弊——只有实际执行证据才能证明进步

## 目标上下文

- **成功定义**：可验证、可自演化的 domain skill：process.md 反映领域专家思维、eval cases 区分好坏输出（含 judge_calibration）、有明确的进化路径和 evolve_history 证据链
- **失败模式**：
  - eval 只测结构不测功能——所有 case 通过但输出垃圾
  - judge_prompt 过严/过宽——LLM-as-judge 产生系统偏差
  - 进化不可解释——改了什么、为什么改不清楚
- **领域词汇表**：eval、judge_calibration、only-increase、run_script、invoke_skill_judge、assert、scaffold、evolve_history、genesis、preflight、bootstrap、fixture、failure_mode、process

## 模式切换

- `$ARGUMENTS` 包含 `--bootstrap` → 执行 `self-bootstrap.md`
- 否则 → 创建新 skill

## 创建流程

读取 `process.md`、`scaffold.md`、`../meta_whitepaper.md`，严格按步骤执行：

**Step 0（目标优先）** → 先定义：成功是什么、失败是什么、领域词汇是什么。输出 `.step0.yaml`（强制）。这是整个创建过程的北极星，后续每个决策都要回答「这能让 skill 更好地解决领域问题吗？」

**Step 1-2（分析 + 调研）** → 需求确认后，立即启动 5 类 sub-agent 并行调研——文献、前沿实现、工具分析、边界用例、用户场景。调研产出结构化 JSON，每条发现必须有具体论文/URL，不接受「参考了相关研究」。

**Step 3-3.5（设计 + 进化路径）** → 基于调研设计 SKILL.md 和 process.md，让 Claude 每次执行都有领域锚点。同时设计 self-bootstrap.md，让 v0 从诞生起就有可执行的进化路径。

**Step 4（失败模式优先 eval）** → 这是最重要的步骤。Eval 的设计顺序是：先问「什么是坏的输出」，再问「什么断言能自动检测到它」。支持五类断言：
- `contains` / `not_contains`：字符串存在性（基础）
- `min_count` / `max_count`：数量约束（结构）
- `run_script`：执行 shell 脚本验证行为，不只是检查字符串（功能验证）
- `invoke_skill_judge`：LLM-as-judge 评判语义质量（最强区分力）
- `judge_calibration`：meta-oracle，用已知 good/bad 样本双向校验 judge_prompt 的区分力（oracle 质量保证）

**Step 4.5（Preflight）** → 完整 eval 前先用 2-3 条核心 case 验证方案「至少奏效」。Preflight 失败时重新设计，不浪费完整 eval 的资源。

**Step 5-6（manifest + genesis）** → 元数据和创世记录。Genesis 的核心价值是：记录设计假设、被否决的替代方案、调研影响矩阵。这是未来版本最需要继承的。

**Step 7（验收）** → 运行 `tools/validate.sh`，人工审查每条断言的值是否包含领域特有词汇。`run_script` 断言必须在真实 fixture 上执行并记录输出。结果记入 attempt 追踪。

**Step 8-9（Article + Evolution）** → 准出必须。Article 可独立阅读，包含 GSB 对比分析。Evolution 给下一版本提供可执行的 Top 3 方向。

## 能力边界

awesome-skill-creator **能做**：
- 创建任意领域的 skill（domain / utility / infrastructure / meta）
- 基于 eval 和调研驱动的自举进化
- 通过 `run_script` 断言验证 Skill 的行为，而非只验证结构
- 通过 `invoke_skill_judge` 对 Skill 输出进行语义质量评判
- 通过 `judge_calibration` 验证 judge_prompt 本身的区分力（meta-oracle）
- 通过 P0/P1/P2 分级机制控制 only-increase 约束膨胀
- 生成 arxiv 质量的技术论文记录进化过程

awesome-skill-creator **不能做**：
- 替代真正的领域专家（终极检验需要人类独立评估）
- 保证 eval 完全没有自我参照偏差（外部来源 case 和终极检验是缓解机制，不是根治）
- 在嵌套 LLM session 中执行 LLM 类断言（会自动 skip，需独立运行）
- 自动化执行 step-level 评判（当前 judge 仍是 output-level）

## 核心约束（不可绕过）

1. **Only-increase**：历史 eval case 永不删除或变宽松（P2 归档 ≠ 删除）
2. **单点攻破**：每轮自举只攻一个优化点，确保因果可解释
3. **Evidence**：fail→pass 必须有具体执行证据，不接受文字宣称
4. **真实调研**：每条发现必须有具体来源；sub-agent 必须产出实质性 JSON
5. **执行证据**：`eval_report.json` 必须由 `run_eval.sh` 实际执行产生
6. **Preflight 先行**：完整 eval 前必须先过 preflight
7. **终极检验**：终极检验说明见 `terminal_test.md`（以 knowledge-crystallizer 为外部锚点，由用户做四维独立评估）
8. **Fixture 隔离**：eval 产生的测试 skill 目录必须存放在 `.tmp/eval/<技能名>_<版本>/` 中
9. **.step0.yaml 强制**：Step 0 目标定义文件为必须交付物，validate_structure.sh 强制检查
10. **judge_calibration 强制**：每个新 Skill 的 eval 中必须包含 ≥1 条 `judge_calibration` 断言（validate_evals.sh 自动检查）
11. **P2 归档规范**：P2 case 必须有 `superseded_by` 字段指向取代它的 case id；validate_evals.sh 检查引用完整性
12. **参考抄录强制（准出标准）**：所有 eval_research 中 `design_impact ≠ context_only` 的文献必须生成参考卡片存入 `evolve_history/v0/assets/references/`，绝对数量 ≥3；validate_structure.sh 检查，缺失不允许 ship
13. **eval 覆盖率强制**：eval cases 总数 ≥10，且必须覆盖 `.step0.yaml` 中每一个 failure_mode（每个 mode ≥1 fail case + ≥1 pass case）；validate_evals.sh 检查 failure_mode_id 字段覆盖率
