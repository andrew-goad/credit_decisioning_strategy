# Module 2 Decision Simulator Build

## Part 91

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_90.md)

<a id="c038-m01845"></a>

### C038-M01845

**ChatGPT** · 2026-05-13T10:07:49.010821-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01845 -->
According to a document from 2026-05-13, this is most likely coming from **Section 13.7C — Product × score-band comparison**, not from the M2-01 parameter setup. In the current file, Section 13.7C builds separate `baseline b` and `challenger c` CTEs, then `FULL OUTER JOIN`s them on `product_type_policy_key` and `score_band_policy_key`. Both joined tables expose a column named `score_band_policy_key`, so an unqualified reference like `CASE score_band_policy_key ...` becomes ambiguous. fileciteturn318file18

## What to change

Find the final `ORDER BY` at the end of **Section 13.7C**. It likely looks like this:

```sql
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
```

Replace it with this:

```sql
ORDER BY
    COALESCE(b.product_type_policy_key, c.product_type_policy_key),

    CASE COALESCE(b.score_band_policy_key, c.score_band_policy_key)
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;
```

That should resolve the ambiguity.

## Why this fixes it

The `SELECT` creates readable output aliases:

```sql
COALESCE(b.product_type_policy_key, c.product_type_policy_key) AS product_type_policy_key,
COALESCE(b.score_band_policy_key, c.score_band_policy_key) AS score_band_policy_key,
```

But inside `CASE score_band_policy_key`, PostgreSQL can still see both joined input columns:

```sql
b.score_band_policy_key
c.score_band_policy_key
```

So it does not know which one you mean. Using `COALESCE(b.score_band_policy_key, c.score_band_policy_key)` makes the intended join-side-safe segment key explicit.

## Also check Section 13.7B

If you see the same pattern in **Section 13.7B — Score-band-level comparison**, apply the same style. The unsafe form is:

```sql
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;
```

The safe replacement is:

```sql
ORDER BY
    CASE COALESCE(b.score_band_policy_key, c.score_band_policy_key)
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END;
```

## Do you need to clear anything?

No. This is a SQL reference/alias issue, not a data corruption issue.

If you are still in the same session and M2-01 already made it through Section 12, you can patch Section 13.7C and continue from **Section 13**. If you prefer a clean test path, rerun **M2-01 from Section 1** after applying the patch.
<!-- END_MESSAGE C038-M01845 -->


---

<a id="c038-m01846"></a>

### C038-M01846

**Andrew** · 2026-05-13T12:34:12.869000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01846 -->
M2-1 through M2-13 ran successfully.  M2-14 populated this error: SQL Error [P0001]: ERROR: Module 2 Section 13 failure: expected exactly one active comparison registry row, found 0.
  Where: PL/pgSQL function inline_code_block line 109 at RAISE
  ERROR: Module 2 Section 13 failure: expected exactly one active comparison registry row, found 0.
  Where: PL/pgSQL function inline_code_block line 109 at RAISE
<!-- END_MESSAGE C038-M01846 -->


---

<a id="c038-m01855"></a>

### C038-M01855

**ChatGPT** · 2026-05-13T12:38:20.475598-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01855 -->
According to a document from 2026-05-13, this is expected for **M2-14** if you are running Section 13 as part of the full sequence. Section 2 explicitly says that when `effective_comparison_group_id` is `NULL`, Section 13 will not have an active comparison unless you set `selected_comparison_group_id` explicitly; common reasons include the selected run not being part of any comparison or being a baseline in multiple comparisons. fileciteturn319file4 Section 3 also says comparison selection is optional for a single strategy slice, and the active comparison helper may contain zero rows; Section 13 is the part that requires exactly one active comparison **when Section 13 itself is run**. fileciteturn319file11

## What happened

**M2-14 is a reference run, not a governed baseline/challenger comparison run.**

You selected:

```sql
selected_module2_run_id = 'M2-14'
```

M2-14 maps to the credit-box baseline/reference scenario. It does not naturally resolve to one active comparison group. Therefore Section 13 found:

```text
active comparison registry rows = 0
```

and raised:

```text
Module 2 Section 13 failure: expected exactly one active comparison registry row, found 0.
```

That specific hard fail is coming from Section 13’s active comparison cardinality check, which currently raises when the active comparison count is not exactly one. fileciteturn320file13

## Immediate next step for M2-14

Do **not** treat this as a failed M2-14 strategy run.

If your SQL client is using normal autocommit behavior, Sections 1–12 likely completed and M2-14 was archived before Section 13 failed. In that case, continue with:

```text
skip Section 13
run Section 14
run Section 15
run Section 16 through 16.8
```

Section 14 is designed to handle this case. If Section 13 comparison helpers are absent, Section 14 creates NOT_APPLICABLE comparison-readiness context instead of failing latest-run QA solely because matched comparison was not run. fileciteturn321file16

## Quick validation before continuing

Run this to confirm the M2-14 latest-run table still exists:

```sql
SELECT
    COUNT(*) AS latest_run_rows,
    COUNT(DISTINCT application_id) AS latest_run_distinct_application_ids
FROM credit_decisioning_sim.strategy_decisions;
```

Then confirm M2-14 archive persistence:

```sql
SELECT
    r.module2_run_id,
    r.run_sequence_number,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_name,
    r.strategy_version,

    COUNT(a.*) AS archived_rows,
    COUNT(DISTINCT a.application_id) AS archived_distinct_application_ids

FROM credit_decisioning_sim.strategy_run_campaign_registry r

LEFT JOIN credit_decisioning_sim.strategy_decisions_archive a
    ON a.strategy_set_name = r.strategy_set_name
   AND a.strategy_name = r.strategy_name
   AND a.strategy_version = r.strategy_version
   AND a.module1_scenario_set_name = r.module1_scenario_set_name
   AND a.module1_scenario_name = r.module1_scenario_name
   AND a.population_id = r.population_id

WHERE r.module2_run_id = 'M2-14'
  AND r.registry_active_flag IS TRUE

GROUP BY
    r.module2_run_id,
    r.run_sequence_number,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_name,
    r.strategy_version;
```

If `latest_run_rows` is populated and the archive query returns the expected row count, continue from **Section 14**.

If your SQL client runs the whole script inside one explicit transaction and rolled everything back, rerun M2-14 from Section 1, but **skip Section 13**.

## Which campaign runs should skip Section 13?

For this rerun campaign, run Section 13 only when there is a governed comparison selected. Skip Section 13 for standalone/reference runs.

Likely skip Section 13 for:

```text
M2-14
M2-15
M2-21
M2-24
M2-27
M2-30
M2-31
M2-32
```

Also watch baseline runs that are used in multiple comparisons. For those, Section 13 may require explicit selection if you actually want a comparison:

```text
M2-01  can compare to CG01–CG06
M2-16  can compare to CG10–CG11
```

For ordinary campaign evidence capture, it is fine to skip Section 13 on those baseline/reference rows unless you specifically want a selected comparison context captured for that run.

## Practical campaign execution rule

For each M2 run:

```text
Run Sections 1–12.
Check Section 2.11F / 3.5H active comparison selection.
If effective_comparison_group_id is populated, run Section 13.
If effective_comparison_group_id is NULL, skip Section 13.
Run Sections 14–16.8.
```

For **M2-14 specifically**, continue with **Section 14** now.
<!-- END_MESSAGE C038-M01855 -->


---

<a id="c038-m01856"></a>

### C038-M01856

**Andrew** · 2026-05-13T12:44:16.873000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01856 -->
Can't we add logic to skip section 13 for those specific campaigns?  seems like it'd be easier to explain in run procedure.  also, maybe add a parameter at the top so custom runs can decide to skip or not, without having to manually skip.
<!-- END_MESSAGE C038-M01856 -->


---

<a id="c038-m01859"></a>

### C038-M01859

**ChatGPT** · 2026-05-13T12:51:16.849414-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01859 -->
According to a document from 2026-05-13, yes — this is the right fix. The current code already tells the user that `selected_comparison_group_id` is optional and that Section 2 can auto-select a comparison when possible, but it also warns that when `effective_comparison_group_id` is `NULL`, Section 13 will not have an active comparison unless the user explicitly selects one. fileciteturn323file13 fileciteturn323file5 The problem is that Section 13 still hard-fails when it does not find exactly one active comparison row. fileciteturn323file0

I recommend **not hardcoding specific M2 runs like M2-14 / M2-15 / M2-21**. Instead, add a simple operator control:

```sql
section13_execution_mode = 'AUTO'
```

Then Section 13 behaves as follows:

| Mode | Behavior |
|---|---|
| `AUTO` | Run Section 13 only when Section 2 resolved exactly one comparison. Otherwise create NOT_APPLICABLE comparison context and continue. |
| `SKIP` | Always skip matched comparison for this run. Useful for custom/ad hoc runs. |
| `REQUIRE` | Require exactly one active comparison and fail if missing. Useful when the operator intentionally wants Section 13 comparison evidence. |

This makes the full campaign procedure simple again:

```text
For each M2 run:
    set selected_module2_run_id
    keep section13_execution_mode = 'AUTO'
    run straight through Sections 1–16.8
```

For M2-14, `AUTO` would skip Section 13 because no comparison is naturally selected, then Section 14 can continue and carry comparison context as NOT_APPLICABLE. Section 14 already has a design pattern for temporary NOT_APPLICABLE comparison/source-consistency placeholders when Section 13 has not produced real comparison evidence. fileciteturn324file14

---

## Patch 1 — add Section 13 control object to Section 1 and Section 2 resets

Add this line anywhere you are already dropping the Section 2 comparison helpers in **Section 1.2 / 1.4** and **Section 2.0**:

```sql
DROP TABLE IF EXISTS tmp_m2_section13_execution_control;
```

For example, in **Section 2.0**, use:

```sql
DROP TABLE IF EXISTS tmp_m2_comparison_plan;
DROP TABLE IF EXISTS tmp_m2_active_comparison_selection;
DROP TABLE IF EXISTS tmp_m2_section13_execution_control;
```

---

## Patch 2 — add the Section 13 execution parameter to Section 2.1

In `tmp_m2_operator_run_selector`, add this column immediately after `selected_comparison_group_id`:

```sql
    /***********************************************************************************************
    Section 13 execution control.

    AUTO:
        Run Section 13 only when Section 2 resolves exactly one active comparison.
        If no comparison is resolved, Section 13 creates NOT_APPLICABLE comparison context and
        continues without failure.

    SKIP:
        Never run matched comparison for this run.
        Useful for custom/ad hoc runs where comparison evidence is intentionally not needed.

    REQUIRE:
        Require exactly one active comparison.
        Useful when the operator intentionally wants Section 13 comparison evidence and wants the
        script to fail if comparison selection is missing or ambiguous.
    ***********************************************************************************************/
    section13_execution_mode                    TEXT NOT NULL DEFAULT 'AUTO',
```

