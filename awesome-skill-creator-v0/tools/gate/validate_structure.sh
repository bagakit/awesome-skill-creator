#!/usr/bin/env bash
# validate_structure.sh — Check directory structure and required files
# Usage: validate_structure.sh <skill-dir> [--ship]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

SKILL_DIR="${1:?Usage: validate_structure.sh <skill-dir> [--ship]}"
SKILL_DIR="${SKILL_DIR%/}"
SHIP_MODE="${2:-}"

echo "[Structure: $SKILL_DIR]"

# Required core files
required_files=(
  "SKILL.md"
  "process.md"
  "manifest.yaml"
  "evals/objective_cases.yaml"
  "evals/eval_protocol.md"
)

for f in "${required_files[@]}"; do
  if [[ -f "$SKILL_DIR/$f" ]]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

# process.md content checks (scaffold.md §process.md: Step 0 must be first)
if [[ -f "$SKILL_DIR/process.md" ]]; then
  if grep -qiE "(Step 0|Step0|目标定义|Goal.First)" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: Step 0 / 目标定义 present"
  else
    fail "process.md: missing Step 0 / 目标定义 (scaffold.md: Step 0 must be first step)"
  fi
  # Step 0 must be FIRST step — check it appears before Step 1 (scaffold.md: "必须是第一步")
  step0_line=$(grep -niE "^#{1,3}\s.*(Step 0|Step0|目标定义)" "$SKILL_DIR/process.md" 2>/dev/null | head -1 | cut -d: -f1)
  step1_line=$(grep -niE "^#{1,3}\s.*Step [1-9]" "$SKILL_DIR/process.md" 2>/dev/null | head -1 | cut -d: -f1)
  if [[ -n "$step0_line" && -n "$step1_line" ]]; then
    if [[ "$step0_line" -lt "$step1_line" ]]; then
      pass "process.md: Step 0 is first (line $step0_line < Step 1 at line $step1_line)"
    else
      fail "process.md: Step 0 (line $step0_line) appears after Step 1 (line $step1_line) — scaffold.md: Step 0 必须是第一步"
    fi
  fi
  if grep -qiE "(Preflight|preflight)" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: Preflight step present"
  else
    fail "process.md: missing Preflight step (scaffold.md required)"
  fi
  if grep -qiE "(sub.agent|sub_agent|Sub-Agent|SubAgent)" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: sub-agent orchestration step present"
  else
    fail "process.md: missing sub-agent orchestration step (scaffold.md §process.md required)"
  fi
  if grep -qiE "(attempt|尝试追踪|attempt-001)" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: attempt 追踪步骤 present"
  else
    fail "process.md: missing attempt 追踪步骤 (scaffold.md §process.md required)"
  fi
  # process.md minimum step count: should have ≥8 steps (Step 0 through Step 7+) (scaffold.md §process.md)
  step_count=$(grep -cE "^#{1,3}\s+Step [0-9]" "$SKILL_DIR/process.md" 2>/dev/null | tr -d ' ' || echo 0)
  if [[ "${step_count:-0}" -ge 8 ]]; then
    pass "process.md: ≥8 steps found ($step_count) (scaffold.md: Step 0 through Step 7+)"
  else
    fail "process.md: only $step_count numbered steps found (scaffold.md: Step 0 through Step 7+ required)"
  fi
  # I/O definition check: each step should have clear input/output (scaffold.md §process.md)
  if grep -qE "(Input:|Output:|→ 输出|→ 产出|produces|yields)" "$SKILL_DIR/process.md" 2>/dev/null || \
     grep -q "输入" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: input/output definitions present"
  else
    fail "process.md: no input/output definitions found (scaffold.md: 每个步骤有明确的输入/输出定义)"
  fi
  # process.md must reference validate.sh (scaffold.md §Step 7: 验收步骤必须运行 validate.sh)
  if grep -qE "validate\.sh" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: references validate.sh (scaffold.md §Step 7: 验收步骤必须运行 validate.sh)"
  else
    fail "process.md: missing validate.sh reference (scaffold.md §Step 7: 验收步骤必须包含 'tools/validate.sh <skill-dir>' 指令)"
  fi
  # process.md must reference run_eval.sh (scaffold.md §Step 7: 执行 eval 步骤必须运行 run_eval.sh)
  if grep -qE "run_eval\.sh" "$SKILL_DIR/process.md" 2>/dev/null; then
    pass "process.md: references run_eval.sh (scaffold.md §Step 7: eval 执行步骤)"
  else
    fail "process.md: missing run_eval.sh reference (scaffold.md §Step 7: 验收步骤必须包含 'bash tools/scripts/run_eval.sh <skill-dir>' 指令)"
  fi
fi

