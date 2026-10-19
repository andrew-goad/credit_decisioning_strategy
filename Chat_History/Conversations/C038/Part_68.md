# Module 2 Decision Simulator Build

## Part 68

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_67.md) · [Next](Part_69.md)

<a id="c038-m01346"></a>

### C038-M01346

**ChatGPT** · 2026-05-11T21:18:47.037617-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01346 -->
I consolidated the full campaign QA pack into one **Section 17**. The first 15 subsections add the campaign checks that were not represented in your current Section 17; the former 17.1–17.5 checks are retained at the end as **17.16–17.20**. This keeps one section, avoids duplicating the former 16–20 checks, and makes Section 17 the single post-campaign acceptance/export layer. fileciteturn184file0

```sql
/***************************************************************************************************
SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the final post-campaign control tower after all planned Module 2 campaign runs have been
    completed, archived, validated, compared, summarized, and captured into persistent evidence.

    Section 17 answers:

        "Is the completed Module 2 campaign structurally complete, registry-aligned,
         evidence-complete, convention-clean, comparison-ready, parameter-traceable,
         and analytically ready for final interpretation?"

WHY THIS SECTION EXISTS:
    Earlier sections execute and capture the strategy campaign:

        Section 11:
            materializes the latest-run strategy output.

        Section 12:
            persists completed latest-run output into the governed strategy archive.

        Section 13:
            provides archive-backed matched baseline / challenger comparison.

        Section 14:
            validates latest-run behavior and creates validation evidence.

        Section 15:
            summarizes archive-backed strategy frontier tradeoffs.

        Section 16:
            persists executive evidence, validation evidence, parameter snapshots,
            and product × score segment evidence.

    Section 17 is different.

    Section 17 does not create new strategy output.
    Section 17 reviews the completed campaign from persistent archive, registry, comparison,
    validation, frontier, and evidence objects.

WHAT SECTION 17 INCLUDES:
    17.1  Archive campaign inventory.
    17.2  Archive slice detail.
    17.3  Archive grain duplicate check.
    17.4  Campaign registry to archive reconciliation.
    17.5  Registry runs missing or mismatched in archive.
    17.6  Archive slices without active campaign registry row.
    17.7  Section 16 evidence coverage summary.
    17.8  Section 16 evidence coverage detail by run.
    17.9  Full-archive final-output convention checks.
    17.10 Validation status summary by campaign run.
    17.11 Validation REVIEW / NOT_APPLICABLE concentration.
    17.12 Comparison registry readiness.
    17.13 Matched comparison source-field consistency.
    17.14 Executive evidence campaign summary.
    17.15 Baseline × challenger delta summary.
    17.16 Product guardrail strategy effect check.
    17.17 Counteroffer-first strategy effect check.
    17.18 Parameter snapshot profile audit.
    17.19 Product guardrail policy exact-value audit.
    17.20 Final Module 2 campaign acceptance rollup.

WHY THE FORMER 16–20 CAMPAIGN QUERIES ARE AT THE END:
    The prior Section 17 already represented the former campaign queries 16–20:

        product guardrail strategy effect check,
        counteroffer-first strategy effect check,
        parameter snapshot profile audit,
        product guardrail policy exact-value audit,
        and final campaign acceptance rollup.

    This updated Section 17 adds the missing campaign checks first and keeps those strategy-effect
    and acceptance checks as the closing subsections.

HOW TO USE THIS SECTION:
    Run Section 17 after:
        1. all planned Module 2 campaign runs are complete;
        2. Section 15 has been rerun from the completed archive;
        3. Section 15-derived frontier fields have been refreshed into
           credit_decisioning_sim.strategy_run_evidence_summary, if reruns changed the archive;
        4. Section 16 evidence rows exist for all accepted campaign runs.

EXPECTED CURRENT CAMPAIGN SHAPE:
    active campaign registry runs:
        36

    active comparison groups:
        17

    archived strategy / scenario / population slices:
        36

    archived applicant rows:
        1,800,000

    rows per archived campaign slice:
        50,000

    expected product guardrail policy audit rows:
        5 product-guardrail runs × 2 audited products = 10 rows

CREDIT RISK CONCEPTS TAUGHT IN THIS SECTION:
    Archive completeness:
        Confirms the campaign has a complete governed history layer.

    Registry reconciliation:
        Confirms documentation run IDs reconcile to technical archive keys.

    Matched comparison:
        Confirms baseline and challenger strategy slices use the same Module 1 population and source
        fields so strategy deltas are not contaminated by upstream population drift.

    Output conventions:
        Confirms APPROVE, COUNTEROFFER, MANUAL_REVIEW, and DECLINE rows obey final exposure,
        affordability, Expected Loss, simulated offer-exposure, and reason-code rules.

    Validation status interpretation:
        PASS means the expectation was satisfied.
        REVIEW means the item needs interpretation before documentation.
        NOT_APPLICABLE means the test could not be evaluated in that run context.

    Product guardrails:
        Product-specific tightening should affect intended products and not unintentionally change
        unaffected products.

    Counteroffer-first treatment:
        A counteroffer-first strategy should increase reduced-exposure treatment and generally reduce
        approved PTI / approved Expected Loss on counteroffer rows.

    Parameter snapshots:
        Strategy results are not fully governed unless the parameter payload that produced them is
        preserved and audit-readable.

INTERPRETATION BOUNDARIES:
    Section 17 validates campaign evidence quality and strategy-effect directionality.

    Section 17 does not declare production approval.
    Section 17 does not validate real applicant treatment.
    Section 17 does not create customer notices.
    Section 17 does not create adverse-action reasons.
    Section 17 does not calculate revenue, margin, funding cost, capital, profitability, or Module 3
    economics.
    Section 17 does not replace the written Validation Summary.

READ-ONLY BOUNDARY:
    Section 17 does not insert rows.
    Section 17 does not delete rows.
    Section 17 does not update rows.
    Section 17 does not modify the latest-run table.
    Section 17 does not modify the archive.
    Section 17 does not modify evidence tables.
    Section 17 does not modify campaign registry tables.
    Section 17 does not recalculate decisions.
    Section 17 does not recalculate approved exposure.
    Section 17 does not recalculate approved Expected Loss.
    Section 17 does not reassign simulated reason codes.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CTE:
        Breaks campaign acceptance into readable named layers.

    GROUP BY:
        Converts applicant-level archive rows into run-level, product-level, validation-level,
        comparison-level, and campaign-level evidence.

    LEFT JOIN:
        Preserves missing-match diagnostics instead of hiding missing archive or evidence rows.

    JOIN:
        Enforces matched baseline / challenger comparison at the intended technical key.

    CROSS JOIN LATERAL:
        Expands JSONB product-policy snapshots into row-level product-policy audit records.

    COUNT(*) FILTER:
        Counts specific pass / review / violation conditions in one aggregate query.

    IS DISTINCT FROM:
        Performs NULL-safe comparisons for source-field consistency and parameter audit checks.

    CASE:
        Converts diagnostic counts into readable campaign acceptance statuses.

***************************************************************************************************/



/***************************************************************************************************
SECTION 17.1 — MODULE 2 ARCHIVE CAMPAIGN INVENTORY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the completed Module 2 campaign archive contains the expected number of completed
    strategy / scenario / population slices and total applicant rows.

SQL PURPOSE:
    Summarize credit_decisioning_sim.strategy_decisions_archive at the completed-run archive grain:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

EXPECTED RESULT:
    archived_strategy_scenario_slices = 36
    total_archived_rows = 1,800,000
    slices_not_50000_rows = 0
    slices_with_duplicate_application_ids = 0
    archive_campaign_inventory_status = MODULE_2_ARCHIVE_INVENTORY_READY

INTERPRETATION:
    This is the first campaign-level acceptance check.

    If this fails, do not interpret strategy effects yet. First resolve missing, duplicate, or
    incorrectly sized archive slices.

***************************************************************************************************/

WITH archive_inventory AS (
    SELECT
        /*******************************************************************************************
        Archive replacement / rerun key.

        Each group should represent one completed campaign run slice.
        *******************************************************************************************/
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        /*******************************************************************************************
        Row-count evidence.

        archived_rows should equal 50,000 for every planned campaign slice.
        distinct_application_id_count should also equal 50,000.
        *******************************************************************************************/
        COUNT(*) AS archived_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        /*******************************************************************************************
        Archive persistence timestamps.

        These are audit metadata only.
        They should not be used as comparison keys.
        *******************************************************************************************/
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
)

SELECT
    COUNT(*) AS archived_strategy_scenario_slices,
    SUM(archived_rows) AS total_archived_rows,

    COUNT(*) FILTER (
        WHERE archived_rows <> 50000
    ) AS slices_not_50000_rows,

    COUNT(*) FILTER (
        WHERE archived_rows <> distinct_application_id_count
    ) AS slices_with_duplicate_application_ids,

    MIN(first_archive_inserted_ts) AS first_campaign_archive_inserted_ts,
    MAX(last_archive_inserted_ts) AS last_campaign_archive_inserted_ts,

    CASE
        WHEN COUNT(*) = 36
         AND SUM(archived_rows) = 1800000
         AND COUNT(*) FILTER (WHERE archived_rows <> 50000) = 0
         AND COUNT(*) FILTER (WHERE archived_rows <> distinct_application_id_count) = 0
            THEN 'MODULE_2_ARCHIVE_INVENTORY_READY'

        ELSE 'REVIEW_MODULE_2_ARCHIVE_INVENTORY'
    END AS archive_campaign_inventory_status

FROM archive_inventory;



/***************************************************************************************************
SECTION 17.2 — MODULE 2 ARCHIVE SLICE DETAIL
****************************************************************************************************

BUSINESS PURPOSE:
    Display every archived strategy / Module 1 scenario / population slice so reviewers can visually
    confirm the completed campaign inventory.

SQL PURPOSE:
    Produce one row per archived campaign slice with row count, distinct application count, run IDs,
    and archive timestamps.

EXPECTED RESULT:
    36 rows.
    Each row should show:
        archived_rows = 50,000
        distinct_application_id_count = 50,000

WHAT TO LOOK FOR:
    Missing run:
        A planned campaign run did not archive.

    More than 36 rows:
        An extra strategy / scenario slice exists outside the intended campaign.

    archived_rows <> 50,000:
        A run did not preserve the expected Module 1 population size.

    min_strategy_run_id <> max_strategy_run_id:
        The archive slice may contain mixed run IDs.

***************************************************************************************************/

SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS archived_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    /***********************************************************************************************
    Strategy run ID range.

    These are audit metadata, not archive grain. They are shown to catch accidental mixed-run slices.
    ***********************************************************************************************/
    MIN(strategy_run_id) AS min_strategy_run_id,
    MAX(strategy_run_id) AS max_strategy_run_id,

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
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 17.3 — MODULE 2 ARCHIVE GRAIN DUPLICATE CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the archive is unique at the official row-level archive grain.

OFFICIAL ARCHIVE GRAIN:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id

EXPECTED RESULT:
    duplicate_archive_grain_count = 0

INTERPRETATION:
    A non-zero value indicates duplicate applicant rows inside at least one archived strategy slice.
    Do not interpret matched comparisons until this is resolved.

***************************************************************************************************/

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
) duplicate_archive_rows;



/***************************************************************************************************
SECTION 17.4 — CAMPAIGN REGISTRY TO ARCHIVE RECONCILIATION
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that every active campaign registry run has a corresponding archived strategy slice.

WHY THIS MATTERS:
    The campaign registry provides the human-readable run IDs and evidence-story IDs.

    The archive provides the row-level strategy output history.

    The two must reconcile before final documentation.

EXPECTED RESULT:
    registry_run_count = 36
    registry_runs_with_archive_rows = 36
    registry_runs_missing_archive_rows = 0
    registry_runs_not_50000_rows = 0
    registry_runs_with_duplicate_application_ids = 0
    campaign_registry_archive_status = CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE

***************************************************************************************************/

WITH registry_runs AS (
    SELECT
        /*******************************************************************************************
        Campaign registry identifiers.

        These fields are documentation and evidence-linkage metadata.
        *******************************************************************************************/
        module1_run_id,
        module2_run_id,
        run_sequence_number,
        showcase_id,
        showcase_name,
        comparison_group_id,
        validation_evidence_group_id,

        /*******************************************************************************************
        Technical archive key fields.

        These fields must join to the archive slice.
        *******************************************************************************************/
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_set_name,
        strategy_name,
        strategy_version

    FROM credit_decisioning_sim.strategy_run_campaign_registry

    WHERE registry_active_flag IS TRUE
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

registry_archive_join AS (
    SELECT
        r.*,

        /*******************************************************************************************
        COALESCE converts missing archive slices into zero counts so missing rows remain visible.
        *******************************************************************************************/
        COALESCE(a.archived_rows, 0) AS archived_rows,
        COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count

    FROM registry_runs r

    LEFT JOIN archive_counts a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id
)

SELECT
    COUNT(*) AS registry_run_count,

    COUNT(*) FILTER (
        WHERE archived_rows > 0
    ) AS registry_runs_with_archive_rows,

    COUNT(*) FILTER (
        WHERE archived_rows = 0
    ) AS registry_runs_missing_archive_rows,

    COUNT(*) FILTER (
        WHERE archived_rows <> 50000
    ) AS registry_runs_not_50000_rows,

    COUNT(*) FILTER (
        WHERE archived_rows <> distinct_application_id_count
    ) AS registry_runs_with_duplicate_application_ids,

    CASE
        WHEN COUNT(*) = 36
         AND COUNT(*) FILTER (WHERE archived_rows > 0) = 36
         AND COUNT(*) FILTER (WHERE archived_rows = 0) = 0
         AND COUNT(*) FILTER (WHERE archived_rows <> 50000) = 0
         AND COUNT(*) FILTER (WHERE archived_rows <> distinct_application_id_count) = 0
            THEN 'CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE'

        ELSE 'REVIEW_CAMPAIGN_REGISTRY_ARCHIVE_RECONCILIATION'
    END AS campaign_registry_archive_status

FROM registry_archive_join;



/***************************************************************************************************
SECTION 17.5 — REGISTRY RUNS MISSING OR MISMATCHED IN ARCHIVE
****************************************************************************************************

BUSINESS PURPOSE:
    Provide run-level detail only when the registry-to-archive reconciliation is incomplete.

EXPECTED RESULT:
    Zero rows.

HOW TO USE:
    If Section 17.4 fails, this query shows exactly which module2_run_id is missing from archive or
    has the wrong row count / duplicate application count.

***************************************************************************************************/

WITH registry_runs AS (
    SELECT *
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
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
)

SELECT
    r.module1_run_id,
    r.module2_run_id,
    r.run_sequence_number,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version,

    COALESCE(a.archived_rows, 0) AS archived_rows,
    COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count

FROM registry_runs r

LEFT JOIN archive_counts a
    ON a.strategy_set_name = r.strategy_set_name
   AND a.strategy_name = r.strategy_name
   AND a.strategy_version = r.strategy_version
   AND a.module1_scenario_set_name = r.module1_scenario_set_name
   AND a.module1_scenario_name = r.module1_scenario_name
   AND a.population_id = r.population_id

WHERE COALESCE(a.archived_rows, 0) <> 50000
   OR COALESCE(a.archived_rows, 0) <> COALESCE(a.distinct_application_id_count, 0)

ORDER BY r.run_sequence_number;



/***************************************************************************************************
SECTION 17.6 — ARCHIVE SLICES WITHOUT ACTIVE CAMPAIGN REGISTRY ROW
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the archive does not contain orphan campaign slices outside the active campaign
    registry.

EXPECTED RESULT:
    Zero rows.

INTERPRETATION:
    Rows returned here are archived strategy slices that exist but do not map to an active campaign
    registry run.

    This may indicate:
        an ad hoc development run was archived,
        a registry row was not seeded,
        a scenario / strategy name mismatch occurred,
        or a stale archive slice remains from prior testing.

***************************************************************************************************/

WITH archive_slices AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS archived_rows
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
    a.*
FROM archive_slices a

LEFT JOIN credit_decisioning_sim.strategy_run_campaign_registry r
    ON r.strategy_set_name = a.strategy_set_name
   AND r.strategy_name = a.strategy_name
   AND r.strategy_version = a.strategy_version
   AND r.module1_scenario_set_name = a.module1_scenario_set_name
   AND r.module1_scenario_name = a.module1_scenario_name
   AND r.population_id = a.population_id
   AND r.registry_active_flag IS TRUE

WHERE r.module2_run_id IS NULL

ORDER BY
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.strategy_name;



/***************************************************************************************************
SECTION 17.7 — SECTION 16 EVIDENCE COVERAGE SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that persistent Section 16 evidence exists for every completed campaign run.

EVIDENCE TABLES CHECKED:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

EXPECTED RESULT:
    registry_run_count = 36
    runs_with_one_executive_evidence_row = 36
    runs_with_one_parameter_snapshot_row = 36
    runs_with_validation_evidence_rows = 36
    runs_with_segment_evidence_rows = 36
    evidence_coverage_issue_count = 0
    evidence_campaign_status = SECTION_16_EVIDENCE_COVERAGE_READY

***************************************************************************************************/

WITH registry_runs AS (
    SELECT
        module2_run_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
),

executive_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS executive_rows
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
        COUNT(*) AS validation_rows
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
        COUNT(*) AS segment_rows
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

joined AS (
    SELECT
        r.module2_run_id,
        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(p.parameter_rows, 0) AS parameter_rows,
        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(s.segment_rows, 0) AS segment_rows

    FROM registry_runs r

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
)

SELECT
    COUNT(*) AS registry_run_count,

    COUNT(*) FILTER (
        WHERE executive_rows = 1
    ) AS runs_with_one_executive_evidence_row,

    COUNT(*) FILTER (
        WHERE parameter_rows = 1
    ) AS runs_with_one_parameter_snapshot_row,

    COUNT(*) FILTER (
        WHERE validation_rows > 0
    ) AS runs_with_validation_evidence_rows,

    COUNT(*) FILTER (
        WHERE segment_rows > 0
    ) AS runs_with_segment_evidence_rows,

    COUNT(*) FILTER (
        WHERE executive_rows <> 1
           OR parameter_rows <> 1
           OR validation_rows = 0
           OR segment_rows = 0
    ) AS evidence_coverage_issue_count,

    CASE
        WHEN COUNT(*) = 36
         AND COUNT(*) FILTER (WHERE executive_rows = 1) = 36
         AND COUNT(*) FILTER (WHERE parameter_rows = 1) = 36
         AND COUNT(*) FILTER (WHERE validation_rows > 0) = 36
         AND COUNT(*) FILTER (WHERE segment_rows > 0) = 36
            THEN 'SECTION_16_EVIDENCE_COVERAGE_READY'

        ELSE 'REVIEW_SECTION_16_EVIDENCE_COVERAGE'
    END AS evidence_campaign_status

FROM joined;



/***************************************************************************************************
SECTION 17.8 — SECTION 16 EVIDENCE COVERAGE DETAIL BY RUN
****************************************************************************************************

BUSINESS PURPOSE:
    Display evidence counts for each individual campaign run.

EXPECTED RESULT:
    36 rows.

    Each row should generally show:
        executive_rows = 1
        parameter_rows = 1
        validation_rows > 0
        segment_rows = 25

WHY SEGMENT_ROWS SHOULD BE 25:
    Current Module 2 campaign uses:

        5 products × 5 score bands = 25 product × score evidence rows per run.

***************************************************************************************************/

WITH registry_runs AS (
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

executive_evidence AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        COUNT(*) AS executive_rows
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
        COUNT(*) AS validation_rows
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
        COUNT(*) AS segment_rows
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
)

SELECT
    r.module2_run_id,
    r.run_sequence_number,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    r.strategy_name,
    r.strategy_version,

    COALESCE(e.executive_rows, 0) AS executive_rows,
    COALESCE(p.parameter_rows, 0) AS parameter_rows,
    COALESCE(v.validation_rows, 0) AS validation_rows,
    COALESCE(s.segment_rows, 0) AS segment_rows,

    CASE
        WHEN COALESCE(e.executive_rows, 0) = 1
         AND COALESCE(p.parameter_rows, 0) = 1
         AND COALESCE(v.validation_rows, 0) > 0
         AND COALESCE(s.segment_rows, 0) > 0
            THEN 'EVIDENCE_CAPTURE_READY'

        ELSE 'EVIDENCE_CAPTURE_REVIEW_REQUIRED'
    END AS evidence_capture_status

FROM registry_runs r

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

ORDER BY r.run_sequence_number;



/***************************************************************************************************
SECTION 17.9 — FULL ARCHIVE FINAL OUTPUT CONVENTION CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Apply final-output convention checks across the full Module 2 campaign archive.

WHY THIS MATTERS:
    Section 14 validates the latest-run output.

    Section 17.9 validates the entire archived campaign.

EXPECTED RESULT:
    All violation counts should equal zero.

CONVENTIONS CHECKED:
    exactly one final decision flag per row;
    simulated_offer_exposure_flag reconciles to APPROVE / COUNTEROFFER;
    APPROVE preserves requested exposure;
    COUNTEROFFER has positive reduced exposure;
    MANUAL_REVIEW remains unresolved;
    DECLINE follows zero-exposure convention;
    approved PTI and approved Expected Loss conventions hold;
    reason-code fields are complete and outcome-family aligned.

***************************************************************************************************/

SELECT
    COUNT(*) AS archived_rows,

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
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_payment_to_income_ratio IS NULL
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

FROM credit_decisioning_sim.strategy_decisions_archive;



/***************************************************************************************************
SECTION 17.10 — VALIDATION STATUS SUMMARY BY CAMPAIGN RUN
****************************************************************************************************

BUSINESS PURPOSE:
    Summarize persistent validation evidence by campaign run.

VALIDATION STATUS INTERPRETATION:
    PASS:
        The validation expectation was satisfied.

    REVIEW:
        The pattern should be interpreted before final documentation.
        REVIEW is not automatic invalidation.

    NOT_APPLICABLE:
        The validation item could not be evaluated in that run context.

EXPECTED RESULT:
    36 rows.
    Each row should have validation_evidence_rows populated.
    REVIEW / NOT_APPLICABLE rows should be interpreted before final Validation Summary drafting.

***************************************************************************************************/

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

    strategy_name,
    strategy_version,

    COUNT(*) AS validation_evidence_rows,

    COUNT(*) FILTER (
        WHERE validation_status = 'PASS'
    ) AS pass_count,

    COUNT(*) FILTER (
        WHERE validation_status = 'REVIEW'
    ) AS review_count,

    COUNT(*) FILTER (
        WHERE validation_status = 'NOT_APPLICABLE'
    ) AS not_applicable_count,

    /***********************************************************************************************
    Documentation helper.

    This field is intentionally compact. It identifies the validation items that require narrative
    interpretation without forcing reviewers to scan all validation rows.
    ***********************************************************************************************/
    STRING_AGG(
        validation_area || ': ' || validation_test_name || ' [' || validation_status || ']',
        ' | '
        ORDER BY validation_area, validation_test_name
    ) FILTER (
        WHERE validation_status IN ('REVIEW', 'NOT_APPLICABLE')
    ) AS review_or_not_applicable_items

FROM credit_decisioning_sim.strategy_run_validation_evidence

GROUP BY
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
    strategy_name,
    strategy_version

ORDER BY run_sequence_number;



/***************************************************************************************************
SECTION 17.11 — VALIDATION REVIEW CONCENTRATION
****************************************************************************************************

BUSINESS PURPOSE:
    Identify validation checks that most frequently produced REVIEW or NOT_APPLICABLE statuses.

WHY THIS MATTERS:
    A campaign can be structurally clean while still requiring interpretation around recurring
    diagnostic patterns.

EXPECTED INTERPRETATION:
    Common REVIEW items are documentation prompts, not automatic failures.

    Use this output to decide which themes belong in the final validation narrative:
        counteroffer concentration;
        mixed-signal / borderline profile concentration;
        manual-review burden;
        product-level skew;
        comparison readiness;
        source-field consistency;
        convention review items.

***************************************************************************************************/

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,

    COUNT(*) AS run_count,

    STRING_AGG(
        module2_run_id,
        ', '
        ORDER BY run_sequence_number
    ) AS affected_module2_run_ids

FROM credit_decisioning_sim.strategy_run_validation_evidence

WHERE validation_status IN ('REVIEW', 'NOT_APPLICABLE')

GROUP BY
    validation_area,
    validation_test_name,
    validation_category,
    validation_status

ORDER BY
    validation_status,
    run_count DESC,
    validation_area,
    validation_test_name;



/***************************************************************************************************
SECTION 17.12 — COMPARISON REGISTRY READINESS
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that every planned baseline / challenger comparison has both strategy slices archived.

EXPECTED RESULT:
    17 rows.
    Each row should show:
        baseline_archived_rows = 50,000
        challenger_archived_rows = 50,000
        comparison_readiness_status = COMPARISON_READY

WHY THIS MATTERS:
    Comparison claims should not be made unless both sides of the comparison are present and complete
    in the archive.

***************************************************************************************************/

WITH comparisons AS (
    SELECT *
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
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
)

SELECT
    c.comparison_group_id,
    c.comparison_set_name,
    c.baseline_module2_run_id,
    c.challenger_module2_run_id,

    c.module1_scenario_set_name,
    c.module1_scenario_name,
    c.population_id,

    c.baseline_strategy_name,
    COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
    COALESCE(b.distinct_application_id_count, 0) AS baseline_distinct_application_id_count,

    c.challenger_strategy_name,
    COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,
    COALESCE(ch.distinct_application_id_count, 0) AS challenger_distinct_application_id_count,

    CASE
        WHEN COALESCE(b.archived_rows, 0) = 50000
         AND COALESCE(ch.archived_rows, 0) = 50000
         AND COALESCE(b.archived_rows, 0) = COALESCE(b.distinct_application_id_count, 0)
         AND COALESCE(ch.archived_rows, 0) = COALESCE(ch.distinct_application_id_count, 0)
            THEN 'COMPARISON_READY'

        ELSE 'COMPARISON_REVIEW_REQUIRED'
    END AS comparison_readiness_status

FROM comparisons c

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

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.13 — MATCHED COMPARISON SOURCE-FIELD CONSISTENCY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that each planned baseline / challenger comparison uses the same immutable Module 1
    source fields at the application level.

WHY THIS MATTERS:
    A valid Module 2 strategy comparison should isolate downstream strategy effects.

    If baseline and challenger rows differ in Module 1 source fields, the observed deltas may reflect
    source-selection drift rather than strategy movement.

EXPECTED RESULT:
    17 rows.
    For each row:
        matched_application_count = 50,000
        source_field_mismatch_count = 0
        source_consistency_status = SOURCE_FIELDS_MATCH

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

SQL TEACHING POINT:
    IS DISTINCT FROM is used for NULL-safe comparisons.

***************************************************************************************************/

WITH comparisons AS (
    SELECT *
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
),

matched_rows AS (
    SELECT
        c.comparison_group_id,
        c.comparison_set_name,
        c.baseline_module2_run_id,
        c.challenger_module2_run_id,

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

    FROM comparisons c

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
)

SELECT
    comparison_group_id,
    comparison_set_name,
    baseline_module2_run_id,
    challenger_module2_run_id,

    COUNT(*) AS matched_application_count,

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
    ) AS source_field_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_product_type_policy_key IS DISTINCT FROM challenger_product_type_policy_key)
        AS product_type_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_score_band_policy_key IS DISTINCT FROM challenger_score_band_policy_key)
        AS score_band_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_credit_score IS DISTINCT FROM challenger_credit_score)
        AS credit_score_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_annual_income IS DISTINCT FROM challenger_annual_income)
        AS annual_income_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_requested_amount IS DISTINCT FROM challenger_requested_amount)
        AS requested_amount_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_requested_monthly_payment_proxy IS DISTINCT FROM challenger_requested_monthly_payment_proxy)
        AS requested_payment_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_requested_payment_to_income_ratio IS DISTINCT FROM challenger_requested_payment_to_income_ratio)
        AS requested_pti_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_amount_to_income_ratio IS DISTINCT FROM challenger_amount_to_income_ratio)
        AS amount_to_income_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_estimated_pd IS DISTINCT FROM challenger_estimated_pd)
        AS estimated_pd_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_estimated_lgd IS DISTINCT FROM challenger_estimated_lgd)
        AS estimated_lgd_mismatch_count,

    COUNT(*) FILTER (WHERE baseline_requested_expected_loss_amount IS DISTINCT FROM challenger_requested_expected_loss_amount)
        AS requested_expected_loss_mismatch_count,

    CASE
        WHEN COUNT(*) = 50000
         AND COUNT(*) FILTER (
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
            ) = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status

FROM matched_rows

GROUP BY
    comparison_group_id,
    comparison_set_name,
    baseline_module2_run_id,
    challenger_module2_run_id

ORDER BY comparison_group_id;



/***************************************************************************************************
SECTION 17.14 — EXECUTIVE EVIDENCE CAMPAIGN SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Display the one-row executive evidence summary for all completed Module 2 campaign runs.

WHY THIS MATTERS:
    This is the primary run-level result table for executive review, README drafting, LinkedIn
    storyline drafting, and final Validation Summary support.

SOURCE:
    credit_decisioning_sim.strategy_run_evidence_summary

EXPECTED RESULT:
    36 rows.
    Each row should have:
        applications = 50,000
        populated frontier fields
        populated validation rollup counts
        populated registry IDs where applicable

INTERPRETATION:
    Query 17.14 is run-level evidence.
    Query 17.15 is comparison-level evidence.

***************************************************************************************************/

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

    strategy_name,
    strategy_version,

    applications,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,

    total_requested_amount,
    total_approved_amount,
    approved_amount_capture_rate,

    total_requested_expected_loss_amount,
    total_approved_expected_loss_amount,
    approved_expected_loss_rate,
    approved_amount_per_approved_expected_loss_dollar,

    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_approved_payment_to_income_ratio_offer_rows,

    frontier_position_type,
    executive_frontier_quadrant,
    frontier_interpretation_note,

    top_primary_reason_code,
    top_non_approval_primary_reason_code,
    top_policy_stop_primary_reason_code,
    top_reason_code_delta_driver_code,

    top_approved_amount_product,
    top_approved_expected_loss_product,
    top_approved_amount_score_band,
    top_approved_expected_loss_score_band,
    top_approved_el_product_score_segment,

    validation_pass_count,
    validation_review_count,
    validation_not_applicable_count,

    module3_growth_inputs_available_flag,
    module3_growth_input_gap_note

FROM credit_decisioning_sim.strategy_run_evidence_summary

ORDER BY run_sequence_number;



/***************************************************************************************************
SECTION 17.15 — BASELINE × CHALLENGER DELTA SUMMARY FOR ALL COMPARISON GROUPS
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the main comparison-level strategy-effect table across all active comparison groups.

WHY THIS MATTERS:
    The executive evidence table is one row per run.

    This query is one row per baseline / challenger comparison.

    It answers:

        "How did the challenger strategy change access, approvals, counteroffers, manual review,
         declines, approved exposure, approved Expected Loss, approved Expected Loss rate,
         offered-population synthetic-risk profile, and approved PTI?"

EXPECTED RESULT:
    17 rows.

INTERPRETATION:
    Positive / negative deltas should be interpreted in the context of the strategy family.

    Examples:
        tighter risk should reduce offer exposure and approved Expected Loss;
        growth should increase access and approved amount with risk tradeoff;
        counteroffer-first should increase counteroffers and reduce approved exposure pressure;
        manual-review reduction should shift unresolved cases to final no-offer without changing
        positive offer exposure economics.

***************************************************************************************************/

WITH comparisons AS (
    SELECT *
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
),

run_summary AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

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

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_pti_offer_rows

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

    c.baseline_module2_run_id,
    c.challenger_module2_run_id,

    c.module1_scenario_set_name,
    c.module1_scenario_name,
    c.population_id,

    c.baseline_strategy_name,
    c.challenger_strategy_name,

    b.applications AS baseline_applications,
    ch.applications AS challenger_applications,

    b.simulated_offer_exposure_rate AS baseline_offer_exposure_rate,
    ch.simulated_offer_exposure_rate AS challenger_offer_exposure_rate,
    ch.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
        AS delta_offer_exposure_rate,

    b.approval_rate AS baseline_approval_rate,
    ch.approval_rate AS challenger_approval_rate,
    ch.approval_rate - b.approval_rate
        AS delta_approval_rate,

    b.counteroffer_rate AS baseline_counteroffer_rate,
    ch.counteroffer_rate AS challenger_counteroffer_rate,
    ch.counteroffer_rate - b.counteroffer_rate
        AS delta_counteroffer_rate,

    b.manual_review_rate AS baseline_manual_review_rate,
    ch.manual_review_rate AS challenger_manual_review_rate,
    ch.manual_review_rate - b.manual_review_rate
        AS delta_manual_review_rate,

    b.decline_rate AS baseline_decline_rate,
    ch.decline_rate AS challenger_decline_rate,
    ch.decline_rate - b.decline_rate
        AS delta_decline_rate,

    b.total_approved_amount AS baseline_total_approved_amount,
    ch.total_approved_amount AS challenger_total_approved_amount,
    ch.total_approved_amount - b.total_approved_amount
        AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    ch.approved_expected_loss_rate AS challenger_approved_expected_loss_rate,
    ch.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    b.avg_synthetic_estimated_pd_proxy_offer_rows AS baseline_offer_row_avg_pd_proxy,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows AS challenger_offer_row_avg_pd_proxy,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_offer_row_avg_pd_proxy,

    b.avg_approved_pti_offer_rows AS baseline_offer_row_avg_approved_pti,
    ch.avg_approved_pti_offer_rows AS challenger_offer_row_avg_approved_pti,
    ch.avg_approved_pti_offer_rows - b.avg_approved_pti_offer_rows
        AS delta_offer_row_avg_approved_pti

FROM comparisons c

JOIN run_summary b
    ON b.strategy_set_name = c.baseline_strategy_set_name
   AND b.strategy_name = c.baseline_strategy_name
   AND b.strategy_version = c.baseline_strategy_version
   AND b.module1_scenario_set_name = c.module1_scenario_set_name
   AND b.module1_scenario_name = c.module1_scenario_name
   AND b.population_id = c.population_id

JOIN run_summary ch
    ON ch.strategy_set_name = c.challenger_strategy_set_name
   AND ch.strategy_name = c.challenger_strategy_name
   AND ch.strategy_version = c.challenger_strategy_version
   AND ch.module1_scenario_set_name = c.module1_scenario_set_name
   AND ch.module1_scenario_name = c.module1_scenario_name
   AND ch.population_id = c.population_id

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.16 — PRODUCT GUARDRAIL STRATEGY EFFECT CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY affects the intended products and leaves
    unaffected products stable.

INTENDED AFFECTED PRODUCTS:
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

INTENDED UNAFFECTED PRODUCTS:
    MORTGAGE
    HELOC
    AUTO_LOAN

WHAT TO LOOK FOR:
    For UNSECURED_PERSONAL_LOAN and REVOLVING_LINE:
        approved amount should generally decline;
        approved Expected Loss should generally decline;
        approval rate should generally decline;
        counteroffer rate may rise.

    For MORTGAGE, HELOC, and AUTO_LOAN:
        deltas should be zero or near zero because the product guardrail policy does not change
        those product rows.

NOTE:
    This checks product-level strategy effect.

    Exact parameter values are audited in Section 17.19.

***************************************************************************************************/

WITH registry_map AS (
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

product_level_metrics AS (
    SELECT
        ar.strategy_set_name,
        ar.strategy_name,
        ar.strategy_version,
        ar.module1_scenario_set_name,
        ar.module1_scenario_name,
        ar.population_id,
        ar.product_type_policy_key,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        COUNT(*) FILTER (WHERE ar.decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE ar.decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE ar.decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        SUM(COALESCE(ar.approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(ar.approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(ar.approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(ar.approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        AVG(ar.approved_payment_to_income_ratio) FILTER (
            WHERE ar.simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_pti_offer_rows,

        AVG(ar.estimated_pd) FILTER (
            WHERE ar.simulated_offer_exposure_flag IS TRUE
        ) AS avg_synthetic_estimated_pd_proxy_offer_rows

    FROM credit_decisioning_sim.strategy_decisions_archive ar

    WHERE ar.strategy_name IN (
        'BASELINE_STRATEGY',
        'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
    )

    GROUP BY
        ar.strategy_set_name,
        ar.strategy_name,
        ar.strategy_version,
        ar.module1_scenario_set_name,
        ar.module1_scenario_name,
        ar.population_id,
        ar.product_type_policy_key
),

paired_product_deltas AS (
    SELECT
        rb.module2_run_id AS baseline_module2_run_id,
        rg.module2_run_id AS guardrail_module2_run_id,

        b.module1_scenario_set_name,
        b.module1_scenario_name,
        b.population_id,
        b.product_type_policy_key,

        b.applications AS baseline_applications,
        g.applications AS guardrail_applications,

        b.simulated_offer_exposure_rate AS baseline_simulated_offer_exposure_rate,
        g.simulated_offer_exposure_rate AS guardrail_simulated_offer_exposure_rate,
        g.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
            AS delta_simulated_offer_exposure_rate,

        b.approval_rate AS baseline_approval_rate,
        g.approval_rate AS guardrail_approval_rate,
        g.approval_rate - b.approval_rate AS delta_approval_rate,

        b.counteroffer_rate AS baseline_counteroffer_rate,
        g.counteroffer_rate AS guardrail_counteroffer_rate,
        g.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

        b.decline_rate AS baseline_decline_rate,
        g.decline_rate AS guardrail_decline_rate,
        g.decline_rate - b.decline_rate AS delta_decline_rate,

        b.total_approved_amount AS baseline_total_approved_amount,
        g.total_approved_amount AS guardrail_total_approved_amount,
        g.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

        b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
        g.total_approved_expected_loss_amount AS guardrail_total_approved_expected_loss_amount,
        g.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
            AS delta_total_approved_expected_loss_amount,

        b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
        g.approved_expected_loss_rate AS guardrail_approved_expected_loss_rate,
        g.approved_expected_loss_rate - b.approved_expected_loss_rate
            AS delta_approved_expected_loss_rate,

        b.avg_approved_pti_offer_rows AS baseline_avg_approved_pti_offer_rows,
        g.avg_approved_pti_offer_rows AS guardrail_avg_approved_pti_offer_rows,
        g.avg_approved_pti_offer_rows - b.avg_approved_pti_offer_rows
            AS delta_avg_approved_pti_offer_rows,

        b.avg_synthetic_estimated_pd_proxy_offer_rows AS baseline_avg_synthetic_estimated_pd_proxy_offer_rows,
        g.avg_synthetic_estimated_pd_proxy_offer_rows AS guardrail_avg_synthetic_estimated_pd_proxy_offer_rows,
        g.avg_synthetic_estimated_pd_proxy_offer_rows - b.avg_synthetic_estimated_pd_proxy_offer_rows
            AS delta_avg_synthetic_estimated_pd_proxy_offer_rows

    FROM product_level_metrics b

    JOIN product_level_metrics g
        ON g.strategy_set_name = b.strategy_set_name
       AND g.strategy_version = b.strategy_version
       AND g.module1_scenario_set_name = b.module1_scenario_set_name
       AND g.module1_scenario_name = b.module1_scenario_name
       AND g.population_id = b.population_id
       AND g.product_type_policy_key = b.product_type_policy_key
       AND g.strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'

    LEFT JOIN registry_map rb
        ON rb.strategy_set_name = b.strategy_set_name
       AND rb.strategy_name = b.strategy_name
       AND rb.strategy_version = b.strategy_version
       AND rb.module1_scenario_set_name = b.module1_scenario_set_name
       AND rb.module1_scenario_name = b.module1_scenario_name
       AND rb.population_id = b.population_id

    LEFT JOIN registry_map rg
        ON rg.strategy_set_name = g.strategy_set_name
       AND rg.strategy_name = g.strategy_name
       AND rg.strategy_version = g.strategy_version
       AND rg.module1_scenario_set_name = g.module1_scenario_set_name
       AND rg.module1_scenario_name = g.module1_scenario_name
       AND rg.population_id = g.population_id

    WHERE b.strategy_name = 'BASELINE_STRATEGY'
)

SELECT
    baseline_module2_run_id,
    guardrail_module2_run_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    product_type_policy_key,

    baseline_applications,
    guardrail_applications,

    delta_simulated_offer_exposure_rate,
    delta_approval_rate,
    delta_counteroffer_rate,
    delta_decline_rate,

    delta_total_approved_amount,
    delta_total_approved_expected_loss_amount,
    delta_approved_expected_loss_rate,
    delta_avg_approved_pti_offer_rows,
    delta_avg_synthetic_estimated_pd_proxy_offer_rows,

    CASE
        WHEN product_type_policy_key IN ('UNSECURED_PERSONAL_LOAN', 'REVOLVING_LINE')
         AND delta_total_approved_amount < 0
         AND delta_total_approved_expected_loss_amount < 0
            THEN 'TARGET_PRODUCT_GUARDRAIL_EFFECT_OBSERVED'

        WHEN product_type_policy_key NOT IN ('UNSECURED_PERSONAL_LOAN', 'REVOLVING_LINE')
         AND ABS(delta_simulated_offer_exposure_rate) < 0.0000001
         AND ABS(delta_approval_rate) < 0.0000001
         AND ABS(delta_counteroffer_rate) < 0.0000001
         AND ABS(delta_decline_rate) < 0.0000001
         AND ABS(delta_total_approved_amount) < 0.01
         AND ABS(delta_total_approved_expected_loss_amount) < 0.01
            THEN 'UNAFFECTED_PRODUCT_REMAINED_STABLE'

        ELSE 'PRODUCT_GUARDRAIL_EFFECT_REVIEW_REQUIRED'
    END AS product_guardrail_effect_status

FROM paired_product_deltas

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    product_type_policy_key;



/***************************************************************************************************
SECTION 17.17 — COUNTEROFFER-FIRST STRATEGY EFFECT CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that COUNTEROFFER_FIRST_EXPOSURE_STRATEGY behaves like a reduced-exposure treatment
    strategy.

WHAT TO LOOK FOR:
    The counteroffer-first strategy should generally:
        increase final counteroffer rate;
        increase total counteroffer exposure reduction;
        reduce approved PTI for final counteroffer rows;
        reduce approved Expected Loss for final counteroffer rows.

***************************************************************************************************/

WITH registry_map AS (
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

counteroffer_metrics AS (
    SELECT
        ar.strategy_set_name,
        ar.strategy_name,
        ar.strategy_version,
        ar.module1_scenario_set_name,
        ar.module1_scenario_name,
        ar.population_id,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE ar.decision_outcome = 'COUNTEROFFER') AS counteroffer_count,

        COUNT(*) FILTER (WHERE ar.decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (
            WHERE ar.preliminary_decision_outcome = 'COUNTEROFFER'
        ) AS preliminary_counteroffer_count,

        COUNT(*) FILTER (
            WHERE ar.preliminary_decision_outcome = 'COUNTEROFFER'
              AND ar.counteroffer_feasibility_pass_flag IS TRUE
        ) AS feasible_counteroffer_count,

        COUNT(*) FILTER (
            WHERE ar.preliminary_decision_outcome = 'COUNTEROFFER'
              AND ar.counteroffer_feasibility_pass_flag IS FALSE
        ) AS failed_counteroffer_count,

        COUNT(*) FILTER (
            WHERE ar.preliminary_decision_outcome = 'COUNTEROFFER'
              AND ar.counteroffer_feasibility_pass_flag IS TRUE
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (WHERE ar.preliminary_decision_outcome = 'COUNTEROFFER'),
            0
        ) AS counteroffer_feasibility_pass_rate,

        AVG(ar.exposure_reduction_pct) FILTER (
            WHERE ar.decision_outcome = 'COUNTEROFFER'
        ) AS avg_exposure_reduction_pct_for_final_counteroffers,

        SUM(ar.exposure_reduction_amount) FILTER (
            WHERE ar.decision_outcome = 'COUNTEROFFER'
        ) AS total_counteroffer_exposure_reduction_amount,

        AVG(ar.approved_payment_to_income_ratio) FILTER (
            WHERE ar.decision_outcome = 'COUNTEROFFER'
        ) AS avg_approved_pti_for_final_counteroffers,

        AVG(ar.approved_expected_loss_amount) FILTER (
            WHERE ar.decision_outcome = 'COUNTEROFFER'
        ) AS avg_approved_el_for_final_counteroffers

    FROM credit_decisioning_sim.strategy_decisions_archive ar

    WHERE ar.strategy_name IN (
        'BASELINE_STRATEGY',
        'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
    )

    GROUP BY
        ar.strategy_set_name,
        ar.strategy_name,
        ar.strategy_version,
        ar.module1_scenario_set_name,
        ar.module1_scenario_name,
        ar.population_id
),

paired_counteroffer_deltas AS (
    SELECT
        rb.module2_run_id AS baseline_module2_run_id,
        rc.module2_run_id AS counteroffer_first_module2_run_id,

        b.module1_scenario_set_name,
        b.module1_scenario_name,
        b.population_id,

        b.applications AS baseline_applications,
        c.applications AS counteroffer_first_applications,

        b.counteroffer_count AS baseline_counteroffer_count,
        c.counteroffer_count AS counteroffer_first_counteroffer_count,
        c.counteroffer_count - b.counteroffer_count AS delta_counteroffer_count,

        b.counteroffer_rate AS baseline_counteroffer_rate,
        c.counteroffer_rate AS counteroffer_first_counteroffer_rate,
        c.counteroffer_rate - b.counteroffer_rate AS delta_counteroffer_rate,

        b.preliminary_counteroffer_count AS baseline_preliminary_counteroffer_count,
        c.preliminary_counteroffer_count AS counteroffer_first_preliminary_counteroffer_count,
        c.preliminary_counteroffer_count - b.preliminary_counteroffer_count
            AS delta_preliminary_counteroffer_count,

        b.feasible_counteroffer_count AS baseline_feasible_counteroffer_count,
        c.feasible_counteroffer_count AS counteroffer_first_feasible_counteroffer_count,
        c.feasible_counteroffer_count - b.feasible_counteroffer_count
            AS delta_feasible_counteroffer_count,

        b.failed_counteroffer_count AS baseline_failed_counteroffer_count,
        c.failed_counteroffer_count AS counteroffer_first_failed_counteroffer_count,
        c.failed_counteroffer_count - b.failed_counteroffer_count
            AS delta_failed_counteroffer_count,

        b.counteroffer_feasibility_pass_rate AS baseline_counteroffer_feasibility_pass_rate,
        c.counteroffer_feasibility_pass_rate AS counteroffer_first_counteroffer_feasibility_pass_rate,
        c.counteroffer_feasibility_pass_rate - b.counteroffer_feasibility_pass_rate
            AS delta_counteroffer_feasibility_pass_rate,

        b.avg_exposure_reduction_pct_for_final_counteroffers
            AS baseline_avg_exposure_reduction_pct_for_final_counteroffers,

        c.avg_exposure_reduction_pct_for_final_counteroffers
            AS counteroffer_first_avg_exposure_reduction_pct_for_final_counteroffers,

        c.avg_exposure_reduction_pct_for_final_counteroffers
            - b.avg_exposure_reduction_pct_for_final_counteroffers
            AS delta_avg_exposure_reduction_pct_for_final_counteroffers,

        b.total_counteroffer_exposure_reduction_amount
            AS baseline_total_counteroffer_exposure_reduction_amount,

        c.total_counteroffer_exposure_reduction_amount
            AS counteroffer_first_total_counteroffer_exposure_reduction_amount,

        c.total_counteroffer_exposure_reduction_amount
            - b.total_counteroffer_exposure_reduction_amount
            AS delta_total_counteroffer_exposure_reduction_amount,

        b.avg_approved_pti_for_final_counteroffers
            AS baseline_avg_approved_pti_for_final_counteroffers,

        c.avg_approved_pti_for_final_counteroffers
            AS counteroffer_first_avg_approved_pti_for_final_counteroffers,

        c.avg_approved_pti_for_final_counteroffers
            - b.avg_approved_pti_for_final_counteroffers
            AS delta_avg_approved_pti_for_final_counteroffers,

        b.avg_approved_el_for_final_counteroffers
            AS baseline_avg_approved_el_for_final_counteroffers,

        c.avg_approved_el_for_final_counteroffers
            AS counteroffer_first_avg_approved_el_for_final_counteroffers,

        c.avg_approved_el_for_final_counteroffers
            - b.avg_approved_el_for_final_counteroffers
            AS delta_avg_approved_el_for_final_counteroffers

    FROM counteroffer_metrics b

    JOIN counteroffer_metrics c
        ON c.strategy_set_name = b.strategy_set_name
       AND c.strategy_version = b.strategy_version
       AND c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'

    LEFT JOIN registry_map rb
        ON rb.strategy_set_name = b.strategy_set_name
       AND rb.strategy_name = b.strategy_name
       AND rb.strategy_version = b.strategy_version
       AND rb.module1_scenario_set_name = b.module1_scenario_set_name
       AND rb.module1_scenario_name = b.module1_scenario_name
       AND rb.population_id = b.population_id

    LEFT JOIN registry_map rc
        ON rc.strategy_set_name = c.strategy_set_name
       AND rc.strategy_name = c.strategy_name
       AND rc.strategy_version = c.strategy_version
       AND rc.module1_scenario_set_name = c.module1_scenario_set_name
       AND rc.module1_scenario_name = c.module1_scenario_name
       AND rc.population_id = c.population_id

    WHERE b.strategy_name = 'BASELINE_STRATEGY'
)

SELECT
    baseline_module2_run_id,
    counteroffer_first_module2_run_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    delta_counteroffer_count,
    delta_counteroffer_rate,
    delta_preliminary_counteroffer_count,
    delta_feasible_counteroffer_count,
    delta_failed_counteroffer_count,
    delta_counteroffer_feasibility_pass_rate,
    delta_avg_exposure_reduction_pct_for_final_counteroffers,
    delta_total_counteroffer_exposure_reduction_amount,
    delta_avg_approved_pti_for_final_counteroffers,
    delta_avg_approved_el_for_final_counteroffers,

    CASE
        WHEN delta_counteroffer_rate > 0
         AND delta_total_counteroffer_exposure_reduction_amount > 0
         AND delta_avg_approved_pti_for_final_counteroffers < 0
         AND delta_avg_approved_el_for_final_counteroffers < 0
            THEN 'COUNTEROFFER_FIRST_EFFECT_OBSERVED'

        ELSE 'COUNTEROFFER_FIRST_EFFECT_REVIEW_REQUIRED'
    END AS counteroffer_strategy_effect_status

FROM paired_counteroffer_deltas

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name;



/***************************************************************************************************
SECTION 17.18 — PARAMETER SNAPSHOT PROFILE AUDIT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that every campaign run has a complete parameter snapshot and that captured strategy
    source fields reconcile to the run-level evidence fields.

WHY THIS MATTERS:
    A campaign result is not fully interpretable unless the parameter card that produced it is
    preserved.

EXPECTED RESULT:
    36 rows.
    Each row should show:
        strategy_params_captured_flag = TRUE
        product_policy_params_captured_flag = TRUE
        run_story_params_captured_flag = TRUE
        parameter_snapshot_status = PARAMETER_SNAPSHOT_READY

***************************************************************************************************/

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

    strategy_name,
    strategy_version,

    parameter_snapshot_hash,

    strategy_params_jsonb IS NOT NULL AS strategy_params_captured_flag,
    product_policy_params_jsonb IS NOT NULL AS product_policy_params_captured_flag,
    run_story_params_jsonb IS NOT NULL AS run_story_params_captured_flag,

    strategy_params_jsonb ->> 'strategy_run_id' AS captured_strategy_run_id,
    strategy_params_jsonb ->> 'module1_input_source' AS captured_module1_input_source,
    strategy_params_jsonb ->> 'source_module1_scenario_set_name' AS captured_source_module1_scenario_set_name,
    strategy_params_jsonb ->> 'source_module1_scenario_name' AS captured_source_module1_scenario_name,
    strategy_params_jsonb ->> 'source_population_id' AS captured_source_population_id,
    strategy_params_jsonb ->> 'failed_counteroffer_resolution' AS captured_failed_counteroffer_resolution,

    CASE
        WHEN strategy_params_jsonb IS NULL
          OR product_policy_params_jsonb IS NULL
          OR run_story_params_jsonb IS NULL
            THEN 'PARAMETER_PAYLOAD_REVIEW_REQUIRED'

        WHEN module1_scenario_set_name IS DISTINCT FROM strategy_params_jsonb ->> 'source_module1_scenario_set_name'
          OR module1_scenario_name IS DISTINCT FROM strategy_params_jsonb ->> 'source_module1_scenario_name'
          OR population_id IS DISTINCT FROM strategy_params_jsonb ->> 'source_population_id'
            THEN 'PARAMETER_SOURCE_LINEAGE_REVIEW_REQUIRED'

        ELSE 'PARAMETER_SNAPSHOT_READY'
    END AS parameter_snapshot_status

FROM credit_decisioning_sim.strategy_run_parameter_snapshot

ORDER BY run_sequence_number;



/***************************************************************************************************
SECTION 17.19 — PRODUCT GUARDRAIL POLICY SNAPSHOT EXACT-VALUE AUDIT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs captured the intended canonical product
    guardrail values for:

        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

WHY THIS MATTERS:
    Structural campaign acceptance can pass even when a product-policy parameter was populated with
    the wrong value.

    This exact-value audit closes that gap.

EXPECTED RESULT:
    10 rows:
        5 product-guardrail runs × 2 audited products.

    Each row should show:
        product_policy_field_mismatch_count = 0
        product_guardrail_policy_value_status = PRODUCT_GUARDRAIL_POLICY_VALUES_MATCH

***************************************************************************************************/

WITH product_guardrail_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_name,
        product_policy_params_jsonb
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
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
        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,
        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,
        r.strategy_name,

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

    CROSS JOIN LATERAL jsonb_array_elements(r.product_policy_params_jsonb)
        AS pp(product_policy_row)

    WHERE pp.product_policy_row ->> 'product_type' IN (
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    )
),

policy_comparison AS (
    SELECT
        e.module2_run_id,
        e.run_sequence_number,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,
        e.strategy_name,
        e.product_type,

        a.actual_product_approve_max_pti,
        e.expected_product_approve_max_pti,

        a.actual_product_review_max_pti,
        e.expected_product_review_max_pti,

        a.actual_product_decline_min_pti,
        e.expected_product_decline_min_pti,

        a.actual_counteroffer_target_pti,
        e.expected_counteroffer_target_pti,

        a.actual_product_approve_max_requested_el,
        e.expected_product_approve_max_requested_el,

        a.actual_product_review_max_requested_el,
        e.expected_product_review_max_requested_el,

        a.actual_product_decline_min_requested_el,
        e.expected_product_decline_min_requested_el,

        a.actual_product_approved_el_cap,
        e.expected_product_approved_el_cap,

        a.actual_product_min_approved_amount,
        e.expected_product_min_approved_amount,

        a.actual_product_max_approved_amount,
        e.expected_product_max_approved_amount,

        a.actual_product_min_counteroffer_pct,
        e.expected_product_min_counteroffer_pct,

        a.actual_product_max_exposure_reduction_pct,
        e.expected_product_max_exposure_reduction_pct,

        (
            CASE WHEN a.product_type IS NULL THEN 1 ELSE 0 END
          + CASE WHEN a.actual_product_approve_max_pti IS DISTINCT FROM e.expected_product_approve_max_pti THEN 1 ELSE 0 END
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
        ) AS product_policy_field_mismatch_count

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
    product_type,

    actual_product_approve_max_pti,
    expected_product_approve_max_pti,

    actual_product_review_max_pti,
    expected_product_review_max_pti,

    actual_product_decline_min_pti,
    expected_product_decline_min_pti,

    actual_counteroffer_target_pti,
    expected_counteroffer_target_pti,

    actual_product_approve_max_requested_el,
    expected_product_approve_max_requested_el,

    actual_product_review_max_requested_el,
    expected_product_review_max_requested_el,

    actual_product_decline_min_requested_el,
    expected_product_decline_min_requested_el,

    actual_product_approved_el_cap,
    expected_product_approved_el_cap,

    actual_product_min_approved_amount,
    expected_product_min_approved_amount,

    actual_product_max_approved_amount,
    expected_product_max_approved_amount,

    actual_product_min_counteroffer_pct,
    expected_product_min_counteroffer_pct,

    actual_product_max_exposure_reduction_pct,
    expected_product_max_exposure_reduction_pct,

    product_policy_field_mismatch_count,

    CASE
        WHEN product_policy_field_mismatch_count = 0
            THEN 'PRODUCT_GUARDRAIL_POLICY_VALUES_MATCH'
        ELSE 'PRODUCT_GUARDRAIL_POLICY_VALUE_REVIEW_REQUIRED'
    END AS product_guardrail_policy_value_status

FROM policy_comparison

ORDER BY
    run_sequence_number,
    product_type;



/***************************************************************************************************
SECTION 17.20 — FINAL MODULE 2 CAMPAIGN ACCEPTANCE ROLLUP
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the final one-row campaign acceptance status after archive, registry, evidence,
    convention, comparison, matched-source, and parameter-snapshot checks.

SQL PURPOSE:
    Confirm:
        active campaign registry rows;
        active comparison registry rows;
        archive inventory and archive grain;
        comparison readiness;
        matched source-field consistency;
        executive evidence and parameter snapshot row counts;
        critical final-output convention integrity;
        product-guardrail policy snapshots match intended canonical values.

EXPECTED FINAL STATUS:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

IMPORTANT:
    This rollup is stricter than the original campaign Query 20 because it includes product guardrail
    exact-value parameter audit and comparison source-field consistency.

***************************************************************************************************/

WITH archive_inventory AS (
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

archive_grain_duplicates AS (
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
    ) duplicate_rows
),

registry_runs AS (
    SELECT COUNT(*) AS active_campaign_registry_rows
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
),

comparison_registry AS (
    SELECT COUNT(*) AS active_comparison_registry_rows
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE registry_active_flag IS TRUE
),

comparison_readiness AS (
    WITH comparisons AS (
        SELECT *
        FROM credit_decisioning_sim.strategy_comparison_campaign_registry
        WHERE registry_active_flag IS TRUE
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
    )

    SELECT
        COUNT(*) AS comparison_group_count,

        COUNT(*) FILTER (
            WHERE COALESCE(b.archived_rows, 0) = 50000
              AND COALESCE(ch.archived_rows, 0) = 50000
              AND COALESCE(b.archived_rows, 0) = COALESCE(b.distinct_application_id_count, 0)
              AND COALESCE(ch.archived_rows, 0) = COALESCE(ch.distinct_application_id_count, 0)
        ) AS comparison_ready_count

    FROM comparisons c

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
),

source_consistency AS (
    WITH comparisons AS (
        SELECT *
        FROM credit_decisioning_sim.strategy_comparison_campaign_registry
        WHERE registry_active_flag IS TRUE
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

        FROM comparisons c

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

    comparison_source_rollup AS (
        SELECT
            comparison_group_id,

            COUNT(*) AS matched_application_count,

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
    )

    SELECT
        COUNT(*) AS source_consistency_group_count,

        COUNT(*) FILTER (
            WHERE matched_application_count = 50000
              AND source_field_mismatch_count = 0
        ) AS source_consistency_pass_count,

        COUNT(*) FILTER (
            WHERE matched_application_count <> 50000
               OR source_field_mismatch_count <> 0
        ) AS source_consistency_review_count

    FROM comparison_source_rollup
),

executive_evidence AS (
    SELECT COUNT(*) AS executive_evidence_rows
    FROM credit_decisioning_sim.strategy_run_evidence_summary
),

parameter_evidence AS (
    SELECT COUNT(*) AS parameter_snapshot_rows
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
),

validation_evidence AS (
    SELECT
        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS validation_evidence_run_count
    FROM credit_decisioning_sim.strategy_run_validation_evidence
),

segment_evidence AS (
    SELECT
        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS segment_evidence_run_count
    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
),

convention_violations AS (
    SELECT
        COUNT(*) FILTER (
            WHERE (
                COALESCE(approval_flag::INT, 0)
                + COALESCE(counteroffer_flag::INT, 0)
                + COALESCE(manual_review_flag::INT, 0)
                + COALESCE(decline_flag::INT, 0)
            ) <> 1
        )
        +
        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        )
        +
        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR triggered_reason_code_list IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
        ) AS critical_convention_violation_count

    FROM credit_decisioning_sim.strategy_decisions_archive
),

product_guardrail_runs AS (
    SELECT
        module2_run_id,
        product_policy_params_jsonb
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),

expected_product_guardrail_policy AS (
    SELECT *
    FROM (
        VALUES
            ('UNSECURED_PERSONAL_LOAN'::TEXT, 0.130000::NUMERIC, 0.220000::NUMERIC, 0.320000::NUMERIC, 0.110000::NUMERIC, 2500.00::NUMERIC, 5000.00::NUMERIC, 8500.00::NUMERIC, 2000.00::NUMERIC, 1000.00::NUMERIC, 27500.00::NUMERIC, 0.500000::NUMERIC, 0.500000::NUMERIC),
            ('REVOLVING_LINE'::TEXT, 0.100000::NUMERIC, 0.180000::NUMERIC, 0.280000::NUMERIC, 0.080000::NUMERIC, 1500.00::NUMERIC, 3200.00::NUMERIC, 6500.00::NUMERIC, 1400.00::NUMERIC, 1000.00::NUMERIC, 16000.00::NUMERIC, 0.500000::NUMERIC, 0.500000::NUMERIC)
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
        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy AS (
    SELECT
        r.module2_run_id,
        pp.product_policy_row ->> 'product_type' AS product_type,

        (pp.product_policy_row ->> 'product_approve_max_pti')::NUMERIC AS actual_product_approve_max_pti,
        (pp.product_policy_row ->> 'product_review_max_pti')::NUMERIC AS actual_product_review_max_pti,
        (pp.product_policy_row ->> 'product_decline_min_pti')::NUMERIC AS actual_product_decline_min_pti,
        (pp.product_policy_row ->> 'counteroffer_target_pti')::NUMERIC AS actual_counteroffer_target_pti,
        (pp.product_policy_row ->> 'product_approve_max_requested_el')::NUMERIC AS actual_product_approve_max_requested_el,
        (pp.product_policy_row ->> 'product_review_max_requested_el')::NUMERIC AS actual_product_review_max_requested_el,
        (pp.product_policy_row ->> 'product_decline_min_requested_el')::NUMERIC AS actual_product_decline_min_requested_el,
        (pp.product_policy_row ->> 'product_approved_el_cap')::NUMERIC AS actual_product_approved_el_cap,
        (pp.product_policy_row ->> 'product_min_approved_amount')::NUMERIC AS actual_product_min_approved_amount,
        (pp.product_policy_row ->> 'product_max_approved_amount')::NUMERIC AS actual_product_max_approved_amount,
        (pp.product_policy_row ->> 'product_min_counteroffer_pct')::NUMERIC AS actual_product_min_counteroffer_pct,
        (pp.product_policy_row ->> 'product_max_exposure_reduction_pct')::NUMERIC AS actual_product_max_exposure_reduction_pct

    FROM product_guardrail_runs r

    CROSS JOIN LATERAL jsonb_array_elements(r.product_policy_params_jsonb)
        AS pp(product_policy_row)

    WHERE pp.product_policy_row ->> 'product_type' IN (
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    )
),

product_guardrail_policy_audit AS (
    SELECT
        COUNT(*) AS expected_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NULL
        ) AS missing_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE a.product_type IS NOT NULL
              AND (
                    a.actual_product_approve_max_pti IS DISTINCT FROM e.expected_product_approve_max_pti
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
              )
        ) AS product_guardrail_policy_mismatch_rows

    FROM expected_run_product_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
)

SELECT
    rr.active_campaign_registry_rows,
    cr.active_comparison_registry_rows,

    cmp.comparison_group_count,
    cmp.comparison_ready_count,

    src.source_consistency_group_count,
    src.source_consistency_pass_count,
    src.source_consistency_review_count,

    (SELECT COUNT(*) FROM archive_inventory) AS archived_strategy_scenario_slices,
    (SELECT SUM(archived_rows) FROM archive_inventory) AS total_archived_rows,

    (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000)
        AS archive_slices_not_50000_rows,

    (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> distinct_application_id_count)
        AS archive_slices_with_duplicate_application_ids,

    agd.duplicate_archive_grain_count,

    ee.executive_evidence_rows,
    pe.parameter_snapshot_rows,
    ve.validation_evidence_run_count,
    se.segment_evidence_run_count,

    cv.critical_convention_violation_count,

    pga.expected_product_guardrail_policy_rows,
    pga.missing_product_guardrail_policy_rows,
    pga.product_guardrail_policy_mismatch_rows,

    CASE
        WHEN rr.active_campaign_registry_rows = 36
         AND cr.active_comparison_registry_rows = 17
         AND cmp.comparison_group_count = 17
         AND cmp.comparison_ready_count = 17
         AND src.source_consistency_group_count = 17
         AND src.source_consistency_pass_count = 17
         AND src.source_consistency_review_count = 0
         AND (SELECT COUNT(*) FROM archive_inventory) = 36
         AND (SELECT SUM(archived_rows) FROM archive_inventory) = 1800000
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000) = 0
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> distinct_application_id_count) = 0
         AND agd.duplicate_archive_grain_count = 0
         AND ee.executive_evidence_rows = 36
         AND pe.parameter_snapshot_rows = 36
         AND ve.validation_evidence_run_count = 36
         AND se.segment_evidence_run_count = 36
         AND cv.critical_convention_violation_count = 0
         AND pga.expected_product_guardrail_policy_rows = 10
         AND pga.missing_product_guardrail_policy_rows = 0
         AND pga.product_guardrail_policy_mismatch_rows = 0
            THEN 'MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS'

        WHEN rr.active_campaign_registry_rows = 36
         AND cr.active_comparison_registry_rows = 17
         AND cmp.comparison_group_count = 17
         AND cmp.comparison_ready_count = 17
         AND src.source_consistency_group_count = 17
         AND src.source_consistency_pass_count = 17
         AND src.source_consistency_review_count = 0
         AND (SELECT COUNT(*) FROM archive_inventory) = 36
         AND (SELECT SUM(archived_rows) FROM archive_inventory) = 1800000
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000) = 0
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> distinct_application_id_count) = 0
         AND agd.duplicate_archive_grain_count = 0
         AND ee.executive_evidence_rows = 36
         AND pe.parameter_snapshot_rows = 36
         AND ve.validation_evidence_run_count = 36
         AND se.segment_evidence_run_count = 36
         AND cv.critical_convention_violation_count = 0
         AND (
                pga.expected_product_guardrail_policy_rows <> 10
             OR pga.missing_product_guardrail_policy_rows > 0
             OR pga.product_guardrail_policy_mismatch_rows > 0
         )
            THEN 'STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED'

        ELSE 'REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS'
    END AS module2_campaign_acceptance_status

FROM registry_runs rr
CROSS JOIN comparison_registry cr
CROSS JOIN comparison_readiness cmp
CROSS JOIN source_consistency src
CROSS JOIN archive_grain_duplicates agd
CROSS JOIN executive_evidence ee
CROSS JOIN parameter_evidence pe
CROSS JOIN validation_evidence ve
CROSS JOIN segment_evidence se
CROSS JOIN convention_violations cv
CROSS JOIN product_guardrail_policy_audit pga;



/***************************************************************************************************
END OF SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW

If execution reaches this point:
    1. Archive campaign inventory has been reviewed.
    2. Archive slice detail has been displayed.
    3. Archive grain duplicates have been checked.
    4. Campaign registry rows have been reconciled to archive slices.
    5. Registry/archive missing or mismatch detail has been displayed.
    6. Orphan archive slices have been checked.
    7. Section 16 evidence coverage has been summarized.
    8. Section 16 evidence detail has been displayed by run.
    9. Full-archive final-output conventions have been checked.
    10. Validation status has been summarized by campaign run.
    11. Validation REVIEW / NOT_APPLICABLE concentration has been reviewed.
    12. Comparison registry readiness has been checked.
    13. Matched comparison source-field consistency has been checked.
    14. Executive evidence campaign summary has been displayed.
    15. Baseline × challenger deltas have been displayed.
    16. Product guardrail strategy effects have been reviewed.
    17. Counteroffer-first strategy effects have been reviewed.
    18. Parameter snapshot completeness has been reviewed.
    19. Product guardrail policy snapshots have been compared to intended canonical values.
    20. Final campaign acceptance has been summarized in one status row.

Interpretation of final acceptance:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        Archive, registry, evidence, convention, comparison, source-consistency, and audited
        product-policy checks are clean.

    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        Structural, archive, evidence, convention, comparison, and source-consistency checks are
        clean, but at least one audited product guardrail parameter snapshot does not match intended
        canonical values.

    REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        One or more structural, archive, registry, evidence, convention, comparison, source-field,
        or parameter checks require review.

No archive rows were modified.
No latest-run rows were modified.
No evidence rows were modified.
No campaign registry rows were modified.
No strategy outputs were recalculated.
No approved exposure values were recalculated.
No approved Expected Loss values were recalculated.
No simulated reason codes were reassigned.
No Module 3 economics were calculated.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01346 -->


---

<a id="c038-m01347"></a>

### C038-M01347

**Andrew** · 2026-05-11T22:33:48.947000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01347 -->
review updated section 17 QA.  perform an elite validation review and then provide an executive narrative of what we learned in this campaign.  cite interesting lessons/observations/executive summary from each run and include key metrics to prove the story.  if possible, add useful charts to help tell the story more clearly.
<!-- END_MESSAGE C038-M01347 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.9_QA_post_campaign_audit_full_archive_final_output_convention_checks.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.8_QA_post_campaign_audit_evidence_coverage_detail_by_run.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.7_QA_post_campaign_audit_confirm_evidence_exists_for_all_campaign_runs.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.6_QA_post_campaign_audit_archive_slices_without_active_campaign_registry_row_expected_result_zero_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.5_QA_post_campaign_audit_registry_runs_missing_or_mismatched_in_archive_expected_result_zero_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.4_QA_post_campaign_audit_registry_to_archive_reconciliation.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.3_QA_post_campaign_audit_archive_grain_dupicate_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.2_QA_post_campaign_audit_archive_slice_detail.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.1_QA_post_campaign_audit_archive_campaign_inventory.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.20_QA_post_campaign_audit_final_campaign_acceptance_rollup.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.19_QA_post_campaign_audit_product_guardrail_policy_snapshot_exact_value.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.18_QA_post_campaign_audit_parameter_snapshot_profile.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.17_QA_post_campaign_audit_counteroffer_first_strategy_effect_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.16_QA_post_campaign_audit_product_guardrail_strategy_effect_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.15_QA_post_campaign_audit_baseline_x_challenger_delta_summary_for_all_comparison_groups.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.14_QA_post_campaign_audit_executive_evidence_campaign_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.13_QA_post_campaign_audit_matched_comparison_source_field_consistency.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.12_QA_post_campaign_audit_comparison_registry_readiness.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.11_QA_post_campaign_audit_validation_review_concentration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.10_QA_post_campaign_audit_validation_status_summary_by_campaign_run.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01356"></a>

### C038-M01356

**ChatGPT** · 2026-05-11T22:42:22.655376-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01356 -->
## Section 17 QA validation review

The updated Section 17 campaign QA is **very strong structurally**, but it is **not yet final-acceptance clean** because one product-guardrail parameter mismatch still remains.

```text
OVERALL STATUS:
    STRUCTURAL QA: PASS
    ARCHIVE / REGISTRY / EVIDENCE QA: PASS
    COMPARISON QA: PASS
    FINAL OUTPUT CONVENTION QA: PASS
    STRATEGY EFFECT QA: PASS
    PARAMETER SNAPSHOT QA: REVIEW REQUIRED

