# Module 2 Decision Simulator Build

## Part 51

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_50.md) · [Next](Part_52.md)

<a id="c038-m00980"></a>

### C038-M00980

**ChatGPT** · 2026-05-10T01:21:52.242194-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00980 -->
Below is the full copy-paste replacement for **Section 14 header through Section 14.3**, with the commentary upgraded to the instructional level you described. I added **Section 14.0** as the dependency preflight and expanded the query-level and inline SQL commentary so reviewers know what each output means, what to look for, and how the SQL is producing the result. fileciteturn104file0

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

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm whether the latest-run strategy behavior is directionally coherent across final
        outcomes, offer exposure, product mix, score-band behavior, affordability pressure, DTI,
        counteroffer treatment, manual-review burden, decline drivers, and simulated reason-code
        explanations.

    Model governance / validation reviewers:
        Confirm whether output conventions, reason-code boundaries, source lineage, row grain,
        and simulation limitations are clearly respected.

    SQL reviewers:
        Confirm that diagnostic queries are read-only, that denominators are safe, that grouping
        logic is interpretable, and that QA outputs are not mutating latest-run or archive rows.

    Executive / portfolio reviewers:
        Use the summarized QA outputs to support a confident story about what the strategy did, what
        changed, what requires review, and what evidence should be carried into the Validation
        Summary or executive narrative.

WHEN TO RUN THIS SECTION:
    Run Section 14 after Section 11 has materialized:

        credit_decisioning_sim.strategy_decisions

    Run Section 12 before Section 14 when archive-readiness diagnostics should confirm that the
    current latest-run slice has been archived.

    Run Section 13 before Section 14 when matched strategy comparison readiness and matched
    source-field consistency evidence should be available for the final validation status summary.

HOW TO READ SECTION 14 OUTPUTS:
    Section 14 is a diagnostic evidence package.

    For each query, reviewers should ask:

        1. Does the output preserve the expected grain?
        2. Does the output align with locked strategy conventions?
        3. Does the output show intuitive credit-risk ordering?
        4. Does the output show any concentration that needs review?
        5. Does the output support the executive story we expect to tell?
        6. Does the output reveal a validation issue or simply an expected strategy tradeoff?

    Section 14 does not require every result to look "clean" in a simplistic way.

    For example:
        higher decline rates in weaker score bands may be expected;
        higher counteroffer rates in high requested-PTI segments may be expected;
        higher policy-stop reason-code concentration under a tighter risk strategy may be expected;
        mixed-signal rows may be valid and realistic.

    The key question is whether the pattern is explainable, bounded, and consistent with the strategy
    design.

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

SQL CONCEPTS TAUGHT IN THIS SECTION:
    COUNT(*):
        Counts rows in the current validation group.

    COUNT(DISTINCT ...):
        Confirms grain and scope, such as one row per application_id and one strategy / scenario
        slice in the latest-run output.

    COUNT(*) FILTER (WHERE ...):
        Calculates conditional counts without removing the rest of the population from the query.

    AVG(...):
        Summarizes average borrower, affordability, exposure, and Expected Loss behavior.

    COALESCE(..., 0):
        Converts unresolved manual-review rows or zero-offer rows to zero when calculating
        all-application portfolio impact metrics.

    FILTER (WHERE simulated_offer_exposure_flag IS TRUE):
        Restricts metrics to final APPROVE and COUNTEROFFER rows when the goal is to describe the
        economics of simulated positive offer-exposure outcomes.

    NULLIF(denominator, 0):
        Prevents divide-by-zero in rates and percentages.

    CASE:
        Converts diagnostic conditions into readable status labels or custom sort order.

    BTRIM:
        Treats blank text fields as missing rather than allowing whitespace-only metadata to appear
        valid.

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
SECTION 14.0 — SECTION 14 DEPENDENCY PREFLIGHT AND READ-ONLY QA SCOPE GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the completed latest-run Module 2 output exists and is structurally available before
    the Section 14 validation queries begin.

    Section 14.0 answers:

        "Can Section 14 safely read the latest-run strategy output and produce validation evidence?"

SQL PURPOSE:
    1. Confirm credit_decisioning_sim.strategy_decisions exists.
    2. Confirm credit_decisioning_sim.strategy_decisions contains rows.
    3. Confirm the latest-run output contains the minimum column set required for Section 14.0–14.3.
    4. Provide non-failing context on archive and comparison-helper availability.
    5. Preserve Section 14 as a read-only validation layer.
    6. Fail clearly if Section 14 is run before latest-run output materialization.

WHY THIS PREFLIGHT EXISTS:
    Section 14 references many fields across many diagnostic queries.

    If the latest-run table is missing, empty, or missing key columns, the validation section should
    fail with a clear instructional message before producing partial or misleading diagnostics.

WHAT THIS PREFLIGHT DOES NOT VALIDATE:
    Section 14.0 does not decide whether the strategy behavior is acceptable.

    Later Section 14 diagnostics review:
        final outcome distribution,
        flag reconciliation,
        product behavior,
        score-band behavior,
        affordability behavior,
        DTI behavior,
        exposure conventions,
        Expected Loss conventions,
        counteroffer feasibility,
        manual-review behavior,
        reason-code behavior,
        edge cases,
        archive readiness,
        and comparison readiness.

WHY ARCHIVE AND COMPARISON HELPERS ARE NOT FAIL-FAST REQUIREMENTS HERE:
    The latest-run QA target is credit_decisioning_sim.strategy_decisions.

    Archive and comparison diagnostics are supporting context.

    A formal campaign run should execute Sections 12 and 13 before Section 14 so archive-readiness,
    comparison-readiness, and matched source-field consistency can be reviewed.

    This preflight surfaces their availability with NOTICE messages rather than blocking the first
    latest-run QA diagnostics.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    TO_REGCLASS:
        Checks whether a table exists before the validation framework references it.

    information_schema.columns:
        Checks whether the latest-run table contains required validation columns.

    VALUES:
        Creates an inline table of required column names.

    STRING_AGG:
        Converts missing required column names into a readable exception message.

    RAISE EXCEPTION:
        Stops Section 14 when required validation targets are not available.

    RAISE NOTICE:
        Prints helpful non-failing context about object availability.

READ-ONLY BOUNDARY:
    Section 14.0 does not insert rows.
    Section 14.0 does not delete rows.
    Section 14.0 does not update rows.
    Section 14.0 does not create or modify latest-run output.
    Section 14.0 does not create or modify archive output.
    Section 14.0 does not recalculate decisions.
    Section 14.0 does not recalculate approved exposure.
    Section 14.0 does not recalculate approved Expected Loss.
    Section 14.0 does not reassign simulated reason codes.
    Section 14.0 does not modify strategy parameters.
    Section 14.0 does not modify product policy parameters.
    Section 14.0 does not insert evidence rows.

***************************************************************************************************/

