# Module 2 Decision Simulator Build

## Part 25

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_24.md) · [Next](Part_26.md)

<a id="c038-m00629"></a>

### C038-M00629

**ChatGPT** · 2026-05-09T09:24:22.140588-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00629 -->
Yes — this is valuable, and I agree it should be handled **in parallel with the commentary / instructional hardening pass**, not as a separate disconnected cleanup.

The cleanest design is to add a **Module 2 campaign registry overlay**. This preserves Module 1 as authoritative, while giving Module 2 stable run IDs and validation-story IDs that can be used in the executive evidence table, validation evidence table, README, LinkedIn posts, and the future Module 2 Validation Summary.

Module 1 should remain unchanged. Its scenario lineage and matched-population design are already governed through `scenario_set_name`, `scenario_name`, and `population_id`; the BRD specifically frames those fields as the scenario comparison and traceability mechanism, while the Module 1 Validation Summary confirms that matched scenario comparison works because scenario archives preserve 50,000-row matched populations using the same `population_id`. fileciteturn10file4 fileciteturn10file5

## Recommended design

Add two persistent Module 2 registry tables:

```text
credit_decisioning_sim.strategy_run_campaign_registry
credit_decisioning_sim.strategy_comparison_campaign_registry
```

The first table describes **individual planned runs**. The second table describes **planned comparisons** between those runs.

This gives you stable identifiers such as:

```text
module1_run_id = M1-01
module2_run_id = M2-02
showcase_id = SC01
comparison_group_id = CG01
validation_evidence_group_id = VE01
```

Those IDs are then captured into Section 16 evidence tables.

## What this does and does not change

| Area | Recommendation |
|---|---|
| Module 1 SQL | Do not change |
| Module 1 archive | Do not change |
| Module 2 decision logic | Do not change |
| Module 2 reason-code logic | Do not change |
| Module 2 approved exposure / Expected Loss logic | Do not change |
| Module 2 latest-run and archive outputs | Optional; not required initially |
| Module 2 evidence tables | Yes, add registry IDs |
| Section 13 comparison setup | Yes, optionally source from comparison registry |
| Validation Summary | Yes, reference run IDs and comparison IDs |

My recommendation is **not** to add the campaign IDs to every row in `strategy_decisions` or `strategy_decisions_archive` yet. That would force Section 11 and Section 12 schema changes and broader retesting. The archive already has the true technical lineage fields. The campaign IDs are best treated as **validation / evidence metadata** stored in Section 16.

That gives you the connection you want without disturbing accepted row-level strategy outputs.

---

# 1. Run campaign registry

Recommended table:

```sql
credit_decisioning_sim.strategy_run_campaign_registry
```

Recommended grain:

```text
one row per planned Module 1 scenario × Module 2 strategy run
```

Recommended key fields:

| Field | Purpose |
|---|---|
| `module1_run_id` | Short ID for the Module 1 scenario run, for example `M1-01` |
| `module2_run_id` | Short ID for the Module 2 strategy run, for example `M2-02` |
| `run_sequence_number` | Execution order for the run campaign |
| `showcase_id` | Groups runs into a story arc, for example `SC01` |
| `showcase_name` | Human-readable showcase name |
| `comparison_group_id` | Primary comparison group, for example `CG01` |
| `validation_evidence_group_id` | Validation evidence grouping ID |
| `module1_scenario_set_name` | Exact Module 1 scenario set |
| `module1_scenario_name` | Exact Module 1 scenario |
| `population_id` | Exact Module 1 population |
| `strategy_set_name` | Exact Module 2 strategy set |
| `strategy_name` | Exact Module 2 strategy |
| `strategy_version` | Exact Module 2 strategy version |
| `module1_parameter_family_changed` | Example: `RATE_ENVIRONMENT`, `SCORE_MIX`, `PRODUCT_MIX` |
| `module1_parameter_change_summary` | Plain-English description |
| `module2_strategy_family_changed` | Example: `RISK_TIGHTENING`, `GROWTH`, `COUNTEROFFER_MANAGEMENT` |
| `module2_parameter_change_summary` | Plain-English description |
| `expected_storyline` | What the run is intended to demonstrate |
| `validation_summary_section_hint` | Where it should appear later |
| `readme_storyline_label` | Short label for README / GitHub |
| `linkedin_post_sequence` | Optional post sequence |
| `registry_active_flag` | Whether this run is active in the campaign |

This table becomes the authoritative map between:

```text
M1-01 / M2-02 / SC01 / CG01
```

and the actual technical identifiers:

```text
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0
```

---

# 2. Comparison campaign registry

Recommended table:

```sql
credit_decisioning_sim.strategy_comparison_campaign_registry
```

Recommended grain:

```text
one row per planned baseline-vs-challenger comparison
```

Recommended fields:

| Field | Purpose |
|---|---|
| `comparison_group_id` | Stable comparison ID, for example `CG01` |
| `comparison_set_name` | Human-readable comparison set |
| `showcase_id` | Story grouping |
| `baseline_module2_run_id` | Baseline run ID |
| `challenger_module2_run_id` | Challenger run ID |
| `baseline_strategy_set_name` | Exact baseline strategy set |
| `baseline_strategy_name` | Exact baseline strategy |
| `baseline_strategy_version` | Exact baseline version |
| `challenger_strategy_set_name` | Exact challenger strategy set |
| `challenger_strategy_name` | Exact challenger strategy |
| `challenger_strategy_version` | Exact challenger version |
| `module1_scenario_set_name` | Shared Module 1 scenario set |
| `module1_scenario_name` | Shared Module 1 scenario |
| `population_id` | Shared population |
| `expected_comparison_storyline` | What movement is expected |
| `primary_metric_focus` | Example: `APPROVED_EL_REDUCTION`, `OFFER_GROWTH`, `COUNTEROFFER_MANAGEMENT` |
| `active_comparison_flag` | Whether Section 13 should use this comparison |

This lets Section 13 compare by **comparison ID**, not by manually editing strategy names each time.

Example:

```text
CG01:
M2-01 BASELINE_STRATEGY
vs
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
on
M1-01 BASELINE_V2
```

That is much cleaner for the Validation Summary.

---

# 3. Section-by-section implementation plan

## Section 0 — Commentary only

Add a short explanation that Module 2 now includes an optional campaign registry layer.

Purpose:

```text
The campaign registry does not define Module 1 lineage.
The campaign registry does not define decision outcomes.
The campaign registry maps technical scenario / strategy identifiers to human-readable run IDs used for evidence capture and documentation.
```

This belongs in the teaching / instructional hardening pass.

## Section 2 — Add campaign registry setup

I recommend creating the persistent registry tables in Section 2 because Section 2 is already the parameter / control framework.

Add a subsection such as:

```text
SECTION 2.X — Campaign Registry and Validation Storyline Metadata
```

This section should:

```text
CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_campaign_registry
CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_comparison_campaign_registry
CREATE UNIQUE INDEX IF NOT EXISTS ...
```

It can also seed your planned run roadmap using `INSERT ... ON CONFLICT DO UPDATE`.

This is better than placing registry creation only in Section 16 because Section 13 and Section 16 can both use it.

## Section 3 — Add registry gatekeeper, but do not over-block development

Add a registry match diagnostic:

```text
current run key matches exactly one active campaign registry row
```

Recommended behavior:

| Condition | Behavior |
|---|---|
| Exactly one registry match | `RUN_REGISTRY_MATCHED` |
| No registry match | Allow development fallback, but flag as `RUN_REGISTRY_NOT_FOUND_FALLBACK_USED` |
| More than one registry match | Fail fast |

For the formal run campaign, we should treat `RUN_REGISTRY_MATCHED` as required. For ad hoc development, fallback is acceptable.

I would avoid hard failing on “no match” unless we add a parameter like:

```text
campaign_registry_required_flag = TRUE
```

For now, use a clear status field and make Section 16 evidence expose that status.

## Section 13 — Tie comparison setup to comparison registry

Section 13 already has a comparison selector. The permanent improvement is to make it load from:

```sql
credit_decisioning_sim.strategy_comparison_campaign_registry
```

where:

```sql
active_comparison_flag = TRUE
```

Then `tmp_m2_strategy_comparison_params` is populated from the persistent comparison registry.

This makes Section 13 outputs automatically traceable to:

```text
comparison_group_id
showcase_id
baseline_module2_run_id
challenger_module2_run_id
```

That is better than manually editing the temp comparison table.

## Section 14 — No major logic change

Section 14 should stay read-only.

However, the validation summary table can carry run IDs later through Section 16, so Section 14 does not need to know the campaign registry directly.

That preserves Section 14’s purpose: validate the latest-run strategy output.

The attached Section 14 already materializes `tmp_m2_validation_status_summary`, which Section 16 consumes for persistent evidence capture. fileciteturn10file0

## Section 15 — Minor optional enhancement

Section 15 can stay mostly unchanged.

If useful, Section 15 executive frontier output can include:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
```

But this is optional because Section 16 is the persistent evidence layer.

## Section 16 — Main evidence integration

Section 16 should be the main consumer of the campaign registry.

Update Section 16 so that:

```text
current latest-run key
→ joins strategy_run_campaign_registry
→ populates run IDs and story metadata
→ stores those IDs in all evidence tables
```

The evidence tables should store at least:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
validation_evidence_group_id
run_sequence_number
readme_storyline_label
linkedin_post_sequence
validation_summary_section_hint
run_registry_match_status
```

These should go into:

```text
strategy_run_evidence_summary
strategy_run_validation_evidence
strategy_run_parameter_snapshot
strategy_run_segment_evidence_summary
```

That gives you full traceability from the executive evidence row to the Validation Summary.

---

# 4. Evidence table updates

## `strategy_run_evidence_summary`

Add:

```text
run_sequence_number
module1_run_id
module2_run_id
showcase_id
comparison_group_id
validation_evidence_group_id
readme_storyline_label
linkedin_post_sequence
validation_summary_section_hint
run_registry_match_status
```

This becomes the main “one-row evidence story” table.

## `strategy_run_validation_evidence`

Add:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
validation_evidence_group_id
run_sequence_number
```

Then the future Validation Summary can pull validation test rows by:

```sql
WHERE validation_evidence_group_id = 'VE01'
```

or:

```sql
WHERE module2_run_id = 'M2-02'
```

## `strategy_run_parameter_snapshot`

Add:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
run_sequence_number
```

This ties parameter evidence directly to the run ID.

## `strategy_run_segment_evidence_summary`

