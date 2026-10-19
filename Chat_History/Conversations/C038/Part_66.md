# Module 2 Decision Simulator Build

## Part 66

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_65.md) · [Next](Part_67.md)

<a id="c038-m01273"></a>

### C038-M01273

**ChatGPT** · 2026-05-11T12:37:43.950223-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01273 -->
Great. Now that all Module 2 campaign runs are complete, I would test the campaign in this order:

1. **Archive completeness and grain**
2. **Registry-to-archive reconciliation**
3. **Evidence-table completeness**
4. **Validation and convention integrity**
5. **Comparison readiness and matched-row consistency**
6. **Strategy frontier / campaign result review**
7. **Parameter snapshot audit**

These queries use the persistent archive, campaign registry, comparison registry, and Section 16 evidence tables. That is the right level now because Section 12 is the governed archive persistence layer, Section 13 is the matched strategy comparison layer, Section 14 is the latest-run validation framework, Section 15 is the archive-backed frontier layer, and Section 16 is the persistent evidence capture layer. fileciteturn184file20 fileciteturn184file19 fileciteturn184file17 fileciteturn184file11 fileciteturn184file9

Below is the exact test pack I would run.

---

## Query 1 — Module 2 archive campaign inventory

**Purpose:** Confirm that all 36 campaign runs archived exactly 50,000 rows each.

**Expected:**

```text
archived_strategy_scenario_slices = 36
total_archived_rows = 1,800,000
slices_not_50000_rows = 0
archive_campaign_inventory_status = MODULE_2_ARCHIVE_INVENTORY_READY
```

```sql
/***************************************************************************************************
QUERY 1 — MODULE 2 ARCHIVE CAMPAIGN INVENTORY

Purpose:
    Confirm that the completed Module 2 campaign archive contains exactly the expected 36 archived
    strategy × Module 1 scenario × population slices.

Expected:
    36 slices
    1,800,000 total rows
    50,000 rows per slice
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
)

SELECT
    COUNT(*) AS archived_strategy_scenario_slices,
    SUM(archived_rows) AS total_archived_rows,
    COUNT(*) FILTER (WHERE archived_rows <> 50000) AS slices_not_50000_rows,
    COUNT(*) FILTER (WHERE archived_rows <> distinct_application_id_count) AS slices_with_duplicate_application_ids,

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
```

---

## Query 2 — Archive slice detail

**Purpose:** Show every archived run slice. This is the table I would visually inspect for missing or duplicated M2 runs.

**Expected:** 36 rows, each with 50,000 archived rows.

```sql
/***************************************************************************************************
QUERY 2 — MODULE 2 ARCHIVE SLICE DETAIL

Purpose:
    Display every archived strategy / Module 1 scenario / population slice.

Expected:
    36 rows.
    Each row should have archived_rows = 50,000 and distinct_application_id_count = 50,000.
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
```

---

## Query 3 — Archive grain duplicate check

**Purpose:** Confirm there are no duplicate archive rows at the official archive grain.

**Expected:** `duplicate_archive_grain_count = 0`

```sql
/***************************************************************************************************
QUERY 3 — MODULE 2 ARCHIVE GRAIN DUPLICATE CHECK

Purpose:
    Confirm the archive is unique at:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

Expected:
    duplicate_archive_grain_count = 0
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
) d;
```

---

## Query 4 — Campaign registry to archive reconciliation

**Purpose:** Confirm each active campaign registry row has a matching archive slice.

**Expected:**

```text
registry_run_count = 36
registry_runs_with_archive_rows = 36
registry_runs_missing_archive_rows = 0
registry_runs_not_50000_rows = 0
campaign_registry_archive_status = CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE
```

```sql
/***************************************************************************************************
QUERY 4 — CAMPAIGN REGISTRY TO ARCHIVE RECONCILIATION

Purpose:
    Confirm every active campaign registry run has exactly one matching archived strategy slice.

Expected:
    36 active registry runs.
    Each active registry run should have 50,000 archived rows.
***************************************************************************************************/

WITH registry_runs AS (
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

        registry_active_flag
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
    COUNT(*) FILTER (WHERE archived_rows > 0) AS registry_runs_with_archive_rows,
    COUNT(*) FILTER (WHERE archived_rows = 0) AS registry_runs_missing_archive_rows,
    COUNT(*) FILTER (WHERE archived_rows <> 50000) AS registry_runs_not_50000_rows,
    COUNT(*) FILTER (WHERE archived_rows <> distinct_application_id_count) AS registry_runs_with_duplicate_application_ids,

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
```

---

## Query 5 — Registry rows missing archive detail

**Purpose:** If Query 4 fails, this shows exactly which run IDs are missing or not at 50,000 rows.

**Expected:** zero rows.

```sql
/***************************************************************************************************
QUERY 5 — REGISTRY RUNS MISSING OR MISMATCHED IN ARCHIVE

Purpose:
    Show any active campaign registry run where archive rows are missing or row count is not 50,000.

Expected:
    zero rows.
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
```

---

## Query 6 — Archive rows with no campaign registry match

**Purpose:** Confirm the archive does not contain orphan strategy slices outside the campaign registry.

**Expected:** zero rows.

```sql
/***************************************************************************************************
QUERY 6 — ARCHIVE SLICES WITHOUT ACTIVE CAMPAIGN REGISTRY ROW

Purpose:
    Confirm every archived campaign slice maps back to an active strategy_run_campaign_registry row.

Expected:
    zero rows.
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
```

---

## Query 7 — Section 16 evidence-table coverage

**Purpose:** Confirm persistent evidence exists for every completed campaign run.

**Expected:**

```text
executive_evidence_rows = 36
parameter_snapshot_rows = 36
segment_evidence_run_count = 36
validation_evidence_run_count = 36
evidence_campaign_status = SECTION_16_EVIDENCE_COVERAGE_READY
```

```sql
/***************************************************************************************************
QUERY 7 — SECTION 16 EVIDENCE COVERAGE SUMMARY

Purpose:
    Confirm Section 16 evidence exists for all 36 campaign runs.

Expected:
    executive_evidence_rows = 36
    parameter_snapshot_rows = 36
    validation evidence represented for 36 runs
    segment evidence represented for 36 runs
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

    COUNT(*) FILTER (WHERE executive_rows = 1) AS runs_with_one_executive_evidence_row,
    COUNT(*) FILTER (WHERE parameter_rows = 1) AS runs_with_one_parameter_snapshot_row,
    COUNT(*) FILTER (WHERE validation_rows > 0) AS runs_with_validation_evidence_rows,
    COUNT(*) FILTER (WHERE segment_rows > 0) AS runs_with_segment_evidence_rows,

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
```

---

## Query 8 — Evidence coverage detail by run

**Purpose:** Show which run has missing evidence if Query 7 fails.

**Expected:** 36 rows; each run should have `executive_rows = 1`, `parameter_rows = 1`, `validation_rows > 0`, and `segment_rows = 25` if every product × score segment is present.

```sql
/***************************************************************************************************
QUERY 8 — SECTION 16 EVIDENCE COVERAGE DETAIL BY RUN

Purpose:
    Display evidence counts for each campaign run.

Expected:
    executive_rows = 1
    parameter_rows = 1
    validation_rows > 0
    segment_rows = 25 for a full 5 product × 5 score-band matrix
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
```

---

## Query 9 — Final output convention checks across the full archive

**Purpose:** Apply Section 14-style final output convention checks across all archived campaign rows, not just the latest run.

**Expected:** all violation counts = 0.

```sql
/***************************************************************************************************
QUERY 9 — FULL ARCHIVE FINAL OUTPUT CONVENTION CHECKS

Purpose:
    Apply final-output convention checks across all archived Module 2 campaign rows.

Expected:
    All violation counts should be zero.
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
```

---

## Query 10 — Validation status summary by run

**Purpose:** Show PASS / REVIEW / NOT_APPLICABLE counts for every captured run.

**Expected:** No structural surprises. REVIEW rows are acceptable but should be interpreted.

```sql
/***************************************************************************************************
QUERY 10 — VALIDATION STATUS SUMMARY BY CAMPAIGN RUN

Purpose:
    Summarize Section 16 validation evidence by run.

Interpretation:
    REVIEW does not automatically mean invalid.
    REVIEW means the pattern should be interpreted before documentation.
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

    COUNT(*) FILTER (WHERE validation_status = 'PASS') AS pass_count,
    COUNT(*) FILTER (WHERE validation_status = 'REVIEW') AS review_count,
    COUNT(*) FILTER (WHERE validation_status = 'NOT_APPLICABLE') AS not_applicable_count,

    STRING_AGG(
        validation_area || ': ' || validation_test_name || ' [' || validation_status || ']',
        ' | '
        ORDER BY validation_area, validation_test_name
    ) FILTER (WHERE validation_status IN ('REVIEW', 'NOT_APPLICABLE')) AS review_or_not_applicable_items

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
```

---

## Query 11 — Validation REVIEW concentration

**Purpose:** Identify which validation tests most commonly produced REVIEW across the campaign.

**Expected:** REVIEW items may exist. This tells us which topics need narrative explanation.

```sql
/***************************************************************************************************
QUERY 11 — VALIDATION REVIEW CONCENTRATION

Purpose:
    Identify validation tests that most frequently produced REVIEW or NOT_APPLICABLE across the
    completed campaign.
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
```

---

## Query 12 — Comparison registry readiness across all comparison groups

**Purpose:** Confirm every planned comparison has both baseline and challenger archived at 50,000 rows.