FINAL ACCEPTANCE STATUS:
    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED
```

The remaining issue is narrow and specific:

```text
Run:
    M2-36 — BROAD_LGD_STRESS / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY

Product:
    UNSECURED_PERSONAL_LOAN

Parameter:
    product_decline_min_requested_el

Expected:
    8,500.00

Actual:
    85,000.00
```

That means the broad LGD stress product-guardrail run still has the old typo in the **captured parameter snapshot** for unsecured personal loan. Structurally, the campaign ran cleanly; analytically, M2-36 should be rerun with that one value corrected before treating the product-guardrail / broad-LGD stress result as final.

---

## Elite validation review

### 1. Archive and campaign inventory: PASS

Section 17.1 confirms the full campaign archive is complete:

```text
archived_strategy_scenario_slices = 36
total_archived_rows               = 1,800,000
slices_not_50000_rows             = 0
slices_with_duplicate_app_ids     = 0
status                            = MODULE_2_ARCHIVE_INVENTORY_READY
```

That means the campaign landed at the expected design size:

```text
36 runs × 50,000 synthetic applications = 1,800,000 archived Module 2 rows
```

This is exactly the right archive footprint for the Module 2 campaign. Section 12 is the governed archive layer, preserving completed latest-run strategy slices for comparison and validation rather than relying on the replaceable latest-run table. fileciteturn184file21

### 2. Archive grain: PASS

Section 17.3 shows:

```text
duplicate_archive_grain_count = 0
```

That confirms no duplicate rows exist at the official archive grain:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

This is a hard acceptance signal. It means the archive is safe for matched comparison.

### 3. Registry-to-archive reconciliation: PASS

Section 17.4 confirms:

```text
registry_run_count                         = 36
registry_runs_with_archive_rows            = 36
registry_runs_missing_archive_rows         = 0
registry_runs_not_50000_rows               = 0
registry_runs_with_duplicate_applications  = 0
status                                     = CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE
```

Sections 17.5 and 17.6 returned zero rows, meaning there are no registry runs missing from archive and no orphan archive slices outside the active campaign registry.

This validates the run-governance spine:

```text
campaign registry → archive slice → evidence row → validation evidence → comparison evidence
```

### 4. Evidence coverage: PASS

Section 17.7 confirms Section 16 evidence exists for all 36 runs:

```text
runs_with_one_executive_evidence_row      = 36
runs_with_one_parameter_snapshot_row      = 36
runs_with_validation_evidence_rows        = 36
runs_with_segment_evidence_rows           = 36
evidence_coverage_issue_count             = 0
status                                    = SECTION_16_EVIDENCE_COVERAGE_READY
```

Section 17.8 confirms each run has:

```text
executive_rows  = 1
parameter_rows  = 1
validation_rows = 22
segment_rows    = 25
status          = EVIDENCE_CAPTURE_READY
```

The 25 segment rows are expected:

```text
5 products × 5 score bands = 25 product × score segments
```

This is exactly why Section 16 exists: the archive preserves applicant-level output, while Section 16 persists executive evidence, validation evidence, parameter snapshots, and product × score segment evidence so the campaign can be reviewed without manually rebuilding dozens of grids. fileciteturn184file10

### 5. Full-archive final-output conventions: PASS

Section 17.9 validates all 1.8M archived rows and shows **zero** violations across final decision flags, simulated offer-exposure flags, approved amount conventions, affordability conventions, approved Expected Loss conventions, reason-code completeness, and reason-family alignment.

```text
archived_rows                                      = 1,800,000
final_outcome_flag_count_violation_rows            = 0
simulated_offer_exposure_flag_violation_rows       = 0
approve_amount_violation_rows                      = 0
counteroffer_amount_violation_rows                 = 0
manual_review_amount_violation_rows                = 0
decline_amount_violation_rows                      = 0
counteroffer_affordability_violation_rows          = 0
manual_review_affordability_violation_rows         = 0
decline_affordability_violation_rows               = 0
approve_expected_loss_violation_rows               = 0
counteroffer_expected_loss_violation_rows          = 0
manual_review_expected_loss_violation_rows         = 0
decline_expected_loss_violation_rows               = 0
reason_code_completeness_violation_rows            = 0
reason_family_alignment_violation_rows             = 0
```

This is one of the strongest validation results. Section 14 treats final-output convention violations as more severe than ordinary diagnostic REVIEW items because they suggest implementation or convention defects. Here, the full archive is convention-clean. fileciteturn184file14

### 6. Validation status summary: PASS with interpretive review items

Section 17.10 shows:

```text
validation evidence rows = 792
PASS                     = 719
REVIEW                   = 72
NOT_APPLICABLE           = 1
```

The recurring REVIEW themes are:

```text
Mixed-signal and borderline concentration review: 36 runs
Counteroffer concentration review: 31 runs
Final counteroffer feasibility / affordability review: 3 runs
Decline / policy-stop convention review: 1 run
Matched comparison readiness review: 1 run
```

This is acceptable. Section 14’s validation summary framework intentionally uses REVIEW for interpretive diagnostics rather than automatic invalidation; critical structural failures are expected to be caught by fail-fast gatekeepers or convention checks. fileciteturn184file19

### 7. Comparison readiness and matched-source consistency: PASS

Section 17.12 confirms all comparison groups are ready:

```text
comparison groups = 17
baseline rows     = 50,000 for each pair
challenger rows   = 50,000 for each pair
status            = COMPARISON_READY for all 17
```

Section 17.13 confirms source-field consistency:

```text
matched_application_count     = 50,000 for all 17 comparisons
source_field_mismatch_count   = 0 for all 17 comparisons
source_consistency_status     = SOURCE_FIELDS_MATCH for all 17 comparisons
```

This is a major analytical acceptance point. It proves the baseline / challenger deltas are clean Module 2 strategy effects, not Module 1 source-drift artifacts. Section 13 is designed specifically to isolate downstream strategy effects by matching baseline and challenger slices on the same Module 1 scenario, population, and application ID. fileciteturn184file20

### 8. Parameter snapshot audit: PASS except M2-36 product guardrail exact-value audit

Section 17.18 shows:

```text
PARAMETER_SNAPSHOT_READY = 36 runs
```

That means strategy JSONB, product-policy JSONB, and run-story JSONB were captured for every run. Section 16.4 intentionally snapshots the active strategy card and product-policy card so the campaign can prove what parameter payload produced each result. fileciteturn184file7

Section 17.19 shows 9 of 10 product-guardrail product-policy audit rows match expected values. The single remaining mismatch is:

```text
M2-36 / BROAD_LGD_STRESS / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
UNSECURED_PERSONAL_LOAN
actual product_decline_min_requested_el   = 85,000.00
expected product_decline_min_requested_el = 8,500.00
```

That is why Section 17.20 properly returns:

```text
STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED
```

### Validation conclusion

The campaign is **structurally valid, convention-clean, comparison-ready, and analytically rich**, but it is **not yet final-acceptance complete** because M2-36 still has one product-policy parameter mismatch. The fix is narrow: correct the M2-36 `UNSECURED_PERSONAL_LOAN product_decline_min_requested_el` value to `8500.00`, rerun M2-36 through Section 16, rerun Section 15, refresh frontier evidence if needed, and rerun Section 17.

---

## Useful charts

I created four charts to support the executive story:

[Strategy frontier: access vs approved Expected Loss rate](sandbox:/mnt/data/module2_section17_strategy_frontier_access_vs_el_rate.png)

[Baseline vs challenger tradeoff: access movement vs approved Expected Loss movement](sandbox:/mnt/data/module2_section17_comparison_delta_access_vs_expected_loss.png)

[Average approved Expected Loss movement by challenger strategy family](sandbox:/mnt/data/module2_section17_avg_approved_el_delta_by_strategy_family.png)

[Product guardrail strategy: approved amount reduction in targeted products](sandbox:/mnt/data/module2_section17_product_guardrail_target_product_approved_amount_delta.png)

Treat the product-guardrail / broad-LGD stress portion as provisional until M2-36 is corrected.

---

# Executive campaign narrative

## The campaign proved the strategy engine can simulate credit-policy tradeoffs, not just assign outcomes

Module 2 did what it was designed to do: it transformed a fixed synthetic applicant and risk foundation into governed strategy outcomes across multiple credit-policy postures. The campaign tested access, risk discipline, affordability discipline, counteroffer treatment, product guardrails, manual-review resolution, and scenario sensitivity across 36 archived runs.

The important outcome is not one “best” strategy. The important outcome is that the system made tradeoffs visible:

```text
Growth strategies increased access and approved exposure, but increased approved Expected Loss.
Risk-discipline strategies reduced approved Expected Loss and offered-population risk, but reduced access.
Affordability strategies reduced approved exposure and approved PTI, but introduced access tradeoffs.
Counteroffer strategies preserved or improved positive offer exposure through reduced-exposure treatment.
Product guardrails targeted unsecured / revolving exposure without disrupting unaffected products.
Manual-review reduction converted unresolved outcomes into final no-offer outcomes without changing offer economics.
```

That is exactly the type of strategy-frontier behavior Section 15 is designed to classify. Section 15 explicitly treats the frontier as a tradeoff view across access, approved amount, approved Expected Loss, affordability, synthetic-risk profile, counteroffer reliance, review burden, decline concentration, and reason-code movement, not as a single “winner” ranking. fileciteturn184file12

---

## Core lesson 1 — Baseline strategy establishes a stable reference frontier

The main baseline run, **M2-01 / BASELINE_V2 / BASELINE_STRATEGY**, produced:

```text
Approval rate:                  22.58%
Counteroffer rate:              38.13%
Manual-review rate:             13.88%
Decline rate:                   25.41%
Simulated offer-exposure rate:  60.72%
Total approved amount:          $3.880B
Total approved Expected Loss:   $58.93M
Approved Expected Loss rate:    1.519%
```

This baseline is a credible reference point: a material share of positive offer exposure comes through counteroffer, not just clean approval. That is a useful signal because Module 2 is not only a binary approve/decline engine; it includes exposure treatment and counteroffer feasibility. Section 8 separates counteroffer feasibility from preliminary routing, and Section 9 resolves final outcomes after feasibility has been tested. fileciteturn184file25turn184file24

---

## Core lesson 2 — Tighter synthetic-risk strategy is a real risk-discipline lever

The tighter synthetic-risk strategy behaved consistently across baseline, near-prime expansion, and credit-stress scenarios.

Average challenger deltas:

```text
Delta offer exposure rate:       -2.97 percentage points
Delta approval rate:             -1.39 percentage points
Delta counteroffer rate:         -1.57 percentage points
Delta decline rate:              +5.48 percentage points
Delta approved amount:           -$184.66M
Delta approved Expected Loss:    -$8.75M
Delta approved EL rate:          -0.180 percentage points
```

The strongest example is **CG12 / CREDIT_STRESS_SCORE_MIX**, where tighter risk moved:

```text
Offer exposure:        -3.08 pp
Decline rate:          +7.26 pp
Approved amount:       -$181.78M
Approved Expected Loss:-$9.41M
Approved EL rate:      -0.252 pp
Offer-row PD proxy:    -1.50 pp
```

Executive lesson: **tightening synthetic-risk thresholds does not merely reduce approvals; it materially improves the risk profile of the offered population.**

---

## Core lesson 3 — Growth strategy expands access, but the tradeoff is visible and measurable

Growth strategy behaved exactly as expected.

Average challenger deltas:

```text
Delta offer exposure rate:       +3.08 percentage points
Delta approval rate:             +6.49 percentage points
Delta decline rate:              -3.46 percentage points
Delta approved amount:           +$259.21M
Delta approved Expected Loss:    +$9.13M
Delta approved EL rate:          +0.125 percentage points
```

The cleanest examples:

```text
M2-03 / BASELINE_V2 / GROWTH_ORIENTED_STRATEGY
Offer exposure:        63.70%
Approved amount:       $4.117B
Approved EL:           $67.77M
Approved EL rate:      1.646%