DO $$
DECLARE
    /***********************************************************************************************
    Object availability diagnostics.

    These Boolean variables confirm whether the permanent latest-run table and supporting context
    objects exist before Section 14 references them.
    ***********************************************************************************************/
    v_latest_run_table_exists BOOLEAN;
    v_archive_table_exists BOOLEAN;
    v_comparison_readiness_exists BOOLEAN;
    v_source_consistency_exists BOOLEAN;

    /***********************************************************************************************
    Latest-run row-count diagnostic.

    Section 14 is meaningful only when the latest-run output contains applicant-level rows.
    ***********************************************************************************************/
    v_latest_run_row_count BIGINT;

    /***********************************************************************************************
    Required-column diagnostic.

    If any required latest-run column is missing, Section 14 should fail with a clear list rather
    than producing a later, less-informative SQL error.
    ***********************************************************************************************/
    v_missing_required_columns TEXT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    14.0A Confirm latest-run output table exists.

    Business purpose:
        Section 14 validates the completed latest-run Module 2 output.

        That output is materialized in Section 11 as:
            credit_decisioning_sim.strategy_decisions

    SQL mechanics:
        TO_REGCLASS returns NULL when the object is absent.

    Failure interpretation:
        Section 11 has not run successfully, or the latest-run table was dropped after Section 11.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO v_latest_run_table_exists;

    IF v_latest_run_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 14 failure: credit_decisioning_sim.strategy_decisions does not exist. Run Section 11 before Section 14.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    14.0B Confirm latest-run output contains rows.

    Business purpose:
        A zero-row latest-run output cannot support meaningful strategy QA, product diagnostics,
        score-band diagnostics, reason-code review, exposure review, or validation-status evidence.

    SQL mechanics:
        COUNT(*) counts the applicant-level rows available for validation.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_run_row_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_run_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 14 failure: credit_decisioning_sim.strategy_decisions contains zero rows.';
    END IF;

    RAISE NOTICE
        'Module 2 Section 14 preflight: latest-run output contains % row(s).',
        v_latest_run_row_count;


    /*-------------------------------------------------------------------------------------------
    14.0C Confirm latest-run output contains the minimum validation column set used in Sections
    14.0 through 14.3.

    Business purpose:
        Sections 14.1–14.3 validate scope, structural integrity, final outcome distribution, final
        flag reconciliation, preliminary-to-final routing, exposure economics, and Expected Loss
        summaries.

        Missing any of the required fields below would make those diagnostics incomplete or invalid.

    SQL mechanics:
        The VALUES clause creates the required column list.

        information_schema.columns checks whether each required column exists in
        credit_decisioning_sim.strategy_decisions.

        STRING_AGG returns a comma-separated list of missing columns.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(required_columns.column_name, ', ' ORDER BY required_columns.column_name)
    INTO v_missing_required_columns
    FROM (
        VALUES
            /***************************************************************************************
            Strategy identity and latest-run audit fields.
            ***************************************************************************************/
            ('module2_model_version'),
            ('strategy_set_name'),
            ('strategy_name'),
            ('strategy_version'),
            ('strategy_run_id'),
            ('strategy_run_ts'),
            ('latest_output_created_ts'),

            /***************************************************************************************
            Archive controls and Module 1 lineage.
            ***************************************************************************************/
            ('archive_run_flag'),
            ('strategy_archive_reset_mode'),
            ('module1_input_source'),
            ('module1_source_table_name'),
            ('module1_model_version'),
            ('module1_scenario_set_name'),
            ('module1_scenario_name'),
            ('population_id'),
            ('anchor_date'),

            /***************************************************************************************
            Application and applicant identifiers.
            ***************************************************************************************/
            ('application_id'),
            ('applicant_id'),

            /***************************************************************************************
            Product, score, requested-structure, synthetic risk, LGD, and requested Expected Loss.
            ***************************************************************************************/
            ('product_type_policy_key'),
            ('score_band_policy_key'),
            ('credit_score'),
            ('requested_amount'),
            ('requested_monthly_payment_proxy'),
            ('requested_payment_to_income_ratio'),
            ('estimated_pd'),
            ('estimated_lgd'),
            ('requested_expected_loss_amount'),

            /***************************************************************************************
            Preliminary routing and final outcome fields used in Section 14.3.
            ***************************************************************************************/
            ('preliminary_decision_outcome'),
            ('decision_outcome'),
            ('decision_path'),
            ('decision_resolution_source'),

            /***************************************************************************************
            Final outcome flags and simulated offer-exposure flag.
            ***************************************************************************************/
            ('approval_flag'),
            ('counteroffer_flag'),
            ('manual_review_flag'),
            ('decline_flag'),
            ('simulated_offer_exposure_flag'),

            /***************************************************************************************
            Final approved exposure, affordability, and approved Expected Loss fields.
            ***************************************************************************************/
            ('approved_amount'),
            ('approved_payment_to_income_ratio'),
            ('approved_expected_loss_amount'),

            /***************************************************************************************
            Simulated reason-code fields.
            ***************************************************************************************/
            ('primary_reason_code'),
            ('primary_reason_family'),
            ('triggered_reason_code_list')
    ) AS required_columns(column_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = 'credit_decisioning_sim'
          AND c.table_name = 'strategy_decisions'
          AND c.column_name = required_columns.column_name
    );

    IF v_missing_required_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 14 failure: credit_decisioning_sim.strategy_decisions is missing required Section 14 validation column(s): %.',
            v_missing_required_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    14.0D Surface supporting context availability.

    Business purpose:
        Section 14 later uses archive and comparison helper objects for readiness diagnostics.

        The first latest-run QA blocks do not need those objects, but the user should know whether
        they are available.

    Interpretation:
        Missing archive or comparison helpers does not invalidate Sections 14.1–14.3.

        For formal full campaign evidence, run:
            Section 12 for archive context.
            Section 13 for matched comparison readiness and matched source-field consistency.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NOT NULL
    INTO v_archive_table_exists;

    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_comparison_readiness'),
        TO_REGCLASS('tmp_m2_strategy_comparison_readiness')
    ) IS NOT NULL
    INTO v_comparison_readiness_exists;

    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_comparison_source_consistency'),
        TO_REGCLASS('tmp_m2_strategy_comparison_source_consistency')
    ) IS NOT NULL
    INTO v_source_consistency_exists;

    IF v_archive_table_exists IS DISTINCT FROM TRUE THEN
        RAISE NOTICE
            'Module 2 Section 14 preflight: strategy_decisions_archive is not available. Archive-readiness diagnostics should be treated as not applicable until Section 12 has run.';
    END IF;

    IF v_comparison_readiness_exists IS DISTINCT FROM TRUE THEN
        RAISE NOTICE
            'Module 2 Section 14 preflight: tmp_m2_strategy_comparison_readiness is not available. Matched comparison readiness should be treated as not applicable until Section 13 has run.';
    END IF;

    IF v_source_consistency_exists IS DISTINCT FROM TRUE THEN
        RAISE NOTICE
            'Module 2 Section 14 preflight: tmp_m2_strategy_comparison_source_consistency is not available. Matched source-field consistency should be treated as not applicable until Section 13 has run.';
    END IF;
END $$;



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

WHAT TO LOOK FOR:
    latest_run_rows:
        Should be positive and should match latest_run_distinct_application_id_count.

    latest_run_distinct_strategy_count:
        Should equal 1.

    latest_run_distinct_module1_scenario_population_count:
        Should equal 1.

    validation_scope_status:
        Should be LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW.

REVIEW TRIGGERS:
    REVIEW_EMPTY_LATEST_RUN_OUTPUT:
        Section 11 did not produce usable output.

    REVIEW_DUPLICATE_APPLICATION_ID_IN_LATEST_RUN:
        The applicant-level grain is broken. Downstream QA should not be interpreted.

    REVIEW_MULTIPLE_STRATEGIES_IN_LATEST_RUN:
        The latest-run table is mixing more than one Module 2 strategy.

    REVIEW_MULTIPLE_MODULE1_SCENARIO_POPULATION_SLICES_IN_LATEST_RUN:
        The latest-run table is mixing more than one upstream Module 1 scenario / population slice.

WHY THIS SECTION EXISTS:
    Validation evidence should be scoped before it is interpreted.

    A latest-run strategy output should be evaluated as:
        one active Module 2 strategy,
        applied to one selected Module 1 scenario / population slice,
        producing one final simulated strategy outcome per synthetic application.

SQL TEACHING POINT:
    COUNT(DISTINCT application_id):
        Tests row-level grain.

    COUNT(DISTINCT (field1, field2, field3)):
        Tests whether a multi-column identity appears once in the output.

    MIN / MAX timestamp:
        Shows timestamp range without using timestamps as comparison keys.

    CASE:
        Converts structural checks into one readable validation_scope_status.

BOUNDARY:
    Section 14 validates simulation coherence and output consistency.

    It does not convert Module 2 into an operational decision system.
    It does not validate real applicant treatment.
    It does not validate calibrated default forecasting.
    It does not validate customer notices.
    It does not validate fair-lending conclusions.

***************************************************************************************************/