**Expected:**

```text
17 comparison rows
baseline_archived_rows = 50000
challenger_archived_rows = 50000
comparison_readiness_status = COMPARISON_READY
```

```sql
/***************************************************************************************************
QUERY 12 — COMPARISON REGISTRY READINESS ACROSS ALL COMPARISON GROUPS

Purpose:
    Confirm each planned baseline / challenger comparison has both strategy slices archived.

Expected:
    17 comparison groups.
    Each baseline and challenger should have 50,000 rows.
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
```

---

## Query 13 — Matched comparison source-field consistency across all comparison groups

**Purpose:** Confirm baseline and challenger use the same immutable Module 1 source fields for every matched application. This is the most important pure strategy-comparison integrity check.

**Expected:**

```text
matched_application_count = 50000 for every comparison group
source_field_mismatch_count = 0
source_consistency_status = SOURCE_FIELDS_MATCH
```

```sql
/***************************************************************************************************
QUERY 13 — MATCHED COMPARISON SOURCE-FIELD CONSISTENCY ACROSS ALL COMPARISON GROUPS

Purpose:
    Confirm that each baseline / challenger comparison isolates Module 2 strategy effects by matching
    the same Module 1 source applications and immutable source fields.

Expected:
    matched_application_count = 50,000 for each comparison group.
    source_field_mismatch_count = 0 for each comparison group.
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
```

---

## Query 14 — Executive evidence campaign summary

**Purpose:** Show the high-level result table for all 36 runs from the persistent evidence layer.

**Expected:** This is not pass/fail; it is the main result table to inspect.

```sql
/***************************************************************************************************
QUERY 14 — EXECUTIVE EVIDENCE CAMPAIGN SUMMARY

Purpose:
    Display the one-row executive evidence summary for all completed Module 2 campaign runs.

Use:
    This is the core result table for executive review and later documentation.
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
```

---

## Query 15 — Baseline vs challenger delta summary for all comparison groups

**Purpose:** Produce the first high-level comparison result table across all 17 comparison pairs.

**Expected:** Not pass/fail. This should show whether each challenger moved the intended levers.

```sql
/***************************************************************************************************
QUERY 15 — BASELINE VS CHALLENGER DELTA SUMMARY FOR ALL COMPARISON GROUPS

Purpose:
    Summarize comparison deltas across all governed baseline / challenger pairs.

Interpretation:
    Use this as the first campaign strategy-effect table.
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
```

---

## Query 16 — Product guardrail strategy effect check

**Purpose:** Confirm product guardrail runs moved unsecured / revolving behavior.

**Expected:** Not a pass/fail. I want to see whether UPL and Revolving have lower approved amount / approved EL / offer exposure under guardrails.

```sql
/***************************************************************************************************
QUERY 16 — PRODUCT GUARDRAIL STRATEGY PRODUCT-LEVEL EFFECT CHECK

Purpose:
    Review product-level outcomes for PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY versus BASELINE_STRATEGY.

Use:
    Confirm that guardrail movement concentrates in:
        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE
***************************************************************************************************/

SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_name,
    product_type_policy_key,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS approval_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS decline_rate,

    SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,
    SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
        AS approved_expected_loss_rate,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS avg_synthetic_estimated_pd_proxy_offer_rows

FROM credit_decisioning_sim.strategy_decisions_archive

WHERE strategy_name IN ('BASELINE_STRATEGY', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY')

GROUP BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_name,
    product_type_policy_key

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    product_type_policy_key,
    strategy_name;
```

---

## Query 17 — Counteroffer strategy effect check

**Purpose:** Confirm counteroffer-first strategy increased counteroffer behavior and exposure reduction.

**Expected:** Counteroffer-first should show higher counteroffer rate / exposure reduction in its comparison contexts.

```sql
/***************************************************************************************************
QUERY 17 — COUNTEROFFER-FIRST STRATEGY EFFECT CHECK

Purpose:
    Review counteroffer behavior for COUNTEROFFER_FIRST_EXPOSURE_STRATEGY versus baseline contexts.

Use:
    Confirm that counteroffer-first strategy increases reduced-exposure treatment without causing
    unexpected convention failures.
***************************************************************************************************/

SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_name,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS counteroffer_rate,

    COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER') AS preliminary_counteroffer_count,

    COUNT(*) FILTER (
        WHERE preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS TRUE
    ) AS feasible_counteroffer_count,

    COUNT(*) FILTER (
        WHERE preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS FALSE
    ) AS failed_counteroffer_count,

    COUNT(*) FILTER (
        WHERE preliminary_decision_outcome = 'COUNTEROFFER'
          AND counteroffer_feasibility_pass_flag IS TRUE
    )::NUMERIC
    / NULLIF(COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER'), 0)
        AS counteroffer_feasibility_pass_rate,

    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_exposure_reduction_pct_for_final_counteroffers,

    SUM(exposure_reduction_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS total_counteroffer_exposure_reduction_amount,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_pti_for_final_counteroffers,

    AVG(approved_expected_loss_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS avg_approved_el_for_final_counteroffers

FROM credit_decisioning_sim.strategy_decisions_archive

WHERE strategy_name IN ('BASELINE_STRATEGY', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY')

GROUP BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_name

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    strategy_name;
```

---

## Query 18 — Parameter snapshot profile audit

**Purpose:** Confirm each run captured strategy and product-policy JSON payloads.

**Expected:** 36 rows; all capture flags TRUE.

```sql
/***************************************************************************************************
QUERY 18 — PARAMETER SNAPSHOT PROFILE AUDIT

Purpose:
    Confirm every campaign run has captured strategy, product-policy, and run-story JSONB payloads.

Expected:
    36 rows.
    All capture flags should be TRUE.
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
    strategy_params_jsonb ->> 'failed_counteroffer_resolution' AS captured_failed_counteroffer_resolution

FROM credit_decisioning_sim.strategy_run_parameter_snapshot

ORDER BY run_sequence_number;
```

---

## Query 19 — Product-policy snapshot extraction for guardrail runs

**Purpose:** Confirm the actual captured product-policy values for `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY`.

**Expected:** UPL and Revolving should show the guardrail values you intended.

```sql
/***************************************************************************************************
QUERY 19 — PRODUCT POLICY SNAPSHOT EXTRACTION FOR PRODUCT GUARDRAIL RUNS

Purpose:
    Extract product-policy JSONB payload for PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY runs.

Use:
    Confirm UPL and REVOLVING_LINE captured the exact guardrail policy values.
***************************************************************************************************/

SELECT
    ps.module2_run_id,
    ps.run_sequence_number,
    ps.module1_scenario_set_name,
    ps.module1_scenario_name,
    ps.strategy_name,

    product_policy_row ->> 'product_type' AS product_type,

    (product_policy_row ->> 'product_approve_max_pti')::NUMERIC AS product_approve_max_pti,
    (product_policy_row ->> 'product_review_max_pti')::NUMERIC AS product_review_max_pti,
    (product_policy_row ->> 'product_decline_min_pti')::NUMERIC AS product_decline_min_pti,
    (product_policy_row ->> 'counteroffer_target_pti')::NUMERIC AS counteroffer_target_pti,

    (product_policy_row ->> 'product_approve_max_requested_el')::NUMERIC AS product_approve_max_requested_el,
    (product_policy_row ->> 'product_review_max_requested_el')::NUMERIC AS product_review_max_requested_el,
    (product_policy_row ->> 'product_decline_min_requested_el')::NUMERIC AS product_decline_min_requested_el,
    (product_policy_row ->> 'product_approved_el_cap')::NUMERIC AS product_approved_el_cap,

    (product_policy_row ->> 'product_min_approved_amount')::NUMERIC AS product_min_approved_amount,
    (product_policy_row ->> 'product_max_approved_amount')::NUMERIC AS product_max_approved_amount,

    (product_policy_row ->> 'product_min_counteroffer_pct')::NUMERIC AS product_min_counteroffer_pct,
    (product_policy_row ->> 'product_max_exposure_reduction_pct')::NUMERIC AS product_max_exposure_reduction_pct

FROM credit_decisioning_sim.strategy_run_parameter_snapshot ps

CROSS JOIN LATERAL jsonb_array_elements(ps.product_policy_params_jsonb) AS product_policy_row

WHERE ps.strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
  AND product_policy_row ->> 'product_type' IN ('UNSECURED_PERSONAL_LOAN', 'REVOLVING_LINE')

ORDER BY
    ps.run_sequence_number,
    product_policy_row ->> 'product_type';
```

---

## Query 20 — Final “go / review” acceptance rollup

**Purpose:** One compact status line for campaign readiness.

**Expected:**

```text
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```

