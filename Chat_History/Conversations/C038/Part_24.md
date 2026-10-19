# Module 2 Decision Simulator Build

## Part 24

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_23.md) · [Next](Part_25.md)

<a id="c038-m00584"></a>

### C038-M00584

**ChatGPT** · 2026-05-08T23:13:19.275063-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00584 -->
```sql
/***************************************************************************************************
SECTION 16 — STRATEGY RUN EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER
****************************************************************************************************

BUSINESS PURPOSE:
    Persist a compact, executive-ready evidence record for each completed Module 2 strategy run.

    The Module 2 archive stores row-level simulated strategy outcomes. Section 13, Section 14,
    and Section 15 produce comparison and validation outputs. Section 16 distills those outputs into
    persistent evidence tables so the project can support:

        1. repeatable run tracking,
        2. executive storytelling,
        3. validation-summary drafting,
        4. README / portfolio evidence,
        5. future Module 3 growth and economics design.

WHY THIS SECTION EXISTS:
    During a large scenario / strategy run campaign, the user should not have to collect key results
    from dozens of QA outputs after every run.

    Section 16 captures the key story:
        What scenario was used?
        What strategy was applied?
        What changed?
        What were the final outcomes?
        What was the simulated offer exposure?
        What was the approved exposure?
        What was the approved Expected Loss?
        Which products and score bands drove the result?
        Which simulated reason codes explain the outcome?
        Which validation checks passed, required review, or were not applicable?
        What evidence is available for later Module 3 growth / earnings logic?

READ-ONLY / PERSISTENCE BOUNDARY:
    Section 16 does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive

    Section 16 does create and maintain separate evidence tables:
        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

    Section 16 deletes and replaces evidence rows only for the current run key in these evidence
    tables. It does not delete or change strategy archive rows.

MODELING BOUNDARY:
    Section 16 does not recalculate decision_outcome.
    Section 16 does not recalculate approved_amount.
    Section 16 does not recalculate approved_expected_loss_amount.
    Section 16 does not reassign simulated reason codes.
    Section 16 does not implement earnings, pricing, revenue, funding-cost, or profitability logic.

MODULE 3 READINESS BOUNDARY:
    Section 16 captures growth / exposure / APR-proxy / term / product-mix fields that will be useful
    for a future Module 3 economics layer.

    It does not calculate revenue, yield, funding cost, risk-adjusted margin, profitability, capital,
    or pricing optimization. Those remain future Module 3 scope.

INTERPRETATION BOUNDARIES:
    estimated_pd remains the SQL field name from Module 1 and is interpreted as the synthetic
    estimated-PD proxy.

    requested_expected_loss_amount means requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount means simulated approved-exposure Expected Loss after Module 2
    exposure treatment.

    simulated_offer_exposure_flag means the simulated strategy produced positive offer exposure
    through APPROVE or COUNTEROFFER.

    simulated_offer_exposure_flag does not imply operational account creation, funding, production
    approval, or real applicant treatment.

    Reason codes remain simulated strategy explanation codes. They are not customer communications,
    regulatory reason codes, or real-world treatment explanations.

***************************************************************************************************/



/***************************************************************************************************
SECTION 16.0 — CURRENT RUN KEY AND EVIDENCE CAPTURE GATEKEEPER
****************************************************************************************************

PURPOSE:
    Identify the current latest-run Module 2 strategy slice and confirm that the supporting
    temporary outputs needed for evidence capture are available.

WHY THIS MATTERS:
    The evidence tables are persisted at the same practical grain as the archived strategy slice:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

    Section 16 should capture exactly one current latest-run strategy / Module 1 scenario / population
    slice per execution.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_current_run_key;

CREATE TEMP TABLE tmp_m2_current_run_key
ON COMMIT PRESERVE ROWS
AS
SELECT DISTINCT
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution,

    module1_input_source,
    module1_source_table_name,

    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,

    latest_output_created_ts
FROM credit_decisioning_sim.strategy_decisions;


/*
Optional run-story helper table.

Users may edit this section before a run campaign to attach run-roadmap labels, showcase names,
expected storyline, observed storyline, and review notes.

If the user does not edit these fields, Section 16 still captures the technical evidence and
derives basic scenario / strategy family labels from scenario and strategy names.
*/
DROP TABLE IF EXISTS tmp_m2_current_run_story_params;

CREATE TEMP TABLE tmp_m2_current_run_story_params
ON COMMIT PRESERVE ROWS
AS
SELECT
    TRUE AS active_story_flag,

    module1_scenario_name AS module1_run_id,
    module1_scenario_name || '__' || strategy_name AS module2_run_id,

    CASE
        WHEN module1_scenario_name IN ('BASELINE_V2', 'CREDIT_BOX_BASELINE_REFERENCE',
                                       'PRODUCT_MIX_BASELINE_REFERENCE',
                                       'EXPOSURE_BASELINE_REFERENCE',
                                       'LGD_BASELINE_REFERENCE')
            THEN 'BASELINE_REFERENCE'
        WHEN module1_scenario_name ILIKE '%RATE%'
            THEN 'RATE_SENSITIVITY_SHOWCASE'
        WHEN module1_scenario_name ILIKE '%SCORE%'
          OR module1_scenario_name ILIKE '%PRIME%'
          OR module1_scenario_name ILIKE '%CREDIT_STRESS%'
            THEN 'CREDIT_BOX_SHOWCASE'
        WHEN module1_scenario_name ILIKE '%MIX%'
            THEN 'PORTFOLIO_MIX_SHOWCASE'
        WHEN module1_scenario_name ILIKE '%BALANCE%'
          OR module1_scenario_name ILIKE '%EXPOSURE%'
            THEN 'EXPOSURE_INTENSITY_SHOWCASE'
        WHEN module1_scenario_name ILIKE '%LGD%'
          OR module1_scenario_name ILIKE '%SEVERITY%'
            THEN 'SEVERITY_SENSITIVITY_SHOWCASE'
        ELSE 'UNCLASSIFIED_SHOWCASE'
    END AS showcase_name,

    CASE
        WHEN module1_scenario_name ILIKE '%RATE_UP%'
          OR module1_scenario_name ILIKE '%RATE_DOWN%'
            THEN 'RATE_ENVIRONMENT'
        WHEN module1_scenario_name ILIKE '%SCORE%'
          OR module1_scenario_name ILIKE '%PRIME%'
          OR module1_scenario_name ILIKE '%CREDIT_STRESS%'
            THEN 'SCORE_MIX'
        WHEN module1_scenario_name ILIKE '%PRODUCT%'
          OR module1_scenario_name ILIKE '%UNSECURED%'
          OR module1_scenario_name ILIKE '%REVOLVING%'
          OR module1_scenario_name ILIKE '%SECURED%'
            THEN 'PRODUCT_MIX'
        WHEN module1_scenario_name ILIKE '%BALANCE%'
          OR module1_scenario_name ILIKE '%EXPOSURE%'
            THEN 'EXPOSURE_INTENSITY'
        WHEN module1_scenario_name ILIKE '%LGD%'
          OR module1_scenario_name ILIKE '%SEVERITY%'
            THEN 'LGD_SEVERITY'
        ELSE 'BASELINE_OR_UNCLASSIFIED'
    END AS module1_parameter_family_changed,

    CASE
        WHEN module1_scenario_name = 'BASELINE_V2'
            THEN 'Module 1 baseline scenario using accepted V2.0 defaults.'
        WHEN module1_scenario_name ILIKE '%RATE_UP%'
            THEN 'Module 1 rate-up sensitivity scenario.'
        WHEN module1_scenario_name ILIKE '%RATE_DOWN%'
            THEN 'Module 1 rate-down sensitivity scenario.'
        WHEN module1_scenario_name ILIKE '%PRIME%'
            THEN 'Module 1 score-mix scenario emphasizing prime or near-prime composition.'
        WHEN module1_scenario_name ILIKE '%UNSECURED%'
            THEN 'Module 1 product-mix or severity scenario emphasizing unsecured exposure.'
        WHEN module1_scenario_name ILIKE '%REVOLVING%'
            THEN 'Module 1 product-mix scenario emphasizing revolving exposure.'
        WHEN module1_scenario_name ILIKE '%SEVERITY%'
          OR module1_scenario_name ILIKE '%LGD%'
            THEN 'Module 1 LGD / severity sensitivity scenario.'
        ELSE 'Module 1 scenario parameter change summary not manually specified.'
    END AS module1_parameter_change_summary,

    CASE
        WHEN strategy_name = 'BASELINE_STRATEGY'
            THEN 'BASELINE'
        WHEN strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY'
            THEN 'RISK_TIGHTENING'
        WHEN strategy_name = 'GROWTH_ORIENTED_STRATEGY'
            THEN 'GROWTH'
        WHEN strategy_name = 'TIGHTER_AFFORDABILITY_STRATEGY'
            THEN 'AFFORDABILITY_TIGHTENING'
        WHEN strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
            THEN 'COUNTEROFFER_MANAGEMENT'
        WHEN strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
            THEN 'PRODUCT_GUARDRAILS'
        WHEN strategy_name = 'MANUAL_REVIEW_REDUCTION_STRATEGY'
            THEN 'OPERATIONS_REVIEW_REDUCTION'
        ELSE 'UNCLASSIFIED_STRATEGY'
    END AS module2_strategy_family_changed,

    CASE
        WHEN strategy_name = 'BASELINE_STRATEGY'
            THEN 'Module 2 baseline strategy using accepted V1.0 defaults.'
        WHEN strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY'
            THEN 'Module 2 strategy tightens synthetic estimated-PD proxy tolerance thresholds.'
        WHEN strategy_name = 'GROWTH_ORIENTED_STRATEGY'
            THEN 'Module 2 strategy loosens selected synthetic-risk, PTI, and DTI tolerances for growth-oriented comparison.'
        WHEN strategy_name = 'TIGHTER_AFFORDABILITY_STRATEGY'
            THEN 'Module 2 strategy tightens PTI thresholds and counteroffer target PTI.'
        WHEN strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
            THEN 'Module 2 strategy emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.'
        WHEN strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
            THEN 'Module 2 strategy applies tighter guardrails to selected unsecured / revolving products.'
        WHEN strategy_name = 'MANUAL_REVIEW_REDUCTION_STRATEGY'
            THEN 'Module 2 strategy resolves failed counteroffers to final no-offer outcomes to reduce unresolved manual review.'
        ELSE 'Module 2 strategy parameter change summary not manually specified.'
    END AS module2_parameter_change_summary,

    CASE
        WHEN strategy_name = 'BASELINE_STRATEGY'
            THEN 'Establish reference strategy behavior for this Module 1 scenario.'
        WHEN strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY'
            THEN 'Demonstrate risk-discipline tradeoff: lower simulated offer exposure and approved Expected Loss, with higher decline rate.'
        WHEN strategy_name = 'GROWTH_ORIENTED_STRATEGY'
            THEN 'Demonstrate growth tradeoff: higher simulated offer exposure and approved amount, with measurable risk impact.'
        WHEN strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
            THEN 'Demonstrate exposure-management tradeoff through reduced approved amount, improved PTI, and lower approved Expected Loss.'
        ELSE 'Expected storyline not manually specified.'
    END AS expected_storyline,

    NULL::TEXT AS observed_storyline,
    NULL::TEXT AS validation_notes

FROM tmp_m2_current_run_key
LIMIT 1;



DO $$
DECLARE
    v_latest_table_exists BOOLEAN;
    v_latest_row_count BIGINT;
    v_current_key_count BIGINT;
    v_validation_summary_exists BOOLEAN;
    v_frontier_summary_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;
    v_product_policy_params_exists BOOLEAN;
    v_story_param_count BIGINT;
BEGIN
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO v_latest_table_exists;

    IF v_latest_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: credit_decisioning_sim.strategy_decisions does not exist.';
    END IF;

    SELECT COUNT(*)
    INTO v_latest_row_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: latest-run strategy_decisions table contains zero rows.';
    END IF;

    SELECT COUNT(*)
    INTO v_current_key_count
    FROM tmp_m2_current_run_key;

    IF v_current_key_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: expected exactly one current latest-run strategy / Module 1 scenario / population key, found %.',
            v_current_key_count;
    END IF;

    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary'),
        TO_REGCLASS('tmp_m2_validation_status_summary')
    ) IS NOT NULL
    INTO v_validation_summary_exists;

    IF v_validation_summary_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_m2_validation_status_summary is required before evidence capture.';
    END IF;

    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary'),
        TO_REGCLASS('tmp_m2_strategy_frontier_executive_summary')
    ) IS NOT NULL
    INTO v_frontier_summary_exists;

    IF v_frontier_summary_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_m2_strategy_frontier_executive_summary is required before evidence capture.';
    END IF;

    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_strategy_params'),
        TO_REGCLASS('tmp_module2_strategy_params')
    ) IS NOT NULL
    INTO v_strategy_params_exists;

    IF v_strategy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_module2_strategy_params is required for parameter snapshot capture.';
    END IF;

    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_product_policy_params'),
        TO_REGCLASS('tmp_module2_product_policy_params')
    ) IS NOT NULL
    INTO v_product_policy_params_exists;

    IF v_product_policy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_module2_product_policy_params is required for product-policy parameter snapshot capture.';
    END IF;

    SELECT COUNT(*)
    INTO v_story_param_count
    FROM tmp_m2_current_run_story_params
    WHERE active_story_flag IS TRUE;

    IF v_story_param_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: expected exactly one active story-parameter row, found %.',
            v_story_param_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 16.1 — CREATE PERSISTENT EVIDENCE TABLES
****************************************************************************************************

PURPOSE:
    Create persistent evidence tables used to preserve executive story, validation evidence,
    parameter snapshots, and product × score segment evidence.

GRAIN:
    Main executive evidence:
        one row per Module 1 scenario × Module 2 strategy version

    Validation evidence:
        one row per run × validation test

    Parameter snapshot:
        one row per run

    Segment evidence:
        one row per run × product_type_policy_key × score_band_policy_key

***************************************************************************************************/


CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_evidence_summary (
    evidence_snapshot_ts TIMESTAMP,
    evidence_snapshot_id TEXT,

    module1_run_id TEXT,
    module2_run_id TEXT,
    showcase_name TEXT,

    module1_parameter_family_changed TEXT,
    module1_parameter_change_summary TEXT,
    module2_strategy_family_changed TEXT,
    module2_parameter_change_summary TEXT,
    expected_storyline TEXT,
    observed_storyline TEXT,
    validation_notes TEXT,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    latest_output_created_ts TIMESTAMP,
    archive_inserted_ts TIMESTAMP,

    archive_run_flag BOOLEAN,
    strategy_archive_reset_mode TEXT,
    failed_counteroffer_resolution TEXT,

    module1_input_source TEXT,
    module1_source_table_name TEXT,

    module1_model_version TEXT,
    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,
    anchor_date DATE,

    applications BIGINT,
    distinct_application_id_count BIGINT,
    duplicate_application_count BIGINT,

    approval_count BIGINT,
    counteroffer_count BIGINT,
    manual_review_count BIGINT,
    decline_count BIGINT,
    offer_count BIGINT,

    approval_rate NUMERIC,
    counteroffer_rate NUMERIC,
    manual_review_rate NUMERIC,
    decline_rate NUMERIC,
    simulated_offer_exposure_rate NUMERIC,
    approval_share_of_offers NUMERIC,
    counteroffer_share_of_offers NUMERIC,

    total_requested_amount NUMERIC,
    total_approved_amount NUMERIC,
    approved_amount_capture_rate NUMERIC,

    avg_requested_amount NUMERIC,
    avg_approved_amount_all_apps NUMERIC,
    avg_approved_amount_offer_rows NUMERIC,

    total_exposure_reduction_amount NUMERIC,

    counteroffer_requested_amount NUMERIC,
    counteroffer_approved_amount NUMERIC,
    counteroffer_exposure_reduction_amount NUMERIC,
    counteroffer_exposure_reduction_pct_avg NUMERIC,

    manual_review_requested_amount NUMERIC,
    manual_review_requested_expected_loss_amount NUMERIC,
    decline_requested_amount NUMERIC,
    decline_requested_expected_loss_amount NUMERIC,

    avg_requested_payment_to_income_ratio NUMERIC,
    avg_approved_payment_to_income_ratio_offer_rows NUMERIC,

    avg_apr_proxy_all_apps NUMERIC,
    avg_apr_proxy_offer_rows NUMERIC,
    requested_amount_weighted_apr_proxy NUMERIC,
    approved_amount_weighted_apr_proxy NUMERIC,
    requested_amount_x_apr_proxy_sum NUMERIC,
    approved_amount_x_apr_proxy_sum NUMERIC,

    avg_loan_term_months_offer_rows NUMERIC,
    approved_amount_weighted_term_months NUMERIC,
    term_missing_or_revolving_count BIGINT,

    secured_approved_amount_share NUMERIC,
    unsecured_approved_amount_share NUMERIC,
    revolving_approved_amount_share NUMERIC,
    installment_approved_amount_share NUMERIC,
    mortgage_approved_amount_share NUMERIC,

    product_approved_amount_mix_jsonb JSONB,
    product_approved_expected_loss_mix_jsonb JSONB,
    product_offer_rate_jsonb JSONB,

    avg_synthetic_estimated_pd_proxy_all_apps NUMERIC,
    avg_synthetic_estimated_pd_proxy_offer_rows NUMERIC,
    avg_synthetic_estimated_pd_proxy_declined_rows NUMERIC,

    avg_estimated_lgd_all_apps NUMERIC,
    avg_estimated_lgd_offer_rows NUMERIC,

    total_requested_expected_loss_amount NUMERIC,
    total_approved_expected_loss_amount NUMERIC,
    avg_requested_expected_loss_amount NUMERIC,
    avg_approved_expected_loss_all_apps NUMERIC,
    avg_approved_expected_loss_offer_rows NUMERIC,

    requested_expected_loss_rate NUMERIC,
    approved_expected_loss_rate NUMERIC,
    approved_amount_per_approved_expected_loss_dollar NUMERIC,

    top_primary_reason_family TEXT,
    top_primary_reason_code TEXT,
    top_primary_reason_population_share NUMERIC,

    top_non_approval_primary_reason_family TEXT,
    top_non_approval_primary_reason_code TEXT,
    top_non_approval_reason_population_share NUMERIC,

    top_policy_stop_primary_reason_family TEXT,
    top_policy_stop_primary_reason_code TEXT,
    top_policy_stop_reason_population_share NUMERIC,

    top_reason_code_delta_driver_family TEXT,
    top_reason_code_delta_driver_code TEXT,
    top_reason_code_delta_driver_baseline_share NUMERIC,
    top_reason_code_delta_driver_strategy_share NUMERIC,
    top_reason_code_delta_population_share NUMERIC,

    top_counteroffer_reason_code TEXT,
    top_manual_review_reason_code TEXT,
    top_decline_reason_code TEXT,

    frontier_position_type TEXT,
    executive_frontier_quadrant TEXT,
    frontier_interpretation_note TEXT,

    validation_pass_count BIGINT,
    validation_review_count BIGINT,
    validation_not_applicable_count BIGINT,
    validation_review_items TEXT,
    validation_status_summary_jsonb JSONB,

    top_approved_amount_product TEXT,
    top_approved_amount_product_share NUMERIC,
    top_approved_expected_loss_product TEXT,
    top_approved_expected_loss_product_share NUMERIC,
    top_counteroffer_product TEXT,
    top_decline_product TEXT,
    highest_offer_rate_product TEXT,
    lowest_offer_rate_product TEXT,

    top_approved_amount_score_band TEXT,
    top_approved_expected_loss_score_band TEXT,
    top_counteroffer_score_band TEXT,
    top_decline_score_band TEXT,
    highest_offer_rate_score_band TEXT,
    lowest_offer_rate_score_band TEXT,
    highest_approved_el_rate_score_band TEXT,

    top_approved_amount_product_score_segment TEXT,
    top_approved_el_product_score_segment TEXT,
    top_counteroffer_product_score_segment TEXT,
    top_decline_product_score_segment TEXT,
    highest_approved_el_rate_product_score_segment TEXT,

    largest_delta_approved_amount_product TEXT,
    largest_delta_approved_el_product TEXT,
    largest_delta_offer_rate_score_band TEXT,
    largest_delta_decline_rate_score_band TEXT,
    largest_delta_approved_el_product_score_segment TEXT,

    module3_growth_inputs_available_flag BOOLEAN,
    module3_growth_input_gap_note TEXT,
    module3_revenue_model_required_flag BOOLEAN,
    module3_boundary_note TEXT
);


CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_validation_evidence (
    evidence_snapshot_ts TIMESTAMP,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,

    validation_area TEXT,
    validation_test_name TEXT,
    validation_category TEXT,
    validation_status TEXT,
    observed_value TEXT,
    expected_behavior TEXT,
    interpretation TEXT
);


CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_parameter_snapshot (
    evidence_snapshot_ts TIMESTAMP,
    evidence_snapshot_id TEXT,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,

    strategy_params_jsonb JSONB,
    product_policy_params_jsonb JSONB,
    run_story_params_jsonb JSONB,
    parameter_snapshot_hash TEXT
);


CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_segment_evidence_summary (
    evidence_snapshot_ts TIMESTAMP,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,

    product_type_policy_key TEXT,
    score_band_policy_key TEXT,
    product_score_policy_segment TEXT,

    applications BIGINT,

    approval_count BIGINT,
    counteroffer_count BIGINT,
    manual_review_count BIGINT,
    decline_count BIGINT,
    offer_count BIGINT,

    approval_rate NUMERIC,
    counteroffer_rate NUMERIC,
    manual_review_rate NUMERIC,
    decline_rate NUMERIC,
    simulated_offer_exposure_rate NUMERIC,

    total_requested_amount NUMERIC,
    total_approved_amount NUMERIC,
    approved_amount_capture_rate NUMERIC,

    avg_requested_amount NUMERIC,
    avg_approved_amount_all_apps NUMERIC,
    avg_approved_amount_offer_rows NUMERIC,

    avg_apr_proxy_all_apps NUMERIC,
    avg_apr_proxy_offer_rows NUMERIC,
    requested_amount_weighted_apr_proxy NUMERIC,
    approved_amount_weighted_apr_proxy NUMERIC,

    avg_loan_term_months_offer_rows NUMERIC,
    approved_amount_weighted_term_months NUMERIC,

    avg_synthetic_estimated_pd_proxy_all_apps NUMERIC,
    avg_synthetic_estimated_pd_proxy_offer_rows NUMERIC,
    avg_estimated_lgd_offer_rows NUMERIC,

    total_requested_expected_loss_amount NUMERIC,
    total_approved_expected_loss_amount NUMERIC,
    approved_expected_loss_rate NUMERIC,

    avg_requested_payment_to_income_ratio NUMERIC,
    avg_approved_payment_to_income_ratio_offer_rows NUMERIC,

    top_primary_reason_family TEXT,
    top_primary_reason_code TEXT,
    top_primary_reason_population_share NUMERIC,

    top_non_approval_primary_reason_family TEXT,
    top_non_approval_primary_reason_code TEXT,
    top_non_approval_reason_population_share NUMERIC
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_evidence_summary_key
ON credit_decisioning_sim.strategy_run_evidence_summary (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);


CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_validation_evidence_key
ON credit_decisioning_sim.strategy_run_validation_evidence (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_parameter_snapshot_key
ON credit_decisioning_sim.strategy_run_parameter_snapshot (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_segment_evidence_key
ON credit_decisioning_sim.strategy_run_segment_evidence_summary (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    product_type_policy_key,
    score_band_policy_key
);



/***************************************************************************************************
SECTION 16.2 — REPLACE CURRENT RUN EVIDENCE ROWS
****************************************************************************************************

PURPOSE:
    Maintain one current evidence record per archived strategy / Module 1 scenario / population key.

WHY DELETE / INSERT IS USED:
    Strategy slices may be rerun under STRATEGY_SCENARIO_ONLY archive reset behavior. Evidence rows
    should reflect the current archived version of that strategy slice, not accumulate duplicates for
    the same practical evidence grain.

***************************************************************************************************/

DELETE FROM credit_decisioning_sim.strategy_run_evidence_summary e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;


DELETE FROM credit_decisioning_sim.strategy_run_validation_evidence e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;


DELETE FROM credit_decisioning_sim.strategy_run_parameter_snapshot e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;


DELETE FROM credit_decisioning_sim.strategy_run_segment_evidence_summary e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;



/***************************************************************************************************
SECTION 16.3 — CAPTURE CURRENT RUN VALIDATION EVIDENCE DETAIL
****************************************************************************************************

PURPOSE:
    Persist the Section 14 validation status summary for the current run.

INTERPRETATION:
    These rows support the future Module 2 Validation Summary.

    PASS means the diagnostic expectation was satisfied.
    REVIEW means the pattern should be interpreted but is not a fail-fast defect.
    NOT_APPLICABLE means the test depends on comparison conditions that are not available for the
    current run context.

***************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_run_validation_evidence (
    evidence_snapshot_ts,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation
)
SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    k.module2_model_version,
    k.strategy_set_name,
    k.strategy_name,
    k.strategy_version,
    k.strategy_run_id,
    k.strategy_run_ts,

    k.module1_scenario_set_name,
    k.module1_scenario_name,
    k.population_id,

    v.validation_area,
    v.validation_test_name,
    v.validation_category,
    v.validation_status,
    v.observed_value::TEXT,
    v.expected_behavior::TEXT,
    v.interpretation::TEXT
FROM tmp_m2_current_run_key k
CROSS JOIN tmp_m2_validation_status_summary v;



/***************************************************************************************************
SECTION 16.4 — CAPTURE CURRENT RUN PARAMETER SNAPSHOT
****************************************************************************************************

PURPOSE:
    Persist the exact active Module 2 strategy parameter card, product policy parameter card, and
    run-story metadata for the current evidence row.

WHY THIS MATTERS:
    The active parameter tables are temporary. Without a parameter snapshot, later documentation may
    know what happened but not exactly which parameter values were active.

MODULE 3 READINESS:
    This snapshot also preserves product policy values that may later support growth, economics,
    pricing proxy, exposure, or profitability design in a future Module 3.

***************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_run_parameter_snapshot (
    evidence_snapshot_ts,
    evidence_snapshot_id,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_params_jsonb,
    product_policy_params_jsonb,
    run_story_params_jsonb,
    parameter_snapshot_hash
)
WITH snapshot_payload AS (
    SELECT
        k.*,

        (
            SELECT to_jsonb(sp)
            FROM tmp_module2_strategy_params sp
            WHERE sp.active_strategy_flag IS TRUE
            LIMIT 1
        ) AS strategy_params_jsonb,

        (
            SELECT jsonb_agg(to_jsonb(pp) ORDER BY pp.product_type)
            FROM tmp_module2_product_policy_params pp
        ) AS product_policy_params_jsonb,

        (
            SELECT to_jsonb(rsp)
            FROM tmp_m2_current_run_story_params rsp
            WHERE rsp.active_story_flag IS TRUE
            LIMIT 1
        ) AS run_story_params_jsonb
    FROM tmp_m2_current_run_key k
)

SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    MD5(
        strategy_set_name || '|'
        || strategy_name || '|'
        || strategy_version || '|'
        || module1_scenario_set_name || '|'
        || module1_scenario_name || '|'
        || population_id || '|'
        || CURRENT_TIMESTAMP::TEXT
    ) AS evidence_snapshot_id,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_params_jsonb,
    product_policy_params_jsonb,
    run_story_params_jsonb,

    MD5(
        COALESCE(strategy_params_jsonb::TEXT, '')
        || '|'
        || COALESCE(product_policy_params_jsonb::TEXT, '')
        || '|'
        || COALESCE(run_story_params_jsonb::TEXT, '')
    ) AS parameter_snapshot_hash
FROM snapshot_payload;



/***************************************************************************************************
SECTION 16.5 — CAPTURE CURRENT RUN SEGMENT EVIDENCE SUMMARY
****************************************************************************************************

PURPOSE:
    Persist product × score-band evidence for the current run.

WHY THIS MATTERS:
    Executive summaries need a concise one-row narrative, but senior credit strategy review also
    requires product and score segmentation.

    This companion table preserves the detailed product × score evidence that supports the executive
    driver fields.

MODULE 3 READINESS:
    Product × score segment metrics will be useful for future growth / earnings logic because revenue,
    funding cost, utilization, and margin assumptions are likely to be product-sensitive and may also
    be score-sensitive.

***************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_run_segment_evidence_summary (
    evidence_snapshot_ts,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,

    applications,

    approval_count,
    counteroffer_count,
    manual_review_count,
    decline_count,
    offer_count,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,

    total_requested_amount,
    total_approved_amount,
    approved_amount_capture_rate,

    avg_requested_amount,
    avg_approved_amount_all_apps,
    avg_approved_amount_offer_rows,

    avg_apr_proxy_all_apps,
    avg_apr_proxy_offer_rows,
    requested_amount_weighted_apr_proxy,
    approved_amount_weighted_apr_proxy,

    avg_loan_term_months_offer_rows,
    approved_amount_weighted_term_months,

    avg_synthetic_estimated_pd_proxy_all_apps,
    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_estimated_lgd_offer_rows,

    total_requested_expected_loss_amount,
    total_approved_expected_loss_amount,
    approved_expected_loss_rate,

    avg_requested_payment_to_income_ratio,
    avg_approved_payment_to_income_ratio_offer_rows,

    top_primary_reason_family,
    top_primary_reason_code,
    top_primary_reason_population_share,

    top_non_approval_primary_reason_family,
    top_non_approval_primary_reason_code,
    top_non_approval_reason_population_share
)
WITH segment_summary AS (
    SELECT
        module2_model_version,
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        strategy_run_ts,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        AVG(base_apr_for_payment_calc) AS avg_apr_proxy_all_apps,
        AVG(base_apr_for_payment_calc) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_apr_proxy_offer_rows,

        SUM(requested_amount * base_apr_for_payment_calc)
            / NULLIF(SUM(requested_amount), 0) AS requested_amount_weighted_apr_proxy,

        SUM(COALESCE(approved_amount, 0) * base_apr_for_payment_calc)
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0) AS approved_amount_weighted_apr_proxy,

        AVG(loan_term_months) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_loan_term_months_offer_rows,

        SUM(COALESCE(approved_amount, 0) * loan_term_months)
            / NULLIF(SUM(COALESCE(approved_amount, 0)) FILTER (WHERE loan_term_months IS NOT NULL), 0)
            AS approved_amount_weighted_term_months,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,
        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_estimated_lgd_offer_rows,

        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows

    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        module2_model_version,
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        strategy_run_ts,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment
),

reason_counts AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,

        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS reason_row_count
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,
        primary_reason_family,
        primary_reason_code
),

top_reason AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,
        primary_reason_family,
        primary_reason_code,
        reason_row_count,
        ROW_NUMBER() OVER (
            PARTITION BY product_type_policy_key, score_band_policy_key, product_score_policy_segment
            ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
        ) AS reason_rank
    FROM reason_counts
),

top_non_approval_reason AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,
        primary_reason_family,
        primary_reason_code,
        reason_row_count,
        ROW_NUMBER() OVER (
            PARTITION BY product_type_policy_key, score_band_policy_key, product_score_policy_segment
            ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
        ) AS reason_rank
    FROM reason_counts
    WHERE primary_reason_family <> 'APPROVAL'
)

SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    s.module2_model_version,
    s.strategy_set_name,
    s.strategy_name,
    s.strategy_version,
    s.strategy_run_id,
    s.strategy_run_ts,

    s.module1_scenario_set_name,
    s.module1_scenario_name,
    s.population_id,

    s.product_type_policy_key,
    s.score_band_policy_key,
    s.product_score_policy_segment,

    s.applications,

    s.approval_count,
    s.counteroffer_count,
    s.manual_review_count,
    s.decline_count,
    s.offer_count,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate,

    s.total_requested_amount,
    s.total_approved_amount,
    s.approved_amount_capture_rate,

    s.avg_requested_amount,
    s.avg_approved_amount_all_apps,
    s.avg_approved_amount_offer_rows,

    s.avg_apr_proxy_all_apps,
    s.avg_apr_proxy_offer_rows,
    s.requested_amount_weighted_apr_proxy,
    s.approved_amount_weighted_apr_proxy,

    s.avg_loan_term_months_offer_rows,
    s.approved_amount_weighted_term_months,

    s.avg_synthetic_estimated_pd_proxy_all_apps,
    s.avg_synthetic_estimated_pd_proxy_offer_rows,
    s.avg_estimated_lgd_offer_rows,

    s.total_requested_expected_loss_amount,
    s.total_approved_expected_loss_amount,
    s.approved_expected_loss_rate,

    s.avg_requested_payment_to_income_ratio,
    s.avg_approved_payment_to_income_ratio_offer_rows,

    tr.primary_reason_family AS top_primary_reason_family,
    tr.primary_reason_code AS top_primary_reason_code,
    tr.reason_row_count::NUMERIC / NULLIF(s.applications, 0) AS top_primary_reason_population_share,

    nr.primary_reason_family AS top_non_approval_primary_reason_family,
    nr.primary_reason_code AS top_non_approval_primary_reason_code,
    nr.reason_row_count::NUMERIC / NULLIF(s.applications, 0) AS top_non_approval_reason_population_share

FROM segment_summary s
LEFT JOIN top_reason tr
    ON tr.product_type_policy_key = s.product_type_policy_key
   AND tr.score_band_policy_key = s.score_band_policy_key
   AND tr.product_score_policy_segment = s.product_score_policy_segment
   AND tr.reason_rank = 1
LEFT JOIN top_non_approval_reason nr
    ON nr.product_type_policy_key = s.product_type_policy_key
   AND nr.score_band_policy_key = s.score_band_policy_key
   AND nr.product_score_policy_segment = s.product_score_policy_segment
   AND nr.reason_rank = 1;



/***************************************************************************************************
SECTION 16.6 — CAPTURE CURRENT RUN EXECUTIVE EVIDENCE SUMMARY
****************************************************************************************************

PURPOSE:
    Insert the one-row executive evidence summary for the current run.

DESIGN:
    Most portfolio-level metrics are calculated directly from credit_decisioning_sim.strategy_decisions.

    Frontier posture and baseline-relative fields are carried from Section 15 temporary output.

    Validation status counts are carried from tmp_m2_validation_status_summary.

    Segment driver fields are calculated from current latest-run product, score, and product × score
    summaries.

***************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_run_evidence_summary (
    evidence_snapshot_ts,
    evidence_snapshot_id,

    module1_run_id,
    module2_run_id,
    showcase_name,

    module1_parameter_family_changed,
    module1_parameter_change_summary,
    module2_strategy_family_changed,
    module2_parameter_change_summary,
    expected_storyline,
    observed_storyline,
    validation_notes,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    latest_output_created_ts,
    archive_inserted_ts,

    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution,

    module1_input_source,
    module1_source_table_name,

    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,

    applications,
    distinct_application_id_count,
    duplicate_application_count,

    approval_count,
    counteroffer_count,
    manual_review_count,
    decline_count,
    offer_count,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,
    approval_share_of_offers,
    counteroffer_share_of_offers,

    total_requested_amount,
    total_approved_amount,
    approved_amount_capture_rate,

    avg_requested_amount,
    avg_approved_amount_all_apps,
    avg_approved_amount_offer_rows,

    total_exposure_reduction_amount,

    counteroffer_requested_amount,
    counteroffer_approved_amount,
    counteroffer_exposure_reduction_amount,
    counteroffer_exposure_reduction_pct_avg,

    manual_review_requested_amount,
    manual_review_requested_expected_loss_amount,
    decline_requested_amount,
    decline_requested_expected_loss_amount,

    avg_requested_payment_to_income_ratio,
    avg_approved_payment_to_income_ratio_offer_rows,

    avg_apr_proxy_all_apps,
    avg_apr_proxy_offer_rows,
    requested_amount_weighted_apr_proxy,
    approved_amount_weighted_apr_proxy,
    requested_amount_x_apr_proxy_sum,
    approved_amount_x_apr_proxy_sum,

    avg_loan_term_months_offer_rows,
    approved_amount_weighted_term_months,
    term_missing_or_revolving_count,

    secured_approved_amount_share,
    unsecured_approved_amount_share,
    revolving_approved_amount_share,
    installment_approved_amount_share,
    mortgage_approved_amount_share,

    product_approved_amount_mix_jsonb,
    product_approved_expected_loss_mix_jsonb,
    product_offer_rate_jsonb,

    avg_synthetic_estimated_pd_proxy_all_apps,
    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_synthetic_estimated_pd_proxy_declined_rows,

    avg_estimated_lgd_all_apps,
    avg_estimated_lgd_offer_rows,

    total_requested_expected_loss_amount,
    total_approved_expected_loss_amount,
    avg_requested_expected_loss_amount,
    avg_approved_expected_loss_all_apps,
    avg_approved_expected_loss_offer_rows,

    requested_expected_loss_rate,
    approved_expected_loss_rate,
    approved_amount_per_approved_expected_loss_dollar,

    top_primary_reason_family,
    top_primary_reason_code,
    top_primary_reason_population_share,

    top_non_approval_primary_reason_family,
    top_non_approval_primary_reason_code,
    top_non_approval_reason_population_share,

    top_policy_stop_primary_reason_family,
    top_policy_stop_primary_reason_code,
    top_policy_stop_reason_population_share,

    top_reason_code_delta_driver_family,
    top_reason_code_delta_driver_code,
    top_reason_code_delta_driver_baseline_share,
    top_reason_code_delta_driver_strategy_share,
    top_reason_code_delta_population_share,

    top_counteroffer_reason_code,
    top_manual_review_reason_code,
    top_decline_reason_code,

    frontier_position_type,
    executive_frontier_quadrant,
    frontier_interpretation_note,

    validation_pass_count,
    validation_review_count,
    validation_not_applicable_count,
    validation_review_items,
    validation_status_summary_jsonb,

    top_approved_amount_product,
    top_approved_amount_product_share,
    top_approved_expected_loss_product,
    top_approved_expected_loss_product_share,
    top_counteroffer_product,
    top_decline_product,
    highest_offer_rate_product,
    lowest_offer_rate_product,

    top_approved_amount_score_band,
    top_approved_expected_loss_score_band,
    top_counteroffer_score_band,
    top_decline_score_band,
    highest_offer_rate_score_band,
    lowest_offer_rate_score_band,
    highest_approved_el_rate_score_band,

    top_approved_amount_product_score_segment,
    top_approved_el_product_score_segment,
    top_counteroffer_product_score_segment,
    top_decline_product_score_segment,
    highest_approved_el_rate_product_score_segment,

    largest_delta_approved_amount_product,
    largest_delta_approved_el_product,
    largest_delta_offer_rate_score_band,
    largest_delta_decline_rate_score_band,
    largest_delta_approved_el_product_score_segment,

    module3_growth_inputs_available_flag,
    module3_growth_input_gap_note,
    module3_revenue_model_required_flag,
    module3_boundary_note
)
WITH current_key AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
),

story AS (
    SELECT *
    FROM tmp_m2_current_run_story_params
    WHERE active_story_flag IS TRUE
    LIMIT 1
),

archive_ts AS (
    SELECT
        MAX(ar.archive_inserted_ts) AS archive_inserted_ts
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = k.strategy_name
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id
),

portfolio AS (
    SELECT
        COUNT(*) AS applications,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_count,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS approval_share_of_offers,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS counteroffer_share_of_offers,

        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        SUM(COALESCE(exposure_reduction_amount, 0)) AS total_exposure_reduction_amount,

        SUM(requested_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_requested_amount,

        SUM(approved_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_approved_amount,

        SUM(exposure_reduction_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_exposure_reduction_amount,

        AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_exposure_reduction_pct_avg,

        SUM(requested_amount) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_requested_amount,

        SUM(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_requested_expected_loss_amount,

        SUM(requested_amount) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_requested_amount,

        SUM(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_requested_expected_loss_amount,

        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows,

        AVG(base_apr_for_payment_calc) AS avg_apr_proxy_all_apps,
        AVG(base_apr_for_payment_calc) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_apr_proxy_offer_rows,

        SUM(requested_amount * base_apr_for_payment_calc)
            / NULLIF(SUM(requested_amount), 0)
            AS requested_amount_weighted_apr_proxy,

        SUM(COALESCE(approved_amount, 0) * base_apr_for_payment_calc)
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_amount_weighted_apr_proxy,

        SUM(requested_amount * base_apr_for_payment_calc)
            AS requested_amount_x_apr_proxy_sum,

        SUM(COALESCE(approved_amount, 0) * base_apr_for_payment_calc)
            AS approved_amount_x_apr_proxy_sum,

        AVG(loan_term_months) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_loan_term_months_offer_rows,

        SUM(COALESCE(approved_amount, 0) * loan_term_months)
            / NULLIF(SUM(COALESCE(approved_amount, 0)) FILTER (WHERE loan_term_months IS NOT NULL), 0)
            AS approved_amount_weighted_term_months,

        COUNT(*) FILTER (
            WHERE loan_term_months IS NULL
               OR product_type_policy_key IN ('REVOLVING_LINE')
        ) AS term_missing_or_revolving_count,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,
        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,
        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_declined_rows,

        AVG(estimated_lgd) AS avg_estimated_lgd_all_apps,
        AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_estimated_lgd_offer_rows,

        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,
        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        SUM(requested_expected_loss_amount)
            / NULLIF(SUM(requested_amount), 0)
            AS requested_expected_loss_rate,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(COALESCE(approved_expected_loss_amount, 0)), 0)
            AS approved_amount_per_approved_expected_loss_dollar,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('MORTGAGE', 'HELOC', 'AUTO_LOAN')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS secured_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('REVOLVING_LINE', 'UNSECURED_PERSONAL_LOAN')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS unsecured_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('REVOLVING_LINE', 'HELOC')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS revolving_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('MORTGAGE', 'AUTO_LOAN', 'UNSECURED_PERSONAL_LOAN')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS installment_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key = 'MORTGAGE'
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS mortgage_approved_amount_share
    FROM credit_decisioning_sim.strategy_decisions
),

product_summary AS (
    SELECT
        product_type_policy_key,

        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS offer_rate,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY product_type_policy_key
),

product_totals AS (
    SELECT
        SUM(total_approved_amount) AS total_approved_amount,
        SUM(total_approved_expected_loss_amount) AS total_approved_expected_loss_amount
    FROM product_summary
),

product_json AS (
    SELECT
        jsonb_object_agg(
            ps.product_type_policy_key,
            jsonb_build_object(
                'applications', ps.applications,
                'offer_count', ps.offer_count,
                'offer_rate', ps.offer_rate,
                'total_approved_amount', ps.total_approved_amount,
                'approved_amount_share', ps.total_approved_amount / NULLIF(pt.total_approved_amount, 0)
            )
        ) AS product_approved_amount_mix_jsonb,

        jsonb_object_agg(
            ps.product_type_policy_key,
            jsonb_build_object(
                'total_approved_expected_loss_amount', ps.total_approved_expected_loss_amount,
                'approved_expected_loss_share', ps.total_approved_expected_loss_amount / NULLIF(pt.total_approved_expected_loss_amount, 0),
                'approved_expected_loss_rate', ps.approved_expected_loss_rate
            )
        ) AS product_approved_expected_loss_mix_jsonb,

        jsonb_object_agg(
            ps.product_type_policy_key,
            jsonb_build_object(
                'applications', ps.applications,
                'offer_count', ps.offer_count,
                'offer_rate', ps.offer_rate
            )
        ) AS product_offer_rate_jsonb
    FROM product_summary ps
    CROSS JOIN product_totals pt
),

product_drivers AS (
    SELECT
        (SELECT product_type_policy_key FROM product_summary ORDER BY total_approved_amount DESC NULLS LAST, product_type_policy_key LIMIT 1)
            AS top_approved_amount_product,

        (SELECT total_approved_amount / NULLIF((SELECT total_approved_amount FROM product_totals), 0)
         FROM product_summary
         ORDER BY total_approved_amount DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS top_approved_amount_product_share,

        (SELECT product_type_policy_key FROM product_summary ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, product_type_policy_key LIMIT 1)
            AS top_approved_expected_loss_product,

        (SELECT total_approved_expected_loss_amount / NULLIF((SELECT total_approved_expected_loss_amount FROM product_totals), 0)
         FROM product_summary
         ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS top_approved_expected_loss_product_share,

        (SELECT product_type_policy_key FROM product_summary ORDER BY counteroffer_count DESC, product_type_policy_key LIMIT 1)
            AS top_counteroffer_product,

        (SELECT product_type_policy_key FROM product_summary ORDER BY decline_count DESC, product_type_policy_key LIMIT 1)
            AS top_decline_product,

        (SELECT product_type_policy_key FROM product_summary ORDER BY offer_rate DESC NULLS LAST, product_type_policy_key LIMIT 1)
            AS highest_offer_rate_product,

        (SELECT product_type_policy_key FROM product_summary ORDER BY offer_rate ASC NULLS LAST, product_type_policy_key LIMIT 1)
            AS lowest_offer_rate_product
),

score_summary AS (
    SELECT
        score_band_policy_key,

        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS offer_rate,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY score_band_policy_key
),

score_drivers AS (
    SELECT
        (SELECT score_band_policy_key FROM score_summary ORDER BY total_approved_amount DESC NULLS LAST, score_band_policy_key LIMIT 1)
            AS top_approved_amount_score_band,

        (SELECT score_band_policy_key FROM score_summary ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, score_band_policy_key LIMIT 1)
            AS top_approved_expected_loss_score_band,

        (SELECT score_band_policy_key FROM score_summary ORDER BY counteroffer_count DESC, score_band_policy_key LIMIT 1)
            AS top_counteroffer_score_band,

        (SELECT score_band_policy_key FROM score_summary ORDER BY decline_count DESC, score_band_policy_key LIMIT 1)
            AS top_decline_score_band,

        (SELECT score_band_policy_key FROM score_summary ORDER BY offer_rate DESC NULLS LAST, score_band_policy_key LIMIT 1)
            AS highest_offer_rate_score_band,

        (SELECT score_band_policy_key FROM score_summary ORDER BY offer_rate ASC NULLS LAST, score_band_policy_key LIMIT 1)
            AS lowest_offer_rate_score_band,

        (SELECT score_band_policy_key FROM score_summary ORDER BY approved_expected_loss_rate DESC NULLS LAST, score_band_policy_key LIMIT 1)
            AS highest_approved_el_rate_score_band
),

product_score_summary AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_type_policy_key || ' / ' || score_band_policy_key
            AS product_score_policy_segment,

        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        product_type_policy_key,
        score_band_policy_key
),

product_score_drivers AS (
    SELECT
        (SELECT product_score_policy_segment FROM product_score_summary ORDER BY total_approved_amount DESC NULLS LAST, product_score_policy_segment LIMIT 1)
            AS top_approved_amount_product_score_segment,

        (SELECT product_score_policy_segment FROM product_score_summary ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, product_score_policy_segment LIMIT 1)
            AS top_approved_el_product_score_segment,

        (SELECT product_score_policy_segment FROM product_score_summary ORDER BY counteroffer_count DESC, product_score_policy_segment LIMIT 1)
            AS top_counteroffer_product_score_segment,

        (SELECT product_score_policy_segment FROM product_score_summary ORDER BY decline_count DESC, product_score_policy_segment LIMIT 1)
            AS top_decline_product_score_segment,

        (SELECT product_score_policy_segment FROM product_score_summary ORDER BY approved_expected_loss_rate DESC NULLS LAST, product_score_policy_segment LIMIT 1)
            AS highest_approved_el_rate_product_score_segment
),

reason_counts AS (
    SELECT
        decision_outcome,
        primary_reason_family,
        primary_reason_code,
        COUNT(*) AS reason_row_count,
        COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0) AS reason_population_share
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        decision_outcome,
        primary_reason_family,
        primary_reason_code
),

reason_drivers AS (
    SELECT
        (SELECT primary_reason_family FROM reason_counts ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_primary_reason_family,

        (SELECT primary_reason_code FROM reason_counts ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_primary_reason_code,

        (SELECT reason_population_share FROM reason_counts ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_primary_reason_population_share,

        (SELECT primary_reason_family FROM reason_counts WHERE decision_outcome <> 'APPROVE' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_non_approval_primary_reason_family,

        (SELECT primary_reason_code FROM reason_counts WHERE decision_outcome <> 'APPROVE' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_non_approval_primary_reason_code,

        (SELECT reason_population_share FROM reason_counts WHERE decision_outcome <> 'APPROVE' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_non_approval_reason_population_share,

        (SELECT primary_reason_family FROM reason_counts WHERE primary_reason_family = 'POLICY_STOP' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_policy_stop_primary_reason_family,

        (SELECT primary_reason_code FROM reason_counts WHERE primary_reason_family = 'POLICY_STOP' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_policy_stop_primary_reason_code,

        (SELECT reason_population_share FROM reason_counts WHERE primary_reason_family = 'POLICY_STOP' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_policy_stop_reason_population_share,

        (SELECT primary_reason_code FROM reason_counts WHERE decision_outcome = 'COUNTEROFFER' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_counteroffer_reason_code,

        (SELECT primary_reason_code FROM reason_counts WHERE decision_outcome = 'MANUAL_REVIEW' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_manual_review_reason_code,

        (SELECT primary_reason_code FROM reason_counts WHERE decision_outcome = 'DECLINE' ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code LIMIT 1)
            AS top_decline_reason_code
),

validation_summary AS (
    SELECT
        COUNT(*) FILTER (WHERE validation_status = 'PASS') AS validation_pass_count,
        COUNT(*) FILTER (WHERE validation_status = 'REVIEW') AS validation_review_count,
        COUNT(*) FILTER (WHERE validation_status = 'NOT_APPLICABLE') AS validation_not_applicable_count,

        STRING_AGG(
            validation_area || ': ' || validation_test_name || ' [' || validation_status || ']',
            ' | '
            ORDER BY validation_area, validation_test_name
        ) FILTER (WHERE validation_status IN ('REVIEW', 'NOT_APPLICABLE'))
            AS validation_review_items,

        jsonb_agg(
            jsonb_build_object(
                'validation_area', validation_area,
                'validation_test_name', validation_test_name,
                'validation_category', validation_category,
                'validation_status', validation_status,
                'observed_value', observed_value,
                'expected_behavior', expected_behavior,
                'interpretation', interpretation
            )
            ORDER BY validation_area, validation_test_name
        ) AS validation_status_summary_jsonb
    FROM tmp_m2_validation_status_summary
),

frontier AS (
    SELECT
        f.*
    FROM tmp_m2_strategy_frontier_executive_summary f
    JOIN current_key k
        ON f.strategy_set_name = k.strategy_set_name
       AND f.strategy_name = k.strategy_name
       AND f.strategy_version = k.strategy_version
       AND f.module1_scenario_set_name = k.module1_scenario_set_name
       AND f.module1_scenario_name = k.module1_scenario_name
       AND f.population_id = k.population_id
    LIMIT 1
),

baseline_product AS (
    SELECT
        ar.product_type_policy_key,
        SUM(COALESCE(ar.approved_amount, 0)) AS baseline_total_approved_amount,
        SUM(COALESCE(ar.approved_expected_loss_amount, 0)) AS baseline_total_approved_el
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = 'BASELINE_STRATEGY'
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id
    GROUP BY ar.product_type_policy_key
),

current_product AS (
    SELECT
        product_type_policy_key,
        SUM(COALESCE(approved_amount, 0)) AS current_total_approved_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS current_total_approved_el
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY product_type_policy_key
),

product_delta AS (
    SELECT
        cp.product_type_policy_key,
        cp.current_total_approved_amount - bp.baseline_total_approved_amount
            AS delta_total_approved_amount,
        cp.current_total_approved_el - bp.baseline_total_approved_el
            AS delta_total_approved_el
    FROM current_product cp
    JOIN baseline_product bp
        ON bp.product_type_policy_key = cp.product_type_policy_key
),

baseline_score AS (
    SELECT
        ar.score_band_policy_key,
        COUNT(*) FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)::NUMERIC / NULLIF(COUNT(*), 0)
            AS baseline_offer_rate,
        COUNT(*) FILTER (WHERE ar.decision_outcome = 'DECLINE')::NUMERIC / NULLIF(COUNT(*), 0)
            AS baseline_decline_rate
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = 'BASELINE_STRATEGY'
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id
    GROUP BY ar.score_band_policy_key
),

current_score AS (
    SELECT
        score_band_policy_key,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC / NULLIF(COUNT(*), 0)
            AS current_offer_rate,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC / NULLIF(COUNT(*), 0)
            AS current_decline_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY score_band_policy_key
),

score_delta AS (
    SELECT
        cs.score_band_policy_key,
        cs.current_offer_rate - bs.baseline_offer_rate AS delta_offer_rate,
        cs.current_decline_rate - bs.baseline_decline_rate AS delta_decline_rate
    FROM current_score cs
    JOIN baseline_score bs
        ON bs.score_band_policy_key = cs.score_band_policy_key
),

baseline_product_score AS (
    SELECT
        ar.product_type_policy_key,
        ar.score_band_policy_key,
        ar.product_type_policy_key || ' / ' || ar.score_band_policy_key AS product_score_policy_segment,
        SUM(COALESCE(ar.approved_expected_loss_amount, 0)) AS baseline_total_approved_el
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = 'BASELINE_STRATEGY'
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id
    GROUP BY
        ar.product_type_policy_key,
        ar.score_band_policy_key
),

current_product_score AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_type_policy_key || ' / ' || score_band_policy_key AS product_score_policy_segment,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS current_total_approved_el
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        product_type_policy_key,
        score_band_policy_key
),

product_score_delta AS (
    SELECT
        cps.product_score_policy_segment,
        cps.current_total_approved_el - bps.baseline_total_approved_el
            AS delta_total_approved_el
    FROM current_product_score cps
    JOIN baseline_product_score bps
        ON bps.product_type_policy_key = cps.product_type_policy_key
       AND bps.score_band_policy_key = cps.score_band_policy_key
),

delta_drivers AS (
    SELECT
        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT product_type_policy_key
                FROM product_delta
                ORDER BY ABS(delta_total_approved_amount) DESC NULLS LAST, product_type_policy_key
                LIMIT 1
            )
        END AS largest_delta_approved_amount_product,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT product_type_policy_key
                FROM product_delta
                ORDER BY ABS(delta_total_approved_el) DESC NULLS LAST, product_type_policy_key
                LIMIT 1
            )
        END AS largest_delta_approved_el_product,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT score_band_policy_key
                FROM score_delta
                ORDER BY ABS(delta_offer_rate) DESC NULLS LAST, score_band_policy_key
                LIMIT 1
            )
        END AS largest_delta_offer_rate_score_band,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT score_band_policy_key
                FROM score_delta
                ORDER BY ABS(delta_decline_rate) DESC NULLS LAST, score_band_policy_key
                LIMIT 1
            )
        END AS largest_delta_decline_rate_score_band,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT product_score_policy_segment
                FROM product_score_delta
                ORDER BY ABS(delta_total_approved_el) DESC NULLS LAST, product_score_policy_segment
                LIMIT 1
            )
        END AS largest_delta_approved_el_product_score_segment
),

module3_readiness AS (
    SELECT
        CASE
            WHEN SUM(COALESCE(approved_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) > 0
             AND COUNT(*) FILTER (
                    WHERE simulated_offer_exposure_flag IS TRUE
                      AND base_apr_for_payment_calc IS NOT NULL
                      AND approved_amount IS NOT NULL
                      AND estimated_pd IS NOT NULL
                      AND estimated_lgd IS NOT NULL
                      AND approved_expected_loss_amount IS NOT NULL
                 ) > 0
                THEN TRUE
            ELSE FALSE
        END AS module3_growth_inputs_available_flag,

        CASE
            WHEN COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) = 0
                THEN 'No simulated offer-exposure rows are available for future Module 3 economics.'
            WHEN COUNT(*) FILTER (
                    WHERE simulated_offer_exposure_flag IS TRUE
                      AND base_apr_for_payment_calc IS NULL
                 ) > 0
                THEN 'One or more offer rows are missing APR proxy values.'
            WHEN COUNT(*) FILTER (
                    WHERE simulated_offer_exposure_flag IS TRUE
                      AND approved_amount IS NULL
                 ) > 0
                THEN 'One or more offer rows are missing approved_amount values.'
            ELSE 'Core Module 3 readiness inputs are available: approved amount, APR proxy, product, synthetic estimated-PD proxy, LGD, and approved Expected Loss. Utilization, funding cost, fee income, and revenue assumptions remain future Module 3 design inputs.'
        END AS module3_growth_input_gap_note,

        TRUE AS module3_revenue_model_required_flag,

        'Earnings, revenue, funding cost, profitability, and risk-adjusted margin logic are intentionally deferred to Module 3. Section 16 captures readiness inputs only.'::TEXT
            AS module3_boundary_note
    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    MD5(
        k.strategy_set_name || '|'
        || k.strategy_name || '|'
        || k.strategy_version || '|'
        || k.module1_scenario_set_name || '|'
        || k.module1_scenario_name || '|'
        || k.population_id || '|'
        || CURRENT_TIMESTAMP::TEXT
    ) AS evidence_snapshot_id,

    story.module1_run_id,
    story.module2_run_id,
    story.showcase_name,

    story.module1_parameter_family_changed,
    story.module1_parameter_change_summary,
    story.module2_strategy_family_changed,
    story.module2_parameter_change_summary,
    story.expected_storyline,
    COALESCE(story.observed_storyline, f.frontier_interpretation_note) AS observed_storyline,
    story.validation_notes,

    k.module2_model_version,
    k.strategy_set_name,
    k.strategy_name,
    k.strategy_version,
    k.strategy_run_id,
    k.strategy_run_ts,

    k.latest_output_created_ts,
    ats.archive_inserted_ts,

    k.archive_run_flag,
    k.strategy_archive_reset_mode,
    k.failed_counteroffer_resolution,

    k.module1_input_source,
    k.module1_source_table_name,

    k.module1_model_version,
    k.module1_scenario_set_name,
    k.module1_scenario_name,
    k.population_id,
    k.anchor_date,

    p.applications,
    p.distinct_application_id_count,
    p.duplicate_application_count,

    p.approval_count,
    p.counteroffer_count,
    p.manual_review_count,
    p.decline_count,
    p.offer_count,

    p.approval_rate,
    p.counteroffer_rate,
    p.manual_review_rate,
    p.decline_rate,
    p.simulated_offer_exposure_rate,
    p.approval_share_of_offers,
    p.counteroffer_share_of_offers,

    p.total_requested_amount,
    p.total_approved_amount,
    p.approved_amount_capture_rate,

    p.avg_requested_amount,
    p.avg_approved_amount_all_apps,
    p.avg_approved_amount_offer_rows,

    p.total_exposure_reduction_amount,

    p.counteroffer_requested_amount,
    p.counteroffer_approved_amount,
    p.counteroffer_exposure_reduction_amount,
    p.counteroffer_exposure_reduction_pct_avg,

    p.manual_review_requested_amount,
    p.manual_review_requested_expected_loss_amount,
    p.decline_requested_amount,
    p.decline_requested_expected_loss_amount,

    p.avg_requested_payment_to_income_ratio,
    p.avg_approved_payment_to_income_ratio_offer_rows,

    p.avg_apr_proxy_all_apps,
    p.avg_apr_proxy_offer_rows,
    p.requested_amount_weighted_apr_proxy,
    p.approved_amount_weighted_apr_proxy,
    p.requested_amount_x_apr_proxy_sum,
    p.approved_amount_x_apr_proxy_sum,

    p.avg_loan_term_months_offer_rows,
    p.approved_amount_weighted_term_months,
    p.term_missing_or_revolving_count,

    p.secured_approved_amount_share,
    p.unsecured_approved_amount_share,
    p.revolving_approved_amount_share,
    p.installment_approved_amount_share,
    p.mortgage_approved_amount_share,

    pj.product_approved_amount_mix_jsonb,
    pj.product_approved_expected_loss_mix_jsonb,
    pj.product_offer_rate_jsonb,

    p.avg_synthetic_estimated_pd_proxy_all_apps,
    p.avg_synthetic_estimated_pd_proxy_offer_rows,
    p.avg_synthetic_estimated_pd_proxy_declined_rows,

    p.avg_estimated_lgd_all_apps,
    p.avg_estimated_lgd_offer_rows,

    p.total_requested_expected_loss_amount,
    p.total_approved_expected_loss_amount,
    p.avg_requested_expected_loss_amount,
    p.avg_approved_expected_loss_all_apps,
    p.avg_approved_expected_loss_offer_rows,

    p.requested_expected_loss_rate,
    p.approved_expected_loss_rate,
    p.approved_amount_per_approved_expected_loss_dollar,

    COALESCE(f.top_primary_reason_family, rd.top_primary_reason_family),
    COALESCE(f.top_primary_reason_code, rd.top_primary_reason_code),
    COALESCE(f.top_primary_reason_population_share, rd.top_primary_reason_population_share),

    COALESCE(f.top_non_approval_primary_reason_family, rd.top_non_approval_primary_reason_family),
    COALESCE(f.top_non_approval_primary_reason_code, rd.top_non_approval_primary_reason_code),
    COALESCE(f.top_non_approval_reason_population_share, rd.top_non_approval_reason_population_share),

    COALESCE(f.top_policy_stop_primary_reason_family, rd.top_policy_stop_primary_reason_family),
    COALESCE(f.top_policy_stop_primary_reason_code, rd.top_policy_stop_primary_reason_code),
    COALESCE(f.top_policy_stop_reason_population_share, rd.top_policy_stop_reason_population_share),

    f.top_reason_code_delta_driver_family,
    f.top_reason_code_delta_driver_code,
    f.top_reason_code_delta_driver_baseline_share,
    f.top_reason_code_delta_driver_strategy_share,
    f.top_reason_code_delta_population_share,

    rd.top_counteroffer_reason_code,
    rd.top_manual_review_reason_code,
    rd.top_decline_reason_code,

    f.frontier_position_type,
    f.executive_frontier_quadrant,
    f.frontier_interpretation_note,

    vs.validation_pass_count,
    vs.validation_review_count,
    vs.validation_not_applicable_count,
    vs.validation_review_items,
    vs.validation_status_summary_jsonb,

    pd.top_approved_amount_product,
    pd.top_approved_amount_product_share,
    pd.top_approved_expected_loss_product,
    pd.top_approved_expected_loss_product_share,
    pd.top_counteroffer_product,
    pd.top_decline_product,
    pd.highest_offer_rate_product,
    pd.lowest_offer_rate_product,

    sd.top_approved_amount_score_band,
    sd.top_approved_expected_loss_score_band,
    sd.top_counteroffer_score_band,
    sd.top_decline_score_band,
    sd.highest_offer_rate_score_band,
    sd.lowest_offer_rate_score_band,
    sd.highest_approved_el_rate_score_band,

    psd.top_approved_amount_product_score_segment,
    psd.top_approved_el_product_score_segment,
    psd.top_counteroffer_product_score_segment,
    psd.top_decline_product_score_segment,
    psd.highest_approved_el_rate_product_score_segment,

    dd.largest_delta_approved_amount_product,
    dd.largest_delta_approved_el_product,
    dd.largest_delta_offer_rate_score_band,
    dd.largest_delta_decline_rate_score_band,
    dd.largest_delta_approved_el_product_score_segment,

    mr.module3_growth_inputs_available_flag,
    mr.module3_growth_input_gap_note,
    mr.module3_revenue_model_required_flag,
    mr.module3_boundary_note

FROM current_key k
CROSS JOIN story
CROSS JOIN archive_ts ats
CROSS JOIN portfolio p
CROSS JOIN product_json pj
CROSS JOIN product_drivers pd
CROSS JOIN score_drivers sd
CROSS JOIN product_score_drivers psd
CROSS JOIN reason_drivers rd
CROSS JOIN validation_summary vs
CROSS JOIN delta_drivers dd
CROSS JOIN module3_readiness mr
LEFT JOIN frontier f
    ON TRUE;



/***************************************************************************************************
SECTION 16.7 — LOCAL EVIDENCE CAPTURE GATEKEEPERS
****************************************************************************************************

PURPOSE:
    Confirm that Section 16 persisted exactly the evidence expected for the current run.

These checks validate evidence-capture integrity only.
They do not modify latest-run output or archive output.

***************************************************************************************************/

DO $$
DECLARE
    k RECORD;

    v_summary_count BIGINT;
    v_validation_count BIGINT;
    v_parameter_snapshot_count BIGINT;
    v_segment_count BIGINT;
    v_expected_segment_count BIGINT;

    v_null_required_summary_count BIGINT;
    v_module3_gap_count BIGINT;
BEGIN
    SELECT *
    INTO k
    FROM tmp_m2_current_run_key
    LIMIT 1;

    SELECT COUNT(*)
    INTO v_summary_count
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id;

    IF v_summary_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: expected exactly one executive evidence summary row for current run, found %.',
            v_summary_count;
    END IF;


    SELECT COUNT(*)
    INTO v_validation_count
    FROM credit_decisioning_sim.strategy_run_validation_evidence e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id;

    IF v_validation_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: no validation evidence rows were captured for current run.';
    END IF;


    SELECT COUNT(*)
    INTO v_parameter_snapshot_count
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id;

    IF v_parameter_snapshot_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: expected exactly one parameter snapshot row for current run, found %.',
            v_parameter_snapshot_count;
    END IF;


    SELECT COUNT(*)
    INTO v_segment_count
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id;

    SELECT COUNT(*)
    INTO v_expected_segment_count
    FROM (
        SELECT DISTINCT
            product_type_policy_key,
            score_band_policy_key
        FROM credit_decisioning_sim.strategy_decisions
    ) d;

    IF v_segment_count <> v_expected_segment_count THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: segment evidence row count (%) does not match expected product × score segment count (%).',
            v_segment_count,
            v_expected_segment_count;
    END IF;


    SELECT COUNT(*)
    INTO v_null_required_summary_count
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id
      AND (
             e.evidence_snapshot_ts IS NULL
          OR e.strategy_set_name IS NULL
          OR e.strategy_name IS NULL
          OR e.strategy_version IS NULL
          OR e.module1_scenario_set_name IS NULL
          OR e.module1_scenario_name IS NULL
          OR e.population_id IS NULL
          OR e.applications IS NULL
          OR e.approval_rate IS NULL
          OR e.counteroffer_rate IS NULL
          OR e.manual_review_rate IS NULL
          OR e.decline_rate IS NULL
          OR e.simulated_offer_exposure_rate IS NULL
          OR e.total_approved_amount IS NULL
          OR e.total_approved_expected_loss_amount IS NULL
          OR e.top_primary_reason_code IS NULL
      );

    IF v_null_required_summary_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: executive evidence summary has null required evidence fields.';
    END IF;


    SELECT COUNT(*)
    INTO v_module3_gap_count
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id
      AND e.module3_growth_inputs_available_flag IS DISTINCT FROM TRUE;

    /*
    A Module 3 readiness gap does not fail Section 16 because Module 3 is future scope.
    The evidence row stores the gap note for later design review.
    */
END $$;



/***************************************************************************************************
SECTION 16.8 — EVIDENCE CAPTURE DIAGNOSTICS AND EXPORT-READY VIEWS
****************************************************************************************************

PURPOSE:
    Provide compact review outputs after evidence capture.

HOW TO USE:
    After each Module 2 run in the scenario / strategy campaign, the user should review:
        1. the latest executive evidence summary row,
        2. validation rows with REVIEW or NOT_APPLICABLE status,
        3. parameter snapshot existence,
        4. product × score segment evidence count.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
16.8A Evidence object row-count diagnostic for the current run.
-----------------------------------------------------------------------------------------------*/
WITH k AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
)

SELECT
    'strategy_run_evidence_summary' AS evidence_object_name,
    COUNT(*) AS current_run_evidence_rows
FROM credit_decisioning_sim.strategy_run_evidence_summary e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id

UNION ALL

SELECT
    'strategy_run_validation_evidence' AS evidence_object_name,
    COUNT(*) AS current_run_evidence_rows
FROM credit_decisioning_sim.strategy_run_validation_evidence e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id

UNION ALL

SELECT
    'strategy_run_parameter_snapshot' AS evidence_object_name,
    COUNT(*) AS current_run_evidence_rows
FROM credit_decisioning_sim.strategy_run_parameter_snapshot e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id

UNION ALL

SELECT
    'strategy_run_segment_evidence_summary' AS evidence_object_name,
    COUNT(*) AS current_run_evidence_rows
FROM credit_decisioning_sim.strategy_run_segment_evidence_summary e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id;


/*-----------------------------------------------------------------------------------------------
16.8B Latest executive evidence summary row.

This is the primary one-row evidence record to export after each run.
-----------------------------------------------------------------------------------------------*/
SELECT
    evidence_snapshot_ts,

    module1_run_id,
    module2_run_id,
    showcase_name,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_parameter_family_changed,
    module2_strategy_family_changed,

    applications,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,

    total_requested_amount,
    total_approved_amount,
    approved_amount_capture_rate,

    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_approved_payment_to_income_ratio_offer_rows,

    total_requested_expected_loss_amount,
    total_approved_expected_loss_amount,
    approved_expected_loss_rate,
    approved_amount_per_approved_expected_loss_dollar,

    top_primary_reason_code,
    top_non_approval_primary_reason_code,
    top_policy_stop_primary_reason_code,
    top_reason_code_delta_driver_code,
    top_reason_code_delta_population_share,

    frontier_position_type,
    executive_frontier_quadrant,
    frontier_interpretation_note,

    top_approved_amount_product,
    top_approved_expected_loss_product,
    top_approved_amount_score_band,
    top_approved_expected_loss_score_band,
    top_approved_el_product_score_segment,

    largest_delta_approved_amount_product,
    largest_delta_approved_el_product,
    largest_delta_offer_rate_score_band,
    largest_delta_decline_rate_score_band,
    largest_delta_approved_el_product_score_segment,

    validation_pass_count,
    validation_review_count,
    validation_not_applicable_count,
    validation_review_items,

    module3_growth_inputs_available_flag,
    module3_growth_input_gap_note,
    module3_boundary_note

FROM credit_decisioning_sim.strategy_run_evidence_summary
ORDER BY evidence_snapshot_ts DESC
LIMIT 1;


/*-----------------------------------------------------------------------------------------------
16.8C Current run validation items requiring interpretation.

REVIEW and NOT_APPLICABLE statuses are not automatic failures. They are prompts for validation
narrative and later documentation.
-----------------------------------------------------------------------------------------------*/
WITH k AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
)

SELECT
    e.validation_area,
    e.validation_test_name,
    e.validation_category,
    e.validation_status,
    e.observed_value,
    e.expected_behavior,
    e.interpretation
FROM credit_decisioning_sim.strategy_run_validation_evidence e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id
WHERE e.validation_status IN ('REVIEW', 'NOT_APPLICABLE')
ORDER BY
    e.validation_status,
    e.validation_area,
    e.validation_test_name;


/*-----------------------------------------------------------------------------------------------
16.8D Current run product × score segment evidence.

This view supports executive driver review and future Module 3 product / score-sensitive economics.
-----------------------------------------------------------------------------------------------*/
WITH k AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
)

SELECT
    e.product_type_policy_key,
    e.score_band_policy_key,
    e.product_score_policy_segment,

    e.applications,

    e.approval_rate,
    e.counteroffer_rate,
    e.manual_review_rate,
    e.decline_rate,
    e.simulated_offer_exposure_rate,

    e.total_approved_amount,
    e.total_approved_expected_loss_amount,
    e.approved_expected_loss_rate,

    e.approved_amount_weighted_apr_proxy,
    e.approved_amount_weighted_term_months,

    e.avg_synthetic_estimated_pd_proxy_offer_rows,
    e.avg_approved_payment_to_income_ratio_offer_rows,

    e.top_primary_reason_code,
    e.top_non_approval_primary_reason_code
FROM credit_decisioning_sim.strategy_run_segment_evidence_summary e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id
ORDER BY
    e.total_approved_expected_loss_amount DESC NULLS LAST,
    e.product_type_policy_key,
    e.score_band_policy_key;


/*-----------------------------------------------------------------------------------------------
16.8E Parameter snapshot diagnostic.

This confirms that the temporary parameter tables were captured into persistent evidence.
-----------------------------------------------------------------------------------------------*/
WITH k AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
)

SELECT
    e.evidence_snapshot_ts,
    e.strategy_set_name,
    e.strategy_name,
    e.strategy_version,
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,

    e.parameter_snapshot_hash,

    e.strategy_params_jsonb IS NOT NULL AS strategy_params_captured_flag,
    e.product_policy_params_jsonb IS NOT NULL AS product_policy_params_captured_flag,
    e.run_story_params_jsonb IS NOT NULL AS run_story_params_captured_flag
FROM credit_decisioning_sim.strategy_run_parameter_snapshot e
JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id;



/***************************************************************************************************
END OF SECTION 16 — STRATEGY RUN EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER

Section 16 established:
    1. Persistent executive run evidence summary.
    2. Persistent validation evidence detail.
    3. Persistent strategy and product-policy parameter snapshot.
    4. Persistent product × score segment evidence summary.
    5. Module 3 readiness fields for future growth / earnings design.
    6. Product, score-band, and product × score executive driver fields.
    7. Reason-code storytelling fields for executive interpretation.
    8. Compact export-ready diagnostics after every run.

Section 16 does not modify latest-run strategy decisions.
Section 16 does not modify strategy archive rows.
Section 16 does not recalculate decisions.
Section 16 does not reassign simulated reason codes.
Section 16 does not recalculate approved exposure.
Section 16 does not recalculate approved Expected Loss.
Section 16 does not implement revenue, earnings, pricing, funding-cost, profitability, or capital logic.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00584 -->


---

<a id="c038-m00585"></a>

### C038-M00585

**Andrew** · 2026-05-09T07:35:12.467000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00585 -->
SQL Error [P0001]: ERROR: Module 2 Section 16 failure: tmp_m2_validation_status_summary is required before evidence capture.
  Where: PL/pgSQL function inline_code_block line 46 at RAISE
  ERROR: Module 2 Section 16 failure: tmp_m2_validation_status_summary is required before evidence capture.
  Where: PL/pgSQL function inline_code_block line 46 at RAISE
<!-- END_MESSAGE C038-M00585 -->


---

<a id="c038-m00590"></a>

### C038-M00590

**ChatGPT** · 2026-05-09T07:39:01.259829-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00590 -->
This is an **execution-order / temp-table dependency issue**, not a Module 2 decision-logic issue.

Section 16 is correctly stopping because it needs the Section 14 validation status summary:

```sql
tmp_m2_validation_status_summary
```

That object is a **temporary table**. It only exists in the same active database session after Section 14 has been run. `ON COMMIT PRESERVE ROWS` preserves rows through commits, but it does **not** preserve the temp table after the connection/session is closed or if the SQL is run in a different session.

## Most likely cause

You ran Section 16 without first running Section 14 in the same active session, or your SQL client opened a new connection between the Section 14/15 QA work and the Section 16 run.

Section 16 also depends on these temporary objects:

```sql
tmp_m2_validation_status_summary
tmp_m2_strategy_frontier_executive_summary
tmp_module2_strategy_params
tmp_module2_product_policy_params
```

So after fixing the Section 14 dependency, Section 16 could hit the next missing temp object if Section 15 or the parameter sections were also not present in the same session.

This dependency is conceptually appropriate because Section 16 is meant to persist the evidence layer after QA has been produced. Module 1’s implementation guidance explicitly treats QA outputs as validation evidence rather than decorative outputs, and that is the same discipline we are applying here. fileciteturn8file3

## Immediate fix

Run this pre-check before Section 16:

```sql
SELECT
    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') AS validation_summary_temp,
    TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary') AS frontier_summary_temp,
    TO_REGCLASS('pg_temp.tmp_module2_strategy_params') AS strategy_params_temp,
    TO_REGCLASS('pg_temp.tmp_module2_product_policy_params') AS product_policy_params_temp;
