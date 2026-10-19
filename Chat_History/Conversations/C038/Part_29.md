# Module 2 Decision Simulator Build

## Part 29

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_28.md) · [Next](Part_30.md)

<a id="c038-m00696"></a>

### C038-M00696

**ChatGPT** · 2026-05-09T16:48:21.825567-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00696 -->
Using your uploaded Section 10 as the base, this version hardens commentary while preserving the accepted reason-candidate → rank → pivot pattern and the required Section 10 gatekeeper / diagnostic structure. fileciteturn32file19turn32file15

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

SQL PURPOSE:
    1. Read from tmp_m2_stage_6_final_decision_resolution.
    2. Preserve all prior source, lineage, Module 2 strategy metadata, thresholds, segmentation,
       rule flags, preliminary routing diagnostics, exposure-treatment diagnostics, and final
       decision fields.
    3. Create one candidate simulated reason-code row per applicable rule / route / treatment driver.
    4. Filter reason-code candidates by final decision_outcome family.
    5. Rank candidate reasons deterministically using governed priority ranges.
    6. Pivot ranked candidates into:
            primary_reason_code
            secondary_reason_code
            tertiary_reason_code
            primary_reason_family
            triggered_reason_code_list
            reason_priority_rank
            reason_code_count
    7. Validate reason-code completeness, outcome-family alignment, reason-code uniqueness, and
       staging integrity.
    8. Keep latest-run output creation and archive persistence deferred.

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
SECTION 10.1 — CLEAN RESET OF SECTION 10 STAGING OBJECT
****************************************************************************************************

PURPOSE:
    Drop the Section 10 reason-code staging object before rebuilding it.

WHY THIS MATTERS:
    A partial rerun should not allow stale simulated reason-code rows to remain available to
    Section 11 latest-run output creation.

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

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_7_reason_code_assignment
ON COMMIT PRESERVE ROWS
AS
WITH reason_candidate_base AS (
    SELECT
        f.*
    FROM tmp_m2_stage_6_final_decision_resolution f
),

