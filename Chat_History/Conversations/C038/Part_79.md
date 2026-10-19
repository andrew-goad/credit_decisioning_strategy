# Module 2 Decision Simulator Build

## Part 79

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_78.md) · [Next](Part_80.md)

<a id="c038-m01561"></a>

### C038-M01561

**ChatGPT** · 2026-05-12T10:45:49.099352-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01561 -->
According to the current 2026-05-12 SQL capture, Section 9 is the final decision-resolution layer that consumes `tmp_m2_stage_5_exposure_treatment` and produces `tmp_m2_stage_6_final_decision_resolution`; Section 10 then consumes that stage for simulated reason-code assignment. fileciteturn238file13 fileciteturn237file25

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

INPUT:
    tmp_m2_stage_5_exposure_treatment

OUTPUT:
    tmp_m2_stage_6_final_decision_resolution

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

FINAL DECISION TAXONOMY:
    Section 9 creates exactly four allowed final decision_outcome values:

        APPROVE
        COUNTEROFFER
        MANUAL_REVIEW
        DECLINE

FINAL RESOLUTION HIERARCHY:
    1. Preliminary APPROVE resolves to final APPROVE.
    2. Preliminary COUNTEROFFER with passed feasibility resolves to final COUNTEROFFER.
    3. Preliminary COUNTEROFFER with failed feasibility resolves using failed_counteroffer_resolution:
            MANUAL_REVIEW
            or
            DECLINE
    4. Preliminary MANUAL_REVIEW resolves to final MANUAL_REVIEW.
    5. Preliminary DECLINE resolves to final DECLINE.
    6. Any unexpected residual path resolves conservatively to final MANUAL_REVIEW.

WHY FINAL DECISION RESOLUTION IS SEPARATED FROM PRELIMINARY ROUTING:
    Section 7 creates preliminary routes before approved exposure exists.

    Section 8 evaluates approved exposure treatment and counteroffer feasibility.

    Section 9 resolves final simulated outcomes using both prior layers.

    This separation protects interpretability:
        preliminary routing explains where the row was sent;
        exposure treatment explains what exposure was feasible;
        final decision resolution explains what simulated strategy outcome remains after feasibility.

WHY SECTION 8 EXPOSURE FEASIBILITY IS REQUIRED BEFORE FINAL COUNTEROFFER RESOLUTION:
    A preliminary COUNTEROFFER route is not final.

    It must pass reduced-exposure feasibility tests before becoming a final COUNTEROFFER outcome.

    Feasibility tests include:
        product maximum approved amount,
        product minimum approved amount,
        minimum counteroffer percent,
        maximum exposure-reduction limit,
        approved PTI target,
        approved Expected Loss cap,
        and rounding convention.

WHY FAILED COUNTEROFFERS USE A GOVERNED RESOLUTION PARAMETER:
    Infeasible counteroffers can resolve to:

        MANUAL_REVIEW
        or
        DECLINE

    The active strategy controls this through:

        failed_counteroffer_resolution

    Default posture:
        MANUAL_REVIEW

    Strategic interpretation:
        MANUAL_REVIEW preserves unresolved failed-counteroffer cases for interpretation.
        DECLINE tests operational review-burden reduction by converting failed counteroffers to
        final no-offer outcomes.

    This is a simulated strategy-control parameter, not production underwriting policy.

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

APPROVE BOUNDARY:
    APPROVE is a simulated positive offer-exposure outcome.

    APPROVE rows preserve requested exposure and requested-exposure economics:
        approved_amount = requested_amount
        approved_monthly_payment_proxy = requested_monthly_payment_proxy
        approved_payment_to_income_ratio = requested_payment_to_income_ratio
        approved_expected_loss_amount = requested_expected_loss_amount

COUNTEROFFER BOUNDARY:
    COUNTEROFFER is a simulated positive offer-exposure outcome with reduced approved exposure.

    COUNTEROFFER rows should show:
        approved_amount > 0
        approved_amount < requested_amount
        counteroffer_amount = approved_amount
        approved_payment_to_income_ratio <= counteroffer_target_pti
        approved_expected_loss_amount <= product_approved_el_cap
        counteroffer_feasibility_pass_flag = TRUE

    COUNTEROFFER does not imply:
        operational negotiation,
        customer acceptance,
        booked exposure,
        funded exposure,
        production approval,
        account creation,
        or real applicant treatment.

MANUAL_REVIEW BOUNDARY:
    MANUAL_REVIEW remains unresolved by design.

    Manual-review rows retain:
        approved_amount = NULL
        counteroffer_amount = NULL
        approved_monthly_payment_proxy = NULL
        approved_payment_to_income_ratio = NULL
        approved_expected_loss_amount = NULL

