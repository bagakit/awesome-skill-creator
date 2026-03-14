#!/usr/bin/env bash
# validate_evals.sh — Validate eval cases and protocol
# Usage: validate_evals.sh <evals-dir>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

EVALS_DIR="${1:?Usage: validate_evals.sh <evals-dir>}"
CASES_FILE="$EVALS_DIR/objective_cases.yaml"
PROTOCOL_FILE="$EVALS_DIR/eval_protocol.md"

echo "[Evals: $EVALS_DIR]"

# eval_protocol.md exists + content checks (scaffold.md §eval_protocol.md 必须)
if [[ -f "$PROTOCOL_FILE" ]]; then
  pass "eval_protocol.md exists"
  # Required content: GSB protocol, preflight, pass/fail criteria, only-increase
  if grep -qiE "(GSB|Good.*Same.*Bad|增值率)" "$PROTOCOL_FILE" 2>/dev/null; then
    pass "eval_protocol.md: GSB 对比协议 present"
  else
    fail "eval_protocol.md: missing GSB 对比协议 (scaffold.md required)"
  fi
  if grep -qiE "(Preflight|preflight|快速验证)" "$PROTOCOL_FILE" 2>/dev/null; then
    pass "eval_protocol.md: Preflight 协议 present"
  else
    fail "eval_protocol.md: missing Preflight 协议 (scaffold.md required: 包含 preflight 协议)"
  fi
  if grep -qiE "(only.increase|只增不删|历史.*用例)" "$PROTOCOL_FILE" 2>/dev/null; then
    pass "eval_protocol.md: only-increase 合规 present"
  else
    fail "eval_protocol.md: missing only-increase 合规说明 (scaffold.md required: 遵循 only-increase 原则)"
  fi
  if grep -qiE "(通过|失败|pass|fail|判断标准|判定)" "$PROTOCOL_FILE" 2>/dev/null; then
    pass "eval_protocol.md: 判断标准 present"
  else
    fail "eval_protocol.md: missing 判断标准/pass-fail criteria (scaffold.md required)"
  fi
  # GSB threshold: eval_protocol.md must specify a numeric threshold for GSB increase rate (scaffold.md: 增值率)
  if grep -qE "[0-9]+%" "$PROTOCOL_FILE" 2>/dev/null; then
    pass "eval_protocol.md: contains numeric GSB threshold percentage (scaffold.md: 增值率 must have measurable criterion)"
  else
    fail "eval_protocol.md: missing numeric GSB threshold (scaffold.md: 增值率 must specify a percentage, e.g. '增值率 < 30%' — add quantitative pass criterion)"
  fi
else
  fail "eval_protocol.md missing"
fi

# YAML syntax
if [[ ! -f "$CASES_FILE" ]]; then
  fail "objective_cases.yaml missing"
  summary
  exit $_EXIT_CODE
fi

if yaml_valid "$CASES_FILE"; then
  pass "objective_cases.yaml YAML syntax valid"
else
  fail "objective_cases.yaml YAML syntax invalid"
  summary
  exit $_EXIT_CODE
fi

# Eval case ID uniqueness check (duplicate IDs break only-increase principle traceability)
dup_ids=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  ids = (data['cases'] || []).map { |c| c['id'].to_s }
  dups = ids.select { |id| ids.count(id) > 1 }.uniq
  dups.empty? ? puts('OK') : puts('DUPS:' + dups.join(','))
" 2>/dev/null || echo "OK")
if [[ "$dup_ids" == "OK" ]]; then
  pass "Eval case IDs are unique"
else
  fail "Duplicate eval case IDs: ${dup_ids#DUPS:}"
fi

# Case count ≥5
case_count=$(yaml_list_length "$CASES_FILE" "cases")
if [[ "$case_count" -ge 5 ]]; then
  pass "Case count: $case_count (≥5)"
else
  fail "Case count: $case_count (<5, need ≥5)"
fi

# Expected-fail count ≥2 (scaffold.md: ≥2 pass, ≥2 fail)
fail_count=$(yaml_array_field_values "$CASES_FILE" "cases" "expected_result" | grep -c "^fail$" || true)
if [[ "$fail_count" -ge 2 ]]; then
  pass "Expected-fail cases: $fail_count (≥2)"
