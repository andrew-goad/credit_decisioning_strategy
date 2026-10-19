# Module 2 Decision Simulator Build

## Part 71

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_70.md) · [Next](Part_72.md)

<a id="c038-m01413"></a>

### C038-M01413

**ChatGPT** · 2026-05-12T01:55:54.257682-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01413 -->
Understood. Below is **only** the full copy-paste patch for **Section 0 and Section 1**. It does **not** include the redesigned Section 2 or updated Section 3.

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
    Pre-production credit strategy outcome simulation on synthetic applicants without exposing PII.

****************************************************************************************************/


/***************************************************************************************************
EXECUTIVE SNAPSHOT
****************************************************************************************************

WHAT THIS IS:
    Module 2 is a governed synthetic credit strategy simulation layer.

    It consumes completed Module 1 synthetic application and risk outputs, applies configurable
    Module 2 strategy and product-policy controls, assigns simulated strategy outcomes, calculates
    simulated approved exposure economics, assigns simulated strategy explanation codes, persists
    latest-run and archive outputs, and captures validation-ready evidence.

WHY IT MATTERS:
    Credit strategy is not a score cutoff.

    It is a governed tradeoff among:
        access,
        approval rate,
        counteroffer usage,
        manual-review burden,
        decline concentration,
        affordability,
        approved exposure,
        synthetic estimated-risk profile,
        requested Expected Loss,
        approved Expected Loss,
        product-specific guardrails,
        and explainability.

    Module 2 makes those tradeoffs visible in a controlled, synthetic, reproducible environment.

WHAT THIS DEMONSTRATES:
    This module demonstrates:
        credit strategy architecture thinking,
        parameterized policy simulation,
        staged decision-engine design,
        product-policy control,
        exposure-treatment logic,
        counteroffer feasibility,
        simulated reason-code transparency,
        archive-backed comparison,
        validation discipline,
        parameter snapshot governance,
        and executive-ready evidence capture.

CORE INSIGHT:
    A credit strategy outcome should not be treated as a black-box label.

    In Module 2, final simulated outcomes emerge through a transparent chain:

        Module 1 Applicant / Product / Risk Profile
        → Module 2 Strategy Controls
        → Product Policy Controls
        → Diagnostic Segmentation
        → Rule Trigger Flags
        → Preliminary Routing
        → Approved Exposure and Counteroffer Feasibility
        → Final Simulated Strategy Outcome
        → Simulated Strategy Explanation Codes
        → Latest-Run Output
        → Archive Persistence
        → Matched Comparison
        → Validation / QA
        → Strategy Frontier Summary
        → Evidence Capture
        → Post-Campaign Acceptance

READER TAKEAWAY:
    This SQL file is intended to read as a full-system design artifact.

    A reviewer should be able to understand:
        what the module does,
        why it is structured this way,
        how it consumes Module 1,
        how strategy controls are selected,
        how product policy affects outcomes,
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

    Module 2 captures selected exposure, APR-proxy, term, product, score, and approved Expected Loss
    fields that will support future Module 3 economics work.

    Module 2 does not calculate:
        revenue,
        yield,
        funding cost,
        margin,
        profitability,
        capital,
        pricing optimization,
        net income,
        or lifetime value.

====================================================================================================
0.1 EXECUTIVE PURPOSE
====================================================================================================

Module 2 answers the strategy-simulation question:

    "Given a completed Module 1 synthetic applicant population and a governed Module 2 strategy,
     what simulated strategy outcome does each synthetic applicant receive, what simulated exposure
     is assigned, and what simulated strategy explanation codes describe the outcome?"

Module 2 supports:
    pre-production strategy design,
    champion / challenger comparison,
    exposure-treatment review,
    counteroffer feasibility analysis,
    simulated reason-code transparency,
    portfolio-level strategy diagnostics,
    matched archive comparison,
    validation-summary evidence capture,
    README / portfolio result narrative,
    LinkedIn campaign storytelling,
    and future Module 3 economics design.

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
    4. A strategy and product-policy control framework.
    5. A staged decision-outcome architecture.
    6. A simulated approved-exposure and counteroffer feasibility engine.
    7. A simulated strategy explanation-code framework.
    8. A latest-run and archive persistence framework.
    9. A matched strategy comparison framework.
    10. A QA and validation evidence framework.
    11. A frontier and executive evidence framework.
    12. A post-campaign acceptance and parameter-audit framework.

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

They protect the credibility of the module by keeping the implementation focused on governed
synthetic strategy simulation.

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
    → Module 2 Strategy Controls
    → Product Policy Controls
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
    → Strategy Frontier Summary
    → Executive Evidence Capture
    → Post-Campaign Acceptance

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

1. Strategy controls over hidden logic
    Strategy behavior should be governed through explicit parameters, profiles, and product-policy
    controls before users rewrite downstream CASE logic.

2. Baseline first
    BASELINE_STRATEGY is the default reference posture.

    Challenger strategies are examples of how the engine can test different tradeoffs:
        tighter risk,
        growth,
        affordability discipline,
        counteroffer-first treatment,
        product guardrails,
        and manual-review reduction.

3. Staged over monolithic
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
        evidence capture,
        and post-campaign acceptance.

4. Explainable over opaque
    Every major outcome should be traceable through:
        active strategy controls,
        product-policy controls,
        segmentation,
        rule-trigger flags,
        preliminary routing,
        exposure-treatment diagnostics,
        final decision fields,
        and simulated strategy explanation codes.

5. Simulated outcomes over operational decisions
    APPROVE, COUNTEROFFER, MANUAL_REVIEW, and DECLINE are simulated outcomes for synthetic
    applicants.

6. Matched comparison over population drift
    Strategy comparisons should hold Module 1 scenario and population constant when isolating
    downstream Module 2 strategy effects.

7. Governed archive over ad hoc outputs
    The latest-run table is replaceable.
    The archive table preserves completed strategy outputs.

8. Evidence capture over scattered manual notes
    Section 16 persists executive evidence, validation evidence, parameter snapshots, and product ×
    score segment evidence.

9. Post-campaign synchronization over manual patching
    After a full campaign, Section 15 frontier fields should be synchronized into persistent evidence
    through a formal post-campaign process.

10. Modular expansion over scope creep
    Growth, earnings, funding cost, risk-adjusted margin, pricing, and profitability belong to a
    future Module 3 economics layer.

====================================================================================================
0.6 BASELINE DEFAULT VS CAMPAIGN CHALLENGER EXAMPLES
====================================================================================================

Baseline default strategy:

    BASELINE_STRATEGY

Campaign challenger examples:

    TIGHTER_SYNTHETIC_RISK_STRATEGY
        Lowers synthetic estimated-risk thresholds to reduce approved Expected Loss and improve the
        offered-population risk profile.

    GROWTH_ORIENTED_STRATEGY
        Expands approval and offer exposure using growth-oriented thresholds and product policy.

    TIGHTER_AFFORDABILITY_STRATEGY
        Tightens PTI and DTI posture to reduce payment-burden stress.

    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
        Uses reduced-exposure treatment to preserve access while lowering approved exposure pressure.

    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
        Tightens unsecured personal loan and revolving line policy while leaving secured / auto
        products stable.

    MANUAL_REVIEW_REDUCTION_STRATEGY
        Resolves failed counteroffer cases to DECLINE rather than MANUAL_REVIEW to test operational
        review-burden reduction.

Important:
    The active selected run may use any strategy.
    The default reference strategy remains BASELINE_STRATEGY.

====================================================================================================
0.7 FORMAL CAMPAIGN SCENARIO FRAMEWORK
====================================================================================================

The formal Module 2 campaign is organized into six scenario families:

    SC01 — Baseline Strategy Frontier
        Compare multiple Module 2 strategies on the same Module 1 BASELINE_V2 population.

    SC02 — Rate Environment Sensitivity
        Test strategy behavior under RATE_UP_200BP, RATE_UP_300BP, and RATE_DOWN_200BP.

    SC03 — Credit Box Sensitivity
        Test strategy behavior under prime-growth, near-prime expansion, and credit-stress score mix.

    SC04 — Portfolio Mix Sensitivity
        Test strategy behavior under unsecured growth, secured balance growth, and revolving-line
        expansion.

    SC05 — Exposure Intensity Sensitivity
        Test strategy behavior under exposure baseline, high-balance appetite, and low-balance
        conservative request scenarios.

    SC06 — LGD Severity Sensitivity
        Test strategy behavior under secured severity, unsecured severity, and broad LGD stress.

These campaign scenarios are examples of how the engine can be used.

Users may add custom scenarios and custom strategies, but formal campaign evidence should remain
registry-matched, parameter-snapshot captured, and validation-reviewed.

====================================================================================================
0.8 OPERATING JOB AID — SINGLE RUN
====================================================================================================

Use this workflow for one governed Module 2 run.

    1. Run Section 1.
        Resets temporary objects and the replaceable latest-run table.

    2. Configure Section 2.
        Select the intended Module 2 run or strategy configuration.

        Default starting point:
            BASELINE_STRATEGY on BASELINE_V2.

    3. Run Section 3.
        Fails fast if strategy configuration, product policy, source selection, or registry linkage is
        invalid.

    4. Run Sections 4–11.
        Stages source data, segments profiles, builds rule flags, routes decisions, calculates
        exposure treatment, resolves final outcomes, assigns reason codes, and materializes the
        latest-run output.

    5. Run Section 12.
        Persists the completed run to the archive when archive_run_flag = TRUE.

    6. Run Section 13 as needed.
        Reviews selected matched comparison from the comparison registry.

    7. Run Section 14.
        Validates the latest-run output and materializes validation summary evidence.

    8. Run Section 15.
        Builds archive-backed frontier summary.

    9. Run Section 16.
        Captures executive evidence, validation evidence, parameter snapshot, and segment evidence
        for the completed current run.

====================================================================================================
0.9 OPERATING JOB AID — FULL CAMPAIGN
====================================================================================================

Use this workflow for a full multi-run campaign.

    1. For each planned M2 run:
        select the run in Section 2;
        run Sections 1–16.8;
        confirm Section 16.8 evidence outputs.

    2. After all campaign runs are complete:
        rerun Section 15 once from the completed archive.

    3. Run Section 16.9.
        Synchronizes fresh Section 15 frontier fields into:
            credit_decisioning_sim.strategy_run_evidence_summary

    4. Run Section 17.
        Performs final post-campaign archive, registry, comparison, validation, evidence, parameter,
        product-policy, and acceptance checks.

Why the Section 15 → Section 16.9 → Section 17 sequence matters:
    Section 15 is archive-wide.
    Section 16 captures evidence one run at a time.
    After a full campaign or rerun, earlier evidence rows may need frontier labels refreshed from the
    final completed archive.
    Section 16.9 formalizes that refresh so users do not need an informal patch.

====================================================================================================
0.10 CUSTOM STRATEGY GUIDANCE
====================================================================================================

Formal campaign runs:
    Use governed campaign run IDs, strategy names, product-policy settings, and registry-matched
    evidence.

Custom experiments:
    Users may create custom strategy settings or product-policy settings to test unique situations.

Custom runs should be clearly labeled with:
    custom strategy name,
    custom product-policy logic,
    custom parameter-change reason,
    custom expected storyline,
    and registry setting appropriate to the intended use.

Recommendation:
    Use standard campaign settings for governed validation evidence.
    Use custom settings for exploratory analysis unless a custom registry row is intentionally added
    and reviewed.

====================================================================================================
0.11 VALIDATION AND ACCEPTANCE GUIDANCE
====================================================================================================

A successful SQL run is not the same as a validated strategy run.

A completed run should be reviewed across:

    1. Structural integrity
        row count, application_id uniqueness, strategy lineage, and Module 1 scenario lineage.

    2. Final outcome integrity
        one final decision outcome per row and final flags reconcile.

    3. Amount and economics conventions
        APPROVE preserves requested exposure;
        COUNTEROFFER reduces exposure;
        MANUAL_REVIEW remains unresolved;
        DECLINE uses zero-exposure convention.

    4. Risk and affordability behavior
        synthetic estimated-risk tiers, requested PTI buckets, DTI buckets, requested versus approved
        PTI.

    5. Counteroffer behavior
        feasibility pass / fail, exposure reduction, approved PTI target, approved Expected Loss cap.

    6. Reason-code coverage
        every row explainable; reason family aligns to final outcome.

    7. Archive persistence
        archived slice row count equals latest-run row count; archive grain is unique.

    8. Matched comparison
        baseline and challenger share the same Module 1 scenario and population; source fields match.

    9. Frontier and evidence capture
        Section 15 summarizes strategy tradeoffs; Section 16 stores evidence.

    10. Final campaign acceptance
        Section 17 validates the full campaign archive, registry, comparison, evidence, convention,
        and parameter audit state.

====================================================================================================
0.12 TERMINOLOGY AND INTERPRETATION BOUNDARIES
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
0.13 FINAL DECISION TAXONOMY
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
0.14 COUNTEROFFER DESIGN BOUNDARY
====================================================================================================

COUNTEROFFER is a distinct final decision_outcome.

A preliminary counteroffer route does not guarantee a final feasible counteroffer.

Final COUNTEROFFER is assigned only after approved exposure, approved PTI, and approved Expected Loss
feasibility have been evaluated.

More detailed counteroffer interpretation is captured through:
    decision_path,
    counteroffer feasibility diagnostics,
    exposure-treatment fields,
    simulated reason codes,
    QA outputs,
    frontier summaries,
    and evidence tables.

====================================================================================================
0.15 ARCHITECTURE OVERVIEW
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

The evidence tables preserve executive story, validation evidence, parameter snapshots, and product ×
score evidence for documentation.

The campaign registry maps technical scenario / strategy identifiers to run IDs and comparison IDs
used by the run campaign and future Validation Summary.

====================================================================================================
0.16 ARCHIVE GRAIN AND REPLACEMENT KEY
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
0.17 CAMPAIGN REGISTRY AND VALIDATION EVIDENCE IDS
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
    module1_scenario_set_name
    module1_scenario_name
    population_id
    strategy_set_name
    strategy_name
    strategy_version
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

====================================================================================================
0.18 PHYSICAL STAGE FLOW
====================================================================================================

Temporary parameter and selector tables:
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

Temporary comparison, validation, frontier, and evidence helpers:
    tmp_m2_source_selection_scope
    tmp_m2_campaign_registry_current_run_match
    tmp_m2_comparison_campaign_registry_active_match
    tmp_m2_strategy_comparison_params
    tmp_m2_strategy_comparison_readiness
    tmp_m2_strategy_comparison_matched_rows
    tmp_m2_strategy_comparison_source_consistency
    tmp_m2_validation_status_summary
    tmp_m2_strategy_frontier_executive_summary
    tmp_m2_current_run_key
    tmp_m2_current_run_story_params

Permanent outputs:
    credit_decisioning_sim.strategy_decisions
    credit_decisioning_sim.strategy_decisions_archive

Permanent evidence outputs:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

Permanent registry outputs:
    credit_decisioning_sim.strategy_run_campaign_registry
    credit_decisioning_sim.strategy_comparison_campaign_registry

====================================================================================================
0.19 SQL SECTION MAP
====================================================================================================

Section 0  — Executive Purpose, Module 2 Boundaries, Design Principles, and SQL Section Map

Section 1  — Schema Setup / Clean Rerun Reset
    Establishes schema availability, temporary-object cleanup, and clean latest-run behavior.

Section 2  — Strategy Profile, Product Policy Profile, Campaign Registry, and Run Selector Framework
    Defines active strategy controls, product-policy controls, run selectors, and campaign registry
    metadata used for campaign evidence traceability.

Section 3  — Fail-Fast Strategy Parameter, Source, Product Policy, Profile, and Registry Gatekeeper
    Validates selected run configuration, profile compatibility, threshold ordering, source input
    readiness, product policy completeness, archive controls, output conventions, and registry
    linkage.

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

Section 16.9 — Post-Campaign Frontier Evidence Synchronization
    After full campaign completion and a fresh Section 15 run, synchronizes frontier fields into
    persistent executive evidence.

Section 17 — Post-Campaign Acceptance, Export, Parameter Audit, and Strategy Effect Review
    Performs final campaign acceptance, exact parameter audit, strategy effect review, and export-
    ready evidence review.

====================================================================================================
0.20 PORTFOLIO ARTIFACT VALUE
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
    3. Drop temporary Module 2 selector, parameter, staging, comparison, validation, frontier, and
       evidence helper objects from prior executions.
    4. Drop the replaceable latest-run strategy output table for clean full-rerun behavior.
    5. Preserve the governed archive, campaign registry, comparison registry, and evidence tables.

WHEN TO RUN:
    Run Section 1 when executing the full Module 2 engine from the beginning.

WHEN NOT TO RUN:
    Do not run Section 1 by itself when the goal is only to:
        rerun Section 15 from the archive,
        run Section 16.9 frontier evidence synchronization,
        rerun Section 17 post-campaign acceptance,
        or refresh evidence from an already-materialized latest-run table.

    Section 1 drops:
        credit_decisioning_sim.strategy_decisions

    That table is the current latest-run output needed by later QA and evidence-capture steps.

PRESERVED GOVERNED OBJECTS:
    credit_decisioning_sim.strategy_decisions_archive
    credit_decisioning_sim.strategy_run_campaign_registry
    credit_decisioning_sim.strategy_comparison_campaign_registry
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

WHY THIS SECTION EXISTS:
    Module 2 is intentionally staged.

    A prior failed run, partial run, or exploratory run can leave temporary objects in the active
    session. Those temporary objects should not silently influence the next full strategy execution.

    Section 1 resets transient execution artifacts before the parameter framework, source-selection
    layer, decision stages, QA layers, frontier summary, and evidence capture are rebuilt.

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

    The archive should not be dropped during ordinary clean rerun setup.

WHY EVIDENCE AND REGISTRY TABLES ARE NOT DROPPED HERE:
    The campaign registry and Section 16 evidence tables support run-roadmap traceability,
    validation-summary linkage, parameter snapshots, executive story capture, and product × score
    evidence.

    They are persistent governance artifacts, not transient execution staging tables.

    Section 16 handles evidence replacement at the current run key. Section 1 should not destroy
    historical evidence or campaign registry metadata.

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

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
1.1 Create / reuse dedicated simulation schema.

Business purpose:
    Keep Module 2 outputs, archives, registry tables, and evidence tables organized under one
    governed simulation schema.

SQL purpose:
    Ensure the schema exists before any temporary or permanent Module 2 objects are referenced.

SQL teaching note:
    CREATE SCHEMA IF NOT EXISTS is non-destructive. It creates the schema only if needed and reuses it
    if it already exists.
-----------------------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;



/*-----------------------------------------------------------------------------------------------
1.2 Clean reset of temporary Module 2 selector, profile, and parameter objects.

Business purpose:
    Prevent stale run selectors, profile catalogs, or active parameter cards from prior runs from
    influencing the current strategy run.

Why this matters:
    Module 2 is parameter-driven.

    If an old temporary strategy row, product-policy row, or run selector remains in the session, the
    engine could appear to run successfully while using the wrong strategy configuration.

Boundary:
    These are temporary execution objects only.

    Persistent campaign registry and evidence tables are not dropped here.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_operator_run_selector;
DROP TABLE IF EXISTS tmp_m2_campaign_run_catalog;
DROP TABLE IF EXISTS tmp_m2_selected_run_config;
DROP TABLE IF EXISTS tmp_m2_strategy_profile_catalog;
DROP TABLE IF EXISTS tmp_m2_product_policy_profile_catalog;
DROP TABLE IF EXISTS tmp_m2_strategy_product_policy_compatibility;

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
    Each stage depends on the prior stage.

    Removing prior-stage artifacts prevents downstream logic from reading stale data if a rerun stops
    and restarts mid-script.
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

Section 13 helper interpretation:
    tmp_m2_strategy_comparison_params:
        canonical temporary comparison selector populated from the comparison campaign registry.

    tmp_m2_strategy_comparison_readiness:
        temporary readiness summary for the active baseline / challenger comparison.

    tmp_m2_strategy_comparison_matched_rows:
        temporary matched baseline / challenger row-level helper table.

    tmp_m2_strategy_comparison_source_consistency:
        temporary source-field consistency diagnostic for matched comparison.

Boundary:
    These temporary helper objects are not the governed archive itself.
    These temporary helper objects are not persistent evidence history.

    Section 12 controls archive persistence.
    Section 13 controls read-only matched comparison.
    Section 14 materializes validation status summary.
    Section 15 materializes strategy frontier summaries.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_source_selection_scope;
DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;
DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_registry;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_campaign_registry_map;
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

    If a user wants to rerun only Section 15, Section 16.9, or Section 17 from existing persisted
    outputs, this Section 1 latest-run reset should not be executed first.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;
```

I used the current attached Section 0 / Section 1 structure as the base and limited this patch to those two sections only. fileciteturn193file48 fileciteturn193file51
<!-- END_MESSAGE C038-M01413 -->


---

<a id="c038-m01414"></a>

### C038-M01414

**Andrew** · 2026-05-12T02:02:00.960000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01414 -->
Proceed with the full copy-paste patch: redesign of section 2.  DO NOT give me the updated section 3 in the next response. Only deliver the full copy paste patch for the redesigned section 2.
<!-- END_MESSAGE C038-M01414 -->


---

<a id="c038-m01420"></a>

### C038-M01420

**ChatGPT** · 2026-05-12T02:11:43.929575-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01420 -->
Below is **only the redesigned Section 2 full copy-paste patch**. It preserves the existing downstream contract around `tmp_module2_strategy_params` and `tmp_module2_product_policy_params`, while replacing the manually edited active parameter row with a profile-driven run selector, campaign catalog, product-policy catalog, and registry seed framework. fileciteturn193file1

```sql
/***************************************************************************************************
SECTION 2 — STRATEGY PROFILE, PRODUCT POLICY PROFILE, CAMPAIGN REGISTRY, AND RUN SELECTOR FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize the governed configuration layer for Module 2.

    Section 2 answers:

        "Which Module 2 run, strategy profile, product-policy profile, Module 1 source slice,
         archive behavior, registry IDs, and comparison IDs should this execution use?"

DESIGN CHANGE IN THIS VERSION:
    Section 2 is now profile-driven.

    Instead of manually editing 20+ numeric thresholds for each formal campaign run, the operator
    selects a governed Module 2 run ID:

        selected_module2_run_id = 'M2-01'

    The SQL then derives:
        Module 1 scenario set,
        Module 1 scenario name,
        population,
        strategy profile,
        product-policy profile,
        strategy name,
        strategy version,
        module2_run_id,
        strategy_run_id,
        active strategy parameter card,
        active product-policy parameter card,
        campaign registry row,
        and comparison registry rows.

WHY THIS MATTERS:
    The prior manual configuration pattern was powerful but operationally fragile.

    It was too easy to:
        carry stale commentary,
        type a wrong threshold,
        run the wrong strategy name,
        forget a registry update,
        or mismatch strategy and product-policy posture.

    The profile catalog keeps the engine flexible while making formal campaign runs safer.

BASELINE DEFAULT:
    BASELINE_STRATEGY is the default reference strategy.

CAMPAIGN CHALLENGER EXAMPLES:
    TIGHTER_SYNTHETIC_RISK_STRATEGY
    GROWTH_ORIENTED_STRATEGY
    TIGHTER_AFFORDABILITY_STRATEGY
    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
    MANUAL_REVIEW_REDUCTION_STRATEGY

CUSTOM USER FLEXIBILITY:
    Custom experimentation remains supported.

    Users who want to create their own strategy posture can use:
        run_mode = 'CUSTOM'

    and then edit the custom strategy and product-policy profile rows.

    Custom runs should be clearly labeled and should not be treated as formal campaign validation
    evidence unless the user intentionally adds governed registry support.

DOWNSTREAM CONTRACT PRESERVED:
    Later sections continue to consume:

        tmp_module2_strategy_params
        tmp_module2_product_policy_params

    This redesign changes how those tables are generated.
    It does not require later sections to read new profile-catalog tables directly.

SQL TEACHING POINT:
    This section demonstrates a common controlled-simulation pattern:

        operator selector
        → executable profile catalog
        → executable campaign catalog
        → generated active parameter card
        → fail-fast validation
        → downstream deterministic execution

***************************************************************************************************/



