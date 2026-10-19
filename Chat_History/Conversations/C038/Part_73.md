# Module 2 Decision Simulator Build

## Part 73

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_72.md) · [Next](Part_74.md)

<a id="c038-m01472"></a>

### C038-M01472

**ChatGPT** · 2026-05-12T07:08:11.308924-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01472 -->
This is the updated **Section 3 gatekeeper patch only**. It is designed to pair with the redesigned Section 2 you assembled, including the profile catalogs, deterministic `strategy_run_id`, standard/custom run selector, strategy/product-policy compatibility map, and optional auto-derived comparison selector. Your redesigned Section 2 now creates the selector/profile/catalog/control objects that Section 3 should validate, while Section 4 still expects `tmp_m2_source_selection_scope` and `tmp_m2_campaign_registry_current_run_match` from Section 3 before staging Module 1 rows. fileciteturn202file0 fileciteturn203file0

```sql
/***************************************************************************************************
SECTION 3 — FAIL-FAST STRATEGY PARAMETER, SOURCE, PRODUCT POLICY, PROFILE, AND REGISTRY GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Stop invalid Module 2 configuration before applicant-level strategy logic runs.

    Section 3 answers:

        "Is the selected Module 2 run configured well enough to proceed into Module 1 source staging,
         strategy segmentation, rule construction, preliminary routing, exposure treatment, final
         decision resolution, archive persistence, comparison review, QA, frontier analysis, and
         evidence capture?"

WHY THIS SECTION CHANGED:
    Section 2 is now profile-driven.

    The active strategy and product-policy parameter cards are generated from:
        operator selector,
        strategy profile catalog,
        product-policy profile catalog,
        strategy/product-policy compatibility map,
        campaign run catalog,
        campaign registry,
        and comparison registry.

    Section 3 therefore validates not only threshold values, but also:
        selected run cardinality,
        run-mode coherence,
        deterministic strategy_run_id,
        strategy profile compatibility,
        product-policy profile compatibility,
        formal campaign registry linkage,
        optional comparison auto-selection,
        and Module 1 source-scope readiness.

WHY FAIL FAST:
    A failed setup is safer than a successful run under the wrong strategy profile.

    Section 3 prevents:
        stale run selector usage,
        multiple active strategy rows,
        invalid threshold ordering,
        wrong product-policy profile,
        unsupported product configuration,
        malformed source input,
        duplicate source applications,
        missing campaign registry linkage,
        ambiguous comparison setup,
        and weak evidence traceability.

WHAT SECTION 3 DOES:
    1. Confirms required Section 2 temporary objects exist.
    2. Confirms exactly one active operator selector and one selected run configuration exist.
    3. Confirms exactly one active strategy parameter card exists.
    4. Validates strategy identity, run mode, source controls, archive controls, threshold ordering,
       decision conventions, and rule-control parameters.
    5. Validates strategy profile and product-policy profile compatibility.
    6. Validates product-policy completeness and product-level threshold coherence.
    7. Validates selected Module 1 source table, source lineage columns, required fields, row count,
       scenario scope, application uniqueness, and required-field completeness.
    8. Materializes tmp_m2_source_selection_scope for Section 4.
    9. Materializes tmp_m2_campaign_registry_current_run_match for Sections 4 and 16.
    10. Materializes tmp_m2_comparison_campaign_registry_active_match for Section 13 review.
    11. Displays compact setup diagnostics.

WHAT SECTION 3 DOES NOT DO:
    Section 3 does not consume Module 1 rows into the main staging table.
    Section 3 does not assign strategy segments.
    Section 3 does not assign rule flags.
    Section 3 does not route decisions.
    Section 3 does not calculate approved exposure.
    Section 3 does not assign final decision_outcome.
    Section 3 does not assign simulated reason codes.
    Section 3 does not create latest-run output.
    Section 3 does not insert archive rows.
    Section 3 does not perform matched comparison.
    Section 3 does not perform full QA validation.

***************************************************************************************************/



/***************************************************************************************************
SECTION 3.0 — LOCAL SECTION 3 RESET
****************************************************************************************************

PURPOSE:
    Remove Section 3 helper tables before rebuilding gatekeeper outputs.

SQL TEACHING POINT:
    These helper tables are temporary contracts between Section 3 and later sections.

    Section 4 uses:
        tmp_m2_source_selection_scope
        tmp_m2_campaign_registry_current_run_match

    Section 13 uses:
        tmp_m2_comparison_campaign_registry_active_match

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_source_selection_scope;
DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;
DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;



/***************************************************************************************************
SECTION 3.1 — OPERATOR SELECTOR, PROFILE, PARAMETER, AND PRODUCT-POLICY GATEKEEPER
****************************************************************************************************

PURPOSE:
    Validate the active Section 2 configuration before any source rows are consumed.

WHAT TO LOOK FOR IF THIS FAILS:
    Most failures here mean Section 2 should be corrected and rerun.

    Common causes:
        selected_module2_run_id is not in the campaign catalog;
        run_mode is invalid;
        more than one active strategy row exists;
        strategy_run_id was manually altered;
        product-policy profile does not match strategy profile;
        product policy has missing / duplicate product rows;
        threshold ordering is invalid;
        custom-mode fields are incomplete.

***************************************************************************************************/

DO $$
DECLARE
    p RECORD;
    op RECORD;

    v_required_temp_missing_count BIGINT;
    v_required_temp_missing_names TEXT;

    v_active_selector_count BIGINT;
    v_selected_run_count BIGINT;
    v_active_strategy_count BIGINT;

    v_strategy_profile_match_count BIGINT;
    v_compatibility_match_count BIGINT;
    v_formal_compatibility_count BIGINT;

    v_product_policy_count BIGINT;
    v_product_policy_profile_count BIGINT;
    v_supported_product_count BIGINT;
    v_duplicate_product_count BIGINT;
    v_unsupported_product_count BIGINT;
    v_missing_supported_product_count BIGINT;
    v_bad_product_policy_count BIGINT;

    v_explicit_comparison_problem_count BIGINT;
BEGIN
    /***********************************************************************************************
    3.1A Required temporary object existence.

    Business purpose:
        Section 3 must validate the objects generated by Section 2.

    SQL mechanics:
        TO_REGCLASS('pg_temp.<table_name>') checks for temporary table existence in the current
        session.
    ***********************************************************************************************/
    WITH required_temp_objects AS (
        SELECT *
        FROM (
            VALUES
                ('tmp_m2_operator_run_selector'),
                ('tmp_m2_strategy_profile_catalog'),
                ('tmp_m2_product_policy_profile_catalog'),
                ('tmp_m2_strategy_product_policy_compatibility'),
                ('tmp_m2_campaign_run_catalog'),
                ('tmp_m2_selected_run_config'),
                ('tmp_module2_strategy_params'),
                ('tmp_module2_product_policy_params'),
                ('tmp_m2_comparison_plan'),
                ('tmp_m2_active_comparison_selection')
        ) AS v(table_name)
    ),

    missing_temp_objects AS (
        SELECT table_name
        FROM required_temp_objects
        WHERE TO_REGCLASS('pg_temp.' || table_name) IS NULL
    )

    SELECT
        COUNT(*),
        STRING_AGG(table_name, ', ' ORDER BY table_name)
    INTO
        v_required_temp_missing_count,
        v_required_temp_missing_names
    FROM missing_temp_objects;

    IF v_required_temp_missing_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: required Section 2 temporary object(s) missing: %. Rerun redesigned Section 2.',
            v_required_temp_missing_names;
    END IF;


    /***********************************************************************************************
    3.1B Active operator selector cardinality.

    Business purpose:
        There must be exactly one operator control row.

    SQL teaching point:
        COUNT(*) FILTER would also work here, but a plain WHERE count is easiest to read.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_active_selector_count
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE;

    IF v_active_selector_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected exactly one active operator selector, found %.',
            v_active_selector_count;
    END IF;

    SELECT *
    INTO op
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE
    LIMIT 1;

    IF op.run_mode NOT IN ('STANDARD_CAMPAIGN', 'CUSTOM') THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: run_mode must be STANDARD_CAMPAIGN or CUSTOM. Found: %.',
            COALESCE(op.run_mode, '<NULL>');
    END IF;

    IF op.run_mode = 'STANDARD_CAMPAIGN'
       AND (op.selected_module2_run_id IS NULL OR NULLIF(BTRIM(op.selected_module2_run_id), '') IS NULL) THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: STANDARD_CAMPAIGN mode requires selected_module2_run_id.';
    END IF;


    /***********************************************************************************************
    3.1C Selected run configuration cardinality.

    Business purpose:
        Section 2 should normalize STANDARD_CAMPAIGN and CUSTOM mode into one selected run row.

    Failure interpretation:
        Zero rows usually means selected_module2_run_id does not exist in the campaign catalog.
        Multiple rows means selector logic is ambiguous.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_selected_run_count
    FROM tmp_m2_selected_run_config;

    IF v_selected_run_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected exactly one selected run configuration row, found %. Check selected_module2_run_id and run_mode.',
            v_selected_run_count;
    END IF;


    /***********************************************************************************************
    3.1D Active strategy parameter-card cardinality.
    ***********************************************************************************************/
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


    /***********************************************************************************************
    3.1E Required strategy identity and profile fields.

    Credit strategy interpretation:
        Strategy identity describes the downstream Module 2 policy posture.
        Module 1 scenario fields describe the upstream synthetic population.

        These must remain separate.
    ***********************************************************************************************/
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

    IF p.strategy_profile_code IS NULL OR NULLIF(BTRIM(p.strategy_profile_code), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_profile_code must be populated.';
    END IF;

    IF p.product_policy_profile_code IS NULL OR NULLIF(BTRIM(p.product_policy_profile_code), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: product_policy_profile_code must be populated.';
    END IF;

    IF p.strategy_run_id IS NULL OR NULLIF(BTRIM(p.strategy_run_id), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_run_id must be populated.';
    END IF;

    IF p.strategy_run_ts IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: strategy_run_ts must be populated.';
    END IF;


    /***********************************************************************************************
    3.1F Deterministic strategy_run_id convention.

    Business purpose:
        Prevent hand-typed run IDs from drifting away from selected_module2_run_id, strategy_name,
        and strategy_version.

    Expected:
        M2-29_COUNTEROFFER_FIRST_EXPOSURE_STRATEGY_V1_0_RUN
    ***********************************************************************************************/
    IF p.strategy_run_id <> p.module2_run_id || '_' || p.strategy_name || '_' || p.strategy_version || '_RUN' THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: strategy_run_id does not match deterministic convention. Found %, expected %.',
            p.strategy_run_id,
            p.module2_run_id || '_' || p.strategy_name || '_' || p.strategy_version || '_RUN';
    END IF;


    /***********************************************************************************************
    3.1G Strategy profile catalog match.

    SQL mechanics:
        The active strategy card should trace back to exactly one executable strategy profile row.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_strategy_profile_match_count
    FROM tmp_m2_strategy_profile_catalog sp
    WHERE sp.strategy_profile_code = p.strategy_profile_code
      AND sp.strategy_name = p.strategy_name
      AND sp.strategy_set_name = p.strategy_set_name
      AND sp.strategy_version = p.strategy_version;

    IF v_strategy_profile_match_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active strategy card does not match exactly one strategy profile catalog row. Match count: %.',
            v_strategy_profile_match_count;
    END IF;


    /***********************************************************************************************
    3.1H Run-mode coherence.

    STANDARD_CAMPAIGN:
        formal campaign path;
        must require registry match;
        should use ARCHIVE source;
        must use a standard campaign profile.

    CUSTOM:
        exploratory path;
        does not require campaign registry unless a future custom registry path is added.
    ***********************************************************************************************/
    IF p.run_mode NOT IN ('STANDARD_CAMPAIGN', 'CUSTOM') THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active strategy run_mode must be STANDARD_CAMPAIGN or CUSTOM. Found: %.',
            COALESCE(p.run_mode, '<NULL>');
    END IF;

    IF p.run_mode = 'STANDARD_CAMPAIGN' THEN
        IF p.campaign_registry_required_flag IS DISTINCT FROM TRUE THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: STANDARD_CAMPAIGN requires campaign_registry_required_flag = TRUE.';
        END IF;

        IF p.standard_campaign_profile_flag IS DISTINCT FROM TRUE THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: STANDARD_CAMPAIGN selected strategy profile is not marked as a standard campaign profile.';
        END IF;

        IF p.module1_input_source <> 'ARCHIVE' THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: STANDARD_CAMPAIGN should consume Module 1 ARCHIVE input. Found: %.',
                COALESCE(p.module1_input_source, '<NULL>');
        END IF;

        IF p.module2_run_id IS NULL OR p.module2_run_id !~ '^M2-[0-9][0-9]$' THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: STANDARD_CAMPAIGN module2_run_id must follow M2-## format. Found: %.',
                COALESCE(p.module2_run_id, '<NULL>');
        END IF;

        IF p.run_sequence_number IS NULL THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: STANDARD_CAMPAIGN requires run_sequence_number.';
        END IF;
    END IF;

    IF p.run_mode = 'CUSTOM' THEN
        IF p.campaign_registry_required_flag IS DISTINCT FROM FALSE THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: CUSTOM mode should set campaign_registry_required_flag = FALSE unless a custom registry path is deliberately added.';
        END IF;

        IF p.source_module1_scenario_set_name IS NULL
           OR NULLIF(BTRIM(p.source_module1_scenario_set_name), '') IS NULL
           OR p.source_module1_scenario_name IS NULL
           OR NULLIF(BTRIM(p.source_module1_scenario_name), '') IS NULL
           OR p.source_population_id IS NULL
           OR NULLIF(BTRIM(p.source_population_id), '') IS NULL THEN
            RAISE EXCEPTION
                'Module 2 Section 3 failure: CUSTOM mode requires source Module 1 scenario set, scenario name, and population_id.';
        END IF;
    END IF;


    /***********************************************************************************************
    3.1I Source selection and archive controls.
    ***********************************************************************************************/
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

    IF p.archive_run_flag IS NULL THEN
        RAISE EXCEPTION 'Module 2 Section 3 failure: archive_run_flag must not be NULL.';
    END IF;

    IF p.strategy_archive_reset_mode IS NULL
       OR p.strategy_archive_reset_mode NOT IN ('NONE','STRATEGY_SCENARIO_ONLY','STRATEGY_SET_ONLY','ALL') THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: invalid strategy_archive_reset_mode: %.',
            COALESCE(p.strategy_archive_reset_mode, '<NULL>');
    END IF;


    /***********************************************************************************************
    3.1J Global threshold validation.

    Credit risk interpretation:
        Lower synthetic estimated-risk thresholds tighten risk appetite.
        Higher thresholds expand access.

        PTI thresholds express payment-burden tolerance.
        DTI thresholds express existing-obligation capacity.
    ***********************************************************************************************/
    IF p.approve_max_estimated_pd_proxy IS NULL
       OR p.counteroffer_max_estimated_pd_proxy IS NULL
       OR p.review_max_estimated_pd_proxy IS NULL
       OR p.decline_min_estimated_pd_proxy IS NULL
       OR p.approve_max_estimated_pd_proxy < 0
       OR p.counteroffer_max_estimated_pd_proxy < 0
       OR p.review_max_estimated_pd_proxy < 0
       OR p.decline_min_estimated_pd_proxy < 0
       OR p.approve_max_estimated_pd_proxy > 1
       OR p.counteroffer_max_estimated_pd_proxy > 1
       OR p.review_max_estimated_pd_proxy > 1
       OR p.decline_min_estimated_pd_proxy > 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: synthetic estimated-risk thresholds must be populated and between 0 and 1.';
    END IF;

    IF NOT (
        p.approve_max_estimated_pd_proxy < p.counteroffer_max_estimated_pd_proxy
        AND p.counteroffer_max_estimated_pd_proxy < p.review_max_estimated_pd_proxy
        AND p.review_max_estimated_pd_proxy <= p.decline_min_estimated_pd_proxy
    ) THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: synthetic estimated-risk threshold ordering is invalid.';
    END IF;

    IF p.global_approve_max_pti IS NULL
       OR p.global_review_max_pti IS NULL
       OR p.global_decline_min_pti IS NULL
       OR p.global_approve_max_pti < 0
       OR p.global_review_max_pti < 0
       OR p.global_decline_min_pti < 0
       OR p.global_approve_max_pti > 2
       OR p.global_review_max_pti > 2
       OR p.global_decline_min_pti > 2 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: global PTI thresholds must be populated and reasonably bounded.';
    END IF;

    IF NOT (
        p.global_approve_max_pti < p.global_review_max_pti
        AND p.global_review_max_pti <= p.global_decline_min_pti
    ) THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: global PTI threshold ordering is invalid.';
    END IF;

    IF p.approve_max_dti IS NULL
       OR p.review_max_dti IS NULL
       OR p.decline_min_dti IS NULL
       OR p.approve_max_dti < 0
       OR p.review_max_dti < 0
       OR p.decline_min_dti < 0
       OR p.approve_max_dti > 2
       OR p.review_max_dti > 2
       OR p.decline_min_dti > 2 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: DTI thresholds must be populated and reasonably bounded.';
    END IF;

    IF NOT (
        p.approve_max_dti < p.review_max_dti
        AND p.review_max_dti <= p.decline_min_dti
    ) THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: DTI threshold ordering is invalid.';
    END IF;

    IF p.borderline_threshold_buffer_pct IS NULL
       OR p.borderline_threshold_buffer_pct < 0
       OR p.borderline_threshold_buffer_pct > 0.250000 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: borderline_threshold_buffer_pct must be between 0 and 0.25.';
    END IF;


    /***********************************************************************************************
    3.1K Rule-control and decision-convention validation.
    ***********************************************************************************************/
    IF p.bankruptcy_policy_stop_enabled IS NULL
       OR p.major_derogatory_policy_stop_enabled IS NULL
       OR p.severe_delinquency_policy_stop_enabled IS NULL
       OR p.high_utilization_review_enabled IS NULL
       OR p.low_score_review_enabled IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: rule-control Boolean parameters must not be NULL.';
    END IF;

    IF p.severe_delinquency_count_threshold IS NULL
       OR p.severe_delinquency_count_threshold < 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: severe_delinquency_count_threshold must be non-negative.';
    END IF;

    IF p.high_utilization_review_threshold IS NULL
       OR p.high_utilization_review_threshold < 0
       OR p.high_utilization_review_threshold > 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: high_utilization_review_threshold must be between 0 and 1.';
    END IF;

    IF p.low_score_review_threshold IS NULL
       OR p.low_score_review_threshold < 300
       OR p.low_score_review_threshold > 850 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: low_score_review_threshold must be between 300 and 850.';
    END IF;

    IF p.approve_reason_code <> 'APPROVED_AS_REQUESTED' THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: approve_reason_code must equal APPROVED_AS_REQUESTED.';
    END IF;

    IF p.reason_code_required_flag IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: reason_code_required_flag must be TRUE.';
    END IF;

    IF p.simulated_offer_exposure_flag_enabled IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: simulated_offer_exposure_flag_enabled must be TRUE.';
    END IF;

    IF p.manual_review_approved_amount_convention <> 'NULL_UNRESOLVED'
       OR p.approved_el_manual_review_convention <> 'NULL_UNRESOLVED' THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: MANUAL_REVIEW conventions must be NULL_UNRESOLVED.';
    END IF;

    IF p.decline_approved_amount_convention <> 'ZERO'
       OR p.approved_el_decline_convention <> 'ZERO' THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: DECLINE conventions must be ZERO.';
    END IF;

    IF p.allow_approved_amount_above_requested_flag IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: allow_approved_amount_above_requested_flag must be FALSE.';
    END IF;

    IF p.failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW','DECLINE') THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: failed_counteroffer_resolution must be MANUAL_REVIEW or DECLINE.';
    END IF;


    /***********************************************************************************************
    3.1L Strategy ↔ product-policy compatibility.

    Business purpose:
        Formal strategy profiles should carry the product-policy posture that matches the strategy
        story.

    Examples:
        PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY → PRODUCT_GUARDRAIL_PRODUCT_POLICY
        COUNTEROFFER_FIRST_EXPOSURE_STRATEGY → COUNTEROFFER_FIRST_PRODUCT_POLICY
        TIGHTER_AFFORDABILITY_STRATEGY → AFFORDABILITY_TIGHT_PRODUCT_POLICY
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_compatibility_match_count
    FROM tmp_m2_strategy_product_policy_compatibility c
    WHERE c.strategy_profile_code = p.strategy_profile_code
      AND c.strategy_name = p.strategy_name
      AND c.required_product_policy_profile_code = p.product_policy_profile_code;

    IF v_compatibility_match_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active strategy profile and product-policy profile are incompatible.';
    END IF;

    SELECT COUNT(*)
    INTO v_formal_compatibility_count
    FROM tmp_m2_strategy_product_policy_compatibility c
    WHERE c.strategy_profile_code = p.strategy_profile_code
      AND c.strategy_name = p.strategy_name
      AND c.required_product_policy_profile_code = p.product_policy_profile_code
      AND c.formal_campaign_compatible_flag IS TRUE;

    IF p.run_mode = 'STANDARD_CAMPAIGN'
       AND v_formal_compatibility_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: STANDARD_CAMPAIGN run is not marked formal-campaign compatible in strategy/product-policy compatibility map.';
    END IF;


    /***********************************************************************************************
    3.1M Product-policy completeness and coherence.

    Expected:
        exactly five rows;
        one per supported product;
        one product-policy profile;
        no unsupported product keys.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_product_policy_count
    FROM tmp_module2_product_policy_params;

    IF v_product_policy_count <> 5 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: expected 5 active product-policy rows, found %.',
            v_product_policy_count;
    END IF;

    SELECT COUNT(DISTINCT product_policy_profile_code)
    INTO v_product_policy_profile_count
    FROM tmp_module2_product_policy_params;

    IF v_product_policy_profile_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active product-policy table should contain exactly one product_policy_profile_code, found %.',
            v_product_policy_profile_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM tmp_module2_product_policy_params pp
        WHERE pp.product_policy_profile_code IS DISTINCT FROM p.product_policy_profile_code
    ) THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active product-policy rows do not match active strategy product_policy_profile_code.';
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
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active product-policy table does not contain the full supported product set.';
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
        RAISE EXCEPTION
            'Module 2 Section 3 failure: duplicate product-policy rows exist.';
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
        RAISE EXCEPTION
            'Module 2 Section 3 failure: unsupported product_type found in product-policy table.';
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
        RAISE EXCEPTION
            'Module 2 Section 3 failure: one or more supported products are missing product-policy rows.';
    END IF;

    SELECT COUNT(*)
    INTO v_bad_product_policy_count
    FROM tmp_module2_product_policy_params
    WHERE product_approve_max_pti IS NULL
       OR product_review_max_pti IS NULL
       OR product_decline_min_pti IS NULL
       OR counteroffer_target_pti IS NULL
       OR product_approve_max_pti < 0
       OR product_review_max_pti < 0
       OR product_decline_min_pti < 0
       OR counteroffer_target_pti < 0
       OR product_approve_max_pti > 2
       OR product_review_max_pti > 2
       OR product_decline_min_pti > 2
       OR counteroffer_target_pti > 2
       OR NOT (
            product_approve_max_pti < product_review_max_pti
            AND product_review_max_pti <= product_decline_min_pti
            AND counteroffer_target_pti <= product_approve_max_pti
       )

       OR product_approve_max_requested_el IS NULL
       OR product_review_max_requested_el IS NULL
       OR product_decline_min_requested_el IS NULL
       OR product_approved_el_cap IS NULL
       OR product_approve_max_requested_el < 0
       OR product_review_max_requested_el < 0
       OR product_decline_min_requested_el < 0
       OR product_approved_el_cap < 0
       OR NOT (
            product_approve_max_requested_el < product_review_max_requested_el
            AND product_review_max_requested_el <= product_decline_min_requested_el
       )

       OR product_min_approved_amount IS NULL
       OR product_max_approved_amount IS NULL
       OR product_min_approved_amount <= 0
       OR product_max_approved_amount <= product_min_approved_amount

       OR counteroffer_allowed_flag IS NULL
       OR manual_review_allowed_flag IS NULL
       OR product_min_counteroffer_pct IS NULL
       OR product_max_exposure_reduction_pct IS NULL
       OR product_min_counteroffer_pct < 0
       OR product_min_counteroffer_pct > 1
       OR product_max_exposure_reduction_pct < 0
       OR product_max_exposure_reduction_pct > 1

       OR exposure_assignment_method IS NULL
       OR exposure_assignment_method <> 'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'

       OR approved_amount_rounding_increment IS NULL
       OR approved_amount_rounding_increment <= 0;

    IF v_bad_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: % product-policy row(s) failed threshold, exposure, counteroffer, or rounding validation.',
            v_bad_product_policy_count;
    END IF;


    /***********************************************************************************************
    3.1N Explicit comparison selector validation.

    Business purpose:
        selected_comparison_group_id is optional. If the user explicitly typed a CG## value, it should
        exist. If auto-selection is ambiguous, Section 13 can be skipped or the user can rerun Section
        2 with an explicit comparison group.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_explicit_comparison_problem_count
    FROM tmp_m2_active_comparison_selection
    WHERE requested_comparison_group_id IS NOT NULL
      AND active_comparison_selection_status IN (
            'EXPLICIT_COMPARISON_GROUP_NOT_FOUND_REVIEW',
            'EXPLICIT_COMPARISON_GROUP_DUPLICATE_REVIEW'
      );

    IF v_explicit_comparison_problem_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: explicit selected_comparison_group_id was not valid. Review tmp_m2_active_comparison_selection.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.2 — MODULE 1 SOURCE-INPUT VALIDATION AND SOURCE-SCOPE MATERIALIZATION
****************************************************************************************************

PURPOSE:
    Validate the selected Module 1 source before Section 4 creates the main source-staging table.

WHY THIS MATTERS:
    Matched strategy comparison depends on clean source lineage.

    If source selection is ambiguous, strategy deltas may reflect population drift, source-selection
    error, or upstream scenario mismatch rather than true Module 2 strategy movement.

OUTPUT:
    tmp_m2_source_selection_scope

SECTION 4 DEPENDENCY:
    Section 4 compares its staged output back to this helper table to confirm that the source rows
    staged in Section 4 match the source rows validated here.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_source_selection_scope;

DO $$
DECLARE
    p RECORD;

    v_source_table_schema TEXT;
    v_source_table_name TEXT;
    v_source_regclass REGCLASS;

    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;
    v_module1_model_version_col TEXT;
    v_base_apr_col TEXT;

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
        'application_seq',
        'application_date',
        'anchor_date',
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
        'loan_term_months'
    ];

    v_null_check_expression TEXT;
BEGIN
    /***********************************************************************************************
    Active strategy card.
    ***********************************************************************************************/
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;


    /***********************************************************************************************
    Source table selection.

    LATEST:
        credit_decisioning_sim.synthetic_applications

    ARCHIVE:
        credit_decisioning_sim.synthetic_applications_scenario_archive
    ***********************************************************************************************/
    IF p.module1_input_source = 'LATEST' THEN
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications';

    ELSIF p.module1_input_source = 'ARCHIVE' THEN
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications_scenario_archive';

    ELSE
        RAISE EXCEPTION
            'Module 2 Section 3 failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
            COALESCE(p.module1_input_source, '<NULL>');
    END IF;

    v_source_regclass := TO_REGCLASS(v_source_table_schema || '.' || v_source_table_name);

    IF v_source_regclass IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: Module 1 source table %.% does not exist.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /***********************************************************************************************
    Detect scenario lineage column names.

    Module 1 latest-run outputs may use:
        scenario_set_name / scenario_name

    Archive or normalized outputs may use:
        module1_scenario_set_name / module1_scenario_name
    ***********************************************************************************************/
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
            'Module 2 Section 3 failure: source table %.% lacks required scenario lineage columns.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /***********************************************************************************************
    Detect Module 1 model-version and APR-proxy column aliases.

    These are required conceptually, but may be exposed under alternate names.
    ***********************************************************************************************/
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'module1_model_version'
        )
            THEN 'module1_model_version'
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'model_version'
        )
            THEN 'model_version'
        ELSE NULL
    END
    INTO v_module1_model_version_col;

    IF v_module1_model_version_col IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: source table %.% must contain module1_model_version or model_version.',
            v_source_table_schema,
            v_source_table_name;
    END IF;

    SELECT CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'base_apr_for_payment_calc'
        )
            THEN 'base_apr_for_payment_calc'
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = v_source_table_schema
              AND table_name = v_source_table_name
              AND column_name = 'base_apr_for_payment_calculation'
        )
            THEN 'base_apr_for_payment_calculation'
        ELSE NULL
    END
    INTO v_base_apr_col;

    IF v_base_apr_col IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: source table %.% must contain base_apr_for_payment_calc or base_apr_for_payment_calculation.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /***********************************************************************************************
    Required source column existence.

    loan_term_months must exist but may be NULL for REVOLVING_LINE rows.
    ***********************************************************************************************/
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


    /***********************************************************************************************
    Required-field null expression.

    Product-specific term convention:
        loan_term_months may be NULL for REVOLVING_LINE because revolving products may not have a
        fixed amortizing term.

    SQL mechanics:
        v_null_check_expression is injected into dynamic SQL below.
    ***********************************************************************************************/
    v_null_check_expression :=
        'application_id IS NULL'
        || ' OR applicant_id IS NULL'
        || ' OR application_seq IS NULL'
        || ' OR application_date IS NULL'
        || ' OR anchor_date IS NULL'
        || ' OR ' || FORMAT('%I IS NULL', v_module1_model_version_col)
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
        || ' OR ' || FORMAT('%I IS NULL', v_base_apr_col)
        || ' OR ' || FORMAT('%I IS NULL', v_scenario_set_col)
        || ' OR ' || FORMAT('%I IS NULL', v_scenario_name_col)
        || ' OR ('
        || '      UPPER(REGEXP_REPLACE(BTRIM(product_type::TEXT), ''[^A-Za-z0-9]+'', ''_'', ''g'')) NOT IN ('
        || '          ''REVOLVING_LINE'', ''REVOLVING'', ''CREDIT_CARD'', ''REVOLVING_CREDIT_LINE'''
        || '      )'
        || '      AND loan_term_months IS NULL'
        || '    )';


    /***********************************************************************************************
    LATEST source validation.

    LATEST mode expects the latest Module 1 table to represent one scenario / population slice.
    ***********************************************************************************************/
    IF p.module1_input_source = 'LATEST' THEN
        EXECUTE FORMAT(
            'SELECT
                 COUNT(*),
                 COUNT(DISTINCT application_id),
                 COUNT(DISTINCT (%I, %I, population_id))
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
            'SELECT
                 MIN(%I)::TEXT,
                 MIN(%I)::TEXT,
                 MIN(population_id)::TEXT
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


    /***********************************************************************************************
    ARCHIVE source validation.

    ARCHIVE mode filters to the selected Module 1 scenario set/name/population.
    ***********************************************************************************************/
    ELSE
        EXECUTE FORMAT(
            'SELECT
                 COUNT(*),
                 COUNT(DISTINCT application_id),
                 COUNT(DISTINCT (%I, %I, population_id))
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


    /***********************************************************************************************
    Source row-count and uniqueness gatekeepers.
    ***********************************************************************************************/
    IF v_selected_row_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: selected Module 1 source slice contains zero rows.';
    END IF;

    IF v_selected_distinct_application_count <> v_selected_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: selected source application_id is not unique. Rows=%, distinct application_id=%, duplicate groups=%.',
            v_selected_row_count,
            v_selected_distinct_application_count,
            v_duplicate_application_group_count;
    END IF;

    IF v_scenario_population_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: selected source slice has % scenario / population combinations. Expected exactly one.',
            v_scenario_population_count;
    END IF;

    IF v_null_required_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: selected source contains % row(s) with null required fields.',
            v_null_required_field_count;
    END IF;


    /***********************************************************************************************
    Materialize Section 3 source-scope helper.

    Section 4 will use this as the source-selection contract.
    ***********************************************************************************************/
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
****************************************************************************************************

PURPOSE:
    Match the current technical Module 1 scenario × Module 2 strategy run key to the persistent
    campaign registry.

WHY THIS MATTERS:
    Formal campaign runs should not rely only on long technical names.

    The campaign registry provides stable:
        module1_run_id,
        module2_run_id,
        run_sequence_number,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id,
        README labels,
        LinkedIn sequence labels,
        and Validation Summary section hints.

OUTPUT:
    tmp_m2_campaign_registry_current_run_match

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;

CREATE TEMP TABLE tmp_m2_campaign_registry_current_run_match
ON COMMIT PRESERVE ROWS
AS
WITH active_run AS (
    SELECT
        p.campaign_registry_required_flag,

        p.module2_run_id AS active_module2_run_id,
        p.run_sequence_number AS active_run_sequence_number,

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
        ON r.module2_run_id = a.active_module2_run_id
       AND r.module1_scenario_set_name = a.module1_scenario_set_name
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

    a.active_module2_run_id,
    a.active_run_sequence_number,

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
    v_profile_registry_mismatch_count BIGINT;
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

    SELECT COUNT(*)
    INTO v_profile_registry_mismatch_count
    FROM tmp_m2_campaign_registry_current_run_match
    WHERE run_registry_match_status = 'RUN_REGISTRY_MATCHED'
      AND (
            active_module2_run_id IS DISTINCT FROM module2_run_id
         OR active_run_sequence_number IS DISTINCT FROM run_sequence_number
      );

    IF v_profile_registry_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: active generated run ID / sequence does not match campaign registry.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.4 — ACTIVE COMPARISON REGISTRY HELPER
****************************************************************************************************

PURPOSE:
    Materialize the currently active comparison registry row for Section 13.

IMPORTANT:
    Comparison selection is optional for running a single strategy slice.

    If the selected run is not part of a comparison, or if auto-selection is ambiguous for a baseline
    run, this helper may contain zero rows.

    Section 13 requires exactly one active comparison only when Section 13 is run.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;

CREATE TEMP TABLE tmp_m2_comparison_campaign_registry_active_match
ON COMMIT PRESERVE ROWS
AS
SELECT *
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE active_comparison_flag IS TRUE
  AND registry_active_flag IS TRUE;



DO $$
DECLARE
    v_active_comparison_count BIGINT;
    v_selection_count BIGINT;
    v_explicit_bad_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_selection_count
    FROM tmp_m2_active_comparison_selection;

    IF v_selection_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: tmp_m2_active_comparison_selection should contain exactly one row, found %.',
            v_selection_count;
    END IF;

    SELECT COUNT(*)
    INTO v_active_comparison_count
    FROM tmp_m2_comparison_campaign_registry_active_match;

    IF v_active_comparison_count > 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: more than one active comparison registry row exists.';
    END IF;

    SELECT COUNT(*)
    INTO v_explicit_bad_count
    FROM tmp_m2_active_comparison_selection
    WHERE requested_comparison_group_id IS NOT NULL
      AND effective_comparison_group_id IS NULL;

    IF v_explicit_bad_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 3 failure: explicit comparison group was requested but not resolved. Review selected_comparison_group_id.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.5 — SETUP DIAGNOSTICS
****************************************************************************************************

PURPOSE:
    Display compact review outputs after the fail-fast gatekeepers pass.

INTERPRETATION:
    These outputs are setup diagnostics.

    They are not:
        final strategy validation,
        archive validation,
        matched comparison validation,
        Section 14 QA,
        or Section 16 evidence capture.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
3.5A Active operator selector.

Expected:
    exactly one row.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_ACTIVE_OPERATOR_SELECTOR' AS diagnostic_name,
    active_selector_flag,
    run_mode,
    selected_module2_run_id,
    selected_comparison_group_id,
    custom_module2_run_id,
    custom_strategy_profile_code,
    custom_product_policy_profile_code,
    custom_parameter_change_reason
FROM tmp_m2_operator_run_selector
WHERE active_selector_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
3.5B Selected run configuration.

Expected:
    exactly one row.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_SELECTED_RUN_CONFIG' AS diagnostic_name,
    *
FROM tmp_m2_selected_run_config;



/*-----------------------------------------------------------------------------------------------
3.5C Active strategy parameter card.

Expected:
    exactly one row.

Key interpretation:
    This is the strategy card downstream sections will consume.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_ACTIVE_STRATEGY_PARAMETER_CARD' AS diagnostic_name,

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
    failed_counteroffer_resolution

FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
3.5D Global threshold setup.

Purpose:
    Show the active strategy-level risk, affordability, and DTI threshold posture.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_GLOBAL_THRESHOLD_SETUP' AS diagnostic_name,

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

    borderline_threshold_buffer_pct

FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
3.5E Product-policy setup.

Expected:
    five rows.

Key interpretation:
    Product-level policy is where product-specific affordability, requested-EL, approved-EL,
    amount-cap, and counteroffer behavior is controlled.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_PRODUCT_POLICY_SETUP' AS diagnostic_name,

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

ORDER BY
    product_type;



/*-----------------------------------------------------------------------------------------------
3.5F Effective Module 1 source-selection scope.

Expected:
    exactly one row.

This is the validated source-scope contract used by Section 4.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_SOURCE_SELECTION_SCOPE' AS diagnostic_name,

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

FROM tmp_m2_source_selection_scope;



/*-----------------------------------------------------------------------------------------------
3.5G Current run campaign registry match.

Expected for STANDARD_CAMPAIGN:
    run_registry_match_status = RUN_REGISTRY_MATCHED
    registry_match_count = 1
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_CAMPAIGN_REGISTRY_MATCH' AS diagnostic_name,

    campaign_registry_required_flag,
    registry_match_count,
    run_registry_match_status,

    active_module2_run_id,
    active_run_sequence_number,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    strategy_profile_code,
    product_policy_profile_code,

    module1_run_id,
    module2_run_id,
    run_sequence_number,

    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    module1_parameter_family_changed,
    module1_parameter_change_summary,

    module2_strategy_family_changed,
    module2_parameter_change_summary,

    expected_storyline,
    validation_summary_section_hint,
    readme_storyline_label,
    linkedin_post_sequence

FROM tmp_m2_campaign_registry_current_run_match;



/*-----------------------------------------------------------------------------------------------
3.5H Active comparison auto-selection diagnostic.

Purpose:
    Confirm how Section 2 resolved the active Section 13 comparison.

Interpretation:
    effective_comparison_group_id may be NULL for baseline runs used in multiple comparisons or for
    runs not included in the comparison plan.

    That is acceptable for single-run execution.
    Section 13 requires an active comparison only when Section 13 is run.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_ACTIVE_COMPARISON_SELECTION' AS diagnostic_name,

    run_mode,
    selected_module2_run_id,
    requested_comparison_group_id,
    effective_comparison_group_id,

    explicit_match_count,
    challenger_match_count,
    baseline_match_count,

    active_comparison_selection_status

FROM tmp_m2_active_comparison_selection;



/*-----------------------------------------------------------------------------------------------
3.5I Active comparison registry row.

Expected:
    zero or one row.

One row:
    Section 13 has an active governed comparison available.

Zero rows:
    Current selected run does not imply a unique comparison, or the user should set
    selected_comparison_group_id explicitly before Section 13 review.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_3_ACTIVE_COMPARISON_REGISTRY_ROW' AS diagnostic_name,
    *
FROM tmp_m2_comparison_campaign_registry_active_match;



/***************************************************************************************************
END OF SECTION 3 — FAIL-FAST STRATEGY PARAMETER, SOURCE, PRODUCT POLICY, PROFILE, AND REGISTRY GATEKEEPER

If execution reaches this point:
    1. Section 2 control objects exist.
    2. Exactly one active selector exists.
    3. Exactly one selected run configuration exists.
    4. Exactly one active strategy parameter card exists.
    5. Strategy profile and product-policy profile are compatible.
    6. Product-policy rows are complete and coherent.
    7. Module 1 source table exists and is scoped to one valid source slice.
    8. tmp_m2_source_selection_scope is materialized for Section 4.
    9. tmp_m2_campaign_registry_current_run_match is materialized for Section 4 and Section 16.
    10. tmp_m2_comparison_campaign_registry_active_match is materialized for Section 13 review.
    11. Setup diagnostics have been displayed.

Next:
    Run Section 4 to stage the validated Module 1 source into the Module 2 source-staging table.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01472 -->


---

<a id="c038-m01473"></a>

### C038-M01473

**Andrew** · 2026-05-12T07:21:10.387000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01473 -->
review our changes through section 3 before we move on:
<!-- END_MESSAGE C038-M01473 -->


**Attachments in export:** `Pasted text(173).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01481"></a>

