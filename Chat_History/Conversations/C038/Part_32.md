# Module 2 Decision Simulator Build

## Part 32

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_31.md) · [Next](Part_33.md)

<a id="c038-m00765"></a>

### C038-M00765

**ChatGPT** · 2026-05-09T18:13:57.686469-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00765 -->
Below is the updated **Section 14 header + Sections 14.1–14.5** as a copy-paste replacement, aligned to the higher commentary / governance standard from the hardened Sections 0–13 and preserving the SQL intent from your provided Section 14 chunk. fileciteturn46file2turn46file5

```sql
/***************************************************************************************************
SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the full read-only QA and validation evidence framework for the completed latest-run
    Module 2 strategy output.

    Section 14 answers:

        "Does this completed Module 2 strategy run behave coherently, consistently, explainably,
         and within the documented simulation boundaries?"

    Section 14 also creates the evidence foundation for later:
        validation-summary drafting,
        executive evidence capture,
        README interpretation,
        LinkedIn result storytelling,
        and controlled campaign-run documentation.

SQL PURPOSE:
    1. Inspect credit_decisioning_sim.strategy_decisions as the primary latest-run output.
    2. Inspect credit_decisioning_sim.strategy_decisions_archive only for archive-readiness context.
    3. Validate latest-run structural integrity, row grain, strategy scope, Module 1 lineage, final
       outcome completeness, final flag reconciliation, exposure conventions, Expected Loss
       conventions, simulated reason-code coverage, and segment-level strategy behavior.
    4. Review strategy behavior across:
            product,
            score band,
            product × score,
            synthetic estimated-risk tier,
            requested PTI,
            DTI,
            requested exposure,
            approved exposure,
            requested Expected Loss,
            approved Expected Loss,
            counteroffer treatment,
            manual-review treatment,
            decline / policy-stop behavior,
            simulated offer exposure,
            reason-code coverage,
            mixed-signal cases,
            borderline cases,
            archive readiness,
            matched strategy comparison readiness,
            and matched source-field consistency.
    5. Produce documentation-ready validation evidence queries.
    6. Materialize tmp_m2_validation_status_summary near the end of Section 14.
    7. Preserve a strictly read-only validation boundary for permanent Module 2 outputs.

PRIMARY VALIDATION TARGET:
    credit_decisioning_sim.strategy_decisions

SUPPORTING CONTEXT TABLES:
    credit_decisioning_sim.strategy_decisions_archive
    tmp_m2_strategy_comparison_readiness
    tmp_m2_strategy_comparison_source_consistency

TEMPORARY VALIDATION OUTPUT:
    tmp_m2_validation_status_summary

GRAIN OF PRIMARY VALIDATION TARGET:
    One row per application_id
    for one selected Module 1 scenario / population
    and one active Module 2 strategy version.

WHY QA IS SEPARATED FROM OUTPUT CREATION AND ARCHIVE PERSISTENCE:
    Section 11 materializes the latest-run output.

    Section 12 persists archive rows.

    Section 13 compares archived strategy slices.

    Section 14 validates the completed latest-run output and produces evidence that the strategy
    result is coherent, explainable, internally consistent, and bounded by the intended simulation
    design.

WHY DECISION DISTRIBUTION IS NOT SUFFICIENT BY ITSELF:
    A strategy output can have plausible high-level approval, counteroffer, manual-review, and
    decline rates while still failing product behavior, score-band behavior, affordability ordering,
    exposure conventions, counteroffer feasibility, reason-code coverage, or edge-case explainability.

    Therefore Section 14 reviews:
        structural integrity,
        final decision distribution,
        final flag reconciliation,
        product behavior,
        score-band behavior,
        product × score behavior,
        synthetic estimated-risk ordering,
        requested PTI sensitivity,
        DTI capacity behavior,
        requested versus approved exposure,
        requested versus approved Expected Loss,
        counteroffer feasibility,
        manual-review unresolved behavior,
        simulated policy-stop behavior,
        simulated reason-code coverage,
        simulated offer-exposure profile,
        mixed-signal cases,
        borderline cases,
        archive readiness,
        matched comparison readiness,
        and matched source-field consistency.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 14, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 14 does not recalculate estimated_pd.
    Section 14 does not calibrate estimated_pd.
    Section 14 does not validate production default forecasting.
    Section 14 does not treat estimated_pd as an empirically calibrated probability of default.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        Module 2 approved-exposure Expected Loss after simulated exposure treatment.

    Section 14 validates the distinction and reviews whether the values behave coherently.

    Section 14 does not recalculate either value.

APPROVED EXPOSURE BOUNDARY:
    approved_amount is final simulated approved exposure after Module 2 final decision resolution.

    APPROVE:
        approved_amount should equal requested_amount.

    COUNTEROFFER:
        approved_amount should be positive and below requested_amount.

    MANUAL_REVIEW:
        approved_amount should remain NULL because the simulated outcome is unresolved.

    DECLINE:
        approved_amount should equal zero by the locked no-offer convention.

MANUAL REVIEW BOUNDARY:
    MANUAL_REVIEW remains unresolved by design.

    Manual-review rows should not have:
        approved_amount,
        approved_payment_to_income_ratio,
        approved_expected_loss_amount,
        or simulated positive offer exposure.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies final simulated positive offer-exposure outcomes.

    It should be TRUE for:
        APPROVE
        COUNTEROFFER

    It should be FALSE for:
        MANUAL_REVIEW
        DECLINE

    It does not imply:
        operational account creation,
        booked exposure,
        funded exposure,
        production approval,
        real applicant treatment,
        or servicing activity.

SIMULATED REASON-CODE BOUNDARY:
    primary_reason_code, secondary_reason_code, tertiary_reason_code, and triggered_reason_code_list
    are simulated strategy explanation codes.

    They support:
        transparency,
        QA review,
        strategy interpretation,
        portfolio diagnostics,
        decision-path traceability,
        matched comparison,
        executive evidence capture,
        and validation documentation.

    They are not:
        customer communications,
        regulatory notices,
        production compliance determinations,
        adverse-action reasons,
        or fair-lending conclusions.

EDGE-CASE REVIEW:
    Edge cases should remain visible and explainable.

    Realistic overlap is not automatically a defect.

    It becomes a concern only if it:
        dominates the output,
        violates locked conventions,
        cannot be explained through staged diagnostics,
        or creates unstable strategy behavior.

VALIDATION STATUS SUMMARY PRINCIPLE:
    tmp_m2_validation_status_summary uses:

        PASS
        REVIEW
        NOT_APPLICABLE

    REVIEW means the pattern should be interpreted before documentation.

    REVIEW does not automatically mean the strategy output is invalid.

    Ordinary diagnostic patterns should not be labeled FAIL because critical structural failures
    should be handled earlier by fail-fast gatekeepers.

READ-ONLY BOUNDARY:
    Section 14 does not insert, delete, update, or modify latest-run output rows.
    Section 14 does not insert, delete, update, or modify archive rows.
    Section 14 does not recalculate decision_outcome.
    Section 14 does not reassign simulated reason codes.
    Section 14 does not recalculate approved exposure.
    Section 14 does not recalculate approved Expected Loss.
    Section 14 does not modify strategy parameters.
    Section 14 does not modify product policy parameters.
    Section 14 does not create archive rows.
    Section 14 does not run new modeling workstreams.
    Section 14 does not draft the BRD or written Validation Summary.

OPERATING GUIDANCE:
    Run Section 14 after Section 11 has materialized:

        credit_decisioning_sim.strategy_decisions

    Run Section 12 before Section 14 when archive-readiness diagnostics should confirm that the
    current latest-run slice has been archived.

    Run Section 13 before Section 14 when matched strategy comparison readiness and matched
    source-field consistency evidence should be available for the final validation status summary.

GOVERNANCE ROLE:
    Section 14 is the primary SQL validation evidence layer for the completed latest-run Module 2
    output.

    It supports later:
        executive evidence capture,
        Validation Summary drafting,
        README result interpretation,
        LinkedIn storyline development,
        and controlled campaign-run documentation.

COMMON MISUSE TO AVOID:
    Do not interpret Section 14 as recalculating strategy output.
    Do not interpret high-level approval rate alone as validation acceptance.
    Do not interpret REVIEW as automatic invalidation.
    Do not interpret simulated offer exposure as operational exposure.
    Do not interpret simulated reason codes as external communication text.
    Do not draft final validation narrative before reviewing the SQL evidence outputs.

***************************************************************************************************/



/***************************************************************************************************
SECTION 14.1 — VALIDATION SCOPE AND BOUNDARY
****************************************************************************************************

PURPOSE:
    Establish the latest-run validation scope before running detailed QA query blocks.

BUSINESS PURPOSE:
    Confirm exactly what Section 14 is validating before interpreting detailed diagnostics.

    The primary validation target is:
        credit_decisioning_sim.strategy_decisions

    Archive and comparison objects may be referenced later for readiness context, but they are not
    the primary latest-run validation target.

SQL PURPOSE:
    1. Count latest-run rows.
    2. Confirm application_id row grain.
    3. Confirm single-strategy latest-run scope.
    4. Confirm single Module 1 scenario / population latest-run scope.
    5. Show latest-run timestamp metadata.
    6. Produce a compact validation_scope_status.

EXPECTED RESULT:
    validation_scope_status should ordinarily equal:

        LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW

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
    It does not validate customer notices.
    It does not validate fair-lending conclusions.

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


/*-----------------------------------------------------------------------------------------------
14.1A Latest-run strategy and Module 1 lineage scope.

Purpose:
    Display the technical identity of the latest-run strategy slice.

Interpretation:
    Module 2 strategy identifiers describe the downstream strategy.

    Module 1 scenario identifiers describe the upstream synthetic population and risk environment.

    These concepts must remain separate for clean validation, archive persistence, and matched
    strategy comparison.

Expected:
    One row for the completed latest-run strategy / Module 1 scenario / population slice.

Timestamp note:
    strategy_run_ts and latest_output_created_ts are audit metadata.

    They support traceability, but they do not define comparison grain.
-----------------------------------------------------------------------------------------------*/

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
    Confirm that the latest-run strategy_decisions table is populated, unique at application_id, and
    complete across required strategy, lineage, decision, reason-code, and risk-economics fields.

BUSINESS PURPOSE:
    Establish that the output surface is structurally sound before strategy behavior is interpreted.

SQL PURPOSE:
    1. Confirm total row count.
    2. Confirm application_id uniqueness.
    3. Confirm single strategy version.
    4. Confirm single Module 1 scenario / population slice.
    5. Identify missing required lineage fields.
    6. Identify missing required final outcome fields.
    7. Identify missing required simulated reason-code fields.
    8. Identify missing requested Expected Loss fields.

EXPECTED INTERPRETATION:
    total_rows should equal distinct_application_id_count.

    duplicate_application_row_count should equal zero.

    distinct_strategy_version_count should equal one.

    distinct_module1_scenario_population_count should equal one.

    Missing core field counts should equal zero.

WHY STRUCTURAL QA COMES BEFORE STRATEGY QA:
    Decision distribution, reason-code summaries, product behavior, score-band behavior, and exposure
    diagnostics are only interpretable when the latest-run output has the expected row grain and
    lineage scope.

BOUNDARY:
    These are diagnostic checks.

    Earlier sections contain fail-fast gatekeepers. Section 14.2 provides documentation-ready
    evidence that the latest-run output remains structurally coherent.

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

    COUNT(*) FILTER (
        WHERE strategy_set_name IS NULL
           OR BTRIM(strategy_set_name) = ''
    ) AS null_or_blank_strategy_set_name_rows,

    COUNT(*) FILTER (
        WHERE strategy_name IS NULL
           OR BTRIM(strategy_name) = ''
    ) AS null_or_blank_strategy_name_rows,

    COUNT(*) FILTER (
        WHERE strategy_version IS NULL
           OR BTRIM(strategy_version) = ''
    ) AS null_or_blank_strategy_version_rows,

    COUNT(*) FILTER (
        WHERE module1_scenario_set_name IS NULL
           OR BTRIM(module1_scenario_set_name) = ''
    ) AS null_or_blank_module1_scenario_set_name_rows,

    COUNT(*) FILTER (
        WHERE module1_scenario_name IS NULL
           OR BTRIM(module1_scenario_name) = ''
    ) AS null_or_blank_module1_scenario_name_rows,

    COUNT(*) FILTER (
        WHERE population_id IS NULL
           OR BTRIM(population_id) = ''
    ) AS null_or_blank_population_id_rows,

    COUNT(*) FILTER (WHERE decision_outcome IS NULL)
        AS null_decision_outcome_rows,

    COUNT(*) FILTER (WHERE primary_reason_code IS NULL)
        AS null_primary_reason_code_rows,

    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL)
        AS null_requested_expected_loss_amount_rows,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.2A Row count by Module 1 input source.

Purpose:
    Confirm whether the latest-run output was sourced from the Module 1 latest-run table or the
    Module 1 scenario archive.

Expected:
    One input source and one source table for the latest-run output.

Interpretation:
    ARCHIVE source is preferred for formal strategy comparison because it preserves the exact
    upstream Module 1 scenario slice used for matched comparison.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.2B Duplicate application_id diagnostic.

Expected:
    zero rows.

Interpretation:
    application_id is the row-level latest-run grain for Module 2 V1.0.

    If any rows appear, the latest-run table is not unique at application_id and downstream
    application-level QA should not be interpreted until corrected.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.2C Required-field completeness diagnostic.

Purpose:
    Surface missing fields needed for latest-run QA interpretation.

Interpretation:
    This query does not replace fail-fast gatekeepers.

    It provides compact validation evidence that strategy metadata, Module 1 lineage, product /
    score keys, requested-structure fields, risk-economics fields, final decision fields, and
    simulated reason-code fields are present in the latest-run output.

Expected:
    All missing_* counts should be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE module2_model_version IS NULL
           OR BTRIM(module2_model_version) = ''
    ) AS missing_module2_model_version_rows,

    COUNT(*) FILTER (
        WHERE strategy_run_id IS NULL
           OR BTRIM(strategy_run_id) = ''
    ) AS missing_strategy_run_id_rows,

    COUNT(*) FILTER (WHERE strategy_run_ts IS NULL)
        AS missing_strategy_run_ts_rows,

    COUNT(*) FILTER (
        WHERE product_type_policy_key IS NULL
           OR BTRIM(product_type_policy_key) = ''
    ) AS missing_product_type_policy_key_rows,

    COUNT(*) FILTER (
        WHERE score_band_policy_key IS NULL
           OR BTRIM(score_band_policy_key) = ''
    ) AS missing_score_band_policy_key_rows,

    COUNT(*) FILTER (WHERE credit_score IS NULL)
        AS missing_credit_score_rows,

    COUNT(*) FILTER (WHERE requested_amount IS NULL)
        AS missing_requested_amount_rows,

    COUNT(*) FILTER (WHERE requested_monthly_payment_proxy IS NULL)
        AS missing_requested_monthly_payment_proxy_rows,

    COUNT(*) FILTER (WHERE requested_payment_to_income_ratio IS NULL)
        AS missing_requested_payment_to_income_ratio_rows,

    COUNT(*) FILTER (WHERE estimated_pd IS NULL)
        AS missing_synthetic_estimated_pd_proxy_rows,

    COUNT(*) FILTER (WHERE estimated_lgd IS NULL)
        AS missing_estimated_lgd_rows,

    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL)
        AS missing_requested_expected_loss_amount_rows,

    COUNT(*) FILTER (WHERE decision_outcome IS NULL)
        AS missing_decision_outcome_rows,

    COUNT(*) FILTER (
        WHERE decision_path IS NULL
           OR BTRIM(decision_path) = ''
    ) AS missing_decision_path_rows,

    COUNT(*) FILTER (
        WHERE decision_resolution_source IS NULL
           OR BTRIM(decision_resolution_source) = ''
    ) AS missing_decision_resolution_source_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_code IS NULL
           OR BTRIM(primary_reason_code) = ''
    ) AS missing_primary_reason_code_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_family IS NULL
           OR BTRIM(primary_reason_family) = ''
    ) AS missing_primary_reason_family_rows,

    COUNT(*) FILTER (
        WHERE triggered_reason_code_list IS NULL
           OR BTRIM(triggered_reason_code_list) = ''
    ) AS missing_triggered_reason_code_list_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.3 — DECISION OUTCOME DISTRIBUTION
****************************************************************************************************

PURPOSE:
    Summarize final simulated strategy outcomes and confirm high-level outcome composition.

BUSINESS PURPOSE:
    Provide the first executive-readable view of the completed latest-run Module 2 strategy output.

SQL PURPOSE:
    1. Count final decision_outcome values.
    2. Calculate population share by decision_outcome.
    3. Display final flag counts by decision_outcome.
    4. Display simulated offer-exposure counts by decision_outcome.
    5. Summarize synthetic estimated-risk proxy, requested PTI, approved amount, requested Expected
       Loss, and approved Expected Loss by final outcome.

EXPECTED INTERPRETATION:
    Every row should have exactly one final decision_outcome.

    APPROVE and COUNTEROFFER represent simulated positive offer-exposure outcomes.

    MANUAL_REVIEW remains unresolved by design.

    DECLINE follows the zero-exposure convention.

WHY THIS QUERY IS NOT SUFFICIENT BY ITSELF:
    Outcome distribution is necessary but not complete validation evidence.

    A strategy can have plausible overall rates while still failing:
        product behavior,
        score-band behavior,
        affordability sensitivity,
        approved-exposure conventions,
        counteroffer feasibility,
        reason-code explanation coverage,
        or edge-case review.

    Section 14 therefore continues with segment-level and diagnostic validation after this high-level
    outcome review.

***************************************************************************************************/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_population,

    COUNT(*) FILTER (WHERE approval_flag IS TRUE)
        AS approval_flag_count,

    COUNT(*) FILTER (WHERE counteroffer_flag IS TRUE)
        AS counteroffer_flag_count,

    COUNT(*) FILTER (WHERE manual_review_flag IS TRUE)
        AS manual_review_flag_count,

    COUNT(*) FILTER (WHERE decline_flag IS TRUE)
        AS decline_flag_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_flag_count,

    AVG(estimated_pd)
        AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_apps,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

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


/*-----------------------------------------------------------------------------------------------
14.3A Final decision-flag reconciliation distribution.

Purpose:
    Confirm that exactly one final decision flag is TRUE for each row.

Expected:
    final_decision_flag_count = 1 for every row.

Interpretation:
    This is compact evidence that approval_flag, counteroffer_flag, manual_review_flag, and
    decline_flag reconcile to final decision_outcome.

    Earlier sections contain fail-fast checks. This query provides documentation-ready QA evidence.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.3B Preliminary route to final outcome distribution.

Purpose:
    Show how preliminary routing resolved after exposure treatment and final decision resolution.

Interpretation:
    This query connects Section 7 preliminary routing to Section 9 final outcome resolution.

    It is especially useful for reviewing:
        preliminary COUNTEROFFER rows that became final COUNTEROFFER,
        failed preliminary COUNTEROFFER rows that became MANUAL_REVIEW or DECLINE,
        preliminary MANUAL_REVIEW rows that remained unresolved,
        preliminary DECLINE rows confirmed as no-offer outcomes,
        and preliminary APPROVE rows confirmed as positive offer exposure.
-----------------------------------------------------------------------------------------------*/

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

BUSINESS PURPOSE:
    Evaluate whether final simulated strategy outcomes, approved exposure, requested Expected Loss,
    approved Expected Loss, and reason-code patterns behave coherently across product types.

SQL PURPOSE:
    1. Summarize final decision outcomes by product.
    2. Calculate product-level decision rates.
    3. Compare requested exposure to approved exposure by product.
    4. Compare requested-exposure Expected Loss to approved-exposure Expected Loss by product.
    5. Review product-level simulated reason-code distributions.

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
        final simulated strategy outcome,
        and simulated explanation-code distribution.

METRIC CONVENTION:
    All-application approved metrics use COALESCE to treat unresolved manual-review approved exposure
    as zero for portfolio-impact summaries.

    Offer-row metrics use FILTER where simulated_offer_exposure_flag = TRUE.

    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is approved-exposure Expected Loss.

BOUNDARY:
    Product-level QA supports strategy interpretation.

    It does not define product policy for real applicants.
    It does not create production underwriting guidance.
    It does not override Section 2 product policy parameters.

***************************************************************************************************/

WITH product_outcome AS (
    SELECT
        product_type_policy_key,
        decision_outcome,

        COUNT(*) AS row_count,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(estimated_lgd) AS avg_estimated_lgd,

        AVG(requested_amount) AS avg_requested_amount,

        AVG(COALESCE(approved_amount, 0))
            AS avg_approved_amount_all_apps,

        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        AVG(requested_expected_loss_amount)
            AS avg_requested_expected_loss_amount,

        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_count

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


/*-----------------------------------------------------------------------------------------------
14.4A Product-level decision-rate summary.

Purpose:
    Provide one compact row per product for executive and validation review.

Interpretation:
    This query is useful for identifying product-level strategy skew.

    A high decline rate, high manual-review rate, high counteroffer rate, or low simulated
    offer-exposure rate may be valid, but it should be explainable through:
        product exposure,
        product PTI thresholds,
        product Expected Loss thresholds,
        product approved amount caps,
        LGD,
        score mix,
        affordability mix,
        counteroffer feasibility,
        and reason-code distribution.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')
        AS approval_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS counteroffer_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS manual_review_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
        AS decline_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY product_type_policy_key

ORDER BY product_type_policy_key;


/*-----------------------------------------------------------------------------------------------
14.4B Product-level primary reason-code distribution.

Purpose:
    Confirm that product-level strategy outcomes remain explainable through simulated strategy
    explanation codes.

Interpretation:
    Product-level reason-code concentration can help explain why a product has higher approvals,
    higher counteroffers, higher manual reviews, or higher declines.

    High concentration is not automatically a defect.

    It means the product-level strategy story should explain why that reason dominates.
-----------------------------------------------------------------------------------------------*/

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

BUSINESS PURPOSE:
    Confirm that final simulated strategy outcomes align directionally with borrower-quality
    segmentation while preserving realistic overlap.

SQL PURPOSE:
    1. Summarize final decision outcomes by score band.
    2. Calculate score-band approval, counteroffer, manual-review, decline, and simulated
       offer-exposure rates.
    3. Review average credit score, synthetic estimated-risk proxy, DTI, requested PTI, requested
       Expected Loss, and approved Expected Loss by score-band outcome.
    4. Provide compact score-band decision-rate evidence.
    5. Review score-band reason-code distribution.

BUSINESS INTERPRETATION:
    Stronger score bands should generally show higher approval rates and positive simulated
    offer-exposure rates.

    Weaker score bands should generally show higher manual-review or decline rates.

    Perfect monotonicity is not required at every micro-segment because product mix, affordability,
    exposure structure, behavioral signals, and product-specific policy rules can create realistic
    overlap.

WHY OVERLAP IS EXPECTED:
    Realistic portfolios contain:
        strong-score applicants with high requested PTI,
        weaker-score applicants with manageable requested PTI,
        high-income applicants with large requested exposure,
        lower-risk score bands with product-level exposure pressure,
        and higher-risk score bands with lower exposure.

    Section 14.5 should therefore be read as directional QA, not rigid deterministic ordering.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name and is interpreted as the synthetic
    estimated-PD proxy.

    Score-band QA reviews directional strategy behavior and risk ordering.

    It does not validate calibrated default probabilities.

EXPECTED LOSS BOUNDARY:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is approved-exposure Expected Loss.

    Score-band QA compares their behavior but does not recalculate them.

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
        100.0 * o.row_count::NUMERIC
        / NULLIF(s.applications, 0),
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


/*-----------------------------------------------------------------------------------------------
14.5A Score-band decision-rate summary.

Purpose:
    Provide a compact one-row-per-score-band profile for directional risk-ordering review.

Interpretation:
    This query should support fast validation of the high-level score-band story:

        stronger score bands should generally show lower synthetic estimated-risk proxy values,
        higher approval rates,
        and higher simulated offer-exposure rates;

        weaker score bands should generally show higher synthetic estimated-risk proxy values,
        higher manual-review rates,
        or higher decline rates.

    Perfect monotonicity is not required because product mix, requested PTI, DTI, exposure intensity,
    behavioral signals, and product-specific policy controls can create realistic overlap.

Documentation use:
    This query is one of the cleanest Section 14 outputs for README and Validation Summary discussion.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.5B Score-band reason-code distribution.

Purpose:
    Review whether score-band outcomes remain explainable through simulated strategy explanation
    codes.

Business interpretation:
    Stronger score bands should generally concentrate in approval or lower-friction positive
    offer-exposure reason families.

    Weaker score bands should generally show more manual-review, counteroffer, or policy-stop
    explanation patterns.

    Product mix, affordability, DTI, exposure, and behavioral signals can create exceptions.

Boundary:
    Reason codes are simulated strategy explanation codes.

    They are not customer communications.
    They are not external notices.
    They are not regulatory reason codes.
    They are not fair-lending conclusions.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

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
END OF SECTION 14.5 — SCORE-BAND STRATEGY QA

This partial Section 14 chunk has established:
    1. Section 14 validation purpose and read-only boundary.
    2. Latest-run validation scope and lineage diagnostics.
    3. Latest-run structural integrity diagnostics.
    4. Required-field completeness diagnostics.
    5. Final decision outcome distribution diagnostics.
    6. Final decision flag reconciliation diagnostics.
    7. Preliminary route to final outcome diagnostics.
    8. Product-level strategy QA.
    9. Product-level reason-code distribution QA.
    10. Score-band strategy QA.
    11. Score-band reason-code distribution QA.
    12. Continued interpretation of estimated_pd as the synthetic estimated-PD proxy.
    13. Continued distinction between requested-exposure Expected Loss and approved-exposure
        Expected Loss.
    14. Continued simulated offer-exposure boundary discipline.
    15. Continued simulated reason-code boundary discipline.

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
```
<!-- END_MESSAGE C038-M00765 -->


