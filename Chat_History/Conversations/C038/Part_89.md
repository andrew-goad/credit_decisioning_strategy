# Module 2 Decision Simulator Build

## Part 89

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_88.md) · [Next](Part_90.md)

<a id="c038-m01786"></a>

### C038-M01786

**ChatGPT** · 2026-05-13T07:57:20.842019-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01786 -->
Below replaces **Section 17.9 through Section 17.16** and stops before **Section 17.17**. I interpreted your “17.9–17.6” as **17.9–17.16** based on the three patch ranges you listed. The current attached Section 17 still includes the older fixed-shape expectations in places such as Section 17.14 / 17.15, while Sections 17.1–17.8 have now moved toward dynamic, registry-scoped acceptance; this patch aligns 17.9–17.16 to that same standard. fileciteturn290file0 fileciteturn290file9

```sql
/***************************************************************************************************
SECTION 17.9 — ACTIVE CAMPAIGN ARCHIVE FINAL OUTPUT CONVENTION CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Apply final-output convention checks across the archived rows belonging to active campaign
    registry runs.

    Section 17.9 answers:

        "Do the archived rows for the active campaign satisfy the locked final output conventions?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    The strategy archive may contain older development runs, ad hoc custom experiments, inactive
    campaign runs, or historical slices.

    Section 17 acceptance should evaluate the active campaign registry scope, not every historical
    archive row unless the user intentionally activates those runs in the campaign registry.

CONVENTIONS CHECKED:
    exactly one final decision flag per row;
    simulated_offer_exposure_flag reconciles to APPROVE / COUNTEROFFER;
    APPROVE preserves requested exposure, payment proxy, PTI, and requested Expected Loss;
    COUNTEROFFER has positive reduced exposure and satisfies target PTI / approved EL cap;
    MANUAL_REVIEW remains unresolved;
    DECLINE follows zero-exposure convention;
    simulated reason-code fields are complete;
    primary_reason_family aligns to decision_outcome.

EXPECTED RESULT:
    critical_convention_violation_count = 0
    active_campaign_archive_convention_status = ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY

READ-ONLY BOUNDARY:
    This section does not modify archive rows, latest-run rows, evidence rows, registry rows, or
    parameter rows.

***************************************************************************************************/

WITH active_campaign_runs AS (
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

convention_counts AS (
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
)

SELECT
    active_campaign_archived_rows,

    final_outcome_flag_count_violation_rows,
    simulated_offer_exposure_flag_violation_rows,

    approve_amount_violation_rows,
    counteroffer_amount_violation_rows,
    manual_review_amount_violation_rows,
    decline_amount_violation_rows,

    approve_payment_violation_rows,
    counteroffer_affordability_violation_rows,
    manual_review_affordability_violation_rows,
    decline_affordability_violation_rows,

    approve_expected_loss_violation_rows,
    counteroffer_expected_loss_violation_rows,
    manual_review_expected_loss_violation_rows,
    decline_expected_loss_violation_rows,

    reason_code_completeness_violation_rows,
    reason_family_alignment_violation_rows,

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
    ) AS critical_convention_violation_count,

    CASE
        WHEN active_campaign_archived_rows = 0
            THEN 'REVIEW_NO_ACTIVE_CAMPAIGN_ARCHIVE_ROWS'

        WHEN (
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
        ) = 0
            THEN 'ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY'

        ELSE 'REVIEW_ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS'
    END AS active_campaign_archive_convention_status

FROM convention_counts;



/***************************************************************************************************
SECTION 17.10 — VALIDATION STATUS SUMMARY BY ACTIVE CAMPAIGN RUN
****************************************************************************************************

BUSINESS PURPOSE:
    Summarize Section 16 validation evidence by active campaign registry run.

    Section 17.10 answers:

        "For each active campaign run, what validation evidence statuses were captured?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    Persistent validation evidence may contain old development or inactive run evidence.

    Section 17 evaluates active campaign registry runs.

DYNAMIC VALIDATION EVIDENCE DESIGN:
    expected_validation_key_count is derived from the distinct validation evidence keys present across
    active campaign registry runs:

        validation_area
        validation_test_name
        validation_category

EXPECTED RESULT:
    One row per active campaign registry run.

    Each row should generally show:
        validation_rows = expected_validation_key_count
        validation_distinct_key_count = expected_validation_key_count
        duplicate_validation_key_rows = 0

***************************************************************************************************/

WITH active_campaign_runs AS (
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

validation_by_run AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        COUNT(v.*) AS validation_rows,

        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS validation_distinct_key_count,

        COUNT(v.*) - COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS duplicate_validation_key_rows,

        COUNT(*) FILTER (WHERE v.validation_status = 'PASS')
            AS validation_pass_count,

        COUNT(*) FILTER (WHERE v.validation_status = 'REVIEW')
            AS validation_review_count,

        COUNT(*) FILTER (WHERE v.validation_status = 'NOT_APPLICABLE')
            AS validation_not_applicable_count,

        COUNT(*) FILTER (
            WHERE v.validation_status NOT IN ('PASS', 'REVIEW', 'NOT_APPLICABLE')
              AND v.validation_status IS NOT NULL
        ) AS validation_unexpected_status_count

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    GROUP BY
        r.module2_run_id,
        r.run_sequence_number
)

SELECT
    r.run_sequence_number,
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

    COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,

    COALESCE(v.validation_rows, 0) AS validation_rows,
    COALESCE(v.validation_distinct_key_count, 0) AS validation_distinct_key_count,

    COALESCE(v.validation_rows, 0)
        - COALESCE(vkc.expected_validation_key_count, 0)
        AS validation_evidence_row_gap,

    COALESCE(v.duplicate_validation_key_rows, 0) AS duplicate_validation_key_rows,

    COALESCE(v.validation_pass_count, 0) AS validation_pass_count,
    COALESCE(v.validation_review_count, 0) AS validation_review_count,
    COALESCE(v.validation_not_applicable_count, 0) AS validation_not_applicable_count,
    COALESCE(v.validation_unexpected_status_count, 0) AS validation_unexpected_status_count,

    CASE
        WHEN COALESCE(vkc.expected_validation_key_count, 0) = 0
            THEN 'REVIEW_VALIDATION_KEY_CATALOG_MISSING'

        WHEN COALESCE(v.validation_rows, 0) = COALESCE(vkc.expected_validation_key_count, 0)
         AND COALESCE(v.validation_distinct_key_count, 0) = COALESCE(vkc.expected_validation_key_count, 0)
         AND COALESCE(v.duplicate_validation_key_rows, 0) = 0
         AND COALESCE(v.validation_unexpected_status_count, 0) = 0
            THEN 'VALIDATION_EVIDENCE_COMPLETE'

        ELSE 'REVIEW_VALIDATION_EVIDENCE_COMPLETENESS'
    END AS validation_evidence_status

FROM active_campaign_runs r

CROSS JOIN validation_key_catalog vkc

LEFT JOIN validation_by_run v
    ON v.module2_run_id = r.module2_run_id

ORDER BY r.run_sequence_number;



/***************************************************************************************************
SECTION 17.11 — VALIDATION REVIEW / NOT_APPLICABLE CONCENTRATION
****************************************************************************************************

BUSINESS PURPOSE:
    Display validation evidence items from active campaign runs that require interpretation or
    context.

    Section 17.11 answers:

        "Which validation areas most often produced REVIEW or NOT_APPLICABLE status across the active
         campaign?"

INTERPRETATION:
    REVIEW does not automatically mean invalid.
    NOT_APPLICABLE does not automatically mean missing.

    Both should be reviewed before executive narrative, README, LinkedIn, or validation-summary
    claims are drafted.

EXPECTED RESULT:
    Zero rows is possible when all active campaign validation evidence is PASS.

***************************************************************************************************/

WITH active_campaign_runs AS (
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

active_validation_evidence AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        v.validation_area,
        v.validation_test_name,
        v.validation_category,
        v.validation_status,
        v.observed_value,
        v.expected_behavior,
        v.interpretation
    FROM active_campaign_runs r

    JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    WHERE v.validation_status IN ('REVIEW', 'NOT_APPLICABLE')
)

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,

    COUNT(*) AS validation_item_occurrence_count,
    COUNT(DISTINCT module2_run_id) AS impacted_campaign_run_count,

    MIN(run_sequence_number) AS first_impacted_run_sequence_number,
    MAX(run_sequence_number) AS last_impacted_run_sequence_number,

    STRING_AGG(DISTINCT module2_run_id, ', ')
        AS impacted_module2_run_ids,

    MIN(observed_value) AS sample_observed_value,
    MIN(expected_behavior) AS expected_behavior,
    MIN(interpretation) AS interpretation

FROM active_validation_evidence

GROUP BY
    validation_area,
    validation_test_name,
    validation_category,
    validation_status

ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        ELSE 99
    END,
    impacted_campaign_run_count DESC,
    validation_area,
    validation_test_name;



/***************************************************************************************************
SECTION 17.12 — ACTIVE COMPARISON REGISTRY READINESS
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm each active comparison registry group has baseline and challenger archive slices that are
    ready for matched comparison.

    Section 17.12 answers:

        "For each active comparison group, do the baseline and challenger slices exist, match the
         selected Module 1 source population size, and overlap completely by application_id?"

DYNAMIC ACCEPTANCE PRINCIPLE:
    Expected comparison row count is derived from the selected Module 1 source slice in:

        credit_decisioning_sim.synthetic_applications_scenario_archive

    It is not hardcoded to 50,000.

EXPECTED RESULT:
    One row per active comparison group.

    Each row should generally show:
        baseline_archived_rows = expected_module1_source_rows
        challenger_archived_rows = expected_module1_source_rows
        matched_application_id_count = expected_module1_source_rows
        baseline_only_application_id_count = 0
        challenger_only_application_id_count = 0
        readiness_status = READY_FOR_MATCHED_COMPARISON

***************************************************************************************************/

WITH active_comparisons AS (
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
        challenger_strategy_version
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
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

    s.expected_module1_source_rows,
    s.expected_module1_distinct_application_id_count,

    c.baseline_strategy_set_name,
    c.baseline_strategy_name,
    c.baseline_strategy_version,

    c.challenger_strategy_set_name,
    c.challenger_strategy_name,
    c.challenger_strategy_version,

    (
        c.baseline_strategy_set_name IS NOT DISTINCT FROM c.challenger_strategy_set_name
        AND c.baseline_strategy_name IS NOT DISTINCT FROM c.challenger_strategy_name
        AND c.baseline_strategy_version IS NOT DISTINCT FROM c.challenger_strategy_version
    ) AS same_strategy_selected_flag,

    COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
    COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

    COALESCE(b.distinct_application_id_count, 0) AS baseline_distinct_application_id_count,
    COALESCE(ch.distinct_application_id_count, 0) AS challenger_distinct_application_id_count,

    COALESCE(o.matched_application_id_count, 0) AS matched_application_id_count,
    COALESCE(o.baseline_only_application_id_count, 0) AS baseline_only_application_id_count,
    COALESCE(o.challenger_only_application_id_count, 0) AS challenger_only_application_id_count,

    CASE
        WHEN s.expected_module1_source_rows IS NULL
            THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN s.expected_module1_source_rows <> s.expected_module1_distinct_application_id_count
            THEN 'REVIEW_MODULE1_SOURCE_APPLICATION_ID_GRAIN'

        WHEN (
            c.baseline_strategy_set_name IS NOT DISTINCT FROM c.challenger_strategy_set_name
            AND c.baseline_strategy_name IS NOT DISTINCT FROM c.challenger_strategy_name
            AND c.baseline_strategy_version IS NOT DISTINCT FROM c.challenger_strategy_version
        )
            THEN 'REVIEW_SAME_STRATEGY_SELECTED'

        WHEN COALESCE(b.archived_rows, 0) = 0
          OR COALESCE(ch.archived_rows, 0) = 0
            THEN 'REVIEW_COMPARISON_ARCHIVE_MISSING_SLICE'

        WHEN COALESCE(b.archived_rows, 0) <> s.expected_module1_source_rows
          OR COALESCE(ch.archived_rows, 0) <> s.expected_module1_source_rows
            THEN 'REVIEW_COMPARISON_ARCHIVE_ROW_COUNT_MISMATCH'

        WHEN COALESCE(b.distinct_application_id_count, 0) <> s.expected_module1_source_rows
          OR COALESCE(ch.distinct_application_id_count, 0) <> s.expected_module1_source_rows
            THEN 'REVIEW_COMPARISON_ARCHIVE_APPLICATION_ID_GRAIN'

        WHEN COALESCE(o.matched_application_id_count, 0) <> s.expected_module1_source_rows
          OR COALESCE(o.baseline_only_application_id_count, 0) <> 0
          OR COALESCE(o.challenger_only_application_id_count, 0) <> 0
            THEN 'REVIEW_COMPARISON_APPLICATION_OVERLAP'

        ELSE 'READY_FOR_MATCHED_COMPARISON'
    END AS readiness_status

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

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.13 — ACTIVE COMPARISON MATCHED SOURCE-FIELD CONSISTENCY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm matched baseline and challenger rows share the same immutable Module 1 source fields.

    Section 17.13 answers:

        "Are baseline / challenger deltas interpretable as Module 2 strategy movement rather than
         Module 1 population drift?"

WHY THIS MATTERS:
    Matched strategy comparison should isolate downstream Module 2 strategy effects.

    If Module 1 source fields differ between baseline and challenger rows, the comparison may reflect:
        population drift,
        source-selection error,
        upstream scenario mismatch,
        archive corruption,
        or incomplete rerun replacement.

SOURCE FIELDS COMPARED:
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

EXPECTED RESULT:
    One row per active comparison group.

    source_consistency_status should generally equal:
        SOURCE_FIELDS_MATCH

***************************************************************************************************/

WITH active_comparisons AS (
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

module1_source_counts AS (
    SELECT
        scenario_set_name AS module1_scenario_set_name,
        scenario_name AS module1_scenario_name,
        population_id,

        COUNT(*) AS expected_module1_source_rows
    FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    GROUP BY
        scenario_set_name,
        scenario_name,
        population_id
),

matched_rows AS (
    SELECT
        c.comparison_group_id,
        c.comparison_set_name,

        c.baseline_module2_run_id,
        c.challenger_module2_run_id,

        s.expected_module1_source_rows,

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

    LEFT JOIN module1_source_counts s
        ON s.module1_scenario_set_name = c.module1_scenario_set_name
       AND s.module1_scenario_name = c.module1_scenario_name
       AND s.population_id = c.population_id

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
        comparison_set_name,

        baseline_module2_run_id,
        challenger_module2_run_id,

        MAX(expected_module1_source_rows) AS expected_module1_source_rows,

        COUNT(*) AS matched_application_count,

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
        ) AS amount_to_income_mismatch_count,

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

    FROM matched_rows

    GROUP BY
        comparison_group_id,
        comparison_set_name,
        baseline_module2_run_id,
        challenger_module2_run_id
)

SELECT
    c.comparison_group_id,
    c.comparison_set_name,

    c.baseline_module2_run_id,
    c.challenger_module2_run_id,

    c.module1_scenario_set_name,
    c.module1_scenario_name,
    c.population_id,

    COALESCE(s.expected_module1_source_rows, 0) AS expected_module1_source_rows,
    COALESCE(r.matched_application_count, 0) AS matched_application_count,

    COALESCE(r.product_type_mismatch_count, 0) AS product_type_mismatch_count,
    COALESCE(r.score_band_mismatch_count, 0) AS score_band_mismatch_count,
    COALESCE(r.credit_score_mismatch_count, 0) AS credit_score_mismatch_count,
    COALESCE(r.annual_income_mismatch_count, 0) AS annual_income_mismatch_count,
    COALESCE(r.requested_amount_mismatch_count, 0) AS requested_amount_mismatch_count,
    COALESCE(r.requested_payment_mismatch_count, 0) AS requested_payment_mismatch_count,
    COALESCE(r.requested_pti_mismatch_count, 0) AS requested_pti_mismatch_count,
    COALESCE(r.amount_to_income_mismatch_count, 0) AS amount_to_income_mismatch_count,
    COALESCE(r.estimated_pd_mismatch_count, 0) AS estimated_pd_mismatch_count,
    COALESCE(r.estimated_lgd_mismatch_count, 0) AS estimated_lgd_mismatch_count,
    COALESCE(r.requested_expected_loss_mismatch_count, 0) AS requested_expected_loss_mismatch_count,
    COALESCE(r.module1_lineage_mismatch_count, 0) AS module1_lineage_mismatch_count,

    (
        COALESCE(r.product_type_mismatch_count, 0)
        + COALESCE(r.score_band_mismatch_count, 0)
        + COALESCE(r.credit_score_mismatch_count, 0)
        + COALESCE(r.annual_income_mismatch_count, 0)
        + COALESCE(r.requested_amount_mismatch_count, 0)
        + COALESCE(r.requested_payment_mismatch_count, 0)
        + COALESCE(r.requested_pti_mismatch_count, 0)
        + COALESCE(r.amount_to_income_mismatch_count, 0)
        + COALESCE(r.estimated_pd_mismatch_count, 0)
        + COALESCE(r.estimated_lgd_mismatch_count, 0)
        + COALESCE(r.requested_expected_loss_mismatch_count, 0)
        + COALESCE(r.module1_lineage_mismatch_count, 0)
    ) AS source_field_mismatch_count,

    CASE
        WHEN COALESCE(s.expected_module1_source_rows, 0) = 0
            THEN 'NOT_APPLICABLE_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN COALESCE(r.matched_application_count, 0) <> COALESCE(s.expected_module1_source_rows, 0)
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN (
            COALESCE(r.product_type_mismatch_count, 0)
            + COALESCE(r.score_band_mismatch_count, 0)
            + COALESCE(r.credit_score_mismatch_count, 0)
            + COALESCE(r.annual_income_mismatch_count, 0)
            + COALESCE(r.requested_amount_mismatch_count, 0)
            + COALESCE(r.requested_payment_mismatch_count, 0)
            + COALESCE(r.requested_pti_mismatch_count, 0)
            + COALESCE(r.amount_to_income_mismatch_count, 0)
            + COALESCE(r.estimated_pd_mismatch_count, 0)
            + COALESCE(r.estimated_lgd_mismatch_count, 0)
            + COALESCE(r.requested_expected_loss_mismatch_count, 0)
            + COALESCE(r.module1_lineage_mismatch_count, 0)
        ) = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status

FROM active_comparisons c

LEFT JOIN module1_source_counts s
    ON s.module1_scenario_set_name = c.module1_scenario_set_name
   AND s.module1_scenario_name = c.module1_scenario_name
   AND s.population_id = c.population_id

LEFT JOIN source_consistency_by_group r
    ON r.comparison_group_id = c.comparison_group_id

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.14 — EXECUTIVE EVIDENCE CAMPAIGN SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Display the one-row executive evidence summary for each active campaign registry run.

    Section 17.14 answers:

        "What is the run-level executive evidence story for each active campaign run?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    Persistent executive evidence may contain historical or ad hoc evidence rows.

    Section 17 should display the active campaign registry scope.

DYNAMIC ACCEPTANCE PRINCIPLE:
    applications is compared to the selected Module 1 source population row count derived from:

        credit_decisioning_sim.synthetic_applications_scenario_archive

    It is not assumed to be 50,000.

EXPECTED RESULT:
    One row per active campaign registry run.

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

module1_source_counts AS (
    SELECT
        scenario_set_name AS module1_scenario_set_name,
        scenario_name AS module1_scenario_name,
        population_id,

        COUNT(*) AS expected_module1_source_rows
    FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    GROUP BY
        scenario_set_name,
        scenario_name,
        population_id
),

executive_evidence_ranked AS (
    SELECT
        e.*,

        COUNT(*) OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        ) AS executive_evidence_rows_for_run,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY evidence_snapshot_ts DESC NULLS LAST
        ) AS executive_evidence_row_rank
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
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

    s.expected_module1_source_rows,

    COALESCE(e.executive_evidence_rows_for_run, 0) AS executive_evidence_rows_for_run,

    e.applications,
    e.applications - s.expected_module1_source_rows AS applications_minus_expected_source_rows,

    e.approval_rate,
    e.counteroffer_rate,
    e.manual_review_rate,
    e.decline_rate,
    e.simulated_offer_exposure_rate,

    e.total_requested_amount,
    e.total_approved_amount,
    e.approved_amount_capture_rate,

    e.total_requested_expected_loss_amount,
    e.total_approved_expected_loss_amount,
    e.approved_expected_loss_rate,
    e.approved_amount_per_approved_expected_loss_dollar,

    e.avg_synthetic_estimated_pd_proxy_offer_rows,
    e.avg_approved_payment_to_income_ratio_offer_rows,

    e.frontier_position_type,
    e.executive_frontier_quadrant,
    e.frontier_interpretation_note,

    e.top_primary_reason_code,
    e.top_non_approval_primary_reason_code,
    e.top_policy_stop_primary_reason_code,
    e.top_reason_code_delta_driver_code,

    e.top_approved_amount_product,
    e.top_approved_expected_loss_product,
    e.top_approved_amount_score_band,
    e.top_approved_expected_loss_score_band,
    e.top_approved_el_product_score_segment,

    e.validation_pass_count,
    e.validation_review_count,
    e.validation_not_applicable_count,

    e.module3_growth_inputs_available_flag,
    e.module3_growth_input_gap_note,

    CASE
        WHEN s.expected_module1_source_rows IS NULL
            THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN COALESCE(e.executive_evidence_rows_for_run, 0) = 0
            THEN 'REVIEW_EXECUTIVE_EVIDENCE_ROW_MISSING'

        WHEN COALESCE(e.executive_evidence_rows_for_run, 0) <> 1
            THEN 'REVIEW_DUPLICATE_EXECUTIVE_EVIDENCE_ROWS'

        WHEN e.applications IS DISTINCT FROM s.expected_module1_source_rows
            THEN 'REVIEW_EXECUTIVE_EVIDENCE_APPLICATION_COUNT_MISMATCH'

        WHEN e.frontier_position_type IS NULL
          OR e.executive_frontier_quadrant IS NULL
            THEN 'REVIEW_FRONTIER_FIELDS_NOT_SYNCHRONIZED'

        ELSE 'EXECUTIVE_EVIDENCE_READY'
    END AS executive_evidence_status

FROM active_campaign_runs r

LEFT JOIN module1_source_counts s
    ON s.module1_scenario_set_name = r.module1_scenario_set_name
   AND s.module1_scenario_name = r.module1_scenario_name
   AND s.population_id = r.population_id

LEFT JOIN executive_evidence_ranked e
    ON e.strategy_set_name = r.strategy_set_name
   AND e.strategy_name = r.strategy_name
   AND e.strategy_version = r.strategy_version
   AND e.module1_scenario_set_name = r.module1_scenario_set_name
   AND e.module1_scenario_name = r.module1_scenario_name
   AND e.population_id = r.population_id
   AND e.executive_evidence_row_rank = 1

ORDER BY r.run_sequence_number;



/***************************************************************************************************
SECTION 17.15 — BASELINE × CHALLENGER DELTA SUMMARY FOR ACTIVE COMPARISON GROUPS
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the main comparison-level strategy-effect table across all active comparison groups.

    Section 17.15 answers:

        "How did each challenger strategy change access, approvals, counteroffers, manual review,
         declines, approved exposure, approved Expected Loss, approved Expected Loss rate,
         offered-population synthetic-risk profile, and approved PTI?"

WHY THIS SECTION IS DYNAMIC:
    It returns one row per active comparison registry group.

    It does not assume a fixed comparison-group count.

READINESS CONTEXT:
    comparison_readiness_status and source_consistency_status are included so deltas are interpreted
    only when matched comparison and source-field checks are clean.

***************************************************************************************************/

WITH active_comparisons AS (
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
),

module1_source_counts AS (
    SELECT
        scenario_set_name AS module1_scenario_set_name,
        scenario_name AS module1_scenario_name,
        population_id,

        COUNT(*) AS expected_module1_source_rows
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

        COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
        COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

        COALESCE(b.distinct_application_id_count, 0)
            AS baseline_distinct_application_id_count,

        COALESCE(ch.distinct_application_id_count, 0)
            AS challenger_distinct_application_id_count,

        COALESCE(o.matched_application_id_count, 0) AS matched_application_id_count,
        COALESCE(o.baseline_only_application_id_count, 0) AS baseline_only_application_id_count,
        COALESCE(o.challenger_only_application_id_count, 0) AS challenger_only_application_id_count,

        CASE
            WHEN s.expected_module1_source_rows IS NULL
                THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

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

    LEFT JOIN comparison_overlap o
        ON o.comparison_group_id = c.comparison_group_id
),

matched_rows AS (
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
        ch.requested_expected_loss_amount AS challenger_requested_expected_loss_amount

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

source_consistency AS (
    SELECT
        comparison_group_id,

        COUNT(*) AS matched_source_rows,

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
        ) AS source_field_mismatch_count
    FROM matched_rows
    GROUP BY comparison_group_id
),

executive_evidence_ranked AS (
    SELECT
        e.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY evidence_snapshot_ts DESC NULLS LAST
        ) AS evidence_row_rank
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
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

    c.baseline_strategy_name,
    c.challenger_strategy_name,

    cr.expected_module1_source_rows,
    cr.matched_application_id_count,
    cr.baseline_only_application_id_count,
    cr.challenger_only_application_id_count,
    cr.comparison_readiness_status,

    COALESCE(sc.source_field_mismatch_count, 0) AS source_field_mismatch_count,

    CASE
        WHEN cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN COALESCE(sc.source_field_mismatch_count, 0) = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status,

    c.expected_comparison_storyline,
    c.primary_metric_focus,

    b.approval_rate AS baseline_approval_rate,
    ch.approval_rate AS challenger_approval_rate,
    ch.approval_rate - b.approval_rate AS delta_approval_rate,

    b.counteroffer_rate AS baseline_counteroffer_rate,
    ch.counteroffer_rate AS challenger_counteroffer_rate,
    ch.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

    b.manual_review_rate AS baseline_manual_review_rate,
    ch.manual_review_rate AS challenger_manual_review_rate,
    ch.manual_review_rate - b.manual_review_rate AS delta_manual_review_rate,

    b.decline_rate AS baseline_decline_rate,
    ch.decline_rate AS challenger_decline_rate,
    ch.decline_rate - b.decline_rate AS delta_decline_rate,

    b.simulated_offer_exposure_rate AS baseline_simulated_offer_exposure_rate,
    ch.simulated_offer_exposure_rate AS challenger_simulated_offer_exposure_rate,
    ch.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
        AS delta_simulated_offer_exposure_rate,

    b.total_approved_amount AS baseline_total_approved_amount,
    ch.total_approved_amount AS challenger_total_approved_amount,
    ch.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    ch.approved_expected_loss_rate AS challenger_approved_expected_loss_rate,
    ch.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    b.avg_synthetic_estimated_pd_proxy_offer_rows AS baseline_avg_pd_proxy_offer_rows,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows AS challenger_avg_pd_proxy_offer_rows,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows
        - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_avg_pd_proxy_offer_rows,

    b.avg_approved_payment_to_income_ratio_offer_rows AS baseline_avg_approved_pti_offer_rows,
    ch.avg_approved_payment_to_income_ratio_offer_rows AS challenger_avg_approved_pti_offer_rows,
    ch.avg_approved_payment_to_income_ratio_offer_rows
        - b.avg_approved_payment_to_income_ratio_offer_rows
        AS delta_avg_approved_pti_offer_rows,

    b.frontier_position_type AS baseline_frontier_position_type,
    ch.frontier_position_type AS challenger_frontier_position_type,

    b.executive_frontier_quadrant AS baseline_executive_frontier_quadrant,
    ch.executive_frontier_quadrant AS challenger_executive_frontier_quadrant,

    ch.frontier_interpretation_note AS challenger_frontier_interpretation_note,

    ch.top_reason_code_delta_driver_code AS challenger_top_reason_code_delta_driver_code

FROM active_comparisons c

LEFT JOIN comparison_readiness cr
    ON cr.comparison_group_id = c.comparison_group_id

LEFT JOIN source_consistency sc
    ON sc.comparison_group_id = c.comparison_group_id

LEFT JOIN executive_evidence_ranked b
    ON b.strategy_set_name = c.baseline_strategy_set_name
   AND b.strategy_name = c.baseline_strategy_name
   AND b.strategy_version = c.baseline_strategy_version
   AND b.module1_scenario_set_name = c.module1_scenario_set_name
   AND b.module1_scenario_name = c.module1_scenario_name
   AND b.population_id = c.population_id
   AND b.evidence_row_rank = 1

LEFT JOIN executive_evidence_ranked ch
    ON ch.strategy_set_name = c.challenger_strategy_set_name
   AND ch.strategy_name = c.challenger_strategy_name
   AND ch.strategy_version = c.challenger_strategy_version
   AND ch.module1_scenario_set_name = c.module1_scenario_set_name
   AND ch.module1_scenario_name = c.module1_scenario_name
   AND ch.population_id = c.population_id
   AND ch.evidence_row_rank = 1

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.16 — PRODUCT GUARDRAIL STRATEGY EFFECT CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Review the product-level strategy effect for active comparison groups where the challenger is:

        PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY

    Section 17.16 answers:

        "Did product-specific guardrail challengers change product-level approval, offer exposure,
         approved amount, approved Expected Loss, and decline / counteroffer behavior in an
         interpretable way?"

WHY THIS SECTION IS DYNAMIC:
    The number of product-guardrail comparisons is derived from the active comparison registry.

    It is not hardcoded to five runs.

INTERPRETATION:
    UNSECURED_PERSONAL_LOAN and REVOLVING_LINE are the primary audited product guardrail targets.

    Other products are displayed as monitoring rows so unintended spillover can be reviewed.

READ-ONLY BOUNDARY:
    This section does not modify archive, evidence, registry, strategy-parameter, or product-policy
    rows.

***************************************************************************************************/

WITH product_guardrail_comparisons AS (
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
        challenger_strategy_version
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
      AND challenger_strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),

module1_source_counts AS (
    SELECT
        scenario_set_name AS module1_scenario_set_name,
        scenario_name AS module1_scenario_name,
        population_id,

        COUNT(*) AS expected_module1_source_rows
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
    FROM product_guardrail_comparisons c

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
    FROM product_guardrail_comparisons c

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

        COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
        COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

        COALESCE(o.matched_application_id_count, 0) AS matched_application_id_count,
        COALESCE(o.baseline_only_application_id_count, 0) AS baseline_only_application_id_count,
        COALESCE(o.challenger_only_application_id_count, 0) AS challenger_only_application_id_count,

        CASE
            WHEN s.expected_module1_source_rows IS NULL
                THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

            WHEN COALESCE(b.archived_rows, 0) <> s.expected_module1_source_rows
              OR COALESCE(ch.archived_rows, 0) <> s.expected_module1_source_rows
                THEN 'REVIEW_COMPARISON_ARCHIVE_ROW_COUNT_MISMATCH'

            WHEN COALESCE(o.matched_application_id_count, 0) <> s.expected_module1_source_rows
              OR COALESCE(o.baseline_only_application_id_count, 0) <> 0
              OR COALESCE(o.challenger_only_application_id_count, 0) <> 0
                THEN 'REVIEW_COMPARISON_APPLICATION_OVERLAP'

            ELSE 'READY_FOR_MATCHED_COMPARISON'
        END AS comparison_readiness_status

    FROM product_guardrail_comparisons c

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

product_metrics AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        product_type_policy_key,

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

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        AVG(requested_amount) AS avg_requested_amount,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows

    FROM credit_decisioning_sim.strategy_decisions_archive

    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        product_type_policy_key
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
    cr.matched_application_id_count,
    cr.comparison_readiness_status,

    COALESCE(b.product_type_policy_key, ch.product_type_policy_key) AS product_type_policy_key,

    CASE
        WHEN COALESCE(b.product_type_policy_key, ch.product_type_policy_key)
             IN ('UNSECURED_PERSONAL_LOAN', 'REVOLVING_LINE')
            THEN 'TARGET_PRODUCT_GUARDRAIL_PRODUCT'
        ELSE 'NON_TARGET_PRODUCT_MONITORING_ROW'
    END AS product_guardrail_audit_product_type,

    b.applications AS baseline_applications,
    ch.applications AS challenger_applications,

    b.approval_rate AS baseline_approval_rate,
    ch.approval_rate AS challenger_approval_rate,
    ch.approval_rate - b.approval_rate AS delta_approval_rate,

    b.counteroffer_rate AS baseline_counteroffer_rate,
    ch.counteroffer_rate AS challenger_counteroffer_rate,
    ch.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

    b.manual_review_rate AS baseline_manual_review_rate,
    ch.manual_review_rate AS challenger_manual_review_rate,
    ch.manual_review_rate - b.manual_review_rate AS delta_manual_review_rate,

    b.decline_rate AS baseline_decline_rate,
    ch.decline_rate AS challenger_decline_rate,
    ch.decline_rate - b.decline_rate AS delta_decline_rate,

    b.simulated_offer_exposure_rate AS baseline_simulated_offer_exposure_rate,
    ch.simulated_offer_exposure_rate AS challenger_simulated_offer_exposure_rate,
    ch.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
        AS delta_simulated_offer_exposure_rate,

    b.total_approved_amount AS baseline_total_approved_amount,
    ch.total_approved_amount AS challenger_total_approved_amount,
    ch.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    ch.approved_expected_loss_rate AS challenger_approved_expected_loss_rate,
    ch.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    b.avg_approved_amount_offer_rows AS baseline_avg_approved_amount_offer_rows,
    ch.avg_approved_amount_offer_rows AS challenger_avg_approved_amount_offer_rows,
    ch.avg_approved_amount_offer_rows - b.avg_approved_amount_offer_rows
        AS delta_avg_approved_amount_offer_rows,

    b.avg_approved_expected_loss_offer_rows AS baseline_avg_approved_expected_loss_offer_rows,
    ch.avg_approved_expected_loss_offer_rows AS challenger_avg_approved_expected_loss_offer_rows,
    ch.avg_approved_expected_loss_offer_rows - b.avg_approved_expected_loss_offer_rows
        AS delta_avg_approved_expected_loss_offer_rows,

    b.avg_synthetic_estimated_pd_proxy_offer_rows AS baseline_avg_pd_proxy_offer_rows,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows AS challenger_avg_pd_proxy_offer_rows,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows
        - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_avg_pd_proxy_offer_rows,

    CASE
        WHEN cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN COALESCE(b.product_type_policy_key, ch.product_type_policy_key)
             IN ('UNSECURED_PERSONAL_LOAN', 'REVOLVING_LINE')
         AND ch.total_approved_amount <= b.total_approved_amount
         AND ch.total_approved_expected_loss_amount <= b.total_approved_expected_loss_amount
            THEN 'TARGET_PRODUCT_GUARDRAIL_EFFECT_VISIBLE'

        WHEN COALESCE(b.product_type_policy_key, ch.product_type_policy_key)
             IN ('UNSECURED_PERSONAL_LOAN', 'REVOLVING_LINE')
            THEN 'REVIEW_TARGET_PRODUCT_GUARDRAIL_EFFECT'

        ELSE 'NON_TARGET_PRODUCT_MONITORING_ROW'
    END AS product_guardrail_strategy_effect_status

FROM product_guardrail_comparisons c

LEFT JOIN comparison_readiness cr
    ON cr.comparison_group_id = c.comparison_group_id

LEFT JOIN product_metrics b
    ON b.strategy_set_name = c.baseline_strategy_set_name
   AND b.strategy_name = c.baseline_strategy_name
   AND b.strategy_version = c.baseline_strategy_version
   AND b.module1_scenario_set_name = c.module1_scenario_set_name
   AND b.module1_scenario_name = c.module1_scenario_name
   AND b.population_id = c.population_id

LEFT JOIN product_metrics ch
    ON ch.strategy_set_name = c.challenger_strategy_set_name
   AND ch.strategy_name = c.challenger_strategy_name
   AND ch.strategy_version = c.challenger_strategy_version
   AND ch.module1_scenario_set_name = c.module1_scenario_set_name
   AND ch.module1_scenario_name = c.module1_scenario_name
   AND ch.population_id = c.population_id
   AND ch.product_type_policy_key = b.product_type_policy_key

ORDER BY
    c.comparison_group_id,
    CASE COALESCE(b.product_type_policy_key, ch.product_type_policy_key)
        WHEN 'UNSECURED_PERSONAL_LOAN' THEN 1
        WHEN 'REVOLVING_LINE' THEN 2
        WHEN 'MORTGAGE' THEN 3
        WHEN 'HELOC' THEN 4
        WHEN 'AUTO_LOAN' THEN 5
        ELSE 99
    END;
```

