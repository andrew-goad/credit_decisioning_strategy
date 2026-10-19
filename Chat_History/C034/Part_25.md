# Module 1 Synthetic Application Portfolio Build

## Part 25

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_24.md) · [Next](Part_26.md)

<a id="c034-m01182"></a>

### C034-M01182

**ChatGPT** · 2026-05-16T21:12:16.711541-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01182 -->
According to a document from **2026-05-17**, your current Section 17.1 is the compact archive campaign inventory row, and Section 17.2 is the one-row-per-active-registry-run archive slice detail output. fileciteturn294file17 fileciteturn294file15

The easiest implementation is to **replace the full existing Section 17.1 and full existing Section 17.2** with the two blocks below.

These updates do **not** change the archive acceptance logic. They add Option C visibility fields only.

---

# Replace Section 17.1 with this

```sql
/***************************************************************************************************
SECTION 17.1 — MODULE 2 ARCHIVE CAMPAIGN INVENTORY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that active campaign registry runs have matching archived strategy slices, and that each
    archived slice matches the row count of its selected Module 1 source population.

SQL PURPOSE:
    1. Read active campaign registry runs.
    2. Derive expected source population row counts from the Module 1 scenario archive.
    3. Read archived Module 2 strategy slice counts.
    4. Compare archived row counts and distinct application_id counts to expected Module 1 source
       counts.
    5. Surface Option C selective/aggressive counteroffer strategy split evidence at campaign level.
    6. Return one compact campaign inventory status row.

DYNAMIC ACCEPTANCE PRINCIPLE:
    The expected archived row count is not hardcoded.

    For every active campaign registry run:

        expected_module1_source_rows =
            COUNT(*)
            FROM credit_decisioning_sim.synthetic_applications_scenario_archive
            WHERE scenario_set_name = module1_scenario_set_name
              AND scenario_name = module1_scenario_name
              AND population_id = population_id

OPTION C VISIBILITY NOTE:
    The Option C fields in this inventory are visibility fields.

    They show whether the completed active campaign archive includes:
        SELECTIVE_FEASIBILITY slices,
        AGGRESSIVE_EXPANSION slices,
        ordinary counteroffer candidate rows,
        and aggressive requested-structure override rows.

    These fields are not acceptance conditions by themselves.

    Acceptance still depends on:
        source-count availability,
        archive slice availability,
        row-count match,
        and application_id grain integrity.

EXPECTED RESULT:
    active_campaign_registry_rows > 0
    module1_source_count_missing_runs = 0
    registry_runs_missing_archive_rows = 0
    registry_runs_with_archive_row_count_mismatch = 0
    registry_runs_with_duplicate_application_ids = 0
    archive_campaign_inventory_status = MODULE_2_ARCHIVE_INVENTORY_READY

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

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        strategy_set_name,
        strategy_name,
        strategy_version
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
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

        /*******************************************************************************************
        Option C counteroffer strategy split archive visibility.

        These fields summarize row-level Option C evidence at the archived strategy / scenario /
        population slice grain before Section 17 rolls that evidence up to campaign level.
        *******************************************************************************************/
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
),

registry_archive_join AS (
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

        s.expected_module1_source_rows,
        s.expected_module1_distinct_application_id_count,

        COALESCE(a.archived_rows, 0) AS archived_rows,
        COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count,

        a.counteroffer_strategy_variant,
        COALESCE(a.aggressive_counteroffer_expansion_enabled, FALSE)
            AS aggressive_counteroffer_expansion_enabled,

        COALESCE(a.ordinary_counteroffer_candidate_rows, 0)
            AS ordinary_counteroffer_candidate_rows,

        COALESCE(a.aggressive_override_rows, 0)
            AS aggressive_override_rows,

        COALESCE(a.aggressive_override_final_counteroffer_rows, 0)
            AS aggressive_override_final_counteroffer_rows,

        COALESCE(a.aggressive_override_final_manual_review_rows, 0)
            AS aggressive_override_final_manual_review_rows,

        COALESCE(a.aggressive_override_final_decline_rows, 0)
            AS aggressive_override_final_decline_rows,

        a.first_archive_inserted_ts,
        a.last_archive_inserted_ts

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
)

SELECT
    COUNT(*) AS active_campaign_registry_rows,

    COUNT(DISTINCT (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) AS distinct_module1_source_slices,

    COUNT(*) FILTER (
        WHERE expected_module1_source_rows IS NULL
    ) AS module1_source_count_missing_runs,

    SUM(COALESCE(expected_module1_source_rows, 0)) AS expected_total_active_campaign_source_rows,

    COUNT(*) FILTER (
        WHERE archived_rows > 0
    ) AS registry_runs_with_archive_rows,

    COUNT(*) FILTER (
        WHERE archived_rows = 0
    ) AS registry_runs_missing_archive_rows,

    SUM(archived_rows) AS total_active_campaign_archived_rows,

    COUNT(*) FILTER (
        WHERE expected_module1_source_rows IS NOT NULL
          AND archived_rows <> expected_module1_source_rows
    ) AS registry_runs_with_archive_row_count_mismatch,

    COUNT(*) FILTER (
        WHERE expected_module1_source_rows IS NOT NULL
          AND distinct_application_id_count <> expected_module1_source_rows
    ) AS registry_runs_with_duplicate_or_missing_application_ids,

    /***********************************************************************************************
    Option C campaign-level archive visibility.

    These fields help reviewers confirm that the completed active campaign archive contains the
    selective and aggressive counteroffer strategy evidence expected after Option C.

    They are not acceptance-status inputs in this section.
    ***********************************************************************************************/
    COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) FILTER (
        WHERE counteroffer_strategy_variant = 'SELECTIVE_FEASIBILITY'
    ) AS selective_feasibility_archived_slice_count,

    COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) FILTER (
        WHERE counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
    ) AS aggressive_expansion_archived_slice_count,

    COALESCE(SUM(ordinary_counteroffer_candidate_rows), 0)
        AS ordinary_counteroffer_candidate_archived_row_count,

    COALESCE(SUM(aggressive_override_rows), 0)
        AS aggressive_override_archived_row_count,

    COALESCE(SUM(aggressive_override_final_counteroffer_rows), 0)
        AS aggressive_override_final_counteroffer_archived_row_count,

    COALESCE(SUM(aggressive_override_final_manual_review_rows), 0)
        AS aggressive_override_final_manual_review_archived_row_count,

    COALESCE(SUM(aggressive_override_final_decline_rows), 0)
        AS aggressive_override_final_decline_archived_row_count,

    MIN(first_archive_inserted_ts) AS first_campaign_archive_inserted_ts,
    MAX(last_archive_inserted_ts) AS last_campaign_archive_inserted_ts,

    CASE
        WHEN COUNT(*) = 0
            THEN 'REVIEW_NO_ACTIVE_CAMPAIGN_REGISTRY_RUNS'

        WHEN COUNT(*) FILTER (WHERE expected_module1_source_rows IS NULL) > 0
            THEN 'REVIEW_MODULE1_SOURCE_COUNTS_MISSING'

        WHEN COUNT(*) FILTER (WHERE archived_rows = 0) > 0
            THEN 'REVIEW_CAMPAIGN_ARCHIVE_MISSING_RUNS'

        WHEN COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND archived_rows <> expected_module1_source_rows
        ) > 0
            THEN 'REVIEW_CAMPAIGN_ARCHIVE_ROW_COUNT_MISMATCH'

        WHEN COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND distinct_application_id_count <> expected_module1_source_rows
        ) > 0
            THEN 'REVIEW_CAMPAIGN_ARCHIVE_APPLICATION_ID_GRAIN'

        ELSE 'MODULE_2_ARCHIVE_INVENTORY_READY'
    END AS archive_campaign_inventory_status

FROM registry_archive_join;
```

---

# Replace Section 17.2 with this

```sql
/***************************************************************************************************
SECTION 17.2 — MODULE 2 ARCHIVE SLICE DETAIL
****************************************************************************************************

BUSINESS PURPOSE:
    Display every active campaign registry run and its matching archived strategy slice so reviewers
    can confirm run-by-run archive completeness.

SQL PURPOSE:
    Produce one row per active campaign registry run with:
        registry IDs,
        Module 1 source lineage,
        Module 2 strategy identity,
        expected Module 1 source row count,
        archived row count,
        distinct archived application count,
        row-count gap,
        application-id grain gap,
        Option C ordinary-versus-aggressive counteroffer path evidence,
        and archive readiness status.

OPTION C VISIBILITY NOTE:
    This section surfaces Option C fields at the same grain as the archive slice detail:

        one row per active campaign registry run.

    These fields help reviewers see whether each archived slice behaved as:
        NOT_COUNTEROFFER_SPLIT_STRATEGY,
        SELECTIVE_FEASIBILITY,
        or AGGRESSIVE_EXPANSION.

    They also show how many archived rows entered:
        ordinary counteroffer candidacy,
        aggressive requested-structure override routing,
        final COUNTEROFFER through aggressive override,
        final MANUAL_REVIEW through aggressive override,
        and final DECLINE through aggressive override.

    These fields improve reviewability without changing archive grain or acceptance logic.

EXPECTED RESULT:
    One row per active campaign registry run.

    Each row should generally show:
        archived_rows = expected_module1_source_rows
        distinct_application_id_count = expected_module1_source_rows
        archive_slice_detail_status = ARCHIVE_SLICE_READY

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

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        strategy_set_name,
        strategy_name,
        strategy_version
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE registry_active_flag IS TRUE
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

        /*******************************************************************************************
        Strategy run audit metadata.

        strategy_run_id is not archive grain and is not a replacement key.

        MIN / MAX are shown only to help reviewers detect whether a slice appears to mix multiple run
        audit identifiers.
        *******************************************************************************************/
        MIN(strategy_run_id) AS min_strategy_run_id,
        MAX(strategy_run_id) AS max_strategy_run_id,

        /*******************************************************************************************
        Option C counteroffer strategy split detail.

        MAX(counteroffer_strategy_variant):
            The slice-level Option C variant label.

            Under normal campaign execution, each archived slice should have one consistent value.

        BOOL_OR(aggressive_counteroffer_expansion_enabled):
            Shows whether the archived slice used the aggressive expansion posture.

        Ordinary / aggressive row counts:
            Provide applicant-level evidence rollups without changing the archive slice grain.
        *******************************************************************************************/
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
    r.run_sequence_number,
    r.module1_run_id,
    r.module2_run_id,
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

    s.expected_module1_source_rows,
    s.expected_module1_distinct_application_id_count,

    COALESCE(a.archived_rows, 0) AS archived_rows,
    COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count,

    COALESCE(a.archived_rows, 0)
        - COALESCE(s.expected_module1_source_rows, 0)
            AS archived_row_count_gap,

    COALESCE(a.distinct_application_id_count, 0)
        - COALESCE(s.expected_module1_source_rows, 0)
            AS application_id_count_gap,

    a.min_strategy_run_id,
    a.max_strategy_run_id,

    /***********************************************************************************************
    Option C archive slice detail.

    These fields are diagnostic visibility fields.

    They help confirm whether each active campaign archive slice carried the ordinary-versus-
    aggressive counteroffer evidence expected after Option C.
    ***********************************************************************************************/
    a.counteroffer_strategy_variant,
    COALESCE(a.aggressive_counteroffer_expansion_enabled, FALSE)
        AS aggressive_counteroffer_expansion_enabled,

    COALESCE(a.ordinary_counteroffer_candidate_rows, 0)
        AS ordinary_counteroffer_candidate_rows,

    COALESCE(a.aggressive_override_rows, 0)
        AS aggressive_override_rows,

    COALESCE(a.aggressive_override_final_counteroffer_rows, 0)
        AS aggressive_override_final_counteroffer_rows,

    COALESCE(a.aggressive_override_final_manual_review_rows, 0)
        AS aggressive_override_final_manual_review_rows,

    COALESCE(a.aggressive_override_final_decline_rows, 0)
        AS aggressive_override_final_decline_rows,

    a.first_archive_inserted_ts,
    a.last_archive_inserted_ts,

    CASE
        WHEN s.expected_module1_source_rows IS NULL
            THEN 'REVIEW_MODULE1_SOURCE_COUNT_MISSING'

        WHEN COALESCE(a.archived_rows, 0) = 0
            THEN 'REVIEW_ARCHIVE_SLICE_MISSING'

        WHEN COALESCE(a.archived_rows, 0) <> s.expected_module1_source_rows
            THEN 'REVIEW_ARCHIVE_SLICE_ROW_COUNT_MISMATCH'

        WHEN COALESCE(a.distinct_application_id_count, 0) <> s.expected_module1_source_rows
            THEN 'REVIEW_ARCHIVE_SLICE_APPLICATION_ID_GRAIN'

        ELSE 'ARCHIVE_SLICE_READY'
    END AS archive_slice_detail_status

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

ORDER BY
    r.run_sequence_number,
    r.module2_run_id,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version;
```

