# Attempt 005：Day 5 — run_script 可执行断言

**target_point**: 消除"结构通过但功能错误"的评测盲区

**假设**: 如果 eval 断言从"文件存在 + 内容包含"升级到"在真实 fixture 上运行脚本并检查 exit code"（run_script），则能发现纯 contains 断言无法发现的功能性错误。

**核心机制验证**：
1. run_script 断言是否能在 fixture skill 目录上执行真实验证脚本？
2. run_script 能发现哪些 contains 断言发现不了的错误？
3. fixture 目录隔离到 .tmp/ 是否防止了评测污染主目录？

## 研究背景

Day 4 的 eval 包含 fail case 和 evolution_direction，但断言类型仍然是 contains/not_contains。这类断言只能检查"文本是否出现"，不能检查"脚本是否可执行"或"生成的文件是否通过验证"。

典型盲区：
- SKILL.md 存在且含关键词，但 YAML frontmatter 格式错误（contains 看不出来）
- process.md 包含正确步骤描述，但步骤顺序错乱（contains 看不出来）
- evals/objective_cases.yaml 存在，但 YAML 解析失败（contains 看不出来）

## 预期证据

1. 在同一组 fixture 上，run_script 发现了 2 个 contains 断言未发现的格式错误
2. .tmp/ 隔离机制使得评测不污染项目根目录
3. run_script 的 exit code 判断比 contains 的文本匹配更精确

## Expected Outcome

run_script 断言类型加入 eval schema，配合真实 fixture（.tmp/eval/<skill>_<version>/），使评测从"看形状"升级到"跑脚本"。