---

<a id="c038-m00768"></a>

### C038-M00768

**ChatGPT** · 2026-05-09T18:14:38.238325-04:00 · alternate branch

<!-- BEGIN_MESSAGE C038-M00768 -->
Using your provided Section 14 header + Sections 14.1–14.5 as the base, below is the copy-paste replacement at the same elevated commentary / governance level as the hardened Sections 0–13. I preserved the SQL intent and expanded the teaching, interpretation, and boundary language. fileciteturn46file8turn46file9

```sql
/***************************************************************************************************
SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the full read-only validation, QA, and diagnostic evidence layer for the completed
    latest-run Module 2 strategy output.

    Section 14 answers:

        "Does this completed Module 2 strategy run behave coherently, consistently, explainably,
         and within the documented simulation boundaries?"

    Section 14 also supports later documentation by producing query outputs that can be used for:
        Validation Summary drafting,
        executive evidence capture,
        README interpretation,
        LinkedIn result storytelling,
        and campaign-run governance.

SQL PURPOSE:
    1. Inspect credit_decisioning_sim.strategy_decisions as the primary latest-run output.
    2. Inspect credit_decisioning_sim.strategy_decisions_archive only for archive-readiness context.
    3. Consume Section 13 comparison helper outputs when available.
    4. Validate latest-run scope, row grain, lineage consistency, final outcome completeness, final
       flag reconciliation, approved-exposure conventions, approved Expected Loss conventions, and
       simulated reason-code coverage.
    5. Review strategy behavior across:
            product,
            score band,
            product × score,
            synthetic estimated-risk tier,
            requested PTI,
            DTI,
            requested exposure,
            approved exposure,
            requested Expected Loss,
            approved Expected Loss,
            counteroffer treatment,
            manual-review treatment,
            decline / policy-stop behavior,
            simulated offer exposure,
            mixed-signal cases,
            borderline cases,
            archive readiness,
            matched comparison readiness,
            and matched source-field consistency.
    6. Materialize tmp_m2_validation_status_summary near the end of Section 14 as a compact temporary
       validation status output.
    7. Preserve a strictly read-only boundary for permanent Module 2 outputs.

INPUTS:
    credit_decisioning_sim.strategy_decisions
        Completed latest-run Module 2 strategy output created in Section 11.

    credit_decisioning_sim.strategy_decisions_archive
        Governed strategy archive history created and maintained in Section 12.

    tmp_m2_strategy_comparison_readiness
        Temporary Section 13 readiness summary for the selected baseline / challenger comparison.
        Used when Section 13 has already run.

    tmp_m2_strategy_comparison_source_consistency
        Temporary Section 13 matched source-field consistency diagnostic.
        Used when Section 13 has already run.

OUTPUTS:
    Read-only validation and QA result sets.

TEMPORARY OUTPUT CREATED LATER IN SECTION 14:
    tmp_m2_validation_status_summary

GRAIN OF VALIDATION TARGET:
    credit_decisioning_sim.strategy_decisions should contain:

        one row per application_id
        for one selected Module 1 scenario / population
        and one active Module 2 strategy version.

WHY QA IS SEPARATED FROM OUTPUT CREATION AND ARCHIVE PERSISTENCE:
    Section 11 materializes the latest-run output.

    Section 12 persists archive rows.

    Section 13 compares archived strategy slices.

    Section 14 validates the completed latest-run output and provides evidence that the strategy
    result is coherent, explainable, internally consistent, and bounded by the intended simulation
    design.

WHY DECISION DISTRIBUTION IS NOT SUFFICIENT BY ITSELF:
    A strategy output can have plausible high-level approval, counteroffer, manual-review, and
    decline rates while still failing product behavior, affordability ordering, exposure conventions,
    reason-code coverage, or edge-case explainability.

    Therefore Section 14 reviews:
        structural integrity,
        final decision distribution,
        final flag reconciliation,
        product behavior,
        score-band behavior,
        product × score behavior,
        synthetic estimated-risk tier behavior,
        requested PTI behavior,
        DTI behavior,
        requested versus approved exposure,
        requested versus approved Expected Loss,
        counteroffer feasibility,
        manual-review unresolved behavior,
        simulated policy-stop behavior,
        simulated reason-code coverage,
        simulated offer-exposure profile,
        mixed-signal cases,
        borderline cases,
        archive readiness,
        matched comparison readiness,
        and matched source-field consistency.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 14, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 14 does not recalculate estimated_pd.
    Section 14 does not treat estimated_pd as a calibrated probability of default.
    Section 14 does not validate production default forecasting.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        Module 2 approved-exposure Expected Loss after simulated exposure treatment.

    Section 14 validates the distinction but does not recalculate either value.

MANUAL REVIEW BOUNDARY:
    MANUAL_REVIEW remains unresolved by design.

    Manual-review rows should not have final approved amount, final approved PTI, or final approved
    Expected Loss populated.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows.

    It means the simulated strategy output includes positive offer exposure.

    It does not imply:
        operational account creation,
        funding,
        production approval,
        booked exposure,
        real applicant treatment,
        or real customer treatment.

SIMULATED REASON-CODE BOUNDARY:
    primary_reason_code, secondary_reason_code, tertiary_reason_code, and triggered_reason_code_list
    are simulated strategy explanation codes.

    They support:
        transparency,
        QA review,
        strategy interpretation,
        portfolio diagnostics,
        decision-path traceability,
        matched strategy comparison,
        and validation evidence.

    They are not:
        external notices,
        production compliance determinations,
        customer communications,
        adverse-action reason codes,
        or fair-lending conclusions.

EDGE-CASE REVIEW:
    Edge cases should remain visible and explainable.

    Realistic overlap is not automatically a defect.

    It becomes a concern only if it:
        dominates the output,
        violates locked output conventions,
        lacks simulated reason-code explanation,
        or cannot be explained through:
            product structure,
            borrower profile,
            affordability,
            synthetic estimated-risk tiering,
            rule triggers,
            exposure-treatment diagnostics,
            counteroffer feasibility,
            or simulated reason-code assignment.

VALIDATION STATUS SUMMARY PRINCIPLE:
    tmp_m2_validation_status_summary uses:

        PASS
        REVIEW
        NOT_APPLICABLE

    It does not use ordinary diagnostic FAIL status because critical structural failures should be
    handled earlier by fail-fast gatekeepers.

    REVIEW means the pattern is worth interpretation.
    REVIEW does not automatically mean the strategy is invalid.

READ-ONLY BOUNDARY:
    Section 14 does not insert, delete, update, or modify latest-run output rows.
    Section 14 does not insert, delete, update, or modify archive rows.
    Section 14 does not recalculate decision_outcome.
    Section 14 does not reassign simulated reason codes.
    Section 14 does not recalculate approved exposure.
    Section 14 does not recalculate approved Expected Loss.
    Section 14 does not modify strategy parameters.
    Section 14 does not modify product policy parameters.
    Section 14 does not create archive rows.
    Section 14 does not perform new modeling workstreams.
    Section 14 does not draft the BRD or written Validation Summary.

OPERATING GUIDANCE:
    Run Section 14 after Section 11 has materialized:

        credit_decisioning_sim.strategy_decisions

    Run Section 12 before Section 14 when archive-readiness diagnostics should show the current
    latest-run slice as archived.

    Run Section 13 before Section 14 when matched comparison readiness and matched source-field
    consistency should populate in tmp_m2_validation_status_summary.

GOVERNANCE ROLE:
    Section 14 is the primary validation evidence layer for the completed latest-run Module 2 output.

    It supports later:
        executive evidence capture,
        validation-summary drafting,
        README storytelling,
        LinkedIn result interpretation,
        and controlled campaign-run documentation.

COMMON MISUSE TO AVOID:
    Do not interpret Section 14 as recalculating strategy output.
    Do not interpret REVIEW as automatic invalidation.
    Do not interpret simulated offer exposure as operational exposure.
    Do not interpret simulated reason codes as external communication text.
    Do not interpret high-level approval rate alone as validation acceptance.
    Do not draft final validation narrative before reviewing the SQL evidence outputs.

***************************************************************************************************/



/***************************************************************************************************
SECTION 14.1 — VALIDATION SCOPE AND BOUNDARY
****************************************************************************************************

PURPOSE:
    Establish the latest-run validation scope before running detailed QA query blocks.

BUSINESS PURPOSE:
    Confirm exactly what Section 14 is validating before any strategy behavior or outcome evidence is
    interpreted.

    The primary validation target is:

        credit_decisioning_sim.strategy_decisions

    Archive information may be referenced later for archive-readiness and comparison-readiness
    context, but Section 14 is fundamentally a latest-run validation layer.

SQL PURPOSE:
    1. Count latest-run rows.
    2. Count distinct application_id values.
    3. Confirm the latest-run table contains one Module 2 strategy version.
    4. Confirm the latest-run table contains one Module 1 scenario / population slice.
    5. Surface run timestamp and latest-output timestamp metadata.
    6. Assign a validation_scope_status label for review.

EXPECTED INTERPRETATION:
    validation_scope_status should ordinarily equal:

        LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW

    Anything else should be reviewed before interpreting downstream Section 14 diagnostics.

WHY THIS SECTION EXISTS:
    Validation evidence should be scoped before it is interpreted.

    A latest-run strategy output should be evaluated as:
        one active Module 2 strategy,
        applied to one selected Module 1 scenario / population slice,
        producing one final simulated strategy outcome per synthetic application.

WHY MODULE 1 LINEAGE AND MODULE 2 STRATEGY METADATA ARE BOTH SHOWN:
    Module 1 lineage identifies the upstream synthetic population and scenario environment.

    Module 2 strategy metadata identifies the downstream simulated strategy applied to that
    population.

    These concepts must remain separate.

TIMESTAMP BOUNDARY:
    strategy_run_ts and latest_output_created_ts are audit metadata.

    They help trace when the strategy run and latest-run materialization occurred.

    They should not be used as matched-comparison keys or business outcome metrics.

BOUNDARY:
    Section 14 validates simulation coherence and output consistency.
    It does not convert Module 2 into an operational decision system.
    It does not validate real applicant treatment.
    It does not validate calibrated default forecasting.
    It does not validate regulatory notices.
    It does not validate fair-lending conclusions.

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


/*-----------------------------------------------------------------------------------------------
14.1A Latest-run strategy and Module 1 lineage scope.

Purpose:
    Display the technical identity of the completed latest-run output.

Business interpretation:
    This query intentionally separates:
        Module 2 strategy identity
        from
        Module 1 scenario / population identity.

Expected:
    One row for a single latest-run strategy / Module 1 scenario / population slice.

Review trigger:
    More than one row may indicate mixed strategy output, mixed Module 1 scenario lineage, or a
    latest-run materialization problem.
-----------------------------------------------------------------------------------------------*/

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
    Confirm that the latest-run strategy_decisions table is populated, unique at application_id, and
    complete across the core fields needed for strategy QA.

BUSINESS PURPOSE:
    Validate the structural foundation before interpreting decision outcomes, segment behavior,
    exposure economics, reason-code distributions, or edge-case diagnostics.

SQL PURPOSE:
    1. Count total latest-run rows.
    2. Count distinct application_id values.
    3. Surface duplicate application_id row count.
    4. Confirm one strategy version is present.
    5. Confirm one Module 1 scenario / population slice is present.
    6. Surface missing key lineage fields.
    7. Surface missing core decision and reason-code fields.
    8. Display latest-output timestamp range.

EXPECTED INTERPRETATION:
    total_rows should equal distinct_application_id_count.

    distinct_strategy_version_count should equal 1.

    distinct_module1_scenario_population_count should equal 1.

    Required lineage, strategy, final decision, requested Expected Loss, and simulated reason-code
    fields should be populated.

WHY STRUCTURAL QA COMES BEFORE STRATEGY QA:
    Decision distribution, reason-code summaries, product behavior, score-band behavior, and exposure
    diagnostics are only interpretable if the output table has the expected row grain and lineage
    scope.

BOUNDARY:
    This section provides structural diagnostics only.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not recalculate outcomes.
    It does not reassign reason codes.

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

    COUNT(*) FILTER (
        WHERE strategy_set_name IS NULL
           OR BTRIM(strategy_set_name) = ''
    ) AS null_or_blank_strategy_set_name_rows,

    COUNT(*) FILTER (
        WHERE strategy_name IS NULL
           OR BTRIM(strategy_name) = ''
    ) AS null_or_blank_strategy_name_rows,

    COUNT(*) FILTER (
        WHERE strategy_version IS NULL
           OR BTRIM(strategy_version) = ''
    ) AS null_or_blank_strategy_version_rows,

    COUNT(*) FILTER (
        WHERE module1_scenario_set_name IS NULL
           OR BTRIM(module1_scenario_set_name) = ''
    ) AS null_or_blank_module1_scenario_set_name_rows,

    COUNT(*) FILTER (
        WHERE module1_scenario_name IS NULL
           OR BTRIM(module1_scenario_name) = ''
    ) AS null_or_blank_module1_scenario_name_rows,

    COUNT(*) FILTER (
        WHERE population_id IS NULL
           OR BTRIM(population_id) = ''
    ) AS null_or_blank_population_id_rows,

    COUNT(*) FILTER (WHERE decision_outcome IS NULL)
        AS null_decision_outcome_rows,

    COUNT(*) FILTER (WHERE primary_reason_code IS NULL)
        AS null_primary_reason_code_rows,

    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL)
        AS null_requested_expected_loss_amount_rows,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.2A Row count by Module 1 input source.

Purpose:
    Confirm which Module 1 source mode produced the latest-run output.

Expected:
    One source mode and one source table for the latest-run output.

Interpretation:
    module1_input_source distinguishes latest-run Module 1 consumption from archive-slice
    consumption.

    For formal scenario / strategy campaign runs, ARCHIVE input is generally preferred because it
    preserves exact upstream scenario slice lineage.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.2B Duplicate application_id diagnostic.

Expected:
    zero rows.

Business interpretation:
    The latest-run output should contain one row per application_id.

Review trigger:
    If any rows appear, the latest-run table is not unique at application_id and downstream
    application-level QA should not be interpreted until corrected.

Boundary:
    This query only detects duplicates. It does not remove them.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.2C Required-field completeness diagnostic.

Purpose:
    Surface missing core fields needed for strategy QA.

Business interpretation:
    Earlier sections contain fail-fast gatekeepers. This query provides documentation-ready evidence
    that the latest-run output remains complete after materialization.

Expected:
    All missing-field counts should ordinarily be zero.

Important distinction:
    Manual-review approved exposure fields are intentionally nullable and are not treated as missing
    in this required-field diagnostic.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE module2_model_version IS NULL
           OR BTRIM(module2_model_version) = ''
    ) AS missing_module2_model_version_rows,

    COUNT(*) FILTER (
        WHERE strategy_run_id IS NULL
           OR BTRIM(strategy_run_id) = ''
    ) AS missing_strategy_run_id_rows,

    COUNT(*) FILTER (
        WHERE strategy_run_ts IS NULL
    ) AS missing_strategy_run_ts_rows,

    COUNT(*) FILTER (
        WHERE product_type_policy_key IS NULL
           OR BTRIM(product_type_policy_key) = ''
    ) AS missing_product_type_policy_key_rows,

    COUNT(*) FILTER (
        WHERE score_band_policy_key IS NULL
           OR BTRIM(score_band_policy_key) = ''
    ) AS missing_score_band_policy_key_rows,

    COUNT(*) FILTER (
        WHERE credit_score IS NULL
    ) AS missing_credit_score_rows,

    COUNT(*) FILTER (
        WHERE requested_amount IS NULL
    ) AS missing_requested_amount_rows,

    COUNT(*) FILTER (
        WHERE requested_monthly_payment_proxy IS NULL
    ) AS missing_requested_monthly_payment_proxy_rows,

    COUNT(*) FILTER (
        WHERE requested_payment_to_income_ratio IS NULL
    ) AS missing_requested_payment_to_income_ratio_rows,

    COUNT(*) FILTER (
        WHERE estimated_pd IS NULL
    ) AS missing_synthetic_estimated_pd_proxy_rows,

    COUNT(*) FILTER (
        WHERE estimated_lgd IS NULL
    ) AS missing_estimated_lgd_rows,

    COUNT(*) FILTER (
        WHERE requested_expected_loss_amount IS NULL
    ) AS missing_requested_expected_loss_amount_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome IS NULL
    ) AS missing_decision_outcome_rows,

    COUNT(*) FILTER (
        WHERE decision_path IS NULL
           OR BTRIM(decision_path) = ''
    ) AS missing_decision_path_rows,

    COUNT(*) FILTER (
        WHERE decision_resolution_source IS NULL
           OR BTRIM(decision_resolution_source) = ''
    ) AS missing_decision_resolution_source_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_code IS NULL
           OR BTRIM(primary_reason_code) = ''
    ) AS missing_primary_reason_code_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_family IS NULL
           OR BTRIM(primary_reason_family) = ''
    ) AS missing_primary_reason_family_rows,

    COUNT(*) FILTER (
        WHERE triggered_reason_code_list IS NULL
           OR BTRIM(triggered_reason_code_list) = ''
    ) AS missing_triggered_reason_code_list_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.3 — DECISION OUTCOME DISTRIBUTION
****************************************************************************************************

PURPOSE:
    Summarize final simulated strategy outcomes and confirm final decision flag behavior at the
    population level.

BUSINESS PURPOSE:
    Provide the high-level final simulated strategy outcome distribution before moving into segment,
    exposure, affordability, reason-code, and edge-case diagnostics.

SQL PURPOSE:
    1. Count final decision_outcome values.
    2. Calculate population share by final outcome.
    3. Display final decision-flag counts by outcome.
    4. Display simulated offer-exposure count by outcome.
    5. Compare requested and approved exposure / Expected Loss summaries by outcome.
    6. Show preliminary route to final outcome resolution.

EXPECTED INTERPRETATION:
    Every row should have exactly one final decision_outcome.

    APPROVE and COUNTEROFFER represent simulated positive offer-exposure outcomes.

    MANUAL_REVIEW remains unresolved by design.

    DECLINE follows the zero-exposure convention.

WHY THIS QUERY IS NOT SUFFICIENT BY ITSELF:
    Outcome distribution is necessary but not complete validation evidence.

    A strategy can have plausible overall approval, counteroffer, manual-review, and decline rates
    while still failing:
        product-level behavior,
        score-band behavior,
        affordability behavior,
        exposure conventions,
        counteroffer feasibility,
        reason-code coverage,
        or edge-case explainability.

    Section 14 therefore continues with segment-level and diagnostic validation after this high-level
    outcome review.

BOUNDARY:
    These are simulated strategy outcomes for synthetic applicants.

    They are not operational applicant decisions.

***************************************************************************************************/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_population,

    COUNT(*) FILTER (WHERE approval_flag IS TRUE) AS approval_flag_count,
    COUNT(*) FILTER (WHERE counteroffer_flag IS TRUE) AS counteroffer_flag_count,
    COUNT(*) FILTER (WHERE manual_review_flag IS TRUE) AS manual_review_flag_count,
    COUNT(*) FILTER (WHERE decline_flag IS TRUE) AS decline_flag_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_flag_count,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_apps,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

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


/*-----------------------------------------------------------------------------------------------
14.3A Final decision-flag reconciliation distribution.

Purpose:
    Confirm that final outcome flags reconcile to the final decision taxonomy.

Expected:
    final_decision_flag_count = 1 for every row.

Business interpretation:
    Exactly one of the following should be TRUE for each synthetic application:
        approval_flag
        counteroffer_flag
        manual_review_flag
        decline_flag

    This query complements the Section 11 gatekeeper and provides documentation-ready evidence.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.3B Preliminary route to final outcome distribution.

Purpose:
    Show how preliminary routing resolved after exposure-treatment feasibility and final decision
    resolution.

Business interpretation:
    This query connects:
        Section 7 preliminary routing
        to
        Section 9 final simulated outcome resolution.

    It is especially useful for identifying:
        preliminary counteroffers that resolved to final COUNTEROFFER,
        failed counteroffers that resolved to MANUAL_REVIEW or DECLINE,
        preliminary reviews that remained unresolved,
        and preliminary declines that were confirmed.

Boundary:
    decision_resolution_source is an internal simulation diagnostic, not a simulated reason code.
-----------------------------------------------------------------------------------------------*/

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

BUSINESS PURPOSE:
    Evaluate whether final simulated outcomes, approved exposure, approved PTI, approved Expected
    Loss, and simulated reason-code patterns behave coherently by product type.

SQL PURPOSE:
    1. Summarize final decision outcomes by product.
    2. Calculate product-specific outcome shares.
    3. Compare requested and approved exposure by product and outcome.
    4. Compare requested and approved Expected Loss by product and outcome.
    5. Review product-level simulated offer exposure.
    6. Review product-level primary reason-code distributions.

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
    All-application approved metrics use COALESCE because those metrics describe full-population
    portfolio impact.

    Offer-row metrics use FILTER where simulated_offer_exposure_flag = TRUE because those metrics
    describe approved positive-offer economics only.

MANUAL REVIEW CONVENTION:
    MANUAL_REVIEW rows remain unresolved by design.

    Their final approved exposure and approved Expected Loss fields should remain NULL.

    Full-population portfolio summaries use COALESCE for aggregate exposure impact, not because
    manual-review rows are truly approved for zero.

EXPECTED INTERPRETATION:
    Product-level differences are expected.

    A product with higher exposure, higher LGD, or tighter product guardrails may show different
    approval, counteroffer, review, decline, approved exposure, and approved Expected Loss patterns.

BOUNDARY:
    Product-level QA supports strategy interpretation.

    It does not define production product policy.
    It does not approve real applicants.
    It does not set real credit-line limits.

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

        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        AVG(requested_expected_loss_amount)
            AS avg_requested_expected_loss_amount,

        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_count

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


/*-----------------------------------------------------------------------------------------------
14.4A Product-level decision-rate summary.

Purpose:
    Provide one compact row per product for fast product-level strategy QA.

Business interpretation:
    This query is useful for spotting product-level strategy concentration, product-specific offer
    exposure, and product-specific approved Expected Loss behavior.

Expected:
    Product-level outcome rates may differ materially because product policy parameters and product
    structural economics differ.
-----------------------------------------------------------------------------------------------*/

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

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_count,

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


/*-----------------------------------------------------------------------------------------------
14.4B Product-level primary reason-code distribution.

Purpose:
    Confirm that product-level strategy outcomes remain explainable through simulated strategy
    explanation codes.

Business interpretation:
    Product-level reason-code concentration can reveal whether a product is being driven primarily by:
        clean approval,
        counteroffer exposure limits,
        affordability pressure,
        expected-loss limits,
        manual-review uncertainty,
        or simulated policy stops.

Boundary:
    primary_reason_code is a simulated strategy explanation code.

    It is not external communication text.
-----------------------------------------------------------------------------------------------*/

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

BUSINESS PURPOSE:
    Review whether score-band behavior is directionally coherent and explainable within the broader
    Module 2 strategy design.

SQL PURPOSE:
    1. Summarize final decision outcomes by score band.
    2. Calculate score-band outcome rates.
    3. Compare average credit score and synthetic estimated-PD proxy by score-band / outcome.
    4. Compare requested PTI, DTI, requested Expected Loss, and approved Expected Loss by score-band
       / outcome.
    5. Provide a compact score-band decision-rate summary.
    6. Review score-band reason-code distribution.

BUSINESS INTERPRETATION:
    Stronger score bands should generally show higher approval / positive offer rates.

    Weaker score bands should generally show higher manual-review or decline rates.

    Perfect monotonicity is not required at every micro-segment because product mix, affordability,
    exposure structure, behavioral signals, DTI, LGD, requested Expected Loss, and product-specific
    policy rules can create realistic overlap.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name and is interpreted as the synthetic
    estimated-PD proxy.

    Score-band QA reviews directional strategy behavior and risk ordering.

    It does not validate calibrated default probabilities.
    It does not validate production risk model calibration.
    It does not create a post-decision risk model.

WHY SCORE-BAND QA IS NEEDED EVEN WHEN estimated_pd EXISTS:
    Score band is the borrower-quality anchor.

    estimated_pd is the synthetic risk proxy after multiple borrower, product, affordability, and
    structural effects.

    Reviewing both helps confirm that the strategy preserves intuitive credit-quality ordering while
    still allowing realistic mixed-signal cases.

EXPECTED INTERPRETATION:
    Stronger score bands should generally have:
        lower average synthetic estimated-PD proxy,
        higher approval or simulated offer-exposure rates,
        lower policy-stop concentration,
        and reason codes concentrated more often in approval or lower-friction offer outcomes.

    Weaker score bands should generally have:
        higher average synthetic estimated-PD proxy,
        more manual-review or policy-stop outcomes,
        and reason codes reflecting elevated risk, capacity stress, affordability pressure, or
        simulated policy stops.

BOUNDARY:
    Score-band QA supports strategy interpretation.

    It does not create production underwriting cutoffs.
    It does not imply real applicant treatment.
    It does not convert score band into a deterministic decision rule.

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
        100.0 * o.row_count::NUMERIC
        / NULLIF(s.applications, 0),
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


/*-----------------------------------------------------------------------------------------------
14.5A Score-band compact decision-rate summary.

Purpose:
    Provide one compact score-band profile for directional risk-ordering review.

Business interpretation:
    This query helps validate that borrower-quality bands remain directionally coherent after
    strategy routing, exposure treatment, counteroffer feasibility, final outcome assignment, and
    reason-code assignment.

Expected:
    Stronger score bands should generally show higher approval and simulated offer-exposure rates.

    Weaker score bands should generally show higher manual-review or decline rates.

Review trigger:
    Unexpected score-band ordering is not automatically wrong, but it should be explained through
    product mix, affordability stress, DTI, exposure size, requested Expected Loss, policy-stop
    triggers, or reason-code distributions.
-----------------------------------------------------------------------------------------------*/

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


/*-----------------------------------------------------------------------------------------------
14.5B Score-band primary reason-code distribution.

Purpose:
    Review whether score-band outcomes are explainable through simulated strategy explanation codes.

Business interpretation:
    This query supports review of whether weaker score bands concentrate in expected simulated
    policy-stop or manual-review explanation families while stronger score bands concentrate in
    approval or lower-friction offer outcomes.

Important:
    Reason-code concentration is not automatically a defect.

    It becomes a review item when the concentration is unexpected, unexplained, or inconsistent with
    the intended strategy posture.

Boundary:
    primary_reason_code is a simulated strategy explanation code.

    It is not external communication text.
    It is not an adverse-action reason code.
    It is not a production compliance conclusion.
-----------------------------------------------------------------------------------------------*/

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
```
<!-- END_MESSAGE C038-M00768 -->


