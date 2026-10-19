# Module 2 Decision Simulator Build

## Part 47

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_46.md) · [Next](Part_48.md)

<a id="c038-m00943"></a>

### C038-M00943

**ChatGPT** · 2026-05-10T00:19:16.206646-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00943 -->
I recommend replacing Section 10 with the version below. It preserves your existing candidate → rank → pivot reason-code logic, adds a Section 10.0 dependency preflight, and strengthens the instructional commentary around credit-risk interpretation, SQL mechanics, and run boundaries. fileciteturn97file0

```sql
/***************************************************************************************************
SECTION 10 — SIMULATED REASON-CODE ASSIGNMENT LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Assign deterministic simulated strategy explanation codes after final decision resolution.

    Section 10 answers:

        "Why did this synthetic applicant receive this simulated strategy outcome?"

    Section 10 does not answer:

        "What real applicant communication would be sent?"
        "What regulatory notice would be produced?"
        "What compliance conclusion should be drawn?"
        "What happened to an actual applicant?"

    This section is the explanation layer.

    Section 9 created final simulated outcomes.
    Section 10 explains those outcomes through deterministic simulated strategy reason codes.

SQL PURPOSE:
    1. Confirm required Section 10 dependencies exist.
    2. Read from tmp_m2_stage_6_final_decision_resolution.
    3. Preserve all prior source, lineage, Module 2 strategy metadata, thresholds, segmentation,
       rule flags, preliminary routing diagnostics, exposure-treatment diagnostics, and final
       decision fields.
    4. Create one candidate simulated reason-code row per applicable rule / route / treatment driver.
    5. Filter reason-code candidates by final decision_outcome family.
    6. Deduplicate repeated candidate reason codes.
    7. Rank candidate reasons deterministically using governed priority ranges.
    8. Pivot ranked candidates into:
            primary_reason_code
            secondary_reason_code
            tertiary_reason_code
            primary_reason_family
            triggered_reason_code_list
            reason_priority_rank
            reason_code_count
    9. Validate reason-code completeness, outcome-family alignment, reason-code uniqueness, and
       staging integrity.
    10. Keep latest-run output creation and archive persistence deferred.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that simulated reason codes reflect the major strategy drivers behind APPROVE,
        COUNTEROFFER, MANUAL_REVIEW, and DECLINE outcomes.

    Model governance / validation reviewers:
        Confirm that the reason-code layer is deterministic, bounded, and clearly separated from
        customer communications, regulatory notices, and fair-lending conclusions.

    SQL reviewers:
        Confirm that the candidate → deduplicate → rank → pivot pattern is readable, deterministic,
        and locally validated.

    Portfolio / executive reviewers:
        Use the reason-code diagnostics to understand the dominant simulated strategy explanation
        patterns before latest-run output, archive persistence, QA, frontier review, and evidence
        capture.

WHEN TO RUN THIS SECTION:
    Run Section 10 after:

        Section 9 — Final Decision Resolution Layer

    Section 10 should be run before:

        Section 11 — Latest-Run Strategy Decision Output Table

    Section 10 depends on:

        tmp_m2_stage_6_final_decision_resolution

HOW TO INTERPRET THIS SECTION:
    Passing Section 10 means:
        row count is preserved from Section 9,
        application_id remains unique,
        every final simulated outcome has a primary simulated reason code,
        reason-code family aligns to final decision_outcome,
        primary / secondary / tertiary reason fields are deterministic and non-duplicative,
        prohibited external-communication terminology is not used,
        and latest-run output creation remains deferred to Section 11.

    Passing Section 10 does not mean:
        latest-run output has been materialized,
        archive persistence worked,
        full QA validation has passed,
        matched comparison is complete,
        strategy frontier evidence has been created,
        or executive evidence has been captured.

INPUT:
    tmp_m2_stage_6_final_decision_resolution

OUTPUT:
    tmp_m2_stage_7_reason_code_assignment

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

WHY REASON-CODE ASSIGNMENT IS SEPARATED FROM FINAL DECISION RESOLUTION:
    Section 9 creates final simulated strategy outcomes and final approved-exposure economics.

    Section 10 explains those outcomes.

    Keeping explanation logic separate allows the reason-code layer to use:
        final decision_outcome,
        decision_path,
        decision_resolution_source,
        Section 6 rule-trigger flags,
        Section 7 preliminary routing diagnostics,
        Section 8 counteroffer feasibility diagnostics,
        final exposure-treatment fields,
        mixed-signal diagnostics,
        and borderline diagnostics.

    This separation also makes the reason-code layer easier to test because Section 10 does not
    recalculate decisions or exposure fields.

REASON-CODE BOUNDARY:
    The fields created in Section 10 are simulated strategy explanation codes.

    They support:
        transparency,
        QA review,
        strategy interpretation,
        portfolio diagnostics,
        decision-path traceability,
        and validation evidence.

    They are not:
        customer communications,
        regulatory notices,
        production compliance determinations,
        adverse-action notices,
        real applicant treatment explanations,
        or fair-lending conclusions.

OUTCOME-SPECIFIC FILTERING:
    Candidate reasons are filtered by final decision_outcome family so that:

        APPROVE rows receive APPROVAL reasons.
        COUNTEROFFER rows receive COUNTEROFFER reasons.
        MANUAL_REVIEW rows receive MANUAL_REVIEW reasons.
        DECLINE rows receive POLICY_STOP reasons.

WHY THE CANDIDATE → RANK → PIVOT PATTERN IS USED:
    A single row can have multiple valid explanatory drivers.

    For example:
        a final COUNTEROFFER row may be driven by product exposure limits, affordability pressure,
        requested Expected Loss pressure, and elevated synthetic estimated-risk.

    A single opaque CASE expression would hide that overlap.

    Section 10 therefore:
        creates candidate reasons,
        deduplicates candidates,
        ranks them deterministically,
        assigns primary / secondary / tertiary reason fields,
        and preserves the full triggered reason-code list.

REASON PRIORITY RANGES:
    POLICY_STOP / DECLINE reasons:
        100–199

    MANUAL_REVIEW reasons:
        300–399

    COUNTEROFFER reasons:
        500–599

    APPROVAL reasons:
        900–999

    Lower numeric rank means higher priority.

TRIGGERED REASON LIST:
    triggered_reason_code_list contains all applicable candidate reason codes after filtering to the
    final decision_outcome family.

    It is a diagnostic list.

    It is not customer-facing explanation text.
    It is not a regulatory notice.
    It is not a prioritized external communication.

SECONDARY AND TERTIARY REASONS:
    secondary_reason_code and tertiary_reason_code are additional diagnostics only.

    They do not change:
        decision_outcome,
        decision_path,
        approved exposure,
        approved PTI,
        approved Expected Loss,
        or simulated offer-exposure convention.

APPROVAL REASON BOUNDARY:
    APPROVE rows receive APPROVED_AS_REQUESTED.

    This indicates that the synthetic applicant passed the simulated strategy conditions required
    for an as-requested positive offer-exposure outcome.

COUNTEROFFER REASON BOUNDARY:
    COUNTEROFFER reason codes explain which simulated strategy constraints drove reduced-exposure
    treatment.

    They do not imply operational negotiation, account creation, funding, or real applicant treatment.

MANUAL REVIEW REASON BOUNDARY:
    MANUAL_REVIEW reason codes explain why the simulated strategy outcome remains unresolved.

    They do not represent completed operational review.

DECLINE / POLICY STOP REASON BOUNDARY:
    POLICY_STOP reason codes explain final simulated no-offer paths for synthetic applicants.

    They are simulated strategy explanation codes only.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field and is interpreted as the synthetic
    estimated-PD proxy.

    Section 10 does not recalculate estimated_pd.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is approved-exposure Expected Loss after Module 2 final exposure
    treatment.

    Section 10 explains outcomes but does not recalculate either value.

LATEST-RUN / ARCHIVE BOUNDARY:
    Section 10 creates only a temporary reason-code staging table.

    Section 10 does not create:
        credit_decisioning_sim.strategy_decisions

    Section 10 does not insert rows into:
        credit_decisioning_sim.strategy_decisions_archive

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the reason-code assignment layer as a session-scoped staging table.

    ON COMMIT PRESERVE ROWS:
        Keeps the staging table available across transaction boundaries in the active session.

    CTE chain:
        The WITH clause breaks reason-code assignment into readable steps:
            reason_candidate_base
            reason_candidates_raw
            reason_candidates
            ranked_reasons
            reason_pivot
            final_reason_assignment

    UNION ALL:
        Adds candidate reason rows from many explanation families without hiding them inside one
        large CASE expression.

    GROUP BY:
        Deduplicates repeated reason-code candidates.

    ROW_NUMBER() OVER (...):
        Ranks candidate reasons deterministically within each application_id.

    FILTER:
        Pivots ranked candidate reason rows into primary, secondary, and tertiary fields.

    STRING_AGG:
        Creates triggered_reason_code_list in deterministic rank order.

    IS DISTINCT FROM:
        Supports NULL-safe validation checks.

    pg_attribute:
        Inspects physical columns to make sure reason-code fields are not created in earlier stages.

    TO_REGCLASS:
        Confirms latest-run materialization remains deferred until Section 11.

GOVERNANCE ROLE:
    Section 10 makes strategy explanations deterministic, reviewable, and auditable.

    It supports later:
        latest-run output materialization,
        archive persistence,
        reason-code QA,
        matched strategy comparison,
        executive frontier summaries,
        and evidence capture.

COMMON MISUSE TO AVOID:
    Do not interpret primary_reason_code as a real applicant communication.
    Do not interpret secondary_reason_code or tertiary_reason_code as additional final decisions.
    Do not interpret triggered_reason_code_list as a priority-ordered customer explanation.
    Do not infer that simulated explanation codes are externally approved communication text.
    Do not treat POLICY_STOP reason families as regulatory adverse-action reason codes.
    Do not treat MANUAL_REVIEW reason families as completed operational review notes.

TESTING RELEVANCE:
    Section 10 local gatekeepers confirm:
        row-count preservation,
        application_id uniqueness,
        reason-code completeness,
        outcome-family alignment,
        primary reason-code prefix alignment,
        reason-code uniqueness,
        prohibited-language controls,
        and absence of latest-run / archive creation.

DOWNSTREAM DEPENDENCY:
    Section 11 consumes tmp_m2_stage_7_reason_code_assignment and materializes
    credit_decisioning_sim.strategy_decisions.

PORTFOLIO ARTIFACT VALUE:
    This section demonstrates that the Module 2 strategy engine does not stop at assigning outcomes.

    It produces transparent explanation evidence that allows reviewers to understand why simulated
    strategy outcomes occurred and how they relate to the underlying strategy architecture.

***************************************************************************************************/



/***************************************************************************************************
SECTION 10.0 — SECTION 10 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 9 final decision-resolution output exists and is ready for simulated
    reason-code assignment.

    Section 10.0 answers:

        "Can Section 10 safely explain the final simulated outcomes produced by Section 9?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_6_final_decision_resolution exists.
    2. Confirm the final decision-resolution table contains rows.
    3. Confirm application_id remains unique before reason-code fields are added.
    4. Confirm required final decision fields are populated.
    5. Confirm key route / trigger fields used by reason-code logic are populated.
    6. Confirm reason-code fields do not already exist in Section 9 output.
    7. Fail clearly if Section 10 is run out of order.

WHY THIS PREFLIGHT EXISTS:
    Section 10 is a transformation layer.

    It should fail with a clear instructional message if Section 9 has not run, rather than producing
    a lower-level missing-table error.

CREDIT RISK INTERPRETATION:
    Explanation logic depends on final simulated outcomes.

    Reason codes should not be assigned before:
        final decision_outcome exists,
        final decision flags reconcile,
        approved exposure conventions are resolved,
        counteroffer feasibility has been resolved,
        and failed counteroffers have been assigned their final simulated outcome.

BOUNDARY:
    Section 10.0 does not create reason codes.
    Section 10.0 does not create final decisions.
    Section 10.0 does not create latest-run output.
    Section 10.0 does not insert archive rows.
    Section 10.0 does not modify any persistent table.

***************************************************************************************************/

DO $$
DECLARE
    v_stage6_exists BOOLEAN;
    v_stage6_row_count BIGINT;
    v_stage6_distinct_application_count BIGINT;
    v_required_stage6_gap_count BIGINT;
    v_premature_reason_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 9 final decision-resolution table must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

        pg_temp is checked because tmp_m2_stage_6_final_decision_resolution is a temporary table.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_6_final_decision_resolution'),
        TO_REGCLASS('tmp_m2_stage_6_final_decision_resolution')
    ) IS NOT NULL
    INTO v_stage6_exists;

    IF v_stage6_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: tmp_m2_stage_6_final_decision_resolution is required. Run Section 9 before Section 10.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 9 output must contain rows.

    Business interpretation:
        Reason-code assignment over an empty applicant population is not useful and usually indicates
        an upstream source, routing, exposure-treatment, or final-resolution issue.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage6_row_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: tmp_m2_stage_6_final_decision_resolution contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id should be unique before reason codes are added.

    Section 10 should add explanation fields only.

    It should not repair grain problems from earlier stages.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage6_distinct_application_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_distinct_application_count <> v_stage6_row_count THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: tmp_m2_stage_6_final_decision_resolution is not unique at application_id. Rows=%, distinct application_id=%.',
            v_stage6_row_count,
            v_stage6_distinct_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final decision and reason-code input fields must be populated.

    Business interpretation:
        Reason-code assignment depends on final outcome, final decision path, decision-resolution
        source, and the trigger / route / exposure-treatment diagnostics preserved from earlier
        sections.

    Important:
        Some counteroffer feasibility fields are intentionally NULL for non-counteroffer rows.
        The check below focuses on route-driving and explanation-driving fields that should be
        available for all rows or for their applicable route family.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_stage6_gap_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE application_id IS NULL
       OR decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL
       OR decision_priority_rank IS NULL

       OR approval_flag IS NULL
       OR counteroffer_flag IS NULL
       OR manual_review_flag IS NULL
       OR decline_flag IS NULL
       OR simulated_offer_exposure_flag IS NULL

       OR preliminary_decision_outcome IS NULL
       OR exposure_treatment_status IS NULL
       OR exposure_treatment_path IS NULL

       OR hard_policy_stop_flag IS NULL
       OR bankruptcy_policy_stop_flag IS NULL
       OR major_derogatory_policy_stop_flag IS NULL
       OR severe_delinquency_policy_stop_flag IS NULL
       OR synthetic_risk_decline_trigger_flag IS NULL
       OR dti_decline_trigger_flag IS NULL
       OR requested_pti_decline_trigger_flag IS NULL
       OR requested_el_decline_trigger_flag IS NULL
       OR requested_exposure_extreme_flag IS NULL
       OR exposure_policy_stop_candidate_flag IS NULL

       OR counteroffer_candidate_flag IS NULL
       OR counteroffer_candidate_trigger_count IS NULL
       OR exposure_counteroffer_candidate_flag IS NULL
       OR counteroffer_affordability_candidate_flag IS NULL
       OR counteroffer_expected_loss_candidate_flag IS NULL
       OR counteroffer_risk_band_eligible_flag IS NULL

       OR manual_review_candidate_flag IS NULL
       OR manual_review_borderline_trigger_flag IS NULL
       OR manual_review_mixed_signal_trigger_flag IS NULL
       OR manual_review_affordability_trigger_flag IS NULL
       OR manual_review_risk_trigger_flag IS NULL
       OR manual_review_dti_trigger_flag IS NULL
       OR manual_review_expected_loss_trigger_flag IS NULL
       OR supplemental_behavioral_review_trigger_flag IS NULL

       OR severe_requested_structure_trigger_flag IS NULL
       OR borderline_profile_flag IS NULL
       OR mixed_signal_profile_type IS NULL
       OR strategy_risk_tier IS NULL
       OR requested_pti_bucket IS NULL
       OR requested_exposure_tier IS NULL
       OR requested_expected_loss_tier IS NULL

       OR failed_counteroffer_resolution IS NULL
       OR failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE')

       OR (
            preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS NULL
       );

    IF v_required_stage6_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % Section 9 row(s) are missing final outcome, route, trigger, or exposure-treatment fields required for reason-code assignment.',
            v_required_stage6_gap_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 9 output should not already contain Section 10 reason-code fields.

    Business purpose:
        Reason-code assignment belongs to Section 10.

        If these fields already exist in Section 9 output, the staged architecture boundary has been
        crossed.

    SQL mechanics:
        pg_attribute inspects physical columns on the temporary table.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_premature_reason_column_count
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

    IF v_premature_reason_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: simulated reason-code field(s) already exist before Section 10 reason-code assignment.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 10.1 — CLEAN RESET OF SECTION 10 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 10 reason-code staging object before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 10 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale simulated reason-code rows to remain available to
    Section 11 latest-run output creation.

    Section 11 assumes tmp_m2_stage_7_reason_code_assignment reflects the current:
        Section 9 final decision-resolution output,
        final decision taxonomy,
        final route diagnostics,
        final exposure conventions,
        and current simulated reason-code assignment logic.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the table does not exist, PostgreSQL does not error.

BOUNDARY:
    This drop affects only the temporary Section 10 staging object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_7_reason_code_assignment;



/***************************************************************************************************
SECTION 10.2 — CREATE SIMULATED REASON-CODE ASSIGNMENT TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_7_reason_code_assignment

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_6_final_decision_resolution

OUTPUT:
    All Section 9 fields plus:
        primary_reason_code
        secondary_reason_code
        tertiary_reason_code
        primary_reason_family
        triggered_reason_code_list
        reason_priority_rank
        reason_code_count

IMPLEMENTATION PATTERN:
    reason_candidate_base:
        preserves the Section 9 final decision record.

    reason_candidates_raw:
        creates one row per application_id per candidate simulated strategy explanation code.

    reason_candidates:
        deduplicates repeated candidate reason codes.

    ranked_reasons:
        assigns deterministic rank order.

    reason_pivot:
        converts candidate rows back to one row per application_id.

    final_reason_assignment:
        preserves all Section 9 fields and adds final Section 10 reason-code fields.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 10 intentionally preserves all prior fields plus simulated reason-code diagnostics for
    Section 11 latest-run materialization.

    Permanent output selection is handled later with an explicit field list in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_7_reason_code_assignment
ON COMMIT PRESERVE ROWS
AS
WITH reason_candidate_base AS (
    /***********************************************************************************************
    CTE: reason_candidate_base

    Purpose:
        Preserve every Section 9 final decision-resolution row before reason-code candidates are
        generated.

    SQL mechanics:
        SELECT f.* carries the full final decision-resolution record forward.

    Boundary:
        This CTE does not assign reasons yet.
        It only establishes the source population for the reason-code layer.
    ***********************************************************************************************/
    SELECT
        f.*
    FROM tmp_m2_stage_6_final_decision_resolution f
),

reason_candidates_raw AS (

    /***********************************************************************************************
    APPROVAL REASONS — PRIORITY 900–999

    APPROVE rows receive APPROVED_AS_REQUESTED as the required approval explanation code.

    Credit risk interpretation:
        APPROVED_AS_REQUESTED means the synthetic applicant received a simulated positive offer
        exposure outcome without reduced-exposure treatment.

    Boundary:
        This is not an account-opening event.
        This is not funded exposure.
        This is not a real applicant communication.
    ***********************************************************************************************/

    SELECT
        application_id,
        'APPROVED_AS_REQUESTED'::TEXT AS candidate_reason_code,
        'APPROVAL'::TEXT AS candidate_reason_family,
        900::INTEGER AS candidate_reason_priority_rank,
        'decision_outcome_APPROVE'::TEXT AS candidate_reason_source
    FROM reason_candidate_base
    WHERE decision_outcome = 'APPROVE'



    /***********************************************************************************************
    COUNTEROFFER REASONS — PRIORITY 500–599

    These reasons explain why final COUNTEROFFER rows received reduced-exposure treatment.

    Counteroffer reason codes are generated only for rows where:
        decision_outcome = 'COUNTEROFFER'

    This preserves outcome-family alignment.

    COUNTEROFFER_MULTIPLE_CONSTRAINTS is intentionally lower priority than specific counteroffer
    drivers so it generally appears as a secondary or tertiary diagnostic when multiple driver
    families are active.
    ***********************************************************************************************/

    UNION ALL

    /***********************************************************************************************
    Product exposure limit driver.

    Indicates that product exposure policy or product cap behavior contributed to reduced exposure.

    SQL mechanics:
        This candidate is created when:
            the Section 6 exposure counteroffer candidate flag was active,
            or requested exposure was above product cap,
            or the product cap amount was the binding raw feasible amount.
    ***********************************************************************************************/
    SELECT
        application_id,
        'COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT',
        'COUNTEROFFER',
        500,
        'exposure_counteroffer_candidate_or_product_cap_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            exposure_counteroffer_candidate_flag IS TRUE
         OR requested_exposure_above_product_cap_flag IS TRUE
         OR (
                counteroffer_product_cap_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_product_cap_amount = counteroffer_raw_max_feasible_amount
            AND requested_amount > product_max_approved_amount
         )
      )

    UNION ALL

    /***********************************************************************************************
    Affordability adjustment driver.

    Indicates that requested PTI pressure or the counteroffer PTI target contributed to reduced
    exposure.

    Credit risk interpretation:
        Counteroffer can preserve access by reducing exposure so the approved PTI proxy is lower than
        requested PTI.
    ***********************************************************************************************/
    SELECT
        application_id,
        'COUNTEROFFER_AFFORDABILITY_ADJUSTMENT',
        'COUNTEROFFER',
        510,
        'requested_pti_counteroffer_candidate_or_pti_target_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_affordability_candidate_flag IS TRUE
         OR requested_pti_counteroffer_candidate_flag IS TRUE
         OR (
                counteroffer_pti_target_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_pti_target_amount = counteroffer_raw_max_feasible_amount
         )
      )

    UNION ALL

    /***********************************************************************************************
    Approved Expected Loss limit driver.

    Indicates that requested Expected Loss pressure or the product approved Expected Loss cap
    contributed to reduced exposure.

    Credit risk interpretation:
        Reducing approved exposure can reduce approved Expected Loss while leaving estimated_pd and
        estimated_lgd unchanged.
    ***********************************************************************************************/
    SELECT
        application_id,
        'COUNTEROFFER_EXPECTED_LOSS_LIMIT',
        'COUNTEROFFER',
        520,
        'requested_el_counteroffer_candidate_or_approved_el_cap_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_expected_loss_candidate_flag IS TRUE
         OR (
                counteroffer_el_cap_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_el_cap_amount = counteroffer_raw_max_feasible_amount
         )
      )

    UNION ALL

    /***********************************************************************************************
    Synthetic-risk exposure-limit driver.

    Indicates that the row sat in the synthetic estimated-risk counteroffer band.

    Boundary:
        estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy. Section 10 does not recalculate it.
    ***********************************************************************************************/
    SELECT
        application_id,
        'COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT',
        'COUNTEROFFER',
        530,
        'counteroffer_risk_band_eligible'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND counteroffer_risk_band_eligible_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Multiple counteroffer constraints.

    Indicates that more than one counteroffer candidate dimension was active.

    This is intentionally lower priority than specific counteroffer drivers.
    ***********************************************************************************************/
    SELECT
        application_id,
        'COUNTEROFFER_MULTIPLE_CONSTRAINTS',
        'COUNTEROFFER',
        580,
        'multiple_counteroffer_candidate_families'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND counteroffer_candidate_trigger_count > 1



    /***********************************************************************************************
    MANUAL REVIEW REASONS — PRIORITY 300–399

    These reasons explain why the final row remains unresolved under simulated strategy handling.

    Manual-review reasons are generated only for rows where:
        decision_outcome = 'MANUAL_REVIEW'

    Specific failed-counteroffer feasibility diagnostics rank above generic failed-counteroffer
    review routing. This preserves useful counteroffer feasibility traceability.
    ***********************************************************************************************/

    UNION ALL

    /***********************************************************************************************
    Failed counteroffer because product did not allow counteroffer.

    This is a manual-review reason when failed_counteroffer_resolution routes the infeasible
    counteroffer to MANUAL_REVIEW.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT',
        'MANUAL_REVIEW',
        300,
        'COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT'

    UNION ALL

    /***********************************************************************************************
    Failed counteroffer because PTI target could not be met.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_PTI_TARGET_NOT_MET',
        'MANUAL_REVIEW',
        305,
        'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'

    UNION ALL

    /***********************************************************************************************
    Failed counteroffer because approved Expected Loss remained above product cap.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_APPROVED_EL_ABOVE_CAP',
        'MANUAL_REVIEW',
        310,
        'COUNTEROFFER_APPROVED_EL_ABOVE_CAP'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_APPROVED_EL_ABOVE_CAP'

    UNION ALL

    /***********************************************************************************************
    Failed counteroffer because the reduced amount was not actually below requested amount.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED',
        'MANUAL_REVIEW',
        312,
        'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'

    UNION ALL

    /***********************************************************************************************
    Failed counteroffer because the reduced amount violated minimum offer / reduction-floor
    constraints.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER',
        'MANUAL_REVIEW',
        315,
        'counteroffer_amount_below_minimum_or_reduction_floor'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason IN (
            'COUNTEROFFER_ROUNDED_AMOUNT_NULL',
            'COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE',
            'COUNTEROFFER_BELOW_PRODUCT_MINIMUM',
            'COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT',
            'COUNTEROFFER_EXCEEDS_MAX_REDUCTION'
      )

    UNION ALL

    /***********************************************************************************************
    Generic failed counteroffer routed to manual review.

    This reason is intentionally lower priority than specific feasibility-failure reasons.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_NOT_FEASIBLE',
        'MANUAL_REVIEW',
        320,
        'generic_failed_counteroffer_to_review'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND failed_counteroffer_resolution = 'MANUAL_REVIEW'

    UNION ALL

    /***********************************************************************************************
    Borderline synthetic-risk review.

    Indicates threshold-adjacent synthetic estimated-risk behavior or elevated/high synthetic-risk
    tiering near strategy boundaries.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK',
        'MANUAL_REVIEW',
        330,
        'borderline_synthetic_estimated_risk'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_borderline_trigger_flag IS TRUE
         OR (
                borderline_profile_flag IS TRUE
            AND strategy_risk_tier IN (
                    'ELEVATED_SYNTHETIC_RISK',
                    'HIGH_SYNTHETIC_RISK'
                )
         )
      )

    UNION ALL

    /***********************************************************************************************
    Borderline affordability review.

    Indicates requested PTI is in an elevated / high / severe bucket and the row is threshold-adjacent.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_BORDERLINE_AFFORDABILITY',
        'MANUAL_REVIEW',
        340,
        'borderline_requested_affordability'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND borderline_profile_flag IS TRUE
      AND requested_pti_bucket IN (
            'ELEVATED_REQUESTED_PTI',
            'HIGH_REQUESTED_PTI',
            'SEVERE_REQUESTED_PTI'
      )

    UNION ALL

    /***********************************************************************************************
    Mixed-signal profile review.

    Indicates realistic overlapping signals such as strong credit with high PTI, weak credit with
    low PTI, large exposure with low synthetic risk, or high DTI with low requested PTI.

    Boundary:
        Mixed-signal profile is diagnostic only. It is not a final decision by itself.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_MIXED_SIGNAL_PROFILE',
        'MANUAL_REVIEW',
        350,
        'mixed_signal_profile'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_mixed_signal_trigger_flag IS TRUE
         OR mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
      )

    UNION ALL

    /***********************************************************************************************
    Requested-structure review.

    Indicates unresolved requested affordability, requested Expected Loss, requested exposure, or
    severe requested-structure pressure.

    Credit risk interpretation:
        This reason is based on requested structure, not approved structure.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_REQUESTED_STRUCTURE',
        'MANUAL_REVIEW',
        360,
        'requested_structure_stress'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            severe_requested_structure_trigger_flag IS TRUE
         OR manual_review_affordability_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR exposure_policy_stop_candidate_flag IS TRUE
         OR requested_exposure_tier IN (
                'ABOVE_PRODUCT_APPROVAL_CAP',
                'EXTREME_REQUESTED_EXPOSURE'
            )
         OR requested_pti_bucket IN (
                'ELEVATED_REQUESTED_PTI',
                'HIGH_REQUESTED_PTI',
                'SEVERE_REQUESTED_PTI'
            )
         OR requested_expected_loss_tier IN (
                'ELEVATED_REQUESTED_EL',
                'HIGH_REQUESTED_EL',
                'SEVERE_REQUESTED_EL'
            )
      )

    UNION ALL

    /***********************************************************************************************
    Elevated synthetic-risk manual review.

    Indicates the manual-review risk trigger was active.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_ELEVATED_SYNTHETIC_RISK',
        'MANUAL_REVIEW',
        370,
        'manual_review_risk_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND manual_review_risk_trigger_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Elevated DTI manual review.

    Indicates DTI capacity contributed to unresolved manual review.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_ELEVATED_DTI',
        'MANUAL_REVIEW',
        380,
        'manual_review_dti_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND manual_review_dti_trigger_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Expected Loss manual review.

    Indicates requested Expected Loss contributed to unresolved manual review.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_EXPECTED_LOSS',
        'MANUAL_REVIEW',
        385,
        'manual_review_expected_loss_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND manual_review_expected_loss_trigger_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Supplemental behavioral signal review.

    Indicates high-utilization or low-score supplemental review trigger behavior.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_SUPPLEMENTAL_BEHAVIORAL_SIGNAL',
        'MANUAL_REVIEW',
        390,
        'supplemental_behavioral_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND supplemental_behavioral_review_trigger_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Residual strategy review.

    Fallback explanation for residual manual-review paths.

    Boundary:
        Residual review should be non-dominant and visible in QA.
    ***********************************************************************************************/
    SELECT
        application_id,
        'MANUAL_REVIEW_RESIDUAL_STRATEGY_REVIEW',
        'MANUAL_REVIEW',
        399,
        'residual_manual_review_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            decision_path IN (
                'RESIDUAL_STRATEGY_REVIEW',
                'FINAL_RESIDUAL_STRATEGY_REVIEW'
            )
         OR decision_resolution_source = 'FINAL_RESIDUAL_FALLBACK'
      )



    /***********************************************************************************************
    DECLINE / POLICY STOP REASONS — PRIORITY 100–199

    These reasons explain final no-offer simulated policy stop paths.

    These are simulated policy stop reasons for synthetic applicants.

    They are not:
        customer communications,
        regulatory notices,
        adverse-action reason codes,
        production compliance determinations,
        or fair-lending conclusions.
    ***********************************************************************************************/

    UNION ALL

    /***********************************************************************************************
    Bankruptcy simulated policy stop.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_BANKRUPTCY_FLAG',
        'POLICY_STOP',
        100,
        'bankruptcy_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND bankruptcy_policy_stop_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Major derogatory simulated policy stop.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_MAJOR_DEROGATORY',
        'POLICY_STOP',
        110,
        'major_derogatory_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND major_derogatory_policy_stop_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Recent delinquency simulated policy stop.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_RECENT_DELINQUENCY',
        'POLICY_STOP',
        120,
        'severe_delinquency_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND severe_delinquency_policy_stop_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    High synthetic estimated-PD proxy simulated policy stop.

    Boundary:
        estimated_pd remains the Module 1 synthetic estimated-PD proxy input.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY',
        'POLICY_STOP',
        130,
        'synthetic_risk_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            synthetic_risk_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_SYNTHETIC_RISK'
      )

    UNION ALL

    /***********************************************************************************************
    High DTI simulated policy stop.

    Credit risk interpretation:
        DTI reflects existing-obligation capacity, not just requested-exposure affordability.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_HIGH_DTI',
        'POLICY_STOP',
        140,
        'dti_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            dti_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_DTI_CAPACITY'
      )

    UNION ALL

    /***********************************************************************************************
    High requested PTI simulated policy stop.

    Includes direct requested PTI decline triggers and failed counteroffers routed to decline because
    PTI target could not be met.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_HIGH_REQUESTED_PTI',
        'POLICY_STOP',
        145,
        'requested_pti_decline_or_counteroffer_pti_failure_to_decline'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            requested_pti_decline_trigger_flag IS TRUE
         OR (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS FALSE
            AND failed_counteroffer_resolution = 'DECLINE'
            AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
            )
      )

    UNION ALL

    /***********************************************************************************************
    Failed counteroffer resolved to decline.

    This reason explains strategy settings where failed_counteroffer_resolution = DECLINE.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_COUNTEROFFER_NOT_FEASIBLE',
        'POLICY_STOP',
        150,
        'failed_counteroffer_resolution_to_decline'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND failed_counteroffer_resolution = 'DECLINE'

    UNION ALL

    /***********************************************************************************************
    High requested Expected Loss simulated policy stop.

    Boundary:
        requested_expected_loss_amount is requested-exposure Expected Loss.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_HIGH_REQUESTED_EXPECTED_LOSS',
        'POLICY_STOP',
        160,
        'requested_el_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND requested_el_decline_trigger_flag IS TRUE

    UNION ALL

    /***********************************************************************************************
    Exposure limit unresolved simulated policy stop.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_EXPOSURE_LIMIT_UNRESOLVED',
        'POLICY_STOP',
        170,
        'requested_exposure_policy_stop_candidate'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            requested_exposure_extreme_flag IS TRUE
         OR exposure_policy_stop_candidate_flag IS TRUE
      )

    UNION ALL

    /***********************************************************************************************
    Residual decline.

    Fallback explanation for final DECLINE rows where no more specific policy-stop candidate was
    generated.

    Boundary:
        This should be visible and generally non-dominant in QA.
    ***********************************************************************************************/
    SELECT
        application_id,
        'POLICY_STOP_RESIDUAL_DECLINE',
        'POLICY_STOP',
        199,
        'residual_decline_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND NOT (
            bankruptcy_policy_stop_flag IS TRUE
         OR major_derogatory_policy_stop_flag IS TRUE
         OR severe_delinquency_policy_stop_flag IS TRUE
         OR synthetic_risk_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_SYNTHETIC_RISK'
         OR dti_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_DTI_CAPACITY'
         OR requested_pti_decline_trigger_flag IS TRUE
         OR (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS FALSE
            AND failed_counteroffer_resolution = 'DECLINE'
            AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
            )
         OR (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS FALSE
            AND failed_counteroffer_resolution = 'DECLINE'
            )
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR exposure_policy_stop_candidate_flag IS TRUE
      )
),

reason_candidates AS (
    /***********************************************************************************************
    CTE: reason_candidates

    Purpose:
        Deduplicate reason candidates.

    Why this exists:
        A row can satisfy the same candidate reason through multiple related diagnostics.

        Deduplication keeps triggered_reason_code_list readable while preserving deterministic
        ranking.

    SQL mechanics:
        GROUP BY collapses duplicate candidate reason records at:
            application_id,
            candidate_reason_code,
            candidate_reason_family,
            candidate_reason_priority_rank.

        MIN(candidate_reason_source) preserves one deterministic source label when multiple source
        paths generated the same reason.
    ***********************************************************************************************/
    SELECT
        application_id,
        candidate_reason_code,
        candidate_reason_family,
        candidate_reason_priority_rank,
        MIN(candidate_reason_source) AS candidate_reason_source
    FROM reason_candidates_raw
    GROUP BY
        application_id,
        candidate_reason_code,
        candidate_reason_family,
        candidate_reason_priority_rank
),

ranked_reasons AS (
    /***********************************************************************************************
    CTE: ranked_reasons

    Purpose:
        Rank candidate reasons.

    SQL mechanics:
        ROW_NUMBER() assigns one deterministic row number per application_id.

        Ordering uses:
            candidate_reason_priority_rank,
            candidate_reason_code.

        Lower numeric rank means higher priority.

        Alphabetic reason-code ordering breaks ties deterministically.
    ***********************************************************************************************/
    SELECT
        rc.*,

        ROW_NUMBER() OVER (
            PARTITION BY rc.application_id
            ORDER BY
                rc.candidate_reason_priority_rank,
                rc.candidate_reason_code
        ) AS reason_row_number

    FROM reason_candidates rc
),

reason_pivot AS (
    /***********************************************************************************************
    CTE: reason_pivot

    Purpose:
        Pivot ranked reason candidates back to one row per application_id.

    SQL mechanics:
        FILTER extracts the first, second, and third ranked reasons.

        STRING_AGG builds the full triggered reason-code list in deterministic priority order.

    Boundary:
        secondary_reason_code and tertiary_reason_code are diagnostics only.
    ***********************************************************************************************/
    SELECT
        application_id,

        MAX(candidate_reason_code) FILTER (WHERE reason_row_number = 1)
            AS primary_reason_code,

        MAX(candidate_reason_code) FILTER (WHERE reason_row_number = 2)
            AS secondary_reason_code,

        MAX(candidate_reason_code) FILTER (WHERE reason_row_number = 3)
            AS tertiary_reason_code,

        MAX(candidate_reason_family) FILTER (WHERE reason_row_number = 1)
            AS primary_reason_family,

        MAX(candidate_reason_priority_rank) FILTER (WHERE reason_row_number = 1)
            AS reason_priority_rank,

        STRING_AGG(
            candidate_reason_code,
            ' | '
            ORDER BY candidate_reason_priority_rank, candidate_reason_code
        ) AS triggered_reason_code_list,

        COUNT(*)::INTEGER AS reason_code_count

    FROM ranked_reasons
    GROUP BY application_id
),

final_reason_assignment AS (
    /***********************************************************************************************
    CTE: final_reason_assignment

    Purpose:
        Preserve all Section 9 final decision-resolution fields and add Section 10 simulated
        reason-code fields.

    SQL mechanics:
        LEFT JOIN keeps every final decision-resolution row even if reason_pivot is missing.

        The Section 10.3 gatekeeper then fails if any row lacks required reason-code assignment.

    Why not use INNER JOIN:
        A missing reason should be detected by a clear gatekeeper exception, not silently remove the
        application from the staging output.
    ***********************************************************************************************/
    SELECT
        b.*,

        rp.primary_reason_code,
        rp.secondary_reason_code,
        rp.tertiary_reason_code,
        rp.primary_reason_family,
        rp.triggered_reason_code_list,
        rp.reason_priority_rank,
        rp.reason_code_count

    FROM reason_candidate_base b
    LEFT JOIN reason_pivot rp
        ON rp.application_id = b.application_id
)

SELECT *
FROM final_reason_assignment;



/***************************************************************************************************
SECTION 10.3 — LOCAL FAIL-FAST CHECKS FOR SIMULATED REASON-CODE ASSIGNMENT
****************************************************************************************************

PURPOSE:
    Validate the Section 10 reason-code staging layer before latest-run output creation, archive
    persistence, full QA, or matched strategy comparison are built.

BUSINESS PURPOSE:
    Ensure every final simulated outcome has a complete, outcome-family-aligned, deterministic
    strategy explanation before the final latest-run output table is materialized.

SQL PURPOSE:
    1. Confirm row count is preserved from Section 9 to Section 10.
    2. Confirm application_id remains unique.
    3. Confirm required simulated reason-code fields are populated.
    4. Confirm APPROVE reason-code convention.
    5. Confirm COUNTEROFFER reason-code convention.
    6. Confirm MANUAL_REVIEW reason-code convention.
    7. Confirm DECLINE / POLICY_STOP reason-code convention.
    8. Confirm secondary and tertiary reasons do not duplicate higher-priority reason fields.
    9. Confirm reason-code family alignment and prohibited terminology controls.
    10. Confirm latest-run output table has not been created before Section 11.

LOCAL GATEKEEPER BOUNDARY:
    These are local Section 10 staging gatekeepers only.

    They are not:
        full Module 2 QA,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        or final documentation evidence.

SQL MECHANICS:
    This block uses PL/pgSQL because it needs multiple diagnostic counts and fail-fast exceptions.

***************************************************************************************************/

DO $$
DECLARE
    /***********************************************************************************************
    Row-grain diagnostics.
    ***********************************************************************************************/
    v_stage6_count BIGINT;
    v_stage7_count BIGINT;
    v_stage7_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    /***********************************************************************************************
    Reason-code completeness and alignment diagnostics.
    ***********************************************************************************************/
    v_required_reason_failure_count BIGINT;
    v_approval_reason_failure_count BIGINT;
    v_counteroffer_reason_failure_count BIGINT;
    v_manual_review_reason_failure_count BIGINT;
    v_decline_reason_failure_count BIGINT;
    v_reason_uniqueness_failure_count BIGINT;
    v_family_leakage_failure_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 9 to Section 10.

    Business purpose:
        Section 10 should add explanation fields only.

        It should not filter applicants or duplicate applicants.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage6_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    SELECT COUNT(*)
    INTO v_stage7_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    IF v_stage7_count <> v_stage6_count THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: row count changed from Section 9 to Section 10. Stage 6 rows: %, Stage 7 rows: %.',
            v_stage6_count,
            v_stage7_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.

    Business purpose:
        Duplicate application_id values would duplicate latest-run output rows, archive rows, QA
        counts, comparison results, and evidence capture.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage7_distinct_app_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    IF v_stage7_distinct_app_count <> v_stage7_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_7_reason_code_assignment
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 10 failure: application_id uniqueness was not preserved. Stage 7 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage7_count,
            v_stage7_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required reason-code fields must be complete.

    Business purpose:
        Every row must be explainable before the latest-run table is materialized.

    Expected:
        primary_reason_code populated,
        primary_reason_family populated,
        reason_priority_rank positive,
        triggered_reason_code_list populated,
        reason_code_count at least 1.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE primary_reason_code IS NULL
       OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
       OR primary_reason_family IS NULL
       OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
       OR reason_priority_rank IS NULL
       OR reason_priority_rank <= 0
       OR triggered_reason_code_list IS NULL
       OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
       OR reason_code_count IS NULL
       OR reason_code_count < 1;

    IF v_required_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have missing or invalid required simulated reason-code fields.',
            v_required_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: APPROVE reason convention.

    Business interpretation:
        APPROVE rows should receive exactly one approval explanation code unless approval diagnostics
        are explicitly expanded in a future design.

    Expected:
        primary_reason_code = APPROVED_AS_REQUESTED
        primary_reason_family = APPROVAL
        reason_priority_rank = 900
        no secondary / tertiary reason
        triggered_reason_code_list = APPROVED_AS_REQUESTED
        reason_code_count = 1
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approval_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'APPROVE'
      AND (
            primary_reason_code <> 'APPROVED_AS_REQUESTED'
         OR primary_reason_family <> 'APPROVAL'
         OR reason_priority_rank <> 900
         OR secondary_reason_code IS NOT NULL
         OR tertiary_reason_code IS NOT NULL
         OR triggered_reason_code_list <> 'APPROVED_AS_REQUESTED'
         OR reason_code_count <> 1
      );

    IF v_approval_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % APPROVE row(s) violate approval reason-code conventions.',
            v_approval_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: COUNTEROFFER reason convention.

    Business interpretation:
        Final COUNTEROFFER rows must receive a COUNTEROFFER-family primary reason.

    Expected:
        primary_reason_family = COUNTEROFFER
        primary_reason_code begins with COUNTEROFFER_
        reason_priority_rank in 500–599
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            primary_reason_family <> 'COUNTEROFFER'
         OR primary_reason_code NOT LIKE 'COUNTEROFFER_%'
         OR reason_priority_rank < 500
         OR reason_priority_rank >= 600
      );

    IF v_counteroffer_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % COUNTEROFFER row(s) violate counteroffer reason-code conventions.',
            v_counteroffer_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: MANUAL_REVIEW reason convention.

    Business interpretation:
        Final MANUAL_REVIEW rows must receive a MANUAL_REVIEW-family primary reason.

    Expected:
        primary_reason_family = MANUAL_REVIEW
        primary_reason_code begins with MANUAL_REVIEW_
        reason_priority_rank in 300–399
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            primary_reason_family <> 'MANUAL_REVIEW'
         OR primary_reason_code NOT LIKE 'MANUAL_REVIEW_%'
         OR reason_priority_rank < 300
         OR reason_priority_rank >= 400
      );

    IF v_manual_review_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % MANUAL_REVIEW row(s) violate manual-review reason-code conventions.',
            v_manual_review_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DECLINE reason convention.

    Business interpretation:
        Final DECLINE rows must receive a POLICY_STOP-family primary reason.

    Expected:
        primary_reason_family = POLICY_STOP
        primary_reason_code begins with POLICY_STOP_
        reason_priority_rank in 100–199
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decline_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'DECLINE'
      AND (
            primary_reason_family <> 'POLICY_STOP'
         OR primary_reason_code NOT LIKE 'POLICY_STOP_%'
         OR reason_priority_rank < 100
         OR reason_priority_rank >= 200
      );

    IF v_decline_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % DECLINE row(s) violate policy-stop reason-code conventions.',
            v_decline_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: secondary and tertiary reason codes must not duplicate higher-priority fields.

    Business purpose:
        Preserve diagnostic usefulness in the reason-code fields.

    Expected:
        secondary_reason_code differs from primary_reason_code when populated.
        tertiary_reason_code differs from primary_reason_code and secondary_reason_code when populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_reason_uniqueness_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE (
            secondary_reason_code IS NOT NULL
            AND secondary_reason_code = primary_reason_code
          )
       OR (
            tertiary_reason_code IS NOT NULL
            AND (
                    tertiary_reason_code = primary_reason_code
                 OR tertiary_reason_code = secondary_reason_code
            )
          );

    IF v_reason_uniqueness_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have duplicate primary / secondary / tertiary reason-code values.',
            v_reason_uniqueness_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: reason-code family and prohibited-term controls.

    Business purpose:
        Protect interpretation boundaries.

        Simulated reason codes should remain internal strategy explanation codes and should not use
        terms reserved for external communication, regulatory notice, adverse-action handling, or
        fair-lending conclusions.

    Important:
        This is a terminology and boundary guardrail.

        It does not turn simulated reason codes into approved customer communication text.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_family_leakage_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE primary_reason_family NOT IN (
            'APPROVAL',
            'COUNTEROFFER',
            'MANUAL_REVIEW',
            'POLICY_STOP'
      )
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
          )
       OR COALESCE(primary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
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

    IF v_family_leakage_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have reason-code family alignment or prohibited-term boundary failures.',
            v_family_leakage_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must not exist yet in a clean full-script execution.

    Business purpose:
        Section 11 creates credit_decisioning_sim.strategy_decisions.

        Section 10 creates only the temporary reason-code staging table.

    Operating note:
        In a clean full script execution, Section 1 drops the replaceable latest-run output table
        before stages are rebuilt.

        If this gatekeeper fails, it usually means a user is running Section 10 after a prior
        latest-run output still exists. For a full rerun, start from Section 1 or rebuild through the
        intended Section 11 flow.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: final latest-run strategy_decisions table exists before Section 11.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 10.4 — LOCAL REASON-CODE SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 10 simulated reason-code layer.

BUSINESS PURPOSE:
    Let reviewers inspect how final simulated outcomes were explained before the final latest-run
    output table is materialized.

SQL PURPOSE:
    Display review outputs for:
        decision_outcome × primary_reason_code,
        primary_reason_family distribution,
        primary_reason_code distribution,
        secondary_reason_code distribution,
        tertiary_reason_code distribution,
        reason_code_count distribution,
        product × primary_reason_code,
        score band × primary_reason_code,
        strategy risk tier × primary_reason_code,
        requested PTI bucket × primary_reason_code,
        mixed-signal profile × primary_reason_code,
        counteroffer feasibility failure reason × primary_reason_code,
        decision path × primary_reason_code,
        decision resolution source × primary_reason_code.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        full Module 2 QA,
        latest-run output validation,
        archive validation,
        matched strategy comparison,
        strategy frontier evidence,
        or Validation Summary acceptance.

SQL TEACHING POINT:
    These SELECT statements are read-only diagnostics.

    GROUP BY summarizes explanation-code distribution.

    AVG fields help reviewers connect reason-code patterns to synthetic estimated-risk, affordability,
    and exposure-treatment behavior.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
10.4.0 Row count and reason-code completeness snapshot.

Purpose:
    Provide a compact first look at Section 10 staging integrity.

Expected:
    stage7_row_count = distinct_application_id_count.
    missing_primary_reason_code_rows = 0.
    missing_primary_reason_family_rows = 0.
    missing_triggered_reason_code_list_rows = 0.

Boundary:
    This is a local staging diagnostic, not full Module 2 QA.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS stage7_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    COUNT(*) FILTER (
        WHERE primary_reason_code IS NULL
           OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
    ) AS missing_primary_reason_code_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_family IS NULL
           OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
    ) AS missing_primary_reason_family_rows,

    COUNT(*) FILTER (
        WHERE triggered_reason_code_list IS NULL
           OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
    ) AS missing_triggered_reason_code_list_rows,

    MIN(reason_code_count) AS min_reason_code_count,
    AVG(reason_code_count) AS avg_reason_code_count,
    MAX(reason_code_count) AS max_reason_code_count

FROM tmp_m2_stage_7_reason_code_assignment;



/*-----------------------------------------------------------------------------------------------
10.4.1 Count by decision_outcome × primary_reason_code.

Purpose:
    Show the primary explanation distribution within each final simulated outcome.

Interpretation:
    This is the main diagnostic for understanding why final outcomes occurred.

Boundary:
    primary_reason_code is a simulated strategy explanation code, not external communication text.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY decision_outcome), 0),
        2
    ) AS pct_within_decision_outcome
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.2 Count by primary_reason_family.

Purpose:
    Confirm primary reason family distribution.

Expected:
    primary_reason_family should align to final decision_outcome:
        APPROVE       → APPROVAL
        COUNTEROFFER  → COUNTEROFFER
        MANUAL_REVIEW → MANUAL_REVIEW
        DECLINE       → POLICY_STOP
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_family,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_stage
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY primary_reason_family
ORDER BY primary_reason_family;



/*-----------------------------------------------------------------------------------------------
10.4.3 Count by primary_reason_code.

Purpose:
    Reveal the most common simulated strategy explanation codes.

Interpretation:
    This helps identify reason-code concentration.

    High concentration is not automatically a defect, but it should be interpreted in Section 14 QA
    and Section 16 evidence capture.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    primary_reason_family,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_stage
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    primary_reason_code,
    primary_reason_family
ORDER BY
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.4 Count by secondary_reason_code.

Purpose:
    Show secondary explanation diagnostics.

Interpretation:
    Secondary reasons are diagnostics only.

    NULL is expected when no second reason exists after final-outcome family filtering.
-----------------------------------------------------------------------------------------------*/

SELECT
    secondary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY secondary_reason_code
ORDER BY
    row_count DESC,
    secondary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.5 Count by tertiary_reason_code.

Purpose:
    Show tertiary explanation diagnostics.

Interpretation:
    Tertiary reasons are diagnostics only.

    NULL is expected when no third reason exists after final-outcome family filtering.
-----------------------------------------------------------------------------------------------*/

SELECT
    tertiary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY tertiary_reason_code
ORDER BY
    row_count DESC,
    tertiary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.6 Count by reason_code_count.

Purpose:
    Show how many simulated explanation candidates were active after final-outcome family filtering.

Interpretation:
    A reason_code_count greater than 1 means multiple same-family explanation drivers were available.

    It does not mean multiple final decisions.
-----------------------------------------------------------------------------------------------*/

SELECT
    reason_code_count,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY reason_code_count
ORDER BY reason_code_count;



/*-----------------------------------------------------------------------------------------------
10.4.7 Product × primary_reason_code.

Purpose:
    Show whether explanation patterns vary by product.

Credit risk interpretation:
    Product structure affects exposure, payment mechanics, LGD, affordability, approved Expected Loss,
    and counteroffer feasibility.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    product_type_policy_key,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.8 Score band × primary_reason_code.

Purpose:
    Show whether explanation patterns vary by score band.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

    Score band and synthetic estimated-risk proxy should generally align directionally while
    preserving realistic overlap.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    score_band_policy_key,
    decision_outcome,
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
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.9 Strategy risk tier × primary_reason_code.

Purpose:
    Show how synthetic estimated-risk tiers relate to simulated explanation codes.

Interpretation:
    Higher synthetic risk tiers should generally align with more review, counteroffer, or policy-stop
    reason patterns, subject to product, affordability, DTI, and exposure interactions.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    strategy_risk_tier,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
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
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.10 Requested PTI bucket × primary_reason_code.

Purpose:
    Show how requested affordability buckets relate to simulated explanation codes.

Interpretation:
    This uses requested-structure PTI, not approved PTI.

    approved_payment_to_income_ratio is populated only where final outcome convention supports it.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    requested_pti_bucket,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
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
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.11 Mixed-signal profile × primary_reason_code.

Purpose:
    Show how mixed-signal diagnostic profiles were explained after final outcome assignment.

Interpretation:
    Mixed-signal profile is diagnostic only.

    It does not automatically determine final decision_outcome or primary_reason_code.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    mixed_signal_profile_type,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
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
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.12 Counteroffer feasibility failure reason × primary_reason_code.

Purpose:
    Show how Section 8 counteroffer feasibility failure diagnostics map into Section 10 simulated
    strategy explanation codes.

Interpretation:
    Counteroffer feasibility failure reasons are Section 8 diagnostics.

    Section 10 maps them into simulated strategy explanation codes only when the final outcome is
    MANUAL_REVIEW or DECLINE.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    counteroffer_feasibility_failure_reason,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.13 Decision path × primary_reason_code.

Purpose:
    Connect internal final decision paths to simulated strategy explanation codes.

Interpretation:
    decision_path is an internal simulated strategy path label.

    primary_reason_code is the simulated strategy explanation code assigned after final outcome
    resolution.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_path,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    decision_path,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.14 Decision resolution source × primary_reason_code.

Purpose:
    Show whether the assigned primary explanation code aligns with the final outcome-resolution
    mechanism.

Interpretation:
    decision_resolution_source documents how final outcome resolution occurred.

    This query is useful for reviewing:
        confirmed preliminary approvals,
        confirmed preliminary declines,
        feasible counteroffers,
        failed counteroffers routed to review,
        failed counteroffers routed to decline,
        and residual fallback behavior.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_resolution_source,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_resolution_source,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    decision_resolution_source,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code;



/***************************************************************************************************
END OF SECTION 10 — SIMULATED REASON-CODE ASSIGNMENT LAYER

If execution reaches this point:
    1. Section 10 dependency preflight passed.
    2. tmp_m2_stage_7_reason_code_assignment exists.
    3. Row count is unchanged from tmp_m2_stage_6_final_decision_resolution.
    4. application_id remains unique.
    5. All Section 9 final decision, final flag, approved-exposure, approved-affordability, and
       approved-economics fields are preserved.
    6. primary_reason_code is populated for every row.
    7. primary_reason_family is populated for every row.
    8. triggered_reason_code_list is populated for every row.
    9. reason_priority_rank is populated and positive for every row.
    10. reason_code_count is populated and at least 1 for every row.
    11. APPROVE rows align to APPROVAL reason family.
    12. COUNTEROFFER rows align to COUNTEROFFER reason family.
    13. MANUAL_REVIEW rows align to MANUAL_REVIEW reason family.
    14. DECLINE rows align to POLICY_STOP reason family.
    15. secondary_reason_code and tertiary_reason_code are diagnostics only.
    16. Simulated reason codes are deterministic strategy explanation codes.
    17. Simulated reason codes are not customer communications, regulatory notices, production
        compliance determinations, adverse-action notices, fair-lending conclusions, or real applicant
        treatment explanations.
    18. The latest-run strategy_decisions table has not been created by Section 10.
    19. Archive persistence has not occurred in Section 10.

No latest-run strategy_decisions table has been created.
No strategy archive rows have been inserted.
No evidence rows have been inserted.
No matched strategy comparison has been performed.
No strategy frontier has been calculated.
No full Module 2 QA framework has been built.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 11 should consume tmp_m2_stage_7_reason_code_assignment and materialize the permanent
    latest-run strategy decision output table:
        credit_decisioning_sim.strategy_decisions

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00943 -->


---

<a id="c038-m00944"></a>

### C038-M00944

**Andrew** · 2026-05-10T00:32:11.655000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00944 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 11 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00944 -->


**Attachments in export:** `Pasted text(149).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_46.md) · [Next](Part_48.md)
