# Module 2 Decision Simulator Build

## Part 31

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_30.md) · [Next](Part_32.md)

<a id="c038-m00729"></a>

### C038-M00729

**Andrew** · 2026-05-09T17:22:32.279000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00729 -->
section 14:
<!-- END_MESSAGE C038-M00729 -->


**Attachments in export:** `Pasted text(122).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00735"></a>

### C038-M00735

**ChatGPT** · 2026-05-09T17:28:05.363340-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00735 -->
Section 14 review: **accepted, with no additional patch required.** The uploaded Section 14 already reflects the accepted validation architecture and includes the final validation-status summary layer. It remains read-only, validates the completed latest-run output, preserves the `estimated_pd` synthetic estimated-PD proxy boundary, preserves the requested-versus-approved Expected Loss distinction, and includes product, score-band, product × score, synthetic-risk, affordability, DTI, exposure, counteroffer, manual-review, decline / policy-stop, reason-code, simulated-offer exposure, archive-readiness, comparison-readiness, and edge-case diagnostics. fileciteturn42file12

The key final patch is already present: **Section 14.19 creates `tmp_m2_validation_status_summary`** and uses the expected fields: `validation_area`, `validation_test_name`, `validation_category`, `validation_status`, `observed_value`, `expected_behavior`, and `interpretation`. It also uses the correct status framework: `PASS`, `REVIEW`, and `NOT_APPLICABLE`, with no ordinary diagnostic `FAIL` status. fileciteturn40file14

The Section 13-to-Section 14 connection also appears properly integrated. Section 14.19 includes **matched strategy comparison readiness** and **matched source-field consistency** as validation summary rows, including the `matched_module1_source_fields_consistency` diagnostic and the `SOURCE_FIELDS_MATCH` / `SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED` / `NOT_APPLICABLE` handling. fileciteturn41file0

One implementation dependency to preserve during final assembly: Section 13 must run before Section 14 when you want matched comparison readiness and source-field consistency evidence populated from the comparison framework. Our updated Section 13 creates the needed comparison helpers, and the updated Section 1 cleanup now resets the Section 13 helper temps and `tmp_m2_validation_status_summary`, so the full-run sequence is clean.

**Acceptance position:** Section 14 is now final for the commentary-hardening pass. The next appropriate step is to proceed to **Section 15** only if we are continuing the hardening pass, or to begin full canonical SQL code capture if Sections 15–16 are already being handled as post-core evidence / frontier layers.
<!-- END_MESSAGE C038-M00735 -->


---

<a id="c038-m00737"></a>

### C038-M00737

**Andrew** · 2026-05-09T17:29:32.035000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00737 -->
I passed it to you to do the commentary-hardening pass.  here it is again:
<!-- END_MESSAGE C038-M00737 -->


**Attachments in export:** `Pasted text(123).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00752"></a>

### C038-M00752

**ChatGPT** · 2026-05-09T17:34:29.577526-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00752 -->
I completed the Section 14 commentary-hardening pass and prepared a paste-ready SQL file.

Changes applied:
- Added top-level **INPUTS / OUTPUT / GRAIN / GOVERNANCE ROLE / COMMON MISUSE / DOWNSTREAM DEPENDENCY / PORTFOLIO ARTIFACT VALUE** commentary.
- Added a Section 14.19 dependency note clarifying that comparison-readiness rows expect the Section 13 comparison helper to exist in the same execution session.
- Removed the embedded `MODULE 2 FULL SQL CODE CAPTURE — PART 7D/7E/7F` boundary comments from inside Section 14 so this is now clean section-level SQL.
- Preserved the existing validation logic, including `tmp_m2_validation_status_summary`, matched strategy comparison readiness, and matched source-field consistency coverage. fileciteturn44file4

Download the hardened Section 14 SQL here:

[Download Section 14 commentary-hardened SQL](sandbox:/mnt/data/module2_section_14_commentary_hardened.sql)
<!-- END_MESSAGE C038-M00752 -->


---

<a id="c038-m00754"></a>

### C038-M00754

**Andrew** · 2026-05-09T17:57:20.502000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00754 -->
this is not at the elite commentary level that you gave me for the sections 0-13 above.  also those you had as a copy paste, not as a download.  please follow the same process we've been following and have it be at an elite, commentary level.  here is section 14 again.  also, here is sections 0-13 so you can see the level you had been performing at.  please give me updated section 14 at that elite commentary/header level as a copy paste.
<!-- END_MESSAGE C038-M00754 -->


**Attachments in export:** `Pasted text(124).txt`, `Pasted text (2)(2).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00758"></a>

### C038-M00758

**ChatGPT** · 2026-05-09T18:07:29.003071-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00758 -->
You’re right. Below is a **copy-paste Section 14 replacement** written at the same elevated instructional / governance level as the hardened Sections 0–13, while preserving the Section 14 validation intent, read-only boundary, and `tmp_m2_validation_status_summary` evidence layer. I used your resent Section 14 and the accepted Sections 0–13 style standard as the basis. fileciteturn45file0turn45file1

```sql
/***************************************************************************************************
SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the full read-only QA and validation evidence layer for the completed latest-run
    Module 2 strategy output.

    Section 14 answers:

        "Does this completed Module 2 strategy run behave coherently, consistently, explainably,
         and within the documented simulation boundaries?"

    Section 14 also creates a compact validation status summary table that can later serve as an
    evidence spine for:
        Validation Summary drafting,
        executive evidence capture,
        README interpretation,
        LinkedIn result storytelling,
        and campaign-run documentation.

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
    6. Materialize tmp_m2_validation_status_summary as a compact temporary validation status output.
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

TEMPORARY OUTPUT:
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

    It does not imply operational account creation, funding, production approval, operational
    exposure, or real applicant treatment.

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

    They are not external notices, production compliance determinations, customer communications,
    or fair-lending conclusions.

EDGE-CASE REVIEW:
    Edge cases should remain visible and explainable.

    Realistic overlap is not automatically a defect.

    It becomes a concern only if it dominates the output, violates locked conventions, or cannot be
    explained through:
        product structure,
        borrower profile,
        affordability,
        synthetic estimated-risk tiering,
        rule triggers,
        exposure-treatment diagnostics,
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

    If Section 13 has not run in the current session, Section 14 creates temporary NOT_APPLICABLE
    comparison-readiness placeholders so latest-run QA can still proceed.

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
SECTION 14.0 — OPTIONAL COMPARISON-HELPER SAFETY SETUP
****************************************************************************************************

PURPOSE:
    Ensure Section 14 can create a complete validation status summary even when Section 13 comparison
    helpers are not present in the current database session.

BUSINESS PURPOSE:
    Latest-run validation should remain available even if matched comparison is not ready.

    Comparison-readiness diagnostics should be marked NOT_APPLICABLE rather than causing Section 14
    to fail solely because Section 13 was not run.

SQL PURPOSE:
    1. Check whether tmp_m2_strategy_comparison_readiness exists.
    2. Check whether tmp_m2_strategy_comparison_source_consistency exists.
    3. Create temporary NOT_APPLICABLE placeholder rows only when those helper tables do not exist.

READ-ONLY BOUNDARY:
    This section creates temporary helper placeholders only.

    It does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive
        strategy parameters
        product policy parameters
        reason codes
        approved exposure
        approved Expected Loss

****************************************************************************************************/

