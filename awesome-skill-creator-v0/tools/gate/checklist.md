# 准出速查清单

> 自动 = `tools/validate.sh` 覆盖，手动 = 需人工判断。
> 用于 Step 7 验收中「参照 `tools/checklist.md` 执行手动检查项」。

---

## 结构完整性 `[validate_structure.sh]`

- `[自动]` 目录名匹配 `{name}-v{N}` 模式（如 `skill-creator-v7`，不匹配为 **fail**）
- `[自动]` SKILL.md / process.md / manifest.yaml / evals/objective_cases.yaml / evals/eval_protocol.md 存在
- `[自动]` SKILL.md 含「目标上下文」「能力边界」「核心约束」「失败模式」段落；含触发指令/$ARGUMENTS处理（缺失为 **fail**）；引用 process.md（缺失为 **fail**）；frontmatter 仅允许且必须含 name/description 两个字段（字段缺失或多余均为 **fail**）
- `[自动]` process.md 含 Step 0（且为第一步，**fail**）/ ≥8 编号步骤（**fail**） / Preflight（**fail**） / sub-agent 编排（**fail**） / attempt 追踪（**fail**） / I/O 定义；引用 validate.sh（**fail**）；引用 run_eval.sh（**fail**，scaffold.md §Step 7: 必须包含 eval 执行指令）
- `[自动]` .step0.yaml 存在：skill_name（与目录一致，**fail**）+ created_at（ISO 日期，**fail**）+ success_definition（必须含 domain_vocab 中至少 1 个词汇，**fail**）+ ≥3 failure_modes（含 id/description/eval_detection，子字段缺失为 **fail**）+ ≥5 domain_vocab（不足为 **fail**）；SKILL.md description 含 domain_vocab 词汇（缺失为 **fail**）
- `[自动]` evolve_history/vN/genesis.md：含 假设/方法/被否决方案/已知局限/未来方向/调研影响矩阵（矩阵 ≥5 行，其中 ≥3 行含具体 URL/年份/会议名，填充后 **fail**；TODO 占位则跳过）；含独立评估框架（缺失为 **fail**）
- `[自动]` evolve_history/vN/summary.md：含 状态/攻克优化点/eval通过率/版本提升/已知局限 五个字段
- `[自动]` evolve_history/vN/evolution.md（`--ship` 时必须存在）：含 现状评估（有量化数字，**fail**）/不足分析/Top 3 优化建议（含问题/方案/收益/复杂度四要素，各缺失为 **fail**）/依赖分析；Top 3 条目 ≥3（**fail**）
- `[自动]` evolve_history/vN/target_point.md：含 目标/Goal（本轮攻克核心问题）+ 瓶颈/Bottleneck（缺失为 **fail**）+ 放弃的替代点（缺失为 **fail**，whitepaper §3.2）
- `[自动]` evolve_history/vN/comparison.md：含对比表格或前后对比内容（缺失为 **fail**）+ 已知代价/Trade-offs 节（缺失为 **fail**，whitepaper §3.2）；evolve_history/vN/failures/（有多次 attempt 时必须，缺失为 **fail**）
- `[自动]` eval_research/*.json：5 个文件，JSON 语法合法，必须 schema 字段存在（generated_at/skill_domain/agent_type/findings/top_insights/suggested_eval_cases）；generated_at 必须是 YYYY-MM-DD 格式且非 TODO 占位（**fail**）；agent_type 与文件名匹配（**fail**）；top_insights ≥3（不足为 **fail**）；findings[] 每条含 title/source/year/key_finding/design_impact（缺失为 **fail**）；findings[].source 必须是具体 URL 或会议/期刊名（模糊来源为 **fail**）；每个文件 ≥2 条真实发现（TODO 占位则跳过，**fail**）；suggested_eval_cases[] 每条含 description/source_title 字段；dimension ∈ {correctness|coverage|consistency}；expected_result ∈ {pass|fail}（枚举非法为 **fail**）
- `[自动]` release_checklist.md 含 Objective/客观 + Subjective/主观 两个节（缺失为 **fail**）
- `[自动]` attempt-001/ 包含 7 个文件（hypothesis.md/diff.md/preflight.json/eval_report.json/blind_eval_report.json/stress_report.json/verdict.json）；diff.md 须含基线对比内容（改动/Baseline/v0→等，缺失为 **fail**）
- `[自动]` attempt JSON 文件：execution_status 不含 "predicted"（"actual" 为 pass，"pending" 为 warn）；各 JSON schema 字段完整（preflight.json: attempt_id/timestamp/sanity_cases_run（execution_status=actual 时非空，**fail**）/results/verdict ∈ {proceed,abort}，abort_reason（verdict=abort 时必须，**fail**）；stress_report.json: status/stress_scenarios（非空）；eval_report.json: status/total/passed；blind_eval_report.json: status/qualified 或 total_score/dimensions）
- `[自动]` hypothesis.md 含 target_point / 假设 / 预期证据 三个字段（缺失为 **fail**）；verdict.json 含 verdict / attempt_id / evidence 字段（verdict ∈ {pass, fail, pending}；非 pending 时 evidence 不可为空，**fail**）
- `[自动]` locks/ 目录含 evolve.lock / promote.lock / register.lock（缺失为 **fail**，whitepaper §2.5）
- `[自动]` self-bootstrap.md：7 个 Phase 存在；evidence 要求（Phase 4 Only-increase 约束处，fail→pass 必须附 evidence）、Phase 6 judge_calibration 要求已记录
- `[自动]` Article 目录、evolution.md（`--ship` 模式下必须存在，缺失为 **fail**）；article/ 目录内必须含 .md 文件（缺失为 **fail**）；assets/references/（`--ship` 模式下缺失为 **fail**）
- `[自动]` meta 类型 Skill：tools/ 下 15 个标准脚本文件均存在（含 _lib.sh、suggest_p2_candidates.sh，缺失或不可执行为 **fail**）；run_eval.sh / run_blind_eval.sh 必须为完整实现（<30 行为 **fail**）
- `[自动]` 项目根目录 .gitignore 含 `.tmp/` 条目（缺失为 **fail**，whitepaper §1.2.12）
- `[信息]` 版本历史记录在 `evolve_history/` 中（`version_history/` 已在 v7 废弃，不再检查）

## Manifest 合规 `[validate_manifest.sh]`

- `[自动]` YAML 语法合法
- `[自动]` name / family / version / status / type / bootstrap_status / capabilities / federation_protocol / whitepaper_ref 字段存在（9 个必须字段）
- `[自动]` type ∈ {meta, infrastructure, domain, utility}（**fail**）；capabilities 为非空列表（**fail**）；version 匹配 `v\d+`（**fail**）；whitepaper_ref 目标文件必须存在（**fail**）
- `[自动]` bootstrap_status ∈ {genesis, objective_bootstrapping, subjective_bootstrapping, mature}
- `[自动]` status ∈ {draft, researching, optimizing, bootstrapping, pressure_testing, releasable, active, retired, archived} 枚举检查
- `[自动]` bootstrap_completed / bootstrap_target / creator_version / parent_version / auto_upgrade_policy / latest_alias 字段存在（缺失为 **fail**，whitepaper §2.2: 调度器必需字段，不能准出）；creator_version / parent_version 匹配 `v\d+` 或 `name-v\d+` 格式（**fail**）
- `[自动]` name = family + "-" + version（如 family=skill-creator, version=v3 → name=skill-creator-v3）；version 与目录名后缀一致；manifest name 与目录名不匹配为 **warn**（可能是别名，非 fail）
- `[自动]` federation_protocol 格式 N.N（如 "2.0"）；auto_upgrade_policy ∈ {all_ge_old_and_one_gt, manual, disabled}
- `[自动]` bootstrap_target 格式 v{N}；bootstrap_completed 为布尔值；latest_alias 等于 family

## Eval 质量 `[validate_evals.sh]`

- `[自动]` objective_cases.yaml 语法合法，case 数 ≥5（≥2 expected_result: pass，≥2 expected_result: fail）；case id 不得重复（**fail**）
- `[自动]` expected_result: fail 的 case ≥2，且每条有 evolution_direction
- `[自动]` 每条 case 含必须字段：id / description / expected_result / input / assertions / source / added_in / target_point / regression_level（缺失为 **fail**）
- `[自动]` dimension 字段存在且 ∈ {correctness, coverage, consistency}（缺失为 **fail**）
- `[自动]` 三维度覆盖：correctness / coverage / consistency 各至少 1 条（缺失为 **fail**）
- `[自动]` regression_level ∈ {P0, P1}；tier ∈ {P0, P1, P2}（若存在）；≥1 条 regression_level: P0（缺失为 **fail**，scaffold.md 升级门禁必须有 P0 case）
- `[自动]` source diversity ≥3 条非 human_designed case（**fail**）；frontier_paper ≥2 条（不足为 **fail**，process.md §4）；frontier_paper case description 需含论文标题（**fail**）；source ∈ {human_designed, agent_generated, frontier_paper, failure_log}；added_in 必须匹配 v\d+ 格式（缺失为 **fail**）
- `[自动]` 所有断言 type 必须在合法枚举内（file_exists / contains / not_contains / yaml_valid / yaml_field_equals / min_count / structure_match / run_script / invoke_skill / invoke_skill_judge / judge_calibration，未知类型为 **fail**）；各类型必须字段：contains/file_exists/not_contains/structure_match 需 `value`；yaml_valid 需 `target`；yaml_field_equals 需 `target+field+value`；min_count 需 `target+element+value`（缺失为 **fail**）
- `[自动]` ≥1 条 `run_script` 断言（v4 约束）；`script` 字段必须存在（**fail**）
- `[自动]` ≥1 条 `invoke_skill` 断言，含 target / skill_file / input / expected_contains（均必须，v5 约束）
- `[自动]` ≥1 条 `invoke_skill_judge` 断言，含 target / skill_file / input / judge_prompt（均必须，v6 约束）；judge_prompt 必须含 PASS 和 FAIL 关键词（缺失为 **fail**）
- `[自动]` ≥1 条 `judge_calibration` 断言，含 judge_prompt/good_example/bad_example（v7 约束）；judge_prompt 必须含 PASS 和 FAIL 关键词（缺失为 **fail**）；good_example == bad_example 为 **fail**；good/bad_example <50 chars 为 **fail**
- `[自动]` evolution_direction 不足 15 字符为 **fail**；target_point 不足 5 字符为 **fail**
- `[自动]` pass case 的 contains 断言 domain-specific 比率 ≥60%（**fail**，process.md §Step 7）；file_exists-only ratio ≤40%（**fail**）
- `[自动]` P2 case 均有 `superseded_by` 字段且引用有效（v7 约束）
- `[自动]` ≥3 条 case 有 `gsb_baseline.bare_llm_expected + skill_advantage` 字段
- `[自动]` eval_protocol.md 含 GSB 协议（**fail**） + Preflight（**fail**） + only-increase（**fail**） + 判断标准（**fail**） + 数字 GSB 阈值百分比（**fail**，如 "增值率 < 30%"）
- `[手动]` ⚠ **结构检查 ≠ 质量检查**：逐条确认 `contains` 断言的 `value` 包含领域特有词汇，而非「process」「Step」等通用词
- `[手动]` `judge_calibration` 的 `good_example` 和 `bad_example` 的差异是否足够明显，能区分好坏输出

## Article 质量 `[validate_article.sh --ship]`

- `[自动]` 总词数 8,000-12,000（**fail**）；各节词数在规定范围内（Abstract 150-250 / Introduction 1200-1500 / Related Work 1000-1500 / Design 2000-3000 / Evaluation 1500-2500 / Discussion 1000-1500 / Conclusion 200-300，超出为 **fail**）
- `[自动]` 必须 heading 存在（Abstract / Introduction / Related Work / Design / Evaluation / Discussion / Conclusion）
- `[自动]` Discussion 含 Limitations 子节
- `[自动]` Related Work 引用 ≥10 篇；按主题分组（≥2 subsections，不足为 **fail**）
- `[自动]` Abstract 包含 问题/motivation 元素（**fail**）+ 方法/approach 元素（**fail**）+ 结果/results 元素（**fail**）+ 意义/significance 元素（**fail**，scaffold.md: 问题/方法/结果/意义 四元素全检）
- `[自动]` Introduction 包含 contribution/novelty 声明（**fail**）+ 论文结构路线图（**fail**，scaffold.md: 贡献展开 + 论文路线图）
- `[自动]` Design 有 ≥3 个子节（设计原则层→架构层→细节层，不足为 **fail**）；包含 ≥3 处决策论证语言（because/tradeoff/ensures 等，不足为 **fail**）
- `[自动]` Evaluation 包含 GSB 分布分析（**fail**）+ ≥2 个子节（scaffold.md: 方法论→结果→GSB基线对比→变异分析，不足为 **fail**）
- `[自动]` Discussion/Limitations 包含量化数据（数字/百分比/case数量，缺失为 **fail**，scaffold.md: 失败分析需量化）
- `[自动]` Conclusion 明确提及未来版本方向（缺失为 **fail**，scaffold.md: 明确 v1 方向）
- `[自动]` assets/references/ 中每张参考卡片至少在正文中被引用一次（scaffold.md: 每张至少被引用一次）
- `[手动]` Article 可独立阅读（不依赖 process.md 上下文）
- `[手动]` 每个设计决策有「原则→证据→权衡」论证链（不只是描述做了什么）

## 参考卡片 `[validate_ref_cards.sh --ship]`

- `[自动]` 命名格式：`ref_{author}_{year}_{slug}.md`（含 4 位年份；warn）
- `[自动]` frontmatter 含 summary / type / relevance；type ∈ {paper, book, repo, blog, doc, spec, talk}；relevance ∈ {high, medium, low}（枚举非法为 **fail**）
- `[自动]` 书目信息 含 `**Verified**: yyyy-mm-dd` 格式验证日期（缺失为 **fail**）
- `[自动]` 必须 section 存在：书目信息 / 影响力与同类对比 / 核心方法分析（7 子节）/ 对当前 Skill 的价值（3 子节）
- `[自动]` 「不适用的部分」非空；「关键启发」含至少 1 处 `**...**` 加粗
- `[手动]` 每张卡片的「对本次自举的影响」明确指向 Phase 或设计决策（非「暂不适用」占大多数）

## P2 归档管理

- `[工具]` 运行 `tools/suggest_p2_candidates.sh evals/` 扫描 eval suite，确认无遗漏 P2 归档候选
- `[手动]` 对工具输出的 CANDIDATE 条目，确认是否实际被取代（assertion 子集 ≠ 一定冗余）

## 引用完整性 `[validate_references.sh]`

- `[自动]` 所有相对链接目标文件存在（无悬空引用）
- `[自动]` Article 中引用的 ref_* 均在 assets/references/ 有对应文件（**fail**）；assets/references/ 每张卡片均被 Article 引用（**fail**）

## 执行证据

- `[自动]` 5 个 JSON 文件（preflight / eval_report / blind_eval_report / stress_report / verdict）execution_status 不含 "predicted"
- `[手动]` 所有 `expected_result: fail` 中若有变为 pass 的，必须有 `evidence` 字段记录实际执行证据

## GSB 基线对比

- `[手动]` 至少对 2 条关键 case 执行 `run_blind_eval.sh` 对比 Skill vs 裸 LLM
- `[手动]` Skill 增值率（Good / (Good+Same+Bad)）是否 ≥30%？
- `[手动]` 如有 Bad/Same case，已定位到 process.md 的具体步骤并记录归因

## 自举可执行性

- `[手动]` self-bootstrap.md Phase 1-7 是否都可以在当前版本上逐步执行，无缺失前提？
- `[手动]` Phase 2 论文调研：实际执行了 WebSearch，且 genesis.md 调研影响矩阵 ≥5 行？

---

> 最后一项不可省略：`validate.sh <skill-dir> --ship` 全部通过后，更新 manifest.yaml 的 `bootstrap_status`。
