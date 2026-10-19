# Module 2 Decision Simulator Build

## Part 90

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_89.md) · [Next](Part_91.md)

<a id="c038-m01797"></a>

### C038-M01797

**ChatGPT** · 2026-05-13T08:33:19.047221-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01797 -->
Replace your current **Sections 17.17 through 17.20** with the copy-paste block below. This removes the remaining fixed campaign-shape assumptions from these sections, scopes the effect checks through the active comparison/campaign registries, keeps the product-guardrail exact-value audit, and makes the final acceptance rollup dynamic rather than hardcoded to 36 runs / 50,000 rows / 18 validation rows. The current attached section still had the older counteroffer-first logic and a hardcoded final rollup, so this patch aligns it with the dynamic standard used in 17.1–17.16. fileciteturn294file0 fileciteturn294file6

```sql
/***************************************************************************************************
SECTION 17.17 — COUNTEROFFER-FIRST STRATEGY EFFECT CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Review the strategy effect for active comparison groups where the challenger is:

        COUNTEROFFER_FIRST_EXPOSURE_STRATEGY

    Section 17.17 answers:

        "Did counteroffer-first strategy design increase reduced-exposure treatment and create an
         interpretable counteroffer-management effect relative to its registered baseline?"

WHY THIS SECTION IS COMPARISON-REGISTRY-SCOPED:
    The active comparison registry defines the governed baseline / challenger pairs.

    This section does not infer pairings only from strategy_name.

DYNAMIC ACCEPTANCE PRINCIPLE:
    Expected matched comparison row count is derived from the selected Module 1 source population.

    It is not hardcoded to 50,000.

INTERPRETATION:
    A counteroffer-first strategy should generally:
        increase final counteroffer rate;
        increase feasible counteroffer treatment;
        increase total counteroffer exposure reduction;
        preserve comparison readiness and source consistency;
        and produce interpretable approved PTI / approved Expected Loss movement.

    The effect check is diagnostic.
    It is not a production recommendation.

READ-ONLY BOUNDARY:
    This section does not modify archive rows, evidence rows, registry rows, strategy parameters, or
    product-policy parameters.

***************************************************************************************************/

WITH counteroffer_first_comparisons AS (
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

        expected_comparison_storyline,
        primary_metric_focus
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
      AND challenger_strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
),

module1_source_counts AS (
    SELECT
        scenario_set_name AS module1_scenario_set_name,
        scenario_name AS module1_scenario_name,
        population_id,

        COUNT(*) AS expected_module1_source_rows,
        COUNT(DISTINCT application_id) AS expected_module1_distinct_application_id_count
    FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    GROUP BY
        scenario_set_name,
        scenario_name,
        population_id
),

archive_counts AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS archived_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count
    FROM credit_decisioning_sim.strategy_decisions_archive
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

baseline_applications AS (
    SELECT DISTINCT
        c.comparison_group_id,
        b.application_id
    FROM counteroffer_first_comparisons c

    JOIN credit_decisioning_sim.strategy_decisions_archive b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id
),

challenger_applications AS (
    SELECT DISTINCT
        c.comparison_group_id,
        ch.application_id
    FROM counteroffer_first_comparisons c

    JOIN credit_decisioning_sim.strategy_decisions_archive ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id
),

comparison_overlap AS (
    SELECT
        COALESCE(b.comparison_group_id, ch.comparison_group_id)
            AS comparison_group_id,

        COUNT(*) FILTER (
            WHERE b.application_id IS NOT NULL
              AND ch.application_id IS NOT NULL
        ) AS matched_application_id_count,

        COUNT(*) FILTER (
            WHERE b.application_id IS NOT NULL
              AND ch.application_id IS NULL
        ) AS baseline_only_application_id_count,

        COUNT(*) FILTER (
            WHERE b.application_id IS NULL
              AND ch.application_id IS NOT NULL
        ) AS challenger_only_application_id_count

    FROM baseline_applications b

    FULL OUTER JOIN challenger_applications ch
        ON ch.comparison_group_id = b.comparison_group_id
       AND ch.application_id = b.application_id

    GROUP BY COALESCE(b.comparison_group_id, ch.comparison_group_id)
),

comparison_readiness AS (
    SELECT
        c.comparison_group_id,

        s.expected_module1_source_rows,
        s.expected_module1_distinct_application_id_count,

        COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
        COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

        COALESCE(b.distinct_application_id_count, 0)
            AS baseline_distinct_application_id_count,

        COALESCE(ch.distinct_application_id_count, 0)
            AS challenger_distinct_application_id_count,

        COALESCE(o.matched_application_id_count, 0)
            AS matched_application_id_count,

        COALESCE(o.baseline_only_application_id_count, 0)
            AS baseline_only_application_id_count,

        COALESCE(o.challenger_only_application_id_count, 0)
            AS challenger_only_application_id_count,

        CASE
            WHEN s.expected_module1_source_rows IS NULL
                THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

            WHEN s.expected_module1_source_rows <> s.expected_module1_distinct_application_id_count
                THEN 'REVIEW_MODULE1_SOURCE_APPLICATION_ID_GRAIN'

            WHEN COALESCE(b.archived_rows, 0) = 0
              OR COALESCE(ch.archived_rows, 0) = 0
                THEN 'REVIEW_COMPARISON_ARCHIVE_MISSING_SLICE'

            WHEN COALESCE(b.archived_rows, 0) <> s.expected_module1_source_rows
              OR COALESCE(ch.archived_rows, 0) <> s.expected_module1_source_rows
              OR COALESCE(b.distinct_application_id_count, 0) <> s.expected_module1_source_rows
              OR COALESCE(ch.distinct_application_id_count, 0) <> s.expected_module1_source_rows
                THEN 'REVIEW_COMPARISON_ARCHIVE_ROW_COUNT_OR_GRAIN'

            WHEN COALESCE(o.matched_application_id_count, 0) <> s.expected_module1_source_rows
              OR COALESCE(o.baseline_only_application_id_count, 0) <> 0
              OR COALESCE(o.challenger_only_application_id_count, 0) <> 0
                THEN 'REVIEW_COMPARISON_APPLICATION_OVERLAP'

            ELSE 'READY_FOR_MATCHED_COMPARISON'
        END AS comparison_readiness_status

    FROM counteroffer_first_comparisons c

    LEFT JOIN module1_source_counts s
        ON s.module1_scenario_set_name = c.module1_scenario_set_name
       AND s.module1_scenario_name = c.module1_scenario_name
       AND s.population_id = c.population_id

    LEFT JOIN archive_counts b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id

    LEFT JOIN archive_counts ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id

    LEFT JOIN comparison_overlap o
        ON o.comparison_group_id = c.comparison_group_id
),

counteroffer_metrics AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
        ) AS preliminary_counteroffer_count,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS TRUE
        ) AS feasible_counteroffer_count,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
        ) AS failed_counteroffer_count,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS TRUE
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER'),
            0
        ) AS counteroffer_feasibility_pass_rate,

        AVG(exposure_reduction_pct) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_exposure_reduction_pct_for_final_counteroffers,

        SUM(exposure_reduction_amount) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS total_counteroffer_exposure_reduction_amount,

        AVG(requested_payment_to_income_ratio) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_requested_pti_for_final_counteroffers,

        AVG(approved_payment_to_income_ratio) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_approved_pti_for_final_counteroffers,

        AVG(requested_expected_loss_amount) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_requested_expected_loss_for_final_counteroffers,

        AVG(approved_expected_loss_amount) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_approved_el_for_final_counteroffers,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate

    FROM credit_decisioning_sim.strategy_decisions_archive

    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
)

SELECT
    c.comparison_group_id,
    c.comparison_set_name,
    c.showcase_id,
    c.showcase_name,

    c.baseline_module2_run_id,
    c.challenger_module2_run_id,

    c.module1_scenario_set_name,
    c.module1_scenario_name,
    c.population_id,

    cr.expected_module1_source_rows,
    cr.baseline_archived_rows,
    cr.challenger_archived_rows,
    cr.matched_application_id_count,
    cr.baseline_only_application_id_count,
    cr.challenger_only_application_id_count,
    cr.comparison_readiness_status,

    c.expected_comparison_storyline,
    c.primary_metric_focus,

    b.applications AS baseline_applications,
    ch.applications AS challenger_applications,

    b.approval_rate AS baseline_approval_rate,
    ch.approval_rate AS counteroffer_first_approval_rate,
    ch.approval_rate - b.approval_rate AS delta_approval_rate,

    b.counteroffer_count AS baseline_counteroffer_count,
    ch.counteroffer_count AS counteroffer_first_counteroffer_count,
    ch.counteroffer_count - b.counteroffer_count AS delta_counteroffer_count,

    b.counteroffer_rate AS baseline_counteroffer_rate,
    ch.counteroffer_rate AS counteroffer_first_counteroffer_rate,
    ch.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

    b.preliminary_counteroffer_count AS baseline_preliminary_counteroffer_count,
    ch.preliminary_counteroffer_count AS counteroffer_first_preliminary_counteroffer_count,
    ch.preliminary_counteroffer_count - b.preliminary_counteroffer_count
        AS delta_preliminary_counteroffer_count,

    b.feasible_counteroffer_count AS baseline_feasible_counteroffer_count,
    ch.feasible_counteroffer_count AS counteroffer_first_feasible_counteroffer_count,
    ch.feasible_counteroffer_count - b.feasible_counteroffer_count
        AS delta_feasible_counteroffer_count,

    b.failed_counteroffer_count AS baseline_failed_counteroffer_count,
    ch.failed_counteroffer_count AS counteroffer_first_failed_counteroffer_count,
    ch.failed_counteroffer_count - b.failed_counteroffer_count
        AS delta_failed_counteroffer_count,

    b.counteroffer_feasibility_pass_rate AS baseline_counteroffer_feasibility_pass_rate,
    ch.counteroffer_feasibility_pass_rate AS counteroffer_first_feasibility_pass_rate,
    ch.counteroffer_feasibility_pass_rate - b.counteroffer_feasibility_pass_rate
        AS delta_counteroffer_feasibility_pass_rate,

    b.avg_exposure_reduction_pct_for_final_counteroffers
        AS baseline_avg_exposure_reduction_pct_for_final_counteroffers,

    ch.avg_exposure_reduction_pct_for_final_counteroffers
        AS counteroffer_first_avg_exposure_reduction_pct_for_final_counteroffers,

    ch.avg_exposure_reduction_pct_for_final_counteroffers
        - b.avg_exposure_reduction_pct_for_final_counteroffers
        AS delta_avg_exposure_reduction_pct_for_final_counteroffers,

    b.total_counteroffer_exposure_reduction_amount
        AS baseline_total_counteroffer_exposure_reduction_amount,

    ch.total_counteroffer_exposure_reduction_amount
        AS counteroffer_first_total_counteroffer_exposure_reduction_amount,

    COALESCE(ch.total_counteroffer_exposure_reduction_amount, 0)
        - COALESCE(b.total_counteroffer_exposure_reduction_amount, 0)
        AS delta_total_counteroffer_exposure_reduction_amount,

    b.avg_approved_pti_for_final_counteroffers
        AS baseline_avg_approved_pti_for_final_counteroffers,

    ch.avg_approved_pti_for_final_counteroffers
        AS counteroffer_first_avg_approved_pti_for_final_counteroffers,

    ch.avg_approved_pti_for_final_counteroffers
        - b.avg_approved_pti_for_final_counteroffers
        AS delta_avg_approved_pti_for_final_counteroffers,

    b.avg_approved_el_for_final_counteroffers
        AS baseline_avg_approved_el_for_final_counteroffers,

    ch.avg_approved_el_for_final_counteroffers
        AS counteroffer_first_avg_approved_el_for_final_counteroffers,

    ch.avg_approved_el_for_final_counteroffers
        - b.avg_approved_el_for_final_counteroffers
        AS delta_avg_approved_el_for_final_counteroffers,

    b.total_approved_amount AS baseline_total_approved_amount,
    ch.total_approved_amount AS counteroffer_first_total_approved_amount,
    ch.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount AS counteroffer_first_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    ch.approved_expected_loss_rate AS counteroffer_first_approved_expected_loss_rate,
    ch.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    CASE
        WHEN cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN ch.counteroffer_rate >= b.counteroffer_rate
         AND COALESCE(ch.total_counteroffer_exposure_reduction_amount, 0)
             >= COALESCE(b.total_counteroffer_exposure_reduction_amount, 0)
         AND (
                b.avg_approved_pti_for_final_counteroffers IS NULL
             OR ch.avg_approved_pti_for_final_counteroffers IS NULL
             OR ch.avg_approved_pti_for_final_counteroffers
                <= b.avg_approved_pti_for_final_counteroffers
         )
            THEN 'COUNTEROFFER_FIRST_EFFECT_VISIBLE'

        ELSE 'REVIEW_COUNTEROFFER_FIRST_EFFECT'
    END AS counteroffer_first_strategy_effect_status

FROM counteroffer_first_comparisons c

LEFT JOIN comparison_readiness cr
    ON cr.comparison_group_id = c.comparison_group_id

LEFT JOIN counteroffer_metrics b
    ON b.strategy_set_name = c.baseline_strategy_set_name
   AND b.strategy_name = c.baseline_strategy_name
   AND b.strategy_version = c.baseline_strategy_version
   AND b.module1_scenario_set_name = c.module1_scenario_set_name
   AND b.module1_scenario_name = c.module1_scenario_name
   AND b.population_id = c.population_id

LEFT JOIN counteroffer_metrics ch
    ON ch.strategy_set_name = c.challenger_strategy_set_name
   AND ch.strategy_name = c.challenger_strategy_name
   AND ch.strategy_version = c.challenger_strategy_version
   AND ch.module1_scenario_set_name = c.module1_scenario_set_name
   AND ch.module1_scenario_name = c.module1_scenario_name
   AND ch.population_id = c.population_id

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.18 — PARAMETER SNAPSHOT PROFILE AUDIT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that every active campaign registry run has exactly one parameter snapshot and that the
    snapshot contains the strategy, product-policy, and run-story payloads needed for governance and
    documentation.

    Section 17.18 answers:

        "Did Section 16 preserve the parameter configuration for every active campaign run?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    Persistent parameter snapshots may contain ad hoc or historical development runs.

    Section 17 evaluates active campaign registry runs.

EXPECTED RESULT:
    One row per active campaign registry run.

    Each row should generally show:
        parameter_snapshot_rows_for_run = 1
        strategy_params_captured_flag = TRUE
        product_policy_params_captured_flag = TRUE
        run_story_params_captured_flag = TRUE
        parameter_snapshot_hash_captured_flag = TRUE
        parameter_snapshot_status = PARAMETER_SNAPSHOT_READY

***************************************************************************************************/

WITH active_campaign_runs AS (
    SELECT
        module1_run_id,
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

parameter_snapshot_ranked AS (
    SELECT
        p.*,

        COUNT(*) OVER (
            PARTITION BY
                module2_run_id,
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        ) AS parameter_snapshot_rows_for_run,

        ROW_NUMBER() OVER (
            PARTITION BY
                module2_run_id,
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY evidence_snapshot_ts DESC NULLS LAST
        ) AS parameter_snapshot_row_rank
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot p
)

SELECT
    r.run_sequence_number,
    r.module1_run_id,
    r.module2_run_id,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    r.strategy_name,
    r.strategy_version,

    COALESCE(p.parameter_snapshot_rows_for_run, 0) AS parameter_snapshot_rows_for_run,

    p.evidence_snapshot_ts,
    p.evidence_snapshot_id,

    p.run_registry_match_status,

    p.strategy_params_jsonb IS NOT NULL
        AS strategy_params_captured_flag,

    p.product_policy_params_jsonb IS NOT NULL
        AS product_policy_params_captured_flag,

    CASE
        WHEN p.product_policy_params_jsonb IS NULL THEN NULL
        WHEN jsonb_typeof(p.product_policy_params_jsonb) = 'array'
            THEN jsonb_array_length(p.product_policy_params_jsonb)
        ELSE NULL
    END AS product_policy_snapshot_row_count,

    p.run_story_params_jsonb IS NOT NULL
        AS run_story_params_captured_flag,

    p.parameter_snapshot_hash IS NOT NULL
        AS parameter_snapshot_hash_captured_flag,

    p.parameter_snapshot_hash,

    CASE
        WHEN COALESCE(p.parameter_snapshot_rows_for_run, 0) = 0
            THEN 'PARAMETER_SNAPSHOT_MISSING'

        WHEN COALESCE(p.parameter_snapshot_rows_for_run, 0) > 1
            THEN 'DUPLICATE_PARAMETER_SNAPSHOT_REVIEW_REQUIRED'

        WHEN p.strategy_params_jsonb IS NULL
          OR p.product_policy_params_jsonb IS NULL
          OR p.run_story_params_jsonb IS NULL
          OR p.parameter_snapshot_hash IS NULL
            THEN 'PARAMETER_PAYLOAD_REVIEW_REQUIRED'

        WHEN jsonb_typeof(p.product_policy_params_jsonb) <> 'array'
          OR jsonb_array_length(p.product_policy_params_jsonb) = 0
            THEN 'PRODUCT_POLICY_PAYLOAD_REVIEW_REQUIRED'

        WHEN p.module2_run_id IS DISTINCT FROM r.module2_run_id
          OR p.run_sequence_number IS DISTINCT FROM r.run_sequence_number
          OR p.module1_run_id IS DISTINCT FROM r.module1_run_id
          OR p.showcase_id IS DISTINCT FROM r.showcase_id
          OR p.comparison_group_id IS DISTINCT FROM r.comparison_group_id
          OR p.validation_evidence_group_id IS DISTINCT FROM r.validation_evidence_group_id
            THEN 'PARAMETER_SOURCE_LINEAGE_REVIEW_REQUIRED'

        ELSE 'PARAMETER_SNAPSHOT_READY'
    END AS parameter_snapshot_status

FROM active_campaign_runs r

LEFT JOIN parameter_snapshot_ranked p
    ON p.module2_run_id = r.module2_run_id
   AND p.strategy_set_name = r.strategy_set_name
   AND p.strategy_name = r.strategy_name
   AND p.strategy_version = r.strategy_version
   AND p.module1_scenario_set_name = r.module1_scenario_set_name
   AND p.module1_scenario_name = r.module1_scenario_name
   AND p.population_id = r.population_id
   AND p.parameter_snapshot_row_rank = 1

ORDER BY r.run_sequence_number;



/***************************************************************************************************
SECTION 17.19 — PRODUCT GUARDRAIL POLICY SNAPSHOT EXACT-VALUE AUDIT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that active campaign PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs captured the intended
    canonical product-guardrail values for:

        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

WHY THIS MATTERS:
    Structural campaign acceptance can pass even when a product-policy parameter was populated with
    the wrong value.

    This exact-value audit closes that gap.

WHY THIS SECTION IS REGISTRY-SCOPED:
    The audit starts from active campaign registry rows and then joins to parameter snapshots.

    This prevents historical ad hoc PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY snapshots from inflating the
    active campaign audit.

DYNAMIC EXPECTED ROW COUNT:
    Expected audit rows are derived as:

        active PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY campaign runs
        × audited product count

    The audited product count is currently two:
        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

CANONICAL VALUE BOUNDARY:
    The exact product-policy values below are intentionally fixed because this section validates the
    specific product-guardrail profile design.

***************************************************************************************************/

WITH product_guardrail_campaign_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        strategy_set_name,
        strategy_name,
        strategy_version
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
      AND strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),

parameter_snapshots_by_run AS (
    SELECT
        module2_run_id,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS parameter_snapshot_rows_for_run,

        (ARRAY_AGG(product_policy_params_jsonb ORDER BY evidence_snapshot_ts DESC NULLS LAST))[1]
            AS product_policy_params_jsonb

    FROM credit_decisioning_sim.strategy_run_parameter_snapshot

    GROUP BY
        module2_run_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

product_guardrail_runs AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        COALESCE(p.parameter_snapshot_rows_for_run, 0)
            AS parameter_snapshot_rows_for_run,

        p.product_policy_params_jsonb

    FROM product_guardrail_campaign_runs r

    LEFT JOIN parameter_snapshots_by_run p
        ON p.module2_run_id = r.module2_run_id
       AND p.strategy_set_name = r.strategy_set_name
       AND p.strategy_name = r.strategy_name
       AND p.strategy_version = r.strategy_version
       AND p.module1_scenario_set_name = r.module1_scenario_set_name
       AND p.module1_scenario_name = r.module1_scenario_name
       AND p.population_id = r.population_id
),

expected_product_guardrail_policy AS (
    SELECT *
    FROM (
        VALUES
            (
                'UNSECURED_PERSONAL_LOAN'::TEXT,
                0.130000::NUMERIC,
                0.220000::NUMERIC,
                0.320000::NUMERIC,
                0.110000::NUMERIC,
                2500.00::NUMERIC,
                5000.00::NUMERIC,
                8500.00::NUMERIC,
                2000.00::NUMERIC,
                1000.00::NUMERIC,
                27500.00::NUMERIC,
                0.500000::NUMERIC,
                0.500000::NUMERIC
            ),
            (
                'REVOLVING_LINE'::TEXT,
                0.100000::NUMERIC,
                0.180000::NUMERIC,
                0.280000::NUMERIC,
                0.080000::NUMERIC,
                1500.00::NUMERIC,
                3200.00::NUMERIC,
                6500.00::NUMERIC,
                1400.00::NUMERIC,
                1000.00::NUMERIC,
                16000.00::NUMERIC,
                0.500000::NUMERIC,
                0.500000::NUMERIC
            )
    ) AS v(
        product_type,
        expected_product_approve_max_pti,
        expected_product_review_max_pti,
        expected_product_decline_min_pti,
        expected_counteroffer_target_pti,
        expected_product_approve_max_requested_el,
        expected_product_review_max_requested_el,
        expected_product_decline_min_requested_el,
        expected_product_approved_el_cap,
        expected_product_min_approved_amount,
        expected_product_max_approved_amount,
        expected_product_min_counteroffer_pct,
        expected_product_max_exposure_reduction_pct
    )
),

expected_run_product_rows AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        r.strategy_name,
        r.strategy_version,

        r.parameter_snapshot_rows_for_run,

        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy_raw AS (
    SELECT
        r.module2_run_id,

        pp.product_policy_row ->> 'product_type' AS product_type,

        (pp.product_policy_row ->> 'product_approve_max_pti')::NUMERIC
            AS actual_product_approve_max_pti,

        (pp.product_policy_row ->> 'product_review_max_pti')::NUMERIC
            AS actual_product_review_max_pti,

        (pp.product_policy_row ->> 'product_decline_min_pti')::NUMERIC
            AS actual_product_decline_min_pti,

        (pp.product_policy_row ->> 'counteroffer_target_pti')::NUMERIC
            AS actual_counteroffer_target_pti,

        (pp.product_policy_row ->> 'product_approve_max_requested_el')::NUMERIC
            AS actual_product_approve_max_requested_el,

        (pp.product_policy_row ->> 'product_review_max_requested_el')::NUMERIC
            AS actual_product_review_max_requested_el,

        (pp.product_policy_row ->> 'product_decline_min_requested_el')::NUMERIC
            AS actual_product_decline_min_requested_el,

        (pp.product_policy_row ->> 'product_approved_el_cap')::NUMERIC
            AS actual_product_approved_el_cap,

        (pp.product_policy_row ->> 'product_min_approved_amount')::NUMERIC
            AS actual_product_min_approved_amount,

        (pp.product_policy_row ->> 'product_max_approved_amount')::NUMERIC
            AS actual_product_max_approved_amount,

        (pp.product_policy_row ->> 'product_min_counteroffer_pct')::NUMERIC
            AS actual_product_min_counteroffer_pct,

        (pp.product_policy_row ->> 'product_max_exposure_reduction_pct')::NUMERIC
            AS actual_product_max_exposure_reduction_pct

    FROM product_guardrail_runs r

    CROSS JOIN LATERAL jsonb_array_elements(
        COALESCE(r.product_policy_params_jsonb, '[]'::jsonb)
    ) AS pp(product_policy_row)

    WHERE pp.product_policy_row ->> 'product_type' IN (
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    )
),

actual_product_guardrail_policy AS (
    SELECT
        module2_run_id,
        product_type,

        COUNT(*) AS actual_product_policy_rows_for_product,

        MAX(actual_product_approve_max_pti) AS actual_product_approve_max_pti,
        MAX(actual_product_review_max_pti) AS actual_product_review_max_pti,
        MAX(actual_product_decline_min_pti) AS actual_product_decline_min_pti,
        MAX(actual_counteroffer_target_pti) AS actual_counteroffer_target_pti,

        MAX(actual_product_approve_max_requested_el) AS actual_product_approve_max_requested_el,
        MAX(actual_product_review_max_requested_el) AS actual_product_review_max_requested_el,
        MAX(actual_product_decline_min_requested_el) AS actual_product_decline_min_requested_el,
        MAX(actual_product_approved_el_cap) AS actual_product_approved_el_cap,

        MAX(actual_product_min_approved_amount) AS actual_product_min_approved_amount,
        MAX(actual_product_max_approved_amount) AS actual_product_max_approved_amount,
        MAX(actual_product_min_counteroffer_pct) AS actual_product_min_counteroffer_pct,
        MAX(actual_product_max_exposure_reduction_pct) AS actual_product_max_exposure_reduction_pct

    FROM actual_product_guardrail_policy_raw

    GROUP BY
        module2_run_id,
        product_type
),

policy_comparison AS (
    SELECT
        e.*,

        COALESCE(a.actual_product_policy_rows_for_product, 0)
            AS actual_product_policy_rows_for_product,

        a.actual_product_approve_max_pti,
        a.actual_product_review_max_pti,
        a.actual_product_decline_min_pti,
        a.actual_counteroffer_target_pti,

        a.actual_product_approve_max_requested_el,
        a.actual_product_review_max_requested_el,
        a.actual_product_decline_min_requested_el,
        a.actual_product_approved_el_cap,

        a.actual_product_min_approved_amount,
        a.actual_product_max_approved_amount,
        a.actual_product_min_counteroffer_pct,
        a.actual_product_max_exposure_reduction_pct,

        CASE
            WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1
                THEN NULL

            ELSE
                (
                    CASE WHEN a.actual_product_approve_max_pti IS DISTINCT FROM e.expected_product_approve_max_pti THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_review_max_pti IS DISTINCT FROM e.expected_product_review_max_pti THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_decline_min_pti IS DISTINCT FROM e.expected_product_decline_min_pti THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_counteroffer_target_pti IS DISTINCT FROM e.expected_counteroffer_target_pti THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_approve_max_requested_el IS DISTINCT FROM e.expected_product_approve_max_requested_el THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_review_max_requested_el IS DISTINCT FROM e.expected_product_review_max_requested_el THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_decline_min_requested_el IS DISTINCT FROM e.expected_product_decline_min_requested_el THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_approved_el_cap IS DISTINCT FROM e.expected_product_approved_el_cap THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_min_approved_amount IS DISTINCT FROM e.expected_product_min_approved_amount THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_max_approved_amount IS DISTINCT FROM e.expected_product_max_approved_amount THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_min_counteroffer_pct IS DISTINCT FROM e.expected_product_min_counteroffer_pct THEN 1 ELSE 0 END
                  + CASE WHEN a.actual_product_max_exposure_reduction_pct IS DISTINCT FROM e.expected_product_max_exposure_reduction_pct THEN 1 ELSE 0 END
                )
        END AS product_policy_field_mismatch_count

    FROM expected_run_product_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
)

SELECT
    module2_run_id,
    run_sequence_number,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_name,
    strategy_version,

    parameter_snapshot_rows_for_run,

    product_type,

    actual_product_policy_rows_for_product,

    expected_product_approve_max_pti,
    actual_product_approve_max_pti,

    expected_product_review_max_pti,
    actual_product_review_max_pti,

    expected_product_decline_min_pti,
    actual_product_decline_min_pti,

    expected_counteroffer_target_pti,
    actual_counteroffer_target_pti,

    expected_product_approve_max_requested_el,
    actual_product_approve_max_requested_el,

    expected_product_review_max_requested_el,
    actual_product_review_max_requested_el,

    expected_product_decline_min_requested_el,
    actual_product_decline_min_requested_el,

    expected_product_approved_el_cap,
    actual_product_approved_el_cap,

    expected_product_min_approved_amount,
    actual_product_min_approved_amount,

    expected_product_max_approved_amount,
    actual_product_max_approved_amount,

    expected_product_min_counteroffer_pct,
    actual_product_min_counteroffer_pct,

    expected_product_max_exposure_reduction_pct,
    actual_product_max_exposure_reduction_pct,

    product_policy_field_mismatch_count,

    CASE
        WHEN parameter_snapshot_rows_for_run = 0
            THEN 'PRODUCT_GUARDRAIL_PARAMETER_SNAPSHOT_MISSING'

        WHEN parameter_snapshot_rows_for_run > 1
            THEN 'PRODUCT_GUARDRAIL_PARAMETER_SNAPSHOT_DUPLICATE_REVIEW_REQUIRED'

        WHEN actual_product_policy_rows_for_product = 0
            THEN 'PRODUCT_GUARDRAIL_POLICY_ROW_MISSING'

        WHEN actual_product_policy_rows_for_product > 1
            THEN 'PRODUCT_GUARDRAIL_POLICY_ROW_DUPLICATE_REVIEW_REQUIRED'

        WHEN product_policy_field_mismatch_count = 0
            THEN 'PRODUCT_GUARDRAIL_POLICY_VALUES_MATCH'

        ELSE 'PRODUCT_GUARDRAIL_POLICY_VALUE_MISMATCH'
    END AS product_guardrail_policy_value_status

FROM policy_comparison

ORDER BY
    run_sequence_number,
    product_type;



/***************************************************************************************************
SECTION 17.20 — FINAL MODULE 2 CAMPAIGN ACCEPTANCE ROLLUP
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the final one-row campaign acceptance status after archive, registry, comparison,
    matched-source, evidence, convention, parameter-snapshot, and product-policy checks.

    Section 17.20 answers:

        "Is the completed active Module 2 campaign structurally ready for executive analysis,
         validation-summary drafting, README interpretation, and LinkedIn storyline development?"

DYNAMIC ACCEPTANCE DESIGN:
    Section 17.20 derives expected campaign shape from active registry and source evidence.

    It does not hardcode:
        campaign run count,
        comparison group count,
        archive rows per slice,
        total archive rows,
        validation evidence row count,
        product-guardrail campaign run count,
        or product-guardrail audit row count.

DERIVED EXPECTATIONS:
    expected_campaign_runs:
        count of active campaign registry rows.

    expected_comparison_groups:
        count of active comparison registry rows.

    expected_total_active_campaign_source_rows:
        sum of selected Module 1 source-population rows across active campaign runs.

    expected_validation_key_count:
        distinct validation_area + validation_test_name + validation_category across active campaign
        validation evidence.

    expected_product_guardrail_policy_rows:
        active PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY campaign runs × audited product count.

CANONICAL PRODUCT-GUARDRAIL VALUE BOUNDARY:
    The UPL and revolving-line exact values remain fixed because the audit validates the intended
    product-guardrail profile.

FINAL STATUS VALUES:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED

    REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS

READ-ONLY BOUNDARY:
    Section 17.20 does not modify archive, latest-run, evidence, registry, strategy-parameter, or
    product-policy rows.

***************************************************************************************************/

WITH active_campaign_runs AS (
    SELECT
        module1_run_id,
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

campaign_registry_summary AS (
    SELECT
        COUNT(*) AS active_campaign_registry_rows,

        COUNT(*) - COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS duplicate_active_campaign_technical_key_rows
    FROM active_campaign_runs
),

active_comparisons AS (
    SELECT
        comparison_group_id,
        comparison_set_name,

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
        challenger_strategy_version
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
),

comparison_registry_summary AS (
    SELECT
        COUNT(*) AS active_comparison_registry_rows,

        COUNT(*) - COUNT(DISTINCT comparison_group_id)
            AS duplicate_active_comparison_group_rows
    FROM active_comparisons
),

module1_source_counts AS (
    SELECT
        scenario_set_name AS module1_scenario_set_name,
        scenario_name AS module1_scenario_name,
        population_id,

        COUNT(*) AS expected_module1_source_rows,
        COUNT(DISTINCT application_id) AS expected_module1_distinct_application_id_count
    FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    GROUP BY
        scenario_set_name,
        scenario_name,
        population_id
),

archive_counts AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS archived_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count
    FROM credit_decisioning_sim.strategy_decisions_archive
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

active_campaign_archive_join AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,
        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        s.expected_module1_source_rows,
        s.expected_module1_distinct_application_id_count,

        COALESCE(a.archived_rows, 0) AS archived_rows,
        COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count

    FROM active_campaign_runs r

    LEFT JOIN module1_source_counts s
        ON s.module1_scenario_set_name = r.module1_scenario_set_name
       AND s.module1_scenario_name = r.module1_scenario_name
       AND s.population_id = r.population_id

    LEFT JOIN archive_counts a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id
),

active_campaign_archive_rows AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,
        a.*
    FROM active_campaign_runs r

    JOIN credit_decisioning_sim.strategy_decisions_archive a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id
),

archive_grain_duplicates AS (
    SELECT
        COUNT(*) AS duplicate_archive_grain_count
    FROM (
        SELECT
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id,
            application_id,
            COUNT(*) AS row_count
        FROM active_campaign_archive_rows
        GROUP BY
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id,
            application_id
        HAVING COUNT(*) > 1
    ) d
),

archive_summary AS (
    SELECT
        COUNT(*) AS active_campaign_registry_rows_for_archive_check,

        COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NULL
        ) AS active_runs_missing_module1_source_count,

        COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND expected_module1_source_rows
                    <> expected_module1_distinct_application_id_count
        ) AS active_runs_with_module1_source_application_id_grain_issue,

        SUM(COALESCE(expected_module1_source_rows, 0))
            AS expected_total_active_campaign_source_rows,

        COUNT(*) FILTER (
            WHERE archived_rows > 0
        ) AS active_runs_with_archive_rows,

        COUNT(*) FILTER (
            WHERE archived_rows = 0
        ) AS active_runs_missing_archive_rows,

        SUM(archived_rows) AS total_active_campaign_archived_rows,

        COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND archived_rows <> expected_module1_source_rows
        ) AS active_runs_with_archive_row_count_mismatch,

        COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND distinct_application_id_count <> expected_module1_source_rows
        ) AS active_runs_with_archive_application_id_grain_issue
    FROM active_campaign_archive_join
),

baseline_applications AS (
    SELECT DISTINCT
        c.comparison_group_id,
        b.application_id
    FROM active_comparisons c

    JOIN credit_decisioning_sim.strategy_decisions_archive b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id
),

challenger_applications AS (
    SELECT DISTINCT
        c.comparison_group_id,
        ch.application_id
    FROM active_comparisons c

    JOIN credit_decisioning_sim.strategy_decisions_archive ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id
),

comparison_application_union AS (
    SELECT
        COALESCE(b.comparison_group_id, ch.comparison_group_id)
            AS comparison_group_id,

        b.application_id AS baseline_application_id,
        ch.application_id AS challenger_application_id

    FROM baseline_applications b

    FULL OUTER JOIN challenger_applications ch
        ON ch.comparison_group_id = b.comparison_group_id
       AND ch.application_id = b.application_id
),

comparison_application_overlap AS (
    SELECT
        comparison_group_id,

        COUNT(*) FILTER (
            WHERE baseline_application_id IS NOT NULL
              AND challenger_application_id IS NOT NULL
        ) AS matched_application_id_count,

        COUNT(*) FILTER (
            WHERE baseline_application_id IS NOT NULL
              AND challenger_application_id IS NULL
        ) AS baseline_only_application_id_count,

        COUNT(*) FILTER (
            WHERE baseline_application_id IS NULL
              AND challenger_application_id IS NOT NULL
        ) AS challenger_only_application_id_count

    FROM comparison_application_union
    GROUP BY comparison_group_id
),

comparison_readiness_by_group AS (
    SELECT
        c.comparison_group_id,

        s.expected_module1_source_rows,
        s.expected_module1_distinct_application_id_count,

        COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
        COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

        COALESCE(b.distinct_application_id_count, 0)
            AS baseline_distinct_application_id_count,

        COALESCE(ch.distinct_application_id_count, 0)
            AS challenger_distinct_application_id_count,

        COALESCE(o.matched_application_id_count, 0)
            AS matched_application_id_count,

        COALESCE(o.baseline_only_application_id_count, 0)
            AS baseline_only_application_id_count,

        COALESCE(o.challenger_only_application_id_count, 0)
            AS challenger_only_application_id_count,

        CASE
            WHEN s.expected_module1_source_rows IS NULL
                THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

            WHEN s.expected_module1_source_rows
                    <> s.expected_module1_distinct_application_id_count
                THEN 'REVIEW_MODULE1_SOURCE_APPLICATION_ID_GRAIN'

            WHEN COALESCE(b.archived_rows, 0) = 0
              OR COALESCE(ch.archived_rows, 0) = 0
                THEN 'REVIEW_COMPARISON_ARCHIVE_MISSING_SLICE'

            WHEN COALESCE(b.archived_rows, 0) <> s.expected_module1_source_rows
              OR COALESCE(ch.archived_rows, 0) <> s.expected_module1_source_rows
              OR COALESCE(b.distinct_application_id_count, 0) <> s.expected_module1_source_rows
              OR COALESCE(ch.distinct_application_id_count, 0) <> s.expected_module1_source_rows
                THEN 'REVIEW_COMPARISON_ARCHIVE_ROW_COUNT_OR_GRAIN'

            WHEN COALESCE(o.matched_application_id_count, 0) <> s.expected_module1_source_rows
              OR COALESCE(o.baseline_only_application_id_count, 0) <> 0
              OR COALESCE(o.challenger_only_application_id_count, 0) <> 0
                THEN 'REVIEW_COMPARISON_APPLICATION_OVERLAP'

            ELSE 'READY_FOR_MATCHED_COMPARISON'
        END AS comparison_readiness_status

    FROM active_comparisons c

    LEFT JOIN module1_source_counts s
        ON s.module1_scenario_set_name = c.module1_scenario_set_name
       AND s.module1_scenario_name = c.module1_scenario_name
       AND s.population_id = c.population_id

    LEFT JOIN archive_counts b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id

    LEFT JOIN archive_counts ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id

    LEFT JOIN comparison_application_overlap o
        ON o.comparison_group_id = c.comparison_group_id
),

comparison_readiness_summary AS (
    SELECT
        COUNT(*) AS comparison_group_count,

        COUNT(*) FILTER (
            WHERE comparison_readiness_status = 'READY_FOR_MATCHED_COMPARISON'
        ) AS comparison_ready_count,

        COUNT(*) FILTER (
            WHERE comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
        ) AS comparison_review_count
    FROM comparison_readiness_by_group
),

matched_source_rows AS (
    SELECT
        c.comparison_group_id,

        b.application_id,

        b.product_type_policy_key AS baseline_product_type_policy_key,
        ch.product_type_policy_key AS challenger_product_type_policy_key,

        b.score_band_policy_key AS baseline_score_band_policy_key,
        ch.score_band_policy_key AS challenger_score_band_policy_key,

        b.credit_score AS baseline_credit_score,
        ch.credit_score AS challenger_credit_score,

        b.annual_income AS baseline_annual_income,
        ch.annual_income AS challenger_annual_income,

        b.requested_amount AS baseline_requested_amount,
        ch.requested_amount AS challenger_requested_amount,

        b.requested_monthly_payment_proxy AS baseline_requested_monthly_payment_proxy,
        ch.requested_monthly_payment_proxy AS challenger_requested_monthly_payment_proxy,

        b.requested_payment_to_income_ratio AS baseline_requested_payment_to_income_ratio,
        ch.requested_payment_to_income_ratio AS challenger_requested_payment_to_income_ratio,

        b.amount_to_income_ratio AS baseline_amount_to_income_ratio,
        ch.amount_to_income_ratio AS challenger_amount_to_income_ratio,

        b.estimated_pd AS baseline_estimated_pd,
        ch.estimated_pd AS challenger_estimated_pd,

        b.estimated_lgd AS baseline_estimated_lgd,
        ch.estimated_lgd AS challenger_estimated_lgd,

        b.requested_expected_loss_amount AS baseline_requested_expected_loss_amount,
        ch.requested_expected_loss_amount AS challenger_requested_expected_loss_amount,

        b.module1_scenario_set_name AS baseline_module1_scenario_set_name,
        ch.module1_scenario_set_name AS challenger_module1_scenario_set_name,

        b.module1_scenario_name AS baseline_module1_scenario_name,
        ch.module1_scenario_name AS challenger_module1_scenario_name,

        b.population_id AS baseline_population_id,
        ch.population_id AS challenger_population_id

    FROM active_comparisons c

    JOIN credit_decisioning_sim.strategy_decisions_archive b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id

    JOIN credit_decisioning_sim.strategy_decisions_archive ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id
       AND ch.application_id = b.application_id
),

source_consistency_by_group AS (
    SELECT
        comparison_group_id,

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
        ) AS source_field_mismatch_count

    FROM matched_source_rows
    GROUP BY comparison_group_id
),

source_consistency_summary AS (
    SELECT
        COUNT(*) AS source_consistency_group_count,

        COUNT(*) FILTER (
            WHERE cr.comparison_readiness_status = 'READY_FOR_MATCHED_COMPARISON'
              AND COALESCE(sc.matched_application_count, 0) = cr.expected_module1_source_rows
              AND COALESCE(sc.source_field_mismatch_count, 0) = 0
        ) AS source_consistency_pass_count,

        COUNT(*) FILTER (
            WHERE cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
               OR COALESCE(sc.matched_application_count, 0) <> cr.expected_module1_source_rows
               OR COALESCE(sc.source_field_mismatch_count, 0) <> 0
        ) AS source_consistency_review_count,

        COALESCE(SUM(COALESCE(sc.source_field_mismatch_count, 0)), 0)::BIGINT
            AS total_source_field_mismatch_rows

    FROM comparison_readiness_by_group cr

    LEFT JOIN source_consistency_by_group sc
        ON sc.comparison_group_id = cr.comparison_group_id
),

executive_evidence_by_run AS (
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

parameter_evidence_by_run AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS parameter_snapshot_rows
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

validation_key_catalog AS (
    SELECT
        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS expected_validation_key_count
    FROM active_campaign_runs r

    JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id
),

validation_evidence_by_run AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS validation_rows,

        COUNT(DISTINCT (
            validation_area,
            validation_test_name,
            validation_category
        )) AS validation_distinct_key_count,

        COUNT(*) - COUNT(DISTINCT (
            validation_area,
            validation_test_name,
            validation_category
        )) AS duplicate_validation_key_rows
    FROM credit_decisioning_sim.strategy_run_validation_evidence
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

archive_segment_expected AS (
    SELECT
        r.module2_run_id,

        COUNT(DISTINCT (
            a.product_type_policy_key,
            a.score_band_policy_key,
            a.product_score_policy_segment
        )) AS expected_segment_rows
    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id

    GROUP BY r.module2_run_id
),

segment_evidence_by_run AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS segment_rows,

        COUNT(DISTINCT (
            product_type_policy_key,
            score_band_policy_key,
            product_score_policy_segment
        )) AS segment_distinct_key_count,

        COUNT(*) - COUNT(DISTINCT (
            product_type_policy_key,
            score_band_policy_key,
            product_score_policy_segment
        )) AS duplicate_segment_key_rows
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

evidence_by_campaign_run AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(p.parameter_snapshot_rows, 0) AS parameter_snapshot_rows,

        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(v.validation_distinct_key_count, 0) AS validation_distinct_key_count,
        COALESCE(v.duplicate_validation_key_rows, 0) AS duplicate_validation_key_rows,

        COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,

        COALESCE(ase.expected_segment_rows, 0) AS expected_segment_rows,
        COALESCE(s.segment_rows, 0) AS segment_rows,
        COALESCE(s.segment_distinct_key_count, 0) AS segment_distinct_key_count,
        COALESCE(s.duplicate_segment_key_rows, 0) AS duplicate_segment_key_rows

    FROM active_campaign_runs r

    CROSS JOIN validation_key_catalog vkc

    LEFT JOIN archive_segment_expected ase
        ON ase.module2_run_id = r.module2_run_id

    LEFT JOIN executive_evidence_by_run e
        ON e.strategy_set_name = r.strategy_set_name
       AND e.strategy_name = r.strategy_name
       AND e.strategy_version = r.strategy_version
       AND e.module1_scenario_set_name = r.module1_scenario_set_name
       AND e.module1_scenario_name = r.module1_scenario_name
       AND e.population_id = r.population_id

    LEFT JOIN parameter_evidence_by_run p
        ON p.strategy_set_name = r.strategy_set_name
       AND p.strategy_name = r.strategy_name
       AND p.strategy_version = r.strategy_version
       AND p.module1_scenario_set_name = r.module1_scenario_set_name
       AND p.module1_scenario_name = r.module1_scenario_name
       AND p.population_id = r.population_id

    LEFT JOIN validation_evidence_by_run v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    LEFT JOIN segment_evidence_by_run s
        ON s.strategy_set_name = r.strategy_set_name
       AND s.strategy_name = r.strategy_name
       AND s.strategy_version = r.strategy_version
       AND s.module1_scenario_set_name = r.module1_scenario_set_name
       AND s.module1_scenario_name = r.module1_scenario_name
       AND s.population_id = r.population_id
),

evidence_summary AS (
    SELECT
        COUNT(*) AS registry_run_count_for_evidence_check,

        MAX(expected_validation_key_count)
            AS expected_validation_key_count,

        COALESCE(SUM(executive_rows), 0)::BIGINT AS executive_evidence_rows,

        COUNT(*) FILTER (
            WHERE executive_rows = 1
        ) AS executive_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE executive_rows <> 1
        ) AS executive_evidence_issue_run_count,

        COALESCE(SUM(parameter_snapshot_rows), 0)::BIGINT
            AS parameter_snapshot_rows,

        COUNT(*) FILTER (
            WHERE parameter_snapshot_rows = 1
        ) AS parameter_snapshot_complete_run_count,

        COUNT(*) FILTER (
            WHERE parameter_snapshot_rows <> 1
        ) AS parameter_snapshot_issue_run_count,

        COUNT(*) FILTER (
            WHERE expected_validation_key_count > 0
              AND validation_rows = expected_validation_key_count
              AND validation_distinct_key_count = expected_validation_key_count
              AND duplicate_validation_key_rows = 0
        ) AS validation_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE expected_validation_key_count = 0
               OR validation_rows <> expected_validation_key_count
               OR validation_distinct_key_count <> expected_validation_key_count
               OR duplicate_validation_key_rows <> 0
        ) AS validation_evidence_incomplete_run_count,

        MIN(validation_rows) AS min_validation_rows_per_run,
        MAX(validation_rows) AS max_validation_rows_per_run,
        COALESCE(SUM(validation_rows), 0)::BIGINT
            AS total_validation_evidence_rows,

        COUNT(*) FILTER (
            WHERE expected_segment_rows > 0
              AND segment_rows = expected_segment_rows
              AND segment_distinct_key_count = expected_segment_rows
              AND duplicate_segment_key_rows = 0
        ) AS segment_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE expected_segment_rows = 0
               OR segment_rows <> expected_segment_rows
               OR segment_distinct_key_count <> expected_segment_rows
               OR duplicate_segment_key_rows <> 0
        ) AS segment_evidence_issue_run_count,

        MIN(expected_segment_rows) AS min_expected_segment_rows_per_run,
        MAX(expected_segment_rows) AS max_expected_segment_rows_per_run,
        MIN(segment_rows) AS min_segment_rows_per_run,
        MAX(segment_rows) AS max_segment_rows_per_run,
        COALESCE(SUM(segment_rows), 0)::BIGINT
            AS total_segment_evidence_rows
    FROM evidence_by_campaign_run
),

convention_violations AS (
    SELECT
        COUNT(*) AS active_campaign_archived_rows,

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

    FROM active_campaign_archive_rows
),

convention_summary AS (
    SELECT
        active_campaign_archived_rows,

        (
            final_outcome_flag_count_violation_rows
            + simulated_offer_exposure_flag_violation_rows
            + approve_amount_violation_rows
            + counteroffer_amount_violation_rows
            + manual_review_amount_violation_rows
            + decline_amount_violation_rows
            + approve_payment_violation_rows
            + counteroffer_affordability_violation_rows
            + manual_review_affordability_violation_rows
            + decline_affordability_violation_rows
            + approve_expected_loss_violation_rows
            + counteroffer_expected_loss_violation_rows
            + manual_review_expected_loss_violation_rows
            + decline_expected_loss_violation_rows
            + reason_code_completeness_violation_rows
            + reason_family_alignment_violation_rows
        ) AS critical_convention_violation_count
    FROM convention_violations
),

product_guardrail_campaign_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM active_campaign_runs
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),

parameter_snapshots_by_run AS (
    SELECT
        module2_run_id,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS parameter_snapshot_rows_for_run,

        (ARRAY_AGG(product_policy_params_jsonb ORDER BY evidence_snapshot_ts DESC NULLS LAST))[1]
            AS product_policy_params_jsonb

    FROM credit_decisioning_sim.strategy_run_parameter_snapshot

    GROUP BY
        module2_run_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

product_guardrail_runs AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        COALESCE(p.parameter_snapshot_rows_for_run, 0)
            AS parameter_snapshot_rows_for_run,

        p.product_policy_params_jsonb

    FROM product_guardrail_campaign_runs r

    LEFT JOIN parameter_snapshots_by_run p
        ON p.module2_run_id = r.module2_run_id
       AND p.strategy_set_name = r.strategy_set_name
       AND p.strategy_name = r.strategy_name
       AND p.strategy_version = r.strategy_version
       AND p.module1_scenario_set_name = r.module1_scenario_set_name
       AND p.module1_scenario_name = r.module1_scenario_name
       AND p.population_id = r.population_id
),

expected_product_guardrail_policy AS (
    SELECT *
    FROM (
        VALUES
            (
                'UNSECURED_PERSONAL_LOAN'::TEXT,
                0.130000::NUMERIC,
                0.220000::NUMERIC,
                0.320000::NUMERIC,
                0.110000::NUMERIC,
                2500.00::NUMERIC,
                5000.00::NUMERIC,
                8500.00::NUMERIC,
                2000.00::NUMERIC,
                1000.00::NUMERIC,
                27500.00::NUMERIC,
                0.500000::NUMERIC,
                0.500000::NUMERIC
            ),
            (
                'REVOLVING_LINE'::TEXT,
                0.100000::NUMERIC,
                0.180000::NUMERIC,
                0.280000::NUMERIC,
                0.080000::NUMERIC,
                1500.00::NUMERIC,
                3200.00::NUMERIC,
                6500.00::NUMERIC,
                1400.00::NUMERIC,
                1000.00::NUMERIC,
                16000.00::NUMERIC,
                0.500000::NUMERIC,
                0.500000::NUMERIC
            )
    ) AS v(
        product_type,
        expected_product_approve_max_pti,
        expected_product_review_max_pti,
        expected_product_decline_min_pti,
        expected_counteroffer_target_pti,
        expected_product_approve_max_requested_el,
        expected_product_review_max_requested_el,
        expected_product_decline_min_requested_el,
        expected_product_approved_el_cap,
        expected_product_min_approved_amount,
        expected_product_max_approved_amount,
        expected_product_min_counteroffer_pct,
        expected_product_max_exposure_reduction_pct
    )
),

expected_product_guardrail_rows AS (
    SELECT
        r.module2_run_id,
        r.parameter_snapshot_rows_for_run,
        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy_raw AS (
    SELECT
        r.module2_run_id,

        pp.product_policy_row ->> 'product_type' AS product_type,

        (pp.product_policy_row ->> 'product_approve_max_pti')::NUMERIC
            AS actual_product_approve_max_pti,

        (pp.product_policy_row ->> 'product_review_max_pti')::NUMERIC
            AS actual_product_review_max_pti,

        (pp.product_policy_row ->> 'product_decline_min_pti')::NUMERIC
            AS actual_product_decline_min_pti,

        (pp.product_policy_row ->> 'counteroffer_target_pti')::NUMERIC
            AS actual_counteroffer_target_pti,

        (pp.product_policy_row ->> 'product_approve_max_requested_el')::NUMERIC
            AS actual_product_approve_max_requested_el,

        (pp.product_policy_row ->> 'product_review_max_requested_el')::NUMERIC
            AS actual_product_review_max_requested_el,

        (pp.product_policy_row ->> 'product_decline_min_requested_el')::NUMERIC
            AS actual_product_decline_min_requested_el,

        (pp.product_policy_row ->> 'product_approved_el_cap')::NUMERIC
            AS actual_product_approved_el_cap,

        (pp.product_policy_row ->> 'product_min_approved_amount')::NUMERIC
            AS actual_product_min_approved_amount,

        (pp.product_policy_row ->> 'product_max_approved_amount')::NUMERIC
            AS actual_product_max_approved_amount,

        (pp.product_policy_row ->> 'product_min_counteroffer_pct')::NUMERIC
            AS actual_product_min_counteroffer_pct,

        (pp.product_policy_row ->> 'product_max_exposure_reduction_pct')::NUMERIC
            AS actual_product_max_exposure_reduction_pct

    FROM product_guardrail_runs r

    CROSS JOIN LATERAL jsonb_array_elements(
        COALESCE(r.product_policy_params_jsonb, '[]'::jsonb)
    ) AS pp(product_policy_row)

    WHERE pp.product_policy_row ->> 'product_type' IN (
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    )
),

actual_product_guardrail_policy AS (
    SELECT
        module2_run_id,
        product_type,

        COUNT(*) AS actual_product_policy_rows_for_product,

        MAX(actual_product_approve_max_pti) AS actual_product_approve_max_pti,
        MAX(actual_product_review_max_pti) AS actual_product_review_max_pti,
        MAX(actual_product_decline_min_pti) AS actual_product_decline_min_pti,
        MAX(actual_counteroffer_target_pti) AS actual_counteroffer_target_pti,

        MAX(actual_product_approve_max_requested_el) AS actual_product_approve_max_requested_el,
        MAX(actual_product_review_max_requested_el) AS actual_product_review_max_requested_el,
        MAX(actual_product_decline_min_requested_el) AS actual_product_decline_min_requested_el,
        MAX(actual_product_approved_el_cap) AS actual_product_approved_el_cap,

        MAX(actual_product_min_approved_amount) AS actual_product_min_approved_amount,
        MAX(actual_product_max_approved_amount) AS actual_product_max_approved_amount,
        MAX(actual_product_min_counteroffer_pct) AS actual_product_min_counteroffer_pct,
        MAX(actual_product_max_exposure_reduction_pct) AS actual_product_max_exposure_reduction_pct

    FROM actual_product_guardrail_policy_raw

    GROUP BY
        module2_run_id,
        product_type
),

product_guardrail_policy_audit_summary AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM product_guardrail_campaign_runs
        ) AS product_guardrail_campaign_run_count,

        (
            SELECT COUNT(*)
            FROM expected_product_guardrail_policy
        ) AS audited_product_count,

        (
            SELECT COUNT(*)
            FROM product_guardrail_runs
            WHERE parameter_snapshot_rows_for_run = 1
        ) AS product_guardrail_parameter_snapshot_complete_run_count,

        (
            SELECT COUNT(*)
            FROM product_guardrail_runs
            WHERE parameter_snapshot_rows_for_run <> 1
        ) AS product_guardrail_parameter_snapshot_issue_run_count,

        COUNT(*) AS expected_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NULL
        ) AS missing_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1
        ) AS product_guardrail_policy_row_count_issue_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(a.actual_product_policy_rows_for_product, 0) = 1
              AND (
                    a.actual_product_approve_max_pti IS DISTINCT FROM e.expected_product_approve_max_pti
                 OR a.actual_product_review_max_pti IS DISTINCT FROM e.expected_product_review_max_pti
                 OR a.actual_product_decline_min_pti IS DISTINCT FROM e.expected_product_decline_min_pti
                 OR a.actual_counteroffer_target_pti IS DISTINCT FROM e.expected_counteroffer_target_pti
                 OR a.actual_product_approve_max_requested_el IS DISTINCT FROM e.expected_product_approve_max_requested_el
                 OR a.actual_product_review_max_requested_el IS DISTINCT FROM e.expected_product_review_max_requested_el
                 OR a.actual_product_decline_min_requested_el IS DISTINCT FROM e.expected_product_decline_min_requested_el
                 OR a.actual_product_approved_el_cap IS DISTINCT FROM e.expected_product_approved_el_cap
                 OR a.actual_product_min_approved_amount IS DISTINCT FROM e.expected_product_min_approved_amount
                 OR a.actual_product_max_approved_amount IS DISTINCT FROM e.expected_product_max_approved_amount
                 OR a.actual_product_min_counteroffer_pct IS DISTINCT FROM e.expected_product_min_counteroffer_pct
                 OR a.actual_product_max_exposure_reduction_pct IS DISTINCT FROM e.expected_product_max_exposure_reduction_pct
              )
        ) AS product_guardrail_policy_mismatch_rows

    FROM expected_product_guardrail_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
),

acceptance_inputs AS (
    SELECT
        /*******************************************************************************************
        Dynamic expected campaign shape.
        *******************************************************************************************/
        cr.active_campaign_registry_rows AS expected_campaign_runs,
        cmpr.active_comparison_registry_rows AS expected_comparison_groups,

        ar.expected_total_active_campaign_source_rows,
        ev.expected_validation_key_count,

        pga.product_guardrail_campaign_run_count
            AS expected_product_guardrail_campaign_runs,

        pga.audited_product_count,
        pga.expected_product_guardrail_policy_rows,

        /*******************************************************************************************
        Registry and archive.
        *******************************************************************************************/
        cr.active_campaign_registry_rows,
        cr.duplicate_active_campaign_technical_key_rows,

        cmpr.active_comparison_registry_rows,
        cmpr.duplicate_active_comparison_group_rows,

        ar.active_campaign_registry_rows_for_archive_check,
        ar.active_runs_missing_module1_source_count,
        ar.active_runs_with_module1_source_application_id_grain_issue,
        ar.active_runs_with_archive_rows,
        ar.active_runs_missing_archive_rows,
        ar.total_active_campaign_archived_rows,
        ar.active_runs_with_archive_row_count_mismatch,
        ar.active_runs_with_archive_application_id_grain_issue,

        agd.duplicate_archive_grain_count,

        /*******************************************************************************************
        Comparison and source consistency.
        *******************************************************************************************/
        cmp.comparison_group_count,
        cmp.comparison_ready_count,
        cmp.comparison_review_count,

        src.source_consistency_group_count,
        src.source_consistency_pass_count,
        src.source_consistency_review_count,
        src.total_source_field_mismatch_rows,

        /*******************************************************************************************
        Evidence.
        *******************************************************************************************/
        ev.registry_run_count_for_evidence_check,

        ev.executive_evidence_rows,
        ev.executive_evidence_complete_run_count,
        ev.executive_evidence_issue_run_count,

        ev.parameter_snapshot_rows,
        ev.parameter_snapshot_complete_run_count,
        ev.parameter_snapshot_issue_run_count,

        ev.validation_evidence_complete_run_count,
        ev.validation_evidence_incomplete_run_count,
        ev.min_validation_rows_per_run,
        ev.max_validation_rows_per_run,
        ev.total_validation_evidence_rows,

        ev.segment_evidence_complete_run_count,
        ev.segment_evidence_issue_run_count,
        ev.min_expected_segment_rows_per_run,
        ev.max_expected_segment_rows_per_run,
        ev.min_segment_rows_per_run,
        ev.max_segment_rows_per_run,
        ev.total_segment_evidence_rows,

        /*******************************************************************************************
        Final-output conventions.
        *******************************************************************************************/
        cv.active_campaign_archived_rows,
        cv.critical_convention_violation_count,

        /*******************************************************************************************
        Product guardrail policy exact-value audit.
        *******************************************************************************************/
        pga.product_guardrail_campaign_run_count,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,
        pga.expected_product_guardrail_policy_rows AS actual_product_guardrail_policy_rows_checked,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_row_count_issue_rows,
        pga.product_guardrail_policy_mismatch_rows,

        /*******************************************************************************************
        Gate-level flags.
        *******************************************************************************************/
        (
            cr.active_campaign_registry_rows > 0
            AND cr.duplicate_active_campaign_technical_key_rows = 0
        ) AS campaign_registry_ready_flag,

        (
            cmpr.duplicate_active_comparison_group_rows = 0
        ) AS comparison_registry_ready_flag,

        (
            cr.active_campaign_registry_rows > 0
            AND ar.active_campaign_registry_rows_for_archive_check = cr.active_campaign_registry_rows
            AND ar.active_runs_missing_module1_source_count = 0
            AND ar.active_runs_with_module1_source_application_id_grain_issue = 0
            AND ar.active_runs_missing_archive_rows = 0
            AND ar.active_runs_with_archive_row_count_mismatch = 0
            AND ar.active_runs_with_archive_application_id_grain_issue = 0
            AND agd.duplicate_archive_grain_count = 0
        ) AS archive_ready_flag,

        (
            cmp.comparison_group_count = cmpr.active_comparison_registry_rows
            AND cmp.comparison_review_count = 0
        ) AS comparison_ready_flag,

        (
            src.source_consistency_group_count = cmpr.active_comparison_registry_rows
            AND src.source_consistency_review_count = 0
            AND src.total_source_field_mismatch_rows = 0
        ) AS source_consistency_ready_flag,

        (
            ev.registry_run_count_for_evidence_check = cr.active_campaign_registry_rows
            AND ev.expected_validation_key_count > 0
            AND ev.executive_evidence_complete_run_count = cr.active_campaign_registry_rows
            AND ev.executive_evidence_issue_run_count = 0
            AND ev.parameter_snapshot_complete_run_count = cr.active_campaign_registry_rows
            AND ev.parameter_snapshot_issue_run_count = 0
            AND ev.validation_evidence_complete_run_count = cr.active_campaign_registry_rows
            AND ev.validation_evidence_incomplete_run_count = 0
            AND ev.segment_evidence_complete_run_count = cr.active_campaign_registry_rows
            AND ev.segment_evidence_issue_run_count = 0
        ) AS evidence_ready_flag,

        (
            cv.active_campaign_archived_rows > 0
            AND cv.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,

        (
            pga.product_guardrail_campaign_run_count = 0
            OR (
                pga.product_guardrail_parameter_snapshot_complete_run_count
                    = pga.product_guardrail_campaign_run_count
                AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
                AND pga.expected_product_guardrail_policy_rows
                    = pga.product_guardrail_campaign_run_count * pga.audited_product_count
                AND pga.missing_product_guardrail_policy_rows = 0
                AND pga.product_guardrail_policy_row_count_issue_rows = 0
                AND pga.product_guardrail_policy_mismatch_rows = 0
            )
        ) AS product_guardrail_policy_ready_flag

    FROM campaign_registry_summary cr
    CROSS JOIN comparison_registry_summary cmpr
    CROSS JOIN archive_summary ar
    CROSS JOIN archive_grain_duplicates agd
    CROSS JOIN comparison_readiness_summary cmp
    CROSS JOIN source_consistency_summary src
    CROSS JOIN evidence_summary ev
    CROSS JOIN convention_summary cv
    CROSS JOIN product_guardrail_policy_audit_summary pga
),

acceptance_status AS (
    SELECT
        ai.*,

        (
            campaign_registry_ready_flag
            AND comparison_registry_ready_flag
            AND archive_ready_flag
            AND comparison_ready_flag
            AND source_consistency_ready_flag
            AND evidence_ready_flag
            AND final_output_conventions_ready_flag
        ) AS structural_acceptance_ready_flag,

        CASE
            WHEN campaign_registry_ready_flag
             AND comparison_registry_ready_flag
             AND archive_ready_flag
             AND comparison_ready_flag
             AND source_consistency_ready_flag
             AND evidence_ready_flag
             AND final_output_conventions_ready_flag
             AND product_guardrail_policy_ready_flag
                THEN 'MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS'

            WHEN campaign_registry_ready_flag
             AND comparison_registry_ready_flag
             AND archive_ready_flag
             AND comparison_ready_flag
             AND source_consistency_ready_flag
             AND evidence_ready_flag
             AND final_output_conventions_ready_flag
             AND product_guardrail_policy_ready_flag IS DISTINCT FROM TRUE
                THEN 'STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED'

            ELSE 'REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS'
        END AS module2_campaign_acceptance_status,

        CONCAT_WS(
            ' | ',

            CASE
                WHEN campaign_registry_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_CAMPAIGN_REGISTRY'
            END,

            CASE
                WHEN comparison_registry_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_COMPARISON_REGISTRY'
            END,

            CASE
                WHEN archive_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_ARCHIVE_INVENTORY_OR_ARCHIVE_GRAIN'
            END,

            CASE
                WHEN comparison_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_COMPARISON_READINESS'
            END,

            CASE
                WHEN source_consistency_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_MATCHED_SOURCE_FIELD_CONSISTENCY'
            END,

            CASE
                WHEN evidence_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_SECTION_16_EVIDENCE_COMPLETENESS'
            END,

            CASE
                WHEN final_output_conventions_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_FINAL_OUTPUT_CONVENTIONS'
            END,

            CASE
                WHEN product_guardrail_policy_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_PRODUCT_GUARDRAIL_POLICY_EXACT_VALUES'
            END
        ) AS acceptance_review_focus

    FROM acceptance_inputs ai
)

SELECT
    /***********************************************************************************************
    Final status.
    ***********************************************************************************************/
    module2_campaign_acceptance_status,

    CASE
        WHEN acceptance_review_focus IS NULL
          OR acceptance_review_focus = ''
            THEN 'ALL_FINAL_ACCEPTANCE_GATES_PASSED'
        ELSE acceptance_review_focus
    END AS acceptance_review_focus,


    /***********************************************************************************************
    Gate flags.
    ***********************************************************************************************/
    campaign_registry_ready_flag,
    comparison_registry_ready_flag,
    archive_ready_flag,
    comparison_ready_flag,
    source_consistency_ready_flag,
    evidence_ready_flag,
    final_output_conventions_ready_flag,
    product_guardrail_policy_ready_flag,
    structural_acceptance_ready_flag,


    /***********************************************************************************************
    Dynamic expected campaign shape.
    ***********************************************************************************************/
    expected_campaign_runs,
    expected_comparison_groups,
    expected_total_active_campaign_source_rows,
    expected_validation_key_count,
    expected_product_guardrail_campaign_runs,
    audited_product_count,
    expected_product_guardrail_policy_rows,


    /***********************************************************************************************
    Registry and archive evidence.
    ***********************************************************************************************/
    active_campaign_registry_rows,
    duplicate_active_campaign_technical_key_rows,

    active_comparison_registry_rows,
    duplicate_active_comparison_group_rows,

    active_campaign_registry_rows_for_archive_check,
    active_runs_missing_module1_source_count,
    active_runs_with_module1_source_application_id_grain_issue,
    active_runs_with_archive_rows,
    active_runs_missing_archive_rows,
    total_active_campaign_archived_rows,
    active_runs_with_archive_row_count_mismatch,
    active_runs_with_archive_application_id_grain_issue,
    duplicate_archive_grain_count,


    /***********************************************************************************************
    Comparison and source-consistency evidence.
    ***********************************************************************************************/
    comparison_group_count,
    comparison_ready_count,
    comparison_review_count,

    source_consistency_group_count,
    source_consistency_pass_count,
    source_consistency_review_count,
    total_source_field_mismatch_rows,


    /***********************************************************************************************
    Section 16 evidence completeness.
    ***********************************************************************************************/
    registry_run_count_for_evidence_check,

    executive_evidence_rows,
    executive_evidence_complete_run_count,
    executive_evidence_issue_run_count,

    parameter_snapshot_rows,
    parameter_snapshot_complete_run_count,
    parameter_snapshot_issue_run_count,

    validation_evidence_complete_run_count,
    validation_evidence_incomplete_run_count,
    min_validation_rows_per_run,
    max_validation_rows_per_run,
    total_validation_evidence_rows,

    segment_evidence_complete_run_count,
    segment_evidence_issue_run_count,
    min_expected_segment_rows_per_run,
    max_expected_segment_rows_per_run,
    min_segment_rows_per_run,
    max_segment_rows_per_run,
    total_segment_evidence_rows,


    /***********************************************************************************************
    Convention and product-guardrail policy audit evidence.
    ***********************************************************************************************/
    active_campaign_archived_rows,
    critical_convention_violation_count,

    product_guardrail_campaign_run_count,
    product_guardrail_parameter_snapshot_complete_run_count,
    product_guardrail_parameter_snapshot_issue_run_count,
    actual_product_guardrail_policy_rows_checked,
    missing_product_guardrail_policy_rows,
    product_guardrail_policy_row_count_issue_rows,
    product_guardrail_policy_mismatch_rows

FROM acceptance_status;
```
<!-- END_MESSAGE C038-M01797 -->