/***************************************************************************************************
SECTION 2.0 — LOCAL SECTION 2 RESET
****************************************************************************************************

PURPOSE:
    Allow Section 2 to be rerun safely within the same SQL session without requiring a full Section 1
    reset.

BUSINESS PURPOSE:
    If the operator changes selected_module2_run_id from one run to another, the old temporary
    selector, catalog, and parameter objects should not remain in the active session.

BOUNDARY:
    This local reset drops Section 2 temporary objects only.

    It does not drop:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive
        credit_decisioning_sim.strategy_run_campaign_registry
        credit_decisioning_sim.strategy_comparison_campaign_registry
        any Section 16 evidence table

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_operator_run_selector;
DROP TABLE IF EXISTS tmp_m2_strategy_profile_catalog;
DROP TABLE IF EXISTS tmp_m2_product_policy_profile_catalog;
DROP TABLE IF EXISTS tmp_m2_strategy_product_policy_compatibility;
DROP TABLE IF EXISTS tmp_m2_campaign_run_catalog;
DROP TABLE IF EXISTS tmp_m2_selected_run_config;

DROP TABLE IF EXISTS tmp_module2_strategy_params;
DROP TABLE IF EXISTS tmp_module2_product_policy_params;



/***************************************************************************************************
SECTION 2.1 — OPERATOR RUN SELECTOR
****************************************************************************************************

USER ACTION:
    For ordinary campaign operation, edit selected_module2_run_id.

DEFAULT:
    M2-01 / BASELINE_V2 / BASELINE_STRATEGY

STANDARD CAMPAIGN EXAMPLES:
    M2-01:
        Baseline strategy on BASELINE_V2.

    M2-02:
        Tighter synthetic-risk challenger on BASELINE_V2.

    M2-05:
        Counteroffer-first challenger on BASELINE_V2.

    M2-23:
        Product guardrails on UNSECURED_GROWTH_MIX.

    M2-29:
        Counteroffer-first strategy on HIGH_BALANCE_APPETITE.

    M2-36:
        Product guardrails on BROAD_LGD_STRESS.

CUSTOM MODE:
    Set run_mode = 'CUSTOM' only when building an exploratory run outside the formal 36-run campaign.

    In CUSTOM mode:
        custom Module 1 scenario fields must be populated,
        custom strategy and product-policy profile codes should be reviewed,
        campaign_registry_required_flag will be FALSE unless a custom registry path is later added.

SQL TEACHING POINT:
    This table is the operator control panel.

    Later CTEs join this selected run to the campaign catalog and profile catalogs to build the active
    parameter cards.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_operator_run_selector (
    active_selector_flag                         BOOLEAN NOT NULL,
    run_mode                                     TEXT NOT NULL,

    /***********************************************************************************************
    Standard campaign controls.
    ***********************************************************************************************/
    selected_module2_run_id                      TEXT,
    selected_comparison_group_id                 TEXT,

    /***********************************************************************************************
    Custom run controls.

    These are used only when run_mode = 'CUSTOM'.
    ***********************************************************************************************/
    custom_module1_run_id                        TEXT,
    custom_module2_run_id                        TEXT,
    custom_run_sequence_number                   INTEGER,

    custom_module1_scenario_set_name             TEXT,
    custom_module1_scenario_name                 TEXT,
    custom_population_id                         TEXT,

    custom_strategy_profile_code                 TEXT,
    custom_product_policy_profile_code           TEXT,

    custom_showcase_id                           TEXT,
    custom_showcase_name                         TEXT,
    custom_comparison_group_id                   TEXT,
    custom_validation_evidence_group_id          TEXT,

    custom_module1_parameter_family_changed      TEXT,
    custom_module1_parameter_change_summary      TEXT,
    custom_module2_strategy_family_changed       TEXT,
    custom_module2_parameter_change_summary      TEXT,
    custom_expected_storyline                    TEXT,
    custom_validation_summary_section_hint        TEXT,
    custom_readme_storyline_label                TEXT,
    custom_linkedin_post_sequence                INTEGER,
    custom_parameter_change_reason               TEXT
) ON COMMIT PRESERVE ROWS;


