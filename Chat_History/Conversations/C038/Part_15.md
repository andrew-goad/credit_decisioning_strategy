# Module 2 Decision Simulator Build

## Part 15

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_14.md) · [Next](Part_16.md)

<a id="c038-m00223"></a>

### C038-M00223

**ChatGPT** · 2026-05-06T18:04:59.955328-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00223 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 7 OF 7 START

/***************************************************************************************************
SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Provide read-only archive inventory and matched strategy comparison queries.

    Section 13 answers:

        "How do two archived Module 2 strategy runs differ when applied to the same Module 1 scenario
         and population?"

SQL PURPOSE:
    1. Inspect credit_decisioning_sim.strategy_decisions_archive.
    2. Provide archive inventory.
    3. Create a temporary comparison parameter table.
    4. Evaluate comparison readiness.
    5. Compare baseline and challenger strategy slices at portfolio, segment, outcome-migration,
       reason-code, simulated offer-exposure, and row-level diagnostic levels.
    6. Confirm matched source-field consistency for immutable Module 1 input fields.
    7. Avoid mutating archive history or recalculating strategy outcomes.

READ-ONLY BOUNDARY:
    Section 13 does not insert archive rows.
    Section 13 does not delete archive rows.
    Section 13 does not update archive rows.
    Section 13 does not recalculate decision_outcome.
    Section 13 does not recalculate approved exposure.
    Section 13 does not recalculate approved Expected Loss.
    Section 13 does not reassign simulated reason codes.

TEMPORARY PARAMETER NOTE:
    tmp_m2_strategy_comparison_params is a temporary comparison-selection helper table.

    Creating or replacing this temporary helper object does not mutate the governed latest-run or
    archive outputs.

WHY ARCHIVE INVENTORY IS SEPARATED FROM ARCHIVE PERSISTENCE:
    Section 12 persists completed latest-run outputs.
    Section 13 inspects completed archived outputs.

    This separation protects archive history from being changed during comparison review.

WHY MATCHED COMPARISON REQUIRES THE SAME MODULE 1 SCENARIO AND POPULATION:
    Module 2 strategy comparison should isolate downstream strategy effects.

    In Module 2 V1.0, baseline and challenger strategy slices must share:
        module1_scenario_set_name
        module1_scenario_name
        population_id

    Comparing across different Module 1 scenarios would mix upstream population / rate-environment
    effects with downstream Module 2 strategy effects.

WHY MODULE 1 SCENARIO METADATA AND MODULE 2 STRATEGY METADATA REMAIN SEPARATE:
    Module 1 scenario metadata describes the synthetic population and upstream risk environment.
    Module 2 strategy metadata describes the simulated decision strategy applied to that population.

    These are not interchangeable.

WHY ROW-LEVEL MATCHING USES APPLICATION_ID:
    application_id identifies the same synthetic application within the same Module 1 scenario and
    population. It is the correct row-level join key for matched Module 2 strategy comparison.

WHY STRATEGY_RUN_ID AND TIMESTAMPS ARE NOT MATCHED-COMPARISON KEYS:
    strategy_run_id, strategy_run_ts, latest_output_created_ts, and archive_inserted_ts are audit
    metadata.

    They support traceability but should not define matched strategy comparison grain.

WHY DECISION MIGRATION IS USEFUL:
    Decision migration shows how final simulated strategy outcomes move from baseline to challenger:
        APPROVE → COUNTEROFFER
        APPROVE → MANUAL_REVIEW
        APPROVE → DECLINE
        DECLINE → APPROVE
        or stable outcomes.

WHY REQUESTED AND APPROVED EXPECTED LOSS ARE BOTH COMPARED:
    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.
    approved_expected_loss_amount is approved-exposure Expected Loss after Module 2 exposure
    treatment.

    Comparing both shows how strategy changes affect requested-risk profile and simulated
    offer-exposure economics.

WHY SIMULATED OFFER EXPOSURE IS NOT OPERATIONAL EXPOSURE:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows in the simulated strategy
    output.

    It does not imply operational account creation, funding, production approval, or real applicant
    treatment.

WHY REASON-CODE MIGRATION SUPPORTS EXPLAINABILITY:
    Numeric deltas explain how much strategy behavior changed.
    Reason-code movement explains why strategy behavior changed.

SECTION 13 IS NOT THE FULL QA FRAMEWORK:
    Section 13 compares archived strategy slices.
    Section 14 validates the latest-run output.

***************************************************************************************************/



/***************************************************************************************************
SECTION 13.1 — ARCHIVE INVENTORY
****************************************************************************************************

PURPOSE:
    Show what archived Module 2 strategy runs are available.

INTERPRETATION:
    This is the first query users should review before selecting baseline and challenger strategies.

***************************************************************************************************/

SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS archived_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count
FROM credit_decisioning_sim.strategy_decisions_archive
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


/* Outcome inventory for archived strategy slices. */
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    decision_outcome,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY
                    strategy_set_name,
                    strategy_name,
                    strategy_version,
                    module1_scenario_set_name,
                    module1_scenario_name,
                    population_id
            ),
            0
        ),
        2
    ) AS pct_of_archived_slice
FROM credit_decisioning_sim.strategy_decisions_archive
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    decision_outcome
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 13.2 — COMPARISON PARAMETER TABLE
****************************************************************************************************

PURPOSE:
    Define the selected baseline and challenger archived strategy slices for read-only comparison.

USER ACTION:
    Update tmp_m2_strategy_comparison_params before running Section 13 comparison queries if the
    defaults do not identify the intended archived baseline and challenger strategy slices.

V1.0 COMPARISON BOUNDARY:
    Matched strategy comparison requires:
        same module1_scenario_set_name
        same module1_scenario_name
        same population_id

    Baseline and challenger should differ by strategy_name and/or strategy_version.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;

CREATE TEMP TABLE tmp_m2_strategy_comparison_params (
    comparison_set_name                   TEXT,

    baseline_strategy_set_name            TEXT,
    baseline_strategy_name                TEXT,
    baseline_strategy_version             TEXT,

    challenger_strategy_set_name          TEXT,
    challenger_strategy_name              TEXT,
    challenger_strategy_version           TEXT,

    module1_scenario_set_name             TEXT,
    module1_scenario_name                 TEXT,
    population_id                         TEXT
) ON COMMIT PRESERVE ROWS;


/*
Default comparison selection:
    Baseline defaults to the current latest-run strategy identity.
    Challenger uses a placeholder strategy name that users should update to an archived challenger.

This default makes Section 13 safe to execute even when only one strategy slice has been archived.
Readiness diagnostics will show whether comparison is possible.
*/
INSERT INTO tmp_m2_strategy_comparison_params (
    comparison_set_name,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id
)
SELECT
    'MODULE2_BASELINE_VS_CHALLENGER' AS comparison_set_name,

    strategy_set_name AS baseline_strategy_set_name,
    strategy_name AS baseline_strategy_name,
    strategy_version AS baseline_strategy_version,

    strategy_set_name AS challenger_strategy_set_name,
    'CHALLENGER_STRATEGY_PLACEHOLDER' AS challenger_strategy_name,
    strategy_version AS challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id
FROM credit_decisioning_sim.strategy_decisions
LIMIT 1;


/* Display current comparison parameter selection. */
SELECT *
FROM tmp_m2_strategy_comparison_params;



