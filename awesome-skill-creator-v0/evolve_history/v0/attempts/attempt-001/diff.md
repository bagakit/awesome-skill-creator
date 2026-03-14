# Diff: Day 1 变更清单

## 新增文件

- `SKILL.md` — 最小 slash command 定义（name + description frontmatter）
- `process.md` — 10 步创建流程（Step 0 目标定义 → Step 9 归档）
- `scaffold.md` — 下游 skill 目录规范（目录约定 + eval case schema）
- `manifest.yaml` — 调度器字段 contract（name, version, status, bootstrap_completed 等）
- `evals/objective_cases.yaml` — append-only eval case 格式定义，含 `added_in` 字段

## 关键设计决策

### Only-Increase 原则（最关键创新）

eval case 只能新增，不能删除。删除 case 的后果：系统可以靠缩小承诺范围伪装成"更强"。
→ 每条 case 带 `added_in: vN` 字段，追溯 case 的引入版本

### 目录 contract

```
skill-name-vN/
  SKILL.md          # slash command
  process.md        # 执行流程
  manifest.yaml     # 调度元数据
  evals/
    objective_cases.yaml
```

### 被否决的方案

- **纯 prompt 方式（无结构化目录）**：被否决，因为每次创建结果不可复现，无法追溯失败原因
- **只有 SKILL.md，无 process.md**：被否决，因为没有过程记录，每次创建都是"一次性输出"

## 与上一代（基线，无协议）的对比

| 指标 | 无协议（基线） | Day 1（scaffold + only-increase） |
|------|---------------|-----------------------------------|
| 目录结构一致性 | 无 | 有（validate_structure 强制） |
| eval 追溯性 | 无 | 有（added_in 字段） |
| 防删 case 机制 | 无 | 有（only-increase 约束） |
| 进化历史 | 无 | 有（evolve_history/） |