```

If any value is `NULL`, rerun the relevant section in the same session:

| Missing temp object | Rerun |
|---|---|
| `tmp_m2_validation_status_summary` | Section 14 |
| `tmp_m2_strategy_frontier_executive_summary` | Section 15 |
| `tmp_module2_strategy_params` | Sections 2–3, or full script |
| `tmp_module2_product_policy_params` | Sections 2–3, or full script |

For this test, the cleanest path is:

```text
Run Sections 14 → 15 → 16 in the same SQL session.
```

Or simply rerun the full Module 2 script top to bottom if you want to confirm all temp dependencies and evidence tables are populated in one pass.

## No business-logic patch required

I would **not** patch Section 16 to silently proceed without `tmp_m2_validation_status_summary`.

That would weaken the evidence-capture purpose. Section 16 should not create an executive evidence row that lacks the validation evidence layer. The fail-fast behavior is doing the right thing.

## Optional hardening patch

The only patch I would consider is a better dependency diagnostic so Section 16 reports **all missing required temp objects at once** instead of failing one at a time.

### BEFORE

Your current Section 16 gatekeeper checks each required object separately and raises at the first missing object.

### AFTER — optional diagnostic pre-check

Add this right before the Section 16.0 `DO $$` gatekeeper:

```sql
/***************************************************************************************************
SECTION 16.0A — EVIDENCE CAPTURE TEMP DEPENDENCY DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    Show whether Section 16 has the temporary upstream evidence objects required for run evidence
    capture.

INTERPRETATION:
    Section 16 should be run after Sections 14 and 15 in the same active database session.

    Temporary objects do not survive a closed connection, even when created with
    ON COMMIT PRESERVE ROWS.

***************************************************************************************************/

