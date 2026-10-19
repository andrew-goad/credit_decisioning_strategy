# Module 1 Synthetic Application Portfolio Build

## Part 26

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_25.md) · [Next](Part_27.md)

<a id="c034-m01207"></a>

### C034-M01207

**ChatGPT** · 2026-05-16T22:29:35.703578-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01207 -->
According to a document from **2026-05-17**, Section 17.16–17.20 are structurally sound, but the closing campaign acceptance layer still needs to fully absorb Option C. The current Section 17 map still refers to `17.17 Counteroffer-first strategy effect check`, and the current 17.17 title has been partly updated to Option C while the body still filters for `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY`. fileciteturn305file15 fileciteturn305file2

No new section is required. The cleanest implementation is:

```text
17.16 keep product guardrail effect check, with no major logic change
17.17 replace counteroffer-first with Option C selective/aggressive split effect check
17.18 add Option C parameter-snapshot payload visibility
17.19 keep product guardrail policy exact-value audit
17.20 update final acceptance rollup to include Option C evidence readiness
```

Replace your current **17.16 through end of Section 17** with this full block.

```sql
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

OPTION C NOTE:
    Product guardrail strategy effect is separate from the Option C counteroffer strategy split.

    Section 17.16 remains focused on product-level guardrail behavior.

    Section 17.17 handles selective-versus-aggressive counteroffer strategy split evidence.

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

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')
            AS approval_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_rows,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_rows,

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

        SUM(COALESCE(approved_amount, 0))
            AS total_approved_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(exposure_reduction_amount, 0)) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS total_counteroffer_exposure_reduction_amount,

        AVG(approved_amount) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_amount_offer_rows,

        AVG(approved_expected_loss_amount) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_expected_loss_offer_rows,

        AVG(estimated_pd) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(approved_payment_to_income_ratio) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_pti_offer_rows

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
    cr.baseline_archived_rows,
    cr.challenger_archived_rows,
    cr.matched_application_id_count,
    cr.baseline_only_application_id_count,
    cr.challenger_only_application_id_count,
    cr.comparison_readiness_status,

    COALESCE(b.product_type_policy_key, ch.product_type_policy_key)
        AS product_type_policy_key,

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
    ch.total_approved_amount - b.total_approved_amount
        AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount
        AS baseline_total_approved_expected_loss_amount,

    ch.total_approved_expected_loss_amount
        AS challenger_total_approved_expected_loss_amount,

    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.total_counteroffer_exposure_reduction_amount
        AS baseline_total_counteroffer_exposure_reduction_amount,

    ch.total_counteroffer_exposure_reduction_amount
        AS challenger_total_counteroffer_exposure_reduction_amount,

    ch.total_counteroffer_exposure_reduction_amount
        - b.total_counteroffer_exposure_reduction_amount
            AS delta_total_counteroffer_exposure_reduction_amount,

    b.avg_approved_pti_offer_rows AS baseline_avg_approved_pti_offer_rows,
    ch.avg_approved_pti_offer_rows AS challenger_avg_approved_pti_offer_rows,
    ch.avg_approved_pti_offer_rows - b.avg_approved_pti_offer_rows
        AS delta_avg_approved_pti_offer_rows,

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



/***************************************************************************************************
SECTION 17.17 — OPTION C COUNTEROFFER STRATEGY SPLIT EFFECT CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Review the strategy effect for active comparison groups where the challenger is one of the formal
    Option C counteroffer strategy split strategies:

        SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
        AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

    Section 17.17 answers:

        "Did the selective and aggressive counteroffer strategy challengers produce interpretable
         counteroffer-management effects relative to their registered baselines?"

WHY THIS SECTION REPLACED COUNTEROFFER-FIRST:
    The prior COUNTEROFFER_FIRST_EXPOSURE_STRATEGY label was intentionally split into two clearer
    strategy postures:

        SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
            Preserves conservative, feasibility-first behavior.

        AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY
            Tests expansion-oriented routing by sending governed severe requested-structure cases
            into counteroffer feasibility testing.

WHY THIS SECTION IS COMPARISON-REGISTRY-SCOPED:
    The active comparison registry defines the governed baseline / challenger pairs.

    This section does not infer pairings only from strategy_name.

DYNAMIC ACCEPTANCE PRINCIPLE:
    Expected matched comparison row count is derived from the selected Module 1 source population.

    It is not hardcoded to 50,000.

INTERPRETATION:
    SELECTIVE_FEASIBILITY should generally:
        preserve governed counteroffer feasibility behavior,
        produce ordinary counteroffer candidates where appropriate,
        and produce no aggressive override rows.

    AGGRESSIVE_EXPANSION should generally:
        show aggressive override rows when severe requested-structure cases are present and eligible,
        split those aggressive override rows across final COUNTEROFFER, MANUAL_REVIEW, and DECLINE
        depending on Section 8 feasibility and Section 9 final resolution,
        and preserve reason-code traceability.

    This effect check is diagnostic.
    It is not a production recommendation.
    It does not decide whether aggressive expansion is better.

READ-ONLY BOUNDARY:
    This section does not modify archive rows, evidence rows, registry rows, strategy parameters, or
    product-policy parameters.

***************************************************************************************************/

WITH option_c_comparisons AS (
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
      AND challenger_strategy_name IN (
            'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY',
            'AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY'
      )
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
    FROM option_c_comparisons c

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
    FROM option_c_comparisons c

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

    FROM option_c_comparisons c

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

        MAX(counteroffer_strategy_variant)
            AS counteroffer_strategy_variant,

        COALESCE(
            BOOL_OR(aggressive_counteroffer_expansion_enabled),
            FALSE
        ) AS aggressive_counteroffer_expansion_enabled,

        COUNT(*) FILTER (
            WHERE ordinary_counteroffer_candidate_flag IS TRUE
        ) AS ordinary_counteroffer_candidate_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS aggressive_override_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS final_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
        ) AS final_manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
        ) AS final_decline_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS simulated_offer_exposure_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        )::NUMERIC / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
        )::NUMERIC / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
        )::NUMERIC / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        )::NUMERIC / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        SUM(COALESCE(exposure_reduction_amount, 0)) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS total_counteroffer_exposure_reduction_amount,

        AVG(exposure_reduction_pct) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_exposure_reduction_pct_for_final_counteroffers,

        AVG(approved_payment_to_income_ratio) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_approved_pti_for_final_counteroffers,

        AVG(approved_expected_loss_amount) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS avg_approved_expected_loss_for_final_counteroffers,

        SUM(COALESCE(approved_amount, 0))
            AS total_approved_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(exposure_reduction_amount, 0)) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'COUNTEROFFER'
        ) AS aggressive_override_counteroffer_exposure_reduction_amount,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'COUNTEROFFER'
        ) AS aggressive_override_final_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'MANUAL_REVIEW'
        ) AS aggressive_override_final_manual_review_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'DECLINE'
        ) AS aggressive_override_final_decline_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND COALESCE(triggered_reason_code_list, '')
                  LIKE '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
        ) AS aggressive_override_counteroffer_reason_trace_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND COALESCE(triggered_reason_code_list, '')
                  LIKE '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
        ) AS aggressive_override_manual_review_reason_trace_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND COALESCE(triggered_reason_code_list, '')
                  LIKE '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
        ) AS aggressive_override_decline_reason_trace_rows,

        SUM(COALESCE(approved_expected_loss_amount, 0))::NUMERIC
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

    c.baseline_strategy_name,
    c.challenger_strategy_name,
    c.expected_comparison_storyline,
    c.primary_metric_focus,

    b.counteroffer_strategy_variant AS baseline_counteroffer_strategy_variant,
    ch.counteroffer_strategy_variant AS challenger_counteroffer_strategy_variant,

    b.aggressive_counteroffer_expansion_enabled
        AS baseline_aggressive_counteroffer_expansion_enabled,

    ch.aggressive_counteroffer_expansion_enabled
        AS challenger_aggressive_counteroffer_expansion_enabled,

    b.ordinary_counteroffer_candidate_rows
        AS baseline_ordinary_counteroffer_candidate_rows,

    ch.ordinary_counteroffer_candidate_rows
        AS challenger_ordinary_counteroffer_candidate_rows,

    ch.ordinary_counteroffer_candidate_rows
        - b.ordinary_counteroffer_candidate_rows
            AS delta_ordinary_counteroffer_candidate_rows,

    b.aggressive_override_rows AS baseline_aggressive_override_rows,
    ch.aggressive_override_rows AS challenger_aggressive_override_rows,
    ch.aggressive_override_rows - b.aggressive_override_rows
        AS delta_aggressive_override_rows,

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

    b.total_counteroffer_exposure_reduction_amount
        AS baseline_total_counteroffer_exposure_reduction_amount,

    ch.total_counteroffer_exposure_reduction_amount
        AS challenger_total_counteroffer_exposure_reduction_amount,

    ch.total_counteroffer_exposure_reduction_amount
        - b.total_counteroffer_exposure_reduction_amount
            AS delta_total_counteroffer_exposure_reduction_amount,

    b.avg_exposure_reduction_pct_for_final_counteroffers
        AS baseline_avg_exposure_reduction_pct_for_final_counteroffers,

    ch.avg_exposure_reduction_pct_for_final_counteroffers
        AS challenger_avg_exposure_reduction_pct_for_final_counteroffers,

    b.avg_approved_pti_for_final_counteroffers
        AS baseline_avg_approved_pti_for_final_counteroffers,

    ch.avg_approved_pti_for_final_counteroffers
        AS challenger_avg_approved_pti_for_final_counteroffers,

    b.total_approved_amount AS baseline_total_approved_amount,
    ch.total_approved_amount AS challenger_total_approved_amount,
    ch.total_approved_amount - b.total_approved_amount
        AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount
        AS baseline_total_approved_expected_loss_amount,

    ch.total_approved_expected_loss_amount
        AS challenger_total_approved_expected_loss_amount,

    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    ch.approved_expected_loss_rate AS challenger_approved_expected_loss_rate,
    ch.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    ch.aggressive_override_final_counteroffer_rows,
    ch.aggressive_override_final_manual_review_rows,
    ch.aggressive_override_final_decline_rows,

    ch.aggressive_override_counteroffer_reason_trace_rows,
    ch.aggressive_override_manual_review_reason_trace_rows,
    ch.aggressive_override_decline_reason_trace_rows,

    CASE
        WHEN cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN ch.counteroffer_strategy_variant = 'SELECTIVE_FEASIBILITY'
         AND COALESCE(ch.aggressive_override_rows, 0) = 0
            THEN 'OPTION_C_SELECTIVE_FEASIBILITY_EFFECT_VISIBLE'

        WHEN ch.counteroffer_strategy_variant = 'SELECTIVE_FEASIBILITY'
         AND COALESCE(ch.aggressive_override_rows, 0) > 0
            THEN 'REVIEW_SELECTIVE_FEASIBILITY_HAS_AGGRESSIVE_OVERRIDE_ROWS'

        WHEN ch.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
         AND ch.aggressive_counteroffer_expansion_enabled IS TRUE
         AND COALESCE(ch.aggressive_override_rows, 0) > 0
            THEN 'OPTION_C_AGGRESSIVE_EXPANSION_EFFECT_VISIBLE'

        WHEN ch.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
         AND ch.aggressive_counteroffer_expansion_enabled IS TRUE
         AND COALESCE(ch.aggressive_override_rows, 0) = 0
            THEN 'REVIEW_AGGRESSIVE_EXPANSION_NO_OVERRIDE_ROWS'

        WHEN ch.counteroffer_strategy_variant = 'NOT_COUNTEROFFER_SPLIT_STRATEGY'
            THEN 'NOT_APPLICABLE_NON_COUNTEROFFER_SPLIT_STRATEGY'

        ELSE 'REVIEW_OPTION_C_COUNTEROFFER_STRATEGY_EFFECT'
    END AS option_c_counteroffer_strategy_effect_status

FROM option_c_comparisons c

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

OPTION C PARAMETER SNAPSHOT NOTE:
    Option C controls are captured inside strategy_params_jsonb.

    Section 17.18 surfaces whether each active campaign run captured the Option C fields needed to
    explain selective-versus-aggressive counteroffer behavior:

        counteroffer_strategy_variant
        aggressive_counteroffer_expansion_enabled
        severe_requested_structure_counteroffer_override_enabled
        exposure_extreme_counteroffer_override_enabled
        exposure_policy_stop_counteroffer_override_enabled
        requested_pti_decline_counteroffer_override_enabled
        requested_el_decline_counteroffer_override_enabled

EXPECTED RESULT:
    One row per active campaign registry run.

    Each row should generally show:
        parameter_snapshot_rows_for_run = 1
        strategy_params_captured_flag = TRUE
        product_policy_params_captured_flag = TRUE
        run_story_params_captured_flag = TRUE
        parameter_snapshot_hash_captured_flag = TRUE
        option_c_strategy_controls_captured_flag = TRUE
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
),

parameter_snapshot_profile AS (
    SELECT
        r.*,

        COALESCE(p.parameter_snapshot_rows_for_run, 0)
            AS parameter_snapshot_rows_for_run,

        p.strategy_params_jsonb,
        p.product_policy_params_jsonb,
        p.run_story_params_jsonb,
        p.parameter_snapshot_hash,

        p.module1_run_id AS snapshot_module1_run_id,
        p.module2_run_id AS snapshot_module2_run_id,
        p.run_sequence_number AS snapshot_run_sequence_number,
        p.showcase_id AS snapshot_showcase_id,
        p.comparison_group_id AS snapshot_comparison_group_id,
        p.validation_evidence_group_id AS snapshot_validation_evidence_group_id
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
)

SELECT
    run_sequence_number,
    module1_run_id,
    module2_run_id,
    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    parameter_snapshot_rows_for_run,

    strategy_params_jsonb IS NOT NULL
        AS strategy_params_captured_flag,

    product_policy_params_jsonb IS NOT NULL
        AS product_policy_params_captured_flag,

    run_story_params_jsonb IS NOT NULL
        AS run_story_params_captured_flag,

    parameter_snapshot_hash IS NOT NULL
        AS parameter_snapshot_hash_captured_flag,

    parameter_snapshot_hash,

    /***********************************************************************************************
    Option C strategy-control payload visibility.

    These fields read the JSONB strategy parameter snapshot. They do not recalculate strategy logic.
    ***********************************************************************************************/
    CASE
        WHEN jsonb_typeof(strategy_params_jsonb) = 'object'
         AND strategy_params_jsonb ? 'counteroffer_strategy_variant'
         AND strategy_params_jsonb ? 'aggressive_counteroffer_expansion_enabled'
         AND strategy_params_jsonb ? 'severe_requested_structure_counteroffer_override_enabled'
         AND strategy_params_jsonb ? 'exposure_extreme_counteroffer_override_enabled'
         AND strategy_params_jsonb ? 'exposure_policy_stop_counteroffer_override_enabled'
         AND strategy_params_jsonb ? 'requested_pti_decline_counteroffer_override_enabled'
         AND strategy_params_jsonb ? 'requested_el_decline_counteroffer_override_enabled'
            THEN TRUE
        ELSE FALSE
    END AS option_c_strategy_controls_captured_flag,

    strategy_params_jsonb ->> 'counteroffer_strategy_variant'
        AS captured_counteroffer_strategy_variant,

    (strategy_params_jsonb ->> 'aggressive_counteroffer_expansion_enabled')::BOOLEAN
        AS captured_aggressive_counteroffer_expansion_enabled,

    (strategy_params_jsonb ->> 'severe_requested_structure_counteroffer_override_enabled')::BOOLEAN
        AS captured_severe_requested_structure_counteroffer_override_enabled,

    (strategy_params_jsonb ->> 'exposure_extreme_counteroffer_override_enabled')::BOOLEAN
        AS captured_exposure_extreme_counteroffer_override_enabled,

    (strategy_params_jsonb ->> 'exposure_policy_stop_counteroffer_override_enabled')::BOOLEAN
        AS captured_exposure_policy_stop_counteroffer_override_enabled,

    (strategy_params_jsonb ->> 'requested_pti_decline_counteroffer_override_enabled')::BOOLEAN
        AS captured_requested_pti_decline_counteroffer_override_enabled,

    (strategy_params_jsonb ->> 'requested_el_decline_counteroffer_override_enabled')::BOOLEAN
        AS captured_requested_el_decline_counteroffer_override_enabled,

    CASE
        WHEN COALESCE(parameter_snapshot_rows_for_run, 0) = 0
            THEN 'PARAMETER_SNAPSHOT_MISSING'

        WHEN COALESCE(parameter_snapshot_rows_for_run, 0) > 1
            THEN 'DUPLICATE_PARAMETER_SNAPSHOT_REVIEW_REQUIRED'

        WHEN strategy_params_jsonb IS NULL
          OR product_policy_params_jsonb IS NULL
          OR run_story_params_jsonb IS NULL
          OR parameter_snapshot_hash IS NULL
            THEN 'PARAMETER_PAYLOAD_REVIEW_REQUIRED'

        WHEN jsonb_typeof(product_policy_params_jsonb) <> 'array'
          OR jsonb_array_length(product_policy_params_jsonb) = 0
            THEN 'PRODUCT_POLICY_PAYLOAD_REVIEW_REQUIRED'

        WHEN NOT (
            jsonb_typeof(strategy_params_jsonb) = 'object'
            AND strategy_params_jsonb ? 'counteroffer_strategy_variant'
            AND strategy_params_jsonb ? 'aggressive_counteroffer_expansion_enabled'
            AND strategy_params_jsonb ? 'severe_requested_structure_counteroffer_override_enabled'
            AND strategy_params_jsonb ? 'exposure_extreme_counteroffer_override_enabled'
            AND strategy_params_jsonb ? 'exposure_policy_stop_counteroffer_override_enabled'
            AND strategy_params_jsonb ? 'requested_pti_decline_counteroffer_override_enabled'
            AND strategy_params_jsonb ? 'requested_el_decline_counteroffer_override_enabled'
        )
            THEN 'OPTION_C_PARAMETER_PAYLOAD_REVIEW_REQUIRED'

        WHEN snapshot_module2_run_id IS DISTINCT FROM module2_run_id
          OR snapshot_run_sequence_number IS DISTINCT FROM run_sequence_number
          OR snapshot_module1_run_id IS DISTINCT FROM module1_run_id
          OR snapshot_showcase_id IS DISTINCT FROM showcase_id
          OR snapshot_comparison_group_id IS DISTINCT FROM comparison_group_id
          OR snapshot_validation_evidence_group_id IS DISTINCT FROM validation_evidence_group_id
            THEN 'PARAMETER_SOURCE_LINEAGE_REVIEW_REQUIRED'

        ELSE 'PARAMETER_SNAPSHOT_READY'
    END AS parameter_snapshot_status

FROM parameter_snapshot_profile

ORDER BY run_sequence_number;



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

CANONICAL PRODUCT-GUARDRAIL VALUE BOUNDARY:
    The exact product-policy values below are intentionally fixed because this section validates the
    specific product-guardrail profile design.

OPTION C NOTE:
    Section 17.19 is intentionally product-guardrail-specific.

    Option C selective/aggressive counteroffer strategy split evidence is evaluated in Sections 17.17,
    17.18, and 17.20.

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
    matched-source, evidence, convention, parameter-snapshot, product-policy, and Option C evidence
    checks.

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
        product-guardrail audit row count,
        or Option C strategy count.

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

OPTION C ACCEPTANCE NOTE:
    Section 17.20 now treats Option C evidence readiness as part of structural acceptance.

    This means final acceptance requires:
        Option C archive fields to be populated,
        aggressive override reason traces to be preserved,
        selective feasibility strategies to have no aggressive override rows,
        executive evidence Option C frontier fields to be populated,
        and Option C validation rows to be captured where they are part of the validation spine.

    Section 17.20 still does not decide whether aggressive expansion is better.

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
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) FILTER (
            WHERE counteroffer_strategy_variant IS NULL
               OR aggressive_counteroffer_expansion_enabled IS NULL
               OR severe_requested_structure_counteroffer_override_enabled IS NULL
               OR exposure_extreme_counteroffer_override_enabled IS NULL
               OR exposure_policy_stop_counteroffer_override_enabled IS NULL
               OR requested_pti_decline_counteroffer_override_enabled IS NULL
               OR requested_el_decline_counteroffer_override_enabled IS NULL
               OR ordinary_counteroffer_candidate_flag IS NULL
               OR aggressive_counteroffer_requested_structure_override_flag IS NULL
        ) AS option_c_archive_field_gap_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND (
                    (
                        decision_outcome = 'COUNTEROFFER'
                        AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                            '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
                    )
                 OR (
                        decision_outcome = 'MANUAL_REVIEW'
                        AND preliminary_decision_outcome = 'COUNTEROFFER'
                        AND counteroffer_feasibility_pass_flag IS FALSE
                        AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
                        AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                            '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
                 OR (
                        decision_outcome = 'DECLINE'
                        AND preliminary_decision_outcome = 'COUNTEROFFER'
                        AND counteroffer_feasibility_pass_flag IS FALSE
                        AND failed_counteroffer_resolution = 'DECLINE'
                        AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                            '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
              )
        ) AS aggressive_override_reason_trace_gap_rows,

        COUNT(*) FILTER (
            WHERE strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY'
              AND aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS selective_strategy_aggressive_override_rows

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
        COUNT(*) AS active_campaign_registry_rows_for_archive_check,

        COUNT(*) FILTER (
            WHERE s.expected_module1_source_rows IS NULL
        ) AS active_runs_missing_module1_source_count,

        COUNT(*) FILTER (
            WHERE s.expected_module1_source_rows IS NOT NULL
              AND s.expected_module1_source_rows <> s.expected_module1_distinct_application_id_count
        ) AS active_runs_with_module1_source_application_id_grain_issue,

        COUNT(*) FILTER (
            WHERE COALESCE(a.archived_rows, 0) > 0
        ) AS active_runs_with_archive_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(a.archived_rows, 0) = 0
        ) AS active_runs_missing_archive_rows,

        SUM(COALESCE(a.archived_rows, 0))
            AS total_active_campaign_archived_rows,

        SUM(COALESCE(s.expected_module1_source_rows, 0))
            AS expected_total_active_campaign_source_rows,

        COUNT(*) FILTER (
            WHERE s.expected_module1_source_rows IS NOT NULL
              AND COALESCE(a.archived_rows, 0) <> s.expected_module1_source_rows
        ) AS active_runs_with_archive_row_count_mismatch,

        COUNT(*) FILTER (
            WHERE s.expected_module1_source_rows IS NOT NULL
              AND COALESCE(a.distinct_application_id_count, 0) <> s.expected_module1_source_rows
        ) AS active_runs_with_archive_application_id_grain_issue,

        SUM(COALESCE(a.option_c_archive_field_gap_rows, 0))
            AS total_option_c_archive_field_gap_rows,

        SUM(COALESCE(a.aggressive_override_reason_trace_gap_rows, 0))
            AS total_aggressive_override_reason_trace_gap_rows,

        SUM(COALESCE(a.selective_strategy_aggressive_override_rows, 0))
            AS total_selective_strategy_aggressive_override_rows

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

active_archive_rows AS (
    SELECT
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

archive_grain_duplicate_summary AS (
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
        FROM active_archive_rows
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

comparison_application_overlap AS (
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

comparison_readiness_by_group AS (
    SELECT
        c.comparison_group_id,

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

    LEFT JOIN comparison_application_overlap o
        ON o.comparison_group_id = c.comparison_group_id
),

comparison_summary AS (
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

source_consistency_by_group AS (
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

    FROM matched_source_rows
    GROUP BY comparison_group_id
),

source_consistency_summary AS (
    SELECT
        COUNT(*) AS source_consistency_group_count,

        COUNT(*) FILTER (
            WHERE cr.comparison_readiness_status = 'READY_FOR_MATCHED_COMPARISON'
              AND COALESCE(sc.source_field_mismatch_count, 0) = 0
        ) AS source_consistency_pass_count,

        COUNT(*) FILTER (
            WHERE cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
               OR COALESCE(sc.source_field_mismatch_count, 0) <> 0
        ) AS source_consistency_review_count,

        COALESCE(SUM(sc.source_field_mismatch_count), 0)
            AS total_source_field_mismatch_rows

    FROM comparison_readiness_by_group cr

    LEFT JOIN source_consistency_by_group sc
        ON sc.comparison_group_id = cr.comparison_group_id
),

archive_segment_expected AS (
    SELECT
        r.module2_run_id,

        COUNT(DISTINCT (
            a.product_type_policy_key,
            a.score_band_policy_key,
            a.product_score_policy_segment
        )) FILTER (
            WHERE a.application_id IS NOT NULL
        ) AS expected_segment_rows

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

executive_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS executive_rows,

        COUNT(*) FILTER (
            WHERE counteroffer_strategy_variant IS NULL
               OR NULLIF(BTRIM(counteroffer_strategy_variant), '') IS NULL
               OR aggressive_counteroffer_expansion_enabled IS NULL
               OR ordinary_counteroffer_candidate_rows IS NULL
               OR ordinary_counteroffer_candidate_rate IS NULL
               OR aggressive_override_rows IS NULL
               OR aggressive_override_rate IS NULL
               OR aggressive_override_final_counteroffer_rows IS NULL
               OR aggressive_override_final_counteroffer_rate IS NULL
               OR aggressive_override_final_manual_review_rows IS NULL
               OR aggressive_override_final_manual_review_rate IS NULL
               OR aggressive_override_final_decline_rows IS NULL
               OR aggressive_override_final_decline_rate IS NULL
               OR option_c_frontier_posture_type IS NULL
               OR NULLIF(BTRIM(option_c_frontier_posture_type), '') IS NULL
               OR option_c_frontier_interpretation_note IS NULL
               OR NULLIF(BTRIM(option_c_frontier_interpretation_note), '') IS NULL
        ) AS option_c_executive_evidence_gap_rows

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
        )) AS duplicate_validation_key_rows,

        COUNT(*) FILTER (
            WHERE validation_area = 'Option C counteroffer split'
        ) AS option_c_validation_evidence_rows

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

evidence_by_run AS (
    SELECT
        r.module2_run_id,

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(e.option_c_executive_evidence_gap_rows, 0)
            AS option_c_executive_evidence_gap_rows,

        COALESCE(p.parameter_rows, 0) AS parameter_rows,

        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(v.validation_distinct_key_count, 0) AS validation_distinct_key_count,
        COALESCE(v.duplicate_validation_key_rows, 0) AS duplicate_validation_key_rows,
        COALESCE(v.option_c_validation_evidence_rows, 0) AS option_c_validation_evidence_rows,

        COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,

        COALESCE(ase.expected_segment_rows, 0) AS expected_segment_rows,

        COALESCE(s.segment_rows, 0) AS segment_rows,
        COALESCE(s.segment_distinct_key_count, 0) AS segment_distinct_key_count,
        COALESCE(s.duplicate_segment_key_rows, 0) AS duplicate_segment_key_rows

    FROM active_campaign_runs r

    CROSS JOIN validation_key_catalog vkc

    LEFT JOIN archive_segment_expected ase
        ON ase.module2_run_id = r.module2_run_id

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
),

evidence_summary AS (
    SELECT
        COUNT(*) AS registry_run_count_for_evidence_check,

        MAX(expected_validation_key_count)
            AS expected_validation_key_count,

        SUM(executive_rows) AS executive_evidence_rows,

        COUNT(*) FILTER (
            WHERE executive_rows = 1
              AND option_c_executive_evidence_gap_rows = 0
        ) AS executive_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE executive_rows <> 1
               OR option_c_executive_evidence_gap_rows <> 0
        ) AS executive_evidence_issue_run_count,

        SUM(parameter_rows) AS parameter_snapshot_rows,

        COUNT(*) FILTER (
            WHERE parameter_rows = 1
        ) AS parameter_snapshot_complete_run_count,

        COUNT(*) FILTER (
            WHERE parameter_rows <> 1
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
        SUM(validation_rows) AS total_validation_evidence_rows,

        SUM(option_c_validation_evidence_rows)
            AS total_option_c_validation_evidence_rows,

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
        SUM(segment_rows) AS total_segment_evidence_rows,

        SUM(option_c_executive_evidence_gap_rows)
            AS total_option_c_executive_evidence_gap_rows

    FROM evidence_by_run
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
            WHERE (
                    decision_outcome IN ('APPROVE', 'COUNTEROFFER')
                    AND simulated_offer_exposure_flag IS DISTINCT FROM TRUE
                  )
               OR (
                    decision_outcome IN ('MANUAL_REVIEW', 'DECLINE')
                    AND simulated_offer_exposure_flag IS DISTINCT FROM FALSE
                  )
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
              AND (
                    approved_amount IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
                 OR approved_payment_to_income_ratio IS NOT NULL
              )
        ) AS manual_review_amount_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
              )
        ) AS decline_amount_violation_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
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
            WHERE counteroffer_strategy_variant IS NULL
               OR aggressive_counteroffer_expansion_enabled IS NULL
               OR severe_requested_structure_counteroffer_override_enabled IS NULL
               OR exposure_extreme_counteroffer_override_enabled IS NULL
               OR exposure_policy_stop_counteroffer_override_enabled IS NULL
               OR requested_pti_decline_counteroffer_override_enabled IS NULL
               OR requested_el_decline_counteroffer_override_enabled IS NULL
               OR ordinary_counteroffer_candidate_flag IS NULL
               OR aggressive_counteroffer_requested_structure_override_flag IS NULL
        ) AS option_c_archive_field_gap_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND (
                    (
                        decision_outcome = 'COUNTEROFFER'
                        AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                            '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
                    )
                 OR (
                        decision_outcome = 'MANUAL_REVIEW'
                        AND preliminary_decision_outcome = 'COUNTEROFFER'
                        AND counteroffer_feasibility_pass_flag IS FALSE
                        AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
                        AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                            '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
                 OR (
                        decision_outcome = 'DECLINE'
                        AND preliminary_decision_outcome = 'COUNTEROFFER'
                        AND counteroffer_feasibility_pass_flag IS FALSE
                        AND failed_counteroffer_resolution = 'DECLINE'
                        AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                            '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
              )
        ) AS aggressive_override_reason_trace_gap_rows,

        COUNT(*) FILTER (
            WHERE strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY'
              AND aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS selective_strategy_aggressive_override_rows

    FROM active_archive_rows
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
            + reason_code_completeness_violation_rows
            + reason_family_alignment_violation_rows
            + option_c_archive_field_gap_rows
            + aggressive_override_reason_trace_gap_rows
            + selective_strategy_aggressive_override_rows
        ) AS critical_convention_violation_count,

        option_c_archive_field_gap_rows,
        aggressive_override_reason_trace_gap_rows,
        selective_strategy_aggressive_override_rows

    FROM convention_counts
),

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

        COUNT(*) AS expected_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(e.parameter_snapshot_rows_for_run, 0) = 1
              AND COALESCE(a.actual_product_policy_rows_for_product, 0) = 1
              AND a.actual_product_approve_max_pti IS NOT DISTINCT FROM e.expected_product_approve_max_pti
              AND a.actual_product_review_max_pti IS NOT DISTINCT FROM e.expected_product_review_max_pti
              AND a.actual_product_decline_min_pti IS NOT DISTINCT FROM e.expected_product_decline_min_pti
              AND a.actual_counteroffer_target_pti IS NOT DISTINCT FROM e.expected_counteroffer_target_pti
              AND a.actual_product_approve_max_requested_el IS NOT DISTINCT FROM e.expected_product_approve_max_requested_el
              AND a.actual_product_review_max_requested_el IS NOT DISTINCT FROM e.expected_product_review_max_requested_el
              AND a.actual_product_decline_min_requested_el IS NOT DISTINCT FROM e.expected_product_decline_min_requested_el
              AND a.actual_product_approved_el_cap IS NOT DISTINCT FROM e.expected_product_approved_el_cap
              AND a.actual_product_min_approved_amount IS NOT DISTINCT FROM e.expected_product_min_approved_amount
              AND a.actual_product_max_approved_amount IS NOT DISTINCT FROM e.expected_product_max_approved_amount
              AND a.actual_product_min_counteroffer_pct IS NOT DISTINCT FROM e.expected_product_min_counteroffer_pct
              AND a.actual_product_max_exposure_reduction_pct IS NOT DISTINCT FROM e.expected_product_max_exposure_reduction_pct
        ) AS product_guardrail_policy_ready_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(e.parameter_snapshot_rows_for_run, 0) <> 1
               OR COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1
               OR a.actual_product_approve_max_pti IS DISTINCT FROM e.expected_product_approve_max_pti
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
        ) AS product_guardrail_policy_mismatch_rows

    FROM expected_product_guardrail_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
),

acceptance_inputs AS (
    SELECT
        cr.active_campaign_registry_rows AS expected_campaign_runs,
        cmpr.active_comparison_registry_rows AS expected_comparison_groups,

        ar.expected_total_active_campaign_source_rows,
        ev.expected_validation_key_count,

        pga.product_guardrail_campaign_run_count
            AS expected_product_guardrail_campaign_runs,

        pga.audited_product_count,
        pga.expected_product_guardrail_policy_rows,

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
        ar.total_option_c_archive_field_gap_rows,
        ar.total_aggressive_override_reason_trace_gap_rows,
        ar.total_selective_strategy_aggressive_override_rows,

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
        ev.total_option_c_executive_evidence_gap_rows,

        ev.parameter_snapshot_rows,
        ev.parameter_snapshot_complete_run_count,
        ev.parameter_snapshot_issue_run_count,

        ev.validation_evidence_complete_run_count,
        ev.validation_evidence_incomplete_run_count,
        ev.min_validation_rows_per_run,
        ev.max_validation_rows_per_run,
        ev.total_validation_evidence_rows,
        ev.total_option_c_validation_evidence_rows,

        ev.segment_evidence_complete_run_count,
        ev.segment_evidence_issue_run_count,
        ev.min_expected_segment_rows_per_run,
        ev.max_expected_segment_rows_per_run,
        ev.min_segment_rows_per_run,
        ev.max_segment_rows_per_run,
        ev.total_segment_evidence_rows,

        cv.active_campaign_archived_rows,
        cv.critical_convention_violation_count,
        cv.option_c_archive_field_gap_rows,
        cv.aggressive_override_reason_trace_gap_rows,
        cv.selective_strategy_aggressive_override_rows,

        pga.product_guardrail_policy_ready_rows,
        pga.product_guardrail_policy_mismatch_rows,

        /*******************************************************************************************
        Acceptance flags.
        *******************************************************************************************/
        (
            cr.active_campaign_registry_rows > 0
            AND cr.duplicate_active_campaign_technical_key_rows = 0
        ) AS campaign_registry_ready_flag,

        (
            cmpr.active_comparison_registry_rows > 0
            AND cmpr.duplicate_active_comparison_group_rows = 0
        ) AS comparison_registry_ready_flag,

        (
            ar.active_campaign_registry_rows_for_archive_check = cr.active_campaign_registry_rows
            AND ar.active_runs_missing_module1_source_count = 0
            AND ar.active_runs_with_module1_source_application_id_grain_issue = 0
            AND ar.active_runs_missing_archive_rows = 0
            AND ar.active_runs_with_archive_row_count_mismatch = 0
            AND ar.active_runs_with_archive_application_id_grain_issue = 0
            AND ar.total_active_campaign_archived_rows = ar.expected_total_active_campaign_source_rows
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
            AND ev.executive_evidence_issue_run_count = 0
            AND ev.parameter_snapshot_issue_run_count = 0
            AND ev.validation_evidence_incomplete_run_count = 0
            AND ev.segment_evidence_issue_run_count = 0
            AND ev.total_option_c_executive_evidence_gap_rows = 0
            AND ev.total_option_c_validation_evidence_rows > 0
        ) AS evidence_ready_flag,

        (
            cv.active_campaign_archived_rows > 0
            AND cv.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,

        (
            ar.total_option_c_archive_field_gap_rows = 0
            AND ar.total_aggressive_override_reason_trace_gap_rows = 0
            AND ar.total_selective_strategy_aggressive_override_rows = 0
            AND ev.total_option_c_executive_evidence_gap_rows = 0
            AND ev.total_option_c_validation_evidence_rows > 0
        ) AS option_c_evidence_ready_flag,

        (
            pga.expected_product_guardrail_policy_rows = pga.product_guardrail_policy_ready_rows
            AND pga.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag

    FROM campaign_registry_summary cr
    CROSS JOIN comparison_registry_summary cmpr
    CROSS JOIN archive_summary ar
    CROSS JOIN archive_grain_duplicate_summary agd
    CROSS JOIN comparison_summary cmp
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
            AND option_c_evidence_ready_flag
        ) AS structural_acceptance_ready_flag,

        CASE
            WHEN campaign_registry_ready_flag
             AND comparison_registry_ready_flag
             AND archive_ready_flag
             AND comparison_ready_flag
             AND source_consistency_ready_flag
             AND evidence_ready_flag
             AND final_output_conventions_ready_flag
             AND option_c_evidence_ready_flag
             AND product_guardrail_policy_ready_flag
                THEN 'MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS'

            WHEN campaign_registry_ready_flag
             AND comparison_registry_ready_flag
             AND archive_ready_flag
             AND comparison_ready_flag
             AND source_consistency_ready_flag
             AND evidence_ready_flag
             AND final_output_conventions_ready_flag
             AND option_c_evidence_ready_flag
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
                WHEN option_c_evidence_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_OPTION_C_COUNTEROFFER_SPLIT_EVIDENCE'
            END,

            CASE
                WHEN product_guardrail_policy_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_PRODUCT_GUARDRAIL_POLICY_EXACT_VALUES'
            END
        ) AS acceptance_review_focus

    FROM acceptance_inputs ai
)

SELECT
    module2_campaign_acceptance_status,
    structural_acceptance_ready_flag,
    acceptance_review_focus,

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
    Registry and archive readiness.
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
    Comparison and source-consistency readiness.
    ***********************************************************************************************/
    comparison_group_count,
    comparison_ready_count,
    comparison_review_count,

    source_consistency_group_count,
    source_consistency_pass_count,
    source_consistency_review_count,
    total_source_field_mismatch_rows,

    /***********************************************************************************************
    Evidence readiness.
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
    Final-output convention readiness.
    ***********************************************************************************************/
    active_campaign_archived_rows,
    critical_convention_violation_count,

    /***********************************************************************************************
    Option C evidence readiness.

    These fields make the selective/aggressive counteroffer split part of final campaign acceptance.
    ***********************************************************************************************/
    total_option_c_archive_field_gap_rows,
    total_aggressive_override_reason_trace_gap_rows,
    total_selective_strategy_aggressive_override_rows,

    total_option_c_executive_evidence_gap_rows,
    total_option_c_validation_evidence_rows,

    option_c_archive_field_gap_rows,
    aggressive_override_reason_trace_gap_rows,
    selective_strategy_aggressive_override_rows,

    option_c_evidence_ready_flag,

    /***********************************************************************************************
    Product guardrail exact-value policy audit.
    ***********************************************************************************************/
    product_guardrail_policy_ready_rows,
    product_guardrail_policy_mismatch_rows,
    product_guardrail_policy_ready_flag,

    /***********************************************************************************************
    Final acceptance flags.
    ***********************************************************************************************/
    campaign_registry_ready_flag,
    comparison_registry_ready_flag,
    archive_ready_flag,
    comparison_ready_flag,
    source_consistency_ready_flag,
    evidence_ready_flag,
    final_output_conventions_ready_flag

FROM acceptance_status;



/***************************************************************************************************
END OF SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW

If execution reaches this point:
    1. Active campaign archive inventory has been reviewed.
    2. Active campaign archive slice detail has been reviewed.
    3. Archive grain has been checked.
    4. Campaign registry to archive reconciliation has been reviewed.
    5. Missing or mismatched registry runs have been surfaced.
    6. Archive slices without active campaign registry rows have been surfaced.
    7. Section 16 evidence coverage has been summarized.
    8. Section 16 evidence detail by run has been reviewed.
    9. Active-campaign final-output conventions have been checked.
    10. Validation evidence status mix has been summarized by campaign run.
    11. Validation REVIEW / NOT_APPLICABLE concentration has been surfaced.
    12. Comparison registry readiness has been reviewed.
    13. Matched source-field consistency has been reviewed.
    14. Executive evidence campaign summary has been reviewed.
    15. Baseline × challenger strategy deltas have been summarized.
    16. Product guardrail strategy effects have been reviewed.
    17. Option C selective/aggressive counteroffer strategy split effects have been reviewed.
    18. Parameter snapshot profile evidence has been reviewed.
    19. Product guardrail policy exact-value audit has been reviewed.
    20. Final Module 2 campaign acceptance rollup has been produced.

Option C note:
    Section 17 now treats the selective/aggressive counteroffer strategy split as part of final
    campaign evidence readiness.

    Final acceptance requires the evidence layer to preserve:
        ordinary counteroffer candidacy,
        aggressive requested-structure override routing,
        aggressive override final outcome mix,
        aggressive override reason-code traceability,
        and Option C frontier posture.

    Section 17 does not decide whether aggressive expansion is better.

    It confirms that the SQL evidence layer is complete enough to support final interpretation.

Interpretation guidance:
    If module2_campaign_acceptance_status = MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        the active Module 2 campaign is structurally ready for executive analysis, validation-summary
        drafting, README interpretation, and LinkedIn storyline development.

    If module2_campaign_acceptance_status =
       STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        structural acceptance passed, but product-guardrail exact-value evidence should be reviewed
        before final documentation claims are made.

    If module2_campaign_acceptance_status = REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        review acceptance_review_focus and the relevant Section 17 diagnostic outputs before using
        the campaign as final evidence.

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

The important changes are concentrated in **17.17** and **17.20**.

Section 17.17 now officially evaluates the two Option C challenger strategies rather than the legacy `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY`. Section 17.20 now treats Option C archive traceability, executive evidence completeness, and validation evidence capture as part of structural campaign acceptance.
<!-- END_MESSAGE C034-M01207 -->


---

<a id="c034-m01209"></a>

### C034-M01209

**Andrew** · 2026-05-16T22:32:23.920000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01209 -->
review sections 17.16 thru 17.18 logic, comments, headers for potential needed changes. Please make it very easy to implement (full copy paste). here is current 17.16 thru 17.18 code:
<!-- END_MESSAGE C034-M01209 -->


**Attachments in export:** `Pasted text(216).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_25.md) · [Next](Part_27.md)