reason_candidates_raw AS (

    /***********************************************************************************************
    APPROVAL REASONS — PRIORITY 900–999

    APPROVE rows receive APPROVED_AS_REQUESTED as the required approval explanation code.
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

    COUNTEROFFER_MULTIPLE_CONSTRAINTS is intentionally lower priority than specific counteroffer
    drivers so it generally appears as a secondary or tertiary diagnostic when multiple driver
    families are active.
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

    Specific failed-counteroffer feasibility diagnostics rank above generic failed-counteroffer
    review routing. This preserves useful counteroffer feasibility traceability.
    ***********************************************************************************************/

    UNION ALL

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
    They are not customer communications or regulatory notices.
    ***********************************************************************************************/

    UNION ALL

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
        'POLICY_STOP_RECENT_DELINQUENCY',
        'POLICY_STOP',
        120,
        'severe_delinquency_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND severe_delinquency_policy_stop_flag IS TRUE

    UNION ALL

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

/*-----------------------------------------------------------------------------------------------
Deduplicate reason candidates.

A row can satisfy the same candidate reason through multiple related diagnostics. Deduplication keeps
the triggered reason list readable while preserving deterministic ranking.
-----------------------------------------------------------------------------------------------*/
reason_candidates AS (
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

/*-----------------------------------------------------------------------------------------------
Rank candidate reasons.

The primary reason is the lowest-ranked candidate reason within the final decision_outcome family.
Ties are resolved alphabetically by candidate_reason_code for deterministic output.
-----------------------------------------------------------------------------------------------*/
ranked_reasons AS (
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

/*-----------------------------------------------------------------------------------------------
Pivot ranked reason candidates back to one row per application_id.

triggered_reason_code_list contains all candidate codes after final-outcome family filtering.
secondary_reason_code and tertiary_reason_code are diagnostic only.
-----------------------------------------------------------------------------------------------*/
reason_pivot AS (
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

/*-----------------------------------------------------------------------------------------------
Final Section 10 staging table.

This preserves all final decision-resolution fields and adds simulated reason-code assignment fields.
-----------------------------------------------------------------------------------------------*/
final_reason_assignment AS (
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

LOCAL GATEKEEPER BOUNDARY:
    These are local Section 10 staging gatekeepers only.

    They are not:
        full Module 2 QA,
        archive validation,
        matched strategy comparison,
        or final documentation evidence.

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
    v_family_leakage_failure_count BIGINT;
    v_reason_uniqueness_failure_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 9 to Section 10.
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

    Every row must be explainable.
    APPROVE rows receive APPROVED_AS_REQUESTED.
    Non-approval rows receive an outcome-family-aligned strategy explanation code.
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

    APPROVE rows should receive exactly one approval explanation code unless approval diagnostics are
    explicitly expanded in a future design.
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
    Gatekeeper: secondary and tertiary reason codes must not duplicate higher-priority fields.

    This preserves diagnostic usefulness in the reason-code list.
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

    This protects interpretation boundaries. Simulated reason codes should remain strategy
    explanation codes and should not contain terms reserved for external communication or compliance
    conclusions.
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

    Section 11 creates credit_decisioning_sim.strategy_decisions.
    Section 10 creates only the temporary reason-code staging table.
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

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        full Module 2 QA,
        latest-run output validation,
        archive validation,
        matched strategy comparison,
        or Validation Summary acceptance.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
10.4.1 Count by decision_outcome × primary_reason_code.

Interpretation:
    Shows the primary explanation distribution within each final simulated outcome.
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

Interpretation:
    primary_reason_family should align to final decision_outcome.
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

Interpretation:
    Reveals the most common simulated strategy explanation codes.
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

Interpretation:
    Secondary reasons are diagnostics only. NULL is expected when no second reason exists.
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

Interpretation:
    Tertiary reasons are diagnostics only. NULL is expected when no third reason exists.
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

Interpretation:
    reason_code_count shows how many simulated explanation candidates were active after final-outcome
    family filtering.
-----------------------------------------------------------------------------------------------*/
SELECT
    reason_code_count,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY reason_code_count
ORDER BY reason_code_count;


/*-----------------------------------------------------------------------------------------------
10.4.7 Product × primary_reason_code.

Interpretation:
    Shows whether explanation patterns vary by product.
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

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.
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

Interpretation:
    Shows how synthetic estimated-risk tiers relate to simulated explanation codes.
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

Interpretation:
    Uses requested-structure PTI, not approved PTI.
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

Interpretation:
    Mixed-signal profile is diagnostic only. This query shows how those profiles were explained
    after final outcome assignment.
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

Interpretation:
    Counteroffer feasibility failure reasons are Section 8 diagnostics.
    Section 10 maps them into simulated strategy explanation codes when the final outcome is
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

Interpretation:
    decision_resolution_source documents how final outcome resolution occurred.
    This query shows whether the assigned primary explanation code aligns with that resolution path.
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
    1. tmp_m2_stage_7_reason_code_assignment exists.
    2. Row count is unchanged from tmp_m2_stage_6_final_decision_resolution.
    3. application_id remains unique.
    4. All Section 9 final decision, final flag, approved-exposure, approved-affordability, and
       approved-economics fields are preserved.
    5. primary_reason_code is populated for every row.
    6. primary_reason_family is populated for every row.
    7. triggered_reason_code_list is populated for every row.
    8. reason_priority_rank is populated and positive for every row.
    9. reason_code_count is populated and at least 1 for every row.
    10. APPROVE rows align to APPROVAL reason family.
    11. COUNTEROFFER rows align to COUNTEROFFER reason family.
    12. MANUAL_REVIEW rows align to MANUAL_REVIEW reason family.
    13. DECLINE rows align to POLICY_STOP reason family.
    14. secondary_reason_code and tertiary_reason_code are diagnostics only.
    15. Simulated reason codes are deterministic strategy explanation codes.
    16. Simulated reason codes are not customer communications, regulatory notices, production
        compliance determinations, or real applicant treatment explanations.

No latest-run strategy_decisions table has been created.
No strategy archive rows have been inserted.
No evidence rows have been inserted.
No matched strategy comparison has been performed.
No full Module 2 QA framework has been built.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

Recommended next patch chunk: **Section 11 — Latest-Run Strategy Decision Output Table**.
<!-- END_MESSAGE C038-M00696 -->


---

<a id="c038-m00698"></a>

### C038-M00698

**Andrew** · 2026-05-09T16:49:59.762000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00698 -->
section 11:
<!-- END_MESSAGE C038-M00698 -->


**Attachments in export:** `Pasted text(118).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00701"></a>

### C038-M00701

**ChatGPT** · 2026-05-09T16:54:09.852391-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00701 -->
Section 11 below is hardened using your uploaded Section 11 as the base, preserving the latest-run materialization pattern, explicit output-field list, indexes, gatekeepers, and local diagnostics. fileciteturn33file0

```sql
/***************************************************************************************************
SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Materialize the completed Module 2 latest-run strategy output table.

    Section 11 answers:

        "What is the current final simulated strategy output for the selected Module 1 source
         population / scenario and active Module 2 strategy?"

SQL PURPOSE:
    1. Consume tmp_m2_stage_7_reason_code_assignment.
    2. Create credit_decisioning_sim.strategy_decisions as the latest-run output.
    3. Use an explicit SELECT list rather than SELECT *.
    4. Preserve Module 2 strategy metadata and archive controls.
    5. Preserve Module 1 lineage.
    6. Preserve application, borrower, product, requested-structure, affordability, synthetic
       estimated-risk proxy, LGD, and requested Expected Loss fields.
    7. Preserve strategy segmentation, rule-trigger, preliminary routing, exposure-treatment,
       counteroffer feasibility, final decision, final exposure, and simulated reason-code fields.
    8. Add latest_output_created_ts as latest-run audit metadata.
    9. Create practical latest-run indexes.
    10. Validate latest-run output integrity through local gatekeepers.
    11. Provide lightweight latest-run diagnostics.

INPUT:
    tmp_m2_stage_7_reason_code_assignment

OUTPUT:
    credit_decisioning_sim.strategy_decisions

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

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
    intentionally expose the fields needed for review and validation.

    Explicit field selection prevents accidental downstream schema drift if an upstream temporary
    stage later gains a development-only helper field.

CAMPAIGN REGISTRY BOUNDARY:
    Section 11 does not add campaign registry IDs to the row-level latest-run strategy output.

    Campaign IDs such as:
        module1_run_id,
        module2_run_id,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id

    are evidence-linkage metadata.

    They are captured later in Section 16 evidence tables, not inserted into every latest-run
    applicant row in Section 11.

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

    It does not imply operational account creation, external applicant treatment, or a real applicant
    decision.

SIMULATED REASON-CODE BOUNDARY:
    Reason-code fields are simulated strategy explanation codes only.

    They support:
        strategy transparency,
        QA review,
        decision-path traceability,
        matched comparison,
        executive evidence capture,
        and validation documentation.

    They are not external notices or compliance determinations.

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

***************************************************************************************************/



/***************************************************************************************************
SECTION 11.1 — CLEAN RESET OF LATEST-RUN OUTPUT TABLE
****************************************************************************************************

PURPOSE:
    Drop the replaceable latest-run output table before rebuilding it from completed Section 10
    staging output.

WHY THIS MATTERS:
    The latest-run table is intentionally current-run only.

    Dropping it prevents a partial or prior latest-run output from being mixed with the current
    completed strategy run.

BOUNDARY:
    This does not drop:
        credit_decisioning_sim.strategy_decisions_archive
        credit_decisioning_sim.strategy_run_campaign_registry
        credit_decisioning_sim.strategy_comparison_campaign_registry
        Section 16 evidence tables

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

IMPORTANT:
    This table does not preserve prior runs.

    Prior completed runs are preserved through Section 12 archive persistence.

***************************************************************************************************/

CREATE TABLE credit_decisioning_sim.strategy_decisions AS
WITH active_archive_controls AS (
    SELECT
        archive_run_flag,
        strategy_archive_reset_mode
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
)
SELECT
    /***********************************************************************************************
    1. Module 2 strategy metadata

    strategy_run_id and strategy_run_ts are audit metadata. They support run traceability but do
    not replace the archive replacement / rerun key.
    ***********************************************************************************************/
    r.module2_model_version,
    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version,
    r.strategy_run_id,
    r.strategy_run_ts,
    r.failed_counteroffer_resolution,

    /*
    Archive controls are included in the latest-run output so Section 12 archive persistence can be
    audited directly from the completed latest-run table.

    These fields are not part of the row-level application grain.
    They do not replace the archive replacement / rerun key.
    */
    aac.archive_run_flag,
    aac.strategy_archive_reset_mode,

    r.module1_input_source,
    r.module1_source_table_name,


    /***********************************************************************************************
    2. Module 1 lineage

    These fields preserve upstream synthetic population and scenario lineage from Module 1.
    ***********************************************************************************************/
    r.module1_model_version,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.anchor_date,


    /***********************************************************************************************
    3. Application lineage
    ***********************************************************************************************/
    r.application_seq,
    r.application_id,
    r.applicant_id,
    r.application_date,


    /***********************************************************************************************
    4. Product and score segmentation
    ***********************************************************************************************/
    r.product_type,
    r.product_type_policy_key,
    r.score_band,
    r.score_band_policy_key,
    r.credit_score,
    r.product_score_policy_segment,


    /***********************************************************************************************
    5. Borrower and behavioral profile

    prequalified_flag and returning_customer_flag remain nullable when Module 1 does not provide
    them.
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
    6. Requested structure and requested-exposure economics

    requested_expected_loss_amount is the Module 2 alias for Module 1 requested-exposure Expected
    Loss.

    estimated_pd remains the finalized Module 1 SQL field and is interpreted as the synthetic
    estimated-PD proxy.
    ***********************************************************************************************/
    r.requested_amount,
    r.loan_term_months,
    r.base_apr_for_payment_calc,
    r.requested_monthly_payment_proxy,
    r.requested_payment_to_income_ratio,
    r.amount_to_income_ratio,
    r.estimated_pd,
    r.estimated_lgd,
    r.requested_expected_loss_amount,


    /***********************************************************************************************
    7. Strategy threshold context

    These values support audit review and explainability. They are included because final strategy
    outcomes should be traceable to the active strategy and product-policy settings used to generate
    them.
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

    r.product_approve_max_pti,
    r.product_review_max_pti,
    r.product_decline_min_pti,
    r.counteroffer_target_pti,

    r.product_approve_max_requested_el,
    r.product_review_max_requested_el,
    r.product_decline_min_requested_el,
    r.product_approved_el_cap,

    r.product_min_approved_amount,
    r.product_max_approved_amount,

    r.counteroffer_allowed_flag,
    r.manual_review_allowed_flag,
    r.product_min_counteroffer_pct,
    r.product_max_exposure_reduction_pct,
    r.exposure_assignment_method,
    r.approved_amount_rounding_increment,


    /***********************************************************************************************
    8. Strategy segmentation diagnostics
    ***********************************************************************************************/
    r.strategy_risk_tier,
    r.requested_pti_bucket,
    r.dti_bucket,
    r.requested_exposure_tier,
    r.requested_expected_loss_tier,
    r.mixed_signal_profile_type,
    r.mixed_signal_condition_count,
    r.borderline_profile_flag,


    /***********************************************************************************************
    9. Rule-trigger diagnostics

    These fields support audit review and reason-code traceability.
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

    r.manual_review_allowed_by_product_flag,
    r.manual_review_risk_trigger_flag,
    r.manual_review_affordability_trigger_flag,
    r.manual_review_dti_trigger_flag,
    r.manual_review_expected_loss_trigger_flag,
    r.manual_review_mixed_signal_trigger_flag,
    r.manual_review_borderline_trigger_flag,
    r.manual_review_candidate_flag,
    r.manual_review_candidate_trigger_count,

    r.high_utilization_review_trigger_flag,
    r.low_score_review_trigger_flag,
    r.supplemental_behavioral_review_trigger_flag,
    r.supplemental_behavioral_review_trigger_count,

    r.clean_approval_candidate_flag,
    r.total_rule_trigger_count,


    /***********************************************************************************************
    10. Preliminary routing diagnostics
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
    11. Exposure treatment and counteroffer feasibility diagnostics

    The preliminary fields support traceability from preliminary routing through final decision
    resolution.
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


    /***********************************************************************************************
    12. Final decision outcome fields
    ***********************************************************************************************/
    r.decision_outcome,
    r.decision_path,
    r.decision_priority_rank,
    r.decision_resolution_source,


    /***********************************************************************************************
    13. Final decision flags
    ***********************************************************************************************/
    r.approval_flag,
    r.counteroffer_flag,
    r.manual_review_flag,
    r.decline_flag,
    r.simulated_offer_exposure_flag,


    /***********************************************************************************************
    14. Final approved exposure and economics
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
    15. Simulated reason-code fields

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
    16. Latest-run audit timestamp

    latest_output_created_ts is audit metadata. It should not be used as deterministic comparison
    evidence unless specifically validating run metadata.
    ***********************************************************************************************/
    CURRENT_TIMESTAMP AS latest_output_created_ts

FROM tmp_m2_stage_7_reason_code_assignment r
CROSS JOIN active_archive_controls aac;



/***************************************************************************************************
SECTION 11.3 — LATEST-RUN INDEXES
****************************************************************************************************

PURPOSE:
    Create practical indexes for latest-run QA, review, reporting, and later archive persistence.

BUSINESS PURPOSE:
    Support fast review of common latest-run dimensions without changing the output data.

INTERPRETATION:
    Indexes improve query performance and review ergonomics.

    They do not alter rows, decision outcomes, exposure fields, reason codes, or archive state.

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

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_primary_reason
    ON credit_decisioning_sim.strategy_decisions (primary_reason_code);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_offer_exposure
    ON credit_decisioning_sim.strategy_decisions (simulated_offer_exposure_flag);



/***************************************************************************************************
SECTION 11.4 — LOCAL FAIL-FAST CHECKS FOR LATEST-RUN OUTPUT
****************************************************************************************************

PURPOSE:
    Validate latest-run output integrity before archive persistence.

BUSINESS PURPOSE:
    Confirm that the permanent latest-run output table faithfully preserves the completed Section 10
    result and obeys the accepted Module 2 output conventions.

LOCAL GATEKEEPER BOUNDARY:
    These are latest-run output gatekeepers only.

    They are not:
        archive validation,
        matched strategy comparison,
        full Module 2 QA,
        final Validation Summary evidence,
        or campaign-run evidence capture.

***************************************************************************************************/

DO $$
DECLARE
    v_stage7_count BIGINT;
    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;

    v_output_table_exists BOOLEAN;
    v_duplicate_application_count BIGINT;
    v_latest_output_created_ts_null_count BIGINT;

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
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO v_output_table_exists;

    IF v_output_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: credit_decisioning_sim.strategy_decisions does not exist.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run row count must match Section 10 staging.

    This confirms Section 11 materialized the completed reason-code staging layer without dropping,
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
    Gatekeeper: metadata and lineage integrity.

    Strategy metadata identifies the downstream Module 2 strategy.
    Module 1 lineage identifies the upstream synthetic population / scenario.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_metadata_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE strategy_set_name IS NULL
       OR NULLIF(BTRIM(strategy_set_name), '') IS NULL
       OR strategy_name IS NULL
       OR NULLIF(BTRIM(strategy_name), '') IS NULL
       OR strategy_version IS NULL
       OR NULLIF(BTRIM(strategy_version), '') IS NULL
       OR strategy_run_id IS NULL
       OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
       OR strategy_run_ts IS NULL
       OR module1_scenario_set_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
       OR module1_scenario_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
       OR population_id IS NULL
       OR NULLIF(BTRIM(population_id), '') IS NULL;

    IF v_metadata_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have missing strategy metadata or Module 1 lineage.',
            v_metadata_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls are populated and valid.

    archive_run_flag and strategy_archive_reset_mode support Section 12 archive persistence. They
    are not archive replacement keys.
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
            'Module 2 Section 11 failure: % row(s) have missing or invalid archive control fields.',
            v_archive_control_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final decision integrity.

    Exactly one of approval_flag, counteroffer_flag, manual_review_flag, and decline_flag must be
    TRUE per row.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decision_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL
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
            'Module 2 Section 11 failure: % latest-run row(s) have final decision integrity or flag reconciliation failures.',
            v_decision_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated_offer_exposure_flag integrity.

    TRUE only for APPROVE and COUNTEROFFER.
    FALSE for MANUAL_REVIEW and DECLINE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_offer_flag_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE simulated_offer_exposure_flag
          IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'));

    IF v_offer_flag_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have simulated_offer_exposure_flag reconciliation failures.',
            v_offer_flag_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: amount / exposure integrity.

    APPROVE:
        approved_amount = requested_amount

    COUNTEROFFER:
        approved_amount is positive and below requested_amount

    MANUAL_REVIEW:
        approved_amount is NULL because unresolved

    DECLINE:
        approved_amount = 0 by zero-exposure convention
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_amount_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE
        (
            approved_amount IS NOT NULL
            AND approved_amount < 0
        )
     OR (
            approved_amount IS NOT NULL
            AND approved_amount > requested_amount
        )
     OR (
            decision_outcome = 'APPROVE'
            AND approved_amount IS DISTINCT FROM requested_amount
        )
     OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                approved_amount IS NULL
                OR approved_amount <= 0
                OR approved_amount >= requested_amount
                OR counteroffer_amount IS DISTINCT FROM approved_amount
            )
        )
     OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND approved_amount IS NOT NULL
        )
     OR (
            decision_outcome = 'DECLINE'
            AND approved_amount IS DISTINCT FROM 0::NUMERIC
        );

    IF v_amount_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have approved amount or exposure convention failures.',
            v_amount_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Expected Loss integrity.

    requested_expected_loss_amount is requested-exposure Expected Loss.
    approved_expected_loss_amount is approved-exposure Expected Loss.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_expected_loss_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE requested_expected_loss_amount IS NULL
       OR (
            approved_expected_loss_amount IS NOT NULL
            AND approved_expected_loss_amount < 0
       )
       OR (
            decision_outcome = 'APPROVE'
            AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
       )
       OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                approved_expected_loss_amount IS NULL
                OR approved_expected_loss_amount > requested_expected_loss_amount
            )
       )
       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND approved_expected_loss_amount IS NOT NULL
       )
       OR (
            decision_outcome = 'DECLINE'
            AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
       );

    IF v_expected_loss_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % latest-run row(s) have requested / approved Expected Loss convention failures.',
            v_expected_loss_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated reason-code integrity.

    Reason-code fields should be populated and aligned to final decision_outcome.
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

    These checks protect the interpretation boundary that Module 2 reason codes are simulated
    strategy explanation codes only.
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

