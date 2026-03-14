---
summary: "Catastrophic interference shows connectionist networks lose old knowledge when learning new tasks — the foundational motivation for awesome-skill-creator's only-increase eval and P0 constraint protection"
type: paper
relevance: high
---

# McCloskey & Cohen (1989) — Catastrophic Interference in Connectionist Networks: The Sequential Learning Problem

## 书目信息
- **Authors**: Michael McCloskey, Neal J. Cohen
- **Year**: 1989
- **Venue**: Psychology of Learning and Motivation, Vol. 24, pp. 109–165
- **Links**: [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S0079742108605368)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 5000+，命名了连续学习领域的核心问题"灾难性遗忘"；是 Kirkpatrick et al. (2017) EWC 等现代工作的历史起点
- **领域定位**: 神经网络连续学习；认知科学与 AI 的交叉
- **同类对比**: Kirkpatrick et al. (2017) 提出 EWC 作为解决方案（弹性权重固定）；McCloskey & Cohen (1989) 定义了问题本身——两者关系是"发现问题"与"解决问题"

## 核心方法分析

### 问题定义
当连接主义网络（神经网络）序列学习两个任务时，学习新任务会导致旧任务的性能灾难性下降（catastrophic interference / catastrophic forgetting）——即使旧任务只是暂时停止训练。

### 结论
连接主义网络的权重是全局共享的（任务 A 和任务 B 都写入同一权重矩阵），导致学习任务 B 时必然覆盖与任务 A 相关的权重，造成任务 A 性能的断崖式下降（非平滑遗忘，而是"灾难性"干扰）。人类认知系统具有某种机制可以避免这一问题（complementary learning systems 假说）。

### 核心类比
**LLM skill 的版本迭代也面临"功能性灾难遗忘"**：每次 attempt 修改 skill prompt 以通过新的 eval case，可能导致之前通过的 eval case 失败——这是 only-increase eval 和 P0 保护机制需要解决的"功能退化"问题，在概念上与神经网络的灾难性遗忘同构。

### 技术机制
1. **实验设计**：先训练任务 A（如加法）至收敛，再训练任务 B（如乘法），测量任务 A 性能
2. **观察结果**：任务 A 的错误率在任务 B 训练后急剧上升（接近随机水平）
3. **原因分析**：反向传播（backpropagation）修改权重以最小化任务 B 的损失，但这些权重对任务 A 来说已经是错误的
4. **对比人类认知**：人类可以学习新技能而不干扰旧技能（海马-新皮层互补学习系统）

### 创新性
命名并系统化描述了神经网络连续学习的核心障碍；触发了 30 年后连续学习（Continual Learning）领域的大量研究。

### 实验设计
经典的序列任务学习实验（简单算术任务）；清晰展示了灾难性遗忘的存在和严重程度。

### 局限性
1. 实验任务简单（算术），在更复杂任务上的推广需要后续验证
2. 不适用于不修改权重的 LLM（如 GPT-4）——其"遗忘"是 prompt 层面的，不是权重层面的
3. 解决方案（如 EWC）的探索不在本文范围内

## 对当前 Skill 的价值

### 关键启发
**only-increase eval 的深层动机来自对"功能退化"的防范**：every new attempt that modifies a skill prompt to pass new eval cases risks "forgetting" (failing) previously passing eval cases — this is the prompt-level analog of catastrophic interference. The only-increase eval rule is the engineering solution: **eval history must never regress**.

**P0/P1/P2 分层保护机制**的类比：P0 assertions 对应"最高权重的神经连接"（Kirkpatrick 的 Fisher information matrix 高权重参数），必须受到保护不被新 attempt 覆盖；P2 assertions 对应低权重参数，允许在新 attempt 中被替换。

**attempt 历史追踪的必要性**：在没有 eval history 记录的情况下，开发者无法感知"功能退化"——就像神经网络在没有旧任务测试集的情况下，无法检测到灾难性遗忘。

### 本地验证思路
选择 skill-creator 某个历史 attempt（如 v5），运行其 eval suite；再应用 v7 的改进，重新运行 v5 的 eval suite，检查 v5 通过的 cases 中有多少在 v7 中失败——如果存在退化，说明发生了"功能退化"问题，only-increase eval 机制应已捕获。

### 不适用的部分
McCloskey & Cohen 的研究针对权重更新的神经网络；awesome-skill-creator 的 skill 是 prompt（离散文本），不是可梯度更新的权重。因此，EWC 等连续学习解决方案（正则化权重更新）不能直接应用。只有核心类比（不让新修改覆盖旧功能）是有效的，具体机制需要 prompt 层面的实现（即 only-increase eval + P0 保护）。
