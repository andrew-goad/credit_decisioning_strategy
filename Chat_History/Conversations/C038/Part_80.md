# Module 2 Decision Simulator Build

## Part 80

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_79.md) · [Next](Part_81.md)

<a id="c038-m01564"></a>

### C038-M01564

**ChatGPT** · 2026-05-12T11:04:54.700726-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01564 -->
According to a document from 2026-05-12, Section 10 is the simulated reason-code assignment layer that consumes `tmp_m2_stage_6_final_decision_resolution` and creates `tmp_m2_stage_7_reason_code_assignment`; Section 11 then consumes that Section 10 output as the source for the permanent latest-run table. fileciteturn243file6 fileciteturn242file24

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

    Section 10 is the explanation-code layer.

    It explains final simulated strategy outcomes after Section 9 has already resolved:
        final decision_outcome,
        final decision_path,
        final decision flags,
        simulated_offer_exposure_flag,
        final approved exposure,
        final approved affordability proxy,
        and final approved Expected Loss.

SQL PURPOSE:
    1. Confirm required Section 10 dependency objects exist.
    2. Read from tmp_m2_stage_6_final_decision_resolution.
    3. Preserve all prior source, lineage, Module 2 strategy metadata, thresholds, segmentation,
       rule flags, preliminary routing diagnostics, exposure-treatment diagnostics, and final
       decision fields.
    4. Create one candidate simulated reason-code row per applicable rule / route / treatment driver.
    5. Filter reason-code candidates by final decision_outcome family.
    6. Deduplicate repeated candidate reason codes.
    7. Rank candidate reasons deterministically using governed priority ranges.
    8. Pivot ranked candidate reasons into:
            primary_reason_code
            secondary_reason_code
            tertiary_reason_code
            primary_reason_family
            triggered_reason_code_list
            reason_priority_rank
            reason_code_count
    9. Validate reason-code completeness, outcome-family alignment, reason-code priority ranges,
       reason-code uniqueness, and staging integrity.
    10. Confirm latest-run output creation and archive persistence remain deferred.
    11. Provide local reason-code diagnostics before Section 11 materializes the latest-run output.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the assigned explanation codes reflect the simulated strategy drivers behind
        APPROVE, COUNTEROFFER, MANUAL_REVIEW, and DECLINE outcomes.

    Model governance / validation reviewers:
        Confirm that reason codes are deterministic, bounded, internally consistent, and clearly
        labeled as simulated strategy explanation codes rather than customer-facing explanations.

    SQL reviewers:
        Confirm that the candidate → deduplicate → rank → pivot pattern is deterministic and avoids
        hiding overlapping strategy drivers inside one opaque CASE block.

    Portfolio / executive reviewers:
        Use Section 10 diagnostics to understand which strategy explanation themes dominate the
        current run before latest-run output, archive persistence, QA, frontier analysis, and evidence
        capture.

WHEN TO RUN THIS SECTION:
    Run Section 10 after:

        Section 9 — Final Decision Resolution Layer

    Section 10 should be run before:

        Section 11 — Latest-Run Strategy Decision Output Table

    Section 10 depends on:

        tmp_m2_stage_6_final_decision_resolution

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
        borderline diagnostics,
        and product-policy controls.

    This separation also makes the reason-code layer easier to validate because Section 10 does not
    recalculate final decisions or exposure fields.

WHY THE CANDIDATE → RANK → PIVOT PATTERN IS USED:
    A single row can have multiple valid explanatory drivers.

    Example:
        A final COUNTEROFFER row may be driven by:
            product exposure limits,
            requested affordability pressure,
            requested Expected Loss pressure,
            and elevated synthetic estimated-risk.

    A single large CASE expression would hide that overlap.

    Section 10 therefore:
        creates candidate reasons,
        deduplicates repeated candidate reason codes,
        ranks them deterministically,
        assigns primary / secondary / tertiary reason fields,
        and preserves the full triggered reason-code list.

OUTCOME-SPECIFIC FILTERING:
    Candidate reasons are filtered by final decision_outcome family so that:

        APPROVE rows receive APPROVAL reasons.
        COUNTEROFFER rows receive COUNTEROFFER reasons.
        MANUAL_REVIEW rows receive MANUAL_REVIEW reasons.
        DECLINE rows receive POLICY_STOP reasons.

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

APPROVAL REASON BOUNDARY:
    APPROVE rows receive:

        APPROVED_AS_REQUESTED

    This indicates that the synthetic applicant passed the simulated strategy conditions required for
    an as-requested positive offer-exposure outcome.

COUNTEROFFER REASON BOUNDARY:
    COUNTEROFFER reason codes explain which simulated strategy constraints drove reduced-exposure
    treatment.

    They do not imply:
        operational negotiation,
        customer acceptance,
        booked exposure,
        funded exposure,
        production approval,
        account creation,
        or real applicant treatment.

MANUAL REVIEW REASON BOUNDARY:
    MANUAL_REVIEW reason codes explain why the simulated strategy outcome remains unresolved.

    They do not represent completed operational review.