else
  fail "Expected-fail cases: $fail_count (<2, need ≥2)"
fi

# Expected-pass count ≥2 (scaffold.md: ≥2 pass, ≥2 fail)
pass_count=$(yaml_array_field_values "$CASES_FILE" "cases" "expected_result" | grep -c "^pass$" || true)
if [[ "$pass_count" -ge 2 ]]; then
  pass "Expected-pass cases: $pass_count (≥2)"
else
  fail "Expected-pass cases: $pass_count (<2, need ≥2)"
fi

# Each fail case has evolution_direction
while IFS= read -r line; do
  case "$line" in
    OK:*)    pass "Fail case '${line#OK:}' has evolution_direction" ;;
    WEAK:*)  fail "Fail case '${line#WEAK:}' evolution_direction is too short/generic (need specific direction ≥15 chars — scaffold.md: fail case 必须有有效进化方向)" ;;
    MISSING:*) fail "Fail case '${line#MISSING:}' missing evolution_direction" ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  fails = (data['cases'] || []).select { |c| c['expected_result'] == 'fail' }
  fails.each do |c|
    ed = c['evolution_direction'].to_s.strip
    if ed.empty?
      puts 'MISSING:' + c['id'].to_s
    elsif ed.downcase.include?('todo') || ed.length < 15
      puts 'WEAK:' + c['id'].to_s
    else
      puts 'OK:' + c['id'].to_s
    end
  end
" 2>/dev/null || true)

# Required fields per case
required_case_fields=("id" "description" "expected_result" "input" "assertions" "source" "added_in" "target_point" "regression_level")
while IFS= read -r line; do
  if [[ "$line" == OK:* ]]; then
    pass "Case '${line#OK:}' has all required fields"
  else
    id=$(echo "$line" | cut -d: -f2)
    fields=$(echo "$line" | cut -d: -f3)
    fail "Case '$id' missing fields: $fields"
  fi
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    missing = []
    %w[id description expected_result input source added_in target_point regression_level].each do |f|
      missing << f unless c[f] && !c[f].to_s.strip.empty?
    end
    # assertions must be a non-empty list (not just truthy)
    if c['assertions'].is_a?(Array) && !c['assertions'].empty?
      nil # ok
    elsif c['assertions'].is_a?(Array)
      missing << 'assertions (empty list)'
    else
      missing << 'assertions'
    end
    if missing.empty?
      puts 'OK:' + id
    else
      puts 'MISSING:' + id + ':' + missing.join(',')
    end
  end
" 2>/dev/null || true)

# target_point content quality check: should be specific, not TODO/empty/too-short (scaffold.md: 本轮攻克的单一优化点)
while IFS= read -r line; do
  case "$line" in
    OK:*)    pass "Case '${line#OK:}' target_point is specific" ;;
    WEAK:*)  fail "Case '${line#WEAK:}' target_point is too short/generic (need specific optimization point ≥5 chars — scaffold.md: 本轮攻克的单一优化点)" ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    tp = c['target_point'].to_s.strip
    next if tp.empty? || tp.include?('{TODO')   # missing or placeholder — caught elsewhere
    if tp.downcase.include?('todo') || tp.length < 5
      puts 'WEAK:' + c['id'].to_s
    else
      puts 'OK:' + c['id'].to_s
    end
  end
" 2>/dev/null || true)

# added_in format check: must match v\d+ (scaffold.md: 引入版本号)
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' added_in format is valid (v\\d+)" ;;
    INVALID:*)
      rest="${line#INVALID:}"; id="${rest%%:*}"; val="${rest#*:}"
      fail "Case '$id' added_in '$val' does not match v\\d+ pattern (scaffold.md: added_in must be version number)"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    ai = c['added_in'].to_s.strip
    next if ai.empty?  # missing — caught by required_fields check
    if ai =~ /^v\d+$/
      puts 'OK:' + id
    else
      puts 'INVALID:' + id + ':' + ai
    end
  end
" 2>/dev/null || true)

