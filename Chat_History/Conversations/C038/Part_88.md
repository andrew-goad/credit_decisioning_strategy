# Module 2 Decision Simulator Build

## Part 88

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_87.md) · [Next](Part_89.md)

<a id="c038-m01740"></a>

### C038-M01740

**ChatGPT** · 2026-05-13T00:42:05.771496-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01740 -->
You’re right. Do **not** use the full Section 17.20 rewrite I gave last time. Keep your `expected_campaign_shape` CTE in the clearer form with the product-guardrail expectation comment and `5` / `10` expected values. Your current Section 17.20 is the final acceptance rollup, so this should be a targeted `acceptance_inputs` CTE replacement only. fileciteturn274file0

Replace only the existing `acceptance_inputs AS (...)` block with this:

```sql
acceptance_inputs AS (
    SELECT
        /*******************************************************************************************
        Expected campaign shape.
        *******************************************************************************************/
        x.expected_campaign_runs,
        x.expected_comparison_groups,
        x.expected_archive_slices,
        x.expected_archive_rows,
        x.expected_rows_per_archive_slice,
        x.expected_validation_rows_per_run,
        x.expected_product_guardrail_campaign_runs,
        x.expected_product_guardrail_policy_rows,

        /*******************************************************************************************
        Registry and archive.
        *******************************************************************************************/
        rr.active_campaign_registry_rows,
        cr.active_comparison_registry_rows,

        a.archived_strategy_scenario_slices,
        a.total_archived_rows,
        a.archive_slices_not_50000_rows,
        a.archive_slices_with_duplicate_application_ids,

        agd.duplicate_archive_grain_count,

        /*******************************************************************************************
        Comparison and source consistency.
        *******************************************************************************************/
        cmp.comparison_group_count,
        cmp.comparison_ready_count,
        cmp.comparison_review_count,

        src.source_consistency_group_count,
        src.source_consistency_pass_count,
        src.source_consistency_review_count,
        src.total_source_field_mismatch_rows,

        /*******************************************************************************************
        Evidence.
        *******************************************************************************************/
        ev.registry_run_count_for_evidence_check,

        ev.executive_evidence_rows,
        ev.executive_evidence_complete_run_count,
        ev.executive_evidence_issue_run_count,

        ev.parameter_snapshot_rows,
        ev.parameter_snapshot_complete_run_count,
        ev.parameter_snapshot_issue_run_count,

        ev.validation_evidence_complete_run_count,
        ev.validation_evidence_incomplete_run_count,
        ev.min_validation_rows_per_run,
        ev.max_validation_rows_per_run,
        ev.total_validation_evidence_rows,

        ev.segment_evidence_run_count,
        ev.segment_evidence_issue_run_count,
        ev.min_segment_rows_per_run,
        ev.max_segment_rows_per_run,
        ev.total_segment_evidence_rows,

        /*******************************************************************************************
        Final-output conventions.
        *******************************************************************************************/
        cv.critical_convention_violation_count,

        /*******************************************************************************************
        Product guardrail policy exact-value audit.

        This assumes product_guardrail_policy_audit is registry-scoped upstream.
        It should count only the five formal active campaign product-guardrail runs:
            M2-06
            M2-23
            M2-26
            M2-34
            M2-36
        *******************************************************************************************/
        pga.product_guardrail_campaign_run_count,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,

        pga.expected_product_guardrail_policy_rows AS actual_product_guardrail_policy_rows_checked,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_mismatch_rows,

        /*******************************************************************************************
        Gate-level flags.

        These are included in the final output to make failed acceptance easier to troubleshoot.
        *******************************************************************************************/
        (
            rr.active_campaign_registry_rows = x.expected_campaign_runs
        ) AS campaign_registry_ready_flag,

        (
            cr.active_comparison_registry_rows = x.expected_comparison_groups
        ) AS comparison_registry_ready_flag,

        (
            a.archived_strategy_scenario_slices = x.expected_archive_slices
            AND a.total_archived_rows = x.expected_archive_rows
            AND a.archive_slices_not_50000_rows = 0
            AND a.archive_slices_with_duplicate_application_ids = 0
            AND agd.duplicate_archive_grain_count = 0
        ) AS archive_ready_flag,

        (
            cmp.comparison_group_count = x.expected_comparison_groups
            AND cmp.comparison_ready_count = x.expected_comparison_groups
            AND cmp.comparison_review_count = 0
        ) AS comparison_ready_flag,

        (
            src.source_consistency_group_count = x.expected_comparison_groups
            AND src.source_consistency_pass_count = x.expected_comparison_groups
            AND src.source_consistency_review_count = 0
            AND src.total_source_field_mismatch_rows = 0
        ) AS source_consistency_ready_flag,

        (
            ev.registry_run_count_for_evidence_check = x.expected_campaign_runs
            AND ev.executive_evidence_complete_run_count = x.expected_campaign_runs
            AND ev.executive_evidence_issue_run_count = 0
            AND ev.parameter_snapshot_complete_run_count = x.expected_campaign_runs
            AND ev.parameter_snapshot_issue_run_count = 0
            AND ev.validation_evidence_complete_run_count = x.expected_campaign_runs
            AND ev.validation_evidence_incomplete_run_count = 0
            AND ev.min_validation_rows_per_run = x.expected_validation_rows_per_run
            AND ev.max_validation_rows_per_run = x.expected_validation_rows_per_run
            AND ev.segment_evidence_run_count = x.expected_campaign_runs
            AND ev.segment_evidence_issue_run_count = 0
        ) AS evidence_ready_flag,

        (
            cv.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,

        (
            pga.product_guardrail_campaign_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_complete_run_count = x.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
            AND pga.expected_product_guardrail_policy_rows = x.expected_product_guardrail_policy_rows
            AND pga.missing_product_guardrail_policy_rows = 0
            AND pga.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag

    FROM expected_campaign_shape x
    CROSS JOIN registry_summary rr
    CROSS JOIN comparison_registry_summary cr
    CROSS JOIN archive_summary a
    CROSS JOIN archive_grain_duplicates agd
    CROSS JOIN comparison_readiness cmp
    CROSS JOIN source_consistency src
    CROSS JOIN evidence_coverage ev
    CROSS JOIN convention_summary cv
    CROSS JOIN product_guardrail_policy_audit pga
),
```

This keeps the update limited to **17.20C** and uses the previously intended product-guardrail fields.
<!-- END_MESSAGE C038-M01740 -->


---

<a id="c038-m01741"></a>

### C038-M01741

**Andrew** · 2026-05-13T00:49:15.737000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01741 -->
is this correct for your 17.20D?  you suggested: 17.20D — update the final SELECT

In the final SELECT, add this field near the expected campaign shape fields:

    expected_product_guardrail_campaign_runs,

