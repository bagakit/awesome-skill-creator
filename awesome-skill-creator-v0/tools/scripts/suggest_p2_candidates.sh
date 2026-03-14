#!/usr/bin/env bash
# suggest_p2_candidates.sh — Scan eval suite and suggest P2 archive candidates
#
# A case is a P2 candidate when its assertions are semantically subsumed by another case.
# Two modes of subsumption are detected:
#
#   1. Exact subsumption (after path normalization):
#      Case A's normalized assertion tokens are a strict subset of case B's tokens.
#      Example: A checks `contains: "foo"` in <skill>/evals/cases.yaml;
#               B checks that AND `min_count: cases >= 5` in same normalized target.
#
#   2. String-containment subsumption:
#      Case A's `contains: X` on target T is covered by case B's `contains: Y` on same T
#      when X is a substring of Y — because any file containing Y also contains X.
#      Example: A checks `contains: "合格"`, B checks `contains: "**合格**: 是"`.
#
# Path normalization: strips skill-specific directory prefixes
#   (`<skill-name>-v<N>/` → `<skill>/`) so structurally identical cases on
#   different skill fixtures are recognized as equivalent.
#
# Usage:
#   suggest_p2_candidates.sh <evals-dir>
#   suggest_p2_candidates.sh <evals-dir> --json    # machine-readable output
#
# Output:
#   CANDIDATE: <weak-id> → superseded by <strong-id>  (suggested P2 archive)
#
# Note: All suggestions require human review before archiving. The tool
# detects structural/semantic subsumption; it cannot assess domain intent.

set -euo pipefail

EVALS_DIR="${1:?Usage: suggest_p2_candidates.sh <evals-dir>}"
JSON_MODE="${2:-}"
CASES_FILE="$EVALS_DIR/objective_cases.yaml"

if [[ ! -f "$CASES_FILE" ]]; then
  echo "ERROR: $CASES_FILE not found" >&2
  exit 1
fi

ruby -ryaml -e '
  require "set"

  json_mode = ARGV[1] == "--json"
  data = YAML.load_file(ARGV[0])
  cases = (data["cases"] || []).reject { |c| c["tier"] == "P2" }

  # Normalize a value: strip skill-specific path prefixes so that
  # "hello-world-v0/evals/foo.yaml" and "code-reviewer-v0/evals/foo.yaml"
  # both normalize to "<skill>/evals/foo.yaml".
  def normalize(v)
    return v unless v.is_a?(String)
    v.gsub(/\A[a-z][a-zA-Z0-9_-]+-v\d+\//, "<skill>/")
  end

  # Build normalized assertion fingerprint: set of "type:key=val" tokens per case.
  def fingerprint(c)
    fps = []
    (c["assertions"] || []).each do |a|
      a.each do |k, v|
        fps << "#{a["type"]}:#{k}=#{normalize(v)}" unless k == "type"
      end
    end
    fps.to_set
  end

  # For a `contains` assertion token "contains:value=X" on target T,
  # check whether a stronger token "contains:value=Y" covers it via
  # string containment (X is a substring of Y, same T).
  def contains_token_subsumed_by?(weak_tok, strong_set)
    # weak_tok must be a contains:value= token
    return false unless weak_tok.start_with?("contains:value=")
    weak_val = weak_tok.sub(/\Acontains:value=/, "")
    strong_set.any? do |s|
      next false unless s.start_with?("contains:value=")
      strong_val = s.sub(/\Acontains:value=/, "")
      # Weak is covered if strong_val contains weak_val as substring
      strong_val != weak_val && strong_val.include?(weak_val)
    end
  end

  # Check if weak case w is semantically subsumed by strong case s.
  # This combines:
  #   (a) exact token subsumption (after normalization), and
  #   (b) string-containment subsumption for `contains:value` tokens.
  #
  # Matching also requires that for each weak `contains:value=X` token,
  # the strong case has an assertion targeting the same normalized path.
  def subsumed_by?(weak_fp, strong_fp)
    return false if weak_fp.empty?
    return false if weak_fp == strong_fp
    # Extract target tokens for each case
    strong_targets = strong_fp.select { |t| t.include?(":target=") }.map { |t| t.split(":target=", 2)[1] }.to_set

    weak_fp.all? do |wt|
      # (a) exact match
      next true if strong_fp.include?(wt)
      # (b) string-containment: weak contains:value=X covered by strong contains:value=Y where X ⊆ Y
      if wt.start_with?("contains:value=")
        next contains_token_subsumed_by?(wt, strong_fp)
      end
      # (c) weak target= token: if strong has any assertion on same normalized target, that is fine
      if wt.start_with?("contains:target=")
        weak_target = wt.sub(/\Acontains:target=/, "")
        next strong_targets.include?(weak_target)
      end
      false
    end
  end

  fps = {}
  cases.each { |c| fps[c["id"]] = fingerprint(c) }

  candidates = {}
  cases.each do |weak|
    wid = weak["id"]
    wfp = fps[wid]
    next if wfp.empty?
    cases.each do |strong|
      sid = strong["id"]
      next if sid == wid
      sfp = fps[sid]
      if subsumed_by?(wfp, sfp)
        candidates[wid] ||= []
        candidates[wid] << sid
      end
    end
  end

  # Deduplicate: if A→B and A→C, keep only the strongest (most tokens) superseder
  best_candidates = {}
  candidates.each do |wid, sids|
    best = sids.max_by { |sid| fps[sid].size }
    best_candidates[wid] = best
  end

  if json_mode
    require "json"
    out = best_candidates.map do |wid, sid|
      { "candidate" => wid, "superseded_by" => sid,
        "weak_tokens" => fps[wid].to_a.sort, "strong_tokens" => fps[sid].to_a.sort }
    end
    puts JSON.pretty_generate(out)
  elsif best_candidates.empty?
    puts "No P2 candidates found — all active cases have unique assertion coverage."
  else
    count = best_candidates.size
    puts "P2 candidates: #{count} case(s) found (human review required before archiving)"
    puts ""
    best_candidates.each do |wid, sid|
      wsize = fps[wid].size
      ssize = fps[sid].size
      puts "  CANDIDATE: #{wid}  (#{wsize} token(s))"
      puts "    → superseded_by: #{sid}  (#{ssize} token(s), covers all of the above)"
      puts ""
    end
    puts "To archive a candidate, add to its entry in objective_cases.yaml:"
    puts "  tier: P2"
    puts "  superseded_by: <stronger-case-id>"
  end
' "$CASES_FILE" "$JSON_MODE"
