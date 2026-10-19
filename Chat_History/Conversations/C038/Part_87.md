# Module 2 Decision Simulator Build

## Part 87

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_86.md) · [Next](Part_88.md)

<a id="c038-m01686"></a>

### C038-M01686

**ChatGPT** · 2026-05-12T22:39:00.157925-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01686 -->
According to a document from 2026-05-13, your current Section 17.20 already performs the final acceptance rollup, but the validation evidence check is still too compressed because it counts distinct runs with validation evidence rather than proving each run captured the full Section 14 validation spine. The replacement below makes that explicit with `expected_validation_rows_per_run = 18`, complete/incomplete validation run counts, and min/max validation rows per run. It also keeps the product-guardrail exact-value audit aligned to Section 17.19’s canonical UPL and revolving-line values. fileciteturn263file2 fileciteturn264file1

Replace your current **Section 17.20** with this full copy-paste version:

```sql
/***************************************************************************************************
SECTION 17.20 — FINAL MODULE 2 CAMPAIGN ACCEPTANCE ROLLUP
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the final one-row campaign acceptance status after archive, registry, evidence,
    convention, comparison, matched-source, and product-policy parameter checks.

    Section 17.20 answers:

        "Is the completed Module 2 campaign evidence structurally ready for executive analysis,
         validation-summary drafting, README interpretation, and LinkedIn storyline development?"

SQL PURPOSE:
    Confirm campaign acceptance across these gates:

        1. Campaign registry completeness.
        2. Comparison registry completeness.
        3. Archive inventory completeness.
        4. Archive row-level grain uniqueness.
        5. Comparison readiness.
        6. Matched source-field consistency.
        7. Executive evidence completeness.
        8. Parameter snapshot completeness.
        9. Validation evidence completeness.
        10. Segment evidence completeness.
        11. Full-archive final-output convention integrity.
        12. Product-guardrail exact-value parameter snapshot audit.

EXPECTED FINAL STATUS:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

WHY THIS VERSION IS CLEARER:
    Earlier versions confirmed that validation evidence existed for each campaign run.

    This version confirms each run has the complete Section 14 validation evidence spine:

        expected_validation_rows_per_run = 18

    That makes Section 17.20 a stronger final acceptance rollup because it can distinguish:

        "validation evidence exists"

    from:

        "the full validation evidence set was captured for every campaign run."

EXPECTED FORMAL CAMPAIGN SHAPE:
    active campaign registry rows:
        36

    active comparison registry rows:
        17

    archived strategy / scenario / population slices:
        36

    archived applicant rows:
        1,800,000

    rows per archived slice:
        50,000

    comparison-ready groups:
        17

    source-consistent comparison groups:
        17

    executive evidence rows:
        36

    parameter snapshot rows:
        36

    complete validation evidence runs:
        36 runs × 18 validation rows per run

    product-guardrail policy audit rows:
        5 product-guardrail runs × 2 audited products = 10 rows

ACCEPTANCE STATUS VALUES:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        Archive, registry, evidence, convention, comparison, source-consistency, and audited
        product-policy checks are clean.

    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        Structural, archive, evidence, convention, comparison, and source-consistency checks are
        clean, but the product-guardrail exact-value parameter audit requires review.

    REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        One or more structural, archive, registry, evidence, convention, comparison, source-field,
        validation, or parameter checks require review before final interpretation.

READ-ONLY BOUNDARY:
    Section 17.20 does not insert archive rows.
    Section 17.20 does not delete archive rows.
    Section 17.20 does not update archive rows.
    Section 17.20 does not modify latest-run rows.
    Section 17.20 does not modify evidence rows.
    Section 17.20 does not modify campaign registry rows.
    Section 17.20 does not modify comparison registry rows.
    Section 17.20 does not modify strategy parameter rows.
    Section 17.20 does not modify product-policy parameter rows.
    Section 17.20 does not recalculate decisions, approved exposure, approved Expected Loss, or
    simulated reason codes.

***************************************************************************************************/

WITH expected_campaign_shape AS (
    SELECT
        36::BIGINT AS expected_campaign_runs,
        17::BIGINT AS expected_comparison_groups,
        36::BIGINT AS expected_archive_slices,
        1800000::BIGINT AS expected_archive_rows,
        50000::BIGINT AS expected_rows_per_archive_slice,
        18::BIGINT AS expected_validation_rows_per_run,
        10::BIGINT AS expected_product_guardrail_policy_rows
),


/***************************************************************************************************
1. ACTIVE CAMPAIGN REGISTRY RUNS
***************************************************************************************************/

campaign_registry_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
),

registry_summary AS (
    SELECT
        COUNT(*) AS active_campaign_registry_rows
    FROM campaign_registry_runs
),


/***************************************************************************************************
2. ARCHIVE INVENTORY AND ARCHIVE GRAIN
***************************************************************************************************/

archive_inventory AS (
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

archive_summary AS (
    SELECT
        COUNT(*) AS archived_strategy_scenario_slices,

        COALESCE(SUM(archived_rows), 0)::BIGINT
            AS total_archived_rows,

        COUNT(*) FILTER (
            WHERE archived_rows <> 50000
        ) AS archive_slices_not_50000_rows,

        COUNT(*) FILTER (
            WHERE archived_rows <> distinct_application_id_count
        ) AS archive_slices_with_duplicate_application_ids
    FROM archive_inventory
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
    ) duplicate_archive_rows
),


/***************************************************************************************************
3. ACTIVE COMPARISON REGISTRY AND COMPARISON READINESS
***************************************************************************************************/

active_comparisons AS (
    SELECT
        comparison_group_id,

        baseline_strategy_set_name,
        baseline_strategy_name,
        baseline_strategy_version,

        challenger_strategy_set_name,
        challenger_strategy_name,
        challenger_strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
),

comparison_registry_summary AS (
    SELECT
        COUNT(*) AS active_comparison_registry_rows
    FROM active_comparisons
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
    SELECT
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
    SELECT
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
            WHEN COALESCE(b.archived_rows, 0) = 50000
             AND COALESCE(ch.archived_rows, 0) = 50000
             AND COALESCE(b.archived_rows, 0) = COALESCE(b.distinct_application_id_count, 0)
             AND COALESCE(ch.archived_rows, 0) = COALESCE(ch.distinct_application_id_count, 0)
             AND COALESCE(o.matched_application_id_count, 0) = 50000
             AND COALESCE(o.baseline_only_application_id_count, 0) = 0
             AND COALESCE(o.challenger_only_application_id_count, 0) = 0
                THEN 'COMPARISON_READY'

            ELSE 'COMPARISON_REVIEW_REQUIRED'
        END AS comparison_readiness_status

    FROM active_comparisons c

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

comparison_readiness AS (
    SELECT
        COUNT(*) AS comparison_group_count,

        COUNT(*) FILTER (
            WHERE comparison_readiness_status = 'COMPARISON_READY'
        ) AS comparison_ready_count,

        COUNT(*) FILTER (
            WHERE comparison_readiness_status <> 'COMPARISON_READY'
        ) AS comparison_review_count
    FROM comparison_readiness_by_group
),


/***************************************************************************************************
4. MATCHED SOURCE-FIELD CONSISTENCY
***************************************************************************************************/

comparison_source_rollup AS (
    SELECT
        c.comparison_group_id,

        COUNT(*) AS matched_application_count,

        COUNT(*) FILTER (
            WHERE b.product_type_policy_key IS DISTINCT FROM ch.product_type_policy_key
               OR b.score_band_policy_key IS DISTINCT FROM ch.score_band_policy_key
               OR b.credit_score IS DISTINCT FROM ch.credit_score
               OR b.annual_income IS DISTINCT FROM ch.annual_income
               OR b.requested_amount IS DISTINCT FROM ch.requested_amount
               OR b.requested_monthly_payment_proxy IS DISTINCT FROM ch.requested_monthly_payment_proxy
               OR b.requested_payment_to_income_ratio IS DISTINCT FROM ch.requested_payment_to_income_ratio
               OR b.amount_to_income_ratio IS DISTINCT FROM ch.amount_to_income_ratio
               OR b.estimated_pd IS DISTINCT FROM ch.estimated_pd
               OR b.estimated_lgd IS DISTINCT FROM ch.estimated_lgd
               OR b.requested_expected_loss_amount IS DISTINCT FROM ch.requested_expected_loss_amount
               OR b.module1_scenario_set_name IS DISTINCT FROM ch.module1_scenario_set_name
               OR b.module1_scenario_name IS DISTINCT FROM ch.module1_scenario_name
               OR b.population_id IS DISTINCT FROM ch.population_id
        ) AS source_field_mismatch_count

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

    GROUP BY c.comparison_group_id
),

source_consistency AS (
    SELECT
        COUNT(*) AS source_consistency_group_count,

        COUNT(*) FILTER (
            WHERE COALESCE(r.matched_application_count, 0) = 50000
              AND COALESCE(r.source_field_mismatch_count, 0) = 0
        ) AS source_consistency_pass_count,

        COUNT(*) FILTER (
            WHERE COALESCE(r.matched_application_count, 0) <> 50000
               OR COALESCE(r.source_field_mismatch_count, 0) <> 0
        ) AS source_consistency_review_count,

        COALESCE(SUM(COALESCE(r.source_field_mismatch_count, 0)), 0)::BIGINT
            AS total_source_field_mismatch_rows

    FROM active_comparisons c

    LEFT JOIN comparison_source_rollup r
        ON r.comparison_group_id = c.comparison_group_id
),


/***************************************************************************************************
5. SECTION 16 EVIDENCE COVERAGE BY ACTIVE CAMPAIGN RUN
***************************************************************************************************/

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

segment_evidence_by_run AS (
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

evidence_by_registry_run AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(p.parameter_snapshot_rows, 0) AS parameter_snapshot_rows,
        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(s.segment_rows, 0) AS segment_rows

    FROM campaign_registry_runs r

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

evidence_coverage AS (
    SELECT
        COUNT(*) AS registry_run_count_for_evidence_check,

        /*******************************************************************************************
        Executive evidence.
        Expected: one executive evidence row per active campaign registry run.
        *******************************************************************************************/
        COALESCE(SUM(executive_rows), 0)::BIGINT
            AS executive_evidence_rows,

        COUNT(*) FILTER (
            WHERE executive_rows = 1
        ) AS executive_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE executive_rows <> 1
        ) AS executive_evidence_issue_run_count,


        /*******************************************************************************************
        Parameter snapshot evidence.
        Expected: one parameter snapshot row per active campaign registry run.
        *******************************************************************************************/
        COALESCE(SUM(parameter_snapshot_rows), 0)::BIGINT
            AS parameter_snapshot_rows,

        COUNT(*) FILTER (
            WHERE parameter_snapshot_rows = 1
        ) AS parameter_snapshot_complete_run_count,

        COUNT(*) FILTER (
            WHERE parameter_snapshot_rows <> 1
        ) AS parameter_snapshot_issue_run_count,


        /*******************************************************************************************
        Validation evidence.
        Expected: 18 validation evidence rows per active campaign registry run.
        *******************************************************************************************/
        MAX(e.expected_validation_rows_per_run)
            AS expected_validation_rows_per_run,

        COUNT(*) FILTER (
            WHERE validation_rows = e.expected_validation_rows_per_run
        ) AS validation_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE validation_rows <> e.expected_validation_rows_per_run
        ) AS validation_evidence_incomplete_run_count,

        MIN(validation_rows) AS min_validation_rows_per_run,
        MAX(validation_rows) AS max_validation_rows_per_run,

        COALESCE(SUM(validation_rows), 0)::BIGINT
            AS total_validation_evidence_rows,


        /*******************************************************************************************
        Product × score segment evidence.
        Expected: segment evidence exists for every active campaign registry run.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE segment_rows > 0
        ) AS segment_evidence_run_count,

        COUNT(*) FILTER (
            WHERE segment_rows = 0
        ) AS segment_evidence_issue_run_count,

        MIN(segment_rows) AS min_segment_rows_per_run,
        MAX(segment_rows) AS max_segment_rows_per_run,

        COALESCE(SUM(segment_rows), 0)::BIGINT
            AS total_segment_evidence_rows

    FROM evidence_by_registry_run r

    CROSS JOIN expected_campaign_shape e
),


/***************************************************************************************************
6. FULL-ARCHIVE FINAL-OUTPUT CONVENTION INTEGRITY
***************************************************************************************************/

convention_violations AS (
    SELECT
        /*******************************************************************************************
        Final flag convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE (
                COALESCE(approval_flag::INT, 0)
                + COALESCE(counteroffer_flag::INT, 0)
                + COALESCE(manual_review_flag::INT, 0)
                + COALESCE(decline_flag::INT, 0)
            ) <> 1
        ) AS final_outcome_flag_count_violation_rows,

        /*******************************************************************************************
        Simulated offer exposure convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_violation_rows,

        /*******************************************************************************************
        Approved exposure / affordability / Expected Loss conventions.
        *******************************************************************************************/
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

        /*******************************************************************************************
        Simulated reason-code convention.
        *******************************************************************************************/
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

    FROM credit_decisioning_sim.strategy_decisions_archive
),

convention_summary AS (
    SELECT
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


/***************************************************************************************************
7. PRODUCT-GUARDRAIL EXACT-VALUE PARAMETER SNAPSHOT AUDIT
***************************************************************************************************/

product_guardrail_runs AS (
    SELECT
        module2_run_id,
        product_policy_params_jsonb
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
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
        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy AS (
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

    CROSS JOIN LATERAL jsonb_array_elements(r.product_policy_params_jsonb)
        AS pp(product_policy_row)

    WHERE pp.product_policy_row ->> 'product_type' IN (
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    )
),

product_guardrail_policy_audit AS (
    SELECT
        COUNT(*) AS expected_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NULL
        ) AS missing_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NOT NULL
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

    FROM expected_run_product_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
),


/***************************************************************************************************
8. FINAL ACCEPTANCE INPUTS AND STATUS FLAGS
***************************************************************************************************/

acceptance_inputs AS (
    SELECT
        /*******************************************************************************************
        Expected campaign shape.
        *******************************************************************************************/
        x.expected_campaign_runs,
        x.expected_comparison_groups,
        x.expected_archive_slices,
        x.expected_archive_rows,
        x.expected_rows_per_archive_slice,
        x.expected_validation_rows_per_run,
        x.expected_product_guardrail_policy_rows,

        /*******************************************************************************************
        Registry and archive.
        *******************************************************************************************/
        rr.active_campaign_registry_rows,
        cr.active_comparison_registry_rows,

        a.archived_strategy_scenario_slices,
        a.total_archived_rows,
        a.archive_slices_not_50000_rows,
        a.archive_slices_with_duplicate_application_ids,

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

        ev.segment_evidence_run_count,
        ev.segment_evidence_issue_run_count,
        ev.min_segment_rows_per_run,
        ev.max_segment_rows_per_run,
        ev.total_segment_evidence_rows,

        /*******************************************************************************************
        Final-output conventions.
        *******************************************************************************************/
        cv.critical_convention_violation_count,

        /*******************************************************************************************
        Product guardrail policy exact-value audit.
        *******************************************************************************************/
        pga.expected_product_guardrail_policy_rows AS actual_product_guardrail_policy_rows_checked,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_mismatch_rows,


        /*******************************************************************************************
        Gate-level flags.

        These are included in the output to make the final acceptance result easy to troubleshoot.
        *******************************************************************************************/
        (
            rr.active_campaign_registry_rows = x.expected_campaign_runs
        ) AS campaign_registry_ready_flag,

        (
            cr.active_comparison_registry_rows = x.expected_comparison_groups
        ) AS comparison_registry_ready_flag,

        (
            a.archived_strategy_scenario_slices = x.expected_archive_slices
            AND a.total_archived_rows = x.expected_archive_rows
            AND a.archive_slices_not_50000_rows = 0
            AND a.archive_slices_with_duplicate_application_ids = 0
            AND agd.duplicate_archive_grain_count = 0
        ) AS archive_ready_flag,

        (
            cmp.comparison_group_count = x.expected_comparison_groups
            AND cmp.comparison_ready_count = x.expected_comparison_groups
            AND cmp.comparison_review_count = 0
        ) AS comparison_ready_flag,

        (
            src.source_consistency_group_count = x.expected_comparison_groups
            AND src.source_consistency_pass_count = x.expected_comparison_groups
            AND src.source_consistency_review_count = 0
            AND src.total_source_field_mismatch_rows = 0
        ) AS source_consistency_ready_flag,

        (
            ev.registry_run_count_for_evidence_check = x.expected_campaign_runs
            AND ev.executive_evidence_complete_run_count = x.expected_campaign_runs
            AND ev.executive_evidence_issue_run_count = 0
            AND ev.parameter_snapshot_complete_run_count = x.expected_campaign_runs
            AND ev.parameter_snapshot_issue_run_count = 0
            AND ev.validation_evidence_complete_run_count = x.expected_campaign_runs
            AND ev.validation_evidence_incomplete_run_count = 0
            AND ev.min_validation_rows_per_run = x.expected_validation_rows_per_run
            AND ev.max_validation_rows_per_run = x.expected_validation_rows_per_run
            AND ev.segment_evidence_run_count = x.expected_campaign_runs
            AND ev.segment_evidence_issue_run_count = 0
        ) AS evidence_ready_flag,

        (
            cv.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,

        (
            pga.expected_product_guardrail_policy_rows = x.expected_product_guardrail_policy_rows
            AND pga.missing_product_guardrail_policy_rows = 0
            AND pga.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag

    FROM expected_campaign_shape x
    CROSS JOIN registry_summary rr
    CROSS JOIN comparison_registry_summary cr
    CROSS JOIN archive_summary a
    CROSS JOIN archive_grain_duplicates agd
    CROSS JOIN comparison_readiness cmp
    CROSS JOIN source_consistency src
    CROSS JOIN evidence_coverage ev
    CROSS JOIN convention_summary cv
    CROSS JOIN product_guardrail_policy_audit pga
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
    Expected campaign shape.
    ***********************************************************************************************/
    expected_campaign_runs,
    expected_comparison_groups,
    expected_archive_slices,
    expected_archive_rows,
    expected_rows_per_archive_slice,
    expected_validation_rows_per_run,
    expected_product_guardrail_policy_rows,


    /***********************************************************************************************
    Registry and archive evidence.
    ***********************************************************************************************/
    active_campaign_registry_rows,
    active_comparison_registry_rows,

    archived_strategy_scenario_slices,
    total_archived_rows,
    archive_slices_not_50000_rows,
    archive_slices_with_duplicate_application_ids,
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

    Validation evidence is intentionally exact:
        18 rows per run in the current Section 14 design.
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

    segment_evidence_run_count,
    segment_evidence_issue_run_count,
    min_segment_rows_per_run,
    max_segment_rows_per_run,
    total_segment_evidence_rows,


    /***********************************************************************************************
    Convention and parameter audit evidence.
    ***********************************************************************************************/
    critical_convention_violation_count,

    actual_product_guardrail_policy_rows_checked,
    missing_product_guardrail_policy_rows,
    product_guardrail_policy_mismatch_rows

FROM acceptance_status;
```
<!-- END_MESSAGE C038-M01686 -->


