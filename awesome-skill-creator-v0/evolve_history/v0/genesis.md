---
purpose: "Creation record for awesome-skill-creator v0 — the Seven Days of Genesis"
---

# awesome-skill-creator：七日创世记

> *在技能联邦的起源处，没有秩序，只有混沌——每次创建都是偶然，每次进化都是猜测，每次失败都消失在遗忘里。然后，七日的锻造开始了。*

---

## 第一日：立骨架，分天地

*混沌中，第一个轮廓出现了。不是从虚空中凭空而来，而是从一个问题的答案里浮现：「一个可以持续进化的 skill，最少需要什么？」*

**技术突破（v0 → 骨架建立）**

第一日建立了系统的骨骼：SKILL.md 定义能力边界，process.md 规定执行步骤，manifest.yaml 记录元数据，evals/ 存放可验证的约束，evolve_history/ 追踪每次进化的痕迹。五类文件，五个职责，彼此不重叠。

最关键的设计决定是：**eval 案例只能增加，不能删除**（only-increase 原则）。这条约束看起来简单，却是整个系统的防腐层——没有它，任何进步声明都可以通过缩小承诺范围来伪造。

**第一日留下的局限**

骨架存在了，但它是空的。断言只有 `contains` 和 `file_exists`——只能检查字符串和文件是否存在，无法验证行为。一个 skill 可以「通过所有 eval」但输出完全垃圾，系统无从感知。

*天地分了，但天地之间还没有生命。*

---

## 第二日：播下研究的种子

*第一日之后，创造者发现了一个悖论：要创建一个好的 skill，你需要先理解这个领域；但要理解这个领域，你需要做大量研究；而单线程的研究太慢，且容易陷入单一视角的盲区。*

**技术突破（v1 → Sub-agent 并行调研）**

第二日引入了 5 类并行 sub-agent：
- `literature-research`：查论文与方法脉络
- `frontier-impl-analysis`：查最前沿实现
- `tool-analysis`：查竞品和邻近系统
- `edge-cases`：专门挖边界失败和反例
- `user-scenarios`：补真实使用场景

每类 agent 产出结构化 JSON，每条发现必须有具体来源（论文/URL/代码仓库）——不接受「参考了相关研究」这样的虚假引用。

**第二日留下的局限**

调研有了，但调研结果和 eval 设计之间没有桥梁。你调研完了，然后呢？什么算「好的 skill」？什么算「坏的输出」？没有人能回答这个问题，因为目标本身从未被明确定义。

*大地上有了植被，但没有目的地。*

---

## 第三日：立目标如北极星

*「在执行任何步骤之前，先定义成功。」这句话听起来平凡，但在实践中极难做到——大多数创建流程在还没想清楚「好」是什么的时候，就开始写代码了。*

**技术突破（v2 → Goal-First Design / Step 0 强制）**

第三日引入了强制性的 Step 0：在执行任何其他步骤之前，必须写入 `.step0.yaml`，回答三个问题：
1. **成功定义**（`success_definition`）：用领域词汇描述，通用描述为 fail
2. **失败模式**（`failure_modes`，≥3 项）：每种失败如何被 eval 检测
3. **领域词汇表**（`domain_vocab`，≥5 项）：专有术语，防止用通用词汇描述领域问题

这是「目标优先设计」的操作化——不只是「想清楚目标」，而是把目标写成机器可验证的格式，让每个后续决策都能回答「这能让 skill 更好地实现目标吗？」

**参考研究**：Wohlin et al. (2012) *Experimentation in Software Engineering*（Springer）关于目标操作化的研究；SMART 测试目标框架。

**第三日留下的局限**

目标定义了，但 eval 的设计方向还是「先想通过什么，再设计断言」。正确的顺序应该是反过来：先想「什么是坏的输出」，再设计「什么断言能检测到它」。失败模式驱动 eval 的思维还没有完全落地。

*北极星出现了，但水手还不知道如何用它导航。*