Then replace the current product-guardrail output fields with these:

    product_guardrail_campaign_run_count,
    product_guardrail_parameter_snapshot_complete_run_count,
    product_guardrail_parameter_snapshot_issue_run_count,

    actual_product_guardrail_policy_rows_checked,
    missing_product_guardrail_policy_rows,
    product_guardrail_policy_mismatch_rows        and this is what I did: 
<!-- END_MESSAGE C038-M01741 -->


**Attachments in export:** `Pasted text(176).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01744"></a>

### C038-M01744

**ChatGPT** · 2026-05-13T00:51:29.334924-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01744 -->
Yes — your **17.20D final `SELECT` update is correct** for the recommendation.

You included the newly required expected-shape field:

```sql
expected_product_guardrail_campaign_runs,
```

and you included the revised product-guardrail audit output fields:

```sql
product_guardrail_campaign_run_count,
product_guardrail_parameter_snapshot_complete_run_count,
product_guardrail_parameter_snapshot_issue_run_count,

actual_product_guardrail_policy_rows_checked,
missing_product_guardrail_policy_rows,
product_guardrail_policy_mismatch_rows
```

That matches the intended 17.20D update. The only difference is that you placed:

```sql
expected_product_guardrail_policy_rows,
expected_product_guardrail_campaign_runs,
```

rather than:

```sql
expected_product_guardrail_campaign_runs,
expected_product_guardrail_policy_rows,
```

That ordering is not a SQL issue. It will still work. For readability, I slightly prefer listing campaign runs first, then policy rows, because the logic is:

```text
5 product-guardrail campaign runs × 2 audited products = 10 product-policy audit rows
```

But your current ordering is valid. fileciteturn277file10

The only thing to verify is that your upstream **`acceptance_inputs AS (...)`** block now exposes all of these fields:

```sql
x.expected_product_guardrail_campaign_runs,
x.expected_product_guardrail_policy_rows,

pga.product_guardrail_campaign_run_count,
pga.product_guardrail_parameter_snapshot_complete_run_count,
pga.product_guardrail_parameter_snapshot_issue_run_count,