SELECT
    'tmp_m2_validation_status_summary' AS required_temp_object,
    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') IS NOT NULL AS object_available_flag,
    'Rerun Section 14 in the same session if unavailable.' AS remediation_note

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_executive_summary' AS required_temp_object,
    TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary') IS NOT NULL AS object_available_flag,
    'Rerun Section 15 in the same session if unavailable.' AS remediation_note

UNION ALL

SELECT
    'tmp_module2_strategy_params' AS required_temp_object,
    TO_REGCLASS('pg_temp.tmp_module2_strategy_params') IS NOT NULL AS object_available_flag,
    'Rerun Sections 2–3 or the full script in the same session if unavailable.' AS remediation_note

UNION ALL

SELECT
    'tmp_module2_product_policy_params' AS required_temp_object,
    TO_REGCLASS('pg_temp.tmp_module2_product_policy_params') IS NOT NULL AS object_available_flag,
    'Rerun Sections 2–3 or the full script in the same session if unavailable.' AS remediation_note;
```

This does not change logic. It only makes the dependency issue easier to diagnose.

## Recommended next action

Run:

```text
Sections 14, 15, and 16 together in the same session.
```

Then review Section 16.8 outputs. If Section 16 still fails, send the next error exactly as shown.
<!-- END_MESSAGE C038-M00590 -->


---

<a id="c038-m00592"></a>

### C038-M00592

**Andrew** · 2026-05-09T07:41:02.699000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00592 -->
I ran sections 1-15 just prior to running this.
<!-- END_MESSAGE C038-M00592 -->


---

<a id="c038-m00595"></a>

### C038-M00595

**ChatGPT** · 2026-05-09T07:43:17.021718-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00595 -->
This means **Section 14 did not actually materialize**:

```sql
tmp_m2_validation_status_summary
```

even though you ran Sections 1–15.

So the problem is not session loss if Sections 1–15 were truly run immediately before Section 16. The more likely issue is one of these:

1. **Section 14 produced the validation summary as a final SELECT / CTE only**, not as a temp table.
2. **The Section 14 validation summary patch was not actually integrated into the local SQL file.**
3. **The summary table was created under a different name.**
4. **The specific Section 14 block that creates the summary was skipped or not executed**, even if earlier Section 14 QA queries ran.

The accepted Section 14 patch required the object name:

```sql
tmp_m2_validation_status_summary
```

and Section 16 depends on that exact temp table. The prior final patch notes explicitly called for this table / CTE near the end of Section 14, with `tmp_m2_validation_status_summary` as the recommended name. fileciteturn8file2

## Run this diagnostic first

Run this immediately after Section 15, before Section 16:

```sql
SELECT
    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') AS pg_temp_validation_summary,
    TO_REGCLASS('tmp_m2_validation_status_summary') AS unqualified_validation_summary,
    TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary') AS pg_temp_frontier_summary,
    TO_REGCLASS('tmp_m2_strategy_frontier_executive_summary') AS unqualified_frontier_summary,
    TO_REGCLASS('pg_temp.tmp_module2_strategy_params') AS pg_temp_strategy_params,
    TO_REGCLASS('pg_temp.tmp_module2_product_policy_params') AS pg_temp_product_policy_params;
