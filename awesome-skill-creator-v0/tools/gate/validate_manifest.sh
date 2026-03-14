#!/usr/bin/env bash
# validate_manifest.sh — Validate manifest.yaml format and fields
# Usage: validate_manifest.sh <manifest-path>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib.sh"

MANIFEST="${1:?Usage: validate_manifest.sh <manifest-path>}"

echo "[Manifest: $MANIFEST]"

# YAML syntax
if yaml_valid "$MANIFEST"; then
  pass "YAML syntax valid"
else
  fail "YAML syntax invalid"
  summary
  exit $_EXIT_CODE
fi

# Required fields (scaffold.md §manifest.yaml 必须包含)
required_fields=("name" "family" "version" "status" "type" "bootstrap_status" "capabilities" "federation_protocol" "whitepaper_ref")
for field in "${required_fields[@]}"; do
  val=$(yaml_get "$MANIFEST" "$field")
  if [[ -n "$val" && "$val" != "None" ]]; then
    pass "Field '$field' present: $val"
  else
    fail "Field '$field' missing or empty"
  fi
done

# Scheduler-required fields (whitepaper §2.2: missing → "视为结构不完整，不能准出")
# parent_version may be explicitly null for v0 (no prior version) — that's valid
for field in "bootstrap_completed" "bootstrap_target" "creator_version" "parent_version" "auto_upgrade_policy" "latest_alias"; do
  val=$(yaml_get "$MANIFEST" "$field")
  if [[ -n "$val" && "$val" != "None" ]]; then
    pass "Field '$field' present: $val"
  elif [[ "$field" == "parent_version" && -z "$val" ]]; then
    pass "Field '$field' null/absent (v0: no prior version — acceptable)"
  else
    fail "Field '$field' missing (whitepaper §2.2: scheduler requires this field — 不能准出)"
  fi
done

# bootstrap_target format: should be vN (scaffold.md: "当前版本要产出的下一版本")
bt_val=$(yaml_get "$MANIFEST" "bootstrap_target")
if [[ -n "$bt_val" && "$bt_val" != "None" ]]; then
  if [[ "$bt_val" =~ ^v[0-9]+$ ]]; then
    pass "bootstrap_target '$bt_val' matches v\\d+ pattern"
  else
    fail "bootstrap_target '$bt_val' does not match v\\d+ pattern (scaffold.md §manifest: bootstrap_target must be version number)"
  fi
fi

# federation_protocol format: should be a version string like "2.0" (whitepaper §2.2)
fp_val=$(yaml_get "$MANIFEST" "federation_protocol")
if [[ -n "$fp_val" && "$fp_val" != "None" ]]; then
  if [[ "$fp_val" =~ ^[0-9]+\.[0-9]+$ ]]; then
    pass "federation_protocol '$fp_val' matches version format (N.N)"
  else
    fail "federation_protocol '$fp_val' must be version format like '2.0' (N.N)"
  fi
fi

# bootstrap_completed must be boolean (scaffold.md: bootstrap_completed: bool)
bc_val=$(yaml_get "$MANIFEST" "bootstrap_completed")
if [[ -n "$bc_val" && "$bc_val" != "None" ]]; then
  if [[ "$bc_val" =~ ^(true|false|True|False|yes|no)$ ]]; then
    pass "bootstrap_completed '$bc_val' is boolean"
  else
    fail "bootstrap_completed '$bc_val' must be boolean true/false (scaffold.md §manifest)"
  fi
fi

# creator_version and parent_version should follow vN pattern (scaffold.md §manifest)
for versioned_field in "creator_version" "parent_version"; do
  vf_val=$(yaml_get "$MANIFEST" "$versioned_field")
  if [[ -n "$vf_val" && "$vf_val" != "None" ]]; then
    if [[ "$vf_val" =~ ^v[0-9]+ || "$vf_val" =~ -v[0-9]+$ || "$vf_val" == "none" ]]; then
      pass "$versioned_field '$vf_val' format valid"
    else
      fail "$versioned_field '$vf_val' must follow v\\d+ or name-v\\d+ pattern (scaffold.md §manifest)"
    fi
  fi
done

# auto_upgrade_policy enum (whitepaper: default all_ge_old_and_one_gt)
aup_val=$(yaml_get "$MANIFEST" "auto_upgrade_policy")
if [[ -n "$aup_val" && "$aup_val" != "None" ]]; then
  if [[ "$aup_val" =~ ^(all_ge_old_and_one_gt|manual|disabled)$ ]]; then
    pass "auto_upgrade_policy '$aup_val' is valid enum"
  else
    fail "auto_upgrade_policy '$aup_val' not in {all_ge_old_and_one_gt, manual, disabled} (scaffold.md §manifest enum)"
  fi
fi

# type enum
type_val=$(yaml_get "$MANIFEST" "type")
if [[ "$type_val" =~ ^(meta|infrastructure|domain|utility)$ ]]; then
  pass "type '$type_val' is valid enum"