Then update the insert column list from:

```sql
INSERT INTO tmp_m2_operator_run_selector (
    active_selector_flag,
    run_mode,
    selected_module2_run_id,
    selected_comparison_group_id
)
```

to:

```sql
INSERT INTO tmp_m2_operator_run_selector (
    active_selector_flag,
    run_mode,
    selected_module2_run_id,
    selected_comparison_group_id,
    section13_execution_mode
)
```

And update the `VALUES` from:

```sql
VALUES (
    TRUE,
    'STANDARD_CAMPAIGN',
    'M2-01',
    NULL
);
```

to:

```sql
VALUES (
    TRUE,
    'STANDARD_CAMPAIGN',
    'M2-01',
    NULL,
    'AUTO'
);
```

For the full campaign rerun, keep:

```sql
section13_execution_mode = 'AUTO'
```

---

## Patch 3 — add a new Section 2 control table after active comparison selection

Place this **after `tmp_m2_active_comparison_selection` has been created** and before Section 2 diagnostics.

```sql
/***************************************************************************************************
SECTION 2.10X — SECTION 13 EXECUTION CONTROL
****************************************************************************************************

BUSINESS PURPOSE:
    Decide whether Section 13 matched comparison should run for the selected Module 2 run.

WHY THIS EXISTS:
    Not every formal campaign run has a natural matched baseline / challenger comparison.

    Some runs are reference slices, standalone scenario anchors, or baseline runs used by multiple
    comparison groups.

    Prior behavior required the user to manually skip Section 13 when no unique comparison existed.

    This control makes the run procedure simpler:
        section13_execution_mode = AUTO

    AUTO allows the full script to continue through Section 13 without failure when no comparison is
    applicable.

SECTION 13 MODES:
    AUTO:
        Run Section 13 only when effective_comparison_group_id is populated.

    SKIP:
        Always skip Section 13 matched comparison.

    REQUIRE:
        Require Section 13 matched comparison and fail if no active comparison is available.

OUTPUT:
    tmp_m2_section13_execution_control

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_section13_execution_control;

CREATE TEMP TABLE tmp_m2_section13_execution_control
ON COMMIT PRESERVE ROWS
AS
WITH selector AS (
    SELECT
        run_mode,
        selected_module2_run_id,
        selected_comparison_group_id,

        UPPER(
            COALESCE(
                NULLIF(BTRIM(section13_execution_mode), ''),
                'AUTO'
            )
        ) AS section13_execution_mode
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE
),

active_comparison AS (
    SELECT
        run_mode,
        selected_module2_run_id,
        requested_comparison_group_id,
        effective_comparison_group_id,
        explicit_match_count,
        challenger_match_count,
        baseline_match_count,
        active_comparison_selection_status
    FROM tmp_m2_active_comparison_selection
)

SELECT
    s.run_mode,
    s.selected_module2_run_id,
    s.selected_comparison_group_id,
    s.section13_execution_mode,

    a.requested_comparison_group_id,
    a.effective_comparison_group_id,

    a.explicit_match_count,
    a.challenger_match_count,
    a.baseline_match_count,
    a.active_comparison_selection_status,

    CASE
        WHEN s.section13_execution_mode = 'SKIP'
            THEN FALSE

        WHEN s.section13_execution_mode = 'REQUIRE'
            THEN TRUE

        WHEN s.section13_execution_mode = 'AUTO'
         AND a.effective_comparison_group_id IS NOT NULL
            THEN TRUE

        ELSE FALSE
    END AS section13_should_run_flag,

    CASE
        WHEN s.section13_execution_mode = 'SKIP'
            THEN 'SECTION_13_SKIPPED_BY_OPERATOR'

        WHEN s.section13_execution_mode = 'REQUIRE'
         AND a.effective_comparison_group_id IS NULL
            THEN 'SECTION_13_REQUIRED_BUT_NO_EFFECTIVE_COMPARISON_SELECTED'

        WHEN s.section13_execution_mode = 'REQUIRE'
         AND a.effective_comparison_group_id IS NOT NULL
            THEN 'SECTION_13_REQUIRED_AND_COMPARISON_SELECTED'

        WHEN s.section13_execution_mode = 'AUTO'
         AND a.effective_comparison_group_id IS NOT NULL
            THEN 'SECTION_13_AUTO_RUN_COMPARISON_SELECTED'

        WHEN s.section13_execution_mode = 'AUTO'
         AND a.effective_comparison_group_id IS NULL
            THEN 'SECTION_13_AUTO_SKIPPED_NO_UNIQUE_COMPARISON'

        ELSE 'SECTION_13_REVIEW_INVALID_EXECUTION_MODE'
    END AS section13_execution_status

FROM selector s

LEFT JOIN active_comparison a
    ON a.run_mode = s.run_mode
   AND a.selected_module2_run_id IS NOT DISTINCT FROM s.selected_module2_run_id;
```

Add this diagnostic near **Section 2.11**:

```sql
/*-----------------------------------------------------------------------------------------------
2.11H Section 13 execution control diagnostic.

Purpose:
    Show whether Section 13 will run, skip, or require comparison for this selected run.

Expected for standard campaign reruns:
    section13_execution_mode = AUTO

Interpretation:
    section13_should_run_flag = TRUE:
        Section 13 will run real matched comparison.

    section13_should_run_flag = FALSE:
        Section 13 will create NOT_APPLICABLE comparison context and continue.

    section13_execution_mode = REQUIRE:
        Section 13 will fail if no active comparison exists.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_13_EXECUTION_CONTROL' AS diagnostic_name,
    *
FROM tmp_m2_section13_execution_control;
```

---

## Patch 4 — replace Section 13.0A with skip-aware logic

Replace current **Section 13.0A** with this:

```sql
/*-----------------------------------------------------------------------------------------------
13.0A Persistent comparison registry existence and active-selection gatekeeper.

Business purpose:
    Decide whether Section 13 should run real matched comparison or create NOT_APPLICABLE comparison
    context for the current run.

Why this is skip-aware:
    Some campaign runs are valid standalone/reference runs and do not have a unique active comparison.

    Section 13 should not fail those runs when section13_execution_mode = AUTO.

Execution modes:
    AUTO:
        Run only when one active comparison exists.
        Otherwise continue with NOT_APPLICABLE comparison context.

    SKIP:
        Always continue with NOT_APPLICABLE comparison context.

    REQUIRE:
        Require exactly one active comparison and fail if missing or ambiguous.
-----------------------------------------------------------------------------------------------*/

DO $$
DECLARE
    ctl RECORD;

    v_registry_exists BOOLEAN;
    v_active_comparison_count BIGINT;
    v_required_registry_column_gap_count BIGINT;
    v_placeholder_count BIGINT;
    v_same_strategy_count BIGINT;
BEGIN
    /***********************************************************************************************
    Ensure a Section 13 execution control exists.

    Preferred source:
        tmp_m2_section13_execution_control from Section 2.

    Fallback:
        AUTO mode based on current active comparison count.
    ***********************************************************************************************/
    IF COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_section13_execution_control'),
        TO_REGCLASS('tmp_m2_section13_execution_control')
    ) IS NULL THEN

        CREATE TEMP TABLE tmp_m2_section13_execution_control
        ON COMMIT PRESERVE ROWS
        AS
        WITH active_count AS (
            SELECT
                COUNT(*) AS active_comparison_count
            FROM credit_decisioning_sim.strategy_comparison_campaign_registry
            WHERE active_comparison_flag IS TRUE
              AND registry_active_flag IS TRUE
        )
        SELECT
            NULL::TEXT AS run_mode,
            NULL::TEXT AS selected_module2_run_id,
            NULL::TEXT AS selected_comparison_group_id,
            'AUTO'::TEXT AS section13_execution_mode,

            NULL::TEXT AS requested_comparison_group_id,
            NULL::TEXT AS effective_comparison_group_id,

            NULL::BIGINT AS explicit_match_count,
            NULL::BIGINT AS challenger_match_count,
            NULL::BIGINT AS baseline_match_count,

            CASE
                WHEN active_comparison_count = 1
                    THEN 'AUTO_SELECTED_FROM_EXISTING_ACTIVE_COMPARISON'
                ELSE 'AUTO_NO_UNIQUE_ACTIVE_COMPARISON'
            END AS active_comparison_selection_status,

            CASE
                WHEN active_comparison_count = 1
                    THEN TRUE
                ELSE FALSE
            END AS section13_should_run_flag,

            CASE
                WHEN active_comparison_count = 1
                    THEN 'SECTION_13_AUTO_RUN_EXISTING_ACTIVE_COMPARISON'
                ELSE 'SECTION_13_AUTO_SKIPPED_NO_UNIQUE_COMPARISON'
            END AS section13_execution_status

        FROM active_count;
    END IF;


    SELECT *
    INTO ctl
    FROM tmp_m2_section13_execution_control
    LIMIT 1;

    IF ctl.section13_execution_mode NOT IN ('AUTO', 'SKIP', 'REQUIRE') THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: invalid section13_execution_mode %. Valid values are AUTO, SKIP, REQUIRE.',
            ctl.section13_execution_mode;
    END IF;


    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_comparison_campaign_registry') IS NOT NULL
    INTO v_registry_exists;

    IF v_registry_exists IS DISTINCT FROM TRUE THEN
        IF ctl.section13_execution_mode IN ('AUTO', 'SKIP')
           AND ctl.section13_should_run_flag IS DISTINCT FROM TRUE THEN
            RETURN;
        END IF;

        RAISE EXCEPTION
            'Module 2 Section 13 failure: strategy_comparison_campaign_registry does not exist. Run Section 2 registry setup before Section 13.';
    END IF;


    /***********************************************************************************************
    Required registry-column check.

    Only needed when real comparison is expected.
    ***********************************************************************************************/
    IF ctl.section13_should_run_flag IS DISTINCT FROM TRUE THEN
        RETURN;
    END IF;


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


    SELECT COUNT(*)
    INTO v_active_comparison_count
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE active_comparison_flag IS TRUE
      AND registry_active_flag IS TRUE;

    IF v_active_comparison_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: section13_execution_mode = %, but expected exactly one active comparison registry row, found %.',
            ctl.section13_execution_mode,
            v_active_comparison_count;
    END IF;


    SELECT COUNT(*)
    INTO v_placeholder_count
    FROM credit_decisioning_sim.strategy_comparison_campaign_registry
    WHERE active_comparison_flag IS TRUE
      AND registry_active_flag IS TRUE
      AND (
             comparison_group_id ILIKE '%PLACEHOLDER%'
          OR comparison_set_name ILIKE '%PLACEHOLDER%'
          OR baseline_module2_run_id ILIKE '%PLACEHOLDER%'
          OR challenger_module2_run_id ILIKE '%PLACEHOLDER%'
          OR baseline_strategy_set_name ILIKE '%PLACEHOLDER%'
          OR baseline_strategy_name ILIKE '%PLACEHOLDER%'
          OR baseline_strategy_version ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_set_name ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_name ILIKE '%PLACEHOLDER%'
          OR challenger_strategy_version ILIKE '%PLACEHOLDER%'
      );

    IF v_placeholder_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 13 failure: active comparison registry row contains placeholder comparison or strategy identifiers.';
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
```

