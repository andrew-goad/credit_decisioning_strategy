# Module 2 Decision Simulator Build

## Part 84

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_83.md) · [Next](Part_85.md)

<a id="c038-m01608"></a>

### C038-M01608

**ChatGPT** · 2026-05-12T12:23:39.357920-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01608 -->
I’m treating Section 14 as the read-only latest-run validation layer, with compatibility alignment to the Section 13 comparison helpers and Section 16 evidence capture. The current canonical direction is that Section 14 validates `credit_decisioning_sim.strategy_decisions`, references archive/comparison context only as readiness evidence, and materializes `tmp_m2_validation_status_summary` for downstream evidence capture. fileciteturn253file20 Section 13 now provides `tmp_m2_strategy_comparison_readiness` and `tmp_m2_strategy_comparison_source_consistency`, and Section 16 depends on `tmp_m2_validation_status_summary` for persistent validation evidence. fileciteturn253file22 fileciteturn253file11

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

    Section 14 also creates the validation evidence foundation for later:
        validation-summary drafting,
        executive evidence capture,
        README interpretation,
        LinkedIn result storytelling,
        controlled campaign-run documentation,
        and future Module 3 economics planning.

SQL PURPOSE:
    1. Validate credit_decisioning_sim.strategy_decisions as the primary latest-run output.
    2. Preserve a read-only boundary over latest-run and archive data.
    3. Validate latest-run structural integrity, row grain, strategy scope, and Module 1 lineage.
    4. Validate final outcome completeness, final flag reconciliation, simulated offer-exposure
       convention, exposure convention, affordability convention, Expected Loss convention, and
       simulated reason-code convention.
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
            reason-code coverage,
            mixed-signal cases,
            borderline cases,
            archive readiness,
            matched strategy comparison readiness,
            and matched source-field consistency.
    6. Materialize tmp_m2_validation_status_summary as the compact validation-evidence spine consumed
       by Section 16.
    7. Keep full documentation drafting outside SQL execution.

PRIMARY VALIDATION TARGET:
    credit_decisioning_sim.strategy_decisions

SUPPORTING CONTEXT OBJECTS:
    credit_decisioning_sim.strategy_decisions_archive
        Used only for archive-readiness context.

    tmp_m2_strategy_comparison_readiness
        Optional Section 13 comparison-readiness helper.

    tmp_m2_strategy_comparison_source_consistency
        Optional Section 13 matched source-field consistency helper.

TEMPORARY OUTPUT CREATED:
    tmp_m2_validation_status_summary

TEMPORARY CONTEXT HELPERS CREATED:
    tmp_m2_validation_archive_readiness_context
    tmp_m2_validation_comparison_readiness_context
    tmp_m2_validation_source_consistency_context

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

RELATIONSHIP TO SECTION 13:
    Section 13 provides archive-backed matched strategy comparison readiness and source-field
    consistency diagnostics.

    Section 14 consumes those diagnostics when they exist.

    If Section 13 has not been run, Section 14 does not fail solely for that reason. Instead, it
    records matched comparison readiness as NOT_APPLICABLE in tmp_m2_validation_status_summary.

RELATIONSHIP TO SECTION 16:
    Section 16 persists validation evidence by reading tmp_m2_validation_status_summary.

    Section 14 therefore materializes a compact validation status table near the end of the section.

VALIDATION STATUS SUMMARY PRINCIPLE:
    tmp_m2_validation_status_summary uses:

        PASS
        REVIEW
        NOT_APPLICABLE

    PASS:
        The validation expectation was satisfied.

    REVIEW:
        The pattern may be acceptable, but should be interpreted before documentation.

        REVIEW does not automatically mean the strategy output is invalid.

    NOT_APPLICABLE:
        The test depends on unavailable archive slices, unavailable comparison helpers, or a non-ready
        matched comparison setup.

    Section 14 intentionally avoids FAIL for ordinary diagnostic patterns because critical structural
    failures are handled earlier through fail-fast gatekeepers and Section 11 output conventions.

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
        Module 2 approved-exposure Expected Loss after simulated final exposure treatment.

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
        validation documentation,
        README interpretation,
        and LinkedIn storyline development.

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
    source-field consistency evidence should be available for the validation status summary.

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
SECTION 14.0 — VALIDATION DEPENDENCY PREFLIGHT AND OPTIONAL CONTEXT HELPERS
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the latest-run table exists and prepare optional archive / comparison context for
    validation evidence.

    Section 14.0 answers:

        "Can Section 14 safely validate the completed latest-run output, and what optional archive or
         matched-comparison context is available?"

SQL PURPOSE:
    1. Confirm credit_decisioning_sim.strategy_decisions exists.
    2. Confirm the latest-run table contains rows.
    3. Reset Section 14 temporary helper objects.
    4. Materialize archive-readiness context safely.
    5. Materialize matched-comparison readiness context safely.
    6. Materialize matched source-field consistency context safely.

COMPATIBILITY DESIGN:
    Section 14 can be run whether or not Section 13 was executed.

    If Section 13 helper tables do not exist, Section 14 records comparison and source-consistency
    evidence as NOT_APPLICABLE rather than failing.

BOUNDARY:
    This section creates temporary helper objects only.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not recalculate strategy outputs.

***************************************************************************************************/

DO $$
DECLARE
    v_latest_run_exists BOOLEAN;
    v_latest_run_row_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must exist.

    Section 14 validates the latest-run output created by Section 11.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO v_latest_run_exists;

    IF v_latest_run_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 14 failure: credit_decisioning_sim.strategy_decisions does not exist. Run Section 11 before Section 14.';
    END IF;

    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must contain rows.

    An empty latest-run output cannot support validation evidence.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_run_row_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_run_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 14 failure: credit_decisioning_sim.strategy_decisions contains zero rows.';
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
14.0A Reset Section 14 temporary helper outputs.