```

Then run:

```sql
SELECT
    n.nspname AS schema_name,
    c.relname AS object_name,
    c.relkind AS object_type
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE c.relname ILIKE '%validation%summary%'
   OR c.relname ILIKE '%m2%validation%'
ORDER BY
    n.nspname,
    c.relname;
```

If `tmp_m2_validation_status_summary` does not appear, Section 14 is not creating the required temp table.

## Most likely targeted patch

Look near the end of Section 14 for a block that does something like this:

```sql
WITH validation_status_summary AS (
    ...
)
SELECT
    *
FROM validation_status_summary;
```

or:

```sql
SELECT
    ...
```

that produces the validation status output but does not persist it.

Patch it to this pattern.

### BEFORE

```sql
WITH validation_status_summary AS (
    ...
)
SELECT
    *
FROM validation_status_summary
ORDER BY
    validation_area,
    validation_test_name;
```

### AFTER

```sql
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

CREATE TEMP TABLE tmp_m2_validation_status_summary
ON COMMIT PRESERVE ROWS
AS
WITH validation_status_summary AS (
    ...
)
SELECT
    *
FROM validation_status_summary;

/*
Review output:
    Final Section 14 validation status summary.

This table is intentionally materialized because Section 16 consumes it as the persistent
evidence source for strategy_run_validation_evidence.
*/
SELECT
    *
