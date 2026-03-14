---
summary: "PromptFoo's CI-integrated LLM testing and red-teaming patterns directly inform awesome-skill-creator's only-increase eval philosophy and P0/P1/P2 assertion tiering"
type: repo
relevance: medium
---

# PromptFoo (2024) — promptfoo: Test Your Prompts, Agents, and RAGs

## 书目信息
- **Authors**: PromptFoo (Ian Webster et al.)
- **Year**: 2024
- **Venue**: GitHub Open Source Repository
- **Links**: [GitHub](https://github.com/promptfoo/promptfoo)
- **Verified**: 2026-03-14

## 影响力与同类对比
- **影响力指标**: GitHub 5k+ stars；LLM 开发者 CI/CD 工具链的代表；被多家商业团队用于生产 LLM 测试
- **领域定位**: LLM 系统测试自动化；prompt 回归测试；红队测试
- **同类对比**: OpenAI Evals 更面向静态 benchmark；PromptFoo 更面向开发者工作流中的动态测试（每次代码/prompt 变更时自动运行）；awesome-skill-creator 借鉴 PromptFoo 的 CI 哲学，但针对 skill 创建期而非发布后回归

## 核心方法分析

### 问题定义
LLM 应用开发中，如何确保每次 prompt 变更不引入退化（regression）？如何在开发过程中系统地测试多种 prompt 变体？

### 结论
将 LLM 测试集成到 CI/CD 流水线，通过声明式 YAML 配置定义测试套件，支持多 provider 并行对比（A/B testing of prompts），并通过 threshold 而非 exact match 判断通过/失败；红队测试（red-teaming）模块可自动生成对抗性输入检测安全漏洞。

### 核心类比
**PromptFoo 的 regression test 哲学 = awesome-skill-creator 的 only-increase eval 哲学**：两者都要求新版本的 eval 通过率不低于旧版本——即 eval 是防退化的安全网，而不仅是功能验证。

### 技术机制
1. **YAML test config**：声明 prompts、providers（LLM 模型）、test cases（输入 + assertion）
2. **Assertion types**：contains、icontains、starts-with、regex、javascript（自定义函数）、llm-rubric（LLM-as-judge）
3. **Threshold scoring**：每个 test case 可设 score 阈值，而非强制 pass/fail
4. **Provider comparison**：同一 test suite 在多个 provider 上并行运行，输出对比报告
5. **Red-teaming**：自动生成注入攻击、越狱尝试，测试 LLM 应用的鲁棒性

### 创新性
第一个将 LLM 测试与 CI/CD（GitHub Actions）原生集成的开源框架；llm-rubric assertion 类型是 invoke_skill_judge 的工程化前身。

### 实验设计
开源框架，通过文档案例和社区最佳实践验证；提供可对比的 benchmark 报告格式。

### 局限性
1. 测试套件仍需手工设计，未实现测试用例自动生成
2. llm-rubric 的 judge 校准问题（calibration）需用户自行处理
3. 主要面向 API-style LLM 调用，对 agent 型 skill 的测试支持有限

## 对当前 Skill 的价值

### 关键启发
**only-increase eval 的操作定义来自 PromptFoo 的 regression test 模式**：awesome-skill-creator 的 eval score 只能在新版本中保持或提升，不允许退化——这与 PromptFoo "每次 CI 运行都必须通过上次通过的所有 test cases"是同一哲学的不同表达。

**P0/P1/P2 assertion 分层**借鉴了 PromptFoo 的 threshold scoring：P0 assertions 对应高 threshold（必须 100% 通过）；P1/P2 对应低 threshold（允许一定失败率）。

**run_script assertion 的 JavaScript 自定义函数**形式参考了 PromptFoo 的 javascript assertion type：允许用代码精确表达无法用自然语言描述的验证逻辑。

### 本地验证思路
将 PromptFoo 与 awesome-skill-creator 生成的 skill 的 eval 对接：导出 skill eval cases 为 PromptFoo YAML 格式，验证两个框架在相同 test cases 上的通过/失败判断是否一致。

### 不适用的部分
PromptFoo 的 provider comparison（多模型 A/B 测试）在 awesome-skill-creator 的 skill 创建流程中不直接适用——skill 针对特定模型创建，跨模型比较不是主要场景。PromptFoo 的 red-teaming 模块针对安全问题，而 awesome-skill-creator 的 eval 针对功能质量，两者关注点不同。