Purpose:
    Remove prior validation helper objects so current validation evidence reflects the current
    latest-run and current optional Section 13 context.

Boundary:
    These are temporary objects only.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_validation_archive_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_comparison_readiness_context;
DROP TABLE IF EXISTS tmp_m2_validation_source_consistency_context;
DROP TABLE IF EXISTS tmp_m2_validation_status_summary;



/*-----------------------------------------------------------------------------------------------
14.0B Archive-readiness context helper.

Purpose:
    Determine whether the current latest-run slice is present in the archive.

Interpretation:
    If archive table exists and current latest-run slice is archived at matching row count, archive
    readiness should be PASS in the validation status summary.

    If the archive table does not exist or current slice is missing, this is usually REVIEW or
    NOT_APPLICABLE depending on intended workflow.
-----------------------------------------------------------------------------------------------*/

CREATE TEMP TABLE tmp_m2_validation_archive_readiness_context (
    archive_table_exists                                    BOOLEAN,
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

DO $$
BEGIN
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NULL THEN
        INSERT INTO tmp_m2_validation_archive_readiness_context (
            archive_table_exists,
            latest_run_rows,
            latest_run_distinct_application_id_count,
            current_archived_slice_rows,
            current_archived_slice_distinct_application_id_count,
            current_archived_slice_null_archive_ts_rows,
            archive_readiness_status
        )
        SELECT
            FALSE AS archive_table_exists,
            COUNT(*) AS latest_run_rows,
            COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count,
            0::BIGINT AS current_archived_slice_rows,
            0::BIGINT AS current_archived_slice_distinct_application_id_count,
            0::BIGINT AS current_archived_slice_null_archive_ts_rows,
            'NOT_APPLICABLE_ARCHIVE_TABLE_NOT_AVAILABLE' AS archive_readiness_status
        FROM credit_decisioning_sim.strategy_decisions;

    ELSE
        INSERT INTO tmp_m2_validation_archive_readiness_context (
            archive_table_exists,
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
        )
        WITH latest_key AS (
            SELECT
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id,
                COUNT(*) AS latest_run_rows,
                COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count
            FROM credit_decisioning_sim.strategy_decisions
            GROUP BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        )

        SELECT
            TRUE AS archive_table_exists,

            k.strategy_set_name,
            k.strategy_name,
            k.strategy_version,
            k.module1_scenario_set_name,
            k.module1_scenario_name,
            k.population_id,

            k.latest_run_rows,
            k.latest_run_distinct_application_id_count,

            COUNT(ar.application_id) AS current_archived_slice_rows,
            COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count,
            COUNT(ar.application_id) FILTER (WHERE ar.archive_inserted_ts IS NULL)
                AS current_archived_slice_null_archive_ts_rows,

            CASE
                WHEN COUNT(ar.application_id) = 0
                    THEN 'REVIEW_CURRENT_LATEST_RUN_SLICE_NOT_ARCHIVED'

                WHEN COUNT(ar.application_id) <> k.latest_run_rows
                    THEN 'REVIEW_ARCHIVED_CURRENT_SLICE_ROW_COUNT_MISMATCH'

                WHEN COUNT(DISTINCT ar.application_id) <> COUNT(ar.application_id)
                    THEN 'REVIEW_ARCHIVED_CURRENT_SLICE_DUPLICATE_APPLICATION_ID'

                WHEN COUNT(ar.application_id) FILTER (WHERE ar.archive_inserted_ts IS NULL) > 0
                    THEN 'REVIEW_ARCHIVED_CURRENT_SLICE_NULL_ARCHIVE_TS'

                ELSE 'CURRENT_LATEST_RUN_SLICE_ARCHIVED'
            END AS archive_readiness_status

        FROM latest_key k

        LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
            ON ar.strategy_set_name = k.strategy_set_name
           AND ar.strategy_name = k.strategy_name
           AND ar.strategy_version = k.strategy_version
           AND ar.module1_scenario_set_name = k.module1_scenario_set_name
           AND ar.module1_scenario_name = k.module1_scenario_name
           AND ar.population_id = k.population_id

        GROUP BY
            k.strategy_set_name,
            k.strategy_name,
            k.strategy_version,
            k.module1_scenario_set_name,
            k.module1_scenario_name,
            k.population_id,
            k.latest_run_rows,
            k.latest_run_distinct_application_id_count;
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
14.0C Matched-comparison readiness context helper.

Purpose:
    Copy Section 13 comparison-readiness output when available, or create a NOT_APPLICABLE
    placeholder when Section 13 has not been run.

Boundary:
    This object is temporary validation context only.
-----------------------------------------------------------------------------------------------*/

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

DO $$
BEGIN
    IF COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_comparison_readiness'),
        TO_REGCLASS('tmp_m2_strategy_comparison_readiness')
    ) IS NOT NULL THEN

        INSERT INTO tmp_m2_validation_comparison_readiness_context (
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
        )
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
        FROM tmp_m2_strategy_comparison_readiness
        LIMIT 1;

    ELSE
        INSERT INTO tmp_m2_validation_comparison_readiness_context (
            readiness_status,
            expected_comparison_storyline,
            primary_metric_focus
        )
        VALUES (
            'NOT_APPLICABLE_SECTION_13_COMPARISON_READINESS_NOT_AVAILABLE',
            'Section 13 comparison readiness helper was not available during Section 14.',
            'NOT_APPLICABLE'
        );
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
14.0D Matched source-field consistency context helper.

