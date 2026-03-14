# awesome-skill-creator v0 — 终极检验（Terminal Test）说明

本文件是 `awesome-skill-creator-v0` 唯一的“终极检验/外部锚点”说明入口，目的是避免在执行与迭代时被目录结构混淆。

## 终极检验对象（外部锚点）

终极检验对象固定为仓库根目录下的：

- `../knowledge-crystallizer/project_plan/PRD.md`

该 PRD 是需求与约束的单一事实来源（SSOT）。

## 为什么需要终极检验

客观层 eval / judge_prompt / case 设计都可能存在自我参照偏差。终极检验要求把 v0 交付到一个真实 domain（knowledge-crystallizer），并由用户独立按四维评分（总分 ≥14/20），作为唯一外部锚点。

## 合格标准（与 v0 release checklist 对齐）

- 输出一个可执行的 `knowledge-crystallizer` skill（包含 `judge_calibration` 断言 ≥1 条）
- 用户独立评估四维度：目标导向 / 领域特异性 / Eval 区分力 / 可执行性
- 总分 ≥ 14/20，且无单维度 ≤ 2

## 交付物边界

- `awesome-skill-creator-v0` 的分发包（dist）不应包含终极检验对象目录；终极检验对象属于仓库工作区层面的外部锚点。
- 终极检验对象的文献调研、里程碑、开放问题等内容，统一写在 `../knowledge-crystallizer/project_plan/`。