```sql
/***************************************************************************************************
QUERY 20 — MODULE 2 CAMPAIGN ACCEPTANCE ROLLUP

Purpose:
    Produce one compact campaign-level readiness status.

Expected:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
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
    ) d
),

executive_evidence AS (
    SELECT COUNT(*) AS executive_evidence_rows
    FROM credit_decisioning_sim.strategy_run_evidence_summary
),

parameter_evidence AS (
    SELECT COUNT(*) AS parameter_snapshot_rows
    FROM credit_decisioning_sim.strategy_run_parameter_snapshot
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
        )
        AS critical_convention_violation_count
    FROM credit_decisioning_sim.strategy_decisions_archive
)

SELECT
    rr.active_campaign_registry_rows,
    cr.active_comparison_registry_rows,

    (SELECT COUNT(*) FROM archive_inventory) AS archived_strategy_scenario_slices,
    (SELECT SUM(archived_rows) FROM archive_inventory) AS total_archived_rows,
    (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000) AS archive_slices_not_50000_rows,
    (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> distinct_application_id_count) AS archive_slices_with_duplicate_application_ids,

    agd.duplicate_archive_grain_count,

    ee.executive_evidence_rows,
    pe.parameter_snapshot_rows,

    cv.critical_convention_violation_count,

    CASE
        WHEN rr.active_campaign_registry_rows = 36
         AND cr.active_comparison_registry_rows = 17
         AND (SELECT COUNT(*) FROM archive_inventory) = 36
         AND (SELECT SUM(archived_rows) FROM archive_inventory) = 1800000
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000) = 0
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> distinct_application_id_count) = 0
         AND agd.duplicate_archive_grain_count = 0
         AND ee.executive_evidence_rows = 36
         AND pe.parameter_snapshot_rows = 36
         AND cv.critical_convention_violation_count = 0
            THEN 'MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS'
        ELSE 'REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS'
    END AS module2_campaign_acceptance_status

FROM registry_runs rr
CROSS JOIN comparison_registry cr
CROSS JOIN archive_grain_duplicates agd
CROSS JOIN executive_evidence ee
CROSS JOIN parameter_evidence pe
CROSS JOIN convention_violations cv;
```

---

The highest-value outputs to send back are **Query 1**, **Query 4**, **Query 7**, **Query 9**, **Query 12**, **Query 13**, **Query 14**, **Query 15**, and **Query 20**. Those will tell us whether the campaign is structurally ready, evidence-complete, comparison-ready, and analytically interpretable.
<!-- END_MESSAGE C038-M01273 -->


---

<a id="c038-m01274"></a>

### C038-M01274

**Andrew** · 2026-05-11T13:31:42.766000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01274 -->
review the first 10 queries from our campaign:
<!-- END_MESSAGE C038-M01274 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_5_registry_runs_missing_or_mismatched_expected_result_zero_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_4_campaign_registry_to_archive_reconciliation.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_3_archive_grain_duplicate_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_2_archive_slice_detail.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_1_expected_strategy_x_module1_scenario_x_population_slice_counts.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_10_validation_status_summary_by_campaign_run.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_9_full_archive_final_output_convention_checks.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_8_evidence_coverage_detail_by_run.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_7_confirm_evidence_exists_for_all_campaign_runs.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_6_archive_slices_without_active_campaign_registry_row_expected_result_zero_rows.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01282"></a>

### C038-M01282

**ChatGPT** · 2026-05-11T13:36:41.793968-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01282 -->
## Overall verdict for Queries 1–10

The first 10 campaign QA outputs are **strong**. I would mark this batch as:

```text
STATUS: PASS — MODULE 2 CAMPAIGN STRUCTURE, ARCHIVE, REGISTRY, EVIDENCE, AND OUTPUT CONVENTIONS ARE CLEAN
```

The only items requiring interpretation are the expected **REVIEW / NOT_APPLICABLE validation-status rows** in Query 10. They are not structural failures. Section 14’s validation framework explicitly uses `PASS`, `REVIEW`, and `NOT_APPLICABLE`, where `REVIEW` means the pattern should be interpreted before documentation rather than treated as automatic invalidation. fileciteturn184file17

---

## Query-by-query review

| Query | Result | Review |
|---:|---|---|
| 1 | **PASS** | 36 archived strategy/scenario slices, 1,800,000 archived rows, zero non-50k slices, zero duplicate-application slices. |
| 2 | **PASS** | All 36 archive slices are present at 50,000 rows each. SC05 now correctly uses `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET`; no old exposure-intensity set name appears. |
| 3 | **PASS** | `duplicate_archive_grain_count = 0`. Archive grain is clean. |
| 4 | **PASS** | All 36 active campaign registry runs reconcile to archive rows. No missing archive rows, no non-50k rows, no duplicate application rows. |
| 5 | **PASS** | Zero registry runs are missing or mismatched in archive. Ideal result. |
| 6 | **PASS** | Zero archive slices exist without active campaign registry rows. Ideal result. |
| 7 | **PASS** | Section 16 evidence coverage is complete: 36 executive evidence rows, 36 parameter snapshots, validation evidence for 36 runs, segment evidence for 36 runs. |
| 8 | **PASS** | Every run has `executive_rows = 1`, `parameter_rows = 1`, `validation_rows = 22`, `segment_rows = 25`, and `EVIDENCE_CAPTURE_READY`. |
| 9 | **PASS** | Full 1.8M-row archive has zero final-output convention violations. This is a very strong result. |
| 10 | **PASS with interpretation items** | All 36 runs have 22 validation evidence rows. Total validation: 719 PASS, 72 REVIEW, 1 NOT_APPLICABLE. No evidence of structural failure. |

Section 12 is the governed archive persistence layer and preserves completed strategy outputs for comparison and validation, so Queries 1–6 are the core archive/registry acceptance checks. fileciteturn184file20 Section 16 is the persistent evidence layer, so Queries 7–8 are the evidence-capture acceptance checks. fileciteturn184file9

---

## Key acceptance signals

### Archive and campaign inventory are clean

Query 1 shows:

```text
archived_strategy_scenario_slices      = 36
total_archived_rows                    = 1,800,000
slices_not_50000_rows                  = 0
slices_with_duplicate_application_ids  = 0
archive_campaign_inventory_status      = MODULE_2_ARCHIVE_INVENTORY_READY
```

That means the full planned Module 2 campaign landed at the expected grain:

```text
36 runs × 50,000 applications = 1,800,000 archived rows
```

This is exactly what we wanted.

### Archive grain is clean

Query 3 shows:

```text
duplicate_archive_grain_count = 0
```

That confirms there are no duplicate rows at:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

This is a hard acceptance point.

### Registry reconciles to archive

Query 4 shows:

```text
registry_run_count                         = 36
registry_runs_with_archive_rows            = 36
registry_runs_missing_archive_rows         = 0
registry_runs_not_50000_rows               = 0
registry_runs_with_duplicate_application_ids = 0
campaign_registry_archive_status           = CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE
```

Query 5 then returns zero rows, which confirms there are no specific registry rows requiring cleanup.

Query 6 also returns zero rows, meaning there are no orphan archive slices outside the active campaign registry.

This is a strong governance result.

---

## Evidence capture review

Query 7 shows:

```text
registry_run_count                       = 36
runs_with_one_executive_evidence_row     = 36
runs_with_one_parameter_snapshot_row     = 36
runs_with_validation_evidence_rows       = 36
runs_with_segment_evidence_rows          = 36
evidence_coverage_issue_count            = 0
evidence_campaign_status                 = SECTION_16_EVIDENCE_COVERAGE_READY
```

Query 8 confirms each run has:

```text
executive_rows   = 1
parameter_rows   = 1
validation_rows  = 22
segment_rows     = 25
status           = EVIDENCE_CAPTURE_READY
```

The `segment_rows = 25` is exactly right for:

```text
5 products × 5 score bands = 25 product × score segments
```

This means Section 16 persisted the executive story, validation detail, parameter snapshot, and product × score segment evidence for every completed campaign run. Section 16.7 was designed to gate exactly these evidence-capture expectations. fileciteturn184file3

One small documentation nuance: several baseline/reference runs have blank `comparison_group_id` in Query 8. I would not treat that as a failure because the comparison registry, not the run registry alone, is the authoritative object for baseline/challenger pairing. Query 12 and Query 13 will be the important follow-up checks for comparison readiness and matched source-field consistency.

---

## Full-archive output convention review

Query 9 is one of the strongest outputs in the set. Across all:

```text
1,800,000 archived rows
```

every convention check is zero:

```text
final_outcome_flag_count_violation_rows         = 0
simulated_offer_exposure_flag_violation_rows    = 0
approve_amount_violation_rows                   = 0
counteroffer_amount_violation_rows              = 0
manual_review_amount_violation_rows             = 0
decline_amount_violation_rows                   = 0
counteroffer_affordability_violation_rows       = 0
manual_review_affordability_violation_rows      = 0
decline_affordability_violation_rows            = 0
approve_expected_loss_violation_rows            = 0
counteroffer_expected_loss_violation_rows       = 0
manual_review_expected_loss_violation_rows      = 0
decline_expected_loss_violation_rows            = 0
reason_code_completeness_violation_rows         = 0
reason_family_alignment_violation_rows          = 0
```

This confirms the locked final-output conventions held across the entire archived campaign. That is a major acceptance result because Section 14.17 treats these convention violations as stronger evidence than ordinary diagnostic REVIEW patterns. fileciteturn184file13

---

## Validation-status review from Query 10

Query 10 shows every run captured:

```text
validation_evidence_rows = 22
```

Across the full campaign:

```text
Total validation evidence rows = 792
PASS                          = 719
REVIEW                        = 72
NOT_APPLICABLE                = 1
```

That is a clean validation-evidence footprint. The recurring REVIEW items are interpretive, not structural.

### Recurring REVIEW patterns

The recurring review items are:

```text
Mixed-signal and borderline concentration review:
    36 of 36 runs

Counteroffer concentration review:
    31 of 36 runs

Final counteroffer feasibility and affordability conventions:
    3 runs

Decline zero-exposure and policy-stop reason convention:
    1 run

Matched comparison readiness:
    1 run

Matched source-field consistency:
    1 NOT_APPLICABLE
```