---

<a id="c038-m01798"></a>

### C038-M01798

**Andrew** · 2026-05-13T08:38:34.451000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01798 -->
review this final section 17 comment.  Also, review the full section 17 for consistency and clear narrative after this recent pass.
<!-- END_MESSAGE C038-M01798 -->


**Attachments in export:** `Pasted text(180).txt`, `Pasted text (2)(3).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01801"></a>

### C038-M01801

**ChatGPT** · 2026-05-13T08:44:36.056938-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01801 -->
According to a document from 2026-05-13, **Section 17 is now narratively coherent and the logic direction is right**. I would not reopen SQL logic unless runtime testing exposes an issue. The remaining refinements are **comment-only alignment**: a few phrases still sound like the older fixed/full-archive campaign framing, while the recent pass moved Section 17 to active-campaign-registry-scoped, dynamic acceptance. fileciteturn297file11

## Verdict

**Keep the current Section 17 structure. Make only small commentary edits.**

The strongest parts are now aligned:

Section 17 is framed as the final read-only control tower after all runs, archive persistence, validation, comparison, Section 15 frontier refresh, Section 16.9 synchronization, and evidence capture. fileciteturn297file9

The header now clearly states the dynamic acceptance design: Section 17 no longer assumes 50,000 rows per Module 1 slice, and instead derives expected source counts from `credit_decisioning_sim.synthetic_applications_scenario_archive` using `module1_scenario_set_name`, `module1_scenario_name`, and `population_id`. fileciteturn297file11

The validation and segment evidence commentary is also aligned: Section 17 no longer hardcodes 18 validation rows or 25 product × score rows; it derives validation keys and segment evidence expectations dynamically. fileciteturn297file16

The final Section 17.20 output is now consistent with that design. It exposes dynamic expected campaign-shape fields such as `expected_total_active_campaign_source_rows`, `expected_validation_key_count`, `expected_product_guardrail_campaign_runs`, `audited_product_count`, and `expected_product_guardrail_policy_rows`, instead of relying on fixed 36 / 50,000 / 18 assumptions. fileciteturn298file16

## Commentary items I would still tighten

First, replace **“Full-archive final-output conventions”** with **“active-campaign archive final-output conventions.”** This wording appears in the Section 17 map and ending comment. The old phrase implies all historical archive rows are in scope, but the new design correctly evaluates rows tied to active campaign registry runs.

Second, replace **“accepted campaign runs”** with **“active campaign registry runs”** where the sentence is describing Section 17’s scope. “Accepted” sounds like a status already determined; “active campaign registry runs” is the actual SQL scope.

Third, the product-guardrail review language should mention **missing, duplicate, or mismatched** policy evidence, not only mismatches. The newer 17.19 / 17.20 design checks product-guardrail campaign-run count, parameter snapshot completeness, missing rows, row-count issues, and value mismatches.

Fourth, the ending comment should explicitly say the final acceptance is now based on **dynamic expectations derived from active registries, Module 1 source counts, validation evidence keys, segment evidence keys, and audited product-policy values.** That will close the narrative loop from the updated Section 17 header to the ending.

## Recommended replacement for the final Section 17 ending comment

I would replace your current ending comment with this version. It preserves your structure, but aligns the wording to the dynamic, active-registry-scoped design.

```sql
/***************************************************************************************************
END OF SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW

If execution reaches this point:
    1. Active campaign archive inventory has been reviewed.
    2. Active campaign archive slice detail has been displayed.
    3. Archive grain duplicates have been checked.
    4. Active campaign registry rows have been reconciled to archive slices.
    5. Registry/archive missing or mismatch detail has been displayed.
    6. Archive slices without active campaign registry rows have been surfaced for review.
    7. Section 16 evidence coverage has been summarized.
    8. Section 16 evidence detail has been displayed by run.
    9. Active-campaign archive final-output conventions have been checked.
    10. Validation status has been summarized by active campaign run.
    11. Validation REVIEW / NOT_APPLICABLE concentration has been reviewed.
    12. Active comparison registry readiness has been checked.
    13. Matched comparison source-field consistency has been checked.
    14. Executive evidence campaign summary has been displayed.
    15. Baseline × challenger deltas have been displayed.
    16. Product guardrail strategy effects have been reviewed.
    17. Counteroffer-first strategy effects have been reviewed.
    18. Parameter snapshot completeness has been reviewed.
    19. Product guardrail policy snapshots have been compared to intended canonical values.
    20. Final campaign acceptance has been summarized in one status row.

Dynamic acceptance basis:
    Section 17 acceptance is derived from active registry and evidence state.

    It does not assume:
        a fixed number of campaign runs,
        a fixed number of comparison groups,
        a fixed Module 1 source population size,
        a fixed total archive row count,
        a fixed Section 14 validation evidence row count,
        a fixed product × score segment count,
        or a fixed number of product-guardrail strategy runs.

    Instead, Section 17 derives expected values from:
        active campaign registry rows,
        active comparison registry rows,
        selected Module 1 source-population counts,
        active campaign archive slices,
        persisted validation evidence keys,
        archived product × score segment keys,
        Section 16 evidence tables,
        and audited product-policy expectations.

Interpretation of final acceptance:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        Active campaign archive, registry, evidence, convention, comparison, source-consistency,
        parameter snapshot, and audited product-policy checks are clean.

        This means the campaign SQL evidence is structurally ready for executive interpretation,
        README drafting, LinkedIn storytelling, and written Validation Summary drafting within the
        documented simulation boundaries.

    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        Structural, archive, evidence, convention, comparison, source-consistency, and parameter
        snapshot checks are clean, but at least one audited product-guardrail policy snapshot check
        requires review.

        This status may reflect a missing product-policy row, duplicate product-policy row, missing
        parameter snapshot, duplicate parameter snapshot, or product-policy value mismatch.

        The campaign may be structurally complete, but product-guardrail parameter evidence should be
        reviewed before final interpretation.

    REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        One or more structural, archive, registry, evidence, convention, comparison, source-field,
        validation, parameter, or product-policy checks require review.

        This status means final documentation should pause until the specific Section 17 diagnostic
        query identifying the issue has been reviewed.

Recommended post-Section 17 workflow:
    If module2_campaign_acceptance_status = MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        1. Preserve the Section 17 outputs.
        2. Use Section 17.20 as the final campaign acceptance row.
        3. Use Section 17.14–17.17 for executive narrative development.
        4. Use Section 17.18–17.19 for parameter governance evidence.
        5. Proceed to written Validation Summary / README / LinkedIn drafting.

    If module2_campaign_acceptance_status = STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        1. Review Section 17.19.
        2. Confirm whether the product-guardrail parameter evidence issue is expected or erroneous.
        3. Rerun affected campaign slices or evidence capture if needed.
        4. Rerun Section 15 if archive-changing corrections were made.
        5. Rerun Section 16.9 after a fresh Section 15 run.
        6. Rerun Section 17.

    If module2_campaign_acceptance_status = REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        1. Identify which Section 17 diagnostic query produced the review condition.
        2. Correct archive, registry, comparison, evidence, source-consistency, validation, parameter,
           or product-policy issues as needed.
        3. Rerun affected campaign slices only if the issue affects accepted strategy output.
        4. Rerun Section 15 after archive-changing corrections.
        5. Rerun Section 16.9 after a fresh Section 15 run.
        6. Rerun Section 17.

Read-only boundary:
    Section 17 did not insert archive rows.
    Section 17 did not delete archive rows.
    Section 17 did not update archive rows.
    Section 17 did not modify latest-run rows.
    Section 17 did not modify evidence rows.
    Section 17 did not modify campaign registry rows.
    Section 17 did not modify comparison registry rows.
    Section 17 did not modify strategy parameter rows.
    Section 17 did not modify product-policy parameter rows.
    Section 17 did not synchronize frontier evidence.
    Section 17 did not recalculate decision outcomes.
    Section 17 did not recalculate approved exposure values.
    Section 17 did not recalculate approved Expected Loss values.
    Section 17 did not reassign simulated reason codes.
    Section 17 did not implement revenue logic.
    Section 17 did not implement earnings logic.
    Section 17 did not implement pricing optimization logic.
    Section 17 did not implement funding-cost logic.
    Section 17 did not implement profitability logic.
    Section 17 did not implement capital logic.
    Section 17 did not implement risk-adjusted margin logic.

Final documentation boundary:
    Section 17 provides SQL evidence acceptance.

    It does not itself draft:
        BRD text,
        written Validation Summary conclusions,
        README narrative,
        LinkedIn posts,
        production policy recommendations,
        model validation approval,
        fair-lending conclusions,
        customer communications,
        or operational implementation instructions.

Final campaign workflow checkpoint:
    Full-campaign SQL workflow is complete only after:

        all planned runs through Section 16.8
        → fresh Section 15
        → Section 16.9 synchronization
        → Section 17 final acceptance

***************************************************************************************************/
```

## Final Section 17 narrative assessment

After this small comment patch, Section 17 will read cleanly end to end:

Section 17.1–17.8 establish **dynamic archive and evidence completeness**.

Section 17.9–17.13 establish **active campaign convention integrity, validation status, comparison readiness, and source consistency**.

Section 17.14–17.17 establish **executive evidence and strategy-effect interpretation**.

Section 17.18–17.19 establish **parameter governance and exact product-policy auditability**.

Section 17.20 provides the **one-row final campaign acceptance result**.

That is the right narrative order. The section now tells a coherent story: first prove the campaign is complete, then prove it is comparable, then prove the evidence is complete, then review strategy effects, then audit parameters, then summarize final acceptance.
<!-- END_MESSAGE C038-M01801 -->


---

<a id="c038-m01802"></a>

### C038-M01802

**Andrew** · 2026-05-13T08:53:24.666000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01802 -->
review full code one more time before my I test its execution again.  ignore the phrase "final validated release"  i will not publish until testing is complete.
<!-- END_MESSAGE C038-M01802 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(3).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01815"></a>

### C038-M01815

**ChatGPT** · 2026-05-13T09:01:47.225997-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01815 -->
According to a document from 2026-05-13, the uploaded full Module 2 file is ready for execution testing. I would **not make another SQL patch before testing**. I reviewed the current uploaded file directly, not the older pasted-section snippets, and the recent dynamic Section 17 work is present in the current file. fileciteturn302file2

## Verdict

**Proceed to execution testing.**

I found no static structural blocker that would justify another code-design pass before running it. The file now has the active-campaign-registry-scoped Section 17.9 convention check, the comparison-registry-scoped counteroffer-first check, the dynamic Section 17.20 final acceptance rollup, and the Section 1 / Section 14 helper cleanup alignment. fileciteturn304file0 fileciteturn304file6 fileciteturn304file7 fileciteturn303file11

## Static checks I performed on the uploaded file

I checked the exact uploaded file:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(3).txt
```

