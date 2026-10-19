# Module 2 Decision Simulator Build

## Part 07

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_06.md) · [Next](Part_08.md)

<a id="c038-m00164"></a>

### C038-M00164

**Andrew** · 2026-05-06T15:54:04.617000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00164 -->
This is strong. I agree with the Section 11 patches and the Section 12 Strategy Decision Archive Persistence Layer.

Section 12 correctly:
- consumes credit_decisioning_sim.strategy_decisions
- creates or reuses credit_decisioning_sim.strategy_decisions_archive
- preserves latest-run output as replaceable
- preserves archive output as governed history
- uses the locked archive grain:
  strategy_set_name
  strategy_name
  strategy_version
  module1_scenario_set_name
  module1_scenario_name
  population_id
  application_id
- uses the locked archive replacement / rerun key:
  strategy_set_name
  strategy_name
  strategy_version
  module1_scenario_set_name
  module1_scenario_name
  population_id
- correctly excludes application_id from the replacement / rerun key
- treats strategy_run_id, strategy_run_ts, latest_output_created_ts, and archive_inserted_ts as audit metadata
- supports archive_run_flag = FALSE without inserting or deleting archive rows
- supports strategy_archive_reset_mode values:
  NONE
  STRATEGY_SCENARIO_ONLY
  STRATEGY_SET_ONLY
  ALL
- fails in NONE mode when the same replacement key already exists
- inserts latest-run rows without recalculating decisions, reasons, approved exposure, or approved Expected Loss
- creates archive indexes
- provides local archive diagnostics
- does not build matched strategy comparison
- does not build full Module 2 QA
- does not draft BRD or Validation Summary documentation

Treat Section 12 as accepted, subject to the targeted hardening patches below.

Do not rewrite Sections 0–12 in full unless necessary.

================================================================================
1. TARGETED SECTION 12 PATCH — ARCHIVE SCHEMA DATA-TYPE ALIGNMENT
================================================================================

Section 12 already checks whether the archive table is missing latest-run columns.

Please add a targeted schema data-type alignment check for common columns between:

credit_decisioning_sim.strategy_decisions

and:

credit_decisioning_sim.strategy_decisions_archive

Purpose:
If the archive table already existed from an earlier build, it may contain the same column names but incompatible data types. Missing-column checks alone do not catch that.

Patch objective:
Fail clearly if any common latest-run column and archive column have incompatible data types.

Recommended comparison:
Compare information_schema.columns for both tables on column_name and validate at least:

- data_type
- numeric_precision where applicable
- numeric_scale where applicable
- character_maximum_length where applicable
- datetime_precision where applicable

Exclude archive_inserted_ts from the latest-run-to-archive comparison because it exists only on the archive table.

Recommended additional schema check:
Also check for unexpected archive columns that do not exist in the latest-run table, except archive_inserted_ts.

Preferred V1.0 behavior:
Fail if unexpected non-latest-run archive columns exist.

Reason:
For this module, the archive should be a persisted copy of the governed latest-run output plus archive_inserted_ts. Unexpected extra archive columns may indicate an older incompatible archive schema.

Commentary should explain:
- the archive table may pre-exist from an earlier implementation version
- Section 12 should not silently insert into a misaligned archive schema
- this is a schema governance check, not a modeling check
- if the latest-run output schema changes in future development, the archive table may need to be altered or recreated

================================================================================
2. TARGETED SECTION 12 PATCH — EXPAND PERSISTENCE MISMATCH CHECK
================================================================================

Section 12 already validates that archived rows match latest-run rows for key final outputs.

Please expand the persistence mismatch check to include the full set of core decision, exposure, economics, and reason-code fields needed for audit traceability.

At minimum, include comparisons for:

Decision fields:
- decision_outcome
- decision_path
- decision_priority_rank
- decision_resolution_source

Decision flags:
- approval_flag
- counteroffer_flag
- manual_review_flag
- decline_flag
- simulated_offer_exposure_flag

Exposure fields:
- approved_amount
- counteroffer_amount
- exposure_reduction_flag
- exposure_reduction_amount
- exposure_reduction_pct

Affordability fields:
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio

Expected Loss fields:
- requested_expected_loss_amount
- approved_expected_loss_amount
- approved_el_reduction_amount
- approved_el_reduction_pct

Reason-code fields:
- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- primary_reason_family
- triggered_reason_code_list
- reason_priority_rank
- reason_code_count

Key metadata / lineage fields:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id
- applicant_id
- product_type_policy_key
- score_band_policy_key

Use IS DISTINCT FROM for comparisons so NULL handling remains explicit and safe.

Reason:
Archive persistence should prove that Section 12 persisted the already-materialized latest-run output without changing final decision, exposure, economics, reason-code, or lineage values.

Important:
Do not compare archive_inserted_ts to latest_output_created_ts. They are different audit timestamps with different meanings.

================================================================================
3. TARGETED SECTION 12 PATCH — UNIQUE ARCHIVE GRAIN ENFORCEMENT
================================================================================

If not already present, please ensure Section 12 creates or validates a uniqueness control on the full archive row-level grain:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

Preferred implementation:
Create a unique index if feasible:

strategy_set_name,
strategy_name,
strategy_version,
module1_scenario_set_name,
module1_scenario_name,
population_id,
application_id

If an existing archive table contains duplicates that prevent unique-index creation, Section 12 should fail clearly and instruct the user to reset or clean the archive.

Reason:
The archive should not contain duplicate rows for the same application under the same Module 1 scenario and Module 2 strategy version.

This protects matched strategy comparison from ambiguous row-level joins.

================================================================================
4. SECTION 12 ACCEPTANCE CRITERIA
================================================================================

After these targeted patches, treat Section 12 as accepted if:

- credit_decisioning_sim.strategy_decisions_archive exists
- archive_inserted_ts exists
- archive table contains all latest-run columns plus archive_inserted_ts
- common latest-run / archive columns have aligned data types
- unexpected archive columns do not exist, except archive_inserted_ts
- archive_run_flag = FALSE skips insert/delete behavior without changing archive rows
- NONE mode fails if the current replacement key already exists
- STRATEGY_SCENARIO_ONLY replaces only the current strategy / Module 1 scenario / population slice
- STRATEGY_SET_ONLY replaces all strategy_name / strategy_version outputs within the selected strategy_set_name + Module 1 scenario + population
- ALL clears the archive before inserting the latest-run output
- archive grain is unique at:
  strategy_set_name
  strategy_name
  strategy_version
  module1_scenario_set_name
  module1_scenario_name
  population_id
  application_id
- archive replacement key excludes application_id
- latest-run row count equals current archived slice row count when archive_run_flag = TRUE
- current archived slice has no duplicate application_id values
- archived core decision / exposure / economics / reason-code fields match latest-run values
- archived lineage fields match latest-run values
- no outcomes are recalculated
- no reason codes are recalculated
- no approved exposure or approved Expected Loss is recalculated
- no matched strategy comparison is built yet
- no full Module 2 QA framework is built yet

================================================================================
5. NEXT BUILD SCOPE: SECTION 13 ONLY
================================================================================

After the targeted Section 12 patches, please build only:

SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK

Section 13 should consume:

credit_decisioning_sim.strategy_decisions_archive

Do not build:
- full Module 2 QA framework
- final Validation Summary
- BRD documentation
- dashboards
- production reporting layer

Those belong later.

================================================================================
6. SECTION 13 OBJECTIVE
================================================================================

Section 13 should provide read-only archive inventory and matched strategy comparison queries.

Section 13 should answer:

“How do two archived Module 2 strategy runs differ when applied to the same Module 1 scenario and population?”

Section 13 should not answer:

“Is the full Module 2 system validated?”

Full validation comes later after the complete SQL module is assembled and executed.

================================================================================
7. SECTION 13 DESIGN BOUNDARY
================================================================================

Section 13 should be read-only.

It should not:
- insert rows
- delete rows
- update rows
- create or replace final output tables
- modify archive rows
- recalculate decision outcomes
- recalculate reason codes
- recalculate approved exposure
- recalculate approved Expected Loss

It should only inspect archived strategy outputs.

Important:
Section 13 should not be a blocking gatekeeper for ordinary single-strategy execution.

If only one strategy is archived, Section 13 should still provide archive inventory and clearly show that matched comparison requires two selected archived strategy slices.

================================================================================
8. COMPARISON PARAMETER DESIGN
================================================================================

Please create a temporary comparison parameter table.

Recommended table:

tmp_m2_strategy_comparison_params

Recommended fields:

- comparison_set_name
- baseline_strategy_set_name
- baseline_strategy_name
- baseline_strategy_version
- challenger_strategy_set_name
- challenger_strategy_name
- challenger_strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

Recommended default values can be placeholders, but the commentary should explain that users must set them to archived strategy slices that exist.

Do not overload Module 1 scenario fields.

For Module 2 v1.0, matched strategy comparison should require:
- same module1_scenario_set_name
- same module1_scenario_name
- same population_id
- different strategy_name and/or strategy_version

Do not compare across different Module 1 scenarios in v1.0 unless explicitly designed later.

Reason:
Module 2 strategy comparison should isolate downstream strategy effects. Comparing across different Module 1 scenarios would mix upstream population / rate-environment effects with strategy effects.

================================================================================
9. SECTION 13 COMPARISON READINESS CHECK
================================================================================

Create a non-mutating comparison readiness query.

This should report:

- comparison_set_name
- module1_scenario_set_name
- module1_scenario_name
- population_id
- baseline strategy identifiers
- challenger strategy identifiers
- baseline archived row count
- challenger archived row count
- baseline distinct application_id count
- challenger distinct application_id count
- matched application_id count
- baseline-only application_id count
- challenger-only application_id count
- readiness_status

Recommended readiness_status values:

READY_FOR_MATCHED_COMPARISON:
- baseline rows > 0
- challenger rows > 0
- baseline distinct application count = challenger distinct application count
- matched application count = baseline distinct application count
- baseline-only count = 0
- challenger-only count = 0