DECLINE / POLICY STOP REASON BOUNDARY:
    POLICY_STOP reason codes explain final simulated no-offer paths for synthetic applicants.

    They are simulated strategy explanation codes only.

REASON-CODE BOUNDARY:
    The fields created in Section 10 are simulated strategy explanation codes.

    They support:
        transparency,
        QA review,
        strategy interpretation,
        portfolio diagnostics,
        decision-path traceability,
        matched comparison,
        executive evidence capture,
        validation documentation,
        README summaries,
        and LinkedIn campaign storytelling.

    They are not:
        customer communications,
        regulatory notices,
        production compliance determinations,
        real applicant treatment explanations,
        adverse-action notices,
        or fair-lending conclusions.

SECONDARY AND TERTIARY REASONS:
    secondary_reason_code and tertiary_reason_code are additional diagnostics only.

    They do not change:
        decision_outcome,
        decision_path,
        approved exposure,
        approved PTI,
        approved Expected Loss,
        simulated offer exposure,
        or archive behavior.

TRIGGERED REASON LIST:
    triggered_reason_code_list contains all applicable candidate reason codes after filtering to the
    final decision_outcome family.

    This field is useful for QA and documentation because it preserves more explanatory detail than
    the primary / secondary / tertiary fields alone.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field and is interpreted as the synthetic
    estimated-PD proxy.

    Section 10 does not recalculate estimated_pd.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is approved-exposure Expected Loss after Module 2 final exposure
    treatment.

    Section 10 explains outcomes but does not recalculate either value.

COUNTEROFFER FEASIBILITY FAILURE BOUNDARY:
    counteroffer_feasibility_failure_reason is a Section 8 feasibility diagnostic.

    It is not a final simulated reason code.

    Section 10 may use that diagnostic to assign an internal MANUAL_REVIEW or POLICY_STOP explanation
    when failed counteroffer resolution produces final MANUAL_REVIEW or final DECLINE.

LATEST-RUN / ARCHIVE BOUNDARY:
    Section 10 creates only a temporary reason-code staging table.

    Section 10 does not create:

        credit_decisioning_sim.strategy_decisions

    Section 10 does not insert rows into:

        credit_decisioning_sim.strategy_decisions_archive

GOVERNANCE ROLE:
    Section 10 makes strategy explanations deterministic, reviewable, and tied to the final outcome
    taxonomy.

    It ensures the latest-run table is not materialized until every row has an outcome-family-aligned
    simulated explanation code.

COMMON MISUSE TO AVOID:
    Do not treat primary_reason_code as customer-facing language.
    Do not treat triggered_reason_code_list as adverse-action notices.
    Do not treat reason_priority_rank as a regulatory severity score.
    Do not treat reason codes as fair-lending conclusions.
    Do not infer production compliance approval from reason-code completeness.
    Do not use Section 10 to recalculate decisions or approved exposure.

***************************************************************************************************/



/***************************************************************************************************
SECTION 10.0 — SECTION 10 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 9 final decision-resolution output exists and is populated before simulated
    reason-code assignment begins.

    Section 10.0 answers:

        "Can Section 10 safely assign simulated reason codes from the final decision-resolution layer?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_6_final_decision_resolution exists.
    2. Confirm tmp_m2_stage_6_final_decision_resolution contains rows.
    3. Confirm application_id is unique before reason-code fields are added.
    4. Confirm final decision fields required for reason assignment are populated.
    5. Confirm final exposure convention fields required for reason diagnostics are present.
    6. Confirm Section 9 did not already create reason-code fields.
    7. Fail clearly if Section 9 has not been run.

BOUNDARY:
    Section 10.0 does not create reason codes.
    Section 10.0 does not create latest-run output.
    Section 10.0 does not insert archive rows.
    Section 10.0 does not modify persistent tables.

***************************************************************************************************/