INSERT INTO tmp_m2_operator_run_selector (
    active_selector_flag,
    run_mode,
    selected_module2_run_id,
    selected_comparison_group_id
)
VALUES (
    TRUE,
    'STANDARD_CAMPAIGN',
    'M2-01',
    'CG01'
);



/***************************************************************************************************
SECTION 2.2 — EXECUTABLE STRATEGY PROFILE CATALOG
****************************************************************************************************

PURPOSE:
    Store governed strategy-level profiles used by the formal campaign and custom experimentation.

COMMENT STANDARD USED BELOW:
    Parameter family:
        what the fields control.

    Baseline default:
        BASELINE_STRATEGY value.

    Campaign challenger examples:
        strategy profile values used in the formal campaign.

    Downstream use:
        where later SQL consumes the field.

    Edit guidance:
        how to tune the profile safely.

KEY STRATEGY PARAMETER FAMILIES:

    Synthetic estimated-risk thresholds:
        Fields:
            approve_max_estimated_pd_proxy
            counteroffer_max_estimated_pd_proxy
            review_max_estimated_pd_proxy
            decline_min_estimated_pd_proxy

        Baseline default:
            BASELINE_STRATEGY = 0.080000 / 0.160000 / 0.300000 / 0.350000

        Campaign challenger examples:
            TIGHTER_SYNTHETIC_RISK_STRATEGY = 0.060000 / 0.120000 / 0.250000 / 0.300000
            GROWTH_ORIENTED_STRATEGY        = 0.100000 / 0.200000 / 0.350000 / 0.400000

        Credit risk concept:
            Lower values tighten synthetic-risk appetite.
            Higher values expand eligibility and access.

    Global PTI thresholds:
        Fields:
            global_approve_max_pti
            global_review_max_pti
            global_decline_min_pti

        Baseline default:
            BASELINE_STRATEGY = 0.250000 / 0.400000 / 0.550000

        Campaign challenger examples:
            GROWTH_ORIENTED_STRATEGY       = 0.280000 / 0.430000 / 0.580000
            TIGHTER_AFFORDABILITY_STRATEGY = 0.220000 / 0.350000 / 0.500000

        Credit risk concept:
            PTI is the payment-burden bridge between structure and affordability.

    DTI thresholds:
        Fields:
            approve_max_dti
            review_max_dti
            decline_min_dti

        Baseline default:
            BASELINE_STRATEGY = 0.430000 / 0.600000 / 0.600000

        Campaign challenger examples:
            GROWTH_ORIENTED_STRATEGY       = 0.460000 / 0.630000 / 0.630000
            TIGHTER_AFFORDABILITY_STRATEGY = 0.400000 / 0.550000 / 0.550000

        Credit risk concept:
            DTI is existing-obligation capacity. In Module 2 V1.0, it is not directly corrected by
            counteroffer exposure reduction.

    Failed counteroffer resolution:
        Field:
            failed_counteroffer_resolution

        Baseline default:
            BASELINE_STRATEGY = MANUAL_REVIEW

        Campaign challenger example:
            MANUAL_REVIEW_REDUCTION_STRATEGY = DECLINE

        Credit risk / operations concept:
            This isolates operational review burden from positive-offer economics.

SQL TEACHING POINT:
    This catalog is executable documentation.

    The values are not merely comments. They are the values used to generate the active strategy
    parameter card.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_strategy_profile_catalog
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM (
    VALUES
        /*******************************************************************************************
        BASELINE_STRATEGY_PROFILE

        Baseline default:
            The accepted V1.0 reference strategy.

        Product policy:
            BASELINE_PRODUCT_POLICY

        Expected behavior:
            Establishes the reference access, counteroffer, manual-review, decline, approved amount,
            and approved Expected Loss pattern.
        *******************************************************************************************/
        (
            'BASELINE_STRATEGY_PROFILE'::TEXT,
            'BASELINE_STRATEGY'::TEXT,
            'BASELINE_PRODUCT_POLICY'::TEXT,
            'BASELINE'::TEXT,
            'Module 2 baseline strategy using accepted V1.0 defaults.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.080000::NUMERIC(12,6),
            0.160000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),

            0.250000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.430000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        ),

        /*******************************************************************************************
        TIGHTER_SYNTHETIC_RISK_PROFILE

        Baseline default comparison:
            Baseline synthetic-risk thresholds:
                0.080000 / 0.160000 / 0.300000 / 0.350000

            Tighter risk thresholds:
                0.060000 / 0.120000 / 0.250000 / 0.300000

        Product policy:
            BASELINE_PRODUCT_POLICY

        Expected behavior:
            Lower offer exposure and approved Expected Loss.
            Higher decline rate.
            Improved offered-population synthetic estimated-risk profile.
        *******************************************************************************************/
        (
            'TIGHTER_SYNTHETIC_RISK_PROFILE'::TEXT,
            'TIGHTER_SYNTHETIC_RISK_STRATEGY'::TEXT,
            'BASELINE_PRODUCT_POLICY'::TEXT,
            'RISK_DISCIPLINE'::TEXT,
            'Tightens synthetic estimated-risk thresholds while keeping baseline product policy.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.060000::NUMERIC(12,6),
            0.120000::NUMERIC(12,6),
            0.250000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),

            0.250000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.430000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        ),

        /*******************************************************************************************
        GROWTH_ORIENTED_PROFILE

        Baseline default comparison:
            Baseline synthetic-risk thresholds:
                0.080000 / 0.160000 / 0.300000 / 0.350000

            Growth thresholds:
                0.100000 / 0.200000 / 0.350000 / 0.400000

        Product policy:
            GROWTH_PRODUCT_POLICY

        Expected behavior:
            Higher offer exposure and approved amount.
            Higher approved Expected Loss tradeoff.
        *******************************************************************************************/
        (
            'GROWTH_ORIENTED_PROFILE'::TEXT,
            'GROWTH_ORIENTED_STRATEGY'::TEXT,
            'GROWTH_PRODUCT_POLICY'::TEXT,
            'GROWTH'::TEXT,
            'Expands access and approved exposure using growth-oriented thresholds and product caps.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.100000::NUMERIC(12,6),
            0.200000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),

            0.280000::NUMERIC(12,6),
            0.430000::NUMERIC(12,6),
            0.580000::NUMERIC(12,6),

            0.460000::NUMERIC(12,6),
            0.630000::NUMERIC(12,6),
            0.630000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        ),

        /*******************************************************************************************
        TIGHTER_AFFORDABILITY_PROFILE

        Baseline default comparison:
            Baseline global PTI:
                0.250000 / 0.400000 / 0.550000

            Affordability-tight global PTI:
                0.220000 / 0.350000 / 0.500000

        Product policy:
            AFFORDABILITY_TIGHT_PRODUCT_POLICY

        Expected behavior:
            Lower approved exposure and approved PTI.
            More payment-burden discipline under rate-stress scenarios.
        *******************************************************************************************/
        (
            'TIGHTER_AFFORDABILITY_PROFILE'::TEXT,
            'TIGHTER_AFFORDABILITY_STRATEGY'::TEXT,
            'AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT,
            'AFFORDABILITY_DISCIPLINE'::TEXT,
            'Tightens affordability posture through global and product PTI controls.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.080000::NUMERIC(12,6),
            0.160000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),

            0.220000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),
            0.500000::NUMERIC(12,6),

            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        ),

        /*******************************************************************************************
        COUNTEROFFER_FIRST_PROFILE

        Baseline default comparison:
            Global risk thresholds remain baseline.

        Product policy:
            COUNTEROFFER_FIRST_PRODUCT_POLICY

        Expected behavior:
            More final COUNTEROFFER outcomes.
            Lower approved amount.
            Lower approved PTI.
            Lower approved Expected Loss on reduced-exposure offers.
        *******************************************************************************************/
        (
            'COUNTEROFFER_FIRST_PROFILE'::TEXT,
            'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'::TEXT,
            'COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT,
            'COUNTEROFFER_MANAGEMENT'::TEXT,
            'Emphasizes reduced-exposure treatment for exposure and affordability management.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.080000::NUMERIC(12,6),
            0.160000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),

            0.250000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.430000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        ),

        /*******************************************************************************************
        PRODUCT_GUARDRAIL_PROFILE

        Baseline default comparison:
            Global risk thresholds remain baseline.

        Product policy:
            PRODUCT_GUARDRAIL_PRODUCT_POLICY

        Expected behavior:
            Tightens unsecured personal loan and revolving line.
            Leaves mortgage, HELOC, and auto at baseline product-policy values.
        *******************************************************************************************/
        (
            'PRODUCT_GUARDRAIL_PROFILE'::TEXT,
            'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'::TEXT,
            'PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT,
            'PRODUCT_GUARDRAILS'::TEXT,
            'Applies tighter product guardrails to unsecured personal loan and revolving line.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.080000::NUMERIC(12,6),
            0.160000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),

            0.250000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.430000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        ),

        /*******************************************************************************************
        MANUAL_REVIEW_REDUCTION_PROFILE

        Baseline default comparison:
            Strategy thresholds and product policy remain baseline.

        Key change:
            failed_counteroffer_resolution = DECLINE

        Expected behavior:
            Positive-offer economics remain unchanged.
            Manual-review rate falls.
            Decline rate rises by the same unresolved-case movement.
        *******************************************************************************************/
        (
            'MANUAL_REVIEW_REDUCTION_PROFILE'::TEXT,
            'MANUAL_REVIEW_REDUCTION_STRATEGY'::TEXT,
            'BASELINE_PRODUCT_POLICY'::TEXT,
            'REVIEW_BURDEN_REDUCTION'::TEXT,
            'Routes failed counteroffers to DECLINE to reduce unresolved manual review.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_BASELINE_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            TRUE::BOOLEAN,
            'ARCHIVE'::TEXT,
            TRUE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.080000::NUMERIC(12,6),
            0.160000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),

            0.250000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.430000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'DECLINE'::TEXT
        ),

        /*******************************************************************************************
        CUSTOM_USER_DEFINED_STRATEGY_PROFILE

        Purpose:
            Exploratory profile for user-defined tests.

        Starting point:
            Baseline values.

        Edit guidance:
            Change only the values required by the business question.
            Label the custom run clearly in Section 2.1.
            Treat custom runs as exploratory unless registry support is deliberately added.
        *******************************************************************************************/
        (
            'CUSTOM_USER_DEFINED_STRATEGY_PROFILE'::TEXT,
            'CUSTOM_USER_DEFINED_STRATEGY'::TEXT,
            'CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT,
            'CUSTOM'::TEXT,
            'User-defined exploratory strategy profile. Edit deliberately and document why.'::TEXT,

            'MODULE2_V1_0'::TEXT,
            'MODULE2_CUSTOM_STRATEGY_SET'::TEXT,
            'V1_0'::TEXT,

            FALSE::BOOLEAN,
            'ARCHIVE'::TEXT,
            FALSE::BOOLEAN,
            'STRATEGY_SCENARIO_ONLY'::TEXT,

            0.080000::NUMERIC(12,6),
            0.160000::NUMERIC(12,6),
            0.300000::NUMERIC(12,6),
            0.350000::NUMERIC(12,6),

            0.250000::NUMERIC(12,6),
            0.400000::NUMERIC(12,6),
            0.550000::NUMERIC(12,6),

            0.430000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),
            0.600000::NUMERIC(12,6),

            0.050000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            4::INTEGER,

            TRUE::BOOLEAN,
            0.850000::NUMERIC(12,6),

            TRUE::BOOLEAN,
            580::INTEGER,

            'APPROVED_AS_REQUESTED'::TEXT,
            TRUE::BOOLEAN,
            TRUE::BOOLEAN,
            'NULL_UNRESOLVED'::TEXT,
            'ZERO'::TEXT,
            'ZERO'::TEXT,
            'NULL_UNRESOLVED'::TEXT,
            FALSE::BOOLEAN,

            'MANUAL_REVIEW'::TEXT
        )
) AS v(
    strategy_profile_code,
    strategy_name,
    default_product_policy_profile_code,
    strategy_family_code,
    strategy_profile_description,

    module2_model_version,
    strategy_set_name,
    strategy_version,

    standard_campaign_profile_flag,
    default_module1_input_source,
    default_archive_run_flag,
    default_strategy_archive_reset_mode,

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
);



