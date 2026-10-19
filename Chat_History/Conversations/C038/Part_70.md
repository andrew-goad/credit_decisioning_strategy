# Module 2 Decision Simulator Build

## Part 70

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_69.md) · [Next](Part_71.md)

<a id="c038-m01409"></a>

### C038-M01409

**ChatGPT** · 2026-05-12T01:48:46.473010-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01409 -->
Below is the first full copy-paste patch for **Sections 0–3**. I preserved the downstream contract that later sections depend on: `tmp_module2_strategy_params`, `tmp_module2_product_policy_params`, `tmp_m2_source_selection_scope`, and `tmp_m2_campaign_registry_current_run_match`. Those objects are currently consumed by Section 4 and Section 16, so the redesign changes how they are generated without breaking the rest of the pipeline. fileciteturn191file48 fileciteturn193file8 fileciteturn194file4

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
    Module 2 strategy and product-policy profiles, assigns simulated strategy outcomes, calculates
    simulated approved exposure economics, assigns simulated strategy explanation codes, persists
    latest-run and archive outputs, and produces validation-ready evidence.

WHY IT MATTERS:
    Credit strategy is not a score cutoff.

    It is a structured tradeoff among:
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

WHAT THIS DEMONSTRATES:
    This module demonstrates:
        credit strategy architecture thinking,
        parameterized policy simulation,
        profile-driven strategy controls,
        staged decision-engine design,
        exposure-treatment logic,
        counteroffer feasibility,
        reason-code transparency,
        archive-backed comparison,
        validation discipline,
        parameter snapshot governance,
        and executive-ready evidence capture.

CORE INSIGHT:
    A credit strategy outcome should not be treated as a black-box label.

    In Module 2, final simulated outcomes emerge through a transparent chain:

        Module 1 Applicant / Product / Risk Profile
        → Module 2 Strategy Profile
        → Product Policy Profile
        → Diagnostic Segmentation
        → Rule Trigger Flags
        → Preliminary Routing
        → Approved Exposure and Counteroffer Feasibility
        → Final Simulated Strategy Outcome
        → Simulated Strategy Explanation Codes
        → Latest-Run Output
        → Archive Persistence
        → Matched Comparison
        → QA and Validation
        → Frontier Summary
        → Evidence Capture
        → Post-Campaign Acceptance

READER TAKEAWAY:
    This SQL file should read as a full-system design artifact.

    A reviewer should be able to understand:
        what the module does,
        why it is structured this way,
        how it consumes Module 1,
        how strategy profiles are selected,
        how product policy profiles are selected,
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

    Module 2 does not calculate revenue, yield, funding cost, margin, profitability, capital,
    pricing optimization, or lifetime value.

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
    and future LinkedIn campaign storytelling.

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
    4. A profile-driven strategy and product-policy framework.
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
    → Module 2 Strategy Profile
    → Product Policy Profile
    → Strategy Segmentation
    → Rule Triggers
    → Preliminary Routing
    → Exposure Treatment
    → Counteroffer Feasibility
    → Final Simulated Outcome
    → Simulated Strategy Explanation Codes
    → Latest-Run Output
    → Archive Persistence
    → Matched Strategy Comparison
    → Validation Evidence
    → Executive Evidence
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

1. Strategy-profile driven over hand-edited thresholds
    Formal campaign runs should select a governed strategy profile and product-policy profile rather
    than manually editing many numeric values for every run.

2. Parameterized over hard-coded
    Downstream decision logic should consume governed parameters before users rewrite CASE logic.

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
    Outcomes should be traceable through:
        strategy profile,
        product policy profile,
        segmentation,
        trigger flags,
        routing,
        exposure treatment,
        final decision,
        and simulated reason codes.

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
    through a formal Section 16.9 process.

10. Modular expansion over scope creep
    Growth, earnings, funding cost, risk-adjusted margin, pricing, and profitability belong to a
    future Module 3 economics layer.

====================================================================================================
0.6 CAMPAIGN SCENARIO FRAMEWORK
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

These scenario families are examples of how the engine can be used. Users may add custom scenarios
and custom strategies, but formal campaign evidence should remain registry-matched and parameter-
snapshot audited.

====================================================================================================
0.7 BASELINE DEFAULT VS CAMPAIGN CHALLENGERS
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
    A selected active run may use any of these strategies.
    The baseline default remains BASELINE_STRATEGY.

====================================================================================================
0.8 OPERATING JOB AID — SINGLE RUN
====================================================================================================

For a single governed Module 2 run:

    1. Run Section 1.
        Resets temporary objects and the replaceable latest-run table.

    2. Edit Section 2.1 only if needed.
        For a standard campaign run, set:
            run_mode = 'STANDARD_CAMPAIGN'
            selected_module2_run_id = desired run ID, such as 'M2-01' or 'M2-29'

        Default:
            M2-01 / BASELINE_STRATEGY / BASELINE_V2

    3. Run Section 2.
        Builds:
            strategy profile catalog,
            product-policy profile catalog,
            campaign run catalog,
            active strategy parameter card,
            active product-policy parameter card,
            campaign registry,
            comparison registry.

    4. Run Section 3.
        Fails fast if strategy configuration, product policy, source selection, or registry linkage is
        invalid.

    5. Run Sections 4–11.
        Stages source data, segments profiles, builds rule flags, routes decisions, calculates
        exposure treatment, resolves final outcomes, assigns reason codes, and materializes latest-run
        output.

    6. Run Section 12.
        Persists the completed run to the archive when archive_run_flag = TRUE.

    7. Run Section 13 as needed.
        Reviews selected matched comparison from the comparison registry.

    8. Run Section 14.
        Validates the latest-run output and materializes validation summary evidence.

    9. Run Section 15.
        Builds archive-backed frontier summary.

    10. Run Section 16.
        Captures executive evidence, validation evidence, parameter snapshot, and segment evidence
        for the current completed run.

====================================================================================================
0.9 OPERATING JOB AID — FULL CAMPAIGN
====================================================================================================

For the full 36-run campaign:

    1. For each planned M2 run:
        select the run in Section 2.1;
        run Sections 1–16.8;
        confirm Section 16.8 evidence outputs.

    2. After all campaign runs are complete:
        rerun Section 15 once from the completed archive.

    3. Run Section 16.9.
        Synchronizes fresh Section 15 frontier fields into
        credit_decisioning_sim.strategy_run_evidence_summary.

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
0.10 CUSTOM STRATEGY MODE
====================================================================================================

Formal campaign mode:
    run_mode = 'STANDARD_CAMPAIGN'
    selected_module2_run_id = 'M2-##'

Custom experiment mode:
    run_mode = 'CUSTOM'

Custom mode exists for users who want to create their own strategy and product-policy settings.

Custom mode should be labeled carefully:
    custom_module2_run_id
    custom_strategy_profile_code
    custom_product_policy_profile_code
    custom_parameter_change_reason

Recommendation:
    Use standard campaign mode for governed validation evidence.
    Use custom mode for exploratory analysis unless a custom registry row is intentionally added and
    reviewed.

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
0.12 SQL SECTION MAP
====================================================================================================

Section 0  — Executive Purpose, Module 2 Boundaries, Design Principles, and SQL Section Map

Section 1  — Schema Setup / Clean Rerun Reset
    Establishes schema availability, temporary-object cleanup, and clean latest-run behavior.

Section 2  — Strategy Profile, Product Policy Profile, Campaign Registry, and Run Selector Framework
    Defines the operator run selector, executable strategy profile catalog, executable product-policy
    profile catalog, campaign run catalog, active parameter cards, run registry, and comparison
    registry.

Section 3  — Fail-Fast Strategy Parameter, Source, Product Policy, Profile, and Registry Gatekeeper
    Validates selected run configuration, profile compatibility, threshold ordering, source input
    readiness, product policy completeness, archive controls, output conventions, and registry
    linkage.

Section 4  — Module 1 Source Selection and Lineage Normalization
    Consumes Module 1 latest-run or archive output and creates the source staging layer.

Section 5  — Derived Strategy Segmentation Layer
    Adds diagnostic segmentation fields and carries forward active thresholds.

Section 6  — Rule Flag Construction Layer
    Converts segmentation and source inputs into non-final rule-trigger flags.

Section 7  — Preliminary Decision Routing Layer
    Converts overlapping rule flags into one preliminary route.

Section 8  — Approved Exposure and Counteroffer Feasibility Layer
    Calculates preliminary approved exposure and counteroffer feasibility.

Section 9  — Final Decision Resolution Layer
    Resolves final simulated decision outcomes and approved-exposure economics.

Section 10 — Simulated Reason-Code Assignment Layer
    Assigns deterministic simulated strategy explanation codes.

Section 11 — Latest-Run Strategy Decision Output Table
    Materializes credit_decisioning_sim.strategy_decisions.

Section 12 — Strategy Decision Archive Persistence Layer
    Persists completed latest-run outputs into credit_decisioning_sim.strategy_decisions_archive.

Section 13 — Archive Inventory and Matched Strategy Comparison Framework
    Provides read-only archive inventory and matched baseline / challenger comparison.

Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics
    Provides latest-run validation queries and materializes tmp_m2_validation_status_summary.

Section 15 — Strategy Frontier Summary and Executive Comparison View
    Summarizes archived strategy frontier tradeoffs.

Section 16 — Strategy Run Evidence Capture and Executive Story Register
    Persists executive evidence, validation evidence, parameter snapshots, and product × score segment
    evidence.

Section 16.9 — Post-Campaign Frontier Evidence Synchronization
    After full campaign completion and a fresh Section 15 run, synchronizes frontier fields into
    persistent executive evidence.

Section 17 — Post-Campaign Acceptance, Export, Parameter Audit, and Strategy Effect Review
    Performs final campaign acceptance, exact parameter audit, strategy effect review, and export-
    ready evidence review.

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
    2. Set the search path.
    3. Drop temporary Module 2 operator, profile, parameter, staging, comparison, validation,
       frontier, and evidence helper objects from prior executions.
    4. Drop the replaceable latest-run strategy output table.
    5. Preserve the governed archive, campaign registry, comparison registry, and evidence tables.

RUN GUIDANCE:
    Use Section 1 for a full rerun from the beginning.

    Do not run Section 1 by itself when the goal is only to:
        rerun Section 15 from the archive,
        run Section 16.9 frontier evidence synchronization,
        or rerun Section 17 post-campaign acceptance.

    Section 1 drops:
        credit_decisioning_sim.strategy_decisions

    That table is the current latest-run output needed by later evidence-capture steps.