### C038-M01481

**ChatGPT** · 2026-05-12T07:27:57.904452-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01481 -->
According to a document from 2026-05-12, my review verdict is:

```text
SECTIONS 0–3 STATUS:
    STRUCTURALLY READY TO PROCEED

RECOMMENDATION:
    Make two small governance-cleanup patches before moving to Section 4.

BLOCKER STATUS:
    No logic blocker found in Sections 0–3.
```

I would proceed, but I would make the two cleanup items below first.

## What looks strong

### 1. Section 0 / Section 1 are directionally aligned with the new architecture

The top-of-script framing now correctly treats Module 2 as a governed synthetic strategy simulation layer, not an operational underwriting engine. It also correctly distinguishes Module 1 lineage from Module 2 strategy identity and keeps the expected downstream chain visible: Module 1 profile → Module 2 strategy controls → product policy → segmentation → rules → routing → exposure treatment → final outcome → reason codes → archive / comparison / validation / evidence. fileciteturn206file0

Section 1 now resets the new selector/profile/parameter objects, including:

```text
tmp_m2_operator_run_selector
tmp_m2_campaign_run_catalog
tmp_m2_selected_run_config
tmp_m2_strategy_profile_catalog
tmp_m2_product_policy_profile_catalog
tmp_m2_strategy_product_policy_compatibility
tmp_module2_strategy_params
tmp_module2_product_policy_params
```