# source enum check
while IFS= read -r line; do
  if [[ "$line" == OK:* ]]; then
    pass "Case '${line#OK:}' source is valid enum"
  else
    id=$(echo "$line" | cut -d: -f2)
    src=$(echo "$line" | cut -d: -f3)
    fail "Case '$id' source '$src' not in {human_designed, agent_generated, frontier_paper, failure_log}"
  fi
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  valid_sources = %w[human_designed agent_generated frontier_paper failure_log]
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    src = c['source']
    if valid_sources.include?(src)
      puts 'OK:' + id
    else
      puts 'BAD:' + id + ':' + src.to_s
    end
  end
" 2>/dev/null || true)

# GSB baseline: at least 3 cases with gsb_baseline
gsb_count=$(yaml_has_nested_field "$CASES_FILE" "cases" "gsb_baseline")
if [[ "$gsb_count" -ge 3 ]]; then
  pass "GSB baseline: $gsb_count cases have gsb_baseline (≥3)"
else
  fail "GSB baseline: $gsb_count cases have gsb_baseline (<3, need ≥3)"
fi

# GSB baseline sub-fields check
while IFS= read -r line; do
  if [[ "$line" == OK:* ]]; then
    pass "Case '${line#OK:}' gsb_baseline has required sub-fields"
  else
    id=$(echo "$line" | cut -d: -f2)
    fields=$(echo "$line" | cut -d: -f3)
    fail "Case '$id' gsb_baseline missing: $fields"
  fi
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    next unless c['gsb_baseline']
    id = c['id'].to_s
    gsb = c['gsb_baseline']
    missing = []
    missing << 'bare_llm_expected' unless gsb['bare_llm_expected'] && !gsb['bare_llm_expected'].to_s.strip.empty?
    missing << 'skill_advantage'   unless gsb['skill_advantage']   && !gsb['skill_advantage'].to_s.strip.empty?
    if missing.empty?
      puts 'OK:' + id
    else
      puts 'MISSING:' + id + ':' + missing.join(',')
    end
  end
" 2>/dev/null || true)

# regression_level enum check: P0 | P1 (fail on invalid, not just missing)
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' regression_level is valid (P0/P1)" ;;
    MISSING:*) ;;  # already caught by required_fields check above
    INVALID:*)
      rest="${line#INVALID:}"; id="${rest%%:*}"; val="${rest#*:}"
      fail "Case '$id' regression_level '$val' not in {P0, P1}"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    rl = c['regression_level'].to_s.strip
    if rl.empty?
      # missing — already caught
    elsif %w[P0 P1].include?(rl)
      puts 'OK:' + id
    else
      puts 'INVALID:' + id + ':' + rl
    end
  end
" 2>/dev/null || true)

# ≥1 P0 regression_level case required (upgrade gate: P0 cases must all pass)
p0_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  puts (data['cases'] || []).count { |c| c['regression_level'].to_s == 'P0' }
" 2>/dev/null)
if [[ "$p0_count" -ge 1 ]]; then
  pass "P0 cases: $p0_count cases with regression_level P0 (upgrade gate requires ≥1)"
else
  fail "P0 cases: 0 cases with regression_level P0 (scaffold.md upgrade gate requires ≥1 P0 case)"
fi

# tier enum check (P0/P1/P2) — optional field, but must be valid enum if present
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' tier is valid (P0/P1/P2)" ;;
    INVALID:*)
      rest="${line#INVALID:}"; id="${rest%%:*}"; val="${rest#*:}"
      fail "Case '$id' tier '$val' not in {P0, P1, P2} (eval_protocol.md tier enum)"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    t = c['tier'].to_s.strip
    next if t.empty?  # tier is optional
    if %w[P0 P1 P2].include?(t)
      puts 'OK:' + id
    else
      puts 'INVALID:' + id + ':' + t
    end
  end
" 2>/dev/null || true)

# ===== v3 新增检测 =====