Static results:

| Check | Result |
|---|---:|
| File length | 61,173 lines / ~2.35M characters |
| Formal section headings | 156 |
| Duplicate formal section headings | 0 |
| Section 14 coverage | 14.0 through 14.20 present |
| Section 17 coverage | 17.1 through 17.20 present |
| Block comments `/* ... */` | balanced: 1,395 / 1,395 |
| Executable `DO $$ ... END $$;` blocks | balanced: 36 / 36 |
| Parentheses after stripping comments / strings | balanced |
| Section 14.19 validation areas | 18 |
| Legacy hardcoded final-campaign constants in executable Section 17 | no `36::BIGINT`, no `17::BIGINT`, no `1800000`, no `expected_rows_per_archive_slice`, no `expected_validation_rows_per_run` |

The remaining `50,000` references I saw in Section 17 are explanatory comments saying the code is **not** hardcoded to 50,000, plus `0.500000` product-policy numeric constants. I did not find the old executable `archived_rows = 50000` acceptance pattern in the current Section 17.

## Key confirmations

**Section 1.4 is aligned.** It now drops the Section 14 helper objects:

```sql
tmp_m2_validation_archive_readiness_context
tmp_m2_validation_comparison_readiness_context
tmp_m2_validation_source_consistency_context
tmp_m2_validation_status_summary
```