---

These two replacements keep the original Section 17.1 / 17.2 acceptance posture intact:

```text
17.1 remains the compact campaign inventory status row.
17.2 remains the run-by-run archive slice detail.
```

The Option C fields are added as **visibility and interpretation fields**, not as new archive-grain keys and not as new row-count acceptance criteria.
<!-- END_MESSAGE C034-M01182 -->


---

<a id="c034-m01183"></a>

### C034-M01183

**Andrew** · 2026-05-16T21:26:35.917000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01183 -->
make this implementation easier (give full 17.7 and 17.8 copy paste - current versions attached): This is the most important update in the first half of Section 17.

The current evidence coverage logic already checks executive evidence, parameter evidence, validation evidence, and segment evidence. It also dynamically derives expected validation keys and expected segment rows rather than hardcoding counts.

Now it should also confirm that the executive evidence row contains Option C frontier evidence.

Add to the executive_evidence CTE in 17.7 / 17.8

Inside the CTE that summarizes credit_decisioning_sim.strategy_run_evidence_summary, add:

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

Do not require these fields to be non-null in Section 17.7:

delta_ordinary_counteroffer_candidate_rate
delta_aggressive_override_rate
delta_aggressive_override_final_counteroffer_rate
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
avg_approved_pti_for_aggressive_override_counteroffers
avg_approved_el_for_aggressive_override_counteroffers

Those can legitimately be NULL when no baseline reference exists or no aggressive override final counteroffers exist.

Add to the final SELECT in 17.7 / 17.8
COALESCE(e.option_c_executive_evidence_gap_rows, 0)
    AS option_c_executive_evidence_gap_rows,
Add to evidence_capture_status

Add this condition to the EVIDENCE_CAPTURE_READY branch:

AND COALESCE(e.option_c_executive_evidence_gap_rows, 0) = 0

So the acceptance logic becomes:

evidence exists
validation evidence complete
segment evidence complete
parameter evidence complete
Option C executive evidence complete
Add these fields to Section 17.8 detail output

If Section 17.8 displays run-by-run evidence coverage, include the executive Option C fields:

e.counteroffer_strategy_variant,
e.aggressive_counteroffer_expansion_enabled,
e.ordinary_counteroffer_candidate_rows,
e.ordinary_counteroffer_candidate_rate,
e.aggressive_override_rows,
e.aggressive_override_rate,
e.aggressive_override_final_counteroffer_rows,
e.aggressive_override_final_counteroffer_rate,
e.aggressive_override_final_manual_review_rows,
e.aggressive_override_final_manual_review_rate,
e.aggressive_override_final_decline_rows,
e.aggressive_override_final_decline_rate,
e.option_c_frontier_posture_type,
e.option_c_frontier_interpretation_note,
COALESCE(e.option_c_executive_evidence_gap_rows, 0)
    AS option_c_executive_evidence_gap_rows

This is the right place to confirm that Section 16.6 / 16.9 successfully persisted and synchronized Option C evidence.
<!-- END_MESSAGE C034-M01183 -->


**Attachments in export:** `Pasted text(212).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01184"></a>

### C034-M01184

**ChatGPT** · 2026-05-16T21:30:40.426188-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01184 -->
According to a document from **2026-05-17**, your current Section 17.7 / 17.8 already uses the right dynamic evidence-coverage design: it derives expected validation evidence keys and expected segment rows instead of hardcoding fixed counts. The replacement below keeps that design and adds the missing Option C executive-evidence completeness checks. fileciteturn297file19

Replace your full current **17.7** and **17.8** with this:

```sql
/***************************************************************************************************
SECTION 17.7 — SECTION 16 EVIDENCE COVERAGE SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that persistent Section 16 evidence exists for every active campaign registry run and
    that validation / segment evidence is complete relative to dynamically derived evidence spines.

EVIDENCE TABLES CHECKED:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

DYNAMIC VALIDATION EVIDENCE DESIGN:
    expected_validation_key_count is derived from distinct validation keys present across active
    campaign runs:

        validation_area
        validation_test_name
        validation_category

    This avoids hardcoding the Section 14 validation spine row count.

DYNAMIC SEGMENT EVIDENCE DESIGN:
    expected_segment_rows is derived for each run from its archived strategy slice:

        product_type_policy_key
        score_band_policy_key
        product_score_policy_segment

    This avoids assuming a fixed product × score segment count.

OPTION C EXECUTIVE EVIDENCE DESIGN:
    Section 16.6 captures Option C frontier fields into the persistent executive evidence row.

    Section 16.9 later synchronizes those fields from a fresh Section 15 run after the full campaign
    archive is complete.

    Section 17.7 therefore confirms that each active campaign run has populated Option C executive
    evidence fields, including:
        counteroffer_strategy_variant
        aggressive_counteroffer_expansion_enabled
        ordinary counteroffer candidate metrics
        aggressive override metrics
        aggressive override final outcome mix
        Option C frontier posture labels

    Important:
        Section 17.7 does not require baseline-relative Option C delta fields to be populated.

        These fields may legitimately be NULL when no matching baseline exists:
            delta_ordinary_counteroffer_candidate_rate
            delta_aggressive_override_rate
            delta_aggressive_override_final_counteroffer_rate

        Section 17.7 also does not require aggressive override average quality metrics to be
        populated.

        These fields may legitimately be NULL when no aggressive override final COUNTEROFFER rows
        exist:
            avg_exposure_reduction_pct_for_aggressive_override_counteroffers
            avg_approved_pti_for_aggressive_override_counteroffers
            avg_approved_el_for_aggressive_override_counteroffers

EXPECTED RESULT:
    registry_run_count > 0
    expected_validation_key_count > 0
    runs_with_one_executive_evidence_row = registry_run_count
    runs_with_one_parameter_snapshot_row = registry_run_count
    runs_with_complete_validation_evidence_rows = registry_run_count
    runs_with_complete_segment_evidence_rows = registry_run_count
    runs_with_complete_option_c_executive_evidence = registry_run_count
    evidence_coverage_issue_count = 0
    evidence_campaign_status = SECTION_16_EVIDENCE_COVERAGE_READY

***************************************************************************************************/

WITH registry_runs AS (
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

    FROM registry_runs r

    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id

    GROUP BY r.module2_run_id
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

        /*******************************************************************************************
        Option C executive evidence completeness.

        These fields are expected to be populated in the one-row executive evidence summary after
        Section 16.6 / Section 16.9.

        Do not include baseline-relative delta fields or aggressive override average quality metrics
        in this required-field check because they may be legitimately NULL.
        *******************************************************************************************/
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

validation_key_catalog AS (
    SELECT
        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS expected_validation_key_count

    FROM credit_decisioning_sim.strategy_run_validation_evidence v

    JOIN registry_runs r
        ON r.strategy_set_name = v.strategy_set_name
       AND r.strategy_name = v.strategy_name
       AND r.strategy_version = v.strategy_version
       AND r.module1_scenario_set_name = v.module1_scenario_set_name
       AND r.module1_scenario_name = v.module1_scenario_name
       AND r.population_id = v.population_id
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
        )) AS duplicate_validation_key_rows

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

joined AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(e.option_c_executive_evidence_gap_rows, 0)
            AS option_c_executive_evidence_gap_rows,

        COALESCE(p.parameter_rows, 0) AS parameter_rows,

        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(v.validation_distinct_key_count, 0) AS validation_distinct_key_count,
        COALESCE(v.duplicate_validation_key_rows, 0) AS duplicate_validation_key_rows,

        COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,

        COALESCE(ase.expected_segment_rows, 0) AS expected_segment_rows,

        COALESCE(s.segment_rows, 0) AS segment_rows,
        COALESCE(s.segment_distinct_key_count, 0) AS segment_distinct_key_count,
        COALESCE(s.duplicate_segment_key_rows, 0) AS duplicate_segment_key_rows

    FROM registry_runs r

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
)

