# v0 Failures

## Genesis Attempt Failures (attempt-001)

The genesis attempt had two post-creation structural failures caught by `validate.sh`:

### Failure 1: `.step0.yaml` skill_name mismatch
- **Found**: `skill_name: awesome-skill-creator`
- **Expected**: `skill_name: awesome-skill-creator-v0` (must match directory name)
- **Root cause**: Initial creation used family name instead of versioned directory name
- **Fix**: Updated `skill_name` field to match directory
- **Impact**: validate_manifest failed 1 case

### Failure 2: `manifest.yaml` whitepaper_ref wrong depth
- **Found**: `whitepaper_ref: ../facts/meta_whitepaper.md`
- **Expected**: `whitepaper_ref: ../../facts/meta_whitepaper.md`
- **Root cause**: Skill placed in `awesome-skill-creator-v0/` subdirectory after initial creation at repo root, relative path not updated
- **Fix**: Added one `../` level to the path
- **Impact**: validate_manifest failed 1 case

### Failure 3: Article word count below minimum (9 failures)
- **Found**: Total 3573 words, Design 1824, Evaluation 1105
- **Expected**: Total ≥8000, Design 2000-3000, Evaluation 1500-2500
- **Root cause**: Article first draft targeted brevity over required minimums
- **Fix**: Expanded Design sections (3.8, 3.9 on preflight + attempt tracking), added Evaluation section 4.5 (case distribution analysis)
- **Final state**: Total 8519, Design 2163, Evaluation 1518 — all pass

## Note on attempts-002 through attempt-007

Attempts 002-007 represent historical reconstructions of the skill-creator v1-v7 generational evolution (the Seven Days of Genesis narrative). They contain `execution_status: "predicted"` because they document the design-level breakthroughs of each generation, not live eval runs. These are architectural evidence, not execution evidence.
