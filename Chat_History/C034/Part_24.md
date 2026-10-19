# Module 1 Synthetic Application Portfolio Build

## Part 24

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_23.md) · [Next](Part_25.md)

<a id="c034-m01142"></a>

### C034-M01142

**Andrew** · 2026-05-16T11:49:49.331000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01142 -->
please review section 16 logic, comments, header for potential needed changes.  current section 16 attached.
<!-- END_MESSAGE C034-M01142 -->


**Attachments in export:** `Pasted text(206).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01145"></a>

### C034-M01145

**ChatGPT** · 2026-05-16T11:58:01.560039-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01145 -->
According to a document from **2026-05-16**, Section 16 is structurally strong, but it now needs a targeted Option C carry-forward patch. Section 16’s current role is to persist run-level executive evidence, validation evidence, parameter snapshots, and product × score segment evidence, while Section 16.9 later refreshes Section 15-derived frontier fields after the full campaign archive is complete. fileciteturn277file8

## Verdict

```text
Section 16 core architecture: keep
Section 16.0–16.8 run-level evidence capture: keep
Section 16.9 post-campaign synchronization: keep
Section 16 Option C alignment: needs targeted patch
Core rewrite needed: no
Execution blockers from current code: none obvious
```

The main gap is that Section 15 now exposes Option C frontier fields, but Section 16 still appears to capture and synchronize only the older frontier fields: `frontier_position_type`, `executive_frontier_quadrant`, `frontier_interpretation_note`, and reason-code delta-driver fields. Section 16.9’s current documented refresh list confirms that limitation. fileciteturn277file0

So the required update is:

```text
Section 15 creates Option C frontier evidence.
Section 16.6 must persist it into strategy_run_evidence_summary.
Section 16.9 must refresh it after full-campaign Section 15 rerun.
Section 16.7 / 16.8 must validate and display it.
```

---

# Recommended Section 16 changes

## Change 1 — Update top Section 16 header / narrative

Add this block after **WHY FRONTIER FIELDS COME FROM SECTION 15**.

```sql
WHY OPTION C FRONTIER FIELDS COME FROM SECTION 15:
    Option C selective-versus-aggressive counteroffer evidence is calculated in the archive-wide
    frontier layer.

    Section 15 summarizes:
        ordinary counteroffer candidacy,
        aggressive counteroffer expansion override routing,
        aggressive override final outcome mix,
        aggressive override approved-exposure quality,
        aggressive override approved Expected Loss,
        and Option C frontier posture labels.

    Section 16 should capture those Section 15-derived fields into persistent executive evidence.

    Why this matters:
        The one-row executive evidence summary is the durable run-level story register.

        If Option C frontier fields are not persisted here, later README, LinkedIn, validation-summary,
        and final campaign evidence will not clearly distinguish:

            SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
            from
            AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

    Boundary:
        Section 16 does not calculate Option C frontier metrics.

        Section 16 only persists and later synchronizes the completed Section 15 frontier evidence.
```

Also update the top `SQL PURPOSE` list.

### Before

```sql
12. Persist the current one-row executive evidence summary.
13. Validate current-run evidence capture through local Section 16.7 gatekeepers.
14. Display compact export-ready Section 16.8 diagnostics.
```

### After

```sql
12. Persist the current one-row executive evidence summary, including Section 15-derived Option C
    selective/aggressive counteroffer frontier fields.
13. Validate current-run evidence capture through local Section 16.7 gatekeepers.
14. Display compact export-ready Section 16.8 diagnostics, including Option C evidence fields.
```

And in the “Section 16 captures the story” question list, add:

```sql
        Did the run represent selective counteroffer feasibility or aggressive counteroffer expansion?
        How many ordinary counteroffer candidates and aggressive override rows were observed?
        How did aggressive override rows resolve across COUNTEROFFER, MANUAL_REVIEW, and DECLINE?
```

---

# Change 2 — Section 16.1: add Option C columns to `strategy_run_evidence_summary`

Add these columns to the `CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_evidence_summary` definition, ideally near the existing frontier fields.

```sql
    /***********************************************************************************************
    Option C counteroffer strategy split frontier evidence.

    These fields are sourced from Section 15 frontier outputs.

    They preserve the executive-level evidence needed to compare:
        SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
        against
        AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

    Boundary:
        These are strategy-simulation frontier evidence fields.

        They do not recalculate decisions.
        They do not recalculate approved exposure.
        They do not recalculate approved Expected Loss.
        They do not represent production underwriting guidance.
    ***********************************************************************************************/
    counteroffer_strategy_variant TEXT,
    aggressive_counteroffer_expansion_enabled BOOLEAN,

    ordinary_counteroffer_candidate_rows BIGINT,
    ordinary_counteroffer_candidate_rate NUMERIC,
    delta_ordinary_counteroffer_candidate_rate NUMERIC,

    aggressive_override_rows BIGINT,
    aggressive_override_rate NUMERIC,
    delta_aggressive_override_rate NUMERIC,

    aggressive_override_final_counteroffer_rows BIGINT,
    aggressive_override_final_counteroffer_rate NUMERIC,
    delta_aggressive_override_final_counteroffer_rate NUMERIC,

    aggressive_override_final_manual_review_rows BIGINT,
    aggressive_override_final_manual_review_rate NUMERIC,

    aggressive_override_final_decline_rows BIGINT,
    aggressive_override_final_decline_rate NUMERIC,

    avg_exposure_reduction_pct_for_aggressive_override_counteroffers NUMERIC,
    avg_approved_pti_for_aggressive_override_counteroffers NUMERIC,
    avg_approved_el_for_aggressive_override_counteroffers NUMERIC,

    option_c_frontier_posture_type TEXT,
    option_c_frontier_interpretation_note TEXT,
```

Then add the same fields to the Section 16.1 schema-hardening block for older evidence tables:

```sql
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS counteroffer_strategy_variant TEXT,
    ADD COLUMN IF NOT EXISTS aggressive_counteroffer_expansion_enabled BOOLEAN,

    ADD COLUMN IF NOT EXISTS ordinary_counteroffer_candidate_rows BIGINT,
    ADD COLUMN IF NOT EXISTS ordinary_counteroffer_candidate_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS delta_ordinary_counteroffer_candidate_rate NUMERIC,

    ADD COLUMN IF NOT EXISTS aggressive_override_rows BIGINT,
    ADD COLUMN IF NOT EXISTS aggressive_override_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS delta_aggressive_override_rate NUMERIC,

    ADD COLUMN IF NOT EXISTS aggressive_override_final_counteroffer_rows BIGINT,
    ADD COLUMN IF NOT EXISTS aggressive_override_final_counteroffer_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS delta_aggressive_override_final_counteroffer_rate NUMERIC,

    ADD COLUMN IF NOT EXISTS aggressive_override_final_manual_review_rows BIGINT,
    ADD COLUMN IF NOT EXISTS aggressive_override_final_manual_review_rate NUMERIC,

    ADD COLUMN IF NOT EXISTS aggressive_override_final_decline_rows BIGINT,
    ADD COLUMN IF NOT EXISTS aggressive_override_final_decline_rate NUMERIC,

    ADD COLUMN IF NOT EXISTS avg_exposure_reduction_pct_for_aggressive_override_counteroffers NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_pti_for_aggressive_override_counteroffers NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_el_for_aggressive_override_counteroffers NUMERIC,

    ADD COLUMN IF NOT EXISTS option_c_frontier_posture_type TEXT,
    ADD COLUMN IF NOT EXISTS option_c_frontier_interpretation_note TEXT;
```

If your existing hardening block already has one long `ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary ADD COLUMN IF NOT EXISTS ...` statement, add the fields into that same statement rather than creating a duplicate separate block.

---

# Change 3 — Section 16.1: add Option C evidence indexes

Add these after the existing evidence-table indexes.

```sql
/*-----------------------------------------------------------------------------------------------
Option C executive evidence review indexes.

Purpose:
    Support review of selective feasibility versus aggressive expansion evidence across completed
    campaign runs.

Boundary:
    These indexes improve review ergonomics only.

    They do not modify evidence values.
-----------------------------------------------------------------------------------------------*/

CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_evidence_option_c_variant
ON credit_decisioning_sim.strategy_run_evidence_summary (
    counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_evidence_option_c_posture
ON credit_decisioning_sim.strategy_run_evidence_summary (
    option_c_frontier_posture_type
);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_evidence_aggressive_override
ON credit_decisioning_sim.strategy_run_evidence_summary (
    aggressive_override_rows,
    aggressive_override_final_counteroffer_rows
);
```

---

# Change 4 — Section 16.6: insert Option C fields into the executive evidence summary

Section 16.6 is the critical current-run capture step. It already reads `tmp_m2_strategy_frontier_executive_summary`, which Section 15 now uses as the primary export-ready frontier output. Section 15 explicitly states that Section 16.6 consumes this table for current-run evidence capture. fileciteturn277file4

In the `INSERT INTO credit_decisioning_sim.strategy_run_evidence_summary (...)` column list, add these fields near the existing frontier fields:

```sql
    counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled,

    ordinary_counteroffer_candidate_rows,
    ordinary_counteroffer_candidate_rate,
    delta_ordinary_counteroffer_candidate_rate,

    aggressive_override_rows,
    aggressive_override_rate,
    delta_aggressive_override_rate,

    aggressive_override_final_counteroffer_rows,
    aggressive_override_final_counteroffer_rate,
    delta_aggressive_override_final_counteroffer_rate,

    aggressive_override_final_manual_review_rows,
    aggressive_override_final_manual_review_rate,

    aggressive_override_final_decline_rows,
    aggressive_override_final_decline_rate,

    avg_exposure_reduction_pct_for_aggressive_override_counteroffers,
    avg_approved_pti_for_aggressive_override_counteroffers,
    avg_approved_el_for_aggressive_override_counteroffers,

    option_c_frontier_posture_type,
    option_c_frontier_interpretation_note,
```

Then add the corresponding values in the `SELECT` list from the Section 15 frontier alias. I’ll use `f` below; replace `f.` with your actual `tmp_m2_strategy_frontier_executive_summary` alias.

```sql
    f.counteroffer_strategy_variant,
    f.aggressive_counteroffer_expansion_enabled,

    f.ordinary_counteroffer_candidate_rows,
    f.ordinary_counteroffer_candidate_rate,
    f.delta_ordinary_counteroffer_candidate_rate,

    f.aggressive_override_rows,
    f.aggressive_override_rate,
    f.delta_aggressive_override_rate,

    f.aggressive_override_final_counteroffer_rows,
    f.aggressive_override_final_counteroffer_rate,
    f.delta_aggressive_override_final_counteroffer_rate,

    f.aggressive_override_final_manual_review_rows,
    f.aggressive_override_final_manual_review_rate,

    f.aggressive_override_final_decline_rows,
    f.aggressive_override_final_decline_rate,

    f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers,
    f.avg_approved_pti_for_aggressive_override_counteroffers,
    f.avg_approved_el_for_aggressive_override_counteroffers,

    f.option_c_frontier_posture_type,
    f.option_c_frontier_interpretation_note,
```

## Add a Section 16.6 header comment

```sql
OPTION C EXECUTIVE EVIDENCE CAPTURE NOTE:
    Section 16.6 should persist the Option C frontier fields created in Section 15.

    These fields are Section 15-derived evidence.

    They are captured here so the persistent executive evidence row can explain whether this run
    behaved as:
        selective counteroffer feasibility,
        aggressive counteroffer expansion,
        non-Option-C strategy behavior,
        or an Option C frontier point requiring review.

    Section 16.6 does not calculate these fields.
    It only stores the Section 15 output.
```

---

# Change 5 — Section 16.7: validate Option C evidence fields

Section 16.7 already checks that exactly one executive summary row exists, that validation row counts match Section 14, that parameter and segment evidence exists, that registry-linkage fields are populated and aligned, and that Module 3 gaps do not fail the run. fileciteturn277file3

Add a specific Option C completeness variable:

```sql
    v_option_c_evidence_gap_count BIGINT;
```

Then add this gatekeeper after the required executive-summary field check.

```sql
    /*-------------------------------------------------------------------------------------------
    16.7X Option C executive evidence completeness gatekeeper.

    Business purpose:
        Confirm that Section 16.6 persisted the Option C frontier fields from Section 15 into the
        one-row executive evidence summary.

    Expected:
        Core Option C posture fields should be populated for every evidence row.

        Baseline-relative delta fields may be NULL when no matching baseline exists, so this check
        does not require delta fields to be populated.

        Aggressive override average metrics may be NULL when no aggressive override final
        COUNTEROFFER rows exist, so this check does not require those averages to be populated.

    Boundary:
        This check validates evidence capture only.

        It does not judge whether aggressive expansion is better.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_option_c_evidence_gap_count
    FROM credit_decisioning_sim.strategy_run_evidence_summary e
    WHERE e.strategy_set_name = k.strategy_set_name
      AND e.strategy_name = k.strategy_name
      AND e.strategy_version = k.strategy_version
      AND e.module1_scenario_set_name = k.module1_scenario_set_name
      AND e.module1_scenario_name = k.module1_scenario_name
      AND e.population_id = k.population_id
      AND (
            e.counteroffer_strategy_variant IS NULL
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
      );

    IF v_option_c_evidence_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: executive evidence summary is missing required Option C frontier evidence fields for the current run.';
    END IF;
```

Then update the Section 16.7 SQL purpose list:

```sql
12. Confirm Option C frontier evidence fields are populated in the executive evidence summary.
```

Renumber the Module 3 readiness line if needed.

---

# Change 6 — Section 16.8: display Option C evidence in export-ready outputs

In the current-run executive evidence summary display, add these fields near the frontier fields:

```sql
    counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled,

    ordinary_counteroffer_candidate_rows,
    ordinary_counteroffer_candidate_rate,
    delta_ordinary_counteroffer_candidate_rate,

    aggressive_override_rows,
    aggressive_override_rate,
    delta_aggressive_override_rate,

    aggressive_override_final_counteroffer_rows,
    aggressive_override_final_counteroffer_rate,
    delta_aggressive_override_final_counteroffer_rate,

    aggressive_override_final_manual_review_rows,
    aggressive_override_final_manual_review_rate,

    aggressive_override_final_decline_rows,
    aggressive_override_final_decline_rate,

    option_c_frontier_posture_type,
    option_c_frontier_interpretation_note,
```

Add this optional diagnostic result set in Section 16.8:

```sql
/*-----------------------------------------------------------------------------------------------
16.8X Option C executive evidence review.

Purpose:
    Display the captured Option C selective/aggressive counteroffer frontier evidence for the current
    run.

Interpretation:
    SELECTIVE_FEASIBILITY should generally show no aggressive override rows.
    AGGRESSIVE_EXPANSION may show aggressive override rows, with final outcomes split across
    COUNTEROFFER, MANUAL_REVIEW, and DECLINE.

Boundary:
    This is evidence-review output only.

    It does not decide whether aggressive expansion is better.
-----------------------------------------------------------------------------------------------*/

SELECT
    e.module2_run_id,
    e.run_sequence_number,
    e.showcase_id,
    e.comparison_group_id,

    e.strategy_name,
    e.strategy_version,
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,

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
    e.option_c_frontier_interpretation_note

FROM credit_decisioning_sim.strategy_run_evidence_summary e
JOIN tmp_m2_current_run_key k
  ON e.strategy_set_name = k.strategy_set_name
 AND e.strategy_name = k.strategy_name
 AND e.strategy_version = k.strategy_version
 AND e.module1_scenario_set_name = k.module1_scenario_set_name
 AND e.module1_scenario_name = k.module1_scenario_name
 AND e.population_id = k.population_id;
```

Also update Section 16.8 `SQL PURPOSE`:

```sql
7. Display captured Option C selective/aggressive counteroffer frontier evidence.
```

---

# Change 7 — Section 16.9: synchronize Option C frontier fields after full campaign

This is the most important Section 16 update.

Section 16.9 currently refreshes only the older Section 15-derived fields. Its documented refresh list includes frontier posture, executive quadrant, frontier interpretation, and top reason-code delta-driver fields. fileciteturn277file18

Now Section 16.9 must also refresh the Section 15-derived Option C fields.

## 7A — Update Section 16.9 header

In **WHAT THIS SECTION UPDATES**, add:

```sql
        counteroffer_strategy_variant
        aggressive_counteroffer_expansion_enabled
        ordinary_counteroffer_candidate_rows
        ordinary_counteroffer_candidate_rate
        delta_ordinary_counteroffer_candidate_rate
        aggressive_override_rows
        aggressive_override_rate
        delta_aggressive_override_rate
        aggressive_override_final_counteroffer_rows
        aggressive_override_final_counteroffer_rate
        delta_aggressive_override_final_counteroffer_rate
        aggressive_override_final_manual_review_rows
        aggressive_override_final_manual_review_rate
        aggressive_override_final_decline_rows
        aggressive_override_final_decline_rate
        avg_exposure_reduction_pct_for_aggressive_override_counteroffers
        avg_approved_pti_for_aggressive_override_counteroffers
        avg_approved_el_for_aggressive_override_counteroffers
        option_c_frontier_posture_type
        option_c_frontier_interpretation_note
```

Also update the “specifically may refresh” list at the end of Section 16.9, because it currently only names the old frontier and reason-code fields. fileciteturn277file6

## 7B — Add Option C fields to required-column checks

In both Section 16.9 required-column checks:

```text
strategy_run_evidence_summary required columns
tmp_m2_strategy_frontier_executive_summary required columns
```

add these fields:

```sql
                ('counteroffer_strategy_variant'),
                ('aggressive_counteroffer_expansion_enabled'),

                ('ordinary_counteroffer_candidate_rows'),
                ('ordinary_counteroffer_candidate_rate'),
                ('delta_ordinary_counteroffer_candidate_rate'),

                ('aggressive_override_rows'),
                ('aggressive_override_rate'),
                ('delta_aggressive_override_rate'),

                ('aggressive_override_final_counteroffer_rows'),
                ('aggressive_override_final_counteroffer_rate'),
                ('delta_aggressive_override_final_counteroffer_rate'),

                ('aggressive_override_final_manual_review_rows'),
                ('aggressive_override_final_manual_review_rate'),

                ('aggressive_override_final_decline_rows'),
                ('aggressive_override_final_decline_rate'),

                ('avg_exposure_reduction_pct_for_aggressive_override_counteroffers'),
                ('avg_approved_pti_for_aggressive_override_counteroffers'),
                ('avg_approved_el_for_aggressive_override_counteroffers'),

                ('option_c_frontier_posture_type'),
                ('option_c_frontier_interpretation_note'),
```

The snippet shows Section 16.9 already has required-column checks for evidence and fresh Section 15 frontier tables, so this is a direct extension of the existing pattern. fileciteturn277file6

## 7C — Add Option C fields to the pre-update candidate mismatch logic

Where Section 16.9 builds the candidate table identifying rows needing synchronization, add `IS DISTINCT FROM` comparisons for the Option C fields.

Use your existing table aliases. I’ll write this as `e` for evidence and `f` for frontier:

```sql
   OR e.counteroffer_strategy_variant
        IS DISTINCT FROM f.counteroffer_strategy_variant
   OR e.aggressive_counteroffer_expansion_enabled
        IS DISTINCT FROM f.aggressive_counteroffer_expansion_enabled

   OR e.ordinary_counteroffer_candidate_rows
        IS DISTINCT FROM f.ordinary_counteroffer_candidate_rows
   OR e.ordinary_counteroffer_candidate_rate
        IS DISTINCT FROM f.ordinary_counteroffer_candidate_rate
   OR e.delta_ordinary_counteroffer_candidate_rate
        IS DISTINCT FROM f.delta_ordinary_counteroffer_candidate_rate

   OR e.aggressive_override_rows
        IS DISTINCT FROM f.aggressive_override_rows
   OR e.aggressive_override_rate
        IS DISTINCT FROM f.aggressive_override_rate
   OR e.delta_aggressive_override_rate
        IS DISTINCT FROM f.delta_aggressive_override_rate

   OR e.aggressive_override_final_counteroffer_rows
        IS DISTINCT FROM f.aggressive_override_final_counteroffer_rows
   OR e.aggressive_override_final_counteroffer_rate
        IS DISTINCT FROM f.aggressive_override_final_counteroffer_rate
   OR e.delta_aggressive_override_final_counteroffer_rate
        IS DISTINCT FROM f.delta_aggressive_override_final_counteroffer_rate

   OR e.aggressive_override_final_manual_review_rows
        IS DISTINCT FROM f.aggressive_override_final_manual_review_rows
   OR e.aggressive_override_final_manual_review_rate
        IS DISTINCT FROM f.aggressive_override_final_manual_review_rate

   OR e.aggressive_override_final_decline_rows
        IS DISTINCT FROM f.aggressive_override_final_decline_rows
   OR e.aggressive_override_final_decline_rate
        IS DISTINCT FROM f.aggressive_override_final_decline_rate

   OR e.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
        IS DISTINCT FROM f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
   OR e.avg_approved_pti_for_aggressive_override_counteroffers
        IS DISTINCT FROM f.avg_approved_pti_for_aggressive_override_counteroffers
   OR e.avg_approved_el_for_aggressive_override_counteroffers
        IS DISTINCT FROM f.avg_approved_el_for_aggressive_override_counteroffers

   OR e.option_c_frontier_posture_type
        IS DISTINCT FROM f.option_c_frontier_posture_type
   OR e.option_c_frontier_interpretation_note
        IS DISTINCT FROM f.option_c_frontier_interpretation_note
```

## 7D — Add Option C fields to the `UPDATE SET`

```sql
    counteroffer_strategy_variant = f.counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled = f.aggressive_counteroffer_expansion_enabled,

    ordinary_counteroffer_candidate_rows = f.ordinary_counteroffer_candidate_rows,
    ordinary_counteroffer_candidate_rate = f.ordinary_counteroffer_candidate_rate,
    delta_ordinary_counteroffer_candidate_rate = f.delta_ordinary_counteroffer_candidate_rate,

    aggressive_override_rows = f.aggressive_override_rows,
    aggressive_override_rate = f.aggressive_override_rate,
    delta_aggressive_override_rate = f.delta_aggressive_override_rate,

    aggressive_override_final_counteroffer_rows = f.aggressive_override_final_counteroffer_rows,
    aggressive_override_final_counteroffer_rate = f.aggressive_override_final_counteroffer_rate,
    delta_aggressive_override_final_counteroffer_rate = f.delta_aggressive_override_final_counteroffer_rate,

    aggressive_override_final_manual_review_rows = f.aggressive_override_final_manual_review_rows,
    aggressive_override_final_manual_review_rate = f.aggressive_override_final_manual_review_rate,

    aggressive_override_final_decline_rows = f.aggressive_override_final_decline_rows,
    aggressive_override_final_decline_rate = f.aggressive_override_final_decline_rate,

    avg_exposure_reduction_pct_for_aggressive_override_counteroffers =
        f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers,
    avg_approved_pti_for_aggressive_override_counteroffers =
        f.avg_approved_pti_for_aggressive_override_counteroffers,
    avg_approved_el_for_aggressive_override_counteroffers =
        f.avg_approved_el_for_aggressive_override_counteroffers,

    option_c_frontier_posture_type = f.option_c_frontier_posture_type,
    option_c_frontier_interpretation_note = f.option_c_frontier_interpretation_note,
```

## 7E — Add Option C fields to the post-update mismatch check

Use the same `IS DISTINCT FROM` field list from 7C in the post-update validation query. The purpose is to prove matched evidence rows now align with the fresh Section 15 output.

## 7F — Add Section 16.9 diagnostic output

Add a small review output after the synchronization summary:

```sql
/*-----------------------------------------------------------------------------------------------
16.9X Option C frontier synchronization review.

Purpose:
    Show persistent evidence rows after synchronization for Option C frontier fields.

Interpretation:
    These fields should now match the fresh Section 15 frontier output for matched technical run keys.
-----------------------------------------------------------------------------------------------*/

SELECT
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,
    e.strategy_set_name,
    e.strategy_name,
    e.strategy_version,

    e.module2_run_id,
    e.run_sequence_number,
    e.showcase_id,
    e.comparison_group_id,

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

    e.option_c_frontier_posture_type,
    e.option_c_frontier_interpretation_note

FROM credit_decisioning_sim.strategy_run_evidence_summary e
WHERE e.counteroffer_strategy_variant IN (
        'SELECTIVE_FEASIBILITY',
        'AGGRESSIVE_EXPANSION'
    )
   OR e.aggressive_override_rows > 0
ORDER BY
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,
    e.run_sequence_number NULLS LAST,
    e.strategy_name;
```

---

# Change 8 — Section 16.4 parameter snapshot: comment update only

No logic change is needed if the strategy parameter snapshot uses the full active strategy parameter card as JSONB.

Because Option C controls live in `tmp_module2_strategy_params`, they should already be captured inside the strategy-parameter JSONB payload. Section 16’s header already says Section 16.4 snapshots active strategy parameters, product-policy parameters, run-story metadata, and a parameter snapshot hash. fileciteturn277file9

Add this comment near Section 16.4:

```sql
Option C parameter snapshot note:
    The active strategy parameter JSONB payload includes the Option C counteroffer split controls
    from tmp_module2_strategy_params.

    This means the parameter snapshot preserves:
        counteroffer_strategy_variant,
        aggressive_counteroffer_expansion_enabled,
        severe_requested_structure_counteroffer_override_enabled,
        exposure_extreme_counteroffer_override_enabled,
        exposure_policy_stop_counteroffer_override_enabled,
        requested_pti_decline_counteroffer_override_enabled,
        requested_el_decline_counteroffer_override_enabled.

    No separate Option C parameter snapshot table is required.
```

---

# Change 9 — Section 16.3 validation evidence: no logic change

No logic change is needed in Section 16.3 if it persists every row from `tmp_m2_validation_status_summary`.

Section 14.19 now adds Option C validation rows, and Section 16.3 should automatically capture them if it inserts from the full validation summary table. Section 16’s header already identifies `tmp_m2_validation_status_summary` as the Section 14 validation status summary input. fileciteturn277file5

Add only this short comment near Section 16.3:

```sql
Option C validation evidence note:
    Section 14.19 now includes Option C validation rows in tmp_m2_validation_status_summary.

    Section 16.3 does not need special Option C insert logic as long as it persists every row from
    tmp_m2_validation_status_summary.
```

---

# Change 10 — End-of-section summaries

## End of 16.0–16.8

Add these to the “If execution reaches this point” list:

```sql
    13. Option C selective/aggressive counteroffer frontier fields have been captured in the
        executive evidence summary where Section 15 provided a matching frontier row.
    14. Option C validation evidence rows from Section 14 have been persisted where present.
```

Renumber the existing Module 3 / diagnostic items if needed.

Add this Option C note:

```sql
Option C note:
    Section 16.0–16.8 now captures the run-level evidence needed to document the Option C
    counteroffer strategy split.

    The persistent evidence layer can distinguish:
        ordinary counteroffer candidacy,
        aggressive requested-structure override routing,
        aggressive override final outcome mix,
        and Option C frontier posture.

    Section 16 does not decide whether aggressive expansion is better.

    It preserves the evidence needed for Section 17 acceptance and later documentation.
```

## End of 16.9

Add these to the “If execution reaches this point” list:

```sql
    7. Section 15-derived Option C frontier fields have been refreshed for all matching evidence rows.
    8. Matched evidence rows now align with the fresh Section 15 Option C frontier output.
```

Update the “specifically may refresh” list to include the Option C fields from Change 7A.

---

# Final recommendation

Patch Section 16, but do not rewrite it.

```text
Keep:
  - run-level evidence capture architecture
  - four persistent evidence tables
  - delete / insert replacement by current run key
  - validation evidence capture
  - parameter snapshot capture
  - product × score segment evidence
  - executive evidence summary
  - Section 16.9 post-campaign synchronization pattern

Add:
  - Option C fields to strategy_run_evidence_summary
  - Option C fields to Section 16.6 executive summary insert
  - Option C completeness checks in Section 16.7
  - Option C display output in Section 16.8
  - Option C field synchronization in Section 16.9
```

The key principle is:

```text
Section 15 creates Option C frontier evidence.
Section 16 persists and synchronizes that evidence.
Section 17 will use it for final campaign acceptance.
```

After these updates, Section 16 will be aligned with the Option C architecture and ready for Section 17 review.
<!-- END_MESSAGE C034-M01145 -->


---

<a id="c034-m01147"></a>

### C034-M01147

**Andrew** · 2026-05-16T19:51:17.016000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01147 -->
please assist more clearly in helping me implement 7C - Add Option C fields to the pre-update candidate mismatch logic.  Here is the section 16.9 as it currently stands.
<!-- END_MESSAGE C034-M01147 -->


**Attachments in export:** `Pasted text(207).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01149"></a>

### C034-M01149

**ChatGPT** · 2026-05-16T19:56:01.183657-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01149 -->
According to a document from **2026-05-16**, your current Section 16.9 already lists the Option C fields in the “fields refreshed from fresh Section 15 output” header, but the actual `16.9C` pre-update candidate logic still compares only the older frontier / reason-code fields. fileciteturn279file4 The specific place to patch is **SECTION 16.9C — BUILD PRE-UPDATE SYNCHRONIZATION CANDIDATES**, where `field_compare` creates mismatch flags such as `frontier_position_type_mismatch_flag`, `executive_frontier_quadrant_mismatch_flag`, and `top_reason_code_delta_population_share_mismatch_flag`. fileciteturn280file7turn280file0

Replace your entire current **Section 16.9C** with this version.

```sql
/***************************************************************************************************
SECTION 16.9C — BUILD PRE-UPDATE SYNCHRONIZATION CANDIDATES
****************************************************************************************************

PURPOSE:
    Compare persistent executive evidence rows to fresh Section 15 frontier rows and identify which
    evidence rows need synchronization.

SQL LOGIC:
    1. Start from persistent strategy_run_evidence_summary.
    2. Left join to tmp_m2_strategy_frontier_executive_summary on technical run key.
    3. Compare each Section 15-derived field using IS DISTINCT FROM.
    4. Calculate a mismatch count and row-level sync action.

WHY IS DISTINCT FROM:
    IS DISTINCT FROM treats NULLs explicitly.

    NULL versus non-NULL is a mismatch.
    NULL versus NULL is not a mismatch.

OPTION C SYNCHRONIZATION NOTE:
    Section 15 now produces Option C selective/aggressive counteroffer frontier fields.

    Section 16.9C should therefore compare both:
        legacy frontier fields
        and
        Option C frontier fields

    before Section 16.9D applies updates.

IMPLEMENTATION NOTE:
    Some Option C field names are long.

    For the three aggressive-override average metrics, this section uses shorter candidate-table
    aliases to avoid PostgreSQL's 63-character identifier truncation behavior.

    Use these shortened Section 15 aliases later in Section 16.9D:
        section15_avg_agr_ovr_co_exposure_reduction_pct
        section15_avg_agr_ovr_co_approved_pti
        section15_avg_agr_ovr_co_approved_el

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_candidates
ON COMMIT PRESERVE ROWS
AS
WITH field_compare AS (
    SELECT
        /*******************************************************************************************
        Technical run key.

        Synchronization is matched on the same technical run key used by Section 15 frontier output
        and Section 16 executive evidence.
        *******************************************************************************************/
        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,

        /*******************************************************************************************
        Optional campaign IDs for review readability.

        These fields are not match keys. They help reviewers understand which campaign rows would be
        refreshed.
        *******************************************************************************************/
        e.module1_run_id,
        e.module2_run_id,
        e.run_sequence_number,
        e.showcase_id,
        e.showcase_name,
        e.comparison_group_id,
        e.validation_evidence_group_id,

        /*******************************************************************************************
        Match diagnostic.

        TRUE means this persistent evidence row has a matching fresh Section 15 frontier row.
        FALSE means this evidence row is not updated by Section 16.9 and should be reviewed only if
        campaign completeness is expected.
        *******************************************************************************************/
        CASE
            WHEN f.strategy_set_name IS NOT NULL
                THEN TRUE
            ELSE FALSE
        END AS frontier_match_flag,

        /*******************************************************************************************
        Current persistent evidence values — standard frontier fields.
        *******************************************************************************************/
        e.frontier_position_type
            AS evidence_frontier_position_type,

        e.executive_frontier_quadrant
            AS evidence_executive_frontier_quadrant,

        e.frontier_interpretation_note
            AS evidence_frontier_interpretation_note,

        e.top_reason_code_delta_driver_family
            AS evidence_top_reason_code_delta_driver_family,

        e.top_reason_code_delta_driver_code
            AS evidence_top_reason_code_delta_driver_code,

        e.top_reason_code_delta_driver_baseline_share
            AS evidence_top_reason_code_delta_driver_baseline_share,

        e.top_reason_code_delta_driver_strategy_share
            AS evidence_top_reason_code_delta_driver_strategy_share,

        e.top_reason_code_delta_population_share
            AS evidence_top_reason_code_delta_population_share,

        /*******************************************************************************************
        Current persistent evidence values — Option C frontier fields.

        These values currently stored in credit_decisioning_sim.strategy_run_evidence_summary may be
        stale if Section 15 was rerun after the full campaign archive was completed.
        *******************************************************************************************/
        e.counteroffer_strategy_variant
            AS evidence_counteroffer_strategy_variant,

        e.aggressive_counteroffer_expansion_enabled
            AS evidence_aggressive_counteroffer_expansion_enabled,

        e.ordinary_counteroffer_candidate_rows
            AS evidence_ordinary_counteroffer_candidate_rows,

        e.ordinary_counteroffer_candidate_rate
            AS evidence_ordinary_counteroffer_candidate_rate,

        e.delta_ordinary_counteroffer_candidate_rate
            AS evidence_delta_ordinary_counteroffer_candidate_rate,

        e.aggressive_override_rows
            AS evidence_aggressive_override_rows,

        e.aggressive_override_rate
            AS evidence_aggressive_override_rate,

        e.delta_aggressive_override_rate
            AS evidence_delta_aggressive_override_rate,

        e.aggressive_override_final_counteroffer_rows
            AS evidence_aggressive_override_final_counteroffer_rows,

        e.aggressive_override_final_counteroffer_rate
            AS evidence_aggressive_override_final_counteroffer_rate,

        e.delta_aggressive_override_final_counteroffer_rate
            AS evidence_delta_aggressive_override_final_counteroffer_rate,

        e.aggressive_override_final_manual_review_rows
            AS evidence_aggressive_override_final_manual_review_rows,

        e.aggressive_override_final_manual_review_rate
            AS evidence_aggressive_override_final_manual_review_rate,

        e.aggressive_override_final_decline_rows
            AS evidence_aggressive_override_final_decline_rows,

        e.aggressive_override_final_decline_rate
            AS evidence_aggressive_override_final_decline_rate,

        e.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
            AS evidence_avg_agr_ovr_co_exposure_reduction_pct,

        e.avg_approved_pti_for_aggressive_override_counteroffers
            AS evidence_avg_agr_ovr_co_approved_pti,

        e.avg_approved_el_for_aggressive_override_counteroffers
            AS evidence_avg_agr_ovr_co_approved_el,

        e.option_c_frontier_posture_type
            AS evidence_option_c_frontier_posture_type,

        e.option_c_frontier_interpretation_note
            AS evidence_option_c_frontier_interpretation_note,

        /*******************************************************************************************
        Fresh Section 15 values — standard frontier fields.
        *******************************************************************************************/
        f.frontier_position_type
            AS section15_frontier_position_type,

        f.executive_frontier_quadrant
            AS section15_executive_frontier_quadrant,

        f.frontier_interpretation_note
            AS section15_frontier_interpretation_note,

        f.top_reason_code_delta_driver_family
            AS section15_top_reason_code_delta_driver_family,

        f.top_reason_code_delta_driver_code
            AS section15_top_reason_code_delta_driver_code,

        f.top_reason_code_delta_driver_baseline_share
            AS section15_top_reason_code_delta_driver_baseline_share,

        f.top_reason_code_delta_driver_strategy_share
            AS section15_top_reason_code_delta_driver_strategy_share,

        f.top_reason_code_delta_population_share
            AS section15_top_reason_code_delta_population_share,

        /*******************************************************************************************
        Fresh Section 15 values — Option C frontier fields.

        These are the authoritative current frontier values after Section 15 was rerun from the
        completed campaign archive.
        *******************************************************************************************/
        f.counteroffer_strategy_variant
            AS section15_counteroffer_strategy_variant,

        f.aggressive_counteroffer_expansion_enabled
            AS section15_aggressive_counteroffer_expansion_enabled,

        f.ordinary_counteroffer_candidate_rows
            AS section15_ordinary_counteroffer_candidate_rows,

        f.ordinary_counteroffer_candidate_rate
            AS section15_ordinary_counteroffer_candidate_rate,

        f.delta_ordinary_counteroffer_candidate_rate
            AS section15_delta_ordinary_counteroffer_candidate_rate,

        f.aggressive_override_rows
            AS section15_aggressive_override_rows,

        f.aggressive_override_rate
            AS section15_aggressive_override_rate,

        f.delta_aggressive_override_rate
            AS section15_delta_aggressive_override_rate,

        f.aggressive_override_final_counteroffer_rows
            AS section15_aggressive_override_final_counteroffer_rows,

        f.aggressive_override_final_counteroffer_rate
            AS section15_aggressive_override_final_counteroffer_rate,

        f.delta_aggressive_override_final_counteroffer_rate
            AS section15_delta_aggressive_override_final_counteroffer_rate,

        f.aggressive_override_final_manual_review_rows
            AS section15_aggressive_override_final_manual_review_rows,

        f.aggressive_override_final_manual_review_rate
            AS section15_aggressive_override_final_manual_review_rate,

        f.aggressive_override_final_decline_rows
            AS section15_aggressive_override_final_decline_rows,

        f.aggressive_override_final_decline_rate
            AS section15_aggressive_override_final_decline_rate,

        f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
            AS section15_avg_agr_ovr_co_exposure_reduction_pct,

        f.avg_approved_pti_for_aggressive_override_counteroffers
            AS section15_avg_agr_ovr_co_approved_pti,

        f.avg_approved_el_for_aggressive_override_counteroffers
            AS section15_avg_agr_ovr_co_approved_el,

        f.option_c_frontier_posture_type
            AS section15_option_c_frontier_posture_type,

        f.option_c_frontier_interpretation_note
            AS section15_option_c_frontier_interpretation_note,

        /*******************************************************************************************
        Field-level mismatch flags — standard frontier fields.
        *******************************************************************************************/
        (
            e.frontier_position_type
            IS DISTINCT FROM f.frontier_position_type
        ) AS frontier_position_type_mismatch_flag,

        (
            e.executive_frontier_quadrant
            IS DISTINCT FROM f.executive_frontier_quadrant
        ) AS executive_frontier_quadrant_mismatch_flag,

        (
            e.frontier_interpretation_note
            IS DISTINCT FROM f.frontier_interpretation_note
        ) AS frontier_interpretation_note_mismatch_flag,

        (
            e.top_reason_code_delta_driver_family
            IS DISTINCT FROM f.top_reason_code_delta_driver_family
        ) AS top_reason_code_delta_driver_family_mismatch_flag,

        (
            e.top_reason_code_delta_driver_code
            IS DISTINCT FROM f.top_reason_code_delta_driver_code
        ) AS top_reason_code_delta_driver_code_mismatch_flag,

        (
            e.top_reason_code_delta_driver_baseline_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_baseline_share
        ) AS top_reason_code_delta_driver_baseline_share_mismatch_flag,

        (
            e.top_reason_code_delta_driver_strategy_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_strategy_share
        ) AS top_reason_code_delta_driver_strategy_share_mismatch_flag,

        (
            e.top_reason_code_delta_population_share
            IS DISTINCT FROM f.top_reason_code_delta_population_share
        ) AS top_reason_code_delta_population_share_mismatch_flag,

        /*******************************************************************************************
        Field-level mismatch flags — Option C frontier fields.

        These flags determine whether Section 16.9D should refresh the Option C evidence fields in
        the persistent executive evidence table.
        *******************************************************************************************/
        (
            e.counteroffer_strategy_variant
            IS DISTINCT FROM f.counteroffer_strategy_variant
        ) AS counteroffer_strategy_variant_mismatch_flag,

        (
            e.aggressive_counteroffer_expansion_enabled
            IS DISTINCT FROM f.aggressive_counteroffer_expansion_enabled
        ) AS aggressive_counteroffer_expansion_enabled_mismatch_flag,

        (
            e.ordinary_counteroffer_candidate_rows
            IS DISTINCT FROM f.ordinary_counteroffer_candidate_rows
        ) AS ordinary_counteroffer_candidate_rows_mismatch_flag,

        (
            e.ordinary_counteroffer_candidate_rate
            IS DISTINCT FROM f.ordinary_counteroffer_candidate_rate
        ) AS ordinary_counteroffer_candidate_rate_mismatch_flag,

        (
            e.delta_ordinary_counteroffer_candidate_rate
            IS DISTINCT FROM f.delta_ordinary_counteroffer_candidate_rate
        ) AS delta_ordinary_counteroffer_candidate_rate_mismatch_flag,

        (
            e.aggressive_override_rows
            IS DISTINCT FROM f.aggressive_override_rows
        ) AS aggressive_override_rows_mismatch_flag,

        (
            e.aggressive_override_rate
            IS DISTINCT FROM f.aggressive_override_rate
        ) AS aggressive_override_rate_mismatch_flag,

        (
            e.delta_aggressive_override_rate
            IS DISTINCT FROM f.delta_aggressive_override_rate
        ) AS delta_aggressive_override_rate_mismatch_flag,

        (
            e.aggressive_override_final_counteroffer_rows
            IS DISTINCT FROM f.aggressive_override_final_counteroffer_rows
        ) AS aggressive_override_final_counteroffer_rows_mismatch_flag,

        (
            e.aggressive_override_final_counteroffer_rate
            IS DISTINCT FROM f.aggressive_override_final_counteroffer_rate
        ) AS aggressive_override_final_counteroffer_rate_mismatch_flag,

        (
            e.delta_aggressive_override_final_counteroffer_rate
            IS DISTINCT FROM f.delta_aggressive_override_final_counteroffer_rate
        ) AS delta_aggressive_override_final_counteroffer_rate_mismatch_flag,

        (
            e.aggressive_override_final_manual_review_rows
            IS DISTINCT FROM f.aggressive_override_final_manual_review_rows
        ) AS aggressive_override_final_manual_review_rows_mismatch_flag,

        (
            e.aggressive_override_final_manual_review_rate
            IS DISTINCT FROM f.aggressive_override_final_manual_review_rate
        ) AS aggressive_override_final_manual_review_rate_mismatch_flag,

        (
            e.aggressive_override_final_decline_rows
            IS DISTINCT FROM f.aggressive_override_final_decline_rows
        ) AS aggressive_override_final_decline_rows_mismatch_flag,

        (
            e.aggressive_override_final_decline_rate
            IS DISTINCT FROM f.aggressive_override_final_decline_rate
        ) AS aggressive_override_final_decline_rate_mismatch_flag,

        (
            e.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
            IS DISTINCT FROM f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
        ) AS avg_agr_ovr_co_exposure_reduction_pct_mismatch_flag,

        (
            e.avg_approved_pti_for_aggressive_override_counteroffers
            IS DISTINCT FROM f.avg_approved_pti_for_aggressive_override_counteroffers
        ) AS avg_agr_ovr_co_approved_pti_mismatch_flag,

        (
            e.avg_approved_el_for_aggressive_override_counteroffers
            IS DISTINCT FROM f.avg_approved_el_for_aggressive_override_counteroffers
        ) AS avg_agr_ovr_co_approved_el_mismatch_flag,

        (
            e.option_c_frontier_posture_type
            IS DISTINCT FROM f.option_c_frontier_posture_type
        ) AS option_c_frontier_posture_type_mismatch_flag,

        (
            e.option_c_frontier_interpretation_note
            IS DISTINCT FROM f.option_c_frontier_interpretation_note
        ) AS option_c_frontier_interpretation_note_mismatch_flag

    FROM credit_decisioning_sim.strategy_run_evidence_summary e

    LEFT JOIN tmp_m2_strategy_frontier_executive_summary f
        ON f.strategy_set_name = e.strategy_set_name
       AND f.strategy_name = e.strategy_name
       AND f.strategy_version = e.strategy_version
       AND f.module1_scenario_set_name = e.module1_scenario_set_name
       AND f.module1_scenario_name = e.module1_scenario_name
       AND f.population_id = e.population_id
),

field_counted AS (
    SELECT
        fc.*,

        /*******************************************************************************************
        Count only mismatches for matched frontier rows.

        Unmatched rows are reviewed separately and are not updated.

        This count now includes:
            standard frontier posture fields,
            reason-code movement fields,
            and Option C selective/aggressive counteroffer frontier fields.
        *******************************************************************************************/
        CASE
            WHEN fc.frontier_match_flag IS TRUE
                THEN (
                    fc.frontier_position_type_mismatch_flag::INT
                    + fc.executive_frontier_quadrant_mismatch_flag::INT
                    + fc.frontier_interpretation_note_mismatch_flag::INT
                    + fc.top_reason_code_delta_driver_family_mismatch_flag::INT
                    + fc.top_reason_code_delta_driver_code_mismatch_flag::INT
                    + fc.top_reason_code_delta_driver_baseline_share_mismatch_flag::INT
                    + fc.top_reason_code_delta_driver_strategy_share_mismatch_flag::INT
                    + fc.top_reason_code_delta_population_share_mismatch_flag::INT

                    + fc.counteroffer_strategy_variant_mismatch_flag::INT
                    + fc.aggressive_counteroffer_expansion_enabled_mismatch_flag::INT
                    + fc.ordinary_counteroffer_candidate_rows_mismatch_flag::INT
                    + fc.ordinary_counteroffer_candidate_rate_mismatch_flag::INT
                    + fc.delta_ordinary_counteroffer_candidate_rate_mismatch_flag::INT
                    + fc.aggressive_override_rows_mismatch_flag::INT
                    + fc.aggressive_override_rate_mismatch_flag::INT
                    + fc.delta_aggressive_override_rate_mismatch_flag::INT
                    + fc.aggressive_override_final_counteroffer_rows_mismatch_flag::INT
                    + fc.aggressive_override_final_counteroffer_rate_mismatch_flag::INT
                    + fc.delta_aggressive_override_final_counteroffer_rate_mismatch_flag::INT
                    + fc.aggressive_override_final_manual_review_rows_mismatch_flag::INT
                    + fc.aggressive_override_final_manual_review_rate_mismatch_flag::INT
                    + fc.aggressive_override_final_decline_rows_mismatch_flag::INT
                    + fc.aggressive_override_final_decline_rate_mismatch_flag::INT
                    + fc.avg_agr_ovr_co_exposure_reduction_pct_mismatch_flag::INT
                    + fc.avg_agr_ovr_co_approved_pti_mismatch_flag::INT
                    + fc.avg_agr_ovr_co_approved_el_mismatch_flag::INT
                    + fc.option_c_frontier_posture_type_mismatch_flag::INT
                    + fc.option_c_frontier_interpretation_note_mismatch_flag::INT
                )
            ELSE NULL
        END AS frontier_field_mismatch_count

    FROM field_compare fc
)

SELECT
    fcnt.*,

    /***********************************************************************************************
    Row-level synchronization action.

    SYNC_FRONTIER_FIELDS_FROM_SECTION_15 now means at least one Section 15-derived field differs,
    including Option C frontier fields.
    ***********************************************************************************************/
    CASE
        WHEN fcnt.frontier_match_flag IS DISTINCT FROM TRUE
            THEN 'NO_MATCHING_SECTION_15_FRONTIER_ROW_REVIEW'

        WHEN COALESCE(fcnt.frontier_field_mismatch_count, 0) > 0
            THEN 'SYNC_FRONTIER_FIELDS_FROM_SECTION_15'

        ELSE 'FRONTIER_FIELDS_ALREADY_CURRENT'
    END AS frontier_sync_action

FROM field_counted fcnt;
```

## What changed in plain terms

This replacement does four things inside **16.9C**:

1. It adds the current persistent Option C evidence fields from `strategy_run_evidence_summary`.
2. It adds the fresh Section 15 Option C fields from `tmp_m2_strategy_frontier_executive_summary`.
3. It adds Option C `IS DISTINCT FROM` mismatch flags.
4. It updates `frontier_field_mismatch_count` so `SYNC_FRONTIER_FIELDS_FROM_SECTION_15` triggers when **either** old frontier fields **or** Option C fields differ.

The shorter aliases for the three average metrics are intentional:

```sql
section15_avg_agr_ovr_co_exposure_reduction_pct
section15_avg_agr_ovr_co_approved_pti
section15_avg_agr_ovr_co_approved_el
```

Use those same aliases in **16.9D** when you update the evidence table.
<!-- END_MESSAGE C034-M01149 -->


---

<a id="c034-m01150"></a>

### C034-M01150

**Andrew** · 2026-05-16T20:04:54.617000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01150 -->
when you say: The shorter aliases for the three average metrics are intentional:

section15_avg_agr_ovr_co_exposure_reduction_pct
section15_avg_agr_ovr_co_approved_pti
section15_avg_agr_ovr_co_approved_el

Use those same aliases in 16.9D when you update the evidence table.   - please make remaining section 16.9.D through the end of 16.9 updates easier, including any above updates I have not incorporated.  here is the code as it currently is.  provide a full copy paste for this remaining 16.9.
<!-- END_MESSAGE C034-M01150 -->


**Attachments in export:** `Pasted text(208).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01158"></a>

### C034-M01158

**ChatGPT** · 2026-05-16T20:11:23.990434-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01158 -->
According to a document from **2026-05-17**, your current Section 16.9 already frames the post-campaign sync correctly: it refreshes Section 15-derived frontier fields in `credit_decisioning_sim.strategy_run_evidence_summary`, and it now lists the Option C fields as part of the intended refresh set. The remaining issue is that 16.9D onward still needs to actually update, post-check, display, and summarize those Option C fields. fileciteturn282file0turn282file1

Replace everything from:

```sql
SECTION 16.9D — APPLY FRONTIER FIELD SYNCHRONIZATION
```

through:

```sql
END OF SECTION 16.9 — POST-CAMPAIGN FRONTIER EVIDENCE SYNCHRONIZATION
```

with the full copy-paste block below.

This assumes your updated **16.9C** candidate table includes the shorter aliases we discussed:

```sql
section15_avg_agr_ovr_co_exposure_reduction_pct
section15_avg_agr_ovr_co_approved_pti
section15_avg_agr_ovr_co_approved_el
```

```sql
/***************************************************************************************************
SECTION 16.9D — APPLY FRONTIER FIELD SYNCHRONIZATION
****************************************************************************************************

PURPOSE:
    Update only matched evidence rows where Section 15-derived frontier fields differ.

SQL LOGIC:
    UPDATE uses the candidate table built in Section 16.9C.

    Rows with no matching Section 15 frontier row are not updated.

OPTION C UPDATE NOTE:
    Section 16.9D now refreshes both:

        1. Standard Section 15 frontier fields:
            frontier_position_type
            executive_frontier_quadrant
            frontier_interpretation_note
            top reason-code delta driver fields

        2. Option C selective/aggressive counteroffer frontier fields:
            counteroffer_strategy_variant
            aggressive_counteroffer_expansion_enabled
            ordinary counteroffer candidate metrics
            aggressive override metrics
            aggressive override final outcome mix
            aggressive override approved-exposure quality metrics
            Option C frontier posture labels

WHY SHORT SECTION 15 ALIASES ARE USED:
    PostgreSQL object identifiers are limited to 63 bytes.

    The three aggressive-override average metric names are long, so Section 16.9C should expose
    shorter candidate-table aliases:

        section15_avg_agr_ovr_co_exposure_reduction_pct
        section15_avg_agr_ovr_co_approved_pti
        section15_avg_agr_ovr_co_approved_el

    This section uses those aliases when updating the persistent evidence table.

BOUNDARY:
    Section 16.9D updates only deterministic Section 15-derived frontier evidence fields.

    It does not update:
        latest-run rows,
        archive rows,
        validation evidence rows,
        parameter snapshots,
        segment evidence rows,
        observed_storyline,
        validation_notes,
        strategy parameters,
        product-policy parameters,
        decision outcomes,
        approved exposure,
        approved Expected Loss,
        or simulated reason codes.
***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_frontier_evidence_sync_update_result;

CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_update_result
ON COMMIT PRESERVE ROWS
AS
WITH updated AS (
    UPDATE credit_decisioning_sim.strategy_run_evidence_summary e
    SET
        /*******************************************************************************************
        Standard frontier posture fields.
        *******************************************************************************************/
        frontier_position_type =
            c.section15_frontier_position_type,

        executive_frontier_quadrant =
            c.section15_executive_frontier_quadrant,

        frontier_interpretation_note =
            c.section15_frontier_interpretation_note,

        /*******************************************************************************************
        Baseline-relative reason-code movement fields.
        *******************************************************************************************/
        top_reason_code_delta_driver_family =
            c.section15_top_reason_code_delta_driver_family,

        top_reason_code_delta_driver_code =
            c.section15_top_reason_code_delta_driver_code,

        top_reason_code_delta_driver_baseline_share =
            c.section15_top_reason_code_delta_driver_baseline_share,

        top_reason_code_delta_driver_strategy_share =
            c.section15_top_reason_code_delta_driver_strategy_share,

        top_reason_code_delta_population_share =
            c.section15_top_reason_code_delta_population_share,

        /*******************************************************************************************
        Option C counteroffer strategy split frontier fields.

        These values come from the fresh Section 15 archive-wide frontier output.

        They preserve the persistent executive evidence needed to distinguish:

            SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
            from
            AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

        at the frontier evidence layer.
        *******************************************************************************************/
        counteroffer_strategy_variant =
            c.section15_counteroffer_strategy_variant,

        aggressive_counteroffer_expansion_enabled =
            c.section15_aggressive_counteroffer_expansion_enabled,

        ordinary_counteroffer_candidate_rows =
            c.section15_ordinary_counteroffer_candidate_rows,

        ordinary_counteroffer_candidate_rate =
            c.section15_ordinary_counteroffer_candidate_rate,

        delta_ordinary_counteroffer_candidate_rate =
            c.section15_delta_ordinary_counteroffer_candidate_rate,

        aggressive_override_rows =
            c.section15_aggressive_override_rows,

        aggressive_override_rate =
            c.section15_aggressive_override_rate,

        delta_aggressive_override_rate =
            c.section15_delta_aggressive_override_rate,

        aggressive_override_final_counteroffer_rows =
            c.section15_aggressive_override_final_counteroffer_rows,

        aggressive_override_final_counteroffer_rate =
            c.section15_aggressive_override_final_counteroffer_rate,

        delta_aggressive_override_final_counteroffer_rate =
            c.section15_delta_aggressive_override_final_counteroffer_rate,

        aggressive_override_final_manual_review_rows =
            c.section15_aggressive_override_final_manual_review_rows,

        aggressive_override_final_manual_review_rate =
            c.section15_aggressive_override_final_manual_review_rate,

        aggressive_override_final_decline_rows =
            c.section15_aggressive_override_final_decline_rows,

        aggressive_override_final_decline_rate =
            c.section15_aggressive_override_final_decline_rate,

        avg_exposure_reduction_pct_for_aggressive_override_counteroffers =
            c.section15_avg_agr_ovr_co_exposure_reduction_pct,

        avg_approved_pti_for_aggressive_override_counteroffers =
            c.section15_avg_agr_ovr_co_approved_pti,

        avg_approved_el_for_aggressive_override_counteroffers =
            c.section15_avg_agr_ovr_co_approved_el,

        option_c_frontier_posture_type =
            c.section15_option_c_frontier_posture_type,

        option_c_frontier_interpretation_note =
            c.section15_option_c_frontier_interpretation_note

    FROM tmp_m2_frontier_evidence_sync_candidates c

    WHERE c.frontier_match_flag IS TRUE
      AND COALESCE(c.frontier_field_mismatch_count, 0) > 0

      AND e.strategy_set_name = c.strategy_set_name
      AND e.strategy_name = c.strategy_name
      AND e.strategy_version = c.strategy_version
      AND e.module1_scenario_set_name = c.module1_scenario_set_name
      AND e.module1_scenario_name = c.module1_scenario_name
      AND e.population_id = c.population_id

    RETURNING
        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,

        e.module1_run_id,
        e.module2_run_id,
        e.run_sequence_number,
        e.showcase_id,
        e.showcase_name,
        e.comparison_group_id,
        e.validation_evidence_group_id
)

