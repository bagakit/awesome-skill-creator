---
summary: "EvoPrompting uses evolutionary algorithms (crossover + mutation) to search over prompt space — the automated alternative to awesome-skill-creator's agent-guided attempt search"
type: paper
relevance: medium
---

# Guo et al. (2023) — Connecting Large Language Models with Evolutionary Algorithms Yields Powerful Prompt Optimizers

## 书目信息
- **Authors**: Qingyan Guo, Rui Wang, Junliang Guo, et al.
- **Year**: 2023
- **Venue**: ICLR 2024
- **Links**: [arXiv](https://arxiv.org/abs/2309.08532)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 500+；提出了 EvoPrompt 框架，是 prompt 自动优化领域的代表工作
- **领域定位**: Prompt 优化自动化；进化计算 + LLM 结合
- **同类对比**: DSPy 用编译器范式优化 prompt（基于梯度/bootstrap）；EvoPrompting 用进化算法（基于种群搜索）；awesome-skill-creator 用 agent-in-the-loop（基于有监督的定向搜索）

## 核心方法分析

### 问题定义
如何在无需梯度信息的情况下自动优化离散 prompt，使其在给定任务上达到最优性能？

### 结论
将进化算法（遗传算法和差分进化算法）应用于 prompt 优化：将 prompt 视为"个体"，通过 LLM 实现"交叉"（组合两个 prompt 的优秀部分）和"变异"（改写 prompt 某些部分），以 eval score 为"适应度"进行选择淘汰；在多个 NLP benchmark 上超过人工设计的 prompt 和其他自动优化方法。

### 核心类比
**EvoPrompting 的种群搜索 = awesome-skill-creator 的 attempt 历史池**：多次 attempt 不是简单的线性迭代，而是一个多样性的搜索过程——每次 attempt 是不同的"个体"，eval score 是适应度，最终选择最优 attempt 的逻辑与进化选择类似。

### 技术机制
1. **种群初始化**：生成多个初始 prompt 变体（多样性初始化）
2. **遗传算法模式**：选择两个高适应度 prompt，LLM 执行"交叉"（取各自优秀部分合并）
3. **差分进化模式**：基于三个个体的差异，LLM 执行"变异"（改写某些表达）
4. **适应度评估**：在 eval 集上运行，以通过率作为适应度分数
5. **精英保留**：每代保留 top-k 个体，防止最优解退化

### 创新性
第一个将进化算法与 LLM prompt 优化结合的工作；证明 LLM 可以有效实现"交叉"和"变异"操作（因为 LLM 理解语义，不是随机字符组合）。

### 实验设计
在 BBH（Big-Bench Hard）、MMLU 等 benchmark 上与人工 prompt、APE、GrIPS 等方法对比；两种进化算法（GA 和 DE）都超过 baseline。

### 局限性
1. 需要大量 LLM 调用（种群大小 × 迭代次数），成本较高
2. 适应度评估需要标注的 eval 集；awesome-skill-creator 面向新领域，eval 集动态生成
3. 进化搜索是无监督的，无法利用用户的领域知识指导搜索方向

## 对当前 Skill 的价值

### 关键启发
**attempt 多样性策略的理论依据来自 EvoPrompting 的种群多样性原则**：attempt 之间应该有足够的差异性（不同策略方向），而不是只在上一个 attempt 基础上小幅调整——这与进化算法中"多样性维持"的重要性一致。

**v1 方向：并行 attempt 搜索**可以借鉴 EvoPrompting 的并行种群评估：多个 sub-agent 并行尝试不同方向的 skill 实现，以 eval score 选择最优者——这比串行 attempt 更高效。

**GSB 中 B（Bad baseline）的设计**：EvoPrompting 中的"精英保留"机制解释了为什么 awesome-skill-creator 要保留 attempt 历史而不是只看当前版本——历史 attempt 可以为后续优化提供"基因库"。

### 本地验证思路
在新 skill 创建任务中，设计两组实验：(A) 串行 attempt（每次基于上次失败改进）；(B) 并行 attempt（3 个 sub-agent 同时探索不同方向），比较两种策略的最终 eval 通过率和成本。

### 不适用的部分
EvoPrompting 假设有固定的 labeled eval 集可以计算适应度；awesome-skill-creator 的 eval cases 在创建期是动态演化的。进化算法的大种群（20-50 个个体）在交互式 session 中成本过高，awesome-skill-creator 只能支持 3-5 次 attempt（小种群）。
