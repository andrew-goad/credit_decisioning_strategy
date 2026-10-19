# Module 2 Decision Simulator Build

## Part 86

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_85.md) · [Next](Part_87.md)

<a id="c038-m01623"></a>

### C038-M01623

**ChatGPT** · 2026-05-12T15:23:42.721436-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01623 -->
Below is the remaining Section 14 patch: **Section 14.14 through Section 14.20 plus the Section 14 ending**. This completes the Section 14 pass after the prior patches ended at Section 14.13. It preserves the accepted Section 14 contract: read-only latest-run validation, optional archive/comparison context, and a compact `tmp_m2_validation_status_summary` using `PASS`, `REVIEW`, and `NOT_APPLICABLE` for Section 16 evidence capture. fileciteturn253file20 fileciteturn253file70 fileciteturn253file11

```sql
/***************************************************************************************************
SECTION 14.14 — SIMULATED REASON-CODE COVERAGE AND CONCENTRATION QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that every final simulated outcome has a complete, outcome-family-aligned simulated
    explanation code.

    Section 14.14 answers:

        "Is every latest-run row explainable, and are explanation themes concentrated in ways that
         should be reviewed before documentation?"

SQL PURPOSE:
    1. Check simulated reason-code completeness.
    2. Check reason-family alignment to decision_outcome.
    3. Review primary reason-code distribution.
    4. Review reason-code count distribution.
    5. Review product × score reason-code concentration.
    6. Review the most common primary reason-code concentration.

BOUNDARY:
    Reason codes are internal simulated strategy explanation codes.

    They are not:
        customer communications,
        regulatory notices,
        adverse-action reasons,
        production compliance determinations,
        or fair-lending conclusions.

WHY CONCENTRATION IS REVIEWED:
    High reason-code concentration may be valid.

    Example:
        A baseline run may naturally have a large APPROVED_AS_REQUESTED population.

    But high concentration should be interpreted before documentation because it can also indicate:
        a narrow scenario,
        an aggressive strategy posture,
        an overly dominant rule,
        a product-policy skew,
        or a configuration issue.

READ-ONLY BOUNDARY:
    Section 14.14 does not modify latest-run rows.
    Section 14.14 does not modify archive rows.
    Section 14.14 does not reassign reason codes.
    Section 14.14 does not recalculate decisions.
    Section 14.14 does not recalculate approved exposure or approved Expected Loss.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.14A Reason-code completeness and family alignment diagnostic.

Purpose:
    Confirm every row has a complete simulated reason-code payload and that primary_reason_family
    reconciles to decision_outcome.

Expected:
    all violation counts = 0.

Outcome-family mapping:
    APPROVE       → APPROVAL
    COUNTEROFFER  → COUNTEROFFER
    MANUAL_REVIEW → MANUAL_REVIEW
    DECLINE       → POLICY_STOP
-----------------------------------------------------------------------------------------------*/

SELECT
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

    COUNT(*) FILTER (
        WHERE reason_priority_rank IS NULL
           OR reason_priority_rank <= 0
    ) AS invalid_reason_priority_rank_rows,

    COUNT(*) FILTER (
        WHERE reason_code_count IS NULL
           OR reason_code_count < 1
    ) AS invalid_reason_code_count_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND primary_reason_family IS DISTINCT FROM 'APPROVAL'
    ) AS approve_reason_family_alignment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND primary_reason_family IS DISTINCT FROM 'COUNTEROFFER'
    ) AS counteroffer_reason_family_alignment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND primary_reason_family IS DISTINCT FROM 'MANUAL_REVIEW'
    ) AS manual_review_reason_family_alignment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
    ) AS decline_reason_family_alignment_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.14B Primary reason-code distribution.

Purpose:
    Show the main simulated explanation-code distribution for the latest-run output.

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
    ) AS pct_of_latest_run,

    AVG(reason_code_count) AS avg_reason_code_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    primary_reason_family,
    primary_reason_code

ORDER BY
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
14.14C Reason-code count distribution.

Purpose:
    Show how many same-family reason candidates each row carried after Section 10 filtering.

Interpretation:
    Higher reason_code_count means more overlapping same-family explanation drivers existed.

    It does not automatically mean greater severity.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    reason_code_count,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY decision_outcome), 0),
        2
    ) AS pct_within_decision_outcome

FROM credit_decisioning_sim.strategy_decisions

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
14.14D Product × score × primary reason-code concentration.

Purpose:
    Review whether simulated explanation themes concentrate within specific product × score segments.

Interpretation:
    Segment-level reason concentration helps explain whether a product × score pocket is driven by
    approval, counteroffer, manual-review, or policy-stop logic.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY product_type_policy_key, score_band_policy_key
            ),
            0
        ),
        2
    ) AS pct_within_product_score_segment,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    score_band_policy_key,
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
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
14.14E Top primary reason-code concentration.

Purpose:
    Provide one compact diagnostic for dominant reason-code concentration.

Interpretation:
    A high top_primary_reason_code_share may be valid, especially for baseline / approval-heavy runs,
    but it should be explained in validation or executive narrative if it is very high.
-----------------------------------------------------------------------------------------------*/

WITH reason_distribution AS (
    SELECT
        primary_reason_family,
        primary_reason_code,
        COUNT(*) AS row_count,

        COUNT(*)::NUMERIC
            / NULLIF(SUM(COUNT(*)) OVER (), 0) AS reason_share

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY
        primary_reason_family,
        primary_reason_code
)

SELECT
    primary_reason_family AS top_primary_reason_family,
    primary_reason_code AS top_primary_reason_code,
    row_count AS top_primary_reason_code_rows,
    reason_share AS top_primary_reason_code_share,

    CASE
        WHEN reason_share > 0.750000
            THEN 'REVIEW_HIGH_PRIMARY_REASON_CODE_CONCENTRATION'
        ELSE 'PRIMARY_REASON_CODE_CONCENTRATION_WITHIN_REVIEW_BOUNDS'
    END AS reason_code_concentration_status

FROM reason_distribution

ORDER BY
    reason_share DESC,
    row_count DESC,
    primary_reason_family,
    primary_reason_code

LIMIT 1;



/***************************************************************************************************
SECTION 14.15 — SIMULATED OFFER-EXPOSURE PROFILE
****************************************************************************************************

BUSINESS PURPOSE:
    Review the population receiving simulated positive offer exposure.

    Section 14.15 answers:

        "Which rows receive simulated positive offer exposure, and what is the risk / affordability /
         exposure profile of those rows?"

SQL PURPOSE:
    1. Summarize simulated_offer_exposure_flag distribution.
    2. Compare offer rows and no-offer / unresolved rows on risk, PTI, exposure, and Expected Loss.
    3. Review product × score composition of simulated offer-exposure rows.
    4. Review primary reason-code profile among offer and non-offer rows.

BOUNDARY:
    simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.

    It does not imply:
        booked exposure,
        funded exposure,
        account creation,
        production approval,
        customer treatment,
        or real applicant treatment.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.15A Simulated offer-exposure summary.

Purpose:
    Compare positive simulated offer-exposure rows to no-offer / unresolved rows.

Interpretation:
    TRUE:
        APPROVE or COUNTEROFFER.

    FALSE:
        MANUAL_REVIEW or DECLINE.
-----------------------------------------------------------------------------------------------*/

SELECT
    simulated_offer_exposure_flag,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY simulated_offer_exposure_flag

ORDER BY simulated_offer_exposure_flag DESC;



/*-----------------------------------------------------------------------------------------------
14.15B Product × score composition of simulated offer-exposure rows.

Purpose:
    Show which product × score segments receive simulated positive offer exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_rows,

    COUNT(*) AS total_segment_rows,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    SUM(COALESCE(approved_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_amount_offer_rows,

    SUM(COALESCE(approved_expected_loss_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_expected_loss_offer_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    score_band_policy_key

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
14.15C Offer-exposure reason-code profile.

Purpose:
    Review simulated reason-code themes by offer-exposure flag.

Interpretation:
    Offer rows should primarily carry APPROVAL or COUNTEROFFER reason families.
    Non-offer / unresolved rows should primarily carry MANUAL_REVIEW or POLICY_STOP families.
-----------------------------------------------------------------------------------------------*/

SELECT
    simulated_offer_exposure_flag,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY simulated_offer_exposure_flag), 0),
        2
    ) AS pct_within_offer_exposure_flag,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    simulated_offer_exposure_flag,
    primary_reason_family,
    primary_reason_code

ORDER BY
    simulated_offer_exposure_flag DESC,
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.16 — MIXED-SIGNAL AND EDGE-CASE REVIEW
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that realistic edge cases remain visible and explainable.

    Section 14.16 answers:

        "Do mixed-signal and threshold-adjacent profiles remain visible, bounded, and explainable
         through staged strategy logic?"

SQL PURPOSE:
    1. Display mixed-signal profile distribution.
    2. Display borderline profile distribution.
    3. Provide targeted edge-case samples.
    4. Keep samples limited so the validation package remains reviewable.

EDGE-CASE BOUNDARY:
    Realistic overlap is not automatically a defect.

    It becomes a review concern only if it:
        dominates the output,
        violates final output conventions,
        or cannot be explained through product structure, borrower profile, affordability, synthetic
        estimated-risk tiering, rule triggers, or exposure-treatment diagnostics.

SAMPLE LIMITS:
    Sample queries use limited row counts to support diagnostic review without overwhelming the
    validation evidence package.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.16A Mixed-signal profile distribution.

Purpose:
    Confirm realistic overlap remains visible and non-dominant.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run,

    AVG(mixed_signal_condition_count) AS avg_mixed_signal_condition_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY mixed_signal_profile_type

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
    END;



/*-----------------------------------------------------------------------------------------------
14.16B Borderline profile distribution.

Purpose:
    Review threshold-adjacent profiles.

Interpretation:
    Borderline profiles are not defects. They are useful validation evidence because real credit
    strategy often has threshold-adjacent cases requiring traceable treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run,

    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY borderline_profile_flag

ORDER BY borderline_profile_flag DESC;



/*-----------------------------------------------------------------------------------------------
14.16C Strong credit / high requested PTI sample.

Purpose:
    Review applicants with strong score-band profile but high requested affordability stress.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    credit_score,
    annual_income,
    requested_amount,
    requested_payment_to_income_ratio,
    approved_payment_to_income_ratio,
    estimated_pd AS synthetic_estimated_pd_proxy,
    strategy_risk_tier,
    requested_pti_bucket,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE score_band_policy_key IN ('SUPER_PRIME', 'PRIME')
  AND requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')

ORDER BY
    requested_payment_to_income_ratio DESC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16D Weak credit / low requested PTI sample.

Purpose:
    Review applicants with weaker score-band profile but low requested affordability stress.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    credit_score,
    annual_income,
    requested_amount,
    requested_payment_to_income_ratio,
    estimated_pd AS synthetic_estimated_pd_proxy,
    strategy_risk_tier,
    requested_pti_bucket,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE score_band_policy_key IN ('SUBPRIME', 'DEEP_SUBPRIME')
  AND requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')

ORDER BY
    estimated_pd DESC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16E Large exposure / low synthetic risk sample.

Purpose:
    Review large-request rows that do not carry high synthetic estimated-risk.

Interpretation:
    These rows often test product caps, exposure treatment, and counteroffer feasibility rather than
    pure risk-score behavior.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    requested_amount,
    requested_exposure_tier,
    strategy_risk_tier,
    estimated_pd AS synthetic_estimated_pd_proxy,
    requested_payment_to_income_ratio,
    approved_amount,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE mixed_signal_profile_type IN ('LARGE_EXPOSURE_LOW_RISK', 'MULTIPLE_MIXED_SIGNALS')

ORDER BY
    requested_amount DESC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16F High synthetic risk / low exposure sample.

Purpose:
    Review smaller-request rows that still carry high synthetic estimated-risk.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    requested_amount,
    requested_exposure_tier,
    strategy_risk_tier,
    estimated_pd AS synthetic_estimated_pd_proxy,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE mixed_signal_profile_type IN ('HIGH_RISK_LOW_EXPOSURE', 'MULTIPLE_MIXED_SIGNALS')

ORDER BY
    estimated_pd DESC,
    requested_amount ASC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16G High DTI / low requested PTI sample.

Purpose:
    Review rows where existing-obligation capacity stress differs from requested-payment stress.

Interpretation:
    DTI is existing-obligation capacity.
    Requested PTI is requested-structure affordability.
    These can move differently.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    debt_to_income_ratio,
    requested_payment_to_income_ratio,
    dti_bucket,
    requested_pti_bucket,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE mixed_signal_profile_type IN ('HIGH_DTI_LOW_REQUESTED_PTI', 'MULTIPLE_MIXED_SIGNALS')

ORDER BY
    debt_to_income_ratio DESC,
    requested_payment_to_income_ratio ASC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16H Multiple mixed-signal profiles.

Purpose:
    Review applicants carrying multiple overlapping diagnostic signals.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    mixed_signal_profile_type,
    mixed_signal_condition_count,
    strategy_risk_tier,
    requested_pti_bucket,
    dti_bucket,
    requested_exposure_tier,
    requested_expected_loss_tier,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE mixed_signal_profile_type = 'MULTIPLE_MIXED_SIGNALS'

ORDER BY
    mixed_signal_condition_count DESC,
    total_rule_trigger_count DESC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16I Borderline profiles.

Purpose:
    Review threshold-adjacent applicants.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    borderline_profile_flag,
    strategy_risk_tier,
    requested_pti_bucket,
    dti_bucket,
    requested_expected_loss_tier,
    decision_outcome,
    decision_path,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE borderline_profile_flag IS TRUE

ORDER BY
    total_rule_trigger_count DESC,
    application_id

LIMIT 25;



/*-----------------------------------------------------------------------------------------------
14.16J Counteroffer cases with large exposure reductions.

Purpose:
    Review large exposure-reduction cases among final COUNTEROFFER rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    requested_amount,
    approved_amount,
    counteroffer_amount,
    exposure_reduction_amount,
    exposure_reduction_pct,
    requested_payment_to_income_ratio,
    approved_payment_to_income_ratio,
    requested_expected_loss_amount,
    approved_expected_loss_amount,
    primary_reason_code

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'COUNTEROFFER'

ORDER BY
    exposure_reduction_pct DESC NULLS LAST,
    requested_amount DESC,
    application_id

LIMIT 25;



/***************************************************************************************************
SECTION 14.17 — FINAL OUTPUT CONVENTION VALIDATION
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that locked final output conventions hold in the latest-run table.

    Section 14.17 answers:

        "Do final decision flags, simulated offer-exposure flags, approved amount conventions,
         affordability conventions, approved Expected Loss conventions, and reason-code conventions
         reconcile to final decision_outcome?"

SQL PURPOSE:
    1. Produce compact violation counts for final output conventions.
    2. Confirm exactly one final decision flag is TRUE per row.
    3. Confirm simulated_offer_exposure_flag reconciles to APPROVE and COUNTEROFFER.
    4. Confirm approved amount conventions by final outcome.
    5. Confirm approved monthly payment and approved PTI conventions by final outcome.
    6. Confirm approved Expected Loss conventions by final outcome.
    7. Confirm simulated reason-code completeness.
    8. Confirm simulated reason-family alignment.

EXPECTED RESULT:
    All violation counts should be zero.

INTERPRETATION:
    Non-zero violation counts should be reviewed before any Validation Summary, README, LinkedIn, or
    executive narrative claims are drafted.

    A convention violation is stronger evidence than an ordinary diagnostic REVIEW pattern.

    It suggests a potential implementation issue or a broken upstream assumption.

READ-ONLY BOUNDARY:
    Section 14.17 does not modify latest-run rows.
    Section 14.17 does not modify archive rows.
    Section 14.17 does not recalculate decisions.
    Section 14.17 does not reassign reason codes.
    Section 14.17 does not recalculate approved exposure.
    Section 14.17 does not recalculate approved Expected Loss.

****************************************************************************************************/

SELECT
    COUNT(*) FILTER (
        WHERE (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
        ) <> 1
    ) AS final_outcome_flag_count_violation_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag
              IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
    ) AS simulated_offer_exposure_flag_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_amount IS DISTINCT FROM requested_amount
    ) AS approve_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
          )
    ) AS counteroffer_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_amount IS NOT NULL
    ) AS manual_review_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
    ) AS approve_payment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_monthly_payment_proxy IS NULL
             OR approved_payment_to_income_ratio IS NULL
             OR approved_payment_to_income_ratio > counteroffer_target_pti
          )
    ) AS counteroffer_affordability_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND (
                approved_monthly_payment_proxy IS NOT NULL
             OR approved_payment_to_income_ratio IS NOT NULL
          )
    ) AS manual_review_affordability_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND (
                approved_monthly_payment_proxy IS DISTINCT FROM 0::NUMERIC
             OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
          )
    ) AS decline_affordability_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
    ) AS approve_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount < 0
             OR approved_expected_loss_amount > requested_expected_loss_amount
             OR approved_expected_loss_amount > product_approved_el_cap
          )
    ) AS counteroffer_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_expected_loss_amount IS NOT NULL
    ) AS manual_review_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_code IS NULL
           OR primary_reason_family IS NULL
           OR triggered_reason_code_list IS NULL
           OR reason_code_count IS NULL
           OR reason_code_count < 1
    ) AS reason_code_completeness_violation_rows,

    COUNT(*) FILTER (
        WHERE (
                decision_outcome = 'APPROVE'
            AND primary_reason_family IS DISTINCT FROM 'APPROVAL'
        )
        OR (
                decision_outcome = 'COUNTEROFFER'
            AND primary_reason_family IS DISTINCT FROM 'COUNTEROFFER'
        )
        OR (
                decision_outcome = 'MANUAL_REVIEW'
            AND primary_reason_family IS DISTINCT FROM 'MANUAL_REVIEW'
        )
        OR (
                decision_outcome = 'DECLINE'
            AND primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
        )
    ) AS reason_family_alignment_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.18 — ARCHIVE, MATCHED COMPARISON, AND SOURCE-CONSISTENCY READINESS
****************************************************************************************************

BUSINESS PURPOSE:
    Surface archive and matched-comparison readiness context for the completed latest-run validation
    package.

    Section 14.18 answers:

        "Is the latest-run slice archived, and if Section 13 was run, is the selected comparison
         ready and source-consistent?"

SQL PURPOSE:
    1. Display archive-readiness context from tmp_m2_validation_archive_readiness_context.
    2. Display selected comparison readiness context from tmp_m2_validation_comparison_readiness_context.
    3. Display matched source-field consistency context from tmp_m2_validation_source_consistency_context.

BOUNDARY:
    Archive and comparison readiness are context diagnostics.

    They do not modify archive rows.
    They do not recalculate comparison deltas.
    They do not recalculate latest-run outputs.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.18A Archive-readiness context for current latest-run slice.

Expected:
    archive_readiness_status = CURRENT_LATEST_RUN_SLICE_ARCHIVED
    when Section 12 was run and archive persistence was intended.

Boundary:
    Missing archive context may be acceptable for ad hoc latest-run validation, but formal campaign
    evidence should normally be archive-backed.
-----------------------------------------------------------------------------------------------*/

SELECT
    archive_table_exists,
    archive_inserted_ts_column_exists,

    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    latest_run_rows,
    latest_run_distinct_application_id_count,

    current_archived_slice_rows,
    current_archived_slice_distinct_application_id_count,
    current_archived_slice_null_archive_ts_rows,

    archive_readiness_status

FROM tmp_m2_validation_archive_readiness_context

ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/*-----------------------------------------------------------------------------------------------
14.18B Selected comparison readiness context.

Expected when Section 13 was run and comparison is ready:
    readiness_status = READY_FOR_MATCHED_COMPARISON.

If Section 13 was not run:
    readiness_status = NOT_APPLICABLE_SECTION_13_COMPARISON_READINESS_NOT_AVAILABLE.
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,

    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    same_strategy_selected_flag,

    baseline_archived_row_count,
    challenger_archived_row_count,

    baseline_distinct_application_id_count,
    challenger_distinct_application_id_count,

    baseline_duplicate_application_row_count,
    challenger_duplicate_application_row_count,

    matched_application_id_count,
    baseline_only_application_id_count,
    challenger_only_application_id_count,

    readiness_status,
    expected_comparison_storyline,
    primary_metric_focus

FROM tmp_m2_validation_comparison_readiness_context;



/*-----------------------------------------------------------------------------------------------
14.18C Matched source-field consistency context.

Expected when Section 13 was run and matched comparison is source-consistent:
    source_consistency_status = SOURCE_FIELDS_MATCH.

If Section 13 was not run:
    source_consistency_status = NOT_APPLICABLE_SECTION_13_SOURCE_CONSISTENCY_NOT_AVAILABLE.
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    readiness_status,

    matched_application_count,
    source_field_mismatch_count,

    product_type_mismatch_count,
    score_band_mismatch_count,
    credit_score_mismatch_count,
    annual_income_mismatch_count,
    requested_amount_mismatch_count,
    requested_payment_mismatch_count,
    requested_pti_mismatch_count,
    amount_to_income_mismatch_count,
    estimated_pd_mismatch_count,
    estimated_lgd_mismatch_count,
    requested_expected_loss_mismatch_count,
    module1_lineage_mismatch_count,

    source_consistency_status

FROM tmp_m2_validation_source_consistency_context;



/***************************************************************************************************
SECTION 14.19 — MATERIALIZE VALIDATION STATUS SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Create the compact validation-evidence spine consumed by Section 16.

    Section 14.19 answers:

        "What are the main validation status findings for this latest-run output, expressed in a
         compact, documentation-ready table?"

SQL PURPOSE:
    1. Drop and recreate tmp_m2_validation_status_summary.
    2. Summarize structural integrity.
    3. Summarize final output conventions.
    4. Summarize reason-code coverage.
    5. Summarize decision distribution, product behavior, synthetic-risk ordering, affordability,
       DTI, exposure / Expected Loss, counteroffer, manual review, decline, offer exposure, edge
       cases, archive context, comparison context, and source consistency.
    6. Use PASS / REVIEW / NOT_APPLICABLE status values only.

STATUS RULE:
    PASS:
        Expected condition satisfied.

    REVIEW:
        Diagnostic pattern should be interpreted before documentation.

    NOT_APPLICABLE:
        Supporting object, comparison context, or applicable population was unavailable.

BOUNDARY:
    This section creates one temporary validation summary table.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not modify persistent evidence rows.
    Section 16 persists validation evidence later.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

CREATE TEMP TABLE tmp_m2_validation_status_summary
ON COMMIT PRESERVE ROWS
AS
WITH base AS (
    SELECT *
    FROM credit_decisioning_sim.strategy_decisions
),

structural AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) - COUNT(DISTINCT application_id)
            AS duplicate_application_row_count,

        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version
        )) AS distinct_strategy_version_count,

        COUNT(DISTINCT (
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS distinct_module1_scenario_population_count,

        COUNT(*) FILTER (
            WHERE application_id IS NULL
               OR applicant_id IS NULL
               OR strategy_set_name IS NULL
               OR strategy_name IS NULL
               OR strategy_version IS NULL
               OR module1_scenario_set_name IS NULL
               OR module1_scenario_name IS NULL
               OR population_id IS NULL
        ) AS required_identity_gap_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome IS NULL
               OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
        ) AS decision_outcome_gap_rows,

        COUNT(*) FILTER (
            WHERE requested_expected_loss_amount IS NULL
               OR estimated_pd IS NULL
               OR estimated_lgd IS NULL
        ) AS requested_risk_economics_gap_rows
    FROM base
),

rates AS (
    SELECT
        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate
    FROM base
),

final_conventions AS (
    SELECT
        COUNT(*) FILTER (
            WHERE (
                COALESCE(approval_flag::INT, 0)
                + COALESCE(counteroffer_flag::INT, 0)
                + COALESCE(manual_review_flag::INT, 0)
                + COALESCE(decline_flag::INT, 0)
            ) <> 1
        ) AS final_outcome_flag_count_violation_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
              AND (
                    approved_amount IS DISTINCT FROM requested_amount
                 OR approved_monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
                 OR approved_payment_to_income_ratio IS DISTINCT FROM requested_payment_to_income_ratio
                 OR approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
              )
        ) AS approve_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    approved_amount IS NULL
                 OR approved_amount <= 0
                 OR approved_amount >= requested_amount
                 OR counteroffer_amount IS DISTINCT FROM approved_amount
                 OR approved_payment_to_income_ratio IS NULL
                 OR approved_payment_to_income_ratio > counteroffer_target_pti
                 OR approved_expected_loss_amount IS NULL
                 OR approved_expected_loss_amount < 0
                 OR approved_expected_loss_amount > requested_expected_loss_amount
                 OR approved_expected_loss_amount > product_approved_el_cap
                 OR counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
              )
        ) AS counteroffer_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND (
                    approved_amount IS NOT NULL
                 OR approved_monthly_payment_proxy IS NOT NULL
                 OR approved_payment_to_income_ratio IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
                 OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
              )
        ) AS manual_review_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_monthly_payment_proxy IS DISTINCT FROM 0::NUMERIC
                 OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
                 OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
              )
        ) AS decline_convention_violation_rows
    FROM base
),

reason_conventions AS (
    SELECT
        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR triggered_reason_code_list IS NULL
               OR reason_priority_rank IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
        ) AS reason_code_completeness_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND primary_reason_family IS DISTINCT FROM 'APPROVAL'
            )
            OR (
                    decision_outcome = 'COUNTEROFFER'
                AND primary_reason_family IS DISTINCT FROM 'COUNTEROFFER'
            )
            OR (
                    decision_outcome = 'MANUAL_REVIEW'
                AND primary_reason_family IS DISTINCT FROM 'MANUAL_REVIEW'
            )
            OR (
                    decision_outcome = 'DECLINE'
                AND primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
            )
        ) AS reason_family_alignment_violation_rows
    FROM base
),

product_diagnostics AS (
    SELECT
        MAX(approval_rate) AS max_product_approval_rate,
        MAX(counteroffer_rate) AS max_product_counteroffer_rate,
        MAX(manual_review_rate) AS max_product_manual_review_rate,
        MAX(decline_rate) AS max_product_decline_rate,
        MIN(simulated_offer_exposure_rate) AS min_product_simulated_offer_exposure_rate
    FROM (
        SELECT
            product_type_policy_key,

            COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
                / NULLIF(COUNT(*), 0) AS approval_rate,

            COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
                / NULLIF(COUNT(*), 0) AS counteroffer_rate,

            COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
                / NULLIF(COUNT(*), 0) AS manual_review_rate,

            COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
                / NULLIF(COUNT(*), 0) AS decline_rate,

            COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
                / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

        FROM base

        GROUP BY product_type_policy_key
    ) p
),

risk_direction AS (
    SELECT
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_rows,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_rows,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_decline_rows
    FROM base
),

affordability_diagnostics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND approved_payment_to_income_ratio > counteroffer_target_pti
        ) AS counteroffer_rows_above_target_pti,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
              AND approved_payment_to_income_ratio IS DISTINCT FROM requested_payment_to_income_ratio
        ) AS approve_pti_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND approved_payment_to_income_ratio IS NOT NULL
        ) AS manual_review_approved_pti_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
        ) AS decline_approved_pti_violation_rows
    FROM base
),

dti_diagnostics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE dti_decline_trigger_flag IS TRUE
        ) AS severe_dti_trigger_rows,

        COUNT(*) FILTER (
            WHERE dti_decline_trigger_flag IS TRUE
              AND decision_outcome <> 'DECLINE'
        ) AS severe_dti_non_decline_rows,

        AVG(debt_to_income_ratio) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_dti_offer_rows,

        AVG(debt_to_income_ratio) FILTER (
            WHERE decision_outcome = 'DECLINE'
        ) AS avg_dti_decline_rows
    FROM base
),

exposure_expected_loss_diagnostics AS (
    SELECT
        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate
    FROM base
),

counteroffer_diagnostics AS (
    SELECT
        COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER')
            AS preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS TRUE
        ) AS feasible_preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
        ) AS failed_preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS final_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND primary_reason_family IS DISTINCT FROM 'COUNTEROFFER'
        ) AS counteroffer_reason_family_violation_rows
    FROM base
),

manual_review_diagnostics AS (
    SELECT
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND (
                    approved_amount IS NOT NULL
                 OR approved_payment_to_income_ratio IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
                 OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
              )
        ) AS manual_review_unresolved_violation_rows
    FROM base
),

decline_diagnostics AS (
    SELECT
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
        ) AS decline_reason_family_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
                 OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
              )
        ) AS decline_zero_exposure_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND hard_policy_stop_flag IS TRUE
        ) AS hard_policy_stop_decline_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND synthetic_risk_decline_trigger_flag IS TRUE
        ) AS synthetic_risk_decline_trigger_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND dti_decline_trigger_flag IS TRUE
        ) AS dti_decline_trigger_rows
    FROM base
),

reason_concentration AS (
    SELECT
        MAX(reason_share) AS top_primary_reason_code_share
    FROM (
        SELECT
            primary_reason_code,
            COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0) AS reason_share
        FROM base
        GROUP BY primary_reason_code
    ) r
),

offer_exposure_diagnostics AS (
    SELECT
        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS simulated_offer_exposure_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_violation_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
              AND decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER')
        ) AS offer_flag_wrong_outcome_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS FALSE
              AND decision_outcome IN ('APPROVE', 'COUNTEROFFER')
        ) AS non_offer_flag_positive_outcome_rows
    FROM base
),

edge_case_diagnostics AS (
    SELECT
        COUNT(*) AS applications,

        COUNT(*) FILTER (
            WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
        )::NUMERIC / NULLIF(COUNT(*), 0) AS mixed_signal_profile_rate,

        COUNT(*) FILTER (
            WHERE borderline_profile_flag IS TRUE
        )::NUMERIC / NULLIF(COUNT(*), 0) AS borderline_profile_rate
    FROM base
),

archive_context AS (
    SELECT
        BOOL_OR(archive_table_exists) AS archive_table_exists,
        BOOL_OR(archive_inserted_ts_column_exists) AS archive_inserted_ts_column_exists,
        SUM(latest_run_rows) AS latest_run_rows,
        SUM(current_archived_slice_rows) AS current_archived_slice_rows,
        SUM(current_archived_slice_null_archive_ts_rows) AS current_archived_slice_null_archive_ts_rows,
        MAX(archive_readiness_status) AS archive_readiness_status
    FROM tmp_m2_validation_archive_readiness_context
),

comparison_context AS (
    SELECT
        COALESCE(
            MAX(readiness_status),
            'NOT_APPLICABLE_SECTION_13_COMPARISON_READINESS_NOT_AVAILABLE'
        ) AS readiness_status,

        COALESCE(MAX(matched_application_id_count), 0)
            AS matched_application_id_count,

        COALESCE(MAX(baseline_only_application_id_count), 0)
            AS baseline_only_application_id_count,

        COALESCE(MAX(challenger_only_application_id_count), 0)
            AS challenger_only_application_id_count
    FROM tmp_m2_validation_comparison_readiness_context
),

source_context AS (
    SELECT
        COALESCE(
            MAX(source_consistency_status),
            'NOT_APPLICABLE_SECTION_13_SOURCE_CONSISTENCY_NOT_AVAILABLE'
        ) AS source_consistency_status,

        COALESCE(MAX(matched_application_count), 0)
            AS matched_application_count,

        COALESCE(MAX(source_field_mismatch_count), 0)
            AS source_field_mismatch_count
    FROM tmp_m2_validation_source_consistency_context
)

SELECT
    'STRUCTURAL_INTEGRITY'::TEXT AS validation_area,
    'Latest-run row grain and scope'::TEXT AS validation_test_name,
    'STRUCTURAL'::TEXT AS validation_category,

    CASE
        WHEN s.total_rows > 0
         AND s.total_rows = s.distinct_application_id_count
         AND s.duplicate_application_row_count = 0
         AND s.distinct_strategy_version_count = 1
         AND s.distinct_module1_scenario_population_count = 1
         AND s.required_identity_gap_rows = 0
         AND s.decision_outcome_gap_rows = 0
         AND s.requested_risk_economics_gap_rows = 0
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status,

    (
        'rows=' || s.total_rows
        || '; distinct_application_id=' || s.distinct_application_id_count
        || '; duplicate_application_rows=' || s.duplicate_application_row_count
        || '; distinct_strategy_versions=' || s.distinct_strategy_version_count
        || '; distinct_module1_scenario_populations=' || s.distinct_module1_scenario_population_count
        || '; required_identity_gap_rows=' || s.required_identity_gap_rows
        || '; decision_outcome_gap_rows=' || s.decision_outcome_gap_rows
        || '; requested_risk_economics_gap_rows=' || s.requested_risk_economics_gap_rows
    ) AS observed_value,

    'One row per application_id, one strategy slice, one Module 1 scenario / population, and no required identity / decision / requested-risk gaps.'
        AS expected_behavior,

    'Structural integrity must be sound before strategy behavior, segment behavior, counteroffer behavior, reason codes, archive context, or evidence capture are interpreted.'
        AS interpretation

FROM structural s

UNION ALL

SELECT
    'FINAL_OUTPUT_CONVENTIONS',
    'Final decision flags and output conventions',
    'CONVENTION',

    CASE
        WHEN fc.final_outcome_flag_count_violation_rows = 0
         AND fc.simulated_offer_exposure_flag_violation_rows = 0
         AND fc.approve_convention_violation_rows = 0
         AND fc.counteroffer_convention_violation_rows = 0
         AND fc.manual_review_convention_violation_rows = 0
         AND fc.decline_convention_violation_rows = 0
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status,

    (
        'flag_violations=' || fc.final_outcome_flag_count_violation_rows
        || '; offer_flag_violations=' || fc.simulated_offer_exposure_flag_violation_rows
        || '; approve_convention_violations=' || fc.approve_convention_violation_rows
        || '; counteroffer_convention_violations=' || fc.counteroffer_convention_violation_rows
        || '; manual_review_convention_violations=' || fc.manual_review_convention_violation_rows
        || '; decline_convention_violations=' || fc.decline_convention_violation_rows
    ) AS observed_value,

    'Decision flags reconcile to decision_outcome; APPROVE preserves requested terms; COUNTEROFFER uses feasible reduced exposure; MANUAL_REVIEW remains unresolved; DECLINE uses zero-exposure convention.'
        AS expected_behavior,

    'This is a locked final-output convention check. Non-zero counts require implementation review before documentation.'
        AS interpretation

FROM final_conventions fc

UNION ALL

SELECT
    'REASON_CODE_COVERAGE',
    'Simulated reason-code completeness and family alignment',
    'EXPLAINABILITY',

    CASE
        WHEN rc.reason_code_completeness_violation_rows = 0
         AND rc.reason_family_alignment_violation_rows = 0
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status,

    (
        'reason_code_completeness_violations=' || rc.reason_code_completeness_violation_rows
        || '; reason_family_alignment_violations=' || rc.reason_family_alignment_violation_rows
    ) AS observed_value,

    'Every row should have a complete simulated reason-code payload and primary_reason_family should align to decision_outcome.'
        AS expected_behavior,

    'Reason codes are simulated strategy explanation codes only, but every latest-run row must be explainable before evidence capture.'
        AS interpretation

FROM reason_conventions rc

UNION ALL

SELECT
    'DECISION_DISTRIBUTION',
    'Final outcome rate profile',
    'PORTFOLIO_DIAGNOSTIC',

    CASE
        WHEN r.applications = 0
            THEN 'REVIEW'

        WHEN r.manual_review_rate > 0.400000
          OR r.counteroffer_rate > 0.400000
          OR r.decline_rate > 0.750000
            THEN 'REVIEW'

        ELSE 'PASS'
    END AS validation_status,

    (
        'applications=' || r.applications
        || '; approval_rate=' || COALESCE(r.approval_rate::TEXT, '<NULL>')
        || '; counteroffer_rate=' || COALESCE(r.counteroffer_rate::TEXT, '<NULL>')
        || '; manual_review_rate=' || COALESCE(r.manual_review_rate::TEXT, '<NULL>')
        || '; decline_rate=' || COALESCE(r.decline_rate::TEXT, '<NULL>')
        || '; simulated_offer_exposure_rate=' || COALESCE(r.simulated_offer_exposure_rate::TEXT, '<NULL>')
    ) AS observed_value,

    'Outcome rates should be interpretable through strategy parameters, product policy, source scenario, and reason-code distribution.'
        AS expected_behavior,

    'High manual review, counteroffer, or decline concentration may be valid for a particular scenario but should be interpreted before executive narrative.'
        AS interpretation

FROM rates r

UNION ALL

SELECT
    'PRODUCT_BEHAVIOR',
    'Product-level concentration review',
    'SEGMENT_DIAGNOSTIC',

    CASE
        WHEN pd.max_product_manual_review_rate > 0.500000
          OR pd.max_product_counteroffer_rate > 0.500000
          OR pd.max_product_decline_rate > 0.850000
          OR pd.min_product_simulated_offer_exposure_rate < 0.050000
            THEN 'REVIEW'
        ELSE 'PASS'
    END AS validation_status,

    (
        'max_product_approval_rate=' || COALESCE(pd.max_product_approval_rate::TEXT, '<NULL>')
        || '; max_product_counteroffer_rate=' || COALESCE(pd.max_product_counteroffer_rate::TEXT, '<NULL>')
        || '; max_product_manual_review_rate=' || COALESCE(pd.max_product_manual_review_rate::TEXT, '<NULL>')
        || '; max_product_decline_rate=' || COALESCE(pd.max_product_decline_rate::TEXT, '<NULL>')
        || '; min_product_simulated_offer_exposure_rate=' || COALESCE(pd.min_product_simulated_offer_exposure_rate::TEXT, '<NULL>')
    ) AS observed_value,

    'Product-level skews should be explainable through product policy, LGD, requested exposure, affordability, and reason-code mix.'
        AS expected_behavior,

    'REVIEW indicates a product-level concentration that may be valid but should be explained in documentation.'
        AS interpretation

FROM product_diagnostics pd

UNION ALL

SELECT
    'SYNTHETIC_RISK_ORDERING',
    'Offer rows versus decline rows synthetic estimated-risk profile',
    'RISK_DIAGNOSTIC',

    CASE
        WHEN rd.offer_rows = 0 OR rd.decline_rows = 0
            THEN 'NOT_APPLICABLE'

        WHEN rd.avg_synthetic_estimated_pd_proxy_decline_rows
           >= rd.avg_synthetic_estimated_pd_proxy_offer_rows
            THEN 'PASS'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'offer_rows=' || rd.offer_rows
        || '; decline_rows=' || rd.decline_rows
        || '; avg_offer_estimated_pd_proxy=' || COALESCE(rd.avg_synthetic_estimated_pd_proxy_offer_rows::TEXT, '<NULL>')
        || '; avg_decline_estimated_pd_proxy=' || COALESCE(rd.avg_synthetic_estimated_pd_proxy_decline_rows::TEXT, '<NULL>')
    ) AS observed_value,

    'Decline rows should generally have equal or higher average synthetic estimated-PD proxy than simulated positive offer-exposure rows.'
        AS expected_behavior,

    'This is directional synthetic-risk coherence, not calibrated default-model validation.'
        AS interpretation

FROM risk_direction rd

UNION ALL

SELECT
    'AFFORDABILITY_PTI',
    'Requested versus approved PTI conventions',
    'AFFORDABILITY_DIAGNOSTIC',

    CASE
        WHEN ad.approve_pti_convention_violation_rows = 0
         AND ad.counteroffer_rows_above_target_pti = 0
         AND ad.manual_review_approved_pti_violation_rows = 0
         AND ad.decline_approved_pti_violation_rows = 0
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status,

    (
        'counteroffer_rows=' || ad.counteroffer_rows
        || '; counteroffer_rows_above_target_pti=' || ad.counteroffer_rows_above_target_pti
        || '; approve_pti_violations=' || ad.approve_pti_convention_violation_rows
        || '; manual_review_approved_pti_violations=' || ad.manual_review_approved_pti_violation_rows
        || '; decline_approved_pti_violations=' || ad.decline_approved_pti_violation_rows
    ) AS observed_value,

    'APPROVE should preserve requested PTI; COUNTEROFFER should satisfy target PTI; MANUAL_REVIEW should remain unresolved; DECLINE should use zero approved PTI.'
        AS expected_behavior,

    'PTI is a strategy-simulation affordability proxy. Non-zero convention violations require review before documentation.'
        AS interpretation

FROM affordability_diagnostics ad

UNION ALL

SELECT
    'DTI_CAPACITY',
    'Severe DTI trigger behavior',
    'CAPACITY_DIAGNOSTIC',

    CASE
        WHEN dd.severe_dti_trigger_rows = 0
            THEN 'NOT_APPLICABLE'

        WHEN dd.severe_dti_non_decline_rows = 0
            THEN 'PASS'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'severe_dti_trigger_rows=' || dd.severe_dti_trigger_rows
        || '; severe_dti_non_decline_rows=' || dd.severe_dti_non_decline_rows
        || '; avg_dti_offer_rows=' || COALESCE(dd.avg_dti_offer_rows::TEXT, '<NULL>')
        || '; avg_dti_decline_rows=' || COALESCE(dd.avg_dti_decline_rows::TEXT, '<NULL>')
    ) AS observed_value,

    'Severe DTI trigger rows should generally resolve as no-offer capacity concerns unless another governed route explains the outcome.'
        AS expected_behavior,

    'DTI is an existing-obligation capacity signal and is not directly corrected by exposure reduction in Module 2 V1.0.'
        AS interpretation

FROM dti_diagnostics dd

UNION ALL

SELECT
    'EXPOSURE_EXPECTED_LOSS',
    'Requested versus approved exposure and Expected Loss profile',
    'ECONOMICS_DIAGNOSTIC',

    CASE
        WHEN eeld.total_requested_amount IS NULL
          OR eeld.total_requested_amount <= 0
            THEN 'REVIEW'
        ELSE 'PASS'
    END AS validation_status,

    (
        'total_requested_amount=' || COALESCE(eeld.total_requested_amount::TEXT, '<NULL>')
        || '; total_approved_amount=' || COALESCE(eeld.total_approved_amount::TEXT, '<NULL>')
        || '; approved_amount_capture_rate=' || COALESCE(eeld.approved_amount_capture_rate::TEXT, '<NULL>')
        || '; total_requested_expected_loss_amount=' || COALESCE(eeld.total_requested_expected_loss_amount::TEXT, '<NULL>')
        || '; total_approved_expected_loss_amount=' || COALESCE(eeld.total_approved_expected_loss_amount::TEXT, '<NULL>')
        || '; approved_expected_loss_rate=' || COALESCE(eeld.approved_expected_loss_rate::TEXT, '<NULL>')
    ) AS observed_value,

    'Approved exposure and approved Expected Loss should be interpretable through outcome mix, product policy, counteroffer treatment, and no-offer conventions.'
        AS expected_behavior,

    'This is a synthetic strategy economics diagnostic, not a production loss forecast or profitability measure.'
        AS interpretation

FROM exposure_expected_loss_diagnostics eeld

UNION ALL

SELECT
    'COUNTEROFFER_VALIDATION',
    'Counteroffer feasibility and final convention review',
    'COUNTEROFFER',

    CASE
        WHEN cd.preliminary_counteroffer_rows = 0
            THEN 'NOT_APPLICABLE'

        WHEN cd.counteroffer_reason_family_violation_rows = 0
         AND cd.final_counteroffer_rows = cd.feasible_preliminary_counteroffer_rows
            THEN 'PASS'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'preliminary_counteroffer_rows=' || cd.preliminary_counteroffer_rows
        || '; feasible_preliminary_counteroffer_rows=' || cd.feasible_preliminary_counteroffer_rows
        || '; failed_preliminary_counteroffer_rows=' || cd.failed_preliminary_counteroffer_rows
        || '; final_counteroffer_rows=' || cd.final_counteroffer_rows
        || '; counteroffer_reason_family_violations=' || cd.counteroffer_reason_family_violation_rows
    ) AS observed_value,

    'Final COUNTEROFFER rows should come from feasible preliminary counteroffers and carry COUNTEROFFER reason family.'
        AS expected_behavior,

    'Failed preliminary counteroffers may resolve to MANUAL_REVIEW or DECLINE depending on failed_counteroffer_resolution; final COUNTEROFFER should be feasible.'
        AS interpretation

FROM counteroffer_diagnostics cd

UNION ALL

SELECT
    'MANUAL_REVIEW_VALIDATION',
    'Manual-review unresolved convention',
    'MANUAL_REVIEW',

    CASE
        WHEN mrd.manual_review_rows = 0
            THEN 'NOT_APPLICABLE'

        WHEN mrd.manual_review_unresolved_violation_rows = 0
            THEN 'PASS'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'manual_review_rows=' || mrd.manual_review_rows
        || '; manual_review_unresolved_violation_rows=' || mrd.manual_review_unresolved_violation_rows
    ) AS observed_value,

    'MANUAL_REVIEW rows should remain unresolved with NULL approved exposure / PTI / Expected Loss and no simulated offer exposure.'
        AS expected_behavior,

    'MANUAL_REVIEW is unresolved simulated strategy routing, not completed operational review.'
        AS interpretation

FROM manual_review_diagnostics mrd

UNION ALL

SELECT
    'DECLINE_POLICY_STOP_VALIDATION',
    'Decline zero-exposure and policy-stop convention',
    'DECLINE_POLICY_STOP',

    CASE
        WHEN dd.decline_rows = 0
            THEN 'NOT_APPLICABLE'

        WHEN dd.decline_reason_family_violation_rows = 0
         AND dd.decline_zero_exposure_violation_rows = 0
            THEN 'PASS'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'decline_rows=' || dd.decline_rows
        || '; decline_reason_family_violations=' || dd.decline_reason_family_violation_rows
        || '; decline_zero_exposure_violations=' || dd.decline_zero_exposure_violation_rows
        || '; hard_policy_stop_decline_rows=' || dd.hard_policy_stop_decline_rows
        || '; synthetic_risk_decline_trigger_rows=' || dd.synthetic_risk_decline_trigger_rows
        || '; dti_decline_trigger_rows=' || dd.dti_decline_trigger_rows
    ) AS observed_value,

    'DECLINE rows should follow zero-exposure conventions and carry POLICY_STOP reason family.'
        AS expected_behavior,

    'POLICY_STOP reason codes are internal simulated strategy explanation codes only.'
        AS interpretation

FROM decline_diagnostics dd

UNION ALL

SELECT
    'REASON_CODE_CONCENTRATION',
    'Top primary reason-code concentration',
    'EXPLAINABILITY_DIAGNOSTIC',

    CASE
        WHEN rcd.top_primary_reason_code_share IS NULL
            THEN 'REVIEW'

        WHEN rcd.top_primary_reason_code_share > 0.750000
            THEN 'REVIEW'

        ELSE 'PASS'
    END AS validation_status,

    'top_primary_reason_code_share=' || COALESCE(rcd.top_primary_reason_code_share::TEXT, '<NULL>')
        AS observed_value,

    'Reason-code concentration may be valid, but very high concentration should be explained before documentation.'
        AS expected_behavior,

    'High reason concentration may indicate a deliberate strategy posture, a narrow scenario, or a configuration issue requiring review.'
        AS interpretation

FROM reason_concentration rcd

UNION ALL

SELECT
    'OFFER_EXPOSURE_PROFILE',
    'Simulated offer-exposure flag convention',
    'OFFER_EXPOSURE',

    CASE
        WHEN oed.simulated_offer_exposure_flag_violation_rows = 0
         AND oed.offer_flag_wrong_outcome_rows = 0
         AND oed.non_offer_flag_positive_outcome_rows = 0
            THEN 'PASS'
        ELSE 'REVIEW'
    END AS validation_status,

    (
        'simulated_offer_exposure_rows=' || oed.simulated_offer_exposure_rows
        || '; simulated_offer_exposure_flag_violations=' || oed.simulated_offer_exposure_flag_violation_rows
        || '; offer_flag_wrong_outcome_rows=' || oed.offer_flag_wrong_outcome_rows
        || '; non_offer_flag_positive_outcome_rows=' || oed.non_offer_flag_positive_outcome_rows
    ) AS observed_value,

    'simulated_offer_exposure_flag should be TRUE only for APPROVE and COUNTEROFFER and FALSE for MANUAL_REVIEW and DECLINE.'
        AS expected_behavior,

    'Simulated offer exposure is not booked, funded, operational, or real applicant exposure.'
        AS interpretation

FROM offer_exposure_diagnostics oed

UNION ALL

SELECT
    'EDGE_CASE_VISIBILITY',
    'Mixed-signal and borderline profile visibility',
    'EDGE_CASE_DIAGNOSTIC',

    CASE
        WHEN ecd.mixed_signal_profile_rate > 0.300000
          OR ecd.borderline_profile_rate > 0.300000
            THEN 'REVIEW'
        ELSE 'PASS'
    END AS validation_status,

    (
        'mixed_signal_profile_rate=' || COALESCE(ecd.mixed_signal_profile_rate::TEXT, '<NULL>')
        || '; borderline_profile_rate=' || COALESCE(ecd.borderline_profile_rate::TEXT, '<NULL>')
    ) AS observed_value,

    'Mixed-signal and borderline profiles should be visible and explainable but not unexpectedly dominant.'
        AS expected_behavior,

    'REVIEW indicates edge-case concentration should be interpreted using Section 14.16 samples and reason-code diagnostics.'
        AS interpretation

FROM edge_case_diagnostics ecd

UNION ALL

SELECT
    'ARCHIVE_READINESS',
    'Current latest-run slice archived',
    'ARCHIVE_CONTEXT',

    CASE
        WHEN ac.archive_table_exists IS DISTINCT FROM TRUE
            THEN 'NOT_APPLICABLE'

        WHEN ac.archive_readiness_status = 'CURRENT_LATEST_RUN_SLICE_ARCHIVED'
            THEN 'PASS'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'archive_table_exists=' || COALESCE(ac.archive_table_exists::TEXT, '<NULL>')
        || '; archive_inserted_ts_column_exists=' || COALESCE(ac.archive_inserted_ts_column_exists::TEXT, '<NULL>')
        || '; latest_run_rows=' || COALESCE(ac.latest_run_rows::TEXT, '<NULL>')
        || '; current_archived_slice_rows=' || COALESCE(ac.current_archived_slice_rows::TEXT, '<NULL>')
        || '; current_archived_slice_null_archive_ts_rows=' || COALESCE(ac.current_archived_slice_null_archive_ts_rows::TEXT, '<NULL>')
        || '; archive_readiness_status=' || COALESCE(ac.archive_readiness_status, '<NULL>')
    ) AS observed_value,

    'When archive persistence is intended, the current latest-run slice should be present in the archive with matching row count and populated archive_inserted_ts.'
        AS expected_behavior,

    'Archive readiness is context for comparison and evidence. Missing archive may be acceptable for ad hoc runs but should be reviewed for formal campaign evidence.'
        AS interpretation

FROM archive_context ac

UNION ALL

SELECT
    'MATCHED_COMPARISON_READINESS',
    'Selected Section 13 comparison readiness',
    'COMPARISON_CONTEXT',

    CASE
        WHEN cc.readiness_status = 'READY_FOR_MATCHED_COMPARISON'
            THEN 'PASS'

        WHEN cc.readiness_status ILIKE 'NOT_APPLICABLE%'
            THEN 'NOT_APPLICABLE'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'readiness_status=' || COALESCE(cc.readiness_status, '<NULL>')
        || '; matched_application_id_count=' || COALESCE(cc.matched_application_id_count::TEXT, '<NULL>')
        || '; baseline_only_application_id_count=' || COALESCE(cc.baseline_only_application_id_count::TEXT, '<NULL>')
        || '; challenger_only_application_id_count=' || COALESCE(cc.challenger_only_application_id_count::TEXT, '<NULL>')
    ) AS observed_value,

    'Matched comparison should be READY_FOR_MATCHED_COMPARISON before baseline / challenger deltas are interpreted.'
        AS expected_behavior,

    'If Section 13 was not run or comparison is not ready, latest-run validation can continue, but matched comparison evidence should be treated as not applicable or requiring review.'
        AS interpretation

FROM comparison_context cc

UNION ALL

SELECT
    'MATCHED_SOURCE_CONSISTENCY',
    'Matched baseline / challenger immutable source fields',
    'COMPARISON_CONTEXT',

    CASE
        WHEN sc.source_consistency_status = 'SOURCE_FIELDS_MATCH'
            THEN 'PASS'

        WHEN sc.source_consistency_status ILIKE 'NOT_APPLICABLE%'
          OR sc.source_consistency_status = 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE'

        ELSE 'REVIEW'
    END AS validation_status,

    (
        'source_consistency_status=' || COALESCE(sc.source_consistency_status, '<NULL>')
        || '; matched_application_count=' || COALESCE(sc.matched_application_count::TEXT, '<NULL>')
        || '; source_field_mismatch_count=' || COALESCE(sc.source_field_mismatch_count::TEXT, '<NULL>')
    ) AS observed_value,

    'Matched comparison should have zero immutable Module 1 source-field mismatches before deltas are interpreted as pure Module 2 strategy movement.'
        AS expected_behavior,

    'Source-field mismatches may indicate population drift, source-selection error, upstream scenario mismatch, or archive corruption.'
        AS interpretation

FROM source_context sc;



/***************************************************************************************************
SECTION 14.20 — VALIDATION STATUS SUMMARY REVIEW OUTPUTS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide compact outputs for reviewing the validation status summary that Section 16 will persist.

    Section 14.20 answers:

        "What validation areas passed, what requires interpretation, and what is not applicable for
         this run?"

SQL PURPOSE:
    1. Display all validation status rows.
    2. Summarize validation status counts.
    3. Display REVIEW / NOT_APPLICABLE items.
    4. Provide a compact Section 14 completion status.

BOUNDARY:
    These are temporary validation outputs only.

    Persistent evidence capture occurs in Section 16.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.20A Full validation status summary.

Purpose:
    Main documentation-ready Section 14 status table.

Expected:
    Review every row with validation_status in ('REVIEW', 'NOT_APPLICABLE') before writing final
    narrative.

Boundary:
    REVIEW is not automatic invalidation.
    NOT_APPLICABLE is context-dependent.
-----------------------------------------------------------------------------------------------*/

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation

FROM tmp_m2_validation_status_summary

ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        WHEN 'PASS' THEN 3
        ELSE 99
    END,
    validation_area,
    validation_test_name;



/*-----------------------------------------------------------------------------------------------
14.20B Validation status rollup.

Purpose:
    Summarize the number of PASS, REVIEW, and NOT_APPLICABLE rows.

Interpretation:
    REVIEW rows are not automatic invalidation.

    They are prompts for interpretation before documentation.
-----------------------------------------------------------------------------------------------*/

SELECT
    validation_status,
    COUNT(*) AS validation_test_count

FROM tmp_m2_validation_status_summary

GROUP BY validation_status

ORDER BY
    CASE validation_status
        WHEN 'PASS' THEN 1
        WHEN 'REVIEW' THEN 2
        WHEN 'NOT_APPLICABLE' THEN 3
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
14.20C REVIEW and NOT_APPLICABLE validation items.

Purpose:
    Provide a compact list of items that need interpretation or context.

Use:
    These rows are the quickest bridge from SQL QA evidence to validation-summary drafting notes.
-----------------------------------------------------------------------------------------------*/

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation

FROM tmp_m2_validation_status_summary

WHERE validation_status IN ('REVIEW', 'NOT_APPLICABLE')

ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        ELSE 99
    END,
    validation_area,
    validation_test_name;



/*-----------------------------------------------------------------------------------------------
14.20D Section 14 completion status.

Purpose:
    Provide one compact status row for downstream Section 16 evidence capture.

Expected:
    section_14_validation_status =
        SECTION_14_VALIDATION_SUMMARY_READY_FOR_EVIDENCE_CAPTURE

Interpretation:
    REVIEW items may still be present.

    They are carried into Section 16 as evidence prompts and should be interpreted before final
    narrative drafting.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS validation_status_rows,

    COUNT(*) FILTER (WHERE validation_status = 'PASS')
        AS pass_rows,

    COUNT(*) FILTER (WHERE validation_status = 'REVIEW')
        AS review_rows,

    COUNT(*) FILTER (WHERE validation_status = 'NOT_APPLICABLE')
        AS not_applicable_rows,

    COUNT(*) FILTER (
        WHERE validation_area IN (
            'STRUCTURAL_INTEGRITY',
            'FINAL_OUTPUT_CONVENTIONS',
            'REASON_CODE_COVERAGE'
        )
          AND validation_status <> 'PASS'
    ) AS core_validation_review_rows,

    CASE
        WHEN COUNT(*) = 0
            THEN 'SECTION_14_VALIDATION_SUMMARY_NOT_CREATED'

        WHEN COUNT(*) FILTER (
            WHERE validation_area IN (
                'STRUCTURAL_INTEGRITY',
                'FINAL_OUTPUT_CONVENTIONS',
                'REASON_CODE_COVERAGE'
            )
              AND validation_status <> 'PASS'
        ) = 0
            THEN 'SECTION_14_VALIDATION_SUMMARY_READY_FOR_EVIDENCE_CAPTURE'

        ELSE 'SECTION_14_CORE_VALIDATION_REVIEW_REQUIRED_BEFORE_EVIDENCE_CAPTURE'
    END AS section_14_validation_status

FROM tmp_m2_validation_status_summary;



/***************************************************************************************************
END OF SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions existed and contained rows.
    2. Latest-run validation scope was displayed.
    3. Latest-run structural integrity diagnostics were displayed.
    4. Final decision distribution was displayed.
    5. Final flag reconciliation diagnostics were displayed.
    6. Product-level strategy QA was displayed.
    7. Score-band strategy QA was displayed.
    8. Product × score decision matrix was displayed.
    9. Synthetic estimated-risk ordering QA was displayed.
    10. Requested PTI affordability QA was displayed.
    11. DTI capacity QA was displayed.
    12. Requested versus approved exposure and Expected Loss QA was displayed.
    13. Counteroffer validation diagnostics were displayed.
    14. Manual-review validation diagnostics were displayed.
    15. Decline / policy-stop validation diagnostics were displayed.
    16. Simulated reason-code coverage diagnostics were displayed.
    17. Simulated offer-exposure profile diagnostics were displayed.
    18. Mixed-signal and edge-case review outputs were displayed.
    19. Final output convention validation was displayed.
    20. Archive-readiness context was displayed.
    21. Matched comparison readiness context was displayed when Section 13 context was available.
    22. Matched source-field consistency context was displayed when Section 13 context was available.
    23. tmp_m2_validation_status_summary was created.
    24. Validation status rollups and REVIEW / NOT_APPLICABLE rows are available for review.

Section 14 established:
    1. The read-only latest-run validation evidence layer.
    2. The compact validation status summary consumed by Section 16.
    3. The validation interpretation bridge from SQL QA outputs to executive evidence capture.
    4. Compatibility with Section 13 matched comparison readiness and source-consistency helpers.
    5. Compatibility with Section 16 validation evidence persistence.

No latest-run rows have been modified.
No archive rows have been modified.
No campaign registry rows have been modified.
No comparison registry rows have been modified.
No strategy parameters have been modified.
No product-policy parameters have been modified.
No decision outcomes have been recalculated.
No approved exposure values have been recalculated.
No approved payment proxy values have been recalculated.
No approved PTI values have been recalculated.
No approved Expected Loss values have been recalculated.
No simulated reason codes have been reassigned.
No evidence rows have been inserted.
No strategy frontier has been calculated.
No BRD or written Validation Summary has been drafted.

Next section:
    Section 15 should consume credit_decisioning_sim.strategy_decisions_archive and build the
    archive-backed strategy frontier summary and executive comparison view.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01623 -->


---

<a id="c038-m01624"></a>

### C038-M01624

**Andrew** · 2026-05-12T15:59:11.460000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01624 -->
evaluate the full, updated code now that our passes are complete
<!-- END_MESSAGE C038-M01624 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01645"></a>

### C038-M01645

**ChatGPT** · 2026-05-12T16:07:57.843291-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01645 -->
According to a document from 2026-05-12, the updated Module 2 code is now in strong **release-candidate / near-canonical** shape. I would not do another broad commentary rewrite. The remaining work should be limited to a final runtime execution pass and, at most, a few small hardening refinements. The uploaded file now includes the expanded section map through Section 17, including Section 16.9 for post-campaign frontier synchronization and Section 17 for final post-campaign acceptance. fileciteturn254file12

I did a static/code-structure review, not a live PostgreSQL execution. I checked continuity, section coverage, major object contracts, comment/parenthesis/DO-block balance, campaign roadmap shape, comparison-group shape, and the new Section 14 / 16.9 / 17 workflow alignment.

## Overall verdict

**Status: ready for final database execution testing.**

The code now reads like a governed end-to-end strategy simulation artifact rather than a collection of independent SQL queries. The major architecture is coherent:

Sections 0–3 now establish the job aid, profile-driven run selection, registry alignment, and fail-fast configuration controls. Section 2 clearly makes `selected_module2_run_id` the main operator control, makes `selected_comparison_group_id` optional / auto-derived, and documents the 36-run campaign and 17 comparison groups close to the operator edit point. fileciteturn254file13

Sections 4–10 preserve a clean staged decision pipeline: Module 1 source selection, segmentation, rule flags, preliminary routing, exposure treatment, final decision resolution, and simulated reason-code assignment. The code continues to preserve the correct boundary that `estimated_pd` is the Module 1 synthetic estimated-PD proxy, not a recalibrated Module 2 model output. fileciteturn254file5

Sections 11–13 are structurally aligned: latest-run materialization remains separate from archive persistence, archive grain is protected, and matched strategy comparison uses the archive and the comparison registry rather than inferring baseline / challenger from the latest-run table. The archive design continues to treat campaign IDs as evidence-linkage metadata rather than row-level archive grain. fileciteturn255file3

Section 14 is now substantially stronger. It has the right contract: validate `credit_decisioning_sim.strategy_decisions`, use archive / comparison context only as supporting evidence, tolerate missing Section 13 helpers as `NOT_APPLICABLE`, and materialize `tmp_m2_validation_status_summary` for Section 16. fileciteturn255file15turn254file10

Sections 15, 16, 16.9, and 17 now form a credible post-campaign evidence workflow: archive-wide frontier, per-run evidence capture, post-campaign frontier synchronization, and final acceptance. Section 16.9 explicitly refreshes Section 15-derived frontier fields into `credit_decisioning_sim.strategy_run_evidence_summary`, and Section 17 checks campaign completion after the full campaign sequence. fileciteturn254file1turn255file0turn254file0

## Static checks I performed

I found the expected major section structure from Section 0 through Section 17, including 16.9. Section 14 now includes 14.0 through 14.20, and the remaining post-campaign sections are present.

I also checked structural syntax indicators on the uploaded text file:

| Check | Result |
|---|---:|
| Block comments `/* ... */` | Balanced |
| Actual `DO $$ ... END $$;` blocks after removing comments | Balanced |
| Parentheses after removing comments / quoted strings | Balanced |
| Formal Module 2 campaign run catalog | 36 run-sequence rows |
| Formal comparison plan | 17 comparison groups |
| Section 14 validation summary rows | 18 validation areas |

Those are not a substitute for PostgreSQL execution, but they are good evidence that the final pasted file is structurally coherent.

## Highest-value improvements from the completed passes

The biggest improvement is **Section 2**. Moving from manually edited values to executable profile catalogs and a single `selected_module2_run_id` makes the module much safer to run. The run selector now clearly distinguishes the run being executed from the comparison being reviewed; this directly addresses the earlier confusion around M2-21 / M2-29 / M2-36 and registry matching. fileciteturn254file13

The second biggest improvement is **Section 14**. The validation framework now reads like a real validation evidence layer: structural integrity, output conventions, product behavior, score-band behavior, product × score behavior, risk ordering, PTI, DTI, exposure / Expected Loss, counteroffer, manual review, decline, reason codes, offer exposure, edge cases, archive readiness, comparison readiness, and source consistency. It also creates the exact evidence spine Section 16 needs. fileciteturn255file15turn254file10

The third biggest improvement is **Section 16.9**. This solves the awkward workflow issue we identified earlier: after a full campaign, Section 15 is archive-wide, while Section 16 evidence is captured run-by-run. Section 16.9 now formalizes the frontier-field refresh so users do not need an informal manual patch. fileciteturn254file1turn254file17

The fourth biggest improvement is **Section 17**. It now behaves like a true campaign acceptance control tower. It expects the completed campaign shape, including 36 active campaign runs, 17 comparison groups, 36 archived slices, 1,800,000 archived rows, 50,000 rows per slice, and 10 product-guardrail audit rows. It also includes the product-guardrail exact-value audit that closes the earlier M2-36 / 8,500 versus 85,000 type of risk. fileciteturn254file6turn254file0

## Items I would still tighten before calling it “final validated release”

These are not broad redesign items. They are small hardening items.

**1. Change the file banner from “FINAL VALIDATED RELEASE” to “VALIDATION-READY RELEASE CANDIDATE” until the new full file has executed cleanly.**

The current banner says `VERSION: V1.0 (FINAL VALIDATED RELEASE)`. That may be true after a clean run, but based only on this review, I would label it as validation-ready rather than final. Once the full script executes and Section 17 returns `MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS`, then “final validated release” is defensible.

**2. Add the new Section 14 helper tables to Section 1 cleanup.**

Section 14.0 correctly drops these helpers itself, so this is not a blocker:

```sql
tmp_m2_validation_archive_readiness_context
tmp_m2_validation_comparison_readiness_context
tmp_m2_validation_source_consistency_context
```

Still, Section 1’s purpose is broad clean-rerun reset. Adding those three to Section 1 would make the reset inventory fully aligned with the new Section 14 design.

**3. Consider strengthening Section 17 evidence completeness beyond “validation rows > 0.”**

Section 16.7 validates that the current run’s validation evidence row count matches `tmp_m2_validation_status_summary` at capture time. That is good. Section 17.7 and 17.20, however, mostly check that validation evidence exists for all runs, not that every run has the same complete validation-status row count. Section 14 now creates 18 validation status rows. A stronger campaign acceptance check would flag any run whose validation evidence row count differs from the campaign norm or from the expected Section 14 status count.

This is not urgent because Section 16.7 already guards normal execution, but Section 17 is the final control tower, so stricter completeness would be appropriate.

**4. Keep Section 13 “as needed” guidance explicit.**

For runs that are not part of a comparison group, Section 13 can legitimately be skipped. Section 14 now handles missing Section 13 context as `NOT_APPLICABLE`, which is correct. The code already says Section 13 is optional / contextual, but the user workflow should keep emphasizing that Section 13 is not required for every single run.

## Product guardrail check

The product-guardrail profile and Section 17.19 exact-value audit appear aligned. In the product-policy profile, the `PRODUCT_GUARDRAIL_PRODUCT_POLICY` row for `UNSECURED_PERSONAL_LOAN` uses the intended tightened values, including `product_decline_min_requested_el = 8500.00`, `product_approved_el_cap = 2000.00`, and `product_max_approved_amount = 27500.00`. The `REVOLVING_LINE` guardrail row uses `product_decline_min_requested_el = 6500.00`, `product_approved_el_cap = 1400.00`, and `product_max_approved_amount = 16000.00`. Section 17.19 audits those same expected values across the five product-guardrail runs and expects 10 audited product rows. fileciteturn254file6

That means the earlier 85,000-style error risk is now explicitly guarded.

## Final recommendation

Treat this uploaded file as the **canonical release candidate** and do not do another large commentary pass.

The next step should be a controlled runtime validation:

1. Run one baseline slice, preferably M2-01, through Sections 1–16.8.
2. Confirm Section 14 produces `tmp_m2_validation_status_summary`.
3. Confirm Section 16 captures one executive row, validation rows, one parameter snapshot, and product × score segment evidence.
4. Run a product-guardrail slice, preferably M2-36, and confirm Section 17.19 shows all product guardrail values match.
5. After the full campaign, rerun Section 15, run Section 16.9, then run Section 17.
6. Final acceptance target: `MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS`.

My assessment: **the architecture is sound, the workflow is now much clearer, and the evidence / acceptance framework is strong enough to support the eventual BRD, Validation Summary, README, and LinkedIn storyline work.**
<!-- END_MESSAGE C038-M01645 -->


---

<a id="c038-m01647"></a>

### C038-M01647

**Andrew** · 2026-05-12T16:41:31.459000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01647 -->
please give me before and after code changes (if any) for items 2-4 above: 2. Add the new Section 14 helper tables to Section 1 cleanup.; 3. Consider strengthening Section 17 evidence completeness beyond “validation rows > 0.”; 4. Keep Section 13 “as needed” guidance explicit.
<!-- END_MESSAGE C038-M01647 -->


---

<a id="c038-m01657"></a>

### C038-M01657

**ChatGPT** · 2026-05-12T16:48:09.209579-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01657 -->
According to a document from 2026-05-12, I would make **two actual code changes** and **one comment-only guidance change**. Section 14 now creates three helper context tables, but Section 1 currently only drops `tmp_m2_validation_status_summary`; adding those helper drops makes the clean-rerun reset fully aligned with the new Section 14 design. fileciteturn258file6turn258file17 Section 17 already expects evidence coverage across 36 campaign runs, but its current evidence checks treat validation evidence as complete when rows are merely `> 0`; I would tighten that to the current Section 14 expected count of **18 validation status rows per run**. fileciteturn257file0

## 2. Add the new Section 14 helper tables to Section 1 cleanup

**Recommendation: yes, make this change.**

This is a small, safe Section 1 cleanup alignment. Section 14.0 already drops and recreates these helpers, so this is not required for correctness, but Section 1 is the clean full-rerun reset and should include them.

### Before

Find this block in **Section 1.4**:

```sql
-- Section 14 compact validation status summary.
-- Recreated after latest-run QA completes.
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