SELECT
    COUNT(*) AS registry_run_count,

    MAX(expected_validation_key_count)
        AS expected_validation_key_count,

    /***********************************************************************************************
    Executive evidence coverage.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE executive_rows = 1
    ) AS runs_with_one_executive_evidence_row,

    COUNT(*) FILTER (
        WHERE executive_rows <> 1
    ) AS runs_with_missing_or_duplicate_executive_evidence_rows,

    COUNT(*) FILTER (
        WHERE executive_rows = 1
          AND option_c_executive_evidence_gap_rows = 0
    ) AS runs_with_complete_option_c_executive_evidence,

    COUNT(*) FILTER (
        WHERE executive_rows = 1
          AND option_c_executive_evidence_gap_rows > 0
    ) AS runs_with_option_c_executive_evidence_gaps,

    SUM(option_c_executive_evidence_gap_rows)
        AS total_option_c_executive_evidence_gap_rows,

    /***********************************************************************************************
    Parameter evidence coverage.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE parameter_rows = 1
    ) AS runs_with_one_parameter_snapshot_row,

    COUNT(*) FILTER (
        WHERE parameter_rows <> 1
    ) AS runs_with_missing_or_duplicate_parameter_snapshot_rows,

    /***********************************************************************************************
    Validation evidence coverage.

    expected_validation_key_count is dynamic and comes from the persisted validation evidence key
    set across active campaign runs.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE expected_validation_key_count > 0
          AND validation_rows = expected_validation_key_count
          AND validation_distinct_key_count = expected_validation_key_count
          AND duplicate_validation_key_rows = 0
    ) AS runs_with_complete_validation_evidence_rows,

    COUNT(*) FILTER (
        WHERE expected_validation_key_count = 0
           OR validation_rows <> expected_validation_key_count
           OR validation_distinct_key_count <> expected_validation_key_count
           OR duplicate_validation_key_rows <> 0
    ) AS runs_with_incomplete_validation_evidence_rows,

    MIN(validation_rows) AS min_validation_rows_per_run,
    MAX(validation_rows) AS max_validation_rows_per_run,

    /***********************************************************************************************
    Product × score segment evidence coverage.

    expected_segment_rows is dynamic and comes from each run's archived strategy slice.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE expected_segment_rows > 0
          AND segment_rows = expected_segment_rows
          AND segment_distinct_key_count = expected_segment_rows
          AND duplicate_segment_key_rows = 0
    ) AS runs_with_complete_segment_evidence_rows,

    COUNT(*) FILTER (
        WHERE expected_segment_rows = 0
           OR segment_rows <> expected_segment_rows
           OR segment_distinct_key_count <> expected_segment_rows
           OR duplicate_segment_key_rows <> 0
    ) AS runs_with_incomplete_segment_evidence_rows,

    MIN(expected_segment_rows) AS min_expected_segment_rows_per_run,
    MAX(expected_segment_rows) AS max_expected_segment_rows_per_run,
    MIN(segment_rows) AS min_actual_segment_rows_per_run,
    MAX(segment_rows) AS max_actual_segment_rows_per_run,

    /***********************************************************************************************
    Overall evidence issue count.

    This now includes Option C executive evidence completeness.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE executive_rows <> 1
           OR parameter_rows <> 1
           OR expected_validation_key_count = 0
           OR validation_rows <> expected_validation_key_count
           OR validation_distinct_key_count <> expected_validation_key_count
           OR duplicate_validation_key_rows <> 0
           OR expected_segment_rows = 0
           OR segment_rows <> expected_segment_rows
           OR segment_distinct_key_count <> expected_segment_rows
           OR duplicate_segment_key_rows <> 0
           OR option_c_executive_evidence_gap_rows <> 0
    ) AS evidence_coverage_issue_count,

    CASE
        WHEN COUNT(*) = 0
            THEN 'REVIEW_NO_ACTIVE_CAMPAIGN_REGISTRY_RUNS'

        WHEN MAX(expected_validation_key_count) = 0
            THEN 'REVIEW_VALIDATION_EVIDENCE_KEY_CATALOG_MISSING'

        WHEN COUNT(*) FILTER (
            WHERE executive_rows = 1
              AND parameter_rows = 1
              AND expected_validation_key_count > 0
              AND validation_rows = expected_validation_key_count
              AND validation_distinct_key_count = expected_validation_key_count
              AND duplicate_validation_key_rows = 0
              AND expected_segment_rows > 0
              AND segment_rows = expected_segment_rows
              AND segment_distinct_key_count = expected_segment_rows
              AND duplicate_segment_key_rows = 0
              AND option_c_executive_evidence_gap_rows = 0
        ) = COUNT(*)
            THEN 'SECTION_16_EVIDENCE_COVERAGE_READY'

        ELSE 'REVIEW_SECTION_16_EVIDENCE_COVERAGE'
    END AS evidence_campaign_status

FROM joined;



/***************************************************************************************************
SECTION 17.8 — SECTION 16 EVIDENCE COVERAGE DETAIL BY RUN
****************************************************************************************************

BUSINESS PURPOSE:
    Display evidence counts for each individual campaign run and confirm complete evidence capture
    without relying on fixed campaign size, fixed validation-row count, or fixed segment-row count.

SQL PURPOSE:
    Provide one row per active campaign registry run with:
        executive evidence count,
        parameter snapshot count,
        validation evidence counts,
        derived expected validation key count,
        segment evidence counts,
        derived expected segment count,
        Option C executive evidence fields,
        Option C executive evidence completeness status,
        and per-run evidence capture status.

OPTION C DETAIL PURPOSE:
    This section confirms that Section 16.6 and Section 16.9 successfully persisted and synchronized
    the Option C frontier evidence needed to interpret:

        SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
        versus
        AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

    at the persistent executive evidence layer.

EXPECTED RESULT:
    One row per active campaign registry run.

    Each row should generally show:
        executive_rows = 1
        parameter_rows = 1
        validation_rows = expected_validation_key_count
        validation_evidence_row_gap = 0
        duplicate_validation_key_rows = 0
        segment_rows = expected_segment_rows
        segment_evidence_row_gap = 0
        duplicate_segment_key_rows = 0
        option_c_executive_evidence_gap_rows = 0
        evidence_capture_status = EVIDENCE_CAPTURE_READY

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

    FROM registry_runs r

    LEFT JOIN credit_decisioning_sim.strategy_decisions_archive a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id

    GROUP BY r.module2_run_id
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

        /*******************************************************************************************
        Option C executive evidence fields.

        MAX / BOOL_OR are used only because this CTE is grouped by run key.

        The normal expected pattern is exactly one executive evidence row per run key.
        If there are duplicates, Section 17.8 still surfaces representative values while the row-count
        fields identify the duplicate evidence issue.
        *******************************************************************************************/
        MAX(counteroffer_strategy_variant)
            AS counteroffer_strategy_variant,

        COALESCE(
            BOOL_OR(aggressive_counteroffer_expansion_enabled),
            FALSE
        ) AS aggressive_counteroffer_expansion_enabled,

        MAX(ordinary_counteroffer_candidate_rows)
            AS ordinary_counteroffer_candidate_rows,

        MAX(ordinary_counteroffer_candidate_rate)
            AS ordinary_counteroffer_candidate_rate,

        MAX(aggressive_override_rows)
            AS aggressive_override_rows,

        MAX(aggressive_override_rate)
            AS aggressive_override_rate,

        MAX(aggressive_override_final_counteroffer_rows)
            AS aggressive_override_final_counteroffer_rows,

        MAX(aggressive_override_final_counteroffer_rate)
            AS aggressive_override_final_counteroffer_rate,

        MAX(aggressive_override_final_manual_review_rows)
            AS aggressive_override_final_manual_review_rows,

        MAX(aggressive_override_final_manual_review_rate)
            AS aggressive_override_final_manual_review_rate,

        MAX(aggressive_override_final_decline_rows)
            AS aggressive_override_final_decline_rows,

        MAX(aggressive_override_final_decline_rate)
            AS aggressive_override_final_decline_rate,

        MAX(option_c_frontier_posture_type)
            AS option_c_frontier_posture_type,

        MAX(option_c_frontier_interpretation_note)
            AS option_c_frontier_interpretation_note,

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

validation_key_catalog AS (
    SELECT
        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS expected_validation_key_count

    FROM credit_decisioning_sim.strategy_run_validation_evidence v

    JOIN registry_runs r
        ON r.strategy_set_name = v.strategy_set_name
       AND r.strategy_name = v.strategy_name
       AND r.strategy_version = v.strategy_version
       AND r.module1_scenario_set_name = v.module1_scenario_set_name
       AND r.module1_scenario_name = v.module1_scenario_name
       AND r.population_id = v.population_id
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
        )) AS duplicate_validation_key_rows

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
)

SELECT
    r.run_sequence_number,
    r.module2_run_id,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,

    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    /***********************************************************************************************
    Evidence row-count checks.
    ***********************************************************************************************/
    COALESCE(e.executive_rows, 0) AS executive_rows,
    COALESCE(p.parameter_rows, 0) AS parameter_rows,

    COALESCE(v.validation_rows, 0) AS validation_rows,
    COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,

    COALESCE(v.validation_rows, 0)
        - COALESCE(vkc.expected_validation_key_count, 0)
            AS validation_evidence_row_gap,

    COALESCE(v.validation_distinct_key_count, 0)
        AS validation_distinct_key_count,

    COALESCE(v.duplicate_validation_key_rows, 0)
        AS duplicate_validation_key_rows,

    COALESCE(ase.expected_segment_rows, 0)
        AS expected_segment_rows,

    COALESCE(s.segment_rows, 0)
        AS segment_rows,

    COALESCE(s.segment_rows, 0)
        - COALESCE(ase.expected_segment_rows, 0)
            AS segment_evidence_row_gap,

    COALESCE(s.segment_distinct_key_count, 0)
        AS segment_distinct_key_count,

    COALESCE(s.duplicate_segment_key_rows, 0)
        AS duplicate_segment_key_rows,

    /***********************************************************************************************
    Option C executive evidence fields.

    These values come from credit_decisioning_sim.strategy_run_evidence_summary and confirm that
    Section 16 captured / synchronized the selective-versus-aggressive counteroffer frontier evidence.
    ***********************************************************************************************/
    e.counteroffer_strategy_variant,
    e.aggressive_counteroffer_expansion_enabled,

    e.ordinary_counteroffer_candidate_rows,
    e.ordinary_counteroffer_candidate_rate,

    e.aggressive_override_rows,
    e.aggressive_override_rate,

    e.aggressive_override_final_counteroffer_rows,
    e.aggressive_override_final_counteroffer_rate,

    e.aggressive_override_final_manual_review_rows,
    e.aggressive_override_final_manual_review_rate,

    e.aggressive_override_final_decline_rows,
    e.aggressive_override_final_decline_rate,

    e.option_c_frontier_posture_type,
    e.option_c_frontier_interpretation_note,

    COALESCE(e.option_c_executive_evidence_gap_rows, 0)
        AS option_c_executive_evidence_gap_rows,

    /***********************************************************************************************
    Per-run evidence capture status.

    EVIDENCE_CAPTURE_READY now requires:
        one executive evidence row,
        one parameter snapshot row,
        complete validation evidence,
        complete segment evidence,
        and complete required Option C executive evidence fields.
    ***********************************************************************************************/
    CASE
        WHEN COALESCE(e.executive_rows, 0) = 1
         AND COALESCE(p.parameter_rows, 0) = 1
         AND COALESCE(vkc.expected_validation_key_count, 0) > 0
         AND COALESCE(v.validation_rows, 0) = COALESCE(vkc.expected_validation_key_count, 0)
         AND COALESCE(v.validation_distinct_key_count, 0) = COALESCE(vkc.expected_validation_key_count, 0)
         AND COALESCE(v.duplicate_validation_key_rows, 0) = 0
         AND COALESCE(ase.expected_segment_rows, 0) > 0
         AND COALESCE(s.segment_rows, 0) = COALESCE(ase.expected_segment_rows, 0)
         AND COALESCE(s.segment_distinct_key_count, 0) = COALESCE(ase.expected_segment_rows, 0)
         AND COALESCE(s.duplicate_segment_key_rows, 0) = 0
         AND COALESCE(e.option_c_executive_evidence_gap_rows, 0) = 0
            THEN 'EVIDENCE_CAPTURE_READY'

        ELSE 'EVIDENCE_CAPTURE_REVIEW_REQUIRED'
    END AS evidence_capture_status

FROM registry_runs r

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

ORDER BY
    r.run_sequence_number,
    r.module2_run_id;
```

The main implementation changes are:

```text
17.7:
    Adds option_c_executive_evidence_gap_rows to executive_evidence.
    Adds runs_with_complete_option_c_executive_evidence.
    Adds runs_with_option_c_executive_evidence_gaps.
    Adds Option C evidence completeness to evidence_coverage_issue_count.
    Adds Option C evidence completeness to SECTION_16_EVIDENCE_COVERAGE_READY.

