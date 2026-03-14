#!/usr/bin/env bash
# validate_article.sh — Validate article word counts, headings, and references
# Usage: validate_article.sh <article.md>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

ARTICLE="${1:?Usage: validate_article.sh <article.md>}"

echo "[Article: $(basename "$ARTICLE")]"

if [[ ! -f "$ARTICLE" ]]; then
  fail "Article file not found: $ARTICLE"
  summary
  exit $_EXIT_CODE
fi

# Total word count: 8000-12000
total=$(count_words "$ARTICLE")
if [[ "$total" -ge 8000 && "$total" -le 12000 ]]; then
  pass "Total word count: $total (8000-12000)"
else
  if [[ "$total" -lt 8000 ]]; then
    fail "Total word count: $total (below 8000 minimum)"
  else
    fail "Total word count: $total (above 12000 maximum)"
  fi
fi

# Per-section word counts (avoid associative array issues with set -u)
check_section_words() {
  local section="$1" min_w="$2" max_w="$3"
  local wc
  wc=$(count_words_section "$ARTICLE" "$section")
  if [[ "$wc" -ge "$min_w" && "$wc" -le "$max_w" ]]; then
    pass "§$section: $wc words ($min_w-$max_w)"
  else
    fail "§$section: $wc words (expected $min_w-$max_w — scaffold.md section word count requirement)"
  fi
}

check_section_words "Abstract" 150 250

