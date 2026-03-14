# Skill 目录标准模板

> 联邦中每个 Skill 目录必须遵循此结构。由 awesome-skill-creator 创建的所有 Skill 均以此为蓝本。
> 内置七代能力：`.step0.yaml` 强制（v4）；`run_script` 断言（v4）；`invoke_skill` 断言（v5）；
> `invoke_skill_judge` 断言（v6）；`judge_calibration` 断言（v7）；P0/P1/P2 分级（v7）；
> GSB 分布分析强制写入 Article Evaluation 章节（v7）。

## 分发层级（Distribution Tiers）

每个文件属于三个层级之一，`tools/gen_dist.sh` 按此打包：

| 层级 | 内容 | 用途 |
|------|------|------|
| **runtime** | SKILL.md, process.md, manifest.yaml, .step0.yaml, self-bootstrap.md, scaffold.md, locks/（reset） | 消费者运行 skill 的最小集合 |
| **quality** | runtime + evals/, tools/ | 质量验证：运行 validate.sh、自举演化 |
| **build** | evolve_history/, version_history/, .tmp/ | 构建产物：研究历史、attempt 记录、文章 — 不分发 |

分发边界由 `.skillignore` 声明，`gen_dist.sh` 执行打包。

## 标准目录结构

```
{skill-name}-{version}/
├── .skillignore                    # 分发边界声明（gen_dist.sh 读取）[meta]
├── SKILL.md                        # Claude Code slash command 主文件（必须）[runtime]
├── process.md                      # 该 Skill 的核心工作流程（必须）[runtime]
├── manifest.yaml                   # 元数据：版本、状态、能力声明（必须）[runtime]
├── scaffold.md                     # 目录结构与规范参考[runtime]
├── .step0.yaml                     # 目标定义：success_definition/failure_modes/domain_vocab（强制）[runtime]
├── self-bootstrap.md               # 进化协议（Step 3.5 产出）[runtime]
├── locks/                          # [runtime — reset on distribute]
│   ├── evolve.lock
│   ├── promote.lock
│   └── register.lock
├── evals/                                                  # [quality]
│   ├── objective_cases.yaml          # 客观层评测用例（必须，≥5 条）
│   ├── eval_protocol.md            # 评测执行规范（必须）
│   └── eval_research/              # 结构化调研 JSON（必须，5 个文件）
│       ├── literature_review.json
│       ├── frontier_impls.json
│       ├── tool_analysis.json
│       ├── edge_cases.json
│       └── user_scenarios.json
├── tools/                                                  # [quality] — meta 类型时为 runtime
│   ├── validate.sh                                         # shim
│   ├── gate/                                               # 只读验证器（无副作用）
│   └── scripts/                                            # 生成器 + 执行器（有副作用）
├── evolve_history/                                         # [build — 不分发]
│   └── v0/
│       ├── genesis.md                                      # 创世记录（必须）
│       ├── summary.md                                      # 本版本摘要（必须）
│       ├── target_point.md                                 # 目标、瓶颈、放弃的替代点（必须）
│       ├── comparison.md                                   # 优劣势分析（必须）
│       ├── release_checklist.md                            # 准出检查清单（必须）
│       ├── evolution.md                                    # 进化建议（准出必须）
│       ├── attempts/
│       │   └── attempt-001/
│       │       ├── hypothesis.md
│       │       ├── diff.md
│       │       ├── preflight.json
│       │       ├── eval_report.json
│       │       ├── blind_eval_report.json
│       │       ├── stress_report.json
│       │       └── verdict.json
│       ├── article/
│       │   └── {skill}_{ver}_article_{paper-name}.md
│       └── assets/
│           └── references/
└── version_history/                # [build — 不分发]
```

## 各文件规范

### SKILL.md（必须）
- Frontmatter 只使用两个字段：`name`、`description`
- `description` 字段必须包含 `.step0.yaml` 中 `domain_vocab` 的词汇
- 包含完整的触发指令和执行逻辑
- 包含「目标上下文」段落（成功定义、失败模式、领域词汇表）
- 包含「能力边界」和「核心约束」段落

### process.md（必须）
- 步骤清晰、可执行、可验证
- Step 0（目标优先）必须是第一步
- **Step 数量 ≥ 8**
- **Step 7（验收）必须引用 `tools/validate.sh`**
- **Step 7（验收）必须引用 `tools/scripts/run_eval.sh`**

### manifest.yaml（必须）
必须包含以下字段：
```yaml
name: string              # 版本化名称
family: string            # 稳定家族名
version: string           # 版本号，格式 v{N}
status: string            # draft | researching | optimizing | bootstrapping | pressure_testing | releasable | active | retired | archived
bootstrap_completed: bool
bootstrap_target: string
creator_version: string
parent_version: string
auto_upgrade_policy: string
latest_alias: string      # 必须等于 family 字段值
type: string              # meta | infrastructure | domain | utility
bootstrap_status: string  # genesis | objective_bootstrapping | subjective_bootstrapping | mature
capabilities: list        # 非空
federation_protocol: string  # 格式 N.N
whitepaper_ref: string
```