# SKILL.md content checks (scaffold.md §SKILL.md 必须包含的段落)
if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
  # Frontmatter name field (scaffold.md: Frontmatter 只使用 name、description)
  if grep -qE "^name:" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: frontmatter 'name' field present"
  else
    fail "SKILL.md: missing frontmatter 'name' field (scaffold.md §SKILL.md required)"
  fi
  # Frontmatter extra fields check (scaffold.md: "只使用支持的字段：name、description")
  fm_check=$(ruby -e "
    content = File.read('$SKILL_DIR/SKILL.md') rescue ''
    if content =~ /\A---\n(.*?)\n---/m
      fields = \$1.scan(/^(\w+)\s*:/).flatten
      extra = fields - ['name', 'description']
      puts extra.empty? ? 'OK' : 'EXTRA:' + extra.join(', ')
    else
      puts 'NO_FM'
    end
  " 2>/dev/null || echo "SKIP")
  case "$fm_check" in
    OK)      pass "SKILL.md: frontmatter only has allowed fields (name/description)" ;;
    EXTRA:*) fail "SKILL.md: frontmatter extra fields: ${fm_check#EXTRA:} (scaffold.md: only name+description allowed — move other fields to manifest.yaml)" ;;
    *)       : ;;
  esac
  if grep -qE "^description:" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: frontmatter 'description' field present"
    # description must contain at least 1 domain vocab term from .step0.yaml (process.md §3)
    # Skip if description is still a placeholder ({TODO}) or .step0.yaml has only TODO vocab
    if [[ -f "$SKILL_DIR/.step0.yaml" ]]; then
      desc_line=$(grep "^description:" "$SKILL_DIR/SKILL.md" 2>/dev/null | head -1)
      if echo "$desc_line" | grep -q "{TODO" 2>/dev/null; then
        : # placeholder not yet filled — skip
      else
        vocab_found=$(ruby -ryaml -e "
          step0 = YAML.load_file('$SKILL_DIR/.step0.yaml')
          vocab = (step0['domain_vocab'] || []).map { |v| v.to_s.downcase.split(/\s*\/\s*|\s*,\s*/).map(&:strip) }.flatten
          vocab = vocab.reject { |v| v.start_with?('todo') }
          desc = STDIN.read.downcase
          found = vocab.any? { |v| v.length > 2 && desc.include?(v) }
          puts found ? 'yes' : (vocab.empty? ? 'skip' : 'no')
        " <<< "$desc_line" 2>/dev/null || echo "skip")
        if [[ "$vocab_found" == "yes" ]]; then
          pass "SKILL.md: description contains domain vocab from .step0.yaml (process.md §3)"
        elif [[ "$vocab_found" == "no" ]]; then
          fail "SKILL.md: description must contain domain vocab from .step0.yaml (process.md §3: description 需含 domain_vocab 词汇)"
        fi
      fi
    fi
  else
    fail "SKILL.md: missing frontmatter 'description' field (scaffold.md §SKILL.md required)"
  fi
  if grep -qiE "(目标上下文|Goal Context|北极星目标|North.*Star|成功定义|Success.*Definit|领域词汇)" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: 目标上下文/Goal Context section present"
  else
    fail "SKILL.md: missing 目标上下文/Goal Context section (scaffold.md required)"
  fi
  if grep -qiE "(失败模式|Failure Mode|failure_mode|FailureMode)" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: 失败模式/Failure Modes section present (process.md §3.7)"
  else
    fail "SKILL.md: missing 失败模式/Failure Modes section (process.md §3.7: 引用 Step 0 的 2-3 个失败场景)"
  fi
  if grep -qiE "^#{1,3}\s.*(能力边界|Capability Boundary|Capabilities)" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: 能力边界/Capabilities section present"
  else
    fail "SKILL.md: missing 能力边界/Capabilities section (scaffold.md required)"
  fi
  if grep -qiE "^#{1,3}\s.*(核心约束|Core Constraint|Constraint)" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: 核心约束/Core Constraints section present"
  else
    fail "SKILL.md: missing 核心约束/Core Constraints section (scaffold.md required)"
  fi
  # SKILL.md must have trigger instructions / $ARGUMENTS handling (scaffold.md: 包含完整的触发指令和执行逻辑)
  if grep -qE "(\\\$ARGUMENTS|ARGUMENTS|--bootstrap|bootstrap|触发|trigger|when.*invoked)" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: trigger instructions / \$ARGUMENTS handling present (scaffold.md: 包含完整的触发指令和执行逻辑)"
  else
    fail "SKILL.md: missing trigger instructions / \$ARGUMENTS handling (scaffold.md: 包含完整的触发指令和执行逻辑)"
  fi
  # SKILL.md must reference process.md (process.md §3: 指令中引用 process.md，不内联)
  if grep -qE "process\.md" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
    pass "SKILL.md: references process.md (process.md §3: not inlined)"
  else
    fail "SKILL.md: must reference process.md rather than inlining the flow (process.md §3)"
  fi
fi

# genesis.md
dir_version=$(basename "$SKILL_DIR" | grep -oE 'v[0-9]+$' || true)
genesis_path="evolve_history/${dir_version}/genesis.md"
genesis_file=""
if [[ -f "$SKILL_DIR/$genesis_path" ]]; then
  pass "$genesis_path exists"
  genesis_file="$SKILL_DIR/$genesis_path"
elif find "$SKILL_DIR/evolve_history" -name "genesis.md" -type f 2>/dev/null | grep -q .; then
  pass "genesis.md exists (in evolve_history/)"
  genesis_file=$(find "$SKILL_DIR/evolve_history" -name "genesis.md" -type f 2>/dev/null | head -1)
else
  fail "genesis.md missing in evolve_history/"
fi

# genesis.md content checks (scaffold.md: 假设/方法/已知局限/未来方向/调研影响矩阵)
if [[ -n "$genesis_file" ]]; then
  if grep -qiE "^#{1,3}\s.*(假设|Design Assumption|Assumption)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 假设/Design Assumptions section present"
  else
    fail "genesis.md: missing 假设/Design Assumptions section (scaffold.md required)"
  fi
  if grep -qiE "^#{1,3}\s.*(方法|Method)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 方法/Methods section present"
  else
    fail "genesis.md: missing 方法/Methods section (scaffold.md required)"
  fi
  if grep -qiE "^#{1,3}\s.*(已知局限|Known Limitation)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 已知局限/Known Limitations section present"
  else
    fail "genesis.md: missing 已知局限/Known Limitations section (scaffold.md required)"
  fi
  if grep -qiE "^#{1,3}\s.*(未来方向|Future Direction)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 未来方向/Future Directions section present"
  else
    fail "genesis.md: missing 未来方向/Future Directions section (scaffold.md required)"
  fi
  if grep -qiE "(调研影响矩阵|研究影响矩阵|Research.*Matrix|Influence.*Matrix)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 调研影响矩阵 section present"
    # Matrix row count: ≥5 data rows (scaffold.md §self-bootstrap: ≥5 行，来源具体可查)
    # Exclude header rows (cells containing Chinese/English column titles without year/URL/domain content)
    # Count only data rows: rows that are NOT the first header row (skip row that precedes the |---|--- separator)
    matrix_rows=$(awk '/^\|[-| ]+\|/{found_sep=1; next} found_sep && /^\|[^-]/{count++} END{print count+0}' "$genesis_file" 2>/dev/null || echo 0)
    if grep -qE "^\|[^-].*\{TODO" "$genesis_file" 2>/dev/null; then
      : # still has TODO placeholders — skip row count requirement
    elif [[ "$matrix_rows" -ge 5 ]]; then
      pass "genesis.md: 调研影响矩阵 ≥5 rows ($matrix_rows found)"
    else
      fail "genesis.md: 调研影响矩阵 only $matrix_rows rows (<5, scaffold.md requires ≥5 specific sources — fill in real research)"
    fi
    # URL/citation check: matrix rows should have concrete titles/URLs/venues (scaffold.md §genesis)
    url_rows=$(grep -cE "^\|[^-].*(https?://|doi:|arxiv|github\.com|[0-9]{4})" "$genesis_file" 2>/dev/null | tr -d ' ' || echo 0)
    if grep -qE "^\|[^-].*\{TODO" "$genesis_file" 2>/dev/null; then
      : # still has TODO placeholders — skip citation requirement
    elif [[ "$url_rows" -ge 3 ]]; then
      pass "genesis.md: 调研影响矩阵 ≥3 rows have concrete citations/URLs ($url_rows found)"
    else
      fail "genesis.md: 调研影响矩阵 only $url_rows rows with concrete citations/URLs/years (<3, scaffold.md: 每条来源必须包含具体标题/URL/会议名)"
    fi
  else
    fail "genesis.md: missing 调研影响矩阵 section (scaffold.md required)"
  fi
  # 被否决方案 section (process.md §Step 6: 必须包含第3项)
  if grep -qiE "(被否决|否决方案|Rejected.*Alternative|rejected_alternative|Discarded.*Option|未采用)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 被否决方案/Rejected Alternatives section present (process.md §Step 6)"
  else
    fail "genesis.md: missing 被否决方案/Rejected Alternatives section (process.md §Step 6: 必须包含第3项)"
  fi
  # independent evaluation framework section (release_checklist.md: genesis.md must include 独立评估框架)
  if grep -qiE "(独立评估|independent.*eval|evaluator.*framework|评估框架)" "$genesis_file" 2>/dev/null; then
    pass "genesis.md: 独立评估框架/Independent Evaluation section present"
  else
    fail "genesis.md: missing 独立评估框架 section (release_checklist.md: genesis.md must include 独立评估框架)"
  fi
fi

# .step0.yaml — optional but checked if present (process.md §Step 0 protocol)
if [[ -f "$SKILL_DIR/.step0.yaml" ]]; then
  while IFS= read -r result; do
    case "$result" in
      OK)            pass ".step0.yaml valid (success_definition + failure_modes + domain_vocab)" ;;
      COUNT:*)       fail ".step0.yaml failure_modes: ${result#COUNT:} (process.md §Step 0: ≥3 real failure_modes required — not enough non-TODO entries)" ;;
      MISSING:*)     fail ".step0.yaml missing required fields: ${result#MISSING:}" ;;
    esac
  done < <(ruby -ryaml -e "
    y = YAML.load_file('$SKILL_DIR/.step0.yaml')
    missing = []
    missing << 'success_definition' unless y['success_definition']
    fms = y['failure_modes']
    missing << 'failure_modes' unless fms.is_a?(Array) && !fms.empty?
    missing << 'domain_vocab' unless y['domain_vocab'].is_a?(Array) && !y['domain_vocab'].empty?
    if missing.empty?
      fm_count = fms.length
      todo_count = fms.count { |f| f.to_s.include?('TODO') }
      real_count = fm_count - todo_count
      if real_count > 0 && real_count < 3
        puts \"COUNT:#{real_count} failure_modes (expected ≥3, got #{real_count})\"
      else
        puts 'OK'
      end
    else
      puts \"MISSING:#{missing.join(',')}\"
    end
  " 2>/dev/null || true)
  # failure_modes item sub-fields: each must have id, description, eval_detection (process.md §Step 0)
  while IFS= read -r line; do
    case "$line" in
      OK)       pass ".step0.yaml failure_modes items have required sub-fields (id/description/eval_detection)" ;;
      SKIP)     : ;;
      MISSING:*) fail ".step0.yaml failure_modes item missing sub-fields: ${line#MISSING:} (process.md §Step 0 format)" ;;
    esac
  done < <(ruby -ryaml -e "
    y = YAML.load_file('$SKILL_DIR/.step0.yaml')
    fms = y['failure_modes'] || []
    if fms.empty?
      puts 'SKIP'
    else
      bad = []
      fms.each_with_index do |fm, i|
        if fm.is_a?(Hash)
          next if fm.to_s.include?('{TODO') || fm['id'].to_s.include?('TODO')
          %w[id description eval_detection].each do |f|
            bad << \"item #{i+1} missing '#{f}'\" unless fm[f] && !fm[f].to_s.empty?
          end
        else
          # String-type entry: skip if placeholder, fail if real content
          next if fm.to_s.include?('TODO')
          bad << \"item #{i+1} is a plain string (must be dict with id/description/eval_detection, got: '#{fm.to_s[0..40]}')\"
        end
      end
      bad.empty? ? puts('OK') : puts('MISSING:' + bad.first)
    end
  " 2>/dev/null || true)
  # domain_vocab minimum count ≥5 (process.md §Step 0: 领域词汇表，至少 5 项)
  dv_result=$(ruby -ryaml -e "
    y = YAML.load_file('$SKILL_DIR/.step0.yaml')
    vocab = y['domain_vocab'] || []
    real_vocab = vocab.reject { |v| v.to_s.include?('TODO') }
    if real_vocab.length >= 5
      puts 'OK:' + real_vocab.length.to_s
    elsif real_vocab.empty?
      puts 'SKIP'
    else
      puts 'LOW:' + real_vocab.length.to_s
    end
  " 2>/dev/null || echo "SKIP")
  case "$dv_result" in
    OK:*)   pass ".step0.yaml domain_vocab: ${dv_result#OK:} terms (≥5, process.md §Step 0)" ;;
    LOW:*)  fail ".step0.yaml domain_vocab: ${dv_result#LOW:} terms (<5, process.md §Step 0: 领域词汇表至少 5 项)" ;;
    SKIP)   : ;;
  esac
  # success_definition must use domain vocab (process.md §Step 0: 用领域词汇描述具体成功输出)
  sd_result=$(ruby -ryaml -e "
    y = YAML.load_file('$SKILL_DIR/.step0.yaml')
    sd = y['success_definition'].to_s
    if sd.empty? || sd.include?('TODO')
      puts 'SKIP'
    else
      vocab = (y['domain_vocab'] || []).map { |v| v.to_s.downcase }.reject { |v| v.include?('todo') || v.length <= 2 }
      if vocab.empty?
        puts 'SKIP'
      else
        sd_lower = sd.downcase
        found = vocab.any? { |v| sd_lower.include?(v) }
        puts found ? 'OK' : 'WARN'
      end
    end
  " 2>/dev/null || echo "SKIP")
  case "$sd_result" in
    OK)   pass ".step0.yaml success_definition: contains domain vocab term (process.md §Step 0)" ;;
    WARN) fail ".step0.yaml success_definition: must use domain vocab terms (process.md §Step 0: 用领域词汇描述具体成功输出 — generic descriptions not acceptable)" ;;
    SKIP) : ;;
  esac
  # created_at format check (process.md §Step 0 format: ISO date)
  cat_val=$(ruby -ryaml -e "puts YAML.load_file('$SKILL_DIR/.step0.yaml')['created_at'].to_s" 2>/dev/null || true)
  if [[ -z "$cat_val" || "$cat_val" == "null" ]]; then
    fail ".step0.yaml missing created_at field (process.md §Step 0 format: created_at: YYYY-MM-DD)"
  elif [[ "$cat_val" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    pass ".step0.yaml created_at '$cat_val' is valid ISO date"
  else
    fail ".step0.yaml created_at '$cat_val' not in YYYY-MM-DD format (process.md §Step 0)"
  fi
  # skill_name field check (process.md §Step 0 format: skill_name: <name>)
  sn_val=$(ruby -ryaml -e "puts YAML.load_file('$SKILL_DIR/.step0.yaml')['skill_name'].to_s" 2>/dev/null || true)
  dir_basename="$(basename "$SKILL_DIR")"
  if [[ -z "$sn_val" ]]; then
    fail ".step0.yaml missing skill_name field (process.md §Step 0 format: skill_name: <name>)"
  elif [[ "$sn_val" == "$dir_basename" ]]; then
    pass ".step0.yaml skill_name '$sn_val' consistent with directory"
  elif echo "$sn_val" | grep -q "{TODO"; then
    : # skeleton placeholder — skip
  else
    fail ".step0.yaml skill_name '$sn_val' does not match directory '${dir_basename}' (process.md §Step 0)"
  fi
else
  fail ".step0.yaml missing (required for v4+; was optional/warn in v3)"
fi

# Directory name pattern: {name}-v{N}
dir_name="$(basename "$SKILL_DIR")"
if [[ "$dir_name" =~ ^[a-z][a-z0-9-]*-v[0-9]+$ ]]; then
  pass "Directory name '$dir_name' matches {name}-v{N} pattern"
else
  fail "Directory name '$dir_name' does not match {name}-v{N} pattern"
fi

# locks/ — required by whitepaper §2.5
for lock in evolve.lock promote.lock register.lock; do
  if [[ -f "$SKILL_DIR/locks/$lock" ]]; then
    pass "locks/$lock exists"
  else
    fail "locks/$lock missing (required by whitepaper §2.5)"
  fi
done

# eval_research/ — required by whitepaper §3.2
for json in literature_review.json frontier_impls.json tool_analysis.json edge_cases.json user_scenarios.json; do
  json_path="$SKILL_DIR/evals/eval_research/$json"
  # Expected agent_type per file (scaffold.md §eval_research) — use case to avoid declare -A (bash 3.2 compat)
  case "$json" in
    literature_review.json) expected_atype="literature-research" ;;
    frontier_impls.json)    expected_atype="frontier-impl-analysis" ;;
    tool_analysis.json)     expected_atype="tool-analysis" ;;
    edge_cases.json)        expected_atype="edge-cases" ;;
    user_scenarios.json)    expected_atype="user-scenarios" ;;
    *)                      expected_atype="" ;;
  esac
  if [[ -f "$json_path" ]]; then
    pass "evals/eval_research/$json exists"
    # JSON validity check
    if ruby -rjson -e "JSON.parse(File.read('$json_path'))" 2>/dev/null; then
      pass "evals/eval_research/$json is valid JSON"
      # Schema check: required fields (scaffold.md §eval_research schema)
      while IFS= read -r schema_line; do
        if [[ "$schema_line" == OK ]]; then
          pass "evals/eval_research/$json has required schema fields"
        else
          fail "evals/eval_research/$json missing schema fields: ${schema_line#MISSING:} (scaffold.md §eval_research required)"
        fi
      done < <(ruby -rjson -e "
        data = JSON.parse(File.read('$json_path'))
        required = %w[generated_at skill_domain agent_type findings top_insights suggested_eval_cases]
        missing = required.reject { |f| data.key?(f) }
        if missing.empty?
          puts 'OK'
        else
          puts 'MISSING:' + missing.join(',')
        end
      " 2>/dev/null || true)
      # generated_at date format check (process.md §2.2 schema: YYYY-MM-DD)
      gen_at=$(ruby -rjson -e "puts JSON.parse(File.read('$json_path'))['generated_at'].to_s" 2>/dev/null || true)
      if [[ "$gen_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        pass "evals/eval_research/$json generated_at format valid: $gen_at"
      elif [[ "$gen_at" == "TODO" || "$gen_at" == "" ]]; then
        fail "evals/eval_research/$json generated_at missing or placeholder (process.md §2.2 requires YYYY-MM-DD)"
      else
        fail "evals/eval_research/$json generated_at '$gen_at' not in YYYY-MM-DD format (process.md §2.2)"
      fi

      # top_insights count check (process.md §2.2 schema example shows 3 items; require ≥3)
      ti_count=$(ruby -rjson -e "
        data = JSON.parse(File.read('$json_path'))
        puts (data['top_insights'] || []).length
      " 2>/dev/null || echo "0")
      if [[ "${ti_count:-0}" -ge 3 ]]; then
        pass "evals/eval_research/$json top_insights: $ti_count insight(s)"
      elif [[ "${ti_count:-0}" -ge 1 ]]; then
        fail "evals/eval_research/$json top_insights: only $ti_count (<3, process.md §2.2 schema requires ≥3 top insights)"
      else
        fail "evals/eval_research/$json top_insights is empty (process.md §2.2 schema requires ≥3)"
      fi

      # agent_type enum check (scaffold.md §eval_research agent_type values)
      actual_atype=$(ruby -rjson -e "puts JSON.parse(File.read('$json_path'))['agent_type'].to_s" 2>/dev/null || true)
      if [[ "$actual_atype" == "$expected_atype" ]]; then
        pass "evals/eval_research/$json agent_type '$actual_atype' matches expected"
      else
        fail "evals/eval_research/$json agent_type '$actual_atype' does not match expected '$expected_atype' (scaffold.md §eval_research: agent_type must match filename)"
      fi
      # suggested_eval_cases sub-schema: description/source_title/dimension/expected_result (scaffold.md §eval_research)
      while IFS= read -r sline; do
        case "$sline" in
          OK)        pass "evals/eval_research/$json suggested_eval_cases required fields valid" ;;
          MISSING:*) fail "evals/eval_research/$json suggested_eval_cases missing fields: ${sline#MISSING:} (scaffold.md §eval_research)" ;;
          INVALID:*) fail "evals/eval_research/$json suggested_eval_cases invalid enum: ${sline#INVALID:} (scaffold.md §eval_research)" ;;
        esac
      done < <(ruby -rjson -e "
        data = JSON.parse(File.read('$json_path'))
        cases = data['suggested_eval_cases'] || []
        if cases.empty?
          puts 'OK'
        else
          real_cases = cases.reject { |c| c.to_s.include?('TODO') }
          missing_fields = real_cases.flat_map { |c|
            m = []
            m << 'description' unless c['description'] && !c['description'].to_s.strip.empty?
            m << 'source_title' unless c['source_title'] && !c['source_title'].to_s.strip.empty?
            m
          }.uniq
          invalid = real_cases.select { |c|
            d = c['dimension'].to_s; e = c['expected_result'].to_s
            !(d =~ /^(correctness|coverage|consistency)$/) ||
            !(e =~ /^(pass|fail)$/)
          }.map { |c| \"dim=#{c['dimension']},result=#{c['expected_result']}\" }
          if !missing_fields.empty?
            puts 'MISSING:' + missing_fields.join(',')
          elsif !invalid.empty?
            puts 'INVALID:' + invalid.first
          else
            puts 'OK'
          end
        end
      " 2>/dev/null || true)
      # findings entry sub-schema check (scaffold.md §eval_research: title/source/year/key_finding/design_impact)
      while IFS= read -r fline; do
        case "$fline" in
          OK) pass "evals/eval_research/$json findings entries have required sub-fields" ;;
          EMPTY) fail "evals/eval_research/$json findings list is empty (scaffold.md §eval_research requires ≥1 research finding)" ;;
          MISSING:*) fail "evals/eval_research/$json findings entry missing sub-fields: ${fline#MISSING:} (scaffold.md §eval_research schema)" ;;
        esac
      done < <(ruby -rjson -e "
        data = JSON.parse(File.read('$json_path'))
        required = %w[title source year key_finding design_impact]
        findings = data['findings'] || []
        if findings.empty?
          puts 'EMPTY'
        else
          all_missing = findings.flat_map { |f| required.reject { |k| f.key?(k) && !f[k].to_s.strip.empty? } }.uniq
          if all_missing.empty?
            puts 'OK'
          else
            puts 'MISSING:' + all_missing.join(',')
          end
        end
      " 2>/dev/null || true)
      # findings minimum count ≥2 (scaffold.md §eval_research: 调研文件应有不少于2条真实发现)
      # Skip if all findings are TODO placeholders (skeleton)
      while IFS= read -r fcount; do
        case "$fcount" in
          SKIP)    : ;;  # all TODO placeholders — skeleton, skip
          OK:*)    pass "evals/eval_research/$json findings count: ${fcount#OK:} entries (≥2, scaffold.md §eval_research depth)" ;;
          LOW:*)   fail "evals/eval_research/$json findings count: ${fcount#LOW:} entries (<2 real findings, scaffold.md §eval_research: each file should have ≥2 actual research findings)" ;;
        esac
      done < <(ruby -rjson -e "
        data = JSON.parse(File.read('$json_path'))
        findings = data['findings'] || []
        real = findings.reject { |f| f['title'].to_s.include?('TODO') || f['key_finding'].to_s.include?('TODO') }
        if real.empty?
          puts 'SKIP'
        elsif real.length >= 2
          puts 'OK:' + real.length.to_s
        else
          puts 'LOW:' + real.length.to_s
        end
      " 2>/dev/null || true)
      # findings source quality check: academic/tool research entries should have URL/conference/year (process.md §2.3)
      # Skip user_scenarios.json (internally derived scenarios) and tool_analysis community entries
      case "$json" in
        user_scenarios.json) : ;;  # user scenarios are internally derived — no external citation required
        *)
          while IFS= read -r qline; do
            case "$qline" in
              OK)         pass "evals/eval_research/$json findings sources have concrete citations (URL/conference/year)" ;;
              PLACEHOLDER) : ;;  # all TODO/placeholder — skip
              POOR:*)     fail "evals/eval_research/$json findings entry has vague source: ${qline#POOR:} (process.md §2.3: source must be URL or conference/journal name — e.g. 'NeurIPS 2023' or 'https://...')" ;;
            esac
          done < <(ruby -rjson -e "
            data = JSON.parse(File.read('$json_path'))
            findings = (data['findings'] || []).reject { |f| f['title'].to_s.include?('TODO') || f['source'].to_s.include?('TODO') }
            if findings.empty?
              puts 'PLACEHOLDER'
            else
              poor = findings.select { |f|
                s = f['source'].to_s
                # Good: has URL, arxiv, doi, conference name, journal year, github
                !(s.match?(/https?:\/\//) || s.match?(/arxiv/i) || s.match?(/doi:/i) ||
                  s.match?(/github\.com/i) || s.match?(/[0-9]{4}/) || s.match?(/ICLR|NeurIPS|ICML|ACL|EMNLP|CVPR|ICCV|ECCV|AAAI|IJCAI/i) ||
                  s.include?('.md') || s.include?('internal') || s.include?('community'))
              }.map { |f| f['title'].to_s[0, 40] }
              poor.empty? ? puts('OK') : poor.each { |t| puts 'POOR:' + t }
            end
          " 2>/dev/null || true)
          ;;
      esac
    else
      fail "evals/eval_research/$json is invalid JSON"
    fi
  else
    fail "evals/eval_research/$json missing (required sub-agent research artifact)"
  fi
done

# evals/cases/ — v3 legacy dirs; v4+ uses evals/objective_cases.yaml (SSOT)
# Neither required nor prohibited; no check emitted (avoids noise for both old and new skills)

# Article directory — must be named exactly 'article' (whitepaper §2.3); required for --ship
if [[ -d "$SKILL_DIR/evolve_history/${dir_version}/article" ]]; then
  pass "evolve_history/${dir_version}/article/ exists"
  article_md=$(find "$SKILL_DIR/evolve_history/${dir_version}/article" -maxdepth 1 -name "*.md" 2>/dev/null | head -1)
  if [[ -n "$article_md" ]]; then
    pass "Article markdown found: $(basename "$article_md")"
  else
    fail "No article markdown found in article/ (scaffold.md: article/ must contain an .md file)"
  fi
elif [[ "$SHIP_MODE" == "--ship" ]]; then
  fail "evolve_history/${dir_version}/article/ missing (scaffold.md: Article 目录必须存在 — required for --ship)"
fi

# evolution.md — must be named exactly 'evolution.md' (whitepaper §2.3)
if [[ -f "$SKILL_DIR/evolve_history/${dir_version}/evolution.md" ]]; then
  pass "evolve_history/${dir_version}/evolution.md exists"
  evo_file="$SKILL_DIR/evolve_history/${dir_version}/evolution.md"
  # Content checks: 4 required sections (scaffold.md §Evolution 核心要求)
  if grep -qiE "(现状评估|当前状态|Current State|Eval.*Rate|量化对比|性能对比|通过率)" "$evo_file" 2>/dev/null; then
    pass "evolution.md: 现状评估/Current State section present"
    # Quantified performance: must contain pass rate numbers or percentages (scaffold.md: 量化表现)
    if grep -qE "\{TODO" "$evo_file" 2>/dev/null; then
      : # skeleton placeholder — skip quantification check
    elif grep -qE "[0-9]+/[0-9]+|[0-9]+%|[0-9]+ pass|通过率.*[0-9]|[0-9]+.*通过" "$evo_file" 2>/dev/null; then
      pass "evolution.md: 现状评估 contains quantified performance data (scaffold.md: 量化表现)"
    else
      fail "evolution.md: 现状评估 must contain quantified performance data (scaffold.md: 量化表现 — add pass rate e.g. '44/44 passed')"
    fi
  else
    fail "evolution.md: missing 现状评估/Current State section (scaffold.md §Evolution required)"
  fi
  if grep -qiE "(不足分析|Weakness|Limitation|缺陷|设计取舍|局限|已知局限)" "$evo_file" 2>/dev/null; then
    pass "evolution.md: 不足分析/Weaknesses section present"
  else
    fail "evolution.md: missing 不足分析/Weaknesses section (scaffold.md §Evolution required)"
  fi
  if grep -qiE "(Top 3|Top3|优化建议|Optimization|优化方向)" "$evo_file" 2>/dev/null; then
    pass "evolution.md: Top 3 优化建议 section present"
    # Check that at least 3 recommendation items exist (numbered 1/2/3 or heading items)
    evo_item_count=$(grep -cE "^(###|[1-9]\.|[1-9]\))\s" "$evo_file" 2>/dev/null | tr -d ' ' || echo 0)
    if [[ "${evo_item_count:-0}" -ge 3 ]]; then
      pass "evolution.md: ≥3 recommendation items found ($evo_item_count) (scaffold.md: Top 3 按进化效率排序)"
    else
      fail "evolution.md: only $evo_item_count numbered items found (<3, scaffold.md: Top 3 优化建议 requires ≥3 items)"
    fi
    # Each Top 3 item should contain all 4 elements: 问题/方案/收益/复杂度 (scaffold.md: 每条含问题/方案/收益/复杂度)
    if grep -qE "\{TODO" "$evo_file" 2>/dev/null; then
      : # skeleton/placeholder — skip per-item structure check
    else
      if grep -qiE "问题|Problem|现状|痛点|challenge|issue" "$evo_file" 2>/dev/null; then
        pass "evolution.md: contains 问题/Problem element (scaffold.md: 每条含问题/方案/收益/复杂度)"
      else
        fail "evolution.md: missing 问题/Problem element (scaffold.md: 每条含问题/方案/收益/复杂度 — required)"
      fi
      if grep -qiE "方案|Solution|解决|实现|改进|approach" "$evo_file" 2>/dev/null; then
        pass "evolution.md: contains 方案/Solution element (scaffold.md: 每条含问题/方案/收益/复杂度)"
      else
        fail "evolution.md: missing 方案/Solution element (scaffold.md: 每条含问题/方案/收益/复杂度 — required)"
      fi
      if grep -qiE "收益|Benefit|价值|改善|gain|benefit" "$evo_file" 2>/dev/null; then
        pass "evolution.md: contains 收益/Benefit element (scaffold.md: 每条含问题/方案/收益/复杂度)"
      else
        fail "evolution.md: missing 收益/Benefit element (scaffold.md: 每条含问题/方案/收益/复杂度 — required)"
      fi
      if grep -qiE "复杂度|Complexity|难度|complexity|effort" "$evo_file" 2>/dev/null; then
        pass "evolution.md: contains 复杂度/Complexity element (scaffold.md: 每条含问题/方案/收益/复杂度)"
      else
        fail "evolution.md: missing 复杂度/Complexity element (scaffold.md: 每条含问题/方案/收益/复杂度 — required)"
      fi
    fi
  else
    fail "evolution.md: missing Top 3 优化建议 section (scaffold.md §Evolution required)"
  fi
  if grep -qiE "(依赖分析|Dependency|攻破顺序|Attack Order|执行顺序|建议.*顺序)" "$evo_file" 2>/dev/null; then
    pass "evolution.md: 依赖分析/Dependency Analysis section present"
  else
    fail "evolution.md: missing 依赖分析/Dependency Analysis section (scaffold.md §Evolution required)"
  fi
elif [[ "$SHIP_MODE" == "--ship" ]]; then
  fail "evolve_history/${dir_version}/evolution.md missing (scaffold.md: evolution.md 必须存在 — required for --ship)"
fi

# attempt-001 required artifacts (whitepaper §3.2)
attempt_dir="$SKILL_DIR/evolve_history/${dir_version}/attempts/attempt-001"
if [[ -d "$attempt_dir" ]]; then
  pass "attempt-001/ exists"
  for artifact in hypothesis.md diff.md preflight.json eval_report.json blind_eval_report.json stress_report.json verdict.json; do
    if [[ -f "$attempt_dir/$artifact" ]]; then
      pass "attempt-001/$artifact exists"
    else
      fail "attempt-001/$artifact missing (required by whitepaper §3.2)"
    fi
  done
  # verdict.json content: must have 'verdict' + attempt_id + evidence fields (process.md §attempt format)
  if [[ -f "$attempt_dir/verdict.json" ]]; then
    vj_result=$(ruby -rjson -e "
      begin
        j = JSON.parse(File.read('$attempt_dir/verdict.json'))
        missing = []
        missing << 'verdict'    unless j.key?('verdict')
        missing << 'attempt_id' unless j.key?('attempt_id')
        missing << 'evidence'   unless j.key?('evidence')
        # verdict must be pass|fail (not arbitrary string) when execution_status != pending
        v = j['verdict'].to_s
        if j.key?('verdict') && !v.empty? && !%w[pass fail pending].include?(v)
          missing << \"verdict '#{v}' not in {pass, fail}\"
        end
        # evidence must be non-empty when execution_status is actual
        if j.key?('evidence') && j['execution_status'].to_s == 'actual' && j['evidence'].to_s.strip.empty?
          missing << 'evidence (empty - must describe actual execution result)'
        end
        missing.empty? ? puts('OK') : puts('MISSING:' + missing.join(', '))
      rescue => e
        puts 'ERROR:' + e.message
      end
    " 2>/dev/null || echo "ERROR:ruby failed")
    case "$vj_result" in
      OK)        pass "attempt-001/verdict.json: required fields present (verdict/attempt_id/evidence)" ;;
      MISSING:*) fail "attempt-001/verdict.json: missing fields: ${vj_result#MISSING:} (process.md §attempt: 引用以上文件的实际结果)" ;;
      ERROR:*)   fail "attempt-001/verdict.json: JSON parse error — ${vj_result#ERROR:}" ;;
    esac
  fi
  # hypothesis.md content: must have target_point + 假设/Hypothesis (process.md §hypothesis format)
  if [[ -f "$attempt_dir/hypothesis.md" ]]; then
    if grep -qiE "(target_point|目标优化点)" "$attempt_dir/hypothesis.md" 2>/dev/null; then
      pass "attempt-001/hypothesis.md: target_point field present"
    else
      fail "attempt-001/hypothesis.md: missing target_point field (process.md §hypothesis required)"
    fi
    if grep -qiE "(假设|Hypothesis|hypothesis)" "$attempt_dir/hypothesis.md" 2>/dev/null; then
      pass "attempt-001/hypothesis.md: 假设/Hypothesis field present"
    else
      fail "attempt-001/hypothesis.md: missing 假设/Hypothesis field (process.md §hypothesis required)"
    fi
    if grep -qiE "(预期证据|预期成功|expected.*evidence|Expected.*Evidence|expected.*success|成功标准)" "$attempt_dir/hypothesis.md" 2>/dev/null; then
      pass "attempt-001/hypothesis.md: 预期证据/Expected Evidence field present"
    else
      fail "attempt-001/hypothesis.md: missing 预期证据/Expected Evidence field (process.md §Step 10 format: 预期证据 field required)"
    fi
  fi
  # diff.md content: must describe actual changes vs baseline (process.md §Step 10 format)
  if [[ -f "$attempt_dir/diff.md" ]]; then
    if grep -qiE "(与基线|Baseline|specific.*change|具体.*改动|改动|Diff|diff|v[0-9]+.*→|→.*v[0-9]+)" "$attempt_dir/diff.md" 2>/dev/null; then
      pass "attempt-001/diff.md: has baseline comparison content"
    elif grep -qiE "\{TODO" "$attempt_dir/diff.md" 2>/dev/null; then
      : # still placeholder — skip
    else
      fail "attempt-001/diff.md: no baseline comparison found (process.md §Step 10: diff.md must describe changes vs baseline)"
    fi
  fi
  # execution_status check (scaffold.md §attempts: "predicted" 结果不算有效执行证据)
  for json_artifact in preflight.json eval_report.json blind_eval_report.json stress_report.json verdict.json; do
    json_file="$attempt_dir/$json_artifact"
    if [[ -f "$json_file" ]]; then
      if grep -q '"predicted"' "$json_file" 2>/dev/null; then
        fail "attempt-001/$json_artifact execution_status: 'predicted' found (scaffold.md: 预测结果不算有效执行证据)"
      elif grep -q '"actual"' "$json_file" 2>/dev/null; then
        pass "attempt-001/$json_artifact execution_status: actual"
      else
        warn "attempt-001/$json_artifact execution_status not 'actual' yet (fill in after real execution)"
      fi
    fi
  done

  # preflight.json schema: required fields + verdict enum (process.md §Step 4.5)
  if [[ -f "$attempt_dir/preflight.json" ]]; then
    pf_result=$(ruby -rjson -e "
      begin
        j = JSON.parse(File.read('$attempt_dir/preflight.json'))
        # Skip schema checks for pending/placeholder skeletons
        if j['execution_status'].to_s == 'pending' || j['verdict'].to_s == 'pending'
          puts 'PENDING'
        else
          missing = []
          missing << 'attempt_id' unless j['attempt_id']
          missing << 'timestamp' unless j['timestamp']
          missing << 'sanity_cases_run' unless j['sanity_cases_run'].is_a?(Array)
          missing << 'sanity_cases_run (empty — ≥1 required per process.md §Step 4)' if j['sanity_cases_run'].is_a?(Array) && j['sanity_cases_run'].empty? && j['execution_status'].to_s == 'actual'
          missing << 'results' unless j['results'].is_a?(Hash)
          missing << 'verdict' unless j.key?('verdict')
          verdict = j['verdict'].to_s
          if !missing.include?('verdict') && !%w[proceed abort].include?(verdict)
            missing << \"verdict '#{verdict}' not in {proceed, abort}\"
          end
          # abort requires abort_reason (process.md §Step 4.5)
          if verdict == 'abort' && !j['abort_reason']
            missing << 'abort_reason (required when verdict=abort)'
          end
          if missing.empty?
            puts 'OK'
          else
            puts 'MISSING:' + missing.join(',')
          end
        end
      rescue => e
        puts 'ERROR:' + e.message
      end
    " 2>/dev/null || echo "ERROR:ruby failed")
    case "$pf_result" in
      OK)        pass "attempt-001/preflight.json: all required fields present (attempt_id/timestamp/sanity_cases_run/results/verdict)" ;;
      PENDING)   pass "attempt-001/preflight.json: pending skeleton — schema check deferred" ;;
      MISSING:*) fail "attempt-001/preflight.json: missing fields or invalid values: ${pf_result#MISSING:} (process.md §Step 4.5)" ;;
      ERROR:*)   fail "attempt-001/preflight.json: JSON parse error — ${pf_result#ERROR:}" ;;
    esac
  fi

  # stress_report.json schema: required fields (scaffold.md §stress testing)
  if [[ -f "$attempt_dir/stress_report.json" ]]; then
    sr_result=$(ruby -rjson -e "
      begin
        j = JSON.parse(File.read('$attempt_dir/stress_report.json'))
        # Skip schema checks for pending/placeholder skeletons
        if j['execution_status'].to_s == 'pending' || j['status'].to_s == 'pending'
          puts 'PENDING'
        else
          missing = []
          missing << 'status' unless j.key?('status')
          missing << 'stress_scenarios' unless j['stress_scenarios'].is_a?(Array)
          if j['stress_scenarios'].is_a?(Array) && j['stress_scenarios'].empty?
            missing << 'stress_scenarios (empty)'
          end
          missing.empty? ? puts('OK') : puts('MISSING:' + missing.join(', '))
        end
      rescue => e
        puts 'ERROR:' + e.message
      end
    " 2>/dev/null || echo "ERROR:ruby failed")
    case "$sr_result" in
      OK)        pass "attempt-001/stress_report.json: required fields present (status/stress_scenarios)" ;;
      PENDING)   pass "attempt-001/stress_report.json: pending skeleton — schema check deferred" ;;
      MISSING:*) fail "attempt-001/stress_report.json: missing fields: ${sr_result#MISSING:} (scaffold.md §stress testing)" ;;
      ERROR:*)   fail "attempt-001/stress_report.json: JSON parse error — ${sr_result#ERROR:}" ;;
    esac
  fi
  # eval_report.json schema: required fields (scaffold.md §attempt: run_eval.sh output)
  if [[ -f "$attempt_dir/eval_report.json" ]]; then
    er_result=$(ruby -rjson -e "
      begin
        j = JSON.parse(File.read('$attempt_dir/eval_report.json'))
        # Skip schema checks for pending/placeholder skeletons
        if j['execution_status'].to_s == 'pending'
          puts 'PENDING'
        else
          missing = []
          missing << 'status' unless j.key?('status')
          missing << 'total' unless j.key?('total')
          missing << 'passed' unless j.key?('passed')
          missing.empty? ? puts('OK') : puts('MISSING:' + missing.join(', '))
        end
      rescue => e
        puts 'ERROR:' + e.message
      end
    " 2>/dev/null || echo "ERROR:ruby failed")
    case "$er_result" in
      OK)        pass "attempt-001/eval_report.json: required fields present (status/total/passed)" ;;
      PENDING)   pass "attempt-001/eval_report.json: pending skeleton — schema check deferred" ;;
      MISSING:*) fail "attempt-001/eval_report.json: missing fields: ${er_result#MISSING:} (scaffold.md §attempt: run_eval.sh output)" ;;
      ERROR:*)   fail "attempt-001/eval_report.json: JSON parse error — ${er_result#ERROR:}" ;;
    esac
  fi
  # blind_eval_report.json schema: required fields (process.md §attempt: run_blind_eval.sh output)
  if [[ -f "$attempt_dir/blind_eval_report.json" ]]; then
    ber_result=$(ruby -rjson -e "
      begin
        j = JSON.parse(File.read('$attempt_dir/blind_eval_report.json'))
        if j['execution_status'].to_s == 'pending' || j['status'].to_s == 'pending'
          puts 'PENDING'
        else
          missing = []
          missing << 'status' unless j.key?('status')
          missing << 'qualified/total_score' unless j.key?('qualified') || j.key?('total_score')
          missing << 'dimensions' unless j.key?('dimensions')
          missing.empty? ? puts('OK') : puts('MISSING:' + missing.join(', '))
        end
      rescue => e
        puts 'ERROR:' + e.message
      end
    " 2>/dev/null || echo "ERROR:ruby failed")
    case "$ber_result" in
      OK)        pass "attempt-001/blind_eval_report.json: required fields present (status/qualified/dimensions)" ;;
      PENDING)   pass "attempt-001/blind_eval_report.json: pending skeleton — schema check deferred" ;;
      MISSING:*) fail "attempt-001/blind_eval_report.json: missing fields: ${ber_result#MISSING:} (process.md §attempt)" ;;
      ERROR:*)   fail "attempt-001/blind_eval_report.json: JSON parse error — ${ber_result#ERROR:}" ;;
    esac
  fi