FROM tmp_m2_validation_status_summary
ORDER BY
    validation_area,
    validation_test_name;
```

That preserves all accepted validation logic. It only changes the final Section 14 summary from a transient result set into the temp table Section 16 needs.

## Also check for a naming mismatch

Search your SQL file for:

```text
tmp_m2_validation_status_summary
```

If it only appears in Section 16, then Section 14 never creates it.

If you find something similar like:

```sql
tmp_module2_validation_status_summary
tmp_m2_validation_summary
tmp_m2_validation_status
```

then the patch is a naming reconciliation issue: either rename the Section 14 temp table to the canonical name or update Section 16 to match. I recommend using the canonical name:

```sql
tmp_m2_validation_status_summary
```

## What to rerun after patch

After patching Section 14, rerun:

```text
Section 14 final validation summary block
Section 15
Section 16
```

You do not need to rerun Sections 1–13 unless the temp tables used by Section 14 or 15 are gone.

## Bottom line

Section 16 is behaving correctly. It should not capture executive evidence without the Section 14 validation summary.

The required fix is almost certainly:

```text
Materialize Section 14 validation status summary as:
tmp_m2_validation_status_summary
```

rather than leaving it as a one-time SELECT / CTE output.
<!-- END_MESSAGE C038-M00595 -->


---

<a id="c038-m00596"></a>

### C038-M00596

**Andrew** · 2026-05-09T07:51:20.709000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00596 -->
full section 14 code to assist this review:
<!-- END_MESSAGE C038-M00596 -->


**Attachments in export:** `Pasted text(107).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00599"></a>