### After

Replace it with:

```sql
-- Section 14 archive-readiness context helper.
-- Recreated during Section 14.0 dependency preflight.
DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;

-- Section 14 comparison-readiness context helper.
-- Recreated during Section 14.0 dependency preflight.
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;

-- Section 14 matched source-field consistency context helper.
-- Recreated during Section 14.0 dependency preflight.
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;

-- Section 14 compact validation status summary.
-- Recreated after latest-run QA completes.
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

## 3. Strengthen Section 17 evidence completeness beyond `validation_rows > 0`

**Recommendation: yes, make this change.**

The current Section 16.7 run-level gatekeeper already validates that the current run’s persistent validation evidence row count matches `tmp_m2_validation_status_summary`, which is good. fileciteturn256file7 Section 17 is the final campaign-level acceptance control tower, so it should also catch any stale, missing, or partially captured validation evidence after reruns.

For the current Section 14 design, `tmp_m2_validation_status_summary` materializes **18 validation areas**, so Section 17 can require **18 validation evidence rows per campaign run**. If we later add or remove validation status rows in Section 14, we should update this value.

### 3A. Section 17.7 — evidence coverage summary

#### Before

Current Section 17.7 logic effectively treats validation evidence as complete if each run has at least one validation row:

```sql
validation_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS validation_rows
    FROM credit_decisioning_sim.strategy_run_validation_evidence
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

