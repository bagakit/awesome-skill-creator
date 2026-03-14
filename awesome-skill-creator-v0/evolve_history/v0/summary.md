# awesome-skill-creator v0 版本摘要

- **状态**：active
- **攻克的优化点**：将 skill-creator v0-v7 七次迭代积累的全部能力凝结为 awesome-skill-creator 的干净起点
- **eval 通过率**：待 validate.sh --ship 实际执行后填入
- **相比上版本的提升**：新家族名（awesome-skill-creator），继承全部七代能力，genesis 叙事统一记录进化逻辑，工具链直接从 v7 继承
- **已知局限**：output-level oracle（无 step-level judge）；静态 calibration 样本；P2 归档手动

## 本版本做了什么

将 skill-creator v0-v7 七次迭代积累的全部能力凝结为 awesome-skill-creator 的起点：

- Goal-First Design（.step0.yaml 强制，v0 代 heritage）
- 5 类 Sub-agent 并行调研（v1 代 heritage）
- 失败模式优先 eval（v3 代 heritage）
- run_script 行为验证（v4 代 heritage）
- invoke_skill_judge LLM-as-judge（v5/v6 代 heritage）
- judge_calibration meta-oracle（v7 代 heritage）
- P0/P1/P2 分级（v7 代 heritage）
- 三层分发体系 runtime/quality/build（v7 代 heritage）
- tools/gate + tools/scripts 结构化（v7 代 heritage）

## 本版本未做什么（留给 v1）

- Step-level judge（invoke_step_judge）
- P2 智能归档推荐（suggest_p2_candidates.sh 的 subsumption 分析）
- Oracle 自动校准（从执行日志提取 calibration 样本）

## 进化轨迹

本版本是 awesome-skill-creator 的第一级火箭。v1 的首要任务不是「多创建几个 skill」，而是「通过 step-level judge 让进化的归因能力从 output-level 提升到 step-level」。