The important point is that Query 9 shows **zero hard convention violations** across the full archive. So the Query 10 review items should be treated as narrative / diagnostic prompts, not implementation defects.

### Runs worth targeted interpretation

These are the specific runs I would flag for focused narrative review:

| Run | Scenario | Strategy | Review item |
|---|---|---|---|
| M2-09 | `RATE_DOWN_200BP` | `BASELINE_STRATEGY` | Final counteroffer feasibility / affordability review |
| M2-13 | `RATE_DOWN_200BP` | `GROWTH_ORIENTED_STRATEGY` | Final counteroffer feasibility / affordability review |
| M2-30 | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | `BASELINE_STRATEGY` | Final counteroffer feasibility / affordability review |
| M2-20 | `CREDIT_STRESS_SCORE_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Decline / policy-stop convention review |
| M2-01 | `BASELINE_V2` | `BASELINE_STRATEGY` | Comparison readiness REVIEW and source-field NOT_APPLICABLE |

For M2-09, M2-13, and M2-30, I would look at counteroffer feasibility distribution and approved PTI / approved Expected Loss edge cases. For M2-20, I would look at decline reason-code distribution and policy-stop concentration. For M2-01, I would not worry yet; it likely reflects evidence captured when the baseline run did not yet have a completed comparison context. Query 12 and Query 13 should supersede that with campaign-wide comparison readiness.

---

## Final assessment for Queries 1–10

I would mark the first 10 campaign QA queries as:

```text
MODULE 2 CAMPAIGN STRUCTURAL QA: PASS
ARCHIVE COMPLETENESS: PASS
ARCHIVE GRAIN: PASS
REGISTRY-TO-ARCHIVE RECONCILIATION: PASS
ORPHAN ARCHIVE CHECK: PASS
EVIDENCE CAPTURE COVERAGE: PASS
FULL-ARCHIVE OUTPUT CONVENTIONS: PASS
VALIDATION STATUS SUMMARY: PASS WITH INTERPRETIVE REVIEW ITEMS
```

The campaign is now ready for the next layer: **Queries 11–20**, especially Query 12, Query 13, Query 14, Query 15, and Query 20. Those will confirm comparison readiness, source-field consistency, executive results, baseline/challenger deltas, and final campaign acceptance.
<!-- END_MESSAGE C038-M01282 -->


---

<a id="c038-m01283"></a>

### C038-M01283

**Andrew** · 2026-05-11T14:37:53.431000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01283 -->
please review queries 11-15 from our campaign
<!-- END_MESSAGE C038-M01283 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_13_matched_comparison_source_field_consistency.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_12_comparison_registry_readiness.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_11_validation_review_concentration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_15_baseline_x_challenger_delta_summary_for_all_comparison_groups.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_14_executive_evidence_campaign_summary.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01294"></a>

### C038-M01294

**ChatGPT** · 2026-05-11T14:48:29.351665-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01294 -->
## Overall verdict for Queries 11–15

The campaign results from **Queries 11–15 are strong and analytically usable**. I would mark them:

```text
STATUS: PASS — COMPARISON READINESS, MATCHED SOURCE CONSISTENCY, EXECUTIVE RESULTS, AND BASELINE/CHALLENGER DELTAS ARE CLEAN

FOLLOW-UP: Refresh or override stale run-time frontier labels in Query 14 before final documentation.
```

The important distinction: **Queries 12, 13, and 15 prove the post-campaign comparison layer is ready and valid.** Query 14 is also structurally complete, but 9 saved executive-evidence rows still show `NO_BASELINE_REFERENCE_AVAILABLE` even though their comparison groups are now ready. That looks like a **run-time evidence-capture freshness issue**, not a data or comparison failure.

Section 13 is designed to isolate downstream Module 2 strategy effects by comparing baseline and challenger slices on the same Module 1 scenario, population, and `application_id`; Query 13 confirms that design held across the campaign. fileciteturn184file19

---

## Query 11 — Validation review concentration

**Verdict: PASS with expected interpretive review items.**

Query 11 shows 6 validation-review concentration rows:

| Validation item | Status | Run count | Interpretation |
|---|---:|---:|---|
| Mixed-signal and borderline concentration review | REVIEW | 36 | Expected. Mixed-signal / borderline visibility is part of realistic synthetic portfolio behavior. |
| Counteroffer concentration review | REVIEW | 31 | Expected. Counteroffer is a major Module 2 treatment path, especially under exposure and affordability constraints. |
| Final counteroffer feasibility and affordability conventions | REVIEW | 3 | Needs targeted narrative review for M2-09, M2-13, M2-30. |
| Decline zero-exposure and policy-stop reason convention | REVIEW | 1 | Needs targeted narrative review for M2-20. |
| Selected baseline / challenger comparison readiness | REVIEW | 1 | M2-01 run-time artifact; now superseded by Query 12. |
| Immutable Module 1 source fields match across matched comparison rows | NOT_APPLICABLE | 1 | M2-01 run-time artifact; now superseded by Query 13. |

This is not a structural failure. Section 14 explicitly treats `REVIEW` as a prompt for interpretation before documentation, not automatic invalidation. fileciteturn184file17

The key supporting point is that your earlier Query 9 showed **zero hard convention violations** across all 1.8M archived rows. So the Query 11 REVIEW rows should be handled as validation-narrative items, not implementation defects.

---

## Query 12 — Comparison registry readiness

**Verdict: PASS.**

All **17 comparison groups** are ready:

```text
baseline_archived_rows = 50,000
challenger_archived_rows = 50,000
comparison_readiness_status = COMPARISON_READY
```

This is a major acceptance point. It confirms that every planned baseline/challenger comparison pair exists in the archive with full row counts:

```text
CG01–CG06: baseline strategy frontier on BASELINE_V2
CG07–CG09: rate sensitivity comparisons
CG10–CG12: credit-box sensitivity comparisons
CG13–CG14: portfolio-mix sensitivity comparisons
CG15: exposure-intensity sensitivity comparison
CG16–CG17: LGD severity sensitivity comparisons
```

The corrected SC05 name also appears properly:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
HIGH_BALANCE_APPETITE
```

So the prior registry naming issue is resolved in the comparison layer.

---

## Query 13 — Matched comparison source-field consistency

**Verdict: PASS — very strong result.**

All **17 comparison groups** show:

```text
matched_application_count = 50,000
source_field_mismatch_count = 0
source_consistency_status = SOURCE_FIELDS_MATCH
```

Every individual source-field mismatch count is also zero:

```text
product_type_mismatch_count = 0
score_band_mismatch_count = 0
credit_score_mismatch_count = 0
annual_income_mismatch_count = 0
requested_amount_mismatch_count = 0
requested_payment_mismatch_count = 0
requested_pti_mismatch_count = 0
amount_to_income_mismatch_count = 0
estimated_pd_mismatch_count = 0
estimated_lgd_mismatch_count = 0
requested_expected_loss_mismatch_count = 0
```

This is one of the most important results in the whole campaign. It proves the comparisons are not contaminated by Module 1 source drift. The observed deltas in Query 15 can be interpreted as **Module 2 strategy effects**, not population mismatch or source-selection error.

---

## Query 14 — Executive evidence campaign summary

**Verdict: PASS structurally, with one evidence-freshness follow-up.**

The executive evidence table has all **36 campaign runs**, each with:

```text
applications = 50,000
module3_growth_inputs_available_flag = TRUE
```

Validation summary in Query 14 reconciles to the earlier validation totals:

```text
validation_pass_count total             = 719
validation_review_count total           = 72
validation_not_applicable_count total   = 1
```

Run-level ranges look coherent:

| Metric | Min | Max | Interpretation |
|---|---:|---:|---|
| Approval rate | 10.854% | 31.228% | Lowest under credit stress + tighter risk; highest under rate-down + growth. |
| Counteroffer rate | 27.140% | 45.406% | Highest under near-prime expansion + counteroffer-first. |
| Manual-review rate | 9.440% | 16.410% | Lowest under manual-review reduction; highest under broad LGD stress + guardrails. |
| Decline rate | 15.082% | 50.748% | Lowest under prime-growth score mix; highest under credit stress + tighter risk. |
| Simulated offer exposure rate | 37.994% | 72.420% | Lowest under credit stress + tighter risk; highest under prime-growth baseline. |
| Approved amount capture rate | 39.792% | 66.107% | Lowest under credit stress + tighter risk; highest under prime-growth baseline. |
| Approved EL rate | 1.275% | 2.007% | Lowest under prime-growth baseline; highest under credit-stress baseline. |

Those extremes make sense.

### Frontier classification distribution

Query 14 shows:

```text
BASELINE_REFERENCE_POINT                  19
RISK_DISCIPLINE_FRONTIER_POINT             3
COUNTEROFFER_MANAGEMENT_FRONTIER_POINT     2
GROWTH_ORIENTED_FRONTIER_POINT             1
REVIEW_BURDEN_REDUCTION_FRONTIER_POINT     1
BALANCED_OR_MIXED_FRONTIER_POINT           1
NO_BASELINE_REFERENCE_AVAILABLE            9
```

The first six categories are interpretable and useful. Section 15 classifies archived frontier points using diagnostic strategy posture labels; those labels are designed for executive interpretation, not production recommendations. fileciteturn184file11

### Follow-up: 9 stale or run-time frontier labels

The 9 `NO_BASELINE_REFERENCE_AVAILABLE` rows are the only item I would flag:

```text
M2-11  RATE_UP_200BP / TIGHTER_AFFORDABILITY_STRATEGY
M2-12  RATE_UP_300BP / TIGHTER_AFFORDABILITY_STRATEGY
M2-13  RATE_DOWN_200BP / GROWTH_ORIENTED_STRATEGY
M2-18  NEAR_PRIME_EXPANSION_MIX / COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
M2-23  UNSECURED_GROWTH_MIX / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
M2-26  REVOLVING_LINE_EXPANSION_MIX / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
M2-29  HIGH_BALANCE_APPETITE / COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
M2-34  UNSECURED_SEVERITY_STRESS / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
M2-36  BROAD_LGD_STRESS / PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
```

But Query 12 and Query 15 prove those baseline/challenger pairs now exist and compare correctly. So this is not a data defect. It means the saved Section 16 executive evidence for those rows likely captured Section 15 frontier state before the full campaign comparison landscape was complete, or before the final post-campaign comparison context was available.

Recommendation: before final README / Validation Summary drafting, either:

```text
1. Treat Query 15 as the authoritative post-campaign comparison-delta table; or
2. Refresh the frontier fields in strategy_run_evidence_summary from a fresh post-campaign Section 15 run.
```

I would do option 2 if you want Query 14 to be the final single executive evidence table.

---

## Query 15 — Baseline vs challenger delta summary

**Verdict: PASS — strategy behavior is directionally coherent and strongly interpretable.**

Query 15 is the most important analytical result so far. It shows the strategy families doing what they were designed to do.

### Tighter synthetic risk

Comparison groups:

```text
CG01, CG10, CG12
```

Observed pattern:

```text
Offer exposure down:      -2.514 to -3.306 percentage points
Approved amount down:     -$151.3M to -$220.9M
Approved EL down:         -$7.3M to -$9.6M
Approved EL rate down:    -0.133 to -0.252 percentage points
Offer-row PD proxy down:  -0.785 to -1.496 percentage points
Decline rate up:          +4.358 to +7.258 percentage points
```

Interpretation:

```text
Strong risk-discipline behavior.
The strategy gives up access and approved exposure to reduce approved Expected Loss and improve the offered-population synthetic-risk profile.
```

CG12 under `CREDIT_STRESS_SCORE_MIX` is especially strong: tighter risk reduces approved EL by about **$9.41M** and lowers offered-row synthetic PD proxy by about **1.50 percentage points**, while increasing decline rate by about **7.26 percentage points**.

### Growth oriented

Comparison groups:

```text
CG02, CG09
```

Observed pattern:

```text
Offer exposure up:        +2.986 to +3.166 percentage points
Approval rate up:         +6.254 to +6.720 percentage points
Approved amount up:       +$238.0M to +$280.4M
Approved EL up:           +$8.8M to +$9.4M
Approved EL rate up:      about +0.123 to +0.127 percentage points
Decline rate down:        about -3.45 percentage points
```

Interpretation:

```text
Clean growth tradeoff.
The strategy expands approvals, offer exposure, and approved amount, with a measurable approved Expected Loss increase.
```

This is exactly what a growth-oriented challenger should do.

### Tighter affordability

Comparison groups:

```text
CG03, CG07, CG08
```

Observed pattern:

```text
Offer exposure down:      -3.186 to -3.320 percentage points
Approval rate down:       -3.224 to -3.684 percentage points
Approved amount down:     -$274.8M to -$290.0M
Approved EL down:         -$3.6M to -$3.9M
Offer-row approved PTI down: -0.267 to -0.400 percentage points
Manual review up:         +1.774 to +1.918 percentage points
Decline up:               about +1.40 percentage points
```

Interpretation:

```text
Affordability discipline is working.
The strategy reduces approved exposure and offer-row PTI, but it is not a pure risk-rate reducer; approved EL rate moves only slightly upward in some cases due to mix effects.
```

This is fine and should be narrated correctly: the strategy is about **payment-burden discipline**, not simply minimizing approved EL rate.

### Counteroffer-first exposure strategy

Comparison groups:

```text
CG04, CG11, CG15
```

Observed pattern:

```text
Offer exposure up:        +0.986 to +1.148 percentage points
Approval rate down:       -2.000 to -2.672 percentage points
Counteroffer rate up:     +3.102 to +3.820 percentage points
Manual review down:       -0.986 to -1.148 percentage points
Decline rate unchanged:    0.000 percentage points
Approved amount down:     -$189.2M to -$222.8M
Approved EL down:         -$4.2M to -$5.9M
Offer-row approved PTI down: -0.853 to -0.986 percentage points
```

Interpretation:

```text
Very clean counteroffer-management behavior.
The strategy shifts outcomes from approval/manual review into reduced-exposure counteroffers, preserves or slightly expands simulated positive offer exposure, and lowers approved exposure and approved Expected Loss.
```

CG15 under `HIGH_BALANCE_APPETITE` is especially useful for the final narrative: high-balance demand plus counteroffer-first treatment reduces approved exposure by about **$215.5M** and approved EL by about **$4.88M**, while increasing counteroffer rate by about **3.15 percentage points**.

### Product-specific guardrails

Comparison groups:

```text
CG05, CG13, CG14, CG16, CG17
```

Observed pattern:

```text
Offer exposure down:      -0.680 to -0.992 percentage points
Approval rate down:       -1.712 to -2.420 percentage points
Counteroffer rate up:     +0.720 to +1.532 percentage points
Manual review up:         +0.680 to +0.992 percentage points
Decline rate unchanged:    0.000 percentage points
Approved amount down:     -$37.0M to -$56.3M
Approved EL down:         -$2.0M to -$3.0M
Approved EL rate down:    -0.039 to -0.072 percentage points
Offer-row PD proxy down:  modestly negative
Offer-row approved PTI down: modestly negative
```

Interpretation:

```text
Product guardrails are behaving as targeted guardrails rather than blunt declines.
They reduce approved exposure and approved EL, especially in product-mix / severity contexts, without increasing decline rate.
```

That is a good result. It means the guardrails are shifting approval behavior into counteroffer/manual review and lowering approved exposure risk without functioning as broad no-offer policy stops.

### Manual-review reduction

Comparison group:

```text
CG06
```

Observed pattern:

```text
Manual review rate down:  -4.438 percentage points
Decline rate up:          +4.438 percentage points
Offer exposure unchanged:  0.000
Approved amount unchanged: 0.000
Approved EL unchanged:     0.000
```

Interpretation:

```text
Extremely clean parameter behavior.
The strategy changes unresolved manual-review disposition into final no-offer disposition without changing positive-offer exposure economics.
```

This is exactly what `failed_counteroffer_resolution = 'DECLINE'` should demonstrate.

---

## Main conclusion from Queries 11–15

I would summarize this batch as:

```text
1. Validation REVIEW items are expected interpretive prompts, not structural defects.
2. All 17 baseline/challenger comparison groups are comparison-ready.
3. All 17 matched comparisons have perfect Module 1 source-field consistency.
4. Executive evidence is complete for all 36 runs.
5. Strategy deltas are directionally coherent and explainable.
6. The only cleanup recommendation is to refresh stale frontier labels in the executive evidence rows where Query 14 still says NO_BASELINE_REFERENCE_AVAILABLE despite post-campaign comparisons now being ready.
```

The campaign is analytically ready. Before writing the final validation summary, I would refresh the affected frontier/evidence labels or clearly treat Query 15 as the authoritative post-campaign comparison table.
<!-- END_MESSAGE C038-M01294 -->


---

<a id="c038-m01295"></a>

### C038-M01295

**Andrew** · 2026-05-11T14:57:11.230000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01295 -->
how do I: 2. Refresh the frontier fields in strategy_run_evidence_summary from a fresh post-campaign Section 15 run. and 6. The only cleanup recommendation is to refresh stale frontier labels in the executive evidence rows where Query 14 still says NO_BASELINE_REFERENCE_AVAILABLE despite post-campaign comparisons now being ready. give me step by step.
<!-- END_MESSAGE C038-M01295 -->


---

<a id="c038-m01301"></a>

### C038-M01301

**ChatGPT** · 2026-05-11T15:01:42.986704-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01301 -->
Yes. The clean way is to **rerun Section 15 after the full campaign archive is complete**, then use the fresh Section 15 temporary frontier output to update the stale Section 15-derived fields in the persistent executive evidence table.

Do **not** rerun full Section 16 expecting it to refresh all 36 runs. Section 16.6 captures the **current latest-run table**, not every archived run, so one Section 16 rerun only refreshes the current latest-run slice. Section 15 is the correct source for this cleanup because it reads the full archive and creates `tmp_m2_strategy_frontier_executive_summary` across archived strategy/scenario slices. fileciteturn184file11 Section 16.6 then stores Section 15 frontier fields into `strategy_run_evidence_summary`, but it does that at the current-run grain during each run. fileciteturn184file4

Below is the exact step-by-step.

---

## Step 1 — Do not run Section 1

Do **not** start from Section 1 for this refresh. Section 1 drops the replaceable latest-run table, and the operating guidance explicitly says not to run Section 1 by itself when the goal is only to refresh Section 15 frontier outputs or Section 16 evidence capture. fileciteturn184file50

For this cleanup, start at:

```text
SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
```

Run **all of Section 15** through the creation of:

```sql
tmp_m2_strategy_frontier_executive_summary
```

Section 15 is read-only against the archive. It does not change latest-run output or archive rows. fileciteturn184file11

