---
name: ref_nie_2020_dynabench_adversarial_nli
summary: Dynabench 提出"模型驱动的动态数据收集"范式——先让模型失败，再定向收集针对该失败的新数据/方案；将 eval 失败作为研究问题的起点而非终点
type: research
relevance: 支撑 process.md Step 7 的"eval fail → problem_statement → 定向调研"流程——fail case 不是需要绕过的障碍，而是定义下一步研究问题的精确输入
---

# Nie et al. (2020) — Adversarial NLI: A New Benchmark for Natural Language Understanding + Dynabench

**Authors**: Yixin Nie, Adina Williams, Emily Dinan, Mohit Bansal, Jason Weston, Douwe Kiela
**Year**: 2020
**Venue**: ACL 2020 / Dynabench (Facebook AI Research)
**URL**: https://arxiv.org/abs/1910.14599 (Adversarial NLI); https://dynabench.org
**Verified**: 2026-03-16

## 核心发现

**Model-in-the-loop 数据收集**：传统 benchmark 是静态的，模型一旦适应就失去区分力。Dynabench 的方案：
1. 部署当前最强模型
2. 让人类/自动化系统专门找该模型的**失败案例**
3. 将失败案例作为新 benchmark，驱动下一代模型改进

核心洞见：**失败是研究问题的精确定义工具**。"模型在 X 上失败"比"我们想改进 X"更精确——它给出了具体的 observable behavior 和 expected behavior，直接对应可搜索的研究问题。

Adversarial NLI 用此方法比静态 benchmark 更能区分模型能力边界。

## 对本 Skill 设计的影响

- `process.md Step 7.9` 的 `problem_statement.observed_behavior` / `expected_behavior` 字段设计来源于此——失败的 eval case 直接给出了这两个字段的填写材料
- 强调"直接改文件 = 闭门造车"的设计理由：eval fail 是精确的问题陈述来源，应该先转化为研究问题再修复，而不是直接 patch
- 与 Kitchenham PICOC 框架配合：fail case → PICOC problem_statement → 定向搜索 → frontier_coverage 判定