SELECT
    /***********************************************************************************************
    Constant label so the result grid is self-describing when copied into QA notes.
    ***********************************************************************************************/
    'MODULE_2_LATEST_RUN_VALIDATION_SCOPE' AS validation_scope_name,

    /***********************************************************************************************
    Row-count and grain checks.

    latest_run_rows:
        Total rows in the current latest-run output.

    latest_run_distinct_application_id_count:
        Number of unique application_id values.

    Expected:
        These two values should match.
    ***********************************************************************************************/
    COUNT(*) AS latest_run_rows,
    COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count,

    /***********************************************************************************************
    Strategy scope check.

    Expected:
        Exactly one distinct Module 2 strategy identity in the latest-run table.

    Why:
        credit_decisioning_sim.strategy_decisions is current-run output, not a multi-strategy archive.
    ***********************************************************************************************/
    COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version
    )) AS latest_run_distinct_strategy_count,

    /***********************************************************************************************
    Module 1 scenario / population scope check.

    Expected:
        Exactly one Module 1 scenario / population slice in the latest-run table.

    Why:
        Module 2 V1.0 latest-run output should represent one selected upstream population.
    ***********************************************************************************************/
    COUNT(DISTINCT (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) AS latest_run_distinct_module1_scenario_population_count,

    /***********************************************************************************************
    Timestamp metadata.

    These values support run traceability.

    They are not strategy comparison keys and should not be used to define archive replacement grain.
    ***********************************************************************************************/
    MIN(strategy_run_ts) AS min_strategy_run_ts,
    MAX(strategy_run_ts) AS max_strategy_run_ts,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,

    /***********************************************************************************************
    Human-readable scope status.

    SQL mechanics:
        CASE is evaluated top to bottom.

        The most severe scope issue is reported first.

    Interpretation:
        The expected ready value is:
            LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW
    ***********************************************************************************************/
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

Business purpose:
    Display the technical identity of the latest-run strategy slice.

Credit risk interpretation:
    Module 2 strategy identifiers describe the downstream strategy decision layer.

    Module 1 scenario identifiers describe the upstream synthetic population and risk environment.

    These concepts must remain separate. The same Module 2 strategy can be applied to different
    Module 1 scenarios, and the same Module 1 scenario can be tested under multiple Module 2
    strategies.

What to look for:
    One row for the completed latest-run strategy / Module 1 scenario / population slice.

    row_count should equal distinct_application_id_count.

Review triggers:
    Multiple rows indicate mixed scope, such as multiple strategies, multiple Module 1 slices, or
    inconsistent metadata.

    row_count different from distinct_application_id_count indicates duplicate application_id values.

SQL mechanics:
    GROUP BY returns one row for each unique combination of strategy metadata, archive controls, input
    source, and Module 1 lineage.

    COUNT(*) counts rows within that technical slice.

    COUNT(DISTINCT application_id) confirms whether the slice is unique at application_id.

Documentation use:
    This is the "run identity" table. It is useful for validation summary traceability and executive
    evidence notes.
-----------------------------------------------------------------------------------------------*/

SELECT
    /***********************************************************************************************
    Module 2 strategy identity.

    These fields identify the downstream strategy applied to the selected Module 1 population.
    ***********************************************************************************************/
    module2_model_version,

    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    /***********************************************************************************************
    Archive controls carried from the active strategy parameter card.

    These explain intended archive behavior but are not part of application-level grain.
    ***********************************************************************************************/
    archive_run_flag,
    strategy_archive_reset_mode,

    /***********************************************************************************************
    Module 1 input source.

    LATEST means the run consumed the replaceable Module 1 latest-run table.

    ARCHIVE means the run consumed a persisted Module 1 scenario archive slice, which is preferred
    for formal matched comparison.
    ***********************************************************************************************/
    module1_input_source,
    module1_source_table_name,

    /***********************************************************************************************
    Module 1 lineage.

    These fields identify the upstream scenario / population used as the synthetic applicant source.
    ***********************************************************************************************/
    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,

    /***********************************************************************************************
    Row-count and grain confirmation for this exact technical scope.
    ***********************************************************************************************/
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
    /***********************************************************************************************
    Order output by stable technical lineage so repeated runs are easier to compare visually.
    ***********************************************************************************************/
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

WHAT TO LOOK FOR:
    This query is a compact "structural health card."

    The strongest pattern is:
        total_rows > 0,
        duplicate_application_row_count = 0,
        distinct_strategy_version_count = 1,
        distinct_module1_scenario_population_count = 1,
        all null_or_blank_* and null_* counts = 0.

REVIEW TRIGGERS:
    Duplicate application rows:
        Application-level QA, reason-code counts, exposure totals, and evidence capture may be
        overstated.

    Multiple strategy identities:
        The latest-run table may have been contaminated by a prior output or improper append.

    Missing lineage:
        Archive persistence, comparison, and evidence capture become difficult to trace.

    Missing decision or reason-code fields:
        Section 9 or Section 10 may not have completed correctly.

SQL TEACHING POINT:
    COUNT(*) - COUNT(DISTINCT application_id):
        Quickly computes duplicate row surplus at application_id grain.

    COUNT(*) FILTER (WHERE condition):
        Counts rows that meet a specific defect condition without filtering the full result.

    BTRIM(field) = '':
        Treats whitespace-only text as blank.

BOUNDARY:
    These are diagnostic checks.

    Earlier sections contain fail-fast gatekeepers. Section 14.2 provides documentation-ready
    evidence that the latest-run output remains structurally coherent.

***************************************************************************************************/

SELECT
    /***********************************************************************************************
    Basic row-count and application-level grain.
    ***********************************************************************************************/
    COUNT(*) AS total_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    /***********************************************************************************************
    Duplicate surplus.

    Expected:
        zero.

    Interpretation:
        A positive value means total rows exceed distinct application_id values.
    ***********************************************************************************************/
    COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_row_count,

    /***********************************************************************************************
    Strategy scope.

    Expected:
        one distinct strategy identity.
    ***********************************************************************************************/
    COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version
    )) AS distinct_strategy_version_count,

    /***********************************************************************************************
    Module 1 scenario / population scope.

    Expected:
        one distinct Module 1 scenario / population identity.
    ***********************************************************************************************/
    COUNT(DISTINCT (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) AS distinct_module1_scenario_population_count,

    /***********************************************************************************************
    Identifier completeness.

    application_id is the row-level latest-run grain.
    applicant_id supports applicant lineage.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE application_id IS NULL) AS null_application_id_rows,
    COUNT(*) FILTER (WHERE applicant_id IS NULL) AS null_applicant_id_rows,

    /***********************************************************************************************
    Module 2 strategy metadata completeness.

    These fields identify the downstream strategy. Blank strings are treated as missing.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Module 1 lineage completeness.

    These fields identify the upstream scenario / population.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Final decision and reason-code completeness.

    Missing final decisions or primary reason codes would prevent outcome and explanation QA.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE decision_outcome IS NULL)
        AS null_decision_outcome_rows,

    COUNT(*) FILTER (WHERE primary_reason_code IS NULL)
        AS null_primary_reason_code_rows,

    /***********************************************************************************************
    Requested Expected Loss completeness.

    requested_expected_loss_amount is needed to compare requested-exposure economics to final
    approved-exposure economics.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE requested_expected_loss_amount IS NULL)
        AS null_requested_expected_loss_amount_rows,

    /***********************************************************************************************
    Latest-run materialization timestamp range.

    This supports audit traceability only.
    ***********************************************************************************************/
    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
14.2A Row count by Module 1 input source.

Business purpose:
    Confirm whether the latest-run output was sourced from the Module 1 latest-run table or a Module
    1 scenario archive slice.

Credit risk interpretation:
    ARCHIVE source is preferred for formal strategy comparison because it preserves the exact upstream
    Module 1 scenario slice used for controlled matched comparison.

What to look for:
    One row.

    row_count should equal distinct_application_id_count.

Review triggers:
    More than one input source or source table indicates mixed source selection.

    LATEST source may be acceptable for development, but formal campaign documentation should use
    ARCHIVE when the goal is controlled scenario / strategy comparison.

SQL mechanics:
    GROUP BY splits the latest-run output by module1_input_source and module1_source_table_name.

    COUNT(DISTINCT application_id) confirms whether each source group is unique at application grain.

Documentation use:
    Use this output to explain whether the run was development-style latest-run consumption or formal
    archived-scenario consumption.
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

Business purpose:
    Surface duplicate application_id values directly if the structural summary reports duplicates.

Expected:
    zero rows.

Credit risk interpretation:
    application_id is the row-level latest-run grain for Module 2 V1.0.

    Duplicate application rows would distort approval rates, offer-exposure rates, approved amount
    totals, approved Expected Loss totals, reason-code counts, archive persistence, comparison, and
    evidence capture.

What to look for:
    No rows returned.

Review triggers:
    Any returned row requires immediate review before interpreting downstream QA.

SQL mechanics:
    GROUP BY application_id collapses rows by application.

    HAVING COUNT(*) > 1 keeps only duplicated application_id groups.

    ORDER BY duplicate count descending puts the worst duplication groups first.

    LIMIT 100 keeps the diagnostic sample bounded.

Documentation use:
    If zero rows, this query supports the validation statement that application-level latest-run grain
    is preserved.
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

Business purpose:
    Surface missing fields needed for latest-run QA interpretation.

Credit risk interpretation:
    The strategy output must preserve enough information to explain the simulated result:
        strategy identity,
        source lineage,
        product / score segmentation,
        requested structure,
        synthetic estimated-risk proxy,
        LGD,
        requested Expected Loss,
        final outcome,
        final path,
        decision resolution source,
        and simulated reason codes.

Expected:
    All missing_* counts should be zero.

Review triggers:
    Any nonzero count should be reviewed before documentation.

    Missing requested-structure or risk-economics fields weakens risk and affordability interpretation.

    Missing decision or reason-code fields means the final strategy output is not explainable.

SQL mechanics:
    COUNT(*) FILTER (WHERE condition) creates one missing-field count per required field family.

    BTRIM catches blank strings that would otherwise appear non-null.

Documentation use:
    This query provides compact evidence that the output is documentation-ready from a field
    completeness perspective.
-----------------------------------------------------------------------------------------------*/

SELECT
    /***********************************************************************************************
    Strategy run metadata completeness.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Product / score and borrower-quality fields.

    These are needed for product, score-band, and product × score validation later in Section 14.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Requested-structure and risk-economics fields.

    These fields are needed to validate affordability, synthetic estimated-risk ordering, requested
    Expected Loss, approved Expected Loss, and exposure treatment.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Final decision fields.

    These fields are needed before any decision distribution, migration, or final convention QA can
    be interpreted.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Simulated reason-code fields.

    These fields make final strategy outcomes explainable.
    ***********************************************************************************************/
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

WHAT TO LOOK FOR:
    The outcome distribution should align with the active strategy posture.

    For a tighter risk strategy, reviewers may expect:
        lower simulated offer exposure,
        higher decline or manual-review share,
        lower approved Expected Loss,
        or stronger reason-code concentration in risk-tightening families.

    For a growth strategy, reviewers may expect:
        higher simulated offer exposure,
        higher approved amount,
        potentially higher approved Expected Loss,
        and more acceptance of marginal risk segments.

REVIEW TRIGGERS:
    A high manual-review rate is not automatically invalid, but it may indicate operational burden.

    A high counteroffer rate is not automatically invalid, but it may indicate dependence on
    reduced-exposure treatment.

    A high decline rate is not automatically invalid, but it should align with the strategy posture
    and reason-code story.

    APPROVE or COUNTEROFFER rows with unusually high average approved Expected Loss should be reviewed
    later in Expected Loss diagnostics.

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

SQL TEACHING POINT:
    GROUP BY decision_outcome:
        Creates one row per final outcome.

    SUM(COUNT(*)) OVER ():
        Window aggregate that computes the total population denominator while still returning one row
        per decision_outcome.

    FILTER:
        Counts flags within each outcome group without changing the grouped population.

    COALESCE:
        Treats unresolved or no-offer approved exposure / Expected Loss as zero for all-application
        portfolio-impact metrics.

    FILTER (WHERE simulated_offer_exposure_flag IS TRUE):
        Restricts averages to APPROVE and COUNTEROFFER rows when measuring offer-row economics.

DOCUMENTATION USE:
    This query is the first table to summarize the executive story, but it should be paired with
    product, score, affordability, exposure, Expected Loss, counteroffer, and reason-code diagnostics
    before final narrative drafting.

***************************************************************************************************/

SELECT
    /***********************************************************************************************
    Final simulated strategy outcome.

    Expected values:
        APPROVE
        COUNTEROFFER
        MANUAL_REVIEW
        DECLINE
    ***********************************************************************************************/
    decision_outcome,

    /***********************************************************************************************
    Outcome count and population share.

    pct_of_population uses the total latest-run population as the denominator.
    ***********************************************************************************************/
    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_population,

    /***********************************************************************************************
    Final flag counts by outcome group.

    Expected:
        In the APPROVE group, approval_flag_count should equal row_count.
        In the COUNTEROFFER group, counteroffer_flag_count should equal row_count.
        In the MANUAL_REVIEW group, manual_review_flag_count should equal row_count.
        In the DECLINE group, decline_flag_count should equal row_count.

    These fields support quick visual flag reconciliation.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE approval_flag IS TRUE)
        AS approval_flag_count,

    COUNT(*) FILTER (WHERE counteroffer_flag IS TRUE)
        AS counteroffer_flag_count,

    COUNT(*) FILTER (WHERE manual_review_flag IS TRUE)
        AS manual_review_flag_count,

    COUNT(*) FILTER (WHERE decline_flag IS TRUE)
        AS decline_flag_count,

    /***********************************************************************************************
    Simulated positive offer-exposure count.

    Expected:
        TRUE for APPROVE and COUNTEROFFER.
        FALSE for MANUAL_REVIEW and DECLINE.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_flag_count,

    /***********************************************************************************************
    Average synthetic estimated-risk proxy.

    estimated_pd remains the SQL field name, interpreted as the synthetic estimated-PD proxy.

    Review:
        DECLINE or MANUAL_REVIEW rows may have higher average estimated_pd under risk-sensitive
        strategies.
    ***********************************************************************************************/
    AVG(estimated_pd)
        AS avg_synthetic_estimated_pd_proxy,

    /***********************************************************************************************
    Average requested PTI.

    This describes requested-structure affordability pressure before final approved exposure
    treatment.
    ***********************************************************************************************/
    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    /***********************************************************************************************
    All-application approved amount average.

    COALESCE converts unresolved manual-review and no-offer rows to zero.

    Use:
        Portfolio-level approved-exposure impact across the full latest-run population.
    ***********************************************************************************************/
    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_apps,

    /***********************************************************************************************
    Offer-row approved amount average.

    FILTER restricts the average to rows with simulated positive offer exposure.

    Use:
        Economics of rows that actually received APPROVE or COUNTEROFFER.
    ***********************************************************************************************/
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    /***********************************************************************************************
    Requested-exposure Expected Loss average.

    This is the Module 1 requested-exposure Expected Loss carried into Module 2.
    ***********************************************************************************************/
    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    /***********************************************************************************************
    All-application approved Expected Loss average.

    COALESCE converts unresolved / no-offer rows to zero.

    Use:
        Portfolio-level approved Expected Loss impact across the full latest-run population.
    ***********************************************************************************************/
    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_all_apps,

    /***********************************************************************************************
    Offer-row approved Expected Loss average.

    Use:
        Approved Expected Loss among rows that received simulated positive offer exposure.
    ***********************************************************************************************/
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_expected_loss_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY
    /***********************************************************************************************
    Business-readable outcome ordering.

    APPROVE and COUNTEROFFER are simulated positive offer-exposure outcomes.
    MANUAL_REVIEW is unresolved.
    DECLINE is no-offer.
    ***********************************************************************************************/
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
14.3A Final decision-flag reconciliation distribution.

Business purpose:
    Confirm that exactly one final decision flag is TRUE for each latest-run row.

Credit risk interpretation:
    The final decision taxonomy should be mutually exclusive at the row level.

    A row should not be both APPROVE and DECLINE, or both COUNTEROFFER and MANUAL_REVIEW.

Expected:
    final_decision_flag_count = 1 for every row.

What to look for:
    One result row:
        final_decision_flag_count = 1
        row_count = full latest-run row count

Review triggers:
    final_decision_flag_count = 0:
        Row has decision_outcome but no final flag, or flags are missing.

    final_decision_flag_count > 1:
        Row has conflicting final outcome flags.

SQL mechanics:
    Boolean flags are cast to INT:
        TRUE becomes 1.
        FALSE becomes 0.
        NULL is handled through COALESCE(..., 0).

    The sum produces the number of active final decision flags per row.

Documentation use:
    This query is useful evidence that the final four-outcome taxonomy reconciles to the final flag
    fields.
-----------------------------------------------------------------------------------------------*/

SELECT
    /***********************************************************************************************
    Count how many final outcome flags are active on each row.

    Expected:
        exactly 1.
    ***********************************************************************************************/
    (
        COALESCE(approval_flag::INT, 0)
        + COALESCE(counteroffer_flag::INT, 0)
        + COALESCE(manual_review_flag::INT, 0)
        + COALESCE(decline_flag::INT, 0)
    ) AS final_decision_flag_count,

    /***********************************************************************************************
    Count how many rows have each flag-count pattern.
    ***********************************************************************************************/
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

Business purpose:
    Show how preliminary routing resolved after exposure treatment and final decision resolution.

Credit risk interpretation:
    This query connects:
        Section 7 preliminary route
        → Section 8 exposure-treatment feasibility
        → Section 9 final decision resolution.

    It helps reviewers understand whether preliminary routes resolved as expected.

What to look for:
    preliminary APPROVE:
        Should generally resolve to final APPROVE.

    preliminary COUNTEROFFER:
        May resolve to final COUNTEROFFER if feasibility passes.
        May resolve to MANUAL_REVIEW or DECLINE if feasibility fails, depending on
        failed_counteroffer_resolution.

    preliminary MANUAL_REVIEW:
        Should generally remain final MANUAL_REVIEW.

    preliminary DECLINE:
        Should generally remain final DECLINE.

Review triggers:
    Large unexpected migration from preliminary APPROVE to non-offer outcomes would require review.

    Large failed-counteroffer migration should be interpreted with Section 8 counteroffer feasibility
    diagnostics and Section 10 reason-code assignment.

SQL mechanics:
    GROUP BY preliminary_decision_outcome, decision_outcome, decision_resolution_source:
        Summarizes each route-to-outcome transition.

    SUM(COUNT(*)) OVER (PARTITION BY preliminary_decision_outcome):
        Calculates the denominator within each preliminary outcome group.

    pct_within_preliminary_outcome:
        Shows how each preliminary route resolved as a percentage of that preliminary route.

Documentation use:
    This query is useful for executive storytelling because it explains that final outcomes are not
    assigned in one opaque step; they are resolved through staged routing and feasibility logic.
-----------------------------------------------------------------------------------------------*/

SELECT
    /***********************************************************************************************
    Section 7 route before exposure treatment and final resolution.
    ***********************************************************************************************/
    preliminary_decision_outcome,

    /***********************************************************************************************
    Section 9 final simulated strategy outcome.
    ***********************************************************************************************/
    decision_outcome,

    /***********************************************************************************************
    Internal resolution label explaining how final outcome was confirmed or resolved.
    ***********************************************************************************************/
    decision_resolution_source,

    /***********************************************************************************************
    Number of rows in this preliminary-to-final transition.
    ***********************************************************************************************/
    COUNT(*) AS row_count,

    /***********************************************************************************************
    Percentage within the preliminary route.

    Example:
        If preliminary_decision_outcome = COUNTEROFFER, this percentage shows how much of the
        preliminary counteroffer population became final COUNTEROFFER, MANUAL_REVIEW, or DECLINE.
    ***********************************************************************************************/
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
    /***********************************************************************************************
    Business-readable ordering for preliminary route.
    ***********************************************************************************************/
    CASE preliminary_decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,

    /***********************************************************************************************
    Business-readable ordering for final outcome.
    ***********************************************************************************************/
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,

    decision_resolution_source;
```
<!-- END_MESSAGE C038-M00980 -->


---

<a id="c038-m00981"></a>

### C038-M00981

**Andrew** · 2026-05-10T01:24:06.017000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00981 -->
as requested, let's start with section 14.4 through section 14.6. let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 14.4-14.6 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00981 -->


**Attachments in export:** `Pasted text(154).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00984"></a>

### C038-M00984

**ChatGPT** · 2026-05-10T01:28:29.000055-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00984 -->
Below is the full copy-paste replacement for **Section 14.4 through Section 14.6**, with expanded query-level interpretation guidance and inline SQL commentary explaining how the diagnostics work and what reviewers should look for. fileciteturn106file0

```sql
/***************************************************************************************************
SECTION 14.4 — PRODUCT-LEVEL STRATEGY QA
****************************************************************************************************

BUSINESS PURPOSE:
    Evaluate whether final simulated Module 2 strategy outcomes, approved exposure, requested
    Expected Loss, approved Expected Loss, affordability, synthetic estimated-risk profile, and
    simulated explanation-code patterns behave coherently across product types.

    Section 14.4 answers:

        "Does each product type behave in a way that is directionally intuitive, explainable, and
         consistent with product-aware strategy design?"

SQL PURPOSE:
    1. Summarize final decision outcomes by product.
    2. Calculate product-level outcome shares within each product.
    3. Compare requested exposure to approved exposure by product and outcome.
    4. Compare requested-exposure Expected Loss to approved-exposure Expected Loss by product and
       outcome.
    5. Summarize compact product-level decision rates.
    6. Review product-level simulated primary reason-code distributions.

WHY PRODUCT-LEVEL QA MATTERS:
    Product type is not a cosmetic segmentation field.

    Product type can materially affect:
        requested exposure,
        term structure,
        payment burden,
        requested PTI,
        LGD,
        requested Expected Loss,
        approved amount caps,
        counteroffer feasibility,
        approved exposure treatment,
        approved Expected Loss,
        final simulated outcome,
        and simulated explanation-code distribution.

    A portfolio-level approval rate can look reasonable while one product is behaving in a way that
    requires review. Product-level QA prevents that problem.

CREDIT RISK INTERPRETATION:
    Secured or collateralized products may show larger requested exposure, different LGD behavior,
    and different approved Expected Loss dynamics.

    Unsecured or revolving products may show more sensitivity to synthetic estimated-risk proxy,
    utilization, affordability, or product-specific guardrails.

    High product-level decline, manual-review, or counteroffer rates are not automatically defects.

    They should be explainable through:
        product policy thresholds,
        requested exposure,
        requested PTI,
        DTI,
        requested Expected Loss,
        approved Expected Loss cap,
        counteroffer feasibility,
        score mix,
        and reason-code distribution.

WHAT TO LOOK FOR:
    For each product:
        row counts should be nonzero where the product exists in the latest-run population;
        outcome mix should be explainable;
        simulated offer-exposure rate should align with product risk and product-policy posture;
        approved amount should not exceed requested amount;
        approved Expected Loss should be directionally coherent with approved exposure;
        reason-code distribution should explain product-level outcome concentration.

REVIEW TRIGGERS:
    A product with unusually high decline concentration:
        review synthetic risk, DTI, requested PTI, requested Expected Loss, and policy-stop reason
        codes.

    A product with unusually high manual-review concentration:
        review borderline profile, mixed-signal profile, failed counteroffer routing, and unresolved
        requested-structure diagnostics.

    A product with unusually high counteroffer concentration:
        review exposure caps, PTI target, approved Expected Loss cap, minimum counteroffer amount,
        and counteroffer feasibility diagnostics.

    A product with high approved Expected Loss among offer rows:
        review whether approved exposure, estimated_pd, estimated_lgd, and product approved-EL cap
        are behaving as designed.

METRIC CONVENTIONS:
    All-application approved metrics:
        use COALESCE(approved_amount, 0) or COALESCE(approved_expected_loss_amount, 0).

        This means unresolved manual-review rows and no-offer rows contribute zero to portfolio-level
        approved exposure or approved Expected Loss impact.

    Offer-row metrics:
        use FILTER (WHERE simulated_offer_exposure_flag IS TRUE).

        This means the metric describes only final APPROVE and final COUNTEROFFER rows.

    requested_expected_loss_amount:
        requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        approved-exposure Expected Loss after Module 2 final exposure treatment.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 14.4, estimated_pd is interpreted as the synthetic estimated-PD proxy.

    Section 14.4 does not recalculate estimated_pd.
    Section 14.4 does not validate calibrated default probabilities.
    Section 14.4 does not create a post-decision risk model.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies simulated positive offer-exposure outcomes only.

    It is TRUE for:
        APPROVE
        COUNTEROFFER

    It is FALSE for:
        MANUAL_REVIEW
        DECLINE

    It does not imply booked exposure, funded exposure, production approval, account creation, or real
    applicant treatment.

REASON-CODE BOUNDARY:
    primary_reason_code and primary_reason_family are simulated strategy explanation fields.

    They support product-level explainability.

    They are not customer communications, adverse-action notices, regulatory reason codes, production
    compliance determinations, or fair-lending conclusions.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CTE:
        product_outcome first summarizes product × decision_outcome metrics, then the outer SELECT
        adds within-product percentages.

    GROUP BY:
        groups rows by product and outcome so each product's strategy distribution is visible.

    WINDOW SUM:
        SUM(row_count) OVER (PARTITION BY product_type_policy_key) calculates the product-level
        denominator while preserving one row per product × outcome.

    FILTER:
        counts or averages only rows meeting a condition without removing the rest of the group.

    COALESCE:
        turns unresolved / no-offer approved exposure into zero for all-application portfolio-impact
        summaries.

    NULLIF:
        prevents divide-by-zero when calculating rates.

DOCUMENTATION USE:
    Section 14.4 outputs are strong candidates for:
        Validation Summary product-level behavior discussion,
        executive product-level story,
        README product diagnostics,
        and Section 16 segment evidence interpretation.

READ-ONLY BOUNDARY:
    Section 14.4 does not modify latest-run rows.
    Section 14.4 does not modify archive rows.
    Section 14.4 does not modify product policy parameters.
    Section 14.4 does not recalculate decisions, reason codes, approved exposure, or Expected Loss.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.4.1 Product × final outcome distribution with exposure and Expected Loss diagnostics.

Business purpose:
    Show how each product distributes across final simulated outcomes and how each product × outcome
    combination behaves economically.

Credit risk interpretation:
    This is the first product-level view because it shows not only outcome mix, but also the
    associated synthetic estimated-risk proxy, LGD, requested exposure, approved exposure, requested
    PTI, approved PTI, requested Expected Loss, and approved Expected Loss.

What to look for:
    Each product should have an explainable distribution across APPROVE, COUNTEROFFER, MANUAL_REVIEW,
    and DECLINE.

    Within-product percentages should sum to approximately 100 percent across outcomes for each
    product.

    Offer-row approved amount and approved Expected Loss should be populated only where simulated
    positive offer exposure exists.

Review triggers:
    Unexpected product concentration in DECLINE, MANUAL_REVIEW, or COUNTEROFFER should be connected
    to product policy, score mix, requested exposure, requested PTI, approved Expected Loss cap, and
    reason-code distribution.

SQL mechanics:
    The product_outcome CTE groups by product and final decision outcome.

    The outer query calculates pct_within_product using a window denominator:
        SUM(row_count) OVER (PARTITION BY product_type_policy_key)

    This avoids needing a second denominator join.

Documentation use:
    Use this output to explain the product-level strategy story before drilling into product-level
    reason codes.
-----------------------------------------------------------------------------------------------*/

WITH product_outcome AS (
    SELECT
        /*******************************************************************************************
        Product key used by Module 2 product-policy logic.
        *******************************************************************************************/
        product_type_policy_key,

        /*******************************************************************************************
        Final simulated strategy outcome assigned in Section 9.
        *******************************************************************************************/
        decision_outcome,

        /*******************************************************************************************
        Row count for this product × outcome combination.
        *******************************************************************************************/
        COUNT(*) AS row_count,

        /*******************************************************************************************
        Synthetic estimated-risk proxy and LGD averages.

        estimated_pd remains the Module 1 SQL field name and is interpreted as the synthetic
        estimated-PD proxy.
        *******************************************************************************************/
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(estimated_lgd) AS avg_estimated_lgd,

        /*******************************************************************************************
        Requested exposure average.

        This is the original requested amount from Module 1 before Module 2 exposure treatment.
        *******************************************************************************************/
        AVG(requested_amount) AS avg_requested_amount,

        /*******************************************************************************************
        All-application approved amount average.

        COALESCE treats unresolved manual-review rows and no-offer rows as zero so this metric
        reflects product-level portfolio impact across all applications in the product × outcome
        group.
        *******************************************************************************************/
        AVG(COALESCE(approved_amount, 0))
            AS avg_approved_amount_all_apps,

        /*******************************************************************************************
        Offer-row approved amount average.

        FILTER restricts the average to final APPROVE and COUNTEROFFER rows.

        This metric describes the approved exposure profile only among rows that received simulated
        positive offer exposure.
        *******************************************************************************************/
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        /*******************************************************************************************
        Requested PTI average.

        This is requested-structure affordability pressure before final approved exposure treatment.
        *******************************************************************************************/
        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        /*******************************************************************************************
        Offer-row approved PTI average.

        This describes final approved-exposure affordability among simulated positive offer-exposure
        rows.
        *******************************************************************************************/
        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows,

        /*******************************************************************************************
        Requested-exposure Expected Loss average.

        This value comes from Module 1 and reflects the original requested exposure.
        *******************************************************************************************/
        AVG(requested_expected_loss_amount)
            AS avg_requested_expected_loss_amount,

        /*******************************************************************************************
        All-application approved Expected Loss average.

        COALESCE treats unresolved / no-offer approved Expected Loss as zero for product-level
        portfolio-impact review.
        *******************************************************************************************/
        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,

        /*******************************************************************************************
        Offer-row approved Expected Loss average.

        This describes approved Expected Loss only among rows that received simulated positive offer
        exposure.
        *******************************************************************************************/
        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        /*******************************************************************************************
        Count of final simulated positive offer-exposure rows in this product × outcome group.

        For APPROVE and COUNTEROFFER groups, this should usually equal row_count.
        For MANUAL_REVIEW and DECLINE groups, this should usually equal zero.
        *******************************************************************************************/
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

    /***********************************************************************************************
    Percent of the product population represented by this final outcome.

    SQL mechanics:
        SUM(row_count) OVER (PARTITION BY product_type_policy_key) calculates the total number of
        rows in the product while preserving product × outcome rows in the output.

        NULLIF protects against divide-by-zero.
    ***********************************************************************************************/
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
    /***********************************************************************************************
    Product ordering first, then business-readable final outcome ordering.
    ***********************************************************************************************/
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

Business purpose:
    Provide one compact row per product for executive and validation review.

Credit risk interpretation:
    This query is the product-level "control card."

    It shows whether a product is producing more approvals, counteroffers, manual reviews, declines,
    simulated positive offer exposure, approved exposure, or approved Expected Loss than expected.

What to look for:
    approval_rate:
        Higher values indicate more as-requested positive offer outcomes.

    counteroffer_rate:
        Higher values indicate more reliance on reduced-exposure treatment.

    manual_review_rate:
        Higher values indicate more unresolved strategy outcomes and potential operational burden.

    decline_rate:
        Higher values indicate more no-offer outcomes.

    simulated_offer_exposure_rate:
        APPROVE + COUNTEROFFER rate; use this as the access / positive-offer metric.

    total_approved_amount:
        Product-level approved exposure impact.

    total_approved_expected_loss_amount:
        Product-level approved Expected Loss impact.

Review triggers:
    Product-level skew should not be judged only as "good" or "bad."

    It should be interpreted against:
        product exposure,
        product PTI thresholds,
        product Expected Loss thresholds,
        product approved amount caps,
        LGD,
        score mix,
        affordability mix,
        counteroffer feasibility,
        and reason-code distribution.

SQL mechanics:
    COUNT(*) FILTER calculates outcome-specific counts without excluding other rows.

    Dividing the filtered count by COUNT(*) creates a product-level rate.

    NULLIF(COUNT(*), 0) protects against divide-by-zero.

    COALESCE is used for all-application approved amount and approved Expected Loss totals so no-offer
    and unresolved rows contribute zero to product-level portfolio-impact metrics.

Documentation use:
    Use this query as the compact product-level table in the executive story and Validation Summary.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,

    /***********************************************************************************************
    Product population size.
    ***********************************************************************************************/
    COUNT(*) AS applications,

    /***********************************************************************************************
    Final APPROVE count and rate.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')
        AS approval_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    /***********************************************************************************************
    Final COUNTEROFFER count and rate.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS counteroffer_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    /***********************************************************************************************
    Final MANUAL_REVIEW count and rate.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
        AS manual_review_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS manual_review_rate,

    /***********************************************************************************************
    Final DECLINE count and rate.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
        AS decline_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    /***********************************************************************************************
    Simulated positive offer-exposure count and rate.

    TRUE for APPROVE and COUNTEROFFER only.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    /***********************************************************************************************
    Requested exposure and approved exposure totals.

    total_requested_amount:
        total applicant-requested exposure.

    total_approved_amount:
        final simulated approved exposure, with unresolved / no-offer rows contributing zero.
    ***********************************************************************************************/
    SUM(requested_amount) AS total_requested_amount,
    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

    /***********************************************************************************************
    Requested Expected Loss and approved Expected Loss totals.

    requested Expected Loss:
        based on original requested exposure.

    approved Expected Loss:
        based on final approved exposure after Module 2 strategy treatment.
    ***********************************************************************************************/
    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    /***********************************************************************************************
    Average synthetic estimated-risk proxy and requested affordability pressure.
    ***********************************************************************************************/
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    /***********************************************************************************************
    Offer-row approved PTI average.

    This metric describes approved affordability only for simulated positive offer-exposure rows.
    ***********************************************************************************************/
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY product_type_policy_key

ORDER BY product_type_policy_key;



/*-----------------------------------------------------------------------------------------------
14.4B Product-level primary reason-code distribution.

Business purpose:
    Confirm that product-level strategy outcomes remain explainable through simulated strategy
    explanation codes.

Credit risk interpretation:
    Product-level reason-code concentration helps explain why a product has higher approvals,
    higher counteroffers, higher manual reviews, or higher declines.

    For example:
        product exposure limit reasons may explain counteroffer concentration;
        high synthetic estimated-risk proxy reasons may explain decline concentration;
        requested-structure reasons may explain manual-review concentration;
        approved-as-requested reasons may explain approval concentration.

What to look for:
    Product reason-code distribution should align with the product-level decision-rate summary.

    A product with high counteroffer rate should generally show counteroffer-family reasons.

    A product with high decline rate should generally show policy-stop-family reasons.

    A product with high manual-review rate should generally show manual-review-family reasons.

Review triggers:
    High reason-code concentration is not automatically a defect.

    It means the product-level strategy story should explain why that reason dominates.

    Unexpected family alignment should be reviewed against Section 10 reason-code assignment and
    final decision family conventions.

SQL mechanics:
    GROUP BY product, outcome, reason family, and reason code creates one row per explanation pattern.

    SUM(COUNT(*)) OVER (PARTITION BY product_type_policy_key) provides the product-level denominator
    while preserving reason-code-level rows.

Documentation use:
    Use this query to explain product-level outcome concentration in validation or executive notes.

Boundary:
    Reason codes are simulated strategy explanation codes only.

    They are not customer communications, adverse-action reason codes, regulatory notices, or
    fair-lending conclusions.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,

    /***********************************************************************************************
    Number of rows in this product × outcome × reason-code combination.
    ***********************************************************************************************/
    COUNT(*) AS row_count,

    /***********************************************************************************************
    Percent of the product population represented by this reason-code pattern.

    This denominator is the whole product population, not only the final outcome population.

    That makes the result useful for product-level storytelling.
    ***********************************************************************************************/
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

BUSINESS PURPOSE:
    Validate whether final simulated Module 2 strategy outcomes behave directionally by borrower
    credit-quality segmentation while preserving realistic overlap.

    Section 14.5 answers:

        "Do stronger score bands generally receive more favorable simulated outcomes and weaker score
         bands generally show more review / no-offer pressure, while preserving realistic
         non-deterministic overlap?"

SQL PURPOSE:
    1. Summarize final decision outcomes by score band.
    2. Calculate score-band approval, counteroffer, manual-review, decline, and simulated
       offer-exposure rates.
    3. Review average credit score, synthetic estimated-risk proxy, DTI, requested PTI, requested
       Expected Loss, and approved Expected Loss by score-band outcome.
    4. Provide compact score-band decision-rate evidence.
    5. Review score-band reason-code distribution.

WHY SCORE-BAND QA MATTERS:
    Score band is a core borrower-quality segmentation dimension.

    It should generally align directionally with:
        synthetic estimated-risk proxy,
        final decision mix,
        simulated offer-exposure rate,
        manual-review rate,
        decline rate,
        requested Expected Loss,
        approved Expected Loss,
        and reason-code patterns.

CREDIT RISK INTERPRETATION:
    Stronger score bands should generally show:
        lower average synthetic estimated-risk proxy,
        higher approval rates,
        higher simulated offer-exposure rates,
        lower policy-stop concentration.

    Weaker score bands should generally show:
        higher average synthetic estimated-risk proxy,
        higher manual-review or decline rates,
        higher policy-stop or review-family reason-code concentration.

    Perfect monotonicity is not required at every micro-segment because product mix, requested PTI,
    DTI, exposure structure, behavioral signals, LGD, and product-specific policy rules can create
    realistic overlap.

WHY OVERLAP IS EXPECTED:
    Realistic portfolios contain:
        strong-score applicants with high requested PTI,
        weaker-score applicants with manageable requested PTI,
        high-income applicants with large requested exposure,
        lower-risk score bands with product-level exposure pressure,
        higher-risk score bands with lower exposure,
        and mixed-signal profiles that do not fit one-dimensional score logic.

    Section 14.5 should therefore be read as directional QA, not rigid deterministic ordering.

WHAT TO LOOK FOR:
    Average estimated_pd should generally increase from stronger to weaker score bands.

    Approval and simulated offer-exposure rates should generally be stronger in better score bands.

    Manual-review and decline rates should generally be higher in weaker score bands, subject to
    strategy design.

    Reason-code families should align with the final outcome families.

REVIEW TRIGGERS:
    A weak score band with very high approval rate:
        review product mix, requested PTI, requested exposure, and estimated_pd distribution.

    A strong score band with high decline or manual-review rate:
        review requested PTI, DTI, product exposure, requested Expected Loss, hard policy stops, and
        reason-code drivers.

    A score band with unexpected reason-code concentration:
        review Section 10 reason-code assignment and Section 6 trigger flags.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name and is interpreted as the synthetic
    estimated-PD proxy.

    Section 14.5 does not recalculate estimated_pd.
    Section 14.5 does not validate calibrated default probabilities.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss.

    approved_expected_loss_amount is approved-exposure Expected Loss.

    Score-band QA compares their behavior but does not recalculate either value.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    Multi-CTE pattern:
        score_summary calculates score-band-level rates.
        score_outcome calculates score-band × outcome metrics.
        the final SELECT joins them so outcome rows can carry full score-band rates.

    COUNT(*) FILTER:
        calculates outcome-specific counts and rates.

    NULLIF:
        protects rate calculations from divide-by-zero.

    Custom ORDER BY CASE:
        ensures score bands are displayed from strongest to weakest rather than alphabetically.

DOCUMENTATION USE:
    Score-band QA is one of the clearest evidence layers for explaining whether the strategy respects
    borrower-quality ordering while preserving realistic overlap.

READ-ONLY BOUNDARY:
    Section 14.5 does not modify latest-run rows.
    Section 14.5 does not modify archive rows.
    Section 14.5 does not recalculate decisions, reason codes, approved exposure, or Expected Loss.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.5.1 Score-band × final outcome distribution with score-band rates.

Business purpose:
    Show final outcome distribution by score band while carrying score-band-level decision rates into
    each outcome row.

Credit risk interpretation:
    This output combines:
        outcome concentration within each score band,
        average credit score,
        average synthetic estimated-risk proxy,
        DTI,
        requested PTI,
        requested Expected Loss,
        approved Expected Loss,
        and score-band-level final decision rates.

What to look for:
    Stronger score bands should generally show lower average estimated_pd and higher simulated
    offer-exposure rate.

    Weaker score bands should generally show higher average estimated_pd and higher review / decline
    pressure.

Review triggers:
    Large reversals in score-band ordering should be investigated, especially when not explained by
    product mix, affordability, DTI, exposure, or reason codes.

SQL mechanics:
    score_summary:
        one row per score band with overall score-band rates.

    score_outcome:
        one row per score band × final outcome with outcome-level averages.

    final SELECT:
        joins score_outcome to score_summary so each outcome row carries the overall score-band rate
        context.

Documentation use:
    Use this output to bridge high-level score-band strategy behavior and final outcome explanation.
-----------------------------------------------------------------------------------------------*/

WITH score_summary AS (
    SELECT
        score_band_policy_key,

        /*******************************************************************************************
        Score-band population size.
        *******************************************************************************************/
        COUNT(*) AS applications,

        /*******************************************************************************************
        Final decision rates by score band.

        Each numerator is calculated with FILTER.
        The denominator is the full score-band population.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        /*******************************************************************************************
        Simulated offer-exposure rate.

        TRUE for APPROVE and COUNTEROFFER.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY score_band_policy_key
),

score_outcome AS (
    SELECT
        score_band_policy_key,
        decision_outcome,

        /*******************************************************************************************
        Row count for each score-band × outcome combination.
        *******************************************************************************************/
        COUNT(*) AS row_count,

        /*******************************************************************************************
        Borrower-quality and risk diagnostics by score-band × outcome.
        *******************************************************************************************/
        AVG(credit_score) AS avg_credit_score,
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
        AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,

        /*******************************************************************************************
        Requested-structure affordability and requested-exposure Expected Loss.
        *******************************************************************************************/
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

        /*******************************************************************************************
        Approved-exposure Expected Loss across all applications in the group.

        COALESCE converts unresolved / no-offer rows to zero for all-application impact review.
        *******************************************************************************************/
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

    /***********************************************************************************************
    Percent of the score band represented by this outcome.

    Denominator comes from score_summary.applications.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Overall score-band rates repeated on each score-band × outcome row for review convenience.
    ***********************************************************************************************/
    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate

FROM score_outcome o

JOIN score_summary s
    ON s.score_band_policy_key = o.score_band_policy_key

ORDER BY
    /***********************************************************************************************
    Strongest-to-weakest score-band ordering.
    ***********************************************************************************************/
    CASE o.score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    /***********************************************************************************************
    Business-readable outcome ordering.
    ***********************************************************************************************/
    CASE o.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
14.5A Score-band decision-rate summary.

Business purpose:
    Provide a compact one-row-per-score-band profile for directional risk-ordering review.

Credit risk interpretation:
    This query is a fast score-band health card.

    It helps confirm whether borrower-quality segmentation aligns directionally with:
        credit score,
        synthetic estimated-risk proxy,
        requested PTI,
        DTI,
        approval rate,
        counteroffer rate,
        manual-review rate,
        decline rate,
        simulated offer-exposure rate,
        total approved exposure,
        and total approved Expected Loss.

What to look for:
    Stronger score bands should generally show:
        higher avg_credit_score,
        lower avg_synthetic_estimated_pd_proxy,
        higher approval rate,
        higher simulated offer-exposure rate.

    Weaker score bands should generally show:
        lower avg_credit_score,
        higher avg_synthetic_estimated_pd_proxy,
        higher manual-review or decline rate.

Review triggers:
    Perfect monotonicity is not required.

    But large unexpected reversals should be explainable through product mix, requested PTI, DTI,
    exposure intensity, behavioral signals, or product-specific policy controls.

SQL mechanics:
    GROUP BY score_band_policy_key creates one row per score band.

    FILTER calculates each final-outcome rate.

    SUM(COALESCE(..., 0)) calculates all-application approved exposure and approved Expected Loss
    totals.

Documentation use:
    This query is one of the cleanest Section 14 outputs for README and Validation Summary discussion.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,

    /***********************************************************************************************
    Score-band population size.
    ***********************************************************************************************/
    COUNT(*) AS applications,

    /***********************************************************************************************
    Core score-band quality and capacity profile.
    ***********************************************************************************************/
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio,

    /***********************************************************************************************
    Final decision rates by score band.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    All-application approved exposure and approved Expected Loss by score band.
    ***********************************************************************************************/
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

Business purpose:
    Review whether score-band outcomes remain explainable through simulated strategy explanation
    codes.

Credit risk interpretation:
    Stronger score bands should generally concentrate in approval or lower-friction positive
    offer-exposure reason families.

    Weaker score bands should generally show more manual-review, counteroffer, or policy-stop
    explanation patterns.

    Product mix, affordability, DTI, exposure, and behavioral signals can create exceptions.

What to look for:
    primary_reason_family should align to decision_outcome:
        APPROVE       → APPROVAL
        COUNTEROFFER  → COUNTEROFFER
        MANUAL_REVIEW → MANUAL_REVIEW
        DECLINE       → POLICY_STOP

    Reason-code concentration should be directionally explainable by score-band quality and other
    strategy dimensions.

Review triggers:
    Strong score bands dominated by policy-stop reasons require review.

    Weak score bands dominated by approval reasons may be acceptable only if synthetic estimated-risk,
    affordability, product mix, and exposure are explainable.

SQL mechanics:
    GROUP BY score band, decision outcome, reason family, and reason code creates one row per
    score-band explanation pattern.

    SUM(COUNT(*)) OVER (PARTITION BY score_band_policy_key) gives the score-band denominator for
    pct_within_score_band.

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

    /***********************************************************************************************
    Count rows in this score-band × outcome × reason-code pattern.
    ***********************************************************************************************/
    COUNT(*) AS row_count,

    /***********************************************************************************************
    Average synthetic estimated-risk proxy for this explanation pattern.

    This helps reviewers see whether reason-code concentration aligns with risk profile.
    ***********************************************************************************************/
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,

    /***********************************************************************************************
    Percent of the score-band population represented by this reason-code pattern.
    ***********************************************************************************************/
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

WHY PRODUCT × SCORE MATTERS:
    Product × score-band analysis is one of the most important Module 2 validation outputs.

    Product type and score band are both major strategy dimensions:

        product type:
            shapes requested exposure, payment mechanics, LGD, product caps, affordability treatment,
            counteroffer feasibility, and product-level Expected Loss behavior.

        score band:
            shapes borrower-quality segmentation, synthetic estimated-risk tiering, and directional
            risk posture.

    Reviewing them jointly prevents portfolio-level averages from hiding important segment-level
    strategy behavior.

CREDIT RISK INTERPRETATION:
    A portfolio-level approval rate may look reasonable while a product × score intersection behaves
    unexpectedly.

    For example:
        unsecured weaker-score segments may show elevated manual review or decline concentration;
        secured stronger-score segments may show higher simulated offer exposure;
        high-balance product segments may show counteroffer concentration due to exposure caps;
        revolving weaker-score segments may show reason-code concentration tied to product guardrails.

    Product × score QA helps identify whether those patterns are coherent and explainable.

WHAT TO LOOK FOR:
    Stronger score bands within each product should generally show better outcome rates than weaker
    score bands, subject to product structure and affordability.

    Products with larger requested exposure or higher LGD may show higher requested Expected Loss or
    more exposure treatment.

    Product × score segments with high approved Expected Loss should be explainable through approved
    exposure, estimated_pd, estimated_lgd, and product caps.

REVIEW TRIGGERS:
    A product × score segment with high decline or manual-review concentration:
        review reason codes, risk tier, DTI, requested PTI, requested Expected Loss, and product
        guardrails.

    A product × score segment with high counteroffer concentration:
        review exposure caps, counteroffer target PTI, product approved Expected Loss cap, and
        feasibility pass / fail behavior.

    A product × score segment with high simulated offer exposure but high approved Expected Loss:
        review whether the strategy is intentionally growth-oriented or whether risk discipline needs
        tightening.

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

SQL CONCEPTS TAUGHT IN THIS SECTION:
    GROUP BY product × score:
        creates the segment-level validation grain.

    FILTER:
        calculates outcome-specific counts and rates in one grouped query.

    COALESCE:
        turns unresolved or no-offer approved values into zero for all-application impact metrics.

    Window denominator:
        calculates within-segment percentages while preserving product × score × outcome or product
        × score × reason-code rows.

    Custom ORDER BY:
        sorts score bands strongest to weakest.

DOCUMENTATION USE:
    Section 14.6 is a strong bridge between QA and executive storytelling.

    It tells reviewers where the strategy actually moved the portfolio and which segments drive
    access, exposure, approved Expected Loss, counteroffer, review, and decline behavior.

READ-ONLY BOUNDARY:
    Section 14.6 does not modify latest-run rows.
    Section 14.6 does not modify archive rows.
    Section 14.6 does not recalculate decisions, reason codes, approved exposure, or Expected Loss.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
14.6A Product × score segment summary.

Business purpose:
    Provide one row per product × score-band segment.

Credit risk interpretation:
    This is the most compact segment-level strategy distribution table in Section 14.

    It connects:
        product,
        credit quality,
        access,
        exposure,
        affordability,
        synthetic estimated-risk proxy,
        LGD,
        requested Expected Loss,
        and approved Expected Loss.

What to look for:
    Identify where simulated offer exposure concentrates.

    Identify where approved exposure concentrates.

    Identify where approved Expected Loss concentrates.

    Identify where product-aware strategy behavior differs across score bands.

Review triggers:
    Product × score segments with high approved Expected Loss or high decline concentration should be
    interpreted before executive documentation.

    Small segments should be interpreted carefully because rates can be noisy.

SQL mechanics:
    GROUP BY product_type_policy_key, score_band_policy_key creates the product × score segment
    grain.

    FILTER calculates outcome-specific counts and rates.

    COALESCE supports all-application approved exposure and approved Expected Loss metrics.

Documentation use:
    Strong candidate for README / executive evidence because it connects product, credit quality,
    access, exposure, affordability, and approved Expected Loss in one view.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,

    /***********************************************************************************************
    Segment size.
    ***********************************************************************************************/
    COUNT(*) AS applications,

    /***********************************************************************************************
    Final decision counts and rates.

    Each rate uses the product × score segment population as the denominator.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Simulated positive offer exposure.

    TRUE for final APPROVE and final COUNTEROFFER rows.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_count,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    /***********************************************************************************************
    Segment borrower-quality, synthetic risk, and LGD profile.
    ***********************************************************************************************/
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(estimated_lgd) AS avg_estimated_lgd,

    /***********************************************************************************************
    Requested and approved exposure metrics.

    avg_approved_amount_all_apps:
        all-app impact view.

    avg_approved_amount_offer_rows:
        economics of positive simulated offer-exposure rows only.
    ***********************************************************************************************/
    AVG(requested_amount) AS avg_requested_amount,
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,

    /***********************************************************************************************
    Requested and approved affordability metrics.
    ***********************************************************************************************/
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    /***********************************************************************************************
    Requested and approved Expected Loss metrics.

    These fields preserve the distinction between requested-exposure EL and approved-exposure EL.
    ***********************************************************************************************/
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

Business purpose:
    Expand the product × score matrix by final decision_outcome.

Credit risk interpretation:
    This query shows whether a product × score segment is dominated by one simulated strategy path.

    A segment dominated by APPROVE may indicate a lower-friction access segment.

    A segment dominated by COUNTEROFFER may indicate exposure-treatment dependency.

    A segment dominated by MANUAL_REVIEW may indicate unresolved borderline or mixed-signal pressure.

    A segment dominated by DECLINE may indicate policy-stop, severe risk, DTI, or requested-structure
    pressure.

What to look for:
    pct_within_product_score_segment should identify the dominant final outcome in each segment.

    avg_synthetic_estimated_pd_proxy and avg_requested_payment_to_income_ratio should help explain
    why the outcome concentration occurred.

Review triggers:
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

SQL mechanics:
    The window denominator partitions by product and score band so the percentage is calculated within
    each product × score segment.

Documentation use:
    Use this query to describe segment-level decision concentration.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,

    /***********************************************************************************************
    Number of rows in this product × score × outcome group.
    ***********************************************************************************************/
    COUNT(*) AS row_count,

    /***********************************************************************************************
    Percent of the product × score segment represented by this outcome.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Risk, affordability, approved exposure, and approved Expected Loss diagnostics for this segment
    and outcome.
    ***********************************************************************************************/
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

Business purpose:
    Connect product × score outcome concentration to simulated strategy explanation codes.

Credit risk interpretation:
    This diagnostic explains why product × score segments are moving into particular final outcomes.

Example uses:
    Identify whether weak-score unsecured declines are driven by synthetic risk, DTI, exposure,
    requested PTI, or product policy stops.

    Identify whether product × score counteroffers are driven by product exposure limits,
    affordability adjustment, synthetic risk exposure limits, or approved Expected Loss limits.

What to look for:
    Reason family should align to final outcome family.

    The dominant reason code should explain the segment's dominant final outcome.

Review triggers:
    A high segment-level reason-code concentration is not automatically wrong, but it should be
    explainable and consistent with the strategy design.

    Unexpected reason families should be reviewed against Section 10 reason-code logic.

SQL mechanics:
    GROUP BY product, score band, decision outcome, reason family, and reason code creates the most
    granular Section 14.6 explanation view.

    The window denominator partitions by product × score segment, so pct_within_product_score_segment
    shows how much of the segment is explained by each outcome / reason-code pattern.

Boundary:
    Reason codes are simulated strategy explanation codes only.

    They are not external notices, production compliance reasons, customer communications, or
    fair-lending conclusions.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,

    /***********************************************************************************************
    Count rows in this product × score × outcome × reason-code pattern.
    ***********************************************************************************************/
    COUNT(*) AS row_count,

    /***********************************************************************************************
    Percent of the product × score segment represented by this reason-code pattern.
    ***********************************************************************************************/
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
END OF SECTION 14.6 — PRODUCT × SCORE DECISION MATRIX

If execution reaches this point:
    1. Product-level strategy QA has been reviewed.
    2. Product-level decision-rate evidence is available.
    3. Product-level reason-code distribution evidence is available.
    4. Score-band strategy QA has been reviewed.
    5. Score-band decision-rate evidence is available.
    6. Score-band reason-code distribution evidence is available.
    7. Product × score segment strategy QA has been reviewed.
    8. Product × score × decision-outcome concentration evidence is available.
    9. Product × score × reason-code explanation evidence is available.
    10. estimated_pd remains interpreted as the synthetic estimated-PD proxy.
    11. requested_expected_loss_amount remains requested-exposure Expected Loss.
    12. approved_expected_loss_amount remains approved-exposure Expected Loss.
    13. simulated_offer_exposure_flag remains a simulated positive offer-exposure indicator only.
    14. simulated reason codes remain internal strategy explanation codes only.

No latest-run output rows have been modified.
No archive rows have been modified.
No strategy parameter rows have been modified.
No product policy parameter rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been reassigned.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 14.7 should continue the latest-run QA framework by reviewing synthetic risk-tier
    behavior, risk ordering, and whether final outcomes align directionally with the synthetic
    estimated-risk proxy.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00984 -->


---

<a id="c038-m00985"></a>

### C038-M00985

**Andrew** · 2026-05-10T09:19:32.053000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00985 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 14.7-14.10 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00985 -->


**Attachments in export:** `Pasted text(155).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_50.md) · [Next](Part_52.md)