---

## Patch 5 — replace Section 13.0B so skipped runs still produce safe context

Replace current **Section 13.0B** with this:

```sql
/*-----------------------------------------------------------------------------------------------
13.0B Canonical active comparison parameter table.

Business purpose:
    Materialize the active comparison when Section 13 should run real comparison.

    When Section 13 is skipped by AUTO or SKIP mode, create a one-row NOT_APPLICABLE comparison
    context instead of failing the run.

Why this matters:
    Downstream Section 13, Section 14, and Section 16 references can safely read the same temporary
    table name regardless of whether matched comparison applies to the current run.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;

CREATE TEMP TABLE tmp_m2_strategy_comparison_params
ON COMMIT PRESERVE ROWS
AS
WITH ctl AS (
    SELECT *
    FROM tmp_m2_section13_execution_control
    LIMIT 1
),

real_comparison AS (
    SELECT
        c.comparison_group_id,
        c.comparison_set_name,

        c.showcase_id,
        c.showcase_name,

        c.baseline_module2_run_id,
        c.challenger_module2_run_id,

        c.baseline_strategy_set_name,
        c.baseline_strategy_name,
        c.baseline_strategy_version,

        c.challenger_strategy_set_name,
        c.challenger_strategy_name,
        c.challenger_strategy_version,

        c.module1_scenario_set_name,
        c.module1_scenario_name,
        c.population_id,

        c.expected_comparison_storyline,
        c.primary_metric_focus,

        c.active_comparison_flag,
        c.registry_active_flag,
        c.registry_created_ts,
        c.registry_updated_ts

    FROM credit_decisioning_sim.strategy_comparison_campaign_registry c

    CROSS JOIN ctl

    WHERE ctl.section13_should_run_flag IS TRUE
      AND c.active_comparison_flag IS TRUE
      AND c.registry_active_flag IS TRUE
),

not_applicable_comparison AS (
    SELECT
        NULL::TEXT AS comparison_group_id,

        ctl.section13_execution_status::TEXT AS comparison_set_name,

        NULL::TEXT AS showcase_id,
        NULL::TEXT AS showcase_name,

        NULL::TEXT AS baseline_module2_run_id,
        NULL::TEXT AS challenger_module2_run_id,

        NULL::TEXT AS baseline_strategy_set_name,
        NULL::TEXT AS baseline_strategy_name,
        NULL::TEXT AS baseline_strategy_version,

        NULL::TEXT AS challenger_strategy_set_name,
        NULL::TEXT AS challenger_strategy_name,
        NULL::TEXT AS challenger_strategy_version,

        NULL::TEXT AS module1_scenario_set_name,
        NULL::TEXT AS module1_scenario_name,
        NULL::TEXT AS population_id,

        'Section 13 matched comparison was not applicable for this run.'::TEXT
            AS expected_comparison_storyline,

        'NOT_APPLICABLE'::TEXT AS primary_metric_focus,

        FALSE::BOOLEAN AS active_comparison_flag,
        TRUE::BOOLEAN AS registry_active_flag,
        NULL::TIMESTAMP AS registry_created_ts,
        NULL::TIMESTAMP AS registry_updated_ts

    FROM ctl

    WHERE ctl.section13_should_run_flag IS DISTINCT FROM TRUE
)

SELECT *
FROM real_comparison

UNION ALL

SELECT *
FROM not_applicable_comparison;
```

---

## What this changes operationally

After this patch, your standard campaign rerun procedure becomes:

```text
For each M2-01 through M2-36:
    set selected_module2_run_id = 'M2-##'
    keep selected_comparison_group_id = NULL
    keep section13_execution_mode = 'AUTO'
    run Sections 1–16.8 straight through
```

For M2-14, the control table should show:

```text
section13_execution_mode = AUTO
section13_should_run_flag = false
section13_execution_status = SECTION_13_AUTO_SKIPPED_NO_UNIQUE_COMPARISON
```

That is exactly what we want: M2-14 is still archived, validated, and captured into evidence, but matched comparison is treated as not applicable for that run.

For a custom run:

```sql
section13_execution_mode = 'SKIP'
```

means “do not attempt comparison.”

```sql
section13_execution_mode = 'REQUIRE'
```

means “I intentionally want comparison evidence, so fail if comparison is not properly selected.”

That gives you a clean job aid and avoids teaching users which M2 rows to manually skip.
<!-- END_MESSAGE C038-M01859 -->


---

<a id="c038-m01860"></a>

### C038-M01860

**Andrew** · 2026-05-13T13:04:25.995000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01860 -->
do I place SECTION 2.10X — SECTION 13 EXECUTION CONTROL between SECTION 2.10B and SECTION 2.10C? do we need to change the header for section 2 or the ending (see attached)?    header: /***************************************************************************************************
SECTION 2 — STRATEGY PROFILE, PRODUCT POLICY PROFILE, CAMPAIGN REGISTRY, AND RUN SELECTOR FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize the governed configuration layer for Module 2.

    Section 2 answers:

        "Which Module 2 run, strategy profile, product-policy profile, Module 1 source slice,
         archive behavior, registry IDs, and comparison IDs should this execution use?"

DESIGN CHANGE IN THIS VERSION:
    Section 2 is now profile-driven.

    Instead of manually editing 20+ numeric thresholds for each formal campaign run, the operator
    selects a governed Module 2 run ID:

        selected_module2_run_id = 'M2-01'

    The SQL then derives:
        Module 1 scenario set,
        Module 1 scenario name,
        population,
        strategy profile,
        product-policy profile,
        strategy name,
        strategy version,
        module2_run_id,
        strategy_run_id,
        active strategy parameter card,
        active product-policy parameter card,
        campaign registry row,
        and comparison registry rows.

WHY THIS MATTERS:
    The prior manual configuration pattern was powerful but operationally fragile.

    It was too easy to:
        carry stale commentary,
        type a wrong threshold,
        run the wrong strategy name,
        forget a registry update,
        or mismatch strategy and product-policy posture.

    The profile catalog keeps the engine flexible while making formal campaign runs safer.

BASELINE DEFAULT:
    BASELINE_STRATEGY is the default reference strategy.

CAMPAIGN CHALLENGER EXAMPLES:
    TIGHTER_SYNTHETIC_RISK_STRATEGY
    GROWTH_ORIENTED_STRATEGY
    TIGHTER_AFFORDABILITY_STRATEGY
    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
    MANUAL_REVIEW_REDUCTION_STRATEGY

CUSTOM USER FLEXIBILITY:
    Custom experimentation remains supported.

    Users who want to create their own strategy posture can use:
        run_mode = 'CUSTOM'

    and then edit the custom strategy and product-policy profile rows.

    Custom runs should be clearly labeled and should not be treated as formal campaign validation
    evidence unless the user intentionally adds governed registry support.

DOWNSTREAM CONTRACT PRESERVED:
    Later sections continue to consume:

        tmp_module2_strategy_params
        tmp_module2_product_policy_params

    This redesign changes how those tables are generated.
    It does not require later sections to read new profile-catalog tables directly.

SQL TEACHING POINT:
    This section demonstrates a common controlled-simulation pattern:

        operator selector
        → executable profile catalog
        → executable campaign catalog
        → generated active parameter card
        → fail-fast validation
        → downstream deterministic execution

***************************************************************************************************/
     ending: /*-----------------------------------------------------------------------------------------------
2.11H Section 13 execution control diagnostic.

Purpose:
    Show whether Section 13 will run, skip, or require comparison for this selected run.

Expected for standard campaign reruns:
    section13_execution_mode = AUTO

Interpretation:
    section13_should_run_flag = TRUE:
        Section 13 will run real matched comparison.

    section13_should_run_flag = FALSE:
        Section 13 will create NOT_APPLICABLE comparison context and continue.

    section13_execution_mode = REQUIRE:
        Section 13 will fail if no active comparison exists.
-----------------------------------------------------------------------------------------------*/

SELECT
    'SECTION_13_EXECUTION_CONTROL' AS diagnostic_name,
    *
FROM tmp_m2_section13_execution_control;
<!-- END_MESSAGE C038-M01860 -->


---

<a id="c038-m01863"></a>

### C038-M01863

**ChatGPT** · 2026-05-13T13:08:00.259740-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01863 -->
According to a document from 2026-05-13, **do not place the new Section 13 execution control between 2.10B and 2.10C**. Place it **after the existing Section 2.10 comparison-selection / registry-upsert / active-comparison-index logic is complete, and immediately before Section 2.11 review outputs**. The current Section 2.10 flow separates comparison catalog, active-comparison selection logic, persistent registry upsert, and review diagnostics, and Section 2.11 is where setup review outputs begin. fileciteturn326file7 fileciteturn326file0

## Placement recommendation

Use this order:

```text
2.10A  Materialize the formal comparison plan
2.10B  Resolve active comparison selection
2.10C  Seed / update comparison registry and active comparison flag
2.10D  Optional one-active-comparison governance index
2.10E  Section 13 execution control        <-- place the new block here
2.11   Section 2 review outputs
```

So I would **rename `SECTION 2.10X` to `SECTION 2.10E`**. “2.10X” was a placeholder. Since your current code already has **2.10D Optional one-active-comparison governance index**, the clean final numbering is:

```sql
SECTION 2.10E — SECTION 13 EXECUTION CONTROL
```

This is the best location because the new control depends on `tmp_m2_active_comparison_selection`, and it should be created before your new `2.11H Section 13 execution control diagnostic`. Section 2.11 already contains diagnostics for the active comparison selection and active comparison registry row, so adding 2.11H after 2.11G is the right review-output placement. fileciteturn325file7

## Section 2 header