else
  fail "attempt-001/ missing"
fi

# failures/ directory (scaffold.md: 有失败时必须; 没有记录失败不允许)
# Only warn if there are multiple attempts (suggesting failures that weren't recorded)
attempt_count=$(find "$SKILL_DIR/evolve_history/${dir_version}/attempts" -maxdepth 1 -type d -name "attempt-*" 2>/dev/null | wc -l | tr -d ' ')
if [[ -d "$SKILL_DIR/evolve_history/${dir_version}/failures" ]]; then
  pass "evolve_history/${dir_version}/failures/ exists (failure records kept)"
elif [[ "${attempt_count:-0}" -gt 1 ]]; then
  fail "evolve_history/${dir_version}/failures/ missing but ${attempt_count} attempts found (scaffold.md: 有失败时必须 — failures/ required when >1 attempts)"
else
  pass "evolve_history/${dir_version}/failures/ absent (single attempt — first-try success plausible)"
fi

# summary.md (scaffold.md §evolve_history/vN/summary.md 必须)
if [[ -f "$SKILL_DIR/evolve_history/${dir_version}/summary.md" ]]; then
  pass "evolve_history/${dir_version}/summary.md exists"
  summ_file="$SKILL_DIR/evolve_history/${dir_version}/summary.md"
  # Content checks: scaffold.md specifies 5 required fields
  if grep -qiE "(状态|Status|releasable|active|draft)" "$summ_file" 2>/dev/null; then
    pass "summary.md: 状态/Status field present"
  else
    fail "summary.md: missing 状态/Status field (scaffold.md §summary.md required)"
  fi
  if grep -qiE "(攻克的优化点|优化点|Optimization Point)" "$summ_file" 2>/dev/null; then
    pass "summary.md: 攻克的优化点 field present"
  else
    fail "summary.md: missing 攻克的优化点 field (scaffold.md §summary.md required)"
  fi
  if grep -qiE "(eval.*通过率|通过率|Pass Rate|[0-9]+/[0-9]+)" "$summ_file" 2>/dev/null; then
    pass "summary.md: eval 通过率/Pass Rate present"
  else
    fail "summary.md: missing eval 通过率 (scaffold.md §summary.md required)"
  fi
  if grep -qiE "(相比上版本|相比.*提升|Improvement|提升)" "$summ_file" 2>/dev/null; then
    pass "summary.md: 相比上版本的提升/Improvement field present"
  else
    fail "summary.md: missing 相比上版本的提升 field (scaffold.md §summary.md required)"
  fi
  if grep -qiE "(已知局限|Known Limitation|局限)" "$summ_file" 2>/dev/null; then
    pass "summary.md: 已知局限/Known Limitations field present"
  else
    fail "summary.md: missing 已知局限/Known Limitations field (scaffold.md §summary.md required)"
  fi