That is the correct reset behavior for the redesigned Section 2 architecture. fileciteturn211file3

### 2. Section 2 now solves the core operator problem

The redesigned Section 2 clearly moves from hand-editing many values to selecting a campaign run through:

```sql
selected_module2_run_id
```

It also now states that `BASELINE_STRATEGY` is the default reference strategy and that `TIGHTER_SYNTHETIC_RISK_STRATEGY` is a challenger, not the default. That directly resolves the commentary issue you flagged earlier. fileciteturn208file4

The local Section 2 reset is also correct. It drops the selector, strategy profile catalog, product-policy profile catalog, compatibility map, campaign catalog, selected-run config, comparison-plan helpers, and the two canonical active parameter tables. That makes Section 2 rerunnable within a session without requiring a full Section 1 reset. fileciteturn211file0

### 3. The active comparison auto-selection is conceptually right

The new optional `selected_comparison_group_id` design is a strong improvement. Section 2 now allows the operator to leave the comparison selector as `NULL`, and Section 2.10 derives the active comparison where the selected run maps unambiguously to a challenger comparison. The logic explicitly gives priority to an explicit CG selection, then auto-derives from selected challenger run, then uses `CG01` for `M2-01`, then derives from unique baseline usage, otherwise leaves the comparison unresolved. fileciteturn208file5

