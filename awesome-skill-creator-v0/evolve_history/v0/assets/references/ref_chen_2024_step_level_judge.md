---
summary: "Step-level value preference optimization localizes error-causing steps in math reasoning chains via MCTS Q-values, directly motivating v1's invoke_step_judge direction"
type: paper
relevance: high
---

# Chen et al. (2024) — Step-Level Value Preference Optimization

## 书目信息

- **Authors**: Guoxin Chen, Minpeng Liao, Chengxi Li, Kai Fan
- **Year**: 2024
- **Venue**: EMNLP 2024 Findings
- **Links**: [arXiv](https://arxiv.org/abs/2406.10858) | [ACL Anthology](https://aclanthology.org/2024.findings-emnlp.463/)
- **Verified**: 2026-03-14 (corrected from earlier wrong attribution "Gu et al.")

## 影响力与同类对比

- **影响力指标**：2024 新兴工作，step-level reward 方向的重要参考
- **领域定位**：LLM 推理质量，过程奖励模型（Process Reward Models）
- **同类对比**：相比 outcome-level reward（只评判最终答案），step-level reward 可以识别「正确答案但推理错误」的案例；相比 human step annotations，自动化 step-level 评判降低了标注成本

## 核心方法分析

### 问题定义

数学推理等多步任务中，output-level reward 无法区分「通过正确推理得到正确答案」和「通过错误推理碰巧得到正确答案」。如何对每个推理步骤分别评判质量？

### 结论

步骤级奖励模型（step-level reward models）比输出级奖励模型有更强的归因能力；按步骤分配奖励信号显著提升了推理链的质量；步骤边界定义是实现的关键挑战。

### 核心类比

步骤级评判相当于「批改作业时逐步批改」——不只看最终答案是否正确，而是每个计算步骤都有独立的分值，错误可以精确定位到第几步。

### 技术机制

1. Step segmentation：明确定义推理链中步骤的边界（通常用特殊 token 或换行符）
2. Per-step value function：为每个步骤训练独立的价值估计
3. Step-level preference data：收集步骤级的 good/bad 对比样本
4. Value preference optimization：基于步骤级奖励的偏好优化

### 创新性

将 preference optimization 从 output-level 扩展到 step-level；证明步骤级奖励信号在数学推理任务上有显著提升。

### 实验设计

在数学推理基准（MATH、GaoKao2023、OCWCourses）上验证，步骤级偏好优化（SVPO）比 output-level DPO 提升 2–6 个百分点（MATH: 57.1% → 59.5%，GaoKao2023 +1.7%，OCWCourses +6.0%）。核心价值是诊断精度（定位出错步骤），而非大幅度的绝对提升。注：「步骤级可定位 73% 的推理错误」为早期参考资料中的说法，尚未独立验证，引用时应谨慎。

### 局限性

步骤边界定义依赖领域先验；步骤级标注数据收集成本较高；跨领域泛化能力有限。

## 对当前 Skill 的价值

### 关键启发

**v1 方向 1（invoke_step_judge）的直接动机**：Chen et al. 证明步骤级评判有更强的错误定位能力——awesome-skill-creator 的 process.md 已有 Step 0-10 边界定义，这是实现 invoke_step_judge 的现成基础设施。

**步骤边界定义是关键**：本文最大的工程挑战是步骤分割——awesome-skill-creator 的每个步骤都有明确的「输入/输出」定义，这是比数学推理链更清晰的步骤边界。

### 本地验证思路

可以用 awesome-skill-creator 的 10 个步骤作为测试床：为每个步骤设计独立的 good/bad 样本对，验证 step-level judge 能否比 output-level judge 更精确定位失败来源。

### 不适用的部分

本文的 value preference optimization 是针对训练的——awesome-skill-creator 不训练模型，只进行推理时的质量评估。步骤级奖励训练的方法不直接适用，但步骤级评判的思想完全适用。