PRESERVED GOVERNED OBJECTS:
    credit_decisioning_sim.strategy_decisions_archive
    credit_decisioning_sim.strategy_run_campaign_registry
    credit_decisioning_sim.strategy_comparison_campaign_registry
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
1.1 Create / reuse dedicated simulation schema.

SQL insight:
    CREATE SCHEMA IF NOT EXISTS is non-destructive.
-----------------------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;



/*-----------------------------------------------------------------------------------------------
1.2 Clean reset of temporary operator, profile, and parameter objects.

Business purpose:
    Prevent stale run selectors or stale profile catalogs from influencing the next run.
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
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_current_run_key;
DROP TABLE IF EXISTS tmp_m2_current_run_story_params;



/*-----------------------------------------------------------------------------------------------
1.6 Clean reset of latest-run output table.

Business purpose:
    Clear the replaceable current-run output before Section 11 rebuilds it.

Important:
    This is safe for a full run.
    Do not use this reset immediately before a Section 15 / Section 16.9 / Section 17-only refresh.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 2 — STRATEGY PROFILE, PRODUCT POLICY PROFILE, CAMPAIGN REGISTRY, AND RUN SELECTOR FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize all Module 2 strategy assumptions, product-policy settings, source-selection controls,
    archive controls, profile selections, campaign run IDs, comparison IDs, and documentation labels.

    Section 2 answers:

        "Which governed campaign run, strategy profile, product-policy profile, Module 1 source slice,
         and evidence identifiers should the current Module 2 execution use?"

DESIGN CHANGE IN THIS VERSION:
    Section 2 is now profile-driven.

    Instead of manually editing many numeric thresholds for each formal campaign run, the operator
    selects a run ID:

        selected_module2_run_id = 'M2-01'

    The SQL then derives:
        Module 1 scenario set,
        Module 1 scenario name,
        population,
        strategy name,
        strategy profile,
        product-policy profile,
        module2_run_id,
        strategy_run_id,
        active strategy parameter card,
        active product-policy card,
        campaign registry row,
        and comparison registry rows.

WHY THIS MATTERS:
    The prior manual configuration pattern made it too easy to type a wrong value, rerun the wrong
    strategy, or carry stale documentation labels.

    Profile catalogs reduce operator error and make campaign behavior easier to audit.

BASELINE DEFAULT:
    BASELINE_STRATEGY is the default.

CAMPAIGN CHALLENGER EXAMPLES:
    TIGHTER_SYNTHETIC_RISK_STRATEGY
    GROWTH_ORIENTED_STRATEGY
    TIGHTER_AFFORDABILITY_STRATEGY
    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
    MANUAL_REVIEW_REDUCTION_STRATEGY

CUSTOM USER FLEXIBILITY:
    Users may still create custom strategy and product-policy profiles.

    Custom mode is intentionally supported, but custom runs should be clearly labeled and should not
    be treated as formal campaign evidence unless registry-matched intentionally.

***************************************************************************************************/



