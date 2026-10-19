# Module 2 Decision Simulator Build

## Part 50

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_49.md) · [Next](Part_51.md)

<a id="c038-m00962"></a>

### C038-M00962

**ChatGPT** · 2026-05-10T00:58:38.434628-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00962 -->
I recommend replacing Section 13 with the version below. I preserved the current registry-driven comparison logic and the matched source-field diagnostic, added a clearer archive/registry preflight, and strengthened the commentary so the section teaches the run purpose, credit-risk interpretation, matched-comparison discipline, and SQL mechanics. fileciteturn104file0

```sql
/***************************************************************************************************
SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Provide read-only archive inventory and matched baseline / challenger strategy comparison
    diagnostics.

    Section 13 answers:

        "How do two archived Module 2 strategy runs differ when applied to the same Module 1 scenario
         and population?"

    Section 13 does not answer:

        "Is the latest-run output fully validated?"
        "Which strategy should be selected for production?"
        "What real applicant treatment should occur?"
        "What customer-facing reason should be communicated?"

    This section is the archive-backed comparison layer.

    Section 12 persisted completed strategy outputs into the archive.
    Section 13 inspects those archived outputs without changing them.

SQL PURPOSE:
    1. Confirm required archive and comparison-registry dependencies exist.
    2. Inspect credit_decisioning_sim.strategy_decisions_archive.
    3. Provide archive inventory and archive grain diagnostics.
    4. Load one governed active comparison from the persistent comparison campaign registry.
    5. Materialize tmp_m2_strategy_comparison_params as the canonical temporary comparison selector.
    6. Evaluate comparison readiness.
    7. Create a matched baseline / challenger helper table for read-only comparison diagnostics.
    8. Compare baseline and challenger strategy slices at:
            portfolio level,
            decision migration level,
            row-level sample level,
            product level,
            score-band level,
            product × score level,
            reason-code movement level,
            simulated offer-exposure transition level,
            approved exposure level,
            approved PTI level,
            approved Expected Loss level.
    9. Confirm matched source-field consistency for immutable Module 1 input fields.
    10. Avoid mutating archive history or recalculating strategy outcomes.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm whether the challenger strategy changed simulated offer exposure, approved amount,
        approved Expected Loss, affordability, counteroffer usage, manual review, decline rate, and
        reason-code mix in the intended direction.

    Model governance / validation reviewers:
        Confirm that baseline and challenger are compared on the same Module 1 scenario / population
        and that immutable Module 1 source fields match across the paired rows.

    SQL reviewers:
        Confirm that the comparison is read-only, registry-selected, application_id matched, and
        supported by explicit readiness and source-consistency diagnostics.

    Portfolio / executive reviewers:
        Use the portfolio-level delta, migration matrix, reason-code movement, and segment deltas to
        describe the strategy tradeoff in plain business terms.

WHEN TO RUN THIS SECTION:
    Run Section 13 after:

        Section 12 — Strategy Decision Archive Persistence Layer

    Section 13 should be run before or alongside:

        Section 14 — Module 2 Validation, QA, and Strategy Outcome Diagnostics
        Section 15 — Strategy Frontier Summary and Executive Comparison View
        Section 16 — Strategy Run Evidence Capture and Executive Story Register

    Section 13 depends on:

        credit_decisioning_sim.strategy_decisions_archive
        credit_decisioning_sim.strategy_comparison_campaign_registry

HOW TO INTERPRET THIS SECTION:
    Passing Section 13 means:
        the active comparison registry row was selected,
        comparison parameters were materialized,
        archive inventory is available,
        comparison readiness was evaluated,
        matched-row diagnostics were created,
        source-field consistency was evaluated,
        and read-only comparison outputs are available for review.

    Passing Section 13 does not mean:
        the selected comparison is ready.

    Readiness is indicated by:

        tmp_m2_strategy_comparison_readiness.readiness_status

    The key ready value is:

        READY_FOR_MATCHED_COMPARISON

    If readiness is not ready, the inventory outputs remain useful, but matched comparison outputs
    should not be interpreted as a valid baseline / challenger strategy result.

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
    Section 13 does not insert evidence rows.
    Section 13 does not draft documentation.

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
    Decision migration shows how final simulated strategy outcomes move from baseline to challenger.

    Example movements include:

        APPROVE → COUNTEROFFER
        APPROVE → MANUAL_REVIEW
        APPROVE → DECLINE
        DECLINE → APPROVE
        stable outcomes

    Decision migration is often more executive-readable than a table of deltas alone because it shows
    where simulated applicants moved in the strategy taxonomy.

WHY REQUESTED AND APPROVED EXPECTED LOSS ARE BOTH COMPARED:
    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is approved-exposure Expected Loss after Module 2 exposure
    treatment.

    Comparing both shows whether the challenger changed:
        the source-risk profile being selected,
        the final offer-exposure economics,
        or both.

WHY SIMULATED OFFER EXPOSURE IS NOT OPERATIONAL EXPOSURE:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows in the simulated strategy
    output.

    It does not imply:
        operational account creation,
        booked exposure,
        funded exposure,
        production approval,
        customer treatment,
        or real applicant treatment.

WHY REASON-CODE MIGRATION SUPPORTS EXPLAINABILITY:
    Numeric deltas explain how much strategy behavior changed.

    Reason-code movement helps explain why strategy behavior changed.

    For example, a lower simulated offer-exposure rate becomes more interpretable when paired with a
    higher share of POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY or a higher counteroffer-related
    reason-code concentration.

WHY MATCHED SOURCE-FIELD CONSISTENCY IS VALIDATED:
    A matched strategy comparison should isolate Module 2 strategy effects.

    If immutable Module 1 source fields differ between baseline and challenger rows, the comparison
    may reflect population drift, source-selection error, or upstream scenario mismatch rather than
    true downstream strategy movement.

SECTION 13 IS NOT THE FULL QA FRAMEWORK:
    Section 13 compares archived strategy slices.

    Section 14 validates the completed latest-run output.

    Section 16 later persists executive evidence and validation evidence.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    Temporary tables:
        Used to preserve the active comparison selector, readiness result, matched-row helper, and
        source-consistency summary for downstream diagnostics.

    Persistent registry:
        Used to select comparison metadata by governed comparison_group_id rather than inferring from
        the latest-run table.

    JOIN:
        Used to select baseline and challenger archive slices using strategy and Module 1 lineage keys.

    FULL OUTER JOIN:
        Used in readiness evaluation to detect baseline-only and challenger-only application_id values.

    application_id matching:
        Used to pair the same synthetic applicant across baseline and challenger strategy outputs.

    COUNT(*) FILTER:
        Used to calculate outcome counts, rate numerators, and diagnostic counts concisely.

    NULLIF:
        Used to avoid divide-by-zero in rates.

    COALESCE:
        Used in all-application exposure and Expected Loss metrics so unresolved / no-offer rows
        contribute zero to portfolio-level approved exposure and approved Expected Loss totals.

    IS DISTINCT FROM:
        Used in source-field consistency checks so NULL comparisons remain explicit and safe.

    CASE:
        Used to classify readiness status, decision migration type, and source-consistency status.

GOVERNANCE ROLE:
    Section 13 protects comparison discipline.

    It prevents strategy movement from being interpreted unless the baseline and challenger are:
        registry-selected,
        archived,
        same-scenario,
        same-population,
        row-matched,
        and source-consistent.

COMMON MISUSE TO AVOID:
    Do not interpret Section 13 deltas as production outcome movement.
    Do not compare different Module 1 scenarios and call the result a pure Module 2 strategy delta.
    Do not use timestamps as comparison keys.
    Do not treat reason-code movement as external communication text.
    Do not treat simulated offer exposure as operational exposure.
    Do not treat an empty matched output as a valid zero-change comparison; review readiness_status.
    Do not treat source-field mismatch as a strategy effect.

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
    1. Drop prior temporary Section 13 helper objects.
    2. Confirm the archive table exists.
    3. Confirm the persistent comparison campaign registry exists.
    4. Confirm required registry columns exist.
    5. Confirm exactly one active comparison row is selected.
    6. Reject placeholder or same-strategy comparison setup.
    7. Materialize tmp_m2_strategy_comparison_params.
    8. Preserve comparison IDs and documentation metadata for downstream diagnostics.

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
13.0A Persistent archive and comparison registry dependency gatekeeper.

Business purpose:
    Fail clearly if the archive or registry objects required for governed comparison are missing.

SQL mechanics:
    TO_REGCLASS checks whether persistent tables exist.
    information_schema.columns checks whether the registry contains the fields Section 13 expects.
    COUNT(*) validates active comparison cardinality and placeholder protection.

Interpretation:
    This block validates comparison setup only.

    It does not prove that the selected baseline and challenger slices are present in the archive.
    Slice availability is evaluated in Section 13.2 readiness.
-----------------------------------------------------------------------------------------------*/

DO $$
DECLARE
    v_archive_exists BOOLEAN;
    v_registry_exists BOOLEAN;
    v_required_registry_column_gap_count BIGINT;
    v_active_comparison_count BIGINT;
    v_placeholder_count BIGINT;
    v_same_strategy_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Archive dependency check.

    Section 13 can summarize an empty archive, but the archive table itself must exist.
    Section 12 creates / reuses credit_decisioning_sim.strategy_decisions_archive.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NOT NULL
    INTO v_archive_exists;

    IF v_archive_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: strategy_decisions_archive does not exist. Run Section 12 archive setup / persistence before Section 13.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Comparison registry dependency check.

    The active baseline / challenger comparison should come from the persistent comparison campaign
    registry, not from latest-run inference.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_comparison_campaign_registry') IS NOT NULL
    INTO v_registry_exists;

    IF v_registry_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: strategy_comparison_campaign_registry does not exist. Run Section 2 registry setup before Section 13.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Registry schema check.

    Business purpose:
        Section 13 needs comparison IDs, run IDs, strategy keys, Module 1 lineage, story metadata,
        and active flags.

    SQL mechanics:
        A VALUES list defines required columns.
        NOT EXISTS checks whether each required column is present in information_schema.columns.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_registry_column_gap_count
    FROM (
        VALUES
            ('comparison_group_id'),
            ('comparison_set_name'),
            ('showcase_id'),
            ('showcase_name'),
            ('baseline_module2_run_id'),
            ('challenger_module2_run_id'),
            ('baseline_strategy_set_name'),
            ('baseline_strategy_name'),
            ('baseline_strategy_version'),
            ('challenger_strategy_set_name'),
            ('challenger_strategy_name'),
            ('challenger_strategy_version'),
            ('module1_scenario_set_name'),
            ('module1_scenario_name'),
            ('population_id'),
            ('expected_comparison_storyline'),
            ('primary_metric_focus'),
            ('active_comparison_flag'),
            ('registry_active_flag'),
            ('registry_created_ts'),
            ('registry_updated_ts')
    ) AS required_columns(column_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = 'credit_decisioning_sim'
          AND c.table_name = 'strategy_comparison_campaign_registry'
          AND c.column_name = required_columns.column_name
    );

    IF v_required_registry_column_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: strategy_comparison_campaign_registry is missing required column(s).';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Active comparison cardinality.

    Expected:
        exactly one row with active_comparison_flag = TRUE and registry_active_flag = TRUE.

    Why this matters:
        Section 13 should compare one selected baseline / challenger pair at a time.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Placeholder protection.

    Business purpose:
        Prevent accidental interpretation of placeholder comparison metadata as real strategy
        comparison evidence.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Same-strategy protection.

    Business purpose:
        A baseline / challenger comparison should compare two distinct Module 2 strategy slices.

    If the same strategy identity is selected for both sides, the comparison would not represent a
    challenger test.
    -------------------------------------------------------------------------------------------*/
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

Business purpose:
    Materialize the one active comparison registry row into the temporary parameter table used by all
    downstream Section 13 queries.

Why this table name matters:
    Sections 13.1+ consume tmp_m2_strategy_comparison_params.

    Keeping the table name stable protects downstream Section 13, Section 14, and Section 16
    references.

SQL mechanics:
    CREATE TEMP TABLE ... AS SELECT stores the selected active registry row for the current session.

Boundary:
    This is a temporary selector table only.
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

Interpretation:
    This output is the comparison "control card" for Section 13.

    Confirm the baseline and challenger strategy identities before interpreting any deltas.
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
    This is the first output users should review before changing active comparison registry settings.

    It answers:

        "What completed strategy / scenario / population slices exist in the archive?"

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

SQL mechanics:
    GROUP BY summarizes the archive at the completed strategy / scenario / population slice grain.

Archive slice grain:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

Interpretation:
    archived_row_count should equal distinct_application_id_count for each slice if archive grain is
    clean.
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

Business purpose:
    Show final simulated outcome composition for every archived strategy / scenario / population
    slice.

Interpretation:
    This is a broad archive view.

    It is not the selected comparison delta; the selected comparison is evaluated later.
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

Interpretation:
    If rows appear here, archive matched comparison should not be interpreted until duplicate archive
    grain is corrected.
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

SQL TEACHING POINT:
    The readiness table is built from several CTEs:
        p:
            the active comparison parameter card.

        baseline_slice:
            archived rows matching the baseline strategy and Module 1 scenario / population.

        challenger_slice:
            archived rows matching the challenger strategy and Module 1 scenario / population.

        baseline_counts / challenger_counts:
            row count and duplicate diagnostics.

        baseline_apps / challenger_apps:
            unique application_id sets.

        application_match:
            full outer join of application_id sets to identify match completeness.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_readiness;

CREATE TEMP TABLE tmp_m2_strategy_comparison_readiness
ON COMMIT PRESERVE ROWS
AS
WITH p AS (
    /***********************************************************************************************
    Active comparison selector.

    Section 13.0 validated that exactly one row exists.
    LIMIT 1 is safe and keeps downstream CTEs simple.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

baseline_slice AS (
    /***********************************************************************************************
    Baseline archived slice.

    Match on:
        baseline strategy identity
        same Module 1 scenario set
        same Module 1 scenario name
        same population_id
    ***********************************************************************************************/
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
    /***********************************************************************************************
    Challenger archived slice.

    This uses the same Module 1 scenario / population as the baseline so the comparison isolates
    Module 2 strategy effects.
    ***********************************************************************************************/
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
    /***********************************************************************************************
    Baseline grain diagnostics.

    duplicate count = total rows - distinct application_id count.
    ***********************************************************************************************/
    SELECT
        COUNT(*) AS baseline_archived_row_count,
        COUNT(DISTINCT application_id) AS baseline_distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS baseline_duplicate_application_row_count
    FROM baseline_slice
),

challenger_counts AS (
    /***********************************************************************************************
    Challenger grain diagnostics.
    ***********************************************************************************************/
    SELECT
        COUNT(*) AS challenger_archived_row_count,
        COUNT(DISTINCT application_id) AS challenger_distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS challenger_duplicate_application_row_count
    FROM challenger_slice
),

baseline_apps AS (
    /***********************************************************************************************
    Baseline application_id set.

    DISTINCT protects the application matching step from duplicate archived rows while the duplicate
    count remains visible in readiness.
    ***********************************************************************************************/
    SELECT DISTINCT application_id
    FROM baseline_slice
),

challenger_apps AS (
    /***********************************************************************************************
    Challenger application_id set.
    ***********************************************************************************************/
    SELECT DISTINCT application_id
    FROM challenger_slice
),

application_match AS (
    /***********************************************************************************************
    Application match diagnostic.

    FULL OUTER JOIN shows:
        matched application_id values,
        baseline-only application_id values,
        challenger-only application_id values.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Readiness status.

    Order matters:
        same-strategy selection is checked first;
        missing slices are checked before row-count mismatch;
        duplicate archive grain is checked before interpreting matching;
        unmatched application_id sets are checked last.
    ***********************************************************************************************/
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

Interpretation:
    Review readiness_status before interpreting Section 13.3+.

    If readiness_status is not READY_FOR_MATCHED_COMPARISON, downstream matched comparison outputs
    may be empty or incomplete by design.
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

TEMPORARY OUTPUT:
    tmp_m2_strategy_comparison_matched_rows

GRAIN:
    One row per matched application_id for the selected baseline / challenger pair.

BOUNDARY:
    This table is temporary only.
    It is derived from archive rows.
    It does not mutate archive rows.
    It does not recalculate strategy outputs.

WHY THIS HELPER IS USEFUL:
    Matched comparison requires many repeated fields:
        baseline outcome,
        challenger outcome,
        source fields,
        reason codes,
        approved amount,
        approved PTI,
        approved Expected Loss,
        exposure reduction.

    Materializing the helper table once makes later diagnostics easier to read and less error-prone.

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
        /*******************************************************************************************
        Comparison registry metadata.

        These fields let later diagnostics tie back to the run roadmap and validation-summary
        comparison group.
        *******************************************************************************************/
        p.comparison_group_id,
        p.comparison_set_name,
        p.showcase_id,
        p.showcase_name,
        p.baseline_module2_run_id,
        p.challenger_module2_run_id,

        /*******************************************************************************************
        Row-level match key.

        application_id represents the same synthetic applicant inside the same Module 1 scenario and
        population.
        *******************************************************************************************/
        b.application_id,

        /*******************************************************************************************
        Baseline and challenger Module 1 lineage.

        These should match for pure Module 2 strategy comparison.
        Section 13.10 validates this explicitly.
        *******************************************************************************************/
        b.module1_scenario_set_name AS baseline_module1_scenario_set_name,
        c.module1_scenario_set_name AS challenger_module1_scenario_set_name,

        b.module1_scenario_name AS baseline_module1_scenario_name,
        c.module1_scenario_name AS challenger_module1_scenario_name,

        b.population_id AS baseline_population_id,
        c.population_id AS challenger_population_id,

        /*******************************************************************************************
        Baseline and challenger strategy identities.

        These should differ by intended Module 2 strategy selection.
        *******************************************************************************************/
        b.strategy_set_name AS baseline_strategy_set_name,
        b.strategy_name AS baseline_strategy_name,
        b.strategy_version AS baseline_strategy_version,

        c.strategy_set_name AS challenger_strategy_set_name,
        c.strategy_name AS challenger_strategy_name,
        c.strategy_version AS challenger_strategy_version,

        /*******************************************************************************************
        Immutable source fields.

        These should match across baseline and challenger if the comparison is isolating Module 2
        strategy effects.
        *******************************************************************************************/
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

        /*******************************************************************************************
        Final outcome fields.

        These are the key fields for decision migration.
        *******************************************************************************************/
        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        /*******************************************************************************************
        Decision migration type.

        This classification translates final outcome movement into a readable strategy movement
        label.

        It does not create or change decisions.
        *******************************************************************************************/
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

        /*******************************************************************************************
        Reason-code fields.

        Reason-code movement helps explain why numeric movement occurred.
        *******************************************************************************************/
        b.primary_reason_family AS baseline_primary_reason_family,
        c.primary_reason_family AS challenger_primary_reason_family,

        b.primary_reason_code AS baseline_primary_reason_code,
        c.primary_reason_code AS challenger_primary_reason_code,

        /*******************************************************************************************
        Simulated offer exposure.

        TRUE means final outcome is APPROVE or COUNTEROFFER.
        It does not mean booked or funded exposure.
        *******************************************************************************************/
        b.simulated_offer_exposure_flag AS baseline_simulated_offer_exposure_flag,
        c.simulated_offer_exposure_flag AS challenger_simulated_offer_exposure_flag,

        /*******************************************************************************************
        Final approved exposure and approved economics.

        COALESCE is used in deltas for approved amount and approved Expected Loss because unresolved
        and no-offer outcomes should contribute zero to total approved-exposure economics.
        *******************************************************************************************/
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



/*-----------------------------------------------------------------------------------------------
13.2C Matched helper row-count diagnostic.

Interpretation:
    matched_helper_row_count should equal matched_application_id_count from Section 13.2A when
    readiness_status is READY_FOR_MATCHED_COMPARISON.

    If readiness is not ready, this count may be zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS matched_helper_row_count,
    COUNT(DISTINCT application_id) AS matched_helper_distinct_application_id_count
FROM tmp_m2_strategy_comparison_matched_rows;



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

BOUNDARY:
    This is an archived strategy summary.

    It does not recalculate outcomes.
    It does not update the archive.

****************************************************************************************************/

WITH p AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),

selected_slices AS (
    /***********************************************************************************************
    Pull baseline and challenger rows into one CTE with a comparison_role label.

    UNION ALL is used intentionally because baseline and challenger are distinct strategy slices.
    ***********************************************************************************************/
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

SQL TEACHING POINT:
    The query summarizes baseline and challenger separately, then LEFT JOINs them back to the active
    comparison parameter row so the output still shows comparison metadata even when one side is not
    available.

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
    /***********************************************************************************************
    Portfolio-level metrics by comparison role.

    This is the foundation for baseline-versus-challenger deltas.
    ***********************************************************************************************/
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

    Examples:
        APPROVE → DECLINE indicates access tightened for those matched rows.
        DECLINE → APPROVE indicates access expanded for those matched rows.
        APPROVE → COUNTEROFFER indicates access was preserved but exposure treatment changed.
        STABLE_OUTCOME indicates no final outcome movement.

BOUNDARY:
    This is simulated strategy movement on synthetic applicants.

    It is not production account movement and not real applicant treatment.

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

SQL MECHANICS:
    ORDER BY ABS(delta_approved_expected_loss_amount), then ABS(delta_approved_amount), surfaces rows
    with the largest economic movement first.

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

WHY PRODUCT AND SCORE SEGMENTS MATTER:
    Product type affects requested exposure, payment mechanics, LGD, counteroffer feasibility, and
    approved Expected Loss.

    Score band affects borrower-quality segmentation and synthetic estimated-risk profile.

    Product × score review prevents portfolio averages from hiding concentrated strategy movement.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
13.7A Product-level matched strategy delta summary.

Interpretation:
    Shows whether challenger movement concentrated in a product family.

    Sort order emphasizes absolute approved Expected Loss movement first.
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

Interpretation:
    Shows whether strategy movement concentrates in stronger or weaker borrower-quality bands.

    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.
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

Interpretation:
    Shows concentrated strategy movement at the intersection of product type and borrower-quality
    segment.

    This is often the most useful diagnostic for explaining why a portfolio-level delta occurred.
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

    They are not:
        customer communications,
        regulatory notices,
        adverse-action reason codes,
        production compliance determinations,
        or fair-lending conclusions.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
13.8A Primary reason-code distribution delta.

Interpretation:
    Shows whether the challenger increased or decreased specific explanation-code shares.

SQL mechanics:
    FULL OUTER JOIN preserves reason codes that appear only in baseline or only in challenger.
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

Interpretation:
    Shows how individual applications moved from one simulated explanation code to another.

    This is useful when outcome movement is modest but explanation movement is meaningful.
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

    It answers:

        "Did the challenger add or remove simulated offer exposure, and what happened to approved
         amount, approved affordability, and approved Expected Loss?"

BOUNDARY:
    simulated_offer_exposure_flag indicates simulated positive offer exposure only.

    It is not booked exposure, funded exposure, or real applicant treatment.

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

WHY THIS DIAGNOSTIC MATTERS:
    A matched challenger comparison is only a clean Module 2 strategy comparison if the same
    synthetic applicant source fields are being compared.

    Source mismatch means the observed delta may reflect upstream data differences, not downstream
    strategy behavior.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_source_consistency;

CREATE TEMP TABLE tmp_m2_strategy_comparison_source_consistency
ON COMMIT PRESERVE ROWS
AS
WITH readiness AS (
    /***********************************************************************************************
    Readiness result.

    If readiness is not READY_FOR_MATCHED_COMPARISON, source consistency is marked NOT_APPLICABLE.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_strategy_comparison_readiness
    LIMIT 1
),

matched AS (
    /***********************************************************************************************
    Matched baseline / challenger rows.

    This may be empty if the comparison is not ready.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_strategy_comparison_matched_rows
),

field_flags AS (
    /***********************************************************************************************
    Row-level source-field mismatch flags.

    IS DISTINCT FROM treats NULL safely:
        NULL IS DISTINCT FROM NULL = FALSE
        NULL IS DISTINCT FROM value = TRUE
    ***********************************************************************************************/
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
    /***********************************************************************************************
    Aggregate source consistency counts.

    matched_application_count:
        number of row-level comparisons evaluated.

    source_field_mismatch_count:
        rows where at least one immutable source field differs.

    Individual mismatch counts:
        identify which source dimension caused the mismatch.
    ***********************************************************************************************/
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

Expected when comparison is ready:
    source_consistency_status = SOURCE_FIELDS_MATCH

If status is SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED:
    Do not interpret strategy deltas as pure Module 2 strategy effects until the mismatch is reviewed.

If status is NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON:
    Review Section 13.2 readiness before interpreting comparison outputs.
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



/*-----------------------------------------------------------------------------------------------
13.10B Source-field mismatch sample.

Purpose:
    Provide a small row-level sample if immutable Module 1 fields differ across matched rows.

Expected:
    zero rows when source_consistency_status = SOURCE_FIELDS_MATCH.

Interpretation:
    If rows appear, review source lineage and archive selection before using strategy deltas as pure
    Module 2 strategy movement.

Boundary:
    This sample is diagnostic only.
-----------------------------------------------------------------------------------------------*/

SELECT
    application_id,

    baseline_product_type_policy_key,
    challenger_product_type_policy_key,

    baseline_score_band_policy_key,
    challenger_score_band_policy_key,

    baseline_credit_score,
    challenger_credit_score,

    baseline_annual_income,
    challenger_annual_income,

    baseline_requested_amount,
    challenger_requested_amount,

    baseline_requested_monthly_payment_proxy,
    challenger_requested_monthly_payment_proxy,

    baseline_requested_payment_to_income_ratio,
    challenger_requested_payment_to_income_ratio,

    baseline_amount_to_income_ratio,
    challenger_amount_to_income_ratio,

    baseline_estimated_pd,
    challenger_estimated_pd,

    baseline_estimated_lgd,
    challenger_estimated_lgd,

    baseline_requested_expected_loss_amount,
    challenger_requested_expected_loss_amount,

    baseline_module1_scenario_set_name,
    challenger_module1_scenario_set_name,

    baseline_module1_scenario_name,
    challenger_module1_scenario_name,

    baseline_population_id,
    challenger_population_id
FROM tmp_m2_strategy_comparison_matched_rows
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
ORDER BY application_id
LIMIT 50;



/***************************************************************************************************
END OF SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions_archive exists.
    2. credit_decisioning_sim.strategy_comparison_campaign_registry exists.
    3. Required comparison registry columns exist.
    4. tmp_m2_strategy_comparison_params exists.
    5. tmp_m2_strategy_comparison_readiness exists.
    6. tmp_m2_strategy_comparison_matched_rows exists.
    7. tmp_m2_strategy_comparison_source_consistency exists.
    8. Active comparison selection is sourced from the persistent comparison campaign registry.
    9. Archive inventory is available.
    10. Archived decision-outcome inventory is available.
    11. Archive grain duplicate diagnostics are available.
    12. Selected comparison readiness diagnostics are available.
    13. Portfolio-level baseline and challenger summaries are available.
    14. Portfolio-level baseline / challenger delta summaries are available.
    15. Decision outcome migration matrix is available.
    16. Matched applicant-level delta sample is available.
    17. Product-level, score-band, and product × score strategy movement diagnostics are available.
    18. Reason-code movement diagnostics are available.
    19. Simulated offer-exposure and economic transition diagnostics are available.
    20. Matched source-field consistency diagnostics are available.
    21. Section 13 remains read-only against latest-run and archive outputs.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No latest-run rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been recalculated.
No approved exposure has been recalculated.
No requested or approved Expected Loss has been recalculated.
No full Module 2 QA framework has been created.
No strategy frontier summary has been created.
No executive evidence rows have been inserted.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 14 should validate the completed latest-run output and create
    tmp_m2_validation_status_summary for evidence capture.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00962 -->


---

<a id="c038-m00963"></a>

### C038-M00963

**Andrew** · 2026-05-10T01:03:52.134000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00963 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 14 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00963 -->


**Attachments in export:** `Pasted text(152).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00971"></a>

