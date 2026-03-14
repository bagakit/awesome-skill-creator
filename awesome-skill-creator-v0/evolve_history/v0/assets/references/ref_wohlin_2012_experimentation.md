---
summary: "Rigorous empirical study design for software engineering — the methodological basis for awesome-skill-creator's GSB baseline comparison and attempt-level controlled evaluation"
type: book
relevance: medium
---

# Wohlin et al. (2012) — Experimentation in Software Engineering

## 书目信息
- **Authors**: Claes Wohlin, Per Runeson, Martin Höst, Magnus C. Ohlsson, Björn Regnell, Anders Wesslén
- **Year**: 2012
- **Venue**: Springer (2nd edition; 1st edition 2000)
- **Links**: [Springer](https://link.springer.com/book/10.1007/978-3-642-29044-2)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 10000+，软件工程实验设计的标准教材；ICSE/FSE 等顶级会议的方法论参考
- **领域定位**: 软件工程实证研究方法；实验设计与统计分析
- **同类对比**: Myers (2011) 聚焦测试设计；Wohlin et al. (2012) 聚焦评估实验设计——前者回答"如何测试"，后者回答"如何衡量测试结果的统计意义"

## 核心方法分析

### 问题定义
如何设计可靠的实验来评估软件工程技术的效果？如何避免评估偏差，确保结论可复现？

### 结论
实证研究需要明确的：(1) 研究对象（object）；(2) 目标（purpose）；(3) 质量焦点（quality focus）；(4) 视角（perspective）；(5) 上下文（context）。此 GQM（Goal-Question-Metric）框架是可靠评估的基础。内部效度（internal validity）和外部效度（external validity）的平衡是实验设计的核心张力。

### 核心类比
**GQM 框架 = awesome-skill-creator 的 eval case 设计原则**：每个 eval case 应明确 Goal（此 case 验证什么质量属性）、Question（如何通过测试来度量）、Metric（具体的通过/失败判断标准）——这与 run_script/invoke_skill_judge/judge_calibration 的三层结构对应。

### 技术机制
1. **GQM（Goal-Question-Metric）**：从目标出发推导度量指标，避免"测量容易测量的而非重要的"
2. **实验变量控制**：独立变量（处理变量）、依赖变量（结果变量）、控制变量（保持固定）的明确分离
3. **基线比较**：任何新技术的效果必须与明确定义的基线对比
4. **统计显著性**：效果必须超过统计噪音阈值才能声明有效
5. **威胁识别**：主动识别和报告内部/外部效度威胁

### 创新性
将自然科学实验方法系统化移植到软件工程领域；GQM 框架成为软件度量领域的标准工具。

### 实验设计
本身是方法论教材，通过大量软件工程案例研究展示方法应用。

### 局限性
1. 书中假设实验可以严格控制变量；LLM 系统的随机性使严格控制困难
2. 统计显著性测试假设大样本；awesome-skill-creator 的 eval cases 通常是小样本（10-20 cases）
3. 外部效度要求跨场景复现；LLM skill 的跨领域效度是已知挑战

## 对当前 Skill 的价值

### 关键启发
**GSB（Good/Sufficient/Bad）baseline comparison 的设计来自 Wohlin 的基线比较原则**：任何声称 skill 有改进的版本必须相对明确的基线（前一版本或空实现）展示可量化的提升——而不能只说"eval 通过了"。

**only-increase eval 的统计意义**：新版本的 eval 通过率提升需要超过噪音阈值（LLM 非确定性）才有意义；Wohlin 的统计显著性原则解释了为什么 attempt 间的微小 eval 分数波动（±5%）不应驱动 prompt 修改。

**威胁识别**原则推动了 v7 中对 eval 自引用问题（self-referential bias）的明确承认：awesome-skill-creator 评测 awesome-skill-creator 这一设计存在内部效度威胁，文章结尾的"terminal test"需求正是应对外部效度威胁的直接回应。

### 本地验证思路
对 v0-v7 的演化数据进行 GQM 分析：明确每代改进的 Goal（是什么质量属性改进了？）、Question（用什么 eval 来测量？）、Metric（通过率从 X% 提升到 Y%？）；检查是否有缺少基线对比的"改进声明"。

### 不适用的部分
Wohlin 的统计检验（t-test、Mann-Whitney 等）需要多次重复实验的数据；awesome-skill-creator 的每代 skill 是单次构建，无法满足重复实验要求。GQM 框架假设 metric 在实验前固定，而 awesome-skill-creator 的 eval 在 skill 创建过程中动态演化（这是 only-increase eval 的已知局限）。