DECLINE BOUNDARY:
    DECLINE follows the locked zero-exposure convention.

    Decline rows receive:
        approved_amount = 0
        counteroffer_amount = NULL
        approved_monthly_payment_proxy = 0
        approved_payment_to_income_ratio = 0
        approved_expected_loss_amount = 0

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag means the simulated strategy output includes positive offer exposure
    for the synthetic applicant.

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
    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is approved-exposure Expected Loss from Module 2 after final
    simulated exposure treatment.

    Section 9 finalizes approved Expected Loss convention, but it does not recalculate estimated_pd.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field and is interpreted as the synthetic
    estimated-PD proxy.

    Module 2 does not recalculate estimated_pd.

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
    CTE chain:
        active_strategy_params
            selects the final-resolution strategy control.

        resolution_inputs
            attaches the governed failed_counteroffer_resolution value.

        decision_core
            converts preliminary route + feasibility into final outcome labels.

        decision_flags
            creates reconciled Boolean outcome flags.

        final_exposure_assignment
            applies final exposure, affordability, and Expected Loss conventions.

    CASE hierarchy:
        Encodes final simulated outcome resolution.

    CROSS JOIN:
        Attaches one active strategy parameter row to every exposure-treatment row.

    IS DISTINCT FROM:
        Used in gatekeepers to compare NULL safely.

    pg_attribute:
        Confirms simulated reason-code fields and latest-run materialization did not appear early.

GOVERNANCE ROLE:
    Section 9 locks the final simulated outcome taxonomy and final output conventions before
    explanation codes, latest-run materialization, archive persistence, comparison, QA, and evidence
    capture occur.

COMMON MISUSE TO AVOID:
    Do not interpret decision_outcome as a real applicant decision.
    Do not interpret decision_path as customer communication.
    Do not interpret simulated_offer_exposure_flag as booked or funded exposure.
    Do not interpret approved_expected_loss_amount as a production loss forecast.
    Do not interpret MANUAL_REVIEW as completed operational review.
    Do not infer reason-code explanations before Section 10.

***************************************************************************************************/



/***************************************************************************************************
SECTION 9.0 — SECTION 9 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 8 exposure-treatment output and the active failed-counteroffer strategy
    control are available before final decision resolution begins.

    Section 9.0 answers:

        "Can Section 9 safely convert Section 8 exposure treatment into final simulated outcomes?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_5_exposure_treatment exists.
    2. Confirm tmp_m2_stage_5_exposure_treatment contains rows.
    3. Confirm application_id is unique before final decision fields are added.
    4. Confirm tmp_module2_strategy_params exists.
    5. Confirm exactly one active strategy parameter row exists.
    6. Confirm failed_counteroffer_resolution is populated and valid.
    7. Confirm key Section 8 fields required for final resolution are populated.
    8. Fail clearly if Section 8 or Section 2 has not been run.

BOUNDARY:
    Section 9.0 does not create final decisions.
    Section 9.0 does not assign reason codes.
    Section 9.0 does not create latest-run output.
    Section 9.0 does not insert archive rows.
    Section 9.0 does not modify persistent tables.

***************************************************************************************************/