This aligns **17.9–17.16** with the new dynamic pattern established in **17.1–17.8**: active-registry scope, Module 1 source-count derivation, no fixed 50,000-row assumption, no fixed 17-comparison assumption, and no fixed 36-run assumption.
<!-- END_MESSAGE C038-M01786 -->


---

<a id="c038-m01787"></a>

### C038-M01787

**Andrew** · 2026-05-13T08:17:04.205000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01787 -->
thanks. proceed with reviewing sections 17.17 through 17.20 (current code attached) to see if they need updated regarding the hardcoded acceptance logic and the changes we just made thru 17.16.
<!-- END_MESSAGE C038-M01787 -->


**Attachments in export:** `Pasted text(179).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01793"></a>

### C038-M01793

**ChatGPT** · 2026-05-13T08:20:53.132337-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01793 -->
According to a document from 2026-05-13, **yes — Sections 17.17 through 17.20 still need updates** to align with the dynamic, active-campaign-registry-scoped approach we just applied through 17.16. The largest required update is **17.20**. Sections **17.17–17.19** need lighter but still important alignment. fileciteturn293file9

## Summary

| Section | Needs update? | Severity | Why |
|---|---:|---:|---|
| **17.17 Counteroffer-first strategy effect check** | Yes | Moderate | Should be driven by active comparison registry, not broad archive pairing by strategy name. |
| **17.18 Parameter snapshot profile audit** | Yes | Moderate | Current query reads directly from parameter snapshot table and still says “expected 36 rows.” It should start from active campaign registry. |
| **17.19 Product guardrail policy exact-value audit** | Minor | Low-to-moderate | Already partly registry-scoped, but comments still hardcode 5 / 10. Expected audit count should be dynamic. |
| **17.20 Final campaign acceptance rollup** | Yes | High | Still hardcodes 36, 17, 1,800,000, 50,000, 18, 5, and 10. This must be redesigned dynamically. |

## Section 17.17 — Counteroffer-first strategy effect check

This section should be updated.

The current logic is useful, but it is still shaped like a standalone campaign query. It uses `registry_map` from the active campaign registry and then calculates metrics for `BASELINE_STRATEGY` and `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` from the archive. The output tests whether counteroffer rate, exposure reduction, approved PTI, and approved EL moved in the expected direction. fileciteturn292file7

The issue is not a direct hardcoded `50,000` or `36`. The issue is **scope and pairing**.

Now that 17.12–17.16 are active-comparison-registry-driven, 17.17 should also start from:

```sql
credit_decisioning_sim.strategy_comparison_campaign_registry
```

where:

```sql
challenger_strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
```

Then it should compare only the baseline and challenger slices defined by active comparison registry rows. That makes it consistent with 17.15 and 17.16.

Recommended update:

```text
17.17 should become:
    active counteroffer-first comparison groups
    → derive expected Module 1 source rows
    → confirm comparison readiness
    → calculate baseline and challenger counteroffer metrics
    → output deltas and strategy-effect status
