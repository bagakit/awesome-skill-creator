# Release Checklist — awesome-skill-creator v0

## Objective Layer

- [ ] `validate.sh awesome-skill-creator-v0/ --ship` → 0 failures, 0 warnings
- [ ] `run_eval.sh awesome-skill-creator-v0/` → all executed cases pass
- [ ] tools/gate/ 所有验证脚本可执行
- [ ] evals/objective_cases.yaml 含 ≥1 judge_calibration 断言
- [ ] evals/objective_cases.yaml 总 case 数 ≥10（≥4 pass, ≥4 fail）
- [ ] evals/objective_cases.yaml 覆盖 .step0.yaml 所有 failure_mode（每个 mode ≥1 fail + ≥1 pass，`failure_mode_id` 字段完整）
- [ ] evals/objective_cases.yaml 三个维度（correctness/coverage/consistency）各 ≥2 条
- [ ] .step0.yaml 存在且含 ≥5 domain_vocab
- [ ] manifest.yaml 所有必须字段完整
- [ ] locks/ 三个锁文件存在
- [ ] evolve_history/v0/genesis.md 含七节必须内容
- [ ] evolve_history/v0/assets/references/ 参考卡片数 ≥ eval_research 中 design_impact≠context_only 的 findings 总数，且绝对值 ≥3
- [ ] assets/references/ 每张卡片含 frontmatter（summary/type/relevance）和 Verified 日期

## Subjective Layer (Terminal Test)

- [ ] 按 `terminal_test.md`：用 awesome-skill-creator-v0 推进/产出 knowledge-crystallizer 可执行 skill（含 judge_calibration 断言 ≥1 条）
- [ ] 用户独立评估四维度，总分 ≥14/20
- [ ] genesis.md 独立评估框架章节更新为「是」
