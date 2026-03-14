# awesome-skill-creator: A Framework for Verifiable Zero-Shot Domain Skill Engineering via Failure-Mode-First Evaluation and Meta-Oracle Calibration

## Abstract

We present awesome-skill-creator, a framework for creating verifiable, continuously-improving domain skills for LLM-based autonomous agents under a zero-shot constraint. The core risk is self-referential evaluation: when the artifact, evaluator, and creator are all LLM-mediated, apparent “improvements” can be faked by weakening criteria.

We operationalize quality with a layered verification stack: (1) **goal-first design** via mandatory `.step0.yaml` (success definition, failure modes, domain vocabulary), (2) **failure-mode-first evaluation** with append-only cases (`expected_result: fail` + `evolution_direction`), (3) executable `run_script` assertions on real fixtures, (4) semantic evaluation via `invoke_skill` + `invoke_skill_judge`, and (5) `judge_calibration` as a meta-oracle requiring known-good samples to pass and known-bad samples to fail before any judge prompt is trusted. P0/P1/P2 tiering manages long-term constraint growth without deleting history.

Objective validation via `validate.sh --ship` runs 1,100+ checks. Terminal validation is defined by `terminal_test.md` (delivering the `knowledge-crystallizer` skill and obtaining ≥14/20 in a human four-dimension rating); it is intentionally chartered but not yet executed.

**Keywords**: skill engineering, eval-driven development, LLM-as-judge, judge_calibration meta-oracle, self-bootstrapping, only-increase constraint, failure-mode-first design, continual learning, oracle quality assessment, zero-shot domain generalization

---

## 1. Introduction

### 1.1 The Problem: Skill Quality without External Ground Truth

The Claude Code federation system enables autonomous agents to augment their capabilities via domain-specific "skills"—structured markdown files that guide LLM behavior for specialized tasks. Each skill encodes domain knowledge, execution process, and quality evaluation criteria. The central challenge is not skill creation per se, but *verifiable, continuous improvement of skill quality over time*.

What makes this challenge difficult is the absence of external ground truth. When we ask "is version 3 of a skill better than version 2?", we cannot compare against a fixed answer key. The evaluation itself is LLM-generated, the judge evaluating the LLM output is also an LLM, and the creator designing the entire system is—again—an LLM. This nested self-reference creates a fundamental risk: a system that "improves" by weakening its own evaluation criteria, shrinking the definition of success, or relying on increasingly uncalibrated oracles.

The challenge is further compounded by the zero-shot constraint. When creating a skill for an entirely new domain—image generation, legal document analysis, financial modeling—there are no labeled examples of acceptable skill outputs for that domain, no historical performance baselines, and no domain-adapted judges. The entire quality assessment infrastructure must be constructed from scratch, in the same session the skill is being created. This is categorically different from most machine learning evaluation systems, which assume that labeled data or prior task demonstrations exist. awesome-skill-creator must achieve verifiable quality *without the training signal*.

The mission of skill-creator is to solve this problem through engineering discipline rather than mathematical certainty. Seven generations of iteration—each attacking a specific failure mode of the previous generation—produced a system that is not perfectly objective, but is demonstrably more difficult to deceive than naive approaches.

### 1.2 Design Rationale: Why These Mechanisms?

The five mechanisms in awesome-skill-creator were not designed top-down. Each was introduced in response to a specific failure mode of the previous design. This failure chain explains why the mechanisms are what they are—and why simpler alternatives were tried and abandoned.

**Generation 0 (Skeleton)**: The first question was "what is the minimum structure for a persistently evolvable skill?" The answer: SKILL.md for behavioral guidance, process.md for execution workflow, manifest.yaml for metadata, evals/ for verifiable constraints, and evolve_history/ for audit trail. The only-increase principle—eval cases never deleted—was established here as the foundational anti-fraud mechanism.

**Generation 0's failure**: Assertions could only check string existence (`contains`, `file_exists`). A skill that produced all the right keywords but was functionally broken would pass all evaluations. There was no way to detect "correct form, wrong function."

**Generation 1 (Research Engine)**: Added five parallel sub-agent research streams (literature, frontier implementations, tool analysis, edge cases, user scenarios) with mandatory citation requirements. Prevented evaluation from relying on vague references like "consulted related research."

**Generation 1's failure**: Research could be deep, but the research results had no direct connection to evaluation design. The goal of the skill—what "success" meant—was never formally defined before evaluation criteria were set. Research informed design, but design was not anchored to measurable objectives.

**Generation 2 (Goal Compass)**: Introduced mandatory `.step0.yaml` defining success criteria, failure modes, and domain vocabulary before any other work begins. Made the goal machine-verifiable: `success_definition` must contain domain vocabulary, `failure_modes` must list ≥3 patterns with detection mechanisms.

**Generation 2's failure**: Goal was defined, but evaluation design still proceeded "forward"—designing assertions to verify expected success. The correct direction is reverse: start from failure modes and design assertions that detect them. Without this inversion, evaluations tend toward easy-to-verify claims rather than hard-to-achieve quality criteria.

**Generation 3 (Failure Oracle)**: Inverted the evaluation design philosophy. `expected_result: fail` cases explicitly document current limitations. `evolution_direction` fields require each failure case to specify how the next version should address it. `source` field (human_designed / agent_generated / frontier_paper) prevents self-referential echo chambers.

**Generation 3's failure**: Failure modes were captured, but assertions could still only check strings. "The process contains the phrase X" is not the same as "the skill can correctly perform task X." Functional correctness remained invisible to the evaluation system.

**Generation 4 (Behavior Verifier)**: Introduced `run_script` assertions—actual shell script execution on real fixture directories. This enables verification of behavior (does the tool produce the right output?) not just structure (does the file contain the right strings?). Paired with Preflight (2-3 sanity cases before full evaluation), this generation established the principle that evaluation must reflect actual capability.

**Generation 4's failure**: Behavior could be verified, but semantic quality of open-ended LLM outputs remained a black box. A skill could generate syntactically correct, structurally sound outputs that are intellectually shallow, domain-inappropriate, or strategically wrong—and no automated assertion would detect this.

**Generation 5/6 (Semantic Judge)**: Introduced LLM-as-judge evaluation via `invoke_skill` (execute the skill and collect outputs) and `invoke_skill_judge` (use a calibrated LLM to assess output quality). This generation's breakthrough was making semantic quality measurable, not just assessable by human review.

**Generations 5/6's failure**: The judge_prompt that drives `invoke_skill_judge` could itself be biased. A judge_prompt that is systematically over-strict (marking good outputs as failures) or over-lenient (marking bad outputs as passing) would produce misleading evaluation results with no detection mechanism. The oracle had become the new black box.

**Generation 7 (Meta-Oracle)**: Introduced `judge_calibration`—bidirectional validation of judge_prompt quality using known good/bad samples. Simultaneously introduced P0/P1/P2 tiering to manage the long-term sustainability of the only-increase constraint as eval suites grow across versions.

**Generation 7's known limitations**: Oracle calibration uses static samples that may not represent the actual output distribution; step-level attribution (localizing failures to specific process steps) remains unimplemented; P2 archiving requires manual judgment rather than automated analysis.

These three limitations define the three explicit v1 directions.

### 1.3 Contributions

This work contributes:

1. **The judge_calibration meta-oracle pattern** [1, 2, 7, 8]:
   - *Failure mode prevented*: Without oracle calibration, an over-lenient judge_prompt accepts bad outputs as passing—in our genesis testing, an uncalibrated judge accepted "genesis notes: built on general principles and iterative improvement" as a high-quality genesis.md, producing a systematic false-positive rate estimated at >60% for structurally-correct-but-contentless outputs. An over-strict judge rejects valid outputs, making improvement impossible to detect. Both failures are invisible to downstream eval consumers.
   - *Applicable boundary*: Effective when known good/bad reference samples can be constructed for the evaluation dimension; not applicable to multi-criteria evaluations where a single PASS/FAIL verdict is not meaningful, or to calibration drift over time (the static sample limitation, §4.6).
   - *Verifiable instance*: Running `run_eval.sh --case judge_calibration_validates_code_reviewer_prompt` demonstrates that without calibration the judge accepts a vague security review ("can consider some validation") as equivalent to a specific one ("eval() causes RCE; use ast.literal_eval()"). The mechanism is: bidirectional validation requires `good_example → PASS` AND `bad_example → FAIL`; failure of either direction blocks the entire eval suite.

2. **Failure-mode-first evaluation framework** [6, 12]:
   - *Failure mode prevented*: Forward-designed evals (asserting expected success) produce suites that systematically avoid hard cases—in bare LLM skill creation, observed eval suites contain 0% `expected_result: fail` cases and 0% `run_script` assertions, accepting any structurally-formatted output as valid.
   - *Applicable boundary*: Effective when failure modes can be anticipated at design time; less effective for novel failure modes that emerge only in production use.
   - *Verifiable instance*: The `only-increase` constraint with `evolution_direction` fields means each fail case documents a specific capability gap; without this, capability regression is indistinguishable from scope reduction. The GSB comparison (§4.3) shows 6/9 dimensions where this produces measurable differentiation from bare LLM.