# dimension 字段：每条 case 必须有 dimension（scaffold.md §eval-case 必须字段）
while IFS= read -r line; do
  case "$line" in
    OK) pass "All cases have valid dimension field" ;;
    MISSING:*) fail "Case '${line#MISSING:}' missing dimension field (correctness/coverage/consistency)" ;;
    INVALID:*)
      id=$(echo "${line#INVALID:}" | cut -d: -f1)
      val=$(echo "${line#INVALID:}" | cut -d: -f2)
      fail "Case '$id' has invalid dimension '$val' (must be correctness|coverage|consistency)"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  valid_dims = %w[correctness coverage consistency]
  missing_dim = []
  invalid_dim = []
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    d = c['dimension']
    if d.nil?
      missing_dim << id
    elsif !valid_dims.include?(d)
      invalid_dim << id + ':' + d.to_s
    end
  end
  missing_dim.each { |id| puts 'MISSING:' + id }
  invalid_dim.each { |x| puts 'INVALID:' + x }
  puts 'OK' if missing_dim.empty? && invalid_dim.empty?
" 2>/dev/null || true)

# 三维度覆盖：correctness / coverage / consistency 各至少 1 条（scaffold.md §2.3 要求）
while IFS= read -r line; do
  dim="${line#*:}"
  if [[ "$line" == HAS:* ]]; then
    pass "Dimension '$dim' covered"
  else
    fail "Dimension '$dim' has no cases (scaffold.md requires all three dimensions covered)"
  fi
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  dims = (data['cases'] || []).map { |c| c['dimension'] }.compact.uniq
  %w[correctness coverage consistency].each do |d|
    puts dims.include?(d) ? 'HAS:' + d : 'MISSING:' + d
  end
" 2>/dev/null || true)

# source 多样性：frontier_paper 或非 human_designed 的 case ≥ 3（process.md §4/scaffold.md 要求）
non_human_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  count = (data['cases'] || []).count { |c| c['source'] != 'human_designed' }
  puts count
" 2>/dev/null)
if [[ "$non_human_count" -ge 3 ]]; then
  pass "Source diversity: $non_human_count non-human_designed cases (≥3)"
else
  fail "Source diversity: $non_human_count non-human_designed cases (<3, need frontier_paper/agent_generated ≥3 per scaffold.md)"
fi

# frontier_paper ≥2（process.md §4: ≥2 条标注 source: frontier_paper）
frontier_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  count = (data['cases'] || []).count { |c| c['source'].to_s == 'frontier_paper' }
  puts count
" 2>/dev/null)
if [[ "$frontier_count" -ge 2 ]]; then
  pass "frontier_paper sources: $frontier_count cases (≥2)"
else
  fail "frontier_paper sources: $frontier_count cases (<2, need ≥2 frontier_paper sources per process.md §4)"
fi

