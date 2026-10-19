# Module 2 Decision Simulator Build

## Part 22

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_21.md) · [Next](Part_23.md)

<a id="c038-m00449"></a>

### C038-M00449

**ChatGPT** · 2026-05-08T13:29:21.894035-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00449 -->
Yes. With only 50k–100k archived rows, **Section 12.6 should not run for over an hour**. That points to a runtime/blocking issue or an expensive join pattern, not normal archive volume.

Most likely causes, in priority order:

## 1. Prior disconnected session is holding a lock

Because you previously had a network disconnection, the old PostgreSQL session may still be open and holding a lock on:

```sql
credit_decisioning_sim.strategy_decisions
credit_decisioning_sim.strategy_decisions_archive
```

If Section 12.6 is trying to create an index, delete/replace archive rows, insert rows, or run a validation join, it may simply be **waiting**, not actually processing.

Run this first:

```sql
SELECT
    pid,
    usename,
    state,
    wait_event_type,
    wait_event,
    now() - query_start AS runtime,
    left(query, 500) AS running_query
FROM pg_stat_activity
WHERE datname = current_database()
  AND state <> 'idle'
ORDER BY query_start;
```

If you see:

```text
wait_event_type = Lock
```

then it is blocked.

Then run:

```sql
SELECT
    blocked.pid AS blocked_pid,
    blocked.query AS blocked_query,
    blocking.pid AS blocking_pid,
    blocking.query AS blocking_query,
    blocking.state AS blocking_state,
    now() - blocking.query_start AS blocking_runtime
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks
    ON blocked_locks.pid = blocked.pid
JOIN pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
   AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
   AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
   AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
   AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
   AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
   AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
   AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
   AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
   AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
   AND blocking_locks.pid <> blocked_locks.pid
JOIN pg_stat_activity blocking
    ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

If the blocker is an abandoned/disconnected run, cancel the blocked query or terminate the blocker carefully.

Cancel current long-running query:

```sql
SELECT pg_cancel_backend(<blocked_pid>);
```

Terminate an abandoned blocking session:

```sql
SELECT pg_terminate_backend(<blocking_pid>);
```

Only terminate a backend if you are confident it is your stale session.

---

## 2. Section 12.6 may be doing a row-explosion join

If Section 12.6 is the archive persistence mismatch check, it should join latest-run rows to archive rows at the **full row grain**, including:

```sql
application_id
```

If it joins only on the replacement key:

```sql
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
```

then each 50,000-row latest slice can join to 50,000 archived rows, producing:

```text
50,000 × 50,000 = 2.5 billion joined rows
```

That would absolutely explain an hour-long query.

The join should look directionally like this:

```sql
FROM credit_decisioning_sim.strategy_decisions sd
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = sd.strategy_set_name
   AND ar.strategy_name = sd.strategy_name
   AND ar.strategy_version = sd.strategy_version
   AND ar.module1_scenario_set_name = sd.module1_scenario_set_name
   AND ar.module1_scenario_name = sd.module1_scenario_name
   AND ar.population_id = sd.population_id
   AND ar.application_id = sd.application_id
```

If `application_id` is missing from that join, that is a **BLOCKER patch**.

---

## 3. Unique index creation could be waiting on locks

If Section 12.6 is the unique archive grain index creation, it should also be quick at this size unless blocked.

The unique index is important:

```sql
strategy_set_name,
strategy_name,
strategy_version,
module1_scenario_set_name,
module1_scenario_name,
population_id,
application_id
```

But if another session is touching the archive table, `CREATE UNIQUE INDEX` may wait.

Check index activity:

```sql
SELECT
    pid,
    datname,
    relid::regclass AS table_name,
    index_relid::regclass AS index_name,
    phase,
    blocks_total,
    blocks_done,
    tuples_total,
    tuples_done
FROM pg_stat_progress_create_index;
```

If this returns a row and is progressing, let it run. If it is waiting on a lock, use the lock diagnostics above.

---

## My recommendation right now

Do not assume this is normal processing.

Run these two diagnostics first:

```sql
SELECT
    pid,
    usename,
    state,
    wait_event_type,
    wait_event,
    now() - query_start AS runtime,
    left(query, 500) AS running_query
FROM pg_stat_activity
WHERE datname = current_database()
  AND state <> 'idle'
ORDER BY query_start;
```

Then:

```sql
SELECT
    pid,
    wait_event_type,
    wait_event,
    now() - query_start AS runtime,
    left(query, 1000) AS running_query
FROM pg_stat_activity
WHERE query ILIKE '%strategy_decisions_archive%'
   OR query ILIKE '%strategy_decisions%';
```

Send me the output and, if possible, the exact Section 12.6 SQL block currently running.

Most likely outcome:

```text
If wait_event_type = Lock:
    stale disconnected session / blocking lock.

If no lock but query is running actively:
    likely row-explosion join or missing application_id join predicate.

If pg_stat_progress_create_index shows progress:
    index creation is running; wait unless blocked.
```
<!-- END_MESSAGE C038-M00449 -->


---

<a id="c038-m00451"></a>

### C038-M00451

**Andrew** · 2026-05-08T13:32:07.178000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00451 -->
*No text body is present in the export. This message may contain an image or attachment.*
<!-- END_MESSAGE C038-M00451 -->


**Attachments in export:** `image(67).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00453"></a>

### C038-M00453

**ChatGPT** · 2026-05-08T13:33:50.950671-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00453 -->
Your screenshot shows this is **not a lock wait**.

The long-running session has:

```text
pid = 13664
state = active
wait_event_type = NULL
wait_event = NULL
runtime ≈ 1h55m
running_query starts with SECTION 12.6 — LOCAL FAI...
```

That means PostgreSQL is actively working through the Section 12.6 block. With a 50,000-row latest table and 50,000-row archived slice, this is almost certainly a **row-explosion join** inside the Section 12.6 persistence mismatch check.

## Most likely cause

Section 12.6 is probably joining:

```sql
credit_decisioning_sim.strategy_decisions
```

to:

```sql
credit_decisioning_sim.strategy_decisions_archive
```

using only the archive replacement key:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
```

but not:

```text
application_id
```

If so, the join becomes:

```text
50,000 latest rows × 50,000 archived rows = 2.5 billion joined rows
```

That would explain the multi-hour runtime.

The archive **replacement key** excludes `application_id`, but the archive **row-level comparison / persistence mismatch check** must include `application_id`.

## Immediate action

Cancel the running query:

```sql
SELECT pg_cancel_backend(13664);
```

If it does not cancel after a reasonable wait:

```sql
SELECT pg_terminate_backend(13664);
```

Only terminate it if you are sure this is your abandoned / stuck Section 12.6 run.

## Targeted blocker patch — Section 12.6 persistence mismatch check

This is a **BLOCKER** if confirmed. It does not change strategy logic. It only fixes the archive validation join so it compares each latest-run application to its matching archived application.

### BEFORE — problematic pattern

Look for a Section 12.6 block that joins latest-run to archive like this, or directionally like this:

```sql
FROM credit_decisioning_sim.strategy_decisions sd
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = sd.strategy_set_name
   AND ar.strategy_name = sd.strategy_name
   AND ar.strategy_version = sd.strategy_version
   AND ar.module1_scenario_set_name = sd.module1_scenario_set_name
   AND ar.module1_scenario_name = sd.module1_scenario_name
   AND ar.population_id = sd.population_id
WHERE
       ar.decision_outcome IS DISTINCT FROM sd.decision_outcome
    OR ar.decision_path IS DISTINCT FROM sd.decision_path
    OR ...
```

The issue is that this compares every latest row to every archived row in the same replacement slice.

### AFTER — corrected row-level comparison

Patch the join to include `application_id`:

```sql
FROM credit_decisioning_sim.strategy_decisions sd
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = sd.strategy_set_name
   AND ar.strategy_name = sd.strategy_name
   AND ar.strategy_version = sd.strategy_version
   AND ar.module1_scenario_set_name = sd.module1_scenario_set_name
   AND ar.module1_scenario_name = sd.module1_scenario_name
   AND ar.population_id = sd.population_id

   /*
   Archive persistence comparison must be row-level.

   The archive replacement / rerun key intentionally excludes application_id because it
   identifies the full strategy × Module 1 scenario × population slice to replace.

   However, latest-run versus archive field comparison must include application_id,
   because the archive grain is one row per application within that replacement slice.

   Without application_id, a 50,000-row latest table joined to a 50,000-row archive slice
   creates 2.5 billion joined pairs and can run for hours.
   */
   AND ar.application_id = sd.application_id
WHERE
       ar.decision_outcome IS DISTINCT FROM sd.decision_outcome
    OR ar.decision_path IS DISTINCT FROM sd.decision_path
    OR ...
```

## Safer full replacement for the mismatch check

If you want to replace the full mismatch-count logic cleanly, use this pattern inside Section 12.6:

```sql
WITH latest_run AS (
    SELECT
        *
    FROM credit_decisioning_sim.strategy_decisions
),
archived_current_slice AS (
    SELECT
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN (
        SELECT DISTINCT
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        FROM credit_decisioning_sim.strategy_decisions
    ) k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = k.strategy_name
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id
),
persistence_mismatches AS (
    SELECT
        lr.application_id
    FROM latest_run lr
    JOIN archived_current_slice ar
        ON ar.strategy_set_name = lr.strategy_set_name
       AND ar.strategy_name = lr.strategy_name
       AND ar.strategy_version = lr.strategy_version
       AND ar.module1_scenario_set_name = lr.module1_scenario_set_name
       AND ar.module1_scenario_name = lr.module1_scenario_name
       AND ar.population_id = lr.population_id
       AND ar.application_id = lr.application_id
    WHERE
           ar.decision_outcome IS DISTINCT FROM lr.decision_outcome
        OR ar.decision_path IS DISTINCT FROM lr.decision_path
        OR ar.decision_priority_rank IS DISTINCT FROM lr.decision_priority_rank
        OR ar.decision_resolution_source IS DISTINCT FROM lr.decision_resolution_source
        OR ar.approval_flag IS DISTINCT FROM lr.approval_flag
        OR ar.counteroffer_flag IS DISTINCT FROM lr.counteroffer_flag
        OR ar.manual_review_flag IS DISTINCT FROM lr.manual_review_flag
        OR ar.decline_flag IS DISTINCT FROM lr.decline_flag
        OR ar.simulated_offer_exposure_flag IS DISTINCT FROM lr.simulated_offer_exposure_flag
        OR ar.approved_amount IS DISTINCT FROM lr.approved_amount
        OR ar.counteroffer_amount IS DISTINCT FROM lr.counteroffer_amount
        OR ar.exposure_reduction_flag IS DISTINCT FROM lr.exposure_reduction_flag
        OR ar.exposure_reduction_amount IS DISTINCT FROM lr.exposure_reduction_amount
        OR ar.exposure_reduction_pct IS DISTINCT FROM lr.exposure_reduction_pct
        OR ar.approved_monthly_payment_proxy IS DISTINCT FROM lr.approved_monthly_payment_proxy
        OR ar.approved_payment_to_income_ratio IS DISTINCT FROM lr.approved_payment_to_income_ratio
        OR ar.requested_expected_loss_amount IS DISTINCT FROM lr.requested_expected_loss_amount
        OR ar.approved_expected_loss_amount IS DISTINCT FROM lr.approved_expected_loss_amount
        OR ar.approved_el_reduction_amount IS DISTINCT FROM lr.approved_el_reduction_amount
        OR ar.approved_el_reduction_pct IS DISTINCT FROM lr.approved_el_reduction_pct
        OR ar.primary_reason_code IS DISTINCT FROM lr.primary_reason_code
        OR ar.secondary_reason_code IS DISTINCT FROM lr.secondary_reason_code
        OR ar.tertiary_reason_code IS DISTINCT FROM lr.tertiary_reason_code
        OR ar.primary_reason_family IS DISTINCT FROM lr.primary_reason_family
        OR ar.triggered_reason_code_list IS DISTINCT FROM lr.triggered_reason_code_list
        OR ar.reason_priority_rank IS DISTINCT FROM lr.reason_priority_rank
        OR ar.reason_code_count IS DISTINCT FROM lr.reason_code_count
        OR ar.strategy_set_name IS DISTINCT FROM lr.strategy_set_name
        OR ar.strategy_name IS DISTINCT FROM lr.strategy_name
        OR ar.strategy_version IS DISTINCT FROM lr.strategy_version
        OR ar.module1_scenario_set_name IS DISTINCT FROM lr.module1_scenario_set_name
        OR ar.module1_scenario_name IS DISTINCT FROM lr.module1_scenario_name
        OR ar.population_id IS DISTINCT FROM lr.population_id
        OR ar.application_id IS DISTINCT FROM lr.application_id
        OR ar.applicant_id IS DISTINCT FROM lr.applicant_id
        OR ar.product_type_policy_key IS DISTINCT FROM lr.product_type_policy_key
        OR ar.score_band_policy_key IS DISTINCT FROM lr.score_band_policy_key
)
SELECT
    COUNT(*) AS archive_persistence_mismatch_count