/***************************************************************************************************
SECTION 13.3 — SELECTED COMPARISON READINESS
****************************************************************************************************

PURPOSE:
    Confirm whether the selected baseline and challenger archived strategy slices are suitable for
    matched comparison.

READINESS STATUS VALUES:
    READY_FOR_MATCHED_COMPARISON
    NOT_READY_SAME_STRATEGY_SELECTED
    NOT_READY_BASELINE_MISSING
    NOT_READY_CHALLENGER_MISSING
    NOT_READY_DUPLICATE_ARCHIVE_GRAIN
    NOT_READY_ROW_COUNT_MISMATCH
    NOT_READY_UNMATCHED_APPLICATIONS

IMPORTANT:
    This is diagnostic and read-only.
    It does not block ordinary archive inventory review.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

baseline_counts AS (
    SELECT
        COUNT(*) AS baseline_archived_row_count,
        COUNT(DISTINCT application_id) AS baseline_distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS baseline_duplicate_application_row_count
    FROM baseline_slice
),

challenger_counts AS (
    SELECT
        COUNT(*) AS challenger_archived_row_count,
        COUNT(DISTINCT application_id) AS challenger_distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS challenger_duplicate_application_row_count
    FROM challenger_slice
),

baseline_apps AS (
    SELECT DISTINCT application_id
    FROM baseline_slice
),

challenger_apps AS (
    SELECT DISTINCT application_id
    FROM challenger_slice
),

application_match AS (
    SELECT
        COUNT(*) FILTER (
            WHERE b.application_id IS NOT NULL
              AND c.application_id IS NOT NULL
        ) AS matched_application_id_count,

        COUNT(*) FILTER (
            WHERE b.application_id IS NOT NULL
              AND c.application_id IS NULL
        ) AS baseline_only_application_id_count,

        COUNT(*) FILTER (
            WHERE b.application_id IS NULL
              AND c.application_id IS NOT NULL
        ) AS challenger_only_application_id_count
    FROM baseline_apps b
    FULL OUTER JOIN challenger_apps c
        ON c.application_id = b.application_id
),

readiness AS (
    SELECT
        p.comparison_set_name,

        p.module1_scenario_set_name,
        p.module1_scenario_name,
        p.population_id,

        p.baseline_strategy_set_name,
        p.baseline_strategy_name,
        p.baseline_strategy_version,

        p.challenger_strategy_set_name,
        p.challenger_strategy_name,
        p.challenger_strategy_version,

        (
            p.baseline_strategy_set_name = p.challenger_strategy_set_name
            AND p.baseline_strategy_name = p.challenger_strategy_name
            AND p.baseline_strategy_version = p.challenger_strategy_version
        ) AS same_strategy_selected_flag,

        bc.baseline_archived_row_count,
        cc.challenger_archived_row_count,

        bc.baseline_distinct_application_id_count,
        cc.challenger_distinct_application_id_count,

        bc.baseline_duplicate_application_row_count,
        cc.challenger_duplicate_application_row_count,

        am.matched_application_id_count,
        am.baseline_only_application_id_count,
        am.challenger_only_application_id_count,

        CASE
            /*
            Same-strategy comparison is not a valid Module 2 V1.0 strategy delta comparison.

            Deterministic reproducibility testing can be designed later if needed.
            Section 13 V1.0 is focused on baseline versus challenger strategy comparison.
            */
            WHEN p.baseline_strategy_set_name = p.challenger_strategy_set_name
             AND p.baseline_strategy_name = p.challenger_strategy_name
             AND p.baseline_strategy_version = p.challenger_strategy_version
                THEN 'NOT_READY_SAME_STRATEGY_SELECTED'

            WHEN bc.baseline_archived_row_count = 0
                THEN 'NOT_READY_BASELINE_MISSING'

            WHEN cc.challenger_archived_row_count = 0
                THEN 'NOT_READY_CHALLENGER_MISSING'

            WHEN bc.baseline_duplicate_application_row_count > 0
              OR cc.challenger_duplicate_application_row_count > 0
                THEN 'NOT_READY_DUPLICATE_ARCHIVE_GRAIN'

            WHEN bc.baseline_archived_row_count <> cc.challenger_archived_row_count
                THEN 'NOT_READY_ROW_COUNT_MISMATCH'

            WHEN am.baseline_only_application_id_count > 0
              OR am.challenger_only_application_id_count > 0
              OR am.matched_application_id_count <> bc.baseline_distinct_application_id_count
                THEN 'NOT_READY_UNMATCHED_APPLICATIONS'

            ELSE 'READY_FOR_MATCHED_COMPARISON'
        END AS readiness_status

    FROM p
    CROSS JOIN baseline_counts bc
    CROSS JOIN challenger_counts cc
    CROSS JOIN application_match am
)
SELECT *
FROM readiness;