/***************************************************************************************************
SECTION 2.3 — EXECUTABLE PRODUCT-POLICY PROFILE CATALOG
****************************************************************************************************

PURPOSE:
    Store exact product-policy values for governed campaign product-policy profiles.

SUPPORTED PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

PRODUCT-POLICY PROFILE SUMMARY:
    BASELINE_PRODUCT_POLICY:
        Default product policy.

    GROWTH_PRODUCT_POLICY:
        Raises selected approved amount caps and approved Expected Loss caps.

    AFFORDABILITY_TIGHT_PRODUCT_POLICY:
        Tightens product PTI thresholds and counteroffer target PTI.

    COUNTEROFFER_FIRST_PRODUCT_POLICY:
        Makes reduced-exposure treatment more active and more feasible.

    PRODUCT_GUARDRAIL_PRODUCT_POLICY:
        Keeps MORTGAGE, HELOC, and AUTO_LOAN at baseline.
        Tightens UNSECURED_PERSONAL_LOAN and REVOLVING_LINE.

    CUSTOM_USER_DEFINED_PRODUCT_POLICY:
        User-editable exploratory product-policy profile starting from baseline values.

CREDIT RISK CONCEPT:
    Product-specific policy matters because product type affects:
        requested exposure,
        payment burden,
        LGD,
        requested Expected Loss,
        counteroffer feasibility,
        approved exposure,
        and approved Expected Loss.

SQL TEACHING POINT:
    A product-policy catalog prevents a user from scrolling through one long positional VALUES block
    to figure out which number belongs to which product variable.

    Each row below is executable documentation:
        product_policy_profile_code + product_type + named values.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_product_policy_profile_catalog
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM (
    VALUES
        /*******************************************************************************************
        BASELINE_PRODUCT_POLICY
        *******************************************************************************************/
        ('BASELINE_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),0.320000::NUMERIC(12,6),10000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),800000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
        ('BASELINE_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.220000::NUMERIC(12,6),8000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),175000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
        ('BASELINE_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.380000::NUMERIC(12,6),0.160000::NUMERIC(12,6),3500.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),3000.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),65000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('BASELINE_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.150000::NUMERIC(12,6),0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.130000::NUMERIC(12,6),3000.00::NUMERIC(18,2),6000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),2500.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),35000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('BASELINE_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.120000::NUMERIC(12,6),0.200000::NUMERIC(12,6),0.300000::NUMERIC(12,6),0.100000::NUMERIC(12,6),2000.00::NUMERIC(18,2),4000.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),1800.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),

        /*******************************************************************************************
        GROWTH_PRODUCT_POLICY

        Strategy tie-in:
            Used by GROWTH_ORIENTED_STRATEGY.

        Business intent:
            Expand approved exposure capacity while making the approved Expected Loss tradeoff
            measurable.
        *******************************************************************************************/
        ('GROWTH_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),0.320000::NUMERIC(12,6),10000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),11000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),880000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
        ('GROWTH_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.220000::NUMERIC(12,6),8000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),7700.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),192500.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
        ('GROWTH_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.380000::NUMERIC(12,6),0.160000::NUMERIC(12,6),3500.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),3300.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),71500.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('GROWTH_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.150000::NUMERIC(12,6),0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.130000::NUMERIC(12,6),3000.00::NUMERIC(18,2),6000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),2750.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),38500.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('GROWTH_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.120000::NUMERIC(12,6),0.200000::NUMERIC(12,6),0.300000::NUMERIC(12,6),0.100000::NUMERIC(12,6),2000.00::NUMERIC(18,2),4000.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),1980.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),22000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),

        /*******************************************************************************************
        AFFORDABILITY_TIGHT_PRODUCT_POLICY

        Strategy tie-in:
            Used by TIGHTER_AFFORDABILITY_STRATEGY.

        Business intent:
            Tighten product-level PTI posture and lower counteroffer target PTI.
        *******************************************************************************************/
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.320000::NUMERIC(12,6),0.420000::NUMERIC(12,6),0.520000::NUMERIC(12,6),0.290000::NUMERIC(12,6),10000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),800000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.220000::NUMERIC(12,6),0.320000::NUMERIC(12,6),0.420000::NUMERIC(12,6),0.190000::NUMERIC(12,6),8000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),175000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.160000::NUMERIC(12,6),0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.140000::NUMERIC(12,6),3500.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),3000.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),65000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.130000::NUMERIC(12,6),0.220000::NUMERIC(12,6),0.320000::NUMERIC(12,6),0.110000::NUMERIC(12,6),3000.00::NUMERIC(18,2),6000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),2500.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),35000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.100000::NUMERIC(12,6),0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.080000::NUMERIC(12,6),2000.00::NUMERIC(18,2),4000.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),1800.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),

        /*******************************************************************************************
        COUNTEROFFER_FIRST_PRODUCT_POLICY

        Strategy tie-in:
            Used by COUNTEROFFER_FIRST_EXPOSURE_STRATEGY.

        Business intent:
            Make reduced-exposure treatment more active by lowering selected approved EL caps,
            product caps, target PTI, and allowing more exposure reduction.
        *******************************************************************************************/
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.330000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),0.300000::NUMERIC(12,6),8500.00::NUMERIC(18,2),18000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),700000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.600000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.235000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.200000::NUMERIC(12,6),6800.00::NUMERIC(18,2),14500.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),5600.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),150000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.350000::NUMERIC(12,6),0.600000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.170000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.380000::NUMERIC(12,6),0.145000::NUMERIC(12,6),3000.00::NUMERIC(18,2),6300.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),2400.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),57500.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.140000::NUMERIC(12,6),0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.115000::NUMERIC(12,6),2500.00::NUMERIC(18,2),5400.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),2000.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.600000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.110000::NUMERIC(12,6),0.200000::NUMERIC(12,6),0.300000::NUMERIC(12,6),0.090000::NUMERIC(12,6),1700.00::NUMERIC(18,2),3600.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),1400.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),17500.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.600000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),

        /*******************************************************************************************
        PRODUCT_GUARDRAIL_PRODUCT_POLICY

        Strategy tie-in:
            Used by PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY.

        Business intent:
            Keep secured and auto products at baseline.
            Tighten unsecured personal loan and revolving line.
        *******************************************************************************************/
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),0.320000::NUMERIC(12,6),10000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),800000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.220000::NUMERIC(12,6),8000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),175000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.380000::NUMERIC(12,6),0.160000::NUMERIC(12,6),3500.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),3000.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),65000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.130000::NUMERIC(12,6),0.220000::NUMERIC(12,6),0.320000::NUMERIC(12,6),0.110000::NUMERIC(12,6),2500.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),8500.00::NUMERIC(18,2),2000.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),27500.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.100000::NUMERIC(12,6),0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.080000::NUMERIC(12,6),1500.00::NUMERIC(18,2),3200.00::NUMERIC(18,2),6500.00::NUMERIC(18,2),1400.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),

        /*******************************************************************************************
        CUSTOM_USER_DEFINED_PRODUCT_POLICY

        Starting point:
            Baseline values.

        Edit guidance:
            Use for custom experiments only.
        *******************************************************************************************/
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),0.320000::NUMERIC(12,6),10000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),800000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.220000::NUMERIC(12,6),8000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),175000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.380000::NUMERIC(12,6),0.160000::NUMERIC(12,6),3500.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),3000.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),65000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.150000::NUMERIC(12,6),0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.130000::NUMERIC(12,6),3000.00::NUMERIC(18,2),6000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),2500.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),35000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.120000::NUMERIC(12,6),0.200000::NUMERIC(12,6),0.300000::NUMERIC(12,6),0.100000::NUMERIC(12,6),2000.00::NUMERIC(18,2),4000.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),1800.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2))
) AS v(
    product_policy_profile_code,
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
);



/***************************************************************************************************
SECTION 2.4 — STRATEGY ↔ PRODUCT-POLICY COMPATIBILITY MAP
****************************************************************************************************

PURPOSE:
    Define which product-policy profile each governed strategy profile should use.

WHY THIS MATTERS:
    A strategy name alone is not enough.

    Examples:
        PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY should use PRODUCT_GUARDRAIL_PRODUCT_POLICY.
        COUNTEROFFER_FIRST_EXPOSURE_STRATEGY should use COUNTEROFFER_FIRST_PRODUCT_POLICY.
        TIGHTER_AFFORDABILITY_STRATEGY should use AFFORDABILITY_TIGHT_PRODUCT_POLICY.

    Section 3 will validate these pairings before applicant-level logic runs.

SQL TEACHING POINT:
    This map is a small control table.

    It makes compatibility testable instead of relying on comments alone.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_strategy_product_policy_compatibility
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM (
    VALUES
        ('BASELINE_STRATEGY_PROFILE'::TEXT, 'BASELINE_STRATEGY'::TEXT, 'BASELINE_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('TIGHTER_SYNTHETIC_RISK_PROFILE'::TEXT, 'TIGHTER_SYNTHETIC_RISK_STRATEGY'::TEXT, 'BASELINE_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('GROWTH_ORIENTED_PROFILE'::TEXT, 'GROWTH_ORIENTED_STRATEGY'::TEXT, 'GROWTH_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('TIGHTER_AFFORDABILITY_PROFILE'::TEXT, 'TIGHTER_AFFORDABILITY_STRATEGY'::TEXT, 'AFFORDABILITY_TIGHT_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('COUNTEROFFER_FIRST_PROFILE'::TEXT, 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'::TEXT, 'COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('PRODUCT_GUARDRAIL_PROFILE'::TEXT, 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'::TEXT, 'PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('MANUAL_REVIEW_REDUCTION_PROFILE'::TEXT, 'MANUAL_REVIEW_REDUCTION_STRATEGY'::TEXT, 'BASELINE_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
        ('CUSTOM_USER_DEFINED_STRATEGY_PROFILE'::TEXT, 'CUSTOM_USER_DEFINED_STRATEGY'::TEXT, 'CUSTOM_USER_DEFINED_PRODUCT_POLICY'::TEXT, FALSE::BOOLEAN)
) AS v(
    strategy_profile_code,
    strategy_name,
    required_product_policy_profile_code,
    formal_campaign_compatible_flag
);



/***************************************************************************************************
SECTION 2.5 — FORMAL MODULE 2 CAMPAIGN RUN CATALOG
****************************************************************************************************

PURPOSE:
    Define the formal 36-run Module 2 campaign roadmap.

WHY THIS EXISTS:
    The campaign catalog connects:
        Module 1 scenario slice
        → Module 2 strategy profile
        → product-policy profile
        → run ID
        → comparison group
        → validation evidence group
        → README / LinkedIn / Validation Summary storyline

RUN-ID DESIGN:
    module2_run_id is derived from run_sequence_number:

        'M2-' || LPAD(run_sequence_number::TEXT, 2, '0')

    strategy_run_id is generated later from:

        module2_run_id || '_' || strategy_name || '_' || strategy_version || '_RUN'

WHY RUN IDs ARE DETERMINISTIC:
    Reruns should preserve the same run ID.

    Run IDs should not be generated from database max values because reruns, repair runs, or deleted
    evidence rows could otherwise shift the campaign identity.

CAMPAIGN SCENARIO FAMILIES:
    SC01 — Baseline Strategy Frontier
    SC02 — Rate Environment Sensitivity
    SC03 — Credit Box Sensitivity
    SC04 — Portfolio Mix Sensitivity
    SC05 — Exposure Intensity Sensitivity
    SC06 — LGD Severity Sensitivity

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_campaign_run_catalog
ON COMMIT PRESERVE ROWS
AS
SELECT
    c.*,

    /***********************************************************************************************
    Deterministic Module 2 run ID.

    This derives M2-01 through M2-36 from run_sequence_number.
    ***********************************************************************************************/
    'M2-' || LPAD(c.run_sequence_number::TEXT, 2, '0') AS module2_run_id