### C038-M00599

**ChatGPT** · 2026-05-09T07:52:47.064077-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00599 -->
I reviewed the Section 14 code you attached. The important finding is:

**Section 14 does contain the required `tmp_m2_validation_status_summary` creation block.**

Specifically, your Section 14.19 includes:

```sql
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

CREATE TEMP TABLE tmp_m2_validation_status_summary
ON COMMIT PRESERVE ROWS
AS
...
```

So the Section 16 error is **not because Section 14 is missing the temp table creation logic**. The uploaded Section 14 text clearly includes the intended Section 14.19 validation status summary table creation. fileciteturn9file0

## Most likely explanation

One of these happened:

1. **Section 14.19 did not actually execute**, even though earlier Section 14 QA queries did.
2. **Section 14.19 executed in a different database session / connection** than Section 16.
3. **The SQL client executed only part of the Section 14 script**, for example through Section 14.18 but not Section 14.19.
4. **The full “Sections 1–15” run did not include the latest Section 14.19 block**, even though the pasted Section 14 file does.

This is now an execution-control issue, not a design issue.

---

## Confirm immediately after Section 14.19

Run this right after Section 14.19 and before Section 15 or 16:

```sql
SELECT
    pg_backend_pid() AS backend_pid,
    current_database() AS database_name,
    current_schema() AS current_schema_name,

    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary')
        AS pg_temp_validation_summary,

    TO_REGCLASS('tmp_m2_validation_status_summary')
        AS unqualified_validation_summary;
```

Expected:

```text
pg_temp_validation_summary = tmp_m2_validation_status_summary
```

or at least non-null.

Then run:

```sql
SELECT
    COUNT(*) AS validation_status_summary_rows
FROM tmp_m2_validation_status_summary;
```

Expected:

```text
validation_status_summary_rows > 0
```

If this works immediately after Section 14.19 but Section 16 still fails later, the session changed between Section 14 and Section 16.

---

## Add a small Section 14.19 post-check

I recommend adding this directly after the Section 14.19 `CREATE TEMP TABLE` block.

```sql
/***************************************************************************************************
SECTION 14.19A — VALIDATION STATUS SUMMARY MATERIALIZATION CHECK
****************************************************************************************************

PURPOSE:
    Confirm that Section 14.19 successfully materialized tmp_m2_validation_status_summary.

WHY THIS EXISTS:
    Section 16 depends on this temporary table to persist validation evidence.

    Temporary tables are session-scoped. If Section 16 is run in a different database session, or if
    Section 14.19 was skipped, Section 16 will not be able to capture validation evidence.

***************************************************************************************************/

DO $$
DECLARE
    v_validation_summary_exists BOOLEAN;
    v_validation_summary_rows BIGINT;
BEGIN
    SELECT TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') IS NOT NULL
    INTO v_validation_summary_exists;

    IF v_validation_summary_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 14.19 failure: tmp_m2_validation_status_summary was not materialized.';
    END IF;

    SELECT COUNT(*)
    INTO v_validation_summary_rows
    FROM tmp_m2_validation_status_summary;

    IF v_validation_summary_rows <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 14.19 failure: tmp_m2_validation_status_summary contains zero rows.';
    END IF;
END $$;


/*
Review output:
    Section 14.19 validation status summary row count.

Expected:
    row_count > 0
*/
SELECT
    COUNT(*) AS validation_status_summary_rows
FROM tmp_m2_validation_status_summary;
```

