#!/usr/bin/env bash
# gen_ref_card.sh — Generate a reference card template
# Usage: gen_ref_card.sh <title> <output-dir>
# Example: gen_ref_card.sh "Smith 2024 Attention" ./assets/

set -euo pipefail

TITLE="${1:?Usage: gen_ref_card.sh <title> <output-dir>}"
OUTPUT_DIR="${2:?Usage: gen_ref_card.sh <title> <output-dir>}"

# Generate filename from title
filename=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-z0-9_')
output_file="$OUTPUT_DIR/ref_${filename}.md"

if [[ -f "$output_file" ]]; then
  echo "Error: file already exists: $output_file"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

cat > "$output_file" << 'REFCARD_EOF'
---
summary: "{TODO: ≤30 characters, value-focused summary to current Skill}"
type: "{TODO: paper|book|repo|blog|doc|spec|talk}"
relevance: "{TODO: high|medium|low}"
---

# {TODO: Full Title}

## 书目信息

- **Authors**: {TODO}
- **Year**: {TODO}
- **Venue**: {TODO: journal/conference/publisher}
- **Links**: [{TODO: title}]({TODO: url})
- **Verified**: {TODO: yyyy-mm-dd}

## 影响力与同类对比

{TODO: Field position, citation impact, practical adoption}

**同类工作对比**:
1. {TODO: Similar work 1} — {TODO: key difference}
2. {TODO: Similar work 2} — {TODO: key difference}

## 核心方法分析

### 问题定义

{TODO: What problem does this work address?}

### 结论

{TODO: Main findings/results}

### 核心类比

{TODO: Non-specialist language analogy for the core idea}

### 技术机制

{TODO: How it works technically}

### 创新性

{TODO: What's novel compared to prior work}

### 实验设计

{TODO: How were claims validated?}

### 局限性

{TODO: Known limitations of the work}

## 对当前 Skill 的价值

### 关键启发

- **{TODO: Most important insight}**: {TODO: explanation}
- {TODO: Additional insight}

### 本地验证思路

{TODO: How to verify this work's claims in our context}

### 不适用的部分

{TODO: What aspects don't apply to our use case and why — this section must not be empty}
REFCARD_EOF

echo "✓ Created: $output_file"
echo "  Fill in all {TODO} placeholders."
echo "  Quality gate: summary has Skill perspective? URLs verified? Core analogy non-specialist? ≥1 bold insight? 不适用 populated?"