FROM persistence_mismatches;
```

Expected result after patch:

```text
archive_persistence_mismatch_count = 0
```

## Quick proof query

After cancellation, run this to confirm the row-explosion risk:

```sql
WITH counts AS (
    SELECT
        (SELECT COUNT(*) FROM credit_decisioning_sim.strategy_decisions) AS latest_rows,
        (
            SELECT COUNT(*)
            FROM credit_decisioning_sim.strategy_decisions_archive ar
            JOIN (
                SELECT DISTINCT
                    strategy_set_name,
                    strategy_name,
                    strategy_version,
                    module1_scenario_set_name,
                    module1_scenario_name,
                    population_id
                FROM credit_decisioning_sim.strategy_decisions
            ) k
                ON ar.strategy_set_name = k.strategy_set_name
               AND ar.strategy_name = k.strategy_name
               AND ar.strategy_version = k.strategy_version
               AND ar.module1_scenario_set_name = k.module1_scenario_set_name
               AND ar.module1_scenario_name = k.module1_scenario_name
               AND ar.population_id = k.population_id
        ) AS archived_slice_rows
)
SELECT
    latest_rows,
    archived_slice_rows,
    latest_rows::NUMERIC * archived_slice_rows::NUMERIC AS rows_if_joined_without_application_id
FROM counts;
```

Expected:

```text
latest_rows = 50,000
archived_slice_rows = 50,000
rows_if_joined_without_application_id = 2,500,000,000
```

## Bottom line

This is almost certainly not a data-volume issue and not a lock issue. It is likely a Section 12.6 archive validation join missing `application_id`.

Cancel the current run, patch the Section 12.6 latest-vs-archive mismatch join to include `application_id`, then rerun Section 12. The archive output itself is probably fine; the problem is the validation check comparing it inefficiently.
<!-- END_MESSAGE C038-M00453 -->


---

<a id="c038-m00455"></a>

### C038-M00455

**Andrew** · 2026-05-08T13:46:18.804000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00455 -->
this is the full 12.6 logic and it is preceded by: /***************************************************************************************************
SECTION 12.5 — ARCHIVE INVENTORY SNAPSHOT AFTER PERSISTENCE
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
<!-- END_MESSAGE C038-M00455 -->


**Attachments in export:** `Pasted text(105).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00458"></a>

### C038-M00458

**ChatGPT** · 2026-05-08T13:48:50.888465-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00458 -->
You are right to paste the full block. My earlier row-explosion diagnosis needs to be corrected.

In the Section 12.6 code you pasted, the persistence mismatch join **already includes `application_id`**:

```sql
AND ar.application_id = sd.application_id
```

So the long runtime is **not** caused by the missing-`application_id` join issue I suspected. The uploaded Section 12.6 logic confirms the row-level join predicate is present. fileciteturn4file0

The more likely issue is now **performance / indexing / stale statistics before the Section 12.6 gatekeeper**, especially because Section 12.6 runs several archive-wide or archive-slice checks before the Section 12 index creation layer has a chance to help.

## Most likely cause

Section 12.6 is doing several operations against:

```sql
credit_decisioning_sim.strategy_decisions_archive
```

including:

```sql
COUNT(DISTINCT application_id)
GROUP BY application_id
latest-run vs archive comparison
full archive duplicate-grain GROUP BY
```

Those should be fast for one 50,000-row archived slice. But if the archive table has more rows than expected, lacks the full archive-grain index, or PostgreSQL has stale stats, the planner can choose a very poor plan.

The heaviest candidate in your pasted block is probably the **full archive duplicate grain check** near the end:

```sql
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
        application_id
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

That checks the **entire archive**, not only the current archived slice. That is logically valid, but it can become expensive as the archive grows, especially before a unique archive-grain index exists.

## Immediate action

Cancel the running Section 12.6 session:

```sql
SELECT pg_cancel_backend(13664);
```

If it does not cancel cleanly:

```sql
SELECT pg_terminate_backend(13664);
```

Then run this quick size check:

```sql
SELECT
    c.relname,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_table_size
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'credit_decisioning_sim'
  AND c.relname IN ('strategy_decisions', 'strategy_decisions_archive');
