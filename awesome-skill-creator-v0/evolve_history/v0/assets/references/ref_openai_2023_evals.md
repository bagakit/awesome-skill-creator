---
summary: "OpenAI Evals establishes the run_eval_suite pattern and grading abstraction that awesome-skill-creator's run_script assertions directly extend for LLM-based skill evaluation"
type: repo
relevance: medium
---

# OpenAI (2023) — Evals: A Framework for Evaluating LLMs and LLM Systems

## 书目信息
- **Authors**: OpenAI
- **Year**: 2023
- **Venue**: GitHub Open Source Repository
- **Links**: [GitHub](https://github.com/openai/evals)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: GitHub 14k+ stars；LLM 评测框架的早期代表；被 PromptFoo、LangSmith 等后续框架参考
- **领域定位**: LLM 系统评测基础设施；eval 规范化和可复现性
- **同类对比**: PromptFoo 更面向 CI/CD 集成和开发者工作流；OpenAI Evals 更面向研究性评测和大规模 benchmark；awesome-skill-creator 在两者之间，聚焦单 skill 的创建期 eval

## 核心方法分析

### 问题定义
如何构建可复现、可扩展的 LLM 评测基础设施，使不同团队的评测结果可比较？

### 结论
将 eval 分为三层：(1) eval spec（评测任务定义）；(2) grader（判断输出是否通过的组件，可以是 exact match / LLM-as-judge / human）；(3) runner（执行框架，管理输入分发、结果收集、统计汇总）。这三层分离使评测具有可复现性。

### 核心类比
**OpenAI Evals 的三层架构 = awesome-skill-creator 的 eval case 结构**：eval spec 对应 skill 的 eval cases 定义；grader 对应 run_script/invoke_skill_judge 的断言类型；runner 对应 skill 的 eval 执行逻辑。

### 技术机制
1. **YAML-based eval spec**：声明式定义输入样本、预期输出和评测指标
2. **Built-in graders**：exact match、includes、fuzzy match、model-graded（LLM-as-judge）
3. **Registry**：集中管理 eval 定义，支持跨团队共享
4. **Completion functions**：将被测 LLM 抽象为可替换的接口，支持对比不同模型

### 创新性
第一个将 LLM-as-judge 作为 grader 标准选项的开源框架；建立了"eval spec 作为代码"（evals as code）的工程实践。

### 实验设计
开源框架，通过社区贡献的 eval 案例库（覆盖数百个任务类型）验证框架的通用性。

### 局限性
1. 主要面向静态 benchmark，不直接支持 skill 创建期的动态 eval 需求
2. LLM-as-judge grader 的 calibration 机制未内置，需要用户自行验证 judge 质量
3. 框架较重（依赖 OpenAI 基础设施），不适合轻量化集成

## 对当前 Skill 的价值

### 关键启发
**run_script assertions 的 grader 抽象灵感来自 OpenAI Evals 的 grader 分类**：exact match 对应 `assert type: equals`，includes 对应 `assert type: contains`，model-graded 对应 `invoke_skill_judge`——awesome-skill-creator 在此基础上增加了 `judge_calibration` 这个 OpenAI Evals 缺失的 meta-grader 层。

**Eval spec 作为代码**的原则解释了为什么 awesome-skill-creator 要求 eval cases 以结构化形式（而非自然语言描述）定义：确保 eval 可复现、可版本控制、可比较。

### 本地验证思路
将 skill 的 eval cases 与 OpenAI Evals 的 YAML spec 格式对比：是否具备相同的三层分离（spec/grader/runner）？如果 awesome-skill-creator 生成的 skill eval 定义混淆了这三层，说明 eval 设计可改进。

### 不适用的部分
OpenAI Evals 的 Registry 和跨团队共享机制在 awesome-skill-creator 的单用户 session 场景中不适用；OpenAI Evals 假设 benchmark 是静态的，而 awesome-skill-creator 的 eval 在 skill 创建过程中动态演化。