DO $$
DECLARE
    v_stage6_exists BOOLEAN;
    v_stage6_row_count BIGINT;
    v_stage6_distinct_application_count BIGINT;
    v_required_stage6_gap_count BIGINT;
    v_existing_reason_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 9 final decision-resolution stage must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

    Business interpretation:
        Section 10 must consume the final decision-resolution layer, not preliminary routing,
        exposure treatment, or rule flags.
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
    Gatekeeper: Section 9 final decision-resolution stage must contain rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage6_row_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: tmp_m2_stage_6_final_decision_resolution contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id must be unique before reason-code assignment.

    Section 10 should add explanation fields only.

    It should not repair upstream row-grain problems.
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
    Gatekeeper: final decision-resolution fields required for reason assignment must be populated.

    Business interpretation:
        Simulated explanation codes should be assigned after final decision resolution, not before.

        Missing final outcome or final path fields would make the explanation layer ambiguous.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_stage6_gap_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_priority_rank IS NULL
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL

       OR approval_flag IS NULL
       OR counteroffer_flag IS NULL
       OR manual_review_flag IS NULL
       OR decline_flag IS NULL
       OR simulated_offer_exposure_flag IS NULL

       OR requested_amount IS NULL
       OR requested_payment_to_income_ratio IS NULL
       OR requested_expected_loss_amount IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL

       OR product_type_policy_key IS NULL
       OR score_band_policy_key IS NULL
       OR strategy_risk_tier IS NULL
       OR requested_pti_bucket IS NULL
       OR dti_bucket IS NULL
       OR requested_exposure_tier IS NULL
       OR requested_expected_loss_tier IS NULL

       OR hard_policy_stop_flag IS NULL
       OR synthetic_risk_decline_trigger_flag IS NULL
       OR dti_decline_trigger_flag IS NULL
       OR counteroffer_candidate_flag IS NULL
       OR manual_review_candidate_flag IS NULL
       OR clean_approval_candidate_flag IS NULL

       OR (
            decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
            AND approved_amount IS NULL
       )

       OR (
            decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
            AND approved_expected_loss_amount IS NULL
       );

    IF v_required_stage6_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % Section 9 row(s) are missing fields required for simulated reason-code assignment.',
            v_required_stage6_gap_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 9 should not already have reason-code fields.

    Business purpose:
        Protect the staged architecture.

        Reason-code assignment belongs in Section 10.

    SQL mechanics:
        pg_attribute inspects the physical columns of the temp table.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_existing_reason_column_count
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

    IF v_existing_reason_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: reason-code fields already exist before Section 10 assignment.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 10.1 — CLEAN RESET OF SECTION 10 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 10 reason-code assignment stage before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 10 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale reason-code rows to remain available to Section 11.

    Section 11 assumes tmp_m2_stage_7_reason_code_assignment reflects the current:
        Section 9 final decision-resolution output,
        final decision taxonomy,
        and reason-code assignment logic.

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
        deduplicates repeated candidate reason codes and keeps the best rank for each code.

    ranked_reasons:
        assigns deterministic rank order within application_id.

    reason_pivot:
        converts candidate rows back to one row per application_id.

    final_reason_assignment:
        preserves all Section 9 fields and adds final Section 10 reason-code fields.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 10 intentionally preserves all prior fields plus explanation-code diagnostics for Section
    11 latest-run materialization.

    Permanent output selection is handled later with an explicit field list in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_7_reason_code_assignment
ON COMMIT PRESERVE ROWS
AS
WITH reason_candidate_base AS (
    /***********************************************************************************************
    CTE: reason_candidate_base

    Purpose:
        Preserve the final decision-resolution row from Section 9.

    Boundary:
        No reason candidates are created in this CTE.
    ***********************************************************************************************/
    SELECT
        f.*
    FROM tmp_m2_stage_6_final_decision_resolution f
),

