# awesome-skill-creator v0 → v1 进化分析

## 当前状态（v0）

| 能力层 | 实现状态 | 已知瓶颈 |
|--------|---------|---------|
| 目标定义 | .step0.yaml 强制 ✓ | 目标与 eval 的双向追踪仍手动 |
| 并行调研 | 5 类 sub-agent ✓ | 调研质量无自动验证 |
| 行为验证 | run_script 真实执行 ✓ | 依赖作者写出好 fixture |
| 语义质量 | invoke_skill_judge ✓ | output-level，无法定位失败步骤 |
| Oracle 质量 | judge_calibration ✓ | 静态样本，不反映真实输出分布 |
| 约束管理 | P0/P1/P2 分级 ✓ | P2 归档完全手动 |
| 分发体系 | 三层分发 + .skillignore ✓ | gen_dist.sh 尚未经过真实分发验证 |

## 不足分析

### 设计取舍（非缺陷）

- token 消耗较高（sub-agent + 多步验证）：这是故意的代价，适用于需要长期维护的 skill
- judge_calibration 样本手工编写：在有历史执行日志前，手工样本是唯一可行方案

### 真正的缺陷

1. **output-level oracle 上限**：judge_calibration 无法精确定位「哪个步骤失败了」，evolution_direction 只能写模糊方向
2. **P2 归档手动**：随 eval suite 增长，手动识别归档候选会成为瓶颈
3. **静态 calibration 样本代表性不足**：手工样本可能与真实输出分布差异较大

## Top 3 v1 优化方向

### 方向 1：Step-Level Judge（优先级最高）

**问题**：当前 invoke_skill_judge 评判整体输出，失败时只知道「输出不好」，无法定位到 process.md 的哪个步骤出了问题。evolution_direction 字段只能写模糊方向。

**方案**：新断言类型 `invoke_step_judge`——指定步骤编号 + 步骤输出的独立 judge_prompt。

**实现要点**：
- process.md 约定步骤输出格式（每个步骤有明确的交付物边界）
- run_eval.sh 支持步骤级日志记录
- judge_calibration 对应升级为 step-level good/bad 样本对

**收益**：能精确定位「Step X 的输出失败」而非「整体输出不足」，大幅提升 eval 的归因能力

**复杂度**：高（需要 process.md 格式约定 + run_eval.sh 修改 + 新断言类型）

**验收指标**：v1 的至少 3 条 eval case 能精确定位到「Step X 的输出失败」

**参考**：Gu et al. (2024) Step-Level Reward Models，https://arxiv.org/abs/2406.10858

---

### 方向 2：P2 智能归档推荐

**问题**：当前 51+ 条 eval case 已接近手动管理的可控上限。P2 归档决策完全依赖人工判断，随版本增长会成为维护瓶颈。

**方案**：实现 `suggest_p2_candidates.sh` 的断言 subsumption 分析——当 case A 的所有断言约束是 case B 的子集时，自动推荐 A 为 P2 候选。

**实现要点**：
- 分析 objective_cases.yaml 中的 `contains`/`not_contains` 断言包含关系
- 自动生成 `superseded_by` 字段建议，human review 后确认
- validate_evals.sh 可选 `--suggest-p2` flag 输出推荐列表

**收益**：将 only-increase 约束的管理从「人工记忆」升级为「工具辅助」

**复杂度**：中（suggest_p2_candidates.sh 已有基础框架，需增加 subsumption 分析逻辑）

**验收指标**：对 v0 自身 eval suite 运行 suggest_p2_candidates.sh，输出至少 2 条合理归档建议

**参考**：Weyuker (1982) 测试集优化原则，IEEE TSE

---

### 方向 3：Oracle 自动校准（依赖方向 1）

**问题**：judge_calibration 的 good/bad 样本是静态手工样本——如果 skill 真实输出分布与样本差异大，calibration 通过了但 judge 仍可能误判。

**方案**：run_eval.sh 记录 invoke_skill_judge 的完整原始输出，新增 `gen_calibration_samples.sh` 从执行日志中提取代表性样本。

**实现要点**：
- run_eval.sh 新增 `--record-judge-outputs` flag，保存原始 judge 输出到 `attempts/attempt-N/judge_outputs/`
- gen_calibration_samples.sh：PASS 分数最高 → good_example 候选；FAIL 分数最低 → bad_example 候选
- validate_evals.sh 升级：如有历史执行日志，验证 good_example 是否来自真实通过的执行

**收益**：将 oracle 质量验证从「静态手工样本」升级为「动态执行驱动样本」

**复杂度**：中高（依赖方向 1 的执行日志格式）

**验收指标**：对 knowledge-crystallizer 的 invoke_skill_judge 执行历史运行 gen_calibration_samples.sh，能自动生成可用的 calibration case

**参考**：Molina & Gorla (2024) Automated Oracle Quality Assessment

---

## 依赖分析

1. 完成 v0 终极检验（knowledge-crystallizer，用户 ≥14/20 评分）——方向 1/2/3 的前提
2. 方向 2（P2 推荐）作为基础设施，可在 v1 开发过程中并行完成（约 1-2 天）
3. 方向 1（step-level judge）优先级最高但复杂度也最高，建议先做 POC 验证 process.md 步骤输出格式的可行性
4. 方向 3 依赖方向 1 确定日志格式，最后实施