# frontier_paper cases must have paper title in description (process.md §4: 在 description 中注明论文标题)
while IFS= read -r line; do
  case "$line" in
    OK:*)   pass "frontier_paper case '${line#OK:}': description contains paper title reference" ;;
    WARN:*) fail "frontier_paper case '${line#WARN:}': description missing paper title (process.md §4: frontier_paper cases 必须在 description 中注明论文标题)" ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    next unless c['source'].to_s == 'frontier_paper'
    id = c['id'].to_s
    desc = c['description'].to_s.downcase
    orig_desc = c['description'].to_s
    # skip placeholder descriptions (skeleton TODOs are not yet filled in)
    next if orig_desc.include?('{TODO')
    # paper title indicator: quotes, year in parens, et al., or specific paper reference
    has_title = orig_desc.match?(/[\"\u201c\u201d\u2018\u2019'].*[\"\u201c\u201d\u2018\u2019']/) ||
                orig_desc.match?(/\([12][0-9]{3}\)/) ||
                orig_desc.match?(/et al\./) ||
                orig_desc.match?(/\b[A-Z][a-z]+\s+et\s+al/) ||
                desc.match?(/according to|based on|paper:|paper\s*:|from the paper/)
    puts has_title ? \"OK:#{id}\" : \"WARN:#{id}\"
  end
" 2>/dev/null || true)

# 60% domain vocab check: pass cases' contains assertions must be 60%+ domain-specific (scaffold.md §eval领域特异性)
# Generic terms to exclude: correctness, pass, fail, file, output, input, test, true, false, none, null, error, ok
domain_vocab_result=$(ruby -ryaml -e "
  generic = %w[correctness pass fail file output input test true false none null error ok warning info debug
               coverage consistency dimension source expected result actual status type value target field
               message code name version added_in description id assertion assertions]
  data = YAML.load_file('$CASES_FILE')
  pass_cases = (data['cases'] || []).select { |c| c['expected_result'] == 'pass' }
  all_vals = []
  pass_cases.each do |c|
    (c['assertions'] || []).each do |a|
      case a['type'].to_s
      when 'contains'
        v = a['value'].to_s.strip
        all_vals << v unless v.empty?
      when 'invoke_skill', 'invoke_skill_judge'
        (a['expected_contains'] || []).each { |v| all_vals << v.to_s.strip unless v.to_s.strip.empty? }
      end
    end
  end
  total = all_vals.length
  domain_specific = all_vals.count { |v| !generic.include?(v.downcase.strip) && v.length > 2 }
  pct = total > 0 ? (domain_specific.to_f / total * 100).round : 0
  puts \"#{domain_specific}/#{total}:#{pct}\"
" 2>/dev/null || echo "0/0:0")
dv_domain="${domain_vocab_result%%/*}"
dv_rest="${domain_vocab_result#*/}"
dv_total="${dv_rest%%:*}"
dv_pct="${dv_rest##*:}"
if [[ "$dv_total" -eq 0 ]]; then
  fail "Domain vocab check: no contains assertions found in pass cases (process.md §Step 7: 必须修复 — add domain-specific contains assertions)"
elif [[ "$dv_pct" -ge 60 ]]; then
  pass "Domain vocab ratio: ${dv_domain}/${dv_total} (${dv_pct}% ≥ 60% domain-specific, scaffold.md §eval领域特异性)"
else
  fail "Domain vocab ratio: ${dv_domain}/${dv_total} (${dv_pct}% < 60% domain-specific — process.md §Step 7: 必须修复，提升领域特异性)"
fi

# file_exists 占比：单一 file_exists 断言的 case 占比 ≤ 40%（fail）
while IFS= read -r line; do
  counts="${line%%:*}"
  pct="${line##*:}"
  file_only="${counts%%/*}"
  total="${counts##*/}"
  if [[ "$pct" -le 40 ]]; then
    pass "file_exists-only ratio: ${file_only}/${total} (${pct}% ≤ 40%)"
  else
    fail "file_exists-only ratio: ${file_only}/${total} (${pct}% > 40% — process.md §Step 7: 必须修复，降低 file_exists 单断言 case 占比)"
  fi
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  pass_cases = (data['cases'] || []).select { |c| c['expected_result'] == 'pass' }
  total = pass_cases.length
  file_only = pass_cases.count do |c|
    assertions = c['assertions'] || []
    assertions.all? { |a| a['type'] == 'file_exists' }
  end
  ratio = total > 0 ? file_only.to_f / total : 0
  puts \"#{file_only}/#{total}:#{(ratio * 100).round}\"
" 2>/dev/null || true)

# 全类型断言字段完整性检查（eval_protocol.md §断言类型表）
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' assertions all have required fields" ;;
    MISSING:*)
      rest="${line#MISSING:}"
      id="${rest%%:*}"
      detail="${rest#*:}"
      fail "Case '$id' assertion missing required fields: $detail"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    errors = []
    (c['assertions'] || []).each_with_index do |a, ai|
      t = a['type'].to_s
      errors << \"assertion[#{ai}]:missing:type\" if t.empty?
      case t
      when 'contains', 'file_exists', 'not_contains', 'structure_match'
        errors << \"#{t}:missing:value\" unless a['value'] && !a['value'].to_s.strip.empty?
      when 'yaml_valid'
        errors << \"yaml_valid:missing:target\" unless a['target'] && !a['target'].to_s.strip.empty?
      when 'yaml_field_equals'
        errors << \"yaml_field_equals:missing:target\" unless a['target'] && !a['target'].to_s.strip.empty?
        errors << \"yaml_field_equals:missing:field\"  unless a['field']  && !a['field'].to_s.strip.empty?
        errors << \"yaml_field_equals:missing:value\"  unless a['value']  && !a['value'].to_s.strip.empty?
      when 'min_count'
        errors << \"min_count:missing:target\"  unless a['target']  && !a['target'].to_s.strip.empty?
        errors << \"min_count:missing:element\" unless a['element'] && !a['element'].to_s.strip.empty?
        errors << \"min_count:missing:value\"   unless a['value']
      end
    end
    if errors.empty?
      puts 'OK:' + id
    else
      puts 'MISSING:' + id + ':' + errors.join(';')
    end
  end
" 2>/dev/null || true)

# Assertion type enum check: all types must be in known enum (eval_protocol.md §断言类型表)
while IFS= read -r line; do
  case "$line" in
    OK:*)      pass "Case '${line#OK:}' all assertion types are valid enum values" ;;
    UNKNOWN:*)
      rest="${line#UNKNOWN:}"
      id="${rest%%:*}"
      t="${rest#*:}"
      fail "Case '$id' has unknown assertion type: '$t' (eval_protocol.md valid types: file_exists/contains/not_contains/yaml_valid/yaml_field_equals/min_count/structure_match/run_script/invoke_skill/invoke_skill_judge/judge_calibration)"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  valid_types = %w[file_exists contains not_contains yaml_valid yaml_field_equals min_count structure_match run_script invoke_skill invoke_skill_judge judge_calibration]
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    unknown = (c['assertions'] || []).map { |a| a['type'].to_s }.reject { |t| valid_types.include?(t) || t.empty? }.uniq
    if unknown.empty?
      puts 'OK:' + id
    else
      unknown.each { |t| puts 'UNKNOWN:' + id + ':' + t }
    end
  end