### C038-M00971

**ChatGPT** · 2026-05-10T01:07:27.609484-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00971 -->
Based on the uploaded Section 14, I would **keep Sections 14.1–14.19 as written** and add one targeted hardening block before Section 14.1: a **Section 14.0 dependency preflight**. Your current Section 14 already has strong headers, SQL-purpose framing, boundary language, validation-status construction, archive/comparison readiness recap, and matched source-field consistency integration. The one gap versus the “elite” standard from Sections 6–13 is that Section 14 starts directly with diagnostics instead of first teaching and checking the minimum object/column dependencies. fileciteturn104file0

Insert this block **after the main Section 14 header and before Section 14.1**. No other Section 14 rewrite is needed.

```sql
/***************************************************************************************************
SECTION 14.0 — SECTION 14 DEPENDENCY PREFLIGHT AND READ-ONLY QA SCOPE GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the latest-run Module 2 output and supporting archive context exist before the
    Section 14 validation framework begins.

    Section 14.0 answers:

        "Is the completed latest-run output structurally available for read-only validation review?"

SQL PURPOSE:
    1. Confirm credit_decisioning_sim.strategy_decisions exists.
    2. Confirm credit_decisioning_sim.strategy_decisions contains rows.
    3. Confirm credit_decisioning_sim.strategy_decisions_archive exists for archive-readiness
       diagnostics.
    4. Confirm the latest-run output contains the minimum column set required by Section 14 QA.
    5. Preserve Section 14 as a read-only validation layer.
    6. Fail clearly if Section 14 is run before latest-run output materialization.

WHY THIS PREFLIGHT EXISTS:
    Section 14 is intentionally read-only.

    It should not create latest-run output, repair archive state, insert evidence rows, or recalculate
    strategy results.

    However, because Section 14 references a broad set of latest-run fields across many diagnostic
    queries, it should fail with an instructional message if the latest-run table or required columns
    are missing.

WHAT THIS PREFLIGHT DOES NOT VALIDATE:
    Section 14.0 does not decide whether the strategy behavior is acceptable.

    Later Section 14 diagnostics review:
        product behavior,
        score-band behavior,
        product × score behavior,
        synthetic estimated-risk ordering,
        affordability sensitivity,
        DTI behavior,
        exposure conventions,
        Expected Loss conventions,
        counteroffer feasibility,
        manual-review behavior,
        decline / policy-stop behavior,
        reason-code alignment,
        edge-case behavior,
        archive readiness,
        comparison readiness,
        and matched source-field consistency.

WHY ARCHIVE EXISTENCE IS CHECKED HERE:
    Section 14 includes archive-readiness recap diagnostics.

    The archive table is created or reused in Section 12.

    If the archive table is absent, Section 14.18 archive-readiness queries cannot be interpreted.

    For a formal full Module 2 run, execute Section 12 before Section 14.

WHY COMPARISON HELPERS ARE NOT REQUIRED HERE:
    Section 13 comparison helpers are optional for latest-run QA.

    Section 14.18A creates temporary NOT_APPLICABLE placeholders when Section 13 comparison helper
    tables are absent.

    Therefore this preflight does not require:
        tmp_m2_strategy_comparison_readiness
        tmp_m2_strategy_comparison_source_consistency

SQL CONCEPTS TAUGHT IN THIS SECTION:
    TO_REGCLASS:
        Checks whether a table exists before the validation framework references it.

    information_schema.columns:
        Checks whether the latest-run table contains the columns Section 14 expects to validate.

    VALUES:
        Creates an inline list of required column names.

    STRING_AGG:
        Converts missing required column names into a readable exception message.

    RAISE EXCEPTION:
        Stops Section 14 when required validation targets are not available.

    RAISE NOTICE:
        Prints helpful non-failing context about the latest-run row count.

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

    These Boolean variables confirm whether the permanent latest-run and archive tables exist before
    Section 14 references them.
    ***********************************************************************************************/
    v_latest_run_table_exists BOOLEAN;
    v_archive_table_exists BOOLEAN;

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
    14.0C Confirm archive table exists for archive-readiness diagnostics.

    Business purpose:
        Section 14.18 recaps whether the current latest-run slice is aligned to archive history.

        The archive table is created or reused in Section 12.

    Boundary:
        This check does not insert archive rows.
        This check does not repair archive rows.
        This check does not validate archive persistence fidelity.

        Section 12 owns archive persistence and archive validation.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NOT NULL
    INTO v_archive_table_exists;

    IF v_archive_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 14 failure: credit_decisioning_sim.strategy_decisions_archive does not exist. Run Section 12 before Section 14 archive-readiness diagnostics.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    14.0D Confirm latest-run output contains the minimum Section 14 validation column set.

    Business purpose:
        Section 14 references many fields across structural QA, decision QA, segment QA, exposure QA,
        Expected Loss QA, reason-code QA, and edge-case review.

        A missing field should be surfaced immediately with a readable message.

    SQL mechanics:
        The VALUES clause lists required columns.

        information_schema.columns checks whether each required column exists in the latest-run
        output table.

        STRING_AGG builds a readable comma-separated missing-column list.
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
            Application, product, and borrower profile fields.
            ***************************************************************************************/
            ('application_id'),
            ('applicant_id'),
            ('product_type_policy_key'),
            ('score_band_policy_key'),
            ('product_score_policy_segment'),
            ('credit_score'),
            ('annual_income'),
            ('debt_to_income_ratio'),
            ('utilization_rate'),
            ('delinquency_count_12m'),
            ('major_derogatory_flag'),
            ('bankruptcy_flag'),

            /***************************************************************************************
            Requested-structure, synthetic risk, LGD, and requested Expected Loss fields.
            ***************************************************************************************/
            ('requested_amount'),
            ('loan_term_months'),
            ('base_apr_for_payment_calc'),
            ('requested_monthly_payment_proxy'),
            ('requested_payment_to_income_ratio'),
            ('amount_to_income_ratio'),
            ('estimated_pd'),
            ('estimated_lgd'),
            ('requested_expected_loss_amount'),

            /***************************************************************************************
            Strategy segmentation fields.
            ***************************************************************************************/
            ('strategy_risk_tier'),
            ('requested_pti_bucket'),
            ('dti_bucket'),
            ('requested_exposure_tier'),
            ('requested_expected_loss_tier'),
            ('mixed_signal_profile_type'),
            ('mixed_signal_condition_count'),
            ('borderline_profile_flag'),

            /***************************************************************************************
            Rule-trigger fields used by Section 14 diagnostics.
            ***************************************************************************************/
            ('hard_policy_stop_flag'),
            ('hard_policy_stop_count'),
            ('synthetic_risk_decline_trigger_flag'),
            ('requested_pti_decline_trigger_flag'),
            ('dti_decline_trigger_flag'),
            ('requested_el_decline_trigger_flag'),
            ('requested_exposure_extreme_flag'),
            ('counteroffer_candidate_flag'),
            ('manual_review_candidate_flag'),
            ('clean_approval_candidate_flag'),
            ('total_rule_trigger_count'),

            /***************************************************************************************
            Preliminary routing and exposure-treatment fields.
            ***************************************************************************************/
            ('preliminary_decision_outcome'),
            ('preliminary_decision_path'),
            ('preliminary_decision_priority_rank'),
            ('exposure_treatment_status'),
            ('exposure_treatment_path'),
            ('counteroffer_feasibility_pass_flag'),
            ('counteroffer_feasibility_failure_reason'),
            ('counteroffer_feasibility_constraint_count'),

            /***************************************************************************************
            Final outcome, flags, exposure, affordability, and Expected Loss fields.
            ***************************************************************************************/
            ('decision_outcome'),
            ('decision_path'),
            ('decision_priority_rank'),
            ('decision_resolution_source'),
            ('approval_flag'),
            ('counteroffer_flag'),
            ('manual_review_flag'),
            ('decline_flag'),
            ('simulated_offer_exposure_flag'),
            ('approved_amount'),
            ('counteroffer_amount'),
            ('exposure_reduction_flag'),
            ('exposure_reduction_amount'),
            ('exposure_reduction_pct'),
            ('approved_monthly_payment_proxy'),
            ('approved_payment_to_income_ratio'),
            ('approved_expected_loss_amount'),
            ('approved_el_reduction_amount'),
            ('approved_el_reduction_pct'),
            ('product_approved_el_cap'),
            ('counteroffer_target_pti'),

            /***************************************************************************************
            Simulated reason-code fields.
            ***************************************************************************************/
            ('primary_reason_code'),
            ('secondary_reason_code'),
            ('tertiary_reason_code'),
            ('primary_reason_family'),
            ('triggered_reason_code_list'),
            ('reason_priority_rank'),
            ('reason_code_count')
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
END $$;
```
<!-- END_MESSAGE C038-M00971 -->