and the commentary explains why Section 14 also performs a local rerun reset. fileciteturn303file11

**Section 14 is aligned.** Section 14.0 includes the validation dependency preflight and optional context-helper framework, and Section 14.18 consumes the archive-readiness, comparison-readiness, and source-consistency helper outputs. fileciteturn302file16 fileciteturn303file5

**Section 17.9 is now active-campaign scoped.** It checks final-output conventions only across archived rows belonging to active campaign registry runs, not every historical archive row. That is the right acceptance scope. fileciteturn304file0

**Section 17.14 and 17.15 are dynamic.** Section 17.14 compares executive evidence applications to the selected Module 1 source population instead of assuming 50,000 rows, and Section 17.15 returns one row per active comparison registry group rather than assuming a fixed comparison count. fileciteturn304file7 fileciteturn304file8

**Section 17.17 is correctly comparison-registry scoped.** It now reviews active comparison groups where the challenger is `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY`, rather than inferring pairings only from strategy name. fileciteturn304file6

**Section 17.20 is now dynamic.** It explicitly says it no longer hardcodes campaign run count, comparison group count, archive rows per slice, total archive rows, validation evidence row count, product-guardrail campaign run count, or product-guardrail audit row count. It derives expected campaign shape from active registry and source evidence. fileciteturn304file7

