# Module 2 Decision Simulator Build

## Part 17

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_16.md) · [Next](Part_18.md)

<a id="c038-m00229"></a>

### C038-M00229

**ChatGPT** · 2026-05-06T18:37:46.219611-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00229 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 7A OF 7F START

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

    It does not imply operational account creation, funding, operational approval, or real applicant
    treatment.

WHY REASON-CODE MIGRATION SUPPORTS EXPLAINABILITY:
    Numeric deltas explain how much strategy behavior changed.
    Reason-code movement explains why strategy behavior changed.

SECTION 13 IS NOT THE FULL QA FRAMEWORK:
    Section 13 compares archived strategy slices.
    Section 14 validates the latest-run output.

***************************************************************************************************/



/***************************************************************************************************
SECTION 13.0 — COMPARISON PARAMETER SETUP
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

WHY MODULE 2 STRATEGY METADATA IS NOT MODULE 1 SCENARIO METADATA:
    strategy_set_name, strategy_name, and strategy_version identify the downstream simulated strategy.
    module1_scenario_set_name, module1_scenario_name, and population_id identify the upstream
    Module 1 source population and risk environment.

    Section 13 uses both sets of identifiers because matched strategy comparison must preserve
    upstream lineage while comparing downstream strategy behavior.

WHY THE DEFAULT CHALLENGER IS A PLACEHOLDER:
    The default comparison parameter row is intended to make the script executable after a single
    archived strategy run. If no challenger has been archived yet, the readiness query will report
    that comparison is not ready rather than mutating archive data or failing ordinary inventory
    review.

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


/*
Diagnostic display of current comparison parameter selection.

This is a read-only review query against the temporary comparison parameter table.
It does not imply that matched comparison is ready.
*/
SELECT
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
FROM tmp_m2_strategy_comparison_params;



/***************************************************************************************************
SECTION 13.1 — ARCHIVE INVENTORY
****************************************************************************************************

PURPOSE:
    Show what archived Module 2 strategy runs are available.

INTERPRETATION:
    This is the first query users should review before selecting baseline and challenger strategies.

WHY ARCHIVE INVENTORY IS READ-ONLY:
    Inventory should help users understand what exists in the archive.
    It should not change archive contents, recalculate strategy outcomes, or alter prior run history.

WHY TIMESTAMP FIELDS ARE INCLUDED BUT NOT USED AS COMPARISON KEYS:
    latest_output_created_ts and archive_inserted_ts support audit traceability.

    They should not be used as deterministic comparison keys because they can vary across reruns even
    when the business strategy output is otherwise reproducible.

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


/*
Outcome inventory for archived strategy slices.

This query gives users a quick view of final simulated strategy outcome composition for each
archived strategy / Module 1 scenario / population slice.
*/
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


/*
Archive grain diagnostic.

The archive is expected to be unique at:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id

This diagnostic should return zero rows if the unique archive grain is intact.
*/
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id,
    COUNT(*) AS duplicate_archive_grain_row_count
FROM credit_decisioning_sim.strategy_decisions_archive
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id
HAVING COUNT(*) > 1
ORDER BY
    duplicate_archive_grain_row_count DESC,
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id;