---

<a id="c038-m00972"></a>

### C038-M00972

**Andrew** · 2026-05-10T01:11:44.128000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00972 -->
I don't see a lot of inline code commentary explaining the sql in section 14 Also module 1 commentary would have explained what to look for in each query result.  that is the type of level we are striving for.
<!-- END_MESSAGE C038-M00972 -->


---

<a id="c038-m00975"></a>

### C038-M00975

**ChatGPT** · 2026-05-10T01:13:10.877462-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00975 -->
Agreed. Section 14 is **not yet at the elite commentary / instructional level** we established.

My prior pass focused too much on **scope, boundaries, and validation coverage**, and not enough on the two things you are calling out:

1. **Inline SQL teaching** — explaining what each aggregation, `FILTER`, `CASE`, `COALESCE`, `NULLIF`, `ORDER BY`, and grouped result is doing.
2. **Result interpretation guidance** — explaining what reviewers should look for in each query output, what “good” looks like, what requires review, and how to speak to the result later.

That matters especially in Section 14 because it is not a transformation section. It is a **diagnostic evidence section**, so the commentary has to teach reviewers how to read each result grid. The current Section 14 has strong top-level scope language, but many query blocks still use short labels such as “Counteroffer summary” or “Strong credit / high requested PTI sample,” without enough embedded explanation of how to interpret the result or how the SQL is producing it. fileciteturn104file0 fileciteturn104file23