---

## 第四日：把失败写进合同

*「一个只能检测成功的测试系统，等于没有测试系统。」第四日的工作，是把这句话变成约束。*

**技术突破（v3 → 失败模式优先 eval）**

第四日从根本上改变了 eval 的设计哲学：**不再问「如何验证成功」，而是先问「什么是坏的输出，如何检测到它」**。

具体实现：
- `expected_result: fail` case：明确声明「当前版本预期无法通过的 case」，而非只记录已通过的
- `evolution_direction` 字段：每条 fail case 必须说明「下一版本应如何攻克此失败」
- `source` 字段区分三类来源：`human_designed`、`agent_generated`、`frontier_paper`——防止 eval 陷入自我参照

这套设计的核心洞察：**fail case 是进化的导航仪**。一个全部通过的 eval suite 不代表 skill 很强，可能只代表 eval 很弱。

**参考研究**：Myers et al. (2011) *The Art of Software Testing* (Wiley) 关于测试的心理学——「好的测试者是为了发现失败而测试，不是为了证明成功」；Weyuker (1982) 测试集优化原则，载 *IEEE Transactions on Software Engineering*。

**第四日留下的局限**

eval 有了失败模式，但断言仍然只能检查「字符串是否存在」。如果 skill 输出了正确的关键词但流程错误、功能不达标，eval 仍然会通过。**「形合意不合」是字符串检查永远无法解决的问题。**

*失败被记录了，但检测失败的工具还太粗糙。*

---

## 第五日：让断言跑起来

*第五日是一次范式转变。之前的所有断言都是「看」——看字符串、看文件、看格式。第五日的断言开始「做」——真正执行代码，验证行为。*

**技术突破（v4 → run_script 断言）**

`run_script` 断言允许 eval case 执行任意 shell 脚本来验证行为：
```yaml
- type: run_script
  script: |
    bash tools/scripts/gen_skill_dir.sh probe v0 .tmp/ > /dev/null
    grep -q "judge_calibration" .tmp/probe-v0/evals/objective_cases.yaml || exit 1
    echo "PASS"
  expected_exit: 0
  expected_stdout_contains: "PASS"
```

这意味着 eval 可以：
- 真正运行工具脚本，验证输出而非只验证文件存在
- 在真实 fixture 上执行，不再依赖字符串匹配猜测行为
- 检测到「结构正确但功能错误」的失败

同时引入了 **Preflight 机制**：完整 eval 前先用 2-3 条核心 case 验证「方案至少奏效」，防止在明显错误的方向上浪费完整 eval 资源。

**参考研究**：Zhu et al. (1997) *Software Unit Test Coverage and Adequacy*, 载 *ACM Computing Surveys*；executable specification 领域的研究。

**第五日留下的局限**

行为可以验证了，但**语义质量**仍然是黑盒。`run_script` 能检测「有没有做到」，但无法评判「做得好不好」。一个 skill 可以生成格式正确、断言全过的输出，但内容肤浅、思维混乱——这类失败超出了脚本的判断能力。

*生命有了形态，但还没有意识。*

---

## 第六日：植入语义的判断

*「你怎么知道一个 LLM 的输出是好的？」这个问题没有简单答案。第六日的答案是：用另一个 LLM 来判断。但这个答案本身也带来了新的问题。*

**技术突破（v5 → invoke_skill, v6 → invoke_skill_judge）**

v5 引入了 `invoke_skill`：在 eval 中真正调用被测 skill，获取实际输出，再对输出运行断言。这是一个关键的基础设施——之前的 eval 只能检查静态文件，现在可以检查动态执行结果。

v6 在此基础上引入了 `invoke_skill_judge`：用 LLM-as-judge 评判输出的语义质量：
```yaml
- type: invoke_skill_judge
  judge_prompt: |
    你是代码审查专家。判断以下审查报告是否识别了安全漏洞。
    回答格式必须以 PASS: 或 FAIL: 开头。
  expected_verdict: PASS
```