```

## Targeted performance patch

This is not a business-logic patch. It is a **Section 12 execution-order / validation-performance patch**.

Add this immediately after Section 12.5 and before Section 12.6.

```sql
/***************************************************************************************************
SECTION 12.5A — ARCHIVE VALIDATION INDEX SUPPORT BEFORE FAIL-FAST CHECKS
****************************************************************************************************

Purpose:
    Section 12.6 performs archive persistence gatekeepers that compare the latest-run table
    to the current archived slice and validate archive grain integrity.

    These checks are validation checks, not strategy logic. They should not become a runtime
    bottleneck. The latest-run and archive tables therefore need practical indexes before
    Section 12.6 performs row-level comparison and archive grain review.

Boundary:
    This section does not recalculate decision_outcome.
    This section does not recalculate approved exposure.
    This section does not recalculate approved Expected Loss.
    This section does not reassign simulated reason codes.
    This section only supports efficient archive validation.

Why this exists:
    The archive replacement / rerun key identifies the strategy × Module 1 scenario × population
    slice. The row-level archive grain additionally includes application_id.

    Section 12.6 compares latest-run rows to archived rows at the row-level grain. Without a
    supporting index, PostgreSQL may choose a poor plan, especially as the archive grows across
    multiple strategy and scenario slices.

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
    The archive should not contain duplicate rows for the same application under the same
    Module 1 scenario and Module 2 strategy version.

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
```

## Optional Section 12.6 hardening patch

Because the unique index above enforces the full archive row-level grain, you can replace the expensive full-archive duplicate `GROUP BY` check with an index-existence / validity check.

### BEFORE

```sql
/*-------------------------------------------------------------------------------------------
Gatekeeper: archive row-level grain must be unique across the full archive.
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
        application_id
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
```

### AFTER

Add this variable to the `DECLARE` block:

```sql
v_archive_unique_grain_index_valid BOOLEAN;
```

Then replace the duplicate-grain block with:

```sql
/*-------------------------------------------------------------------------------------------
Gatekeeper: archive row-level grain uniqueness must be enforced.

The unique index created before Section 12.6 is the authoritative archive-grain control.
This avoids repeatedly scanning and grouping the full archive as the archive grows.

If duplicate archive grain existed, the unique index creation would have failed before
this gatekeeper. This check confirms that the uniqueness control exists and is valid.
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
```

## Why this is the right patch

This preserves all accepted logic.

It does **not** change:

```text
decision outcomes
approved amounts
approved Expected Loss
reason codes
archive replacement behavior
archive grain
archive replacement key
strategy metadata
Module 1 scenario metadata
```

It only changes the validation performance posture so the archive gatekeeper can scale.

## What to rerun

After applying the Section 12.5A patch:

1. Rerun Section 12.
2. Confirm Section 12.6 completes quickly.
3. Confirm the archive slice still shows:

```text
archived_rows = 50,000
distinct_application_id_count = 50,000
archive_inserted_ts populated
persistence mismatch count = 0
```

4. Continue to Section 13.

If the unique index creation fails, send the duplicate-key error. That would mean the archive really does contain duplicate row-level grain and needs cleanup before comparison.
<!-- END_MESSAGE C038-M00458 -->


---

<a id="c038-m00460"></a>

### C038-M00460

**Andrew** · 2026-05-08T13:55:10.180000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00460 -->
if i wanted to just re-run the full code top to bottom is that ok too?
<!-- END_MESSAGE C038-M00460 -->


---

<a id="c038-m00462"></a>

### C038-M00462

**ChatGPT** · 2026-05-08T13:56:28.548346-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00462 -->
Yes, rerunning the full Module 2 code top to bottom is okay, but **do not rerun it unchanged while the current Section 12.6 session is still active**.

The current long-running Section 12.6 block is a validation-performance issue, not a strategy-output issue. Your pasted Section 12.6 already includes the correct row-level archive comparison join on `application_id`, so the earlier suspected row-explosion join is not the issue. fileciteturn4file0

## Recommended path

First cancel the currently running backend:

```sql
SELECT pg_cancel_backend(13664);
```

If it does not cancel:

```sql
SELECT pg_terminate_backend(13664);
```

Then add the Section 12 validation index support before rerunning. The safest place is **between Section 12.5 and Section 12.6**.

At minimum, add:

```sql
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
```

Then rerun the full code top to bottom.

## What the full rerun will do

With:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

a full rerun should:

```text
rebuild the latest-run strategy_decisions table
recreate all temp staging tables
preserve the archive table
delete only the current strategy / Module 1 scenario / population archive slice
insert the refreshed 50,000-row latest-run output
```

That is okay.

For the same baseline strategy / same Module 1 `BASELINE_V2` slice, you should expect:

```text
Sections 3–11 business outputs unchanged
latest timestamps changed
archive_inserted_ts changed
Section 12 deleted rows = 50,000 if the slice already existed
Section 12 inserted rows = 50,000
current archived slice rows = 50,000
archive duplicate grain = 0
persistence mismatch count = 0
```

## One caution

Do **not** use full rerun if the active parameters are accidentally set to:

```text
strategy_archive_reset_mode = ALL
```

unless you intentionally want to clear the entire Module 2 archive.

For your current case, `STRATEGY_SCENARIO_ONLY` is the correct rerun mode.

## Bottom line

Yes: full top-to-bottom rerun is acceptable.

But the clean sequence is:

```text
1. Cancel/terminate the long-running Section 12.6 backend.
2. Add the Section 12.5A index-support patch before Section 12.6.
3. Confirm archive_run_flag = TRUE and reset mode = STRATEGY_SCENARIO_ONLY.
4. Rerun full Module 2 SQL.
5. Review Section 12 again.
```

This preserves all accepted strategy logic and should prevent Section 12.6 from becoming a runtime bottleneck.
<!-- END_MESSAGE C038-M00462 -->


---

<a id="c038-m00464"></a>

### C038-M00464

**Andrew** · 2026-05-08T14:05:42.814000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00464 -->
the full code ran in less than 5 minutes successfully!  I will prepare and send the section 13 QA next to review.
<!-- END_MESSAGE C038-M00464 -->


---

<a id="c038-m00465"></a>

### C038-M00465

**ChatGPT** · 2026-05-08T14:06:17.877227-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00465 -->
Great — that is strong confirmation.

The fact that the **full code ran successfully in under five minutes** means the Section 12 runtime issue is resolved for practical execution. Your pasted Section 12.6 block already included the row-level `application_id` join, so the long runtime was not a missing-grain join; it was more likely planner/index/statistics related around archive validation checks. The successful rerun confirms the current script is executable at the current archive scale.

For context, this is exactly the kind of staged, QA-integrated execution discipline Module 1 established: the SQL implementation is meant to be a governed artifact with archive persistence, validation gates, and comparison readiness rather than just an executable script. The Module 1 BRD’s SQL guidance emphasizes staged materialization, archive persistence, embedded QA, and implementation readability as part of the system design, not afterthoughts. fileciteturn4file2 Module 1’s Validation Summary also reinforces that scenario comparison should be matched, controlled, and supported by validation evidence, not inferred from a successful run alone. fileciteturn4file3

Send the Section 13 QA when ready. I’ll review it specifically for:

```text
archive inventory completeness
baseline/challenger slice counts
matched application_id count
readiness_status
same-strategy prevention
source-field consistency
portfolio-level deltas
decision migration matrix
product × score deltas
reason-code movement
simulated offer-exposure comparison
unmatched-row diagnostics
```

The key expected result, once the tighter synthetic-risk challenger is archived under the same Module 1 baseline slice, is:

```text
readiness_status = READY_FOR_MATCHED_COMPARISON
matched_application_id_count = 50,000
baseline_only_application_id_count = 0
challenger_only_application_id_count = 0
source_consistency_status = SOURCE_FIELDS_MATCH
```
<!-- END_MESSAGE C038-M00465 -->


---

<a id="c038-m00467"></a>

### C038-M00467

**Andrew** · 2026-05-08T14:24:58.005000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00467 -->
13.4 through 13.7 QA are blank.  here is the 13.0 through 13.3 QA to review. full section 13 code attached to help evaluate why 13.4 through 13.7 would be blank.
<!-- END_MESSAGE C038-M00467 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.1_QA_archive_inventory.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.1_QA_outcome_inventory_for_archived_strategy_slices.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.1_QA_archive_grain_diagnostic_expected_result_zero_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.2_QA_archive_inventory_and_matched_strategy_comparison_framework_selected_comparison_readiness.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.3_QA_portfolio_level_archived_strategy_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.0_QA_archive_inventory_and_matched_strategy_comparison_framework_parameter_setup.csv`, `Pasted text(106).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00471"></a>

### C038-M00471

**ChatGPT** · 2026-05-08T14:27:37.655636-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00471 -->
## Section 13.0–13.3 review

**Verdict: Section 13 archive inventory is healthy, but the comparison parameter selection is wrong for the intended baseline-vs-challenger run.**

This is why Sections **13.4 through 13.7 are blank**.

The archive itself looks good. The issue is not missing archived data. The issue is that `tmp_m2_strategy_comparison_params` is currently pointing to:

```text
baseline_strategy_name    = TIGHTER_SYNTHETIC_RISK_STRATEGY
challenger_strategy_name  = CHALLENGER_STRATEGY_PLACEHOLDER
```

So Section 13 is comparing:

```text
TIGHTER_SYNTHETIC_RISK_STRATEGY
vs
CHALLENGER_STRATEGY_PLACEHOLDER
```

and the placeholder strategy does not exist in the archive.

That is why readiness returns:

```text
NOT_READY_CHALLENGER_MISSING
```

and why the matched comparison sections are blank.

---

## What the QA shows

### 13.1 archive inventory — PASS

Your archive contains both required strategy slices:

| strategy_name | rows | distinct applications | approvals | counteroffers | manual reviews | declines |
|---|---:|---:|---:|---:|---:|---:|
| `BASELINE_STRATEGY` | 50,000 | 50,000 | 11,291 | 19,067 | 6,939 | 12,703 |
| `TIGHTER_SYNTHETIC_RISK_STRATEGY` | 50,000 | 50,000 | 10,649 | 18,452 | 6,017 | 14,882 |

This is exactly what we need for matched strategy comparison.

### 13.1 archive grain diagnostic — PASS

The duplicate archive grain diagnostic returned zero rows.

That means the archive grain is clean at:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

### 13.2 comparison readiness — NOT READY due to parameter selection

Current readiness result:

```text
readiness_status = NOT_READY_CHALLENGER_MISSING
baseline_archived_row_count = 50,000
challenger_archived_row_count = 0
matched_application_id_count = 0
baseline_only_application_id_count = 50,000
challenger_only_application_id_count = 0
```

This is not an archive failure. It means Section 13 did not select the archived challenger slice.

### 13.3 portfolio summary — misleading until parameters are corrected

Section 13.3 returned one row labeled:

```text
comparison_role = BASELINE
strategy_name   = TIGHTER_SYNTHETIC_RISK_STRATEGY
```

That is technically consistent with the current temporary comparison parameter table, but analytically it is not the intended baseline. It is labeling the tighter strategy as the comparison baseline because Section 13.0 defaulted the baseline from the current latest-run table.

The Section 13.0 code is designed to insert the current latest-run strategy as the baseline and a placeholder challenger unless the user updates the temp comparison parameters. Since your latest-run table is now the tighter strategy, the temp comparison table selected that as baseline and left the challenger as the placeholder. fileciteturn4file0

---

## Why 13.4 through 13.7 are blank

Those sections require both a baseline slice and a challenger slice.

Because the selected challenger is:

```text
CHALLENGER_STRATEGY_PLACEHOLDER
```

the challenger CTE is empty. Then:

- Section 13.4 joins baseline summary to challenger summary, so no challenger row means no output.
- Section 13.5 decision migration joins baseline rows to challenger rows, so no challenger rows means no matched rows.
- Section 13.6 matched applicant delta sample has no matched challenger rows.
- Section 13.7 product / score / product × score deltas have no matched challenger rows.

So the blank outputs are expected under the current Section 13.0 parameter setup.

---

## Correct comparison parameter setup

Run this **after Section 13.0 creates `tmp_m2_strategy_comparison_params` and before rerunning Sections 13.2 onward**.

```sql
UPDATE tmp_m2_strategy_comparison_params
SET
    comparison_set_name = 'BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',

    baseline_strategy_set_name = 'MODULE2_BASELINE_STRATEGY_SET',
    baseline_strategy_name = 'BASELINE_STRATEGY',
    baseline_strategy_version = 'V1_0',

    challenger_strategy_set_name = 'MODULE2_BASELINE_STRATEGY_SET',
    challenger_strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY',
    challenger_strategy_version = 'V1_0',

    module1_scenario_set_name = 'MODULE1_V2_BASELINE_SET',
    module1_scenario_name = 'BASELINE_V2',
    population_id = 'BASE_POPULATION_V1';
```

Then rerun:

```text
13.2 onward
```

You do not need to rerun Sections 0–12.

---

## Expected Section 13.2 result after the fix

You should expect:

```text
readiness_status = READY_FOR_MATCHED_COMPARISON
baseline_archived_row_count = 50,000
challenger_archived_row_count = 50,000
baseline_distinct_application_id_count = 50,000
challenger_distinct_application_id_count = 50,000
matched_application_id_count = 50,000
baseline_only_application_id_count = 0
challenger_only_application_id_count = 0
```

---

## Expected high-level comparison direction

Based on the archive inventory already shown, the tighter synthetic-risk strategy should produce these directional deltas versus baseline:

| Metric | Baseline | Tighter risk | Delta |
|---|---:|---:|---:|
| Approval count | 11,291 | 10,649 | -642 |
| Counteroffer count | 19,067 | 18,452 | -615 |
| Manual review count | 6,939 | 6,017 | -922 |
| Decline count | 12,703 | 14,882 | +2,179 |
| Simulated offer-exposure count | 30,358 | 29,101 | -1,257 |

That is directionally consistent with a tighter synthetic estimated-risk proxy strategy.

---

## Recommended small Section 13.0 improvement for later

This is not required immediately, but later I recommend changing Section 13.0 so the default comparison parameters are explicit rather than using the current latest-run strategy as the baseline.

Current behavior is safe but easy to misread:

```text
baseline = whatever strategy_decisions currently contains
challenger = placeholder
```

For production-quality usability, Section 13.0 should either:

1. insert no default row and require the user to set parameters, or  
2. insert a clearly documented baseline-vs-tighter default if those slices exist.

For now, the smallest fix is just the `UPDATE` statement above.

## Bottom line

Section 13 archive data is good. The comparison is blank because the comparison parameter table selected the wrong baseline and a nonexistent challenger placeholder.

Apply the parameter update, rerun Section 13.2–13.7, and the matched comparison outputs should populate.
<!-- END_MESSAGE C038-M00471 -->


---

<a id="c038-m00472"></a>

### C038-M00472

**Andrew** · 2026-05-08T15:14:32.263000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00472 -->
I'd rather a more permanent section 13 solution.  Please advise on the permanent section 13 solution to fix this issue forever
<!-- END_MESSAGE C038-M00472 -->


---

<a id="c038-m00477"></a>

### C038-M00477

**ChatGPT** · 2026-05-08T15:18:02.679498-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00477 -->
Yes. The permanent fix is to **stop Section 13.0 from inferring comparison parameters from the latest-run table**.

That inference is the root cause. Your current Section 13.0 creates `tmp_m2_strategy_comparison_params`, then inserts the **current latest-run strategy** as the baseline and uses `CHALLENGER_STRATEGY_PLACEHOLDER` as the challenger. That worked poorly once your latest-run table became `TIGHTER_SYNTHETIC_RISK_STRATEGY`, because Section 13 then treated the tighter strategy as the baseline and compared it to a nonexistent placeholder. fileciteturn6file0

## Permanent Section 13 design recommendation

Replace Section 13.0 with a **governed comparison registry + active selector**.

The permanent structure should be:

```text
tmp_m2_strategy_comparison_registry
    = contains one or more named comparison setups

tmp_m2_strategy_comparison_params
    = contains exactly one selected active comparison
```

Then Sections 13.1–13.11 can continue reading from:

```sql
tmp_m2_strategy_comparison_params
```

No downstream Section 13 logic needs to change.

## Why this fixes the issue permanently

This prevents Section 13 from depending on whatever strategy happened to be materialized last in:

```sql
credit_decisioning_sim.strategy_decisions
```

That latest-run table changes every time you run a new strategy. It should not determine the baseline/challenger comparison.

The corrected Section 13.0 should require explicit comparison identity:

```text
baseline_strategy_name
challenger_strategy_name
module1_scenario_name
population_id
```

That makes Section 13 deterministic, reviewable, and safe for future strategy libraries.

---

# Recommended permanent Section 13.0 patch

Replace the current Section 13.0 comparison parameter setup with this structure.

```sql
/***************************************************************************************************
SECTION 13.0 — GOVERNED COMPARISON PARAMETER SETUP
****************************************************************************************************

PURPOSE:
    Define the selected baseline and challenger archived strategy slices for read-only matched
    comparison.

PERMANENT DESIGN CHANGE:
    Section 13 no longer infers the baseline strategy from credit_decisioning_sim.strategy_decisions.

    The latest-run table changes whenever a new strategy is executed. Using it as the default
    comparison baseline can silently select the wrong strategy after a challenger run.

    Instead, Section 13 uses a governed temporary comparison registry. Users explicitly select
    one active comparison, and downstream Section 13 queries read from the canonical
    tmp_m2_strategy_comparison_params table.

BUSINESS INTERPRETATION:
    A Module 2 strategy comparison should answer:

        "How did the challenger Module 2 strategy change outcomes relative to the baseline
         Module 2 strategy when both were applied to the same Module 1 scenario and population?"

V1.0 MATCHED COMPARISON BOUNDARY:
    Baseline and challenger strategy slices must share:

        module1_scenario_set_name
        module1_scenario_name
        population_id

    This isolates downstream Module 2 strategy effects.

WHY LATEST-RUN INFERENCE IS NOT USED:
    credit_decisioning_sim.strategy_decisions is the current latest-run output.
    It is intentionally replaceable.

    It is appropriate for latest-run QA.
    It is not appropriate as an implicit comparison selector.

WHY A REGISTRY IS USED:
    The registry allows multiple planned comparisons to be listed while selecting exactly one
    active comparison for the current Section 13 review.

READ-ONLY BOUNDARY:
    This section creates temporary helper tables only.
    It does not insert, delete, update, or modify archive rows.
    It does not recalculate decisions, approved exposure, approved Expected Loss, or simulated
    reason codes.

***************************************************************************************************/


DROP TABLE IF EXISTS tmp_m2_strategy_comparison_registry;

CREATE TEMP TABLE tmp_m2_strategy_comparison_registry (
    active_comparison_flag              BOOLEAN NOT NULL,
    comparison_set_name                 TEXT NOT NULL,
    comparison_description              TEXT,

    baseline_strategy_set_name          TEXT NOT NULL,
    baseline_strategy_name              TEXT NOT NULL,
    baseline_strategy_version           TEXT NOT NULL,

    challenger_strategy_set_name        TEXT NOT NULL,
    challenger_strategy_name            TEXT NOT NULL,
    challenger_strategy_version         TEXT NOT NULL,

    module1_scenario_set_name           TEXT NOT NULL,
    module1_scenario_name               TEXT NOT NULL,
    population_id                       TEXT NOT NULL
) ON COMMIT PRESERVE ROWS;


/*
Primary active comparison for the current Module 2 validation workflow.

Users should update this registry row when changing the comparison being reviewed.

Do not use CHALLENGER_STRATEGY_PLACEHOLDER.
Do not infer baseline or challenger from the latest-run table.
*/
INSERT INTO tmp_m2_strategy_comparison_registry (
    active_comparison_flag,
    comparison_set_name,
    comparison_description,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id
)
VALUES (
    TRUE,
    'BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
    'Compares Module 2 baseline strategy against tighter synthetic-risk strategy on the same Module 1 BASELINE_V2 archived population.',

    'MODULE2_BASELINE_STRATEGY_SET',
    'BASELINE_STRATEGY',
    'V1_0',

    'MODULE2_BASELINE_STRATEGY_SET',
    'TIGHTER_SYNTHETIC_RISK_STRATEGY',
    'V1_0',

    'MODULE1_V2_BASELINE_SET',
    'BASELINE_V2',
    'BASE_POPULATION_V1'
);


/*
Optional future comparisons can be added here with active_comparison_flag = FALSE.

Only one comparison should be active at a time. The selected active row is copied into
tmp_m2_strategy_comparison_params, which is the canonical table used by Sections 13.2+.
*/


/***************************************************************************************************
SECTION 13.0A — COMPARISON PARAMETER GATEKEEPER
****************************************************************************************************

PURPOSE:
    Validate that exactly one active comparison has been selected and that the selected comparison
    is meaningful before downstream Section 13 matched-comparison queries run.

WHY THIS GATEKEEPER EXISTS:
    Section 13 comparison outputs can appear blank if the challenger strategy slice does not exist
    or if placeholder comparison parameters are used.

    This gatekeeper prevents accidental placeholder comparison setup and protects reviewers from
    interpreting blank output as a strategy result.

BOUNDARY:
    This gatekeeper validates comparison selection only.
    It does not modify archive rows.
    It does not recalculate any strategy output.

***************************************************************************************************/