DO $$
DECLARE
    v_stage5_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;

    v_stage5_row_count BIGINT;
    v_stage5_distinct_application_count BIGINT;

    v_active_strategy_count BIGINT;
    v_bad_failed_counteroffer_resolution_count BIGINT;
    v_required_stage5_gap_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 8 exposure-treatment stage must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

    Business interpretation:
        Section 9 must consume the exposure-treatment layer, not preliminary routing directly.
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

    Business interpretation:
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
    Gatekeeper: Section 8 exposure-treatment stage must contain rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage5_row_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: tmp_m2_stage_5_exposure_treatment contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id must be unique before final outcome fields are added.

    Section 9 should add final decision-resolution fields only.

    It should not repair upstream row-grain problems.
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

    Business interpretation:
        Final resolution must use one and only one failed-counteroffer strategy control.
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
    Gatekeeper: failed_counteroffer_resolution must be valid.

    Allowed values:
        MANUAL_REVIEW
        DECLINE
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_bad_failed_counteroffer_resolution_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
      AND (
            failed_counteroffer_resolution IS NULL
         OR failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE')
      );

    IF v_bad_failed_counteroffer_resolution_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: active failed_counteroffer_resolution must be MANUAL_REVIEW or DECLINE.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: key Section 8 fields required for final resolution must be populated.

    Non-counteroffer rows are allowed to have NULL counteroffer-specific fields.

    Manual-review rows are expected to have unresolved preliminary exposure fields.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_stage5_gap_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome IS NULL
       OR preliminary_decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR preliminary_decision_path IS NULL
       OR preliminary_decision_priority_rank IS NULL
       OR preliminary_route_reason_family IS NULL
       OR preliminary_route_trigger_count IS NULL

       OR exposure_treatment_status IS NULL
       OR exposure_treatment_path IS NULL
       OR exposure_reduction_flag_preliminary IS NULL
       OR counteroffer_feasibility_evaluated_flag IS NULL

       OR requested_amount IS NULL
       OR requested_monthly_payment_proxy IS NULL
       OR requested_payment_to_income_ratio IS NULL
       OR requested_expected_loss_amount IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL

       OR (
            preliminary_decision_outcome = 'APPROVE'
            AND (
                approved_amount_preliminary IS NULL
             OR approved_monthly_payment_proxy_preliminary IS NULL
             OR approved_payment_to_income_ratio_preliminary IS NULL
             OR approved_expected_loss_amount_preliminary IS NULL
            )
       )

       OR (
            preliminary_decision_outcome = 'DECLINE'
            AND (
                approved_amount_preliminary IS NULL
             OR approved_monthly_payment_proxy_preliminary IS NULL
             OR approved_payment_to_income_ratio_preliminary IS NULL
             OR approved_expected_loss_amount_preliminary IS NULL
            )
       )

       OR (
            preliminary_decision_outcome = 'COUNTEROFFER'
            AND (
                counteroffer_feasibility_pass_flag IS NULL
             OR counteroffer_feasibility_constraint_count IS NULL
             OR (
                    counteroffer_feasibility_pass_flag IS TRUE
                AND (
                        approved_amount_preliminary IS NULL
                     OR counteroffer_amount_preliminary IS NULL
                     OR approved_monthly_payment_proxy_preliminary IS NULL
                     OR approved_payment_to_income_ratio_preliminary IS NULL
                     OR approved_expected_loss_amount_preliminary IS NULL
                   )
                )
             OR (
                    counteroffer_feasibility_pass_flag IS FALSE
                AND counteroffer_feasibility_failure_reason IS NULL
                )
            )
       );

    IF v_required_stage5_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % Section 8 row(s) are missing fields required for final decision resolution.',
            v_required_stage5_gap_count;
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
    A partial rerun should not allow stale final decision-resolution rows to remain available to
    Section 10.

    Section 10 assumes tmp_m2_stage_6_final_decision_resolution reflects the current:
        Section 8 exposure-treatment output,
        active failed-counteroffer resolution setting,
        and final outcome convention logic.

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

SQL DESIGN:
    This section uses a CTE chain so final outcome resolution is readable and auditable.

    The chain is:

        active_strategy_params
            selects failed_counteroffer_resolution from the active strategy card.

        resolution_inputs
            attaches the governed failed-counteroffer final-resolution parameter.

        decision_core
            resolves final outcome labels, paths, priorities, and resolution sources.

        decision_flags
            creates final outcome flags and simulated_offer_exposure_flag.

        final_exposure_assignment
            applies final approved exposure, affordability, and Expected Loss conventions.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 9 intentionally preserves all prior diagnostics plus final decision-resolution fields for
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
        Select the governed failed-counteroffer resolution strategy control.

    Business interpretation:
        This parameter decides how a preliminary COUNTEROFFER row resolves when Section 8 determines
        that no feasible reduced-exposure offer exists.

    Allowed values:
        MANUAL_REVIEW
        DECLINE
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
        Attach failed_counteroffer_resolution to every Section 8 row.

    SQL mechanics:
        CROSS JOIN is safe because Section 9.0 confirms exactly one active strategy parameter row.

    Boundary:
        No final outcome is assigned in this CTE.
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
        Resolve final decision labels from preliminary route + counteroffer feasibility.

    SQL mechanics:
        CASE evaluates top to bottom.

    Business interpretation:
        This is where final simulated decision_outcome becomes locked for the current row.

    Boundary:
        Reason codes are still not assigned here.
    ***********************************************************************************************/
    SELECT
        ri.*,

        /*******************************************************************************************
        Final decision_outcome.

        Allowed final values:
            APPROVE
            COUNTEROFFER
            MANUAL_REVIEW
            DECLINE
        *******************************************************************************************/
        CASE
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

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'DECLINE'
                THEN 'DECLINE'

            ELSE 'MANUAL_REVIEW'
        END AS decision_outcome,


        /*******************************************************************************************
        Final decision_path.

        decision_path is an internal simulated strategy path label.

        It is not:
            customer communication,
            regulatory notice language,
            adverse-action reason text,
            or production compliance language.
        *******************************************************************************************/
        CASE
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

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
             AND ri.preliminary_decision_path = 'SEVERE_REQUESTED_STRUCTURE_REVIEW'
                THEN 'SEVERE_REQUESTED_STRUCTURE_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
             AND ri.preliminary_decision_path = 'MANUAL_REVIEW_CANDIDATE'
                THEN 'MANUAL_REVIEW_CANDIDATE'

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
             AND ri.preliminary_decision_path = 'RESIDUAL_STRATEGY_REVIEW'
                THEN 'RESIDUAL_STRATEGY_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW_UNRESOLVED'

            WHEN ri.preliminary_decision_outcome = 'DECLINE'
             AND ri.preliminary_decision_path IN (
                    'HARD_POLICY_STOP',
                    'SEVERE_SYNTHETIC_RISK',
                    'SEVERE_DTI_CAPACITY'
                 )
                THEN ri.preliminary_decision_path

            WHEN ri.preliminary_decision_outcome = 'DECLINE'
                THEN 'PRELIMINARY_DECLINE_RESOLVED'

            ELSE 'RESIDUAL_FINAL_REVIEW'
        END AS decision_path,


        /*******************************************************************************************
        Final decision_priority_rank.

        Lower values represent more severe or higher-priority final resolution paths.

        This rank is an internal diagnostic.
        It is not a regulatory severity score.
        *******************************************************************************************/
        CASE
            WHEN ri.preliminary_decision_outcome = 'DECLINE'
             AND ri.preliminary_decision_path = 'HARD_POLICY_STOP'
                THEN 1

            WHEN ri.preliminary_decision_outcome = 'DECLINE'
             AND ri.preliminary_decision_path = 'SEVERE_SYNTHETIC_RISK'
                THEN 2

            WHEN ri.preliminary_decision_outcome = 'DECLINE'
             AND ri.preliminary_decision_path = 'SEVERE_DTI_CAPACITY'
                THEN 3

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS TRUE
                THEN 4

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'DECLINE'
                THEN 5

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 6

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 7

            WHEN ri.preliminary_decision_outcome = 'APPROVE'
                THEN 8

            ELSE 9
        END AS decision_priority_rank,


        /*******************************************************************************************
        decision_resolution_source.

        This describes which upstream layer / control resolved the final outcome.

        It helps Section 10 reason-code logic and Section 14 QA explain the final output.
        *******************************************************************************************/
        CASE
            WHEN ri.preliminary_decision_outcome = 'APPROVE'
                THEN 'PRELIMINARY_APPROVE_ROUTE'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBILITY_PASSED'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'

            WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ri.counteroffer_feasibility_pass_flag IS FALSE
             AND ri.failed_counteroffer_resolution = 'DECLINE'
                THEN 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'

            WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'PRELIMINARY_MANUAL_REVIEW_ROUTE'

            WHEN ri.preliminary_decision_outcome = 'DECLINE'
                THEN 'PRELIMINARY_DECLINE_ROUTE'

            ELSE 'FINAL_RESOLUTION_FALLBACK_TO_REVIEW'
        END AS decision_resolution_source

    FROM resolution_inputs ri
),