**The final Section 17 ending is coherent.** It now states that acceptance is derived from active registries, selected Module 1 source-population counts, active campaign archive slices, persisted validation evidence keys, archived product × score segment keys, Section 16 evidence tables, and audited product-policy expectations. fileciteturn304file14

## One non-blocking comment-only item

The Section 17 header / map still contains two phrases that are slightly behind the actual SQL logic:

```text
17.9 Full-archive final-output convention checks
Full-archive convention violation counts should be zero
```

The actual Section 17.9 query is correctly active-campaign scoped. This is **not an execution blocker**. You can leave it until after runtime testing or change those two phrases later to:

```text
17.9 Active-campaign archive final-output convention checks
Active-campaign archive convention violation counts should be zero
```

I would not interrupt testing for that.

## Runtime watch points

When you test, the most likely review statuses are not syntax issues; they are data-state issues:

1. **Section 17 expects active campaign registry rows.** If active flags are wrong, the dynamic acceptance logic will evaluate the wrong scope.

2. **Section 17 derives validation completeness from persisted validation evidence keys.** If Section 16 evidence capture was skipped for any active run, Section 17 will correctly flag evidence incompleteness.

3. **Section 17.14 expects frontier fields to be synchronized.** If Section 15 was not rerun after the final archive state, or Section 16.9 was skipped, frontier fields may come back as review-required.

