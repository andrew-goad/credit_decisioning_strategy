# Module 2 Decision Simulator Build

## Part 30

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_29.md) · [Next](Part_31.md)

<a id="c038-m00711"></a>

### C038-M00711

**ChatGPT** · 2026-05-09T17:03:39.923096-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00711 -->
Section 12 hardened below, using the uploaded Section 12 archive-persistence layer as the base and preserving the accepted archive controls, schema-alignment checks, validation-index support, fail-fast archive gatekeepers, and 12.8.11 archive-mode diagnostic. fileciteturn36file0

```sql
/***************************************************************************************************
SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Persist completed latest-run Module 2 strategy outputs into a governed archive table.

    Section 12 answers:

        "Should this completed Module 2 strategy run be archived, and if so, how should existing
         archive rows be handled before inserting the current latest-run output?"

SQL PURPOSE:
    1. Consume credit_decisioning_sim.strategy_decisions.
    2. Create or reuse credit_decisioning_sim.strategy_decisions_archive.
    3. Validate latest-run archive controls.
    4. Validate archive schema alignment.
    5. Capture archive inventory before persistence.
    6. Apply governed archive reset / replacement behavior.
    7. Insert the current latest-run output into the archive when archive_run_flag = TRUE.
    8. Add archive_inserted_ts as archive persistence audit metadata.
    9. Capture archive inventory after persistence.
    10. Add archive validation indexes before row-level persistence checks.
    11. Validate archive grain, current slice integrity, and archive-control behavior.
    12. Create practical archive indexes.
    13. Provide lightweight archive diagnostics.

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

    credit_decisioning_sim.strategy_decisions_archive is the governed history layer.

    It supports:
        completed-run retention,
        rerun replacement control,
        strategy comparison,
        strategy frontier analysis,
        validation evidence review,
        and documentation traceability.

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
        or final outcome flags.

    It persists the already-materialized latest-run output.

ARCHIVE GRAIN:
    One row per application
    × Module 1 scenario
    × Module 2 strategy version.

Archive row-level grain fields:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id

ARCHIVE REPLACEMENT / RERUN KEY:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

WHY APPLICATION_ID IS EXCLUDED FROM THE REPLACEMENT KEY:
    The replacement key identifies the completed strategy / scenario / population slice.

    application_id identifies each row within that slice.

    Deleting by replacement key clears the whole prior slice before inserting the current completed
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
    None of them should define matched strategy comparison grain.

ARCHIVE CONTROL MODES:
    archive_run_flag = FALSE:
        Skip archive persistence.
        Do not delete archive rows.
        Do not insert archive rows.

    strategy_archive_reset_mode = NONE:
        Do not delete existing archive rows before insert.
        Fail if the current replacement key already exists.

    strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY:
        Ordinary rerun mode.
        Replace only the current strategy / Module 1 scenario / population slice.

    strategy_archive_reset_mode = STRATEGY_SET_ONLY:
        Broader reset mode.
        Replace all strategy_name / strategy_version outputs within the current strategy_set_name
        for the selected Module 1 scenario and population.

    strategy_archive_reset_mode = ALL:
        Broadest reset mode.
        Delete all archive rows before inserting the current latest-run output.

SCHEMA ALIGNMENT NOTE:
    The archive table is created from the current latest-run output schema when it does not exist.

    If the latest-run schema changes after the archive already exists, the archive table may need to
    be altered or recreated so both schemas remain aligned.

    Section 12 includes practical schema alignment gatekeepers:
        missing-column checks,
        data-type alignment checks,
        unexpected archive column checks,
        and archive_inserted_ts existence checks.

    It does not attempt to build a full dynamic schema migration system.

WHY ARCHIVE VALIDATION INDEXES ARE CREATED BEFORE SECTION 12.6:
    Section 12.6 compares latest-run rows to archived rows at row-level archive grain.

    As the archive grows across strategy and scenario slices, row-level validation can become slow if
    the latest-run and archive tables lack supporting indexes.

    Section 12.5A therefore creates validation indexes before Section 12.6 performs persistence
    fidelity checks.

CAMPAIGN REGISTRY BOUNDARY:
    Campaign IDs such as module1_run_id, module2_run_id, showcase_id, comparison_group_id, and
    validation_evidence_group_id are evidence-linkage metadata.

    They are persisted later through Section 16 evidence capture.

    They do not replace archive grain and are not inserted into every archive row in Section 12.

MATCHED COMPARISON BOUNDARY:
    Section 12 persists archive rows.

    It does not compare archived strategies.

    Matched strategy comparison is built in Section 13.

GOVERNANCE ROLE:
    Section 12 protects history, replacement discipline, schema consistency, archive grain, and
    persistence fidelity before archive comparison or executive evidence capture occurs.

COMMON MISUSE TO AVOID:
    Do not use the latest-run table as strategy history.
    Do not manually delete archive rows outside governed archive controls.
    Do not treat timestamp fields as matched-comparison keys.
    Do not interpret archive persistence as recalculation or revalidation of decision logic.
    Do not interpret archive_inserted_ts as a business outcome.

***************************************************************************************************/



/***************************************************************************************************
SECTION 12.1 — LATEST-RUN SOURCE INTEGRITY AND ARCHIVE-CONTROL PREFLIGHT
****************************************************************************************************

PURPOSE:
    Confirm that the latest-run strategy_decisions table exists, is populated, is unique at
    application_id, and contains one unambiguous archive-control configuration and replacement key.

BUSINESS PURPOSE:
    Archive persistence should operate on one completed latest-run strategy slice.

    A mixed latest-run table would make archive reset behavior ambiguous and could corrupt archive
    history.

***************************************************************************************************/

DO $$
DECLARE
    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;
    v_archive_control_null_count BIGINT;
    v_archive_control_invalid_count BIGINT;
    v_archive_flag_value_count BIGINT;
    v_archive_mode_value_count BIGINT;
    v_archive_key_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must exist.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: credit_decisioning_sim.strategy_decisions does not exist.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output must contain rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run strategy_decisions table contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run application_id must be unique.

    Section 12 archive persistence assumes one latest-run row per application_id.
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
    Gatekeeper: archive controls must be populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_control_null_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE archive_run_flag IS NULL
       OR strategy_archive_reset_mode IS NULL
       OR NULLIF(BTRIM(strategy_archive_reset_mode), '') IS NULL;

    IF v_archive_control_null_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % latest-run row(s) have null archive controls.',
            v_archive_control_null_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive reset mode must be valid.
    -------------------------------------------------------------------------------------------*/
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
    Gatekeeper: latest-run table must contain exactly one archive control configuration.

    A mixed latest-run output would make archive behavior ambiguous.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT archive_run_flag)
    INTO v_archive_flag_value_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_archive_flag_value_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % distinct archive_run_flag values. Expected exactly one.',
            v_archive_flag_value_count;
    END IF;

    SELECT COUNT(DISTINCT strategy_archive_reset_mode)
    INTO v_archive_mode_value_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_archive_mode_value_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % distinct strategy_archive_reset_mode values. Expected exactly one.',
            v_archive_mode_value_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run table must contain exactly one archive replacement / rerun key.

    The latest-run output should represent one strategy / Module 1 scenario / population slice.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_key_count
    FROM (
        SELECT DISTINCT
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        FROM credit_decisioning_sim.strategy_decisions
    ) k;

    IF v_archive_key_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % archive replacement keys. Expected exactly one.',
            v_archive_key_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.2 — ARCHIVE TABLE SETUP AND SCHEMA ALIGNMENT CHECK
****************************************************************************************************

ARCHIVE TABLE DESIGN:
    all fields from credit_decisioning_sim.strategy_decisions
    plus archive_inserted_ts.

archive_inserted_ts:
    Audit metadata indicating when the latest-run output was persisted to archive.

WHY SCHEMA ALIGNMENT MATTERS:
    Archive rows should be a faithful persisted copy of the governed latest-run output.

    If the latest-run schema and archive schema diverge, matched comparison, frontier analysis,
    QA review, and evidence capture can become unreliable.

***************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_decisions_archive
(LIKE credit_decisioning_sim.strategy_decisions INCLUDING DEFAULTS);

ALTER TABLE credit_decisioning_sim.strategy_decisions_archive
ADD COLUMN IF NOT EXISTS archive_inserted_ts TIMESTAMP;


/*-----------------------------------------------------------------------------------------------
Practical schema-alignment gatekeeper.

If the archive already existed before the latest-run schema changed, it may be missing columns, may
contain incompatible data types, or may contain unexpected extra columns.

This gatekeeper fails clearly rather than silently inserting misaligned rows.
-----------------------------------------------------------------------------------------------*/
DO $$
DECLARE
    v_missing_archive_columns TEXT;
    v_type_mismatch_columns TEXT;
    v_unexpected_archive_columns TEXT;
    v_archive_inserted_ts_exists BOOLEAN;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Missing-column check.

    The archive should contain every latest-run column.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(l.column_name, ', ' ORDER BY l.ordinal_position)
    INTO v_missing_archive_columns
    FROM information_schema.columns l
    WHERE l.table_schema = 'credit_decisioning_sim'
      AND l.table_name = 'strategy_decisions'
      AND NOT EXISTS (
            SELECT 1
            FROM information_schema.columns a
            WHERE a.table_schema = 'credit_decisioning_sim'
              AND a.table_name = 'strategy_decisions_archive'
              AND a.column_name = l.column_name
      );

    IF v_missing_archive_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive is missing latest-run column(s): %. Align or recreate the archive table before persistence.',
            v_missing_archive_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Data-type alignment check.

    The archive table may already exist from an earlier implementation version. A missing-column
    check alone is not sufficient because the archive could contain the same column names with
    incompatible data types.

    This is a schema governance check, not a modeling check.
    -------------------------------------------------------------------------------------------*/
    WITH common_columns AS (
        SELECT
            l.column_name,

            l.data_type AS latest_data_type,
            a.data_type AS archive_data_type,

            l.numeric_precision AS latest_numeric_precision,
            a.numeric_precision AS archive_numeric_precision,

            l.numeric_scale AS latest_numeric_scale,
            a.numeric_scale AS archive_numeric_scale,

            l.character_maximum_length AS latest_character_maximum_length,
            a.character_maximum_length AS archive_character_maximum_length,

            l.datetime_precision AS latest_datetime_precision,
            a.datetime_precision AS archive_datetime_precision,

            l.ordinal_position
        FROM information_schema.columns l
        JOIN information_schema.columns a
            ON a.table_schema = 'credit_decisioning_sim'
           AND a.table_name = 'strategy_decisions_archive'
           AND a.column_name = l.column_name
        WHERE l.table_schema = 'credit_decisioning_sim'
          AND l.table_name = 'strategy_decisions'
    )
    SELECT STRING_AGG(
        FORMAT(
            '%s latest(data_type=%s, numeric_precision=%s, numeric_scale=%s, char_len=%s, datetime_precision=%s) archive(data_type=%s, numeric_precision=%s, numeric_scale=%s, char_len=%s, datetime_precision=%s)',
            column_name,
            COALESCE(latest_data_type, '<NULL>'),
            COALESCE(latest_numeric_precision::TEXT, '<NULL>'),
            COALESCE(latest_numeric_scale::TEXT, '<NULL>'),
            COALESCE(latest_character_maximum_length::TEXT, '<NULL>'),
            COALESCE(latest_datetime_precision::TEXT, '<NULL>'),
            COALESCE(archive_data_type, '<NULL>'),
            COALESCE(archive_numeric_precision::TEXT, '<NULL>'),
            COALESCE(archive_numeric_scale::TEXT, '<NULL>'),
            COALESCE(archive_character_maximum_length::TEXT, '<NULL>'),
            COALESCE(archive_datetime_precision::TEXT, '<NULL>')
        ),
        '; '
        ORDER BY ordinal_position
    )
    INTO v_type_mismatch_columns
    FROM common_columns
    WHERE latest_data_type IS DISTINCT FROM archive_data_type
       OR latest_numeric_precision IS DISTINCT FROM archive_numeric_precision
       OR latest_numeric_scale IS DISTINCT FROM archive_numeric_scale
       OR latest_character_maximum_length IS DISTINCT FROM archive_character_maximum_length
       OR latest_datetime_precision IS DISTINCT FROM archive_datetime_precision;

    IF v_type_mismatch_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive has data-type mismatch(es) versus strategy_decisions: %.',
            v_type_mismatch_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Unexpected archive column check.

    For Module 2 V1.0, the archive should be a persisted copy of the governed latest-run output plus
    archive_inserted_ts.

    Unexpected extra columns may indicate an older incompatible archive schema.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(a.column_name, ', ' ORDER BY a.ordinal_position)
    INTO v_unexpected_archive_columns
    FROM information_schema.columns a
    WHERE a.table_schema = 'credit_decisioning_sim'
      AND a.table_name = 'strategy_decisions_archive'
      AND a.column_name <> 'archive_inserted_ts'
      AND NOT EXISTS (
            SELECT 1
            FROM information_schema.columns l
            WHERE l.table_schema = 'credit_decisioning_sim'
              AND l.table_name = 'strategy_decisions'
              AND l.column_name = a.column_name
      );

    IF v_unexpected_archive_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive contains unexpected non-latest-run column(s): %. Align or recreate the archive table before persistence.',
            v_unexpected_archive_columns;
    END IF;


    /*-------------------------------------------------------------------------------------------
    archive_inserted_ts existence check.

    This column exists only on the archive table and is excluded from latest-run-to-archive schema
    comparisons.
    -------------------------------------------------------------------------------------------*/
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
            'Module 2 Section 12 failure: strategy_decisions_archive is missing archive_inserted_ts.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.3 — ARCHIVE INVENTORY SNAPSHOT BEFORE PERSISTENCE
****************************************************************************************************

PURPOSE:
    Capture archive inventory before any delete / insert behavior so Section 12 can validate that
    archive reset modes do not unintentionally affect unrelated strategy slices.

BUSINESS PURPOSE:
    Archive reset behavior must be observable.

    Capturing inventory before persistence lets the module compare what changed after Section 12.4.

***************************************************************************************************/

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
    archive_run_flag                         BOOLEAN,
    strategy_archive_reset_mode              TEXT,

    strategy_set_name                        TEXT,
    strategy_name                            TEXT,
    strategy_version                         TEXT,
    module1_scenario_set_name                TEXT,
    module1_scenario_name                    TEXT,
    population_id                            TEXT,

    latest_run_row_count                     BIGINT,
    latest_run_distinct_application_count    BIGINT,

    archive_row_count_before                 BIGINT,
    archive_deleted_rows                     BIGINT,
    archive_inserted_rows                    BIGINT,
    archive_row_count_after                  BIGINT,

    archive_action                           TEXT,
    archive_action_ts                        TIMESTAMP
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 12.4 — APPLY ARCHIVE CONTROL LOGIC
****************************************************************************************************

PURPOSE:
    Apply the active archive_run_flag and strategy_archive_reset_mode controls.

BUSINESS PURPOSE:
    Archive persistence should be governed, repeatable, and explainable.

    Users should be able to distinguish:
        skipped persistence,
        append-only insert,
        ordinary slice replacement,
        strategy-set replacement,
        and full archive reset.

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
    Read the single archive-control configuration and archive replacement key from latest-run output.

    Section 12.1 has already validated that exactly one such configuration exists.
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

    SELECT
        COUNT(*),
        COUNT(DISTINCT application_id)
    INTO
        v_latest_count,
        v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    SELECT COUNT(*)
    INTO v_archive_before_count
    FROM credit_decisioning_sim.strategy_decisions_archive;


    /*-------------------------------------------------------------------------------------------
    archive_run_flag = FALSE:
        Skip archive persistence.
        Do not delete archive rows.
        Do not insert archive rows.
    -------------------------------------------------------------------------------------------*/
    IF v_archive_run_flag IS FALSE THEN
        v_archive_action := 'ARCHIVE_PERSISTENCE_SKIPPED_ARCHIVE_RUN_FLAG_FALSE';
        v_deleted_rows := 0;
        v_inserted_rows := 0;

        RAISE NOTICE
            'Module 2 Section 12: archive persistence skipped because archive_run_flag = FALSE. Existing archive rows preserved.';


    ELSE
        /*---------------------------------------------------------------------------------------
        archive_run_flag = TRUE:
            Apply governed reset mode before inserting current latest-run rows.
        ---------------------------------------------------------------------------------------*/

        IF v_strategy_archive_reset_mode = 'NONE' THEN
            /*-----------------------------------------------------------------------------------
            NONE:
                Append only if the current replacement key does not already exist.
                This prevents silent duplicate archive slices.
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
                    'Module 2 Section 12 failure: strategy_archive_reset_mode = NONE, but % archive row(s) already exist for the current replacement key.',
                    v_existing_key_count;
            END IF;

            v_archive_action := 'ARCHIVE_INSERT_WITHOUT_DELETE_NONE_MODE';
            v_deleted_rows := 0;


        ELSIF v_strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY' THEN
            /*-----------------------------------------------------------------------------------
            STRATEGY_SCENARIO_ONLY:
                Ordinary rerun mode.
                Replace only the exact strategy / Module 1 scenario / population slice.
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
                Broader reset mode.
                Clears all strategy_name / strategy_version outputs within the same strategy set
                for the selected Module 1 scenario and population.
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
                Broad reset mode.
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

        The dynamic column list is derived from the latest-run table schema so the INSERT is explicit
        and does not depend on physical column order. archive_inserted_ts is added separately.
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


    SELECT COUNT(*)
    INTO v_archive_after_count
    FROM credit_decisioning_sim.strategy_decisions_archive;


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

PURPOSE:
    Capture archive inventory after archive control logic runs.

BUSINESS PURPOSE:
    The after snapshot supports Section 12.6 validation of skip behavior, replacement behavior, and
    reset-mode scope.

***************************************************************************************************/

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

PURPOSE:
    Support efficient archive persistence validation before Section 12.6 row-level gatekeepers.

BUSINESS PURPOSE:
    Section 12.6 compares the latest-run table to the current archived slice and validates archive
    grain integrity.

    These are validation checks, not strategy logic. They should not become a runtime bottleneck as
    the archive grows across multiple strategy and scenario slices.

BOUNDARY:
    This section does not recalculate decision_outcome.
    This section does not recalculate approved exposure.
    This section does not recalculate approved Expected Loss.
    This section does not reassign simulated reason codes.
    This section only supports efficient archive validation.

WHY THIS EXISTS:
    The archive replacement / rerun key identifies the strategy × Module 1 scenario × population
    slice.

    The row-level archive grain additionally includes application_id.

    Section 12.6 compares latest-run rows to archived rows at the row-level grain. Without a
    supporting index, PostgreSQL may choose a poor plan, especially as the archive grows.

***************************************************************************************************/

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


/*
Unique archive grain enforcement:
    The archive should not contain duplicate rows for the same application under the same Module 1
    scenario and Module 2 strategy version.

    If duplicates already exist, this index creation will fail clearly. That is preferable to
    allowing ambiguous matched comparison later.
*/
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_unique_grain
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

PURPOSE:
    Validate archive persistence behavior before matched comparison or full QA is built.

BUSINESS PURPOSE:
    Confirm that archive persistence preserved latest-run results, applied archive controls within
    the expected scope, and maintained archive grain.

THESE CHECKS VALIDATE:
    latest-run source integrity,
    archive table existence,
    archive skip behavior,
    archive insert behavior,
    archive mode behavior,
    archive grain integrity,
    and persistence fidelity.

BOUNDARY:
    These are archive persistence gatekeepers only.

    They are not:
        matched strategy comparison,
        full latest-run QA,
        executive frontier analysis,
        or evidence capture.

***************************************************************************************************/

DO $$
DECLARE
    a RECORD;

    v_archive_table_exists BOOLEAN;
    v_archive_inserted_ts_exists BOOLEAN;
    v_archive_unique_grain_index_valid BOOLEAN;

    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;

    v_current_archive_count BIGINT;
    v_current_archive_distinct_app_count BIGINT;
    v_current_archive_null_ts_count BIGINT;
    v_current_archive_duplicate_app_count BIGINT;

    v_inventory_diff_count BIGINT;
    v_after_inventory_group_count BIGINT;
    v_persistence_mismatch_count BIGINT;
BEGIN
    SELECT *
    INTO a
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1;

    IF a IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: tmp_m2_archive_persistence_audit contains no rows.';
    END IF;


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
    Gatekeeper: archive_run_flag = FALSE skip behavior.

    Skip mode should not delete or insert archive rows.
    Existing archive inventory should remain unchanged.
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
        ) d
        WHERE before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive inventory changed even though archive_run_flag = FALSE.';
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive_run_flag = TRUE insert behavior.

    The current archived slice should contain exactly one row per latest-run application_id.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS TRUE THEN
        IF a.archive_inserted_rows <> v_latest_count THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive_inserted_rows (%) does not equal latest-run row count (%).',
                a.archive_inserted_rows,
                v_latest_count;
        END IF;

        IF a.strategy_archive_reset_mode = 'NONE'
           AND a.archive_deleted_rows <> 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: NONE mode deleted % archive row(s); expected zero.',
                a.archive_deleted_rows;
        END IF;

        IF a.strategy_archive_reset_mode = 'ALL'
           AND a.archive_deleted_rows <> a.archive_row_count_before THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: ALL mode deleted % row(s), but archive_row_count_before was %.',
                a.archive_deleted_rows,
                a.archive_row_count_before;
        END IF;

        SELECT
            COUNT(*),
            COUNT(DISTINCT application_id)
        INTO
            v_current_archive_count,
            v_current_archive_distinct_app_count
        FROM credit_decisioning_sim.strategy_decisions_archive
        WHERE strategy_set_name = a.strategy_set_name
          AND strategy_name = a.strategy_name
          AND strategy_version = a.strategy_version
          AND module1_scenario_set_name = a.module1_scenario_set_name
          AND module1_scenario_name = a.module1_scenario_name
          AND population_id = a.population_id;

        IF v_current_archive_count <> v_latest_count THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: current archived slice row count (%) does not match latest-run row count (%).',
                v_current_archive_count,
                v_latest_count;
        END IF;

        IF v_current_archive_distinct_app_count <> v_latest_distinct_app_count THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: current archived slice distinct application_id count (%) does not match latest-run distinct application_id count (%).',
                v_current_archive_distinct_app_count,
                v_latest_distinct_app_count;
        END IF;

        SELECT COUNT(*)
        INTO v_current_archive_null_ts_count
        FROM credit_decisioning_sim.strategy_decisions_archive
        WHERE strategy_set_name = a.strategy_set_name
          AND strategy_name = a.strategy_name
          AND strategy_version = a.strategy_version
          AND module1_scenario_set_name = a.module1_scenario_set_name
          AND module1_scenario_name = a.module1_scenario_name
          AND population_id = a.population_id
          AND archive_inserted_ts IS NULL;

        IF v_current_archive_null_ts_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: % current archived slice row(s) have null archive_inserted_ts.',
                v_current_archive_null_ts_count;
        END IF;

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

        IF v_current_archive_duplicate_app_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: current archived slice contains % duplicate application_id group(s).',
                v_current_archive_duplicate_app_count;
        END IF;


        /*---------------------------------------------------------------------------------------
        Gatekeeper: persisted archive rows must match latest-run values for core decision, exposure,
        affordability, Expected Loss, reason-code, and lineage fields.

        This confirms Section 12 persisted the already-materialized strategy result rather than
        recalculating or altering it.

        archive_inserted_ts is intentionally not compared to latest_output_created_ts. They are
        different audit timestamps with different meanings.
        ---------------------------------------------------------------------------------------*/
        SELECT COUNT(*)
        INTO v_persistence_mismatch_count
        FROM credit_decisioning_sim.strategy_decisions sd
        JOIN credit_decisioning_sim.strategy_decisions_archive ar
            ON ar.strategy_set_name = sd.strategy_set_name
           AND ar.strategy_name = sd.strategy_name
           AND ar.strategy_version = sd.strategy_version
           AND ar.module1_scenario_set_name = sd.module1_scenario_set_name
           AND ar.module1_scenario_name = sd.module1_scenario_name
           AND ar.population_id = sd.population_id
           AND ar.application_id = sd.application_id
        WHERE sd.strategy_set_name = a.strategy_set_name
          AND sd.strategy_name = a.strategy_name
          AND sd.strategy_version = a.strategy_version
          AND sd.module1_scenario_set_name = a.module1_scenario_set_name
          AND sd.module1_scenario_name = a.module1_scenario_name
          AND sd.population_id = a.population_id
          AND (
                /* Key metadata and lineage fields */
                ar.strategy_set_name IS DISTINCT FROM sd.strategy_set_name
             OR ar.strategy_name IS DISTINCT FROM sd.strategy_name
             OR ar.strategy_version IS DISTINCT FROM sd.strategy_version
             OR ar.module1_scenario_set_name IS DISTINCT FROM sd.module1_scenario_set_name
             OR ar.module1_scenario_name IS DISTINCT FROM sd.module1_scenario_name
             OR ar.population_id IS DISTINCT FROM sd.population_id
             OR ar.application_id IS DISTINCT FROM sd.application_id
             OR ar.applicant_id IS DISTINCT FROM sd.applicant_id
             OR ar.product_type_policy_key IS DISTINCT FROM sd.product_type_policy_key
             OR ar.score_band_policy_key IS DISTINCT FROM sd.score_band_policy_key

                /* Final decision fields */
             OR ar.decision_outcome IS DISTINCT FROM sd.decision_outcome
             OR ar.decision_path IS DISTINCT FROM sd.decision_path
             OR ar.decision_priority_rank IS DISTINCT FROM sd.decision_priority_rank
             OR ar.decision_resolution_source IS DISTINCT FROM sd.decision_resolution_source

                /* Final decision flags */
             OR ar.approval_flag IS DISTINCT FROM sd.approval_flag
             OR ar.counteroffer_flag IS DISTINCT FROM sd.counteroffer_flag
             OR ar.manual_review_flag IS DISTINCT FROM sd.manual_review_flag
             OR ar.decline_flag IS DISTINCT FROM sd.decline_flag
             OR ar.simulated_offer_exposure_flag IS DISTINCT FROM sd.simulated_offer_exposure_flag

                /* Final exposure fields */
             OR ar.approved_amount IS DISTINCT FROM sd.approved_amount
             OR ar.counteroffer_amount IS DISTINCT FROM sd.counteroffer_amount
             OR ar.exposure_reduction_flag IS DISTINCT FROM sd.exposure_reduction_flag
             OR ar.exposure_reduction_amount IS DISTINCT FROM sd.exposure_reduction_amount
             OR ar.exposure_reduction_pct IS DISTINCT FROM sd.exposure_reduction_pct

                /* Final affordability fields */
             OR ar.approved_monthly_payment_proxy IS DISTINCT FROM sd.approved_monthly_payment_proxy
             OR ar.approved_payment_to_income_ratio IS DISTINCT FROM sd.approved_payment_to_income_ratio

                /* Requested and approved Expected Loss fields */
             OR ar.requested_expected_loss_amount IS DISTINCT FROM sd.requested_expected_loss_amount
             OR ar.approved_expected_loss_amount IS DISTINCT FROM sd.approved_expected_loss_amount
             OR ar.approved_el_reduction_amount IS DISTINCT FROM sd.approved_el_reduction_amount
             OR ar.approved_el_reduction_pct IS DISTINCT FROM sd.approved_el_reduction_pct

                /* Simulated reason-code fields */
             OR ar.primary_reason_code IS DISTINCT FROM sd.primary_reason_code
             OR ar.secondary_reason_code IS DISTINCT FROM sd.secondary_reason_code
             OR ar.tertiary_reason_code IS DISTINCT FROM sd.tertiary_reason_code
             OR ar.primary_reason_family IS DISTINCT FROM sd.primary_reason_family
             OR ar.triggered_reason_code_list IS DISTINCT FROM sd.triggered_reason_code_list
             OR ar.reason_priority_rank IS DISTINCT FROM sd.reason_priority_rank
             OR ar.reason_code_count IS DISTINCT FROM sd.reason_code_count
          );

        IF v_persistence_mismatch_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: % archived row(s) do not match latest-run core decision / exposure / economics / reason-code / lineage fields.',
                v_persistence_mismatch_count;
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive mode behavior — preserve unrelated archive inventory where applicable.

    NONE and STRATEGY_SCENARIO_ONLY should not change archive slices outside the current replacement
    key.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS TRUE
       AND a.strategy_archive_reset_mode IN ('NONE', 'STRATEGY_SCENARIO_ONLY') THEN

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
        ) d
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
                'Module 2 Section 12 failure: archive inventory outside the current replacement key changed under mode %.',
                a.strategy_archive_reset_mode;
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    STRATEGY_SET_ONLY may change any archive group within:
        current strategy_set_name
        current Module 1 scenario
        current population_id

    It should not change groups outside that selected strategy set / scenario / population scope.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS TRUE
       AND a.strategy_archive_reset_mode = 'STRATEGY_SET_ONLY' THEN

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
        ) d
        WHERE NOT (
                strategy_set_name = a.strategy_set_name
            AND module1_scenario_set_name = a.module1_scenario_set_name
            AND module1_scenario_name = a.module1_scenario_name
            AND population_id = a.population_id
        )
          AND before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive inventory outside the selected strategy set / scenario / population changed under STRATEGY_SET_ONLY mode.';
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    ALL mode should leave only the current latest-run replacement group after insertion.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS TRUE
       AND a.strategy_archive_reset_mode = 'ALL' THEN

        SELECT COUNT(*)
        INTO v_after_inventory_group_count
        FROM tmp_m2_archive_inventory_after;

        IF v_after_inventory_group_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: ALL reset mode should leave exactly one archive inventory group after current insert. Found %.',
                v_after_inventory_group_count;
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive row-level grain uniqueness must be enforced.

    The unique index created before Section 12.6 is the authoritative archive-grain control.
    This avoids repeatedly scanning and grouping the full archive as the archive grows.

    If duplicate archive grain existed, the unique index creation would have failed before this
    gatekeeper. This check confirms that the uniqueness control exists and is valid.
    -------------------------------------------------------------------------------------------*/
    SELECT EXISTS (
        SELECT 1
        FROM pg_index i
        JOIN pg_class idx
            ON idx.oid = i.indexrelid
        JOIN pg_class tbl
            ON tbl.oid = i.indrelid
        JOIN pg_namespace ns
            ON ns.oid = tbl.relnamespace
        WHERE ns.nspname = 'credit_decisioning_sim'
          AND tbl.relname = 'strategy_decisions_archive'
          AND idx.relname = 'idx_m2_strategy_decisions_archive_unique_grain'
          AND i.indisunique IS TRUE
          AND i.indisvalid IS TRUE
    )
    INTO v_archive_unique_grain_index_valid;

    IF v_archive_unique_grain_index_valid IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive unique row-level grain index is missing or invalid.';
    END IF;

    /*
    Boundary confirmation:
        Section 12 does not recalculate decision_outcome.
        Section 12 does not recalculate approved_amount.
        Section 12 does not recalculate approved_expected_loss_amount.
        Section 12 does not reassign simulated reason codes.
        Section 12 does not build matched strategy comparison queries.
        Section 12 does not build the full Module 2 QA framework.
    */
END $$;



/***************************************************************************************************
SECTION 12.7 — ARCHIVE INDEXES
****************************************************************************************************

PURPOSE:
    Support archive inventory, replacement-key lookup, row-level matching, strategy comparison, and
    reporting diagnostics.

BUSINESS PURPOSE:
    Archive history becomes more useful as it grows across strategy runs and Module 1 scenarios.

    Practical indexes support archive diagnostics and later matched comparison without changing any
    archived values.

BOUNDARY:
    Index creation does not change strategy outcomes, exposure economics, reason codes, or archive
    row content.

***************************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_strategy_identity
    ON credit_decisioning_sim.strategy_decisions_archive (
        strategy_set_name,
        strategy_name,
        strategy_version
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_module1_lineage
    ON credit_decisioning_sim.strategy_decisions_archive (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_replacement_key
    ON credit_decisioning_sim.strategy_decisions_archive (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_decision_outcome
    ON credit_decisioning_sim.strategy_decisions_archive (decision_outcome);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_product_decision
    ON credit_decisioning_sim.strategy_decisions_archive (
        product_type_policy_key,
        decision_outcome
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_score_decision
    ON credit_decisioning_sim.strategy_decisions_archive (
        score_band_policy_key,
        decision_outcome
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_primary_reason
    ON credit_decisioning_sim.strategy_decisions_archive (primary_reason_code);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_offer_exposure
    ON credit_decisioning_sim.strategy_decisions_archive (simulated_offer_exposure_flag);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_decisions_archive_inserted_ts
    ON credit_decisioning_sim.strategy_decisions_archive (archive_inserted_ts);



/***************************************************************************************************
SECTION 12.8 — LOCAL ARCHIVE PERSISTENCE DIAGNOSTICS
****************************************************************************************************

PURPOSE:
    Provide lightweight archive diagnostics after persistence.

BUSINESS PURPOSE:
    Let reviewers confirm what Section 12 did before moving to archive inventory, matched comparison,
    frontier summary, or evidence capture.

INTERPRETATION:
    These are archive diagnostics only.

    They are not:
        matched strategy comparison,
        full Module 2 QA,
        validation-summary evidence by themselves,
        or executive story capture.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
12.8.1 Archive persistence audit summary.

Interpretation:
    Shows whether Section 12 skipped, inserted, replaced, reset, and how many rows were affected.
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
12.8.2 Archive inventory before persistence.

Interpretation:
    Shows archive slices before Section 12.4 archive controls were applied.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    row_count
FROM tmp_m2_archive_inventory_before
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
12.8.3 Archive inventory after persistence.

Interpretation:
    Shows archive slices after Section 12.4 archive controls were applied.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    row_count
FROM tmp_m2_archive_inventory_after
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
12.8.4 Current archived slice row count and distinct application_id count.

Expected when archive_run_flag = TRUE:
    current_archived_slice_row_count = latest_run_row_count
    current_archived_slice_distinct_application_id_count = latest_run_distinct_application_count

Expected when archive_run_flag = FALSE:
    zero rows may return if the current slice was not previously archived.
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
    a.latest_run_row_count,
    COUNT(ar.*) AS current_archived_slice_row_count,
    COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count
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
    a.population_id,
    a.latest_run_row_count;


/*-----------------------------------------------------------------------------------------------
12.8.5 Current archived slice count by decision_outcome.

Interpretation:
    Archive-level outcome distribution for the current replacement key.
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
        100.0 * COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0),
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
12.8.6 Current archived slice count by primary_reason_code.

Interpretation:
    Reason-code fields are simulated strategy explanation codes.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)
SELECT
    ar.primary_reason_family,
    ar.primary_reason_code,
    COUNT(*) AS row_count
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
    ar.primary_reason_family,
    ar.primary_reason_code;


/*-----------------------------------------------------------------------------------------------
12.8.7 Current archived slice product × decision_outcome.

Interpretation:
    Product-level archive diagnostic for the current replacement key.
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
    AVG(ar.estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(ar.requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(ar.approved_payment_to_income_ratio)
        FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_payment_to_income_ratio_offer_rows
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
12.8.8 Current archived slice score band × decision_outcome.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)
SELECT
    ar.score_band_policy_key,
    ar.decision_outcome,
    COUNT(*) AS row_count,
    AVG(ar.credit_score) AS avg_credit_score,
    AVG(ar.estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
GROUP BY
    ar.score_band_policy_key,
    ar.decision_outcome
ORDER BY
    CASE ar.score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    CASE ar.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
12.8.9 Current archived slice simulated_offer_exposure_flag profile.

Interpretation:
    simulated_offer_exposure_flag indicates simulated positive offer exposure only.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)
SELECT
    ar.simulated_offer_exposure_flag,
    COUNT(*) AS row_count,
    SUM(COALESCE(ar.approved_amount, 0)) AS total_approved_amount,
    AVG(ar.estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
GROUP BY ar.simulated_offer_exposure_flag
ORDER BY ar.simulated_offer_exposure_flag;


/*-----------------------------------------------------------------------------------------------
12.8.10 Current archived slice exposure, Expected Loss, and timestamp summary.

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
    ar.decision_outcome,
    COUNT(*) AS row_count,

    SUM(ar.requested_amount) AS total_requested_amount,
    SUM(COALESCE(ar.approved_amount, 0)) AS total_approved_amount,

    SUM(ar.requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

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
12.8.11 Archive mode diagnostic.

This is the clearest diagnostic for whether Section 12 skipped, replaced, reset, or inserted.
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



/***************************************************************************************************
END OF SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions_archive exists.
    2. archive_inserted_ts exists.
    3. Archive table contains all latest-run columns plus archive_inserted_ts.
    4. Common latest-run / archive columns have aligned data types.
    5. Unexpected archive columns do not exist, except archive_inserted_ts.
    6. latest-run archive controls are populated and unambiguous.
    7. archive_run_flag = FALSE skips persistence without deleting or inserting archive rows.
    8. archive_run_flag = TRUE persists latest-run rows according to strategy_archive_reset_mode.
    9. STRATEGY_SCENARIO_ONLY replaces only the current replacement key.
    10. STRATEGY_SET_ONLY replaces the selected strategy set for the selected Module 1 scenario and
        population.
    11. ALL resets the full archive before inserting the current latest-run output.
    12. NONE inserts only when the current replacement key does not already exist.
    13. Archive row-level grain is protected by a unique index.
    14. Archive diagnostics are available for inventory and current-slice review.
    15. Section 12 does not recalculate decision outcomes, exposure, Expected Loss, or simulated
        reason codes.
    16. Section 12 does not perform matched strategy comparison.
    17. Section 12 does not perform full Module 2 QA.
    18. Campaign registry IDs remain evidence-linkage metadata handled later through evidence capture.

No matched strategy comparison queries have been created.
No full Module 2 QA framework has been created.
No executive evidence rows have been inserted.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00711 -->


---

<a id="c038-m00713"></a>

### C038-M00713

**Andrew** · 2026-05-09T17:08:31.718000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00713 -->
section 13:
<!-- END_MESSAGE C038-M00713 -->


**Attachments in export:** `Pasted text(120).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00724"></a>