/***************************************************************************************************
SECTION 13.2 — SELECTED COMPARISON READINESS
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

WHY SAME-STRATEGY COMPARISON IS FLAGGED:
    A matched comparison between identical strategy identifiers may be useful for deterministic
    reproducibility testing in a future workflow.

    Section 13 V1.0 is focused on baseline-versus-challenger strategy comparison. Selecting the same
    strategy on both sides does not produce a strategy-delta comparison and is therefore labeled
    NOT_READY_SAME_STRATEGY_SELECTED.

WHY APPLICATION SET MATCHING MATTERS:
    Matched strategy comparison should isolate downstream Module 2 strategy effects.

    If baseline-only or challenger-only application_id values exist, differences may reflect archive
    selection problems, population mismatch, or archive integrity issues rather than strategy changes.

WHY DUPLICATE ARCHIVE GRAIN MATTERS:
    Duplicate application_id values within a selected strategy / Module 1 scenario / population slice
    make row-level matching ambiguous.

    The comparison framework therefore reports duplicate archive grain before interpreting strategy
    deltas.

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
SELECT
    comparison_set_name,

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

    readiness_status
FROM readiness;



/***************************************************************************************************
END OF MODULE 2 FULL SQL CODE CAPTURE — PART 7A OF 7F

Part 7A established:
    1. Section 13 purpose and read-only archive-comparison boundary.
    2. tmp_m2_strategy_comparison_params for baseline / challenger selection.
    3. Archive inventory for available Module 2 strategy slices.
    4. Archived decision-outcome inventory.
    5. Archive grain duplicate diagnostic.
    6. Selected comparison readiness diagnostics.
    7. Explicit NOT_READY_SAME_STRATEGY_SELECTED handling.
    8. Safe matched-population readiness checks using application_id.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No decision outcomes have been recalculated.
No simulated reason codes have been recalculated.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No full Module 2 QA framework has been created in this subpart.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 7A OF 7F END
```

Ready for next part: say CONTINUE FULL CODE PART 7B
<!-- END_MESSAGE C038-M00229 -->


---

<a id="c038-m00230"></a>

### C038-M00230

**Andrew** · 2026-05-06T18:38:35.558000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00230 -->
CONTINUE FULL CODE PART 7B
<!-- END_MESSAGE C038-M00230 -->


---

<a id="c038-m00232"></a>

### C038-M00232

**ChatGPT** · 2026-05-06T18:41:52.688097-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00232 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 7B OF 7F START

/***************************************************************************************************
SECTION 13.3 — PORTFOLIO-LEVEL ARCHIVED STRATEGY SUMMARY
****************************************************************************************************

PURPOSE:
    Compare selected archived strategies at the portfolio level.

BUSINESS INTERPRETATION:
    This query summarizes each selected archived strategy slice independently before calculating
    baseline-versus-challenger deltas.

    It answers:
        "What does each archived strategy output look like at the total portfolio level?"

READ-ONLY BOUNDARY:
    This query does not mutate archive rows.
    This query does not recalculate decision outcomes.
    This query does not recalculate approved exposure.
    This query does not recalculate approved Expected Loss.
    This query does not reassign simulated reason codes.

METRIC CONVENTIONS:
    Approval rate:
        approval_count / applications

    Counteroffer rate:
        counteroffer_count / applications

    Manual review rate:
        manual_review_count / applications

    Decline rate:
        decline_count / applications

    Simulated offer exposure rate:
        simulated_offer_exposure_count / applications

    All-application approved exposure metrics:
        Use COALESCE(approved_amount, 0)
        Use COALESCE(approved_expected_loss_amount, 0)

        These describe total simulated exposure impact across the full application population.

    Offer-row metrics:
        Use FILTER (WHERE simulated_offer_exposure_flag IS TRUE)

        These describe the profile of synthetic applicants receiving simulated positive offer exposure.

    Manual-review rows remain unresolved by design.
    Their approved exposure fields remain NULL in the source output and should not be overwritten.

ESTIMATED_PD TERMINOLOGY:
    estimated_pd remains the finalized Module 1 SQL field name.
    In this Module 2 comparison output, it is interpreted as the synthetic estimated-PD proxy.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows.

    It does not imply operational account creation, funding, operational approval, or real applicant
    treatment.

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

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_counteroffers,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(estimated_lgd) AS avg_estimated_lgd,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows,

    COUNT(*) FILTER (WHERE primary_reason_family = 'APPROVAL') AS approval_reason_family_count,
    COUNT(*) FILTER (WHERE primary_reason_family = 'COUNTEROFFER') AS counteroffer_reason_family_count,
    COUNT(*) FILTER (WHERE primary_reason_family = 'MANUAL_REVIEW') AS manual_review_reason_family_count,
    COUNT(*) FILTER (WHERE primary_reason_family = 'POLICY_STOP') AS policy_stop_reason_family_count
FROM selected_slices
GROUP BY
    comparison_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
ORDER BY
    CASE comparison_role
        WHEN 'BASELINE' THEN 1
        WHEN 'CHALLENGER' THEN 2
        ELSE 99
    END;



/***************************************************************************************************
SECTION 13.4 — BASELINE VS CHALLENGER PORTFOLIO-LEVEL DELTA SUMMARY
****************************************************************************************************

PURPOSE:
    Show direct portfolio-level deltas between baseline and challenger archived strategy slices.

BUSINESS INTERPRETATION:
    This query answers:
        "How did the challenger strategy change portfolio-level simulated outcomes relative to the
         baseline strategy, when applied to the same Module 1 scenario and population?"

COMPARISON BOUNDARY:
    This is a matched strategy simulation comparison.
    It should not be interpreted as causal proof beyond the controlled synthetic strategy-simulation
    boundary.

WHY BASELINE_* / CHALLENGER_* / DELTA_* NAMING IS USED:
    Explicit metric prefixes make the comparison auditable and prevent users from confusing baseline
    values, challenger values, and arithmetic differences.

SAFE DENOMINATOR RULE:
    All rates use NULLIF denominators.
    This keeps Section 13 diagnostic behavior robust even when baseline or challenger slices are
    missing or not ready for comparison.

TIMESTAMP BOUNDARY:
    strategy_run_ts, latest_output_created_ts, and archive_inserted_ts are audit metadata.
    They are intentionally excluded from deterministic strategy-delta metrics.

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

        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_declined_rows,

        AVG(estimated_lgd) AS avg_estimated_lgd_all_apps
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
    c.applications - b.applications AS delta_applications,

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

    b.total_requested_amount AS baseline_total_requested_amount,
    c.total_requested_amount AS challenger_total_requested_amount,
    c.total_requested_amount - b.total_requested_amount AS delta_total_requested_amount,

    b.total_approved_amount AS baseline_total_approved_amount,
    c.total_approved_amount AS challenger_total_approved_amount,
    c.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    b.avg_requested_amount AS baseline_avg_requested_amount,
    c.avg_requested_amount AS challenger_avg_requested_amount,
    c.avg_requested_amount - b.avg_requested_amount AS delta_avg_requested_amount,

    b.avg_approved_amount_all_apps AS baseline_avg_approved_amount_all_apps,
    c.avg_approved_amount_all_apps AS challenger_avg_approved_amount_all_apps,
    c.avg_approved_amount_all_apps - b.avg_approved_amount_all_apps
        AS delta_avg_approved_amount_all_apps,

    b.avg_approved_amount_offer_rows AS baseline_avg_approved_amount_offer_rows,
    c.avg_approved_amount_offer_rows AS challenger_avg_approved_amount_offer_rows,
    c.avg_approved_amount_offer_rows - b.avg_approved_amount_offer_rows
        AS delta_avg_approved_amount_offer_rows,

    b.total_requested_expected_loss_amount AS baseline_total_requested_expected_loss_amount,
    c.total_requested_expected_loss_amount AS challenger_total_requested_expected_loss_amount,
    c.total_requested_expected_loss_amount - b.total_requested_expected_loss_amount
        AS delta_total_requested_expected_loss_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    c.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    c.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.avg_requested_expected_loss_amount AS baseline_avg_requested_expected_loss_amount,
    c.avg_requested_expected_loss_amount AS challenger_avg_requested_expected_loss_amount,
    c.avg_requested_expected_loss_amount - b.avg_requested_expected_loss_amount
        AS delta_avg_requested_expected_loss_amount,

    b.avg_approved_expected_loss_all_apps AS baseline_avg_approved_expected_loss_all_apps,
    c.avg_approved_expected_loss_all_apps AS challenger_avg_approved_expected_loss_all_apps,
    c.avg_approved_expected_loss_all_apps - b.avg_approved_expected_loss_all_apps
        AS delta_avg_approved_expected_loss_all_apps,

    b.avg_approved_expected_loss_offer_rows AS baseline_avg_approved_expected_loss_offer_rows,
    c.avg_approved_expected_loss_offer_rows AS challenger_avg_approved_expected_loss_offer_rows,
    c.avg_approved_expected_loss_offer_rows - b.avg_approved_expected_loss_offer_rows
        AS delta_avg_approved_expected_loss_offer_rows,

    b.avg_requested_payment_to_income_ratio AS baseline_avg_requested_payment_to_income_ratio,
    c.avg_requested_payment_to_income_ratio AS challenger_avg_requested_payment_to_income_ratio,
    c.avg_requested_payment_to_income_ratio - b.avg_requested_payment_to_income_ratio
        AS delta_avg_requested_payment_to_income_ratio,

    b.avg_approved_pti_offer_rows AS baseline_avg_approved_pti_offer_rows,
    c.avg_approved_pti_offer_rows AS challenger_avg_approved_pti_offer_rows,
    c.avg_approved_pti_offer_rows - b.avg_approved_pti_offer_rows
        AS delta_avg_approved_pti_offer_rows,

    b.avg_synthetic_estimated_pd_proxy_all_apps
        AS baseline_avg_synthetic_estimated_pd_proxy_all_apps,
    c.avg_synthetic_estimated_pd_proxy_all_apps
        AS challenger_avg_synthetic_estimated_pd_proxy_all_apps,
    c.avg_synthetic_estimated_pd_proxy_all_apps
      - b.avg_synthetic_estimated_pd_proxy_all_apps
        AS delta_avg_synthetic_estimated_pd_proxy_all_apps,

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
        AS delta_avg_synthetic_estimated_pd_proxy_declined_rows,

    b.avg_estimated_lgd_all_apps AS baseline_avg_estimated_lgd_all_apps,
    c.avg_estimated_lgd_all_apps AS challenger_avg_estimated_lgd_all_apps,
    c.avg_estimated_lgd_all_apps - b.avg_estimated_lgd_all_apps
        AS delta_avg_estimated_lgd_all_apps

FROM p
JOIN portfolio_summary b
    ON b.comparison_role = 'BASELINE'
JOIN portfolio_summary c
    ON c.comparison_role = 'CHALLENGER';



/***************************************************************************************************
SECTION 13.5 — DECISION MIGRATION MATRIX
****************************************************************************************************

PURPOSE:
    Show how final simulated decision outcomes changed from baseline to challenger.

BUSINESS INTERPRETATION:
    This is one of the most important archived strategy comparison outputs.

    It answers:
        "Which synthetic applicants stayed in the same final strategy outcome, and which moved from
         one final outcome to another?"

EXAMPLES OF USEFUL MOVEMENT QUESTIONS:
    How many baseline APPROVE rows became challenger COUNTEROFFER?
    How many baseline APPROVE rows became challenger MANUAL_REVIEW?
    How many baseline APPROVE rows became challenger DECLINE?
    How many baseline DECLINE rows became challenger APPROVE?
    How much of the matched population was stable versus changed?

MATCHED POPULATION DENOMINATOR:
    pct_of_matched_population uses the matched application population only.

    This is intentional. If baseline and challenger are not fully matched, the migration matrix should
    not pretend it represents the full latest-run or archive slice population.

READINESS NOTE:
    The readiness query in Section 13.2 should be reviewed before interpreting this migration matrix.
    This query remains read-only and diagnostic.

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
),

migration_summary AS (
    SELECT
        baseline_decision_outcome,
        challenger_decision_outcome,
        COUNT(*) AS matched_rows
    FROM matched
    GROUP BY
        baseline_decision_outcome,
        challenger_decision_outcome
)

SELECT
    baseline_decision_outcome,
    challenger_decision_outcome,
    matched_rows,

    ROUND(
        100.0 * matched_rows::NUMERIC
        / NULLIF(SUM(matched_rows) OVER (), 0),
        2
    ) AS pct_of_matched_population,

    CASE
        WHEN baseline_decision_outcome = challenger_decision_outcome
            THEN 'STABLE_OUTCOME'
        ELSE 'MIGRATED_OUTCOME'
    END AS decision_migration_type
FROM migration_summary
ORDER BY
    CASE baseline_decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    CASE challenger_decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 13.6 — MATCHED APPLICANT-LEVEL DELTA SAMPLE
****************************************************************************************************

PURPOSE:
    Show row-level examples of the largest strategy movements.

BUSINESS INTERPRETATION:
    This query supports deep-dive review.

    It answers:
        "Which matched synthetic applications experienced the largest change in approved exposure,
         approved affordability proxy, or approved Expected Loss?"

ROW-LEVEL MATCHING KEY:
    Baseline and challenger rows are joined on:
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

    This preserves the distinction between upstream Module 1 scenario lineage and downstream
    Module 2 strategy identity.

WHY COALESCE IS USED FOR DELTA AMOUNTS:
    MANUAL_REVIEW rows are unresolved and have NULL approved exposure by design.
    DECLINE rows have zero approved exposure by convention.

    COALESCE is used only for delta arithmetic in this diagnostic output.
    It does not change the stored source values.

SORT ORDER:
    Largest absolute approved Expected Loss movement first.
    Largest absolute approved amount movement second.

BOUNDARY:
    This query does not imply real customer treatment.
    It shows synthetic applicant-level strategy simulation movement.

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

        b.credit_score,
        b.annual_income,
        b.requested_amount,
        b.requested_payment_to_income_ratio,
        b.requested_expected_loss_amount,

        b.estimated_pd AS baseline_synthetic_estimated_pd_proxy,
        c.estimated_pd AS challenger_synthetic_estimated_pd_proxy,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.decision_path AS baseline_decision_path,
        c.decision_path AS challenger_decision_path,

        b.primary_reason_family AS baseline_primary_reason_family,
        c.primary_reason_family AS challenger_primary_reason_family,

        b.primary_reason_code AS baseline_primary_reason_code,
        c.primary_reason_code AS challenger_primary_reason_code,

        b.simulated_offer_exposure_flag AS baseline_simulated_offer_exposure_flag,
        c.simulated_offer_exposure_flag AS challenger_simulated_offer_exposure_flag,

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
            AS delta_approved_expected_loss_amount,

        b.exposure_reduction_pct AS baseline_exposure_reduction_pct,
        c.exposure_reduction_pct AS challenger_exposure_reduction_pct,

        c.exposure_reduction_pct - b.exposure_reduction_pct
            AS delta_exposure_reduction_pct,

        CASE
            WHEN b.decision_outcome = c.decision_outcome
                THEN 'STABLE_OUTCOME'
            ELSE 'MIGRATED_OUTCOME'
        END AS decision_migration_type

    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT
    application_id,
    applicant_id,

    product_type_policy_key,
    score_band_policy_key,

    credit_score,
    annual_income,
    requested_amount,
    requested_payment_to_income_ratio,
    requested_expected_loss_amount,

    baseline_synthetic_estimated_pd_proxy,
    challenger_synthetic_estimated_pd_proxy,

    baseline_decision_outcome,
    challenger_decision_outcome,
    decision_migration_type,

    baseline_decision_path,
    challenger_decision_path,

    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code,

    baseline_simulated_offer_exposure_flag,
    challenger_simulated_offer_exposure_flag,

    baseline_approved_amount,
    challenger_approved_amount,
    delta_approved_amount,

    baseline_approved_payment_to_income_ratio,
    challenger_approved_payment_to_income_ratio,
    delta_approved_payment_to_income_ratio,

    baseline_approved_expected_loss_amount,
    challenger_approved_expected_loss_amount,
    delta_approved_expected_loss_amount,

    baseline_exposure_reduction_pct,
    challenger_exposure_reduction_pct,
    delta_exposure_reduction_pct
FROM matched
ORDER BY
    ABS(delta_approved_expected_loss_amount) DESC,
    ABS(delta_approved_amount) DESC,
    application_id
LIMIT 50;



/***************************************************************************************************
END OF MODULE 2 FULL SQL CODE CAPTURE — PART 7B OF 7F

Part 7B established:
    1. Portfolio-level archived strategy summaries for selected baseline and challenger slices.
    2. Safe-denominator rate calculations.
    3. Explicit all-application versus offer-row approved exposure metrics.
    4. Portfolio-level baseline / challenger / delta metrics.
    5. Decision migration matrix using the matched application population denominator.
    6. Matched applicant-level delta sample for row-level strategy movement review.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No decision outcomes have been recalculated.
No simulated reason codes have been recalculated.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No full Module 2 QA framework has been created in this subpart.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 7B OF 7F END
```

Ready for next part: say CONTINUE FULL CODE PART 7C
<!-- END_MESSAGE C038-M00232 -->


---

<a id="c038-m00234"></a>

### C038-M00234

**Andrew** · 2026-05-06T18:43:43.954000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00234 -->
CONTINUE FULL CODE PART 7C
<!-- END_MESSAGE C038-M00234 -->


---

<a id="c038-m00236"></a>

### C038-M00236

**ChatGPT** · 2026-05-06T18:47:34.117813-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00236 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 7C OF 7F START

/***************************************************************************************************
SECTION 13.7 — PRODUCT / SCORE / PRODUCT × SCORE STRATEGY COMPARISON
****************************************************************************************************

PURPOSE:
    Show where strategy changes concentrate by product, score band, and product × score-band segment.

BUSINESS INTERPRETATION:
    These queries answer:
        "Which products changed most?"
        "Which score bands changed most?"
        "Which product × score-band intersections drove strategy movement?"

WHY SEGMENT-LEVEL COMPARISON MATTERS:
    Portfolio-level deltas can hide concentrated strategy effects.

    A challenger strategy may have a modest overall approval-rate change while creating material
    movement in a specific product, score band, or product × score segment.

MATCHED COMPARISON BOUNDARY:
    Baseline and challenger rows are matched on:
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

    This isolates downstream Module 2 strategy effects for the same synthetic applicant population.

METRIC CONVENTIONS:
    Rates use safe NULLIF denominators.

    Approved exposure metrics are shown as all-application metrics using COALESCE because these
    segment summaries measure total simulated exposure impact.

    Offer-row metrics are explicitly named when they use only simulated positive offer-exposure rows.

ESTIMATED_PD TERMINOLOGY:
    estimated_pd remains the finalized Module 1 SQL field name.
    In Section 13, it is interpreted as the synthetic estimated-PD proxy.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.7A Product-level matched strategy delta summary.

This query summarizes matched baseline-versus-challenger strategy movement by product.
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
        b.product_type_policy_key,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.simulated_offer_exposure_flag AS baseline_simulated_offer_exposure_flag,
        c.simulated_offer_exposure_flag AS challenger_simulated_offer_exposure_flag,

        COALESCE(b.approved_amount, 0) AS baseline_approved_amount_all_app_value,
        COALESCE(c.approved_amount, 0) AS challenger_approved_amount_all_app_value,

        COALESCE(b.approved_expected_loss_amount, 0) AS baseline_approved_el_all_app_value,
        COALESCE(c.approved_expected_loss_amount, 0) AS challenger_approved_el_all_app_value,

        b.estimated_pd AS baseline_synthetic_estimated_pd_proxy,
        c.estimated_pd AS challenger_synthetic_estimated_pd_proxy
    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT
    product_type_policy_key,

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

    COUNT(*) FILTER (WHERE baseline_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_simulated_offer_exposure_rate,
    COUNT(*) FILTER (WHERE challenger_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_simulated_offer_exposure_rate,
    (
        COUNT(*) FILTER (WHERE challenger_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_simulated_offer_exposure_rate,

    AVG(baseline_approved_amount_all_app_value) AS baseline_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value) AS challenger_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value)
      - AVG(baseline_approved_amount_all_app_value)
        AS delta_avg_approved_amount_all_apps,

    AVG(baseline_approved_el_all_app_value) AS baseline_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value) AS challenger_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value)
      - AVG(baseline_approved_el_all_app_value)
        AS delta_avg_approved_expected_loss_all_apps,

    AVG(baseline_synthetic_estimated_pd_proxy) AS baseline_avg_synthetic_estimated_pd_proxy,
    AVG(challenger_synthetic_estimated_pd_proxy) AS challenger_avg_synthetic_estimated_pd_proxy,
    AVG(challenger_synthetic_estimated_pd_proxy)
      - AVG(baseline_synthetic_estimated_pd_proxy)
        AS delta_avg_synthetic_estimated_pd_proxy
FROM matched
GROUP BY product_type_policy_key
ORDER BY product_type_policy_key;


/*-----------------------------------------------------------------------------------------------
13.7B Score-band-level matched strategy delta summary.

This query summarizes matched baseline-versus-challenger strategy movement by score band.
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
        b.score_band_policy_key,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.simulated_offer_exposure_flag AS baseline_simulated_offer_exposure_flag,
        c.simulated_offer_exposure_flag AS challenger_simulated_offer_exposure_flag,

        COALESCE(b.approved_amount, 0) AS baseline_approved_amount_all_app_value,
        COALESCE(c.approved_amount, 0) AS challenger_approved_amount_all_app_value,

        COALESCE(b.approved_expected_loss_amount, 0) AS baseline_approved_el_all_app_value,
        COALESCE(c.approved_expected_loss_amount, 0) AS challenger_approved_el_all_app_value,

        b.estimated_pd AS baseline_synthetic_estimated_pd_proxy,
        c.estimated_pd AS challenger_synthetic_estimated_pd_proxy
    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)

SELECT
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

    COUNT(*) FILTER (WHERE baseline_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_simulated_offer_exposure_rate,
    COUNT(*) FILTER (WHERE challenger_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_simulated_offer_exposure_rate,
    (
        COUNT(*) FILTER (WHERE challenger_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_simulated_offer_exposure_rate,

    AVG(baseline_approved_amount_all_app_value) AS baseline_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value) AS challenger_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value)
      - AVG(baseline_approved_amount_all_app_value)
        AS delta_avg_approved_amount_all_apps,

    AVG(baseline_approved_el_all_app_value) AS baseline_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value) AS challenger_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value)
      - AVG(baseline_approved_el_all_app_value)
        AS delta_avg_approved_expected_loss_all_apps,

    AVG(baseline_synthetic_estimated_pd_proxy) AS baseline_avg_synthetic_estimated_pd_proxy,
    AVG(challenger_synthetic_estimated_pd_proxy) AS challenger_avg_synthetic_estimated_pd_proxy,
    AVG(challenger_synthetic_estimated_pd_proxy)
      - AVG(baseline_synthetic_estimated_pd_proxy)
        AS delta_avg_synthetic_estimated_pd_proxy
FROM matched
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


/*-----------------------------------------------------------------------------------------------
13.7C Product × score-band matched strategy delta summary.

This is the main segment-level comparison view for strategy movement.
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
        b.product_type_policy_key,
        b.score_band_policy_key,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.simulated_offer_exposure_flag AS baseline_simulated_offer_exposure_flag,
        c.simulated_offer_exposure_flag AS challenger_simulated_offer_exposure_flag,

        COALESCE(b.approved_amount, 0) AS baseline_approved_amount_all_app_value,
        COALESCE(c.approved_amount, 0) AS challenger_approved_amount_all_app_value,

        COALESCE(b.approved_expected_loss_amount, 0) AS baseline_approved_el_all_app_value,
        COALESCE(c.approved_expected_loss_amount, 0) AS challenger_approved_el_all_app_value,

        b.estimated_pd AS baseline_synthetic_estimated_pd_proxy,
        c.estimated_pd AS challenger_synthetic_estimated_pd_proxy
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

    COUNT(*) FILTER (WHERE baseline_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_simulated_offer_exposure_rate,
    COUNT(*) FILTER (WHERE challenger_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_simulated_offer_exposure_rate,
    (
        COUNT(*) FILTER (WHERE challenger_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_simulated_offer_exposure_rate,

    AVG(baseline_approved_amount_all_app_value) AS baseline_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value) AS challenger_avg_approved_amount_all_apps,
    AVG(challenger_approved_amount_all_app_value)
      - AVG(baseline_approved_amount_all_app_value)
        AS delta_avg_approved_amount_all_apps,

    AVG(baseline_approved_el_all_app_value) AS baseline_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value) AS challenger_avg_approved_expected_loss_all_apps,
    AVG(challenger_approved_el_all_app_value)
      - AVG(baseline_approved_el_all_app_value)
        AS delta_avg_approved_expected_loss_all_apps,

    AVG(baseline_synthetic_estimated_pd_proxy) AS baseline_avg_synthetic_estimated_pd_proxy,
    AVG(challenger_synthetic_estimated_pd_proxy) AS challenger_avg_synthetic_estimated_pd_proxy,
    AVG(challenger_synthetic_estimated_pd_proxy)
      - AVG(baseline_synthetic_estimated_pd_proxy)
        AS delta_avg_synthetic_estimated_pd_proxy
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
SECTION 13.8 — REASON-CODE MOVEMENT SUMMARY
****************************************************************************************************

PURPOSE:
    Show how simulated strategy explanation codes differ between selected archived strategies.

BUSINESS INTERPRETATION:
    Numeric movement tells users how much strategy behavior changed.
    Reason-code movement helps explain why strategy behavior changed.

REASON-CODE BOUNDARY:
    Reason codes are simulated strategy explanation codes only.

    They are not regulatory adverse-action reasons.
    They are not customer notices.
    They are not compliance-approved reason codes.
    They are not fair-lending conclusions.

WHY FAMILY AND CODE ARE BOTH INCLUDED:
    Movement across reason families is analytically different from movement within the same family.

    Example:
        POLICY_STOP / POLICY_STOP_HIGH_DTI
        moving to
        MANUAL_REVIEW / MANUAL_REVIEW_ELEVATED_DTI

    is materially different from movement between two policy-stop reasons.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.8A Primary reason distribution by selected strategy.
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
    CASE comparison_role
        WHEN 'BASELINE' THEN 1
        WHEN 'CHALLENGER' THEN 2
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
13.8B Matched reason-code migration.

The denominator is the matched application population.
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

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

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
),

reason_migration AS (
    SELECT
        baseline_decision_outcome,
        challenger_decision_outcome,

        baseline_primary_reason_family,
        baseline_primary_reason_code,

        challenger_primary_reason_family,
        challenger_primary_reason_code,

        COUNT(*) AS matched_rows
    FROM matched
    GROUP BY
        baseline_decision_outcome,
        challenger_decision_outcome,
        baseline_primary_reason_family,
        baseline_primary_reason_code,
        challenger_primary_reason_family,
        challenger_primary_reason_code
)

SELECT
    baseline_decision_outcome,
    challenger_decision_outcome,

    baseline_primary_reason_family,
    baseline_primary_reason_code,

    challenger_primary_reason_family,
    challenger_primary_reason_code,

    matched_rows,

    ROUND(
        100.0 * matched_rows::NUMERIC
        / NULLIF(SUM(matched_rows) OVER (), 0),
        2
    ) AS pct_of_matched_population,

    CASE
        WHEN baseline_primary_reason_family = challenger_primary_reason_family
         AND baseline_primary_reason_code = challenger_primary_reason_code
            THEN 'STABLE_REASON_CODE'
        WHEN baseline_primary_reason_family = challenger_primary_reason_family
            THEN 'MOVED_WITHIN_REASON_FAMILY'
        ELSE 'MOVED_ACROSS_REASON_FAMILY'
    END AS reason_code_migration_type
FROM reason_migration
ORDER BY
    matched_rows DESC,
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code;



/***************************************************************************************************
SECTION 13.9 — SIMULATED OFFER-EXPOSURE COMPARISON
****************************************************************************************************

PURPOSE:
    Compare simulated positive offer-exposure profiles between baseline and challenger.

BUSINESS INTERPRETATION:
    This query focuses only on rows where the simulated strategy produces positive offer exposure:
        APPROVE
        COUNTEROFFER

    It answers:
        "How did the offered population and simulated exposure profile change?"

TERMINOLOGY:
    Use:
        simulated offer exposure
        offer rows
        positive offer outcomes

    Do not interpret this as operational account creation, funded exposure, or real customer treatment.

WHY THIS VIEW IS SEPARATE FROM TOTAL POPULATION METRICS:
    MANUAL_REVIEW rows are unresolved by design.
    DECLINE rows follow the zero-exposure convention.

    Offer-row profile metrics should therefore be reviewed separately from all-application portfolio
    impact metrics.

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

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS positive_offer_rate,

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

    AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_estimated_lgd_offer_rows,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_requested_pti_offer_rows,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    SUM(COALESCE(requested_expected_loss_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_requested_expected_loss_offer_rows,

    SUM(COALESCE(approved_expected_loss_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_expected_loss_offer_rows,

    AVG(requested_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_requested_expected_loss_offer_rows,

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
ORDER BY
    CASE comparison_role
        WHEN 'BASELINE' THEN 1
        WHEN 'CHALLENGER' THEN 2
        ELSE 99
    END;



/***************************************************************************************************
SECTION 13.10 — UNMATCHED ROW DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    If comparison readiness is not READY_FOR_MATCHED_COMPARISON, identify baseline-only and
    challenger-only application_id values.

BUSINESS INTERPRETATION:
    This diagnostic helps users determine whether a comparison selection issue, archive integrity
    issue, or population mismatch is preventing matched strategy comparison.

BOUNDARY:
    This query is read-only.
    It does not mutate archive rows.
    It does not recalculate any strategy result.

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
SECTION 13.11 — MATCHED MODULE 1 SOURCE-FIELD CONSISTENCY DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    Confirm that matched baseline and challenger strategy slices share the same immutable Module 1
    source fields.

WHY THIS MATTERS:
    Matched Module 2 strategy comparison should isolate downstream strategy effects.

    If Module 1 source fields differ between matched baseline and challenger rows, comparison results
    may reflect population drift, source-selection error, or upstream scenario mismatch rather than
    true downstream strategy movement.

FIELDS COMPARED:
    product_type_policy_key
    score_band_policy_key
    credit_score
    annual_income
    requested_amount
    requested_monthly_payment_proxy
    requested_payment_to_income_ratio
    amount_to_income_ratio
    estimated_pd
    estimated_lgd
    requested_expected_loss_amount
    module1_scenario_set_name
    module1_scenario_name
    population_id

NULL HANDLING:
    IS DISTINCT FROM is used so NULL comparisons remain explicit and safe.

READINESS BOUNDARY:
    This diagnostic does not fail execution solely because placeholder comparison parameters are not
    ready. If matched comparison is not ready, source_consistency_status reports:

        NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON

READ-ONLY BOUNDARY:
    This diagnostic does not mutate archive rows.
    This diagnostic does not recalculate decisions.
    This diagnostic does not recalculate simulated reason codes.
    This diagnostic does not recalculate approved exposure.
    This diagnostic does not recalculate Expected Loss.

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
    9. Product-level, score-band-level, and product × score-band matched strategy deltas can be reviewed.
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

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 7C OF 7F END
```

Ready for next part: say CONTINUE FULL CODE PART 7D
<!-- END_MESSAGE C038-M00236 -->


---

<a id="c038-m00238"></a>

### C038-M00238

**Andrew** · 2026-05-06T18:49:24.872000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00238 -->
CONTINUE FULL CODE PART 7D
<!-- END_MESSAGE C038-M00238 -->


---

<a id="c038-m00240"></a>

### C038-M00240

**ChatGPT** · 2026-05-06T18:53:05.437995-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00240 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 7D OF 7F START

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
    5. Produce a compact temporary validation status summary in Section 14.19.
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
    It is not treated as a calibrated probability of default.

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
    It does not imply operational account creation, funding, operational approval, or real applicant
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
SECTION 14.1 — VALIDATION SCOPE AND BOUNDARY
****************************************************************************************************

PURPOSE:
    Establish the latest-run validation scope before running the detailed QA query blocks.

BUSINESS INTERPRETATION:
    This section confirms what Section 14 is validating:
        the completed latest-run Module 2 strategy output in
        credit_decisioning_sim.strategy_decisions.

    Archive information may be referenced later for readiness context, but the primary validation
    target is the latest-run output.

WHY THIS SECTION EXISTS:
    Validation evidence should be scoped before it is interpreted.

    A latest-run strategy output should be evaluated as:
        one active Module 2 strategy,
        applied to one selected Module 1 scenario / population slice,
        producing one final simulated strategy outcome per synthetic application.

BOUNDARY:
    Section 14 validates simulation coherence and output consistency.
    It does not convert Module 2 into an operational decision system.
    It does not validate real applicant treatment.
    It does not validate calibrated default forecasting.
    It does not validate regulatory notices or fair-lending conclusions.

***************************************************************************************************/