DO $$
BEGIN
    IF TO_REGCLASS('tmp_m2_strategy_comparison_readiness') IS NULL THEN
        CREATE TEMP TABLE tmp_m2_strategy_comparison_readiness (
            comparison_group_id                         TEXT,
            comparison_set_name                         TEXT,
            showcase_id                                 TEXT,
            showcase_name                               TEXT,

            baseline_module2_run_id                     TEXT,
            challenger_module2_run_id                   TEXT,

            module1_scenario_set_name                   TEXT,
            module1_scenario_name                       TEXT,
            population_id                               TEXT,

            baseline_strategy_set_name                  TEXT,
            baseline_strategy_name                      TEXT,
            baseline_strategy_version                   TEXT,

            challenger_strategy_set_name                TEXT,
            challenger_strategy_name                    TEXT,
            challenger_strategy_version                 TEXT,

            same_strategy_selected_flag                 BOOLEAN,

            baseline_archived_row_count                 BIGINT,
            challenger_archived_row_count               BIGINT,

            baseline_distinct_application_id_count      BIGINT,
            challenger_distinct_application_id_count    BIGINT,

            baseline_duplicate_application_row_count    BIGINT,
            challenger_duplicate_application_row_count  BIGINT,

            matched_application_id_count                BIGINT,
            baseline_only_application_id_count          BIGINT,
            challenger_only_application_id_count        BIGINT,

            readiness_status                            TEXT,
            expected_comparison_storyline               TEXT,
            primary_metric_focus                        TEXT
        ) ON COMMIT PRESERVE ROWS;

        INSERT INTO tmp_m2_strategy_comparison_readiness (
            comparison_group_id,
            comparison_set_name,
            readiness_status,
            baseline_archived_row_count,
            challenger_archived_row_count,
            matched_application_id_count,
            baseline_only_application_id_count,
            challenger_only_application_id_count
        )
        VALUES (
            NULL,
            NULL,
            'NOT_APPLICABLE_SECTION_13_NOT_RUN',
            NULL,
            NULL,
            NULL,
            NULL,
            NULL
        );
    END IF;

    IF TO_REGCLASS('tmp_m2_strategy_comparison_source_consistency') IS NULL THEN
        CREATE TEMP TABLE tmp_m2_strategy_comparison_source_consistency (
            comparison_group_id                         TEXT,
            comparison_set_name                         TEXT,

            baseline_module2_run_id                     TEXT,
            challenger_module2_run_id                   TEXT,

            module1_scenario_set_name                   TEXT,
            module1_scenario_name                       TEXT,
            population_id                               TEXT,

            readiness_status                            TEXT,

            matched_application_count                   BIGINT,
            source_field_mismatch_count                 BIGINT,

            product_type_mismatch_count                 BIGINT,
            score_band_mismatch_count                   BIGINT,
            credit_score_mismatch_count                 BIGINT,
            annual_income_mismatch_count                BIGINT,
            requested_amount_mismatch_count             BIGINT,
            requested_payment_mismatch_count            BIGINT,
            requested_pti_mismatch_count                BIGINT,
            amount_to_income_mismatch_count             BIGINT,
            estimated_pd_mismatch_count                 BIGINT,
            estimated_lgd_mismatch_count                BIGINT,
            requested_expected_loss_mismatch_count      BIGINT,
            module1_lineage_mismatch_count              BIGINT,

            source_consistency_status                   TEXT
        ) ON COMMIT PRESERVE ROWS;

        INSERT INTO tmp_m2_strategy_comparison_source_consistency (
            comparison_group_id,
            comparison_set_name,
            readiness_status,
            matched_application_count,
            source_field_mismatch_count,
            source_consistency_status
        )
        VALUES (
            NULL,
            NULL,
            'NOT_APPLICABLE_SECTION_13_NOT_RUN',
            NULL,
            NULL,
            'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'
        );
    END IF;
END $$;



/***************************************************************************************************
SECTION 14.1 — VALIDATION SCOPE AND BOUNDARY
****************************************************************************************************

PURPOSE:
    Establish the latest-run validation scope before running detailed QA query blocks.

BUSINESS INTERPRETATION:
    This section confirms what Section 14 is validating:

        the completed latest-run Module 2 strategy output
        in credit_decisioning_sim.strategy_decisions.

    Archive information may be referenced later for readiness context, but the primary validation
    target is the latest-run output.

WHY THIS SECTION EXISTS:
    Validation evidence should be scoped before it is interpreted.

    A latest-run strategy output should be evaluated as:
        one active Module 2 strategy,
        applied to one selected Module 1 scenario / population slice,
        producing one final simulated strategy outcome per synthetic application.

EXPECTED RESULT:
    validation_scope_status should ordinarily equal:

        LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW

BOUNDARY:
    Section 14 validates simulation coherence and output consistency.
    It does not convert Module 2 into an operational decision system.
    It does not validate real applicant treatment.
    It does not validate calibrated default forecasting.
    It does not validate external notices or fair-lending conclusions.

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

Interpretation:
    This query intentionally separates Module 2 strategy identifiers from Module 1 scenario
    identifiers.

Expected:
    One row for a single latest-run strategy / Module 1 scenario / population slice.
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
    Confirm that the latest-run strategy_decisions table exists, is populated, and has the expected
    row-level integrity.

BUSINESS PURPOSE:
    Before reviewing strategy behavior, confirm that the output table has the correct structural
    foundation.

EXPECTED INTERPRETATION:
    total_rows should equal distinct_application_id_count.

    distinct_strategy_version_count should equal 1.

    distinct_module1_scenario_population_count should equal 1.

    Required lineage, strategy, final decision, and simulated reason-code fields should be populated.

WHY STRUCTURAL QA COMES BEFORE STRATEGY QA:
    Decision distribution, reason-code summaries, and exposure diagnostics are only interpretable if
    the output table has the expected row grain and lineage scope.

****************************************************************************************************/

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

    COUNT(*) FILTER (WHERE strategy_set_name IS NULL OR BTRIM(strategy_set_name) = '')
        AS null_or_blank_strategy_set_name_rows,

    COUNT(*) FILTER (WHERE strategy_name IS NULL OR BTRIM(strategy_name) = '')
        AS null_or_blank_strategy_name_rows,

    COUNT(*) FILTER (WHERE strategy_version IS NULL OR BTRIM(strategy_version) = '')
        AS null_or_blank_strategy_version_rows,

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


/*-----------------------------------------------------------------------------------------------
14.2A Row count by Module 1 input source.

Expected:
    One source mode and one source table for the latest-run output.
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

Interpretation:
    This surfaces missing core fields needed for strategy QA.

    Earlier sections contain fail-fast gatekeepers. This query gives documentation-ready evidence
    that the latest-run output remains complete.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE module2_model_version IS NULL OR BTRIM(module2_model_version) = '')
        AS missing_module2_model_version_rows,

    COUNT(*) FILTER (WHERE strategy_run_id IS NULL OR BTRIM(strategy_run_id) = '')
        AS missing_strategy_run_id_rows,

    COUNT(*) FILTER (WHERE strategy_run_ts IS NULL)
        AS missing_strategy_run_ts_rows,

    COUNT(*) FILTER (WHERE product_type_policy_key IS NULL OR BTRIM(product_type_policy_key) = '')
        AS missing_product_type_policy_key_rows,

    COUNT(*) FILTER (WHERE score_band_policy_key IS NULL OR BTRIM(score_band_policy_key) = '')
        AS missing_score_band_policy_key_rows,

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

    COUNT(*) FILTER (WHERE decision_path IS NULL OR BTRIM(decision_path) = '')
        AS missing_decision_path_rows,

    COUNT(*) FILTER (WHERE decision_resolution_source IS NULL OR BTRIM(decision_resolution_source) = '')
        AS missing_decision_resolution_source_rows,

    COUNT(*) FILTER (WHERE primary_reason_code IS NULL OR BTRIM(primary_reason_code) = '')
        AS missing_primary_reason_code_rows,

    COUNT(*) FILTER (WHERE primary_reason_family IS NULL OR BTRIM(primary_reason_family) = '')
        AS missing_primary_reason_family_rows,

    COUNT(*) FILTER (WHERE triggered_reason_code_list IS NULL OR BTRIM(triggered_reason_code_list) = '')
        AS missing_triggered_reason_code_list_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.3 — DECISION OUTCOME DISTRIBUTION
****************************************************************************************************

PURPOSE:
    Summarize final simulated strategy outcomes.

BUSINESS PURPOSE:
    Show the high-level result of the Module 2 strategy after final decision resolution.

EXPECTED INTERPRETATION:
    Every row should have exactly one final decision_outcome.

    APPROVE and COUNTEROFFER represent simulated positive offer-exposure outcomes.

    MANUAL_REVIEW remains unresolved by design.

    DECLINE follows the zero-exposure convention.

WHY THIS QUERY IS NOT SUFFICIENT BY ITSELF:
    Outcome distribution is necessary but not complete validation evidence.

    A strategy can have plausible overall rates while still failing product behavior, score-band
    behavior, affordability behavior, exposure conventions, counteroffer feasibility, or reason-code
    explanation coverage.

****************************************************************************************************/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0),
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