NOT_READY_BASELINE_MISSING:
- baseline rows = 0

NOT_READY_CHALLENGER_MISSING:
- challenger rows = 0

NOT_READY_ROW_COUNT_MISMATCH:
- both exist, but baseline / challenger row counts differ

NOT_READY_UNMATCHED_APPLICATIONS:
- row counts may match, but application_id sets are not identical

NOT_READY_DUPLICATE_ARCHIVE_GRAIN:
- either selected slice has duplicate application_id values

This is a diagnostic readiness query, not a table mutation.

================================================================================
10. SECTION 13 QUERY BLOCKS TO BUILD
================================================================================

Please build the following read-only query blocks.

--------------------------------------------------------------------------------
13.1 Archive inventory
--------------------------------------------------------------------------------

Purpose:
Show what archived Module 2 strategy runs are available.

Group by:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

Include:
- row count
- distinct application_id count
- min archive_inserted_ts
- max archive_inserted_ts
- min latest_output_created_ts
- max latest_output_created_ts
- count by decision_outcome if practical, or provide a separate outcome inventory

Interpretation:
This is the first query users run to confirm which strategy slices exist.

--------------------------------------------------------------------------------
13.2 Selected comparison readiness
--------------------------------------------------------------------------------

Use tmp_m2_strategy_comparison_params.

Purpose:
Confirm the selected baseline and challenger strategy slices are suitable for matched comparison.

Include the readiness_status logic described above.

--------------------------------------------------------------------------------
13.3 Portfolio-level archived strategy summary
--------------------------------------------------------------------------------

Purpose:
Compare archived strategies at the portfolio level.

For each selected strategy slice, include:

Counts and rates:
- applications
- approval_count / approval_rate
- counteroffer_count / counteroffer_rate
- manual_review_count / manual_review_rate
- decline_count / decline_rate
- simulated_offer_exposure_count / simulated_offer_exposure_rate

Exposure:
- total_requested_amount
- total_approved_amount
- average_requested_amount
- average_approved_amount
- average_exposure_reduction_pct among counteroffers

Affordability:
- average_requested_payment_to_income_ratio
- average_approved_payment_to_income_ratio for rows with simulated_offer_exposure_flag = TRUE

Risk / economics:
- average estimated_pd
- average estimated_lgd
- total_requested_expected_loss_amount
- total_approved_expected_loss_amount
- average_requested_expected_loss_amount
- average_approved_expected_loss_amount

Reason code:
- top-level primary_reason_family distribution, if practical, or separate reason-code summary query

--------------------------------------------------------------------------------
13.4 Baseline vs challenger portfolio delta summary
--------------------------------------------------------------------------------

Purpose:
Show direct portfolio-level deltas between baseline and challenger.

Output one row for the comparison.

Include:
- delta approval_rate
- delta counteroffer_rate
- delta manual_review_rate
- delta decline_rate
- delta simulated_offer_exposure_rate
- delta total_approved_amount
- delta average_approved_amount
- delta total_approved_expected_loss_amount
- delta average_approved_expected_loss_amount
- delta average_approved_payment_to_income_ratio
- delta average estimated_pd among offered rows
- delta average estimated_pd among declined rows

Use clear naming:
- baseline_*
- challenger_*
- delta_*

Do not treat this as causal proof beyond the matched strategy simulation boundary.

--------------------------------------------------------------------------------
13.5 Decision migration matrix
--------------------------------------------------------------------------------

Purpose:
Show how final decision outcomes changed from baseline to challenger.

Rows should include:
- baseline_decision_outcome
- challenger_decision_outcome
- matched_rows
- pct_of_matched_population

This is one of the most important Section 13 outputs.

It should help answer:
- How many approvals became counteroffers?
- How many approvals became manual reviews?
- How many approvals became declines?
- How many declines became approvals?
- How much movement occurred versus stability?

--------------------------------------------------------------------------------
13.6 Matched applicant-level delta sample
--------------------------------------------------------------------------------

Purpose:
Show row-level examples of the largest strategy movements.

Join baseline and challenger on:
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

Include:
- application_id
- applicant_id
- product_type_policy_key
- score_band_policy_key
- requested_amount
- baseline decision_outcome
- challenger decision_outcome
- baseline primary_reason_code
- challenger primary_reason_code
- baseline approved_amount
- challenger approved_amount
- delta approved_amount
- baseline approved_payment_to_income_ratio
- challenger approved_payment_to_income_ratio
- delta approved_payment_to_income_ratio
- baseline approved_expected_loss_amount
- challenger approved_expected_loss_amount
- delta approved_expected_loss_amount

Sort by:
- largest absolute delta approved_expected_loss_amount
- then largest absolute delta approved_amount

Limit:
- 50 rows

--------------------------------------------------------------------------------
13.7 Product × score matched strategy delta summary
--------------------------------------------------------------------------------

Purpose:
Show where strategy changes concentrate by product and score band.

Group by:
- product_type_policy_key
- score_band_policy_key

Include:
- matched_rows
- baseline approval_rate
- challenger approval_rate
- delta approval_rate
- baseline counteroffer_rate
- challenger counteroffer_rate
- delta counteroffer_rate
- baseline manual_review_rate
- challenger manual_review_rate
- delta manual_review_rate
- baseline decline_rate
- challenger decline_rate
- delta decline_rate
- baseline average approved_amount
- challenger average approved_amount
- delta average approved_amount
- baseline average approved_expected_loss_amount
- challenger average approved_expected_loss_amount
- delta average approved_expected_loss_amount

This is the main segment-level comparison view.

--------------------------------------------------------------------------------
13.8 Reason-code movement summary
--------------------------------------------------------------------------------

Purpose:
Show how strategy explanation codes differ between baseline and challenger.

Include two views:

A. Primary reason distribution by selected strategy
- strategy identifiers
- decision_outcome
- primary_reason_family
- primary_reason_code
- row_count
- pct_of_strategy_population

B. Matched reason-code migration
- baseline_primary_reason_code
- challenger_primary_reason_code
- matched_rows
- pct_of_matched_population

This helps validate whether strategy changes are explainable, not just numeric.

--------------------------------------------------------------------------------
13.9 Simulated offer-exposure comparison
--------------------------------------------------------------------------------

Purpose:
Compare offered-book profiles between baseline and challenger.

For rows where simulated_offer_exposure_flag = TRUE, include:
- offer_count
- total_approved_amount
- average_approved_amount
- average estimated_pd
- average approved_payment_to_income_ratio
- total_approved_expected_loss_amount
- average approved_expected_loss_amount

Also include:
- positive_offer_rate
- counteroffer_share_of_offers
- approval_share_of_offers

This should be presented separately from the total applicant population because manual review and decline rows do not have booked / offered exposure economics.

Use “simulated offer exposure,” not “booked exposure.”

--------------------------------------------------------------------------------
13.10 Unmatched row diagnostic
--------------------------------------------------------------------------------

Purpose:
If readiness_status is not READY_FOR_MATCHED_COMPARISON, provide a diagnostic identifying baseline-only and challenger-only application_id values.

Include:
- application_id
- presence_status:
  BASELINE_ONLY
  CHALLENGER_ONLY

Limit:
- 100 rows

This supports debugging archive selection or archive integrity issues.

================================================================================
11. SECTION 13 COMPARISON METRIC CONVENTIONS
================================================================================

Please preserve these metric conventions:

Approval rate:
approval_count / applications

Counteroffer rate:
counteroffer_count / applications

Manual review rate:
manual_review_count / applications

Decline rate:
decline_count / applications

Simulated offer exposure rate:
simulated_offer_exposure_count / applications

Positive offer outcomes:
APPROVE + COUNTEROFFER

Requested Expected Loss:
requested_expected_loss_amount

Approved Expected Loss:
approved_expected_loss_amount

Estimated-PD proxy:
estimated_pd remains the SQL field name, interpreted only as the synthetic estimated-PD proxy.

Do not rename it in SQL unless explicitly instructed.

Timestamp fields:
Do not use strategy_run_ts, latest_output_created_ts, or archive_inserted_ts as deterministic comparison metrics.

They are audit metadata.

================================================================================
12. SECTION 13 LOCAL READ-ONLY SANITY CHECKS
================================================================================

Because Section 13 is read-only, local checks should be diagnostics rather than mutating gatekeepers.

Include diagnostic checks for:

- selected baseline slice exists
- selected challenger slice exists
- selected baseline and challenger are under the same Module 1 scenario and population
- selected baseline and challenger are not the exact same strategy_set_name + strategy_name + strategy_version
- baseline row count
- challenger row count
- matched application count
- unmatched application count
- duplicate application_id count in each selected slice

Do not block ordinary script execution if only inventory is being reviewed.

But clearly label comparison readiness.

================================================================================
13. SECTION 13 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 13 comments should explain:

- why archive inventory is separated from archive persistence
- why matched comparison requires the same Module 1 scenario and population
- why Module 2 strategy metadata must remain separate from Module 1 scenario metadata
- why row-level matching uses application_id
- why strategy_run_id and timestamps are audit metadata, not matched-comparison keys
- why strategy comparison is read-only
- why decision migration is useful for strategy interpretation
- why requested Expected Loss and approved Expected Loss should both be compared
- why simulated offer exposure is not booked exposure
- why reason-code migration supports explainability
- why Section 13 is not the full QA framework

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.
No adverse-action reason-code language.

================================================================================
14. SECTION 13 DELIVERABLE
================================================================================

Please now provide:

1. Targeted Section 12 patches only:
   - archive schema data-type alignment check
   - expanded persistence mismatch check
   - unique archive grain enforcement if not already present

2. Section 13 SQL only:
   ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK.

3. A short explanation of what Section 13 establishes.

4. A short explanation of what Section 13 intentionally does not build.

5. The recommended next build step after Section 13.

Do not write Section 14+ yet.
<!-- END_MESSAGE C038-M00164 -->