SELECT
    CURRENT_TIMESTAMP AS frontier_evidence_sync_ts,
    COUNT(*) AS evidence_rows_updated
FROM updated;



/***************************************************************************************************
SECTION 16.9E — POST-SYNCHRONIZATION CHECK
****************************************************************************************************

PURPOSE:
    Confirm that every persistent executive evidence row with a matching fresh Section 15 frontier row
    now has aligned Section 15-derived frontier fields.

SQL LOGIC:
    1. Recompare persistent evidence rows to tmp_m2_strategy_frontier_executive_summary.
    2. Build row-level mismatch flags.
    3. Count standard frontier mismatches and Option C frontier mismatches separately.
    4. Materialize a one-row postcheck summary for Section 16.9F and Section 16.9G.

WHY THIS CHECK EXISTS:
    Section 16.9D is an UPDATE.

    This postcheck proves that the update aligned matched evidence rows to the fresh Section 15
    frontier output.

OPTION C POSTCHECK NOTE:
    The postcheck validates both old and new Section 15-derived fields.

    That means a row is not considered synchronized until it matches Section 15 across:
        standard frontier labels,
        executive quadrant,
        reason-code movement fields,
        ordinary counteroffer candidacy metrics,
        aggressive override metrics,
        aggressive override outcome mix,
        aggressive override quality metrics,
        and Option C frontier posture labels.

BOUNDARY:
    Unmatched evidence rows do not fail automatically.

    They remain review items because they may represent custom, non-campaign, legacy, or otherwise
    out-of-scope evidence rows.
***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_frontier_evidence_sync_postcheck_detail;
DROP TABLE IF EXISTS tmp_m2_frontier_evidence_sync_postcheck;


CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_postcheck_detail
ON COMMIT PRESERVE ROWS
AS
WITH post_compare AS (
    SELECT
        /*******************************************************************************************
        Technical run key.
        *******************************************************************************************/
        e.strategy_set_name,
        e.strategy_name,
        e.strategy_version,
        e.module1_scenario_set_name,
        e.module1_scenario_name,
        e.population_id,

        /*******************************************************************************************
        Campaign / documentation identifiers.
        *******************************************************************************************/
        e.module1_run_id,
        e.module2_run_id,
        e.run_sequence_number,
        e.showcase_id,
        e.showcase_name,
        e.comparison_group_id,
        e.validation_evidence_group_id,

        /*******************************************************************************************
        Match diagnostic.
        *******************************************************************************************/
        CASE
            WHEN f.strategy_set_name IS NOT NULL
                THEN TRUE
            ELSE FALSE
        END AS frontier_match_flag,

        /*******************************************************************************************
        Standard frontier mismatch flags.
        *******************************************************************************************/
        (
            e.frontier_position_type
            IS DISTINCT FROM f.frontier_position_type
        ) AS frontier_position_type_mismatch_flag,

        (
            e.executive_frontier_quadrant
            IS DISTINCT FROM f.executive_frontier_quadrant
        ) AS executive_frontier_quadrant_mismatch_flag,

        (
            e.frontier_interpretation_note
            IS DISTINCT FROM f.frontier_interpretation_note
        ) AS frontier_interpretation_note_mismatch_flag,

        (
            e.top_reason_code_delta_driver_family
            IS DISTINCT FROM f.top_reason_code_delta_driver_family
        ) AS top_reason_code_delta_driver_family_mismatch_flag,

        (
            e.top_reason_code_delta_driver_code
            IS DISTINCT FROM f.top_reason_code_delta_driver_code
        ) AS top_reason_code_delta_driver_code_mismatch_flag,

        (
            e.top_reason_code_delta_driver_baseline_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_baseline_share
        ) AS top_reason_code_delta_driver_baseline_share_mismatch_flag,

        (
            e.top_reason_code_delta_driver_strategy_share
            IS DISTINCT FROM f.top_reason_code_delta_driver_strategy_share
        ) AS top_reason_code_delta_driver_strategy_share_mismatch_flag,

        (
            e.top_reason_code_delta_population_share
            IS DISTINCT FROM f.top_reason_code_delta_population_share
        ) AS top_reason_code_delta_population_share_mismatch_flag,

        /*******************************************************************************************
        Option C frontier mismatch flags.
        *******************************************************************************************/
        (
            e.counteroffer_strategy_variant
            IS DISTINCT FROM f.counteroffer_strategy_variant
        ) AS counteroffer_strategy_variant_mismatch_flag,

        (
            e.aggressive_counteroffer_expansion_enabled
            IS DISTINCT FROM f.aggressive_counteroffer_expansion_enabled
        ) AS aggressive_counteroffer_expansion_enabled_mismatch_flag,

        (
            e.ordinary_counteroffer_candidate_rows
            IS DISTINCT FROM f.ordinary_counteroffer_candidate_rows
        ) AS ordinary_counteroffer_candidate_rows_mismatch_flag,

        (
            e.ordinary_counteroffer_candidate_rate
            IS DISTINCT FROM f.ordinary_counteroffer_candidate_rate
        ) AS ordinary_counteroffer_candidate_rate_mismatch_flag,

        (
            e.delta_ordinary_counteroffer_candidate_rate
            IS DISTINCT FROM f.delta_ordinary_counteroffer_candidate_rate
        ) AS delta_ordinary_counteroffer_candidate_rate_mismatch_flag,

        (
            e.aggressive_override_rows
            IS DISTINCT FROM f.aggressive_override_rows
        ) AS aggressive_override_rows_mismatch_flag,

        (
            e.aggressive_override_rate
            IS DISTINCT FROM f.aggressive_override_rate
        ) AS aggressive_override_rate_mismatch_flag,

        (
            e.delta_aggressive_override_rate
            IS DISTINCT FROM f.delta_aggressive_override_rate
        ) AS delta_aggressive_override_rate_mismatch_flag,

        (
            e.aggressive_override_final_counteroffer_rows
            IS DISTINCT FROM f.aggressive_override_final_counteroffer_rows
        ) AS aggressive_override_final_counteroffer_rows_mismatch_flag,

        (
            e.aggressive_override_final_counteroffer_rate
            IS DISTINCT FROM f.aggressive_override_final_counteroffer_rate
        ) AS aggressive_override_final_counteroffer_rate_mismatch_flag,

        (
            e.delta_aggressive_override_final_counteroffer_rate
            IS DISTINCT FROM f.delta_aggressive_override_final_counteroffer_rate
        ) AS delta_aggressive_override_final_counteroffer_rate_mismatch_flag,

        (
            e.aggressive_override_final_manual_review_rows
            IS DISTINCT FROM f.aggressive_override_final_manual_review_rows
        ) AS aggressive_override_final_manual_review_rows_mismatch_flag,

        (
            e.aggressive_override_final_manual_review_rate
            IS DISTINCT FROM f.aggressive_override_final_manual_review_rate
        ) AS aggressive_override_final_manual_review_rate_mismatch_flag,

        (
            e.aggressive_override_final_decline_rows
            IS DISTINCT FROM f.aggressive_override_final_decline_rows
        ) AS aggressive_override_final_decline_rows_mismatch_flag,

        (
            e.aggressive_override_final_decline_rate
            IS DISTINCT FROM f.aggressive_override_final_decline_rate
        ) AS aggressive_override_final_decline_rate_mismatch_flag,

        (
            e.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
            IS DISTINCT FROM f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
        ) AS avg_agr_ovr_co_exposure_reduction_pct_mismatch_flag,

        (
            e.avg_approved_pti_for_aggressive_override_counteroffers
            IS DISTINCT FROM f.avg_approved_pti_for_aggressive_override_counteroffers
        ) AS avg_agr_ovr_co_approved_pti_mismatch_flag,

        (
            e.avg_approved_el_for_aggressive_override_counteroffers
            IS DISTINCT FROM f.avg_approved_el_for_aggressive_override_counteroffers
        ) AS avg_agr_ovr_co_approved_el_mismatch_flag,

        (
            e.option_c_frontier_posture_type
            IS DISTINCT FROM f.option_c_frontier_posture_type
        ) AS option_c_frontier_posture_type_mismatch_flag,

        (
            e.option_c_frontier_interpretation_note
            IS DISTINCT FROM f.option_c_frontier_interpretation_note
        ) AS option_c_frontier_interpretation_note_mismatch_flag

    FROM credit_decisioning_sim.strategy_run_evidence_summary e

    LEFT JOIN tmp_m2_strategy_frontier_executive_summary f
        ON f.strategy_set_name = e.strategy_set_name
       AND f.strategy_name = e.strategy_name
       AND f.strategy_version = e.strategy_version
       AND f.module1_scenario_set_name = e.module1_scenario_set_name
       AND f.module1_scenario_name = e.module1_scenario_name
       AND f.population_id = e.population_id
),