Expected:
    final_decision_flag_count = 1 for every row.

This query complements Section 11 gatekeepers and provides documentation-ready evidence.
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

Interpretation:
    This query shows how preliminary routing resolved after exposure-treatment and final decision
    resolution.
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

****************************************************************************************************/

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

Interpretation:
    One row per product for fast product-level strategy QA.
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


/*-----------------------------------------------------------------------------------------------
14.4B Product-level primary reason-code distribution.

Interpretation:
    Confirms that product-level strategy outcomes remain explainable through simulated strategy
    explanation codes.
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

****************************************************************************************************/

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


/*-----------------------------------------------------------------------------------------------
14.5A Score-band compact decision-rate summary.

Interpretation:
    Provides quick evidence of directional score-band behavior.
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

Interpretation:
    Helps confirm that weaker score-band outcomes remain explainable through simulated strategy
    explanation codes.
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
SECTION 14.6 — PRODUCT × SCORE DECISION MATRIX
****************************************************************************************************

PURPOSE:
    Validate interaction behavior across product and score-band segments.

BUSINESS INTERPRETATION:
    Product × score QA is more informative than product-only or score-only QA because strategy
    outcomes often concentrate at intersections such as:
        unsecured + weaker score,
        revolving + weaker score,
        mortgage + high exposure,
        HELOC + secured exposure,
        auto + moderate affordability pressure.

WHY THIS MATTERS:
    A portfolio-level strategy can look reasonable while a product × score intersection behaves
    unexpectedly.

    Product × score validation helps isolate where simulated strategy outcomes, exposure, and
    approved Expected Loss are concentrated.

****************************************************************************************************/

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
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
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
14.6A Product × score × decision outcome distribution.

Interpretation:
    Detailed distribution for reviewing outcome concentration inside each product × score segment.
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
14.6B Product × score primary reason-code concentration.

Interpretation:
    This query helps identify whether a specific explanation code dominates any product × score
    segment.
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
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.7 — SYNTHETIC RISK ORDERING QA
****************************************************************************************************

PURPOSE:
    Review whether synthetic estimated-risk tiers align directionally with final strategy outcomes.

BUSINESS INTERPRETATION:
    Synthetic estimated-risk tier should generally influence strategy outcomes.

    Lower-risk tiers should generally show more approvals and positive simulated offer exposure.

    Higher-risk tiers should generally show more manual review, counteroffer, or decline outcomes.

IMPORTANT:
    Perfect monotonicity is not required at every intersection because product mix, DTI, PTI,
    exposure, and hard simulated policy-stop flags can override or interact with synthetic risk.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

****************************************************************************************************/

SELECT
    strategy_risk_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY strategy_risk_tier), 0),
        2
    ) AS pct_within_strategy_risk_tier,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,

    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    strategy_risk_tier,
    decision_outcome

ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
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
14.7A Synthetic risk ordering summary.

Interpretation:
    Compares positive simulated offer rows against declined rows.

Expected:
    Average synthetic estimated-PD proxy for offer rows should generally be lower than for declined
    rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_rows,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
        AS avg_synthetic_estimated_pd_proxy_decline_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'APPROVE')
        AS avg_synthetic_estimated_pd_proxy_approve_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_synthetic_estimated_pd_proxy_counteroffer_rows,

    AVG(estimated_pd) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS avg_synthetic_estimated_pd_proxy_manual_review_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.7B Risk-tier primary reason-code distribution.

Interpretation:
    Shows whether risk-tier outcomes are explainable through expected simulated reason-code families.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_risk_tier,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    strategy_risk_tier,
    decision_outcome,
    primary_reason_family,
    primary_reason_code

ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.8 — REQUESTED PTI / AFFORDABILITY SENSITIVITY QA
****************************************************************************************************

PURPOSE:
    Validate that requested-structure affordability pressure influences simulated strategy outcomes.

BUSINESS INTERPRETATION:
    requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.

    Higher requested PTI should generally:
        reduce clean approvals,
        increase counteroffers,
        increase manual review,
        or increase declines.

    Approved PTI is calculated only after simulated exposure treatment and applies to positive
    simulated offer-exposure rows.

BOUNDARY:
    This section reviews requested affordability sensitivity.

    It does not recalculate approved payment or approved PTI.

****************************************************************************************************/

SELECT
    requested_pti_bucket,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY requested_pti_bucket), 0),
        2
    ) AS pct_within_requested_pti_bucket,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows,

    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

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
14.8A Requested PTI sensitivity summary.

Interpretation:
    Compact comparison of low / moderate / elevated / high / severe requested PTI behavior.
-----------------------------------------------------------------------------------------------*/

SELECT
    requested_pti_bucket,

    COUNT(*) AS applications,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

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

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY requested_pti_bucket

ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
14.8B Product × requested PTI bucket summary.

Interpretation:
    Shows whether affordability pressure varies by product structure.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    requested_pti_bucket,

    COUNT(*) AS applications,

    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    product_type_policy_key,
    requested_pti_bucket

ORDER BY
    product_type_policy_key,
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;



/***************************************************************************************************
SECTION 14.9 — DTI CAPACITY QA
****************************************************************************************************

PURPOSE:
    Validate behavior across DTI capacity buckets.

BUSINESS INTERPRETATION:
    DTI is an existing-obligation capacity signal.

    Unlike requested PTI, DTI is not directly solved by counteroffer exposure reduction in Module 2
    V1.0 because a counteroffer changes the simulated requested exposure treatment, not the
    applicant's existing obligations.

EXPECTED BEHAVIOR:
    Higher DTI buckets should generally show more manual review or decline outcomes.

BOUNDARY:
    This section reviews DTI sensitivity.

    It does not recalculate DTI.
    It does not adjust DTI through approved exposure treatment.

****************************************************************************************************/

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
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

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
14.9A DTI bucket compact strategy summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_bucket,

    COUNT(*) AS applications,

    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy

FROM credit_decisioning_sim.strategy_decisions

GROUP BY dti_bucket

ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
14.9B DTI reason-code distribution.
-----------------------------------------------------------------------------------------------*/

SELECT
    dti_bucket,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS row_count,

    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    dti_bucket,
    decision_outcome,
    primary_reason_family,
    primary_reason_code

ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
        ELSE 99
    END,
    row_count DESC,
    primary_reason_family,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.10 — APPROVED EXPOSURE AND EXPECTED LOSS QA
****************************************************************************************************

PURPOSE:
    Validate final approved exposure, approved PTI, and approved Expected Loss behavior.

BUSINESS INTERPRETATION:
    Module 2 transforms requested exposure into final simulated approved exposure only after:
        preliminary routing,
        counteroffer feasibility,
        final decision resolution,
        and locked outcome conventions.

APPROVED EXPOSURE CONVENTIONS:
    APPROVE:
        approved_amount = requested_amount.

    COUNTEROFFER:
        approved_amount is positive and lower than requested_amount.

    MANUAL_REVIEW:
        approved_amount is NULL because the outcome is unresolved.

    DECLINE:
        approved_amount = 0 by zero-exposure convention.

EXPECTED LOSS CONVENTIONS:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is approved-exposure Expected Loss.

    Section 14 validates conventions and comparisons. It does not recalculate Expected Loss.

****************************************************************************************************/

SELECT
    decision_outcome,

    COUNT(*) AS row_count,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_counteroffers,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows

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
14.10A Product-level requested versus approved exposure and Expected Loss.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,

    COUNT(*) AS applications,

    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY product_type_policy_key

ORDER BY product_type_policy_key;