pga.expected_product_guardrail_policy_rows AS actual_product_guardrail_policy_rows_checked,
pga.missing_product_guardrail_policy_rows,
pga.product_guardrail_policy_mismatch_rows,
```

and that your `product_guardrail_policy_ready_flag` uses:

```sql
(
    pga.product_guardrail_campaign_run_count = x.expected_product_guardrail_campaign_runs
    AND pga.product_guardrail_parameter_snapshot_complete_run_count = x.expected_product_guardrail_campaign_runs
    AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
    AND pga.expected_product_guardrail_policy_rows = x.expected_product_guardrail_policy_rows
    AND pga.missing_product_guardrail_policy_rows = 0
    AND pga.product_guardrail_policy_mismatch_rows = 0
) AS product_guardrail_policy_ready_flag
```

If those upstream pieces are present, your final `SELECT` is good.

For cleaner presentation only, I would format your expected campaign shape fields like this:

```sql
/***********************************************************************************************
Expected campaign shape.
***********************************************************************************************/
expected_campaign_runs,
expected_comparison_groups,
expected_archive_slices,
expected_archive_rows,
expected_rows_per_archive_slice,
expected_validation_rows_per_run,
expected_product_guardrail_campaign_runs,
expected_product_guardrail_policy_rows,
```

But again: **your pasted 17.20D field list is functionally correct.**
<!-- END_MESSAGE C038-M01744 -->


---

<a id="c038-m01745"></a>

### C038-M01745

**Andrew** · 2026-05-13T01:00:38.390000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01745 -->
evaluate the full code one more time.
<!-- END_MESSAGE C038-M01745 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(2).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01760"></a>

### C038-M01760

**ChatGPT** · 2026-05-13T01:08:08.082794-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01760 -->
According to a document from 2026-05-13, the current uploaded Module 2 code is in **release-candidate / execution-ready shape**. I would not make another code-design pass. The latest file has the key final updates in place: Section 1.4 cleanup includes the new Section 14 helper objects, Section 14 carries its validation context helpers and `tmp_m2_validation_status_summary`, Section 17.7 / 17.8 now check complete validation evidence at **18 rows per run**, and Section 17.20 now includes the product-guardrail campaign-run expectation and readiness logic. fileciteturn280file11 fileciteturn280file5 fileciteturn280file0 fileciteturn281file1

## Verdict

**Static review result: ready for final PostgreSQL execution testing.**

I would treat the current file as the canonical release candidate. I would only call it truly “final validated release” after the full runtime path completes and Section 17.20 returns:

```sql
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```

I did not execute the SQL against PostgreSQL in this review. I performed a full static inspection of the uploaded file.

## What I checked

The uploaded file has:

| Static check | Result |
|---|---:|
| File size reviewed | ~2.22M characters |
| Lines reviewed | 59,125 |
| Formal section / subsection headers found | 156 |
| Duplicate formal section headers | 0 |
| Block comments `/* ... */` | Balanced |
| `DO $$ ... END $$;` blocks | Balanced, 36 / 36 |
| Parentheses after comment/string stripping | Balanced |
| Section 14 coverage | 14.0 through 14.20 present |
| Section 17 coverage | 17.1 through 17.20 present |
| Section 14.19 validation areas | 18 |
| Section 2.5 campaign catalog rows | 36 |
| Section 2.10 comparison groups | 17 |
| Section 16.9 | Present |
| Section 17.20 | Present once |

## Key confirmations

Section 1.4 is now aligned with the new Section 14 design. It drops `tmp_m2_validation_archive_readiness_context`, `tmp_m2_validation_comparison_readiness_context`, `tmp_m2_validation_source_consistency_context`, and `tmp_m2_validation_status_summary`, and the commentary correctly explains why Section 14 also performs a local reset for rerun safety. fileciteturn280file11

Section 14 is correctly positioned as the read-only latest-run validation layer. It identifies `credit_decisioning_sim.strategy_decisions` as the primary validation target, uses archive/comparison/source consistency as context, creates the three Section 14.0 helper objects, and materializes `tmp_m2_validation_status_summary` as the evidence spine consumed by Section 16. It also correctly treats missing Section 13 context as `NOT_APPLICABLE` rather than a hard failure. fileciteturn280file5 fileciteturn280file2

Section 17.7 and 17.8 are now stronger than the earlier version. They no longer merely check `validation_rows > 0`; they require validation rows to match the expected Section 14 validation spine, which is currently **18 rows per run**. That is the correct campaign-level acceptance standard. fileciteturn280file0

Section 16.9 is still properly documented as the post-campaign frontier evidence synchronization layer, and Section 17 correctly states that it should run after all campaign runs are complete, Section 15 has been rerun from the completed archive, and Section 16.9 has synchronized fresh frontier fields into `strategy_run_evidence_summary`. fileciteturn280file6turn280file15

Section 17.20 now has the intended expected campaign shape, including `expected_product_guardrail_campaign_runs = 5` and `expected_product_guardrail_policy_rows = 10`, with the five formal product-guardrail runs listed as M2-06, M2-23, M2-26, M2-34, and M2-36. fileciteturn281file1turn281file2

The product-guardrail audit is now registry-scoped and stronger. It starts from formal active campaign product-guardrail runs, checks parameter snapshot completeness, audits UPL and revolving-line policy rows, and flags missing or mismatched product-policy values. The final `product_guardrail_policy_ready_flag` now requires the product-guardrail campaign-run count, complete parameter snapshot count, expected policy-row count, no missing rows, and no mismatches. fileciteturn281file0turn281file11

## Minor observations, not required changes

The field name `actual_product_guardrail_policy_rows_checked` is acceptable, but semantically it is really the joined audit-row count from `pga.expected_product_guardrail_policy_rows`. It still works because the readiness flag compares it to the expected 10 audit rows and separately checks missing/mismatch counts. No change is required.

The formal campaign shape hardcodes 50,000 rows per archive slice and 18 validation rows per run. That is correct for this V1.0 campaign. If the formal campaign size or Section 14 validation spine changes later, Section 17.7, Section 17.8, and Section 17.20 should be updated together.

The banner still says `FINAL VALIDATED RELEASE`. That is fine after runtime acceptance, but strictly speaking the current status from this review is **static release candidate** until PostgreSQL execution and Section 17.20 acceptance pass.

## Final recommendation

Do **not** make more code changes right now.

Run the final execution path:

```text
all planned runs through Section 16.8
→ fresh Section 15
→ Section 16.9 synchronization
→ Section 17
→ confirm Section 17.20 returns MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
```

My assessment: the architecture, commentary, workflow, validation spine, evidence capture, frontier synchronization, and final acceptance framework are now coherent and ready for runtime validation.
<!-- END_MESSAGE C038-M01760 -->


---

<a id="c038-m01761"></a>

### C038-M01761

**Andrew** · 2026-05-13T01:10:48.202000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01761 -->
why would we hardcode this?  we want this to be flexible for whatever the user chooses in module 1: The formal campaign shape hardcodes 50,000 rows per archive slice and 18 validation rows per run. That is correct for this V1.0 campaign. If the formal campaign size or Section 14 validation spine changes later, Section 17.7, Section 17.8, and Section 17.20 should be updated together.
<!-- END_MESSAGE C038-M01761 -->


---

<a id="c038-m01764"></a>

### C038-M01764

**ChatGPT** · 2026-05-13T01:13:38.181337-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01764 -->
According to a document from 2026-05-13, you’re right. The **50,000 rows per archive slice** should not be hardcoded if we want Module 2 to support whatever population size the user selected in Module 1. The current Section 17 commentary and checks still describe the current formal campaign shape as 36 runs, 17 comparison groups, 1,800,000 archived rows, and 50,000 rows per slice; that is valid for the campaign we just ran, but it should be treated as an observed/example campaign shape, not a permanent acceptance assumption. fileciteturn282file2

I would revise the design this way:

## 1. Archive slice row counts should be dynamic

The better standard is:

```text
Each Module 2 archived slice should equal the row count of its selected Module 1 source slice.
```

So instead of this logic:

```sql
archived_rows = 50000
```

Section 17 should derive:

```sql
expected_source_rows
```

from the active campaign registry joined to the Module 1 scenario archive:

```text
strategy_run_campaign_registry
→ module1_scenario_set_name
→ module1_scenario_name
→ population_id
→ synthetic_applications_scenario_archive row count
```

Then Section 17 should check:

```sql
archived_rows = expected_source_rows
distinct_application_id_count = expected_source_rows
```

That lets Module 1 use 50,000, 75,000, 100,000, or any other governed population size without breaking Module 2 acceptance.

## 2. Total archive rows should also be dynamic

Instead of hardcoding:

```sql
expected_archive_rows = 1800000
```

derive it as:

```sql
SUM(expected_source_rows) across active campaign runs
```

For the campaign we just ran, that naturally equals:

```text
36 × 50,000 = 1,800,000
```

But if a future Module 1 population uses 75,000 rows and the user runs 36 Module 2 campaign rows, the expected total becomes:

```text
36 × 75,000 = 2,700,000
```

without requiring code edits.

## 3. Validation rows should not be permanently hardcoded to 18 either

This one is slightly different. The **18** is not tied to Module 1. It comes from the current Section 14 validation status spine. Section 16.7 already validates each current run by checking that persistent validation evidence matches `tmp_m2_validation_status_summary`, which is the right local gatekeeper. fileciteturn282file3

For Section 17 campaign acceptance, instead of hardcoding:

```sql
expected_validation_rows_per_run = 18
```

I would derive the validation evidence spine from the evidence table itself:

```text
expected validation key set =
distinct validation_area + validation_test_name + validation_category
across active campaign runs
```

Then each run should have:

```sql
validation_distinct_key_count = expected_validation_key_count
validation_rows = validation_distinct_key_count
```

That gives us flexibility if Section 14 later grows from 18 checks to 19, 22, or 25 checks. It also protects against partial evidence capture by checking completeness per run. The current Section 17.7 / 17.8 wording explicitly says 18 validation rows and 25 segment rows, which was useful for our specific campaign but is too rigid for a reusable engine. fileciteturn282file12

## 4. What should remain hardcoded?

Very little.

I would keep only values that are true design constants for a specific audit, such as the two audited product types in the product-guardrail exact-value audit:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

Even the expected product-guardrail count can be dynamic:

```sql
expected_product_guardrail_campaign_runs =
COUNT(*) active campaign runs where strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'