decision_flags AS (
    /***********************************************************************************************
    CTE: decision_flags

    Purpose:
        Convert final decision_outcome into final Boolean flags.

    SQL mechanics:
        Each flag is defined directly from decision_outcome.

        The Section 9.3 gatekeeper later confirms exactly one final decision flag is TRUE per row.

    Business interpretation:
        simulated_offer_exposure_flag is TRUE only for positive simulated offer-exposure outcomes:
            APPROVE
            COUNTEROFFER
    ***********************************************************************************************/
    SELECT
        dc.*,

        (dc.decision_outcome = 'APPROVE')
            AS approval_flag,

        (dc.decision_outcome = 'COUNTEROFFER')
            AS counteroffer_flag,

        (dc.decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_flag,

        (dc.decision_outcome = 'DECLINE')
            AS decline_flag,

        (dc.decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
            AS simulated_offer_exposure_flag

    FROM decision_core dc
),

final_exposure_assignment AS (
    /***********************************************************************************************
    CTE: final_exposure_assignment

    Purpose:
        Apply final approved exposure, affordability, and approved Expected Loss conventions.

    Business interpretation:
        APPROVE:
            preserve requested exposure and requested economics.

        COUNTEROFFER:
            use feasible reduced-exposure economics from Section 8.

        MANUAL_REVIEW:
            remain unresolved with NULL final approved exposure economics.

        DECLINE:
            use locked zero-exposure convention.

    Boundary:
        These are simulated strategy output fields.

        They are not booked balances, funded exposures, or operational account records.
    ***********************************************************************************************/
    SELECT
        df.*,

        /*******************************************************************************************
        Final approved_amount.

        APPROVE:
            requested amount.

        COUNTEROFFER:
            feasible reduced amount from Section 8.

        MANUAL_REVIEW:
            unresolved.

        DECLINE:
            zero exposure.
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

        Populated only for final COUNTEROFFER.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN df.counteroffer_amount_preliminary
            ELSE NULL::NUMERIC
        END AS counteroffer_amount,


        /*******************************************************************************************
        Final exposure_reduction_flag.

        TRUE only when a positive simulated offer exists with reduced exposure.

        DECLINE has 100% no-offer exposure reduction amount, but it is not a reduced positive offer.
        Therefore exposure_reduction_flag remains FALSE for DECLINE.
        *******************************************************************************************/
        CASE
            WHEN df.decision_outcome = 'COUNTEROFFER'
                THEN TRUE
            ELSE FALSE
        END AS exposure_reduction_flag,


        /*******************************************************************************************
        Final exposure_reduction_amount.
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

        Boundary:
            This remains a strategy-simulation payment proxy, not a contractual payment schedule.
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

        Boundary:
            This is the simulated approved-exposure affordability proxy.
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
            requested-exposure Expected Loss.

        COUNTEROFFER:
            reduced approved-exposure Expected Loss from Section 8.

        MANUAL_REVIEW:
            unresolved.

        DECLINE:
            zero approved exposure Expected Loss.
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
FROM final_exposure_assignment;



/***************************************************************************************************
SECTION 9.3 — LOCAL FAIL-FAST CHECKS FOR FINAL DECISION RESOLUTION
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 9 produced complete, internally consistent, final simulated strategy
    outcomes before Section 10 assigns simulated reason codes.

    Section 9.3 answers:

        "Did Section 9 preserve applicant grain, assign exactly one final outcome, apply final
         exposure conventions, apply failed-counteroffer resolution, and avoid creating reason-code
         or latest-run output fields too early?"

SQL PURPOSE:
    1. Confirm row count is unchanged from tmp_m2_stage_5_exposure_treatment.
    2. Confirm application_id remains unique.
    3. Confirm final decision fields are complete and valid.
    4. Confirm exactly one final decision flag is TRUE per row.
    5. Confirm simulated_offer_exposure_flag reconciles to final decision_outcome.
    6. Confirm final APPROVE convention.
    7. Confirm final COUNTEROFFER convention.
    8. Confirm final MANUAL_REVIEW unresolved convention.
    9. Confirm final DECLINE zero-exposure convention.
    10. Confirm failed_counteroffer_resolution was applied correctly.
    11. Confirm Section 9 did not create simulated reason-code fields.
    12. Confirm Section 9 did not create latest-run output.

LOCAL GATEKEEPER BOUNDARY:
    These are local Section 9 staging gatekeepers only.

    They are not:
        simulated reason-code validation,
        latest-run materialization validation,
        archive validation,
        matched strategy comparison,
        full Module 2 QA,
        strategy frontier review,
        or Validation Summary evidence by themselves.

***************************************************************************************************/

DO $$
DECLARE
    v_stage5_count BIGINT;
    v_stage6_count BIGINT;
    v_stage6_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    v_decision_completeness_failure_count BIGINT;
    v_flag_reconciliation_failure_count BIGINT;
    v_offer_flag_failure_count BIGINT;

    v_approve_convention_failure_count BIGINT;
    v_counteroffer_convention_failure_count BIGINT;
    v_manual_review_convention_failure_count BIGINT;
    v_decline_convention_failure_count BIGINT;

    v_failed_counteroffer_resolution_failure_count BIGINT;
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
        counteroffer_amount IS NULL.
        approved payment / PTI / Expected Loss equal requested equivalents.
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
            'Module 2 Section 9 failure: % final APPROVE row(s) violate as-requested approval conventions.',
            v_approve_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: COUNTEROFFER final convention.

    Business interpretation:
        COUNTEROFFER is a feasible reduced-exposure positive simulated offer.

    Expected:
        approved_amount > 0.
        approved_amount < requested_amount.
        counteroffer_amount = approved_amount.
        approved PTI <= counteroffer_target_pti.
        approved Expected Loss <= product_approved_el_cap.
        counteroffer_feasibility_pass_flag = TRUE.
        simulated_offer_exposure_flag = TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            preliminary_decision_outcome <> 'COUNTEROFFER'
         OR counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR approved_amount IS NULL
         OR approved_amount <= 0
         OR approved_amount >= requested_amount
         OR counteroffer_amount IS DISTINCT FROM approved_amount
         OR exposure_reduction_flag IS DISTINCT FROM TRUE
         OR exposure_reduction_amount IS NULL
         OR exposure_reduction_amount <= 0
         OR exposure_reduction_pct IS NULL
         OR exposure_reduction_pct <= 0
         OR approved_monthly_payment_proxy IS NULL
         OR approved_payment_to_income_ratio IS NULL
         OR approved_payment_to_income_ratio > counteroffer_target_pti
         OR approved_expected_loss_amount IS NULL
         OR approved_expected_loss_amount < 0
         OR approved_expected_loss_amount > requested_expected_loss_amount
         OR approved_expected_loss_amount > product_approved_el_cap
         OR approved_el_reduction_amount IS NULL
         OR approved_el_reduction_amount < 0
         OR (
                requested_expected_loss_amount > 0
            AND approved_el_reduction_pct IS NULL
            )
         OR simulated_offer_exposure_flag IS DISTINCT FROM TRUE
      );

    IF v_counteroffer_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final COUNTEROFFER row(s) violate reduced-exposure counteroffer conventions.',
            v_counteroffer_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: MANUAL_REVIEW final convention.

    Business interpretation:
        MANUAL_REVIEW is unresolved by design.

    Expected:
        final approved exposure fields remain NULL.
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
            'Module 2 Section 9 failure: % final MANUAL_REVIEW row(s) violate unresolved conventions.',
            v_manual_review_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DECLINE final convention.

    Business interpretation:
        DECLINE is a final no-offer outcome using locked zero-exposure conventions.

    Expected:
        approved_amount = 0.
        approved payment / PTI / Expected Loss = 0.
        simulated_offer_exposure_flag = FALSE.

    Note:
        exposure_reduction_flag remains FALSE because DECLINE is not a reduced positive offer.
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

    Section 11 creates credit_decisioning_sim.strategy_decisions.

    Why this matters:
        If latest-run output already exists while Section 9 is being rerun, a user could accidentally
        review stale Section 11 output instead of the current staging output.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: final latest-run strategy_decisions table exists before Section 11. Run the pipeline from Section 1 or drop/rebuild latest-run output through Section 11.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 9.4 — LOCAL FINAL DECISION RESOLUTION SANITY CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide lightweight diagnostics for Section 9 final decision resolution.

    Section 9.4 answers:

        "What final simulated outcomes did Section 9 assign, how were failed preliminary
         counteroffers resolved, and do final exposure conventions look ready for reason-code
         assignment?"

SQL PURPOSE:
    Display review outputs for:
        final decision outcome distribution,
        final decision path distribution,
        decision resolution source,
        simulated offer-exposure flag,
        preliminary × final decision migration,
        failed counteroffer resolution,
        final decision by product,
        final decision by score band,
        final decision by product × score,
        final decision by synthetic risk tier,
        final decision by requested PTI bucket,
        final decision by DTI bucket,
        final decision by requested exposure tier,
        final decision by requested Expected Loss tier,
        mixed-signal final decision behavior,
        borderline final decision behavior,
        final requested vs approved exposure behavior,
        final requested vs approved affordability behavior,
        final requested vs approved Expected Loss behavior,
        and one compact readiness summary.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        simulated reason-code validation,
        latest-run output validation,
        archive validation,
        matched strategy comparison,
        strategy frontier evidence,
        full Module 2 QA,
        or Validation Summary acceptance.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
9.4.1 Count by decision_outcome.

Purpose:
    Show the final simulated strategy outcome distribution.

Boundary:
    decision_outcome is final for this simulated strategy run, but it is not a real applicant decision.
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
    Show final internal decision path labels.

Boundary:
    decision_path is internal strategy explanation support.

    It is not customer communication language.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_stage

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_path

ORDER BY decision_path;



/*-----------------------------------------------------------------------------------------------
9.4.3 Count by decision_resolution_source.

Purpose:
    Show which upstream source resolved the final decision.

Interpretation:
    This helps reviewers distinguish:
        preliminary approval route;
        preliminary decline route;
        passed counteroffer feasibility;
        failed counteroffer to review;
        failed counteroffer to decline;
        preliminary manual review route.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_resolution_source,
    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_stage

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_resolution_source

ORDER BY decision_resolution_source;



/*-----------------------------------------------------------------------------------------------
9.4.4 Count by simulated_offer_exposure_flag.

Purpose:
    Review simulated positive offer-exposure rows.

Expected:
    TRUE only for APPROVE and COUNTEROFFER.

Boundary:
    simulated_offer_exposure_flag does not imply booked or funded exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    simulated_offer_exposure_flag,
    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_stage

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY simulated_offer_exposure_flag

ORDER BY simulated_offer_exposure_flag;



/*-----------------------------------------------------------------------------------------------
9.4.5 Preliminary decision outcome × final decision outcome.

Purpose:
    Show how preliminary routes resolved into final outcomes.

Key interpretation:
    Preliminary COUNTEROFFER can resolve to:
        final COUNTEROFFER when feasibility passes;
        final MANUAL_REVIEW or DECLINE when feasibility fails, depending on failed_counteroffer_resolution.
-----------------------------------------------------------------------------------------------*/

SELECT
    preliminary_decision_outcome,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (PARTITION BY preliminary_decision_outcome),
            0
        ),
        2
    ) AS pct_within_preliminary_outcome

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
9.4.6 Failed counteroffer final resolution summary.

