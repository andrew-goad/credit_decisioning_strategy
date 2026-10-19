# Module 2 Decision Simulator Build

## Part 46

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_45.md) · [Next](Part_47.md)

<a id="c038-m00936"></a>

### C038-M00936

**ChatGPT** · 2026-05-10T00:10:23.206161-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00936 -->
I recommend replacing Section 9 with the version below. It preserves your current final decision-resolution logic, adds a Section 9.0 dependency preflight, and hardens the instructional commentary around run order, interpretation boundaries, credit-risk concepts, and SQL mechanics. fileciteturn95file0

```sql
/***************************************************************************************************
SECTION 9 — FINAL DECISION RESOLUTION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Resolve preliminary routing plus exposure-treatment feasibility into final simulated strategy
    outcomes for each synthetic applicant.

    Section 9 answers:

        "Given preliminary routing and exposure-treatment feasibility, what is the final simulated
         strategy outcome for this synthetic applicant?"

    Section 9 does not answer:

        "What simulated reason codes explain the outcome?"

    Section 9 is the final outcome-resolution layer.

    It converts:
        Section 7 preliminary route
        +
        Section 8 exposure-treatment / counteroffer feasibility evidence

    into:
        final simulated decision_outcome,
        final decision_path,
        final decision flags,
        final simulated offer-exposure flag,
        final approved exposure,
        final approved affordability proxy,
        and final approved Expected Loss.

SQL PURPOSE:
    1. Confirm required Section 9 dependencies exist.
    2. Read from tmp_m2_stage_5_exposure_treatment.
    3. Attach the governed failed_counteroffer_resolution strategy parameter.
    4. Convert preliminary_decision_outcome and counteroffer feasibility into final:
            decision_outcome
            decision_path
            decision_priority_rank
            decision_resolution_source
    5. Create final decision flags:
            approval_flag
            counteroffer_flag
            manual_review_flag
            decline_flag
            simulated_offer_exposure_flag
    6. Create final approved exposure, approved affordability, and approved economics fields:
            approved_amount
            counteroffer_amount
            exposure_reduction_flag
            exposure_reduction_amount
            exposure_reduction_pct
            approved_monthly_payment_proxy
            approved_payment_to_income_ratio
            approved_expected_loss_amount
            approved_el_reduction_amount
            approved_el_reduction_pct
    7. Preserve preliminary routing and exposure-treatment diagnostics.
    8. Validate final outcome and final exposure conventions before simulated reason-code assignment.
    9. Confirm that simulated reason-code fields are not created yet.
    10. Confirm that latest-run table materialization remains deferred to Section 11.
    11. Provide local final decision-resolution diagnostics before Section 10 reason-code assignment.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that preliminary routes and exposure-treatment feasibility resolve into intuitive final
        simulated strategy outcomes.

    Model governance / validation reviewers:
        Confirm that Section 9 finalizes simulated outcomes without assigning customer-facing
        explanations, modifying archive history, or overstating simulated outputs as operational
        underwriting decisions.

    SQL reviewers:
        Confirm that the final outcome CASE logic is deterministic, parameter-governed, and locally
        validated through final convention checks.

    Portfolio / executive reviewers:
        Use Section 9 diagnostics to understand how the strategy’s final outcome mix emerges after
        counteroffer feasibility and failed-counteroffer resolution are applied.

WHEN TO RUN THIS SECTION:
    Run Section 9 after:

        Section 8 — Approved Exposure and Counteroffer Feasibility Layer

    Section 9 should be run before:

        Section 10 — Simulated Reason-Code Assignment Layer

    Section 9 depends on:

        tmp_m2_stage_5_exposure_treatment
        tmp_module2_strategy_params

HOW TO INTERPRET THIS SECTION:
    Passing Section 9 means:
        row count is preserved from Section 8,
        application_id remains unique,
        every row has one final simulated decision_outcome,
        final decision flags reconcile to decision_outcome,
        simulated_offer_exposure_flag reconciles to APPROVE / COUNTEROFFER,
        APPROVE rows preserve requested exposure,
        COUNTEROFFER rows have feasible reduced exposure,
        MANUAL_REVIEW rows remain unresolved,
        DECLINE rows follow zero-exposure convention,
        failed preliminary counteroffers resolve according to failed_counteroffer_resolution,
        and simulated reason-code assignment remains deferred.

    Passing Section 9 does not mean:
        simulated reason codes are assigned,
        latest-run output has been materialized,
        archive persistence worked,
        matched comparison is complete,
        full QA validation has passed,
        strategy frontier evidence has been created,
        or executive evidence has been captured.

INPUT:
    tmp_m2_stage_5_exposure_treatment

OUTPUT:
    tmp_m2_stage_6_final_decision_resolution

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

FINAL DECISION TAXONOMY:
    Section 9 resolves every row into exactly one of:

        APPROVE
        COUNTEROFFER
        MANUAL_REVIEW
        DECLINE

WHY FINAL DECISION RESOLUTION IS SEPARATED FROM PRELIMINARY ROUTING:
    Section 7 creates preliminary routes before approved exposure exists.

    Section 8 evaluates exposure treatment and counteroffer feasibility.

    Section 9 resolves final simulated strategy outcomes using both prior layers.

    This separation protects interpretability:

        preliminary routing explains where the row was sent;
        exposure treatment explains what exposure was feasible;
        final decision resolution explains what simulated strategy outcome remains after feasibility.

WHY SECTION 8 EXPOSURE FEASIBILITY IS REQUIRED BEFORE FINAL COUNTEROFFER RESOLUTION:
    A preliminary COUNTEROFFER route is not final.

    It must pass reduced-exposure feasibility tests before becoming a final COUNTEROFFER outcome.

    Feasibility tests include:
        product cap,
        product minimum,
        minimum counteroffer percent,
        maximum exposure reduction,
        approved PTI target,
        and approved Expected Loss cap.

WHY FAILED COUNTEROFFERS USE A GOVERNED RESOLUTION PARAMETER:
    Infeasible counteroffers can be routed to:

        MANUAL_REVIEW
        or
        DECLINE

    The active strategy controls this through:

        failed_counteroffer_resolution

    Default:
        MANUAL_REVIEW

    This is a simulated strategy-control parameter, not operational underwriting policy.

CREDIT RISK INTERPRETATION — APPROVE:
    APPROVE is a simulated positive offer-exposure outcome as requested.

    In Section 9:
        approved_amount = requested_amount
        approved_payment_to_income_ratio = requested_payment_to_income_ratio
        approved_expected_loss_amount = requested_expected_loss_amount

    This means the strategy preserved the requested structure.

    It does not mean:
        a real account is opened,
        real funding occurs,
        or an operational applicant treatment is made.

CREDIT RISK INTERPRETATION — COUNTEROFFER:
    COUNTEROFFER is a simulated positive offer-exposure outcome with reduced approved exposure.

    In Section 9, final COUNTEROFFER requires:
        preliminary_decision_outcome = 'COUNTEROFFER'
        counteroffer_feasibility_pass_flag = TRUE

    A final COUNTEROFFER row receives:
        approved_amount below requested_amount,
        counteroffer_amount equal to approved_amount,
        positive exposure reduction,
        approved PTI at or below the product target,
        approved Expected Loss at or below the product cap.

CREDIT RISK INTERPRETATION — MANUAL_REVIEW:
    MANUAL_REVIEW remains unresolved by design.

    Manual-review rows retain:
        approved_amount = NULL
        counteroffer_amount = NULL
        approved_monthly_payment_proxy = NULL
        approved_payment_to_income_ratio = NULL
        approved_expected_loss_amount = NULL

    This is not missing data.

    It is the intentional unresolved convention for simulated manual review.

CREDIT RISK INTERPRETATION — DECLINE:
    DECLINE follows the zero-exposure convention.

    Decline rows receive:
        approved_amount = 0
        approved_monthly_payment_proxy = 0
        approved_payment_to_income_ratio = 0
        approved_expected_loss_amount = 0

    Decline is a simulated no-offer outcome in this synthetic strategy engine.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag means the simulated strategy output includes positive offer
    exposure for the synthetic applicant.

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

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount:
        Approved-exposure Expected Loss from Module 2 after final exposure treatment.

    Conceptual formula:
        approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd

    estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
    proxy.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field.

    In Section 9, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 9 does not:
        recalculate estimated_pd,
        calibrate a default model,
        create a post-decision risk model,
        or validate production default forecasting.

WHY DECISION_OUTCOME BECOMES FINAL HERE BUT REASON CODES REMAIN DEFERRED:
    Section 9 establishes the final simulated strategy outcome and final approved-exposure economics.

    Section 10 explains those outcomes using:
        final decision outcome,
        final decision path,
        preliminary routing diagnostics,
        rule-trigger diagnostics,
        exposure-treatment diagnostics,
        counteroffer feasibility diagnostics,
        mixed-signal diagnostics,
        and borderline diagnostics.

    Keeping final outcome assignment separate from simulated reason-code assignment makes both layers
    easier to validate.

REASON-CODE BOUNDARY:
    Section 9 does not assign simulated reason codes.

    It does not create:
        primary_reason_code
        secondary_reason_code
        tertiary_reason_code
        triggered_reason_code_list
        reason_priority_rank
        primary_reason_family
        reason_code_count

LATEST-RUN / ARCHIVE BOUNDARY:
    Section 9 does not create:

        credit_decisioning_sim.strategy_decisions

    Section 9 does not insert rows into:

        credit_decisioning_sim.strategy_decisions_archive

    Latest-run output materialization remains deferred to Section 11.
    Archive persistence remains deferred to Section 12.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the final decision-resolution layer as a session-scoped staging table.

    ON COMMIT PRESERVE ROWS:
        Keeps the staging table available across transaction boundaries in the active session.

    CTE chain:
        The WITH clause breaks final decision resolution into readable steps:
            active_strategy_params
            resolution_inputs
            decision_core
            decision_flags
            final_exposure_fields

    CROSS JOIN:
        Attaches the one active failed_counteroffer_resolution parameter to every exposure-treatment
        row.

    CASE:
        Implements final decision resolution and final exposure conventions.

        CASE evaluates top to bottom and returns the first matching branch, so order matters.

    Boolean expressions:
        Convert final decision_outcome into final decision flags.

    IS DISTINCT FROM:
        Provides NULL-safe equality checks in gatekeepers.

    pg_attribute:
        Inspects physical columns on the temporary table to confirm simulated reason-code fields were
        not created too early.

    TO_REGCLASS:
        Checks whether the latest-run output table exists before Section 11 materializes it.

GOVERNANCE ROLE:
    Section 9 locks the final simulated outcome taxonomy and final output conventions before
    explanation codes, latest-run materialization, archive persistence, comparison, QA, frontier
    review, and evidence capture occur.

COMMON MISUSE TO AVOID:
    Do not interpret decision_outcome as a real applicant decision.
    Do not interpret decision_path as a customer communication or regulatory explanation.
    Do not interpret simulated_offer_exposure_flag as operational account creation.
    Do not interpret approved_expected_loss_amount as a production loss forecast.
    Do not interpret MANUAL_REVIEW rows as completed operational reviews.
    Do not treat counteroffer feasibility failure diagnostics as final simulated reason codes.
    Do not treat Section 9 output as the permanent latest-run table.

TESTING RELEVANCE:
    Section 9 local gatekeepers confirm:
        final outcome completeness,
        final flag reconciliation,
        simulated offer-exposure convention,
        APPROVE exposure convention,
        COUNTEROFFER exposure convention,
        MANUAL_REVIEW unresolved convention,
        DECLINE zero-exposure convention,
        failed counteroffer resolution,
        absence of simulated reason-code fields,
        and latest-run materialization deferral.

DOWNSTREAM DEPENDENCY:
    Section 10 consumes:

        tmp_m2_stage_6_final_decision_resolution

    Section 10 requires:
        final decision_outcome,
        decision_path,
        final flags,
        simulated_offer_exposure_flag,
        approved exposure fields,
        approved affordability fields,
        approved Expected Loss fields,
        rule-trigger diagnostics,
        preliminary routing diagnostics,
        exposure-treatment diagnostics,
        and counteroffer feasibility diagnostics.

PORTFOLIO ARTIFACT VALUE:
    This section demonstrates a mature decision-engine boundary:

        preliminary route is not final outcome;
        counteroffer candidate is not feasible counteroffer;
        exposure treatment is not reason-code assignment;
        final outcome is not archive persistence;
        and simulated strategy output remains clearly bounded.

***************************************************************************************************/



/***************************************************************************************************
SECTION 9.0 — SECTION 9 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 8 exposure-treatment output and the active strategy parameter card exist
    before final decision resolution begins.

    Section 9.0 answers:

        "Can Section 9 safely resolve final simulated outcomes from the current Section 8
         exposure-treatment layer?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_5_exposure_treatment exists.
    2. Confirm tmp_module2_strategy_params exists.
    3. Confirm the exposure-treatment table contains rows.
    4. Confirm application_id remains unique before final decision fields are added.
    5. Confirm exactly one active strategy parameter row exists.
    6. Confirm failed_counteroffer_resolution is valid.
    7. Confirm Section 8 exposure-treatment fields required by Section 9 are populated.
    8. Fail clearly if Section 9 is run out of order.

WHY THIS PREFLIGHT EXISTS:
    Section 9 is a transformation layer.

    It should fail with a clear instructional message if Section 8 has not run, rather than producing
    a lower-level missing-table error.

CREDIT RISK INTERPRETATION:
    Final decision resolution depends on:
        preliminary route,
        exposure-treatment status,
        counteroffer feasibility,
        preliminary approved exposure,
        preliminary approved affordability,
        preliminary approved Expected Loss,
        and failed-counteroffer resolution strategy.

    If any of these inputs are unavailable, final simulated outcome assignment would be ambiguous.

BOUNDARY:
    Section 9.0 does not create final decisions.
    Section 9.0 does not create final exposure fields.
    Section 9.0 does not create reason codes.
    Section 9.0 does not create the latest-run output table.
    Section 9.0 does not modify any persistent table.

***************************************************************************************************/

DO $$
DECLARE
    v_stage5_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;

    v_stage5_row_count BIGINT;
    v_stage5_distinct_application_count BIGINT;
    v_active_strategy_count BIGINT;

    v_failed_counteroffer_resolution_gap_count BIGINT;
    v_required_section8_gap_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 8 exposure-treatment table must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

        pg_temp is checked because tmp_m2_stage_5_exposure_treatment is a temporary table.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_5_exposure_treatment'),
        TO_REGCLASS('tmp_m2_stage_5_exposure_treatment')
    ) IS NOT NULL
    INTO v_stage5_exists;

    IF v_stage5_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: tmp_m2_stage_5_exposure_treatment is required. Run Section 8 before Section 9.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: active strategy parameter table must exist.

    Section 9 needs failed_counteroffer_resolution from the active strategy card.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_strategy_params'),
        TO_REGCLASS('tmp_module2_strategy_params')
    ) IS NOT NULL
    INTO v_strategy_params_exists;

    IF v_strategy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: tmp_module2_strategy_params is required. Run Section 2 before Section 9.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 8 exposure-treatment table must contain rows.

    Business interpretation:
        Final decision resolution over an empty applicant population is not useful and usually
        indicates an upstream source, routing, or exposure-treatment issue.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage5_row_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: tmp_m2_stage_5_exposure_treatment contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id should be unique before final decision resolution.

    Section 9 should add final decision fields only.

    It should not repair grain problems from earlier stages.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage5_distinct_application_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_distinct_application_count <> v_stage5_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: tmp_m2_stage_5_exposure_treatment is not unique at application_id. Rows=%, distinct application_id=%.',
            v_stage5_row_count,
            v_stage5_distinct_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active strategy parameter row.

    Section 3 already validates this, but Section 9 repeats the local dependency check so this
    section fails clearly when run out of order or with stale parameter state.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: failed_counteroffer_resolution must be populated and valid.

    Business interpretation:
        Failed preliminary counteroffers must resolve through a governed strategy parameter.

    Allowed values:
        MANUAL_REVIEW
        DECLINE
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_failed_counteroffer_resolution_gap_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
      AND (
             failed_counteroffer_resolution IS NULL
          OR failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE')
      );

    IF v_failed_counteroffer_resolution_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: active strategy failed_counteroffer_resolution must be MANUAL_REVIEW or DECLINE.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 8 fields required by Section 9 must be populated or intentionally NULL by
    route convention.

    Business interpretation:
        Final decision resolution needs complete preliminary outcome, exposure-treatment status,
        and counteroffer feasibility evidence.

    Manual-review and failed-counteroffer exposure fields may be NULL by design.

    This check therefore validates route-driving fields, not every final exposure value.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_section8_gap_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome IS NULL
       OR preliminary_decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR preliminary_decision_path IS NULL
       OR NULLIF(BTRIM(preliminary_decision_path), '') IS NULL
       OR preliminary_decision_priority_rank IS NULL
       OR exposure_treatment_status IS NULL
       OR NULLIF(BTRIM(exposure_treatment_status), '') IS NULL
       OR exposure_treatment_path IS NULL
       OR NULLIF(BTRIM(exposure_treatment_path), '') IS NULL
       OR counteroffer_feasibility_evaluated_flag IS NULL
       OR requested_amount IS NULL
       OR requested_monthly_payment_proxy IS NULL
       OR requested_payment_to_income_ratio IS NULL
       OR requested_expected_loss_amount IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL
       OR (
            preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS NULL
       )
       OR (
            preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS TRUE
            AND (
                   approved_amount_preliminary IS NULL
                OR counteroffer_amount_preliminary IS NULL
                OR approved_monthly_payment_proxy_preliminary IS NULL
                OR approved_payment_to_income_ratio_preliminary IS NULL
                OR approved_expected_loss_amount_preliminary IS NULL
                OR exposure_reduction_amount_preliminary IS NULL
                OR exposure_reduction_pct_preliminary IS NULL
            )
       );

    IF v_required_section8_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % Section 8 row(s) are missing route-driving or feasible-counteroffer fields required for final decision resolution.',
            v_required_section8_gap_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 9.1 — CLEAN RESET OF SECTION 9 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 9 final decision-resolution stage before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 9 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale final-resolution rows to remain available to Section 10.

    Section 10 assumes tmp_m2_stage_6_final_decision_resolution reflects the current:
        Section 8 exposure-treatment output,
        active failed-counteroffer resolution parameter,
        final decision taxonomy,
        and final exposure conventions.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the table does not exist, PostgreSQL does not error.

BOUNDARY:
    This drop affects only the temporary Section 9 staging object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_6_final_decision_resolution;



/***************************************************************************************************
SECTION 9.2 — CREATE FINAL DECISION RESOLUTION TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_6_final_decision_resolution

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_5_exposure_treatment

OUTPUT:
    All Section 8 fields plus final decision, final flag, final approved exposure, final approved
    affordability, and final approved economics fields.

FINAL DECISION TAXONOMY:
    APPROVE
    COUNTEROFFER
    MANUAL_REVIEW
    DECLINE

IMPORTANT:
    Section 9 creates final simulated strategy outcomes.

    Section 9 does not create simulated reason codes.
    Section 9 does not create the permanent latest-run output table.
    Section 9 does not insert archive rows.

SQL DESIGN:
    This section uses a CTE chain so final decision resolution remains readable.

    The chain is:

        active_strategy_params
            selects failed_counteroffer_resolution from the one active strategy parameter card.

        resolution_inputs
            attaches failed_counteroffer_resolution to every Section 8 row.

        decision_core
            resolves decision_outcome, decision_path, decision_priority_rank, and
            decision_resolution_source.

        decision_flags
            creates final decision flags and simulated_offer_exposure_flag.

        final_exposure_fields
            applies final approved-exposure, affordability, and approved Expected Loss conventions.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 9 intentionally preserves all prior fields plus final decision-resolution fields for
    Section 10 reason-code assignment.

    Permanent output selection is handled later with an explicit field list in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_6_final_decision_resolution
ON COMMIT PRESERVE ROWS
AS
WITH active_strategy_params AS (
    /***********************************************************************************************
    CTE: active_strategy_params

    Purpose:
        Select the active failed-counteroffer resolution parameter.

    SQL mechanics:
        Section 9.0 validates exactly one active strategy row exists.

        LIMIT 1 is therefore safe.

    Credit risk interpretation:
        failed_counteroffer_resolution governs how infeasible preliminary counteroffers resolve:
            MANUAL_REVIEW
            or
            DECLINE.
    ***********************************************************************************************/
    SELECT
        failed_counteroffer_resolution
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

resolution_inputs AS (
    /***********************************************************************************************
    CTE: resolution_inputs

    Purpose:
        Attach failed_counteroffer_resolution to every Section 8 exposure-treatment row.

    SQL mechanics:
        CROSS JOIN is appropriate because active_strategy_params has exactly one row.

    Boundary:
        This CTE does not resolve final outcomes yet.

        It only makes the strategy resolution parameter available to the final decision CASE logic.
    ***********************************************************************************************/
    SELECT
        et.*,
        p.failed_counteroffer_resolution
    FROM tmp_m2_stage_5_exposure_treatment et
    CROSS JOIN active_strategy_params p
),

decision_core AS (
    /***********************************************************************************************
    CTE: decision_core

    Purpose:
        Resolve final simulated decision outcome and final decision path.

    Business interpretation:
        This is the first point in the Module 2 pipeline where decision_outcome becomes final.

    Boundary:
        Simulated reason codes are still not assigned here.
    ***********************************************************************************************/
    SELECT
        ri.*,

        /*******************************************************************************************
        Final decision_outcome.

        Allowed values:
            APPROVE
            COUNTEROFFER
            MANUAL_REVIEW
            DECLINE

        Final outcome resolution combines:
            preliminary_decision_outcome,
            counteroffer_feasibility_pass_flag,
            failed_counteroffer_resolution.

        Resolution logic:
            Preliminary DECLINE:
                remains final DECLINE.

            Preliminary MANUAL_REVIEW:
                remains final MANUAL_REVIEW.

            Preliminary APPROVE:
                becomes final APPROVE.

            Preliminary COUNTEROFFER with feasibility pass:
                becomes final COUNTEROFFER.

            Preliminary COUNTEROFFER with feasibility fail:
                resolves to MANUAL_REVIEW or DECLINE according to failed_counteroffer_resolution.

            Residual:
                resolves conservatively to MANUAL_REVIEW.
        *******************************************************************************************/
        CASE
            WHEN ri.preliminary_decision_outcome = 'DECLINE'
                THEN 'DECLINE'

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVE'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'DECLINE'
                THEN 'DECLINE'

            ELSE 'MANUAL_REVIEW'
        END AS decision_outcome,


        /*******************************************************************************************
        Final decision_path.

        decision_path is a simulated internal strategy path label.

        It is not:
            a customer communication,
            a regulatory explanation,
            a compliance notice,
            or a simulated reason code.

        APPROVE:
            APPROVE_AS_REQUESTED

        COUNTEROFFER:
            COUNTEROFFER_FEASIBLE

        Failed counteroffer:
            COUNTEROFFER_NOT_FEASIBLE_REVIEW
            or
            COUNTEROFFER_NOT_FEASIBLE_DECLINE

        Preliminary DECLINE and MANUAL_REVIEW:
            preserve the preliminary path because no exposure-treatment feasibility changed their
            route.
        *******************************************************************************************/
        CASE
            WHEN ri.preliminary_decision_outcome = 'DECLINE'
                THEN ri.preliminary_decision_path

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN ri.preliminary_decision_path

            WHEN ri.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVE_AS_REQUESTED'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBLE'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'COUNTEROFFER_NOT_FEASIBLE_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'DECLINE'
                THEN 'COUNTEROFFER_NOT_FEASIBLE_DECLINE'

            ELSE 'FINAL_RESIDUAL_STRATEGY_REVIEW'
        END AS decision_path,


        /*******************************************************************************************
        Final decision priority rank.

        For ordinary resolved rows:
            carry the preliminary route priority rank.

        Residual fallback:
            use 99 so unexpected residual handling remains visible in QA.

        Interpretation:
            This rank is a strategy-routing diagnostic.

            It is not a simulated reason-code priority rank.
        *******************************************************************************************/
        CASE
            WHEN ri.preliminary_decision_outcome IN (
                    'DECLINE',
                    'MANUAL_REVIEW',
                    'APPROVE',
                    'COUNTEROFFER'
                 )
                THEN ri.preliminary_decision_priority_rank

            ELSE 99
        END AS decision_priority_rank,


        /*******************************************************************************************
        decision_resolution_source.

        This documents how the final simulated strategy outcome was resolved.

        It is an internal simulation diagnostic, not a reason code.

        This field helps later QA answer:
            Did the final outcome come from a confirmed preliminary route?
            Did a counteroffer pass feasibility?
            Did a counteroffer fail and resolve to review?
            Did a counteroffer fail and resolve to decline?
            Did residual fallback occur?
        *******************************************************************************************/
        CASE
            WHEN ri.preliminary_decision_outcome = 'DECLINE'
                THEN 'PRELIMINARY_DECLINE_CONFIRMED'

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'PRELIMINARY_MANUAL_REVIEW_CONFIRMED'

            WHEN ri.preliminary_decision_outcome = 'APPROVE'
                THEN 'PRELIMINARY_APPROVE_CONFIRMED'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBILITY_CONFIRMED'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'DECLINE'
                THEN 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'

            ELSE 'FINAL_RESIDUAL_FALLBACK'
        END AS decision_resolution_source

    FROM resolution_inputs ri
),

decision_flags AS (
    /***********************************************************************************************
    CTE: decision_flags

    Purpose:
        Convert final decision_outcome into final Boolean outcome flags.

    Business interpretation:
        These are the final decision flags used by latest-run output, QA, archive persistence,
        comparison, frontier, and evidence capture.

    Boundary:
        These flags are final simulated outcome flags.

        They are not operational decision actions.
    ***********************************************************************************************/
    SELECT
        dc.*,

        /*******************************************************************************************
        Final decision flags.

        Exactly one of these should be TRUE per row:
            approval_flag
            counteroffer_flag
            manual_review_flag
            decline_flag

        Section 9.3 validates this reconciliation.
        *******************************************************************************************/
        (dc.decision_outcome = 'APPROVE') AS approval_flag,
        (dc.decision_outcome = 'COUNTEROFFER') AS counteroffer_flag,
        (dc.decision_outcome = 'MANUAL_REVIEW') AS manual_review_flag,
        (dc.decision_outcome = 'DECLINE') AS decline_flag,


        /*******************************************************************************************
        simulated_offer_exposure_flag.

        TRUE only for:
            APPROVE
            COUNTEROFFER

        FALSE for:
            MANUAL_REVIEW
            DECLINE

        This means simulated positive offer exposure only.

        It does not imply:
            operational account creation,
            booked exposure,
            funded exposure,
            production approval,
            customer treatment,
            or real applicant treatment.
        *******************************************************************************************/
        (dc.decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
            AS simulated_offer_exposure_flag

    FROM decision_core dc
),

final_exposure_fields AS (
    /***********************************************************************************************
    CTE: final_exposure_fields

    Purpose:
        Apply final approved-exposure, affordability, and approved Expected Loss conventions.

    Business interpretation:
        This is where final decision_outcome becomes final output economics.

    Boundary:
        These are final simulated Module 2 strategy fields.

        They are not production booking, servicing, or profitability fields.
    ***********************************************************************************************/
    SELECT
        df.*,

        /*******************************************************************************************
        Final approved_amount.

        APPROVE:
            approved_amount = requested_amount.

        COUNTEROFFER:
            approved_amount = feasible reduced exposure from Section 8.

        MANUAL_REVIEW:
            approved_amount = NULL because the simulated review outcome is unresolved.

        DECLINE:
            approved_amount = 0 by locked zero-exposure convention.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN df.requested_amount

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.approved_amount_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_amount,


        /*******************************************************************************************
        Final counteroffer_amount.

        Populated only for final COUNTEROFFER rows.

        For final COUNTEROFFER rows:
            counteroffer_amount = approved_amount

        For all other rows:
            counteroffer_amount = NULL
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.counteroffer_amount_preliminary
            ELSE NULL::NUMERIC
        END AS counteroffer_amount,


        /*******************************************************************************************
        Final exposure_reduction_flag.

        TRUE only for final COUNTEROFFER rows.

        DECLINE rows have zero exposure by convention, but they are not reduced-exposure positive
        offer outcomes. Therefore exposure_reduction_flag remains FALSE for DECLINE.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN TRUE
            ELSE FALSE
        END AS exposure_reduction_flag,


        /*******************************************************************************************
        Final exposure_reduction_amount.

        APPROVE:
            zero reduction.

        COUNTEROFFER:
            requested_amount - approved_amount.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            requested_amount because final approved exposure is zero.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.exposure_reduction_amount_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN df.requested_amount

            ELSE NULL::NUMERIC
        END AS exposure_reduction_amount,


        /*******************************************************************************************
        Final exposure_reduction_pct.

        APPROVE:
            zero.

        COUNTEROFFER:
            percentage reduction from requested amount to approved amount.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            one, reflecting zero final approved exposure convention.

        SQL note:
            Section 8 already calculates counteroffer reduction percent for feasible counteroffers.

            Section 9 carries that value forward for final COUNTEROFFER rows.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.exposure_reduction_pct_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN 1.0::NUMERIC

            ELSE NULL::NUMERIC
        END AS exposure_reduction_pct,


        /*******************************************************************************************
        Final approved_monthly_payment_proxy.

        APPROVE:
            requested_monthly_payment_proxy.

        COUNTEROFFER:
            approved_monthly_payment_proxy_preliminary from feasible exposure treatment.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            zero by zero-exposure convention.

        This remains a strategy-simulation proxy, not a contractual payment schedule.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN df.requested_monthly_payment_proxy

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.approved_monthly_payment_proxy_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_monthly_payment_proxy,


        /*******************************************************************************************
        Final approved_payment_to_income_ratio.

        approved_payment_to_income_ratio is the preferred Module 2 output field name for final
        approved-exposure affordability proxy.

        It is distinct from:
            requested_payment_to_income_ratio

        APPROVE:
            requested PTI is preserved.

        COUNTEROFFER:
            approved PTI comes from feasible reduced-exposure treatment.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            zero by zero-exposure convention.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN df.requested_payment_to_income_ratio

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.approved_payment_to_income_ratio_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_payment_to_income_ratio,


        /*******************************************************************************************
        Final approved_expected_loss_amount.

        APPROVE:
            requested_expected_loss_amount.

        COUNTEROFFER:
            approved_expected_loss_amount_preliminary from feasible reduced exposure.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            zero by zero-exposure convention.

        approved_expected_loss_amount uses approved exposure, not requested exposure.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN df.requested_expected_loss_amount

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.approved_expected_loss_amount_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_expected_loss_amount,


        /*******************************************************************************************
        Final approved_el_reduction_amount.

        APPROVE:
            zero.

        COUNTEROFFER:
            requested_expected_loss_amount - approved_expected_loss_amount.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            requested_expected_loss_amount because final approved Expected Loss is zero.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.approved_el_reduction_amount_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN df.requested_expected_loss_amount

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_amount,


        /*******************************************************************************************
        Final approved_el_reduction_pct.

        APPROVE:
            zero.

        COUNTEROFFER:
            Section 8 preliminary approved EL reduction percent carried forward.

        MANUAL_REVIEW:
            NULL because unresolved.

        DECLINE:
            1.0 when requested_expected_loss_amount > 0.
            0.0 when requested_expected_loss_amount = 0.

        This avoids undefined percentage treatment when requested-exposure Expected Loss is zero.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.approved_el_reduction_pct_preliminary

            WHEN df.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN df.decision_outcome = 'DECLINE'
                THEN CASE
                    WHEN df.requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_pct

    FROM decision_flags df
)

SELECT *
FROM final_exposure_fields;



/***************************************************************************************************
SECTION 9.3 — LOCAL FAIL-FAST CHECKS FOR FINAL DECISION RESOLUTION
****************************************************************************************************

PURPOSE:
    Validate final decision and exposure conventions before simulated reason-code assignment.

BUSINESS PURPOSE:
    Confirm that final simulated outcomes, final flags, final approved exposure, final approved
    affordability, final approved Expected Loss, and failed-counteroffer resolution are internally
    consistent before Section 10 assigns simulated explanation codes.

SQL PURPOSE:
    1. Confirm row count is preserved from Section 8 to Section 9.
    2. Confirm application_id remains unique.
    3. Confirm final decision fields are complete and valid.
    4. Confirm exactly one final decision flag is TRUE per row.
    5. Confirm final decision flags reconcile to decision_outcome.
    6. Confirm simulated_offer_exposure_flag reconciles to APPROVE / COUNTEROFFER.
    7. Confirm APPROVE rows preserve requested exposure and requested economics.
    8. Confirm COUNTEROFFER rows have feasible reduced exposure.
    9. Confirm MANUAL_REVIEW rows remain unresolved.
    10. Confirm DECLINE rows follow the zero-exposure convention.
    11. Confirm failed preliminary COUNTEROFFER rows resolve according to failed_counteroffer_resolution.
    12. Confirm simulated reason-code fields do not exist yet.
    13. Confirm the permanent latest-run output table has not been created before Section 11.

LOCAL GATEKEEPER BOUNDARY:
    These are local Section 9 staging gatekeepers only.

    They are not:
        simulated reason-code validation,
        latest-run output validation,
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
    v_stage5_count BIGINT;
    v_stage6_count BIGINT;
    v_stage6_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    /***********************************************************************************************
    Final decision and flag diagnostics.
    ***********************************************************************************************/
    v_decision_completeness_failure_count BIGINT;
    v_flag_reconciliation_failure_count BIGINT;
    v_offer_flag_failure_count BIGINT;

    /***********************************************************************************************
    Final output convention diagnostics.
    ***********************************************************************************************/
    v_approve_convention_failure_count BIGINT;
    v_counteroffer_convention_failure_count BIGINT;
    v_manual_review_convention_failure_count BIGINT;
    v_decline_convention_failure_count BIGINT;

    /***********************************************************************************************
    Failed-counteroffer resolution diagnostic.
    ***********************************************************************************************/
    v_failed_counteroffer_resolution_failure_count BIGINT;

    /***********************************************************************************************
    Section boundary diagnostics.
    ***********************************************************************************************/
    v_forbidden_reason_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 8 to Section 9.

    Business purpose:
        Section 9 should add final decision-resolution fields only.

        It should not filter applicants or duplicate applicants.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage5_count
    FROM tmp_m2_stage_5_exposure_treatment;

    SELECT COUNT(*)
    INTO v_stage6_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_count <> v_stage5_count THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: row count changed from Section 8 to Section 9. Stage 5 rows: %, Stage 6 rows: %.',
            v_stage5_count,
            v_stage6_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.

    Business purpose:
        Duplicate application_id values would duplicate simulated reason codes, latest-run output
        rows, archive rows, QA counts, comparison results, and evidence capture.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage6_distinct_app_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_distinct_app_count <> v_stage6_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_6_final_decision_resolution
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 9 failure: application_id uniqueness was not preserved. Stage 6 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage6_count,
            v_stage6_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final decision fields must be complete and valid.

    Expected:
        decision_outcome is one of:
            APPROVE,
            COUNTEROFFER,
            MANUAL_REVIEW,
            DECLINE.

        decision_path, decision_priority_rank, and decision_resolution_source are populated.

        failed_counteroffer_resolution is attached and valid.

    Boundary:
        These are internal simulated strategy labels, not customer communications.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decision_completeness_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_priority_rank IS NULL
       OR decision_priority_rank <= 0
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL
       OR failed_counteroffer_resolution IS NULL
       OR failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE');

    IF v_decision_completeness_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % row(s) have null or invalid final decision fields.',
            v_decision_completeness_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one final decision flag must be TRUE and all flags must reconcile to
    decision_outcome.

    Expected:
        approval_flag TRUE only for APPROVE.
        counteroffer_flag TRUE only for COUNTEROFFER.
        manual_review_flag TRUE only for MANUAL_REVIEW.
        decline_flag TRUE only for DECLINE.

    SQL mechanics:
        Boolean flags are cast to INT and summed.
        Exactly one TRUE flag should produce a sum of 1.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_flag_reconciliation_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
          ) <> 1
       OR approval_flag IS DISTINCT FROM (decision_outcome = 'APPROVE')
       OR counteroffer_flag IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
       OR manual_review_flag IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
       OR decline_flag IS DISTINCT FROM (decision_outcome = 'DECLINE');

    IF v_flag_reconciliation_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % row(s) have final decision flag reconciliation failures.',
            v_flag_reconciliation_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated_offer_exposure_flag must reconcile to decision_outcome.

    Expected:
        TRUE for APPROVE and COUNTEROFFER.

        FALSE for MANUAL_REVIEW and DECLINE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_offer_flag_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE simulated_offer_exposure_flag
          IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'));

    IF v_offer_flag_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % row(s) have simulated_offer_exposure_flag reconciliation failures.',
            v_offer_flag_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: APPROVE final convention.

    Business interpretation:
        APPROVE preserves requested exposure and requested-exposure economics.

    Expected:
        approved_amount = requested_amount.
        counteroffer_amount is NULL.
        exposure reduction is zero.
        approved payment equals requested payment.
        approved PTI equals requested PTI.
        approved Expected Loss equals requested Expected Loss.
        simulated_offer_exposure_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approve_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'APPROVE'
      AND (
            approved_amount IS DISTINCT FROM requested_amount
         OR counteroffer_amount IS NOT NULL
         OR exposure_reduction_flag IS DISTINCT FROM FALSE
         OR exposure_reduction_amount IS DISTINCT FROM 0::NUMERIC
         OR exposure_reduction_pct IS DISTINCT FROM 0::NUMERIC
         OR approved_monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
         OR approved_payment_to_income_ratio IS DISTINCT FROM requested_payment_to_income_ratio
         OR approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_amount IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_pct IS DISTINCT FROM 0::NUMERIC
         OR simulated_offer_exposure_flag IS DISTINCT FROM TRUE
      );

    IF v_approve_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final APPROVE row(s) violate final exposure / economics conventions.',
            v_approve_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: COUNTEROFFER final convention.

    Business interpretation:
        COUNTEROFFER must have passed feasibility and must have positive approved exposure below the
        requested amount.

    Expected:
        counteroffer_feasibility_pass_flag = TRUE.
        approved_amount > 0.
        approved_amount < requested_amount.
        counteroffer_amount = approved_amount.
        exposure reduction is positive.
        approved PTI is at or below counteroffer target.
        approved Expected Loss is at or below product approved EL cap.
        simulated_offer_exposure_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
         OR approved_amount IS NULL
         OR approved_amount <= 0
         OR approved_amount >= requested_amount
         OR counteroffer_amount IS DISTINCT FROM approved_amount
         OR exposure_reduction_flag IS DISTINCT FROM TRUE
         OR exposure_reduction_amount IS DISTINCT FROM (requested_amount - approved_amount)
         OR exposure_reduction_pct IS DISTINCT FROM (
                exposure_reduction_amount / NULLIF(requested_amount, 0)
            )
         OR approved_monthly_payment_proxy IS NULL
         OR approved_payment_to_income_ratio IS NULL
         OR approved_expected_loss_amount IS NULL
         OR approved_expected_loss_amount > product_approved_el_cap
         OR approved_payment_to_income_ratio > counteroffer_target_pti
         OR simulated_offer_exposure_flag IS DISTINCT FROM TRUE
      );

    IF v_counteroffer_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final COUNTEROFFER row(s) violate final exposure / economics conventions.',
            v_counteroffer_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: MANUAL_REVIEW final convention.

    Business interpretation:
        Manual review remains unresolved by design.

    Expected:
        approved exposure fields are NULL.
        approved affordability fields are NULL.
        approved Expected Loss fields are NULL.
        simulated_offer_exposure_flag = FALSE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            approved_amount IS NOT NULL
         OR counteroffer_amount IS NOT NULL
         OR exposure_reduction_flag IS DISTINCT FROM FALSE
         OR exposure_reduction_amount IS NOT NULL
         OR exposure_reduction_pct IS NOT NULL
         OR approved_monthly_payment_proxy IS NOT NULL
         OR approved_payment_to_income_ratio IS NOT NULL
         OR approved_expected_loss_amount IS NOT NULL
         OR approved_el_reduction_amount IS NOT NULL
         OR approved_el_reduction_pct IS NOT NULL
         OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
      );

    IF v_manual_review_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final MANUAL_REVIEW row(s) violate unresolved-review conventions.',
            v_manual_review_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DECLINE final convention.

    Business interpretation:
        DECLINE follows the zero-exposure convention.

    Expected:
        approved_amount = 0.
        approved payment = 0.
        approved PTI = 0.
        approved Expected Loss = 0.
        exposure reduction amount = requested_amount.
        exposure reduction percent = 1.0.
        simulated_offer_exposure_flag = FALSE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decline_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'DECLINE'
      AND (
            approved_amount IS DISTINCT FROM 0::NUMERIC
         OR counteroffer_amount IS NOT NULL
         OR exposure_reduction_flag IS DISTINCT FROM FALSE
         OR exposure_reduction_amount IS DISTINCT FROM requested_amount
         OR exposure_reduction_pct IS DISTINCT FROM 1.0::NUMERIC
         OR approved_monthly_payment_proxy IS DISTINCT FROM 0::NUMERIC
         OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
         OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_amount IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_pct IS DISTINCT FROM CASE
                WHEN requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                ELSE 0::NUMERIC
            END
         OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
      );

    IF v_decline_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final DECLINE row(s) violate zero-exposure conventions.',
            v_decline_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: failed counteroffer resolution must follow governed parameter.

    For preliminary COUNTEROFFER rows where counteroffer feasibility failed:

        failed_counteroffer_resolution = MANUAL_REVIEW
            must resolve to MANUAL_REVIEW.

        failed_counteroffer_resolution = DECLINE
            must resolve to DECLINE.

    This check ensures the active strategy parameter, not hidden downstream logic, controls failed
    counteroffer final resolution.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_failed_counteroffer_resolution_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND (
            (
                failed_counteroffer_resolution = 'MANUAL_REVIEW'
                AND NOT (
                    decision_outcome = 'MANUAL_REVIEW'
                    AND decision_path = 'COUNTEROFFER_NOT_FEASIBLE_REVIEW'
                    AND decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'
                )
            )
         OR (
                failed_counteroffer_resolution = 'DECLINE'
                AND NOT (
                    decision_outcome = 'DECLINE'
                    AND decision_path = 'COUNTEROFFER_NOT_FEASIBLE_DECLINE'
                    AND decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'
                )
            )
      );

    IF v_failed_counteroffer_resolution_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % failed preliminary COUNTEROFFER row(s) violate failed_counteroffer_resolution conventions.',
            v_failed_counteroffer_resolution_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 9 must not create simulated reason-code fields yet.

    Business purpose:
        Simulated reason codes are assigned in Section 10, after final decision_outcome and final
        exposure fields exist.

    SQL mechanics:
        pg_attribute inspects the physical columns of the temporary table.

        If any reason-code field exists, Section 9 has crossed its boundary.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_reason_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_6_final_decision_resolution'::REGCLASS
      AND attnum > 0
      AND NOT attisdropped
      AND attname IN (
            'primary_reason_code',
            'secondary_reason_code',
            'tertiary_reason_code',
            'triggered_reason_code_list',
            'reason_priority_rank',
            'primary_reason_family',
            'reason_code_count'
      );

    IF v_forbidden_reason_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: simulated reason-code field(s) were created before Section 10.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must not exist yet.

    Business purpose:
        Section 11 creates credit_decisioning_sim.strategy_decisions.

        Section 9 creates only temporary final-resolution staging output.

    Operating note:
        In a clean full script execution, Section 1 drops the replaceable latest-run output table
        before stages are rebuilt.

        If this gatekeeper fails, it usually means a user is running Section 9 after a prior latest-run
        output still exists. For a full rerun, start from Section 1 or drop / rebuild latest-run output
        through the intended Section 11 flow.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: final latest-run strategy_decisions table exists before Section 11.';
    END IF;

    /*
    Archive note:
        Section 9 contains no archive insert logic.
        Archive persistence remains deferred to Section 12.
    */
END $$;



/***************************************************************************************************
SECTION 9.4 — LOCAL FINAL DECISION RESOLUTION SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for final decision resolution.

BUSINESS PURPOSE:
    Let reviewers inspect how preliminary routing and exposure-treatment feasibility resolved into
    final simulated outcomes before simulated reason codes are assigned.

SQL PURPOSE:
    Display review outputs for:
        final decision outcome distribution,
        final decision path distribution,
        final decision resolution source distribution,
        simulated offer-exposure flag distribution,
        preliminary outcome × final outcome,
        exposure-treatment status × final outcome,
        counteroffer feasibility × final outcome,
        counteroffer failure reason × final outcome,
        product × final outcome,
        score band × final outcome,
        synthetic risk tier × final outcome,
        requested PTI bucket × final outcome,
        requested exposure tier × final outcome,
        requested Expected Loss tier × final outcome,
        mixed-signal profile × final outcome,
        borderline profile × final outcome,
        requested amount by final outcome,
        approved amount by final outcome,
        requested versus approved PTI by final outcome,
        requested versus approved Expected Loss by final outcome.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        full Module 2 QA,
        reason-code validation,
        latest-run output validation,
        archive validation,
        matched strategy comparison,
        strategy frontier evidence,
        or Validation Summary acceptance.

SQL TEACHING POINT:
    These SELECT statements are read-only diagnostics.

    GROUP BY summarizes final outcome behavior.

    AVG fields help reviewers understand whether final outcomes are directionally coherent with
    requested exposure, approved exposure, affordability, synthetic estimated-risk profile, and
    Expected Loss.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
9.4.1 Count by decision_outcome.

Purpose:
    Show final simulated outcome distribution before reason-code assignment.

Expected:
    every row has one of APPROVE, COUNTEROFFER, MANUAL_REVIEW, DECLINE.

Boundary:
    This is staging output. The permanent latest-run table is created in Section 11.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_stage
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.2 Count by decision_path.

Purpose:
    Show internal final decision path distribution.

Interpretation:
    decision_path is an internal simulated strategy path label.

    It is not:
        a simulated reason code,
        customer communication language,
        regulatory notice language,
        or production compliance language.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_path
ORDER BY decision_path;



/*-----------------------------------------------------------------------------------------------
9.4.3 Count by decision_resolution_source.

Purpose:
    Show how final outcomes were resolved.

Interpretation:
    This connects final outcome to one of the following resolution mechanisms:
        confirmed preliminary route,
        confirmed counteroffer feasibility,
        failed counteroffer-to-review,
        failed counteroffer-to-decline,
        or residual fallback.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_resolution_source,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_resolution_source
ORDER BY decision_resolution_source;



/*-----------------------------------------------------------------------------------------------
9.4.4 Count by simulated_offer_exposure_flag.

Purpose:
    Confirm positive simulated offer-exposure convention.

Expected:
    TRUE for APPROVE and COUNTEROFFER.
    FALSE for MANUAL_REVIEW and DECLINE.

Boundary:
    Simulated offer exposure does not imply booked or funded exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    simulated_offer_exposure_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY simulated_offer_exposure_flag
ORDER BY simulated_offer_exposure_flag;



/*-----------------------------------------------------------------------------------------------
9.4.5 Preliminary decision outcome × final decision outcome.

Purpose:
    Show how preliminary routing resolved after Section 8 exposure-treatment feasibility.

Interpretation:
    This query is especially useful for understanding failed preliminary counteroffers.

    Preliminary COUNTEROFFER rows may resolve to:
        COUNTEROFFER,
        MANUAL_REVIEW,
        or DECLINE

    depending on feasibility and failed_counteroffer_resolution.
-----------------------------------------------------------------------------------------------*/

SELECT
    preliminary_decision_outcome,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    preliminary_decision_outcome,
    decision_outcome
ORDER BY
    CASE preliminary_decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
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
9.4.6 Exposure treatment status × final decision outcome.

Purpose:
    Connect Section 8 exposure-treatment status to Section 9 final outcome.

Interpretation:
    This shows whether:
        approved-as-requested rows became final APPROVE,
        feasible preliminary counteroffers became final COUNTEROFFER,
        failed preliminary counteroffers resolved according to strategy parameter,
        unresolved review remained manual review,
        preliminary no-offer rows became final DECLINE.
-----------------------------------------------------------------------------------------------*/

SELECT
    exposure_treatment_status,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    exposure_treatment_status,
    decision_outcome
ORDER BY
    exposure_treatment_status,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.7 Counteroffer feasibility pass flag × final decision outcome.

Purpose:
    Show how counteroffer feasibility status resolved into final outcomes.

Interpretation:
    TRUE / FALSE values apply only to preliminary COUNTEROFFER rows.

    NULL applies to non-counteroffer preliminary routes.

Boundary:
    Feasibility pass is not itself a reason code.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_pass_flag,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    counteroffer_feasibility_pass_flag,
    decision_outcome
ORDER BY
    counteroffer_feasibility_pass_flag,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.8 Counteroffer feasibility failure reason × final decision outcome.

Purpose:
    Show how failed-counteroffer feasibility diagnostics resolved into final outcome.

Interpretation:
    Failure reasons are exposure-feasibility diagnostics, not simulated reason codes.

    Section 10 assigns simulated reason codes after final decision outcome exists.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    counteroffer_feasibility_failure_reason,
    decision_outcome
ORDER BY
    counteroffer_feasibility_failure_reason,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.9 Product × decision_outcome.

Purpose:
    Show final simulated strategy outcomes by product before reason-code assignment.

Credit risk interpretation:
    Product type affects requested amount, payment mechanics, LGD, affordability pressure,
    counteroffer feasibility, and approved Expected Loss.

Boundary:
    This is final outcome staging, not the permanent latest-run output.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.10 Score band × decision_outcome.

Purpose:
    Show final simulated outcomes by score-band policy key.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

    Score band and estimated_pd should generally align directionally while preserving realistic
    overlap.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.11 Strategy risk tier × decision_outcome.

Purpose:
    Show how synthetic estimated-risk tier flows into final simulated strategy outcomes.

Interpretation:
    Higher synthetic estimated-risk tiers should generally show more no-offer or unresolved pressure,
    subject to product, affordability, exposure, and policy-stop interactions.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.12 Requested PTI bucket × decision_outcome.

Purpose:
    Show how requested affordability pressure resolved into final simulated outcomes.

Interpretation:
    requested_pti_bucket uses requested-structure PTI, not approved PTI.

    The approved_payment_to_income_ratio average shows the final approved-exposure affordability
    proxy where final outcomes populate approved PTI.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.13 Requested exposure tier × decision_outcome.

Purpose:
    Show how requested exposure pressure resolved into final simulated outcomes.

Interpretation:
    requested_exposure_tier describes requested exposure pressure before final outcome assignment.

    approved_amount is the final exposure field after Section 9 resolution.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_exposure_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    requested_exposure_tier,
    decision_outcome
ORDER BY
    requested_exposure_tier,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.14 Requested Expected Loss tier × decision_outcome.

Purpose:
    Show how requested-exposure Expected Loss pressure resolved into final simulated outcomes.

Interpretation:
    requested_expected_loss_tier uses requested-exposure Expected Loss.

    approved_expected_loss_amount is final approved-exposure Expected Loss after Section 9 final
    exposure convention.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_expected_loss_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    requested_expected_loss_tier,
    decision_outcome
ORDER BY
    requested_expected_loss_tier,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.15 Mixed-signal profile × decision_outcome.

Purpose:
    Show how mixed-signal diagnostic profiles resolved into final simulated strategy outcomes.

Interpretation:
    mixed_signal_profile_type is diagnostic only.

    It does not automatically determine final approval, counteroffer, manual review, or decline.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    mixed_signal_profile_type,
    decision_outcome
ORDER BY
    mixed_signal_profile_type,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.16 Borderline profile flag × decision_outcome.

Purpose:
    Show how threshold-adjacent profiles resolved into final simulated outcomes.

Interpretation:
    borderline_profile_flag is diagnostic only.

    It is not automatic final manual review.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    borderline_profile_flag,
    decision_outcome
ORDER BY
    borderline_profile_flag,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
9.4.17 Average requested_amount by decision_outcome.

Purpose:
    Show requested exposure profile by final simulated outcome.

Interpretation:
    requested_amount is the original requested exposure from Module 1.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.18 Average approved_amount by decision_outcome.

Purpose:
    Show final approved exposure profile by final simulated outcome.

Interpretation:
    approved_amount is final approved exposure after Section 9 final outcome resolution.

    Manual-review rows remain NULL.
    Decline rows use zero exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(approved_amount) AS avg_approved_amount
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.19 Average requested PTI and approved PTI by decision_outcome.

Purpose:
    Compare requested affordability pressure to final approved affordability proxy.

Interpretation:
    requested_payment_to_income_ratio is the original requested-structure PTI.

    approved_payment_to_income_ratio is the final approved-exposure affordability proxy.

    For manual review, approved PTI is NULL.
    For decline, approved PTI is zero by zero-exposure convention.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.20 Average requested Expected Loss and approved Expected Loss by decision_outcome.

Purpose:
    Compare requested-exposure Expected Loss to final approved-exposure Expected Loss.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is final approved-exposure Expected Loss.

    For manual review, approved Expected Loss is NULL.
    For decline, approved Expected Loss is zero by zero-exposure convention.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
END OF SECTION 9 — FINAL DECISION RESOLUTION LAYER

If execution reaches this point:
    1. Section 9 dependency preflight passed.
    2. tmp_m2_stage_6_final_decision_resolution exists.
    3. Row count is unchanged from tmp_m2_stage_5_exposure_treatment.
    4. application_id remains unique.
    5. final decision_outcome is populated.
    6. decision_outcome is one of APPROVE, COUNTEROFFER, MANUAL_REVIEW, DECLINE.
    7. decision_path is populated.
    8. decision_priority_rank is populated.
    9. decision_resolution_source is populated.
    10. approval_flag, counteroffer_flag, manual_review_flag, and decline_flag reconcile to
        decision_outcome.
    11. exactly one final decision flag is TRUE per row.
    12. simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.
    13. simulated_offer_exposure_flag is FALSE for MANUAL_REVIEW and DECLINE.
    14. final approved exposure fields are populated by locked outcome convention.
    15. final approved affordability fields are populated by locked outcome convention.
    16. final approved Expected Loss fields are populated by locked outcome convention.
    17. final APPROVE rows preserve requested exposure.
    18. final COUNTEROFFER rows reflect feasible reduced exposure.
    19. final MANUAL_REVIEW rows remain unresolved.
    20. final DECLINE rows follow zero-exposure convention.
    21. failed_counteroffer_resolution has been applied to infeasible preliminary COUNTEROFFER rows.
    22. estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy.
    23. requested_expected_loss_amount remains requested-exposure Expected Loss.
    24. approved_expected_loss_amount is now final approved-exposure Expected Loss.
    25. Section 9 local final decision-resolution diagnostics are available for review.

No simulated reason codes have been assigned.
No latest-run strategy_decisions table has been created.
No strategy archive rows have been inserted.
No evidence rows have been inserted.
No matched strategy comparison has been performed.
No strategy frontier has been calculated.
No full Module 2 QA framework has been built.

Next section:
    Section 10 should consume tmp_m2_stage_6_final_decision_resolution and assign deterministic
    simulated strategy explanation codes using final decision outcome, final decision path, rule
    triggers, preliminary routing diagnostics, exposure-treatment diagnostics, and counteroffer
    feasibility diagnostics.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00936 -->


---

<a id="c038-m00937"></a>

### C038-M00937

**Andrew** · 2026-05-10T00:13:11.562000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00937 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 10 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00937 -->


**Attachments in export:** `Pasted text(148).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_45.md) · [Next](Part_47.md)