expected_product_guardrail_policy_rows =
expected_product_guardrail_campaign_runs × COUNT(expected audited products)
```

So we do not need to hardcode 5 or 10 either, except in explanatory comments about the formal campaign we ran.

## Recommended design standard

I would change the Section 17 acceptance philosophy from:

```text
Does the campaign match the exact 36 × 50,000 formal campaign we just ran?
```

to:

```text
Does every active campaign registry run have one archived slice, and does each archived slice match its selected Module 1 source population?
```

That is the right standard for a reusable Module 2 engine.

## Bottom line

Your instinct is correct. My prior wording was too specific to the campaign we just completed. The better version is:

```text
Do not hardcode Module 1 population size.
Do not hardcode total archive rows.
Do not hardcode validation-row count as a permanent constant.
Derive expected archive counts from active campaign registry + Module 1 source counts.
Derive expected validation completeness from the persisted validation evidence key set.
```

I would make one final Section 17 hardening pass to remove those hardcoded assumptions from 17.7, 17.8, and 17.20.
<!-- END_MESSAGE C038-M01764 -->


---

<a id="c038-m01765"></a>

### C038-M01765

**Andrew** · 2026-05-13T01:15:37.062000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01765 -->
is it only section 17 we need to change related to this hardcoding? no other sections?
<!-- END_MESSAGE C038-M01765 -->


---

<a id="c038-m01769"></a>

### C038-M01769

**ChatGPT** · 2026-05-13T01:18:16.177421-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01769 -->
According to a document from 2026-05-13, **the required SQL logic changes are concentrated in Section 17**. I would not change Sections 3–16 for this hardcoding issue, except for **comment-only cleanup** where Section 0 or Section 17 language still describes the old fixed campaign shape.

The key reason: Sections 11, 12, 14, and 16 are already run-local or source-driven. Section 12 persists the already-materialized latest-run output rather than assuming a fixed row count, and Section 16.7 validates current-run evidence against `tmp_m2_validation_status_summary` and the latest-run product × score segment count rather than a fixed campaign population. fileciteturn281file29 fileciteturn281file12

## What needs code changes

**Yes: Section 17 needs code changes.** Specifically, the hardcoded acceptance logic appears in:

| Area | Current issue | Change needed |
|---|---|---|
| **17.1** | Assumes `36` slices, `1,800,000` rows, and `50,000` rows per slice | Derive expected slices and total rows from active campaign registry + expected Module 1 source counts |
| **17.2** | Comment says each slice should be `50,000` | Comment-only update or add expected-source-row display |
| **17.4 / 17.5** | Uses `archived_rows <> 50000` and `COUNT(*) = 36` | Compare archived rows to expected source rows per registry run |
| **17.7 / 17.8** | Uses `36` campaign runs and `18` validation rows | Derive campaign run count from active registry and validation spine count from evidence/key set or Section 14 design |
| **17.20** | Hardcodes `36`, `17`, `1,800,000`, `50,000`, `18`, and product-guardrail `5/10` | Derive all except the audited product-value expectations |

The retrieved current Section 17 snippets show these exact fixed assumptions: Section 17.1 expects `36`, `1,800,000`, and `50,000`; Section 17.4/17.5 check `archived_rows <> 50000`; Section 17.7/17.8 expect `36` runs and `18` validation rows; and Section 17.20 defines `expected_campaign_shape` with `36`, `17`, `1,800,000`, `50,000`, and `18`. fileciteturn283file9 fileciteturn283file11 fileciteturn282file7 fileciteturn282file2

## What does **not** need code changes

**Section 13 does not need this fix.** Its matched-comparison readiness already compares baseline and challenger row counts to each other and to their own distinct application counts; it does not require a hardcoded `50,000` population. That is the right pattern because matched comparison should prove equal population overlap, not assume a fixed population size. fileciteturn284file1

**Section 14 does not need this fix.** It validates the latest-run output and uses archive/comparison context, but its job is not full-campaign row-count acceptance. Section 14’s local validation boundary is latest-run QA, not campaign-shape enforcement. fileciteturn284file16

**Section 16 does not need this fix.** Section 16.7 is already designed to compare validation evidence to `tmp_m2_validation_status_summary` and segment evidence to the current latest-run segment count. That means it is already flexible for future Section 14 validation-spine changes and future Module 1 population sizes at the current-run level. fileciteturn281file12

## Comment-only updates outside Section 17

I would also update **Section 0 / job-aid commentary** if it implies a fixed formal campaign shape. The current Section 0 describes the formal campaign framework and operating flow, but the reusable-engine standard should say Section 17 derives expected archive and evidence counts from the active campaign registry and selected Module 1 source populations, not from fixed 50,000-row assumptions. fileciteturn281file0

Also, if you keep the old standalone “campaign query pack” outside the canonical SQL, that query pack still has hardcoded `50,000`, `1,800,000`, and `36` expectations. That is separate from the canonical module, but it should be updated or retired if you want all QA collateral to be flexible. fileciteturn281file8

## Recommendation

Make one focused change set:

1. **Patch Section 17 only for SQL logic.**
2. **Update Section 0 and Section 17 comments to describe dynamic acceptance.**
3. **Do not touch Sections 3–16 for this issue.**
4. **Ignore or separately update old standalone QA queries if they are still part of your workflow.**

The better acceptance principle is:

```text
For every active campaign registry run:
    archived row count must equal that run’s selected Module 1 source population count;
    archived distinct application count must equal archived row count;
    evidence must exist once per active campaign registry run;
    validation evidence must be complete relative to the validation evidence spine, not hardcoded to 18 forever.
```
<!-- END_MESSAGE C038-M01769 -->


---

<a id="c038-m01770"></a>

### C038-M01770

**Andrew** · 2026-05-13T01:22:42.536000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01770 -->
thanks.  proceed with updating section 17 through 17.8 (current code attached):
<!-- END_MESSAGE C038-M01770 -->


**Attachments in export:** `Pasted text(177).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01773"></a>

### C038-M01773

**ChatGPT** · 2026-05-13T01:33:07.621524-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01773 -->
According to a document from 2026-05-13, the current Section 17 still frames the completed campaign around fixed counts like 36 active runs, 1,800,000 archived rows, 50,000 rows per slice, and 18 validation rows per run. This patch updates **Section 17 through Section 17.8 only** so archive and evidence acceptance are derived dynamically from the active campaign registry, Module 1 source slice counts, archived slice counts, and persisted validation evidence keys. fileciteturn286file7 fileciteturn285file15

Replace your current **Section 17 header through the end of Section 17.8** with this. It intentionally stops before **Section 17.9**.