M2-13 / RATE_DOWN_200BP / GROWTH_ORIENTED_STRATEGY
Offer exposure:        63.56%
Approved amount:       $4.272B
Approved EL:           $68.73M
Approved EL rate:      1.609%
```

Executive lesson: **growth strategy increased access and approved exposure, but it did not hide the risk cost.** The campaign quantified the tradeoff in dollars and rates.

---

## Core lesson 4 — Affordability tightening lowers exposure and PTI, but it is not a pure EL-rate reducer

Tighter affordability strategy performed as an affordability-control strategy rather than a simple risk-minimization strategy.

Average challenger deltas:

```text
Delta offer exposure rate:        -3.26 percentage points
Delta approval rate:              -3.38 percentage points
Delta manual-review rate:         +1.85 percentage points
Delta decline rate:               +1.41 percentage points
Delta approved amount:            -$284.28M
Delta approved Expected Loss:     -$3.82M
Delta approved EL rate:           +0.016 percentage points
Delta approved PTI on offer rows: -0.356 percentage points
```

Under rate stress:

```text
M2-11 / RATE_UP_200BP / TIGHTER_AFFORDABILITY_STRATEGY
Offer exposure:        57.78%
Approved amount:       $3.484B
Approved EL:           $54.54M

M2-12 / RATE_UP_300BP / TIGHTER_AFFORDABILITY_STRATEGY
Offer exposure:        57.71%
Approved amount:       $3.442B
Approved EL:           $54.36M
```

Executive lesson: **affordability tightening reduced approved exposure and approved PTI, but mix effects can keep approved EL rate from declining mechanically.** This is realistic credit-strategy behavior: affordability controls may reduce exposure while concentrating remaining offers in different risk/product mixes.

---

## Core lesson 5 — Counteroffer-first strategy is the cleanest access-preserving exposure-management lever

Counteroffer-first strategy was especially compelling because it increased counteroffers while reducing approved exposure and approved Expected Loss.

Across its three comparison contexts, it delivered:

```text
Average delta offer exposure rate:      +1.08 percentage points
Average delta approval rate:            -2.28 percentage points
Average delta counteroffer rate:        +3.36 percentage points
Average delta approved amount:          -$209.18M
Average delta approved Expected Loss:   -$5.00M
Average delta approved PTI:             -0.927 percentage points
```

The Section 17.17 counteroffer effect check was clean:

```text
M2-05 vs M2-01:
    +1,910 counteroffers
    +3.82 pp counteroffer rate
    +$283.42M exposure reduction
    -1.32 pp approved PTI
    -$364 average approved EL per final counteroffer