...

COUNT(*) FILTER (
    WHERE validation_rows > 0
) AS runs_with_validation_evidence_rows,

...

COUNT(*) FILTER (
    WHERE executive_rows <> 1
       OR parameter_rows <> 1
       OR validation_rows = 0
       OR segment_rows = 0
) AS evidence_coverage_issue_count,

CASE
    WHEN COUNT(*) = 36
     AND COUNT(*) FILTER (WHERE executive_rows = 1) = 36
     AND COUNT(*) FILTER (WHERE parameter_rows = 1) = 36
     AND COUNT(*) FILTER (WHERE validation_rows > 0) = 36
     AND COUNT(*) FILTER (WHERE segment_rows > 0) = 36
        THEN 'SECTION_16_EVIDENCE_COVERAGE_READY'

    ELSE 'REVIEW_SECTION_16_EVIDENCE_COVERAGE'
END AS evidence_campaign_status
```

#### After

Replace **the entire Section 17.7 query** with this tightened version:

```sql
/***************************************************************************************************
SECTION 17.7 — SECTION 16 EVIDENCE COVERAGE SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that persistent Section 16 evidence exists for every completed campaign run and that
    validation evidence was fully captured, not merely present.

EVIDENCE TABLES CHECKED:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

EXPECTED RESULT:
    registry_run_count = 36
    runs_with_one_executive_evidence_row = 36
    runs_with_one_parameter_snapshot_row = 36
    runs_with_complete_validation_evidence_rows = 36
    runs_with_segment_evidence_rows = 36
    evidence_coverage_issue_count = 0
    evidence_campaign_status = SECTION_16_EVIDENCE_COVERAGE_READY

WHY VALIDATION ROW COUNT IS EXACT:
    Section 14 currently materializes 18 validation status rows into tmp_m2_validation_status_summary.

    Section 16.3 persists those rows into:
        credit_decisioning_sim.strategy_run_validation_evidence

    Section 17 should therefore confirm each campaign run has the full validation evidence spine, not
    merely validation_rows > 0.

MAINTENANCE NOTE:
    If Section 14.19 later adds or removes validation status rows, update expected_validation_rows
    below.

***************************************************************************************************/