reason_candidates_raw AS (
    /***********************************************************************************************
    APPROVAL REASONS — PRIORITY 900–999

    APPROVE rows receive APPROVED_AS_REQUESTED as the required approval explanation code.

    Boundary:
        This is a simulated strategy explanation code, not external approval language.
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

    A final COUNTEROFFER row may have several valid drivers. The ranking rules decide which driver is
    primary while preserving all candidates in triggered_reason_code_list.
    ***********************************************************************************************/

    UNION ALL

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

    SELECT
        application_id,
        'COUNTEROFFER_AFFORDABILITY_ADJUSTMENT',
        'COUNTEROFFER',
        510,
        'requested_pti_or_pti_target_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_affordability_candidate_flag IS TRUE
         OR requested_pti_counteroffer_candidate_flag IS TRUE
         OR requested_pti_review_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
         OR (
                counteroffer_pti_target_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_pti_target_amount = counteroffer_raw_max_feasible_amount
         )
      )

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_EXPECTED_LOSS_LIMIT',
        'COUNTEROFFER',
        520,
        'requested_expected_loss_or_approved_el_cap_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_expected_loss_candidate_flag IS TRUE
         OR requested_el_counteroffer_candidate_flag IS TRUE
         OR requested_el_review_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
         OR (
                counteroffer_el_cap_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_el_cap_amount = counteroffer_raw_max_feasible_amount
         )
      )

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_ELEVATED_SYNTHETIC_RISK',
        'COUNTEROFFER',
        530,
        'synthetic_risk_counteroffer_band'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            synthetic_risk_counteroffer_band_flag IS TRUE
         OR counteroffer_risk_band_eligible_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_MULTIPLE_CONSTRAINTS',
        'COUNTEROFFER',
        590,
        'multiple_counteroffer_candidate_drivers'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND COALESCE(counteroffer_candidate_trigger_count, 0) > 1

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_FEASIBLE_REDUCED_EXPOSURE',
        'COUNTEROFFER',
        599,
        'counteroffer_feasibility_passed_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'


    /***********************************************************************************************
    MANUAL REVIEW REASONS — PRIORITY 300–399

    These reasons explain unresolved final MANUAL_REVIEW outcomes.

    MANUAL_REVIEW can result from:
        failed counteroffer routed to review;
        severe requested-structure stress;
        synthetic-risk review band;
        affordability review;
        DTI review;
        requested Expected Loss review;
        mixed-signal profile;
        borderline threshold proximity;
        supplemental review diagnostics;
        residual strategy review.
    ***********************************************************************************************/

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_FAILED_COUNTEROFFER',
        'MANUAL_REVIEW',
        300,
        'failed_counteroffer_resolution_to_manual_review'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'
         OR decision_path = 'COUNTEROFFER_NOT_FEASIBLE_REVIEW'
         OR (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS FALSE
            AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
         )
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_SEVERE_REQUESTED_STRUCTURE',
        'MANUAL_REVIEW',
        310,
        'severe_requested_structure_review'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            decision_path = 'SEVERE_REQUESTED_STRUCTURE_REVIEW'
         OR severe_requested_structure_trigger_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW',
        'MANUAL_REVIEW',
        320,
        'synthetic_risk_review_band'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_risk_trigger_flag IS TRUE
         OR synthetic_risk_review_band_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_AFFORDABILITY_REVIEW',
        'MANUAL_REVIEW',
        330,
        'requested_pti_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_affordability_trigger_flag IS TRUE
         OR requested_pti_review_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_DTI_REVIEW',
        'MANUAL_REVIEW',
        340,
        'dti_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_dti_trigger_flag IS TRUE
         OR dti_review_trigger_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_EXPECTED_LOSS_REVIEW',
        'MANUAL_REVIEW',
        350,
        'requested_expected_loss_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_expected_loss_trigger_flag IS TRUE
         OR requested_el_review_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_MIXED_SIGNAL_PROFILE',
        'MANUAL_REVIEW',
        360,
        'mixed_signal_profile'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_mixed_signal_trigger_flag IS TRUE
         OR mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_BORDERLINE_PROFILE',
        'MANUAL_REVIEW',
        370,
        'borderline_profile_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_borderline_trigger_flag IS TRUE
         OR borderline_profile_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_HIGH_UTILIZATION',
        'MANUAL_REVIEW',
        380,
        'high_utilization_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND high_utilization_review_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_LOW_SCORE',
        'MANUAL_REVIEW',
        385,
        'low_score_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND low_score_review_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_RESIDUAL_STRATEGY_REVIEW',
        'MANUAL_REVIEW',
        399,
        'manual_review_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'


    /***********************************************************************************************
    POLICY STOP / DECLINE REASONS — PRIORITY 100–199

    These reasons explain final simulated no-offer outcomes.

    POLICY_STOP codes are internal simulated strategy explanation codes only.
    They are not adverse-action notices.
    ***********************************************************************************************/

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_BANKRUPTCY',
        'POLICY_STOP',
        100,
        'bankruptcy_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND bankruptcy_policy_stop_flag IS TRUE

    UNION ALL

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

    SELECT
        application_id,
        'POLICY_STOP_SEVERE_DELINQUENCY',
        'POLICY_STOP',
        120,
        'severe_delinquency_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND severe_delinquency_policy_stop_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_SEVERE_SYNTHETIC_RISK',
        'POLICY_STOP',
        130,
        'synthetic_risk_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND synthetic_risk_decline_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_SEVERE_DTI',
        'POLICY_STOP',
        140,
        'dti_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND dti_decline_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_FAILED_COUNTEROFFER',
        'POLICY_STOP',
        150,
        'failed_counteroffer_resolution_to_decline'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'
         OR decision_path = 'COUNTEROFFER_NOT_FEASIBLE_DECLINE'
         OR (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS FALSE
            AND failed_counteroffer_resolution = 'DECLINE'
         )
      )

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_REQUESTED_PTI_SEVERE',
        'POLICY_STOP',
        160,
        'requested_pti_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND requested_pti_decline_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_REQUESTED_EL_SEVERE',
        'POLICY_STOP',
        170,
        'requested_expected_loss_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND requested_el_decline_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_EXPOSURE_POLICY',
        'POLICY_STOP',
        180,
        'exposure_policy_stop_or_extreme_exposure'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            exposure_policy_stop_candidate_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR requested_exposure_below_product_minimum_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_NO_OFFER',
        'POLICY_STOP',
        199,
        'decline_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
),

reason_candidates AS (
    /***********************************************************************************************
    CTE: reason_candidates

    Purpose:
        Deduplicate candidate reasons.

    Why deduplication matters:
        The same conceptual driver can be created by multiple related trigger fields.

        Example:
            requested Expected Loss pressure and approved EL cap binding can both support
            COUNTEROFFER_EXPECTED_LOSS_LIMIT.

    SQL mechanics:
        GROUP BY application_id / reason code / family.
        MIN(priority) retains the strongest rank.
        STRING_AGG preserves source diagnostics for internal review if needed.
    ***********************************************************************************************/
    SELECT
        application_id,
        candidate_reason_code,
        candidate_reason_family,
        MIN(candidate_reason_priority_rank) AS candidate_reason_priority_rank,

        STRING_AGG(
            DISTINCT candidate_reason_source,
            '|' ORDER BY candidate_reason_source
        ) AS candidate_reason_source_list

    FROM reason_candidates_raw

    GROUP BY
        application_id,
        candidate_reason_code,
        candidate_reason_family
),

