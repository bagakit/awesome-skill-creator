# Attempt 001：Day 1 — Scaffold + Only-Increase 原则

**target_point**: 建立可自演化 skill 系统的最小可行骨架

**假设**: 如果给 skill 创建过程建立标准目录骨架（SKILL.md + process.md + manifest.yaml + evals/）并引入 append-only eval 约束，则系统可以开始有意义的进化——即使评测能力还非常基础。

**核心机制验证**：
1. 标准目录骨架是否足够描述一个可执行的 skill？
2. append-only eval 约束（只允许新增 case，不允许删除）是否防止了进度伪造？
3. 骨架生成是否可重复（gen_skill_dir.sh 可以创建符合规范的空骨架）？

## 研究背景

v0 之前没有"skill 创建协议"。每次创建 skill 都是特设性的，没有统一的目录约定、eval 格式或进化追踪机制。这使得每个 skill 都是孤立的，无法系统性地改进。

## 预期证据

1. `gen_skill_dir.sh <name> v0` 生成符合目录规范的骨架，validate_structure 全通过
2. 骨架包含 `evals/objective_cases.yaml` 和 `SKILL.md` + `process.md`
3. eval case 格式包含 `added_in` 字段，支持版本追溯

## Expected Outcome

建立目录 contract 和 eval append-only 原则，证明"结构化 skill 创建"比特设创建更可追溯。