The right fix is a **query-by-query commentary hardening pass**, not just adding Section 14.0.

For Section 14, each diagnostic query should follow this pattern:

```sql
/*-----------------------------------------------------------------------------------------------
14.X Query name.

Business purpose:
    What this output helps a strategy, validation, or executive reviewer understand.

Credit risk interpretation:
    What concept the query is testing: access, affordability, risk ordering, Expected Loss, exposure
    discipline, manual-review burden, reason-code explainability, etc.

What to look for:
    The expected healthy pattern.

Review triggers:
    Patterns that are not automatically failures but require interpretation before documentation.

SQL mechanics:
    How the query works:
        GROUP BY,
        FILTER,
        COALESCE,
        NULLIF,
        CASE,
        window denominator,
        ordering logic,
        sampled rows,
        etc.

Documentation use:
    Whether this output can support the validation summary, executive story, README, or later
    Module 3 design.
-----------------------------------------------------------------------------------------------*/
```

And inside the SQL itself, we should add targeted comments like:

```sql
    /*
    Count final approvals in this diagnostic group.

    SQL mechanics:
        FILTER applies the condition only to this aggregate without removing rows from the full
        grouped population.

    Interpretation:
        This lets approval_count, counteroffer_count, manual_review_count, and decline_count be
        calculated in the same grouped result.
    */
    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
```

