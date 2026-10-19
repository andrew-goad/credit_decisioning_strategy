# Module 2 Decision Simulator Build

## Part 08

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_07.md) · [Next](Part_09.md)

<a id="c038-m00174"></a>

### C038-M00174

**ChatGPT** · 2026-05-06T16:29:27.395318-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00174 -->
Section 13 is accepted with the targeted refinements below. Section 14 then adds the read-only QA and validation evidence layer for the completed latest-run Module 2 output. The design preserves Module 1’s validated boundaries: `estimated_pd` remains the finalized SQL field interpreted as the synthetic estimated-PD proxy, Expected Loss remains a comparative simulation construct, and scenario / strategy outputs remain controlled synthetic simulation outputs rather than forecasts or production decisions. fileciteturn4file0 Module 1’s validation confirms the deterministic, matched-comparison foundation that Module 2 extends into strategy-outcome comparison. fileciteturn4file1

---

# 1. Targeted Section 13 patches only

## Patch 13.A — Same-strategy comparison readiness check

If your current Section 13.2 already includes this exact logic, no further code change is needed. This locks the intended v1.0 behavior.

### BEFORE

```sql
CASE
    WHEN c.baseline_archived_row_count = 0
        THEN 'NOT_READY_BASELINE_MISSING'
```

### AFTER

```sql
CASE
    /*
    Same-strategy comparison is not a valid Module 2 v1.0 strategy delta comparison.

    A deterministic reproducibility test may be designed later, but Section 13 v1.0 is focused
    on baseline versus challenger strategy comparison.
    */
    WHEN p.baseline_strategy_set_name = p.challenger_strategy_set_name
     AND p.baseline_strategy_name = p.challenger_strategy_name
     AND p.baseline_strategy_version = p.challenger_strategy_version
        THEN 'NOT_READY_SAME_STRATEGY_SELECTED'

    WHEN c.baseline_archived_row_count = 0
        THEN 'NOT_READY_BASELINE_MISSING'
```

Also ensure this diagnostic field is present:

```sql
(
    p.baseline_strategy_set_name = p.challenger_strategy_set_name
    AND p.baseline_strategy_name = p.challenger_strategy_name
    AND p.baseline_strategy_version = p.challenger_strategy_version
) AS same_strategy_selected_flag,
```

---

## Patch 13.B — Null-sensitive approved-exposure metric clarification

Apply this convention anywhere Section 13 summarizes approved amount, approved PTI, or approved Expected Loss.

### BEFORE

```sql
SUM(approved_amount) AS total_approved_amount,
AVG(approved_amount) AS average_approved_amount,
AVG(approved_payment_to_income_ratio) AS average_approved_payment_to_income_ratio,
SUM(approved_expected_loss_amount) AS total_approved_expected_loss_amount,
AVG(approved_expected_loss_amount) AS average_approved_expected_loss_amount
```

### AFTER

```sql
/*
All-application metrics:
    Treat unresolved manual-review approved exposure as zero only for portfolio-level
    impact measurement.

Offer-row metrics:
    Describe only rows where the simulated strategy produced positive offer exposure.
*/
SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
    AS avg_approved_amount_offer_rows,

AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
    AS avg_approved_pti_offer_rows,

SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,
AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
    AS avg_approved_expected_loss_offer_rows
```

Apply the same naming convention to Section 13.3, 13.4, 13.7, and 13.9 outputs.

---

## Patch 13.C — Safe rate and percentage denominators

### BEFORE

```sql
COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') / COUNT(*) AS approval_rate
```

### AFTER

```sql
COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
    / NULLIF(COUNT(*), 0) AS approval_rate
```

For percentage-of-population outputs:

### BEFORE

```sql
100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS pct_of_matched_population
```

### AFTER

```sql
100.0 * COUNT(*)::NUMERIC
    / NULLIF(SUM(COUNT(*)) OVER (), 0) AS pct_of_matched_population
```

---

## Patch 13.D — Matched comparison denominator must use matched population

For the decision migration matrix, lock this denominator.

### BEFORE

```sql
ROUND(
    100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
    2
) AS pct_of_matched_population
```

### AFTER

```sql
/*
Denominator is the matched population only.

If baseline and challenger are not fully matched, this metric describes the matched subset.
The readiness query separately reports unmatched rows.
*/
ROUND(
    100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0),
    2
) AS pct_of_matched_population
```

---

## Patch 13.E — Terminology cleanup

Replace any output alias using `book`, `booked`, or `approved_book` terminology.

### BEFORE

```sql
approved_book_count
approved_book_avg_pd
booked_exposure_amount
```

### AFTER

```sql
simulated_offer_exposure_count
offer_rows_avg_synthetic_estimated_pd_proxy
simulated_offer_exposure_amount
```

Section 13 should consistently use:

```text
simulated offer exposure
offer rows
positive offer outcomes
simulated offer-exposure profile
```

---

## Patch 13.F — Reason-code movement includes family and code

Replace the matched reason-code migration query output in Section 13.8B.

### BEFORE

```sql
SELECT
    baseline_primary_reason_code,
    challenger_primary_reason_code,
    COUNT(*) AS matched_rows,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population
FROM matched
GROUP BY
    baseline_primary_reason_code,
    challenger_primary_reason_code
```

### AFTER

```sql
SELECT
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code,
    COUNT(*) AS matched_rows,
    ROUND(
        100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population
FROM matched
GROUP BY
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code
```

And ensure the `matched` CTE includes:

```sql
b.primary_reason_family AS baseline_primary_reason_family,
b.primary_reason_code AS baseline_primary_reason_code,
c.primary_reason_family AS challenger_primary_reason_family,
c.primary_reason_code AS challenger_primary_reason_code
```

---

# 2. Section 14 SQL only — Module 2 Validation, QA, and Strategy Outcome Diagnostics