/***************************************************************************************************
SECTION 2.1 — OPERATOR RUN SELECTOR
****************************************************************************************************

USER ACTION:
    For ordinary campaign operation, edit only selected_module2_run_id.

DEFAULT:
    M2-01 / BASELINE_V2 / BASELINE_STRATEGY

STANDARD CAMPAIGN EXAMPLES:
    M2-01:
        baseline strategy on BASELINE_V2.

    M2-02:
        tighter synthetic-risk challenger on BASELINE_V2.

    M2-05:
        counteroffer-first challenger on BASELINE_V2.

    M2-29:
        counteroffer-first strategy on HIGH_BALANCE_APPETITE.

    M2-36:
        product guardrail strategy on BROAD_LGD_STRESS.

CUSTOM MODE:
    Set run_mode = 'CUSTOM' only when building an exploratory run outside the formal 36-run campaign.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_operator_run_selector (
    active_selector_flag                         BOOLEAN NOT NULL,
    run_mode                                     TEXT NOT NULL,
    selected_module2_run_id                      TEXT,

    custom_module1_run_id                        TEXT,
    custom_module2_run_id                        TEXT,
    custom_run_sequence_number                   INTEGER,

    custom_module1_scenario_set_name             TEXT,
    custom_module1_scenario_name                 TEXT,
    custom_population_id                         TEXT,

    custom_strategy_set_name                     TEXT,
    custom_strategy_name                         TEXT,
    custom_strategy_version                      TEXT,
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
    selected_module2_run_id
)
VALUES (
    TRUE,
    'STANDARD_CAMPAIGN',
    'M2-01'
);



/***************************************************************************************************
SECTION 2.2 — EXECUTABLE STRATEGY PROFILE CATALOG
****************************************************************************************************

PURPOSE:
    Store the governed strategy-level profiles used by the campaign.

COMMENT STANDARD:
    For each parameter family, use this interpretation:

        Baseline default:
            BASELINE_STRATEGY value.

        Campaign challenger examples:
            Other strategy profile values.

        Downstream use:
            Sections 5 and 6 carry these thresholds into segmentation and trigger flags.
            Sections 7–9 convert triggers into routing, exposure treatment, and final outcomes.

STRATEGY PROFILE SUMMARY:
    BASELINE_STRATEGY:
        default strategy posture.

    TIGHTER_SYNTHETIC_RISK_STRATEGY:
        lowers estimated-risk thresholds.

    GROWTH_ORIENTED_STRATEGY:
        expands estimated-risk and affordability tolerance.

    TIGHTER_AFFORDABILITY_STRATEGY:
        tightens PTI / DTI posture.

    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY:
        keeps baseline global risk posture but uses counteroffer-first product policy.

    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY:
        keeps baseline global risk posture but uses product guardrails for UPL and revolving.

    MANUAL_REVIEW_REDUCTION_STRATEGY:
        keeps baseline offer economics but resolves failed counteroffers to DECLINE.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_strategy_profile_catalog
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM (
    VALUES
        /*******************************************************************************************
        Baseline default.

        This is the accepted V1.0 default strategy posture.
        *******************************************************************************************/
        (
            'BASELINE_STRATEGY_PROFILE',
            'BASELINE_STRATEGY',
            'BASELINE_PRODUCT_POLICY',
            'BASELINE',
            'Module 2 baseline strategy using accepted V1.0 defaults.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.080000, 0.160000, 0.300000, 0.350000,
            0.250000, 0.400000, 0.550000,
            0.430000, 0.600000, 0.600000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
        ),

        /*******************************************************************************************
        Tighter synthetic-risk challenger.

        Parameter movement:
            lowers synthetic estimated-risk thresholds.

        Business intent:
            reduce approved Expected Loss and offered-population risk profile.
        *******************************************************************************************/
        (
            'TIGHTER_SYNTHETIC_RISK_PROFILE',
            'TIGHTER_SYNTHETIC_RISK_STRATEGY',
            'BASELINE_PRODUCT_POLICY',
            'RISK_DISCIPLINE',
            'Tightens synthetic estimated-risk thresholds while keeping baseline product policy.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.060000, 0.120000, 0.250000, 0.300000,
            0.250000, 0.400000, 0.550000,
            0.430000, 0.600000, 0.600000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
        ),

        /*******************************************************************************************
        Growth-oriented challenger.

        Parameter movement:
            expands estimated-risk and affordability tolerance.
            uses growth product policy.

        Business intent:
            increase access and approved amount while making the approved Expected Loss tradeoff
            visible.
        *******************************************************************************************/
        (
            'GROWTH_ORIENTED_PROFILE',
            'GROWTH_ORIENTED_STRATEGY',
            'GROWTH_PRODUCT_POLICY',
            'GROWTH',
            'Expands access and approved exposure using growth-oriented thresholds and caps.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.100000, 0.200000, 0.350000, 0.400000,
            0.280000, 0.430000, 0.580000,
            0.460000, 0.630000, 0.630000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
        ),

        /*******************************************************************************************
        Tighter affordability challenger.

        Parameter movement:
            keeps baseline synthetic-risk thresholds.
            tightens global PTI / DTI posture.
            uses affordability-tight product policy.

        Business intent:
            reduce payment-burden stress and approved PTI.
        *******************************************************************************************/
        (
            'TIGHTER_AFFORDABILITY_PROFILE',
            'TIGHTER_AFFORDABILITY_STRATEGY',
            'AFFORDABILITY_TIGHT_PRODUCT_POLICY',
            'AFFORDABILITY_DISCIPLINE',
            'Tightens affordability posture through global and product PTI controls.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.080000, 0.160000, 0.300000, 0.350000,
            0.220000, 0.350000, 0.500000,
            0.400000, 0.550000, 0.550000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
        ),

        /*******************************************************************************************
        Counteroffer-first exposure challenger.

        Parameter movement:
            keeps baseline global risk posture.
            uses counteroffer-first product policy.

        Business intent:
            preserve access through reduced-exposure offers while reducing approved exposure, approved
            PTI, and approved Expected Loss.
        *******************************************************************************************/
        (
            'COUNTEROFFER_FIRST_PROFILE',
            'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY',
            'COUNTEROFFER_FIRST_PRODUCT_POLICY',
            'COUNTEROFFER_MANAGEMENT',
            'Emphasizes reduced-exposure treatment for exposure and affordability management.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.080000, 0.160000, 0.300000, 0.350000,
            0.250000, 0.400000, 0.550000,
            0.430000, 0.600000, 0.600000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
        ),

        /*******************************************************************************************
        Product-specific guardrail challenger.

        Parameter movement:
            keeps baseline global risk posture.
            tightens unsecured personal loan and revolving line product policy.

        Business intent:
            control higher-LGD unsecured / revolving exposure without disrupting secured and auto
            products.
        *******************************************************************************************/
        (
            'PRODUCT_GUARDRAIL_PROFILE',
            'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY',
            'PRODUCT_GUARDRAIL_PRODUCT_POLICY',
            'PRODUCT_GUARDRAILS',
            'Applies tighter product guardrails to unsecured personal loan and revolving line.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.080000, 0.160000, 0.300000, 0.350000,
            0.250000, 0.400000, 0.550000,
            0.430000, 0.600000, 0.600000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
        ),

        /*******************************************************************************************
        Manual-review reduction challenger.

        Parameter movement:
            keeps baseline strategy economics.
            changes failed counteroffer resolution from MANUAL_REVIEW to DECLINE.

        Business intent:
            test operational review-burden reduction without changing positive-offer economics.
        *******************************************************************************************/
        (
            'MANUAL_REVIEW_REDUCTION_PROFILE',
            'MANUAL_REVIEW_REDUCTION_STRATEGY',
            'BASELINE_PRODUCT_POLICY',
            'REVIEW_BURDEN_REDUCTION',
            'Routes failed counteroffers to DECLINE to reduce unresolved manual review.',
            'MODULE2_V1_0',
            'MODULE2_BASELINE_STRATEGY_SET',
            'V1_0',
            TRUE,
            'ARCHIVE',
            TRUE,
            'STRATEGY_SCENARIO_ONLY',

            0.080000, 0.160000, 0.300000, 0.350000,
            0.250000, 0.400000, 0.550000,
            0.430000, 0.600000, 0.600000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'DECLINE'
        ),

        /*******************************************************************************************
        Custom user-defined profile.

        Edit this row only when run_mode = CUSTOM.

        It starts from baseline values so exploratory users can change only the fields they intend to
        test.
        *******************************************************************************************/
        (
            'CUSTOM_USER_DEFINED_STRATEGY_PROFILE',
            'CUSTOM_USER_DEFINED_STRATEGY',
            'CUSTOM_USER_DEFINED_PRODUCT_POLICY',
            'CUSTOM',
            'User-defined exploratory strategy profile. Edit deliberately and document why.',
            'MODULE2_V1_0',
            'MODULE2_CUSTOM_STRATEGY_SET',
            'V1_0',
            FALSE,
            'ARCHIVE',
            FALSE,
            'STRATEGY_SCENARIO_ONLY',

            0.080000, 0.160000, 0.300000, 0.350000,
            0.250000, 0.400000, 0.550000,
            0.430000, 0.600000, 0.600000,

            0.050000,

            TRUE, TRUE, TRUE, 4,
            TRUE, 0.850000,
            TRUE, 580,

            'APPROVED_AS_REQUESTED',
            TRUE,
            TRUE,
            'NULL_UNRESOLVED',
            'ZERO',
            'ZERO',
            'NULL_UNRESOLVED',
            FALSE,
            'MANUAL_REVIEW'
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
    Store exact product-policy values for every governed campaign product-policy profile.

SUPPORTED PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

PRODUCT-POLICY PROFILE SUMMARY:
    BASELINE_PRODUCT_POLICY:
        default product policy.

    GROWTH_PRODUCT_POLICY:
        increases selected approved amount caps and approved Expected Loss caps.

    AFFORDABILITY_TIGHT_PRODUCT_POLICY:
        tightens product PTI and counteroffer target PTI.

    COUNTEROFFER_FIRST_PRODUCT_POLICY:
        lowers target PTI and approved EL caps while allowing more exposure reduction.

    PRODUCT_GUARDRAIL_PRODUCT_POLICY:
        tightens unsecured personal loan and revolving line only.

    CUSTOM_USER_DEFINED_PRODUCT_POLICY:
        user-editable exploratory product policy starting from baseline values.

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
        ('BASELINE_PRODUCT_POLICY','MORTGAGE',0.350000,0.450000,0.550000,0.320000,10000.00,20000.00,40000.00,10000.00,75000.00,800000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',5000.00),
        ('BASELINE_PRODUCT_POLICY','HELOC',0.250000,0.350000,0.450000,0.220000,8000.00,16000.00,30000.00,7000.00,10000.00,175000.00,TRUE,TRUE,0.400000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',1000.00),
        ('BASELINE_PRODUCT_POLICY','AUTO_LOAN',0.180000,0.280000,0.380000,0.160000,3500.00,7000.00,12000.00,3000.00,5000.00,65000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('BASELINE_PRODUCT_POLICY','UNSECURED_PERSONAL_LOAN',0.150000,0.250000,0.350000,0.130000,3000.00,6000.00,10000.00,2500.00,1000.00,35000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('BASELINE_PRODUCT_POLICY','REVOLVING_LINE',0.120000,0.200000,0.300000,0.100000,2000.00,4000.00,8000.00,1800.00,1000.00,20000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),

        /*******************************************************************************************
        GROWTH_PRODUCT_POLICY

        Baseline product rules with higher approved exposure and approved EL caps.
        *******************************************************************************************/
        ('GROWTH_PRODUCT_POLICY','MORTGAGE',0.350000,0.450000,0.550000,0.320000,10000.00,20000.00,40000.00,11000.00,75000.00,880000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',5000.00),
        ('GROWTH_PRODUCT_POLICY','HELOC',0.250000,0.350000,0.450000,0.220000,8000.00,16000.00,30000.00,7700.00,10000.00,192500.00,TRUE,TRUE,0.400000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',1000.00),
        ('GROWTH_PRODUCT_POLICY','AUTO_LOAN',0.180000,0.280000,0.380000,0.160000,3500.00,7000.00,12000.00,3300.00,5000.00,71500.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('GROWTH_PRODUCT_POLICY','UNSECURED_PERSONAL_LOAN',0.150000,0.250000,0.350000,0.130000,3000.00,6000.00,10000.00,2750.00,1000.00,38500.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('GROWTH_PRODUCT_POLICY','REVOLVING_LINE',0.120000,0.200000,0.300000,0.100000,2000.00,4000.00,8000.00,1980.00,1000.00,22000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),

        /*******************************************************************************************
        AFFORDABILITY_TIGHT_PRODUCT_POLICY

        Product PTI thresholds and counteroffer target PTI tightened.
        *******************************************************************************************/
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY','MORTGAGE',0.320000,0.420000,0.520000,0.290000,10000.00,20000.00,40000.00,10000.00,75000.00,800000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',5000.00),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY','HELOC',0.220000,0.320000,0.420000,0.190000,8000.00,16000.00,30000.00,7000.00,10000.00,175000.00,TRUE,TRUE,0.400000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',1000.00),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY','AUTO_LOAN',0.160000,0.250000,0.350000,0.140000,3500.00,7000.00,12000.00,3000.00,5000.00,65000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY','UNSECURED_PERSONAL_LOAN',0.130000,0.220000,0.320000,0.110000,3000.00,6000.00,10000.00,2500.00,1000.00,35000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('AFFORDABILITY_TIGHT_PRODUCT_POLICY','REVOLVING_LINE',0.100000,0.180000,0.280000,0.080000,2000.00,4000.00,8000.00,1800.00,1000.00,20000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),

        /*******************************************************************************************
        COUNTEROFFER_FIRST_PRODUCT_POLICY

        Designed to make reduced-exposure treatment more active and more feasible.
        *******************************************************************************************/
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY','MORTGAGE',0.330000,0.450000,0.550000,0.300000,8500.00,18000.00,40000.00,8000.00,75000.00,700000.00,TRUE,TRUE,0.400000,0.600000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',5000.00),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY','HELOC',0.235000,0.350000,0.450000,0.200000,6800.00,14500.00,30000.00,5600.00,10000.00,150000.00,TRUE,TRUE,0.350000,0.600000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',1000.00),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY','AUTO_LOAN',0.170000,0.280000,0.380000,0.145000,3000.00,6300.00,12000.00,2400.00,5000.00,57500.00,TRUE,TRUE,0.450000,0.550000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY','UNSECURED_PERSONAL_LOAN',0.140000,0.250000,0.350000,0.115000,2500.00,5400.00,10000.00,2000.00,1000.00,30000.00,TRUE,TRUE,0.400000,0.600000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('COUNTEROFFER_FIRST_PRODUCT_POLICY','REVOLVING_LINE',0.110000,0.200000,0.300000,0.090000,1700.00,3600.00,8000.00,1400.00,1000.00,17500.00,TRUE,TRUE,0.400000,0.600000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),

        /*******************************************************************************************
        PRODUCT_GUARDRAIL_PRODUCT_POLICY

        Leaves MORTGAGE, HELOC, and AUTO_LOAN at baseline.
        Tightens UNSECURED_PERSONAL_LOAN and REVOLVING_LINE.
        *******************************************************************************************/
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY','MORTGAGE',0.350000,0.450000,0.550000,0.320000,10000.00,20000.00,40000.00,10000.00,75000.00,800000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',5000.00),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY','HELOC',0.250000,0.350000,0.450000,0.220000,8000.00,16000.00,30000.00,7000.00,10000.00,175000.00,TRUE,TRUE,0.400000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',1000.00),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY','AUTO_LOAN',0.180000,0.280000,0.380000,0.160000,3500.00,7000.00,12000.00,3000.00,5000.00,65000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY','UNSECURED_PERSONAL_LOAN',0.130000,0.220000,0.320000,0.110000,2500.00,5000.00,8500.00,2000.00,1000.00,27500.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('PRODUCT_GUARDRAIL_PRODUCT_POLICY','REVOLVING_LINE',0.100000,0.180000,0.280000,0.080000,1500.00,3200.00,6500.00,1400.00,1000.00,16000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),

        /*******************************************************************************************
        CUSTOM_USER_DEFINED_PRODUCT_POLICY

        Starts from baseline values. Edit only for custom experiments.
        *******************************************************************************************/
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY','MORTGAGE',0.350000,0.450000,0.550000,0.320000,10000.00,20000.00,40000.00,10000.00,75000.00,800000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',5000.00),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY','HELOC',0.250000,0.350000,0.450000,0.220000,8000.00,16000.00,30000.00,7000.00,10000.00,175000.00,TRUE,TRUE,0.400000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',1000.00),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY','AUTO_LOAN',0.180000,0.280000,0.380000,0.160000,3500.00,7000.00,12000.00,3000.00,5000.00,65000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY','UNSECURED_PERSONAL_LOAN',0.150000,0.250000,0.350000,0.130000,3000.00,6000.00,10000.00,2500.00,1000.00,35000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00),
        ('CUSTOM_USER_DEFINED_PRODUCT_POLICY','REVOLVING_LINE',0.120000,0.200000,0.300000,0.100000,2000.00,4000.00,8000.00,1800.00,1000.00,20000.00,TRUE,TRUE,0.500000,0.500000,'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',500.00)
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

    Example:
        PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY should use PRODUCT_GUARDRAIL_PRODUCT_POLICY.
        COUNTEROFFER_FIRST_EXPOSURE_STRATEGY should use COUNTEROFFER_FIRST_PRODUCT_POLICY.
        TIGHTER_AFFORDABILITY_STRATEGY should use AFFORDABILITY_TIGHT_PRODUCT_POLICY.

    Section 3 validates this pairing before applicant-level logic runs.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_strategy_product_policy_compatibility
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM (
    VALUES
        ('BASELINE_STRATEGY_PROFILE', 'BASELINE_STRATEGY', 'BASELINE_PRODUCT_POLICY', TRUE),
        ('TIGHTER_SYNTHETIC_RISK_PROFILE', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'BASELINE_PRODUCT_POLICY', TRUE),
        ('GROWTH_ORIENTED_PROFILE', 'GROWTH_ORIENTED_STRATEGY', 'GROWTH_PRODUCT_POLICY', TRUE),
        ('TIGHTER_AFFORDABILITY_PROFILE', 'TIGHTER_AFFORDABILITY_STRATEGY', 'AFFORDABILITY_TIGHT_PRODUCT_POLICY', TRUE),
        ('COUNTEROFFER_FIRST_PROFILE', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'COUNTEROFFER_FIRST_PRODUCT_POLICY', TRUE),
        ('PRODUCT_GUARDRAIL_PROFILE', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'PRODUCT_GUARDRAIL_PRODUCT_POLICY', TRUE),
        ('MANUAL_REVIEW_REDUCTION_PROFILE', 'MANUAL_REVIEW_REDUCTION_STRATEGY', 'BASELINE_PRODUCT_POLICY', TRUE),
        ('CUSTOM_USER_DEFINED_STRATEGY_PROFILE', 'CUSTOM_USER_DEFINED_STRATEGY', 'CUSTOM_USER_DEFINED_PRODUCT_POLICY', FALSE)
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
    Define the formal 36-run campaign roadmap.

SQL DESIGN:
    module2_run_id is derived from run_sequence_number:

        'M2-' || LPAD(run_sequence_number::TEXT, 2, '0')

    strategy_run_id is later derived from:

        module2_run_id || '_' || strategy_name || '_' || strategy_version || '_RUN'

WHY DERIVE RUN IDs:
    Reruns should preserve the same run ID.
    Run IDs should not be generated from database max values.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_campaign_run_catalog
ON COMMIT PRESERVE ROWS
AS
SELECT
    c.*,
    'M2-' || LPAD(c.run_sequence_number::TEXT, 2, '0') AS module2_run_id
FROM (
    VALUES
        (1,'M1-01','SC01','Baseline Strategy Frontier',NULL,'VE01','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','BASELINE','Baseline default strategy.','Establish baseline Module 2 behavior on BASELINE_V2.','Baseline strategy evidence','Baseline strategy reference',1,TRUE),

        (2,'M1-01','SC01','Baseline Strategy Frontier','CG01','VE02','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','TIGHTER_SYNTHETIC_RISK_PROFILE','BASELINE_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','RISK_DISCIPLINE','Tighter synthetic estimated-risk thresholds.','Compare baseline with tighter synthetic-risk appetite.','Tighter risk evidence','Tighter synthetic-risk challenger',2,TRUE),
        (3,'M1-01','SC01','Baseline Strategy Frontier','CG02','VE03','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','GROWTH_ORIENTED_PROFILE','GROWTH_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','GROWTH','Growth-oriented thresholds and product policy.','Compare baseline with growth-oriented strategy.','Growth strategy evidence','Growth-oriented challenger',3,TRUE),
        (4,'M1-01','SC01','Baseline Strategy Frontier','CG03','VE04','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','TIGHTER_AFFORDABILITY_PROFILE','AFFORDABILITY_TIGHT_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','AFFORDABILITY_DISCIPLINE','Tighter affordability thresholds and product PTI policy.','Compare baseline with tighter affordability strategy.','Affordability evidence','Tighter affordability challenger',4,TRUE),
        (5,'M1-01','SC01','Baseline Strategy Frontier','CG04','VE05','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','COUNTEROFFER_FIRST_PROFILE','COUNTEROFFER_FIRST_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','COUNTEROFFER_MANAGEMENT','Counteroffer-first product policy.','Compare baseline with counteroffer-first exposure strategy.','Counteroffer evidence','Counteroffer-first challenger',5,TRUE),
        (6,'M1-01','SC01','Baseline Strategy Frontier','CG05','VE06','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','PRODUCT_GUARDRAILS','Product guardrails for unsecured and revolving exposure.','Compare baseline with product-specific guardrails.','Product guardrail evidence','Product guardrail challenger',6,TRUE),
        (7,'M1-01','SC01','Baseline Strategy Frontier','CG06','VE07','MODULE1_V2_BASELINE_SET','BASELINE_V2','BASE_POPULATION_V1','MANUAL_REVIEW_REDUCTION_PROFILE','BASELINE_PRODUCT_POLICY','BASELINE','Module 1 baseline scenario.','REVIEW_BURDEN_REDUCTION','Failed counteroffers resolve to decline.','Compare baseline with manual-review reduction strategy.','Manual review reduction evidence','Manual-review reduction challenger',7,TRUE),

        (8,'M1-02','SC02','Rate Environment Sensitivity',NULL,'VE08','MODULE1_V2_BASELINE_SET','RATE_UP_200BP','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 rate-up 200bp scenario.','BASELINE','Baseline strategy under rate-up 200bp.','Evaluate baseline behavior under 200bp rate stress.','Rate-up 200 baseline evidence','Rate-up 200 baseline',8,TRUE),
        (9,'M1-03','SC02','Rate Environment Sensitivity',NULL,'VE09','MODULE1_V2_BASELINE_SET','RATE_DOWN_200BP','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 rate-down 200bp scenario.','BASELINE','Baseline strategy under rate-down 200bp.','Evaluate baseline behavior under 200bp rate relief.','Rate-down baseline evidence','Rate-down 200 baseline',9,TRUE),
        (10,'M1-04','SC02','Rate Environment Sensitivity',NULL,'VE10','MODULE1_V2_BASELINE_SET','RATE_UP_300BP','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 rate-up 300bp scenario.','BASELINE','Baseline strategy under rate-up 300bp.','Evaluate baseline behavior under 300bp rate stress.','Rate-up 300 baseline evidence','Rate-up 300 baseline',10,TRUE),
        (11,'M1-02','SC02','Rate Environment Sensitivity','CG07','VE11','MODULE1_V2_BASELINE_SET','RATE_UP_200BP','BASE_POPULATION_V1','TIGHTER_AFFORDABILITY_PROFILE','AFFORDABILITY_TIGHT_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 rate-up 200bp scenario.','AFFORDABILITY_DISCIPLINE','Tighter affordability strategy under rate stress.','Evaluate tighter affordability under 200bp rate stress.','Rate-up 200 affordability evidence','Rate-up 200 affordability challenger',11,TRUE),
        (12,'M1-04','SC02','Rate Environment Sensitivity','CG08','VE12','MODULE1_V2_BASELINE_SET','RATE_UP_300BP','BASE_POPULATION_V1','TIGHTER_AFFORDABILITY_PROFILE','AFFORDABILITY_TIGHT_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 rate-up 300bp scenario.','AFFORDABILITY_DISCIPLINE','Tighter affordability strategy under heavier rate stress.','Evaluate tighter affordability under 300bp rate stress.','Rate-up 300 affordability evidence','Rate-up 300 affordability challenger',12,TRUE),
        (13,'M1-03','SC02','Rate Environment Sensitivity','CG09','VE13','MODULE1_V2_BASELINE_SET','RATE_DOWN_200BP','BASE_POPULATION_V1','GROWTH_ORIENTED_PROFILE','GROWTH_PRODUCT_POLICY','RATE_ENVIRONMENT','Module 1 rate-down 200bp scenario.','GROWTH','Growth strategy under rate relief.','Evaluate growth under rate relief.','Rate-down growth evidence','Rate-down growth challenger',13,TRUE),

        (14,'M1-05','SC03','Credit Box Sensitivity',NULL,'VE14','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','CREDIT_BOX_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Credit-box baseline reference scenario.','BASELINE','Baseline strategy on credit-box reference.','Establish credit-box reference behavior.','Credit-box reference evidence','Credit-box reference baseline',14,TRUE),
        (15,'M1-06','SC03','Credit Box Sensitivity',NULL,'VE15','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','PRIME_GROWTH_SCORE_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Prime-growth score mix scenario.','BASELINE','Baseline strategy on prime-growth score mix.','Evaluate baseline under stronger score mix.','Prime growth evidence','Prime growth baseline',15,TRUE),
        (16,'M1-07','SC03','Credit Box Sensitivity',NULL,'VE16','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','NEAR_PRIME_EXPANSION_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Near-prime expansion score mix scenario.','BASELINE','Baseline strategy on near-prime expansion.','Evaluate baseline under near-prime expansion.','Near-prime baseline evidence','Near-prime expansion baseline',16,TRUE),
        (17,'M1-07','SC03','Credit Box Sensitivity','CG10','VE17','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','NEAR_PRIME_EXPANSION_MIX','BASE_POPULATION_V1','TIGHTER_SYNTHETIC_RISK_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Near-prime expansion score mix scenario.','RISK_DISCIPLINE','Tighter synthetic-risk strategy under near-prime expansion.','Evaluate risk discipline under near-prime expansion.','Near-prime tighter risk evidence','Near-prime tighter risk challenger',17,TRUE),
        (18,'M1-07','SC03','Credit Box Sensitivity','CG11','VE18','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','NEAR_PRIME_EXPANSION_MIX','BASE_POPULATION_V1','COUNTEROFFER_FIRST_PROFILE','COUNTEROFFER_FIRST_PRODUCT_POLICY','CREDIT_BOX','Near-prime expansion score mix scenario.','COUNTEROFFER_MANAGEMENT','Counteroffer-first strategy under near-prime expansion.','Evaluate counteroffer-first under near-prime expansion.','Near-prime counteroffer evidence','Near-prime counteroffer challenger',18,TRUE),
        (19,'M1-08','SC03','Credit Box Sensitivity',NULL,'VE19','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','CREDIT_STRESS_SCORE_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Credit-stress score mix scenario.','BASELINE','Baseline strategy on credit-stress score mix.','Evaluate baseline under credit stress.','Credit stress baseline evidence','Credit stress baseline',19,TRUE),
        (20,'M1-08','SC03','Credit Box Sensitivity','CG12','VE20','MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET','CREDIT_STRESS_SCORE_MIX','BASE_POPULATION_V1','TIGHTER_SYNTHETIC_RISK_PROFILE','BASELINE_PRODUCT_POLICY','CREDIT_BOX','Credit-stress score mix scenario.','RISK_DISCIPLINE','Tighter risk strategy under credit stress.','Evaluate risk discipline under credit stress.','Credit stress tighter risk evidence','Credit stress risk challenger',20,TRUE),

        (21,'M1-09','SC04','Portfolio Mix Sensitivity',NULL,'VE21','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','PORTFOLIO_MIX_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Portfolio-mix baseline reference scenario.','BASELINE','Baseline strategy on portfolio-mix reference.','Establish product-mix reference behavior.','Portfolio mix reference evidence','Portfolio mix reference baseline',21,TRUE),
        (22,'M1-10','SC04','Portfolio Mix Sensitivity',NULL,'VE22','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','UNSECURED_GROWTH_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Unsecured growth product-mix scenario.','BASELINE','Baseline strategy on unsecured growth mix.','Evaluate baseline under unsecured growth.','Unsecured growth baseline evidence','Unsecured growth baseline',22,TRUE),
        (23,'M1-10','SC04','Portfolio Mix Sensitivity','CG13','VE23','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','UNSECURED_GROWTH_MIX','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','PRODUCT_MIX','Unsecured growth product-mix scenario.','PRODUCT_GUARDRAILS','Product guardrails under unsecured growth.','Evaluate product guardrails under unsecured growth.','Unsecured growth guardrail evidence','Unsecured growth guardrails',23,TRUE),
        (24,'M1-11','SC04','Portfolio Mix Sensitivity',NULL,'VE24','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','SECURED_BALANCE_GROWTH_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Secured balance growth product-mix scenario.','BASELINE','Baseline strategy on secured-balance growth.','Evaluate baseline under secured-balance growth.','Secured balance growth evidence','Secured balance baseline',24,TRUE),
        (25,'M1-12','SC04','Portfolio Mix Sensitivity',NULL,'VE25','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','REVOLVING_LINE_EXPANSION_MIX','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','PRODUCT_MIX','Revolving-line expansion product-mix scenario.','BASELINE','Baseline strategy on revolving expansion.','Evaluate baseline under revolving-line expansion.','Revolving expansion baseline evidence','Revolving expansion baseline',25,TRUE),
        (26,'M1-12','SC04','Portfolio Mix Sensitivity','CG14','VE26','MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET','REVOLVING_LINE_EXPANSION_MIX','BASE_POPULATION_V1','PRODUCT_GUARDRAIL_PROFILE','PRODUCT_GUARDRAIL_PRODUCT_POLICY','PRODUCT_MIX','Revolving-line expansion product-mix scenario.','PRODUCT_GUARDRAILS','Product guardrails under revolving expansion.','Evaluate product guardrails under revolving-line expansion.','Revolving expansion guardrail evidence','Revolving expansion guardrails',26,TRUE),

        (27,'M1-13','SC05','Exposure Intensity Sensitivity',NULL,'VE27','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','EXPOSURE_BASELINE_REFERENCE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','EXPOSURE_INTENSITY','Exposure-intensity baseline reference scenario.','BASELINE','Baseline strategy on exposure reference.','Establish exposure-intensity reference behavior.','Exposure reference evidence','Exposure reference baseline',27,TRUE),
        (28,'M1-14','SC05','Exposure Intensity Sensitivity',NULL,'VE28','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','HIGH_BALANCE_APPETITE','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','EXPOSURE_INTENSITY','High-balance appetite scenario.','BASELINE','Baseline strategy under higher requested exposure intensity.','Evaluate baseline under high-balance appetite.','High-balance baseline evidence','High-balance baseline',28,TRUE),
        (29,'M1-14','SC05','Exposure Intensity Sensitivity','CG15','VE29','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','HIGH_BALANCE_APPETITE','BASE_POPULATION_V1','COUNTEROFFER_FIRST_PROFILE','COUNTEROFFER_FIRST_PRODUCT_POLICY','EXPOSURE_INTENSITY','High-balance appetite scenario.','COUNTEROFFER_MANAGEMENT','Counteroffer-first strategy under high-balance appetite.','Evaluate counteroffer treatment under high-balance appetite.','High-balance counteroffer evidence','High-balance counteroffer challenger',29,TRUE),
        (30,'M1-15','SC05','Exposure Intensity Sensitivity',NULL,'VE30','MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET','LOW_BALANCE_CONSERVATIVE_REQUESTS','BASE_POPULATION_V1','BASELINE_STRATEGY_PROFILE','BASELINE_PRODUCT_POLICY','EXPOSURE_INTENSITY','Low-balance conservative requests scenario.','BASELINE','Baseline strategy under lower requested exposure intensity.','Evaluate baseline under low-balance conservative requests.','Low-balance baseline evidence','Low-balance baseline',30,TRUE),

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
****************************************************************************************************/

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
        op.custom_strategy_profile_code AS strategy_profile_code,
        op.custom_product_policy_profile_code AS product_policy_profile_code,
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



/* Active strategy parameter card. */
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

    /***********************************************************************************************
    strategy_run_id is generated from existing identifiers.

    This avoids hand-editing:
        M2-29_COUNTEROFFER_FIRST_EXPOSURE_STRATEGY_V1_0_RUN

    and makes reruns deterministic.
    ***********************************************************************************************/
    sr.module2_run_id || '_' || sp.strategy_name || '_' || sp.strategy_version || '_RUN'
        AS strategy_run_id,

    CURRENT_TIMESTAMP AS strategy_run_ts,

    sp.default_archive_run_flag AS archive_run_flag,
    sp.default_strategy_archive_reset_mode AS strategy_archive_reset_mode,

    sp.standard_campaign_profile_flag AS standard_campaign_profile_flag,

    CASE
        WHEN sr.run_mode = 'STANDARD_CAMPAIGN' THEN TRUE
        ELSE FALSE
    END AS campaign_registry_required_flag,

    sp.default_module1_input_source AS module1_input_source,

    sr.module1_scenario_set_name AS source_module1_scenario_set_name,
    sr.module1_scenario_name AS source_module1_scenario_name,
    sr.population_id AS source_population_id,

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


/* Active product-policy parameter card. */
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

FROM tmp_module2_product_policy_profile_catalog pp

JOIN tmp_module2_strategy_params sp
    ON sp.product_policy_profile_code = pp.product_policy_profile_code

WHERE sp.active_strategy_flag IS TRUE;



/***************************************************************************************************
SECTION 2.7 — CREATE / HARDEN PERSISTENT STRATEGY RUN CAMPAIGN REGISTRY
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


/* Run-ID and technical-key indexes. */
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


/* Reset active comparison to CG01 unless the user changes it after Section 2. */
UPDATE credit_decisioning_sim.strategy_comparison_campaign_registry
SET
    active_comparison_flag = FALSE,
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE active_comparison_flag IS TRUE;



/***************************************************************************************************
SECTION 2.10 — SEED / UPDATE STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************/

WITH comparison_plan AS (
    SELECT *
    FROM (
        VALUES
            ('CG01','Baseline vs Tighter Synthetic Risk','SC01','Baseline Strategy Frontier','M2-01','M2-02','Tighter synthetic-risk discipline','approved Expected Loss reduction',TRUE),
            ('CG02','Baseline vs Growth Oriented','SC01','Baseline Strategy Frontier','M2-01','M2-03','Growth expansion tradeoff','offer exposure and approved amount growth',FALSE),
            ('CG03','Baseline vs Tighter Affordability','SC01','Baseline Strategy Frontier','M2-01','M2-04','Affordability discipline tradeoff','approved PTI discipline',FALSE),
            ('CG04','Baseline vs Counteroffer First','SC01','Baseline Strategy Frontier','M2-01','M2-05','Counteroffer-first exposure management','counteroffer rate and exposure reduction',FALSE),
            ('CG05','Baseline vs Product Guardrails','SC01','Baseline Strategy Frontier','M2-01','M2-06','Product-specific guardrail effect','product-level approved EL reduction',FALSE),
            ('CG06','Baseline vs Manual Review Reduction','SC01','Baseline Strategy Frontier','M2-01','M2-07','Manual-review burden reduction','manual-review rate reduction',FALSE),

            ('CG07','Rate-Up 200bp Baseline vs Affordability Tight','SC02','Rate Environment Sensitivity','M2-08','M2-11','Affordability under 200bp rate stress','approved PTI under rate stress',FALSE),
            ('CG08','Rate-Up 300bp Baseline vs Affordability Tight','SC02','Rate Environment Sensitivity','M2-10','M2-12','Affordability under 300bp rate stress','approved PTI under severe rate stress',FALSE),
            ('CG09','Rate-Down 200bp Baseline vs Growth','SC02','Rate Environment Sensitivity','M2-09','M2-13','Growth under rate relief','offer growth under rate relief',FALSE),

            ('CG10','Near-Prime Baseline vs Tighter Risk','SC03','Credit Box Sensitivity','M2-16','M2-17','Risk discipline under near-prime expansion','approved EL reduction',FALSE),
            ('CG11','Near-Prime Baseline vs Counteroffer First','SC03','Credit Box Sensitivity','M2-16','M2-18','Counteroffer management under near-prime expansion','counteroffer rate and exposure reduction',FALSE),
            ('CG12','Credit Stress Baseline vs Tighter Risk','SC03','Credit Box Sensitivity','M2-19','M2-20','Risk discipline under credit stress','approved EL reduction under stress',FALSE),

            ('CG13','Unsecured Growth Baseline vs Product Guardrails','SC04','Portfolio Mix Sensitivity','M2-22','M2-23','Product guardrails under unsecured growth','unsecured approved EL reduction',FALSE),
            ('CG14','Revolving Expansion Baseline vs Product Guardrails','SC04','Portfolio Mix Sensitivity','M2-25','M2-26','Product guardrails under revolving expansion','revolving approved EL reduction',FALSE),

            ('CG15','High-Balance Baseline vs Counteroffer First','SC05','Exposure Intensity Sensitivity','M2-28','M2-29','Counteroffer management under high-balance appetite','approved exposure reduction',FALSE),

            ('CG16','Unsecured Severity Baseline vs Product Guardrails','SC06','LGD Severity Sensitivity','M2-33','M2-34','Product guardrails under unsecured severity stress','approved EL reduction under severity stress',FALSE),
            ('CG17','Broad LGD Baseline vs Product Guardrails','SC06','LGD Severity Sensitivity','M2-35','M2-36','Product guardrails under broad LGD stress','approved EL reduction under broad severity stress',FALSE)
    ) AS v(
        comparison_group_id,
        comparison_set_name,
        showcase_id,
        showcase_name,
        baseline_module2_run_id,
        challenger_module2_run_id,
        expected_comparison_storyline,
        primary_metric_focus,
        active_comparison_flag
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
        b.population_id

    FROM comparison_plan cp

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
    TRUE,
    CURRENT_TIMESTAMP

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
SECTION 2.11 — SETUP REVIEW OUTPUTS
****************************************************************************************************/

SELECT
    'ACTIVE_MODULE2_RUN_SELECTOR' AS diagnostic_name,
    *
FROM tmp_m2_operator_run_selector
WHERE active_selector_flag IS TRUE;


SELECT
    'ACTIVE_STRATEGY_PARAMETER_CARD' AS diagnostic_name,

    run_mode,
    module2_run_id,
    run_sequence_number,
    strategy_profile_code,
    product_policy_profile_code,

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

    failed_counteroffer_resolution

FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;


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

    product_min_counteroffer_pct,
    product_max_exposure_reduction_pct

FROM tmp_module2_product_policy_params
ORDER BY product_type;


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



/***************************************************************************************************
SECTION 3 — FAIL-FAST STRATEGY PARAMETER, SOURCE, PRODUCT POLICY, PROFILE, AND REGISTRY GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Stop invalid strategy configuration, incompatible strategy / product-policy pairing, malformed
    source selection, incomplete product-policy setup, or missing formal registry linkage before any
    applicant-level strategy logic runs.

    Section 3 answers:

        "Is the selected run configured well enough to proceed into Module 1 source staging,
         segmentation, trigger construction, decision routing, exposure treatment, archive
         persistence, comparison, validation, frontier analysis, and evidence capture?"

WHY FAIL FAST:
    A failed run is safer than a successful run under the wrong parameter card.

    Section 3 prevents:
        stale run selector usage,
        wrong product-policy profile,
        invalid threshold ordering,
        bad source selection,
        duplicate source rows,
        missing product policy,
        broken decision conventions,
        and missing formal campaign registry linkage.

***************************************************************************************************/



/***************************************************************************************************
SECTION 3.1 — ACTIVE STRATEGY, PRODUCT POLICY, PROFILE, AND THRESHOLD GATEKEEPER
****************************************************************************************************/

DO $$
DECLARE
    p RECORD;

    v_active_selector_count BIGINT;
    v_selected_run_count BIGINT;
    v_active_strategy_count BIGINT;
    v_product_policy_count BIGINT;
    v_supported_product_count BIGINT;
    v_duplicate_product_count BIGINT;
    v_unsupported_product_count BIGINT;
    v_missing_supported_product_count BIGINT;
    v_bad_product_policy_count BIGINT;
    v_profile_mismatch_count BIGINT;
BEGIN
    /* Exactly one active operator selector. */
    SELECT COUNT(*)
    INTO v_active_selector_count
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE;

    IF v_active_selector_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected exactly one active operator run selector, found %.',
            v_active_selector_count;
    END IF;


    /* Exactly one selected run configuration. */
    SELECT COUNT(*)
    INTO v_selected_run_count
    FROM tmp_m2_selected_run_config;

    IF v_selected_run_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected exactly one selected run configuration, found %.',
            v_selected_run_count;
    END IF;


    /* Exactly one active strategy parameter row. */
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;

    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;


    /* Required strategy identity fields. */
    IF p.module2_model_version IS NULL OR NULLIF(BTRIM(p.module2_model_version), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: module2_model_version must be populated.';
    END IF;

    IF p.strategy_set_name IS NULL OR NULLIF(BTRIM(p.strategy_set_name), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_set_name must be populated.';
    END IF;

    IF p.strategy_name IS NULL OR NULLIF(BTRIM(p.strategy_name), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_name must be populated.';
    END IF;

    IF p.strategy_version IS NULL OR NULLIF(BTRIM(p.strategy_version), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_version must be populated.';
    END IF;

    IF p.strategy_run_id IS NULL OR NULLIF(BTRIM(p.strategy_run_id), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_run_id must be populated.';
    END IF;

    IF p.strategy_run_id <> p.module2_run_id || '_' || p.strategy_name || '_' || p.strategy_version || '_RUN' THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: strategy_run_id does not match deterministic run-ID convention. Found: %, expected: %.',
            p.strategy_run_id,
            p.module2_run_id || '_' || p.strategy_name || '_' || p.strategy_version || '_RUN';
    END IF;

    IF p.strategy_run_ts IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_run_ts must be populated.';
    END IF;


    /* Standard campaign mode requirements. */
    IF p.run_mode = 'STANDARD_CAMPAIGN' THEN
        IF p.campaign_registry_required_flag IS DISTINCT FROM TRUE THEN
            RAISE EXCEPTION 'Module 2 Section 3 failure: STANDARD_CAMPAIGN runs require campaign_registry_required_flag = TRUE.';
        END IF;

        IF p.module1_input_source <> 'ARCHIVE' THEN
            RAISE EXCEPTION 'Module 2 Section 3 failure: STANDARD_CAMPAIGN runs should consume Module 1 ARCHIVE input.';
        END IF;

        IF p.standard_campaign_profile_flag IS DISTINCT FROM TRUE THEN
            RAISE EXCEPTION 'Module 2 Section 3 failure: selected STANDARD_CAMPAIGN strategy profile is not marked as standard campaign compatible.';
        END IF;
    END IF;


    /* Module 1 input source controls. */
    IF p.module1_input_source IS NULL OR p.module1_input_source NOT IN ('LATEST', 'ARCHIVE') THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
            COALESCE(p.module1_input_source, '<NULL>');
    END IF;

    IF p.module1_input_source = 'ARCHIVE'
       AND (
            p.source_module1_scenario_set_name IS NULL
         OR NULLIF(BTRIM(p.source_module1_scenario_set_name), '') IS NULL
         OR p.source_module1_scenario_name IS NULL
         OR NULLIF(BTRIM(p.source_module1_scenario_name), '') IS NULL
         OR p.source_population_id IS NULL
         OR NULLIF(BTRIM(p.source_population_id), '') IS NULL
       ) THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: ARCHIVE input requires source_module1_scenario_set_name, source_module1_scenario_name, and source_population_id.';
    END IF;


    /* Archive controls. */
    IF p.archive_run_flag IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: archive_run_flag must not be NULL.';
    END IF;

    IF p.strategy_archive_reset_mode IS NULL
       OR p.strategy_archive_reset_mode NOT IN ('NONE','STRATEGY_SCENARIO_ONLY','STRATEGY_SET_ONLY','ALL') THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: invalid strategy_archive_reset_mode: %.',
            COALESCE(p.strategy_archive_reset_mode, '<NULL>');
    END IF;


    /* Synthetic estimated-risk threshold ordering. */
    IF NOT (
        p.approve_max_estimated_pd_proxy < p.counteroffer_max_estimated_pd_proxy
        AND p.counteroffer_max_estimated_pd_proxy < p.review_max_estimated_pd_proxy
        AND p.review_max_estimated_pd_proxy <= p.decline_min_estimated_pd_proxy
    ) THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: estimated-risk threshold ordering is invalid.';
    END IF;


    /* PTI and DTI threshold ordering. */
    IF NOT (
        p.global_approve_max_pti < p.global_review_max_pti
        AND p.global_review_max_pti <= p.global_decline_min_pti
    ) THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: global PTI threshold ordering is invalid.';
    END IF;

    IF NOT (
        p.approve_max_dti < p.review_max_dti
        AND p.review_max_dti <= p.decline_min_dti
    ) THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: DTI threshold ordering is invalid.';
    END IF;


    /* Diagnostic buffer. */
    IF p.borderline_threshold_buffer_pct IS NULL
       OR p.borderline_threshold_buffer_pct < 0
       OR p.borderline_threshold_buffer_pct > 0.250000 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: borderline_threshold_buffer_pct must be between 0 and 0.25.';
    END IF;


    /* Rule controls. */
    IF p.bankruptcy_policy_stop_enabled IS NULL
       OR p.major_derogatory_policy_stop_enabled IS NULL
       OR p.severe_delinquency_policy_stop_enabled IS NULL
       OR p.high_utilization_review_enabled IS NULL
       OR p.low_score_review_enabled IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: rule-control Boolean parameters must not be NULL.';
    END IF;

    IF p.severe_delinquency_count_threshold IS NULL
       OR p.severe_delinquency_count_threshold < 0 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: severe_delinquency_count_threshold must be non-negative.';
    END IF;

    IF p.high_utilization_review_threshold IS NULL
       OR p.high_utilization_review_threshold < 0
       OR p.high_utilization_review_threshold > 1 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: high_utilization_review_threshold must be between 0 and 1.';
    END IF;

    IF p.low_score_review_threshold IS NULL
       OR p.low_score_review_threshold < 300
       OR p.low_score_review_threshold > 850 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: low_score_review_threshold must be between 300 and 850.';
    END IF;


    /* Decision conventions. */
    IF p.approve_reason_code <> 'APPROVED_AS_REQUESTED' THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: approve_reason_code must equal APPROVED_AS_REQUESTED.';
    END IF;

    IF p.reason_code_required_flag IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: reason_code_required_flag must be TRUE.';
    END IF;

    IF p.simulated_offer_exposure_flag_enabled IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: simulated_offer_exposure_flag_enabled must be TRUE.';
    END IF;

    IF p.manual_review_approved_amount_convention <> 'NULL_UNRESOLVED'
       OR p.approved_el_manual_review_convention <> 'NULL_UNRESOLVED' THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: manual-review conventions must be NULL_UNRESOLVED.';
    END IF;

    IF p.decline_approved_amount_convention <> 'ZERO'
       OR p.approved_el_decline_convention <> 'ZERO' THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: decline conventions must be ZERO.';
    END IF;

    IF p.allow_approved_amount_above_requested_flag IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: allow_approved_amount_above_requested_flag must be FALSE.';
    END IF;

    IF p.failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW','DECLINE') THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: failed_counteroffer_resolution must be MANUAL_REVIEW or DECLINE.';
    END IF;


    /* Strategy ↔ product-policy compatibility. */
    SELECT COUNT(*)
    INTO v_profile_mismatch_count
    FROM tmp_module2_strategy_params sp
    LEFT JOIN tmp_m2_strategy_product_policy_compatibility c
        ON c.strategy_profile_code = sp.strategy_profile_code
       AND c.strategy_name = sp.strategy_name
       AND c.required_product_policy_profile_code = sp.product_policy_profile_code
    WHERE sp.active_strategy_flag IS TRUE
      AND c.strategy_profile_code IS NULL;

    IF v_profile_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active strategy profile and product-policy profile are incompatible.';
    END IF;


    /* Product-policy completeness. */
    SELECT COUNT(*)
    INTO v_product_policy_count
    FROM tmp_module2_product_policy_params;

    IF v_product_policy_count <> 5 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected 5 product policy rows, found %.',
            v_product_policy_count;
    END IF;

    SELECT COUNT(DISTINCT product_type)
    INTO v_supported_product_count
    FROM tmp_module2_product_policy_params
    WHERE product_type IN (
        'MORTGAGE',
        'HELOC',
        'AUTO_LOAN',
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    );

    IF v_supported_product_count <> 5 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: product policy table does not contain the full supported product set.';
    END IF;

    SELECT COUNT(*)
    INTO v_duplicate_product_count
    FROM (
        SELECT product_type
        FROM tmp_module2_product_policy_params
        GROUP BY product_type
        HAVING COUNT(*) > 1
    ) d;

    IF v_duplicate_product_count > 0 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: duplicate product policy rows exist.';
    END IF;

    SELECT COUNT(*)
    INTO v_unsupported_product_count
    FROM tmp_module2_product_policy_params
    WHERE product_type NOT IN (
        'MORTGAGE',
        'HELOC',
        'AUTO_LOAN',
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    );

    IF v_unsupported_product_count > 0 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: unsupported product_type found in product policy table.';
    END IF;

    SELECT COUNT(*)
    INTO v_missing_supported_product_count
    FROM (
        SELECT product_type
        FROM (
            VALUES
                ('MORTGAGE'),
                ('HELOC'),
                ('AUTO_LOAN'),
                ('UNSECURED_PERSONAL_LOAN'),
                ('REVOLVING_LINE')
        ) supported(product_type)
        WHERE NOT EXISTS (
            SELECT 1
            FROM tmp_module2_product_policy_params pp
            WHERE pp.product_type = supported.product_type
        )
    ) missing_products;

    IF v_missing_supported_product_count > 0 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: one or more supported products are missing product policy rows.';
    END IF;

    SELECT COUNT(*)
    INTO v_bad_product_policy_count
    FROM tmp_module2_product_policy_params
    WHERE product_approve_max_pti IS NULL
       OR product_review_max_pti IS NULL
       OR product_decline_min_pti IS NULL
       OR counteroffer_target_pti IS NULL
       OR NOT (
            product_approve_max_pti < product_review_max_pti
            AND product_review_max_pti <= product_decline_min_pti
            AND counteroffer_target_pti <= product_approve_max_pti
       )
       OR product_approve_max_requested_el IS NULL
       OR product_review_max_requested_el IS NULL
       OR product_decline_min_requested_el IS NULL
       OR NOT (
            product_approve_max_requested_el < product_review_max_requested_el
            AND product_review_max_requested_el <= product_decline_min_requested_el
       )
       OR product_approved_el_cap IS NULL
       OR product_approved_el_cap < 0
       OR product_min_approved_amount IS NULL
       OR product_max_approved_amount IS NULL
       OR product_min_approved_amount <= 0
       OR product_max_approved_amount < product_min_approved_amount
       OR counteroffer_allowed_flag IS NULL
       OR manual_review_allowed_flag IS NULL
       OR product_min_counteroffer_pct IS NULL
       OR product_max_exposure_reduction_pct IS NULL
       OR product_min_counteroffer_pct < 0
       OR product_min_counteroffer_pct > 1
       OR product_max_exposure_reduction_pct < 0
       OR product_max_exposure_reduction_pct > 1
       OR exposure_assignment_method <> 'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'
       OR approved_amount_rounding_increment IS NULL
       OR approved_amount_rounding_increment <= 0;

    IF v_bad_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: % product policy row(s) failed threshold, amount, counteroffer, or method validation.',
            v_bad_product_policy_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.2 — MODULE 1 SOURCE SELECTION AND SOURCE-SCOPE GATEKEEPER
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_source_selection_scope;

DO $$
DECLARE
    p RECORD;

    v_source_table_schema TEXT;
    v_source_table_name TEXT;
    v_source_regclass REGCLASS;

    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;

    v_effective_module1_scenario_set_name TEXT;
    v_effective_module1_scenario_name TEXT;
    v_effective_population_id TEXT;

    v_required_missing_columns TEXT;
    v_selected_row_count BIGINT;
    v_selected_distinct_application_count BIGINT;
    v_duplicate_application_group_count BIGINT;
    v_scenario_population_count BIGINT;
    v_null_required_field_count BIGINT;

    v_required_column_list TEXT[] := ARRAY[
        'application_id',
        'applicant_id',
        'product_type',
        'score_band',
        'credit_score',
        'requested_amount',
        'annual_income',
        'monthly_payment_proxy',
        'payment_to_income_ratio',
        'amount_to_income_ratio',
        'debt_to_income_ratio',
        'utilization_rate',
        'tradeline_count',
        'months_since_oldest_trade',
        'recent_inquiry_count',
        'delinquency_count_12m',
        'major_derogatory_flag',
        'bankruptcy_flag',
        'estimated_pd',
        'estimated_lgd',
        'expected_loss_amount',
        'population_id',
        'base_apr_for_payment_calc',
        'loan_term_months'
    ];

    v_null_check_expression TEXT;
BEGIN
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;


    IF p.module1_input_source = 'LATEST' THEN
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications';
    ELSE
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications_scenario_archive';
    END IF;

    v_source_regclass := TO_REGCLASS(v_source_table_schema || '.' || v_source_table_name);

    IF v_source_regclass IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: Module 1 source table %.% does not exist.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /* Detect lineage column naming convention. */
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'module1_scenario_set_name'
        )
            THEN 'module1_scenario_set_name'
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'scenario_set_name'
        )
            THEN 'scenario_set_name'
        ELSE NULL
    END
    INTO v_scenario_set_col;

    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'module1_scenario_name'
        )
            THEN 'module1_scenario_name'
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'scenario_name'
        )
            THEN 'scenario_name'
        ELSE NULL
    END
    INTO v_scenario_name_col;

    IF v_scenario_set_col IS NULL OR v_scenario_name_col IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: source table %.% lacks scenario lineage columns.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /* Required source columns. */
    SELECT STRING_AGG(required_column, ', ' ORDER BY required_column)
    INTO v_required_missing_columns
    FROM UNNEST(v_required_column_list) AS required_column
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = v_source_table_schema
          AND c.table_name = v_source_table_name
          AND c.column_name = required_column
    );

    IF v_required_missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: source table %.% is missing required column(s): %.',
            v_source_table_schema,
            v_source_table_name,
            v_required_missing_columns;
    END IF;


    v_null_check_expression :=
        'application_id IS NULL'
        || ' OR applicant_id IS NULL'
        || ' OR product_type IS NULL'
        || ' OR score_band IS NULL'
        || ' OR credit_score IS NULL'
        || ' OR requested_amount IS NULL'
        || ' OR annual_income IS NULL'
        || ' OR monthly_payment_proxy IS NULL'
        || ' OR payment_to_income_ratio IS NULL'
        || ' OR amount_to_income_ratio IS NULL'
        || ' OR debt_to_income_ratio IS NULL'
        || ' OR utilization_rate IS NULL'
        || ' OR tradeline_count IS NULL'
        || ' OR months_since_oldest_trade IS NULL'
        || ' OR recent_inquiry_count IS NULL'
        || ' OR delinquency_count_12m IS NULL'
        || ' OR major_derogatory_flag IS NULL'
        || ' OR bankruptcy_flag IS NULL'
        || ' OR estimated_pd IS NULL'
        || ' OR estimated_lgd IS NULL'
        || ' OR expected_loss_amount IS NULL'
        || ' OR population_id IS NULL'
        || ' OR base_apr_for_payment_calc IS NULL'
        || ' OR ' || FORMAT('%I IS NULL', v_scenario_set_col)
        || ' OR ' || FORMAT('%I IS NULL', v_scenario_name_col);


    IF p.module1_input_source = 'LATEST' THEN
        EXECUTE FORMAT(
            'SELECT COUNT(*), COUNT(DISTINCT application_id), COUNT(DISTINCT (%I, %I, population_id))
             FROM %I.%I',
            v_scenario_set_col,
            v_scenario_name_col,
            v_source_table_schema,
            v_source_table_name
        )
        INTO
            v_selected_row_count,
            v_selected_distinct_application_count,
            v_scenario_population_count;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM (
                 SELECT application_id
                 FROM %I.%I
                 GROUP BY application_id
                 HAVING COUNT(*) > 1
             ) d',
            v_source_table_schema,
            v_source_table_name
        )
        INTO v_duplicate_application_group_count;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM %I.%I
             WHERE %s',
            v_source_table_schema,
            v_source_table_name,
            v_null_check_expression
        )
        INTO v_null_required_field_count;

        EXECUTE FORMAT(
            'SELECT MIN(%I)::TEXT, MIN(%I)::TEXT, MIN(population_id)::TEXT
             FROM %I.%I',
            v_scenario_set_col,
            v_scenario_name_col,
            v_source_table_schema,
            v_source_table_name
        )
        INTO
            v_effective_module1_scenario_set_name,
            v_effective_module1_scenario_name,
            v_effective_population_id;

        IF v_scenario_population_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: LATEST source contains % scenario / population combinations. Expected exactly one.',
                v_scenario_population_count;
        END IF;

    ELSE
        EXECUTE FORMAT(
            'SELECT COUNT(*), COUNT(DISTINCT application_id), COUNT(DISTINCT (%I, %I, population_id))
             FROM %I.%I
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3',
            v_scenario_set_col,
            v_scenario_name_col,
            v_source_table_schema,
            v_source_table_name,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO
            v_selected_row_count,
            v_selected_distinct_application_count,
            v_scenario_population_count
        USING
            p.source_module1_scenario_set_name,
            p.source_module1_scenario_name,
            p.source_population_id;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM (
                 SELECT application_id
                 FROM %I.%I
                 WHERE %I = $1
                   AND %I = $2
                   AND population_id = $3
                 GROUP BY application_id
                 HAVING COUNT(*) > 1
             ) d',
            v_source_table_schema,
            v_source_table_name,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_duplicate_application_group_count
        USING
            p.source_module1_scenario_set_name,
            p.source_module1_scenario_name,
            p.source_population_id;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM %I.%I
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3
               AND (%s)',
            v_source_table_schema,
            v_source_table_name,
            v_scenario_set_col,
            v_scenario_name_col,
            v_null_check_expression
        )
        INTO v_null_required_field_count
        USING
            p.source_module1_scenario_set_name,
            p.source_module1_scenario_name,
            p.source_population_id;

        v_effective_module1_scenario_set_name := p.source_module1_scenario_set_name;
        v_effective_module1_scenario_name := p.source_module1_scenario_name;
        v_effective_population_id := p.source_population_id;
    END IF;


    IF v_selected_row_count = 0 THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: selected Module 1 source slice contains zero rows.';
    END IF;

    IF v_selected_distinct_application_count <> v_selected_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: selected source application_id is not unique. Rows=%, distinct application_id=%, duplicate groups=%.',
            v_selected_row_count,
            v_selected_distinct_application_count,
            v_duplicate_application_group_count;
    END IF;

    IF v_null_required_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: selected source contains % row(s) with null required fields.',
            v_null_required_field_count;
    END IF;


    CREATE TEMP TABLE tmp_m2_source_selection_scope (
        module1_input_source                         TEXT,
        source_table_schema                          TEXT,
        source_table_name                            TEXT,
        source_scenario_set_column_name              TEXT,
        source_scenario_name_column_name             TEXT,

        effective_module1_scenario_set_name          TEXT,
        effective_module1_scenario_name              TEXT,
        effective_population_id                      TEXT,

        selected_row_count                           BIGINT,
        selected_distinct_application_id_count       BIGINT,
        duplicate_application_group_count            BIGINT,
        null_required_field_row_count                BIGINT
    ) ON COMMIT PRESERVE ROWS;

    INSERT INTO tmp_m2_source_selection_scope (
        module1_input_source,
        source_table_schema,
        source_table_name,
        source_scenario_set_column_name,
        source_scenario_name_column_name,
        effective_module1_scenario_set_name,
        effective_module1_scenario_name,
        effective_population_id,
        selected_row_count,
        selected_distinct_application_id_count,
        duplicate_application_group_count,
        null_required_field_row_count
    )
    VALUES (
        p.module1_input_source,
        v_source_table_schema,
        v_source_table_name,
        v_scenario_set_col,
        v_scenario_name_col,
        v_effective_module1_scenario_set_name,
        v_effective_module1_scenario_name,
        v_effective_population_id,
        v_selected_row_count,
        v_selected_distinct_application_count,
        v_duplicate_application_group_count,
        v_null_required_field_count
    );
END $$;



/***************************************************************************************************
SECTION 3.3 — CAMPAIGN REGISTRY MATCH GATEKEEPER
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;

CREATE TEMP TABLE tmp_m2_campaign_registry_current_run_match
ON COMMIT PRESERVE ROWS
AS
WITH active_run AS (
    SELECT
        p.campaign_registry_required_flag,

        p.source_module1_scenario_set_name AS module1_scenario_set_name,
        p.source_module1_scenario_name AS module1_scenario_name,
        p.source_population_id AS population_id,

        p.strategy_set_name,
        p.strategy_name,
        p.strategy_version,

        p.strategy_profile_code,
        p.product_policy_profile_code
    FROM tmp_module2_strategy_params p
    WHERE p.active_strategy_flag IS TRUE
),

registry_matches AS (
    SELECT
        r.*
    FROM credit_decisioning_sim.strategy_run_campaign_registry r
    JOIN active_run a
        ON r.module1_scenario_set_name = a.module1_scenario_set_name
       AND r.module1_scenario_name = a.module1_scenario_name
       AND r.population_id = a.population_id
       AND r.strategy_set_name = a.strategy_set_name
       AND r.strategy_name = a.strategy_name
       AND r.strategy_version = a.strategy_version
    WHERE r.registry_active_flag IS TRUE
),

registry_count AS (
    SELECT COUNT(*) AS registry_match_count
    FROM registry_matches
),

registry_single AS (
    SELECT *
    FROM registry_matches
    ORDER BY run_sequence_number NULLS LAST, module2_run_id
    LIMIT 1
)

SELECT
    a.campaign_registry_required_flag,

    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,

    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,

    a.strategy_profile_code,
    a.product_policy_profile_code,

    rc.registry_match_count,

    CASE
        WHEN rc.registry_match_count = 1
            THEN 'RUN_REGISTRY_MATCHED'
        WHEN rc.registry_match_count = 0 AND a.campaign_registry_required_flag IS TRUE
            THEN 'RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW'
        WHEN rc.registry_match_count = 0
            THEN 'RUN_REGISTRY_NOT_FOUND_FALLBACK_ALLOWED'
        WHEN rc.registry_match_count > 1
            THEN 'RUN_REGISTRY_DUPLICATE_MATCH_REVIEW_REQUIRED'
        ELSE 'RUN_REGISTRY_MATCH_STATUS_REVIEW'
    END AS run_registry_match_status,

    rs.module1_run_id,
    rs.module2_run_id,
    rs.run_sequence_number,

    rs.showcase_id,
    rs.showcase_name,
    rs.comparison_group_id,
    rs.validation_evidence_group_id,

    rs.module1_parameter_family_changed,
    rs.module1_parameter_change_summary,

    rs.module2_strategy_family_changed,
    rs.module2_parameter_change_summary,

    rs.expected_storyline,
    rs.validation_summary_section_hint,
    rs.readme_storyline_label,
    rs.linkedin_post_sequence

FROM active_run a
CROSS JOIN registry_count rc
LEFT JOIN registry_single rs
    ON TRUE;



DO $$
DECLARE
    m RECORD;
    v_registry_exists BOOLEAN;
    v_required_registry_id_gap_count BIGINT;
BEGIN
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_run_campaign_registry') IS NOT NULL
    INTO v_registry_exists;

    SELECT *
    INTO m
    FROM tmp_m2_campaign_registry_current_run_match
    LIMIT 1;

    IF v_registry_exists IS DISTINCT FROM TRUE
       AND m.campaign_registry_required_flag IS TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: campaign_registry_required_flag = TRUE but strategy_run_campaign_registry does not exist.';
    END IF;

    IF m.campaign_registry_required_flag IS TRUE
       AND m.run_registry_match_status <> 'RUN_REGISTRY_MATCHED' THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: campaign_registry_required_flag = TRUE but current run key did not match exactly one active campaign registry row. Match status: %.',
            m.run_registry_match_status;
    END IF;

    IF m.registry_match_count > 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: current run key matched more than one active campaign registry row.';
    END IF;

    SELECT COUNT(*)
    INTO v_required_registry_id_gap_count
    FROM tmp_m2_campaign_registry_current_run_match
    WHERE run_registry_match_status = 'RUN_REGISTRY_MATCHED'
      AND (
            module1_run_id IS NULL
         OR module2_run_id IS NULL
         OR run_sequence_number IS NULL
         OR validation_evidence_group_id IS NULL
      );

    IF v_required_registry_id_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: matched campaign registry row is missing required run IDs or validation evidence IDs.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.4 — ACTIVE COMPARISON REGISTRY HELPER
****************************************************************************************************

PURPOSE:
    Materialize the currently active comparison registry row for Section 13 review.

NOTE:
    This is not required for single-run execution.
    It supports governed comparison review after the relevant baseline and challenger slices exist.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;

CREATE TEMP TABLE tmp_m2_comparison_campaign_registry_active_match
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE active_comparison_flag IS TRUE
  AND registry_active_flag IS TRUE;



/***************************************************************************************************
SECTION 3.5 — SETUP DIAGNOSTICS
****************************************************************************************************/

SELECT
    'SECTION_3_ACTIVE_STRATEGY_GATEKEEPER_RESULT' AS diagnostic_name,
    module2_run_id,
    run_mode,
    strategy_profile_code,
    product_policy_profile_code,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
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


SELECT
    'SECTION_3_SOURCE_SELECTION_SCOPE' AS diagnostic_name,
    *
FROM tmp_m2_source_selection_scope;


SELECT
    'SECTION_3_CAMPAIGN_REGISTRY_MATCH' AS diagnostic_name,
    *
FROM tmp_m2_campaign_registry_current_run_match;


SELECT
    'SECTION_3_PRODUCT_POLICY_PROFILE_SUMMARY' AS diagnostic_name,
    product_policy_profile_code,
    COUNT(*) AS product_policy_rows,
    COUNT(DISTINCT product_type) AS distinct_product_count,
    MIN(product_type) AS first_product_type,
    MAX(product_type) AS last_product_type
FROM tmp_module2_product_policy_params
GROUP BY product_policy_profile_code
ORDER BY product_policy_profile_code;


SELECT
    'SECTION_3_ACTIVE_COMPARISON_REGISTRY_ROW' AS diagnostic_name,
    *
FROM tmp_m2_comparison_campaign_registry_active_match;
```
<!-- END_MESSAGE C038-M01409 -->


---

<a id="c038-m01410"></a>

### C038-M01410

**Andrew** · 2026-05-12T01:51:47.016000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01410 -->
I think you bit off more than you could chew in one response.  Let's break it up.  Proceed with the first full copy-paste patch: updated section 0, updated section 1.  SAVE the redesign of section 2 and the updated section 3 for subsequent responses.  I repeat - DO NOT give me the redesign of section 2 or the updated section 3 in the next response.  Only deliver the full copy paste patch's for the updated section 0 and 1.
<!-- END_MESSAGE C038-M01410 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_69.md) · [Next](Part_71.md)