SELECT
    'MODULE_2_LATEST_RUN_VALIDATION_SCOPE' AS validation_scope_name,

    COUNT(*) AS latest_run_rows,
    COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count,

    COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version
    )) AS latest_run_distinct_strategy_count,

    COUNT(DISTINCT (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) AS latest_run_distinct_module1_scenario_population_count,

    MIN(strategy_run_ts) AS min_strategy_run_ts,
    MAX(strategy_run_ts) AS max_strategy_run_ts,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,

    CASE
        WHEN COUNT(*) = 0
            THEN 'REVIEW_EMPTY_LATEST_RUN_OUTPUT'

        WHEN COUNT(*) <> COUNT(DISTINCT application_id)
            THEN 'REVIEW_DUPLICATE_APPLICATION_ID_IN_LATEST_RUN'

        WHEN COUNT(DISTINCT (strategy_set_name, strategy_name, strategy_version)) <> 1
            THEN 'REVIEW_MULTIPLE_STRATEGIES_IN_LATEST_RUN'

        WHEN COUNT(DISTINCT (module1_scenario_set_name, module1_scenario_name, population_id)) <> 1
            THEN 'REVIEW_MULTIPLE_MODULE1_SCENARIO_POPULATION_SLICES_IN_LATEST_RUN'

        ELSE 'LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW'
    END AS validation_scope_status
FROM credit_decisioning_sim.strategy_decisions;


/*
Latest-run strategy and Module 1 lineage scope.

This query intentionally separates Module 2 strategy identifiers from Module 1 scenario identifiers.
*/
SELECT
    module2_model_version,

    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    archive_run_flag,
    strategy_archive_reset_mode,

    module1_input_source,
    module1_source_table_name,

    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,

    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    module2_model_version,

    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    archive_run_flag,
    strategy_archive_reset_mode,

    module1_input_source,
    module1_source_table_name,

    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/***************************************************************************************************
SECTION 14.2 — LATEST-RUN STRUCTURAL INTEGRITY SUMMARY
****************************************************************************************************

PURPOSE:
    Confirm that the latest-run strategy_decisions table exists, is populated, and has the expected
    row-level integrity.

EXPECTED INTERPRETATION:
    total rows should equal distinct application_id count.
    exactly one strategy version should be present in latest-run output.
    exactly one Module 1 scenario / population should be present unless multi-scenario processing is
    explicitly designed later.

WHY STRUCTURAL QA COMES BEFORE STRATEGY QA:
    Decision distribution, reason-code summaries, and exposure diagnostics are only interpretable if
    the output table has the expected row grain and lineage scope.

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

    COUNT(*) FILTER (WHERE application_id IS NULL) AS null_application_id_rows,
    COUNT(*) FILTER (WHERE applicant_id IS NULL) AS null_applicant_id_rows,

    COUNT(*) FILTER (WHERE strategy_set_name IS NULL OR BTRIM(strategy_set_name) = '') AS null_or_blank_strategy_set_name_rows,
    COUNT(*) FILTER (WHERE strategy_name IS NULL OR BTRIM(strategy_name) = '') AS null_or_blank_strategy_name_rows,
    COUNT(*) FILTER (WHERE strategy_version IS NULL OR BTRIM(strategy_version) = '') AS null_or_blank_strategy_version_rows,

    COUNT(*) FILTER (WHERE module1_scenario_set_name IS NULL OR BTRIM(module1_scenario_set_name) = '')
        AS null_or_blank_module1_scenario_set_name_rows,

    COUNT(*) FILTER (WHERE module1_scenario_name IS NULL OR BTRIM(module1_scenario_name) = '')
        AS null_or_blank_module1_scenario_name_rows,

    COUNT(*) FILTER (WHERE population_id IS NULL OR BTRIM(population_id) = '')
        AS null_or_blank_population_id_rows,

    COUNT(*) FILTER (WHERE decision_outcome IS NULL) AS null_decision_outcome_rows,
    COUNT(*) FILTER (WHERE primary_reason_code IS NULL) AS null_primary_reason_code_rows,
    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL) AS null_requested_expected_loss_amount_rows,

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


/*
Duplicate application diagnostic.

Expected result:
    zero rows.

If any rows appear, the latest-run table is not unique at application_id and downstream
application-level QA should not be interpreted until corrected.
*/
SELECT
    application_id,
    COUNT(*) AS duplicate_application_row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY application_id
HAVING COUNT(*) > 1
ORDER BY
    duplicate_application_row_count DESC,
    application_id
LIMIT 100;


/*
Required-field completeness diagnostic.

This query surfaces missing core fields needed for strategy QA. It is diagnostic only; earlier sections
already contain fail-fast gatekeepers.
*/
SELECT
    COUNT(*) FILTER (WHERE module2_model_version IS NULL OR BTRIM(module2_model_version) = '') AS missing_module2_model_version_rows,
    COUNT(*) FILTER (WHERE strategy_run_id IS NULL OR BTRIM(strategy_run_id) = '') AS missing_strategy_run_id_rows,
    COUNT(*) FILTER (WHERE strategy_run_ts IS NULL) AS missing_strategy_run_ts_rows,

    COUNT(*) FILTER (WHERE product_type_policy_key IS NULL OR BTRIM(product_type_policy_key) = '') AS missing_product_type_policy_key_rows,
    COUNT(*) FILTER (WHERE score_band_policy_key IS NULL OR BTRIM(score_band_policy_key) = '') AS missing_score_band_policy_key_rows,
    COUNT(*) FILTER (WHERE credit_score IS NULL) AS missing_credit_score_rows,

    COUNT(*) FILTER (WHERE requested_amount IS NULL) AS missing_requested_amount_rows,
    COUNT(*) FILTER (WHERE requested_monthly_payment_proxy IS NULL) AS missing_requested_monthly_payment_proxy_rows,
    COUNT(*) FILTER (WHERE requested_payment_to_income_ratio IS NULL) AS missing_requested_payment_to_income_ratio_rows,
    COUNT(*) FILTER (WHERE estimated_pd IS NULL) AS missing_synthetic_estimated_pd_proxy_rows,
    COUNT(*) FILTER (WHERE estimated_lgd IS NULL) AS missing_estimated_lgd_rows,
    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL) AS missing_requested_expected_loss_amount_rows,

    COUNT(*) FILTER (WHERE decision_outcome IS NULL) AS missing_decision_outcome_rows,
    COUNT(*) FILTER (WHERE decision_path IS NULL OR BTRIM(decision_path) = '') AS missing_decision_path_rows,
    COUNT(*) FILTER (WHERE decision_resolution_source IS NULL OR BTRIM(decision_resolution_source) = '')
        AS missing_decision_resolution_source_rows,

    COUNT(*) FILTER (WHERE primary_reason_code IS NULL OR BTRIM(primary_reason_code) = '') AS missing_primary_reason_code_rows,
    COUNT(*) FILTER (WHERE primary_reason_family IS NULL OR BTRIM(primary_reason_family) = '') AS missing_primary_reason_family_rows,
    COUNT(*) FILTER (WHERE triggered_reason_code_list IS NULL OR BTRIM(triggered_reason_code_list) = '')
        AS missing_triggered_reason_code_list_rows
FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.3 — DECISION OUTCOME DISTRIBUTION
****************************************************************************************************

PURPOSE:
    Summarize final simulated strategy outcomes.

EXPECTED INTERPRETATION:
    every row should have exactly one final outcome.
    APPROVE and COUNTEROFFER represent simulated positive offer-exposure outcomes.
    MANUAL_REVIEW remains unresolved.
    DECLINE follows the zero-exposure convention.

WHY THIS QUERY IS NOT SUFFICIENT BY ITSELF:
    Outcome distribution is necessary but not complete validation evidence.

    A strategy could have plausible overall rates while still failing product, score, affordability,
    exposure, or reason-code QA. Section 14 therefore continues with segment-level and diagnostic
    validation after this high-level outcome review.

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

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_flag_count,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

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


/*
Final decision-flag reconciliation distribution.

Expected result:
    final_decision_flag_count = 1 for every row.

This query is diagnostic evidence complementing the Section 11 gatekeeper.
*/
SELECT
    (
        COALESCE(approval_flag::INT, 0)
        + COALESCE(counteroffer_flag::INT, 0)
        + COALESCE(manual_review_flag::INT, 0)
        + COALESCE(decline_flag::INT, 0)
    ) AS final_decision_flag_count,

    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    (
        COALESCE(approval_flag::INT, 0)
        + COALESCE(counteroffer_flag::INT, 0)
        + COALESCE(manual_review_flag::INT, 0)
        + COALESCE(decline_flag::INT, 0)
    )