```sql
/***************************************************************************************************
SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the full read-only QA and validation query framework for the completed latest-run
    Module 2 strategy output.

    Section 14 answers:

        "Does this completed Module 2 strategy run behave coherently, consistently, and within
         the documented simulation boundaries?"

SQL PURPOSE:
    1. Inspect credit_decisioning_sim.strategy_decisions as the primary latest-run output.
    2. Inspect credit_decisioning_sim.strategy_decisions_archive only for archive-readiness context.
    3. Validate structural integrity, decision distribution, segmentation behavior, risk ordering,
       affordability sensitivity, reason-code coverage, counteroffer behavior, manual-review
       behavior, simulated offer-exposure profile, and edge-case explainability.
    4. Produce documentation-ready validation evidence queries.
    5. Preserve a strictly read-only QA boundary.

READ-ONLY BOUNDARY:
    Section 14 does not insert, delete, update, or modify any table.
    Section 14 does not recalculate decision_outcome.
    Section 14 does not reassign simulated reason codes.
    Section 14 does not recalculate approved exposure.
    Section 14 does not recalculate approved Expected Loss.
    Section 14 does not insert archive rows.

WHY QA IS SEPARATED FROM OUTPUT CREATION AND ARCHIVE PERSISTENCE:
    Section 11 materializes the latest-run output.
    Section 12 persists archive rows.
    Section 13 compares archived strategy slices.

    Section 14 validates the completed latest-run output and provides evidence that the strategy
    result is coherent, explainable, and internally consistent.

WHY DECISION DISTRIBUTION IS NOT SUFFICIENT BY ITSELF:
    A strategy output can have plausible high-level rates while still failing on product behavior,
    affordability ordering, reason-code coverage, exposure conventions, or edge cases.

    Therefore Section 14 reviews:
        product behavior
        score-band behavior
        synthetic estimated-risk tier behavior
        requested PTI behavior
        DTI behavior
        requested versus approved exposure
        counteroffer feasibility
        manual-review unresolved population
        policy-stop behavior
        simulated reason-code coverage
        simulated offer exposure
        mixed-signal and borderline cases

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 14, estimated_pd is interpreted as the synthetic estimated-PD proxy.
    It is not recalculated.
    It is not treated as a calibrated production probability of default.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        Module 2 approved-exposure Expected Loss after simulated exposure treatment.

    Both are reviewed because strategy rules can change approved exposure while requested exposure
    remains the original application structure.

MANUAL REVIEW BOUNDARY:
    MANUAL_REVIEW remains unresolved by design.
    Manual-review rows should not have approved amount, approved PTI, or approved Expected Loss
    populated.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows.

    It means the simulated strategy output includes positive offer exposure.
    It does not imply operational account creation, funding, production approval, or real applicant
    treatment.

SIMULATED REASON-CODE BOUNDARY:
    primary_reason_code, secondary_reason_code, tertiary_reason_code, and triggered_reason_code_list
    are simulated strategy explanation codes.

    They support transparency, QA review, strategy interpretation, portfolio diagnostics, and
    decision-path traceability.

EDGE-CASE REVIEW:
    Edge cases should remain visible and explainable.

    Realistic overlap is not automatically a defect. It becomes a concern only if it dominates the
    output, violates conventions, or cannot be explained through product structure, borrower profile,
    affordability, synthetic estimated-risk tiering, rule triggers, or exposure-treatment diagnostics.

SECTION 14 IS NOT THE FINAL WRITTEN VALIDATION SUMMARY:
    Section 14 provides validation evidence queries.
    The written Validation Summary will be drafted later after the full SQL module has been executed
    and evidence outputs are reviewed.

***************************************************************************************************/



/***************************************************************************************************
SECTION 14.1 — LATEST-RUN STRUCTURAL INTEGRITY SUMMARY
****************************************************************************************************

Purpose:
    Confirm that the latest-run strategy_decisions table exists, is populated, and has the expected
    row-level integrity.

Expected interpretation:
    total rows should equal distinct application_id count.
    exactly one strategy version should be present in latest-run output.
    exactly one Module 1 scenario / population should be present unless multi-scenario processing is
    explicitly designed later.

***************************************************************************************************/

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_row_count,

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

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts
FROM credit_decisioning_sim.strategy_decisions;


/* Row count by Module 1 input source. */
SELECT
    module1_input_source,
    module1_source_table_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    module1_input_source,
    module1_source_table_name
ORDER BY
    module1_input_source,
    module1_source_table_name;


/* Strategy identity and Module 1 lineage inventory in latest-run output. */
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/***************************************************************************************************
SECTION 14.2 — FINAL DECISION DISTRIBUTION
****************************************************************************************************

Purpose:
    Summarize final simulated strategy outcomes.

Expected interpretation:
    every row should have exactly one final outcome.
    APPROVE and COUNTEROFFER represent simulated positive offer-exposure outcomes.
    MANUAL_REVIEW remains unresolved.
    DECLINE follows the zero-exposure convention.

***************************************************************************************************/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
        AS pct_of_population,

    COUNT(*) FILTER (WHERE approval_flag IS TRUE) AS approval_flag_count,
    COUNT(*) FILTER (WHERE counteroffer_flag IS TRUE) AS counteroffer_flag_count,
    COUNT(*) FILTER (WHERE manual_review_flag IS TRUE) AS manual_review_flag_count,
    COUNT(*) FILTER (WHERE decline_flag IS TRUE) AS decline_flag_count,
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_flag_count
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



/***************************************************************************************************
SECTION 14.3 — DECISION OUTCOME BY PRODUCT
****************************************************************************************************

Purpose:
    Confirm product-level strategy behavior.

Interpretation:
    Product-level outcomes should reflect product-specific policy parameters and structural differences.

Metric convention:
    all-app approved metrics use COALESCE to treat unresolved rows as zero for portfolio impact.
    offer-row metrics use FILTER where simulated_offer_exposure_flag = TRUE.

***************************************************************************************************/

WITH product_outcome AS (
    SELECT
        product_type_policy_key,
        decision_outcome,

        COUNT(*) AS row_count,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        product_type_policy_key,
        decision_outcome
)
SELECT
    product_type_policy_key,
    decision_outcome,
    row_count,

    ROUND(
        100.0 * row_count::NUMERIC
        / NULLIF(SUM(row_count) OVER (PARTITION BY product_type_policy_key), 0),
        2
    ) AS pct_within_product,

    avg_synthetic_estimated_pd_proxy,
    avg_requested_payment_to_income_ratio,
    avg_approved_pti_offer_rows,
    avg_requested_expected_loss_amount,
    avg_approved_expected_loss_all_apps,
    avg_approved_expected_loss_offer_rows
FROM product_outcome
ORDER BY
    product_type_policy_key,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.4 — DECISION OUTCOME BY SCORE BAND
****************************************************************************************************

Purpose:
    Validate directional risk ordering by score band.

Expected interpretation:
    Stronger score bands should generally show higher approval / offer rates.
    Weaker score bands should generally show higher manual review or decline rates.

    Perfect monotonicity is not required at every micro-segment because product mix, affordability,
    exposure structure, and behavioral signals can create realistic overlap.

***************************************************************************************************/

WITH score_summary AS (
    SELECT
        score_band_policy_key,

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
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY score_band_policy_key
),
score_outcome AS (
    SELECT
        score_band_policy_key,
        decision_outcome,
        COUNT(*) AS row_count,
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        score_band_policy_key,
        decision_outcome
)
SELECT
    o.score_band_policy_key,
    o.decision_outcome,
    o.row_count,

    ROUND(
        100.0 * o.row_count::NUMERIC / NULLIF(s.applications, 0),
        2
    ) AS pct_within_score_band,

    o.avg_synthetic_estimated_pd_proxy,
    o.avg_requested_payment_to_income_ratio,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate
FROM score_outcome o
JOIN score_summary s
    ON s.score_band_policy_key = o.score_band_policy_key
ORDER BY
    CASE o.score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    CASE o.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.5 — PRODUCT × SCORE DECISION MATRIX
****************************************************************************************************

Purpose:
    Show where strategy outcomes concentrate across product and credit quality.

This is one of the core validation outputs.

***************************************************************************************************/

SELECT
    product_type_policy_key,
    score_band_policy_key,

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
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
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



/***************************************************************************************************
SECTION 14.6 — RISK-TIER DECISION VALIDATION
****************************************************************************************************

Purpose:
    Validate that synthetic estimated-risk segmentation flows coherently into outcomes.

Expected interpretation:
    Higher synthetic risk tiers should generally show lower approval rates and higher review / decline
    rates.

Reminder:
    estimated_pd is the Module 1 synthetic estimated-PD proxy input, not a calibrated production PD.

***************************************************************************************************/

WITH risk_summary AS (
    SELECT
        strategy_risk_tier,

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
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY strategy_risk_tier
),
risk_outcome AS (
    SELECT
        strategy_risk_tier,
        decision_outcome,
        COUNT(*) AS row_count,
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        strategy_risk_tier,
        decision_outcome
)
SELECT
    o.strategy_risk_tier,
    o.decision_outcome,
    o.row_count,

    ROUND(
        100.0 * o.row_count::NUMERIC / NULLIF(s.applications, 0),
        2
    ) AS pct_within_risk_tier,

    o.avg_synthetic_estimated_pd_proxy,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate
FROM risk_outcome o
JOIN risk_summary s
    ON s.strategy_risk_tier = o.strategy_risk_tier
ORDER BY
    CASE o.strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    CASE o.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.7 — REQUESTED PTI / AFFORDABILITY DECISION VALIDATION
****************************************************************************************************

Purpose:
    Validate that requested-structure affordability pressure affects strategy outcomes.

Expected interpretation:
    Higher requested PTI buckets should generally show fewer clean approvals and more counteroffer,
    manual review, or decline outcomes.

***************************************************************************************************/

WITH pti_summary AS (
    SELECT
        requested_pti_bucket,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY requested_pti_bucket
),
pti_outcome AS (
    SELECT
        requested_pti_bucket,
        decision_outcome,
        COUNT(*) AS row_count,
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        requested_pti_bucket,
        decision_outcome
)
SELECT
    o.requested_pti_bucket,
    o.decision_outcome,
    o.row_count,

    ROUND(
        100.0 * o.row_count::NUMERIC / NULLIF(s.applications, 0),
        2
    ) AS pct_within_requested_pti_bucket,

    o.avg_requested_payment_to_income_ratio,
    o.avg_approved_pti_offer_rows,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate
FROM pti_outcome o
JOIN pti_summary s
    ON s.requested_pti_bucket = o.requested_pti_bucket
ORDER BY
    CASE o.requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    CASE o.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.8 — DTI CAPACITY DECISION VALIDATION
****************************************************************************************************

Purpose:
    Validate that DTI capacity pressure affects strategy routing.

Expected interpretation:
    Higher DTI should generally reduce clean approval likelihood and increase review / decline routing.

Boundary:
    DTI remains an existing-obligation capacity signal and is not directly fixed by counteroffer in
    Module 2 v1.0.

***************************************************************************************************/

WITH dti_summary AS (
    SELECT
        dti_bucket,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY dti_bucket
),
dti_outcome AS (
    SELECT
        dti_bucket,
        decision_outcome,
        COUNT(*) AS row_count,
        AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        dti_bucket,
        decision_outcome
)
SELECT
    o.dti_bucket,
    o.decision_outcome,
    o.row_count,

    ROUND(
        100.0 * o.row_count::NUMERIC / NULLIF(s.applications, 0),
        2
    ) AS pct_within_dti_bucket,

    o.avg_debt_to_income_ratio,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate
FROM dti_outcome o
JOIN dti_summary s
    ON s.dti_bucket = o.dti_bucket
ORDER BY
    CASE o.dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
        ELSE 99
    END,
    CASE o.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.9 — REQUESTED VS APPROVED EXPOSURE AND ECONOMICS BY OUTCOME
****************************************************************************************************

Purpose:
    Validate final amount and economics conventions.

Expected interpretation:
    APPROVE rows preserve requested amount and requested Expected Loss.
    COUNTEROFFER rows reduce approved amount and approved Expected Loss.
    DECLINE rows have zero approved exposure and zero approved Expected Loss.
    MANUAL_REVIEW rows remain unresolved with NULL approved exposure fields.

***************************************************************************************************/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_counteroffers,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
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



/***************************************************************************************************
SECTION 14.10 — COUNTEROFFER VALIDATION DIAGNOSTICS
****************************************************************************************************

Purpose:
    Validate that counteroffer outcomes are explainable and feasible.

Expected interpretation:
    Final COUNTEROFFER rows should show:
        approved_amount < requested_amount
        reduced approved PTI relative to requested PTI
        approved Expected Loss at or below relevant approved-exposure cap
        interpretable simulated reason-code assignment

***************************************************************************************************/


/* 14.10A Counteroffer summary. */
SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS final_counteroffer_rows,
    COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER') AS preliminary_counteroffer_rows,
    COUNT(*) FILTER (
        WHERE preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS TRUE
    ) AS feasible_counteroffers,
    COUNT(*) FILTER (
        WHERE preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS FALSE
    ) AS failed_counteroffers,

    COUNT(*) FILTER (
        WHERE preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS TRUE
    )::NUMERIC
    / NULLIF(COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER'), 0)
        AS counteroffer_feasibility_pass_rate,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_final_counteroffers,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_requested_pti_for_final_counteroffers,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_for_final_counteroffers,

    AVG(approved_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_expected_loss_for_final_counteroffers
FROM credit_decisioning_sim.strategy_decisions;


/* 14.10B Counteroffer feasibility failure reason distribution. */
SELECT
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE
GROUP BY counteroffer_feasibility_failure_reason
ORDER BY counteroffer_feasibility_failure_reason;


/* 14.10C Product × counteroffer feasibility summary. */
SELECT
    product_type_policy_key,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS preliminary_counteroffer_rows,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_amount_for_final_counteroffers,
    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_final_counteroffers
FROM credit_decisioning_sim.strategy_decisions
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag
ORDER BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag;


/* 14.10D Score band × counteroffer feasibility summary. */
SELECT
    score_band_policy_key,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS preliminary_counteroffer_rows,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_for_final_counteroffers
FROM credit_decisioning_sim.strategy_decisions
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



/***************************************************************************************************
SECTION 14.11 — MANUAL REVIEW VALIDATION DIAGNOSTICS
****************************************************************************************************

Purpose:
    Validate unresolved manual-review population.

Expected interpretation:
    Manual review should concentrate in unresolved, borderline, mixed-signal, or failed-counteroffer
    cases.

    Manual-review rows should not have approved_amount, approved PTI, or approved Expected Loss
    populated.

***************************************************************************************************/


/* 14.11A Manual review summary. */
SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_rows,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_synthetic_estimated_pd_proxy_manual_review,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_requested_payment_to_income_ratio_manual_review,

    AVG(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_requested_expected_loss_amount_manual_review,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS FALSE
    ) AS failed_counteroffer_to_manual_review_rows
FROM credit_decisioning_sim.strategy_decisions;


/* 14.11B Manual review by decision path. */
SELECT
    decision_path,
    COUNT(*) AS manual_review_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'MANUAL_REVIEW'
GROUP BY decision_path
ORDER BY decision_path;


/* 14.11C Manual review by primary reason code. */
SELECT
    primary_reason_code,
    COUNT(*) AS manual_review_rows,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_manual_review_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'MANUAL_REVIEW'
GROUP BY primary_reason_code
ORDER BY primary_reason_code;


/* 14.11D Mixed-signal profile × manual review count. */
SELECT
    mixed_signal_profile_type,
    COUNT(*) AS manual_review_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'MANUAL_REVIEW'
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


/* 14.11E Borderline profile × manual review count. */
SELECT
    borderline_profile_flag,
    COUNT(*) AS manual_review_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'MANUAL_REVIEW'
GROUP BY borderline_profile_flag
ORDER BY borderline_profile_flag;


/* 14.11F Manual review unresolved-exposure convention check. */
SELECT
    COUNT(*) AS manual_review_exposure_convention_violation_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'MANUAL_REVIEW'
  AND (
        approved_amount IS NOT NULL
     OR approved_payment_to_income_ratio IS NOT NULL
     OR approved_expected_loss_amount IS NOT NULL
  );



/***************************************************************************************************
SECTION 14.12 — DECLINE / POLICY-STOP VALIDATION DIAGNOSTICS
****************************************************************************************************

Purpose:
    Validate final no-offer strategy outcomes.

Expected interpretation:
    Declines should be explainable through policy-stop, severe synthetic risk, severe DTI,
    failed-counteroffer-to-decline, high requested PTI, requested Expected Loss, or exposure-limit
    drivers.

    Reason codes remain simulated strategy explanation codes.

***************************************************************************************************/


/* 14.12A Decline summary. */
SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_rows,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_synthetic_estimated_pd_proxy_declines,

    AVG(debt_to_income_ratio) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_debt_to_income_ratio_declines,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_requested_payment_to_income_ratio_declines,

    AVG(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_requested_expected_loss_amount_declines
FROM credit_decisioning_sim.strategy_decisions;


/* 14.12B Declines by decision path. */
SELECT
    decision_path,
    COUNT(*) AS decline_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'DECLINE'
GROUP BY decision_path
ORDER BY decision_path;


/* 14.12C Declines by primary reason code. */
SELECT
    primary_reason_code,
    COUNT(*) AS decline_rows,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_decline_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'DECLINE'
GROUP BY primary_reason_code
ORDER BY primary_reason_code;


/* 14.12D Hard simulated policy stop flags among declines. */
SELECT
    hard_policy_stop_flag,
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag,
    COUNT(*) AS decline_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'DECLINE'
GROUP BY
    hard_policy_stop_flag,
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag
ORDER BY
    hard_policy_stop_flag,
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag;


/* 14.12E Decline zero-exposure convention check. */
SELECT
    COUNT(*) AS decline_exposure_convention_violation_rows
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'DECLINE'
  AND (
        approved_amount IS DISTINCT FROM 0::NUMERIC
     OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
     OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
  );



/***************************************************************************************************
SECTION 14.13 — REASON-CODE COVERAGE AND ALIGNMENT
****************************************************************************************************

Purpose:
    Validate reason-code completeness and family alignment.

Expected interpretation:
    APPROVE rows should use APPROVAL family.
    COUNTEROFFER rows should use COUNTEROFFER family.
    MANUAL_REVIEW rows should use MANUAL_REVIEW family.
    DECLINE rows should use POLICY_STOP family.

***************************************************************************************************/


/* 14.13A Reason-code completeness and prohibited-boundary-term diagnostics. */
SELECT
    COUNT(*) FILTER (WHERE primary_reason_code IS NULL) AS null_primary_reason_code_rows,
    COUNT(*) FILTER (WHERE primary_reason_family IS NULL) AS null_primary_reason_family_rows,
    COUNT(*) FILTER (WHERE triggered_reason_code_list IS NULL) AS null_triggered_reason_code_list_rows,
    COUNT(*) FILTER (WHERE reason_code_count IS NULL OR reason_code_count < 1) AS invalid_reason_code_count_rows,

    COUNT(*) FILTER (
        WHERE UPPER(COALESCE(primary_reason_code, '')) LIKE '%ADVERSE_ACTION%'
           OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%ADVERSE_ACTION%'
           OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%ADVERSE_ACTION%'
           OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%ADVERSE_ACTION%'
           OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%REGULATORY%'
           OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%REGULATORY%'
           OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%REGULATORY%'
           OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%REGULATORY%'
           OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%CUSTOMER_NOTICE%'
           OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%CUSTOMER_NOTICE%'
           OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%CUSTOMER_NOTICE%'
           OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%CUSTOMER_NOTICE%'
           OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%FAIR_LENDING%'
           OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%FAIR_LENDING%'
           OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%FAIR_LENDING%'
           OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%FAIR_LENDING%'
    ) AS prohibited_boundary_term_rows
FROM credit_decisioning_sim.strategy_decisions;


/* 14.13B Decision outcome × primary reason family. */
SELECT
    decision_outcome,
    primary_reason_family,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    decision_outcome,
    primary_reason_family
ORDER BY
    decision_outcome,
    primary_reason_family;


/* 14.13C Decision outcome × primary reason code. */
SELECT
    decision_outcome,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY decision_outcome), 0),
        2
    ) AS pct_within_decision_outcome
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    decision_outcome,
    primary_reason_code
ORDER BY
    decision_outcome,
    primary_reason_code;


/* 14.13D Primary reason-code distribution. */
SELECT
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_population
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    primary_reason_family,
    primary_reason_code
ORDER BY
    primary_reason_family,
    primary_reason_code;


/* 14.13E Average reason_code_count by decision_outcome. */
SELECT
    decision_outcome,
    AVG(reason_code_count) AS avg_reason_code_count,
    MIN(reason_code_count) AS min_reason_code_count,
    MAX(reason_code_count) AS max_reason_code_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/* 14.13F Reason family leakage diagnostic. */
SELECT
    COUNT(*) AS reason_family_leakage_rows
FROM credit_decisioning_sim.strategy_decisions
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



/***************************************************************************************************
SECTION 14.14 — SIMULATED OFFER-EXPOSURE PROFILE
****************************************************************************************************

Purpose:
    Summarize rows where simulated_offer_exposure_flag = TRUE.

Terminology:
    Use simulated offer exposure, not account-opening or funding terminology.

***************************************************************************************************/


/* 14.14A Overall simulated offer-exposure profile. */
SELECT
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
        AS approval_share_of_offers,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
        AS counteroffer_share_of_offers,

    SUM(COALESCE(approved_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_amount_offer_rows,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    SUM(COALESCE(approved_expected_loss_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_expected_loss_offer_rows,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
FROM credit_decisioning_sim.strategy_decisions;


/* 14.14B Product × simulated offer-exposure profile. */
SELECT
    product_type_policy_key,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_all_apps,
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY product_type_policy_key
ORDER BY product_type_policy_key;


/* 14.14C Score band × simulated offer-exposure profile. */
SELECT
    score_band_policy_key,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY score_band_policy_key
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.15 — EDGE-CASE AND MIXED-SIGNAL REVIEW
****************************************************************************************************

Purpose:
    Validate that realistic edge cases remain visible and explainable.

Expected interpretation:
    Edge cases should exist but be traceable through staged logic.
    Realistic overlap should not be treated as a defect unless it dominates or violates output
    conventions.

***************************************************************************************************/


/* 14.15A Strong credit / high requested PTI sample. */
SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    credit_score,
    requested_amount,
    requested_payment_to_income_ratio,
    approved_payment_to_income_ratio,
    estimated_pd AS synthetic_estimated_pd_proxy,
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


/* 14.15B Weak credit / low requested PTI sample. */
SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    credit_score,
    requested_amount,
    requested_payment_to_income_ratio,
    estimated_pd AS synthetic_estimated_pd_proxy,
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


/* 14.15C Large exposure / low synthetic risk sample. */
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
    decision_outcome,
    primary_reason_code
FROM credit_decisioning_sim.strategy_decisions
WHERE mixed_signal_profile_type IN ('LARGE_EXPOSURE_LOW_RISK', 'MULTIPLE_MIXED_SIGNALS')
ORDER BY
    requested_amount DESC,
    application_id
LIMIT 25;


/* 14.15D High synthetic risk / low exposure sample. */
SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    requested_amount,
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


/* 14.15E High DTI / low requested PTI sample. */
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
    primary_reason_code
FROM credit_decisioning_sim.strategy_decisions
WHERE mixed_signal_profile_type IN ('HIGH_DTI_LOW_REQUESTED_PTI', 'MULTIPLE_MIXED_SIGNALS')
ORDER BY
    debt_to_income_ratio DESC,
    requested_payment_to_income_ratio ASC,
    application_id
LIMIT 25;


/* 14.15F Multiple mixed-signal profiles. */
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
    decision_outcome,
    primary_reason_code
FROM credit_decisioning_sim.strategy_decisions
WHERE mixed_signal_profile_type = 'MULTIPLE_MIXED_SIGNALS'
ORDER BY
    mixed_signal_condition_count DESC,
    total_rule_trigger_count DESC,
    application_id
LIMIT 25;


/* 14.15G Borderline profiles. */
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
    primary_reason_code
FROM credit_decisioning_sim.strategy_decisions
WHERE borderline_profile_flag IS TRUE
ORDER BY
    total_rule_trigger_count DESC,
    application_id
LIMIT 25;


/* 14.15H Counteroffer cases with large exposure reductions. */
SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    requested_amount,
    approved_amount,
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
    exposure_reduction_pct DESC,
    exposure_reduction_amount DESC,
    application_id
LIMIT 25;


/* 14.15I Manual review residual fallback cases. */
SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    primary_reason_code,
    total_rule_trigger_count,
    mixed_signal_profile_type,
    borderline_profile_flag
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'MANUAL_REVIEW'
  AND decision_path IN (
        'RESIDUAL_STRATEGY_REVIEW',
        'FINAL_RESIDUAL_STRATEGY_REVIEW'
  )
ORDER BY
    total_rule_trigger_count DESC,
    application_id
LIMIT 25;


/* 14.15J Decline residual fallback cases, if any. */
SELECT
    application_id,
    applicant_id,
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    primary_reason_code,
    total_rule_trigger_count,
    hard_policy_stop_flag,
    synthetic_risk_decline_trigger_flag,
    dti_decline_trigger_flag
FROM credit_decisioning_sim.strategy_decisions
WHERE decision_outcome = 'DECLINE'
  AND primary_reason_code = 'POLICY_STOP_RESIDUAL_DECLINE'
ORDER BY
    total_rule_trigger_count DESC,
    application_id
LIMIT 25;



/***************************************************************************************************
SECTION 14.16 — FINAL OUTPUT CONVENTION VALIDATION
****************************************************************************************************

Purpose:
    Confirm final output conventions hold in the latest-run table.

This query returns diagnostic failure counts suitable for validation evidence.

Expected result:
    all violation counts should be zero.

***************************************************************************************************/

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
             OR approved_amount >= requested_amount
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
          AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
    ) AS approve_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount > requested_expected_loss_amount
          )
    ) AS counteroffer_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_expected_loss_amount IS NOT NULL
    ) AS manual_review_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_expected_loss_violation_rows
FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.17 — ARCHIVE AND COMPARISON READINESS RECAP
****************************************************************************************************

Purpose:
    Summarize whether the latest run is archived and whether Section 13 comparison is available.

This recap does not replace Section 13. It gives Section 14 users a latest-run readiness snapshot.

***************************************************************************************************/

WITH latest_context AS (
    SELECT
        archive_run_flag,
        strategy_archive_reset_mode,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS latest_run_row_count,
        COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        archive_run_flag,
        strategy_archive_reset_mode,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),
current_archived_slice AS (
    SELECT
        lc.strategy_set_name,
        lc.strategy_name,
        lc.strategy_version,
        lc.module1_scenario_set_name,
        lc.module1_scenario_name,
        lc.population_id,

        COUNT(ar.*) AS current_archived_slice_row_count,
        COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count,
        MIN(ar.archive_inserted_ts) AS min_archive_inserted_ts,
        MAX(ar.archive_inserted_ts) AS max_archive_inserted_ts
    FROM latest_context lc
    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
        ON ar.strategy_set_name = lc.strategy_set_name
       AND ar.strategy_name = lc.strategy_name
       AND ar.strategy_version = lc.strategy_version
       AND ar.module1_scenario_set_name = lc.module1_scenario_set_name
       AND ar.module1_scenario_name = lc.module1_scenario_name
       AND ar.population_id = lc.population_id
    GROUP BY
        lc.strategy_set_name,
        lc.strategy_name,
        lc.strategy_version,
        lc.module1_scenario_set_name,
        lc.module1_scenario_name,
        lc.population_id
),
comparison_inventory AS (
    SELECT
        lc.strategy_set_name,
        lc.module1_scenario_set_name,
        lc.module1_scenario_name,
        lc.population_id,

        COUNT(DISTINCT (
            ar.strategy_set_name,
            ar.strategy_name,
            ar.strategy_version
        )) AS archived_strategy_slice_count_for_same_set_scenario_population
    FROM latest_context lc
    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
        ON ar.strategy_set_name = lc.strategy_set_name
       AND ar.module1_scenario_set_name = lc.module1_scenario_set_name
       AND ar.module1_scenario_name = lc.module1_scenario_name
       AND ar.population_id = lc.population_id
    GROUP BY
        lc.strategy_set_name,
        lc.module1_scenario_set_name,
        lc.module1_scenario_name,
        lc.population_id
)
SELECT
    lc.archive_run_flag,
    lc.strategy_archive_reset_mode,

    lc.strategy_set_name,
    lc.strategy_name,
    lc.strategy_version,

    lc.module1_scenario_set_name,
    lc.module1_scenario_name,
    lc.population_id,

    lc.latest_run_row_count,
    lc.latest_run_distinct_application_id_count,

    cas.current_archived_slice_row_count,
    cas.current_archived_slice_distinct_application_id_count,
    cas.min_archive_inserted_ts,
    cas.max_archive_inserted_ts,

    ci.archived_strategy_slice_count_for_same_set_scenario_population,

    (
        ci.archived_strategy_slice_count_for_same_set_scenario_population >= 2
    ) AS at_least_two_strategy_slices_available_for_matched_comparison,

    CASE
        WHEN lc.archive_run_flag IS FALSE
            THEN 'LATEST_RUN_NOT_MARKED_FOR_ARCHIVE'

        WHEN cas.current_archived_slice_row_count = lc.latest_run_row_count
         AND cas.current_archived_slice_distinct_application_id_count = lc.latest_run_distinct_application_id_count
         AND ci.archived_strategy_slice_count_for_same_set_scenario_population >= 2
            THEN 'ARCHIVED_AND_COMPARISON_CANDIDATES_AVAILABLE'

        WHEN cas.current_archived_slice_row_count = lc.latest_run_row_count
         AND cas.current_archived_slice_distinct_application_id_count = lc.latest_run_distinct_application_id_count
            THEN 'ARCHIVED_CURRENT_SLICE_ONLY'

        ELSE 'ARCHIVE_READINESS_REVIEW_REQUIRED'
    END AS archive_and_comparison_readiness_status
FROM latest_context lc
LEFT JOIN current_archived_slice cas
    ON cas.strategy_set_name = lc.strategy_set_name
   AND cas.strategy_name = lc.strategy_name
   AND cas.strategy_version = lc.strategy_version
   AND cas.module1_scenario_set_name = lc.module1_scenario_set_name
   AND cas.module1_scenario_name = lc.module1_scenario_name
   AND cas.population_id = lc.population_id
LEFT JOIN comparison_inventory ci
    ON ci.strategy_set_name = lc.strategy_set_name
   AND ci.module1_scenario_set_name = lc.module1_scenario_set_name
   AND ci.module1_scenario_name = lc.module1_scenario_name
   AND ci.population_id = lc.population_id;



/***************************************************************************************************
END OF SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS

If execution reaches this point:
    1. Latest-run structural integrity can be reviewed.
    2. Final decision distribution can be reviewed.
    3. Product, score, product × score, risk-tier, requested PTI, and DTI behavior can be reviewed.
    4. Requested versus approved exposure and economics can be reviewed.
    5. Counteroffer behavior can be validated.
    6. Manual-review unresolved behavior can be validated.
    7. Decline / policy-stop behavior can be validated.
    8. Simulated reason-code coverage and family alignment can be validated.
    9. Simulated offer-exposure profile can be reviewed.
    10. Edge cases and mixed-signal profiles can be inspected.
    11. Final output conventions can be tested through diagnostic failure counts.
    12. Archive and comparison readiness can be reviewed.

No latest-run output rows have been modified.
No archive rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been reassigned.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

---

# 3. What Section 14 establishes

Section 14 establishes the read-only QA and validation evidence framework for the completed Module 2 latest-run output. It validates structure, final outcomes, product behavior, score-band behavior, synthetic estimated-risk ordering, affordability sensitivity, DTI behavior, counteroffer feasibility, manual-review unresolved treatment, decline / policy-stop behavior, reason-code coverage, simulated offer exposure, edge cases, output conventions, and archive readiness.

---

# 4. What Section 14 intentionally does not build

Section 14 does not modify data, create new strategy outcomes, recalculate approved exposure, recalculate approved Expected Loss, reassign simulated reason codes, insert archive rows, build dashboards, or draft the BRD / Validation Summary.

It is the SQL evidence layer, not the written validation artifact.

---

# 5. Recommended next step after Section 14

Next should be a **full-script assembly and execution pass**:

```text
Sections 0–14 integrated run
```

That pass should confirm all dependencies, object names, parameter columns, staged-table columns, final output columns, archive behavior, and QA queries execute end-to-end before drafting the Module 2 BRD or Validation Summary.
<!-- END_MESSAGE C038-M00174 -->


---

<a id="c038-m00176"></a>

### C038-M00176

**Andrew** · 2026-05-06T16:55:35.594000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00176 -->
*No text body is present in the export. This message may contain an image or attachment.*
<!-- END_MESSAGE C038-M00176 -->


**Attachments in export:** `Pasted text(101).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

