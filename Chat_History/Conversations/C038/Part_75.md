# Module 2 Decision Simulator Build

## Part 75

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_74.md) · [Next](Part_76.md)

<a id="c038-m01534"></a>

### C038-M01534

**ChatGPT** · 2026-05-12T09:29:11.392070-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01534 -->
According to the current Module 2 SQL captured on 2026-05-12, Section 5 is the **Derived Strategy Segmentation Layer** that creates `tmp_m2_stage_2_strategy_segments`, and Section 6 is designed to consume that object as the next non-final rule-trigger layer. fileciteturn223file2 fileciteturn222file3

```sql
/***************************************************************************************************
SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Create a non-decisioning strategy segmentation layer that translates continuous and categorical
    Module 1 inputs into policy-readable diagnostic segments.

    Section 5 answers:

        "How should this synthetic applicant be described for strategy-rule interpretation?"

    Section 5 does not answer:

        "What final simulated strategy outcome should this synthetic applicant receive?"

    This section is the applicant-description layer.

    It prepares the borrower, product, requested-affordability, requested-exposure, requested Expected
    Loss, score-band, synthetic estimated-risk, mixed-signal, and borderline context that later
    rule-trigger logic will consume.

SQL PURPOSE:
    1. Confirm required Section 5 dependencies exist.
    2. Read from tmp_m2_stage_1_source_applications.
    3. Preserve all Section 4 source, lineage, and Module 2 strategy metadata fields.
    4. Attach active global strategy thresholds.
    5. Attach product-specific policy thresholds and controls.
    6. Normalize score_band into score_band_policy_key.
    7. Derive non-decisioning diagnostic segments:
            strategy_risk_tier
            requested_pti_bucket
            dti_bucket
            requested_exposure_tier
            requested_expected_loss_tier
            product_score_policy_segment
            mixed_signal_profile_type
            mixed_signal_condition_count
            borderline_profile_flag
    8. Preserve threshold values in the staged data for downstream auditability.
    9. Validate that segmentation is populated without creating decisions, final flags, simulated
       reason codes, or approved-exposure outputs.
    10. Provide local staging diagnostics before Section 6 rule-trigger construction.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the segmentation buckets are intuitive and useful before they become rule
        triggers.

    Model governance / validation reviewers:
        Confirm that Section 5 remains descriptive and does not assign outcomes.

    SQL reviewers:
        Confirm that CTEs preserve row grain, attach active strategy/product policy controls, and
        create segmentation fields through transparent CASE logic.

    Portfolio / executive reviewers:
        Use Section 5 diagnostics to understand the selected population profile before interpreting
        decision outcomes later.

WHEN TO RUN THIS SECTION:
    Run Section 5 after:

        Section 4 — Module 1 Source Selection and Lineage Normalization

    Section 5 should be run before:

        Section 6 — Rule Flag Construction Layer

    Section 5 depends on:

        tmp_m2_stage_1_source_applications
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

HOW TO INTERPRET THIS SECTION:
    Passing Section 5 means:
        row count is preserved from Section 4;
        application_id remains unique;
        strategy thresholds are attached;
        product-policy thresholds are attached;
        score_band_policy_key is created;
        diagnostic segmentation fields are populated;
        mixed-signal and borderline diagnostics are populated;
        and downstream decision, reason-code, and approved-exposure fields have not been created.

    Passing Section 5 does not mean:
        a rule trigger has fired;
        a preliminary route has been assigned;
        a counteroffer is feasible;
        a final decision has been assigned;
        approved exposure exists;
        reason codes are complete;
        archive persistence worked;
        or full validation has passed.

RELATIONSHIP TO SECTION 4:
    Section 4 created the clean Module 1 → Module 2 handoff layer.

    Section 5 consumes that source stage and adds policy-readable descriptions.

    Section 5 does not go back to the Module 1 source tables.
    Section 5 does not rewrite Module 1 lineage.
    Section 5 does not change product_type.
    Section 5 does not change requested_amount.
    Section 5 does not change estimated_pd.
    Section 5 does not change requested_expected_loss_amount.

RELATIONSHIP TO SECTION 2:
    Section 2 now creates profile-driven active strategy and product-policy parameter cards.

    Section 5 consumes the canonical active parameter tables:

        tmp_module2_strategy_params
        tmp_module2_product_policy_params

    It does not read the profile catalogs directly.

    This preserves the downstream contract:
        Section 2 chooses the strategy and product-policy profiles;
        Section 3 validates them;
        Section 5 attaches the active threshold values to applicant-level staging rows.

WHY SEGMENTATION IS SEPARATED FROM DECISION RULES:
    Segmentation describes the synthetic applicant profile.

    Decision rules later evaluate that profile and create rule-trigger flags.

    Preliminary routing later prioritizes overlapping rule triggers.

    Exposure treatment later evaluates approved exposure, approved PTI, and approved Expected Loss.

    Final decision resolution later creates final simulated strategy outcomes.

    Keeping these layers separate improves:
        readability,
        auditability,
        QA,
        troubleshooting,
        strategy tuning,
        and documentation traceability.

WHY THRESHOLD VALUES ARE ATTACHED:
    Downstream stages should be interpretable without forcing reviewers to reverse-engineer the
    active parameter tables.

    Section 5 therefore carries forward:
        global synthetic estimated-risk thresholds,
        global PTI thresholds,
        DTI thresholds,
        rule-control parameters,
        product PTI thresholds,
        requested Expected Loss thresholds,
        approved Expected Loss caps,
        approved amount limits,
        counteroffer controls,
        and rounding controls.

    This makes later rule flags, preliminary routing, exposure treatment, and final decision resolution
    easier to audit.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field.

    Section 5 uses estimated_pd only as the synthetic estimated-PD proxy input for diagnostic
    segmentation.

    Section 5 does not recalculate estimated_pd.
    Section 5 does not calibrate estimated_pd.
    Section 5 does not create a post-decision risk model.

REQUESTED PTI BOUNDARY:
    requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.

    Approved payment and approved PTI do not exist yet.

    Section 5 therefore segments requested affordability pressure, not approved affordability after
    exposure treatment.

DTI BOUNDARY:
    debt_to_income_ratio is an existing-obligation capacity signal.

    In Module 2 V1.0, DTI is not directly fixed by counteroffer exposure reduction because a
    counteroffer changes the requested exposure treatment, not the applicant's existing obligations.

REQUESTED EXPOSURE VS APPROVED EXPOSURE:
    requested_amount is the original requested exposure from Module 1.

    approved_amount does not exist in Section 5.

    Section 5 may describe requested exposure intensity, but it does not assign approved exposure.

REQUESTED EXPECTED LOSS VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount does not exist in Section 5.

    Section 5 segments requested-exposure Expected Loss pressure before any approved-exposure
    treatment is calculated.

MIXED-SIGNAL PROFILE BOUNDARY:
    mixed_signal_profile_type is diagnostic only.

    It identifies realistic overlap patterns such as:
        strong credit with high requested PTI,
        weak credit with low requested PTI,
        large exposure with low synthetic estimated-risk,
        high synthetic estimated-risk with low exposure,
        high DTI with low requested PTI.

    It does not automatically approve, decline, route to review, or trigger counteroffer.

BORDERLINE PROFILE BOUNDARY:
    borderline_profile_flag uses the governed borderline_threshold_buffer_pct parameter from Section 2.

    No hidden hardcoded threshold-adjacent buffer is used.

    Borderline status is diagnostic only.

    It helps later QA and manual-review trigger interpretation, but it does not create a final outcome
    in Section 5.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the segmentation layer as a session-scoped staging table.

    ON COMMIT PRESERVE ROWS:
        Keeps the staging rows available across transaction boundaries in the same session.

    CTE chain:
        The WITH clause breaks segmentation into readable steps:
            active_strategy_params
            threshold_enriched
            score_normalized
            core_segments
            mixed_signal_conditions
            mixed_signal_scored
            borderline_scored
            final_segments

    JOIN active_strategy_params ON TRUE:
        Attaches the single active strategy parameter card to every staged applicant row.

    JOIN product policy:
        Attaches product-specific thresholds and controls using product_type_policy_key.

    CASE:
        Converts continuous values into readable diagnostic categories.

    REGEXP_REPLACE + UPPER + BTRIM:
        Normalizes score band text into stable policy keys.

    Boolean expressions:
        Create diagnostic mixed-signal conditions and borderline flags.

    CASE WHEN ... THEN 1 ELSE 0 END:
        Converts TRUE / FALSE conditions into 1 / 0 so they can be counted safely.

    IS DISTINCT FROM:
        Used later in gatekeepers to detect mismatches safely, including NULL differences.

WHY NO DECISION OUTPUTS ARE CREATED IN SECTION 5:
    Section 5 does not create:
        decision_outcome
        decision_path
        approval_flag
        decline_flag
        manual_review_flag
        counteroffer_flag
        simulated_offer_exposure_flag
        reason codes
        approved_amount
        counteroffer_amount
        approved payment
        approved PTI
        approved Expected Loss

GOVERNANCE ROLE:
    Section 5 makes the strategy-rule input profile transparent.

    It demonstrates separation of concerns:
        Module 1 source values are preserved.
        Strategy thresholds are attached.
        Product policy thresholds are attached.
        Diagnostic segments are created.
        Decision logic remains deferred.

COMMON MISUSE TO AVOID:
    Do not interpret strategy_risk_tier as a final decision.
    Do not interpret requested_pti_bucket as approved affordability.
    Do not interpret dti_bucket as counteroffer-adjusted capacity.
    Do not interpret requested_exposure_tier as approved exposure.
    Do not interpret requested_expected_loss_tier as approved Expected Loss.
    Do not interpret mixed_signal_profile_type as a final route.
    Do not interpret borderline_profile_flag as automatic manual review.
    Do not treat segmentation output as operational applicant treatment.

TESTING RELEVANCE:
    Section 5 local diagnostics help confirm that diagnostic segmentation is complete, stable, and
    aligned to the selected Module 1 population and Module 2 strategy before rule-trigger construction
    begins.

DOWNSTREAM DEPENDENCY:
    Section 6 consumes tmp_m2_stage_2_strategy_segments.

    Downstream rule logic should not read directly from Section 4 when Section 5-derived diagnostic
    fields are needed.

PORTFOLIO ARTIFACT VALUE:
    This section shows that the strategy engine is not a monolithic decision CASE block.

    It demonstrates a mature staged architecture where applicant description, rule triggers,
    preliminary routing, exposure treatment, final outcomes, explanation codes, archive comparison,
    and validation evidence are separated and reviewable.

***************************************************************************************************/



/***************************************************************************************************
SECTION 5.0 — SECTION 5 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the required upstream staging and parameter objects exist before the segmentation
    layer is built.

    Section 5.0 answers:

        "Can Section 5 safely build segmentation from the validated Section 4 source stage and the
         active Section 2 parameter cards?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_1_source_applications exists.
    2. Confirm tmp_module2_strategy_params exists.
    3. Confirm tmp_module2_product_policy_params exists.
    4. Confirm exactly one active strategy parameter row exists.
    5. Confirm source-stage rows exist.
    6. Confirm product-policy rows exist.

WHY THIS PREFLIGHT EXISTS:
    Section 5 is a transformation layer.

    It should fail with a clear instructional message if Sections 2, 3, or 4 have not been run, rather
    than producing a lower-level missing-table or missing-column error.

BOUNDARY:
    Section 5.0 does not create segmentation.
    Section 5.0 does not create decisions.
    Section 5.0 does not create reason codes.
    Section 5.0 does not calculate approved exposure.
    Section 5.0 does not modify any persistent table.

***************************************************************************************************/

DO $$
DECLARE
    v_stage1_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;
    v_product_policy_params_exists BOOLEAN;

    v_active_strategy_count BIGINT;
    v_stage1_row_count BIGINT;
    v_product_policy_row_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 4 source-stage table must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

    Business interpretation:
        Section 5 should consume the validated Section 4 source stage, not the raw Module 1 source.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_1_source_applications'),
        TO_REGCLASS('tmp_m2_stage_1_source_applications')
    ) IS NOT NULL
    INTO v_stage1_exists;

    IF v_stage1_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_m2_stage_1_source_applications is required. Run Section 4 before Section 5.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: active strategy parameter table must exist.

    Business interpretation:
        Section 5 needs global synthetic-risk, PTI, DTI, rule-control, and borderline-buffer
        parameters from the active strategy card.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_strategy_params'),
        TO_REGCLASS('tmp_module2_strategy_params')
    ) IS NOT NULL
    INTO v_strategy_params_exists;

    IF v_strategy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_module2_strategy_params is required. Run redesigned Section 2 before Section 5.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: product-policy parameter table must exist.

    Business interpretation:
        Section 5 needs product-level PTI, requested Expected Loss, approved Expected Loss, approved
        amount, counteroffer, and manual-review policy controls.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_product_policy_params'),
        TO_REGCLASS('tmp_module2_product_policy_params')
    ) IS NOT NULL
    INTO v_product_policy_params_exists;

    IF v_product_policy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_module2_product_policy_params is required. Run redesigned Section 2 before Section 5.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active strategy parameter row.

    Section 3 validates this in more detail. Section 5 repeats the cardinality check to protect
    against out-of-order or partial reruns.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 4 source-stage rows must exist.

    Business interpretation:
        Segmentation over an empty applicant set is not useful and usually indicates an upstream
        source-selection problem.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage1_row_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_stage1_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product-policy rows must exist.

    Section 3 validates completeness and supported products. Section 5 confirms the table is populated
    before the product-policy join is attempted.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_product_policy_row_count
    FROM tmp_module2_product_policy_params;

    IF v_product_policy_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_module2_product_policy_params contains zero rows.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 5.1 — CLEAN RESET OF SECTION 5 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 5 segmentation stage before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 5 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale segmentation rows to remain available to Section 6.

    Section 6 assumes tmp_m2_stage_2_strategy_segments reflects the current:
        Section 4 source stage,
        active Module 2 strategy card,
        and active product policy card.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the table does not exist, PostgreSQL does not error.

BOUNDARY:
    This drop affects only the temporary Section 5 staging object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;



/***************************************************************************************************
SECTION 5.2 — CREATE DERIVED STRATEGY SEGMENTATION TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_2_strategy_segments

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_1_source_applications

OUTPUT:
    All Section 4 fields plus:
        global strategy thresholds,
        product policy thresholds,
        rule-control parameters,
        normalized score band key,
        diagnostic strategy segmentation fields,
        mixed-signal diagnostics,
        and borderline profile flag.

SQL DESIGN:
    This section uses a CTE chain so the segmentation process is readable and reviewable.

    The chain is:

        active_strategy_params
            selects the one active strategy parameter card.

        threshold_enriched
            attaches global strategy and product policy thresholds to each source row.

        score_normalized
            creates score_band_policy_key.

        core_segments
            creates the main diagnostic segmentation fields.

        mixed_signal_conditions
            creates Boolean diagnostic mixed-signal conditions.

        mixed_signal_scored
            counts how many mixed-signal conditions are present.

        borderline_scored
            creates borderline_profile_flag using the governed threshold buffer.

        final_segments
            creates product_score_policy_segment and mixed_signal_profile_type.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 5 intentionally preserves all prior fields plus segmentation diagnostics for downstream
    rule-trigger construction.

    Permanent output selection is handled later with explicit field selection in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_2_strategy_segments
ON COMMIT PRESERVE ROWS
AS
WITH active_strategy_params AS (
    /***********************************************************************************************
    CTE: active_strategy_params

    Purpose:
        Select the single active Module 2 strategy parameter row.

    SQL mechanics:
        Section 5.0 confirms exactly one active row exists.

        LIMIT 1 is therefore safe after the preflight check.

    Credit risk interpretation:
        This row supplies the global strategy posture:
            synthetic estimated-risk thresholds,
            PTI thresholds,
            DTI thresholds,
            diagnostic buffer,
            and rule-control switches.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

threshold_enriched AS (
    /***********************************************************************************************
    CTE: threshold_enriched

    Purpose:
        Attach global strategy thresholds and product-specific policy thresholds to every staged
        applicant row.

    SQL mechanics:
        s.* preserves the full Section 4 source-stage row.

        JOIN active_strategy_params p ON TRUE:
            attaches the one active strategy card to every row.

        JOIN tmp_module2_product_policy_params pp:
            attaches the product-policy row that matches product_type_policy_key.

    Credit risk interpretation:
        Product policy is attached here because affordability tolerance, requested Expected Loss
        thresholds, approved Expected Loss caps, approved exposure ranges, and counteroffer controls
        vary by product.

    Boundary:
        These thresholds are attached for transparency and downstream use.

        Section 5 does not apply final rules or assign outcomes.
    ***********************************************************************************************/
    SELECT
        s.*,

        /*******************************************************************************************
        Global synthetic estimated-risk thresholds.

        estimated_pd is interpreted as the synthetic estimated-PD proxy.

        These thresholds describe synthetic risk bands used for strategy simulation.
        *******************************************************************************************/
        p.approve_max_estimated_pd_proxy,
        p.counteroffer_max_estimated_pd_proxy,
        p.review_max_estimated_pd_proxy,
        p.decline_min_estimated_pd_proxy,

        /*******************************************************************************************
        Global PTI thresholds.

        Product-specific PTI thresholds are used for product-aware segmentation and rules, but global
        values are retained for strategy transparency.
        *******************************************************************************************/
        p.global_approve_max_pti,
        p.global_review_max_pti,
        p.global_decline_min_pti,

        /*******************************************************************************************
        DTI thresholds.

        DTI remains an existing-obligation capacity signal.
        *******************************************************************************************/
        p.approve_max_dti,
        p.review_max_dti,
        p.decline_min_dti,

        /*******************************************************************************************
        Borderline diagnostic buffer.

        This governed parameter prevents hidden hardcoded threshold-adjacent logic.
        *******************************************************************************************/
        p.borderline_threshold_buffer_pct,

        /*******************************************************************************************
        Section 6 rule-control parameters.

        These are carried forward so rule-trigger logic is transparent in the staged data.
        *******************************************************************************************/
        p.bankruptcy_policy_stop_enabled,
        p.major_derogatory_policy_stop_enabled,
        p.severe_delinquency_policy_stop_enabled,
        p.severe_delinquency_count_threshold,

        p.high_utilization_review_enabled,
        p.high_utilization_review_threshold,

        p.low_score_review_enabled,
        p.low_score_review_threshold,

        /*******************************************************************************************
        Product policy profile and product-level policy thresholds.

        product_policy_profile_code supports later parameter-snapshot and QA interpretation.

        These are attached here for downstream transparency.
        Section 5 does not apply final exposure treatment or counteroffer feasibility logic.
        *******************************************************************************************/
        pp.product_policy_profile_code,

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
        pp.approved_amount_rounding_increment,

        /*******************************************************************************************
        Requested Expected Loss low / moderate split.

        This uses product_approve_max_requested_el / 2.0 because Section 5 classifies
        requested-exposure Expected Loss.

        product_approved_el_cap is carried forward for later approved-exposure logic but does not
        drive pre-decision requested Expected Loss tiering.

        Credit risk interpretation:
            requested_expected_loss_amount reflects the original requested exposure.

            approved_expected_loss_amount does not exist yet.
        *******************************************************************************************/
        (pp.product_approve_max_requested_el / 2.0) AS requested_el_low_moderate_split

    FROM tmp_m2_stage_1_source_applications s

    JOIN active_strategy_params p
        ON TRUE

    JOIN tmp_module2_product_policy_params pp
        ON pp.product_type = s.product_type_policy_key
),

score_normalized AS (
    /***********************************************************************************************
    CTE: score_normalized

    Purpose:
        Normalize the original Module 1 score_band field into a stable Module 2 policy key.

    SQL mechanics:
        BTRIM removes leading / trailing spaces.
        REGEXP_REPLACE converts non-alphanumeric runs into underscores.
        UPPER standardizes capitalization.
        CASE maps accepted source variants to governed score-band keys.

    Credit risk interpretation:
        Score band is a borrower-quality segment.

        It is not the same as estimated_pd, but it should generally align directionally with the
        synthetic estimated-PD proxy.

    Boundary:
        Module 1 score_band is preserved.
        Section 5 adds score_band_policy_key for downstream strategy logic and QA.
    ***********************************************************************************************/
    SELECT
        te.*,

        CASE
            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('SUPER_PRIME', 'SUPERPRIME', 'SP')
                THEN 'SUPER_PRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('PRIME', 'P')
                THEN 'PRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('NEAR_PRIME', 'NEARPRIME', 'NP')
                THEN 'NEAR_PRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('SUBPRIME', 'SUB_PRIME', 'SUB')
                THEN 'SUBPRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('DEEP_SUBPRIME', 'DEEP_SUB_PRIME', 'DEEP_SUB', 'DS')
                THEN 'DEEP_SUBPRIME'

            ELSE NULL
        END AS score_band_policy_key

    FROM threshold_enriched te
),

core_segments AS (
    /***********************************************************************************************
    CTE: core_segments

    Purpose:
        Create the primary non-decisioning segmentation fields.

    Fields created:
        strategy_risk_tier
        requested_pti_bucket
        dti_bucket
        requested_exposure_tier
        requested_expected_loss_tier

    Boundary:
        These are diagnostic profile categories.

        They do not assign final decision outcomes.
    ***********************************************************************************************/
    SELECT
        sn.*,

        /*******************************************************************************************
        Synthetic estimated-risk tier.

        Uses estimated_pd as the Module 1 synthetic estimated-PD proxy input.

        Interpretation:
            LOW_SYNTHETIC_RISK:
                materially below the clean-approval threshold.

            MODERATE_SYNTHETIC_RISK:
                within the clean-approval threshold.

            ELEVATED_SYNTHETIC_RISK:
                above clean-approval threshold but within counteroffer appetite.

            HIGH_SYNTHETIC_RISK:
                above counteroffer appetite but below the severe decline trigger.

            SEVERE_SYNTHETIC_RISK:
                at or above the decline trigger.

        Boundary:
            This is a diagnostic tier.

            Section 6 creates risk trigger flags later.
            Section 5 does not assign decisions.
        *******************************************************************************************/
        CASE
            WHEN sn.estimated_pd <= (sn.approve_max_estimated_pd_proxy / 2.0)
                THEN 'LOW_SYNTHETIC_RISK'

            WHEN sn.estimated_pd <= sn.approve_max_estimated_pd_proxy
                THEN 'MODERATE_SYNTHETIC_RISK'

            WHEN sn.estimated_pd <= sn.counteroffer_max_estimated_pd_proxy
                THEN 'ELEVATED_SYNTHETIC_RISK'

            WHEN sn.estimated_pd < sn.decline_min_estimated_pd_proxy
                THEN 'HIGH_SYNTHETIC_RISK'

            ELSE 'SEVERE_SYNTHETIC_RISK'
        END AS strategy_risk_tier,

        /*******************************************************************************************
        Requested PTI bucket.

        requested_payment_to_income_ratio is the original requested-structure affordability proxy.

        approved_payment_to_income_ratio does not exist yet.
        *******************************************************************************************/
        CASE
            WHEN sn.requested_payment_to_income_ratio <= (sn.product_approve_max_pti / 2.0)
                THEN 'LOW_REQUESTED_PTI'

            WHEN sn.requested_payment_to_income_ratio <= sn.product_approve_max_pti
                THEN 'MODERATE_REQUESTED_PTI'

            WHEN sn.requested_payment_to_income_ratio <= sn.product_review_max_pti
                THEN 'ELEVATED_REQUESTED_PTI'

            WHEN sn.requested_payment_to_income_ratio < sn.product_decline_min_pti
                THEN 'HIGH_REQUESTED_PTI'

            ELSE 'SEVERE_REQUESTED_PTI'
        END AS requested_pti_bucket,

        /*******************************************************************************************
        DTI bucket.

        debt_to_income_ratio represents existing-obligation capacity.

        In Module 2 V1.0, DTI is not directly fixed by reduced requested exposure.
        *******************************************************************************************/
        CASE
            WHEN sn.debt_to_income_ratio <= (sn.approve_max_dti / 2.0)
                THEN 'LOW_DTI'

            WHEN sn.debt_to_income_ratio <= sn.approve_max_dti
                THEN 'MODERATE_DTI'

            WHEN sn.debt_to_income_ratio <= sn.review_max_dti
                THEN 'ELEVATED_DTI'

            WHEN sn.debt_to_income_ratio < sn.decline_min_dti
                THEN 'HIGH_DTI'

            ELSE 'SEVERE_DTI'
        END AS dti_bucket,

        /*******************************************************************************************
        Requested exposure tier.

        This describes the original requested amount relative to product policy controls.

        It does not assign approved_amount.
        *******************************************************************************************/
        CASE
            WHEN sn.requested_amount < sn.product_min_approved_amount
                THEN 'BELOW_PRODUCT_MINIMUM'

            WHEN sn.requested_amount <= (sn.product_max_approved_amount * 0.50)
                THEN 'LOW_REQUESTED_EXPOSURE'

            WHEN sn.requested_amount <= sn.product_max_approved_amount
                THEN 'WITHIN_PRODUCT_APPROVAL_CAP'

            WHEN sn.requested_amount <= (sn.product_max_approved_amount * 1.50)
                THEN 'ABOVE_PRODUCT_APPROVAL_CAP'

            ELSE 'EXTREME_REQUESTED_EXPOSURE'
        END AS requested_exposure_tier,

        /*******************************************************************************************
        Requested Expected Loss tier.

        requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

        approved_expected_loss_amount does not exist yet.
        *******************************************************************************************/
        CASE
            WHEN sn.requested_expected_loss_amount <= sn.requested_el_low_moderate_split
                THEN 'LOW_REQUESTED_EL'

            WHEN sn.requested_expected_loss_amount <= sn.product_approve_max_requested_el
                THEN 'MODERATE_REQUESTED_EL'

            WHEN sn.requested_expected_loss_amount <= sn.product_review_max_requested_el
                THEN 'ELEVATED_REQUESTED_EL'

            WHEN sn.requested_expected_loss_amount < sn.product_decline_min_requested_el
                THEN 'HIGH_REQUESTED_EL'

            ELSE 'SEVERE_REQUESTED_EL'
        END AS requested_expected_loss_tier

    FROM score_normalized sn
),

mixed_signal_conditions AS (
    /***********************************************************************************************
    CTE: mixed_signal_conditions

    Purpose:
        Create Boolean diagnostic conditions for realistic overlapping applicant profiles.

    Credit risk interpretation:
        Real credit portfolios are not perfectly separated.

        Strong score applicants can have high requested affordability stress.
        Weak score applicants can request modest exposure with low PTI.
        Low-risk applicants can request large exposure.
        High-risk applicants can request small exposure.
        High DTI can coexist with low requested PTI.

    Boundary:
        These conditions are diagnostic only.

        They do not assign final outcomes.
        They do not assign reason codes.
        They do not create Section 6 rule-trigger flags yet.
    ***********************************************************************************************/
    SELECT
        cs.*,

        (
            cs.score_band_policy_key IN ('SUPER_PRIME', 'PRIME')
            AND cs.requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
        ) AS strong_credit_high_pti_condition,

        (
            cs.score_band_policy_key IN ('SUBPRIME', 'DEEP_SUBPRIME')
            AND cs.requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS weak_credit_low_pti_condition,

        (
            cs.requested_exposure_tier IN ('ABOVE_PRODUCT_APPROVAL_CAP', 'EXTREME_REQUESTED_EXPOSURE')
            AND cs.strategy_risk_tier IN ('LOW_SYNTHETIC_RISK', 'MODERATE_SYNTHETIC_RISK')
        ) AS large_exposure_low_risk_condition,

        (
            cs.strategy_risk_tier IN ('HIGH_SYNTHETIC_RISK', 'SEVERE_SYNTHETIC_RISK')
            AND (
                cs.requested_exposure_tier = 'BELOW_PRODUCT_MINIMUM'
                OR cs.requested_amount <= cs.product_min_approved_amount
            )
        ) AS high_risk_low_exposure_condition,

        (
            cs.dti_bucket IN ('HIGH_DTI', 'SEVERE_DTI')
            AND cs.requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS high_dti_low_requested_pti_condition

    FROM core_segments cs
),

mixed_signal_scored AS (
    /***********************************************************************************************
    CTE: mixed_signal_scored

    Purpose:
        Count how many mixed-signal diagnostic conditions are active on each row.

    SQL mechanics:
        CASE WHEN condition THEN 1 ELSE 0 END creates stable 1 / 0 values.

        This avoids NULL arithmetic if a condition ever evaluates to NULL.

    Why count rather than choose immediately:
        Multiple mixed signals can coexist.

        Section 5 preserves that complexity instead of forcing a single explanation too early.
    ***********************************************************************************************/
    SELECT
        msc.*,

        (
            CASE WHEN msc.strong_credit_high_pti_condition IS TRUE THEN 1 ELSE 0 END
            + CASE WHEN msc.weak_credit_low_pti_condition IS TRUE THEN 1 ELSE 0 END
            + CASE WHEN msc.large_exposure_low_risk_condition IS TRUE THEN 1 ELSE 0 END
            + CASE WHEN msc.high_risk_low_exposure_condition IS TRUE THEN 1 ELSE 0 END
            + CASE WHEN msc.high_dti_low_requested_pti_condition IS TRUE THEN 1 ELSE 0 END
        ) AS mixed_signal_condition_count

    FROM mixed_signal_conditions msc
),

borderline_scored AS (
    /***********************************************************************************************
    CTE: borderline_scored

    Purpose:
        Identify threshold-adjacent profiles using the governed borderline_threshold_buffer_pct.

    SQL mechanics:
        ABS(value - threshold) <= threshold × buffer

        GREATEST(..., 0.000001) protects very small threshold values from creating an unusably tiny
        comparison band.

    Credit risk interpretation:
        Borderline profiles sit close to a strategy threshold.

        They are useful for later QA, manual-review review, and sensitivity interpretation.

    Boundary:
        Borderline status is diagnostic only.

        It does not create final manual review.
        It does not create a reason code.
        It does not override any downstream rule hierarchy.
    ***********************************************************************************************/
    SELECT
        mss.*,

        (
            /***************************************************************************************
            Synthetic estimated-risk threshold adjacency.
            ***************************************************************************************/
            ABS(mss.estimated_pd - mss.approve_max_estimated_pd_proxy)
                <= GREATEST(mss.approve_max_estimated_pd_proxy * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.estimated_pd - mss.counteroffer_max_estimated_pd_proxy)
                <= GREATEST(mss.counteroffer_max_estimated_pd_proxy * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.estimated_pd - mss.review_max_estimated_pd_proxy)
                <= GREATEST(mss.review_max_estimated_pd_proxy * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.estimated_pd - mss.decline_min_estimated_pd_proxy)
                <= GREATEST(mss.decline_min_estimated_pd_proxy * mss.borderline_threshold_buffer_pct, 0.000001)

            /***************************************************************************************
            Requested PTI threshold adjacency.
            ***************************************************************************************/
            OR ABS(mss.requested_payment_to_income_ratio - mss.product_approve_max_pti)
                <= GREATEST(mss.product_approve_max_pti * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.requested_payment_to_income_ratio - mss.product_review_max_pti)
                <= GREATEST(mss.product_review_max_pti * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.requested_payment_to_income_ratio - mss.product_decline_min_pti)
                <= GREATEST(mss.product_decline_min_pti * mss.borderline_threshold_buffer_pct, 0.000001)

            /***************************************************************************************
            DTI threshold adjacency.
            ***************************************************************************************/
            OR ABS(mss.debt_to_income_ratio - mss.approve_max_dti)
                <= GREATEST(mss.approve_max_dti * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.debt_to_income_ratio - mss.review_max_dti)
                <= GREATEST(mss.review_max_dti * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.debt_to_income_ratio - mss.decline_min_dti)
                <= GREATEST(mss.decline_min_dti * mss.borderline_threshold_buffer_pct, 0.000001)

            /***************************************************************************************
            Requested Expected Loss threshold adjacency.
            ***************************************************************************************/
            OR ABS(mss.requested_expected_loss_amount - mss.product_approve_max_requested_el)
                <= GREATEST(mss.product_approve_max_requested_el * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.requested_expected_loss_amount - mss.product_review_max_requested_el)
                <= GREATEST(mss.product_review_max_requested_el * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.requested_expected_loss_amount - mss.product_decline_min_requested_el)
                <= GREATEST(mss.product_decline_min_requested_el * mss.borderline_threshold_buffer_pct, 0.000001)

            /***************************************************************************************
            Requested amount threshold adjacency.
            ***************************************************************************************/
            OR ABS(mss.requested_amount - mss.product_min_approved_amount)
                <= GREATEST(mss.product_min_approved_amount * mss.borderline_threshold_buffer_pct, 0.000001)

            OR ABS(mss.requested_amount - mss.product_max_approved_amount)
                <= GREATEST(mss.product_max_approved_amount * mss.borderline_threshold_buffer_pct, 0.000001)
        ) AS borderline_profile_flag

    FROM mixed_signal_scored mss
),

final_segments AS (
    /***********************************************************************************************
    CTE: final_segments

    Purpose:
        Create the final Section 5 segmentation fields.

    Fields created:
        product_score_policy_segment
        mixed_signal_profile_type

    SQL mechanics:
        product_score_policy_segment concatenates product_type_policy_key and score_band_policy_key.

        mixed_signal_profile_type uses:
            MULTIPLE_MIXED_SIGNALS when more than one mixed-signal condition exists;
            otherwise the first applicable single mixed-signal condition;
            otherwise NO_MIXED_SIGNAL_PROFILE.

    Boundary:
        These are still diagnostic descriptors.

        No outcome is assigned.
    ***********************************************************************************************/
    SELECT
        bs.*,

        (
            bs.product_type_policy_key || '_' || bs.score_band_policy_key
        ) AS product_score_policy_segment,

        CASE
            WHEN bs.mixed_signal_condition_count > 1
                THEN 'MULTIPLE_MIXED_SIGNALS'

            WHEN bs.strong_credit_high_pti_condition IS TRUE
                THEN 'STRONG_CREDIT_HIGH_PTI'

            WHEN bs.weak_credit_low_pti_condition IS TRUE
                THEN 'WEAK_CREDIT_LOW_PTI'

            WHEN bs.large_exposure_low_risk_condition IS TRUE
                THEN 'LARGE_EXPOSURE_LOW_RISK'

            WHEN bs.high_risk_low_exposure_condition IS TRUE
                THEN 'HIGH_RISK_LOW_EXPOSURE'

            WHEN bs.high_dti_low_requested_pti_condition IS TRUE
                THEN 'HIGH_DTI_LOW_REQUESTED_PTI'

            ELSE 'NO_MIXED_SIGNAL_PROFILE'
        END AS mixed_signal_profile_type

    FROM borderline_scored bs
)

SELECT *
FROM final_segments;



/***************************************************************************************************
SECTION 5.3 — LOCAL FAIL-FAST CHECKS FOR STRATEGY SEGMENTATION
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that every selected synthetic application can be described consistently before Section 6
    creates rule-trigger flags.

    Section 5.3 answers:

        "Did Section 5 preserve row-level grain and create complete diagnostic segmentation without
         prematurely creating decision output fields?"

SQL PURPOSE:
    1. Confirm Section 4 source stage still contains rows.
    2. Confirm Section 5 row count equals Section 4 row count.
    3. Confirm application_id remains unique.
    4. Confirm required segmentation fields are populated.
    5. Confirm product and score policy keys are populated.
    6. Confirm product-policy configuration remains one-to-one.
    7. Confirm required thresholds and controls are available.
    8. Confirm Section 5 did not create decision, reason-code, or approved-exposure fields.

LOCAL GATEKEEPER BOUNDARY:
    These are Section 5 staging gatekeepers only.

    They are not:
        final decision validation,
        reason-code validation,
        approved-exposure validation,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        full Module 2 QA,
        or Validation Summary evidence by themselves.

***************************************************************************************************/

DO $$
DECLARE
    v_stage1_count BIGINT;
    v_stage2_count BIGINT;
    v_stage2_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    v_null_segment_count BIGINT;
    v_null_policy_key_count BIGINT;
    v_product_policy_mismatch_count BIGINT;
    v_missing_threshold_count BIGINT;
    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 4 source stage must contain rows.

    SQL mechanics:
        COUNT(*) checks the upstream staging population.

    Business interpretation:
        If Stage 1 is empty, segmentation cannot produce a valid profile layer.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage1_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_stage1_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 4 to Section 5.

    Why this matters:
        Section 5 should add descriptors, not filter applicants or duplicate applicants.

    SQL mechanics:
        Compare Stage 1 row count to Stage 2 row count.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage2_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_count <> v_stage1_count THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: row count changed from Section 4 to Section 5. Stage 1 rows: %, Stage 2 rows: %.',
            v_stage1_count,
            v_stage2_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id must remain unique.

    Business interpretation:
        Segmentation should remain applicant-grain.

        Duplicate rows here would duplicate downstream rule triggers and decision outcomes.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage2_distinct_app_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_distinct_app_count <> v_stage2_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_2_strategy_segments
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 5 failure: segmentation stage contains duplicate application_id values. Stage 2 rows: %, distinct application_id: %, duplicate groups: %.',
            v_stage2_count,
            v_stage2_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required segmentation outputs must be populated.

    These fields are the core descriptive outputs Section 6 depends on.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_segment_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE strategy_risk_tier IS NULL
       OR requested_pti_bucket IS NULL
       OR dti_bucket IS NULL
       OR requested_exposure_tier IS NULL
       OR requested_expected_loss_tier IS NULL
       OR product_score_policy_segment IS NULL
       OR mixed_signal_profile_type IS NULL
       OR mixed_signal_condition_count IS NULL
       OR borderline_profile_flag IS NULL;

    IF v_null_segment_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have null segmentation fields.',
            v_null_segment_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product and score policy keys must be populated.

    Why this matters:
        Product × score segmentation is central to strategy QA, frontier evidence, and future
        evidence capture.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_policy_key_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE product_type_policy_key IS NULL
       OR NULLIF(BTRIM(product_type_policy_key), '') IS NULL
       OR score_band_policy_key IS NULL
       OR NULLIF(BTRIM(score_band_policy_key), '') IS NULL;

    IF v_null_policy_key_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have null or blank product / score policy keys.',
            v_null_policy_key_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: every row must still have exactly one product policy configuration.

    Section 4 validates initial product-policy mapping.
    Section 5 confirms the mapping remains visible after threshold enrichment.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_product_policy_mismatch_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE product_policy_match_count <> 1
       OR product_policy_config_found_flag IS DISTINCT FROM TRUE;

    IF v_product_policy_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) no longer have exactly one product policy configuration.',
            v_product_policy_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: all thresholds needed for segmentation and later rule logic must be available.

    Why this matters:
        Section 6 expects these values to be present when it builds rule-trigger flags.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_missing_threshold_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE approve_max_estimated_pd_proxy IS NULL
       OR counteroffer_max_estimated_pd_proxy IS NULL
       OR review_max_estimated_pd_proxy IS NULL
       OR decline_min_estimated_pd_proxy IS NULL

       OR global_approve_max_pti IS NULL
       OR global_review_max_pti IS NULL
       OR global_decline_min_pti IS NULL

       OR approve_max_dti IS NULL
       OR review_max_dti IS NULL
       OR decline_min_dti IS NULL

       OR borderline_threshold_buffer_pct IS NULL

       OR bankruptcy_policy_stop_enabled IS NULL
       OR major_derogatory_policy_stop_enabled IS NULL
       OR severe_delinquency_policy_stop_enabled IS NULL
       OR severe_delinquency_count_threshold IS NULL
       OR high_utilization_review_enabled IS NULL
       OR high_utilization_review_threshold IS NULL
       OR low_score_review_enabled IS NULL
       OR low_score_review_threshold IS NULL

       OR product_policy_profile_code IS NULL
       OR product_approve_max_pti IS NULL
       OR product_review_max_pti IS NULL
       OR product_decline_min_pti IS NULL
       OR counteroffer_target_pti IS NULL

       OR product_approve_max_requested_el IS NULL
       OR product_review_max_requested_el IS NULL
       OR product_decline_min_requested_el IS NULL
       OR product_approved_el_cap IS NULL
       OR requested_el_low_moderate_split IS NULL

       OR product_min_approved_amount IS NULL
       OR product_max_approved_amount IS NULL

       OR counteroffer_allowed_flag IS NULL
       OR manual_review_allowed_flag IS NULL
       OR product_min_counteroffer_pct IS NULL
       OR product_max_exposure_reduction_pct IS NULL
       OR exposure_assignment_method IS NULL
       OR approved_amount_rounding_increment IS NULL;

    IF v_missing_threshold_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have missing threshold or product policy values.',
            v_missing_threshold_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 5 must not create decision, reason-code, or approved-exposure fields.

    This protects the staged architecture boundary.

    SQL mechanics:
        pg_attribute inspects the physical columns of the temp table.

        If any downstream-only field exists, Section 5 fails.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_2_strategy_segments'::REGCLASS
      AND attnum > 0
      AND NOT attisdropped
      AND attname IN (
            'decision_outcome',
            'decision_path',
            'approval_flag',
            'decline_flag',
            'manual_review_flag',
            'counteroffer_flag',
            'simulated_offer_exposure_flag',

            'primary_reason_code',
            'secondary_reason_code',
            'tertiary_reason_code',
            'triggered_reason_code_list',
            'reason_priority_rank',
            'primary_reason_family',

            'approved_amount',
            'counteroffer_amount',
            'approved_monthly_payment_proxy',
            'approved_payment_to_income_ratio',
            'approved_expected_loss_amount'
      );

    IF v_forbidden_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: forbidden decision, reason-code, or approved-exposure field(s) were created in segmentation stage.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 5.4 — LOCAL SEGMENTATION SANITY CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide lightweight diagnostics for Section 5 segmentation.

    Section 5.4 answers:

        "What diagnostic profile did Section 5 create, and does that profile look ready for Section 6
         rule-trigger construction?"

SQL PURPOSE:
    Display review outputs for:
        row count,
        application_id uniqueness,
        Module 1 lineage,
        Module 2 strategy identity,
        product-policy profile attachment,
        synthetic estimated-risk tier distribution,
        requested PTI bucket distribution,
        DTI bucket distribution,
        requested exposure tier distribution,
        requested Expected Loss tier distribution,
        product × score segment distribution,
        mixed-signal profile distribution,
        borderline profile distribution,
        product × risk tier distribution,
        score band × risk tier distribution,
        requested PTI bucket × risk tier distribution,
        and one compact readiness summary.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        final strategy validation,
        final decision distribution,
        reason-code coverage,
        archive comparison,
        strategy frontier evidence,
        or Validation Summary acceptance.

SQL TEACHING POINT:
    These queries use GROUP BY and COUNT(*) FILTER to summarize diagnostic categories.

    They are not mutating queries.

    They do not alter segmentation results.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
5.4.1 Row count and distinct application_id count.

Expected:
    stage2_row_count = distinct_application_id_count.

Interpretation:
    Confirms the segmentation layer is still one row per application.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS stage2_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_2_strategy_segments;



/*-----------------------------------------------------------------------------------------------
5.4.2 Module 1 lineage and Module 2 strategy identity.

Purpose:
    Confirm that Section 5 preserved the selected source and active strategy identity.

Expected:
    one row.

Interpretation:
    Module 1 fields identify the upstream synthetic scenario / population.
    Module 2 fields identify the downstream strategy applied to that population.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,

    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
5.4.3 Product-policy profile attachment.

Purpose:
    Confirm that the active product-policy profile was attached to staged segmentation rows.

Expected:
    one product_policy_profile_code for a given run.

Interpretation:
    This confirms which product-policy profile is driving product-level segmentation controls.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_policy_profile_code,
    product_type_policy_key,
    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    product_policy_profile_code,
    product_type_policy_key
ORDER BY
    product_policy_profile_code,
    product_type_policy_key;



/*-----------------------------------------------------------------------------------------------
5.4.4 Count by synthetic estimated-risk tier.

Purpose:
    Review segmentation by synthetic estimated-risk tier.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

    The average estimated_pd by tier should generally increase from LOW_SYNTHETIC_RISK toward
    SEVERE_SYNTHETIC_RISK.

Boundary:
    This is a segmentation diagnostic, not final risk validation.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    MIN(estimated_pd) AS min_synthetic_estimated_pd_proxy,
    MAX(estimated_pd) AS max_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY strategy_risk_tier
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.5 Count by requested PTI bucket.

Purpose:
    Review requested-structure affordability segmentation.

Interpretation:
    This is requested-structure affordability, not approved affordability.

    Approved PTI does not exist yet.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    MIN(requested_payment_to_income_ratio) AS min_requested_payment_to_income_ratio,
    MAX(requested_payment_to_income_ratio) AS max_requested_payment_to_income_ratio
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_pti_bucket
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.6 Count by DTI bucket.

Purpose:
    Review existing-obligation capacity segmentation.

Interpretation:
    DTI reflects existing-obligation capacity and is not directly corrected by counteroffer.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_bucket,
    COUNT(*) AS row_count,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    MIN(debt_to_income_ratio) AS min_debt_to_income_ratio,
    MAX(debt_to_income_ratio) AS max_debt_to_income_ratio
FROM tmp_m2_stage_2_strategy_segments
GROUP BY dti_bucket
ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.7 Count by requested exposure tier.

Purpose:
    Review requested exposure intensity relative to product policy limits.

Interpretation:
    This describes requested exposure relative to product policy limits.

    It does not assign approved_amount.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_exposure_tier,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    MIN(requested_amount) AS min_requested_amount,
    MAX(requested_amount) AS max_requested_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_exposure_tier
ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'LOW_REQUESTED_EXPOSURE' THEN 2
        WHEN 'WITHIN_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 4
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.8 Count by requested Expected Loss tier.

Purpose:
    Review requested-exposure Expected Loss segmentation.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount does not exist yet.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_expected_loss_tier,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    MIN(requested_expected_loss_amount) AS min_requested_expected_loss_amount,
    MAX(requested_expected_loss_amount) AS max_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_expected_loss_tier
ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.9 Product × score segment distribution.

Purpose:
    Review product × score segmentation.

Interpretation:
    This is the key segment dimension used later for product × score evidence capture.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment
ORDER BY
    product_type_policy_key,
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.10 Mixed-signal profile distribution.

Purpose:
    Review realistic overlapping applicant profiles.

Interpretation:
    Mixed-signal profiles are diagnostic only.

    They help explain why later outcomes may not sort perfectly by one variable.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    mixed_signal_condition_count,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    mixed_signal_profile_type,
    mixed_signal_condition_count
ORDER BY
    mixed_signal_condition_count DESC,
    mixed_signal_profile_type;



/*-----------------------------------------------------------------------------------------------
5.4.11 Borderline profile distribution.

Purpose:
    Review how many rows are threshold-adjacent.

Interpretation:
    borderline_profile_flag is diagnostic only.

    It is not automatic manual review.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY borderline_profile_flag
ORDER BY borderline_profile_flag;



/*-----------------------------------------------------------------------------------------------
5.4.12 Product × synthetic estimated-risk tier.

Purpose:
    Show how synthetic estimated-risk tiers distribute by product.

Interpretation:
    Product mix can explain later outcome patterns.

    This diagnostic helps avoid overinterpreting portfolio averages.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    product_type_policy_key,
    strategy_risk_tier
ORDER BY
    product_type_policy_key,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.13 Score band × synthetic estimated-risk tier.

Purpose:
    Review whether score-band segmentation and synthetic estimated-risk tiering are directionally
    coherent.

Interpretation:
    Score band and estimated_pd are different fields, but they should generally align directionally.

    Perfect separation is not required because Module 1 intentionally preserves realistic overlap.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    score_band_policy_key,
    strategy_risk_tier
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.14 Requested PTI bucket × synthetic estimated-risk tier.

Purpose:
    Review how requested affordability pressure overlaps with synthetic estimated-risk tier.

Interpretation:
    Requested PTI and estimated_pd can overlap in realistic ways.

    Section 5 should preserve those interactions instead of flattening them.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    requested_pti_bucket,
    strategy_risk_tier
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
5.4.15 Section 5 readiness summary.

Purpose:
    Provide one compact readiness row for the segmentation stage.

Expected:
    section_5_segmentation_status = SECTION_5_SEGMENTATION_READY_FOR_RULE_FLAGS

Interpretation:
    This confirms only that Section 5 is ready for Section 6.

    It does not validate final strategy outcomes.
-----------------------------------------------------------------------------------------------*/

WITH segmentation_summary AS (
    SELECT
        COUNT(*) AS stage2_row_count,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) FILTER (
            WHERE strategy_risk_tier IS NULL
               OR requested_pti_bucket IS NULL
               OR dti_bucket IS NULL
               OR requested_exposure_tier IS NULL
               OR requested_expected_loss_tier IS NULL
               OR score_band_policy_key IS NULL
               OR product_score_policy_segment IS NULL
               OR mixed_signal_profile_type IS NULL
               OR mixed_signal_condition_count IS NULL
               OR borderline_profile_flag IS NULL
        ) AS segmentation_gap_rows,

        COUNT(*) FILTER (
            WHERE product_policy_match_count <> 1
               OR product_policy_config_found_flag IS DISTINCT FROM TRUE
        ) AS product_policy_match_gap_rows,

        COUNT(DISTINCT (
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS distinct_module1_scenario_population_count,

        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version
        )) AS distinct_module2_strategy_count,

        COUNT(DISTINCT product_score_policy_segment) AS distinct_product_score_segments,

        COUNT(*) FILTER (
            WHERE borderline_profile_flag IS TRUE
        ) AS borderline_profile_rows,

        COUNT(*) FILTER (
            WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
        ) AS mixed_signal_profile_rows

    FROM tmp_m2_stage_2_strategy_segments
)

SELECT
    stage2_row_count,
    distinct_application_id_count,
    segmentation_gap_rows,
    product_policy_match_gap_rows,
    distinct_module1_scenario_population_count,
    distinct_module2_strategy_count,
    distinct_product_score_segments,
    borderline_profile_rows,
    mixed_signal_profile_rows,

    CASE
        WHEN stage2_row_count > 0
         AND stage2_row_count = distinct_application_id_count
         AND segmentation_gap_rows = 0
         AND product_policy_match_gap_rows = 0
         AND distinct_module1_scenario_population_count = 1
         AND distinct_module2_strategy_count = 1
            THEN 'SECTION_5_SEGMENTATION_READY_FOR_RULE_FLAGS'
        ELSE 'REVIEW_SECTION_5_SEGMENTATION_BEFORE_RULE_FLAGS'
    END AS section_5_segmentation_status

FROM segmentation_summary;



/***************************************************************************************************
END OF SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER

If execution reaches this point:
    1. Section 5 dependency preflight passed.
    2. tmp_m2_stage_2_strategy_segments exists.
    3. Row count is unchanged from tmp_m2_stage_1_source_applications.
    4. application_id remains unique.
    5. All Section 4 source and lineage fields are preserved.
    6. Module 2 strategy metadata is preserved.
    7. Global strategy thresholds are attached.
    8. Product policy thresholds and controls are attached.
    9. product_policy_profile_code is attached.
    10. score_band_policy_key is created.
    11. strategy_risk_tier is created.
    12. requested_pti_bucket is created.
    13. dti_bucket is created.
    14. requested_exposure_tier is created.
    15. requested_expected_loss_tier is created.
    16. product_score_policy_segment is created.
    17. mixed_signal_profile_type and mixed_signal_condition_count are created.
    18. borderline_profile_flag is created using governed borderline_threshold_buffer_pct.
    19. requested_expected_loss_amount remains requested-exposure Expected Loss.
    20. estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy.
    21. Section 5 local staging gatekeepers passed.
    22. Section 5 local segmentation diagnostics are available for review.

Section 5 established:
    1. The non-decisioning applicant-description layer.
    2. Strategy-threshold visibility at applicant grain.
    3. Product-policy visibility at applicant grain.
    4. Score-band normalization.
    5. Risk, affordability, DTI, exposure, Expected Loss, mixed-signal, and borderline diagnostic
       segmentation.
    6. The staging foundation Section 6 needs for rule-trigger construction.

No final decision outcomes have been created.
No preliminary decision routes have been created.
No decision flags have been created.
No simulated offer-exposure flag has been created.
No simulated reason codes have been assigned.
No approved amount has been calculated.
No counteroffer amount has been calculated.
No approved payment has been calculated.
No approved PTI has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full QA framework has been built.

Next section:
    Section 6 should consume tmp_m2_stage_2_strategy_segments and create the non-final rule-trigger
    flag layer.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01534 -->


---

<a id="c038-m01535"></a>

### C038-M01535

**Andrew** · 2026-05-12T09:37:16.753000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01535 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 6 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01535 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_74.md) · [Next](Part_76.md)