WITH expected_validation_status_rows AS (
    SELECT 18::BIGINT AS expected_validation_rows
),

registry_runs AS (
    SELECT
        module2_run_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
),

executive_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS executive_rows
    FROM credit_decisioning_sim.strategy_run_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

parameter_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS parameter_rows
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

validation_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS validation_rows
    FROM credit_decisioning_sim.strategy_run_validation_evidence
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

segment_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS segment_rows
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

joined AS (
    SELECT
        r.module2_run_id,

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(p.parameter_rows, 0) AS parameter_rows,
        COALESCE(v.validation_rows, 0) AS validation_rows,
        ev.expected_validation_rows,
        COALESCE(s.segment_rows, 0) AS segment_rows

    FROM registry_runs r

    CROSS JOIN expected_validation_status_rows ev

    LEFT JOIN executive_evidence e
        ON e.strategy_set_name = r.strategy_set_name
       AND e.strategy_name = r.strategy_name
       AND e.strategy_version = r.strategy_version
       AND e.module1_scenario_set_name = r.module1_scenario_set_name
       AND e.module1_scenario_name = r.module1_scenario_name
       AND e.population_id = r.population_id

    LEFT JOIN parameter_evidence p
        ON p.strategy_set_name = r.strategy_set_name
       AND p.strategy_name = r.strategy_name
       AND p.strategy_version = r.strategy_version
       AND p.module1_scenario_set_name = r.module1_scenario_set_name
       AND p.module1_scenario_name = r.module1_scenario_name
       AND p.population_id = r.population_id

    LEFT JOIN validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    LEFT JOIN segment_evidence s
        ON s.strategy_set_name = r.strategy_set_name
       AND s.strategy_name = r.strategy_name
       AND s.strategy_version = r.strategy_version
       AND s.module1_scenario_set_name = r.module1_scenario_set_name
       AND s.module1_scenario_name = r.module1_scenario_name
       AND s.population_id = r.population_id
)