Add:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
validation_evidence_group_id
run_sequence_number
```

This makes product × score evidence exportable by run ID.

---

# 5. How the Validation Summary will use these IDs

The future Module 2 Validation Summary should include a run inventory table like:

| Run ID | Scenario | Strategy | Purpose | Evidence group |
|---|---|---|---|---|
| `M2-01` | `M1-01 BASELINE_V2` | `BASELINE_STRATEGY` | Baseline reference | `VE01` |
| `M2-02` | `M1-01 BASELINE_V2` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Risk discipline challenger | `VE02` |

Then each validation section can reference the IDs:

```text
Run M2-02 reduced simulated offer-exposure rate by 2.51 percentage points versus M2-01.
Run M2-02 reduced total approved Expected Loss by approximately $7.26M.
Run M2-02’s largest reason-code movement was POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY.
```

That is much stronger than referencing only long scenario names.

The linkage becomes:

```text
Validation Summary claim
→ module2_run_id / comparison_group_id
→ strategy_run_evidence_summary
→ strategy_run_validation_evidence
→ strategy_run_parameter_snapshot
→ strategy_decisions_archive
```

That is an audit-ready chain.

---

# 6. Why this should be paired with commentary hardening

This is exactly the kind of enhancement that should be built during the commentary / instructional hardening pass.

The code should explain:

```text
why campaign IDs exist
why they do not replace Module 1 scenario lineage
why they do not replace Module 2 strategy metadata
why they support validation evidence and storytelling
why archive replacement keys remain unchanged
why run IDs are not matched-comparison keys
why validation claims should reference evidence IDs
```

That will make the SQL feel much more like Module 1 V2.0: not just executable, but readable as a governed strategy simulation artifact.

---

# 7. Recommended implementation order

I recommend this order:

| Step | Patch | Purpose |
|---:|---|---|
| 1 | Section 2 registry table setup | Create persistent registry objects |
| 2 | Section 3 registry match diagnostic | Detect missing or duplicate registry mappings |
| 3 | Section 13 comparison registry linkage | Let comparison IDs drive baseline / challenger selection |
| 4 | Section 16 evidence table column additions | Store run IDs in persistent evidence |
| 5 | Section 16 join to run registry | Populate evidence tables from registry |
| 6 | Commentary hardening around Sections 0, 2, 13, 16 | Explain governance and interpretation |
| 7 | Rerun baseline and tighter strategy | Backfill evidence rows with registry IDs |
| 8 | Start full scenario / strategy campaign | Every run now records executive evidence cleanly |

---

# 8. My recommendation

Proceed with this change before the full run campaign.

It is valuable because it gives you a clean evidence bridge:

```text
roadmap table
→ code output
→ archive slice
→ executive evidence row
→ validation evidence row
→ final Validation Summary narrative
```

It does not require Module 1 changes. It does not change Module 2 strategy logic. It simply makes the run campaign and future documentation much easier to govern, explain, and defend.
<!-- END_MESSAGE C038-M00629 -->


---

<a id="c038-m00630"></a>

### C038-M00630

**Andrew** · 2026-05-09T09:30:16.425000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00630 -->
I agree except commentary hardening will proceed from top to bottom of the code.  Later today, we will start this and go section by section hardening commentary and installing these code updates.  We will then re-test anything that makes sense.  Once we approve, we will start the full campaign run.
<!-- END_MESSAGE C038-M00630 -->


---

<a id="c038-m00633"></a>

### C038-M00633

**ChatGPT** · 2026-05-09T09:31:13.432462-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00633 -->
Agreed. That is the right sequence.

We should **not** start the full campaign run until the code is hardened top-to-bottom and the campaign registry / evidence ID updates are installed. The registry update is not just cosmetic; it creates the clean bridge from SQL output to Validation Summary claims.

The plan should be:

| Phase | Work | Purpose |
|---:|---|---|
| 1 | Top-to-bottom commentary hardening | Bring Module 2 to the Module 1 V2.0 instructional standard |
| 2 | Install campaign registry objects | Add stable run IDs, showcase IDs, comparison IDs, and validation evidence IDs |
| 3 | Join Section 16 evidence capture to campaign registry | Ensure executive evidence rows tie directly to run roadmap and Validation Summary |
| 4 | Link Section 13 comparison setup to comparison registry | Make baseline/challenger comparisons selectable by governed comparison IDs |
| 5 | Add / alter evidence table columns | Store IDs in summary, validation, parameter snapshot, and segment evidence tables |
| 6 | Rerun targeted tests | Confirm Section 13, Section 15, and Section 16 remain clean |
| 7 | Rerun baseline and tighter-risk evidence captures | Backfill accepted evidence rows with registry IDs |
| 8 | Start full campaign run | Execute Module 1 / Module 2 roadmap with clean evidence capture |

This matches the governance logic already established in Module 1: scenario metadata and `population_id` support controlled comparison, while validation evidence should be traceable and documentation-ready rather than reconstructed after the fact. The Module 1 BRD explicitly frames scenario metadata, archive persistence, and matched row-level comparison as core design requirements, and the Module 1 Validation Summary shows the value of matched comparison and documented validation evidence. fileciteturn10file4 fileciteturn10file5

One implementation point to remember when we install this: because the Section 16 evidence tables already exist, we should not rely only on `CREATE TABLE IF NOT EXISTS`. We will need targeted:

```sql
ALTER TABLE ... ADD COLUMN IF NOT EXISTS
```

for the new registry ID fields. Otherwise the existing evidence tables will not automatically gain the new columns.

The code updates I would expect during the hardening pass are:

| Section | Update |
|---:|---|
| Section 0 | Commentary only: explain campaign registry and evidence IDs without replacing Module 1 / Module 2 lineage |
| Section 2 | Create persistent campaign registry and comparison registry tables |
| Section 3 | Add registry match diagnostic / gatekeeper logic |
| Section 13 | Populate comparison params from comparison campaign registry |
| Section 16 | Join current run to campaign registry and persist IDs into all evidence tables |
| Section 16 | Add `ALTER TABLE ADD COLUMN IF NOT EXISTS` patches for existing evidence tables |
| Section 16 | Add diagnostics showing registry match status and evidence ID capture |

Retesting after these changes should be focused, not full revalidation from scratch:

| Test | Why |
|---|---|
| Full run through Section 16 for `BASELINE_STRATEGY` | Confirms registry IDs and baseline evidence capture |
| Full run through Section 16 for `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Confirms challenger evidence capture |
| Section 13 comparison readiness | Confirms comparison registry selects the right baseline/challenger |
| Section 15 frontier summary | Confirms strategy frontier still works with registry metadata |
| Section 16 evidence diagnostics | Confirms executive, validation, parameter, and segment evidence rows include IDs |
| Evidence table query by `module2_run_id` and `comparison_group_id` | Confirms Validation Summary traceability |

After that, the full campaign run can proceed with confidence that every run has:

```text
technical lineage
campaign ID
showcase ID
comparison group
validation evidence group
parameter snapshot
executive evidence row
segment evidence
validation evidence
```

That will make the future Module 2 Validation Summary much cleaner: every claim can reference a stable run ID or comparison ID rather than a long scenario / strategy name.
<!-- END_MESSAGE C038-M00633 -->


---

<a id="c038-m00634"></a>

### C038-M00634

**Andrew** · 2026-05-09T14:48:42.643000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00634 -->
let's begin with the commentary hardening pass + code update.  first section: as a reminder of the level of commentary/header quality we are looking for, here is module 1 V2.0 again.
<!-- END_MESSAGE C038-M00634 -->


**Attachments in export:** `Pasted text(108).txt`, `module1_synthetic_application_risk_engine_v2.0(24).sql`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00636"></a>

### C038-M00636

**ChatGPT** · 2026-05-09T14:51:30.130778-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00636 -->
The Module 1 V2.0 standard is clear: the code and artifacts should read as governed portfolio assets, not merely executable SQL. Module 1 sets that tone through an executive snapshot, explicit “what this is / is not” framing, design principles, scenario-governance language, parameter governance, and validation evidence discipline. fileciteturn10file5 The Module 1 Validation Summary also reinforces that a successful run is not the same as validated behavior; evidence, interpretation, and boundaries must be captured clearly. fileciteturn10file6

Below is the **Section 0 / global header replacement patch only**. This is commentary-only. It does not change business logic, SQL expressions, table names, thresholds, joins, archive behavior, or QA logic.