---

<a id="c038-m01688"></a>

### C038-M01688

**Andrew** · 2026-05-12T23:06:44.380000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01688 -->
review updated full code:
<!-- END_MESSAGE C038-M01688 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(1).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01710"></a>

### C038-M01710

**ChatGPT** · 2026-05-12T23:14:35.274661-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01710 -->
According to a document from 2026-05-13, the updated full Module 2 SQL is in **strong release-candidate shape**. I would not do another broad rewrite. The latest changes landed in the right places: Section 1.4 now includes the Section 14 helper cleanup, Section 14 has the local helper reset/context logic, Section 17.7 and 17.8 now test complete validation-evidence capture rather than `validation_rows > 0`, and Section 17.20 now carries the stronger final acceptance rollup. fileciteturn268file15 fileciteturn268file14 fileciteturn268file0 fileciteturn268file9

## Overall verdict

**Static review status: ready for final database execution testing.**

I did not execute this against PostgreSQL, so I would treat this as a **validation-ready release candidate** until the full runtime path succeeds and Section 17.20 returns:

```sql
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```

After that runtime acceptance, the “FINAL VALIDATED RELEASE” banner is defensible.

## What is now correct

**Section 1.4 is now aligned with Section 14.** It includes `tmp_m2_validation_archive_readiness_context`, `tmp_m2_validation_comparison_readiness_context`, `tmp_m2_validation_source_consistency_context`, and `tmp_m2_validation_status_summary`, and the comments correctly explain why Section 14 also drops those objects locally for rerun safety. fileciteturn268file15