/***************************************************************************************************
SECTION 13.4 — PORTFOLIO-LEVEL ARCHIVED STRATEGY SUMMARY
****************************************************************************************************

PURPOSE:
    Compare selected archived strategies at the portfolio level.

METRIC CONVENTIONS:
    all-app approved exposure metrics:
        use COALESCE(approved_amount, 0)
        use COALESCE(approved_expected_loss_amount, 0)

    offer-row metrics:
        use FILTER (WHERE simulated_offer_exposure_flag IS TRUE)

    Manual-review rows remain unresolved in source data.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

selected_slices AS (
    SELECT
        'BASELINE'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)

SELECT
    comparison_role,

    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_count,
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    AVG(requested_amount) AS average_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_counteroffers,

    AVG(requested_payment_to_income_ratio) AS average_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    AVG(estimated_pd) AS average_synthetic_estimated_pd_proxy,
    AVG(estimated_lgd) AS average_estimated_lgd,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(requested_expected_loss_amount) AS average_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows
FROM selected_slices
GROUP BY
    comparison_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
ORDER BY comparison_role;



/***************************************************************************************************
SECTION 13.5 — BASELINE VS CHALLENGER PORTFOLIO DELTA SUMMARY
****************************************************************************************************

PURPOSE:
    Show direct portfolio-level deltas between baseline and challenger.

BOUNDARY:
    This is a matched strategy simulation comparison. It should not be interpreted as causal proof
    beyond the controlled synthetic strategy-simulation boundary.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

selected_slices AS (
    SELECT
        'BASELINE'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

portfolio_summary AS (
    SELECT
        comparison_role,

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

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_declined_rows

    FROM selected_slices
    GROUP BY comparison_role
)

SELECT
    p.comparison_set_name,

    p.module1_scenario_set_name,
    p.module1_scenario_name,
    p.population_id,

    p.baseline_strategy_set_name,
    p.baseline_strategy_name,
    p.baseline_strategy_version,

    p.challenger_strategy_set_name,
    p.challenger_strategy_name,
    p.challenger_strategy_version,

    b.applications AS baseline_applications,
    c.applications AS challenger_applications,

    b.approval_rate AS baseline_approval_rate,
    c.approval_rate AS challenger_approval_rate,
    c.approval_rate - b.approval_rate AS delta_approval_rate,

    b.counteroffer_rate AS baseline_counteroffer_rate,
    c.counteroffer_rate AS challenger_counteroffer_rate,
    c.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

    b.manual_review_rate AS baseline_manual_review_rate,
    c.manual_review_rate AS challenger_manual_review_rate,
    c.manual_review_rate - b.manual_review_rate AS delta_manual_review_rate,

    b.decline_rate AS baseline_decline_rate,
    c.decline_rate AS challenger_decline_rate,
    c.decline_rate - b.decline_rate AS delta_decline_rate,

    b.simulated_offer_exposure_rate AS baseline_simulated_offer_exposure_rate,
    c.simulated_offer_exposure_rate AS challenger_simulated_offer_exposure_rate,
    c.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
        AS delta_simulated_offer_exposure_rate,

    b.total_approved_amount AS baseline_total_approved_amount,
    c.total_approved_amount AS challenger_total_approved_amount,
    c.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    b.avg_approved_amount_all_apps AS baseline_avg_approved_amount_all_apps,
    c.avg_approved_amount_all_apps AS challenger_avg_approved_amount_all_apps,
    c.avg_approved_amount_all_apps - b.avg_approved_amount_all_apps
        AS delta_avg_approved_amount_all_apps,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    c.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    c.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.avg_approved_expected_loss_all_apps AS baseline_avg_approved_expected_loss_all_apps,
    c.avg_approved_expected_loss_all_apps AS challenger_avg_approved_expected_loss_all_apps,
    c.avg_approved_expected_loss_all_apps - b.avg_approved_expected_loss_all_apps
        AS delta_avg_approved_expected_loss_all_apps,

    b.avg_approved_pti_offer_rows AS baseline_avg_approved_pti_offer_rows,
    c.avg_approved_pti_offer_rows AS challenger_avg_approved_pti_offer_rows,
    c.avg_approved_pti_offer_rows - b.avg_approved_pti_offer_rows
        AS delta_avg_approved_pti_offer_rows,

    b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS baseline_avg_synthetic_estimated_pd_proxy_offer_rows,
    c.avg_synthetic_estimated_pd_proxy_offer_rows
        AS challenger_avg_synthetic_estimated_pd_proxy_offer_rows,
    c.avg_synthetic_estimated_pd_proxy_offer_rows
      - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_avg_synthetic_estimated_pd_proxy_offer_rows,

    b.avg_synthetic_estimated_pd_proxy_declined_rows
        AS baseline_avg_synthetic_estimated_pd_proxy_declined_rows,
    c.avg_synthetic_estimated_pd_proxy_declined_rows
        AS challenger_avg_synthetic_estimated_pd_proxy_declined_rows,
    c.avg_synthetic_estimated_pd_proxy_declined_rows
      - b.avg_synthetic_estimated_pd_proxy_declined_rows
        AS delta_avg_synthetic_estimated_pd_proxy_declined_rows

FROM p
JOIN portfolio_summary b
    ON b.comparison_role = 'BASELINE'
JOIN portfolio_summary c
    ON c.comparison_role = 'CHALLENGER';



/***************************************************************************************************
SECTION 13.6 — DECISION MIGRATION MATRIX
****************************************************************************************************

PURPOSE:
    Show how final simulated decision outcomes changed from baseline to challenger.

DENOMINATOR:
    pct_of_matched_population uses the matched application population only.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

matched AS (
    SELECT
        b.application_id,
        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome
    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT
    baseline_decision_outcome,
    challenger_decision_outcome,
    COUNT(*) AS matched_rows,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population
FROM matched
GROUP BY
    baseline_decision_outcome,
    challenger_decision_outcome
ORDER BY
    baseline_decision_outcome,
    challenger_decision_outcome;



/***************************************************************************************************
SECTION 13.7 — MATCHED APPLICANT-LEVEL DELTA SAMPLE
****************************************************************************************************

PURPOSE:
    Show row-level examples of the largest strategy movements.

SORT:
    Largest absolute approved Expected Loss movement, then largest absolute approved amount movement.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

matched AS (
    SELECT
        b.application_id,
        b.applicant_id,
        b.product_type_policy_key,
        b.score_band_policy_key,
        b.requested_amount,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.primary_reason_code AS baseline_primary_reason_code,
        c.primary_reason_code AS challenger_primary_reason_code,

        b.approved_amount AS baseline_approved_amount,
        c.approved_amount AS challenger_approved_amount,
        COALESCE(c.approved_amount, 0) - COALESCE(b.approved_amount, 0)
            AS delta_approved_amount,

        b.approved_payment_to_income_ratio AS baseline_approved_payment_to_income_ratio,
        c.approved_payment_to_income_ratio AS challenger_approved_payment_to_income_ratio,
        c.approved_payment_to_income_ratio - b.approved_payment_to_income_ratio
            AS delta_approved_payment_to_income_ratio,

        b.approved_expected_loss_amount AS baseline_approved_expected_loss_amount,
        c.approved_expected_loss_amount AS challenger_approved_expected_loss_amount,
        COALESCE(c.approved_expected_loss_amount, 0)
          - COALESCE(b.approved_expected_loss_amount, 0)
            AS delta_approved_expected_loss_amount

    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT *
FROM matched
ORDER BY
    ABS(delta_approved_expected_loss_amount) DESC,
    ABS(delta_approved_amount) DESC,
    application_id
LIMIT 50;



/***************************************************************************************************
SECTION 13.8 — PRODUCT × SCORE MATCHED STRATEGY DELTA SUMMARY
****************************************************************************************************

PURPOSE:
    Show where strategy changes concentrate by product and score band.

METRIC CONVENTION:
    approved amount and approved Expected Loss averages use all-application metrics with COALESCE,
    because this segment-level comparison is measuring portfolio impact.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

matched AS (
    SELECT
        b.product_type_policy_key,
        b.score_band_policy_key,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        COALESCE(b.approved_amount, 0) AS baseline_approved_amount_all_app_value,
        COALESCE(c.approved_amount, 0) AS challenger_approved_amount_all_app_value,

        COALESCE(b.approved_expected_loss_amount, 0) AS baseline_approved_el_all_app_value,
        COALESCE(c.approved_expected_loss_amount, 0) AS challenger_approved_el_all_app_value
    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT
    product_type_policy_key,
    score_band_policy_key,

    COUNT(*) AS matched_rows,

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_approval_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_approval_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_approval_rate,

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_counteroffer_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_counteroffer_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_counteroffer_rate,

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_manual_review_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_manual_review_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_manual_review_rate,

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_decline_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_decline_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_decline_rate,

    AVG(baseline_approved_amount_all_app_value) AS baseline_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value) AS challenger_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value)
      - AVG(baseline_approved_amount_all_app_value)
        AS delta_avg_approved_amount_all_apps,

    AVG(baseline_approved_el_all_app_value) AS baseline_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value) AS challenger_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value)
      - AVG(baseline_approved_el_all_app_value)
        AS delta_avg_approved_expected_loss_all_apps

FROM matched
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
SECTION 13.9 — REASON-CODE MOVEMENT SUMMARY
****************************************************************************************************

PURPOSE:
    Show how simulated strategy explanation codes differ between selected archived strategies.

BOUNDARY:
    Reason codes are simulated strategy explanation codes only.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.9A Primary reason distribution by selected strategy.
-----------------------------------------------------------------------------------------------*/
WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

selected_slices AS (
    SELECT
        'BASELINE'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)

SELECT
    comparison_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY comparison_role), 0),
        2
    ) AS pct_of_strategy_population
FROM selected_slices
GROUP BY
    comparison_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    comparison_role,
    decision_outcome,
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
13.9B Matched reason-code migration.

Reason family is included because movement across families is analytically different from movement
within the same family.
-----------------------------------------------------------------------------------------------*/
WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

