# Module 2 Decision Simulator Build

## Part 45

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_44.md) · [Next](Part_46.md)

<a id="c038-m00930"></a>

### C038-M00930

**ChatGPT** · 2026-05-09T23:57:22.157881-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00930 -->
I recommend replacing Section 8 with the version below. I preserved the core exposure-treatment and counteroffer feasibility logic from your current Section 8, added a Section 8.0 dependency preflight, and strengthened the instructional commentary around the credit-risk concepts, SQL mechanics, and interpretation boundaries. fileciteturn95file0

```sql
/***************************************************************************************************
SECTION 8 — APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Calculate preliminary approved-exposure economics and counteroffer feasibility after preliminary
    routing has identified which rows require exposure treatment.

    Section 8 answers:

        "Given the preliminary route, what approved exposure treatment would be economically and
         structurally feasible?"

    Section 8 does not answer:

        "What is the final simulated strategy outcome?"

    This section is the exposure-treatment feasibility layer.

    It converts Section 7 preliminary routing into preliminary exposure economics, but it deliberately
    stops before final decision resolution.

SQL PURPOSE:
    1. Confirm required Section 8 dependencies exist.
    2. Read from tmp_m2_stage_4_preliminary_decision_routing.
    3. Preserve all prior source, lineage, Module 2 strategy metadata, segmentation, rule-trigger,
       and preliminary routing fields.
    4. Calculate preliminary approved exposure treatment by preliminary route.
    5. Evaluate reduced-exposure counteroffer feasibility for preliminary COUNTEROFFER rows.
    6. Calculate preliminary approved payment, approved PTI, and approved Expected Loss only where
       appropriate.
    7. Preserve failed counteroffers as unresolved for later final decision resolution.
    8. Validate exposure-treatment conventions and feasibility logic.
    9. Confirm that final decision fields and simulated reason-code fields are not created yet.
    10. Provide local exposure-treatment diagnostics before Section 9 final decision resolution.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm whether the reduced-exposure treatment logic reflects the intended simulated strategy
        posture for counteroffer feasibility, affordability control, approved Expected Loss control,
        product caps, and minimum viable exposure.

    Model governance / validation reviewers:
        Confirm that Section 8 remains a preliminary exposure-treatment layer and does not
        prematurely assign final decisions or simulated reason codes.

    SQL reviewers:
        Confirm that exposure calculations are transparent, staged through readable CTEs, and
        validated through local fail-fast gatekeepers.

    Portfolio / executive reviewers:
        Use Section 8 diagnostics to understand how preliminary approval and counteroffer routes
        translate into requested versus preliminary approved exposure, PTI, and Expected Loss.

WHEN TO RUN THIS SECTION:
    Run Section 8 after:

        Section 7 — Preliminary Decision Routing Layer

    Section 8 should be run before:

        Section 9 — Final Decision Resolution Layer

    Section 8 depends on:

        tmp_m2_stage_4_preliminary_decision_routing

HOW TO INTERPRET THIS SECTION:
    Passing Section 8 means:
        row count is preserved from Section 7,
        application_id remains unique,
        preliminary APPROVE rows preserve requested exposure,
        preliminary DECLINE rows follow the zero-exposure convention,
        preliminary MANUAL_REVIEW rows remain unresolved,
        preliminary COUNTEROFFER rows are explicitly evaluated for feasibility,
        feasible preliminary COUNTEROFFER rows satisfy all reduced-exposure constraints,
        infeasible preliminary COUNTEROFFER rows remain unresolved for Section 9,
        and no final decision / reason-code fields were created early.

    Passing Section 8 does not mean:
        a final decision has been assigned,
        failed counteroffers have been resolved,
        simulated offer exposure has been assigned,
        final approved exposure exists,
        final approved PTI exists,
        final approved Expected Loss exists,
        simulated reason codes are assigned,
        archive persistence worked,
        or full validation has passed.

INPUT:
    tmp_m2_stage_4_preliminary_decision_routing

OUTPUT:
    tmp_m2_stage_5_exposure_treatment

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

WHY APPROVED EXPOSURE TREATMENT IS SEPARATED FROM PRELIMINARY ROUTING:
    Section 7 identifies the preliminary route.

    Section 8 tests whether the preliminary route can support a coherent approved-exposure treatment.

    This separation is important because route assignment and exposure feasibility are different
    questions:

        Section 7 asks:
            "Where should the row go next?"

        Section 8 asks:
            "Can the exposure treatment implied by that route satisfy product, affordability, and
             approved Expected Loss constraints?"

    The separation makes counteroffer behavior transparent, testable, and auditable.

WHY PRELIMINARY COUNTEROFFER DOES NOT GUARANTEE A VIABLE COUNTEROFFER:
    A preliminary COUNTEROFFER route only means:

        "This row should be tested for reduced-exposure feasibility."

    It does not mean:
        approved_amount exists,
        counteroffer_amount exists,
        approved monthly payment proxy exists,
        approved PTI exists,
        approved Expected Loss exists,
        or a viable counteroffer has been created.

    A viable preliminary counteroffer must satisfy all required feasibility constraints:
        product cap,
        product minimum,
        minimum counteroffer percent,
        maximum exposure reduction,
        approved PTI target,
        and approved Expected Loss cap.

WHY APPROVED AMOUNT IS STILL PRELIMINARY:
    Section 8 calculates approved_amount_preliminary.

    Section 9 later resolves final decision_outcome and final exposure fields.

    This distinction prevents the module from treating a feasibility calculation as a completed final
    simulated strategy outcome.

WHY APPROVED PAYMENT AND APPROVED PTI ARE STRATEGY-SIMULATION PROXIES:
    approved_monthly_payment_proxy_preliminary scales the requested monthly payment proxy
    proportionally with preliminary approved exposure.

    approved_payment_to_income_ratio_preliminary then compares that preliminary payment proxy to
    monthly income.

    This is not a contractual amortization schedule.
    This is not a servicing calculation.
    This is not a production payment quote.

    It is a strategy-simulation affordability proxy.

WHY APPROVED EXPECTED LOSS IS BASED ON APPROVED EXPOSURE:
    requested_expected_loss_amount uses the requested exposure from Module 1.

    approved_expected_loss_amount_preliminary uses the preliminary approved exposure from Module 2.

    Conceptual formula:
        approved_expected_loss_amount_preliminary
            = approved_amount_preliminary × estimated_pd × estimated_lgd

    estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
    proxy.

WHY ESTIMATED_PD IS NOT RECALCULATED:
    Module 2 V1.0 does not create a post-decision risk model.

    Exposure treatment changes approved exposure and simulated approved-exposure Expected Loss.

    It does not recalculate the synthetic estimated-PD proxy.

WHY FAILED COUNTEROFFERS ARE NOT RESOLVED HERE:
    Failed counteroffers require a governed final-resolution policy:

        MANUAL_REVIEW
        or
        DECLINE

    That final resolution occurs in Section 9 using failed_counteroffer_resolution.

    Section 8 only identifies whether preliminary COUNTEROFFER exposure treatment passed or failed.

MANUAL REVIEW BOUNDARY:
    Preliminary MANUAL_REVIEW rows remain unresolved by design.

    They receive:
        approved_amount_preliminary = NULL
        counteroffer_amount_preliminary = NULL
        approved_monthly_payment_proxy_preliminary = NULL
        approved_payment_to_income_ratio_preliminary = NULL
        approved_expected_loss_amount_preliminary = NULL

DECLINE BOUNDARY:
    Preliminary DECLINE rows receive the zero-exposure convention in this exposure-treatment stage.

    Final DECLINE is still not assigned until Section 9.

APPROVE BOUNDARY:
    Preliminary APPROVE rows preserve requested exposure and requested payment structure.

    Section 8 does not yet create final approval_flag or simulated_offer_exposure_flag.

COUNTEROFFER BOUNDARY:
    Preliminary COUNTEROFFER rows are tested for feasibility.

    A feasible preliminary counteroffer remains preliminary until Section 9 resolves final decision.

    An infeasible preliminary counteroffer remains unresolved until Section 9 applies the governed
    failed_counteroffer_resolution parameter.

REASON-CODE BOUNDARY:
    Section 8 does not assign simulated reason codes.

    It does not create:
        primary_reason_code,
        secondary_reason_code,
        tertiary_reason_code,
        triggered_reason_code_list,
        reason_priority_rank,
        primary_reason_family.

    Counteroffer feasibility failure reasons are diagnostics only.

    They are not final simulated reason codes.

FINAL OUTCOME BOUNDARY:
    Section 8 does not create:
        decision_outcome,
        decision_path,
        approval_flag,
        decline_flag,
        manual_review_flag,
        counteroffer_flag,
        simulated_offer_exposure_flag.

APPROVED-EXPOSURE BOUNDARY:
    Section 8 creates preliminary exposure-treatment fields only.

    Final approved exposure fields are created later:
        approved_amount,
        counteroffer_amount,
        approved_monthly_payment_proxy,
        approved_payment_to_income_ratio,
        approved_expected_loss_amount.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the exposure-treatment layer as a session-scoped staging table.

    ON COMMIT PRESERVE ROWS:
        Keeps the staging table available across transaction boundaries in the active session.

    CTE chain:
        The WITH clause breaks exposure treatment into named steps:
            exposure_inputs
            counteroffer_components
            counteroffer_raw
            counteroffer_rounding
            counteroffer_test_economics
            counteroffer_feasibility
            exposure_amount_assignment
            approved_affordability
            approved_economics
            final_exposure_treatment

    LEAST:
        Chooses the most conservative upper bound across requested amount, product cap, PTI target,
        and approved Expected Loss cap.

    GREATEST:
        Chooses the binding minimum viable amount across product minimum, minimum counteroffer
        percent, and maximum exposure-reduction floor.

    NULLIF:
        Prevents divide-by-zero when calculating PTI target exposure, approved PTI, and EL-cap
        exposure.

    FLOOR:
        Rounds down counteroffer amounts so the rounded amount does not accidentally violate product,
        PTI, or approved Expected Loss constraints.

    Boolean::INT:
        Converts TRUE / FALSE feasibility failures into 1 / 0 so constraint failures can be counted.

    IS DISTINCT FROM:
        Provides NULL-safe comparison in Section 8 gatekeepers.

    pg_attribute:
        Inspects physical columns on the temporary table to confirm that downstream-only final fields
        were not created too early.

GOVERNANCE ROLE:
    Section 8 makes counteroffer feasibility transparent.

    It shows which constraints created a feasible reduced-exposure treatment and which constraints
    caused preliminary counteroffers to fail.

COMMON MISUSE TO AVOID:
    Do not interpret approved_amount_preliminary as final approved_amount.
    Do not interpret counteroffer_amount_preliminary as final counteroffer_amount.
    Do not interpret counteroffer_feasibility_failure_reason as a final reason code.
    Do not interpret preliminary DECLINE exposure convention as final decision resolution.
    Do not interpret preliminary MANUAL_REVIEW unresolved fields as missing data errors.
    Do not interpret feasible preliminary COUNTEROFFER as final COUNTEROFFER.
    Do not treat approved PTI proxy as a contractual payment quote.
    Do not treat approved Expected Loss as production loss forecasting.

TESTING RELEVANCE:
    Section 8 local diagnostics help reviewers confirm:
        row-count preservation,
        application_id uniqueness,
        APPROVE preliminary exposure convention,
        DECLINE zero-exposure convention,
        MANUAL_REVIEW unresolved convention,
        COUNTEROFFER feasibility pass / fail behavior,
        approved PTI target compliance for feasible counteroffers,
        approved Expected Loss cap compliance for feasible counteroffers,
        and absence of final decision / reason-code fields.

DOWNSTREAM DEPENDENCY:
    Section 9 consumes tmp_m2_stage_5_exposure_treatment.

    Section 9 uses exposure_treatment_status, counteroffer feasibility results, and preliminary
    exposure-treatment fields to resolve final decision_outcome and final exposure fields.

PORTFOLIO ARTIFACT VALUE:
    This section demonstrates that the strategy engine does not treat counteroffer as a simple label.

    It treats counteroffer as a governed feasibility workflow:
        route identification,
        exposure constraint calculation,
        affordability testing,
        approved Expected Loss testing,
        failure diagnostics,
        and final downstream resolution.

***************************************************************************************************/



/***************************************************************************************************
SECTION 8.0 — SECTION 8 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 7 preliminary routing output exists and is populated before preliminary
    exposure-treatment and counteroffer feasibility logic begins.

    Section 8.0 answers:

        "Can Section 8 safely calculate exposure treatment from the current Section 7 preliminary
         routing layer?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_4_preliminary_decision_routing exists.
    2. Confirm the preliminary-routing table contains rows.
    3. Confirm application_id remains unique before exposure-treatment fields are added.
    4. Confirm required Section 7 route fields are populated.
    5. Confirm required amount, affordability, risk, product-policy, and counteroffer fields are
       populated.
    6. Fail clearly if Section 8 is run out of order.

WHY THIS PREFLIGHT EXISTS:
    Section 8 is a transformation layer.

    It should fail with a clear instructional message if Section 7 has not run, rather than producing
    a lower-level missing-table error.

CREDIT RISK INTERPRETATION:
    Exposure treatment depends on more than the preliminary route.

    Section 8 must also have:
        requested amount,
        requested payment proxy,
        requested PTI,
        annual income,
        estimated_pd,
        estimated_lgd,
        requested Expected Loss,
        product amount limits,
        counteroffer amount limits,
        approved Expected Loss caps,
        and rounding increments.

BOUNDARY:
    Section 8.0 does not create exposure-treatment fields.
    Section 8.0 does not create final decisions.
    Section 8.0 does not create reason codes.
    Section 8.0 does not calculate approved exposure.
    Section 8.0 does not modify any persistent table.

***************************************************************************************************/

DO $$
DECLARE
    v_stage4_exists BOOLEAN;
    v_stage4_row_count BIGINT;
    v_stage4_distinct_application_count BIGINT;
    v_required_route_gap_count BIGINT;
    v_required_exposure_input_gap_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 7 preliminary-routing table must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

        pg_temp is checked because tmp_m2_stage_4_preliminary_decision_routing is a temporary table.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_4_preliminary_decision_routing'),
        TO_REGCLASS('tmp_m2_stage_4_preliminary_decision_routing')
    ) IS NOT NULL
    INTO v_stage4_exists;

    IF v_stage4_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: tmp_m2_stage_4_preliminary_decision_routing is required. Run Section 7 before Section 8.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 7 preliminary-routing table must contain rows.

    Business interpretation:
        Exposure treatment over an empty applicant population is not useful and usually indicates an
        upstream source, segmentation, rule-flag, or preliminary-routing issue.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage4_row_count
    FROM tmp_m2_stage_4_preliminary_decision_routing;

    IF v_stage4_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: tmp_m2_stage_4_preliminary_decision_routing contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id should be unique before exposure treatment is added.

    Section 8 should add exposure-treatment fields only.

    It should not repair grain problems from earlier stages.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage4_distinct_application_count
    FROM tmp_m2_stage_4_preliminary_decision_routing;

    IF v_stage4_distinct_application_count <> v_stage4_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: tmp_m2_stage_4_preliminary_decision_routing is not unique at application_id. Rows=%, distinct application_id=%.',
            v_stage4_row_count,
            v_stage4_distinct_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary route fields required by Section 8 must be populated.

    Business interpretation:
        Section 8 depends on preliminary_decision_outcome to decide whether a row should preserve
        requested exposure, receive zero preliminary exposure, remain unresolved, or be evaluated for
        counteroffer feasibility.

    Exposure-routing flags are also checked because they document which rows require approved
    exposure calculation and counteroffer feasibility testing.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_route_gap_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE preliminary_decision_outcome IS NULL
       OR preliminary_decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR preliminary_decision_path IS NULL
       OR NULLIF(BTRIM(preliminary_decision_path), '') IS NULL
       OR preliminary_decision_priority_rank IS NULL
       OR preliminary_route_reason_family IS NULL
       OR NULLIF(BTRIM(preliminary_route_reason_family), '') IS NULL
       OR requires_counteroffer_feasibility_flag IS NULL
       OR requires_approved_exposure_calculation_flag IS NULL;

    IF v_required_route_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % Section 7 row(s) are missing preliminary routing fields required for exposure treatment.',
            v_required_route_gap_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exposure-treatment input fields required by Section 8 must be populated.

    Credit risk interpretation:
        Counteroffer feasibility requires product constraints, affordability inputs, requested
        exposure, estimated risk, LGD, and requested Expected Loss.

    SQL mechanics:
        This check counts rows missing any required input field before the CTE chain performs
        calculations.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_exposure_input_gap_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE requested_amount IS NULL
       OR requested_monthly_payment_proxy IS NULL
       OR requested_payment_to_income_ratio IS NULL
       OR annual_income IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL
       OR requested_expected_loss_amount IS NULL

       OR product_min_approved_amount IS NULL
       OR product_max_approved_amount IS NULL
       OR product_min_counteroffer_pct IS NULL
       OR product_max_exposure_reduction_pct IS NULL
       OR product_approved_el_cap IS NULL
       OR counteroffer_target_pti IS NULL
       OR approved_amount_rounding_increment IS NULL
       OR counteroffer_allowed_flag IS NULL;

    IF v_required_exposure_input_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % Section 7 row(s) are missing exposure-treatment input fields required by Section 8.',
            v_required_exposure_input_gap_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 8.1 — CLEAN RESET OF SECTION 8 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 8 exposure-treatment stage before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 8 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale exposure-treatment rows to remain available to Section 9.

    Section 9 assumes tmp_m2_stage_5_exposure_treatment reflects the current:
        Section 7 preliminary routing output,
        active strategy parameter state already carried forward,
        product policy thresholds already carried forward,
        and current exposure-treatment logic.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the table does not exist, PostgreSQL does not error.

BOUNDARY:
    This drop affects only the temporary Section 8 staging object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_5_exposure_treatment;



/***************************************************************************************************
SECTION 8.2 — CREATE APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_5_exposure_treatment

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_4_preliminary_decision_routing

OUTPUT:
    All Section 7 fields plus:
        exposure_treatment_status
        exposure_treatment_path
        approved_amount_preliminary
        counteroffer_amount_preliminary
        exposure_reduction_flag_preliminary
        exposure_reduction_amount_preliminary
        exposure_reduction_pct_preliminary
        approved_monthly_payment_proxy_preliminary
        approved_payment_to_income_ratio_preliminary
        approved_expected_loss_amount_preliminary
        approved_el_reduction_amount_preliminary
        approved_el_reduction_pct_preliminary
        counteroffer feasibility component fields
        counteroffer feasibility diagnostics

SQL DESIGN:
    This section uses a CTE chain so each exposure-treatment calculation is visible.

    The chain is:

        exposure_inputs
            preserves Section 7 output.

        counteroffer_components
            calculates the product cap, PTI target amount, approved Expected Loss cap amount, and
            minimum viable counteroffer amount.

        counteroffer_raw
            identifies the most conservative raw feasible amount.

        counteroffer_rounding
            rounds the raw amount down using the product rounding increment.

        counteroffer_test_economics
            calculates test payment, test PTI, and test approved Expected Loss for the rounded
            counteroffer amount.

        counteroffer_feasibility
            evaluates pass / fail and assigns feasibility failure diagnostics.

        exposure_amount_assignment
            assigns preliminary approved amount, counteroffer amount, and exposure reduction fields.

        approved_affordability
            assigns preliminary approved payment and preliminary approved PTI.

        approved_economics
            assigns preliminary approved Expected Loss and preliminary EL reduction diagnostics.

        final_exposure_treatment
            assigns exposure_treatment_status and exposure_treatment_path.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 8 intentionally preserves all prior fields plus exposure-treatment diagnostics for
    Section 9 final decision resolution.

    Permanent output selection is handled later with an explicit field list in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_5_exposure_treatment
ON COMMIT PRESERVE ROWS
AS
WITH exposure_inputs AS (
    /***********************************************************************************************
    CTE: exposure_inputs

    Purpose:
        Preserve every Section 7 preliminary-routing field before exposure-treatment calculations are
        added.

    SQL mechanics:
        SELECT r.* carries the full upstream row forward.

    Boundary:
        This CTE does not create any new fields.
    ***********************************************************************************************/
    SELECT
        r.*
    FROM tmp_m2_stage_4_preliminary_decision_routing r
),

counteroffer_components AS (
    /***********************************************************************************************
    CTE: counteroffer_components

    Purpose:
        Calculate the core counteroffer feasibility inputs for preliminary COUNTEROFFER rows.

    Credit risk interpretation:
        A reduced-exposure offer must respect:
            product maximum exposure,
            affordability target,
            approved Expected Loss cap,
            product minimum approved amount,
            minimum percent of requested amount,
            and maximum exposure reduction.

    Boundary:
        These component amounts are feasibility inputs.

        They are not final approved amounts.
    ***********************************************************************************************/
    SELECT
        ei.*,

        /*******************************************************************************************
        Product cap amount.

        A counteroffer cannot exceed:
            requested_amount,
            product_max_approved_amount.

        This is one of the upper bounds used to identify the most conservative feasible reduced
        exposure.

        SQL mechanics:
            LEAST chooses the smaller of requested exposure and product cap.
        *******************************************************************************************/
        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN LEAST(ei.requested_amount, ei.product_max_approved_amount)
            ELSE NULL::NUMERIC
        END AS counteroffer_product_cap_amount,


        /*******************************************************************************************
        PTI target amount.

        Module 2 V1.0 scales payment proportionally with approved exposure.

        This estimates the approved amount that would bring approved PTI to the product-specific
        counteroffer target.

        Algebra:
            requested_payment_to_income_ratio
                = requested_monthly_payment_proxy / monthly_income

            If payment scales with exposure:
                approved_pti ≈ requested_pti × approved_amount / requested_amount

            Solve for approved_amount at target PTI:
                approved_amount ≈ requested_amount × target_pti / requested_pti

        This is a strategy-simulation proxy, not a contractual amortization calculation.

        SQL mechanics:
            NULLIF prevents divide-by-zero when requested PTI equals zero.
        *******************************************************************************************/
        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ei.requested_payment_to_income_ratio > 0
                THEN ei.requested_amount
                     * ei.counteroffer_target_pti
                     / NULLIF(ei.requested_payment_to_income_ratio, 0)

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN ei.requested_amount

            ELSE NULL::NUMERIC
        END AS counteroffer_pti_target_amount,


        /*******************************************************************************************
        Approved Expected Loss cap amount.

        This estimates the maximum exposure that can satisfy the product approved-exposure Expected
        Loss cap.

        Formula:
            product_approved_el_cap / NULLIF(estimated_pd × estimated_lgd, 0)

        estimated_pd is interpreted as the synthetic estimated-PD proxy.

        SQL mechanics:
            NULLIF prevents divide-by-zero if estimated_pd × estimated_lgd is zero.
        *******************************************************************************************/
        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN ei.product_approved_el_cap / NULLIF((ei.estimated_pd * ei.estimated_lgd), 0)
            ELSE NULL::NUMERIC
        END AS counteroffer_el_cap_amount,


        /*******************************************************************************************
        Minimum viable counteroffer amount.

        The counteroffer must not fall below:
            product minimum approved amount,
            minimum viable percentage of requested amount,
            floor implied by maximum permitted exposure reduction.

        These are governed product-policy parameters, not hidden constants.

        SQL mechanics:
            GREATEST selects the largest minimum-floor value. The candidate counteroffer must be at or
            above that floor to be viable.
        *******************************************************************************************/
        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN GREATEST(
                    ei.product_min_approved_amount,
                    ei.requested_amount * ei.product_min_counteroffer_pct,
                    ei.requested_amount * (1.0 - ei.product_max_exposure_reduction_pct)
                )
            ELSE NULL::NUMERIC
        END AS counteroffer_min_viable_amount

    FROM exposure_inputs ei
),

counteroffer_raw AS (
    /***********************************************************************************************
    CTE: counteroffer_raw

    Purpose:
        Identify the raw maximum feasible counteroffer amount before rounding.

    Credit risk interpretation:
        A feasible reduced-exposure amount must satisfy all upper-bound constraints.

        The most conservative approach is to take the lowest upper-bound amount.

    SQL mechanics:
        LEAST chooses the most restrictive upper bound across requested amount, product cap, PTI
        target, and approved Expected Loss cap.

        If a required component is unavailable, the raw feasible amount remains NULL so feasibility
        fails explicitly and diagnostically.
    ***********************************************************************************************/
    SELECT
        cc.*,

        CASE
            WHEN cc.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cc.counteroffer_product_cap_amount IS NOT NULL
             AND cc.counteroffer_pti_target_amount IS NOT NULL
             AND cc.counteroffer_el_cap_amount IS NOT NULL
                THEN LEAST(
                    cc.requested_amount,
                    cc.counteroffer_product_cap_amount,
                    cc.counteroffer_pti_target_amount,
                    cc.counteroffer_el_cap_amount
                )
            ELSE NULL::NUMERIC
        END AS counteroffer_raw_max_feasible_amount

    FROM counteroffer_components cc
),

counteroffer_rounding AS (
    /***********************************************************************************************
    CTE: counteroffer_rounding

    Purpose:
        Apply conservative product-specific rounding to the raw feasible counteroffer amount.

    Credit risk interpretation:
        Rounding down protects against accidentally exceeding affordability or approved Expected Loss
        constraints after rounding.

    SQL mechanics:
        FLOOR(raw_amount / increment) × increment
            rounds the raw value down to the nearest allowed product increment.

    Boundary:
        If rounding pushes the amount below the minimum viable amount, feasibility fails later.
    ***********************************************************************************************/
    SELECT
        cr.*,

        CASE
            WHEN cr.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cr.counteroffer_raw_max_feasible_amount IS NOT NULL
             AND cr.approved_amount_rounding_increment > 0
                THEN FLOOR(cr.counteroffer_raw_max_feasible_amount / cr.approved_amount_rounding_increment)
                     * cr.approved_amount_rounding_increment
            ELSE NULL::NUMERIC
        END AS counteroffer_rounded_amount

    FROM counteroffer_raw cr
),

counteroffer_test_economics AS (
    /***********************************************************************************************
    CTE: counteroffer_test_economics

    Purpose:
        Calculate test affordability and test approved Expected Loss for the rounded counteroffer
        amount.

    Business interpretation:
        These test values determine whether the reduced-exposure treatment works.

    Boundary:
        These are test economics for preliminary COUNTEROFFER rows only.

        If feasibility fails, preliminary approved fields remain NULL for that failed counteroffer
        route.
    ***********************************************************************************************/
    SELECT
        cor.*,

        /*******************************************************************************************
        Counteroffer test monthly payment proxy.

        This value is calculated for feasibility testing only.

        Payment is scaled proportionally with exposure:
            requested payment × rounded amount / requested amount

        This is a strategy-simulation proxy, not a contractual payment recalculation.
        *******************************************************************************************/
        CASE
            WHEN cor.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cor.counteroffer_rounded_amount IS NOT NULL
                THEN cor.requested_monthly_payment_proxy
                     * cor.counteroffer_rounded_amount
                     / NULLIF(cor.requested_amount, 0)
            ELSE NULL::NUMERIC
        END AS counteroffer_test_monthly_payment_proxy,


        /*******************************************************************************************
        Counteroffer test PTI.

        This tests whether the reduced exposure can meet the governed product-specific PTI target.

        SQL mechanics:
            monthly income is annual_income / 12.
            NULLIF protects against zero monthly income.
        *******************************************************************************************/
        CASE
            WHEN cor.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cor.counteroffer_rounded_amount IS NOT NULL
                THEN (
                    cor.requested_monthly_payment_proxy
                    * cor.counteroffer_rounded_amount
                    / NULLIF(cor.requested_amount, 0)
                ) / NULLIF((cor.annual_income / 12.0), 0)
            ELSE NULL::NUMERIC
        END AS counteroffer_test_payment_to_income_ratio,


        /*******************************************************************************************
        Counteroffer test approved Expected Loss.

        This tests the approved-exposure Expected Loss implied by the rounded reduced exposure.

        Conceptual formula:
            rounded counteroffer amount × estimated_pd × estimated_lgd

        estimated_pd remains the Module 1 synthetic estimated-PD proxy input.
        *******************************************************************************************/
        CASE
            WHEN cor.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cor.counteroffer_rounded_amount IS NOT NULL
                THEN cor.counteroffer_rounded_amount * cor.estimated_pd * cor.estimated_lgd
            ELSE NULL::NUMERIC
        END AS counteroffer_test_expected_loss_amount

    FROM counteroffer_rounding cor
),

counteroffer_feasibility AS (
    /***********************************************************************************************
    CTE: counteroffer_feasibility

    Purpose:
        Convert the component calculations into counteroffer feasibility pass / fail evidence.

    Business interpretation:
        A preliminary COUNTEROFFER row passes only if the reduced exposure satisfies every relevant
        structural, affordability, and approved Expected Loss constraint.

    SQL mechanics:
        Boolean expressions are cast to integers to count failed constraints.

        The pass flag repeats the required conditions explicitly so feasibility remains auditable.

        The failure reason uses deterministic priority order so each failed counteroffer receives one
        primary feasibility failure diagnostic.
    ***********************************************************************************************/
    SELECT
        cte.*,

        /*******************************************************************************************
        Counteroffer feasibility constraint count.

        Diagnostic only.

        Counts failed constraints among preliminary COUNTEROFFER rows.

        Non-counteroffer preliminary routes receive NULL because they were not evaluated for
        counteroffer feasibility.

        Interpretation:
            Higher counts indicate multiple binding or failed feasibility constraints.
        *******************************************************************************************/
        CASE
            WHEN cte.preliminary_decision_outcome = 'COUNTEROFFER' THEN
                (
                    (cte.counteroffer_allowed_flag IS DISTINCT FROM TRUE)::INT
                    + (cte.counteroffer_raw_max_feasible_amount IS NULL)::INT
                    + (cte.counteroffer_rounded_amount IS NULL)::INT
                    + (
                        cte.counteroffer_rounded_amount IS NOT NULL
                        AND cte.counteroffer_rounded_amount <= 0
                      )::INT
                    + (
                        cte.counteroffer_rounded_amount IS NOT NULL
                        AND cte.counteroffer_rounded_amount >= cte.requested_amount
                      )::INT
                    + (
                        cte.counteroffer_rounded_amount IS NOT NULL
                        AND cte.counteroffer_rounded_amount < cte.product_min_approved_amount
                      )::INT
                    + (
                        cte.counteroffer_rounded_amount IS NOT NULL
                        AND cte.counteroffer_rounded_amount < cte.requested_amount * cte.product_min_counteroffer_pct
                      )::INT
                    + (
                        cte.counteroffer_rounded_amount IS NOT NULL
                        AND cte.counteroffer_rounded_amount < cte.requested_amount * (1.0 - cte.product_max_exposure_reduction_pct)
                      )::INT
                    + (
                        cte.counteroffer_rounded_amount IS NOT NULL
                        AND cte.counteroffer_rounded_amount > cte.product_max_approved_amount
                      )::INT
                    + (
                        cte.counteroffer_test_payment_to_income_ratio IS NOT NULL
                        AND cte.counteroffer_test_payment_to_income_ratio > cte.counteroffer_target_pti
                      )::INT
                    + (
                        cte.counteroffer_test_expected_loss_amount IS NOT NULL
                        AND cte.counteroffer_test_expected_loss_amount > cte.product_approved_el_cap
                      )::INT
                )
            ELSE NULL::INTEGER
        END AS counteroffer_feasibility_constraint_count,


        /*******************************************************************************************
        Counteroffer feasibility pass flag.

        A preliminary COUNTEROFFER row passes only when every required feasibility condition is met.

        Required conditions:
            product allows counteroffer,
            rounded amount is present,
            rounded amount is positive,
            rounded amount is below requested amount,
            rounded amount is above product minimum,
            rounded amount is above minimum requested percent,
            rounded amount does not exceed maximum allowed reduction,
            rounded amount is within product cap,
            approved PTI test meets target,
            approved Expected Loss test meets product cap.

        Non-counteroffer preliminary routes receive NULL.
        *******************************************************************************************/
        CASE
            WHEN cte.preliminary_decision_outcome <> 'COUNTEROFFER'
                THEN NULL::BOOLEAN

            WHEN cte.counteroffer_allowed_flag IS TRUE
             AND cte.counteroffer_rounded_amount IS NOT NULL
             AND cte.counteroffer_rounded_amount > 0
             AND cte.counteroffer_rounded_amount < cte.requested_amount
             AND cte.counteroffer_rounded_amount >= cte.product_min_approved_amount
             AND cte.counteroffer_rounded_amount >= cte.requested_amount * cte.product_min_counteroffer_pct
             AND cte.counteroffer_rounded_amount >= cte.requested_amount * (1.0 - cte.product_max_exposure_reduction_pct)
             AND cte.counteroffer_rounded_amount <= cte.product_max_approved_amount
             AND cte.counteroffer_test_payment_to_income_ratio <= cte.counteroffer_target_pti
             AND cte.counteroffer_test_expected_loss_amount <= cte.product_approved_el_cap
                THEN TRUE

            ELSE FALSE
        END AS counteroffer_feasibility_pass_flag,


        /*******************************************************************************************
        Counteroffer feasibility failure reason.

        Deterministic priority order.

        These are feasibility diagnostics, not final simulated reason codes.

        The final reason-code layer later uses final decision_outcome, route diagnostics, and
        exposure-treatment diagnostics to assign simulated strategy explanation codes.
        *******************************************************************************************/
        CASE
            WHEN cte.preliminary_decision_outcome <> 'COUNTEROFFER'
                THEN NULL::TEXT

            WHEN cte.counteroffer_allowed_flag IS DISTINCT FROM TRUE
                THEN 'COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT'

            WHEN cte.counteroffer_raw_max_feasible_amount IS NULL
                THEN 'COUNTEROFFER_RAW_AMOUNT_NULL'

            WHEN cte.counteroffer_rounded_amount IS NULL
                THEN 'COUNTEROFFER_ROUNDED_AMOUNT_NULL'

            WHEN cte.counteroffer_rounded_amount <= 0
                THEN 'COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE'

            WHEN cte.counteroffer_rounded_amount >= cte.requested_amount
                THEN 'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'

            WHEN cte.counteroffer_rounded_amount < cte.product_min_approved_amount
                THEN 'COUNTEROFFER_BELOW_PRODUCT_MINIMUM'

            WHEN cte.counteroffer_rounded_amount < cte.requested_amount * cte.product_min_counteroffer_pct
                THEN 'COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT'

            WHEN cte.counteroffer_rounded_amount < cte.requested_amount * (1.0 - cte.product_max_exposure_reduction_pct)
                THEN 'COUNTEROFFER_EXCEEDS_MAX_REDUCTION'

            WHEN cte.counteroffer_rounded_amount > cte.product_max_approved_amount
                THEN 'COUNTEROFFER_EXCEEDS_PRODUCT_CAP'

            WHEN cte.counteroffer_test_payment_to_income_ratio > cte.counteroffer_target_pti
                THEN 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'

            WHEN cte.counteroffer_test_expected_loss_amount > cte.product_approved_el_cap
                THEN 'COUNTEROFFER_APPROVED_EL_ABOVE_CAP'

            WHEN NOT (
                cte.counteroffer_allowed_flag IS TRUE
                AND cte.counteroffer_rounded_amount IS NOT NULL
                AND cte.counteroffer_rounded_amount > 0
                AND cte.counteroffer_rounded_amount < cte.requested_amount
                AND cte.counteroffer_rounded_amount >= cte.product_min_approved_amount
                AND cte.counteroffer_rounded_amount >= cte.requested_amount * cte.product_min_counteroffer_pct
                AND cte.counteroffer_rounded_amount >= cte.requested_amount * (1.0 - cte.product_max_exposure_reduction_pct)
                AND cte.counteroffer_rounded_amount <= cte.product_max_approved_amount
                AND cte.counteroffer_test_payment_to_income_ratio <= cte.counteroffer_target_pti
                AND cte.counteroffer_test_expected_loss_amount <= cte.product_approved_el_cap
            )
                THEN 'COUNTEROFFER_FEASIBILITY_UNKNOWN'

            ELSE NULL::TEXT
        END AS counteroffer_feasibility_failure_reason

    FROM counteroffer_test_economics cte
),

exposure_amount_assignment AS (
    /***********************************************************************************************
    CTE: exposure_amount_assignment

    Purpose:
        Assign preliminary approved exposure fields according to the preliminary route and
        counteroffer feasibility result.

    Credit risk interpretation:
        APPROVE:
            preserves requested exposure.

        COUNTEROFFER:
            receives reduced exposure only when feasibility passes.

        DECLINE:
            receives zero preliminary exposure convention.

        MANUAL_REVIEW:
            remains unresolved.

    Boundary:
        These fields are preliminary only.

        Section 9 creates final approved exposure fields.
    ***********************************************************************************************/
    SELECT
        cf.*,

        /*******************************************************************************************
        approved_amount_preliminary.

        APPROVE:
            requested_amount.

        COUNTEROFFER:
            rounded feasible reduced exposure when feasibility passes.

        DECLINE:
            zero preliminary exposure convention.

        MANUAL_REVIEW:
            NULL, unresolved by design.
        *******************************************************************************************/
        CASE
            WHEN cf.preliminary_decision_outcome = 'APPROVE'
                THEN cf.requested_amount

            WHEN cf.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN cf.counteroffer_rounded_amount

            WHEN cf.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN cf.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_amount_preliminary,


        /*******************************************************************************************
        counteroffer_amount_preliminary.

        Populated only for feasible preliminary COUNTEROFFER rows.

        Failed counteroffers remain unresolved for Section 9 final decision resolution.
        *******************************************************************************************/
        CASE
            WHEN cf.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN cf.counteroffer_rounded_amount
            ELSE NULL::NUMERIC
        END AS counteroffer_amount_preliminary,


        /*******************************************************************************************
        exposure_reduction_flag_preliminary.

        TRUE only for feasible preliminary COUNTEROFFER rows.

        DECLINE rows use zero exposure but are not treated as counteroffer exposure reduction.
        *******************************************************************************************/
        CASE
            WHEN cf.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN TRUE
            ELSE FALSE
        END AS exposure_reduction_flag_preliminary,


        /*******************************************************************************************
        exposure_reduction_amount_preliminary.

        APPROVE:
            zero reduction.

        COUNTEROFFER:
            requested amount minus feasible rounded counteroffer amount.

        DECLINE:
            requested amount, reflecting zero preliminary exposure convention.

        MANUAL_REVIEW:
            NULL, unresolved by design.
        *******************************************************************************************/
        CASE
            WHEN cf.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN cf.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN cf.requested_amount - cf.counteroffer_rounded_amount

            WHEN cf.preliminary_decision_outcome = 'DECLINE'
                THEN cf.requested_amount

            WHEN cf.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS exposure_reduction_amount_preliminary,


        /*******************************************************************************************
        exposure_reduction_pct_preliminary.

        APPROVE:
            zero.

        COUNTEROFFER:
            percentage reduction from requested amount to feasible counteroffer amount.

        DECLINE:
            one, reflecting zero preliminary exposure convention.

        MANUAL_REVIEW:
            NULL, unresolved by design.

        SQL mechanics:
            NULLIF protects against divide-by-zero when requested_amount is zero.
        *******************************************************************************************/
        CASE
            WHEN cf.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN cf.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN (cf.requested_amount - cf.counteroffer_rounded_amount)
                     / NULLIF(cf.requested_amount, 0)

            WHEN cf.preliminary_decision_outcome = 'DECLINE'
                THEN 1.0::NUMERIC

            WHEN cf.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS exposure_reduction_pct_preliminary

    FROM counteroffer_feasibility cf
),

approved_affordability AS (
    /***********************************************************************************************
    CTE: approved_affordability

    Purpose:
        Assign preliminary approved payment and preliminary approved PTI fields.

    Credit risk interpretation:
        This is where preliminary exposure treatment becomes preliminary affordability treatment.

    Boundary:
        These are strategy-simulation proxies.

        They are not production payment quotes.
        They are not final approved PTI fields.
    ***********************************************************************************************/
    SELECT
        eaa.*,

        /*******************************************************************************************
        Preliminary approved payment proxy.

        APPROVE:
            preserve requested monthly payment proxy.

        COUNTEROFFER:
            use feasible counteroffer test payment proxy.

        DECLINE:
            zero preliminary exposure convention.

        MANUAL_REVIEW:
            unresolved NULL convention.
        *******************************************************************************************/
        CASE
            WHEN eaa.preliminary_decision_outcome = 'APPROVE'
                THEN eaa.requested_monthly_payment_proxy

            WHEN eaa.preliminary_decision_outcome = 'COUNTEROFFER'
             AND eaa.counteroffer_feasibility_pass_flag IS TRUE
                THEN eaa.counteroffer_test_monthly_payment_proxy

            WHEN eaa.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN eaa.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_monthly_payment_proxy_preliminary,


        /*******************************************************************************************
        Preliminary approved PTI.

        APPROVE:
            preserve requested PTI.

        COUNTEROFFER:
            use feasible counteroffer test PTI.

        DECLINE:
            zero preliminary exposure convention.

        MANUAL_REVIEW:
            unresolved NULL convention.
        *******************************************************************************************/
        CASE
            WHEN eaa.preliminary_decision_outcome = 'APPROVE'
                THEN eaa.requested_payment_to_income_ratio

            WHEN eaa.preliminary_decision_outcome = 'COUNTEROFFER'
             AND eaa.counteroffer_feasibility_pass_flag IS TRUE
                THEN eaa.counteroffer_test_payment_to_income_ratio

            WHEN eaa.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN eaa.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_payment_to_income_ratio_preliminary

    FROM exposure_amount_assignment eaa
),

approved_economics AS (
    /***********************************************************************************************
    CTE: approved_economics

    Purpose:
        Assign preliminary approved Expected Loss and preliminary Expected Loss reduction diagnostics.

    Credit risk interpretation:
        Requested Expected Loss describes the original requested exposure.

        Approved Expected Loss describes the exposure after preliminary exposure treatment.

        Reducing exposure can reduce approved Expected Loss even when estimated_pd and estimated_lgd
        remain unchanged.

    Boundary:
        These are preliminary values.

        Section 9 creates final approved Expected Loss fields.
    ***********************************************************************************************/
    SELECT
        aa.*,

        /*******************************************************************************************
        Preliminary approved Expected Loss.

        APPROVE:
            requested_expected_loss_amount.

        COUNTEROFFER:
            rounded approved exposure × estimated_pd × estimated_lgd.

        DECLINE:
            zero preliminary exposure convention.

        MANUAL_REVIEW:
            unresolved NULL convention.
        *******************************************************************************************/
        CASE
            WHEN aa.preliminary_decision_outcome = 'APPROVE'
                THEN aa.requested_expected_loss_amount

            WHEN aa.preliminary_decision_outcome = 'COUNTEROFFER'
             AND aa.counteroffer_feasibility_pass_flag IS TRUE
                THEN aa.counteroffer_test_expected_loss_amount

            WHEN aa.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN aa.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_expected_loss_amount_preliminary,


        /*******************************************************************************************
        Preliminary approved Expected Loss reduction amount.

        Diagnostic only.

        Final approved Expected Loss fields are created later.
        *******************************************************************************************/
        CASE
            WHEN aa.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN aa.preliminary_decision_outcome = 'COUNTEROFFER'
             AND aa.counteroffer_feasibility_pass_flag IS TRUE
                THEN aa.requested_expected_loss_amount - aa.counteroffer_test_expected_loss_amount

            WHEN aa.preliminary_decision_outcome = 'DECLINE'
                THEN aa.requested_expected_loss_amount

            WHEN aa.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_amount_preliminary,


        /*******************************************************************************************
        Preliminary approved Expected Loss reduction percent.

        Diagnostic only.

        For DECLINE, the zero-exposure convention reduces requested-exposure Expected Loss to zero.

        When requested_expected_loss_amount is zero, the reduction percent is zero rather than
        undefined.
        *******************************************************************************************/
        CASE
            WHEN aa.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN aa.preliminary_decision_outcome = 'COUNTEROFFER'
             AND aa.counteroffer_feasibility_pass_flag IS TRUE
                THEN (aa.requested_expected_loss_amount - aa.counteroffer_test_expected_loss_amount)
                     / NULLIF(aa.requested_expected_loss_amount, 0)

            WHEN aa.preliminary_decision_outcome = 'DECLINE'
                THEN CASE
                    WHEN aa.requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END

            WHEN aa.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_pct_preliminary

    FROM approved_affordability aa
),

final_exposure_treatment AS (
    /***********************************************************************************************
    CTE: final_exposure_treatment

    Purpose:
        Add compact preliminary exposure-treatment status and path labels.

    Boundary:
        exposure_treatment_status and exposure_treatment_path are not final decision fields.

        They are Section 8 diagnostics used by Section 9 and later QA.
    ***********************************************************************************************/
    SELECT
        ae.*,

        /*******************************************************************************************
        Counteroffer feasibility evaluated flag.

        Only preliminary COUNTEROFFER rows receive feasibility evaluation.

        This flag helps Section 8 and later QA distinguish:
            counteroffer rows evaluated for feasibility,
            versus non-counteroffer rows where feasibility is not applicable.
        *******************************************************************************************/
        (ae.preliminary_decision_outcome = 'COUNTEROFFER')
            AS counteroffer_feasibility_evaluated_flag,


        /*******************************************************************************************
        exposure_treatment_status.

        Preliminary exposure-treatment label.

        This is not final decision_outcome and not a simulated reason code.
        *******************************************************************************************/
        CASE
            WHEN ae.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVED_AS_REQUESTED_PRELIMINARY'

            WHEN ae.preliminary_decision_outcome = 'DECLINE'
                THEN 'NO_OFFER_PRELIMINARY_DECLINE'

            WHEN ae.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'UNRESOLVED_MANUAL_REVIEW'

            WHEN ae.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ae.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBLE_PRELIMINARY'

            WHEN ae.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ae.counteroffer_feasibility_pass_flag IS FALSE
                THEN 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'

            ELSE 'EXPOSURE_TREATMENT_UNKNOWN'
        END AS exposure_treatment_status,


        /*******************************************************************************************
        exposure_treatment_path.

        Compact preliminary exposure-treatment path label.

        This is not final decision_path.
        *******************************************************************************************/
        CASE
            WHEN ae.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVE_AS_REQUESTED'

            WHEN ae.preliminary_decision_outcome = 'DECLINE'
                THEN 'NO_OFFER'

            WHEN ae.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW_UNRESOLVED'

            WHEN ae.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ae.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBLE'

            WHEN ae.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ae.counteroffer_feasibility_pass_flag IS FALSE
                THEN 'COUNTEROFFER_NOT_FEASIBLE'

            ELSE 'EXPOSURE_TREATMENT_UNKNOWN'
        END AS exposure_treatment_path

    FROM approved_economics ae
)

SELECT *
FROM final_exposure_treatment;



/***************************************************************************************************
SECTION 8.3 — LOCAL FAIL-FAST CHECKS FOR EXPOSURE TREATMENT
****************************************************************************************************

PURPOSE:
    Validate the Section 8 preliminary exposure-treatment layer before final decision resolution.

BUSINESS PURPOSE:
    Confirm that approved-exposure treatment, approved affordability proxies, approved Expected Loss
    proxies, and counteroffer feasibility diagnostics are internally consistent before Section 9
    resolves final decision_outcome.

SQL PURPOSE:
    1. Confirm row count is preserved from Section 7 to Section 8.
    2. Confirm application_id remains unique.
    3. Confirm required exposure-treatment fields are complete.
    4. Confirm preliminary APPROVE rows preserve requested exposure and requested economics.
    5. Confirm preliminary DECLINE rows follow zero-exposure convention.
    6. Confirm preliminary MANUAL_REVIEW rows remain unresolved.
    7. Confirm preliminary COUNTEROFFER rows are explicitly evaluated for feasibility.
    8. Confirm feasible preliminary COUNTEROFFER rows satisfy reduced-exposure conventions.
    9. Confirm infeasible preliminary COUNTEROFFER rows remain unresolved with failure diagnostics.
    10. Confirm Section 8 did not create final decision, final exposure, or reason-code fields.

LOCAL GATEKEEPER BOUNDARY:
    These are local Section 8 staging gatekeepers only.

    They are not:
        final decision validation,
        simulated reason-code validation,
        archive validation,
        matched strategy comparison,
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
    v_stage4_count BIGINT;
    v_stage5_count BIGINT;
    v_stage5_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    /***********************************************************************************************
    Exposure-treatment convention diagnostics.
    ***********************************************************************************************/
    v_required_field_failure_count BIGINT;
    v_approve_route_failure_count BIGINT;
    v_decline_route_failure_count BIGINT;
    v_manual_review_route_failure_count BIGINT;
    v_counteroffer_route_failure_count BIGINT;
    v_counteroffer_pass_failure_count BIGINT;
    v_counteroffer_fail_failure_count BIGINT;

    /***********************************************************************************************
    Section boundary diagnostic.
    ***********************************************************************************************/
    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 7 to Section 8.

    Business purpose:
        Section 8 should add exposure-treatment fields only.

        It should not filter applicants or duplicate applicants.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage4_count
    FROM tmp_m2_stage_4_preliminary_decision_routing;

    SELECT COUNT(*)
    INTO v_stage5_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_count <> v_stage4_count THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: row count changed from Section 7 to Section 8. Stage 4 rows: %, Stage 5 rows: %.',
            v_stage4_count,
            v_stage5_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.

    Business purpose:
        Duplicate application_id values would duplicate final decision resolution, approved exposure,
        approved Expected Loss, and reason-code counts downstream.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage5_distinct_app_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_distinct_app_count <> v_stage5_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_5_exposure_treatment
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 8 failure: application_id uniqueness was not preserved. Stage 5 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage5_count,
            v_stage5_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required exposure-treatment fields must be complete.

    Required fields:
        exposure_treatment_status,
        exposure_treatment_path,
        counteroffer_feasibility_evaluated_flag.

    Interpretation:
        These labels document how the preliminary route was treated before final decision resolution.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_field_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE exposure_treatment_status IS NULL
       OR NULLIF(BTRIM(exposure_treatment_status), '') IS NULL
       OR exposure_treatment_path IS NULL
       OR NULLIF(BTRIM(exposure_treatment_path), '') IS NULL
       OR counteroffer_feasibility_evaluated_flag IS NULL;

    IF v_required_field_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % row(s) have missing exposure-treatment status/path or feasibility-evaluated flag.',
            v_required_field_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary APPROVE route convention.

    Expected:
        preliminary APPROVE preserves requested exposure, requested payment, requested PTI, and
        requested Expected Loss.

    Boundary:
        These are still preliminary fields. Section 9 creates final approved fields.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approve_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'APPROVE'
      AND (
            approved_amount_preliminary IS DISTINCT FROM requested_amount
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR exposure_reduction_pct_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_monthly_payment_proxy_preliminary IS DISTINCT FROM requested_monthly_payment_proxy
         OR approved_payment_to_income_ratio_preliminary IS DISTINCT FROM requested_payment_to_income_ratio
         OR approved_expected_loss_amount_preliminary IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_pct_preliminary IS DISTINCT FROM 0::NUMERIC
         OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM FALSE
         OR counteroffer_feasibility_pass_flag IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR exposure_treatment_status <> 'APPROVED_AS_REQUESTED_PRELIMINARY'
         OR exposure_treatment_path <> 'APPROVE_AS_REQUESTED'
      );

    IF v_approve_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary APPROVE row(s) violate approved-as-requested preliminary exposure convention.',
            v_approve_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary DECLINE route convention.

    Expected:
        preliminary DECLINE receives zero preliminary exposure, zero preliminary approved payment,
        zero preliminary approved PTI, and zero preliminary approved Expected Loss.

    Important:
        Final DECLINE is not created until Section 9.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decline_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'DECLINE'
      AND (
            approved_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS DISTINCT FROM requested_amount
         OR exposure_reduction_pct_preliminary IS DISTINCT FROM 1.0::NUMERIC
         OR approved_monthly_payment_proxy_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_payment_to_income_ratio_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_expected_loss_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_amount_preliminary IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_pct_preliminary IS DISTINCT FROM
                CASE
                    WHEN requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END
         OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM FALSE
         OR counteroffer_feasibility_pass_flag IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR exposure_treatment_status <> 'NO_OFFER_PRELIMINARY_DECLINE'
         OR exposure_treatment_path <> 'NO_OFFER'
      );

    IF v_decline_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary DECLINE row(s) violate zero-exposure preliminary convention.',
            v_decline_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary MANUAL_REVIEW route convention.

    Manual review remains unresolved.

    Expected:
        preliminary approved exposure, preliminary approved payment, preliminary approved PTI, and
        preliminary approved Expected Loss remain NULL.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'MANUAL_REVIEW'
      AND (
            approved_amount_preliminary IS NOT NULL
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS NOT NULL
         OR exposure_reduction_pct_preliminary IS NOT NULL
         OR approved_monthly_payment_proxy_preliminary IS NOT NULL
         OR approved_payment_to_income_ratio_preliminary IS NOT NULL
         OR approved_expected_loss_amount_preliminary IS NOT NULL
         OR approved_el_reduction_amount_preliminary IS NOT NULL
         OR approved_el_reduction_pct_preliminary IS NOT NULL
         OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM FALSE
         OR counteroffer_feasibility_pass_flag IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR exposure_treatment_status <> 'UNRESOLVED_MANUAL_REVIEW'
         OR exposure_treatment_path <> 'MANUAL_REVIEW_UNRESOLVED'
      );

    IF v_manual_review_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary MANUAL_REVIEW row(s) violate unresolved preliminary exposure convention.',
            v_manual_review_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary COUNTEROFFER route must be explicitly evaluated and pass/fail must be
    non-null.

    Expected:
        every preliminary COUNTEROFFER row receives:
            counteroffer_feasibility_evaluated_flag = TRUE,
            non-null counteroffer_feasibility_pass_flag,
            feasible or not-feasible exposure treatment status.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_feasibility_evaluated_flag IS DISTINCT FROM TRUE
         OR counteroffer_feasibility_pass_flag IS NULL
         OR exposure_treatment_status NOT IN (
                'COUNTEROFFER_FEASIBLE_PRELIMINARY',
                'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'
            )
         OR exposure_treatment_path NOT IN (
                'COUNTEROFFER_FEASIBLE',
                'COUNTEROFFER_NOT_FEASIBLE'
            )
      );

    IF v_counteroffer_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary COUNTEROFFER row(s) were not explicitly evaluated for feasibility.',
            v_counteroffer_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: feasible preliminary COUNTEROFFER convention.

    Expected:
        feasible counteroffers have a positive reduced approved amount,
        approved amount is below requested amount,
        exposure reduction is positive,
        approved amount respects product minimum and cap,
        approved PTI meets target,
        approved Expected Loss meets cap,
        no feasibility failure reason is populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_pass_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS TRUE
      AND (
            approved_amount_preliminary IS NULL
         OR counteroffer_amount_preliminary IS DISTINCT FROM approved_amount_preliminary
         OR approved_amount_preliminary <= 0
         OR approved_amount_preliminary >= requested_amount
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM TRUE
         OR exposure_reduction_amount_preliminary <= 0
         OR exposure_reduction_pct_preliminary <= 0
         OR approved_amount_preliminary < product_min_approved_amount
         OR approved_amount_preliminary > product_max_approved_amount
         OR approved_payment_to_income_ratio_preliminary > counteroffer_target_pti
         OR approved_expected_loss_amount_preliminary > product_approved_el_cap
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR exposure_treatment_status <> 'COUNTEROFFER_FEASIBLE_PRELIMINARY'
         OR exposure_treatment_path <> 'COUNTEROFFER_FEASIBLE'
      );

    IF v_counteroffer_pass_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % feasible preliminary COUNTEROFFER row(s) violate counteroffer feasibility convention.',
            v_counteroffer_pass_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: infeasible preliminary COUNTEROFFER convention.

    Expected:
        infeasible preliminary counteroffers remain unresolved in Section 8,
        have NULL preliminary approved-exposure fields,
        and carry a feasibility failure reason.

    Section 9 later resolves the final outcome using failed_counteroffer_resolution.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_fail_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND (
            approved_amount_preliminary IS NOT NULL
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS NOT NULL
         OR exposure_reduction_pct_preliminary IS NOT NULL
         OR approved_monthly_payment_proxy_preliminary IS NOT NULL
         OR approved_payment_to_income_ratio_preliminary IS NOT NULL
         OR approved_expected_loss_amount_preliminary IS NOT NULL
         OR approved_el_reduction_amount_preliminary IS NOT NULL
         OR approved_el_reduction_pct_preliminary IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NULL
         OR exposure_treatment_status <> 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'
         OR exposure_treatment_path <> 'COUNTEROFFER_NOT_FEASIBLE'
      );

    IF v_counteroffer_fail_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % infeasible preliminary COUNTEROFFER row(s) violate failed-counteroffer convention.',
            v_counteroffer_fail_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 8 must not create final decision, final flags, final exposure fields,
    simulated reason-code fields, latest-run output, or archive logic.

    Exact final field names are checked.

    Preliminary exposure-treatment fields are allowed.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_5_exposure_treatment'::REGCLASS
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
            'Module 2 Section 8 failure: forbidden final decision, final exposure, or reason-code field(s) were created in exposure-treatment stage.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 8.4 — LOCAL EXPOSURE-TREATMENT SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for Section 8 exposure treatment and counteroffer feasibility.

BUSINESS PURPOSE:
    Let reviewers inspect preliminary exposure-treatment behavior before final decision resolution.

SQL PURPOSE:
    Display review outputs for:
        preliminary route × exposure-treatment status,
        exposure-treatment path,
        feasibility-evaluated flag,
        counteroffer feasibility pass / fail,
        counteroffer failure reason,
        product × counteroffer feasibility,
        score band × counteroffer feasibility,
        requested PTI bucket × counteroffer feasibility,
        synthetic risk tier × counteroffer feasibility,
        requested versus preliminary approved amount,
        requested versus preliminary approved PTI,
        requested versus preliminary approved Expected Loss,
        exposure reduction for feasible counteroffers,
        counteroffer failure reason by product,
        counteroffer feasibility constraint count for failed counteroffers.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        final strategy validation,
        final decision distribution,
        simulated reason-code validation,
        archive validation,
        matched strategy comparison,
        strategy frontier evidence,
        or Validation Summary acceptance.

SQL TEACHING POINT:
    These SELECT statements are read-only diagnostics.

    GROUP BY summarizes exposure-treatment behavior.

    AVG fields help reviewers understand whether exposure treatment is directionally coherent with
    requested exposure, requested PTI, synthetic estimated-risk proxy, and requested Expected Loss.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
8.4.1 Count by preliminary_decision_outcome × exposure_treatment_status.

Purpose:
    Show how each preliminary route maps into exposure-treatment status.

Expected:
    APPROVE:
        APPROVED_AS_REQUESTED_PRELIMINARY

    DECLINE:
        NO_OFFER_PRELIMINARY_DECLINE

    MANUAL_REVIEW:
        UNRESOLVED_MANUAL_REVIEW

    COUNTEROFFER:
        COUNTEROFFER_FEASIBLE_PRELIMINARY
        or COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY

Boundary:
    exposure_treatment_status is not final decision_outcome.
-----------------------------------------------------------------------------------------------*/

SELECT
    preliminary_decision_outcome,
    exposure_treatment_status,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY
    preliminary_decision_outcome,
    exposure_treatment_status
ORDER BY
    preliminary_decision_outcome,
    exposure_treatment_status;



/*-----------------------------------------------------------------------------------------------
8.4.2 Count by exposure_treatment_path.

Purpose:
    Summarize the compact preliminary exposure-treatment path labels.

Interpretation:
    exposure_treatment_path is a preliminary exposure-treatment label.

    It is not final decision_path.
-----------------------------------------------------------------------------------------------*/

SELECT
    exposure_treatment_path,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_path
ORDER BY exposure_treatment_path;



/*-----------------------------------------------------------------------------------------------
8.4.3 Count by counteroffer_feasibility_evaluated_flag.

Purpose:
    Confirm which rows were explicitly evaluated for counteroffer feasibility.

Expected:
    TRUE only for preliminary COUNTEROFFER rows.

Interpretation:
    Non-counteroffer preliminary routes should not receive counteroffer feasibility evaluation.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_evaluated_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY counteroffer_feasibility_evaluated_flag
ORDER BY counteroffer_feasibility_evaluated_flag;



/*-----------------------------------------------------------------------------------------------
8.4.4 Count by counteroffer_feasibility_pass_flag.

Purpose:
    Show the pass / fail distribution of preliminary counteroffer feasibility.

Interpretation:
    TRUE and FALSE apply only to preliminary COUNTEROFFER rows.

    NULL applies to non-counteroffer preliminary routes.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY counteroffer_feasibility_pass_flag
ORDER BY counteroffer_feasibility_pass_flag;



/*-----------------------------------------------------------------------------------------------
8.4.5 Count by counteroffer_feasibility_failure_reason.

Purpose:
    Show the distribution of feasibility failure diagnostics.

Interpretation:
    Failure reasons explain preliminary counteroffer feasibility failure only.

    They are not final simulated reason codes.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY counteroffer_feasibility_failure_reason
ORDER BY counteroffer_feasibility_failure_reason;



/*-----------------------------------------------------------------------------------------------
8.4.6 Product × counteroffer_feasibility_pass_flag.

Purpose:
    Show whether counteroffer feasibility varies by product.

Credit risk interpretation:
    Product-specific policy parameters can affect counteroffer feasibility through:
        product cap,
        product minimum amount,
        approved Expected Loss cap,
        minimum counteroffer percent,
        maximum exposure reduction,
        and rounding increment.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag
ORDER BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag;



/*-----------------------------------------------------------------------------------------------
8.4.7 Score band × counteroffer_feasibility_pass_flag.

Purpose:
    Show whether counteroffer feasibility varies by score band.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

    Score band and estimated_pd should generally show directional alignment, while realistic overlap
    remains possible.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    score_band_policy_key,
    counteroffer_feasibility_pass_flag
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    counteroffer_feasibility_pass_flag;



/*-----------------------------------------------------------------------------------------------
8.4.8 Requested PTI bucket × counteroffer_feasibility_pass_flag.

Purpose:
    Show whether requested affordability pressure affects counteroffer feasibility.

Interpretation:
    requested_payment_to_income_ratio is requested-structure PTI.

    approved_payment_to_income_ratio_preliminary is the preliminary post-treatment PTI proxy for
    feasible counteroffers.

Boundary:
    approved_payment_to_income_ratio_preliminary is not final approved PTI.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio_preliminary) AS avg_approved_payment_to_income_ratio_preliminary
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    requested_pti_bucket,
    counteroffer_feasibility_pass_flag
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    counteroffer_feasibility_pass_flag;



/*-----------------------------------------------------------------------------------------------
8.4.9 Strategy risk tier × counteroffer_feasibility_pass_flag.

Purpose:
    Show whether synthetic estimated-risk tier interacts with counteroffer feasibility.

Interpretation:
    This is useful because approved Expected Loss cap feasibility depends on:
        approved amount,
        estimated_pd,
        and estimated_lgd.

Boundary:
    estimated_pd is not recalculated by counteroffer treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount_preliminary) AS avg_approved_expected_loss_amount_preliminary
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    strategy_risk_tier,
    counteroffer_feasibility_pass_flag
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    counteroffer_feasibility_pass_flag;



/*-----------------------------------------------------------------------------------------------
8.4.10 Average requested_amount versus approved_amount_preliminary by exposure_treatment_status.

Purpose:
    Show how exposure treatment changes requested exposure into preliminary approved exposure.

Interpretation:
    Approved amount is still preliminary at this stage.

    Feasible counteroffers should show approved_amount_preliminary below requested_amount.

    Manual-review rows should have NULL approved_amount_preliminary.
-----------------------------------------------------------------------------------------------*/

SELECT
    exposure_treatment_status,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount_preliminary) AS avg_approved_amount_preliminary,
    AVG(requested_amount - approved_amount_preliminary)
        FILTER (WHERE approved_amount_preliminary IS NOT NULL)
        AS avg_requested_minus_approved_amount_preliminary
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_status
ORDER BY exposure_treatment_status;



/*-----------------------------------------------------------------------------------------------
8.4.11 Average requested PTI versus approved PTI preliminary by exposure_treatment_status.

Purpose:
    Show whether preliminary exposure treatment improves affordability.

Interpretation:
    approved_payment_to_income_ratio_preliminary is a strategy-simulation proxy.

    It is not final approved PTI and not a contractual payment quote.
-----------------------------------------------------------------------------------------------*/

SELECT
    exposure_treatment_status,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio_preliminary)
        AS avg_approved_payment_to_income_ratio_preliminary,
    AVG(requested_payment_to_income_ratio - approved_payment_to_income_ratio_preliminary)
        FILTER (WHERE approved_payment_to_income_ratio_preliminary IS NOT NULL)
        AS avg_requested_minus_approved_pti_preliminary
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_status
ORDER BY exposure_treatment_status;



/*-----------------------------------------------------------------------------------------------
8.4.12 Average requested Expected Loss versus approved Expected Loss preliminary by exposure_treatment_status.

Purpose:
    Show how preliminary exposure treatment changes requested-exposure Expected Loss into
    preliminary approved-exposure Expected Loss.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount_preliminary is preliminary approved-exposure Expected Loss.

Boundary:
    Final approved_expected_loss_amount is created in Section 9.
-----------------------------------------------------------------------------------------------*/

SELECT
    exposure_treatment_status,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount_preliminary)
        AS avg_approved_expected_loss_amount_preliminary,
    AVG(requested_expected_loss_amount - approved_expected_loss_amount_preliminary)
        FILTER (WHERE approved_expected_loss_amount_preliminary IS NOT NULL)
        AS avg_requested_minus_approved_expected_loss_preliminary
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_status
ORDER BY exposure_treatment_status;



/*-----------------------------------------------------------------------------------------------
8.4.13 Average exposure_reduction_pct_preliminary by product for feasible counteroffers.

Purpose:
    Show the size of exposure reductions among feasible preliminary counteroffers by product.

Interpretation:
    Feasible counteroffers should show positive exposure reduction.

    Product differences may reflect different caps, minimums, requested amount distributions, PTI
    targets, approved Expected Loss caps, and rounding increments.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    COUNT(*) AS feasible_counteroffer_rows,
    AVG(exposure_reduction_pct_preliminary) AS avg_exposure_reduction_pct_preliminary,
    MIN(exposure_reduction_pct_preliminary) AS min_exposure_reduction_pct_preliminary,
    MAX(exposure_reduction_pct_preliminary) AS max_exposure_reduction_pct_preliminary
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS TRUE
GROUP BY product_type_policy_key
ORDER BY product_type_policy_key;



/*-----------------------------------------------------------------------------------------------
8.4.14 Count of counteroffer failures by product and failure reason.

Purpose:
    Show which counteroffer feasibility constraints are failing by product.

Interpretation:
    Failure reasons explain feasibility failure only.

    They are not final simulated reason codes.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS failed_counteroffer_rows
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE
GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_failure_reason
ORDER BY
    product_type_policy_key,
    failed_counteroffer_rows DESC,
    counteroffer_feasibility_failure_reason;



/*-----------------------------------------------------------------------------------------------
8.4.15 Average counteroffer_feasibility_constraint_count for failed counteroffers.

Purpose:
    Show how many feasibility constraints failed on preliminary COUNTEROFFER rows.

Interpretation:
    Higher counts indicate multiple feasibility constraints failed on the same preliminary
    COUNTEROFFER row.

    This helps distinguish:
        one binding issue,
        versus multiple simultaneous feasibility problems.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS failed_counteroffer_rows,
    AVG(counteroffer_feasibility_constraint_count)
        AS avg_counteroffer_feasibility_constraint_count,
    MIN(counteroffer_feasibility_constraint_count)
        AS min_counteroffer_feasibility_constraint_count,
    MAX(counteroffer_feasibility_constraint_count)
        AS max_counteroffer_feasibility_constraint_count
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE
GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_failure_reason
ORDER BY
    product_type_policy_key,
    failed_counteroffer_rows DESC,
    counteroffer_feasibility_failure_reason;



/***************************************************************************************************
END OF SECTION 8 — APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY LAYER

If execution reaches this point:
    1. Section 8 dependency preflight passed.
    2. tmp_m2_stage_5_exposure_treatment exists.
    3. Row count is unchanged from tmp_m2_stage_4_preliminary_decision_routing.
    4. application_id remains unique.
    5. Module 1 lineage remains preserved.
    6. Module 2 strategy metadata remains preserved.
    7. All Section 7 preliminary routing fields remain preserved.
    8. Preliminary APPROVE rows preserve requested exposure, requested payment, requested PTI, and
       requested-exposure Expected Loss.
    9. Preliminary DECLINE rows use the zero-exposure convention.
    10. Preliminary MANUAL_REVIEW rows remain unresolved with NULL preliminary approved-exposure
        fields.
    11. Preliminary COUNTEROFFER rows are explicitly evaluated for counteroffer feasibility.
    12. Feasible preliminary COUNTEROFFER rows have reduced exposure.
    13. Feasible preliminary COUNTEROFFER rows have approved_amount_preliminary < requested_amount.
    14. Feasible preliminary COUNTEROFFER rows satisfy product minimum, product cap, minimum
        counteroffer percent, maximum exposure reduction, approved PTI target, and approved Expected
        Loss cap.
    15. Infeasible preliminary COUNTEROFFER rows retain NULL preliminary approved-exposure fields and
        have a counteroffer_feasibility_failure_reason.
    16. Counteroffer feasibility failure reasons are diagnostics only, not simulated reason codes.
    17. estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy.
    18. approved_expected_loss_amount_preliminary is based on preliminary approved exposure.
    19. Failed counteroffer final resolution is deferred to Section 9.
    20. Section 8 local exposure-treatment diagnostics are available for review.

No final decision_outcome exists yet.
No final decision_path exists yet.
No final approval / counteroffer / manual review / decline flags exist yet.
No simulated_offer_exposure_flag exists yet.
No simulated reason codes exist yet.
No final approved_amount exists yet.
No final counteroffer_amount exists yet.
No final approved payment proxy exists yet.
No final approved payment-to-income ratio exists yet.
No final approved Expected Loss exists yet.
No latest-run strategy decision output has been created.
No archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full QA framework has been built.

Next section:
    Section 9 should consume tmp_m2_stage_5_exposure_treatment and resolve final decision_outcome,
    final decision_path, final decision flags, simulated offer-exposure flag, final approved exposure,
    final approved payment proxy, final approved PTI, and final approved Expected Loss fields.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00930 -->


---

<a id="c038-m00931"></a>

### C038-M00931

**Andrew** · 2026-05-10T00:04:27.818000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00931 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 9 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00931 -->


**Attachments in export:** `Pasted text(147).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_44.md) · [Next](Part_46.md)