**Recovered attached instruction:** [Read the complete supplied text](../../Attachments/C038-M00176_Pasted_text_101.txt).

This is strong. I agree with the Section 13 refinements and the Section 14 Module 2 Validation, QA, and Strategy Outcome Diagnostics layer.

Section 14 should be treated as accepted after the two targeted final patches below are incorporated.

Section 14 correctly:
- remains read-only
- validates the completed latest-run Module 2 output
- preserves Module 1 estimated_pd as the synthetic estimated-PD proxy
- preserves requested_expected_loss_amount as requested-exposure Expected Loss
- validates decision distribution
- validates product, score-band, product × score-band, risk-tier, PTI, DTI, exposure, counteroffer, manual review, decline, reason-code, simulated-offer exposure, and edge-case behavior
- includes archive and comparison readiness diagnostics
- avoids modifying strategy parameters
- avoids modifying product policy parameters
- avoids recalculating decisions
- avoids recalculating reason codes
- avoids recalculating approved exposure
- avoids recalculating approved Expected Loss
- avoids modifying latest-run or archive rows
- avoids drafting the BRD or Validation Summary

Do not rewrite Sections 0–14 in design form again.

We are now moving from incremental section design into full canonical SQL capture.

================================================================================
1. FINAL TARGETED PATCH — SECTION 13 MATCHED SOURCE-FIELD CONSISTENCY DIAGNOSTIC
================================================================================