DO $$
DECLARE
    v_active_comparison_count BIGINT;
    v_placeholder_count BIGINT;
    v_same_strategy_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_active_comparison_count
    FROM tmp_m2_strategy_comparison_registry
    WHERE active_comparison_flag IS TRUE;

    IF v_active_comparison_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 13.0 failure: expected exactly one active strategy comparison, found %.',
            v_active_comparison_count;
    END IF;


    SELECT COUNT(*)
    INTO v_placeholder_count
    FROM tmp_m2_strategy_comparison_registry
    WHERE active_comparison_flag IS TRUE
      AND (
             baseline_strategy_name ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_name ILIKE '%PLACEHOLDER%'
          OR baseline_strategy_set_name ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_set_name ILIKE '%PLACEHOLDER%'
          OR comparison_set_name ILIKE '%PLACEHOLDER%'
      );

    IF v_placeholder_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 13.0 failure: active comparison contains placeholder strategy identifiers. Update tmp_m2_strategy_comparison_registry before running matched comparison.';
    END IF;


    SELECT COUNT(*)
    INTO v_same_strategy_count
    FROM tmp_m2_strategy_comparison_registry
    WHERE active_comparison_flag IS TRUE
      AND baseline_strategy_set_name = challenger_strategy_set_name
      AND baseline_strategy_name = challenger_strategy_name
      AND baseline_strategy_version = challenger_strategy_version;

    IF v_same_strategy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 13.0 failure: active comparison selects the same strategy as both baseline and challenger.';
    END IF;
END $$;


/***************************************************************************************************
SECTION 13.0B — CANONICAL ACTIVE COMPARISON PARAMETER TABLE
****************************************************************************************************

PURPOSE:
    Materialize the single active comparison into the canonical parameter table used by all
    downstream Section 13 queries.

WHY THIS TABLE IS PRESERVED:
    Sections 13.2 through 13.11 already reference tmp_m2_strategy_comparison_params.

    By loading the active registry row into this canonical table, the permanent Section 13 fix
    avoids rewriting downstream comparison queries.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;

CREATE TEMP TABLE tmp_m2_strategy_comparison_params (
    comparison_set_name                   TEXT,

    baseline_strategy_set_name            TEXT,
    baseline_strategy_name                TEXT,
    baseline_strategy_version             TEXT,

    challenger_strategy_set_name          TEXT,
    challenger_strategy_name              TEXT,
    challenger_strategy_version           TEXT,

    module1_scenario_set_name             TEXT,
    module1_scenario_name                 TEXT,
    population_id                         TEXT
) ON COMMIT PRESERVE ROWS;


INSERT INTO tmp_m2_strategy_comparison_params (
    comparison_set_name,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id
)
SELECT
    comparison_set_name,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id
FROM tmp_m2_strategy_comparison_registry
WHERE active_comparison_flag IS TRUE;


/*
Diagnostic display of the selected active comparison.

This is the comparison that Sections 13.2 through 13.11 will use.
*/
SELECT
    comparison_set_name,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id
FROM tmp_m2_strategy_comparison_params;
```

---

## What this fixes

This permanently fixes the problem where Section 13 accidentally compares:

```text
latest-run strategy
vs
CHALLENGER_STRATEGY_PLACEHOLDER
```

Instead, Section 13 will now compare the explicitly selected active comparison:

```text
BASELINE_STRATEGY
vs
TIGHTER_SYNTHETIC_RISK_STRATEGY
```

on:

```text
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
```

## What should happen after this patch

After rerunning Section 13 with this Section 13.0 replacement, Section 13.2 should show:

```text
readiness_status = READY_FOR_MATCHED_COMPARISON
baseline_archived_row_count = 50,000
challenger_archived_row_count = 50,000
matched_application_id_count = 50,000
baseline_only_application_id_count = 0
challenger_only_application_id_count = 0
```

Then Sections 13.4 through 13.7 should populate normally.

## Recommended adoption

I recommend treating this as a **required Section 13 hardening patch** before further matched strategy comparison.

It does not change:

```text
decision logic
approved exposure logic
approved Expected Loss logic
reason-code logic
archive persistence logic
latest-run output
archive rows
```

It only fixes the comparison-selection framework so Section 13 is stable, explicit, and reusable as your strategy library grows.
<!-- END_MESSAGE C038-M00477 -->


---

<a id="c038-m00478"></a>

### C038-M00478

**Andrew** · 2026-05-08T15:38:55.408000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00478 -->
review section 13 QA: 
<!-- END_MESSAGE C038-M00478 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.4_QA_baseline_vs_challenger_portfolio_level_delta_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.5_QA_archive_inventory_and_matched_strategy_comparison_framework_decision_migration_matrix.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.6_QA_archive_inventory_and_matched_strategy_comparison_framework_matched_applicant_level_delta_sample.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.7A_QA_archive_inventory_and_matched_strategy_comparison_framework_product_level_matched_strategy_delta_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.7B_QA_archive_inventory_and_matched_strategy_comparison_framework_score_band_level_matched_strategy_delta_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.7C_QA_archive_inventory_and_matched_strategy_comparison_framework_product_x_score_band_matched_strategy_delta_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.8A_QA_archive_inventory_and_matched_strategy_comparison_framework_primary_reason_distribution_by_selected_strategy.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.8B_QA_archive_inventory_and_matched_strategy_comparison_framework_matched_reason_code_migration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.9_QA_archive_inventory_and_matched_strategy_comparison_framework_simulated_offer_exposure_comparison.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.10_QA_archive_inventory_and_matched_strategy_comparison_framework_unmatched_row_diagnostic_expected_result_zero_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.11_QA_archive_inventory_and_matched_strategy_comparison_framework_matched_module_1_source_field_consistency_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.0_QA_archive_inventory_and_matched_strategy_comparison_framework_parameter_setup(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.1_QA_archive_inventory(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.1_QA_outcome_inventory_for_archived_strategy_slices(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.1_QA_archive_grain_diagnostic_expected_result_zero_rows(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.2_QA_archive_inventory_and_matched_strategy_comparison_framework_selected_comparison_readiness(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_13.3_QA_portfolio_level_archived_strategy_summary(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00489"></a>

### C038-M00489

**ChatGPT** · 2026-05-08T15:43:44.999069-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00489 -->
## Section 13 QA review — Archive Inventory and Matched Strategy Comparison Framework

**Verdict: PASS, with one code-control note.**

The Section 13 QA now behaves correctly. The comparison parameter issue is resolved for this run, both archived strategy slices are present, the matched comparison is ready, source fields match exactly, and Sections 13.4–13.11 now produce meaningful baseline-versus-challenger outputs.

This confirms that Section 13 is successfully comparing:

```text
Baseline:
MODULE2_BASELINE_STRATEGY_SET / BASELINE_STRATEGY / V1_0

Challenger:
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0

Module 1 source:
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
```

That is the correct comparison design: same Module 1 scenario and population, different Module 2 strategy.

---

# 1. Section 13.0 — Comparison parameter setup

**Assessment: PASS.**

The comparison parameter row is now correct:

| Field | Value |
|---|---|
| `comparison_set_name` | `BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK` |
| Baseline strategy | `BASELINE_STRATEGY / V1_0` |
| Challenger strategy | `TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0` |
| Module 1 scenario | `MODULE1_V2_BASELINE_SET / BASELINE_V2` |
| Population | `BASE_POPULATION_V1` |

This fixes the earlier problem where the comparison selected a placeholder challenger and caused Sections 13.4–13.7 to return blank outputs.

**Code-control note:** the attached Section 13 code excerpt still appears to show the earlier placeholder-based default behavior, where baseline is inferred from `strategy_decisions` and challenger is set to `CHALLENGER_STRATEGY_PLACEHOLDER`. If that is still in the canonical SQL, the permanent Section 13.0 registry patch should be integrated before final code recapture. The current QA proves the comparison parameters were corrected for this run, but the final script should not rely on a manual update after Section 13.0. fileciteturn6file0

---

# 2. Section 13.1 — Archive inventory

**Assessment: PASS.**

The archive contains both required strategy slices:

| Strategy | Rows | Distinct applications | Approve | Counteroffer | Manual review | Decline |
|---|---:|---:|---:|---:|---:|---:|
| `BASELINE_STRATEGY` | 50,000 | 50,000 | 11,291 | 19,067 | 6,939 | 12,703 |
| `TIGHTER_SYNTHETIC_RISK_STRATEGY` | 50,000 | 50,000 | 10,649 | 18,452 | 6,017 | 14,882 |

The archive grain diagnostic returns zero rows, so there are no duplicate archive rows at:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

This confirms archive readiness for matched strategy comparison.

---

# 3. Section 13.2 — Selected comparison readiness

**Assessment: PASS.**

Readiness status is:

```text
READY_FOR_MATCHED_COMPARISON
```

Key readiness values:

| Check | Observed | Assessment |
|---|---:|---|
| Baseline archived rows | 50,000 | PASS |
| Challenger archived rows | 50,000 | PASS |
| Baseline distinct applications | 50,000 | PASS |
| Challenger distinct applications | 50,000 | PASS |
| Matched `application_id` count | 50,000 | PASS |
| Baseline-only applications | 0 | PASS |
| Challenger-only applications | 0 | PASS |
| Duplicate application rows | 0 both sides | PASS |
| Same strategy selected | `FALSE` | PASS |

This is the core Section 13 acceptance result.

The matched comparison is valid because the baseline and challenger are applied to the same Module 1 archived scenario and the same `population_id`. This preserves the interpretation that deltas are downstream Module 2 strategy effects, not upstream Module 1 scenario drift.

---

# 4. Section 13.3 — Portfolio-level archived strategy summary

**Assessment: PASS.**

The portfolio summary shows the tighter synthetic-risk strategy behaving directionally as expected.

| Metric | Baseline | Tighter synthetic-risk | Delta |
|---|---:|---:|---:|
| Applications | 50,000 | 50,000 | 0 |
| Approval rate | 22.58% | 21.30% | -1.28 pts |
| Counteroffer rate | 38.13% | 36.90% | -1.23 pts |
| Manual review rate | 13.88% | 12.03% | -1.84 pts |
| Decline rate | 25.41% | 29.76% | +4.36 pts |
| Simulated offer-exposure rate | 60.72% | 58.20% | -2.51 pts |
| Total approved amount | $3.880B | $3.728B | -$151.3M |
| Total approved Expected Loss | $58.93M | $51.67M | -$7.26M |
| Avg synthetic estimated-PD proxy among offer rows | 0.0642 | 0.0564 | -0.0079 |
| Avg approved PTI among offer rows | 0.1221 | 0.1197 | -0.0024 |

This is a strong result. The tighter synthetic-risk strategy reduces offer exposure, total approved amount, and approved Expected Loss. The tradeoff is a higher decline rate.

Requested amount and requested Expected Loss are unchanged across strategies, which is exactly what we want in a matched Module 2 strategy comparison. The same Module 1 inputs were used; only the downstream strategy changed.

---

# 5. Section 13.4 — Baseline vs challenger portfolio delta summary

**Assessment: PASS.**

Section 13.4 confirms the same portfolio-level tradeoff in explicit `baseline_*`, `challenger_*`, and `delta_*` form.

Important deltas:

```text
delta_approval_rate                    = -0.01284
delta_counteroffer_rate                = -0.01230
delta_manual_review_rate               = -0.01844
delta_decline_rate                     = +0.04358
delta_simulated_offer_exposure_rate    = -0.02514
delta_total_approved_amount            = -151,306,405.84
delta_total_approved_expected_loss     = -7,257,884.13
delta_avg_approved_expected_loss_all_apps = -145.16
delta_avg_synthetic_estimated_pd_proxy_offer_rows = -0.00785
```

This is exactly the strategic story expected from a tighter synthetic estimated-risk proxy strategy:

```text
less offer exposure
lower approved Expected Loss
lower offered-population risk proxy
more final declines
```

No issue indicated.

---

# 6. Section 13.5 — Decision migration matrix

**Assessment: PASS.**

The decision migration matrix is populated and interpretable.

Total stability / migration:

| Migration type | Rows | Share |
|---|---:|---:|
| Stable final outcome | 45,469 | 90.94% |
| Migrated final outcome | 4,531 | 9.06% |

Decision migration detail:

| Baseline outcome | Challenger outcome | Rows | Interpretation |
|---|---|---:|---|
| `APPROVE` | `APPROVE` | 10,649 | Stable approvals |
| `APPROVE` | `COUNTEROFFER` | 581 | Tightening converts clean approvals to constrained offers |
| `APPROVE` | `MANUAL_REVIEW` | 61 | Tightening moves a small approval population into unresolved review |
| `COUNTEROFFER` | `COUNTEROFFER` | 17,324 | Stable counteroffers |
| `COUNTEROFFER` | `MANUAL_REVIEW` | 1,163 | Counteroffers become unresolved under tighter risk |
| `COUNTEROFFER` | `DECLINE` | 580 | Counteroffers become no-offer paths |
| `MANUAL_REVIEW` | `COUNTEROFFER` | 547 | Previously unresolved rows become reduced-offer feasible |
| `MANUAL_REVIEW` | `MANUAL_REVIEW` | 4,793 | Stable manual review |
| `MANUAL_REVIEW` | `DECLINE` | 1,599 | Review rows become no-offer paths |
| `DECLINE` | `DECLINE` | 12,703 | Stable declines |

This is one of the most valuable Section 13 outputs.

The largest strategic movement is toward more declines, especially from manual review and counteroffer populations. That is directionally consistent with tighter synthetic-risk thresholds.

The `MANUAL_REVIEW → COUNTEROFFER` movement is not automatically a defect. It reflects the fact that threshold changes can alter routing and feasibility paths, not merely tighten outcomes monotonically at the aggregate level. The key validation point is that source fields match, archive rows match, and the movement is explainable in reason-code migration.

---

# 7. Section 13.6 — Matched applicant-level delta sample

**Assessment: PASS.**

The top 50 row-level movements are concentrated in:

```text
MORTGAGE / SUBPRIME
baseline COUNTEROFFER → challenger DECLINE
```

The dominant reason-code movement is:

```text
COUNTEROFFER_EXPECTED_LOSS_LIMIT
or
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