**Section 14 is aligned with the helper-table design.** Section 14.0A locally drops the Section 14 helpers, Section 14.0B creates the archive-readiness context, and the later Section 14.18 outputs read the archive, comparison, and source-consistency context helpers. fileciteturn268file14 fileciteturn268file5

**Section 14.19 still has the correct evidence-spine contract.** It creates `tmp_m2_validation_status_summary` with the expected validation areas and status model. The updated design explicitly feeds Section 16 evidence capture, which is what we wanted. fileciteturn268file8

**Section 17 evidence completeness is now much stronger.** Section 17.7 and 17.8 now expect 18 validation evidence rows per run, rather than merely checking that validation rows exist. This is the right final-campaign standard because it verifies the full Section 14 validation spine was captured for every run. fileciteturn268file0

**Section 17.20 is now much clearer.** It defines the campaign acceptance gates, the expected campaign shape, the exact 18 validation rows per run, and the final acceptance statuses. It also exposes review-focus flags so a failed rollup is easier to troubleshoot. fileciteturn268file9 fileciteturn268file10 fileciteturn268file12

## Static checks I performed on the uploaded file

I checked the actual uploaded full file text, not only the snippets.

| Check | Result |
|---|---:|
| File size reviewed | ~2.2M characters |
| Lines reviewed | ~58.8K lines |
| Block comments `/* ... */` | Balanced |
| `DO $$ ... END $$;` blocks after removing comments | Balanced |
| Parentheses after removing comments / quoted strings | Balanced |
| Section header duplicates | No duplicate formal section headers found |
| Section 14.0–14.20 coverage | Present |
| Section 16.9 | Present |
| Section 17.1–17.20 coverage | Present |
| Section 14.19 validation rows | 18 |
| Section 17.20 | Present once |

That is good structural evidence. It does not replace a live PostgreSQL run, but it reduces the risk of copy/paste fragmentation, missing section blocks, or obvious syntax-shape problems.

## Minor remaining items

### 1. Update Section 0.18 physical stage flow

This is a **comment-only consistency update**. Section 0.18 still lists `tmp_m2_validation_status_summary`, but it does not list the three new Section 14 validation context helpers. The runtime code is fine; this is documentation hygiene.

In Section 0.18, under:

```sql
Temporary comparison, validation, frontier, and evidence helpers:
```

add these immediately before `tmp_m2_validation_status_summary`:

```sql
    tmp_m2_validation_archive_readiness_context
    tmp_m2_validation_comparison_readiness_context
    tmp_m2_validation_source_consistency_context
```

### 2. Optional hardening for Section 17.19 / 17.20 product-guardrail audit

The product-guardrail audit currently reads from `strategy_run_parameter_snapshot` where `strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'`. That works if the evidence table contains only the formal campaign rows. For maximum formal-campaign discipline, I would eventually filter those rows through the active campaign registry so old ad hoc/custom product-guardrail snapshots cannot inflate the expected product-guardrail audit count.

This is **not urgent** if the evidence tables are clean and only contain the accepted 36 campaign runs. It is a good hardening improvement if you expect to keep ad hoc development evidence in the same persistent evidence tables.

### 3. Runtime acceptance still matters

The next real test is execution, not commentary. The file now expects the final workflow:

```text
all planned runs through Section 16.8
→ fresh Section 15
→ Section 16.9 synchronization
→ Section 17 final acceptance
```

That workflow is also documented in the final Section 17 guidance. fileciteturn268file7

## Final recommendation

Do **not** reopen broad section rewrites.

Make the small **Section 0.18 comment-only helper list update**, then run the final database execution path. If Section 17.20 returns `MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS`, I would consider the SQL implementation accepted within the documented synthetic-simulation boundaries.
<!-- END_MESSAGE C038-M01710 -->


---

<a id="c038-m01712"></a>

### C038-M01712

**Andrew** · 2026-05-12T23:27:05.024000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01712 -->
please advise on the before / after update in full copy paste for 2. Optional hardening for Section 17.19 / 17.20 product-guardrail audit
<!-- END_MESSAGE C038-M01712 -->


---

<a id="c038-m01723"></a>

### C038-M01723

**ChatGPT** · 2026-05-12T23:34:23.300240-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01723 -->
According to a document from 2026-05-13, the current product-guardrail audit logic is technically correct for a clean evidence table, but it scopes product-guardrail runs by `strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'` directly from `strategy_run_parameter_snapshot`. The hardening change is to scope the audit through the **active campaign registry first**, then join to parameter snapshots. That prevents old ad hoc/custom product-guardrail evidence rows from inflating the expected 10-row audit. fileciteturn273file3