M2-18 vs M2-16:
    +1,551 counteroffers
    +3.10 pp counteroffer rate
    +$297.92M exposure reduction
    -1.36 pp approved PTI
    -$408 average approved EL per final counteroffer

M2-29 vs M2-28:
    +1,576 counteroffers
    +3.15 pp counteroffer rate
    +$329.09M exposure reduction
    -1.33 pp approved PTI
    -$341 average approved EL per final counteroffer
```

Executive lesson: **counteroffer-first did not simply decline more applicants. It moved applicants from approval/manual-review pressure into reduced-exposure offers.**

---

## Core lesson 6 — Product guardrails worked surgically, but one parameter still needs correction

The product-specific guardrail strategy targeted:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

and left these products stable:

```text
MORTGAGE
HELOC
AUTO_LOAN
```

Section 17.16 confirms:

```text
Unaffected product stable rows:        15
Target product guardrail observed rows:10
Review rows:                           0
```

For affected products, the product guardrails reduced approved amount and approved Expected Loss:

```text
REVOLVING_LINE average approved amount reduction:           about -$20.39M
REVOLVING_LINE average approved EL reduction:               about -$1.29M

UNSECURED_PERSONAL_LOAN average approved amount reduction:  about -$23.30M
UNSECURED_PERSONAL_LOAN average approved EL reduction:      about -$1.21M
```

However, **M2-36 still has the product-policy exact-value mismatch**:

```text
BROAD_LGD_STRESS / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
UNSECURED_PERSONAL_LOAN product_decline_min_requested_el:
    actual   = 85,000
    expected = 8,500