" 2>/dev/null || true)

# ===== v4 新增检测 =====

# run_script 断言：至少 1 条 case 使用 run_script 类型（v4 核心能力）
run_script_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  count = (data['cases'] || []).count do |c|
    (c['assertions'] || []).any? { |a| a['type'] == 'run_script' }
  end
  puts count
" 2>/dev/null)
if [[ "$run_script_count" -ge 1 ]]; then
  pass "run_script assertions: $run_script_count cases use run_script (v4 executable assertions)"
else
  fail "run_script assertions: 0 cases use run_script (v4 requires ≥1 executable assertion)"
fi

# run_script 断言字段完整性检查
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' run_script has required fields (script)" ;;
    MISSING:*)
      rest="${line#MISSING:}"
      id="${rest%%:*}"
      fields="${rest#*:}"
      fail "Case '$id' run_script missing: $fields"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'run_script'
      missing = []
      missing << 'script' unless a['script'] && !a['script'].to_s.strip.empty?
      if missing.empty?
        puts 'OK:' + id
      else
        puts 'MISSING:' + id + ':' + missing.join(',')
      end
    end
  end
" 2>/dev/null || true)

# ⭐ v5: invoke_skill 断言：至少 1 条 case 使用 invoke_skill 类型（v5 核心能力）
invoke_skill_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  count = (data['cases'] || []).count do |c|
    (c['assertions'] || []).any? { |a| a['type'] == 'invoke_skill' }
  end
  puts count
" 2>/dev/null)
if [[ "$invoke_skill_count" -ge 1 ]]; then
  pass "invoke_skill assertions: $invoke_skill_count cases use invoke_skill (v5 LLM-level assertions)"
else
  fail "invoke_skill assertions: 0 cases use invoke_skill (v5 requires ≥1 LLM-level assertion)"
fi

# invoke_skill 断言字段完整性检查
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' invoke_skill has required fields (target, skill_file, input, expected_contains)" ;;
    MISSING:*)
      rest="${line#MISSING:}"
      id="${rest%%:*}"
      fields="${rest#*:}"
      fail "Case '$id' invoke_skill missing: $fields"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'invoke_skill'
      missing = []
      missing << 'target'     unless a['target']     && !a['target'].to_s.strip.empty?
      missing << 'skill_file' unless a['skill_file'] && !a['skill_file'].to_s.strip.empty?
      missing << 'input'      unless a['input']      && !a['input'].to_s.strip.empty?
      missing << 'expected_contains (must be non-empty list)' unless a['expected_contains'].is_a?(Array) && !a['expected_contains'].empty?
      if missing.empty?
        puts 'OK:' + id
      else
        puts 'MISSING:' + id + ':' + missing.join(',')
      end
    end
  end
