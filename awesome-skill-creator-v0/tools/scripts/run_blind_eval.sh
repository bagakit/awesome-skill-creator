#!/usr/bin/env bash
# run_blind_eval.sh — GSB (Good/Same/Bad) blind evaluation: Skill vs bare LLM
#
# EXECUTION PROTOCOL:
#   For each case with gsb_baseline:
#     1. Run the case INPUT through full skill (SKILL.md + process.md guidance)
#     2. Run the SAME input through bare LLM (no skill guidance)
#     3. Compare outputs on the assertion dimensions
#     4. Human annotator labels: Good / Same / Bad
#
# This script cannot be run non-interactively — it requires:
#   a) A running Claude session for both skill and bare executions
#   b) Human annotation of comparative quality
#
# Usage:
#   run_blind_eval.sh <skill-dir> <case-id> --record <output-dir>
#
# Output: blind_eval_report.json in <output-dir>/
#
# IMPORTANT: The blind eval results in blind_eval_report.json MUST be produced
# by actually running both paths and recording human judgment.
# Any blind_eval_report.json not produced by this script is invalid.

set -euo pipefail

SKILL_DIR="${1:?Usage: run_blind_eval.sh <skill-dir> <case-id> --record <output-dir>}"
CASE_ID="${2:?Provide case-id}"
OUTPUT_DIR="${4:?Provide output dir after --record}"

echo "=== run_blind_eval.sh: GSB Blind Evaluation ==="
echo "This requires interactive execution. Steps:"
echo ""
echo "Step 1: Run skill-guided execution"
echo "  → Invoke: /skill-creator $CASE_ID"
echo "  → Record: output artifacts"
echo ""
echo "Step 2: Run bare LLM execution"
echo "  → Same input, no SKILL.md / process.md provided"
echo "  → Record: output artifacts"
echo ""
echo "Step 3: Compare on assertion dimensions"
echo "  → Does skill output pass more assertions? → Good"
echo "  → No significant difference? → Same"
echo "  → Skill output passes fewer? → Bad"
echo ""
echo "Step 4: Record results"
echo "  → Output: $OUTPUT_DIR/blind_eval_report.json"
echo "  → Must include: execution_type='actual', both outputs, human annotation"
echo ""
echo "Exiting — run this interactively with actual LLM sessions."
exit 0