post_counted AS (
    SELECT
        pc.*,

        /*******************************************************************************************
        Standard frontier mismatch count.

        Counted only for evidence rows that matched a fresh Section 15 frontier row.
        *******************************************************************************************/
        CASE
            WHEN pc.frontier_match_flag IS TRUE
                THEN (
                    pc.frontier_position_type_mismatch_flag::INT
                    + pc.executive_frontier_quadrant_mismatch_flag::INT
                    + pc.frontier_interpretation_note_mismatch_flag::INT
                    + pc.top_reason_code_delta_driver_family_mismatch_flag::INT
                    + pc.top_reason_code_delta_driver_code_mismatch_flag::INT
                    + pc.top_reason_code_delta_driver_baseline_share_mismatch_flag::INT
                    + pc.top_reason_code_delta_driver_strategy_share_mismatch_flag::INT
                    + pc.top_reason_code_delta_population_share_mismatch_flag::INT
                )
            ELSE NULL
        END AS standard_frontier_field_mismatch_count,

        /*******************************************************************************************
        Option C frontier mismatch count.

        Counted only for evidence rows that matched a fresh Section 15 frontier row.
        *******************************************************************************************/
        CASE
            WHEN pc.frontier_match_flag IS TRUE
                THEN (
                    pc.counteroffer_strategy_variant_mismatch_flag::INT
                    + pc.aggressive_counteroffer_expansion_enabled_mismatch_flag::INT
                    + pc.ordinary_counteroffer_candidate_rows_mismatch_flag::INT
                    + pc.ordinary_counteroffer_candidate_rate_mismatch_flag::INT
                    + pc.delta_ordinary_counteroffer_candidate_rate_mismatch_flag::INT
                    + pc.aggressive_override_rows_mismatch_flag::INT
                    + pc.aggressive_override_rate_mismatch_flag::INT
                    + pc.delta_aggressive_override_rate_mismatch_flag::INT
                    + pc.aggressive_override_final_counteroffer_rows_mismatch_flag::INT
                    + pc.aggressive_override_final_counteroffer_rate_mismatch_flag::INT
                    + pc.delta_aggressive_override_final_counteroffer_rate_mismatch_flag::INT
                    + pc.aggressive_override_final_manual_review_rows_mismatch_flag::INT
                    + pc.aggressive_override_final_manual_review_rate_mismatch_flag::INT
                    + pc.aggressive_override_final_decline_rows_mismatch_flag::INT
                    + pc.aggressive_override_final_decline_rate_mismatch_flag::INT
                    + pc.avg_agr_ovr_co_exposure_reduction_pct_mismatch_flag::INT
                    + pc.avg_agr_ovr_co_approved_pti_mismatch_flag::INT
                    + pc.avg_agr_ovr_co_approved_el_mismatch_flag::INT
                    + pc.option_c_frontier_posture_type_mismatch_flag::INT
                    + pc.option_c_frontier_interpretation_note_mismatch_flag::INT
                )
            ELSE NULL
        END AS option_c_frontier_field_mismatch_count

    FROM post_compare pc
)