---

<a id="c038-m00770"></a>

### C038-M00770

**Andrew** · 2026-05-09T18:16:13.220000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00770 -->
thank you.  do the same for sections 14.6-14.10:
<!-- END_MESSAGE C038-M00770 -->


**Attachments in export:** `Pasted text(126).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00773"></a>

### C038-M00773

**ChatGPT** · 2026-05-09T18:20:01.380078-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00773 -->
Below is the updated **Sections 14.6–14.10** copy-paste replacement, elevated to the same commentary / governance standard as the prior hardened sections while preserving the SQL intent from your provided Section 14.6–14.10 chunk. fileciteturn47file0

```sql
/***************************************************************************************************
SECTION 14.6 — PRODUCT × SCORE DECISION MATRIX
****************************************************************************************************

BUSINESS PURPOSE:
    Validate how final simulated Module 2 strategy outcomes concentrate across the intersection of
    product type and borrower credit-quality segmentation.

    Section 14.6 answers:

        "Are simulated strategy outcomes concentrated in product × score-band segments in ways that
         are directionally intuitive, explainable, and consistent with product-aware strategy design?"

SQL PURPOSE:
    1. Summarize final decision outcomes by product_type_policy_key and score_band_policy_key.
    2. Calculate approval, counteroffer, manual-review, decline, and simulated offer-exposure rates.
    3. Summarize average credit score, synthetic estimated-risk proxy, LGD, requested exposure,
       approved exposure, requested PTI, approved PTI, requested Expected Loss, and approved Expected
       Loss by product × score segment.
    4. Expand the matrix by decision_outcome so segment-level outcome concentration can be reviewed.
    5. Expand the matrix by primary_reason_code so segment-level outcomes remain explainable.

BUSINESS INTERPRETATION:
    Product × score-band analysis is one of the most important Module 2 validation outputs.

    Product type and score band are both major strategy dimensions:

        product type:
            shapes requested exposure, payment mechanics, LGD, product caps, affordability treatment,
            counteroffer feasibility, and product-level Expected Loss behavior.

        score band:
            shapes borrower-quality segmentation, synthetic estimated-risk tiering, and directional
            risk posture.

    Reviewing them jointly prevents portfolio-level averages from hiding important segment-level
    behavior.

WHY PRODUCT × SCORE MATTERS:
    A portfolio-level approval rate may look reasonable while a product × score intersection behaves
    unexpectedly.

    For example:
        unsecured weaker-score segments may show elevated manual review or decline concentration;
        secured stronger-score segments may show higher simulated offer exposure;
        high-balance product segments may show counteroffer concentration due to exposure caps;
        revolving weaker-score segments may show reason-code concentration tied to product guardrails.

    Product × score QA helps identify whether those patterns are coherent and explainable.

METRIC CONVENTIONS:
    approval_rate:
        APPROVE rows / applications.

    counteroffer_rate:
        COUNTEROFFER rows / applications.

    manual_review_rate:
        MANUAL_REVIEW rows / applications.

    decline_rate:
        DECLINE rows / applications.

    simulated_offer_exposure_rate:
        APPROVE + COUNTEROFFER rows / applications.

    avg_approved_amount_all_apps:
        Uses COALESCE(approved_amount, 0) because it describes total simulated exposure impact across
        the full segment.

    avg_approved_amount_offer_rows:
        Uses only rows where simulated_offer_exposure_flag = TRUE because it describes the positive
        simulated offer-exposure population.

    avg_approved_expected_loss_all_apps:
        Uses COALESCE(approved_expected_loss_amount, 0) because it describes total simulated approved
        Expected Loss impact across the full segment.

    avg_approved_expected_loss_offer_rows:
        Uses only rows where simulated_offer_exposure_flag = TRUE because it describes the approved
        Expected Loss profile of simulated positive offer-exposure outcomes.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 14.6, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 14.6 does not recalculate estimated_pd.
    Section 14.6 does not validate calibrated default probabilities.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        Module 2 approved-exposure Expected Loss after final exposure treatment.

    Section 14.6 compares these values for validation interpretation but does not recalculate either
    value.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies final simulated positive offer exposure.

    It does not imply operational account creation, funding, booking, production approval, or real
    applicant treatment.

REASON-CODE BOUNDARY:
    primary_reason_code and primary_reason_family are simulated strategy explanation fields.

    They support segment-level explainability.

    They are not customer communications, adverse-action notices, regulatory reason codes, or
    fair-lending conclusions.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
14.6A Product × score segment summary.

Purpose:
    Provide one row per product × score-band segment.

Interpretation:
    This is the most compact segment-level strategy distribution table in Section 14.

    Use it to identify:
        where simulated offer exposure concentrates,
        where approved exposure concentrates,
        where approved Expected Loss concentrates,
        and where product-aware strategy behavior differs across score bands.

Documentation use:
    Strong candidate for README / executive evidence because it connects product, credit quality,
    access, exposure, affordability, and approved Expected Loss in one view.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,

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

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    AVG(credit_score) AS avg_credit_score,
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

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount

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
14.6B Product × score × decision-outcome distribution.

Purpose:
    Expand the product × score matrix by final decision_outcome.

Interpretation:
    This query shows whether a product × score segment is dominated by one simulated strategy path.

    High concentration is not automatically wrong. It should be explainable through:
        score quality,
        product exposure,
        PTI,
        DTI,
        requested Expected Loss,
        approved Expected Loss,
        counteroffer feasibility,
        or simulated reason codes.

Expected use:
    Review segments where pct_within_product_score_segment is unusually high for:
        MANUAL_REVIEW,
        DECLINE,
        COUNTEROFFER,
        or APPROVE.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,

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
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome

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
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
14.6C Product × score × primary reason-code distribution.

Purpose:
    Connect product × score outcome concentration to simulated strategy explanation codes.

Interpretation:
    This diagnostic explains why product × score segments are moving into particular final outcomes.

    Example uses:
        Identify whether weak-score unsecured declines are driven by synthetic risk, DTI, exposure,
        requested PTI, or product policy stops.

        Identify whether product × score counteroffers are driven by product exposure limits,
        affordability adjustment, synthetic risk exposure limits, or approved Expected Loss limits.

Boundary:
    Reason codes are simulated strategy explanation codes only. They are not external notices or
    production compliance reasons.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,
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
    ) AS pct_within_product_score_segment

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,
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
SECTION 14.7 — SYNTHETIC RISK ORDERING QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that synthetic estimated-risk segmentation flows coherently into final simulated
    strategy outcomes.

    Section 14.7 answers:

        "Does the strategy generally offer more favorable outcomes to lower synthetic-risk tiers
         and route higher synthetic-risk tiers toward counteroffer, manual review, or decline in a
         directionally coherent way?"

SQL PURPOSE:
    1. Summarize final decision outcomes by strategy_risk_tier.
    2. Calculate approval, counteroffer, manual-review, decline, and simulated offer-exposure rates
       by synthetic risk tier.
    3. Compare requested PTI, requested Expected Loss, and approved Expected Loss by risk tier and
       final outcome.
    4. Provide a compact synthetic-risk-tier summary.
    5. Compare average synthetic estimated-risk proxy between simulated offer rows and declined rows.
    6. Produce a directional synthetic-risk-ordering status.

BUSINESS INTERPRETATION:
    Higher synthetic estimated-risk tiers should generally show:
        lower clean approval rates,
        lower simulated offer-exposure rates,
        higher manual-review rates,
        higher decline rates,
        or more counteroffer behavior when exposure treatment is feasible.

    Counteroffer behavior may appear in elevated risk tiers where reduced exposure can satisfy
    affordability and approved Expected Loss constraints.

WHY PERFECT MONOTONICITY IS NOT REQUIRED:
    Product mix, requested exposure, DTI, requested PTI, behavioral signals, product guardrails, and
    counteroffer feasibility can create realistic overlap.

    The validation expectation is broad directional coherence, not rigid deterministic sorting.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 14.7, estimated_pd is interpreted only as the synthetic estimated-PD proxy.

    This QA block reviews directional ordering and strategy sensitivity.

    It does not validate a calibrated default model.
    It does not calculate rank-order performance statistics.
    It does not produce production model validation evidence.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is approved-exposure Expected Loss.

    This section compares their behavior across synthetic risk tiers but does not recalculate either
    field.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
14.7A Synthetic risk tier × final decision outcome.

Purpose:
    Review how strategy_risk_tier maps into final simulated outcomes.

Interpretation:
    Lower synthetic risk tiers should generally show more APPROVE and positive offer-exposure
    behavior.

    Higher synthetic risk tiers should generally show more COUNTEROFFER, MANUAL_REVIEW, or DECLINE
    behavior.

    Exceptions should be explainable through product mix, affordability, DTI, exposure, or reason
    codes.
-----------------------------------------------------------------------------------------------*/

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

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

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
    o.avg_requested_payment_to_income_ratio,
    o.avg_requested_expected_loss_amount,
    o.avg_approved_expected_loss_all_apps,

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