Yes, I would make a **small header update**. Your current Section 2 header asks which run, strategy profile, product-policy profile, Module 1 source slice, archive behavior, registry IDs, and comparison IDs the execution should use. That is still correct, but now Section 2 also controls whether Section 13 should run, auto-skip, or be required. fileciteturn324file13

Replace this sentence in the header question:

```sql
        "Which Module 2 run, strategy profile, product-policy profile, Module 1 source slice,
         archive behavior, registry IDs, and comparison IDs should this execution use?"
```

with:

```sql
        "Which Module 2 run, strategy profile, product-policy profile, Module 1 source slice,
         archive behavior, registry IDs, comparison IDs, and Section 13 comparison-execution mode
         should this execution use?"
```

Then in the “SQL then derives” list, replace:

```sql
        campaign registry row,
        and comparison registry rows.
```

with:

```sql
        campaign registry row,
        comparison registry rows,
        active comparison selection,
        and Section 13 execution behavior.
```

I would also add one short block after **AUTO COMPARISON SELECTION** in Section 2.1:

```sql
SECTION 13 EXECUTION MODE:
    section13_execution_mode controls whether matched comparison should run.

    AUTO:
        Run Section 13 only when Section 2 resolves a unique active comparison.
        If no unique comparison exists, Section 13 creates NOT_APPLICABLE context and continues.

    SKIP:
        Always skip real matched comparison for this run.

    REQUIRE:
        Require exactly one active comparison and fail if comparison selection is missing or ambiguous.
```

That makes the user-facing run procedure clearer without overloading the main Section 2 header.

## Section 2 ending

Yes, update the ending lightly. Add one line to the “If execution reaches this point” list:

```sql
    10. Section 13 execution behavior has been resolved as AUTO, SKIP, or REQUIRE.
```

Then update the “Next section” sentence from:

```sql
Next section:
    Section 3 should run fail-fast strategy, source-selection, product-policy, archive-control, and
    registry gatekeepers before downstream strategy logic is built.
```

to:

```sql
Next section:
    Section 3 should run fail-fast strategy, source-selection, product-policy, archive-control,
    registry, and Section 13 execution-control gatekeepers before downstream strategy logic is built.
```

## Section 1 and Section 2.0 resets

Also add this drop to both reset areas:

```sql
DROP TABLE IF EXISTS tmp_m2_section13_execution_control;
```

In **Section 1.2**, put it near the other selector/comparison temp objects:

```sql
DROP TABLE IF EXISTS tmp_m2_comparison_plan;
DROP TABLE IF EXISTS tmp_m2_active_comparison_selection;
DROP TABLE IF EXISTS tmp_m2_section13_execution_control;
```

And in **Section 2.0**, use the same pattern:

```sql
/* Comparison-plan helpers used to auto-select and control Section 13 comparison execution. */
DROP TABLE IF EXISTS tmp_m2_comparison_plan;
DROP TABLE IF EXISTS tmp_m2_active_comparison_selection;
DROP TABLE IF EXISTS tmp_m2_section13_execution_control;
```

## Your 2.11H diagnostic

Your proposed **2.11H** diagnostic is good. I would keep it exactly where you placed it: **after 2.11G Active comparison registry row**.

I would only update this sentence:

```sql
    section13_should_run_flag = FALSE:
        Section 13 will create NOT_APPLICABLE comparison context and continue.
```

to:

```sql
    section13_should_run_flag = FALSE:
        Section 13 will create NOT_APPLICABLE comparison context and continue when Section 13 is
        reached.
```

That makes clear the behavior occurs inside Section 13, not inside Section 2.

## Bottom line

Use:

```text
2.10E — Section 13 Execution Control
```

Place it **after 2.10D and before Section 2.11**.

Then keep your diagnostic as:

```text
2.11H — Section 13 execution control diagnostic
```

And make only small header / ending edits so Section 2 explicitly teaches that the operator now controls both the selected campaign run and the Section 13 matched-comparison execution behavior.
<!-- END_MESSAGE C038-M01863 -->


---

<a id="c038-m01865"></a>

### C038-M01865

**Andrew** · 2026-05-13T13:34:49.044000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01865 -->
header: after auto comparison selection is 'why auto-selection helps' and 'when to set selected_comparison_group_id explicitly' where should this new section 13 execution mode comment sit exactly?
<!-- END_MESSAGE C038-M01865 -->


---

<a id="c038-m01868"></a>

### C038-M01868

**ChatGPT** · 2026-05-13T13:39:19.833059-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01868 -->
Place the new **SECTION 13 EXECUTION MODE** comment **immediately after**:

```sql
WHEN TO SET selected_comparison_group_id EXPLICITLY:
```

and **immediately before**:

```sql
RUN MODE OPTIONS:
```

Do **not** place it between `AUTO COMPARISON SELECTION`, `WHY AUTO-SELECTION HELPS`, and `WHEN TO SET selected_comparison_group_id EXPLICITLY`. Those three blocks are one logical explanation: first how comparison auto-selection works, then why it helps, then when the user should override it. The new Section 13 execution mode comment should come **after** that explanation because it answers the next operational question: “Now that comparison selection has or has not resolved, should Section 13 run, skip, or require a comparison?” Your current Section 2.1 flow goes from `AUTO COMPARISON SELECTION` to `WHY AUTO-SELECTION HELPS` to `WHEN TO SET selected_comparison_group_id EXPLICITLY`, and then into `RUN MODE OPTIONS`, so this new block belongs right before `RUN MODE OPTIONS`. fileciteturn327file10

Use this exact placement:

```sql
WHEN TO SET selected_comparison_group_id EXPLICITLY:
    Set selected_comparison_group_id when the selected run is a baseline used in multiple comparisons.

    Example:
        M2-16 is the baseline for both:
            CG10 — near-prime baseline vs tighter risk
            CG11 — near-prime baseline vs counteroffer-first

        If selected_module2_run_id = 'M2-16', set selected_comparison_group_id to either:
            'CG10'
            or
            'CG11'

SECTION 13 EXECUTION MODE:
    section13_execution_mode controls whether Section 13 should run real matched comparison, skip
    matched comparison, or require matched comparison.

    AUTO:
        Run Section 13 only when Section 2 resolves a unique active comparison.

        If no unique comparison exists, Section 13 creates NOT_APPLICABLE comparison context and
        continues.

        Recommended for standard full-campaign reruns.

    SKIP:
        Do not run real matched comparison for this run.

        Use this for custom or ad hoc runs where comparison evidence is intentionally not needed.

    REQUIRE:
        Require exactly one active comparison.

        Use this when the operator intentionally wants Section 13 comparison evidence and wants the
        script to fail if comparison selection is missing or ambiguous.

RUN MODE OPTIONS:
    STANDARD_CAMPAIGN:
        Use the formal 36-run campaign catalog.

    CUSTOM:
        Use only for exploratory runs outside the formal campaign roadmap.
```

Separately, in the actual `CREATE TEMP TABLE tmp_m2_operator_run_selector` definition, put the new column **immediately after** `selected_comparison_group_id`, because it is logically paired with comparison behavior:

```sql
selected_comparison_group_id        TEXT,
section13_execution_mode            TEXT NOT NULL DEFAULT 'AUTO',
```

That creates a clean operator flow:

```text
selected_module2_run_id
→ selected_comparison_group_id
→ section13_execution_mode
→ run_mode / campaign behavior
```

Then the executable **2.10E — Section 13 Execution Control** block should still sit later, after active comparison selection is built and before Section 2.11 diagnostics.
<!-- END_MESSAGE C038-M01868 -->


---

<a id="c038-m01870"></a>

### C038-M01870

**Andrew** · 2026-05-13T13:47:45.672000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01870 -->
ok, here is the full code for review after those changes:
<!-- END_MESSAGE C038-M01870 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(4).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01889"></a>

### C038-M01889

**ChatGPT** · 2026-05-13T13:58:49.067141-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01889 -->
According to a document from 2026-05-13, the latest uploaded file is structurally strong, and the new Section 13 execution-control framework is mostly in place. Section 2 now has `section13_execution_mode`, the selector insert includes `section13_execution_mode = 'AUTO'`, Section 2.10E builds `tmp_m2_section13_execution_control`, and Section 13.0B creates a one-row NOT_APPLICABLE comparison context when Section 13 is skipped. fileciteturn333file3 fileciteturn330file2 fileciteturn332file0

## Verdict before execution

**Do one small Section 13.2 patch before continuing the full rerun.**

The file is very close, but there is one remaining consistency issue: Section 13.0B now correctly creates NOT_APPLICABLE comparison context for runs like M2-14, but Section 13.2 still interprets that null comparison as “baseline and challenger archive missing,” producing a `NOT_READY_...` readiness status rather than a `NOT_APPLICABLE_...` status. Section 14.19 maps readiness values beginning with `NOT_APPLICABLE` to `NOT_APPLICABLE`, but everything else becomes `REVIEW`; so without this patch, M2-14 should run without failing, but it may create unnecessary validation REVIEW noise for matched-comparison readiness. fileciteturn332file16 fileciteturn332file3

## Static checks

I reviewed the uploaded file directly. The structure is sound:

| Check | Result |
|---|---:|
| Formal section headings | no duplicate headings found |
| Block comments | balanced |
| Executable `DO $$ ... END $$;` blocks after removing comments | balanced |
| Parentheses after removing comments / quoted strings | balanced |
| Section 2.10E | present |
| Section 13.0A / 13.0B skip-aware framework | present |
| Section 17.20 dynamic acceptance rollup | present |
| Old Section 17 hardcoded `36::BIGINT`, `17::BIGINT`, `1800000`, `expected_validation_rows_per_run` | not present in current Section 17 |

Section 17 is now dynamically framed and does not hardcode campaign run count, comparison group count, archive rows per slice, total archive rows, validation evidence row count, product-guardrail campaign run count, or product-guardrail audit row count. fileciteturn330file1

## Required small patch: Section 13.2 readiness status

In **Section 13.2**, find the `CASE ... END AS readiness_status` block. Add the first `WHEN` shown below before the existing same-strategy / archive-missing checks.

### Replace the current readiness `CASE` with this

