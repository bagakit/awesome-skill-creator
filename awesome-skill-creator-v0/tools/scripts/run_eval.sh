#!/usr/bin/env bash
# run_eval.sh — Execute objective eval cases against REAL file system outputs (v7)
#
# EXECUTION CONTRACT:
#   Every result in this report came from actually checking a real file.
#   'fixture_not_created' = the test skill was never actually created by skill-creator.
#   No predicted values. No simulated results.
#
# Usage:
#   run_eval.sh <skill-dir> [--fixtures <dir>]
#     Evaluates cases where fixture dirs exist in <fixtures-dir>
#     Default: <project-root>/.tmp/eval/<skill-name>_<version>/
#     e.g. skill-creator-v3 → .tmp/eval/skill-creator_v3/
#     Fixtures MUST NOT pollute the project root directory.
#
#   run_eval.sh <skill-dir> --self
#     Runs only self-referential cases (assertions against skill-creator's own files)
#
# Exit: 0 = all executed cases match expected; 1 = any unexpected result

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../gate/_lib.sh"

SKILL_DIR="${1:?Usage: run_eval.sh <skill-dir> [--fixtures <dir> | --self] [--all-tiers]}"
SKILL_DIR="${SKILL_DIR%/}"
MODE="${2:-}"
FIXTURES_DIR="${3:-}"
# --all-tiers may appear at any position (2nd, 3rd, or 4th arg)
ALL_TIERS=""
for _arg in "$@"; do [[ "$_arg" == "--all-tiers" ]] && ALL_TIERS="--all-tiers"; done

# ⭐ v4: unified single source — evals/objective_cases.yaml (same file validate_evals.sh uses)
# v3 used evals/cases/objective/objective_cases.yaml; v4 eliminates the dual-file debt
CASES_FILE="$SKILL_DIR/evals/objective_cases.yaml"

if [[ ! -f "$CASES_FILE" ]]; then
  echo "ERROR: Cases file not found: $CASES_FILE" >&2
  exit 1
fi

if [[ -z "$FIXTURES_DIR" ]]; then
  # Default: .tmp/eval/<skill-name>_<version>/ under project root
  # e.g. skill-creator-v3 → .tmp/eval/skill-creator_v3/
  _skill_basename=$(basename "$SKILL_DIR")
  _fixture_subdir=$(echo "$_skill_basename" | sed 's/-\(v[0-9]*\)$/_\1/')
  FIXTURES_DIR="$(dirname "$SKILL_DIR")/.tmp/eval/$_fixture_subdir"
fi

echo "=== run_eval.sh: Objective Evaluation ==="
echo "Skill dir : $SKILL_DIR"
echo "Fixtures  : $FIXTURES_DIR"
echo "Mode      : ${MODE:-default}"
echo "Timestamp : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
echo "EXECUTION CONTRACT:"
echo "  Every result came from actually checking a real file."
echo "  fixture_not_created = skill was never run on that test input."
echo "  No predicted values."
echo ""

# All evaluation logic in Ruby to avoid bash YAML parsing fragility
ruby - "$CASES_FILE" "$FIXTURES_DIR" "$SKILL_DIR" "$MODE" "$ALL_TIERS" <<'RUBY'
require 'yaml'
require 'shellwords'

cases_file   = ARGV[0]
fixtures_dir = ARGV[1]
skill_dir    = ARGV[2]
mode         = ARGV[3]
all_tiers    = ARGV[4] == '--all-tiers'   # v7: include P2 archived cases when true

data  = YAML.load_file(cases_file)
cases = data['cases'] || []

# ⭐ v7 tiered protection: skip P2 (archived) cases unless --all-tiers
p2_archived = cases.count { |c| c['tier'] == 'P2' }
cases = cases.reject { |c| c['tier'] == 'P2' } unless all_tiers

total = passed = failed = not_created = 0