or:

```sql
    /*
    All-application approved amount average.

    COALESCE converts unresolved manual-review rows and no-offer rows to zero so this metric reflects
    portfolio-level approved exposure impact across the full application population.

    Use this metric for portfolio exposure impact, not for offer-row economics.
    */
    AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
```

or:

```sql
    /*
    Offer-row approved amount average.

    FILTER limits the average to simulated positive offer-exposure outcomes only.

    Use this metric to understand the approved exposure profile among rows that actually received
    simulated offer exposure.
    */
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_amount_offer_rows,
```

So the acceptance standard for Section 14 should be revised to:

**Section 14 is accepted only when every query block explains:**
- what the query is for;
- what result pattern reviewers should expect;
- what result pattern should trigger review;
- which credit risk concept is being tested;
- how the SQL logic produces the result;
- how the output can later be used in validation or executive storytelling.

I recommend we redo Section 14 in chunks, because it is too large to harden responsibly in one pass. Start with:

**Section 14 header + 14.0 + 14.1 + 14.2 + 14.3**

Then continue:

**14.4–14.6**, **14.7–14.10**, **14.11–14.13**, **14.14–14.16**, **14.17–14.19**.

For the next pass, I’ll return full copy-paste replacement blocks with the actual query commentary upgraded—not just a summary note.
<!-- END_MESSAGE C038-M00975 -->


---

<a id="c038-m00976"></a>

### C038-M00976

**Andrew** · 2026-05-10T01:16:54.996000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00976 -->
as requested, let's start with section 14 header through section 14.3.  let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 14.0-14.3 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00976 -->


**Attachments in export:** `Pasted text(153).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_49.md) · [Next](Part_51.md)
