---
summary: "Comprehensive survey of regression test minimization, selection, and prioritization — the canonical reference for subsumption-based test suite reduction and its hazards"
type: paper
relevance: high
---

# Yoo & Harman (2012) — Regression Testing Minimization, Selection and Prioritization: A Survey

## 书目信息

**作者**：Shin Yoo, Mark Harman
**年份**：2012
**来源**：Software Testing, Verification and Reliability (STVR), Vol. 22, No. 2, pp. 67–120
**DOI/Link**：https://doi.org/10.1002/stvr.430
**Verified**: 2026-03-15

## 影响力与同类对比

- **影响力**：引用 1500+，是测试套件管理领域的标准综述；Harman 是 SBSE（Search-Based Software Engineering）领域奠基人之一
- **领域定位**：覆盖三大方向——minimization（删减）、selection（选择）、prioritization（排序）——awesome-skill-creator 的 P2 归档对应 minimization 分支
- **同类对比**：Weyuker (1982) 回答"什么程序可以被测试"；本文回答"如何维护一个随时间增长的测试套件"。两者互补——Weyuker 是测试的理论边界，本文是测试管理的工程实践

## 核心方法分析

### 问题定义

**测试套件维护的三元悖论**：测试套件随时间增长（only-increase）→ 执行成本增加 → 工程团队面临压力要删减。但删减可能降低 fault detection。如何在不损失检测能力的前提下缩减测试套件？

### 结论

1. **Subsumption 是最严格的冗余定义**：测试用例 A subsumes B 当且仅当 A 覆盖的所有代码元素 B 也覆盖（且 B 还覆盖额外元素）。如果 A 通过，B 必然通过；B 是冗余的。
2. **Greedy 算法是实践首选**：每步选择覆盖最多未覆盖元素的用例，O(n²) 复杂度，接近最优（ILP 是精确解但 NP-hard）。
3. **Rothermel 危险**：最小化套件在统计上能找出更多 fault（因为删除了重复覆盖），但个别 fault 可能因"幸存的唯一覆盖者被删除"而漏检。最小化不保证 fault-detection equivalence。
4. **Prioritization 优于纯删减**：排序不删用例，在有限时间内优先运行高价值用例，兼顾完整性和速度。

### 核心类比

**P2 归档 ≈ Subsumption-Based Minimization**：当 case A 的所有断言约束是 case B 的子集时，B 通过则 A 必然通过——这正是 Yoo & Harman 定义的 assertion-level subsumption。P2 归档（而非删除）是 awesome-skill-creator 对"Rothermel 危险"的工程响应：通过 `superseded_by` 字段保留审计链，使"删减"可逆。

### 技术机制

1. **Coverage-based minimization**：选取最小的测试集使覆盖率等价于原套件。断言覆盖版本：选取最小集使所有目标约束仍有至少一个用例覆盖。
2. **Fault-based minimization**：以 mutation testing 生成 mutant，删除未能杀死额外 mutant 的用例（比 coverage-based 更精确但更昂贵）。
3. **ILP formulation**：精确求解最小覆盖集，在大型套件上 NP-hard；近似（greedy）在实践中足够。
4. **Essential test cases**：某些用例是唯一覆盖某 fault 的"不可删除"用例，对应 awesome-skill-creator 的 P0 tier。

### 创新性

第一次系统比较三个维度（minimization vs selection vs prioritization）的工程权衡；提供了 80+ 篇论文的结构化分类，使领域导航成为可能。

### 实验设计

基于文献综述，分析各方法在真实开源软件（Unix 工具、Space、Siemens 套件等）上的对比数据；Rothermel 等人的实验数据表明平均删减 55-90%，但 fault detection 下降 0-20%。

### 局限性

1. 多数实验基于代码覆盖率（行/分支/路径），而 LLM eval case 的"覆盖"是语义层面，无法直接套用代码覆盖指标
2. Fault-based minimization 需要 mutation testing 基础设施，在 LLM skill 评测中不可用（LLM skill 的"mutant"无法系统生成）
3. 未考虑 oracle 本身也可能随时间退化的情况（awesome-skill-creator 的 judge_calibration 解决了这个 gap）

## 对当前 Skill 的价值

### 关键启发

**P2 归档是 subsumption-based minimization 的 only-increase 变体**：传统 minimization 删除被 subsume 的用例；P2 归档通过 `tier: P2 + superseded_by` 标记而非删除，使缩减可逆且可审计。这直接回应了 Rothermel 危险——P2 归档的 `--all-tiers` 审计通道确保被归档 case 在需要时可完整重现。

**Essential case = P0 tier 的类比**：Yoo & Harman 的"essential test cases"（唯一覆盖某 fault 的用例）在 awesome-skill-creator 中对应 P0 case——不可归档、不可弱化。P1 是 Greedy 首选但非 essential 的集合。P2 是已被更强用例 subsume 的归档层。

- **`suggest_p2_candidates.sh` 的理论基础**：该脚本实现了 assertion-level subsumption 检测，是 coverage-based minimization 的 LLM eval 变体

### 本地验证思路

- 在 `suggest_p2_candidates.sh` 的输出中，每个 CANDIDATE 应是"更强 case 通过则更弱 case 也必然通过"的子集关系——这可以通过在相同 fixture 上分别运行两个 case 并验证结论一致性来确认
- 可以测量：在当前 51 条 active case 中，strict subsumption 对的比例是多少？这是 only-increase 约束的"冗余压力"指标

### 不适用的部分

1. **代码覆盖率指标**不适用于 LLM eval：skill 输出没有代码行，无法计算 branch coverage。awesome-skill-creator 用"断言集合的 token 包含关系"替代
2. **Fault-based minimization** 需要 mutation testing，在 prompt-level skill 中不可行
3. **ILP 精确求解**对于 51 条 case 的套件没有必要，greedy（即 `suggest_p2_candidates.sh` 当前策略）已足够