17.8:
    Carries the actual Option C executive fields into the run-by-run detail.
    Adds option_c_executive_evidence_gap_rows.
    Adds Option C evidence completeness to EVIDENCE_CAPTURE_READY.
```

This keeps Section 17.7 / 17.8 aligned with the post-Option-C evidence chain:

```text
Section 15 creates Option C frontier evidence.
Section 16.6 captures it.
Section 16.9 synchronizes it.
Section 17.7 / 17.8 confirms it exists for every active campaign run.
```
<!-- END_MESSAGE C034-M01184 -->


---

<a id="c034-m01186"></a>

### C034-M01186

**Andrew** · 2026-05-16T21:40:34.076000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01186 -->
do I also include + option_c_archive_field_gap_rows
+ aggressive_override_reason_trace_gap_rows
+ selective_strategy_aggressive_override_rows in the active_campaign_archive_convention_status?
<!-- END_MESSAGE C034-M01186 -->


---

<a id="c034-m01188"></a>

### C034-M01188

**ChatGPT** · 2026-05-16T21:42:34.141713-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01188 -->
According to a document from **2026-05-17**, yes — you should include all three of these in `active_campaign_archive_convention_status` **if they are included in `critical_convention_violation_count`**. The current 17.9 status logic repeats the convention-violation sum inside the `CASE`; if you add Option C rows to `critical_convention_violation_count` but not to the status `CASE`, the output could show a nonzero critical violation count while still returning `ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY`. fileciteturn300file2

Use this rule:

```text
If a field is part of critical_convention_violation_count,
it must also be part of the active_campaign_archive_convention_status READY test.
```

So yes, include:

```sql
+ option_c_archive_field_gap_rows
+ aggressive_override_reason_trace_gap_rows
+ selective_strategy_aggressive_override_rows
```

in both places.

Replace the end of the Section 17.9 final `SELECT` with this pattern:

```sql
SELECT
    active_campaign_archived_rows,

    final_outcome_flag_count_violation_rows,
    simulated_offer_exposure_flag_violation_rows,

    approve_amount_violation_rows,
    counteroffer_amount_violation_rows,
    manual_review_amount_violation_rows,
    decline_amount_violation_rows,

    approve_payment_violation_rows,
    counteroffer_affordability_violation_rows,
    manual_review_affordability_violation_rows,
    decline_affordability_violation_rows,

    approve_expected_loss_violation_rows,
    counteroffer_expected_loss_violation_rows,
    manual_review_expected_loss_violation_rows,
    decline_expected_loss_violation_rows,

    reason_code_completeness_violation_rows,
    reason_family_alignment_violation_rows,

    /*
    Option C archive convention checks.

    These are treated as critical Section 17 archive convention checks because the completed active
    campaign archive must preserve the selective/aggressive counteroffer path evidence needed for
    final campaign interpretation.

    option_c_archive_field_gap_rows:
        archive rows are missing required Option C control/path fields.

    aggressive_override_reason_trace_gap_rows:
        aggressive override rows are missing expected path-specific simulated reason-code evidence.

    selective_strategy_aggressive_override_rows:
        SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY produced aggressive override rows, which would
        violate the intended selective feasibility posture.
    */
    option_c_archive_field_gap_rows,
    aggressive_override_reason_trace_gap_rows,
    selective_strategy_aggressive_override_rows,

    (
        final_outcome_flag_count_violation_rows
        + simulated_offer_exposure_flag_violation_rows
        + approve_amount_violation_rows
        + counteroffer_amount_violation_rows
        + manual_review_amount_violation_rows
        + decline_amount_violation_rows
        + approve_payment_violation_rows
        + counteroffer_affordability_violation_rows
        + manual_review_affordability_violation_rows
        + decline_affordability_violation_rows
        + approve_expected_loss_violation_rows
        + counteroffer_expected_loss_violation_rows
        + manual_review_expected_loss_violation_rows
        + decline_expected_loss_violation_rows
        + reason_code_completeness_violation_rows
        + reason_family_alignment_violation_rows

        /*
        Option C critical convention additions.
        */
        + option_c_archive_field_gap_rows
        + aggressive_override_reason_trace_gap_rows
        + selective_strategy_aggressive_override_rows
    ) AS critical_convention_violation_count,

    CASE
        WHEN active_campaign_archived_rows = 0
            THEN 'REVIEW_NO_ACTIVE_CAMPAIGN_ARCHIVE_ROWS'

        WHEN (
            final_outcome_flag_count_violation_rows
            + simulated_offer_exposure_flag_violation_rows
            + approve_amount_violation_rows
            + counteroffer_amount_violation_rows
            + manual_review_amount_violation_rows
            + decline_amount_violation_rows
            + approve_payment_violation_rows
            + counteroffer_affordability_violation_rows
            + manual_review_affordability_violation_rows
            + decline_affordability_violation_rows
            + approve_expected_loss_violation_rows
            + counteroffer_expected_loss_violation_rows
            + manual_review_expected_loss_violation_rows
            + decline_expected_loss_violation_rows
            + reason_code_completeness_violation_rows
            + reason_family_alignment_violation_rows

            /*
            Option C critical convention additions.

            Keep these aligned with critical_convention_violation_count above.
            */
            + option_c_archive_field_gap_rows
            + aggressive_override_reason_trace_gap_rows
            + selective_strategy_aggressive_override_rows
        ) = 0
            THEN 'ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY'

        ELSE 'REVIEW_ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS'
    END AS active_campaign_archive_convention_status

FROM convention_counts;
```

Also update the Section 17.9 `EXPECTED RESULT` comment to include the Option C expectation:

```sql
EXPECTED RESULT:
    option_c_archive_field_gap_rows = 0
    aggressive_override_reason_trace_gap_rows = 0
    selective_strategy_aggressive_override_rows = 0
    critical_convention_violation_count = 0
    active_campaign_archive_convention_status = ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY
```

That keeps the numeric critical count, the readiness status, and the commentary aligned.
<!-- END_MESSAGE C034-M01188 -->


---

<a id="c034-m01190"></a>

### C034-M01190

**Andrew** · 2026-05-16T21:53:37.512000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01190 -->
please make this change easier to implement (give full 17.10 copy paste - current 17.10 attached): 9. Section 17.10 — add Option C validation status visibility

Section 17.10 should not need a full rewrite. Because Section 14.19 now writes Option C rows into tmp_m2_validation_status_summary, and Section 16 persists those rows into validation evidence, Section 17.10 should automatically include them if it summarizes all persisted validation evidence.

However, I recommend adding explicit Option C validation counts so the reviewer can see the Option C validation status without drilling into Section 17.11.

Add these to the Section 17.10 run-level validation summary SELECT:

COUNT(*) FILTER (
    WHERE validation_area = 'Option C counteroffer split'
) AS option_c_validation_evidence_rows,

COUNT(*) FILTER (
    WHERE validation_area = 'Option C counteroffer split'
      AND validation_status = 'PASS'
) AS option_c_validation_pass_count,

COUNT(*) FILTER (
    WHERE validation_area = 'Option C counteroffer split'
      AND validation_status = 'REVIEW'
) AS option_c_validation_review_count,

COUNT(*) FILTER (
    WHERE validation_area = 'Option C counteroffer split'
      AND validation_status = 'NOT_APPLICABLE'
) AS option_c_validation_not_applicable_count

Add this comment to the 17.10 header:

Option C validation note:
    Section 14.19 now creates dedicated Option C validation rows.

    Section 17.10 should show whether those rows were captured for each active campaign run and
    whether the Option C field preservation, path behavior, reason traceability, and matched-context
    checks were PASS, REVIEW, or NOT_APPLICABLE.

Missing Option C validation rows should be caught in Section 17.7 through the dynamic validation key completeness design. Section 17.10 should focus on the status mix of rows that exist.
<!-- END_MESSAGE C034-M01190 -->


**Attachments in export:** `Pasted text(213).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01194"></a>

### C034-M01194

**ChatGPT** · 2026-05-16T21:56:37.696882-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01194 -->
According to a document from **2026-05-17**, your current 17.10 already has the right structure: active campaign registry scope, dynamic validation key count, per-run validation counts, duplicate-key check, and `VALIDATION_EVIDENCE_COMPLETE` / `REVIEW_VALIDATION_EVIDENCE_COMPLETENESS` status logic. The patch below keeps that structure and adds explicit Option C validation status visibility. fileciteturn299file0

Replace your full current **Section 17.10** with this:

```sql
/***************************************************************************************************
SECTION 17.10 — VALIDATION STATUS SUMMARY BY ACTIVE CAMPAIGN RUN
****************************************************************************************************

BUSINESS PURPOSE:
    Summarize Section 16 validation evidence by active campaign registry run.

    Section 17.10 answers:

        "For each active campaign run, what validation evidence statuses were captured?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    Persistent validation evidence may contain old development or inactive run evidence.

    Section 17 evaluates active campaign registry runs.

DYNAMIC VALIDATION EVIDENCE DESIGN:
    expected_validation_key_count is derived from the distinct validation evidence keys present across
    active campaign registry runs:

        validation_area
        validation_test_name
        validation_category

    This avoids hardcoding the Section 14 validation evidence row count.

OPTION C VALIDATION NOTE:
    Section 14.19 now creates dedicated Option C validation rows using:

        validation_area = 'Option C counteroffer split'

    Section 16 persists those rows into:

        credit_decisioning_sim.strategy_run_validation_evidence

    Section 17.10 therefore surfaces the Option C validation status mix for each active campaign run:
        Option C validation evidence rows
        Option C PASS count
        Option C REVIEW count
        Option C NOT_APPLICABLE count

    Interpretation:
        Missing Option C validation rows should be caught by the dynamic validation-key completeness
        design in Section 17.7 / Section 17.8.

        Section 17.10 focuses on the status mix of validation rows that exist.

EXPECTED RESULT:
    One row per active campaign registry run.

    Each row should generally show:
        validation_rows = expected_validation_key_count
        validation_distinct_key_count = expected_validation_key_count
        duplicate_validation_key_rows = 0
        validation_unexpected_status_count = 0

    For Option C:
        option_c_validation_evidence_rows > 0 when Option C validation rows are part of the current
        Section 14 validation spine.
        option_c_validation_review_count should be reviewed before final campaign interpretation.

***************************************************************************************************/

WITH active_campaign_runs AS (
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

validation_key_catalog AS (
    /***********************************************************************************************
    Dynamic validation evidence key catalog.

    Purpose:
        Derive the expected validation evidence row count from the actual persisted validation spine
        across active campaign runs.

    Why this matters:
        Section 14 validation evidence can evolve as the module matures.

        Section 17 should not rely on a hardcoded validation row count that becomes stale when new
        validation rows, such as Option C validation rows, are added.
    ***********************************************************************************************/
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

validation_by_run AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        /*******************************************************************************************
        Overall validation evidence row counts.
        *******************************************************************************************/
        COUNT(v.*) AS validation_rows,

        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS validation_distinct_key_count,

        COUNT(v.*) - COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS duplicate_validation_key_rows,

        /*******************************************************************************************
        Overall validation status mix.

        PASS:
            expected behavior satisfied.

        REVIEW:
            pattern requires interpretation before documentation.

        NOT_APPLICABLE:
            supporting context or relevant subpopulation was unavailable.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE v.validation_status = 'PASS'
        ) AS validation_pass_count,

        COUNT(*) FILTER (
            WHERE v.validation_status = 'REVIEW'
        ) AS validation_review_count,

        COUNT(*) FILTER (
            WHERE v.validation_status = 'NOT_APPLICABLE'
        ) AS validation_not_applicable_count,

        COUNT(*) FILTER (
            WHERE v.validation_status NOT IN ('PASS', 'REVIEW', 'NOT_APPLICABLE')
              AND v.validation_status IS NOT NULL
        ) AS validation_unexpected_status_count,

        /*******************************************************************************************
        Option C validation status mix.

        Purpose:
            Surface the status of dedicated Option C validation evidence rows without requiring the
            reviewer to drill into Section 17.11.

        Expected validation_area:
            Option C counteroffer split

        These rows should cover:
            latest-run Option C field preservation,
            latest-run aggressive override behavior,
            aggressive override reason-code traceability,
            and matched comparison Option C context when available.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE v.validation_area = 'Option C counteroffer split'
        ) AS option_c_validation_evidence_rows,

        COUNT(*) FILTER (
            WHERE v.validation_area = 'Option C counteroffer split'
              AND v.validation_status = 'PASS'
        ) AS option_c_validation_pass_count,

        COUNT(*) FILTER (
            WHERE v.validation_area = 'Option C counteroffer split'
              AND v.validation_status = 'REVIEW'
        ) AS option_c_validation_review_count,

        COUNT(*) FILTER (
            WHERE v.validation_area = 'Option C counteroffer split'
              AND v.validation_status = 'NOT_APPLICABLE'
        ) AS option_c_validation_not_applicable_count

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    GROUP BY
        r.module2_run_id,
        r.run_sequence_number
)

SELECT
    r.run_sequence_number,
    r.module2_run_id,
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

    /***********************************************************************************************
    Dynamic expected validation evidence count.
    ***********************************************************************************************/
    COALESCE(vkc.expected_validation_key_count, 0)
        AS expected_validation_key_count,

    /***********************************************************************************************
    Actual validation evidence coverage for this active campaign run.
    ***********************************************************************************************/
    COALESCE(v.validation_rows, 0)
        AS validation_rows,

    COALESCE(v.validation_distinct_key_count, 0)
        AS validation_distinct_key_count,

    COALESCE(v.validation_rows, 0)
        - COALESCE(vkc.expected_validation_key_count, 0)
            AS validation_evidence_row_gap,

    COALESCE(v.duplicate_validation_key_rows, 0)
        AS duplicate_validation_key_rows,

    /***********************************************************************************************
    Overall validation status mix.
    ***********************************************************************************************/
    COALESCE(v.validation_pass_count, 0)
        AS validation_pass_count,

    COALESCE(v.validation_review_count, 0)
        AS validation_review_count,

    COALESCE(v.validation_not_applicable_count, 0)
        AS validation_not_applicable_count,

    COALESCE(v.validation_unexpected_status_count, 0)
        AS validation_unexpected_status_count,

    /***********************************************************************************************
    Option C validation status visibility.

    These fields summarize dedicated Option C validation evidence for the active campaign run.

    They are diagnostic visibility fields.

    Validation completeness remains governed by the dynamic validation key count above.
    ***********************************************************************************************/
    COALESCE(v.option_c_validation_evidence_rows, 0)
        AS option_c_validation_evidence_rows,

    COALESCE(v.option_c_validation_pass_count, 0)
        AS option_c_validation_pass_count,

    COALESCE(v.option_c_validation_review_count, 0)
        AS option_c_validation_review_count,

    COALESCE(v.option_c_validation_not_applicable_count, 0)
        AS option_c_validation_not_applicable_count,

    /***********************************************************************************************
    Per-run validation evidence status.

    VALIDATION_EVIDENCE_COMPLETE means:
        the run has the expected number of validation evidence rows,
        the run has the expected number of distinct validation keys,
        no duplicate validation keys exist,
        and no unexpected validation_status values exist.

    Note:
        This status does not require all validation rows to be PASS.

        REVIEW and NOT_APPLICABLE are valid validation statuses that require interpretation.
    ***********************************************************************************************/
    CASE
        WHEN COALESCE(vkc.expected_validation_key_count, 0) = 0
            THEN 'REVIEW_VALIDATION_KEY_CATALOG_MISSING'

        WHEN COALESCE(v.validation_rows, 0) = COALESCE(vkc.expected_validation_key_count, 0)
         AND COALESCE(v.validation_distinct_key_count, 0) = COALESCE(vkc.expected_validation_key_count, 0)
         AND COALESCE(v.duplicate_validation_key_rows, 0) = 0
         AND COALESCE(v.validation_unexpected_status_count, 0) = 0
            THEN 'VALIDATION_EVIDENCE_COMPLETE'

        ELSE 'REVIEW_VALIDATION_EVIDENCE_COMPLETENESS'
    END AS validation_evidence_status

FROM active_campaign_runs r

CROSS JOIN validation_key_catalog vkc

LEFT JOIN validation_by_run v
    ON v.module2_run_id = r.module2_run_id

ORDER BY
    r.run_sequence_number,
    r.module2_run_id;
```

This version adds the four requested Option C fields and keeps the underlying acceptance logic unchanged:

```text
option_c_validation_evidence_rows
option_c_validation_pass_count
option_c_validation_review_count
option_c_validation_not_applicable_count
```

It also keeps Section 17.10 focused on **status mix visibility**, while leaving missing-row detection to the dynamic validation-key completeness checks in Sections 17.7 / 17.8.
<!-- END_MESSAGE C034-M01194 -->


---

<a id="c034-m01196"></a>

### C034-M01196

**Andrew** · 2026-05-16T22:00:58.752000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01196 -->
review sections 17.11 thru 17.15 logic, comments, headers for potential needed changes.  Please make it very easy to implement (full copy paste).  here is current 17.11 thru 17.15 code:
<!-- END_MESSAGE C034-M01196 -->


**Attachments in export:** `Pasted text(214).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01200"></a>

### C034-M01200

**ChatGPT** · 2026-05-16T22:08:21.529868-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01200 -->
According to a document from **2026-05-17**, Sections 17.11–17.15 are already in the right structural pattern: registry-scoped validation concentration, active comparison readiness, source-field consistency, executive evidence summary, and baseline/challenger delta summary. The needed update is targeted: add Option C visibility and interpretation fields without changing the acceptance grain or turning Section 17 into a recalculation layer. fileciteturn301file13turn301file3

Replace your current **17.11 through 17.15** with the full block below.

```sql
/***************************************************************************************************
SECTION 17.11 — VALIDATION REVIEW / NOT_APPLICABLE CONCENTRATION
****************************************************************************************************

BUSINESS PURPOSE:
    Display validation evidence items from active campaign runs that require interpretation or
    context.

    Section 17.11 answers:

        "Which validation areas most often produced REVIEW or NOT_APPLICABLE status across the active
         campaign?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    Persistent validation evidence may contain historical, ad hoc, or inactive evidence rows.

    Section 17 evaluates the active formal campaign registry only.

INTERPRETATION:
    REVIEW does not automatically mean invalid.
    NOT_APPLICABLE does not automatically mean missing.

    Both should be reviewed before executive narrative, README, LinkedIn, or validation-summary
    claims are drafted.

OPTION C VALIDATION NOTE:
    Section 14.19 now creates dedicated Option C validation rows using:

        validation_area = 'Option C counteroffer split'

    This section intentionally surfaces those rows when they are REVIEW or NOT_APPLICABLE so the
    final campaign narrative can distinguish:

        ordinary counteroffer candidacy
        from
        aggressive counteroffer expansion override behavior.

    Option C REVIEW rows may be valid strategy findings, not defects.

EXPECTED RESULT:
    Zero rows is possible when all active campaign validation evidence is PASS.

***************************************************************************************************/

WITH active_campaign_runs AS (
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

active_validation_evidence AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        v.validation_area,
        v.validation_test_name,
        v.validation_category,
        v.validation_status,
        v.observed_value,
        v.expected_behavior,
        v.interpretation
    FROM active_campaign_runs r

    JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    WHERE v.validation_status IN ('REVIEW', 'NOT_APPLICABLE')
)

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,

    CASE
        WHEN validation_area = 'Option C counteroffer split'
            THEN 'OPTION_C_VALIDATION_ITEM'
        ELSE 'GENERAL_VALIDATION_ITEM'
    END AS validation_context_type,

    COUNT(*) AS validation_item_occurrence_count,
    COUNT(DISTINCT module2_run_id) AS impacted_campaign_run_count,

    MIN(run_sequence_number) AS first_impacted_run_sequence_number,
    MAX(run_sequence_number) AS last_impacted_run_sequence_number,

    STRING_AGG(DISTINCT module2_run_id, ', ')
        AS impacted_module2_run_ids,

    MIN(observed_value) AS sample_observed_value,
    MIN(expected_behavior) AS expected_behavior,
    MIN(interpretation) AS interpretation

FROM active_validation_evidence

GROUP BY
    validation_area,
    validation_test_name,
    validation_category,
    validation_status

ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        ELSE 99
    END,
    CASE
        WHEN validation_area = 'Option C counteroffer split' THEN 1
        ELSE 2
    END,
    impacted_campaign_run_count DESC,
    validation_area,
    validation_test_name;



/***************************************************************************************************
SECTION 17.12 — ACTIVE COMPARISON REGISTRY READINESS
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm each active comparison registry group has baseline and challenger archive slices that are
    ready for matched comparison.

    Section 17.12 answers:

        "For each active comparison group, do the baseline and challenger slices exist, match the
         selected Module 1 source population size, and overlap completely by application_id?"

DYNAMIC ACCEPTANCE PRINCIPLE:
    Expected comparison row count is derived from the selected Module 1 source slice in:

        credit_decisioning_sim.synthetic_applications_scenario_archive

    It is not hardcoded to 50,000.

OPTION C VISIBILITY NOTE:
    This section adds Option C visibility fields for the baseline and challenger archived slices.

    These fields show whether the comparison is testing:
        a non-Option-C strategy,
        selective counteroffer feasibility,
        or aggressive counteroffer expansion.

    They are visibility fields only.

    They do not change matched-comparison readiness. Readiness still depends on:
        archive slice availability,
        expected source row count,
        application_id grain,
        and complete baseline / challenger overlap.

EXPECTED RESULT:
    One row per active comparison group.

    Each row should generally show:
        baseline_archived_rows = expected_module1_source_rows
        challenger_archived_rows = expected_module1_source_rows
        matched_application_id_count = expected_module1_source_rows
        baseline_only_application_id_count = 0
        challenger_only_application_id_count = 0
        readiness_status = READY_FOR_MATCHED_COMPARISON

***************************************************************************************************/

WITH active_comparisons AS (
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

        /*******************************************************************************************
        Option C slice-level visibility.

        These fields do not define archive grain.
        They summarize downstream Module 2 strategy-output evidence for comparison interpretation.
        *******************************************************************************************/
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
        ) AS aggressive_override_final_decline_rows

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