/*-----------------------------------------------------------------------------------------------
14.7B Compact synthetic risk tier summary.

Purpose:
    Provide one row per synthetic risk tier for directional risk-ordering review.

Interpretation:
    This query is useful for checking whether synthetic estimated-risk tiers are ordered as expected
    and whether simulated offer exposure declines as synthetic risk increases.

Documentation use:
    Strong candidate for Validation Summary evidence because it is compact and easy to interpret.

Boundary:
    This is directional risk-ordering QA, not calibrated model performance testing.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,

    COUNT(*) AS applications,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    MIN(estimated_pd) AS min_synthetic_estimated_pd_proxy,
    MAX(estimated_pd) AS max_synthetic_estimated_pd_proxy,

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
        AS total_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY strategy_risk_tier

ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
14.7C Offered versus declined synthetic estimated-risk comparison.

Purpose:
    Compare average synthetic estimated-risk proxy for simulated positive offer-exposure rows versus
    final declined rows.

Expected interpretation:
    Offered rows should generally have lower average synthetic estimated-PD proxy than declined rows.

Status logic:
    SYNTHETIC_RISK_ORDERING_DIRECTIONALLY_ALIGNED:
        Average synthetic estimated-risk proxy among offered rows is less than or equal to the
        average among declined rows.

    SYNTHETIC_RISK_ORDERING_REVIEW_REQUIRED:
        Offered rows have a higher average synthetic estimated-risk proxy than declined rows.

    NOT_APPLICABLE_INSUFFICIENT_OFFER_OR_DECLINE_ROWS:
        Comparison cannot be evaluated because one side has zero rows.

Boundary:
    This is a broad directional check, not calibrated model validation.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_rows,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
        AS decline_rows,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS manual_review_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_synthetic_estimated_pd_proxy_decline_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_synthetic_estimated_pd_proxy_manual_review_rows,

    CASE
        WHEN COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) = 0
          OR COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') = 0
            THEN 'NOT_APPLICABLE_INSUFFICIENT_OFFER_OR_DECLINE_ROWS'

        WHEN AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
           <= AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            THEN 'SYNTHETIC_RISK_ORDERING_DIRECTIONALLY_ALIGNED'

        ELSE 'SYNTHETIC_RISK_ORDERING_REVIEW_REQUIRED'
    END AS synthetic_risk_ordering_status

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.8 — REQUESTED PTI / AFFORDABILITY SENSITIVITY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that requested-structure affordability pressure affects simulated Module 2 strategy
    outcomes in a directionally coherent way.

    Section 14.8 answers:

        "Does higher requested PTI generally reduce clean approval likelihood and increase
         counteroffer, manual review, or decline behavior?"

SQL PURPOSE:
    1. Summarize final decision outcomes by requested_pti_bucket.
    2. Calculate approval, counteroffer, manual-review, decline, and simulated offer-exposure rates by
       requested PTI bucket.
    3. Compare requested PTI, approved PTI, synthetic estimated-risk proxy, requested Expected Loss,
       and approved Expected Loss by requested PTI bucket and outcome.
    4. Produce a directional requested PTI sensitivity status.
    5. Review whether final COUNTEROFFER rows improved approved PTI relative to requested PTI.

BUSINESS INTERPRETATION:
    Higher requested PTI buckets should generally show:
        fewer clean approvals,
        more counteroffers,
        more manual reviews,
        or more declines.

    Counteroffer rows should generally reduce approved PTI relative to requested PTI because approved
    exposure has been reduced.

REQUESTED VS APPROVED PTI:
    requested_payment_to_income_ratio:
        Comes from the Module 1 requested structure.

    approved_payment_to_income_ratio:
        Module 2 post-exposure-treatment affordability proxy.

    approved_payment_to_income_ratio exists only for simulated positive offer-exposure rows.

    Manual-review rows remain unresolved and should not have approved PTI populated.

WHY THIS SECTION USES REQUESTED PTI BUCKETS:
    Strategy routing starts from the original requested structure.

    Counteroffer and approved exposure treatment may later improve affordability for feasible final
    COUNTEROFFER rows.

    Therefore requested_pti_bucket is the correct input-side affordability lens for Section 14.8.

BOUNDARY:
    This section reviews affordability sensitivity.

    It does not recalculate requested PTI.
    It does not recalculate approved PTI.
    It does not calculate contractual amortization.
    It does not perform production affordability underwriting.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
14.8A Requested PTI bucket × final decision outcome.

Purpose:
    Review how requested-structure affordability pressure flows into final simulated outcomes.

Interpretation:
    Lower requested PTI buckets should generally have higher approval / simulated offer-exposure
    rates.

    Higher requested PTI buckets should generally show more counteroffer, manual review, or decline
    behavior.

    Exceptions should be explainable through product structure, credit quality, DTI, exposure, and
    reason codes.
-----------------------------------------------------------------------------------------------*/

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
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

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
            AS avg_approved_pti_offer_rows,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
        AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

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
    o.avg_synthetic_estimated_pd_proxy,
    o.avg_requested_expected_loss_amount,
    o.avg_approved_expected_loss_all_apps,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate

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


