# Module 2 Decision Simulator Build

## Part 64

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_63.md) · [Next](Part_65.md)

<a id="c038-m01145"></a>

### C038-M01145

**ChatGPT** · 2026-05-10T12:57:39.087037-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01145 -->
According to a document from 2026-05-10, your updated file **does fix the prior hard blocker**: `avg_apr_proxy_offer_rows` now has `NUMERIC` in the persistent segment evidence table definition, and Sections **14.11–14.13** are restored before Section 14.14. The remaining formal-script hardening item is exactly the Section 16.1E schema-evolution block: the current version still only adds registry-linkage columns to older evidence tables, so an older persistent table could still be missing non-registry columns that later inserts reference. fileciteturn144file0 fileciteturn145file0

Your plan to **drop evidence tables before the campaign run** is good. That will force the current `CREATE TABLE IF NOT EXISTS` definitions to create the correct schema fresh. Still, for the canonical governed script, I recommend replacing the current 16.1E block with the expanded version below. This makes reruns safer after future edits and prevents “existing table missing column” failures. One caveat: `ADD COLUMN IF NOT EXISTS` fixes missing columns; it does **not** fix existing columns with the wrong data type. Dropping the evidence tables before the campaign run handles that concern cleanly.

## Re-evaluation after your update

I would now mark the file as:

```text
STATUS: READY FOR TARGETED 16.1E PATCH + SMOKE TEST
FULL CAMPAIGN RUN: WAIT UNTIL 16.1E PATCH IS INSERTED OR EVIDENCE TABLES ARE DROPPED CLEANLY
```

The two prior blockers are addressed:

```text
1. avg_apr_proxy_offer_rows NUMERIC is fixed.
2. Sections 14.11, 14.12, and 14.13 are restored before Section 14.14.
```

The remaining action is not a logic blocker if you drop the evidence tables first, but it is a governance-quality patch for canonical rerun safety:

```text
Replace Section 16.1E with the expanded schema-hardening block below.
```

---

# Before — current Section 16.1E block

```sql
/*-----------------------------------------------------------------------------------------------
16.1E Evidence table schema hardening for registry-linkage patch.

Business purpose:
    Add registry-linkage columns to evidence tables that may already exist from a prior version of
    Section 16.

Why this is necessary:
    CREATE TABLE IF NOT EXISTS does not modify an existing table.

    Without these ALTER TABLE statements, an older evidence table could exist without the new
    run-ID columns, causing later INSERT statements to fail.

SQL mechanics:
    Each ALTER TABLE statement is idempotent because ADD COLUMN IF NOT EXISTS only adds the column
    when the target table does not already have it.

Boundary:
    These statements add columns only when needed.

    They do not delete rows.
    They do not update rows.
    They do not alter strategy outputs.
-----------------------------------------------------------------------------------------------*/

ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS showcase_name TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS showcase_name TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS showcase_name TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;
```

---

# After — replacement Section 16.1E block

```sql
/*-----------------------------------------------------------------------------------------------
16.1E Evidence table schema hardening for full evidence-table rerun safety.

Business purpose:
    Add any missing evidence-table columns to persistent evidence tables that may already exist from
    a prior version of Section 16.

Why this is necessary:
    CREATE TABLE IF NOT EXISTS creates a table only when it does not already exist.

    It does not upgrade an older persistent table.

    If a prior development version created one of the evidence tables with a narrower schema, later
    Section 16 INSERT statements can fail because the table exists but lacks one or more current
    evidence columns.

Formal governed-script position:
    The evidence tables should persist across the campaign.

    They should not be dropped during ordinary reruns.

    Therefore this block hardens all four persistent evidence tables against missing-column drift.

Important limitation:
    ADD COLUMN IF NOT EXISTS handles missing columns.

    It does not correct existing columns with the wrong data type.

    If an evidence table exists with incorrect column types, use a one-time evidence-table rebuild or
    an explicit ALTER COLUMN TYPE migration.

Operational note:
    Explicit INSERT column lists are used later in Section 16.

    Therefore column order in an older table does not need to match the CREATE TABLE definition
    exactly after columns are added.

SQL mechanics:
    Each ALTER TABLE statement is idempotent.

    Existing columns are left untouched.

    Missing columns are added.

Boundary:
    These statements do not delete rows.
    These statements do not update rows.
    These statements do not modify latest-run output.
    These statements do not modify archive output.
    These statements do not modify campaign registry rows.
    These statements do not recalculate strategy outputs.
-----------------------------------------------------------------------------------------------*/

ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS evidence_snapshot_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS evidence_snapshot_id TEXT,
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT,
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT,
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT,
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT,
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER,
    ADD COLUMN IF NOT EXISTS showcase_id TEXT,
    ADD COLUMN IF NOT EXISTS showcase_name TEXT,
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT,
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT,
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT,
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER,
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT,
    ADD COLUMN IF NOT EXISTS module1_parameter_family_changed TEXT,
    ADD COLUMN IF NOT EXISTS module1_parameter_change_summary TEXT,
    ADD COLUMN IF NOT EXISTS module2_strategy_family_changed TEXT,
    ADD COLUMN IF NOT EXISTS module2_parameter_change_summary TEXT,
    ADD COLUMN IF NOT EXISTS expected_storyline TEXT,
    ADD COLUMN IF NOT EXISTS observed_storyline TEXT,
    ADD COLUMN IF NOT EXISTS validation_notes TEXT,
    ADD COLUMN IF NOT EXISTS module2_model_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_set_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_id TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS latest_output_created_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS archive_inserted_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS archive_run_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS strategy_archive_reset_mode TEXT,
    ADD COLUMN IF NOT EXISTS failed_counteroffer_resolution TEXT,
    ADD COLUMN IF NOT EXISTS module1_input_source TEXT,
    ADD COLUMN IF NOT EXISTS module1_source_table_name TEXT,
    ADD COLUMN IF NOT EXISTS module1_model_version TEXT,
    ADD COLUMN IF NOT EXISTS module1_scenario_set_name TEXT,
    ADD COLUMN IF NOT EXISTS module1_scenario_name TEXT,
    ADD COLUMN IF NOT EXISTS population_id TEXT,
    ADD COLUMN IF NOT EXISTS anchor_date DATE,
    ADD COLUMN IF NOT EXISTS applications BIGINT,
    ADD COLUMN IF NOT EXISTS distinct_application_id_count BIGINT,
    ADD COLUMN IF NOT EXISTS duplicate_application_count BIGINT,
    ADD COLUMN IF NOT EXISTS approval_count BIGINT,
    ADD COLUMN IF NOT EXISTS counteroffer_count BIGINT,
    ADD COLUMN IF NOT EXISTS manual_review_count BIGINT,
    ADD COLUMN IF NOT EXISTS decline_count BIGINT,
    ADD COLUMN IF NOT EXISTS offer_count BIGINT,
    ADD COLUMN IF NOT EXISTS approval_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS manual_review_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS decline_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS simulated_offer_exposure_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS approval_share_of_offers NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_share_of_offers NUMERIC,
    ADD COLUMN IF NOT EXISTS total_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS total_approved_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_capture_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_amount_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_amount_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS total_exposure_reduction_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_approved_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_exposure_reduction_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_exposure_reduction_pct_avg NUMERIC,
    ADD COLUMN IF NOT EXISTS manual_review_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS manual_review_requested_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS decline_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS decline_requested_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_requested_payment_to_income_ratio NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_payment_to_income_ratio_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_apr_proxy_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_apr_proxy_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS requested_amount_weighted_apr_proxy NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_weighted_apr_proxy NUMERIC,
    ADD COLUMN IF NOT EXISTS requested_amount_x_apr_proxy_sum NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_x_apr_proxy_sum NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_loan_term_months_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_weighted_term_months NUMERIC,
    ADD COLUMN IF NOT EXISTS term_missing_or_revolving_count BIGINT,
    ADD COLUMN IF NOT EXISTS secured_approved_amount_share NUMERIC,
    ADD COLUMN IF NOT EXISTS unsecured_approved_amount_share NUMERIC,
    ADD COLUMN IF NOT EXISTS revolving_approved_amount_share NUMERIC,
    ADD COLUMN IF NOT EXISTS installment_approved_amount_share NUMERIC,
    ADD COLUMN IF NOT EXISTS mortgage_approved_amount_share NUMERIC,
    ADD COLUMN IF NOT EXISTS product_approved_amount_mix_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS product_approved_expected_loss_mix_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS product_offer_rate_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS avg_synthetic_estimated_pd_proxy_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_synthetic_estimated_pd_proxy_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_synthetic_estimated_pd_proxy_declined_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_estimated_lgd_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_estimated_lgd_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS total_requested_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS total_approved_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_requested_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_expected_loss_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_expected_loss_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS requested_expected_loss_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_expected_loss_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_per_approved_expected_loss_dollar NUMERIC,
    ADD COLUMN IF NOT EXISTS top_primary_reason_family TEXT,
    ADD COLUMN IF NOT EXISTS top_primary_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_primary_reason_population_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_non_approval_primary_reason_family TEXT,
    ADD COLUMN IF NOT EXISTS top_non_approval_primary_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_non_approval_reason_population_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_policy_stop_primary_reason_family TEXT,
    ADD COLUMN IF NOT EXISTS top_policy_stop_primary_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_policy_stop_reason_population_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_reason_code_delta_driver_family TEXT,
    ADD COLUMN IF NOT EXISTS top_reason_code_delta_driver_code TEXT,
    ADD COLUMN IF NOT EXISTS top_reason_code_delta_driver_baseline_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_reason_code_delta_driver_strategy_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_reason_code_delta_population_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_counteroffer_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_manual_review_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_decline_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS frontier_position_type TEXT,
    ADD COLUMN IF NOT EXISTS executive_frontier_quadrant TEXT,
    ADD COLUMN IF NOT EXISTS frontier_interpretation_note TEXT,
    ADD COLUMN IF NOT EXISTS validation_pass_count BIGINT,
    ADD COLUMN IF NOT EXISTS validation_review_count BIGINT,
    ADD COLUMN IF NOT EXISTS validation_not_applicable_count BIGINT,
    ADD COLUMN IF NOT EXISTS validation_review_items TEXT,
    ADD COLUMN IF NOT EXISTS validation_status_summary_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS top_approved_amount_product TEXT,
    ADD COLUMN IF NOT EXISTS top_approved_amount_product_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_approved_expected_loss_product TEXT,
    ADD COLUMN IF NOT EXISTS top_approved_expected_loss_product_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_counteroffer_product TEXT,
    ADD COLUMN IF NOT EXISTS top_decline_product TEXT,
    ADD COLUMN IF NOT EXISTS highest_offer_rate_product TEXT,
    ADD COLUMN IF NOT EXISTS lowest_offer_rate_product TEXT,
    ADD COLUMN IF NOT EXISTS top_approved_amount_score_band TEXT,
    ADD COLUMN IF NOT EXISTS top_approved_expected_loss_score_band TEXT,
    ADD COLUMN IF NOT EXISTS top_counteroffer_score_band TEXT,
    ADD COLUMN IF NOT EXISTS top_decline_score_band TEXT,
    ADD COLUMN IF NOT EXISTS highest_offer_rate_score_band TEXT,
    ADD COLUMN IF NOT EXISTS lowest_offer_rate_score_band TEXT,
    ADD COLUMN IF NOT EXISTS highest_approved_el_rate_score_band TEXT,
    ADD COLUMN IF NOT EXISTS top_approved_amount_product_score_segment TEXT,
    ADD COLUMN IF NOT EXISTS top_approved_el_product_score_segment TEXT,
    ADD COLUMN IF NOT EXISTS top_counteroffer_product_score_segment TEXT,
    ADD COLUMN IF NOT EXISTS top_decline_product_score_segment TEXT,
    ADD COLUMN IF NOT EXISTS highest_approved_el_rate_product_score_segment TEXT,
    ADD COLUMN IF NOT EXISTS largest_delta_approved_amount_product TEXT,
    ADD COLUMN IF NOT EXISTS largest_delta_approved_el_product TEXT,
    ADD COLUMN IF NOT EXISTS largest_delta_offer_rate_score_band TEXT,
    ADD COLUMN IF NOT EXISTS largest_delta_decline_rate_score_band TEXT,
    ADD COLUMN IF NOT EXISTS largest_delta_approved_el_product_score_segment TEXT,
    ADD COLUMN IF NOT EXISTS module3_growth_inputs_available_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS module3_growth_input_gap_note TEXT,
    ADD COLUMN IF NOT EXISTS module3_revenue_model_required_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS module3_boundary_note TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS evidence_snapshot_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT,
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT,
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT,
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT,
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER,
    ADD COLUMN IF NOT EXISTS showcase_id TEXT,
    ADD COLUMN IF NOT EXISTS showcase_name TEXT,
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT,
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT,
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT,
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER,
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT,
    ADD COLUMN IF NOT EXISTS module2_model_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_set_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_id TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS module1_scenario_set_name TEXT,
    ADD COLUMN IF NOT EXISTS module1_scenario_name TEXT,
    ADD COLUMN IF NOT EXISTS population_id TEXT,
    ADD COLUMN IF NOT EXISTS validation_area TEXT,
    ADD COLUMN IF NOT EXISTS validation_test_name TEXT,
    ADD COLUMN IF NOT EXISTS validation_category TEXT,
    ADD COLUMN IF NOT EXISTS validation_status TEXT,
    ADD COLUMN IF NOT EXISTS observed_value TEXT,
    ADD COLUMN IF NOT EXISTS expected_behavior TEXT,
    ADD COLUMN IF NOT EXISTS interpretation TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS evidence_snapshot_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS evidence_snapshot_id TEXT,
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT,
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT,
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT,
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT,
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER,
    ADD COLUMN IF NOT EXISTS showcase_id TEXT,
    ADD COLUMN IF NOT EXISTS showcase_name TEXT,
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT,
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT,
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT,
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER,
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT,
    ADD COLUMN IF NOT EXISTS module2_model_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_set_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_id TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS module1_scenario_set_name TEXT,
    ADD COLUMN IF NOT EXISTS module1_scenario_name TEXT,
    ADD COLUMN IF NOT EXISTS population_id TEXT,
    ADD COLUMN IF NOT EXISTS strategy_params_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS product_policy_params_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS run_story_params_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS parameter_snapshot_hash TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS evidence_snapshot_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN,
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT,
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT,
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT,
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT,
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER,
    ADD COLUMN IF NOT EXISTS showcase_id TEXT,
    ADD COLUMN IF NOT EXISTS showcase_name TEXT,
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT,
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT,
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT,
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER,
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT,
    ADD COLUMN IF NOT EXISTS module2_model_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_set_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_name TEXT,
    ADD COLUMN IF NOT EXISTS strategy_version TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_id TEXT,
    ADD COLUMN IF NOT EXISTS strategy_run_ts TIMESTAMP,
    ADD COLUMN IF NOT EXISTS module1_scenario_set_name TEXT,
    ADD COLUMN IF NOT EXISTS module1_scenario_name TEXT,
    ADD COLUMN IF NOT EXISTS population_id TEXT,
    ADD COLUMN IF NOT EXISTS product_type_policy_key TEXT,
    ADD COLUMN IF NOT EXISTS score_band_policy_key TEXT,
    ADD COLUMN IF NOT EXISTS product_score_policy_segment TEXT,
    ADD COLUMN IF NOT EXISTS applications BIGINT,
    ADD COLUMN IF NOT EXISTS approval_count BIGINT,
    ADD COLUMN IF NOT EXISTS counteroffer_count BIGINT,
    ADD COLUMN IF NOT EXISTS manual_review_count BIGINT,
    ADD COLUMN IF NOT EXISTS decline_count BIGINT,
    ADD COLUMN IF NOT EXISTS offer_count BIGINT,
    ADD COLUMN IF NOT EXISTS approval_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS counteroffer_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS manual_review_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS decline_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS simulated_offer_exposure_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS total_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS total_approved_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_capture_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_requested_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_amount_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_amount_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_apr_proxy_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_apr_proxy_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS requested_amount_weighted_apr_proxy NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_weighted_apr_proxy NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_loan_term_months_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_amount_weighted_term_months NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_synthetic_estimated_pd_proxy_all_apps NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_synthetic_estimated_pd_proxy_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_estimated_lgd_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS total_requested_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS total_approved_expected_loss_amount NUMERIC,
    ADD COLUMN IF NOT EXISTS approved_expected_loss_rate NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_requested_payment_to_income_ratio NUMERIC,
    ADD COLUMN IF NOT EXISTS avg_approved_payment_to_income_ratio_offer_rows NUMERIC,
    ADD COLUMN IF NOT EXISTS top_primary_reason_family TEXT,
    ADD COLUMN IF NOT EXISTS top_primary_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_primary_reason_population_share NUMERIC,
    ADD COLUMN IF NOT EXISTS top_non_approval_primary_reason_family TEXT,
    ADD COLUMN IF NOT EXISTS top_non_approval_primary_reason_code TEXT,
    ADD COLUMN IF NOT EXISTS top_non_approval_reason_population_share NUMERIC;
```