## Recommendation

Make the hardening change.

This is a good targeted improvement because Section 17 is the final acceptance layer and should evaluate the formal campaign, not any stray historical evidence rows. The final Section 17 workflow is intended to review completed campaign archive, registry, comparison, validation, parameter-snapshot, product-policy, and evidence objects after all runs and Section 16.9 synchronization are complete. fileciteturn273file17

---

# 1. Section 17.19 product-guardrail audit

## Before

The current Section 17.19 starts its audit scope like this:

```sql
WITH product_guardrail_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_name,
        product_policy_params_jsonb
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),
```

That works if the parameter snapshot table contains only the formal campaign rows. The risk is that an old ad hoc/custom run with the same `strategy_name` could be included.

## After

Replace the **full current Section 17.19** with this registry-scoped version:

```sql
/***************************************************************************************************
SECTION 17.19 — PRODUCT GUARDRAIL POLICY SNAPSHOT EXACT-VALUE AUDIT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that formal campaign PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs captured the intended
    canonical product-guardrail values for:

        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

WHY THIS MATTERS:
    Structural campaign acceptance can pass even when a product-policy parameter was populated with
    the wrong value.

    This exact-value audit closes that gap.

WHY THIS VERSION IS REGISTRY-SCOPED:
    The audit now starts from active formal campaign registry rows and then joins to parameter
    snapshots.

    This prevents old ad hoc/custom PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY evidence rows from inflating
    the expected product-guardrail audit count.

EXPECTED RESULT:
    10 rows:
        5 formal product-guardrail campaign runs × 2 audited products.

    Each row should show:
        parameter_snapshot_rows_for_run = 1
        product_policy_field_mismatch_count = 0
        product_guardrail_policy_value_status = PRODUCT_GUARDRAIL_POLICY_VALUES_MATCH

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

        /*
        If duplicate parameter snapshots exist for the same run key, this keeps the most recent
        product-policy payload for display while still surfacing the duplicate count.
        */
        (ARRAY_AGG(product_policy_params_jsonb ORDER BY evidence_snapshot_ts DESC))[1]
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

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.parameter_snapshot_rows_for_run,

        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.parameter_snapshot_rows_for_run,

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

policy_comparison_raw AS (
    SELECT
        e.module2_run_id,
        e.run_sequence_number,

        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,

        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,

        e.parameter_snapshot_rows_for_run,

        e.product_type,

        e.expected_product_approve_max_pti,
        a.actual_product_approve_max_pti,

        e.expected_product_review_max_pti,
        a.actual_product_review_max_pti,

        e.expected_product_decline_min_pti,
        a.actual_product_decline_min_pti,

        e.expected_counteroffer_target_pti,
        a.actual_counteroffer_target_pti,

        e.expected_product_approve_max_requested_el,
        a.actual_product_approve_max_requested_el,

        e.expected_product_review_max_requested_el,
        a.actual_product_review_max_requested_el,

        e.expected_product_decline_min_requested_el,
        a.actual_product_decline_min_requested_el,

        e.expected_product_approved_el_cap,
        a.actual_product_approved_el_cap,

        e.expected_product_min_approved_amount,
        a.actual_product_min_approved_amount,

        e.expected_product_max_approved_amount,
        a.actual_product_max_approved_amount,

        e.expected_product_min_counteroffer_pct,
        a.actual_product_min_counteroffer_pct,

        e.expected_product_max_exposure_reduction_pct,
        a.actual_product_max_exposure_reduction_pct,

        CASE
            WHEN a.product_type IS NULL
                THEN 13

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
),

policy_comparison AS (
    SELECT
        p.*,

        CASE
            WHEN parameter_snapshot_rows_for_run = 0
                THEN 'PRODUCT_GUARDRAIL_PARAMETER_SNAPSHOT_MISSING'

            WHEN parameter_snapshot_rows_for_run > 1
                THEN 'PRODUCT_GUARDRAIL_PARAMETER_SNAPSHOT_DUPLICATE_REVIEW_REQUIRED'

            WHEN product_policy_field_mismatch_count = 0
                THEN 'PRODUCT_GUARDRAIL_POLICY_VALUES_MATCH'

            WHEN product_policy_field_mismatch_count = 13
                THEN 'PRODUCT_GUARDRAIL_POLICY_ROW_MISSING'

            ELSE 'PRODUCT_GUARDRAIL_POLICY_VALUE_MISMATCH'
        END AS product_guardrail_policy_value_status

    FROM policy_comparison_raw p
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
    product_guardrail_policy_value_status

FROM policy_comparison

ORDER BY
    run_sequence_number,
    product_type;
```

---

# 2. Section 17.20 product-guardrail audit

## Before

In the current Section 17.20, the product-guardrail CTE starts from parameter snapshots only:

```sql
product_guardrail_runs AS (
    SELECT
        module2_run_id,
        product_policy_params_jsonb
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),
```

That should be hardened the same way: start from formal active campaign registry rows, then join to parameter snapshots.

## After — targeted Section 17.20 patch

You do **not** need to replace all of Section 17.20 again. Replace the product-guardrail-related pieces below.

### 17.20A — update `expected_campaign_shape`

Replace your current `expected_campaign_shape` CTE with this:

```sql
WITH expected_campaign_shape AS (
    SELECT
        36::BIGINT AS expected_campaign_runs,
        17::BIGINT AS expected_comparison_groups,
        36::BIGINT AS expected_archive_slices,
        1800000::BIGINT AS expected_archive_rows,
        50000::BIGINT AS expected_rows_per_archive_slice,
        18::BIGINT AS expected_validation_rows_per_run,

        /*******************************************************************************************
        Product-guardrail audit expectation.

        Formal campaign has five PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs:

            M2-06
            M2-23
            M2-26
            M2-34
            M2-36

        Each run audits two products:

            UNSECURED_PERSONAL_LOAN
            REVOLVING_LINE

        Expected audit rows:
            5 × 2 = 10.
        *******************************************************************************************/
        5::BIGINT AS expected_product_guardrail_campaign_runs,
        10::BIGINT AS expected_product_guardrail_policy_rows
),
```

### 17.20B — replace the entire product-guardrail CTE cluster

In Section 17.20, replace the block beginning at:

```sql
product_guardrail_runs AS (
```

through the end of:

```sql
product_guardrail_policy_audit AS (
    ...
),
```

with this:

```sql
/***************************************************************************************************
7. PRODUCT-GUARDRAIL EXACT-VALUE PARAMETER SNAPSHOT AUDIT
***************************************************************************************************/

product_guardrail_campaign_runs AS (
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

        /*
        If duplicate parameter snapshots exist for the same run key, this keeps the most recent
        product-policy payload for the value comparison while the duplicate count remains visible.
        */
        (ARRAY_AGG(product_policy_params_jsonb ORDER BY evidence_snapshot_ts DESC))[1]
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

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.parameter_snapshot_rows_for_run,

        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy AS (
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

product_guardrail_policy_audit AS (
    SELECT
        /*******************************************************************************************
        Formal product-guardrail campaign run scope.
        *******************************************************************************************/
        (
            SELECT COUNT(*)
            FROM product_guardrail_campaign_runs
        ) AS product_guardrail_campaign_run_count,

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

        /*******************************************************************************************
        Exact-value audit row scope.
        *******************************************************************************************/
        COUNT(*) AS expected_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NULL
        ) AS missing_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NOT NULL
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

    FROM expected_run_product_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
),
```

### 17.20C — update `acceptance_inputs`

Inside `acceptance_inputs AS (...)`, add these selected fields near the existing product-guardrail fields:

```sql
        x.expected_product_guardrail_campaign_runs,
```

Then replace the current product-guardrail audit fields with these:

```sql
        /*******************************************************************************************
        Product guardrail policy exact-value audit.
        *******************************************************************************************/
        pga.product_guardrail_campaign_run_count,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,

        pga.expected_product_guardrail_policy_rows AS actual_product_guardrail_policy_rows_checked,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_mismatch_rows,
```

Finally, replace the current `product_guardrail_policy_ready_flag` logic with this:

```sql
        (
            pga.product_guardrail_campaign_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_complete_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
            AND pga.expected_product_guardrail_policy_rows = x.expected_product_guardrail_policy_rows
            AND pga.missing_product_guardrail_policy_rows = 0
            AND pga.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag
```