FROM (
    VALUES
        /*******************************************************************************************
        SC01 — Baseline Strategy Frontier.

        Purpose:
            Compare multiple Module 2 strategies on the same Module 1 BASELINE_V2 population.

        Interpretation:
            This is the cleanest pure Module 2 strategy frontier because the upstream population is
            held constant.
        *******************************************************************************************/
        (1::INTEGER,'M1-01'::TEXT,'SC01'::TEXT,'Baseline Strategy Frontier'::TEXT,NULL::TEXT,'VE01'::TEXT,'MODULE1_V2_BASELINE_SET'::TEXT,'BASELINE_V2'::TEXT,'BASE_POPULATION_V1'::TEXT,'BASELINE_STRATEGY_PROFILE'::TEXT,'BASELINE_PRODUCT_POLICY'::TEXT,'BASELINE'::TEXT,'Module 1 baseline scenario using accepted V2.0 defaults.'::TEXT,'BASELINE'::TEXT,'Module 2 baseline strategy using accepted V1.0 defaults.'::TEXT,'Establish baseline Module 2 behavior on BASELINE_V2.'::TEXT,'Baseline strategy evidence'::TEXT,'Baseline strategy reference'::TEXT,1::INTEGER,TRUE::BOOLEAN),

        (2,'M1-01','SC01','Baseline Strategy Frontier','CG01','VE02','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','TIGHTER_SYNTHETIC_RISK_PROFILE','BASELINE_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario using accepted V2.0 defaults.','RISK_DISCIPLINE','Tighter synthetic estimated-risk thresholds.','Demonstrate risk-discipline tradeoff: lower simulated offer exposure and approved Expected Loss, with higher decline rate.','Tighter risk evidence','Tighter synthetic-risk challenger',2,TRUE),

        (3,'M1-01','SC01','Baseline Strategy Frontier','CG02','VE03','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','GROWTH_ORIENTED_PROFILE','GROWTH_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario using accepted V2.0 defaults.','GROWTH','Growth-oriented thresholds and product policy.','Demonstrate growth tradeoff: higher simulated offer exposure and approved amount, with measurable risk impact.','Growth strategy evidence','Growth-oriented challenger',3,TRUE),

        (4,'M1-01','SC01','Baseline Strategy Frontier','CG03','VE04','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','TIGHTER_AFFORDABILITY_PROFILE','AFFORDABILITY_TIGHT_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario using accepted V2.0 defaults.','AFFORDABILITY_DISCIPLINE','Tighter affordability thresholds and product PTI policy.','Demonstrate affordability discipline and how tighter PTI guardrails affect offer exposure, counteroffers, and review burden.','Affordability evidence','Tighter affordability challenger',4,TRUE),

        (5,'M1-01','SC01','Baseline Strategy Frontier','CG04','VE05','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','COUNTEROFFER_FIRST_PROFILE','COUNTEROFFER_FIRST_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario using accepted V2.0 defaults.','COUNTEROFFER_MANAGEMENT','Counteroffer-first product policy.','Demonstrate exposure-management tradeoff through counteroffer feasibility and approved exposure reduction.','Counteroffer evidence','Counteroffer-first challenger',5,TRUE),

        (6,'M1-01','SC01','Baseline Strategy Frontier','CG05','VE06','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario using accepted V2.0 defaults.','PRODUCT_GUARDRAILS','Product guardrails for unsecured and revolving exposure.','Demonstrate product-specific risk guardrails and where product-level strategy controls change outcomes.','Product guardrail evidence','Product guardrail challenger',6,TRUE),

        (7,'M1-01','SC01','Baseline Strategy Frontier','CG06','VE07','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','MANUAL_REVIEW_REDUCTION_PROFILE','BASELINE_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario using accepted V2.0 defaults.','REVIEW_BURDEN_REDUCTION','Failed counteroffers resolve to decline.','Demonstrate operational review-burden reduction and the corresponding no-offer tradeoff.','Manual review reduction evidence','Manual-review reduction challenger',7,TRUE),


        /*******************************************************************************************
        SC02 — Rate Environment Sensitivity.

        Purpose:
            Evaluate how upstream rate changes affect affordability, approved exposure, and strategy
            performance.
        *******************************************************************************************/
        (8,'M1-02','SC02','Rate Environment Sensitivity',NULL,'VE08','MODULE1_V2_BASELINE_SET','RATE_UP_200BP','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 200 basis-point rate-up scenario.','BASELINE','Baseline strategy under rate-up 200bp.','Evaluate baseline strategy behavior under a 200 basis-point upstream rate-stress scenario.','Rate-up 200 baseline evidence','Rate-up 200 baseline',8,TRUE),

        (9,'M1-03','SC02','Rate Environment Sensitivity',NULL,'VE09','MODULE1_V2_BASELINE_SET','RATE_DOWN_200BP','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 200 basis-point rate-down scenario.','BASELINE','Baseline strategy under rate-down 200bp.','Evaluate baseline strategy behavior under 200 basis-point rate relief.','Rate-down baseline evidence','Rate-down 200 baseline',9,TRUE),

        (10,'M1-04','SC02','Rate Environment Sensitivity',NULL,'VE10','MODULE1_V2_BASELINE_SET','RATE_UP_300BP','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 300 basis-point rate-up scenario.','BASELINE','Baseline strategy under rate-up 300bp.','Evaluate baseline strategy behavior under a 300 basis-point upstream rate-stress scenario.','Rate-up 300 baseline evidence','Rate-up 300 baseline',10,TRUE),

        (11,'M1-02','SC02','Rate Environment Sensitivity','CG07','VE11','MODULE1_V2_BASELINE_SET','RATE_UP_200BP','BASE_POPULATION_V1','TIGHTER_AFFORDABILITY_PROFILE','AFFORDABILITY_TIGHT_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 200 basis-point rate-up scenario.','AFFORDABILITY_DISCIPLINE','Tighter affordability strategy under 200bp rate stress.','Evaluate tighter affordability discipline under 200bp rate stress.','Rate-up 200 affordability evidence','Rate-up 200 affordability challenger',11,TRUE),

        (12,'M1-04','SC02','Rate Environment Sensitivity','CG08','VE12','MODULE1_V2_BASELINE_SET','RATE_UP_300BP','BASE_POPULATION_V1','TIGHTER_AFFORDABILITY_PROFILE','AFFORDABILITY_TIGHT_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 300 basis-point rate-up scenario.','AFFORDABILITY_DISCIPLINE','Tighter affordability strategy under 300bp rate stress.','Evaluate tighter affordability discipline under 300bp rate stress.','Rate-up 300 affordability evidence','Rate-up 300 affordability challenger',12,TRUE),

        (13,'M1-03','SC02','Rate Environment Sensitivity','CG09','VE13','MODULE1_V2_BASELINE_SET','RATE_DOWN_200BP','BASE_POPULATION_V1','GROWTH_ORIENTED_PROFILE','GROWTH_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 200 basis-point rate-down scenario.','GROWTH','Growth strategy under rate relief.','Evaluate growth strategy under rate relief.','Rate-down growth evidence','Rate-down growth challenger',13,TRUE),


        /*******************************************************************************************
        SC03 — Credit Box Sensitivity.

        Purpose:
            Evaluate strategy behavior under prime-growth, near-prime expansion, and credit-stress
            score-mix environments.
        *******************************************************************************************/
        (14,'M1-05','SC03','Credit Box Sensitivity',NULL,'VE14','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','CREDIT_BOX_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Credit-box baseline reference scenario.','BASELINE','Baseline strategy on credit-box reference.','Establish credit-box reference behavior.','Credit-box reference evidence','Credit-box reference baseline',14,TRUE),

        (15,'M1-06','SC03','Credit Box Sensitivity',NULL,'VE15','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','PRIME_GROWTH_SCORE_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Prime-growth score-mix scenario.','BASELINE','Baseline strategy on prime-growth score mix.','Evaluate baseline under stronger score mix.','Prime growth evidence','Prime growth baseline',15,TRUE),

        (16,'M1-07','SC03','Credit Box Sensitivity',NULL,'VE16','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','NEAR_PRIME_EXPANSION_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Near-prime expansion score-mix scenario.','BASELINE','Baseline strategy on near-prime expansion.','Evaluate baseline under near-prime expansion.','Near-prime baseline evidence','Near-prime expansion baseline',16,TRUE),

        (17,'M1-07','SC03','Credit Box Sensitivity','CG10','VE17','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','NEAR_PRIME_EXPANSION_MIX','BASE_POPULATION_V1','TIGHTER_SYNTHETIC_RISK_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Near-prime expansion score-mix scenario.','RISK_DISCIPLINE','Tighter synthetic-risk strategy under near-prime expansion.','Evaluate risk discipline under near-prime expansion.','Near-prime tighter risk evidence','Near-prime tighter risk challenger',17,TRUE),

        (18,'M1-07','SC03','Credit Box Sensitivity','CG11','VE18','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','NEAR_PRIME_EXPANSION_MIX','BASE_POPULATION_V1','COUNTEROFFER_FIRST_PROFILE','COUNTEROFFER_FIRST_PRODUCT_POLICY','CREDIT_BOX','Near-prime expansion score-mix scenario.','COUNTEROFFER_MANAGEMENT','Counteroffer-first strategy under near-prime expansion.','Evaluate counteroffer-first exposure management under near-prime expansion.','Near-prime counteroffer evidence','Near-prime counteroffer challenger',18,TRUE),

        (19,'M1-08','SC03','Credit Box Sensitivity',NULL,'VE19','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','CREDIT_STRESS_SCORE_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Credit-stress score-mix scenario.','BASELINE','Baseline strategy on credit-stress score mix.','Evaluate baseline under credit stress.','Credit stress baseline evidence','Credit stress baseline',19,TRUE),

        (20,'M1-08','SC03','Credit Box Sensitivity','CG12','VE20','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','CREDIT_STRESS_SCORE_MIX','BASE_POPULATION_V1','TIGHTER_SYNTHETIC_RISK_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Credit-stress score-mix scenario.','RISK_DISCIPLINE','Tighter risk strategy under credit stress.','Evaluate risk discipline under credit stress.','Credit stress tighter risk evidence','Credit stress risk challenger',20,TRUE),


        /*******************************************************************************************
        SC04 — Portfolio Mix Sensitivity.

        Purpose:
            Evaluate how product-mix changes interact with baseline strategy and product guardrails.
        *******************************************************************************************/
        (21,'M1-09','SC04','Portfolio Mix Sensitivity',NULL,'VE21','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','PORTFOLIO_MIX_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Portfolio-mix baseline reference scenario.','BASELINE','Baseline strategy on portfolio-mix reference.','Establish product-mix reference behavior.','Portfolio mix reference evidence','Portfolio mix reference baseline',21,TRUE),

        (22,'M1-10','SC04','Portfolio Mix Sensitivity',NULL,'VE22','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','UNSECURED_GROWTH_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Unsecured growth product-mix scenario.','BASELINE','Baseline strategy on unsecured growth mix.','Evaluate baseline under unsecured growth.','Unsecured growth baseline evidence','Unsecured growth baseline',22,TRUE),

        (23,'M1-10','SC04','Portfolio Mix Sensitivity','CG13','VE23','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','UNSECURED_GROWTH_MIX','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','PRODUCT_MIX','Unsecured growth product-mix scenario.','PRODUCT_GUARDRAILS','Product guardrails under unsecured growth.','Evaluate product guardrails under unsecured growth.','Unsecured growth guardrail evidence','Unsecured growth guardrails',23,TRUE),

        (24,'M1-11','SC04','Portfolio Mix Sensitivity',NULL,'VE24','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','SECURED_BALANCE_GROWTH_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Secured balance growth product-mix scenario.','BASELINE','Baseline strategy on secured-balance growth.','Evaluate baseline under secured-balance growth.','Secured balance growth evidence','Secured balance baseline',24,TRUE),

        (25,'M1-12','SC04','Portfolio Mix Sensitivity',NULL,'VE25','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','REVOLVING_LINE_EXPANSION_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Revolving-line expansion product-mix scenario.','BASELINE','Baseline strategy on revolving expansion.','Evaluate baseline under revolving-line expansion.','Revolving expansion baseline evidence','Revolving expansion baseline',25,TRUE),

        (26,'M1-12','SC04','Portfolio Mix Sensitivity','CG14','VE26','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','REVOLVING_LINE_EXPANSION_MIX','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','PRODUCT_MIX','Revolving-line expansion product-mix scenario.','PRODUCT_GUARDRAILS','Product guardrails under revolving expansion.','Evaluate product guardrails under revolving-line expansion.','Revolving expansion guardrail evidence','Revolving expansion guardrails',26,TRUE),


        /*******************************************************************************************
        SC05 — Exposure Intensity Sensitivity.

        Purpose:
            Evaluate high-balance and low-balance request environments, including counteroffer-first
            treatment under high-balance appetite.
        *******************************************************************************************/
        (27,'M1-13','SC05','Exposure Intensity Sensitivity',NULL,'VE27','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','EXPOSURE_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','EXPOSURE_INTENSITY','Exposure-intensity baseline reference scenario.','BASELINE','Baseline strategy on exposure reference.','Establish exposure-intensity reference behavior.','Exposure reference evidence','Exposure reference baseline',27,TRUE),

        (28,'M1-14','SC05','Exposure Intensity Sensitivity',NULL,'VE28','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','HIGH_BALANCE_APPETITE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','EXPOSURE_INTENSITY','High-balance appetite scenario.','BASELINE','Baseline strategy under higher requested exposure intensity.','Evaluate baseline under high-balance appetite.','High-balance baseline evidence','High-balance baseline',28,TRUE),

        (29,'M1-14','SC05','Exposure Intensity Sensitivity','CG15','VE29','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','HIGH_BALANCE_APPETITE','BASE_POPULATION_V1','COUNTEROFFER_FIRST_PROFILE','COUNTEROFFER_FIRST_PRODUCT_POLICY','EXPOSURE_INTENSITY','High-balance appetite scenario.','COUNTEROFFER_MANAGEMENT','Counteroffer-first strategy under high-balance appetite.','Evaluate counteroffer treatment under high-balance appetite.','High-balance counteroffer evidence','High-balance counteroffer challenger',29,TRUE),

        (30,'M1-15','SC05','Exposure Intensity Sensitivity',NULL,'VE30','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','LOW_BALANCE_CONSERVATIVE_REQUESTS','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','EXPOSURE_INTENSITY','Low-balance conservative requests scenario.','BASELINE','Baseline strategy under lower requested exposure intensity.','Evaluate baseline under low-balance conservative requests.','Low-balance baseline evidence','Low-balance baseline',30,TRUE),


        /*******************************************************************************************
        SC06 — LGD Severity Sensitivity.

        Purpose:
            Evaluate strategy behavior under secured severity, unsecured severity, and broad LGD
            stress, including product guardrails.
        *******************************************************************************************/
        (31,'M1-16','SC06','LGD Severity Sensitivity',NULL,'VE31','MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET','LGD_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','LGD_SEVERITY','LGD baseline reference scenario.','BASELINE','Baseline strategy on LGD reference.','Establish LGD reference behavior.','LGD reference evidence','LGD reference baseline',31,TRUE),

        (32,'M1-17','SC06','LGD Severity Sensitivity',NULL,'VE32','MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET','SECURED_SEVERITY_STRESS','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','LGD_SEVERITY','Secured severity stress scenario.','BASELINE','Baseline strategy under secured severity stress.','Evaluate baseline under secured LGD severity stress.','Secured severity baseline evidence','Secured severity baseline',32,TRUE),

        (33,'M1-18','SC06','LGD Severity Sensitivity',NULL,'VE33','MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET','UNSECURED_SEVERITY_STRESS','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','LGD_SEVERITY','Unsecured severity stress scenario.','BASELINE','Baseline strategy under unsecured severity stress.','Evaluate baseline under unsecured LGD severity stress.','Unsecured severity baseline evidence','Unsecured severity baseline',33,TRUE),

        (34,'M1-18','SC06','LGD Severity Sensitivity','CG16','VE34','MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET','UNSECURED_SEVERITY_STRESS','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','LGD_SEVERITY','Unsecured severity stress scenario.','PRODUCT_GUARDRAILS','Product guardrails under unsecured severity stress.','Evaluate product guardrails under unsecured severity stress.','Unsecured severity guardrail evidence','Unsecured severity guardrails',34,TRUE),

        (35,'M1-19','SC06','LGD Severity Sensitivity',NULL,'VE35','MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET','BROAD_LGD_STRESS','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','LGD_SEVERITY','Broad LGD stress scenario.','BASELINE','Baseline strategy under broad LGD stress.','Evaluate baseline under broad LGD stress.','Broad LGD baseline evidence','Broad LGD baseline',35,TRUE),

        (36,'M1-19','SC06','LGD Severity Sensitivity','CG17','VE36','MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET','BROAD_LGD_STRESS','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','LGD_SEVERITY','Broad LGD stress scenario.','PRODUCT_GUARDRAILS','Product guardrails under broad LGD stress.','Evaluate product guardrails under broad LGD stress.','Broad LGD guardrail evidence','Broad LGD guardrails',36,TRUE)
) AS c(
    run_sequence_number,
    module1_run_id,
    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_profile_code,
    product_policy_profile_code,

    module1_parameter_family_changed,
    module1_parameter_change_summary,

    module2_strategy_family_changed,
    module2_parameter_change_summary,

    expected_storyline,
    validation_summary_section_hint,
    readme_storyline_label,
    linkedin_post_sequence,

    registry_active_flag
);



