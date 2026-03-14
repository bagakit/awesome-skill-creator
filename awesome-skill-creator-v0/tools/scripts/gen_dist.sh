#!/usr/bin/env bash
# gen_dist.sh — Package a skill directory for distribution
# Usage: gen_dist.sh <skill-dir> [--runtime|--quality] [--dry-run] [--out <dir>]
#
# Distribution tiers (scaffold.md §Distribution):
#   --runtime   Minimal runtime layer: SKILL.md, process.md, manifest.yaml,
#               .step0.yaml, self-bootstrap.md, scaffold.md, locks/ (reset to empty)
#   --quality   Full verifiable layer (default): runtime + evals/, tools/
#
# Build artifacts NEVER distributed: evolve_history/, version_history/, .tmp/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../gate/_lib.sh"

SKILL_DIR="${1:?Usage: gen_dist.sh <skill-dir> [--runtime|--quality] [--dry-run] [--out <dir>]}"
SKILL_DIR="${SKILL_DIR%/}"
TIER="quality"
DRY_RUN=false
OUT_DIR=""

for arg in "${@:2}"; do
  case "$arg" in
    --runtime)   TIER="runtime" ;;
    --quality)   TIER="quality" ;;
    --dry-run)   DRY_RUN=true ;;
    --out=*)     OUT_DIR="${arg#--out=}" ;;
    --out)       ;;  # handled by next arg; not supported in this simple parser
  esac
done

if [[ ! -d "$SKILL_DIR" ]]; then
  echo "Error: '$SKILL_DIR' is not a directory"
  exit 1
fi

SKILL_NAME="$(basename "$SKILL_DIR")"
if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="${SKILL_DIR}-dist-${TIER}"
fi

echo "[gen_dist: $SKILL_NAME → $OUT_DIR (tier: $TIER)]"

# ── Runtime layer ─────────────────────────────────────────────────────────────
# Always included regardless of tier
RUNTIME_FILES=(
  "SKILL.md"
  "process.md"
  "manifest.yaml"
)
RUNTIME_OPTIONAL_FILES=(
  ".step0.yaml"
  "self-bootstrap.md"
  "scaffold.md"
)
RUNTIME_DIRS=(
  "locks"
)

# ── Quality layer (adds on top of runtime) ────────────────────────────────────
QUALITY_DIRS=(
  "evals"
  "tools"
)

# ── Build artifacts: NEVER distributed ───────────────────────────────────────
EXCLUDED_DIRS=(
  "evolve_history"
  "version_history"
  ".tmp"
)

# ── Collect what will be distributed ─────────────────────────────────────────
TO_COPY_FILES=()
TO_COPY_DIRS=()

for f in "${RUNTIME_FILES[@]}"; do
  if [[ -f "$SKILL_DIR/$f" ]]; then
    TO_COPY_FILES+=("$f")
  else
    echo "  ⚠ WARN: required runtime file missing: $f"
  fi
done

for f in "${RUNTIME_OPTIONAL_FILES[@]}"; do
  [[ -f "$SKILL_DIR/$f" ]] && TO_COPY_FILES+=("$f")
done

for d in "${RUNTIME_DIRS[@]}"; do
  [[ -d "$SKILL_DIR/$d" ]] && TO_COPY_DIRS+=("$d")
done

if [[ "$TIER" == "quality" ]]; then
  for d in "${QUALITY_DIRS[@]}"; do
    if [[ -d "$SKILL_DIR/$d" ]]; then
      # Skip empty directories (e.g. tools/ with no scripts)
      if [[ -n "$(ls -A "$SKILL_DIR/$d" 2>/dev/null)" ]]; then
        TO_COPY_DIRS+=("$d")
      fi
    fi
  done
fi

# ── Dry run: just report ──────────────────────────────────────────────────────
if $DRY_RUN; then
  echo ""
  echo "  Files:"
  for f in "${TO_COPY_FILES[@]}"; do
    echo "    ✓ $f"
  done
  echo "  Directories:"
  for d in "${TO_COPY_DIRS[@]}"; do
    echo "    ✓ $d/"
    if [[ "$d" == "locks" ]]; then
      echo "      (locks reset to empty)"
    fi
  done
  echo ""
  echo "  Excluded (build artifacts):"
  for d in "${EXCLUDED_DIRS[@]}"; do
    [[ -d "$SKILL_DIR/$d" ]] && echo "    ✗ $d/"
  done
  echo ""
  echo "  → Output: $OUT_DIR/ (dry run — nothing written)"
  exit 0
fi

# ── Create output directory ───────────────────────────────────────────────────
if [[ -d "$OUT_DIR" ]]; then
  echo "Error: output directory '$OUT_DIR' already exists (remove it first)"
  exit 1
fi
mkdir -p "$OUT_DIR"

# ── Copy files ────────────────────────────────────────────────────────────────
copied=0
for f in "${TO_COPY_FILES[@]}"; do
  cp "$SKILL_DIR/$f" "$OUT_DIR/$f"
  echo "  ✓ $f"
  ((copied++)) || true
done

for d in "${TO_COPY_DIRS[@]}"; do
  if [[ "$d" == "locks" ]]; then
    # Reset locks to empty (fresh lifecycle state for consumer)
    mkdir -p "$OUT_DIR/locks"
    for lock in evolve.lock promote.lock register.lock; do
      [[ -f "$SKILL_DIR/locks/$lock" ]] && touch "$OUT_DIR/locks/$lock"
    done
    echo "  ✓ locks/ (reset to empty)"
  else
    cp -r "$SKILL_DIR/$d" "$OUT_DIR/$d"
    echo "  ✓ $d/"
  fi
  ((copied++)) || true
done

echo ""
echo "  Excluded (build artifacts):"
for d in "${EXCLUDED_DIRS[@]}"; do
  [[ -d "$SKILL_DIR/$d" ]] && echo "    ✗ $d/"
done

echo ""
echo "=== Distribution package ready: $OUT_DIR/ (tier: $TIER, $copied items) ==="
