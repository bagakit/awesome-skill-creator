#!/usr/bin/env bash
# validate_references.sh — Check cross-file reference integrity
# Usage: validate_references.sh <skill-dir>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

SKILL_DIR="${1:?Usage: validate_references.sh <skill-dir>}"
SKILL_DIR="${SKILL_DIR%/}"

echo "[References: $SKILL_DIR]"

# 1. Scan all .md files for relative links ](path) and verify targets exist
while IFS= read -r mdfile; do
  # Use process substitution (not pipe) so fail/pass update _FAIL/_EXIT_CODE in parent shell
  while IFS= read -r link; do
    # Skip absolute URLs, anchors, and template placeholders
    [[ "$link" =~ ^https?:// ]] && continue
    [[ "$link" =~ ^mailto: ]] && continue
    [[ "$link" =~ ^# ]] && continue
    [[ "$link" == "url" ]] && continue

    # Remove anchor part
    link_path="${link%%#*}"
    [[ -z "$link_path" ]] && continue

    # Resolve relative to the file's directory
    file_dir="$(dirname "$mdfile")"
    target="$file_dir/$link_path"

    if [[ -e "$target" ]]; then
      pass "$(basename "$mdfile"): link to '$link_path' OK"
    else
      fail "$(basename "$mdfile"): broken link to '$link_path'"
    fi
  done < <(grep -oE '\]\([^)]+\)' "$mdfile" 2>/dev/null | sed 's/^\](\(.*\))$/\1/' || true)
done < <(find "$SKILL_DIR" -name "*.md" -type f 2>/dev/null)

# 2. Scan Article for ref card references, verify assets/ files exist
# Assets are at evolve_history/vN/assets/references/ (sibling of article/)
# Find the version-specific article dir (use skill dir version suffix if available)
dir_version=$(basename "$SKILL_DIR" | grep -oE 'v[0-9]+$' || true)
if [[ -n "$dir_version" && -d "$SKILL_DIR/evolve_history/${dir_version}/article" ]]; then
  article_dir="$SKILL_DIR/evolve_history/${dir_version}/article"
else
  article_dir=$(find "$SKILL_DIR/evolve_history" -maxdepth 3 -type d -name "article" 2>/dev/null | sort -r | head -1)
fi
if [[ -n "$article_dir" ]]; then
  article_md=$(find "$article_dir" -maxdepth 1 -name "*.md" ! -name "ref_*" 2>/dev/null | head -1)
  # assets are at evolve_history/vN/assets/references/ (sibling of article/, NOT inside article/)
  assets_dir="$(dirname "$article_dir")/assets/references"

  if [[ -n "$article_md" && -d "$assets_dir" ]]; then
    # Forward check: ref_* mentions in article BODY (non-bibliography lines) must have corresponding files
    # Bibliography lines start with [N] so exclude them — bibliography IDs ≠ ref card files
    while IFS= read -r ref; do
      [[ -z "$ref" ]] && continue
      if find "$assets_dir" -name "${ref}*" -type f 2>/dev/null | grep -q .; then
        pass "Article body ref '$ref' has corresponding asset file"
      else
        fail "Article body ref '$ref' has no corresponding file in assets/references/ (scaffold.md: 参考卡片每张至少在正文中被引用一次)"
      fi
    done < <(grep -v '^\[[0-9]' "$article_md" 2>/dev/null | grep -oE 'ref_[a-zA-Z0-9_]+' | sort -u || true)

    # Reverse check: each ref card in assets/ must be cited at least once in article (scaffold.md: 每张至少被引用一次)
    while IFS= read -r card; do
      [[ -z "$card" ]] && continue
      card_basename="$(basename "$card" .md)"
      if grep -qF "$card_basename" "$article_md" 2>/dev/null; then
        pass "assets ref card '$(basename "$card")' is cited in article"
      else
        fail "assets ref card '$(basename "$card")' not cited in article (scaffold.md: 每张至少被引用一次 — required)"
      fi
    done < <(find "$assets_dir" -name "ref_*.md" -type f 2>/dev/null || true)
  fi
fi

exit $_EXIT_CODE