---

## Section 15 baseline join: why I flagged it, and what I recommend

The current Section 15 baseline-relative frontier design defines baseline availability where `BASELINE_STRATEGY` exists for the same `strategy_set_name`, `module1_scenario_set_name`, `module1_scenario_name`, and `population_id`. That is adequate for the current **V1_0-only** strategy campaign because the archive should only contain one baseline strategy version per comparable frontier group. fileciteturn144file16

The future issue is this: the archive grain and replacement key explicitly include `strategy_version`, which means the archive is designed to retain strategy-version-specific slices. fileciteturn144file10 If later you archive both:

```text
BASELINE_STRATEGY / V1_0
BASELINE_STRATEGY / V1_1
TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_1
```

then a Section 15 baseline join that does **not** include `strategy_version` can accidentally match a challenger to more than one baseline, or to the wrong baseline version. That can create duplicate frontier rows or incorrect baseline-relative deltas.

My recommended approach is:

```text
Current V1_0 campaign:
    No immediate blocker. Existing Section 15 baseline logic is acceptable if all campaign runs use V1_0.

Future-proof canonical script:
    Make Section 15 baseline matching version-explicit by adding strategy_version to:
        baseline_groups,
        frontier_group_reason_universe,
        baseline_reason_population_shares,
        top_reason_code_delta_driver joins,
        and final baseline_reference join.
```

The simplest future-safe policy is:

```text
A strategy frontier point should compare to BASELINE_STRATEGY with the same:
    strategy_set_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
```

That is clean, deterministic, and consistent with the archive grain.

A more flexible alternative would be a registry-driven baseline-version map, where a challenger can explicitly compare to a different baseline version. I would **not** add that complexity yet. For this project, same-version matching is the right first governed design.

The exact Section 15.3 concept patch would be:

```sql
/* Add strategy_version to comparable baseline group. */
baseline_groups AS (
    SELECT DISTINCT
        strategy_set_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    FROM baseline_reference
),

/* Add strategy_version to reason-code universe. */
frontier_group_reason_universe AS (
    SELECT DISTINCT
        strategy_set_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code
    FROM reason_population_shares
),

/* Add strategy_version to baseline reason shares. */
baseline_reason_population_shares AS (
    SELECT
        strategy_set_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        primary_reason_family,
        primary_reason_code,
        reason_population_share AS baseline_reason_population_share
    FROM reason_population_shares
    WHERE strategy_name = 'BASELINE_STRATEGY'
),

/* In top_reason_code_delta_driver, join baseline_groups by strategy_version too. */
JOIN baseline_groups bg
    ON bg.strategy_set_name = s.strategy_set_name
   AND bg.strategy_version = s.strategy_version
   AND bg.module1_scenario_set_name = s.module1_scenario_set_name
   AND bg.module1_scenario_name = s.module1_scenario_name
   AND bg.population_id = s.population_id

/* Join reason-code universe by strategy_version too. */
JOIN frontier_group_reason_universe u
    ON u.strategy_set_name = s.strategy_set_name
   AND u.strategy_version = s.strategy_version
   AND u.module1_scenario_set_name = s.module1_scenario_set_name
   AND u.module1_scenario_name = s.module1_scenario_name
   AND u.population_id = s.population_id

/* Join baseline reason shares by strategy_version too. */
LEFT JOIN baseline_reason_population_shares br
    ON br.strategy_set_name = s.strategy_set_name
   AND br.strategy_version = s.strategy_version
   AND br.module1_scenario_set_name = s.module1_scenario_set_name
   AND br.module1_scenario_name = s.module1_scenario_name
   AND br.population_id = s.population_id
   AND br.primary_reason_family = u.primary_reason_family
   AND br.primary_reason_code = u.primary_reason_code

/* In the final baseline_reference join, add strategy_version. */
LEFT JOIN baseline_reference b
    ON b.strategy_set_name = s.strategy_set_name
   AND b.strategy_version = s.strategy_version
   AND b.module1_scenario_set_name = s.module1_scenario_set_name
   AND b.module1_scenario_name = s.module1_scenario_name
   AND b.population_id = s.population_id
```

I would treat that Section 15 patch as **future-proofing**, not a campaign blocker for the current V1_0 run. The 16.1E schema-hardening patch is the one I would insert now.
<!-- END_MESSAGE C038-M01145 -->


---

<a id="c038-m01147"></a>

### C038-M01147

**Andrew** · 2026-05-10T13:02:59.529000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01147 -->
I updated 16.1E block. Now let's talk about next steps and remind me of our campaign run tables (module 1 parameter tables and module 2 parameter tables).
<!-- END_MESSAGE C038-M01147 -->


---

<a id="c038-m01152"></a>

### C038-M01152

**ChatGPT** · 2026-05-10T13:06:51.751000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01152 -->
According to a document from 2026-05-10, the updated Module 2 flow is now set up so Section 16 consumes the Section 3 campaign-registry match, Section 14 validation summary, Section 15 frontier summary, and the active Module 2 strategy / product-policy parameter cards before writing persistent evidence tables. That means the next phase should shift from code hardening to controlled campaign execution and evidence review. fileciteturn147file13

## Current status

With the expanded **16.1E** block in place, I would treat the canonical Module 2 file as **campaign-prep ready**, subject to one clean smoke test.

Your plan to drop the Section 16 evidence tables before the formal campaign is still good. The expanded `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` block protects reruns and future schema drift, while the one-time drop gives us a clean campaign evidence base.

I would drop only the evidence tables, not the archive or registry tables, unless you intentionally want to restart the entire campaign history:

```sql
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_evidence_summary;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_validation_evidence;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_parameter_snapshot;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_segment_evidence_summary;
```

Do **not** drop these ordinary campaign-control tables unless you are intentionally rebuilding the campaign roadmap:

```sql
credit_decisioning_sim.strategy_run_campaign_registry
credit_decisioning_sim.strategy_comparison_campaign_registry
```

And do **not** drop the Module 2 archive unless you want to lose completed strategy slices:

```sql
credit_decisioning_sim.strategy_decisions_archive
```

Section 1 is intentionally designed to preserve the archive, campaign registry, and evidence history tables during normal reruns, while dropping only transient execution objects and the replaceable latest-run output. fileciteturn147file14

## Recommended next steps

First, do one **clean smoke test** before the formal campaign. Use the current baseline combination:

```text
Module 1:
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

Module 2:
MODULE2_BASELINE_STRATEGY_SET / BASELINE_STRATEGY / V1_0
```

That run should prove the final canonical file can execute from Section 1 through Section 16 with the new 16.1E block, restored Sections 14.11–14.13, registry matching, archive persistence, frontier output, validation summary, and evidence capture.

Second, run the **tighter synthetic-risk strategy** against the same archived Module 1 population:

```text
Module 1:
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

Module 2:
MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0
```

That gives you the first clean baseline-versus-challenger pair. Section 13 should then be able to compare the archived baseline and challenger slices under the same Module 1 scenario and population, and Section 15 should classify both frontier points.

Third, after the challenger run, review Section 16.8 carefully. That should be the “post-run evidence packet” after every campaign run: row counts, executive evidence summary, validation REVIEW / NOT_APPLICABLE rows, product × score segment evidence, parameter snapshot hash, and registry linkage diagnostics. Section 16 is explicitly designed to persist executive evidence, validation evidence, parameter snapshots, and product × score evidence for later Validation Summary, README, LinkedIn, and Module 3 planning. fileciteturn147file13

Fourth, once the baseline/challenger pair is clean, continue the broader campaign matrix. At that point, the work becomes repetitive and controlled: update the active Module 1 or Module 2 parameter row, confirm registry mapping, run, archive, validate, capture evidence, review Section 16.8, then move to the next run.

## Campaign run tables — Module 1

For **Module 1**, the primary parameter table is:

```text
tmp_module1_params
```

This is the single-row temporary configuration object for the Module 1 run. It carries scenario identity, generation assumptions, archive behavior, product mix, score mix, APR anchors, LGD assumptions, and other governed Module 1 simulation controls. The Module 1 code describes it as a temporary table used as a single-row configuration object, with `scenario_set_name` serving as the comparison family / project grouping and `scenario_name` identifying the individual run inside that family. fileciteturn149file2

The key Module 1 run identity fields to check before each run are:

```text
scenario_set_name
scenario_name
population_id
```

For our current baseline run:

```text
scenario_set_name = MODULE1_V2_BASELINE_SET
scenario_name     = BASELINE_V2
population_id     = BASE_POPULATION_V1
```

The primary Module 1 output tables are:

```text
credit_decisioning_sim.synthetic_applications
credit_decisioning_sim.synthetic_applications_scenario_archive
```

`synthetic_applications` is the latest-run Module 1 output. `synthetic_applications_scenario_archive` is the persistent scenario archive used for controlled downstream Module 2 runs. Module 1 inserts the latest run into the scenario archive when `archive_run_flag = TRUE`, and the archive is indexed by scenario set, scenario name, population, application, product, and score fields for comparison and downstream use. fileciteturn148file0

## Campaign run tables — Module 2

For **Module 2**, the two main temporary parameter tables are:

```text
tmp_module2_strategy_params
tmp_module2_product_policy_params
```