SELECT
    COUNT(*) AS registry_run_count,

    MAX(expected_validation_rows) AS expected_validation_rows_per_run,

    COUNT(*) FILTER (
        WHERE executive_rows = 1
    ) AS runs_with_one_executive_evidence_row,

    COUNT(*) FILTER (
        WHERE parameter_rows = 1
    ) AS runs_with_one_parameter_snapshot_row,

    COUNT(*) FILTER (
        WHERE validation_rows = expected_validation_rows
    ) AS runs_with_complete_validation_evidence_rows,

    COUNT(*) FILTER (
        WHERE validation_rows <> expected_validation_rows
    ) AS runs_with_incomplete_validation_evidence_rows,

    MIN(validation_rows) AS min_validation_rows_per_run,
    MAX(validation_rows) AS max_validation_rows_per_run,

    COUNT(*) FILTER (
        WHERE segment_rows > 0
    ) AS runs_with_segment_evidence_rows,

    COUNT(*) FILTER (
        WHERE executive_rows <> 1
           OR parameter_rows <> 1
           OR validation_rows <> expected_validation_rows
           OR segment_rows = 0
    ) AS evidence_coverage_issue_count,

    CASE
        WHEN COUNT(*) = 36
         AND COUNT(*) FILTER (WHERE executive_rows = 1) = 36
         AND COUNT(*) FILTER (WHERE parameter_rows = 1) = 36
         AND COUNT(*) FILTER (WHERE validation_rows = expected_validation_rows) = 36
         AND COUNT(*) FILTER (WHERE segment_rows > 0) = 36
            THEN 'SECTION_16_EVIDENCE_COVERAGE_READY'

        ELSE 'REVIEW_SECTION_16_EVIDENCE_COVERAGE'
    END AS evidence_campaign_status