### 17.20D — update the final `SELECT`

In the final `SELECT`, add this field near the expected campaign shape fields:

```sql
    expected_product_guardrail_campaign_runs,
```

Then replace the current product-guardrail output fields with these:

```sql
    product_guardrail_campaign_run_count,
    product_guardrail_parameter_snapshot_complete_run_count,
    product_guardrail_parameter_snapshot_issue_run_count,

    actual_product_guardrail_policy_rows_checked,
    missing_product_guardrail_policy_rows,
    product_guardrail_policy_mismatch_rows
```

---

## Net effect of the patch

After this hardening, Section 17.19 and Section 17.20 will audit only the **five formal active campaign product-guardrail runs**, not any historical ad hoc/custom evidence rows that happen to share `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY`.

Expected clean result:

```text
product_guardrail_campaign_run_count = 5
product_guardrail_parameter_snapshot_complete_run_count = 5
product_guardrail_parameter_snapshot_issue_run_count = 0
actual_product_guardrail_policy_rows_checked = 10
missing_product_guardrail_policy_rows = 0
product_guardrail_policy_mismatch_rows = 0
product_guardrail_policy_ready_flag = true
```

This is a cleaner final-campaign acceptance standard.
<!-- END_MESSAGE C038-M01723 -->


---

<a id="c038-m01725"></a>

### C038-M01725

**Andrew** · 2026-05-13T00:03:26.834000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01725 -->
make this update simpler.  provide as one full copy paste for this section.
<!-- END_MESSAGE C038-M01725 -->


---

<a id="c038-m01730"></a>

### C038-M01730

**Andrew** · 2026-05-13T00:07:59.495000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01730 -->
17.20C — update acceptance_inputs - make this simpler - provide as one full copy paste for this section
<!-- END_MESSAGE C038-M01730 -->


---

<a id="c038-m01732"></a>

### C038-M01732

**ChatGPT** · 2026-05-13T00:08:31.931759-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01732 -->
Here is a **single full copy-paste replacement for Section 17.20 only**. It keeps the final acceptance rollup readable, and it hardens the product-guardrail audit by scoping it through the active campaign registry before joining to parameter snapshots. That prevents historical ad hoc `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` snapshots from inflating the final campaign audit. The current Section 17.20 is already the final acceptance rollup, and Section 16.4 stores `product_policy_params_jsonb`, which is the correct payload for this exact-value audit. fileciteturn274file1 fileciteturn274file18