`tmp_module2_strategy_params` is the active strategy card. It contains the Module 2 strategy identity, Module 1 source selection, archive controls, registry requirement flag, synthetic estimated-risk thresholds, PTI thresholds, DTI thresholds, rule controls, decision conventions, and failed-counteroffer resolution. `tmp_module2_product_policy_params` is the product-policy card, with one row per supported product and product-specific PTI, requested Expected Loss, approved Expected Loss cap, exposure, counteroffer, manual-review, and rounding controls. Section 5 explicitly depends on both objects before strategy segmentation can proceed. fileciteturn147file0

The key Module 2 strategy identity fields are:

```text
strategy_set_name
strategy_name
strategy_version
strategy_run_id
strategy_run_ts
```

The Module 1 source-selection fields inside `tmp_module2_strategy_params` are:

```text
module1_input_source
source_module1_scenario_set_name
source_module1_scenario_name
source_population_id
```

For formal campaign runs, we should use:

```text
module1_input_source = ARCHIVE
```

That makes Module 2 consume the selected Module 1 archived scenario slice rather than whatever happens to be in the latest-run Module 1 table. Section 4 supports both latest-run and archive inputs, but it documents archive input as the controlled source for a selected Module 1 scenario archive slice. fileciteturn147file4

The persistent Module 2 campaign registry tables are:

```text
credit_decisioning_sim.strategy_run_campaign_registry
credit_decisioning_sim.strategy_comparison_campaign_registry
```

`strategy_run_campaign_registry` maps technical run keys to documentation IDs such as:

```text
module1_run_id
module2_run_id
run_sequence_number
showcase_id
showcase_name
comparison_group_id
validation_evidence_group_id
readme_storyline_label
linkedin_post_sequence
validation_summary_section_hint
```

Those IDs are evidence-linkage metadata. They do not replace the technical SQL key. Section 16 uses them to connect SQL output to archive slices, comparison results, evidence rows, and future Validation Summary claims. fileciteturn147file13

`strategy_comparison_campaign_registry` controls the active baseline-versus-challenger comparison by `comparison_group_id`. Section 13 is designed to use a governed comparison selector rather than inferring comparisons from the latest-run table, because the latest-run table changes every time a new strategy is executed. fileciteturn146file18

The primary Module 2 output tables are:

```text
credit_decisioning_sim.strategy_decisions
credit_decisioning_sim.strategy_decisions_archive
```

`strategy_decisions` is the replaceable latest-run output. `strategy_decisions_archive` is the governed historical layer used for comparison, frontier analysis, validation evidence review, and documentation traceability. fileciteturn146file51

The persistent Module 2 evidence tables are:

```text
credit_decisioning_sim.strategy_run_evidence_summary
credit_decisioning_sim.strategy_run_validation_evidence
credit_decisioning_sim.strategy_run_parameter_snapshot
credit_decisioning_sim.strategy_run_segment_evidence_summary
```

These are the tables we should drop once before the formal campaign if we want a clean evidence base. Section 16 then recreates or reuses them, deletes prior evidence only for the current run key, and captures validation evidence, parameter snapshots, segment evidence, and executive evidence for each completed run. fileciteturn147file13

## Practical run checklist

For each **Module 1** run:

```text
1. Update tmp_module1_params.
2. Confirm scenario_set_name / scenario_name / population_id.
3. Confirm archive_run_flag = TRUE for campaign runs.
4. Run Module 1.
5. Confirm credit_decisioning_sim.synthetic_applications is populated.
6. Confirm credit_decisioning_sim.synthetic_applications_scenario_archive has the expected scenario slice.
7. Review Module 1 QA outputs before using the scenario in Module 2.
```

For each **Module 2** run:

```text
1. Update tmp_module2_strategy_params.
2. Confirm tmp_module2_product_policy_params.
3. Confirm source_module1_scenario_set_name / source_module1_scenario_name / source_population_id.
4. Confirm the run exists in strategy_run_campaign_registry.
5. Confirm the intended comparison exists in strategy_comparison_campaign_registry.
6. Run Sections 1–12 to create latest-run output and archive it.
7. Run Section 13 once a baseline/challenger pair exists.
8. Run Section 14 validation QA.
9. Run Section 15 frontier summary.
10. Run Section 16 evidence capture.
11. Review Section 16.8 before moving to the next run.
```

The next move I recommend is: **run the Module 2 baseline strategy once on the Module 1 baseline archive, then run the tighter synthetic-risk strategy, then review Section 13 / 14 / 15 / 16 outputs as the first formal campaign pair.**
<!-- END_MESSAGE C038-M01152 -->


---

<a id="c038-m01153"></a>

### C038-M01153

**Andrew** · 2026-05-10T13:14:57.375000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01153 -->
full code ran just fine.
<!-- END_MESSAGE C038-M01153 -->


---

<a id="c038-m01156"></a>

### C038-M01156

**ChatGPT** · 2026-05-10T13:16:50.154800-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01156 -->
Excellent. That is the point where I would **stop code hardening and freeze the canonical Module 2 SQL**, except for parameter-table edits needed to run each campaign scenario / strategy.

A clean full execution is meaningful because the file is now exercising the full path:

```text
Module 1 source selection
→ strategy segmentation
→ rule flags
→ preliminary routing
→ exposure treatment
→ final decision resolution
→ reason-code assignment
→ latest-run output
→ archive persistence
→ comparison diagnostics
→ validation QA
→ frontier summary
→ persistent evidence capture
```

The code structure supports that interpretation: Section 11 materializes the latest-run strategy output, Section 12 persists the governed archive, Section 13 handles matched archive comparison, Section 14 validates the completed latest-run output, Section 15 summarizes archive-backed frontier tradeoffs, and Section 16 persists executive evidence, validation evidence, parameter snapshots, and product × score evidence. fileciteturn149file20 fileciteturn149file19 fileciteturn149file18 fileciteturn149file17 fileciteturn149file10 fileciteturn149file8

## What this means

If the full code ran through Section 16 without exceptions, then the big runtime risks we were worried about are resolved:

```text
1. The restored Section 14.11–14.13 blocks are syntactically valid.
2. The Section 16.1 evidence-table schema is compatible with the later inserts.
3. The archive persistence layer executed.
4. The validation summary object was available for Section 16.
5. The frontier summary object was available for Section 16.
6. Evidence capture inserted successfully.
7. Section 16.7 local evidence gatekeepers did not find a blocking evidence issue.
```

Section 16.7 is designed to either complete successfully or raise a clear exception when executive evidence, validation evidence, parameter snapshot evidence, segment evidence, or registry-linkage evidence is incomplete. So a clean pass is a strong local acceptance signal for the evidence-capture layer. fileciteturn149file2

## Immediate next step: freeze the code

I would now create a clean internal checkpoint:

```text
Module 2 V1.0 canonical SQL — campaign-run candidate
Status: runtime smoke test passed
Code hardening: frozen
Allowed edits going forward: parameter tables and campaign registry active rows only
```

At this point, avoid further broad commentary edits. The file has already proven it runs, and the bigger project risk now shifts from code syntax to **campaign operation discipline**.

## Before the formal campaign

Since you plan to drop evidence tables before formal campaign runs, do that once immediately before starting the official sequence:

```sql
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_evidence_summary;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_validation_evidence;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_parameter_snapshot;
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_run_segment_evidence_summary;
```

Do **not** drop these unless you intentionally want to restart history or roadmap metadata:

```text
credit_decisioning_sim.strategy_decisions_archive
credit_decisioning_sim.strategy_run_campaign_registry
credit_decisioning_sim.strategy_comparison_campaign_registry
```

Section 1 is designed to preserve archive, registry, and evidence history under ordinary rerun behavior, while Section 12 governs archive persistence and Section 16 governs evidence replacement at the current run key. fileciteturn149file30 fileciteturn149file19 fileciteturn149file8

## First formal run pair

I would start with the baseline pair we have been anchoring around:

```text
Run 1:
Module 1 scenario:
    MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

Module 2 strategy:
    MODULE2_BASELINE_STRATEGY_SET / BASELINE_STRATEGY / V1_0
```

Then:

```text
Run 2:
Module 1 scenario:
    MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

Module 2 strategy:
    MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0
```

That gives the first clean baseline-versus-challenger pair. Section 13 should then show a governed matched comparison, Section 15 should show a small frontier, and Section 16 should capture persistent run evidence for both rows. Section 13’s purpose is exactly to compare archived Module 2 strategy runs applied to the same Module 1 scenario and population. fileciteturn149file18

## After every Module 2 campaign run

Use Section 16.8 as the post-run evidence review packet. It is designed to show evidence row counts, the executive evidence row, REVIEW / NOT_APPLICABLE validation evidence, product × score evidence, parameter snapshot hash, and registry-linkage consistency. fileciteturn149file1

The review rhythm should be:

```text
1. Confirm Section 16.8A evidence row counts.
2. Review Section 16.8B executive evidence summary.
3. Review Section 16.8C validation REVIEW / NOT_APPLICABLE rows.
4. Review Section 16.8D product × score segment evidence.
5. Review Section 16.8E parameter snapshot hash.
6. Review Section 16.8F registry-linkage consistency.
```

For campaign tracking, after each run I would record:

```text
module1_run_id
module2_run_id
run_sequence_number
showcase_id
comparison_group_id
validation_evidence_group_id
run_registry_match_status
strategy_name
strategy_version
module1_scenario_name
population_id
validation_pass_count
validation_review_count
validation_not_applicable_count
frontier_position_type
executive_frontier_quadrant
parameter_snapshot_hash
```

## Campaign operating rule

From here forward, the safest rule is:

```text
Do not edit downstream logic during the campaign.
Only change:
    tmp_module2_strategy_params
    tmp_module2_product_policy_params, if needed
    active campaign registry rows
    active comparison registry rows
```

That keeps the campaign evidence clean. If the logic changes mid-campaign, earlier and later runs are no longer strictly comparable without versioning the code itself.

My recommendation: **freeze the code, drop only the Section 16 evidence tables if you want a clean evidence base, then begin the baseline + tighter synthetic-risk formal pair.**
<!-- END_MESSAGE C038-M01156 -->


---

<a id="c038-m01157"></a>

### C038-M01157

**Andrew** · 2026-05-10T13:18:20.032000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01157 -->
we had nice parameter charts with that showed what the values should be for all parameters for each module 1 and module 2 campaign run.  can you re-provide those and enhance if needed?
<!-- END_MESSAGE C038-M01157 -->


---

<a id="c038-m01176"></a>

### C038-M01176

**ChatGPT** · 2026-05-10T13:29:11.566399-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01176 -->
According to a document from 2026-05-10, the current Module 2 SQL uses Section 2 as the governed parameter/control layer: `tmp_module2_strategy_params` is the one-row active strategy card, `tmp_module2_product_policy_params` is the product-policy card, and the campaign registries map technical Module 1 / Module 2 keys to run IDs, comparison groups, and validation evidence IDs. Section 3 then gatekeeps that setup before any downstream strategy logic runs. fileciteturn150file5

Below is the enhanced runbook-style version of the parameter charts. The rows are meant to tell you **what to set before each campaign run**. Since both modules are parameter-card driven, the operating rule is:

```text
Module 1:
    Edit tmp_module1_params for the selected M1 run.
    Run Module 1.
    Archive the completed scenario slice.

Module 2:
    Edit tmp_module2_strategy_params for the selected M2 run.
    Confirm tmp_module2_product_policy_params profile.
    Confirm registry row exists.
    Run full Module 2.
    Review Section 16.8 evidence outputs.
```

---

# 1. Module 1 — baseline constants to preserve unless the scenario says otherwise

The Module 1 baseline is a 50,000-row synthetic population using `BASE_POPULATION_V1`, with a 2025 application window and an anchor date of `2025-12-31`. The Module 1 BRD also defines the baseline product mix, score-band mix, product amount bounds, term structures, APR anchors, and LGD assumptions. fileciteturn151file15 fileciteturn151file16 fileciteturn151file1

| Parameter family | Parameter | Baseline value | Keep constant unless… |
|---|---:|---:|---|
| Run size | `application_count` | `50000` | Always keep fixed for campaign comparability |
| Population | `population_id` | `BASE_POPULATION_V1` | Always keep fixed when doing matched scenario / strategy comparison |
| Application window | `portfolio_start_date` | `2025-01-01` | Keep fixed unless creating a time-window scenario |
| Application window | `portfolio_end_date` | `2025-12-31` | Keep fixed unless creating a time-window scenario |
| Reporting date | `anchor_date` | `2025-12-31` | Keep fixed for current campaign |
| Archive | `archive_run_flag` | `TRUE` | Keep true for formal campaign runs |
| Archive | `archive_reset_mode` | `SCENARIO_ONLY` | Recommended rerun mode |
| Rate environment | `rate_shift_bps` | `0` | Change only for rate-up / rate-down scenarios |
| Product mix | Mortgage / Revolving / Auto / Personal / HELOC | `30% / 25% / 20% / 15% / 10%` | Change only for product-mix scenarios |
| Score mix | Super Prime / Prime / Near Prime / Subprime / Deep Subprime | `18% / 28% / 24% / 18% / 12%` | Change only for credit-box scenarios |
| Base APR | Mortgage / Auto / Personal / Revolving / HELOC | `6.00% / 6.50% / 11.00% / 20.00% / 8.00%` | Usually keep fixed; rate scenarios should use `rate_shift_bps` |
| LGD | Mortgage / Auto / Personal / Revolving / HELOC | `20% / 45% / 70% / 85% / 25%` | Change only for LGD severity scenarios |