else
  fail "evolve_history/${dir_version}/summary.md missing (scaffold.md §evolve_history 必须)"
fi

# target_point.md and comparison.md (whitepaper §3.2)
for doc in target_point.md comparison.md release_checklist.md; do
  if [[ -f "$SKILL_DIR/evolve_history/${dir_version}/$doc" ]]; then
    pass "evolve_history/${dir_version}/$doc exists"
  else
    fail "evolve_history/${dir_version}/$doc missing (required by whitepaper §3.2)"
  fi
done
# release_checklist.md structure check: must have Objective + Subjective sections (gen_skill_dir.sh template)
rc_file="$SKILL_DIR/evolve_history/${dir_version}/release_checklist.md"
if [[ -f "$rc_file" ]]; then
  if grep -qiE "(客观|Objective)" "$rc_file" 2>/dev/null; then
    pass "release_checklist.md: Objective/客观 section present"
  else
    fail "release_checklist.md: missing Objective/客观 section (gen_skill_dir.sh template requires both Objective and Subjective sections)"
  fi
  if grep -qiE "(主观|Subjective)" "$rc_file" 2>/dev/null; then
    pass "release_checklist.md: Subjective/主观 section present"
  else
    fail "release_checklist.md: missing Subjective/主观 section (gen_skill_dir.sh template: Subjective Layer for terminal validation)"
  fi