That means this becomes practical:

```sql
selected_module2_run_id = 'M2-29'
selected_comparison_group_id = NULL
```

and Section 2 should auto-resolve the active comparison to:

```text
CG15 — M2-28 vs M2-29
```

That is much better than asking the operator to remember both the run ID and comparison ID.

### 4. Product-policy catalog and compatibility map look right

The product-policy catalog now has executable profile rows rather than only commentary. The `PRODUCT_GUARDRAIL_PRODUCT_POLICY` row correctly uses `8500.00` for the unsecured personal loan `product_decline_min_requested_el`, and the revolving line guardrail row correctly uses the tightened values including `6500.00` for `product_decline_min_requested_el` and `16000.00` for `product_max_approved_amount`. fileciteturn212file13

The strategy-to-product-policy compatibility map is also correct. It maps:

```text
BASELINE_STRATEGY_PROFILE                  → BASELINE_PRODUCT_POLICY
TIGHTER_SYNTHETIC_RISK_PROFILE             → BASELINE_PRODUCT_POLICY
GROWTH_ORIENTED_PROFILE                    → GROWTH_PRODUCT_POLICY
TIGHTER_AFFORDABILITY_PROFILE              → AFFORDABILITY_TIGHT_PRODUCT_POLICY
COUNTEROFFER_FIRST_PROFILE                 → COUNTEROFFER_FIRST_PRODUCT_POLICY
PRODUCT_GUARDRAIL_PROFILE                  → PRODUCT_GUARDRAIL_PRODUCT_POLICY
MANUAL_REVIEW_REDUCTION_PROFILE            → BASELINE_PRODUCT_POLICY
CUSTOM_USER_DEFINED_STRATEGY_PROFILE       → CUSTOM_USER_DEFINED_PRODUCT_POLICY
```

That compatibility layer is exactly what we wanted: executable governance, not just comments. fileciteturn212file14

### 5. The campaign run catalog is materially better than the old hardcoding

The formal campaign catalog now cleanly derives `module2_run_id` from `run_sequence_number`, and the catalog starts correctly with `M2-01` as the `BASELINE_STRATEGY_PROFILE` / `BASELINE_PRODUCT_POLICY` baseline run, followed by the SC01 challengers. fileciteturn212file16

This is the right design choice:

```sql
'M2-' || LPAD(c.run_sequence_number::TEXT, 2, '0') AS module2_run_id
```

and downstream:

```sql
module2_run_id || '_' || strategy_name || '_' || strategy_version || '_RUN'
```

That preserves deterministic rerun identity without relying on database max values.

### 6. Section 3 is correctly redesigned around the new Section 2 contract

Section 3 now validates that the required redesigned Section 2 temp objects exist, including the operator selector, strategy catalog, product-policy catalog, compatibility map, campaign catalog, selected-run config, active parameter tables, comparison plan, and active comparison selection table. fileciteturn207file10

It also validates active selector cardinality, valid `run_mode`, selected-run cardinality, active strategy-card cardinality, required identity fields, deterministic `strategy_run_id`, strategy-profile catalog match, standard/custom mode coherence, source selection, archive controls, threshold ordering, decision conventions, product-policy completeness, and explicit comparison selector validity. fileciteturn207file11turn207file8

The Section 3 source validation is also strong. It detects scenario lineage column aliases, detects `module1_model_version` / `model_version`, detects APR-proxy aliases, requires core source columns, and explicitly allows `loan_term_months` to be null for revolving-line style products. fileciteturn210file0turn210file1

### 7. The Section 3 → Section 4 contract is preserved

Section 3 still materializes the key helper tables that Section 4 and later sections expect:

```text
tmp_m2_source_selection_scope
tmp_m2_campaign_registry_current_run_match
tmp_m2_comparison_campaign_registry_active_match
```

The end-of-section diagnostics and footer correctly state that these are created for Section 4, Section 13, and Section 16 usage. fileciteturn208file8

That matters because Section 4 is designed to validate its staged source against `tmp_m2_source_selection_scope`, so this redesign does not break the next-stage dependency. fileciteturn208file15

## Two cleanup items before moving to Section 4

### Cleanup 1 — Replace the comparison “one active row” index safely

This is the only item I would treat as an actual governance-hardening patch before moving on.

Your current Section 2.10D creates the right **new** index definition:

```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_comparison_campaign_registry_one_active
ON credit_decisioning_sim.strategy_comparison_campaign_registry (active_comparison_flag)
WHERE active_comparison_flag IS TRUE
  AND registry_active_flag IS TRUE;
```

That predicate is correct. fileciteturn209file1

However, because the old implementation used the **same index name** with a narrower predicate that did not include `registry_active_flag`, `CREATE INDEX IF NOT EXISTS` will not replace the existing older index if it already exists in your database. The old predicate could still constrain inactive registry rows if any older active flag remains. The earlier version used the same index name with only `WHERE active_comparison_flag IS TRUE`. fileciteturn209file2

I recommend replacing Section 2.10D with this safer version:

```sql
/*-----------------------------------------------------------------------------------------------
2.10D One-active-comparison governance index.

Purpose:
    Ensure that at most one active, registry-active comparison row exists for Section 13.

Migration note:
    Drop and recreate this index because earlier versions used the same index name with a narrower
    predicate that did not include registry_active_flag.
-----------------------------------------------------------------------------------------------*/

DROP INDEX IF EXISTS credit_decisioning_sim.idx_m2_strategy_comparison_campaign_registry_one_active;

CREATE UNIQUE INDEX idx_m2_strategy_comparison_campaign_registry_one_active
ON credit_decisioning_sim.strategy_comparison_campaign_registry (active_comparison_flag)
WHERE active_comparison_flag IS TRUE
  AND registry_active_flag IS TRUE;
```

This avoids a subtle migration problem.

### Cleanup 2 — Add two optional drops to Section 1.2

Section 2.0 already drops:

```text
tmp_m2_comparison_plan
tmp_m2_active_comparison_selection
```

so this is not a blocker. But Section 1 is the clean full-rerun reset, so I would also include those two drops in Section 1.2 or Section 1.4 for completeness. Section 2.0 already handles them correctly. fileciteturn211file0

Add:

```sql
DROP TABLE IF EXISTS tmp_m2_comparison_plan;
DROP TABLE IF EXISTS tmp_m2_active_comparison_selection;
```

This is just cleanup consistency.

## One documentation caution

Your header currently labels the script as:

```text
VERSION: V1.0 (FINAL VALIDATED RELEASE)
```

Because we are still integrating Section 2/3 redesign, Section 16.9, and any downstream compatibility updates, I would not call this “FINAL VALIDATED RELEASE” yet. The top of the uploaded file shows that wording. fileciteturn206file0

I would temporarily use:

```text
VERSION: V1.0 — INTEGRATION HARDENING CANDIDATE
```

Then switch back to:

```text
VERSION: V1.0 — FINAL VALIDATED RELEASE
```

only after the redesigned Sections 0–3, Section 16.9, and final Section 17 acceptance all run clean.

## Final readiness position

```text
SECTION 0:
    PASS — Stronger executive framing and correct baseline/challenger distinction.

SECTION 1:
    PASS WITH MINOR CLEANUP — Add two optional temp-table drops for comparison auto-selection helpers.

SECTION 2:
    PASS WITH ONE GOVERNANCE PATCH — Profile-driven architecture is correct; replace the comparison active-row index with DROP + CREATE to avoid stale old-index predicate risk.

SECTION 3:
    PASS — Correctly validates the redesigned Section 2 contract and preserves downstream helper tables for Section 4, Section 13, and Section 16.
```

My recommendation: apply the two small cleanup patches, then move to Section 4.
<!-- END_MESSAGE C038-M01481 -->


---

<a id="c038-m01482"></a>

### C038-M01482

**Andrew** · 2026-05-12T07:53:15.898000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01482 -->
earlier you mentioned a specific pass and deliverable roadmap.  Is section 4 the correct next update to work on?
<!-- END_MESSAGE C038-M01482 -->


---

<a id="c038-m01486"></a>

### C038-M01486

**ChatGPT** · 2026-05-12T07:55:50.251180-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01486 -->
You’re right to pause. Based on the roadmap I laid out earlier, **Section 4 is not the next major architectural deliverable**.

The original roadmap was:

```text
Deliverable 1:
    Section 0
    Section 1
    Redesigned Section 2
    Updated Section 3

Deliverable 2:
    Section 15 header / workflow update
    Section 16 header / workflow update
    New Section 16.9 frontier evidence synchronization
    Section 17 header / final acceptance workflow update

Deliverable 3:
    Section-by-section commentary tightening across Sections 4–14 and 16–17
```

So, strictly following that plan, the correct next major update is **Section 16.9 plus the related Section 15 / 16 / 17 workflow alignment**, not Section 4. Section 0 already references the full-campaign flow where users rerun Section 15, run Section 16.9, and then run Section 17, so we should make that workflow real before doing a broad commentary pass. fileciteturn211file0

That said, **Section 4 is the next operational SQL section after Section 3**, so it is a reasonable next section only if we are switching into the sequential commentary / compatibility pass. Section 4 is the Module 1 → Module 2 handoff layer and consumes the Section 3 helper objects, including `tmp_m2_source_selection_scope` and `tmp_m2_campaign_registry_current_run_match`. fileciteturn211file31

## My recommendation

Do **not** start the full Section 4 commentary pass yet.

I would proceed in this order:

```text
1. Apply the two small cleanup patches from the Sections 0–3 review.
   - Section 1: add drops for tmp_m2_comparison_plan and tmp_m2_active_comparison_selection.
   - Section 2.10D: drop/recreate the one-active-comparison index.

2. Build Section 16.9.
   - This formalizes the post-campaign frontier evidence synchronization.
   - It removes the awkward manual “rerun Section 15, then patch evidence rows” process.

3. Update Section 15 / Section 16 / Section 17 headers and job-aid language.
   - Make the full-campaign workflow clear:
       run all campaign runs through Section 16.8;
       rerun Section 15;
       run Section 16.9;
       run Section 17.

4. Then start the Section 4–14 commentary and compatibility tightening pass.
```

## Why not Section 4 immediately?

Because the biggest unresolved workflow issue is not in Section 4. It is the **post-campaign evidence refresh problem**. We already identified that Section 15 is archive-wide, while Section 16 captures evidence one run at a time. Without a formal Section 16.9, the job aid is harder to explain and users may need an informal patch after campaign reruns.

Section 16 already depends on Section 15 frontier outputs and persists executive evidence rows, parameter snapshots, and segment evidence. fileciteturn211file11 Section 15 already produces the archive-backed frontier classification and executive frontier summary that Section 16 consumes. fileciteturn211file14 The missing piece is the formal synchronization block.

## Where Section 4 fits next

After Section 16.9 is added, Section 4 becomes the correct next section for the broader tightening pass.

When we get to Section 4, I would not redesign it heavily. I would focus on:

```text
1. Commentary tightening:
    Make the Module 1 → Module 2 handoff sharper and less verbose.

2. New architecture alignment:
    Reflect that Section 2 is now profile-driven and Section 3 validates the selected source scope.

3. Alias consistency:
    Ensure Section 4 mirrors any source-column alias handling that Section 3 validates.

4. Run interpretation:
    Explain what to look for in the Section 4 outputs:
        row count,
        product-policy match,
        source lineage,
        normalized product key,
        requested_* aliases,
        no premature decision fields.

5. SQL teaching:
    Explain how dynamic source selection, lineage normalization, product-key derivation, and validation-only product-policy joins work.
```