Purpose:
    Review how infeasible preliminary counteroffers resolved.

Expected:
    If failed_counteroffer_resolution = MANUAL_REVIEW:
        failed preliminary counteroffers resolve to MANUAL_REVIEW.

    If failed_counteroffer_resolution = DECLINE:
        failed preliminary counteroffers resolve to DECLINE.
-----------------------------------------------------------------------------------------------*/

SELECT
    failed_counteroffer_resolution,
    counteroffer_feasibility_pass_flag,
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    decision_path,
    decision_resolution_source,

    COUNT(*) AS row_count

FROM tmp_m2_stage_6_final_decision_resolution

WHERE preliminary_decision_outcome = 'COUNTEROFFER'

GROUP BY
    failed_counteroffer_resolution,
    counteroffer_feasibility_pass_flag,
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    decision_path,
    decision_resolution_source

ORDER BY
    counteroffer_feasibility_pass_flag,
    decision_outcome,
    counteroffer_feasibility_failure_reason;



/*-----------------------------------------------------------------------------------------------
9.4.7 Product × decision_outcome.

Purpose:
    Review final simulated outcome distribution by product.

Interpretation:
    Product behavior should be explainable through product policy, requested exposure, affordability,
    LGD, requested Expected Loss, and counteroffer feasibility.
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
9.4.8 Score band × decision_outcome.

Purpose:
    Review final outcome behavior by score-band policy key.

Boundary:
    score band supports borrower-quality interpretation but is not the only decision driver.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

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
9.4.9 Product × score segment × decision_outcome.

Purpose:
    Review final outcome behavior across the key product × score evidence dimension.

Interpretation:
    This preview supports later Section 16 product × score segment evidence.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_rows,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_rows

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    decision_outcome

ORDER BY
    product_type_policy_key,
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
9.4.10 Synthetic risk tier × decision_outcome.

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
    AVG(synthetic_risk_trigger_count) AS avg_synthetic_risk_trigger_count

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
9.4.11 Requested PTI bucket × decision_outcome.

Purpose:
    Review final outcomes by requested-structure affordability bucket.

Boundary:
    requested_payment_to_income_ratio is requested PTI.

    approved_payment_to_income_ratio is final approved-exposure PTI proxy.
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
9.4.12 DTI bucket × decision_outcome.

Purpose:
    Review final outcomes by existing-obligation capacity bucket.

Boundary:
    DTI is not directly counteroffer-adjustable in Module 2 V1.0.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_bucket,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(dti_trigger_count) AS avg_dti_trigger_count

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    dti_bucket,
    decision_outcome

ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
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
    Review final outcomes by requested exposure tier.

Boundary:
    requested_amount is original requested exposure.

    approved_amount is final simulated approved exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_exposure_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,
    AVG(exposure_reduction_pct) AS avg_exposure_reduction_pct

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    requested_exposure_tier,
    decision_outcome

ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'LOW_REQUESTED_EXPOSURE' THEN 2
        WHEN 'WITHIN_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'WITHIN_PRODUCT_LIMITS' THEN 4
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 5
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 6
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
9.4.14 Requested Expected Loss tier × decision_outcome.

Purpose:
    Review final outcomes by requested-exposure Expected Loss tier.

Boundary:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is final approved-exposure Expected Loss.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_expected_loss_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount,
    AVG(approved_el_reduction_pct) AS avg_approved_el_reduction_pct

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    requested_expected_loss_tier,
    decision_outcome

ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
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
9.4.15 Mixed-signal profile × decision_outcome.

Purpose:
    Review final outcome behavior for realistic overlapping applicant profiles.

Boundary:
    mixed_signal_profile_type is diagnostic, not final route logic by itself.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(mixed_signal_condition_count) AS avg_mixed_signal_condition_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

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
    Review final outcome behavior for threshold-adjacent profiles.

Boundary:
    borderline_profile_flag is diagnostic only.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

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
    Review original requested exposure by final simulated outcome.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    SUM(requested_amount) AS total_requested_amount
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
    Review final approved exposure by final simulated outcome.

Expected:
    APPROVE:
        approved_amount equals requested_amount.

    COUNTEROFFER:
        approved_amount is positive and below requested_amount.

    MANUAL_REVIEW:
        approved_amount is NULL.

    DECLINE:
        approved_amount is zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(approved_amount) AS avg_approved_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount
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
    Review final affordability treatment by outcome.

Boundary:
    approved_payment_to_income_ratio is a final strategy-simulation affordability proxy.
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
    Review final requested-versus-approved Expected Loss by outcome.

Boundary:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is final approved-exposure Expected Loss.
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
9.4.21 Section 9 readiness summary.

Purpose:
    Provide one compact readiness row for the final decision-resolution stage.

Expected:
    section_9_final_decision_resolution_status =
        SECTION_9_FINAL_DECISION_RESOLUTION_READY_FOR_REASON_CODE_ASSIGNMENT

Interpretation:
    This confirms only that Section 9 is ready for Section 10.

    It does not validate simulated reason codes, latest-run output, archive persistence, comparison,
    QA, frontier, or evidence capture.
-----------------------------------------------------------------------------------------------*/