```

It should not broadly infer pairs only from `strategy_name`.

## Section 17.18 — Parameter snapshot profile audit

This section should be updated.

The current section says the expected result is **36 rows** and queries directly from:

```sql
credit_decisioning_sim.strategy_run_parameter_snapshot
```

without starting from the active campaign registry. fileciteturn293file9

That is inconsistent with the dynamic Section 17 standard. If old ad hoc parameter snapshots exist, they can appear in 17.18 even though they are not part of the active campaign. Also, the “36 rows” expectation is now too rigid.

Recommended update:

```text
17.18 should start from active campaign registry runs,
then left join parameter snapshots by technical run key.
```

It should report:

```sql
parameter_snapshot_rows_for_run
strategy_params_captured_flag
product_policy_params_captured_flag
run_story_params_captured_flag
captured source lineage fields
parameter_snapshot_status
```

Expected result should become:

```text
one row per active campaign registry run
```

not:

```text
36 rows
```

The status logic should distinguish:

```text
PARAMETER_SNAPSHOT_READY
PARAMETER_SNAPSHOT_MISSING
DUPLICATE_PARAMETER_SNAPSHOT_REVIEW_REQUIRED
PARAMETER_PAYLOAD_REVIEW_REQUIRED
PARAMETER_SOURCE_LINEAGE_REVIEW_REQUIRED
```

## Section 17.19 — Product guardrail policy exact-value audit

This section is mostly on the right track, but still needs cleanup.

The current version now starts from active formal campaign registry rows and then joins to parameter snapshots, which is exactly the right direction. It explicitly says this prevents old ad hoc or custom `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` evidence rows from inflating the audit count. fileciteturn293file12

The remaining issue is the expected-result language. It still says:

```text
10 rows:
    5 formal product-guardrail campaign runs × 2 audited products