ranked_reasons AS (
    /***********************************************************************************************
    CTE: ranked_reasons

    Purpose:
        Rank reason candidates within each application.

    SQL mechanics:
        ROW_NUMBER provides deterministic primary / secondary / tertiary ordering.

        Tie-breakers:
            candidate_reason_priority_rank,
            candidate_reason_family,
            candidate_reason_code.

    Interpretation:
        Lower candidate_reason_priority_rank means higher priority.
    ***********************************************************************************************/
    SELECT
        rc.*,

        ROW_NUMBER() OVER (
            PARTITION BY rc.application_id
            ORDER BY
                rc.candidate_reason_priority_rank,
                rc.candidate_reason_family,
                rc.candidate_reason_code
        ) AS reason_rank

    FROM reason_candidates rc
),

reason_pivot AS (
    /***********************************************************************************************
    CTE: reason_pivot

    Purpose:
        Pivot ranked reason candidates back to one row per application_id.

    SQL mechanics:
        MAX(CASE WHEN reason_rank = n THEN candidate_reason_code END) creates primary, secondary,
        and tertiary reason fields.

        STRING_AGG preserves the full deterministic triggered reason list.
    ***********************************************************************************************/
    SELECT
        rr.application_id,

        MAX(CASE WHEN rr.reason_rank = 1 THEN rr.candidate_reason_code END)
            AS primary_reason_code,

        MAX(CASE WHEN rr.reason_rank = 2 THEN rr.candidate_reason_code END)
            AS secondary_reason_code,

        MAX(CASE WHEN rr.reason_rank = 3 THEN rr.candidate_reason_code END)
            AS tertiary_reason_code,

        MAX(CASE WHEN rr.reason_rank = 1 THEN rr.candidate_reason_family END)
            AS primary_reason_family,

        STRING_AGG(
            rr.candidate_reason_code,
            '|' ORDER BY
                rr.reason_rank,
                rr.candidate_reason_priority_rank,
                rr.candidate_reason_code
        ) AS triggered_reason_code_list,

        MAX(CASE WHEN rr.reason_rank = 1 THEN rr.candidate_reason_priority_rank END)
            AS reason_priority_rank,

        COUNT(*) AS reason_code_count

    FROM ranked_reasons rr

    GROUP BY
        rr.application_id
),