WITH final_resolution_summary AS (
    SELECT
        COUNT(*) AS stage6_row_count,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) FILTER (
            WHERE decision_outcome IS NULL
               OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
               OR decision_path IS NULL
               OR decision_priority_rank IS NULL
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
            WHERE decision_outcome = 'APPROVE'
              AND approved_amount IS DISTINCT FROM requested_amount
        ) AS approve_amount_convention_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    approved_amount IS NULL
                 OR approved_amount <= 0
                 OR approved_amount >= requested_amount
                 OR counteroffer_amount IS DISTINCT FROM approved_amount
                 OR counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
              )
        ) AS counteroffer_convention_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND (
                    approved_amount IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
              )
        ) AS manual_review_unresolved_convention_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
              )
        ) AS decline_zero_exposure_convention_gap_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
              AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
              AND decision_outcome <> 'MANUAL_REVIEW'
        ) AS failed_counteroffer_to_review_gap_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
              AND failed_counteroffer_resolution = 'DECLINE'
              AND decision_outcome <> 'DECLINE'
        ) AS failed_counteroffer_to_decline_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
        ) AS final_approve_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS final_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
        ) AS final_manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
        ) AS final_decline_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS simulated_offer_exposure_rows

    FROM tmp_m2_stage_6_final_decision_resolution
)