```sql
/***************************************************************************************************
SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the final post-campaign control tower after all planned Module 2 campaign runs have been
    completed, archived, validated, compared, summarized, synchronized, and captured into persistent
    evidence.

    Section 17 answers:

        "Is the completed Module 2 campaign structurally complete, registry-aligned,
         evidence-complete, convention-clean, comparison-ready, source-consistent,
         parameter-traceable, product-policy-audited, and analytically ready for final
         interpretation?"

WHY THIS SECTION EXISTS:
    Earlier sections execute, validate, archive, compare, summarize, and capture the strategy
    campaign.

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

        Section 16.0–16.8:
            persists run-level executive evidence, validation evidence, parameter snapshots, and
            product × score segment evidence.

        Section 16.9:
            synchronizes fresh Section 15-derived frontier fields into persistent executive evidence
            after the full campaign archive is complete.

    Section 17 is different.

    Section 17 does not create new strategy output.
    Section 17 does not persist new evidence.
    Section 17 does not synchronize frontier evidence.
    Section 17 reviews the completed campaign from persistent archive, registry, comparison,
    validation, parameter-snapshot, product-policy, and evidence objects.

SECTION 17 WORKFLOW POSITION:
    Section 17 is the final read-only acceptance layer.

    It should be run after:

        1. All planned Module 2 campaign runs have completed through Section 16.8.
        2. Section 15 has been rerun once from the completed campaign archive.
        3. Section 16.9 has synchronized fresh Section 15 frontier fields into:
                credit_decisioning_sim.strategy_run_evidence_summary
        4. Section 16 evidence rows exist for all accepted campaign runs.
        5. Any known reruns, repair runs, or product-policy corrections have been completed.

WHY SECTION 16.9 MUST COME BEFORE SECTION 17:
    Section 15 is archive-wide.

    Section 16.0–16.8 captures evidence one run at a time.

    If a baseline or challenger was added or rerun after earlier evidence capture, older executive
    evidence rows may still contain stale Section 15-derived frontier labels.

    Section 16.9 formalizes the refresh so Section 17 evaluates the final synchronized evidence
    state rather than a partially stale campaign evidence layer.

DO NOT RUN SECTION 1 IMMEDIATELY BEFORE SECTION 17:
    Section 1 drops the replaceable latest-run table and temporary objects.

    Section 17 is designed to read persistent archive, registry, comparison, and evidence objects.

    If the user needs to refresh frontier evidence before Section 17:
        rerun Section 15 from the completed archive;
        run Section 16.9;
        then run Section 17.

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

WHY THE FORMER CAMPAIGN QUERIES 16–20 ARE AT THE END:
    The prior standalone campaign QA queries 16–20 are now represented by the closing Section 17
    checks:

        product guardrail strategy effect check,
        counteroffer-first strategy effect check,
        parameter snapshot profile audit,
        product guardrail policy exact-value audit,
        and final campaign acceptance rollup.

    Section 17 adds earlier campaign-wide completeness, reconciliation, evidence, convention, and
    comparison-readiness checks first, then keeps those strategy-effect and acceptance checks as the
    final executive acceptance layer.

DYNAMIC ACCEPTANCE DESIGN:
    Section 17 no longer assumes that every Module 1 source slice has 50,000 rows.

    Instead, for every active campaign registry run, Section 17 derives the expected source population
    row count from:

        credit_decisioning_sim.synthetic_applications_scenario_archive

    using:

        module1_scenario_set_name
        module1_scenario_name
        population_id

    Then Section 17 checks whether each archived Module 2 strategy slice has:

        archived_rows = expected_module1_source_rows
        distinct_application_id_count = expected_module1_source_rows

    This allows Module 2 to work with any governed Module 1 population size selected by the user.

VALIDATION EVIDENCE COMPLETENESS DESIGN:
    Section 17 no longer hardcodes the Section 14 validation evidence spine as 18 rows forever.

    Instead, Section 17 derives the validation evidence key set from persisted validation evidence
    across active campaign registry runs:

        validation_area
        validation_test_name
        validation_category

    Each run should contain the full derived validation evidence key set, without duplicate
    validation keys.

SEGMENT EVIDENCE COMPLETENESS DESIGN:
    Section 17 no longer assumes a fixed 25 product × score segment rows.

    Instead, Section 17 derives expected segment evidence count from each archived strategy slice
    using the distinct product × score × product-score segment combinations present in the archive.

WHAT TO LOOK FOR IN SECTION 17 RESULTS:
    Archive inventory:
        Every active campaign registry run should have one matching archived strategy slice, and each
        archived slice should match its selected Module 1 source population row count.

    Archive grain:
        Duplicate archive-grain count should be zero.

    Registry reconciliation:
        Every active campaign registry run should reconcile to the archive.

    Evidence coverage:
        Every accepted campaign run should have one executive evidence row, one parameter snapshot,
        complete validation evidence, and complete segment evidence.

    Final-output conventions:
        Full-archive convention violation counts should be zero.

    Validation status:
        PASS rows are expected.
        REVIEW rows should be interpreted before documentation.
        NOT_APPLICABLE rows should be understood in context.

    Comparison readiness:
        Formal comparison groups should be ready after the full campaign archive is complete.

    Source-field consistency:
        Matched baseline and challenger source fields should match so Module 2 strategy deltas are not
        contaminated by Module 1 population drift.

    Executive evidence:
        Frontier labels should reflect the fresh post-campaign Section 15 state after Section 16.9.

    Parameter snapshots:
        Strategy and product-policy payloads should be present and traceable for every accepted run.

    Product guardrail audit:
        Product-guardrail strategy runs should preserve intended exact UPL and revolving-line policy
        values.

READ-ONLY BOUNDARY:
    Section 17 does not insert archive rows.
    Section 17 does not delete archive rows.
    Section 17 does not update archive rows.
    Section 17 does not modify latest-run rows.
    Section 17 does not modify evidence rows.
    Section 17 does not modify campaign registry rows.
    Section 17 does not modify comparison registry rows.
    Section 17 does not modify strategy parameter rows.
    Section 17 does not modify product-policy parameter rows.
    Section 17 does not recalculate decisions.
    Section 17 does not recalculate approved exposure.
    Section 17 does not recalculate approved Expected Loss.
    Section 17 does not reassign simulated reason codes.
    Section 17 does not draft the BRD.
    Section 17 does not draft the written Validation Summary.

COMMON MISUSE TO AVOID:
    Do not run Section 1 immediately before Section 17.
    Do not interpret Section 17 as creating or repairing evidence.
    Do not interpret Section 17 as recalculating frontier fields.
    Do not interpret Section 17 as replacing Section 14 latest-run QA.
    Do not interpret Section 17 as replacing the written Validation Summary.
    Do not interpret simulated reason-code movement as customer communication language.

***************************************************************************************************/



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
    5. Return one compact campaign inventory status row.

DYNAMIC ACCEPTANCE PRINCIPLE:
    The expected archived row count is not hardcoded.

    For every active campaign registry run:

        expected_module1_source_rows =
            COUNT(*)
            FROM credit_decisioning_sim.synthetic_applications_scenario_archive
            WHERE scenario_set_name = module1_scenario_set_name
              AND scenario_name = module1_scenario_name
              AND population_id = population_id

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
        and archive readiness status.

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

    COALESCE(a.archived_rows, 0) - COALESCE(s.expected_module1_source_rows, 0)
        AS archived_row_count_gap,

    COALESCE(a.distinct_application_id_count, 0) - COALESCE(s.expected_module1_source_rows, 0)
        AS distinct_application_id_count_gap,

    a.min_strategy_run_id,
    a.max_strategy_run_id,

    a.first_archive_inserted_ts,
    a.last_archive_inserted_ts,

    CASE
        WHEN s.expected_module1_source_rows IS NULL
            THEN 'REVIEW_MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN COALESCE(a.archived_rows, 0) = 0
            THEN 'REVIEW_ARCHIVE_SLICE_MISSING'

        WHEN a.archived_rows <> s.expected_module1_source_rows
            THEN 'REVIEW_ARCHIVE_ROW_COUNT_MISMATCH'

        WHEN a.distinct_application_id_count <> s.expected_module1_source_rows
            THEN 'REVIEW_ARCHIVE_APPLICATION_ID_GRAIN'

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
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.strategy_name,
    r.strategy_version;



/***************************************************************************************************
SECTION 17.3 — MODULE 2 ARCHIVE GRAIN DUPLICATE CHECK
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm the archive is unique at the governed row-level archive grain.

SQL PURPOSE:
    Count duplicate rows at:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

EXPECTED RESULT:
    duplicate_archive_grain_count = 0
    archive_grain_status = ARCHIVE_GRAIN_READY

***************************************************************************************************/

SELECT
    COUNT(*) AS duplicate_archive_grain_count,

    CASE
        WHEN COUNT(*) = 0
            THEN 'ARCHIVE_GRAIN_READY'
        ELSE 'REVIEW_DUPLICATE_ARCHIVE_GRAIN'
    END AS archive_grain_status

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



/***************************************************************************************************
SECTION 17.4 — CAMPAIGN REGISTRY TO ARCHIVE RECONCILIATION
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm every active campaign registry run has exactly one matching archived strategy slice whose
    row count matches the selected Module 1 source population.

SQL PURPOSE:
    Reconcile active campaign registry runs to archive counts and Module 1 source counts.

EXPECTED RESULT:
    registry_run_count > 0
    registry_runs_with_archive_rows = registry_run_count
    registry_runs_missing_archive_rows = 0
    registry_runs_with_archive_row_count_mismatch = 0
    registry_runs_with_duplicate_or_missing_application_ids = 0
    campaign_registry_archive_status = CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE

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
        strategy_version
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

        s.expected_module1_source_rows,

        COALESCE(a.archived_rows, 0) AS archived_rows,
        COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count

    FROM registry_runs r

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
    COUNT(*) AS registry_run_count,

    COUNT(*) FILTER (
        WHERE expected_module1_source_rows IS NULL
    ) AS registry_runs_missing_module1_source_count,

    COUNT(*) FILTER (
        WHERE archived_rows > 0
    ) AS registry_runs_with_archive_rows,

    COUNT(*) FILTER (
        WHERE archived_rows = 0
    ) AS registry_runs_missing_archive_rows,

    COUNT(*) FILTER (
        WHERE expected_module1_source_rows IS NOT NULL
          AND archived_rows <> expected_module1_source_rows
    ) AS registry_runs_with_archive_row_count_mismatch,

    COUNT(*) FILTER (
        WHERE expected_module1_source_rows IS NOT NULL
          AND distinct_application_id_count <> expected_module1_source_rows
    ) AS registry_runs_with_duplicate_or_missing_application_ids,

    CASE
        WHEN COUNT(*) = 0
            THEN 'REVIEW_NO_ACTIVE_CAMPAIGN_REGISTRY_RUNS'

        WHEN COUNT(*) FILTER (WHERE expected_module1_source_rows IS NULL) > 0
            THEN 'REVIEW_REGISTRY_MODULE1_SOURCE_COUNT_MISSING'

        WHEN COUNT(*) FILTER (WHERE archived_rows = 0) > 0
            THEN 'REVIEW_CAMPAIGN_REGISTRY_ARCHIVE_MISSING_RUNS'

        WHEN COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND archived_rows <> expected_module1_source_rows
        ) > 0
            THEN 'REVIEW_CAMPAIGN_REGISTRY_ARCHIVE_ROW_COUNT_MISMATCH'

        WHEN COUNT(*) FILTER (
            WHERE expected_module1_source_rows IS NOT NULL
              AND distinct_application_id_count <> expected_module1_source_rows
        ) > 0
            THEN 'REVIEW_CAMPAIGN_REGISTRY_ARCHIVE_APPLICATION_ID_GRAIN'

        ELSE 'CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE'
    END AS campaign_registry_archive_status

FROM registry_archive_join;



/***************************************************************************************************
SECTION 17.5 — REGISTRY RUNS MISSING OR MISMATCHED IN ARCHIVE
****************************************************************************************************

BUSINESS PURPOSE:
    Provide row-level troubleshooting detail for active campaign registry runs that do not reconcile
    to the archive.

SQL PURPOSE:
    Display active registry runs where:
        Module 1 source count is missing,
        archive slice is missing,
        archive row count differs from expected Module 1 source rows,
        or archive distinct application_id count differs from expected Module 1 source rows.

EXPECTED RESULT:
    zero rows.

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
        strategy_version
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

        s.expected_module1_source_rows,

        COALESCE(a.archived_rows, 0) AS archived_rows,
        COALESCE(a.distinct_application_id_count, 0) AS distinct_application_id_count,

        COALESCE(a.archived_rows, 0) - COALESCE(s.expected_module1_source_rows, 0)
            AS archived_row_count_gap,

        COALESCE(a.distinct_application_id_count, 0) - COALESCE(s.expected_module1_source_rows, 0)
            AS distinct_application_id_count_gap

    FROM registry_runs r

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

    expected_module1_source_rows,
    archived_rows,
    distinct_application_id_count,
    archived_row_count_gap,
    distinct_application_id_count_gap,

    CASE
        WHEN expected_module1_source_rows IS NULL
            THEN 'MODULE1_SOURCE_COUNT_NOT_FOUND'

        WHEN archived_rows = 0
            THEN 'ARCHIVE_SLICE_MISSING'

        WHEN archived_rows <> expected_module1_source_rows
            THEN 'ARCHIVE_ROW_COUNT_MISMATCH'

        WHEN distinct_application_id_count <> expected_module1_source_rows
            THEN 'ARCHIVE_APPLICATION_ID_GRAIN_MISMATCH'

        ELSE 'ARCHIVE_SLICE_READY'
    END AS archive_reconciliation_issue_type

FROM registry_archive_join

WHERE expected_module1_source_rows IS NULL
   OR archived_rows = 0
   OR archived_rows <> expected_module1_source_rows
   OR distinct_application_id_count <> expected_module1_source_rows

ORDER BY
    run_sequence_number,
    module2_run_id;



/***************************************************************************************************
SECTION 17.6 — ARCHIVE SLICES WITHOUT ACTIVE CAMPAIGN REGISTRY ROW
****************************************************************************************************

BUSINESS PURPOSE:
    Identify archived strategy slices that are not represented by an active campaign registry row.

SQL PURPOSE:
    Surface archive slices that may be:
        old development runs,
        ad hoc custom experiments,
        inactive campaign runs,
        or archive rows that need documentation review.

EXPECTED RESULT:
    For a clean formal campaign archive, this may return zero rows.

INTERPRETATION:
    Rows returned here are not automatically invalid.

    They should be reviewed because Section 17 acceptance is registry-scoped. Extra archive slices can
    be legitimate historical evidence, but they should not be confused with the active campaign.

***************************************************************************************************/

WITH archive_slices AS (
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
),

active_registry_runs AS (
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
)

SELECT
    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,

    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,

    a.archived_rows,
    a.distinct_application_id_count,

    a.first_archive_inserted_ts,
    a.last_archive_inserted_ts,

    'ARCHIVE_SLICE_WITHOUT_ACTIVE_CAMPAIGN_REGISTRY_ROW' AS archive_registry_status

FROM archive_slices a

LEFT JOIN active_registry_runs r
    ON r.strategy_set_name = a.strategy_set_name
   AND r.strategy_name = a.strategy_name
   AND r.strategy_version = a.strategy_version
   AND r.module1_scenario_set_name = a.module1_scenario_set_name
   AND r.module1_scenario_name = a.module1_scenario_name
   AND r.population_id = a.population_id

WHERE r.module2_run_id IS NULL

ORDER BY
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,
    a.strategy_name,
    a.strategy_version;



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

EXPECTED RESULT:
    registry_run_count > 0
    expected_validation_key_count > 0
    runs_with_one_executive_evidence_row = registry_run_count
    runs_with_one_parameter_snapshot_row = registry_run_count
    runs_with_complete_validation_evidence_rows = registry_run_count
    runs_with_complete_segment_evidence_rows = registry_run_count
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
        )) AS expected_segment_rows

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

validation_key_catalog AS (
    SELECT
        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS expected_validation_key_count
    FROM registry_runs r

    JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id
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

        COALESCE(e.executive_rows, 0) AS executive_rows,
        COALESCE(p.parameter_rows, 0) AS parameter_rows,

        COALESCE(v.validation_rows, 0) AS validation_rows,
        COALESCE(v.validation_distinct_key_count, 0) AS validation_distinct_key_count,
        COALESCE(v.duplicate_validation_key_rows, 0) AS duplicate_validation_key_rows,

        COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,

        COALESCE(s.segment_rows, 0) AS segment_rows,
        COALESCE(s.segment_distinct_key_count, 0) AS segment_distinct_key_count,
        COALESCE(s.duplicate_segment_key_rows, 0) AS duplicate_segment_key_rows,

        COALESCE(ase.expected_segment_rows, 0) AS expected_segment_rows

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

    MAX(expected_validation_key_count) AS expected_validation_key_count,

    COUNT(*) FILTER (
        WHERE executive_rows = 1
    ) AS runs_with_one_executive_evidence_row,

    COUNT(*) FILTER (
        WHERE parameter_rows = 1
    ) AS runs_with_one_parameter_snapshot_row,

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
        and per-run evidence capture status.

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
        )) AS expected_segment_rows

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

validation_key_catalog AS (
    SELECT
        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS expected_validation_key_count
    FROM registry_runs r

    JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id
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

    COALESCE(vkc.expected_validation_key_count, 0) AS expected_validation_key_count,
    COALESCE(v.validation_rows, 0) AS validation_rows,
    COALESCE(v.validation_distinct_key_count, 0) AS validation_distinct_key_count,

    COALESCE(v.validation_rows, 0)
        - COALESCE(vkc.expected_validation_key_count, 0)
        AS validation_evidence_row_gap,

    COALESCE(v.duplicate_validation_key_rows, 0) AS duplicate_validation_key_rows,

    COALESCE(ase.expected_segment_rows, 0) AS expected_segment_rows,
    COALESCE(s.segment_rows, 0) AS segment_rows,
    COALESCE(s.segment_distinct_key_count, 0) AS segment_distinct_key_count,

    COALESCE(s.segment_rows, 0)
        - COALESCE(ase.expected_segment_rows, 0)
        AS segment_evidence_row_gap,

    COALESCE(s.duplicate_segment_key_rows, 0) AS duplicate_segment_key_rows,

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

ORDER BY r.run_sequence_number;
```