FROM joined;
```

### 3B. Section 17.8 — evidence detail by run

#### Before

Current Section 17.8 says each run should show `validation_rows > 0`, and the status also uses `> 0`:

```sql
COALESCE(v.validation_rows, 0) AS validation_rows,

...

CASE
    WHEN COALESCE(e.executive_rows, 0) = 1
     AND COALESCE(p.parameter_rows, 0) = 1
     AND COALESCE(v.validation_rows, 0) > 0
     AND COALESCE(s.segment_rows, 0) > 0
        THEN 'EVIDENCE_CAPTURE_READY'

    ELSE 'EVIDENCE_CAPTURE_REVIEW_REQUIRED'
END AS evidence_capture_status
```

#### After

Replace **Section 17.8** with this tightened version:

```sql
/***************************************************************************************************
SECTION 17.8 — SECTION 16 EVIDENCE COVERAGE DETAIL BY RUN
****************************************************************************************************

BUSINESS PURPOSE:
    Display evidence counts for each individual campaign run and confirm the full validation evidence
    spine was captured for each run.

EXPECTED RESULT:
    36 rows.

    Each row should generally show:
        executive_rows = 1
        parameter_rows = 1
        validation_rows = 18
        validation_evidence_row_gap = 0
        segment_rows = 25

WHY VALIDATION_ROWS SHOULD BE 18:
    Current Section 14.19 materializes 18 validation status rows.

    Section 16.3 should persist all 18 rows for each current run.

WHY SEGMENT_ROWS SHOULD BE 25:
    Current Module 2 campaign uses:

        5 products × 5 score bands = 25 product × score evidence rows per run.

***************************************************************************************************/