So the clean answer is:

```text
Next major deliverable:
    Section 16.9 + Section 15/16/17 workflow headers.

Next sequential commentary section:
    Section 4.

Recommended next step:
    Do Section 16.9 first, then begin Section 4.
```
<!-- END_MESSAGE C038-M01486 -->


---

<a id="c038-m01488"></a>

### C038-M01488

**Andrew** · 2026-05-12T08:04:16.746000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01488 -->
Since the responses seem to error if we try too much in one prompt, let's do section 16.9, section 15, 16, and 17 one at a time.  Proceed in the order that makes sense and do the first of those 4 updates.  provide back the full copy paste code.
<!-- END_MESSAGE C038-M01488 -->


---

<a id="c038-m01494"></a>

### C038-M01494

**ChatGPT** · 2026-05-12T08:10:48.226868-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01494 -->
Proceeding first with **Section 16.9**, because it directly fixes the awkward post-campaign workflow we identified: after the full campaign, rerun Section 15 from the completed archive, then run this synchronization block, then run Section 17. Section 15 already produces the archive-backed `tmp_m2_strategy_frontier_executive_summary`, and Section 16.6 stores Section 15-derived frontier fields inside `strategy_run_evidence_summary`, including `frontier_position_type`, `executive_frontier_quadrant`, `frontier_interpretation_note`, and reason-code delta driver fields. fileciteturn214file3 fileciteturn214file4