4. **Product-guardrail policy audit is now flexible but still exact-value based.** If active `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` runs exist, their UPL and revolving-line product-policy values must match the canonical audit values.

## Recommended execution path

For another full-campaign acceptance test, use:

```text
all intended runs through Section 16.8
→ rerun Section 15 once from the completed archive
→ run Section 16.9
→ run Section 17
→ check Section 17.20
```

The target final value remains:

```sql
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```

My recommendation: **run it now.** If execution fails, the failure will likely be a concrete PostgreSQL/runtime issue or an actual data-state acceptance issue, not a reason to keep redesigning the SQL.
<!-- END_MESSAGE C038-M01815 -->


---

<a id="c038-m01816"></a>

### C038-M01816

**Andrew** · 2026-05-13T09:11:35.750000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01816 -->
ok, let's re-run the full module 2 campaign for this test - please give me the same 36 run campaign we did earlier in a map form - what parameters do I change for each of the 36 runs.  i assume it will be much simpler with our catalogs now.  is there anything i need to clear before doing so?  or will re-running each clear the prior results?
<!-- END_MESSAGE C038-M01816 -->


---

<a id="c038-m01818"></a>

### C038-M01818

**ChatGPT** · 2026-05-13T09:17:17.304978-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01818 -->
According to a document from 2026-05-13, yes — the rerun is much simpler now. For a standard campaign run, you should keep:

```sql
run_mode = 'STANDARD_CAMPAIGN'
selected_comparison_group_id = NULL
```

and change only:

```sql
selected_module2_run_id = 'M2-##'
```

Section 2 says `selected_module2_run_id` is the main operator control for the formal campaign; from that one ID, the SQL derives the Module 1 scenario, population, strategy profile, product-policy profile, strategy name/version, run ID, active parameter card, campaign registry row, and evidence metadata. fileciteturn307file0

## Do you need to clear anything first?

For the normal full campaign rerun: **no separate manual clearing step is needed**.

Run each campaign slice through **Sections 1–16.8**. Section 1 clears temporary objects and the replaceable latest-run table, but it preserves the governed archive, campaign registry, comparison registry, and evidence tables. fileciteturn306file10 Section 12 controls archive replacement by the current strategy/scenario/population slice, and the standard rerun mode should replace the matching prior archive slice rather than globally clearing the archive. fileciteturn306file67 Section 16 replaces evidence rows for the current run key, so rerunning the same M2 run should refresh that run’s evidence instead of duplicating it. fileciteturn306file76

Do **not** truncate or drop the archive/evidence tables unless you intentionally want to destroy prior governed history. For this test, just rerun the 36 standard campaign runs.

After all 36 are complete, run:

```text
fresh Section 15
→ Section 16.9
→ Section 17
```