SELECT
    pcnt.*,

    /***********************************************************************************************
    Total frontier mismatch count.

    This is the value used by the fail-fast postcheck.
    ***********************************************************************************************/
    CASE
        WHEN pcnt.frontier_match_flag IS TRUE
            THEN (
                COALESCE(pcnt.standard_frontier_field_mismatch_count, 0)
                + COALESCE(pcnt.option_c_frontier_field_mismatch_count, 0)
            )
        ELSE NULL
    END AS frontier_field_mismatch_count

FROM post_counted pcnt;



CREATE TEMP TABLE tmp_m2_frontier_evidence_sync_postcheck
ON COMMIT PRESERVE ROWS
AS
WITH post_summary AS (
    SELECT
        COUNT(*) AS evidence_rows_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS TRUE
        ) AS matched_evidence_rows_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS DISTINCT FROM TRUE
        ) AS unmatched_evidence_rows_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS TRUE
              AND COALESCE(standard_frontier_field_mismatch_count, 0) > 0
        ) AS matched_rows_with_standard_frontier_mismatch_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS TRUE
              AND COALESCE(option_c_frontier_field_mismatch_count, 0) > 0
        ) AS matched_rows_with_option_c_frontier_mismatch_after_sync,

        COUNT(*) FILTER (
            WHERE frontier_match_flag IS TRUE
              AND COALESCE(frontier_field_mismatch_count, 0) > 0
        ) AS matched_rows_with_frontier_mismatch_after_sync,

        COALESCE(
            SUM(frontier_field_mismatch_count) FILTER (
                WHERE frontier_match_flag IS TRUE
            ),
            0
        ) AS total_matched_frontier_field_mismatches_after_sync

    FROM tmp_m2_frontier_evidence_sync_postcheck_detail
)

SELECT
    CURRENT_TIMESTAMP AS frontier_evidence_postcheck_ts,

    u.frontier_evidence_sync_ts,
    u.evidence_rows_updated,

    ps.evidence_rows_after_sync,
    ps.matched_evidence_rows_after_sync,
    ps.unmatched_evidence_rows_after_sync,

    ps.matched_rows_with_standard_frontier_mismatch_after_sync,
    ps.matched_rows_with_option_c_frontier_mismatch_after_sync,
    ps.matched_rows_with_frontier_mismatch_after_sync,
    ps.total_matched_frontier_field_mismatches_after_sync,

    CASE
        WHEN ps.matched_evidence_rows_after_sync = 0
            THEN 'FRONTIER_EVIDENCE_SYNC_REVIEW_NO_MATCHING_SECTION_15_FRONTIER_ROWS'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync = 0
            THEN 'FRONTIER_EVIDENCE_SYNC_READY_ALL_EVIDENCE_ROWS_MATCH_SECTION_15'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync > 0
            THEN 'FRONTIER_EVIDENCE_SYNC_READY_WITH_UNMATCHED_EVIDENCE_ROWS_REVIEW'

        ELSE 'FRONTIER_EVIDENCE_SYNC_MISMATCH_REVIEW_REQUIRED'
    END AS frontier_evidence_sync_status,

    CASE
        WHEN ps.matched_evidence_rows_after_sync = 0
            THEN 'No persistent executive evidence rows matched the fresh Section 15 frontier output. Confirm Section 15 was rerun from the completed archive and evidence rows use the same technical run keys.'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync = 0
            THEN 'All persistent executive evidence rows match the fresh Section 15 frontier output, including Option C selective/aggressive counteroffer frontier fields.'

        WHEN ps.matched_rows_with_frontier_mismatch_after_sync = 0
         AND ps.unmatched_evidence_rows_after_sync > 0
            THEN 'All matched evidence rows were synchronized. Unmatched evidence rows remain for review; these may be custom, non-archived, or legacy evidence rows.'

        ELSE 'One or more matched evidence rows still differ from Section 15 output after synchronization. Review standard and Option C mismatch counts.'
    END AS frontier_evidence_sync_interpretation

FROM post_summary ps

CROSS JOIN tmp_m2_frontier_evidence_sync_update_result u;



/***************************************************************************************************
SECTION 16.9F — POST-SYNCHRONIZATION FAIL-FAST CHECK
****************************************************************************************************

PURPOSE:
    Fail only when matched evidence rows still disagree with fresh Section 15 output.

BOUNDARY:
    Unmatched evidence rows do not fail this section automatically.

    They are review items because they may represent custom, non-campaign, legacy, or otherwise
    out-of-scope evidence rows.

OPTION C NOTE:
    This fail-fast check now includes Option C frontier fields.

    A matched row is not synchronized unless both standard frontier fields and Option C
    selective/aggressive counteroffer frontier fields match the fresh Section 15 output.

***************************************************************************************************/

DO $$
DECLARE
    v_matched_rows_after_sync                  BIGINT;
    v_matched_mismatch_rows_after_sync         BIGINT;
    v_sync_status                              TEXT;
BEGIN
    SELECT
        matched_evidence_rows_after_sync,
        matched_rows_with_frontier_mismatch_after_sync,
        frontier_evidence_sync_status
    INTO
        v_matched_rows_after_sync,
        v_matched_mismatch_rows_after_sync,
        v_sync_status
    FROM tmp_m2_frontier_evidence_sync_postcheck
    LIMIT 1;

    IF v_matched_rows_after_sync = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: no persistent executive evidence rows matched fresh Section 15 frontier output.';
    END IF;

    IF v_matched_mismatch_rows_after_sync > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16.9 failure: % matched evidence row(s) still disagree with fresh Section 15 frontier output after synchronization. Status: %.',
            v_matched_mismatch_rows_after_sync,
            v_sync_status;
    END IF;
END $$;



/***************************************************************************************************
SECTION 16.9G — FRONTIER SYNCHRONIZATION REVIEW OUTPUTS
****************************************************************************************************

PURPOSE:
    Display the synchronization result and the rows that were updated or still require review.

SQL PURPOSE:
    1. Display one compact synchronization status row.
    2. Display rows updated by synchronization.
    3. Display unmatched persistent evidence rows, if any.
    4. Display matched evidence rows after synchronization.
    5. Display Option C selective/aggressive counteroffer frontier synchronization evidence.

BOUNDARY:
    These are review outputs only.

    They do not update evidence rows.
    They do not recalculate Section 15.
    They do not modify archive or latest-run rows.
***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.9G.1 Synchronization status summary.

Expected:
    frontier_evidence_sync_status should be either:
        FRONTIER_EVIDENCE_SYNC_READY_ALL_EVIDENCE_ROWS_MATCH_SECTION_15
        FRONTIER_EVIDENCE_SYNC_READY_WITH_UNMATCHED_EVIDENCE_ROWS_REVIEW

Interpretation:
    evidence_rows_updated:
        number of executive evidence rows refreshed from Section 15.

    matched_rows_with_option_c_frontier_mismatch_after_sync:
        should be zero after synchronization.

    unmatched_evidence_rows_after_sync:
        evidence rows with no matching current Section 15 frontier row.
-----------------------------------------------------------------------------------------------*/