---

# 2. Module 1 — campaign scenario parameter chart

Use this as the run-order and parameter-edit chart for `tmp_module1_params`.

| M1 run | Showcase | `scenario_set_name` | `scenario_name` | Primary parameter family | Main parameter edit | Feeds Module 2 runs |
|---:|---|---|---|---|---|---|
| M1-01 | SC01 Baseline Strategy Frontier | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | Baseline | Baseline product mix, score mix, rate, exposure, LGD | M2-01 to M2-07 |
| M1-02 | SC02 Rate Environment Sensitivity | `MODULE1_V2_BASELINE_SET` | `RATE_UP_200BP` | Rate environment | `rate_shift_bps = +200` | M2-08, M2-11 |
| M1-03 | SC02 Rate Environment Sensitivity | `MODULE1_V2_BASELINE_SET` | `RATE_DOWN_200BP` | Rate environment | `rate_shift_bps = -200` | M2-09, M2-13 |
| M1-04 | SC02 Rate Environment Sensitivity | `MODULE1_V2_BASELINE_SET` | `RATE_UP_300BP` | Rate environment | `rate_shift_bps = +300` | M2-10, M2-12 |
| M1-05 | SC03 Credit Box Sensitivity | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `CREDIT_BOX_BASELINE_REFERENCE` | Credit-box baseline | Baseline score mix under credit-box scenario set | M2-14 |
| M1-06 | SC03 Credit Box Sensitivity | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `PRIME_GROWTH_SCORE_MIX` | Score mix | Stronger-score / prime-growth score mix | M2-15 |
| M1-07 | SC03 Credit Box Sensitivity | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `NEAR_PRIME_EXPANSION_MIX` | Score mix | More near-prime weight | M2-16, M2-17, M2-18 |
| M1-08 | SC03 Credit Box Sensitivity | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `CREDIT_STRESS_SCORE_MIX` | Score mix | Weaker-score / stress mix | M2-19, M2-20 |
| M1-09 | SC04 Portfolio Mix Sensitivity | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `PRODUCT_MIX_BASELINE_REFERENCE` | Product-mix baseline | Baseline product mix under product-mix scenario set | M2-21 |
| M1-10 | SC04 Portfolio Mix Sensitivity | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `UNSECURED_GROWTH_MIX` | Product mix | Higher unsecured personal loan share | M2-22, M2-23 |
| M1-11 | SC04 Portfolio Mix Sensitivity | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `SECURED_BALANCE_GROWTH_MIX` | Product mix | Higher secured-balance share | M2-24 |
| M1-12 | SC04 Portfolio Mix Sensitivity | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `REVOLVING_LINE_EXPANSION_MIX` | Product mix | Higher revolving-line share | M2-25, M2-26 |
| M1-13 | SC05 Exposure Intensity Sensitivity | `MODULE1_V2_EXPOSURE_INTENSITY_SET` | `EXPOSURE_BASELINE_REFERENCE` | Exposure baseline | Baseline requested-exposure behavior | M2-27 |
| M1-14 | SC05 Exposure Intensity Sensitivity | `MODULE1_V2_EXPOSURE_INTENSITY_SET` | `HIGH_BALANCE_APPETITE` | Exposure intensity | Higher requested-balance appetite | M2-28, M2-29 |
| M1-15 | SC05 Exposure Intensity Sensitivity | `MODULE1_V2_EXPOSURE_INTENSITY_SET` | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | Exposure intensity | Lower requested-balance appetite | M2-30 |
| M1-16 | SC06 LGD Severity Sensitivity | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `LGD_BASELINE_REFERENCE` | LGD baseline | Baseline LGD values | M2-31 |
| M1-17 | SC06 LGD Severity Sensitivity | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `SECURED_SEVERITY_STRESS` | LGD severity | Higher secured-product LGD assumptions | M2-32 |
| M1-18 | SC06 LGD Severity Sensitivity | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `UNSECURED_SEVERITY_STRESS` | LGD severity | Higher unsecured / revolving LGD assumptions | M2-33, M2-34 |
| M1-19 | SC06 LGD Severity Sensitivity | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `BROAD_LGD_STRESS` | LGD severity | Broad LGD stress across secured and unsecured products | M2-35, M2-36 |

The current Module 2 comparison registry includes comparison groups through `CG17`, including `UNSECURED_SEVERITY_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS` for M2-33 versus M2-34 and `BROAD_LGD_STRESS_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS` for M2-35 versus M2-36. fileciteturn158file6

---

# 3. Module 1 — recommended numeric scenario overrides

These are the enhanced values I would use to make the campaign clean, interpretable, and executive-readable. Baseline constants come from the Module 1 design artifacts; scenario overrides are the recommended campaign values to install when creating each Module 1 scenario row.

## 3.1 Rate environment scenarios

| Scenario | `rate_shift_bps` | Interpretation |
|---|---:|---|
| `BASELINE_V2` | `0` | Current-rate baseline |
| `RATE_UP_200BP` | `+200` | Moderate rate stress |
| `RATE_DOWN_200BP` | `-200` | Rate relief / growth opportunity |
| `RATE_UP_300BP` | `+300` | Stronger rate stress |

## 3.2 Score mix scenarios

| Scenario | Super Prime | Prime | Near Prime | Subprime | Deep Subprime | Purpose |
|---|---:|---:|---:|---:|---:|---|
| Baseline / reference | 18% | 28% | 24% | 18% | 12% | Diversified default score mix |
| `PRIME_GROWTH_SCORE_MIX` | 26% | 36% | 22% | 10% | 6% | Stronger-credit growth population |
| `NEAR_PRIME_EXPANSION_MIX` | 12% | 22% | 36% | 20% | 10% | Tests expansion into near-prime |
| `CREDIT_STRESS_SCORE_MIX` | 8% | 16% | 22% | 30% | 24% | Tests weaker-credit mix and risk tightening |

## 3.3 Product mix scenarios

| Scenario | Mortgage | Revolving Line | Auto Loan | Unsecured Personal Loan | HELOC | Purpose |
|---|---:|---:|---:|---:|---:|---|
| Baseline / reference | 30% | 25% | 20% | 15% | 10% | Diversified consumer-retail mix |
| `UNSECURED_GROWTH_MIX` | 20% | 20% | 15% | 35% | 10% | Tests unsecured growth pressure |
| `SECURED_BALANCE_GROWTH_MIX` | 40% | 12% | 25% | 8% | 15% | Tests secured balance growth |
| `REVOLVING_LINE_EXPANSION_MIX` | 20% | 40% | 15% | 15% | 10% | Tests revolving-line concentration |

## 3.4 LGD severity scenarios

| Scenario | Mortgage LGD | Auto LGD | Personal LGD | Revolving LGD | HELOC LGD | Purpose |
|---|---:|---:|---:|---:|---:|---|
| Baseline / reference | 20% | 45% | 70% | 85% | 25% | Baseline severity assumptions |
| `SECURED_SEVERITY_STRESS` | 28% | 55% | 70% | 85% | 35% | Stresses collateral-backed severity |
| `UNSECURED_SEVERITY_STRESS` | 20% | 45% | 85% | 95% | 25% | Stresses unsecured / revolving severity |
| `BROAD_LGD_STRESS` | 28% | 55% | 85% | 95% | 35% | Stresses all product severity families |

---

# 4. Module 2 — strategy profile parameter chart

The current patched Module 2 file’s active strategy row is set to `TIGHTER_SYNTHETIC_RISK_STRATEGY` on the archived Module 1 `BASELINE_V2` population, with `campaign_registry_required_flag = TRUE`, `module1_input_source = ARCHIVE`, and `strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY`. Its tighter synthetic-risk thresholds are `0.060000 / 0.120000 / 0.250000 / 0.300000` for approve / counteroffer / review / decline synthetic estimated-PD proxy thresholds. fileciteturn154file0 fileciteturn154file9

| Strategy profile | Strategy name | Approve max estimated-PD proxy | Counteroffer max estimated-PD proxy | Review max estimated-PD proxy | Decline min estimated-PD proxy | Global approve PTI | Global review PTI | Global decline PTI | Approve DTI | Review DTI | Decline DTI | Failed counteroffer resolution | Product policy profile |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| Baseline | `BASELINE_STRATEGY` | 0.080000 | 0.160000 | 0.300000 | 0.350000 | 0.250000 | 0.400000 | 0.550000 | 0.430000 | 0.600000 | 0.600000 | `MANUAL_REVIEW` | Baseline product policy |
| Tighter synthetic risk | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | 0.060000 | 0.120000 | 0.250000 | 0.300000 | 0.250000 | 0.400000 | 0.550000 | 0.430000 | 0.600000 | 0.600000 | `MANUAL_REVIEW` | Baseline product policy |
| Growth oriented | `GROWTH_ORIENTED_STRATEGY` | 0.100000 | 0.200000 | 0.350000 | 0.400000 | 0.280000 | 0.430000 | 0.580000 | 0.460000 | 0.630000 | 0.630000 | `MANUAL_REVIEW` | Growth product policy |
| Tighter affordability | `TIGHTER_AFFORDABILITY_STRATEGY` | 0.080000 | 0.160000 | 0.300000 | 0.350000 | 0.220000 | 0.350000 | 0.500000 | 0.400000 | 0.550000 | 0.550000 | `MANUAL_REVIEW` | Affordability-tight product policy |
| Counteroffer first | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | 0.080000 | 0.160000 | 0.300000 | 0.350000 | 0.250000 | 0.400000 | 0.550000 | 0.430000 | 0.600000 | 0.600000 | `MANUAL_REVIEW` | Counteroffer-first product policy |
| Product-specific guardrails | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | 0.080000 | 0.160000 | 0.300000 | 0.350000 | 0.250000 | 0.400000 | 0.550000 | 0.430000 | 0.600000 | 0.600000 | `MANUAL_REVIEW` | Product-guardrail policy |
| Manual-review reduction | `MANUAL_REVIEW_REDUCTION_STRATEGY` | 0.080000 | 0.160000 | 0.300000 | 0.350000 | 0.250000 | 0.400000 | 0.550000 | 0.430000 | 0.600000 | 0.600000 | `DECLINE` | Baseline product policy |

The baseline and tighter synthetic-risk rows above are source-backed from the SQL snippets. The remaining strategy profiles are the enhanced campaign runbook values I recommend so that each strategy has a clear, distinct interpretation: growth, affordability discipline, exposure treatment, product-specific guardrails, or review-burden reduction. The registry descriptions support those strategy families: growth loosens selected tolerances, affordability tightening tightens PTI controls, counteroffer management emphasizes reduced-exposure treatment, product guardrails target selected unsecured / revolving products, and manual-review reduction resolves failed counteroffers to final no-offer outcomes. fileciteturn157file8 fileciteturn157file10

---

# 5. Module 2 — baseline product-policy parameter chart

Module 2 product policy must contain exactly one row for each supported product: `MORTGAGE`, `HELOC`, `AUTO_LOAN`, `UNSECURED_PERSONAL_LOAN`, and `REVOLVING_LINE`. Section 3 validates product-policy cardinality, supported products, threshold ordering, exposure bounds, counteroffer controls, and rounding settings before downstream logic runs. fileciteturn160file13

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Min counteroffer % | Max exposure reduction % | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `MORTGAGE` | 0.350000 | 0.450000 | 0.550000 | 0.320000 | 10000 | 20000 | 40000 | 10000 | 75000 | 800000 | 0.500000 | 0.500000 | 5000 |
| `HELOC` | 0.250000 | 0.350000 | 0.450000 | 0.220000 | 8000 | 16000 | 30000 | 7000 | 10000 | 175000 | 0.400000 | 0.500000 | 1000 |
| `AUTO_LOAN` | 0.180000 | 0.280000 | 0.380000 | 0.160000 | 3500 | 7000 | 12000 | 3000 | 5000 | 65000 | 0.500000 | 0.500000 | 500 |
| `UNSECURED_PERSONAL_LOAN` | 0.150000 | 0.250000 | 0.350000 | 0.130000 | 3000 | 6000 | 10000 | 2500 | 1000 | 35000 | 0.500000 | 0.500000 | 500 |
| `REVOLVING_LINE` | 0.120000 | 0.200000 | 0.300000 | 0.100000 | 2000 | 4000 | 8000 | 1800 | 1000 | 20000 | 0.500000 | 0.500000 | 500 |

The baseline product policy rows explicitly state they are simulated strategy defaults, not production underwriting limits, final approved credit policy, empirical calibration, real customer treatment rules, or regulatory thresholds. fileciteturn161file4

---

# 6. Module 2 — enhanced product-policy profiles by strategy

Use these product-policy edits when the strategy profile calls for product-policy behavior rather than only global strategy threshold changes.