fi
# comparison.md content: must have comparison content (table or Without/With sections) (whitepaper §3.2 优劣势分析)
cmp_file="$SKILL_DIR/evolve_history/${dir_version}/comparison.md"
if [[ -f "$cmp_file" ]]; then
  if grep -qE "^\|" "$cmp_file" 2>/dev/null || grep -qiE "(Without|Without.*Skill|Without.*this|Before.*Skill|v[0-9]+.*v[0-9]+)" "$cmp_file" 2>/dev/null; then
    pass "evolve_history/${dir_version}/comparison.md: has comparison content (table or before/after sections)"
  elif grep -qiE "\{TODO" "$cmp_file" 2>/dev/null; then
    : # still placeholder skeleton — skip
  else
    fail "evolve_history/${dir_version}/comparison.md: no comparison table or before/after sections found (whitepaper §3.2: 优劣势分析)"
  fi
fi
# comparison.md Trade-offs section: must document costs/trade-offs (scaffold.md template §Trade-offs)
if [[ -f "$cmp_file" ]]; then
  if grep -qiE "(Trade.off|Trade-off|已知代价|代价|权衡|Limitation.*of.*Skill|Skill.*Limitation|我们放弃|We give up|缺点|Disadvantage)" "$cmp_file" 2>/dev/null; then
    pass "comparison.md: has Trade-offs/代价 section (scaffold.md template: 必须说明权衡和代价)"
  elif grep -qiE "\{TODO" "$cmp_file" 2>/dev/null; then
    : # skeleton placeholder — skip
  else
    fail "comparison.md: missing Trade-offs/代价 section (scaffold.md template §Trade-offs: 必须说明 Skill 引入的代价和权衡)"
  fi