final_reason_assignment AS (
    /***********************************************************************************************
    CTE: final_reason_assignment

    Purpose:
        Preserve all Section 9 fields and add final simulated reason-code fields.

    Boundary:
        This still creates only a temporary staging table.

        Permanent latest-run output is created in Section 11.
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
SECTION 10.3 — LOCAL FAIL-FAST CHECKS FOR SIMULATED REASON CODES
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 10 produced complete, deterministic, outcome-family-aligned simulated
    explanation codes before Section 11 materializes the latest-run output.

    Section 10.3 answers:

        "Did Section 10 preserve applicant grain, assign complete reason-code fields, align reason
         family to final outcome, and avoid creating latest-run or archive output early?"

SQL PURPOSE:
    1. Confirm row count is unchanged from tmp_m2_stage_6_final_decision_resolution.
    2. Confirm application_id remains unique.
    3. Confirm required reason-code fields are complete.
    4. Confirm APPROVE reason-code convention.
    5. Confirm COUNTEROFFER reason-code convention.
    6. Confirm MANUAL_REVIEW reason-code convention.
    7. Confirm DECLINE reason-code convention.
    8. Confirm primary reason family reconciles to final decision outcome.
    9. Confirm reason-code priority range reconciles to reason family.
    10. Confirm reason-code count and triggered list are coherent.
    11. Confirm Section 10 did not create permanent latest-run output.
    12. Confirm Section 10 did not insert archive rows.

LOCAL GATEKEEPER BOUNDARY:
    These are local Section 10 staging gatekeepers only.

    They are not:
        latest-run materialization validation,
        archive validation,
        matched strategy comparison,
        full Module 2 QA,
        strategy frontier review,
        or Validation Summary evidence by themselves.

***************************************************************************************************/

DO $$
DECLARE
    v_stage6_count BIGINT;
    v_stage7_count BIGINT;
    v_stage7_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    v_required_reason_failure_count BIGINT;
    v_approval_reason_failure_count BIGINT;
    v_counteroffer_reason_failure_count BIGINT;
    v_manual_review_reason_failure_count BIGINT;
    v_decline_reason_failure_count BIGINT;
    v_reason_family_alignment_failure_count BIGINT;
    v_reason_priority_range_failure_count BIGINT;
    v_reason_list_coherence_failure_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 9 to Section 10.

    Business purpose:
        Section 10 should add reason-code fields only.

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

    Final COUNTEROFFER rows must receive a COUNTEROFFER-family primary reason.
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

    Final MANUAL_REVIEW rows must receive a MANUAL_REVIEW-family primary reason.
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

    Final DECLINE rows must receive a POLICY_STOP-family primary reason.
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
    Gatekeeper: primary reason family must reconcile to final decision_outcome.

    Expected mapping:
        APPROVE       → APPROVAL
        COUNTEROFFER  → COUNTEROFFER
        MANUAL_REVIEW → MANUAL_REVIEW
        DECLINE       → POLICY_STOP
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_reason_family_alignment_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE (
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

    IF v_reason_family_alignment_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have primary_reason_family misaligned to decision_outcome.',
            v_reason_family_alignment_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: reason priority rank must fall inside the expected range for the primary family.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_reason_priority_range_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE (
            primary_reason_family = 'POLICY_STOP'
            AND reason_priority_rank NOT BETWEEN 100 AND 199
          )
       OR (
            primary_reason_family = 'MANUAL_REVIEW'
            AND reason_priority_rank NOT BETWEEN 300 AND 399
          )
       OR (
            primary_reason_family = 'COUNTEROFFER'
            AND reason_priority_rank NOT BETWEEN 500 AND 599
          )
       OR (
            primary_reason_family = 'APPROVAL'
            AND reason_priority_rank NOT BETWEEN 900 AND 999
          );

    IF v_reason_priority_range_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have reason_priority_rank outside the expected family range.',
            v_reason_priority_range_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: reason-code count and triggered reason list must be coherent.

    This is a practical string-list check.

    It verifies:
        reason_code_count is positive;
        primary_reason_code appears in triggered_reason_code_list;
        secondary_reason_code appears when populated;
        tertiary_reason_code appears when populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_reason_list_coherence_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE reason_code_count < 1
       OR triggered_reason_code_list NOT LIKE '%' || primary_reason_code || '%'
       OR (
            secondary_reason_code IS NOT NULL
            AND triggered_reason_code_list NOT LIKE '%' || secondary_reason_code || '%'
          )
       OR (
            tertiary_reason_code IS NOT NULL
            AND triggered_reason_code_list NOT LIKE '%' || tertiary_reason_code || '%'
          );

    IF v_reason_list_coherence_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have incoherent triggered_reason_code_list / reason_code_count fields.',
            v_reason_list_coherence_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output must still be deferred to Section 11.

    This protects the run sequence.

    If strategy_decisions already exists here, the user may be rerunning Section 10 after Section 11
    without clearing the latest-run output.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: credit_decisioning_sim.strategy_decisions exists before Section 11 materialization. Drop/rebuild latest-run output through Section 11 or rerun from Section 1.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 10.4 — LOCAL SIMULATED REASON-CODE SANITY CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide lightweight diagnostics for Section 10 simulated reason-code assignment.

    Section 10.4 answers:

        "What explanation-code themes were assigned, and do they align with final simulated outcomes,
         decision paths, products, score bands, and exposure-treatment diagnostics?"

SQL PURPOSE:
    Display review outputs for:
        reason-code assignment row count,
        final decision outcome × reason family,
        primary reason-code distribution,
        product × primary reason-code,
        score band × primary reason-code,
        product × score × primary reason-code,
        counteroffer reason-code drivers,
        manual-review reason-code drivers,
        decline / policy-stop reason-code drivers,
        failed-counteroffer failure reason × primary reason-code,
        decision path × primary reason-code,
        decision resolution source × primary reason-code,
        mixed-signal profile × primary reason-code,
        borderline profile × primary reason-code,
        sample reason-code trace,
        and one compact readiness summary.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        final latest-run validation,
        archive validation,
        matched strategy comparison,
        strategy frontier evidence,
        full Module 2 QA,
        customer communication language,
        adverse-action language,
        or Validation Summary acceptance.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
10.4.1 Row count and distinct application_id count.

Purpose:
    Confirm the reason-code layer is still one row per application.

Expected:
    stage7_row_count = distinct_application_id_count.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS stage7_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_7_reason_code_assignment;



/*-----------------------------------------------------------------------------------------------
10.4.2 Final decision outcome × primary reason family.

Purpose:
    Confirm outcome-family alignment.

Expected:
    APPROVE       → APPROVAL
    COUNTEROFFER  → COUNTEROFFER
    MANUAL_REVIEW → MANUAL_REVIEW
    DECLINE       → POLICY_STOP
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    primary_reason_family,
    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY decision_outcome), 0),
        2
    ) AS pct_within_decision_outcome

FROM tmp_m2_stage_7_reason_code_assignment

GROUP BY
    decision_outcome,
    primary_reason_family

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family;



/*-----------------------------------------------------------------------------------------------
10.4.3 Primary reason-code distribution.

Purpose:
    Show the main simulated explanation-code distribution.

Interpretation:
    This is the central reason-code QA output for the current staging layer.

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
    ) AS pct_of_stage

FROM tmp_m2_stage_7_reason_code_assignment

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
10.4.4 Reason-code count distribution.

Purpose:
    Show how many explanation drivers were available per row after outcome-family filtering.

Interpretation:
    Higher reason_code_count means more overlapping same-family explanation drivers existed.

    It does not mean the final outcome is more severe.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    reason_code_count,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_outcome,
    reason_code_count
ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    reason_code_count;



/*-----------------------------------------------------------------------------------------------
10.4.5 Product × primary reason-code distribution.

Purpose:
    Review whether explanation-code themes concentrate by product.

Interpretation:
    Product concentration may reflect product caps, LGD, requested exposure, PTI, requested Expected
    Loss, and counteroffer feasibility behavior.
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
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code
ORDER BY
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.6 Score band × primary reason-code distribution.

Purpose:
    Review whether explanation-code themes concentrate by borrower-quality segment.

Boundary:
    Score band supports interpretation but is not itself a reason-code family.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_7_reason_code_assignment
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
10.4.7 Product × score × primary reason-code distribution.

Purpose:
    Review the core product × score segment explanation-code matrix.

Interpretation:
    This previews the segment-level evidence that later sections use for executive story capture.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_rows
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    primary_reason_family,
    primary_reason_code
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
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.8 Counteroffer primary reason-code distribution.

Purpose:
    Review why final COUNTEROFFER rows were explained as reduced-exposure treatments.

Boundary:
    These are simulated strategy explanation codes, not customer-facing counteroffer explanations.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS final_counteroffer_rows,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,
    AVG(exposure_reduction_pct) AS avg_exposure_reduction_pct,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM tmp_m2_stage_7_reason_code_assignment
WHERE decision_outcome = 'COUNTEROFFER'
GROUP BY primary_reason_code
ORDER BY
    final_counteroffer_rows DESC,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.9 Manual-review primary reason-code distribution.

Purpose:
    Review why final MANUAL_REVIEW rows remained unresolved.

Boundary:
    MANUAL_REVIEW is unresolved simulated strategy routing.

    It is not completed operational review.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS final_manual_review_rows,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_7_reason_code_assignment
WHERE decision_outcome = 'MANUAL_REVIEW'
GROUP BY primary_reason_code
ORDER BY
    final_manual_review_rows DESC,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.10 Decline / policy-stop primary reason-code distribution.

Purpose:
    Review why final DECLINE rows were explained as simulated no-offer outcomes.

Boundary:
    POLICY_STOP reason codes are internal simulated explanation codes only.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS final_decline_rows,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_7_reason_code_assignment
WHERE decision_outcome = 'DECLINE'
GROUP BY primary_reason_code
ORDER BY
    final_decline_rows DESC,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.11 Triggered reason-code list sample by outcome.

Purpose:
    Show compact examples of how primary, secondary, tertiary, and full triggered reason lists appear.

Interpretation:
    triggered_reason_code_list preserves all same-family reason candidates after filtering.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    application_id,
    product_type_policy_key,
    score_band_policy_key,
    decision_path,
    decision_resolution_source,

    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    primary_reason_family,
    reason_priority_rank,
    reason_code_count,
    triggered_reason_code_list

FROM tmp_m2_stage_7_reason_code_assignment

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_code,
    application_id

LIMIT 100;



/*-----------------------------------------------------------------------------------------------
10.4.12 Counteroffer feasibility failure reason × primary_reason_code.

Purpose:
    Review how failed preliminary counteroffer diagnostics align to final explanation codes.

Boundary:
    counteroffer_feasibility_failure_reason is a feasibility diagnostic, not a final reason code.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE
GROUP BY
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    primary_reason_code
ORDER BY
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.13 Decision path × primary_reason_code.

Purpose:
    Review whether the assigned primary explanation code aligns with the final internal decision path.

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
    Review whether the assigned primary explanation code aligns with the final resolution source.

Interpretation:
    decision_resolution_source documents how final outcome resolution occurred.
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



/*-----------------------------------------------------------------------------------------------
10.4.15 Mixed-signal profile × primary_reason_code.

Purpose:
    Review how realistic overlapping applicant profiles explain final outcomes.

Boundary:
    mixed_signal_profile_type remains diagnostic.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(reason_code_count) AS avg_reason_code_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    mixed_signal_profile_type,
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
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.16 Borderline profile flag × primary_reason_code.

Purpose:
    Review whether threshold-adjacent profiles concentrate in particular explanation-code themes.

Boundary:
    borderline_profile_flag uses governed threshold proximity logic and remains diagnostic.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(reason_code_count) AS avg_reason_code_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    borderline_profile_flag,
    primary_reason_family,
    primary_reason_code
ORDER BY
    borderline_profile_flag,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.17 Reason-code priority-rank distribution.

Purpose:
    Confirm priority ranks stay inside the intended family ranges.

Expected:
    POLICY_STOP   100–199
    MANUAL_REVIEW 300–399
    COUNTEROFFER  500–599
    APPROVAL      900–999
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_family,
    reason_priority_rank,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    primary_reason_family,
    reason_priority_rank,
    primary_reason_code
ORDER BY
    reason_priority_rank,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
10.4.18 Section 10 readiness summary.

Purpose:
    Provide one compact readiness row for the reason-code assignment stage.

Expected:
    section_10_reason_code_assignment_status =
        SECTION_10_REASON_CODES_READY_FOR_LATEST_RUN_MATERIALIZATION

Interpretation:
    This confirms only that Section 10 is ready for Section 11.

    It does not validate latest-run materialization, archive persistence, matched comparison,
    Section 14 QA, Section 15 frontier, or Section 16 evidence capture.
-----------------------------------------------------------------------------------------------*/

WITH reason_code_summary AS (
    SELECT
        COUNT(*) AS stage7_row_count,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR triggered_reason_code_list IS NULL
               OR reason_priority_rank IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
        ) AS required_reason_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
              AND primary_reason_family <> 'APPROVAL'
        ) AS approve_family_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND primary_reason_family <> 'COUNTEROFFER'
        ) AS counteroffer_family_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND primary_reason_family <> 'MANUAL_REVIEW'
        ) AS manual_review_family_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND primary_reason_family <> 'POLICY_STOP'
        ) AS decline_family_gap_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_family = 'POLICY_STOP'
              AND reason_priority_rank NOT BETWEEN 100 AND 199
        ) AS policy_stop_priority_gap_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_family = 'MANUAL_REVIEW'
              AND reason_priority_rank NOT BETWEEN 300 AND 399
        ) AS manual_review_priority_gap_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_family = 'COUNTEROFFER'
              AND reason_priority_rank NOT BETWEEN 500 AND 599
        ) AS counteroffer_priority_gap_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_family = 'APPROVAL'
              AND reason_priority_rank NOT BETWEEN 900 AND 999
        ) AS approval_priority_gap_rows,

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

        COUNT(DISTINCT primary_reason_code) AS distinct_primary_reason_code_count

    FROM tmp_m2_stage_7_reason_code_assignment
)