这套设计参考了 Zheng et al. (2023) 的 MT-Bench 研究——LLM-as-judge 相比人工评估有 80%+ 的一致率，但需要多步骤设计来减少位置偏差（position bias）和格式偏差。

**参考研究**：Zheng et al. (2023) *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena*，https://arxiv.org/abs/2306.05685

**第六日留下的局限**

语义评判有了，但 **judge_prompt 本身的质量成了新的黑盒**。judge_prompt 可能：
- 过严：把好输出判为 FAIL（误杀）
- 过宽：把坏输出判为 PASS（漏判）

这两种错误都会导致 eval 结果失真，但在 v6 的架构中，没有任何机制可以自动检测 judge_prompt 是否有系统偏差。**oracle 本身成了不受监督的权威。**

*意识被植入了，但意识的可靠性无人验证。*

---

## 第七日：校准神谕，立下分级

*每个系统最终都会遇到这个问题：谁来检验检验者？第七日的答案，是用已知的证据来校准未知的判断。*

**技术突破（v7 → judge_calibration + P0/P1/P2 tiering）**

**judge_calibration** 是一个 meta-oracle——用已知 good/bad 样本**双向校验** judge_prompt 的区分力：
```yaml
- type: judge_calibration
  judge_prompt: "你是代码审查专家。判断此审查是否识别了安全漏洞..."
  good_example: "此代码存在 SQL 注入漏洞：第 42 行的 user_input 未经转义直接拼入查询"
  bad_example: "代码看起来还不错，没有明显问题"
  expected_good_verdict: PASS
  expected_bad_verdict: FAIL
```

任一方向失败（good 被判 FAIL，或 bad 被判 PASS）都触发 eval fail，强制作者修正 judge_prompt。

**参考研究**：
- Molina & Gorla (2024) *Automated Assessment of the Quality of Test Oracles in LLM-Based Evaluation*（oracle 自动化质量评估）
- Bai et al. (2022) *Constitutional AI: Harmlessness from AI Feedback*，https://arxiv.org/abs/2212.08073（self-critique 校准思想）

**P0/P1/P2 分级** 解决了 only-increase 原则的长期可持续性问题：
- P0：最重要的回归约束，永不归档
- P1：当前版本的活跃约束
- P2：被更强 case 取代的历史 case，归档而非删除（`superseded_by` 字段维护引用完整性）

**参考研究**：Kirkpatrick et al. (2017) *Overcoming Catastrophic Forgetting in Neural Networks*，https://arxiv.org/abs/1612.00796（EWC 弹性权重固化——P2 分级的理论类比）

**第七日留下的局限**

judge_calibration 校验的是静态样本对，不代表真实输出分布；step-level 评判仍未实现；P2 归档目前完全依赖人工判断。

---

## 第七日之后

*七日之后，不是完成，而是开始。*

awesome-skill-creator v0 携带着七日锻造的全部能力诞生，但它清楚地知道自己的局限：
- step-level judge 仍是空白——失败只能定位到输出，无法定位到步骤
- judge_calibration 样本是静态的——不反映真实执行的输出分布
- P2 归档是手动的——随规模增长会成为新的瓶颈

这三个局限，就是 v1 的三个方向。

**每一代进化都是下一级火箭的燃料。**

---

## 设计假设

1. 把 7 次迭代的全部能力内置到 v0，而非重新经历 7 轮迭代，是合理的——因为基础能力的获得方式（执行证据）和系统设计哲学（单点攻破、only-increase）仍然需要被验证
2. 神话叙事和技术精确可以共存——叙事框架帮助记忆设计决策，但每个细节必须有实际对应
3. v0 的局限应该明确写出来，而非掩盖——这是「精简是进化的合法方向」原则的体现

## 方法