/*-----------------------------------------------------------------------------------------------
14.10B Final approved exposure convention diagnostic.

Expected:
    all violation counts should be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_amount IS DISTINCT FROM requested_amount
    ) AS approve_amount_convention_violation_rows,

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
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_amount IS NOT NULL
    ) AS manual_review_amount_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_amount_convention_violation_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.10C Final approved Expected Loss convention diagnostic.

Expected:
    all violation counts should be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
    ) AS approve_expected_loss_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount > requested_expected_loss_amount
             OR approved_expected_loss_amount > product_approved_el_cap
          )
    ) AS counteroffer_expected_loss_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_expected_loss_amount IS NOT NULL
    ) AS manual_review_expected_loss_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_expected_loss_convention_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.11 — COUNTEROFFER VALIDATION DIAGNOSTICS
****************************************************************************************************

PURPOSE:
    Validate counteroffer behavior and feasibility.

BUSINESS INTERPRETATION:
    COUNTEROFFER is a distinct simulated positive offer-exposure outcome.

    A final COUNTEROFFER should:
        pass counteroffer feasibility,
        have approved_amount below requested_amount,
        satisfy product minimum and product cap,
        satisfy minimum counteroffer percent,
        satisfy maximum exposure reduction,
        satisfy approved PTI target,
        satisfy approved Expected Loss cap,
        and carry a counteroffer-family simulated explanation code.

BOUNDARY:
    Counteroffer diagnostics do not imply operational negotiation or real applicant treatment.

****************************************************************************************************/

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
    ) AS infeasible_preliminary_counteroffer_rows,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS final_counteroffer_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND simulated_offer_exposure_flag IS TRUE
    ) AS final_counteroffer_offer_exposure_rows,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_final_counteroffers,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_final_counteroffers,

    AVG(approved_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_expected_loss_final_counteroffers

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.11A Counteroffer feasibility failure reason distribution.

Interpretation:
    Failure reasons are feasibility diagnostics, not final simulated reason codes.
-----------------------------------------------------------------------------------------------*/

SELECT
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS row_count

FROM credit_decisioning_sim.strategy_decisions

WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE

GROUP BY counteroffer_feasibility_failure_reason

ORDER BY
    row_count DESC,
    counteroffer_feasibility_failure_reason;


/*-----------------------------------------------------------------------------------------------
14.11B Product × counteroffer feasibility.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    counteroffer_feasibility_pass_flag,

    COUNT(*) AS preliminary_counteroffer_rows,

    AVG(requested_amount) AS avg_requested_amount,
    AVG(counteroffer_rounded_amount) AS avg_counteroffer_rounded_amount,
    AVG(approved_payment_to_income_ratio_preliminary) AS avg_approved_pti_preliminary,
    AVG(approved_expected_loss_amount_preliminary) AS avg_approved_expected_loss_preliminary

FROM credit_decisioning_sim.strategy_decisions

WHERE preliminary_decision_outcome = 'COUNTEROFFER'

GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag

ORDER BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag;


/*-----------------------------------------------------------------------------------------------
14.11C Score band × counteroffer feasibility.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    counteroffer_feasibility_pass_flag,

    COUNT(*) AS preliminary_counteroffer_rows,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio_preliminary) AS avg_approved_pti_preliminary

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
14.11D Final counteroffer convention diagnostic.

Expected:
    all violation counts should be zero.
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
          AND approved_payment_to_income_ratio > counteroffer_target_pti
    ) AS counteroffer_approved_pti_above_target_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND approved_expected_loss_amount > product_approved_el_cap
    ) AS counteroffer_approved_expected_loss_above_cap_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND primary_reason_family <> 'COUNTEROFFER'
    ) AS counteroffer_reason_family_alignment_violation_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.11E Counteroffer primary reason-code distribution.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS final_counteroffer_rows

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'COUNTEROFFER'

GROUP BY primary_reason_code

ORDER BY
    final_counteroffer_rows DESC,
    primary_reason_code;



/***************************************************************************************************
SECTION 14.12 — MANUAL REVIEW VALIDATION DIAGNOSTICS
****************************************************************************************************

PURPOSE:
    Validate MANUAL_REVIEW behavior.

BUSINESS INTERPRETATION:
    MANUAL_REVIEW is unresolved by design.

    Manual-review rows should retain NULL final approved exposure, NULL final approved PTI, and NULL
    final approved Expected Loss.

    Manual-review outcomes should be explainable through:
        failed counteroffer resolution,
        requested-structure stress,
        borderline profiles,
        mixed-signal profiles,
        elevated synthetic risk,
        elevated DTI,
        expected-loss pressure,
        supplemental behavioral review signals,
        or residual review fallback.

****************************************************************************************************/

SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS FALSE
    ) AS failed_counteroffer_to_manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
    ) AS mixed_signal_manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND borderline_profile_flag IS TRUE
    ) AS borderline_manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_amount IS NOT NULL
    ) AS manual_review_approved_amount_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_payment_to_income_ratio IS NOT NULL
    ) AS manual_review_approved_pti_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_expected_loss_amount IS NOT NULL
    ) AS manual_review_approved_expected_loss_violation_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.12A Manual review by decision path.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    decision_resolution_source,
    COUNT(*) AS manual_review_rows

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'MANUAL_REVIEW'

GROUP BY
    decision_path,
    decision_resolution_source

ORDER BY
    manual_review_rows DESC,
    decision_path,
    decision_resolution_source;


/*-----------------------------------------------------------------------------------------------
14.12B Manual review by primary reason code.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS manual_review_rows

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'MANUAL_REVIEW'

GROUP BY primary_reason_code

ORDER BY
    manual_review_rows DESC,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
14.12C Mixed-signal profile × manual review count.
-----------------------------------------------------------------------------------------------*/

SELECT
    mixed_signal_profile_type,

    COUNT(*) AS row_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS manual_review_rows,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY mixed_signal_profile_type

ORDER BY
    manual_review_rows DESC,
    mixed_signal_profile_type;


/*-----------------------------------------------------------------------------------------------
14.12D Borderline profile × manual review count.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,

    COUNT(*) AS row_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS manual_review_rows,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate

FROM credit_decisioning_sim.strategy_decisions

GROUP BY borderline_profile_flag

ORDER BY borderline_profile_flag;



/***************************************************************************************************
SECTION 14.13 — DECLINE / POLICY-STOP VALIDATION DIAGNOSTICS
****************************************************************************************************

PURPOSE:
    Validate DECLINE and simulated policy-stop behavior.

BUSINESS INTERPRETATION:
    DECLINE is a simulated no-offer outcome using the zero-exposure convention.

    Decline rows should have:
        approved_amount = 0,
        approved_payment_to_income_ratio = 0,
        approved_expected_loss_amount = 0,
        simulated_offer_exposure_flag = FALSE,
        and primary_reason_family = POLICY_STOP.

BOUNDARY:
    These are simulated strategy explanation codes and internal strategy diagnostics.

****************************************************************************************************/

SELECT
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
        AS decline_rows,

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
          AND requested_pti_decline_trigger_flag IS TRUE
    ) AS requested_pti_decline_trigger_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND requested_el_decline_trigger_flag IS TRUE
    ) AS requested_el_decline_trigger_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_approved_amount_violation_rows,

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
    ) AS decline_reason_family_alignment_violation_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.13A Declines by decision path.
-----------------------------------------------------------------------------------------------*/

SELECT
    decision_path,
    decision_resolution_source,
    COUNT(*) AS decline_rows

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'DECLINE'

GROUP BY
    decision_path,
    decision_resolution_source

ORDER BY
    decline_rows DESC,
    decision_path,
    decision_resolution_source;


/*-----------------------------------------------------------------------------------------------
14.13B Declines by primary reason code.
-----------------------------------------------------------------------------------------------*/

SELECT
    primary_reason_code,
    COUNT(*) AS decline_rows

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'DECLINE'

GROUP BY primary_reason_code

ORDER BY
    decline_rows DESC,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
14.13C Hard simulated policy-stop flags among declines.
-----------------------------------------------------------------------------------------------*/

SELECT
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag,

    COUNT(*) AS decline_rows

FROM credit_decisioning_sim.strategy_decisions

WHERE decision_outcome = 'DECLINE'

GROUP BY
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag

ORDER BY
    decline_rows DESC,
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag;



/***************************************************************************************************
SECTION 14.14 — REASON-CODE COVERAGE AND ALIGNMENT
****************************************************************************************************

PURPOSE:
    Validate simulated reason-code completeness, family alignment, concentration, and boundary
    discipline.

BUSINESS INTERPRETATION:
    Every final simulated outcome should be explainable.

    Reason-code family should align to final decision outcome:

        APPROVE        → APPROVAL
        COUNTEROFFER   → COUNTEROFFER
        MANUAL_REVIEW  → MANUAL_REVIEW
        DECLINE        → POLICY_STOP

BOUNDARY:
    Reason codes are simulated strategy explanation codes only.

****************************************************************************************************/