SELECT
    stage7_row_count,
    distinct_application_id_count,

    required_reason_gap_rows,
    approve_family_gap_rows,
    counteroffer_family_gap_rows,
    manual_review_family_gap_rows,
    decline_family_gap_rows,

    policy_stop_priority_gap_rows,
    manual_review_priority_gap_rows,
    counteroffer_priority_gap_rows,
    approval_priority_gap_rows,

    final_approve_rows,
    final_counteroffer_rows,
    final_manual_review_rows,
    final_decline_rows,
    distinct_primary_reason_code_count,

    CASE
        WHEN stage7_row_count > 0
         AND stage7_row_count = distinct_application_id_count
         AND required_reason_gap_rows = 0
         AND approve_family_gap_rows = 0
         AND counteroffer_family_gap_rows = 0
         AND manual_review_family_gap_rows = 0
         AND decline_family_gap_rows = 0
         AND policy_stop_priority_gap_rows = 0
         AND manual_review_priority_gap_rows = 0
         AND counteroffer_priority_gap_rows = 0
         AND approval_priority_gap_rows = 0
            THEN 'SECTION_10_REASON_CODES_READY_FOR_LATEST_RUN_MATERIALIZATION'
        ELSE 'REVIEW_SECTION_10_REASON_CODES_BEFORE_LATEST_RUN_MATERIALIZATION'
    END AS section_10_reason_code_assignment_status

