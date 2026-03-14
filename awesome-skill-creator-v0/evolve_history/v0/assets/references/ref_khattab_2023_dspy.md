---
summary: "DSPy compiles declarative LM programs into optimized pipelines by treating prompts as learnable parameters — the closest prior art to awesome-skill-creator's self-evolving skill design"
type: paper
relevance: high
---

# Khattab et al. (2023) — DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines

## 书目信息
- **Authors**: Omar Khattab, Arnav Singhvi, Paridhi Maheshwari, et al.
- **Year**: 2023
- **Venue**: ICLR 2024
- **Links**: [arXiv](https://arxiv.org/abs/2310.03714)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 1500+，开源框架 GitHub 16k+ stars，正在成为 LM 系统工程的事实标准之一
- **领域定位**: LM program optimization；prompt 工程自动化
- **同类对比**: Guo et al. (2023, EvoPrompting) 用进化算法优化 prompt；DSPy 用编译器范式自动优化整个 LM pipeline；awesome-skill-creator 是 agent-in-the-loop 的人工监督优化

## 核心方法分析

### 问题定义
如何将 LM 系统从"手工 prompt engineering"解放出来，使其能像传统软件一样被自动优化？

### 结论
将 LM 程序的 prompt 和 few-shot examples 视为可学习参数，通过自动优化（bootstrapping + teleprompter 算法）在给定 metric 上最大化性能，同时保持程序逻辑声明式（与实现解耦）。

### 核心类比
**DSPy 之于 LM pipeline，相当于编译器之于高级语言**：程序员写声明式逻辑，编译器负责优化实现细节。awesome-skill-creator 的角色是"skill 编译器"——用户描述需求，系统生成并优化 skill 的 prompt 实现。

### 技术机制
1. **Signature**：声明式接口定义（输入字段 → 输出字段），不含 prompt 实现
2. **Module**：封装 LM call 的可组合模块（CoT, ReAct 等）
3. **Teleprompter（Optimizer）**：给定 metric，自动搜索最优 prompt 和 few-shot examples
4. **Bootstrap**：从训练数据自动生成 few-shot examples，通过 metric 筛选高质量样本
5. **Compilation**：将优化后的 prompt 和 examples 固化为可部署的程序

### 创新性
第一个将"编译器"范式引入 LM 系统优化的框架；将 prompt 工程从艺术（手工设计）转变为工程（自动优化）。

### 实验设计
在 GSM8K、HotpotQA 等标准 benchmark 上验证；DSPy 优化后的 pipeline 在多个任务上超过手工 prompt 工程，与 GPT-4 few-shot 表现相当（使用更小模型）。

### 局限性
1. Metric 函数仍需手工设计，且需要训练集；awesome-skill-creator 针对零样本新领域，无法依赖训练集
2. Teleprompter 的计算开销较高（需要多次 LM 调用）
3. DSPy 的 signature 抽象层可能与特定任务的 prompt 结构要求冲突

## 对当前 Skill 的价值

### 关键启发
**DSPy 的 bootstrap + metric-driven optimization 是 awesome-skill-creator attempt tracking + eval-driven improvement 的工业级验证**：两者都用 metric（eval score）驱动 prompt 改进循环，DSPy 自动化这个循环，awesome-skill-creator 用 agent-in-the-loop 实现更灵活的改进策略。

**GSB（Good/Sufficient/Bad）baseline 比较**的灵感部分来自 DSPy 的 compilation 评估方式：优化后的版本必须相对 baseline 有可衡量的提升，而不仅是绝对分数达标。

**v1 方向：自动化 attempt 搜索**可以借鉴 DSPy 的 teleprompter 设计——将 attempt 生成、执行、评分、筛选的循环自动化。

### 本地验证思路
比较手工设计的 skill prompt 与 DSPy 自动优化后的 prompt 的 eval 通过率；验证 awesome-skill-creator 的 agent-driven 优化能否在同等轮次内达到接近 DSPy 的效果。

### 不适用的部分
DSPy 假设有 labeled training data（即使是少量）；awesome-skill-creator 针对全新领域的零样本 skill 创建，没有历史训练数据。DSPy 的 bootstrap 样本生成需要多轮 LM 调用，在 awesome-skill-creator 的交互式 session 中成本过高。