# Abstract content: should cover problem, method, results, significance (scaffold.md: 问题/方法/结果/意义)
abs_line=$(grep -niE "^#{1,6}\s+.*Abstract" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$abs_line" ]]; then
  if awk -v start="$abs_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null | grep -qiE "(problem|issue|challenge|motivation|问题|miscalibrat|fail)" 2>/dev/null; then
    pass "Abstract: problem/motivation element present (scaffold.md: 问题/方法/结果/意义)"
  else
    fail "Abstract: missing problem/motivation element (scaffold.md: Abstract 需涵盖 问题 — add problem/challenge/motivation language)"
  fi
  if awk -v start="$abs_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null | grep -qiE "(method|approach|present|introduce|propose|framework|mechanism|方法|我们)" 2>/dev/null; then
    pass "Abstract: method/approach element present (scaffold.md: 问题/方法/结果/意义)"
  else
    fail "Abstract: missing method/approach element (scaffold.md: Abstract 需涵盖 方法 — add method/approach/framework language)"
  fi
  # Abstract: results element (scaffold.md: 结果)
  if awk -v start="$abs_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null | grep -qiE "(result|show|achieve|demonstrate|evaluation|pass rate|结果|表现|通过率|准确率)" 2>/dev/null; then
    pass "Abstract: results element present (scaffold.md: 问题/方法/结果/意义)"
  else
    fail "Abstract: missing results element (scaffold.md: Abstract 需涵盖 结果 — add result/outcome/evaluation language)"
  fi
  # Abstract: significance element (scaffold.md: 意义)
  if awk -v start="$abs_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null | grep -qiE "(together|address|enable|contribut|advance|impact|significance|improve|benefit|意义|贡献|影响|价值|together these)" 2>/dev/null; then
    pass "Abstract: significance/impact element present (scaffold.md: 问题/方法/结果/意义)"
  else
    fail "Abstract: missing significance/impact element (scaffold.md: Abstract 需涵盖 意义 — add significance/contribution/impact language)"
  fi
fi
check_section_words "Introduction" 1200 1500
check_section_words "Related Work" 1000 1500
check_section_words "Design" 2000 3000
check_section_words "Evaluation" 1500 2500
check_section_words "Discussion" 1000 1500
check_section_words "Conclusion" 200 300

# Required headings
required_headings=("Abstract" "Introduction" "Related Work" "Design" "Evaluation" "Discussion" "Conclusion")
for h in "${required_headings[@]}"; do
  if has_section "$ARTICLE" "$h"; then
    pass "Heading '$h' found"
  else
    fail "Heading '$h' missing"
  fi
done

# Discussion contains Limitations subsection (spec: Discussion 含 Limitations 子节)
disc_line=$(grep -niE "^#{2,6}\s+.*\bDiscussion\b" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$disc_line" ]]; then
  disc_content=$(awk -v start="$disc_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null)
  if echo "$disc_content" | grep -qiE "^#{3,6}.*Limitation" 2>/dev/null; then
    pass "Discussion: contains Limitations subsection"
  else
    fail "Discussion: missing Limitations subsection (spec requires ### Limitations under ## Discussion)"
  fi
else
  fail "Discussion section not found (cannot check Limitations subsection)"
fi

# Design section must have sub-headings (scaffold.md: 设计原则层 → 架构层 → 细节层)
design_line=$(grep -niE "^## .*\bDesign\b" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$design_line" ]]; then
  design_subsections=$(awk -v start="$design_line" 'NR > start && /^## / { exit } NR > start && /^### / { count++ } END { print count+0 }' "$ARTICLE" 2>/dev/null)
  if [[ "${design_subsections:-0}" -ge 3 ]]; then
    pass "Design: $design_subsections sub-headings in Design section (≥3, scaffold.md: Design 设计原则层→架构层→细节层)"
  else
    fail "Design: only ${design_subsections:-0} sub-headings in Design section (<3, scaffold.md: Design must have ≥3 sub-sections 设计原则层→架构层→细节层)"
  fi
else
  fail "Design section heading not found (cannot check sub-headings)"
fi

# Design section must contain decision rationale language (scaffold.md: 每个决策有论证链)
if [[ -n "$design_line" ]]; then
  design_rationale=$(awk -v start="$design_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null | grep -ciE "(because|trade.off|tradeoff|ensures|requires|rationale|therefore|enables|avoids|prevents|因为|因此|由于|权衡|论证)" || true)
  if [[ "${design_rationale:-0}" -ge 3 ]]; then
    pass "Design: contains decision rationale language (≥3 occurrences) (scaffold.md: 每个决策有论证链)"
  else
    fail "Design: missing decision rationale (scaffold.md: Design 每个决策需要论证链 — add 'because/therefore/tradeoff' language, ≥3 occurrences)"
  fi
fi

# Discussion failure analysis must be quantified (scaffold.md: 失败分析需量化)
# Check that the article's Discussion/Limitations sections contain quantified failure data
# Strategy: find Limitations heading, check the surrounding lines for numbers
if grep -qiE "^#{2,6}\s+.*Limitation" "$ARTICLE" 2>/dev/null; then
  lim_line=$(grep -niE "^#{2,6}\s+.*Limitation" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
  # Extract Limitations section content (stop at next ##/### heading)
  lim_content=$(awk -v start="$lim_line" 'NR > start && /^#{2,3} / { exit } NR > start' "$ARTICLE" 2>/dev/null)
  if echo "$lim_content" | grep -qE "[0-9]+[%/]|[0-9]+.*case|[0-9]+.*fail|[0-9]+.*error|[0-9]+.*pass|[0-9]+\/[0-9]+" 2>/dev/null; then
    pass "Discussion/Limitations: failure analysis contains quantification (scaffold.md: 失败分析需量化)"
  else
    fail "Discussion/Limitations: failure analysis lacks quantification (scaffold.md: 失败分析需量化 — add specific numbers/percentages/case counts)"
  fi
fi

# Related Work references ≥10
ref_count=$(grep -oE '\[[0-9]+\]|ref_[a-zA-Z0-9_]+' "$ARTICLE" 2>/dev/null | sort -u | wc -l | tr -d ' ')
if [[ "$ref_count" -ge 10 ]]; then
  pass "Reference count: $ref_count unique refs (≥10)"
else
  fail "Reference count: $ref_count unique refs (<10, need ≥10)"
fi

# Related Work must be grouped by theme (scaffold.md: 按主题分组 — should have ≥2 subsections)
rw_line=$(grep -niE "^#{2,6}\s+.*Related Work" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$rw_line" ]]; then
  # Count subsections (###) after Related Work until the next ## section
  rw_subs=$(awk -v start="$rw_line" 'NR > start && /^## / { exit } NR > start && /^### / { count++ } END { print count+0 }' "$ARTICLE" 2>/dev/null)
  if [[ "${rw_subs:-0}" -ge 2 ]]; then
    pass "Related Work: $rw_subs subsections (按主题分组, scaffold.md: grouped by theme)"
  else
    fail "Related Work: only ${rw_subs:-0} subsections (<2, scaffold.md: 按主题分组 ≥2 subsections required)"
  fi
fi

# Evaluation section contains GSB analysis — must be in Evaluation section specifically (scaffold.md mandate)
eval_gsb_line=$(grep -niE "^#{2,6}\s+.*Evaluation\b" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$eval_gsb_line" ]]; then
  eval_gsb_content=$(awk -v start="$eval_gsb_line" 'NR > start && /^## [^#]/ { exit } NR > start' "$ARTICLE" 2>/dev/null)
  if echo "$eval_gsb_content" | grep -qiE "GSB|Good.*Same.*Bad|增值率|Good-Skill-Bad|Good / Same / Bad" 2>/dev/null; then
    pass "Evaluation section contains GSB analysis"
  else
    fail "Evaluation section missing GSB analysis (scaffold.md: Evaluation 章节必须包含 GSB 分布分析 — add GSB comparison subsection)"
  fi
else
  fail "Evaluation section not found (cannot check GSB analysis)"
fi

# Evaluation section should have subsections (scaffold.md: 方法论→结果→基线对比→变异分析)
eval_line=$(grep -niE "^#{2,6}\s+.*Evaluation\b" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$eval_line" ]]; then
  eval_subs=$(awk -v start="$eval_line" 'NR > start && /^## / { exit } NR > start && /^### / { count++ } END { print count+0 }' "$ARTICLE" 2>/dev/null)
  if [[ "${eval_subs:-0}" -ge 2 ]]; then
    pass "Evaluation: $eval_subs subsections (scaffold.md: 方法论→结果→GSB基线对比→变异分析)"
  else
    fail "Evaluation: only ${eval_subs:-0} subsections (<2, scaffold.md: ≥2 sub-sections required 方法论→结果→GSB基线对比→变异分析)"
  fi
fi

# Introduction must mention contributions (scaffold.md: Introduction 贡献展开)
# Extract Introduction section and check for contribution keyword
intro_line=$(grep -niE "^#{1,6}\s+.*Introduction" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$intro_line" ]]; then
  intro_content=$(awk -v start="$intro_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null || true)
  if echo "$intro_content" | grep -qiE "(contribution|贡献|novelty|this paper|this work|we present|we propose|our approach|our design)" 2>/dev/null; then
    pass "Introduction: contribution/novelty mention present (scaffold.md: 贡献展开)"
  else
    fail "Introduction: missing contribution/novelty mention (scaffold.md: Introduction 需贡献展开 — state what this paper contributes)"
  fi
  # Introduction must contain a paper roadmap/structure overview (scaffold.md: 论文路线图)
  # Use full section (no head limit) so roadmap at end of long Introduction is not missed
  intro_content2=$(awk -v start="$intro_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null || true)
  if echo "$intro_content2" | grep -qiE "(section|§[0-9]|remainder|organized|rest of|structure of|路线图|论文结构|本文组织|本文安排)" 2>/dev/null; then
    pass "Introduction: paper roadmap/structure overview present (scaffold.md: 论文路线图)"
  else
    fail "Introduction: missing paper roadmap/structure overview (scaffold.md: 论文路线图 — describe section structure, e.g. 'Section 2 covers...')"
  fi
fi

# Conclusion section mentions future version direction (scaffold.md: Conclusion 明确 v1 方向)
conc_line=$(grep -niE "^#{2,6}\s+.*Conclusion" "$ARTICLE" 2>/dev/null | head -1 | cut -d: -f1)
if [[ -n "$conc_line" ]]; then
  conc_content=$(awk -v start="$conc_line" 'NR > start && /^## / { exit } NR > start' "$ARTICLE" 2>/dev/null)
  if echo "$conc_content" | grep -qiE "(v[1-9]|future work|future version|next version|future direction|下一版本|v1 方向|v1 目标|v2 方向|evolution|进化方向)" 2>/dev/null; then
    pass "Conclusion: contains future version direction (scaffold.md: Conclusion 明确 v1 方向)"
  else
    fail "Conclusion: missing future version direction (scaffold.md: Conclusion 必须明确提及未来版本方向 — add v1/v2 direction or future work)"
  fi
else
  fail "Conclusion section not found (cannot check future version direction)"
fi

# Ref cards in assets/references/ should each be cited in article body
# Article is at evolve_history/vN/article/xxx.md; assets are at evolve_history/vN/assets/references/
assets_dir="$(dirname "$(dirname "$ARTICLE")")/assets/references"
if [[ -d "$assets_dir" ]]; then
  while IFS= read -r card; do
    card_name=$(basename "$card" .md)
    if grep -qF "$card_name" "$ARTICLE" 2>/dev/null; then
      pass "Ref card '$card_name' cited in article"
    else
      fail "Ref card '$card_name' not cited in article body (scaffold.md: 参考卡片每张至少在正文中被引用一次)"
    fi
  done < <(find "$assets_dir" -name "*.md" -type f 2>/dev/null | sort)
fi

exit $_EXIT_CODE