### C038-M00724

**ChatGPT** · 2026-05-09T17:15:10.304499-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00724 -->
Using the uploaded Section 13 as the base, I hardened the commentary and converted Section 13 to the permanent registry-driven comparison design, while preserving the read-only archive-comparison boundary and adding the matched source-field consistency diagnostic. fileciteturn39file4 fileciteturn39file3

One assembly note: Section 13 now creates additional temporary helper tables, so during final recapture we should add these to Section 1 cleanup as well:

```sql
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;
```

```sql
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
    3. Load one governed active comparison from the persistent comparison campaign registry.
    4. Materialize tmp_m2_strategy_comparison_params as the canonical temporary comparison selector.
    5. Evaluate comparison readiness.
    6. Create a matched baseline / challenger helper table for read-only comparison diagnostics.
    7. Compare baseline and challenger strategy slices at portfolio, segment, outcome-migration,
       reason-code, simulated offer-exposure, and row-level diagnostic levels.
    8. Confirm matched source-field consistency for immutable Module 1 input fields.
    9. Avoid mutating archive history or recalculating strategy outcomes.

INPUTS:
    credit_decisioning_sim.strategy_decisions_archive
    credit_decisioning_sim.strategy_comparison_campaign_registry

TEMPORARY OUTPUTS:
    tmp_m2_strategy_comparison_params
    tmp_m2_strategy_comparison_readiness
    tmp_m2_strategy_comparison_matched_rows
    tmp_m2_strategy_comparison_source_consistency

READ-ONLY BOUNDARY:
    Section 13 does not insert archive rows.
    Section 13 does not delete archive rows.
    Section 13 does not update archive rows.
    Section 13 does not recalculate decision_outcome.
    Section 13 does not recalculate approved exposure.
    Section 13 does not recalculate approved Expected Loss.
    Section 13 does not reassign simulated reason codes.
    Section 13 does not modify strategy parameters.
    Section 13 does not modify product policy parameters.
    Section 13 does not create latest-run output.

WHY SECTION 13 USES THE COMPARISON CAMPAIGN REGISTRY:
    The latest-run table changes whenever a new strategy is executed.

    Using credit_decisioning_sim.strategy_decisions as the implicit comparison selector can silently
    select the wrong baseline or challenger after a later run.

    Section 13 therefore uses:
        credit_decisioning_sim.strategy_comparison_campaign_registry

    and loads the single active comparison into:
        tmp_m2_strategy_comparison_params

    This supports governed, repeatable, documentation-ready comparison by comparison_group_id.

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

    Comparing across different Module 1 scenarios would mix upstream population / environment
    effects with downstream Module 2 strategy effects.

WHY MODULE 1 SCENARIO METADATA AND MODULE 2 STRATEGY METADATA REMAIN SEPARATE:
    Module 1 scenario metadata describes the synthetic population and upstream risk environment.

    Module 2 strategy metadata describes the simulated decision strategy applied to that population.

    These are not interchangeable.

WHY ROW-LEVEL MATCHING USES APPLICATION_ID:
    application_id identifies the same synthetic application within the same Module 1 scenario and
    population.

    It is the correct row-level join key for matched Module 2 strategy comparison.

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
        stable outcomes

WHY REQUESTED AND APPROVED EXPECTED LOSS ARE BOTH COMPARED:
    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is approved-exposure Expected Loss after Module 2 exposure
    treatment.

    Comparing both shows how strategy changes affect requested-risk profile and simulated
    offer-exposure economics.

WHY SIMULATED OFFER EXPOSURE IS NOT OPERATIONAL EXPOSURE:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows in the simulated strategy
    output.

    It does not imply operational account creation or real applicant treatment.

WHY REASON-CODE MIGRATION SUPPORTS EXPLAINABILITY:
    Numeric deltas explain how much strategy behavior changed.

    Reason-code movement explains why strategy behavior changed.

WHY MATCHED SOURCE-FIELD CONSISTENCY IS VALIDATED:
    A matched strategy comparison should isolate Module 2 strategy effects.

    If immutable Module 1 source fields differ between baseline and challenger rows, the comparison
    may reflect population drift, source-selection error, or upstream scenario mismatch rather than
    true downstream strategy movement.

SECTION 13 IS NOT THE FULL QA FRAMEWORK:
    Section 13 compares archived strategy slices.

    Section 14 validates the completed latest-run output.

    Section 16 later persists executive evidence and validation evidence.

COMMON MISUSE TO AVOID:
    Do not interpret Section 13 deltas as production outcome movement.
    Do not compare different Module 1 scenarios and call the result a pure Module 2 strategy delta.
    Do not use timestamps as comparison keys.
    Do not treat reason-code movement as external communication text.
    Do not treat simulated offer exposure as operational exposure.

***************************************************************************************************/



/***************************************************************************************************
SECTION 13.0 — GOVERNED COMPARISON PARAMETER SETUP
****************************************************************************************************

PURPOSE:
    Load the selected active baseline / challenger comparison from the persistent comparison campaign
    registry into the canonical temporary comparison parameter table.

BUSINESS PURPOSE:
    Make strategy comparison governed by explicit comparison_group_id and campaign registry metadata
    instead of implicit latest-run inference.

SQL PURPOSE:
    1. Confirm the persistent comparison campaign registry exists.
    2. Confirm exactly one active comparison row is selected.
    3. Reject placeholder or same-strategy comparison setup.
    4. Materialize tmp_m2_strategy_comparison_params.
    5. Preserve comparison IDs and documentation metadata for downstream diagnostics.

REGISTRY SOURCE:
    credit_decisioning_sim.strategy_comparison_campaign_registry

CANONICAL TEMPORARY SELECTOR:
    tmp_m2_strategy_comparison_params

READ-ONLY BOUNDARY:
    This section creates temporary helper objects only.

    It does not insert, delete, update, or modify archive rows.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;


/*-----------------------------------------------------------------------------------------------
13.0A Persistent comparison registry existence and active-selection gatekeeper.
-----------------------------------------------------------------------------------------------*/

DO $$
DECLARE
    v_registry_exists BOOLEAN;
    v_active_comparison_count BIGINT;
    v_placeholder_count BIGINT;
    v_same_strategy_count BIGINT;
BEGIN
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_comparison_campaign_registry') IS NOT NULL
    INTO v_registry_exists;

    IF v_registry_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: strategy_comparison_campaign_registry does not exist. Run Section 2 registry setup before Section 13.';
    END IF;

    SELECT COUNT(*)
    INTO v_active_comparison_count
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE active_comparison_flag IS TRUE
      AND registry_active_flag IS TRUE;

    IF v_active_comparison_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: expected exactly one active comparison registry row, found %.',
            v_active_comparison_count;
    END IF;

    SELECT COUNT(*)
    INTO v_placeholder_count
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE active_comparison_flag IS TRUE
      AND registry_active_flag IS TRUE
      AND (
             baseline_strategy_name ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_name ILIKE '%PLACEHOLDER%'
          OR baseline_strategy_set_name ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_set_name ILIKE '%PLACEHOLDER%'
          OR comparison_set_name ILIKE '%PLACEHOLDER%'
          OR comparison_group_id ILIKE '%PLACEHOLDER%'
      );

    IF v_placeholder_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: active comparison registry row contains placeholder strategy identifiers.';
    END IF;

    SELECT COUNT(*)
    INTO v_same_strategy_count
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE active_comparison_flag IS TRUE
      AND registry_active_flag IS TRUE
      AND baseline_strategy_set_name = challenger_strategy_set_name
      AND baseline_strategy_name = challenger_strategy_name
      AND baseline_strategy_version = challenger_strategy_version;

    IF v_same_strategy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: active comparison selects the same strategy as both baseline and challenger.';
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
13.0B Canonical active comparison parameter table.

Sections 13.1+ consume this table.

Keeping this table name stable protects downstream Section 13, Section 14, and Section 16 references.
-----------------------------------------------------------------------------------------------*/

CREATE TEMP TABLE tmp_m2_strategy_comparison_params
ON COMMIT PRESERVE ROWS
AS
SELECT
    comparison_group_id,
    comparison_set_name,

    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    expected_comparison_storyline,
    primary_metric_focus,

    active_comparison_flag,
    registry_active_flag,
    registry_created_ts,
    registry_updated_ts
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE active_comparison_flag IS TRUE
  AND registry_active_flag IS TRUE;


/*-----------------------------------------------------------------------------------------------
13.0C Diagnostic display of selected active comparison.

Expected:
    exactly one row.
-----------------------------------------------------------------------------------------------*/
SELECT
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    expected_comparison_storyline,
    primary_metric_focus
FROM tmp_m2_strategy_comparison_params;



/***************************************************************************************************
SECTION 13.1 — ARCHIVE INVENTORY
****************************************************************************************************

PURPOSE:
    Show what archived Module 2 strategy runs are available.

BUSINESS PURPOSE:
    Give reviewers a complete archive inventory before interpreting selected baseline / challenger
    comparison outputs.

INTERPRETATION:
    This is the first query users should review before changing active comparison registry settings.

WHY ARCHIVE INVENTORY IS READ-ONLY:
    Inventory should help users understand what exists in the archive.

    It should not change archive contents, recalculate strategy outcomes, or alter prior run history.

WHY TIMESTAMP FIELDS ARE INCLUDED BUT NOT USED AS COMPARISON KEYS:
    latest_output_created_ts and archive_inserted_ts support audit traceability.

    They should not be used as deterministic comparison keys because they can vary across reruns even
    when the business strategy output is otherwise reproducible.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.1A Archive slice inventory.
-----------------------------------------------------------------------------------------------*/
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


/*-----------------------------------------------------------------------------------------------
13.1B Archived decision-outcome inventory.
-----------------------------------------------------------------------------------------------*/
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


/*-----------------------------------------------------------------------------------------------
13.1C Archive grain duplicate diagnostic.

Expected:
    zero rows.

The archive is expected to be unique at:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id
-----------------------------------------------------------------------------------------------*/
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

BUSINESS PURPOSE:
    Prevent users from interpreting missing archive slices, duplicate archive grain, row-count
    mismatch, or unmatched application sets as valid strategy movement.

TEMPORARY OUTPUT:
    tmp_m2_strategy_comparison_readiness

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

    It does not block archive inventory review.
    It does not mutate archive rows.
    It does not recalculate any strategy output.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;

CREATE TEMP TABLE tmp_m2_strategy_comparison_readiness
ON COMMIT PRESERVE ROWS
AS
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
)

SELECT
    p.comparison_group_id,
    p.comparison_set_name,
    p.showcase_id,
    p.showcase_name,

    p.baseline_module2_run_id,
    p.challenger_module2_run_id,

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
    END AS readiness_status,

    p.expected_comparison_storyline,
    p.primary_metric_focus

FROM p
CROSS JOIN baseline_counts bc
CROSS JOIN challenger_counts cc
CROSS JOIN application_match am;


/*-----------------------------------------------------------------------------------------------
13.2A Selected comparison readiness output.
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
FROM tmp_m2_strategy_comparison_readiness;



/***************************************************************************************************
SECTION 13.2B — MATCHED BASELINE / CHALLENGER HELPER TABLE
****************************************************************************************************

PURPOSE:
    Create a temporary matched comparison helper table for downstream read-only diagnostics.

BUSINESS PURPOSE:
    Avoid repeating a long baseline / challenger row-level join in every Section 13 query.

BOUNDARY:
    This table is temporary only.
    It is derived from archive rows.
    It does not mutate archive rows.
    It does not recalculate strategy outputs.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;

CREATE TEMP TABLE tmp_m2_strategy_comparison_matched_rows
ON COMMIT PRESERVE ROWS
AS
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
        p.comparison_group_id,
        p.comparison_set_name,
        p.showcase_id,
        p.showcase_name,
        p.baseline_module2_run_id,
        p.challenger_module2_run_id,

        b.application_id,

        b.module1_scenario_set_name AS baseline_module1_scenario_set_name,
        c.module1_scenario_set_name AS challenger_module1_scenario_set_name,

        b.module1_scenario_name AS baseline_module1_scenario_name,
        c.module1_scenario_name AS challenger_module1_scenario_name,

        b.population_id AS baseline_population_id,
        c.population_id AS challenger_population_id,

        b.strategy_set_name AS baseline_strategy_set_name,
        b.strategy_name AS baseline_strategy_name,
        b.strategy_version AS baseline_strategy_version,

        c.strategy_set_name AS challenger_strategy_set_name,
        c.strategy_name AS challenger_strategy_name,
        c.strategy_version AS challenger_strategy_version,

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

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        CASE
            WHEN b.decision_outcome = c.decision_outcome
                THEN 'STABLE_OUTCOME'

            WHEN b.decision_outcome IN ('APPROVE', 'COUNTEROFFER')
             AND c.decision_outcome IN ('MANUAL_REVIEW', 'DECLINE')
                THEN 'OFFER_TO_NO_OFFER_OR_REVIEW'

            WHEN b.decision_outcome IN ('MANUAL_REVIEW', 'DECLINE')
             AND c.decision_outcome IN ('APPROVE', 'COUNTEROFFER')
                THEN 'NO_OFFER_OR_REVIEW_TO_OFFER'

            WHEN b.decision_outcome = 'APPROVE'
             AND c.decision_outcome = 'COUNTEROFFER'
                THEN 'APPROVE_TO_COUNTEROFFER'

            WHEN b.decision_outcome = 'COUNTEROFFER'
             AND c.decision_outcome = 'APPROVE'
                THEN 'COUNTEROFFER_TO_APPROVE'

            ELSE 'OTHER_OUTCOME_MOVEMENT'
        END AS decision_migration_type,

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
        COALESCE(c.approved_amount, 0) - COALESCE(b.approved_amount, 0) AS delta_approved_amount,

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
            AS delta_exposure_reduction_pct

    FROM baseline_slice b
    JOIN challenger_slice c
        ON c.application_id = b.application_id
    CROSS JOIN p
)
SELECT *
FROM matched;



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

METRIC CONVENTIONS:
    All-application approved exposure metrics use COALESCE because they describe total simulated
    exposure impact across the full application population.

    Offer-row metrics use FILTER where simulated_offer_exposure_flag = TRUE.

    Manual-review rows remain unresolved by design.

****************************************************************************************************/

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

SAFE DENOMINATOR RULE:
    All rates use NULLIF denominators.

TIMESTAMP BOUNDARY:
    strategy_run_ts, latest_output_created_ts, and archive_inserted_ts are audit metadata.

    They are intentionally excluded from deterministic strategy-delta metrics.

****************************************************************************************************/

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

        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

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
    p.comparison_group_id,
    p.comparison_set_name,
    p.primary_metric_focus,

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

    b.total_requested_expected_loss_amount AS baseline_total_requested_expected_loss_amount,
    c.total_requested_expected_loss_amount AS challenger_total_requested_expected_loss_amount,
    c.total_requested_expected_loss_amount - b.total_requested_expected_loss_amount
        AS delta_total_requested_expected_loss_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    c.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    c.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.avg_approved_expected_loss_all_apps AS baseline_avg_approved_expected_loss_all_apps,
    c.avg_approved_expected_loss_all_apps AS challenger_avg_approved_expected_loss_all_apps,
    c.avg_approved_expected_loss_all_apps - b.avg_approved_expected_loss_all_apps
        AS delta_avg_approved_expected_loss_all_apps,

    b.avg_approved_expected_loss_offer_rows AS baseline_avg_approved_expected_loss_offer_rows,
    c.avg_approved_expected_loss_offer_rows AS challenger_avg_approved_expected_loss_offer_rows,
    c.avg_approved_expected_loss_offer_rows - b.avg_approved_expected_loss_offer_rows
        AS delta_avg_approved_expected_loss_offer_rows,

    b.avg_approved_pti_offer_rows AS baseline_avg_approved_pti_offer_rows,
    c.avg_approved_pti_offer_rows AS challenger_avg_approved_pti_offer_rows,
    c.avg_approved_pti_offer_rows - b.avg_approved_pti_offer_rows
        AS delta_avg_approved_pti_offer_rows,

    b.avg_synthetic_estimated_pd_proxy_all_apps AS baseline_avg_synthetic_estimated_pd_proxy_all_apps,
    c.avg_synthetic_estimated_pd_proxy_all_apps AS challenger_avg_synthetic_estimated_pd_proxy_all_apps,
    c.avg_synthetic_estimated_pd_proxy_all_apps - b.avg_synthetic_estimated_pd_proxy_all_apps
        AS delta_avg_synthetic_estimated_pd_proxy_all_apps,

    b.avg_synthetic_estimated_pd_proxy_offer_rows AS baseline_avg_synthetic_estimated_pd_proxy_offer_rows,
    c.avg_synthetic_estimated_pd_proxy_offer_rows AS challenger_avg_synthetic_estimated_pd_proxy_offer_rows,
    c.avg_synthetic_estimated_pd_proxy_offer_rows - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_avg_synthetic_estimated_pd_proxy_offer_rows

FROM p
LEFT JOIN portfolio_summary b
    ON b.comparison_role = 'BASELINE'
LEFT JOIN portfolio_summary c
    ON c.comparison_role = 'CHALLENGER';



/***************************************************************************************************
SECTION 13.5 — DECISION OUTCOME MIGRATION MATRIX
****************************************************************************************************

PURPOSE:
    Show how final simulated outcomes move from baseline to challenger for matched applications.

BUSINESS INTERPRETATION:
    This query answers:

        "Where did strategy movement occur?"

****************************************************************************************************/

SELECT
    comparison_group_id,
    comparison_set_name,

    baseline_decision_outcome,
    challenger_decision_outcome,
    decision_migration_type,

    COUNT(*) AS matched_row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population,

    SUM(delta_approved_amount) AS delta_total_approved_amount,
    AVG(delta_approved_amount) AS avg_delta_approved_amount,

    SUM(delta_approved_expected_loss_amount) AS delta_total_approved_expected_loss_amount,
    AVG(delta_approved_expected_loss_amount) AS avg_delta_approved_expected_loss_amount,

    AVG(delta_approved_payment_to_income_ratio) AS avg_delta_approved_payment_to_income_ratio

FROM tmp_m2_strategy_comparison_matched_rows
GROUP BY
    comparison_group_id,
    comparison_set_name,
    baseline_decision_outcome,
    challenger_decision_outcome,
    decision_migration_type
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
    END,
    decision_migration_type;



/***************************************************************************************************
SECTION 13.6 — MATCHED APPLICANT-LEVEL DELTA SAMPLE
****************************************************************************************************

PURPOSE:
    Provide a row-level sample of the largest matched strategy movements.

BUSINESS PURPOSE:
    Help reviewers inspect concrete examples of strategy movement rather than relying only on
    aggregate summaries.

INTERPRETATION:
    This is a diagnostic sample.

    It should not be interpreted as a production review queue or applicant treatment list.

****************************************************************************************************/

SELECT
    comparison_group_id,
    comparison_set_name,
    application_id,

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
FROM tmp_m2_strategy_comparison_matched_rows
ORDER BY
    ABS(delta_approved_expected_loss_amount) DESC,
    ABS(delta_approved_amount) DESC,
    application_id
LIMIT 50;



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

METRIC CONVENTIONS:
    Rates use safe NULLIF denominators.

    Approved exposure metrics are all-application metrics using COALESCE because these segment
    summaries measure total simulated exposure impact.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.7A Product-level matched strategy delta summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    baseline_product_type_policy_key AS product_type_policy_key,

    COUNT(*) AS matched_applications,

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

    SUM(COALESCE(baseline_approved_amount, 0)) AS baseline_total_approved_amount,
    SUM(COALESCE(challenger_approved_amount, 0)) AS challenger_total_approved_amount,
    SUM(delta_approved_amount) AS delta_total_approved_amount,

    SUM(COALESCE(baseline_approved_expected_loss_amount, 0))
        AS baseline_total_approved_expected_loss_amount,

    SUM(COALESCE(challenger_approved_expected_loss_amount, 0))
        AS challenger_total_approved_expected_loss_amount,

    SUM(delta_approved_expected_loss_amount)
        AS delta_total_approved_expected_loss_amount

FROM tmp_m2_strategy_comparison_matched_rows
GROUP BY baseline_product_type_policy_key
ORDER BY
    ABS(SUM(delta_approved_expected_loss_amount)) DESC,
    baseline_product_type_policy_key;


/*-----------------------------------------------------------------------------------------------
13.7B Score-band matched strategy delta summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    baseline_score_band_policy_key AS score_band_policy_key,

    COUNT(*) AS matched_applications,

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

    SUM(delta_approved_amount) AS delta_total_approved_amount,
    SUM(delta_approved_expected_loss_amount) AS delta_total_approved_expected_loss_amount

FROM tmp_m2_strategy_comparison_matched_rows
GROUP BY baseline_score_band_policy_key
ORDER BY
    CASE baseline_score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
13.7C Product × score matched strategy delta summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    baseline_product_type_policy_key AS product_type_policy_key,
    baseline_score_band_policy_key AS score_band_policy_key,

    COUNT(*) AS matched_applications,

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

    SUM(delta_approved_amount) AS delta_total_approved_amount,
    SUM(delta_approved_expected_loss_amount) AS delta_total_approved_expected_loss_amount,

    AVG(baseline_estimated_pd) AS avg_synthetic_estimated_pd_proxy

FROM tmp_m2_strategy_comparison_matched_rows
GROUP BY
    baseline_product_type_policy_key,
    baseline_score_band_policy_key
ORDER BY
    ABS(SUM(delta_approved_expected_loss_amount)) DESC,
    baseline_product_type_policy_key,
    CASE baseline_score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;



/***************************************************************************************************
SECTION 13.8 — REASON-CODE MOVEMENT COMPARISON
****************************************************************************************************

PURPOSE:
    Compare simulated primary reason-code distributions and reason-code transitions.

BUSINESS PURPOSE:
    Numeric deltas show how much the strategy changed.

    Reason-code movement helps explain why the strategy changed.

BOUNDARY:
    Reason codes are simulated strategy explanation codes.

    They are not external communication text.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.8A Primary reason-code distribution delta.
-----------------------------------------------------------------------------------------------*/
WITH baseline_reasons AS (
    SELECT
        baseline_primary_reason_family AS primary_reason_family,
        baseline_primary_reason_code AS primary_reason_code,
        COUNT(*) AS baseline_row_count
    FROM tmp_m2_strategy_comparison_matched_rows
    GROUP BY
        baseline_primary_reason_family,
        baseline_primary_reason_code
),

challenger_reasons AS (
    SELECT
        challenger_primary_reason_family AS primary_reason_family,
        challenger_primary_reason_code AS primary_reason_code,
        COUNT(*) AS challenger_row_count
    FROM tmp_m2_strategy_comparison_matched_rows
    GROUP BY
        challenger_primary_reason_family,
        challenger_primary_reason_code
),

denominator AS (
    SELECT COUNT(*) AS matched_application_count
    FROM tmp_m2_strategy_comparison_matched_rows
)

SELECT
    COALESCE(b.primary_reason_family, c.primary_reason_family) AS primary_reason_family,
    COALESCE(b.primary_reason_code, c.primary_reason_code) AS primary_reason_code,

    COALESCE(b.baseline_row_count, 0) AS baseline_row_count,
    COALESCE(c.challenger_row_count, 0) AS challenger_row_count,

    COALESCE(c.challenger_row_count, 0) - COALESCE(b.baseline_row_count, 0)
        AS delta_row_count,

    COALESCE(b.baseline_row_count, 0)::NUMERIC
        / NULLIF(d.matched_application_count, 0) AS baseline_population_share,

    COALESCE(c.challenger_row_count, 0)::NUMERIC
        / NULLIF(d.matched_application_count, 0) AS challenger_population_share,

    (
        COALESCE(c.challenger_row_count, 0)::NUMERIC
        / NULLIF(d.matched_application_count, 0)
    )
    -
    (
        COALESCE(b.baseline_row_count, 0)::NUMERIC
        / NULLIF(d.matched_application_count, 0)
    ) AS delta_population_share

FROM baseline_reasons b
FULL OUTER JOIN challenger_reasons c
    ON c.primary_reason_family = b.primary_reason_family
   AND c.primary_reason_code = b.primary_reason_code
CROSS JOIN denominator d
ORDER BY
    ABS(
        COALESCE(c.challenger_row_count, 0)
        - COALESCE(b.baseline_row_count, 0)
    ) DESC,
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
13.8B Primary reason-code transition matrix.
-----------------------------------------------------------------------------------------------*/
SELECT
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code,

    COUNT(*) AS matched_row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population,

    SUM(delta_approved_amount) AS delta_total_approved_amount,
    SUM(delta_approved_expected_loss_amount) AS delta_total_approved_expected_loss_amount

FROM tmp_m2_strategy_comparison_matched_rows
GROUP BY
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code
ORDER BY
    matched_row_count DESC,
    baseline_primary_reason_family,
    baseline_primary_reason_code,
    challenger_primary_reason_family,
    challenger_primary_reason_code;



/***************************************************************************************************
SECTION 13.9 — SIMULATED OFFER-EXPOSURE AND ECONOMIC TRANSITION SUMMARY
****************************************************************************************************

PURPOSE:
    Summarize how simulated positive offer exposure, approved amount, approved PTI, and approved
    Expected Loss change across matched rows.

BUSINESS INTERPRETATION:
    This query connects decision migration to exposure economics.

****************************************************************************************************/

SELECT
    baseline_simulated_offer_exposure_flag,
    challenger_simulated_offer_exposure_flag,
    decision_migration_type,

    COUNT(*) AS matched_row_count,

    ROUND(
        100.0 * COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population,

    SUM(COALESCE(baseline_approved_amount, 0)) AS baseline_total_approved_amount,
    SUM(COALESCE(challenger_approved_amount, 0)) AS challenger_total_approved_amount,
    SUM(delta_approved_amount) AS delta_total_approved_amount,

    SUM(COALESCE(baseline_approved_expected_loss_amount, 0))
        AS baseline_total_approved_expected_loss_amount,

    SUM(COALESCE(challenger_approved_expected_loss_amount, 0))
        AS challenger_total_approved_expected_loss_amount,

    SUM(delta_approved_expected_loss_amount)
        AS delta_total_approved_expected_loss_amount,

    AVG(delta_approved_payment_to_income_ratio)
        AS avg_delta_approved_payment_to_income_ratio,

    AVG(delta_exposure_reduction_pct)
        AS avg_delta_exposure_reduction_pct

FROM tmp_m2_strategy_comparison_matched_rows
GROUP BY
    baseline_simulated_offer_exposure_flag,
    challenger_simulated_offer_exposure_flag,
    decision_migration_type
ORDER BY
    baseline_simulated_offer_exposure_flag,
    challenger_simulated_offer_exposure_flag,
    decision_migration_type;



/***************************************************************************************************
SECTION 13.10 — MATCHED SOURCE-FIELD CONSISTENCY DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    Confirm that matched baseline and challenger strategy slices share the same immutable Module 1
    source fields.

BUSINESS PURPOSE:
    Matched strategy comparison should isolate Module 2 strategy effects.

    If Module 1 source fields differ between baseline and challenger rows, the comparison may reflect
    population drift, source-selection error, or upstream scenario mismatch rather than downstream
    strategy movement.

TEMPORARY OUTPUT:
    tmp_m2_strategy_comparison_source_consistency

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
    Uses IS DISTINCT FROM so NULL behavior is explicit and safe.

STATUS VALUES:
    SOURCE_FIELDS_MATCH
    SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED
    NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON

BOUNDARY:
    This diagnostic is read-only.

    It does not mutate archive rows.
    It does not recalculate any decisions.
    It does not recalculate simulated reason codes.
    It does not recalculate approved exposure.
    It does not recalculate requested or approved Expected Loss.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;

CREATE TEMP TABLE tmp_m2_strategy_comparison_source_consistency
ON COMMIT PRESERVE ROWS
AS
WITH readiness AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_readiness
    LIMIT 1
),

matched AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_matched_rows
),

field_flags AS (
    SELECT
        m.*,

        (
            baseline_product_type_policy_key
                IS DISTINCT FROM challenger_product_type_policy_key
        ) AS product_type_mismatch_flag,

        (
            baseline_score_band_policy_key
                IS DISTINCT FROM challenger_score_band_policy_key
        ) AS score_band_mismatch_flag,

        (
            baseline_credit_score
                IS DISTINCT FROM challenger_credit_score
        ) AS credit_score_mismatch_flag,

        (
            baseline_annual_income
                IS DISTINCT FROM challenger_annual_income
        ) AS annual_income_mismatch_flag,

        (
            baseline_requested_amount
                IS DISTINCT FROM challenger_requested_amount
        ) AS requested_amount_mismatch_flag,

        (
            baseline_requested_monthly_payment_proxy
                IS DISTINCT FROM challenger_requested_monthly_payment_proxy
        ) AS requested_payment_mismatch_flag,

        (
            baseline_requested_payment_to_income_ratio
                IS DISTINCT FROM challenger_requested_payment_to_income_ratio
        ) AS requested_pti_mismatch_flag,

        (
            baseline_amount_to_income_ratio
                IS DISTINCT FROM challenger_amount_to_income_ratio
        ) AS amount_to_income_mismatch_flag,

        (
            baseline_estimated_pd
                IS DISTINCT FROM challenger_estimated_pd
        ) AS estimated_pd_mismatch_flag,

        (
            baseline_estimated_lgd
                IS DISTINCT FROM challenger_estimated_lgd
        ) AS estimated_lgd_mismatch_flag,

        (
            baseline_requested_expected_loss_amount
                IS DISTINCT FROM challenger_requested_expected_loss_amount
        ) AS requested_expected_loss_mismatch_flag,

        (
            baseline_module1_scenario_set_name
                IS DISTINCT FROM challenger_module1_scenario_set_name
            OR baseline_module1_scenario_name
                IS DISTINCT FROM challenger_module1_scenario_name
            OR baseline_population_id
                IS DISTINCT FROM challenger_population_id
        ) AS module1_lineage_mismatch_flag

    FROM matched m
),

summary AS (
    SELECT
        COUNT(*) AS matched_application_count,

        COUNT(*) FILTER (
            WHERE product_type_mismatch_flag
               OR score_band_mismatch_flag
               OR credit_score_mismatch_flag
               OR annual_income_mismatch_flag
               OR requested_amount_mismatch_flag
               OR requested_payment_mismatch_flag
               OR requested_pti_mismatch_flag
               OR amount_to_income_mismatch_flag
               OR estimated_pd_mismatch_flag
               OR estimated_lgd_mismatch_flag
               OR requested_expected_loss_mismatch_flag
               OR module1_lineage_mismatch_flag
        ) AS source_field_mismatch_count,

        COUNT(*) FILTER (WHERE product_type_mismatch_flag)
            AS product_type_mismatch_count,

        COUNT(*) FILTER (WHERE score_band_mismatch_flag)
            AS score_band_mismatch_count,

        COUNT(*) FILTER (WHERE credit_score_mismatch_flag)
            AS credit_score_mismatch_count,

        COUNT(*) FILTER (WHERE annual_income_mismatch_flag)
            AS annual_income_mismatch_count,

        COUNT(*) FILTER (WHERE requested_amount_mismatch_flag)
            AS requested_amount_mismatch_count,

        COUNT(*) FILTER (WHERE requested_payment_mismatch_flag)
            AS requested_payment_mismatch_count,

        COUNT(*) FILTER (WHERE requested_pti_mismatch_flag)
            AS requested_pti_mismatch_count,

        COUNT(*) FILTER (WHERE amount_to_income_mismatch_flag)
            AS amount_to_income_mismatch_count,

        COUNT(*) FILTER (WHERE estimated_pd_mismatch_flag)
            AS estimated_pd_mismatch_count,

        COUNT(*) FILTER (WHERE estimated_lgd_mismatch_flag)
            AS estimated_lgd_mismatch_count,

        COUNT(*) FILTER (WHERE requested_expected_loss_mismatch_flag)
            AS requested_expected_loss_mismatch_count,

        COUNT(*) FILTER (WHERE module1_lineage_mismatch_flag)
            AS module1_lineage_mismatch_count

    FROM field_flags
)

SELECT
    r.comparison_group_id,
    r.comparison_set_name,

    r.baseline_module2_run_id,
    r.challenger_module2_run_id,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    r.readiness_status,

    s.matched_application_count,
    s.source_field_mismatch_count,

    s.product_type_mismatch_count,
    s.score_band_mismatch_count,
    s.credit_score_mismatch_count,
    s.annual_income_mismatch_count,
    s.requested_amount_mismatch_count,
    s.requested_payment_mismatch_count,
    s.requested_pti_mismatch_count,
    s.amount_to_income_mismatch_count,
    s.estimated_pd_mismatch_count,
    s.estimated_lgd_mismatch_count,
    s.requested_expected_loss_mismatch_count,
    s.module1_lineage_mismatch_count,

    CASE
        WHEN r.readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN s.source_field_mismatch_count = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status

FROM readiness r
CROSS JOIN summary s;


/*-----------------------------------------------------------------------------------------------
13.10A Matched source-field consistency output.
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
FROM tmp_m2_strategy_comparison_source_consistency;



/***************************************************************************************************
END OF SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK

If execution reaches this point:
    1. tmp_m2_strategy_comparison_params exists.
    2. tmp_m2_strategy_comparison_readiness exists.
    3. tmp_m2_strategy_comparison_matched_rows exists.
    4. tmp_m2_strategy_comparison_source_consistency exists.
    5. Active comparison selection is sourced from the persistent comparison campaign registry.
    6. Archive inventory is available.
    7. Archived decision-outcome inventory is available.
    8. Archive grain duplicate diagnostics are available.
    9. Selected comparison readiness diagnostics are available.
    10. Portfolio-level baseline and challenger summaries are available.
    11. Portfolio-level baseline / challenger delta summaries are available.
    12. Decision outcome migration matrix is available.
    13. Matched applicant-level delta sample is available.
    14. Product-level, score-band, and product × score strategy movement diagnostics are available.
    15. Reason-code movement diagnostics are available.
    16. Simulated offer-exposure and economic transition diagnostics are available.
    17. Matched source-field consistency diagnostics are available.
    18. Section 13 remains read-only against latest-run and archive outputs.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No latest-run rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been recalculated.
No approved exposure has been recalculated.
No requested or approved Expected Loss has been recalculated.
No full Module 2 QA framework has been created.
No executive evidence rows have been inserted.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

Recommended next patch chunk: **Section 14 — Validation, QA, and Strategy Outcome Diagnostics**, with the final `tmp_m2_validation_status_summary` integrated near the end.
<!-- END_MESSAGE C038-M00724 -->


---

<a id="c038-m00725"></a>

### C038-M00725

**Andrew** · 2026-05-09T17:18:18.547000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00725 -->
go ahead and provide updated section 1 with those additional temp tables:
<!-- END_MESSAGE C038-M00725 -->


**Attachments in export:** `Pasted text(121).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00727"></a>