PURPOSE:
    Provide lightweight latest-run diagnostics.

BUSINESS PURPOSE:
    Let reviewers inspect the newly materialized latest-run output before archive persistence begins.

INTERPRETATION:
    These are latest-run output diagnostics.

    They are not:
        archive QA,
        matched strategy comparison,
        full Module 2 validation,
        executive frontier summary,
        or final evidence capture.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
11.5.1 Latest-run row count and distinct application_id count.

Expected:
    latest_run_row_count = distinct_application_id_count.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS latest_run_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,
    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts
FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
11.5.2 Count by decision_outcome.

Interpretation:
    High-level final simulated strategy outcome distribution.

    This is not the full Section 14 decision distribution QA.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
        AS pct_of_latest_run
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
11.5.3 Count by decision_path.

Interpretation:
    decision_path is an internal simulated strategy path label.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_path,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_path
ORDER BY decision_path;


/*-----------------------------------------------------------------------------------------------
11.5.4 Count by primary_reason_code.

Interpretation:
    primary_reason_code is a simulated strategy explanation code.
-----------------------------------------------------------------------------------------------*/
SELECT
    primary_reason_code,
    primary_reason_family,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    primary_reason_code,
    primary_reason_family
ORDER BY
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
11.5.5 Count by primary_reason_family.