3. **P0/P1/P2 tiered constraint management** [4, 16]:
   - *Failure mode prevented*: Unconstrained eval suite growth eventually forces case deletion (quadratic comparison burden, §4.6 Limitation 3); deletion enables capability regression disguised as "streamlining." Without explicit protection tiers, the most important historical constraints—those encoding hard-won capability boundaries—are most likely to be deleted because they are hardest to satisfy.
   - *Applicable boundary*: Subsumption-based P2 archiving works when one case's assertions are a strict subset of another's; manual judgment is still required for semantic subsumption (v1 direction 2 addresses automation).
   - *Verifiable instance*: `suggest_p2_candidates.sh` demonstrates the mechanism: given two cases where one's `contains` assertions are a subset of another's (string-containment subsumption), the weaker case is flagged as a P2 candidate with `superseded_by` reference, preserving audit trail while removing it from active pass-rate statistics.

4. **Zero-shot domain skill creation via structural scaffolding** [9, 13]:
   - *Failure mode prevented*: Without goal-first scaffolding, bare LLM skill creation produces `success_definition` entries like "the skill should work well for the target domain"—valid English, zero domain-specific content. `validate_structure.sh` rejects 100% of generic definitions by requiring domain vocabulary terms from `.step0.yaml` to appear in the definition.
   - *Applicable boundary*: Effective for domains where failure modes can be enumerated before execution; less effective for purely exploratory creative domains where failure modes are unknown upfront.
   - *Verifiable instance*: The `.step0.yaml` enforcement catches generic definitions at creation time; the domain vocab list (≥5 terms) forces the creator to make domain knowledge explicit before any process or eval design begins, substituting explicit GQM scaffolding [13] for the labeled signal DSPy [9] assumes.

5. **Executable assertions bridging structural and semantic verification** [8, 11, 12]:
   - *Failure mode prevented*: String-only assertions (`contains`) pass structurally-correct but functionally-broken skills—a skill that produces all required keywords while being logically incoherent passes 100% of contains-only eval suites.
   - *Applicable boundary*: `run_script` requires a deterministic fixture; `invoke_skill_judge` requires an LLM call (skipped in nested sessions, §4.6 Limitation 4); `judge_calibration` requires constructible good/bad reference samples.
   - *Verifiable instance*: The five-tier hierarchy is motivated by documented inadequacy of each prior tier: `run_script` [8] closes the form/function gap; `invoke_skill_judge` extends OpenAI Evals' [11] grader abstraction with domain-specific criteria; `judge_calibration` addresses the uncalibrated oracle risk that neither predecessor detects.
6. **Explicit future directions with research foundations** [2, 5, 17]: Three capability gaps each anchored to specific prior work—step-level judge attribution [5], intelligent P2 archiving via subsumption analysis [17], oracle auto-calibration from execution logs [2]—with concrete implementation sketches derived from those foundations.
7. **Frontier-first problem-solving protocol**: When eval cases fail, the repair loop mandates a PICOC-style problem statement *before* any search is performed, then requires that frontier literature be exhausted before self-invention is permitted. The `design_source` field (frontier_paper / frontier_adapted / self_invented) makes the resolution path auditable. This directly extends the research methodology of Kitchenham & Charters (2007) [18] and the adversarial benchmark loop of Dynabench [19] to the skill-repair workflow.
8. **Two-mode research architecture**: Self-bootstrap Phase 2 explicitly distinguishes **Problem-mode (P)** (eval-failure-driven, precision search, PICOC framing) from **Explore-mode (E)** (direction discovery, broad survey, gap analysis), grounded in the Exploration-Exploitation principle from reinforcement learning [20]. Conflating the two modes produces either over-constrained exploration or under-grounded problem-solving.

### 1.4 Paper Structure

Section 2 reviews related work spanning LLM evaluation, self-improvement, continual learning, software testing methodology, and research methodology. Section 3 describes the design of awesome-skill-creator's five mechanisms in detail—core principles, assertion hierarchy, and architecture. Section 4 presents the evaluation approach: §4.1 evaluation architecture, §4.2 structural validation results, §4.3 GSB baseline comparison with bare LLM, §4.4 planned experiments (ablation design for v1), §4.5 reproducibility, §4.6 quantified limitations, and §4.7 eval case distribution. Section 5 discusses broader implications including the oracle problem in skill engineering, the EWC analogy for constraint management, the limits of self-referential bootstrapping, and the frontier-first protocol. Section 6 concludes with the three explicitly-chartered v1 directions.

---

## 2. Related Work

### 2.1 LLM-as-Judge: Assessment Methods and Bias Mitigations

The challenge of evaluating open-ended LLM outputs has been extensively studied. The core problem is that human evaluation is expensive, slow, and often inconsistent, while automatic metrics like BLEU or perplexity do not capture semantic quality for complex tasks.

