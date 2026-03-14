#!/usr/bin/env bash
# validate.sh — Top-level validation aggregator
# Usage: tools/validate.sh <skill-dir> [--ship]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SKILL_DIR="${1:?Usage: tools/validate.sh <skill-dir> [--ship]}"
SKILL_DIR="${SKILL_DIR%/}"
SHIP_MODE="${2:-}"

TMPOUT=$(mktemp)
trap "rm -f $TMPOUT" EXIT

run_validator() {
  bash "$1" "${@:2}" 2>&1 | tee -a "$TMPOUT" || true
}

echo "=== Federation Skill Validation ==="
echo "Target: $SKILL_DIR"
echo ""

# Core validations
echo "--- Structure ---"
run_validator "$SCRIPT_DIR/validate_structure.sh" "$SKILL_DIR" "${SHIP_MODE:-}"
echo ""

echo "--- Manifest ---"
run_validator "$SCRIPT_DIR/validate_manifest.sh" "$SKILL_DIR/manifest.yaml"
echo ""

echo "--- Evals ---"
run_validator "$SCRIPT_DIR/validate_evals.sh" "$SKILL_DIR/evals"
echo ""

# Ship-mode: Article + Ref Cards
if [[ "$SHIP_MODE" == "--ship" ]]; then
  echo "--- Article (--ship) ---"
  # Article dir is named exactly 'article/' per whitepaper §2.3
  dir_version=$(basename "$SKILL_DIR" | grep -oE 'v[0-9]+$' || true)
  article_dir="$SKILL_DIR/evolve_history/${dir_version}/article"
  if [[ -d "$article_dir" ]]; then
    article_md=$(find "$article_dir" -maxdepth 1 -name "*.md" ! -name "ref_*" 2>/dev/null | head -1)
    if [[ -n "$article_md" ]]; then
      run_validator "$SCRIPT_DIR/validate_article.sh" "$article_md"
    else
      echo "  ✗ No article markdown found in article/" | tee -a "$TMPOUT"
    fi

    echo ""
    echo "--- Ref Cards (--ship) ---"
    assets_dir="$SKILL_DIR/evolve_history/${dir_version}/assets/references"
    if [[ -d "$assets_dir" ]]; then
      run_validator "$SCRIPT_DIR/validate_ref_cards.sh" "$assets_dir"
    else
      echo "  ✗ No assets/references directory found (required for --ship: ref cards must accompany article)" | tee -a "$TMPOUT"
    fi
  else
    echo "  ✗ No article/ directory found at evolve_history/${dir_version}/article/" | tee -a "$TMPOUT"
  fi
  echo ""
fi

echo "--- References ---"
run_validator "$SCRIPT_DIR/validate_references.sh" "$SKILL_DIR"
echo ""

# Final count from captured output
_PASS=$(grep -c "✓" "$TMPOUT" || true)
_FAIL=$(grep -c "✗" "$TMPOUT" || true)
_WARN=$(grep -c "⚠" "$TMPOUT" || true)

echo ""
echo "=== Summary: $_PASS passed, $_FAIL failed, $_WARN warnings ==="
[[ $_FAIL -gt 0 ]] && exit 1 || exit 0