Expected:
    primary_reason_family should align to final decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    primary_reason_family,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY primary_reason_family
ORDER BY primary_reason_family;


/*-----------------------------------------------------------------------------------------------
11.5.6 Product × decision_outcome.

Interpretation:
    Product-level latest-run diagnostic before full Section 14 product QA.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    product_type_policy_key,
    decision_outcome
ORDER BY
    product_type_policy_key,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.7 Score band × decision_outcome.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
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
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.8 Product × primary_reason_code.

Interpretation:
    Shows how simulated explanation patterns vary by product.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
11.5.9 Score band × primary_reason_code.

Interpretation:
    Shows whether simulated explanation patterns align with credit-quality segmentation.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM credit_decisioning_sim.strategy_decisions
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
    decision_outcome,
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
11.5.10 Strategy risk tier × decision_outcome.

Interpretation:
    Shows how synthetic estimated-risk tier flows into final simulated outcomes.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
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
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.11 Requested PTI bucket × decision_outcome.

Interpretation:
    requested_pti_bucket uses requested-structure PTI.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows
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
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.12 Mixed-signal profile × decision_outcome.

Interpretation:
    mixed_signal_profile_type is diagnostic only.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    decision_outcome,
    COUNT(*) AS row_count
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
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.13 Borderline profile flag × decision_outcome.

Interpretation:
    borderline_profile_flag is diagnostic only.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    decision_outcome,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    borderline_profile_flag,
    decision_outcome
ORDER BY
    borderline_profile_flag,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.14 Average requested_amount versus approved_amount by decision_outcome.

Interpretation:
    approved_amount is final approved exposure after Section 9 final decision resolution.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.15 Average requested PTI versus approved PTI by decision_outcome.

Interpretation:
    requested_payment_to_income_ratio is requested-structure PTI.
    approved_payment_to_income_ratio is final approved-exposure affordability proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.16 Average requested Expected Loss versus approved Expected Loss by decision_outcome.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss.
    approved_expected_loss_amount is approved-exposure Expected Loss.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.17 Simulated offer-exposure profile.

simulated_offer_exposure_flag indicates simulated positive offer exposure only.
-----------------------------------------------------------------------------------------------*/
SELECT
    simulated_offer_exposure_flag,
    COUNT(*) AS row_count,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps
FROM credit_decisioning_sim.strategy_decisions
GROUP BY simulated_offer_exposure_flag
ORDER BY simulated_offer_exposure_flag;



/***************************************************************************************************
END OF SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions exists.
    2. Row count matches tmp_m2_stage_7_reason_code_assignment.
    3. application_id remains unique.
    4. Module 2 strategy metadata is populated.
    5. archive_run_flag and strategy_archive_reset_mode are populated.
    6. Module 1 lineage is populated.
    7. final decision_outcome is populated.
    8. final decision flags reconcile to decision_outcome.
    9. exactly one final decision flag is TRUE per row.
    10. simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.
    11. simulated_offer_exposure_flag is FALSE for MANUAL_REVIEW and DECLINE.
    12. approved_amount conventions hold by decision_outcome.
    13. approved_expected_loss_amount conventions hold by decision_outcome.
    14. primary_reason_code is populated for every row.
    15. primary_reason_family aligns to decision_outcome.
    16. latest_output_created_ts is populated.
    17. Practical latest-run indexes are created.
    18. Campaign registry IDs remain outside the row-level latest-run output and are persisted later
        through Section 16 evidence capture.

No archive rows have been inserted.
No matched strategy comparison logic has been created.
No full Module 2 QA framework has been created.
No executive evidence rows have been inserted.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00701 -->


---

<a id="c038-m00703"></a>

### C038-M00703

**Andrew** · 2026-05-09T16:56:22.391000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00703 -->
section 12:
<!-- END_MESSAGE C038-M00703 -->


**Attachments in export:** `Pasted text(119).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_28.md) · [Next](Part_30.md)