comparison_application_union AS (
    SELECT
        COALESCE(b.comparison_group_id, ch.comparison_group_id)
            AS comparison_group_id,

        b.application_id AS baseline_application_id,
        ch.application_id AS challenger_application_id

    FROM baseline_applications b

    FULL OUTER JOIN challenger_applications ch
        ON ch.comparison_group_id = b.comparison_group_id
       AND ch.application_id = b.application_id
),

comparison_application_overlap AS (
    SELECT
        comparison_group_id,

        COUNT(*) FILTER (
            WHERE baseline_application_id IS NOT NULL
              AND challenger_application_id IS NOT NULL
        ) AS matched_application_id_count,

        COUNT(*) FILTER (
            WHERE baseline_application_id IS NOT NULL
              AND challenger_application_id IS NULL
        ) AS baseline_only_application_id_count,

        COUNT(*) FILTER (
            WHERE baseline_application_id IS NULL
              AND challenger_application_id IS NOT NULL
        ) AS challenger_only_application_id_count

    FROM comparison_application_union

    GROUP BY comparison_group_id
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

    s.expected_module1_source_rows,
    s.expected_module1_distinct_application_id_count,

    c.baseline_strategy_set_name,
    c.baseline_strategy_name,
    c.baseline_strategy_version,

    c.challenger_strategy_set_name,
    c.challenger_strategy_name,
    c.challenger_strategy_version,

    (
        c.baseline_strategy_set_name IS NOT DISTINCT FROM c.challenger_strategy_set_name
        AND c.baseline_strategy_name IS NOT DISTINCT FROM c.challenger_strategy_name
        AND c.baseline_strategy_version IS NOT DISTINCT FROM c.challenger_strategy_version
    ) AS same_strategy_selected_flag,

    COALESCE(b.archived_rows, 0) AS baseline_archived_rows,
    COALESCE(ch.archived_rows, 0) AS challenger_archived_rows,

    COALESCE(b.distinct_application_id_count, 0) AS baseline_distinct_application_id_count,
    COALESCE(ch.distinct_application_id_count, 0) AS challenger_distinct_application_id_count,

    COALESCE(o.matched_application_id_count, 0) AS matched_application_id_count,
    COALESCE(o.baseline_only_application_id_count, 0) AS baseline_only_application_id_count,
    COALESCE(o.challenger_only_application_id_count, 0) AS challenger_only_application_id_count,

    /***********************************************************************************************
    Option C baseline / challenger visibility.

    These fields help reviewers recognize whether a comparison group is testing selective feasibility
    or aggressive expansion behavior.
    ***********************************************************************************************/
    b.counteroffer_strategy_variant AS baseline_counteroffer_strategy_variant,
    ch.counteroffer_strategy_variant AS challenger_counteroffer_strategy_variant,

    COALESCE(b.aggressive_counteroffer_expansion_enabled, FALSE)
        AS baseline_aggressive_counteroffer_expansion_enabled,

    COALESCE(ch.aggressive_counteroffer_expansion_enabled, FALSE)
        AS challenger_aggressive_counteroffer_expansion_enabled,

    COALESCE(b.ordinary_counteroffer_candidate_rows, 0)
        AS baseline_ordinary_counteroffer_candidate_rows,

    COALESCE(ch.ordinary_counteroffer_candidate_rows, 0)
        AS challenger_ordinary_counteroffer_candidate_rows,

    COALESCE(b.aggressive_override_rows, 0)
        AS baseline_aggressive_override_rows,

    COALESCE(ch.aggressive_override_rows, 0)
        AS challenger_aggressive_override_rows,

    COALESCE(ch.aggressive_override_final_counteroffer_rows, 0)
        AS challenger_aggressive_override_final_counteroffer_rows,

    COALESCE(ch.aggressive_override_final_manual_review_rows, 0)
        AS challenger_aggressive_override_final_manual_review_rows,

    COALESCE(ch.aggressive_override_final_decline_rows, 0)
        AS challenger_aggressive_override_final_decline_rows,

    CASE
        WHEN s.expected_module1_source_rows IS NULL
            THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN s.expected_module1_source_rows <> s.expected_module1_distinct_application_id_count
            THEN 'REVIEW_MODULE1_SOURCE_APPLICATION_ID_GRAIN'

        WHEN (
            c.baseline_strategy_set_name IS NOT DISTINCT FROM c.challenger_strategy_set_name
            AND c.baseline_strategy_name IS NOT DISTINCT FROM c.challenger_strategy_name
            AND c.baseline_strategy_version IS NOT DISTINCT FROM c.challenger_strategy_version
        )
            THEN 'REVIEW_SAME_STRATEGY_SELECTED'

        WHEN COALESCE(b.archived_rows, 0) = 0
          OR COALESCE(ch.archived_rows, 0) = 0
            THEN 'REVIEW_COMPARISON_ARCHIVE_MISSING_SLICE'

        WHEN COALESCE(b.archived_rows, 0) <> s.expected_module1_source_rows
          OR COALESCE(ch.archived_rows, 0) <> s.expected_module1_source_rows
            THEN 'REVIEW_COMPARISON_ARCHIVE_ROW_COUNT_MISMATCH'

        WHEN COALESCE(b.distinct_application_id_count, 0) <> s.expected_module1_source_rows
          OR COALESCE(ch.distinct_application_id_count, 0) <> s.expected_module1_source_rows
            THEN 'REVIEW_COMPARISON_ARCHIVE_APPLICATION_ID_GRAIN'

        WHEN COALESCE(o.matched_application_id_count, 0) <> s.expected_module1_source_rows
          OR COALESCE(o.baseline_only_application_id_count, 0) <> 0
          OR COALESCE(o.challenger_only_application_id_count, 0) <> 0
            THEN 'REVIEW_COMPARISON_APPLICATION_OVERLAP'

        ELSE 'READY_FOR_MATCHED_COMPARISON'
    END AS readiness_status

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

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.13 — ACTIVE COMPARISON MATCHED SOURCE-FIELD CONSISTENCY
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm matched baseline and challenger rows share the same immutable Module 1 source fields.

    Section 17.13 answers:

        "Are baseline / challenger deltas interpretable as Module 2 strategy movement rather than
         Module 1 population drift?"

WHY THIS MATTERS:
    Matched strategy comparison should isolate downstream Module 2 strategy effects.

    If Module 1 source fields differ between baseline and challenger rows, the comparison may reflect:
        population drift,
        source-selection error,
        upstream scenario mismatch,
        archive corruption,
        or incomplete rerun replacement.

SOURCE FIELDS COMPARED:
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

OPTION C SOURCE-CONSISTENCY BOUNDARY:
    Do not add Option C fields to source-field consistency.

    Fields such as:
        counteroffer_strategy_variant,
        aggressive_counteroffer_expansion_enabled,
        ordinary_counteroffer_candidate_flag,
        aggressive_counteroffer_requested_structure_override_flag

    are downstream Module 2 strategy-output fields.

    They are expected to differ when a comparison tests selective counteroffer feasibility versus
    aggressive counteroffer expansion.

EXPECTED RESULT:
    One row per active comparison group.

    source_consistency_status should generally equal:
        SOURCE_FIELDS_MATCH

***************************************************************************************************/

WITH active_comparisons AS (
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

matched_rows AS (
    SELECT
        c.comparison_group_id,
        c.comparison_set_name,

        c.baseline_module2_run_id,
        c.challenger_module2_run_id,

        s.expected_module1_source_rows,

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
        ch.requested_expected_loss_amount AS challenger_requested_expected_loss_amount,

        b.module1_scenario_set_name AS baseline_module1_scenario_set_name,
        ch.module1_scenario_set_name AS challenger_module1_scenario_set_name,

        b.module1_scenario_name AS baseline_module1_scenario_name,
        ch.module1_scenario_name AS challenger_module1_scenario_name,

        b.population_id AS baseline_population_id,
        ch.population_id AS challenger_population_id

    FROM active_comparisons c

    LEFT JOIN module1_source_counts s
        ON s.module1_scenario_set_name = c.module1_scenario_set_name
       AND s.module1_scenario_name = c.module1_scenario_name
       AND s.population_id = c.population_id

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
        comparison_set_name,

        baseline_module2_run_id,
        challenger_module2_run_id,

        MAX(expected_module1_source_rows) AS expected_module1_source_rows,

        COUNT(*) AS matched_application_count,

        COUNT(*) FILTER (
            WHERE baseline_product_type_policy_key IS DISTINCT FROM challenger_product_type_policy_key
        ) AS product_type_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_score_band_policy_key IS DISTINCT FROM challenger_score_band_policy_key
        ) AS score_band_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_credit_score IS DISTINCT FROM challenger_credit_score
        ) AS credit_score_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_annual_income IS DISTINCT FROM challenger_annual_income
        ) AS annual_income_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_amount IS DISTINCT FROM challenger_requested_amount
        ) AS requested_amount_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_monthly_payment_proxy IS DISTINCT FROM challenger_requested_monthly_payment_proxy
        ) AS requested_payment_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_payment_to_income_ratio IS DISTINCT FROM challenger_requested_payment_to_income_ratio
        ) AS requested_pti_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_amount_to_income_ratio IS DISTINCT FROM challenger_amount_to_income_ratio
        ) AS amount_to_income_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_estimated_pd IS DISTINCT FROM challenger_estimated_pd
        ) AS estimated_pd_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_estimated_lgd IS DISTINCT FROM challenger_estimated_lgd
        ) AS estimated_lgd_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_requested_expected_loss_amount IS DISTINCT FROM challenger_requested_expected_loss_amount
        ) AS requested_expected_loss_mismatch_count,

        COUNT(*) FILTER (
            WHERE baseline_module1_scenario_set_name IS DISTINCT FROM challenger_module1_scenario_set_name
               OR baseline_module1_scenario_name IS DISTINCT FROM challenger_module1_scenario_name
               OR baseline_population_id IS DISTINCT FROM challenger_population_id
        ) AS module1_lineage_mismatch_count

    FROM matched_rows

    GROUP BY
        comparison_group_id,
        comparison_set_name,
        baseline_module2_run_id,
        challenger_module2_run_id
)