/*-----------------------------------------------------------------------------------------------
14.8B Requested PTI affordability sensitivity status check.

Purpose:
    Compare approval rates in lower requested PTI buckets versus higher requested PTI buckets.

Status logic:
    REQUESTED_PTI_AFFORDABILITY_SENSITIVITY_DIRECTIONALLY_ALIGNED:
        High / severe requested PTI approval rate is less than or equal to low / moderate requested
        PTI approval rate.

    REQUESTED_PTI_AFFORDABILITY_SENSITIVITY_REVIEW_REQUIRED:
        High / severe requested PTI approval rate exceeds low / moderate requested PTI approval rate.

    NOT_APPLICABLE_INSUFFICIENT_PTI_BUCKET_DENSITY:
        One side of the comparison has no rows.

Interpretation:
    This is a directional diagnostic, not a hard acceptance rule.

    A REVIEW result should be explained through product mix, score mix, DTI, exposure, or reason-code
    patterns before documentation.
-----------------------------------------------------------------------------------------------*/

WITH affordability_rates AS (
    SELECT
        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS low_or_moderate_requested_pti_rows,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
        ) AS high_or_severe_requested_pti_rows,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
            ),
            0
        ) AS low_or_moderate_requested_pti_approval_rate,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
            ),
            0
        ) AS high_or_severe_requested_pti_approval_rate

    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    low_or_moderate_requested_pti_rows,
    high_or_severe_requested_pti_rows,
    low_or_moderate_requested_pti_approval_rate,
    high_or_severe_requested_pti_approval_rate,

    CASE
        WHEN low_or_moderate_requested_pti_rows = 0
          OR high_or_severe_requested_pti_rows = 0
            THEN 'NOT_APPLICABLE_INSUFFICIENT_PTI_BUCKET_DENSITY'

        WHEN high_or_severe_requested_pti_approval_rate
          <= low_or_moderate_requested_pti_approval_rate
            THEN 'REQUESTED_PTI_AFFORDABILITY_SENSITIVITY_DIRECTIONALLY_ALIGNED'

        ELSE 'REQUESTED_PTI_AFFORDABILITY_SENSITIVITY_REVIEW_REQUIRED'
    END AS requested_pti_affordability_sensitivity_status