SELECT
    *
FROM tmp_m2_frontier_evidence_sync_postcheck;



/*-----------------------------------------------------------------------------------------------
16.9G.2 Rows updated by synchronization.

Purpose:
    Show the rows whose persistent evidence frontier fields were stale before this sync.

Interpretation:
    These rows are expected after campaign reruns or when early campaign evidence was captured before
    all comparison slices were archived.

Option C note:
    frontier_field_mismatch_count includes standard frontier fields and Option C frontier fields.
-----------------------------------------------------------------------------------------------*/

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
    population_id,

    frontier_field_mismatch_count,

    /***********************************************************************************************
    Standard frontier fields before / after.
    ***********************************************************************************************/
    evidence_frontier_position_type,
    section15_frontier_position_type,

    evidence_executive_frontier_quadrant,
    section15_executive_frontier_quadrant,

    evidence_frontier_interpretation_note,
    section15_frontier_interpretation_note,

    evidence_top_reason_code_delta_driver_family,
    section15_top_reason_code_delta_driver_family,

    evidence_top_reason_code_delta_driver_code,
    section15_top_reason_code_delta_driver_code,

    evidence_top_reason_code_delta_population_share,
    section15_top_reason_code_delta_population_share,

    /***********************************************************************************************
    Option C frontier fields before / after.
    ***********************************************************************************************/
    evidence_counteroffer_strategy_variant,
    section15_counteroffer_strategy_variant,

    evidence_aggressive_counteroffer_expansion_enabled,
    section15_aggressive_counteroffer_expansion_enabled,

    evidence_ordinary_counteroffer_candidate_rows,
    section15_ordinary_counteroffer_candidate_rows,

    evidence_ordinary_counteroffer_candidate_rate,
    section15_ordinary_counteroffer_candidate_rate,

    evidence_delta_ordinary_counteroffer_candidate_rate,
    section15_delta_ordinary_counteroffer_candidate_rate,

    evidence_aggressive_override_rows,
    section15_aggressive_override_rows,

    evidence_aggressive_override_rate,
    section15_aggressive_override_rate,

    evidence_delta_aggressive_override_rate,
    section15_delta_aggressive_override_rate,

    evidence_aggressive_override_final_counteroffer_rows,
    section15_aggressive_override_final_counteroffer_rows,

    evidence_aggressive_override_final_counteroffer_rate,
    section15_aggressive_override_final_counteroffer_rate,

    evidence_delta_aggressive_override_final_counteroffer_rate,
    section15_delta_aggressive_override_final_counteroffer_rate,

    evidence_option_c_frontier_posture_type,
    section15_option_c_frontier_posture_type,

    evidence_option_c_frontier_interpretation_note,
    section15_option_c_frontier_interpretation_note

FROM tmp_m2_frontier_evidence_sync_candidates

WHERE frontier_match_flag IS TRUE
  AND COALESCE(frontier_field_mismatch_count, 0) > 0

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    run_sequence_number NULLS LAST,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
16.9G.3 Unmatched persistent evidence rows.

Purpose:
    Show persistent executive evidence rows that did not have a matching fresh Section 15 frontier
    row.

Interpretation:
    These are review items, not automatic failures.

    They may represent:
        custom runs,
        old development runs,
        inactive campaign rows,
        non-archived evidence,
        or evidence rows outside the current Section 15 frontier scope.
-----------------------------------------------------------------------------------------------*/

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
    population_id,

    'NO_MATCHING_SECTION_15_FRONTIER_ROW_REVIEW' AS unmatched_evidence_status

FROM tmp_m2_frontier_evidence_sync_postcheck_detail

WHERE frontier_match_flag IS DISTINCT FROM TRUE

ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    run_sequence_number NULLS LAST,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
16.9G.4 Matched evidence rows after synchronization.

Purpose:
    Show the final synchronized frontier fields that will be consumed by Section 17 and executive
    evidence review.

Expected:
    Values from credit_decisioning_sim.strategy_run_evidence_summary should match the fresh Section
    15 frontier output for all matched rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    e.module1_run_id,
    e.module2_run_id,
    e.run_sequence_number,
    e.showcase_id,
    e.showcase_name,
    e.comparison_group_id,
    e.validation_evidence_group_id,

    e.strategy_set_name,
    e.strategy_name,
    e.strategy_version,
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,

    /***********************************************************************************************
    Standard synchronized frontier fields.
    ***********************************************************************************************/
    e.frontier_position_type,
    e.executive_frontier_quadrant,
    e.frontier_interpretation_note,

    e.top_reason_code_delta_driver_family,
    e.top_reason_code_delta_driver_code,
    e.top_reason_code_delta_driver_baseline_share,
    e.top_reason_code_delta_driver_strategy_share,
    e.top_reason_code_delta_population_share,

    /***********************************************************************************************
    Option C synchronized frontier fields.
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
    e.option_c_frontier_interpretation_note

FROM credit_decisioning_sim.strategy_run_evidence_summary e

JOIN tmp_m2_strategy_frontier_executive_summary f
    ON f.strategy_set_name = e.strategy_set_name
   AND f.strategy_name = e.strategy_name
   AND f.strategy_version = e.strategy_version
   AND f.module1_scenario_set_name = e.module1_scenario_set_name
   AND f.module1_scenario_name = e.module1_scenario_name
   AND f.population_id = e.population_id

ORDER BY
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,
    e.strategy_set_name,
    e.run_sequence_number NULLS LAST,
    CASE
        WHEN e.strategy_name = 'BASELINE_STRATEGY' THEN 1
        ELSE 2
    END,
    e.strategy_name,
    e.strategy_version;



/*-----------------------------------------------------------------------------------------------
16.9G.5 Option C frontier synchronization review.

Purpose:
    Display persistent evidence rows after synchronization for Option C frontier fields.

Interpretation:
    These fields should now match the fresh Section 15 frontier output for matched technical run keys.

    SELECTIVE_FEASIBILITY rows should generally show:
        aggressive_override_rows = 0

    AGGRESSIVE_EXPANSION rows may show:
        aggressive_override_rows > 0

    Those aggressive override rows may resolve to:
        COUNTEROFFER,
        MANUAL_REVIEW,
        or DECLINE

    depending on Section 8 feasibility and Section 9 final-resolution behavior.
-----------------------------------------------------------------------------------------------*/

SELECT
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,

    e.strategy_set_name,
    e.strategy_name,
    e.strategy_version,

    e.module2_run_id,
    e.run_sequence_number,
    e.showcase_id,
    e.comparison_group_id,

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
    e.option_c_frontier_interpretation_note

FROM credit_decisioning_sim.strategy_run_evidence_summary e

WHERE e.counteroffer_strategy_variant IN (
        'SELECTIVE_FEASIBILITY',
        'AGGRESSIVE_EXPANSION'
    )
   OR COALESCE(e.aggressive_override_rows, 0) > 0

ORDER BY
    e.module1_scenario_set_name,
    e.module1_scenario_name,
    e.population_id,
    e.run_sequence_number NULLS LAST,
    CASE
        WHEN e.counteroffer_strategy_variant = 'SELECTIVE_FEASIBILITY' THEN 1
        WHEN e.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION' THEN 2
        ELSE 3
    END,
    e.strategy_name,
    e.strategy_version;



/***************************************************************************************************
END OF SECTION 16.9 — POST-CAMPAIGN FRONTIER EVIDENCE SYNCHRONIZATION

If execution reaches this point:
    1. Fresh Section 15 frontier output exists.
    2. Persistent executive evidence exists.
    3. Section 15-derived standard frontier fields have been refreshed for all matching evidence rows.
    4. Section 15-derived Option C frontier fields have been refreshed for all matching evidence rows.
    5. Matched evidence rows now align with the fresh Section 15 frontier output.
    6. Unmatched evidence rows, if any, have been surfaced for review.
    7. Section 17 can be run for final post-campaign acceptance.

Post-campaign synchronization boundary:
    Section 16.9 may update only Section 15-derived frontier fields in:

        credit_decisioning_sim.strategy_run_evidence_summary

    Specifically, Section 16.9 may refresh:

        Standard frontier fields:
            frontier_position_type
            executive_frontier_quadrant
            frontier_interpretation_note
            top_reason_code_delta_driver_family
            top_reason_code_delta_driver_code
            top_reason_code_delta_driver_baseline_share
            top_reason_code_delta_driver_strategy_share
            top_reason_code_delta_population_share

        Option C counteroffer frontier fields:
            counteroffer_strategy_variant
            aggressive_counteroffer_expansion_enabled
            ordinary_counteroffer_candidate_rows
            ordinary_counteroffer_candidate_rate
            delta_ordinary_counteroffer_candidate_rate
            aggressive_override_rows
            aggressive_override_rate
            delta_aggressive_override_rate
            aggressive_override_final_counteroffer_rows
            aggressive_override_final_counteroffer_rate
            delta_aggressive_override_final_counteroffer_rate
            aggressive_override_final_manual_review_rows
            aggressive_override_final_manual_review_rate
            aggressive_override_final_decline_rows
            aggressive_override_final_decline_rate
            avg_exposure_reduction_pct_for_aggressive_override_counteroffers
            avg_approved_pti_for_aggressive_override_counteroffers
            avg_approved_el_for_aggressive_override_counteroffers
            option_c_frontier_posture_type
            option_c_frontier_interpretation_note

Option C note:
    Section 16.9 now synchronizes the persistent evidence needed to compare:

        SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
        against
        AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

    at the executive evidence layer.

    Section 16.9 does not decide whether aggressive expansion is better.

    It only ensures that persistent executive evidence reflects the fresh Section 15 archive-wide
    frontier output after the full campaign archive has been completed.

Read / write boundary:
    Section 16.9 does not modify latest-run output rows.
    Section 16.9 does not modify archive rows.
    Section 16.9 does not modify campaign registry rows.
    Section 16.9 does not modify validation evidence detail rows.
    Section 16.9 does not modify parameter snapshots.
    Section 16.9 does not modify product × score segment evidence.
    Section 16.9 does not modify strategy parameter rows.
    Section 16.9 does not modify product-policy parameter rows.
    Section 16.9 does not recalculate decision outcomes.
    Section 16.9 does not recalculate approved exposure values.
    Section 16.9 does not recalculate approved Expected Loss values.
    Section 16.9 does not reassign simulated reason codes.
    Section 16.9 does not implement revenue, earnings, pricing, funding-cost, profitability, capital,
    or risk-adjusted margin logic.

Next:
    Run Section 17 after reviewing the Section 16.9 synchronization summary.

***************************************************************************************************/
```

This replacement completes the remaining 16.9 work. The key functional additions are:

```text
16.9D:
    Updates all Option C frontier fields, not just legacy frontier fields.

16.9E:
    Rechecks all standard + Option C fields after synchronization.

16.9F:
    Fails if any matched evidence row still differs from fresh Section 15 output.

16.9G:
    Adds Option C-specific review visibility.

End summary:
    Correctly states that Option C frontier fields are now part of the synchronized evidence layer.
```
<!-- END_MESSAGE C034-M01158 -->


---

<a id="c034-m01160"></a>

### C034-M01160

**Andrew** · 2026-05-16T20:21:49.302000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01160 -->
please review section 16 one final time following logic, headers, comment changes (code attached).
<!-- END_MESSAGE C034-M01160 -->


**Attachments in export:** `Pasted text(209).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01166"></a>

### C034-M01166

**ChatGPT** · 2026-05-16T20:25:15.828014-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01166 -->
According to a document from **2026-05-17**, Section 16 is **almost accepted**, but I found **one SQL-breaking blocker** in the evidence-table schema hardening block. After fixing that, I would treat Section 16 as ready and proceed to Section 17. fileciteturn284file0

# Final verdict

```text
Section 16 architecture: accepted
Section 16 Option C integration: accepted
Section 16.9 synchronization logic: accepted
Execution readiness: blocked by one small ALTER TABLE syntax issue
Required fix before run: yes
```

The good news: the core Option C logic is now aligned. Section 16’s top header correctly frames Section 16.0–16.8 as run-level evidence capture and Section 16.9 as post-campaign frontier evidence synchronization. It also now states that Section 16.6 persists Section 15-derived Option C selective/aggressive counteroffer frontier fields, and Section 16.9 refreshes them after a fresh Section 15 run. fileciteturn284file0

# 1. Required blocker fix — missing data type in Section 16.1 schema hardening

In the latest Section 16, the `ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary` schema-hardening block appears to have this line:

```sql
ADD COLUMN IF NOT EXISTS option_c_frontier_interpretation_note,
```

That is SQL-breaking because PostgreSQL requires a data type for each `ADD COLUMN`. The nearby Option C evidence fields are correctly typed, but this specific field is missing `TEXT`. fileciteturn287file17

## Replace this

```sql
    ADD COLUMN IF NOT EXISTS option_c_frontier_posture_type TEXT,
    ADD COLUMN IF NOT EXISTS option_c_frontier_interpretation_note,
    ADD COLUMN IF NOT EXISTS validation_pass_count BIGINT,
```

## With this

```sql
    ADD COLUMN IF NOT EXISTS option_c_frontier_posture_type TEXT,
    ADD COLUMN IF NOT EXISTS option_c_frontier_interpretation_note TEXT,
    ADD COLUMN IF NOT EXISTS validation_pass_count BIGINT,
```

That is the only execution blocker I see.

---

# 2. Section 16.9 is now aligned

The updated Section 16.9C candidate logic now compares both the standard Section 15 frontier fields and the Option C frontier fields. It includes mismatch flags for `counteroffer_strategy_variant`, `aggressive_counteroffer_expansion_enabled`, ordinary counteroffer candidate metrics, aggressive override metrics, aggressive override final outcome mix, aggressive override quality metrics, and the Option C posture/interpretation fields. fileciteturn285file14

Section 16.9D is also aligned. It now updates the standard frontier fields and the Option C fields from the fresh Section 15 frontier output, including the shortened aliases for the long aggressive-override average metric names. fileciteturn285file13

Section 16.9E/F are strong. The post-synchronization check separates standard frontier mismatches from Option C frontier mismatches, then fails only if matched evidence rows still disagree with fresh Section 15 output after synchronization. fileciteturn286file0

The Section 16.9 ending is aligned as well. It explicitly states that standard frontier fields and Option C frontier fields have been refreshed, that matched evidence rows align to fresh Section 15 output, and that Section 17 can be run for final post-campaign acceptance. fileciteturn286file1

---

# 3. Optional commentary polish — Section 16.7 end summary

This is not a blocker, but the Section 16.7 end summary does not yet mention the new Option C evidence completeness gatekeeper, even though the gatekeeper itself exists and validates required Option C frontier evidence fields. fileciteturn285file19

In the **END OF SECTION 16.7** list, add one item after the current item 8, then renumber the later items.

## Add

```sql
    9. Required Option C frontier evidence fields are populated in the executive evidence summary.
```

This makes the summary match the logic that now exists.

---

# 4. Optional commentary polish — Section 16.6 SQL PURPOSE