ORDER BY final_decision_flag_count;


/*
Preliminary route to final outcome distribution.

This query shows how preliminary routing resolved after exposure-treatment and final decision logic.
*/
SELECT
    preliminary_decision_outcome,
    decision_outcome,
    decision_resolution_source,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY preliminary_decision_outcome), 0),
        2
    ) AS pct_within_preliminary_outcome
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    preliminary_decision_outcome,
    decision_outcome,
    decision_resolution_source
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
    END,
    decision_resolution_source;



/***************************************************************************************************
SECTION 14.4 — PRODUCT-LEVEL STRATEGY QA
****************************************************************************************************

PURPOSE:
    Confirm product-level strategy behavior.

BUSINESS INTERPRETATION:
    Product-level outcomes should reflect product-specific policy parameters and structural
    differences.

    Product type can affect:
        requested exposure,
        requested payment burden,
        requested PTI,
        LGD,
        requested Expected Loss,
        counteroffer feasibility,
        approved exposure treatment,
        and final simulated strategy outcome.

METRIC CONVENTION:
    All-application approved metrics use COALESCE to treat unresolved manual-review approved exposure
    as zero for portfolio-impact summaries.

    Offer-row metrics use FILTER where simulated_offer_exposure_flag = TRUE.

BOUNDARY:
    Product-level QA supports strategy interpretation.
    It does not define product policy for real applicants.

***************************************************************************************************/