This patch removes the hardcoded **50,000**, **1,800,000**, **36**, **18**, and **25** assumptions from the first acceptance block. The remaining Section 17.9–17.20 blocks can stay in place for now, but Section 17.20 will still need the same dynamic treatment later so the final rollup agrees with this updated 17.1–17.8 logic.
<!-- END_MESSAGE C038-M01773 -->


---

<a id="c038-m01775"></a>

### C038-M01775

**Andrew** · 2026-05-13T07:37:13.282000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01775 -->
thanks. proceed with reviewing sections 17.9 through 17.16 (current code attached) to see if they need updated regarding the hardcoded acceptance logic and the changes we just made thru 17.8.
<!-- END_MESSAGE C038-M01775 -->


**Attachments in export:** `Pasted text(178).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01780"></a>

### C038-M01780

**ChatGPT** · 2026-05-13T07:42:37.198963-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01780 -->
According to a document from 2026-05-13, **yes — Sections 17.9 through 17.16 need targeted updates**, but not all for the same reason. The core issue is that Sections 17.1–17.8 are now moving toward **dynamic, active-campaign-registry-scoped acceptance**, while parts of 17.9–17.16 still describe or assume the old fixed formal campaign shape: **36 runs, 17 comparisons, 50,000 rows per slice, 1,800,000 total rows, and 5 product-guardrail runs**. The attached Section 17 still contains that fixed-shape language in the header and in later expectations. fileciteturn286file0

## Summary recommendation

Update **17.9–17.16**, but do it as a focused alignment pass, not a full redesign.

| Section | Needs logic change? | Needs comment change? | Reason |
|---|---:|---:|---|
| **17.9** | Yes | Yes | It currently checks the full archive. It should check active campaign registry archive rows only, otherwise old ad hoc archive slices can affect acceptance. |
| **17.10** | Yes, light | Yes | Should be active-registry-scoped and aligned to dynamic validation evidence completeness. |
| **17.11** | Yes, light | Yes | Same as 17.10; should review REVIEW / NOT_APPLICABLE concentration only for active campaign runs. |
| **17.12** | Yes, material | Yes | Must remove 50,000 / 17 assumptions and derive expected matched counts from Module 1 source rows. |
| **17.13** | Yes, material | Yes | Should align with dynamic comparison readiness and source consistency for active comparison groups. |
| **17.14** | Yes, light-to-moderate | Yes | Current comments still say 36 rows and applications = 50,000. Query should join active campaign registry and display expected source rows / gaps. |
| **17.15** | Yes, moderate | Yes | Current comments say expected 17 rows. Should derive active comparison count and include readiness/source status context. |
| **17.16** | Yes, moderate | Yes | Should derive product-guardrail runs from active registry, not assume exactly five, even if our formal campaign example has five. |

## Section-by-section review

### 17.9 — Full-archive final-output convention checks

This should be changed.

The current intent is sound: validate decision flags, exposure conventions, affordability conventions, Expected Loss conventions, and reason-code conventions across archived rows. But now that 17.1–17.8 are registry-scoped, 17.9 should not scan the entire `strategy_decisions_archive` blindly. If historical ad hoc or inactive archive slices exist, they could pollute Section 17 acceptance.

Recommended change: rename / reframe it from **full archive** to **active campaign archive convention checks**, and build a CTE that starts from active campaign registry rows, then joins to matching archive rows.

No hardcoded row count is needed. This section should only ask:

```text
Do all archived rows belonging to active campaign registry runs satisfy final output conventions?
```

### 17.10 — Validation status summary by campaign run

This should be lightly updated.

It probably does not need major business logic changes, but it should be scoped through active campaign registry rows. The updated 17.7 / 17.8 logic already derives the validation key catalog dynamically, so 17.10 should not imply a fixed 18-row validation spine.

Recommended change: join `strategy_run_campaign_registry` to `strategy_run_validation_evidence`, and summarize validation statuses per active registry run. Keep `PASS`, `REVIEW`, and `NOT_APPLICABLE` counts, but do not hardcode the expected number of validation rows.

### 17.11 — Validation REVIEW / NOT_APPLICABLE concentration

This should be lightly updated.

Same logic as 17.10: scope to active campaign registry rows. This prevents old development evidence from appearing in final campaign review. It should remain a review table, not an acceptance gate.

Recommended change: active registry join, then filter `validation_status IN ('REVIEW', 'NOT_APPLICABLE')`.

### 17.12 — Comparison registry readiness

This definitely needs a material update.

This section is the biggest remaining dynamic-acceptance gap. The current Section 17 materials still describe all 17 formal comparison groups as expected and still use fixed 50,000-row assumptions in comparison readiness language. fileciteturn286file5

Recommended change: for each active comparison registry row, derive:

```text
expected_module1_source_rows
```

from:

```sql
credit_decisioning_sim.synthetic_applications_scenario_archive
```

using:

```sql
module1_scenario_set_name
module1_scenario_name
population_id
```

Then require:

```sql
baseline_archived_rows = expected_module1_source_rows
challenger_archived_rows = expected_module1_source_rows
baseline_distinct_application_id_count = expected_module1_source_rows
challenger_distinct_application_id_count = expected_module1_source_rows
matched_application_id_count = expected_module1_source_rows
baseline_only_application_id_count = 0
challenger_only_application_id_count = 0
```

This removes both the fixed **17** and fixed **50,000** assumptions.

### 17.13 — Matched comparison source-field consistency

This also needs a material update.

The current source-field consistency logic is conceptually correct: compare immutable Module 1 source fields between baseline and challenger using `IS DISTINCT FROM`. The attached code shows the correct direction by comparing fields such as estimated LGD and requested Expected Loss and producing `SOURCE_FIELDS_MATCH` / `SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED`. fileciteturn287file3

But it should align with dynamic Section 17.12:

```text
active comparison registry row
→ expected Module 1 source count
→ matched baseline/challenger rows
→ source-field mismatch counts
```

Recommended change: preserve the field comparisons, but ensure every active comparison group appears even if the match is missing or incomplete. The status should distinguish:

```text
SOURCE_FIELDS_MATCH
SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED
COMPARISON_NOT_READY_SOURCE_CONSISTENCY_NOT_EVALUABLE
```

### 17.14 — Executive evidence campaign summary

This needs comment cleanup and probably a light logic alignment.

The current code says the expected result is **36 rows** and each row should have **applications = 50,000**. That is now wrong for a flexible Module 1 population size. fileciteturn287file1

Recommended change: start from active campaign registry rows and left join `strategy_run_evidence_summary`. Add:

```sql
expected_module1_source_rows
applications_minus_expected_source_rows
executive_evidence_status
```

This lets the grid continue to be an executive evidence table, but it becomes flexible.

### 17.15 — Baseline × challenger delta summary

This needs comment cleanup and moderate logic alignment.

The current comment says expected result is **17 rows**. That should become:

```text
one row per active comparison registry group
```

The query should be driven by `strategy_comparison_campaign_registry`, not by an assumed count. If it already does that, then the SQL may only need light additions: include dynamic readiness/source consistency fields from updated 17.12 / 17.13 logic, or recompute them locally.

Recommended change: ensure the output has these fields:

```sql
comparison_readiness_status
source_consistency_status
expected_module1_source_rows
matched_application_id_count
baseline_only_application_id_count
challenger_only_application_id_count
```

Then the deltas are easier to trust.

### 17.16 — Product guardrail strategy effect check

This needs moderate alignment.

The current Section 17 header still treats the product-guardrail expectation as **5 product-guardrail runs × 2 audited products = 10 rows**. That is true for our campaign, but it should not be a permanent hardcoded acceptance assumption. fileciteturn286file0

For 17.16 specifically, the product-guardrail strategy effect check should derive product-guardrail runs from the active campaign registry:

```sql
WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
  AND registry_active_flag IS TRUE
