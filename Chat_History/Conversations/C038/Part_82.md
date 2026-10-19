# Module 2 Decision Simulator Build

## Part 82

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_81.md) · [Next](Part_83.md)

<a id="c038-m01590"></a>

### C038-M01590

**ChatGPT** · 2026-05-12T11:49:46.071027-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01590 -->
According to a document from 2026-05-12, Section 12 is the governed archive persistence layer: it consumes `credit_decisioning_sim.strategy_decisions`, creates or reuses `credit_decisioning_sim.strategy_decisions_archive`, applies `archive_run_flag` and `strategy_archive_reset_mode`, validates schema alignment, protects archive grain, and keeps matched comparison deferred to Section 13. fileciteturn248file2

```sql
/***************************************************************************************************
SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Persist completed latest-run Module 2 strategy outputs into the governed strategy archive.

    Section 12 answers:

        "Should this completed Module 2 latest-run strategy output become governed historical
         evidence, and if so, how should the archive handle prior rows for the same strategy /
         Module 1 scenario / population slice?"

    Section 12 is the history-control layer.

    Section 11 created the replaceable latest-run output table.
    Section 12 preserves completed runs in the archive so later sections can compare, validate,
    summarize, and capture evidence across multiple completed strategy slices.

SQL PURPOSE:
    1. Confirm the latest-run output exists, is populated, and is unique at application_id.
    2. Confirm the latest-run output contains one unambiguous archive-control configuration.
    3. Confirm the latest-run output contains one unambiguous archive replacement key.
    4. Create or reuse credit_decisioning_sim.strategy_decisions_archive.
    5. Add missing latest-run columns to the archive table when safe.
    6. Add archive_inserted_ts when needed.
    7. Validate latest-run / archive schema alignment.
    8. Capture archive inventory before persistence.
    9. Apply governed archive persistence behavior:
            archive_run_flag = FALSE
            strategy_archive_reset_mode = NONE
            strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
            strategy_archive_reset_mode = STRATEGY_SET_ONLY
            strategy_archive_reset_mode = ALL
    10. Insert the current latest-run output into the archive when archive_run_flag = TRUE.
    11. Add archive_inserted_ts as archive persistence audit metadata.
    12. Capture archive inventory after persistence.
    13. Create archive validation indexes before row-level persistence checks.
    14. Validate archive skip / insert / replacement / reset behavior.
    15. Validate archive row-level grain.
    16. Validate current-slice persistence fidelity versus the latest-run table.
    17. Create practical archive review indexes.
    18. Provide lightweight archive diagnostics before Section 13 matched comparison.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the completed latest-run strategy slice was archived only when intended and that
        reruns replaced the intended slice.

    Model governance / validation reviewers:
        Confirm that the archive is stable, traceable, unique at archive grain, and not silently
        mixed across strategies, Module 1 scenarios, or populations.

    SQL reviewers:
        Confirm that archive persistence uses explicit column lists, schema checks, safe reset modes,
        row-count audits, and row-level persistence fidelity checks.

    Portfolio / executive reviewers:
        Use Section 12 diagnostics to confirm that a completed strategy run is available for
        Section 13 comparison, Section 15 frontier review, and Section 16 evidence capture.

WHEN TO RUN THIS SECTION:
    Run Section 12 after:

        Section 11 — Latest-Run Strategy Decision Output Table

    Section 12 should be run before:

        Section 13 — Archive Inventory and Matched Strategy Comparison Framework
        Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics
        Section 15 — Strategy Frontier Summary and Executive Comparison View
        Section 16 — Strategy Run Evidence Capture and Executive Story Register

INPUT:
    credit_decisioning_sim.strategy_decisions

OUTPUT:
    credit_decisioning_sim.strategy_decisions_archive

TEMPORARY DIAGNOSTIC OUTPUTS:
    tmp_m2_archive_inventory_before
    tmp_m2_archive_inventory_after
    tmp_m2_archive_persistence_audit

WHY LATEST-RUN OUTPUT AND ARCHIVE PERSISTENCE ARE SEPARATE:
    credit_decisioning_sim.strategy_decisions is the current latest-run output.

    It is replaced each run.

    credit_decisioning_sim.strategy_decisions_archive is the governed historical evidence layer.

    It supports:
        completed-run retention,
        rerun replacement control,
        matched baseline / challenger comparison,
        strategy frontier analysis,
        validation evidence review,
        executive evidence capture,
        README narrative support,
        LinkedIn campaign narrative support,
        and future Validation Summary drafting.

SECTION 12 DOES NOT RECALCULATE STRATEGY RESULTS:
    Section 12 does not recalculate:
        decision_outcome,
        decision_path,
        approved_amount,
        approved_payment_to_income_ratio,
        approved_expected_loss_amount,
        simulated reason codes,
        trigger flags,
        segmentation fields,
        counteroffer feasibility,
        final outcome flags,
        or simulated offer-exposure flags.

    It persists the already-materialized latest-run output.

ARCHIVE ROW-LEVEL GRAIN:
    One archive row per:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

ARCHIVE REPLACEMENT / RERUN KEY:
    The archive replacement key is:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

WHY APPLICATION_ID IS EXCLUDED FROM THE REPLACEMENT KEY:
    The replacement key identifies the completed strategy / scenario / population slice.

    application_id identifies each row within that slice.

    Deleting by replacement key clears the prior completed slice before inserting the current
    latest-run slice.

AUDIT METADATA BOUNDARY:
    strategy_run_id:
        run traceability metadata.

    strategy_run_ts:
        run timestamp metadata.

    latest_output_created_ts:
        latest-run table materialization metadata.

    archive_inserted_ts:
        archive persistence metadata.

    None of these timestamp or run-audit fields define archive replacement grain.
    None of these timestamp or run-audit fields should define matched strategy comparison grain.

ARCHIVE CONTROL MODES:
    archive_run_flag = FALSE:
        Skip archive persistence.
        Do not delete archive rows.
        Do not insert archive rows.

    strategy_archive_reset_mode = NONE:
        Append-only mode for the current replacement key.
        Do not delete existing archive rows before insert.
        Fail if the current replacement key already exists.

    strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY:
        Ordinary governed rerun mode.
        Replace only the current strategy / Module 1 scenario / population slice.

    strategy_archive_reset_mode = STRATEGY_SET_ONLY:
        Broader reset mode.
        Replace all strategy_name / strategy_version outputs within the current strategy_set_name
        for the selected Module 1 scenario and population.

    strategy_archive_reset_mode = ALL:
        Broadest reset mode.
        Delete all archive rows before inserting the current latest-run output.

        Use intentionally.

SCHEMA ALIGNMENT NOTE:
    The archive table is created from the current latest-run output schema when the archive does not
    yet exist.

    If the latest-run schema evolves after the archive already exists, Section 12 safely adds missing
    latest-run columns to the archive table and then validates type alignment.

    Section 12 does not attempt to be a full dynamic schema migration system.

    It provides practical governed archive compatibility checks:
        missing latest-run column checks,
        safe ADD COLUMN IF NOT EXISTS behavior,
        data-type alignment checks,
        unexpected archive column checks,
        and archive_inserted_ts existence checks.

WHY ARCHIVE VALIDATION INDEXES ARE CREATED BEFORE SECTION 12.6:
    Section 12.6 compares the latest-run table to the current archived slice at row-level archive
    grain.

    As the archive grows across strategy and scenario slices, row-level validation can become slow if
    the latest-run and archive tables lack supporting indexes.

    Section 12.5A creates validation indexes before Section 12.6 performs persistence fidelity
    checks.

CAMPAIGN REGISTRY BOUNDARY:
    Campaign IDs such as:
        module1_run_id,
        module2_run_id,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id,
        readme_storyline_label,
        linkedin_post_sequence,
        validation_summary_section_hint

    are evidence-linkage metadata.

    They are persisted later through Section 16 evidence capture.

    They do not replace archive grain and are not inserted into every archive row in Section 12.

MATCHED COMPARISON BOUNDARY:
    Section 12 persists archive rows.

    It does not compare archived strategies.

    Matched strategy comparison is built in Section 13.

SECTION 14 QA BOUNDARY:
    Section 12 verifies archive persistence fidelity.

    It does not replace latest-run validation.

    Full latest-run validation remains Section 14.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TABLE IF NOT EXISTS ... LIKE:
        Creates the archive table from the latest-run table shape when the archive does not yet exist.

    ALTER TABLE ... ADD COLUMN IF NOT EXISTS:
        Adds archive_inserted_ts and missing latest-run columns without failing on reruns.

    pg_attribute + format_type:
        Reads exact PostgreSQL column types so missing archive columns can be added safely.

    information_schema / pg_catalog inspection:
        Validates schema alignment before persistence.

    DO $$ ... END $$:
        Runs procedural archive-control logic with variables, IF statements, dynamic SQL, and explicit
        exceptions.

    SELECT ... INTO:
        Loads counts, archive controls, replacement keys, and diagnostic values into PL/pgSQL
        variables.

    GET DIAGNOSTICS ... ROW_COUNT:
        Captures how many rows were deleted or inserted by the most recent DML statement.

    EXECUTE FORMAT(...):
        Runs a dynamic INSERT statement using an explicit column list derived from the latest-run
        schema.

    IS DISTINCT FROM:
        Performs NULL-safe comparisons when validating latest-run versus archived values.

    FULL OUTER JOIN:
        Compares before / after archive inventory and latest-run / archive row-level persistence even
        when a row exists on only one side.

    CREATE UNIQUE INDEX:
        Enforces the row-level archive grain so matched comparison does not operate on duplicate
        archived applications.

GOVERNANCE ROLE:
    Section 12 protects:
        archive history,
        replacement discipline,
        schema consistency,
        row-level archive grain,
        and persistence fidelity.

COMMON MISUSE TO AVOID:
    Do not use the latest-run table as strategy history.
    Do not manually delete archive rows outside governed archive controls.
    Do not treat timestamp fields as matched-comparison keys.
    Do not interpret archive persistence as recalculation or revalidation of decision logic.
    Do not interpret archive_inserted_ts as a business outcome.
    Do not treat archive_run_flag = TRUE as proof that validation passed.
    Do not treat archive persistence as a substitute for Section 14 QA.

***************************************************************************************************/



/***************************************************************************************************
SECTION 12.1 — LATEST-RUN SOURCE INTEGRITY AND ARCHIVE-CONTROL PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that archive persistence is operating on one completed, internally coherent latest-run
    strategy slice.

    Section 12.1 answers:

        "Is credit_decisioning_sim.strategy_decisions safe to archive?"

SQL PURPOSE:
    1. Confirm latest-run table exists.
    2. Confirm latest-run table contains rows.
    3. Confirm latest-run table is unique at application_id.
    4. Confirm the latest-run output contains exactly one archive-control configuration.
    5. Confirm the latest-run output contains exactly one archive replacement key.
    6. Confirm archive controls are populated and valid.
    7. Confirm key identity, lineage, decision, reason-code, requested-risk, and final-output fields
       needed by archive persistence are populated.

BOUNDARY:
    Section 12.1 does not create archive rows.
    Section 12.1 does not delete archive rows.
    Section 12.1 does not update archive rows.
    Section 12.1 does not create comparison outputs.
    Section 12.1 does not run full Section 14 QA.

***************************************************************************************************/

DO $$
DECLARE
    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    v_archive_control_null_count BIGINT;
    v_archive_control_invalid_count BIGINT;
    v_archive_control_configuration_count BIGINT;
    v_archive_replacement_key_count BIGINT;

    v_required_latest_output_gap_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must exist.

    SQL mechanics:
        TO_REGCLASS returns NULL if the table is absent.

    Business interpretation:
        Section 12 must archive the Section 11 latest-run output. If that table is absent, the
        archive step cannot proceed.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: credit_decisioning_sim.strategy_decisions does not exist. Run Section 11 before Section 12.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output must contain rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run strategy_decisions table contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id must be unique in latest-run output.

    Archive persistence assumes one latest-run row per synthetic application for the current run key.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_distinct_app_count <> v_latest_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM credit_decisioning_sim.strategy_decisions
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run application_id is not unique. Latest rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_latest_count,
            v_latest_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls must be populated and valid.

    archive_run_flag:
        TRUE or FALSE.

    strategy_archive_reset_mode:
        NONE
        STRATEGY_SCENARIO_ONLY
        STRATEGY_SET_ONLY
        ALL
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_control_null_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE archive_run_flag IS NULL
       OR strategy_archive_reset_mode IS NULL
       OR NULLIF(BTRIM(strategy_archive_reset_mode), '') IS NULL;

    IF v_archive_control_null_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % latest-run row(s) have missing archive controls.',
            v_archive_control_null_count;
    END IF;

    SELECT COUNT(*)
    INTO v_archive_control_invalid_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE strategy_archive_reset_mode NOT IN (
        'NONE',
        'STRATEGY_SCENARIO_ONLY',
        'STRATEGY_SET_ONLY',
        'ALL'
    );

    IF v_archive_control_invalid_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % latest-run row(s) have invalid strategy_archive_reset_mode values.',
            v_archive_control_invalid_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive-control configuration must be unambiguous.

    Business interpretation:
        A single latest-run strategy slice cannot contain mixed archive_run_flag or
        strategy_archive_reset_mode values.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT (
        archive_run_flag,
        strategy_archive_reset_mode
    ))
    INTO v_archive_control_configuration_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_archive_control_configuration_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % archive-control configurations. Expected exactly one.',
            v_archive_control_configuration_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive replacement key must be unambiguous.

    Replacement key:
        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    ))
    INTO v_archive_replacement_key_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_archive_replacement_key_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % archive replacement keys. Expected exactly one.',
            v_archive_replacement_key_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required latest-run output fields needed by archive persistence.

    Important:
        MANUAL_REVIEW rows are unresolved by design, so approved_amount and
        approved_expected_loss_amount may be NULL only for MANUAL_REVIEW.

        APPROVE, COUNTEROFFER, and DECLINE rows must have final approved exposure and approved
        Expected Loss populated according to Section 11 conventions.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_latest_output_gap_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE module2_model_version IS NULL
       OR NULLIF(BTRIM(module2_model_version), '') IS NULL
       OR strategy_set_name IS NULL
       OR NULLIF(BTRIM(strategy_set_name), '') IS NULL
       OR strategy_name IS NULL
       OR NULLIF(BTRIM(strategy_name), '') IS NULL
       OR strategy_version IS NULL
       OR NULLIF(BTRIM(strategy_version), '') IS NULL
       OR strategy_run_id IS NULL
       OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
       OR strategy_run_ts IS NULL

       OR module1_model_version IS NULL
       OR NULLIF(BTRIM(module1_model_version), '') IS NULL
       OR module1_scenario_set_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
       OR module1_scenario_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
       OR population_id IS NULL
       OR NULLIF(BTRIM(population_id), '') IS NULL

       OR application_id IS NULL
       OR NULLIF(BTRIM(application_id), '') IS NULL
       OR applicant_id IS NULL
       OR NULLIF(BTRIM(applicant_id), '') IS NULL

       OR requested_amount IS NULL
       OR requested_expected_loss_amount IS NULL
       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL

       OR decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL

       OR approval_flag IS NULL
       OR counteroffer_flag IS NULL
       OR manual_review_flag IS NULL
       OR decline_flag IS NULL
       OR simulated_offer_exposure_flag IS NULL

       OR primary_reason_code IS NULL
       OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
       OR primary_reason_family IS NULL
       OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
       OR triggered_reason_code_list IS NULL
       OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
       OR reason_priority_rank IS NULL
       OR reason_code_count IS NULL

       OR latest_output_created_ts IS NULL

       OR (
            decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
            AND approved_amount IS NULL
       )

       OR (
            decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'DECLINE')
            AND approved_expected_loss_amount IS NULL
       );

    IF v_required_latest_output_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % latest-run row(s) are missing required archive persistence fields.',
            v_required_latest_output_gap_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.2 — CREATE / ALIGN ARCHIVE TABLE SCHEMA
****************************************************************************************************

BUSINESS PURPOSE:
    Ensure the governed archive table exists and is compatible with the current latest-run output.

    Section 12.2 answers:

        "Can the current latest-run output be inserted into the archive without schema ambiguity?"

SQL PURPOSE:
    1. Create archive table if it does not exist.
    2. Add archive_inserted_ts if it does not exist.
    3. Add missing latest-run columns to the archive table when safe.
    4. Validate that all latest-run columns exist in the archive table.
    5. Validate exact PostgreSQL type alignment for common latest-run / archive columns.
    6. Validate that archive contains no unexpected columns except archive_inserted_ts.

WHY THIS SECTION USES DYNAMIC ADD COLUMN:
    The latest-run output schema can evolve during development.

    Formal archive persistence should be rerunnable when a new latest-run column is added.

    Instead of failing immediately when a latest-run column is missing from an existing archive table,
    this block adds missing latest-run columns with their exact PostgreSQL type and then validates
    alignment.

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
    c RECORD;

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
    FOR c IN
        SELECT
            la.attname AS column_name,
            pg_catalog.format_type(la.atttypid, la.atttypmod) AS column_type
        FROM pg_attribute la

        JOIN pg_class lc
            ON lc.oid = la.attrelid

        JOIN pg_namespace ln
            ON ln.oid = lc.relnamespace

        WHERE ln.nspname = 'credit_decisioning_sim'
          AND lc.relname = 'strategy_decisions'
          AND la.attnum > 0
          AND la.attisdropped IS FALSE
          AND NOT EXISTS (
              SELECT 1
              FROM pg_attribute aa
              JOIN pg_class ac
                  ON ac.oid = aa.attrelid
              JOIN pg_namespace an
                  ON an.oid = ac.relnamespace
              WHERE an.nspname = 'credit_decisioning_sim'
                AND ac.relname = 'strategy_decisions_archive'
                AND aa.attnum > 0
                AND aa.attisdropped IS FALSE
                AND aa.attname = la.attname
          )
        ORDER BY la.attnum
    LOOP
        EXECUTE FORMAT(
            'ALTER TABLE credit_decisioning_sim.strategy_decisions_archive ADD COLUMN IF NOT EXISTS %I %s',
            c.column_name,
            c.column_type
        );
    END LOOP;


    /*-------------------------------------------------------------------------------------------
    Verify no latest-run columns remain missing from archive.

    Business interpretation:
        Every latest-run column should be preservable in the archive.
    -------------------------------------------------------------------------------------------*/
    WITH latest_columns AS (
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
            a.attname AS column_name,
            pg_catalog.format_type(a.atttypid, a.atttypmod) AS column_type
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
        SELECT
            a.attname AS column_name,
            pg_catalog.format_type(a.atttypid, a.atttypmod) AS column_type
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

    unexpected_columns AS (
        SELECT a.column_name
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
        FROM pg_attribute a
        JOIN pg_class c
            ON c.oid = a.attrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'credit_decisioning_sim'
          AND c.relname = 'strategy_decisions_archive'
          AND a.attname = 'archive_inserted_ts'
          AND a.attnum > 0
          AND a.attisdropped IS FALSE
    )
    INTO v_archive_inserted_ts_exists;

    IF v_archive_inserted_ts_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive table is missing archive_inserted_ts.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.3 — ARCHIVE INVENTORY SNAPSHOT BEFORE PERSISTENCE
****************************************************************************************************

BUSINESS PURPOSE:
    Capture pre-persistence archive inventory so Section 12 can validate exactly what changed.

    Section 12.3 answers:

        "What archive slices existed before the current archive-control logic ran?"

SQL PURPOSE:
    1. Drop and recreate tmp_m2_archive_inventory_before.
    2. Summarize archive rows by archive replacement slice before Section 12.4.
    3. Drop and recreate tmp_m2_archive_persistence_audit.
    4. Prepare a one-row temporary audit table that Section 12.4 will populate.

WHY THIS SECTION EXISTS:
    Archive-control modes should be testable.

    The before snapshot allows later validation that:
        skip mode changed nothing;
        scenario-only mode changed only the current slice;
        strategy-set mode changed only the selected strategy set for the selected scenario/population;
        all mode cleared prior archive state;
        none mode appended only when no prior current-key rows existed.

BOUNDARY:
    Section 12.3 does not modify archive rows.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;

CREATE TEMP TABLE tmp_m2_archive_inventory_before
ON COMMIT PRESERVE ROWS
AS
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions_archive
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;


DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

CREATE TEMP TABLE tmp_m2_archive_persistence_audit (
    /***********************************************************************************************
    Active archive controls.
    ***********************************************************************************************/
    archive_run_flag                         BOOLEAN,
    strategy_archive_reset_mode              TEXT,

    /***********************************************************************************************
    Archive replacement / rerun key.
    ***********************************************************************************************/
    strategy_set_name                        TEXT,
    strategy_name                            TEXT,
    strategy_version                         TEXT,
    module1_scenario_set_name                TEXT,
    module1_scenario_name                    TEXT,
    population_id                            TEXT,

    /***********************************************************************************************
    Latest-run source row counts.
    ***********************************************************************************************/
    latest_run_row_count                     BIGINT,
    latest_run_distinct_application_count    BIGINT,

    /***********************************************************************************************
    Archive before / delete / insert / after counts.
    ***********************************************************************************************/
    archive_row_count_before                 BIGINT,
    archive_deleted_rows                     BIGINT,
    archive_inserted_rows                    BIGINT,
    archive_row_count_after                  BIGINT,

    /***********************************************************************************************
    Human-readable archive action label.
    ***********************************************************************************************/
    archive_action                           TEXT,
    archive_action_ts                        TIMESTAMP
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 12.4 — APPLY ARCHIVE CONTROL LOGIC
****************************************************************************************************

BUSINESS PURPOSE:
    Apply the active archive persistence control settings to the governed strategy archive.

    Section 12.4 answers:

        "Should this latest-run strategy slice be inserted into archive history, and what prior
         archive rows should be removed first?"

SQL PURPOSE:
    1. Read the single archive-control configuration and replacement key.
    2. Count latest-run rows and archive rows before persistence.
    3. If archive_run_flag = FALSE, skip delete and insert behavior.
    4. If archive_run_flag = TRUE, apply strategy_archive_reset_mode.
    5. Insert latest-run rows into archive using an explicit dynamic column list.
    6. Capture deleted-row and inserted-row counts.
    7. Insert one audit row into tmp_m2_archive_persistence_audit.

WHY DYNAMIC INSERT IS USED:
    The archive is designed to contain all latest-run columns plus archive_inserted_ts.

    Instead of relying on physical column order, Section 12 builds an explicit latest-run column list
    from information_schema.columns.

    This is safer and more auditable than INSERT ... SELECT *.

BOUNDARY:
    Section 12.4 modifies archive rows only according to governed archive controls.

    It does not recalculate decision outcomes.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.
    It does not reassign simulated reason codes.

****************************************************************************************************/

DO $$
DECLARE
    v_archive_run_flag BOOLEAN;
    v_strategy_archive_reset_mode TEXT;

    v_strategy_set_name TEXT;
    v_strategy_name TEXT;
    v_strategy_version TEXT;
    v_module1_scenario_set_name TEXT;
    v_module1_scenario_name TEXT;
    v_population_id TEXT;

    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_archive_before_count BIGINT;
    v_archive_after_count BIGINT;
    v_existing_key_count BIGINT;

    v_deleted_rows BIGINT := 0;
    v_inserted_rows BIGINT := 0;

    v_archive_action TEXT;
    v_insert_columns TEXT;
    v_select_columns TEXT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Read the single archive-control configuration and archive replacement key.

    Section 12.1 has already validated that this SELECT resolves to one logical configuration.
    -------------------------------------------------------------------------------------------*/
    SELECT
        archive_run_flag,
        strategy_archive_reset_mode,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    INTO
        v_archive_run_flag,
        v_strategy_archive_reset_mode,
        v_strategy_set_name,
        v_strategy_name,
        v_strategy_version,
        v_module1_scenario_set_name,
        v_module1_scenario_name,
        v_population_id
    FROM (
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
    ) k;


    /*-------------------------------------------------------------------------------------------
    Count latest-run rows.

    These counts become audit evidence for archive persistence.
    -------------------------------------------------------------------------------------------*/
    SELECT
        COUNT(*),
        COUNT(DISTINCT application_id)
    INTO
        v_latest_count,
        v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;


    /*-------------------------------------------------------------------------------------------
    Count total archive rows before persistence.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_before_count
    FROM credit_decisioning_sim.strategy_decisions_archive;


    /*-------------------------------------------------------------------------------------------
    archive_run_flag = FALSE:
        Skip archive persistence.

    Business purpose:
        Allows development runs or diagnostic runs to materialize latest-run output without
        preserving it as governed archive history.
    -------------------------------------------------------------------------------------------*/
    IF v_archive_run_flag IS FALSE THEN
        v_archive_action := 'ARCHIVE_SKIPPED_ARCHIVE_RUN_FLAG_FALSE';


    ELSE
        /*---------------------------------------------------------------------------------------
        archive_run_flag = TRUE:
            Apply governed archive reset / replacement mode before insert.
        ---------------------------------------------------------------------------------------*/

        IF v_strategy_archive_reset_mode = 'NONE' THEN
            /*-----------------------------------------------------------------------------------
            NONE:
                Append-only behavior for the current replacement key.

                If the key already exists, fail rather than creating duplicate archive grain.
            -----------------------------------------------------------------------------------*/
            SELECT COUNT(*)
            INTO v_existing_key_count
            FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = v_strategy_set_name
              AND strategy_name = v_strategy_name
              AND strategy_version = v_strategy_version
              AND module1_scenario_set_name = v_module1_scenario_set_name
              AND module1_scenario_name = v_module1_scenario_name
              AND population_id = v_population_id;

            IF v_existing_key_count > 0 THEN
                RAISE EXCEPTION
                    'Module 2 Section 12 failure: strategy_archive_reset_mode = NONE but archive already contains % row(s) for the current replacement key.',
                    v_existing_key_count;
            END IF;

            v_archive_action := 'ARCHIVE_INSERTED_NONE_MODE_NO_PRIOR_KEY';


        ELSIF v_strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY' THEN
            /*-----------------------------------------------------------------------------------
            STRATEGY_SCENARIO_ONLY:
                Ordinary governed rerun behavior.

                Deletes only the prior archived rows for the current:
                    strategy_set_name,
                    strategy_name,
                    strategy_version,
                    module1_scenario_set_name,
                    module1_scenario_name,
                    population_id.
            -----------------------------------------------------------------------------------*/
            DELETE FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = v_strategy_set_name
              AND strategy_name = v_strategy_name
              AND strategy_version = v_strategy_version
              AND module1_scenario_set_name = v_module1_scenario_set_name
              AND module1_scenario_name = v_module1_scenario_name
              AND population_id = v_population_id;

            GET DIAGNOSTICS v_deleted_rows = ROW_COUNT;
            v_archive_action := 'ARCHIVE_REPLACED_STRATEGY_SCENARIO_ONLY';


        ELSIF v_strategy_archive_reset_mode = 'STRATEGY_SET_ONLY' THEN
            /*-----------------------------------------------------------------------------------
            STRATEGY_SET_ONLY:
                Broader reset behavior.

                Deletes all archived rows in the current strategy_set_name for the selected Module 1
                scenario and population.

                This supports restarting a strategy-family comparison without disturbing unrelated
                Module 1 scenarios or unrelated populations.
            -----------------------------------------------------------------------------------*/
            DELETE FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = v_strategy_set_name
              AND module1_scenario_set_name = v_module1_scenario_set_name
              AND module1_scenario_name = v_module1_scenario_name
              AND population_id = v_population_id;

            GET DIAGNOSTICS v_deleted_rows = ROW_COUNT;
            v_archive_action := 'ARCHIVE_REPLACED_STRATEGY_SET_ONLY';


        ELSIF v_strategy_archive_reset_mode = 'ALL' THEN
            /*-----------------------------------------------------------------------------------
            ALL:
                Broadest reset behavior.

                Deletes all archive rows before inserting the current latest-run output.

                Use intentionally.
            -----------------------------------------------------------------------------------*/
            DELETE FROM credit_decisioning_sim.strategy_decisions_archive;

            GET DIAGNOSTICS v_deleted_rows = ROW_COUNT;
            v_archive_action := 'ARCHIVE_FULL_RESET_ALL_MODE';


        ELSE
            RAISE EXCEPTION
                'Module 2 Section 12 failure: unsupported strategy_archive_reset_mode: %.',
                v_strategy_archive_reset_mode;
        END IF;


        /*---------------------------------------------------------------------------------------
        Insert current latest-run rows into archive.

        SQL mechanics:
            v_insert_columns:
                target archive columns matching latest-run output columns.

            v_select_columns:
                source expressions from credit_decisioning_sim.strategy_decisions.

            archive_inserted_ts:
                added separately using CURRENT_TIMESTAMP.

        Why this is safer than SELECT *:
            SELECT * depends on physical column order.
            This dynamic insert uses explicit column names.
        ---------------------------------------------------------------------------------------*/
        SELECT
            STRING_AGG(FORMAT('%I', column_name), ', ' ORDER BY ordinal_position),
            STRING_AGG(FORMAT('sd.%I', column_name), ', ' ORDER BY ordinal_position)
        INTO
            v_insert_columns,
            v_select_columns
        FROM information_schema.columns
        WHERE table_schema = 'credit_decisioning_sim'
          AND table_name = 'strategy_decisions';

        IF v_insert_columns IS NULL OR v_select_columns IS NULL THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: unable to derive latest-run insert column list for archive persistence.';
        END IF;

        EXECUTE FORMAT(
            'INSERT INTO credit_decisioning_sim.strategy_decisions_archive (%s, archive_inserted_ts)
             SELECT %s, CURRENT_TIMESTAMP
             FROM credit_decisioning_sim.strategy_decisions sd',
            v_insert_columns,
            v_select_columns
        );

        GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Count total archive rows after archive-control behavior.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_after_count
    FROM credit_decisioning_sim.strategy_decisions_archive;


    /*-------------------------------------------------------------------------------------------
    Insert one temporary archive persistence audit row.

    Boundary:
        This audit row supports current-run Section 12 validation.

        It is not persistent executive evidence.
        Persistent evidence is captured later in Section 16.
    -------------------------------------------------------------------------------------------*/
    INSERT INTO tmp_m2_archive_persistence_audit (
        archive_run_flag,
        strategy_archive_reset_mode,

        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        latest_run_row_count,
        latest_run_distinct_application_count,

        archive_row_count_before,
        archive_deleted_rows,
        archive_inserted_rows,
        archive_row_count_after,

        archive_action,
        archive_action_ts
    )
    VALUES (
        v_archive_run_flag,
        v_strategy_archive_reset_mode,

        v_strategy_set_name,
        v_strategy_name,
        v_strategy_version,
        v_module1_scenario_set_name,
        v_module1_scenario_name,
        v_population_id,

        v_latest_count,
        v_latest_distinct_app_count,

        v_archive_before_count,
        v_deleted_rows,
        v_inserted_rows,
        v_archive_after_count,

        v_archive_action,
        CURRENT_TIMESTAMP
    );
END $$;



/***************************************************************************************************
SECTION 12.5 — ARCHIVE INVENTORY SNAPSHOT AFTER PERSISTENCE
****************************************************************************************************

BUSINESS PURPOSE:
    Capture post-persistence archive inventory so Section 12 can validate archive-control behavior.

    Section 12.5 answers:

        "What archive slices exist after the current archive-control logic ran?"

SQL PURPOSE:
    1. Drop and recreate tmp_m2_archive_inventory_after.
    2. Summarize archive rows by archive replacement slice after Section 12.4.
    3. Provide comparable inventory grain to tmp_m2_archive_inventory_before.

BOUNDARY:
    Section 12.5 does not modify archive rows.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;

CREATE TEMP TABLE tmp_m2_archive_inventory_after
ON COMMIT PRESERVE ROWS
AS
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions_archive
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/***************************************************************************************************
SECTION 12.5A — ARCHIVE VALIDATION INDEX SUPPORT BEFORE FAIL-FAST CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Support efficient archive persistence validation before Section 12.6 row-level gatekeepers.

    Section 12.5A answers:

        "Are the latest-run and archive tables indexed well enough for archive fidelity checks?"

SQL PURPOSE:
    1. Create latest-run validation-grain index.
    2. Create archive validation-grain index.
    3. Create unique archive row-level grain index.
    4. Analyze latest-run and archive tables for query planning.

UNIQUE ARCHIVE GRAIN ENFORCEMENT:
    The archive should not contain duplicate rows for the same application under the same Module 1
    scenario and Module 2 strategy version.

    If duplicates already exist, unique index creation will fail clearly.

    That is preferable to allowing ambiguous matched comparison later.

BOUNDARY:
    This section does not modify decisions, exposure values, Expected Loss values, reason codes, or
    archive data values.

****************************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_validation_grain
ON credit_decisioning_sim.strategy_decisions (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_validation_grain
ON credit_decisioning_sim.strategy_decisions_archive (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_m2_strategy_decisions_archive_row_grain
ON credit_decisioning_sim.strategy_decisions_archive (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id
);

ANALYZE credit_decisioning_sim.strategy_decisions;
ANALYZE credit_decisioning_sim.strategy_decisions_archive;



/***************************************************************************************************
SECTION 12.6 — LOCAL FAIL-FAST CHECKS FOR ARCHIVE PERSISTENCE
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Section 12 archive persistence behaved exactly as governed before archive comparison,
    validation, frontier, or evidence capture proceeds.

    Section 12.6 answers:

        "Did Section 12 preserve archive grain, apply the intended archive-control mode, and faithfully
         persist the current latest-run output?"

SQL PURPOSE:
    1. Confirm archive table and archive_inserted_ts exist.
    2. Confirm tmp_m2_archive_persistence_audit contains exactly one audit row.
    3. Confirm latest-run source integrity remains valid.
    4. Confirm archive_run_flag = FALSE changed no archive rows.
    5. Confirm archive_run_flag = TRUE inserted exactly latest-run row count.
    6. Confirm current archived slice row count equals latest-run row count.
    7. Confirm current archived slice is unique at application_id.
    8. Confirm archive_inserted_ts is populated for inserted current-slice rows.
    9. Confirm archive row-level grain is unique across the full archive.
    10. Confirm reset modes did not change unintended archive slices.
    11. Confirm archived current-slice values match latest-run values across every latest-run column.

BOUNDARY:
    Section 12.6 does not modify archive rows.
    Section 12.6 does not modify latest-run rows.
    Section 12.6 does not recalculate strategy outputs.

***************************************************************************************************/

DO $$
DECLARE
    a RECORD;

    v_audit_count BIGINT;

    v_archive_table_exists BOOLEAN;
    v_archive_inserted_ts_exists BOOLEAN;

    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;

    v_current_archive_count BIGINT;
    v_current_archive_distinct_app_count BIGINT;
    v_current_archive_null_ts_count BIGINT;
    v_current_archive_duplicate_app_count BIGINT;

    v_archive_duplicate_grain_count BIGINT;

    v_inventory_diff_count BIGINT;
    v_after_inventory_group_count BIGINT;

    v_before_current_key_rows BIGINT;
    v_before_current_set_rows BIGINT;

    v_persistence_compare_predicate TEXT;
    v_persistence_mismatch_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: one archive persistence audit row.

    Section 12.3 recreated the audit table.
    Section 12.4 should have inserted exactly one current-run audit row.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_audit_count
    FROM tmp_m2_archive_persistence_audit;

    IF v_audit_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: expected exactly one archive persistence audit row, found %.',
            v_audit_count;
    END IF;

    SELECT *
    INTO a
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive table and archive_inserted_ts must exist.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NOT NULL
    INTO v_archive_table_exists;

    IF v_archive_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive does not exist after archive setup.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'credit_decisioning_sim'
          AND table_name = 'strategy_decisions_archive'
          AND column_name = 'archive_inserted_ts'
    )
    INTO v_archive_inserted_ts_exists;

    IF v_archive_inserted_ts_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive_inserted_ts column does not exist after archive setup.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run source integrity remains valid.
    -------------------------------------------------------------------------------------------*/
    SELECT
        COUNT(*),
        COUNT(DISTINCT application_id)
    INTO
        v_latest_count,
        v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run table contains zero rows during archive gatekeeper.';
    END IF;

    IF v_latest_distinct_app_count <> v_latest_count THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run application_id uniqueness failed during archive gatekeeper.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: audit math must reconcile.

    Expected:
        after = before - deleted + inserted.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_row_count_after
       <> a.archive_row_count_before - a.archive_deleted_rows + a.archive_inserted_rows THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive audit row-count math does not reconcile. Before %, deleted %, inserted %, after %.',
            a.archive_row_count_before,
            a.archive_deleted_rows,
            a.archive_inserted_rows,
            a.archive_row_count_after;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: full archive row-level grain must be unique.

    This protects Section 13 matched comparison from duplicate archived application rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_duplicate_grain_count
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
    ) d;

    IF v_archive_duplicate_grain_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive contains % duplicate row-level grain group(s).',
            v_archive_duplicate_grain_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive_run_flag = FALSE skip behavior.

    Skip mode should not delete rows.
    Skip mode should not insert rows.
    Skip mode should not change archive inventory.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS FALSE THEN
        IF a.archive_deleted_rows <> 0
           OR a.archive_inserted_rows <> 0
           OR a.archive_row_count_after <> a.archive_row_count_before THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive_run_flag = FALSE but archive row counts changed.';
        END IF;

        SELECT COUNT(*)
        INTO v_inventory_diff_count
        FROM (
            SELECT
                COALESCE(b.strategy_set_name, aft.strategy_set_name) AS strategy_set_name,
                COALESCE(b.strategy_name, aft.strategy_name) AS strategy_name,
                COALESCE(b.strategy_version, aft.strategy_version) AS strategy_version,
                COALESCE(b.module1_scenario_set_name, aft.module1_scenario_set_name) AS module1_scenario_set_name,
                COALESCE(b.module1_scenario_name, aft.module1_scenario_name) AS module1_scenario_name,
                COALESCE(b.population_id, aft.population_id) AS population_id,
                COALESCE(b.row_count, 0) AS before_row_count,
                COALESCE(aft.row_count, 0) AS after_row_count
            FROM tmp_m2_archive_inventory_before b
            FULL OUTER JOIN tmp_m2_archive_inventory_after aft
                ON aft.strategy_set_name = b.strategy_set_name
               AND aft.strategy_name = b.strategy_name
               AND aft.strategy_version = b.strategy_version
               AND aft.module1_scenario_set_name = b.module1_scenario_set_name
               AND aft.module1_scenario_name = b.module1_scenario_name
               AND aft.population_id = b.population_id
        ) x
        WHERE before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive_run_flag = FALSE but before / after archive inventory changed for % slice(s).',
                v_inventory_diff_count;
        END IF;

        RETURN;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive_run_flag = TRUE insert count.

    Expected:
        inserted rows = latest-run rows.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_inserted_rows <> v_latest_count THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive inserted rows (%) do not equal latest-run rows (%).',
            a.archive_inserted_rows,
            v_latest_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: current archived slice row count, application uniqueness, and archive_inserted_ts.

    Current slice is scoped by the archive replacement key.
    -------------------------------------------------------------------------------------------*/
    SELECT
        COUNT(*),
        COUNT(DISTINCT application_id),
        COUNT(*) FILTER (WHERE archive_inserted_ts IS NULL)
    INTO
        v_current_archive_count,
        v_current_archive_distinct_app_count,
        v_current_archive_null_ts_count
    FROM credit_decisioning_sim.strategy_decisions_archive
    WHERE strategy_set_name = a.strategy_set_name
      AND strategy_name = a.strategy_name
      AND strategy_version = a.strategy_version
      AND module1_scenario_set_name = a.module1_scenario_set_name
      AND module1_scenario_name = a.module1_scenario_name
      AND population_id = a.population_id;

    IF v_current_archive_count <> v_latest_count THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: current archived slice row count (%) does not equal latest-run row count (%).',
            v_current_archive_count,
            v_latest_count;
    END IF;

    IF v_current_archive_distinct_app_count <> v_current_archive_count THEN
        SELECT COUNT(*)
        INTO v_current_archive_duplicate_app_count
        FROM (
            SELECT application_id
            FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = a.strategy_set_name
              AND strategy_name = a.strategy_name
              AND strategy_version = a.strategy_version
              AND module1_scenario_set_name = a.module1_scenario_set_name
              AND module1_scenario_name = a.module1_scenario_name
              AND population_id = a.population_id
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 12 failure: current archived slice has duplicate application_id values. Duplicate groups: %.',
            v_current_archive_duplicate_app_count;
    END IF;

    IF v_current_archive_null_ts_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % current archived slice row(s) have null archive_inserted_ts.',
            v_current_archive_null_ts_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: reset-mode scope validation.

    STRATEGY_SCENARIO_ONLY:
        Only the current replacement key should change.

    STRATEGY_SET_ONLY:
        Only the current strategy_set_name within the selected Module 1 scenario / population should
        change.

    ALL:
        After persistence, the archive should contain exactly one slice: the current latest-run slice.

    NONE:
        Prior current-key rows should not have existed before insert.
    -------------------------------------------------------------------------------------------*/
    IF a.strategy_archive_reset_mode = 'NONE' THEN
        SELECT COALESCE(SUM(row_count), 0)
        INTO v_before_current_key_rows
        FROM tmp_m2_archive_inventory_before
        WHERE strategy_set_name = a.strategy_set_name
          AND strategy_name = a.strategy_name
          AND strategy_version = a.strategy_version
          AND module1_scenario_set_name = a.module1_scenario_set_name
          AND module1_scenario_name = a.module1_scenario_name
          AND population_id = a.population_id;

        IF v_before_current_key_rows > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: NONE mode inserted despite prior current-key archive rows existing.';
        END IF;

        IF a.archive_deleted_rows <> 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: NONE mode deleted % row(s). Expected zero.',
                a.archive_deleted_rows;
        END IF;


    ELSIF a.strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY' THEN
        SELECT COUNT(*)
        INTO v_inventory_diff_count
        FROM (
            SELECT
                COALESCE(b.strategy_set_name, aft.strategy_set_name) AS strategy_set_name,
                COALESCE(b.strategy_name, aft.strategy_name) AS strategy_name,
                COALESCE(b.strategy_version, aft.strategy_version) AS strategy_version,
                COALESCE(b.module1_scenario_set_name, aft.module1_scenario_set_name) AS module1_scenario_set_name,
                COALESCE(b.module1_scenario_name, aft.module1_scenario_name) AS module1_scenario_name,
                COALESCE(b.population_id, aft.population_id) AS population_id,
                COALESCE(b.row_count, 0) AS before_row_count,
                COALESCE(aft.row_count, 0) AS after_row_count
            FROM tmp_m2_archive_inventory_before b
            FULL OUTER JOIN tmp_m2_archive_inventory_after aft
                ON aft.strategy_set_name = b.strategy_set_name
               AND aft.strategy_name = b.strategy_name
               AND aft.strategy_version = b.strategy_version
               AND aft.module1_scenario_set_name = b.module1_scenario_set_name
               AND aft.module1_scenario_name = b.module1_scenario_name
               AND aft.population_id = b.population_id
        ) x
        WHERE NOT (
                strategy_set_name = a.strategy_set_name
            AND strategy_name = a.strategy_name
            AND strategy_version = a.strategy_version
            AND module1_scenario_set_name = a.module1_scenario_set_name
            AND module1_scenario_name = a.module1_scenario_name
            AND population_id = a.population_id
        )
          AND before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: STRATEGY_SCENARIO_ONLY changed % unrelated archive slice(s).',
                v_inventory_diff_count;
        END IF;


    ELSIF a.strategy_archive_reset_mode = 'STRATEGY_SET_ONLY' THEN
        SELECT COALESCE(SUM(row_count), 0)
        INTO v_before_current_set_rows
        FROM tmp_m2_archive_inventory_before
        WHERE strategy_set_name = a.strategy_set_name
          AND module1_scenario_set_name = a.module1_scenario_set_name
          AND module1_scenario_name = a.module1_scenario_name
          AND population_id = a.population_id;

        IF a.archive_deleted_rows <> v_before_current_set_rows THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: STRATEGY_SET_ONLY deleted % row(s), but before-inventory current strategy-set rows were %.',
                a.archive_deleted_rows,
                v_before_current_set_rows;
        END IF;

        SELECT COUNT(*)
        INTO v_inventory_diff_count
        FROM (
            SELECT
                COALESCE(b.strategy_set_name, aft.strategy_set_name) AS strategy_set_name,
                COALESCE(b.strategy_name, aft.strategy_name) AS strategy_name,
                COALESCE(b.strategy_version, aft.strategy_version) AS strategy_version,
                COALESCE(b.module1_scenario_set_name, aft.module1_scenario_set_name) AS module1_scenario_set_name,
                COALESCE(b.module1_scenario_name, aft.module1_scenario_name) AS module1_scenario_name,
                COALESCE(b.population_id, aft.population_id) AS population_id,
                COALESCE(b.row_count, 0) AS before_row_count,
                COALESCE(aft.row_count, 0) AS after_row_count
            FROM tmp_m2_archive_inventory_before b
            FULL OUTER JOIN tmp_m2_archive_inventory_after aft
                ON aft.strategy_set_name = b.strategy_set_name
               AND aft.strategy_name = b.strategy_name
               AND aft.strategy_version = b.strategy_version
               AND aft.module1_scenario_set_name = b.module1_scenario_set_name
               AND aft.module1_scenario_name = b.module1_scenario_name
               AND aft.population_id = b.population_id
        ) x
        WHERE NOT (
                strategy_set_name = a.strategy_set_name
            AND module1_scenario_set_name = a.module1_scenario_set_name
            AND module1_scenario_name = a.module1_scenario_name
            AND population_id = a.population_id
        )
          AND before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: STRATEGY_SET_ONLY changed % unrelated archive slice(s).',
                v_inventory_diff_count;
        END IF;


    ELSIF a.strategy_archive_reset_mode = 'ALL' THEN
        SELECT COUNT(*)
        INTO v_after_inventory_group_count
        FROM tmp_m2_archive_inventory_after;

        IF v_after_inventory_group_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: ALL mode should leave one archive slice after insert, found %.',
                v_after_inventory_group_count;
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row-level persistence fidelity.

    Business purpose:
        The current archived slice should match the latest-run table across every latest-run column.

    SQL mechanics:
        Build a dynamic OR predicate:
            ar.<column> IS DISTINCT FROM sd.<column>

        Then FULL OUTER JOIN latest-run rows to current archived-slice rows by application_id.

    Why application_id is enough inside this dynamic query:
        latest-run output is already validated as one replacement key.
        current_archive is filtered to the same replacement key.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(
        FORMAT('ar.%1$I IS DISTINCT FROM sd.%1$I', column_name),
        ' OR ' ORDER BY ordinal_position
    )
    INTO v_persistence_compare_predicate
    FROM information_schema.columns
    WHERE table_schema = 'credit_decisioning_sim'
      AND table_name = 'strategy_decisions';

    IF v_persistence_compare_predicate IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: unable to build persistence comparison predicate.';
    END IF;

    EXECUTE FORMAT(
        $SQL$
        WITH latest_run AS (
            SELECT *
            FROM credit_decisioning_sim.strategy_decisions
        ),

        current_archive AS (
            SELECT *
            FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = %L
              AND strategy_name = %L
              AND strategy_version = %L
              AND module1_scenario_set_name = %L
              AND module1_scenario_name = %L
              AND population_id = %L
        )

        SELECT COUNT(*)
        FROM latest_run sd

        FULL OUTER JOIN current_archive ar
            ON ar.application_id = sd.application_id

        WHERE sd.application_id IS NULL
           OR ar.application_id IS NULL
           OR %s
        $SQL$,
        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id,
        v_persistence_compare_predicate
    )
    INTO v_persistence_mismatch_count;

    IF v_persistence_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % row(s) have latest-run versus archived current-slice persistence mismatches.',
            v_persistence_mismatch_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.7 — PRACTICAL ARCHIVE REVIEW INDEXES
****************************************************************************************************

BUSINESS PURPOSE:
    Add practical archive indexes for downstream review, comparison, validation, frontier analysis,
    and evidence capture.

SQL PURPOSE:
    Create rerunnable indexes on common archive review dimensions.

BOUNDARY:
    Indexes do not modify archive row values.
    Indexes do not recalculate strategy outcomes.
    Indexes do not change validation results.

****************************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_replacement_key
ON credit_decisioning_sim.strategy_decisions_archive (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_strategy_identity
ON credit_decisioning_sim.strategy_decisions_archive (
    strategy_set_name,
    strategy_name,
    strategy_version
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_module1_lineage
ON credit_decisioning_sim.strategy_decisions_archive (
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_decision_outcome
ON credit_decisioning_sim.strategy_decisions_archive (decision_outcome);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_product_decision
ON credit_decisioning_sim.strategy_decisions_archive (
    product_type_policy_key,
    decision_outcome
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_score_decision
ON credit_decisioning_sim.strategy_decisions_archive (
    score_band_policy_key,
    decision_outcome
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_primary_reason
ON credit_decisioning_sim.strategy_decisions_archive (primary_reason_code);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_offer_exposure
ON credit_decisioning_sim.strategy_decisions_archive (simulated_offer_exposure_flag);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_inserted_ts
ON credit_decisioning_sim.strategy_decisions_archive (archive_inserted_ts);



/***************************************************************************************************
SECTION 12.8 — LOCAL ARCHIVE PERSISTENCE SANITY CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide lightweight archive diagnostics after persistence.

    Section 12.8 answers:

        "What archive action was taken, what does the archive now contain, and does the current slice
         look ready for Section 13 matched comparison and downstream QA?"

SQL PURPOSE:
    Display review outputs for:
        archive inventory,
        current latest-run identity,
        archive audit row,
        before / after inventory movement,
        current archived slice row count,
        current archived slice decision distribution,
        current archived slice product distribution,
        current archived slice reason-code distribution,
        current archived slice exposure / Expected Loss summary,
        archive mode diagnostic,
        and one compact readiness row.

INTERPRETATION:
    These diagnostics are local archive persistence checks only.

    They are not:
        matched strategy comparison,
        full Section 14 QA,
        strategy frontier review,
        or executive evidence capture.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
12.8.1 Archive inventory by strategy / Module 1 scenario / population.

Purpose:
    Show all archived strategy slices currently available.

Interpretation:
    This is the first archive view to inspect before Section 13 comparison.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS archived_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    MIN(archive_inserted_ts) AS first_archive_inserted_ts,
    MAX(archive_inserted_ts) AS last_archive_inserted_ts

FROM credit_decisioning_sim.strategy_decisions_archive

GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
12.8.2 Latest-run identity prepared for archive.

Purpose:
    Display the current latest-run replacement key and archive controls.

Expected:
    exactly one row.
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

    COUNT(*) AS latest_run_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts

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



/*-----------------------------------------------------------------------------------------------
12.8.3 Archive persistence audit row.

Purpose:
    Show the action Section 12.4 took.

Interpretation:
    This is the clearest diagnostic for whether Section 12 skipped, appended, replaced, reset, or
    inserted.
-----------------------------------------------------------------------------------------------*/

SELECT
    archive_run_flag,
    strategy_archive_reset_mode,

    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    latest_run_row_count,
    latest_run_distinct_application_count,

    archive_row_count_before,
    archive_deleted_rows,
    archive_inserted_rows,
    archive_row_count_after,

    archive_action,
    archive_action_ts

FROM tmp_m2_archive_persistence_audit;



/*-----------------------------------------------------------------------------------------------
12.8.4 Archive before / after inventory movement.

Purpose:
    Show archive slice-level inventory changes caused by Section 12.

Interpretation:
    For ordinary STRATEGY_SCENARIO_ONLY reruns, only the current replacement key should change.

    For STRATEGY_SET_ONLY, only slices in the current strategy_set_name under the selected Module 1
    scenario / population should change.

    For ALL, prior archive slices should disappear except the newly inserted current slice.

    For archive_run_flag = FALSE, this output should show no row-count changes.
-----------------------------------------------------------------------------------------------*/

SELECT
    COALESCE(b.strategy_set_name, a.strategy_set_name) AS strategy_set_name,
    COALESCE(b.strategy_name, a.strategy_name) AS strategy_name,
    COALESCE(b.strategy_version, a.strategy_version) AS strategy_version,
    COALESCE(b.module1_scenario_set_name, a.module1_scenario_set_name) AS module1_scenario_set_name,
    COALESCE(b.module1_scenario_name, a.module1_scenario_name) AS module1_scenario_name,
    COALESCE(b.population_id, a.population_id) AS population_id,

    COALESCE(b.row_count, 0) AS before_row_count,
    COALESCE(a.row_count, 0) AS after_row_count,

    COALESCE(a.row_count, 0) - COALESCE(b.row_count, 0) AS row_count_delta

FROM tmp_m2_archive_inventory_before b

FULL OUTER JOIN tmp_m2_archive_inventory_after a
    ON a.strategy_set_name = b.strategy_set_name
   AND a.strategy_name = b.strategy_name
   AND a.strategy_version = b.strategy_version
   AND a.module1_scenario_set_name = b.module1_scenario_set_name
   AND a.module1_scenario_name = b.module1_scenario_name
   AND a.population_id = b.population_id

ORDER BY
    ABS(COALESCE(a.row_count, 0) - COALESCE(b.row_count, 0)) DESC,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
12.8.5 Archive row-level grain duplicate diagnostic.

Purpose:
    Confirm full archive uniqueness at archive row-level grain.

Expected:
    duplicate_archive_grain_count = 0.
-----------------------------------------------------------------------------------------------*/

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
) d;



/*-----------------------------------------------------------------------------------------------
12.8.6 Current archived slice row-count diagnostic.

Purpose:
    Confirm the archived current slice exists when archive_run_flag = TRUE.

Boundary:
    If archive_run_flag = FALSE, this query may show zero rows for the current slice if it was never
    previously archived.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    a.archive_run_flag,
    a.strategy_archive_reset_mode,
    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,

    COUNT(ar.*) AS current_archived_slice_rows,
    COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count,

    MIN(ar.archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(ar.archive_inserted_ts) AS max_archive_inserted_ts

FROM archive_context a

LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id

GROUP BY
    a.archive_run_flag,
    a.strategy_archive_reset_mode,
    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id;



/*-----------------------------------------------------------------------------------------------
12.8.7 Current archived slice decision distribution.

Purpose:
    Review final simulated outcome distribution in the archived current slice.

Boundary:
    decision_outcome remains a simulated strategy outcome, not real applicant treatment.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    ar.decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_current_archived_slice,

    AVG(ar.requested_amount) AS avg_requested_amount,
    AVG(ar.approved_amount) AS avg_approved_amount,
    AVG(ar.requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(ar.approved_expected_loss_amount) AS avg_approved_expected_loss_amount

FROM archive_context a

JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id

GROUP BY ar.decision_outcome

ORDER BY
    CASE ar.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
12.8.8 Current archived slice product × decision distribution.

Purpose:
    Confirm product-level outcome behavior is available in the archive for downstream Section 13,
    Section 14, Section 15, and Section 16 analysis.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    ar.product_type_policy_key,
    ar.decision_outcome,

    COUNT(*) AS row_count,

    AVG(ar.requested_amount) AS avg_requested_amount,
    AVG(ar.approved_amount) AS avg_approved_amount,
    AVG(ar.requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(ar.approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    AVG(ar.requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(ar.approved_expected_loss_amount) AS avg_approved_expected_loss_amount

FROM archive_context a

JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id

GROUP BY
    ar.product_type_policy_key,
    ar.decision_outcome

ORDER BY
    ar.product_type_policy_key,
    CASE ar.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;



/*-----------------------------------------------------------------------------------------------
12.8.9 Current archived slice primary reason-code distribution.

Purpose:
    Confirm simulated explanation-code evidence is available in the archive.

Boundary:
    Reason codes remain simulated strategy explanation codes, not customer communications.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    ar.primary_reason_family,
    ar.primary_reason_code,

    COUNT(*) AS row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_current_archived_slice

FROM archive_context a

JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id

GROUP BY
    ar.primary_reason_family,
    ar.primary_reason_code

ORDER BY
    CASE ar.primary_reason_family
        WHEN 'POLICY_STOP' THEN 1
        WHEN 'MANUAL_REVIEW' THEN 2
        WHEN 'COUNTEROFFER' THEN 3
        WHEN 'APPROVAL' THEN 4
        ELSE 99
    END,
    ar.primary_reason_code;



/*-----------------------------------------------------------------------------------------------
12.8.10 Current archived slice requested versus approved exposure / Expected Loss summary.

Purpose:
    Review portfolio-impact metrics in the archived current slice.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss.
    approved_expected_loss_amount is approved-exposure Expected Loss.
    archive_inserted_ts is archive persistence metadata.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    COUNT(*) AS current_archived_slice_rows,

    SUM(ar.requested_amount) AS total_requested_amount,
    SUM(COALESCE(ar.approved_amount, 0)) AS total_approved_amount,

    SUM(COALESCE(ar.approved_amount, 0))
        / NULLIF(SUM(ar.requested_amount), 0) AS approved_amount_capture_rate,

    SUM(ar.requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        / NULLIF(SUM(COALESCE(ar.approved_amount, 0)), 0) AS approved_expected_loss_rate,

    AVG(ar.requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

    AVG(ar.approved_payment_to_income_ratio)
        FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows,

    MIN(ar.latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(ar.latest_output_created_ts) AS max_latest_output_created_ts,
    MIN(ar.archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(ar.archive_inserted_ts) AS max_archive_inserted_ts

FROM archive_context a

JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id;



/*-----------------------------------------------------------------------------------------------
12.8.11 Archive mode diagnostic.

Purpose:
    Show the archive action and row-count effect in one compact row.

Interpretation:
    This is the quickest Section 12 audit view.
-----------------------------------------------------------------------------------------------*/

SELECT
    archive_run_flag,
    strategy_archive_reset_mode,

    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    latest_run_row_count,
    latest_run_distinct_application_count,

    archive_row_count_before,
    archive_deleted_rows,
    archive_inserted_rows,
    archive_row_count_after,

    archive_action,
    archive_action_ts

FROM tmp_m2_archive_persistence_audit;



/*-----------------------------------------------------------------------------------------------
12.8.12 Section 12 readiness summary.

Purpose:
    Provide one compact readiness row for archive persistence.

Expected:
    If archive_run_flag = TRUE:
        SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA

    If archive_run_flag = FALSE:
        SECTION_12_ARCHIVE_PERSISTENCE_SKIPPED_BY_CONTROL

Interpretation:
    This confirms only Section 12 archive persistence status.

    It does not validate Section 13 comparison readiness.
    It does not validate Section 14 QA.
    It does not validate Section 15 frontier completeness.
    It does not validate Section 16 evidence capture.
-----------------------------------------------------------------------------------------------*/

WITH audit_row AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
),

current_archive AS (
    SELECT
        a.archive_run_flag,
        a.strategy_archive_reset_mode,
        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id,

        COUNT(ar.*) AS current_archived_slice_rows,
        COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count,
        COUNT(ar.*) FILTER (WHERE ar.archive_inserted_ts IS NULL) AS current_archived_slice_null_archive_ts_rows
    FROM audit_row a

    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
        ON ar.strategy_set_name = a.strategy_set_name
       AND ar.strategy_name = a.strategy_name
       AND ar.strategy_version = a.strategy_version
       AND ar.module1_scenario_set_name = a.module1_scenario_set_name
       AND ar.module1_scenario_name = a.module1_scenario_name
       AND ar.population_id = a.population_id

    GROUP BY
        a.archive_run_flag,
        a.strategy_archive_reset_mode,
        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id
),

archive_duplicates AS (
    SELECT COUNT(*) AS duplicate_archive_grain_count
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

inventory_diff AS (
    SELECT COUNT(*) AS before_after_inventory_diff_count
    FROM (
        SELECT
            COALESCE(b.strategy_set_name, a.strategy_set_name) AS strategy_set_name,
            COALESCE(b.strategy_name, a.strategy_name) AS strategy_name,
            COALESCE(b.strategy_version, a.strategy_version) AS strategy_version,
            COALESCE(b.module1_scenario_set_name, a.module1_scenario_set_name) AS module1_scenario_set_name,
            COALESCE(b.module1_scenario_name, a.module1_scenario_name) AS module1_scenario_name,
            COALESCE(b.population_id, a.population_id) AS population_id,
            COALESCE(b.row_count, 0) AS before_row_count,
            COALESCE(a.row_count, 0) AS after_row_count
        FROM tmp_m2_archive_inventory_before b
        FULL OUTER JOIN tmp_m2_archive_inventory_after a
            ON a.strategy_set_name = b.strategy_set_name
           AND a.strategy_name = b.strategy_name
           AND a.strategy_version = b.strategy_version
           AND a.module1_scenario_set_name = b.module1_scenario_set_name
           AND a.module1_scenario_name = b.module1_scenario_name
           AND a.population_id = b.population_id
    ) x
    WHERE before_row_count <> after_row_count
)

SELECT
    a.archive_run_flag,
    a.strategy_archive_reset_mode,

    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,

    a.latest_run_row_count,
    a.latest_run_distinct_application_count,

    a.archive_row_count_before,
    a.archive_deleted_rows,
    a.archive_inserted_rows,
    a.archive_row_count_after,
    a.archive_action,

    ca.current_archived_slice_rows,
    ca.current_archived_slice_distinct_application_id_count,
    ca.current_archived_slice_null_archive_ts_rows,

    ad.duplicate_archive_grain_count,
    id.before_after_inventory_diff_count,

    CASE
        WHEN a.archive_run_flag IS FALSE
         AND a.archive_deleted_rows = 0
         AND a.archive_inserted_rows = 0
         AND a.archive_row_count_after = a.archive_row_count_before
         AND id.before_after_inventory_diff_count = 0
            THEN 'SECTION_12_ARCHIVE_PERSISTENCE_SKIPPED_BY_CONTROL'

        WHEN a.archive_run_flag IS TRUE
         AND a.archive_inserted_rows = a.latest_run_row_count
         AND ca.current_archived_slice_rows = a.latest_run_row_count
         AND ca.current_archived_slice_distinct_application_id_count = a.latest_run_row_count
         AND ca.current_archived_slice_null_archive_ts_rows = 0
         AND ad.duplicate_archive_grain_count = 0
            THEN 'SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA'

        ELSE 'REVIEW_SECTION_12_ARCHIVE_PERSISTENCE_BEFORE_COMPARISON_OR_QA'
    END AS section_12_archive_persistence_status

FROM audit_row a
CROSS JOIN current_archive ca
CROSS JOIN archive_duplicates ad
CROSS JOIN inventory_diff id;



/***************************************************************************************************
END OF SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions existed and was populated.
    2. latest-run application_id uniqueness was validated.
    3. latest-run archive controls were populated and unambiguous.
    4. latest-run archive replacement key was populated and unambiguous.
    5. credit_decisioning_sim.strategy_decisions_archive exists.
    6. archive_inserted_ts exists.
    7. Archive table contains all latest-run columns plus archive_inserted_ts.
    8. Missing latest-run columns were added to the archive table where safe.
    9. Common latest-run / archive columns have aligned PostgreSQL data types.
    10. Unexpected archive columns do not exist, except archive_inserted_ts.
    11. Archive inventory before persistence was captured.
    12. Archive control logic was applied.
    13. Archive inventory after persistence was captured.
    14. Archive validation indexes were created.
    15. Archive row-level grain was protected by a unique index.
    16. archive_run_flag = FALSE skipped persistence without deleting or inserting archive rows.
    17. archive_run_flag = TRUE persisted latest-run rows according to strategy_archive_reset_mode.
    18. STRATEGY_SCENARIO_ONLY replaced only the current replacement key.
    19. STRATEGY_SET_ONLY replaced the selected strategy set for the selected Module 1 scenario and
        population.
    20. ALL reset the full archive before inserting the current latest-run output.
    21. NONE inserted only when the current replacement key did not already exist.
    22. Current archived slice row count was validated when archive_run_flag = TRUE.
    23. Current archived slice application_id uniqueness was validated when archive_run_flag = TRUE.
    24. Current archived slice archive_inserted_ts was validated when archive_run_flag = TRUE.
    25. Latest-run values were compared to archived current-slice values when archive_run_flag = TRUE.
    26. Archive diagnostics are available for inventory and current-slice review.

Section 12 established:
    1. The governed Module 2 strategy archive history layer.
    2. Archive replacement discipline.
    3. Archive schema compatibility.
    4. Archive row-level grain protection.
    5. Archive persistence auditability.
    6. Current-slice persistence fidelity.
    7. The archive foundation required by Section 13 matched comparison and Section 15 frontier review.

No decision outcomes have been recalculated.
No decision paths have been recalculated.
No approved exposure values have been recalculated.
No approved payment proxy values have been recalculated.
No approved PTI values have been recalculated.
No approved Expected Loss values have been recalculated.
No simulated reason codes have been reassigned.
No campaign registry rows have been modified.
No comparison registry rows have been modified.
No evidence rows have been inserted.
No matched strategy comparison has been performed.
No full Module 2 QA framework has been performed.
No strategy frontier has been calculated.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 13 should consume credit_decisioning_sim.strategy_decisions_archive for archive inventory
    and governed matched baseline / challenger strategy comparison.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01590 -->


---

<a id="c038-m01591"></a>

### C038-M01591

**Andrew** · 2026-05-12T11:57:16.610000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01591 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 13 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01591 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_81.md) · [Next](Part_83.md)