```sql
    CASE
        WHEN p.active_comparison_flag IS DISTINCT FROM TRUE
          OR p.comparison_group_id IS NULL
            THEN 'NOT_APPLICABLE_SECTION_13_SKIPPED_NO_ACTIVE_COMPARISON'

        WHEN (
            p.baseline_strategy_set_name = p.challenger_strategy_set_name
            AND p.baseline_strategy_name = p.challenger_strategy_name
            AND p.baseline_strategy_version = p.challenger_strategy_version
        )
            THEN 'NOT_READY_SAME_STRATEGY_SELECTED'

        WHEN bc.baseline_archived_row_count = 0
         AND cc.challenger_archived_row_count = 0
            THEN 'NOT_READY_BASELINE_AND_CHALLENGER_ARCHIVE_MISSING'

        WHEN bc.baseline_archived_row_count = 0
            THEN 'NOT_READY_BASELINE_ARCHIVE_MISSING'

        WHEN cc.challenger_archived_row_count = 0
            THEN 'NOT_READY_CHALLENGER_ARCHIVE_MISSING'

        WHEN bc.baseline_duplicate_application_row_count > 0
          OR cc.challenger_duplicate_application_row_count > 0
            THEN 'NOT_READY_DUPLICATE_APPLICATION_ID_IN_ARCHIVE_SLICE'

        WHEN bc.baseline_archived_row_count <> bc.baseline_distinct_application_id_count
          OR cc.challenger_archived_row_count <> cc.challenger_distinct_application_id_count
            THEN 'NOT_READY_ARCHIVE_SLICE_NOT_UNIQUE_AT_APPLICATION_ID'

        WHEN bc.baseline_distinct_application_id_count <> cc.challenger_distinct_application_id_count
            THEN 'NOT_READY_BASELINE_CHALLENGER_ROW_COUNT_MISMATCH'

        WHEN ao.matched_application_id_count <> bc.baseline_distinct_application_id_count
          OR ao.matched_application_id_count <> cc.challenger_distinct_application_id_count
          OR ao.baseline_only_application_id_count > 0
          OR ao.challenger_only_application_id_count > 0
            THEN 'NOT_READY_INCOMPLETE_APPLICATION_ID_OVERLAP'

        ELSE 'READY_FOR_MATCHED_COMPARISON'
    END AS readiness_status,
```

That keeps the Section 13 auto-skip behavior consistent all the way through Section 14 evidence capture.

## Comment-only cleanup I would defer until after runtime

These are not execution blockers:

1. Add `tmp_m2_section13_execution_control` to the Section 0.18 temporary helper list.
2. Update the Section 2.11F note that still says “if `effective_comparison_group_id` is NULL, Section 13 will not have an active comparison unless...” to the newer behavior: Section 13 will create NOT_APPLICABLE context when `section13_execution_mode = 'AUTO'`.
3. Update the Section 13.0 header’s SQL purpose lines that still imply Section 13 always confirms exactly one active comparison. The implementation is now skip-aware.

## Current selected run

Your uploaded file currently has:

```sql
selected_module2_run_id = 'M2-14'
selected_comparison_group_id = null
section13_execution_mode = 'AUTO'
```

That is correct for resuming M2-14. fileciteturn333file3

After the small Section 13.2 patch, rerun M2-14 from **Section 1** and run straight through **Section 16.8**. Then continue the campaign with M2-15 onward using the same `AUTO` setting.
<!-- END_MESSAGE C038-M01889 -->


---

<a id="c038-m01891"></a>

### C038-M01891

**Andrew** · 2026-05-13T14:13:29.501000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01891 -->
for your reference, here is the updated full code after clearing up the readiness_status case when.  the execution of M2-14 went smoothly.
<!-- END_MESSAGE C038-M01891 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(5).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01893"></a>

### C038-M01893

**ChatGPT** · 2026-05-13T14:16:49.674218-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01893 -->
Great — M2-14 running smoothly is the key confirmation we needed.

That validates the new Section 13 behavior: when `section13_execution_mode = 'AUTO'` and the selected run has no unique active comparison, Section 13 can now produce safe `NOT_APPLICABLE` comparison context instead of hard-failing. That means the standard campaign job aid can stay simple: keep `section13_execution_mode = 'AUTO'`, update only `selected_module2_run_id`, and run straight through Sections 1–16.8 for each campaign run. fileciteturn331file0

For the remaining campaign rerun, I would continue from:

```text
M2-15
M2-16
...
M2-36
```

using:

```sql
run_mode = 'STANDARD_CAMPAIGN'
selected_comparison_group_id = NULL
section13_execution_mode = 'AUTO'
```

The only routine edit should be:

```sql
selected_module2_run_id = 'M2-##'
```

The important watch point now is not M2-14-style Section 13 failure. It is making sure each run reaches Section 16.8 cleanly and refreshes its archive/evidence slice. After M2-36, use the normal closing sequence:

```text
fresh Section 15
→ Section 16.9
→ Section 17
```

Target final Section 17.20 status remains:

```sql
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```
<!-- END_MESSAGE C038-M01893 -->


---

<a id="c038-m01895"></a>

### C038-M01895

**Andrew** · 2026-05-13T19:58:16.069000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01895 -->
while running M2-29, encountered this error: 
<!-- END_MESSAGE C038-M01895 -->


**Attachments in export:** `Pasted text(181).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01898"></a>

### C038-M01898

**ChatGPT** · 2026-05-13T20:03:23.127244-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01898 -->
According to a document from 2026-05-13, this M2-29 issue is **not a campaign parameter issue and not a data-result issue**. It is a **partial SQL execution / incomplete `DO $$` block submission**.

The error says PostgreSQL hit an **unterminated dollar quote**. The attached error text shows the submitted SQL ended inside the **Section 8 exposure-treatment gatekeeper** after this list of forbidden downstream fields:

```sql
'attname IN (
    ...
    'approved_payment_to_income_ratio',
    'approved_expected_loss_amount'
). Expected terminating $$
```

That means PostgreSQL saw a `DO $$` block start, but the submitted statement did **not** include the block’s closing `END $$;`. fileciteturn332file7 fileciteturn332file0

The intended Section 8 block should continue after that field list with:

```sql
      );

    IF v_forbidden_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: forbidden final decision, final exposure, or reason-code field(s) were created in exposure-treatment stage.';
    END IF;
END $$;
```

and then proceed into Section 8.4. The canonical Section 8 pattern does include the `END $$;` before Section 8.4. fileciteturn333file10

## What most likely happened

You likely executed a **partial statement or partial selected block** that stopped inside Section 8’s `DO $$` gatekeeper.

This can happen when the SQL client executes only the “current statement” and treats an internal semicolon inside a `DO $$ ... END $$;` block as the end of the statement, or when the selected SQL accidentally ends before the `END $$;`.

M2-29 is counteroffer-heavy, so it reaches this Section 8 logic prominently, but the failure itself is syntax/execution-selection, not M2-29 logic.

## What to do now

Do **not** patch business logic.

For M2-29:

1. Confirm your SQL editor has the full Section 8.3 gatekeeper through:

```sql
END $$;
```

2. Rerun M2-29 from **Section 1**.

3. Execute using one of these safer methods:
   - run the full script / full selected run block through Section 16.8, or
   - if running section-by-section, select the **entire** `DO $$ ... END $$;` block when executing a DO block.

Avoid executing only the “current statement” while your cursor is inside a `DO $$` block.

## Quick rule for the rest of the campaign

For M2-29 through M2-36, keep using:

```sql
selected_comparison_group_id = NULL
section13_execution_mode = 'AUTO'
```

and change only:

```sql
selected_module2_run_id = 'M2-##'
```

This specific error does **not** require clearing archive or evidence tables. Since it failed in Section 8 before latest-run materialization, archive persistence, and evidence capture, just rerun M2-29 cleanly from Section 1.
<!-- END_MESSAGE C038-M01898 -->


---

<a id="c038-m01900"></a>

### C038-M01900

**Andrew** · 2026-05-13T20:09:49.152000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01900 -->
this happened when I executed the code, not a partial code. it also ran just fine from M2-01 to M2-28.  i will try re-executing the full code, but i'd like you to go through section 8 in detail to see if there is something unique to M2-29 that would have triggered this that we missed.
<!-- END_MESSAGE C038-M01900 -->


---

<a id="c038-m01904"></a>

### C038-M01904

**ChatGPT** · 2026-05-13T20:13:41.900936-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01904 -->
According to a document from 2026-05-13, I do **not** see anything unique in **M2-29** that should be able to trigger an “unterminated dollar quote” from Section 8 business logic.

M2-29 is unique in the campaign because it uses:

```text
HIGH_BALANCE_APPETITE
COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
```

and it is paired in the comparison roadmap as:

```text
CG15 — M2-28 vs M2-29
```

So yes, M2-29 is expected to drive more counteroffer / exposure-treatment activity than many earlier baseline runs. But that changes **row counts and feasibility outcomes**, not the SQL parser’s ability to find `END $$;`. The campaign map confirms M2-29’s role as the counteroffer-first challenger on the high-balance-appetite scenario. fileciteturn335file0

## What I found in Section 8

Section 8 is static SQL. It does not generate dynamic SQL based on M2-29. The section design is:

```text
8.0 dependency preflight
8.1 drop/rebuild Section 8 staging object
8.2 create tmp_m2_stage_5_exposure_treatment
8.3 local fail-fast gatekeeper in a DO $$ block
8.4 diagnostic SELECT outputs
```

The Section 8.2 CTE chain is deterministic: it preserves Section 7 output, calculates counteroffer components, rounds feasible counteroffer exposure, tests payment/PTI/EL, evaluates pass/fail, assigns preliminary approved exposure fields, assigns approved affordability and economics fields, and finally assigns `exposure_treatment_status` / `exposure_treatment_path`. fileciteturn336file1

The specific error location is in Section 8.3’s **forbidden final-field gatekeeper**. That gatekeeper checks that Section 8 has not prematurely created downstream fields such as final `decision_outcome`, final flags, simulated reason-code fields, final `approved_amount`, final `approved_payment_to_income_ratio`, or final `approved_expected_loss_amount`. The canonical Section 8.3 block continues after that forbidden-field list with the `IF v_forbidden_column_count > 0 THEN ... END IF; END $$;` close, and then proceeds into Section 8.4. fileciteturn335file1

## Why M2-29 should not cause this parser error

A data-dependent Section 8 problem would look like one of these:

```text
Module 2 Section 8 failure: row count changed...
Module 2 Section 8 failure: application_id uniqueness...
Module 2 Section 8 failure: ... required exposure-treatment fields...
Module 2 Section 8 failure: ... feasible preliminary COUNTEROFFER...
Module 2 Section 8 failure: ... infeasible preliminary COUNTEROFFER...
```

Those would be `P0001` exceptions raised by the Section 8 gatekeeper after the SQL parsed successfully.

Your error is different:

```text
SQL Error [42601]: Unterminated dollar quote
```

That is a **parse-time** error. PostgreSQL is saying it received a `DO $$` opener but did not receive the matching `END $$;` terminator in the submitted SQL text. The attached error text ends immediately after this list item:

```sql
'approved_expected_loss_amount'
      ). Expected terminating $$