SELECT
    decision_outcome,
    primary_reason_family,
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
    primary_reason_family,
    primary_reason_code

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    row_count DESC,
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
14.14A Reason-code completeness diagnostic.

Expected:
    all missing counts should be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (WHERE primary_reason_code IS NULL OR BTRIM(primary_reason_code) = '')
        AS missing_primary_reason_code_rows,

    COUNT(*) FILTER (WHERE primary_reason_family IS NULL OR BTRIM(primary_reason_family) = '')
        AS missing_primary_reason_family_rows,

    COUNT(*) FILTER (WHERE triggered_reason_code_list IS NULL OR BTRIM(triggered_reason_code_list) = '')
        AS missing_triggered_reason_code_list_rows,

    COUNT(*) FILTER (WHERE reason_priority_rank IS NULL OR reason_priority_rank <= 0)
        AS missing_or_invalid_reason_priority_rank_rows,

    COUNT(*) FILTER (WHERE reason_code_count IS NULL OR reason_code_count < 1)
        AS missing_or_invalid_reason_code_count_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.14B Reason-code family alignment diagnostic.

Expected:
    all violation counts should be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
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
14.14C Reason-code concentration diagnostic.

Interpretation:
    High concentration is not automatically wrong. It means the strategy story should explain why a
    particular reason dominates.
-----------------------------------------------------------------------------------------------*/

WITH reason_counts AS (
    SELECT
        primary_reason_code,
        COUNT(*) AS row_count
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY primary_reason_code
),

denominator AS (
    SELECT COUNT(*) AS total_rows
    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    rc.primary_reason_code,
    rc.row_count,
    rc.row_count::NUMERIC / NULLIF(d.total_rows, 0) AS population_share

FROM reason_counts rc
CROSS JOIN denominator d

ORDER BY
    population_share DESC,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
14.14D Prohibited external-communication terminology diagnostic.

Expected:
    prohibited_external_communication_term_rows = 0.

Interpretation:
    This protects the boundary that Module 2 reason codes are simulated strategy explanation codes.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE COALESCE(primary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(primary_reason_code, '') ILIKE '%REGULATORY%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%REGULATORY%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%REGULATORY%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%REGULATORY%'
           OR COALESCE(primary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(primary_reason_code, '') ILIKE '%FAIR_LENDING%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%FAIR_LENDING%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%FAIR_LENDING%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%FAIR_LENDING%'
    ) AS prohibited_external_communication_term_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.15 — SIMULATED OFFER-EXPOSURE PROFILE
****************************************************************************************************

PURPOSE:
    Validate the simulated offer-exposure profile.

BUSINESS INTERPRETATION:
    simulated_offer_exposure_flag indicates positive simulated offer exposure.

    It should be TRUE only for:
        APPROVE
        COUNTEROFFER

    It should be FALSE for:
        MANUAL_REVIEW
        DECLINE

BOUNDARY:
    This flag does not imply account creation, funding, operational approval, or real applicant
    treatment.

****************************************************************************************************/

SELECT
    simulated_offer_exposure_flag,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_population,

    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY simulated_offer_exposure_flag

ORDER BY simulated_offer_exposure_flag;


/*-----------------------------------------------------------------------------------------------
14.15A Simulated offer-exposure flag reconciliation diagnostic.

Expected:
    violation rows = 0.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS DISTINCT FROM
              (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
    ) AS simulated_offer_exposure_flag_reconciliation_violation_rows

FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
14.15B Simulated offer-exposure by product and score band.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_rows,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy

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

PURPOSE:
    Surface edge cases, mixed-signal cases, and borderline profiles for human review.

BUSINESS INTERPRETATION:
    Mixed-signal and borderline cases are expected in a realistic synthetic portfolio.

    They are not automatically errors.

    They become concerns only if they:
        dominate the output,
        violate final conventions,
        lack explanation through staged diagnostics,
        or create unstable strategy behavior.

EDGE-CASE TYPES:
    strong credit with high requested PTI,
    weak credit with low requested PTI,
    large exposure with low synthetic estimated risk,
    high synthetic estimated risk with low exposure,
    high DTI with low requested PTI,
    threshold-adjacent borderline cases.

****************************************************************************************************/

SELECT
    mixed_signal_profile_type,
    borderline_profile_flag,
    decision_outcome,

    COUNT(*) AS row_count,

    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,
    AVG(requested_amount) AS avg_requested_amount,

    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
    AVG(COALESCE(approved_expected_loss_amount, 0)) AS avg_approved_expected_loss_all_apps

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    mixed_signal_profile_type,
    borderline_profile_flag,
    decision_outcome

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
    END,
    borderline_profile_flag,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
14.16A Edge-case sample for review.

Interpretation:
    This sample is not an operational queue. It is a strategy QA review sample.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,

    product_type_policy_key,
    score_band_policy_key,
    credit_score,

    strategy_risk_tier,
    requested_pti_bucket,
    dti_bucket,
    requested_exposure_tier,
    requested_expected_loss_tier,

    mixed_signal_profile_type,
    borderline_profile_flag,

    requested_amount,
    approved_amount,
    requested_payment_to_income_ratio,
    approved_payment_to_income_ratio,
    estimated_pd,
    estimated_lgd,
    requested_expected_loss_amount,
    approved_expected_loss_amount,

    decision_outcome,
    decision_path,
    decision_resolution_source,

    primary_reason_family,
    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    triggered_reason_code_list

FROM credit_decisioning_sim.strategy_decisions

WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
   OR borderline_profile_flag IS TRUE
   OR decision_path IN (
        'RESIDUAL_STRATEGY_REVIEW',
        'FINAL_RESIDUAL_STRATEGY_REVIEW'
   )

ORDER BY
    CASE
        WHEN decision_path IN ('RESIDUAL_STRATEGY_REVIEW', 'FINAL_RESIDUAL_STRATEGY_REVIEW') THEN 1
        WHEN mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE' THEN 2
        WHEN borderline_profile_flag IS TRUE THEN 3
        ELSE 99
    END,
    estimated_pd DESC,
    requested_payment_to_income_ratio DESC,
    application_id

LIMIT 100;


/*-----------------------------------------------------------------------------------------------
14.16B Mixed-signal concentration summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE')
        AS mixed_signal_rows,

    COUNT(*) FILTER (WHERE borderline_profile_flag IS TRUE)
        AS borderline_rows,

    COUNT(*) FILTER (
        WHERE decision_path IN ('RESIDUAL_STRATEGY_REVIEW', 'FINAL_RESIDUAL_STRATEGY_REVIEW')
    ) AS residual_review_rows,

    COUNT(*) FILTER (
        WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
          AND decision_outcome = 'MANUAL_REVIEW'
    ) AS mixed_signal_manual_review_rows,

    COUNT(*) FILTER (
        WHERE borderline_profile_flag IS TRUE
          AND decision_outcome = 'MANUAL_REVIEW'
    ) AS borderline_manual_review_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.17 — FINAL OUTPUT CONVENTION VALIDATION
****************************************************************************************************

PURPOSE:
    Provide compact final convention diagnostics for core Module 2 output rules.

BUSINESS PURPOSE:
    These diagnostics are designed to be easy to paste into a validation artifact because they provide
    clear violation counts for locked output conventions.

EXPECTED RESULT:
    All violation counts should be zero.

BOUNDARY:
    These queries validate existing output values.

    They do not recalculate or modify any values.

****************************************************************************************************/

SELECT
    COUNT(*) FILTER (
        WHERE decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
           OR decision_outcome IS NULL
    ) AS invalid_decision_outcome_rows,

    COUNT(*) FILTER (
        WHERE (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
        ) <> 1
    ) AS final_decision_flag_reconciliation_violation_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS DISTINCT FROM
              (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
    ) AS simulated_offer_exposure_flag_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND (
                approved_amount IS DISTINCT FROM requested_amount
             OR approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
             OR primary_reason_family <> 'APPROVAL'
          )
    ) AS approve_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
             OR counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
             OR approved_expected_loss_amount > product_approved_el_cap
             OR approved_payment_to_income_ratio > counteroffer_target_pti
             OR primary_reason_family <> 'COUNTEROFFER'
          )
    ) AS counteroffer_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND (
                approved_amount IS NOT NULL
             OR approved_payment_to_income_ratio IS NOT NULL
             OR approved_expected_loss_amount IS NOT NULL
             OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
             OR primary_reason_family <> 'MANUAL_REVIEW'
          )
    ) AS manual_review_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND (
                approved_amount IS DISTINCT FROM 0::NUMERIC
             OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
             OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
             OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
             OR primary_reason_family <> 'POLICY_STOP'
          )
    ) AS decline_convention_violation_rows,

    COUNT(*) FILTER (
        WHERE primary_reason_code IS NULL
           OR primary_reason_family IS NULL
           OR triggered_reason_code_list IS NULL
           OR reason_code_count IS NULL
           OR reason_code_count < 1
    ) AS reason_code_completeness_violation_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.18 — ARCHIVE AND COMPARISON READINESS RECAP