Purpose:
    Copy Section 13 source-consistency output when available, or create a NOT_APPLICABLE placeholder
    when Section 13 has not been run.

Boundary:
    This object is temporary validation context only.
-----------------------------------------------------------------------------------------------*/

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

DO $$
BEGIN
    IF COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_comparison_source_consistency'),
        TO_REGCLASS('tmp_m2_strategy_comparison_source_consistency')
    ) IS NOT NULL THEN

        INSERT INTO tmp_m2_validation_source_consistency_context (
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
        )
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
        FROM tmp_m2_strategy_comparison_source_consistency
        LIMIT 1;

    ELSE
        INSERT INTO tmp_m2_validation_source_consistency_context (
            readiness_status,
            matched_application_count,
            source_field_mismatch_count,
            source_consistency_status
        )
        VALUES (
            'NOT_APPLICABLE_SECTION_13_SOURCE_CONSISTENCY_NOT_AVAILABLE',
            0,
            0,
            'NOT_APPLICABLE_SECTION_13_SOURCE_CONSISTENCY_NOT_AVAILABLE'
        );
    END IF;
END $$;



/***************************************************************************************************
SECTION 14.1 — VALIDATION SCOPE AND BOUNDARY
****************************************************************************************************

BUSINESS PURPOSE:
    Establish the latest-run validation scope before interpreting detailed QA diagnostics.

    Section 14.1 answers:

        "Exactly what strategy / Module 1 scenario / population slice is being validated?"

SQL PURPOSE:
    1. Count latest-run rows.
    2. Confirm application_id row grain.
    3. Confirm single-strategy latest-run scope.
    4. Confirm single Module 1 scenario / population latest-run scope.
    5. Show latest-run timestamp metadata.
    6. Produce compact validation_scope_status.

EXPECTED RESULT:
    validation_scope_status should ordinarily equal:

        LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW

BOUNDARY:
    This is validation scope evidence.

    It does not modify data.

****************************************************************************************************/

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

BUSINESS PURPOSE:
    Confirm that the latest-run strategy_decisions table is populated, unique at application_id, and
    complete across required strategy, lineage, decision, reason-code, and risk-economics fields.

    Section 14.2 answers:

        "Is the latest-run output structurally sound enough to interpret?"

SQL PURPOSE:
    1. Confirm total row count.
    2. Confirm application_id uniqueness.
    3. Confirm single strategy version.
    4. Confirm single Module 1 scenario / population slice.
    5. Identify missing required lineage fields.
    6. Identify missing required final outcome fields.
    7. Identify missing required simulated reason-code fields.
    8. Identify missing requested and approved Expected Loss fields.

EXPECTED INTERPRETATION:
    total_rows should equal distinct_application_id_count.

    duplicate_application_row_count should equal zero.

    distinct_strategy_version_count should equal one.

    distinct_module1_scenario_population_count should equal one.

    Missing core field counts should equal zero.

***************************************************************************************************/

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

    COUNT(*) FILTER (WHERE application_id IS NULL)
        AS null_application_id_rows,

    COUNT(*) FILTER (WHERE applicant_id IS NULL)
        AS null_applicant_id_rows,

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

    COUNT(*) FILTER (WHERE decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE'))
        AS invalid_decision_outcome_rows,

    COUNT(*) FILTER (WHERE primary_reason_code IS NULL)
        AS null_primary_reason_code_rows,

    COUNT(*) FILTER (WHERE primary_reason_family IS NULL)
        AS null_primary_reason_family_rows,

    COUNT(*) FILTER (WHERE triggered_reason_code_list IS NULL)
        AS null_triggered_reason_code_list_rows,

    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL)
        AS null_requested_expected_loss_amount_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
          AND approved_expected_loss_amount IS NULL
    ) AS null_required_approved_expected_loss_rows,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.2A Row count by Module 1 input source.

Purpose:
    Confirm whether the current latest-run output came from Module 1 latest-run or Module 1 archive
    source mode.

Interpretation:
    Formal campaign runs generally use ARCHIVE source mode to preserve the exact Module 1 scenario
    slice used for comparison.
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
14.2B Duplicate application diagnostic.

Expected result:
    zero rows.

If any rows appear, the latest-run table is not unique at application_id and downstream
application-level QA should not be interpreted until corrected.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,
    COUNT(*) AS duplicate_application_row_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY application_id

HAVING COUNT(*) > 1

ORDER BY duplicate_application_row_count DESC, application_id

LIMIT 100;