```

That means the SQL submitted to PostgreSQL stopped before the rest of Section 8.3 was received. The code that should follow is the final `IF v_forbidden_column_count` block and `END $$;`. fileciteturn334file0

## My conclusion

This does **not** look like an M2-29 logic defect.

It looks like the SQL client submitted a truncated statement or truncated script around Section 8.3. M2-29 likely made you notice it because it was the first run where execution/submission failed at that point, but M2-29’s data cannot cause PostgreSQL to lose a dollar-quote terminator.

The strongest evidence is:

```text
The error text ends inside the Section 8.3 DO $$ block.
The canonical Section 8.3 block has the required END $$; after that same field list.
Section 8 does not use dynamic SQL or run-dependent dollar quoting.
```

## What I would do next

First, rerun M2-29 from Section 1 using the current full code file, not the error-text capture.

Second, before rerunning, do a quick text check in your editor around Section 8.3. Confirm this exact sequence exists after the forbidden field list:

```sql
      );

    IF v_forbidden_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: forbidden final decision, final exposure, or reason-code field(s) were created in exposure-treatment stage.';
    END IF;
END $$;
```

Then confirm Section 8.4 starts immediately afterward.

Third, continue with:

```sql
selected_module2_run_id = 'M2-29'
selected_comparison_group_id = NULL
section13_execution_mode = 'AUTO'
```

If it fails again with the same `42601 Unterminated dollar quote`, I would suspect one of these SQL-client execution issues rather than code logic:

```text
script text was not fully transmitted;
editor executed only part of the script;
client hit an internal statement-size / selection limit;
the active editor buffer is not the latest full file;
or the script was copied/pasted incompletely around Section 8.3.
```

## Optional safety check before rerun

You can paste and run this tiny client-side sanity query only if your SQL tool supports selecting text manually; it is not required, but it confirms Section 8.3’s terminator exists in the file you are about to execute:

```text
Search in editor:
    SECTION 8.3 — LOCAL FAIL-FAST CHECKS FOR EXPOSURE TREATMENT

Then search forward:
    END $$;

Then confirm the next major header is:
    SECTION 8.4 — LOCAL EXPOSURE-TREATMENT SANITY CHECKS