---

## Step 2 — Confirm fresh Section 15 output is post-campaign complete

Run this immediately after rerunning Section 15.

```sql
/***************************************************************************************************
STEP 2 — CONFIRM FRESH SECTION 15 FRONTIER OUTPUT IS COMPLETE

Expected:
    frontier_rows = 36
    distinct_frontier_keys = 36
    no_baseline_reference_rows = 0
***************************************************************************************************/

SELECT
    COUNT(*) AS frontier_rows,

    COUNT(DISTINCT (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    )) AS distinct_frontier_keys,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'
    ) AS no_baseline_reference_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type IS NULL
           OR executive_frontier_quadrant IS NULL
           OR frontier_interpretation_note IS NULL
    ) AS frontier_required_field_gap_rows

FROM tmp_m2_strategy_frontier_executive_summary;
```

Expected:

```text
frontier_rows                    = 36
distinct_frontier_keys           = 36
no_baseline_reference_rows       = 0
frontier_required_field_gap_rows = 0
```

If `no_baseline_reference_rows` is still greater than zero here, stop. That means Section 15 itself is still not seeing the completed baseline references, and we should diagnose Section 15 before updating persistent evidence.

---

## Step 3 — Preview stale executive evidence rows before update

This shows the stale rows currently stored in `strategy_run_evidence_summary`.

```sql
/***************************************************************************************************
STEP 3 — PREVIEW STALE FRONTIER LABELS IN PERSISTENT EXECUTIVE EVIDENCE

Expected based on Query 14:
    9 rows with NO_BASELINE_REFERENCE_AVAILABLE.
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

    frontier_position_type,
    executive_frontier_quadrant,
    frontier_interpretation_note,
    observed_storyline

FROM credit_decisioning_sim.strategy_run_evidence_summary

WHERE frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'

ORDER BY run_sequence_number;
```

Expected stale run IDs should be the 9 we identified:

```text
M2-11
M2-12
M2-13
M2-18
M2-23
M2-26
M2-29
M2-34
M2-36
```

---

## Step 4 — Preview the before/after mapping

This shows exactly what each stale evidence row will become after joining to fresh Section 15 output.

```sql
/***************************************************************************************************
STEP 4 — PREVIEW FRONTIER REFRESH MAPPING

Purpose:
    Confirm stale persistent executive evidence rows can be matched to fresh Section 15 frontier rows.

Expected:
    9 matched rows.
    old_frontier_position_type = NO_BASELINE_REFERENCE_AVAILABLE
    new_frontier_position_type should be a real strategy posture label.
***************************************************************************************************/

SELECT
    e.run_sequence_number,
    e.module2_run_id,

    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,
    e.strategy_name,
    e.strategy_version,

    e.frontier_position_type AS old_frontier_position_type,
    f.frontier_position_type AS new_frontier_position_type,

    e.executive_frontier_quadrant AS old_executive_frontier_quadrant,
    f.executive_frontier_quadrant AS new_executive_frontier_quadrant,

    e.frontier_interpretation_note AS old_frontier_interpretation_note,
    f.frontier_interpretation_note AS new_frontier_interpretation_note,

    e.top_reason_code_delta_driver_code AS old_top_reason_code_delta_driver_code,
    f.top_reason_code_delta_driver_code AS new_top_reason_code_delta_driver_code,

    e.top_reason_code_delta_population_share AS old_top_reason_code_delta_population_share,
    f.top_reason_code_delta_population_share AS new_top_reason_code_delta_population_share

FROM credit_decisioning_sim.strategy_run_evidence_summary e

JOIN tmp_m2_strategy_frontier_executive_summary f
    ON f.strategy_set_name = e.strategy_set_name
   AND f.strategy_name = e.strategy_name
   AND f.strategy_version = e.strategy_version
   AND f.module1_scenario_set_name = e.module1_scenario_set_name
   AND f.module1_scenario_name = e.module1_scenario_name
   AND f.population_id = e.population_id

WHERE e.frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'

ORDER BY e.run_sequence_number;
```

If this returns fewer than 9 rows, stop and inspect the technical keys. The update should only be run when every stale row maps to one fresh frontier row.

---

## Step 5 — Optional but recommended: create a permanent backup

This gives you a rollback reference even after commit.

```sql
/***************************************************************************************************
STEP 5 — OPTIONAL BACKUP BEFORE FRONTIER REFRESH

Purpose:
    Preserve the current executive evidence table before updating frontier fields.
***************************************************************************************************/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_evidence_summary_backup_pre_frontier_refresh;

CREATE TABLE credit_decisioning_sim.strategy_run_evidence_summary_backup_pre_frontier_refresh AS
SELECT *
FROM credit_decisioning_sim.strategy_run_evidence_summary;
```

---

## Step 6 — Update the stale frontier fields from fresh Section 15

This updates the Section 15-derived frontier fields in `strategy_run_evidence_summary`.

It updates:

```text
frontier_position_type
executive_frontier_quadrant
frontier_interpretation_note
top_reason_code_delta_driver_family
top_reason_code_delta_driver_code
top_reason_code_delta_driver_baseline_share
top_reason_code_delta_driver_strategy_share
top_reason_code_delta_population_share
observed_storyline, only when it appears blank or stale/auto-derived
```

Run this inside a transaction.

```sql
/***************************************************************************************************
STEP 6 — REFRESH STALE FRONTIER FIELDS IN EXECUTIVE EVIDENCE SUMMARY

Purpose:
    Replace stale NO_BASELINE_REFERENCE_AVAILABLE frontier labels using the fresh post-campaign
    Section 15 archive-backed frontier output.

Important:
    This updates persistent evidence fields only.

    It does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive
        strategy parameters
        product policy parameters
        decision outcomes
        approved exposure
        approved Expected Loss
        reason codes
***************************************************************************************************/

BEGIN;

WITH refreshed_frontier AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        frontier_position_type,
        executive_frontier_quadrant,
        frontier_interpretation_note,

        top_reason_code_delta_driver_family,
        top_reason_code_delta_driver_code,
        top_reason_code_delta_driver_baseline_share,
        top_reason_code_delta_driver_strategy_share,
        top_reason_code_delta_population_share

    FROM tmp_m2_strategy_frontier_executive_summary
),

updated_rows AS (
    UPDATE credit_decisioning_sim.strategy_run_evidence_summary e
    SET
        /*******************************************************************************************
        Section 15 frontier posture fields.
        *******************************************************************************************/
        frontier_position_type = f.frontier_position_type,
        executive_frontier_quadrant = f.executive_frontier_quadrant,
        frontier_interpretation_note = f.frontier_interpretation_note,

        /*******************************************************************************************
        Section 15 baseline-relative reason-code movement fields.
        *******************************************************************************************/
        top_reason_code_delta_driver_family = f.top_reason_code_delta_driver_family,
        top_reason_code_delta_driver_code = f.top_reason_code_delta_driver_code,
        top_reason_code_delta_driver_baseline_share = f.top_reason_code_delta_driver_baseline_share,
        top_reason_code_delta_driver_strategy_share = f.top_reason_code_delta_driver_strategy_share,
        top_reason_code_delta_population_share = f.top_reason_code_delta_population_share,

        /*******************************************************************************************
        Observed storyline refresh.

        Preserve manually populated observed_storyline values.

        Refresh observed_storyline only when it is blank, exactly equal to the old frontier note, or
        appears to be the stale auto-derived "no baseline" note.
        *******************************************************************************************/
        observed_storyline =
            CASE
                WHEN e.observed_storyline IS NULL
                  OR e.observed_storyline = e.frontier_interpretation_note
                  OR e.observed_storyline ILIKE '%No baseline strategy slice exists%'
                  OR e.observed_storyline ILIKE '%No baseline reference%'
                    THEN f.frontier_interpretation_note
                ELSE e.observed_storyline
            END

    FROM refreshed_frontier f

    WHERE e.strategy_set_name = f.strategy_set_name
      AND e.strategy_name = f.strategy_name
      AND e.strategy_version = f.strategy_version
      AND e.module1_scenario_set_name = f.module1_scenario_set_name
      AND e.module1_scenario_name = f.module1_scenario_name
      AND e.population_id = f.population_id

      /*******************************************************************************************
      Limit the update to stale rows.

      This avoids rewriting all 36 evidence rows unnecessarily.
      *******************************************************************************************/
      AND e.frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'

    RETURNING
        e.run_sequence_number,
        e.module1_run_id,
        e.module2_run_id,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,
        e.strategy_name,
        e.strategy_version,
        e.frontier_position_type,
        e.executive_frontier_quadrant,
        e.frontier_interpretation_note,
        e.top_reason_code_delta_driver_code,
        e.top_reason_code_delta_population_share
)

SELECT *
FROM updated_rows
ORDER BY run_sequence_number;
```

Review the returned rows. You should see the 9 stale runs updated to meaningful frontier classifications such as:

```text
TIGHTER_AFFORDABILITY_STRATEGY      → likely BALANCED_OR_MIXED_FRONTIER_POINT or related affordability posture
GROWTH_ORIENTED_STRATEGY            → GROWTH_ORIENTED_FRONTIER_POINT
COUNTEROFFER_FIRST_EXPOSURE_STRATEGY → COUNTEROFFER_MANAGEMENT_FRONTIER_POINT
PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY → often BALANCED_OR_MIXED_FRONTIER_POINT or risk/guardrail posture depending on deltas
```

Then verify before committing:

