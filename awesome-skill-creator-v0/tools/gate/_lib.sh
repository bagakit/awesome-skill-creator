#!/usr/bin/env bash
# _lib.sh — Shared functions for skill-creator validation scripts
# Source this file; do not execute directly.

set -euo pipefail

_PASS=0
_FAIL=0
_WARN=0
_EXIT_CODE=0

pass() {
  printf "  ✓ %s\n" "$1"
  (( _PASS++ )) || true
}

fail() {
  printf "  ✗ %s\n" "$1"
  (( _FAIL++ )) || true
  _EXIT_CODE=1
}

warn() {
  printf "  ⚠ %s\n" "$1"
  (( _WARN++ )) || true
}

summary() {
  echo ""
  echo "=== Summary: $_PASS passed, $_FAIL failed, $_WARN warnings ==="
  return $_EXIT_CODE
}

# YAML parsing via Ruby (macOS built-in)
yaml_valid() {
  local file="$1"
  ruby -ryaml -e "YAML.load_file('$file')" 2>/dev/null
}

yaml_get() {
  local file="$1"
  local field="$2"
  ruby -ryaml -e "
    data = YAML.load_file('$file')
    val = data
    '$field'.split('.').each { |k| val = val.is_a?(Hash) ? val[k] : nil }
    puts val.nil? ? '' : val
  " 2>/dev/null
}

yaml_list_length() {
  local file="$1"
  local field="$2"
  ruby -ryaml -e "
    data = YAML.load_file('$file')
    val = data
    '$field'.split('.').each { |k| val = val.is_a?(Hash) ? val[k] : nil }
    puts val.is_a?(Array) ? val.length : 0
  " 2>/dev/null
}

yaml_array_field_values() {
  # Get a specific field from each element in a YAML array
  local file="$1"
  local array_field="$2"
  local element_field="$3"
  ruby -ryaml -e "
    data = YAML.load_file('$file')
    val = data
    '$array_field'.split('.').each { |k| val = val.is_a?(Hash) ? val[k] : nil }
    if val.is_a?(Array)
      val.each { |item| puts item['$element_field'] if item.is_a?(Hash) && item['$element_field'] }
    end
  " 2>/dev/null
}

yaml_has_nested_field() {
  # Check if items in a YAML array have a nested field
  local file="$1"
  local array_field="$2"
  local nested_field="$3"
  ruby -ryaml -e "
    data = YAML.load_file('$file')
    val = data
    '$array_field'.split('.').each { |k| val = val.is_a?(Hash) ? val[k] : nil }
    count = 0
    if val.is_a?(Array)
      val.each do |item|
        if item.is_a?(Hash)
          nested = item
          '$nested_field'.split('.').each { |k| nested = nested.is_a?(Hash) ? nested[k] : nil }
          count += 1 if nested
        end
      end
    end
    puts count
  " 2>/dev/null
}

count_words() {
  # Count words; for CJK text, count characters as words
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo 0
    return
  fi
  ruby -e "
    text = File.read('$file')
    # Remove YAML frontmatter
    text = text.sub(/\A---.*?---\s*/m, '')
    # Remove markdown headings markers
    text = text.gsub(/^#+\s*/, '')
    # Count: CJK characters count as 1 word each, other words by spaces
    cjk = text.scan(/[\u4e00-\u9fff\u3400-\u4dbf]/).length
    non_cjk = text.gsub(/[\u4e00-\u9fff\u3400-\u4dbf]/, ' ').split.length
    puts cjk + non_cjk
  " 2>/dev/null
}

count_words_section() {
  # Count words in a specific markdown section (from heading to next same-level heading)
  local file="$1"
  local heading="$2"
  ruby -e "
    text = File.read('$file')
    # Find the heading
    lines = text.lines
    start_idx = nil
    heading_level = nil
    lines.each_with_index do |line, i|
      if line.strip =~ /^(#+)\s+.*\b#{Regexp.escape('$heading')}\s*$/i
        start_idx = i
        heading_level = \$1.length
        break
      end
    end
    unless start_idx
      puts 0
      exit
    end
    # Collect lines until next heading of same or higher level
    section_lines = []
    lines[(start_idx+1)..].each do |line|
      if line.strip =~ /^(\#{1,#{heading_level}})\s+/
        break
      end
      section_lines << line
    end
    text = section_lines.join
    cjk = text.scan(/[\u4e00-\u9fff\u3400-\u4dbf]/).length
    non_cjk = text.gsub(/[\u4e00-\u9fff\u3400-\u4dbf]/, ' ').split.length
    puts cjk + non_cjk
  " 2>/dev/null
}

has_section() {
  local file="$1"
  local heading="$2"
  grep -qiE "^#{1,6}\s+.*${heading}" "$file" 2>/dev/null
}

resolve_path() {
  # Resolve a path relative to a base directory
  local base="$1"
  local rel="$2"
  local resolved
  resolved="$(cd "$base" && cd "$(dirname "$rel")" 2>/dev/null && pwd)/$(basename "$rel")"
  echo "$resolved"
}