```

Bottom line: **M2-29 is expected to stress Section 8 counteroffer-feasibility logic, but it should not trigger an unterminated dollar quote. Re-execute the full current file; no Section 8 code patch is justified based on this error alone.**
<!-- END_MESSAGE C038-M01904 -->


---

<a id="c038-m01905"></a>

### C038-M01905

**Andrew** · 2026-05-13T20:23:08.444000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01905 -->
weirdly when i re-ran, it worked just fine.  both times i used alt-x to submit the full code.  i wonder why it did that in the earlier run.
<!-- END_MESSAGE C038-M01905 -->


---

<a id="c038-m01907"></a>

### C038-M01907

**ChatGPT** · 2026-05-13T20:25:27.221517-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01907 -->
That behavior strongly points to a **transient client submission issue**, not a Module 2 logic issue.

The earlier error was a PostgreSQL **parse-time** error: it said an “unterminated dollar quote” began at a specific character position and that PostgreSQL was expecting the closing `$$`. That means the database received a `DO $$` block opener but did not receive the matching `END $$;` / closing dollar quote in the SQL text it parsed. Your rerun succeeding with the same full code is the strongest evidence that the canonical SQL itself is syntactically valid. fileciteturn338file0

Most likely explanations:

1. **The SQL client submitted an incomplete buffer once.** Even when you press the same shortcut, clients can occasionally submit only the selected text, current statement, active editor fragment, or a stale internal buffer.

2. **There may have been an invisible active selection.** Many SQL tools execute the highlighted selection if anything is selected; otherwise they execute the full script/current statement. A partial selection ending inside a `DO $$` block would create exactly this error.

3. **The client’s SQL parser may have mis-split around a dollar-quoted block.** PostgreSQL itself understands `DO $$ ... END $$;`, but client-side “execute statement” logic sometimes tries to identify statement boundaries before sending text. If it misidentifies the boundary inside the block, the server receives an incomplete statement.

4. **The submitted text may have been truncated during send.** Less common, but possible with very large scripts, editor/session instability, or a momentary connection/client issue. The error position was far into the file, which fits a large-script submission problem. fileciteturn338file0

5. **The active editor tab may not have been the exact buffer you thought it was.** If one tab had an older/partial copy and another tab had the full code, the shortcut could have executed the active-but-not-obvious tab.

The important part: **M2-29 data could not cause an unterminated dollar quote.** M2-29 can affect rows, counteroffer counts, feasibility results, and validation statuses. It cannot make PostgreSQL lose a closing `$$`. A data-dependent issue would have shown up as a raised exception from a gatekeeper, not as a syntax parse error.

For the rest of the campaign, I would keep going. To reduce recurrence risk, before running each large full-code pass, make sure there is no highlighted text, save the editor buffer, and use the command that executes the whole script rather than “current statement.” If it happens again, rerun once before assuming a code issue. If it repeats at the exact same location twice, then treat it as a real client/script-boundary problem and run the file through a more deterministic method, such as a saved-file execution path.
<!-- END_MESSAGE C038-M01907 -->


---

<a id="c038-m01908"></a>

### C038-M01908

**Andrew** · 2026-05-13T21:41:37.467000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01908 -->
just kicked off M2-36.  almost done with the campaign refresh.  i'd like to discuss an M2-37 to test the custom, non-catalog flow of the code. can you think of an interesting custom M2-37 and the parameters to go with it that would enhance the campaign we are building.  something that goes along with our M1-M36 but that just barely didn't make the earlier cut.
<!-- END_MESSAGE C038-M01908 -->


---

<a id="c038-m01920"></a>

### C038-M01920

**ChatGPT** · 2026-05-13T21:47:42.124316-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01920 -->
According to a document from 2026-05-13, the cleanest **M2-37 custom-flow test** would be a **High-Balance Hybrid Counteroffer + Product Guardrail** run. It fills a real campaign gap: the formal campaign already tests `HIGH_BALANCE_APPETITE` with baseline and counteroffer-first strategy in M2-28 / M2-29, and it tests product guardrails in unsecured / revolving / LGD-stress contexts, but it does **not** test a custom hybrid of counteroffer-first exposure treatment plus unsecured/revolving guardrails under high-balance appetite. fileciteturn344file0

## Recommended M2-37 concept

**M2-37 — HIGH_BALANCE_HYBRID_COUNTEROFFER_GUARDRAIL_CUSTOM**

Business question:

> Can we preserve access under high requested-balance intensity while using reduced-exposure treatment plus tighter unsecured/revolving product caps to control approved exposure and approved Expected Loss?

This is a good custom-flow test because it combines concepts from several campaign runs without duplicating any one of them:

| Existing run | What it tested | M2-37 extension |
|---|---|---|
| `M2-28` | High-balance appetite baseline | Use as reference environment |
| `M2-29` | High-balance counteroffer-first | Add product guardrails |
| `M2-23` / `M2-26` | Product guardrails under unsecured/revolving mix | Move guardrails into high-balance exposure-intensity context |
| `M2-34` / `M2-36` | Product guardrails under LGD stress | Test guardrails against balance intensity instead of LGD severity |

The current code explicitly supports custom runs through `run_mode = 'CUSTOM'`, custom run IDs, custom Module 1 scenario fields, custom profile codes, and custom story labels; Section 2 then normalizes standard and custom modes into the canonical parameter tables used downstream. fileciteturn342file18 The compatibility map also has a custom strategy/product-policy pairing: `CUSTOM_USER_DEFINED_STRATEGY_PROFILE` with `CUSTOM_USER_DEFINED_PRODUCT_POLICY`, marked outside the formal campaign compatibility set. fileciteturn342file0

## When to run it

I would **finish the formal 36-run campaign first**, then run:

```text
fresh Section 15
→ Section 16.9
→ Section 17
```

and preserve the official 36-run acceptance result.

Then run **M2-37** as an exploratory custom test.

Reason: if M2-37 is archived before final Section 17, it may appear as an archive slice without an active campaign registry row. That is not necessarily wrong, but it adds noise while you are trying to confirm the formal campaign. The custom profile guidance itself says custom runs should be treated as exploratory unless registry support is deliberately added. fileciteturn343file1

## Section 2.1 operator selector for M2-37

Use `CUSTOM`, not `STANDARD_CAMPAIGN`.

Use `section13_execution_mode = 'SKIP'` for this first custom-flow test. The current Section 13 execution control supports `AUTO`, `SKIP`, and `REQUIRE`; `SKIP` is specifically useful for custom/ad hoc runs where comparison evidence is intentionally not needed. fileciteturn343file15

```sql
INSERT INTO tmp_m2_operator_run_selector (
    active_selector_flag,
    run_mode,
    selected_module2_run_id,
    selected_comparison_group_id,
    section13_execution_mode,

    custom_module1_run_id,
    custom_module2_run_id,
    custom_run_sequence_number,

    custom_module1_scenario_set_name,
    custom_module1_scenario_name,
    custom_population_id,

    custom_strategy_profile_code,
    custom_product_policy_profile_code,

    custom_showcase_id,
    custom_showcase_name,
    custom_comparison_group_id,
    custom_validation_evidence_group_id,

    custom_module1_parameter_family_changed,
    custom_module1_parameter_change_summary,

    custom_module2_strategy_family_changed,
    custom_module2_parameter_change_summary,

    custom_expected_storyline,
    custom_validation_summary_section_hint,
    custom_readme_storyline_label,
    custom_linkedin_post_sequence,
    custom_parameter_change_reason
)
VALUES (
    TRUE,
    'CUSTOM',
    NULL,
    NULL,
    'SKIP',

    'M1-14',
    'M2-37',
    37,

    'MODULE1_V2_EXPOSURE_INTENSITY_SET',
    'HIGH_BALANCE_APPETITE',
    'BASE_POPULATION_V1',

    'CUSTOM_USER_DEFINED_STRATEGY_PROFILE',
    'CUSTOM_USER_DEFINED_PRODUCT_POLICY',

    'SC05',
    'Exposure Intensity Sensitivity',
    'CG18_CUSTOM',
    'VE37_CUSTOM',

    'EXPOSURE_INTENSITY',
    'Uses the HIGH_BALANCE_APPETITE Module 1 source slice already used by M2-28 and M2-29.',

    'HYBRID_COUNTEROFFER_GUARDRAIL',
    'Combines counteroffer-first exposure treatment with tighter unsecured personal loan and revolving-line guardrails.',

    'Test whether a custom hybrid strategy can preserve access under high requested-balance intensity while controlling unsecured/revolving approved exposure and approved Expected Loss.',
    'Custom M2-37 — high-balance hybrid counteroffer / product-guardrail exploratory evidence',
    'High balance hybrid custom test',
    37,
    'Exploratory M2-37 custom-flow test: non-catalog hybrid of counteroffer-first exposure treatment and product-specific guardrails.'
);
```

Use the exact Module 1 scenario set name that your working M2-28 / M2-29 runs used. The current retrieved campaign snippets show `HIGH_BALANCE_APPETITE` under the exposure-intensity family, with M2-28 as baseline and M2-29 as counteroffer-first. fileciteturn344file0turn344file3

## Custom strategy-profile values

In the `CUSTOM_USER_DEFINED_STRATEGY_PROFILE` row, keep the custom identity, but change the values below.

The current custom strategy profile starts from baseline-like exploratory values and is intended to be edited deliberately for custom tests. fileciteturn343file1

| Parameter | Recommended M2-37 value | Why |
|---|---:|---|
| `strategy_name` | `CUSTOM_USER_DEFINED_STRATEGY` | Safest path; avoids breaking custom compatibility mapping |
| `strategy_set_name` | `MODULE2_CUSTOM_STRATEGY_SET` | Keeps exploratory run separate from formal campaign |
| `default_module1_input_source` | `ARCHIVE` | Use governed Module 1 scenario archive |
| `default_archive_run_flag` | `TRUE` | Archive M2-37 so Section 15 / evidence can see it |
| `default_strategy_archive_reset_mode` | `STRATEGY_SCENARIO_ONLY` | Safe rerun replacement for only M2-37’s slice |
| `approve_max_estimated_pd_proxy` | `0.080000` | Keep clean approval risk posture baseline-like |
| `counteroffer_max_estimated_pd_proxy` | `0.180000` | Slightly widen counteroffer band versus custom baseline `0.160000` |
| `review_max_estimated_pd_proxy` | `0.300000` | Preserve review boundary |
| `decline_min_estimated_pd_proxy` | `0.350000` | Preserve severe-risk decline boundary |
| `global_approve_max_pti` | `0.240000` | Slight affordability discipline |
| `global_review_max_pti` | `0.385000` | Slight affordability discipline |
| `global_decline_min_pti` | `0.535000` | Avoid over-declining solely from global PTI |
| `approve_max_dti` | `0.430000` | Keep DTI baseline-like |
| `review_max_dti` | `0.600000` | Keep DTI baseline-like |
| `decline_min_dti` | `0.600000` | Keep severe DTI convention |
| `borderline_threshold_buffer_pct` | `0.050000` | Keep diagnostics stable |
| `failed_counteroffer_resolution` | `MANUAL_REVIEW` | Preserve visibility into failed counteroffer feasibility |

The main conceptual change is widening the counteroffer band from `0.160000` to `0.180000` while tightening affordability modestly. That gives M2-37 enough difference from M2-29 without turning it into a broad growth strategy.

## Custom product-policy values

Keep `MORTGAGE`, `HELOC`, and `AUTO_LOAN` at custom baseline values.

Only modify:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

The custom product-policy profile is designed as a user-editable exploratory profile starting from baseline values. fileciteturn346file13 The existing product-guardrail audit already treats UPL and revolving line as the exact-value audited products, so those are the right products to target. fileciteturn345file9

| Product | Parameter | M2-37 value |
|---|---|---:|
| `UNSECURED_PERSONAL_LOAN` | `product_approve_max_pti` | `0.130000` |
|  | `product_review_max_pti` | `0.220000` |
|  | `product_decline_min_pti` | `0.320000` |
|  | `counteroffer_target_pti` | `0.110000` |
|  | `product_approve_max_requested_el` | `2500.00` |
|  | `product_review_max_requested_el` | `5000.00` |
|  | `product_decline_min_requested_el` | `8500.00` |
|  | `product_approved_el_cap` | `2000.00` |
|  | `product_min_approved_amount` | `1000.00` |
|  | `product_max_approved_amount` | `27500.00` |
|  | `counteroffer_allowed_flag` | `TRUE` |
|  | `manual_review_allowed_flag` | `TRUE` |
|  | `product_min_counteroffer_pct` | `0.400000` |
|  | `product_max_exposure_reduction_pct` | `0.600000` |
|  | `exposure_assignment_method` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` |
|  | `approved_amount_rounding_increment` | `500.00` |
| `REVOLVING_LINE` | `product_approve_max_pti` | `0.100000` |
|  | `product_review_max_pti` | `0.180000` |
|  | `product_decline_min_pti` | `0.280000` |
|  | `counteroffer_target_pti` | `0.080000` |
|  | `product_approve_max_requested_el` | `1500.00` |
|  | `product_review_max_requested_el` | `3200.00` |
|  | `product_decline_min_requested_el` | `6500.00` |
|  | `product_approved_el_cap` | `1400.00` |
|  | `product_min_approved_amount` | `1000.00` |
|  | `product_max_approved_amount` | `16000.00` |
|  | `counteroffer_allowed_flag` | `TRUE` |
|  | `manual_review_allowed_flag` | `TRUE` |
|  | `product_min_counteroffer_pct` | `0.400000` |
|  | `product_max_exposure_reduction_pct` | `0.600000` |
|  | `exposure_assignment_method` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` |
|  | `approved_amount_rounding_increment` | `500.00` |

Those values keep the UPL / revolving guardrail caps from the product-guardrail strategy, but make counteroffers slightly more flexible through `product_min_counteroffer_pct = 0.400000` and `product_max_exposure_reduction_pct = 0.600000`. That is what makes M2-37 a true hybrid rather than simply “product guardrail under high balance.”

## What I would expect M2-37 to show

Compared with **M2-28**, M2-37 should reduce total approved amount, reduce approved Expected Loss, and increase counteroffer behavior.

Compared with **M2-29**, M2-37 should look more product-disciplined: UPL and revolving line should carry lower approved exposure and approved Expected Loss than the pure counteroffer-first run, while still preserving more access than a harsh risk-tightening strategy.

The most useful post-run checks will be:

```text
Section 14.11 — counteroffer feasibility
Section 14.12 — manual-review unresolved population
Section 14.14 — reason-code coverage / concentration
Section 14.15 — simulated offer-exposure profile
Section 15 — frontier position and executive quadrant
Section 16.8 — evidence capture diagnostics
```

## Clearing / rerun behavior

No special clearing is needed. Run M2-37 from **Section 1** like the other runs.

Because this custom run uses a unique custom strategy set / strategy name / scenario key and `STRATEGY_SCENARIO_ONLY`, rerunning it should replace only the M2-37 custom archive slice if you set `default_archive_run_flag = TRUE`.

My recommendation: **run M2-37 after official 36-run acceptance**, archive it, capture Section 16 evidence, then use it as a “bonus custom strategy design” storyline rather than mixing it into the official 36-run campaign.
<!-- END_MESSAGE C038-M01920 -->


---

<a id="c038-m01922"></a>

### C038-M01922

**Andrew** · 2026-05-13T22:44:04.179000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01922 -->
please compare the results  from 17.1-17.10 from the first time we ran this campaign vs this updated run of the campaign (files ending in _FINAL).
<!-- END_MESSAGE C038-M01922 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.7_QA_post_campaign_audit_confirm_evidence_exists_for_all_campaign_runs(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.6_QA_post_campaign_audit_archive_slices_without_active_campaign_registry_row_expected_result_zero_rows(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.5_QA_post_campaign_audit_registry_runs_missing_or_mismatched_in_archive_expected_result_zero_rows(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.4_QA_post_campaign_audit_registry_to_archive_reconciliation(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.3_QA_post_campaign_audit_archive_grain_duplicate_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.2_QA_post_campaign_audit_archive_slice_detail(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.1_QA_post_campaign_audit_archive_campaign_inventory(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.10_QA_post_campaign_audit_validation_status_summary_by_campaign_run(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.9_QA_post_campaign_audit_full_archive_final_output_convention_checks(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.8_QA_post_campaign_audit_evidence_coverage_detail_by_run(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.4_QA_post_campaign_audit_registry_to_archive_reconciliation_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.5_QA_post_campaign_audit_registry_runs_missing_or_mismatched_in_archive_expected_result_zero_rows_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.6_QA_post_campaign_audit_archive_slices_without_active_campaign_registry_row_expected_result_zero_rows_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.7_QA_post_campaign_audit_confirm_evidence_exists_for_all_campaign_runs_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.8_QA_post_campaign_audit_evidence_coverage_detail_by_run_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.9_QA_post_campaign_audit_full_archive_final_output_convention_checks_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.10_QA_post_campaign_audit_validation_status_summary_by_campaign_run_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.1_QA_post_campaign_audit_archive_campaign_inventory_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.2_QA_post_campaign_audit_archive_slice_detail_FINAL.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.3_QA_post_campaign_audit_archive_grain_duplicate_check_FINAL.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01933"></a>

### C038-M01933

**ChatGPT** · 2026-05-13T22:51:16.019553-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01933 -->
I treated the non-`FINAL` “`(2)`” CSVs as the **first campaign run** and the `_FINAL.csv` files as the **updated campaign refresh**.

## Bottom line

The first campaign run was clean across Sections **17.1–17.10**.

The updated `_FINAL` run is **not yet clean**, but the issue is very specific: the updated Section 17 framework is correctly flagging that the refresh is incomplete for part of the exposure-intensity family.

The updated run shows:

```text
M2-27 — archive slice missing
M2-28 — evidence missing
M2-30 — evidence missing
```

Everything else in 17.1–17.10 looks structurally healthy. Importantly, **final-output conventions are still clean**: zero convention violations in both the first run and the updated `_FINAL` run.

## Section-by-section comparison

| Section | First campaign result | Updated `_FINAL` result | Interpretation |
|---|---:|---:|---|
| **17.1 Archive campaign inventory** | 36 slices, 1,800,000 rows, ready | 36 active registry rows, 35 archived runs, 1,750,000 archived rows, review | Updated run is missing one 50,000-row archive slice: **M2-27**. |
| **17.2 Archive slice detail** | 36 archive rows, all 50,000 / 50,000 distinct applications | 36 active registry rows displayed; 35 ready, 1 missing | New query is better: it shows active registry rows even when archive is missing. **M2-27** is `REVIEW_ARCHIVE_SLICE_MISSING`. |
| **17.3 Archive grain duplicate check** | duplicate count = 0 | duplicate count = 0; `ARCHIVE_GRAIN_READY` | No archive-grain issue in either run. |
| **17.4 Registry-to-archive reconciliation** | 36 of 36 reconciled | 35 of 36 reconciled; 1 missing | Same M2-27 issue. Status changed from ready to review. |
| **17.5 Missing / mismatched registry runs** | 0 rows | 1 row | The one row is **M2-27**, `ARCHIVE_SLICE_MISSING`, gap = -50,000. |
| **17.6 Archive slices without active registry row** | 0 rows | 0 rows | No orphan archive slices. Good. |
| **17.7 Evidence coverage summary** | 36 of 36 complete | 33 of 36 complete; 3 incomplete | Updated evidence acceptance is stricter. It flags **M2-27, M2-28, M2-30** as missing evidence. |
| **17.8 Evidence coverage detail** | all 36 `EVIDENCE_CAPTURE_READY` | 33 ready, 3 review | Incomplete evidence rows are **M2-27, M2-28, M2-30**. |
| **17.9 Final-output convention checks** | 1,800,000 archived rows; all violation counts 0 | 1,750,000 active campaign archived rows; all violation counts 0 | The rows that exist are clean. The issue is missing coverage, not convention failure. |
| **17.10 Validation status by run** | 36 runs, 22 validation rows each | 33 complete runs with 18 validation rows each; 3 runs with 0 validation rows | New Section 14/17 design uses an 18-key validation evidence spine. **M2-27, M2-28, M2-30** lack validation evidence. |

## Specific problem rows in the updated `_FINAL` run

### M2-27 — archive and evidence missing

`17.2_FINAL` and `17.5_FINAL` both identify:

```text
module2_run_id: M2-27
module1_run_id: M1-13
scenario: EXPOSURE_BASELINE_REFERENCE
expected_module1_source_rows: 50,000
archived_rows: 0
distinct_application_id_count: 0
archive_reconciliation_issue_type: ARCHIVE_SLICE_MISSING
```

This is the only archive-missing run.

### M2-28 and M2-30 — archive likely present, evidence missing

`17.8_FINAL` shows these two runs have:

```text
executive_rows = 0
parameter_rows = 0
validation_rows = 0
segment_rows = 0
evidence_capture_status = EVIDENCE_CAPTURE_REVIEW_REQUIRED
```

The archive inventory does **not** flag M2-28 or M2-30 as missing archive slices. So these look like **evidence capture gaps**, not archive gaps.

## Important difference between old and new Section 17 logic

The old first-run outputs were less strict in a few places.

For example, the old 17.7 checked that validation evidence rows existed. The new 17.7 checks that each active campaign run has the **complete validation evidence key set**. That is stronger and better.

The old 17.1 also assumed the fixed campaign shape:

```text
36 slices × 50,000 rows = 1,800,000 rows
```

The updated 17.1 derives expectations from the active registry and selected Module 1 source counts. That is exactly what we wanted for flexible Module 1 population sizes.

So some changes are not deterioration; they are the new QA doing its job.

## Validation-row count changed from 22 to 18

This is expected due to the redesigned Section 14 validation spine.

First run:

```text
36 runs × 22 validation rows = 792 validation evidence rows
```

Updated run:

```text
33 complete runs × 18 validation rows = 594 validation evidence rows
```

For the 33 complete runs, the validation evidence status is clean:

```text
VALIDATION_EVIDENCE_COMPLETE
```

The three incomplete rows are:

```text
M2-27
M2-28
M2-30
```

## One minor query-display issue I noticed

For the missing-evidence rows in `17.10_FINAL`, the query shows:

```text
validation_rows = 0
validation_distinct_key_count = 1
duplicate_validation_key_rows = -1
```

That is a display artifact from a `LEFT JOIN` counting a null composite key. The status is still correct:

```text
REVIEW_VALIDATION_EVIDENCE_COMPLETENESS
```

But after the campaign is clean, I would consider a small cosmetic patch so missing-evidence rows show:

```text
validation_distinct_key_count = 0
duplicate_validation_key_rows = 0
```

Same idea applies to `expected_segment_rows = 1` for M2-27 when the archive slice is missing. It does not change the acceptance conclusion, but it makes the diagnostic cleaner.

## What I would do next

Rerun these three:

```text
M2-27
M2-28
M2-30
```

For each, run straight through:

```text
Sections 1–16.8
```

Use:

```sql
run_mode = 'STANDARD_CAMPAIGN'
selected_comparison_group_id = NULL
section13_execution_mode = 'AUTO'
```

and change only:

```sql
selected_module2_run_id = 'M2-27'
selected_module2_run_id = 'M2-28'
selected_module2_run_id = 'M2-30'
```

Then run:

```text
fresh Section 15
→ Section 16.9
→ Section 17
```

After that, I would expect:

```text
17.1: MODULE_2_ARCHIVE_INVENTORY_READY
17.4: CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE
17.5: zero rows
17.7: SECTION_16_EVIDENCE_COVERAGE_READY
17.8: all 36 EVIDENCE_CAPTURE_READY
17.9: ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY
17.10: all 36 VALIDATION_EVIDENCE_COMPLETE
```

My read: the updated run did **not** reveal a decision-engine defect. It revealed an incomplete rerun/evidence refresh for three specific exposure-intensity runs, with M2-27 also missing archive persistence.
<!-- END_MESSAGE C038-M01933 -->


---

<a id="c038-m01934"></a>

### C038-M01934

**Andrew** · 2026-05-13T23:12:05.696000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01934 -->
when I tried to re-run M2-27, I got this error: SQL Error [P0001]: ERROR: Module 2 Section 16 failure: tmp_m2_strategy_frontier_executive_summary is required before evidence capture.
  Where: PL/pgSQL function inline_code_block line 92 at RAISE
  ERROR: Module 2 Section 16 failure: tmp_m2_strategy_frontier_executive_summary is required before evidence capture.
  Where: PL/pgSQL function inline_code_block line 92 at RAISE
<!-- END_MESSAGE C038-M01934 -->


---

<a id="c038-m01936"></a>

### C038-M01936

**ChatGPT** · 2026-05-13T23:14:21.364852-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01936 -->
This is not an M2-27 strategy defect. It means **Section 16 was reached without Section 15’s temporary frontier table available in the same session**.

Section 16 explicitly requires:

```sql
tmp_m2_strategy_frontier_executive_summary
```

before evidence capture, because Section 16.6 uses Section 15 frontier posture fields when writing the executive evidence row. The Section 16 header lists `tmp_m2_strategy_frontier_executive_summary` as a primary input, and Section 16.0 validates that it exists before evidence capture proceeds. fileciteturn349file26 Section 15 is the section that creates that frontier summary temporary table. fileciteturn349file29

## Why this happened

Most likely sequence:

```text
M2-27 rerun reached Section 16
but Section 15 was not run in that same session after Section 1 reset
```

or:

```text
Section 15 was run earlier, but Section 1 was run afterward
```

Section 1 clears temporary objects. Since `tmp_m2_strategy_frontier_executive_summary` is temporary, it must be rebuilt by Section 15 before Section 16 each time you run through the full evidence-capture path.

## What to do now

If M2-27 already made it through Section 12 archive persistence and Section 14 validation, you **do not need to rerun from Section 1**.

Run this path:

```text
Section 15
→ Section 16.0 through 16.8
```

Make sure you run Section 15 and Section 16 in the **same database session/connection**.

## Quick validation before continuing

First confirm the current latest-run table is still M2-27:

```sql
SELECT
    r.module2_run_id,
    r.run_sequence_number,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_name,
    r.strategy_version,

    COUNT(sd.*) AS latest_run_rows,
    COUNT(DISTINCT sd.application_id) AS latest_run_distinct_application_ids

