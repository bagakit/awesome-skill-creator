---
name: ref_neurips_2024_reproducibility_checklist
summary: NeurIPS 2024 论文可重现性清单，定义了 AI/ML 论文的最低质量标准：每项声明必须有理论或实验支撑，局限性必须量化，系统描述必须可重现，是 arxiv 可发表性的权威操作定义
type: methodology
relevance: 直接支撑 objective_cases.yaml 中的 article_arxiv_quality judge_calibration 和 invoke_skill_judge 两条 eval cases 的 judge_prompt 设计标准；提供"哪些是好 abstract / 坏 abstract"的可判断维度
---

# NeurIPS 2024 — Paper Checklist (Reproducibility & Quality)

**Source**: NeurIPS 2024 Call for Papers
**URL**: https://neurips.cc/public/guides/PaperChecklist
**Verified**: 2026-03-16

## 核心质量标准（与 awesome-skill-creator 直接相关）

### 1. 声明与证据对齐（Claims ↔ Evidence）
每项贡献声明必须：
- 有实验数据支撑（含具体数字，不是"实验表明"）
- 或有引用文献支撑（不是"相关工作表明"）
- 或有理论推导支撑

**arxiv bad pattern**："我们提出了一个框架，能有效提升 skill 质量" → 无效声明
**arxiv good pattern**："judge_calibration 在 5 个领域的 24 个 eval case 中将 judge 偏差检出率从 0% 提升至 83%（见 §4.2）" → 有效声明

### 2. 局限性必须量化（Quantified Limitations）
Limitations 节不能只有描述性语言。必须包含：
- 量化的失败率或错误率
- 具体场景下的能力边界
- 不适用的条件说明

**arxiv bad pattern**："本系统仍有一些局限，未来工作将解决" → 无效
**arxiv good pattern**："约 40% 的 evolution_direction 条目只能指向 general area，无法定位到具体 step（见 §4.4 Limitation 1）" → 有效

### 3. 可重现性（Reproducibility）
系统描述必须包含足够让第三方复现的细节：
- 环境/依赖版本
- 关键参数值
- 执行流程

### 4. 相关工作差异定位（Related Work Positioning）
Related Work 不是列举，而是定位：每篇引用文献应该回答"本工作与之有何不同"，而不只是"X 做了 Y"。

## 对本 Skill 设计的影响

- `objective_cases.yaml` 新增 `article_arxiv_judge_calibration` 的 good/bad 样本设计依据
- `objective_cases.yaml` 新增 `article_arxiv_invoke_skill_judge` 的三维 judge_prompt 设计依据
- 文章 §4.4 Limitations 的量化要求（"~40% of failure diagnoses"）符合 NeurIPS checklist 标准
- 文章 §2 Related Work 每节末尾加"how this work differs"的改进依据