" 2>/dev/null || true)

# ⭐ v6: invoke_skill_judge 断言：至少 1 条 case 使用 invoke_skill_judge 类型（v6 核心能力）
invoke_skill_judge_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  count = (data['cases'] || []).count do |c|
    (c['assertions'] || []).any? { |a| a['type'] == 'invoke_skill_judge' }
  end
  puts count
" 2>/dev/null)
if [[ "$invoke_skill_judge_count" -ge 1 ]]; then
  pass "invoke_skill_judge assertions: $invoke_skill_judge_count cases use invoke_skill_judge (v6 LLM-as-judge)"
else
  fail "invoke_skill_judge assertions: 0 cases use invoke_skill_judge (v6 requires ≥1 LLM-as-judge assertion)"
fi

# invoke_skill_judge 断言字段完整性检查
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' invoke_skill_judge has required fields (target, skill_file, input, judge_prompt)" ;;
    MISSING:*)
      rest="${line#MISSING:}"
      id="${rest%%:*}"
      fields="${rest#*:}"
      fail "Case '$id' invoke_skill_judge missing: $fields"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'invoke_skill_judge'
      missing = []
      missing << 'target'       unless a['target']       && !a['target'].to_s.strip.empty?
      missing << 'skill_file'   unless a['skill_file']   && !a['skill_file'].to_s.strip.empty?
      missing << 'input'        unless a['input']        && !a['input'].to_s.strip.empty?
      missing << 'judge_prompt' unless a['judge_prompt'] && !a['judge_prompt'].to_s.strip.empty?
      if missing.empty?
        puts 'OK:' + id
      else
        puts 'MISSING:' + id + ':' + missing.join(',')
      end
    end
  end
" 2>/dev/null || true)

# invoke_skill_judge judge_prompt PASS/FAIL keyword check (scaffold.md §invoke_skill_judge)
while IFS= read -r line; do
  case "$line" in
    OK:*)      pass "Case '${line#OK:}' invoke_skill_judge judge_prompt: contains PASS and FAIL keywords" ;;
    MISSING:*)
      rest="${line#MISSING:}"; id="${rest%%:*}"; missing="${rest#*:}"
      fail "Case '$id' invoke_skill_judge judge_prompt: missing '$missing' keyword (scaffold.md: judge_prompt must instruct PASS/FAIL)"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'invoke_skill_judge'
      prompt = a['judge_prompt'].to_s
      next if prompt.include?('{TODO') || prompt.strip.empty?
      missing = []
      missing << 'PASS' unless prompt.include?('PASS')
      missing << 'FAIL' unless prompt.include?('FAIL')
      if missing.empty?
        puts 'OK:' + id
      else
        puts 'MISSING:' + id + ':' + missing.join('/')
      end
    end
  end
" 2>/dev/null || true)

# ============================================================
# v7 新增检查
# ============================================================

# --- judge_calibration 断言存在性检查 ---
judge_calibration_count=$(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  count = (data['cases'] || []).count do |c|
    (c['assertions'] || []).any? { |a| a['type'] == 'judge_calibration' }
  end
  puts count
" 2>/dev/null)
if [[ "$judge_calibration_count" -ge 1 ]]; then
  pass "judge_calibration assertions: $judge_calibration_count cases use judge_calibration (v7 oracle quality)"
else
  fail "judge_calibration assertions: 0 cases use judge_calibration (v7 requires ≥1 calibration assertion)"
fi

# --- judge_calibration 字段完整性检查 ---
while IFS= read -r line; do
  case "$line" in
    OK:*) pass "Case '${line#OK:}' judge_calibration has required fields (judge_prompt, good_example, bad_example)" ;;
    MISSING:*)
      rest="${line#MISSING:}"
      id="${rest%%:*}"
      fields="${rest#*:}"
      fail "Case '$id' judge_calibration missing: $fields"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'judge_calibration'
      missing = []
      missing << 'judge_prompt'  unless a['judge_prompt']  && !a['judge_prompt'].to_s.strip.empty?
      missing << 'good_example'  unless a['good_example']  && !a['good_example'].to_s.strip.empty?
      missing << 'bad_example'   unless a['bad_example']   && !a['bad_example'].to_s.strip.empty?
      if missing.empty?
        puts 'OK:' + id
      else
        puts 'MISSING:' + id + ':' + missing.join(',')
      end
    end
  end