```

Then compare each product-guardrail challenger to the relevant baseline for the same Module 1 scenario / population.

It can still highlight UPL and revolving-line effects because those are the intended audited products, but the number of product-guardrail runs should be dynamic.

## What does **not** need to change much

Sections **17.10, 17.11, 17.14, and 17.15** are mostly evidence-review / display sections. They do not need heavy acceptance logic unless you want them to produce explicit status flags. The key requirement is that they should be **active-campaign scoped** and should stop saying fixed counts like 36, 17, or 50,000.

Sections **17.12 and 17.13** are the important logic updates because they are true comparison-readiness and source-consistency controls.

Section **17.9** should be scoped to active campaign rows so the convention checks match the acceptance philosophy from 17.1–17.8.

## Suggested patch sequence

I would split the next work into three patches:

```text
Patch A: 17.9–17.11
    Registry-scoped archive convention checks and validation evidence review.

Patch B: 17.12–17.13
    Dynamic comparison readiness and matched source-field consistency.

Patch C: 17.14–17.16
    Executive evidence summary, baseline × challenger delta summary, and product-guardrail strategy effect check.
```

Do not patch 17.20 yet. Once 17.9–17.16 are aligned, then 17.20 should be updated to consume the same dynamic acceptance assumptions.
<!-- END_MESSAGE C038-M01780 -->


---

<a id="c038-m01781"></a>

### C038-M01781

**Andrew** · 2026-05-13T07:46:41.801000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01781 -->
Thanks.  Perform each of these patches and then provide one 17.9-17.6 full copy paste.  Patch A: 17.9–17.11
    Registry-scoped archive convention checks and validation evidence review.

Patch B: 17.12–17.13
    Dynamic comparison readiness and matched source-field consistency.

Patch C: 17.14–17.16
    Executive evidence summary, baseline × challenger delta summary, and product-guardrail strategy effect check.
<!-- END_MESSAGE C038-M01781 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_87.md) · [Next](Part_89.md)