```sql
/***************************************************************************************************
MODULE 2 — CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE V1.0
Enterprise Credit Decisioning Strategy Simulator

Canonical SQL File:
    module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql

PostgreSQL Implementation

Author / Portfolio Context:
    Andrew R. Goad
    Portfolio-grade governed credit strategy simulation artifact

Primary Purpose:
    Pre-production strategy outcome simulation on synthetic applicants without exposing PII.

****************************************************************************************************/


/***************************************************************************************************
EXECUTIVE SNAPSHOT
****************************************************************************************************

WHAT THIS IS:
    Module 2 is a governed synthetic credit strategy simulation layer.

    It consumes completed Module 1 synthetic application and risk outputs, applies configurable
    Module 2 strategy parameters, assigns simulated strategy outcomes, calculates simulated approved
    exposure economics, assigns simulated strategy explanation codes, persists latest-run and archive
    outputs, and produces validation-ready diagnostics.

WHY IT MATTERS:
    Credit strategy design is not just a question of whether an applicant looks risky.

    It is a structured tradeoff among:
        growth,
        access,
        affordability,
        exposure assignment,
        synthetic estimated-risk profile,
        Expected Loss,
        operational review burden,
        product guardrails,
        and explainability.

    Module 2 makes those tradeoffs visible in a controlled, synthetic, reproducible environment.

WHAT THIS DEMONSTRATES:
    This module demonstrates:
        credit strategy architecture thinking,
        parameterized policy simulation,
        staged decision-engine design,
        exposure-treatment logic,
        reason-code transparency,
        archive-backed comparison,
        validation discipline,
        and executive-ready evidence capture.

CORE INSIGHT:
    A credit strategy outcome should not be treated as a black-box label.

    In Module 2, final simulated outcomes emerge through a transparent chain:

        Module 1 Applicant / Product / Risk Profile
        → Module 2 Strategy Parameters
        → Diagnostic Segmentation
        → Rule Trigger Flags
        → Preliminary Routing
        → Approved Exposure and Counteroffer Feasibility
        → Final Simulated Strategy Outcome
        → Simulated Strategy Explanation Codes
        → Latest-Run Output
        → Archive Persistence
        → Matched Comparison
        → QA and Evidence Capture

READER TAKEAWAY:
    This SQL file should be readable as a full-system design artifact.

    A reviewer should be able to understand:
        what the module does,
        why it is structured this way,
        how it consumes Module 1,
        what outputs are created,
        what assumptions are governed by parameters,
        what boundaries apply,
        how strategy runs are compared,
        and how validation evidence is captured.

****************************************************************************************************/


/***************************************************************************************************
SECTION 0 — EXECUTIVE PURPOSE, MODULE 2 BOUNDARIES, DESIGN PRINCIPLES, AND SQL SECTION MAP
****************************************************************************************************

PROJECT CONTEXT:
    Enterprise Credit Decisioning Strategy Simulator

COMPLETED UPSTREAM MODULE:
    Module 1 — Synthetic Application & Risk Modeling Engine V2.0

CURRENT MODULE:
    Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine V1.0

FUTURE MODULE BOUNDARY:
    Module 3 — Growth, Earnings, and Risk-Adjusted Economics Simulation
        Deferred by design.

    Module 2 captures selected growth-readiness and APR-proxy basis fields for future Module 3 use,
    but it does not calculate earnings, revenue, margin, funding cost, pricing optimization, or
    profitability.

====================================================================================================
0.1 EXECUTIVE PURPOSE
====================================================================================================

Module 2 answers the strategy-simulation question:

    "Given a completed Module 1 synthetic applicant population and a governed Module 2 strategy,
     what simulated strategy outcome does each synthetic applicant receive, what simulated exposure
     is assigned, and what strategy explanation codes describe the outcome?"

Module 2 supports:
    pre-production strategy design,
    champion / challenger comparison,
    exposure-treatment review,
    counteroffer feasibility analysis,
    simulated reason-code transparency,
    portfolio-level strategy diagnostics,
    matched archive comparison,
    and validation-summary evidence capture.

Module 2 does not answer:

    "What real decision should be made for an actual applicant?"

It is a synthetic strategy simulation engine, not an operational underwriting system.

====================================================================================================
0.2 WHAT MODULE 2 IS
====================================================================================================

Module 2 is:

    1. A governed synthetic strategy outcome simulator.
    2. A downstream strategy layer that consumes Module 1 synthetic outputs.
    3. A parameterized credit policy simulation framework.
    4. A staged decision-outcome architecture.
    5. A simulated approved-exposure and counteroffer feasibility engine.
    6. A simulated strategy explanation-code framework.
    7. A latest-run and archive persistence framework.
    8. A matched strategy comparison framework.
    9. A QA and validation evidence framework.
    10. A portfolio artifact designed for executive, technical, and validation review.

====================================================================================================
0.3 WHAT MODULE 2 IS NOT
====================================================================================================

Module 2 is not:

    1. An operational underwriting engine.
    2. A real applicant decision system.
    3. A customer communication framework.
    4. A regulatory notice framework.
    5. A fair-lending conclusion engine.
    6. A production pricing engine.
    7. A profitability model.
    8. A revenue model.
    9. A funding-cost model.
    10. A capital model.
    11. An empirically calibrated default model.
    12. An account-creation or funded-exposure process.
    13. A servicing, billing, or lifecycle performance system.

These exclusions are intentional design boundaries.

They protect the credibility of the module by keeping the implementation focused on governed synthetic
strategy simulation.

====================================================================================================
0.4 RELATIONSHIP TO MODULE 1
====================================================================================================

Module 1 creates the synthetic application and risk foundation.

Module 1 models the upstream chain:

    Application
    → Product Structure
    → APR Proxy
    → Monthly Payment Proxy
    → Requested Payment-to-Income Ratio
    → Synthetic Estimated-PD Proxy
    → LGD
    → Requested-Exposure Expected Loss

Module 2 consumes that completed Module 1 output and applies a downstream strategy layer.

Module 2 models the downstream chain:

    Module 1 Applicant / Product / Risk Profile
    → Strategy Parameters
    → Diagnostic Segmentation
    → Rule Triggers
    → Preliminary Routing
    → Approved Exposure and Counteroffer Feasibility
    → Final Simulated Outcome
    → Simulated Strategy Explanation Codes
    → Latest-Run Output
    → Archive Persistence
    → Matched Strategy Comparison
    → Validation / QA Evidence
    → Executive Story Capture

Module 2 does not rewrite Module 1.

Module 2 does not recalculate the Module 1 synthetic estimated-PD proxy.

Module 2 does not create a post-decision risk model in V1.0.

Module 2 preserves Module 1 scenario lineage through:

    module1_scenario_set_name
    module1_scenario_name
    population_id

Those fields describe the upstream synthetic population and risk environment.

Module 2 strategy metadata is kept separate through:

    strategy_set_name
    strategy_name
    strategy_version
    strategy_run_id
    strategy_run_ts

Those fields describe the downstream strategy applied to the Module 1 population.

====================================================================================================
0.5 CORE DESIGN PRINCIPLES
====================================================================================================

Module 2 follows these design principles:

1. Strategy-parameterized over hard-coded
    Strategy behavior should be changed through governed parameters before changing downstream CASE
    logic. This supports controlled strategy tuning, repeatability, and auditability.

2. Staged over monolithic
    Module 2 is built in layers:
        source staging,
        segmentation,
        rule flags,
        preliminary routing,
        exposure treatment,
        final decision resolution,
        reason-code assignment,
        output materialization,
        archive persistence,
        comparison,
        QA,
        frontier summary,
        and evidence capture.

    This makes the engine easier to validate, debug, and explain.

3. Explainable over opaque
    Every major outcome should be traceable through:
        segmentation fields,
        rule-trigger flags,
        preliminary routing,
        exposure-treatment diagnostics,
        final decision fields,
        and simulated strategy explanation codes.

4. Simulated outcomes over operational decisions
    APPROVE, COUNTEROFFER, MANUAL_REVIEW, and DECLINE are simulated strategy outcomes for synthetic
    applicants. They are not real applicant treatments.

5. Reason-code transparency over black-box routing
    Simulated reason codes are used for strategy explanation, QA, portfolio diagnostics, and
    decision-path traceability.

6. Matched comparison over population drift
    Strategy comparison should hold Module 1 scenario and population constant when isolating
    downstream Module 2 strategy effects.

7. Governed archive over ad hoc outputs
    The latest-run table is replaceable. The archive table preserves completed strategy outputs and
    enables matched comparison.

8. Diagnostics before documentation
    Validation Summary and README claims should be based on captured SQL evidence, not narrative
    assertion.

9. Evidence capture over scattered manual notes
    Section 16 persists executive story, validation evidence, parameter snapshots, and product × score
    segment evidence so future documentation can reference stable run IDs and evidence tables.

10. Modular expansion over scope creep
    Growth, earnings, funding cost, risk-adjusted margin, pricing, and profitability belong to a
    future Module 3 economics layer.

====================================================================================================
0.6 OPERATING JOB AID
====================================================================================================

Recommended user workflow:

1. Confirm Module 1 outputs exist.
    Latest-run source:
        credit_decisioning_sim.synthetic_applications

    Scenario archive source:
        credit_decisioning_sim.synthetic_applications_scenario_archive

2. Choose Module 1 input mode.
    LATEST:
        Use the current Module 1 latest-run table.

    ARCHIVE:
        Use a selected Module 1 scenario archive slice.

3. Confirm Module 2 strategy parameters.
    Review:
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

4. Confirm campaign registry mapping for formal run campaigns.
    Registry IDs such as module1_run_id, module2_run_id, showcase_id, comparison_group_id, and
    validation_evidence_group_id support later Validation Summary and README traceability.

    These IDs do not replace Module 1 scenario lineage or Module 2 strategy metadata.

5. Run Section 3 gatekeepers.
    Fail-fast parameter and source-input checks should stop malformed runs before strategy logic is
    applied.

6. Review latest-run output.
    credit_decisioning_sim.strategy_decisions is the current final simulated strategy output.

7. Archive completed runs when appropriate.
    credit_decisioning_sim.strategy_decisions_archive preserves completed strategy outputs.

8. Compare archived strategies.
    Section 13 supports matched baseline-versus-challenger strategy comparison.

9. Review QA and validation diagnostics.
    Section 14 evaluates structural integrity, decision distributions, segmentation behavior,
    affordability sensitivity, risk ordering, exposure conventions, reason-code coverage, and
    edge-case explainability.

10. Review strategy frontier.
    Section 15 summarizes archived strategy frontier tradeoffs across access, exposure, approved
    Expected Loss, affordability, and reason-code movement.

11. Capture executive evidence.
    Section 16 persists run evidence, validation evidence, parameter snapshots, and segment evidence.

12. Only then draft documentation.
    BRD, Validation Summary, README, and LinkedIn narratives should be based on captured evidence.

====================================================================================================
0.7 PARAMETER CHANGE GUIDANCE
====================================================================================================

Users should tune Module 2 by changing governed parameters first.

Preferred strategy-change workflow:

    1. Define the business question.
    2. Decide whether the question is about risk appetite, affordability, DTI capacity, exposure,
       counteroffer treatment, product guardrails, manual-review handling, or archive behavior.
    3. Modify the relevant parameter family.
    4. Preserve the Module 1 source scenario and population when isolating Module 2 strategy effects.
    5. Run the module.
    6. Review Section 14 QA and Section 15 frontier outputs.
    7. Capture Section 16 evidence.
    8. Document the observed behavior.

Avoid rewriting downstream CASE logic unless the intended behavior cannot be represented through
governed parameters.

Parameter changes should be interpreted as simulated strategy tuning, not empirical model calibration.

====================================================================================================
0.8 TESTING AND VALIDATION GUIDANCE
====================================================================================================

A successful SQL run is not the same as a validated strategy run.

A completed Module 2 run should be reviewed across multiple evidence layers:

    1. Structural integrity
        row count,
        application_id uniqueness,
        strategy lineage,
        Module 1 scenario lineage.

    2. Final outcome integrity
        one final decision_outcome per row,
        final flags reconcile,
        simulated_offer_exposure_flag aligns to APPROVE and COUNTEROFFER.

    3. Amount and economics conventions
        APPROVE preserves requested exposure,
        COUNTEROFFER reduces exposure,
        MANUAL_REVIEW remains unresolved,
        DECLINE uses zero-exposure convention.

    4. Risk and affordability behavior
        synthetic estimated-risk tiers,
        requested PTI buckets,
        DTI buckets,
        requested versus approved PTI.

    5. Counteroffer behavior
        feasibility pass / fail,
        exposure reduction,
        approved PTI target,
        approved Expected Loss cap.

    6. Reason-code coverage
        every row explainable,
        reason family aligns to final outcome,
        reason-code concentration reviewed.

    7. Archive persistence
        archived slice row count equals latest-run row count,
        archive grain is unique,
        persisted values match latest-run values.

    8. Matched comparison
        baseline and challenger share the same Module 1 scenario and population,
        application_id overlap is complete,
        source fields match,
        strategy deltas are interpretable.

    9. Frontier and evidence capture
        Section 15 summarizes strategy tradeoffs,
        Section 16 stores the executive and validation evidence needed for documentation.

====================================================================================================
0.9 TERMINOLOGY AND INTERPRETATION BOUNDARIES
====================================================================================================

estimated_pd:
    The SQL field name estimated_pd is retained because it is the finalized Module 1 output field.

    In Module 2 commentary, QA, reporting, and documentation, estimated_pd should be interpreted as
    the synthetic estimated-PD proxy.

    Module 2 V1.0 does not recalculate estimated_pd.

requested_expected_loss_amount:
    Module 2 alias for Module 1 expected_loss_amount.

    It represents requested-exposure Expected Loss.

approved_expected_loss_amount:
    Module 2 simulated approved-exposure Expected Loss after exposure treatment.

    Conceptual formula:
        approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd

    estimated_pd remains the synthetic estimated-PD proxy input.

requested_payment_to_income_ratio:
    Module 2 alias for Module 1 payment_to_income_ratio.

    It represents the original requested-structure PTI.

approved_payment_to_income_ratio:
    Module 2 post-exposure-treatment affordability proxy for simulated positive offer-exposure rows.

simulated_offer_exposure_flag:
    TRUE for:
        APPROVE
        COUNTEROFFER

    FALSE for:
        MANUAL_REVIEW
        DECLINE

    It indicates simulated positive offer exposure only.
    It does not imply operational account creation, funding, real applicant treatment, or an
    operational approval.

reason codes:
    Module 2 reason codes are simulated strategy explanation codes.

    They support:
        auditability,
        QA review,
        strategy interpretation,
        portfolio diagnostics,
        decision-path traceability,
        and validation evidence.

    They are not customer communications or regulatory notices.

MANUAL_REVIEW:
    MANUAL_REVIEW is unresolved by design.

    Manual-review rows receive:
        approved_amount = NULL
        approved_monthly_payment_proxy = NULL
        approved_payment_to_income_ratio = NULL
        approved_expected_loss_amount = NULL

DECLINE:
    DECLINE follows the zero-exposure convention.

    Decline rows receive:
        approved_amount = 0
        approved_monthly_payment_proxy = 0
        approved_payment_to_income_ratio = 0
        approved_expected_loss_amount = 0

====================================================================================================
0.10 FINAL DECISION TAXONOMY
====================================================================================================

Module 2 uses exactly four final decision_outcome values:

    APPROVE
    COUNTEROFFER
    MANUAL_REVIEW
    DECLINE

APPROVE:
    Clean simulated positive offer outcome as requested.

COUNTEROFFER:
    Simulated positive offer outcome with reduced approved exposure.
    COUNTEROFFER is distinct from APPROVE.

MANUAL_REVIEW:
    Unresolved simulated strategy outcome.
    No approved exposure or approved Expected Loss is assigned.

DECLINE:
    Simulated no-offer outcome using the zero-exposure convention.

====================================================================================================
0.11 COUNTEROFFER DESIGN BOUNDARY
====================================================================================================

COUNTEROFFER is a distinct final decision_outcome.

More detailed counteroffer interpretation is captured through:
    decision_path,
    counteroffer feasibility diagnostics,
    exposure-treatment fields,
    simulated reason codes,
    and frontier / evidence summaries.

A preliminary counteroffer route does not guarantee a final feasible counteroffer.

Final COUNTEROFFER is assigned only after approved exposure, approved PTI, and approved Expected Loss
feasibility have been evaluated.

====================================================================================================
0.12 ARCHITECTURE OVERVIEW
====================================================================================================

Latest-run table:
    credit_decisioning_sim.strategy_decisions

Archive table:
    credit_decisioning_sim.strategy_decisions_archive

Evidence tables:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

Campaign registry tables:
    credit_decisioning_sim.strategy_run_campaign_registry
    credit_decisioning_sim.strategy_comparison_campaign_registry

The latest-run table is replaceable.

The archive table preserves completed strategy runs.

The evidence tables preserve executive story, validation evidence, parameter snapshots, and segment
evidence for documentation.

The campaign registry maps technical scenario / strategy identifiers to run IDs and comparison IDs
used by the run campaign and future Validation Summary.

====================================================================================================
0.13 ARCHIVE GRAIN AND REPLACEMENT KEY
====================================================================================================

Archive grain:
    one row per application × Module 1 scenario × Module 2 strategy version

Archive grain fields:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id

Archive replacement / rerun key:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

application_id is intentionally excluded from the archive replacement key because it identifies rows
inside the replacement slice.

strategy_run_id, strategy_run_ts, latest_output_created_ts, and archive_inserted_ts are audit
metadata.

They support traceability, but they do not define matched strategy comparison grain.

====================================================================================================
0.14 CAMPAIGN REGISTRY AND VALIDATION EVIDENCE IDS
====================================================================================================

Module 2 includes a campaign registry layer to support large scenario / strategy run campaigns.

Campaign IDs may include:
    module1_run_id
    module2_run_id
    showcase_id
    comparison_group_id
    validation_evidence_group_id
    run_sequence_number
    readme_storyline_label
    linkedin_post_sequence
    validation_summary_section_hint

These IDs are documentation and evidence-linkage metadata.

They do not replace:
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    application_id.

They help connect:
    run roadmap
    → SQL output
    → archive slice
    → comparison result
    → executive evidence row
    → validation evidence row
    → parameter snapshot
    → future Validation Summary claim.

For formal campaign runs, each latest-run strategy slice should map to exactly one campaign registry
row.

If no registry mapping exists during development, Section 16 may use fallback story metadata, but
formal documentation should use registry-matched evidence rows.

====================================================================================================
0.15 PHYSICAL STAGE FLOW
====================================================================================================

Temporary parameter tables:
    tmp_module2_strategy_params
    tmp_module2_product_policy_params

Temporary stage tables:
    tmp_m2_stage_1_source_applications
    tmp_m2_stage_2_strategy_segments
    tmp_m2_stage_3_rule_flags
    tmp_m2_stage_4_preliminary_decision_routing
    tmp_m2_stage_5_exposure_treatment
    tmp_m2_stage_6_final_decision_resolution
    tmp_m2_stage_7_reason_code_assignment

Temporary comparison and validation helpers:
    tmp_m2_strategy_comparison_params
    tmp_m2_validation_status_summary
    tmp_m2_strategy_frontier_executive_summary

Permanent outputs:
    credit_decisioning_sim.strategy_decisions
    credit_decisioning_sim.strategy_decisions_archive

Permanent evidence outputs:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

====================================================================================================
0.16 SQL SECTION MAP
====================================================================================================

Section 0  — Executive Purpose, Module 2 Boundaries, Design Principles, and SQL Section Map

Section 1  — Schema Setup / Clean Rerun Reset
    Establishes schema availability, temporary-object cleanup, and clean latest-run behavior.

Section 2  — Strategy Parameter, Product Policy, and Campaign Registry Framework
    Defines active strategy parameters, product-policy parameters, and run / comparison registry
    metadata used for campaign evidence traceability.

Section 3  — Fail-Fast Strategy Parameter Gatekeeper
    Validates parameter cardinality, threshold ordering, source input readiness, product policy
    configuration, archive controls, output conventions, and registry consistency diagnostics.

Section 4  — Module 1 Source Selection and Lineage Normalization
    Consumes Module 1 latest-run or archive output, normalizes Module 1 lineage fields, preserves
    Module 2 strategy metadata, and creates the source staging layer.

Section 5  — Derived Strategy Segmentation Layer
    Adds diagnostic segmentation fields such as synthetic risk tier, requested PTI bucket, DTI bucket,
    requested exposure tier, requested Expected Loss tier, product × score segment, mixed-signal
    profile, and borderline profile flag.

Section 6  — Rule Flag Construction Layer
    Converts segmentation and source inputs into non-final rule-trigger flags across hard simulated
    policy stops, synthetic risk, affordability, DTI, requested Expected Loss, exposure,
    counteroffer candidates, manual-review candidates, supplemental behavior, and clean approval
    diagnostics.

Section 7  — Preliminary Decision Routing Layer
    Converts overlapping rule flags into one preliminary route without assigning final outcomes.

Section 8  — Approved Exposure and Counteroffer Feasibility Layer
    Calculates preliminary approved exposure, counteroffer feasibility, approved payment proxy,
    approved PTI proxy, and approved Expected Loss for exposure-treatment evaluation.

Section 9  — Final Decision Resolution Layer
    Resolves final simulated decision_outcome, decision_path, flags, approved exposure, approved
    payment proxy, approved PTI proxy, and approved Expected Loss.

Section 10 — Simulated Reason-Code Assignment Layer
    Assigns deterministic simulated strategy explanation codes using a candidate → rank → pivot
    pattern.

Section 11 — Latest-Run Strategy Decision Output Table
    Materializes credit_decisioning_sim.strategy_decisions using an explicit output-field list.

Section 12 — Strategy Decision Archive Persistence Layer
    Persists completed latest-run outputs into credit_decisioning_sim.strategy_decisions_archive using
    governed archive controls and archive-grain validation.

Section 13 — Archive Inventory and Matched Strategy Comparison Framework
    Provides read-only archive inventory, comparison readiness, matched baseline / challenger
    strategy comparison, migration analysis, reason-code movement, and source-field consistency
    diagnostics.

Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics
    Provides read-only latest-run validation queries and materializes tmp_m2_validation_status_summary
    for evidence capture.

Section 15 — Strategy Frontier Summary and Executive Comparison View
    Summarizes archived strategy frontiers across simulated offer exposure, approved amount,
    approved Expected Loss, affordability, synthetic estimated-risk profile, reason-code movement,
    segment drivers, and executive frontier classification.

Section 16 — Strategy Run Evidence Capture and Executive Story Register
    Persists one-row executive evidence summaries, validation evidence, parameter snapshots, and
    product × score segment evidence for each completed strategy run.

====================================================================================================
0.17 PORTFOLIO ARTIFACT VALUE
====================================================================================================

This script is intended to function as more than SQL.

It is a portfolio-grade system design artifact demonstrating:

    governed strategy-parameter design,
    staged simulation architecture,
    source lineage discipline,
    archive and comparison architecture,
    validation evidence construction,
    executive story capture,
    modular expansion planning,
    and boundary-aware communication.

A reviewer should be able to read the comments and understand not only what the code executes, but
why the system is structured this way and how to interpret the outputs responsibly.

***************************************************************************************************/
```