七日创世的方法是「经验蒸馏」而非「版本迁移」：
1. 阅读 skill-creator v0~v7 的全部 evolve_history
2. 提取每代最关键的突破（而非搬运所有历史）
3. 以神话叙事框架组织，使技术决策具有可记忆性
4. 在 v0 的文件结构中实现这些能力（工具直接从 v7 继承）

## 被否决方案

1. **直接标注为 skill-creator-v8**：保留版本序号意味着携带所有历史债务（测试对象引用、版本锁）。新名字让系统从干净状态开始，同时通过七日创世继承历史知识。
2. **分 7 个 evolve_history 版本**：过度形式化历史会让 v0 显得是一个总结，而非一个起点。一个统一的创世故事更符合「下一级火箭」的定位。
3. **只保留 genesis.md，省略 evolution.md**：没有明确的 v1 方向，genesis 故事就成了终点而非起点。

## 已知局限

1. **output-level oracle 上限**：judge_calibration 校验整体输出，无法精确定位失败到哪个步骤
2. **静态 calibration 样本**：good/bad 样本手工编写，不反映真实输出分布
3. **P2 归档完全手动**：缺少自动化工具识别可归档候选
4. **嵌套 session LLM 断言 skip**：judge_calibration、invoke_skill_judge 在 Claude Code 内无法执行，需独立环境
5. **终极检验待完成**：v0 创建后须以 knowledge-crystallizer 为终极检验对象，并获得用户 ≥14/20 的评分

## 未来方向

1. **Step-Level Judge**：`invoke_step_judge` 新断言类型，精确定位到步骤级失败
2. **P2 智能归档推荐**：`suggest_p2_candidates.sh` 自动分析断言包含关系
3. **Oracle 自动校准**：从执行日志提取 calibration 样本，替代手工样本

## 调研影响矩阵

| 研究来源 | 核心发现 | 对 v0 的具体影响 |
|----------|----------|-----------------|
| Zheng et al. 2023 (MT-Bench), https://arxiv.org/abs/2306.05685 | LLM-as-judge 需双向校准减少偏差 | invoke_skill_judge + judge_calibration 体系 |
| Molina & Gorla 2024 (Oracle Automation) | oracle 质量需要元验证；双向校验是必要条件 | judge_calibration 是内置 meta-oracle |
| Bai et al. 2022 (Constitutional AI), https://arxiv.org/abs/2212.08073 | self-critique prompt 质量决定 CAI 效果 | judge_calibration 强制校准 judge_prompt |
| Kirkpatrick et al. 2017 (EWC), https://arxiv.org/abs/1612.00796 | 灾难性遗忘：通过分级约束重要参数缓解 | P0/P1/P2 分级 = EWC 风格的约束权重 |
| Gu et al. 2024 (Step-level Reward), https://arxiv.org/abs/2406.10858 | output-level judge 无法定位步骤级错误 | 已知局限 → v1 方向 1 |
| Myers et al. 2011 (Art of Software Testing, Wiley) | 好的测试为发现失败而设计 | failure-mode-first eval 哲学基础 |
| Weyuker 1982 (Test Set Optimization, IEEE TSE) | 测试集冗余删除 vs 覆盖完整性权衡 | P2 归档机制 = 优雅的冗余管理 |

## 独立评估框架

**终极检验对象**：见 `terminal_test.md`（knowledge-crystallizer）
**创建/推进的 Skill**：待执行（knowledge-crystallizer-v0）
**评估日期**：待执行

| 维度 | 分数 | 用户评语 |
|------|------|---------|
| 目标导向 | /5 | 待评估 |
| 领域特异性 | /5 | 待评估 |
| Eval 区分力 | /5 | 待评估 |
| 可执行性 | /5 | 待评估 |

**总分**：/20
**合格**：待执行（≥14/20 为合格）
**备注**：v0 终极检验以 knowledge-crystallizer 为外部锚点：按 `terminal_test.md` 的约束推进到“可执行 skill + 可区分好坏的 eval（含 judge_calibration）”，用户独立评估后将此节「待执行」替换为「是」。