def check_assertion(a, base_dir)
  type    = a['type'].to_s
  value   = a['value'].to_s
  target  = a['target'].to_s
  field   = a['field'].to_s

  case type
  when 'file_exists'
    path = File.join(base_dir, value)
    File.exist?(path) ? [:pass, path] : [:fail, "file not found: #{path}"]

  when 'contains'
    return [:skip, 'no target (needs LLM stdout)'] if target.empty?
    tpath = File.join(base_dir, target)
    return [:fail, "target not found: #{tpath}"] unless File.exist?(tpath)
    content = File.read(tpath) rescue ''
    content.include?(value) ? [:pass, tpath] : [:fail, "'#{value}' not in #{File.basename(tpath)}"]

  when 'not_contains'
    return [:skip, 'no target'] if target.empty?
    tpath = File.join(base_dir, target)
    return [:pass_vacuous, "file absent"] unless File.exist?(tpath)
    content = File.read(tpath) rescue ''
    content.include?(value) ? [:fail, "'#{value}' found in #{File.basename(tpath)}"] : [:pass, tpath]

  when 'yaml_valid'
    tpath = File.join(base_dir, target)
    return [:fail, "file not found: #{tpath}"] unless File.exist?(tpath)
    begin
      YAML.load_file(tpath)
      [:pass, tpath]
    rescue => e
      [:fail, "YAML parse error: #{e.message}"]
    end

  when 'yaml_field_equals'
    tpath = File.join(base_dir, target)
    return [:fail, "file not found: #{tpath}"] unless File.exist?(tpath)
    begin
      y = YAML.load_file(tpath)
      actual = y[field].to_s
      actual == value ? [:pass, "#{field}=#{actual}"] : [:fail, "#{field}=#{actual.inspect} (want #{value.inspect})"]
    rescue => e
      [:fail, "YAML parse error: #{e.message}"]
    end

  when 'min_count'
    tpath = File.join(base_dir, target)
    return [:fail, "file not found: #{tpath}"] unless File.exist?(tpath)
    begin
      y = YAML.load_file(tpath)
      arr = y.is_a?(Hash) ? y.values.first : y
      arr = [arr] unless arr.is_a?(Array)
      min_v = a['value'].to_i
      arr.length >= min_v ? [:pass, "count=#{arr.length}"] : [:fail, "count=#{arr.length} < #{min_v}"]
    rescue => e
      [:fail, "YAML parse error: #{e.message}"]
    end

  when 'run_script'
    # ⭐ v4 — 执行 shell 脚本验证行为
    # v5 新增: timeout_seconds（超时控制）+ sandbox（临时目录隔离）
    script          = a['script'].to_s
    expected_exit   = (a['expected_exit'] || 0).to_i
    expected_stdout = a['expected_stdout_contains'].to_s
    timeout_secs    = a['timeout_seconds']   # v5: integer or nil
    sandbox         = a['sandbox'] == true   # v5: boolean

    run_dir = target.empty? ? base_dir : File.join(base_dir, target)
    return [:fail, "run_script target not found: #{run_dir}"] unless File.exist?(run_dir)

    # v5: sandbox — symlink target files into fresh temp dir to isolate side-effects
    work_dir = if sandbox
      tmp = "/tmp/skill_sandbox_#{Process.pid}_#{rand(9999)}"
      Dir.mkdir(tmp)
      Dir.glob(File.join(run_dir, '*')).each do |f|
        File.symlink(f, File.join(tmp, File.basename(f))) rescue nil
      end
      tmp
    else
      run_dir
    end

    tmpfile = "/tmp/skill_eval_script_#{Process.pid}_#{rand(9999)}.sh"
    File.write(tmpfile, "#!/usr/bin/env bash\nset -uo pipefail\ncd '#{work_dir}'\n#{script}\n")
    File.chmod(0755, tmpfile)

    # v5: timeout wrapper using system `timeout` command (macOS: gtimeout or timeout)
    timeout_cmd = timeout_secs ? "timeout #{timeout_secs.to_i}" : ''
    stdout = `#{timeout_cmd} bash #{tmpfile} 2>&1`
    actual_exit = $?.exitstatus
    File.delete(tmpfile) rescue nil
    require 'fileutils'; FileUtils.rm_rf(work_dir) if sandbox rescue nil

    # timeout(1) exits 124 on timeout
    return [:fail, "run_script timed out after #{timeout_secs}s"] if timeout_secs && actual_exit == 124

    if actual_exit == expected_exit
      if expected_stdout.empty? || stdout.include?(expected_stdout)
        [:pass, "exit=#{actual_exit}#{expected_stdout.empty? ? '' : ", stdout contains '#{expected_stdout}'"}"]
      else
        [:fail, "exit=#{actual_exit} but stdout missing '#{expected_stdout}': #{stdout.strip[0..120]}"]
      end
    else
      [:fail, "exit=#{actual_exit} (expected #{expected_exit}): #{stdout.strip[0..120]}"]
    end

  when 'invoke_skill'
    # ⭐ v5 新增 — 调用 claude CLI 执行 Skill，验证 LLM 输出包含领域专有术语
    # skill_file: SKILL.md 路径（相对于 target 目录）
    # input: 传入 Skill 的用户输入文本
    # expected_contains: 期望输出包含的字符串（单个或数组）
    # pass_rate_threshold: 通过率阈值 default 1.0（处理 LLM 非确定性）
    # runs: 执行次数 default 1
    skill_file          = a['skill_file'].to_s
    input_text          = a['input'].to_s
    expected_contains   = a['expected_contains']
    pass_rate_threshold = (a['pass_rate_threshold'] || 1.0).to_f
    runs                = (a['runs'] || 1).to_i

    skill_path = if target.empty?
      File.join(base_dir, skill_file)
    else
      File.join(base_dir, target, skill_file)
    end
    return [:fail, "invoke_skill: skill_file not found: #{skill_path}"] unless File.exist?(skill_path)

    # Graceful degradation: skip if claude CLI not available
    unless system('which claude > /dev/null 2>&1')
      return [:skip, 'invoke_skill: claude CLI not available (skipped — not a failure)']
    end

    skill_content = File.read(skill_path)
    expected_list = expected_contains.is_a?(Array) ? expected_contains : [expected_contains.to_s]

    pass_count  = 0
    last_output = ''
    runs.times do
      combined = "#{skill_content}\n\n---\n\nUser input: #{input_text}"
      prompt_file = "/tmp/skill_invoke_#{Process.pid}_#{rand(99999)}.txt"
      File.write(prompt_file, combined)
      last_output = `cat #{Shellwords.escape(prompt_file)} | claude -p 2>&1`
      actual_exit = $?.exitstatus
      File.delete(prompt_file) rescue nil
      # Detect nested session error (claude called from within another claude session)
      if last_output.include?('cannot be launched inside another Claude Code session') ||
         last_output.include?('nested') && last_output.include?('session')
        return [:skip, 'invoke_skill: nested Claude session detected (run eval standalone for LLM-level assertions)']
      end
      next if actual_exit != 0
      pass_count += 1 if expected_list.all? { |term| last_output.include?(term) }
    end

    actual_rate = pass_count.to_f / runs
    if actual_rate >= pass_rate_threshold
      [:pass, "invoke_skill: #{pass_count}/#{runs} passed (rate=#{actual_rate.round(2)})"]
    else
      [:fail, "invoke_skill: #{pass_count}/#{runs} passed (rate=#{actual_rate.round(2)} < #{pass_rate_threshold}); missing: #{expected_list.inspect}; tail=#{last_output.strip[0..100]}"]
    end

  when 'judge_calibration'
    # ⭐ v7 新增 — 验证 judge_prompt 的区分力：good_example 应 PASS，bad_example 应 FAIL
    # skill_file: SKILL.md 路径（用于构建 judge context）
    # judge_prompt: 被校准的评判提示
    # good_example: 预期被 judge 判为 PASS 的 Skill 输出样本
    # bad_example: 预期被 judge 判为 FAIL 的 Skill 输出样本
    skill_file   = a['skill_file'].to_s
    judge_prompt = a['judge_prompt'].to_s
    good_example = a['good_example'].to_s
    bad_example  = a['bad_example'].to_s
    timeout_secs = a['timeout_seconds']

    return [:fail, "judge_calibration: judge_prompt is empty"] if judge_prompt.empty?
    return [:fail, "judge_calibration: good_example is empty"] if good_example.empty?
    return [:fail, "judge_calibration: bad_example is empty"] if bad_example.empty?

    unless system('which claude > /dev/null 2>&1')
      return [:skip, 'judge_calibration: claude CLI not available (skipped)']
    end

    timeout_cmd = timeout_secs ? "timeout #{timeout_secs.to_i}" : ''

    # Test good_example: should PASS
    good_full = "#{judge_prompt}#{good_example}"
    good_file = "/tmp/judge_cal_good_#{Process.pid}_#{rand(99999)}.txt"
    File.write(good_file, good_full)
    good_out = `cat #{Shellwords.escape(good_file)} | #{timeout_cmd} claude -p 2>&1`
    good_exit = $?.exitstatus
    File.delete(good_file) rescue nil

    if good_out.include?('cannot be launched inside another Claude Code session')
      return [:skip, 'judge_calibration: nested Claude session detected']
    end

    good_passed = good_out.strip.start_with?('PASS')

    # Test bad_example: should FAIL
    bad_full = "#{judge_prompt}#{bad_example}"
    bad_file = "/tmp/judge_cal_bad_#{Process.pid}_#{rand(99999)}.txt"
    File.write(bad_file, bad_full)
    bad_out = `cat #{Shellwords.escape(bad_file)} | #{timeout_cmd} claude -p 2>&1`
    bad_exit = $?.exitstatus
    File.delete(bad_file) rescue nil

    if bad_out.include?('cannot be launched inside another Claude Code session')
      return [:skip, 'judge_calibration: nested Claude session detected']
    end

    bad_failed = !bad_out.strip.start_with?('PASS')

    if good_passed && bad_failed
      [:pass, "judge_calibration: good→PASS ✓, bad→FAIL ✓"]
    elsif !good_passed && !bad_failed
      [:fail, "judge_calibration: good→FAIL (over-strict) AND bad→PASS (too lenient); judge_prompt needs revision"]
    elsif !good_passed
      [:fail, "judge_calibration: good_example was judged FAIL (over-strict judge_prompt); good_out=#{good_out.strip[0..80]}"]
    else
      [:fail, "judge_calibration: bad_example was judged PASS (too lenient judge_prompt); bad_out=#{bad_out.strip[0..80]}"]
    end

  when 'invoke_skill_judge'
    # ⭐ v6 新增 — LLM-as-judge：执行 Skill 后，用第二个 LLM 调用评估输出语义质量
    # skill_file: SKILL.md 路径（相对于 target）
    # input: 传入 Skill 的用户输入
    # judge_prompt: 评判提示（v6 新增），指导 judge LLM 如何评估输出（返回 PASS 或 FAIL）
    # pass_rate_threshold: 通过率阈值 default 0.8
    # runs: 执行次数 default 2
    # timeout_seconds: invoke_skill 超时控制（v6 新增）
    skill_file          = a['skill_file'].to_s
    input_text          = a['input'].to_s
    judge_prompt        = a['judge_prompt'].to_s
    pass_rate_threshold = (a['pass_rate_threshold'] || 0.8).to_f
    runs                = (a['runs'] || 2).to_i
    timeout_secs        = a['timeout_seconds']

    skill_path = target.empty? ? File.join(base_dir, skill_file) : File.join(base_dir, target, skill_file)
    return [:fail, "invoke_skill_judge: skill_file not found: #{skill_path}"] unless File.exist?(skill_path)

    unless system('which claude > /dev/null 2>&1')
      return [:skip, 'invoke_skill_judge: claude CLI not available (skipped)']
    end

    skill_content = File.read(skill_path)
    default_judge = "Evaluate if the following LLM output demonstrates domain expertise. Reply with exactly PASS if it shows clear domain knowledge, or FAIL with one-line reason if it does not.\n\nOutput to evaluate:\n"
    judge_template = judge_prompt.empty? ? default_judge : judge_prompt

    pass_count  = 0
    last_judge  = ''
    runs.times do
      # Step 1: Execute skill
      combined = "#{skill_content}\n\n---\n\nUser input: #{input_text}"
      invoke_file = "/tmp/skill_judge_invoke_#{Process.pid}_#{rand(99999)}.txt"
      File.write(invoke_file, combined)

      timeout_cmd = timeout_secs ? "timeout #{timeout_secs.to_i}" : ''
      skill_output = `cat #{Shellwords.escape(invoke_file)} | #{timeout_cmd} claude -p 2>&1`
      invoke_exit  = $?.exitstatus
      File.delete(invoke_file) rescue nil

      if skill_output.include?('cannot be launched inside another Claude Code session')
        return [:skip, 'invoke_skill_judge: nested Claude session detected']
      end
      next if invoke_exit != 0
      return [:fail, "invoke_skill_judge: skill timed out after #{timeout_secs}s"] if timeout_secs && invoke_exit == 124

      # Step 2: Judge the output
      judge_full = "#{judge_template}#{skill_output}"
      judge_file = "/tmp/skill_judge_eval_#{Process.pid}_#{rand(99999)}.txt"
      File.write(judge_file, judge_full)
      last_judge = `cat #{Shellwords.escape(judge_file)} | claude -p 2>&1`
      judge_exit = $?.exitstatus
      File.delete(judge_file) rescue nil

      if last_judge.include?('cannot be launched inside another Claude Code session')
        return [:skip, 'invoke_skill_judge: nested Claude session detected (judge step)']
      end
      next if judge_exit != 0
      pass_count += 1 if last_judge.strip.start_with?('PASS')
    end

    actual_rate = pass_count.to_f / runs
    if actual_rate >= pass_rate_threshold
      [:pass, "invoke_skill_judge: #{pass_count}/#{runs} judge-passed (rate=#{actual_rate.round(2)})"]
    else
      [:fail, "invoke_skill_judge: #{pass_count}/#{runs} judge-passed (rate=#{actual_rate.round(2)} < #{pass_rate_threshold}); judge=#{last_judge.strip[0..80]}"]
    end

  else
    [:skip, "unknown type: #{type}"]
  end
