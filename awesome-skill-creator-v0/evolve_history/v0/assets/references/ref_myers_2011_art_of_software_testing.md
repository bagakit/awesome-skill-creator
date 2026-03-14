---
summary: "Seminal software testing textbook: test oracle design, equivalence partitioning, and boundary analysis remain the foundation of assertion-based skill evaluation"
type: book
relevance: medium
---

# Myers, Sandler & Badgett (2011) — The Art of Software Testing (3rd ed.)

## 书目信息
- **Authors**: Glenford J. Myers, Corey Sandler, Tom Badgett
- **Year**: 2011
- **Venue**: Wiley (3rd edition; 1st edition 1979)
- **Links**: [Book](https://www.wiley.com/en-us/The+Art+of+Software+Testing%2C+3rd+Edition-p-9781118031964)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: 引用 5000+，软件测试领域标准教材，40+ 年生命力
- **领域定位**: 软件测试基础理论与实践；测试设计经典参考
- **同类对比**: 与 Wohlin et al. (2012) 互补——Myers 侧重测试设计（如何构造用例），Wohlin 侧重实验方法论（如何评估效果）

## 核心方法分析

### 问题定义
软件测试的核心难题：如何在无穷输入空间中选取最有效的测试用例，以及如何定义正确的预期输出（test oracle）？

### 结论
等价类划分（equivalence partitioning）和边界值分析（boundary value analysis）是最具代价效益的测试用例选取策略；测试 oracle 必须在测试设计阶段预先明确，而非在执行后凭感觉判断。

### 核心类比
**测试 = 破坏性活动**：Myers 的核心哲学是"测试的目标是发现错误，而不是证明程序正确"——这与 awesome-skill-creator 中 eval 用于检测退化而非证明成功的定向哲学完全一致。

### 技术机制
1. **等价类划分**：将输入域分为有效/无效等价类，每类取一个代表用例
2. **边界值分析**：在等价类边界处取额外用例（边界是错误高发区）
3. **判断表测试**：对具有多条件组合逻辑的场景系统化覆盖
4. **Oracle 预定义原则**：测试用例的预期输出必须在测试执行前定义，避免"结果偏向"（confirmation bias）

### 创新性
第一次将测试的"心理学"（测试者心态）和"技术学"（用例设计方法）系统结合；Oracle 预定义原则在 LLM 时代仍然适用。

### 实验设计
经典案例研究（三角形分类程序、日历程序等）展示等价类划分在实际中的应用；数十年教学实践验证了方法的可复用性。

### 局限性
1. 针对确定性程序；LLM 输出的非确定性（每次运行结果不同）超出原书设计范围
2. Oracle 构造假设测试者具有领域专业知识；LLM 场景中 oracle 本身可能也是 LLM 生成的
3. 第3版（2011）未涵盖 ML/AI 系统测试的特殊挑战

## 对当前 Skill 的价值

### 关键启发
**run_script assertions 的设计原则直接来自本书的 oracle 预定义原则**：awesome-skill-creator 要求在创建 skill 时就明确 `expected_output` 或 `judge_prompt`（即 oracle），而非在看到输出后再决定是否通过。等价类划分思想体现在 P0/P1/P2 分层中——P0 是"有效类边界"（必须通过），P1/P2 是更宽泛的等价类。

### 本地验证思路
检查 skill-creator 生成的 skill 的 eval cases：每个 case 的 `expected` 字段是否在用例构造时已明确定义？还是执行后回填？如果是后者，说明违反了 Myers 的 oracle 预定义原则，存在 confirmation bias 风险。

### 不适用的部分
Myers 的方法假设程序行为是确定性的（相同输入→相同输出）。awesome-skill-creator 中的 LLM skill 是概率性的，因此不能直接使用确定性 oracle——这是 invoke_skill_judge 和 pass_rate_threshold 存在的根本原因。