/***************************************************************************************************
SECTION 2.6 — SELECT CURRENT RUN AND GENERATE ACTIVE PARAMETER CARDS
****************************************************************************************************

PURPOSE:
    Convert the operator-selected run into the active strategy and product-policy parameter cards used
    by downstream sections.

OUTPUTS:
    tmp_m2_selected_run_config
    tmp_module2_strategy_params
    tmp_module2_product_policy_params

WHY THIS SECTION EXISTS:
    Downstream code should not need to know whether a run was selected by a campaign ID or built as a
    custom experiment.

    It should only consume the canonical parameter tables:
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

SQL TEACHING POINT:
    This section uses CTEs to normalize two operating modes:

        STANDARD_CAMPAIGN
        CUSTOM

    into one selected-run configuration.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_selected_run_config
ON COMMIT PRESERVE ROWS
AS
WITH op AS (
    SELECT *
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE
    LIMIT 1
),

standard_run AS (
    SELECT
        op.run_mode,

        c.module2_run_id,
        c.run_sequence_number,
        c.module1_run_id,

        c.showcase_id,
        c.showcase_name,
        c.comparison_group_id,
        c.validation_evidence_group_id,

        c.module1_scenario_set_name,
        c.module1_scenario_name,
        c.population_id,

        c.strategy_profile_code,
        c.product_policy_profile_code,

        c.module1_parameter_family_changed,
        c.module1_parameter_change_summary,

        c.module2_strategy_family_changed,
        c.module2_parameter_change_summary,

        c.expected_storyline,
        c.validation_summary_section_hint,
        c.readme_storyline_label,
        c.linkedin_post_sequence,

        c.registry_active_flag

    FROM op

    JOIN tmp_m2_campaign_run_catalog c
        ON c.module2_run_id = op.selected_module2_run_id

    WHERE op.run_mode = 'STANDARD_CAMPAIGN'
),

custom_run AS (
    SELECT
        op.run_mode,

        COALESCE(op.custom_module2_run_id, 'CUSTOM_MODULE2_RUN') AS module2_run_id,
        op.custom_run_sequence_number AS run_sequence_number,
        COALESCE(op.custom_module1_run_id, 'CUSTOM_MODULE1_RUN') AS module1_run_id,

        op.custom_showcase_id AS showcase_id,
        op.custom_showcase_name AS showcase_name,
        op.custom_comparison_group_id AS comparison_group_id,
        op.custom_validation_evidence_group_id AS validation_evidence_group_id,

        op.custom_module1_scenario_set_name AS module1_scenario_set_name,
        op.custom_module1_scenario_name AS module1_scenario_name,
        op.custom_population_id AS population_id,

        COALESCE(op.custom_strategy_profile_code, 'CUSTOM_USER_DEFINED_STRATEGY_PROFILE')
            AS strategy_profile_code,

        COALESCE(op.custom_product_policy_profile_code, 'CUSTOM_USER_DEFINED_PRODUCT_POLICY')
            AS product_policy_profile_code,

        op.custom_module1_parameter_family_changed AS module1_parameter_family_changed,
        op.custom_module1_parameter_change_summary AS module1_parameter_change_summary,

        op.custom_module2_strategy_family_changed AS module2_strategy_family_changed,
        op.custom_module2_parameter_change_summary AS module2_parameter_change_summary,

        op.custom_expected_storyline AS expected_storyline,
        op.custom_validation_summary_section_hint AS validation_summary_section_hint,
        op.custom_readme_storyline_label AS readme_storyline_label,
        op.custom_linkedin_post_sequence AS linkedin_post_sequence,

        FALSE AS registry_active_flag

    FROM op

    WHERE op.run_mode = 'CUSTOM'
)

SELECT *
FROM standard_run

UNION ALL

SELECT *
FROM custom_run;



/*-----------------------------------------------------------------------------------------------
2.6A Active strategy parameter card.

Business purpose:
    Create the one-row strategy card used by Sections 3 through 16.

SQL logic:
    Join selected run configuration to the strategy profile catalog.
    Generate strategy_run_id deterministically from module2_run_id, strategy_name, and version.

Important:
    strategy_run_id supports traceability.
    It does not replace archive grain or matched-comparison grain.
-----------------------------------------------------------------------------------------------*/

CREATE TEMP TABLE tmp_module2_strategy_params
ON COMMIT PRESERVE ROWS
AS
SELECT
    TRUE AS active_strategy_flag,

    sr.run_mode,
    sr.module2_run_id,
    sr.run_sequence_number,
    sr.strategy_profile_code,
    sr.product_policy_profile_code,
    sp.strategy_family_code,
    sp.strategy_profile_description,

    sp.module2_model_version,
    sp.strategy_set_name,
    sp.strategy_name,
    sp.strategy_version,

    sr.module2_run_id || '_' || sp.strategy_name || '_' || sp.strategy_version || '_RUN'
        AS strategy_run_id,

    CURRENT_TIMESTAMP AS strategy_run_ts,

    CASE
        WHEN sr.run_mode = 'STANDARD_CAMPAIGN' THEN TRUE
        ELSE FALSE
    END AS campaign_registry_required_flag,

    sp.default_module1_input_source AS module1_input_source,

    sr.module1_scenario_set_name AS source_module1_scenario_set_name,
    sr.module1_scenario_name AS source_module1_scenario_name,
    sr.population_id AS source_population_id,

    sp.default_archive_run_flag AS archive_run_flag,
    sp.default_strategy_archive_reset_mode AS strategy_archive_reset_mode,

    sp.standard_campaign_profile_flag,

    sp.approve_max_estimated_pd_proxy,
    sp.counteroffer_max_estimated_pd_proxy,
    sp.review_max_estimated_pd_proxy,
    sp.decline_min_estimated_pd_proxy,

    sp.global_approve_max_pti,
    sp.global_review_max_pti,
    sp.global_decline_min_pti,

    sp.approve_max_dti,
    sp.review_max_dti,
    sp.decline_min_dti,

    sp.borderline_threshold_buffer_pct,

    sp.bankruptcy_policy_stop_enabled,
    sp.major_derogatory_policy_stop_enabled,
    sp.severe_delinquency_policy_stop_enabled,
    sp.severe_delinquency_count_threshold,

    sp.high_utilization_review_enabled,
    sp.high_utilization_review_threshold,

    sp.low_score_review_enabled,
    sp.low_score_review_threshold,

    sp.approve_reason_code,
    sp.reason_code_required_flag,
    sp.simulated_offer_exposure_flag_enabled,
    sp.manual_review_approved_amount_convention,
    sp.decline_approved_amount_convention,
    sp.approved_el_decline_convention,
    sp.approved_el_manual_review_convention,
    sp.allow_approved_amount_above_requested_flag,

    sp.failed_counteroffer_resolution

FROM tmp_m2_selected_run_config sr

JOIN tmp_m2_strategy_profile_catalog sp
    ON sp.strategy_profile_code = sr.strategy_profile_code;



/*-----------------------------------------------------------------------------------------------
2.6B Active product-policy parameter card.

Business purpose:
    Create one active product-policy row per supported product.

SQL logic:
    Join the active strategy card to the product-policy profile catalog using product_policy_profile_code.

Expected:
    five rows:
        MORTGAGE
        HELOC
        AUTO_LOAN
        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE
-----------------------------------------------------------------------------------------------*/

CREATE TEMP TABLE tmp_module2_product_policy_params
ON COMMIT PRESERVE ROWS
AS
SELECT
    pp.product_policy_profile_code,
    pp.product_type,

    pp.product_approve_max_pti,
    pp.product_review_max_pti,
    pp.product_decline_min_pti,
    pp.counteroffer_target_pti,

    pp.product_approve_max_requested_el,
    pp.product_review_max_requested_el,
    pp.product_decline_min_requested_el,
    pp.product_approved_el_cap,

    pp.product_min_approved_amount,
    pp.product_max_approved_amount,

    pp.counteroffer_allowed_flag,
    pp.manual_review_allowed_flag,
    pp.product_min_counteroffer_pct,
    pp.product_max_exposure_reduction_pct,
    pp.exposure_assignment_method,
    pp.approved_amount_rounding_increment

FROM tmp_m2_product_policy_profile_catalog pp

JOIN tmp_module2_strategy_params sp
    ON sp.product_policy_profile_code = pp.product_policy_profile_code

WHERE sp.active_strategy_flag IS TRUE;



/***************************************************************************************************
SECTION 2.7 — CREATE / HARDEN PERSISTENT STRATEGY RUN CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Create or reuse the persistent run registry that maps technical strategy/scenario keys to
    campaign run IDs and documentation metadata.

WHY THIS MATTERS:
    The archive key is technical.
    The registry makes the campaign explainable.

    Registry IDs support:
        validation-summary drafting,
        executive evidence capture,
        README evidence,
        LinkedIn storyline planning,
        comparison grouping,
        and run tracking.

REGISTRY BOUNDARY:
    Campaign IDs do not replace technical SQL lineage.

    The technical run key remains:
        module1_scenario_set_name
        module1_scenario_name
        population_id
        strategy_set_name
        strategy_name
        strategy_version

***************************************************************************************************/

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

    strategy_profile_code                  TEXT,
    product_policy_profile_code            TEXT,

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