****************************************************************************************************

PURPOSE:
    Review whether the latest-run output has archive support and whether matched comparison evidence
    is ready.

BUSINESS PURPOSE:
    Module 2 strategy evidence is strongest when:
        latest-run output is validated,
        archive persistence is confirmed,
        baseline / challenger comparison is ready,
        and matched source fields are consistent.

BOUNDARY:
    This section does not insert, delete, update, or modify archive rows.

    It only reports readiness status.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
14.18A Current latest-run archive slice alignment.

Interpretation:
    When archive_run_flag = TRUE and Section 12 has run, current_archived_slice_row_count should
    match latest_run_row_count.
-----------------------------------------------------------------------------------------------*/

WITH latest_key AS (
    SELECT DISTINCT
        archive_run_flag,
        strategy_archive_reset_mode,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_decisions
),

latest_counts AS (
    SELECT
        COUNT(*) AS latest_run_row_count,
        COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count
    FROM credit_decisioning_sim.strategy_decisions
),

archive_counts AS (
    SELECT
        lk.strategy_set_name,
        lk.strategy_name,
        lk.strategy_version,
        lk.module1_scenario_set_name,
        lk.module1_scenario_name,
        lk.population_id,

        COUNT(ar.*) AS current_archived_slice_row_count,
        COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count

    FROM latest_key lk

    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
        ON ar.strategy_set_name = lk.strategy_set_name
       AND ar.strategy_name = lk.strategy_name
       AND ar.strategy_version = lk.strategy_version
       AND ar.module1_scenario_set_name = lk.module1_scenario_set_name
       AND ar.module1_scenario_name = lk.module1_scenario_name
       AND ar.population_id = lk.population_id

    GROUP BY
        lk.strategy_set_name,
        lk.strategy_name,
        lk.strategy_version,
        lk.module1_scenario_set_name,
        lk.module1_scenario_name,
        lk.population_id
)

SELECT
    lk.archive_run_flag,
    lk.strategy_archive_reset_mode,

    lk.strategy_set_name,
    lk.strategy_name,
    lk.strategy_version,
    lk.module1_scenario_set_name,
    lk.module1_scenario_name,
    lk.population_id,

    lc.latest_run_row_count,
    lc.latest_run_distinct_application_id_count,

    ac.current_archived_slice_row_count,
    ac.current_archived_slice_distinct_application_id_count,

    CASE
        WHEN lk.archive_run_flag IS FALSE
            THEN 'ARCHIVE_NOT_REQUIRED_ARCHIVE_RUN_FLAG_FALSE'

        WHEN ac.current_archived_slice_row_count = lc.latest_run_row_count
         AND ac.current_archived_slice_distinct_application_id_count = lc.latest_run_distinct_application_id_count
            THEN 'ARCHIVE_SLICE_ALIGNED_TO_LATEST_RUN'

        ELSE 'ARCHIVE_SLICE_REVIEW_REQUIRED'
    END AS archive_readiness_status

FROM latest_key lk

CROSS JOIN latest_counts lc

JOIN archive_counts ac
    ON ac.strategy_set_name = lk.strategy_set_name
   AND ac.strategy_name = lk.strategy_name
   AND ac.strategy_version = lk.strategy_version
   AND ac.module1_scenario_set_name = lk.module1_scenario_set_name
   AND ac.module1_scenario_name = lk.module1_scenario_name
   AND ac.population_id = lk.population_id;


