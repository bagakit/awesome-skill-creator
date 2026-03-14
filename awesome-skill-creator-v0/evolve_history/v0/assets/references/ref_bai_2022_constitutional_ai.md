---
summary: "Constitutional AI uses self-critique with explicit principles to align LLM behavior; critique prompt quality is the critical bottleneck, directly motivating judge_calibration"
type: paper
relevance: high
---

# Bai et al. (2022) — Constitutional AI: Harmlessness from AI Feedback

## 书目信息

- **Authors**: Yuntao Bai, Saurav Kadavath, Sandipan Kundu, et al. (Anthropic)
- **Year**: 2022
- **Venue**: arXiv preprint
- **Links**: [arXiv](https://arxiv.org/abs/2212.08073)
- **Verified**: 2026-03-14

## 影响力与同类对比

- **影响力指标**：被引 3000+，奠定了 RLAIF（Reinforcement Learning from AI Feedback）领域基础
- **领域定位**：LLM 对齐，AI 自我监督
- **同类对比**：相比 RLHF（人工反馈），Constitutional AI 用 AI 自我批评取代人工标注；相比 simple prompting，CAI 通过迭代 critique-revision 循环实现系统性改进

## 核心方法分析

### 问题定义

如何让 LLM 在减少有害输出方面实现自我对齐，而不依赖大量人工标注？

### 结论

提供明确原则（constitution）的 LLM 自我批评可以有效改善 harmlessness；critique prompt 的质量（明确性、具体性）是 CAI 效果的关键决定因素；迭代 critique-revision 优于单次批评。

### 核心类比

Constitutional AI 相当于「带明确规则手册的自我审查」——不只是「批评自己」，而是「按照一套明确写下来的规则批评自己」。规则手册的质量决定审查的有效性。

### 技术机制

1. Constitution：一套明确的原则（如「不要提供伤害他人的建议」）
2. Critique 阶段：LLM 对自己的输出按照 constitution 进行自我批评
3. Revision 阶段：LLM 基于批评修正输出
4. RL from AI Feedback：用经过 critique 的输出作为训练信号

### 创新性

首次将明确的规则集（constitution）引入 LLM 自我对齐；证明了 AI 自我批评可以替代（部分）人工标注；建立了 RLAIF 范式。

### 实验设计

在有害性、欺骗性等维度评估 CAI 模型；人工和自动评估显示 CAI 比 RLHF baseline 更 harmless；critique prompt 的明确性与效果正相关。

### 局限性

constitution 的设计本身需要人工专业知识；critique 质量上限受制于 LLM 能力；对细粒度领域知识的批评效果有限。

## 对当前 Skill 的价值

### 关键启发

**judge_calibration 是 CAI critique prompt 质量保证的操作化**：Constitutional AI 发现 critique prompt 质量决定 CAI 效果——awesome-skill-creator 的 judge_calibration 通过 good/bad 样本对强制验证 judge_prompt 的区分力，等于给 critique prompt 加了 unit test。

**「原则要明确」的设计理念**：CAI constitution 需要明确、具体——类比地，judge_prompt 需要明确包含 PASS/FAIL 两个关键词，validate_evals.sh 强制检查此约束。

### 本地验证思路

可检验：judge_prompt 中明确包含 PASS 和 FAIL 关键词时，judge_calibration 的通过率是否高于模糊 judge_prompt；validate_evals.sh 是否正确检测缺少 PASS/FAIL 关键词的 judge_prompt。

### 不适用的部分

CAI 的 constitution 是针对 harmlessness 的通用原则集——awesome-skill-creator 的 judge_prompt 是领域特异的（每个 skill 需要自己设计）。CAI 的原则可跨任务复用，但 judge_prompt 不能——这是 judge_calibration 需要每个 skill 独立执行的原因。