FROM reason_code_summary;



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
    7. secondary_reason_code and tertiary_reason_code are populated when additional diagnostics exist.
    8. primary_reason_family is populated for every row.
    9. triggered_reason_code_list is populated for every row.
    10. reason_priority_rank is populated and positive for every row.
    11. reason_code_count is populated and at least 1 for every row.
    12. APPROVE rows align to APPROVAL reason family.
    13. COUNTEROFFER rows align to COUNTEROFFER reason family.
    14. MANUAL_REVIEW rows align to MANUAL_REVIEW reason family.
    15. DECLINE rows align to POLICY_STOP reason family.
    16. reason_priority_rank falls inside the expected range for the primary reason family.
    17. APPROVE rows receive the locked APPROVED_AS_REQUESTED convention.
    18. triggered_reason_code_list preserves all applicable same-family explanation candidates.
    19. secondary_reason_code and tertiary_reason_code are diagnostics only.
    20. Simulated reason codes are deterministic strategy explanation codes.
    21. Simulated reason codes are not customer communications, regulatory notices, adverse-action
        notices, production compliance determinations, fair-lending conclusions, or real applicant
        treatment explanations.
    22. Section 10 local reason-code diagnostics are available for review.

Section 10 established:
    1. The final simulated explanation-code staging layer.
    2. Outcome-family-filtered reason-code assignment.
    3. Deterministic reason-code ranking.
    4. Primary, secondary, and tertiary reason-code diagnostics.
    5. Full triggered reason-code list.
    6. Reason-code family alignment to final decision_outcome.
    7. The staging foundation Section 11 needs for latest-run materialization.

No latest-run strategy_decisions table has been created.
No strategy archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full Module 2 QA framework has been built.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 11 should consume tmp_m2_stage_7_reason_code_assignment and materialize the permanent
    latest-run output table:

        credit_decisioning_sim.strategy_decisions

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01564 -->


---

<a id="c038-m01566"></a>

### C038-M01566

**Andrew** · 2026-05-12T11:11:59.454000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01566 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 11 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01566 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_79.md) · [Next](Part_81.md)