FROM affordability_rates;


/*-----------------------------------------------------------------------------------------------
14.8C Counteroffer PTI improvement diagnostic.

Purpose:
    Confirm that final COUNTEROFFER rows generally improve affordability by reducing approved PTI
    below requested PTI.

Expected interpretation:
    Final COUNTEROFFER rows should generally show:
        approved_payment_to_income_ratio < requested_payment_to_income_ratio.

Review flag:
    counteroffer_rows_without_pti_improvement should ordinarily be zero.

Boundary:
    approved_payment_to_income_ratio is a strategy-simulation affordability proxy.

    It is not a contractual payment quote or production amortization result.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_rows,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_requested_pti_counteroffer_rows,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_counteroffer_rows,

    AVG(
        requested_payment_to_income_ratio - approved_payment_to_income_ratio
    ) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_pti_reduction_counteroffer_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND approved_payment_to_income_ratio >= requested_payment_to_income_ratio
    ) AS counteroffer_rows_without_pti_improvement

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.9 — DTI CAPACITY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that DTI capacity pressure affects simulated strategy routing in a directionally coherent
    way.

    Section 14.9 answers:

        "Does higher existing-obligation capacity pressure generally reduce approval likelihood and
         increase review or decline outcomes?"

SQL PURPOSE:
    1. Summarize final decision outcomes by dti_bucket.
    2. Calculate approval, counteroffer, manual-review, decline, and simulated offer-exposure rates
       by DTI bucket.
    3. Compare DTI, synthetic estimated-risk proxy, requested PTI, and requested Expected Loss by DTI
       bucket and final outcome.
    4. Review severe DTI decline-trigger routing.
    5. Produce a directional DTI capacity sensitivity status.

BUSINESS INTERPRETATION:
    Higher DTI should generally:
        reduce clean approval likelihood,
        increase manual review,
        increase decline routing,
        or interact with counteroffer / affordability treatment where appropriate.

DTI BOUNDARY:
    DTI reflects existing-obligation capacity.

    In Module 2 V1.0, DTI is not directly fixed by counteroffer because a counteroffer adjusts the
    requested exposure treatment, not the synthetic applicant's existing obligations.

WHY DTI IS REVIEWED SEPARATELY FROM REQUESTED PTI:
    requested_payment_to_income_ratio reflects the affordability burden of the requested structure.

    debt_to_income_ratio reflects existing-obligation capacity.

    Both can affect strategy outcomes, but they are distinct capacity signals and should not be
    collapsed into one metric.

BOUNDARY:
    Section 14.9 does not recalculate DTI.
    Section 14.9 does not adjust DTI through counteroffer exposure treatment.
    Section 14.9 does not create production affordability rules.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
14.9A DTI bucket × final decision outcome.

Purpose:
    Review how existing-obligation capacity pressure flows into final simulated outcomes.

Interpretation:
    Higher DTI buckets should generally show lower clean approval rates or higher review / decline
    outcomes.

    Exceptions should be explained through product mix, score band, requested PTI, requested exposure,
    and reason-code distributions.
-----------------------------------------------------------------------------------------------*/

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
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY dti_bucket
),