```sql
/***************************************************************************************************
STEP 6B — VERIFY REFRESH BEFORE COMMIT

Expected:
    stale_no_baseline_reference_rows = 0
***************************************************************************************************/

SELECT
    COUNT(*) FILTER (
        WHERE frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'
    ) AS stale_no_baseline_reference_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type IS NULL
           OR executive_frontier_quadrant IS NULL
           OR frontier_interpretation_note IS NULL
    ) AS missing_frontier_field_rows

FROM credit_decisioning_sim.strategy_run_evidence_summary;
```

Expected:

```text
stale_no_baseline_reference_rows = 0
missing_frontier_field_rows      = 0
```

Now commit:

```sql
COMMIT;
```

If the verification does **not** look right, use:

```sql
ROLLBACK;
```

Do not leave the transaction open.

---

## Step 7 — Post-commit verification

After `COMMIT`, rerun this.

```sql
/***************************************************************************************************
STEP 7 — POST-COMMIT FRONTIER REFRESH VERIFICATION

Expected:
    no_baseline_reference_rows = 0
    executive_evidence_rows = 36
***************************************************************************************************/

SELECT
    COUNT(*) AS executive_evidence_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'
    ) AS no_baseline_reference_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'BASELINE_REFERENCE_POINT'
    ) AS baseline_reference_point_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'RISK_DISCIPLINE_FRONTIER_POINT'
    ) AS risk_discipline_frontier_point_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'GROWTH_ORIENTED_FRONTIER_POINT'
    ) AS growth_oriented_frontier_point_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'COUNTEROFFER_MANAGEMENT_FRONTIER_POINT'
    ) AS counteroffer_management_frontier_point_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'REVIEW_BURDEN_REDUCTION_FRONTIER_POINT'
    ) AS review_burden_reduction_frontier_point_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'EXPOSURE_EFFICIENT_FRONTIER_POINT'
    ) AS exposure_efficient_frontier_point_rows,

    COUNT(*) FILTER (
        WHERE frontier_position_type = 'BALANCED_OR_MIXED_FRONTIER_POINT'
    ) AS balanced_or_mixed_frontier_point_rows

FROM credit_decisioning_sim.strategy_run_evidence_summary;
```

Then rerun Query 14. The stale `NO_BASELINE_REFERENCE_AVAILABLE` rows should be gone.

---

## Step 8 — Confirm the specific formerly stale runs

```sql
/***************************************************************************************************
STEP 8 — CONFIRM FORMERLY STALE RUNS NOW HAVE REFRESHED FRONTIER LABELS

Expected:
    None of these rows should have NO_BASELINE_REFERENCE_AVAILABLE.
***************************************************************************************************/

SELECT
    run_sequence_number,
    module1_run_id,
    module2_run_id,
    showcase_id,
    showcase_name,
    comparison_group_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_name,
    strategy_version,

    frontier_position_type,
    executive_frontier_quadrant,
    frontier_interpretation_note,

    top_reason_code_delta_driver_code,
    top_reason_code_delta_population_share,
    observed_storyline

FROM credit_decisioning_sim.strategy_run_evidence_summary

WHERE module2_run_id IN (
    'M2-11',
    'M2-12',
    'M2-13',
    'M2-18',
    'M2-23',
    'M2-26',
    'M2-29',
    'M2-34',
    'M2-36'
)

ORDER BY run_sequence_number;
```

---

## Step 9 — Final acceptance check

```sql
/***************************************************************************************************
STEP 9 — FINAL FRONTIER EVIDENCE REFRESH ACCEPTANCE CHECK

Expected:
    FRONTIER_EVIDENCE_REFRESH_READY
***************************************************************************************************/

WITH evidence_summary AS (
    SELECT
        COUNT(*) AS executive_evidence_rows,

        COUNT(*) FILTER (
            WHERE frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'
        ) AS no_baseline_reference_rows,

        COUNT(*) FILTER (
            WHERE frontier_position_type IS NULL
               OR executive_frontier_quadrant IS NULL
               OR frontier_interpretation_note IS NULL
        ) AS frontier_required_field_gap_rows,

        COUNT(*) FILTER (
            WHERE strategy_name <> 'BASELINE_STRATEGY'
              AND top_reason_code_delta_driver_code IS NULL
        ) AS challenger_rows_missing_reason_code_delta_driver
    FROM credit_decisioning_sim.strategy_run_evidence_summary
)

SELECT
    executive_evidence_rows,
    no_baseline_reference_rows,
    frontier_required_field_gap_rows,
    challenger_rows_missing_reason_code_delta_driver,

    CASE
        WHEN executive_evidence_rows = 36
         AND no_baseline_reference_rows = 0
         AND frontier_required_field_gap_rows = 0
            THEN 'FRONTIER_EVIDENCE_REFRESH_READY'
        ELSE 'REVIEW_FRONTIER_EVIDENCE_REFRESH'
    END AS frontier_evidence_refresh_status

FROM evidence_summary;
```

The `challenger_rows_missing_reason_code_delta_driver` field is diagnostic. I would not automatically fail the refresh solely on that count unless you expected every challenger to have a non-null top reason-code delta. The key acceptance point for your stated cleanup is:

```text
no_baseline_reference_rows = 0
frontier_evidence_refresh_status = FRONTIER_EVIDENCE_REFRESH_READY
```

---

## Important boundary

This refresh updates only the **persistent executive evidence fields derived from Section 15**. It does not rewrite row-level decisions, archive rows, validation rows, parameter snapshots, or product × score segment evidence. That is appropriate because the issue was stale executive frontier labeling, not a decision-output or archive-integrity issue. Section 16’s evidence layer exists to persist executive story, validation evidence, parameter snapshots, and segment evidence separately from the archive itself. fileciteturn184file9
<!-- END_MESSAGE C038-M01301 -->


---

<a id="c038-m01303"></a>

### C038-M01303

**Andrew** · 2026-05-11T15:20:28.920000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01303 -->
thanks.  it corrected.  here is updated query 14.  do I need to re-provide anything from query 1-13 or 15?  would anything in those have changed?
<!-- END_MESSAGE C038-M01303 -->


---

<a id="c038-m01306"></a>

### C038-M01306

**ChatGPT** · 2026-05-11T15:21:55.507052-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01306 -->
No — you do **not** need to re-provide Queries **1–13** or **15**.

The refresh you performed changed only the **persistent executive evidence table’s Section 15-derived frontier fields**, specifically in:

```text
credit_decisioning_sim.strategy_run_evidence_summary
```

That means **Query 14 changed**, because Query 14 reads from that executive evidence summary table. The other results should be unchanged unless your refresh script accidentally updated something beyond `strategy_run_evidence_summary`.

## What changed

The refresh should have updated fields like:

```text
frontier_position_type
executive_frontier_quadrant
frontier_interpretation_note
top_reason_code_delta_driver_family
top_reason_code_delta_driver_code
top_reason_code_delta_driver_baseline_share
top_reason_code_delta_driver_strategy_share
top_reason_code_delta_population_share
observed_storyline, if your update included the conditional refresh
```

That is consistent with the design: Section 15 creates archive-backed frontier classifications, while Section 16.6 persists those frontier fields into the executive evidence summary for each run. fileciteturn184file11 fileciteturn184file4

## What should not have changed

| Query | Should it change? | Reason |
|---:|---|---|
| 1 | No | Reads Module 2 archive inventory. You did not change archive rows. |
| 2 | No | Reads archive slice detail. Archive unchanged. |
| 3 | No | Checks archive grain duplicates. Archive unchanged. |
| 4 | No | Reconciles campaign registry to archive. Registry and archive unchanged. |
| 5 | No | Shows missing / mismatched registry-to-archive rows. Registry and archive unchanged. |
| 6 | No | Checks orphan archive slices. Archive and registry unchanged. |
| 7 | No, except same counts | Evidence coverage counts should remain identical: still 36 executive rows, 36 parameter snapshots, etc. |
| 8 | No, except same counts | Evidence detail counts should remain identical. Field contents changed, not row counts. |
| 9 | No | Reads full archive final-output conventions. Archive unchanged. |
| 10 | No | Reads validation evidence. You did not update validation evidence. |
| 11 | No | Reads validation-review concentration. Validation evidence unchanged. |
| 12 | No | Reads comparison registry and archive readiness. Registry and archive unchanged. |
| 13 | No | Reads matched comparison source-field consistency from archive. Archive unchanged. |
| 15 | No | Calculates baseline/challenger deltas from archive and comparison registry. Archive and registry unchanged. |

The critical point is that Sections 12 and 13 operate on the archive / comparison layer, and your refresh did not alter those objects. Section 12 is the archive persistence layer, and Section 13 performs matched comparison from archived slices without mutating archive rows. fileciteturn184file20 fileciteturn184file19

## What I would ask you to re-provide

Only the updated:

```text
Query 14 — Executive Evidence Campaign Summary
```

And optionally the post-refresh verification query showing:

```text
no_baseline_reference_rows = 0
executive_evidence_rows = 36
```

That is enough to confirm the stale frontier labels were corrected.

## One optional sanity check

You can run this compact check to confirm the refresh did not change evidence table row counts:

```sql
SELECT
    COUNT(*) AS executive_evidence_rows,
    COUNT(*) FILTER (
        WHERE frontier_position_type = 'NO_BASELINE_REFERENCE_AVAILABLE'
    ) AS no_baseline_reference_rows,
    COUNT(*) FILTER (
        WHERE frontier_position_type IS NULL
           OR executive_frontier_quadrant IS NULL
           OR frontier_interpretation_note IS NULL
    ) AS frontier_field_gap_rows
FROM credit_decisioning_sim.strategy_run_evidence_summary;
```