### C038-M00727

**ChatGPT** · 2026-05-09T17:19:58.104509-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00727 -->
Updated Section 1 below. I added the three Section 13 temporary comparison helpers to the Section 1.4 cleanup block: `tmp_m2_strategy_comparison_readiness`, `tmp_m2_strategy_comparison_matched_rows`, and `tmp_m2_strategy_comparison_source_consistency`. This preserves the existing Section 1 clean-rerun design while ensuring the newer registry-driven comparison artifacts are reset on full rerun. fileciteturn38file0

```sql
/***************************************************************************************************
SECTION 1 — SCHEMA SETUP / CLEAN RERUN RESET
****************************************************************************************************

BUSINESS PURPOSE:
    Establish the dedicated simulation schema and reset transient Module 2 execution objects so a
    full Module 2 run starts from a clean, interpretable state.

    Section 1 answers:

        "What execution artifacts should be cleared before a new full Module 2 strategy run begins,
         and what governed history should be preserved?"

SQL PURPOSE:
    1. Create or reuse the dedicated simulation schema.
    2. Set the search path for convenient object resolution.
    3. Drop temporary Module 2 parameter, staging, comparison, validation, frontier, and evidence
       helper objects from prior executions.
    4. Drop the replaceable latest-run strategy output table for clean rerun behavior.
    5. Preserve the governed archive, campaign registry, and evidence history tables.

INPUTS:
    None required.

OUTPUTS:
    credit_decisioning_sim schema exists.
    Prior temporary Module 2 execution objects are removed.
    credit_decisioning_sim.strategy_decisions is removed so the current run can rebuild it.
    credit_decisioning_sim.strategy_decisions_archive is preserved.
    Persistent evidence and campaign registry tables are preserved.

WHY THIS SECTION EXISTS:
    Module 2 is intentionally staged.

    A prior failed run, partial run, or exploratory run can leave temporary objects in the active
    session. Those temporary objects should not silently influence the next full strategy execution.

    Section 1 therefore resets transient execution artifacts before the parameter framework,
    source-selection layer, decision stages, QA layers, frontier summary, and evidence capture are
    rebuilt.

WHY THE LATEST-RUN TABLE MAY BE DROPPED:
    credit_decisioning_sim.strategy_decisions represents the current completed Module 2 strategy run
    only.

    It is not the history table.
    It is not the comparison archive.
    It is intentionally replaceable.

    Dropping and recreating the latest-run table prevents current-run QA, Section 14 validation, and
    Section 16 evidence capture from accidentally mixing the current strategy output with a prior
    latest-run strategy output.

WHY THE ARCHIVE TABLE IS NOT DROPPED HERE:
    credit_decisioning_sim.strategy_decisions_archive is the governed historical persistence layer.

    Archive behavior is controlled later in Section 12 through:
        archive_run_flag
        strategy_archive_reset_mode

    The archive should never be dropped during ordinary clean rerun setup.

WHY EVIDENCE AND REGISTRY TABLES ARE NOT DROPPED HERE:
    The campaign registry and Section 16 evidence tables support run-roadmap traceability,
    validation-summary linkage, parameter snapshots, executive story capture, and product × score
    evidence.

    They are persistent governance artifacts, not transient execution staging tables.

    Section 16 handles evidence replacement at the current run key. Section 1 should not destroy
    historical evidence or campaign registry metadata.

OPERATING GUIDANCE:
    Run Section 1 when executing the full Module 2 engine from the beginning.

    Do not run Section 1 by itself if the goal is only to refresh Section 15 frontier outputs or
    Section 16 evidence capture from an already-materialized latest-run table. Section 1 drops
    credit_decisioning_sim.strategy_decisions, so an evidence-only refresh should start after the
    latest-run output has already been materialized.

BOUNDARY:
    Section 1 does not create strategy parameters.
    Section 1 does not select Module 1 source data.
    Section 1 does not calculate strategy segments.
    Section 1 does not assign rule flags.
    Section 1 does not route decisions.
    Section 1 does not calculate approved exposure.
    Section 1 does not assign final decision_outcome.
    Section 1 does not assign simulated reason codes.
    Section 1 does not insert archive rows.
    Section 1 does not perform matched comparison.
    Section 1 does not validate strategy outcomes.

GOVERNANCE ROLE:
    This section supports reproducibility by making clean-rerun behavior explicit.

    It also protects the distinction between:
        transient execution objects,
        replaceable latest-run output,
        governed archive history,
        persistent evidence capture,
        and campaign registry metadata.

COMMON MISUSE TO AVOID:
    Do not interpret dropped temporary objects as lost evidence.
    Temporary stage tables are execution artifacts and can be regenerated.

    Do not drop the archive table for ordinary reruns.
    Use Section 12 archive controls instead.

    Do not drop evidence tables or campaign registry tables as part of ordinary strategy execution.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
1.1 Create / reuse dedicated simulation schema.

Business purpose:
    Keep Module 2 outputs, archives, registry tables, and evidence tables organized under one
    governed simulation schema.

SQL purpose:
    Ensure the schema exists before any temporary or permanent Module 2 objects are referenced.

Interpretation:
    CREATE SCHEMA IF NOT EXISTS is non-destructive. It creates the schema only if needed and reuses it
    if it already exists.
-----------------------------------------------------------------------------------------------*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;



/*-----------------------------------------------------------------------------------------------
1.2 Clean reset of temporary Module 2 parameter objects.

Business purpose:
    Prevent stale parameter cards from prior runs from influencing the current strategy run.

Why this matters:
    Module 2 is parameter-driven. If an old temporary strategy row or product-policy row remains in
    the session, the engine could appear to run successfully while using the wrong strategy
    configuration.

Boundary:
    These are temporary parameter staging objects only. Persistent campaign registry and evidence
    tables are not dropped here.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_module2_strategy_params;
DROP TABLE IF EXISTS tmp_module2_product_policy_params;



/*-----------------------------------------------------------------------------------------------
1.3 Clean reset of temporary Module 2 decision-stage objects.

Business purpose:
    Remove prior staged execution layers before rebuilding the full strategy pipeline.

Stage interpretation:
    tmp_m2_stage_1_source_applications:
        normalized Module 1 source input and lineage layer.

    tmp_m2_stage_2_strategy_segments:
        non-decisioning segmentation layer.

    tmp_m2_stage_3_rule_flags:
        deterministic rule-trigger layer.

    tmp_m2_stage_4_preliminary_decision_routing:
        preliminary route assignment layer.

    tmp_m2_stage_5_exposure_treatment:
        approved exposure and counteroffer feasibility layer.

    tmp_m2_stage_6_final_decision_resolution:
        final simulated strategy outcome layer.

    tmp_m2_stage_7_reason_code_assignment:
        simulated strategy explanation-code layer.

Why this matters:
    Each stage depends on the prior stage. Removing prior-stage artifacts prevents downstream logic
    from reading stale data if a rerun stops and restarts mid-script.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_stage_1_source_applications;
DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;
DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;
DROP TABLE IF EXISTS tmp_m2_stage_4_preliminary_decision_routing;
DROP TABLE IF EXISTS tmp_m2_stage_5_exposure_treatment;
DROP TABLE IF EXISTS tmp_m2_stage_6_final_decision_resolution;
DROP TABLE IF EXISTS tmp_m2_stage_7_reason_code_assignment;



/*-----------------------------------------------------------------------------------------------
1.4 Clean reset of temporary archive, comparison, validation, and frontier helper objects.

Business purpose:
    Remove prior diagnostic helper objects so archive diagnostics, matched comparison, validation
    status, and frontier summaries are rebuilt from the current run and current archive state.

Section 13 helper interpretation:
    tmp_m2_strategy_comparison_params:
        canonical temporary comparison selector populated from the comparison campaign registry.

    tmp_m2_strategy_comparison_readiness:
        temporary readiness summary for the active baseline / challenger comparison.

    tmp_m2_strategy_comparison_matched_rows:
        temporary matched baseline / challenger row-level helper table.

    tmp_m2_strategy_comparison_source_consistency:
        temporary source-field consistency diagnostic for matched comparison.

Boundary:
    These temporary helper objects are not the governed archive itself.
    These temporary helper objects are not persistent evidence history.

    Section 12 controls archive persistence.
    Section 13 controls read-only matched comparison.
    Section 14 materializes validation status summary.
    Section 15 materializes strategy frontier summaries.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_registry;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_matched_rows;
DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;
DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;
DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_baseline_deltas;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_efficiency;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_classification;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_segment_highlights;
DROP TABLE IF EXISTS tmp_m2_strategy_frontier_executive_summary;



/*-----------------------------------------------------------------------------------------------
1.5 Clean reset of temporary Section 16 evidence-capture helper objects.

Business purpose:
    Remove prior evidence-capture helper objects while preserving persistent evidence tables.

Why this matters:
    Section 16 uses temporary helper objects to identify the current run key and current run-story
    metadata before inserting persistent evidence rows.

    Those temporary objects should be regenerated for each full run.

Boundary:
    This reset does not drop:
        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

    Those are persistent evidence tables and should remain available across the campaign run series.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_current_run_key;
DROP TABLE IF EXISTS tmp_m2_current_run_story_params;
DROP TABLE IF EXISTS tmp_m2_campaign_registry_current_run_match;
DROP TABLE IF EXISTS tmp_m2_comparison_campaign_registry_active_match;



/*-----------------------------------------------------------------------------------------------
1.6 Clean reset of latest-run output table.

Business purpose:
    Clear the replaceable current-run output before the engine rebuilds it in Section 11.

Interpretation:
    credit_decisioning_sim.strategy_decisions is the current latest-run strategy output only.

    It is deliberately replaced each full run.

This intentionally does not drop:
    credit_decisioning_sim.strategy_decisions_archive
    credit_decisioning_sim.strategy_run_campaign_registry
    credit_decisioning_sim.strategy_comparison_campaign_registry
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

Testing relevance:
    After a full run, Section 11 should recreate credit_decisioning_sim.strategy_decisions and
    Section 14 should validate it.

    If a user wants to rerun only Section 15 / Section 16 from an existing latest-run table, this
    Section 1 latest-run reset should not be executed first.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;
```
<!-- END_MESSAGE C038-M00727 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_29.md) · [Next](Part_31.md)