```

That is correct for our campaign, but not flexible.

Recommended update:

```text
Expected rows =
    active PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY campaign runs
    × audited product count
```

The audited product count can remain fixed at 2 because the exact-value audit is intentionally focused on:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

The exact canonical values can also remain fixed because that is the purpose of this audit: confirming that the product-guardrail strategy captured the intended UPL and revolving-line product-policy values.

So: **keep the exact product-policy values, but make the expected row count dynamic.**

## Section 17.20 — Final campaign acceptance rollup

This section definitely needs a full dynamic redesign.

The current 17.20 still hardcodes the old campaign shape:

```sql
36::BIGINT AS expected_campaign_runs,
17::BIGINT AS expected_comparison_groups,
36::BIGINT AS expected_archive_slices,
1800000::BIGINT AS expected_archive_rows,
50000::BIGINT AS expected_rows_per_archive_slice,
18::BIGINT AS expected_validation_rows_per_run,
5::BIGINT AS expected_product_guardrail_campaign_runs,
10::BIGINT AS expected_product_guardrail_policy_rows
```

It also still checks archive slices against `50000`. fileciteturn293file14

That directly conflicts with the dynamic acceptance design we just applied in 17.1–17.16.

17.20 should now derive:

```text
expected_campaign_runs
    = count of active campaign registry rows