Please add a targeted Section 13 diagnostic to confirm that matched baseline and challenger strategy slices share the same immutable Module 1 source fields.

Reason:
Matched strategy comparison should isolate Module 2 strategy effects.

If Module 1 source fields differ between baseline and challenger rows, the comparison may reflect population drift, source-selection error, or upstream scenario mismatch rather than true downstream strategy movement.

This diagnostic should be read-only.

For matched baseline and challenger rows, compare at least:

- product_type_policy_key
- score_band_policy_key
- credit_score
- annual_income
- requested_amount
- requested_monthly_payment_proxy
- requested_payment_to_income_ratio
- amount_to_income_ratio
- estimated_pd
- estimated_lgd
- requested_expected_loss_amount
- module1_scenario_set_name
- module1_scenario_name
- population_id

Use IS DISTINCT FROM so NULL handling remains explicit and safe.

The diagnostic query should report:

- matched_application_count
- source_field_mismatch_count
- product_type_mismatch_count
- score_band_mismatch_count
- credit_score_mismatch_count
- annual_income_mismatch_count
- requested_amount_mismatch_count
- requested_payment_mismatch_count
- requested_pti_mismatch_count
- estimated_pd_mismatch_count
- estimated_lgd_mismatch_count
- requested_expected_loss_mismatch_count
- source_consistency_status

Suggested source_consistency_status values:

- SOURCE_FIELDS_MATCH
- SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED
- NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON

This should not mutate archive rows.
This should not recalculate any decisions.
This should not recalculate reason codes.
This should not recalculate approved exposure.
This should not recalculate Expected Loss.
This should not fail execution solely because placeholder comparison parameters are not ready.

================================================================================
2. FINAL TARGETED PATCH — SECTION 14 VALIDATION STATUS SUMMARY
================================================================================

Please add a compact validation status summary table or CTE near the end of Section 14.

Recommended name:

tmp_m2_validation_status_summary

Suggested fields:

- validation_area
- validation_test_name
- validation_category
- validation_status
- observed_value
- expected_behavior
- interpretation

Suggested validation_status values:

- PASS
- REVIEW
- NOT_APPLICABLE

Use PASS for structural or diagnostic expectations that are satisfied.

Use REVIEW for diagnostic patterns that may be acceptable but should be interpreted, such as:
- high manual review rate
- high counteroffer concentration
- high reason-code concentration
- unusual product-level decision skew
- comparison not ready
- source-field mismatch review required
- unusual but explainable mixed-signal concentration

Use NOT_APPLICABLE where the test depends on unavailable archive slices, unavailable comparison parameters, or non-ready matched comparison setup.

Do not use FAIL for ordinary diagnostic strategy patterns.

Critical structural failures should already be handled by fail-fast gatekeepers.

The validation summary should include at least these validation areas:

1. Latest-run structural integrity
2. Decision outcome completeness
3. Final flag reconciliation
4. Simulated offer-exposure convention
5. Approved amount convention
6. Approved Expected Loss convention
7. Reason-code completeness
8. Reason-code family alignment
9. Prohibited terminology check
10. Product-level strategy distribution
11. Score-band strategy distribution
12. Synthetic risk ordering
13. Affordability sensitivity
14. Counteroffer diagnostics
15. Manual-review diagnostics
16. Decline / policy-stop diagnostics
17. Mixed-signal and edge-case diagnostics
18. Archive persistence readiness
19. Matched strategy comparison readiness
20. Matched source-field consistency

This table / CTE should be read-only or temporary only.
It should not modify latest-run output.
It should not modify archive output.
It should not change thresholds or strategy parameters.

================================================================================
3. SECTION 14 FINAL ACCEPTANCE CRITERIA
================================================================================

After the targeted Section 13 and Section 14 patches are incorporated, treat Section 14 as accepted if:

- Section 14 remains read-only
- latest-run structural integrity is validated
- decision outcomes are summarized
- product-level outcomes are summarized
- score-band outcomes are summarized
- product × score outcomes are summarized
- synthetic estimated-risk ordering is reviewed
- affordability sensitivity is reviewed
- approved exposure and Expected Loss behavior is reviewed
- counteroffer behavior is reviewed
- manual review behavior is reviewed
- decline / policy-stop behavior is reviewed
- reason-code coverage and concentration are reviewed
- simulated-offer exposure profile is reviewed
- mixed-signal and edge-case examples are available
- archive readiness is reviewed
- matched strategy comparison readiness is reviewed
- matched source-field consistency is reviewed
- tmp_m2_validation_status_summary is created or clearly produced as a final Section 14 validation summary output
- no strategy parameters are modified
- no product policy parameters are modified
- no latest-run rows are modified
- no archive rows are modified
- no decisions, reason codes, approved exposure, or Expected Loss values are recalculated
- no production-decision language appears
- no booked-account language appears
- no adverse-action reason-code language appears

================================================================================
4. NEXT STEP — FULL CANONICAL SQL CODE CAPTURE
================================================================================

After applying the two targeted patches above, we need to capture the full canonical Module 2 SQL script.

This is now the highest-priority next step.

I have not copied the earlier code out of the chat yet, so please do not assume I can reconstruct it from prior snippets.

Please enter FULL CODE CAPTURE MODE.

The goal is to produce the final integrated SQL script exactly as it should be saved as:

module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql

================================================================================
5. FULL CODE CAPTURE RULES
================================================================================

Please follow these rules exactly:

1. Produce the full integrated SQL script from Section 0 through Section 14.

2. Include every accepted section and every accepted patch.

3. Preserve the valuable commentary and teaching notes from all prior section builds.

4. Do not summarize code.

5. Do not omit any section.

6. Do not use placeholders such as:
   - same as above
   - insert prior code here
   - previously defined
   - unchanged
   - omitted for brevity
   - etc.

7. Do not use ellipses.

8. Do not remove governance comments.

9. Do not remove boundary language.

10. Do not simplify the SQL unless required for internal consistency.

11. If you discover a naming inconsistency while assembling, do not silently change logic.

    Instead:
    - call it out as an “Assembly Reconciliation Note”
    - explain the exact issue
    - state the correction
    - provide the corrected integrated version in the code

12. Do not introduce new design logic during full code capture unless required to reconcile accepted sections.

13. Do not add new modeling workstreams.

14. Do not draft the BRD or Validation Summary yet.

15. Do not convert this into documentation prose. This is SQL code capture.

================================================================================
6. REQUIRED FINAL SCRIPT SECTION LIST
================================================================================

The final integrated code must include all sections:

- Section 0 — Executive Purpose, Module 2 Boundaries, and SQL Section Map
- Section 1 — Schema Setup / Clean Rerun Reset
- Section 2 — Strategy Parameter Framework and Product Policy Parameter Framework
- Section 3 — Fail-Fast Strategy Parameter Gatekeeper
- Section 4 — Module 1 Source Selection and Lineage Normalization
- Section 5 — Derived Strategy Segmentation Layer
- Section 6 — Rule Flag Construction Layer
- Section 7 — Preliminary Decision Routing Layer
- Section 8 — Approved Exposure and Counteroffer Feasibility Layer
- Section 9 — Final Decision Resolution Layer
- Section 10 — Simulated Reason-Code Assignment Layer
- Section 11 — Latest-Run Strategy Decision Output Table
- Section 12 — Strategy Decision Archive Persistence Layer
- Section 13 — Archive Inventory and Matched Strategy Comparison Framework
- Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics

================================================================================
7. CANONICAL OBJECT / STAGE NAME CHECK
================================================================================

Before beginning code capture, internally verify that the final script consistently uses these canonical object names.

Do not create alternate names.

Core permanent tables:
- credit_decisioning_sim.strategy_decisions
- credit_decisioning_sim.strategy_decisions_archive

Parameter tables:
- tmp_module2_strategy_params
- tmp_module2_product_policy_params
- tmp_m2_strategy_comparison_params

Stage tables:
- tmp_m2_stage_1_source_applications
- tmp_m2_stage_2_strategy_segments
- tmp_m2_stage_3_rule_flags
- tmp_m2_stage_4_preliminary_decision_routing
- tmp_m2_stage_5_exposure_treatment
- tmp_m2_stage_6_final_decision_resolution
- tmp_m2_stage_7_reason_code_assignment

Validation summary object:
- tmp_m2_validation_status_summary

If any earlier section used a different name, reconcile it during code assembly and call it out as an Assembly Reconciliation Note.

================================================================================
8. CANONICAL TERMINOLOGY CHECK
================================================================================

During code assembly, preserve these interpretation boundaries:

- estimated_pd remains the SQL field name, but commentary must describe it as the synthetic estimated-PD proxy.
- requested_expected_loss_amount means requested-exposure Expected Loss from Module 1.
- approved_expected_loss_amount means approved-exposure Expected Loss from Module 2.
- simulated_offer_exposure_flag means simulated positive offer exposure.
- simulated_offer_exposure_flag does not mean booked exposure, funded exposure, production approval, or real customer treatment.
- reason codes are simulated strategy explanation codes.
- reason codes are not adverse-action reasons, regulatory notices, customer communications, or fair-lending conclusions.

Avoid:
- booked exposure
- booked account
- approved book
- adverse action
- regulatory reason
- customer notice
- production decision
- calibrated PD
- recalibrated risk

================================================================================
9. CHUNKING PROTOCOL TO AVOID LOSING CODE
================================================================================

Because the full script is long, do not try to force the entire file into one response if it risks truncation.

Use this exact chunking approach:

PART 1:
- Section 0
- Section 1
- Section 2
- Section 3

PART 2:
- Section 4

PART 3:
- Section 5
- Section 6

PART 4:
- Section 7
- Section 8

PART 5:
- Section 9
- Section 10

PART 6:
- Section 11
- Section 12

PART 7:
- Section 13
- Section 14

Each part must begin with:

-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART X OF 7 START

Each part must end with:

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART X OF 7 END

At the end of each part, also write:

Ready for next part: say CONTINUE FULL CODE PART X+1

Do not skip ahead.

Do not include non-SQL prose inside the SQL code block except SQL comments.

Do not include Parts 2–7 until I ask for them.

================================================================================
10. START CODE CAPTURE NOW
================================================================================

Please now provide:

1. A brief Assembly Reconciliation Note, only if needed.

2. Confirmation that the two final patches have been integrated into the canonical capture plan:
   - Section 13 matched source-field consistency diagnostic
   - Section 14 validation status summary