The final Section 17 guidance also says the full campaign workflow is complete only after all planned runs through 16.8, then fresh Section 15, Section 16.9 synchronization, and Section 17 final acceptance. fileciteturn307file12

## Section 2 edit pattern

For each run, update only this value in **Section 2.1**:

```sql
VALUES (
    TRUE,
    'STANDARD_CAMPAIGN',
    'M2-01',
    NULL
);
```

Change `'M2-01'` to the run you are executing. Leave `NULL` for the comparison selector unless you are deliberately reviewing a specific Section 13 comparison while running a baseline that has multiple possible comparisons. The code says `selected_comparison_group_id` does **not** control the run being executed; it only controls the active Section 13 comparison. fileciteturn307file0

## 36-run campaign map

| Seq | Edit `selected_module2_run_id` to | Scenario family | Module 1 scenario | Strategy derived | Product-policy profile derived |
|---:|---|---|---|---|---|
| 1 | `M2-01` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 2 | `M2-02` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 3 | `M2-03` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `GROWTH_ORIENTED_STRATEGY` | `GROWTH_PRODUCT_POLICY` |
| 4 | `M2-04` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `TIGHTER_AFFORDABILITY_STRATEGY` | `AFFORDABILITY_TIGHT_PRODUCT_POLICY` |
| 5 | `M2-05` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `COUNTEROFFER_FIRST_PRODUCT_POLICY` |
| 6 | `M2-06` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `PRODUCT_GUARDRAIL_PRODUCT_POLICY` |
| 7 | `M2-07` | SC01 — Baseline Strategy Frontier | `BASELINE_V2` | `MANUAL_REVIEW_REDUCTION_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 8 | `M2-08` | SC02 — Rate Environment Sensitivity | `RATE_UP_200BP` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 9 | `M2-09` | SC02 — Rate Environment Sensitivity | `RATE_DOWN_200BP` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 10 | `M2-10` | SC02 — Rate Environment Sensitivity | `RATE_UP_300BP` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 11 | `M2-11` | SC02 — Rate Environment Sensitivity | `RATE_UP_200BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | `AFFORDABILITY_TIGHT_PRODUCT_POLICY` |
| 12 | `M2-12` | SC02 — Rate Environment Sensitivity | `RATE_UP_300BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | `AFFORDABILITY_TIGHT_PRODUCT_POLICY` |
| 13 | `M2-13` | SC02 — Rate Environment Sensitivity | `RATE_DOWN_200BP` | `GROWTH_ORIENTED_STRATEGY` | `GROWTH_PRODUCT_POLICY` |
| 14 | `M2-14` | SC03 — Credit Box Sensitivity | `CREDIT_BOX_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 15 | `M2-15` | SC03 — Credit Box Sensitivity | `PRIME_GROWTH_SCORE_MIX` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 16 | `M2-16` | SC03 — Credit Box Sensitivity | `NEAR_PRIME_EXPANSION_MIX` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 17 | `M2-17` | SC03 — Credit Box Sensitivity | `NEAR_PRIME_EXPANSION_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 18 | `M2-18` | SC03 — Credit Box Sensitivity | `NEAR_PRIME_EXPANSION_MIX` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `COUNTEROFFER_FIRST_PRODUCT_POLICY` |
| 19 | `M2-19` | SC03 — Credit Box Sensitivity | `CREDIT_STRESS_SCORE_MIX` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 20 | `M2-20` | SC03 — Credit Box Sensitivity | `CREDIT_STRESS_SCORE_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 21 | `M2-21` | SC04 — Portfolio Mix Sensitivity | `PORTFOLIO_MIX_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 22 | `M2-22` | SC04 — Portfolio Mix Sensitivity | `UNSECURED_GROWTH_MIX` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 23 | `M2-23` | SC04 — Portfolio Mix Sensitivity | `UNSECURED_GROWTH_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `PRODUCT_GUARDRAIL_PRODUCT_POLICY` |
| 24 | `M2-24` | SC04 — Portfolio Mix Sensitivity | `SECURED_BALANCE_GROWTH_MIX` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 25 | `M2-25` | SC04 — Portfolio Mix Sensitivity | `REVOLVING_LINE_EXPANSION_MIX` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 26 | `M2-26` | SC04 — Portfolio Mix Sensitivity | `REVOLVING_LINE_EXPANSION_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `PRODUCT_GUARDRAIL_PRODUCT_POLICY` |
| 27 | `M2-27` | SC05 — Exposure Intensity Sensitivity | `EXPOSURE_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 28 | `M2-28` | SC05 — Exposure Intensity Sensitivity | `HIGH_BALANCE_APPETITE` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 29 | `M2-29` | SC05 — Exposure Intensity Sensitivity | `HIGH_BALANCE_APPETITE` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `COUNTEROFFER_FIRST_PRODUCT_POLICY` |
| 30 | `M2-30` | SC05 — Exposure Intensity Sensitivity | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 31 | `M2-31` | SC06 — LGD Severity Sensitivity | `LGD_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 32 | `M2-32` | SC06 — LGD Severity Sensitivity | `SECURED_SEVERITY_STRESS` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 33 | `M2-33` | SC06 — LGD Severity Sensitivity | `UNSECURED_SEVERITY_STRESS` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 34 | `M2-34` | SC06 — LGD Severity Sensitivity | `UNSECURED_SEVERITY_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `PRODUCT_GUARDRAIL_PRODUCT_POLICY` |
| 35 | `M2-35` | SC06 — LGD Severity Sensitivity | `BROAD_LGD_STRESS` | `BASELINE_STRATEGY` | `BASELINE_PRODUCT_POLICY` |
| 36 | `M2-36` | SC06 — LGD Severity Sensitivity | `BROAD_LGD_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `PRODUCT_GUARDRAIL_PRODUCT_POLICY` |

The 36-run menu and the comparison quick reference are embedded in Section 2.1, and the profile compatibility table maps each strategy profile to its required product-policy profile. fileciteturn308file0 fileciteturn308file5 fileciteturn308file9 fileciteturn308file10 fileciteturn307file13

## Comparison group reference

You can leave `selected_comparison_group_id = NULL` for the campaign rerun. The auto-selection logic will select the natural comparison when possible. The governed comparison map is:

| Comparison | Baseline vs challenger |
|---|---|
| `CG01` | `M2-01` vs `M2-02` |
| `CG02` | `M2-01` vs `M2-03` |
| `CG03` | `M2-01` vs `M2-04` |
| `CG04` | `M2-01` vs `M2-05` |
| `CG05` | `M2-01` vs `M2-06` |
| `CG06` | `M2-01` vs `M2-07` |
| `CG07` | `M2-08` vs `M2-11` |
| `CG08` | `M2-10` vs `M2-12` |
| `CG09` | `M2-09` vs `M2-13` |
| `CG10` | `M2-16` vs `M2-17` |
| `CG11` | `M2-16` vs `M2-18` |
| `CG12` | `M2-19` vs `M2-20` |
| `CG13` | `M2-22` vs `M2-23` |
| `CG14` | `M2-25` vs `M2-26` |
| `CG15` | `M2-28` vs `M2-29` |
| `CG16` | `M2-33` vs `M2-34` |
| `CG17` | `M2-35` vs `M2-36` |

For most challenger runs, auto-selection is enough. If you are running Section 13 while sitting on a baseline run that participates in multiple comparisons, set `selected_comparison_group_id` explicitly. The code calls out `M2-16` as an example baseline used in both `CG10` and `CG11`; `M2-01` is also a multi-comparison baseline, although the code defaults it to `CG01`. fileciteturn307file0

## Recommended rerun workflow

For each of the 36 runs:

```text
1. In Section 2.1, set selected_module2_run_id = 'M2-##'.
2. Keep run_mode = 'STANDARD_CAMPAIGN'.
3. Keep selected_comparison_group_id = NULL.
4. Run Sections 1–16.8.
5. Confirm Section 16.8 evidence outputs look clean.
6. Move to the next M2 run.
```

After `M2-36`:

```text
1. Rerun Section 15 once from the completed archive.
2. Run Section 16.9.
3. Run Section 17.
4. Confirm Section 17.20 returns MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS.
```

Bottom line: for the campaign rerun, your only routine edit is `selected_module2_run_id`. The catalog now handles the rest.
<!-- END_MESSAGE C038-M01818 -->


---

<a id="c038-m01819"></a>

### C038-M01819

**Andrew** · 2026-05-13T09:27:46.273000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01819 -->
while running M2-01: SQL Error [42703]: ERROR: record "c" has no field "oid"
  Where: SQL statement "WITH latest_columns AS (
        SELECT a.attname AS column_name
        FROM pg_attribute a
        JOIN pg_class c
            ON c.oid = a.attrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'credit_decisioning_sim'
          AND c.relname = 'strategy_decisions'
          AND a.attnum > 0
          AND a.attisdropped IS FALSE
    ),

    archive_columns AS (
        SELECT a.attname AS column_name
        FROM pg_attribute a
        JOIN pg_class c
            ON c.oid = a.attrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'credit_decisioning_sim'
          AND c.relname = 'strategy_decisions_archive'
          AND a.attnum > 0
          AND a.attisdropped IS FALSE
    ),

    missing_columns AS (
        SELECT l.column_name
        FROM latest_columns l
        LEFT JOIN archive_columns a
            ON a.column_name = l.column_name
        WHERE a.column_name IS NULL
    )

    SELECT
        COUNT(*),
        STRING_AGG(column_name, ', ' ORDER BY column_name)
                                                                                          FROM missing_columns"
PL/pgSQL function inline_code_block line 76 at SQL statement
  ERROR: record "c" has no field "oid"
  Where: SQL statement "WITH latest_columns AS (
        SELECT a.attname AS column_name
        FROM pg_attribute a
        JOIN pg_class c
            ON c.oid = a.attrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'credit_decisioning_sim'
          AND c.relname = 'strategy_decisions'
          AND a.attnum > 0
          AND a.attisdropped IS FALSE
    ),

    archive_columns AS (
        SELECT a.attname AS column_name
        FROM pg_attribute a
        JOIN pg_class c
            ON c.oid = a.attrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'credit_decisioning_sim'
          AND c.relname = 'strategy_decisions_archive'
          AND a.attnum > 0
          AND a.attisdropped IS FALSE
    ),

    missing_columns AS (
        SELECT l.column_name
        FROM latest_columns l
        LEFT JOIN archive_columns a
            ON a.column_name = l.column_name
        WHERE a.column_name IS NULL
    )

    SELECT
        COUNT(*),
        STRING_AGG(column_name, ', ' ORDER BY column_name)
                                                                                          FROM missing_columns"
PL/pgSQL function inline_code_block line 76 at SQL statement
<!-- END_MESSAGE C038-M01819 -->


---

<a id="c038-m01823"></a>

### C038-M01823

**ChatGPT** · 2026-05-13T09:31:18.508026-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01823 -->
According to a document from 2026-05-13, this failure is in **Section 12.2 — archive schema setup / alignment**, not in M2-01’s run selector or campaign catalog. The current Section 12.2 `DO $$` block declares a PL/pgSQL record variable named `c`, then later uses `JOIN pg_class c` inside catalog queries. Inside PL/pgSQL, that can be resolved as the record variable `c`, so `c.oid` becomes “field `oid` on record variable `c`,” which does not exist. That is why PostgreSQL raises: `record "c" has no field "oid"`. fileciteturn309file18

Replace **only Section 12.2** with the corrected version below. This patch renames the loop record to `add_col` and uses non-conflicting catalog aliases like `lat_cls`, `arc_cls`, and `ins_cls`.

```sql
/***************************************************************************************************
SECTION 12.2 — ARCHIVE TABLE SETUP AND SCHEMA ALIGNMENT
****************************************************************************************************

BUSINESS PURPOSE:
    Create or reuse the governed strategy decision archive table and align its schema to the current
    latest-run output table before archive persistence occurs.

SQL PURPOSE:
    1. Create credit_decisioning_sim.strategy_decisions_archive if it does not already exist.
    2. Ensure archive_inserted_ts exists as archive-only persistence metadata.
    3. Add any latest-run columns missing from the archive table.
    4. Verify no latest-run columns remain missing.
    5. Verify common latest-run / archive columns have matching PostgreSQL data types.
    6. Verify archive contains no unexpected columns except archive_inserted_ts.
    7. Verify archive_inserted_ts exists.

WHY THIS PATCH EXISTS:
    This block runs inside PL/pgSQL.

    The prior version declared a record variable named c and also used pg_class c as a SQL alias
    inside catalog queries.

    In PL/pgSQL, that can create name resolution ambiguity where c.oid is interpreted as a field on
    the PL/pgSQL record variable c rather than as the SQL alias for pg_class.

    This version avoids that collision by:
        using add_col as the loop record variable;
        using explicit catalog aliases such as lat_cls, arc_cls, and ins_cls;
        avoiding pg_class c aliases inside the DO block.

BOUNDARY:
    This section may create or alter the archive table structure.

    It does not delete archive rows.
    It does not insert archive rows.
    It does not update archive row values.
    It does not recalculate strategy outputs.

****************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_decisions_archive
    (LIKE credit_decisioning_sim.strategy_decisions INCLUDING DEFAULTS);

ALTER TABLE credit_decisioning_sim.strategy_decisions_archive
    ADD COLUMN IF NOT EXISTS archive_inserted_ts TIMESTAMP;

DO $$
DECLARE
    add_col RECORD;

    v_missing_archive_column_count BIGINT;
    v_missing_archive_columns TEXT;

    v_type_mismatch_count BIGINT;
    v_type_mismatch_columns TEXT;

    v_unexpected_archive_column_count BIGINT;
    v_unexpected_archive_columns TEXT;

    v_archive_inserted_ts_exists BOOLEAN;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Add missing latest-run columns to the archive table.

    SQL mechanics:
        pg_attribute identifies latest-run columns and their exact PostgreSQL type.

        format_type(atttypid, atttypmod) returns type text such as:
            text
            boolean
            integer
            numeric(12,6)
            timestamp without time zone

        ALTER TABLE ... ADD COLUMN IF NOT EXISTS makes reruns safe.
    -------------------------------------------------------------------------------------------*/
    FOR add_col IN
        SELECT
            latest_att.attname AS column_name,
            pg_catalog.format_type(latest_att.atttypid, latest_att.atttypmod) AS column_type
        FROM pg_attribute latest_att

        JOIN pg_class latest_cls
            ON latest_cls.oid = latest_att.attrelid

        JOIN pg_namespace latest_ns
            ON latest_ns.oid = latest_cls.relnamespace

        WHERE latest_ns.nspname = 'credit_decisioning_sim'
          AND latest_cls.relname = 'strategy_decisions'
          AND latest_att.attnum > 0
          AND latest_att.attisdropped IS FALSE
          AND NOT EXISTS (
              SELECT 1
              FROM pg_attribute archive_att

              JOIN pg_class archive_cls
                  ON archive_cls.oid = archive_att.attrelid

              JOIN pg_namespace archive_ns
                  ON archive_ns.oid = archive_cls.relnamespace

              WHERE archive_ns.nspname = 'credit_decisioning_sim'
                AND archive_cls.relname = 'strategy_decisions_archive'
                AND archive_att.attnum > 0
                AND archive_att.attisdropped IS FALSE
                AND archive_att.attname = latest_att.attname
          )
        ORDER BY latest_att.attnum
    LOOP
        EXECUTE FORMAT(
            'ALTER TABLE credit_decisioning_sim.strategy_decisions_archive ADD COLUMN IF NOT EXISTS %I %s',
            add_col.column_name,
            add_col.column_type
        );
    END LOOP;


    /*-------------------------------------------------------------------------------------------
    Verify no latest-run columns remain missing from archive.

    Business interpretation:
        Every latest-run column should be preservable in the archive.
    -------------------------------------------------------------------------------------------*/
    WITH latest_columns AS (
        SELECT
            lat_att.attname AS column_name
        FROM pg_attribute lat_att

        JOIN pg_class lat_cls
            ON lat_cls.oid = lat_att.attrelid

        JOIN pg_namespace lat_ns
            ON lat_ns.oid = lat_cls.relnamespace

        WHERE lat_ns.nspname = 'credit_decisioning_sim'
          AND lat_cls.relname = 'strategy_decisions'
          AND lat_att.attnum > 0
          AND lat_att.attisdropped IS FALSE
    ),

    archive_columns AS (
        SELECT
            arc_att.attname AS column_name
        FROM pg_attribute arc_att

        JOIN pg_class arc_cls
            ON arc_cls.oid = arc_att.attrelid

        JOIN pg_namespace arc_ns
            ON arc_ns.oid = arc_cls.relnamespace

        WHERE arc_ns.nspname = 'credit_decisioning_sim'
          AND arc_cls.relname = 'strategy_decisions_archive'
          AND arc_att.attnum > 0
          AND arc_att.attisdropped IS FALSE
    ),

    missing_columns AS (
        SELECT
            l.column_name
        FROM latest_columns l

        LEFT JOIN archive_columns a
            ON a.column_name = l.column_name

        WHERE a.column_name IS NULL
    )

    SELECT
        COUNT(*),
        STRING_AGG(column_name, ', ' ORDER BY column_name)
    INTO
        v_missing_archive_column_count,
        v_missing_archive_columns
    FROM missing_columns;

    IF v_missing_archive_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive table is missing latest-run column(s): %.',
            v_missing_archive_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Verify PostgreSQL type alignment for common latest-run / archive columns.

    SQL mechanics:
        format_type compares exact rendered PostgreSQL type definitions.

    Business interpretation:
        Archive persistence should not silently coerce or distort latest-run output values.
    -------------------------------------------------------------------------------------------*/
    WITH latest_columns AS (
        SELECT
            lat_att.attname AS column_name,
            pg_catalog.format_type(lat_att.atttypid, lat_att.atttypmod) AS column_type
        FROM pg_attribute lat_att

        JOIN pg_class lat_cls
            ON lat_cls.oid = lat_att.attrelid

        JOIN pg_namespace lat_ns
            ON lat_ns.oid = lat_cls.relnamespace

        WHERE lat_ns.nspname = 'credit_decisioning_sim'
          AND lat_cls.relname = 'strategy_decisions'
          AND lat_att.attnum > 0
          AND lat_att.attisdropped IS FALSE
    ),

    archive_columns AS (
        SELECT
            arc_att.attname AS column_name,
            pg_catalog.format_type(arc_att.atttypid, arc_att.atttypmod) AS column_type
        FROM pg_attribute arc_att

        JOIN pg_class arc_cls
            ON arc_cls.oid = arc_att.attrelid

        JOIN pg_namespace arc_ns
            ON arc_ns.oid = arc_cls.relnamespace

        WHERE arc_ns.nspname = 'credit_decisioning_sim'
          AND arc_cls.relname = 'strategy_decisions_archive'
          AND arc_att.attnum > 0
          AND arc_att.attisdropped IS FALSE
    ),

    type_mismatches AS (
        SELECT
            l.column_name,
            l.column_type AS latest_type,
            a.column_type AS archive_type
        FROM latest_columns l

        JOIN archive_columns a
            ON a.column_name = l.column_name

        WHERE a.column_type IS DISTINCT FROM l.column_type
    )

    SELECT
        COUNT(*),
        STRING_AGG(
            column_name || ' latest=' || latest_type || ' archive=' || archive_type,
            '; ' ORDER BY column_name
        )
    INTO
        v_type_mismatch_count,
        v_type_mismatch_columns
    FROM type_mismatches;

    IF v_type_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run / archive column type mismatch(es): %.',
            v_type_mismatch_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Verify archive has no unexpected columns other than archive_inserted_ts.

    Business interpretation:
        Unexpected archive columns usually indicate stale schema drift or manual alteration.
    -------------------------------------------------------------------------------------------*/
    WITH latest_columns AS (
        SELECT
            lat_att.attname AS column_name
        FROM pg_attribute lat_att

        JOIN pg_class lat_cls
            ON lat_cls.oid = lat_att.attrelid

        JOIN pg_namespace lat_ns
            ON lat_ns.oid = lat_cls.relnamespace

        WHERE lat_ns.nspname = 'credit_decisioning_sim'
          AND lat_cls.relname = 'strategy_decisions'
          AND lat_att.attnum > 0
          AND lat_att.attisdropped IS FALSE
    ),

    archive_columns AS (
        SELECT
            arc_att.attname AS column_name
        FROM pg_attribute arc_att

        JOIN pg_class arc_cls
            ON arc_cls.oid = arc_att.attrelid

        JOIN pg_namespace arc_ns
            ON arc_ns.oid = arc_cls.relnamespace

        WHERE arc_ns.nspname = 'credit_decisioning_sim'
          AND arc_cls.relname = 'strategy_decisions_archive'
          AND arc_att.attnum > 0
          AND arc_att.attisdropped IS FALSE
    ),

    unexpected_columns AS (
        SELECT
            a.column_name
        FROM archive_columns a

        LEFT JOIN latest_columns l
            ON l.column_name = a.column_name

        WHERE l.column_name IS NULL
          AND a.column_name <> 'archive_inserted_ts'
    )

    SELECT
        COUNT(*),
        STRING_AGG(column_name, ', ' ORDER BY column_name)
    INTO
        v_unexpected_archive_column_count,
        v_unexpected_archive_columns
    FROM unexpected_columns;

    IF v_unexpected_archive_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive table contains unexpected column(s): %. Review archive schema before persistence.',
            v_unexpected_archive_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Verify archive_inserted_ts exists.

    archive_inserted_ts is intentionally archive-only.
    It records when archive persistence occurred.
    -------------------------------------------------------------------------------------------*/
    SELECT EXISTS (
        SELECT 1
        FROM pg_attribute ins_att

        JOIN pg_class ins_cls
            ON ins_cls.oid = ins_att.attrelid

        JOIN pg_namespace ins_ns
            ON ins_ns.oid = ins_cls.relnamespace

        WHERE ins_ns.nspname = 'credit_decisioning_sim'
          AND ins_cls.relname = 'strategy_decisions_archive'
          AND ins_att.attname = 'archive_inserted_ts'
          AND ins_att.attnum > 0
          AND ins_att.attisdropped IS FALSE
    )
    INTO v_archive_inserted_ts_exists;

    IF v_archive_inserted_ts_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive table is missing archive_inserted_ts.';
    END IF;
