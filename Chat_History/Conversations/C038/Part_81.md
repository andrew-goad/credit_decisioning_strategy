# Module 2 Decision Simulator Build

## Part 81

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_80.md) · [Next](Part_82.md)

<a id="c038-m01579"></a>

### C038-M01579

**ChatGPT** · 2026-05-12T11:21:23.140128-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01579 -->
According to a document from 2026-05-12, Section 11 is the latest-run output materialization layer: it consumes `tmp_m2_stage_7_reason_code_assignment`, creates `credit_decisioning_sim.strategy_decisions`, uses explicit field selection instead of `SELECT *`, creates practical indexes, and runs local latest-run integrity checks before Section 12 archive persistence. fileciteturn245file8turn245file15turn244file16

```sql
/***************************************************************************************************
SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Materialize the completed Module 2 latest-run strategy output table.

    Section 11 answers:

        "What is the current final simulated strategy output for the selected Module 1 source
         population / scenario and active Module 2 strategy?"

    Section 11 does not answer:

        "What historical strategy runs exist?"
        "How does this run compare to an archived baseline?"
        "Has the latest-run output passed the full validation framework?"
        "Has executive evidence been captured?"

    This section is the permanent latest-run output materialization layer.

    Section 10 created the final temporary reason-code assignment stage.
    Section 11 turns that completed staging layer into the governed current-run output surface.

SQL PURPOSE:
    1. Confirm required Section 11 dependencies exist.
    2. Consume tmp_m2_stage_7_reason_code_assignment.
    3. Create credit_decisioning_sim.strategy_decisions as the replaceable latest-run output.
    4. Use an explicit SELECT list rather than SELECT *.
    5. Preserve Module 2 strategy metadata and archive controls.
    6. Preserve Module 1 lineage.
    7. Preserve application, borrower, product, requested-structure, affordability, synthetic
       estimated-risk proxy, LGD, and requested Expected Loss fields.
    8. Preserve strategy segmentation, rule-trigger, preliminary routing, exposure-treatment,
       counteroffer feasibility, final decision, final exposure, and simulated reason-code fields.
    9. Add latest_output_created_ts as latest-run audit metadata.
    10. Create practical latest-run indexes.
    11. Validate latest-run output integrity through local gatekeepers.
    12. Provide lightweight latest-run diagnostics before archive persistence.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the latest-run output contains the final simulated decision, offer-exposure,
        approved exposure, approved affordability, approved Expected Loss, and explanation fields
        needed for strategy interpretation.

    Model governance / validation reviewers:
        Confirm that the permanent latest-run output is complete, uniquely keyed at application_id,
        and bounded as a synthetic simulation output rather than an operational underwriting output.

    SQL reviewers:
        Confirm that permanent output materialization uses an explicit field list, preserves intended
        columns, avoids SELECT * schema drift, and validates output integrity before archive
        persistence.

    Portfolio / executive reviewers:
        Use Section 11 diagnostics as the first compact view of the completed current run before
        reviewing Section 14 QA, Section 15 frontier output, and Section 16 evidence capture.

WHEN TO RUN THIS SECTION:
    Run Section 11 after:

        Section 10 — Simulated Reason-Code Assignment Layer

    Section 11 should be run before:

        Section 12 — Strategy Decision Archive Persistence Layer
        Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics
        Section 15 — Strategy Frontier Summary and Executive Comparison View
        Section 16 — Strategy Run Evidence Capture and Executive Story Register

    Section 11 depends on:

        tmp_m2_stage_7_reason_code_assignment
        tmp_module2_strategy_params

HOW TO INTERPRET THIS SECTION:
    Passing Section 11 means:
        credit_decisioning_sim.strategy_decisions exists,
        the latest-run output row count matches Section 10 staging,
        application_id remains unique,
        the latest-run table contains exactly one Module 2 strategy slice,
        the latest-run table contains exactly one Module 1 scenario / population slice,
        final decision fields are complete,
        final decision flags reconcile,
        simulated offer-exposure convention holds,
        approved exposure conventions hold,
        approved Expected Loss conventions hold,
        simulated reason-code fields are complete,
        latest-run audit timestamp is populated,
        and practical indexes are available.

    Passing Section 11 does not mean:
        archive persistence has occurred,
        matched comparison has been performed,
        full latest-run validation has passed,
        strategy frontier evidence is complete,
        executive evidence has been captured,
        or documentation is ready to draft.

WHY LATEST-RUN OUTPUT IS SEPARATED FROM STAGING TABLES:
    Temporary staging tables explain the full transformation path.

    credit_decisioning_sim.strategy_decisions is the governed latest-run output designed for:
        downstream QA,
        archive persistence,
        reporting,
        review,
        documentation,
        and future validation.

WHY LATEST-RUN OUTPUT IS REPLACED EACH RUN:
    The latest-run output table represents the current completed Module 2 strategy result only.

    Prior completed outputs are preserved through:

        credit_decisioning_sim.strategy_decisions_archive

    not through accumulation in the latest-run table.

WHY ARCHIVE PERSISTENCE IS DEFERRED:
    Section 11 creates the latest-run output.

    Section 12 controls:
        archive persistence,
        archive replacement behavior,
        archive skip behavior,
        archive reset behavior,
        archive grain checks,
        and archive persistence fidelity.

WHY EXPLICIT OUTPUT-FIELD SELECTION IS USED:
    The final output schema should be governed, reviewable, and stable.

    Temporary staging tables may carry many diagnostics, but the permanent latest-run table should
    intentionally expose the fields needed for review, validation, archive persistence, comparison,
    frontier analysis, and evidence capture.

    Explicit field selection prevents accidental downstream schema drift if an upstream temporary
    stage later gains a development-only helper field.

WHY CAMPAIGN IDS ARE NOT ADDED TO EVERY LATEST-RUN ROW:
    Campaign IDs such as:
        module1_run_id,
        module2_run_id,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id,
        readme_storyline_label,
        linkedin_post_sequence,
        validation_summary_section_hint

    are run-level evidence-linkage metadata.

    They are persisted later in Section 16 evidence tables.

    Section 11 preserves technical lineage and applicant-level strategy output fields.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is the requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount is the approved-exposure Expected Loss calculated by Module 2 after
    final simulated exposure treatment.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In interpretation, estimated_pd means the synthetic estimated-PD proxy.

    Module 2 does not recalculate estimated_pd.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies simulated positive offer exposure for APPROVE and
    COUNTEROFFER outcomes.

    It does not imply:
        operational account creation,
        booked exposure,
        funded exposure,
        production approval,
        customer treatment,
        or real applicant treatment.

SIMULATED REASON-CODE BOUNDARY:
    Reason-code fields are simulated strategy explanation codes only.

    They support:
        strategy transparency,
        QA review,
        decision-path traceability,
        matched comparison,
        executive evidence capture,
        validation documentation,
        README interpretation,
        and LinkedIn campaign storytelling.

    They are not:
        customer communications,
        regulatory notices,
        adverse-action notices,
        production compliance determinations,
        fair-lending conclusions,
        or real applicant treatment explanations.

LATEST_OUTPUT_CREATED_TS BOUNDARY:
    latest_output_created_ts records when the latest-run table was materialized.

    It is audit metadata.

    It is not deterministic comparison evidence.

    Matched strategy comparison should exclude timestamp fields unless specifically validating run
    metadata.

SECTION 11 QA BOUNDARY:
    Section 11 local checks validate latest-run output integrity only.

    They are not the full Module 2 QA framework.

    The full validation and QA framework is built in Section 14.

READ / WRITE BOUNDARY:
    Section 11 drops and recreates only:

        credit_decisioning_sim.strategy_decisions

    Section 11 does not insert archive rows.
    Section 11 does not delete archive rows.
    Section 11 does not update archive rows.
    Section 11 does not modify campaign registry rows.
    Section 11 does not modify comparison registry rows.
    Section 11 does not insert evidence rows.
    Section 11 does not modify strategy parameters.
    Section 11 does not modify product-policy parameters.

GOVERNANCE ROLE:
    Section 11 creates the stable latest-run output surface consumed by:
        Section 12 archive persistence,
        Section 14 latest-run validation,
        Section 15 strategy frontier summary,
        and Section 16 evidence capture.

COMMON MISUSE TO AVOID:
    Do not treat credit_decisioning_sim.strategy_decisions as historical archive.
    Do not compare multiple completed strategies from the latest-run table.
    Do not interpret latest_output_created_ts as a business outcome.
    Do not interpret simulated_offer_exposure_flag as real operational exposure.
    Do not interpret simulated reason codes as external communication text.
    Do not skip Section 12 if the run should become part of governed campaign history.
    Do not skip Section 14 if the run will support validation or executive documentation.

***************************************************************************************************/



/***************************************************************************************************
SECTION 11.0 — SECTION 11 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 10 reason-code assignment output exists, is populated, and is ready to be
    materialized into the latest-run output table.

    Section 11.0 answers:

        "Can Section 11 safely create the permanent latest-run output from the completed Section 10
         reason-code staging layer?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_7_reason_code_assignment exists.
    2. Confirm tmp_m2_stage_7_reason_code_assignment contains rows.
    3. Confirm application_id is unique in Section 10 staging.
    4. Confirm tmp_module2_strategy_params exists.
    5. Confirm exactly one active strategy parameter row exists.
    6. Confirm archive controls are populated and valid.
    7. Confirm required latest-run output fields are available and populated.
    8. Fail clearly if Section 10 or Section 2 has not been run.

BOUNDARY:
    Section 11.0 does not create latest-run output.
    Section 11.0 does not insert archive rows.
    Section 11.0 does not modify evidence tables.
    Section 11.0 does not modify registry tables.

***************************************************************************************************/

DO $$
DECLARE
    v_stage7_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;

    v_stage7_row_count BIGINT;
    v_stage7_distinct_application_count BIGINT;

    v_active_strategy_count BIGINT;
    v_bad_archive_control_count BIGINT;
    v_required_stage7_gap_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 10 reason-code assignment stage must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

    Business interpretation:
        Section 11 must consume the completed reason-code assignment layer, not the Section 9 final
        decision layer. The latest-run output should not be materialized until simulated explanation
        codes are complete.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_7_reason_code_assignment'),
        TO_REGCLASS('tmp_m2_stage_7_reason_code_assignment')
    ) IS NOT NULL
    INTO v_stage7_exists;

    IF v_stage7_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: tmp_m2_stage_7_reason_code_assignment is required. Run Section 10 before Section 11.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: active strategy parameter table must exist.

    Business interpretation:
        Section 11 needs archive controls from the active strategy parameter card so Section 12 can
        later validate archive behavior from the latest-run output itself.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_strategy_params'),
        TO_REGCLASS('tmp_module2_strategy_params')
    ) IS NOT NULL
    INTO v_strategy_params_exists;

    IF v_strategy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: tmp_module2_strategy_params is required. Run Section 2 before Section 11.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 10 staging must contain rows.

    Business interpretation:
        Materializing an empty latest-run output is not useful and usually indicates an upstream
        source, routing, or reason-code assignment issue.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage7_row_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    IF v_stage7_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: tmp_m2_stage_7_reason_code_assignment contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id must be unique before latest-run materialization.

    Section 11 should materialize one row per application_id.

    It should not repair upstream row-grain problems.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage7_distinct_application_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    IF v_stage7_distinct_application_count <> v_stage7_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: tmp_m2_stage_7_reason_code_assignment is not unique at application_id. Rows=%, distinct application_id=%.',
            v_stage7_row_count,
            v_stage7_distinct_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active strategy parameter row.

    Business interpretation:
        Section 11 must attach one archive-control posture to every applicant row.

        More than one active strategy row would duplicate applicant rows when archive controls are
        cross-joined.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls must be populated and valid.

    Allowed strategy_archive_reset_mode values:
        NONE
        STRATEGY_SCENARIO_ONLY
        STRATEGY_SET_ONLY
        ALL
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_bad_archive_control_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
      AND (
            archive_run_flag IS NULL
         OR strategy_archive_reset_mode IS NULL
         OR strategy_archive_reset_mode NOT IN (
                'NONE',
                'STRATEGY_SCENARIO_ONLY',
                'STRATEGY_SET_ONLY',
                'ALL'
            )
      );

    IF v_bad_archive_control_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: active archive controls are missing or invalid.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required Section 10 staging fields must be populated.

    Business interpretation:
        The latest-run output should not be materialized if core identity, lineage, requested-risk,
        final decision, final flag, final exposure, or reason-code fields are missing.

    Important:
        MANUAL_REVIEW rows are unresolved by design, so approved_amount and approved_expected_loss are
        allowed to be NULL for MANUAL_REVIEW.

        APPROVE, COUNTEROFFER, and DECLINE rows must have final approved exposure and approved
        Expected Loss populated according to their conventions.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_stage7_gap_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE module2_model_version IS NULL
       OR NULLIF(BTRIM(module2_model_version), '') IS NULL
       OR strategy_set_name IS NULL
       OR NULLIF(BTRIM(strategy_set_name), '') IS NULL
       OR strategy_name IS NULL
       OR NULLIF(BTRIM(strategy_name), '') IS NULL
       OR strategy_version IS NULL
       OR NULLIF(BTRIM(strategy_version), '') IS NULL
       OR strategy_run_id IS NULL
       OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
       OR strategy_run_ts IS NULL

       OR module1_model_version IS NULL
       OR NULLIF(BTRIM(module1_model_version), '') IS NULL
       OR module1_scenario_set_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
       OR module1_scenario_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
       OR population_id IS NULL
       OR NULLIF(BTRIM(population_id), '') IS NULL

       OR application_id IS NULL
       OR NULLIF(BTRIM(application_id), '') IS NULL
       OR applicant_id IS NULL
       OR NULLIF(BTRIM(applicant_id), '') IS NULL

       OR product_type_policy_key IS NULL
       OR NULLIF(BTRIM(product_type_policy_key), '') IS NULL
       OR score_band_policy_key IS NULL
       OR NULLIF(BTRIM(score_band_policy_key), '') IS NULL

       OR requested_amount IS NULL
       OR requested_expected_loss_amount IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL

       OR decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL

       OR approval_flag IS NULL
       OR counteroffer_flag IS NULL
       OR manual_review_flag IS NULL
       OR decline_flag IS NULL
       OR simulated_offer_exposure_flag IS NULL

       OR primary_reason_code IS NULL
       OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
       OR primary_reason_family IS NULL
       OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
       OR triggered_reason_code_list IS NULL
       OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
       OR reason_priority_rank IS NULL
       OR reason_code_count IS NULL

       OR (
            decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
            AND approved_amount IS NULL
       )

       OR (
            decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
            AND approved_expected_loss_amount IS NULL
       );

    IF v_required_stage7_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % Section 10 staging row(s) are missing required latest-run output fields.',
            v_required_stage7_gap_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 11.1 — CLEAN RESET OF LATEST-RUN OUTPUT TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the replaceable latest-run output table before rebuilding it from completed Section 10
    staging output.

SQL PURPOSE:
    Remove only:

        credit_decisioning_sim.strategy_decisions

WHY THIS MATTERS:
    The latest-run table is intentionally current-run only.

    Dropping it prevents a partial or prior latest-run output from being mixed with the current
    completed strategy run.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the latest-run table does not exist, PostgreSQL does not error.

BOUNDARY:
    This does not drop:
        credit_decisioning_sim.strategy_decisions_archive
        credit_decisioning_sim.strategy_run_campaign_registry
        credit_decisioning_sim.strategy_comparison_campaign_registry
        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

****************************************************************************************************/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 11.2 — CREATE LATEST-RUN STRATEGY DECISION OUTPUT TABLE
****************************************************************************************************

TABLE:
    credit_decisioning_sim.strategy_decisions

GRAIN:
    One row per application_id for the selected Module 1 source scenario / population and active
    Module 2 strategy.

INPUT:
    tmp_m2_stage_7_reason_code_assignment

OUTPUT:
    Permanent latest-run table with final simulated strategy output and diagnostic trace fields.

IMPORTANT:
    This table does not preserve prior runs.

    Prior completed runs are preserved through Section 12 archive persistence.

SQL DESIGN:
    This section uses:

        CREATE TABLE ... AS
        WITH active_archive_controls AS (...)
        SELECT explicit_field_list
        FROM tmp_m2_stage_7_reason_code_assignment
        CROSS JOIN active_archive_controls

    The active archive-control CTE is one row because Section 11.0 validated active strategy
    parameter cardinality.

WHY CROSS JOIN IS APPROPRIATE:
    active_archive_controls contains exactly one active strategy control row.

    CROSS JOIN attaches that one archive-control setting to every applicant row in the latest-run
    output.

    If active_archive_controls had more than one row, CROSS JOIN would duplicate applicants.
    Section 11.0 prevents that.

WHY CAMPAIGN IDS ARE NOT SELECTED HERE:
    Campaign registry IDs are run-level evidence metadata.

    They are persisted later in Section 16 evidence tables.

    The latest-run applicant table keeps technical lineage and applicant-level strategy output fields.

***************************************************************************************************/

CREATE TABLE credit_decisioning_sim.strategy_decisions AS
WITH active_archive_controls AS (
    /***********************************************************************************************
    CTE: active_archive_controls

    Purpose:
        Select the active archive persistence controls from the current strategy parameter card.

    SQL mechanics:
        Section 11.0 already validated exactly one active strategy parameter row.

        LIMIT 1 is therefore safe.

    Boundary:
        These controls are carried into the latest-run output so Section 12 can validate archive
        behavior from the completed current-run table.
    ***********************************************************************************************/
    SELECT
        archive_run_flag,
        strategy_archive_reset_mode
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
)

SELECT
    /***********************************************************************************************
    1. Module 2 strategy metadata.

    These fields identify the downstream simulated strategy applied to the selected Module 1
    population.

    strategy_run_id and strategy_run_ts are audit metadata.

    They support run traceability, but they do not replace the archive replacement / rerun key.
    ***********************************************************************************************/
    r.module2_model_version,
    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version,
    r.strategy_run_id,
    r.strategy_run_ts,
    r.failed_counteroffer_resolution,


    /***********************************************************************************************
    2. Archive controls.

    These are carried from the active strategy parameter card.

    Section 12 uses these fields to govern archive persistence and archive replacement behavior.

    They are not part of applicant grain.
    They are not matched-comparison keys.
    ***********************************************************************************************/
    aac.archive_run_flag,
    aac.strategy_archive_reset_mode,


    /***********************************************************************************************
    3. Module 1 source mode and lineage.

    These fields preserve upstream synthetic population and scenario identity.

    They describe where the applicant population came from, not what Module 2 strategy was applied.
    ***********************************************************************************************/
    r.module1_input_source,
    r.module1_source_table_name,

    r.module1_model_version,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.anchor_date,


    /***********************************************************************************************
    4. Application lineage.

    Section 11 remains one row per application_id.

    application_id is the row-level key for latest-run QA and matched archive comparison.
    ***********************************************************************************************/
    r.application_seq,
    r.application_id,
    r.applicant_id,
    r.application_date,


    /***********************************************************************************************
    5. Product and score segmentation.

    product_type:
        Original Module 1 product value.

    product_type_policy_key:
        Normalized product-policy key used throughout Module 2.

    score_band:
        Original Module 1 score-band value.

    score_band_policy_key:
        Normalized score-band key used for segment evidence and strategy QA.
    ***********************************************************************************************/
    r.product_type,
    r.product_type_policy_key,
    r.score_band,
    r.score_band_policy_key,
    r.credit_score,
    r.product_score_policy_segment,

    r.product_policy_match_count,
    r.product_policy_config_found_flag,
    r.product_policy_profile_code,


    /***********************************************************************************************
    6. Borrower and behavioral profile.

    prequalified_flag and returning_customer_flag may remain NULL when Module 1 does not provide
    them.

    These are source-profile fields, not final decision fields.
    ***********************************************************************************************/
    r.annual_income,
    r.debt_to_income_ratio,
    r.utilization_rate,
    r.tradeline_count,
    r.months_since_oldest_trade,
    r.recent_inquiry_count,
    r.delinquency_count_12m,
    r.major_derogatory_flag,
    r.bankruptcy_flag,
    r.prequalified_flag,
    r.returning_customer_flag,


    /***********************************************************************************************
    7. Requested structure and requested-exposure economics.

    requested_expected_loss_amount:
        Module 2 alias for Module 1 requested-exposure Expected Loss.

    estimated_pd:
        Finalized Module 1 SQL field name; interpreted as synthetic estimated-PD proxy.

    expected_loss_amount:
        Original Module 1 field retained for traceability.

    monthly_payment_proxy and payment_to_income_ratio:
        Original Module 1 names retained for traceability.

    requested_monthly_payment_proxy and requested_payment_to_income_ratio:
        Module 2 requested-structure aliases used to distinguish requested versus approved terms.
    ***********************************************************************************************/
    r.requested_amount,
    r.loan_term_months,
    r.base_apr_for_payment_calc,

    r.monthly_payment_proxy,
    r.payment_to_income_ratio,
    r.amount_to_income_ratio,

    r.requested_monthly_payment_proxy,
    r.requested_payment_to_income_ratio,

    r.estimated_pd,
    r.estimated_lgd,
    r.expected_loss_amount,
    r.requested_expected_loss_amount,


    /***********************************************************************************************
    8. Global strategy thresholds and product-policy controls.

    These fields make the latest-run output auditable without forcing reviewers to reverse-engineer
    the active temporary parameter tables.

    They are copied as run evidence context.

    They do not make Section 11 a parameter-definition section.
    ***********************************************************************************************/
    r.approve_max_estimated_pd_proxy,
    r.counteroffer_max_estimated_pd_proxy,
    r.review_max_estimated_pd_proxy,
    r.decline_min_estimated_pd_proxy,

    r.global_approve_max_pti,
    r.global_review_max_pti,
    r.global_decline_min_pti,

    r.approve_max_dti,
    r.review_max_dti,
    r.decline_min_dti,

    r.borderline_threshold_buffer_pct,

    r.bankruptcy_policy_stop_enabled,
    r.major_derogatory_policy_stop_enabled,
    r.severe_delinquency_policy_stop_enabled,
    r.severe_delinquency_count_threshold,

    r.high_utilization_review_enabled,
    r.high_utilization_review_threshold,

    r.low_score_review_enabled,
    r.low_score_review_threshold,

    r.product_approve_max_pti,
    r.product_review_max_pti,
    r.product_decline_min_pti,
    r.counteroffer_target_pti,

    r.product_approve_max_requested_el,
    r.product_review_max_requested_el,
    r.product_decline_min_requested_el,
    r.product_approved_el_cap,
    r.requested_el_low_moderate_split,

    r.product_min_approved_amount,
    r.product_max_approved_amount,

    r.counteroffer_allowed_flag,
    r.manual_review_allowed_flag,
    r.product_min_counteroffer_pct,
    r.product_max_exposure_reduction_pct,
    r.exposure_assignment_method,
    r.approved_amount_rounding_increment,


    /***********************************************************************************************
    9. Strategy segmentation diagnostics.

    These fields describe the synthetic applicant before rule hierarchy and final outcome resolution.

    They support downstream QA, product × score evidence, frontier interpretation, and executive
    narrative.
    ***********************************************************************************************/
    r.strategy_risk_tier,
    r.requested_pti_bucket,
    r.dti_bucket,
    r.requested_exposure_tier,
    r.requested_expected_loss_tier,

    r.strong_credit_high_pti_condition,
    r.weak_credit_low_pti_condition,
    r.large_exposure_low_risk_condition,
    r.high_risk_low_exposure_condition,
    r.high_dti_low_requested_pti_condition,

    r.mixed_signal_profile_type,
    r.mixed_signal_condition_count,
    r.borderline_profile_flag,


    /***********************************************************************************************
    10. Rule-trigger diagnostics.

    These fields preserve the trigger evidence behind preliminary routing and simulated reason-code
    assignment.

    These are not customer-facing reasons.
    ***********************************************************************************************/
    r.bankruptcy_policy_stop_flag,
    r.major_derogatory_policy_stop_flag,
    r.severe_delinquency_policy_stop_flag,
    r.hard_policy_stop_flag,
    r.hard_policy_stop_count,

    r.synthetic_risk_clean_approval_band_flag,
    r.synthetic_risk_counteroffer_band_flag,
    r.synthetic_risk_review_band_flag,
    r.synthetic_risk_decline_trigger_flag,
    r.synthetic_risk_band_flag_count,
    r.synthetic_risk_trigger_count,

    r.requested_pti_clean_band_flag,
    r.requested_pti_counteroffer_candidate_flag,
    r.requested_pti_review_trigger_flag,
    r.requested_pti_decline_trigger_flag,
    r.affordability_trigger_count,

    r.dti_clean_band_flag,
    r.dti_review_trigger_flag,
    r.dti_decline_trigger_flag,
    r.dti_band_flag_count,
    r.dti_trigger_count,

    r.requested_el_clean_band_flag,
    r.requested_el_counteroffer_candidate_flag,
    r.requested_el_review_trigger_flag,
    r.requested_el_decline_trigger_flag,
    r.requested_el_trigger_count,

    r.requested_exposure_below_product_minimum_flag,
    r.requested_exposure_within_product_limit_flag,
    r.requested_exposure_above_product_cap_flag,
    r.requested_exposure_extreme_flag,
    r.exposure_counteroffer_candidate_flag,
    r.exposure_policy_stop_candidate_flag,
    r.exposure_trigger_count,

    r.counteroffer_allowed_by_product_flag,
    r.counteroffer_risk_band_eligible_flag,
    r.counteroffer_affordability_candidate_flag,
    r.counteroffer_exposure_candidate_flag,
    r.counteroffer_expected_loss_candidate_flag,
    r.counteroffer_candidate_flag,
    r.counteroffer_candidate_trigger_count,

    r.high_utilization_review_trigger_flag,
    r.low_score_review_trigger_flag,
    r.supplemental_behavioral_review_trigger_flag,
    r.supplemental_behavioral_review_trigger_count,

    r.manual_review_allowed_by_product_flag,
    r.manual_review_risk_trigger_flag,
    r.manual_review_affordability_trigger_flag,
    r.manual_review_dti_trigger_flag,
    r.manual_review_expected_loss_trigger_flag,
    r.manual_review_mixed_signal_trigger_flag,
    r.manual_review_borderline_trigger_flag,
    r.manual_review_candidate_flag,
    r.manual_review_candidate_trigger_count,

    r.clean_approval_candidate_flag,
    r.total_rule_trigger_count,


    /***********************************************************************************************
    11. Preliminary routing fields.

    These fields show how overlapping rule triggers were converted into one preliminary route before
    exposure treatment and final resolution.
    ***********************************************************************************************/
    r.severe_requested_structure_trigger_flag,
    r.severe_requested_structure_trigger_count,

    r.preliminary_decision_outcome,
    r.preliminary_decision_path,
    r.preliminary_decision_priority_rank,
    r.preliminary_route_reason_family,
    r.preliminary_route_trigger_count,

    r.preliminary_decline_flag,
    r.preliminary_counteroffer_flag,
    r.preliminary_manual_review_flag,
    r.preliminary_approve_flag,

    r.requires_counteroffer_feasibility_flag,
    r.requires_approved_exposure_calculation_flag,


    /***********************************************************************************************
    12. Exposure treatment and counteroffer feasibility diagnostics.

    These fields support traceability from preliminary routing through final decision resolution.

    counteroffer_feasibility_failure_reason is diagnostic only.
    It is not a simulated final reason code and not customer communication language.
    ***********************************************************************************************/
    r.exposure_treatment_status,
    r.exposure_treatment_path,

    r.approved_amount_preliminary,
    r.counteroffer_amount_preliminary,
    r.exposure_reduction_flag_preliminary,
    r.exposure_reduction_amount_preliminary,
    r.exposure_reduction_pct_preliminary,

    r.approved_monthly_payment_proxy_preliminary,
    r.approved_payment_to_income_ratio_preliminary,

    r.approved_expected_loss_amount_preliminary,
    r.approved_el_reduction_amount_preliminary,
    r.approved_el_reduction_pct_preliminary,

    r.counteroffer_feasibility_evaluated_flag,
    r.counteroffer_feasibility_pass_flag,
    r.counteroffer_feasibility_failure_reason,
    r.counteroffer_feasibility_constraint_count,

    r.counteroffer_product_cap_amount,
    r.counteroffer_pti_target_amount,
    r.counteroffer_el_cap_amount,
    r.counteroffer_raw_max_feasible_amount,
    r.counteroffer_min_viable_amount,
    r.counteroffer_rounded_amount,
    r.counteroffer_test_monthly_payment_proxy,
    r.counteroffer_test_payment_to_income_ratio,
    r.counteroffer_test_expected_loss_amount,


    /***********************************************************************************************
    13. Final decision outcome fields.

    These fields are the final simulated strategy outcome for the latest-run output.

    They are still synthetic strategy outputs, not real applicant decisions.
    ***********************************************************************************************/
    r.decision_outcome,
    r.decision_path,
    r.decision_priority_rank,
    r.decision_resolution_source,


    /***********************************************************************************************
    14. Final decision flags.

    Exactly one of approval_flag, counteroffer_flag, manual_review_flag, and decline_flag should be
    TRUE per row.

    simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.
    ***********************************************************************************************/
    r.approval_flag,
    r.counteroffer_flag,
    r.manual_review_flag,
    r.decline_flag,
    r.simulated_offer_exposure_flag,


    /***********************************************************************************************
    15. Final approved exposure and approved economics.

    APPROVE:
        approved_amount = requested_amount.

    COUNTEROFFER:
        approved_amount is positive and below requested_amount.

    MANUAL_REVIEW:
        approved fields remain NULL.

    DECLINE:
        approved fields follow the locked zero-exposure convention.
    ***********************************************************************************************/
    r.approved_amount,
    r.counteroffer_amount,
    r.exposure_reduction_flag,
    r.exposure_reduction_amount,
    r.exposure_reduction_pct,

    r.approved_monthly_payment_proxy,
    r.approved_payment_to_income_ratio,

    r.approved_expected_loss_amount,
    r.approved_el_reduction_amount,
    r.approved_el_reduction_pct,


    /***********************************************************************************************
    16. Simulated reason-code fields.

    These are simulated strategy explanation codes, not external communication text.
    ***********************************************************************************************/
    r.primary_reason_code,
    r.secondary_reason_code,
    r.tertiary_reason_code,
    r.primary_reason_family,
    r.triggered_reason_code_list,
    r.reason_priority_rank,
    r.reason_code_count,


    /***********************************************************************************************
    17. Latest-run audit timestamp.

    latest_output_created_ts is audit metadata.

    It should not be used as deterministic comparison evidence unless specifically validating run
    metadata.
    ***********************************************************************************************/
    CURRENT_TIMESTAMP AS latest_output_created_ts

FROM tmp_m2_stage_7_reason_code_assignment r

CROSS JOIN active_archive_controls aac;



/***************************************************************************************************
SECTION 11.3 — LATEST-RUN INDEXES
****************************************************************************************************

BUSINESS PURPOSE:
    Create practical indexes for latest-run QA, review, reporting, archive persistence, and matched
    comparison preparation.

SQL PURPOSE:
    Add indexes on common lookup and grouping fields without changing any latest-run rows.

INTERPRETATION:
    Indexes improve query performance and review ergonomics.

    They do not alter:
        row count,
        decision outcomes,
        approved exposure,
        approved Expected Loss,
        reason codes,
        archive state,
        evidence state,
        or registry state.

***************************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_application_id
    ON credit_decisioning_sim.strategy_decisions (application_id);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_strategy_identity
    ON credit_decisioning_sim.strategy_decisions (
        strategy_set_name,
        strategy_name,
        strategy_version
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_module1_lineage
    ON credit_decisioning_sim.strategy_decisions (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_replacement_key
    ON credit_decisioning_sim.strategy_decisions (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_decision_outcome
    ON credit_decisioning_sim.strategy_decisions (decision_outcome);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_product_decision
    ON credit_decisioning_sim.strategy_decisions (
        product_type_policy_key,
        decision_outcome
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_score_decision
    ON credit_decisioning_sim.strategy_decisions (
        score_band_policy_key,
        decision_outcome
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_product_score
    ON credit_decisioning_sim.strategy_decisions (
        product_type_policy_key,
        score_band_policy_key
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_primary_reason
    ON credit_decisioning_sim.strategy_decisions (primary_reason_code);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_offer_exposure
    ON credit_decisioning_sim.strategy_decisions (simulated_offer_exposure_flag);



/***************************************************************************************************
SECTION 11.4 — LOCAL FAIL-FAST CHECKS FOR LATEST-RUN OUTPUT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the permanent latest-run output table faithfully preserves the completed Section 10
    result and obeys the accepted Module 2 output conventions before archive persistence begins.

    Section 11.4 answers:

        "Is credit_decisioning_sim.strategy_decisions structurally sound and safe to hand to
         archive persistence, QA, frontier review, and evidence capture?"

SQL PURPOSE:
    1. Confirm credit_decisioning_sim.strategy_decisions exists.
    2. Confirm row count matches tmp_m2_stage_7_reason_code_assignment.
    3. Confirm application_id uniqueness.
    4. Confirm exactly one Module 2 strategy identity exists.
    5. Confirm exactly one Module 1 scenario / population identity exists.
    6. Confirm latest_output_created_ts is populated.
    7. Confirm strategy metadata and Module 1 lineage are populated.
    8. Confirm archive controls are populated and valid.
    9. Confirm final decision fields and final decision flags reconcile.
    10. Confirm simulated_offer_exposure_flag convention.
    11. Confirm approved amount and exposure conventions.
    12. Confirm requested / approved Expected Loss conventions.
    13. Confirm simulated reason-code completeness and family alignment.
    14. Confirm prohibited reason-code terminology controls.

LOCAL GATEKEEPER BOUNDARY:
    These are latest-run output gatekeepers only.

    They are not:
        archive validation,
        matched strategy comparison,
        full Module 2 QA,
        final Validation Summary evidence,
        executive frontier evidence,
        or campaign-run evidence capture.

SQL MECHANICS:
    This block uses PL/pgSQL because it needs multiple diagnostic counts and fail-fast exceptions.

***************************************************************************************************/

DO $$
DECLARE
    /***********************************************************************************************
    Row-grain diagnostics.
    ***********************************************************************************************/
    v_stage7_count BIGINT;
    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    /***********************************************************************************************
    Object and scope diagnostics.
    ***********************************************************************************************/
    v_output_table_exists BOOLEAN;
    v_strategy_scope_count BIGINT;
    v_module1_scope_count BIGINT;
    v_latest_output_created_ts_null_count BIGINT;

    /***********************************************************************************************
    Integrity diagnostics.
    ***********************************************************************************************/
    v_metadata_failure_count BIGINT;
    v_archive_control_failure_count BIGINT;
    v_decision_integrity_failure_count BIGINT;
    v_offer_flag_failure_count BIGINT;

    v_amount_integrity_failure_count BIGINT;
    v_expected_loss_integrity_failure_count BIGINT;
    v_reason_integrity_failure_count BIGINT;
    v_prohibited_reason_term_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must exist.

    SQL mechanics:
        TO_REGCLASS returns NULL if the table is absent.

    Failure interpretation:
        Section 11.2 did not materialize the output table or was not run.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO v_output_table_exists;

    IF v_output_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: credit_decisioning_sim.strategy_decisions does not exist.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run row count must match Section 10 staging.

    Business purpose:
        Confirm Section 11 materialized the completed reason-code staging layer without dropping,
        duplicating, or filtering rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage7_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    SELECT COUNT(*)
    INTO v_latest_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count <> v_stage7_count THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: latest-run row count (%) does not match Section 10 staging row count (%).',
            v_latest_count,
            v_stage7_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.

    Business purpose:
        The latest-run output should be applicant-grain for one selected strategy / scenario slice.

        Duplicate application_id values would duplicate archive rows, QA counts, comparison rows, and
        evidence metrics.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_distinct_app_count <> v_latest_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM credit_decisioning_sim.strategy_decisions
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 11 failure: application_id uniqueness failed in latest-run output. Rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_latest_count,
            v_latest_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one Module 2 strategy identity should exist in latest-run output.

    Business purpose:
        credit_decisioning_sim.strategy_decisions represents the current completed latest-run slice,
        not a multi-strategy archive.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version
    ))
    INTO v_strategy_scope_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_strategy_scope_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: latest-run output contains % Module 2 strategy identities. Expected exactly one.',
            v_strategy_scope_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one Module 1 scenario / population identity should exist.

    Business purpose:
        Module 2 V1.0 latest-run output is single-scenario / single-population at execution time.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    ))
    INTO v_module1_scope_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_module1_scope_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: latest-run output contains % Module 1 scenario / population identities. Expected exactly one.',
            v_module1_scope_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest_output_created_ts must be populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_output_created_ts_null_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE latest_output_created_ts IS NULL;

    IF v_latest_output_created_ts_null_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have null latest_output_created_ts.',
            v_latest_output_created_ts_null_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: strategy metadata and Module 1 lineage must be populated.

    Business purpose:
        The latest-run output must remain traceable to both:
            upstream Module 1 scenario / population;
            downstream Module 2 strategy.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_metadata_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE module2_model_version IS NULL
       OR NULLIF(BTRIM(module2_model_version), '') IS NULL
       OR strategy_set_name IS NULL
       OR NULLIF(BTRIM(strategy_set_name), '') IS NULL
       OR strategy_name IS NULL
       OR NULLIF(BTRIM(strategy_name), '') IS NULL
       OR strategy_version IS NULL
       OR NULLIF(BTRIM(strategy_version), '') IS NULL
       OR strategy_run_id IS NULL
       OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
       OR strategy_run_ts IS NULL

       OR module1_input_source IS NULL
       OR NULLIF(BTRIM(module1_input_source), '') IS NULL
       OR module1_source_table_name IS NULL
       OR NULLIF(BTRIM(module1_source_table_name), '') IS NULL
       OR module1_model_version IS NULL
       OR NULLIF(BTRIM(module1_model_version), '') IS NULL
       OR module1_scenario_set_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
       OR module1_scenario_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
       OR population_id IS NULL
       OR NULLIF(BTRIM(population_id), '') IS NULL
       OR anchor_date IS NULL

       OR application_id IS NULL
       OR NULLIF(BTRIM(application_id), '') IS NULL
       OR applicant_id IS NULL
       OR NULLIF(BTRIM(applicant_id), '') IS NULL;

    IF v_metadata_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have missing strategy metadata, Module 1 lineage, or application identity fields.',
            v_metadata_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls must be populated and valid.

    Section 11 does not archive rows, but it carries archive controls forward so Section 12 can apply
    governed persistence behavior.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_control_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE archive_run_flag IS NULL
       OR strategy_archive_reset_mode IS NULL
       OR strategy_archive_reset_mode NOT IN (
            'NONE',
            'STRATEGY_SCENARIO_ONLY',
            'STRATEGY_SET_ONLY',
            'ALL'
       );

    IF v_archive_control_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have invalid archive controls.',
            v_archive_control_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final decision fields and final decision flags must reconcile.

    Expected:
        Exactly one of approval_flag, counteroffer_flag, manual_review_flag, decline_flag is TRUE.

        Each flag should equal its decision_outcome expression.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decision_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_priority_rank IS NULL
       OR decision_priority_rank <= 0
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL
       OR approval_flag IS NULL
       OR counteroffer_flag IS NULL
       OR manual_review_flag IS NULL
       OR decline_flag IS NULL
       OR (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
          ) <> 1
       OR approval_flag IS DISTINCT FROM (decision_outcome = 'APPROVE')
       OR counteroffer_flag IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
       OR manual_review_flag IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
       OR decline_flag IS DISTINCT FROM (decision_outcome = 'DECLINE');

    IF v_decision_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have final decision or final flag integrity failures.',
            v_decision_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated_offer_exposure_flag convention.

    Expected:
        TRUE for APPROVE and COUNTEROFFER.

        FALSE for MANUAL_REVIEW and DECLINE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_offer_flag_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE simulated_offer_exposure_flag
          IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'));

    IF v_offer_flag_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have simulated_offer_exposure_flag convention failures.',
            v_offer_flag_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: approved amount and exposure conventions by decision outcome.

    APPROVE:
        approved_amount = requested_amount.

    COUNTEROFFER:
        approved_amount > 0 and approved_amount < requested_amount.

    MANUAL_REVIEW:
        approved_amount IS NULL.

    DECLINE:
        approved_amount = 0.

    Note:
        exposure_reduction_flag is TRUE only for final COUNTEROFFER because it means reduced positive
        offer exposure. DECLINE has zero exposure but is not a reduced positive offer.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_amount_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE requested_amount IS NULL
       OR requested_amount <= 0
       OR (
            approved_amount IS NOT NULL
            AND approved_amount < 0
       )
       OR (
            approved_amount IS NOT NULL
            AND approved_amount > requested_amount
       )
       OR (
            decision_outcome = 'APPROVE'
            AND (
                approved_amount IS DISTINCT FROM requested_amount
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_flag IS DISTINCT FROM FALSE
             OR exposure_reduction_amount IS DISTINCT FROM 0::NUMERIC
             OR exposure_reduction_pct IS DISTINCT FROM 0::NUMERIC
            )
       )
       OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
             OR exposure_reduction_flag IS DISTINCT FROM TRUE
             OR exposure_reduction_amount IS NULL
             OR exposure_reduction_amount <= 0
             OR exposure_reduction_pct IS NULL
             OR exposure_reduction_pct <= 0
            )
       )
       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND (
                approved_amount IS NOT NULL
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_flag IS DISTINCT FROM FALSE
             OR exposure_reduction_amount IS NOT NULL
             OR exposure_reduction_pct IS NOT NULL
            )
       )
       OR (
            decision_outcome = 'DECLINE'
            AND (
                approved_amount IS DISTINCT FROM 0::NUMERIC
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_flag IS DISTINCT FROM FALSE
             OR exposure_reduction_amount IS DISTINCT FROM requested_amount
             OR exposure_reduction_pct IS DISTINCT FROM 1.0::NUMERIC
            )
       );

    IF v_amount_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have approved amount or exposure convention failures.',
            v_amount_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: requested / approved Expected Loss conventions.

    requested_expected_loss_amount:
        requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        approved-exposure Expected Loss after final Module 2 exposure treatment.

    Expected:
        APPROVE preserves requested Expected Loss.
        COUNTEROFFER should not exceed requested Expected Loss or product approved EL cap.
        MANUAL_REVIEW remains unresolved.
        DECLINE uses zero approved Expected Loss.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_expected_loss_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE requested_expected_loss_amount IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL
       OR (
            approved_expected_loss_amount IS NOT NULL
            AND approved_expected_loss_amount < 0
       )
       OR (
            decision_outcome = 'APPROVE'
            AND (
                approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
             OR approved_el_reduction_amount IS DISTINCT FROM 0::NUMERIC
             OR approved_el_reduction_pct IS DISTINCT FROM 0::NUMERIC
            )
       )
       OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount < 0
             OR approved_expected_loss_amount > requested_expected_loss_amount
             OR approved_expected_loss_amount > product_approved_el_cap
             OR approved_el_reduction_amount IS NULL
             OR approved_el_reduction_amount < 0
            )
       )
       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND (
                approved_expected_loss_amount IS NOT NULL
             OR approved_el_reduction_amount IS NOT NULL
             OR approved_el_reduction_pct IS NOT NULL
            )
       )
       OR (
            decision_outcome = 'DECLINE'
            AND (
                approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
             OR approved_el_reduction_amount IS DISTINCT FROM requested_expected_loss_amount
             OR approved_el_reduction_pct IS DISTINCT FROM CASE
                    WHEN requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END
            )
       );

    IF v_expected_loss_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have requested / approved Expected Loss convention failures.',
            v_expected_loss_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated reason-code completeness and family alignment.

    Expected mapping:
        APPROVE       → APPROVAL
        COUNTEROFFER  → COUNTEROFFER
        MANUAL_REVIEW → MANUAL_REVIEW
        DECLINE       → POLICY_STOP
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_reason_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE primary_reason_code IS NULL
       OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
       OR primary_reason_family IS NULL
       OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
       OR triggered_reason_code_list IS NULL
       OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
       OR reason_priority_rank IS NULL
       OR reason_priority_rank <= 0
       OR reason_code_count IS NULL
       OR reason_code_count < 1
       OR (
            decision_outcome = 'APPROVE'
            AND primary_reason_family <> 'APPROVAL'
          )
       OR (
            decision_outcome = 'COUNTEROFFER'
            AND primary_reason_family <> 'COUNTEROFFER'
          )
       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND primary_reason_family <> 'MANUAL_REVIEW'
          )
       OR (
            decision_outcome = 'DECLINE'
            AND primary_reason_family <> 'POLICY_STOP'
          );

    IF v_reason_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have simulated reason-code integrity failures.',
            v_reason_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: prohibited reason-code terminology controls.

    Business purpose:
        Protect the interpretation boundary that Module 2 reason codes are simulated strategy
        explanation codes only.

    These controls prevent terms that imply:
        adverse-action notice,
        regulatory notice,
        customer notice,
        fair-lending conclusion.

    Boundary:
        This does not make simulated reason codes externally approved communication language.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_prohibited_reason_term_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE COALESCE(primary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
       OR COALESCE(secondary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
       OR COALESCE(tertiary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
       OR COALESCE(triggered_reason_code_list, '') ILIKE '%ADVERSE_ACTION%'

       OR COALESCE(primary_reason_code, '') ILIKE '%REGULATORY%'
       OR COALESCE(secondary_reason_code, '') ILIKE '%REGULATORY%'
       OR COALESCE(tertiary_reason_code, '') ILIKE '%REGULATORY%'
       OR COALESCE(triggered_reason_code_list, '') ILIKE '%REGULATORY%'

       OR COALESCE(primary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
       OR COALESCE(secondary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
       OR COALESCE(tertiary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
       OR COALESCE(triggered_reason_code_list, '') ILIKE '%CUSTOMER_NOTICE%'

       OR COALESCE(primary_reason_code, '') ILIKE '%FAIR_LENDING%'
       OR COALESCE(secondary_reason_code, '') ILIKE '%FAIR_LENDING%'
       OR COALESCE(tertiary_reason_code, '') ILIKE '%FAIR_LENDING%'
       OR COALESCE(triggered_reason_code_list, '') ILIKE '%FAIR_LENDING%';

    IF v_prohibited_reason_term_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) contain prohibited reason-code terminology.',
            v_prohibited_reason_term_count;
    END IF;

    /*
    Archive note:
        Section 11 contains no archive insert logic.
        Archive persistence remains deferred to Section 12.
    */
END $$;



/***************************************************************************************************
SECTION 11.5 — LOCAL LATEST-RUN SANITY CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Let reviewers inspect the newly materialized latest-run output before archive persistence begins.

    Section 11.5 answers:

        "What does the current latest-run output look like at a high level?"

SQL PURPOSE:
    Display lightweight diagnostics for:
        latest-run row count,
        application_id uniqueness,
        current strategy identity,
        current Module 1 lineage,
        decision outcome distribution,
        decision path distribution,
        primary reason-code distribution,
        product × decision outcome,
        score band × decision outcome,
        product × primary reason code,
        score band × primary reason code,
        strategy risk tier × decision outcome,
        requested PTI bucket × decision outcome,
        mixed-signal profile × decision outcome,
        simulated offer-exposure flag,
        requested versus approved amount,
        requested versus approved PTI,
        requested versus approved Expected Loss,
        and one compact readiness row.

INTERPRETATION:
    These diagnostics are local latest-run materialization checks only.

    They are not:
        full Section 14 QA,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        executive evidence capture,
        or final written validation evidence.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
11.5.1 Latest-run row count and distinct application_id count.

Purpose:
    Confirm latest-run applicant grain.

Expected:
    latest_run_rows = distinct_application_id_count.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS latest_run_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
11.5.2 Latest-run strategy identity and Module 1 lineage.

Purpose:
    Display the current strategy / scenario / population slice materialized by Section 11.

Expected:
    exactly one row.

Interpretation:
    Module 2 strategy identifiers describe the downstream strategy.
    Module 1 scenario identifiers describe the upstream synthetic population and risk environment.
-----------------------------------------------------------------------------------------------*/

SELECT
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

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,

    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
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
    anchor_date

ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/*-----------------------------------------------------------------------------------------------
11.5.3 Count by decision_outcome.

Purpose:
    Show the final simulated outcome distribution for the latest-run output.

Boundary:
    decision_outcome is simulated strategy output, not real applicant treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.4 Count by decision_path.

Purpose:
    Show internal final decision path labels.

Boundary:
    decision_path is internal simulated strategy traceability, not customer communication language.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    decision_path,
    decision_outcome

ORDER BY
    decision_path,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.5 Count by primary_reason_code.

Purpose:
    Show the main simulated explanation-code distribution.

Boundary:
    These are simulated strategy explanation codes only.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    primary_reason_family,
    primary_reason_code

ORDER BY
    CASE primary_reason_family
        WHEN 'POLICY_STOP' THEN 1
        WHEN 'MANUAL_REVIEW' THEN 2
        WHEN 'COUNTEROFFER' THEN 3
        WHEN 'APPROVAL' THEN 4
        ELSE 99
    END,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
11.5.6 Product × decision_outcome.

Purpose:
    Review final simulated outcome distribution by product.

Interpretation:
    Product-level patterns should be explainable through product policy, requested exposure, PTI,
    LGD, Expected Loss, and counteroffer feasibility.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    decision_outcome

ORDER BY
    product_type_policy_key,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.7 Score band × decision_outcome.

Purpose:
    Review final simulated outcome distribution by borrower-quality segment.

Boundary:
    Score band supports interpretation but is not the only decision driver.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    score_band_policy_key,
    decision_outcome

ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.8 Product × primary_reason_code.

Purpose:
    Review whether simulated explanation-code themes concentrate by product.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_rows,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code

ORDER BY
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
11.5.9 Score band × primary_reason_code.

Purpose:
    Review whether simulated explanation-code themes concentrate by borrower-quality segment.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    score_band_policy_key,
    primary_reason_family,
    primary_reason_code

ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
11.5.10 Strategy risk tier × decision_outcome.

Purpose:
    Review final outcomes by synthetic estimated-risk tier.

Boundary:
    estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
    proxy.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(synthetic_risk_trigger_count) AS avg_synthetic_risk_trigger_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    strategy_risk_tier,
    decision_outcome

ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.11 Requested PTI bucket × decision_outcome.

Purpose:
    Review final outcomes by requested-structure affordability bucket.

Boundary:
    requested_payment_to_income_ratio is requested PTI.

    approved_payment_to_income_ratio is final simulated approved-exposure PTI proxy.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    AVG(affordability_trigger_count) AS avg_affordability_trigger_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    requested_pti_bucket,
    decision_outcome

ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.12 Mixed-signal profile × decision_outcome.

Purpose:
    Review final outcome behavior for realistic overlapping applicant profiles.

Boundary:
    mixed_signal_profile_type is diagnostic, not a final decision reason by itself.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(mixed_signal_condition_count) AS avg_mixed_signal_condition_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    mixed_signal_profile_type,
    decision_outcome

ORDER BY
    CASE mixed_signal_profile_type
        WHEN 'NO_MIXED_SIGNAL_PROFILE' THEN 1
        WHEN 'STRONG_CREDIT_HIGH_PTI' THEN 2
        WHEN 'WEAK_CREDIT_LOW_PTI' THEN 3
        WHEN 'LARGE_EXPOSURE_LOW_RISK' THEN 4
        WHEN 'HIGH_RISK_LOW_EXPOSURE' THEN 5
        WHEN 'HIGH_DTI_LOW_REQUESTED_PTI' THEN 6
        WHEN 'MULTIPLE_MIXED_SIGNALS' THEN 7
        ELSE 99
    END,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.13 Requested versus approved exposure by decision_outcome.

Purpose:
    Review final exposure assignment conventions.

Expected:
    APPROVE preserves requested exposure.
    COUNTEROFFER reduces exposure.
    MANUAL_REVIEW remains unresolved.
    DECLINE uses zero approved exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    AVG(exposure_reduction_amount) AS avg_exposure_reduction_amount,
    AVG(exposure_reduction_pct) AS avg_exposure_reduction_pct

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.14 Requested versus approved PTI by decision_outcome.

Purpose:
    Review final affordability treatment.

Boundary:
    approved_payment_to_income_ratio is a strategy-simulation affordability proxy.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio)
        AS avg_approved_payment_to_income_ratio,

    AVG(
        requested_payment_to_income_ratio - approved_payment_to_income_ratio
    ) FILTER (
        WHERE approved_payment_to_income_ratio IS NOT NULL
    ) AS avg_pti_reduction_where_approved_pti_exists

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.15 Requested versus approved Expected Loss by decision_outcome.

Purpose:
    Review final requested-exposure Expected Loss versus approved-exposure Expected Loss.

Boundary:
    approved_expected_loss_amount is a synthetic strategy simulation metric, not a production loss
    forecast.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_expected_loss_amount,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
11.5.16 Simulated offer-exposure profile.

Purpose:
    Review positive simulated offer exposure.

Expected:
    simulated_offer_exposure_flag = TRUE only for APPROVE and COUNTEROFFER.

Boundary:
    This is simulated positive offer exposure, not booked or funded exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    simulated_offer_exposure_flag,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY simulated_offer_exposure_flag

ORDER BY simulated_offer_exposure_flag;



/*-----------------------------------------------------------------------------------------------
11.5.17 Section 11 readiness summary.

Purpose:
    Provide one compact readiness row for latest-run materialization.

Expected:
    section_11_latest_run_status =
        SECTION_11_LATEST_RUN_READY_FOR_ARCHIVE_PERSISTENCE

Interpretation:
    This confirms only that Section 11 is ready for Section 12.

    It does not validate archive persistence, matched comparison, Section 14 QA, Section 15 frontier,
    or Section 16 evidence capture.
-----------------------------------------------------------------------------------------------*/

WITH latest_run_summary AS (
    SELECT
        COUNT(*) AS latest_run_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version
        )) AS distinct_strategy_identity_count,

        COUNT(DISTINCT (
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS distinct_module1_scenario_population_count,

        COUNT(*) FILTER (
            WHERE latest_output_created_ts IS NULL
        ) AS latest_output_created_ts_null_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome IS NULL
               OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
               OR decision_path IS NULL
               OR decision_resolution_source IS NULL
        ) AS final_decision_gap_rows,

        COUNT(*) FILTER (
            WHERE (
                    COALESCE(approval_flag::INT, 0)
                    + COALESCE(counteroffer_flag::INT, 0)
                    + COALESCE(manual_review_flag::INT, 0)
                    + COALESCE(decline_flag::INT, 0)
                  ) <> 1
        ) AS final_flag_reconciliation_gap_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_gap_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR triggered_reason_code_list IS NULL
               OR reason_priority_rank IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
        ) AS reason_code_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
        ) AS approve_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
        ) AS manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
        ) AS decline_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS simulated_offer_exposure_rows

    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    latest_run_rows,
    distinct_application_id_count,

    distinct_strategy_identity_count,
    distinct_module1_scenario_population_count,

    latest_output_created_ts_null_rows,
    final_decision_gap_rows,
    final_flag_reconciliation_gap_rows,
    simulated_offer_exposure_flag_gap_rows,
    reason_code_gap_rows,

    approve_rows,
    counteroffer_rows,
    manual_review_rows,
    decline_rows,
    simulated_offer_exposure_rows,

    CASE
        WHEN latest_run_rows > 0
         AND latest_run_rows = distinct_application_id_count
         AND distinct_strategy_identity_count = 1
         AND distinct_module1_scenario_population_count = 1
         AND latest_output_created_ts_null_rows = 0
         AND final_decision_gap_rows = 0
         AND final_flag_reconciliation_gap_rows = 0
         AND simulated_offer_exposure_flag_gap_rows = 0
         AND reason_code_gap_rows = 0
            THEN 'SECTION_11_LATEST_RUN_READY_FOR_ARCHIVE_PERSISTENCE'
        ELSE 'REVIEW_SECTION_11_LATEST_RUN_BEFORE_ARCHIVE_PERSISTENCE'
    END AS section_11_latest_run_status

FROM latest_run_summary;



/***************************************************************************************************
END OF SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE

If execution reaches this point:
    1. Section 11 dependency preflight passed.
    2. credit_decisioning_sim.strategy_decisions exists.
    3. Row count matches tmp_m2_stage_7_reason_code_assignment.
    4. application_id remains unique.
    5. Exactly one Module 2 strategy identity is present.
    6. Exactly one Module 1 scenario / population identity is present.
    7. Module 2 strategy metadata is populated.
    8. archive_run_flag and strategy_archive_reset_mode are populated and valid.
    9. Module 1 lineage is populated.
    10. final decision_outcome is populated.
    11. final decision_outcome is one of APPROVE, COUNTEROFFER, MANUAL_REVIEW, DECLINE.
    12. final decision flags reconcile to decision_outcome.
    13. exactly one final decision flag is TRUE per row.
    14. simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.
    15. simulated_offer_exposure_flag is FALSE for MANUAL_REVIEW and DECLINE.
    16. approved_amount conventions hold by decision_outcome.
    17. approved_expected_loss_amount conventions hold by decision_outcome.
    18. primary_reason_code is populated for every row.
    19. primary_reason_family aligns to decision_outcome.
    20. triggered_reason_code_list is populated for every row.
    21. latest_output_created_ts is populated.
    22. Practical latest-run indexes are created.
    23. Campaign registry IDs remain outside the row-level latest-run output and are persisted later
        through Section 16 evidence capture.
    24. Local latest-run diagnostics are available for review.

Section 11 established:
    1. The permanent latest-run output surface.
    2. One current-run row per application_id.
    3. Final simulated decision outcomes.
    4. Final simulated offer-exposure flags.
    5. Final approved exposure fields.
    6. Final approved affordability proxy fields.
    7. Final approved Expected Loss fields.
    8. Simulated strategy explanation-code fields.
    9. Strategy, product-policy, segmentation, rule-trigger, routing, and exposure-treatment trace
       fields needed for downstream QA and evidence capture.
    10. The current-run table Section 12 needs for governed archive persistence.

No archive rows have been inserted.
No matched strategy comparison logic has been created.
No full Module 2 QA framework has been created.
No strategy frontier summary has been created.
No executive evidence rows have been inserted.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 12 should consume credit_decisioning_sim.strategy_decisions and apply governed archive
    persistence using archive_run_flag and strategy_archive_reset_mode.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01579 -->


---

<a id="c038-m01580"></a>

### C038-M01580

**Andrew** · 2026-05-12T11:35:54.459000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01580 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 12 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01580 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_80.md) · [Next](Part_82.md)