/*-----------------------------------------------------------------------------------------------
14.18B Matched strategy comparison readiness recap.

Interpretation:
    Uses Section 13 helper when available.
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    baseline_archived_row_count,
    challenger_archived_row_count,
    matched_application_id_count,
    baseline_only_application_id_count,
    challenger_only_application_id_count,

    readiness_status,
    expected_comparison_storyline,
    primary_metric_focus

FROM tmp_m2_strategy_comparison_readiness;


/*-----------------------------------------------------------------------------------------------
14.18C Matched source-field consistency recap.

Interpretation:
    Uses Section 13 helper when available.

Expected for ready matched comparison:
    source_consistency_status = SOURCE_FIELDS_MATCH
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

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

FROM tmp_m2_strategy_comparison_source_consistency;



/***************************************************************************************************
SECTION 14.19 — VALIDATION STATUS SUMMARY TABLE
****************************************************************************************************

PURPOSE:
    Materialize a compact validation status summary that can be consumed by Section 16 evidence
    capture and later documentation.

BUSINESS PURPOSE:
    Avoid scattering validation evidence across many result grids without a single executive
    interpretation spine.

    tmp_m2_validation_status_summary gives one compact row per major validation area.

SQL PURPOSE:
    Create:

        tmp_m2_validation_status_summary

    with fields:
        validation_area
        validation_test_name
        validation_category
        validation_status
        observed_value
        expected_behavior
        interpretation

VALIDATION STATUS VALUES:
    PASS:
        Structural or diagnostic expectation is satisfied.

    REVIEW:
        Pattern may be acceptable, but should be interpreted before documentation.

    NOT_APPLICABLE:
        Test depends on unavailable archive slices, unavailable comparison parameters, or non-ready
        matched comparison setup.

IMPORTANT:
    This table is temporary only.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not modify strategy parameters.
    It does not modify product policy parameters.
    It does not recalculate decisions, reason codes, approved exposure, or Expected Loss.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

CREATE TEMP TABLE tmp_m2_validation_status_summary
ON COMMIT PRESERVE ROWS
AS
WITH latest AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

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

        COUNT(*) FILTER (WHERE decision_outcome IS NULL) AS null_decision_outcome_rows,

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

    FROM credit_decisioning_sim.strategy_decisions
),

decision_flag_diag AS (
    SELECT
        COUNT(*) FILTER (
            WHERE (
                COALESCE(approval_flag::INT, 0)
                + COALESCE(counteroffer_flag::INT, 0)
                + COALESCE(manual_review_flag::INT, 0)
                + COALESCE(decline_flag::INT, 0)
            ) <> 1
        ) AS final_flag_reconciliation_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

offer_flag_diag AS (
    SELECT
        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS DISTINCT FROM
                  (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

amount_diag AS (
    SELECT
        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND approved_amount IS DISTINCT FROM requested_amount
            )
            OR (
                    decision_outcome = 'COUNTEROFFER'
                AND (
                        approved_amount IS NULL
                     OR approved_amount <= 0
                     OR approved_amount >= requested_amount
                     OR counteroffer_amount IS DISTINCT FROM approved_amount
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
        ) AS approved_amount_convention_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

expected_loss_diag AS (
    SELECT
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
                     OR approved_expected_loss_amount > product_approved_el_cap
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
        ) AS approved_expected_loss_convention_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

reason_diag AS (
    SELECT
        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR BTRIM(primary_reason_code) = ''
               OR primary_reason_family IS NULL
               OR BTRIM(primary_reason_family) = ''
               OR triggered_reason_code_list IS NULL
               OR BTRIM(triggered_reason_code_list) = ''
               OR reason_priority_rank IS NULL
               OR reason_priority_rank <= 0
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
        ) AS reason_family_alignment_violation_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(primary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(primary_reason_code, '') ILIKE '%REGULATORY%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%REGULATORY%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%REGULATORY%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%REGULATORY%'
               OR COALESCE(primary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(primary_reason_code, '') ILIKE '%FAIR_LENDING%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%FAIR_LENDING%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%FAIR_LENDING%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%FAIR_LENDING%'
        ) AS prohibited_external_communication_term_rows

    FROM credit_decisioning_sim.strategy_decisions
),

product_diag AS (
    WITH product_rates AS (
        SELECT
            product_type_policy_key,
            decision_outcome,

            COUNT(*) AS row_count,

            COUNT(*)::NUMERIC
                / NULLIF(
                    SUM(COUNT(*)) OVER (PARTITION BY product_type_policy_key),
                    0
                  ) AS pct_within_product

        FROM credit_decisioning_sim.strategy_decisions

        GROUP BY
            product_type_policy_key,
            decision_outcome
    )
    SELECT
        COUNT(DISTINCT product_type_policy_key) AS product_count,
        MAX(pct_within_product) AS max_single_product_outcome_share
    FROM product_rates
),

score_diag AS (
    SELECT
        COUNT(DISTINCT score_band_policy_key) AS score_band_count,

        AVG(estimated_pd) FILTER (WHERE score_band_policy_key = 'SUPER_PRIME')
            AS super_prime_avg_synthetic_estimated_pd_proxy,

        AVG(estimated_pd) FILTER (WHERE score_band_policy_key = 'DEEP_SUBPRIME')
            AS deep_subprime_avg_synthetic_estimated_pd_proxy

    FROM credit_decisioning_sim.strategy_decisions
),

risk_ordering AS (
    SELECT
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_rows,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_decline_rows

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
        COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER')
            AS preliminary_counteroffer_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS final_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
                 OR approved_amount IS NULL
                 OR approved_amount <= 0
                 OR approved_amount >= requested_amount
                 OR approved_payment_to_income_ratio > counteroffer_target_pti
                 OR approved_expected_loss_amount > product_approved_el_cap
                 OR primary_reason_family <> 'COUNTEROFFER'
              )
        ) AS final_counteroffer_convention_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

manual_review_diag AS (
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
                 OR primary_reason_family <> 'MANUAL_REVIEW'
              )
        ) AS manual_review_unresolved_convention_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

decline_diag AS (
    SELECT
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
                 OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
                 OR primary_reason_family <> 'POLICY_STOP'
              )
        ) AS decline_zero_exposure_or_reason_convention_violation_rows

    FROM credit_decisioning_sim.strategy_decisions
),

mixed_signal_diag AS (
    SELECT
        COUNT(*) FILTER (WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE')
            AS mixed_signal_rows,

        COUNT(*) FILTER (WHERE borderline_profile_flag IS TRUE)
            AS borderline_rows,

        COUNT(*) FILTER (
            WHERE decision_path IN ('RESIDUAL_STRATEGY_REVIEW', 'FINAL_RESIDUAL_STRATEGY_REVIEW')
        ) AS residual_review_rows,

        COUNT(*) FILTER (
            WHERE mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
              AND decision_outcome = 'MANUAL_REVIEW'
        ) AS mixed_signal_manual_review_rows

    FROM credit_decisioning_sim.strategy_decisions
),

archive_diag AS (
    WITH latest_key AS (
        SELECT DISTINCT
            archive_run_flag,
            strategy_archive_reset_mode,
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        FROM credit_decisioning_sim.strategy_decisions
    ),

    latest_counts AS (
        SELECT
            COUNT(*) AS latest_run_row_count,
            COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count
        FROM credit_decisioning_sim.strategy_decisions
    ),

    archive_counts AS (
        SELECT
            lk.archive_run_flag,
            lk.strategy_archive_reset_mode,
            lk.strategy_set_name,
            lk.strategy_name,
            lk.strategy_version,
            lk.module1_scenario_set_name,
            lk.module1_scenario_name,
            lk.population_id,

            COUNT(ar.*) AS current_archived_slice_row_count,
            COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count

        FROM latest_key lk

        LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
            ON ar.strategy_set_name = lk.strategy_set_name
           AND ar.strategy_name = lk.strategy_name
           AND ar.strategy_version = lk.strategy_version
           AND ar.module1_scenario_set_name = lk.module1_scenario_set_name
           AND ar.module1_scenario_name = lk.module1_scenario_name
           AND ar.population_id = lk.population_id

        GROUP BY
            lk.archive_run_flag,
            lk.strategy_archive_reset_mode,
            lk.strategy_set_name,
            lk.strategy_name,
            lk.strategy_version,
            lk.module1_scenario_set_name,
            lk.module1_scenario_name,
            lk.population_id
    )

    SELECT
        ac.archive_run_flag,
        ac.strategy_archive_reset_mode,
        lc.latest_run_row_count,
        lc.latest_run_distinct_application_id_count,
        ac.current_archived_slice_row_count,
        ac.current_archived_slice_distinct_application_id_count

    FROM archive_counts ac
    CROSS JOIN latest_counts lc
),

comparison_readiness AS (
    SELECT
        readiness_status
    FROM tmp_m2_strategy_comparison_readiness
    LIMIT 1
),

matched_source_consistency AS (
    SELECT
        source_consistency_status,
        matched_application_count,
        source_field_mismatch_count
    FROM tmp_m2_strategy_comparison_source_consistency
    LIMIT 1
),

validation_rows AS (
    SELECT
        'Latest-run structural integrity'::TEXT AS validation_area,
        'row_grain_strategy_scope_and_lineage'::TEXT AS validation_test_name,
        'STRUCTURAL'::TEXT AS validation_category,

        CASE
            WHEN total_rows > 0
             AND total_rows = distinct_application_id_count
             AND distinct_strategy_version_count = 1
             AND distinct_module1_scenario_population_count = 1
                THEN 'PASS'
            ELSE 'REVIEW'
        END AS validation_status,

        FORMAT(
            'total_rows=%s; distinct_application_id=%s; distinct_strategy_versions=%s; distinct_module1_scenario_population=%s',
            total_rows,
            distinct_application_id_count,
            distinct_strategy_version_count,
            distinct_module1_scenario_population_count
        ) AS observed_value,

        'Latest-run output should contain one row per application_id, one strategy version, and one Module 1 scenario / population slice.'::TEXT
            AS expected_behavior,

        'Structural integrity establishes whether downstream QA outputs are interpretable.'::TEXT
            AS interpretation

    FROM latest

    UNION ALL

    SELECT
        'Decision outcome completeness',
        'decision_outcome_non_null_and_valid',
        'STRUCTURAL',
        CASE
            WHEN null_decision_outcome_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('null_decision_outcome_rows=%s', null_decision_outcome_rows),
        'Every latest-run row should have a final decision_outcome.',
        'Final outcome completeness is required before decision distribution can be interpreted.'
    FROM latest

    UNION ALL

    SELECT
        'Final flag reconciliation',
        'exactly_one_final_decision_flag',
        'STRUCTURAL',
        CASE
            WHEN final_flag_reconciliation_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('final_flag_reconciliation_violation_rows=%s', final_flag_reconciliation_violation_rows),
        'Exactly one of approval_flag, counteroffer_flag, manual_review_flag, and decline_flag should be TRUE per row.',
        'Flag reconciliation confirms final decision taxonomy integrity.'
    FROM decision_flag_diag

    UNION ALL

    SELECT
        'Simulated offer-exposure convention',
        'offer_exposure_flag_reconciles_to_final_outcome',
        'STRUCTURAL',
        CASE
            WHEN simulated_offer_exposure_flag_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('simulated_offer_exposure_flag_violation_rows=%s', simulated_offer_exposure_flag_violation_rows),
        'simulated_offer_exposure_flag should be TRUE only for APPROVE and COUNTEROFFER.',
        'This confirms simulated positive offer exposure is not assigned to unresolved or no-offer outcomes.'
    FROM offer_flag_diag

    UNION ALL

    SELECT
        'Approved amount convention',
        'approved_amount_by_final_outcome',
        'STRUCTURAL',
        CASE
            WHEN approved_amount_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('approved_amount_convention_violation_rows=%s', approved_amount_convention_violation_rows),
        'APPROVE preserves requested amount; COUNTEROFFER reduces exposure; MANUAL_REVIEW remains NULL; DECLINE equals zero.',
        'Approved amount conventions validate final exposure assignment integrity.'
    FROM amount_diag

    UNION ALL

    SELECT
        'Approved Expected Loss convention',
        'approved_expected_loss_by_final_outcome',
        'STRUCTURAL',
        CASE
            WHEN approved_expected_loss_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('approved_expected_loss_convention_violation_rows=%s', approved_expected_loss_convention_violation_rows),
        'Approved Expected Loss should follow final exposure treatment conventions.',
        'This protects the requested versus approved Expected Loss distinction.'
    FROM expected_loss_diag

    UNION ALL

    SELECT
        'Reason-code completeness',
        'primary_reason_and_triggered_reason_list_present',
        'STRUCTURAL',
        CASE
            WHEN reason_code_completeness_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('reason_code_completeness_violation_rows=%s', reason_code_completeness_violation_rows),
        'Every row should have populated simulated reason-code fields.',
        'Reason-code completeness supports explainability and validation evidence.'
    FROM reason_diag

    UNION ALL

    SELECT
        'Reason-code family alignment',
        'primary_reason_family_reconciles_to_decision_outcome',
        'STRUCTURAL',
        CASE
            WHEN reason_family_alignment_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('reason_family_alignment_violation_rows=%s', reason_family_alignment_violation_rows),
        'Reason family should align to final decision outcome.',
        'Family alignment validates the simulated explanation-code framework.'
    FROM reason_diag

    UNION ALL

    SELECT
        'Prohibited terminology check',
        'external_communication_terms_absent',
        'BOUNDARY',
        CASE
            WHEN prohibited_external_communication_term_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT('prohibited_external_communication_term_rows=%s', prohibited_external_communication_term_rows),
        'Simulated strategy explanation codes should not use external communication terminology.',
        'This protects Module 2 interpretation boundaries.'
    FROM reason_diag

    UNION ALL

    SELECT
        'Product-level strategy distribution',
        'product_level_outcome_concentration_review',
        'DIAGNOSTIC',
        CASE
            WHEN product_count = 0 THEN 'NOT_APPLICABLE'
            WHEN max_single_product_outcome_share <= 0.900000 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'product_count=%s; max_single_product_outcome_share=%s',
            product_count,
            COALESCE(max_single_product_outcome_share::TEXT, '<NULL>')
        ),
        'Product-level outcomes should be reviewed for extreme concentration.',
        'High concentration may be valid but should be explained through product policy and risk structure.'
    FROM product_diag

    UNION ALL

    SELECT
        'Score-band strategy distribution',
        'score_band_directional_risk_review',
        'DIAGNOSTIC',
        CASE
            WHEN score_band_count = 0 THEN 'NOT_APPLICABLE'
            WHEN deep_subprime_avg_synthetic_estimated_pd_proxy >= super_prime_avg_synthetic_estimated_pd_proxy THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'score_band_count=%s; super_prime_avg_synthetic_estimated_pd_proxy=%s; deep_subprime_avg_synthetic_estimated_pd_proxy=%s',
            score_band_count,
            COALESCE(super_prime_avg_synthetic_estimated_pd_proxy::TEXT, '<NULL>'),
            COALESCE(deep_subprime_avg_synthetic_estimated_pd_proxy::TEXT, '<NULL>')
        ),
        'Weaker score bands should generally carry higher synthetic estimated-risk proxy values.',
        'Score-band behavior supports directional risk-ordering validation.'
    FROM score_diag

    UNION ALL

    SELECT
        'Synthetic risk ordering',
        'offer_rows_vs_decline_rows_synthetic_estimated_risk',
        'DIAGNOSTIC',
        CASE
            WHEN simulated_offer_exposure_rows = 0 OR decline_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN avg_synthetic_estimated_pd_proxy_offer_rows <= avg_synthetic_estimated_pd_proxy_decline_rows THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'offer_rows=%s; decline_rows=%s; avg_offer_synthetic_estimated_pd_proxy=%s; avg_decline_synthetic_estimated_pd_proxy=%s',
            simulated_offer_exposure_rows,
            decline_rows,
            COALESCE(avg_synthetic_estimated_pd_proxy_offer_rows::TEXT, '<NULL>'),
            COALESCE(avg_synthetic_estimated_pd_proxy_decline_rows::TEXT, '<NULL>')
        ),
        'Offered rows should generally have lower synthetic estimated-risk proxy than declined rows.',
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
        'decline_zero_exposure_and_reason_convention',
        'DIAGNOSTIC',
        CASE
            WHEN decline_rows = 0 THEN 'NOT_APPLICABLE'
            WHEN decline_zero_exposure_or_reason_convention_violation_rows = 0 THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'decline_rows=%s; decline_zero_exposure_or_reason_convention_violation_rows=%s',
            decline_rows,
            decline_zero_exposure_or_reason_convention_violation_rows
        ),
        'DECLINE rows should have approved_amount = 0, approved_expected_loss_amount = 0, and POLICY_STOP reason family.',
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
            'mixed_signal_rows=%s; borderline_rows=%s; residual_review_rows=%s; mixed_signal_manual_review_rows=%s',
            mixed_signal_rows,
            borderline_rows,
            residual_review_rows,
            mixed_signal_manual_review_rows
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
             AND current_archived_slice_distinct_application_id_count = latest_run_distinct_application_id_count
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
        FORMAT('readiness_status=%s', COALESCE(readiness_status, '<NULL>')),
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
            COALESCE(source_consistency_status, '<NULL>'),
            COALESCE(matched_application_count::TEXT, '<NULL>'),
            COALESCE(source_field_mismatch_count::TEXT, '<NULL>')
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


/*-----------------------------------------------------------------------------------------------
14.19A Display final compact validation status summary.

Interpretation:
    REVIEW rows are shown first because they require interpretation before documentation.
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
14.19B Validation status distribution.

Interpretation:
    Compact summary of the number of PASS, REVIEW, and NOT_APPLICABLE validation rows.
-----------------------------------------------------------------------------------------------*/

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
    3. Product-level behavior can be reviewed.
    4. Score-band behavior can be reviewed.
    5. Product × score behavior can be reviewed.
    6. Synthetic estimated-risk ordering can be reviewed.
    7. Requested PTI and affordability sensitivity can be reviewed.
    8. DTI capacity behavior can be reviewed.
    9. Requested versus approved exposure can be reviewed.
    10. Requested versus approved Expected Loss can be reviewed.
    11. Counteroffer behavior can be validated.
    12. Manual-review unresolved behavior can be validated.
    13. Decline / simulated policy-stop behavior can be validated.
    14. Simulated reason-code coverage and family alignment can be validated.
    15. Simulated offer-exposure profile can be reviewed.
    16. Mixed-signal and edge-case profiles can be inspected.
    17. Final output conventions can be tested through diagnostic violation counts.
    18. Archive readiness can be reviewed.
    19. Matched strategy comparison readiness can be reviewed.
    20. Matched source-field consistency can be reviewed.
    21. tmp_m2_validation_status_summary is available as a compact validation status output.

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
<!-- END_MESSAGE C038-M00758 -->


---

<a id="c038-m00760"></a>

### C038-M00760

**Andrew** · 2026-05-09T18:10:40.772000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00760 -->
I'm going to provide section 14 in sections instead of the full thing at one time.   here is section 14 header + sections 14.1 - 14.5.  please follow the same process we've been following and return it at an elite, commentary level. please give me updated section 14 header + section 14.1-14.5 at that elite commentary/header level as a copy paste.
<!-- END_MESSAGE C038-M00760 -->


---

<a id="c038-m00762"></a>

### C038-M00762

**Andrew** · 2026-05-09T18:11:51.443000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00762 -->
I'm going to provide section 14 in sections instead of the full thing at one time. here is section 14 header + sections 14.1 - 14.5. please follow the same process we've been following and return it at an elite, commentary level. please give me updated section 14 header + section 14.1-14.5 at that elite commentary/header level as a copy paste.
<!-- END_MESSAGE C038-M00762 -->


**Attachments in export:** `Pasted text(125).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_30.md) · [Next](Part_32.md)