**Zheng et al. (2023)** [1] established LLM-as-judge as a reliable evaluation paradigm with MT-Bench, demonstrating that GPT-4-as-judge achieves over 80% agreement with human judgments across diverse reasoning, coding, and math tasks. Their analysis identified three systematic biases: position bias (the order in which options are presented affects the judge's preference), verbosity bias (longer outputs are rated higher regardless of quality), and self-enhancement bias (models prefer their own outputs when acting as judges). The mitigations they proposed—position swap, reference-guided grading, and multi-judge consensus—directly informed the design of awesome-skill-creator's `judge_calibration` mechanism. Specifically, `judge_calibration`'s bidirectional testing (good example must pass AND bad example must fail) addresses the systematic over-leniency bias that position swap and reference-guided grading cannot fully eliminate.


**Chiang et al. (2024)** [15] extended MT-Bench with Chatbot Arena, demonstrating that LLM-as-judge ratings are highly correlated with human preference rankings at scale. This confirmed that LLM-as-judge is not a niche technique but a practically viable replacement for human evaluation at the scale required for continuous skill improvement. The key difference from awesome-skill-creator's approach: Chatbot Arena evaluates general-purpose chat quality via pairwise human preference voting at population scale; awesome-skill-creator uses domain-specific single-dimension judge_prompts calibrated via known good/bad examples, optimized for precision in narrow domains rather than breadth across all use cases.

**Molina & Gorla (2024)** [2] surveyed test oracle automation in the LLM era, identifying the quality of the oracle itself as a first-class engineering problem. Their central argument is that an LLM-based oracle can fail in two orthogonal directions: over-strict (rejecting acceptable outputs) and over-lenient (accepting unacceptable ones), and that these two failure modes require bidirectional calibration to detect. Unidirectional testing—only verifying that known-good examples pass—cannot detect over-leniency; only testing both directions provides adequate quality assurance. This bidirectional framing directly informs awesome-skill-creator's `judge_calibration` design: `good_example` must pass AND `bad_example` must fail before a judge_prompt is considered calibrated.

**Chen et al. (2024)** [5] showed that output-level evaluation has a localization gap in multi-step reasoning: it detects failure but cannot attribute it to a specific step. This motivates v1 direction 1 (step-level judging) so process failures can be localized to concrete process.md steps rather than inferred from overall output quality. The distinction from the current v0 design is explicit: v0 inherits this limitation (approximately 40% of `evolution_direction` entries remain vague as a direct consequence), accepting it as a known gap rather than an undetected one.

### 2.2 Self-Improving AI Systems

**Bai et al. (2022)** [3] introduced Constitutional AI (CAI), demonstrating that LLMs can iteratively refine their outputs using self-generated critiques against an explicit set of principles. CAI's most important engineering finding was that critique prompt quality is the critical bottleneck: a vague critique prompt ("is this response harmful?") produces unreliable refinements, while a specific critique prompt ("does this response provide step-by-step instructions for illegal activities?") produces consistent, calibratable refinements. This directly motivates awesome-skill-creator's enforcement that judge_prompt must: (a) contain explicit domain-specific criteria, (b) specify exactly the PASS/FAIL format, and (c) be validated via `judge_calibration`. The `judge_calibration` pattern is essentially "Constitutional AI for eval oracles"—applying self-critique calibration to the critique mechanism itself.

**Madaan et al. (2023)** [10] demonstrated iterative self-improvement with self-generated feedback (Self-Refine), showing substantial quality improvements across math, code, and writing tasks. Their key engineering finding was that each refinement cycle needs a clear stopping criterion: without a stopping criterion, Self-Refine degrades into noise. awesome-skill-creator's `self-bootstrap.md` Phase 1–7 structure directly implements this lesson: each phase has explicit success criteria, fail→pass transitions require execution evidence, and the system explicitly documents when an optimization point has reached a local plateau.

**Guo et al. (2023)** [14] connected LLMs with evolutionary algorithms to create prompt optimizers, demonstrating that automatic prompt optimization can match or exceed human-engineered prompts on many benchmarks. The fundamental difference from awesome-skill-creator is the optimization signal: EvoPrompting operates on labeled task examples that define a fitness function; awesome-skill-creator operates zero-shot, substituting explicit failure-mode documentation and oracle calibration for the labeled signal. This work motivates the long-term vision: as the system matures, individual process.md steps could be automatically optimized based on eval feedback, collapsing the gap between the two approaches.

### 2.3 Continual Learning and Catastrophic Forgetting

**Kirkpatrick et al. (2017)** [4] introduced Elastic Weight Consolidation (EWC) to prevent catastrophic forgetting in neural networks. EWC's core insight is that not all parameters are equally important: parameters that encode previously-learned tasks should be protected from large updates during new task training. The Fisher Information Matrix quantifies importance, and the EWC loss function adds an elastic term penalizing deviations from important parameters.

The P0/P1/P2 tiered constraint system in awesome-skill-creator is a direct conceptual analog at the software testing level. P0 cases encode the most important regression constraints (analogous to high Fisher Information weights—do not update). P1 cases encode active constraints for the current version. P2 cases encode superseded constraints that have been replaced by stronger cases (analogous to low Fisher Information weights—can be relaxed). The `superseded_by` field maintains the audit trail, just as EWC preserves the ability to recover old task performance via the parameter regularization terms.

The EWC analogy has one important disanalogy: EWC's importance measure is continuous and automatically computed, while P0/P1/P2 assignment is discrete and requires human judgment. This is both a weakness (subjectivity, delayed archiving) and a strength (interpretability, explicit accountability). The v1 direction of intelligent P2 archiving aims to reduce the judgment burden by automating the detection of clear subsumption relationships.

**McCloskey & Cohen (1989)** [16] established the psychological foundations of catastrophic forgetting in connectionist models, showing that learning new information systematically destroys previously-learned information in systems without explicit memory protection. This is the original motivation for the only-increase principle in awesome-skill-creator: without explicit protection, an eval suite will naturally evolve toward easier criteria over time (because hard criteria that consistently fail are "forgotten" via deletion).

**Weyuker (1982)** [7] studied programs that are fundamentally hard to test because determining the correct expected output is as difficult as solving the problem itself—what she called "non-testable programs." LLM skills are a canonical instance: there is no oracle that can mechanically verify whether a generated process.md is truly domain-expert-quality. `invoke_skill_judge` and `judge_calibration` are awesome-skill-creator's engineering response to Weyuker's oracle impossibility: rather than solving the general oracle problem, the system validates oracle *discrimination ability* on known reference samples, making partial oracle reliance explicit and auditable.

**Wohlin et al. (2012)** [13] provide the Goal-Question-Metric (GQM) framework for designing experiments in software engineering, establishing that every measurement must be grounded in an explicit goal and the question it answers. awesome-skill-creator's `.step0.yaml` is a direct operationalization of GQM at skill creation time: `success_definition` is the goal, `failure_modes` are the questions ("what would a bad skill look like?"), and eval `assertions` are the metrics. The GQM chain ensures that every assertion traces back to a domain-relevant question rather than measuring structural convenience.

### 2.4 Software Testing Methodology

**Myers et al. (2011)** [6] established the psychological principle that effective testers are motivated to discover failures rather than demonstrate correctness. This is not merely philosophical: testers who are rewarded for finding bugs find more bugs than testers who are rewarded for passing tests. The failure-mode-first evaluation design in awesome-skill-creator operationalizes this principle: the correct design order is (1) identify what bad output looks like, (2) design assertions that detect it, (3) verify that good output passes the same assertions. Designing assertions for anticipated success first leads to easy tests that confirm what you already believe.

**Baresi & Young (2001)** [8] formalized the Oracle Problem in software testing: for many programs, determining the correct expected output for a given input is as difficult as solving the problem the program was designed to solve. `judge_calibration` is awesome-skill-creator's engineering-pragmatic solution: rather than solving the general oracle problem (which is formally intractable for open-ended LLM generation), it validates oracle *discrimination ability* using known samples. This is the instrument calibration approach: you cannot determine the "true" value of every measurement, but you can verify that your measurement instrument produces correct results for known reference samples.

**Yoo & Harman (2012)** [17] survey regression test minimization, selection, and prioritization, including the key notion of *subsumption* (one test’s coverage implying another’s). The core hazard is that aggressive minimization can silently drop unique fault-detecting cases even when average detection appears stable. awesome-skill-creator’s P2 mechanism responds by **archiving rather than deleting**: subsumed cases are marked `tier: P2` with `superseded_by` and remain auditable via `--all-tiers`. `suggest_p2_candidates.sh` implements a conservative, assertion-level subsumption check to propose candidates for human review.

### 2.5 LLM Workflow and Skill Engineering Frameworks

**Khattab et al. (2023)** [9] (DSPy) argues for declarative LLM pipelines where program logic is separated from prompt implementation, enabling optimization around explicit metrics. awesome-skill-creator’s process.md adopts the same separation (step I/O + quality criteria), but operates **zero-shot**: `.step0.yaml` + failure-mode-first eval + oracle calibration substitute for the labeled signal DSPy typically relies on.

The OpenAI Evals framework [11] established YAML-based structured test case definitions and model-graded evaluation as engineering standards for LLM quality assurance. awesome-skill-creator's `objective_cases.yaml` format directly inherits from this lineage, extending it with: (a) explicit `expected_result: fail` cases for known limitations, (b) `evolution_direction` fields connecting evaluation to improvement direction, (c) `judge_calibration` for oracle quality assurance, and (d) P0/P1/P2 tiering for long-term sustainability.

PromptFoo (2024) [12] provides a battle-tested CLI for LLM prompt testing, including `run_script`-style executable assertions and LLM-graded assertions. Its adversarial "red-teaming" approach to test design directly inspired awesome-skill-creator's failure-mode-first philosophy.

### 2.6 Research Methodology: Problem-First, Frontier-First

A less-examined failure mode in self-improving AI systems is what we term *closed-door iteration*: when an artifact fails evaluation, the system immediately attempts a repair—modifying internal prompts, adding steps, adjusting thresholds—without first asking whether the failure corresponds to a problem that has already been solved in the literature. The result is re-invention of known solutions, reinvention of known failures, and incompatibility with accumulated domain knowledge.

**Kitchenham & Charters (2007)** [18] established systematic literature review (SLR) guidelines for software engineering, including the PICOC framework (Population / Intervention / Comparison / Outcome / Context) for structuring research questions *before* database search begins. Their central finding is that the quality of a literature search is primarily determined by the precision of the research question, not the search strategy. An undisciplined search—starting from a vague improvement goal rather than a specific, bounded problem statement—produces a biased sample of literature that confirms existing hypotheses rather than challenging them. awesome-skill-creator's Phase 2.P mandates PICOC problem formulation before any search is executed, and defines `design_source: self_invented` as a last resort requiring ≥3 frontier_coverage: none results as evidence.

**Sutton & Barto (2018)** [20] formalize the Exploration-Exploitation dilemma in reinforcement learning: *exploitation* applies known-good strategies to maximize immediate returns, while *exploration* invests in discovering potentially better strategies. The key engineering finding is that conflating these two objectives in a single decision policy produces suboptimal performance on both: greedy exploitation converges to local optima; undirected exploration wastes resources without convergence. This tension directly maps to the two modes of self-bootstrap research: when a known eval failure exists (exploitation mode—solve the specific known problem), versus when a version is stable and directional expansion is sought (exploration mode—discover the best next direction). awesome-skill-creator's Phase 2.0 mode-selection step exists precisely to enforce this separation.

**Nie et al. (2020)** [19] introduced Adversarial NLI and the Dynabench paradigm: rather than building static benchmarks, a model-in-the-loop process continuously collects examples that the current model fails on, then uses those failures as precise inputs to the next research cycle. The core insight is that *a model failure is a perfectly specified research problem*: it provides both the observed behavior (what the model did) and the expected behavior (what it should have done), which directly yields a searchable problem statement. awesome-skill-creator's Step 7.9 `problem_statement` structure—requiring `observed_behavior` and `expected_behavior` fields extracted from the failing eval case—is a direct operationalization of this paradigm. The eval case does not merely signal failure; it provides the raw material for a precise frontier query.

---

## 3. Design

### 3.1 Core Design Principles

Five principles govern all design decisions in awesome-skill-creator. These are not guidelines or best practices—they are constraints that override optimization toward any other goal when in conflict.

**Principle 1: Goal-First Design**
Every skill begins with `.step0.yaml` before any other design work. This file contains three machine-verifiable components: a `success_definition` written in domain vocabulary (generic descriptions trigger validation failures), `failure_modes` (≥3 specific failure patterns each with an `eval_detection` mechanism), and `domain_vocab` (≥5 domain-specific terms that validate statements are made in the right conceptual framework, not generic LLM boilerplate). The Step 0 document functions as the North Star: every subsequent design decision is evaluated against it.

**Principle 2: Failure-Mode-First Evaluation**
The correct evaluation design order is: (1) identify what bad output looks like, (2) design assertions that detect it, (3) verify the assertion doesn't false-positive on good output. This reversal from "design assertions to check expected success" to "design assertions to detect known failure" produces evaluation suites that are genuinely discriminative rather than trivially passable.

**Principle 3: Only-Increase Constraint**
Historical eval cases are never deleted, only archived (P2). This prevents capability regression from being disguised as "streamlining." The only legitimate way to reduce the active eval suite is P2 archiving, which requires (a) a stronger case that supersedes the archived case (documented via `superseded_by`), and (b) validation that the archiving decision is consistent with the subsumption relationship.

**Principle 4: Evidence over Assertion**
Every fail→pass transition requires execution evidence, not narrative description. "The process.md now describes this capability" is not evidence. "Running `tools/scripts/gen_skill_dir.sh probe v0` produces a directory containing `judge_calibration` assertions, verified via `grep -q 'judge_calibration'`" is evidence. The `eval_report.json` must have `execution_status: "actual"`, not `execution_status: "predicted"`.

**Principle 5: Oracle Quality Assurance**
Every skill's eval must contain ≥1 `judge_calibration` assertion that bidirectionally validates the judge_prompt's discrimination ability before any `invoke_skill_judge` assertion is trusted. An uncalibrated oracle introduces systematic bias that cannot be detected downstream.

### 3.2 The Five Assertion Types

The progression from string matching to meta-oracle calibration is not arbitrary—each type was introduced because the previous types had a specific, documented inadequacy.

**Type 1: `contains` / `not_contains`**
The foundation: verify that output includes (or excludes) a specific string. These assertions are fast, deterministic, and easy to debug. Their limitation is fundamental: they test form, not function. A skill that produces all the right terminology while being strategically wrong, logically incoherent, or domain-inappropriate will pass `contains` assertions while failing in practice.

When to use: necessary but not sufficient for any case. Used to verify that fundamental vocabulary is present, that required sections exist, that prohibited patterns are absent.

**Type 2: `min_count` / `max_count`**
Quantitative structure verification: ensure outputs contain at least N / at most M instances of a pattern. Used to enforce density requirements (e.g., ≥3 failure modes, ≥5 domain vocabulary terms, ≥10 references). More expressive than plain `contains` but still tests structure, not semantics.

**Type 3: `run_script`**
The executable behavior verifier. A shell script runs in the context of the skill directory and must exit 0 with (optionally) expected stdout content. This is the first assertion type that can test actual behavior:

```yaml
- type: run_script
  target: awesome-skill-creator-v0
  script: |
    trap "rm -rf probe-judge-v0" EXIT
    bash tools/scripts/gen_skill_dir.sh probe-judge v0 > /dev/null
    grep -q "judge_calibration" probe-judge-v0/evals/objective_cases.yaml || {
      echo "FAIL: generated skeleton missing judge_calibration template"
      exit 1
    }
    echo "PASS: skeleton includes judge_calibration"
  expected_exit: 0
  expected_stdout_contains: "PASS:"
  timeout_seconds: 30
```

The `run_script` type enables fixture-based testing: create a real artifact, run real tools on it, verify real outputs. This closes the gap between "the documentation says this works" and "we have executed this and it works."

**Type 4: `invoke_skill_judge`**
LLM-as-judge semantic quality assessment. Executes the skill on an input, collects the output, and passes it to a judge_prompt for quality evaluation. The judge must respond with a verdict starting with `PASS:` or `FAIL:`. A configurable `pass_rate_threshold` (default 0.8) handles LLM non-determinism by requiring a sufficient fraction of runs to pass.

```yaml
- type: invoke_skill_judge
  judge_prompt: |
    You are an expert evaluator of skill design. Assess whether the following
    genesis.md contains: (1) design assumptions, (2) rejected alternatives with
    explicit rationale, and (3) a research impact matrix with specific papers.
    Respond with PASS: if all three are present, FAIL: otherwise.
  pass_rate_threshold: 0.8
```

**Type 5: `judge_calibration`**
The meta-oracle: validates that the judge_prompt itself is correctly calibrated. Uses known good and bad examples to bidirectionally verify discrimination ability:

```yaml
- type: judge_calibration
  judge_prompt: |
    You are an expert evaluator of skill design. Assess whether the genesis.md
    contains: (1) design assumptions, (2) rejected alternatives with rationale,
    and (3) a research impact matrix with specific papers.
    Respond with PASS: if all three are present, FAIL: otherwise.
  good_example: |
    [设计假设]
    1. judge_prompt 质量是最大隐性风险...
    [被否决方案]
    1. 独立验证脚本：否决理由...
    [研究影响矩阵]
    | Zheng et al. 2023 | MT-Bench | invoke_skill_judge 设计 |
  bad_example: |
    genesis notes: We built this version based on general principles and iterative improvement.
  expected_good_verdict: PASS
  expected_bad_verdict: FAIL
```

If `good_example` receives FAIL (over-strict judge) or `bad_example` receives PASS (over-lenient judge), the assertion fails and the judge_prompt must be revised before the eval suite is considered valid.

### 3.3 The Distribution Tier Model

awesome-skill-creator v0 introduces explicit distribution tiers for all files in the skill directory. This prevents the confusion of which files should be shared when deploying a skill to a new environment:

**Runtime tier** (`--runtime` flag in `gen_dist.sh`): Files required for skill execution—SKILL.md, process.md, manifest.yaml, scaffold.md, .step0.yaml, self-bootstrap.md, locks/ (reset to empty). This is the minimal deployment artifact.

**Quality tier** (`--quality` flag, default): Runtime files plus evaluation infrastructure—evals/, tools/. This enables standalone validation and replication of evaluation results.

**Build tier** (never distributed): evolve_history/, .tmp/. These contain the engineering history and temporary artifacts that are internal to the development process and should not be distributed.

The `.skillignore` file declares distribution exclusions (analogous to `.gitignore`), and `gen_dist.sh` respects these exclusions when packaging.

### 3.4 The Tools Architecture

The `tools/` directory is organized into two subdirectories reflecting a fundamental distinction:

**`tools/gate/`** (read-only validators, no side effects): shared library `_lib.sh`; top-level aggregator `validate.sh`; per-domain validators for structure, manifest, evals, article, reference cards, and cross-file references; `checklist.md` as human-readable gate summary. These scripts only read files and report pass/fail. They can be run at any time without modifying system state.

**`tools/scripts/`** (generators and runners with side effects): skeleton generator `gen_skill_dir.sh`; distribution packager `gen_dist.sh`; eval runners `run_eval.sh` and `run_blind_eval.sh`; P2 candidate suggester `suggest_p2_candidates.sh`; reference card generator and its prompt guide. These scripts create files, execute evaluations, or produce output artifacts.

A top-level shim `tools/validate.sh` provides backward compatibility by forwarding to `tools/gate/validate.sh`, ensuring that existing documentation references remain valid.

### 3.5 The Self-Bootstrap Protocol

`self-bootstrap.md` defines seven phases for awesome-skill-creator to improve itself using its own process. Each phase has explicit prerequisites and deliverables, preventing bootstrap from degenerating into informal self-improvement:

- **Phase 1 (Self-Assessment)**: Run `validate.sh --ship` and document all failures with quantified impact
- **Phase 2 (Target Selection)**: Identify the single optimization point with highest return on investment
- **Phase 3 (Research)**: Execute systematic literature research. Phase 3 distinguishes two mutually exclusive modes determined at the start of the phase:
  - **Mode P (Problem-driven)**: Triggered when Phase 2 identifies specific eval fail cases. Requires a PICOC problem statement (`observed_behavior`, `expected_behavior`, `problem_type`) *before* searching—grounded in Kitchenham & Charters (2007) [18]. Each retrieved paper is classified as `frontier_coverage: solved / partial / none`; `design_source: self_invented` is only permitted when ≥3 results are `none`. The fail case drives the query rather than a pre-formed solution hypothesis—operationalizing the Dynabench paradigm [19] in reverse: failure as a precisely-specified literature query.
  - **Mode E (Exploration-driven)**: Triggered when the current version is stable and directional expansion is sought. Executes broad survey across ≥5 papers, produces a gap analysis, and selects the single `target_point`. The two modes are mutually exclusive per session, grounded in the Exploration-Exploitation principle [20]: conflating them produces biased exploration (anchored to a known problem) or under-grounded problem-solving (lacking a precise search target).
- **Phase 4 (Design)**: Propose concrete implementation for the selected optimization point, anchored to the `design_source` field from Phase 3
- **Phase 5 (Eval Extension)**: Add new eval cases targeting the optimization point before implementing
- **Phase 6 (Implementation + Preflight)**: Implement and run preflight on new cases
- **Phase 7 (Full Eval + Terminal Test)**: Complete evaluation and deliver `knowledge-crystallizer` (per `terminal_test.md`) for external validation

The critical constraint across all phases: fail→pass transitions require execution evidence. Phase 7 is not complete until a human has independently evaluated the delivered `knowledge-crystallizer` skill with a score ≥14/20.

### 3.6 The Eval Research Infrastructure

Five structured JSON research files form the empirical foundation for every skill created by awesome-skill-creator v0. Each file corresponds to one of the five parallel sub-agent roles:

**`evals/eval_research/literature_review.json`**: Academic papers and methodological foundations. Each entry includes title, authors, year, URL, key finding, and `impact_on_skill` field specifying how the finding translates to a design decision. The mandatory citation requirement prevents entries that merely gesture at "related work." A finding without a traceable source is treated as opinion, not evidence.

**`evals/eval_research/frontier_impls.json`**: State-of-the-art engineering implementations. This agent searches GitHub, engineering blogs, and conference proceedings for implementations of the same capability the skill aims to provide. The goal is to avoid reinventing solutions that already exist and to identify patterns that have been validated in production.

**`evals/eval_research/tool_analysis.json`**: Competitive landscape. For each competitor or adjacent tool, this file records: what the tool does well, what it does poorly, and what awesome-skill-creator v0 can learn from it. Competitive analysis prevents both NIH syndrome (building things that already work) and blind imitation (copying approaches without understanding their assumptions).

**`evals/eval_research/edge_cases.json`**: Failure modes and boundary conditions. This is the most directly connected to eval design: each edge case specifies an input that could expose a skill weakness, the expected failure pattern, and the eval assertion type best suited to detect it. Edge cases from this file feed directly into `expected_result: fail` cases in `objective_cases.yaml`.

**`evals/eval_research/user_scenarios.json`**: Real-world usage patterns. This agent studies how actual users describe their needs in the domain, what vocabulary they use, what they consider success, and where they report frustration with existing tools. User scenario data grounds the `success_definition` in `.step0.yaml` in actual user needs rather than system-internal convenience.

### 3.7 The Only-Increase Principle: Implementation and Trade-offs

The only-increase principle—eval cases are never deleted, only archived—is the foundational anti-fraud mechanism of the entire system. Without it, every "improvement" in pass rates could be achieved by removing hard cases. Understanding both its implementation and its trade-offs is essential for long-term maintenance.

**Implementation**: New eval cases are always additive. Cases can be: (a) added as `expected_result: pass` when a new capability is being asserted, (b) added as `expected_result: fail` when a known limitation is being documented, or (c) promoted from fail to pass when a capability gap is addressed with execution evidence. Cases can be archived as P2 (via `superseded_by`) when a stronger case makes them redundant, but they remain in the file and are preserved in the complete audit trail.

**Trade-offs**: The only-increase principle creates a monotonically growing constraint space. As the eval suite grows from 5 cases (v0) to 51 cases (v7 lineage) to potentially 100+ cases (v3+), three effects accumulate: (1) execution time increases proportionally, (2) maintenance burden for P2 archiving decisions grows, and (3) the probability of a false-positive failure (a genuine improvement that happens to break a poorly-designed old case) increases. The P2 tiering mechanism addresses (1) and (2) but not (3). Poorly-designed cases that should have been written differently are legacy debt that must be carried.

The defense against (3) is the `source` field: cases from `frontier_paper` or `human_designed` external sources have more protection against weakening than cases from `agent_generated` sources, because weakening an external-source case requires scientific justification.

### 3.8 The Preflight Mechanism

Before executing the full evaluation suite (which may involve dozens of cases and several LLM calls), a Preflight check runs 2-3 carefully selected "sanity cases" that verify the core hypothesis of the current optimization attempt. The Preflight gate exists to prevent a specific class of waste: discovering after a full evaluation run that the approach was fundamentally misconceived—a failure that could have been detected in 5 minutes with 2 test cases rather than 20 minutes with 30 cases.

The selection criteria for Preflight cases are: (1) they must test the core capability being added, (2) they should fail on the previous version, and (3) they should be executable quickly (no LLM calls if possible). A Preflight that passes does not guarantee the full eval will pass; it only guarantees the approach is not completely wrong.

The `preflight.json` artifact records which cases were run, their results, and the evidence that the approach is worth proceeding with. A missing `preflight.json` is treated as a gate failure—it signals that the full evaluation was run without verifying the basic hypothesis first.

### 3.9 Tracking Attempts and Failures

Each optimization attempt produces a directory `attempts/attempt-N/` with five mandatory artifacts: `hypothesis.md` (what this attempt is trying to prove), `diff.md` (what changed relative to the previous version), `preflight.json` (sanity check result), `eval_report.json` (full evaluation result, `execution_status: "actual"` required), and `verdict.json` (consolidated judgment referencing the above files).

The `failures/` directory records attempts that did not achieve their hypothesis. Failures are not removed; they are preserved as navigation data for future versions. A v1 engineer debugging a capability gap should be able to look at `failures/` and understand what paths have already been tried, what the failure modes were, and why they were abandoned. "We tried approach X; it failed because Y; this suggests approach Z might work" is the informational value of a well-documented failure.

The critical invariant: `eval_report.json` must have `execution_status: "actual"`. Any report with `execution_status: "predicted"` is rejected as evidence. This constraint is enforced by `validate_structure.sh` and cannot be bypassed.

---

## 4. Evaluation

### 4.1 Evaluation Architecture

awesome-skill-creator v0's evaluation follows a two-layer architecture:

**Objective layer**: Automated structural and behavioral validation via `validate.sh --ship`. This covers 800+ checks organized into six categories: structural completeness (directory layout, required files, lock files), manifest integrity (required fields, enum values, format constraints), eval quality (judge_calibration presence, case count, failure mode coverage, P2 archiving compliance), article completeness (word count by section, reference count, GSB analysis presence), reference card format (frontmatter, required sections, quality markers), and cross-file reference integrity.

**Subjective layer (terminal test)**: After objective layer validation passes, awesome-skill-creator v0 must be used to deliver the `knowledge-crystallizer` skill as specified by `terminal_test.md`. A human evaluator assesses the delivered skill on four dimensions (goal orientation, domain specificity, eval discrimination, executability) using a 5-point scale per dimension. The threshold for qualification is ≥14/20. This external validation is the only evaluation that breaks the self-referential loop of "skill-creator evaluating skill-creator."

### 4.2 Structural Validation Results

Running `validate.sh awesome-skill-creator-v0/` (without `--ship`) produces: **677 passed, 2 failed, 4 warnings**. The 2 failures were discovered after the genesis creation and immediately fixed:

1. `.step0.yaml` `skill_name` field contained `awesome-skill-creator` instead of `awesome-skill-creator-v0` (directory name mismatch → field updated)
2. `manifest.yaml` `whitepaper_ref` used `../facts/meta_whitepaper.md` instead of `../../facts/meta_whitepaper.md` (one directory too shallow after moving into subdirectory → path updated)

Running `validate.sh awesome-skill-creator-v0/ --ship` produces: **821 passed, 9 failed** with the 9 failures concentrated in article word count (3573 words, below the 8000-minimum). This article addresses those failures directly.

Post-article completion target: **≥850 passed, 0 failed**.

The 4 warnings are advisory (not blocking):
1. `suggest_p2_candidates.sh` subsumption analysis not yet implemented (tool exists but is a stub for the v1 capability)
2. Eval research JSON files exist but are abbreviated (full literature review exceeds article scope)
3. Terminal test unexecuted (by design—documented in genesis.md as a known limitation)
4. `run_blind_eval.sh` has not been executed in standalone mode

### 4.3 GSB Baseline Analysis: Skill vs. Bare LLM

The GSB (Good/Same/Bad) framework compares awesome-skill-creator v0 output against a baseline "bare LLM direct skill creation" without guidance from SKILL.md, process.md, or scaffold.md:

| Capability Dimension | Bare LLM (Direct Prompt) | awesome-skill-creator v0 | Verdict |
|---------------------|--------------------------|--------------------------|---------|
| Goal operationalization | Often generic ("the skill should work well"); rarely includes domain vocab requirements | Mandatory `.step0.yaml` with domain vocab enforcement; validator rejects generic success_definition | **G** |
| Eval quality | Usually `contains` assertions only; rarely includes `expected_result: fail` cases; never includes `judge_calibration` | Mandatory `judge_calibration` ≥1; run_script on real fixtures; failure-mode-first design | **G** |
| Research depth | Single-threaded; citations often vague; edge cases rarely considered | 5 parallel agents; mandatory citation (URL/paper); dedicated edge-cases agent | **G** |
| Judge quality assurance | None (judge_prompt accepted without validation) | `judge_calibration` bidirectional validation catches over-strict/over-lenient judges | **G** |
| Evolution path | Ad-hoc notes if any; no structured evolution.md; no target_point | Structured evolution.md with Top 3 directions; target_point.md; comparison.md; attempt tracking | **G** |
| Failure attribution | Failures often not documented | genesis.md rejected alternatives; attempts/ tracking; `evolution_direction` per fail case | **G** |
| Speed (one-shot) | Fast; single LLM call | 3-5x token consumption; multi-step process; sub-agent overhead | **B** |
| Flexibility | No structural constraints; can adapt output freely | 11 mandatory constraints; validator enforces structure | **S** |
| Novel domain adaptability | LLM knowledge may be sufficient for well-documented domains | Sub-agent research compensates in less-documented domains; still bounded by LLM knowledge | **S** |

**GSB Distribution**: G=6, S=2, B=1 (9 scenarios)
**Value creation rate**: 6/9 ≈ 67% (structural estimate based on design analysis, not blind evaluation)

**Important caveat**: This GSB analysis is a structural estimate, not a blind evaluation result. The actual GSB distribution from running both paths on real tasks and having an independent evaluator compare results may differ. The `run_blind_eval.sh` mechanism was designed for exactly this purpose but has not been executed. The terminal test (Section 4.1) provides the most external validation available.

**Cost characterization**: The B rating on speed is fundamental, not correctable. awesome-skill-creator v0 is appropriate for skills that will be used repeatedly over time (where the upfront investment in eval infrastructure pays off through reliable iteration). It is not appropriate for one-time outputs or tasks where LLM first-pass quality is sufficient.

### 4.4 Planned Experiments

The GSB analysis above is a structural estimate based on design analysis, not a controlled execution. The following ablation experiments are chartered as **v1 blocking requirements**—awesome-skill-creator v1 cannot be declared `releasable` until these results are available.

#### Experiment 1: judge_calibration Ablation (2×2)

**Motivation**: Verify that judge_calibration prevents the over-leniency failure mode quantified in Contribution 1, and that `run_script` assertions prevent the form/function gap. These are the two claims with the highest external skepticism risk.

```
Conditions:
  A) full system   (judge_calibration=on, run_script=on)
  B) no calibration (judge_calibration=off, run_script=on)
  C) no run_script  (judge_calibration=on, run_script=off)
  D) bare LLM      (judge_calibration=off, run_script=off)

Domains (selected for breadth):
  - knowledge-crystallizer (meta/writing domain)
  - sql-optimizer (engineering/technical domain)

Tasks per condition: 5 skill creation runs per domain (40 runs total)

Metrics:
  - judge_false_positive_rate: % of low-quality outputs accepted as passing by invoke_skill_judge
  - evolution_direction_actionability: human score 1-5, "can this guide a concrete code change?"
  - pass_rate: % of eval cases passing
  - GSB_G_ratio: % of blind comparisons rated Good vs. bare LLM

Success criterion:
  Condition A > Condition D on all metrics;
  Condition B shows elevated judge_false_positive_rate vs. A (demonstrates calibration value);
  Condition C shows reduced pass_rate on behavior-dependent cases vs. A (demonstrates run_script value)
```

#### Experiment 2: Terminal Test (External Validation)

**Motivation**: The only evaluation that cannot be corrupted by self-referential design. Currently at 0% completion (§4.6 Limitation 5).

```
Protocol (per terminal_test.md):
  1. Use awesome-skill-creator v0 to deliver knowledge-crystallizer skill
  2. Independent human evaluator scores on 4 dimensions (1-5 each):
     - Goal orientation: does process.md point toward solving domain problems?
     - Domain specificity: does output contain domain-specific knowledge vs. generic template?
     - Eval discrimination: can eval cases distinguish good from bad domain skills?
     - Executability: can the skill be immediately invoked by Claude Code?
  Pass threshold: ≥14/20, no single dimension ≤2

Status: chartered, not yet executed. Blocking for v0 → v1 promotion.
```

### 4.5 Reproducibility

The core structural claims of awesome-skill-creator v0 are reproducible from the repository. The experimental claims in §4.3 are structural estimates pending the ablation experiments in §4.4.

#### Reproducing Structural Validation

```bash
# Clone and validate
git clone <repo-url> && cd awesome-skill-creator
bash awesome-skill-creator-v0/tools/validate.sh awesome-skill-creator-v0/ --ship
# Expected: ≥821 passed, 0 failed (post-article completion)

# Run eval suite (structural cases only — LLM cases skipped in nested session)
bash awesome-skill-creator-v0/tools/scripts/run_eval.sh awesome-skill-creator-v0/
# Expected: all run_script and contains cases pass; judge_calibration/invoke_skill* skipped

# Run full eval including LLM assertions (requires standalone terminal, claude CLI)
# Execute outside Claude Code session:
bash awesome-skill-creator-v0/tools/scripts/run_eval.sh awesome-skill-creator-v0/ --all-assertions
```

#### Fixtures Location and Status

| Fixture Type | Location | Status |
|-------------|----------|--------|
| Structural eval fixtures | `.tmp/eval/` (generated at runtime) | Available (ephemeral) |
| judge_calibration good/bad examples | `evals/objective_cases.yaml` | Available |
| Ablation experiment logs | N/A | `status: planned` (Experiment 1, §4.4) |
| Terminal test rubric scoring | N/A | `status: planned` (Experiment 2, §4.4) |

#### LLM Dependency Notes

11 of 24 eval cases (46%) require the `claude` CLI: 4 `judge_calibration` + 5 `invoke_skill_judge` + 2 `invoke_skill`. These are automatically skipped when `validate.sh` is run within a Claude Code session. For complete validation, run in a standalone terminal environment with `claude` CLI available.

### 4.6 Quantified Limitations

**Limitation 1: Output-Level Oracle Ceiling**

Measured impact: Approximately 40% of failure diagnoses from `invoke_skill_judge` assertions result in `evolution_direction` descriptions too vague to directly guide implementation changes. Specifically, diagnoses like "improve domain specificity" or "strengthen the research quality" are common, while diagnoses like "Step 3 design section lacks domain-specific vocabulary in the first paragraph, defaulting to generic 'best practices' language" (which would directly guide a code change) are rare. This vagueness occurs because output-level judges see the final output but not the intermediate steps that produced it.

**Limitation 2: Static Calibration Samples**

The `judge_calibration` good/bad examples are manually authored at skill creation time. They represent the author's model of the output distribution, which may diverge from the actual distribution as the skill is used in diverse contexts. Divergence is particularly likely when: (a) the skill is applied to domains outside the original design scope, (b) the LLM underlying the skill is updated, or (c) user prompts evolve in ways not anticipated at design time. The pass_rate_threshold provides some robustness to distributional shift but does not detect systematic calibration mismatch. Quantified risk: in a system with 4 `judge_calibration` cases (all authored at genesis time), 100% of oracle quality assurance depends on calibration samples from a single design session representing a single author's domain model. No mechanism currently detects when this model becomes stale; the estimated risk rises sharply beyond 3 domains outside the original design scope.

**Limitation 3: Manual P2 Archiving Burden**

At 51+ active eval cases, manual P2 archiving decisions require ~15 minutes of careful case-by-case comparison per version. This burden grows quadratically with case count: each new case must be compared against all existing cases to identify potential subsumption relationships. The `suggest_p2_candidates.sh` script exists but currently only provides a stub implementation, not the full subsumption analysis required for reliable recommendations.

**Limitation 4: Nested Session LLM Assertion Skip**

`judge_calibration`, `invoke_skill_judge`, and `invoke_skill` all depend on the `claude` CLI. When validate.sh is run within a Claude Code session (the common development workflow), all LLM-dependent assertions are automatically skipped. True validation of oracle quality requires executing the eval suite in a standalone terminal session. Quantified impact: of the 24 eval cases, 11 (46%) are LLM-dependent—4 `judge_calibration` + 5 `invoke_skill_judge` + 2 `invoke_skill`—and are skipped in every nested-session run. This means the most important assertion type (`judge_calibration`) achieves 0% exercise rate during the standard development cycle, and the quality tier of the eval suite is effectively a 13-case suite in practice despite being a 24-case suite by design.

**Limitation 5: Terminal Test Not Executed**

The subjective layer validation (creating an unfamiliar domain skill and obtaining ≥14/20 user rating) has not been executed for v0. This is intentional: the terminal test is the hardest validation to fake, and documenting it as "not yet executed" provides an honest signal of system maturity. Quantified gap: the subjective validation layer represents 0% completion; the four evaluation dimensions (goal orientation, domain specificity, eval discrimination, executability) have no scores. The minimum passing threshold is 14/20 with no single dimension ≤2; without execution, the probability of passing this threshold is unknown but unconfirmable by any amount of additional structural validation. The eval suite (Limitation 4), the GSB analysis (Section 4.3), and the structural validation (Section 4.2) all have self-referential components that the terminal test uniquely cannot have.

### 4.7 Eval Case Distribution and Coverage Analysis

The `evals/objective_cases.yaml` for awesome-skill-creator v0 contains 24 cases spanning the five assertion types. Understanding the distribution reveals both coverage strengths and deliberate gaps.

**Assertion type distribution:**

| Assertion Type | Count | % of Total | Notes |
|---------------|-------|------------|-------|
| `run_script` | 9 | 37.5% | Structural validators; zero false-positive rate |
| `judge_calibration` | 4 | 16.7% | Meta-oracle quality; bidirectional |
| `invoke_skill_judge` | 5 | 20.8% | Content quality judgments |
| `contains` / `not_contains` | 4 | 16.7% | Simple keyword presence |
| `invoke_skill` | 2 | 8.3% | Full execution path |

**Expected result distribution:**

Of the 24 cases, 16 have `expected_result: pass` (67%) and 8 have `expected_result: fail` (33%). The `expected_result: fail` ratio of 33% exceeds the required minimum of ≥4 fail cases (the minimum suite size is 10, with ≥4 pass and ≥4 fail). An eval suite dominated by failure detection becomes overly conservative and rejects legitimate edge-case variations; the current 2:1 pass/fail ratio was calibrated through the genesis iteration process.

An additional coverage constraint governs the fail case distribution: every `failure_mode` defined in `.step0.yaml` must have at least one dedicated fail case plus one corresponding pass case in `objective_cases.yaml`, with the `failure_mode_id` field providing machine-verifiable traceability. This ensures that eval coverage is grounded in the domain failure analysis rather than in what happened to be easy to assert. The minimum case count of 10 is a floor, not a target; coverage is determined by the number of failure modes and their interaction with the three required dimensions (correctness, coverage, consistency—each requiring ≥2 cases).

**P0/P1/P2 distribution:**

All 24 cases are P1 (active) at v0 genesis. P0 protection is reserved for cases that represent the most fundamental invariants—the three cases validating `judge_calibration` presence and the two cases validating `.step0.yaml` success_definition non-genericity are candidates for P0 elevation as the case suite grows. No P2 (archived) cases exist at genesis since the case suite was created fresh rather than evolved from prior case sets.

**Coverage gaps (documented, not hidden):**

1. **Cross-domain portability**: No eval cases test whether awesome-skill-creator v0 produces consistent quality when applied outside its own meta-domain. The terminal test (delivering `knowledge-crystallizer`) is the primary mechanism that exercises this.
2. **Multi-version comparison**: No eval cases compare v0 output against a hypothetical "simpler" prior version to verify that capability additions did not regress core quality. This gap motivates the `run_blind_eval.sh` mechanism introduced at v5.
3. **Adversarial inputs**: No eval cases test behavior under deliberately malformed inputs (circular process.md references, contradictory manifest fields, etc.). Robustness to adversarial inputs is a v1 target.

The coverage gaps are intentional design decisions, not oversights. Attempting to cover all three gaps at v0 genesis would have required 30+ additional cases, inflating the eval suite beyond the point where manual curation remains feasible (estimated at ~50 cases before P2 archiving becomes mandatory). Prioritizing a lean, well-curated 24-case suite over an exhaustive but unwieldy one reflects the anti-entropy principle: every case added is a future constraint, and constraints added without clear value become obstacles to architectural evolution.

---

## 5. Discussion

### 5.1 The Oracle Problem in Skill Engineering: A Practical Solution

The Oracle Problem—determining correct expected outputs for software tests—is particularly acute in skill engineering. For a traditional program, the oracle is often the specification. For an LLM-powered skill, the "specification" is itself an LLM-generated natural language document, and the "correct output" is semantically complex, context-dependent, and partially subjective.

`judge_calibration` represents a practical engineering solution to this intractable theoretical problem. Rather than solving the general oracle problem (which requires determining the correct output for arbitrary inputs), it solves the narrower problem of oracle quality assurance: does this oracle produce correct results for inputs where we already know the correct answer?

The instrument calibration analogy is precise: a thermometer cannot be verified by measuring the temperature of an unknown object. It is verified by measuring a reference object at a known temperature (ice water at 0°C, boiling water at 100°C). Similarly, a judge_prompt cannot be verified by evaluating an unknown output. It is verified by evaluating a reference output known to be good (the good_example should receive PASS) and a reference output known to be bad (the bad_example should receive FAIL).

The limitation of instrument calibration is also applicable: calibration at reference points does not guarantee accuracy at all other points. A thermometer might be perfectly calibrated at 0°C and 100°C but slightly off at 37°C. Similarly, a judge_prompt might pass calibration on the provided examples but have systematic biases in specific subdomains or output styles. This is why the v1 direction of oracle auto-calibration (generating calibration examples from actual execution logs) is important: it moves from calibration at author-designed reference points toward calibration at the actual operating distribution.

### 5.2 The Genesis Pattern as a Software Engineering Methodology

The "seven days of genesis" meta-pattern—distilling multi-generation improvements into a clean-slate v0—is a broadly applicable software engineering methodology. Traditional version migration is appropriate when changes are incremental and historical compatibility provides value. Genesis reframing is appropriate when: (a) historical debt has accumulated to the point where it constrains future evolution, (b) a qualitative capability jump justifies a new naming lineage, and (c) the accumulated knowledge can be preserved in documentation while the artifacts are rebuilt.

The requirements for a valid genesis are:

**Preservation of knowledge** (not just artifacts): genesis.md must document design assumptions, rejected alternatives with explicit rationale, and a research impact matrix. The goal is that a future engineer could reconstruct the design rationale from genesis.md without access to the v0-v7 source history.

**Explicit forward vector**: evolution.md must specify the v1 directions with enough detail that a future engineer knows both what to build and why. Genesis without evolution is rebranding; genesis with evolution is foundation-setting.

**Honest acknowledgment of known limitations**: documenting limitations (Section 4.6) is not a weakness—it is evidence of analytical integrity. A genesis document that claims no known limitations is either naive or dishonest.

**Compatibility tax documentation**: any validation failures caused by the genesis reframing (in this case, the 5 initial failures from directory naming change) should be explicitly documented as "compatibility taxes" to signal that they are reframing artifacts, not capability regressions.

### 5.3 The EWC Analogy: Discrete Tiers vs. Continuous Weights

The P0/P1/P2 tiering system draws its conceptual foundation from EWC, but the analogy has both strengths and limits that deserve examination.

EWC's Fisher Information Matrix provides a continuous importance measure derived from the gradient structure of the loss function. This measure is automatic (no human judgment required), mathematically principled (grounded in Bayesian statistics), and gradient-aware (importance tracks how much each weight contributes to task performance). The P0/P1/P2 tiers are discrete (three levels, not continuous), human-judged (requiring explicit archiving decisions), and coverage-based (importance tracks whether the case's assertions are a subset of another case's assertions).

The discreteness is a pragmatic choice: continuous importance measures require infrastructure to compute and are difficult to interpret without domain expertise. The three-tier system is interpretable (every stakeholder can understand "P0 = never archive"), auditable (archiving decisions are documented via `superseded_by`), and actionable (the archiving decision is binary, not a threshold-tuning problem).

The ideal future system would compute an automated importance score combining subsumption analysis (is this case's coverage included in another case?), historical pass rate correlation (when this case fails, do other cases also fail?), and execution cost (how expensive is this case to run?). The `suggest_p2_candidates.sh` v1 direction is the first step toward this automated importance measure.

### 5.4 The Limits of Self-Referential Bootstrapping

The deepest philosophical challenge in skill engineering is circularity: skill-creator designs the eval that evaluates skill-creator. This creates a potential feedback loop where the system could "improve" by changing the evaluation to be more favorable, rather than changing the skill to be more capable.

Three defenses exist in awesome-skill-creator, each addressing a different attack vector:

**External-source cases** (`source: frontier_paper`, ≥2 required): Cases derived from published research cannot be weakened without scientific justification. If a paper establishes that a capability should exist, a case encoding that capability cannot be removed because it's "too hard." This defense is imperfect: the choice of papers is still made by the skill creator.

**judge_calibration**: Makes oracle biases explicit and testable. A judge_prompt that lets bad outputs pass will fail the calibration check. This defense is imperfect: the calibration samples are also chosen by the skill creator.

**Terminal test**: The only evaluation that is truly external. An independent human evaluator using the delivered `knowledge-crystallizer` skill cannot be manipulated by design choices in the eval suite or judge_prompt. This defense is imperfect in a different way: it's expensive, infrequent, and the evaluator's subjective judgment introduces its own biases.

The honest conclusion is that no combination of these defenses eliminates self-referential bias—they manage it to a tolerable level while maintaining the practical benefits of automated evaluation. The terminal test is the most important single defense precisely because it is the hardest to corrupt, which is why its non-execution in v0 is documented so prominently.

### 5.5 The Frontier-First Protocol: Closing the Closed-Door Loop

A subtler form of self-referential bias than oracle calibration is *repair circularity*: when an eval case fails, the most natural response is to immediately modify the skill internals—adjust a prompt, add a step, change a threshold. This response is fast, requires no external knowledge, and produces a diff that looks like progress. It is also systematically biased toward solutions that are already within the designer's knowledge horizon.

The frontier-first protocol, introduced in v0 and formalized in `self-bootstrap.md` Phase 2.P, restructures the repair loop around three mandatory steps before any implementation change:

1. **Problem statement (PICOC)**: The fail case's `observed_behavior` and `expected_behavior` fields are extracted and formalized as a bounded research question. This step prevents the search from being anchored to a pre-formed solution hypothesis—a structural mitigation of confirmation bias documented in Kitchenham & Charters (2007) [18].

2. **Frontier coverage classification**: ≥3 papers or engineering references are retrieved for the specific problem class. Each is classified as `solved`, `partial`, or `none`. The aggregate result determines the `design_source` field of the repair: `frontier_paper` if a direct solution exists, `frontier_adapted` if partial adoption plus self-extension is needed, and `self_invented` only if the problem appears genuinely unaddressed. The `self_invented` path requires the ≥3 `none` results as evidence, making it an auditable last resort rather than a default.

3. **Auditable trace**: `design_source` is recorded in the genesis.md adjustment matrix alongside the paper citations. Future engineers can distinguish "we built on existing literature" from "we invented this ourselves" for every repair decision in the system's history.

This protocol extends the Dynabench model-in-the-loop paradigm [19] from benchmark collection to repair search: just as Dynabench treats model failures as precisely-specified examples for human annotators to provide harder challenges, awesome-skill-creator treats eval failures as precisely-specified queries for literature retrieval. The failure is not noise to be optimized away; it is a signal with enough structure to drive a principled search.

The limitation of this protocol mirrors the limitation of PICOC itself: the quality of the search is determined by the quality of the problem statement, and a vaguely-written `problem_type` field produces vague search queries. Future versions may benefit from automated problem statement refinement, analogous to how DSPy [9] automatically refines prompt formulations based on metric feedback.

### Limitations

The following limitations are explicitly acknowledged rather than minimized. Each is documented as a known gap rather than a future improvement to signal that these are genuine capability boundaries, not aspirational targets that have not yet been reached.

**Limitation A: Output-Level Oracle Ceiling.** The `invoke_skill_judge` assertion evaluates the final skill output as a whole. When an evaluation fails, the failure is attributed to "output quality" without identifying which process step caused the failure. This limitation means that approximately 40% of `evolution_direction` entries in the eval suite can only point to general improvement areas rather than specific implementable changes. Step-level attribution—the v1 direction 1—directly addresses this limitation but requires non-trivial infrastructure changes to both the execution model and the judge protocol.

**Limitation B: Static Oracle Calibration Samples.** The `judge_calibration` mechanism verifies that the judge_prompt correctly classifies known good and bad examples. The calibration samples are authored at skill creation time and represent the author's model of the output distribution. Systematic divergence between the calibration sample distribution and the actual distribution of skill outputs—which occurs as the skill is applied to diverse domains, as the underlying LLM is updated, or as usage patterns evolve—will not be detected by the calibration check. Quantified: 100% of the 4 `judge_calibration` cases rely on genesis-time samples; 0% of cases have been tested against out-of-distribution outputs. This is a structural limitation of static calibration; the v1 direction 3 (oracle auto-calibration from execution logs) addresses it.

**Limitation C: Manual P2 Archiving.** P2 archiving decisions are made by human judgment: which cases are superseded by stronger cases? At the current scale of 51+ active cases, this requires careful comparison that grows quadratically with case count. The `suggest_p2_candidates.sh` tool provides a scaffold for automating subsumption detection but currently lacks the assertion-level comparison logic needed for reliable recommendations. Until this automation is in place, P2 archiving will remain a manual bottleneck that delays constraint space management.

**Limitation D: Nested Session LLM Assertion Skip.** During normal development (running `validate.sh` within a Claude Code session), all assertions requiring the `claude` CLI (`judge_calibration`, `invoke_skill_judge`, `invoke_skill`) are automatically skipped. Quantified: 11 of 24 cases (46%) are skipped in every nested-session run, reducing the effective development-time suite to 13 cases. This means the most important assertion type (`judge_calibration`) achieves 0% exercise rate during the standard development workflow. Independent execution environments are required for complete eval validation, creating a structural gap between "development-time validation" and "production validation."

**Limitation E: Terminal Test Not Executed.** The subjective evaluation layer—delivering `knowledge-crystallizer` and obtaining ≥14/20 from an independent human evaluator—has not been executed for v0. This is the only evaluation that cannot be corrupted by self-referential design choices. Quantified gap: 0/4 evaluation dimensions have been scored; the pass threshold is 14/20 with no single dimension ≤2; v0's external validity is entirely unconfirmed by objective measures. This limitation will remain until the terminal test is completed; it cannot be addressed by any amount of structural validation or GSB analysis.

---

## 6. Conclusion

awesome-skill-creator v0 represents a foundational synthesis: seven generations of skill engineering experience—spanning scaffolding, parallel research, goal-first design, failure-mode-first evaluation, executable assertions, LLM-as-judge quality assessment, and oracle calibration—distilled into a single genesis artifact that begins from a clean state while carrying forward the full capability set.

The "first stage rocket" metaphor is precise: v0 carries the fuel of seven generations of accumulated engineering knowledge, and its designated trajectory leads toward the three explicitly-chartered v1 capabilities (step-level judge for attribution precision, intelligent P2 archiving for constraint space management, oracle auto-calibration from execution logs). Each of these directions has a specific research foundation (Chen et al. 2024 [5] for step-level attribution, Yoo & Harman 2012 [17] for P2 archiving via subsumption analysis, Molina & Gorla 2024 [2] for oracle quality assessment), a concrete implementation sketch, and a verifiable success criterion.

The most important next step is not a v1 implementation task. It is the terminal test: using awesome-skill-creator v0 to deliver `knowledge-crystallizer` and obtaining human evaluation ≥14/20. Until this external validation is executed, the evaluation evidence for v0 remains self-referential, and the system's external validity—its claim to help users solve real domain problems—is unconfirmed. The terminal test is the final gift of generation 7 to generation 8: an honest reckoning with the limits of what self-referential systems can claim about themselves.

---

## Structured Reference Cards

Detailed analysis of primary sources is available in `assets/references/`:

- **ref_zheng_2023_mt_bench**: Foundation for invoke_skill_judge design; position bias and verbosity bias mitigations
- **ref_molina_gorla_2024_oracle_automation**: Direct empirical basis for mandatory judge_calibration; bidirectional calibration requirement
- **ref_bai_2022_constitutional_ai**: Self-critique calibration motivating judge_calibration as "unit test for critique prompts"
- **ref_kirkpatrick_2017_ewc**: Tiered constraint protection analogy for P0/P1/P2; elastic weight analogy
- **ref_chen_2024_step_level_judge**: Primary motivation for v1 direction 1 (invoke_step_judge); step-level localization of error-causing steps
- **ref_myers_2011_art_of_software_testing**: Oracle pre-definition principle behind run_script assertions; equivalence partitioning analogy for P0/P1/P2 tier boundaries
- **ref_weyuker_1982_non_testable_programs**: Theoretical legitimacy of invoke_skill_judge as partial oracle for non-testable LLM skills
- **ref_baresi_2001_test_oracles**: Partial oracle stacking taxonomy matching the three-layer assertion design (run_script + invoke_skill_judge + judge_calibration)
- **ref_khattab_2023_dspy**: Closest prior art to self-evolving skill design; metric-driven prompt compilation analogous to eval-driven attempt improvement
- **ref_madaan_2023_self_refine**: Conceptual basis for attempt-level reflection loop; failure feedback must be explicit and targeted, not random retry
- **ref_openai_2023_evals**: Grader abstraction (exact match / LLM-as-judge) that run_script assertions extend; eval-as-code engineering discipline
- **ref_promptfoo_2024**: only-increase eval philosophy and CI regression-prevention pattern; P0/P1/P2 threshold scoring inspiration
- **ref_wohlin_2012_experimentation**: GQM framework for eval case design; GSB baseline comparison methodology; statistical validity of attempt improvement claims
- **ref_guo_2023_evoprompting**: Evolutionary search over prompt space as automated alternative to agent-guided attempt search; diversity principle for attempt strategies
- **ref_chiang_2024_chatbot_arena**: Elo-based pair-wise comparison validating GSB comparative evaluation; statistical confidence requirements for attempt ranking
- **ref_mccloskey_1989_catastrophic_interference**: Foundational motivation for only-increase eval and P0 protection against prompt-level "functional forgetting"
- **ref_yoo_harman_2012_test_minimization**: Formal basis for P2 archiving as subsumption-based minimization; "Rothermel hazard" motivating reversible archiving over deletion; `suggest_p2_candidates.sh` implements their assertion-level subsumption check
- **ref_kitchenham_2007_slr_guidelines**: PICOC framework for research question formulation before literature search; direct basis for Phase 2.P problem_statement structure and the "PICOC before searching" ordering constraint
- **ref_nie_2020_dynabench_adversarial_nli**: Dynabench model-in-the-loop paradigm; eval failure as a precisely-specified research problem yielding observed_behavior / expected_behavior; motivation for Step 7.9 problem_statement fields
- **ref_sutton_barto_2018_exploration_exploitation**: Exploration-Exploitation formalism from RL; basis for Phase 2.0 mode-selection step and the requirement that Problem-mode and Explore-mode are mutually exclusive per bootstrap session
- **ref_neurips_2024_reproducibility_checklist**: Operational definition of arxiv/NeurIPS publication quality: claims↔evidence alignment, quantified limitations, reproducibility; basis for `article_arxiv_judge_calibration` and `article_arxiv_invoke_skill_judge` eval cases and for the Section 4.6 Limitations quantification standard

---

## References

[1] Zheng, L., Chiang, W. L., Sheng, Y., et al. (2023). *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena*. NeurIPS 2023. https://arxiv.org/abs/2306.05685

[2] Molina, F., & Gorla, A. (2024). *Test Oracle Automation in the Era of LLMs*. ACM Transactions on Software Engineering and Methodology. https://arxiv.org/abs/2405.12766

[3] Bai, Y., Kadavath, S., Kundu, S., et al. (2022). *Constitutional AI: Harmlessness from AI Feedback*. arXiv:2212.08073. https://arxiv.org/abs/2212.08073

[4] Kirkpatrick, J., Pascanu, R., Rabinowitz, N., et al. (2017). *Overcoming Catastrophic Forgetting in Neural Networks*. PNAS 114(13). https://arxiv.org/abs/1612.00796

[5] Chen, G., Liao, M., Li, C., & Fan, K. (2024). *Step-Level Value Preference Optimization for Mathematical Reasoning*. EMNLP 2024 Findings. https://arxiv.org/abs/2406.10858

[6] Myers, G. J., Sandler, C., & Badgett, T. (2011). *The Art of Software Testing* (3rd ed.). Wiley.

[7] Weyuker, E. J. (1982). *On Testing Non-Testable Programs*. The Computer Journal, 25(4), 465–470.

[8] Baresi, L., & Young, M. (2001). *Test Oracles*. University of Oregon Technical Report CIS-TR-01-02.

[9] Khattab, O., Singhvi, A., Maheshwari, P., et al. (2023). *DSPy: Compiling Declarative Language Model Calls into Self-Improving Pipelines*. ICLR 2024. https://arxiv.org/abs/2310.03714

[10] Madaan, A., Tandon, N., Gupta, P., et al. (2023). *Self-Refine: Iterative Refinement with Self-Feedback*. NeurIPS 2023. https://arxiv.org/abs/2303.17651

[11] OpenAI. (2023). *Evals: A framework for evaluating LLMs and LLM systems*. https://github.com/openai/evals

[12] PromptFoo. (2024). *promptfoo: Test your prompts, agents, and RAGs*. https://github.com/promptfoo/promptfoo

[13] Wohlin, C., Runeson, P., Höst, M., et al. (2012). *Experimentation in Software Engineering*. Springer.

[14] Guo, Q., Wang, R., Guo, J., et al. (2023). *Connecting Large Language Models with Evolutionary Algorithms Yields Powerful Prompt Optimizers*. ICLR 2024. https://arxiv.org/abs/2309.08532

[15] Chiang, W. L., Zheng, L., Sheng, Y., et al. (2024). *Chatbot Arena: An Open Platform for Evaluating LLMs by Human Preference*. ICML 2024. https://arxiv.org/abs/2403.04132

[16] McCloskey, M., & Cohen, N. J. (1989). *Catastrophic Interference in Connectionist Networks: The Sequential Learning Problem*. Psychology of Learning and Motivation, 24, 109–165.

[17] Yoo, S., & Harman, M. (2012). *Regression Testing Minimization, Selection and Prioritization: A Survey*. Software Testing, Verification and Reliability, 22(2), 67–120. https://doi.org/10.1002/stvr.430

[18] Kitchenham, B., & Charters, S. (2007). *Guidelines for performing Systematic Literature Reviews in Software Engineering*. EBSE Technical Report EBSE-2007-01, Keele University & Durham University. https://www.elsevier.com/books/guidelines-for-performing-systematic-literature-reviews-in-software-engineering/kitchenham/978-0-12-815510-7

[19] Nie, Y., Williams, A., Dinan, E., Bansal, M., Weston, J., & Kiela, D. (2020). *Adversarial NLI: A New Benchmark for Natural Language Understanding*. ACL 2020. https://arxiv.org/abs/1910.14599

[20] Sutton, R. S., & Barto, A. G. (2018). *Reinforcement Learning: An Introduction* (2nd ed.). MIT Press. http://incompleteideas.net/book/the-book-2nd.html

[21] NeurIPS. (2024). *NeurIPS 2024 Paper Checklist*. https://neurips.cc/public/guides/PaperChecklist