Recommended next patch chunk: **Section 1** commentary hardening, followed immediately by **Section 2** where we install the persistent campaign registry and comparison registry tables.
<!-- END_MESSAGE C038-M00636 -->


---

<a id="c038-m00638"></a>

### C038-M00638

**Andrew** · 2026-05-09T14:58:54.125000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00638 -->
section 1 now: /***************************************************************************************************
SECTION 1 — SCHEMA SETUP / CLEAN RERUN RESET
****************************************************************************************************

BUSINESS PURPOSE:
    Establish the dedicated simulation schema and reset transient Module 2 execution objects so the
    current run starts cleanly.

SQL PURPOSE:
    1. Create the simulation schema if it does not already exist.
    2. Set the search path for review convenience.
    3. Drop temporary Module 2 parameter and staging objects from prior executions.
    4. Drop the latest-run strategy output table for clean rerun behavior.
    5. Do not drop the strategy archive table.

WHY THE LATEST-RUN TABLE MAY BE DROPPED:
    credit_decisioning_sim.strategy_decisions represents the current completed Module 2 run only.

    It is replaced each run so latest-run QA and reporting are not silently mixed with prior
    strategy outputs.

WHY THE ARCHIVE TABLE IS NOT DROPPED HERE:
    credit_decisioning_sim.strategy_decisions_archive is the governed history layer.

    Archive persistence and archive reset behavior are controlled later by Section 12 using:
        archive_run_flag
        strategy_archive_reset_mode

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
1.1 Create / reuse dedicated simulation schema.
-----------------------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;


/*-----------------------------------------------------------------------------------------------
1.2 Clean reset of temporary Module 2 objects.

Temporary objects are safe to drop on rerun because they are execution staging artifacts.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_module2_strategy_params;
DROP TABLE IF EXISTS tmp_module2_product_policy_params;

DROP TABLE IF EXISTS tmp_m2_stage_1_source_applications;
DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;
DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;
DROP TABLE IF EXISTS tmp_m2_stage_4_preliminary_decision_routing;
DROP TABLE IF EXISTS tmp_m2_stage_5_exposure_treatment;
DROP TABLE IF EXISTS tmp_m2_stage_6_final_decision_resolution;
DROP TABLE IF EXISTS tmp_m2_stage_7_reason_code_assignment;

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;


/*-----------------------------------------------------------------------------------------------
1.3 Clean reset of latest-run output table.

This intentionally does not drop:
    credit_decisioning_sim.strategy_decisions_archive
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;
<!-- END_MESSAGE C038-M00638 -->


---

<a id="c038-m00640"></a>

### C038-M00640

**ChatGPT** · 2026-05-09T15:00:32.432295-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00640 -->
Section 1 should be hardened as a **clean-run control section**, not just a schema setup block. The main code update is to reset the newer Section 15 / Section 16 temporary evidence and frontier objects while **not** dropping archive, evidence, or registry permanent tables. This follows the Module 1 V2.0 pattern of making execution controls explicit, governed, and reviewer-readable rather than relying on implicit script behavior. fileciteturn10file5

```sql
/***************************************************************************************************
SECTION 1 — SCHEMA SETUP / CLEAN RERUN RESET
****************************************************************************************************

BUSINESS PURPOSE:
    Establish the dedicated simulation schema and reset transient Module 2 execution objects so a
    full Module 2 run starts from a clean, interpretable state.

    Section 1 answers:

        "What execution artifacts should be cleared before a new full Module 2 strategy run begins,
         and what governed history should be preserved?"

SQL PURPOSE:
    1. Create or reuse the dedicated simulation schema.
    2. Set the search path for convenient object resolution.
    3. Drop temporary Module 2 parameter, staging, comparison, validation, frontier, and evidence
       helper objects from prior executions.
    4. Drop the replaceable latest-run strategy output table for clean rerun behavior.
    5. Preserve the governed archive, campaign registry, and evidence history tables.

INPUTS:
    None required.

OUTPUTS:
    credit_decisioning_sim schema exists.
    Prior temporary Module 2 execution objects are removed.
    credit_decisioning_sim.strategy_decisions is removed so the current run can rebuild it.
    credit_decisioning_sim.strategy_decisions_archive is preserved.
    Persistent evidence and campaign registry tables are preserved.

WHY THIS SECTION EXISTS:
    Module 2 is intentionally staged.

    A prior failed run, partial run, or exploratory run can leave temporary objects in the active
    session. Those temporary objects should not silently influence the next full strategy execution.

    Section 1 therefore resets transient execution artifacts before the parameter framework,
    source-selection layer, decision stages, QA layers, frontier summary, and evidence capture are
    rebuilt.

WHY THE LATEST-RUN TABLE MAY BE DROPPED:
    credit_decisioning_sim.strategy_decisions represents the current completed Module 2 strategy run
    only.

    It is not the history table.
    It is not the comparison archive.
    It is intentionally replaceable.

    Dropping and recreating the latest-run table prevents current-run QA, Section 14 validation, and
    Section 16 evidence capture from accidentally mixing the current strategy output with a prior
    latest-run strategy output.

WHY THE ARCHIVE TABLE IS NOT DROPPED HERE:
    credit_decisioning_sim.strategy_decisions_archive is the governed historical persistence layer.

    Archive behavior is controlled later in Section 12 through:
        archive_run_flag
        strategy_archive_reset_mode

    The archive should never be dropped during ordinary clean rerun setup.

WHY EVIDENCE AND REGISTRY TABLES ARE NOT DROPPED HERE:
    The campaign registry and Section 16 evidence tables support run-roadmap traceability,
    validation-summary linkage, parameter snapshots, executive story capture, and product × score
    evidence.

    They are persistent governance artifacts, not transient execution staging tables.

    Section 16 handles evidence replacement at the current run key. Section 1 should not destroy
    historical evidence or campaign registry metadata.

OPERATING GUIDANCE:
    Run Section 1 when executing the full Module 2 engine from the beginning.

    Do not run Section 1 by itself if the goal is only to refresh Section 15 frontier outputs or
    Section 16 evidence capture from an already-materialized latest-run table. Section 1 drops
    credit_decisioning_sim.strategy_decisions, so an evidence-only refresh should start after the
    latest-run output has already been materialized.

BOUNDARY:
    Section 1 does not create strategy parameters.
    Section 1 does not select Module 1 source data.
    Section 1 does not calculate strategy segments.
    Section 1 does not assign rule flags.
    Section 1 does not route decisions.
    Section 1 does not calculate approved exposure.
    Section 1 does not assign final decision_outcome.
    Section 1 does not assign simulated reason codes.
    Section 1 does not insert archive rows.
    Section 1 does not perform matched comparison.
    Section 1 does not validate strategy outcomes.

GOVERNANCE ROLE:
    This section supports reproducibility by making clean-rerun behavior explicit.

    It also protects the distinction between:
        transient execution objects,
        replaceable latest-run output,
        governed archive history,
        persistent evidence capture,
        and campaign registry metadata.

COMMON MISUSE TO AVOID:
    Do not interpret dropped temporary objects as lost evidence.
    Temporary stage tables are execution artifacts and can be regenerated.

    Do not drop the archive table for ordinary reruns.
    Use Section 12 archive controls instead.

    Do not drop evidence tables or campaign registry tables as part of ordinary strategy execution.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
1.1 Create / reuse dedicated simulation schema.

Business purpose:
    Keep Module 2 outputs, archives, registry tables, and evidence tables organized under one
    governed simulation schema.

SQL purpose:
    Ensure the schema exists before any temporary or permanent Module 2 objects are referenced.

Interpretation:
    CREATE SCHEMA IF NOT EXISTS is non-destructive. It creates the schema only if needed and reuses it
    if it already exists.
-----------------------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;



/*-----------------------------------------------------------------------------------------------
1.2 Clean reset of temporary Module 2 parameter objects.

Business purpose:
    Prevent stale parameter cards from prior runs from influencing the current strategy run.

Why this matters:
    Module 2 is parameter-driven. If an old temporary strategy row or product-policy row remains in
    the session, the engine could appear to run successfully while using the wrong strategy
    configuration.

Boundary:
    These are temporary parameter staging objects only. Persistent campaign registry and evidence
    tables are not dropped here.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_module2_strategy_params;
DROP TABLE IF EXISTS tmp_module2_product_policy_params;



/*-----------------------------------------------------------------------------------------------
1.3 Clean reset of temporary Module 2 decision-stage objects.

Business purpose:
    Remove prior staged execution layers before rebuilding the full strategy pipeline.

Stage interpretation:
    tmp_m2_stage_1_source_applications:
        normalized Module 1 source input and lineage layer.

    tmp_m2_stage_2_strategy_segments:
        non-decisioning segmentation layer.

    tmp_m2_stage_3_rule_flags:
        deterministic rule-trigger layer.

    tmp_m2_stage_4_preliminary_decision_routing:
        preliminary route assignment layer.

    tmp_m2_stage_5_exposure_treatment:
        approved exposure and counteroffer feasibility layer.

    tmp_m2_stage_6_final_decision_resolution:
        final simulated strategy outcome layer.

    tmp_m2_stage_7_reason_code_assignment:
        simulated strategy explanation-code layer.

Why this matters:
    Each stage depends on the prior stage. Removing prior-stage artifacts prevents downstream logic
    from reading stale data if a rerun stops and restarts mid-script.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_stage_1_source_applications;
DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;
DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;
DROP TABLE IF EXISTS tmp_m2_stage_4_preliminary_decision_routing;
DROP TABLE IF EXISTS tmp_m2_stage_5_exposure_treatment;
DROP TABLE IF EXISTS tmp_m2_stage_6_final_decision_resolution;
DROP TABLE IF EXISTS tmp_m2_stage_7_reason_code_assignment;



/*-----------------------------------------------------------------------------------------------
1.4 Clean reset of temporary archive, comparison, validation, and frontier helper objects.

Business purpose:
    Remove prior diagnostic helper objects so archive diagnostics, matched comparison, validation
    status, and frontier summaries are rebuilt from the current run and current archive state.

Boundary:
    These temporary helper objects are not the governed archive itself.
    These temporary helper objects are not persistent evidence history.

    Section 12 controls archive persistence.
    Section 13 controls read-only matched comparison.
    Section 14 materializes validation status summary.
    Section 15 materializes strategy frontier summaries.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_registry;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_baseline_deltas;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_efficiency;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_classification;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_segment_highlights;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_executive_summary;



/*-----------------------------------------------------------------------------------------------
1.5 Clean reset of temporary Section 16 evidence-capture helper objects.

Business purpose:
    Remove prior evidence-capture helper objects while preserving persistent evidence tables.

Why this matters:
    Section 16 uses temporary helper objects to identify the current run key and current run-story
    metadata before inserting persistent evidence rows.

    Those temporary objects should be regenerated for each full run.

Boundary:
    This reset does not drop:
        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

    Those are persistent evidence tables and should remain available across the campaign run series.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_current_run_key;
DROP TABLE IF EXISTS tmp_m2_current_run_story_params;
DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;
DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;



/*-----------------------------------------------------------------------------------------------
1.6 Clean reset of latest-run output table.

Business purpose:
    Clear the replaceable current-run output before the engine rebuilds it in Section 11.

Interpretation:
    credit_decisioning_sim.strategy_decisions is the current latest-run strategy output only.

    It is deliberately replaced each full run.

This intentionally does not drop:
    credit_decisioning_sim.strategy_decisions_archive
    credit_decisioning_sim.strategy_run_campaign_registry
    credit_decisioning_sim.strategy_comparison_campaign_registry
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

Testing relevance:
    After a full run, Section 11 should recreate credit_decisioning_sim.strategy_decisions and
    Section 14 should validate it.

    If a user wants to rerun only Section 15 / Section 16 from an existing latest-run table, this
    Section 1 latest-run reset should not be executed first.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;
```
<!-- END_MESSAGE C038-M00640 -->


---

<a id="c038-m00642"></a>

### C038-M00642

**Andrew** · 2026-05-09T15:14:58.643000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00642 -->
section 2:
<!-- END_MESSAGE C038-M00642 -->


**Attachments in export:** `Pasted text(109).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00648"></a>

### C038-M00648

**ChatGPT** · 2026-05-09T15:20:58.690071-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00648 -->
Below is the hardened **Section 2 replacement**. It preserves your accepted strategy/product parameter framework and adds the persistent Module 2 campaign registry and comparison registry objects needed to tie SQL outputs to run IDs, comparison groups, and future validation-summary references. fileciteturn10file0

```sql
/***************************************************************************************************
SECTION 2 — STRATEGY PARAMETER, PRODUCT POLICY, AND CAMPAIGN REGISTRY FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize all Module 2 strategy assumptions, threshold settings, source-selection controls,
    archive controls, product policy limits, counteroffer settings, decision conventions, rule
    controls, and formal run-campaign metadata.

    Section 2 answers:

        "What governed assumptions, strategy controls, product-policy settings, and campaign
         identifiers should the current Module 2 run use?"

SQL PURPOSE:
    1. Create tmp_module2_strategy_params with exactly one active strategy row.
    2. Create tmp_module2_product_policy_params with exactly one row per supported product.
    3. Store all strategy defaults as governed simulation parameters.
    4. Avoid hidden hardcoded thresholds in downstream decision logic.
    5. Create persistent campaign registry tables that map technical scenario / strategy identifiers
       to human-readable run IDs and validation-story groupings.
    6. Create persistent comparison registry tables that support governed baseline / challenger
       strategy comparison by comparison_group_id.
    7. Seed the current planned Module 2 campaign roadmap so later validation evidence can tie SQL
       outputs back to stable run IDs.

PARAMETER GOVERNANCE PRINCIPLE:
    Downstream CASE logic should consume strategy and product parameters rather than silently
    embedding ungoverned thresholds.

    Users should tune Module 2 first through:
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

    before rewriting downstream decision, routing, exposure, or reason-code logic.

CAMPAIGN REGISTRY GOVERNANCE PRINCIPLE:
    Module 1 scenario lineage and Module 2 strategy metadata remain the technical source of truth.

    Campaign IDs such as:
        module1_run_id
        module2_run_id
        showcase_id
        comparison_group_id
        validation_evidence_group_id

    are documentation and evidence-linkage metadata.

    They do not replace:
        module1_scenario_set_name
        module1_scenario_name
        population_id
        strategy_set_name
        strategy_name
        strategy_version
        application_id

    They help connect:
        run roadmap
        → SQL output
        → archive slice
        → comparison result
        → executive evidence row
        → validation evidence row
        → parameter snapshot
        → future Validation Summary claim.

DEFAULT THRESHOLD INTERPRETATION:
    Defaults in this section are initial synthetic strategy defaults.

    They are:
        intended for strategy simulation,
        expected to be reviewed through QA and strategy tuning,
        not production underwriting policy,
        not empirical calibration,
        not a calibrated default model,
        not regulatory policy,
        not real customer treatment logic.

OPERATING GUIDANCE:
    For a formal campaign run:
        1. Confirm the Module 1 source scenario fields.
        2. Confirm the Module 2 strategy identity.
        3. Confirm the current strategy exists in credit_decisioning_sim.strategy_run_campaign_registry.
        4. Confirm any intended Section 13 comparison exists in
           credit_decisioning_sim.strategy_comparison_campaign_registry.
        5. Run Section 3 gatekeepers before building downstream strategy logic.

    For ad hoc development:
        campaign_registry_required_flag may be set to FALSE, but formal validation evidence should
        use registry-matched runs.

BOUNDARY:
    Section 2 defines governed controls and campaign metadata.
    Section 2 does not consume Module 1 rows.
    Section 2 does not create decision outcomes.
    Section 2 does not assign reason codes.
    Section 2 does not calculate approved exposure.
    Section 2 does not calculate approved Expected Loss.
    Section 2 does not insert archive rows.
    Section 2 does not perform matched comparison.
    Section 2 does not perform QA validation.

***************************************************************************************************/



