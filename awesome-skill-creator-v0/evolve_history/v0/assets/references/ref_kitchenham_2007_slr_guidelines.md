---
name: ref_kitchenham_2007_slr_guidelines
summary: 软件工程系统文献综述指南，提出 PICOC 框架（Population/Intervention/Comparison/Outcome/Context）用于在搜索之前标准化问题陈述，防止带预设方案进行文献检索
type: methodology
relevance: 直接支撑 self-bootstrap.md Phase 2.P 的"问题陈述优先"设计——搜索前强制填写 PICOC problem_statement，避免闭门造车式的"文献验证"而非真正调研
---

# Kitchenham & Charters (2007) — Guidelines for performing Systematic Literature Reviews in Software Engineering

**Authors**: Barbara Kitchenham, Stuart Charters
**Year**: 2007
**Venue**: EBSE Technical Report, Keele University & Durham University
**URL**: https://www.elsevier.com/books/guidelines-for-performing-systematic-literature-reviews-in-software-engineering/kitchenham/978-0-12-815510-7
**Verified**: 2026-03-16

## 核心发现

系统文献综述（SLR）需要在执行搜索之前完成正式的**研究问题陈述**，其结构化框架 PICOC：
- **P**opulation：研究对象是什么
- **I**ntervention：被评估的方法/工具是什么
- **C**omparison：对比基准是什么
- **O**utcome：关注的可量化结果是什么
- **C**ontext：适用场景/约束是什么

核心洞见：**问题陈述决定搜索词质量**。未经 PICOC 标准化直接搜索，容易带预设方案去"验证"而非"发现"，产生确认偏误（confirmation bias）。

## 对本 Skill 设计的影响

- `self-bootstrap.md Phase 2.P` 的 `problem_statement` 字段结构直接采用 PICOC 简化版
- 强制规定"PICOC 在搜索之前完成"这一顺序约束来源于此
- `design_source` 字段区分 `frontier_paper / self_invented` 的必要性也来源于此框架对"可重复性"的要求