SELECT
    stage6_row_count,
    distinct_application_id_count,

    final_decision_gap_rows,
    final_flag_reconciliation_gap_rows,
    simulated_offer_exposure_flag_gap_rows,

    approve_amount_convention_gap_rows,
    counteroffer_convention_gap_rows,
    manual_review_unresolved_convention_gap_rows,
    decline_zero_exposure_convention_gap_rows,

    failed_counteroffer_to_review_gap_rows,
    failed_counteroffer_to_decline_gap_rows,

    final_approve_rows,
    final_counteroffer_rows,
    final_manual_review_rows,
    final_decline_rows,
    simulated_offer_exposure_rows,

    CASE
        WHEN stage6_row_count > 0
         AND stage6_row_count = distinct_application_id_count
         AND final_decision_gap_rows = 0
         AND final_flag_reconciliation_gap_rows = 0
         AND simulated_offer_exposure_flag_gap_rows = 0
         AND approve_amount_convention_gap_rows = 0
         AND counteroffer_convention_gap_rows = 0
         AND manual_review_unresolved_convention_gap_rows = 0
         AND decline_zero_exposure_convention_gap_rows = 0
         AND failed_counteroffer_to_review_gap_rows = 0
         AND failed_counteroffer_to_decline_gap_rows = 0
            THEN 'SECTION_9_FINAL_DECISION_RESOLUTION_READY_FOR_REASON_CODE_ASSIGNMENT'
        ELSE 'REVIEW_SECTION_9_FINAL_DECISION_RESOLUTION_BEFORE_REASON_CODE_ASSIGNMENT'
    END AS section_9_final_decision_resolution_status