/* Schema hardening for existing registry tables created by earlier versions. */
ALTER TABLE credit_decisioning_sim.strategy_run_campaign_registry
    ADD COLUMN IF NOT EXISTS strategy_profile_code TEXT;

ALTER TABLE credit_decisioning_sim.strategy_run_campaign_registry
    ADD COLUMN IF NOT EXISTS product_policy_profile_code TEXT;


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_module2_run_id
ON credit_decisioning_sim.strategy_run_campaign_registry (module2_run_id);

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
SECTION 2.8 — SEED / UPDATE STRATEGY RUN CAMPAIGN REGISTRY FROM CATALOG
****************************************************************************************************

PURPOSE:
    Upsert the formal 36-run campaign roadmap into the persistent registry.

SQL TEACHING POINT:
    INSERT ... ON CONFLICT performs an upsert.

    If the module2_run_id already exists, the registry row is updated with the current catalog values.
    This makes campaign registry corrections deterministic and rerunnable.

***************************************************************************************************/

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

    strategy_profile_code,
    product_policy_profile_code,

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
SELECT
    c.module1_run_id,
    c.module2_run_id,
    c.run_sequence_number,

    c.showcase_id,
    c.showcase_name,
    c.comparison_group_id,
    c.validation_evidence_group_id,

    c.module1_scenario_set_name,
    c.module1_scenario_name,
    c.population_id,

    sp.strategy_set_name,
    sp.strategy_name,
    sp.strategy_version,

    c.strategy_profile_code,
    c.product_policy_profile_code,

    c.module1_parameter_family_changed,
    c.module1_parameter_change_summary,

    c.module2_strategy_family_changed,
    c.module2_parameter_change_summary,

    c.expected_storyline,
    c.validation_summary_section_hint,
    c.readme_storyline_label,
    c.linkedin_post_sequence,

    c.registry_active_flag,
    CURRENT_TIMESTAMP AS registry_updated_ts

FROM tmp_m2_campaign_run_catalog c

JOIN tmp_m2_strategy_profile_catalog sp
    ON sp.strategy_profile_code = c.strategy_profile_code

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

    strategy_profile_code = EXCLUDED.strategy_profile_code,
    product_policy_profile_code = EXCLUDED.product_policy_profile_code,

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
SECTION 2.9 — CREATE / HARDEN PERSISTENT STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Create or reuse the persistent comparison registry that defines governed baseline / challenger
    comparison groups.

WHY THIS MATTERS:
    The latest-run table changes every run.

    A comparison registry prevents Section 13 from silently comparing the wrong baseline or
    challenger after later campaign runs.

***************************************************************************************************/

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


/* Schema hardening for earlier versions. */
ALTER TABLE credit_decisioning_sim.strategy_comparison_campaign_registry
    ADD COLUMN IF NOT EXISTS baseline_module2_run_id TEXT;

ALTER TABLE credit_decisioning_sim.strategy_comparison_campaign_registry
    ADD COLUMN IF NOT EXISTS challenger_module2_run_id TEXT;


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_comparison_campaign_registry_comparison_group
ON credit_decisioning_sim.strategy_comparison_campaign_registry (comparison_group_id);

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
SECTION 2.10 — SEED / UPDATE STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Seed the 17 formal baseline / challenger comparison groups.

ACTIVE COMPARISON:
    The selected active comparison is controlled by Section 2.1:

        selected_comparison_group_id

    Default:
        CG01

SQL TEACHING POINT:
    The comparison plan lists only baseline and challenger run IDs.

    The SQL then joins back to the campaign registry to populate technical strategy and Module 1
    scenario keys.

    This avoids retyping long scenario / strategy keys and reduces naming mismatch risk.

***************************************************************************************************/

UPDATE credit_decisioning_sim.strategy_comparison_campaign_registry
SET
    active_comparison_flag = FALSE,
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE active_comparison_flag IS TRUE;


WITH op AS (
    SELECT *
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE
    LIMIT 1
),

comparison_plan AS (
    SELECT *
    FROM (
        VALUES
            ('CG01'::TEXT,'Baseline vs Tighter Synthetic Risk'::TEXT,'SC01'::TEXT,'Baseline Strategy Frontier'::TEXT,'M2-01'::TEXT,'M2-02'::TEXT,'Tighter synthetic-risk discipline.'::TEXT,'approved Expected Loss reduction'::TEXT),
            ('CG02','Baseline vs Growth Oriented','SC01','Baseline Strategy Frontier','M2-01','M2-03','Growth expansion tradeoff.','offer exposure and approved amount growth'),
            ('CG03','Baseline vs Tighter Affordability','SC01','Baseline Strategy Frontier','M2-01','M2-04','Affordability discipline tradeoff.','approved PTI discipline'),
            ('CG04','Baseline vs Counteroffer First','SC01','Baseline Strategy Frontier','M2-01','M2-05','Counteroffer-first exposure management.','counteroffer rate and exposure reduction'),
            ('CG05','Baseline vs Product Guardrails','SC01','Baseline Strategy Frontier','M2-01','M2-06','Product-specific guardrail effect.','product-level approved EL reduction'),
            ('CG06','Baseline vs Manual Review Reduction','SC01','Baseline Strategy Frontier','M2-01','M2-07','Manual-review burden reduction.','manual-review rate reduction'),

            ('CG07','Rate-Up 200bp Baseline vs Affordability Tight','SC02','Rate Environment Sensitivity','M2-08','M2-11','Affordability under 200bp rate stress.','approved PTI under rate stress'),
            ('CG08','Rate-Up 300bp Baseline vs Affordability Tight','SC02','Rate Environment Sensitivity','M2-10','M2-12','Affordability under 300bp rate stress.','approved PTI under severe rate stress'),
            ('CG09','Rate-Down 200bp Baseline vs Growth','SC02','Rate Environment Sensitivity','M2-09','M2-13','Growth under rate relief.','offer growth under rate relief'),

            ('CG10','Near-Prime Baseline vs Tighter Risk','SC03','Credit Box Sensitivity','M2-16','M2-17','Risk discipline under near-prime expansion.','approved EL reduction'),
            ('CG11','Near-Prime Baseline vs Counteroffer First','SC03','Credit Box Sensitivity','M2-16','M2-18','Counteroffer management under near-prime expansion.','counteroffer rate and exposure reduction'),
            ('CG12','Credit Stress Baseline vs Tighter Risk','SC03','Credit Box Sensitivity','M2-19','M2-20','Risk discipline under credit stress.','approved EL reduction under stress'),

            ('CG13','Unsecured Growth Baseline vs Product Guardrails','SC04','Portfolio Mix Sensitivity','M2-22','M2-23','Product guardrails under unsecured growth.','unsecured approved EL reduction'),
            ('CG14','Revolving Expansion Baseline vs Product Guardrails','SC04','Portfolio Mix Sensitivity','M2-25','M2-26','Product guardrails under revolving expansion.','revolving approved EL reduction'),

            ('CG15','High-Balance Baseline vs Counteroffer First','SC05','Exposure Intensity Sensitivity','M2-28','M2-29','Counteroffer management under high-balance appetite.','approved exposure reduction'),

            ('CG16','Unsecured Severity Baseline vs Product Guardrails','SC06','LGD Severity Sensitivity','M2-33','M2-34','Product guardrails under unsecured severity stress.','approved EL reduction under severity stress'),
            ('CG17','Broad LGD Baseline vs Product Guardrails','SC06','LGD Severity Sensitivity','M2-35','M2-36','Product guardrails under broad LGD stress.','approved EL reduction under broad severity stress')
    ) AS v(
        comparison_group_id,
        comparison_set_name,
        showcase_id,
        showcase_name,
        baseline_module2_run_id,
        challenger_module2_run_id,
        expected_comparison_storyline,
        primary_metric_focus
    )
),

registry_pairs AS (
    SELECT
        cp.*,

        b.strategy_set_name AS baseline_strategy_set_name,
        b.strategy_name AS baseline_strategy_name,
        b.strategy_version AS baseline_strategy_version,

        ch.strategy_set_name AS challenger_strategy_set_name,
        ch.strategy_name AS challenger_strategy_name,
        ch.strategy_version AS challenger_strategy_version,

        b.module1_scenario_set_name,
        b.module1_scenario_name,
        b.population_id,

        CASE
            WHEN cp.comparison_group_id = COALESCE(op.selected_comparison_group_id, 'CG01')
                THEN TRUE
            ELSE FALSE
        END AS active_comparison_flag

    FROM comparison_plan cp

    CROSS JOIN op

    JOIN credit_decisioning_sim.strategy_run_campaign_registry b
        ON b.module2_run_id = cp.baseline_module2_run_id

    JOIN credit_decisioning_sim.strategy_run_campaign_registry ch
        ON ch.module2_run_id = cp.challenger_module2_run_id

    WHERE b.module1_scenario_set_name = ch.module1_scenario_set_name
      AND b.module1_scenario_name = ch.module1_scenario_name
      AND b.population_id = ch.population_id
)

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
    TRUE AS registry_active_flag,
    CURRENT_TIMESTAMP AS registry_updated_ts

FROM registry_pairs

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



/***************************************************************************************************
SECTION 2.11 — SECTION 2 REVIEW OUTPUTS
****************************************************************************************************

PURPOSE:
    Provide compact setup outputs before Section 3 gatekeepers run.

WHAT TO REVIEW:
    1. Active operator selector.
    2. Selected run configuration.
    3. Active strategy parameter card.
    4. Active product-policy card.
    5. Matching campaign registry row.
    6. Active comparison registry row.

INTERPRETATION:
    These are setup-review outputs.

    Passing visual review here does not replace Section 3 gatekeepers.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
2.11A Active operator selector.

Expected:
    exactly one row.
-----------------------------------------------------------------------------------------------*/

SELECT
    'ACTIVE_MODULE2_RUN_SELECTOR' AS diagnostic_name,
    *
FROM tmp_m2_operator_run_selector
WHERE active_selector_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
2.11B Selected run configuration.

Expected:
    exactly one row.

If this returns zero rows:
    selected_module2_run_id is not in the campaign run catalog,
    or run_mode / custom fields are not configured correctly.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SELECTED_MODULE2_RUN_CONFIG' AS diagnostic_name,
    *
FROM tmp_m2_selected_run_config;



/*-----------------------------------------------------------------------------------------------
2.11C Active strategy parameter card.

Purpose:
    Show the strategy controls that downstream sections will use.

Key review fields:
    strategy_name
    strategy_profile_code
    product_policy_profile_code
    source Module 1 scenario
    synthetic estimated-risk thresholds
    PTI thresholds
    failed_counteroffer_resolution
-----------------------------------------------------------------------------------------------*/

SELECT
    'ACTIVE_STRATEGY_PARAMETER_CARD' AS diagnostic_name,

    run_mode,
    module2_run_id,
    run_sequence_number,

    strategy_profile_code,
    product_policy_profile_code,
    strategy_family_code,

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

    failed_counteroffer_resolution

FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
2.11D Active product-policy card.

Purpose:
    Show the product-level policy values that downstream sections will use.

Expected:
    five rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    'ACTIVE_PRODUCT_POLICY_CARD' AS diagnostic_name,
    product_policy_profile_code,
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

FROM tmp_module2_product_policy_params
ORDER BY product_type;



/*-----------------------------------------------------------------------------------------------
2.11E Matching campaign registry row.

Purpose:
    Confirm the selected active strategy parameter card maps to the persistent campaign registry.

Expected for STANDARD_CAMPAIGN:
    exactly one matching row.

Section 3 will enforce the formal match.
-----------------------------------------------------------------------------------------------*/

SELECT
    'MATCHING_CAMPAIGN_REGISTRY_ROW' AS diagnostic_name,
    r.*
FROM credit_decisioning_sim.strategy_run_campaign_registry r

JOIN tmp_module2_strategy_params p
    ON p.active_strategy_flag IS TRUE
   AND r.module1_scenario_set_name = p.source_module1_scenario_set_name
   AND r.module1_scenario_name = p.source_module1_scenario_name
   AND r.population_id = p.source_population_id
   AND r.strategy_set_name = p.strategy_set_name
   AND r.strategy_name = p.strategy_name
   AND r.strategy_version = p.strategy_version

WHERE r.registry_active_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
2.11F Active comparison registry row.

Purpose:
    Show which governed comparison Section 13 will treat as active.

Default:
    CG01
-----------------------------------------------------------------------------------------------*/

SELECT
    'ACTIVE_COMPARISON_REGISTRY_ROW' AS diagnostic_name,
    *
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE active_comparison_flag IS TRUE
  AND registry_active_flag IS TRUE;