Section 16.6’s SQL purpose list still says it “joins Section 15 frontier posture fields,” but the section now carries more than posture fields. It carries the Option C frontier evidence as well. The actual field list now includes `counteroffer_strategy_variant`, ordinary counteroffer candidate metrics, aggressive override metrics, and `option_c_frontier_posture_type` / `option_c_frontier_interpretation_note`. fileciteturn287file18

Update the Section 16.6 SQL purpose item from:

```sql
    8. Join Section 15 frontier posture fields for the current run.
```

to:

```sql
    8. Join Section 15 frontier posture fields and Option C selective/aggressive counteroffer
       frontier evidence for the current run.
```

This is commentary only.

---

# 5. Section 16 accepted after the blocker fix

After adding `TEXT` to `option_c_frontier_interpretation_note`, Section 16 is ready.

```text
Accepted:
- run-level evidence capture architecture
- validation evidence capture
- parameter snapshot capture
- product × score segment evidence capture
- executive evidence summary capture
- Option C executive evidence fields
- Option C evidence completeness gatekeeper
- Section 16.8 Option C review output
- Section 16.9 post-campaign synchronization
```

Recommended next step after the one-line fix:

```text
Proceed to Section 17 review/update.
```
<!-- END_MESSAGE C034-M01166 -->


---

<a id="c034-m01167"></a>

### C034-M01167

**Andrew** · 2026-05-16T20:33:48.455000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01167 -->
Due to the size of section 17, please begin by reviewing thru section 17.10 logic, comments, headers for potential needed changes.  current code attached.
<!-- END_MESSAGE C034-M01167 -->


**Attachments in export:** `Pasted text(210).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01172"></a>

### C034-M01172

**ChatGPT** · 2026-05-16T20:38:45.301426-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01172 -->
According to a document from **2026-05-17**, Section 17’s architecture is strong and the first half is mostly aligned with the final post-campaign acceptance role: it is read-only, registry-scoped, archive-backed, and intentionally positioned after all runs, fresh Section 15, Section 16.9 synchronization, and persistent evidence capture. The current header also correctly says Section 17 evaluates persistent archive, registry, comparison, validation, parameter-snapshot, product-policy, and evidence objects rather than creating new outputs. fileciteturn290file2

## Verdict for Section 17 through 17.10

```text
Section 17.0–17.10 core architecture: strong
Read-only boundary: correct
Dynamic population-size design: correct
Dynamic validation-evidence key-set design: correct
Execution blockers found so far: none obvious from the retrieved code
Option C alignment: needs targeted updates before final acceptance
Core rewrite needed: no
```

The main gap is not structural. The current Section 17.0–17.10 framework still needs to catch up to the Option C evidence chain we added in Sections 11–16. Section 17 now needs to verify that the completed campaign preserved and synchronized ordinary-versus-aggressive counteroffer evidence at three levels:

```text
archive rows
Section 16 executive evidence
Section 14 validation evidence
```

That matters because Section 16 now persists Section 15-derived Option C frontier evidence, and Section 16.9 refreshes those fields after the fresh archive-wide Section 15 run. Section 17 should not accept the campaign unless that evidence survived into the persistent campaign evidence layer. fileciteturn288file1

---

# 1. Header / top narrative updates

The top Section 17 header is mostly excellent. Keep the workflow-position language, the warning not to run Section 1 immediately before Section 17, and the Section 16.9 dependency language. Those are aligned with the full-campaign workflow. fileciteturn290file12

## Required header patch: add Option C acceptance note

Add this after `VALIDATION EVIDENCE COMPLETENESS DESIGN` or after `SEGMENT EVIDENCE COMPLETENESS DESIGN`.

```sql
OPTION C COUNTEROFFER STRATEGY SPLIT ACCEPTANCE NOTE:
    Section 17 should confirm that the completed campaign preserved the Option C counteroffer
    strategy split evidence created and carried forward by earlier sections.

    Key evidence fields include:
        counteroffer_strategy_variant
        aggressive_counteroffer_expansion_enabled
        ordinary_counteroffer_candidate_flag
        aggressive_counteroffer_requested_structure_override_flag
        ordinary_counteroffer_candidate_rows
        ordinary_counteroffer_candidate_rate
        aggressive_override_rows
        aggressive_override_rate
        aggressive_override_final_counteroffer_rows
        aggressive_override_final_counteroffer_rate
        aggressive_override_final_manual_review_rows
        aggressive_override_final_manual_review_rate
        aggressive_override_final_decline_rows
        aggressive_override_final_decline_rate
        option_c_frontier_posture_type
        option_c_frontier_interpretation_note

    Why this matters:
        Option C intentionally split the prior broad counteroffer-first concept into:

            SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
            AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY

        Section 17 should confirm that the campaign evidence layer can explain the difference between:
            ordinary counteroffer candidacy,
            aggressive requested-structure override routing,
            final aggressive override outcomes,
            and archive-wide Option C frontier posture.

    Boundary:
        Section 17 does not decide whether aggressive expansion is better.

        It confirms that the completed SQL campaign evidence is structurally ready for final
        interpretation and documentation.
```

## Required stale-language patch

The header still references `Counteroffer-first strategy effect check` in the Section 17 map. That should be changed before final acceptance because the formal campaign now uses the selective/aggressive split. The current map still lists 17.17 as “Counteroffer-first strategy effect check.” fileciteturn290file12

Replace:

```sql
17.17 Counteroffer-first strategy effect check.
```

with:

```sql
17.17 Option C counteroffer strategy split effect check.
```

Also replace any wording in the “former campaign queries” paragraph that says:

```sql
counteroffer-first strategy effect check
```

with:

```sql
Option C counteroffer strategy split effect check
```

That is a header/comment change only for now. We can handle the actual 17.17 logic when we review 17.11–17.20.

---

# 2. Section 17.0 — add Option C dependency preflight

Section 17.0 should fail clearly if the persistent archive or evidence tables are missing the Option C columns that downstream Section 17 checks will read.

Add this to the Section 17.0 dependency preflight.

```sql
/*-----------------------------------------------------------------------------------------------
Option C acceptance dependency preflight.

Purpose:
    Confirm that the persistent archive and executive evidence tables contain the Option C fields
    required for final campaign acceptance.

Why this matters:
    Section 17 is the final SQL acceptance layer.

    If these fields are absent, Section 17 cannot confirm whether the campaign preserved the
    selective-versus-aggressive counteroffer evidence created upstream.

Boundary:
    This is a schema-presence check only.

    It does not recalculate outcomes.
    It does not modify archive rows.
    It does not modify evidence rows.
-----------------------------------------------------------------------------------------------*/

WITH required_option_c_columns AS (
    SELECT *
    FROM (
        VALUES
            ('strategy_decisions_archive', 'counteroffer_strategy_variant'),
            ('strategy_decisions_archive', 'aggressive_counteroffer_expansion_enabled'),
            ('strategy_decisions_archive', 'severe_requested_structure_counteroffer_override_enabled'),
            ('strategy_decisions_archive', 'exposure_extreme_counteroffer_override_enabled'),
            ('strategy_decisions_archive', 'exposure_policy_stop_counteroffer_override_enabled'),
            ('strategy_decisions_archive', 'requested_pti_decline_counteroffer_override_enabled'),
            ('strategy_decisions_archive', 'requested_el_decline_counteroffer_override_enabled'),
            ('strategy_decisions_archive', 'ordinary_counteroffer_candidate_flag'),
            ('strategy_decisions_archive', 'aggressive_counteroffer_requested_structure_override_flag'),

            ('strategy_run_evidence_summary', 'counteroffer_strategy_variant'),
            ('strategy_run_evidence_summary', 'aggressive_counteroffer_expansion_enabled'),
            ('strategy_run_evidence_summary', 'ordinary_counteroffer_candidate_rows'),
            ('strategy_run_evidence_summary', 'ordinary_counteroffer_candidate_rate'),
            ('strategy_run_evidence_summary', 'aggressive_override_rows'),
            ('strategy_run_evidence_summary', 'aggressive_override_rate'),
            ('strategy_run_evidence_summary', 'aggressive_override_final_counteroffer_rows'),
            ('strategy_run_evidence_summary', 'aggressive_override_final_counteroffer_rate'),
            ('strategy_run_evidence_summary', 'aggressive_override_final_manual_review_rows'),
            ('strategy_run_evidence_summary', 'aggressive_override_final_manual_review_rate'),
            ('strategy_run_evidence_summary', 'aggressive_override_final_decline_rows'),
            ('strategy_run_evidence_summary', 'aggressive_override_final_decline_rate'),
            ('strategy_run_evidence_summary', 'option_c_frontier_posture_type'),
            ('strategy_run_evidence_summary', 'option_c_frontier_interpretation_note')
    ) AS v(table_name, column_name)
),

missing_option_c_columns AS (
    SELECT
        r.table_name,
        r.column_name
    FROM required_option_c_columns r
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = 'credit_decisioning_sim'
          AND c.table_name = r.table_name
          AND c.column_name = r.column_name
    )
)

SELECT
    COUNT(*),
    STRING_AGG(table_name || '.' || column_name, ', ' ORDER BY table_name, column_name)
INTO
    v_option_c_required_column_gap_count,
    v_option_c_required_missing_columns
FROM missing_option_c_columns;

IF v_option_c_required_column_gap_count > 0 THEN
    RAISE EXCEPTION
        'Module 2 Section 17 failure: missing Option C acceptance column(s): %.',
        v_option_c_required_missing_columns;
END IF;
```

Add these variables to the Section 17.0 `DECLARE` block:

```sql
v_option_c_required_column_gap_count BIGINT;
v_option_c_required_missing_columns TEXT;
```

This is the only preflight change I consider important before running the first half of Section 17.

---

# 3. Section 17.1 and 17.2 — add Option C visibility

## Section 17.1 — Archive campaign inventory

The archive inventory should show whether Option C evidence exists at the campaign level. Add these fields to the inventory SELECT if practical:

```sql
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

COUNT(*) FILTER (
    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
) AS aggressive_override_archived_row_count
```

These are not acceptance checks by themselves; they make Option C visible in the campaign inventory.

## Section 17.2 — Archive slice detail

For each archived strategy / scenario / population slice, add:

```sql
MAX(counteroffer_strategy_variant)
    AS counteroffer_strategy_variant,

COALESCE(BOOL_OR(aggressive_counteroffer_expansion_enabled), FALSE)
    AS aggressive_counteroffer_expansion_enabled,

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
```

This improves reviewability without changing the acceptance grain.

---

# 4. Section 17.3 — no logic change

No change needed.

Archive grain should remain:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

Do **not** add Option C fields to archive grain. Option C fields are strategy-output evidence, not identity keys.

---

# 5. Sections 17.4 and 17.5 — no core logic change

The registry-to-archive reconciliation design is correct, especially because Section 17 now derives expected source population counts from Module 1 scenario archive rather than assuming 50,000 rows. The current header explicitly states the dynamic acceptance design and that archived Module 2 rows should match the expected Module 1 source population count for each active registry run. fileciteturn290file12

Do not add Option C fields to the archive-replacement key or to the population-size logic.

A useful commentary-only note would be:

```sql
Option C note:
    Option C strategy names are reconciled through the same active campaign registry keys as all
    other Module 2 strategies.

    No special archive reconciliation key is used for selective feasibility or aggressive expansion.
```

---

# 6. Section 17.6 — add legacy orphan commentary

No core logic change needed. Section 17.6 should continue surfacing archive slices that do not map to active campaign registry rows.

However, because Option C renamed the prior `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` formal campaign posture, add this comment to the Section 17.6 header:

```sql
Option C legacy-alias note:
    If legacy COUNTEROFFER_FIRST_EXPOSURE_STRATEGY archive slices appear here, they are likely
    historical or pre-Option-C evidence rows.

    They should not be silently treated as part of the active formal campaign unless the campaign
    registry intentionally includes that legacy strategy name.

    For clean final acceptance, either:
        archive those rows as historical non-active evidence,
        or remove / replace them through the governed archive reset workflow before final campaign
        acceptance.
```

This keeps the orphan-slice query useful without weakening the new formal strategy naming.

---

# 7. Sections 17.7 and 17.8 — add Option C evidence coverage

This is the most important update in the first half of Section 17.

The current evidence coverage logic already checks executive evidence, parameter evidence, validation evidence, and segment evidence. It also dynamically derives expected validation keys and expected segment rows rather than hardcoding counts. fileciteturn291file9

Now it should also confirm that the executive evidence row contains Option C frontier evidence.

## Add to the `executive_evidence` CTE in 17.7 / 17.8

Inside the CTE that summarizes `credit_decisioning_sim.strategy_run_evidence_summary`, add:

```sql
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
```

Do **not** require these fields to be non-null in Section 17.7:

```sql
delta_ordinary_counteroffer_candidate_rate
delta_aggressive_override_rate
delta_aggressive_override_final_counteroffer_rate
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
avg_approved_pti_for_aggressive_override_counteroffers
avg_approved_el_for_aggressive_override_counteroffers
```

Those can legitimately be `NULL` when no baseline reference exists or no aggressive override final counteroffers exist.

## Add to the final SELECT in 17.7 / 17.8

```sql
COALESCE(e.option_c_executive_evidence_gap_rows, 0)
    AS option_c_executive_evidence_gap_rows,
```

## Add to `evidence_capture_status`

Add this condition to the `EVIDENCE_CAPTURE_READY` branch:

```sql
AND COALESCE(e.option_c_executive_evidence_gap_rows, 0) = 0
```

So the acceptance logic becomes:

```text
evidence exists
validation evidence complete
segment evidence complete
parameter evidence complete
Option C executive evidence complete
```

## Add these fields to Section 17.8 detail output

If Section 17.8 displays run-by-run evidence coverage, include the executive Option C fields:

```sql
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
```

This is the right place to confirm that Section 16.6 / 16.9 successfully persisted and synchronized Option C evidence.

---

# 8. Section 17.9 — add Option C archive convention checks

Section 17.9 is already correctly scoped to **active campaign archive rows** rather than every historical archive row. That is important and should stay. fileciteturn291file12

Add these checks inside `convention_counts`.

```sql
/***********************************************************************************************
Option C archive evidence checks.

These checks confirm that active campaign archive rows retain the selective/aggressive
counteroffer path fields needed for final campaign interpretation.
***********************************************************************************************/
COUNT(*) FILTER (
    WHERE counteroffer_strategy_variant IS NULL
       OR aggressive_counteroffer_expansion_enabled IS NULL
       OR severe_requested_structure_counteroffer_override_enabled IS NULL
       OR exposure_extreme_counteroffer_override_enabled IS NULL
       OR exposure_policy_stop_counteroffer_override_enabled IS NULL
       OR requested_pti_decline_counteroffer_override_enabled IS NULL
       OR requested_el_decline_counteroffer_override_enabled IS NULL
       OR ordinary_counteroffer_candidate_flag IS NULL
       OR aggressive_counteroffer_requested_structure_override_flag IS NULL
) AS option_c_archive_field_gap_rows,