WITH expected_validation_status_rows AS (
    SELECT 18::BIGINT AS expected_validation_rows
),

registry_runs AS (
    SELECT
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
        population_id
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
),

executive_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS executive_rows
    FROM credit_decisioning_sim.strategy_run_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

parameter_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS parameter_rows
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

validation_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS validation_rows
    FROM credit_decisioning_sim.strategy_run_validation_evidence
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

segment_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS segment_rows
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
)

SELECT
    r.module2_run_id,
    r.run_sequence_number,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    r.strategy_name,
    r.strategy_version,

    COALESCE(e.executive_rows, 0) AS executive_rows,
    COALESCE(p.parameter_rows, 0) AS parameter_rows,

    ev.expected_validation_rows,
    COALESCE(v.validation_rows, 0) AS validation_rows,
    COALESCE(v.validation_rows, 0) - ev.expected_validation_rows AS validation_evidence_row_gap,

    COALESCE(s.segment_rows, 0) AS segment_rows,

    CASE
        WHEN COALESCE(e.executive_rows, 0) = 1
         AND COALESCE(p.parameter_rows, 0) = 1
         AND COALESCE(v.validation_rows, 0) = ev.expected_validation_rows
         AND COALESCE(s.segment_rows, 0) > 0
            THEN 'EVIDENCE_CAPTURE_READY'

        ELSE 'EVIDENCE_CAPTURE_REVIEW_REQUIRED'
    END AS evidence_capture_status

FROM registry_runs r

CROSS JOIN expected_validation_status_rows ev

LEFT JOIN executive_evidence e
    ON e.strategy_set_name = r.strategy_set_name
   AND e.strategy_name = r.strategy_name
   AND e.strategy_version = r.strategy_version
   AND e.module1_scenario_set_name = r.module1_scenario_set_name
   AND e.module1_scenario_name = r.module1_scenario_name
   AND e.population_id = r.population_id

LEFT JOIN parameter_evidence p
    ON p.strategy_set_name = r.strategy_set_name
   AND p.strategy_name = r.strategy_name
   AND p.strategy_version = r.strategy_version
   AND p.module1_scenario_set_name = r.module1_scenario_set_name
   AND p.module1_scenario_name = r.module1_scenario_name
   AND p.population_id = r.population_id

LEFT JOIN validation_evidence v
    ON v.strategy_set_name = r.strategy_set_name
   AND v.strategy_name = r.strategy_name
   AND v.strategy_version = r.strategy_version
   AND v.module1_scenario_set_name = r.module1_scenario_set_name
   AND v.module1_scenario_name = r.module1_scenario_name
   AND v.population_id = r.population_id

LEFT JOIN segment_evidence s
    ON s.strategy_set_name = r.strategy_set_name
   AND s.strategy_name = r.strategy_name
   AND s.strategy_version = r.strategy_version
   AND s.module1_scenario_set_name = r.module1_scenario_set_name
   AND s.module1_scenario_name = r.module1_scenario_name
   AND s.population_id = r.population_id

ORDER BY r.run_sequence_number;
```

### 3C. Section 17.20 — final acceptance rollup

#### Before

Current Section 17.20 counts only distinct runs with validation evidence:

```sql
validation_evidence AS (
    SELECT
        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS validation_evidence_run_count
    FROM credit_decisioning_sim.strategy_run_validation_evidence
),
```

and later checks:

```sql
AND ve.validation_evidence_run_count = 36
```

#### After

Replace the `validation_evidence AS (...)` CTE in **Section 17.20** with this version:

```sql
expected_validation_status_rows AS (
    SELECT 18::BIGINT AS expected_validation_rows
),

validation_evidence_by_run AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS validation_rows
    FROM credit_decisioning_sim.strategy_run_validation_evidence
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

validation_evidence AS (
    SELECT
        COUNT(*) AS validation_evidence_run_count,

        COUNT(*) FILTER (
            WHERE validation_rows = ev.expected_validation_rows
        ) AS complete_validation_evidence_run_count,

        COUNT(*) FILTER (
            WHERE validation_rows <> ev.expected_validation_rows
        ) AS incomplete_validation_evidence_run_count,

        MIN(validation_rows) AS min_validation_rows_per_run,
        MAX(validation_rows) AS max_validation_rows_per_run,

        ev.expected_validation_rows
    FROM validation_evidence_by_run v
    CROSS JOIN expected_validation_status_rows ev
    GROUP BY ev.expected_validation_rows
),
```

Then add these fields to the final `SELECT` output near the existing evidence fields:

```sql
ve.validation_evidence_run_count,
ve.complete_validation_evidence_run_count,
ve.incomplete_validation_evidence_run_count,
ve.expected_validation_rows,
ve.min_validation_rows_per_run,
ve.max_validation_rows_per_run,
```

Finally, replace both acceptance checks that currently say:

```sql
AND ve.validation_evidence_run_count = 36
```

with:

```sql
AND ve.validation_evidence_run_count = 36
AND ve.complete_validation_evidence_run_count = 36
AND ve.incomplete_validation_evidence_run_count = 0
AND ve.expected_validation_rows = 18
AND ve.min_validation_rows_per_run = 18
AND ve.max_validation_rows_per_run = 18
```

## 4. Keep Section 13 “as needed” guidance explicit

**Recommendation: yes, but comment-only. No SQL logic change is needed.**

The current Section 13 design is correct: it reads the archive, uses the comparison campaign registry, creates comparison readiness and source-consistency helpers, and remains read-only. fileciteturn257file7turn257file14 The only improvement is to make the operating guidance clearer so users know Section 13 is required for matched comparison evidence, but not required for every ad hoc latest-run QA pass.

### Before

Current Section 13 guidance says:

```sql
WHEN TO RUN THIS SECTION:
    Run Section 13 after:

        Section 12 — Strategy Decision Archive Persistence Layer

    Section 13 should be run before:

        Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics

    Section 13 outputs are also useful for:

        Section 15 — Strategy Frontier Summary and Executive Comparison View
        Section 16 — Strategy Run Evidence Capture and Executive Story Register
```

### After

Replace that subsection only with:

```sql
WHEN TO RUN THIS SECTION:
    Run Section 13 after:

        Section 12 — Strategy Decision Archive Persistence Layer

    Run Section 13 when matched baseline / challenger comparison evidence is needed.

    Most useful cases:
        1. A formal comparison group has both baseline and challenger slices archived.
        2. The user wants Section 14 to include matched comparison readiness context.
        3. The user wants Section 16 evidence capture to reflect comparison-ready context.
        4. The user is preparing campaign-level analysis, README interpretation, LinkedIn narrative,
           or Validation Summary evidence.

    Section 13 is not required for every ad hoc latest-run QA pass.

    If Section 13 has not been run in the current session:
        Section 14 can still validate the latest-run output.
        Section 14 will treat matched comparison readiness and source consistency as NOT_APPLICABLE
        context rather than failing solely because Section 13 helper tables are absent.

    For the formal full campaign:
        run Section 13 after the relevant archived baseline / challenger slices exist and before the
        Section 14 / Section 16 evidence pass where comparison context should be captured.

    Section 13 outputs are also useful for:

        Section 15 — Strategy Frontier Summary and Executive Comparison View
        Section 16 — Strategy Run Evidence Capture and Executive Story Register
```

## Net recommendation

Make all three updates:

1. **Section 1 cleanup:** actual code patch.
2. **Section 17 evidence completeness:** actual code patch.
3. **Section 13 as-needed guidance:** comment-only patch.

These are targeted hardening changes, not another design pass.
<!-- END_MESSAGE C038-M01657 -->


---

<a id="c038-m01658"></a>

### C038-M01658

**Andrew** · 2026-05-12T16:52:27.975000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01658 -->
please give me before and after code changes for item 2 above: 2. Add the new Section 14 helper tables to Section 1 cleanup.; 
<!-- END_MESSAGE C038-M01658 -->


---

<a id="c038-m01661"></a>

### C038-M01661

**ChatGPT** · 2026-05-12T16:53:48.649749-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01661 -->
Yes. This is a **small Section 1.4 cleanup patch only**. Your current Section 1 cleanup already resets temporary archive, comparison, validation, and frontier helper objects, but the Section 14 helper cleanup currently only drops `tmp_m2_validation_status_summary`. The new Section 14 design also creates three context helpers that should be included in the clean-rerun reset. fileciteturn259file0

## Before

Find this block in **Section 1.4**:

```sql
DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_campaign_registry_map;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;
```

## After

Replace only that portion with this:

```sql
DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

-- Section 14 archive-readiness context helper.
-- Recreated during Section 14.0 dependency preflight.
DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;

-- Section 14 comparison-readiness context helper.
-- Recreated during Section 14.0 dependency preflight.
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;

-- Section 14 matched source-field consistency context helper.
-- Recreated during Section 14.0 dependency preflight.
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;

-- Section 14 compact validation status summary.
-- Recreated after latest-run QA completes.
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_campaign_registry_map;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;
```

No other Section 1 changes are needed for this item. Because each line uses `DROP TABLE IF EXISTS`, this is safe even when Section 14 has not been run yet.
<!-- END_MESSAGE C038-M01661 -->


---

<a id="c038-m01662"></a>

### C038-M01662

**Andrew** · 2026-05-12T17:00:46.448000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01662 -->
show me the change in section 14 as well please
<!-- END_MESSAGE C038-M01662 -->


---

<a id="c038-m01665"></a>

### C038-M01665

**ChatGPT** · 2026-05-12T17:03:17.139673-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01665 -->
According to a document from 2026-05-12, Section 14 already has the matching helper-table logic: the Section 14 header lists the three temporary context helpers, Section 14.0 resets them, Section 14.0 creates/populates them, and Section 14.18 / 14.19 consume them. fileciteturn260file5turn260file3turn260file0turn260file2

So: **if your current Section 14 already contains Section 14.0 from our latest pass, no further Section 14 change is needed.** The Section 1 cleanup patch is just making Section 1 consistent with what Section 14 already creates and resets.

## Section 14 change — header touchpoint

### Before

Older Section 14 language only called out the validation summary as the temporary validation output:

```sql
TEMPORARY VALIDATION OUTPUT:
    tmp_m2_validation_status_summary
```

### After

The updated Section 14 header should show both the final validation summary and the three Section 14.0 context helpers:

```sql
TEMPORARY OUTPUT CREATED LATER IN SECTION 14:
    tmp_m2_validation_status_summary

TEMPORARY CONTEXT HELPERS CREATED IN SECTION 14.0:
    tmp_m2_validation_archive_readiness_context
    tmp_m2_validation_comparison_readiness_context
    tmp_m2_validation_source_consistency_context
