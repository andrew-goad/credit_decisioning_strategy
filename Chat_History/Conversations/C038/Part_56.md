# Module 2 Decision Simulator Build

## Part 56

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_55.md) · [Next](Part_57.md)

<a id="c038-m01011"></a>

### C038-M01011

**ChatGPT** · 2026-05-10T10:13:36.597714-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01011 -->
According to a document from 2026-05-10, I recommend replacing **Section 15.0 through Section 15.4** with the version below. I preserved the frontier logic and strengthened the instructional commentary, inline SQL explanations, result-interpretation guidance, and review triggers. fileciteturn116file1

```sql
/***************************************************************************************************
SECTION 15.0 — FRONTIER SCOPE AND ARCHIVE READINESS SNAPSHOT
****************************************************************************************************

PURPOSE:
    Confirm that the governed Module 2 strategy archive exists and provide a quick archive-level
    readiness snapshot before creating strategy frontier outputs.

BUSINESS PURPOSE:
    Determine whether the archive contains enough completed strategy / scenario slices to support
    meaningful frontier analysis.

    Section 15.0 answers:

        "Is there enough archived strategy history to review strategy frontier tradeoffs?"

SQL PURPOSE:
    1. Confirm credit_decisioning_sim.strategy_decisions_archive exists.
    2. Count archived applicant-level rows.
    3. Count distinct archived application_id values.
    4. Count archived strategy × Module 1 scenario × population slices.
    5. Count distinct Module 1 scenario / population slices.
    6. Count distinct Module 2 strategy versions.
    7. Display archive persistence timestamp range.
    8. Assign a frontier_scope_status.

WHY THIS SECTION COMES FIRST:
    Section 15 is archive-backed.

    Unlike the latest-run table, the archive is the governed history layer that preserves completed
    strategy outputs across runs.

    Before building frontier summaries, reviewers should know whether the archive supports:
        inventory only,
        basic two-strategy comparison,
        or richer multi-strategy frontier review.

FRONTIER READINESS INTERPRETATION:
    FRONTIER_NOT_READY_ARCHIVE_EMPTY:
        No archived rows exist.

        Section 15 cannot produce meaningful frontier metrics.

    FRONTIER_INVENTORY_ONLY_SINGLE_ARCHIVED_SLICE:
        Only one archived strategy / scenario / population slice exists.

        Section 15 can summarize that one point, but it cannot yet show strategy tradeoffs.

    FRONTIER_READY_FOR_MULTI_STRATEGY_REVIEW:
        At least two Module 2 strategy versions exist in the archive.

        Section 15 can begin showing strategy frontier tradeoffs.

    FRONTIER_AVAILABLE_FOR_ARCHIVE_REVIEW:
        Archive contains rows and can be summarized, but richer frontier interpretation depends on
        the mix of scenarios and strategies available.

WHAT TO LOOK FOR:
    archived_rows:
        Should be greater than zero.

    archived_strategy_scenario_slice_count:
        Shows how many completed archived frontier points are available.

    module2_strategy_version_count:
        Two or more indicates that the archive can support strategy tradeoff review.

    module1_scenario_population_slice_count:
        More than one indicates that the archive spans multiple upstream Module 1 scenario /
        population conditions.

REVIEW TRIGGERS:
    If the archive table is missing:
        Section 12 has not created / persisted the governed archive.

    If archived_rows = 0:
        Section 12 may not have archived any completed runs.

    If archived_strategy_scenario_slice_count = 1:
        Section 15 is inventory-only for now.

    If multiple Module 1 scenarios exist:
        preserve the distinction between upstream Module 1 scenario effects and downstream Module 2
        strategy effects.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    TO_REGCLASS:
        Checks whether a table exists before referencing it.

    COUNT(*):
        Counts archived applicant-level rows.

    COUNT(DISTINCT ...):
        Counts unique archive keys and strategy identities.

    String concatenation with ||:
        Creates compact multi-column distinct keys while preserving the existing accepted logic.

    MIN / MAX:
        Summarizes archive timestamp range for traceability.

    CASE:
        Converts archive inventory counts into a readable frontier readiness status.

BOUNDARY:
    This is a read-only diagnostic.

    It does not require a baseline strategy to exist.
    It does not require campaign registry mapping.
    It does not insert archive rows.
    It does not delete archive rows.
    It does not update archive rows.
    It does not validate the latest-run output.
    It does not perform matched comparison.
    It does not calculate frontier classifications.

***************************************************************************************************/

DO $$
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check:
        Section 15 is archive-backed.

    SQL mechanics:
        TO_REGCLASS returns NULL when the named relation does not exist.

    Failure interpretation:
        If this exception is raised, Section 12 has not created or reused
        credit_decisioning_sim.strategy_decisions_archive yet.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 15 failure: credit_decisioning_sim.strategy_decisions_archive does not exist. Run Section 12 before Section 15.';
    END IF;
END $$;


SELECT
    /***********************************************************************************************
    Self-describing diagnostic label.

    This makes the output easier to copy into QA notes or executive review packets.
    ***********************************************************************************************/
    'SECTION_15_FRONTIER_SCOPE' AS diagnostic_name,

    /***********************************************************************************************
    Total archived applicant-level rows.

    Interpretation:
        This is the total row count across all archived strategy / scenario slices.

        It is not expected to equal distinct application_id count when the same population has been
        archived under multiple strategies.
    ***********************************************************************************************/
    COUNT(*) AS archived_rows,

    /***********************************************************************************************
    Distinct application_id values across the full archive.

    Interpretation:
        If the same Module 1 population is archived under multiple strategies, the same
        application_id may appear multiple times in the archive, once per strategy slice.
    ***********************************************************************************************/
    COUNT(DISTINCT application_id) AS distinct_archived_application_ids,

    /***********************************************************************************************
    Distinct archived strategy × scenario × population slices.

    SQL mechanics:
        Concatenating the six technical grain fields creates a readable multi-field distinct key.

    Frontier interpretation:
        This is the count of completed archived frontier points available to Section 15.
    ***********************************************************************************************/
    COUNT(DISTINCT
        strategy_set_name
        || '|' || strategy_name
        || '|' || strategy_version
        || '|' || module1_scenario_set_name
        || '|' || module1_scenario_name
        || '|' || population_id
    ) AS archived_strategy_scenario_slice_count,

    /***********************************************************************************************
    Distinct Module 1 scenario / population slices.

    Credit risk interpretation:
        These fields describe the upstream synthetic population and risk environment.

        Multiple values here mean the archive spans multiple Module 1 scenario conditions.
    ***********************************************************************************************/
    COUNT(DISTINCT
        module1_scenario_set_name
        || '|' || module1_scenario_name
        || '|' || population_id
    ) AS module1_scenario_population_slice_count,

    /***********************************************************************************************
    Distinct Module 2 strategy versions.

    Frontier interpretation:
        Two or more strategy identities are needed for basic multi-strategy frontier review.
    ***********************************************************************************************/
    COUNT(DISTINCT
        strategy_set_name
        || '|' || strategy_name
        || '|' || strategy_version
    ) AS module2_strategy_version_count,

    /***********************************************************************************************
    Archive persistence timestamp range.

    Boundary:
        archive_inserted_ts is audit metadata.

        It supports traceability but should not define strategy comparison grain or frontier rank.
    ***********************************************************************************************/
    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts,

    /***********************************************************************************************
    Frontier scope status.

    SQL mechanics:
        CASE evaluates conditions in order.

        The first matching condition determines the status label.

    Interpretation:
        This label tells reviewers whether Section 15 is not ready, inventory-only, or ready for
        multi-strategy review.
    ***********************************************************************************************/
    CASE
        WHEN COUNT(*) = 0
            THEN 'FRONTIER_NOT_READY_ARCHIVE_EMPTY'

        WHEN COUNT(DISTINCT
                strategy_set_name
                || '|' || strategy_name
                || '|' || strategy_version
                || '|' || module1_scenario_set_name
                || '|' || module1_scenario_name
                || '|' || population_id
             ) = 1
            THEN 'FRONTIER_INVENTORY_ONLY_SINGLE_ARCHIVED_SLICE'

        WHEN COUNT(DISTINCT
                strategy_set_name
                || '|' || strategy_name
                || '|' || strategy_version
             ) >= 2
            THEN 'FRONTIER_READY_FOR_MULTI_STRATEGY_REVIEW'

        ELSE 'FRONTIER_AVAILABLE_FOR_ARCHIVE_REVIEW'
    END AS frontier_scope_status

FROM credit_decisioning_sim.strategy_decisions_archive;



/***************************************************************************************************
SECTION 15.0A — OPTIONAL CAMPAIGN REGISTRY MAP FOR FRONTIER OUTPUTS
****************************************************************************************************

PURPOSE:
    Create a temporary campaign registry map that enriches archived frontier points with formal run
    IDs and documentation metadata when those registry rows exist.

BUSINESS PURPOSE:
    Make the strategy frontier easier to connect to:
        run roadmap,
        validation evidence groups,
        README summaries,
        LinkedIn post sequences,
        executive review,
        and future validation-summary drafting.

SQL PURPOSE:
    1. Drop any prior tmp_m2_strategy_frontier_campaign_registry_map.
    2. Check whether credit_decisioning_sim.strategy_run_campaign_registry exists.
    3. If the registry does not exist, create an empty map with the expected schema.
    4. If the registry exists, load active registry rows.
    5. Rank active registry rows to prevent duplicate registry mappings from multiplying frontier
       output rows.
    6. Surface registry_match_count and frontier_registry_match_status.

REGISTRY MAP GRAIN:
    One row per active technical campaign key:

        module1_scenario_set_name
        module1_scenario_name
        population_id
        strategy_set_name
        strategy_name
        strategy_version

REGISTRY STATUS VALUES:
    FRONTIER_REGISTRY_MATCHED:
        Exactly one active registry row matched the technical frontier key.

    FRONTIER_REGISTRY_DUPLICATE_MATCH_REVIEW:
        More than one active registry row matched the same technical frontier key.

        Section 15 selects one ranked row to avoid duplicate frontier rows, but the registry should
        be reviewed.

    FRONTIER_REGISTRY_NOT_FOUND:
        Assigned later in the executive summary when no registry row exists for a frontier point.

WHAT TO LOOK FOR:
    For formal campaign documentation, frontier rows should ideally map to one active registry row.

    Missing registry rows do not invalidate strategy frontier metrics, but they limit evidence
    traceability.

    Duplicate registry rows should be reviewed before documentation.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    DO $$ ... END $$:
        Allows conditional table creation depending on whether the registry table exists.

    CREATE TEMP TABLE:
        Creates a current-session helper table.

    ROW_NUMBER:
        Selects one registry row when duplicate active registry rows exist for the same technical key.

    COUNT(*) OVER:
        Records how many registry rows map to the same technical key.

    PARTITION BY:
        Defines the technical registry-match grain used for row-numbering and duplicate detection.

BOUNDARY:
    This section reads campaign registry metadata only.

    It does not insert registry rows.
    It does not update registry rows.
    It does not delete registry rows.
    It does not modify archive rows.
    It does not modify strategy outputs.
    It does not require registry mapping for Section 15 metrics to run.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_campaign_registry_map;

DO $$
BEGIN
    /*-------------------------------------------------------------------------------------------
    Conditional branch:
        If the persistent registry does not exist, create an empty temporary map.

    Business interpretation:
        Frontier metrics can still be reviewed without registry metadata.

        The absence of registry metadata is a documentation-linkage limitation, not a strategy output
        failure.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_run_campaign_registry') IS NULL THEN

        CREATE TEMP TABLE tmp_m2_strategy_frontier_campaign_registry_map (
            /***************************************************************************************
            Campaign identifiers.
            ***************************************************************************************/
            module1_run_id                       TEXT,
            module2_run_id                       TEXT,
            run_sequence_number                  INTEGER,

            showcase_id                          TEXT,
            showcase_name                        TEXT,
            comparison_group_id                  TEXT,
            validation_evidence_group_id         TEXT,

            /***************************************************************************************
            Technical Module 1 lineage and Module 2 strategy identity.
            ***************************************************************************************/
            module1_scenario_set_name            TEXT,
            module1_scenario_name                TEXT,
            population_id                        TEXT,

            strategy_set_name                    TEXT,
            strategy_name                        TEXT,
            strategy_version                     TEXT,

            /***************************************************************************************
            Documentation helper fields.
            ***************************************************************************************/
            readme_storyline_label               TEXT,
            linkedin_post_sequence               INTEGER,
            validation_summary_section_hint       TEXT,

            /***************************************************************************************
            Registry diagnostics.
            ***************************************************************************************/
            registry_active_flag                 BOOLEAN,
            registry_match_count                 BIGINT,
            frontier_registry_match_status        TEXT
        ) ON COMMIT PRESERVE ROWS;

    ELSE

        /*---------------------------------------------------------------------------------------
        Registry table exists:
            load active mappings and rank duplicates.

        SQL mechanics:
            registry_ranked calculates two window values:

                registry_match_count:
                    how many active registry rows share the same technical key.

                registry_rank:
                    deterministic row number used to keep one registry row per key.

        Why this matters:
            Without ranking, duplicate active registry rows could multiply frontier rows during
            later LEFT JOINs.
        ---------------------------------------------------------------------------------------*/
        CREATE TEMP TABLE tmp_m2_strategy_frontier_campaign_registry_map
        ON COMMIT PRESERVE ROWS
        AS
        WITH registry_ranked AS (
            SELECT
                /***********************************************************************************
                Stable campaign IDs.

                These are documentation and evidence-linkage fields.
                They do not replace the technical frontier key.
                ***********************************************************************************/
                r.module1_run_id,
                r.module2_run_id,
                r.run_sequence_number,

                r.showcase_id,
                r.showcase_name,
                r.comparison_group_id,
                r.validation_evidence_group_id,

                /***********************************************************************************
                Technical run key used to match archive frontier rows to campaign registry rows.
                ***********************************************************************************/
                r.module1_scenario_set_name,
                r.module1_scenario_name,
                r.population_id,

                r.strategy_set_name,
                r.strategy_name,
                r.strategy_version,

                /***********************************************************************************
                Documentation guidance fields.
                ***********************************************************************************/
                r.readme_storyline_label,
                r.linkedin_post_sequence,
                r.validation_summary_section_hint,

                r.registry_active_flag,

                /***********************************************************************************
                Duplicate active registry mapping count.

                Expected:
                    1

                Review:
                    values greater than 1 mean duplicate active registry rows exist for the same
                    technical run key.
                ***********************************************************************************/
                COUNT(*) OVER (
                    PARTITION BY
                        r.module1_scenario_set_name,
                        r.module1_scenario_name,
                        r.population_id,
                        r.strategy_set_name,
                        r.strategy_name,
                        r.strategy_version
                ) AS registry_match_count,

                /***********************************************************************************
                Deterministic row selector for duplicate registry mappings.

                ORDER BY:
                    run_sequence_number first when populated,
                    then module2_run_id for deterministic tie-breaking.
                ***********************************************************************************/
                ROW_NUMBER() OVER (
                    PARTITION BY
                        r.module1_scenario_set_name,
                        r.module1_scenario_name,
                        r.population_id,
                        r.strategy_set_name,
                        r.strategy_name,
                        r.strategy_version
                    ORDER BY
                        r.run_sequence_number NULLS LAST,
                        r.module2_run_id
                ) AS registry_rank

            FROM credit_decisioning_sim.strategy_run_campaign_registry r

            WHERE r.registry_active_flag IS TRUE
        )

        SELECT
            module1_run_id,
            module2_run_id,
            run_sequence_number,

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

            readme_storyline_label,
            linkedin_post_sequence,
            validation_summary_section_hint,

            registry_active_flag,
            registry_match_count,

            /***************************************************************************************
            Registry match status.

            FRONTIER_REGISTRY_MATCHED:
                clean one-to-one mapping.

            FRONTIER_REGISTRY_DUPLICATE_MATCH_REVIEW:
                Section 15 selected one ranked row, but the registry should be reviewed.
            ***************************************************************************************/
            CASE
                WHEN registry_match_count = 1
                    THEN 'FRONTIER_REGISTRY_MATCHED'
                ELSE 'FRONTIER_REGISTRY_DUPLICATE_MATCH_REVIEW'
            END AS frontier_registry_match_status

        FROM registry_ranked

        WHERE registry_rank = 1;
    END IF;
END $$;


/*-----------------------------------------------------------------------------------------------
15.0A.1 Campaign registry map review output.

Business purpose:
    Display the registry mappings available to enrich frontier rows.

What to look for:
    For formal campaign documentation, the archived strategy slices in the frontier should ideally
    appear here with one active registry row each.

Review triggers:
    No rows:
        registry table may not exist, or no active registry rows exist.

    FRONTIER_REGISTRY_DUPLICATE_MATCH_REVIEW:
        more than one active registry row maps to the same technical frontier key.

SQL mechanics:
    This SELECT reads only the temporary map created above.

Boundary:
    Missing rows do not mean missing archive results.

    They mean one or more archive frontier points may not yet have formal campaign IDs attached.
-----------------------------------------------------------------------------------------------*/

SELECT
    *
FROM tmp_m2_strategy_frontier_campaign_registry_map
ORDER BY
    run_sequence_number,
    module2_run_id,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 15.1 — ARCHIVED FRONTIER INVENTORY
****************************************************************************************************

PURPOSE:
    Create an inventory of archived strategy / scenario / population slices available for frontier
    analysis.

BUSINESS PURPOSE:
    Confirm what completed Module 2 strategy outputs exist in the archive before interpreting
    strategy frontier metrics.

    Section 15.1 answers:

        "What completed archived frontier points are available, and are they clean at archive grain?"

SQL PURPOSE:
    1. Drop any prior tmp_m2_strategy_frontier_inventory.
    2. Create tmp_m2_strategy_frontier_inventory.
    3. Summarize archived row counts by strategy / scenario / population slice.
    4. Confirm distinct application_id counts within each slice.
    5. Surface duplicate application_id counts within each slice.
    6. Show latest-output and archive timestamp ranges.
    7. Show final outcome counts.
    8. Show simulated positive offer-exposure count.

FRONTIER INVENTORY GRAIN:
    One row per:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

WHAT TO LOOK FOR:
    archived_row_count:
        completed applicant-level population for the archived slice.

    distinct_application_id_count:
        should equal archived_row_count within each slice.

    duplicate_application_row_count:
        should ordinarily be zero.

    approval_count / counteroffer_count / manual_review_count / decline_count:
        first high-level outcome view for each archived slice.

    simulated_offer_exposure_count:
        should equal APPROVE + COUNTEROFFER if final output conventions are intact.

REVIEW TRIGGERS:
    duplicate_application_row_count > 0:
        Archive grain issue. Frontier metrics should not be interpreted until reviewed.

    Unexpected archived_row_count:
        May indicate incomplete archive persistence, wrong archive reset mode, or source-scope
        mismatch.

    Missing expected baseline or challenger slices:
        Baseline-relative deltas or comparison interpretation may be unavailable.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the archive inventory for reuse in later diagnostics.

    GROUP BY:
        Collapses applicant-level archive rows into one row per archived frontier slice.

    COUNT(DISTINCT application_id):
        Confirms archive row-level grain within each slice.

    COUNT(*) FILTER:
        Calculates outcome-specific counts in the same grouped query.

BOUNDARY:
    This inventory is read-only against the archive.

    The temporary table is a diagnostic helper only.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;

CREATE TEMP TABLE tmp_m2_strategy_frontier_inventory
ON COMMIT PRESERVE ROWS
AS
SELECT
    /***********************************************************************************************
    Technical frontier key.

    This is the core Section 15 summary grain.
    ***********************************************************************************************/
    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    /***********************************************************************************************
    Row-count and archive-grain diagnostics.

    Expected within each archived slice:
        archived_row_count = distinct_application_id_count
        duplicate_application_row_count = 0
    ***********************************************************************************************/
    COUNT(*) AS archived_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_row_count,

    /***********************************************************************************************
    Latest-output and archive timestamp ranges.

    Boundary:
        These timestamps are audit metadata only.

        They are not comparison keys, not archive replacement keys, and not frontier ranking inputs.
    ***********************************************************************************************/
    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,

    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts,

    /***********************************************************************************************
    Final simulated outcome counts.

    These provide the first quick outcome composition view for each archived frontier point.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

    /***********************************************************************************************
    Simulated positive offer-exposure count.

    Expected:
        final APPROVE rows + final COUNTEROFFER rows.
    ***********************************************************************************************/
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS simulated_offer_exposure_count

FROM credit_decisioning_sim.strategy_decisions_archive

GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
15.1A Archive frontier inventory review output.

Business purpose:
    Display every archived strategy / scenario / population slice available to Section 15.

What to look for:
    Confirm the archive includes the intended baseline and challenger strategy slices.

    Confirm row counts and duplicate_application_row_count before interpreting frontier metrics.

Review triggers:
    duplicate_application_row_count > 0:
        Archive grain requires review.

    Missing expected strategy_name:
        The run may not have been archived or may have been archived under different identifiers.

SQL mechanics:
    This is a simple SELECT from the temporary inventory table.

Documentation use:
    Use this as the "available archived runs" control table.
-----------------------------------------------------------------------------------------------*/

SELECT
    *
FROM tmp_m2_strategy_frontier_inventory
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 15.2 — STRATEGY FRONTIER SUMMARY
****************************************************************************************************

PURPOSE:
    Produce one portfolio-level summary row per archived Module 1 scenario × Module 2 strategy slice.

BUSINESS PURPOSE:
    Convert archived applicant-level strategy outputs into strategy frontier metrics.

    Section 15.2 answers:

        "For each archived strategy / scenario slice, what are the core access, exposure, risk,
         affordability, Expected Loss, and reason-code characteristics?"

SQL PURPOSE:
    1. Drop any prior tmp_m2_strategy_frontier_summary.
    2. Create tmp_m2_strategy_frontier_summary.
    3. Calculate final decision counts and rates.
    4. Calculate simulated positive offer-exposure counts and rates.
    5. Calculate approval and counteroffer shares among offer rows.
    6. Calculate requested amount and approved amount totals / averages.
    7. Calculate counteroffer exposure-reduction averages.
    8. Calculate requested PTI and approved PTI averages.
    9. Calculate synthetic estimated-risk proxy averages across all rows, offer rows, declined rows,
       and manual-review rows.
    10. Calculate LGD averages.
    11. Calculate requested Expected Loss and approved Expected Loss metrics.
    12. Calculate requested and approved Expected Loss rates.
    13. Identify the top primary reason code.
    14. Identify the top non-approval reason code.
    15. Identify the top policy-stop reason code.

BUSINESS INTERPRETATION:
    This is the core strategy frontier table.

    It summarizes:
        decision distribution,
        simulated offer exposure,
        approved amount,
        approved affordability,
        synthetic estimated-risk profile,
        requested Expected Loss,
        approved Expected Loss,
        approved Expected Loss rate,
        and primary reason-code concentration.

WHAT TO LOOK FOR:
    simulated_offer_exposure_rate:
        Access / positive simulated offer-exposure metric.

    total_approved_amount:
        Simulated approved exposure impact.

    total_approved_expected_loss_amount:
        Total synthetic approved-exposure Expected Loss.

    approved_expected_loss_rate:
        Approved Expected Loss per approved exposure dollar.

    counteroffer_share_of_offers:
        Reliance on reduced-exposure treatment among positive offer rows.

    manual_review_rate:
        Unresolved outcome burden.

    decline_rate:
        No-offer concentration.

    top_non_approval_primary_reason_code:
        Often more useful than top_primary_reason_code when approvals dominate.

REVIEW TRIGGERS:
    High approved_expected_loss_rate:
        Review risk, product, LGD, approved amount, and strategy posture.

    High counteroffer_share_of_offers:
        Review whether the strategy depends heavily on reduced-exposure treatment.

    High manual_review_rate:
        Review unresolved operational burden.

    High decline_rate:
        Review no-offer concentration and policy-stop reason-code story.

METRIC CONVENTIONS:
    approval_rate:
        approval_count / applications

    counteroffer_rate:
        counteroffer_count / applications

    manual_review_rate:
        manual_review_count / applications

    decline_rate:
        decline_count / applications

    simulated_offer_exposure_rate:
        simulated_offer_exposure_count / applications

    approval_share_of_offers:
        approval_count / simulated_offer_exposure_count

    counteroffer_share_of_offers:
        counteroffer_count / simulated_offer_exposure_count

    requested_expected_loss_rate:
        total_requested_expected_loss_amount / total_requested_amount

    approved_expected_loss_rate:
        total_approved_expected_loss_amount / total_approved_amount

    All-application approved exposure metrics:
        Use COALESCE(approved_amount, 0)
        Use COALESCE(approved_expected_loss_amount, 0)

    Offer-row metrics:
        Use FILTER (WHERE simulated_offer_exposure_flag IS TRUE)

WHY NON-APPROVAL REASON FIELDS ARE INCLUDED:
    top_primary_reason_code is often APPROVED_AS_REQUESTED.

    That is technically correct but not always the most useful executive explanation of strategy
    movement.

    top_non_approval_primary_reason_code and top_policy_stop_primary_reason_code help explain what
    constrains access, drives reduced exposure, or concentrates final no-offer outcomes.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CTE:
        Breaks the frontier summary into readable stages.

    COUNT(*) FILTER:
        Calculates outcome-specific metrics in one grouped query.

    COALESCE:
        Converts unresolved / no-offer approved values to zero for all-application impact metrics.

    NULLIF:
        Prevents divide-by-zero in rates and shares.

    ROW_NUMBER:
        Ranks reason-code distributions so the top reason code can be selected deterministically.

    LEFT JOIN:
        Adds reason-code story fields while preserving every frontier summary row.

BOUNDARY:
    approved_expected_loss_rate is a synthetic strategy frontier metric.

    It is not a production loss-rate forecast.
    It is not profitability.
    It is not capital consumption.
    It is not risk-adjusted margin.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;

CREATE TEMP TABLE tmp_m2_strategy_frontier_summary
ON COMMIT PRESERVE ROWS
AS
WITH slice_summary AS (
    SELECT
        /*******************************************************************************************
        Frontier grain:
            one archived strategy / Module 1 scenario / population slice.
        *******************************************************************************************/
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        /*******************************************************************************************
        Archived slice population size.
        *******************************************************************************************/
        COUNT(*) AS applications,

        /*******************************************************************************************
        Final outcome counts.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        /*******************************************************************************************
        Positive simulated offer-exposure count.

        TRUE for APPROVE and COUNTEROFFER only.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_count,

        /*******************************************************************************************
        Final decision rates.

        SQL mechanics:
            FILTER creates the numerator for each final outcome.
            COUNT(*) is the archived-slice denominator.
            NULLIF prevents divide-by-zero.
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
        Positive simulated offer-exposure rate.

        Use this as the high-level simulated access / positive-offer metric.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        /*******************************************************************************************
        Offer composition.

        approval_share_of_offers:
            share of positive offer rows that were final APPROVE.

        counteroffer_share_of_offers:
            share of positive offer rows that were final COUNTEROFFER.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS approval_share_of_offers,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS counteroffer_share_of_offers,

        /*******************************************************************************************
        Requested and approved exposure totals.

        COALESCE turns unresolved / no-offer approved exposure into zero for portfolio-impact
        metrics.
        *******************************************************************************************/
        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

        /*******************************************************************************************
        Offer-row approved amount.

        FILTER keeps this metric focused on final APPROVE and COUNTEROFFER rows only.
        *******************************************************************************************/
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        /*******************************************************************************************
        Counteroffer exposure reduction.

        Populated only for final COUNTEROFFER rows.
        *******************************************************************************************/
        AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS avg_exposure_reduction_pct_counteroffers,

        /*******************************************************************************************
        Requested and approved affordability.

        requested_payment_to_income_ratio:
            original requested-structure PTI.

        approved_payment_to_income_ratio:
            final approved-exposure PTI proxy for offer rows.
        *******************************************************************************************/
        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows,

        /*******************************************************************************************
        Synthetic estimated-risk profile.

        estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD
        proxy.
        *******************************************************************************************/
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_declined_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS avg_synthetic_estimated_pd_proxy_manual_review_rows,

        /*******************************************************************************************
        LGD profile.

        estimated_lgd remains a synthetic product / exposure severity approximation.
        *******************************************************************************************/
        AVG(estimated_lgd) AS avg_estimated_lgd_all_apps,

        AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_estimated_lgd_offer_rows,

        /*******************************************************************************************
        Requested and approved Expected Loss totals and averages.

        requested_expected_loss_amount:
            requested-exposure Expected Loss.

        approved_expected_loss_amount:
            approved-exposure Expected Loss after final Module 2 exposure treatment.
        *******************************************************************************************/
        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        /*******************************************************************************************
        Expected Loss rates.

        requested_expected_loss_rate:
            requested EL / requested amount.

        approved_expected_loss_rate:
            approved EL / approved amount.

        Boundary:
            These are synthetic strategy metrics, not production loss-rate forecasts.
        *******************************************************************************************/
        SUM(requested_expected_loss_amount)
            / NULLIF(SUM(requested_amount), 0)
            AS requested_expected_loss_rate,

        SUM(COALESCE(approved_expected_loss_amount, 0))
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
),

reason_counts AS (
    /***********************************************************************************************
    CTE: reason_counts

    Purpose:
        Rank primary reason codes within each archived strategy / scenario slice.

    SQL mechanics:
        COUNT(*) creates reason-code frequency.
        Window SUM creates the population-share denominator.
        ROW_NUMBER selects the top reason code deterministically.

    Interpretation:
        top_primary_reason_code is often APPROVED_AS_REQUESTED for high-approval strategies.
    ***********************************************************************************************/
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS primary_reason_row_count,

        COUNT(*)::NUMERIC
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
            ) AS primary_reason_population_share,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                COUNT(*) DESC,
                primary_reason_family,
                primary_reason_code
        ) AS reason_rank

    FROM credit_decisioning_sim.strategy_decisions_archive

    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code
),

non_approval_reason_counts AS (
    /***********************************************************************************************
    CTE: non_approval_reason_counts

    Purpose:
        Identify the top non-approval reason code.

    Why this matters:
        APPROVED_AS_REQUESTED may dominate top_primary_reason_code, but executive storytelling often
        needs the most common constraint, counteroffer, review, or no-offer driver.
    ***********************************************************************************************/
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS non_approval_reason_row_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                COUNT(*) DESC,
                primary_reason_family,
                primary_reason_code
        ) AS non_approval_reason_rank

    FROM credit_decisioning_sim.strategy_decisions_archive

    WHERE decision_outcome <> 'APPROVE'

    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code
),

policy_stop_reason_counts AS (
    /***********************************************************************************************
    CTE: policy_stop_reason_counts

    Purpose:
        Identify the top policy-stop reason code.

    Why this matters:
        Policy-stop concentration helps explain final no-offer behavior.

    Boundary:
        POLICY_STOP reason codes are simulated strategy explanation codes, not adverse-action
        reasons or customer communication text.
    ***********************************************************************************************/
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS policy_stop_reason_row_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                COUNT(*) DESC,
                primary_reason_family,
                primary_reason_code
        ) AS policy_stop_reason_rank

    FROM credit_decisioning_sim.strategy_decisions_archive

    WHERE primary_reason_family = 'POLICY_STOP'

    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code
)

SELECT
    /***********************************************************************************************
    Core frontier metrics from the archived slice summary.
    ***********************************************************************************************/
    s.*,

    /***********************************************************************************************
    Top primary reason code overall.
    ***********************************************************************************************/
    r.primary_reason_family AS top_primary_reason_family,
    r.primary_reason_code AS top_primary_reason_code,
    r.primary_reason_row_count AS top_primary_reason_row_count,
    r.primary_reason_population_share AS top_primary_reason_population_share,

    /***********************************************************************************************
    Top non-approval reason code.

    Interpretation:
        Useful when the top overall reason is APPROVED_AS_REQUESTED and reviewers need the strongest
        constraint / non-approval story.
    ***********************************************************************************************/
    nr.primary_reason_family AS top_non_approval_primary_reason_family,
    nr.primary_reason_code AS top_non_approval_primary_reason_code,

    nr.non_approval_reason_row_count::NUMERIC
        / NULLIF(s.applications, 0) AS top_non_approval_reason_population_share,

    /***********************************************************************************************
    Top policy-stop reason code.

    Interpretation:
        Useful for explaining no-offer concentration.
    ***********************************************************************************************/
    ps.primary_reason_family AS top_policy_stop_primary_reason_family,
    ps.primary_reason_code AS top_policy_stop_primary_reason_code,

    ps.policy_stop_reason_row_count::NUMERIC
        / NULLIF(s.applications, 0) AS top_policy_stop_reason_population_share

FROM slice_summary s

LEFT JOIN reason_counts r
    ON r.strategy_set_name = s.strategy_set_name
   AND r.strategy_name = s.strategy_name
   AND r.strategy_version = s.strategy_version
   AND r.module1_scenario_set_name = s.module1_scenario_set_name
   AND r.module1_scenario_name = s.module1_scenario_name
   AND r.population_id = s.population_id
   AND r.reason_rank = 1

LEFT JOIN non_approval_reason_counts nr
    ON nr.strategy_set_name = s.strategy_set_name
   AND nr.strategy_name = s.strategy_name
   AND nr.strategy_version = s.strategy_version
   AND nr.module1_scenario_set_name = s.module1_scenario_set_name
   AND nr.module1_scenario_name = s.module1_scenario_name
   AND nr.population_id = s.population_id
   AND nr.non_approval_reason_rank = 1

LEFT JOIN policy_stop_reason_counts ps
    ON ps.strategy_set_name = s.strategy_set_name
   AND ps.strategy_name = s.strategy_name
   AND ps.strategy_version = s.strategy_version
   AND ps.module1_scenario_set_name = s.module1_scenario_set_name
   AND ps.module1_scenario_name = s.module1_scenario_name
   AND ps.population_id = s.population_id
   AND ps.policy_stop_reason_rank = 1;


/*-----------------------------------------------------------------------------------------------
15.2A Core strategy frontier summary review output.

Business purpose:
    Display one summary row per archived strategy / scenario / population slice.

What to look for:
    Review:
        simulated_offer_exposure_rate,
        total_approved_amount,
        total_approved_expected_loss_amount,
        approved_expected_loss_rate,
        avg_synthetic_estimated_pd_proxy_offer_rows,
        counteroffer_share_of_offers,
        manual_review_rate,
        decline_rate,
        top_non_approval_primary_reason_code,
        top_policy_stop_primary_reason_code.

Review triggers:
    Large approved Expected Loss rate, large counteroffer share, large manual-review burden, or
    dominant policy-stop reasons should be interpreted before executive storytelling.

SQL mechanics:
    This query reads the already materialized temporary summary table.

Documentation use:
    This output is the technical foundation for the later executive summary table.
-----------------------------------------------------------------------------------------------*/

SELECT
    *
FROM tmp_m2_strategy_frontier_summary
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 15.3 — BASELINE-RELATIVE FRONTIER DELTAS
****************************************************************************************************

PURPOSE:
    Calculate baseline-relative deltas for each archived strategy slice where a baseline strategy
    exists for the same Module 1 scenario / population / strategy set.

BUSINESS PURPOSE:
    Make frontier interpretation sharper by anchoring each non-baseline strategy point to a
    consistent baseline reference.

    Section 15.3 answers:

        "Relative to BASELINE_STRATEGY on the same Module 1 scenario and population, what changed in
         access, exposure, approved Expected Loss, affordability, offered-population synthetic risk,
         and reason-code distribution?"

BASELINE DEFINITION:
    The baseline reference is identified by:

        strategy_name = 'BASELINE_STRATEGY'

    within the same:
        strategy_set_name
        module1_scenario_set_name
        module1_scenario_name
        population_id

WHY THIS MATTERS:
    Frontier analysis is more interpretable when strategy points are compared against a consistent
    baseline reference.

    It helps distinguish:
        absolute strategy posture,
        versus baseline-relative movement.

BASELINE UNAVAILABLE BOUNDARY:
    If no baseline strategy exists for a scenario / strategy set, baseline-relative fields are NULL
    and baseline_available_flag is FALSE.

    This is diagnostic behavior, not a failure.

    NULL baseline-relative values should not be interpreted as zero movement.

REASON-CODE DELTA DRIVER:
    top_reason_code_delta_driver_* fields identify the simulated reason code with the largest
    population-share movement versus baseline.

    This helps explain not only what changed numerically, but why the strategy frontier point moved.

WHAT TO LOOK FOR:
    baseline_available_flag:
        TRUE means baseline-relative deltas are interpretable.
        FALSE means baseline-relative deltas are unavailable.

    delta_simulated_offer_exposure_rate:
        access movement relative to baseline.

    delta_total_approved_amount:
        approved exposure movement relative to baseline.

    delta_total_approved_expected_loss_amount:
        approved Expected Loss movement relative to baseline.

    delta_approved_expected_loss_rate:
        approved Expected Loss rate movement relative to baseline.

    top_reason_code_delta_driver_code:
        explanation-code movement with the largest population-share shift.

REVIEW TRIGGERS:
    baseline_available_flag = FALSE:
        baseline-relative interpretation is unavailable.

    Large access increase with large approved Expected Loss increase:
        growth / risk tradeoff should be explained.

    Large approved Expected Loss decrease with access decrease:
        risk-discipline tradeoff should be explained.

    Large reason-code movement:
        should be reviewed for strategy story.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    baseline_reference:
        selects baseline frontier rows.

    baseline_groups:
        identifies comparable groups that actually have a baseline.

    reason_population_shares:
        calculates reason-code shares per archived strategy slice.

    frontier_group_reason_universe:
        creates the union of reason codes inside each scenario / strategy-set group.

    baseline_reason_population_shares:
        isolates baseline reason-code shares.

    top_reason_code_delta_driver:
        compares strategy reason-code share to baseline reason-code share and ranks the largest
        absolute movement.

    LEFT JOIN:
        preserves strategy rows even when baseline or reason-code deltas are unavailable.

BOUNDARY:
    This section reads from archive-derived temporary tables and archive reason-code counts only.

    It does not mutate archive rows.
    It does not recalculate applicant outcomes.
    It does not reassign reason codes.
    It does not create matched application-level comparison output.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_baseline_deltas;

CREATE TEMP TABLE tmp_m2_strategy_frontier_baseline_deltas
ON COMMIT PRESERVE ROWS
AS
WITH baseline_reference AS (
    /***********************************************************************************************
    Baseline reference rows.

    Baseline is selected by strategy_name = BASELINE_STRATEGY within the same strategy set and
    Module 1 scenario / population.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_strategy_frontier_summary
    WHERE strategy_name = 'BASELINE_STRATEGY'
),

baseline_groups AS (
    /***********************************************************************************************
    Comparable groups where a baseline exists.

    This CTE prevents reason-code delta logic from implying movement versus a missing baseline.
    ***********************************************************************************************/
    SELECT DISTINCT
        strategy_set_name,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM baseline_reference
),

reason_population_shares AS (
    /***********************************************************************************************
    Reason-code population shares by archived frontier slice.

    SQL mechanics:
        COUNT(*) gives reason count.
        Window SUM gives the slice-level denominator.

    Interpretation:
        Each reason_population_share is the share of the archived slice represented by that
        primary_reason_code.
    ***********************************************************************************************/
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        primary_reason_family,
        primary_reason_code,

        COUNT(*)::NUMERIC
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
            ) AS reason_population_share

    FROM credit_decisioning_sim.strategy_decisions_archive

    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code
),

frontier_group_reason_universe AS (
    /***********************************************************************************************
    Reason-code universe within each frontier group.

    Purpose:
        Include reason codes that appear in any strategy row in the same scenario / strategy-set
        group so movement from zero to nonzero, or nonzero to zero, can be detected.
    ***********************************************************************************************/
    SELECT DISTINCT
        strategy_set_name,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code
    FROM reason_population_shares
),

baseline_reason_population_shares AS (
    /***********************************************************************************************
    Baseline reason-code share table.

    Purpose:
        Provides baseline comparison values for reason-code movement.
    ***********************************************************************************************/
    SELECT
        strategy_set_name,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code,
        reason_population_share AS baseline_reason_population_share
    FROM reason_population_shares
    WHERE strategy_name = 'BASELINE_STRATEGY'
),

top_reason_code_delta_driver AS (
    /***********************************************************************************************
    Reason-code movement driver.

    Purpose:
        For each non-baseline strategy row where a baseline exists, find the reason code whose
        population share moved most versus baseline.

    SQL mechanics:
        JOIN baseline_groups:
            restricts the calculation to groups with a true baseline.

        COALESCE:
            treats missing strategy or baseline reason-code shares as zero.

        ROW_NUMBER:
            ranks the largest absolute movement first.
    ***********************************************************************************************/
    SELECT
        s.strategy_set_name,
        s.strategy_name,
        s.strategy_version,
        s.module1_scenario_set_name,
        s.module1_scenario_name,
        s.population_id,

        u.primary_reason_family AS top_reason_code_delta_driver_family,
        u.primary_reason_code AS top_reason_code_delta_driver_code,

        COALESCE(br.baseline_reason_population_share, 0)
            AS top_reason_code_delta_driver_baseline_share,

        COALESCE(rs.reason_population_share, 0)
            AS top_reason_code_delta_driver_strategy_share,

        COALESCE(rs.reason_population_share, 0)
          - COALESCE(br.baseline_reason_population_share, 0)
            AS top_reason_code_delta_population_share,

        ROW_NUMBER() OVER (
            PARTITION BY
                s.strategy_set_name,
                s.strategy_name,
                s.strategy_version,
                s.module1_scenario_set_name,
                s.module1_scenario_name,
                s.population_id
            ORDER BY
                ABS(
                    COALESCE(rs.reason_population_share, 0)
                  - COALESCE(br.baseline_reason_population_share, 0)
                ) DESC,
                u.primary_reason_family,
                u.primary_reason_code
        ) AS reason_code_delta_rank

    FROM tmp_m2_strategy_frontier_summary s

    JOIN baseline_groups bg
        ON bg.strategy_set_name = s.strategy_set_name
       AND bg.module1_scenario_set_name = s.module1_scenario_set_name
       AND bg.module1_scenario_name = s.module1_scenario_name
       AND bg.population_id = s.population_id

    JOIN frontier_group_reason_universe u
        ON u.strategy_set_name = s.strategy_set_name
       AND u.module1_scenario_set_name = s.module1_scenario_set_name
       AND u.module1_scenario_name = s.module1_scenario_name
       AND u.population_id = s.population_id

    LEFT JOIN reason_population_shares rs
        ON rs.strategy_set_name = s.strategy_set_name
       AND rs.strategy_name = s.strategy_name
       AND rs.strategy_version = s.strategy_version
       AND rs.module1_scenario_set_name = s.module1_scenario_set_name
       AND rs.module1_scenario_name = s.module1_scenario_name
       AND rs.population_id = s.population_id
       AND rs.primary_reason_family = u.primary_reason_family
       AND rs.primary_reason_code = u.primary_reason_code

    LEFT JOIN baseline_reason_population_shares br
        ON br.strategy_set_name = s.strategy_set_name
       AND br.module1_scenario_set_name = s.module1_scenario_set_name
       AND br.module1_scenario_name = s.module1_scenario_name
       AND br.population_id = s.population_id
       AND br.primary_reason_family = u.primary_reason_family
       AND br.primary_reason_code = u.primary_reason_code

    WHERE s.strategy_name <> 'BASELINE_STRATEGY'
)

SELECT
    /***********************************************************************************************
    Technical frontier key.
    ***********************************************************************************************/
    s.strategy_set_name,
    s.strategy_name,
    s.strategy_version,

    s.module1_scenario_set_name,
    s.module1_scenario_name,
    s.population_id,

    /***********************************************************************************************
    Baseline reference identity.

    NULL values mean no matching BASELINE_STRATEGY was available for the same strategy set and
    Module 1 scenario / population.
    ***********************************************************************************************/
    b.strategy_name AS baseline_strategy_name,
    b.strategy_version AS baseline_strategy_version,

    (b.strategy_name IS NOT NULL) AS baseline_available_flag,

    /***********************************************************************************************
    Population count movement.

    In a controlled same-population strategy comparison, delta_applications should generally be zero.
    ***********************************************************************************************/
    s.applications,
    b.applications AS baseline_applications,
    s.applications - b.applications AS delta_applications,

    /***********************************************************************************************
    Final outcome-rate deltas.
    ***********************************************************************************************/
    s.approval_rate,
    b.approval_rate AS baseline_approval_rate,
    s.approval_rate - b.approval_rate AS delta_approval_rate,

    s.counteroffer_rate,
    b.counteroffer_rate AS baseline_counteroffer_rate,
    s.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

    s.manual_review_rate,
    b.manual_review_rate AS baseline_manual_review_rate,
    s.manual_review_rate - b.manual_review_rate AS delta_manual_review_rate,

    s.decline_rate,
    b.decline_rate AS baseline_decline_rate,
    s.decline_rate - b.decline_rate AS delta_decline_rate,

    /***********************************************************************************************
    Simulated offer-exposure deltas.

    This is the primary access / positive-offer movement metric.
    ***********************************************************************************************/
    s.simulated_offer_exposure_rate,
    b.simulated_offer_exposure_rate AS baseline_simulated_offer_exposure_rate,
    s.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
        AS delta_simulated_offer_exposure_rate,

    s.counteroffer_share_of_offers,
    b.counteroffer_share_of_offers AS baseline_counteroffer_share_of_offers,
    s.counteroffer_share_of_offers - b.counteroffer_share_of_offers
        AS delta_counteroffer_share_of_offers,

    /***********************************************************************************************
    Approved exposure deltas.
    ***********************************************************************************************/
    s.total_approved_amount,
    b.total_approved_amount AS baseline_total_approved_amount,
    s.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    s.avg_approved_amount_all_apps,
    b.avg_approved_amount_all_apps AS baseline_avg_approved_amount_all_apps,
    s.avg_approved_amount_all_apps - b.avg_approved_amount_all_apps
        AS delta_avg_approved_amount_all_apps,

    s.avg_approved_amount_offer_rows,
    b.avg_approved_amount_offer_rows AS baseline_avg_approved_amount_offer_rows,
    s.avg_approved_amount_offer_rows - b.avg_approved_amount_offer_rows
        AS delta_avg_approved_amount_offer_rows,

    /***********************************************************************************************
    Offered-population synthetic risk and affordability deltas.

    estimated_pd remains interpreted as the synthetic estimated-PD proxy.
    ***********************************************************************************************/
    s.avg_synthetic_estimated_pd_proxy_offer_rows,
    b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS baseline_avg_synthetic_estimated_pd_proxy_offer_rows,
    s.avg_synthetic_estimated_pd_proxy_offer_rows
      - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_avg_synthetic_estimated_pd_proxy_offer_rows,

    s.avg_approved_payment_to_income_ratio_offer_rows,
    b.avg_approved_payment_to_income_ratio_offer_rows
        AS baseline_avg_approved_payment_to_income_ratio_offer_rows,
    s.avg_approved_payment_to_income_ratio_offer_rows
      - b.avg_approved_payment_to_income_ratio_offer_rows
        AS delta_avg_approved_payment_to_income_ratio_offer_rows,

    /***********************************************************************************************
    Requested and approved Expected Loss deltas.

    requested_expected_loss_amount:
        requested-exposure Expected Loss.

    approved_expected_loss_amount:
        approved-exposure Expected Loss after final strategy treatment.
    ***********************************************************************************************/
    s.total_requested_expected_loss_amount,
    b.total_requested_expected_loss_amount AS baseline_total_requested_expected_loss_amount,
    s.total_requested_expected_loss_amount - b.total_requested_expected_loss_amount
        AS delta_total_requested_expected_loss_amount,

    s.total_approved_expected_loss_amount,
    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    s.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    s.avg_approved_expected_loss_offer_rows,
    b.avg_approved_expected_loss_offer_rows
        AS baseline_avg_approved_expected_loss_offer_rows,
    s.avg_approved_expected_loss_offer_rows
      - b.avg_approved_expected_loss_offer_rows
        AS delta_avg_approved_expected_loss_offer_rows,

    s.approved_expected_loss_rate,
    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    s.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    /***********************************************************************************************
    Reason-code story fields from the strategy point.
    ***********************************************************************************************/
    s.top_primary_reason_family,
    s.top_primary_reason_code,
    s.top_primary_reason_population_share,

    s.top_non_approval_primary_reason_family,
    s.top_non_approval_primary_reason_code,
    s.top_non_approval_reason_population_share,

    s.top_policy_stop_primary_reason_family,
    s.top_policy_stop_primary_reason_code,
    s.top_policy_stop_reason_population_share,

    /***********************************************************************************************
    Largest reason-code movement versus baseline.

    These fields are NULL when the strategy is the baseline or when no baseline exists.
    ***********************************************************************************************/
    td.top_reason_code_delta_driver_family,
    td.top_reason_code_delta_driver_code,
    td.top_reason_code_delta_driver_baseline_share,
    td.top_reason_code_delta_driver_strategy_share,
    td.top_reason_code_delta_population_share

FROM tmp_m2_strategy_frontier_summary s

LEFT JOIN baseline_reference b
    ON b.strategy_set_name = s.strategy_set_name
   AND b.module1_scenario_set_name = s.module1_scenario_set_name
   AND b.module1_scenario_name = s.module1_scenario_name
   AND b.population_id = s.population_id

LEFT JOIN top_reason_code_delta_driver td
    ON td.strategy_set_name = s.strategy_set_name
   AND td.strategy_name = s.strategy_name
   AND td.strategy_version = s.strategy_version
   AND td.module1_scenario_set_name = s.module1_scenario_set_name
   AND td.module1_scenario_name = s.module1_scenario_name
   AND td.population_id = s.population_id
   AND td.reason_code_delta_rank = 1;


/*-----------------------------------------------------------------------------------------------
15.3A Baseline-relative frontier delta review output.

Business purpose:
    Display baseline-relative strategy movement where a baseline reference exists.

What to look for:
    baseline_available_flag = TRUE:
        baseline-relative deltas are interpretable.

    baseline_available_flag = FALSE:
        baseline-relative deltas are unavailable.

Review triggers:
    NULL baseline-relative values mean no matching BASELINE_STRATEGY was archived for that scenario /
    population / strategy set.

    They should not be interpreted as zero movement.

SQL mechanics:
    This SELECT reads the materialized baseline-delta temporary table.

Documentation use:
    Use this table to explain how each archived strategy point moved relative to baseline.
-----------------------------------------------------------------------------------------------*/

SELECT
    *
FROM tmp_m2_strategy_frontier_baseline_deltas
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 15.4 — STRATEGY EFFICIENCY METRICS
****************************************************************************************************

PURPOSE:
    Convert frontier summary metrics into executive-readable synthetic efficiency indicators.

BUSINESS PURPOSE:
    Support strategy posture comparison by translating raw frontier metrics into compact synthetic
    access / exposure / approved Expected Loss efficiency signals.

    Section 15.4 answers:

        "How much simulated approved exposure, simulated offer access, and portfolio coverage is
         produced relative to approved Expected Loss?"

SQL PURPOSE:
    1. Drop any prior tmp_m2_strategy_frontier_efficiency.
    2. Materialize tmp_m2_strategy_frontier_efficiency.
    3. Calculate frontier_approved_expected_loss_rate.
    4. Calculate approved_amount_per_approved_expected_loss_dollar.
    5. Calculate offer_rate_per_approved_expected_loss_rate_unit.
    6. Calculate applications_per_million_approved_expected_loss.
    7. Carry positive_offer_access_rate.
    8. Carry manual_review_burden_rate.
    9. Carry no_offer_outcome_rate.
    10. Assign frontier_efficiency_metric_status.

BUSINESS INTERPRETATION:
    These metrics help compare strategy posture.

    Examples:
        How much approved exposure is produced per unit of approved Expected Loss?
        How much simulated offer-exposure rate is produced per unit of approved Expected Loss rate?
        How many applications are covered per million dollars of approved Expected Loss?
        What is the approved Expected Loss rate on simulated approved exposure?
        How much manual-review burden does the strategy create?
        What share of the population receives simulated positive offer exposure?

WHAT TO LOOK FOR:
    approved_amount_per_approved_expected_loss_dollar:
        Higher values may indicate more simulated approved exposure per unit of approved Expected
        Loss.

    frontier_approved_expected_loss_rate:
        Lower values may indicate stronger synthetic approved Expected Loss discipline.

    positive_offer_access_rate:
        Higher values indicate more simulated positive offer exposure.

    manual_review_burden_rate:
        Higher values indicate more unresolved outcomes.

    no_offer_outcome_rate:
        Higher values indicate more final DECLINE outcomes.

REVIEW TRIGGERS:
    NO_SIMULATED_OFFER_EXPOSURE_FOR_EFFICIENCY_REVIEW:
        Approved-exposure efficiency metrics are not meaningful because no approved exposure exists.

    APPROVED_EXPECTED_LOSS_NOT_AVAILABLE_FOR_EFFICIENCY_REVIEW:
        Approved Expected Loss metrics are unavailable.

    Very high approved Expected Loss rate:
        Review product, score band, LGD, approved amount, offered-population risk, and strategy
        posture.

IMPORTANT:
    These are comparative synthetic strategy metrics.

    They are not:
        profitability,
        capital,
        pricing,
        funding cost,
        margin,
        account performance,
        or production risk-adjusted return metrics.

    Those are intentionally deferred to future Module 3.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    Division by NULLIF(..., 0):
        Prevents divide-by-zero.

    Carry-forward SELECT:
        d.* preserves baseline-delta fields while adding efficiency fields.

    CASE:
        Labels whether efficiency metrics are available for interpretation.

BOUNDARY:
    Efficiency metrics are calculated from already archived outputs.

    Section 15.4 does not recalculate approved amount.
    Section 15.4 does not recalculate approved Expected Loss.
    Section 15.4 does not calculate revenue.
    Section 15.4 does not calculate profitability.
    Section 15.4 does not implement Module 3 economics.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_efficiency;

CREATE TEMP TABLE tmp_m2_strategy_frontier_efficiency
ON COMMIT PRESERVE ROWS
AS
SELECT
    /***********************************************************************************************
    Preserve all baseline-relative frontier fields.

    This keeps Section 15.4 additive:
        it enriches the baseline-delta table with synthetic efficiency metrics rather than replacing
        or recalculating earlier frontier fields.
    ***********************************************************************************************/
    d.*,

    /***********************************************************************************************
    Approved Expected Loss rate.

    Formula:
        total approved Expected Loss / total approved amount

    Boundary:
        Synthetic strategy metric, not a production loss-rate forecast.
    ***********************************************************************************************/
    d.total_approved_expected_loss_amount
        / NULLIF(d.total_approved_amount, 0)
        AS frontier_approved_expected_loss_rate,

    /***********************************************************************************************
    Approved amount per approved Expected Loss dollar.

    Formula:
        total approved amount / total approved Expected Loss

    Interpretation:
        Higher values can indicate more simulated approved exposure per unit of approved Expected
        Loss.

    Boundary:
        This is not profitability or risk-adjusted return.
    ***********************************************************************************************/
    d.total_approved_amount
        / NULLIF(d.total_approved_expected_loss_amount, 0)
        AS approved_amount_per_approved_expected_loss_dollar,

    /***********************************************************************************************
    Offer rate per approved Expected Loss rate unit.

    Formula:
        simulated offer-exposure rate / approved Expected Loss rate

    Interpretation:
        A synthetic access-efficiency proxy.

    Boundary:
        This is not a pricing, profit, or capital metric.
    ***********************************************************************************************/
    d.simulated_offer_exposure_rate
        / NULLIF(d.approved_expected_loss_rate, 0)
        AS offer_rate_per_approved_expected_loss_rate_unit,

    /***********************************************************************************************
    Applications per million approved Expected Loss.

    Formula:
        applications / (total approved Expected Loss / 1,000,000)

    Interpretation:
        Scaled synthetic coverage metric.

    Review:
        Useful for comparing frontier points, but not a production profitability metric.
    ***********************************************************************************************/
    d.applications::NUMERIC
        / NULLIF(d.total_approved_expected_loss_amount / 1000000.0, 0)
        AS applications_per_million_approved_expected_loss,

    /***********************************************************************************************
    Executive-readable alias fields.
    ***********************************************************************************************/
    d.simulated_offer_exposure_rate AS positive_offer_access_rate,

    d.manual_review_rate AS manual_review_burden_rate,

    d.decline_rate AS no_offer_outcome_rate,

    /***********************************************************************************************
    Efficiency metric availability status.

    SQL mechanics:
        CASE prevents reviewers from over-interpreting efficiency metrics when approved exposure or
        approved Expected Loss is unavailable.

    Interpretation:
        FRONTIER_EFFICIENCY_METRICS_AVAILABLE means the synthetic efficiency fields can be reviewed.
    ***********************************************************************************************/
    CASE
        WHEN d.total_approved_amount IS NULL
          OR d.total_approved_amount = 0
            THEN 'NO_SIMULATED_OFFER_EXPOSURE_FOR_EFFICIENCY_REVIEW'

        WHEN d.total_approved_expected_loss_amount IS NULL
            THEN 'APPROVED_EXPECTED_LOSS_NOT_AVAILABLE_FOR_EFFICIENCY_REVIEW'

        ELSE 'FRONTIER_EFFICIENCY_METRICS_AVAILABLE'
    END AS frontier_efficiency_metric_status

FROM tmp_m2_strategy_frontier_baseline_deltas d;


/*-----------------------------------------------------------------------------------------------
15.4A Strategy efficiency metrics review output.

Business purpose:
    Display the synthetic efficiency metrics most useful for executive interpretation.

What to look for:
    frontier_efficiency_metric_status:
        confirms whether metrics are interpretable.

    approved_amount_per_approved_expected_loss_dollar:
        synthetic approved exposure per approved Expected Loss dollar.

    applications_per_million_approved_expected_loss:
        scaled coverage metric.

    positive_offer_access_rate:
        simulated positive offer-exposure rate.

    manual_review_burden_rate:
        unresolved outcome burden.

    top reason-code fields:
        explanation layer for why the efficiency posture exists.

Review triggers:
    If efficiency status is not FRONTIER_EFFICIENCY_METRICS_AVAILABLE, do not overstate synthetic
    efficiency metrics.

    If approved Expected Loss rate is high, use product, score, risk, LGD, and reason-code diagnostics
    before drafting narrative.

SQL mechanics:
    This query reads tmp_m2_strategy_frontier_efficiency only.

Documentation use:
    This output can support executive story framing, but it should not be described as profitability,
    capital efficiency, or production risk-adjusted return.
-----------------------------------------------------------------------------------------------*/

SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    applications,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,
    counteroffer_share_of_offers,

    total_approved_amount,
    total_approved_expected_loss_amount,

    frontier_approved_expected_loss_rate,
    approved_amount_per_approved_expected_loss_dollar,
    offer_rate_per_approved_expected_loss_rate_unit,
    applications_per_million_approved_expected_loss,

    positive_offer_access_rate,
    manual_review_burden_rate,
    no_offer_outcome_rate,

    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_approved_payment_to_income_ratio_offer_rows,

    top_primary_reason_family,
    top_primary_reason_code,

    top_non_approval_primary_reason_family,
    top_non_approval_primary_reason_code,
    top_non_approval_reason_population_share,

    top_policy_stop_primary_reason_family,
    top_policy_stop_primary_reason_code,
    top_policy_stop_reason_population_share,

    top_reason_code_delta_driver_family,
    top_reason_code_delta_driver_code,
    top_reason_code_delta_driver_baseline_share,
    top_reason_code_delta_driver_strategy_share,
    top_reason_code_delta_population_share,

    frontier_efficiency_metric_status

FROM tmp_m2_strategy_frontier_efficiency

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/***************************************************************************************************
END OF SECTION 15.4 — STRATEGY EFFICIENCY METRICS

If execution reaches this point:
    1. Archive frontier scope has been reviewed.
    2. Optional campaign registry mapping has been prepared for frontier enrichment.
    3. Archived frontier inventory has been materialized.
    4. One-row-per-archived-slice frontier summary metrics have been materialized.
    5. Top primary, non-approval, and policy-stop reason-code fields have been added.
    6. Baseline-relative deltas have been calculated where BASELINE_STRATEGY exists.
    7. Reason-code movement versus baseline has been calculated only where a baseline exists.
    8. Synthetic efficiency metrics have been calculated.
    9. Efficiency metric availability has been labeled.
    10. Section 15 remains archive-backed and read-only.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No latest-run rows have been modified.
No campaign registry rows have been inserted.
No campaign registry rows have been deleted.
No campaign registry rows have been updated.
No decision outcomes have been recalculated.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No simulated reason codes have been reassigned.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 15.5 should classify each frontier point into an executive-readable diagnostic posture
    label using the summary, baseline-delta, reason-code, and efficiency fields created above.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01011 -->


---

<a id="c038-m01012"></a>

### C038-M01012

**Andrew** · 2026-05-10T10:21:53.096000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01012 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 15.5-15.8 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M01012 -->


**Attachments in export:** `Pasted text(160).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_55.md) · [Next](Part_57.md)