```sql
/***************************************************************************************************
SECTION 16.9 — POST-CAMPAIGN FRONTIER EVIDENCE SYNCHRONIZATION
****************************************************************************************************

BUSINESS PURPOSE:
    Refresh Section 15-derived frontier fields in the persistent executive evidence table after the
    full campaign archive is complete.

    Section 16.9 answers:

        "After the full campaign archive has been finalized and Section 15 has been rerun, do the
         persistent executive evidence rows reflect the newest archive-backed frontier labels,
         executive frontier quadrant, interpretation note, and baseline-relative reason-code movement
         fields?"

WHY THIS SECTION EXISTS:
    Section 15 is archive-wide.

    Section 16 evidence capture is run-level.

    During a full campaign, early evidence rows may be captured before every baseline / challenger
    strategy slice exists in the archive. After additional runs or reruns are completed, a fresh
    Section 15 run may produce improved frontier labels and baseline-relative movement fields.

    Without Section 16.9, the user would need to run an informal manual patch.

    Section 16.9 formalizes that refresh.

WHEN TO RUN:
    Full campaign workflow:
        1. Run each planned campaign run through Section 16.8.
        2. Rerun Section 15 once from the completed archive.
        3. Run Section 16.9.
        4. Run Section 17.

IMPORTANT:
    Do not run Section 1 immediately before Section 16.9 unless Section 15 is rerun afterward.

    Section 16.9 requires:
        tmp_m2_strategy_frontier_executive_summary

    That table is created by Section 15 and is temporary to the active SQL session.

WHAT THIS SECTION UPDATES:
    credit_decisioning_sim.strategy_run_evidence_summary

    Fields refreshed from fresh Section 15 output:
        frontier_position_type
        executive_frontier_quadrant
        frontier_interpretation_note
        top_reason_code_delta_driver_family
        top_reason_code_delta_driver_code
        top_reason_code_delta_driver_baseline_share
        top_reason_code_delta_driver_strategy_share
        top_reason_code_delta_population_share

WHAT THIS SECTION DOES NOT UPDATE:
    This section does not update:
        latest-run outputs,
        archive rows,
        validation status rows,
        parameter snapshots,
        segment evidence rows,
        strategy parameters,
        product-policy parameters,
        decision outcomes,
        approved exposure,
        approved Expected Loss,
        simulated reason codes,
        observed_storyline,
        validation_notes.

WHY observed_storyline IS NOT UPDATED:
    observed_storyline may contain user-authored interpretation from the current run.

    Section 16.9 updates only deterministic Section 15-derived frontier fields. It does not overwrite
    analyst narrative.

EVIDENCE GRAIN:
    Synchronization is matched on the technical run key:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

SQL TEACHING POINT:
    This section uses a pre-update candidate table and a post-update check.

    The candidate table shows what would change.
    The UPDATE applies only matched rows with field differences.
    The post-check confirms that matched rows now agree with fresh Section 15 output.

INTERPRETATION:
    Rows updated > 0:
        expected when earlier evidence rows had stale frontier fields.

    Rows updated = 0:
        acceptable when evidence already reflects the current Section 15 frontier state.

    Unmatched evidence rows:
        review signal only. They may represent custom / non-archived / old evidence rows.

    Matched rows still mismatched after sync:
        fail-fast condition.

BOUNDARY:
    Section 16.9 is evidence synchronization only.

    It does not recalculate frontier logic.
    It does not rebuild Section 15.
    It does not modify archive history.
    It does not modify latest-run output.
    It does not create or remove campaign registry rows.
    It does not validate final campaign acceptance.

***************************************************************************************************/



/***************************************************************************************************
SECTION 16.9A — LOCAL RESET OF FRONTIER SYNCHRONIZATION HELPERS
****************************************************************************************************

PURPOSE:
    Remove prior Section 16.9 helper objects before rebuilding the synchronization audit from the
    current Section 15 frontier output.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_frontier_evidence_sync_candidates;
DROP TABLE IF EXISTS tmp_m2_frontier_evidence_sync_update_result;
DROP TABLE IF EXISTS tmp_m2_frontier_evidence_sync_postcheck;



/***************************************************************************************************
SECTION 16.9B — PREFLIGHT GATEKEEPERS
****************************************************************************************************

PURPOSE:
    Confirm that the persistent evidence table and fresh Section 15 frontier output are available,
    non-empty, and unique at the run key before synchronization starts.

***************************************************************************************************/

DO $$
DECLARE
    v_evidence_table_regclass              REGCLASS;
    v_frontier_table_regclass              REGCLASS;

    v_missing_evidence_columns             TEXT;
    v_missing_frontier_columns             TEXT;

    v_evidence_rows                        BIGINT;
    v_frontier_rows                        BIGINT;

    v_evidence_duplicate_key_count          BIGINT;
    v_frontier_duplicate_key_count          BIGINT;
BEGIN
    /***********************************************************************************************
    Locate the persistent executive evidence table and the temporary Section 15 frontier table.

    to_regclass returns NULL when an object does not exist.
    ***********************************************************************************************/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_run_evidence_summary')
    INTO v_evidence_table_regclass;

    SELECT TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary')
    INTO v_frontier_table_regclass;

    IF v_evidence_table_regclass IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: credit_decisioning_sim.strategy_run_evidence_summary does not exist. Run Section 16 evidence capture before synchronization.';
    END IF;

    IF v_frontier_table_regclass IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: tmp_m2_strategy_frontier_executive_summary does not exist. Rerun Section 15 immediately before Section 16.9.';
    END IF;


    /***********************************************************************************************
    Confirm required columns exist in the persistent executive evidence table.
    ***********************************************************************************************/
    WITH required_columns AS (
        SELECT *
        FROM (
            VALUES
                ('strategy_set_name'),
                ('strategy_name'),
                ('strategy_version'),
                ('module1_scenario_set_name'),
                ('module1_scenario_name'),
                ('population_id'),

                ('frontier_position_type'),
                ('executive_frontier_quadrant'),
                ('frontier_interpretation_note'),

                ('top_reason_code_delta_driver_family'),
                ('top_reason_code_delta_driver_code'),
                ('top_reason_code_delta_driver_baseline_share'),
                ('top_reason_code_delta_driver_strategy_share'),
                ('top_reason_code_delta_population_share')
        ) AS v(column_name)
    )

    SELECT STRING_AGG(column_name, ', ' ORDER BY column_name)
    INTO v_missing_evidence_columns
    FROM required_columns rc
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_attribute a
        WHERE a.attrelid = v_evidence_table_regclass
          AND a.attname = rc.column_name
          AND a.attisdropped IS FALSE
    );

    IF v_missing_evidence_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: strategy_run_evidence_summary is missing required column(s): %.',
            v_missing_evidence_columns;
    END IF;


    /***********************************************************************************************
    Confirm required columns exist in the fresh Section 15 frontier summary.
    ***********************************************************************************************/
    WITH required_columns AS (
        SELECT *
        FROM (
            VALUES
                ('strategy_set_name'),
                ('strategy_name'),
                ('strategy_version'),
                ('module1_scenario_set_name'),
                ('module1_scenario_name'),
                ('population_id'),

                ('frontier_position_type'),
                ('executive_frontier_quadrant'),
                ('frontier_interpretation_note'),

                ('top_reason_code_delta_driver_family'),
                ('top_reason_code_delta_driver_code'),
                ('top_reason_code_delta_driver_baseline_share'),
                ('top_reason_code_delta_driver_strategy_share'),
                ('top_reason_code_delta_population_share')
        ) AS v(column_name)
    )

    SELECT STRING_AGG(column_name, ', ' ORDER BY column_name)
    INTO v_missing_frontier_columns
    FROM required_columns rc
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_attribute a
        WHERE a.attrelid = v_frontier_table_regclass
          AND a.attname = rc.column_name
          AND a.attisdropped IS FALSE
    );

    IF v_missing_frontier_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: tmp_m2_strategy_frontier_executive_summary is missing required column(s): %.',
            v_missing_frontier_columns;
    END IF;


    /***********************************************************************************************
    Non-empty evidence and frontier checks.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_evidence_rows
    FROM credit_decisioning_sim.strategy_run_evidence_summary;

    SELECT COUNT(*)
    INTO v_frontier_rows
    FROM tmp_m2_strategy_frontier_executive_summary;

    IF v_evidence_rows = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: strategy_run_evidence_summary contains zero rows. Capture Section 16 evidence before synchronization.';
    END IF;

    IF v_frontier_rows = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: tmp_m2_strategy_frontier_executive_summary contains zero rows. Rerun Section 15 from the completed archive.';
    END IF;


    /***********************************************************************************************
    Duplicate-key checks.

    Synchronization must be one frontier row to one evidence row at the technical run key.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_evidence_duplicate_key_count
    FROM (
        SELECT
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id,
            COUNT(*) AS row_count
        FROM credit_decisioning_sim.strategy_run_evidence_summary
        GROUP BY
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        HAVING COUNT(*) > 1
    ) d;

    IF v_evidence_duplicate_key_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: strategy_run_evidence_summary has % duplicate technical run key(s). Resolve duplicate evidence rows before frontier synchronization.',
            v_evidence_duplicate_key_count;
    END IF;

    SELECT COUNT(*)
    INTO v_frontier_duplicate_key_count
    FROM (
        SELECT
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id,
            COUNT(*) AS row_count
        FROM tmp_m2_strategy_frontier_executive_summary
        GROUP BY
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        HAVING COUNT(*) > 1
    ) d;

    IF v_frontier_duplicate_key_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: tmp_m2_strategy_frontier_executive_summary has % duplicate technical run key(s). Rerun / review Section 15 before synchronization.',
            v_frontier_duplicate_key_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 16.9C — BUILD PRE-UPDATE SYNCHRONIZATION CANDIDATES
****************************************************************************************************

PURPOSE:
    Compare persistent executive evidence rows to fresh Section 15 frontier rows and identify which
    evidence rows need synchronization.

SQL LOGIC:
    1. Start from persistent strategy_run_evidence_summary.
    2. Left join to tmp_m2_strategy_frontier_executive_summary on technical run key.
    3. Compare each Section 15-derived field using IS DISTINCT FROM.
    4. Calculate a mismatch count and row-level sync action.

WHY IS DISTINCT FROM:
    IS DISTINCT FROM treats NULLs explicitly.

    NULL versus non-NULL is a mismatch.
    NULL versus NULL is not a mismatch.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_candidates
ON COMMIT PRESERVE ROWS
AS
WITH field_compare AS (
    SELECT
        /*******************************************************************************************
        Technical run key.
        *******************************************************************************************/
        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,

        /*******************************************************************************************
        Optional campaign IDs for review readability.
        *******************************************************************************************/
        e.module1_run_id,
        e.module2_run_id,
        e.run_sequence_number,
        e.showcase_id,
        e.showcase_name,
        e.comparison_group_id,
        e.validation_evidence_group_id,

        /*******************************************************************************************
        Match diagnostic.
        *******************************************************************************************/
        CASE
            WHEN f.strategy_set_name IS NOT NULL
                THEN TRUE
            ELSE FALSE
        END AS frontier_match_flag,

        /*******************************************************************************************
        Current persistent evidence values.
        *******************************************************************************************/
        e.frontier_position_type
            AS evidence_frontier_position_type,

        e.executive_frontier_quadrant
            AS evidence_executive_frontier_quadrant,

        e.frontier_interpretation_note
            AS evidence_frontier_interpretation_note,

        e.top_reason_code_delta_driver_family
            AS evidence_top_reason_code_delta_driver_family,

        e.top_reason_code_delta_driver_code
            AS evidence_top_reason_code_delta_driver_code,

        e.top_reason_code_delta_driver_baseline_share
            AS evidence_top_reason_code_delta_driver_baseline_share,

        e.top_reason_code_delta_driver_strategy_share
            AS evidence_top_reason_code_delta_driver_strategy_share,

        e.top_reason_code_delta_population_share
            AS evidence_top_reason_code_delta_population_share,

        /*******************************************************************************************
        Fresh Section 15 values.
        *******************************************************************************************/
        f.frontier_position_type
            AS section15_frontier_position_type,

        f.executive_frontier_quadrant
            AS section15_executive_frontier_quadrant,

        f.frontier_interpretation_note
            AS section15_frontier_interpretation_note,

        f.top_reason_code_delta_driver_family
            AS section15_top_reason_code_delta_driver_family,

        f.top_reason_code_delta_driver_code
            AS section15_top_reason_code_delta_driver_code,

        f.top_reason_code_delta_driver_baseline_share
            AS section15_top_reason_code_delta_driver_baseline_share,

        f.top_reason_code_delta_driver_strategy_share
            AS section15_top_reason_code_delta_driver_strategy_share,

        f.top_reason_code_delta_population_share
            AS section15_top_reason_code_delta_population_share,

        /*******************************************************************************************
        Field-level mismatch flags.
        *******************************************************************************************/
        (
            e.frontier_position_type
            IS DISTINCT FROM f.frontier_position_type
        ) AS frontier_position_type_mismatch_flag,

        (
            e.executive_frontier_quadrant
            IS DISTINCT FROM f.executive_frontier_quadrant
        ) AS executive_frontier_quadrant_mismatch_flag,

        (
            e.frontier_interpretation_note
            IS DISTINCT FROM f.frontier_interpretation_note
        ) AS frontier_interpretation_note_mismatch_flag,

        (
            e.top_reason_code_delta_driver_family
            IS DISTINCT FROM f.top_reason_code_delta_driver_family
        ) AS top_reason_code_delta_driver_family_mismatch_flag,

        (
            e.top_reason_code_delta_driver_code
            IS DISTINCT FROM f.top_reason_code_delta_driver_code
        ) AS top_reason_code_delta_driver_code_mismatch_flag,

        (
            e.top_reason_code_delta_driver_baseline_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_baseline_share
        ) AS top_reason_code_delta_driver_baseline_share_mismatch_flag,

        (
            e.top_reason_code_delta_driver_strategy_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_strategy_share
        ) AS top_reason_code_delta_driver_strategy_share_mismatch_flag,

        (
            e.top_reason_code_delta_population_share
            IS DISTINCT FROM f.top_reason_code_delta_population_share
        ) AS top_reason_code_delta_population_share_mismatch_flag

    FROM credit_decisioning_sim.strategy_run_evidence_summary e

    LEFT JOIN tmp_m2_strategy_frontier_executive_summary f
        ON f.strategy_set_name = e.strategy_set_name
       AND f.strategy_name = e.strategy_name
       AND f.strategy_version = e.strategy_version
       AND f.module1_scenario_set_name = e.module1_scenario_set_name
       AND f.module1_scenario_name = e.module1_scenario_name
       AND f.population_id = e.population_id
)

SELECT
    fc.*,

    /***********************************************************************************************
    Count only mismatches for matched frontier rows.

    Unmatched rows are reviewed separately and are not updated.
    ***********************************************************************************************/
    CASE
        WHEN fc.frontier_match_flag IS TRUE
            THEN (
                fc.frontier_position_type_mismatch_flag::INT
                + fc.executive_frontier_quadrant_mismatch_flag::INT
                + fc.frontier_interpretation_note_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_family_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_code_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_baseline_share_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_strategy_share_mismatch_flag::INT
                + fc.top_reason_code_delta_population_share_mismatch_flag::INT
            )
        ELSE NULL
    END AS frontier_field_mismatch_count,

    CASE
        WHEN fc.frontier_match_flag IS DISTINCT FROM TRUE
            THEN 'NO_MATCHING_SECTION_15_FRONTIER_ROW_REVIEW'

        WHEN (
                fc.frontier_position_type_mismatch_flag::INT
                + fc.executive_frontier_quadrant_mismatch_flag::INT
                + fc.frontier_interpretation_note_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_family_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_code_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_baseline_share_mismatch_flag::INT
                + fc.top_reason_code_delta_driver_strategy_share_mismatch_flag::INT
                + fc.top_reason_code_delta_population_share_mismatch_flag::INT
             ) > 0
            THEN 'SYNC_FRONTIER_FIELDS_FROM_SECTION_15'

        ELSE 'FRONTIER_FIELDS_ALREADY_CURRENT'
    END AS frontier_sync_action

FROM field_compare fc;



/***************************************************************************************************
SECTION 16.9D — APPLY FRONTIER FIELD SYNCHRONIZATION
****************************************************************************************************

PURPOSE:
    Update only matched evidence rows where Section 15-derived frontier fields differ.

SQL LOGIC:
    UPDATE uses the candidate table built in Section 16.9C.

    Rows with no matching Section 15 frontier row are not updated.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_update_result
ON COMMIT PRESERVE ROWS
AS
WITH updated AS (
    UPDATE credit_decisioning_sim.strategy_run_evidence_summary e
    SET
        /*******************************************************************************************
        Frontier posture fields.
        *******************************************************************************************/
        frontier_position_type =
            c.section15_frontier_position_type,

        executive_frontier_quadrant =
            c.section15_executive_frontier_quadrant,

        frontier_interpretation_note =
            c.section15_frontier_interpretation_note,

        /*******************************************************************************************
        Baseline-relative reason-code movement fields.
        *******************************************************************************************/
        top_reason_code_delta_driver_family =
            c.section15_top_reason_code_delta_driver_family,

        top_reason_code_delta_driver_code =
            c.section15_top_reason_code_delta_driver_code,

        top_reason_code_delta_driver_baseline_share =
            c.section15_top_reason_code_delta_driver_baseline_share,

        top_reason_code_delta_driver_strategy_share =
            c.section15_top_reason_code_delta_driver_strategy_share,

        top_reason_code_delta_population_share =
            c.section15_top_reason_code_delta_population_share

    FROM tmp_m2_frontier_evidence_sync_candidates c

    WHERE c.frontier_match_flag IS TRUE
      AND c.frontier_field_mismatch_count > 0

      AND e.strategy_set_name = c.strategy_set_name
      AND e.strategy_name = c.strategy_name
      AND e.strategy_version = c.strategy_version
      AND e.module1_scenario_set_name = c.module1_scenario_set_name
      AND e.module1_scenario_name = c.module1_scenario_name
      AND e.population_id = c.population_id

    RETURNING
        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id
)

SELECT
    CURRENT_TIMESTAMP AS frontier_evidence_sync_ts,
    COUNT(*) AS evidence_rows_updated
FROM updated;



/***************************************************************************************************
SECTION 16.9E — POST-SYNCHRONIZATION CHECK
****************************************************************************************************

PURPOSE:
    Confirm that every evidence row with a matching fresh Section 15 frontier row now has aligned
    Section 15-derived frontier fields.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_postcheck
ON COMMIT PRESERVE ROWS
AS
WITH post_compare AS (
    SELECT
        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,

        CASE
            WHEN f.strategy_set_name IS NOT NULL
                THEN TRUE
            ELSE FALSE
        END AS frontier_match_flag,

        (
            e.frontier_position_type
            IS DISTINCT FROM f.frontier_position_type
        ) AS frontier_position_type_mismatch_flag,

        (
            e.executive_frontier_quadrant
            IS DISTINCT FROM f.executive_frontier_quadrant
        ) AS executive_frontier_quadrant_mismatch_flag,

        (
            e.frontier_interpretation_note
            IS DISTINCT FROM f.frontier_interpretation_note
        ) AS frontier_interpretation_note_mismatch_flag,

        (
            e.top_reason_code_delta_driver_family
            IS DISTINCT FROM f.top_reason_code_delta_driver_family
        ) AS top_reason_code_delta_driver_family_mismatch_flag,

        (
            e.top_reason_code_delta_driver_code
            IS DISTINCT FROM f.top_reason_code_delta_driver_code
        ) AS top_reason_code_delta_driver_code_mismatch_flag,

        (
            e.top_reason_code_delta_driver_baseline_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_baseline_share
        ) AS top_reason_code_delta_driver_baseline_share_mismatch_flag,

        (
            e.top_reason_code_delta_driver_strategy_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_strategy_share
        ) AS top_reason_code_delta_driver_strategy_share_mismatch_flag,

        (
            e.top_reason_code_delta_population_share
            IS DISTINCT FROM f.top_reason_code_delta_population_share
        ) AS top_reason_code_delta_population_share_mismatch_flag

    FROM credit_decisioning_sim.strategy_run_evidence_summary e

    LEFT JOIN tmp_m2_strategy_frontier_executive_summary f
        ON f.strategy_set_name = e.strategy_set_name
       AND f.strategy_name = e.strategy_name
       AND f.strategy_version = e.strategy_version
       AND f.module1_scenario_set_name = e.module1_scenario_set_name
       AND f.module1_scenario_name = e.module1_scenario_name
       AND f.population_id = e.population_id
),

post_summary AS (
    SELECT
        COUNT(*) AS evidence_rows_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS TRUE
        ) AS matched_evidence_rows_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS DISTINCT FROM TRUE
        ) AS unmatched_evidence_rows_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS TRUE
              AND (
                    frontier_position_type_mismatch_flag
                 OR executive_frontier_quadrant_mismatch_flag
                 OR frontier_interpretation_note_mismatch_flag
                 OR top_reason_code_delta_driver_family_mismatch_flag
                 OR top_reason_code_delta_driver_code_mismatch_flag
                 OR top_reason_code_delta_driver_baseline_share_mismatch_flag
                 OR top_reason_code_delta_driver_strategy_share_mismatch_flag
                 OR top_reason_code_delta_population_share_mismatch_flag
              )
        ) AS matched_rows_with_frontier_mismatch_after_sync

    FROM post_compare
)

SELECT
    ps.*,

    u.evidence_rows_updated,

    CASE
        WHEN ps.matched_evidence_rows_after_sync = 0
            THEN 'FRONTIER_EVIDENCE_SYNC_NO_MATCHED_EVIDENCE_ROWS_REVIEW'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync = 0
            THEN 'FRONTIER_EVIDENCE_SYNC_READY_ALL_EVIDENCE_ROWS_MATCH_SECTION_15'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync > 0
            THEN 'FRONTIER_EVIDENCE_SYNC_READY_WITH_UNMATCHED_EVIDENCE_ROWS_REVIEW'

        ELSE 'FRONTIER_EVIDENCE_SYNC_MISMATCH_REVIEW_REQUIRED'
    END AS frontier_evidence_sync_status,

    CASE
        WHEN ps.matched_evidence_rows_after_sync = 0
            THEN 'No persistent executive evidence rows matched the fresh Section 15 frontier output. Confirm Section 15 was rerun from the completed archive and evidence rows use the same technical run keys.'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync = 0
            THEN 'All persistent executive evidence rows match the fresh Section 15 frontier output.'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync > 0
            THEN 'All matched evidence rows were synchronized. Unmatched evidence rows remain for review; these may be custom, non-archived, or legacy evidence rows.'

        ELSE 'One or more matched evidence rows still differ from Section 15 output after synchronization.'
    END AS frontier_evidence_sync_interpretation

FROM post_summary ps

CROSS JOIN tmp_m2_frontier_evidence_sync_update_result u;



/***************************************************************************************************
SECTION 16.9F — POST-SYNCHRONIZATION FAIL-FAST CHECK
****************************************************************************************************

PURPOSE:
    Fail only when matched evidence rows still disagree with fresh Section 15 output.

BOUNDARY:
    Unmatched evidence rows do not fail this section automatically.

    They are review items because they may represent custom or non-campaign evidence outside the
    current archive frontier.

***************************************************************************************************/

DO $$
DECLARE
    v_matched_rows_after_sync                 BIGINT;
    v_matched_mismatch_rows_after_sync         BIGINT;
    v_sync_status                             TEXT;
BEGIN
    SELECT
        matched_evidence_rows_after_sync,
        matched_rows_with_frontier_mismatch_after_sync,
        frontier_evidence_sync_status
    INTO
        v_matched_rows_after_sync,
        v_matched_mismatch_rows_after_sync,
        v_sync_status
    FROM tmp_m2_frontier_evidence_sync_postcheck
    LIMIT 1;

    IF v_matched_rows_after_sync = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: no persistent executive evidence rows matched fresh Section 15 frontier output.';
    END IF;

    IF v_matched_mismatch_rows_after_sync > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: % matched evidence row(s) still disagree with fresh Section 15 frontier output after synchronization. Status: %.',
            v_matched_mismatch_rows_after_sync,
            v_sync_status;
    END IF;
END $$;



/***************************************************************************************************
SECTION 16.9G — FRONTIER SYNCHRONIZATION REVIEW OUTPUTS
****************************************************************************************************

PURPOSE:
    Display the synchronization result and the rows that were updated or still require review.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.9G.1 Synchronization status summary.

Expected:
    frontier_evidence_sync_status should be either:
        FRONTIER_EVIDENCE_SYNC_READY_ALL_EVIDENCE_ROWS_MATCH_SECTION_15
        FRONTIER_EVIDENCE_SYNC_READY_WITH_UNMATCHED_EVIDENCE_ROWS_REVIEW

Interpretation:
    evidence_rows_updated:
        number of executive evidence rows refreshed from Section 15.

    unmatched_evidence_rows_after_sync:
        evidence rows with no matching current Section 15 frontier row.
-----------------------------------------------------------------------------------------------*/

SELECT
    *
FROM tmp_m2_frontier_evidence_sync_postcheck;



/*-----------------------------------------------------------------------------------------------
16.9G.2 Rows updated by synchronization.

Purpose:
    Show the rows whose persistent evidence frontier fields were stale before this sync.

Interpretation:
    These rows are expected after campaign reruns or when early campaign evidence was captured before
    all comparison slices were archived.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    evidence_frontier_position_type,
    section15_frontier_position_type,

    evidence_executive_frontier_quadrant,
    section15_executive_frontier_quadrant,

    evidence_frontier_interpretation_note,
    section15_frontier_interpretation_note,

    evidence_top_reason_code_delta_driver_code,
    section15_top_reason_code_delta_driver_code,

    frontier_field_mismatch_count,
    frontier_sync_action

FROM tmp_m2_frontier_evidence_sync_candidates

WHERE frontier_sync_action = 'SYNC_FRONTIER_FIELDS_FROM_SECTION_15'

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    run_sequence_number NULLS LAST,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
16.9G.3 Unmatched evidence rows for review.

Purpose:
    Identify persistent executive evidence rows that did not match the fresh Section 15 frontier
    output.

Common causes:
    custom evidence rows,
    non-archived evidence rows,
    older evidence from a prior campaign design,
    archive rows not currently represented in Section 15.

Action:
    Review before final documentation if these are expected to be part of the formal campaign.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    evidence_frontier_position_type,
    evidence_executive_frontier_quadrant,
    evidence_top_reason_code_delta_driver_code,

    frontier_sync_action

FROM tmp_m2_frontier_evidence_sync_candidates

WHERE frontier_match_flag IS DISTINCT FROM TRUE

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    run_sequence_number NULLS LAST,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
16.9G.4 Matched evidence rows after synchronization.

Purpose:
    Show the final synchronized frontier fields that will be consumed by Section 17 and executive
    evidence review.
-----------------------------------------------------------------------------------------------*/

SELECT
    e.module1_run_id,
    e.module2_run_id,
    e.run_sequence_number,
    e.showcase_id,
    e.showcase_name,
    e.comparison_group_id,
    e.validation_evidence_group_id,

    e.strategy_set_name,
    e.strategy_name,
    e.strategy_version,
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,

    e.frontier_position_type,
    e.executive_frontier_quadrant,
    e.frontier_interpretation_note,

    e.top_reason_code_delta_driver_family,
    e.top_reason_code_delta_driver_code,
    e.top_reason_code_delta_driver_baseline_share,
    e.top_reason_code_delta_driver_strategy_share,
    e.top_reason_code_delta_population_share

FROM credit_decisioning_sim.strategy_run_evidence_summary e

JOIN tmp_m2_strategy_frontier_executive_summary f
    ON f.strategy_set_name = e.strategy_set_name
   AND f.strategy_name = e.strategy_name
   AND f.strategy_version = e.strategy_version
   AND f.module1_scenario_set_name = e.module1_scenario_set_name
   AND f.module1_scenario_name = e.module1_scenario_name
   AND f.population_id = e.population_id

ORDER BY
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,
    e.strategy_set_name,
    e.run_sequence_number NULLS LAST,
    CASE
        WHEN e.strategy_name = 'BASELINE_STRATEGY' THEN 1
        ELSE 2
    END,
    e.strategy_name,
    e.strategy_version;



/***************************************************************************************************
END OF SECTION 16.9 — POST-CAMPAIGN FRONTIER EVIDENCE SYNCHRONIZATION

If execution reaches this point:
    1. Fresh Section 15 frontier output exists.
    2. Persistent executive evidence exists.
    3. Section 15-derived frontier fields have been refreshed for all matching evidence rows.
    4. Matched evidence rows now align with fresh Section 15 frontier output.
    5. Unmatched evidence rows, if any, have been surfaced for review.
    6. Section 17 can be run for final post-campaign acceptance.

Next:
    Run Section 17 after reviewing the Section 16.9 synchronization summary.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01494 -->


---

<a id="c038-m01496"></a>

### C038-M01496

**Andrew** · 2026-05-12T08:15:57.416000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01496 -->
16.8 had ended with this: /***************************************************************************************************
END OF SECTION 16.0-16.8 — STRATEGY RUN EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER

If execution reaches this point:
    1. Persistent executive run evidence summary has been created or reused.
    2. Persistent validation evidence detail has been created or reused.
    3. Persistent strategy and product-policy parameter snapshot evidence has been created or reused.
    4. Persistent product × score segment evidence summary has been created or reused.
    5. Prior evidence rows for the current run key were replaced in the evidence tables only.
    6. Current Section 14 validation evidence detail was persisted.
    7. Current strategy, product-policy, and story parameter snapshots were persisted.
    8. Current product × score segment evidence was persisted.
    9. Current one-row executive evidence summary was persisted.
    10. Local Section 16 evidence-capture gatekeepers passed.
    11. Evidence object row-count diagnostics are available.
    12. Current executive evidence summary output is available.
    13. REVIEW / NOT_APPLICABLE validation evidence rows are available for documentation review.
    14. Product × score companion evidence is available for executive driver review.
    15. Parameter snapshot diagnostics are available.
    16. Registry-linkage consistency diagnostics are available.
    17. Module 3 readiness fields have been captured for future growth / economics design.

Registry evidence now carries:
    module1_run_id
    module2_run_id
    run_sequence_number
    showcase_id
    showcase_name
    comparison_group_id
    validation_evidence_group_id
    readme_storyline_label
    linkedin_post_sequence
    validation_summary_section_hint
    run_registry_match_status

Section 16 established:
    1. Persistent executive story evidence.
    2. Persistent validation evidence detail.
    3. Persistent strategy and product-policy parameter snapshots.
    4. Persistent product × score segment evidence.
    5. Module 3 readiness fields for future growth / earnings design.
    6. Product, score-band, and product × score executive driver fields.
    7. Reason-code storytelling fields for executive interpretation.
    8. Compact export-ready diagnostics after every run.
    9. Registry-backed evidence traceability for campaign and validation documentation.

No latest-run output rows have been modified.
No archive rows have been modified.
No campaign registry rows have been modified.
No strategy parameter rows have been modified.
No product policy parameter rows have been modified.
No decision outcomes have been recalculated.
No approved exposure values have been recalculated.
No approved Expected Loss values have been recalculated.
No simulated reason codes have been reassigned.
No revenue logic has been implemented.
No earnings logic has been implemented.
No pricing optimization logic has been implemented.
No funding-cost logic has been implemented.
No profitability logic has been implemented.
No capital logic has been implemented.
No risk-adjusted margin logic has been implemented.

***************************************************************************************************/     should we keep that + have the ending to 16.9 how you have it? what do you recommend?
<!-- END_MESSAGE C038-M01496 -->


---

<a id="c038-m01498"></a>

### C038-M01498

**ChatGPT** · 2026-05-12T08:18:14.736175-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01498 -->
Yes — I recommend keeping a distinct **end-of-Section-16.0–16.8 footer**, then adding a separate **end-of-Section-16.9 footer**.

But I would **tighten the 16.8 footer** slightly. The footer you pasted is directionally right, but it is long and risks making readers think Section 16 is fully complete before the post-campaign synchronization step. Section 16.8 is the end of **run-level evidence capture**, while Section 16.9 is a separate **post-campaign evidence synchronization** step.

That distinction matters because Section 16.8 is a review/export-ready diagnostics layer after evidence capture, and its boundary is read-only for that subsection. fileciteturn215file5 Section 16.6, however, persists Section 15-derived frontier posture fields into the executive evidence row at run-capture time, which is exactly why a later post-campaign refresh can be needed after Section 15 is rerun from the completed archive. fileciteturn215file7 Section 0 also now describes the full campaign workflow as: rerun Section 15, then run Section 16.9, then run Section 17. fileciteturn215file0

## Recommendation

Use this structure:

```text
END OF SECTION 16.0–16.8
    Confirms current-run evidence capture is complete.
    Tells user what to do for single-run workflow.
    Tells user what to do for full-campaign workflow.