```

Executive lesson: **the strategy effect is directionally right, but governance caught a parameter defect before final signoff.** That is a validation success, not just a coding problem. The exact-value audit did its job.

---

## Core lesson 7 — Manual-review reduction isolated exactly one operational lever

**M2-07 / MANUAL_REVIEW_REDUCTION_STRATEGY** is a clean demonstration of governed final-resolution behavior.

Relative to baseline:

```text
Delta offer exposure rate:       0.00 pp
Delta approval rate:             0.00 pp
Delta counteroffer rate:         0.00 pp
Delta manual-review rate:       -4.44 pp
Delta decline rate:             +4.44 pp
Delta approved amount:           $0
Delta approved Expected Loss:    $0
```

Executive lesson: **manual-review reduction did not alter positive-offer economics; it changed the disposition of failed / unresolved cases.** That is exactly what a `failed_counteroffer_resolution = DECLINE` strategy should demonstrate.

---

# Run-by-run executive observations

| Run | Scenario / strategy | Key metrics | Executive observation |
|---:|---|---:|---|
| M2-01 | Baseline / baseline strategy | Offer 60.72%; approved $3.880B; EL $58.93M; EL rate 1.519% | Baseline reference point. Balanced mix of approval and counteroffer; establishes the main frontier anchor. |
| M2-02 | Baseline / tighter risk | Offer 58.20%; decline 29.76%; approved EL $51.67M | Risk discipline worked: lower access, lower approved EL, lower offered-population risk. |
| M2-03 | Baseline / growth | Offer 63.70%; approval 28.84%; approved $4.117B; EL $67.77M | Growth expanded approvals and exposure with visible EL tradeoff. |
| M2-04 | Baseline / tighter affordability | Offer 57.53%; approved $3.605B; approved PTI 11.95% | Affordability tightened exposure and PTI but produced mixed risk-rate tradeoff. |
| M2-05 | Baseline / counteroffer-first | Counteroffer 41.95%; approved $3.690B; EL $54.71M | Counteroffer strategy preserved access while reducing exposure and EL. |
| M2-06 | Baseline / product guardrails | Offer 60.04%; approved $3.842B; EL $56.88M | Targeted guardrails reduced EL without broad disruption. |
| M2-07 | Baseline / manual-review reduction | Manual review 9.44%; decline 29.84%; economics unchanged | Cleanly converts unresolved review to decline without affecting offer economics. |
| M2-08 | Rate up 200 / baseline | Offer 61.04%; approved $3.772B; EL rate 1.549% | Rate stress modestly shifts affordability and approved economics. |
| M2-09 | Rate down 200 / baseline | Approval 24.51%; approved $3.991B | Rate relief improves approval and approved exposure. |
| M2-10 | Rate up 300 / baseline | Approval 20.99%; approved $3.732B; EL rate 1.562% | Higher rate stress compresses clean approval and approved amount. |
| M2-11 | Rate up 200 / affordability-tight | Offer 57.78%; approved $3.484B | Affordability strategy controls payment burden under rate stress. |
| M2-12 | Rate up 300 / affordability-tight | Offer 57.71%; approved $3.442B | Affordability tightening becomes more relevant as rate stress intensifies. |
| M2-13 | Rate down 200 / growth | Approval 31.23%; approved $4.272B; EL $68.73M | Rate relief plus growth strategy produces the strongest approval expansion. |
| M2-14 | Credit-box reference / baseline | Same as baseline reference | Confirms scenario-family baseline reference consistency. |
| M2-15 | Prime-growth mix / baseline | Offer 72.42%; approval 30.37%; EL rate 1.275% | Best access / lowest approved EL rate; stronger score mix is powerful. |
| M2-16 | Near-prime expansion / baseline | Offer 59.67%; EL $70.28M; EL rate 1.954% | Near-prime expansion materially raises approved EL pressure. |
| M2-17 | Near-prime / tighter risk | Offer 56.36%; EL $60.70M | Tighter risk reduces near-prime approved EL by $9.58M vs baseline. |
| M2-18 | Near-prime / counteroffer-first | Counteroffer 45.41%; approved $3.374B | Counteroffer treatment is especially active in near-prime expansion. |
| M2-19 | Credit stress / baseline | Offer 41.08%; decline 43.49%; EL rate 2.007% | Credit stress creates the harshest baseline risk profile. |
| M2-20 | Credit stress / tighter risk | Offer 37.99%; decline 50.75%; EL $40.23M | Tighter risk under stress sharply reduces approved EL but materially reduces access. |
| M2-21 | Portfolio mix reference / baseline | Same as baseline reference | Confirms product-mix reference anchor. |
| M2-22 | Unsecured growth / baseline | Approved $2.915B; EL $48.71M; EL rate 1.671% | Unsecured growth lowers approved amount but increases EL-rate pressure. |
| M2-23 | Unsecured growth / product guardrails | Approved $2.859B; EL $45.72M | Guardrails reduce unsecured-growth approved EL by about $2.99M. |
| M2-24 | Secured balance growth / baseline | Approved $5.041B; EL $71.74M | Highest approved amount; secured growth drives exposure scale. |
| M2-25 | Revolving expansion / baseline | Approved $2.866B; EL rate 1.659% | Revolving expansion has lower exposure scale but higher risk-rate pressure. |
| M2-26 | Revolving expansion / product guardrails | Approved $2.818B; EL $44.84M | Guardrails reduce revolving-expansion EL by about $2.71M. |
| M2-27 | Exposure baseline reference / baseline | Same as baseline reference | Confirms exposure-intensity reference anchor. |
| M2-28 | High-balance appetite / baseline | Approved $4.142B; EL $61.33M | Higher requested exposure increases approved exposure and EL. |
| M2-29 | High-balance / counteroffer-first | Offer 60.57%; approved $3.926B; EL $56.45M | Counteroffer-first offsets high-balance pressure: -$215.5M approved amount and -$4.88M EL vs baseline. |
| M2-30 | Low-balance conservative / baseline | Approval 30.24%; approved $3.382B; EL $52.72M | Lower requested exposure improves approval rate while lowering approved dollars. |
| M2-31 | LGD reference / baseline | Same as baseline reference | Confirms LGD reference anchor. |
| M2-32 | Secured severity stress / baseline | Approved $3.634B; EL $65.92M | Secured LGD stress raises EL materially while reducing approved exposure. |
| M2-33 | Unsecured severity stress / baseline | Approved $3.872B; EL $59.45M | Unsecured severity stress has modest portfolio-level EL lift versus broad/secured stress. |
| M2-34 | Unsecured severity / guardrails | Approved $3.834B; EL $57.06M | Guardrails reduce unsecured-severity EL by about $2.38M. |
| M2-35 | Broad LGD stress / baseline | Approved $3.626B; EL $66.43M; EL rate 1.832% | Broad LGD stress produces one of the highest EL rates. |
| M2-36 | Broad LGD stress / product guardrails | Approved $3.588B; EL $64.05M | Directionally reduces EL, but product-policy snapshot still has UPL 85,000 vs 8,500 mismatch. Rerun needed before final signoff. |

---

## Final executive summary

This campaign demonstrated a governed synthetic credit strategy engine capable of producing stable, comparable, explainable strategy outcomes across a large multi-scenario run plan.

The strongest evidence points are:

```text
1. 36 strategy / scenario slices archived cleanly.
2. 1.8M archived applicant-level strategy rows validated.
3. 0 archive grain duplicates.
4. 0 full-archive final-output convention violations.
5. 17 of 17 comparison groups ready.
6. 17 of 17 matched comparisons source-field consistent.
7. 36 of 36 executive evidence rows captured.
8. 36 of 36 parameter snapshots captured.
9. 36 of 36 product × score evidence sets captured.
10. Product guardrail exact-value audit caught one remaining parameter issue before final acceptance.
```

The campaign’s strategic findings are also clear:

```text
Tighter synthetic risk:
    best for approved EL reduction and offered-population risk improvement.

