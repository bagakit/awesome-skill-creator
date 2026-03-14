---
summary: "Non-testable programs lack a computable oracle; LLM skills are the modern canonical example — justifying invoke_skill_judge as a probabilistic oracle substitute"
type: paper
relevance: high
---

# Weyuker (1982) — On Testing Non-Testable Programs

## 书目信息
- **Authors**: Elaine J. Weyuker
- **Year**: 1982
- **Venue**: The Computer Journal, 25(4), 465–470
- **Links**: [Oxford Academic](https://academic.oup.com/comjnl/article/25/4/465/519464)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 1000+，测试理论领域奠基论文之一；40 年后在 LLM 测试语境中重新引起广泛关注
- **领域定位**: 软件测试基础理论；oracle 问题的经典形式化
- **同类对比**: Myers (2011) 设计测试用例假设 oracle 可得；Weyuker (1982) 正面回答"如果 oracle 不可得，测试意味着什么"——两者互为前提和补充

## 核心方法分析

### 问题定义
**Oracle 问题（The Oracle Problem）**：当一个程序的正确输出无法被自动判断时（因为没有可计算的参考实现、或正确性本身依赖人类判断），该程序在什么意义上可以被"测试"？Weyuker 称此类程序为"non-testable programs"。

### 结论
Non-testable programs 无法通过传统"运行→对比预期"方式验证正确性，但可以通过以下替代策略检测异常：
1. **Consistency testing**：同一程序的两次运行结果互相对比（测试非确定性和幂等性）
2. **Metamorphic testing**：基于输入变换的输出关系推断正确性（例如：若输入 x 是 y 的子集，则输出应满足某关系）
3. **Partial oracle**：只验证输出的某些可计算属性，而非完整正确性

### 核心类比
**LLM skill 是 non-testable program 的现代典型**：给定一篇文章，正确的摘要是什么？没有唯一答案，没有可计算的参考实现。awesome-skill-creator 中的 invoke_skill_judge 正是一种"partial oracle"——它不验证完整正确性，而是验证可机器化判断的质量属性子集。

### 技术机制
1. **Weyuker 可测试性公理**：程序 P 是可测试的，当且仅当存在一个可计算函数 O 使得对任意输入 x，O(P(x), x) = true 当且仅当 P(x) 是 x 的正确输出
2. **Non-testable 分类**：(a) 无参考实现（计算代价过高）；(b) 输出正确性本身模糊；(c) 测试涉及外部不可控因素
3. **Metamorphic relations**：不依赖 oracle，而依赖输入-输出间的数学关系进行验证（如排序的对称性）

### 创新性
第一次将"oracle 是否可得"作为可测试性的形式化标准；提出了 non-testable 程序的替代测试策略，这在 LLM 评测时代被重新发现为元测试（metamorphic testing）的基础。

### 实验设计
基于理论分析而非实验；通过数学例子（编译器、仿真程序、随机程序）论证 oracle 问题的普遍性。

### 局限性
1. 1982 年无法预见 LLM 场景；metamorphic testing 的具体应用需要领域知识设计 relations
2. Partial oracle 策略承认测试不完整，但不提供测试覆盖率的量化方法
3. 未讨论 oracle 本身也是 LLM 时（judge 的递归 oracle 问题）的处理方式

## 对当前 Skill 的价值

### 关键启发
**invoke_skill_judge 的理论合法性来自 Weyuker 的 partial oracle 框架**：因为 LLM skill 是 non-testable program（开放式生成任务无完整 oracle），awesome-skill-creator 用 LLM judge 作为 partial oracle——只验证可判断的属性（结构完整性、领域词汇覆盖、逻辑一致性），放弃对"完整正确性"的声称。这解释了为什么 judge_calibration 必须存在：partial oracle 的有效性边界需要显式校准。

### 本地验证思路
可设计 metamorphic test case：对同一 skill 输入两个"应产生一致质量"的等价请求（如中英文版本的同一问题），用 invoke_skill_judge 评分，检查两次评分是否一致（metamorphic relation：等价输入应得等价评分）。

### 不适用的部分
Weyuker 的 consistency testing（同程序两次运行对比）在 LLM skill 中的适用性有限——LLM 输出本身有合理的多样性，两次输出不同不意味着有错误。awesome-skill-creator 通过 pass_rate_threshold 而非 exact-match 来处理这种非确定性。