moving to

POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY
```

The top 50 rows show large approved-exposure and approved Expected Loss reductions:

| Metric | Typical observed pattern |
|---|---:|
| Baseline approved amount | about $145K–$165K |
| Challenger approved amount | $0 |
| Delta approved amount | about -$145K to -$165K |
| Baseline approved Expected Loss | about $9.94K–$10.00K |
| Challenger approved Expected Loss | $0 |
| Delta approved Expected Loss | about -$9.94K to -$10.00K |

This is a strong diagnostic result. The largest row-level deltas are exactly where a tighter synthetic-risk strategy should have the most visible impact: high-risk, high-exposure, previously feasible counteroffer rows becoming no-offer paths.

---

# 8. Section 13.7 — Product / score / product × score deltas

## 13.7A — Product-level deltas

**Assessment: PASS.**

Every product shows increased decline rate under the tighter strategy.

| Product | Delta approval rate | Delta counteroffer rate | Delta manual review rate | Delta decline rate | Delta offer-exposure rate |
|---|---:|---:|---:|---:|---:|
| `AUTO_LOAN` | -2.07 pts | +0.82 pts | -2.87 pts | +4.11 pts | -1.25 pts |
| `HELOC` | -1.51 pts | -1.83 pts | -0.81 pts | +4.15 pts | -3.35 pts |
| `MORTGAGE` | -0.74 pts | -3.97 pts | +0.09 pts | +4.61 pts | -4.71 pts |
| `REVOLVING_LINE` | -1.28 pts | +0.07 pts | -3.23 pts | +4.43 pts | -1.20 pts |
| `UNSECURED_PERSONAL_LOAN` | -1.20 pts | -0.22 pts | -2.76 pts | +4.19 pts | -1.43 pts |

Mortgage has the largest offer-exposure reduction and the largest average approved amount reduction:

```text
Mortgage delta offer-exposure rate = -4.71 pts
Mortgage delta avg approved amount all apps = -$8,338.51
Mortgage delta avg approved Expected Loss all apps = -$348.50
```

That is intuitive because mortgage has large exposure and approved Expected Loss is sensitive to exposure treatment.

## 13.7B — Score-band deltas

**Assessment: PASS.**

Score-band movement is highly interpretable.

| Score band | Delta approval rate | Delta counteroffer rate | Delta manual review rate | Delta decline rate | Delta offer-exposure rate |
|---|---:|---:|---:|---:|---:|
| `SUPER_PRIME` | 0.00 pts | 0.00 pts | 0.00 pts | 0.00 pts | 0.00 pts |
| `PRIME` | -0.59 pts | +1.05 pts | -0.46 pts | 0.00 pts | +0.46 pts |
| `NEAR_PRIME` | -4.63 pts | -1.51 pts | +6.02 pts | +0.12 pts | -6.14 pts |
| `SUBPRIME` | 0.00 pts | -6.50 pts | -17.63 pts | +24.13 pts | -6.50 pts |
| `DEEP_SUBPRIME` | 0.00 pts | -0.02 pts | -0.26 pts | +0.28 pts | -0.02 pts |

This is very strong.

Interpretation:

- `SUPER_PRIME` is unaffected by the tighter synthetic-risk strategy.
- `PRIME` sees only minor movement, mostly approvals becoming counteroffers or review moving to offer.
- `NEAR_PRIME` becomes the main threshold-sensitive middle-risk zone.
- `SUBPRIME` sees the largest tightening effect, with a +24.13 percentage-point decline-rate increase.
- `DEEP_SUBPRIME` was already almost entirely declined under baseline, so the challenger has little room to move it further.

This is exactly the kind of segment-level behavior that makes the strategy comparison marketable.

## 13.7C — Product × score deltas

**Assessment: PASS.**

The product × score matrix shows where tightening concentrates.

Most important movements:

| Segment | Key movement |
|---|---|
| `MORTGAGE / SUBPRIME` | Decline rate +25.96 pts; offer-exposure rate -10.31 pts |
| `REVOLVING_LINE / SUBPRIME` | Decline rate +24.64 pts; manual review -20.54 pts |
| `AUTO_LOAN / SUBPRIME` | Decline rate +22.85 pts |
| `HELOC / SUBPRIME` | Decline rate +22.26 pts |
| `UNSECURED_PERSONAL_LOAN / SUBPRIME` | Decline rate +22.66 pts |
| `MORTGAGE / NEAR_PRIME` | Offer-exposure rate -13.50 pts; manual review +13.25 pts |
| `HELOC / NEAR_PRIME` | Offer-exposure rate -8.42 pts; manual review +8.08 pts |
| `AUTO_LOAN / NEAR_PRIME` | Approval rate -8.45 pts; counteroffer +7.24 pts |

This is excellent segment evidence. It shows that the challenger strategy does not affect all segments equally. It concentrates in the middle and weak-score bands, especially where product exposure is material.

---

# 9. Section 13.8 — Reason-code movement

## 13.8A — Primary reason distribution by selected strategy

**Assessment: PASS.**

The reason-code distribution changes in the expected direction.

Most important changes:

| Reason code | Baseline | Challenger | Direction |
|---|---:|---:|---|
| `APPROVED_AS_REQUESTED` | 11,291 | 10,649 | Down |
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 8,905 | 8,905 | Stable |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 5,021 | 4,713 | Down |
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 1,288 | 770 | Down |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 3,853 | 4,064 | Up |
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 2,961 | 2,788 | Down |
| `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 2,130 | 1,144 | Down |
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 6,369 | 8,623 | Up materially |

This is exactly what a tighter synthetic-risk strategy should show: more final no-offer outcomes explained by high synthetic estimated-PD proxy, fewer approvals, fewer feasible counteroffers, and lower approved Expected Loss.

## 13.8B — Matched reason-code migration

**Assessment: PASS.**

Reason-code migration summary:

| Reason migration type | Rows | Share |
|---|---:|---:|
| Stable reason code | 45,214 | 90.43% |
| Moved across reason family | 4,531 | 9.06% |
| Moved within reason family | 255 | 0.51% |

This reconciles perfectly with the decision migration matrix:

```text
4,531 migrated outcomes = 4,531 moved across reason family
```

That is a clean result. When final outcomes changed, primary reason families changed accordingly.

Important movement examples:

- `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER → POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`: 986 rows
- `APPROVED_AS_REQUESTED → COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT`: 576 rows
- `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT → MANUAL_REVIEW_ELEVATED_SYNTHETIC_RISK`: 530 rows
- `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK → COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT`: 483 rows
- `COUNTEROFFER_EXPECTED_LOSS_LIMIT → POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`: 448 rows

This is highly explainable and strong for portfolio storytelling.

---

# 10. Section 13.9 — Simulated offer-exposure comparison

**Assessment: PASS.**

The tighter strategy reduces simulated offer exposure and improves offered-population risk quality.

| Metric | Baseline | Challenger | Direction |
|---|---:|---:|---|
| Offer count | 30,358 | 29,101 | Down 1,257 |
| Positive offer rate | 60.72% | 58.20% | Down 2.51 pts |
| Approval share of offers | 37.19% | 36.59% | Slightly down |
| Counteroffer share of offers | 62.81% | 63.41% | Slightly up |
| Total approved amount | $3.880B | $3.728B | Down $151.3M |
| Avg approved amount offer rows | $127,792 | $128,113 | Slightly up |
| Avg synthetic estimated-PD proxy offer rows | 0.0642 | 0.0564 | Down |
| Avg approved PTI offer rows | 0.1221 | 0.1197 | Down |
| Total approved Expected Loss | $58.93M | $51.67M | Down $7.26M |
| Avg approved Expected Loss offer rows | $1,941 | $1,776 | Down |

The slight increase in average approved amount among offer rows is not a defect. The tighter strategy removed or moved some riskier/lower-quality offered rows, while the remaining offer population has lower synthetic estimated-PD proxy and lower approved Expected Loss. The total approved amount falls materially, which is the more important portfolio-level exposure result.

This is a very strong “strategy frontier” signal.

---

# 11. Section 13.10 — Unmatched row diagnostic

**Assessment: PASS.**

The unmatched row diagnostic returns zero rows.

That confirms:

```text
baseline-only application_id count = 0
challenger-only application_id count = 0
```

No row-matching issue exists.

---

# 12. Section 13.11 — Matched Module 1 source-field consistency diagnostic

**Assessment: PASS.**

This is one of the most important Section 13 outputs.

Observed:

| Check | Count |
|---|---:|
| Matched applications | 50,000 |
| Source field mismatches | 0 |
| Product type mismatches | 0 |
| Score band mismatches | 0 |
| Credit score mismatches | 0 |
| Annual income mismatches | 0 |
| Requested amount mismatches | 0 |
| Requested payment mismatches | 0 |
| Requested PTI mismatches | 0 |
| Amount-to-income mismatches | 0 |
| Synthetic estimated-PD proxy mismatches | 0 |
| LGD mismatches | 0 |
| Requested Expected Loss mismatches | 0 |
| Module 1 lineage mismatches | 0 |
| Source consistency status | `SOURCE_FIELDS_MATCH` |

This proves the comparison isolated Module 2 strategy effects. The baseline and challenger rows use the same Module 1 application profile, requested structure, affordability, synthetic estimated-PD proxy, LGD, requested Expected Loss, and scenario lineage.

That is the exact evidence needed to support a clean matched strategy comparison.

---

# Section 13 acceptance conclusion

Section 13 passes.

Accepted evidence:

- Archive inventory contains both baseline and tighter synthetic-risk strategy slices.
- Both slices contain 50,000 rows and 50,000 distinct `application_id` values.
- Archive grain duplicate diagnostic returns zero rows.
- Comparison parameters correctly select baseline vs tighter synthetic-risk strategy.
- Readiness status is `READY_FOR_MATCHED_COMPARISON`.
- Matched application count is 50,000.
- No unmatched baseline-only or challenger-only rows exist.
- Portfolio-level deltas are populated and interpretable.
- Decision migration matrix is populated and uses the matched-population denominator.
- 90.94% of rows are stable and 9.06% migrate under the tighter strategy.
- Tighter strategy reduces approvals, counteroffers, manual reviews, simulated offer exposure, total approved amount, and total approved Expected Loss.
- Tighter strategy increases final declines by 2,179 rows.
- Segment deltas concentrate primarily in Near Prime and Subprime, especially product × score segments with meaningful exposure.
- Reason-code movement is aligned to outcome movement.
- Simulated offer-exposure comparison shows lower offered-population synthetic estimated-PD proxy and lower approved Expected Loss.
- Matched Module 1 source-field consistency is perfect.
- Section 13 remains read-only.
- No decision outcomes, approved exposure values, approved Expected Loss values, or simulated reason codes are recalculated by Section 13.

## Patch recommendation

No Section 13 comparison-logic patch is recommended.

One required **code-control confirmation** remains:

```text
Confirm the permanent Section 13.0 comparison registry patch is embedded in the canonical SQL,
not just applied manually through a temporary parameter update.
```

If the canonical code still contains the old placeholder-based Section 13.0 behavior, patch it before final code recapture.

## Strategic interpretation

The tighter synthetic-risk strategy produced an excellent first challenger comparison.

The story is clear:

```text
Tighter synthetic estimated-risk proxy thresholds reduced simulated offer exposure by 2.51 percentage points,
reduced total approved amount by $151.3M,
reduced approved Expected Loss by $7.26M,
and increased final declines by 4.36 percentage points.
```

That is a clean senior-credit-strategy narrative:

```text
risk discipline reduced approved exposure and approved Expected Loss, with a measurable access / decline-rate tradeoff.
```

This is exactly the kind of result that can later feed the strategy frontier summary.
<!-- END_MESSAGE C038-M00489 -->


---

<a id="c038-m00491"></a>

### C038-M00491

**Andrew** · 2026-05-08T15:49:02.731000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00491 -->
ok, let's talk appropriate next step.  I think building the strategy frontier summary would be a potential next step.  thoughts?
<!-- END_MESSAGE C038-M00491 -->


---

<a id="c038-m00493"></a>

