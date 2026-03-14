# Attempt 006：Day 6 — invoke_skill + invoke_skill_judge

**target_point**: 引入 LLM-as-judge 评估主观质量维度

**假设**: 如果引入 invoke_skill_judge 断言类型（用 LLM judge 评估 skill 输出），则能覆盖 run_script 无法覆盖的主观质量维度（领域专向性、叙事质量、设计论证完整性等）。

**核心机制验证**：
1. invoke_skill_judge 能否稳定（多次运行）判断同一输出的质量？
2. invoke_skill（全流程执行 skill）+ invoke_skill_judge（评估输出）组合是否可靠？
3. judge_prompt 的质量如何保证？（Day 6 的核心遗留问题）

## 研究背景

Day 5 的 run_script 能验证"格式正确、脚本可执行"，但无法判断：
- process.md 的领域专向性是否足够
- genesis.md 的设计论证是否完整
- SKILL.md description 是否真的能让 agent 理解意图

这类主观维度需要 LLM judge。

## 预期证据

1. invoke_skill_judge 对 3 个不同质量的 SKILL.md 给出不同评分（能区分好坏）
2. 多次运行同一 case，judge 结论一致率 ≥ 70%（初步稳定性）
3. invoke_skill（全流程）能在 fixture 上真实运行 skill

## Expected Outcome

引入 LLM oracle 层：invoke_skill + invoke_skill_judge 两种断言类型，使 eval 能覆盖主观质量维度。但 judge 质量验证机制缺失——这是 Day 7 要解决的问题。