---

<a id="c038-m00167"></a>

### C038-M00167

**ChatGPT** · 2026-05-06T15:59:09.482939-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00167 -->
Section 12 remains accepted after the hardening patches below. These patches strengthen archive governance without changing the strategy logic, outcome logic, exposure logic, or reason-code assignment logic. They preserve the Module 1 lineage and deterministic comparison discipline: Module 1 outputs remain synthetic, governed, scenario-comparable inputs, with `estimated_pd` interpreted as the synthetic estimated-PD proxy and Expected Loss interpreted as a comparative simulation metric. fileciteturn4file0 Module 1 validation confirms that matched scenario comparison depends on stable population lineage and row-level comparability, which Section 13 extends into Module 2 strategy comparison. fileciteturn4file1

# 1. Targeted Section 12 patches only

## Patch 12.A — Archive schema data-type alignment check

Add this to **Section 12.2 — Archive Table Setup and Schema Alignment Check**, inside the existing schema-alignment `DO $$` block.

### BEFORE

```sql
DO $$
DECLARE
    v_missing_archive_columns TEXT;
    v_archive_inserted_ts_exists BOOLEAN;
BEGIN
```

### AFTER

```sql
DO $$
DECLARE
    v_missing_archive_columns TEXT;
    v_type_mismatch_columns TEXT;
    v_unexpected_archive_columns TEXT;
    v_archive_inserted_ts_exists BOOLEAN;
BEGIN
```

Add this block after the missing-column check and before the `archive_inserted_ts` existence check.

```sql
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive schema data-type alignment.

    The archive table may already exist from an earlier implementation version. A missing-column
    check alone is not sufficient because the archive could contain the same column names with
    incompatible data types.

    This is a schema governance check, not a modeling check.

    If the latest-run output schema changes in future development, the archive table may need to be
    altered or recreated so it remains a persisted copy of the governed latest-run output plus
    archive_inserted_ts.
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
    Gatekeeper: unexpected archive columns.

    For Module 2 v1.0, the archive should be a persisted copy of the governed latest-run output
    plus archive_inserted_ts.

    Unexpected extra columns may indicate an older incompatible archive schema. Section 12 fails
    clearly instead of silently inserting into a misaligned archive structure.
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
```

---

## Patch 12.B — Expanded persistence mismatch check

Replace the existing `v_persistence_mismatch_count` comparison block in **Section 12.6** with the expanded version below.

### BEFORE

```sql
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
                ar.decision_outcome IS DISTINCT FROM sd.decision_outcome
             OR ar.decision_path IS DISTINCT FROM sd.decision_path
             OR ar.approval_flag IS DISTINCT FROM sd.approval_flag
             OR ar.counteroffer_flag IS DISTINCT FROM sd.counteroffer_flag
             OR ar.manual_review_flag IS DISTINCT FROM sd.manual_review_flag
             OR ar.decline_flag IS DISTINCT FROM sd.decline_flag
             OR ar.simulated_offer_exposure_flag IS DISTINCT FROM sd.simulated_offer_exposure_flag
             OR ar.approved_amount IS DISTINCT FROM sd.approved_amount
             OR ar.counteroffer_amount IS DISTINCT FROM sd.counteroffer_amount
             OR ar.approved_payment_to_income_ratio IS DISTINCT FROM sd.approved_payment_to_income_ratio
             OR ar.approved_expected_loss_amount IS DISTINCT FROM sd.approved_expected_loss_amount
             OR ar.primary_reason_code IS DISTINCT FROM sd.primary_reason_code
             OR ar.triggered_reason_code_list IS DISTINCT FROM sd.triggered_reason_code_list
          );
```

### AFTER

```sql
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
```

This confirms Section 12 persisted the already-materialized latest-run result without changing final decision, exposure, affordability, Expected Loss, reason-code, or lineage values.

---

## Patch 12.C — Unique archive grain enforcement

Add this immediately before the unique archive row-grain index in **Section 12.7**.

```sql
/*-----------------------------------------------------------------------------------------------
Pre-index duplicate grain check.

If an existing archive table contains duplicate rows at the locked row-level archive grain, the
unique index cannot be created safely. This gatekeeper fails clearly and instructs the user to
reset or clean the archive before matched strategy comparison is used.

Locked row-level archive grain:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id
-----------------------------------------------------------------------------------------------*/
DO $$
DECLARE
    v_duplicate_archive_grain_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO v_duplicate_archive_grain_count
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

    IF v_duplicate_archive_grain_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive contains % duplicate row-level grain group(s). Reset or clean the archive before creating the unique archive grain index.',
            v_duplicate_archive_grain_count;
    END IF;
END $$;
```

Then replace the existing unique index creation with a recreate-safe version.

### BEFORE

```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_archive_row_grain_unique
    ON credit_decisioning_sim.strategy_decisions_archive (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        application_id
    );
```

### AFTER

```sql
DROP INDEX IF EXISTS credit_decisioning_sim.idx_m2_strategy_archive_row_grain_unique;

CREATE UNIQUE INDEX idx_m2_strategy_archive_row_grain_unique
    ON credit_decisioning_sim.strategy_decisions_archive (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        application_id
    );
```

---

# 2. Section 13 SQL only — Archive Inventory and Matched Strategy Comparison Framework