```sql
/***************************************************************************************************
SECTION 17.20 — FINAL MODULE 2 CAMPAIGN ACCEPTANCE ROLLUP
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the final one-row campaign acceptance status after archive, registry, comparison,
    matched-source, evidence, convention, validation, and product-policy parameter checks.

    Section 17.20 answers:

        "Is the completed Module 2 campaign structurally ready for executive analysis,
         validation-summary drafting, README interpretation, and LinkedIn storyline development?"

SQL PURPOSE:
    Confirm final campaign acceptance across these gates:

        1. Active campaign registry completeness.
        2. Active comparison registry completeness.
        3. Archive inventory completeness.
        4. Archive row-level grain uniqueness.
        5. Comparison readiness.
        6. Matched source-field consistency.
        7. Section 16 evidence completeness.
        8. Full-archive final-output convention integrity.
        9. Product-guardrail exact-value parameter snapshot audit.

WHY PRODUCT-GUARDRAIL AUDIT IS REGISTRY-SCOPED:
    The product-guardrail audit starts from active formal campaign registry rows and then joins to
    parameter snapshots.

    This prevents old ad hoc or custom PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY evidence rows from
    affecting final campaign acceptance.

EXPECTED FORMAL CAMPAIGN SHAPE:
    active campaign registry rows:
        36

    active comparison registry rows:
        17

    archived strategy / scenario / population slices:
        36

    archived applicant rows:
        1,800,000

    rows per archived slice:
        50,000

    comparison-ready groups:
        17

    source-consistent comparison groups:
        17

    executive evidence rows:
        36

    parameter snapshot rows:
        36

    complete validation evidence runs:
        36 runs × 18 validation rows per run

    product-guardrail policy audit:
        5 formal product-guardrail campaign runs × 2 audited products = 10 rows

EXPECTED FINAL STATUS:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

READ-ONLY BOUNDARY:
    Section 17.20 does not insert archive rows.
    Section 17.20 does not delete archive rows.
    Section 17.20 does not update archive rows.
    Section 17.20 does not modify latest-run rows.
    Section 17.20 does not modify evidence rows.
    Section 17.20 does not modify campaign registry rows.
    Section 17.20 does not modify comparison registry rows.
    Section 17.20 does not modify strategy parameter rows.
    Section 17.20 does not modify product-policy parameter rows.
    Section 17.20 does not recalculate decisions, approved exposure, approved Expected Loss, or
    simulated reason codes.

***************************************************************************************************/

WITH expected_campaign_shape AS (
    SELECT
        36::BIGINT AS expected_campaign_runs,
        17::BIGINT AS expected_comparison_groups,
        36::BIGINT AS expected_archive_slices,
        1800000::BIGINT AS expected_archive_rows,
        50000::BIGINT AS expected_rows_per_archive_slice,
        18::BIGINT AS expected_validation_rows_per_run,
        5::BIGINT AS expected_product_guardrail_campaign_runs,
        10::BIGINT AS expected_product_guardrail_policy_rows
),


/***************************************************************************************************
1. ACTIVE CAMPAIGN REGISTRY RUNS
***************************************************************************************************/

campaign_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,

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
        COUNT(*) AS active_campaign_registry_rows
    FROM campaign_runs
),


/***************************************************************************************************
2. ARCHIVE INVENTORY AND ARCHIVE GRAIN
***************************************************************************************************/

archive_slices AS (
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

archive_summary AS (
    SELECT
        COUNT(*) AS archived_strategy_scenario_slices,
        COALESCE(SUM(archived_rows), 0)::BIGINT AS total_archived_rows,

        COUNT(*) FILTER (
            WHERE archived_rows <> 50000
        ) AS archive_slices_not_50000_rows,

        COUNT(*) FILTER (
            WHERE archived_rows <> distinct_application_id_count
        ) AS archive_slices_with_duplicate_application_ids
    FROM archive_slices
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
    ) d
),


/***************************************************************************************************
3. ACTIVE COMPARISON REGISTRY AND COMPARISON READINESS
***************************************************************************************************/

active_comparisons AS (
    SELECT
        comparison_group_id,

        baseline_strategy_set_name,
        baseline_strategy_name,
        baseline_strategy_version,

        challenger_strategy_set_name,
        challenger_strategy_name,
        challenger_strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
),

comparison_registry_summary AS (
    SELECT
        COUNT(*) AS active_comparison_registry_rows
    FROM active_comparisons
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

comparison_overlap AS (
    SELECT
        COALESCE(b.comparison_group_id, ch.comparison_group_id) AS comparison_group_id,

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

comparison_readiness_by_group AS (
    SELECT
        c.comparison_group_id,

        COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
        COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

        COALESCE(b.distinct_application_id_count, 0) AS baseline_distinct_application_id_count,
        COALESCE(ch.distinct_application_id_count, 0) AS challenger_distinct_application_id_count,

        COALESCE(o.matched_application_id_count, 0) AS matched_application_id_count,
        COALESCE(o.baseline_only_application_id_count, 0) AS baseline_only_application_id_count,
        COALESCE(o.challenger_only_application_id_count, 0) AS challenger_only_application_id_count,

        CASE
            WHEN COALESCE(b.archived_rows, 0) = 50000
             AND COALESCE(ch.archived_rows, 0) = 50000
             AND COALESCE(b.distinct_application_id_count, 0) = 50000
             AND COALESCE(ch.distinct_application_id_count, 0) = 50000
             AND COALESCE(o.matched_application_id_count, 0) = 50000
             AND COALESCE(o.baseline_only_application_id_count, 0) = 0
             AND COALESCE(o.challenger_only_application_id_count, 0) = 0
                THEN 'COMPARISON_READY'

            ELSE 'COMPARISON_REVIEW_REQUIRED'
        END AS comparison_readiness_status

    FROM active_comparisons c

    LEFT JOIN archive_slices b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id

    LEFT JOIN archive_slices ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id

    LEFT JOIN comparison_overlap o
        ON o.comparison_group_id = c.comparison_group_id
),

comparison_readiness_summary AS (
    SELECT
        COUNT(*) AS comparison_group_count,

        COUNT(*) FILTER (
            WHERE comparison_readiness_status = 'COMPARISON_READY'
        ) AS comparison_ready_count,

        COUNT(*) FILTER (
            WHERE comparison_readiness_status <> 'COMPARISON_READY'
        ) AS comparison_review_count
    FROM comparison_readiness_by_group
),


/***************************************************************************************************
4. MATCHED SOURCE-FIELD CONSISTENCY
***************************************************************************************************/

source_consistency_by_group AS (
    SELECT
        c.comparison_group_id,

        COUNT(*) AS matched_application_count,

        COUNT(*) FILTER (
            WHERE b.product_type_policy_key IS DISTINCT FROM ch.product_type_policy_key
               OR b.score_band_policy_key IS DISTINCT FROM ch.score_band_policy_key
               OR b.credit_score IS DISTINCT FROM ch.credit_score
               OR b.annual_income IS DISTINCT FROM ch.annual_income
               OR b.requested_amount IS DISTINCT FROM ch.requested_amount
               OR b.requested_monthly_payment_proxy IS DISTINCT FROM ch.requested_monthly_payment_proxy
               OR b.requested_payment_to_income_ratio IS DISTINCT FROM ch.requested_payment_to_income_ratio
               OR b.amount_to_income_ratio IS DISTINCT FROM ch.amount_to_income_ratio
               OR b.estimated_pd IS DISTINCT FROM ch.estimated_pd
               OR b.estimated_lgd IS DISTINCT FROM ch.estimated_lgd
               OR b.requested_expected_loss_amount IS DISTINCT FROM ch.requested_expected_loss_amount
               OR b.module1_scenario_set_name IS DISTINCT FROM ch.module1_scenario_set_name
               OR b.module1_scenario_name IS DISTINCT FROM ch.module1_scenario_name
               OR b.population_id IS DISTINCT FROM ch.population_id
        ) AS source_field_mismatch_count

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

    GROUP BY c.comparison_group_id
),

source_consistency_summary AS (
    SELECT
        COUNT(*) AS source_consistency_group_count,

        COUNT(*) FILTER (
            WHERE COALESCE(s.matched_application_count, 0) = 50000
              AND COALESCE(s.source_field_mismatch_count, 0) = 0
        ) AS source_consistency_pass_count,

        COUNT(*) FILTER (
            WHERE COALESCE(s.matched_application_count, 0) <> 50000
               OR COALESCE(s.source_field_mismatch_count, 0) <> 0
        ) AS source_consistency_review_count,

        COALESCE(SUM(COALESCE(s.source_field_mismatch_count, 0)), 0)::BIGINT
            AS total_source_field_mismatch_rows

    FROM active_comparisons c

    LEFT JOIN source_consistency_by_group s
        ON s.comparison_group_id = c.comparison_group_id
),


/***************************************************************************************************
5. SECTION 16 EVIDENCE COMPLETENESS
***************************************************************************************************/

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

segment_evidence_by_run AS (
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

evidence_by_campaign_run AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(p.parameter_snapshot_rows, 0) AS parameter_snapshot_rows,
        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(s.segment_rows, 0) AS segment_rows

    FROM campaign_runs r

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

        COALESCE(SUM(executive_rows), 0)::BIGINT AS executive_evidence_rows,
        COUNT(*) FILTER (WHERE executive_rows = 1) AS executive_evidence_complete_run_count,
        COUNT(*) FILTER (WHERE executive_rows <> 1) AS executive_evidence_issue_run_count,

        COALESCE(SUM(parameter_snapshot_rows), 0)::BIGINT AS parameter_snapshot_rows,
        COUNT(*) FILTER (WHERE parameter_snapshot_rows = 1) AS parameter_snapshot_complete_run_count,
        COUNT(*) FILTER (WHERE parameter_snapshot_rows <> 1) AS parameter_snapshot_issue_run_count,

        COUNT(*) FILTER (
            WHERE validation_rows = e.expected_validation_rows_per_run
        ) AS validation_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE validation_rows <> e.expected_validation_rows_per_run
        ) AS validation_evidence_incomplete_run_count,

        MIN(validation_rows) AS min_validation_rows_per_run,
        MAX(validation_rows) AS max_validation_rows_per_run,
        COALESCE(SUM(validation_rows), 0)::BIGINT AS total_validation_evidence_rows,

        COUNT(*) FILTER (WHERE segment_rows > 0) AS segment_evidence_run_count,
        COUNT(*) FILTER (WHERE segment_rows = 0) AS segment_evidence_issue_run_count,
        MIN(segment_rows) AS min_segment_rows_per_run,
        MAX(segment_rows) AS max_segment_rows_per_run,
        COALESCE(SUM(segment_rows), 0)::BIGINT AS total_segment_evidence_rows

    FROM evidence_by_campaign_run r
    CROSS JOIN expected_campaign_shape e
),


/***************************************************************************************************
6. FULL-ARCHIVE FINAL-OUTPUT CONVENTION INTEGRITY
***************************************************************************************************/

convention_violations AS (
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

    FROM credit_decisioning_sim.strategy_decisions_archive
),

convention_summary AS (
    SELECT
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


/***************************************************************************************************
7. REGISTRY-SCOPED PRODUCT-GUARDRAIL EXACT-VALUE PARAMETER AUDIT
***************************************************************************************************/

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
    FROM campaign_runs
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

        COALESCE(p.parameter_snapshot_rows_for_run, 0) AS parameter_snapshot_rows_for_run,
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
        r.run_sequence_number,
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

product_guardrail_policy_audit AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM product_guardrail_campaign_runs
        ) AS product_guardrail_campaign_run_count,

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

        COUNT(*) AS actual_product_guardrail_policy_rows_checked,

        COUNT(*) FILTER (
            WHERE a.product_type IS NULL
        ) AS missing_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1
        ) AS product_guardrail_policy_row_count_issue_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NOT NULL
              AND COALESCE(a.actual_product_policy_rows_for_product, 0) = 1
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
        ) AS product_guardrail_policy_value_mismatch_rows

    FROM expected_product_guardrail_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
),


/***************************************************************************************************
8. FINAL ACCEPTANCE FLAGS
***************************************************************************************************/

acceptance_inputs AS (
    SELECT
        x.expected_campaign_runs,
        x.expected_comparison_groups,
        x.expected_archive_slices,
        x.expected_archive_rows,
        x.expected_rows_per_archive_slice,
        x.expected_validation_rows_per_run,
        x.expected_product_guardrail_campaign_runs,
        x.expected_product_guardrail_policy_rows,

        cr.active_campaign_registry_rows,
        cgr.active_comparison_registry_rows,

        a.archived_strategy_scenario_slices,
        a.total_archived_rows,
        a.archive_slices_not_50000_rows,
        a.archive_slices_with_duplicate_application_ids,
        agd.duplicate_archive_grain_count,

        cmp.comparison_group_count,
        cmp.comparison_ready_count,
        cmp.comparison_review_count,

        src.source_consistency_group_count,
        src.source_consistency_pass_count,
        src.source_consistency_review_count,
        src.total_source_field_mismatch_rows,

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
        ev.segment_evidence_run_count,
        ev.segment_evidence_issue_run_count,
        ev.min_segment_rows_per_run,
        ev.max_segment_rows_per_run,
        ev.total_segment_evidence_rows,

        cv.critical_convention_violation_count,

        pga.product_guardrail_campaign_run_count,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,
        pga.actual_product_guardrail_policy_rows_checked,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_row_count_issue_rows,
        pga.product_guardrail_policy_value_mismatch_rows,

        (
            cr.active_campaign_registry_rows = x.expected_campaign_runs
        ) AS campaign_registry_ready_flag,

        (
            cgr.active_comparison_registry_rows = x.expected_comparison_groups
        ) AS comparison_registry_ready_flag,

        (
            a.archived_strategy_scenario_slices = x.expected_archive_slices
            AND a.total_archived_rows = x.expected_archive_rows
            AND a.archive_slices_not_50000_rows = 0
            AND a.archive_slices_with_duplicate_application_ids = 0
            AND agd.duplicate_archive_grain_count = 0
        ) AS archive_ready_flag,

        (
            cmp.comparison_group_count = x.expected_comparison_groups
            AND cmp.comparison_ready_count = x.expected_comparison_groups
            AND cmp.comparison_review_count = 0
        ) AS comparison_ready_flag,

        (
            src.source_consistency_group_count = x.expected_comparison_groups
            AND src.source_consistency_pass_count = x.expected_comparison_groups
            AND src.source_consistency_review_count = 0
            AND src.total_source_field_mismatch_rows = 0
        ) AS source_consistency_ready_flag,

        (
            ev.registry_run_count_for_evidence_check = x.expected_campaign_runs
            AND ev.executive_evidence_complete_run_count = x.expected_campaign_runs
            AND ev.executive_evidence_issue_run_count = 0
            AND ev.parameter_snapshot_complete_run_count = x.expected_campaign_runs
            AND ev.parameter_snapshot_issue_run_count = 0
            AND ev.validation_evidence_complete_run_count = x.expected_campaign_runs
            AND ev.validation_evidence_incomplete_run_count = 0
            AND ev.min_validation_rows_per_run = x.expected_validation_rows_per_run
            AND ev.max_validation_rows_per_run = x.expected_validation_rows_per_run
            AND ev.segment_evidence_run_count = x.expected_campaign_runs
            AND ev.segment_evidence_issue_run_count = 0
        ) AS evidence_ready_flag,

        (
            cv.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,

        (
            pga.product_guardrail_campaign_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_complete_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
            AND pga.actual_product_guardrail_policy_rows_checked = x.expected_product_guardrail_policy_rows
            AND pga.missing_product_guardrail_policy_rows = 0
            AND pga.product_guardrail_policy_row_count_issue_rows = 0
            AND pga.product_guardrail_policy_value_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag

    FROM expected_campaign_shape x
    CROSS JOIN campaign_registry_summary cr
    CROSS JOIN comparison_registry_summary cgr
    CROSS JOIN archive_summary a
    CROSS JOIN archive_grain_duplicates agd
    CROSS JOIN comparison_readiness_summary cmp
    CROSS JOIN source_consistency_summary src
    CROSS JOIN evidence_summary ev
    CROSS JOIN convention_summary cv
    CROSS JOIN product_guardrail_policy_audit pga
),

final_status AS (
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

        CONCAT_WS(
            ' | ',

            CASE WHEN campaign_registry_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_CAMPAIGN_REGISTRY' END,

            CASE WHEN comparison_registry_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_COMPARISON_REGISTRY' END,

            CASE WHEN archive_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_ARCHIVE_INVENTORY_OR_ARCHIVE_GRAIN' END,

            CASE WHEN comparison_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_COMPARISON_READINESS' END,

            CASE WHEN source_consistency_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_MATCHED_SOURCE_FIELD_CONSISTENCY' END,

            CASE WHEN evidence_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_SECTION_16_EVIDENCE_COMPLETENESS' END,

            CASE WHEN final_output_conventions_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_FINAL_OUTPUT_CONVENTIONS' END,

            CASE WHEN product_guardrail_policy_ready_flag IS DISTINCT FROM TRUE
                THEN 'REVIEW_PRODUCT_GUARDRAIL_POLICY_EXACT_VALUES' END
        ) AS acceptance_review_focus,

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
        END AS module2_campaign_acceptance_status

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
    Expected campaign shape.
    ***********************************************************************************************/
    expected_campaign_runs,
    expected_comparison_groups,
    expected_archive_slices,
    expected_archive_rows,
    expected_rows_per_archive_slice,
    expected_validation_rows_per_run,
    expected_product_guardrail_campaign_runs,
    expected_product_guardrail_policy_rows,


    /***********************************************************************************************
    Registry and archive evidence.
    ***********************************************************************************************/
    active_campaign_registry_rows,
    active_comparison_registry_rows,

    archived_strategy_scenario_slices,
    total_archived_rows,
    archive_slices_not_50000_rows,
    archive_slices_with_duplicate_application_ids,
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

    segment_evidence_run_count,
    segment_evidence_issue_run_count,
    min_segment_rows_per_run,
    max_segment_rows_per_run,
    total_segment_evidence_rows,


    /***********************************************************************************************
    Convention and product-guardrail policy audit evidence.
    ***********************************************************************************************/
    critical_convention_violation_count,

    product_guardrail_campaign_run_count,
    product_guardrail_parameter_snapshot_complete_run_count,
    product_guardrail_parameter_snapshot_issue_run_count,
    actual_product_guardrail_policy_rows_checked,
    missing_product_guardrail_policy_rows,
    product_guardrail_policy_row_count_issue_rows,
    product_guardrail_policy_value_mismatch_rows

FROM final_status;
```
<!-- END_MESSAGE C038-M01732 -->