FROM final_resolution_summary;



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
    10. failed_counteroffer_resolution is attached and valid.
    11. approval_flag, counteroffer_flag, manual_review_flag, and decline_flag reconcile to
        decision_outcome.
    12. Exactly one final decision flag is TRUE per row.
    13. simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.
    14. simulated_offer_exposure_flag is FALSE for MANUAL_REVIEW and DECLINE.
    15. Final APPROVE rows preserve requested exposure and requested-exposure economics.
    16. Final COUNTEROFFER rows use feasible reduced-exposure economics.
    17. Final MANUAL_REVIEW rows remain unresolved with NULL approved-exposure economics.
    18. Final DECLINE rows use locked zero-exposure conventions.
    19. Infeasible preliminary COUNTEROFFER rows resolve according to failed_counteroffer_resolution.
    20. estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy.
    21. requested_expected_loss_amount remains requested-exposure Expected Loss.
    22. approved_expected_loss_amount is now final approved-exposure Expected Loss.
    23. No simulated reason-code fields were created.
    24. No latest-run strategy_decisions output table was created.
    25. Section 9 local final decision-resolution diagnostics are available for review.

Section 9 established:
    1. The final simulated decision outcome layer.
    2. Final decision path labels.
    3. Final decision priority ranks.
    4. Final decision resolution source labels.
    5. Final approval / counteroffer / manual review / decline flags.
    6. Final simulated offer-exposure flag.
    7. Final approved exposure fields.
    8. Final approved affordability proxy fields.
    9. Final approved Expected Loss fields.
    10. Parameter-governed failed-counteroffer resolution.

No simulated reason codes have been assigned.
No primary_reason_code has been created.
No secondary_reason_code has been created.
No tertiary_reason_code has been created.
No triggered_reason_code_list has been created.
No reason_priority_rank has been created.
No primary_reason_family has been created.
No reason_code_count has been created.
No latest-run strategy_decisions table has been created.
No strategy archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full QA framework has been built.

Next section:
    Section 10 should consume tmp_m2_stage_6_final_decision_resolution and assign deterministic
    simulated strategy explanation codes using final decision outcomes, final decision paths, rule
    triggers, preliminary routing diagnostics, exposure-treatment diagnostics, and counteroffer
    feasibility diagnostics.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01561 -->


---

<a id="c038-m01562"></a>

### C038-M01562

**Andrew** · 2026-05-12T10:56:49.531000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01562 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 10 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01562 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_78.md) · [Next](Part_80.md)