/***************************************************************************************************
SECTION 14.3 — FINAL DECISION DISTRIBUTION AND FLAG RECONCILIATION
****************************************************************************************************

BUSINESS PURPOSE:
    Validate the final simulated decision distribution and ensure the final Boolean decision flags
    reconcile to decision_outcome.

    Section 14.3 answers:

        "What did the strategy decide, and do the outcome flags agree with that final decision?"

SQL PURPOSE:
    1. Summarize final decision distribution.
    2. Summarize final decision paths and resolution sources.
    3. Check final flag reconciliation.
    4. Check simulated_offer_exposure_flag reconciliation.

BOUNDARY:
    These are simulated strategy outcomes, not real applicant decisions.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.3A Final decision_outcome distribution.

Purpose:
    Show high-level strategy outcome mix.

Interpretation:
    This is the first business-facing distribution, but it is not enough by itself to validate the
    strategy. Later sections review segment behavior, exposure, Expected Loss, counteroffers, reason
    codes, and edge cases.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount

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
14.3B Decision path and resolution source distribution.

Purpose:
    Review how final outcomes were resolved.

Interpretation:
    decision_path and decision_resolution_source help explain whether outcomes came from clean
    approval, feasible counteroffer, failed counteroffer resolution, preliminary manual review, or
    preliminary decline routing.

Boundary:
    These are internal simulated strategy path labels, not customer communication language.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,
    decision_path,
    decision_resolution_source,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_latest_run

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    decision_outcome,
    decision_path,
    decision_resolution_source

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    decision_path,
    decision_resolution_source;



/*-----------------------------------------------------------------------------------------------
14.3C Final flag reconciliation diagnostic.

Purpose:
    Confirm exactly one final outcome flag is TRUE per row and that each flag maps to
    decision_outcome.

Expected:
    all violation counts = 0.
-----------------------------------------------------------------------------------------------*/

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
        WHERE approval_flag IS DISTINCT FROM (decision_outcome = 'APPROVE')
    ) AS approval_flag_reconciliation_violation_rows,

    COUNT(*) FILTER (
        WHERE counteroffer_flag IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
    ) AS counteroffer_flag_reconciliation_violation_rows,

    COUNT(*) FILTER (
        WHERE manual_review_flag IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
    ) AS manual_review_flag_reconciliation_violation_rows,

    COUNT(*) FILTER (
        WHERE decline_flag IS DISTINCT FROM (decision_outcome = 'DECLINE')
    ) AS decline_flag_reconciliation_violation_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag
              IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
    ) AS simulated_offer_exposure_flag_reconciliation_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.4 — PRODUCT-LEVEL STRATEGY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Evaluate whether final simulated strategy outcomes, approved exposure, requested Expected Loss,
    approved Expected Loss, and reason-code patterns behave coherently across products.

    Section 14.4 answers:

        "How does the strategy behave by product, and is that behavior explainable through product
         structure and product-policy controls?"

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

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.4A Product × decision_outcome distribution.
-----------------------------------------------------------------------------------------------*/

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
14.4B Product-level decision-rate summary.

Purpose:
    Provide one compact row per product for executive and validation review.

Interpretation:
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

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_count,

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

    SUM(COALESCE(approved_amount, 0))
        / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        / NULLIF(SUM(COALESCE(approved_amount, 0)), 0) AS approved_expected_loss_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY product_type_policy_key

ORDER BY product_type_policy_key;