SELECT
    c.comparison_group_id,
    c.comparison_set_name,

    c.baseline_module2_run_id,
    c.challenger_module2_run_id,

    c.module1_scenario_set_name,
    c.module1_scenario_name,
    c.population_id,

    COALESCE(s.expected_module1_source_rows, 0) AS expected_module1_source_rows,
    COALESCE(r.matched_application_count, 0) AS matched_application_count,

    COALESCE(r.product_type_mismatch_count, 0) AS product_type_mismatch_count,
    COALESCE(r.score_band_mismatch_count, 0) AS score_band_mismatch_count,
    COALESCE(r.credit_score_mismatch_count, 0) AS credit_score_mismatch_count,
    COALESCE(r.annual_income_mismatch_count, 0) AS annual_income_mismatch_count,
    COALESCE(r.requested_amount_mismatch_count, 0) AS requested_amount_mismatch_count,
    COALESCE(r.requested_payment_mismatch_count, 0) AS requested_payment_mismatch_count,
    COALESCE(r.requested_pti_mismatch_count, 0) AS requested_pti_mismatch_count,
    COALESCE(r.amount_to_income_mismatch_count, 0) AS amount_to_income_mismatch_count,
    COALESCE(r.estimated_pd_mismatch_count, 0) AS estimated_pd_mismatch_count,
    COALESCE(r.estimated_lgd_mismatch_count, 0) AS estimated_lgd_mismatch_count,
    COALESCE(r.requested_expected_loss_mismatch_count, 0) AS requested_expected_loss_mismatch_count,
    COALESCE(r.module1_lineage_mismatch_count, 0) AS module1_lineage_mismatch_count,

    (
        COALESCE(r.product_type_mismatch_count, 0)
        + COALESCE(r.score_band_mismatch_count, 0)
        + COALESCE(r.credit_score_mismatch_count, 0)
        + COALESCE(r.annual_income_mismatch_count, 0)
        + COALESCE(r.requested_amount_mismatch_count, 0)
        + COALESCE(r.requested_payment_mismatch_count, 0)
        + COALESCE(r.requested_pti_mismatch_count, 0)
        + COALESCE(r.amount_to_income_mismatch_count, 0)
        + COALESCE(r.estimated_pd_mismatch_count, 0)
        + COALESCE(r.estimated_lgd_mismatch_count, 0)
        + COALESCE(r.requested_expected_loss_mismatch_count, 0)
        + COALESCE(r.module1_lineage_mismatch_count, 0)
    ) AS source_field_mismatch_count,

    CASE
        WHEN COALESCE(s.expected_module1_source_rows, 0) = 0
            THEN 'NOT_APPLICABLE_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN COALESCE(r.matched_application_count, 0) <> COALESCE(s.expected_module1_source_rows, 0)
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN (
            COALESCE(r.product_type_mismatch_count, 0)
            + COALESCE(r.score_band_mismatch_count, 0)
            + COALESCE(r.credit_score_mismatch_count, 0)
            + COALESCE(r.annual_income_mismatch_count, 0)
            + COALESCE(r.requested_amount_mismatch_count, 0)
            + COALESCE(r.requested_payment_mismatch_count, 0)
            + COALESCE(r.requested_pti_mismatch_count, 0)
            + COALESCE(r.amount_to_income_mismatch_count, 0)
            + COALESCE(r.estimated_pd_mismatch_count, 0)
            + COALESCE(r.estimated_lgd_mismatch_count, 0)
            + COALESCE(r.requested_expected_loss_mismatch_count, 0)
            + COALESCE(r.module1_lineage_mismatch_count, 0)
        ) = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status

FROM active_comparisons c

LEFT JOIN module1_source_counts s
    ON s.module1_scenario_set_name = c.module1_scenario_set_name
   AND s.module1_scenario_name = c.module1_scenario_name
   AND s.population_id = c.population_id

LEFT JOIN source_consistency_by_group r
    ON r.comparison_group_id = c.comparison_group_id

ORDER BY c.comparison_group_id;



/***************************************************************************************************
SECTION 17.14 — EXECUTIVE EVIDENCE CAMPAIGN SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Display the one-row executive evidence summary for each active campaign registry run.

    Section 17.14 answers:

        "What is the run-level executive evidence story for each active campaign run?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    Persistent executive evidence may contain historical or ad hoc evidence rows.

    Section 17 should display the active campaign registry scope.

DYNAMIC ACCEPTANCE PRINCIPLE:
    applications is compared to the selected Module 1 source population row count derived from:

        credit_decisioning_sim.synthetic_applications_scenario_archive

    It is not assumed to be 50,000.

OPTION C EXECUTIVE EVIDENCE NOTE:
    Section 16.6 captures Option C frontier evidence from Section 15.

    Section 16.9 synchronizes those fields after the full campaign archive is complete.

    Section 17.14 surfaces those fields so reviewers can confirm each run-level evidence row carries:
        selective / aggressive counteroffer strategy variant,
        ordinary counteroffer candidate volume,
        aggressive override volume,
        aggressive override final outcome mix,
        and Option C frontier posture labels.

EXPECTED RESULT:
    One row per active campaign registry run.

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

executive_evidence_ranked AS (
    SELECT
        e.*,

        COUNT(*) OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        ) AS executive_evidence_rows_for_run,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY evidence_snapshot_ts DESC NULLS LAST
        ) AS executive_evidence_row_rank
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
)

SELECT
    r.run_sequence_number,
    r.module1_run_id,
    r.module2_run_id,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,

    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,

    r.strategy_name,
    r.strategy_version,

    s.expected_module1_source_rows,

    COALESCE(e.executive_evidence_rows_for_run, 0) AS executive_evidence_rows_for_run,

    e.applications,
    e.applications - s.expected_module1_source_rows AS applications_minus_expected_source_rows,

    e.approval_rate,
    e.counteroffer_rate,
    e.manual_review_rate,
    e.decline_rate,
    e.simulated_offer_exposure_rate,

    e.total_requested_amount,
    e.total_approved_amount,
    e.approved_amount_capture_rate,

    e.total_requested_expected_loss_amount,
    e.total_approved_expected_loss_amount,
    e.approved_expected_loss_rate,
    e.approved_amount_per_approved_expected_loss_dollar,

    e.avg_synthetic_estimated_pd_proxy_offer_rows,
    e.avg_approved_payment_to_income_ratio_offer_rows,

    e.frontier_position_type,
    e.executive_frontier_quadrant,
    e.frontier_interpretation_note,

    /***********************************************************************************************
    Option C executive evidence fields.

    These fields are persisted in Section 16 and synchronized by Section 16.9.
    ***********************************************************************************************/
    e.counteroffer_strategy_variant,
    e.aggressive_counteroffer_expansion_enabled,

    e.ordinary_counteroffer_candidate_rows,
    e.ordinary_counteroffer_candidate_rate,
    e.delta_ordinary_counteroffer_candidate_rate,

    e.aggressive_override_rows,
    e.aggressive_override_rate,
    e.delta_aggressive_override_rate,

    e.aggressive_override_final_counteroffer_rows,
    e.aggressive_override_final_counteroffer_rate,
    e.delta_aggressive_override_final_counteroffer_rate,

    e.aggressive_override_final_manual_review_rows,
    e.aggressive_override_final_manual_review_rate,

    e.aggressive_override_final_decline_rows,
    e.aggressive_override_final_decline_rate,

    e.avg_exposure_reduction_pct_for_aggressive_override_counteroffers,
    e.avg_approved_pti_for_aggressive_override_counteroffers,
    e.avg_approved_el_for_aggressive_override_counteroffers,

    e.option_c_frontier_posture_type,
    e.option_c_frontier_interpretation_note,

    e.top_primary_reason_code,
    e.top_non_approval_primary_reason_code,
    e.top_policy_stop_primary_reason_code,
    e.top_reason_code_delta_driver_code,

    e.top_approved_amount_product,
    e.top_approved_expected_loss_product,
    e.top_approved_amount_score_band,
    e.top_approved_expected_loss_score_band,
    e.top_approved_el_product_score_segment,

    e.validation_pass_count,
    e.validation_review_count,
    e.validation_not_applicable_count,

    e.module3_growth_inputs_available_flag,
    e.module3_growth_input_gap_note,

    CASE
        WHEN s.expected_module1_source_rows IS NULL
            THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN COALESCE(e.executive_evidence_rows_for_run, 0) = 0
            THEN 'REVIEW_EXECUTIVE_EVIDENCE_ROW_MISSING'

        WHEN COALESCE(e.executive_evidence_rows_for_run, 0) <> 1
            THEN 'REVIEW_DUPLICATE_EXECUTIVE_EVIDENCE_ROWS'

        WHEN e.applications IS DISTINCT FROM s.expected_module1_source_rows
            THEN 'REVIEW_EXECUTIVE_EVIDENCE_APPLICATION_COUNT_MISMATCH'

        WHEN e.frontier_position_type IS NULL
          OR e.executive_frontier_quadrant IS NULL
            THEN 'REVIEW_FRONTIER_FIELDS_NOT_SYNCHRONIZED'

        WHEN e.counteroffer_strategy_variant IS NULL
          OR NULLIF(BTRIM(e.counteroffer_strategy_variant), '') IS NULL
          OR e.aggressive_counteroffer_expansion_enabled IS NULL
          OR e.ordinary_counteroffer_candidate_rows IS NULL
          OR e.ordinary_counteroffer_candidate_rate IS NULL
          OR e.aggressive_override_rows IS NULL
          OR e.aggressive_override_rate IS NULL
          OR e.aggressive_override_final_counteroffer_rows IS NULL
          OR e.aggressive_override_final_counteroffer_rate IS NULL
          OR e.aggressive_override_final_manual_review_rows IS NULL
          OR e.aggressive_override_final_manual_review_rate IS NULL
          OR e.aggressive_override_final_decline_rows IS NULL
          OR e.aggressive_override_final_decline_rate IS NULL
          OR e.option_c_frontier_posture_type IS NULL
          OR NULLIF(BTRIM(e.option_c_frontier_posture_type), '') IS NULL
          OR e.option_c_frontier_interpretation_note IS NULL
          OR NULLIF(BTRIM(e.option_c_frontier_interpretation_note), '') IS NULL
            THEN 'REVIEW_OPTION_C_FRONTIER_EVIDENCE_NOT_SYNCHRONIZED'

        ELSE 'EXECUTIVE_EVIDENCE_READY'
    END AS executive_evidence_status

FROM active_campaign_runs r

LEFT JOIN module1_source_counts s
    ON s.module1_scenario_set_name = r.module1_scenario_set_name
   AND s.module1_scenario_name = r.module1_scenario_name
   AND s.population_id = r.population_id

LEFT JOIN executive_evidence_ranked e
    ON e.strategy_set_name = r.strategy_set_name
   AND e.strategy_name = r.strategy_name
   AND e.strategy_version = r.strategy_version
   AND e.module1_scenario_set_name = r.module1_scenario_set_name
   AND e.module1_scenario_name = r.module1_scenario_name
   AND e.population_id = r.population_id
   AND e.executive_evidence_row_rank = 1

ORDER BY r.run_sequence_number;



/***************************************************************************************************
SECTION 17.15 — BASELINE × CHALLENGER DELTA SUMMARY FOR ACTIVE COMPARISON GROUPS
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the main comparison-level strategy-effect table across all active comparison groups.

    Section 17.15 answers:

        "How did each challenger strategy change access, approvals, counteroffers, manual review,
         declines, approved exposure, approved Expected Loss, approved Expected Loss rate,
         offered-population synthetic-risk profile, approved PTI, and Option C counteroffer path
         behavior?"

WHY THIS SECTION IS DYNAMIC:
    It returns one row per active comparison registry group.

    It does not assume a fixed comparison-group count.

READINESS CONTEXT:
    comparison_readiness_status and source_consistency_status are included so deltas are interpreted
    only when matched comparison and source-field checks are clean.

OPTION C COMPARISON NOTE:
    This section adds run-level Option C frontier deltas from persistent executive evidence.

    It does not perform applicant-level matched Option C movement.

    Applicant-level ordinary-versus-aggressive counteroffer path movement remains Section 13.

***************************************************************************************************/