fi

# target_point.md content: must have goal/problem description (whitepaper §3.2: 目标、瓶颈、放弃的替代点)
tp_file="$SKILL_DIR/evolve_history/${dir_version}/target_point.md"
if [[ -f "$tp_file" ]]; then
  if grep -qiE "\{TODO" "$tp_file" 2>/dev/null; then
    : # still placeholder skeleton — skip
  else
    if grep -qiE "(Core Problem|目标|核心目标|target_point|目的|Goal|Objective|攻克)" "$tp_file" 2>/dev/null; then
      pass "evolve_history/${dir_version}/target_point.md: has goal/problem section (whitepaper §3.2)"
    else
      fail "evolve_history/${dir_version}/target_point.md: no goal/problem section found (whitepaper §3.2: 写清目标、瓶颈、放弃的替代点)"
    fi
    if grep -qiE "(瓶颈|Bottleneck|bottleneck|constraint|难点|限制|阻碍|黑盒|无法|无效|失败|缺失|missing|cannot|unable|lacks)" "$tp_file" 2>/dev/null; then
      pass "evolve_history/${dir_version}/target_point.md: has bottleneck/constraint section (whitepaper §3.2: 瓶颈)"
    else
      fail "evolve_history/${dir_version}/target_point.md: no bottleneck section found (whitepaper §3.2: 写清瓶颈)"
    fi
    if grep -qiE "(放弃|Rejected|Discarded|Alternative|备选|替代|abandoned|不采用|vs\.|对比|compared to|v[0-9].*vs|before.*after|旧.*新)" "$tp_file" 2>/dev/null; then
      pass "evolve_history/${dir_version}/target_point.md: has rejected alternatives section (whitepaper §3.2: 放弃的替代点)"
    else
      fail "evolve_history/${dir_version}/target_point.md: no rejected-alternatives section (whitepaper §3.2: 写清放弃的替代点)"
    fi
  fi