END $$;
```

After applying this patch, rerun **M2-01 from Section 1**. You do not need to manually clear anything first. The failed run stopped inside Section 12 before archive persistence completed cleanly, and this Section 12.2 replacement is idempotent: `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, and the archive replacement logic downstream are designed for rerun safety.
<!-- END_MESSAGE C038-M01823 -->


---

<a id="c038-m01825"></a>

### C038-M01825

**Andrew** · 2026-05-13T09:39:06.790000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01825 -->
do I need to update any headers, etc outside of 12.2 as a result of that 12.2 change?
<!-- END_MESSAGE C038-M01825 -->


---

<a id="c038-m01829"></a>

### C038-M01829

**ChatGPT** · 2026-05-13T09:41:26.178247-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01829 -->
No. You do **not** need to update headers or commentary outside **Section 12.2** for this fix.

The change is purely an **implementation-safety correction** inside the Section 12.2 PL/pgSQL block: it avoids a variable / SQL-alias name collision by renaming the loop record and catalog aliases. It does **not** change Section 12’s business purpose, inputs, outputs, archive grain, archive replacement key, archive control modes, or downstream behavior. Section 12 is already described as the archive persistence layer that creates/reuses the archive, validates schema alignment, applies governed reset/replacement behavior, inserts current latest-run output, adds `archive_inserted_ts`, and validates archive grain/control behavior. fileciteturn311file35

I would leave these unchanged:

```text
Section 0 section map
Section 11 latest-run output header
Section 12 main header
Section 12.6 local archive persistence gatekeeper header
Section 13 comparison header
Section 16 evidence headers
Section 17 acceptance headers
```

The only optional polish is inside **Section 12.2 itself**. If you do not want the canonical file to say “WHY THIS PATCH EXISTS,” replace that subsection label with a more permanent wording:

```sql
WHY THIS IMPLEMENTATION USES DISTINCT CATALOG ALIASES:
    This block runs inside PL/pgSQL.

    PL/pgSQL variable names and SQL aliases can create name-resolution ambiguity when they share the
    same identifier.

    This implementation avoids that risk by:
        using add_col as the loop record variable;
        using explicit catalog aliases such as lat_cls, arc_cls, and ins_cls;
        avoiding pg_class c aliases inside the DO block.
```

That is optional. Functionally, the only required update is **Section 12.2**.
<!-- END_MESSAGE C038-M01829 -->


---

<a id="c038-m01831"></a>

### C038-M01831

**Andrew** · 2026-05-13T09:48:24.253000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01831 -->
another error: SQL Error [P0001]: ERROR: Module 2 Section 12 failure: latest-run / archive column type mismatch(es): application_seq latest=integer archive=bigint; reason_code_count latest=bigint archive=integer; strategy_run_ts latest=timestamp with time zone archive=timestamp without time zone. 
  Where: PL/pgSQL function inline_code_block line 209 at RAISE
  ERROR: Module 2 Section 12 failure: latest-run / archive column type mismatch(es): application_seq latest=integer archive=bigint; reason_code_count latest=bigint archive=integer; strategy_run_ts latest=timestamp with time zone archive=timestamp without time zone.
  Where: PL/pgSQL function inline_code_block line 209 at RAISE
<!-- END_MESSAGE C038-M01831 -->


---

<a id="c038-m01833"></a>

### C038-M01833

**ChatGPT** · 2026-05-13T09:52:33.750705-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01833 -->
This is a **persistent archive schema drift** issue from an older Module 2 archive table, not an M2-01 strategy logic issue.

Section 12 is doing the right thing: it compares the current latest-run table to the existing archive before inserting. Your existing `strategy_decisions_archive` was created under an older schema, so it now disagrees with the current `strategy_decisions` table on these fields:

```text
application_seq     latest=integer                  archive=bigint
reason_code_count   latest=bigint                   archive=integer
strategy_run_ts     latest=timestamp with time zone archive=timestamp without time zone
```

Section 12 is designed to create/reuse the archive, validate schema alignment, and stop before persistence if the archive schema is not aligned. The Section 12 commentary also says that if the latest-run schema changes after the archive already exists, the archive may need to be altered or recreated, and that Section 12 does not attempt to be a full dynamic schema migration system. fileciteturn314file35 fileciteturn314file67

## Recommended fix for your current full-campaign test

Because you are intentionally rerunning the full campaign as an execution test, I recommend a **clean persistent output reset** before restarting M2-01.

Run this **once** before rerunning M2-01 from Section 1:

```sql
/***************************************************************************************************
ONE-TIME MODULE 2 EXECUTION TEST RESET — PERSISTENT OUTPUTS ONLY

Purpose:
    Clear old Module 2 archive and evidence tables that may have been created under an earlier
    schema version.

Use when:
    You are intentionally rerunning the full Module 2 campaign from M2-01 through M2-36 and do not
    need to preserve prior Module 2 archive/evidence outputs from earlier development passes.

Do not drop:
    campaign registry tables
    comparison registry tables

Those are governed run-roadmap objects and should remain available.

***************************************************************************************************/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions_archive;

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_evidence_summary;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_validation_evidence;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_parameter_snapshot;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_segment_evidence_summary;
```

Then rerun:

```text
M2-01 from Section 1 through Section 16.8
```

That will let Section 12 recreate `strategy_decisions_archive` from the current latest-run schema, and Section 16 will recreate the evidence tables using the current evidence schema. Section 11 creates the current latest-run output, while Section 12 persists that already-materialized output into the governed archive. fileciteturn314file36 fileciteturn314file35

## Why I recommend reset instead of patching the archive types

You *could* alter the three mismatched archive columns, but because you are doing a full execution test, a clean reset is safer and clearer. It avoids carrying any old archive/evidence schema forward from prior development passes.

Do **not** drop these:

```sql
credit_decisioning_sim.strategy_run_campaign_registry
credit_decisioning_sim.strategy_comparison_campaign_registry
```

Those registry tables define the run map and comparison map. The campaign registry layer connects technical run keys to stable run IDs and comparison IDs for evidence and later documentation. fileciteturn314file13

## After reset

Use the same 36-run process:

```text
For each M2-01 through M2-36:
    set selected_module2_run_id = 'M2-##'
    run Sections 1–16.8

After M2-36:
    run fresh Section 15
    run Section 16.9
    run Section 17
```

The target final Section 17.20 status remains:

```sql
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```
<!-- END_MESSAGE C038-M01833 -->


---

<a id="c038-m01835"></a>

### C038-M01835

**Andrew** · 2026-05-13T10:00:29.768000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01835 -->
another error: SQL Error [42702]: ERROR: column reference "score_band_policy_key" is ambiguous
  Position: 4997
  ERROR: column reference "score_band_policy_key" is ambiguous
  Position: 4997
<!-- END_MESSAGE C038-M01835 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_89.md) · [Next](Part_91.md)