WITH product_outcome AS (
    SELECT
        product_type_policy_key,
        decision_outcome,

        COUNT(*) AS row_count,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(estimated_lgd) AS avg_estimated_lgd,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_count
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

    simulated_offer_exposure_count,

    avg_synthetic_estimated_pd_proxy,
    avg_estimated_lgd,

    avg_requested_amount,
    avg_approved_amount_all_apps,
    avg_approved_amount_offer_rows,

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


/*
Product-level decision-rate summary.

This query gives one row per product and is useful for quick product strategy QA.
*/
SELECT
    product_type_policy_key,

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

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY product_type_policy_key
ORDER BY product_type_policy_key;


/*
Product-level primary reason-code distribution.

This output helps confirm that product-level strategy outcomes remain explainable through simulated
strategy explanation codes.
*/
SELECT
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY product_type_policy_key), 0),
        2
    ) AS pct_within_product
FROM credit_decisioning_sim.strategy_decisions
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



/***************************************************************************************************
SECTION 14.5 — SCORE-BAND STRATEGY QA
****************************************************************************************************

PURPOSE:
    Validate directional strategy behavior by score band.

BUSINESS INTERPRETATION:
    Stronger score bands should generally show higher approval / positive offer rates.
    Weaker score bands should generally show higher manual review or decline rates.

    Perfect monotonicity is not required at every micro-segment because product mix, affordability,
    exposure structure, behavioral signals, and product-specific policy rules can create realistic
    overlap.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name and is interpreted as the synthetic
    estimated-PD proxy.

    Score-band QA reviews directional strategy behavior and risk ordering.
    It does not validate calibrated default probabilities.

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
        AVG(credit_score) AS avg_credit_score,
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps
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

    o.avg_credit_score,
    o.avg_synthetic_estimated_pd_proxy,
    o.avg_debt_to_income_ratio,
    o.avg_requested_payment_to_income_ratio,
    o.avg_requested_expected_loss_amount,
    o.avg_approved_expected_loss_all_apps,

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


/*
Score-band decision-rate summary.

This query provides a compact score-band profile for directional risk-ordering review.
*/
SELECT
    score_band_policy_key,

    COUNT(*) AS applications,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,

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
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount
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