### C038-M00493

**ChatGPT** · 2026-05-08T15:50:42.318406-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00493 -->
Yes — **building the strategy frontier summary is the right next step**, but I would do it in a controlled order.

My recommendation:

```text
1. First: permanently patch Section 13.0 comparison selection.
2. Then: add a new Section 15 — Strategy Frontier Summary.
```

The reason is simple: Section 13 is currently validated functionally, but your attached code still shows the older placeholder/default comparison setup that infers baseline from `strategy_decisions` and sets `CHALLENGER_STRATEGY_PLACEHOLDER`. That behavior caused the earlier blank 13.4–13.7 outputs, so it should be fixed in the canonical SQL before we add new comparison layers. fileciteturn8file0

## Recommended next step

### Step 1 — Required code-control patch

Apply the permanent Section 13.0 comparison registry patch we discussed:

```text
tmp_m2_strategy_comparison_registry
→ exactly one active comparison
→ tmp_m2_strategy_comparison_params
```

This removes dependency on whatever latest-run strategy happens to be in:

```sql
credit_decisioning_sim.strategy_decisions
```

That is important because latest-run output is intentionally replaceable, while archive comparison should be explicitly selected.

### Step 2 — Add Section 15

Add:

```text
SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
```

I would **not** make this part of Section 13. Section 13 is pairwise matched comparison. The strategy frontier is broader: it compares many archived strategy / scenario slices and produces executive-level tradeoff metrics.

## Why Section 15 is valuable

Section 13 answered:

```text
How did one challenger strategy differ from one baseline strategy?
```

The strategy frontier should answer:

```text
Across all archived strategy runs, which strategy posture gives the best tradeoff between
offer exposure, approved amount, approved Expected Loss, affordability, manual-review burden,
and synthetic estimated-risk profile?
```

That is a much more senior-credit-strategy artifact.

It also aligns well with the Module 1 design philosophy: the system is built for scenario-comparable, governed experimentation, not isolated one-off outputs. Module 1’s BRD emphasizes parameter governance, scenario comparability, archive persistence, matched row-level comparison, and QA evidence as core design principles. fileciteturn8file3 Module 1’s Validation Summary also validates matched scenario comparison and emphasizes that scenario differences should be attributable to controlled assumptions rather than population drift. fileciteturn8file4

## Recommended Section 15 structure

I would build Section 15 as read-only and archive-driven.

```text
15.0 Frontier scope and boundary
15.1 Archived strategy frontier inventory
15.2 Strategy frontier summary by Module 1 scenario × Module 2 strategy
15.3 Baseline-relative strategy frontier deltas
15.4 Strategy efficiency metrics
15.5 Efficient-frontier ranking
15.6 Segment-level frontier highlights
15.7 GitHub / LinkedIn export-ready summary
```

## Core Section 15 metrics

Each archived slice should produce one row at this grain:

```text
module1_scenario_set_name
module1_scenario_name
population_id
strategy_set_name
strategy_name
strategy_version
```

Minimum fields:

```text
applications
approval_rate
counteroffer_rate
manual_review_rate
decline_rate
simulated_offer_exposure_rate
counteroffer_share_of_offers
total_requested_amount
total_approved_amount
avg_approved_amount_offer_rows
avg_synthetic_estimated_pd_proxy_offer_rows
avg_synthetic_estimated_pd_proxy_declined_rows
avg_requested_payment_to_income_ratio
avg_approved_payment_to_income_ratio_offer_rows
total_requested_expected_loss_amount
total_approved_expected_loss_amount
avg_approved_expected_loss_offer_rows
approved_expected_loss_rate
top_primary_reason_code
top_primary_reason_family
```

The key senior-level metric is:

```sql
approved_expected_loss_rate =
    total_approved_expected_loss_amount / NULLIF(total_approved_amount, 0)
```

That gives you a clean risk-efficiency metric.

## Frontier interpretation

The frontier should not simply rank the “best” strategy. It should classify strategy posture.

Example classifications:

```text
GROWTH_ORIENTED_FRONTIER
RISK_DISCIPLINE_FRONTIER
EXPOSURE_EFFICIENT_FRONTIER
AFFORDABILITY_DISCIPLINE_FRONTIER
HIGH_REVIEW_BURDEN
HIGH_DECLINE_BURDEN
BALANCED_BASELINE
```

This makes the output useful for storytelling.

For example, your current validated comparison already supports a strong frontier signal:

```text
TIGHTER_SYNTHETIC_RISK_STRATEGY:
- lower offer-exposure rate
- lower total approved amount
- lower total approved Expected Loss
- lower average synthetic estimated-PD proxy among offer rows
- higher decline rate
```

That is a classic **risk discipline** point on the frontier.

## Important boundary

There should be two types of frontier views:

### 1. Pure Module 2 strategy frontier

Same Module 1 scenario and population:

```text
BASELINE_V2 + BASELINE_STRATEGY
BASELINE_V2 + TIGHTER_SYNTHETIC_RISK_STRATEGY
BASELINE_V2 + GROWTH_ORIENTED_STRATEGY
BASELINE_V2 + COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
```

This is the cleanest apples-to-apples strategy frontier.

### 2. Scenario × strategy frontier

Multiple Module 1 scenarios and Module 2 strategies:

```text
RATE_UP_200BP + BASELINE_STRATEGY
RATE_DOWN_200BP + GROWTH_ORIENTED_STRATEGY
UNSECURED_GROWTH_MIX + PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
```

This is more like an executive control tower. It is useful, but it should not be interpreted as a pure strategy effect unless the Module 1 scenario is held constant.

## My recommendation

Proceed in this order:

```text
1. Patch Section 13.0 permanently.
2. Add Section 15 as a read-only frontier layer.
3. Build Section 15 first using the two archived strategies you already have.
4. Then add more Module 2 strategies to make the frontier more interesting.
```

With only two strategies, Section 15 will work, but it becomes truly compelling once you add at least:

```text
BASELINE_STRATEGY
TIGHTER_SYNTHETIC_RISK_STRATEGY
GROWTH_ORIENTED_STRATEGY
COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
```

That will create the marketable “strategy frontier” story:

```text
growth vs risk discipline vs affordability vs exposure management
```

So yes: **Section 15 is the right next enhancement**, but I would lock the Section 13.0 comparison registry patch first.
<!-- END_MESSAGE C038-M00493 -->


---

<a id="c038-m00495"></a>

### C038-M00495

**Andrew** · 2026-05-08T16:01:42.843000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00495 -->
13.0 patch is already installed.
<!-- END_MESSAGE C038-M00495 -->


---

<a id="c038-m00497"></a>

### C038-M00497

**ChatGPT** · 2026-05-08T16:02:43.901738-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00497 -->
Great. If the **local canonical SQL now has the Section 13.0 comparison registry patch installed**, then Section 13 is structurally ready and we can proceed to the strategy frontier layer.

One note: the older attached Section 13 excerpt still showed the prior placeholder-driven setup, where the challenger defaulted to `CHALLENGER_STRATEGY_PLACEHOLDER`. If that attachment is stale and your current script now uses the registry / active-comparison design, no issue. The executed QA already confirms the comparison worked correctly. fileciteturn8file0

## Recommended next step

Add a new read-only section:

```text
SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
```

This should come **after Section 14**.

Section 15 should consume:

```sql
credit_decisioning_sim.strategy_decisions_archive
```

It should not modify latest-run or archive rows.

## Why Section 15 is the right next enhancement

Section 13 answers:

```text
How did one challenger strategy compare to one baseline strategy?
```

Section 15 should answer:

```text
Across archived Module 1 scenarios and Module 2 strategies, what are the risk / growth / exposure / affordability tradeoffs?
```

That becomes your senior-credit-strategy “frontier” artifact.

## Proposed Section 15 structure

```text
15.0 Frontier scope and boundary
15.1 Archived frontier inventory
15.2 Strategy frontier summary
15.3 Baseline-relative frontier deltas
15.4 Strategy efficiency metrics
15.5 Frontier classification
15.6 Segment-level frontier highlights
15.7 Export-ready executive summary
```

## Core metrics Section 15 should produce

At minimum, one row per:

```text
module1_scenario_set_name
module1_scenario_name
population_id
strategy_set_name
strategy_name
strategy_version
```

with:

```text
applications
approval_rate
counteroffer_rate
manual_review_rate
decline_rate
simulated_offer_exposure_rate
counteroffer_share_of_offers
total_approved_amount
avg_approved_amount_offer_rows
avg_synthetic_estimated_pd_proxy_offer_rows
avg_approved_payment_to_income_ratio_offer_rows
total_approved_expected_loss_amount
avg_approved_expected_loss_offer_rows
approved_expected_loss_rate
top_primary_reason_code
top_primary_reason_family
```

The most important frontier metric should be:

```sql
approved_expected_loss_rate =
    total_approved_expected_loss_amount / NULLIF(total_approved_amount, 0)
```

That gives you an executive-readable risk-efficiency measure.

## Recommended next deliverable

The next SQL build should be:

```text
SECTION 15 ONLY — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
```

No changes to Sections 0–14.
<!-- END_MESSAGE C038-M00497 -->


---

<a id="c038-m00499"></a>

### C038-M00499

**Andrew** · 2026-05-08T16:03:24.754000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00499 -->
I agree with that structure.  Proceed with SECTION 15 ONLY — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
<!-- END_MESSAGE C038-M00499 -->


---

<a id="c038-m00504"></a>

### C038-M00504