matched AS (
    SELECT
        b.application_id,

        b.primary_reason_family AS baseline_primary_reason_family,
        b.primary_reason_code AS baseline_primary_reason_code,

        c.primary_reason_family AS challenger_primary_reason_family,
        c.primary_reason_code AS challenger_primary_reason_code
    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code,
    COUNT(*) AS matched_rows,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population
FROM matched
GROUP BY
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code
ORDER BY
    matched_rows DESC,
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code;



/***************************************************************************************************
SECTION 13.10 — SIMULATED OFFER-EXPOSURE COMPARISON
****************************************************************************************************

PURPOSE:
    Compare simulated positive offer-exposure profiles between baseline and challenger.

TERMINOLOGY:
    Use simulated offer exposure, offer rows, and positive offer outcomes.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

selected_slices AS (
    SELECT
        'BASELINE'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS comparison_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)

SELECT
    comparison_role,
    strategy_set_name,
    strategy_name,
    strategy_version,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS positive_offer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
        AS counteroffer_share_of_offers,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
        AS approval_share_of_offers,

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
FROM selected_slices
GROUP BY
    comparison_role,
    strategy_set_name,
    strategy_name,
    strategy_version
ORDER BY comparison_role;



/***************************************************************************************************
SECTION 13.11 — UNMATCHED ROW DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    If comparison readiness is not READY_FOR_MATCHED_COMPARISON, identify baseline-only and
    challenger-only application_id values.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_apps AS (
    SELECT DISTINCT ar.application_id
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_apps AS (
    SELECT DISTINCT ar.application_id
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)

SELECT
    COALESCE(b.application_id, c.application_id) AS application_id,
    CASE
        WHEN b.application_id IS NOT NULL AND c.application_id IS NULL
            THEN 'BASELINE_ONLY'
        WHEN b.application_id IS NULL AND c.application_id IS NOT NULL
            THEN 'CHALLENGER_ONLY'
        ELSE 'MATCHED'
    END AS presence_status
FROM baseline_apps b
FULL OUTER JOIN challenger_apps c
    ON c.application_id = b.application_id
WHERE b.application_id IS NULL
   OR c.application_id IS NULL
ORDER BY
    presence_status,
    application_id
LIMIT 100;



/***************************************************************************************************
SECTION 13.12 — MATCHED MODULE 1 SOURCE-FIELD CONSISTENCY DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    Confirm that matched baseline and challenger strategy slices share the same immutable Module 1
    source fields.

WHY THIS MATTERS:
    Matched Module 2 strategy comparison should isolate downstream strategy effects.

    If Module 1 source fields differ between matched baseline and challenger rows, comparison results
    may reflect population drift, source-selection error, or upstream scenario mismatch rather than
    true downstream strategy movement.

BOUNDARY:
    This diagnostic is read-only.
    It does not mutate archive rows.
    It does not recalculate decisions.
    It does not recalculate simulated reason codes.
    It does not recalculate approved exposure.
    It does not recalculate Expected Loss.
    It does not fail execution solely because placeholder comparison parameters are not ready.

***************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

challenger_slice AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),

baseline_counts AS (
    SELECT
        COUNT(*) AS baseline_archived_row_count,
        COUNT(DISTINCT application_id) AS baseline_distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS baseline_duplicate_application_row_count
    FROM baseline_slice
),

challenger_counts AS (
    SELECT
        COUNT(*) AS challenger_archived_row_count,
        COUNT(DISTINCT application_id) AS challenger_distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS challenger_duplicate_application_row_count
    FROM challenger_slice
),

baseline_apps AS (
    SELECT DISTINCT application_id
    FROM baseline_slice
),

challenger_apps AS (
    SELECT DISTINCT application_id
    FROM challenger_slice
),

application_match AS (
    SELECT
        COUNT(*) FILTER (
            WHERE b.application_id IS NOT NULL
              AND c.application_id IS NOT NULL
        ) AS matched_application_id_count,

        COUNT(*) FILTER (
            WHERE b.application_id IS NOT NULL
              AND c.application_id IS NULL
        ) AS baseline_only_application_id_count,

        COUNT(*) FILTER (
            WHERE b.application_id IS NULL
              AND c.application_id IS NOT NULL
        ) AS challenger_only_application_id_count
    FROM baseline_apps b
    FULL OUTER JOIN challenger_apps c
        ON c.application_id = b.application_id
),

readiness AS (
    SELECT
        CASE
            WHEN p.baseline_strategy_set_name = p.challenger_strategy_set_name
             AND p.baseline_strategy_name = p.challenger_strategy_name
             AND p.baseline_strategy_version = p.challenger_strategy_version
                THEN 'NOT_READY_SAME_STRATEGY_SELECTED'

            WHEN bc.baseline_archived_row_count = 0
                THEN 'NOT_READY_BASELINE_MISSING'

            WHEN cc.challenger_archived_row_count = 0
                THEN 'NOT_READY_CHALLENGER_MISSING'

            WHEN bc.baseline_duplicate_application_row_count > 0
              OR cc.challenger_duplicate_application_row_count > 0
                THEN 'NOT_READY_DUPLICATE_ARCHIVE_GRAIN'

            WHEN bc.baseline_archived_row_count <> cc.challenger_archived_row_count
                THEN 'NOT_READY_ROW_COUNT_MISMATCH'

            WHEN am.baseline_only_application_id_count > 0
              OR am.challenger_only_application_id_count > 0
              OR am.matched_application_id_count <> bc.baseline_distinct_application_id_count
                THEN 'NOT_READY_UNMATCHED_APPLICATIONS'

            ELSE 'READY_FOR_MATCHED_COMPARISON'
        END AS readiness_status
    FROM p
    CROSS JOIN baseline_counts bc
    CROSS JOIN challenger_counts cc
    CROSS JOIN application_match am
),

matched AS (
    SELECT
        b.application_id,

        b.product_type_policy_key AS baseline_product_type_policy_key,
        c.product_type_policy_key AS challenger_product_type_policy_key,

        b.score_band_policy_key AS baseline_score_band_policy_key,
        c.score_band_policy_key AS challenger_score_band_policy_key,

        b.credit_score AS baseline_credit_score,
        c.credit_score AS challenger_credit_score,

        b.annual_income AS baseline_annual_income,
        c.annual_income AS challenger_annual_income,

        b.requested_amount AS baseline_requested_amount,
        c.requested_amount AS challenger_requested_amount,

        b.requested_monthly_payment_proxy AS baseline_requested_monthly_payment_proxy,
        c.requested_monthly_payment_proxy AS challenger_requested_monthly_payment_proxy,

        b.requested_payment_to_income_ratio AS baseline_requested_payment_to_income_ratio,
        c.requested_payment_to_income_ratio AS challenger_requested_payment_to_income_ratio,

        b.amount_to_income_ratio AS baseline_amount_to_income_ratio,
        c.amount_to_income_ratio AS challenger_amount_to_income_ratio,

        b.estimated_pd AS baseline_estimated_pd,
        c.estimated_pd AS challenger_estimated_pd,

        b.estimated_lgd AS baseline_estimated_lgd,
        c.estimated_lgd AS challenger_estimated_lgd,

        b.requested_expected_loss_amount AS baseline_requested_expected_loss_amount,
        c.requested_expected_loss_amount AS challenger_requested_expected_loss_amount,

        b.module1_scenario_set_name AS baseline_module1_scenario_set_name,
        c.module1_scenario_set_name AS challenger_module1_scenario_set_name,

        b.module1_scenario_name AS baseline_module1_scenario_name,
        c.module1_scenario_name AS challenger_module1_scenario_name,

        b.population_id AS baseline_population_id,
        c.population_id AS challenger_population_id

    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
),

source_counts AS (
    SELECT
        COUNT(*) AS matched_application_count,

        COUNT(*) FILTER (
            WHERE baseline_product_type_policy_key IS DISTINCT FROM challenger_product_type_policy_key
               OR baseline_score_band_policy_key IS DISTINCT FROM challenger_score_band_policy_key
               OR baseline_credit_score IS DISTINCT FROM challenger_credit_score
               OR baseline_annual_income IS DISTINCT FROM challenger_annual_income
               OR baseline_requested_amount IS DISTINCT FROM challenger_requested_amount
               OR baseline_requested_monthly_payment_proxy IS DISTINCT FROM challenger_requested_monthly_payment_proxy
               OR baseline_requested_payment_to_income_ratio IS DISTINCT FROM challenger_requested_payment_to_income_ratio
               OR baseline_amount_to_income_ratio IS DISTINCT FROM challenger_amount_to_income_ratio
               OR baseline_estimated_pd IS DISTINCT FROM challenger_estimated_pd
               OR baseline_estimated_lgd IS DISTINCT FROM challenger_estimated_lgd
               OR baseline_requested_expected_loss_amount IS DISTINCT FROM challenger_requested_expected_loss_amount
               OR baseline_module1_scenario_set_name IS DISTINCT FROM challenger_module1_scenario_set_name
               OR baseline_module1_scenario_name IS DISTINCT FROM challenger_module1_scenario_name
               OR baseline_population_id IS DISTINCT FROM challenger_population_id
        ) AS source_field_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_product_type_policy_key IS DISTINCT FROM challenger_product_type_policy_key
        ) AS product_type_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_score_band_policy_key IS DISTINCT FROM challenger_score_band_policy_key
        ) AS score_band_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_credit_score IS DISTINCT FROM challenger_credit_score
        ) AS credit_score_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_annual_income IS DISTINCT FROM challenger_annual_income
        ) AS annual_income_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_amount IS DISTINCT FROM challenger_requested_amount
        ) AS requested_amount_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_monthly_payment_proxy IS DISTINCT FROM challenger_requested_monthly_payment_proxy
        ) AS requested_payment_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_payment_to_income_ratio IS DISTINCT FROM challenger_requested_payment_to_income_ratio
        ) AS requested_pti_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_amount_to_income_ratio IS DISTINCT FROM challenger_amount_to_income_ratio
        ) AS amount_to_income_ratio_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_estimated_pd IS DISTINCT FROM challenger_estimated_pd
        ) AS estimated_pd_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_estimated_lgd IS DISTINCT FROM challenger_estimated_lgd
        ) AS estimated_lgd_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_expected_loss_amount IS DISTINCT FROM challenger_requested_expected_loss_amount
        ) AS requested_expected_loss_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_module1_scenario_set_name IS DISTINCT FROM challenger_module1_scenario_set_name
               OR baseline_module1_scenario_name IS DISTINCT FROM challenger_module1_scenario_name
               OR baseline_population_id IS DISTINCT FROM challenger_population_id
        ) AS module1_lineage_mismatch_count
    FROM matched
)

SELECT
    sc.matched_application_count,
    sc.source_field_mismatch_count,
    sc.product_type_mismatch_count,
    sc.score_band_mismatch_count,
    sc.credit_score_mismatch_count,
    sc.annual_income_mismatch_count,
    sc.requested_amount_mismatch_count,
    sc.requested_payment_mismatch_count,
    sc.requested_pti_mismatch_count,
    sc.amount_to_income_ratio_mismatch_count,
    sc.estimated_pd_mismatch_count,
    sc.estimated_lgd_mismatch_count,
    sc.requested_expected_loss_mismatch_count,
    sc.module1_lineage_mismatch_count,

    CASE
        WHEN r.readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN sc.source_field_mismatch_count = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status
FROM readiness r
CROSS JOIN source_counts sc;



/***************************************************************************************************
END OF SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK

If execution reaches this point:
    1. Archive inventory queries are available.
    2. tmp_m2_strategy_comparison_params exists.
    3. Baseline and challenger readiness can be reviewed.
    4. Same-strategy comparison is explicitly flagged as not ready for V1.0 strategy delta comparison.
    5. Portfolio-level archived strategy summaries can be reviewed.
    6. Baseline versus challenger portfolio deltas can be reviewed.
    7. Decision migration can be reviewed.
    8. Matched applicant-level delta samples can be reviewed.
    9. Product × score matched strategy deltas can be reviewed.
    10. Reason-code distributions and migrations can be reviewed using both reason family and reason code.
    11. Simulated offer-exposure profiles can be compared.
    12. Unmatched row diagnostics can be reviewed.
    13. Matched immutable Module 1 source-field consistency can be reviewed.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No decision outcomes have been recalculated.
No simulated reason codes have been recalculated.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No full Module 2 QA framework has been created.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/



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
    5. Produce a compact temporary validation status summary.
    6. Preserve a strictly read-only QA boundary for permanent Module 2 outputs.

READ-ONLY BOUNDARY:
    Section 14 does not insert, delete, update, or modify latest-run output rows.
    Section 14 does not insert, delete, update, or modify archive rows.
    Section 14 does not recalculate decision_outcome.
    Section 14 does not reassign simulated reason codes.
    Section 14 does not recalculate approved exposure.
    Section 14 does not recalculate approved Expected Loss.
    Section 14 does not modify strategy parameters.
    Section 14 does not modify product policy parameters.

TEMPORARY VALIDATION SUMMARY NOTE:
    tmp_m2_validation_status_summary is a temporary validation evidence table.

    It does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive

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
        product behavior,
        score-band behavior,
        synthetic estimated-risk tier behavior,
        requested PTI behavior,
        DTI behavior,
        requested versus approved exposure,
        counteroffer feasibility,
        manual-review unresolved population,
        simulated policy-stop behavior,
        simulated reason-code coverage,
        simulated offer exposure,
        mixed-signal and borderline cases.

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
    all-app approved metrics use COALESCE to treat unresolved manual-review approved exposure as zero
    for portfolio impact.
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
    Module 2 V1.0.

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
    Declines should be explainable through simulated policy-stop, severe synthetic risk, severe DTI,
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
    Use simulated offer exposure, not operational exposure terminology.

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
SECTION 14.18 — COMPACT VALIDATION STATUS SUMMARY
****************************************************************************************************

PURPOSE:
    Create a compact temporary validation status summary for the completed latest-run Module 2 output.

TABLE:
    tmp_m2_validation_status_summary

FIELDS:
    validation_area
    validation_test_name
    validation_category
    validation_status
    observed_value
    expected_behavior
    interpretation

STATUS VALUES:
    PASS:
        Structural or convention expectations are satisfied.

    REVIEW:
        Diagnostic pattern may be acceptable but should be interpreted.

    NOT_APPLICABLE:
        Test depends on unavailable archive slices, unavailable comparison parameters, or non-ready
        matched comparison setup.

NO FAIL STATUS:
    Critical structural failures are handled by fail-fast gatekeepers in prior sections.

BOUNDARY:
    This temporary summary table does not modify latest-run output or archive output.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

CREATE TEMP TABLE tmp_m2_validation_status_summary
ON COMMIT PRESERVE ROWS
AS
WITH latest_structural AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_row_count,
        COUNT(DISTINCT (strategy_set_name, strategy_name, strategy_version)) AS strategy_version_count,
        COUNT(DISTINCT (module1_scenario_set_name, module1_scenario_name, population_id))
            AS module1_scenario_population_count
    FROM credit_decisioning_sim.strategy_decisions
),

decision_conventions AS (
    SELECT
        COUNT(*) AS total_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome IS NULL
               OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
        ) AS invalid_decision_outcome_rows,

        COUNT(*) FILTER (
            WHERE (
                COALESCE(approval_flag::INT, 0)
                + COALESCE(counteroffer_flag::INT, 0)
                + COALESCE(manual_review_flag::INT, 0)
                + COALESCE(decline_flag::INT, 0)
            ) <> 1
        ) AS final_flag_count_violation_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND approved_amount IS DISTINCT FROM requested_amount
            )
            OR (
                    decision_outcome = 'COUNTEROFFER'
                AND (
                        approved_amount IS NULL
                     OR approved_amount >= requested_amount
                    )
            )
            OR (
                    decision_outcome = 'MANUAL_REVIEW'
                AND approved_amount IS NOT NULL
            )
            OR (
                    decision_outcome = 'DECLINE'
                AND approved_amount IS DISTINCT FROM 0::NUMERIC
            )
        ) AS approved_amount_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE (
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
            )
        ) AS approved_el_convention_violation_rows
    FROM credit_decisioning_sim.strategy_decisions
),

reason_conventions AS (
    SELECT
        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
               OR triggered_reason_code_list IS NULL
        ) AS reason_code_completeness_violation_rows,

        COUNT(*) FILTER (
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
            )
        ) AS reason_family_alignment_violation_rows,

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
        ) AS prohibited_terminology_rows
    FROM credit_decisioning_sim.strategy_decisions
),

product_diag AS (
    SELECT
        COUNT(DISTINCT product_type_policy_key) AS product_count,
        MAX(product_decision_share) AS max_product_decision_share
    FROM (
        SELECT
            product_type_policy_key,
            decision_outcome,
            COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY product_type_policy_key), 0)
                AS product_decision_share
        FROM credit_decisioning_sim.strategy_decisions
        GROUP BY
            product_type_policy_key,
            decision_outcome
    ) x
),

score_diag AS (
    SELECT
        COUNT(DISTINCT score_band_policy_key) AS score_band_count,
        MAX(score_decision_share) AS max_score_decision_share
    FROM (
        SELECT
            score_band_policy_key,
            decision_outcome,
            COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY score_band_policy_key), 0)
                AS score_decision_share
        FROM credit_decisioning_sim.strategy_decisions
        GROUP BY
            score_band_policy_key,
            decision_outcome
    ) x
),

risk_ordering AS (
    SELECT
        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_decline_rows,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_rows,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_rows
    FROM credit_decisioning_sim.strategy_decisions
),

affordability_diag AS (
    SELECT
        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
        ) AS high_requested_pti_rows,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS low_requested_pti_rows,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
            ),
            0
        ) AS high_requested_pti_approval_rate,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
            ),
            0
        ) AS low_requested_pti_approval_rate
    FROM credit_decisioning_sim.strategy_decisions
),

counteroffer_diag AS (
    SELECT
        COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER') AS preliminary_counteroffer_rows,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS final_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    approved_amount IS NULL
                 OR approved_amount >= requested_amount
                 OR approved_payment_to_income_ratio > counteroffer_target_pti
                 OR approved_expected_loss_amount > product_approved_el_cap
              )
        ) AS final_counteroffer_convention_violation_rows
    FROM credit_decisioning_sim.strategy_decisions
),

manual_review_diag AS (
    SELECT
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND (
                    approved_amount IS NOT NULL
                 OR approved_payment_to_income_ratio IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
              )
        ) AS manual_review_unresolved_convention_violation_rows
    FROM credit_decisioning_sim.strategy_decisions
),

decline_diag AS (
    SELECT
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
              )
        ) AS decline_zero_exposure_convention_violation_rows
    FROM credit_decisioning_sim.strategy_decisions
),

mixed_signal_diag AS (
    SELECT
        COUNT(*) FILTER (WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE')
            AS mixed_signal_rows,

        COUNT(*) FILTER (WHERE borderline_profile_flag IS TRUE)
            AS borderline_rows,

        COUNT(*) FILTER (
            WHERE decision_path IN (
                'RESIDUAL_STRATEGY_REVIEW',
                'FINAL_RESIDUAL_STRATEGY_REVIEW'
            )
        ) AS residual_review_rows
    FROM credit_decisioning_sim.strategy_decisions
),

archive_diag AS (
    SELECT
        lc.archive_run_flag,
        lc.strategy_archive_reset_mode,
        lc.latest_run_row_count,
        COUNT(ar.*) AS current_archived_slice_row_count,
        COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count
    FROM (
        SELECT
            archive_run_flag,
            strategy_archive_reset_mode,
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id,
            COUNT(*) AS latest_run_row_count
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
    ) lc
    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
        ON ar.strategy_set_name = lc.strategy_set_name
       AND ar.strategy_name = lc.strategy_name
       AND ar.strategy_version = lc.strategy_version
       AND ar.module1_scenario_set_name = lc.module1_scenario_set_name
       AND ar.module1_scenario_name = lc.module1_scenario_name
       AND ar.population_id = lc.population_id
    GROUP BY
        lc.archive_run_flag,
        lc.strategy_archive_reset_mode,
        lc.latest_run_row_count
),

comparison_params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

comparison_readiness AS (
    WITH p AS (
        SELECT *
        FROM comparison_params
    ),
    baseline_slice AS (
        SELECT ar.*
        FROM credit_decisioning_sim.strategy_decisions_archive ar
        JOIN p
            ON ar.strategy_set_name = p.baseline_strategy_set_name
           AND ar.strategy_name = p.baseline_strategy_name
           AND ar.strategy_version = p.baseline_strategy_version
           AND ar.module1_scenario_set_name = p.module1_scenario_set_name
           AND ar.module1_scenario_name = p.module1_scenario_name
           AND ar.population_id = p.population_id
    ),
    challenger_slice AS (
        SELECT ar.*
        FROM credit_decisioning_sim.strategy_decisions_archive ar
        JOIN p
            ON ar.strategy_set_name = p.challenger_strategy_set_name
           AND ar.strategy_name = p.challenger_strategy_name
           AND ar.strategy_version = p.challenger_strategy_version
           AND ar.module1_scenario_set_name = p.module1_scenario_set_name
           AND ar.module1_scenario_name = p.module1_scenario_name
           AND ar.population_id = p.population_id
    ),
    baseline_counts AS (
        SELECT
            COUNT(*) AS baseline_archived_row_count,
            COUNT(DISTINCT application_id) AS baseline_distinct_application_id_count,
            COUNT(*) - COUNT(DISTINCT application_id) AS baseline_duplicate_application_row_count
        FROM baseline_slice
    ),
    challenger_counts AS (
        SELECT
            COUNT(*) AS challenger_archived_row_count,
            COUNT(DISTINCT application_id) AS challenger_distinct_application_id_count,
            COUNT(*) - COUNT(DISTINCT application_id) AS challenger_duplicate_application_row_count
        FROM challenger_slice
    ),
    baseline_apps AS (
        SELECT DISTINCT application_id FROM baseline_slice
    ),
    challenger_apps AS (
        SELECT DISTINCT application_id FROM challenger_slice
    ),
    application_match AS (
        SELECT
            COUNT(*) FILTER (
                WHERE b.application_id IS NOT NULL
                  AND c.application_id IS NOT NULL
            ) AS matched_application_id_count,

            COUNT(*) FILTER (
                WHERE b.application_id IS NOT NULL
                  AND c.application_id IS NULL
            ) AS baseline_only_application_id_count,

            COUNT(*) FILTER (
                WHERE b.application_id IS NULL
                  AND c.application_id IS NOT NULL
            ) AS challenger_only_application_id_count
        FROM baseline_apps b
        FULL OUTER JOIN challenger_apps c
            ON c.application_id = b.application_id
    )
    SELECT
        CASE
            WHEN p.baseline_strategy_set_name = p.challenger_strategy_set_name
             AND p.baseline_strategy_name = p.challenger_strategy_name
             AND p.baseline_strategy_version = p.challenger_strategy_version
                THEN 'NOT_READY_SAME_STRATEGY_SELECTED'

            WHEN bc.baseline_archived_row_count = 0
                THEN 'NOT_READY_BASELINE_MISSING'

            WHEN cc.challenger_archived_row_count = 0
                THEN 'NOT_READY_CHALLENGER_MISSING'

            WHEN bc.baseline_duplicate_application_row_count > 0
              OR cc.challenger_duplicate_application_row_count > 0
                THEN 'NOT_READY_DUPLICATE_ARCHIVE_GRAIN'

            WHEN bc.baseline_archived_row_count <> cc.challenger_archived_row_count
                THEN 'NOT_READY_ROW_COUNT_MISMATCH'

            WHEN am.baseline_only_application_id_count > 0
              OR am.challenger_only_application_id_count > 0
              OR am.matched_application_id_count <> bc.baseline_distinct_application_id_count
                THEN 'NOT_READY_UNMATCHED_APPLICATIONS'

            ELSE 'READY_FOR_MATCHED_COMPARISON'
        END AS readiness_status
    FROM p
    CROSS JOIN baseline_counts bc
    CROSS JOIN challenger_counts cc
    CROSS JOIN application_match am
),

matched_source_consistency AS (
    WITH p AS (
        SELECT *
        FROM comparison_params
    ),
    r AS (
        SELECT *
        FROM comparison_readiness
    ),
    baseline_slice AS (
        SELECT ar.*
        FROM credit_decisioning_sim.strategy_decisions_archive ar
        JOIN p
            ON ar.strategy_set_name = p.baseline_strategy_set_name
           AND ar.strategy_name = p.baseline_strategy_name
           AND ar.strategy_version = p.baseline_strategy_version
           AND ar.module1_scenario_set_name = p.module1_scenario_set_name
           AND ar.module1_scenario_name = p.module1_scenario_name
           AND ar.population_id = p.population_id
    ),
    challenger_slice AS (
        SELECT ar.*
        FROM credit_decisioning_sim.strategy_decisions_archive ar
        JOIN p
            ON ar.strategy_set_name = p.challenger_strategy_set_name
           AND ar.strategy_name = p.challenger_strategy_name
           AND ar.strategy_version = p.challenger_strategy_version
           AND ar.module1_scenario_set_name = p.module1_scenario_set_name
           AND ar.module1_scenario_name = p.module1_scenario_name
           AND ar.population_id = p.population_id
    ),
    matched AS (
        SELECT
            b.application_id,

            (
                b.product_type_policy_key IS DISTINCT FROM c.product_type_policy_key
             OR b.score_band_policy_key IS DISTINCT FROM c.score_band_policy_key
             OR b.credit_score IS DISTINCT FROM c.credit_score
             OR b.annual_income IS DISTINCT FROM c.annual_income
             OR b.requested_amount IS DISTINCT FROM c.requested_amount
             OR b.requested_monthly_payment_proxy IS DISTINCT FROM c.requested_monthly_payment_proxy
             OR b.requested_payment_to_income_ratio IS DISTINCT FROM c.requested_payment_to_income_ratio
             OR b.amount_to_income_ratio IS DISTINCT FROM c.amount_to_income_ratio
             OR b.estimated_pd IS DISTINCT FROM c.estimated_pd
             OR b.estimated_lgd IS DISTINCT FROM c.estimated_lgd
             OR b.requested_expected_loss_amount IS DISTINCT FROM c.requested_expected_loss_amount
             OR b.module1_scenario_set_name IS DISTINCT FROM c.module1_scenario_set_name
             OR b.module1_scenario_name IS DISTINCT FROM c.module1_scenario_name
             OR b.population_id IS DISTINCT FROM c.population_id
            ) AS source_field_mismatch_flag
        FROM baseline_slice b
        JOIN challenger_slice c
            ON c.module1_scenario_set_name = b.module1_scenario_set_name
           AND c.module1_scenario_name = b.module1_scenario_name
           AND c.population_id = b.population_id
           AND c.application_id = b.application_id
    )
    SELECT
        CASE
            WHEN (SELECT readiness_status FROM r) <> 'READY_FOR_MATCHED_COMPARISON'
                THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

            WHEN COUNT(*) FILTER (WHERE source_field_mismatch_flag IS TRUE) = 0
                THEN 'SOURCE_FIELDS_MATCH'

            ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
        END AS source_consistency_status,

        COUNT(*) AS matched_application_count,

        COUNT(*) FILTER (WHERE source_field_mismatch_flag IS TRUE)
            AS source_field_mismatch_count
    FROM matched
),

validation_rows AS (
    SELECT
        'Latest-run structural integrity'::TEXT AS validation_area,
        'row_count_application_id_strategy_lineage_integrity'::TEXT AS validation_test_name,
        'STRUCTURAL'::TEXT AS validation_category,
        CASE
            WHEN total_rows > 0
             AND duplicate_application_row_count = 0
             AND strategy_version_count = 1
             AND module1_scenario_population_count = 1
                THEN 'PASS'
            ELSE 'REVIEW'
        END AS validation_status,
        FORMAT(
            'rows=%s; distinct_application_id=%s; duplicate_application_rows=%s; strategy_version_count=%s; module1_scenario_population_count=%s',
            total_rows,
            distinct_application_id_count,
            duplicate_application_row_count,
            strategy_version_count,
            module1_scenario_population_count
        ) AS observed_value,
        'Latest-run output should be populated, unique by application_id, and scoped to one strategy and one Module 1 scenario / population.'::TEXT
            AS expected_behavior,
        'Structural integrity confirms that the latest-run strategy output is suitable for downstream QA review.'::TEXT
            AS interpretation
    FROM latest_structural

    UNION ALL

    SELECT
        'Decision outcome completeness',
        'decision_outcome_populated_and_valid',
        'STRUCTURAL',
        CASE
            WHEN invalid_decision_outcome_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('invalid_decision_outcome_rows=%s', invalid_decision_outcome_rows),
        'Every row should have one valid final decision_outcome in APPROVE, COUNTEROFFER, MANUAL_REVIEW, DECLINE.',
        'Decision completeness confirms that the final resolution layer assigned a valid simulated strategy outcome.'
    FROM decision_conventions

    UNION ALL

    SELECT
        'Final flag reconciliation',
        'exactly_one_final_flag_true_per_row',
        'STRUCTURAL',
        CASE
            WHEN final_flag_count_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('final_flag_count_violation_rows=%s', final_flag_count_violation_rows),
        'Exactly one of approval_flag, counteroffer_flag, manual_review_flag, and decline_flag should be TRUE per row.',
        'Final flags should reconcile directly to decision_outcome.'
    FROM decision_conventions

    UNION ALL

    SELECT
        'Simulated offer-exposure convention',
        'offer_exposure_flag_alignment',
        'STRUCTURAL',
        CASE
            WHEN simulated_offer_exposure_flag_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('simulated_offer_exposure_flag_violation_rows=%s', simulated_offer_exposure_flag_violation_rows),
        'simulated_offer_exposure_flag should be TRUE only for APPROVE and COUNTEROFFER.',
        'This validates the simulated positive offer-exposure boundary without implying operational exposure.'
    FROM decision_conventions

    UNION ALL

    SELECT
        'Approved amount convention',
        'approved_amount_by_decision_outcome',
        'STRUCTURAL',
        CASE
            WHEN approved_amount_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('approved_amount_convention_violation_rows=%s', approved_amount_convention_violation_rows),
        'APPROVE equals requested amount; COUNTEROFFER is below requested amount; MANUAL_REVIEW is NULL; DECLINE is zero.',
        'Approved amount conventions confirm that exposure treatment is internally consistent.'
    FROM decision_conventions

    UNION ALL

    SELECT
        'Approved Expected Loss convention',
        'approved_expected_loss_by_decision_outcome',
        'STRUCTURAL',
        CASE
            WHEN approved_el_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('approved_el_convention_violation_rows=%s', approved_el_convention_violation_rows),
        'Approved Expected Loss should follow approved-exposure conventions by decision outcome.',
        'This validates the distinction between requested-exposure and approved-exposure Expected Loss.'
    FROM decision_conventions

    UNION ALL

    SELECT
        'Reason-code completeness',
        'primary_reason_code_and_triggered_list_populated',
        'STRUCTURAL',
        CASE
            WHEN reason_code_completeness_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('reason_code_completeness_violation_rows=%s', reason_code_completeness_violation_rows),
        'Every row should have primary reason fields and at least one triggered simulated reason code.',
        'Every simulated strategy outcome should be explainable.'
    FROM reason_conventions

    UNION ALL

    SELECT
        'Reason-code family alignment',
        'primary_reason_family_aligns_to_decision_outcome',
        'STRUCTURAL',
        CASE
            WHEN reason_family_alignment_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('reason_family_alignment_violation_rows=%s', reason_family_alignment_violation_rows),
        'APPROVE uses APPROVAL; COUNTEROFFER uses COUNTEROFFER; MANUAL_REVIEW uses MANUAL_REVIEW; DECLINE uses POLICY_STOP.',
        'Reason-code family alignment prevents explanation-family leakage.'
    FROM reason_conventions

    UNION ALL

    SELECT
        'Prohibited terminology check',
        'reason_code_boundary_terms_absent',
        'STRUCTURAL',
        CASE
            WHEN prohibited_terminology_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('prohibited_terminology_rows=%s', prohibited_terminology_rows),
        'Reason-code strings should not include prohibited regulatory, customer communication, or fair-lending terminology.',
        'Reason codes remain simulated strategy explanation codes.'
    FROM reason_conventions

    UNION ALL

    SELECT
        'Product-level strategy distribution',
        'product_decision_distribution_review',
        'DIAGNOSTIC',
        CASE
            WHEN product_count = 0 THEN 'REVIEW'
            WHEN max_product_decision_share > 0.900000 THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'product_count=%s; max_product_decision_share=%s',
            product_count,
            COALESCE(max_product_decision_share::TEXT, '<NULL>')
        ),
        'Product-level decision distributions should be reviewed for extreme concentration or unexpected product behavior.',
        'Product-level outcomes should reflect product-specific policy parameters and structure.'
    FROM product_diag

    UNION ALL

    SELECT
        'Score-band strategy distribution',
        'score_band_decision_distribution_review',
        'DIAGNOSTIC',
        CASE
            WHEN score_band_count = 0 THEN 'REVIEW'
            WHEN max_score_decision_share > 0.900000 THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'score_band_count=%s; max_score_decision_share=%s',
            score_band_count,
            COALESCE(max_score_decision_share::TEXT, '<NULL>')
        ),
        'Score-band decision distributions should be reviewed for directional risk ordering and excessive concentration.',
        'Stronger score bands should generally show higher positive offer outcomes than weaker score bands, with realistic overlap.'
    FROM score_diag

    UNION ALL

    SELECT
        'Synthetic risk ordering',
        'offered_vs_declined_synthetic_estimated_pd_proxy',
        'DIAGNOSTIC',
        CASE
            WHEN offer_rows = 0 OR decline_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN avg_synthetic_estimated_pd_proxy_offer_rows <= avg_synthetic_estimated_pd_proxy_decline_rows THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'offer_rows=%s; decline_rows=%s; avg_offer_synthetic_estimated_pd_proxy=%s; avg_decline_synthetic_estimated_pd_proxy=%s',
            offer_rows,
            decline_rows,
            COALESCE(avg_synthetic_estimated_pd_proxy_offer_rows::TEXT, '<NULL>'),
            COALESCE(avg_synthetic_estimated_pd_proxy_decline_rows::TEXT, '<NULL>')
        ),
        'Offered rows should generally have lower synthetic estimated-PD proxy than declined rows.',
        'This validates broad risk ordering without requiring perfect monotonicity at every segment.'
    FROM risk_ordering

    UNION ALL

    SELECT
        'Affordability sensitivity',
        'high_requested_pti_vs_low_requested_pti_approval_rate',
        'DIAGNOSTIC',
        CASE
            WHEN high_requested_pti_rows = 0 OR low_requested_pti_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN high_requested_pti_approval_rate <= low_requested_pti_approval_rate THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'high_requested_pti_rows=%s; low_requested_pti_rows=%s; high_requested_pti_approval_rate=%s; low_requested_pti_approval_rate=%s',
            high_requested_pti_rows,
            low_requested_pti_rows,
            COALESCE(high_requested_pti_approval_rate::TEXT, '<NULL>'),
            COALESCE(low_requested_pti_approval_rate::TEXT, '<NULL>')
        ),
        'Higher requested PTI should generally reduce clean approval likelihood or increase counteroffer / review / decline outcomes.',
        'Affordability sensitivity confirms that requested-structure burden affects strategy outcomes.'
    FROM affordability_diag

    UNION ALL

    SELECT
        'Counteroffer diagnostics',
        'counteroffer_feasibility_and_final_conventions',
        'DIAGNOSTIC',
        CASE
            WHEN preliminary_counteroffer_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN final_counteroffer_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'preliminary_counteroffer_rows=%s; final_counteroffer_rows=%s; final_counteroffer_convention_violation_rows=%s',
            preliminary_counteroffer_rows,
            final_counteroffer_rows,
            final_counteroffer_convention_violation_rows
        ),
        'Final COUNTEROFFER rows should be feasible, below requested amount, and within approved PTI / approved Expected Loss constraints.',
        'Counteroffer diagnostics confirm that reduced-exposure treatment is structurally feasible and explainable.'
    FROM counteroffer_diag

    UNION ALL

    SELECT
        'Manual-review diagnostics',
        'manual_review_unresolved_convention',
        'DIAGNOSTIC',
        CASE
            WHEN manual_review_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN manual_review_unresolved_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'manual_review_rows=%s; manual_review_unresolved_convention_violation_rows=%s',
            manual_review_rows,
            manual_review_unresolved_convention_violation_rows
        ),
        'MANUAL_REVIEW rows should remain unresolved with NULL approved exposure and approved economics.',
        'Manual review should concentrate in unresolved, mixed-signal, borderline, or failed-counteroffer cases.'
    FROM manual_review_diag

    UNION ALL

    SELECT
        'Decline / policy-stop diagnostics',
        'decline_zero_exposure_convention',
        'DIAGNOSTIC',
        CASE
            WHEN decline_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN decline_zero_exposure_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'decline_rows=%s; decline_zero_exposure_convention_violation_rows=%s',
            decline_rows,
            decline_zero_exposure_convention_violation_rows
        ),
        'DECLINE rows should have approved_amount = 0 and approved_expected_loss_amount = 0.',
        'Declines should be explainable through simulated policy-stop or no-offer paths.'
    FROM decline_diag

    UNION ALL

    SELECT
        'Mixed-signal and edge-case diagnostics',
        'mixed_signal_borderline_residual_review',
        'DIAGNOSTIC',
        CASE
            WHEN mixed_signal_rows = 0 AND borderline_rows = 0 AND residual_review_rows = 0 THEN 'NOT_APPLICABLE'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'mixed_signal_rows=%s; borderline_rows=%s; residual_review_rows=%s',
            mixed_signal_rows,
            borderline_rows,
            residual_review_rows
        ),
        'Mixed-signal, borderline, and residual-review populations should be inspected for explainability.',
        'Realistic edge cases should remain visible and traceable through staged strategy logic.'
    FROM mixed_signal_diag

    UNION ALL

    SELECT
        'Archive persistence readiness',
        'latest_run_archive_slice_alignment',
        'DIAGNOSTIC',
        CASE
            WHEN archive_run_flag IS FALSE THEN 'NOT_APPLICABLE'
            WHEN current_archived_slice_row_count = latest_run_row_count
             AND current_archived_slice_distinct_application_id_count = latest_run_row_count
                THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'archive_run_flag=%s; archive_mode=%s; latest_rows=%s; archived_slice_rows=%s; archived_slice_distinct_application_id=%s',
            archive_run_flag,
            strategy_archive_reset_mode,
            latest_run_row_count,
            current_archived_slice_row_count,
            current_archived_slice_distinct_application_id_count
        ),
        'When archive_run_flag is TRUE, the current archived slice should match latest-run row count and application_id count.',
        'Archive readiness supports later matched strategy comparison.'
    FROM archive_diag

    UNION ALL

    SELECT
        'Matched strategy comparison readiness',
        'section13_comparison_readiness_status',
        'DIAGNOSTIC',
        CASE
            WHEN readiness_status = 'READY_FOR_MATCHED_COMPARISON' THEN 'PASS'
            ELSE 'NOT_APPLICABLE'
        END,
        FORMAT('readiness_status=%s', readiness_status),
        'Matched strategy comparison requires two archived strategy slices under the same Module 1 scenario and population.',
        'When not ready, Section 13 inventory and readiness diagnostics should be reviewed before interpreting strategy deltas.'
    FROM comparison_readiness

    UNION ALL

    SELECT
        'Matched source-field consistency',
        'matched_module1_source_fields_consistency',
        'DIAGNOSTIC',
        CASE
            WHEN source_consistency_status = 'SOURCE_FIELDS_MATCH' THEN 'PASS'
            WHEN source_consistency_status = 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED' THEN 'REVIEW'
            ELSE 'NOT_APPLICABLE'
        END,
        FORMAT(
            'source_consistency_status=%s; matched_application_count=%s; source_field_mismatch_count=%s',
            source_consistency_status,
            matched_application_count,
            source_field_mismatch_count
        ),
        'Matched baseline and challenger rows should share immutable Module 1 source fields.',
        'Source-field consistency confirms that matched strategy comparison isolates downstream Module 2 strategy effects.'
    FROM matched_source_consistency
)

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation
FROM validation_rows;


/* Display final compact validation status summary. */
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


/* Validation status distribution. */
SELECT
    validation_status,
    COUNT(*) AS validation_test_count
FROM tmp_m2_validation_status_summary
GROUP BY validation_status
ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        WHEN 'PASS' THEN 3
        ELSE 99
    END;



/***************************************************************************************************
END OF SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS

If execution reaches this point:
    1. Latest-run structural integrity can be reviewed.
    2. Final decision distribution can be reviewed.
    3. Product, score, product × score, risk-tier, requested PTI, and DTI behavior can be reviewed.
    4. Requested versus approved exposure and economics can be reviewed.
    5. Counteroffer behavior can be validated.
    6. Manual-review unresolved behavior can be validated.
    7. Decline / simulated policy-stop behavior can be validated.
    8. Simulated reason-code coverage and family alignment can be validated.
    9. Simulated offer-exposure profile can be reviewed.
    10. Edge cases and mixed-signal profiles can be inspected.
    11. Final output conventions can be tested through diagnostic failure counts.
    12. Archive and comparison readiness can be reviewed.
    13. Matched source-field consistency can be reviewed.
    14. tmp_m2_validation_status_summary is available as a compact validation status output.

No latest-run output rows have been modified.
No archive rows have been modified.
No strategy parameter rows have been modified.
No product policy parameter rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been reassigned.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 7 OF 7 END
```
<!-- END_MESSAGE C038-M00223 -->


---

<a id="c038-m00224"></a>

### C038-M00224

**Andrew** · 2026-05-06T18:09:29.846000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00224 -->
CONTINUE FULL CODE PART 7 (Previously you provided up through SECTION 12 in Parts 1-6)
<!-- END_MESSAGE C038-M00224 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_14.md) · [Next](Part_16.md)