fi

# self-bootstrap.md (process.md §Step 3.5 output)
if [[ -f "$SKILL_DIR/self-bootstrap.md" ]]; then
  pass "self-bootstrap.md exists"
  # Content checks: Phases 1-7 (scaffold.md §self-bootstrap.md)
  missing_phases=()
  for phase in "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5" "Phase 6" "Phase 7"; do
    if grep -q "$phase" "$SKILL_DIR/self-bootstrap.md" 2>/dev/null; then
      : # found
    else
      missing_phases+=("$phase")
    fi
  done
  if [[ ${#missing_phases[@]} -eq 0 ]]; then
    pass "self-bootstrap.md: all 7 phases present"
  else
    fail "self-bootstrap.md: missing phases: ${missing_phases[*]}"
  fi
  # Phase 4 must document evidence requirement (self-bootstrap.md §Phase 4: fail→pass 必须附 evidence, under Only-increase constraint)
  if grep -qiE "(evidence|证据|fail.*pass.*evidence|evidence.*field)" "$SKILL_DIR/self-bootstrap.md" 2>/dev/null; then
    pass "self-bootstrap.md: evidence requirement documented (fail→pass must include evidence)"
  else
    fail "self-bootstrap.md: evidence requirement not documented (self-bootstrap.md Phase 4: fail→pass 必须附 evidence 字段)"
  fi
  # Phase 6 must mention judge_calibration (self-bootstrap.md §Phase 6: v7 强制 judge_calibration)
  if grep -qiE "(judge_calibration|judge calibration)" "$SKILL_DIR/self-bootstrap.md" 2>/dev/null; then
    pass "self-bootstrap.md: Phase 6 judge_calibration requirement present (v7)"
  else
    fail "self-bootstrap.md: Phase 6 missing judge_calibration requirement (self-bootstrap.md §Phase 6 v7: 陌生领域 Skill eval 必须含 judge_calibration)"
  fi
else
  fail "self-bootstrap.md missing (process.md Step 3.5 requires it for evolution lifecycle)"
fi

# version_history: deprecated in v7 — evolve_history/ is the canonical version record

# assets/references (whitepaper §2.3); required for --ship (ref cards needed for Article)
if [[ -d "$SKILL_DIR/evolve_history/${dir_version}/assets/references" ]]; then
  pass "evolve_history/${dir_version}/assets/references/ exists"
elif [[ "$SHIP_MODE" == "--ship" ]]; then
  fail "evolve_history/${dir_version}/assets/references/ missing (whitepaper §2.3: assets/references/ required for --ship)"
fi

# .gitignore check: .tmp/ must be in .gitignore (whitepaper §1.2.12: eval fixtures must not pollute main directory)
# Walk up directory tree to find .gitignore (handles skills placed inside .tmp/ subdirs)
_skill_abs="$(cd "$SKILL_DIR" && pwd)"
gitignore_path=""
_check_dir="$_skill_abs"
for _ in 1 2 3 4 5; do
  _check_dir="$(dirname "$_check_dir")"
  if [[ -f "$_check_dir/.gitignore" ]]; then
    gitignore_path="$_check_dir/.gitignore"
    break
  fi
  [[ "$_check_dir" == "/" ]] && break
done
if [[ -z "$gitignore_path" && -f "$SKILL_DIR/.gitignore" ]]; then
  gitignore_path="$SKILL_DIR/.gitignore"
fi
if [[ -n "$gitignore_path" ]]; then
  if grep -qE "^\.tmp/" "$gitignore_path" 2>/dev/null || grep -qE "^\.tmp$" "$gitignore_path" 2>/dev/null; then
    pass ".gitignore: .tmp/ entry present (whitepaper §1.2.12)"
  else
    fail ".gitignore found but .tmp/ not in it (whitepaper §1.2.12: eval fixtures must not pollute main directory — add .tmp/ to .gitignore)"
  fi
else
  fail ".gitignore not found in project root (whitepaper §1.2.12: .tmp/ must be gitignored — create .gitignore with .tmp/ entry)"
fi

# meta-type skill: standard tools script set (scaffold.md §tools/ standard set)
# tools/gate/ = read-only validators; tools/scripts/ = generators + runners with side effects
manifest_type=$(ruby -ryaml -e "puts YAML.load_file('$SKILL_DIR/manifest.yaml')['type'].to_s" 2>/dev/null || true)
if [[ "$manifest_type" == "meta" ]]; then
  # shim at tools/ top-level
  for tool in validate.sh; do
    if [[ -f "$SKILL_DIR/tools/$tool" ]]; then
      pass "tools/$tool exists (meta-type shim)"
      if [[ ! -x "$SKILL_DIR/tools/$tool" ]]; then
        fail "tools/$tool is not executable (run: chmod +x tools/$tool — scripts must be executable)"
      fi
    else
      fail "tools/$tool missing (scaffold.md standard tools set for meta-type skills — required for meta-type Skills)"
    fi
  done
  # gate/ subtree: read-only validators
  for tool in gate/_lib.sh gate/validate.sh gate/validate_structure.sh gate/validate_manifest.sh gate/validate_evals.sh gate/validate_article.sh gate/validate_ref_cards.sh gate/validate_references.sh gate/checklist.md; do
    if [[ -f "$SKILL_DIR/tools/$tool" ]]; then
      pass "tools/$tool exists (meta-type standard set)"
      if [[ "$tool" == *.sh && ! -x "$SKILL_DIR/tools/$tool" ]]; then
        fail "tools/$tool is not executable (run: chmod +x tools/$tool — scripts must be executable)"
      fi
    else
      fail "tools/$tool missing (scaffold.md standard tools set for meta-type skills — required for meta-type Skills)"
    fi
  done
  # scripts/ subtree: generators + runners (side effects)
  for tool in scripts/gen_skill_dir.sh scripts/gen_ref_card.sh scripts/gen_dist.sh scripts/run_eval.sh scripts/run_blind_eval.sh scripts/suggest_p2_candidates.sh scripts/ref_card_gen.md; do
    if [[ -f "$SKILL_DIR/tools/$tool" ]]; then
      pass "tools/$tool exists (meta-type standard set)"
      if [[ "$tool" == *.sh && ! -x "$SKILL_DIR/tools/$tool" ]]; then
        fail "tools/$tool is not executable (run: chmod +x tools/$tool — scripts must be executable)"
      fi
    else
      fail "tools/$tool missing (scaffold.md standard tools set for meta-type skills — required for meta-type Skills)"
    fi
  done
  # run_eval.sh and run_blind_eval.sh must not be placeholder stubs (whitepaper: 不能是占位脚本)
  for eval_script in scripts/run_eval.sh scripts/run_blind_eval.sh; do
    eval_path="$SKILL_DIR/tools/$eval_script"
    if [[ -f "$eval_path" ]]; then
      line_count=$(wc -l < "$eval_path" 2>/dev/null | tr -d ' ')
      if [[ "${line_count:-0}" -ge 30 ]]; then
        pass "tools/$eval_script: non-stub implementation ($line_count lines, whitepaper: 不能是占位脚本)"
      else
        fail "tools/$eval_script: too short ($line_count lines) — is a placeholder stub (whitepaper: eval scripts 不能是占位脚本 — implement fully)"
      fi
    fi
  done
fi

exit $_EXIT_CODE