**ChatGPT** · 2026-05-08T16:09:33.895612-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00504 -->
```sql
/***************************************************************************************************
SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW
****************************************************************************************************

BUSINESS PURPOSE:
    Provide an executive-ready, read-only strategy frontier view across archived Module 2 strategy
    outputs.

    Section 13 answers:

        "How does one selected challenger strategy compare to one selected baseline strategy?"

    Section 15 answers:

        "Across archived strategy / scenario slices, what are the portfolio-level tradeoffs between
         simulated offer exposure, approved amount, approved Expected Loss, affordability, synthetic
         estimated-risk profile, counteroffer usage, manual-review burden, and decline rate?"

SQL PURPOSE:
    1. Consume credit_decisioning_sim.strategy_decisions_archive.
    2. Summarize every archived Module 1 scenario × Module 2 strategy slice.
    3. Calculate strategy frontier metrics.
    4. Calculate baseline-relative deltas where a baseline strategy exists for the same Module 1
       scenario / population / strategy set.
    5. Classify strategy frontier posture using transparent diagnostic labels.
    6. Provide segment-level frontier highlights.
    7. Produce an executive-ready summary table for GitHub / LinkedIn / portfolio storytelling.

READ-ONLY BOUNDARY:
    Section 15 does not insert archive rows.
    Section 15 does not delete archive rows.
    Section 15 does not update archive rows.
    Section 15 does not modify credit_decisioning_sim.strategy_decisions.
    Section 15 does not modify credit_decisioning_sim.strategy_decisions_archive.
    Section 15 does not recalculate decision_outcome.
    Section 15 does not recalculate approved exposure.
    Section 15 does not recalculate approved Expected Loss.
    Section 15 does not reassign simulated reason codes.

TEMPORARY OUTPUTS CREATED:
    tmp_m2_strategy_frontier_inventory
    tmp_m2_strategy_frontier_summary
    tmp_m2_strategy_frontier_baseline_deltas
    tmp_m2_strategy_frontier_efficiency
    tmp_m2_strategy_frontier_classification
    tmp_m2_strategy_frontier_segment_highlights
    tmp_m2_strategy_frontier_executive_summary

INTERPRETATION BOUNDARIES:
    estimated_pd remains the finalized Module 1 SQL field name and is interpreted here as the
    synthetic estimated-PD proxy.

    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is simulated approved-exposure Expected Loss after Module 2
    exposure treatment.

    simulated_offer_exposure_flag identifies simulated positive offer-exposure outcomes:
        APPROVE
        COUNTEROFFER

    It does not imply operational account creation, funding, operational approval, or real applicant
    treatment.

    Simulated reason codes remain strategy explanation codes for QA, transparency, and portfolio
    interpretation. They are not customer communications or regulatory reason codes.

STRATEGY FRONTIER CONCEPT:
    A strategy frontier is not a single "best strategy" ranking.

    It is a structured view of tradeoffs:
        access / simulated offer exposure,
        approved exposure,
        approved Expected Loss,
        synthetic estimated-risk profile,
        affordability quality,
        counteroffer reliance,
        manual-review burden,
        and decline concentration.

    A growth-oriented point may increase simulated offer exposure while increasing approved Expected
    Loss. A risk-discipline point may reduce approved Expected Loss while lowering simulated offer
    exposure. A counteroffer-management point may preserve more access while reducing approved
    exposure quality metrics. These are strategy tradeoffs, not production recommendations.

SCENARIO / STRATEGY DISCIPLINE:
    Pure Module 2 strategy frontier:
        Compare multiple Module 2 strategies within the same Module 1 scenario and population.

    Scenario × strategy frontier:
        Compare archived outcomes across multiple Module 1 scenarios and Module 2 strategies.

    The pure strategy frontier is strongest for isolating downstream strategy effects.
    The broader scenario × strategy frontier is useful as an executive control-tower view, but users
    must preserve the distinction between upstream Module 1 scenario effects and downstream Module 2
    strategy effects.

***************************************************************************************************/



/***************************************************************************************************
SECTION 15.0 — FRONTIER SCOPE AND ARCHIVE READINESS SNAPSHOT
****************************************************************************************************

PURPOSE:
    Provide a quick read-only snapshot showing whether the archive contains strategy slices that can
    support frontier analysis.

INTERPRETATION:
    Frontier analysis becomes more useful as more archived strategies and scenarios are added.

    With one archived strategy slice, the frontier is an inventory only.
    With two archived strategies under the same Module 1 scenario, the frontier can show a basic
    tradeoff.
    With three or more strategies, the frontier can begin to show growth / risk / exposure management
    posture.

***************************************************************************************************/

SELECT
    'SECTION_15_FRONTIER_SCOPE' AS diagnostic_name,

    COUNT(*) AS archived_rows,
    COUNT(DISTINCT application_id) AS distinct_archived_application_ids,

    COUNT(DISTINCT
        strategy_set_name
        || '|' || strategy_name
        || '|' || strategy_version
        || '|' || module1_scenario_set_name
        || '|' || module1_scenario_name
        || '|' || population_id
    ) AS archived_strategy_scenario_slice_count,

    COUNT(DISTINCT
        module1_scenario_set_name
        || '|' || module1_scenario_name
        || '|' || population_id
    ) AS module1_scenario_population_slice_count,

    COUNT(DISTINCT
        strategy_set_name
        || '|' || strategy_name
        || '|' || strategy_version
    ) AS module2_strategy_version_count,

    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts,

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
SECTION 15.1 — ARCHIVED FRONTIER INVENTORY
****************************************************************************************************

PURPOSE:
    Create an inventory of archived strategy / scenario slices available for frontier analysis.

BUSINESS INTERPRETATION:
    This table answers:

        "What completed Module 2 strategy runs are available in the archive, and how many rows
         does each contain?"

GOVERNANCE ROLE:
    Frontier analysis should start from archive inventory, not latest-run output, because the archive
    preserves completed strategy slices across runs.

    latest-run output is intentionally replaceable.
    archive output is the governed history layer.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_inventory;

CREATE TEMP TABLE tmp_m2_strategy_frontier_inventory
ON COMMIT PRESERVE ROWS
AS
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS archived_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_row_count,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,

    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

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


/*
Review output:
    Archive frontier inventory.

Expected use:
    Confirm which strategy / scenario slices exist before interpreting frontier metrics.
*/
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
    Produce one summary row per archived Module 1 scenario × Module 2 strategy slice.

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
        and primary reason-code concentration.

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

    counteroffer_share_of_offers:
        counteroffer_count / simulated_offer_exposure_count

    approved_expected_loss_rate:
        total_approved_expected_loss_amount / total_approved_amount

    All-application approved exposure metrics:
        Use COALESCE(approved_amount, 0)
        Use COALESCE(approved_expected_loss_amount, 0)

    Offer-row metrics:
        Use FILTER (WHERE simulated_offer_exposure_flag IS TRUE)

BOUNDARY:
    approved_expected_loss_rate is a frontier efficiency metric for synthetic strategy comparison.
    It is not a production loss-rate forecast.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_summary;

CREATE TEMP TABLE tmp_m2_strategy_frontier_summary
ON COMMIT PRESERVE ROWS
AS
WITH slice_summary AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS applications,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_count,

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

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS approval_share_of_offers,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS counteroffer_share_of_offers,

        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS avg_exposure_reduction_pct_counteroffers,

        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows,

        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_declined_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS avg_synthetic_estimated_pd_proxy_manual_review_rows,

        AVG(estimated_lgd) AS avg_estimated_lgd_all_apps,

        AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_estimated_lgd_offer_rows,

        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

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
)

SELECT
    s.*,

    r.primary_reason_family AS top_primary_reason_family,
    r.primary_reason_code AS top_primary_reason_code,
    r.primary_reason_row_count AS top_primary_reason_row_count,
    r.primary_reason_population_share AS top_primary_reason_population_share

FROM slice_summary s
LEFT JOIN reason_counts r
    ON r.strategy_set_name = s.strategy_set_name
   AND r.strategy_name = s.strategy_name
   AND r.strategy_version = s.strategy_version
   AND r.module1_scenario_set_name = s.module1_scenario_set_name
   AND r.module1_scenario_name = s.module1_scenario_name
   AND r.population_id = s.population_id
   AND r.reason_rank = 1;


/*
Review output:
    Core strategy frontier summary.
*/
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

BOUNDARY:
    If no baseline strategy exists for a scenario / strategy set, baseline-relative fields are NULL
    and baseline_available_flag is FALSE.

    This is diagnostic behavior, not a failure.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_baseline_deltas;

CREATE TEMP TABLE tmp_m2_strategy_frontier_baseline_deltas
ON COMMIT PRESERVE ROWS
AS
WITH baseline_reference AS (
    SELECT *
    FROM tmp_m2_strategy_frontier_summary
    WHERE strategy_name = 'BASELINE_STRATEGY'
)

SELECT
    s.strategy_set_name,
    s.strategy_name,
    s.strategy_version,

    s.module1_scenario_set_name,
    s.module1_scenario_name,
    s.population_id,

    b.strategy_name AS baseline_strategy_name,
    b.strategy_version AS baseline_strategy_version,

    (b.strategy_name IS NOT NULL) AS baseline_available_flag,

    s.applications,
    b.applications AS baseline_applications,
    s.applications - b.applications AS delta_applications,

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

    s.simulated_offer_exposure_rate,
    b.simulated_offer_exposure_rate AS baseline_simulated_offer_exposure_rate,
    s.simulated_offer_exposure_rate - b.simulated_offer_exposure_rate
        AS delta_simulated_offer_exposure_rate,

    s.counteroffer_share_of_offers,
    b.counteroffer_share_of_offers AS baseline_counteroffer_share_of_offers,
    s.counteroffer_share_of_offers - b.counteroffer_share_of_offers
        AS delta_counteroffer_share_of_offers,

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

    s.top_primary_reason_family,
    s.top_primary_reason_code,
    s.top_primary_reason_population_share

FROM tmp_m2_strategy_frontier_summary s
LEFT JOIN baseline_reference b
    ON b.strategy_set_name = s.strategy_set_name
   AND b.module1_scenario_set_name = s.module1_scenario_set_name
   AND b.module1_scenario_name = s.module1_scenario_name
   AND b.population_id = s.population_id;


/*
Review output:
    Baseline-relative strategy frontier deltas.
*/
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
    Convert frontier summary metrics into executive-readable efficiency indicators.

BUSINESS INTERPRETATION:
    These metrics help compare strategy posture.

    Examples:
        How much approved exposure is produced per unit of approved Expected Loss?
        How many simulated positive offer outcomes are produced per million dollars of approved
        Expected Loss?
        What is the approved Expected Loss rate on simulated approved exposure?
        How much manual-review burden does the strategy create?

IMPORTANT:
    These are comparative synthetic strategy metrics.
    They are not profitability, capital, pricing, or production risk-adjusted return metrics.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_efficiency;

CREATE TEMP TABLE tmp_m2_strategy_frontier_efficiency
ON COMMIT PRESERVE ROWS
AS
SELECT
    d.*,

    d.total_approved_expected_loss_amount
        / NULLIF(d.total_approved_amount, 0)
        AS frontier_approved_expected_loss_rate,

    d.total_approved_amount
        / NULLIF(d.total_approved_expected_loss_amount, 0)
        AS approved_amount_per_approved_expected_loss_dollar,

    d.simulated_offer_exposure_rate
        / NULLIF(d.approved_expected_loss_rate, 0)
        AS offer_rate_per_approved_expected_loss_rate_unit,

    d.applications::NUMERIC
        / NULLIF(d.total_approved_expected_loss_amount / 1000000.0, 0)
        AS applications_per_million_approved_expected_loss,

    d.simulated_offer_exposure_rate AS positive_offer_access_rate,

    d.manual_review_rate AS manual_review_burden_rate,

    d.decline_rate AS no_offer_outcome_rate,

    CASE
        WHEN d.total_approved_amount IS NULL
          OR d.total_approved_amount = 0
            THEN 'NO_SIMULATED_OFFER_EXPOSURE_FOR_EFFICIENCY_REVIEW'

        WHEN d.total_approved_expected_loss_amount IS NULL
            THEN 'APPROVED_EXPECTED_LOSS_NOT_AVAILABLE_FOR_EFFICIENCY_REVIEW'

        ELSE 'FRONTIER_EFFICIENCY_METRICS_AVAILABLE'
    END AS frontier_efficiency_metric_status

FROM tmp_m2_strategy_frontier_baseline_deltas d;


/*
Review output:
    Strategy efficiency metrics.
*/
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
    applications_per_million_approved_expected_loss,

    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_approved_payment_to_income_ratio_offer_rows,

    top_primary_reason_family,
    top_primary_reason_code,

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
SECTION 15.5 — FRONTIER CLASSIFICATION
****************************************************************************************************

PURPOSE:
    Assign diagnostic strategy posture labels to each archived frontier point.

BUSINESS INTERPRETATION:
    These labels help reviewers interpret what kind of tradeoff each strategy appears to represent.

CLASSIFICATION BOUNDARY:
    The classifications are diagnostic summaries.

    They do not declare a strategy "best."
    They do not recommend production use.
    They do not replace detailed Section 13 matched comparison or Section 14 validation.

DIAGNOSTIC THRESHOLD NOTE:
    Small threshold values are used only to avoid labeling immaterial changes as strategic movement.

    These thresholds are not credit policy thresholds.
    They are not underwriting cutoffs.
    They are not calibrated empirical performance thresholds.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_classification;

CREATE TEMP TABLE tmp_m2_strategy_frontier_classification
ON COMMIT PRESERVE ROWS
AS
SELECT
    e.*,

    CASE
        WHEN e.strategy_name = 'BASELINE_STRATEGY'
            THEN 'BASELINE_REFERENCE_POINT'

        WHEN e.baseline_available_flag IS DISTINCT FROM TRUE
            THEN 'NO_BASELINE_REFERENCE_AVAILABLE'

        WHEN e.delta_simulated_offer_exposure_rate <= -0.010
         AND e.delta_total_approved_expected_loss_amount < 0
         AND e.delta_avg_synthetic_estimated_pd_proxy_offer_rows < 0
            THEN 'RISK_DISCIPLINE_FRONTIER_POINT'

        WHEN e.delta_simulated_offer_exposure_rate >= 0.010
         AND e.delta_total_approved_amount > 0
         AND e.delta_total_approved_expected_loss_amount >= 0
            THEN 'GROWTH_ORIENTED_FRONTIER_POINT'

        WHEN e.delta_total_approved_expected_loss_amount < 0
         AND e.delta_total_approved_amount >= 0
            THEN 'EXPOSURE_EFFICIENT_FRONTIER_POINT'

        WHEN e.delta_counteroffer_rate >= 0.010
         AND e.delta_approval_rate <= 0
            THEN 'COUNTEROFFER_MANAGEMENT_FRONTIER_POINT'

        WHEN e.delta_manual_review_rate <= -0.010
         AND e.delta_decline_rate > 0
            THEN 'REVIEW_BURDEN_REDUCTION_FRONTIER_POINT'

        ELSE 'BALANCED_OR_MIXED_FRONTIER_POINT'
    END AS frontier_position_type,

    CASE
        WHEN e.strategy_name = 'BASELINE_STRATEGY'
            THEN 'Reference point for same Module 1 scenario / population / strategy set.'

        WHEN e.baseline_available_flag IS DISTINCT FROM TRUE
            THEN 'No baseline strategy slice exists for this Module 1 scenario / population / strategy set.'

        WHEN e.delta_simulated_offer_exposure_rate <= -0.010
         AND e.delta_total_approved_expected_loss_amount < 0
         AND e.delta_avg_synthetic_estimated_pd_proxy_offer_rows < 0
            THEN 'Strategy reduces simulated offer exposure and approved Expected Loss while improving offered-population synthetic estimated-risk profile.'

        WHEN e.delta_simulated_offer_exposure_rate >= 0.010
         AND e.delta_total_approved_amount > 0
         AND e.delta_total_approved_expected_loss_amount >= 0
            THEN 'Strategy expands simulated offer exposure and approved amount with measurable approved Expected Loss tradeoff.'

        WHEN e.delta_total_approved_expected_loss_amount < 0
         AND e.delta_total_approved_amount >= 0
            THEN 'Strategy improves approved Expected Loss while maintaining or expanding total approved amount.'

        WHEN e.delta_counteroffer_rate >= 0.010
         AND e.delta_approval_rate <= 0
            THEN 'Strategy shifts outcomes toward reduced-exposure treatment rather than clean approval.'

        WHEN e.delta_manual_review_rate <= -0.010
         AND e.delta_decline_rate > 0
            THEN 'Strategy reduces unresolved manual-review burden by routing more cases to final no-offer outcomes.'

        ELSE 'Strategy shows mixed tradeoffs requiring segment-level and reason-code review.'
    END AS frontier_interpretation_note

FROM tmp_m2_strategy_frontier_efficiency e;


/*
Review output:
    Strategy frontier classification.
*/
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    frontier_position_type,
    frontier_interpretation_note,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,

    delta_approval_rate,
    delta_counteroffer_rate,
    delta_manual_review_rate,
    delta_decline_rate,
    delta_simulated_offer_exposure_rate,

    total_approved_amount,
    delta_total_approved_amount,

    total_approved_expected_loss_amount,
    delta_total_approved_expected_loss_amount,

    approved_expected_loss_rate,
    delta_approved_expected_loss_rate,

    avg_synthetic_estimated_pd_proxy_offer_rows,
    delta_avg_synthetic_estimated_pd_proxy_offer_rows,

    top_primary_reason_family,
    top_primary_reason_code
FROM tmp_m2_strategy_frontier_classification
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 15.6 — SEGMENT-LEVEL FRONTIER HIGHLIGHTS
****************************************************************************************************

PURPOSE:
    Provide product, score-band, and product × score-band frontier summaries across archived slices.

BUSINESS INTERPRETATION:
    Portfolio frontier metrics can hide concentrated segment movement.

    This segment table helps reviewers answer:
        Which products carry the most approved exposure?
        Which score bands dominate approved Expected Loss?
        Which product × score combinations are most sensitive to strategy posture?

BOUNDARY:
    This is a segment summary over archived outputs.
    It does not recalculate decisions or approved economics.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_segment_highlights;

CREATE TEMP TABLE tmp_m2_strategy_frontier_segment_highlights
ON COMMIT PRESERVE ROWS
AS
WITH segment_base AS (
    SELECT
        'PRODUCT'::TEXT AS segment_level,
        product_type_policy_key AS segment_key,
        product_type_policy_key,
        NULL::TEXT AS score_band_policy_key,

        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        decision_outcome,
        simulated_offer_exposure_flag,
        approved_amount,
        approved_expected_loss_amount,
        estimated_pd,
        approved_payment_to_income_ratio,
        primary_reason_family,
        primary_reason_code
    FROM credit_decisioning_sim.strategy_decisions_archive

    UNION ALL

    SELECT
        'SCORE_BAND'::TEXT AS segment_level,
        score_band_policy_key AS segment_key,
        NULL::TEXT AS product_type_policy_key,
        score_band_policy_key,

        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        decision_outcome,
        simulated_offer_exposure_flag,
        approved_amount,
        approved_expected_loss_amount,
        estimated_pd,
        approved_payment_to_income_ratio,
        primary_reason_family,
        primary_reason_code
    FROM credit_decisioning_sim.strategy_decisions_archive

    UNION ALL

    SELECT
        'PRODUCT_X_SCORE'::TEXT AS segment_level,
        product_type_policy_key || ' / ' || score_band_policy_key AS segment_key,
        product_type_policy_key,
        score_band_policy_key,

        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        decision_outcome,
        simulated_offer_exposure_flag,
        approved_amount,
        approved_expected_loss_amount,
        estimated_pd,
        approved_payment_to_income_ratio,
        primary_reason_family,
        primary_reason_code
    FROM credit_decisioning_sim.strategy_decisions_archive
),

segment_summary AS (
    SELECT
        segment_level,
        segment_key,
        product_type_policy_key,
        score_band_policy_key,

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

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows
    FROM segment_base
    GROUP BY
        segment_level,
        segment_key,
        product_type_policy_key,
        score_band_policy_key,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

segment_reason_counts AS (
    SELECT
        segment_level,
        segment_key,
        product_type_policy_key,
        score_band_policy_key,

        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS reason_row_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                segment_level,
                segment_key,
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
    FROM segment_base
    GROUP BY
        segment_level,
        segment_key,
        product_type_policy_key,
        score_band_policy_key,
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
    s.*,

    r.primary_reason_family AS top_segment_reason_family,
    r.primary_reason_code AS top_segment_reason_code,
    r.reason_row_count AS top_segment_reason_row_count

FROM segment_summary s
LEFT JOIN segment_reason_counts r
    ON r.segment_level = s.segment_level
   AND r.segment_key = s.segment_key
   AND r.strategy_set_name = s.strategy_set_name
   AND r.strategy_name = s.strategy_name
   AND r.strategy_version = s.strategy_version
   AND r.module1_scenario_set_name = s.module1_scenario_set_name
   AND r.module1_scenario_name = s.module1_scenario_name
   AND r.population_id = s.population_id
   AND r.reason_rank = 1;


/*
Review output:
    Segment-level frontier highlights.

This output can be large as the archive grows. The ORDER BY prioritizes higher approved Expected Loss
segments because those are usually the most important for risk / exposure review.
*/
SELECT
    *
FROM tmp_m2_strategy_frontier_segment_highlights
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    segment_level,
    total_approved_expected_loss_amount DESC NULLS LAST,
    segment_key
LIMIT 300;



/***************************************************************************************************
SECTION 15.7 — EXECUTIVE-READY STRATEGY FRONTIER SUMMARY
****************************************************************************************************

PURPOSE:
    Produce a compact strategy frontier table suitable for export into a README, executive review,
    or later presentation artifact.

BUSINESS INTERPRETATION:
    This table intentionally combines:
        decision distribution,
        simulated offer exposure,
        approved exposure,
        approved Expected Loss,
        efficiency metrics,
        strategy posture classification,
        and primary reason-code concentration.

    It is designed to support a concise story:
        "What tradeoff does each strategy / scenario point represent?"

RANKING BOUNDARY:
    Rankings are calculated within each Module 1 scenario / population / strategy set.

    These ranks support comparison, but they do not declare production suitability.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_frontier_executive_summary;

CREATE TEMP TABLE tmp_m2_strategy_frontier_executive_summary
ON COMMIT PRESERVE ROWS
AS
WITH ranked AS (
    SELECT
        c.*,

        COUNT(*) OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        ) AS strategy_count_within_frontier_group,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                simulated_offer_exposure_rate DESC NULLS LAST
        ) AS offer_access_rank_desc,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                total_approved_amount DESC NULLS LAST
        ) AS approved_amount_rank_desc,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                total_approved_expected_loss_amount ASC NULLS LAST
        ) AS total_approved_expected_loss_rank_asc,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                approved_expected_loss_rate ASC NULLS LAST
        ) AS approved_expected_loss_rate_rank_asc,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                avg_synthetic_estimated_pd_proxy_offer_rows ASC NULLS LAST
        ) AS offer_risk_profile_rank_asc,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                manual_review_rate ASC NULLS LAST
        ) AS manual_review_burden_rank_asc,

        RANK() OVER (
            PARTITION BY
                strategy_set_name,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
            ORDER BY
                decline_rate ASC NULLS LAST
        ) AS decline_burden_rank_asc
    FROM tmp_m2_strategy_frontier_classification c
)

SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    frontier_position_type,
    frontier_interpretation_note,

    strategy_count_within_frontier_group,

    applications,

    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,
    counteroffer_share_of_offers,

    total_approved_amount,
    avg_approved_amount_offer_rows,

    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_approved_payment_to_income_ratio_offer_rows,

    total_approved_expected_loss_amount,
    avg_approved_expected_loss_offer_rows,
    approved_expected_loss_rate,

    approved_amount_per_approved_expected_loss_dollar,

    top_primary_reason_family,
    top_primary_reason_code,
    top_primary_reason_population_share,

    baseline_available_flag,

    delta_approval_rate,
    delta_counteroffer_rate,
    delta_manual_review_rate,
    delta_decline_rate,
    delta_simulated_offer_exposure_rate,

    delta_total_approved_amount,
    delta_total_approved_expected_loss_amount,
    delta_approved_expected_loss_rate,
    delta_avg_synthetic_estimated_pd_proxy_offer_rows,

    offer_access_rank_desc,
    approved_amount_rank_desc,
    total_approved_expected_loss_rank_asc,
    approved_expected_loss_rate_rank_asc,
    offer_risk_profile_rank_asc,
    manual_review_burden_rank_asc,
    decline_burden_rank_asc,

    CASE
        WHEN strategy_count_within_frontier_group < 2
            THEN 'SINGLE_STRATEGY_FRONTIER_GROUP'

        WHEN offer_access_rank_desc <= 2
         AND approved_expected_loss_rate_rank_asc <= 2
            THEN 'HIGH_ACCESS_LOWER_APPROVED_EL_RATE'

        WHEN offer_access_rank_desc <= 2
         AND approved_expected_loss_rate_rank_asc > 2
            THEN 'HIGH_ACCESS_HIGHER_APPROVED_EL_RATE'

        WHEN offer_access_rank_desc > 2
         AND approved_expected_loss_rate_rank_asc <= 2
            THEN 'LOWER_ACCESS_LOWER_APPROVED_EL_RATE'

        ELSE 'LOWER_ACCESS_HIGHER_APPROVED_EL_RATE'
    END AS executive_frontier_quadrant

FROM ranked;


/*
Review output:
    Executive-ready strategy frontier summary.

This is the primary Section 15 output for high-level strategy storytelling.
*/
SELECT
    *
FROM tmp_m2_strategy_frontier_executive_summary
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    CASE
        WHEN strategy_name = 'BASELINE_STRATEGY' THEN 1
        ELSE 2
    END,
    frontier_position_type,
    strategy_name,
    strategy_version;



/***************************************************************************************************
SECTION 15.8 — FRONTIER DIAGNOSTIC SUMMARY
****************************************************************************************************

PURPOSE:
    Provide compact diagnostic counts for the Section 15 temporary outputs.

INTERPRETATION:
    These checks are not full QA gatekeepers.

    They confirm that the frontier layer produced populated temporary outputs and show whether
    baseline-relative comparisons are available.

***************************************************************************************************/

SELECT
    'tmp_m2_strategy_frontier_inventory' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_inventory

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_summary' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_summary

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_baseline_deltas' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_baseline_deltas

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_efficiency' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_efficiency

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_classification' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_classification

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_segment_highlights' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_segment_highlights

UNION ALL

SELECT
    'tmp_m2_strategy_frontier_executive_summary' AS frontier_object_name,
    COUNT(*) AS row_count
FROM tmp_m2_strategy_frontier_executive_summary;


/*
Baseline availability diagnostic.

If baseline_available_flag is FALSE, baseline-relative deltas for that archived strategy / scenario
slice should be interpreted as unavailable rather than zero.
*/
SELECT
    strategy_set_name,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS frontier_rows,
    COUNT(*) FILTER (WHERE baseline_available_flag IS TRUE) AS rows_with_baseline_reference,
    COUNT(*) FILTER (WHERE baseline_available_flag IS FALSE) AS rows_without_baseline_reference,

    CASE
        WHEN COUNT(*) FILTER (WHERE baseline_available_flag IS FALSE) = 0
            THEN 'BASELINE_REFERENCES_AVAILABLE_FOR_ALL_FRONTIER_ROWS'
        ELSE 'BASELINE_REFERENCE_MISSING_FOR_ONE_OR_MORE_FRONTIER_ROWS'
    END AS baseline_reference_status
FROM tmp_m2_strategy_frontier_baseline_deltas
GROUP BY
    strategy_set_name,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
ORDER BY
    strategy_set_name,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;


/***************************************************************************************************
END OF SECTION 15 — STRATEGY FRONTIER SUMMARY AND EXECUTIVE COMPARISON VIEW

Section 15 established:
    1. Read-only archive-driven strategy frontier analysis.
    2. One-row-per-archived-slice frontier summary.
    3. Baseline-relative strategy deltas where BASELINE_STRATEGY exists.
    4. Strategy efficiency metrics, including approved_expected_loss_rate.
    5. Diagnostic frontier posture classifications.
    6. Product, score, and product × score frontier segment highlights.
    7. Executive-ready strategy frontier summary for portfolio storytelling.

No archive rows have been inserted.
No archive rows have been deleted.
No archive rows have been updated.
No latest-run rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been recalculated.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00504 -->


---

<a id="c038-m00505"></a>

### C038-M00505

**Andrew** · 2026-05-08T16:33:17.518000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00505 -->
review section 15 QA: 
<!-- END_MESSAGE C038-M00505 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.2_QA_strategy_frontier_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.3_QA_baseline_relative_frontier_deltas.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.4_QA_strategy_efficiency_metrics.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.5_QA_frontier_classification.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.6_QA_segment_level_frontier_highlights.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7_QA_executive_ready_strategy_frontier_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8_QA_frontier_diagnostic_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8_QA_frontier_baseline_availability_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0_QA_frontier_scope_and_archive_readiness_snapshot.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.1_QA_archived_frontier_inventory.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_21.md) · [Next](Part_23.md)
