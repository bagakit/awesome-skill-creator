#!/usr/bin/env bash
# validate_ref_cards.sh — Validate reference card format and content
# Usage: validate_ref_cards.sh <assets-dir>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

ASSETS_DIR="${1:?Usage: validate_ref_cards.sh <assets-dir>}"

echo "[Ref Cards: $ASSETS_DIR]"

if [[ ! -d "$ASSETS_DIR" ]]; then
  fail "Assets directory not found: $ASSETS_DIR"
  summary
  exit $_EXIT_CODE
fi

# Find all ref card files
ref_cards=()
while IFS= read -r f; do
  ref_cards+=("$f")
done < <(find "$ASSETS_DIR" -maxdepth 1 -name "ref_*.md" 2>/dev/null | sort)

if [[ ${#ref_cards[@]} -eq 0 ]]; then
  fail "No ref_*.md files found in $ASSETS_DIR"
  summary
  exit $_EXIT_CODE
fi

pass "Found ${#ref_cards[@]} reference card(s)"

for card in "${ref_cards[@]}"; do
  card_name="$(basename "$card")"
  echo "  --- $card_name ---"

  # Naming convention: ref_{author}_{year}_{slug}.md (scaffold.md §参考卡片)
  # Accept: ref_*_YYYY_*.md (year separated by underscores) OR ref_*YYYY_*.md (year embedded in author token)
  if [[ "$card_name" =~ ^ref_.*[0-9]{4}.*\.md$ ]]; then
    pass "$card_name: naming convention matches ref_{author}_{year}_{slug}.md"
  else
    warn "$card_name: naming convention should be ref_{author}_{year}_{slug}.md (scaffold.md §参考卡片 — include 4-digit year)"
  fi

  # Frontmatter fields: summary, type, relevance
  for field in "summary" "type" "relevance"; do
    if grep -q "^${field}:" "$card" 2>/dev/null; then
      pass "$card_name: frontmatter '$field' present"
    else
      fail "$card_name: frontmatter '$field' missing"
    fi
  done

  # type enum
  type_val=$(grep "^type:" "$card" 2>/dev/null | head -1 | sed 's/^type:\s*//' | tr -d '"' | tr -d "'" | xargs)
  if [[ "$type_val" =~ ^(paper|book|repo|blog|doc|spec|talk)$ ]]; then
    pass "$card_name: type '$type_val' is valid"
  else
    fail "$card_name: type '$type_val' not in {paper, book, repo, blog, doc, spec, talk}"
  fi

  # relevance enum
  rel_val=$(grep "^relevance:" "$card" 2>/dev/null | head -1 | sed 's/^relevance:\s*//' | tr -d '"' | tr -d "'" | xargs)
  if [[ "$rel_val" =~ ^(high|medium|low)$ ]]; then
    pass "$card_name: relevance '$rel_val' is valid"
  else
    fail "$card_name: relevance '$rel_val' not in {high, medium, low}"
  fi

  # 书目信息 required sub-fields: Verified date (scaffold.md §参考卡片)
  if grep -qiE "\*\*Verified\*\*:\s*[0-9]{4}-[0-9]{2}-[0-9]{2}" "$card" 2>/dev/null; then
    pass "$card_name: 书目信息 'Verified' date present"
  else
    fail "$card_name: 书目信息 missing 'Verified: yyyy-mm-dd' (scaffold.md §参考卡片 required — cannot ship without verification date)"
  fi

  # Required sections
  required_sections=("书目信息" "影响力与同类对比" "核心方法分析" "对当前 Skill 的价值")
  for sec in "${required_sections[@]}"; do
    if grep -q "$sec" "$card" 2>/dev/null; then
      pass "$card_name: section '$sec' found"
    else
      fail "$card_name: section '$sec' missing"
    fi
  done

  # 核心方法分析 7 subsections
  analysis_subs=("问题定义" "结论" "核心类比" "技术机制" "创新性" "实验设计" "局限性")
  for sub in "${analysis_subs[@]}"; do
    if grep -q "$sub" "$card" 2>/dev/null; then
      pass "$card_name: 核心方法分析 sub '$sub' found"
    else
      fail "$card_name: 核心方法分析 sub '$sub' missing"
    fi
  done

  # 对当前 Skill 的价值 3 subsections
  value_subs=("关键启发" "本地验证思路" "不适用的部分")
  for sub in "${value_subs[@]}"; do
    if grep -q "$sub" "$card" 2>/dev/null; then
      pass "$card_name: Skill 价值 sub '$sub' found"
    else
      fail "$card_name: Skill 价值 sub '$sub' missing"
    fi
  done

  # "不适用的部分" non-empty (has content after heading)
  while IFS= read -r result; do
    if [[ "$result" == "OK" ]]; then
      pass "$card_name: '不适用的部分' has content"
    else
      fail "$card_name: '不适用的部分' is empty or missing"
    fi
  done < <(ruby -e "
    text = File.read('$card')
    if text =~ /不适用的部分.*?\n(.*?)(?=\n#|\z)/m
      content = \$1.strip
      if content.empty?
        puts 'EMPTY'
      else
        puts 'OK'
      end
    else
      puts 'MISSING'
    end
  " 2>/dev/null || true)

  # "关键启发" contains at least 1 bold (**...**)
  while IFS= read -r result; do
    if [[ "$result" == "OK" ]]; then
      pass "$card_name: '关键启发' contains bold emphasis"
    else
      fail "$card_name: '关键启发' missing bold (**...**) emphasis"
    fi
  done < <(ruby -e "
    text = File.read('$card')
    if text =~ /关键启发.*?\n(.*?)(?=\n#+\s|\z)/m
      section = \$1
      if section.include?('**')
        puts 'OK'
      else
        puts 'NO_BOLD'
      end
    else
      puts 'MISSING'
    end
  " 2>/dev/null || true)
done

exit $_EXIT_CODE