/*
Score-band reason-code distribution.

This supports review of whether weaker score bands concentrate in expected simulated policy-stop
or manual-review explanation families while stronger score bands concentrate in approval or
lower-friction offer outcomes.
*/
SELECT
    score_band_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY score_band_policy_key), 0),
        2
    ) AS pct_within_score_band
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
END OF MODULE 2 FULL SQL CODE CAPTURE — PART 7D OF 7F

Part 7D established:
    1. Section 14 purpose and read-only validation boundary.
    2. Validation scope and latest-run lineage diagnostics.
    3. Latest-run structural integrity diagnostics.
    4. Final decision outcome distribution diagnostics.
    5. Preliminary-route-to-final-outcome review.
    6. Product-level strategy QA.
    7. Score-band strategy QA.
    8. Continued interpretation of estimated_pd as the synthetic estimated-PD proxy.
    9. Continued distinction between requested-exposure Expected Loss and approved-exposure Expected Loss.
    10. Continued simulated offer-exposure boundary discipline.

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

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 7D OF 7F END
```

Ready for next part: say CONTINUE FULL CODE PART 7E
<!-- END_MESSAGE C038-M00240 -->


---

<a id="c038-m00242"></a>

### C038-M00242

**Andrew** · 2026-05-06T18:53:39.509000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00242 -->
CONTINUE FULL CODE PART 7E
<!-- END_MESSAGE C038-M00242 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_16.md) · [Next](Part_18.md)