WITH active_comparisons AS (
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

        COALESCE(b.distinct_application_id_count, 0)
            AS baseline_distinct_application_id_count,

        COALESCE(ch.distinct_application_id_count, 0)
            AS challenger_distinct_application_id_count,

        COALESCE(o.matched_application_id_count, 0) AS matched_application_id_count,
        COALESCE(o.baseline_only_application_id_count, 0) AS baseline_only_application_id_count,
        COALESCE(o.challenger_only_application_id_count, 0) AS challenger_only_application_id_count,

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

    LEFT JOIN comparison_overlap o
        ON o.comparison_group_id = c.comparison_group_id
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

source_consistency AS (
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
    FROM matched_rows
    GROUP BY comparison_group_id
),

executive_evidence_ranked AS (
    SELECT
        e.*,

        ROW_NUMBER() OVER (
            PARTITION BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY evidence_snapshot_ts DESC NULLS LAST
        ) AS evidence_row_rank
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
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

    c.baseline_strategy_name,
    c.challenger_strategy_name,

    cr.expected_module1_source_rows,
    cr.matched_application_id_count,
    cr.baseline_only_application_id_count,
    cr.challenger_only_application_id_count,
    cr.comparison_readiness_status,

    COALESCE(sc.source_field_mismatch_count, 0) AS source_field_mismatch_count,

    CASE
        WHEN cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'

        WHEN COALESCE(sc.source_field_mismatch_count, 0) = 0
            THEN 'SOURCE_FIELDS_MATCH'

        ELSE 'SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED'
    END AS source_consistency_status,

    c.expected_comparison_storyline,
    c.primary_metric_focus,

    /***********************************************************************************************
    Core decision and exposure deltas.
    ***********************************************************************************************/
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
    ch.total_approved_amount - b.total_approved_amount AS delta_total_approved_amount,

    b.total_approved_expected_loss_amount AS baseline_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount AS challenger_total_approved_expected_loss_amount,
    ch.total_approved_expected_loss_amount - b.total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    b.approved_expected_loss_rate AS baseline_approved_expected_loss_rate,
    ch.approved_expected_loss_rate AS challenger_approved_expected_loss_rate,
    ch.approved_expected_loss_rate - b.approved_expected_loss_rate
        AS delta_approved_expected_loss_rate,

    b.avg_synthetic_estimated_pd_proxy_offer_rows AS baseline_avg_pd_proxy_offer_rows,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows AS challenger_avg_pd_proxy_offer_rows,
    ch.avg_synthetic_estimated_pd_proxy_offer_rows
        - b.avg_synthetic_estimated_pd_proxy_offer_rows
        AS delta_avg_pd_proxy_offer_rows,

    b.avg_approved_payment_to_income_ratio_offer_rows AS baseline_avg_approved_pti_offer_rows,
    ch.avg_approved_payment_to_income_ratio_offer_rows AS challenger_avg_approved_pti_offer_rows,
    ch.avg_approved_payment_to_income_ratio_offer_rows
        - b.avg_approved_payment_to_income_ratio_offer_rows
        AS delta_avg_approved_pti_offer_rows,

    /***********************************************************************************************
    Option C run-level frontier evidence deltas.

    These fields come from Section 16 executive evidence after Section 16.9 synchronization.

    They show how the challenger changed ordinary counteroffer candidacy and aggressive override
    behavior at the run-level frontier evidence layer.
    ***********************************************************************************************/
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

    b.ordinary_counteroffer_candidate_rate
        AS baseline_ordinary_counteroffer_candidate_rate,

    ch.ordinary_counteroffer_candidate_rate
        AS challenger_ordinary_counteroffer_candidate_rate,

    ch.ordinary_counteroffer_candidate_rate
        - b.ordinary_counteroffer_candidate_rate
            AS delta_ordinary_counteroffer_candidate_rate,

    b.aggressive_override_rows AS baseline_aggressive_override_rows,
    ch.aggressive_override_rows AS challenger_aggressive_override_rows,
    ch.aggressive_override_rows - b.aggressive_override_rows
        AS delta_aggressive_override_rows,

    b.aggressive_override_rate AS baseline_aggressive_override_rate,
    ch.aggressive_override_rate AS challenger_aggressive_override_rate,
    ch.aggressive_override_rate - b.aggressive_override_rate
        AS delta_aggressive_override_rate,

    b.aggressive_override_final_counteroffer_rows
        AS baseline_aggressive_override_final_counteroffer_rows,

    ch.aggressive_override_final_counteroffer_rows
        AS challenger_aggressive_override_final_counteroffer_rows,

    ch.aggressive_override_final_counteroffer_rows
        - b.aggressive_override_final_counteroffer_rows
            AS delta_aggressive_override_final_counteroffer_rows,

    b.aggressive_override_final_counteroffer_rate
        AS baseline_aggressive_override_final_counteroffer_rate,

    ch.aggressive_override_final_counteroffer_rate
        AS challenger_aggressive_override_final_counteroffer_rate,

    ch.aggressive_override_final_counteroffer_rate
        - b.aggressive_override_final_counteroffer_rate
            AS delta_aggressive_override_final_counteroffer_rate,

    b.aggressive_override_final_manual_review_rows
        AS baseline_aggressive_override_final_manual_review_rows,

    ch.aggressive_override_final_manual_review_rows
        AS challenger_aggressive_override_final_manual_review_rows,

    ch.aggressive_override_final_manual_review_rows
        - b.aggressive_override_final_manual_review_rows
            AS delta_aggressive_override_final_manual_review_rows,

    b.aggressive_override_final_manual_review_rate
        AS baseline_aggressive_override_final_manual_review_rate,

    ch.aggressive_override_final_manual_review_rate
        AS challenger_aggressive_override_final_manual_review_rate,

    ch.aggressive_override_final_manual_review_rate
        - b.aggressive_override_final_manual_review_rate
            AS delta_aggressive_override_final_manual_review_rate,

    b.aggressive_override_final_decline_rows
        AS baseline_aggressive_override_final_decline_rows,

    ch.aggressive_override_final_decline_rows
        AS challenger_aggressive_override_final_decline_rows,

    ch.aggressive_override_final_decline_rows
        - b.aggressive_override_final_decline_rows
            AS delta_aggressive_override_final_decline_rows,

    b.aggressive_override_final_decline_rate
        AS baseline_aggressive_override_final_decline_rate,

    ch.aggressive_override_final_decline_rate
        AS challenger_aggressive_override_final_decline_rate,

    ch.aggressive_override_final_decline_rate
        - b.aggressive_override_final_decline_rate
            AS delta_aggressive_override_final_decline_rate,

    b.option_c_frontier_posture_type AS baseline_option_c_frontier_posture_type,
    ch.option_c_frontier_posture_type AS challenger_option_c_frontier_posture_type,

    ch.option_c_frontier_interpretation_note
        AS challenger_option_c_frontier_interpretation_note,

    CASE
        WHEN cr.comparison_readiness_status <> 'READY_FOR_MATCHED_COMPARISON'
            THEN 'OPTION_C_NOT_APPLICABLE_COMPARISON_NOT_READY'

        WHEN COALESCE(sc.source_field_mismatch_count, 0) <> 0
            THEN 'OPTION_C_NOT_APPLICABLE_SOURCE_FIELD_REVIEW_REQUIRED'

        WHEN ch.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
         AND ch.aggressive_counteroffer_expansion_enabled IS TRUE
         AND COALESCE(ch.aggressive_override_rows, 0) > 0
            THEN 'OPTION_C_AGGRESSIVE_EXPANSION_PATH_EVIDENCE_PRESENT'

        WHEN ch.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
         AND ch.aggressive_counteroffer_expansion_enabled IS TRUE
         AND COALESCE(ch.aggressive_override_rows, 0) = 0
            THEN 'OPTION_C_AGGRESSIVE_EXPANSION_NO_OVERRIDE_ROWS_REVIEW'

        WHEN ch.counteroffer_strategy_variant = 'SELECTIVE_FEASIBILITY'
         AND COALESCE(ch.aggressive_override_rows, 0) = 0
            THEN 'OPTION_C_SELECTIVE_FEASIBILITY_PATH_READY'

        WHEN ch.counteroffer_strategy_variant = 'NOT_COUNTEROFFER_SPLIT_STRATEGY'
            THEN 'OPTION_C_NOT_APPLICABLE_NON_COUNTEROFFER_SPLIT_STRATEGY'

        WHEN ch.counteroffer_strategy_variant IS NULL
            THEN 'OPTION_C_EXECUTIVE_EVIDENCE_MISSING_REVIEW'

        ELSE 'OPTION_C_COUNTEROFFER_PATH_REVIEW_REQUIRED'
    END AS option_c_comparison_delta_status,

    /***********************************************************************************************
    Frontier and reason-code interpretation fields.
    ***********************************************************************************************/
    b.frontier_position_type AS baseline_frontier_position_type,
    ch.frontier_position_type AS challenger_frontier_position_type,

    b.executive_frontier_quadrant AS baseline_executive_frontier_quadrant,
    ch.executive_frontier_quadrant AS challenger_executive_frontier_quadrant,

    ch.frontier_interpretation_note AS challenger_frontier_interpretation_note,

    ch.top_reason_code_delta_driver_code AS challenger_top_reason_code_delta_driver_code

FROM active_comparisons c

LEFT JOIN comparison_readiness cr
    ON cr.comparison_group_id = c.comparison_group_id

LEFT JOIN source_consistency sc
    ON sc.comparison_group_id = c.comparison_group_id

LEFT JOIN executive_evidence_ranked b
    ON b.strategy_set_name = c.baseline_strategy_set_name
   AND b.strategy_name = c.baseline_strategy_name
   AND b.strategy_version = c.baseline_strategy_version
   AND b.module1_scenario_set_name = c.module1_scenario_set_name
   AND b.module1_scenario_name = c.module1_scenario_name
   AND b.population_id = c.population_id
   AND b.evidence_row_rank = 1

LEFT JOIN executive_evidence_ranked ch
    ON ch.strategy_set_name = c.challenger_strategy_set_name
   AND ch.strategy_name = c.challenger_strategy_name
   AND ch.strategy_version = c.challenger_strategy_version
   AND ch.module1_scenario_set_name = c.module1_scenario_set_name
   AND ch.module1_scenario_name = c.module1_scenario_name
   AND ch.population_id = c.population_id
   AND ch.evidence_row_rank = 1

ORDER BY c.comparison_group_id;
```

Summary of what changed:

```text
17.11:
    Adds Option C validation context tagging.

17.12:
    Adds Option C baseline/challenger archive-slice visibility.

17.13:
    Keeps source-field consistency clean and explicitly excludes Option C fields.

17.14:
    Adds Option C executive evidence fields and an Option C synchronization review status.

17.15:
    Adds Option C run-level comparison deltas and an Option C comparison interpretation status.
```

No acceptance grain changes were made.
<!-- END_MESSAGE C034-M01200 -->


---

<a id="c034-m01201"></a>

### C034-M01201

**Andrew** · 2026-05-16T22:15:36.765000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01201 -->
review sections 17.16 thru the end of section 17 logic, comments, headers for potential needed changes, including if we need any new sections. Please make it very easy to implement (full copy paste). here is current 17.16 thru end of section 17 code:
<!-- END_MESSAGE C034-M01201 -->


**Attachments in export:** `Pasted text(215).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_24.md) · [Next](Part_26.md)