dti_outcome AS (
    SELECT
        dti_bucket,
        decision_outcome,

        COUNT(*) AS row_count,

        AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount

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
    o.avg_synthetic_estimated_pd_proxy,
    o.avg_requested_payment_to_income_ratio,
    o.avg_requested_expected_loss_amount,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate

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


/*-----------------------------------------------------------------------------------------------
14.9B DTI decline-trigger diagnostic.

Purpose:
    Review rows where the DTI decline trigger is active.

Interpretation:
    Rows with severe DTI triggers should route consistently with the accepted decision hierarchy.

    Severe DTI is treated as existing-obligation capacity pressure. It is not directly solved by
    reducing approved exposure.

Expected use:
    Confirm that dti_decline_trigger_flag = TRUE does not silently result in unexplained approvals.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_decline_trigger_flag,
    decision_outcome,
    decision_path,
    primary_reason_code,

    COUNT(*) AS row_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    dti_decline_trigger_flag,
    decision_outcome,
    decision_path,
    primary_reason_code

ORDER BY
    dti_decline_trigger_flag DESC,
    CASE decision_outcome
        WHEN 'DECLINE' THEN 1
        WHEN 'MANUAL_REVIEW' THEN 2
        WHEN 'COUNTEROFFER' THEN 3
        WHEN 'APPROVE' THEN 4
        ELSE 99
    END,
    decision_path,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
14.9C DTI sensitivity status check.

Purpose:
    Compare approval rates in lower DTI buckets versus higher DTI buckets.

Status logic:
    DTI_CAPACITY_SENSITIVITY_DIRECTIONALLY_ALIGNED:
        High / severe DTI approval rate is less than or equal to low / moderate DTI approval rate.

    DTI_CAPACITY_SENSITIVITY_REVIEW_REQUIRED:
        High / severe DTI approval rate exceeds low / moderate DTI approval rate.

    NOT_APPLICABLE_INSUFFICIENT_DTI_BUCKET_DENSITY:
        One side of the comparison has no rows.

Interpretation:
    This is a directional diagnostic, not a hard policy assertion.

    A REVIEW result should be interpreted alongside score mix, product mix, requested PTI, exposure,
    and reason-code concentration.
-----------------------------------------------------------------------------------------------*/

WITH dti_rates AS (
    SELECT
        COUNT(*) FILTER (
            WHERE dti_bucket IN ('LOW_DTI', 'MODERATE_DTI')
        ) AS low_or_moderate_dti_rows,

        COUNT(*) FILTER (
            WHERE dti_bucket IN ('HIGH_DTI', 'SEVERE_DTI')
        ) AS high_or_severe_dti_rows,

        COUNT(*) FILTER (
            WHERE dti_bucket IN ('LOW_DTI', 'MODERATE_DTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE dti_bucket IN ('LOW_DTI', 'MODERATE_DTI')
            ),
            0
        ) AS low_or_moderate_dti_approval_rate,

        COUNT(*) FILTER (
            WHERE dti_bucket IN ('HIGH_DTI', 'SEVERE_DTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE dti_bucket IN ('HIGH_DTI', 'SEVERE_DTI')
            ),
            0
        ) AS high_or_severe_dti_approval_rate

    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    low_or_moderate_dti_rows,
    high_or_severe_dti_rows,
    low_or_moderate_dti_approval_rate,
    high_or_severe_dti_approval_rate,

    CASE
        WHEN low_or_moderate_dti_rows = 0
          OR high_or_severe_dti_rows = 0
            THEN 'NOT_APPLICABLE_INSUFFICIENT_DTI_BUCKET_DENSITY'

        WHEN high_or_severe_dti_approval_rate <= low_or_moderate_dti_approval_rate
            THEN 'DTI_CAPACITY_SENSITIVITY_DIRECTIONALLY_ALIGNED'

        ELSE 'DTI_CAPACITY_SENSITIVITY_REVIEW_REQUIRED'
    END AS dti_capacity_sensitivity_status

FROM dti_rates;



/***************************************************************************************************
SECTION 14.10 — APPROVED EXPOSURE AND EXPECTED LOSS QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate final approved exposure, affordability, and approved Expected Loss conventions after
    final simulated decision resolution.

    Section 14.10 answers:

        "Do final approved amount, counteroffer amount, exposure reduction, approved PTI, and approved
         Expected Loss behave consistently with each final simulated strategy outcome?"

SQL PURPOSE:
    1. Summarize requested amount versus approved amount by final decision outcome.
    2. Summarize requested Expected Loss versus approved Expected Loss by final decision outcome.
    3. Review exposure reduction behavior for final COUNTEROFFER rows.
    4. Validate final approved exposure conventions by decision_outcome.
    5. Validate final approved Expected Loss conventions by decision_outcome.
    6. Summarize product-level requested versus approved exposure and Expected Loss.

BUSINESS INTERPRETATION:
    This section confirms that final approved exposure economics behave as designed:

        APPROVE:
            approved_amount = requested_amount.
            approved_expected_loss_amount = requested_expected_loss_amount.

        COUNTEROFFER:
            approved_amount is positive and lower than requested_amount.
            approved_expected_loss_amount should be reduced or at least not exceed requested-exposure
            Expected Loss under the accepted feasibility logic.

        MANUAL_REVIEW:
            approved exposure fields remain NULL because manual review is unresolved by design.

        DECLINE:
            approved exposure and approved Expected Loss are zero by convention.

WHY THIS SECTION MATTERS:
    Decision outcomes alone do not prove the strategy output is economically coherent.

    A final strategy output must also demonstrate that:
        positive offer-exposure outcomes carry valid approved exposure values,
        counteroffers truly reduce exposure,
        manual review remains unresolved,
        declines carry zero approved exposure,
        and approved Expected Loss follows approved-exposure treatment.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount:
        Module 2 approved-exposure Expected Loss after simulated exposure treatment.

    Section 14.10 validates the distinction but does not recalculate either value.

APPROVED PTI BOUNDARY:
    approved_payment_to_income_ratio is a Module 2 strategy-simulation affordability proxy.

    It is not a contractual payment ratio.
    It is not a servicing or billing output.
    It is not production affordability underwriting.

SIMULATED OFFER EXPOSURE BOUNDARY:
    Approved exposure metrics are simulated strategy outputs.

    They do not imply:
        operational account creation,
        funded exposure,
        booked exposure,
        production approval,
        or real applicant treatment.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
14.10A Final requested versus approved exposure and Expected Loss by decision outcome.

Purpose:
    Summarize how requested exposure and requested Expected Loss translate into approved exposure and
    approved Expected Loss after final strategy resolution.

Interpretation:
    APPROVE should preserve requested exposure and requested Expected Loss.

    COUNTEROFFER should show positive exposure reduction.

    MANUAL_REVIEW should remain unresolved.

    DECLINE should show zero approved exposure and zero approved Expected Loss.
-----------------------------------------------------------------------------------------------*/

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

    MIN(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS min_exposure_reduction_pct_for_counteroffers,

    MAX(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS max_exposure_reduction_pct_for_counteroffers,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows,

    AVG(approved_el_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_el_reduction_pct_for_counteroffers

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
14.10B Final approved exposure convention validation.

Purpose:
    Provide compact violation counts for final approved exposure conventions.

Expected result:
    all violation counts should be zero.

Validation conventions:
    APPROVE:
        approved_amount should equal requested_amount.

    COUNTEROFFER:
        approved_amount should be positive, below requested_amount, equal to counteroffer_amount, and
        should have positive exposure reduction.

    MANUAL_REVIEW:
        approved_amount, counteroffer_amount, exposure_reduction_amount, and exposure_reduction_pct
        should remain NULL.

    DECLINE:
        approved_amount should equal zero, counteroffer_amount should be NULL, exposure reduction
        amount should equal requested_amount, and exposure reduction percent should equal 1.0.

Boundary:
    This query validates output conventions. It does not recalculate exposure treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_amount IS DISTINCT FROM requested_amount
    ) AS approve_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
             OR exposure_reduction_flag IS DISTINCT FROM TRUE
             OR exposure_reduction_amount IS NULL
             OR exposure_reduction_amount <= 0
             OR exposure_reduction_pct IS NULL
             OR exposure_reduction_pct <= 0
          )
    ) AS counteroffer_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND (
                approved_amount IS NOT NULL
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_amount IS NOT NULL
             OR exposure_reduction_pct IS NOT NULL
          )
    ) AS manual_review_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND (
                approved_amount IS DISTINCT FROM 0::NUMERIC
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_amount IS DISTINCT FROM requested_amount
             OR exposure_reduction_pct IS DISTINCT FROM 1.0::NUMERIC
          )
    ) AS decline_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE approved_amount IS NOT NULL
          AND approved_amount < 0
    ) AS negative_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount IS NOT NULL
          AND approved_amount > requested_amount
    ) AS approved_amount_above_requested_amount_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.10C Final approved Expected Loss convention validation.