" 2>/dev/null || true)

# --- judge_calibration good_example != bad_example check, and minimum length ≥50 chars ---
while IFS= read -r line; do
  case "$line" in
    OK:*)      pass "Case '${line#OK:}' judge_calibration: good_example != bad_example (distinct samples)" ;;
    SAME:*)    fail "Case '${line#SAME:}' judge_calibration: good_example == bad_example (identical samples — calibration useless)" ;;
    SHORT_G:*) fail "Case '${line#SHORT_G:}' judge_calibration: good_example too short (<50 chars) — must be substantive example (scaffold.md: 足够长以展示能力差异)" ;;
    SHORT_B:*) fail "Case '${line#SHORT_B:}' judge_calibration: bad_example too short (<50 chars) — must be substantive example (scaffold.md: 足够长以展示能力差异)" ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'judge_calibration'
      good = a['good_example'].to_s.strip
      bad  = a['bad_example'].to_s.strip
      next if good.empty? || bad.empty? || good.include?('{TODO') || bad.include?('{TODO')
      if good == bad
        puts 'SAME:' + id
      elsif good.length < 50
        puts 'SHORT_G:' + id
      elsif bad.length < 50
        puts 'SHORT_B:' + id
      else
        puts 'OK:' + id
      end
    end
  end
" 2>/dev/null || true)

# --- judge_calibration judge_prompt contains PASS/FAIL keywords (scaffold.md §judge_calibration) ---
while IFS= read -r line; do
  case "$line" in
    OK:*)      pass "Case '${line#OK:}' judge_calibration judge_prompt: contains PASS and FAIL keywords" ;;
    MISSING:*)
      rest="${line#MISSING:}"; id="${rest%%:*}"; missing="${rest#*:}"
      fail "Case '$id' judge_calibration judge_prompt: missing '$missing' keyword (scaffold.md: judge_prompt 必须明确 PASS/FAIL 指令)"
      ;;
  esac
done < <(ruby -ryaml -e "
  data = YAML.load_file('$CASES_FILE')
  (data['cases'] || []).each do |c|
    id = c['id'].to_s
    (c['assertions'] || []).each do |a|
      next unless a['type'] == 'judge_calibration'
      prompt = a['judge_prompt'].to_s
      next if prompt.include?('{TODO') || prompt.strip.empty?
      missing = []
      missing << 'PASS' unless prompt.include?('PASS')
      missing << 'FAIL' unless prompt.include?('FAIL')
      if missing.empty?
        puts 'OK:' + id
      else
        puts 'MISSING:' + id + ':' + missing.join('/')
      end
    end
  end
" 2>/dev/null || true)

# --- P2 tier superseded_by 引用完整性检查 ---
while IFS= read -r line; do
  case "$line" in
    OK_SUP:*)     rest="${line#OK_SUP:}"; id="${rest%%:*}"; sup="${rest#*:}"; pass "P2 case '$id' superseded_by '$sup' (valid reference)" ;;
    MISSING_SUP:*) fail "P2 case '${line#MISSING_SUP:}' missing superseded_by field" ;;
    INVALID_SUP:*)
      rest="${line#INVALID_SUP:}"
      id="${rest%%:*}"; ref="${rest#*:}"
      fail "P2 case '$id' superseded_by '$ref' — case not found in suite"
      ;;
  esac
done < <(ruby -ryaml -rset -e "
  data = YAML.load_file('$CASES_FILE')
  cases = data['cases'] || []
  all_ids = cases.map { |c| c['id'] }.compact.to_set
  cases.each do |c|
    next unless c['tier'] == 'P2'
    id = c['id'].to_s
    sup = c['superseded_by'].to_s.strip
    if sup.empty?
      puts 'MISSING_SUP:' + id
    elsif !all_ids.include?(sup)
      puts 'INVALID_SUP:' + id + ':' + sup
    else
      puts 'OK_SUP:' + id + ':' + sup
    end
  end
" 2>/dev/null || true)

exit $_EXIT_CODE