### evals/objective_cases.yaml（必须）

**最低数量和质量要求**：
- **至少 10 条评测用例（≥4 pass，≥4 fail）**（validate_evals.sh 强制）
- **每个 `.step0.yaml` failure_mode 必须有 ≥1 专属 fail case + ≥1 pass case**（`failure_mode_id` 字段覆盖率 100%，validate_evals.sh 检查）
- 三个维度（correctness/coverage/consistency）**各至少 2 条** case
- `source: frontier_paper` case ≥ 3 条
- ≥1 条 `run_script` 断言
- ≥1 条 `invoke_skill` 断言
- ≥1 条 `invoke_skill_judge` 断言
- ≥1 条 `judge_calibration` 断言（含 good_example + bad_example）

**`judge_calibration` 格式**：
```yaml
- type: judge_calibration
  judge_prompt: |
    评估以下输出是否展示了领域专业性...回复 PASS 或 FAIL。
    待评估输出：
  good_example: |
    [已知的高质量领域输出样本——judge 应判为 PASS]
  bad_example: |
    [已知的低质量输出样本——judge 应判为 FAIL]
  timeout_seconds: 60
```

**⭐ eval case tier 字段**：
```yaml
  tier: P1      # P0 = 核心不可删，P1 = 当前活跃，P2 = 已归档（需 superseded_by）
  superseded_by: "stronger_case_id"  # 仅 P2 case 需要
```

### evolve_history/v{N}/genesis.md（必须）
必须包含：假设、方法、被否决方案、已知局限、未来方向、调研影响矩阵（≥5 条，≥3 行含具体 URL/年份/会议名）、独立评估框架

### evolve_history/v{N}/summary.md（必须）
```markdown
# {skill-name} v{N} 版本摘要
- **状态**：releasable
- **攻克的优化点**：...
- **eval 通过率**：{N}/{M}
- **相比上版本的提升**：...
- **已知局限**：...
```

### evolve_history/v{N}/article/（必须，domain 类型强制）

Article 是准出物，不是附录。validate_article.sh 检查结构；`article_arxiv_invoke_skill_judge` eval case 检查内容质量。

**强制节结构**：Abstract / Introduction / Related Work / Design / Evaluation / Discussion / Conclusion

**内容质量三项硬要求**（每项缺失为 **fail**）：

1. **贡献可检验性**：每条 contribution 必须有 `failure_mode_prevented` + `applicable_boundary` + `verifiable_instance` 三要素，不接受只有主张的贡献描述
2. **实验证据或 Planned Experiments**：有真实对照实验时提供结果表格（≥2 domain，≥5 tasks/条件）；无实验时必须提供 `### Planned Experiments` 子节，含完整的 ablation design YAML（domain 选择理由、条件定义、metrics 测量方法、success criterion、是否 blocking for next version）
3. **可复现性**：`### Reproducibility` 子节，含最小命令序列（从 clone 到 eval report）、fixtures 位置与状态（现有 / `status: planned`）、LLM 依赖说明

**Related Work 差异定位要求**：每篇引用必须有一句"本工作与之的区别或继承是……"，只描述论文本身为 **fail**。

### evolve_history/v{N}/assets/references/（准出标准）

存放所有参考过的外部文献卡片，**非可选目录**。

**最低要求（validate_structure.sh 强制）**：
- 卡片数 ≥ eval_research JSON 中 `design_impact ≠ context_only` 的 findings 总数
- 绝对数量 ≥ 3 张
- genesis.md 调研影响矩阵中引用的每篇文献都必须有对应卡片

### 参考卡片规范
命名：`ref_{作者姓}_{年份}_{关键词}.md`
frontmatter 必须含 summary / type / relevance
书目信息中必须包含 `**Verified**: yyyy-mm-dd`

## 命名规范

- 目录名：`{skill-name}-{version}`，如 `eval-generator-v0`
- 文件名：小写，连字符分隔，语义化
- 版本号：`v0`, `v1`, `v2`... 严格递增

## 项目根目录配置

- **`.gitignore` 必须包含 `.tmp/` 条目**

## 版本状态机

```
draft → researching → optimizing → pressure_testing → releasable → active → retired → archived
```

## 自动升级门禁

以下条件**全部满足**才允许自动升级（`all_ge_old_and_one_gt`）：
1. 历史 `expected_result: pass` 的 case 100% 通过（无回归）
2. 历史 blind eval 的 GSB 增值率不低于上一版本
3. 无任何已优化 feature 出现退化
4. 至少一个核心指标严格提升
5. evolve_history、Article、Evolution、参考卡片、失败归因全部齐全
6. 当前没有其他正在进行中的同 skill 进化任务