end

puts "Found #{cases.length} eval cases."
puts ""
puts "--- Evaluation Results ---"

cases.each do |c|
  id       = c['id'] || 'unknown'
  expected = c['expected_result'] || 'pass'
  assertions = c['assertions'] || []

  # Find the fixture directory referenced by this case
  # For file_exists: path is in 'value'; for others: path is in 'target'
  fixture_ref = nil
  assertions.each do |a|
    ref = case a['type']
          when 'file_exists' then a['value'].to_s
          else (a['target'] || '').to_s
          end
    parts = ref.split('/')
    # Multi-part path: first segment is fixture dir (e.g. "sql-optimizer-v0/manifest.yaml")
    if parts.length > 1 && parts[0] =~ /-v\d+$/
      fixture_ref = parts[0]
      break
    end
    # Single-part path matching fixture dir pattern (e.g. run_script target: "sql-optimizer-v0")
    if parts.length == 1 && parts[0] =~ /-v\d+$/ && !parts[0].start_with?('skill-creator-v')
      fixture_ref = parts[0]
      break
    end
  end

  # Determine if self-referential (tests skill-creator's own files)
  is_self = fixture_ref.nil? || fixture_ref.start_with?('skill-creator-v')

  # Skip non-self cases in --self mode
  next if mode == '--self' && !is_self

  # Determine base dir
  if is_self
    base_dir = File.dirname(skill_dir)
  else
    fixture_path = File.join(fixtures_dir, fixture_ref.to_s)
    unless Dir.exist?(fixture_path)
      total += 1
      not_created += 1
      if expected == 'fail'
        passed += 1
        puts "  ✓ [#{id}] fixture_not_created → correctly fails (expected: fail)"
      else
        puts "  ○ [#{id}] fixture_not_created → create fixture first with skill-creator"
      end
      next
    end
    base_dir = fixtures_dir
  end

  total += 1
  all_ok   = true
  fail_details = []

  assertions.each do |a|
    result, detail = check_assertion(a, base_dir)
    case result
    when :fail
      all_ok = false
      fail_details << "    ✗ #{a['type']}(#{a['value'] || a['target']}): #{detail}"
    when :skip
      # skips don't affect pass/fail
    end
  end

  actual = all_ok ? 'pass' : 'fail'
  if actual == expected
    passed += 1
    label = expected == 'fail' ? 'correctly fails' : 'pass'
    puts "  ✓ [#{id}] #{label}"
  else
    failed += 1
    puts "  ✗ [#{id}] got=#{actual} expected=#{expected}"
    fail_details.each { |d| puts d }
  end
end

puts ""
puts "--- Summary ---"
puts "Total (P0+P1)  : #{total}"
puts "P2 archived    : #{p2_archived}#{all_tiers ? ' (included above via --all-tiers)' : ' (filtered out)'}"
puts "Passed         : #{passed}"
puts "Failed         : #{failed}"
puts "Needs fixture  : #{not_created}"
puts "Executed       : #{total - not_created} / #{total} cases"

exit(failed > 0 ? 1 : 0)
RUBY