/*-----------------------------------------------------------------------------------------------
14.4C Product-level primary reason-code distribution.

Purpose:
    Review whether product-level behavior is explained by the expected simulated reason-code themes.

Boundary:
    Reason codes are simulated strategy explanation codes, not customer communications.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY product_type_policy_key), 0),
        2
    ) AS pct_within_product,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    primary_reason_family,
    primary_reason_code

ORDER BY
    product_type_policy_key,
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.5 — SCORE-BAND STRATEGY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Evaluate whether final simulated strategy outcomes behave coherently by borrower-quality segment.

    Section 14.5 answers:

        "Does the strategy generally provide more favorable simulated outcomes to stronger score
         bands while preserving realistic overlap?"

SQL PURPOSE:
    1. Summarize final decision outcomes by score band.
    2. Calculate score-band decision rates.
    3. Compare synthetic estimated-risk proxy, requested PTI, requested Expected Loss, approved
       exposure, and approved Expected Loss by score band.
    4. Review score-band reason-code patterns.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.5A Score band × final decision outcome.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY score_band_policy_key), 0),
        2
    ) AS pct_within_score_band,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

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
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
14.5B Score-band decision-rate summary.

Interpretation:
    Stronger score bands should generally show higher approval / offer-exposure rates and lower
    decline rates, although product mix, exposure, DTI, PTI, and policy constraints can create
    realistic overlap.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,

    COUNT(*) AS applications,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

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



/***************************************************************************************************
SECTION 14.6 — PRODUCT × SCORE DECISION MATRIX
****************************************************************************************************

BUSINESS PURPOSE:
    Show where simulated strategy outcomes concentrate across product and borrower-quality segments.

    Section 14.6 answers:

        "Which product × score intersections drive decision outcomes, exposure, and approved Expected
         Loss?"

SQL PURPOSE:
    1. Summarize applications by product × score band.
    2. Calculate final decision rates by product × score.
    3. Calculate simulated offer-exposure rates by product × score.
    4. Compare requested exposure, approved exposure, requested Expected Loss, and approved Expected
       Loss by product × score.
    5. Expand the matrix by final decision outcome.

WHY PRODUCT × SCORE MATTERS:
    Portfolio-level averages can hide important concentration.

    Product × score analysis helps identify whether:
        weaker-score unsecured segments drive approved Expected Loss,
        stronger-score secured segments drive approved amount,
        revolving segments drive counteroffer behavior,
        or product guardrails concentrate decline / review outcomes.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.6A Product × score-band summary.
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

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_count,
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
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount

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
    Identify whether a given product × score segment is dominated by one simulated strategy path.
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
    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
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



/***************************************************************************************************
SECTION 14.7 — SYNTHETIC RISK ORDERING QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that synthetic estimated-risk segmentation flows coherently into final simulated strategy
    outcomes.

    Section 14.7 answers:

        "Does the strategy generally offer more favorable outcomes to lower synthetic-risk tiers and
         route higher synthetic-risk tiers toward counteroffer, manual review, or decline in a
         directionally coherent way?"

SQL PURPOSE:
    1. Summarize final decision outcomes by strategy_risk_tier.
    2. Calculate approval, counteroffer, manual-review, decline, and simulated offer-exposure rates by
       synthetic risk tier.
    3. Compare requested PTI, requested Expected Loss, and approved Expected Loss by risk tier.
    4. Compare average synthetic estimated-risk proxy between simulated offer rows and declined rows.
    5. Produce directional synthetic-risk-ordering diagnostics.

WHY PERFECT MONOTONICITY IS NOT REQUIRED:
    Product mix, requested exposure, DTI, requested PTI, behavioral signals, product guardrails, and
    counteroffer feasibility can create realistic overlap.

    The validation expectation is broad directional coherence, not rigid deterministic sorting.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.7A Synthetic risk tier × final decision outcome.
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
14.7B Offer versus decline synthetic estimated-risk profile.

Purpose:
    Confirm declined rows generally have higher synthetic estimated-risk proxy than simulated
    positive offer-exposure rows.

Expected:
    avg_synthetic_estimated_pd_proxy_decline_rows should generally be >= offer-row average.

Boundary:
    This is directional QA. It is not model calibration.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_rows,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
        AS decline_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_synthetic_estimated_pd_proxy_decline_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
        - AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS decline_minus_offer_avg_synthetic_estimated_pd_proxy,

    CASE
        WHEN COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) = 0
          OR COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') = 0
            THEN 'NOT_APPLICABLE_OFFER_OR_DECLINE_ROWS_MISSING'

        WHEN AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
           >= AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            THEN 'SYNTHETIC_RISK_DIRECTIONALLY_COHERENT'

        ELSE 'REVIEW_SYNTHETIC_RISK_DIRECTIONAL_ORDERING'
    END AS synthetic_risk_directional_status

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.8 — REQUESTED PTI AFFORDABILITY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that requested payment burden and approved payment burden behave coherently across final
    simulated outcomes.

    Section 14.8 answers:

        "Does the strategy respond to requested affordability stress and reduce approved PTI when
         counteroffer treatment is used?"

SQL PURPOSE:
    1. Summarize final outcomes by requested_pti_bucket.
    2. Compare requested PTI and approved PTI by outcome.
    3. Confirm counteroffer rows reduce PTI where applicable.

BOUNDARY:
    requested_payment_to_income_ratio is requested-structure PTI.

    approved_payment_to_income_ratio is a final approved-exposure strategy-simulation affordability
    proxy.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.8A Requested PTI bucket × final decision outcome.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY requested_pti_bucket), 0),
        2
    ) AS pct_within_requested_pti_bucket,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps

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
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
14.8B Requested versus approved PTI by final outcome.

Expected:
    APPROVE:
        approved PTI should equal requested PTI.

    COUNTEROFFER:
        approved PTI should be below requested PTI and at or below counteroffer_target_pti.

    MANUAL_REVIEW:
        approved PTI should remain NULL.

    DECLINE:
        approved PTI should be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio)
        AS avg_approved_payment_to_income_ratio,

    AVG(
        requested_payment_to_income_ratio - approved_payment_to_income_ratio
    ) FILTER (
        WHERE approved_payment_to_income_ratio IS NOT NULL
    ) AS avg_pti_reduction_where_approved_pti_exists,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND approved_payment_to_income_ratio <= counteroffer_target_pti
    ) AS counteroffer_rows_at_or_below_target_pti,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND approved_payment_to_income_ratio > counteroffer_target_pti
    ) AS counteroffer_rows_above_target_pti

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
SECTION 14.9 — DTI CAPACITY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that DTI capacity pressure is visible and directionally coherent in final outcomes.

    Section 14.9 answers:

        "Does severe existing-obligation capacity pressure flow into review or decline behavior as
         intended?"

SQL PURPOSE:
    1. Summarize final outcomes by dti_bucket.
    2. Review DTI decline trigger behavior.
    3. Confirm severe DTI rows are not silently treated as ordinary clean approvals.

BOUNDARY:
    DTI is an existing-obligation capacity signal.

    In Module 2 V1.0, DTI is not directly counteroffer-adjustable because a counteroffer changes
    requested exposure treatment, not the applicant's existing obligations.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.9A DTI bucket × final decision outcome.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_bucket,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY dti_bucket), 0),
        2
    ) AS pct_within_dti_bucket,

    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    dti_bucket,
    decision_outcome

ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
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
14.9B DTI decline trigger behavior.

Purpose:
    Confirm severe DTI trigger rows resolve as high-priority capacity concerns.

Expected:
    dti_decline_trigger_flag = TRUE should generally resolve to DECLINE unless already captured by
    an equivalent higher-priority route. If any are non-decline, review the decision paths.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_decline_trigger_flag,
    decision_outcome,
    decision_path,

    COUNT(*) AS row_count,

    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    dti_decline_trigger_flag,
    decision_outcome,
    decision_path

ORDER BY
    dti_decline_trigger_flag DESC,
    CASE decision_outcome
        WHEN 'DECLINE' THEN 1
        WHEN 'MANUAL_REVIEW' THEN 2
        WHEN 'COUNTEROFFER' THEN 3
        WHEN 'APPROVE' THEN 4
        ELSE 99
    END,
    decision_path;



/***************************************************************************************************
SECTION 14.10 — REQUESTED VERSUS APPROVED EXPOSURE AND EXPECTED LOSS QA
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that final approved exposure and approved Expected Loss behave according to the final
    simulated outcome conventions.

    Section 14.10 answers:

        "How did the strategy convert requested exposure and requested Expected Loss into approved
         exposure and approved Expected Loss?"

SQL PURPOSE:
    1. Compare requested amount and approved amount by final outcome.
    2. Compare requested Expected Loss and approved Expected Loss by final outcome.
    3. Review requested exposure tier behavior.
    4. Review requested Expected Loss tier behavior.
    5. Review approved amount capture and approved Expected Loss rate.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.10A Requested versus approved exposure by final decision outcome.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    SUM(COALESCE(approved_amount, 0))
        / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

    AVG(exposure_reduction_amount) AS avg_exposure_reduction_amount,
    AVG(exposure_reduction_pct) AS avg_exposure_reduction_pct

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
14.10B Requested versus approved Expected Loss by final decision outcome.

Boundary:
    approved_expected_loss_amount is a synthetic strategy simulation metric, not a production loss
    forecast.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_expected_loss_amount,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
        AS approved_expected_loss_rate,

    AVG(approved_el_reduction_amount) AS avg_approved_el_reduction_amount,
    AVG(approved_el_reduction_pct) AS avg_approved_el_reduction_pct

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
14.10C Requested exposure tier × final decision outcome.

Purpose:
    Review how requested exposure intensity flows into final outcomes.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_exposure_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(exposure_reduction_pct) AS avg_exposure_reduction_pct,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    requested_exposure_tier,
    decision_outcome

ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'LOW_REQUESTED_EXPOSURE' THEN 2
        WHEN 'WITHIN_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'WITHIN_PRODUCT_LIMITS' THEN 4
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 5
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 6
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
14.10D Requested Expected Loss tier × final decision outcome.

Purpose:
    Review how requested-exposure Expected Loss pressure flows into final outcomes.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_expected_loss_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
    AVG(approved_el_reduction_pct) AS avg_approved_el_reduction_pct,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    requested_expected_loss_tier,
    decision_outcome

ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.11 — COUNTEROFFER VALIDATION DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that final COUNTEROFFER outcomes are feasible, explainable, and consistent with the
    governed exposure-treatment framework.

    Section 14.11 answers:

        "When Module 2 assigns a final COUNTEROFFER outcome, did the row pass reduced-exposure
         feasibility testing, and does the final exposure treatment behave as intended?"

SQL PURPOSE:
    1. Summarize preliminary and final counteroffer populations.
    2. Calculate counteroffer feasibility pass / fail rates.
    3. Review final counteroffer exposure reduction, requested PTI, approved PTI, requested Expected
       Loss, approved Expected Loss, and approved Expected Loss reduction.
    4. Review failed preliminary counteroffer reasons.
    5. Review counteroffer feasibility by product and score band.
    6. Validate final counteroffer conventions.
    7. Review final COUNTEROFFER simulated reason-code distribution.

BUSINESS INTERPRETATION:
    Final COUNTEROFFER rows should show:
        approved_amount < requested_amount;
        exposure_reduction_pct > 0;
        counteroffer_amount = approved_amount;
        approved_payment_to_income_ratio <= counteroffer_target_pti;
        approved_expected_loss_amount <= product_approved_el_cap;
        counteroffer_feasibility_pass_flag = TRUE;
        primary_reason_family = COUNTEROFFER.

COUNTEROFFER OUTCOME BOUNDARY:
    COUNTEROFFER is a simulated positive offer-exposure outcome for synthetic applicants.

    It does not imply:
        operational negotiation,
        booked exposure,
        funded exposure,
        production approval,
        operational account creation,
        customer communication,
        or real applicant treatment.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.11A Counteroffer summary.

Purpose:
    Provide the primary counteroffer performance and feasibility profile for the latest-run output.

Documentation use:
    This is the headline counteroffer QA table. It supports explanation of how many rows were
    counteroffer candidates, how many became feasible counteroffers, and what affordability / Expected
    Loss improvement was achieved.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS final_counteroffer_rows,

    COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER')
        AS preliminary_counteroffer_rows,

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
    / NULLIF(
        COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER'),
        0
    ) AS counteroffer_feasibility_pass_rate,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_final_counteroffers,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_requested_pti_for_final_counteroffers,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_for_final_counteroffers,

    AVG(
        requested_payment_to_income_ratio - approved_payment_to_income_ratio
    ) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_pti_reduction_for_final_counteroffers,

    AVG(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_requested_expected_loss_for_final_counteroffers,

    AVG(approved_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_expected_loss_for_final_counteroffers,

    AVG(approved_el_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_el_reduction_pct_for_final_counteroffers

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.11B Counteroffer feasibility failure reason distribution.

Purpose:
    Show why preliminary COUNTEROFFER rows failed feasibility testing.

Boundary:
    counteroffer_feasibility_failure_reason is not a final reason code and not external
    communication language.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_failure_reason,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_failed_preliminary_counteroffers

FROM credit_decisioning_sim.strategy_decisions

WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE

GROUP BY counteroffer_feasibility_failure_reason

ORDER BY
    row_count DESC,
    counteroffer_feasibility_failure_reason;



/*-----------------------------------------------------------------------------------------------
14.11C Product × counteroffer feasibility summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    counteroffer_feasibility_pass_flag,

    COUNT(*) AS preliminary_counteroffer_rows,

    AVG(requested_amount) AS avg_requested_amount,

    AVG(approved_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_amount_for_final_counteroffers,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_final_counteroffers,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_for_final_counteroffers,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_expected_loss_for_final_counteroffers

FROM credit_decisioning_sim.strategy_decisions

WHERE preliminary_decision_outcome = 'COUNTEROFFER'

GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag

ORDER BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag;



/*-----------------------------------------------------------------------------------------------
14.11D Score band × counteroffer feasibility summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    counteroffer_feasibility_pass_flag,

    COUNT(*) AS preliminary_counteroffer_rows,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_amount) AS avg_requested_amount,

    AVG(approved_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_amount_for_final_counteroffers,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_final_counteroffers,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_expected_loss_for_final_counteroffers

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



/*-----------------------------------------------------------------------------------------------
14.11E Final COUNTEROFFER convention diagnostic.

Expected:
    all violation counts = 0.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
    ) AS counteroffer_without_feasibility_pass_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
          )
    ) AS counteroffer_amount_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                exposure_reduction_flag IS DISTINCT FROM TRUE
             OR exposure_reduction_amount IS NULL
             OR exposure_reduction_amount <= 0
             OR exposure_reduction_pct IS NULL
             OR exposure_reduction_pct <= 0
          )
    ) AS counteroffer_exposure_reduction_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_payment_to_income_ratio IS NULL
             OR approved_payment_to_income_ratio > counteroffer_target_pti
          )
    ) AS counteroffer_affordability_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount < 0
             OR approved_expected_loss_amount > requested_expected_loss_amount
             OR approved_expected_loss_amount > product_approved_el_cap
          )
    ) AS counteroffer_expected_loss_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND primary_reason_family <> 'COUNTEROFFER'
    ) AS counteroffer_reason_family_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.11F Final COUNTEROFFER primary reason-code distribution.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS final_counteroffer_rows,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,
    AVG(exposure_reduction_pct) AS avg_exposure_reduction_pct,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'COUNTEROFFER'

GROUP BY primary_reason_code

ORDER BY
    final_counteroffer_rows DESC,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.12 — MANUAL REVIEW VALIDATION DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that MANUAL_REVIEW outcomes remain unresolved and explainable.

    Section 14.12 answers:

        "When the strategy assigns MANUAL_REVIEW, does the row remain unresolved, without simulated
         positive offer exposure or approved exposure economics?"

SQL PURPOSE:
    1. Summarize manual-review population.
    2. Review manual-review decision paths.
    3. Review manual-review reason-code distribution.
    4. Validate unresolved exposure, affordability, Expected Loss, and simulated offer-exposure
       conventions.

BOUNDARY:
    MANUAL_REVIEW is unresolved simulated routing.

    It is not a completed operational review.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.12A Manual-review summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS final_manual_review_rows,

    COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'MANUAL_REVIEW')
        AS preliminary_manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS FALSE
    ) AS failed_counteroffer_to_manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND preliminary_decision_path = 'SEVERE_REQUESTED_STRUCTURE_REVIEW'
    ) AS severe_requested_structure_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND preliminary_decision_path = 'MANUAL_REVIEW_CANDIDATE'
    ) AS manual_review_candidate_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND preliminary_decision_path = 'RESIDUAL_STRATEGY_REVIEW'
    ) AS residual_strategy_review_rows,

    AVG(total_rule_trigger_count) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_total_rule_trigger_count_for_manual_review_rows,

    AVG(requested_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_requested_pti_for_manual_review_rows,

    AVG(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_requested_expected_loss_for_manual_review_rows

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.12B Manual-review path and primary reason-code distribution.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    decision_resolution_source,
    primary_reason_code,

    COUNT(*) AS final_manual_review_rows,

    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'MANUAL_REVIEW'

GROUP BY
    decision_path,
    decision_resolution_source,
    primary_reason_code

ORDER BY
    final_manual_review_rows DESC,
    decision_path,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
14.12C Manual-review unresolved convention diagnostic.

Expected:
    all violation counts = 0.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_amount IS NOT NULL
    ) AS manual_review_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND counteroffer_amount IS NOT NULL
    ) AS manual_review_counteroffer_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_monthly_payment_proxy IS NOT NULL
    ) AS manual_review_approved_payment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_payment_to_income_ratio IS NOT NULL
    ) AS manual_review_approved_pti_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_expected_loss_amount IS NOT NULL
    ) AS manual_review_approved_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND simulated_offer_exposure_flag IS DISTINCT FROM FALSE
    ) AS manual_review_offer_exposure_flag_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND primary_reason_family <> 'MANUAL_REVIEW'
    ) AS manual_review_reason_family_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.13 — DECLINE AND POLICY-STOP VALIDATION DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Validate that final DECLINE outcomes follow locked zero-exposure conventions and are explained by
    policy-stop-style simulated reason codes.

    Section 14.13 answers:

        "Do final simulated no-offer outcomes behave as no-offer rows and remain explainable?"

SQL PURPOSE:
    1. Summarize decline population.
    2. Review decline paths and policy-stop reason-code distribution.
    3. Review hard policy stop, severe synthetic risk, severe DTI, and failed counteroffer decline
       drivers.
    4. Validate zero-exposure, zero-affordability, zero-Expected-Loss conventions.

BOUNDARY:
    POLICY_STOP reason codes are internal simulated strategy explanation codes.

    They are not adverse-action notices or customer communication language.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.13A Decline summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
        AS final_decline_rows,

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
    ) AS dti_decline_trigger_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS FALSE
          AND failed_counteroffer_resolution = 'DECLINE'
    ) AS failed_counteroffer_to_decline_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_synthetic_estimated_pd_proxy_for_declines,

    AVG(debt_to_income_ratio) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_dti_for_declines,

    AVG(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_requested_expected_loss_for_declines,

    AVG(total_rule_trigger_count) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_total_rule_trigger_count_for_declines

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.13B Decline path and primary reason-code distribution.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    decision_resolution_source,
    primary_reason_code,

    COUNT(*) AS final_decline_rows,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'DECLINE'

GROUP BY
    decision_path,
    decision_resolution_source,
    primary_reason_code

ORDER BY
    final_decline_rows DESC,
    decision_path,
    primary_reason_code;



/*-----------------------------------------------------------------------------------------------
14.13C Decline zero-exposure convention diagnostic.

Expected:
    all violation counts = 0.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND counteroffer_amount IS NOT NULL
    ) AS decline_counteroffer_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_monthly_payment_proxy IS DISTINCT FROM 0::NUMERIC
    ) AS decline_approved_payment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
    ) AS decline_approved_pti_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_approved_expected_loss_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND simulated_offer_exposure_flag IS DISTINCT FROM FALSE
    ) AS decline_offer_exposure_flag_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND primary_reason_family <> 'POLICY_STOP'
    ) AS decline_reason_family_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



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
    1. Check reason-code completeness.
    2. Check reason-family alignment to decision_outcome.
    3. Review primary reason-code distribution.
    4. Review reason-code count distribution.
    5. Review concentration of the most common reason code.

BOUNDARY:
    Reason codes are internal simulated strategy explanation codes.

    They are not customer communications, regulatory notices, adverse-action reasons, or fair-lending
    conclusions.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.14A Reason-code completeness and family alignment diagnostic.

Expected:
    all violation counts = 0.
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
          AND primary_reason_family <> 'APPROVAL'
    ) AS approve_reason_family_alignment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND primary_reason_family <> 'COUNTEROFFER'
    ) AS counteroffer_reason_family_alignment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND primary_reason_family <> 'MANUAL_REVIEW'
    ) AS manual_review_reason_family_alignment_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND primary_reason_family <> 'POLICY_STOP'
    ) AS decline_reason_family_alignment_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.14B Primary reason-code distribution.
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
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count

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
    Higher reason_code_count means more overlapping explanation drivers existed. It does not
    automatically mean greater severity.
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
    3. Review product and score-band composition of simulated offer-exposure rows.

BOUNDARY:
    simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER.

    It does not imply booked exposure, funded exposure, account creation, production approval, or real
    applicant treatment.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.15A Simulated offer-exposure summary.
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

ORDER BY simulated_offer_exposure_flag;



/*-----------------------------------------------------------------------------------------------
14.15B Product × score composition of simulated offer-exposure rows.
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
        AS avg_synthetic_estimated_pd_proxy_offer_rows

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

    It becomes a review concern only if it dominates the output, violates final output conventions,
    or cannot be explained through product structure, borrower profile, affordability, synthetic
    estimated-risk tiering, rule triggers, or exposure-treatment diagnostics.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.16A Mixed-signal profile distribution.
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
        / NULLIF(COUNT(*), 0) AS decline_rate

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
        / NULLIF(COUNT(*), 0) AS decline_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY borderline_profile_flag

ORDER BY borderline_profile_flag;



/*-----------------------------------------------------------------------------------------------
14.16C Strong credit / high requested PTI sample.
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
-----------------------------------------------------------------------------------------------*/