```sql
/***************************************************************************************************
SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Provide read-only archive inventory and matched strategy comparison queries for completed Module 2
    strategy runs.

    Section 13 answers:

        "How do two archived Module 2 strategy runs differ when applied to the same Module 1
         scenario and population?"

    Section 13 does NOT answer:

        "Is the full Module 2 system validated?"

    Full validation is built later after the complete SQL module is assembled and executed.

SQL PURPOSE:
    1. Inspect credit_decisioning_sim.strategy_decisions_archive.
    2. List archived Module 2 strategy slices.
    3. Define comparison parameters for selecting a baseline and challenger strategy.
    4. Diagnose whether the selected archived slices are ready for matched comparison.
    5. Compare selected archived strategies at portfolio, decision migration, row-level, segment,
       reason-code, and simulated offer-exposure levels.
    6. Provide unmatched-row diagnostics when selected slices are not match-ready.

READ-ONLY BOUNDARY:
    Section 13 does not insert, delete, update, or replace archive rows.
    Section 13 does not recalculate decisions, reason codes, approved exposure, approved payment,
    approved PTI, or approved Expected Loss.

    The only table created here is a temporary comparison-parameter table used to select archived
    strategy slices for read-only diagnostics.

WHY ARCHIVE INVENTORY IS SEPARATED FROM ARCHIVE PERSISTENCE:
    Section 12 persists completed latest-run outputs into the archive.
    Section 13 inspects those archived outputs.

    This separation prevents comparison logic from modifying archive history.

WHY MATCHED COMPARISON REQUIRES THE SAME MODULE 1 SCENARIO AND POPULATION:
    Module 2 strategy comparison should isolate downstream strategy effects.

    For Module 2 v1.0, matched strategy comparison requires:
        same module1_scenario_set_name
        same module1_scenario_name
        same population_id

    Comparing across different Module 1 scenarios would mix upstream synthetic population or
    risk-environment effects with downstream strategy effects.

MODULE 1 SCENARIO METADATA VS MODULE 2 STRATEGY METADATA:
    Module 1 scenario metadata:
        module1_scenario_set_name
        module1_scenario_name
        population_id

    Module 2 strategy metadata:
        strategy_set_name
        strategy_name
        strategy_version

    These concepts remain separate.

WHY ROW-LEVEL MATCHING USES APPLICATION_ID:
    application_id is the row-level synthetic application identifier.

    Matched comparison joins baseline and challenger rows using:
        module1_scenario_set_name
        module1_scenario_name
        population_id
        application_id

    This preserves the same synthetic applicant across strategy runs.

AUDIT METADATA BOUNDARY:
    strategy_run_id, strategy_run_ts, latest_output_created_ts, and archive_inserted_ts are audit
    metadata.

    They support traceability but are not matched-comparison keys and should not define deterministic
    comparison grain.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount:
        approved-exposure Expected Loss created by Module 2 after exposure treatment.

    Both are compared because strategy changes may alter approved exposure while requested exposure
    remains constant.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 13, estimated_pd is interpreted as the synthetic estimated-PD proxy.
    It is not a calibrated production probability of default.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER simulated positive offer
    exposure.

    It does not imply operational account creation, funded exposure, production approval, or real
    customer treatment.

REASON-CODE MIGRATION:
    Reason-code migration helps explain how strategy outcomes changed, not merely that they changed.

    primary_reason_code and related fields are simulated strategy explanation codes only.

SECTION 13 IS NOT THE FULL QA FRAMEWORK:
    Section 13 provides archive inventory and matched strategy comparison diagnostics.
    Full Module 2 QA is built later.

***************************************************************************************************/



/***************************************************************************************************
SECTION 13.0 — COMPARISON PARAMETER TABLE
****************************************************************************************************

Purpose:
    Select one archived baseline strategy slice and one archived challenger strategy slice.

Users should update these placeholder values to archived slices that exist in:
    credit_decisioning_sim.strategy_decisions_archive

For Module 2 v1.0, the baseline and challenger should share:
    module1_scenario_set_name
    module1_scenario_name
    population_id

and should differ by:
    strategy_name and/or strategy_version

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_strategy_comparison_params;

CREATE TEMP TABLE tmp_m2_strategy_comparison_params (
    comparison_set_name              TEXT,

    baseline_strategy_set_name        TEXT,
    baseline_strategy_name            TEXT,
    baseline_strategy_version         TEXT,

    challenger_strategy_set_name      TEXT,
    challenger_strategy_name          TEXT,
    challenger_strategy_version       TEXT,

    module1_scenario_set_name         TEXT,
    module1_scenario_name             TEXT,
    population_id                     TEXT
) ON COMMIT PRESERVE ROWS;


/*-----------------------------------------------------------------------------------------------
Placeholder comparison parameters.

Replace these values with archived strategy identifiers before using the selected comparison outputs.
If the placeholders do not exist in the archive, Section 13 readiness output will clearly report that
matched comparison is not ready.
-----------------------------------------------------------------------------------------------*/
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
VALUES (
    'MODULE2_BASELINE_VS_CHALLENGER_PLACEHOLDER',

    'MODULE2_BASELINE_STRATEGY_SET',
    'BASELINE_STRATEGY',
    'V1_0',

    'MODULE2_CHALLENGER_STRATEGY_SET',
    'CHALLENGER_STRATEGY',
    'V1_0',

    'MODULE1_V2_BASELINE_SET',
    'BASELINE_V2',
    'BASE_POPULATION_V1'
);



/***************************************************************************************************
SECTION 13.1 — ARCHIVE INVENTORY
****************************************************************************************************

Purpose:
    Show which archived Module 2 strategy slices are available.

Interpretation:
    This is the first query users should review before setting comparison parameters.

***************************************************************************************************/

SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    COUNT(*) AS archived_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approve_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

    MIN(latest_output_created_ts) AS min_latest_output_created_ts,
    MAX(latest_output_created_ts) AS max_latest_output_created_ts,
    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts
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
13.1B Archive outcome inventory.

Purpose:
    Provide a compact outcome distribution for every archived strategy slice.
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
        100.0 * COUNT(*)
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
    ) AS pct_of_archived_strategy_slice
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



/***************************************************************************************************
SECTION 13.2 — SELECTED COMPARISON READINESS
****************************************************************************************************

Purpose:
    Confirm whether the selected baseline and challenger archived strategy slices are suitable for
    matched comparison.

This query does not fail the script. It reports readiness.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
baseline AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
challenger AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
baseline_applications AS (
    SELECT application_id, COUNT(*) AS row_count
    FROM baseline
    GROUP BY application_id
),
challenger_applications AS (
    SELECT application_id, COUNT(*) AS row_count
    FROM challenger
    GROUP BY application_id
),
counts AS (
    SELECT
        (SELECT COUNT(*) FROM baseline) AS baseline_archived_row_count,
        (SELECT COUNT(*) FROM challenger) AS challenger_archived_row_count,

        (SELECT COUNT(DISTINCT application_id) FROM baseline) AS baseline_distinct_application_id_count,
        (SELECT COUNT(DISTINCT application_id) FROM challenger) AS challenger_distinct_application_id_count,

        (
            SELECT COUNT(*)
            FROM baseline_applications b
            JOIN challenger_applications c
                ON c.application_id = b.application_id
        ) AS matched_application_id_count,

        (
            SELECT COUNT(*)
            FROM baseline_applications b
            LEFT JOIN challenger_applications c
                ON c.application_id = b.application_id
            WHERE c.application_id IS NULL
        ) AS baseline_only_application_id_count,

        (
            SELECT COUNT(*)
            FROM challenger_applications c
            LEFT JOIN baseline_applications b
                ON b.application_id = c.application_id
            WHERE b.application_id IS NULL
        ) AS challenger_only_application_id_count,

        (
            SELECT COUNT(*)
            FROM baseline_applications
            WHERE row_count > 1
        ) AS baseline_duplicate_application_id_count,

        (
            SELECT COUNT(*)
            FROM challenger_applications
            WHERE row_count > 1
        ) AS challenger_duplicate_application_id_count
)
SELECT
    p.comparison_set_name,

    p.module1_scenario_set_name,
    p.module1_scenario_name,
    p.population_id,

    p.baseline_strategy_set_name,
    p.baseline_strategy_name,
    p.baseline_strategy_version,

    p.challenger_strategy_set_name,
    p.challenger_strategy_name,
    p.challenger_strategy_version,

    c.baseline_archived_row_count,
    c.challenger_archived_row_count,
    c.baseline_distinct_application_id_count,
    c.challenger_distinct_application_id_count,
    c.matched_application_id_count,
    c.baseline_only_application_id_count,
    c.challenger_only_application_id_count,
    c.baseline_duplicate_application_id_count,
    c.challenger_duplicate_application_id_count,

    (
        p.baseline_strategy_set_name = p.challenger_strategy_set_name
        AND p.baseline_strategy_name = p.challenger_strategy_name
        AND p.baseline_strategy_version = p.challenger_strategy_version
    ) AS same_strategy_selected_flag,

    CASE
        WHEN p.baseline_strategy_set_name = p.challenger_strategy_set_name
         AND p.baseline_strategy_name = p.challenger_strategy_name
         AND p.baseline_strategy_version = p.challenger_strategy_version
            THEN 'NOT_READY_SAME_STRATEGY_SELECTED'

        WHEN c.baseline_archived_row_count = 0
            THEN 'NOT_READY_BASELINE_MISSING'

        WHEN c.challenger_archived_row_count = 0
            THEN 'NOT_READY_CHALLENGER_MISSING'

        WHEN c.baseline_duplicate_application_id_count > 0
          OR c.challenger_duplicate_application_id_count > 0
            THEN 'NOT_READY_DUPLICATE_ARCHIVE_GRAIN'

        WHEN c.baseline_archived_row_count <> c.challenger_archived_row_count
          OR c.baseline_distinct_application_id_count <> c.challenger_distinct_application_id_count
            THEN 'NOT_READY_ROW_COUNT_MISMATCH'

        WHEN c.baseline_only_application_id_count > 0
          OR c.challenger_only_application_id_count > 0
            THEN 'NOT_READY_UNMATCHED_APPLICATIONS'

        WHEN c.baseline_archived_row_count > 0
         AND c.challenger_archived_row_count > 0
         AND c.baseline_distinct_application_id_count = c.challenger_distinct_application_id_count
         AND c.matched_application_id_count = c.baseline_distinct_application_id_count
         AND c.baseline_only_application_id_count = 0
         AND c.challenger_only_application_id_count = 0
            THEN 'READY_FOR_MATCHED_COMPARISON'

        ELSE 'NOT_READY_REVIEW_REQUIRED'
    END AS readiness_status
FROM params p
CROSS JOIN counts c;



/***************************************************************************************************
SECTION 13.3 — PORTFOLIO-LEVEL ARCHIVED STRATEGY SUMMARY
****************************************************************************************************

Purpose:
    Compare selected archived strategies at the portfolio level.

Interpretation:
    This is a strategy-simulation summary only. It is not causal proof outside the controlled
    matched-strategy simulation boundary.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
selected_archive AS (
    SELECT
        'BASELINE'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)
SELECT
    selected_strategy_role,
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
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS simulated_offer_exposure_count,

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
    SUM(approved_amount) AS total_approved_amount,
    AVG(requested_amount) AS average_requested_amount,
    AVG(approved_amount) AS average_approved_amount,
    AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
        AS average_exposure_reduction_pct_among_counteroffers,

    AVG(requested_payment_to_income_ratio) AS average_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS average_approved_payment_to_income_ratio_for_offers,

    AVG(estimated_pd) AS average_synthetic_estimated_pd_proxy,
    AVG(estimated_lgd) AS average_estimated_lgd,

    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
    SUM(approved_expected_loss_amount) AS total_approved_expected_loss_amount,
    AVG(requested_expected_loss_amount) AS average_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS average_approved_expected_loss_amount
FROM selected_archive
GROUP BY
    selected_strategy_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
ORDER BY selected_strategy_role;



/***************************************************************************************************
SECTION 13.4 — BASELINE VS CHALLENGER PORTFOLIO DELTA SUMMARY
****************************************************************************************************

Purpose:
    Show direct portfolio-level deltas between selected baseline and challenger strategies.

Metric convention:
    delta_* = challenger_* - baseline_*

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
selected_archive AS (
    SELECT
        'BASELINE'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
summary AS (
    SELECT
        selected_strategy_role,

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

        SUM(approved_amount) AS total_approved_amount,
        AVG(approved_amount) AS average_approved_amount,

        SUM(approved_expected_loss_amount) AS total_approved_expected_loss_amount,
        AVG(approved_expected_loss_amount) AS average_approved_expected_loss_amount,

        AVG(approved_payment_to_income_ratio)
            FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS average_approved_payment_to_income_ratio_for_offers,

        AVG(estimated_pd)
            FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS average_synthetic_estimated_pd_proxy_among_offered_rows,

        AVG(estimated_pd)
            FILTER (WHERE decision_outcome = 'DECLINE')
            AS average_synthetic_estimated_pd_proxy_among_declined_rows
    FROM selected_archive
    GROUP BY selected_strategy_role
),
pivoted AS (
    SELECT
        MAX(applications) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_applications,
        MAX(applications) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_applications,

        MAX(approval_rate) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_approval_rate,
        MAX(approval_rate) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_approval_rate,

        MAX(counteroffer_rate) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_counteroffer_rate,
        MAX(counteroffer_rate) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_counteroffer_rate,

        MAX(manual_review_rate) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_manual_review_rate,
        MAX(manual_review_rate) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_manual_review_rate,

        MAX(decline_rate) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_decline_rate,
        MAX(decline_rate) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_decline_rate,

        MAX(simulated_offer_exposure_rate) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_simulated_offer_exposure_rate,
        MAX(simulated_offer_exposure_rate) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_simulated_offer_exposure_rate,

        MAX(total_approved_amount) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_total_approved_amount,
        MAX(total_approved_amount) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_total_approved_amount,

        MAX(average_approved_amount) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_average_approved_amount,
        MAX(average_approved_amount) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_average_approved_amount,

        MAX(total_approved_expected_loss_amount) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_total_approved_expected_loss_amount,
        MAX(total_approved_expected_loss_amount) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_total_approved_expected_loss_amount,

        MAX(average_approved_expected_loss_amount) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_average_approved_expected_loss_amount,
        MAX(average_approved_expected_loss_amount) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_average_approved_expected_loss_amount,

        MAX(average_approved_payment_to_income_ratio_for_offers) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_average_approved_payment_to_income_ratio_for_offers,
        MAX(average_approved_payment_to_income_ratio_for_offers) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_average_approved_payment_to_income_ratio_for_offers,

        MAX(average_synthetic_estimated_pd_proxy_among_offered_rows) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_average_synthetic_estimated_pd_proxy_among_offered_rows,
        MAX(average_synthetic_estimated_pd_proxy_among_offered_rows) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_average_synthetic_estimated_pd_proxy_among_offered_rows,

        MAX(average_synthetic_estimated_pd_proxy_among_declined_rows) FILTER (WHERE selected_strategy_role = 'BASELINE') AS baseline_average_synthetic_estimated_pd_proxy_among_declined_rows,
        MAX(average_synthetic_estimated_pd_proxy_among_declined_rows) FILTER (WHERE selected_strategy_role = 'CHALLENGER') AS challenger_average_synthetic_estimated_pd_proxy_among_declined_rows
    FROM summary
)
SELECT
    p.comparison_set_name,
    p.module1_scenario_set_name,
    p.module1_scenario_name,
    p.population_id,

    baseline_applications,
    challenger_applications,

    baseline_approval_rate,
    challenger_approval_rate,
    challenger_approval_rate - baseline_approval_rate AS delta_approval_rate,

    baseline_counteroffer_rate,
    challenger_counteroffer_rate,
    challenger_counteroffer_rate - baseline_counteroffer_rate AS delta_counteroffer_rate,

    baseline_manual_review_rate,
    challenger_manual_review_rate,
    challenger_manual_review_rate - baseline_manual_review_rate AS delta_manual_review_rate,

    baseline_decline_rate,
    challenger_decline_rate,
    challenger_decline_rate - baseline_decline_rate AS delta_decline_rate,

    baseline_simulated_offer_exposure_rate,
    challenger_simulated_offer_exposure_rate,
    challenger_simulated_offer_exposure_rate - baseline_simulated_offer_exposure_rate
        AS delta_simulated_offer_exposure_rate,

    baseline_total_approved_amount,
    challenger_total_approved_amount,
    challenger_total_approved_amount - baseline_total_approved_amount
        AS delta_total_approved_amount,

    baseline_average_approved_amount,
    challenger_average_approved_amount,
    challenger_average_approved_amount - baseline_average_approved_amount
        AS delta_average_approved_amount,

    baseline_total_approved_expected_loss_amount,
    challenger_total_approved_expected_loss_amount,
    challenger_total_approved_expected_loss_amount - baseline_total_approved_expected_loss_amount
        AS delta_total_approved_expected_loss_amount,

    baseline_average_approved_expected_loss_amount,
    challenger_average_approved_expected_loss_amount,
    challenger_average_approved_expected_loss_amount - baseline_average_approved_expected_loss_amount
        AS delta_average_approved_expected_loss_amount,

    baseline_average_approved_payment_to_income_ratio_for_offers,
    challenger_average_approved_payment_to_income_ratio_for_offers,
    challenger_average_approved_payment_to_income_ratio_for_offers
        - baseline_average_approved_payment_to_income_ratio_for_offers
        AS delta_average_approved_payment_to_income_ratio_for_offers,

    baseline_average_synthetic_estimated_pd_proxy_among_offered_rows,
    challenger_average_synthetic_estimated_pd_proxy_among_offered_rows,
    challenger_average_synthetic_estimated_pd_proxy_among_offered_rows
        - baseline_average_synthetic_estimated_pd_proxy_among_offered_rows
        AS delta_average_synthetic_estimated_pd_proxy_among_offered_rows,

    baseline_average_synthetic_estimated_pd_proxy_among_declined_rows,
    challenger_average_synthetic_estimated_pd_proxy_among_declined_rows,
    challenger_average_synthetic_estimated_pd_proxy_among_declined_rows
        - baseline_average_synthetic_estimated_pd_proxy_among_declined_rows
        AS delta_average_synthetic_estimated_pd_proxy_among_declined_rows
FROM params p
CROSS JOIN pivoted;



/***************************************************************************************************
SECTION 13.5 — DECISION MIGRATION MATRIX
****************************************************************************************************

Purpose:
    Show how final decision outcomes changed from baseline to challenger.

This is one of the most important Section 13 outputs.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
baseline AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
challenger AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
matched AS (
    SELECT
        b.application_id,
        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome
    FROM baseline b
    JOIN challenger c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)
SELECT
    baseline_decision_outcome,
    challenger_decision_outcome,
    COUNT(*) AS matched_rows,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population
FROM matched
GROUP BY
    baseline_decision_outcome,
    challenger_decision_outcome
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
    END;



/***************************************************************************************************
SECTION 13.6 — MATCHED APPLICANT-LEVEL DELTA SAMPLE
****************************************************************************************************

Purpose:
    Show row-level examples of the largest strategy movements.

Interpretation:
    Manual review rows have unresolved exposure fields. For delta sorting, NULL approved exposure is
    treated as zero simulated offer exposure only for comparison ranking.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
baseline AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
challenger AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
matched AS (
    SELECT
        b.application_id,
        b.applicant_id,
        b.product_type_policy_key,
        b.score_band_policy_key,
        b.requested_amount,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.primary_reason_code AS baseline_primary_reason_code,
        c.primary_reason_code AS challenger_primary_reason_code,

        b.approved_amount AS baseline_approved_amount,
        c.approved_amount AS challenger_approved_amount,
        COALESCE(c.approved_amount, 0) - COALESCE(b.approved_amount, 0)
            AS delta_approved_amount,

        b.approved_payment_to_income_ratio AS baseline_approved_payment_to_income_ratio,
        c.approved_payment_to_income_ratio AS challenger_approved_payment_to_income_ratio,
        COALESCE(c.approved_payment_to_income_ratio, 0) - COALESCE(b.approved_payment_to_income_ratio, 0)
            AS delta_approved_payment_to_income_ratio,

        b.approved_expected_loss_amount AS baseline_approved_expected_loss_amount,
        c.approved_expected_loss_amount AS challenger_approved_expected_loss_amount,
        COALESCE(c.approved_expected_loss_amount, 0) - COALESCE(b.approved_expected_loss_amount, 0)
            AS delta_approved_expected_loss_amount
    FROM baseline b
    JOIN challenger c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)
SELECT *
FROM matched
ORDER BY
    ABS(delta_approved_expected_loss_amount) DESC,
    ABS(delta_approved_amount) DESC,
    application_id
LIMIT 50;



/***************************************************************************************************
SECTION 13.7 — PRODUCT × SCORE MATCHED STRATEGY DELTA SUMMARY
****************************************************************************************************

Purpose:
    Show where strategy changes concentrate by product and score band.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
baseline AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
challenger AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
matched AS (
    SELECT
        b.product_type_policy_key,
        b.score_band_policy_key,

        b.decision_outcome AS baseline_decision_outcome,
        c.decision_outcome AS challenger_decision_outcome,

        b.approved_amount AS baseline_approved_amount,
        c.approved_amount AS challenger_approved_amount,

        b.approved_expected_loss_amount AS baseline_approved_expected_loss_amount,
        c.approved_expected_loss_amount AS challenger_approved_expected_loss_amount
    FROM baseline b
    JOIN challenger c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)
SELECT
    product_type_policy_key,
    score_band_policy_key,

    COUNT(*) AS matched_rows,

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

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_counteroffer_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_counteroffer_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_counteroffer_rate,

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_manual_review_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_manual_review_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'MANUAL_REVIEW')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_manual_review_rate,

    COUNT(*) FILTER (WHERE baseline_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS baseline_decline_rate,
    COUNT(*) FILTER (WHERE challenger_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0) AS challenger_decline_rate,
    (
        COUNT(*) FILTER (WHERE challenger_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0)
    )
    -
    (
        COUNT(*) FILTER (WHERE baseline_decision_outcome = 'DECLINE')::NUMERIC
        / NULLIF(COUNT(*), 0)
    ) AS delta_decline_rate,

    AVG(baseline_approved_amount) AS baseline_average_approved_amount,
    AVG(challenger_approved_amount) AS challenger_average_approved_amount,
    AVG(challenger_approved_amount) - AVG(baseline_approved_amount)
        AS delta_average_approved_amount,

    AVG(baseline_approved_expected_loss_amount) AS baseline_average_approved_expected_loss_amount,
    AVG(challenger_approved_expected_loss_amount) AS challenger_average_approved_expected_loss_amount,
    AVG(challenger_approved_expected_loss_amount) - AVG(baseline_approved_expected_loss_amount)
        AS delta_average_approved_expected_loss_amount
FROM matched
GROUP BY
    product_type_policy_key,
    score_band_policy_key
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



/***************************************************************************************************
SECTION 13.8 — REASON-CODE MOVEMENT SUMMARY
****************************************************************************************************

Purpose:
    Show how simulated strategy explanation codes differ between selected strategies.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
13.8A Primary reason distribution by selected strategy.
-----------------------------------------------------------------------------------------------*/
WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
selected_archive AS (
    SELECT
        'BASELINE'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)
SELECT
    selected_strategy_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    decision_outcome,
    primary_reason_family,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)
        / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY selected_strategy_role), 0),
        2
    ) AS pct_of_strategy_population
FROM selected_archive
GROUP BY
    selected_strategy_role,
    strategy_set_name,
    strategy_name,
    strategy_version,
    decision_outcome,
    primary_reason_family,
    primary_reason_code
ORDER BY
    selected_strategy_role,
    decision_outcome,
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
13.8B Matched reason-code migration.
-----------------------------------------------------------------------------------------------*/
WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
baseline AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
challenger AS (
    SELECT ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
matched AS (
    SELECT
        b.primary_reason_code AS baseline_primary_reason_code,
        c.primary_reason_code AS challenger_primary_reason_code
    FROM baseline b
    JOIN challenger c
        ON c.module1_scenario_set_name = b.module1_scenario_set_name
       AND c.module1_scenario_name = b.module1_scenario_name
       AND c.population_id = b.population_id
       AND c.application_id = b.application_id
)
SELECT
    baseline_primary_reason_code,
    challenger_primary_reason_code,
    COUNT(*) AS matched_rows,
    ROUND(
        100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS pct_of_matched_population
FROM matched
GROUP BY
    baseline_primary_reason_code,
    challenger_primary_reason_code
ORDER BY
    matched_rows DESC,
    baseline_primary_reason_code,
    challenger_primary_reason_code;



/***************************************************************************************************
SECTION 13.9 — SIMULATED OFFER-EXPOSURE COMPARISON
****************************************************************************************************

Purpose:
    Compare simulated positive offer-exposure profiles between selected strategies.

Boundary:
    This is simulated offer exposure only. It is not operational account creation or funded exposure.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
selected_archive AS (
    SELECT
        'BASELINE'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id

    UNION ALL

    SELECT
        'CHALLENGER'::TEXT AS selected_strategy_role,
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
)
SELECT
    selected_strategy_role,
    strategy_set_name,
    strategy_name,
    strategy_version,

    COUNT(*) AS applications,

    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
    COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
        / NULLIF(COUNT(*), 0) AS positive_offer_rate,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_offer_count,
    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_offer_count,

    COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
        AS approval_share_of_offers,

    COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
        / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
        AS counteroffer_share_of_offers,

    SUM(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_amount,

    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS average_approved_amount,

    AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS average_synthetic_estimated_pd_proxy,

    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS average_approved_payment_to_income_ratio,

    SUM(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS total_approved_expected_loss_amount,

    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
        AS average_approved_expected_loss_amount
FROM selected_archive
GROUP BY
    selected_strategy_role,
    strategy_set_name,
    strategy_name,
    strategy_version
ORDER BY selected_strategy_role;



/***************************************************************************************************
SECTION 13.10 — UNMATCHED ROW DIAGNOSTIC
****************************************************************************************************

Purpose:
    If readiness_status is not READY_FOR_MATCHED_COMPARISON, identify baseline-only and
    challenger-only application_id values.

This supports debugging archive selection or archive integrity issues.

***************************************************************************************************/

WITH params AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_params
    LIMIT 1
),
baseline_applications AS (
    SELECT DISTINCT
        ar.application_id
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.baseline_strategy_set_name
       AND ar.strategy_name = p.baseline_strategy_name
       AND ar.strategy_version = p.baseline_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
challenger_applications AS (
    SELECT DISTINCT
        ar.application_id
    FROM credit_decisioning_sim.strategy_decisions_archive ar
    JOIN params p
        ON ar.strategy_set_name = p.challenger_strategy_set_name
       AND ar.strategy_name = p.challenger_strategy_name
       AND ar.strategy_version = p.challenger_strategy_version
       AND ar.module1_scenario_set_name = p.module1_scenario_set_name
       AND ar.module1_scenario_name = p.module1_scenario_name
       AND ar.population_id = p.population_id
),
unmatched AS (
    SELECT
        b.application_id,
        'BASELINE_ONLY'::TEXT AS presence_status
    FROM baseline_applications b
    LEFT JOIN challenger_applications c
        ON c.application_id = b.application_id
    WHERE c.application_id IS NULL

    UNION ALL

    SELECT
        c.application_id,
        'CHALLENGER_ONLY'::TEXT AS presence_status
    FROM challenger_applications c
    LEFT JOIN baseline_applications b
        ON b.application_id = c.application_id
    WHERE b.application_id IS NULL
)
SELECT
    application_id,
    presence_status
FROM unmatched
ORDER BY
    presence_status,
    application_id
LIMIT 100;


/***************************************************************************************************
END OF SECTION 13 — ARCHIVE INVENTORY AND MATCHED STRATEGY COMPARISON FRAMEWORK

If execution reaches this point:
    1. Archive inventory queries are available.
    2. Comparison parameters are available through tmp_m2_strategy_comparison_params.
    3. Selected comparison readiness can be diagnosed.
    4. Portfolio-level baseline / challenger summaries can be reviewed.
    5. Portfolio-level deltas can be reviewed.
    6. Decision migration can be reviewed.
    7. Matched applicant-level deltas can be sampled.
    8. Product × score matched strategy deltas can be reviewed.
    9. Reason-code distribution and migration can be reviewed.
    10. Simulated offer-exposure comparison can be reviewed.
    11. Unmatched application diagnostics can be reviewed.

No archive rows have been inserted, deleted, or updated.
No decision outcomes have been recalculated.
No approved exposure or approved Expected Loss has been recalculated.
No simulated reason codes have been reassigned.
No full Module 2 QA framework has been created.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

# 3. What Section 13 establishes

Section 13 establishes a read-only archive inventory and matched strategy comparison framework. It allows users to inspect archived Module 2 strategy slices, select a baseline and challenger, test whether those slices are match-ready, compare portfolio-level outcomes, review decision migration, inspect row-level deltas, analyze product × score movements, compare reason-code migration, and evaluate simulated offer-exposure differences.

# 4. What Section 13 intentionally does not build

Section 13 does not modify the archive, recalculate outcomes, reassign reason codes, recalculate approved exposure, build the full QA framework, create dashboards, or draft BRD / Validation Summary documentation.

# 5. Recommended next build step

Next should be:

```text
Section 14 — Module 2 Validation, QA, and Strategy Tuning Pass
```

That section should validate the completed Module 2 pipeline end-to-end, including structural integrity, decision distribution, risk ordering, affordability sensitivity, reason-code coverage, approved exposure consistency, archive persistence, and matched strategy comparison behavior.
<!-- END_MESSAGE C038-M00167 -->


---

<a id="c038-m00169"></a>

### C038-M00169

**Andrew** · 2026-05-06T16:24:04.870000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00169 -->
This is strong. I agree with the Section 12 targeted patches and the Section 13 Archive Inventory and Matched Strategy Comparison Framework.

Section 13 correctly:
- consumes credit_decisioning_sim.strategy_decisions_archive
- remains read-only
- provides archive inventory
- creates a comparison parameter table
- supports baseline vs challenger strategy comparison
- requires the same Module 1 scenario and population for v1.0 matched strategy comparison
- preserves the distinction between Module 1 scenario metadata and Module 2 strategy metadata
- uses application_id for row-level matching
- provides comparison readiness diagnostics
- provides portfolio-level strategy summaries
- provides baseline vs challenger delta summaries
- provides decision migration analysis
- provides matched applicant-level delta samples
- provides product × score matched strategy deltas
- provides reason-code movement analysis
- provides simulated offer-exposure comparison
- provides unmatched-row diagnostics
- avoids archive mutation
- avoids decision recalculation
- avoids reason-code recalculation
- avoids approved exposure / approved Expected Loss recalculation
- avoids full Module 2 QA
- avoids BRD or Validation Summary documentation

Treat Section 13 as provisionally accepted, subject to the targeted refinements below.

Do not rewrite Sections 0–13 in full unless necessary.

================================================================================
1. TARGETED SECTION 13 PATCH — SAME-STRATEGY COMPARISON READINESS CHECK
================================================================================

Please add an explicit readiness check preventing users from accidentally comparing the exact same strategy slice to itself.

Current Section 13 already compares baseline and challenger strategy identifiers, but the readiness framework should explicitly label this failure mode.

Add readiness_status value:

NOT_READY_SAME_STRATEGY_SELECTED

Condition:

baseline_strategy_set_name = challenger_strategy_set_name
AND baseline_strategy_name = challenger_strategy_name
AND baseline_strategy_version = challenger_strategy_version

Reason:
A matched comparison between identical strategy identifiers may be useful for reproducibility testing in some future workflow, but Section 13 v1.0 is intended for comparing different archived Module 2 strategy runs.

If a user selects the same strategy on both sides, the framework should clearly identify that no strategy comparison is being performed.

Commentary should explain:
- same-strategy comparison is not a valid v1.0 strategy delta comparison
- deterministic reproducibility testing can be designed later if needed
- Section 13 v1.0 is focused on baseline vs challenger strategy comparison

================================================================================
2. TARGETED SECTION 13 PATCH — CLARIFY NULL-SENSITIVE APPROVED-EXPOSURE METRICS
================================================================================

Please disambiguate portfolio-level and segment-level metrics involving approved_amount, approved_payment_to_income_ratio, and approved_expected_loss_amount.

Reason:
APPROVE and COUNTEROFFER rows have approved exposure.
DECLINE rows have zero approved exposure.
MANUAL_REVIEW rows are unresolved and use NULL approved exposure fields by design.

Therefore, an expression like:

AVG(approved_amount)

can be ambiguous because NULL manual-review rows are excluded automatically.

Please use explicit metric names and formulas.

Recommended conventions:

All-application approved exposure metrics:
- avg_approved_amount_all_apps =
    AVG(COALESCE(approved_amount, 0))

- total_approved_amount =
    SUM(COALESCE(approved_amount, 0))

- avg_approved_expected_loss_all_apps =
    AVG(COALESCE(approved_expected_loss_amount, 0))

- total_approved_expected_loss =
    SUM(COALESCE(approved_expected_loss_amount, 0))

Simulated-offer-only metrics:
- avg_approved_amount_offer_rows =
    AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag = TRUE)

- avg_approved_pti_offer_rows =
    AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag = TRUE)

- avg_approved_expected_loss_offer_rows =
    AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag = TRUE)

Manual-review rows should remain unresolved.
Do not force manual-review approved_amount to zero in the source data.

Interpretation:
- all-app metrics describe portfolio-level simulated exposure impact
- offer-only metrics describe the profile of rows receiving simulated offer exposure
- manual review remains unresolved by design

Apply this convention consistently in:
- portfolio-level archived strategy summary
- baseline vs challenger portfolio delta summary
- product × score matched strategy delta summary
- simulated offer-exposure comparison

================================================================================
3. TARGETED SECTION 13 PATCH — SAFE RATE AND DELTA DENOMINATORS
================================================================================

Please ensure all Section 13 rates and percentages use explicit safe denominators.

Use NULLIF in denominators.

Examples:

approval_rate =
    approval_count::NUMERIC / NULLIF(applications, 0)

pct_of_matched_population =
    matched_rows::NUMERIC / NULLIF(total_matched_rows, 0)

delta_approval_rate =
    challenger_approval_rate - baseline_approval_rate

Do not rely on implicit integer division.

Reason:
Section 13 should remain robust even when a selected archive slice is missing, unmatched, or not ready for comparison.

This is especially important because Section 13 is read-only and diagnostic; it should make non-readiness visible rather than failing unexpectedly in ordinary inventory review.

================================================================================
4. TARGETED SECTION 13 PATCH — MATCHED COMPARISON SHOULD USE MATCHED POPULATION DENOMINATOR
================================================================================

For decision migration and matched applicant-level delta summaries, make sure the denominator is the matched population count, not the baseline row count or challenger row count.

Decision migration matrix should calculate:

pct_of_matched_population =
    matched_rows / total_matched_rows

Where total_matched_rows comes from the joined baseline/challenger matched set.

Reason:
If baseline and challenger are not fully matched, the migration matrix should not pretend it represents the full population. The readiness query already identifies not-ready cases, but the migration metric should still be correctly denominated.

================================================================================
5. TARGETED SECTION 13 PATCH — TERMINOLOGY CLEANUP
================================================================================

Please review Section 13 commentary and query aliases for “booked,” “book,” or “approved-book” language.

Preferred terminology:
- simulated offer exposure
- offered population
- positive offer outcomes
- simulated offer-exposure profile
- offer rows

Avoid:
- booked exposure
- booked account
- approved book
- booked-book
- funded exposure

Reason:
Module 2 simulates strategy outcomes on synthetic applicants. It does not represent real booked accounts, funded exposures, or operational customer treatment.

If any query currently uses approved_book_* naming, please rename it to simulated_offer_* or offer_exposure_*.

================================================================================
6. TARGETED SECTION 13 PATCH — REASON-CODE MOVEMENT SHOULD INCLUDE FAMILY AND CODE
================================================================================

Please make sure reason-code movement outputs include both reason family and reason code.

For primary reason distribution, include:
- decision_outcome
- primary_reason_family
- primary_reason_code
- row_count
- pct_of_strategy_population

For matched reason-code migration, include:
- baseline_primary_reason_family
- baseline_primary_reason_code
- challenger_primary_reason_family
- challenger_primary_reason_code
- matched_rows
- pct_of_matched_population

Reason:
Reason-code migration is more interpretable when the broad family movement and the specific code movement are both visible.

Example:
A movement from POLICY_STOP / POLICY_STOP_HIGH_DTI to MANUAL_REVIEW / MANUAL_REVIEW_ELEVATED_DTI is analytically different from a movement within the same family.

================================================================================
7. SECTION 13 ACCEPTANCE CRITERIA
================================================================================

After these targeted refinements, treat Section 13 as accepted if:

- it is read-only
- it does not insert, delete, update, or modify archive rows
- it does not recalculate decision_outcome
- it does not recalculate reason codes
- it does not recalculate approved exposure
- it does not recalculate approved Expected Loss
- it provides archive inventory
- it provides comparison parameter controls
- it clearly requires same Module 1 scenario and population for v1.0 matched comparison
- it prevents or clearly flags same-strategy comparison
- it reports comparison readiness
- it reports missing baseline or missing challenger slices
- it reports row-count mismatches
- it reports unmatched application_id counts
- it reports duplicate archive grain diagnostics
- it provides portfolio-level strategy summaries
- it provides baseline vs challenger delta summaries
- it provides decision migration matrix
- it provides matched applicant-level delta sample
- it provides product × score strategy delta summary
- it provides reason-code distribution and migration outputs
- it provides simulated offer-exposure comparison
- it provides unmatched-row diagnostics
- all rates use safe denominators
- matched comparison rates use matched-population denominators
- all approved-exposure metrics distinguish all-app vs offer-only interpretations
- no booked-account language appears
- no adverse-action, regulatory, customer-notice, or fair-lending language appears
- it does not build the full Module 2 QA framework
- it does not draft BRD or Validation Summary documentation

================================================================================
8. NEXT BUILD SCOPE: SECTION 14 ONLY
================================================================================

After the targeted Section 13 refinements, please build only:

SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS

Section 14 should consume:

credit_decisioning_sim.strategy_decisions

and, where useful for archive-readiness context:

credit_decisioning_sim.strategy_decisions_archive

However, Section 14 should primarily validate the latest-run output.

Do not build:
- BRD documentation
- Validation Summary documentation
- dashboard artifacts
- production reporting layer
- new decision logic
- new reason-code logic
- new approved exposure calculations
- new archive insert logic

Those belong outside Section 14.

================================================================================
9. SECTION 14 OBJECTIVE
================================================================================

Section 14 should provide the full Module 2 QA and validation query framework for the latest-run strategy output.

Section 14 should answer:

“Does this completed Module 2 strategy run behave coherently, consistently, and within the documented simulation boundaries?”

Section 14 should not answer:

“Is this a production underwriting policy?”
“Is this empirically calibrated?”
“Is this a regulatory adverse-action framework?”
“Is this a fair lending conclusion?”

Section 14 is the evidence layer for Module 2 validation.

It should support:
- structural integrity review
- decision distribution review
- risk-ordering review
- affordability-sensitivity review
- reason-code coverage review
- counteroffer behavior review
- manual-review behavior review
- simulated offer-exposure review
- edge-case review
- documentation-ready validation interpretation

================================================================================
10. SECTION 14 DESIGN BOUNDARY
================================================================================

Section 14 should be read-only.

It should not:
- insert rows
- delete rows
- update rows
- modify latest-run output
- modify archive output
- recalculate decision outcomes
- recalculate reason codes
- recalculate approved exposure
- recalculate approved Expected Loss

It should only inspect and summarize completed Module 2 outputs.

================================================================================
11. SECTION 14 QA QUERY BLOCKS TO BUILD
================================================================================

Please build the following QA query blocks.

--------------------------------------------------------------------------------
14.1 Latest-run structural integrity summary
--------------------------------------------------------------------------------

Purpose:
Confirm that the latest-run strategy_decisions table exists, is populated, and has the expected row-level integrity.

Include:
- total rows
- distinct application_id count
- duplicate application_id count
- distinct strategy_set_name / strategy_name / strategy_version count
- distinct Module 1 scenario / population count
- row count by module1_input_source
- min/max latest_output_created_ts

Expected interpretation:
- total rows should equal distinct application_id count
- exactly one active strategy should be present in the latest-run output
- exactly one Module 1 source scenario / population should be present unless multi-scenario processing is explicitly designed later

--------------------------------------------------------------------------------
14.2 Final decision distribution
--------------------------------------------------------------------------------

Purpose:
Summarize final simulated strategy outcomes.

Include:
- decision_outcome
- row_count
- pct_of_population
- approval_flag count
- counteroffer_flag count
- manual_review_flag count
- decline_flag count
- simulated_offer_exposure_flag count

Expected interpretation:
- every row should have exactly one final outcome
- APPROVE + COUNTEROFFER represent simulated positive offer-exposure outcomes
- MANUAL_REVIEW remains unresolved
- DECLINE follows zero-exposure convention

--------------------------------------------------------------------------------
14.3 Decision outcome by product
--------------------------------------------------------------------------------

Purpose:
Confirm product-level strategy behavior.

Group by:
- product_type_policy_key
- decision_outcome

Include:
- row_count
- pct_within_product
- avg estimated_pd
- avg requested_payment_to_income_ratio
- avg approved_payment_to_income_ratio for offer rows
- avg requested_expected_loss_amount
- avg approved_expected_loss_amount all-app and offer-only, using explicit metric names

Interpretation:
Product-level outcomes should reflect product-specific policy parameters and structural differences.

--------------------------------------------------------------------------------
14.4 Decision outcome by score band
--------------------------------------------------------------------------------

Purpose:
Validate directional risk ordering by score band.

Group by:
- score_band_policy_key
- decision_outcome

Include:
- row_count
- pct_within_score_band
- avg estimated_pd
- avg requested_payment_to_income_ratio
- approval_rate
- counteroffer_rate
- manual_review_rate
- decline_rate
- simulated_offer_exposure_rate

Expected interpretation:
Stronger score bands should generally show higher approval / offer rates.
Weaker score bands should generally show higher manual review or decline rates.

Do not require perfect monotonicity at every micro-segment because product mix, affordability, and exposure structure can create realistic overlap.

--------------------------------------------------------------------------------
14.5 Product × score decision matrix
--------------------------------------------------------------------------------

Purpose:
Show where strategy outcomes concentrate across product and credit quality.

Group by:
- product_type_policy_key
- score_band_policy_key

Include:
- applications
- approval_rate
- counteroffer_rate
- manual_review_rate
- decline_rate
- simulated_offer_exposure_rate
- avg estimated_pd
- avg requested_payment_to_income_ratio
- avg approved_payment_to_income_ratio for offer rows
- avg requested_expected_loss_amount
- avg approved_expected_loss_amount all-app and offer-only

This should be one of the core validation outputs.

--------------------------------------------------------------------------------
14.6 Risk-tier decision validation
--------------------------------------------------------------------------------

Purpose:
Validate that the synthetic estimated-risk segmentation flows coherently into outcomes.

Group by:
- strategy_risk_tier
- decision_outcome

Include:
- row_count
- pct_within_risk_tier
- avg estimated_pd
- approval_rate
- counteroffer_rate
- manual_review_rate
- decline_rate
- simulated_offer_exposure_rate

Expected interpretation:
Higher synthetic risk tiers should generally show lower approval rates and higher review / decline rates.

Reminder:
estimated_pd is the Module 1 synthetic estimated-PD proxy, not a calibrated production PD.

--------------------------------------------------------------------------------
14.7 Requested PTI / affordability decision validation
--------------------------------------------------------------------------------

Purpose:
Validate that requested-structure affordability pressure affects strategy outcomes.

Group by:
- requested_pti_bucket
- decision_outcome

Include:
- row_count
- pct_within_requested_pti_bucket
- avg requested_payment_to_income_ratio
- avg approved_payment_to_income_ratio for offer rows
- approval_rate
- counteroffer_rate
- manual_review_rate
- decline_rate

Expected interpretation:
Higher requested PTI buckets should generally show fewer clean approvals and more counteroffer / manual review / decline outcomes.

--------------------------------------------------------------------------------
14.8 DTI capacity decision validation
--------------------------------------------------------------------------------

Purpose:
Validate that DTI capacity pressure affects strategy routing.

Group by:
- dti_bucket
- decision_outcome

Include:
- row_count
- pct_within_dti_bucket
- avg debt_to_income_ratio
- approval_rate
- counteroffer_rate
- manual_review_rate
- decline_rate

Expected interpretation:
Higher DTI should generally reduce clean approval likelihood and increase review / decline routing.

DTI remains an existing-obligation capacity signal and is not directly fixed by counteroffer in Module 2 v1.0.

--------------------------------------------------------------------------------
14.9 Requested vs approved exposure and economics by outcome
--------------------------------------------------------------------------------

Purpose:
Validate final amount and economics conventions.

Group by:
- decision_outcome

Include:
- row_count
- avg requested_amount
- avg approved_amount_all_apps using COALESCE where appropriate
- avg approved_amount_offer_rows using FILTER where simulated_offer_exposure_flag = TRUE
- total requested_amount
- total approved_amount
- avg exposure_reduction_pct for counteroffers
- total requested_expected_loss_amount
- total approved_expected_loss_amount
- avg requested_expected_loss_amount
- avg approved_expected_loss_amount_all_apps
- avg approved_expected_loss_amount_offer_rows

Expected interpretation:
- APPROVE rows should preserve requested amount and requested Expected Loss
- COUNTEROFFER rows should reduce approved amount and approved Expected Loss
- DECLINE rows should have zero approved exposure and zero approved Expected Loss
- MANUAL_REVIEW rows should remain unresolved with NULL approved exposure fields

--------------------------------------------------------------------------------
14.10 Counteroffer validation diagnostics
--------------------------------------------------------------------------------

Purpose:
Validate that counteroffer outcomes are explainable and feasible.

Include:
- count of final COUNTEROFFER rows
- count of preliminary COUNTEROFFER rows
- count of feasible counteroffers
- count of failed counteroffers
- counteroffer feasibility pass rate
- average exposure_reduction_pct for final COUNTEROFFER rows
- average approved_payment_to_income_ratio for final COUNTEROFFER rows
- average requested_payment_to_income_ratio for final COUNTEROFFER rows
- average approved_expected_loss_amount for final COUNTEROFFER rows
- count by counteroffer_feasibility_failure_reason
- product × counteroffer feasibility summary
- score band × counteroffer feasibility summary

Expected interpretation:
Counteroffer rows should show:
- approved_amount < requested_amount
- reduced PTI relative to requested PTI
- approved Expected Loss at or below relevant approved-exposure cap
- interpretable reason-code assignment

--------------------------------------------------------------------------------
14.11 Manual review validation diagnostics
--------------------------------------------------------------------------------

Purpose:
Validate unresolved manual-review population.

Include:
- count of MANUAL_REVIEW rows
- manual_review_rate
- count by decision_path
- count by primary_reason_code
- avg estimated_pd
- avg requested_payment_to_income_ratio
- avg requested_expected_loss_amount
- mixed_signal_profile_type × manual review count
- borderline_profile_flag × manual review count
- failed-counteroffer-to-manual-review count

Expected interpretation:
Manual review should concentrate in unresolved, borderline, mixed-signal, or failed-counteroffer cases.

Manual review should not have approved_amount, approved_payment_to_income_ratio, or approved_expected_loss_amount populated.

--------------------------------------------------------------------------------
14.12 Decline / policy-stop validation diagnostics
--------------------------------------------------------------------------------

Purpose:
Validate final no-offer strategy outcomes.

Include:
- count of DECLINE rows
- decline_rate
- count by decision_path
- count by primary_reason_code
- avg estimated_pd
- avg debt_to_income_ratio
- avg requested_payment_to_income_ratio
- avg requested_expected_loss_amount
- hard_policy_stop_flag × decline count
- bankruptcy_policy_stop_flag × decline count
- major_derogatory_policy_stop_flag × decline count
- severe_delinquency_policy_stop_flag × decline count

Expected interpretation:
Declines should be explainable through policy-stop, severe synthetic-risk, severe DTI, failed-counteroffer-to-decline, high requested PTI, requested Expected Loss, or exposure-limit drivers.

Reason codes are simulated strategy explanation codes, not adverse-action reasons.

--------------------------------------------------------------------------------
14.13 Reason-code coverage and alignment
--------------------------------------------------------------------------------

Purpose:
Validate reason-code completeness and family alignment.

Include:
- count of rows with null primary_reason_code
- count of rows with null primary_reason_family
- count by decision_outcome × primary_reason_family
- count by decision_outcome × primary_reason_code
- count by primary_reason_code
- avg reason_code_count by decision_outcome
- rows with reason family leakage, if any

Expected interpretation:
- APPROVE rows should use APPROVAL family
- COUNTEROFFER rows should use COUNTEROFFER family
- MANUAL_REVIEW rows should use MANUAL_REVIEW family
- DECLINE rows should use POLICY_STOP family

No reason-code language should imply regulatory adverse-action, customer notice, or fair lending conclusions.

--------------------------------------------------------------------------------
14.14 Simulated offer-exposure profile
--------------------------------------------------------------------------------

Purpose:
Summarize rows where simulated_offer_exposure_flag = TRUE.

Include:
- offer_count
- simulated_offer_exposure_rate
- approval_share_of_offers
- counteroffer_share_of_offers
- total approved_amount
- avg approved_amount
- avg estimated_pd
- avg approved_payment_to_income_ratio
- total approved_expected_loss_amount
- avg approved_expected_loss_amount
- product × simulated offer-exposure profile
- score band × simulated offer-exposure profile

Terminology:
Use simulated offer exposure, not booked exposure.

--------------------------------------------------------------------------------
14.15 Edge-case and mixed-signal review
--------------------------------------------------------------------------------

Purpose:
Validate that realistic edge cases remain visible and explainable.

Include sample queries for:
- strong-credit / high requested PTI
- weak-credit / low requested PTI
- large exposure / low synthetic risk
- high synthetic risk / low exposure
- high DTI / low requested PTI
- multiple mixed-signal profiles
- borderline profiles
- counteroffer cases with large exposure reductions
- manual review residual fallback cases
- decline residual fallback cases, if any

Recommended sample size:
Limit each sample query to 25 or 50 rows.

Expected interpretation:
Edge cases should exist but be explainable through the staged logic.

Do not treat realistic overlap as a defect unless it dominates or violates output conventions.

--------------------------------------------------------------------------------
14.16 Final output convention validation
--------------------------------------------------------------------------------

Purpose:
Confirm final output conventions hold in the latest-run table.

Include checks for:
- exactly one final outcome flag per row
- simulated_offer_exposure_flag aligns to APPROVE / COUNTEROFFER only
- APPROVE rows have approved_amount = requested_amount
- COUNTEROFFER rows have approved_amount < requested_amount
- MANUAL_REVIEW rows have approved_amount IS NULL
- DECLINE rows have approved_amount = 0
- APPROVE rows have approved_expected_loss_amount = requested_expected_loss_amount
- COUNTEROFFER rows have approved_expected_loss_amount <= requested_expected_loss_amount
- MANUAL_REVIEW rows have approved_expected_loss_amount IS NULL
- DECLINE rows have approved_expected_loss_amount = 0

This should be diagnostic and suitable for validation evidence.

--------------------------------------------------------------------------------
14.17 Archive and comparison readiness recap
--------------------------------------------------------------------------------

Purpose:
Summarize whether the latest run is archived and whether Section 13 comparison is available.

Include:
- archive_run_flag
- strategy_archive_reset_mode
- latest-run row count
- current archived slice row count
- current archived slice distinct application_id count
- comparison inventory count for same strategy_set_name / Module 1 scenario / population
- whether at least two strategy slices exist for matched comparison

This should not replace Section 13.
It should simply give Section 14 users a final readiness snapshot.

================================================================================
12. SECTION 14 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 14 comments should explain:

- why QA is separated from output creation and archive persistence
- why Section 14 is read-only
- why decision distribution is not sufficient by itself
- why product, score, PTI, DTI, risk tier, reason-code, and exposure diagnostics are all needed
- why estimated_pd remains the synthetic estimated-PD proxy
- why requested Expected Loss and approved Expected Loss are both reviewed
- why manual review remains unresolved
- why simulated offer exposure is not booked exposure
- why reason codes are simulated strategy explanation codes only
- why edge cases should be reviewed rather than automatically suppressed
- why Section 14 is validation evidence but not the final written Validation Summary

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.
No adverse-action reason-code language.

================================================================================
13. SECTION 14 DELIVERABLE
================================================================================

Please now provide:

1. Targeted Section 13 patches only:
   - same-strategy comparison readiness check
   - null-sensitive approved-exposure metric clarification
   - safe denominator handling
   - matched-population denominator handling
   - terminology cleanup from booked / approved-book to simulated offer exposure
   - reason-code movement should include reason family and reason code

2. Section 14 SQL only:
   MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS.

3. A short explanation of what Section 14 establishes.

4. A short explanation of what Section 14 intentionally does not build.

5. The recommended next step after Section 14.

Do not draft the BRD or Validation Summary yet.
<!-- END_MESSAGE C038-M00169 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_06.md) · [Next](Part_08.md)