FROM credit_decisioning_sim.strategy_decisions sd

LEFT JOIN credit_decisioning_sim.strategy_run_campaign_registry r
    ON r.strategy_set_name = sd.strategy_set_name
   AND r.strategy_name = sd.strategy_name
   AND r.strategy_version = sd.strategy_version
   AND r.module1_scenario_set_name = sd.module1_scenario_set_name
   AND r.module1_scenario_name = sd.module1_scenario_name
   AND r.population_id = sd.population_id
   AND r.registry_active_flag IS TRUE

GROUP BY
    r.module2_run_id,
    r.run_sequence_number,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_name,
    r.strategy_version;
```

Then confirm M2-27 is archived:

```sql
SELECT
    r.module2_run_id,
    r.run_sequence_number,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_name,
    r.strategy_version,

    COUNT(a.*) AS archived_rows,
    COUNT(DISTINCT a.application_id) AS archived_distinct_application_ids

FROM credit_decisioning_sim.strategy_run_campaign_registry r

LEFT JOIN credit_decisioning_sim.strategy_decisions_archive a
    ON a.strategy_set_name = r.strategy_set_name
   AND a.strategy_name = r.strategy_name
   AND a.strategy_version = r.strategy_version
   AND a.module1_scenario_set_name = r.module1_scenario_set_name
   AND a.module1_scenario_name = r.module1_scenario_name
   AND a.population_id = r.population_id

WHERE r.module2_run_id = 'M2-27'
  AND r.registry_active_flag IS TRUE

GROUP BY
    r.module2_run_id,
    r.run_sequence_number,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_name,
    r.strategy_version;
```

Expected:

```text
latest_run_rows = 50000
archived_rows = 50000
```

If both are true, run:

```text
Section 15
Section 16.0–16.8
```

If latest-run is no longer M2-27 or archive rows are still zero, rerun M2-27 from Section 1, but make sure the path includes:

```text
Section 15 before Section 16
```

## Why Section 16 depends on Section 15

Section 16 does not simply capture raw latest-run output. It captures the executive evidence story, including frontier posture, executive quadrant, and frontier interpretation fields. Those are created in Section 15, which summarizes archived strategy frontier tradeoffs and produces `tmp_m2_strategy_frontier_executive_summary`. fileciteturn349file29 Section 16 then consumes that temporary frontier summary when it builds the executive evidence row. fileciteturn349file26

## Practical repair workflow for M2-27 / M2-28 / M2-30

For each repair run, use:

```text
Sections 1–14
Section 15
Section 16.0–16.8
```

After all three are repaired:

```text
fresh Section 15
→ Section 16.9
→ Section 17
```

The final fresh Section 15 / 16.9 / 17 sequence still matters because Section 15 is archive-wide and Section 16.9 refreshes post-campaign frontier fields after the campaign archive is complete.
<!-- END_MESSAGE C038-M01936 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_90.md)