/***************************************************************************************************
SECTION 2.1 — STRATEGY PARAMETER TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Define the single active Module 2 strategy configuration for the current run.

SQL PURPOSE:
    Create a temporary parameter table containing strategy identity, source selection, archive
    controls, thresholds, rule controls, decision conventions, and registry requirements.

WHY THIS TABLE EXISTS:
    Module 2 should be strategy-parameterized rather than hard-coded.

    The same downstream SQL pipeline can simulate different strategies by changing this parameter row
    and product-policy parameter rows.

CARDINALITY REQUIREMENT:
    Exactly one row should have:
        active_strategy_flag = TRUE

    Section 3 enforces this.

****************************************************************************************************/

CREATE TEMP TABLE tmp_module2_strategy_params (
    /***********************************************************************************************
    Active strategy cardinality
    ***********************************************************************************************/
    active_strategy_flag                         BOOLEAN,

    /***********************************************************************************************
    Strategy identity
    ***********************************************************************************************/
    module2_model_version                        TEXT,
    strategy_set_name                            TEXT,
    strategy_name                                TEXT,
    strategy_version                             TEXT,
    strategy_run_id                              TEXT,
    strategy_run_ts                              TIMESTAMP,

    /***********************************************************************************************
    Formal campaign registry control

    campaign_registry_required_flag:
        TRUE means the current technical run key should match exactly one active row in
        credit_decisioning_sim.strategy_run_campaign_registry.

        FALSE allows ad hoc development runs to proceed with fallback evidence metadata.

    This flag does not affect decision logic.
    It only governs evidence traceability expectations.
    ***********************************************************************************************/
    campaign_registry_required_flag              BOOLEAN,

    /***********************************************************************************************
    Module 1 source selection
    ***********************************************************************************************/
    module1_input_source                         TEXT,
    source_module1_scenario_set_name             TEXT,
    source_module1_scenario_name                 TEXT,
    source_population_id                         TEXT,

    /***********************************************************************************************
    Archive controls
    ***********************************************************************************************/
    archive_run_flag                             BOOLEAN,
    strategy_archive_reset_mode                  TEXT,

    /***********************************************************************************************
    Global estimated-risk thresholds

    estimated_pd is the finalized Module 1 SQL field name.

    These thresholds interpret estimated_pd as the synthetic estimated-PD proxy.
    ***********************************************************************************************/
    approve_max_estimated_pd_proxy               NUMERIC(12,6),
    counteroffer_max_estimated_pd_proxy          NUMERIC(12,6),
    review_max_estimated_pd_proxy                NUMERIC(12,6),
    decline_min_estimated_pd_proxy               NUMERIC(12,6),

    /***********************************************************************************************
    Global PTI thresholds

    Product-specific PTI thresholds drive product PTI segmentation and rules.
    These global values provide high-level consistency controls and fallback context.
    ***********************************************************************************************/
    global_approve_max_pti                       NUMERIC(12,6),
    global_review_max_pti                        NUMERIC(12,6),
    global_decline_min_pti                       NUMERIC(12,6),

    /***********************************************************************************************
    DTI thresholds

    DTI is an existing-obligation capacity signal.
    In Module 2 V1.0, DTI is not directly corrected through counteroffer exposure reduction.
    ***********************************************************************************************/
    approve_max_dti                              NUMERIC(12,6),
    review_max_dti                               NUMERIC(12,6),
    decline_min_dti                              NUMERIC(12,6),

    /***********************************************************************************************
    Diagnostic segmentation controls
    ***********************************************************************************************/
    borderline_threshold_buffer_pct              NUMERIC(12,6),

    /*
    borderline_threshold_buffer_pct:
        Governs how close a value must be to a strategy threshold to be tagged as borderline.

        Example:
            0.050000 means "within 5% of the threshold value."

        This is not a production policy tolerance.
        This is a diagnostic segmentation buffer used only to identify threshold-adjacent
        synthetic profiles before decision rules are applied.
    */

    /***********************************************************************************************
    Rule-control parameters for Section 6 trigger construction
    ***********************************************************************************************/
    bankruptcy_policy_stop_enabled               BOOLEAN,
    major_derogatory_policy_stop_enabled         BOOLEAN,
    severe_delinquency_policy_stop_enabled       BOOLEAN,
    severe_delinquency_count_threshold           INTEGER,
    high_utilization_review_enabled              BOOLEAN,
    high_utilization_review_threshold            NUMERIC(12,6),
    low_score_review_enabled                     BOOLEAN,
    low_score_review_threshold                   INTEGER,

    /*
    Rule-control interpretation:
        These parameters control simulated trigger flags only.

        They do not assign final decision_outcome.
        They do not create reason codes.
        They do not represent production underwriting policy.

        Section 6 uses them to answer:
            "Which simulated policy conditions are triggered?"

        Later sections answer:
            "Which final simulated strategy outcome is assigned?"
    */

    /***********************************************************************************************
    Decision convention controls
    ***********************************************************************************************/
    approve_reason_code                          TEXT,
    reason_code_required_flag                    BOOLEAN,
    simulated_offer_exposure_flag_enabled        BOOLEAN,
    manual_review_approved_amount_convention     TEXT,
    decline_approved_amount_convention           TEXT,
    approved_el_decline_convention               TEXT,
    approved_el_manual_review_convention         TEXT,
    allow_approved_amount_above_requested_flag   BOOLEAN,

    /***********************************************************************************************
    Final decision-resolution control
    ***********************************************************************************************/
    failed_counteroffer_resolution               TEXT

    /*
    failed_counteroffer_resolution:
        Governs how preliminary COUNTEROFFER routes resolve when Section 8 determines that no
        viable reduced-exposure treatment exists.

    Allowed values:
        MANUAL_REVIEW
        DECLINE

    Default:
        MANUAL_REVIEW

    Interpretation:
        A failed counteroffer is routed to MANUAL_REVIEW by default because higher-priority hard
        simulated policy stops, severe synthetic estimated-risk, and severe DTI have already routed
        to DECLINE before counteroffer feasibility is evaluated.

    Boundary:
        This is a simulated strategy-control parameter, not production underwriting policy.
    */
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 2.2 — INSERT ACTIVE STRATEGY PARAMETER ROW
****************************************************************************************************

PURPOSE:
    Insert the current active Module 2 strategy configuration.

USER ACTION:
    This default row is intentionally editable.

    For a governed strategy test, users should update:
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        module1_input_source,
        source Module 1 scenario fields when using ARCHIVE,
        strategy thresholds,
        product policy table values,
        archive controls,
        campaign_registry_required_flag.

CURRENT DEFAULT:
    The default row below is aligned to the currently tested TIGHTER_SYNTHETIC_RISK_STRATEGY on the
    Module 1 BASELINE_V2 archive slice.

    To rerun the baseline strategy for evidence backfill, change:
        strategy_name
        strategy_run_id
        synthetic estimated-risk thresholds
        and any other strategy-specific settings
    back to the baseline strategy values.

AUDIT METADATA NOTE:
    strategy_run_id and strategy_run_ts support traceability.
    They do not replace the archive replacement / rerun key.

****************************************************************************************************/

INSERT INTO tmp_module2_strategy_params (
    active_strategy_flag,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    campaign_registry_required_flag,

    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,

    archive_run_flag,
    strategy_archive_reset_mode,

    approve_max_estimated_pd_proxy,
    counteroffer_max_estimated_pd_proxy,
    review_max_estimated_pd_proxy,
    decline_min_estimated_pd_proxy,

    global_approve_max_pti,
    global_review_max_pti,
    global_decline_min_pti,

    approve_max_dti,
    review_max_dti,
    decline_min_dti,

    borderline_threshold_buffer_pct,

    bankruptcy_policy_stop_enabled,
    major_derogatory_policy_stop_enabled,
    severe_delinquency_policy_stop_enabled,
    severe_delinquency_count_threshold,
    high_utilization_review_enabled,
    high_utilization_review_threshold,
    low_score_review_enabled,
    low_score_review_threshold,

    approve_reason_code,
    reason_code_required_flag,
    simulated_offer_exposure_flag_enabled,
    manual_review_approved_amount_convention,
    decline_approved_amount_convention,
    approved_el_decline_convention,
    approved_el_manual_review_convention,
    allow_approved_amount_above_requested_flag,

    failed_counteroffer_resolution
)
VALUES (
    TRUE,

    'MODULE2_V1_0',
    'MODULE2_BASELINE_STRATEGY_SET',
    'TIGHTER_SYNTHETIC_RISK_STRATEGY',
    'V1_0',
    'M2-02_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN',
    CURRENT_TIMESTAMP,

    TRUE,

    /*
    Module 1 source selection.

    LATEST:
        Consumes credit_decisioning_sim.synthetic_applications.

    ARCHIVE:
        Consumes a selected slice of credit_decisioning_sim.synthetic_applications_scenario_archive.
        When ARCHIVE is used, source_module1_scenario_set_name, source_module1_scenario_name, and
        source_population_id must be populated.
    */
    'ARCHIVE',
    'MODULE1_V2_BASELINE_SET',
    'BASELINE_V2',
    'BASE_POPULATION_V1',

    /*
    Archive controls.

    STRATEGY_SCENARIO_ONLY is the ordinary rerun mode:
        replace only the current strategy / Module 1 scenario / population slice.
    */
    TRUE,
    'STRATEGY_SCENARIO_ONLY',

    /*
    Global synthetic estimated-PD proxy thresholds.

    Equality convention:
        APPROVE eligibility:
            estimated_pd <= approve_max_estimated_pd_proxy

        COUNTEROFFER risk band:
            estimated_pd > approve_max_estimated_pd_proxy
            AND estimated_pd <= counteroffer_max_estimated_pd_proxy

        MANUAL_REVIEW risk band:
            estimated_pd > counteroffer_max_estimated_pd_proxy
            AND estimated_pd < decline_min_estimated_pd_proxy

        DECLINE trigger:
            estimated_pd >= decline_min_estimated_pd_proxy

    These values are synthetic strategy defaults for the tighter synthetic-risk challenger,
    not production cutoffs.
    */
    0.060000,
    0.120000,
    0.250000,
    0.300000,

    /*
    Global PTI thresholds.

    Product-specific PTI thresholds are used for product-aware affordability rules.
    These global thresholds provide high-level strategy governance.
    */
    0.250000,
    0.400000,
    0.550000,

    /*
    DTI thresholds.

    DTI is an existing-obligation capacity signal.
    */
    0.430000,
    0.600000,
    0.600000,

    /*
    Borderline diagnostic buffer.

    0.050000 means downstream segmentation tags a profile as threshold-adjacent when a value is
    within 5% of a relevant strategy threshold.

    This is a governed diagnostic parameter, not a production underwriting tolerance and not an
    empirically calibrated cutoff.
    */
    0.050000,

    /*
    Section 6 rule-control defaults.

    These values govern simulated trigger construction only.

    They are not production underwriting rules.
    They are not empirically calibrated policy cutoffs.
    They are not final strategy outcomes.
    */
    TRUE,
    TRUE,
    TRUE,
    4,
    TRUE,
    0.850000,
    TRUE,
    580,

    /*
    Decision convention controls.
    */
    'APPROVED_AS_REQUESTED',
    TRUE,
    TRUE,
    'NULL_UNRESOLVED',
    'ZERO',
    'ZERO',
    'NULL_UNRESOLVED',
    FALSE,

    /*
    Failed counteroffer resolution default.

    MANUAL_REVIEW is intentionally conservative and audit-readable. It avoids silently converting all
    infeasible reduced-exposure cases into declines after higher-priority hard simulated policy stop,
    severe synthetic estimated-risk, and severe DTI routes have already been handled.
    */
    'MANUAL_REVIEW'
);



/***************************************************************************************************
SECTION 2.3 — PRODUCT POLICY PARAMETER TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Define product-specific affordability thresholds, requested Expected Loss thresholds, approved
    exposure limits, counteroffer controls, manual-review permissions, and rounding rules.

SQL PURPOSE:
    Provide one governed policy row per supported Module 1 product type.

SUPPORTED PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

WHY PRODUCT POLICY PARAMETERS ARE SEPARATE FROM STRATEGY PARAMETERS:
    Global strategy parameters govern cross-product decision posture.

    Product policy parameters govern product-specific affordability, exposure, requested Expected
    Loss, approved Expected Loss, counteroffer, and rounding behavior.

    Keeping these separate allows Module 2 to express product-aware strategy logic without burying
    product controls in downstream CASE expressions.

****************************************************************************************************/

CREATE TEMP TABLE tmp_module2_product_policy_params (
    /***********************************************************************************************
    Product identity
    ***********************************************************************************************/
    product_type                            TEXT,

    /***********************************************************************************************
    Product-specific PTI thresholds

    These thresholds use requested_payment_to_income_ratio until approved exposure treatment exists.
    ***********************************************************************************************/
    product_approve_max_pti                 NUMERIC(12,6),
    product_review_max_pti                  NUMERIC(12,6),
    product_decline_min_pti                 NUMERIC(12,6),
    counteroffer_target_pti                 NUMERIC(12,6),

    /***********************************************************************************************
    Requested Expected Loss thresholds

    requested_expected_loss_amount is the Module 2 alias for Module 1 expected_loss_amount.
    It is requested-exposure Expected Loss.
    ***********************************************************************************************/
    product_approve_max_requested_el        NUMERIC(18,2),
    product_review_max_requested_el         NUMERIC(18,2),
    product_decline_min_requested_el        NUMERIC(18,2),

    /***********************************************************************************************
    Approved Expected Loss cap

    product_approved_el_cap is used after exposure treatment is evaluated.
    It does not drive pre-decision requested Expected Loss tiering.
    ***********************************************************************************************/
    product_approved_el_cap                 NUMERIC(18,2),

    /***********************************************************************************************
    Approved exposure limits
    ***********************************************************************************************/
    product_min_approved_amount             NUMERIC(18,2),
    product_max_approved_amount             NUMERIC(18,2),

    /***********************************************************************************************
    Counteroffer and manual-review controls
    ***********************************************************************************************/
    counteroffer_allowed_flag               BOOLEAN,
    manual_review_allowed_flag              BOOLEAN,
    product_min_counteroffer_pct            NUMERIC(12,6),
    product_max_exposure_reduction_pct      NUMERIC(12,6),
    exposure_assignment_method              TEXT,

    /***********************************************************************************************
    Rounding
    ***********************************************************************************************/
    approved_amount_rounding_increment      NUMERIC(18,2)
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 2.4 — INSERT PRODUCT POLICY DEFAULTS
****************************************************************************************************

DEFAULT INTERPRETATION:
    These are initial simulated strategy defaults.

    They are not:
        production underwriting limits,
        final approved credit policy,
        empirical calibration,
        real customer treatment rules,
        or regulatory thresholds.

PRODUCT POLICY INTERPRETATION:
    Product parameters are intended to make the strategy simulator product-aware.

    Mortgage, HELOC, Auto Loan, Unsecured Personal Loan, and Revolving Line each have distinct:
        affordability tolerances,
        requested Expected Loss thresholds,
        approved Expected Loss caps,
        exposure ranges,
        counteroffer rules,
        and rounding increments.

****************************************************************************************************/

INSERT INTO tmp_module2_product_policy_params (
    product_type,

    product_approve_max_pti,
    product_review_max_pti,
    product_decline_min_pti,
    counteroffer_target_pti,

    product_approve_max_requested_el,
    product_review_max_requested_el,
    product_decline_min_requested_el,
    product_approved_el_cap,

    product_min_approved_amount,
    product_max_approved_amount,

    counteroffer_allowed_flag,
    manual_review_allowed_flag,
    product_min_counteroffer_pct,
    product_max_exposure_reduction_pct,
    exposure_assignment_method,
    approved_amount_rounding_increment
)
VALUES
    /*
    MORTGAGE:
        Larger secured exposure. Higher PTI tolerance than unsecured products because mortgage
        structure is long-term and secured, but exposure and approved Expected Loss controls remain
        important.
    */
    (
        'MORTGAGE',
        0.350000,
        0.450000,
        0.550000,
        0.320000,

        10000.00,
        20000.00,
        40000.00,
        10000.00,

        75000.00,
        800000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        5000.00
    ),

    /*
    HELOC:
        Secured revolving exposure. PTI tolerance is lower than mortgage but higher than smaller
        unsecured line-style products.
    */
    (
        'HELOC',
        0.250000,
        0.350000,
        0.450000,
        0.220000,

        8000.00,
        16000.00,
        30000.00,
        7000.00,

        10000.00,
        175000.00,

        TRUE,
        TRUE,
        0.400000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        1000.00
    ),

    /*
    AUTO_LOAN:
        Secured installment exposure with moderate structural risk and payment sensitivity.
    */
    (
        'AUTO_LOAN',
        0.180000,
        0.280000,
        0.380000,
        0.160000,

        3500.00,
        7000.00,
        12000.00,
        3000.00,

        5000.00,
        65000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    ),

    /*
    UNSECURED_PERSONAL_LOAN:
        Smaller unsecured installment exposure with higher loss severity and tighter affordability
        tolerance.
    */
    (
        'UNSECURED_PERSONAL_LOAN',
        0.150000,
        0.250000,
        0.350000,
        0.130000,

        3000.00,
        6000.00,
        10000.00,
        2500.00,

        1000.00,
        35000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    ),

    /*
    REVOLVING_LINE:
        Unsecured revolving exposure with high LGD and APR-sensitive payment proxy upstream.
        Module 2 remains a strategy simulator and not a credit-card billing engine.
    */
    (
        'REVOLVING_LINE',
        0.120000,
        0.200000,
        0.300000,
        0.100000,

        2000.00,
        4000.00,
        8000.00,
        1800.00,

        1000.00,
        20000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    );



/***************************************************************************************************
SECTION 2.5 — PERSISTENT STRATEGY RUN CAMPAIGN REGISTRY
****************************************************************************************************

BUSINESS PURPOSE:
    Create a persistent roadmap table that maps formal Module 2 campaign runs to stable run IDs,
    showcase IDs, comparison IDs, validation evidence IDs, and documentation labels.

SQL PURPOSE:
    Create or reuse:
        credit_decisioning_sim.strategy_run_campaign_registry

REGISTRY GRAIN:
    One row per planned Module 1 scenario × Module 2 strategy version run.

WHY THIS REGISTRY EXISTS:
    Technical lineage fields are precise but long.

    For validation summaries, README outputs, and executive storytelling, it is easier to reference:

        M2-02

    than:

        MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
        +
        MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0

    The registry preserves both:
        compact campaign IDs,
        and exact technical identifiers.

BOUNDARY:
    The campaign registry does not modify Module 1.
    The campaign registry does not modify strategy decisions.
    The campaign registry does not define archive replacement grain.
    The campaign registry does not define matched comparison grain.
    The campaign registry does not change decision logic.

****************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_campaign_registry (
    module1_run_id                         TEXT NOT NULL,
    module2_run_id                         TEXT PRIMARY KEY,
    run_sequence_number                    INTEGER NOT NULL,

    showcase_id                            TEXT,
    showcase_name                          TEXT,
    comparison_group_id                    TEXT,
    validation_evidence_group_id           TEXT,

    module1_scenario_set_name              TEXT NOT NULL,
    module1_scenario_name                  TEXT NOT NULL,
    population_id                          TEXT NOT NULL,

    strategy_set_name                      TEXT NOT NULL,
    strategy_name                          TEXT NOT NULL,
    strategy_version                       TEXT NOT NULL,

    module1_parameter_family_changed        TEXT,
    module1_parameter_change_summary        TEXT,

    module2_strategy_family_changed         TEXT,
    module2_parameter_change_summary        TEXT,

    expected_storyline                     TEXT,
    validation_summary_section_hint         TEXT,
    readme_storyline_label                 TEXT,
    linkedin_post_sequence                 INTEGER,

    registry_active_flag                   BOOLEAN NOT NULL DEFAULT TRUE,
    registry_created_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registry_updated_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_technical_key
ON credit_decisioning_sim.strategy_run_campaign_registry (
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version
);


CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_showcase
ON credit_decisioning_sim.strategy_run_campaign_registry (
    showcase_id,
    run_sequence_number
);


CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_comparison_group
ON credit_decisioning_sim.strategy_run_campaign_registry (
    comparison_group_id,
    run_sequence_number
);



/***************************************************************************************************
SECTION 2.6 — SEED / UPDATE STRATEGY RUN CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Seed the formal Module 2 campaign roadmap.

HOW TO USE:
    Users may update labels, expected_storyline, readme_storyline_label, and linkedin_post_sequence
    as the portfolio story evolves.

IMPORTANT:
    These registry rows do not create Module 1 scenarios.
    These registry rows do not execute Module 2 strategies.
    These registry rows only map planned or completed technical runs to stable evidence IDs.

****************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_run_campaign_registry (
    module1_run_id,
    module2_run_id,
    run_sequence_number,

    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_parameter_family_changed,
    module1_parameter_change_summary,

    module2_strategy_family_changed,
    module2_parameter_change_summary,

    expected_storyline,
    validation_summary_section_hint,
    readme_storyline_label,
    linkedin_post_sequence,

    registry_active_flag,
    registry_updated_ts
)
VALUES
    ('M1-01', 'M2-01', 1, 'SC01', 'Baseline Strategy Frontier', 'CG01', 'VE01',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish the baseline reference strategy output for the Module 1 baseline population.',
     'Baseline reference strategy evidence', 'Baseline strategy reference', 1, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-02', 2, 'SC01', 'Baseline Strategy Frontier', 'CG01', 'VE02',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'RISK_TIGHTENING', 'Tightens synthetic estimated-PD proxy strategy thresholds.',
     'Demonstrate risk-discipline tradeoff: lower simulated offer exposure and approved Expected Loss, with higher no-offer outcomes.',
     'Risk-discipline challenger evidence', 'Tighter synthetic-risk strategy', 2, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-03', 3, 'SC01', 'Baseline Strategy Frontier', 'CG02', 'VE03',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'GROWTH', 'Loosens selected synthetic-risk, PTI, and DTI tolerances for growth-oriented comparison.',
     'Demonstrate growth tradeoff: higher simulated offer exposure and approved amount with measurable risk impact.',
     'Growth challenger evidence', 'Growth-oriented strategy', 3, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-04', 4, 'SC01', 'Baseline Strategy Frontier', 'CG03', 'VE04',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'AFFORDABILITY_TIGHTENING', 'Tightens PTI thresholds and counteroffer target PTI.',
     'Demonstrate affordability discipline and how tighter PTI guardrails affect offer exposure, counteroffers, and review burden.',
     'Affordability challenger evidence', 'Tighter affordability strategy', 4, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-05', 5, 'SC01', 'Baseline Strategy Frontier', 'CG04', 'VE05',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'COUNTEROFFER_MANAGEMENT', 'Emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.',
     'Demonstrate exposure-management tradeoff through counteroffer feasibility and approved exposure reduction.',
     'Counteroffer management evidence', 'Counteroffer-first strategy', 5, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-06', 6, 'SC01', 'Baseline Strategy Frontier', 'CG05', 'VE06',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Demonstrate product-specific risk guardrails and where product-level strategy controls change outcomes.',
     'Product guardrail evidence', 'Product-specific guardrail strategy', 6, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-07', 7, 'SC01', 'Baseline Strategy Frontier', 'CG06', 'VE07',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'MANUAL_REVIEW_REDUCTION_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'OPERATIONS_REVIEW_REDUCTION', 'Resolves failed counteroffers to final no-offer outcomes to reduce unresolved manual review.',
     'Demonstrate operational review-burden reduction and the corresponding no-offer tradeoff.',
     'Manual review reduction evidence', 'Manual-review reduction strategy', 7, TRUE, CURRENT_TIMESTAMP),

    ('M1-02', 'M2-08', 8, 'SC02', 'Rate Environment Sensitivity', NULL, 'VE08',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-up scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under a 200 basis-point upstream rate-stress scenario.',
     'Rate stress baseline evidence', 'Rate-up 200bp baseline strategy', 8, TRUE, CURRENT_TIMESTAMP),

    ('M1-03', 'M2-09', 9, 'SC02', 'Rate Environment Sensitivity', NULL, 'VE09',
     'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-down scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under a 200 basis-point upstream rate-relief scenario.',
     'Rate relief baseline evidence', 'Rate-down 200bp baseline strategy', 9, TRUE, CURRENT_TIMESTAMP),

    ('M1-04', 'M2-10', 10, 'SC02', 'Rate Environment Sensitivity', NULL, 'VE10',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 300 basis-point rate-up scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under a stronger 300 basis-point upstream rate-stress scenario.',
     'Rate stress 300bp evidence', 'Rate-up 300bp baseline strategy', 10, TRUE, CURRENT_TIMESTAMP),

    ('M1-02', 'M2-11', 11, 'SC02', 'Rate Environment Sensitivity', 'CG07', 'VE11',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-up scenario.',
     'AFFORDABILITY_TIGHTENING', 'Tightens PTI thresholds and counteroffer target PTI.',
     'Evaluate whether tighter affordability controls improve approved PTI and approved Expected Loss under rate stress.',
     'Rate stress affordability evidence', 'Rate-up 200bp affordability guardrail', 11, TRUE, CURRENT_TIMESTAMP),

    ('M1-04', 'M2-12', 12, 'SC02', 'Rate Environment Sensitivity', 'CG08', 'VE12',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 300 basis-point rate-up scenario.',
     'AFFORDABILITY_TIGHTENING', 'Tightens PTI thresholds and counteroffer target PTI.',
     'Evaluate whether tighter affordability controls are more protective under stronger rate stress.',
     'Strong rate stress affordability evidence', 'Rate-up 300bp affordability guardrail', 12, TRUE, CURRENT_TIMESTAMP),

    ('M1-03', 'M2-13', 13, 'SC02', 'Rate Environment Sensitivity', 'CG09', 'VE13',
     'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-down scenario.',
     'GROWTH', 'Loosens selected synthetic-risk, PTI, and DTI tolerances for growth-oriented comparison.',
     'Evaluate whether rate relief plus growth posture expands simulated offer exposure and approved amount.',
     'Rate relief growth evidence', 'Rate-down 200bp growth strategy', 13, TRUE, CURRENT_TIMESTAMP),

    ('M1-05', 'M2-14', 14, 'SC03', 'Credit Box Sensitivity', NULL, 'VE14',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_BOX_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'BASELINE_REFERENCE', 'Credit-box baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish credit-box sensitivity reference behavior.',
     'Credit-box reference evidence', 'Credit-box baseline reference', 14, TRUE, CURRENT_TIMESTAMP),

    ('M1-06', 'M2-15', 15, 'SC03', 'Credit Box Sensitivity', NULL, 'VE15',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'PRIME_GROWTH_SCORE_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing stronger-score applicant composition.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy performance under stronger credit-box mix.',
     'Prime-growth mix evidence', 'Prime growth score mix', 15, TRUE, CURRENT_TIMESTAMP),

    ('M1-07', 'M2-16', 16, 'SC03', 'Credit Box Sensitivity', NULL, 'VE16',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing near-prime expansion.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under near-prime expansion.',
     'Near-prime expansion baseline evidence', 'Near-prime expansion baseline', 16, TRUE, CURRENT_TIMESTAMP),

    ('M1-07', 'M2-17', 17, 'SC03', 'Credit Box Sensitivity', 'CG10', 'VE17',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing near-prime expansion.',
     'RISK_TIGHTENING', 'Tightens synthetic estimated-PD proxy strategy thresholds.',
     'Evaluate risk-discipline strategy behavior in a near-prime expansion scenario.',
     'Near-prime risk discipline evidence', 'Near-prime expansion risk discipline', 17, TRUE, CURRENT_TIMESTAMP),

    ('M1-07', 'M2-18', 18, 'SC03', 'Credit Box Sensitivity', 'CG11', 'VE18',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing near-prime expansion.',
     'COUNTEROFFER_MANAGEMENT', 'Emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.',
     'Evaluate whether counteroffer-first strategy preserves access while managing exposure in near-prime expansion.',
     'Near-prime counteroffer evidence', 'Near-prime expansion counteroffer strategy', 18, TRUE, CURRENT_TIMESTAMP),

    ('M1-08', 'M2-19', 19, 'SC03', 'Credit Box Sensitivity', NULL, 'VE19',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing weaker-score applicant composition.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under credit-stress score mix.',
     'Credit-stress baseline evidence', 'Credit stress baseline', 19, TRUE, CURRENT_TIMESTAMP),

    ('M1-08', 'M2-20', 20, 'SC03', 'Credit Box Sensitivity', 'CG12', 'VE20',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing weaker-score applicant composition.',
     'RISK_TIGHTENING', 'Tightens synthetic estimated-PD proxy strategy thresholds.',
     'Evaluate whether risk tightening improves approved Expected Loss behavior under credit-stress mix.',
     'Credit-stress risk discipline evidence', 'Credit stress risk discipline', 20, TRUE, CURRENT_TIMESTAMP),

    ('M1-09', 'M2-21', 21, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE21',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'PRODUCT_MIX_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Product-mix baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish product-mix sensitivity reference behavior.',
     'Product-mix reference evidence', 'Product mix baseline reference', 21, TRUE, CURRENT_TIMESTAMP),

    ('M1-10', 'M2-22', 22, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE22',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing unsecured growth.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under unsecured-growth product mix.',
     'Unsecured growth baseline evidence', 'Unsecured growth baseline', 22, TRUE, CURRENT_TIMESTAMP),

    ('M1-10', 'M2-23', 23, 'SC04', 'Portfolio Mix Sensitivity', 'CG13', 'VE23',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing unsecured growth.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under unsecured-growth product mix.',
     'Unsecured growth guardrail evidence', 'Unsecured growth product guardrails', 23, TRUE, CURRENT_TIMESTAMP),

    ('M1-11', 'M2-24', 24, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE24',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'SECURED_BALANCE_GROWTH_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing secured balance growth.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under secured-balance growth mix.',
     'Secured balance growth evidence', 'Secured balance growth baseline', 24, TRUE, CURRENT_TIMESTAMP),

    ('M1-12', 'M2-25', 25, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE25',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing revolving-line expansion.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under revolving-line expansion.',
     'Revolving expansion baseline evidence', 'Revolving expansion baseline', 25, TRUE, CURRENT_TIMESTAMP),

    ('M1-12', 'M2-26', 26, 'SC04', 'Portfolio Mix Sensitivity', 'CG14', 'VE26',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing revolving-line expansion.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under revolving-line expansion.',
     'Revolving expansion guardrail evidence', 'Revolving expansion product guardrails', 26, TRUE, CURRENT_TIMESTAMP),

    ('M1-13', 'M2-27', 27, 'SC05', 'Exposure Intensity Sensitivity', NULL, 'VE27',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'EXPOSURE_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Exposure-intensity baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish exposure-intensity reference behavior.',
     'Exposure reference evidence', 'Exposure intensity reference', 27, TRUE, CURRENT_TIMESTAMP),

    ('M1-14', 'M2-28', 28, 'SC05', 'Exposure Intensity Sensitivity', NULL, 'VE28',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Module 1 scenario with higher balance appetite.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under higher requested-exposure intensity.',
     'High balance baseline evidence', 'High balance baseline', 28, TRUE, CURRENT_TIMESTAMP),

    ('M1-14', 'M2-29', 29, 'SC05', 'Exposure Intensity Sensitivity', 'CG15', 'VE29',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Module 1 scenario with higher balance appetite.',
     'COUNTEROFFER_MANAGEMENT', 'Emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.',
     'Evaluate counteroffer-first exposure treatment under high-balance requested-exposure intensity.',
     'High balance counteroffer evidence', 'High balance counteroffer strategy', 29, TRUE, CURRENT_TIMESTAMP),

    ('M1-15', 'M2-30', 30, 'SC05', 'Exposure Intensity Sensitivity', NULL, 'VE30',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'LOW_BALANCE_CONSERVATIVE_REQUESTS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Module 1 scenario with lower-balance conservative requests.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under lower requested-exposure intensity.',
     'Low balance baseline evidence', 'Low balance conservative baseline', 30, TRUE, CURRENT_TIMESTAMP),

    ('M1-16', 'M2-31', 31, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE31',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'LGD_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'LGD baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish LGD severity sensitivity reference behavior.',
     'LGD reference evidence', 'LGD baseline reference', 31, TRUE, CURRENT_TIMESTAMP),

    ('M1-17', 'M2-32', 32, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE32',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'SECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario stressing secured-product severity.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under secured-product severity stress.',
     'Secured severity evidence', 'Secured severity stress baseline', 32, TRUE, CURRENT_TIMESTAMP),

    ('M1-18', 'M2-33', 33, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE33',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario stressing unsecured-product severity.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under unsecured-product severity stress.',
     'Unsecured severity baseline evidence', 'Unsecured severity stress baseline', 33, TRUE, CURRENT_TIMESTAMP),

    ('M1-18', 'M2-34', 34, 'SC06', 'LGD Severity Sensitivity', 'CG16', 'VE34',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario stressing unsecured-product severity.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under unsecured severity stress.',
     'Unsecured severity guardrail evidence', 'Unsecured severity product guardrails', 34, TRUE, CURRENT_TIMESTAMP),

    ('M1-19', 'M2-35', 35, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE35',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario applying broad LGD stress.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under broad LGD severity stress.',
     'Broad LGD stress baseline evidence', 'Broad LGD stress baseline', 35, TRUE, CURRENT_TIMESTAMP),

    ('M1-19', 'M2-36', 36, 'SC06', 'LGD Severity Sensitivity', 'CG17', 'VE36',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario applying broad LGD stress.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under broad LGD severity stress.',
     'Broad LGD guardrail evidence', 'Broad LGD stress product guardrails', 36, TRUE, CURRENT_TIMESTAMP)

ON CONFLICT (module2_run_id)
DO UPDATE SET
    module1_run_id = EXCLUDED.module1_run_id,
    run_sequence_number = EXCLUDED.run_sequence_number,
    showcase_id = EXCLUDED.showcase_id,
    showcase_name = EXCLUDED.showcase_name,
    comparison_group_id = EXCLUDED.comparison_group_id,
    validation_evidence_group_id = EXCLUDED.validation_evidence_group_id,
    module1_scenario_set_name = EXCLUDED.module1_scenario_set_name,
    module1_scenario_name = EXCLUDED.module1_scenario_name,
    population_id = EXCLUDED.population_id,
    strategy_set_name = EXCLUDED.strategy_set_name,
    strategy_name = EXCLUDED.strategy_name,
    strategy_version = EXCLUDED.strategy_version,
    module1_parameter_family_changed = EXCLUDED.module1_parameter_family_changed,
    module1_parameter_change_summary = EXCLUDED.module1_parameter_change_summary,
    module2_strategy_family_changed = EXCLUDED.module2_strategy_family_changed,
    module2_parameter_change_summary = EXCLUDED.module2_parameter_change_summary,
    expected_storyline = EXCLUDED.expected_storyline,
    validation_summary_section_hint = EXCLUDED.validation_summary_section_hint,
    readme_storyline_label = EXCLUDED.readme_storyline_label,
    linkedin_post_sequence = EXCLUDED.linkedin_post_sequence,
    registry_active_flag = EXCLUDED.registry_active_flag,
    registry_updated_ts = CURRENT_TIMESTAMP;



/***************************************************************************************************
SECTION 2.7 — PERSISTENT STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************

BUSINESS PURPOSE:
    Define planned baseline-versus-challenger comparisons using stable comparison_group_id values.

SQL PURPOSE:
    Create or reuse:
        credit_decisioning_sim.strategy_comparison_campaign_registry

COMPARISON REGISTRY GRAIN:
    One row per planned comparison_group_id.

WHY THIS REGISTRY EXISTS:
    Section 13 performs matched strategy comparison.

    The comparison registry lets users choose a comparison by ID rather than manually editing
    baseline and challenger strategy names each time.

BOUNDARY:
    The comparison registry does not mutate archive rows.
    The comparison registry does not recalculate strategy outcomes.
    The comparison registry does not replace archive grain.
    The comparison registry is selection metadata for Section 13 and documentation traceability.

****************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_comparison_campaign_registry (
    comparison_group_id                    TEXT PRIMARY KEY,
    comparison_set_name                    TEXT NOT NULL,

    showcase_id                            TEXT,
    showcase_name                          TEXT,

    baseline_module2_run_id                TEXT,
    challenger_module2_run_id              TEXT,

    baseline_strategy_set_name             TEXT NOT NULL,
    baseline_strategy_name                 TEXT NOT NULL,
    baseline_strategy_version              TEXT NOT NULL,

    challenger_strategy_set_name           TEXT NOT NULL,
    challenger_strategy_name               TEXT NOT NULL,
    challenger_strategy_version            TEXT NOT NULL,

    module1_scenario_set_name              TEXT NOT NULL,
    module1_scenario_name                  TEXT NOT NULL,
    population_id                          TEXT NOT NULL,

    expected_comparison_storyline          TEXT,
    primary_metric_focus                   TEXT,

    active_comparison_flag                 BOOLEAN NOT NULL DEFAULT FALSE,
    registry_active_flag                   BOOLEAN NOT NULL DEFAULT TRUE,
    registry_created_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registry_updated_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_comparison_campaign_registry_technical_key
ON credit_decisioning_sim.strategy_comparison_campaign_registry (
    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,
    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);



/***************************************************************************************************
SECTION 2.8 — SEED / UPDATE STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Seed planned comparison groups for Section 13 matched strategy comparison and later validation
    narrative.

ACTIVE COMPARISON:
    Exactly one comparison should ordinarily have:
        active_comparison_flag = TRUE

    Section 13 will use the active comparison to populate tmp_m2_strategy_comparison_params.

CURRENT DEFAULT:
    CG01 is active by default because it supports the already validated first frontier story:
        BASELINE_STRATEGY
        versus
        TIGHTER_SYNTHETIC_RISK_STRATEGY
        on
        BASELINE_V2

****************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_comparison_campaign_registry (
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    expected_comparison_storyline,
    primary_metric_focus,

    active_comparison_flag,
    registry_active_flag,
    registry_updated_ts
)
VALUES
    ('CG01', 'BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-02',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter synthetic-risk strategy on the same Module 1 baseline population.',
     'APPROVED_EXPECTED_LOSS_REDUCTION',
     TRUE, TRUE, CURRENT_TIMESTAMP),

    ('CG02', 'BASELINE_V2_BASELINE_STRATEGY_VS_GROWTH_ORIENTED',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-03',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to growth-oriented strategy on the same Module 1 baseline population.',
     'OFFER_GROWTH',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG03', 'BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_AFFORDABILITY',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-04',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter affordability strategy on the same Module 1 baseline population.',
     'APPROVED_PTI_DISCIPLINE',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG04', 'BASELINE_V2_BASELINE_STRATEGY_VS_COUNTEROFFER_FIRST',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-05',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to counteroffer-first exposure strategy on the same Module 1 baseline population.',
     'COUNTEROFFER_EXPOSURE_MANAGEMENT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG05', 'BASELINE_V2_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-06',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrail strategy on the same Module 1 baseline population.',
     'PRODUCT_GUARDRAIL_EFFECT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG06', 'BASELINE_V2_BASELINE_STRATEGY_VS_MANUAL_REVIEW_REDUCTION',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-07',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'MANUAL_REVIEW_REDUCTION_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to manual-review reduction strategy on the same Module 1 baseline population.',
     'MANUAL_REVIEW_BURDEN_REDUCTION',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG07', 'RATE_UP_200BP_BASELINE_STRATEGY_VS_TIGHTER_AFFORDABILITY',
     'SC02', 'Rate Environment Sensitivity',
     'M2-08', 'M2-11',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter affordability strategy under 200bp rate stress.',
     'RATE_STRESS_AFFORDABILITY_GUARDRAIL',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG08', 'RATE_UP_300BP_BASELINE_STRATEGY_VS_TIGHTER_AFFORDABILITY',
     'SC02', 'Rate Environment Sensitivity',
     'M2-10', 'M2-12',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter affordability strategy under 300bp rate stress.',
     'STRONG_RATE_STRESS_AFFORDABILITY_GUARDRAIL',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG09', 'RATE_DOWN_200BP_BASELINE_STRATEGY_VS_GROWTH_ORIENTED',
     'SC02', 'Rate Environment Sensitivity',
     'M2-09', 'M2-13',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1',
     'Compare baseline strategy to growth-oriented strategy under 200bp rate relief.',
     'RATE_RELIEF_GROWTH_OPPORTUNITY',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG10', 'NEAR_PRIME_EXPANSION_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
     'SC03', 'Credit Box Sensitivity',
     'M2-16', 'M2-17',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter synthetic-risk strategy under near-prime expansion.',
     'NEAR_PRIME_RISK_DISCIPLINE',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG11', 'NEAR_PRIME_EXPANSION_BASELINE_STRATEGY_VS_COUNTEROFFER_FIRST',
     'SC03', 'Credit Box Sensitivity',
     'M2-16', 'M2-18',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to counteroffer-first strategy under near-prime expansion.',
     'NEAR_PRIME_COUNTEROFFER_MANAGEMENT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG12', 'CREDIT_STRESS_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
     'SC03', 'Credit Box Sensitivity',
     'M2-19', 'M2-20',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter synthetic-risk strategy under credit-stress score mix.',
     'CREDIT_STRESS_RISK_DISCIPLINE',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG13', 'UNSECURED_GROWTH_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC04', 'Portfolio Mix Sensitivity',
     'M2-22', 'M2-23',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under unsecured-growth product mix.',
     'UNSECURED_GROWTH_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG14', 'REVOLVING_EXPANSION_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC04', 'Portfolio Mix Sensitivity',
     'M2-25', 'M2-26',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under revolving-line expansion.',
     'REVOLVING_EXPANSION_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG15', 'HIGH_BALANCE_BASELINE_STRATEGY_VS_COUNTEROFFER_FIRST',
     'SC05', 'Exposure Intensity Sensitivity',
     'M2-28', 'M2-29',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1',
     'Compare baseline strategy to counteroffer-first strategy under high-balance appetite.',
     'HIGH_BALANCE_COUNTEROFFER_MANAGEMENT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG16', 'UNSECURED_SEVERITY_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC06', 'LGD Severity Sensitivity',
     'M2-33', 'M2-34',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under unsecured severity stress.',
     'UNSECURED_SEVERITY_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG17', 'BROAD_LGD_STRESS_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC06', 'LGD Severity Sensitivity',
     'M2-35', 'M2-36',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under broad LGD stress.',
     'BROAD_LGD_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP)

ON CONFLICT (comparison_group_id)
DO UPDATE SET
    comparison_set_name = EXCLUDED.comparison_set_name,
    showcase_id = EXCLUDED.showcase_id,
    showcase_name = EXCLUDED.showcase_name,
    baseline_module2_run_id = EXCLUDED.baseline_module2_run_id,
    challenger_module2_run_id = EXCLUDED.challenger_module2_run_id,
    baseline_strategy_set_name = EXCLUDED.baseline_strategy_set_name,
    baseline_strategy_name = EXCLUDED.baseline_strategy_name,
    baseline_strategy_version = EXCLUDED.baseline_strategy_version,
    challenger_strategy_set_name = EXCLUDED.challenger_strategy_set_name,
    challenger_strategy_name = EXCLUDED.challenger_strategy_name,
    challenger_strategy_version = EXCLUDED.challenger_strategy_version,
    module1_scenario_set_name = EXCLUDED.module1_scenario_set_name,
    module1_scenario_name = EXCLUDED.module1_scenario_name,
    population_id = EXCLUDED.population_id,
    expected_comparison_storyline = EXCLUDED.expected_comparison_storyline,
    primary_metric_focus = EXCLUDED.primary_metric_focus,
    active_comparison_flag = EXCLUDED.active_comparison_flag,
    registry_active_flag = EXCLUDED.registry_active_flag,
    registry_updated_ts = CURRENT_TIMESTAMP;


/*
Governance control:
    At most one comparison should be active for Section 13 default comparison selection.
*/
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_comparison_campaign_registry_one_active
ON credit_decisioning_sim.strategy_comparison_campaign_registry (active_comparison_flag)
WHERE active_comparison_flag IS TRUE;



/***************************************************************************************************
SECTION 2.9 — REGISTRY SETUP REVIEW OUTPUTS
****************************************************************************************************

PURPOSE:
    Provide lightweight review outputs confirming the current active strategy parameter row and the
    registry mappings available for the current run.

INTERPRETATION:
    These are setup diagnostics only.

    Section 3 performs formal fail-fast checks.
    Section 13 uses the active comparison registry for matched comparison.
    Section 16 uses the run campaign registry for evidence capture.

****************************************************************************************************/


/* Current active Module 2 strategy parameter row. */
SELECT
    active_strategy_flag,
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,
    campaign_registry_required_flag,
    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,
    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution
FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;


/* Campaign registry row matching the current active strategy technical key. */
SELECT
    r.module1_run_id,
    r.module2_run_id,
    r.run_sequence_number,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version,
    r.module1_parameter_family_changed,
    r.module2_strategy_family_changed,
    r.expected_storyline,
    r.readme_storyline_label,
    r.linkedin_post_sequence,
    r.registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry r
JOIN tmp_module2_strategy_params sp
    ON sp.active_strategy_flag IS TRUE
   AND r.module1_scenario_set_name = sp.source_module1_scenario_set_name
   AND r.module1_scenario_name = sp.source_module1_scenario_name
   AND r.population_id = sp.source_population_id
   AND r.strategy_set_name = sp.strategy_set_name
   AND r.strategy_name = sp.strategy_name
   AND r.strategy_version = sp.strategy_version;


/* Active comparison registry row for Section 13 default matched-comparison selection. */
SELECT
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,
    baseline_module2_run_id,
    challenger_module2_run_id,
    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,
    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    expected_comparison_storyline,
    primary_metric_focus,
    active_comparison_flag,
    registry_active_flag
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE active_comparison_flag IS TRUE
ORDER BY comparison_group_id;


/***************************************************************************************************
END OF SECTION 2 — STRATEGY PARAMETER, PRODUCT POLICY, AND CAMPAIGN REGISTRY FRAMEWORK

Section 2 established:
    1. The active Module 2 strategy parameter row.
    2. The product-specific policy parameter table.
    3. The persistent strategy run campaign registry.
    4. The persistent strategy comparison campaign registry.
    5. Stable run IDs and comparison IDs for validation-summary traceability.
    6. Review outputs showing the current active strategy and registry mappings.

No Module 1 source rows have been consumed.
No strategy outcomes have been assigned.
No approved exposure has been calculated.
No approved Expected Loss has been calculated.
No simulated reason codes have been assigned.
No latest-run output has been created.
No archive rows have been inserted.
No QA validation has been performed.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00648 -->


---

<a id="c038-m00649"></a>

### C038-M00649

**Andrew** · 2026-05-09T15:57:40.446000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00649 -->
section 3: 
<!-- END_MESSAGE C038-M00649 -->


**Attachments in export:** `Pasted text(110).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_24.md) · [Next](Part_26.md)
