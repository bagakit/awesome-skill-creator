# ref_card_gen.md — 参考卡片生成提示词

> Prompt template for generating structured reference cards from a paper/book/repo.
> Use with Claude Code: paste this prompt, fill in `{SOURCE}`, and Claude generates the card.

---

## 使用方式

```
请为以下来源生成一张参考卡片，输出到 evolve_history/vN/assets/references/ref_{slug}.md。

来源：{SOURCE TITLE, AUTHORS, YEAR, URL/DOI}
Skill 背景：{SKILL NAME and what it does}
关联点：{How this source relates to the Skill}
```

---

## 参考卡片格式

```markdown
---
summary: "{One-sentence description of this source}"
type: paper  # paper | book | repo | blog | doc | spec | talk
relevance: high  # high | medium | low
---

# {Title}

## 书目信息

**作者**：{Authors}
**年份**：{Year}
**来源**：{Conference/Journal/URL}
**DOI/Link**：{DOI or URL}

## 影响力与同类对比

{Who cites this? What's its h-index/star count? How does it compare to related work?}

## 核心方法分析

### 问题定义
{What problem does this work address?}

### 结论
{Main takeaways in 2-3 sentences}

### 核心类比
{Best analogy to explain the core idea}

### 技术机制
{How it works technically}

### 创新性
{What's genuinely novel vs prior work?}

### 实验设计
{How claims are validated; key datasets/benchmarks}

### 局限性
{What this work does NOT address or where it breaks down}

## 对当前 Skill 的价值

### 关键启发
**{Bold the most actionable insight}**: {Explanation}
- {Additional insight}

### 本地验证思路
- 如何在本 Skill 的 eval suite 中测试这个思路？
- {Concrete eval case idea}

### 不适用的部分
{What aspects of this work don't apply to our Skill, and why}
```

---

## 质量检查清单（生成后验证）

- [ ] frontmatter 含 summary / type / relevance
- [ ] type ∈ {paper, book, repo, blog, doc, spec, talk}
- [ ] relevance ∈ {high, medium, low}
- [ ] 核心方法分析含 7 子节（问题定义/结论/核心类比/技术机制/创新性/实验设计/局限性）
- [ ] 「不适用的部分」非空（不能写「全部适用」）
- [ ] 「关键启发」含至少 1 处 `**...**` 加粗
- [ ] 文件名格式：`ref_{author}_{year}_{slug}.md`（如 `ref_zheng_2023_mt_bench.md`）
- [ ] 引用验证：Article 正文中引用了此卡片名
