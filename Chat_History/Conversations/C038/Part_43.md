# Module 2 Decision Simulator Build

## Part 43

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_42.md) · [Next](Part_44.md)

<a id="c038-m00920"></a>

### C038-M00920

**ChatGPT** · 2026-05-09T23:41:15.010728-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00920 -->
I recommend replacing Section 6 with the version below. I preserved the functional rule logic from your current Section 6, added a small dependency preflight, and strengthened the instructional commentary so the section teaches the run logic, credit-risk concepts, and SQL mechanics at the same standard as Sections 0–5. fileciteturn92file0

```sql
/***************************************************************************************************
SECTION 6 — RULE FLAG CONSTRUCTION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Convert Section 5 diagnostic segments into deterministic, auditable simulated rule-trigger flags.

    Section 6 answers:

        "Which simulated policy, risk, affordability, exposure, Expected Loss, counteroffer,
         manual-review, and supplemental review conditions are triggered for this synthetic
         applicant?"

    Section 6 does not answer:

        "What is the final simulated strategy outcome?"

    Section 6 is the trigger-evidence layer.

    It does not decide the applicant. It identifies the signals that later routing, exposure
    treatment, final decision resolution, and reason-code assignment will use.

SQL PURPOSE:
    1. Confirm required Section 6 dependencies exist.
    2. Read from tmp_m2_stage_2_strategy_segments.
    3. Preserve all prior source, lineage, strategy metadata, threshold, product policy, and
       segmentation fields.
    4. Create transparent non-final rule-trigger flags across:
            hard simulated policy stops,
            synthetic estimated-risk bands,
            requested affordability,
            DTI capacity,
            requested Expected Loss,
            requested exposure,
            counteroffer candidates,
            manual-review candidates,
            supplemental behavioral review signals,
            clean approval candidate diagnostics.
    5. Create numeric trigger-count fields.
    6. Create true banding-family coverage diagnostics for synthetic estimated-risk and DTI.
    7. Validate flag completeness, count-field integrity, banding-family coverage, candidate-rule
       consistency, and no premature final outcome / reason-code / approved-exposure output creation.
    8. Provide local rule-flag diagnostics before Section 7 preliminary routing.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the trigger families represent intuitive strategy signals before they are
        prioritized into preliminary routes.

    Model governance / validation reviewers:
        Confirm that Section 6 remains a non-final trigger layer and does not prematurely assign
        decisions, approved exposure, or reason codes.

    SQL reviewers:
        Confirm that each trigger family is built through readable CTEs, that true banding families
        are locally validated, and that broader trigger families are intentionally allowed to overlap.

    Portfolio / executive reviewers:
        Use Section 6 diagnostics to understand what kinds of strategy pressures exist in the
        selected population before final outcomes are interpreted.

WHEN TO RUN THIS SECTION:
    Run Section 6 after:

        Section 5 — Derived Strategy Segmentation Layer

    Section 6 should be run before:

        Section 7 — Preliminary Decision Routing Layer

    Section 6 depends on:

        tmp_m2_stage_2_strategy_segments

HOW TO INTERPRET THIS SECTION:
    Passing Section 6 means:
        row count is preserved from Section 5,
        application_id remains unique,
        rule-trigger flags are complete,
        count fields are valid,
        synthetic estimated-risk banding covers every row exactly once,
        DTI banding covers every row exactly once,
        product counteroffer and manual-review permissions are respected,
        and no final decision, reason-code, or approved-exposure fields were created early.

    Passing Section 6 does not mean:
        a final decision has been assigned,
        a preliminary route has been assigned,
        a counteroffer is feasible,
        approved exposure exists,
        approved PTI exists,
        approved Expected Loss exists,
        reason codes are complete,
        archive persistence worked,
        or full validation has passed.

INPUT:
    tmp_m2_stage_2_strategy_segments

OUTPUT:
    tmp_m2_stage_3_rule_flags

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

WHY RULE FLAGS ARE SEPARATED FROM FINAL DECISION HIERARCHY:
    Multiple simulated policy conditions can validly coexist on the same synthetic applicant.

    A row may simultaneously show:
        requested PTI pressure,
        requested Expected Loss pressure,
        requested exposure pressure,
        mixed-signal diagnostics,
        borderline diagnostics,
        supplemental review signals,
        counteroffer candidacy,
        and manual-review candidacy.

    Section 6 preserves overlapping triggers.

    Section 7 prioritizes those overlapping triggers into one preliminary route.

    Section 8 calculates approved exposure and counteroffer feasibility.

    Section 9 resolves final decision_outcome after exposure treatment and counteroffer feasibility.

    Section 10 assigns simulated reason codes after the final outcome exists.

WHY HARD SIMULATED POLICY STOP FLAGS ARE NOT FINAL DECLINES YET:
    Section 6 identifies severe simulated policy-stop trigger conditions.

    Final decision resolution remains downstream because Module 2 is intentionally staged:

        trigger identification
        → preliminary routing
        → exposure treatment
        → final decision resolution
        → reason-code assignment

    This design makes it easier to audit where each outcome came from.

WHY TRUE BANDING FAMILIES ARE CHECKED:
    Some rule families are true bands.

    Synthetic estimated-risk band:
        exactly one of clean approval band, counteroffer band, review band, or decline trigger should
        be TRUE for every row.

    DTI band:
        exactly one of clean, review, or decline trigger should be TRUE for every row.

    These band families are locally validated because gaps or overlaps would indicate threshold
    coverage defects.

WHY BROADER TRIGGER FAMILIES ARE NOT MADE MUTUALLY EXCLUSIVE:
    Requested affordability, requested Expected Loss, requested exposure, mixed-signal diagnostics,
    supplemental review signals, counteroffer candidacy, and manual-review candidacy may overlap by
    design.

    Section 6 is a trigger layer, not a final decision hierarchy.

    Do not use Section 6 to erase valid overlapping strategy signals.

CREDIT RISK CONCEPT — POLICY STOPS:
    Hard simulated policy stops identify severe synthetic conditions such as bankruptcy, major
    derogatory history, or severe recent delinquency.

    In this simulator, they are high-priority trigger evidence.

    They are not real adverse-action determinations and not production compliance outputs.

CREDIT RISK CONCEPT — SYNTHETIC ESTIMATED-RISK BANDING:
    estimated_pd remains the finalized Module 1 SQL field.

    In Module 2, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 6 uses estimated_pd to place each row into one and only one synthetic-risk band.

    Section 6 does not:
        recalculate estimated_pd,
        calibrate a default model,
        validate production default forecasting,
        or create a post-decision risk model.

CREDIT RISK CONCEPT — REQUESTED PTI:
    Requested PTI flags use requested_payment_to_income_ratio from the original Module 1 requested
    structure.

    Approved PTI does not exist yet.

    approved_payment_to_income_ratio is calculated later only after exposure treatment.

    Section 6 therefore flags requested affordability pressure, not approved affordability.

CREDIT RISK CONCEPT — DTI:
    DTI remains an existing-obligation capacity signal.

    It is not directly counteroffer-adjustable in Module 2 V1.0 because a counteroffer changes
    simulated requested-exposure treatment, not the applicant's existing obligations.

CREDIT RISK CONCEPT — REQUESTED EXPECTED LOSS:
    Requested Expected Loss flags use requested_expected_loss_amount.

    requested_expected_loss_amount is the Module 2 alias for Module 1 requested-exposure Expected
    Loss.

    approved_expected_loss_amount does not exist yet.

    Section 6 therefore flags requested-exposure Expected Loss pressure, not approved-exposure
    Expected Loss after strategy treatment.

COUNTEROFFER CANDIDATE BOUNDARY:
    Section 6 identifies counteroffer candidates only.

    A counteroffer candidate is not necessarily a feasible counteroffer.

    Section 6 does not calculate:
        approved_amount,
        counteroffer_amount,
        approved monthly payment proxy,
        approved PTI,
        approved Expected Loss,
        counteroffer feasibility.

MANUAL REVIEW CANDIDATE BOUNDARY:
    Section 6 identifies manual-review candidates only.

    It does not assign MANUAL_REVIEW as final decision_outcome.

    Manual review remains unresolved until final decision resolution.

CLEAN APPROVAL CANDIDATE BOUNDARY:
    clean_approval_candidate_flag is diagnostic only.

    It identifies rows that are clean across major trigger families.

    It does not assign APPROVE.
    It does not create approved exposure.
    It does not create simulated offer exposure.

SUPPLEMENTAL BEHAVIORAL REVIEW FLAG BOUNDARY:
    high_utilization_review_trigger_flag and low_score_review_trigger_flag are simulated strategy
    diagnostics.

    They are not production underwriting rules.
    They are not final outcomes.
    They are not reason codes.

REASON-CODE BOUNDARY:
    Section 6 does not assign:
        primary_reason_code,
        secondary_reason_code,
        tertiary_reason_code,
        triggered_reason_code_list,
        reason_priority_rank,
        primary_reason_family.

    Reason-code assignment occurs after final decision resolution.

FINAL OUTCOME BOUNDARY:
    Section 6 does not assign:
        decision_outcome,
        decision_path,
        approval_flag,
        decline_flag,
        manual_review_flag,
        counteroffer_flag,
        simulated_offer_exposure_flag.

APPROVED-EXPOSURE BOUNDARY:
    Section 6 does not calculate:
        approved_amount,
        counteroffer_amount,
        approved_monthly_payment_proxy,
        approved_payment_to_income_ratio,
        approved_expected_loss_amount.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the rule-trigger layer as a session-scoped staging table.

    ON COMMIT PRESERVE ROWS:
        Keeps the staging table available across transaction boundaries in the active session.

    CTE chain:
        Breaks rule construction into readable steps:
            hard_policy_stop_flags
            hard_policy_stop_counted
            synthetic_risk_flags
            synthetic_risk_counted
            affordability_flags
            affordability_counted
            dti_flags
            dti_counted
            requested_el_flags
            requested_el_counted
            exposure_flags
            exposure_counted
            counteroffer_candidate_flags
            counteroffer_candidate_counted
            supplemental_behavior_flags
            supplemental_behavior_counted
            manual_review_candidate_flags
            manual_review_candidate_counted
            clean_approval_diagnostic
            final_rule_flags

    Boolean expressions:
        Convert strategy conditions into TRUE / FALSE trigger fields.

    ::INT:
        Converts TRUE / FALSE flags into 1 / 0 so trigger-count fields can be calculated.

    CASE is intentionally not used for final outcome assignment here:
        Section 6 is not the final decision hierarchy.

    COUNT(*) and COUNT(DISTINCT application_id):
        Validate row preservation and grain.

    pg_attribute:
        Inspects physical table columns to confirm downstream-only fields were not created too early.

GOVERNANCE ROLE:
    Section 6 turns diagnostic profile fields into transparent trigger evidence.

    It gives downstream routing and reason-code sections a clear foundation while preserving all
    overlapping trigger signals for QA and auditability.

TESTING RELEVANCE:
    Section 6 local diagnostics help reviewers confirm that trigger families behave as expected before
    preliminary routing converts them into one route per application.

DOWNSTREAM DEPENDENCY:
    Section 7 consumes tmp_m2_stage_3_rule_flags.

    Section 7 should not read directly from Section 5 because Section 6 creates the required trigger
    evidence used for preliminary routing.

COMMON MISUSE TO AVOID:
    Do not interpret hard_policy_stop_flag as a final decline.
    Do not interpret counteroffer_candidate_flag as a feasible counteroffer.
    Do not interpret manual_review_candidate_flag as final manual review.
    Do not interpret clean_approval_candidate_flag as final approval.
    Do not interpret requested_pti_decline_trigger_flag as approved affordability failure.
    Do not interpret requested_el_decline_trigger_flag as approved Expected Loss failure.
    Do not expect broad trigger families to be mutually exclusive.
    Do not use Section 6 as the final decision output.

***************************************************************************************************/



/***************************************************************************************************
SECTION 6.0 — SECTION 6 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 5 segmentation output exists and is populated before rule-trigger
    construction begins.

    Section 6.0 answers:

        "Can Section 6 safely build rule-trigger flags from the Section 5 segmentation layer?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_2_strategy_segments exists.
    2. Confirm the segmentation table contains rows.
    3. Confirm application_id remains unique before rule flags are added.
    4. Confirm required Section 5 segmentation fields are present.
    5. Fail clearly if Section 6 is run out of order.

WHY THIS PREFLIGHT EXISTS:
    Section 6 is a transformation layer.

    It should fail with a clear instructional message if Section 5 has not run, rather than producing
    a lower-level missing-table error.

BOUNDARY:
    Section 6.0 does not create rule flags.
    Section 6.0 does not create decisions.
    Section 6.0 does not create reason codes.
    Section 6.0 does not calculate approved exposure.
    Section 6.0 does not modify any persistent table.

***************************************************************************************************/

DO $$
DECLARE
    v_stage2_exists BOOLEAN;
    v_stage2_row_count BIGINT;
    v_stage2_distinct_application_count BIGINT;
    v_required_segment_gap_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 5 segmentation table must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

        pg_temp is checked because tmp_m2_stage_2_strategy_segments is a temporary table.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_2_strategy_segments'),
        TO_REGCLASS('tmp_m2_stage_2_strategy_segments')
    ) IS NOT NULL
    INTO v_stage2_exists;

    IF v_stage2_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: tmp_m2_stage_2_strategy_segments is required. Run Section 5 before Section 6.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 5 segmentation table must contain rows.

    Business interpretation:
        Rule-trigger construction over an empty applicant population is not useful and usually means
        an upstream source-selection or segmentation issue.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage2_row_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: tmp_m2_stage_2_strategy_segments contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id should be unique before rule flags are added.

    Section 6 should add columns only. It should not repair grain problems from earlier stages.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage2_distinct_application_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_distinct_application_count <> v_stage2_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: tmp_m2_stage_2_strategy_segments is not unique at application_id. Rows=%, distinct application_id=%.',
            v_stage2_row_count,
            v_stage2_distinct_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 5 segmentation fields required by Section 6 should be populated.

    Business interpretation:
        Section 6 depends on Section 5 describing risk, affordability, DTI, exposure, Expected Loss,
        mixed-signal, and borderline profile context.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_segment_gap_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE strategy_risk_tier IS NULL
       OR requested_pti_bucket IS NULL
       OR dti_bucket IS NULL
       OR requested_exposure_tier IS NULL
       OR requested_expected_loss_tier IS NULL
       OR product_type_policy_key IS NULL
       OR score_band_policy_key IS NULL
       OR product_score_policy_segment IS NULL
       OR mixed_signal_profile_type IS NULL
       OR mixed_signal_condition_count IS NULL
       OR borderline_profile_flag IS NULL;

    IF v_required_segment_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % Section 5 row(s) are missing required segmentation fields needed for rule-trigger construction.',
            v_required_segment_gap_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 6.1 — CLEAN RESET OF SECTION 6 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 6 rule-flag stage before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 6 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale rule-trigger rows to remain available to Section 7.

    Section 7 assumes tmp_m2_stage_3_rule_flags reflects the current:
        Section 5 segmentation output,
        active strategy parameters already carried forward,
        product policy thresholds already carried forward,
        and current rule-control settings.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the table does not exist, PostgreSQL does not error.

BOUNDARY:
    This drop affects only the temporary Section 6 staging object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;



/***************************************************************************************************
SECTION 6.2 — CREATE RULE FLAG STAGING TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_3_rule_flags

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_2_strategy_segments

OUTPUT:
    All Section 5 fields plus:
        hard simulated policy stop flags,
        synthetic estimated-risk band flags,
        requested PTI flags,
        DTI flags,
        requested Expected Loss flags,
        requested exposure flags,
        counteroffer candidate flags,
        supplemental behavioral review flags,
        manual-review candidate flags,
        clean approval candidate flag,
        trigger count fields,
        true banding-family coverage counts.

SQL DESIGN:
    This section uses a CTE chain to build trigger families step by step.

    The goal is not the shortest SQL.

    The goal is auditable SQL where reviewers can see:
        how each trigger family is created,
        how each trigger count is calculated,
        how true banding coverage is checked,
        and how final routing remains deferred.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 6 intentionally preserves all prior fields plus rule-trigger diagnostics for downstream
    preliminary routing.

    Permanent output selection is handled later with an explicit field list in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_3_rule_flags
ON COMMIT PRESERVE ROWS
AS
WITH hard_policy_stop_flags AS (
    /***********************************************************************************************
    CTE: hard_policy_stop_flags

    Purpose:
        Create individual hard simulated policy stop flags.

    Credit risk interpretation:
        These flags identify severe policy-stop-style conditions.

        They are high-priority trigger evidence, but they are not final declines in Section 6.

    SQL mechanics:
        Each Boolean flag is TRUE only when:
            the strategy parameter enables the policy-stop family,
            and the corresponding applicant/source indicator is TRUE or meets threshold.

    Boundary:
        No final decision is assigned in this CTE.
    ***********************************************************************************************/
    SELECT
        s.*,

        /*******************************************************************************************
        Bankruptcy simulated policy stop.

        Triggered only when the strategy enables bankruptcy stops and the Module 1 source row has
        bankruptcy_flag = TRUE.
        *******************************************************************************************/
        (
            s.bankruptcy_policy_stop_enabled IS TRUE
            AND s.bankruptcy_flag IS TRUE
        ) AS bankruptcy_policy_stop_flag,

        /*******************************************************************************************
        Major derogatory simulated policy stop.

        Triggered only when the strategy enables major derogatory stops and the source row has
        major_derogatory_flag = TRUE.
        *******************************************************************************************/
        (
            s.major_derogatory_policy_stop_enabled IS TRUE
            AND s.major_derogatory_flag IS TRUE
        ) AS major_derogatory_policy_stop_flag,

        /*******************************************************************************************
        Severe delinquency simulated policy stop.

        Triggered only when the strategy enables severe delinquency stops and the recent delinquency
        count meets or exceeds the governed threshold.
        *******************************************************************************************/
        (
            s.severe_delinquency_policy_stop_enabled IS TRUE
            AND s.delinquency_count_12m >= s.severe_delinquency_count_threshold
        ) AS severe_delinquency_policy_stop_flag

    FROM tmp_m2_stage_2_strategy_segments s
),

hard_policy_stop_counted AS (
    /***********************************************************************************************
    CTE: hard_policy_stop_counted

    Purpose:
        Roll individual hard simulated policy stop flags into:
            hard_policy_stop_flag
            hard_policy_stop_count

    SQL mechanics:
        OR creates the any-policy-stop indicator.

        Boolean::INT converts TRUE to 1 and FALSE to 0 so active policy stops can be counted.

    Interpretation:
        hard_policy_stop_count can be greater than 1 if multiple severe policy-stop signals coexist.
    ***********************************************************************************************/
    SELECT
        hps.*,

        (
            hps.bankruptcy_policy_stop_flag
            OR hps.major_derogatory_policy_stop_flag
            OR hps.severe_delinquency_policy_stop_flag
        ) AS hard_policy_stop_flag,

        (
            hps.bankruptcy_policy_stop_flag::INT
            + hps.major_derogatory_policy_stop_flag::INT
            + hps.severe_delinquency_policy_stop_flag::INT
        ) AS hard_policy_stop_count

    FROM hard_policy_stop_flags hps
),

synthetic_risk_flags AS (
    /***********************************************************************************************
    CTE: synthetic_risk_flags

    Purpose:
        Build the true synthetic estimated-risk band family.

    Credit risk interpretation:
        estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy.

        This CTE places each row into one synthetic estimated-risk band based on governed strategy
        thresholds.

    SQL mechanics:
        The four Boolean conditions are designed to cover all rows exactly once when thresholds are
        valid.

    Equality convention:
        Clean approval band:
            estimated_pd <= approve_max_estimated_pd_proxy

        Counteroffer band:
            estimated_pd > approve_max_estimated_pd_proxy
            AND estimated_pd <= counteroffer_max_estimated_pd_proxy

        Review band:
            estimated_pd > counteroffer_max_estimated_pd_proxy
            AND estimated_pd < decline_min_estimated_pd_proxy

        Decline trigger:
            estimated_pd >= decline_min_estimated_pd_proxy

    Boundary:
        The decline trigger is still not final decision_outcome.
    ***********************************************************************************************/
    SELECT
        hpsc.*,

        (
            hpsc.estimated_pd <= hpsc.approve_max_estimated_pd_proxy
        ) AS synthetic_risk_clean_approval_band_flag,

        (
            hpsc.estimated_pd > hpsc.approve_max_estimated_pd_proxy
            AND hpsc.estimated_pd <= hpsc.counteroffer_max_estimated_pd_proxy
        ) AS synthetic_risk_counteroffer_band_flag,

        (
            hpsc.estimated_pd > hpsc.counteroffer_max_estimated_pd_proxy
            AND hpsc.estimated_pd < hpsc.decline_min_estimated_pd_proxy
        ) AS synthetic_risk_review_band_flag,

        (
            hpsc.estimated_pd >= hpsc.decline_min_estimated_pd_proxy
        ) AS synthetic_risk_decline_trigger_flag

    FROM hard_policy_stop_counted hpsc
),

synthetic_risk_counted AS (
    /***********************************************************************************************
    CTE: synthetic_risk_counted

    Purpose:
        Count synthetic estimated-risk pressure triggers.

    SQL mechanics:
        This count excludes the clean approval band because clean band membership is not a trigger.

    Interpretation:
        synthetic_risk_trigger_count counts whether the row sits in a counteroffer, review, or
        decline synthetic-risk zone.
    ***********************************************************************************************/
    SELECT
        srf.*,

        (
            srf.synthetic_risk_counteroffer_band_flag::INT
            + srf.synthetic_risk_review_band_flag::INT
            + srf.synthetic_risk_decline_trigger_flag::INT
        ) AS synthetic_risk_trigger_count

    FROM synthetic_risk_flags srf
),

affordability_flags AS (
    /***********************************************************************************************
    CTE: affordability_flags

    Purpose:
        Create requested PTI affordability flags.

    Credit risk interpretation:
        PTI means payment-to-income ratio.

        These flags evaluate requested_payment_to_income_ratio from the original requested structure.

        Approved PTI does not exist yet.

    SQL mechanics:
        requested_pti_counteroffer_candidate_flag intentionally uses:
            requested_payment_to_income_ratio > product_approve_max_pti

        That means it can overlap with review or decline requested-PTI triggers.

        This overlap is intentional because Section 6 preserves trigger evidence rather than forcing
        route hierarchy.
    ***********************************************************************************************/
    SELECT
        src.*,

        (
            src.requested_payment_to_income_ratio <= src.product_approve_max_pti
        ) AS requested_pti_clean_band_flag,

        (
            src.requested_payment_to_income_ratio > src.product_approve_max_pti
        ) AS requested_pti_counteroffer_candidate_flag,

        (
            src.requested_payment_to_income_ratio > src.product_approve_max_pti
            AND src.requested_payment_to_income_ratio < src.product_decline_min_pti
        ) AS requested_pti_review_trigger_flag,

        (
            src.requested_payment_to_income_ratio >= src.product_decline_min_pti
        ) AS requested_pti_decline_trigger_flag

    FROM synthetic_risk_counted src
),

affordability_counted AS (
    /***********************************************************************************************
    CTE: affordability_counted

    Purpose:
        Count requested PTI affordability trigger pressure.

    SQL mechanics:
        Counteroffer, review, and decline requested-PTI flags may overlap diagnostically.

        Section 7 and later stages determine route priority.
    ***********************************************************************************************/
    SELECT
        af.*,

        (
            af.requested_pti_counteroffer_candidate_flag::INT
            + af.requested_pti_review_trigger_flag::INT
            + af.requested_pti_decline_trigger_flag::INT
        ) AS affordability_trigger_count

    FROM affordability_flags af
),

dti_flags AS (
    /***********************************************************************************************
    CTE: dti_flags

    Purpose:
        Build the true DTI capacity band family.

    Credit risk interpretation:
        DTI is an existing-obligation capacity signal.

        It is not directly counteroffer-adjustable in Module 2 V1.0.

    SQL mechanics:
        The three flags are designed to cover each row exactly once:
            clean,
            review,
            decline.

    Boundary:
        DTI decline trigger is not final decision_outcome in Section 6.
    ***********************************************************************************************/
    SELECT
        ac.*,

        (
            ac.debt_to_income_ratio <= ac.approve_max_dti
        ) AS dti_clean_band_flag,

        (
            ac.debt_to_income_ratio > ac.approve_max_dti
            AND ac.debt_to_income_ratio < ac.decline_min_dti
        ) AS dti_review_trigger_flag,

        (
            ac.debt_to_income_ratio >= ac.decline_min_dti
        ) AS dti_decline_trigger_flag

    FROM affordability_counted ac
),

dti_counted AS (
    /***********************************************************************************************
    CTE: dti_counted

    Purpose:
        Count DTI trigger pressure.

    SQL mechanics:
        This count excludes the clean DTI band because it is not a trigger condition.
    ***********************************************************************************************/
    SELECT
        df.*,

        (
            df.dti_review_trigger_flag::INT
            + df.dti_decline_trigger_flag::INT
        ) AS dti_trigger_count

    FROM dti_flags df
),

requested_el_flags AS (
    /***********************************************************************************************
    CTE: requested_el_flags

    Purpose:
        Create requested Expected Loss trigger flags.

    Credit risk interpretation:
        requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

        approved_expected_loss_amount does not exist yet.

    SQL mechanics:
        requested_el_counteroffer_candidate_flag intentionally uses:
            requested_expected_loss_amount > product_approve_max_requested_el

        That means it can overlap with requested Expected Loss review or decline triggers.

        This overlap is intentional because Section 6 preserves trigger evidence rather than forcing
        route hierarchy.
    ***********************************************************************************************/
    SELECT
        dc.*,

        (
            dc.requested_expected_loss_amount <= dc.product_approve_max_requested_el
        ) AS requested_el_clean_band_flag,

        (
            dc.requested_expected_loss_amount > dc.product_approve_max_requested_el
        ) AS requested_el_counteroffer_candidate_flag,

        (
            dc.requested_expected_loss_amount > dc.product_approve_max_requested_el
            AND dc.requested_expected_loss_amount < dc.product_decline_min_requested_el
        ) AS requested_el_review_trigger_flag,

        (
            dc.requested_expected_loss_amount >= dc.product_decline_min_requested_el
        ) AS requested_el_decline_trigger_flag

    FROM dti_counted dc
),

requested_el_counted AS (
    /***********************************************************************************************
    CTE: requested_el_counted

    Purpose:
        Count requested Expected Loss trigger pressure.

    SQL mechanics:
        Counteroffer, review, and decline requested-Expected-Loss flags may overlap diagnostically.

        Section 7 and later stages determine route priority.
    ***********************************************************************************************/
    SELECT
        ref.*,

        (
            ref.requested_el_counteroffer_candidate_flag::INT
            + ref.requested_el_review_trigger_flag::INT
            + ref.requested_el_decline_trigger_flag::INT
        ) AS requested_el_trigger_count

    FROM requested_el_flags ref
),

exposure_flags AS (
    /***********************************************************************************************
    CTE: exposure_flags

    Purpose:
        Create requested exposure trigger flags from the Section 5 requested_exposure_tier.

    Credit risk interpretation:
        requested_amount is original requested exposure.

        approved_amount does not exist yet.

        Above-cap requested exposure may be counteroffer-eligible.

        Below-minimum and extreme requested exposure are policy-stop candidates that downstream
        routing may convert into preliminary no-offer or unresolved-review paths.

    Boundary:
        Section 6 does not calculate counteroffer amount or approved amount.
    ***********************************************************************************************/
    SELECT
        rec.*,

        (
            rec.requested_exposure_tier = 'BELOW_PRODUCT_MINIMUM'
        ) AS requested_exposure_below_product_minimum_flag,

        (
            rec.requested_exposure_tier = 'WITHIN_PRODUCT_LIMITS'
        ) AS requested_exposure_within_product_limit_flag,

        (
            rec.requested_exposure_tier = 'ABOVE_PRODUCT_APPROVAL_CAP'
        ) AS requested_exposure_above_product_cap_flag,

        (
            rec.requested_exposure_tier = 'EXTREME_REQUESTED_EXPOSURE'
        ) AS requested_exposure_extreme_flag,

        (
            rec.requested_exposure_tier = 'ABOVE_PRODUCT_APPROVAL_CAP'
        ) AS exposure_counteroffer_candidate_flag,

        (
            rec.requested_exposure_tier IN (
                'BELOW_PRODUCT_MINIMUM',
                'EXTREME_REQUESTED_EXPOSURE'
            )
        ) AS exposure_policy_stop_candidate_flag

    FROM requested_el_counted rec
),

exposure_counted AS (
    /***********************************************************************************************
    CTE: exposure_counted

    Purpose:
        Count requested exposure trigger pressure.

    SQL mechanics:
        This is a diagnostic count and may double-count policy-stop candidate categories because it is
        meant to expose trigger pressure, not assign a final route.
    ***********************************************************************************************/
    SELECT
        ef.*,

        (
            ef.requested_exposure_below_product_minimum_flag::INT
            + ef.requested_exposure_above_product_cap_flag::INT
            + ef.requested_exposure_extreme_flag::INT
            + ef.exposure_policy_stop_candidate_flag::INT
        ) AS exposure_trigger_count

    FROM exposure_flags ef
),

counteroffer_candidate_flags AS (
    /***********************************************************************************************
    CTE: counteroffer_candidate_flags

    Purpose:
        Create individual counteroffer-candidate dimensions.

    Credit risk interpretation:
        A counteroffer candidate is a row that may need reduced-exposure feasibility testing.

        It is not a feasible counteroffer yet.

    Counteroffer candidate dimensions:
        synthetic-risk counteroffer band,
        requested PTI pressure,
        requested exposure above product cap,
        requested Expected Loss pressure.

    Boundary:
        No approved amount or counteroffer amount is calculated here.
    ***********************************************************************************************/
    SELECT
        ec.*,

        ec.counteroffer_allowed_flag AS counteroffer_allowed_by_product_flag,

        ec.synthetic_risk_counteroffer_band_flag AS counteroffer_risk_band_eligible_flag,

        ec.requested_pti_counteroffer_candidate_flag AS counteroffer_affordability_candidate_flag,

        ec.exposure_counteroffer_candidate_flag AS counteroffer_exposure_candidate_flag,

        ec.requested_el_counteroffer_candidate_flag AS counteroffer_expected_loss_candidate_flag

    FROM exposure_counted ec
),

counteroffer_candidate_counted AS (
    /***********************************************************************************************
    CTE: counteroffer_candidate_counted

    Purpose:
        Count counteroffer candidate dimensions and create the composite counteroffer candidate flag.

    SQL mechanics:
        counteroffer_candidate_trigger_count counts how many candidate dimensions are active.

        counteroffer_candidate_flag requires:
            product allows counteroffers,
            and at least one counteroffer candidate dimension is active.

    Boundary:
        Feasibility is not tested here.
    ***********************************************************************************************/
    SELECT
        ccf.*,

        (
            ccf.counteroffer_risk_band_eligible_flag::INT
            + ccf.counteroffer_affordability_candidate_flag::INT
            + ccf.counteroffer_exposure_candidate_flag::INT
            + ccf.counteroffer_expected_loss_candidate_flag::INT
        ) AS counteroffer_candidate_trigger_count,

        (
            ccf.counteroffer_allowed_by_product_flag IS TRUE
            AND (
                ccf.counteroffer_risk_band_eligible_flag
                OR ccf.counteroffer_affordability_candidate_flag
                OR ccf.counteroffer_exposure_candidate_flag
                OR ccf.counteroffer_expected_loss_candidate_flag
            )
        ) AS counteroffer_candidate_flag

    FROM counteroffer_candidate_flags ccf
),

supplemental_behavior_flags AS (
    /***********************************************************************************************
    CTE: supplemental_behavior_flags

    Purpose:
        Create supplemental behavioral review flags.

    Credit risk interpretation:
        High utilization and low score can be supplemental review signals.

        They are not final outcomes.

    SQL mechanics:
        Each flag is gated by a strategy enablement flag and a governed threshold.
    ***********************************************************************************************/
    SELECT
        ccc.*,

        (
            ccc.high_utilization_review_enabled IS TRUE
            AND ccc.utilization_rate >= ccc.high_utilization_review_threshold
        ) AS high_utilization_review_trigger_flag,

        (
            ccc.low_score_review_enabled IS TRUE
            AND ccc.credit_score <= ccc.low_score_review_threshold
        ) AS low_score_review_trigger_flag

    FROM counteroffer_candidate_counted ccc
),

supplemental_behavior_counted AS (
    /***********************************************************************************************
    CTE: supplemental_behavior_counted

    Purpose:
        Roll supplemental behavioral review signals into:
            supplemental_behavioral_review_trigger_flag
            supplemental_behavioral_review_trigger_count

    SQL mechanics:
        OR creates the any-supplemental-review indicator.

        Boolean::INT supports trigger counting.
    ***********************************************************************************************/
    SELECT
        sbf.*,

        (
            sbf.high_utilization_review_trigger_flag
            OR sbf.low_score_review_trigger_flag
        ) AS supplemental_behavioral_review_trigger_flag,

        (
            sbf.high_utilization_review_trigger_flag::INT
            + sbf.low_score_review_trigger_flag::INT
        ) AS supplemental_behavioral_review_trigger_count

    FROM supplemental_behavior_flags sbf
),

manual_review_candidate_flags AS (
    /***********************************************************************************************
    CTE: manual_review_candidate_flags

    Purpose:
        Create individual manual-review candidate dimensions.

    Credit risk interpretation:
        Manual-review candidacy captures unresolved or intermediate signal patterns that may need
        review before a final decision can be resolved.

    Manual-review candidate dimensions:
        synthetic risk review band,
        requested PTI review trigger,
        DTI review trigger,
        requested Expected Loss review trigger,
        mixed-signal profile,
        borderline profile,
        supplemental behavioral review trigger.

    Boundary:
        This does not assign MANUAL_REVIEW as final decision_outcome.
    ***********************************************************************************************/
    SELECT
        sbc.*,

        sbc.manual_review_allowed_flag AS manual_review_allowed_by_product_flag,

        sbc.synthetic_risk_review_band_flag AS manual_review_risk_trigger_flag,

        sbc.requested_pti_review_trigger_flag AS manual_review_affordability_trigger_flag,

        sbc.dti_review_trigger_flag AS manual_review_dti_trigger_flag,

        sbc.requested_el_review_trigger_flag AS manual_review_expected_loss_trigger_flag,

        (
            sbc.mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
        ) AS manual_review_mixed_signal_trigger_flag,

        sbc.borderline_profile_flag AS manual_review_borderline_trigger_flag

    FROM supplemental_behavior_counted sbc
),

manual_review_candidate_counted AS (
    /***********************************************************************************************
    CTE: manual_review_candidate_counted

    Purpose:
        Count manual-review candidate dimensions and create the composite manual review candidate
        flag.

    SQL mechanics:
        manual_review_candidate_trigger_count counts how many review-oriented dimensions are active.

        manual_review_candidate_flag requires:
            product allows manual review,
            and at least one review-oriented dimension is active.

    Boundary:
        This does not assign final manual review.
    ***********************************************************************************************/
    SELECT
        mrcf.*,

        (
            mrcf.manual_review_risk_trigger_flag::INT
            + mrcf.manual_review_affordability_trigger_flag::INT
            + mrcf.manual_review_dti_trigger_flag::INT
            + mrcf.manual_review_expected_loss_trigger_flag::INT
            + mrcf.manual_review_mixed_signal_trigger_flag::INT
            + mrcf.manual_review_borderline_trigger_flag::INT
            + mrcf.supplemental_behavioral_review_trigger_flag::INT
        ) AS manual_review_candidate_trigger_count,

        (
            mrcf.manual_review_allowed_by_product_flag IS TRUE
            AND (
                mrcf.manual_review_risk_trigger_flag
                OR mrcf.manual_review_affordability_trigger_flag
                OR mrcf.manual_review_dti_trigger_flag
                OR mrcf.manual_review_expected_loss_trigger_flag
                OR mrcf.manual_review_mixed_signal_trigger_flag
                OR mrcf.manual_review_borderline_trigger_flag
                OR mrcf.supplemental_behavioral_review_trigger_flag
            )
        ) AS manual_review_candidate_flag

    FROM manual_review_candidate_flags mrcf
),

clean_approval_diagnostic AS (
    /***********************************************************************************************
    CTE: clean_approval_diagnostic

    Purpose:
        Create clean_approval_candidate_flag.

    Credit risk interpretation:
        This flag identifies rows that appear clean across major trigger families.

    SQL mechanics:
        The row must be clean across:
            hard policy stops,
            synthetic-risk band,
            requested PTI,
            DTI,
            requested Expected Loss,
            requested exposure,
            severe triggers,
            counteroffer candidacy,
            manual-review candidacy.

    Boundary:
        This flag is diagnostic only.

        It does not assign APPROVE.
        It does not calculate approved exposure.
        It does not create simulated offer exposure.
    ***********************************************************************************************/
    SELECT
        mrcc.*,

        (
            mrcc.hard_policy_stop_flag IS FALSE
            AND mrcc.synthetic_risk_clean_approval_band_flag IS TRUE
            AND mrcc.requested_pti_clean_band_flag IS TRUE
            AND mrcc.dti_clean_band_flag IS TRUE
            AND mrcc.requested_el_clean_band_flag IS TRUE
            AND mrcc.requested_exposure_within_product_limit_flag IS TRUE
            AND mrcc.synthetic_risk_decline_trigger_flag IS FALSE
            AND mrcc.requested_pti_decline_trigger_flag IS FALSE
            AND mrcc.dti_decline_trigger_flag IS FALSE
            AND mrcc.requested_el_decline_trigger_flag IS FALSE
            AND mrcc.requested_exposure_extreme_flag IS FALSE
            AND mrcc.counteroffer_candidate_flag IS FALSE
            AND mrcc.manual_review_candidate_flag IS FALSE
        ) AS clean_approval_candidate_flag

    FROM manual_review_candidate_counted mrcc
),

final_rule_flags AS (
    /***********************************************************************************************
    CTE: final_rule_flags

    Purpose:
        Add final Section 6 count diagnostics.

    Fields created:
        synthetic_risk_band_flag_count
        dti_band_flag_count
        total_rule_trigger_count

    Why only two true banding-family coverage counts:
        Synthetic estimated-risk and DTI are true band families.

        Broader trigger families are allowed to overlap by design.
    ***********************************************************************************************/
    SELECT
        cad.*,

        /*******************************************************************************************
        Synthetic estimated-risk band coverage count.

        Expected:
            exactly 1 for every row.
        *******************************************************************************************/
        (
            cad.synthetic_risk_clean_approval_band_flag::INT
            + cad.synthetic_risk_counteroffer_band_flag::INT
            + cad.synthetic_risk_review_band_flag::INT
            + cad.synthetic_risk_decline_trigger_flag::INT
        ) AS synthetic_risk_band_flag_count,

        /*******************************************************************************************
        DTI band coverage count.

        Expected:
            exactly 1 for every row.
        *******************************************************************************************/
        (
            cad.dti_clean_band_flag::INT
            + cad.dti_review_trigger_flag::INT
            + cad.dti_decline_trigger_flag::INT
        ) AS dti_band_flag_count,

        /*******************************************************************************************
        Total rule trigger count.

        Diagnostic only.

        This is not a reason-code count.
        This is not a final decision priority rank.
        This is not a validation pass / fail metric by itself.
        *******************************************************************************************/
        (
            cad.hard_policy_stop_count
            + cad.synthetic_risk_trigger_count
            + cad.affordability_trigger_count
            + cad.dti_trigger_count
            + cad.requested_el_trigger_count
            + cad.exposure_trigger_count
            + cad.counteroffer_candidate_trigger_count
            + cad.manual_review_candidate_trigger_count
            + cad.supplemental_behavioral_review_trigger_count
        ) AS total_rule_trigger_count

    FROM clean_approval_diagnostic cad
)

SELECT *
FROM final_rule_flags;



/***************************************************************************************************
SECTION 6.3 — LOCAL FAIL-FAST CHECKS FOR RULE FLAG CONSTRUCTION
****************************************************************************************************

PURPOSE:
    Validate the Section 6 rule-trigger layer before preliminary routing is built.

BUSINESS PURPOSE:
    Ensure trigger construction is complete, internally consistent, and still within the Section 6
    non-final boundary before Section 7 creates preliminary routing.

SQL PURPOSE:
    1. Confirm row count is preserved from Section 5 to Section 6.
    2. Confirm application_id remains unique.
    3. Confirm all required rule-trigger flags are non-null.
    4. Confirm all required trigger-count fields are non-null.
    5. Confirm trigger-count fields are non-negative.
    6. Confirm synthetic estimated-risk band coverage equals exactly one active band per row.
    7. Confirm DTI band coverage equals exactly one active band per row.
    8. Confirm clean approval candidate flag does not conflict with material trigger families.
    9. Confirm product counteroffer permissions are respected.
    10. Confirm product manual-review permissions are respected.
    11. Confirm key decline-trigger equality conventions are implemented.
    12. Confirm Section 6 did not create final decision, reason-code, or approved-exposure fields.

LOCAL GATEKEEPER BOUNDARY:
    These are local staging gatekeepers only.

    They are not:
        final decision validation,
        reason-code validation,
        approved-exposure validation,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        full Module 2 QA,
        or Validation Summary evidence by themselves.

SQL MECHANICS:
    This block uses PL/pgSQL because it needs multiple diagnostic counts and fail-fast exceptions.

***************************************************************************************************/

DO $$
DECLARE
    /***********************************************************************************************
    Row-grain diagnostics.
    ***********************************************************************************************/
    v_stage2_count BIGINT;
    v_stage3_count BIGINT;
    v_stage3_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    /***********************************************************************************************
    Flag and count-field completeness diagnostics.
    ***********************************************************************************************/
    v_null_flag_count BIGINT;
    v_null_count_field_count BIGINT;
    v_negative_count_field_count BIGINT;

    /***********************************************************************************************
    Consistency diagnostics.
    ***********************************************************************************************/
    v_clean_conflict_count BIGINT;
    v_counteroffer_not_allowed_count BIGINT;
    v_manual_review_not_allowed_count BIGINT;

    /***********************************************************************************************
    Threshold equality convention diagnostics.
    ***********************************************************************************************/
    v_synthetic_risk_decline_mismatch_count BIGINT;
    v_requested_pti_decline_mismatch_count BIGINT;
    v_dti_decline_mismatch_count BIGINT;
    v_requested_el_decline_mismatch_count BIGINT;

    /***********************************************************************************************
    True banding-family coverage diagnostics.
    ***********************************************************************************************/
    v_synthetic_risk_band_coverage_violation_count BIGINT;
    v_dti_band_coverage_violation_count BIGINT;

    /***********************************************************************************************
    Section boundary diagnostic.
    ***********************************************************************************************/
    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 5 row count must be positive.

    Business purpose:
        Confirm the upstream segmentation layer has data.

    This repeats the preflight concept locally so the gatekeeper block remains self-explanatory.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage2_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: tmp_m2_stage_2_strategy_segments contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 5 to Section 6.

    Business purpose:
        Section 6 should add rule-trigger evidence only.

        It should not filter applicants or duplicate applicants.

    SQL mechanics:
        Compare Stage 2 row count to Stage 3 row count.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage3_count
    FROM tmp_m2_stage_3_rule_flags;

    IF v_stage3_count <> v_stage2_count THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: row count changed from Section 5 to Section 6. Stage 2 rows: %, Stage 3 rows: %.',
            v_stage2_count,
            v_stage3_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.

    Business purpose:
        Duplicate application_id values would duplicate downstream preliminary routes, final decisions,
        approved exposure, Expected Loss, and reason-code counts.

    SQL mechanics:
        Compare COUNT(*) to COUNT(DISTINCT application_id).
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage3_distinct_app_count
    FROM tmp_m2_stage_3_rule_flags;

    IF v_stage3_distinct_app_count <> v_stage3_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_3_rule_flags
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 6 failure: application_id uniqueness was not preserved. Stage 3 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage3_count,
            v_stage3_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required rule flags must be non-null.

    Business purpose:
        Every staged applicant should have complete trigger evidence before preliminary routing.

    SQL mechanics:
        Count rows where any required Section 6 Boolean flag is NULL.

    Interpretation:
        A NULL flag usually indicates a missing upstream field, malformed threshold, or incomplete
        CTE logic.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_flag_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE bankruptcy_policy_stop_flag IS NULL
       OR major_derogatory_policy_stop_flag IS NULL
       OR severe_delinquency_policy_stop_flag IS NULL
       OR hard_policy_stop_flag IS NULL

       OR synthetic_risk_clean_approval_band_flag IS NULL
       OR synthetic_risk_counteroffer_band_flag IS NULL
       OR synthetic_risk_review_band_flag IS NULL
       OR synthetic_risk_decline_trigger_flag IS NULL

       OR requested_pti_clean_band_flag IS NULL
       OR requested_pti_counteroffer_candidate_flag IS NULL
       OR requested_pti_review_trigger_flag IS NULL
       OR requested_pti_decline_trigger_flag IS NULL

       OR dti_clean_band_flag IS NULL
       OR dti_review_trigger_flag IS NULL
       OR dti_decline_trigger_flag IS NULL

       OR requested_el_clean_band_flag IS NULL
       OR requested_el_counteroffer_candidate_flag IS NULL
       OR requested_el_review_trigger_flag IS NULL
       OR requested_el_decline_trigger_flag IS NULL

       OR requested_exposure_below_product_minimum_flag IS NULL
       OR requested_exposure_within_product_limit_flag IS NULL
       OR requested_exposure_above_product_cap_flag IS NULL
       OR requested_exposure_extreme_flag IS NULL
       OR exposure_counteroffer_candidate_flag IS NULL
       OR exposure_policy_stop_candidate_flag IS NULL

       OR counteroffer_allowed_by_product_flag IS NULL
       OR counteroffer_risk_band_eligible_flag IS NULL
       OR counteroffer_affordability_candidate_flag IS NULL
       OR counteroffer_exposure_candidate_flag IS NULL
       OR counteroffer_expected_loss_candidate_flag IS NULL
       OR counteroffer_candidate_flag IS NULL

       OR manual_review_allowed_by_product_flag IS NULL
       OR manual_review_risk_trigger_flag IS NULL
       OR manual_review_affordability_trigger_flag IS NULL
       OR manual_review_dti_trigger_flag IS NULL
       OR manual_review_expected_loss_trigger_flag IS NULL
       OR manual_review_mixed_signal_trigger_flag IS NULL
       OR manual_review_borderline_trigger_flag IS NULL
       OR manual_review_candidate_flag IS NULL

       OR high_utilization_review_trigger_flag IS NULL
       OR low_score_review_trigger_flag IS NULL
       OR supplemental_behavioral_review_trigger_flag IS NULL

       OR clean_approval_candidate_flag IS NULL;

    IF v_null_flag_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have null rule-trigger flags.',
            v_null_flag_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: rule count fields must be non-null.

    Business purpose:
        Trigger counts support QA, preliminary routing interpretation, and later reason-code
        diagnostics.

    SQL mechanics:
        Count rows where any count field is NULL.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_count_field_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE hard_policy_stop_count IS NULL
       OR synthetic_risk_trigger_count IS NULL
       OR affordability_trigger_count IS NULL
       OR dti_trigger_count IS NULL
       OR requested_el_trigger_count IS NULL
       OR exposure_trigger_count IS NULL
       OR counteroffer_candidate_trigger_count IS NULL
       OR manual_review_candidate_trigger_count IS NULL
       OR supplemental_behavioral_review_trigger_count IS NULL
       OR synthetic_risk_band_flag_count IS NULL
       OR dti_band_flag_count IS NULL
       OR total_rule_trigger_count IS NULL;

    IF v_null_count_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have null rule-trigger count fields.',
            v_null_count_field_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: rule count fields must be non-negative.

    Business purpose:
        Trigger counts are sums of Boolean flags.

        They should never be negative.

    SQL mechanics:
        Count rows where any count field is less than zero.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_negative_count_field_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE hard_policy_stop_count < 0
       OR synthetic_risk_trigger_count < 0
       OR affordability_trigger_count < 0
       OR dti_trigger_count < 0
       OR requested_el_trigger_count < 0
       OR exposure_trigger_count < 0
       OR counteroffer_candidate_trigger_count < 0
       OR manual_review_candidate_trigger_count < 0
       OR supplemental_behavioral_review_trigger_count < 0
       OR synthetic_risk_band_flag_count < 0
       OR dti_band_flag_count < 0
       OR total_rule_trigger_count < 0;

    IF v_negative_count_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have negative rule-trigger count fields.',
            v_negative_count_field_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: synthetic estimated-risk band coverage.

    Business purpose:
        Every row must occupy exactly one synthetic estimated-risk band.

    Credit risk interpretation:
        Synthetic estimated-risk is a true banding family.

    Important:
        This does not prevent synthetic-risk triggers from overlapping with affordability, exposure,
        DTI, hard simulated policy stop, counteroffer, or manual-review candidate triggers.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_band_coverage_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE synthetic_risk_band_flag_count <> 1;

    IF v_synthetic_risk_band_coverage_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) do not occupy exactly one synthetic estimated-risk band.',
            v_synthetic_risk_band_coverage_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DTI band coverage.

    Business purpose:
        Every row must occupy exactly one DTI capacity band.

    Credit risk interpretation:
        DTI is a true capacity banding family in Module 2 V1.0.

    Important:
        This does not prevent DTI pressure from coexisting with requested PTI pressure, requested
        Expected Loss pressure, exposure pressure, mixed-signal diagnostics, or other trigger
        families.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_dti_band_coverage_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE dti_band_flag_count <> 1;

    IF v_dti_band_coverage_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) do not occupy exactly one DTI capacity band.',
            v_dti_band_coverage_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: clean approval candidate flag cannot coexist with material trigger families.

    Business purpose:
        clean_approval_candidate_flag should identify rows that are clean across major trigger
        families.

    Boundary:
        This still does not assign final APPROVE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_clean_conflict_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE clean_approval_candidate_flag IS TRUE
      AND (
            hard_policy_stop_flag IS TRUE
         OR synthetic_risk_decline_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
         OR dti_decline_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR counteroffer_candidate_flag IS TRUE
         OR manual_review_candidate_flag IS TRUE
      );

    IF v_clean_conflict_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have clean_approval_candidate_flag conflicting with material triggers.',
            v_clean_conflict_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: counteroffer_candidate_flag cannot be TRUE when product disallows counteroffer.

    Business purpose:
        Product policy controls must govern whether counteroffer treatment is available.

    Boundary:
        This validates candidate logic only. It does not test counteroffer feasibility.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_not_allowed_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE counteroffer_allowed_by_product_flag IS FALSE
      AND counteroffer_candidate_flag IS TRUE;

    IF v_counteroffer_not_allowed_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have counteroffer_candidate_flag TRUE while counteroffer is not allowed by product.',
            v_counteroffer_not_allowed_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: manual_review_candidate_flag cannot be TRUE when product disallows manual review.

    Business purpose:
        Product policy controls must govern whether manual review is available.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_not_allowed_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE manual_review_allowed_by_product_flag IS FALSE
      AND manual_review_candidate_flag IS TRUE;

    IF v_manual_review_not_allowed_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have manual_review_candidate_flag TRUE while manual review is not allowed by product.',
            v_manual_review_not_allowed_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: synthetic estimated-risk decline trigger aligns to equality convention.

    Expected:
        estimated_pd >= decline_min_estimated_pd_proxy
        implies synthetic_risk_decline_trigger_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE estimated_pd >= decline_min_estimated_pd_proxy
      AND synthetic_risk_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_synthetic_risk_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have estimated_pd >= decline_min_estimated_pd_proxy but synthetic_risk_decline_trigger_flag is not TRUE.',
            v_synthetic_risk_decline_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: requested PTI decline trigger aligns to equality convention.

    Expected:
        requested_payment_to_income_ratio >= product_decline_min_pti
        implies requested_pti_decline_trigger_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_requested_pti_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE requested_payment_to_income_ratio >= product_decline_min_pti
      AND requested_pti_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_requested_pti_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have requested PTI >= product_decline_min_pti but requested_pti_decline_trigger_flag is not TRUE.',
            v_requested_pti_decline_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DTI decline trigger aligns to equality convention.

    Expected:
        debt_to_income_ratio >= decline_min_dti
        implies dti_decline_trigger_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_dti_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE debt_to_income_ratio >= decline_min_dti
      AND dti_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_dti_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have DTI >= decline_min_dti but dti_decline_trigger_flag is not TRUE.',
            v_dti_decline_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: requested Expected Loss decline trigger aligns to equality convention.

    Expected:
        requested_expected_loss_amount >= product_decline_min_requested_el
        implies requested_el_decline_trigger_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_requested_el_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE requested_expected_loss_amount >= product_decline_min_requested_el
      AND requested_el_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_requested_el_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have requested_expected_loss_amount >= product_decline_min_requested_el but requested_el_decline_trigger_flag is not TRUE.',
            v_requested_el_decline_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 6 must not create final decision, reason-code, or approved-exposure fields.

    Business purpose:
        Protect the staged architecture boundary.

    SQL mechanics:
        pg_attribute inspects physical columns on the temporary table.

        If any downstream-only field exists, Section 6 fails.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_3_rule_flags'::REGCLASS
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
            'Module 2 Section 6 failure: forbidden final decision, reason-code, or approved-exposure field(s) were created in rule flag stage.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 6.4 — LOCAL RULE-FLAG SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 6 rule-trigger layer.

BUSINESS PURPOSE:
    Let reviewers inspect how Section 5 segmentation converted into rule-trigger evidence before
    preliminary routing begins.

SQL PURPOSE:
    Display review outputs for:
        hard simulated policy stop flags,
        synthetic estimated-risk triggers,
        requested PTI triggers,
        DTI triggers,
        requested Expected Loss triggers,
        requested exposure triggers,
        counteroffer candidate flags,
        manual-review candidate flags,
        supplemental behavioral review triggers,
        clean approval candidates,
        product × trigger summaries,
        score band × synthetic risk summaries,
        requested PTI × affordability summaries,
        mixed-signal × manual-review candidate summaries,
        borderline × manual-review candidate summaries.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        final decision validation,
        final strategy distribution,
        reason-code validation,
        approved-exposure validation,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        or Validation Summary acceptance.

SQL TEACHING POINT:
    These SELECT statements are read-only diagnostics.

    GROUP BY summarizes each trigger family.

    AVG fields help reviewers understand whether the trigger is directionally coherent with the
    underlying value that caused it.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
6.4.1 Count by hard_policy_stop_flag.

Purpose:
    Show the overall prevalence of hard simulated policy stop triggers.

Interpretation:
    TRUE means at least one hard simulated policy stop flag was triggered.

Boundary:
    This is not final DECLINE.
-----------------------------------------------------------------------------------------------*/

SELECT
    hard_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY hard_policy_stop_flag
ORDER BY hard_policy_stop_flag;



/*-----------------------------------------------------------------------------------------------
6.4.2 Count by bankruptcy_policy_stop_flag.

Purpose:
    Show how many rows triggered the bankruptcy simulated policy stop condition.

Interpretation:
    This diagnostic should be reviewed relative to the synthetic population design and strategy
    parameter settings.
-----------------------------------------------------------------------------------------------*/

SELECT
    bankruptcy_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY bankruptcy_policy_stop_flag
ORDER BY bankruptcy_policy_stop_flag;



/*-----------------------------------------------------------------------------------------------
6.4.3 Count by major_derogatory_policy_stop_flag.

Purpose:
    Show how many rows triggered the major derogatory simulated policy stop condition.
-----------------------------------------------------------------------------------------------*/

SELECT
    major_derogatory_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY major_derogatory_policy_stop_flag
ORDER BY major_derogatory_policy_stop_flag;



/*-----------------------------------------------------------------------------------------------
6.4.4 Count by severe_delinquency_policy_stop_flag.

Purpose:
    Show how many rows triggered the severe recent delinquency simulated policy stop condition.
-----------------------------------------------------------------------------------------------*/

SELECT
    severe_delinquency_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY severe_delinquency_policy_stop_flag
ORDER BY severe_delinquency_policy_stop_flag;



/*-----------------------------------------------------------------------------------------------
6.4.5 Count by synthetic_risk_decline_trigger_flag.

Purpose:
    Show how many rows sit in the severe synthetic estimated-risk decline trigger band.

Interpretation:
    avg_synthetic_estimated_pd_proxy should be materially higher for TRUE rows.

Boundary:
    This is not final DECLINE.
-----------------------------------------------------------------------------------------------*/

SELECT
    synthetic_risk_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY synthetic_risk_decline_trigger_flag
ORDER BY synthetic_risk_decline_trigger_flag;



/*-----------------------------------------------------------------------------------------------
6.4.6 Count by requested_pti_decline_trigger_flag.

Purpose:
    Show how many rows have requested PTI at or above the product decline threshold.

Interpretation:
    avg_requested_payment_to_income_ratio should be higher for TRUE rows.

Boundary:
    This is requested affordability pressure, not approved affordability.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_pti_decline_trigger_flag
ORDER BY requested_pti_decline_trigger_flag;



/*-----------------------------------------------------------------------------------------------
6.4.7 Count by dti_decline_trigger_flag.

Purpose:
    Show how many rows have DTI at or above the governed decline threshold.

Interpretation:
    DTI reflects existing obligation capacity and is not directly corrected by counteroffer.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY dti_decline_trigger_flag
ORDER BY dti_decline_trigger_flag;



/*-----------------------------------------------------------------------------------------------
6.4.8 Count by requested_el_decline_trigger_flag.

Purpose:
    Show how many rows have requested-exposure Expected Loss at or above the product decline
    threshold.

Boundary:
    This is requested Expected Loss, not approved Expected Loss.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_el_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_el_decline_trigger_flag
ORDER BY requested_el_decline_trigger_flag;



/*-----------------------------------------------------------------------------------------------
6.4.9 Count by requested_exposure_above_product_cap_flag.

Purpose:
    Show how many rows request exposure above the product approval cap but within the above-cap
    category.

Interpretation:
    These rows may be candidates for reduced-exposure treatment later.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_exposure_above_product_cap_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_exposure_above_product_cap_flag
ORDER BY requested_exposure_above_product_cap_flag;



/*-----------------------------------------------------------------------------------------------
6.4.10 Count by requested_exposure_extreme_flag.

Purpose:
    Show how many rows have extreme requested exposure under product policy.

Interpretation:
    Extreme requested exposure may create severe requested-structure pressure downstream.

Boundary:
    This does not assign final DECLINE or final manual review.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_exposure_extreme_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_exposure_extreme_flag
ORDER BY requested_exposure_extreme_flag;



/*-----------------------------------------------------------------------------------------------
6.4.11 Count by exposure_counteroffer_candidate_flag.

Purpose:
    Show how many rows are exposure-driven counteroffer candidates before feasibility testing.

Boundary:
    This does not prove a viable counteroffer exists.
-----------------------------------------------------------------------------------------------*/

SELECT
    exposure_counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY exposure_counteroffer_candidate_flag
ORDER BY exposure_counteroffer_candidate_flag;



/*-----------------------------------------------------------------------------------------------
6.4.12 Count by counteroffer_candidate_flag.

Purpose:
    Show how many rows are composite counteroffer candidates.

Interpretation:
    avg_counteroffer_candidate_trigger_count shows how many counteroffer-driving dimensions are
    typically active among candidate and non-candidate rows.

Boundary:
    This is candidate status only. Feasibility is tested in Section 8.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(counteroffer_candidate_trigger_count) AS avg_counteroffer_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY counteroffer_candidate_flag
ORDER BY counteroffer_candidate_flag;



/*-----------------------------------------------------------------------------------------------
6.4.13 Count by manual_review_candidate_flag.

Purpose:
    Show how many rows are composite manual-review candidates.

Boundary:
    This is candidate status only. Final manual review is not assigned in Section 6.
-----------------------------------------------------------------------------------------------*/

SELECT
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(manual_review_candidate_trigger_count) AS avg_manual_review_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY manual_review_candidate_flag
ORDER BY manual_review_candidate_flag;



/*-----------------------------------------------------------------------------------------------
6.4.14 Count by high_utilization_review_trigger_flag.

Purpose:
    Show how many rows triggered the supplemental high-utilization review diagnostic.

Interpretation:
    avg_utilization_rate should be higher for TRUE rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    high_utilization_review_trigger_flag,
    COUNT(*) AS row_count,
    AVG(utilization_rate) AS avg_utilization_rate
FROM tmp_m2_stage_3_rule_flags
GROUP BY high_utilization_review_trigger_flag
ORDER BY high_utilization_review_trigger_flag;



/*-----------------------------------------------------------------------------------------------
6.4.15 Count by low_score_review_trigger_flag.

Purpose:
    Show how many rows triggered the supplemental low-score review diagnostic.

Interpretation:
    avg_credit_score should be lower for TRUE rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    low_score_review_trigger_flag,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score
FROM tmp_m2_stage_3_rule_flags
GROUP BY low_score_review_trigger_flag
ORDER BY low_score_review_trigger_flag;



/*-----------------------------------------------------------------------------------------------
6.4.16 Count by clean_approval_candidate_flag.

Purpose:
    Show how many rows are clean across major trigger families.

Interpretation:
    avg_total_rule_trigger_count should generally be low for TRUE rows.

Boundary:
    This is not final approval.
-----------------------------------------------------------------------------------------------*/

SELECT
    clean_approval_candidate_flag,
    COUNT(*) AS row_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY clean_approval_candidate_flag
ORDER BY clean_approval_candidate_flag;



/*-----------------------------------------------------------------------------------------------
6.4.17 Product × hard_policy_stop_flag summary.

Purpose:
    Show whether hard simulated policy stops concentrate by product.

Interpretation:
    Product-level concentration should be reviewed for plausibility and source-population behavior.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    hard_policy_stop_flag,
    COUNT(*) AS row_count,
    AVG(hard_policy_stop_count) AS avg_hard_policy_stop_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    product_type_policy_key,
    hard_policy_stop_flag
ORDER BY
    product_type_policy_key,
    hard_policy_stop_flag;



/*-----------------------------------------------------------------------------------------------
6.4.18 Product × counteroffer_candidate_flag summary.

Purpose:
    Show whether counteroffer candidacy concentrates by product.

Credit risk interpretation:
    Product type affects requested amount, payment burden, loss severity, approved exposure limits,
    and counteroffer feasibility.

Boundary:
    Counteroffer candidacy is not final counteroffer.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(counteroffer_candidate_trigger_count) AS avg_counteroffer_candidate_trigger_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    product_type_policy_key,
    counteroffer_candidate_flag
ORDER BY
    product_type_policy_key,
    counteroffer_candidate_flag;



/*-----------------------------------------------------------------------------------------------
6.4.19 Score band × synthetic risk trigger summary.

Purpose:
    Show how score bands align with synthetic estimated-risk band flags.

Interpretation:
    Stronger score bands should generally have lower synthetic estimated-PD proxy values, while weaker
    score bands should generally have higher values, with realistic overlap preserved.

SQL mechanics:
    Grouping by all four synthetic-risk flags makes the exact band pattern visible.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,

    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag,

    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    score_band_policy_key,
    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    synthetic_risk_decline_trigger_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_clean_approval_band_flag;



/*-----------------------------------------------------------------------------------------------
6.4.20 Requested PTI bucket × affordability trigger summary.

Purpose:
    Show how Section 5 requested PTI buckets convert into Section 6 requested PTI trigger flags.

Interpretation:
    This helps confirm the requested-affordability trigger logic is consistent with the segmentation
    layer.

Boundary:
    This is requested PTI, not approved PTI.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,

    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag,

    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    requested_pti_bucket,
    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag
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
6.4.21 Mixed-signal profile × manual review candidate summary.

Purpose:
    Show how mixed-signal diagnostic profiles influence manual-review candidacy.

Interpretation:
    Mixed-signal profiles are not final routes.

    They are one possible manual-review candidate dimension.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(manual_review_candidate_trigger_count) AS avg_manual_review_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    mixed_signal_profile_type,
    manual_review_candidate_flag
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
    manual_review_candidate_flag;



/*-----------------------------------------------------------------------------------------------
6.4.22 Borderline profile × manual review candidate summary.

Purpose:
    Show whether threshold-adjacent borderline profiles are contributing to manual-review candidacy.

Interpretation:
    Borderline profile status is diagnostic only.

    It is not automatic manual review.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(manual_review_candidate_trigger_count) AS avg_manual_review_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    borderline_profile_flag,
    manual_review_candidate_flag
ORDER BY
    borderline_profile_flag,
    manual_review_candidate_flag;



/***************************************************************************************************
END OF SECTION 6 — RULE FLAG CONSTRUCTION LAYER

If execution reaches this point:
    1. Section 6 dependency preflight passed.
    2. tmp_m2_stage_3_rule_flags exists.
    3. Row count is unchanged from tmp_m2_stage_2_strategy_segments.
    4. application_id remains unique.
    5. Hard simulated policy stop flags are populated.
    6. Synthetic estimated-risk flags are populated.
    7. Exactly one synthetic estimated-risk band is active per row.
    8. Requested PTI flags are populated.
    9. DTI flags are populated.
    10. Exactly one DTI band is active per row.
    11. Requested Expected Loss flags are populated.
    12. Requested exposure flags are populated.
    13. Counteroffer candidate flags are populated.
    14. Manual review candidate flags are populated.
    15. Supplemental behavioral review flags are populated.
    16. clean_approval_candidate_flag is populated as a diagnostic.
    17. Rule count fields are populated, numeric, non-null, and non-negative.
    18. Candidate flags respect product counteroffer and manual-review permissions.
    19. Key decline-trigger equality conventions were checked.
    20. No broader cross-family mutual-exclusivity rule has been imposed.
    21. Section 6 local rule-flag diagnostics are available for review.

No preliminary decision route has been created.
No final decision_outcome has been created.
No final decision_path has been created.
No final approval / decline / manual review / counteroffer flags have been created.
No simulated_offer_exposure_flag has been created.
No simulated reason codes have been assigned.
No approved_amount has been calculated.
No counteroffer_amount has been calculated.
No approved payment proxy has been calculated.
No approved payment-to-income ratio has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No strategy archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full QA framework has been built.

Next section:
    Section 7 should consume tmp_m2_stage_3_rule_flags and convert overlapping rule-trigger evidence
    into one preliminary strategy route per application.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00920 -->


---

<a id="c038-m00922"></a>

### C038-M00922

**Andrew** · 2026-05-09T23:43:54.469000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00922 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 7 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00922 -->


**Attachments in export:** `Pasted text(145).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_42.md) · [Next](Part_44.md)
