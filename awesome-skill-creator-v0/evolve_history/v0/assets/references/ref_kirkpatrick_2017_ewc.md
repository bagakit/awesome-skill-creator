---
summary: "EWC (Elastic Weight Consolidation) protects important neural network weights during new task learning, providing a principled framework for tiered constraint management"
type: paper
relevance: high
---

# Kirkpatrick et al. (2017) — Overcoming Catastrophic Forgetting in Neural Networks

## 书目信息

- **Authors**: James Kirkpatrick, Razvan Pascanu, Neil Rabinowitz, et al. (DeepMind)
- **Year**: 2017
- **Venue**: PNAS (Proceedings of the National Academy of Sciences)
- **Links**: [arXiv](https://arxiv.org/abs/1612.00796)
- **Verified**: 2026-03-14

## 影响力与同类对比

- **影响力指标**：被引 6000+，奠定了持续学习（continual learning）领域的基础
- **领域定位**：神经网络持续学习，防止灾难性遗忘
- **同类对比**：相比 progressive neural networks（参数增长），EWC 在固定参数预算内解决遗忘；相比 rehearsal methods（记忆重放），EWC 不需要保存历史数据

## 核心方法分析

### 问题定义

神经网络学习新任务时，会「忘记」（覆盖）旧任务的能力——这被称为灾难性遗忘（catastrophic forgetting）。如何在学习新能力的同时，保护已有能力？

### 结论

通过 Fisher Information Matrix 识别对旧任务最重要的权重，在新任务训练时对这些权重施加弹性约束（不能随意改变）——重要权重受保护，不重要权重可以自由更新以学习新任务。

### 核心类比

**类比**：EWC 相当于「带橡皮筋的学习」——新能力的学习受到橡皮筋（弹性约束）的约束，橡皮筋越紧（权重越重要），该能力越不会被覆盖。

### 技术机制

1. Fisher Information Matrix：量化每个权重对旧任务的重要性
2. 弹性约束项：在新任务的 loss 中加入 Ω * (θ - θ_A)^2 项，Ω 是重要性系数
3. 分级保护：重要权重（Ω 大）几乎不变，不重要权重（Ω 小）可以自由学习

### 创新性

首次将 Bayesian 框架（Fisher Information 作为后验估计）引入持续学习；提出了「重要性加权」的优雅类比。

### 实验设计

在 Atari 游戏和 Permuted MNIST 上验证：EWC 在学习新游戏时保留了 85%+ 的旧游戏性能，而 naive SGD 只保留了 ~40%。

### 局限性

Fisher Information 的计算在大型网络中代价高；单任务的「重要性」定义可能随时间变化；分级保护不能完全消除遗忘，只是缓解。

## 对当前 Skill 的价值

### 关键启发

**P0/P1/P2 分级是 EWC 思想的 eval 版本**：P0 case（Ω 极大）永不归档；P1 case（Ω 中等）当前活跃；P2 case（Ω 小）可被更强 case 取代归档。这套分级保护机制解决了 only-increase 原则的长期可持续性问题。

**「精简是进化的合法方向」**：EWC 允许不重要权重自由更新——类比地，P2 归档允许旧约束被更强约束取代，在不违反 only-increase 精神的前提下保持 eval suite 可管理。

### 本地验证思路

可检验：P0 case（核心回归约束）是否在所有版本中都保持通过；P2 case 的 superseded_by 引用是否都指向更强约束。

### 不适用的部分

EWC 的 Fisher Information 计算是针对神经网络权重的连续优化——在 eval case 管理中，「重要性」是人工判断的（P0/P1/P2 标签），不是自动计算的。v1 方向 2（P2 智能归档推荐）可部分自动化这个判断。