| Product policy profile | Products affected | What to change | Recommended values |
|---|---|---|---|
| Baseline product policy | All products | Use baseline product policy table above | No changes |
| Growth product policy | All products | Modestly expand offer capacity while preserving guardrails | Increase `product_max_approved_amount` by ~10%; increase `product_approved_el_cap` by ~10%; leave counteroffer controls unchanged |
| Affordability-tight product policy | All products | Tighten payment burden tolerance | Reduce each product’s `product_approve_max_pti`, `product_review_max_pti`, `product_decline_min_pti`, and `counteroffer_target_pti` by ~2–5 percentage points, keeping order intact |
| Counteroffer-first product policy | All products, especially larger-balance products | Force more reduced-exposure treatment | Reduce `counteroffer_target_pti`; reduce `product_approved_el_cap` by ~15–25%; reduce selected `product_max_approved_amount`; keep `counteroffer_allowed_flag = TRUE` |
| Product-guardrail policy | `UNSECURED_PERSONAL_LOAN`, `REVOLVING_LINE` | Tighten unsecured / revolving guardrails | UPL: lower max approved amount toward 25k–30k and approved EL cap toward 2k. Revolving: lower max approved amount toward 15k–18k and approved EL cap toward 1.2k–1.5k |
| Manual-review reduction product policy | All products | Use baseline product policy | Change strategy-level `failed_counteroffer_resolution` to `DECLINE` |

---

# 7. Module 2 — full campaign run map

This is the practical “what should I set for this M2 run?” table. For each row:

```text
tmp_module2_strategy_params.source_module1_scenario_set_name = M1 scenario_set_name
tmp_module2_strategy_params.source_module1_scenario_name     = M1 scenario_name
tmp_module2_strategy_params.source_population_id             = BASE_POPULATION_V1
tmp_module2_strategy_params.strategy_name                    = listed strategy
tmp_module2_strategy_params.strategy_version                 = V1_0
tmp_module2_strategy_params.module1_input_source             = ARCHIVE
tmp_module2_strategy_params.archive_run_flag                 = TRUE
tmp_module2_strategy_params.strategy_archive_reset_mode       = STRATEGY_SCENARIO_ONLY
tmp_module2_strategy_params.campaign_registry_required_flag   = TRUE
```

The campaign registry maps these technical keys to `module1_run_id`, `module2_run_id`, `showcase_id`, `comparison_group_id`, `validation_evidence_group_id`, README labels, and LinkedIn sequence metadata. fileciteturn150file16

| M2 run | Source M1 run | Module 1 scenario | Strategy profile | Comparison role |
|---:|---:|---|---|---|
| M2-01 | M1-01 | `BASELINE_V2` | `BASELINE_STRATEGY` | Baseline reference for CG01–CG06 |
| M2-02 | M1-01 | `BASELINE_V2` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Challenger for CG01 |
| M2-03 | M1-01 | `BASELINE_V2` | `GROWTH_ORIENTED_STRATEGY` | Challenger for CG02 |
| M2-04 | M1-01 | `BASELINE_V2` | `TIGHTER_AFFORDABILITY_STRATEGY` | Challenger for CG03 |
| M2-05 | M1-01 | `BASELINE_V2` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Challenger for CG04 |
| M2-06 | M1-01 | `BASELINE_V2` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Challenger for CG05 |
| M2-07 | M1-01 | `BASELINE_V2` | `MANUAL_REVIEW_REDUCTION_STRATEGY` | Challenger for CG06 |
| M2-08 | M1-02 | `RATE_UP_200BP` | `BASELINE_STRATEGY` | Baseline for CG07 |
| M2-09 | M1-03 | `RATE_DOWN_200BP` | `BASELINE_STRATEGY` | Baseline for CG09 |
| M2-10 | M1-04 | `RATE_UP_300BP` | `BASELINE_STRATEGY` | Baseline for CG08 |
| M2-11 | M1-02 | `RATE_UP_200BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | Challenger for CG07 |
| M2-12 | M1-04 | `RATE_UP_300BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | Challenger for CG08 |
| M2-13 | M1-03 | `RATE_DOWN_200BP` | `GROWTH_ORIENTED_STRATEGY` | Challenger for CG09 |
| M2-14 | M1-05 | `CREDIT_BOX_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Credit-box reference |
| M2-15 | M1-06 | `PRIME_GROWTH_SCORE_MIX` | `BASELINE_STRATEGY` | Prime-growth baseline |
| M2-16 | M1-07 | `NEAR_PRIME_EXPANSION_MIX` | `BASELINE_STRATEGY` | Baseline for CG10–CG11 |
| M2-17 | M1-07 | `NEAR_PRIME_EXPANSION_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Challenger for CG10 |
| M2-18 | M1-07 | `NEAR_PRIME_EXPANSION_MIX` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Challenger for CG11 |
| M2-19 | M1-08 | `CREDIT_STRESS_SCORE_MIX` | `BASELINE_STRATEGY` | Baseline for CG12 |
| M2-20 | M1-08 | `CREDIT_STRESS_SCORE_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Challenger for CG12 |
| M2-21 | M1-09 | `PRODUCT_MIX_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Product-mix reference |
| M2-22 | M1-10 | `UNSECURED_GROWTH_MIX` | `BASELINE_STRATEGY` | Baseline for CG13 |
| M2-23 | M1-10 | `UNSECURED_GROWTH_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Challenger for CG13 |
| M2-24 | M1-11 | `SECURED_BALANCE_GROWTH_MIX` | `BASELINE_STRATEGY` | Secured-balance baseline |
| M2-25 | M1-12 | `REVOLVING_LINE_EXPANSION_MIX` | `BASELINE_STRATEGY` | Baseline for CG14 |
| M2-26 | M1-12 | `REVOLVING_LINE_EXPANSION_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Challenger for CG14 |
| M2-27 | M1-13 | `EXPOSURE_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Exposure-intensity reference |
| M2-28 | M1-14 | `HIGH_BALANCE_APPETITE` | `BASELINE_STRATEGY` | Baseline for CG15 |
| M2-29 | M1-14 | `HIGH_BALANCE_APPETITE` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Challenger for CG15 |
| M2-30 | M1-15 | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | `BASELINE_STRATEGY` | Low-balance baseline |
| M2-31 | M1-16 | `LGD_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | LGD reference |
| M2-32 | M1-17 | `SECURED_SEVERITY_STRESS` | `BASELINE_STRATEGY` | Secured severity baseline |
| M2-33 | M1-18 | `UNSECURED_SEVERITY_STRESS` | `BASELINE_STRATEGY` | Baseline for CG16 |
| M2-34 | M1-18 | `UNSECURED_SEVERITY_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Challenger for CG16 |
| M2-35 | M1-19 | `BROAD_LGD_STRESS` | `BASELINE_STRATEGY` | Baseline for CG17 |
| M2-36 | M1-19 | `BROAD_LGD_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Challenger for CG17 |

The registry snippets explicitly define SC01 baseline strategy frontier comparisons, SC02 rate environment comparisons, SC03 credit-box comparisons, SC04 product-mix comparisons, SC05 exposure-intensity comparison, and SC06 LGD severity comparisons through CG17. fileciteturn158file8 fileciteturn157file12 fileciteturn157file16 fileciteturn158file6

---

# 8. Strategy profile → M2 run lookup

This is the quickest operational chart when editing Section 2.2.

| Strategy profile | M2 run IDs | Main interpretation |
|---|---|---|
| `BASELINE_STRATEGY` | M2-01, M2-08, M2-09, M2-10, M2-14, M2-15, M2-16, M2-19, M2-21, M2-22, M2-24, M2-25, M2-27, M2-28, M2-30, M2-31, M2-32, M2-33, M2-35 | Reference strategy behavior under each Module 1 scenario |
| `TIGHTER_SYNTHETIC_RISK_STRATEGY` | M2-02, M2-17, M2-20 | Synthetic-risk discipline / approved Expected Loss reduction |
| `GROWTH_ORIENTED_STRATEGY` | M2-03, M2-13 | Simulated offer-growth and approved amount expansion |
| `TIGHTER_AFFORDABILITY_STRATEGY` | M2-04, M2-11, M2-12 | Approved PTI discipline under baseline and rate stress |
| `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | M2-05, M2-18, M2-29 | Exposure management through reduced-exposure treatment |
| `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | M2-06, M2-23, M2-26, M2-34, M2-36 | Unsecured / revolving / severity guardrail testing |
| `MANUAL_REVIEW_REDUCTION_STRATEGY` | M2-07 | Operational review-burden reduction through final no-offer resolution |

---

# 9. Run-order recommendation

I would run the campaign in this order:

```text
Phase 1 — Pure Module 2 frontier on baseline population
    M1-01
    M2-01 through M2-07

Phase 2 — Rate sensitivity
    M1-02 → M2-08, M2-11
    M1-04 → M2-10, M2-12
    M1-03 → M2-09, M2-13

Phase 3 — Credit-box sensitivity
    M1-05 → M2-14
    M1-06 → M2-15
    M1-07 → M2-16, M2-17, M2-18
    M1-08 → M2-19, M2-20

Phase 4 — Product-mix sensitivity
    M1-09 → M2-21
    M1-10 → M2-22, M2-23
    M1-11 → M2-24
    M1-12 → M2-25, M2-26

Phase 5 — Exposure-intensity sensitivity
    M1-13 → M2-27
    M1-14 → M2-28, M2-29
    M1-15 → M2-30

Phase 6 — LGD severity sensitivity
    M1-16 → M2-31
    M1-17 → M2-32
    M1-18 → M2-33, M2-34
    M1-19 → M2-35, M2-36
```

After each Module 2 run, use Section 16.8 as the post-run evidence packet: it shows evidence row counts, the executive evidence row, validation rows needing review, product × score evidence, parameter snapshot hash, and registry-linkage diagnostics. fileciteturn150file10

---

# 10. One important enhancement I would add

For the formal campaign, I would add a **parameter-profile lookup table** or at least a commented runbook block above Section 2.2 so you do not have to manually remember which numeric thresholds belong to `BASELINE_STRATEGY`, `TIGHTER_SYNTHETIC_RISK_STRATEGY`, `GROWTH_ORIENTED_STRATEGY`, and the other profiles.

Right now, the script is correct as a one-active-row system, but the campaign is easier to operate if the file also contains a compact reference block like:

```text
Strategy profile:
    BASELINE_STRATEGY
    TIGHTER_SYNTHETIC_RISK_STRATEGY
    GROWTH_ORIENTED_STRATEGY
    TIGHTER_AFFORDABILITY_STRATEGY
    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
    MANUAL_REVIEW_REDUCTION_STRATEGY

Product policy profile:
    BASELINE_PRODUCT_POLICY
    GROWTH_PRODUCT_POLICY
    AFFORDABILITY_TIGHT_PRODUCT_POLICY
    COUNTEROFFER_FIRST_PRODUCT_POLICY
    PRODUCT_GUARDRAIL_POLICY
```

That would reduce operator error. Section 16.4 already snapshots the active strategy parameters, product-policy parameters, and run-story metadata as JSONB and creates a `parameter_snapshot_hash`, so once the run is executed the evidence layer will preserve exactly what parameter payload produced the result. fileciteturn149file5
<!-- END_MESSAGE C038-M01176 -->


---

<a id="c038-m01178"></a>

### C038-M01178

**Andrew** · 2026-05-10T14:32:07.929000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01178 -->
did you intend to call The SC05 Intensity Set or should it be sensitivity_set like the rest?
<!-- END_MESSAGE C038-M01178 -->


---

<a id="c038-m01183"></a>

### C038-M01183

**ChatGPT** · 2026-05-10T14:33:51.123407-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01183 -->
Yes — you caught a naming inconsistency. I **did not intend** for SC05 to be named differently from the other sensitivity scenario families.

For canonical campaign naming, I recommend changing:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SET
```

to:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

The current Module 2 registry rows label SC05 as **“Exposure Intensity Sensitivity”** but use `MODULE1_V2_EXPOSURE_INTENSITY_SET` for M1-13 / M2-27, M1-14 / M2-28, M1-14 / M2-29, and M1-15 / M2-30. The CG15 comparison registry also uses `MODULE1_V2_EXPOSURE_INTENSITY_SET`. fileciteturn163file0 fileciteturn163file9

The cleaner convention is:

```text
SC03: MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET
SC04: MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET
SC05: MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
SC06: MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET
```

SC04 and SC06 already follow the `_SENSITIVITY_SET` convention in the registry. fileciteturn163file0 fileciteturn163file1

The reason to fix it now is that `module1_scenario_set_name` is not just a label. It is part of the technical run key used for Module 1 source selection, Module 2 registry matching, archive replacement, comparison, frontier grouping, and Section 16 evidence capture. If we leave SC05 as `MODULE1_V2_EXPOSURE_INTENSITY_SET`, it will still work if all tables are consistent, but it will look like an exception and could create avoidable confusion later.

I would patch every SC05 occurrence to:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
```

Specifically update:

```text
M1-13 / M2-27
M1-14 / M2-28
M1-14 / M2-29
M1-15 / M2-30
CG15
any Module 1 parameter row for M1-13 through M1-15
any tmp_module2_strategy_params source field when running M2-27 through M2-30
```

Do this **before the formal campaign run**. Since the successful run was a smoke test, I would not worry about preserving the shorter-name archive/evidence slices. For the formal run, standardize the name and rebuild those slices cleanly.
<!-- END_MESSAGE C038-M01183 -->