```

Your current updated file already reflects this design: Section 14 lists those three context helpers as created in Section 14.0. fileciteturn260file7

## Section 14 change — Section 14.0A reset block

This is the direct Section 14 match to the Section 1 cleanup change.

### Before

If your Section 14 reset block only has this:

```sql
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

### After

Replace it with this:

```sql
DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

Your current updated file already has this exact Section 14.0A reset pattern. fileciteturn260file3

## Section 14 change — helper creation blocks

The reset block is not enough by itself; Section 14.0 also needs to create the helper tables. The updated Section 14 already does this.

### Before

Older Section 14 did not have a Section 14.0 preflight/helper layer and moved directly into validation scope / QA.

### After

Section 14 now includes:

```sql
/***************************************************************************************************
SECTION 14.0 — VALIDATION DEPENDENCY PREFLIGHT AND OPTIONAL CONTEXT HELPERS
****************************************************************************************************/
```

and then creates these three helpers:

```sql
CREATE TEMP TABLE tmp_m2_validation_archive_readiness_context (
    archive_table_exists                                    BOOLEAN,
    archive_inserted_ts_column_exists                       BOOLEAN,
    strategy_set_name                                       TEXT,
    strategy_name                                           TEXT,
    strategy_version                                        TEXT,
    module1_scenario_set_name                               TEXT,
    module1_scenario_name                                   TEXT,
    population_id                                           TEXT,
    latest_run_rows                                         BIGINT,
    latest_run_distinct_application_id_count                BIGINT,
    current_archived_slice_rows                             BIGINT,
    current_archived_slice_distinct_application_id_count    BIGINT,
    current_archived_slice_null_archive_ts_rows             BIGINT,
    archive_readiness_status                                TEXT
) ON COMMIT PRESERVE ROWS;
```

```sql
CREATE TEMP TABLE tmp_m2_validation_comparison_readiness_context (
    comparison_group_id                              TEXT,
    comparison_set_name                              TEXT,
    showcase_id                                      TEXT,
    showcase_name                                    TEXT,
    baseline_module2_run_id                          TEXT,
    challenger_module2_run_id                        TEXT,
    module1_scenario_set_name                        TEXT,
    module1_scenario_name                            TEXT,
    population_id                                    TEXT,
    baseline_strategy_set_name                       TEXT,
    baseline_strategy_name                           TEXT,
    baseline_strategy_version                        TEXT,
    challenger_strategy_set_name                     TEXT,
    challenger_strategy_name                         TEXT,
    challenger_strategy_version                      TEXT,
    same_strategy_selected_flag                      BOOLEAN,
    baseline_archived_row_count                      BIGINT,
    challenger_archived_row_count                    BIGINT,
    baseline_distinct_application_id_count           BIGINT,
    challenger_distinct_application_id_count         BIGINT,
    baseline_duplicate_application_row_count         BIGINT,
    challenger_duplicate_application_row_count       BIGINT,
    matched_application_id_count                     BIGINT,
    baseline_only_application_id_count               BIGINT,
    challenger_only_application_id_count             BIGINT,
    readiness_status                                 TEXT,
    expected_comparison_storyline                    TEXT,
    primary_metric_focus                             TEXT
) ON COMMIT PRESERVE ROWS;
```

```sql
CREATE TEMP TABLE tmp_m2_validation_source_consistency_context (
    comparison_group_id                          TEXT,
    comparison_set_name                          TEXT,
    baseline_module2_run_id                      TEXT,
    challenger_module2_run_id                    TEXT,
    module1_scenario_set_name                    TEXT,
    module1_scenario_name                        TEXT,
    population_id                                TEXT,
    readiness_status                             TEXT,
    matched_application_count                    BIGINT,
    source_field_mismatch_count                  BIGINT,
    product_type_mismatch_count                  BIGINT,
    score_band_mismatch_count                    BIGINT,
    credit_score_mismatch_count                  BIGINT,
    annual_income_mismatch_count                 BIGINT,
    requested_amount_mismatch_count              BIGINT,
    requested_payment_mismatch_count             BIGINT,
    requested_pti_mismatch_count                 BIGINT,
    amount_to_income_mismatch_count              BIGINT,
    estimated_pd_mismatch_count                  BIGINT,
    estimated_lgd_mismatch_count                 BIGINT,
    requested_expected_loss_mismatch_count       BIGINT,
    module1_lineage_mismatch_count               BIGINT,
    source_consistency_status                    TEXT
) ON COMMIT PRESERVE ROWS;
```

The archive-readiness helper is created in Section 14.0B, and the source-consistency helper is created in Section 14.0D; the comparison-readiness helper is also part of the Section 14.0 optional context flow. fileciteturn260file17turn260file10turn260file12

## Bottom line

For **item 2**, the only Section 14 code you should need to verify is this:

```sql
DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

If that block already exists in **Section 14.0A**, do not add anything else to Section 14. The Section 1 change simply mirrors this same cleanup inventory at the full-script reset level.
<!-- END_MESSAGE C038-M01665 -->


---

<a id="c038-m01667"></a>

### C038-M01667

**Andrew** · 2026-05-12T19:55:29.602000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01667 -->
I mean if we are already doing it in section 1, shouldn't we drop that from section 14A or do you recommend repeating it?
<!-- END_MESSAGE C038-M01667 -->


---

<a id="c038-m01670"></a>

### C038-M01670

**ChatGPT** · 2026-05-12T19:57:09.059006-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01670 -->
I recommend **repeating it**. Do **not** remove the Section 14.0A drops.

The reason is that Section 1 and Section 14.0A serve different operating modes:

**Section 1** is the **full-script clean rerun reset**. It clears temporary objects before a full Module 2 run from the beginning, and it also drops the replaceable latest-run table. Your Section 1 guidance explicitly warns not to run Section 1 when the goal is only to refresh later evidence or validation outputs, because it drops `credit_decisioning_sim.strategy_decisions`. fileciteturn261file0

**Section 14.0A** is the **local Section 14 rerun reset**. It lets you rerun Section 14 after Section 11, Section 12, or Section 13 without going back to Section 1. That matters because Section 14 now creates local context helpers for archive readiness, comparison readiness, and source consistency; stale versions of those helpers should not survive a Section 14 rerun. The updated Section 14 design depends on those helpers before materializing `tmp_m2_validation_status_summary`. fileciteturn261file17

So the right design is:

```sql
-- Section 1:
-- Global cleanup for full engine rerun.

DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

and also:

```sql
-- Section 14.0A:
-- Local cleanup so Section 14 can be rerun safely without Section 1.

DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

This is not harmful duplication. `DROP TABLE IF EXISTS` is cheap and idempotent. More importantly, it creates **section-level rerun safety**.

I would maybe tighten the Section 14.0A comment so the intent is clear:

```sql
/*-----------------------------------------------------------------------------------------------
14.0A Reset Section 14 temporary helper outputs.

Purpose:
    Remove prior Section 14 helper objects so current validation evidence reflects the current
    latest-run output, current archive state, and current optional Section 13 context.

Why this local reset remains even though Section 1 also drops these objects:
    Section 1 is the full-script reset and should not be run for every validation refresh because it
    drops the latest-run output table.

    Section 14 may be rerun independently after:
        Section 12 archive persistence,
        Section 13 matched comparison refresh,
        or a validation-only review pass.

    These local drops prevent stale Section 14 context helpers from surviving a Section 14 rerun.

Boundary:
    These are temporary objects only.
    Persistent latest-run, archive, registry, and evidence tables are not modified.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;
```

Bottom line: **keep both**. Section 1 provides full-run hygiene; Section 14.0A provides local rerun hygiene.
<!-- END_MESSAGE C038-M01670 -->


---

<a id="c038-m01671"></a>

### C038-M01671

**Andrew** · 2026-05-12T22:21:32.863000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01671 -->
the current 1.4 does not have that level of detail in comments (full section 1 attached). Please evaluate your suggested replacement and let me know if our section 1 commentary is still where we want it. /*----------------------------------------------------------------------------------------------- 
1.4 Clean reset of temporary archive, comparison, validation, and frontier helper objects.

Business purpose:
    Remove prior diagnostic helper objects so archive diagnostics, matched comparison, validation
    status, and frontier summaries are rebuilt from the current run and current archive state.

Section 13 helper interpretation:
    tmp_m2_strategy_comparison_params:
        canonical temporary comparison selector populated from the comparison campaign registry.

    tmp_m2_strategy_comparison_readiness:
        temporary readiness summary for the active baseline / challenger comparison.

    tmp_m2_strategy_comparison_matched_rows:
        temporary matched baseline / challenger row-level helper table.

    tmp_m2_strategy_comparison_source_consistency:
        temporary source-field consistency diagnostic for matched comparison.

Boundary:
    These temporary helper objects are not the governed archive itself.
    These temporary helper objects are not persistent evidence history.

    Section 12 controls archive persistence.
    Section 13 controls read-only matched comparison.
    Section 14 materializes validation status summary.
    Section 15 materializes strategy frontier summaries.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_source_selection_scope;
DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;
DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_registry;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_campaign_registry_map;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_baseline_deltas;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_efficiency;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_classification;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_segment_highlights;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_executive_summary;
<!-- END_MESSAGE C038-M01671 -->


**Attachments in export:** `Pasted text(174).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01674"></a>

### C038-M01674

**ChatGPT** · 2026-05-12T22:24:09.100342-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01674 -->
Yes — your **Section 1 commentary is still in the right style**. It is intentionally broader and cleaner than Section 14 because Section 1 is a reset / hygiene section, not a validation-teaching section. I would **not** add Section 14A-level detail into Section 1. That would make Section 1 too heavy.

The only gap is that **1.4 now needs to acknowledge the three new Section 14 context helpers** because the current 1.4 commentary says Section 14 materializes the validation status summary, but it does not yet mention the archive-readiness, comparison-readiness, and source-consistency helper tables that Section 14.0 now creates. Your current Section 1.4 already frames archive, comparison, validation, and frontier helper cleanup appropriately. fileciteturn261file0

My recommendation: **replace the current 1.4 block with the version below.** It keeps your existing commentary level, adds the new Section 14 helper interpretation, and avoids over-commenting every single `DROP TABLE`.

```sql
/*-----------------------------------------------------------------------------------------------
1.4 Clean reset of temporary archive, comparison, validation, and frontier helper objects.

Business purpose:
    Remove prior diagnostic helper objects so archive diagnostics, matched comparison, validation
    context, validation status, and frontier summaries are rebuilt from the current run and current
    archive state.

Section 13 helper interpretation:
    tmp_m2_strategy_comparison_params:
        canonical temporary comparison selector populated from the comparison campaign registry.

    tmp_m2_strategy_comparison_readiness:
        temporary readiness summary for the active baseline / challenger comparison.

    tmp_m2_strategy_comparison_matched_rows:
        temporary matched baseline / challenger row-level helper table.

    tmp_m2_strategy_comparison_source_consistency:
        temporary source-field consistency diagnostic for matched comparison.

Section 14 helper interpretation:
    tmp_m2_validation_archive_readiness_context:
        temporary archive-readiness context for the current latest-run slice.

    tmp_m2_validation_comparison_readiness_context:
        temporary Section 14 copy of Section 13 matched-comparison readiness, or NOT_APPLICABLE
        context when Section 13 has not been run.

    tmp_m2_validation_source_consistency_context:
        temporary Section 14 copy of Section 13 matched source-field consistency, or NOT_APPLICABLE
        context when Section 13 has not been run.

    tmp_m2_validation_status_summary:
        compact temporary validation evidence spine later consumed by Section 16.

Why Section 14 also drops these objects locally:
    Section 1 is the full-script clean rerun reset.

    Section 14.0A also drops the Section 14 validation helpers so Section 14 can be rerun safely
    without rerunning Section 1.

Boundary:
    These temporary helper objects are not the governed archive itself.
    These temporary helper objects are not persistent evidence history.

    Section 12 controls archive persistence.
    Section 13 controls read-only matched comparison.
    Section 14 controls latest-run validation context and validation status summary.
    Section 15 materializes strategy frontier summaries.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_source_selection_scope;
DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;
DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_registry;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_campaign_registry_map;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_baseline_deltas;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_efficiency;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_classification;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_segment_highlights;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_executive_summary;
```

This is the right balance: it updates Section 1 for the new Section 14 design without turning Section 1 into a second Section 14 explanation.
<!-- END_MESSAGE C038-M01674 -->


---

<a id="c038-m01675"></a>

### C038-M01675

**Andrew** · 2026-05-12T22:31:20.928000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01675 -->
can you make the 3C. Section 17.20 — final acceptance rollup clearer?  provide updated 17.20 as a full copy paste.  here is the current 17.20:
<!-- END_MESSAGE C038-M01675 -->


**Attachments in export:** `Pasted text(175).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_85.md) · [Next](Part_87.md)