/***************************************************************************************************
END OF SECTION 2 — STRATEGY PROFILE, PRODUCT POLICY PROFILE, CAMPAIGN REGISTRY, AND RUN SELECTOR

If execution reaches this point:
    1. The operator run selector exists.
    2. Strategy profile catalog exists.
    3. Product-policy profile catalog exists.
    4. Strategy ↔ product-policy compatibility map exists.
    5. Campaign run catalog exists.
    6. A selected run configuration has been derived.
    7. tmp_module2_strategy_params has been generated.
    8. tmp_module2_product_policy_params has been generated.
    9. Persistent campaign registry has been created / hardened.
    10. Campaign registry has been seeded / updated.
    11. Persistent comparison registry has been created / hardened.
    12. Comparison registry has been seeded / updated.
    13. Setup review outputs have been displayed.

Next:
    Run Section 3 gatekeepers before building applicant-level strategy logic.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01420 -->


---

<a id="c038-m01421"></a>

### C038-M01421

**Andrew** · 2026-05-12T02:22:32.026000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01421 -->
i can see the benefit of what you redesigned in section 2, but the run procedures are still not super clear.  i assume the 'selected_module2_run_id' controls which standard campaign is being run.  if that is the case - why are only selected examples spelled out (also i feel like that information needs to be closer to the location where the user makes the edit)?
<!-- END_MESSAGE C038-M01421 -->


---

<a id="c038-m01423"></a>

### C038-M01423

**ChatGPT** · 2026-05-12T02:25:22.202059-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01423 -->
Yes — your assumption is correct:

```text
selected_module2_run_id controls which standard campaign run is being executed.
```

The way I wrote Section 2.1 is not clear enough. I only listed selected examples to keep the comment block shorter, but for an operator-facing run selector, that was the wrong tradeoff. The run menu should be **right next to the value the user edits**, not buried later in the campaign catalog.

Also, there are really two selectors:

```text
selected_module2_run_id
    Controls the actual Module 2 run configuration.

selected_comparison_group_id
    Controls which comparison Section 13 treats as active.
```

Those are related, but not the same. The current design should say that explicitly. Section 13 uses a governed comparison selector instead of inferring comparison from the latest-run table, so this distinction matters. fileciteturn195file20

## Recommended improvement

I would patch **Section 2.1** so it has:

```text
1. Clear user instruction.
2. Full M2-01 through M2-36 run menu.
3. Explanation that selected_module2_run_id drives the run.
4. Explanation that selected_comparison_group_id is optional / comparison-only.
5. A warning that changing selected_module2_run_id is the normal campaign operation.
```

I would also consider changing:

```sql
selected_comparison_group_id = 'CG01'
```

to either:

```sql
selected_comparison_group_id = NULL
```

or:

```sql
selected_comparison_group_id = 'AUTO'
```

Then Section 2.10 can auto-select the comparison group associated with the selected challenger run. That would prevent a user from selecting `M2-29` but accidentally leaving `CG01` active.

For now, the easiest immediate fix is to make Section 2.1 much clearer.

## Targeted replacement for Section 2.1 only

```sql
/***************************************************************************************************
SECTION 2.1 — OPERATOR RUN SELECTOR
****************************************************************************************************

USER ACTION:
    For a standard campaign run, edit selected_module2_run_id.

    This one field controls which formal Module 2 campaign run is executed.

DEFAULT:
    selected_module2_run_id = 'M2-01'

    This selects:
        M2-01
        BASELINE_V2
        BASELINE_STRATEGY
        BASELINE_PRODUCT_POLICY

IMPORTANT:
    BASELINE_STRATEGY is the default reference strategy.

    TIGHTER_SYNTHETIC_RISK_STRATEGY is a challenger strategy.
    It is not the default.

WHAT selected_module2_run_id CONTROLS:
    selected_module2_run_id joins to the formal campaign run catalog in Section 2.5.

    From that one run ID, Section 2 derives:
        Module 1 scenario set
        Module 1 scenario name
        population_id
        strategy_profile_code
        product_policy_profile_code
        strategy_name
        strategy_version
        module2_run_id
        strategy_run_id
        active strategy parameter card
        active product-policy parameter card
        campaign registry row
        evidence story metadata

WHAT selected_comparison_group_id CONTROLS:
    selected_comparison_group_id controls which baseline / challenger comparison Section 13 treats
    as active.

    It does not control which strategy run is executed.

    For example:
        selected_module2_run_id = 'M2-29'
            runs the high-balance / counteroffer-first strategy slice.

        selected_comparison_group_id = 'CG15'
            tells Section 13 to compare:
                M2-28 baseline high-balance
                versus
                M2-29 counteroffer-first high-balance.

RUN MODE OPTIONS:
    STANDARD_CAMPAIGN:
        Use the formal 36-run campaign catalog.

    CUSTOM:
        Use only for exploratory runs outside the formal campaign roadmap.

STANDARD CAMPAIGN RUN MENU:

    SC01 — Baseline Strategy Frontier
        M2-01  BASELINE_V2                          BASELINE_STRATEGY
        M2-02  BASELINE_V2                          TIGHTER_SYNTHETIC_RISK_STRATEGY
        M2-03  BASELINE_V2                          GROWTH_ORIENTED_STRATEGY
        M2-04  BASELINE_V2                          TIGHTER_AFFORDABILITY_STRATEGY
        M2-05  BASELINE_V2                          COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
        M2-06  BASELINE_V2                          PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
        M2-07  BASELINE_V2                          MANUAL_REVIEW_REDUCTION_STRATEGY

    SC02 — Rate Environment Sensitivity
        M2-08  RATE_UP_200BP                        BASELINE_STRATEGY
        M2-09  RATE_DOWN_200BP                      BASELINE_STRATEGY
        M2-10  RATE_UP_300BP                        BASELINE_STRATEGY
        M2-11  RATE_UP_200BP                        TIGHTER_AFFORDABILITY_STRATEGY
        M2-12  RATE_UP_300BP                        TIGHTER_AFFORDABILITY_STRATEGY
        M2-13  RATE_DOWN_200BP                      GROWTH_ORIENTED_STRATEGY

    SC03 — Credit Box Sensitivity
        M2-14  CREDIT_BOX_BASELINE_REFERENCE         BASELINE_STRATEGY
        M2-15  PRIME_GROWTH_SCORE_MIX                BASELINE_STRATEGY
        M2-16  NEAR_PRIME_EXPANSION_MIX              BASELINE_STRATEGY
        M2-17  NEAR_PRIME_EXPANSION_MIX              TIGHTER_SYNTHETIC_RISK_STRATEGY
        M2-18  NEAR_PRIME_EXPANSION_MIX              COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
        M2-19  CREDIT_STRESS_SCORE_MIX               BASELINE_STRATEGY
        M2-20  CREDIT_STRESS_SCORE_MIX               TIGHTER_SYNTHETIC_RISK_STRATEGY

    SC04 — Portfolio Mix Sensitivity
        M2-21  PORTFOLIO_MIX_BASELINE_REFERENCE      BASELINE_STRATEGY
        M2-22  UNSECURED_GROWTH_MIX                  BASELINE_STRATEGY
        M2-23  UNSECURED_GROWTH_MIX                  PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
        M2-24  SECURED_BALANCE_GROWTH_MIX            BASELINE_STRATEGY
        M2-25  REVOLVING_LINE_EXPANSION_MIX          BASELINE_STRATEGY
        M2-26  REVOLVING_LINE_EXPANSION_MIX          PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY

    SC05 — Exposure Intensity Sensitivity
        M2-27  EXPOSURE_BASELINE_REFERENCE           BASELINE_STRATEGY
        M2-28  HIGH_BALANCE_APPETITE                 BASELINE_STRATEGY
        M2-29  HIGH_BALANCE_APPETITE                 COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
        M2-30  LOW_BALANCE_CONSERVATIVE_REQUESTS     BASELINE_STRATEGY

    SC06 — LGD Severity Sensitivity
        M2-31  LGD_BASELINE_REFERENCE                BASELINE_STRATEGY
        M2-32  SECURED_SEVERITY_STRESS               BASELINE_STRATEGY
        M2-33  UNSECURED_SEVERITY_STRESS             BASELINE_STRATEGY
        M2-34  UNSECURED_SEVERITY_STRESS             PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
        M2-35  BROAD_LGD_STRESS                      BASELINE_STRATEGY
        M2-36  BROAD_LGD_STRESS                      PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY

COMPARISON GROUP QUICK REFERENCE:
    CG01  M2-01 vs M2-02
    CG02  M2-01 vs M2-03
    CG03  M2-01 vs M2-04
    CG04  M2-01 vs M2-05
    CG05  M2-01 vs M2-06
    CG06  M2-01 vs M2-07
    CG07  M2-08 vs M2-11
    CG08  M2-10 vs M2-12
    CG09  M2-09 vs M2-13
    CG10  M2-16 vs M2-17
    CG11  M2-16 vs M2-18
    CG12  M2-19 vs M2-20
    CG13  M2-22 vs M2-23
    CG14  M2-25 vs M2-26
    CG15  M2-28 vs M2-29
    CG16  M2-33 vs M2-34
    CG17  M2-35 vs M2-36

PRACTICAL RUN PROCEDURE:
    To run a standard campaign slice:
        1. Set run_mode = 'STANDARD_CAMPAIGN'.
        2. Set selected_module2_run_id to the desired M2 run.
        3. Optionally set selected_comparison_group_id for Section 13 review.
        4. Run Section 2.
        5. Review Section 2.11 outputs.
        6. Run Section 3 gatekeepers before continuing.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_operator_run_selector (
    active_selector_flag                         BOOLEAN NOT NULL,
    run_mode                                     TEXT NOT NULL,

    /***********************************************************************************************
    Standard campaign controls.

    selected_module2_run_id:
        Main operator control for standard campaign runs.

    selected_comparison_group_id:
        Optional Section 13 comparison selector.
        This does not change the run being executed.
    ***********************************************************************************************/
    selected_module2_run_id                      TEXT,
    selected_comparison_group_id                 TEXT,

    /***********************************************************************************************
    Custom run controls.

    Used only when run_mode = 'CUSTOM'.
    ***********************************************************************************************/
    custom_module1_run_id                        TEXT,
    custom_module2_run_id                        TEXT,
    custom_run_sequence_number                   INTEGER,

    custom_module1_scenario_set_name             TEXT,
    custom_module1_scenario_name                 TEXT,
    custom_population_id                         TEXT,

    custom_strategy_profile_code                 TEXT,
    custom_product_policy_profile_code           TEXT,

    custom_showcase_id                           TEXT,
    custom_showcase_name                         TEXT,
    custom_comparison_group_id                   TEXT,
    custom_validation_evidence_group_id          TEXT,

    custom_module1_parameter_family_changed      TEXT,
    custom_module1_parameter_change_summary      TEXT,
    custom_module2_strategy_family_changed       TEXT,
    custom_module2_parameter_change_summary      TEXT,
    custom_expected_storyline                    TEXT,
    custom_validation_summary_section_hint        TEXT,
    custom_readme_storyline_label                TEXT,
    custom_linkedin_post_sequence                INTEGER,
    custom_parameter_change_reason               TEXT
) ON COMMIT PRESERVE ROWS;


INSERT INTO tmp_m2_operator_run_selector (
    active_selector_flag,
    run_mode,
    selected_module2_run_id,
    selected_comparison_group_id
)
VALUES (
    TRUE,
    'STANDARD_CAMPAIGN',

    /***********************************************************************************************
    EDIT THIS VALUE TO SELECT THE STANDARD CAMPAIGN RUN.

    Examples:
        'M2-01' = baseline default
        'M2-02' = tighter synthetic-risk challenger
        'M2-05' = counteroffer-first on baseline population
        'M2-23' = product guardrails on unsecured growth mix
        'M2-29' = counteroffer-first on high-balance appetite
        'M2-36' = product guardrails on broad LGD stress
    ***********************************************************************************************/
    'M2-01',

    /***********************************************************************************************
    OPTIONAL: EDIT THIS VALUE TO SELECT THE ACTIVE SECTION 13 COMPARISON.

    This does not change which run is executed.

    Examples:
        'CG01' = M2-01 baseline vs M2-02 tighter risk
        'CG15' = M2-28 high-balance baseline vs M2-29 counteroffer-first
        'CG17' = M2-35 broad LGD baseline vs M2-36 product guardrails

    Recommendation:
        Set this to the comparison group associated with the selected challenger run when you are
        reviewing Section 13 comparison outputs.

        For baseline-only runs, leaving the default CG01 is acceptable for initial setup review, but
        users should change it when reviewing a specific comparison.
    ***********************************************************************************************/
    'CG01'
);
```

## One additional structural recommendation

I would go one step further in the next Section 2 patch: make `selected_comparison_group_id` optional and auto-derived.

Preferred future behavior:

```text
selected_module2_run_id = 'M2-29'
selected_comparison_group_id = NULL

SQL derives:
    active comparison = CG15
```

That would reduce operator error. The campaign catalog already carries `comparison_group_id` for challenger runs, so Section 2.10 can use it rather than forcing the user to edit two fields.

For the immediate code clarity issue, though, the targeted Section 2.1 patch above addresses your main concern: the full run menu is placed directly where the user makes the edit.
<!-- END_MESSAGE C038-M01423 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_70.md) · [Next](Part_72.md)