---

<a id="c038-m01184"></a>

### C038-M01184

**Andrew** · 2026-05-10T14:43:12.757000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01184 -->
I made an error on some module 1 runs.  can you give me a query to delete all where scenario_set_name is 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
<!-- END_MESSAGE C038-M01184 -->


---

<a id="c038-m01187"></a>

### C038-M01187

**ChatGPT** · 2026-05-10T14:45:02.915129-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01187 -->
Yes. For **Module 1 archived scenario rows**, the main delete target should be:

```sql
credit_decisioning_sim.synthetic_applications_scenario_archive
```

That is the Module 1 scenario archive table Module 2 consumes when `module1_input_source = 'ARCHIVE'`. Module 2 then carries that lineage forward as `module1_scenario_set_name`, `module1_scenario_name`, and `population_id`, so cleaning the mistaken Module 1 archive slice is the right first move. fileciteturn165file59

Use this safe transaction pattern.

```sql
/***************************************************************************************************
DELETE MODULE 1 ARCHIVED SCENARIO RUNS FOR SC05 EXPOSURE INTENSITY SENSITIVITY SET

Purpose:
    Remove mistakenly-created Module 1 archive rows where scenario_set_name equals:

        MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET

Primary target:
    credit_decisioning_sim.synthetic_applications_scenario_archive

Important:
    Review the preview counts first.

    If the delete counts look correct, run COMMIT.
    If the delete counts look wrong, run ROLLBACK instead of COMMIT.
***************************************************************************************************/

BEGIN;


/*-----------------------------------------------------------------------------------------------
1. Preview rows that will be deleted.

Expected:
    This should show only the mistaken Module 1 exposure-intensity scenario runs.
-----------------------------------------------------------------------------------------------*/

SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_to_delete
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
2. Delete the mistaken Module 1 archived scenario rows.

The RETURNING clause gives a post-delete count by scenario_name and population_id before you commit.
-----------------------------------------------------------------------------------------------*/

WITH deleted_rows AS (
    DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
    RETURNING
        scenario_set_name,
        scenario_name,
        population_id
)
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS deleted_row_count
FROM deleted_rows
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
3. Commit only if the deleted counts are correct.

Use one of these:
    COMMIT;
    ROLLBACK;
-----------------------------------------------------------------------------------------------*/

-- COMMIT;
-- ROLLBACK;
```

If your **latest-run Module 1 table** also currently contains the bad scenario set, run this separately after reviewing the counts:

```sql
/***************************************************************************************************
OPTIONAL — DELETE CURRENT MODULE 1 LATEST-RUN ROWS FOR THE SAME SCENARIO SET

Use only if credit_decisioning_sim.synthetic_applications currently contains the mistaken
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET latest-run output.
***************************************************************************************************/

BEGIN;


/* Preview latest-run rows. */
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_to_delete
FROM credit_decisioning_sim.synthetic_applications
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    scenario_name,
    population_id;


/* Delete latest-run rows if preview confirms they are wrong. */
WITH deleted_rows AS (
    DELETE FROM credit_decisioning_sim.synthetic_applications
    WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
    RETURNING
        scenario_set_name,
        scenario_name,
        population_id
)
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS deleted_row_count
FROM deleted_rows
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    scenario_name,
    population_id;


-- COMMIT;
-- ROLLBACK;
```

If any **Module 2 runs already consumed** those mistaken Module 1 slices, also clean the downstream Module 2 archive/evidence for that same lineage before rerunning. Module 2’s archive/evidence grain uses `module1_scenario_set_name`, `module1_scenario_name`, and `population_id`, so downstream cleanup should use `module1_scenario_set_name`, not `scenario_set_name`. fileciteturn165file51

```sql
/***************************************************************************************************
OPTIONAL — DOWNSTREAM MODULE 2 CLEANUP FOR RUNS THAT CONSUMED THE MISTAKEN MODULE 1 SCENARIO SET

Use only if Module 2 has already been run against:

    MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET

This removes downstream Module 2 latest-run, archive, and Section 16 evidence rows tied to that
Module 1 scenario set.
***************************************************************************************************/

BEGIN;


/* Preview affected Module 2 archive rows. */
SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    COUNT(*) AS module2_archive_rows_to_delete
FROM credit_decisioning_sim.strategy_decisions_archive
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
GROUP BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version
ORDER BY
    module1_scenario_name,
    strategy_name,
    strategy_version;


/* Delete Module 2 latest-run rows if current latest-run used the bad scenario set. */
DELETE FROM credit_decisioning_sim.strategy_decisions
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET';


/* Delete Module 2 archive rows for the bad scenario set. */
DELETE FROM credit_decisioning_sim.strategy_decisions_archive
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET';


/* Delete Section 16 executive evidence rows for the bad scenario set. */
DELETE FROM credit_decisioning_sim.strategy_run_evidence_summary
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET';


/* Delete Section 16 validation evidence rows for the bad scenario set. */
DELETE FROM credit_decisioning_sim.strategy_run_validation_evidence
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET';


/* Delete Section 16 parameter snapshot rows for the bad scenario set. */
DELETE FROM credit_decisioning_sim.strategy_run_parameter_snapshot
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET';


/* Delete Section 16 product × score segment evidence rows for the bad scenario set. */
DELETE FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET';


-- COMMIT;
-- ROLLBACK;
```

My recommendation: run the **Module 1 archive delete first**, then rerun the corrected SC05 Module 1 scenarios with the intended canonical name. Only run the downstream Module 2 cleanup block if those incorrect Module 1 slices had already fed Module 2 runs.
<!-- END_MESSAGE C038-M01187 -->


---

<a id="c038-m01188"></a>

### C038-M01188

**Andrew** · 2026-05-10T14:48:43.483000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01188 -->
I know why I messed up, in your response above you show me 3.3 product mix scenarios but then you skip to 3.4 lgd severity scenarios.  you never show me what the parameters are for the exposure intensity sensitivity.
<!-- END_MESSAGE C038-M01188 -->


---

<a id="c038-m01194"></a>

### C038-M01194

**ChatGPT** · 2026-05-10T14:52:33.592220-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01194 -->
According to a document from 2026-05-10, you are right — I skipped the **Exposure Intensity Sensitivity** parameter chart between Product Mix and LGD Severity. That omission made SC05 ambiguous. The current Module 2 registry identifies SC05 as **Exposure Intensity Sensitivity**, with `HIGH_BALANCE_APPETITE` described as higher requested-exposure intensity and `LOW_BALANCE_CONSERVATIVE_REQUESTS` described as lower requested-exposure intensity. fileciteturn167file9

The missing chart should have been this:

## 3.4 Exposure intensity sensitivity scenarios

These scenarios should change **requested exposure bounds**, not product mix, score mix, rate environment, or LGD. Module 1’s `tmp_module1_params` parameter card has explicit product amount bound fields such as `min_personal_amt`, `max_personal_amt`, `min_auto_amt`, `max_auto_amt`, `min_revolving_amt`, `max_revolving_amt`, `min_heloc_amt`, `max_heloc_amt`, `min_mortgage_amt`, and `max_mortgage_amt`. fileciteturn168file0

The baseline Module 1 V2.0 amount bounds are:

| Product | Baseline min | Baseline max |
|---|---:|---:|
| `UNSECURED_PERSONAL_LOAN` | 1,000 | 50,000 |
| `AUTO_LOAN` | 5,000 | 80,000 |
| `REVOLVING_LINE` | 1,000 | 30,000 |
| `HELOC` | 10,000 | 250,000 |
| `MORTGAGE` | 75,000 | 1,500,000 |

Those bounds are explicitly described in Module 1 as the ranges that shape first-stage requested amount anchors by product. fileciteturn169file0

## Corrected SC05 Module 1 parameter chart

Use this as the missing exposure-intensity section.

| M1 run | Scenario set | Scenario name | Parameter family | What changes | What stays fixed |
|---:|---|---|---|---|---|
| M1-13 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `EXPOSURE_BASELINE_REFERENCE` | Exposure baseline | Use baseline product amount bounds | Product mix, score mix, rate shift, LGD, population |
| M1-14 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `HIGH_BALANCE_APPETITE` | Higher requested exposure | Increase product max requested amount bounds | Product mix, score mix, rate shift, LGD, population |
| M1-15 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | Lower requested exposure | Decrease product max requested amount bounds | Product mix, score mix, rate shift, LGD, population |

## Recommended numeric values

I would keep the **minimums unchanged** and move the **maximums**. That isolates exposure appetite without creating strange low-end behavior or unnecessary conflicts with downstream Module 2 product minimums.

| Scenario | Personal min | Personal max | Auto min | Auto max | Revolving min | Revolving max | HELOC min | HELOC max | Mortgage min | Mortgage max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `EXPOSURE_BASELINE_REFERENCE` | 1,000 | 50,000 | 5,000 | 80,000 | 1,000 | 30,000 | 10,000 | 250,000 | 75,000 | 1,500,000 |
| `HIGH_BALANCE_APPETITE` | 1,000 | 62,500 | 5,000 | 100,000 | 1,000 | 37,500 | 10,000 | 312,500 | 75,000 | 1,875,000 |
| `LOW_BALANCE_CONSERVATIVE_REQUESTS` | 1,000 | 37,500 | 5,000 | 60,000 | 1,000 | 22,500 | 10,000 | 187,500 | 75,000 | 1,125,000 |

That is a clean **+25% / -25% max-bound design**:

```text
HIGH_BALANCE_APPETITE:
    max amount bounds = baseline × 1.25

LOW_BALANCE_CONSERVATIVE_REQUESTS:
    max amount bounds = baseline × 0.75

Minimum amount bounds:
    unchanged from baseline
```

## Why these are the right levers

Exposure intensity should affect `requested_amount`, `amount_to_income_ratio`, requested PTI, requested Expected Loss, and later Module 2 approved-exposure behavior. Module 1 defines `amount_to_income_ratio` as requested amount divided by annual income and treats it as a useful secondary stress signal for exposure appetite interpretation. fileciteturn167file0

So SC05 should be interpreted as:

```text
HIGH_BALANCE_APPETITE:
    Same population.
    Same product mix.
    Same score mix.
    Same rates.
    Same LGD.
    Higher requested exposure ceilings.
    Expected effect: higher requested amount, higher amount-to-income, potentially higher PTI and Expected Loss.

LOW_BALANCE_CONSERVATIVE_REQUESTS:
    Same population.
    Same product mix.
    Same score mix.
    Same rates.
    Same LGD.
    Lower requested exposure ceilings.
    Expected effect: lower requested amount, lower amount-to-income, potentially lower PTI and Expected Loss.
```

## Corrected run linkage

| M1 run | M1 scenario | Feeds M2 run(s) | M2 strategy |
|---:|---|---:|---|
| M1-13 | `EXPOSURE_BASELINE_REFERENCE` | M2-27 | `BASELINE_STRATEGY` |
| M1-14 | `HIGH_BALANCE_APPETITE` | M2-28 | `BASELINE_STRATEGY` |
| M1-14 | `HIGH_BALANCE_APPETITE` | M2-29 | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` |
| M1-15 | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | M2-30 | `BASELINE_STRATEGY` |

The retrieved registry rows show this exact SC05 run intent, though the older retrieved file still used `MODULE1_V2_EXPOSURE_INTENSITY_SET`; based on our naming decision, the canonical set name should now be `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET`. fileciteturn167file9

## Corrected numbering for the parameter runbook

The prior runbook section should now read:

```text
3.1 Rate environment scenarios
3.2 Score mix scenarios
3.3 Product mix scenarios
3.4 Exposure intensity sensitivity scenarios
3.5 LGD severity scenarios
```

The missing SC05 chart is what caused the ambiguity. The clean campaign approach is to rerun M1-13 through M1-15 using the canonical scenario set name and the amount-bound values above, then rerun their downstream M2 runs.
<!-- END_MESSAGE C038-M01194 -->


---

<a id="c038-m01196"></a>

### C038-M01196

**Andrew** · 2026-05-10T15:19:04.703000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01196 -->
the erroneous lgd rows under the exposure_intensity_sensitivity are still there
<!-- END_MESSAGE C038-M01196 -->


**Attachments in export:** `image(68).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01198"></a>

### C038-M01198

**ChatGPT** · 2026-05-10T15:20:57.348631-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01198 -->
Yes — the preview is showing exactly the problem: under

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

you have the three valid SC05 exposure-intensity rows **plus** three LGD rows that belong under the LGD severity scenario set. The LGD rows are:

```text
BROAD_LGD_STRESS
SECURED_SEVERITY_STRESS
UNSECURED_SEVERITY_STRESS
```

The prior block in your screenshot is only the **preview query**, so it did not delete anything yet. fileciteturn170file0

Do **not** delete all six rows unless you want to rerun the full SC05 exposure-intensity set. Use this targeted cleanup instead.