Purpose:
    Provide compact violation counts for approved Expected Loss conventions.

Expected result:
    all violation counts should be zero.

Validation conventions:
    APPROVE:
        approved_expected_loss_amount should equal requested_expected_loss_amount.

    COUNTEROFFER:
        approved_expected_loss_amount should be populated, non-negative, and less than or equal to
        requested_expected_loss_amount.

    MANUAL_REVIEW:
        approved_expected_loss_amount, approved_el_reduction_amount, and approved_el_reduction_pct
        should remain NULL because the outcome is unresolved.

    DECLINE:
        approved_expected_loss_amount should equal zero, approved_el_reduction_amount should equal
        requested_expected_loss_amount, and approved_el_reduction_pct should follow the locked
        decline convention.

Boundary:
    This query validates output conventions. It does not recalculate approved Expected Loss.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
    ) AS approve_approved_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount < 0
             OR approved_expected_loss_amount > requested_expected_loss_amount
          )
    ) AS counteroffer_approved_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND (
                approved_expected_loss_amount IS NOT NULL
             OR approved_el_reduction_amount IS NOT NULL
             OR approved_el_reduction_pct IS NOT NULL
          )
    ) AS manual_review_approved_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND (
                approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
             OR approved_el_reduction_amount IS DISTINCT FROM requested_expected_loss_amount
             OR approved_el_reduction_pct IS DISTINCT FROM
                CASE
                    WHEN requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END
          )
    ) AS decline_approved_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount IS NOT NULL
          AND approved_expected_loss_amount < 0
    ) AS negative_approved_expected_loss_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.10D Product-level requested versus approved exposure and Expected Loss profile.

Purpose:
    Identify which products contribute most to simulated approved exposure and approved Expected Loss
    after Module 2 final exposure treatment.

Interpretation:
    Use this query to explain product-level contribution to:
        total requested exposure,
        total approved exposure,
        total requested Expected Loss,
        total approved Expected Loss,
        and simulated offer-exposure rate.

Documentation use:
    Strong candidate for executive storylines because it connects product mix to exposure and
    approved Expected Loss outcomes.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,

    COUNT(*) AS applications,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY product_type_policy_key

ORDER BY product_type_policy_key;



/***************************************************************************************************
END OF SECTION 14.10 — APPROVED EXPOSURE AND EXPECTED LOSS QA

This partial Section 14 chunk has established:
    1. Product × score segment validation.
    2. Product × score final outcome concentration review.
    3. Product × score simulated reason-code explainability review.
    4. Synthetic estimated-risk tier outcome distribution review.
    5. Synthetic estimated-risk ordering status review.
    6. Requested PTI affordability sensitivity review.
    7. Counteroffer PTI improvement diagnostic.
    8. DTI capacity sensitivity review.
    9. DTI decline-trigger routing diagnostic.
    10. Final approved exposure convention validation.
    11. Final approved Expected Loss convention validation.
    12. Product-level requested versus approved exposure / Expected Loss profile.
    13. Continued interpretation of estimated_pd as the synthetic estimated-PD proxy.
    14. Continued distinction between requested-exposure Expected Loss and approved-exposure Expected
        Loss.
    15. Continued simulated offer-exposure boundary discipline.
    16. Continued simulated reason-code boundary discipline.

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
```
<!-- END_MESSAGE C038-M00773 -->


---

<a id="c038-m00775"></a>

### C038-M00775

**Andrew** · 2026-05-09T18:22:00.215000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00775 -->
do the same for sections 14.11 - 14.15:
<!-- END_MESSAGE C038-M00775 -->


**Attachments in export:** `Pasted text(127).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_31.md) · [Next](Part_33.md)
