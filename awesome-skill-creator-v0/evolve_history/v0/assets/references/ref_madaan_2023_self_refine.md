---
summary: "Self-Refine shows LLMs can iteratively improve their own outputs via self-feedback without additional training — the conceptual basis for awesome-skill-creator's attempt-level reflection loop"
type: paper
relevance: high
---

# Madaan et al. (2023) — Self-Refine: Iterative Refinement with Self-Feedback

## 书目信息
- **Authors**: Aman Madaan, Niket Tandon, Prakhar Gupta, et al.
- **Year**: 2023
- **Venue**: NeurIPS 2023
- **Links**: [arXiv](https://arxiv.org/abs/2303.17651)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 2000+，建立了 LLM self-improvement 的基础范式
- **领域定位**: LLM 自我改进；无训练的迭代优化
- **同类对比**: Constitutional AI (Bai et al. 2022) 通过自我批评微调模型；Self-Refine 在推理时通过自我反馈改进输出，无需微调；DSPy 通过编译优化 prompt；Self-Refine 通过反馈循环优化单次输出

## 核心方法分析

### 问题定义
如何在不修改模型权重的情况下，让 LLM 在推理阶段自动改进其输出质量？

### 结论
给定初始输出，LLM 可以自我生成反馈（指出问题所在），再根据反馈生成改进版本，循环多次；在代码优化、文本改写、数学推理等任务上，迭代 3-4 次后输出质量显著提升，且提升幅度随迭代次数递减（边际效益递减）。

### 核心类比
**Self-Refine 是 awesome-skill-creator attempt tracking 的理论前身**：每次 attempt 在分析上一次 attempt 的 eval 失败后生成改进方案，正是 Self-Refine 的"generate → feedback → refine"循环在 skill 创建场景的实例化。

### 技术机制
1. **Generate**：初始输出生成（initial draft）
2. **Feedback**：基于任务标准对输出进行自我评估，生成具体改进建议（如"第3段论证不充分，需要举例"）
3. **Refine**：基于 feedback 生成新版本输出
4. **Stopping condition**：当 feedback 表示"输出已满足要求"或达到最大迭代次数时停止
5. **无训练**：整个过程只用推理，不修改模型参数

### 创新性
第一个系统证明 LLM 可以无监督自我改进的工作；feedback 的语言明确性（具体指出问题而非只给分数）是改进质量的关键。

### 实验设计
在 7 个任务（代码优化、对话回应、数学推理等）上验证；与无 refine 的单次生成对比；GPT-3.5/GPT-4 上均有效果提升（GPT-4 效果更显著）。

### 局限性
1. Feedback 质量是瓶颈：如果 LLM 无法准确识别自身输出的问题，refine 方向错误
2. 迭代边际效益递减：超过 3-4 次后改进不明显，过多迭代反而可能降质
3. 自我批评偏向（self-enhancement bias）：LLM 倾向于对自己的输出给出过于正面的反馈

## 对当前 Skill 的价值

### 关键启发
**attempt tracking 的改进循环设计来自 Self-Refine 的实践发现**：awesome-skill-creator 在每次 attempt 失败后要求分析失败原因并在下次 attempt 中针对性改进，而非随机重试——这是 Self-Refine "feedback 明确化"原则的直接应用。

**最大 attempt 次数限制**（通常 3-5 次）来自 Self-Refine 的迭代边际效益递减发现：超过阈值后继续 refine 的收益不抵成本，此时应该升级策略而非继续循环。

**eval failure 作为 feedback 信号**：run_script 和 invoke_skill_judge 的失败结果正是 Self-Refine 中 feedback 的机器化形式——将"失败的断言"转化为下一次 attempt 的改进方向。

### 本地验证思路
分析 v0-v7 各代 skill-creator 的 attempt 历史：每次 attempt 改进是否明确针对上次 eval 失败点？还是随机重试？如果是后者，说明未遵循 Self-Refine 原则，改进效率可提升。

### 不适用的部分
Self-Refine 的反馈生成和优化都是同一模型完成（自我批评），在 awesome-skill-creator 中 judge 可以是不同的模型或 prompt（分离的批评者）。这种分离降低了 self-enhancement bias 风险，但引入了 judge 一致性问题（judge_calibration 解决的正是这个问题）。