Expected:

```text
executive_evidence_rows        = 36
no_baseline_reference_rows     = 0
frontier_field_gap_rows        = 0
```

So: **re-send updated Query 14 only. Query 15 and Queries 1–13 should remain valid as already reviewed.**
<!-- END_MESSAGE C038-M01306 -->


---

<a id="c038-m01307"></a>

### C038-M01307

**Andrew** · 2026-05-11T15:25:53.540000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01307 -->
forgot to attach and i confirm no_baseline_reference_rows = 0 and executive_evidence_rows = 36.
<!-- END_MESSAGE C038-M01307 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_14_executive_evidence_campaign_summary(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01315"></a>

### C038-M01315

**ChatGPT** · 2026-05-11T15:29:59.808296-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01315 -->
I reviewed the updated Query 14 file. The frontier refresh worked and Query 14 is now **clean enough for final campaign analysis**.

```text
STATUS: PASS — UPDATED QUERY 14 IS READY
```

The important correction is confirmed:

```text
executive_evidence_rows        = 36
no_baseline_reference_rows     = 0
frontier_required_field_gaps   = 0
```

That is exactly what we wanted after refreshing the Section 15-derived frontier fields in `strategy_run_evidence_summary`. Section 15 is the archive-backed strategy frontier layer, and Section 16 persists those frontier outputs into the executive evidence table. fileciteturn184file11 fileciteturn184file9

## What changed in Query 14

These 9 rows were corrected from stale:

```text
NO_BASELINE_REFERENCE_AVAILABLE
```

into real frontier classifications:

| Run | Scenario | Strategy | Updated frontier position |
|---|---|---|---|
| M2-11 | `RATE_UP_200BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | `BALANCED_OR_MIXED_FRONTIER_POINT` |
| M2-12 | `RATE_UP_300BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | `BALANCED_OR_MIXED_FRONTIER_POINT` |
| M2-13 | `RATE_DOWN_200BP` | `GROWTH_ORIENTED_STRATEGY` | `GROWTH_ORIENTED_FRONTIER_POINT` |
| M2-18 | `NEAR_PRIME_EXPANSION_MIX` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `COUNTEROFFER_MANAGEMENT_FRONTIER_POINT` |
| M2-23 | `UNSECURED_GROWTH_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `COUNTEROFFER_MANAGEMENT_FRONTIER_POINT` |
| M2-26 | `REVOLVING_LINE_EXPANSION_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `COUNTEROFFER_MANAGEMENT_FRONTIER_POINT` |
| M2-29 | `HIGH_BALANCE_APPETITE` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `COUNTEROFFER_MANAGEMENT_FRONTIER_POINT` |
| M2-34 | `UNSECURED_SEVERITY_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `BALANCED_OR_MIXED_FRONTIER_POINT` |
| M2-36 | `BROAD_LGD_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `BALANCED_OR_MIXED_FRONTIER_POINT` |

That correction is coherent with the campaign design.

## Updated frontier distribution

The refreshed Query 14 now shows:

| Frontier position | Count | Interpretation |
|---|---:|---|
| `BASELINE_REFERENCE_POINT` | 19 | Baseline strategy rows across the Module 1 scenario campaign |
| `COUNTEROFFER_MANAGEMENT_FRONTIER_POINT` | 6 | Counteroffer-first and several guardrail strategies shifting outcomes toward reduced-exposure treatment |
| `BALANCED_OR_MIXED_FRONTIER_POINT` | 5 | Affordability-tight and severity/guardrail rows with mixed tradeoffs |
| `RISK_DISCIPLINE_FRONTIER_POINT` | 3 | Tighter synthetic-risk rows |
| `GROWTH_ORIENTED_FRONTIER_POINT` | 2 | Growth-oriented rows |
| `REVIEW_BURDEN_REDUCTION_FRONTIER_POINT` | 1 | Manual-review reduction strategy |

This is analytically sensible. Each strategy family is now classified in the expected direction.

## Strategy-family classification check

The strategy classifications now line up well:

| Strategy | Frontier result |
|---|---|
| `BASELINE_STRATEGY` | 19 baseline reference points |
| `TIGHTER_SYNTHETIC_RISK_STRATEGY` | 3 risk-discipline points |
| `GROWTH_ORIENTED_STRATEGY` | 2 growth-oriented points |
| `TIGHTER_AFFORDABILITY_STRATEGY` | 3 balanced/mixed points |
| `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | 3 counteroffer-management points |
| `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | 3 counteroffer-management points and 2 balanced/mixed points |
| `MANUAL_REVIEW_REDUCTION_STRATEGY` | 1 review-burden-reduction point |

That is the right story. The product guardrail strategy showing both counteroffer-management and balanced/mixed classifications is reasonable because its effect depends on the scenario context: it behaves more like counteroffer/exposure management in baseline, unsecured-growth, and revolving-expansion contexts, and more like mixed risk/exposure discipline under LGD severity stress.

## Executive metric ranges remain coherent

The refreshed Query 14 still has the expected metric profile:

| Metric | Range |
|---|---:|
| Approval rate | 10.854% to 31.228% |
| Counteroffer rate | 27.140% to 45.406% |
| Manual-review rate | 9.440% to 16.410% |
| Decline rate | 15.082% to 50.748% |
| Simulated offer-exposure rate | 37.994% to 72.420% |
| Approved amount capture rate | 39.792% to 66.107% |
| Approved Expected Loss rate | 1.275% to 2.007% |

The extremes make sense:

```text
Lowest access / highest decline:
    M2-20 — CREDIT_STRESS_SCORE_MIX + TIGHTER_SYNTHETIC_RISK_STRATEGY

Highest access:
    M2-15 — PRIME_GROWTH_SCORE_MIX + BASELINE_STRATEGY

Highest approved amount:
    M2-24 — SECURED_BALANCE_GROWTH_MIX + BASELINE_STRATEGY

Lowest approved Expected Loss rate:
    M2-15 — PRIME_GROWTH_SCORE_MIX + BASELINE_STRATEGY

Highest approved Expected Loss rate:
    M2-19 — CREDIT_STRESS_SCORE_MIX + BASELINE_STRATEGY
```

That is directionally coherent with the Module 1 scenarios and Module 2 strategy design.

## Evidence integrity check

Updated Query 14 now shows:

```text
applications total across evidence rows = 1,800,000
all rows have 50,000 applications
module3_growth_inputs_available_flag = TRUE for all 36 rows
frontier_position_type populated for all 36 rows
executive_frontier_quadrant populated for all 36 rows
frontier_interpretation_note populated for all 36 rows
top reason-code fields populated where expected
top reason-code delta driver populated for all 17 challenger rows
top reason-code delta driver null for all 19 baseline rows
```

That last point is exactly right: baseline rows do not need baseline-relative reason-code delta drivers.

## Validation counts remain unchanged

The validation evidence rollup remains:

```text
Total PASS             = 719
Total REVIEW           = 72
Total NOT_APPLICABLE   = 1
```

That matches the earlier Query 10 / Query 11 interpretation. `REVIEW` remains an interpretive status, not automatic invalidation; Section 14 explicitly treats review items as documentation prompts rather than failures. fileciteturn184file17

The one remaining `NOT_APPLICABLE` is still on M2-01, tied to run-time comparison readiness / source-field availability when that evidence row was originally captured. That is not a campaign failure because the post-campaign Query 12 and Query 13 comparison checks already confirmed all comparison pairs are ready and source fields match.

## Minor documentation note: comparison group IDs

Query 14 still has blank `comparison_group_id` for several baseline/reference rows. I would **not** treat that as a defect.

The executive evidence table is one row per run. Some baseline runs serve as reference points for one or more comparison groups, and one scalar `comparison_group_id` field cannot fully represent all comparison relationships. Query 12 and Query 15 remain the authoritative comparison registry / baseline-challenger mapping.

For final documentation, use:

```text
Query 14:
    run-level executive evidence

Query 15:
    comparison-level baseline/challenger deltas

Query 12:
    comparison registry readiness and pairing
```

## Final assessment

```text
UPDATED QUERY 14: PASS
FRONTIER REFRESH: COMPLETE
NO_BASELINE_REFERENCE_AVAILABLE: CLEARED
EXECUTIVE EVIDENCE ROWS: COMPLETE
MODULE 3 READINESS: COMPLETE
READY FOR FINAL CAMPAIGN ANALYSIS: YES
```

You do **not** need to resend Queries 1–13 or Query 15. They should remain valid. The only table materially changed by the refresh was the executive evidence summary table used by Query 14.
<!-- END_MESSAGE C038-M01315 -->


---

<a id="c038-m01317"></a>

### C038-M01317

**Andrew** · 2026-05-11T15:47:24.777000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01317 -->
review queries 16-20:  also, turn this into a section 17 of the code (give it our elite header/comment/inline comment teaching level):
<!-- END_MESSAGE C038-M01317 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_17_counteroffer_first_strategy_effect_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_16_product_guardrail_strategy_product_level_effect_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_20_campaign_acceptance_rollup.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_19_product_policy_snapshot_extraction_for_product_guardrail_runs.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_campaign_inventory_query_18_parameter_snapshot_profile_audit.csv`, `Pasted text(171).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_65.md) · [Next](Part_67.md)