else
  fail "type '$type_val' not in {meta, infrastructure, domain, utility}"
fi

# status enum
status_val=$(yaml_get "$MANIFEST" "status")
if [[ "$status_val" =~ ^(draft|researching|optimizing|pressure_testing|releasable|active|retired|archived|bootstrapping)$ ]]; then
  pass "status '$status_val' is valid enum"
else
  fail "status '$status_val' not in {draft, researching, optimizing, pressure_testing, releasable, active, retired, archived, bootstrapping}"
fi

# bootstrap_status enum
bs_val=$(yaml_get "$MANIFEST" "bootstrap_status")
if [[ "$bs_val" =~ ^(genesis|objective_bootstrapping|subjective_bootstrapping|mature)$ ]]; then
  pass "bootstrap_status '$bs_val' is valid enum"
else
  fail "bootstrap_status '$bs_val' not in {genesis, objective_bootstrapping, subjective_bootstrapping, mature}"
fi

# version pattern
ver_val=$(yaml_get "$MANIFEST" "version")
if [[ "$ver_val" =~ ^v[0-9]+$ ]]; then
  pass "version '$ver_val' matches v\\d+ pattern"
else
  fail "version '$ver_val' does not match v\\d+ pattern"
fi

# capabilities is list and non-empty
cap_len=$(yaml_list_length "$MANIFEST" "capabilities")
if [[ "$cap_len" -gt 0 ]]; then
  pass "capabilities has $cap_len items"
else
  fail "capabilities is empty or not a list"
fi

# whitepaper_ref path existence check
# Resolves relative path from manifest dir; also walks up the tree to handle skills in .tmp/ subdirs
wp_ref=$(yaml_get "$MANIFEST" "whitepaper_ref")
if [[ -n "$wp_ref" && "$wp_ref" != "None" ]]; then
  manifest_dir="$(cd "$(dirname "$MANIFEST")" && pwd)"
  wp_found=""
  # First try direct resolution
  if [[ -f "$manifest_dir/$wp_ref" ]]; then
    wp_found="$manifest_dir/$wp_ref"
  else
    # Walk up directory tree looking for the file (handles skills inside .tmp/ subdirs)
    _wdir="$manifest_dir"
    for _ in 1 2 3 4 5; do
      _wdir="$(dirname "$_wdir")"
      _candidate="$_wdir/$(basename "$wp_ref")"
      if [[ -f "$_candidate" ]]; then
        wp_found="$_candidate"
        break
      fi
      [[ "$_wdir" == "/" ]] && break
    done
  fi
  if [[ -n "$wp_found" ]]; then
    pass "whitepaper_ref '$wp_ref' file exists"
  else
    fail "whitepaper_ref '$wp_ref' file not found (path: $manifest_dir/$wp_ref) — update whitepaper_ref to point to actual whitepaper"
  fi
fi

# name must match directory name of manifest's parent dir
dir_name="$(basename "$(dirname "$MANIFEST")")"
name_val=$(yaml_get "$MANIFEST" "name")
if [[ "$name_val" == "$dir_name" ]]; then
  pass "manifest name '$name_val' matches directory name"
else
  warn "manifest name '$name_val' does not match directory '$dir_name' (may be intentional alias)"
fi

# version must match the vN suffix of the directory name
dir_version_suffix=$(echo "$dir_name" | grep -oE 'v[0-9]+$' || true)
if [[ -n "$dir_version_suffix" ]]; then
  if [[ "$ver_val" == "$dir_version_suffix" ]]; then
    pass "manifest version '$ver_val' matches directory suffix '$dir_version_suffix'"
  else
    fail "manifest version '$ver_val' does not match directory suffix '$dir_version_suffix' (version mismatch)"
  fi
fi

# name must equal family + "-" + version (whitepaper §2.2: name = family-vN)
family_val=$(yaml_get "$MANIFEST" "family")
if [[ -n "$family_val" && "$family_val" != "None" && -n "$ver_val" && "$ver_val" != "None" ]]; then
  expected_name="${family_val}-${ver_val}"
  if [[ "$name_val" == "$expected_name" ]]; then
    pass "manifest name '$name_val' = family '$family_val' + version '$ver_val' (name=family-vN)"
  else
    fail "manifest name '$name_val' does not equal family-version '${expected_name}' (whitepaper §2.2: name must be family-vN)"
  fi
fi

# latest_alias should equal family (whitepaper §2.2: stable entry point = family name)
la_val=$(yaml_get "$MANIFEST" "latest_alias")
if [[ -n "$la_val" && "$la_val" != "None" && -n "$family_val" && "$family_val" != "None" ]]; then
  if [[ "$la_val" == "$family_val" ]]; then
    pass "latest_alias '$la_val' equals family '$family_val' (whitepaper §2.2 stable entry convention)"
  else
    fail "latest_alias '$la_val' does not equal family '$family_val' (whitepaper §2.2: latest_alias must equal family name)"
  fi
fi

exit $_EXIT_CODE