COUNT(*) FILTER (
    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
      AND (
            (
                decision_outcome = 'COUNTEROFFER'
                AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                    '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
            )
         OR (
                decision_outcome = 'MANUAL_REVIEW'
                AND preliminary_decision_outcome = 'COUNTEROFFER'
                AND counteroffer_feasibility_pass_flag IS FALSE
                AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
                AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                    '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
            )
         OR (
                decision_outcome = 'DECLINE'
                AND preliminary_decision_outcome = 'COUNTEROFFER'
                AND counteroffer_feasibility_pass_flag IS FALSE
                AND failed_counteroffer_resolution = 'DECLINE'
                AND COALESCE(triggered_reason_code_list, '') NOT LIKE
                    '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
            )
      )
) AS aggressive_override_reason_trace_gap_rows,

COUNT(*) FILTER (
    WHERE strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY'
      AND aggressive_counteroffer_requested_structure_override_flag IS TRUE
) AS selective_strategy_aggressive_override_rows
```

Then add these fields to the final SELECT:

```sql
option_c_archive_field_gap_rows,
aggressive_override_reason_trace_gap_rows,
selective_strategy_aggressive_override_rows,
```

And include them in `critical_convention_violation_count`:

```sql
+ option_c_archive_field_gap_rows
+ aggressive_override_reason_trace_gap_rows
+ selective_strategy_aggressive_override_rows
```

Also update the Section 17.9 header under `CONVENTIONS CHECKED`:

```sql
    Option C counteroffer split fields are populated;
    aggressive override rows retain path-specific reason-code traceability;
    SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY produces no aggressive override rows.
```

This makes Section 17.9 the active-campaign archive-level counterpart to the Option C checks already added in Sections 11–14.

---

# 9. Section 17.10 — add Option C validation status visibility

Section 17.10 should not need a full rewrite. Because Section 14.19 now writes Option C rows into `tmp_m2_validation_status_summary`, and Section 16 persists those rows into validation evidence, Section 17.10 should automatically include them if it summarizes all persisted validation evidence.

However, I recommend adding explicit Option C validation counts so the reviewer can see the Option C validation status without drilling into Section 17.11.

Add these to the Section 17.10 run-level validation summary SELECT:

```sql
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
```

Add this comment to the 17.10 header:

```sql
Option C validation note:
    Section 14.19 now creates dedicated Option C validation rows.

    Section 17.10 should show whether those rows were captured for each active campaign run and
    whether the Option C field preservation, path behavior, reason traceability, and matched-context
    checks were PASS, REVIEW, or NOT_APPLICABLE.
```

Missing Option C validation rows should be caught in Section 17.7 through the dynamic validation key completeness design. Section 17.10 should focus on the status mix of rows that exist.

---

# What I would not change yet

Do **not** hardcode:

```text
39 active runs
20 comparison groups
1,950,000 rows
50,000 rows per slice
```

inside acceptance logic. The current dynamic design is better. The header correctly says Section 17 derives expected Module 1 source population row counts from `credit_decisioning_sim.synthetic_applications_scenario_archive`, which is more robust than hardcoding 50,000 rows. fileciteturn290file12

Do **not** add Option C fields to archive grain.

Do **not** add Option C fields to immutable source-field consistency.

Do **not** create direct selective-vs-aggressive comparison logic in 17.0–17.10.

Do **not** make Section 17 mutate archive, evidence, registry, parameter, or product-policy rows.

---

# Final recommendation for 17.0–17.10

Make these targeted updates before running the first half of Section 17:

```text
1. Add Option C acceptance note to the top Section 17 header.
2. Replace stale “counteroffer-first” header language with “Option C counteroffer strategy split.”
3. Add Section 17.0 Option C required-column preflight.
4. Add Option C archive visibility fields to 17.1 and 17.2.
5. Add Option C legacy-alias note to 17.6.
6. Add Option C executive evidence completeness checks to 17.7 and 17.8.
7. Add Option C archive convention and reason-trace checks to 17.9.
8. Add Option C validation-status counts to 17.10.
```

After those patches, Sections 17.0–17.10 will be aligned with the Option C architecture. The next review pass should cover **17.11–17.20**, where the larger strategy-effect and final acceptance rollup changes will be required, especially replacing the old `Counteroffer-first` effect check with an official **Option C Selective vs Aggressive Counteroffer Strategy Split** acceptance layer.
<!-- END_MESSAGE C034-M01172 -->


---

<a id="c034-m01173"></a>

### C034-M01173

**Andrew** · 2026-05-16T20:53:17.862000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01173 -->
There is no section 17.0 - should there be?
<!-- END_MESSAGE C034-M01173 -->


---

<a id="c034-m01176"></a>

### C034-M01176

**ChatGPT** · 2026-05-16T20:56:45.660030-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01176 -->
According to a document from **2026-05-17**, you are correct: the current Section 17 map starts at **17.1** and does **not** include a Section 17.0. It lists `17.1 Archive campaign inventory` through `17.20 Final Module 2 campaign acceptance rollup`. fileciteturn293file1

So my reference to **17.0** was not pointing to an existing subsection. It was a recommendation to **add a new preflight subsection before 17.1**.

## Recommendation

Yes — I recommend adding a new:

```sql
SECTION 17.0 — POST-CAMPAIGN ACCEPTANCE DEPENDENCY PREFLIGHT
```

It is not required by the current numbering, but it is the cleanest place for the Option C required-column preflight and general persistent-object dependency checks.

This fits Section 17’s role: Section 17 is the final read-only acceptance layer, designed to run after all campaign runs have completed through Section 16.8, after Section 15 has been rerun from the completed archive, after Section 16.9 has synchronized frontier fields, and after evidence rows exist for all accepted runs. fileciteturn293file4

## Why adding 17.0 is better than putting this in 17.1

Section 17.1 is archive inventory. It should stay focused on inventory.

A preflight should happen before inventory because it answers:

```text
Do the persistent objects and required Option C columns exist before any Section 17 acceptance queries run?
```

That makes 17.0 consistent with the rest of the project’s staged design.

---

# Header map update

In the Section 17 header, update:

```sql
WHAT SECTION 17 INCLUDES:
    17.1  Archive campaign inventory.
    17.2  Archive slice detail.
```

to:

```sql
WHAT SECTION 17 INCLUDES:
    17.0  Post-campaign acceptance dependency preflight.
    17.1  Archive campaign inventory.
    17.2  Archive slice detail.
```

Also update:

```sql
17.17 Counteroffer-first strategy effect check.
```

to:

```sql
17.17 Option C counteroffer strategy split effect check.
```

That second update matters because the formal campaign no longer uses “counteroffer-first” as the primary strategy story.

---

# Add this before Section 17.1

Place this immediately after the main Section 17 header and before:

```sql
SECTION 17.1 — ARCHIVE CAMPAIGN INVENTORY
```

```sql
/***************************************************************************************************
SECTION 17.0 — POST-CAMPAIGN ACCEPTANCE DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the persistent objects required for final Module 2 campaign acceptance exist before
    Section 17 begins reporting campaign-level acceptance evidence.

    Section 17.0 answers:

        "Are the persistent archive, registry, comparison, validation, parameter-snapshot, segment,
         and executive evidence objects available for final post-campaign acceptance review?"

SQL PURPOSE:
    1. Confirm required persistent campaign objects exist.
    2. Confirm Option C counteroffer strategy split fields exist in the archive and executive evidence
       tables.
    3. Fail clearly before Section 17.1 if the campaign acceptance layer cannot read the required
       evidence surface.

WHY THIS SECTION EXISTS:
    Section 17 is the final read-only campaign acceptance layer.

    It should not discover missing persistent objects halfway through archive inventory, evidence
    coverage, final-output convention checks, or final acceptance rollup.

    A dedicated preflight keeps dependency validation separate from campaign analysis.

OPTION C ACCEPTANCE PREFLIGHT:
    Option C evidence must be available in:

        credit_decisioning_sim.strategy_decisions_archive
        credit_decisioning_sim.strategy_run_evidence_summary

    The archive table preserves applicant-level ordinary versus aggressive counteroffer path evidence.

    The executive evidence table preserves run-level frontier evidence after Section 16.9
    synchronization.

BOUNDARY:
    Section 17.0 is read-only.

    It does not create tables.
    It does not alter tables.
    It does not insert, update, or delete rows.
    It does not recalculate outcomes.
    It does not recalculate frontier fields.
***************************************************************************************************/

DO $$
DECLARE
    v_required_object_missing_count      BIGINT;
    v_required_object_missing_names      TEXT;

    v_option_c_required_column_gap_count BIGINT;
    v_option_c_required_missing_columns  TEXT;
BEGIN
    /***********************************************************************************************
    17.0A Required persistent object existence.

    Business purpose:
        Final campaign acceptance depends on persistent objects, not temporary latest-run helpers.

    Why this matters:
        Section 17 should be run after the full campaign workflow is complete.

        Missing persistent objects usually mean one of the required upstream sections was skipped:
            Section 12 archive persistence,
            Section 13 comparison registry / comparison evidence,
            Section 16 run-level evidence capture,
            or Section 16.9 frontier synchronization.
    ***********************************************************************************************/
    WITH required_objects AS (
        SELECT *
        FROM (
            VALUES
                ('credit_decisioning_sim.synthetic_applications_scenario_archive'),
                ('credit_decisioning_sim.strategy_decisions_archive'),
                ('credit_decisioning_sim.strategy_run_campaign_registry'),
                ('credit_decisioning_sim.strategy_comparison_campaign_registry'),
                ('credit_decisioning_sim.strategy_run_evidence_summary'),
                ('credit_decisioning_sim.strategy_run_validation_evidence'),
                ('credit_decisioning_sim.strategy_run_parameter_snapshot'),
                ('credit_decisioning_sim.strategy_run_segment_evidence_summary')
        ) AS v(object_name)
    ),

    object_presence AS (
        SELECT
            object_name,
            TO_REGCLASS(object_name) IS NOT NULL AS object_exists
        FROM required_objects
    )

    SELECT
        COUNT(*),
        STRING_AGG(object_name, ', ' ORDER BY object_name)
    INTO
        v_required_object_missing_count,
        v_required_object_missing_names
    FROM object_presence
    WHERE object_exists IS DISTINCT FROM TRUE;

    IF v_required_object_missing_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 17.0 failure: required persistent object(s) missing for campaign acceptance: %.',
            v_required_object_missing_names;
    END IF;


    /***********************************************************************************************
    17.0B Option C required-column preflight.

    Business purpose:
        Confirm that the persistent campaign evidence surface can support final acceptance review of
        the selective-versus-aggressive counteroffer strategy split.

    Archive-level fields:
        Preserve applicant-level ordinary versus aggressive counteroffer path evidence.

    Executive evidence fields:
        Preserve Section 15-derived, Section 16.9-synchronized frontier evidence.

    Boundary:
        This validates schema presence only.

        It does not require aggressive override rows to exist.
        It does not decide whether aggressive expansion is better.
    ***********************************************************************************************/
    WITH required_option_c_columns AS (
        SELECT *
        FROM (
            VALUES
                /*
                Applicant-level archive evidence.
                */
                ('strategy_decisions_archive', 'counteroffer_strategy_variant'),
                ('strategy_decisions_archive', 'aggressive_counteroffer_expansion_enabled'),
                ('strategy_decisions_archive', 'severe_requested_structure_counteroffer_override_enabled'),
                ('strategy_decisions_archive', 'exposure_extreme_counteroffer_override_enabled'),
                ('strategy_decisions_archive', 'exposure_policy_stop_counteroffer_override_enabled'),
                ('strategy_decisions_archive', 'requested_pti_decline_counteroffer_override_enabled'),
                ('strategy_decisions_archive', 'requested_el_decline_counteroffer_override_enabled'),
                ('strategy_decisions_archive', 'ordinary_counteroffer_candidate_flag'),
                ('strategy_decisions_archive', 'aggressive_counteroffer_requested_structure_override_flag'),

                /*
                Run-level executive frontier evidence.
                */
                ('strategy_run_evidence_summary', 'counteroffer_strategy_variant'),
                ('strategy_run_evidence_summary', 'aggressive_counteroffer_expansion_enabled'),

                ('strategy_run_evidence_summary', 'ordinary_counteroffer_candidate_rows'),
                ('strategy_run_evidence_summary', 'ordinary_counteroffer_candidate_rate'),
                ('strategy_run_evidence_summary', 'aggressive_override_rows'),
                ('strategy_run_evidence_summary', 'aggressive_override_rate'),

                ('strategy_run_evidence_summary', 'aggressive_override_final_counteroffer_rows'),
                ('strategy_run_evidence_summary', 'aggressive_override_final_counteroffer_rate'),
                ('strategy_run_evidence_summary', 'aggressive_override_final_manual_review_rows'),
                ('strategy_run_evidence_summary', 'aggressive_override_final_manual_review_rate'),
                ('strategy_run_evidence_summary', 'aggressive_override_final_decline_rows'),
                ('strategy_run_evidence_summary', 'aggressive_override_final_decline_rate'),

                ('strategy_run_evidence_summary', 'option_c_frontier_posture_type'),
                ('strategy_run_evidence_summary', 'option_c_frontier_interpretation_note')
        ) AS v(table_name, column_name)
    ),

    missing_option_c_columns AS (
        SELECT
            r.table_name,
            r.column_name
        FROM required_option_c_columns r
        WHERE NOT EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'credit_decisioning_sim'
              AND c.table_name = r.table_name
              AND c.column_name = r.column_name
        )
    )

    SELECT
        COUNT(*),
        STRING_AGG(table_name || '.' || column_name, ', ' ORDER BY table_name, column_name)
    INTO
        v_option_c_required_column_gap_count,
        v_option_c_required_missing_columns
    FROM missing_option_c_columns;

    IF v_option_c_required_column_gap_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 17.0 failure: missing Option C acceptance column(s): %.',
            v_option_c_required_missing_columns;
    END IF;
END $$;
```

## Bottom line

There is no existing Section 17.0. That is fine.

But after the Option C changes, adding **17.0** is the better final structure:

```text
17.0 = dependency and Option C schema preflight
17.1 = archive inventory
17.2+ = campaign acceptance analysis
```

I would add it and update the Section 17 map accordingly.
<!-- END_MESSAGE C034-M01176 -->


---

<a id="c034-m01177"></a>

### C034-M01177

**Andrew** · 2026-05-16T21:08:29.517000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01177 -->
please make these two updates easier to perform.  give me copy paste.  here is current 17.1 and 17.2.  3. Section 17.1 and 17.2 — add Option C visibility
Section 17.1 — Archive campaign inventory

The archive inventory should show whether Option C evidence exists at the campaign level. Add these fields to the inventory SELECT if practical:

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

COUNT(*) FILTER (
    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
) AS aggressive_override_archived_row_count

These are not acceptance checks by themselves; they make Option C visible in the campaign inventory.

Section 17.2 — Archive slice detail

For each archived strategy / scenario / population slice, add:

MAX(counteroffer_strategy_variant)
    AS counteroffer_strategy_variant,

COALESCE(BOOL_OR(aggressive_counteroffer_expansion_enabled), FALSE)
    AS aggressive_counteroffer_expansion_enabled,

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

This improves reviewability without changing the acceptance grain.
<!-- END_MESSAGE C034-M01177 -->


**Attachments in export:** `Pasted text(211).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_23.md) · [Next](Part_25.md)