SELECT
    archive_table_exists,

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
    5. Summarize product, counteroffer, manual-review, reason-code, edge-case, archive, comparison,
       and source-consistency diagnostics.
    6. Use PASS / REVIEW / NOT_APPLICABLE status values only.

STATUS RULE:
    PASS:
        Expected condition satisfied.

    REVIEW:
        Diagnostic pattern should be interpreted before documentation.

    NOT_APPLICABLE:
        Supporting object or comparison context was not available or not ready.

BOUNDARY:
    This section creates one temporary validation summary table.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not modify evidence rows.
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
                 OR approved_payment_to_income_ratio IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
                 OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
              )
        ) AS manual_review_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
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
              AND primary_reason_family <> 'COUNTEROFFER'
        ) AS counteroffer_reason_family_violation_rows
    FROM base
),

manual_review_diagnostics AS (
    SELECT
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_rows,

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
        SUM(latest_run_rows) AS latest_run_rows,
        SUM(current_archived_slice_rows) AS current_archived_slice_rows,
        SUM(current_archived_slice_null_archive_ts_rows) AS current_archived_slice_null_archive_ts_rows,
        MAX(archive_readiness_status) AS archive_readiness_status
    FROM tmp_m2_validation_archive_readiness_context
),

comparison_context AS (
    SELECT
        COALESCE(MAX(readiness_status), 'NOT_APPLICABLE_SECTION_13_COMPARISON_READINESS_NOT_AVAILABLE')
            AS readiness_status,

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
        COALESCE(MAX(source_consistency_status), 'NOT_APPLICABLE_SECTION_13_SOURCE_CONSISTENCY_NOT_AVAILABLE')
            AS source_consistency_status,

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
    'REASON_CODE_CONCENTRATION',
    'Top primary reason-code concentration',
    'EXPLAINABILITY_DIAGNOSTIC',

    CASE
        WHEN rc.top_primary_reason_code_share IS NULL
            THEN 'REVIEW'

        WHEN rc.top_primary_reason_code_share > 0.750000
            THEN 'REVIEW'

        ELSE 'PASS'
    END AS validation_status,

    'top_primary_reason_code_share=' || COALESCE(rc.top_primary_reason_code_share::TEXT, '<NULL>')
        AS observed_value,

    'Reason-code concentration may be valid, but very high concentration should be explained before documentation.'
        AS expected_behavior,

    'High reason concentration may indicate a deliberate strategy posture, a narrow scenario, or a configuration issue requiring review.'
        AS interpretation

FROM reason_concentration rc

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

    REVIEW items may still be present. They are carried into Section 16 as evidence prompts.
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
<!-- END_MESSAGE C038-M01608 -->


---

<a id="c038-m01609"></a>

### C038-M01609

**Andrew** · 2026-05-12T14:15:20.695000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01609 -->
the prior pass 4 - operational pipeline commentary and compatibility tightening (section 14 - module 1 source selection and lineage normalization) failed probably due to the complexity being too much for one prompt.  how would you recommend splitting up section 14 into chunks, so it is successful; while making sure you do not miss anything?  do not try pass 4 on section 14 in this response.  just give me a better plan for the section 14 pass 4.
<!-- END_MESSAGE C038-M01609 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_83.md) · [Next](Part_85.md)