```sql
/***************************************************************************************************
TARGETED CLEANUP — DELETE ERRONEOUS LGD SCENARIOS FROM EXPOSURE INTENSITY SCENARIO SET

Purpose:
    Remove only LGD severity scenarios that were mistakenly archived under:

        MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET

Correct rows to preserve under this scenario set:
    EXPOSURE_BASELINE_REFERENCE
    HIGH_BALANCE_APPETITE
    LOW_BALANCE_CONSERVATIVE_REQUESTS

Erroneous rows to delete:
    BROAD_LGD_STRESS
    SECURED_SEVERITY_STRESS
    UNSECURED_SEVERITY_STRESS

Primary target:
    credit_decisioning_sim.synthetic_applications_scenario_archive

Important:
    If you are still inside the prior BEGIN transaction from your screenshot, do not run BEGIN again.
    Either continue in that open transaction or ROLLBACK and restart cleanly.
***************************************************************************************************/

BEGIN;


/*-----------------------------------------------------------------------------------------------
1. Preview only the erroneous LGD rows that will be deleted.

Expected:
    3 rows, each with 50,000 records:
        BROAD_LGD_STRESS
        SECURED_SEVERITY_STRESS
        UNSECURED_SEVERITY_STRESS
-----------------------------------------------------------------------------------------------*/

SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_to_delete
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  )
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
2. Delete only the erroneous LGD rows.

Expected deleted count:
    150,000 total rows if each of the three mistaken scenarios has 50,000 rows.
-----------------------------------------------------------------------------------------------*/

WITH deleted_rows AS (
    DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
      AND scenario_name IN (
            'BROAD_LGD_STRESS',
            'SECURED_SEVERITY_STRESS',
            'UNSECURED_SEVERITY_STRESS'
      )
    RETURNING
        scenario_set_name,
        scenario_name,
        population_id
)
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS deleted_row_count
FROM deleted_rows
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
3. Verify remaining rows under the exposure-intensity scenario set.

Expected:
    Only these three rows should remain:
        EXPOSURE_BASELINE_REFERENCE
        HIGH_BALANCE_APPETITE
        LOW_BALANCE_CONSERVATIVE_REQUESTS
-----------------------------------------------------------------------------------------------*/

SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS remaining_row_count
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
4. Commit only if the preview, delete, and remaining-row checks look correct.

Use COMMIT if correct.
Use ROLLBACK if anything looks wrong.
-----------------------------------------------------------------------------------------------*/

-- COMMIT;
-- ROLLBACK;
```

If those bad LGD rows also exist in the **current Module 1 latest-run table**, use this optional cleanup:

```sql
/***************************************************************************************************
OPTIONAL CLEANUP — DELETE ERRONEOUS LGD SCENARIOS FROM MODULE 1 LATEST-RUN TABLE

Use only if credit_decisioning_sim.synthetic_applications currently contains one of the mistaken
LGD scenarios under MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET.
***************************************************************************************************/

BEGIN;


/* Preview latest-run rows. */
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_to_delete
FROM credit_decisioning_sim.synthetic_applications
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  )
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/* Delete latest-run rows only if preview confirms they are wrong. */
WITH deleted_rows AS (
    DELETE FROM credit_decisioning_sim.synthetic_applications
    WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
      AND scenario_name IN (
            'BROAD_LGD_STRESS',
            'SECURED_SEVERITY_STRESS',
            'UNSECURED_SEVERITY_STRESS'
      )
    RETURNING
        scenario_set_name,
        scenario_name,
        population_id
)
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS deleted_row_count
FROM deleted_rows
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


-- COMMIT;
-- ROLLBACK;
```

If Module 2 already consumed any of those erroneous LGD slices under the wrong Module 1 scenario set, also clean downstream Module 2 archive/evidence rows:

```sql
/***************************************************************************************************
OPTIONAL DOWNSTREAM MODULE 2 CLEANUP — ONLY IF MODULE 2 CONSUMED THE ERRONEOUS LGD SLICES

This removes Module 2 latest-run, archive, and evidence rows tied to the mistaken Module 1 lineage:

    module1_scenario_set_name = MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
    module1_scenario_name IN:
        BROAD_LGD_STRESS
        SECURED_SEVERITY_STRESS
        UNSECURED_SEVERITY_STRESS

Use only if Module 2 was already run against those mistaken Module 1 archive rows.
***************************************************************************************************/

BEGIN;


/* Preview affected Module 2 archive slices. */
SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    COUNT(*) AS module2_archive_rows_to_delete
FROM credit_decisioning_sim.strategy_decisions_archive
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  )
GROUP BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version
ORDER BY
    module1_scenario_name,
    strategy_name,
    strategy_version;


/* Delete Module 2 latest-run rows if current latest-run used the mistaken lineage. */
DELETE FROM credit_decisioning_sim.strategy_decisions
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  );


/* Delete Module 2 archive rows for the mistaken lineage. */
DELETE FROM credit_decisioning_sim.strategy_decisions_archive
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  );


/* Delete Section 16 evidence rows for the mistaken lineage. */
DELETE FROM credit_decisioning_sim.strategy_run_evidence_summary
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  );

DELETE FROM credit_decisioning_sim.strategy_run_validation_evidence
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  );

DELETE FROM credit_decisioning_sim.strategy_run_parameter_snapshot
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  );

DELETE FROM credit_decisioning_sim.strategy_run_segment_evidence_summary
WHERE module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND module1_scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  );


-- COMMIT;
-- ROLLBACK;
```

After cleanup, rerun the LGD scenarios under:

```text
MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET
```

and keep the exposure-intensity set limited to:

```text
EXPOSURE_BASELINE_REFERENCE
HIGH_BALANCE_APPETITE
LOW_BALANCE_CONSERVATIVE_REQUESTS
```
<!-- END_MESSAGE C038-M01198 -->


---

<a id="c038-m01200"></a>

### C038-M01200

**Andrew** · 2026-05-10T15:33:53.019000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01200 -->
Finished module 1 campaign.  will begin module 2 campaign shortly.  please review these QA
<!-- END_MESSAGE C038-M01200 -->


**Attachments in export:** `image(70).png`, `image(71).png`, `module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01209"></a>

### C038-M01209

**ChatGPT** · 2026-05-10T15:37:56.271460-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01209 -->
Your Module 1 campaign QA looks **clean and ready to feed Module 2**. I do not see a blocking issue in the screenshots.

I reviewed three things from what you showed: the scenario-level metric summary, the archive inventory, and the uploaded product × score × scenario QA CSV. The design expectation for Module 1 is controlled scenario testing with matched populations and deterministic outputs, so the key QA question is whether each scenario has 50,000 rows, stable lineage, isolated parameter movement, and expected directional risk behavior before Module 2 consumes the archive. That is exactly the scenario discipline Module 1 was designed to support. fileciteturn170file67

## Overall QA verdict

```text
STATUS: PASS — MODULE 1 CAMPAIGN READY FOR MODULE 2 INPUT
```

The archive now shows **19 scenario slices**, each with:

```text
rows_archived = 50,000
population_id = BASE_POPULATION_V1
first_archived_ts = last_archived_ts for each slice
```

That means each scenario slice appears to have landed as one clean archive insertion. The bad LGD rows under the exposure-intensity set are no longer present in the archive view. SC05 now contains only:

```text
EXPOSURE_BASELINE_REFERENCE
HIGH_BALANCE_APPETITE
LOW_BALANCE_CONSERVATIVE_REQUESTS
```

And SC06 correctly contains:

```text
LGD_BASELINE_REFERENCE
SECURED_SEVERITY_STRESS
UNSECURED_SEVERITY_STRESS
BROAD_LGD_STRESS
```

The uploaded product × score QA CSV also reconciles: **475 rows = 19 scenarios × 5 products × 5 score bands**, and every scenario sums to **50,000 applications**. That is exactly what I would want before starting the Module 2 strategy campaign.

## Scenario behavior review

### Baseline / reference scenarios

These rows correctly match the baseline metrics:

```text
BASELINE_V2
CREDIT_BOX_BASELINE_REFERENCE
EXPOSURE_BASELINE_REFERENCE
LGD_BASELINE_REFERENCE
PORTFOLIO_MIX_BASELINE_REFERENCE
```

They all show the same baseline profile:

```text
applications:          50,000
avg_requested_amount:  about 133,329
avg_apr:               0.1456
avg_monthly_payment:   about 1,510.70
avg_pti:               0.1650
avg_pd:                0.1634
avg_lgd:               0.4923
avg_expected_loss:     about 4,788.67
total_expected_loss:   about 239.43M
```

That is good. It means each scenario family’s baseline reference is properly anchored to the same default population / product / score / exposure / LGD / rate setup.

### Rate sensitivity scenarios

The rate scenarios behave as expected:

```text
RATE_DOWN_200BP:
    avg_apr drops to 0.1285
    avg_monthly_payment drops to about 1,385
    avg_pti drops to 0.1535
    avg_expected_loss declines modestly

RATE_UP_200BP:
    avg_apr rises to 0.1614
    avg_monthly_payment rises to about 1,612
    avg_pti rises to 0.1741
    avg_expected_loss rises modestly

RATE_UP_300BP:
    avg_apr rises further to 0.1685
    avg_monthly_payment rises to about 1,645
    avg_pti rises to 0.1771
    avg_expected_loss rises modestly again
```

This is directionally correct: rate movement flows into APR, payment, PTI, and then modestly into estimated-PD proxy / Expected Loss. That matches the Module 1 design principle that the engine should preserve the transparent chain from rate environment to APR, payment burden, affordability, estimated risk, and Expected Loss. fileciteturn170file67

### Credit box sensitivity scenarios

These look especially strong.

```text
PRIME_GROWTH_SCORE_MIX:
    avg_pd drops to 0.1095
    avg_expected_loss drops to about 3,499.56
    total_expected_loss drops to about 174.98M

NEAR_PRIME_EXPANSION_MIX:
    avg_pd rises modestly to 0.1741
    total_expected_loss rises to about 262.86M

CREDIT_STRESS_SCORE_MIX:
    avg_pd rises sharply to 0.2511
    avg_expected_loss rises to about 6,770.82
    total_expected_loss rises to about 338.54M
```

That is the right gradient. Prime growth improves risk; near-prime expansion adds moderate risk; credit stress materially increases risk. This is exactly the kind of directional borrower-quality behavior Module 1 validation was intended to confirm. The Module 1 Validation Summary emphasizes deterministic population comparability and directional estimated-risk / Expected Loss behavior, so these outputs are aligned with the validated framework. fileciteturn170file68

### Exposure intensity sensitivity scenarios

This now looks correct and clean.

```text
EXPOSURE_BASELINE_REFERENCE:
    avg_requested_amount about 133,329
    total_expected_loss about 239.43M

HIGH_BALANCE_APPETITE:
    avg_requested_amount rises to about 149,334
    avg_monthly_payment rises to about 1,729.54
    avg_pti rises to 0.1886
    total_expected_loss rises to about 276.42M

LOW_BALANCE_CONSERVATIVE_REQUESTS:
    avg_requested_amount drops to about 112,405
    avg_monthly_payment drops to about 1,248.95
    avg_pti drops to 0.1379
    total_expected_loss drops to about 198.63M
```

This is the cleanest possible SC05 behavior: APR, LGD, product mix, and score mix remain effectively stable, while requested exposure and downstream affordability / Expected Loss move. That means the exposure-intensity scenarios are isolating the intended lever.

### LGD severity sensitivity scenarios

These also look correct.

```text
LGD_BASELINE_REFERENCE:
    avg_lgd 0.4923
    total_expected_loss about 239.43M

SECURED_SEVERITY_STRESS:
    avg_lgd 0.5462
    total_expected_loss about 309.92M

UNSECURED_SEVERITY_STRESS:
    avg_lgd 0.5400
    total_expected_loss about 247.53M

BROAD_LGD_STRESS:
    avg_lgd 0.5939
    total_expected_loss about 318.02M
```

The important point: requested amount, APR, PTI, and PD remain stable while LGD and Expected Loss move. That means the LGD scenarios are isolating severity assumptions properly.

The secured severity stress has a much larger total Expected Loss impact than unsecured severity stress, which is reasonable because the portfolio contains large secured-balance products. Broad LGD stress is highest, as expected.

### Portfolio mix sensitivity scenarios

The product mix scenarios also look directionally coherent.

```text
UNSECURED_GROWTH_MIX:
    avg_requested_amount drops to about 101,418
    avg_lgd rises to 0.5487
    total_expected_loss drops to about 211.99M

REVOLVING_LINE_EXPANSION_MIX:
    avg_requested_amount drops to about 99,288
    avg_apr rises to 0.1685
    avg_lgd rises to 0.5785
    total_expected_loss drops to about 203.52M

SECURED_BALANCE_GROWTH_MIX:
    avg_requested_amount rises to about 172,558
    avg_lgd drops to 0.3871
    total_expected_loss rises to about 281.35M
```

These results are plausible. Unsecured and revolving mixes raise LGD / APR characteristics but reduce average requested amount materially, so total Expected Loss can still decline versus baseline. Secured-balance growth lowers average LGD but raises requested exposure enough to increase total Expected Loss. That is exactly the kind of product-structure tradeoff Module 2 should later interpret.

## Archive inventory review

The archive inventory in your screenshot is now clean:

```text
MODULE1_V2_BASELINE_SET:
    BASELINE_V2
    RATE_DOWN_200BP
    RATE_UP_200BP
    RATE_UP_300BP

MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET:
    CREDIT_BOX_BASELINE_REFERENCE
    CREDIT_STRESS_SCORE_MIX
    NEAR_PRIME_EXPANSION_MIX
    PRIME_GROWTH_SCORE_MIX

MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET:
    EXPOSURE_BASELINE_REFERENCE
    HIGH_BALANCE_APPETITE
    LOW_BALANCE_CONSERVATIVE_REQUESTS

MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET:
    BROAD_LGD_STRESS
    LGD_BASELINE_REFERENCE
    SECURED_SEVERITY_STRESS
    UNSECURED_SEVERITY_STRESS

MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET:
    PORTFOLIO_MIX_BASELINE_REFERENCE
    REVOLVING_LINE_EXPANSION_MIX
    SECURED_BALANCE_GROWTH_MIX
    UNSECURED_GROWTH_MIX
```

That is the intended 19-run Module 1 campaign inventory.

## Final pre-Module 2 checks I would run

Before starting Module 2, run this one compact check to confirm no old naming artifacts or misplaced scenario rows remain.

```sql
/***************************************************************************************************
MODULE 1 CAMPAIGN FINAL READINESS CHECK BEFORE MODULE 2

Expected:
    total_archived_scenario_slices = 19
    total_archived_rows = 950000
    bad_row_count = 0
***************************************************************************************************/

WITH expected_scenarios AS (
    SELECT *
    FROM (
        VALUES
            ('MODULE1_V2_BASELINE_SET', 'BASELINE_V2'),
            ('MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP'),
            ('MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP'),
            ('MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP'),

            ('MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_BOX_BASELINE_REFERENCE'),
            ('MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'PRIME_GROWTH_SCORE_MIX'),
            ('MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX'),
            ('MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX'),

            ('MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'PORTFOLIO_MIX_BASELINE_REFERENCE'),
            ('MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX'),
            ('MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'SECURED_BALANCE_GROWTH_MIX'),
            ('MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX'),

            ('MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET', 'EXPOSURE_BASELINE_REFERENCE'),
            ('MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET', 'HIGH_BALANCE_APPETITE'),
            ('MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET', 'LOW_BALANCE_CONSERVATIVE_REQUESTS'),

            ('MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'LGD_BASELINE_REFERENCE'),
            ('MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'SECURED_SEVERITY_STRESS'),
            ('MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS'),
            ('MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS')
    ) v(scenario_set_name, scenario_name)
),

archive_inventory AS (
    SELECT
        scenario_set_name,
        scenario_name,
        population_id,
        COUNT(*) AS archived_rows
    FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    GROUP BY
        scenario_set_name,
        scenario_name,
        population_id
),

unexpected_rows AS (
    SELECT a.*
    FROM archive_inventory a
    LEFT JOIN expected_scenarios e
        ON e.scenario_set_name = a.scenario_set_name
       AND e.scenario_name = a.scenario_name
    WHERE e.scenario_set_name IS NULL
),

missing_rows AS (
    SELECT e.*
    FROM expected_scenarios e
    LEFT JOIN archive_inventory a
        ON a.scenario_set_name = e.scenario_set_name
       AND a.scenario_name = e.scenario_name
       AND a.population_id = 'BASE_POPULATION_V1'
    WHERE a.scenario_set_name IS NULL
)

SELECT
    (SELECT COUNT(*) FROM archive_inventory) AS total_archived_scenario_slices,
    (SELECT SUM(archived_rows) FROM archive_inventory) AS total_archived_rows,
    (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000) AS scenario_slices_not_50000_rows,
    (SELECT COUNT(*) FROM unexpected_rows) AS unexpected_scenario_slice_count,
    (SELECT COUNT(*) FROM missing_rows) AS missing_expected_scenario_slice_count,
    CASE
        WHEN (SELECT COUNT(*) FROM archive_inventory) = 19
         AND (SELECT SUM(archived_rows) FROM archive_inventory) = 950000
         AND (SELECT COUNT(*) FROM archive_inventory WHERE archived_rows <> 50000) = 0
         AND (SELECT COUNT(*) FROM unexpected_rows) = 0
         AND (SELECT COUNT(*) FROM missing_rows) = 0
            THEN 'MODULE_1_CAMPAIGN_READY_FOR_MODULE_2'
        ELSE 'REVIEW_MODULE_1_CAMPAIGN_ARCHIVE_BEFORE_MODULE_2'
    END AS module1_campaign_readiness_status;
```

Also run this specific old-name check:

```sql
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name IN (
    'MODULE1_V2_EXPOSURE_INTENSITY_SET',
    'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
)
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    scenario_name;
```

Expected: only the `_SENSITIVITY_SET` version should appear, and it should have exactly the three SC05 exposure-intensity rows.

## Module 2 readiness note

Before you begin Module 2, make sure the Module 2 campaign registry and comparison registry now use the corrected scenario set name everywhere:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

especially for:

```text
M2-27
M2-28
M2-29
M2-30
CG15
```

If those registry rows still use the older `MODULE1_V2_EXPOSURE_INTENSITY_SET`, Section 3 registry matching will either fail or force you into a mismatch. Since your Module 2 file is designed to use formal registry matching and then carry those IDs into Section 16 evidence capture, the registry needs to be exact before the run. Module 2’s Section 3 and Section 16 framework are specifically designed to use the registry as the run-ID and evidence-linkage source. fileciteturn170file29

My recommendation: **proceed to Module 2 after running the two final readiness checks above.**
<!-- END_MESSAGE C038-M01209 -->


---

<a id="c038-m01210"></a>

### C038-M01210

**Andrew** · 2026-05-10T15:42:47.233000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01210 -->
when I run your query i get 3 unexpected:
<!-- END_MESSAGE C038-M01210 -->


**Attachments in export:** `image(72).png`, `image(74).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01213"></a>

### C038-M01213

**ChatGPT** · 2026-05-10T15:44:02.320911-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01213 -->
Yes — the query is doing its job correctly. You still have **three extra LGD scenario slices archived under the SC05 exposure-intensity scenario set**.

Your readiness output shows:

```text
total_archived_scenario_slices = 22
total_archived_rows            = 1,100,000
unexpected_scenario_slice_count = 3
missing_expected_scenario_slice_count = 0
```

That means:

```text
Expected: 19 slices × 50,000 = 950,000 rows
Actual:   22 slices × 50,000 = 1,100,000 rows
Extra:     3 slices × 50,000 = 150,000 rows
```

The three unexpected rows are exactly these misplaced LGD scenarios:

```text
BROAD_LGD_STRESS
SECURED_SEVERITY_STRESS
UNSECURED_SEVERITY_STRESS
```

They currently exist under:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

They should exist only under:

```text
MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET
```

Use this targeted cleanup. It will preserve the valid SC05 rows:

```text
EXPOSURE_BASELINE_REFERENCE
HIGH_BALANCE_APPETITE
LOW_BALANCE_CONSERVATIVE_REQUESTS
```

```sql
/***************************************************************************************************
TARGETED MODULE 1 ARCHIVE CLEANUP

Purpose:
    Delete only the three LGD severity scenarios that were accidentally archived under the SC05
    exposure-intensity scenario set.

Do not delete the full exposure-intensity set.

Rows to delete:
    MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET / BROAD_LGD_STRESS
    MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET / SECURED_SEVERITY_STRESS
    MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET / UNSECURED_SEVERITY_STRESS

Expected delete count:
    150,000 rows total
    50,000 rows per scenario
***************************************************************************************************/

BEGIN;


/*-----------------------------------------------------------------------------------------------
1. Preview the exact rows that will be deleted.

Expected:
    3 rows, each with 50,000 records.
-----------------------------------------------------------------------------------------------*/

SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_to_delete
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND scenario_name IN (
        'BROAD_LGD_STRESS',
        'SECURED_SEVERITY_STRESS',
        'UNSECURED_SEVERITY_STRESS'
  )
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
2. Delete only the misplaced LGD rows from the exposure-intensity scenario set.

This does not touch the correctly archived LGD severity rows under:

    MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET
-----------------------------------------------------------------------------------------------*/

WITH deleted_rows AS (
    DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
      AND scenario_name IN (
            'BROAD_LGD_STRESS',
            'SECURED_SEVERITY_STRESS',
            'UNSECURED_SEVERITY_STRESS'
      )
    RETURNING
        scenario_set_name,
        scenario_name,
        population_id
)
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS deleted_row_count
FROM deleted_rows
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
3. Verify the exposure-intensity scenario set now contains only the valid SC05 rows.

Expected:
    EXPOSURE_BASELINE_REFERENCE          50,000
    HIGH_BALANCE_APPETITE               50,000
    LOW_BALANCE_CONSERVATIVE_REQUESTS   50,000
-----------------------------------------------------------------------------------------------*/

SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS remaining_row_count
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
4. Verify the LGD severity scenario set still contains the correct LGD rows.

Expected:
    LGD_BASELINE_REFERENCE          50,000
    SECURED_SEVERITY_STRESS         50,000
    UNSECURED_SEVERITY_STRESS       50,000
    BROAD_LGD_STRESS                50,000
-----------------------------------------------------------------------------------------------*/

SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS remaining_row_count
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;


/*-----------------------------------------------------------------------------------------------
5. Commit only if the preview, delete count, and verification outputs are correct.

Expected final Module 1 archive state:
    19 scenario slices
    950,000 total archived rows
    0 unexpected scenario slices
    0 missing expected scenario slices
-----------------------------------------------------------------------------------------------*/

-- COMMIT;
-- ROLLBACK;
```

After you commit, rerun the readiness query. The expected result should be:

```text
total_archived_scenario_slices          = 19
total_archived_rows                     = 950000
scenario_slices_not_50000_rows          = 0
unexpected_scenario_slice_count         = 0
missing_expected_scenario_slice_count   = 0
module1_campaign_readiness_status       = MODULE_1_CAMPAIGN_READY_FOR_MODULE_2
```

Also check whether you are still inside an open transaction from a prior cleanup attempt. If yes, either finish that transaction first with `COMMIT;` or `ROLLBACK;` before starting this block.
<!-- END_MESSAGE C038-M01213 -->


---

<a id="c038-m01214"></a>

### C038-M01214

**Andrew** · 2026-05-10T15:44:37.867000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01214 -->
i ran your targeted cleanup earlier.  why would i still show this?
<!-- END_MESSAGE C038-M01214 -->


---

<a id="c038-m01217"></a>

### C038-M01217

**Andrew** · 2026-05-10T15:46:26.419000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01217 -->
oh...because i didn't say commit
<!-- END_MESSAGE C038-M01217 -->


---

<a id="c038-m01221"></a>

### C038-M01221

**ChatGPT** · 2026-05-10T15:47:36.194127-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01221 -->
Exactly. That explains it.

Because the cleanup block used:

```sql
BEGIN;
```

the `DELETE` stayed inside an open transaction until you explicitly ran:

```sql
COMMIT;
```

If `COMMIT;` stayed commented out, then one of two things happened:

1. The rows were deleted only inside that open transaction, but not persisted.
2. The transaction was later rolled back automatically or manually, so the rows came back.

Run this now first:

```sql
COMMIT;
```

Then rerun the readiness check. If the prior delete transaction is still open in that same connection, this should finalize it.

If the rows still show after that, the prior transaction was already gone or rolled back. In that case, rerun the targeted delete with `COMMIT;` explicitly included:

```sql
BEGIN;

WITH deleted_rows AS (
    DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
    WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
      AND population_id = 'BASE_POPULATION_V1'
      AND scenario_name IN (
            'BROAD_LGD_STRESS',
            'SECURED_SEVERITY_STRESS',
            'UNSECURED_SEVERITY_STRESS'
      )
    RETURNING
        scenario_set_name,
        scenario_name,
        population_id
)
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS deleted_row_count
FROM deleted_rows
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;

COMMIT;
```

Then verify:

```sql
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS remaining_row_count
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_name,
    population_id;
```

Expected remaining SC05 rows:

```text
EXPOSURE_BASELINE_REFERENCE          50,000
HIGH_BALANCE_APPETITE               50,000
LOW_BALANCE_CONSERVATIVE_REQUESTS   50,000
```

Then rerun the readiness query. Expected:

```text
total_archived_scenario_slices          = 19
total_archived_rows                     = 950,000
scenario_slices_not_50000_rows          = 0
unexpected_scenario_slice_count         = 0
missing_expected_scenario_slice_count   = 0
module1_campaign_readiness_status       = MODULE_1_CAMPAIGN_READY_FOR_MODULE_2
```

Small operational rule going forward: whenever we use `BEGIN;` for cleanup, the script must end with either a real `COMMIT;` or a real `ROLLBACK;` — not a commented one.
<!-- END_MESSAGE C038-M01221 -->


---

<a id="c038-m01222"></a>

### C038-M01222

**Andrew** · 2026-05-10T15:53:08.555000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01222 -->
ok, now that we've locked down module 1 campaign.  please re-post the module 2 campaign parameter run guide tables so I do not have to scroll up to get them.  thanks.
<!-- END_MESSAGE C038-M01222 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_63.md) · [Next](Part_65.md)