This does not change validation logic. It simply proves the temp table exists before moving to Section 15 or Section 16.

---

## Add a Section 16 dependency diagnostic before the gatekeeper

I would also add this before the Section 16 `DO $$` gatekeeper so the next failure is easier to diagnose:

```sql
/***************************************************************************************************
SECTION 16.0A — EVIDENCE CAPTURE TEMP DEPENDENCY DIAGNOSTIC
****************************************************************************************************/

SELECT
    pg_backend_pid() AS backend_pid,
    current_database() AS database_name,

    'tmp_m2_validation_status_summary' AS required_temp_object,
    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') IS NOT NULL AS object_available_flag,
    'Rerun Section 14.19 in the same session if unavailable.' AS remediation_note

UNION ALL

SELECT
    pg_backend_pid(),
    current_database(),
    'tmp_m2_strategy_frontier_executive_summary',
    TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary') IS NOT NULL,
    'Rerun Section 15 in the same session if unavailable.'

UNION ALL

SELECT
    pg_backend_pid(),
    current_database(),
    'tmp_module2_strategy_params',
    TO_REGCLASS('pg_temp.tmp_module2_strategy_params') IS NOT NULL,
    'Rerun Sections 2–3 or the full script in the same session if unavailable.'

UNION ALL

SELECT
    pg_backend_pid(),
    current_database(),
    'tmp_module2_product_policy_params',
    TO_REGCLASS('pg_temp.tmp_module2_product_policy_params') IS NOT NULL,
    'Rerun Sections 2–3 or the full script in the same session if unavailable.';
```

This will show all missing temp dependencies at once.

---

## Recommended immediate rerun path

Do this in one SQL editor tab / same connection:

```text
1. Run Section 14.19 only.
2. Run the Section 14.19A materialization check.
3. Run Section 15.
4. Run Section 16.
```

No need to rerun Sections 1–13 if the permanent output tables already exist and the temp parameter tables are still present.

If the parameter temp tables are also gone, then rerun:

```text
Sections 2–3, 14.19, 15, 16
```

or simply run the full script top to bottom in one session.

---

## Bottom line

The uploaded Section 14 code is not missing `tmp_m2_validation_status_summary`. It creates it in Section 14.19. fileciteturn9file0

The Section 16 error means the table was not available **at Section 16 runtime**. Add the Section 14.19A check and Section 16.0A diagnostic, then rerun Section 14.19 → Section 15 → Section 16 in the same session.
<!-- END_MESSAGE C038-M00599 -->


---

<a id="c038-m00600"></a>

### C038-M00600

**Andrew** · 2026-05-09T08:45:04.394000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00600 -->
I see - section 16 ran effectively when I had it all in the same block (ran together) - i wonder if we can have it where I run sections 1-14 and then I run sections 15-16 separately.
<!-- END_MESSAGE C038-M00600 -->


---

<a id="c038-m00606"></a>

### C038-M00606

**ChatGPT** · 2026-05-09T08:47:41.089922-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00606 -->
Yes — you can run it as:

```text
Block A: Sections 1–14
Block B: Sections 15–16
```

**as long as both blocks run in the same PostgreSQL session / connection.**

The reason is that Section 14.19 creates `tmp_m2_validation_status_summary` as a temporary table with `ON COMMIT PRESERVE ROWS`, so it survives commits but not a disconnected or changed database session. fileciteturn11file0 Section 16 also depends on temporary parameter tables like `tmp_module2_strategy_params` and `tmp_module2_product_policy_params`, which are part of the canonical Module 2 temporary object design. fileciteturn11file2

## Recommended operating pattern

### Block A — run Sections 1–14

After Section 14 finishes, run this check **before closing the SQL editor tab or connection**:

```sql
SELECT
    pg_backend_pid() AS backend_pid_after_section_14,

    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') IS NOT NULL
        AS validation_status_summary_available,

    TO_REGCLASS('pg_temp.tmp_module2_strategy_params') IS NOT NULL
        AS strategy_params_available,

    TO_REGCLASS('pg_temp.tmp_module2_product_policy_params') IS NOT NULL
        AS product_policy_params_available;
```

Expected:

```text
validation_status_summary_available = TRUE
strategy_params_available = TRUE
product_policy_params_available = TRUE
```

Then run:

```sql
SELECT
    COUNT(*) AS validation_status_summary_rows
FROM tmp_m2_validation_status_summary;
```

Expected:

```text
validation_status_summary_rows > 0
```

### Block B — run Sections 15–16

Before Section 16 starts, run:

```sql
SELECT
    pg_backend_pid() AS backend_pid_before_section_16,

    TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary') IS NOT NULL
        AS validation_status_summary_available,

    TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary') IS NOT NULL
        AS frontier_executive_summary_available,

    TO_REGCLASS('pg_temp.tmp_module2_strategy_params') IS NOT NULL
        AS strategy_params_available,

    TO_REGCLASS('pg_temp.tmp_module2_product_policy_params') IS NOT NULL
        AS product_policy_params_available;
```

Expected after Section 15 has run:

```text
validation_status_summary_available = TRUE
frontier_executive_summary_available = TRUE
strategy_params_available = TRUE
product_policy_params_available = TRUE
```

If those are true, Section 16 should run.

## Important session rule

If this value changes between Block A and Block B:

```sql
pg_backend_pid()
```

then your SQL client opened a new backend session, and the temp tables from Sections 1–14 are gone.

In that case, Section 16 will fail again unless you recreate the temp dependencies.

## If the session changes, use this recovery sequence

Do **not** rerun Section 1, because Section 1 drops the latest-run output table.

Instead, run this in the new session:

```text
1. Section 2 only — recreate tmp_module2_strategy_params and tmp_module2_product_policy_params
2. Section 3 only — rerun parameter/source gatekeepers
3. Section 14.19 only — recreate tmp_m2_validation_status_summary
4. Section 15
5. Section 16
```

Critical caveat: Section 2 must use the **same active strategy parameters** as the latest-run output you are trying to capture. Otherwise the parameter snapshot in Section 16 could describe a different strategy configuration than the latest-run output.

## My recommendation

For the campaign runs, use the two-block approach:

```text
Block A: Sections 1–14
Block B: Sections 15–16
```

but keep the same SQL connection open. Add the backend/session check above. That gives you a clean operating workflow without changing business logic.

A cross-session permanent solution is possible, but it would require persisting the Section 14 validation summary and parameter snapshot before Section 16. I would only add that if your SQL client keeps changing sessions or you expect frequent disconnects.
<!-- END_MESSAGE C038-M00606 -->


---

<a id="c038-m00608"></a>

### C038-M00608

**Andrew** · 2026-05-09T08:59:54.832000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00608 -->
review section 16 QA:
<!-- END_MESSAGE C038-M00608 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8B_QA_latest_executive_evidence_summary_row.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8D_QA_current_run_product_x_score_segment_evidence.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8E_QA_parameter_snapshot_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8A_QA_evidence_object_row_count_diagnostic_for_the_current_run.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00613"></a>

### C038-M00613

**ChatGPT** · 2026-05-09T09:03:12.644891-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00613 -->
## Section 16 QA review — Strategy Run Evidence Capture and Executive Story Register

**Verdict: PASS, with two optional storytelling refinements.**

Section 16 is working as intended. It captured the current run’s executive story, validation evidence, parameter snapshot, and product × score segment evidence into persistent evidence tables. This gives you exactly what you wanted: a single, compact place to preserve the run narrative and validation signals without having to reconstruct the story from Sections 12–15 every time.

The current captured run is:

```text
Module 1 scenario:
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

Module 2 strategy:
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0
```

---

## 1. Section 16.8A — Evidence object row-count diagnostic

**Assessment: PASS.**

| Evidence object | Current run rows | Expected |
|---|---:|---:|
| `strategy_run_evidence_summary` | 1 | 1 |
| `strategy_run_validation_evidence` | 22 | > 0 |
| `strategy_run_parameter_snapshot` | 1 | 1 |
| `strategy_run_segment_evidence_summary` | 25 | 25 |

This confirms the evidence capture structure is complete.

The 25 segment rows are correct:

```text
5 products × 5 score bands = 25 product × score evidence rows
```

No issue.

---

## 2. Section 16.8B — Latest executive evidence summary row

**Assessment: PASS.**

The executive evidence row is populated and tells a clear risk-discipline story.

Key captured results:

| Metric | Captured value |
|---|---:|
| Applications | 50,000 |
| Approval rate | 21.30% |
| Counteroffer rate | 36.90% |
| Manual review rate | 12.03% |
| Decline rate | 29.76% |
| Simulated offer-exposure rate | 58.20% |
| Total requested amount | $6.666B |
| Total approved amount | $3.728B |
| Approved amount capture rate | 55.92% |
| Total requested Expected Loss | $239.43M |
| Total approved Expected Loss | $51.67M |
| Approved Expected Loss rate | 1.386% |
| Approved amount per approved Expected Loss dollar | $72.15 |
| Avg synthetic estimated-PD proxy, offer rows | 5.64% |
| Avg approved PTI, offer rows | 11.97% |

The frontier fields are also correct:

```text
frontier_position_type = RISK_DISCIPLINE_FRONTIER_POINT
executive_frontier_quadrant = LOWER_ACCESS_LOWER_APPROVED_EL_RATE
```

That is exactly the right executive summary for the tighter synthetic-risk strategy.

---

## 3. Reason-code storytelling fields

**Assessment: PASS.**

The storytelling fields are populated and useful:

| Field | Value |
|---|---|
| `top_primary_reason_code` | `APPROVED_AS_REQUESTED` |
| `top_non_approval_primary_reason_code` | `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` |
| `top_policy_stop_primary_reason_code` | `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` |
| `top_reason_code_delta_driver_code` | `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` |
| `top_reason_code_delta_population_share` | +4.508 percentage points |

This is excellent because it separates the three different reason-code stories:

```text
Most common overall reason:
APPROVED_AS_REQUESTED

Most common non-approval reason:
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT

Largest reason-code movement versus baseline:
POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY
```

That resolves the earlier ambiguity where the top non-approval reason stayed flat at 17.81%. The current evidence correctly shows that the **dominant movement** is synthetic-risk policy-stop growth, not product-cap counteroffers.

---

## 4. Product, score, and product × score executive drivers

**Assessment: PASS.**

The executive driver fields are populated and directionally coherent:

| Driver field | Value |
|---|---|
| `top_approved_amount_product` | `MORTGAGE` |
| `top_approved_expected_loss_product` | `MORTGAGE` |
| `top_approved_amount_score_band` | `PRIME` |
| `top_approved_expected_loss_score_band` | `NEAR_PRIME` |
| `top_approved_el_product_score_segment` | `MORTGAGE / NEAR_PRIME` |
| `largest_delta_approved_amount_product` | `MORTGAGE` |
| `largest_delta_approved_el_product` | `MORTGAGE` |
| `largest_delta_offer_rate_score_band` | `SUBPRIME` |
| `largest_delta_decline_rate_score_band` | `SUBPRIME` |
| `largest_delta_approved_el_product_score_segment` | `MORTGAGE / NEAR_PRIME` |

This is exactly the kind of executive narrative we wanted Section 16 to preserve.

The story is:

```text
Mortgage remains the largest approved-exposure and approved-Expected-Loss driver.
Near Prime is the largest approved Expected Loss score band.
Subprime is the score band with the largest offer-rate and decline-rate movement.
Mortgage / Near Prime is the most important product × score segment for approved Expected Loss movement.
```

That is a strong senior credit strategy narrative.

---

## 5. Section 16.8C — Validation items requiring interpretation

**Assessment: PASS; all three are expected REVIEW items, not defects.**

Section 16 captured:

```text
validation_pass_count = 19
validation_review_count = 3
validation_not_applicable_count = 0
```

The three REVIEW items are appropriate.

### REVIEW 1 — Decision outcome concentration

Observed:

```text
approval_rate = 21.30%
counteroffer_rate = 36.90%
manual_review_rate = 12.03%
decline_rate = 29.76%
```

Interpretation: acceptable for a tighter synthetic-risk strategy. The strategy intentionally shifts more records into decline and counteroffer paths. This should be documented as a strategy posture, not treated as a defect.

### REVIEW 2 — Mixed-signal and edge-case diagnostics

Observed:

```text
mixed_signal_rows = 17,583
borderline_rows = 17,059
residual_review_rows = 0
mixed_signal_manual_review_rows = 1,306
```

Interpretation: acceptable. The important point is that residual review rows are zero. Mixed-signal and borderline populations remain visible, which is desirable for realism and strategy QA.

### REVIEW 3 — Score-band strategy distribution

Observed:

```text
score_band_count = 5
max_score_decision_share = 1.0
```

Interpretation: expected under this tighter strategy because `DEEP_SUBPRIME` is fully routed to decline. That is a concentration worth documenting, but it is directionally coherent with a tighter synthetic-risk strategy and prior Section 13 / 15 evidence.

No validation item is failing.

---

## 6. Section 16.8D — Product × score segment evidence

**Assessment: PASS.**

The segment evidence table has the expected 25 rows and the highest-loss segments are intuitive.

Top approved Expected Loss segments:

| Segment | Approved Expected Loss | Offer rate | Top primary reason |
|---|---:|---:|---|
| `MORTGAGE_NEAR_PRIME` | $16.60M | 62.68% | `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` |
| `MORTGAGE_PRIME` | $12.07M | 82.12% | `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` |
| `MORTGAGE_SUPER_PRIME` | $3.58M | 92.14% | `APPROVED_AS_REQUESTED` |
| `AUTO_LOAN_NEAR_PRIME` | $3.25M | 76.07% | `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` |
| `HELOC_NEAR_PRIME` | $3.11M | 71.60% | `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` |

This confirms that the segment evidence table is doing its job: it identifies the segments driving approved exposure, approved Expected Loss, and strategy explanation.

The decline concentration is also coherent:

```text
All DEEP_SUBPRIME product segments have offer rate = 0 and decline rate = 100%.
Top reason = POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY.
```

That explains the Section 16.8C score-band concentration REVIEW item.

---

## 7. Section 16.8E — Parameter snapshot diagnostic

**Assessment: PASS.**

All parameter snapshot flags are true:

```text
strategy_params_captured_flag = true
product_policy_params_captured_flag = true
run_story_params_captured_flag = true
```

The parameter snapshot hash is populated:

```text
c244a2ef5c0a343ac191ba77b0da71dd
```

This is important. It means the evidence layer preserved the active strategy parameter card, product policy parameter card, and run-story metadata.

This gives you a durable audit trail for later README, Validation Summary, and Module 3 design work.

---

## 8. Module 3 readiness fields

**Assessment: PASS.**

The readiness flag is true:

```text
module3_growth_inputs_available_flag = true
```

The gap note is also correctly bounded:

```text
Core Module 3 readiness inputs are available: approved amount, APR proxy, product,
synthetic estimated-PD proxy, LGD, and approved Expected Loss. Utilization, funding cost,
fee income, and revenue assumptions remain future Module 3 design inputs.
```

This is exactly the right boundary. Section 16 captures growth / exposure / APR proxy inputs, but it does not calculate earnings, revenue, funding cost, or risk-adjusted margin.

---

## 9. Minor optional refinement 1 — `showcase_name`

Current value:

```text
showcase_name = BASELINE_REFERENCE
```

This is technically understandable because the Module 1 scenario is `BASELINE_V2`, but for executive storytelling it undersells the run. This row is not just a baseline reference; it is the **tighter synthetic-risk strategy on the baseline Module 1 scenario**.

I recommend a small metadata-only refinement later:

```text
If module1_scenario_name = 'BASELINE_V2'
and strategy_name = 'BASELINE_STRATEGY':
    showcase_name = BASELINE_REFERENCE

If module1_scenario_name = 'BASELINE_V2'
and strategy_name <> 'BASELINE_STRATEGY':
    showcase_name = BASELINE_STRATEGY_FRONTIER_SHOWCASE
```

This is not a logic issue. It is a narrative metadata improvement.

---

## 10. Minor optional refinement 2 — product × score segment label format

The executive table uses:

```text
MORTGAGE / NEAR_PRIME
```

while the segment evidence table uses:

```text
MORTGAGE_NEAR_PRIME
```

Both refer to the same segment. This is not a defect. But for export consistency, we may eventually want either:

```text
canonical segment key = MORTGAGE_NEAR_PRIME
display segment label = MORTGAGE / NEAR_PRIME
```

or use one format everywhere.

This is optional and not required before running the campaign.

---

# Section 16 acceptance conclusion

Section 16 is accepted.

Accepted evidence:

```text
Executive evidence summary row captured = 1
Validation evidence rows captured = 22
Parameter snapshot row captured = 1
Product × score segment evidence rows captured = 25
Applications = 50,000
All major decision, exposure, risk, reason-code, and frontier fields populated
Validation status summary captured: 19 PASS, 3 REVIEW, 0 NOT_APPLICABLE
Parameter snapshots captured successfully
Module 3 readiness fields populated and correctly bounded
Product / score / product × score drivers populated
Reason-code storytelling fields populated
```

No functional patch is required.

The current Section 16 output gives you a durable one-row executive story for the run:

> The tighter synthetic-risk strategy on `BASELINE_V2` produces a lower-access / lower-approved-Expected-Loss-rate frontier point, with 58.20% simulated offer exposure, $3.73B total approved amount, $51.67M approved Expected Loss, and a 1.386% approved Expected Loss rate. The largest reason-code movement versus baseline is a +4.51 percentage-point increase in `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`, while the largest segment movement is concentrated in `MORTGAGE / NEAR_PRIME` and `SUBPRIME`.

That is exactly the kind of evidence record we wanted before launching the full Module 1 / Module 2 scenario and strategy run campaign.
<!-- END_MESSAGE C038-M00613 -->


---

<a id="c038-m00614"></a>

### C038-M00614

**Andrew** · 2026-05-09T09:08:13.412000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00614 -->
Module 1 scenario:
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

Module 2 strategy:
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0  - do I need to go back and run module2 without the tighter synthetic risk strategy to record that run in the executive table?
<!-- END_MESSAGE C038-M00614 -->


---

<a id="c038-m00617"></a>

### C038-M00617

**ChatGPT** · 2026-05-09T09:09:31.393843-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00617 -->
Yes — **you should run Module 2 again using `BASELINE_STRATEGY`** if you want the baseline run recorded in:

```sql
credit_decisioning_sim.strategy_run_evidence_summary
```

Right now, Section 16 captured the latest run:

```text
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
+
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0
```

The Module 2 archive may already contain the baseline strategy, but **Section 16 only captures executive evidence for the current latest-run table**:

```sql
credit_decisioning_sim.strategy_decisions
```

So if the current latest-run table is the tighter synthetic-risk strategy, Section 16 captures the tighter strategy. It does not automatically backfill the baseline strategy’s executive evidence row from the archive.

## Recommended action

Yes, rerun Module 2 with:

```text
Module 1 input source:
ARCHIVE

source_module1_scenario_set_name:
MODULE1_V2_BASELINE_SET

source_module1_scenario_name:
BASELINE_V2

source_population_id:
BASE_POPULATION_V1

Module 2 strategy:
BASELINE_STRATEGY

strategy_set_name:
MODULE2_BASELINE_STRATEGY_SET

strategy_version:
V1_0

archive_run_flag:
TRUE

strategy_archive_reset_mode:
STRATEGY_SCENARIO_ONLY
```

Then run:

```text
Sections 1–14
Sections 15–16
```

in the same session, or however you are now executing successfully.

## What will happen

The baseline run will:

```text
recreate latest-run strategy_decisions as BASELINE_STRATEGY
replace only the baseline archive slice for BASELINE_V2
preserve the tighter synthetic-risk archive slice
insert or replace one baseline row in strategy_run_evidence_summary
insert or replace the baseline validation evidence rows
insert or replace the baseline parameter snapshot
insert or replace the baseline product × score segment evidence rows
```

It should **not** delete the tighter synthetic-risk evidence row, because Section 16 deletes/replaces evidence only for the current run key:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
```

Since `BASELINE_STRATEGY` and `TIGHTER_SYNTHETIC_RISK_STRATEGY` have different `strategy_name` values, both evidence rows can coexist.

## Do you need to rerun the tighter strategy afterward?

Not unless you want the latest-run table to end on the tighter strategy.

For evidence purposes, once both rows exist in:

```sql
credit_decisioning_sim.strategy_run_evidence_summary
```

you are good.

If you later change Section 16’s schema or add more evidence fields, then you should rerun both baseline and tighter so both evidence rows are captured under the same final evidence design.

## Quick confirmation query after rerunning baseline

Run this after the baseline Section 16 capture:

```sql
SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    applications,
    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,
    total_approved_amount,
    total_approved_expected_loss_amount,
    approved_expected_loss_rate,
    top_primary_reason_code,
    top_non_approval_primary_reason_code,
    top_policy_stop_primary_reason_code,
    frontier_position_type,
    executive_frontier_quadrant,
    evidence_snapshot_ts
FROM credit_decisioning_sim.strategy_run_evidence_summary
WHERE module1_scenario_set_name = 'MODULE1_V2_BASELINE_SET'
  AND module1_scenario_name = 'BASELINE_V2'
  AND population_id = 'BASE_POPULATION_V1'
  AND strategy_set_name = 'MODULE2_BASELINE_STRATEGY_SET'
  AND strategy_version = 'V1_0'
  AND strategy_name IN (
      'BASELINE_STRATEGY',
      'TIGHTER_SYNTHETIC_RISK_STRATEGY'
  )
ORDER BY
    CASE
        WHEN strategy_name = 'BASELINE_STRATEGY' THEN 1
        WHEN strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY' THEN 2
        ELSE 99
    END;
```

Expected result:

```text
2 rows:
1. BASELINE_STRATEGY
2. TIGHTER_SYNTHETIC_RISK_STRATEGY
```

## Bottom line

Yes, rerun the baseline strategy so Section 16 captures the baseline executive evidence row. That gives you a clean paired evidence record:

```text
Baseline strategy evidence row
Tighter synthetic-risk strategy evidence row
```

That pair becomes the foundation for your first executive strategy frontier story.
<!-- END_MESSAGE C038-M00617 -->


---

<a id="c038-m00618"></a>

### C038-M00618

**Andrew** · 2026-05-09T09:14:28.966000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00618 -->
in our mapping tables that guide module 1 and 2 runs we had id's that spoke to the run's and strategy groupings.  I know we have set names, scenario names, etc but to tie to our validation summary it might be nice to have those id's also incorporated.  I don't really want to go back and change anything in module 1.  is there a way to do this in module 2 solely?  do you think this would be valuable?  I just want to make sure the connection from code output to validation summary is clear.
<!-- END_MESSAGE C038-M00618 -->


---

<a id="c038-m00620"></a>

### C038-M00620

**ChatGPT** · 2026-05-09T09:16:07.419733-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00620 -->
Yes — this is valuable, and you can do it **entirely inside Module 2** without changing Module 1.

Module 1 should remain as-is. Its authoritative lineage fields are already sufficient:

```text
scenario_set_name / module1_scenario_set_name
scenario_name / module1_scenario_name
population_id
application_id
```

Module 1’s BRD explicitly frames those scenario fields and `population_id` as the mechanism for scenario grouping, matched comparison, and audit traceability. fileciteturn10file4 The Module 1 Validation Summary also emphasizes that matched scenario comparison works because archived scenarios retain 50,000 rows, share the same `population_id`, and preserve matched borrower-level attributes. fileciteturn10file5

What you are describing is slightly different: not source lineage, but **campaign / validation evidence labeling**.

That belongs naturally in Module 2.

## Recommendation

Add a **Module 2 run campaign registry** and use it to populate the Section 16 evidence tables.

This gives you clean IDs like:

```text
M1-01
M1-02
M2-01
M2-02
SC01
CG01
VE01
```

without touching Module 1.

## Why this is useful

Right now, you can tie everything together using names:

```text
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0
```

That is technically correct, but for the Validation Summary and README, IDs make the narrative easier:

```text
M1-01 + M2-02
Baseline Module 1 scenario with tighter synthetic-risk Module 2 strategy
```

Then your validation artifact can say:

```text
Run M2-02 reduced simulated offer exposure by 2.51 percentage points
and approved Expected Loss by $7.26M relative to M2-01.
```

That is cleaner than repeatedly writing the full scenario / strategy names.

## Best design

Do **not** add these IDs to Module 1.

Do **not** reinterpret them as source lineage.

Add them as **Module 2 evidence and campaign metadata**.

### New persistent table

Recommended table:

```sql
credit_decisioning_sim.strategy_run_campaign_registry
```

Recommended grain:

```text
one row per planned Module 1 scenario × Module 2 strategy run
```

Recommended key fields:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
validation_evidence_group_id
run_sequence_number

module1_scenario_set_name
module1_scenario_name
population_id

strategy_set_name
strategy_name
strategy_version
```

Recommended narrative fields:

```text
showcase_name
module1_parameter_family_changed
module1_parameter_change_summary
module2_strategy_family_changed
module2_parameter_change_summary
expected_storyline
validation_summary_section_hint
readme_storyline_label
linkedin_post_sequence
```

## How it would work

Section 16 already has fields like:

```text
module1_run_id
module2_run_id
showcase_name
module1_parameter_family_changed
module2_strategy_family_changed
expected_storyline
observed_storyline
validation_notes
```

But right now those are mostly derived from scenario / strategy names.

The patch should make Section 16 do this instead:

```text
current latest-run key
→ join to strategy_run_campaign_registry
→ pull M1/M2/showcase/comparison IDs
→ store them in evidence summary, validation evidence, parameter snapshot, and segment evidence
```

That makes Section 16 the bridge between:

```text
SQL run output
archive evidence
validation summary narrative
README / LinkedIn story
```

## Recommended fields to add / use

### Main executive evidence table

Add or populate:

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
```

### Validation evidence detail table

Add:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
validation_evidence_group_id
```

This lets you filter validation rows directly by run ID.

### Parameter snapshot table

Add:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
```

This makes parameter evidence easy to connect to run IDs.

### Segment evidence table

Add:

```text
module1_run_id
module2_run_id
showcase_id
comparison_group_id
```

This makes product × score evidence exportable by run ID.

## Registry match behavior

I recommend a governed but practical approach:

For formal campaign runs:

```text
registry match required
```

For ad hoc development runs:

```text
fallback allowed, but flagged
```

Suggested fields in evidence summary:

```text
run_registry_match_status
```

Values:

```text
RUN_REGISTRY_MATCHED
RUN_REGISTRY_NOT_FOUND_FALLBACK_USED
RUN_REGISTRY_DUPLICATE_MATCH_REVIEW_REQUIRED
```

For your upcoming scenario / strategy campaign, I would make missing registry rows a **REVIEW or fail-fast condition**, because you want every run tied to a validation narrative.

## Why this is better than modifying Module 1

Module 1 should preserve its original design boundary: synthetic application and risk scenario generation. The run IDs you are discussing are not required to generate Module 1 outputs. They are campaign-management labels.

Module 2 Section 16 is the better place because it already captures:

```text
executive evidence
validation evidence
parameter snapshots
frontier story
segment drivers
Module 3 readiness fields
```

That is exactly where validation-summary linking belongs.

## Recommended next patch

Add a targeted Section 16 patch:

```text
SECTION 16.0B — STRATEGY RUN CAMPAIGN REGISTRY
```

Then update:

```text
tmp_m2_current_run_story_params
```

so it pulls from the registry instead of deriving weak default IDs.

The patch should not change:

```text
decision logic
strategy archive logic
reason-code logic
approved exposure
approved Expected Loss
Module 1 outputs
```

It only strengthens evidence traceability.

## Bottom line

Yes, this is valuable.

The clean design is:

```text
Module 1 remains unchanged.
Module 2 creates a campaign registry.
Section 16 joins the current run to that registry.
Evidence tables store M1/M2/showcase/comparison IDs.
Validation Summary references those IDs.
```

That will make the final Validation Summary much cleaner and more professional because every claim can point back to a stable run ID, not just a long scenario / strategy name.
<!-- END_MESSAGE C038-M00620 -->


---

<a id="c038-m00622"></a>

### C038-M00622

**Andrew** · 2026-05-09T09:21:41.572000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00622 -->
let's discuss implementation of creating the module 2 campaign registry, joining section 16 to that registry, ensuring evidence tables store M1/M2/showcase/comparison ids, and validation summary references those ids. if this is a section by section change, it might make sense to do these updates in parallel to our elite teaching/instructional commentary/heading hardening pass.
<!-- END_MESSAGE C038-M00622 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_23.md) · [Next](Part_25.md)