Growth oriented:
    best for access and approved exposure expansion, with clear EL cost.

Tighter affordability:
    best for payment-burden control, especially under rate stress.

Counteroffer first:
    best access-preserving exposure-management lever.

Product guardrails:
    targeted unsecured / revolving tightening works, but M2-36 parameter snapshot must be corrected.

Manual-review reduction:
    cleanly shifts unresolved review to final decline without altering positive-offer economics.
```

My final validation position is:

```text
MODULE 2 CAMPAIGN:
    analytically strong,
    structurally clean,
    comparison-ready,
    convention-clean,
    evidence-complete,
    but not final-acceptance clean until M2-36 product guardrail parameter mismatch is corrected.
```

Once M2-36 is corrected and Section 17.20 returns:

```text
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```

this campaign will be ready to support the Module 2 Validation Summary and final executive story package.
<!-- END_MESSAGE C038-M01356 -->


---

<a id="c038-m01358"></a>

### C038-M01358

**Andrew** · 2026-05-11T22:47:22.795000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01358 -->
hmm...i am positive for all 5 product guardrail runs I just performed that I had it as 8,500 and not 85,000.  is it possible the M2-36 didn't overwrite upon the re-run?  i will try one more time to re-do M2-36.  can you give me something to validate afterwards that it is correct this time before i re-output section 17?
<!-- END_MESSAGE C038-M01358 -->


---

<a id="c038-m01366"></a>

### C038-M01366

**Andrew** · 2026-05-11T23:46:32.547000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01366 -->
review updated section 17 QA (i fixed M2-36). perform an elite validation review and then provide an executive narrative of what we learned in this campaign. cite interesting lessons/observations/executive summary from each run and include key metrics to prove the story. if possible, add useful charts to help tell the story more clearly.
<!-- END_MESSAGE C038-M01366 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.13_QA_post_campaign_audit_matched_comparison_source_field_consistency(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.12_QA_post_campaign_audit_comparison_registry_readiness(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.11_QA_post_campaign_audit_validation_review_concentration(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.10_QA_post_campaign_audit_validation_status_summary_by_campaign_run(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.9_QA_post_campaign_audit_full_archive_final_output_convention_checks(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.8_QA_post_campaign_audit_evidence_coverage_detail_by_run(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.7_QA_post_campaign_audit_confirm_evidence_exists_for_all_campaign_runs(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.6_QA_post_campaign_audit_archive_slices_without_active_campaign_registry_row_expected_result_zero_rows(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.5_QA_post_campaign_audit_registry_runs_missing_or_mismatched_in_archive_expected_result_zero_rows(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.4_QA_post_campaign_audit_registry_to_archive_reconciliation(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.3_QA_post_campaign_audit_archive_grain_dupicate_check(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.2_QA_post_campaign_audit_archive_slice_detail(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.1_QA_post_campaign_audit_archive_campaign_inventory(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.20_QA_post_campaign_audit_final_campaign_acceptance_rollup(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.19_QA_post_campaign_audit_product_guardrail_policy_snapshot_exact_value(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.18_QA_post_campaign_audit_parameter_snapshot_profile(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.17_QA_post_campaign_audit_counteroffer_first_strategy_effect_check(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.16_QA_post_campaign_audit_product_guardrail_strategy_effect_check(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.15_QA_post_campaign_audit_baseline_x_challenger_delta_summary_for_all_comparison_groups(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.14_QA_post_campaign_audit_executive_evidence_campaign_summary(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_67.md) · [Next](Part_69.md)