expected_comparison_groups
    = count of active comparison registry rows

expected archive rows per run
    = selected Module 1 source population count for that run

expected total archive rows
    = sum of expected Module 1 source rows across active campaign runs

expected validation key count
    = distinct validation_area + validation_test_name + validation_category across active campaign evidence

expected product guardrail campaign runs
    = count of active campaign registry rows where strategy_name = PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY

expected product guardrail policy rows
    = expected product guardrail campaign runs × audited product count
```

It should no longer hardcode:

```text
36
17
1,800,000
50,000
18
5
10
```

The only fixed values that should remain are the **canonical product-guardrail policy values** and the two audited product types.

## Recommended patch sequence

I recommend one more Section 17 pass in this order:

```text
Patch D: 17.17–17.18
    Counteroffer-first comparison effect check.
    Parameter snapshot profile audit.

Patch E: 17.19
    Dynamic product-guardrail audit count cleanup while preserving exact canonical values.

Patch F: 17.20
    Full dynamic final campaign acceptance rollup.
```

The 17.20 patch should come last because it should consume the same assumptions used in 17.1–17.19.

## Bottom line

Sections **17.17–17.19** need targeted alignment.

Section **17.20** needs a full dynamic replacement.

After that, Section 17 will be consistent end to end: active registry scoped, Module 1 source-count driven, validation-spine dynamic, comparison-registry driven, and no longer locked to the original 36 × 50,000 campaign shape.
<!-- END_MESSAGE C038-M01793 -->


---

<a id="c038-m01794"></a>

### C038-M01794

**Andrew** · 2026-05-13T08:24:55.015000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01794 -->
Thanks.  Please proceed with: Patch D: 17.17–17.18
    Counteroffer-first comparison effect check.
    Parameter snapshot profile audit.

Patch E: 17.19
    Dynamic product-guardrail audit count cleanup while preserving exact canonical values.

Patch F: 17.20
    Full dynamic final campaign acceptance rollup.     Please provide back one 17.17-17.20 full copy paste.
<!-- END_MESSAGE C038-M01794 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_88.md) · [Next](Part_90.md)
