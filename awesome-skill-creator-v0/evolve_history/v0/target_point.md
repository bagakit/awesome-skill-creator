# v0 Target Point

## 目标/Goal

**本版本攻克的核心问题**：将 7 代 skill-creator 积累的全部能力凝结为一个干净的起点——不是把历史版本打包，而是把经验蒸馏为能力。

创建一个从诞生起就内置 goal-first、failure-mode-first eval、judge_calibration、P0/P1/P2 分级等全部七代突破的 meta skill，让每次新 skill 的创建都能从这个完整基线出发。

## 瓶颈/Bottleneck

**为什么现有方案（直接用 skill-creator-v7）不够好**：

1. **历史债务**：skill-creator-v7 携带了 v0~v6 的所有版本标记、测试对象引用（如 `target: skill-creator-v7`）、格式残留。新系统不应该从这些历史债务中继承。

2. **名称锁定**：skill-creator 的版本序号（v7, v8...）将系统锁定在一条线性升级路径上。awesome-skill-creator 作为新家族名，让系统从干净状态开始，同时携带前 7 代的全部能力。

3. **创世记录缺失**：skill-creator-v7 有 7 个独立的 evolve_history 版本，但没有一个统一的「七日创世」叙事来说明这 7 代突破的逻辑和意义。新系统需要这份传承文档。

## 放弃的替代点

1. **逐步迁移（从 skill-creator-v7 逐步重命名）** → 拒绝：会携带历史债务（版本标记、测试 target 引用、格式残留），无法实现「一切从头开始」的干净状态

2. **仅做表面重命名不改内容** → 拒绝：无法实现「一切从头开始」的干净状态，genesis.md 也无法体现「七日创世」的叙事

3. **保留 v0-v7 全部独立 evolve_history 版本** → 拒绝：形式大于内容，genesis 叙事比历史清单更有传承价值；7 个版本历史对 v0 的使用者来说是噪音而非信息

4. **标注为 skill-creator-v8** → 拒绝：仍然锁定在旧家族名下，且 v8 的语义暗示「从 v7 演化」而非「七代能力的集大成者」