---

<a id="c038-m01735"></a>

### C038-M01735

**ChatGPT** · 2026-05-13T00:10:46.714379-04:00 · alternate branch

<!-- BEGIN_MESSAGE C038-M01735 -->
Replace only the existing **`acceptance_inputs AS (...)`** block in Section 17.20 with the version below. Keep the trailing comma because `acceptance_status AS (...)` follows it in the `WITH` chain. This version is simpler because it first gathers raw acceptance metrics, then calculates the gate flags from those raw fields in one clear layer. Your current Section 17.20 is the final acceptance rollup, and this patch keeps that structure intact. fileciteturn274file1

```sql
/***************************************************************************************************
8. FINAL ACCEPTANCE INPUTS AND STATUS FLAGS
***************************************************************************************************/

acceptance_inputs AS (
    SELECT
        raw.*,

        /*******************************************************************************************
        Gate 1 — Campaign registry completeness.
        *******************************************************************************************/
        (
            raw.active_campaign_registry_rows = raw.expected_campaign_runs
        ) AS campaign_registry_ready_flag,


        /*******************************************************************************************
        Gate 2 — Comparison registry completeness.
        *******************************************************************************************/
        (
            raw.active_comparison_registry_rows = raw.expected_comparison_groups
        ) AS comparison_registry_ready_flag,


        /*******************************************************************************************
        Gate 3 — Archive inventory and archive grain completeness.
        *******************************************************************************************/
        (
            raw.archived_strategy_scenario_slices = raw.expected_archive_slices
            AND raw.total_archived_rows = raw.expected_archive_rows
            AND raw.archive_slices_not_50000_rows = 0
            AND raw.archive_slices_with_duplicate_application_ids = 0
            AND raw.duplicate_archive_grain_count = 0
        ) AS archive_ready_flag,


        /*******************************************************************************************
        Gate 4 — Matched comparison readiness.
        *******************************************************************************************/
        (
            raw.comparison_group_count = raw.expected_comparison_groups
            AND raw.comparison_ready_count = raw.expected_comparison_groups
            AND raw.comparison_review_count = 0
        ) AS comparison_ready_flag,


        /*******************************************************************************************
        Gate 5 — Matched source-field consistency.
        *******************************************************************************************/
        (
            raw.source_consistency_group_count = raw.expected_comparison_groups
            AND raw.source_consistency_pass_count = raw.expected_comparison_groups
            AND raw.source_consistency_review_count = 0
            AND raw.total_source_field_mismatch_rows = 0
        ) AS source_consistency_ready_flag,


        /*******************************************************************************************
        Gate 6 — Section 16 evidence completeness.

        Validation evidence is exact:
            18 validation evidence rows per active campaign run in the current Section 14 design.
        *******************************************************************************************/
        (
            raw.registry_run_count_for_evidence_check = raw.expected_campaign_runs

            AND raw.executive_evidence_complete_run_count = raw.expected_campaign_runs
            AND raw.executive_evidence_issue_run_count = 0

            AND raw.parameter_snapshot_complete_run_count = raw.expected_campaign_runs
            AND raw.parameter_snapshot_issue_run_count = 0

            AND raw.validation_evidence_complete_run_count = raw.expected_campaign_runs
            AND raw.validation_evidence_incomplete_run_count = 0
            AND raw.min_validation_rows_per_run = raw.expected_validation_rows_per_run
            AND raw.max_validation_rows_per_run = raw.expected_validation_rows_per_run
            AND raw.total_validation_evidence_rows =
                raw.expected_campaign_runs * raw.expected_validation_rows_per_run

            AND raw.segment_evidence_run_count = raw.expected_campaign_runs
            AND raw.segment_evidence_issue_run_count = 0
        ) AS evidence_ready_flag,


        /*******************************************************************************************
        Gate 7 — Full-archive final-output convention integrity.
        *******************************************************************************************/
        (
            raw.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,


        /*******************************************************************************************
        Gate 8 — Product-guardrail exact-value parameter snapshot audit.

        This is now registry-scoped:
            only active formal campaign PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs are audited.
        *******************************************************************************************/
        (
            raw.product_guardrail_campaign_run_count = raw.expected_product_guardrail_campaign_runs
            AND raw.product_guardrail_parameter_snapshot_complete_run_count =
                raw.expected_product_guardrail_campaign_runs
            AND raw.product_guardrail_parameter_snapshot_issue_run_count = 0
            AND raw.actual_product_guardrail_policy_rows_checked =
                raw.expected_product_guardrail_policy_rows
            AND raw.missing_product_guardrail_policy_rows = 0
            AND raw.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag

    FROM (
        SELECT
            /***************************************************************************************
            Expected campaign shape.
            ***************************************************************************************/
            x.expected_campaign_runs,
            x.expected_comparison_groups,
            x.expected_archive_slices,
            x.expected_archive_rows,
            x.expected_rows_per_archive_slice,
            x.expected_validation_rows_per_run,
            x.expected_product_guardrail_campaign_runs,
            x.expected_product_guardrail_policy_rows,


            /***************************************************************************************
            Registry and archive.
            ***************************************************************************************/
            COALESCE(rr.active_campaign_registry_rows, 0)
                AS active_campaign_registry_rows,

            COALESCE(cr.active_comparison_registry_rows, 0)
                AS active_comparison_registry_rows,

            COALESCE(a.archived_strategy_scenario_slices, 0)
                AS archived_strategy_scenario_slices,

            COALESCE(a.total_archived_rows, 0)
                AS total_archived_rows,

            COALESCE(a.archive_slices_not_50000_rows, 0)
                AS archive_slices_not_50000_rows,

            COALESCE(a.archive_slices_with_duplicate_application_ids, 0)
                AS archive_slices_with_duplicate_application_ids,

            COALESCE(agd.duplicate_archive_grain_count, 0)
                AS duplicate_archive_grain_count,


            /***************************************************************************************
            Comparison and source consistency.
            ***************************************************************************************/
            COALESCE(cmp.comparison_group_count, 0)
                AS comparison_group_count,

            COALESCE(cmp.comparison_ready_count, 0)
                AS comparison_ready_count,

            COALESCE(cmp.comparison_review_count, 0)
                AS comparison_review_count,

            COALESCE(src.source_consistency_group_count, 0)
                AS source_consistency_group_count,

            COALESCE(src.source_consistency_pass_count, 0)
                AS source_consistency_pass_count,

            COALESCE(src.source_consistency_review_count, 0)
                AS source_consistency_review_count,

            COALESCE(src.total_source_field_mismatch_rows, 0)
                AS total_source_field_mismatch_rows,


            /***************************************************************************************
            Section 16 evidence completeness.
            ***************************************************************************************/
            COALESCE(ev.registry_run_count_for_evidence_check, 0)
                AS registry_run_count_for_evidence_check,

            COALESCE(ev.executive_evidence_rows, 0)
                AS executive_evidence_rows,

            COALESCE(ev.executive_evidence_complete_run_count, 0)
                AS executive_evidence_complete_run_count,

            COALESCE(ev.executive_evidence_issue_run_count, 0)
                AS executive_evidence_issue_run_count,

            COALESCE(ev.parameter_snapshot_rows, 0)
                AS parameter_snapshot_rows,

            COALESCE(ev.parameter_snapshot_complete_run_count, 0)
                AS parameter_snapshot_complete_run_count,

            COALESCE(ev.parameter_snapshot_issue_run_count, 0)
                AS parameter_snapshot_issue_run_count,

            COALESCE(ev.validation_evidence_complete_run_count, 0)
                AS validation_evidence_complete_run_count,

            COALESCE(ev.validation_evidence_incomplete_run_count, 0)
                AS validation_evidence_incomplete_run_count,

            COALESCE(ev.min_validation_rows_per_run, 0)
                AS min_validation_rows_per_run,

            COALESCE(ev.max_validation_rows_per_run, 0)
                AS max_validation_rows_per_run,

            COALESCE(ev.total_validation_evidence_rows, 0)
                AS total_validation_evidence_rows,

            COALESCE(ev.segment_evidence_run_count, 0)
                AS segment_evidence_run_count,

            COALESCE(ev.segment_evidence_issue_run_count, 0)
                AS segment_evidence_issue_run_count,

            COALESCE(ev.min_segment_rows_per_run, 0)
                AS min_segment_rows_per_run,

            COALESCE(ev.max_segment_rows_per_run, 0)
                AS max_segment_rows_per_run,

            COALESCE(ev.total_segment_evidence_rows, 0)
                AS total_segment_evidence_rows,


            /***************************************************************************************
            Final-output conventions.
            ***************************************************************************************/
            COALESCE(cv.critical_convention_violation_count, 0)
                AS critical_convention_violation_count,


            /***************************************************************************************
            Product-guardrail exact-value parameter audit.
            ***************************************************************************************/
            COALESCE(pga.product_guardrail_campaign_run_count, 0)
                AS product_guardrail_campaign_run_count,

            COALESCE(pga.product_guardrail_parameter_snapshot_complete_run_count, 0)
                AS product_guardrail_parameter_snapshot_complete_run_count,

            COALESCE(pga.product_guardrail_parameter_snapshot_issue_run_count, 0)
                AS product_guardrail_parameter_snapshot_issue_run_count,

            COALESCE(pga.expected_product_guardrail_policy_rows, 0)
                AS actual_product_guardrail_policy_rows_checked,

            COALESCE(pga.missing_product_guardrail_policy_rows, 0)
                AS missing_product_guardrail_policy_rows,

            COALESCE(pga.product_guardrail_policy_mismatch_rows, 0)
                AS product_guardrail_policy_mismatch_rows

        FROM expected_campaign_shape x

        CROSS JOIN registry_summary rr
        CROSS JOIN comparison_registry_summary cr
        CROSS JOIN archive_summary a
        CROSS JOIN archive_grain_duplicates agd
        CROSS JOIN comparison_readiness cmp
        CROSS JOIN source_consistency src
        CROSS JOIN evidence_coverage ev
        CROSS JOIN convention_summary cv
        CROSS JOIN product_guardrail_policy_audit pga
    ) raw
),
```
<!-- END_MESSAGE C038-M01735 -->


