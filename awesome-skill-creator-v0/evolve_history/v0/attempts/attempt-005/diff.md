# Diff: Day 5 变更清单

## 新增断言类型

- `run_script` — 在 fixture 目录上执行 shell 脚本，用 exit code 判断通过/失败
  - fixture 路径：`.tmp/eval/<skill>_<version>/`
  - 脚本路径：相对于 skill 根目录的 `tools/gate/` 脚本

## 新增约定

- `.tmp/` 加入 `.gitignore`，不进版本库
- fixture 目录命名规范：`.tmp/eval/<skill-name>_<version>/`
- run_script 断言的 timeout 默认 30 秒

## 关键设计决策

### 真实执行 vs Mock

run_script 必须在真实 fixture 上执行，不接受 mock 通过（白皮书约束 11）。
→ 断言失败时的 exit code 比"找不到关键词"更精确的错误信号

### 隔离机制

评测时创建的 fixture 目录必须在 .tmp/ 下，不能在项目根目录散落。
→ 防止评测产物被误认为是正式文件

## 与 Day 4 的对比

| 指标 | Day 4 | Day 5 |
|------|-------|-------|
| 断言类型 | contains/not_contains | + run_script |
| 检测功能错误 | 弱（文本匹配） | 强（脚本执行） |
| fixture 隔离 | 无约定 | .tmp/ 强制 |