SECTION 16.9
    Runs only after the full campaign and fresh Section 15.

END OF SECTION 16.9
    Confirms post-campaign frontier evidence synchronization is complete.
    Tells user Section 17 is next.
```

I would replace the long 16.8 ending with this tighter version:

```sql
/***************************************************************************************************
END OF SECTION 16.0–16.8 — RUN-LEVEL STRATEGY EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER

If execution reaches this point:
    1. Persistent executive run evidence summary has been created or reused.
    2. Persistent validation evidence detail has been created or reused.
    3. Persistent strategy and product-policy parameter snapshot evidence has been created or reused.
    4. Persistent product × score segment evidence summary has been created or reused.
    5. Prior evidence rows for the current run key were replaced in the evidence tables only.
    6. Current Section 14 validation evidence detail was persisted.
    7. Current strategy, product-policy, and story parameter snapshots were persisted.
    8. Current product × score segment evidence was persisted.
    9. Current one-row executive evidence summary was persisted.
    10. Local Section 16 evidence-capture gatekeepers passed.
    11. Section 16.8 evidence diagnostics and export-ready review outputs are available.
    12. Module 3 readiness fields have been captured for future growth / economics design.

Registry evidence now carries:
    module1_run_id
    module2_run_id
    run_sequence_number
    showcase_id
    showcase_name
    comparison_group_id
    validation_evidence_group_id
    readme_storyline_label
    linkedin_post_sequence
    validation_summary_section_hint
    run_registry_match_status

Current-run evidence capture boundary:
    Section 16.0–16.8 may create, delete, and replace persistent evidence rows for the current run
    key only.

    Section 16.0–16.8 does not modify latest-run output rows.
    Section 16.0–16.8 does not modify archive rows.
    Section 16.0–16.8 does not modify campaign registry rows.
    Section 16.0–16.8 does not modify strategy parameter rows.
    Section 16.0–16.8 does not modify product-policy parameter rows.
    Section 16.0–16.8 does not recalculate decision outcomes.
    Section 16.0–16.8 does not recalculate approved exposure values.
    Section 16.0–16.8 does not recalculate approved Expected Loss values.
    Section 16.0–16.8 does not reassign simulated reason codes.
    Section 16.0–16.8 does not implement revenue, earnings, pricing, funding-cost, profitability,
    capital, or risk-adjusted margin logic.

Workflow guidance:
    For a single run:
        Stop here after reviewing Section 16.8 outputs, or proceed to the next selected run.

    For a full campaign:
        After all planned runs have completed through Section 16.8, rerun Section 15 from the
        completed archive, then run Section 16.9, then run Section 17.

***************************************************************************************************/
```

Then keep the **16.9 ending** separate, with one small adjustment to make the update boundary explicit:

```sql
/***************************************************************************************************
END OF SECTION 16.9 — POST-CAMPAIGN FRONTIER EVIDENCE SYNCHRONIZATION

If execution reaches this point:
    1. Fresh Section 15 frontier output exists.
    2. Persistent executive evidence exists.
    3. Section 15-derived frontier fields have been refreshed for all matching evidence rows.
    4. Matched evidence rows now align with the fresh Section 15 frontier output.
    5. Unmatched evidence rows, if any, have been surfaced for review.
    6. Section 17 can be run for final post-campaign acceptance.

Post-campaign synchronization boundary:
    Section 16.9 may update only Section 15-derived frontier fields in:

        credit_decisioning_sim.strategy_run_evidence_summary

    Specifically, Section 16.9 may refresh:
        frontier_position_type
        executive_frontier_quadrant
        frontier_interpretation_note
        top_reason_code_delta_driver_family
        top_reason_code_delta_driver_code
        top_reason_code_delta_driver_baseline_share
        top_reason_code_delta_driver_strategy_share
        top_reason_code_delta_population_share

    Section 16.9 does not modify latest-run output rows.
    Section 16.9 does not modify archive rows.
    Section 16.9 does not modify campaign registry rows.
    Section 16.9 does not modify validation evidence detail rows.
    Section 16.9 does not modify parameter snapshots.
    Section 16.9 does not modify product × score segment evidence.
    Section 16.9 does not modify strategy parameter rows.
    Section 16.9 does not modify product-policy parameter rows.
    Section 16.9 does not recalculate decision outcomes.
    Section 16.9 does not recalculate approved exposure values.
    Section 16.9 does not recalculate approved Expected Loss values.
    Section 16.9 does not reassign simulated reason codes.
    Section 16.9 does not implement revenue, earnings, pricing, funding-cost, profitability, capital,
    or risk-adjusted margin logic.

Next:
    Run Section 17 after reviewing the Section 16.9 synchronization summary.

***************************************************************************************************/
```

That gives you the cleanest governance narrative:

```text
16.0–16.8 = current-run evidence capture complete
16.9      = post-campaign frontier evidence synchronization complete
17        = final post-campaign acceptance
```

So yes, keep both endings — but make the 16.8 ending a **run-level checkpoint**, and make the 16.9 ending a **post-campaign synchronization checkpoint**.
<!-- END_MESSAGE C038-M01498 -->


---

<a id="c038-m01500"></a>

### C038-M01500

**Andrew** · 2026-05-12T08:22:13.559000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01500 -->
thanks, now proceed with the next section update in our process map (whichever next one makes sense from section 15, 16, and 17).  continue to only do one section at a time in each response.
<!-- END_MESSAGE C038-M01500 -->


---

<a id="c038-m01503"></a>

### C038-M01503

**ChatGPT** · 2026-05-12T08:26:56.806961-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01503 -->
Next, update **Section 15**. That makes the most sense because Section 16.9 depends on a fresh Section 15 frontier output, especially `tmp_m2_strategy_frontier_executive_summary`, and Section 16.6 already carries Section 15 frontier fields into persistent executive evidence. fileciteturn215file14 fileciteturn215file7

Below is a **Section 15 commentary/workflow patch**. Replace your current **Section 15 opening header** with this. Then add the **END OF SECTION 15** footer at the end of Section 15, immediately before Section 16 begins.

```sql
/***************************************************************************************************
SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
****************************************************************************************************

BUSINESS PURPOSE:
    Provide an executive-ready, archive-backed strategy frontier view across completed Module 2
    strategy outputs.

    Section 15 answers:

        "Across archived Module 1 scenario × Module 2 strategy slices, what are the portfolio-level
         tradeoffs between simulated offer exposure, approved amount, approved Expected Loss,
         affordability, synthetic estimated-risk profile, counteroffer usage, manual-review burden,
         decline rate, product behavior, score-band behavior, and simulated reason-code movement?"

    Section 15 is the archive-wide strategy control tower.

    It translates many completed strategy runs into a structured frontier view that can support:
        executive interpretation,
        validation-summary drafting,
        README evidence,
        LinkedIn result storytelling,
        campaign acceptance review,
        and future Module 3 economics design.

WHY SECTION 15 EXISTS:
    A single strategy run can tell the user what happened under one strategy.

    A campaign archive can tell the user how strategies trade off against each other.

    Section 15 summarizes the campaign archive so reviewers can see:
        which strategies expanded access,
        which strategies reduced approved Expected Loss,
        which strategies controlled affordability,
        which strategies shifted outcomes toward counteroffers,
        which strategies reduced manual-review burden,
        which products or score bands drove the story,
        and which reason-code movements explain the strategy change.

SECTION 13 VS SECTION 15:
    Section 13 answers a narrow matched-comparison question:

        "How does one selected challenger strategy compare to one selected baseline strategy on the
         same Module 1 scenario and population?"

    Section 15 answers a broader frontier question:

        "What does the archived strategy landscape look like across all completed strategy / scenario
         slices?"

    Section 13 is best for one baseline-versus-challenger deep dive.

    Section 15 is best for portfolio-level strategy frontier interpretation.

SECTION 14 VS SECTION 15:
    Section 14 validates the current latest-run output.

    Section 15 summarizes archived completed strategy slices.

    Section 15 assumes upstream latest-run QA and archive persistence have already been reviewed.
    It does not replace Section 14 validation.

SECTION 16 VS SECTION 15:
    Section 15 creates temporary archive-wide frontier outputs.

    Section 16 captures persistent run-level evidence.

    Section 16.6 reads Section 15 frontier fields and stores them in the one-row executive evidence
    summary for the current run.

SECTION 16.9 VS SECTION 15:
    Section 15 recalculates the frontier from the completed archive.

    Section 16.9 synchronizes selected Section 15-derived frontier fields into persistent executive
    evidence after the full campaign archive is complete.

    Section 16.9 does not rebuild the frontier.
    It depends on a fresh Section 15 run.

WHEN TO RUN SECTION 15:
    Single-run workflow:
        Run Section 15 after Section 12 archive persistence and Section 14 QA when the user wants a
        current archive-backed frontier view before Section 16 evidence capture.

    Full-campaign workflow:
        1. Run every planned M2 campaign slice through Section 16.8.
        2. Rerun Section 15 once from the completed campaign archive.
        3. Run Section 16.9 to synchronize Section 15-derived frontier fields into persistent
           executive evidence.
        4. Run Section 17 for final campaign acceptance.

IMPORTANT FULL-CAMPAIGN NOTE:
    Section 15 is archive-wide.

    If a baseline or challenger run is rerun after earlier evidence capture, Section 15 should be
    rerun from the completed archive before Section 16.9 and Section 17.

    This prevents stale frontier labels such as:
        NO_BASELINE_REFERENCE_AVAILABLE

    from remaining in executive evidence after the relevant baseline / challenger archive slices are
    now present.

INPUTS:
    credit_decisioning_sim.strategy_decisions_archive
        Governed archive of completed Module 2 strategy outputs.

    credit_decisioning_sim.strategy_run_campaign_registry
        Optional registry enrichment source.

        Used to attach:
            module1_run_id,
            module2_run_id,
            run_sequence_number,
            showcase_id,
            comparison_group_id,
            validation_evidence_group_id,
            readme_storyline_label,
            linkedin_post_sequence,
            validation_summary_section_hint.

        Missing registry mapping is surfaced as a review signal, not an automatic failure.

TEMPORARY OUTPUTS CREATED:
    tmp_m2_strategy_frontier_campaign_registry_map
    tmp_m2_strategy_frontier_inventory
    tmp_m2_strategy_frontier_summary
    tmp_m2_strategy_frontier_baseline_deltas
    tmp_m2_strategy_frontier_efficiency
    tmp_m2_strategy_frontier_classification
    tmp_m2_strategy_frontier_segment_highlights
    tmp_m2_strategy_frontier_executive_summary

PRIMARY EXPORT-READY OUTPUT:
    tmp_m2_strategy_frontier_executive_summary

GRAIN OF CORE FRONTIER TABLES:
    One row per archived:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

WHY SECTION 15 USES THE ARCHIVE:
    credit_decisioning_sim.strategy_decisions is the current latest-run output only.

    It is intentionally replaceable.

    A strategy frontier requires multiple completed strategy / scenario slices, so Section 15 uses:

        credit_decisioning_sim.strategy_decisions_archive

    as the governed history layer.

REGISTRY-AWARE FRONTIER ENRICHMENT:
    Formal campaign runs use stable documentation IDs such as:

        module1_run_id
        module2_run_id
        run_sequence_number
        showcase_id
        comparison_group_id
        validation_evidence_group_id

    These IDs are useful for:
        campaign tracking,
        validation-summary drafting,
        README summaries,
        LinkedIn storyline planning,
        executive review,
        and final Section 17 acceptance.

    Registry IDs are documentation and evidence-linkage metadata.

    They do not replace the technical SQL key:
        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

STRATEGY FRONTIER CONCEPT:
    A strategy frontier is not a single "best strategy" ranking.

    It is a structured view of tradeoffs among:
        access / simulated offer exposure,
        approval rate,
        counteroffer usage,
        manual-review burden,
        decline rate,
        approved exposure,
        approved Expected Loss,
        approved Expected Loss rate,
        offered-population synthetic estimated-risk profile,
        approved PTI quality,
        product-level behavior,
        score-band behavior,
        and simulated reason-code movement.

    A growth-oriented point may increase simulated offer exposure and approved amount while increasing
    approved Expected Loss.

    A risk-discipline point may reduce approved Expected Loss while lowering simulated offer exposure.

    A counteroffer-management point may preserve access through reduced-exposure treatment.

    A product-guardrail point may surgically reduce unsecured or revolving exposure / Expected Loss
    without changing secured-product behavior.

    A manual-review-reduction point may reduce unresolved outcomes while increasing final no-offer
    outcomes.

    These are simulated strategy tradeoffs, not production recommendations.

PURE STRATEGY FRONTIER VS SCENARIO × STRATEGY FRONTIER:
    Pure Module 2 strategy frontier:
        Compare multiple Module 2 strategies within the same Module 1 scenario and population.

        This is strongest for isolating downstream Module 2 strategy effects.

    Scenario × strategy frontier:
        Compare archived outcomes across multiple Module 1 scenarios and Module 2 strategies.

        This is useful as an executive control-tower view, but users must preserve the distinction
        between upstream Module 1 scenario effects and downstream Module 2 strategy effects.

BASELINE-RELATIVE DELTA BOUNDARY:
    Baseline-relative deltas are calculated only where a BASELINE_STRATEGY exists under the same:

        strategy_set_name
        module1_scenario_set_name
        module1_scenario_name
        population_id

    If no baseline is available:
        baseline-relative fields are NULL;
        baseline_available_flag is FALSE;
        frontier_position_type may indicate that no baseline reference is available.

    Missing baseline is not automatically a failure.

    It means the archived frontier point can be summarized but cannot be interpreted as a baseline-
    relative strategy delta until a matching baseline slice exists.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 15, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 15 does not recalculate estimated_pd.
    Section 15 does not calibrate estimated_pd.
    Section 15 does not validate production default forecasting.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        Module 2 approved-exposure Expected Loss after final simulated exposure treatment.

    approved_expected_loss_rate:
        total_approved_expected_loss_amount / total_approved_amount.

        This is a synthetic strategy frontier metric.

        It is not a production loss-rate forecast.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies simulated positive offer exposure.

    It is TRUE for:
        APPROVE
        COUNTEROFFER

    It is FALSE for:
        MANUAL_REVIEW
        DECLINE

    It does not imply:
        operational account creation,
        booked exposure,
        funded exposure,
        production approval,
        customer treatment,
        or real applicant treatment.

SIMULATED REASON-CODE BOUNDARY:
    primary_reason_code and primary_reason_family remain simulated strategy explanation fields.

    They support:
        frontier interpretation,
        QA review,
        executive storytelling,
        README summaries,
        LinkedIn summaries,
        validation evidence,
        and strategy comparison.

    They are not:
        customer communications,
        regulatory notices,
        adverse-action reasons,
        fair-lending conclusions,
        or production compliance determinations.

FRONTIER CLASSIFICATION BOUNDARY:
    frontier_position_type and executive_frontier_quadrant are diagnostic labels.

    They summarize observed strategy posture.

    They do not declare a strategy best.
    They do not recommend production implementation.
    They do not replace Section 13 matched comparison.
    They do not replace Section 14 validation.
    They do not represent model validation approval.

WHAT TO REVIEW IN SECTION 15 OUTPUTS:
    1. Frontier scope:
        Confirm the archive contains the expected number of strategy / scenario slices.

    2. Registry mapping:
        Confirm formal campaign slices map to registry IDs where expected.

    3. Frontier summary:
        Review offer exposure, approved amount, approved Expected Loss, approved Expected Loss rate,
        affordability, risk proxy, LGD, decision mix, and reason-code concentration.

    4. Baseline deltas:
        Review whether challenger strategies have a valid same-scenario baseline.

    5. Efficiency metrics:
        Review tradeoffs such as approved amount per unit of approved Expected Loss.

    6. Frontier classification:
        Review diagnostic posture labels such as risk discipline, growth, counteroffer management,
        product guardrail, review-burden reduction, and mixed tradeoff.

    7. Segment highlights:
        Review product, score-band, and product × score drivers.

    8. Executive frontier summary:
        Use tmp_m2_strategy_frontier_executive_summary as the export-ready Section 15 result.

READ-ONLY BOUNDARY:
    Section 15 does not insert archive rows.
    Section 15 does not delete archive rows.
    Section 15 does not update archive rows.
    Section 15 does not modify credit_decisioning_sim.strategy_decisions.
    Section 15 does not modify credit_decisioning_sim.strategy_decisions_archive.
    Section 15 does not modify campaign registry rows.
    Section 15 does not modify persistent evidence rows.
    Section 15 does not recalculate decision_outcome.
    Section 15 does not recalculate approved exposure.
    Section 15 does not recalculate approved Expected Loss.
    Section 15 does not reassign simulated reason codes.
    Section 15 does not modify strategy parameters.
    Section 15 does not modify product-policy parameters.

SECTION 15 AND MODULE 3:
    Section 15 captures strategy frontier metrics that will be useful for future Module 3 economics
    design.

    It does not calculate:
        revenue,
        yield,
        funding cost,
        profitability,
        capital,
        pricing optimization,
        net income,
        lifetime value,
        or risk-adjusted margin.

COMMON MISUSE TO AVOID:
    Do not interpret Section 15 as production strategy recommendation.
    Do not compare across different Module 1 scenarios and call the result a pure Module 2 strategy
    effect.
    Do not interpret approved Expected Loss rate as a calibrated production loss forecast.
    Do not interpret simulated offer exposure as booked exposure.
    Do not interpret reason-code movement as customer communication language.
    Do not run Section 16.9 before rerunning Section 15 from the completed campaign archive.

***************************************************************************************************/
```

Add this footer at the end of Section 15:

```sql
/***************************************************************************************************
END OF SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW

If execution reaches this point:
    1. Archive-backed frontier scope has been reviewed.
    2. Campaign registry mapping has been created or reviewed where registry rows exist.
    3. Every archived strategy / scenario / population slice has been summarized at frontier grain.
    4. Baseline-relative deltas have been calculated where same-scenario BASELINE_STRATEGY rows exist.
    5. Efficiency indicators have been calculated.
    6. Frontier posture classifications have been assigned.
    7. Product, score-band, and product × score segment highlights have been created.
    8. tmp_m2_strategy_frontier_executive_summary is available as the primary export-ready frontier
       output.

Primary Section 15 output:
    tmp_m2_strategy_frontier_executive_summary

Section 16 dependency:
    Section 16.6 uses tmp_m2_strategy_frontier_executive_summary to carry frontier fields into the
    persistent one-row executive evidence summary for the current run.

Section 16.9 dependency:
    Section 16.9 uses a fresh tmp_m2_strategy_frontier_executive_summary to synchronize Section
    15-derived frontier fields into persistent executive evidence after the full campaign archive is
    complete.

Workflow guidance:
    For a single run:
        Run Section 16 after Section 15 if current-run evidence capture is needed.

    For a full campaign:
        After all planned runs have completed through Section 16.8, rerun Section 15 once from the
        completed archive, then run Section 16.9, then run Section 17.

Read-only boundary:
    Section 15 did not modify latest-run rows.
    Section 15 did not modify archive rows.
    Section 15 did not modify campaign registry rows.
    Section 15 did not modify persistent evidence rows.
    Section 15 did not modify strategy parameter rows.
    Section 15 did not modify product-policy parameter rows.
    Section 15 did not recalculate decision outcomes.
    Section 15 did not recalculate approved exposure values.
    Section 15 did not recalculate approved Expected Loss values.
    Section 15 did not reassign simulated reason codes.
    Section 15 did not implement revenue, earnings, pricing, funding-cost, profitability, capital, or
    risk-adjusted margin logic.

Next:
    For current-run evidence capture:
        Run Section 16.

    For post-campaign evidence synchronization:
        Run Section 16.9 after a fresh Section 15 run.

    For final campaign acceptance:
        Run Section 17 after Section 16.9.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01503 -->


---

<a id="c038-m01504"></a>

### C038-M01504

**Andrew** · 2026-05-12T08:32:03.227000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01504 -->
thanks.  now proceed with the next section update (16 or 17) that makes sense.
<!-- END_MESSAGE C038-M01504 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_72.md) · [Next](Part_74.md)