---

<a id="c038-m01736"></a>

### C038-M01736

**Andrew** · 2026-05-13T00:39:38.108000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01736 -->
I didn't want the full section 20.  and in fact you did not get the expected_campaign_shape right in your last response vs what you previously provided: WITH expected_campaign_shape AS (
    SELECT
        36::BIGINT AS expected_campaign_runs,
        17::BIGINT AS expected_comparison_groups,
        36::BIGINT AS expected_archive_slices,
        1800000::BIGINT AS expected_archive_rows,
        50000::BIGINT AS expected_rows_per_archive_slice,
        18::BIGINT AS expected_validation_rows_per_run,

        /*******************************************************************************************
        Product-guardrail audit expectation.    I simply wanted you to provide the 17.20C update you recommended in a simpler copy paste format.  here is what you replied previously but it was a lot to put together:    17.20C — update acceptance_inputs

Inside acceptance_inputs AS (...), add these selected fields near the existing product-guardrail fields:

        x.expected_product_guardrail_campaign_runs,

Then replace the current product-guardrail audit fields with these:

        /*******************************************************************************************
        Product guardrail policy exact-value audit.
        *******************************************************************************************/
        pga.product_guardrail_campaign_run_count,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,

        pga.expected_product_guardrail_policy_rows AS actual_product_guardrail_policy_rows_checked,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_mismatch_rows,

Finally, replace the current product_guardrail_policy_ready_flag logic with this:

        (
            pga.product_guardrail_campaign_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_complete_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
            AND pga.expected_product_guardrail_policy_rows = x.expected_product_guardrail_policy_rows
            AND pga.missing_product_guardrail_policy_rows = 0
            AND pga.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag 
        Formal campaign has five PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs:

            M2-06
            M2-23
            M2-26
            M2-34
            M2-36

        Each run audits two products:

            UNSECURED_PERSONAL_LOAN
            REVOLVING_LINE

        Expected audit rows:
            5 × 2 = 10.
        *******************************************************************************************/
        5::BIGINT AS expected_product_guardrail_campaign_runs,
        10::BIGINT AS expected_product_guardrail_policy_rows
),
<!-- END_MESSAGE C038-M01736 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_86.md) · [Next](Part_88.md)