3. Then begin FULL CODE CAPTURE PART 1 OF 7 only.

PART 1 should include:
- Section 0
- Section 1
- Section 2
- Section 3

Do not provide Parts 2–7 until I ask for them.

Do not draft the Module 2 BRD or Validation Summary yet.


---

<a id="c038-m00178"></a>

### C038-M00178

**ChatGPT** · 2026-05-06T17:00:55.796962-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00178 -->
No Assembly Reconciliation Note is needed.

The two final patches are integrated into the canonical capture plan:
Section 13 will include the matched Module 1 source-field consistency diagnostic, and Section 14 will include `tmp_m2_validation_status_summary`.

Module 2’s SQL capture continues to preserve Module 1’s authoritative boundary: the synthetic estimated-PD proxy interpretation of `estimated_pd`, the distinction between requested-exposure and approved-exposure Expected Loss, deterministic lineage, and the synthetic strategy-simulation boundary documented and validated in Module 1. fileciteturn4file1 fileciteturn4file2

```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 1 OF 7 START

/***************************************************************************************************
MODULE 2 — CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE V1.0
Enterprise Credit Decisioning Strategy Simulator

Canonical SQL File:
    module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql

PostgreSQL Implementation

****************************************************************************************************/



/***************************************************************************************************
SECTION 0 — EXECUTIVE PURPOSE, MODULE 2 BOUNDARIES, AND SQL SECTION MAP
****************************************************************************************************

PROJECT CONTEXT:
    Enterprise Credit Decisioning Strategy Simulator

COMPLETED UPSTREAM MODULE:
    Module 1 — Synthetic Application & Risk Modeling Engine V2.0

CURRENT MODULE:
    Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine V1.0

EXECUTIVE PURPOSE:
    Module 2 consumes finalized Module 1 synthetic application and risk outputs and applies a
    governed simulated credit policy strategy layer.

    Module 2 answers:

        "Under this simulated strategy, what strategy outcome would this synthetic applicant
         receive, and why?"

    It does not answer:

        "What real customer decision should be made?"

CORE DESIGN THESIS:
    Simulated credit strategy outcomes should not be determined by one variable alone.

    Module 2 outcomes emerge from the interaction of:
        product type,
        requested amount,
        approved exposure treatment,
        score band,
        borrower risk signals,
        affordability stress,
        estimated_pd as the synthetic estimated-PD proxy,
        LGD,
        requested-exposure Expected Loss,
        product-specific strategy rules,
        global strategy configuration,
        and upstream Module 1 scenario lineage.

MODULE 1 RELATIONSHIP:
    Module 2 consumes Module 1 outputs.

    Module 2 does not redesign Module 1.
    Module 2 does not rewrite Module 1.
    Module 2 does not reinterpret Module 1 scenario outputs as forecasts.

    Module 1 scenario fields describe the upstream synthetic population and risk environment.
    Module 2 strategy fields describe the downstream simulated strategy applied to that population.

CANONICAL MODULE 1 LINEAGE FIELDS USED BY MODULE 2:
    module1_scenario_set_name
    module1_scenario_name
    population_id

CANONICAL MODULE 2 STRATEGY FIELDS:
    strategy_set_name
    strategy_name
    strategy_version
    strategy_run_id
    strategy_run_ts

ESTIMATED_PD TERMINOLOGY BOUNDARY:
    The SQL field name estimated_pd is retained because it is the finalized Module 1 output column.

    In all commentary, documentation, QA interpretation, and strategy analysis, estimated_pd should
    be interpreted as the synthetic estimated-PD proxy.

    Module 2 V1.0 does not recalculate estimated_pd.
    Module 2 V1.0 does not create a new post-decision risk model.
    Module 2 V1.0 does not treat estimated_pd as a calibrated production probability of default.

EXPECTED LOSS TERMINOLOGY BOUNDARY:
    Module 1 expected_loss_amount is treated as requested-exposure Expected Loss.

    In Module 2 outputs, this value is carried as:
        requested_expected_loss_amount

    Module 2 also calculates approved-exposure Expected Loss after exposure treatment:
        approved_expected_loss_amount

    Conceptual formula:
        approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd

    estimated_pd remains the synthetic estimated-PD proxy input.

SIMULATED STRATEGY OUTCOME BOUNDARY:
    Module 2 may use terms such as:
        APPROVE,
        COUNTEROFFER,
        MANUAL_REVIEW,
        DECLINE,
        approved_amount,
        counteroffer_amount,
        reason code.

    These are simulated strategy outcomes for synthetic applicants.

    They are not:
        production underwriting decisions,
        real customer approvals or declines,
        real customer treatments,
        compliance-approved reason codes,
        regulatory customer notices,
        fair lending conclusions,
        pricing optimization outputs,
        calibrated default forecasts,
        account creation events,
        funded exposure,
        or operational servicing instructions.

REASON-CODE BOUNDARY:
    Module 2 reason codes are simulated strategy explanation codes.

    They support:
        strategy transparency,
        QA review,
        segmentation analysis,
        decision-path traceability,
        portfolio interpretation.

    They are not regulatory or customer communication reason codes.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag indicates that the simulated strategy output includes positive
    offer exposure for a synthetic applicant.

    It is TRUE for:
        APPROVE
        COUNTEROFFER

    It is FALSE for:
        MANUAL_REVIEW
        DECLINE

    It does not imply operational account creation, funding, production approval, or real customer
    treatment.

CANONICAL FINAL DECISION TAXONOMY:
    APPROVE
    COUNTEROFFER
    MANUAL_REVIEW
    DECLINE

COUNTEROFFER DESIGN DECISION:
    COUNTEROFFER is a distinct final decision_outcome.

    More detailed counteroffer type is captured in decision_path and reason-code diagnostics.

MANUAL REVIEW DESIGN DECISION:
    MANUAL_REVIEW is unresolved by design.

    Manual-review rows receive:
        approved_amount = NULL
        approved_monthly_payment_proxy = NULL
        approved_payment_to_income_ratio = NULL
        approved_expected_loss_amount = NULL

PHYSICAL ARCHITECTURE:
    Latest-run output table:
        credit_decisioning_sim.strategy_decisions

    Strategy archive table:
        credit_decisioning_sim.strategy_decisions_archive

ARCHIVE GRAIN:
    One row per:
        application_id
        × Module 1 scenario
        × Module 2 strategy version

    Row-level archive grain fields:
        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

ARCHIVE REPLACEMENT / RERUN KEY:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

    application_id is intentionally excluded from the replacement key because it identifies rows
    within the replacement slice.

AUDIT METADATA BOUNDARY:
    strategy_run_id and strategy_run_ts support run traceability.

    They do not replace the archive replacement / rerun key.
    They should not be used as matched strategy comparison grain.

SQL SECTION MAP:
    Section 0  — Executive Purpose, Module 2 Boundaries, and SQL Section Map
    Section 1  — Schema Setup / Clean Rerun Reset
    Section 2  — Strategy Parameter Framework and Product Policy Parameter Framework
    Section 3  — Fail-Fast Strategy Parameter Gatekeeper
    Section 4  — Module 1 Source Selection and Lineage Normalization
    Section 5  — Derived Strategy Segmentation Layer
    Section 6  — Rule Flag Construction Layer
    Section 7  — Preliminary Decision Routing Layer
    Section 8  — Approved Exposure and Counteroffer Feasibility Layer
    Section 9  — Final Decision Resolution Layer
    Section 10 — Simulated Reason-Code Assignment Layer
    Section 11 — Latest-Run Strategy Decision Output Table
    Section 12 — Strategy Decision Archive Persistence Layer
    Section 13 — Archive Inventory and Matched Strategy Comparison Framework
    Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics

***************************************************************************************************/



/***************************************************************************************************
SECTION 1 — SCHEMA SETUP / CLEAN RERUN RESET
****************************************************************************************************

BUSINESS PURPOSE:
    Establish the dedicated simulation schema and reset transient Module 2 execution objects so the
    current run starts cleanly.

SQL PURPOSE:
    1. Create the simulation schema if it does not already exist.
    2. Set the search path for review convenience.
    3. Drop temporary Module 2 parameter and staging objects from prior executions.
    4. Drop the latest-run strategy output table for clean rerun behavior.
    5. Do not drop the strategy archive table.

WHY THE LATEST-RUN TABLE MAY BE DROPPED:
    credit_decisioning_sim.strategy_decisions represents the current completed Module 2 run only.

    It is replaced each run so latest-run QA and reporting are not silently mixed with prior
    strategy outputs.

WHY THE ARCHIVE TABLE IS NOT DROPPED HERE:
    credit_decisioning_sim.strategy_decisions_archive is the governed history layer.

    Archive persistence and archive reset behavior are controlled later by Section 12 using:
        archive_run_flag
        strategy_archive_reset_mode

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
1.1 Create / reuse dedicated simulation schema.
-----------------------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;


/*-----------------------------------------------------------------------------------------------
1.2 Clean reset of temporary Module 2 objects.

Temporary objects are safe to drop on rerun because they are execution staging artifacts.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_module2_strategy_params;
DROP TABLE IF EXISTS tmp_module2_product_policy_params;

DROP TABLE IF EXISTS tmp_m2_stage_1_source_applications;
DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;
DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;
DROP TABLE IF EXISTS tmp_m2_stage_4_preliminary_decision_routing;
DROP TABLE IF EXISTS tmp_m2_stage_5_exposure_treatment;
DROP TABLE IF EXISTS tmp_m2_stage_6_final_decision_resolution;
DROP TABLE IF EXISTS tmp_m2_stage_7_reason_code_assignment;

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;


/*-----------------------------------------------------------------------------------------------
1.3 Clean reset of latest-run output table.

This intentionally does not drop:
    credit_decisioning_sim.strategy_decisions_archive
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 2 — STRATEGY PARAMETER FRAMEWORK AND PRODUCT POLICY PARAMETER FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize all Module 2 strategy assumptions, threshold settings, source-selection controls,
    archive controls, product policy limits, counteroffer settings, decision conventions, and rule
    controls.

SQL PURPOSE:
    1. Create tmp_module2_strategy_params with exactly one active strategy row.
    2. Create tmp_module2_product_policy_params with exactly one row per supported product.
    3. Store all strategy defaults as governed simulation parameters.
    4. Avoid hidden hardcoded thresholds in downstream decision logic.

PARAMETER GOVERNANCE PRINCIPLE:
    Downstream CASE logic should consume strategy and product parameters rather than silently
    embedding ungoverned thresholds.

DEFAULT THRESHOLD INTERPRETATION:
    Defaults in this section are initial synthetic strategy defaults.

    They are:
        intended for strategy simulation,
        expected to be reviewed through QA and strategy tuning,
        not production underwriting policy,
        not empirical calibration,
        not a calibrated default model,
        not regulatory policy,
        not real customer treatment logic.

***************************************************************************************************/



/***************************************************************************************************
SECTION 2.1 — STRATEGY PARAMETER TABLE
****************************************************************************************************/

CREATE TEMP TABLE tmp_module2_strategy_params (
    /***********************************************************************************************
    Active strategy cardinality
    ***********************************************************************************************/
    active_strategy_flag                         BOOLEAN,

    /***********************************************************************************************
    Strategy identity
    ***********************************************************************************************/
    module2_model_version                        TEXT,
    strategy_set_name                            TEXT,
    strategy_name                                TEXT,
    strategy_version                             TEXT,
    strategy_run_id                              TEXT,
    strategy_run_ts                              TIMESTAMP,

    /***********************************************************************************************
    Module 1 source selection
    ***********************************************************************************************/
    module1_input_source                         TEXT,
    source_module1_scenario_set_name             TEXT,
    source_module1_scenario_name                 TEXT,
    source_population_id                         TEXT,

    /***********************************************************************************************
    Archive controls
    ***********************************************************************************************/
    archive_run_flag                             BOOLEAN,
    strategy_archive_reset_mode                  TEXT,

    /***********************************************************************************************
    Global estimated-risk thresholds

    estimated_pd is the finalized Module 1 SQL field name.

    These thresholds interpret estimated_pd as the synthetic estimated-PD proxy.
    ***********************************************************************************************/
    approve_max_estimated_pd_proxy               NUMERIC(12,6),
    counteroffer_max_estimated_pd_proxy          NUMERIC(12,6),
    review_max_estimated_pd_proxy                NUMERIC(12,6),
    decline_min_estimated_pd_proxy               NUMERIC(12,6),

    /***********************************************************************************************
    Global PTI thresholds

    Product-specific PTI thresholds drive product PTI segmentation and rules.
    These global values provide high-level consistency controls and fallback context.
    ***********************************************************************************************/
    global_approve_max_pti                       NUMERIC(12,6),
    global_review_max_pti                        NUMERIC(12,6),
    global_decline_min_pti                       NUMERIC(12,6),

    /***********************************************************************************************
    DTI thresholds

    DTI is an existing-obligation capacity signal.
    In Module 2 V1.0, DTI is not directly corrected through counteroffer exposure reduction.
    ***********************************************************************************************/
    approve_max_dti                              NUMERIC(12,6),
    review_max_dti                               NUMERIC(12,6),
    decline_min_dti                              NUMERIC(12,6),

    /***********************************************************************************************
    Diagnostic segmentation controls
    ***********************************************************************************************/
    borderline_threshold_buffer_pct              NUMERIC(12,6),

    /*
    borderline_threshold_buffer_pct:
        Governs how close a value must be to a strategy threshold to be tagged as borderline.

        Example:
            0.050000 means "within 5% of the threshold value."

        This is not a production policy tolerance.
        This is a diagnostic segmentation buffer used only to identify threshold-adjacent
        synthetic profiles before decision rules are applied.
    */

    /***********************************************************************************************
    Rule-control parameters for Section 6 trigger construction
    ***********************************************************************************************/
    bankruptcy_policy_stop_enabled               BOOLEAN,
    major_derogatory_policy_stop_enabled         BOOLEAN,
    severe_delinquency_policy_stop_enabled       BOOLEAN,
    severe_delinquency_count_threshold           INTEGER,
    high_utilization_review_enabled              BOOLEAN,
    high_utilization_review_threshold            NUMERIC(12,6),
    low_score_review_enabled                     BOOLEAN,
    low_score_review_threshold                   INTEGER,

    /*
    Rule-control interpretation:
        These parameters control simulated trigger flags only.

        They do not assign final decision_outcome.
        They do not create reason codes.
        They do not represent production underwriting policy.

        Section 6 uses them to answer:
            "Which simulated policy conditions are triggered?"

        Later sections answer:
            "Which final simulated strategy outcome is assigned?"
    */

    /***********************************************************************************************
    Decision convention controls
    ***********************************************************************************************/
    approve_reason_code                          TEXT,
    reason_code_required_flag                    BOOLEAN,
    simulated_offer_exposure_flag_enabled        BOOLEAN,
    manual_review_approved_amount_convention     TEXT,
    decline_approved_amount_convention           TEXT,
    approved_el_decline_convention               TEXT,
    approved_el_manual_review_convention         TEXT,
    allow_approved_amount_above_requested_flag   BOOLEAN,

    /***********************************************************************************************
    Final decision-resolution control
    ***********************************************************************************************/
    failed_counteroffer_resolution               TEXT

    /*
    failed_counteroffer_resolution:
        Governs how preliminary COUNTEROFFER routes resolve when Section 8 determines that no
        viable reduced-exposure treatment exists.

    Allowed values:
        MANUAL_REVIEW
        DECLINE

    Default:
        MANUAL_REVIEW

    Interpretation:
        A failed counteroffer is routed to MANUAL_REVIEW by default because higher-priority hard
        simulated policy stops, severe synthetic estimated-risk, and severe DTI have already routed
        to DECLINE before counteroffer feasibility is evaluated.

    Boundary:
        This is a simulated strategy-control parameter, not production underwriting policy.
    */
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 2.2 — INSERT ACTIVE STRATEGY PARAMETER ROW
****************************************************************************************************

This default row is intentionally editable.

For a governed strategy test, users should update:
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_input_source,
    source Module 1 scenario fields when using ARCHIVE,
    strategy thresholds,
    product policy table values,
    archive controls.

****************************************************************************************************/

INSERT INTO tmp_module2_strategy_params (
    active_strategy_flag,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,

    archive_run_flag,
    strategy_archive_reset_mode,

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

    borderline_threshold_buffer_pct,

    bankruptcy_policy_stop_enabled,
    major_derogatory_policy_stop_enabled,
    severe_delinquency_policy_stop_enabled,
    severe_delinquency_count_threshold,
    high_utilization_review_enabled,
    high_utilization_review_threshold,
    low_score_review_enabled,
    low_score_review_threshold,

    approve_reason_code,
    reason_code_required_flag,
    simulated_offer_exposure_flag_enabled,
    manual_review_approved_amount_convention,
    decline_approved_amount_convention,
    approved_el_decline_convention,
    approved_el_manual_review_convention,
    allow_approved_amount_above_requested_flag,

    failed_counteroffer_resolution
)
VALUES (
    TRUE,

    'MODULE2_V1_0',
    'MODULE2_BASELINE_STRATEGY_SET',
    'BASELINE_STRATEGY',
    'V1_0',
    'MODULE2_BASELINE_STRATEGY_V1_0_RUN',
    CURRENT_TIMESTAMP,

    /*
    Module 1 source selection.

    LATEST:
        Consumes credit_decisioning_sim.synthetic_applications.

    ARCHIVE:
        Consumes a selected slice of credit_decisioning_sim.synthetic_applications_scenario_archive.
        When ARCHIVE is used, source_module1_scenario_set_name, source_module1_scenario_name, and
        source_population_id must be populated.
    */
    'LATEST',
    NULL,
    NULL,
    NULL,

    /*
    Archive controls.

    STRATEGY_SCENARIO_ONLY is the ordinary rerun mode:
        replace only the current strategy / Module 1 scenario / population slice.
    */
    TRUE,
    'STRATEGY_SCENARIO_ONLY',

    /*
    Global synthetic estimated-PD proxy thresholds.

    Equality convention:
        APPROVE eligibility:
            estimated_pd <= approve_max_estimated_pd_proxy

        COUNTEROFFER risk band:
            estimated_pd > approve_max_estimated_pd_proxy
            AND estimated_pd <= counteroffer_max_estimated_pd_proxy

        MANUAL_REVIEW risk band:
            estimated_pd > counteroffer_max_estimated_pd_proxy
            AND estimated_pd < decline_min_estimated_pd_proxy

        DECLINE trigger:
            estimated_pd >= decline_min_estimated_pd_proxy

    These values are synthetic strategy defaults, not production cutoffs.
    */
    0.080000,
    0.160000,
    0.300000,
    0.350000,

    /*
    Global PTI thresholds.

    Product-specific PTI thresholds are used for product-aware affordability rules.
    These global thresholds provide high-level strategy governance.
    */
    0.250000,
    0.400000,
    0.550000,

    /*
    DTI thresholds.

    DTI is an existing-obligation capacity signal.
    */
    0.430000,
    0.600000,
    0.600000,

    /*
    Borderline diagnostic buffer.

    0.050000 means downstream segmentation tags a profile as threshold-adjacent when a value is
    within 5% of a relevant strategy threshold.

    This is a governed diagnostic parameter, not a production underwriting tolerance and not an
    empirically calibrated cutoff.
    */
    0.050000,

    /*
    Section 6 rule-control defaults.

    These values govern simulated trigger construction only.

    They are not production underwriting rules.
    They are not empirically calibrated policy cutoffs.
    They are not final strategy outcomes.
    */
    TRUE,
    TRUE,
    TRUE,
    4,
    TRUE,
    0.850000,
    TRUE,
    580,

    /*
    Decision convention controls.
    */
    'APPROVED_AS_REQUESTED',
    TRUE,
    TRUE,
    'NULL_UNRESOLVED',
    'ZERO',
    'ZERO',
    'NULL_UNRESOLVED',
    FALSE,

    /*
    Failed counteroffer resolution default.

    MANUAL_REVIEW is intentionally conservative and audit-readable. It avoids silently converting all
    infeasible reduced-exposure cases into declines after higher-priority hard simulated policy stop,
    severe synthetic estimated-risk, and severe DTI routes have already been handled.
    */
    'MANUAL_REVIEW'
);



/***************************************************************************************************
SECTION 2.3 — PRODUCT POLICY PARAMETER TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Define product-specific affordability thresholds, requested Expected Loss thresholds, approved
    exposure limits, counteroffer controls, manual-review permissions, and rounding rules.

SQL PURPOSE:
    Provide one governed policy row per supported Module 1 product type.

SUPPORTED PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

****************************************************************************************************/

CREATE TEMP TABLE tmp_module2_product_policy_params (
    /***********************************************************************************************
    Product identity
    ***********************************************************************************************/
    product_type                            TEXT,

    /***********************************************************************************************
    Product-specific PTI thresholds

    These thresholds use requested_payment_to_income_ratio until approved exposure treatment exists.
    ***********************************************************************************************/
    product_approve_max_pti                 NUMERIC(12,6),
    product_review_max_pti                  NUMERIC(12,6),
    product_decline_min_pti                 NUMERIC(12,6),
    counteroffer_target_pti                 NUMERIC(12,6),

    /***********************************************************************************************
    Requested Expected Loss thresholds

    requested_expected_loss_amount is the Module 2 alias for Module 1 expected_loss_amount.
    It is requested-exposure Expected Loss.
    ***********************************************************************************************/
    product_approve_max_requested_el        NUMERIC(18,2),
    product_review_max_requested_el         NUMERIC(18,2),
    product_decline_min_requested_el        NUMERIC(18,2),

    /***********************************************************************************************
    Approved Expected Loss cap

    product_approved_el_cap is used after exposure treatment is evaluated.
    It does not drive pre-decision requested Expected Loss tiering.
    ***********************************************************************************************/
    product_approved_el_cap                 NUMERIC(18,2),

    /***********************************************************************************************
    Approved exposure limits
    ***********************************************************************************************/
    product_min_approved_amount             NUMERIC(18,2),
    product_max_approved_amount             NUMERIC(18,2),

    /***********************************************************************************************
    Counteroffer and manual-review controls
    ***********************************************************************************************/
    counteroffer_allowed_flag               BOOLEAN,
    manual_review_allowed_flag              BOOLEAN,
    product_min_counteroffer_pct            NUMERIC(12,6),
    product_max_exposure_reduction_pct      NUMERIC(12,6),
    exposure_assignment_method              TEXT,

    /***********************************************************************************************
    Rounding
    ***********************************************************************************************/
    approved_amount_rounding_increment      NUMERIC(18,2)
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 2.4 — INSERT PRODUCT POLICY DEFAULTS
****************************************************************************************************

DEFAULT INTERPRETATION:
    These are initial simulated strategy defaults.

    They are not:
        production underwriting limits,
        final approved credit policy,
        empirical calibration,
        real customer treatment rules,
        or regulatory thresholds.

****************************************************************************************************/

INSERT INTO tmp_module2_product_policy_params (
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
)
VALUES
    /*
    MORTGAGE:
        Larger secured exposure. Higher PTI tolerance than unsecured products because mortgage
        structure is long-term and secured, but exposure and approved Expected Loss controls remain
        important.
    */
    (
        'MORTGAGE',
        0.350000,
        0.450000,
        0.550000,
        0.320000,

        10000.00,
        20000.00,
        40000.00,
        10000.00,

        75000.00,
        800000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        5000.00
    ),

    /*
    HELOC:
        Secured revolving exposure. PTI tolerance is lower than mortgage but higher than smaller
        unsecured line-style products.
    */
    (
        'HELOC',
        0.250000,
        0.350000,
        0.450000,
        0.220000,

        8000.00,
        16000.00,
        30000.00,
        7000.00,

        10000.00,
        175000.00,

        TRUE,
        TRUE,
        0.400000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        1000.00
    ),

    /*
    AUTO_LOAN:
        Secured installment exposure with moderate structural risk and payment sensitivity.
    */
    (
        'AUTO_LOAN',
        0.180000,
        0.280000,
        0.380000,
        0.160000,

        3500.00,
        7000.00,
        12000.00,
        3000.00,

        5000.00,
        65000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    ),

    /*
    UNSECURED_PERSONAL_LOAN:
        Smaller unsecured installment exposure with higher loss severity and tighter affordability
        tolerance.
    */
    (
        'UNSECURED_PERSONAL_LOAN',
        0.150000,
        0.250000,
        0.350000,
        0.130000,

        3000.00,
        6000.00,
        10000.00,
        2500.00,

        1000.00,
        35000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    ),

    /*
    REVOLVING_LINE:
        Unsecured revolving exposure with high LGD and APR-sensitive payment proxy upstream.
        Module 2 remains a strategy simulator and not a credit-card billing engine.
    */
    (
        'REVOLVING_LINE',
        0.120000,
        0.200000,
        0.300000,
        0.100000,

        2000.00,
        4000.00,
        8000.00,
        1800.00,

        1000.00,
        20000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    );



/***************************************************************************************************
SECTION 3 — FAIL-FAST STRATEGY PARAMETER GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Prevent invalid Module 2 strategy configuration, malformed product policy configuration, or
    ambiguous Module 1 source input from reaching decision logic.

SQL PURPOSE:
    1. Validate strategy-parameter cardinality.
    2. Validate strategy identity and archive controls.
    3. Validate threshold ranges and threshold ordering.
    4. Validate decision conventions.
    5. Validate Section 6 rule-control parameters.
    6. Validate failed-counteroffer resolution settings.
    7. Validate product policy completeness, supported products, and product threshold ordering.
    8. Validate Module 1 input source table existence, required fields, row count, scenario selection,
       and application_id uniqueness.

WHY FAIL FAST:
    A completed strategy run under invalid configuration is more dangerous than a failed run.
    Gatekeepers prevent silent strategy distortion.

****************************************************************************************************/



/***************************************************************************************************
SECTION 3.1 — STRATEGY PARAMETER CARDINALITY AND THRESHOLD VALIDATION
****************************************************************************************************/

DO $$
DECLARE
    p RECORD;

    v_active_strategy_count BIGINT;
    v_product_policy_count BIGINT;
    v_supported_product_count BIGINT;
    v_duplicate_product_count BIGINT;
    v_unsupported_product_count BIGINT;
    v_missing_supported_product_count BIGINT;
    v_bad_product_policy_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active strategy parameter row.

    Single-strategy execution requires one and only one active strategy configuration.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;

    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required strategy identity fields.

    These fields identify the downstream simulated strategy, not the upstream Module 1 scenario.
    -------------------------------------------------------------------------------------------*/
    IF p.module2_model_version IS NULL OR NULLIF(BTRIM(p.module2_model_version), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: module2_model_version must be non-null and nonblank.';
    END IF;

    IF p.strategy_set_name IS NULL OR NULLIF(BTRIM(p.strategy_set_name), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_set_name must be non-null and nonblank.';
    END IF;

    IF p.strategy_name IS NULL OR NULLIF(BTRIM(p.strategy_name), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_name must be non-null and nonblank.';
    END IF;

    IF p.strategy_version IS NULL OR NULLIF(BTRIM(p.strategy_version), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_version must be non-null and nonblank.';
    END IF;

    IF p.strategy_run_id IS NULL OR NULLIF(BTRIM(p.strategy_run_id), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_run_id must be non-null and nonblank.';
    END IF;

    IF p.strategy_run_ts IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_run_ts must be non-null.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Module 1 input source.

    LATEST:
        credit_decisioning_sim.synthetic_applications

    ARCHIVE:
        credit_decisioning_sim.synthetic_applications_scenario_archive

    Multi-scenario processing is not designed in Module 2 V1.0.
    -------------------------------------------------------------------------------------------*/
    IF p.module1_input_source IS NULL
       OR p.module1_input_source NOT IN ('LATEST', 'ARCHIVE') THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
            COALESCE(p.module1_input_source, '<NULL>');
    END IF;

    IF p.module1_input_source = 'ARCHIVE' THEN
        IF p.source_module1_scenario_set_name IS NULL
           OR NULLIF(BTRIM(p.source_module1_scenario_set_name), '') IS NULL
           OR p.source_module1_scenario_name IS NULL
           OR NULLIF(BTRIM(p.source_module1_scenario_name), '') IS NULL
           OR p.source_population_id IS NULL
           OR NULLIF(BTRIM(p.source_population_id), '') IS NULL THEN
            RAISE EXCEPTION
                'Module 2 gatekeeper failure: ARCHIVE source requires source_module1_scenario_set_name, source_module1_scenario_name, and source_population_id.';
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls.
    -------------------------------------------------------------------------------------------*/
    IF p.archive_run_flag IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: archive_run_flag must not be null.';
    END IF;

    IF p.strategy_archive_reset_mode IS NULL
       OR p.strategy_archive_reset_mode NOT IN (
            'NONE',
            'STRATEGY_SCENARIO_ONLY',
            'STRATEGY_SET_ONLY',
            'ALL'
       ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: strategy_archive_reset_mode must be NONE, STRATEGY_SCENARIO_ONLY, STRATEGY_SET_ONLY, or ALL. Found: %.',
            COALESCE(p.strategy_archive_reset_mode, '<NULL>');
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: synthetic estimated-PD proxy threshold bounds and ordering.

    estimated_pd remains the SQL field name from Module 1.
    These thresholds interpret estimated_pd as the synthetic estimated-PD proxy.
    -------------------------------------------------------------------------------------------*/
    IF p.approve_max_estimated_pd_proxy IS NULL
       OR p.counteroffer_max_estimated_pd_proxy IS NULL
       OR p.review_max_estimated_pd_proxy IS NULL
       OR p.decline_min_estimated_pd_proxy IS NULL
       OR p.approve_max_estimated_pd_proxy < 0
       OR p.approve_max_estimated_pd_proxy > 1
       OR p.counteroffer_max_estimated_pd_proxy < 0
       OR p.counteroffer_max_estimated_pd_proxy > 1
       OR p.review_max_estimated_pd_proxy < 0
       OR p.review_max_estimated_pd_proxy > 1
       OR p.decline_min_estimated_pd_proxy < 0
       OR p.decline_min_estimated_pd_proxy > 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: synthetic estimated-PD proxy thresholds must be non-null and between 0 and 1.';
    END IF;

    IF NOT (
        p.approve_max_estimated_pd_proxy < p.counteroffer_max_estimated_pd_proxy
        AND p.counteroffer_max_estimated_pd_proxy <= p.review_max_estimated_pd_proxy
        AND p.review_max_estimated_pd_proxy <= p.decline_min_estimated_pd_proxy
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: synthetic estimated-PD proxy threshold ordering is invalid.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: global PTI threshold bounds and ordering.

    PTI thresholds are strategy simulation controls, not production underwriting cutoffs.
    -------------------------------------------------------------------------------------------*/
    IF p.global_approve_max_pti IS NULL
       OR p.global_review_max_pti IS NULL
       OR p.global_decline_min_pti IS NULL
       OR p.global_approve_max_pti < 0
       OR p.global_approve_max_pti > 1.5
       OR p.global_review_max_pti < 0
       OR p.global_review_max_pti > 1.5
       OR p.global_decline_min_pti < 0
       OR p.global_decline_min_pti > 1.5 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: global PTI thresholds must be non-null and between 0 and 1.5.';
    END IF;

    IF NOT (
        p.global_approve_max_pti < p.global_review_max_pti
        AND p.global_review_max_pti <= p.global_decline_min_pti
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: global PTI threshold ordering is invalid.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DTI threshold bounds and ordering.

    DTI is an existing-obligation capacity signal.
    -------------------------------------------------------------------------------------------*/
    IF p.approve_max_dti IS NULL
       OR p.review_max_dti IS NULL
       OR p.decline_min_dti IS NULL
       OR p.approve_max_dti < 0
       OR p.approve_max_dti > 1
       OR p.review_max_dti < 0
       OR p.review_max_dti > 1
       OR p.decline_min_dti < 0
       OR p.decline_min_dti > 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: DTI thresholds must be non-null and between 0 and 1.';
    END IF;

    IF NOT (
        p.approve_max_dti < p.review_max_dti
        AND p.review_max_dti <= p.decline_min_dti
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: DTI threshold ordering is invalid.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: borderline diagnostic buffer.

    This parameter exists only to support non-decisioning segmentation.
    It prevents hidden hardcoded "near threshold" logic from appearing inside downstream CASE blocks.

    Allowed range:
        0.000000 to 0.250000

    Interpretation:
        0.000000 disables threshold-adjacent borderline tagging.
        Values above 0.250000 are not allowed because they would make too much of the population
        appear borderline and reduce diagnostic usefulness.
    -------------------------------------------------------------------------------------------*/
    IF p.borderline_threshold_buffer_pct IS NULL
       OR p.borderline_threshold_buffer_pct < 0
       OR p.borderline_threshold_buffer_pct > 0.250000 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: borderline_threshold_buffer_pct must be between 0 and 0.25.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 6 rule-control parameters.

    These parameters govern simulated rule trigger flags only. They do not create final strategy
    outcomes, reason codes, approved amounts, or approved Expected Loss.
    -------------------------------------------------------------------------------------------*/
    IF p.bankruptcy_policy_stop_enabled IS NULL
       OR p.major_derogatory_policy_stop_enabled IS NULL
       OR p.severe_delinquency_policy_stop_enabled IS NULL
       OR p.high_utilization_review_enabled IS NULL
       OR p.low_score_review_enabled IS NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: Section 6 boolean rule-control parameters must not be null.';
    END IF;

    IF p.severe_delinquency_count_threshold IS NULL
       OR p.severe_delinquency_count_threshold < 0 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: severe_delinquency_count_threshold must be a non-negative integer.';
    END IF;

    IF p.high_utilization_review_threshold IS NULL
       OR p.high_utilization_review_threshold < 0
       OR p.high_utilization_review_threshold > 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: high_utilization_review_threshold must be between 0 and 1.';
    END IF;

    IF p.low_score_review_threshold IS NULL
       OR p.low_score_review_threshold < 300
       OR p.low_score_review_threshold > 850 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: low_score_review_threshold must be between 300 and 850.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: decision convention controls.
    -------------------------------------------------------------------------------------------*/
    IF p.allow_approved_amount_above_requested_flag IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: allow_approved_amount_above_requested_flag must be FALSE for Module 2 V1.0.';
    END IF;

    IF p.decline_approved_amount_convention <> 'ZERO' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: decline_approved_amount_convention must equal ZERO.';
    END IF;

    IF p.manual_review_approved_amount_convention <> 'NULL_UNRESOLVED' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: manual_review_approved_amount_convention must equal NULL_UNRESOLVED.';
    END IF;

    IF p.approved_el_decline_convention <> 'ZERO' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: approved_el_decline_convention must equal ZERO.';
    END IF;

    IF p.approved_el_manual_review_convention <> 'NULL_UNRESOLVED' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: approved_el_manual_review_convention must equal NULL_UNRESOLVED.';
    END IF;

    IF p.reason_code_required_flag IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: reason_code_required_flag must be TRUE.';
    END IF;

    IF p.simulated_offer_exposure_flag_enabled IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: simulated_offer_exposure_flag_enabled must be TRUE.';
    END IF;

    IF p.approve_reason_code IS NULL
       OR NULLIF(BTRIM(p.approve_reason_code), '') IS NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: approve_reason_code must be non-null and nonblank.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: failed counteroffer resolution.

    This parameter governs final decision resolution for preliminary COUNTEROFFER rows where
    Section 8 determines that no viable reduced-exposure treatment exists.

    Allowed values:
        MANUAL_REVIEW
        DECLINE

    Default:
        MANUAL_REVIEW

    This is a simulated strategy-control parameter. It is not production underwriting policy.
    -------------------------------------------------------------------------------------------*/
    IF p.failed_counteroffer_resolution IS NULL
       OR p.failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE') THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: failed_counteroffer_resolution must be MANUAL_REVIEW or DECLINE. Found: %.',
            COALESCE(p.failed_counteroffer_resolution, '<NULL>');
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product policy table contains exactly one row per supported product type.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_product_policy_count
    FROM tmp_module2_product_policy_params;

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

    SELECT COUNT(*)
    INTO v_duplicate_product_count
    FROM (
        SELECT product_type
        FROM tmp_module2_product_policy_params
        GROUP BY product_type
        HAVING COUNT(*) > 1
    ) d;

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
        ) s(product_type)
        EXCEPT
        SELECT product_type
        FROM tmp_module2_product_policy_params
    ) m;

    IF v_product_policy_count <> 5
       OR v_supported_product_count <> 5
       OR v_duplicate_product_count > 0
       OR v_unsupported_product_count > 0
       OR v_missing_supported_product_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: product policy table must contain exactly one row for each supported product type. Rows=%, supported distinct=%, duplicate groups=%, unsupported rows=%, missing supported products=%.',
            v_product_policy_count,
            v_supported_product_count,
            v_duplicate_product_count,
            v_unsupported_product_count,
            v_missing_supported_product_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product policy threshold and exposure validation.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_bad_product_policy_count
    FROM tmp_module2_product_policy_params
    WHERE product_type IS NULL
       OR NULLIF(BTRIM(product_type), '') IS NULL

       OR product_approve_max_pti IS NULL
       OR product_review_max_pti IS NULL
       OR product_decline_min_pti IS NULL
       OR counteroffer_target_pti IS NULL
       OR product_approve_max_pti < 0
       OR product_approve_max_pti > 1.5
       OR product_review_max_pti < 0
       OR product_review_max_pti > 1.5
       OR product_decline_min_pti < 0
       OR product_decline_min_pti > 1.5
       OR counteroffer_target_pti < 0
       OR counteroffer_target_pti > 1.5
       OR product_approve_max_pti >= product_review_max_pti
       OR product_review_max_pti > product_decline_min_pti

       OR product_approve_max_requested_el IS NULL
       OR product_review_max_requested_el IS NULL
       OR product_decline_min_requested_el IS NULL
       OR product_approved_el_cap IS NULL
       OR product_approve_max_requested_el < 0
       OR product_review_max_requested_el < 0
       OR product_decline_min_requested_el < 0
       OR product_approved_el_cap < 0
       OR product_approve_max_requested_el > product_review_max_requested_el
       OR product_review_max_requested_el > product_decline_min_requested_el

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
       OR exposure_assignment_method NOT IN ('MOST_CONSERVATIVE_FEASIBLE_AMOUNT')
       OR approved_amount_rounding_increment IS NULL
       OR approved_amount_rounding_increment <= 0;

    IF v_bad_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: % product policy row(s) failed threshold, exposure, counteroffer, or rounding validation.',
            v_bad_product_policy_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.2 — MODULE 1 SOURCE-INPUT VALIDATION
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that the selected Module 1 source exists, contains rows, has required fields, is scoped
    to exactly one scenario / population slice, and has no duplicate application_id values.

WHY THIS MATTERS:
    Module 2 strategy comparison depends on exact source lineage.

    If source selection is ambiguous, downstream strategy outcomes may be attributed to strategy
    changes when they actually reflect population drift or source-table errors.

****************************************************************************************************/

DO $$
DECLARE
    p RECORD;

    v_source_table_schema TEXT;
    v_source_table_name TEXT;
    v_source_regclass REGCLASS;

    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;

    v_required_missing_columns TEXT;
    v_source_row_count BIGINT;
    v_selected_row_count BIGINT;
    v_selected_distinct_application_count BIGINT;
    v_duplicate_application_group_count BIGINT;
    v_scenario_population_count BIGINT;
    v_null_required_field_count BIGINT;

    v_required_column_list TEXT[] := ARRAY[
        'application_id',
        'applicant_id',
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
        'population_id'
    ];

    v_null_check_expression TEXT;
BEGIN
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;

    IF p.module1_input_source = 'LATEST' THEN
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications';
    ELSE
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications_scenario_archive';
    END IF;

    v_source_regclass := TO_REGCLASS(v_source_table_schema || '.' || v_source_table_name);

    IF v_source_regclass IS NULL THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source table %.% does not exist.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required Module 1 source fields must be present.

    scenario_set_name / scenario_name may appear either as Module 1 raw names or already-normalized
    Module 2 lineage names. Section 4 aliases them to:
        module1_scenario_set_name
        module1_scenario_name
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(missing_col, ', ' ORDER BY missing_col)
    INTO v_required_missing_columns
    FROM (
        SELECT unnest(v_required_column_list) AS missing_col
        EXCEPT
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
    ) m;

    IF v_required_missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source %.% is missing required field(s): %.',
            v_source_table_schema,
            v_source_table_name,
            v_required_missing_columns;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'module1_scenario_set_name'
    ) THEN
        v_scenario_set_col := 'module1_scenario_set_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'scenario_set_name'
    ) THEN
        v_scenario_set_col := 'scenario_set_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source %.% must contain scenario_set_name or module1_scenario_set_name.',
            v_source_table_schema,
            v_source_table_name;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'module1_scenario_name'
    ) THEN
        v_scenario_name_col := 'module1_scenario_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'scenario_name'
    ) THEN
        v_scenario_name_col := 'scenario_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source %.% must contain scenario_name or module1_scenario_name.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: selected source table must contain rows.
    -------------------------------------------------------------------------------------------*/
    EXECUTE FORMAT(
        'SELECT COUNT(*) FROM %I.%I',
        v_source_table_schema,
        v_source_table_name
    )
    INTO v_source_row_count;

    IF v_source_row_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source %.% contains zero rows.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: selected latest-run or archive slice must contain exactly one scenario / population.

    LATEST:
        latest-run table must already represent exactly one Module 1 scenario / population.

    ARCHIVE:
        Section 3 filters using the selected source scenario fields and population_id.
    -------------------------------------------------------------------------------------------*/
    IF p.module1_input_source = 'LATEST' THEN
        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM (
                 SELECT DISTINCT %I, %I, population_id
                 FROM %I.%I
             ) s',
            v_scenario_set_col,
            v_scenario_name_col,
            v_source_table_schema,
            v_source_table_name
        )
        INTO v_scenario_population_count;

        IF v_scenario_population_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: latest-run Module 1 source contains % scenario / population combinations. Module 2 V1.0 expects exactly one.',
                v_scenario_population_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*), COUNT(DISTINCT application_id)
             FROM %I.%I',
            v_source_table_schema,
            v_source_table_name
        )
        INTO v_selected_row_count, v_selected_distinct_application_count;

        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM (
                 SELECT application_id
                 FROM %I.%I
                 GROUP BY application_id
                 HAVING COUNT(*) > 1
             ) d',
            v_source_table_schema,
            v_source_table_name
        )
        INTO v_duplicate_application_group_count;

        v_null_check_expression :=
            'application_id IS NULL
             OR applicant_id IS NULL
             OR product_type IS NULL
             OR score_band IS NULL
             OR credit_score IS NULL
             OR requested_amount IS NULL
             OR annual_income IS NULL
             OR monthly_payment_proxy IS NULL
             OR payment_to_income_ratio IS NULL
             OR amount_to_income_ratio IS NULL
             OR debt_to_income_ratio IS NULL
             OR utilization_rate IS NULL
             OR tradeline_count IS NULL
             OR months_since_oldest_trade IS NULL
             OR recent_inquiry_count IS NULL
             OR delinquency_count_12m IS NULL
             OR major_derogatory_flag IS NULL
             OR bankruptcy_flag IS NULL
             OR estimated_pd IS NULL
             OR estimated_lgd IS NULL
             OR expected_loss_amount IS NULL
             OR population_id IS NULL
             OR ' || FORMAT('%I IS NULL', v_scenario_set_col) || '
             OR ' || FORMAT('%I IS NULL', v_scenario_name_col);

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM %I.%I
             WHERE %s',
            v_source_table_schema,
            v_source_table_name,
            v_null_check_expression
        )
        INTO v_null_required_field_count;

    ELSE
        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM %I.%I
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3',
            v_source_table_schema,
            v_source_table_name,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_selected_row_count
        USING
            p.source_module1_scenario_set_name,
            p.source_module1_scenario_name,
            p.source_population_id;

        IF v_selected_row_count = 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected Module 1 archive slice contains zero rows. scenario_set=%, scenario_name=%, population_id=%.',
                p.source_module1_scenario_set_name,
                p.source_module1_scenario_name,
                p.source_population_id;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM (
                 SELECT DISTINCT %I, %I, population_id
                 FROM %I.%I
                 WHERE %I = $1
                   AND %I = $2
                   AND population_id = $3
             ) s',
            v_scenario_set_col,
            v_scenario_name_col,
            v_source_table_schema,
            v_source_table_name,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_scenario_population_count
        USING
            p.source_module1_scenario_set_name,
            p.source_module1_scenario_name,
            p.source_population_id;

        IF v_scenario_population_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected Module 1 archive slice contains % scenario / population combinations. Expected exactly one.',
                v_scenario_population_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(DISTINCT application_id)
             FROM %I.%I
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3',
            v_source_table_schema,
            v_source_table_name,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_selected_distinct_application_count
        USING
            p.source_module1_scenario_set_name,
            p.source_module1_scenario_name,
            p.source_population_id;

        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM (
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

        v_null_check_expression :=
            'application_id IS NULL
             OR applicant_id IS NULL
             OR product_type IS NULL
             OR score_band IS NULL
             OR credit_score IS NULL
             OR requested_amount IS NULL
             OR annual_income IS NULL
             OR monthly_payment_proxy IS NULL
             OR payment_to_income_ratio IS NULL
             OR amount_to_income_ratio IS NULL
             OR debt_to_income_ratio IS NULL
             OR utilization_rate IS NULL
             OR tradeline_count IS NULL
             OR months_since_oldest_trade IS NULL
             OR recent_inquiry_count IS NULL
             OR delinquency_count_12m IS NULL
             OR major_derogatory_flag IS NULL
             OR bankruptcy_flag IS NULL
             OR estimated_pd IS NULL
             OR estimated_lgd IS NULL
             OR expected_loss_amount IS NULL
             OR population_id IS NULL
             OR ' || FORMAT('%I IS NULL', v_scenario_set_col) || '
             OR ' || FORMAT('%I IS NULL', v_scenario_name_col);

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
    END IF;


    IF v_selected_row_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source slice contains zero rows.';
    END IF;

    IF v_selected_distinct_application_count <> v_selected_row_count THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source slice has duplicate application_id values. Rows=%, distinct application_id=%, duplicate groups=%.',
            v_selected_row_count,
            v_selected_distinct_application_count,
            v_duplicate_application_group_count;
    END IF;

    IF v_duplicate_application_group_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source slice contains % duplicate application_id group(s).',
            v_duplicate_application_group_count;
    END IF;

    IF v_null_required_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: selected Module 1 source slice contains % row(s) with null required fields.',
            v_null_required_field_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.3 — THRESHOLD EQUALITY CONVENTION DOCUMENTATION
****************************************************************************************************

The following equality conventions are locked for downstream rule logic.

SYNTHETIC ESTIMATED-PD PROXY:
    APPROVE eligibility:
        estimated_pd <= approve_max_estimated_pd_proxy

    COUNTEROFFER eligibility:
        estimated_pd > approve_max_estimated_pd_proxy
        AND estimated_pd <= counteroffer_max_estimated_pd_proxy

    MANUAL_REVIEW synthetic risk band:
        estimated_pd > counteroffer_max_estimated_pd_proxy
        AND estimated_pd < decline_min_estimated_pd_proxy

    DECLINE trigger:
        estimated_pd >= decline_min_estimated_pd_proxy

REQUESTED PTI:
    APPROVE:
        requested_payment_to_income_ratio <= product_approve_max_pti

    COUNTEROFFER candidate:
        requested_payment_to_income_ratio > product_approve_max_pti
        and counteroffer can potentially reduce approved PTI to target

    MANUAL_REVIEW:
        requested_payment_to_income_ratio > product_approve_max_pti
        and requested_payment_to_income_ratio < product_decline_min_pti
        where counteroffer is not cleanly viable or review triggers apply

    DECLINE trigger:
        requested_payment_to_income_ratio >= product_decline_min_pti
        when no viable counteroffer or review path is intended

DTI:
    APPROVE:
        debt_to_income_ratio <= approve_max_dti

    MANUAL_REVIEW:
        debt_to_income_ratio > approve_max_dti
        AND debt_to_income_ratio < decline_min_dti

    DECLINE:
        debt_to_income_ratio >= decline_min_dti

REQUESTED EXPECTED LOSS:
    Clean approval must satisfy:
        requested_expected_loss_amount <= product_approve_max_requested_el

    Counteroffer may be considered when requested Expected Loss exceeds clean approval tolerance
    but approved-exposure Expected Loss can satisfy product_approved_el_cap.

    Decline / review boundary uses:
        product_review_max_requested_el
        product_decline_min_requested_el
        final strategy hierarchy

COUNTEROFFER:
    A preliminary counteroffer route is not final.
    Feasibility requires later approved-exposure calculation.

MANUAL REVIEW:
    Manual review remains unresolved by design.

***************************************************************************************************/



/***************************************************************************************************
SECTION 3.4 — LOCAL PARAMETER AND SOURCE SANITY CHECKS
****************************************************************************************************

These queries are lightweight setup diagnostics.

They are not the full Module 2 QA framework.
They do not validate final strategy outcomes.
They exist to make parameter and source setup visible before downstream stages execute.

****************************************************************************************************/


/* Active strategy parameter row. */
SELECT
    active_strategy_flag,
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,
    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,
    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution
FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;


/* Global threshold setup. */
SELECT
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


/* Product policy setup. */
SELECT
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
ORDER BY product_type;


/***************************************************************************************************
END OF PART 1 OF 7

Sections captured in this part:
    Section 0 — Executive Purpose, Module 2 Boundaries, and SQL Section Map
    Section 1 — Schema Setup / Clean Rerun Reset
    Section 2 — Strategy Parameter Framework and Product Policy Parameter Framework
    Section 3 — Fail-Fast Strategy Parameter Gatekeeper

***************************************************************************************************/

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 1 OF 7 END
```

Ready for next part: say CONTINUE FULL CODE PART 2
<!-- END_MESSAGE C038-M00178 -->


---

<a id="c038-m00180"></a>

### C038-M00180

**Andrew** · 2026-05-06T17:06:22.196000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00180 -->
CONTINUE FULL CODE PART 2
<!-- END_MESSAGE C038-M00180 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_07.md) · [Next](Part_09.md)
