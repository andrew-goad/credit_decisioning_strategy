# Campaign QA and strategy expansion

## Part 05

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_04.md) · [Next](Part_06.md)

<a id="c040-m02211"></a>

### C040-M02211

**ChatGPT** · 2026-05-21T10:42:39.357889-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02211 -->
## Section 15 final-campaign QA review verdict

```text
Section 15 final-campaign QA status: PASS
Final campaign archive frontier status: READY
Archived campaign slices: 39
Archived campaign rows: 1,950,000
Registry linkage: PASS
Baseline-reference availability: PASS
Frontier executive summary: PASS
Option C frontier evidence: PASS
Blockers: none
Required changes before Section 16.9: none
```

This is a clean final-campaign Section 15 rerun. Section 15 is doing its intended job: summarizing the completed campaign archive into an archive-wide strategy frontier, not deciding which strategy is “best.” Direct matched row-level comparison remains Section 13, and Section 16.9 uses the fresh Section 15 frontier output to synchronize persistent executive evidence before Section 17. fileciteturn20file3

---

# 1. Section 15.0 — Frontier scope and archive readiness

```text
Status: PASS
```

The campaign archive is complete at the expected scale:

```text
archived_rows = 1,950,000
archived_strategy_scenario_slice_count = 39
rows per slice = 50,000
distinct_archived_application_ids = 50,000
module1_scenario_population_slice_count = 19
module2_strategy_version_count = 8

frontier_scope_status =
FRONTIER_READY_FOR_MULTI_STRATEGY_REVIEW
```

This is exactly right:

```text
39 active campaign runs × 50,000 applications = 1,950,000 archived rows
```

No issue.

Minor optional polish: the interpretation note still references “single archived-slice frontier outputs.” That was useful during M2-01, but for the final-campaign export a better note would be:

```text
Completed campaign frontier outputs are valid for multi-strategy review; baseline-reference rows remain anchors, and rank / quadrant fields are comparative within each Module 1 scenario / population frontier group.
```

This is wording only. It is not a blocker.

---

# 2. Section 15.0A.2 — Campaign registry map

```text
Status: PASS
```

The campaign registry map is clean:

```text
registry rows = 39
registry_active_flag = true for all 39
registry_match_count = 1 for all 39
frontier_registry_match_status = FRONTIER_REGISTRY_MATCHED for all 39
```

This confirms every active run is registry-linked.

No issue.

---

# 3. Section 15.1A — Archive frontier inventory

```text
Status: PASS
```

Every active campaign slice exists in the archive:

```text
archive frontier rows = 39
archived_row_count min = 50,000
archived_row_count max = 50,000
distinct_application_id_count = 50,000 for every slice
duplicate_application_row_count sum = 0
```

Scenario coverage is coherent:

```text
BASELINE_V2                          8 runs
NEAR_PRIME_EXPANSION_MIX             4 runs
HIGH_BALANCE_APPETITE                3 runs
Several 2-run comparison scenarios      2 runs each
Reference-only scenarios                1 run each
```

This is the expected 39-run formal campaign structure.

No issue.

---

# 4. Section 15.2A — Core strategy frontier summary

```text
Status: PASS
```

The core frontier summary has:

```text
frontier rows = 39
applications per row = 50,000
```

Option C posture is correctly distributed:

```text
NOT_COUNTEROFFER_SPLIT_STRATEGY = 33 rows
SELECTIVE_FEASIBILITY = 3 rows
AGGRESSIVE_EXPANSION = 3 rows

aggressive_counteroffer_expansion_enabled = true for 3 rows
aggressive_counteroffer_expansion_enabled = false for 36 rows
```

The Expected Loss metric naming refinements are present and clean:

```text
approved_expected_loss_capture_rate
approved_el_per_approved_dollar
approved_expected_loss_rate as backward-compatible alias
```

No issue.

---

# 5. Section 15.3A — Baseline-relative frontier deltas

```text
Status: PASS
```

Baseline reference availability is clean:

```text
baseline_available_flag = true for all 39 rows
rows_without_baseline_reference = 0
```

This is a major final-campaign pass condition. It means every frontier row can be interpreted relative to its relevant same-scenario baseline where applicable.

No issue.

---

# 6. Section 15.4A — Strategy efficiency metrics

```text
Status: PASS
```

Efficiency metrics are available for all rows:

```text
frontier_efficiency_metric_status =
FRONTIER_EFFICIENCY_METRICS_AVAILABLE

count = 39
```

The refined fields are present:

```text
frontier_approved_expected_loss_capture_rate
frontier_approved_el_per_approved_dollar
frontier_approved_expected_loss_rate
offer_rate_per_approved_el_per_approved_dollar_unit
applications_per_million_approved_expected_loss
```

No issue.

---

# 7. Section 15.5A — Strategy frontier classification

```text
Status: PASS
```

Classification distribution is coherent:

```text
BASELINE_REFERENCE_POINT                  19
BALANCED_OR_MIXED_FRONTIER_POINT          11
GROWTH_ORIENTED_FRONTIER_POINT             3
RISK_DISCIPLINE_FRONTIER_POINT             3
COUNTEROFFER_MANAGEMENT_FRONTIER_POINT     2
REVIEW_BURDEN_REDUCTION_FRONTIER_POINT     1
```

Option C posture classification is also correct:

```text
OPTION_C_NOT_APPLICABLE_FRONTIER_POINT                33
SELECTIVE_COUNTEROFFER_FEASIBILITY_FRONTIER_POINT      3
AGGRESSIVE_COUNTEROFFER_EXPANSION_FRONTIER_POINT       3
```

This is analytically coherent. The final campaign contains many baseline/reference rows because several Module 1 scenario families intentionally include baseline-only sensitivity slices. The challenger rows are classified into interpretable frontier positions.

No issue.

---

# 8. Section 15.6A — Segment-level frontier highlights

```text
Status: PASS
```

The exported 15.6A file contains 300 rows, but that is expected because the query uses a review-ergonomics export limit. The full temporary object is complete, as confirmed by 15.8A:

```text
tmp_m2_strategy_frontier_segment_highlights = 1,365 rows
```

That reconciles exactly:

```text
39 frontier rows × 35 segment rows = 1,365
```

The 35 segment rows per frontier point are:

```text
5 product rows
5 score-band rows
25 product × score rows
```

No issue. The limited 15.6A export is suitable as a highlight view, while 15.8A proves the complete temp object was built.

---

# 9. Section 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
```

This is the primary Section 15 output, and it is clean:

```text
executive frontier rows = 39
registry matched rows = 39
```

Key SC01 baseline-strategy frontier examples are directionally correct:

```text
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
    lower offer exposure
    lower approved Expected Loss
    lower approved EL per approved dollar
    higher decline rate

M2-03 GROWTH_ORIENTED_STRATEGY
    higher offer exposure
    higher approved amount
    higher approved Expected Loss

M2-04 TIGHTER_AFFORDABILITY_STRATEGY
    lower offer exposure
    lower approved amount
    lower total approved Expected Loss
    mixed efficiency profile

M2-05 SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY
    lower access
    lower approved Expected Loss
    no aggressive override rows

M2-37 AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY
    higher access than baseline
    aggressive override path evidence present
```

The Option C aggressive expansion frontier rows are especially important and look coherent:

```text
M2-37 — BASELINE_V2
    aggressive_override_rows = 4,614
    final aggressive override counteroffers = 4,067
    final aggressive override manual reviews = 547
    final aggressive override declines = 0

M2-38 — NEAR_PRIME_EXPANSION_MIX
    aggressive_override_rows = 4,380
    final aggressive override counteroffers = 3,699
    final aggressive override manual reviews = 681
    final aggressive override declines = 0

M2-39 — HIGH_BALANCE_APPETITE
    aggressive_override_rows = 8,892
    final aggressive override counteroffers = 7,081
    final aggressive override manual reviews = 1,811
    final aggressive override declines = 0
```

This proves the aggressive expansion rows are not just flagged; they are flowing into interpretable final outcomes and approved-exposure economics.

No issue.

Optional wording polish: same as 15.0, the `interpretation_note` still references single archived-slice behavior. For the final campaign, the note could be made more direct:

```text
Executive frontier rows are archive-backed and campaign-complete. Baseline-reference rows are anchors; rank, delta, and quadrant fields are comparative within each Module 1 scenario / population frontier group.
```

Not required before Section 16.9.

---

# 10. Section 15.8A — Frontier object row-count diagnostic

```text
Status: PASS
```

All temporary frontier objects are populated:

```text
tmp_m2_strategy_frontier_campaign_registry_map       39
tmp_m2_strategy_frontier_inventory                   39
tmp_m2_strategy_frontier_summary                     39
tmp_m2_strategy_frontier_baseline_deltas             39
tmp_m2_strategy_frontier_efficiency                  39
tmp_m2_strategy_frontier_classification              39
tmp_m2_strategy_frontier_segment_highlights       1,365
tmp_m2_strategy_frontier_executive_summary           39
```

This is a strong internal Section 15 completeness check.

No issue.

---

# 11. Section 15.8B — Frontier baseline availability

```text
Status: PASS
```

Baseline availability is clean across all 19 comparable Module 1 scenario / population frontier groups:

```text
frontier groups = 19
baseline_reference_status =
BASELINE_REFERENCES_AVAILABLE_FOR_ALL_FRONTIER_ROWS
```

No issue.

---

# 12. Section 15.8C — Frontier reason-code storytelling

```text
Status: PASS
```

The reason-code storytelling diagnostic has:

```text
rows = 39
frontier_registry_match_status = FRONTIER_REGISTRY_MATCHED for all rows
```

The reason-code delta drivers are coherent. Examples:

```text
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
    top delta driver = POLICY_STOP_SEVERE_SYNTHETIC_RISK

M2-03 GROWTH_ORIENTED_STRATEGY
    top delta driver = APPROVED_AS_REQUESTED

M2-05 / M2-06 / product-guardrail and selective-counteroffer runs
    top delta driver frequently = MANUAL_REVIEW_SEVERE_REQUESTED_STRUCTURE

M2-37 / M2-38 aggressive expansion
    top delta driver = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
```

This is exactly the kind of executive reason-code story Section 15 is meant to preserve.

No issue.

---

# 13. Section 15.8D — Frontier registry linkage

```text
Status: PASS
```

Registry linkage is fully clean:

```text
executive_frontier_rows = 39
registry_matched_rows = 39
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0

registry_linkage_status =
FRONTIER_REGISTRY_LINKAGE_READY
```

No issue.

---

# 14. Section 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS
```

The diagnostic now returns six meaningful Option C rows:

```text
3 SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY rows
3 AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY rows
```

Selective posture is correct:

```text
SELECTIVE_FEASIBILITY rows:
    aggressive_override_rows = 0
    aggressive override final outcome rows = 0
    option_c_frontier_posture_type =
        SELECTIVE_COUNTEROFFER_FEASIBILITY_FRONTIER_POINT
```

Aggressive posture is correct:

```text
AGGRESSIVE_EXPANSION rows:
    aggressive_override_rows > 0
    aggressive_override_final_counteroffer_rows > 0
    aggressive_override_final_manual_review_rows > 0
    aggressive_override_final_decline_rows = 0
    option_c_frontier_posture_type =
        AGGRESSIVE_COUNTEROFFER_EXPANSION_FRONTIER_POINT
```

Specific aggressive override evidence:

```text
BASELINE_V2:
    aggressive_override_rows = 4,614
    final counteroffer rows = 4,067
    final manual review rows = 547
    avg aggressive override counteroffer exposure reduction pct = 0.413155
    avg aggressive override approved PTI = 0.060490
    avg aggressive override approved EL = 948.59

NEAR_PRIME_EXPANSION_MIX:
    aggressive_override_rows = 4,380
    final counteroffer rows = 3,699
    final manual review rows = 681
    avg aggressive override counteroffer exposure reduction pct = 0.420658
    avg aggressive override approved PTI = 0.062290
    avg aggressive override approved EL = 1,173.83

HIGH_BALANCE_APPETITE:
    aggressive_override_rows = 8,892
    final counteroffer rows = 7,081
    final manual review rows = 1,811
    avg aggressive override counteroffer exposure reduction pct = 0.475047
    avg aggressive override approved PTI = 0.070501
    avg aggressive override approved EL = 993.59
```

This is the major final-campaign Option C frontier proof point. It shows the intended strategic split:

```text
Selective feasibility preserves review-oriented posture with no aggressive override rows.
Aggressive expansion routes additional requested-structure cases into governed feasibility testing.
```

No issue.

---

# Final Section 15 campaign signoff

```text
Final campaign Section 15 QA: ACCEPTED

Archive scope is complete.
39 active campaign frontier rows are present.
1,950,000 archived rows are represented.
Every archived frontier slice has 50,000 rows.
No archive-grain duplicate issue is visible.
Campaign registry linkage is complete.
Baseline references are available for all frontier rows.
Frontier object row counts are complete.
Executive frontier summary is complete.
Reason-code storytelling fields are available.
Option C selective/aggressive frontier evidence is present and interpretable.
No blocker found.
```

## Only optional polish

The only thing I would consider is replacing the generic “single archived-slice” interpretation note in:

```text
15.0
15.7A
```

with final-campaign wording. This is not required for Section 16.9 or Section 17. The outputs themselves are valid.

Recommended final-campaign wording:

```text
Completed campaign frontier outputs are archive-backed and ready for multi-strategy review. Baseline-reference rows are anchors; rank, delta, and quadrant fields are comparative within each Module 1 scenario / population frontier group.
```

## Proceed to Section 16.9

Section 15 is ready for Section 16.9. The workflow is exactly the intended final-campaign sequence:

```text
all runs through Section 16.8
→ rerun Section 15 from completed archive
→ run Section 16.9
→ run Section 17
```

Section 17 is designed to evaluate the final synchronized evidence layer after Section 16.9 refreshes persistent executive evidence from the fresh Section 15 frontier output. fileciteturn20file7
<!-- END_MESSAGE C040-M02211 -->


---

<a id="c040-m02212"></a>

### C040-M02212

**Andrew** · 2026-05-21T10:56:16.065000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02212 -->
thanks.  please review section 16.9 to 17.9 QA
<!-- END_MESSAGE C040-M02212 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.9_QA_active_campaign_archive_final_output_convention_checks_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.8_QA_section_16_evidence_coverage_detail_by_run_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.7_QA_section_16_evidence_coverage_summary_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.6_QA_archive_slices_without_active_campaign_registry_row_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.5_QA_registry_runs_missing_or_mismatched_in_archive_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.4_QA_campaign_registry_to_archive_reconciliation_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.3_QA_module_2_archive_grain_duplicate_check_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.2_QA_module_2_archive_slice_detail_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.1_QA_module_2_archive_campaign_inventory_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.9G.5_QA_option_c_frontier_synchronization_review_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.9G.4_QA_matched_evidence_rows_after_synchronization_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.9G.3_QA_unmatched_persistent_evidence_rows_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.9G.2_QA_rows_updated_by_synchonization_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.9G.1_QA_synchronization_status_summary_campaign.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02218"></a>

### C040-M02218

**ChatGPT** · 2026-05-21T11:09:03.474548-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02218 -->
## Section 16.9 through 17.9 campaign QA review verdict

```text
Section 16.9–17.9 campaign QA status: PASS
Post-campaign frontier synchronization: PASS
Archive campaign inventory: PASS
Archive slice detail: PASS
Archive grain: PASS
Registry-to-archive reconciliation: PASS
Section 16 evidence coverage: PASS
Final output convention checks: PASS
Option C archive/evidence posture: PASS
Blockers: none
Required changes before continuing Section 17 review: none
```

This batch is clean. Section 16.9 successfully confirms that persistent executive evidence now matches the fresh Section 15 campaign frontier output, and Section 17.1–17.9 confirms the active campaign archive, registry coverage, evidence coverage, and output conventions are structurally ready for final acceptance review. Section 16.9 is specifically intended to refresh Section 15-derived frontier fields in persistent evidence after the full archive is complete, and Section 17 is the final read-only post-campaign acceptance layer. fileciteturn21file21 fileciteturn21file18

---

# Section 16.9 — Post-campaign frontier evidence synchronization

## 16.9G.1 — Synchronization status summary

```text
Status: PASS
```

The synchronization post-check is clean:

```text
evidence_rows_after_sync = 39
matched_evidence_rows_after_sync = 39
unmatched_evidence_rows_after_sync = 0

matched_rows_with_standard_frontier_mismatch_after_sync = 0
matched_rows_with_option_c_frontier_mismatch_after_sync = 0
matched_rows_with_frontier_mismatch_after_sync = 0
total_matched_frontier_field_mismatches_after_sync = 0
```

Final status:

```text
FRONTIER_EVIDENCE_SYNC_READY_ALL_EVIDENCE_ROWS_MATCH_SECTION_15
```

The interpretation is exactly what we want:

```text
All persistent executive evidence rows match the fresh Section 15 frontier output,
including Option C selective/aggressive counteroffer frontier fields.
```

The fact that:

```text
evidence_rows_updated = 0
```

is **not a problem**. It means the persistent evidence rows already matched the fresh Section 15 frontier state when the synchronization ran. The decisive check is the post-sync mismatch count, and it is zero.

---

## 16.9G.2 — Rows updated by synchronization

```text
Status: PASS / expected empty
```

The output is empty:

```text
rows updated = 0
```

That is acceptable because 16.9G.1 confirms that all 39 persistent evidence rows already matched Section 15 after synchronization.

No issue.

---

## 16.9G.3 — Unmatched persistent evidence rows

```text
Status: PASS / expected empty
```

The output is empty:

```text
unmatched persistent evidence rows = 0
```

This confirms every active campaign evidence row found its matching Section 15 frontier row.

No issue.

---

## 16.9G.4 — Matched evidence rows after synchronization

```text
Status: PASS
Rows: 39
```

The matched evidence table now contains all active campaign runs:

```text
matched evidence rows = 39
```

The frontier-position distribution is coherent:

```text
BASELINE_REFERENCE_POINT                  19
BALANCED_OR_MIXED_FRONTIER_POINT          11
RISK_DISCIPLINE_FRONTIER_POINT             3
GROWTH_ORIENTED_FRONTIER_POINT             3
COUNTEROFFER_MANAGEMENT_FRONTIER_POINT     2
REVIEW_BURDEN_REDUCTION_FRONTIER_POINT     1
```

Option C posture distribution is correct:

```text
OPTION_C_NOT_APPLICABLE_FRONTIER_POINT                33
SELECTIVE_COUNTEROFFER_FEASIBILITY_FRONTIER_POINT      3
AGGRESSIVE_COUNTEROFFER_EXPANSION_FRONTIER_POINT       3
```

Aggressive expansion evidence is preserved:

```text
M2-37:
    aggressive_override_rows = 4,614
    final counteroffer rows = 4,067
    final manual review rows = 547
    final decline rows = 0

M2-38:
    aggressive_override_rows = 4,380
    final counteroffer rows = 3,699
    final manual review rows = 681
    final decline rows = 0

M2-39:
    aggressive_override_rows = 8,892
    final counteroffer rows = 7,081
    final manual review rows = 1,811
    final decline rows = 0
```

No issue.

---

## 16.9G.5 — Option C frontier synchronization review

```text
Status: PASS
Rows: 6
```

This is the key Option C synchronization proof.

Selective rows are correct:

```text
M2-05 — SELECTIVE_FEASIBILITY
M2-18 — SELECTIVE_FEASIBILITY
M2-29 — SELECTIVE_FEASIBILITY

aggressive_override_rows = 0 for all three
```

Aggressive expansion rows are correct:

```text
M2-37 — AGGRESSIVE_EXPANSION
    aggressive_override_rows = 4,614
    final counteroffer rows = 4,067
    final manual review rows = 547

M2-38 — AGGRESSIVE_EXPANSION
    aggressive_override_rows = 4,380
    final counteroffer rows = 3,699
    final manual review rows = 681

M2-39 — AGGRESSIVE_EXPANSION
    aggressive_override_rows = 8,892
    final counteroffer rows = 7,081
    final manual review rows = 1,811
```

All aggressive expansion rows have:

```text
aggressive_override_final_decline_rows = 0
```

That is coherent with the current governed feasibility / failed-counteroffer handling. No issue.

---

# Section 17.1–17.6 — Archive and registry acceptance checks

## 17.1 — Module 2 archive campaign inventory

```text
Status: PASS
```

The campaign archive inventory is complete:

```text
active_campaign_registry_rows = 39
distinct_module1_source_slices = 19
module1_source_count_missing_runs = 0
expected_total_active_campaign_source_rows = 1,950,000
registry_runs_with_archive_rows = 39
registry_runs_missing_archive_rows = 0
total_active_campaign_archived_rows = 1,950,000
registry_runs_with_archive_row_count_mismatch = 0
registry_runs_with_duplicate_or_missing_application_ids = 0
```

Final status:

```text
MODULE_2_ARCHIVE_INVENTORY_READY
```

Option C archive-level totals are also coherent:

```text
selective_feasibility_archived_slice_count = 3
aggressive_expansion_archived_slice_count = 3
ordinary_counteroffer_candidate_archived_row_count = 782,698
aggressive_override_archived_row_count = 17,886
aggressive_override_final_counteroffer_archived_row_count = 14,847
aggressive_override_final_manual_review_archived_row_count = 3,039
aggressive_override_final_decline_archived_row_count = 0
```

This is a strong archive-completion result. Section 17.1 is designed to compare active registry runs to expected Module 1 source counts and archived Module 2 slice counts dynamically, rather than using hardcoded row expectations. fileciteturn21file17

---

## 17.2 — Module 2 archive slice detail

```text
Status: PASS
Rows: 39
```

All 39 active campaign runs show:

```text
expected_module1_source_rows = 50,000
expected_module1_distinct_application_id_count = 50,000
archived_rows = 50,000
distinct_application_id_count = 50,000
archived_row_count_gap = 0
application_id_count_gap = 0
archive_slice_detail_status = ARCHIVE_SLICE_READY
```

The aggressive expansion rows remain correctly visible:

```text
M2-37 aggressive_override_rows = 4,614
M2-38 aggressive_override_rows = 4,380
M2-39 aggressive_override_rows = 8,892
```

No issue.

---

## 17.3 — Archive grain duplicate check

```text
Status: PASS
```

```text
duplicate_archive_grain_count = 0
archive_grain_status = ARCHIVE_GRAIN_READY
```

The archive is unique at the intended grain.

No issue.

---

## 17.4 — Campaign registry to archive reconciliation

```text
Status: PASS
```

The reconciliation is clean:

```text
registry_run_count = 39
registry_runs_missing_module1_source_count = 0
registry_runs_with_archive_rows = 39
registry_runs_missing_archive_rows = 0
registry_runs_with_archive_row_count_mismatch = 0
registry_runs_with_duplicate_or_missing_application_ids = 0
```

Final status:

```text
CAMPAIGN_REGISTRY_RECONCILES_TO_ARCHIVE
```

No issue.

---

## 17.5 — Registry runs missing or mismatched in archive

```text
Status: PASS / expected empty
```

The output is empty, which is correct.

No active registry run is missing from archive, and no run has an archive row-count or distinct-application mismatch.

No issue.

---

## 17.6 — Archive slices without active campaign registry row

```text
Status: PASS / expected empty
```

The output is empty, which is correct.

There are no archived campaign slices outside the active campaign registry scope.

No issue.

---

# Section 17.7–17.8 — Evidence coverage checks

## 17.7 — Section 16 evidence coverage summary

```text
Status: PASS
```

Evidence coverage is complete:

```text
registry_run_count = 39
expected_validation_key_count = 22

runs_with_one_executive_evidence_row = 39
runs_with_missing_or_duplicate_executive_evidence_rows = 0

runs_with_complete_option_c_executive_evidence = 39
runs_with_option_c_executive_evidence_gaps = 0
total_option_c_executive_evidence_gap_rows = 0

runs_with_one_parameter_snapshot_row = 39
runs_with_missing_or_duplicate_parameter_snapshot_rows = 0

runs_with_complete_validation_evidence_rows = 39
runs_with_incomplete_validation_evidence_rows = 0
min_validation_rows_per_run = 22
max_validation_rows_per_run = 22

runs_with_complete_segment_evidence_rows = 39
runs_with_incomplete_segment_evidence_rows = 0
min_expected_segment_rows_per_run = 25
max_expected_segment_rows_per_run = 25
min_actual_segment_rows_per_run = 25
max_actual_segment_rows_per_run = 25

evidence_coverage_issue_count = 0
```

Final status:

```text
SECTION_16_EVIDENCE_COVERAGE_READY
```

This is a major final-campaign pass. Section 17.7 is specifically designed to confirm evidence exists for every active campaign run across executive evidence, validation evidence, parameter snapshots, and product × score segment evidence. fileciteturn21file16

---

## 17.8 — Section 16 evidence coverage detail by run

```text
Status: PASS
Rows: 39
```

Every run shows:

```text
executive_rows = 1
parameter_rows = 1
validation_rows = 22
expected_validation_key_count = 22
validation_evidence_row_gap = 0
duplicate_validation_key_rows = 0

expected_segment_rows = 25
segment_rows = 25
segment_evidence_row_gap = 0
duplicate_segment_key_rows = 0

option_c_executive_evidence_gap_rows = 0
evidence_capture_status = EVIDENCE_CAPTURE_READY
```

All 39 rows have:

```text
EVIDENCE_CAPTURE_READY
```

Option C evidence is complete for all runs, including:

```text
33 non-Option-C rows
3 selective feasibility rows
3 aggressive expansion rows
```

No issue.

---

# Section 17.9 — Final output convention checks

## 17.9 — Active campaign archive final output convention checks

```text
Status: PASS
```

The final-output convention check is completely clean:

```text
active_campaign_archived_rows = 1,950,000

final_outcome_flag_count_violation_rows = 0
simulated_offer_exposure_flag_violation_rows = 0

approve_amount_violation_rows = 0
counteroffer_amount_violation_rows = 0
manual_review_amount_violation_rows = 0
decline_amount_violation_rows = 0

approve_payment_violation_rows = 0
counteroffer_affordability_violation_rows = 0
manual_review_affordability_violation_rows = 0
decline_affordability_violation_rows = 0

approve_expected_loss_violation_rows = 0
counteroffer_expected_loss_violation_rows = 0
manual_review_expected_loss_violation_rows = 0
decline_expected_loss_violation_rows = 0

option_c_archive_field_gap_rows = 0
aggressive_override_reason_trace_gap_rows = 0
selective_strategy_aggressive_override_rows = 0

reason_code_completeness_violation_rows = 0
reason_family_alignment_violation_rows = 0

critical_convention_violation_count = 0
```

Final status:

```text
ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY
```

This confirms the locked conventions across all 1.95 million archived active-campaign rows:

```text
APPROVE preserves requested exposure / PTI / Expected Loss.
COUNTEROFFER uses feasible reduced exposure.
MANUAL_REVIEW remains unresolved.
DECLINE uses zero-exposure convention.
Reason-code payloads are complete and family-aligned.
Option C fields persist cleanly.
Aggressive override reason traces are present where needed.
Selective strategy rows do not leak aggressive override rows.
```

No issue.

---

# Final signoff for this batch

```text
Section 16.9 through 17.9 QA: ACCEPTED

Post-campaign synchronization completed.
All 39 persistent evidence rows match fresh Section 15 frontier fields.
No unmatched evidence rows.
No remaining frontier mismatch rows.
Archive inventory complete.
Archive grain clean.
Registry-to-archive reconciliation clean.
No orphan active-campaign archive slices.
Evidence coverage complete for all 39 active runs.
Validation evidence complete for all 39 active runs.
Segment evidence complete for all 39 active runs.
Parameter snapshots present for all 39 active runs.
Option C executive evidence complete.
Final-output conventions clean across 1,950,000 archived rows.
No blocker found.
```

You can proceed to the next Section 17 batch.
<!-- END_MESSAGE C040-M02218 -->


---

<a id="c040-m02219"></a>

### C040-M02219

**Andrew** · 2026-05-21T11:10:34.963000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02219 -->
thanks.  please review remaining section 17 QA.
<!-- END_MESSAGE C040-M02219 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.18_QA_parameter_snapshot_profile_audit_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.17_QA_option_c_counteroffer_strategy_split_effect_check_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.16_QA_product_guardrail_strategy_effect_check_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.15_QA_baseline_x_challenger_delta_summary_for_active_comparison_groups_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.14_QA_executive_evidence_campaign_summary_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.13_QA_active_comparison_matched_source_field_consistency_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.12_QA_active_comparison_registry_readiness_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.11_QA_validation_review_not_applicable_concentration_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.10_QA_validation_status_summary_by_active_campaign_run_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.20_QA_final_module_2_campaign_acceptance_rollup_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.19_QA_product_guardrail_policy_snapshot_exact_value_audit_campaign.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02238"></a>

### C040-M02238

**ChatGPT** · 2026-05-21T11:29:00.577512-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02238 -->
## Remaining Section 17 QA review verdict

```text
Section 17.10–17.19 status: PASS
Section 17.20 status: REVIEW / QUERY-LOGIC FALSE POSITIVE
Underlying campaign evidence status: ACCEPTED
Final rollup status: not yet accepted until 17.20 convention rollup is patched and rerun
True data blocker: none found
SQL rollup blocker: yes — Section 17.20 convention-count logic is stale / misaligned with 17.9
```

Section 17 is the final read-only post-campaign acceptance layer and is intended to run after all planned runs have completed through 16.8, Section 15 has been rerun from the completed archive, and Section 16.9 has synchronized fresh frontier evidence into persistent executive evidence. The Section 17 map explicitly includes the checks reviewed here: validation summary, comparison readiness, source consistency, executive evidence, baseline/challenger deltas, product guardrails, Option C, parameter snapshots, product-policy audit, and final acceptance rollup. fileciteturn22file0

The important conclusion: **the campaign looks structurally clean through 17.19. The only remaining issue is that 17.20 is currently producing a false review status because its internal final-output convention aggregation does not match the already-passing 17.9 convention logic.**

---

# 17.10 — Validation status summary by active campaign run

```text
Status: PASS
Rows: 39
```

Every active campaign run has complete validation evidence:

```text
validation_rows = 22 for all 39 runs
expected_validation_key_count = 22 for all 39 runs
validation_evidence_row_gap = 0 for all 39 runs
validation_unexpected_status_count = 0 for all 39 runs
validation_evidence_status = VALIDATION_EVIDENCE_COMPLETE for all 39 runs
```

Validation status mix:

```text
validation_review_count:
    1 review item  = 24 runs
    2 review items = 14 runs
    3 review items = 1 run

validation_not_applicable_count:
    1 to 5 per run, depending on comparison / Option C applicability
```

This is acceptable. `REVIEW` and `NOT_APPLICABLE` rows are interpretation rows, not automatic failure rows.

---

# 17.11 — Validation REVIEW / NOT_APPLICABLE concentration

```text
Status: PASS
Rows: 8
```

The concentration output is coherent.

The three `REVIEW` themes are:

```text
EDGE_CASE_VISIBILITY
    impacted runs = 39

MATCHED_COMPARISON_READINESS
    impacted runs = 9

DECISION_DISTRIBUTION
    impacted runs = 7
```

These are expected interpretation categories. They do not invalidate the campaign.

The `MATCHED_COMPARISON_READINESS` rows should be read carefully: some per-run validation evidence was captured before a challenger comparison existed, or for reference-only runs where no active comparison was selected during that individual run. That does **not** mean the final campaign comparison registry is incomplete, because 17.12 and 17.13 confirm the final active comparison layer is ready and source-consistent.

The `NOT_APPLICABLE` themes are also appropriate:

```text
Option C matched comparison context
Option C aggressive override reason-code traceability
Option C latest-run aggressive override behavior
Matched source consistency where individual run context did not have a ready comparison
Matched comparison readiness where Section 13 was skipped / not applicable
```

No issue.

---

# 17.12 — Active comparison registry readiness

```text
Status: PASS
Rows: 20
```

All active comparison groups are ready:

```text
comparison_group_count = 20
readiness_status = READY_FOR_MATCHED_COMPARISON for all 20
matched_application_id_count = 50,000 for all 20
baseline_only_application_id_count = 0 for all 20
challenger_only_application_id_count = 0 for all 20
same_strategy_selected_flag = false for all 20
```

This is a major campaign-level pass. Every formal comparison group is ready for matched interpretation.

---

# 17.13 — Active comparison matched source-field consistency

```text
Status: PASS
Rows: 20
```

All source-field consistency checks pass:

```text
source_consistency_status = SOURCE_FIELDS_MATCH for all 20 comparison groups
source_field_mismatch_count = 0 for all 20 comparison groups
total source field mismatch rows = 0
```

All immutable Module 1 source fields match across baseline/challenger pairs:

```text
product type
score band
credit score
annual income
requested amount
requested payment
requested PTI
amount-to-income
synthetic estimated-PD proxy
LGD
requested Expected Loss
Module 1 lineage
```

This confirms the comparison layer is isolating Module 2 strategy movement rather than source-population drift.

---

# 17.14 — Executive evidence campaign summary

```text
Status: PASS
Rows: 39
```

Every active campaign run has a clean executive evidence row:

```text
executive_evidence_status = EXECUTIVE_EVIDENCE_READY for all 39
module3_growth_inputs_available_flag = true for all 39
```

The Module 3 readiness note is consistent across runs:

```text
Core Module 3 readiness inputs are available:
    approved amount,
    APR proxy,
    product,
    synthetic estimated-PD proxy,
    LGD,
    approved Expected Loss.

Future Module 3 design still needs:
    utilization,
    funding cost,
    fee income,
    revenue assumptions.
```

No issue.

One naming note: this export still carries `approved_expected_loss_rate` as a legacy-compatible field. That is acceptable because the refined evidence layer already distinguishes capture-rate and approved-EL density elsewhere. It is not a blocker.

---

# 17.15 — Baseline × challenger delta summary for active comparison groups

```text
Status: PASS
Rows: 20
```

All comparison deltas are ready and source-consistent:

```text
comparison_readiness_status = READY_FOR_MATCHED_COMPARISON for all 20
source_consistency_status = SOURCE_FIELDS_MATCH for all 20
```

Option C comparison-status distribution:

```text
OPTION_C_NOT_APPLICABLE_NON_COUNTEROFFER_SPLIT_STRATEGY = 14
OPTION_C_SELECTIVE_FEASIBILITY_PATH_READY = 3
OPTION_C_AGGRESSIVE_EXPANSION_PATH_EVIDENCE_PRESENT = 3
```

This is exactly the expected formal comparison mix:

```text
14 non-Option-C comparisons
3 selective counteroffer feasibility comparisons
3 aggressive counteroffer expansion comparisons
```

No issue.

---

# 17.16 — Product guardrail strategy effect check

```text
Status: PASS
Rows: 25
```

Product guardrail effect evidence is visible where expected:

```text
TARGET_PRODUCT_GUARDRAIL_EFFECT_VISIBLE = 10
NON_TARGET_PRODUCT_MONITORING_ROW = 15
```

This structure is correct:

```text
5 product-guardrail comparisons × 5 products = 25 rows
```

The ten target-product rows represent:

```text
5 product-guardrail runs × 2 audited target products
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE
```

The fifteen non-target product rows are monitoring rows, not failures.

No issue.

---

# 17.17 — Option C counteroffer strategy split effect check

```text
Status: PASS
Rows: 6
```

Option C evidence is clean:

```text
OPTION_C_SELECTIVE_FEASIBILITY_EFFECT_VISIBLE = 3
OPTION_C_AGGRESSIVE_EXPANSION_EFFECT_VISIBLE = 3
```

Selective feasibility rows:

```text
M2-05
M2-18
M2-29

aggressive_override_rows = 0
aggressive override final outcome rows = 0
```

Aggressive expansion rows:

```text
M2-37:
    aggressive_override_rows = 4,614
    aggressive_override_final_counteroffer_rows = 4,067
    aggressive_override_final_manual_review_rows = 547
    aggressive_override_final_decline_rows = 0

M2-38:
    aggressive_override_rows = 4,380
    aggressive_override_final_counteroffer_rows = 3,699
    aggressive_override_final_manual_review_rows = 681
    aggressive_override_final_decline_rows = 0

M2-39:
    aggressive_override_rows = 8,892
    aggressive_override_final_counteroffer_rows = 7,081
    aggressive_override_final_manual_review_rows = 1,811
    aggressive_override_final_decline_rows = 0
```

This is the final Option C proof point: selective feasibility has no aggressive override rows, while aggressive expansion produces governed aggressive override counteroffer/manual-review outcomes.

No issue.

---

# 17.18 — Parameter snapshot profile audit

```text
Status: PASS
Rows: 39
```

All active campaign runs have complete parameter snapshots:

```text
parameter_snapshot_status = PARAMETER_SNAPSHOT_READY for all 39
strategy_params_captured_flag = true for all 39
product_policy_params_captured_flag = true for all 39
run_story_params_captured_flag = true for all 39
parameter_snapshot_hash_captured_flag = true for all 39
option_c_strategy_controls_captured_flag = true for all 39
```

This confirms the campaign is parameter-traceable, including Option C strategy controls.

No issue.

---

# 17.19 — Product guardrail policy snapshot exact-value audit

```text
Status: PASS
Rows: 10
```

The product-guardrail exact-value audit is clean:

```text
product_guardrail campaign runs = 5
audited products per run = 2
total audit rows = 10
product_policy_field_mismatch_count sum = 0
product_guardrail_policy_value_status = PRODUCT_GUARDRAIL_POLICY_VALUES_MATCH for all 10
```

Audited products:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

Audited product-guardrail runs:

```text
M2-06
M2-23
M2-26
M2-34
M2-36
```

This closes the exact-value product-policy audit. Section 17.19 is specifically intended to confirm the active campaign product-guardrail strategy runs captured the intended canonical product-guardrail values for unsecured personal loans and revolving lines. fileciteturn21file11

No issue.

---

# 17.20 — Final campaign acceptance rollup

```text
Status: REVIEW / false-positive rollup issue
Underlying data blocker: none found
Required fix: align 17.20 final-output convention logic to 17.9
```

Current 17.20 output:

```text
module2_campaign_acceptance_status =
REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS

structural_acceptance_ready_flag = false

acceptance_review_focus =
REVIEW_FINAL_OUTPUT_CONVENTIONS

critical_convention_violation_count = 903,077

final_output_conventions_ready_flag = false
```

All other readiness flags are clean:

```text
campaign_registry_ready_flag = true
comparison_registry_ready_flag = true
archive_ready_flag = true
comparison_ready_flag = true
source_consistency_ready_flag = true
evidence_ready_flag = true
parameter_snapshot_ready_flag = true
option_c_evidence_ready_flag = true
product_guardrail_policy_ready_flag = true
```

This is **not** a true campaign-output blocker because 17.9 already passed with:

```text
critical_convention_violation_count = 0
ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY
```

The issue is that 17.20’s internal convention rollup logic is stale and does not match the already-passing 17.9 logic.

## Root cause

In 17.20, the convention rollup includes a stale no-offer payment rule that effectively treats non-null decline payment / PTI fields as a violation.

But the locked convention is:

```text
MANUAL_REVIEW = unresolved / NULL approved fields
DECLINE = zero-exposure / zero-payment / zero-PTI / zero-Expected-Loss convention
```

So decline rows with:

```text
approved_monthly_payment_proxy = 0
approved_payment_to_income_ratio = 0
```

are correct, not violations.

17.9 uses the right distinction:

```text
MANUAL_REVIEW approved fields should be NULL.
DECLINE approved fields should be zero.
```

17.20 should use the same convention logic as 17.9.

## Required correction

Patch 17.20 so its `convention_counts` / `convention_summary` logic mirrors 17.9’s convention definitions.

Specifically, 17.20 should not use a generic:

```text
no_offer_payment_violation_rows
```

for both manual review and decline.

It should use the separated convention checks:

```text
approve_payment_violation_rows
counteroffer_affordability_violation_rows
manual_review_affordability_violation_rows
decline_affordability_violation_rows
```

and the Section 17.9 Expected Loss checks:

```text
APPROVE preserves requested_expected_loss_amount
COUNTEROFFER has non-null, nonnegative approved EL,
    approved EL <= requested EL,
    approved EL <= product_approved_el_cap
MANUAL_REVIEW approved EL is NULL
DECLINE approved EL is zero
```

After that patch, the expected final 17.20 result is:

```text
module2_campaign_acceptance_status =
MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

structural_acceptance_ready_flag = true

acceptance_review_focus =
ALL_FINAL_ACCEPTANCE_GATES_PASSED

critical_convention_violation_count = 0

final_output_conventions_ready_flag = true
```

---

# Final review summary for remaining Section 17 outputs

```text
17.10 validation status summary: PASS
17.11 validation REVIEW / NOT_APPLICABLE concentration: PASS
17.12 comparison registry readiness: PASS
17.13 matched source-field consistency: PASS
17.14 executive evidence campaign summary: PASS
17.15 baseline × challenger delta summary: PASS
17.16 product guardrail strategy effect check: PASS
17.17 Option C counteroffer strategy split effect check: PASS
17.18 parameter snapshot profile audit: PASS
17.19 product guardrail policy exact-value audit: PASS
17.20 final acceptance rollup: NEEDS QUERY LOGIC PATCH
```

## Campaign-level conclusion

```text
The full campaign is structurally accepted through 17.19.

The final 17.20 rollup should not be saved as final yet because it contains a false-positive
convention-count issue.

No evidence suggests the archive, registry, comparison, source consistency, evidence capture,
parameter snapshot, Option C evidence, or product-guardrail audit failed.

The remaining task is to patch 17.20’s convention rollup to reuse the passing 17.9 convention logic,
rerun 17.20, and then save the final acceptance CSV.
```
<!-- END_MESSAGE C040-M02238 -->


---

<a id="c040-m02239"></a>

### C040-M02239

**Andrew** · 2026-05-21T14:44:36.058000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02239 -->
process to patch 17.20 and provide full copy paste for 17.20 updated section
<!-- END_MESSAGE C040-M02239 -->


---

<a id="c040-m02250"></a>

### C040-M02250

**ChatGPT** · 2026-05-21T15:03:17.365214-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02250 -->
According to the current Section 17 material, Section 17 is the final read-only post-campaign acceptance layer after all runs, Section 15 rerun, and Section 16.9 synchronization. Section 17.20 is specifically the one-row final campaign acceptance rollup, and the product-guardrail exact-value audit uses fixed canonical values for `UNSECURED_PERSONAL_LOAN` and `REVOLVING_LINE`. fileciteturn21file18 fileciteturn22file2 fileciteturn24file2

The patch is to replace **Section 17.20 only**. You do **not** need to rerun Sections 1–16.9 for this patch. After replacing this block, rerun Section 17.20, or rerun Section 17 from 17.1 if you want a clean full Section 17 output package.

The key fix is that `convention_counts` now mirrors the already-passing 17.9 convention logic:

```text
MANUAL_REVIEW = unresolved / NULL approved fields
DECLINE = zero-exposure / zero-payment / zero-PTI / zero-Expected-Loss convention
```

It no longer uses the stale combined `no_offer_payment_violation_rows` logic that incorrectly treated valid decline zero-payment rows as violations.

```sql
/***************************************************************************************************
SECTION 17.20 — FINAL MODULE 2 CAMPAIGN ACCEPTANCE ROLLUP
****************************************************************************************************

BUSINESS PURPOSE:
    Produce the final one-row campaign acceptance status after archive, registry, evidence,
    convention, comparison, matched-source, Option C, parameter-snapshot, and product-policy
    audit checks.

    Section 17.20 answers:

        "Is the completed Module 2 campaign evidence structurally ready for executive analysis,
         validation-summary drafting, README interpretation, and LinkedIn storyline development?"

SQL PURPOSE:
    Confirm final campaign acceptance across these gates:

        1. Campaign registry completeness.
        2. Comparison registry completeness.
        3. Archive inventory completeness.
        4. Archive row-level grain uniqueness.
        5. Comparison readiness.
        6. Matched source-field consistency.
        7. Executive evidence completeness.
        8. Parameter snapshot completeness.
        9. Validation evidence completeness.
        10. Segment evidence completeness.
        11. Full-archive final-output convention integrity.
        12. Option C selective/aggressive counteroffer split evidence readiness.
        13. Product-guardrail exact-value parameter snapshot audit.

WHY THIS PATCH EXISTS:
    Section 17.9 already validates final-output conventions using the locked Module 2 conventions:

        APPROVE:
            preserves requested exposure, requested payment / PTI, and requested Expected Loss.

        COUNTEROFFER:
            uses feasible reduced exposure, reduced / controlled approved PTI, and approved
            Expected Loss no greater than requested Expected Loss or the product approved-EL cap.

        MANUAL_REVIEW:
            remains unresolved with NULL approved amount, payment, PTI, and Expected Loss fields.

        DECLINE:
            uses the zero-exposure convention with approved amount, approved payment, approved PTI,
            and approved Expected Loss equal to zero.

    The prior 17.20 rollup used stale combined no-offer payment logic that treated valid DECLINE
    zero-payment / zero-PTI rows as violations.

    This replacement aligns 17.20 with the already-passing 17.9 convention definitions.

EXPECTED FINAL STATUS:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

ACCEPTANCE STATUS VALUES:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        Archive, registry, evidence, convention, comparison, source-consistency, Option C, and audited
        product-policy checks are clean.

    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        Structural, archive, evidence, convention, comparison, source-consistency, and Option C checks
        are clean, but the product-guardrail exact-value parameter audit requires review.

    REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        One or more structural, archive, registry, evidence, convention, comparison, source-field,
        Option C, validation, parameter, or product-policy checks require review before final
        interpretation.

READ-ONLY BOUNDARY:
    Section 17.20 does not insert archive rows.
    Section 17.20 does not delete archive rows.
    Section 17.20 does not update archive rows.
    Section 17.20 does not modify latest-run rows.
    Section 17.20 does not modify evidence rows.
    Section 17.20 does not modify campaign registry rows.
    Section 17.20 does not modify comparison registry rows.
    Section 17.20 does not modify strategy parameter rows.
    Section 17.20 does not modify product-policy parameter rows.
    Section 17.20 does not recalculate decisions, approved exposure, approved Expected Loss, or
    simulated reason codes.

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

active_comparison_registry AS (
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

/***************************************************************************************************
1. MODULE 1 SOURCE POPULATION COUNTS AND ACTIVE RUN SCOPE
***************************************************************************************************/
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

active_run_source_counts AS (
    SELECT
        r.*,

        s.expected_module1_source_rows,
        s.expected_module1_distinct_application_id_count
    FROM active_campaign_runs r

    LEFT JOIN module1_source_counts s
        ON s.module1_scenario_set_name = r.module1_scenario_set_name
       AND s.module1_scenario_name = r.module1_scenario_name
       AND s.population_id = r.population_id
),

active_campaign_duplicate_keys AS (
    SELECT
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS active_registry_key_count
    FROM active_campaign_runs
    GROUP BY
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    HAVING COUNT(*) > 1
),

active_comparison_duplicate_groups AS (
    SELECT
        comparison_group_id,
        COUNT(*) AS active_comparison_group_count
    FROM active_comparison_registry
    GROUP BY comparison_group_id
    HAVING COUNT(*) > 1
),

/***************************************************************************************************
2. DYNAMIC EXPECTED CAMPAIGN SHAPE
***************************************************************************************************/
expected_campaign_shape AS (
    SELECT
        /*******************************************************************************************
        Active registry-driven expected counts.

        These are not hardcoded. They derive from the active campaign registry and active comparison
        registry.
        *******************************************************************************************/
        (SELECT COUNT(*) FROM active_campaign_runs)
            AS expected_campaign_runs,

        (SELECT COUNT(*) FROM active_comparison_registry)
            AS expected_comparison_groups,

        (SELECT COALESCE(SUM(expected_module1_source_rows), 0) FROM active_run_source_counts)
            AS expected_total_active_campaign_source_rows,

        /*******************************************************************************************
        Validation spine count.

        This derives from persistent validation evidence keys currently captured for active campaign
        runs. It avoids hardcoding the Section 14 validation row count.
        *******************************************************************************************/
        (
            SELECT COUNT(DISTINCT (
                v.validation_area,
                v.validation_test_name,
                v.validation_category
            ))
            FROM active_campaign_runs r
            JOIN credit_decisioning_sim.strategy_run_validation_evidence v
                ON v.strategy_set_name = r.strategy_set_name
               AND v.strategy_name = r.strategy_name
               AND v.strategy_version = r.strategy_version
               AND v.module1_scenario_set_name = r.module1_scenario_set_name
               AND v.module1_scenario_name = r.module1_scenario_name
               AND v.population_id = r.population_id
        ) AS expected_validation_key_count,

        /*******************************************************************************************
        Product-guardrail exact-value audit expected shape.
        *******************************************************************************************/
        (
            SELECT COUNT(*)
            FROM active_campaign_runs
            WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
        ) AS expected_product_guardrail_campaign_runs,

        (
            SELECT COUNT(*)
            FROM expected_product_guardrail_policy
        ) AS audited_product_count,

        (
            SELECT COUNT(*)
            FROM active_campaign_runs
            WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
        )
        *
        (
            SELECT COUNT(*)
            FROM expected_product_guardrail_policy
        ) AS expected_product_guardrail_policy_rows
),

/***************************************************************************************************
3. ARCHIVE RECONCILIATION
***************************************************************************************************/
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

archive_reconciliation AS (
    SELECT
        COUNT(*) AS active_campaign_registry_rows_for_archive_check,

        COUNT(*) FILTER (
            WHERE r.expected_module1_source_rows IS NULL
        ) AS active_runs_missing_module1_source_count,

        COUNT(*) FILTER (
            WHERE r.expected_module1_source_rows IS NOT NULL
              AND r.expected_module1_source_rows
                    IS DISTINCT FROM r.expected_module1_distinct_application_id_count
        ) AS active_runs_with_module1_source_application_id_grain_issue,

        COUNT(*) FILTER (
            WHERE a.archived_rows IS NOT NULL
        ) AS active_runs_with_archive_rows,

        COUNT(*) FILTER (
            WHERE a.archived_rows IS NULL
        ) AS active_runs_missing_archive_rows,

        COALESCE(SUM(a.archived_rows), 0) AS total_active_campaign_archived_rows,

        COUNT(*) FILTER (
            WHERE a.archived_rows IS NOT NULL
              AND r.expected_module1_source_rows IS NOT NULL
              AND a.archived_rows IS DISTINCT FROM r.expected_module1_source_rows
        ) AS active_runs_with_archive_row_count_mismatch,

        COUNT(*) FILTER (
            WHERE a.archived_rows IS NOT NULL
              AND (
                    a.archived_rows IS DISTINCT FROM a.distinct_application_id_count
                 OR (
                        r.expected_module1_source_rows IS NOT NULL
                    AND a.distinct_application_id_count IS DISTINCT FROM r.expected_module1_source_rows
                    )
              )
        ) AS active_runs_with_archive_application_id_grain_issue

    FROM active_run_source_counts r

    LEFT JOIN archive_counts a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id
),

active_archive_rows AS (
    SELECT
        a.*
    FROM credit_decisioning_sim.strategy_decisions_archive a

    JOIN active_campaign_runs r
        ON r.strategy_set_name = a.strategy_set_name
       AND r.strategy_name = a.strategy_name
       AND r.strategy_version = a.strategy_version
       AND r.module1_scenario_set_name = a.module1_scenario_set_name
       AND r.module1_scenario_name = a.module1_scenario_name
       AND r.population_id = a.population_id
),

archive_duplicate_grain AS (
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
            COUNT(*) AS archive_grain_row_count
        FROM active_archive_rows
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

/***************************************************************************************************
4. CAMPAIGN AND COMPARISON REGISTRY SUMMARY
***************************************************************************************************/
campaign_registry_summary AS (
    SELECT
        (SELECT COUNT(*) FROM active_campaign_runs)
            AS active_campaign_registry_rows,

        (SELECT COUNT(*) FROM active_campaign_duplicate_keys)
            AS duplicate_active_campaign_technical_key_rows
),

comparison_registry_summary AS (
    SELECT
        (SELECT COUNT(*) FROM active_comparison_registry)
            AS active_comparison_registry_rows,

        (SELECT COUNT(*) FROM active_comparison_duplicate_groups)
            AS duplicate_active_comparison_group_rows
),

/***************************************************************************************************
5. ACTIVE COMPARISON READINESS
***************************************************************************************************/
comparison_baseline_rows AS (
    SELECT
        c.comparison_group_id,
        b.application_id
    FROM active_comparison_registry c

    JOIN credit_decisioning_sim.strategy_decisions_archive b
        ON b.strategy_set_name = c.baseline_strategy_set_name
       AND b.strategy_name = c.baseline_strategy_name
       AND b.strategy_version = c.baseline_strategy_version
       AND b.module1_scenario_set_name = c.module1_scenario_set_name
       AND b.module1_scenario_name = c.module1_scenario_name
       AND b.population_id = c.population_id
),

comparison_challenger_rows AS (
    SELECT
        c.comparison_group_id,
        ch.application_id
    FROM active_comparison_registry c

    JOIN credit_decisioning_sim.strategy_decisions_archive ch
        ON ch.strategy_set_name = c.challenger_strategy_set_name
       AND ch.strategy_name = c.challenger_strategy_name
       AND ch.strategy_version = c.challenger_strategy_version
       AND ch.module1_scenario_set_name = c.module1_scenario_set_name
       AND ch.module1_scenario_name = c.module1_scenario_name
       AND ch.population_id = c.population_id
),

comparison_readiness_by_group AS (
    SELECT
        c.comparison_group_id,

        CASE
            WHEN c.baseline_strategy_set_name = c.challenger_strategy_set_name
             AND c.baseline_strategy_name = c.challenger_strategy_name
             AND c.baseline_strategy_version = c.challenger_strategy_version
                THEN TRUE
            ELSE FALSE
        END AS same_strategy_selected_flag,

        (
            SELECT COUNT(*)
            FROM comparison_baseline_rows b
            WHERE b.comparison_group_id = c.comparison_group_id
        ) AS baseline_archived_row_count,

        (
            SELECT COUNT(*)
            FROM comparison_challenger_rows ch
            WHERE ch.comparison_group_id = c.comparison_group_id
        ) AS challenger_archived_row_count,

        (
            SELECT COUNT(*)
            FROM comparison_baseline_rows b
            JOIN comparison_challenger_rows ch
                ON ch.comparison_group_id = b.comparison_group_id
               AND ch.application_id = b.application_id
            WHERE b.comparison_group_id = c.comparison_group_id
        ) AS matched_application_id_count,

        (
            SELECT COUNT(*)
            FROM comparison_baseline_rows b
            LEFT JOIN comparison_challenger_rows ch
                ON ch.comparison_group_id = b.comparison_group_id
               AND ch.application_id = b.application_id
            WHERE b.comparison_group_id = c.comparison_group_id
              AND ch.application_id IS NULL
        ) AS baseline_only_application_id_count,

        (
            SELECT COUNT(*)
            FROM comparison_challenger_rows ch
            LEFT JOIN comparison_baseline_rows b
                ON b.comparison_group_id = ch.comparison_group_id
               AND b.application_id = ch.application_id
            WHERE ch.comparison_group_id = c.comparison_group_id
              AND b.application_id IS NULL
        ) AS challenger_only_application_id_count

    FROM active_comparison_registry c
),

comparison_readiness_summary AS (
    SELECT
        COUNT(*) AS comparison_group_count,

        COUNT(*) FILTER (
            WHERE same_strategy_selected_flag IS FALSE
              AND baseline_archived_row_count > 0
              AND challenger_archived_row_count > 0
              AND matched_application_id_count = baseline_archived_row_count
              AND matched_application_id_count = challenger_archived_row_count
              AND baseline_only_application_id_count = 0
              AND challenger_only_application_id_count = 0
        ) AS comparison_ready_count,

        COUNT(*) FILTER (
            WHERE same_strategy_selected_flag IS TRUE
               OR baseline_archived_row_count = 0
               OR challenger_archived_row_count = 0
               OR matched_application_id_count <> baseline_archived_row_count
               OR matched_application_id_count <> challenger_archived_row_count
               OR baseline_only_application_id_count <> 0
               OR challenger_only_application_id_count <> 0
        ) AS comparison_review_count

    FROM comparison_readiness_by_group
),

/***************************************************************************************************
6. ACTIVE COMPARISON MATCHED SOURCE-FIELD CONSISTENCY
***************************************************************************************************/
matched_comparison_source_rows AS (
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
        ch.requested_expected_loss_amount AS challenger_requested_expected_loss_amount,

        b.module1_scenario_set_name AS baseline_module1_scenario_set_name,
        ch.module1_scenario_set_name AS challenger_module1_scenario_set_name,

        b.module1_scenario_name AS baseline_module1_scenario_name,
        ch.module1_scenario_name AS challenger_module1_scenario_name,

        b.population_id AS baseline_population_id,
        ch.population_id AS challenger_population_id

    FROM active_comparison_registry c

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
               OR baseline_module1_scenario_set_name IS DISTINCT FROM challenger_module1_scenario_set_name
               OR baseline_module1_scenario_name IS DISTINCT FROM challenger_module1_scenario_name
               OR baseline_population_id IS DISTINCT FROM challenger_population_id
        ) AS source_field_mismatch_count

    FROM matched_comparison_source_rows
    GROUP BY comparison_group_id
),

source_consistency_summary AS (
    SELECT
        COUNT(*) AS source_consistency_group_count,

        COUNT(*) FILTER (
            WHERE source_field_mismatch_count = 0
        ) AS source_consistency_pass_count,

        COUNT(*) FILTER (
            WHERE source_field_mismatch_count <> 0
        ) AS source_consistency_review_count,

        COALESCE(SUM(source_field_mismatch_count), 0) AS total_source_field_mismatch_rows

    FROM source_consistency_by_group
),

/***************************************************************************************************
7. SECTION 16 EVIDENCE COVERAGE
***************************************************************************************************/
executive_evidence_by_run AS (
    SELECT
        r.module2_run_id,

        COUNT(e.strategy_name) AS executive_rows,

        COUNT(*) FILTER (
            WHERE e.strategy_name IS NULL
               OR e.module1_run_id IS NULL
               OR e.module2_run_id IS NULL
               OR e.run_sequence_number IS NULL
               OR e.showcase_id IS NULL
               OR e.validation_evidence_group_id IS NULL
               OR e.run_registry_match_status IS NULL
               OR e.applications IS NULL
               OR e.approval_rate IS NULL
               OR e.counteroffer_rate IS NULL
               OR e.manual_review_rate IS NULL
               OR e.decline_rate IS NULL
               OR e.simulated_offer_exposure_rate IS NULL
               OR e.total_requested_amount IS NULL
               OR e.total_approved_amount IS NULL
               OR e.total_requested_expected_loss_amount IS NULL
               OR e.total_approved_expected_loss_amount IS NULL
               OR e.approved_expected_loss_capture_rate IS NULL
               OR e.approved_el_per_approved_dollar IS NULL
               OR e.frontier_position_type IS NULL
               OR e.executive_frontier_quadrant IS NULL
               OR e.frontier_interpretation_note IS NULL
               OR e.counteroffer_strategy_variant IS NULL
               OR e.aggressive_counteroffer_expansion_enabled IS NULL
               OR e.ordinary_counteroffer_candidate_rows IS NULL
               OR e.aggressive_override_rows IS NULL
               OR e.option_c_frontier_posture_type IS NULL
        ) AS executive_required_field_gap_rows

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_evidence_summary e
        ON e.strategy_set_name = r.strategy_set_name
       AND e.strategy_name = r.strategy_name
       AND e.strategy_version = r.strategy_version
       AND e.module1_scenario_set_name = r.module1_scenario_set_name
       AND e.module1_scenario_name = r.module1_scenario_name
       AND e.population_id = r.population_id

    GROUP BY r.module2_run_id
),

parameter_snapshot_by_run AS (
    SELECT
        r.module2_run_id,

        COUNT(p.strategy_name) AS parameter_snapshot_rows,

        COUNT(*) FILTER (
            WHERE p.strategy_name IS NULL
               OR p.strategy_params_jsonb IS NULL
               OR p.product_policy_params_jsonb IS NULL
               OR p.run_story_params_jsonb IS NULL
               OR p.parameter_snapshot_hash IS NULL
               OR p.module1_run_id IS NULL
               OR p.module2_run_id IS NULL
               OR p.validation_evidence_group_id IS NULL
               OR p.run_registry_match_status IS NULL
        ) AS parameter_snapshot_required_field_gap_rows

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_parameter_snapshot p
        ON p.strategy_set_name = r.strategy_set_name
       AND p.strategy_name = r.strategy_name
       AND p.strategy_version = r.strategy_version
       AND p.module1_scenario_set_name = r.module1_scenario_set_name
       AND p.module1_scenario_name = r.module1_scenario_name
       AND p.population_id = r.population_id

    GROUP BY r.module2_run_id
),

validation_key_catalog AS (
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

validation_evidence_by_run AS (
    SELECT
        r.module2_run_id,

        COUNT(*) FILTER (
            WHERE v.validation_area IS NOT NULL
        ) AS validation_rows,

        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) FILTER (
            WHERE v.validation_area IS NOT NULL
        ) AS validation_distinct_key_count,

        (
            COUNT(*) FILTER (
                WHERE v.validation_area IS NOT NULL
            )
            -
            COUNT(DISTINCT (
                v.validation_area,
                v.validation_test_name,
                v.validation_category
            )) FILTER (
                WHERE v.validation_area IS NOT NULL
            )
        ) AS duplicate_validation_key_rows

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_validation_evidence v
        ON v.strategy_set_name = r.strategy_set_name
       AND v.strategy_name = r.strategy_name
       AND v.strategy_version = r.strategy_version
       AND v.module1_scenario_set_name = r.module1_scenario_set_name
       AND v.module1_scenario_name = r.module1_scenario_name
       AND v.population_id = r.population_id

    GROUP BY r.module2_run_id
),

expected_segment_by_run AS (
    SELECT
        r.module2_run_id,

        COUNT(DISTINCT (
            a.product_type_policy_key,
            a.score_band_policy_key,
            a.product_score_policy_segment
        )) AS expected_segment_rows
    FROM active_campaign_runs r

    JOIN credit_decisioning_sim.strategy_decisions_archive a
        ON a.strategy_set_name = r.strategy_set_name
       AND a.strategy_name = r.strategy_name
       AND a.strategy_version = r.strategy_version
       AND a.module1_scenario_set_name = r.module1_scenario_set_name
       AND a.module1_scenario_name = r.module1_scenario_name
       AND a.population_id = r.population_id

    GROUP BY r.module2_run_id
),

segment_evidence_by_run AS (
    SELECT
        r.module2_run_id,

        COUNT(*) FILTER (
            WHERE s.product_type_policy_key IS NOT NULL
        ) AS segment_rows,

        COUNT(DISTINCT (
            s.product_type_policy_key,
            s.score_band_policy_key,
            s.product_score_policy_segment
        )) FILTER (
            WHERE s.product_type_policy_key IS NOT NULL
        ) AS segment_distinct_key_count,

        (
            COUNT(*) FILTER (
                WHERE s.product_type_policy_key IS NOT NULL
            )
            -
            COUNT(DISTINCT (
                s.product_type_policy_key,
                s.score_band_policy_key,
                s.product_score_policy_segment
            )) FILTER (
                WHERE s.product_type_policy_key IS NOT NULL
            )
        ) AS duplicate_segment_key_rows

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_segment_evidence_summary s
        ON s.strategy_set_name = r.strategy_set_name
       AND s.strategy_name = r.strategy_name
       AND s.strategy_version = r.strategy_version
       AND s.module1_scenario_set_name = r.module1_scenario_set_name
       AND s.module1_scenario_name = r.module1_scenario_name
       AND s.population_id = r.population_id

    GROUP BY r.module2_run_id
),

evidence_summary AS (
    SELECT
        COUNT(*) AS registry_run_count_for_evidence_check,

        SUM(ex.executive_rows) AS executive_evidence_rows,

        COUNT(*) FILTER (
            WHERE ex.executive_rows = 1
              AND ex.executive_required_field_gap_rows = 0
        ) AS executive_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE ex.executive_rows <> 1
               OR ex.executive_required_field_gap_rows <> 0
        ) AS executive_evidence_issue_run_count,

        SUM(ps.parameter_snapshot_rows) AS parameter_snapshot_rows,

        COUNT(*) FILTER (
            WHERE ps.parameter_snapshot_rows = 1
        ) AS parameter_snapshot_single_row_run_count,

        COUNT(*) FILTER (
            WHERE ps.parameter_snapshot_rows <> 1
        ) AS parameter_snapshot_row_count_issue_run_count,

        COUNT(*) AS registry_run_count_for_parameter_snapshot_check,

        COUNT(*) FILTER (
            WHERE ps.parameter_snapshot_rows = 1
              AND ps.parameter_snapshot_required_field_gap_rows = 0
        ) AS parameter_snapshot_ready_run_count,

        COUNT(*) FILTER (
            WHERE ps.parameter_snapshot_rows <> 1
               OR ps.parameter_snapshot_required_field_gap_rows <> 0
        ) AS parameter_snapshot_issue_run_count,

        COUNT(*) FILTER (
            WHERE ve.validation_rows = vk.expected_validation_key_count
              AND ve.validation_distinct_key_count = vk.expected_validation_key_count
              AND ve.duplicate_validation_key_rows = 0
        ) AS validation_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE ve.validation_rows <> vk.expected_validation_key_count
               OR ve.validation_distinct_key_count <> vk.expected_validation_key_count
               OR ve.duplicate_validation_key_rows <> 0
        ) AS validation_evidence_incomplete_run_count,

        MIN(ve.validation_rows) AS min_validation_rows_per_run,
        MAX(ve.validation_rows) AS max_validation_rows_per_run,
        SUM(ve.validation_rows) AS total_validation_evidence_rows,

        COUNT(*) FILTER (
            WHERE se.segment_rows = es.expected_segment_rows
              AND se.segment_distinct_key_count = es.expected_segment_rows
              AND se.duplicate_segment_key_rows = 0
        ) AS segment_evidence_complete_run_count,

        COUNT(*) FILTER (
            WHERE se.segment_rows <> es.expected_segment_rows
               OR se.segment_distinct_key_count <> es.expected_segment_rows
               OR se.duplicate_segment_key_rows <> 0
        ) AS segment_evidence_issue_run_count,

        MIN(es.expected_segment_rows) AS min_expected_segment_rows_per_run,
        MAX(es.expected_segment_rows) AS max_expected_segment_rows_per_run,
        MIN(se.segment_rows) AS min_segment_rows_per_run,
        MAX(se.segment_rows) AS max_segment_rows_per_run,
        SUM(se.segment_rows) AS total_segment_evidence_rows

    FROM active_campaign_runs r

    JOIN executive_evidence_by_run ex
        ON ex.module2_run_id = r.module2_run_id

    JOIN parameter_snapshot_by_run ps
        ON ps.module2_run_id = r.module2_run_id

    JOIN validation_evidence_by_run ve
        ON ve.module2_run_id = r.module2_run_id

    JOIN expected_segment_by_run es
        ON es.module2_run_id = r.module2_run_id

    JOIN segment_evidence_by_run se
        ON se.module2_run_id = r.module2_run_id

    CROSS JOIN validation_key_catalog vk
),

/***************************************************************************************************
8. OPTION C EXECUTIVE EVIDENCE READINESS
***************************************************************************************************/
option_c_evidence_summary AS (
    SELECT
        COUNT(*) AS option_c_evidence_run_count,

        COUNT(*) FILTER (
            WHERE e.counteroffer_strategy_variant IS NULL
               OR e.aggressive_counteroffer_expansion_enabled IS NULL
               OR e.ordinary_counteroffer_candidate_rows IS NULL
               OR e.ordinary_counteroffer_candidate_rate IS NULL
               OR e.aggressive_override_rows IS NULL
               OR e.aggressive_override_rate IS NULL
               OR e.aggressive_override_final_counteroffer_rows IS NULL
               OR e.aggressive_override_final_manual_review_rows IS NULL
               OR e.aggressive_override_final_decline_rows IS NULL
               OR e.option_c_frontier_posture_type IS NULL
        ) AS option_c_executive_evidence_gap_rows,

        COUNT(*) FILTER (
            WHERE e.strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY'
              AND COALESCE(e.aggressive_override_rows, 0) <> 0
        ) AS selective_strategy_aggressive_override_evidence_issue_rows,

        COUNT(*) FILTER (
            WHERE e.strategy_name = 'AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY'
              AND COALESCE(e.aggressive_override_rows, 0) <= 0
        ) AS aggressive_strategy_missing_override_evidence_rows

    FROM active_campaign_runs r

    LEFT JOIN credit_decisioning_sim.strategy_run_evidence_summary e
        ON e.strategy_set_name = r.strategy_set_name
       AND e.strategy_name = r.strategy_name
       AND e.strategy_version = r.strategy_version
       AND e.module1_scenario_set_name = r.module1_scenario_set_name
       AND e.module1_scenario_name = r.module1_scenario_name
       AND e.population_id = r.population_id
),

/***************************************************************************************************
9. FINAL-OUTPUT CONVENTION CHECKS

IMPORTANT:
    This block intentionally mirrors the Section 17.9 convention logic.

    Do not combine MANUAL_REVIEW and DECLINE into one generic no-offer payment rule.

    MANUAL_REVIEW remains unresolved:
        approved amount, approved payment, approved PTI, and approved Expected Loss are NULL.

    DECLINE uses the zero-exposure convention:
        approved amount, approved payment, approved PTI, and approved Expected Loss are zero.
***************************************************************************************************/
convention_counts AS (
    SELECT
        COUNT(*) AS active_campaign_archived_rows,

        COUNT(*) FILTER (
            WHERE (
                    COALESCE(approval_flag::INT, 0)
                  + COALESCE(counteroffer_flag::INT, 0)
                  + COALESCE(manual_review_flag::INT, 0)
                  + COALESCE(decline_flag::INT, 0)
                  ) <> 1
        ) AS final_outcome_flag_count_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome IN ('APPROVE', 'COUNTEROFFER')
                AND simulated_offer_exposure_flag IS DISTINCT FROM TRUE
                  )
               OR (
                    decision_outcome IN ('MANUAL_REVIEW', 'DECLINE')
                AND simulated_offer_exposure_flag IS DISTINCT FROM FALSE
                  )
        ) AS simulated_offer_exposure_flag_violation_rows,

        /*******************************************************************************************
        Amount conventions.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
              AND (
                    approved_amount IS NULL
                 OR approved_amount IS DISTINCT FROM requested_amount
                 OR counteroffer_amount IS NOT NULL
                 OR exposure_reduction_flag IS DISTINCT FROM FALSE
                 OR COALESCE(exposure_reduction_amount, 0) <> 0
                 OR COALESCE(exposure_reduction_pct, 0) <> 0
              )
        ) AS approve_amount_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    approved_amount IS NULL
                 OR counteroffer_amount IS NULL
                 OR counteroffer_amount IS DISTINCT FROM approved_amount
                 OR approved_amount <= 0
                 OR requested_amount IS NULL
                 OR approved_amount >= requested_amount
                 OR exposure_reduction_flag IS DISTINCT FROM TRUE
                 OR exposure_reduction_amount IS NULL
                 OR exposure_reduction_amount <= 0
                 OR exposure_reduction_pct IS NULL
                 OR exposure_reduction_pct <= 0
              )
        ) AS counteroffer_amount_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND (
                    approved_amount IS NOT NULL
                 OR counteroffer_amount IS NOT NULL
                 OR exposure_reduction_flag IS DISTINCT FROM FALSE
                 OR exposure_reduction_amount IS NOT NULL
                 OR exposure_reduction_pct IS NOT NULL
              )
        ) AS manual_review_amount_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0
                 OR counteroffer_amount IS NOT NULL
                 OR exposure_reduction_flag IS DISTINCT FROM FALSE
                 OR COALESCE(exposure_reduction_amount, 0) <> 0
                 OR COALESCE(exposure_reduction_pct, 0) <> 0
              )
        ) AS decline_amount_violation_rows,

        /*******************************************************************************************
        Affordability / payment conventions.

        This is the corrected 17.20 logic:
            APPROVE preserves requested payment and PTI.
            COUNTEROFFER has populated approved payment / PTI and should not increase PTI.
            MANUAL_REVIEW is unresolved / NULL.
            DECLINE is zero-payment / zero-PTI.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
              AND (
                    approved_monthly_payment_proxy IS NULL
                 OR approved_payment_to_income_ratio IS NULL
                 OR approved_monthly_payment_proxy
                        IS DISTINCT FROM requested_monthly_payment_proxy
                 OR approved_payment_to_income_ratio
                        IS DISTINCT FROM requested_payment_to_income_ratio
              )
        ) AS approve_payment_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    approved_monthly_payment_proxy IS NULL
                 OR approved_payment_to_income_ratio IS NULL
                 OR approved_monthly_payment_proxy < 0
                 OR approved_payment_to_income_ratio < 0
                 OR (
                        requested_monthly_payment_proxy IS NOT NULL
                    AND approved_monthly_payment_proxy > requested_monthly_payment_proxy
                    )
                 OR (
                        requested_payment_to_income_ratio IS NOT NULL
                    AND approved_payment_to_income_ratio > requested_payment_to_income_ratio
                    )
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
                    approved_monthly_payment_proxy IS DISTINCT FROM 0
                 OR approved_payment_to_income_ratio IS DISTINCT FROM 0
              )
        ) AS decline_affordability_violation_rows,

        /*******************************************************************************************
        Approved Expected Loss conventions.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
              AND (
                    approved_expected_loss_amount IS NULL
                 OR approved_expected_loss_amount
                        IS DISTINCT FROM requested_expected_loss_amount
              )
        ) AS approve_expected_loss_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    approved_expected_loss_amount IS NULL
                 OR approved_expected_loss_amount < 0
                 OR (
                        requested_expected_loss_amount IS NOT NULL
                    AND approved_expected_loss_amount > requested_expected_loss_amount
                    )
                 OR (
                        product_approved_el_cap IS NOT NULL
                    AND approved_expected_loss_amount > product_approved_el_cap
                    )
              )
        ) AS counteroffer_expected_loss_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND approved_expected_loss_amount IS NOT NULL
        ) AS manual_review_expected_loss_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND approved_expected_loss_amount IS DISTINCT FROM 0
        ) AS decline_expected_loss_violation_rows,

        /*******************************************************************************************
        Reason-code completeness and family alignment.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR triggered_reason_code_list IS NULL
               OR reason_priority_rank IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count <= 0
        ) AS reason_code_completeness_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND primary_reason_family <> 'APPROVAL'
                  )
               OR (
                    decision_outcome = 'COUNTEROFFER'
                AND primary_reason_family <> 'COUNTEROFFER'
                  )
               OR (
                    decision_outcome = 'MANUAL_REVIEW'
                AND primary_reason_family <> 'MANUAL_REVIEW'
                  )
               OR (
                    decision_outcome = 'DECLINE'
                AND primary_reason_family <> 'POLICY_STOP'
                  )
        ) AS reason_family_alignment_violation_rows,

        /*******************************************************************************************
        Option C field persistence and reason traceability.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE counteroffer_strategy_variant IS NULL
               OR aggressive_counteroffer_expansion_enabled IS NULL
               OR ordinary_counteroffer_candidate_flag IS NULL
               OR aggressive_counteroffer_requested_structure_override_flag IS NULL
               OR aggressive_counteroffer_requested_structure_override_enabled IS NULL
               OR exposure_extreme_counteroffer_override_enabled IS NULL
               OR requested_pti_decline_counteroffer_override_enabled IS NULL
               OR requested_el_decline_counteroffer_override_enabled IS NULL
               OR exposure_policy_stop_counteroffer_override_enabled IS NULL
               OR severe_requested_structure_counteroffer_override_enabled IS NULL
        ) AS option_c_archive_field_gap_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND (
                    triggered_reason_code_list IS NULL
                 OR (
                        decision_outcome = 'COUNTEROFFER'
                    AND triggered_reason_code_list NOT LIKE
                            '%COUNTEROFFER_AGGRESSIVE_REQUESTED_STRUCTURE_OVERRIDE%'
                    )
                 OR (
                        decision_outcome = 'MANUAL_REVIEW'
                    AND triggered_reason_code_list NOT LIKE
                            '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
                 OR (
                        decision_outcome = 'DECLINE'
                    AND triggered_reason_code_list NOT LIKE
                            '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
              )
        ) AS aggressive_override_reason_trace_gap_rows,

        COUNT(*) FILTER (
            WHERE strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY'
              AND aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS selective_strategy_aggressive_override_rows

    FROM active_archive_rows
),

convention_summary AS (
    SELECT
        active_campaign_archived_rows,

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
            + option_c_archive_field_gap_rows
            + aggressive_override_reason_trace_gap_rows
            + selective_strategy_aggressive_override_rows
        ) AS critical_convention_violation_count,

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

        option_c_archive_field_gap_rows,
        aggressive_override_reason_trace_gap_rows,
        selective_strategy_aggressive_override_rows

    FROM convention_counts
),

/***************************************************************************************************
10. PRODUCT GUARDRAIL EXACT-VALUE AUDIT SUMMARY
***************************************************************************************************/
product_guardrail_campaign_runs AS (
    SELECT
        module2_run_id,
        run_sequence_number,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        strategy_set_name,
        strategy_name,
        strategy_version
    FROM active_campaign_runs
    WHERE strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
),

product_guardrail_parameter_snapshots AS (
    SELECT
        module2_run_id,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        COUNT(*) AS parameter_snapshot_rows_for_run,

        (ARRAY_AGG(product_policy_params_jsonb ORDER BY evidence_snapshot_ts DESC NULLS LAST))[1]
            AS product_policy_params_jsonb

    FROM credit_decisioning_sim.strategy_run_parameter_snapshot

    GROUP BY
        module2_run_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
),

product_guardrail_runs AS (
    SELECT
        r.module2_run_id,
        r.run_sequence_number,

        r.strategy_set_name,
        r.strategy_name,
        r.strategy_version,

        r.module1_scenario_set_name,
        r.module1_scenario_name,
        r.population_id,

        COALESCE(p.parameter_snapshot_rows_for_run, 0)
            AS parameter_snapshot_rows_for_run,

        p.product_policy_params_jsonb

    FROM product_guardrail_campaign_runs r

    LEFT JOIN product_guardrail_parameter_snapshots p
        ON p.module2_run_id = r.module2_run_id
       AND p.strategy_set_name = r.strategy_set_name
       AND p.strategy_name = r.strategy_name
       AND p.strategy_version = r.strategy_version
       AND p.module1_scenario_set_name = r.module1_scenario_set_name
       AND p.module1_scenario_name = r.module1_scenario_name
       AND p.population_id = r.population_id
),

expected_run_product_rows AS (
    SELECT
        r.module2_run_id,
        r.parameter_snapshot_rows_for_run,
        e.*
    FROM product_guardrail_runs r
    CROSS JOIN expected_product_guardrail_policy e
),

actual_product_guardrail_policy_raw AS (
    SELECT
        r.module2_run_id,

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

    CROSS JOIN LATERAL jsonb_array_elements(
        CASE
            WHEN jsonb_typeof(r.product_policy_params_jsonb) = 'array'
                THEN r.product_policy_params_jsonb
            ELSE '[]'::jsonb
        END
    ) AS pp(product_policy_row)

    WHERE pp.product_policy_row ->> 'product_type' IN (
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    )
),

actual_product_guardrail_policy AS (
    SELECT
        module2_run_id,
        product_type,

        COUNT(*) AS actual_product_policy_rows_for_product,

        MAX(actual_product_approve_max_pti) AS actual_product_approve_max_pti,
        MAX(actual_product_review_max_pti) AS actual_product_review_max_pti,
        MAX(actual_product_decline_min_pti) AS actual_product_decline_min_pti,
        MAX(actual_counteroffer_target_pti) AS actual_counteroffer_target_pti,
        MAX(actual_product_approve_max_requested_el) AS actual_product_approve_max_requested_el,
        MAX(actual_product_review_max_requested_el) AS actual_product_review_max_requested_el,
        MAX(actual_product_decline_min_requested_el) AS actual_product_decline_min_requested_el,
        MAX(actual_product_approved_el_cap) AS actual_product_approved_el_cap,
        MAX(actual_product_min_approved_amount) AS actual_product_min_approved_amount,
        MAX(actual_product_max_approved_amount) AS actual_product_max_approved_amount,
        MAX(actual_product_min_counteroffer_pct) AS actual_product_min_counteroffer_pct,
        MAX(actual_product_max_exposure_reduction_pct) AS actual_product_max_exposure_reduction_pct

    FROM actual_product_guardrail_policy_raw
    GROUP BY
        module2_run_id,
        product_type
),

product_guardrail_policy_comparison AS (
    SELECT
        e.module2_run_id,
        e.product_type,
        e.parameter_snapshot_rows_for_run,

        COALESCE(a.actual_product_policy_rows_for_product, 0)
            AS actual_product_policy_rows_for_product,

        (
            CASE
                WHEN a.product_type IS NULL THEN 1
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 1
                WHEN a.actual_product_approve_max_pti IS DISTINCT FROM e.expected_product_approve_max_pti THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_review_max_pti IS DISTINCT FROM e.expected_product_review_max_pti THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_decline_min_pti IS DISTINCT FROM e.expected_product_decline_min_pti THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_counteroffer_target_pti IS DISTINCT FROM e.expected_counteroffer_target_pti THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_approve_max_requested_el IS DISTINCT FROM e.expected_product_approve_max_requested_el THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_review_max_requested_el IS DISTINCT FROM e.expected_product_review_max_requested_el THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_decline_min_requested_el IS DISTINCT FROM e.expected_product_decline_min_requested_el THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_approved_el_cap IS DISTINCT FROM e.expected_product_approved_el_cap THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_min_approved_amount IS DISTINCT FROM e.expected_product_min_approved_amount THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_max_approved_amount IS DISTINCT FROM e.expected_product_max_approved_amount THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_min_counteroffer_pct IS DISTINCT FROM e.expected_product_min_counteroffer_pct THEN 1
                ELSE 0
            END
            +
            CASE
                WHEN a.product_type IS NULL THEN 0
                WHEN COALESCE(a.actual_product_policy_rows_for_product, 0) <> 1 THEN 0
                WHEN a.actual_product_max_exposure_reduction_pct IS DISTINCT FROM e.expected_product_max_exposure_reduction_pct THEN 1
                ELSE 0
            END
        ) AS product_policy_field_mismatch_count

    FROM expected_run_product_rows e

    LEFT JOIN actual_product_guardrail_policy a
        ON a.module2_run_id = e.module2_run_id
       AND a.product_type = e.product_type
),

product_guardrail_policy_audit AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM product_guardrail_campaign_runs
        ) AS product_guardrail_campaign_run_count,

        (
            SELECT COUNT(*)
            FROM expected_product_guardrail_policy
        ) AS product_guardrail_audited_product_count,

        (
            SELECT COUNT(*)
            FROM product_guardrail_runs
            WHERE parameter_snapshot_rows_for_run = 1
        ) AS product_guardrail_parameter_snapshot_complete_run_count,

        (
            SELECT COUNT(*)
            FROM product_guardrail_runs
            WHERE parameter_snapshot_rows_for_run <> 1
        ) AS product_guardrail_parameter_snapshot_issue_run_count,

        COUNT(*) AS product_guardrail_expected_policy_rows,

        COUNT(*) FILTER (
            WHERE actual_product_policy_rows_for_product = 1
              AND parameter_snapshot_rows_for_run = 1
              AND product_policy_field_mismatch_count = 0
        ) AS product_guardrail_policy_ready_rows,

        COUNT(*) FILTER (
            WHERE actual_product_policy_rows_for_product = 0
        ) AS missing_product_guardrail_policy_rows,

        COUNT(*) FILTER (
            WHERE actual_product_policy_rows_for_product <> 1
        ) AS product_guardrail_policy_row_count_issue_rows,

        COUNT(*) FILTER (
            WHERE product_policy_field_mismatch_count > 0
        ) AS product_guardrail_policy_mismatch_rows

    FROM product_guardrail_policy_comparison
),

/***************************************************************************************************
11. FINAL ACCEPTANCE INPUTS AND STATUS FLAGS
***************************************************************************************************/
acceptance_inputs AS (
    SELECT
        /*******************************************************************************************
        Dynamic expected campaign shape.
        *******************************************************************************************/
        ecs.expected_campaign_runs,
        ecs.expected_comparison_groups,
        ecs.expected_total_active_campaign_source_rows,
        ecs.expected_validation_key_count,
        ecs.expected_product_guardrail_campaign_runs,
        ecs.audited_product_count,
        ecs.expected_product_guardrail_policy_rows,

        /*******************************************************************************************
        Registry readiness.
        *******************************************************************************************/
        crs.active_campaign_registry_rows,
        crs.duplicate_active_campaign_technical_key_rows,

        cprs.active_comparison_registry_rows,
        cprs.duplicate_active_comparison_group_rows,

        /*******************************************************************************************
        Archive readiness.
        *******************************************************************************************/
        ar.active_campaign_registry_rows_for_archive_check,
        ar.active_runs_missing_module1_source_count,
        ar.active_runs_with_module1_source_application_id_grain_issue,
        ar.active_runs_with_archive_rows,
        ar.active_runs_missing_archive_rows,
        ar.total_active_campaign_archived_rows,
        ar.active_runs_with_archive_row_count_mismatch,
        ar.active_runs_with_archive_application_id_grain_issue,
        adg.duplicate_archive_grain_count,

        /*******************************************************************************************
        Comparison readiness.
        *******************************************************************************************/
        cr.comparison_group_count,
        cr.comparison_ready_count,
        cr.comparison_review_count,

        /*******************************************************************************************
        Source-field consistency.
        *******************************************************************************************/
        sc.source_consistency_group_count,
        sc.source_consistency_pass_count,
        sc.source_consistency_review_count,
        sc.total_source_field_mismatch_rows,

        /*******************************************************************************************
        Evidence readiness.
        *******************************************************************************************/
        ev.registry_run_count_for_evidence_check,

        ev.executive_evidence_rows,
        ev.executive_evidence_complete_run_count,
        ev.executive_evidence_issue_run_count,

        ev.parameter_snapshot_rows,
        ev.parameter_snapshot_single_row_run_count,
        ev.parameter_snapshot_row_count_issue_run_count,

        ev.registry_run_count_for_parameter_snapshot_check,
        ev.parameter_snapshot_ready_run_count,
        ev.parameter_snapshot_issue_run_count,

        ev.validation_evidence_complete_run_count,
        ev.validation_evidence_incomplete_run_count,
        ev.min_validation_rows_per_run,
        ev.max_validation_rows_per_run,
        ev.total_validation_evidence_rows,

        ev.segment_evidence_complete_run_count,
        ev.segment_evidence_issue_run_count,
        ev.min_expected_segment_rows_per_run,
        ev.max_expected_segment_rows_per_run,
        ev.min_segment_rows_per_run,
        ev.max_segment_rows_per_run,
        ev.total_segment_evidence_rows,

        /*******************************************************************************************
        Final-output convention readiness.
        *******************************************************************************************/
        cs.active_campaign_archived_rows,
        cs.critical_convention_violation_count,

        cs.final_outcome_flag_count_violation_rows,
        cs.simulated_offer_exposure_flag_violation_rows,

        cs.approve_amount_violation_rows,
        cs.counteroffer_amount_violation_rows,
        cs.manual_review_amount_violation_rows,
        cs.decline_amount_violation_rows,

        cs.approve_payment_violation_rows,
        cs.counteroffer_affordability_violation_rows,
        cs.manual_review_affordability_violation_rows,
        cs.decline_affordability_violation_rows,

        cs.approve_expected_loss_violation_rows,
        cs.counteroffer_expected_loss_violation_rows,
        cs.manual_review_expected_loss_violation_rows,
        cs.decline_expected_loss_violation_rows,

        cs.reason_code_completeness_violation_rows,
        cs.reason_family_alignment_violation_rows,

        cs.option_c_archive_field_gap_rows,
        cs.aggressive_override_reason_trace_gap_rows,
        cs.selective_strategy_aggressive_override_rows,

        /*******************************************************************************************
        Option C evidence readiness.
        *******************************************************************************************/
        oc.option_c_evidence_run_count,
        oc.option_c_executive_evidence_gap_rows,
        oc.selective_strategy_aggressive_override_evidence_issue_rows,
        oc.aggressive_strategy_missing_override_evidence_rows,

        /*******************************************************************************************
        Product guardrail exact-value audit.
        *******************************************************************************************/
        pga.product_guardrail_campaign_run_count,
        pga.product_guardrail_audited_product_count,
        pga.product_guardrail_expected_policy_rows,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,
        pga.product_guardrail_policy_ready_rows,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_row_count_issue_rows,
        pga.product_guardrail_policy_mismatch_rows,

        /*******************************************************************************************
        Acceptance gate flags.
        *******************************************************************************************/
        (
            crs.active_campaign_registry_rows = ecs.expected_campaign_runs
            AND crs.duplicate_active_campaign_technical_key_rows = 0
        ) AS campaign_registry_ready_flag,

        (
            cprs.active_comparison_registry_rows = ecs.expected_comparison_groups
            AND cprs.duplicate_active_comparison_group_rows = 0
        ) AS comparison_registry_ready_flag,

        (
            ar.active_campaign_registry_rows_for_archive_check = ecs.expected_campaign_runs
            AND ar.active_runs_missing_module1_source_count = 0
            AND ar.active_runs_with_module1_source_application_id_grain_issue = 0
            AND ar.active_runs_with_archive_rows = ecs.expected_campaign_runs
            AND ar.active_runs_missing_archive_rows = 0
            AND ar.total_active_campaign_archived_rows = ecs.expected_total_active_campaign_source_rows
            AND ar.active_runs_with_archive_row_count_mismatch = 0
            AND ar.active_runs_with_archive_application_id_grain_issue = 0
            AND adg.duplicate_archive_grain_count = 0
        ) AS archive_ready_flag,

        (
            cr.comparison_group_count = ecs.expected_comparison_groups
            AND cr.comparison_ready_count = ecs.expected_comparison_groups
            AND cr.comparison_review_count = 0
        ) AS comparison_ready_flag,

        (
            sc.source_consistency_group_count = ecs.expected_comparison_groups
            AND sc.source_consistency_pass_count = ecs.expected_comparison_groups
            AND sc.source_consistency_review_count = 0
            AND sc.total_source_field_mismatch_rows = 0
        ) AS source_consistency_ready_flag,

        (
            ev.registry_run_count_for_evidence_check = ecs.expected_campaign_runs
            AND ev.executive_evidence_complete_run_count = ecs.expected_campaign_runs
            AND ev.executive_evidence_issue_run_count = 0
            AND ev.parameter_snapshot_single_row_run_count = ecs.expected_campaign_runs
            AND ev.parameter_snapshot_row_count_issue_run_count = 0
            AND ev.validation_evidence_complete_run_count = ecs.expected_campaign_runs
            AND ev.validation_evidence_incomplete_run_count = 0
            AND ev.segment_evidence_complete_run_count = ecs.expected_campaign_runs
            AND ev.segment_evidence_issue_run_count = 0
        ) AS evidence_ready_flag,

        (
            ev.registry_run_count_for_parameter_snapshot_check = ecs.expected_campaign_runs
            AND ev.parameter_snapshot_ready_run_count = ecs.expected_campaign_runs
            AND ev.parameter_snapshot_issue_run_count = 0
        ) AS parameter_snapshot_ready_flag,

        (
            cs.critical_convention_violation_count = 0
        ) AS final_output_conventions_ready_flag,

        (
            oc.option_c_evidence_run_count = ecs.expected_campaign_runs
            AND oc.option_c_executive_evidence_gap_rows = 0
            AND oc.selective_strategy_aggressive_override_evidence_issue_rows = 0
            AND oc.aggressive_strategy_missing_override_evidence_rows = 0
        ) AS option_c_evidence_ready_flag,

        (
            pga.product_guardrail_campaign_run_count = ecs.expected_product_guardrail_campaign_runs
            AND pga.product_guardrail_audited_product_count = ecs.audited_product_count
            AND pga.product_guardrail_expected_policy_rows = ecs.expected_product_guardrail_policy_rows
            AND pga.product_guardrail_parameter_snapshot_issue_run_count = 0
            AND pga.product_guardrail_policy_ready_rows = ecs.expected_product_guardrail_policy_rows
            AND pga.missing_product_guardrail_policy_rows = 0
            AND pga.product_guardrail_policy_row_count_issue_rows = 0
            AND pga.product_guardrail_policy_mismatch_rows = 0
        ) AS product_guardrail_policy_ready_flag

    FROM expected_campaign_shape ecs
    CROSS JOIN campaign_registry_summary crs
    CROSS JOIN comparison_registry_summary cprs
    CROSS JOIN archive_reconciliation ar
    CROSS JOIN archive_duplicate_grain adg
    CROSS JOIN comparison_readiness_summary cr
    CROSS JOIN source_consistency_summary sc
    CROSS JOIN evidence_summary ev
    CROSS JOIN convention_summary cs
    CROSS JOIN option_c_evidence_summary oc
    CROSS JOIN product_guardrail_policy_audit pga
),

acceptance_status AS (
    SELECT
        ai.*,

        (
            campaign_registry_ready_flag
            AND comparison_registry_ready_flag
            AND archive_ready_flag
            AND comparison_ready_flag
            AND source_consistency_ready_flag
            AND evidence_ready_flag
            AND parameter_snapshot_ready_flag
            AND final_output_conventions_ready_flag
            AND option_c_evidence_ready_flag
            AND product_guardrail_policy_ready_flag
        ) AS structural_acceptance_ready_flag,

        CASE
            WHEN (
                    campaign_registry_ready_flag
                AND comparison_registry_ready_flag
                AND archive_ready_flag
                AND comparison_ready_flag
                AND source_consistency_ready_flag
                AND evidence_ready_flag
                AND parameter_snapshot_ready_flag
                AND final_output_conventions_ready_flag
                AND option_c_evidence_ready_flag
                AND product_guardrail_policy_ready_flag
            )
                THEN 'MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS'

            WHEN (
                    campaign_registry_ready_flag
                AND comparison_registry_ready_flag
                AND archive_ready_flag
                AND comparison_ready_flag
                AND source_consistency_ready_flag
                AND evidence_ready_flag
                AND parameter_snapshot_ready_flag
                AND final_output_conventions_ready_flag
                AND option_c_evidence_ready_flag
                AND product_guardrail_policy_ready_flag IS DISTINCT FROM TRUE
            )
                THEN 'STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED'

            ELSE 'REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS'
        END AS module2_campaign_acceptance_status,

        CONCAT_WS(
            ' | ',

            CASE
                WHEN campaign_registry_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_CAMPAIGN_REGISTRY'
            END,

            CASE
                WHEN comparison_registry_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_COMPARISON_REGISTRY'
            END,

            CASE
                WHEN archive_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_ARCHIVE_INVENTORY_OR_GRAIN'
            END,

            CASE
                WHEN comparison_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_COMPARISON_READINESS'
            END,

            CASE
                WHEN source_consistency_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_MATCHED_SOURCE_FIELD_CONSISTENCY'
            END,

            CASE
                WHEN evidence_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_SECTION_16_EVIDENCE_COMPLETENESS'
            END,

            CASE
                WHEN parameter_snapshot_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_PARAMETER_SNAPSHOT_TRACEABILITY'
            END,

            CASE
                WHEN final_output_conventions_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_FINAL_OUTPUT_CONVENTIONS'
            END,

            CASE
                WHEN option_c_evidence_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_OPTION_C_COUNTEROFFER_SPLIT_EVIDENCE'
            END,

            CASE
                WHEN product_guardrail_policy_ready_flag IS DISTINCT FROM TRUE
                    THEN 'REVIEW_PRODUCT_GUARDRAIL_POLICY_EXACT_VALUES'
            END
        ) AS acceptance_review_focus

    FROM acceptance_inputs ai
)

SELECT
    /***********************************************************************************************
    Final status.
    ***********************************************************************************************/
    module2_campaign_acceptance_status,

    structural_acceptance_ready_flag,

    CASE
        WHEN acceptance_review_focus IS NULL
          OR acceptance_review_focus = ''
            THEN 'ALL_FINAL_ACCEPTANCE_GATES_PASSED'
        ELSE acceptance_review_focus
    END AS acceptance_review_focus,

    /***********************************************************************************************
    Dynamic expected campaign shape.
    ***********************************************************************************************/
    expected_campaign_runs,
    expected_comparison_groups,
    expected_total_active_campaign_source_rows,
    expected_validation_key_count,

    expected_product_guardrail_campaign_runs,
    audited_product_count,
    expected_product_guardrail_policy_rows,

    /***********************************************************************************************
    Registry and archive readiness.
    ***********************************************************************************************/
    active_campaign_registry_rows,
    duplicate_active_campaign_technical_key_rows,

    active_comparison_registry_rows,
    duplicate_active_comparison_group_rows,

    active_campaign_registry_rows_for_archive_check,
    active_runs_missing_module1_source_count,
    active_runs_with_module1_source_application_id_grain_issue,
    active_runs_with_archive_rows,
    active_runs_missing_archive_rows,
    total_active_campaign_archived_rows,
    active_runs_with_archive_row_count_mismatch,
    active_runs_with_archive_application_id_grain_issue,
    duplicate_archive_grain_count,

    /***********************************************************************************************
    Comparison and source-consistency readiness.
    ***********************************************************************************************/
    comparison_group_count,
    comparison_ready_count,
    comparison_review_count,

    source_consistency_group_count,
    source_consistency_pass_count,
    source_consistency_review_count,
    total_source_field_mismatch_rows,

    /***********************************************************************************************
    Evidence readiness.
    ***********************************************************************************************/
    registry_run_count_for_evidence_check,

    executive_evidence_rows,
    executive_evidence_complete_run_count,
    executive_evidence_issue_run_count,

    parameter_snapshot_rows,
    parameter_snapshot_single_row_run_count,
    parameter_snapshot_row_count_issue_run_count,

    registry_run_count_for_parameter_snapshot_check,
    parameter_snapshot_ready_run_count,
    parameter_snapshot_issue_run_count,

    validation_evidence_complete_run_count,
    validation_evidence_incomplete_run_count,
    min_validation_rows_per_run,
    max_validation_rows_per_run,
    total_validation_evidence_rows,

    segment_evidence_complete_run_count,
    segment_evidence_issue_run_count,
    min_expected_segment_rows_per_run,
    max_expected_segment_rows_per_run,
    min_segment_rows_per_run,
    max_segment_rows_per_run,
    total_segment_evidence_rows,

    /***********************************************************************************************
    Final-output convention readiness.

    These fields now mirror Section 17.9 and keep MANUAL_REVIEW NULL conventions separate from
    DECLINE zero-exposure conventions.
    ***********************************************************************************************/
    active_campaign_archived_rows,
    critical_convention_violation_count,

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

    option_c_archive_field_gap_rows,
    aggressive_override_reason_trace_gap_rows,
    selective_strategy_aggressive_override_rows,

    /***********************************************************************************************
    Option C evidence readiness.
    ***********************************************************************************************/
    option_c_evidence_run_count,
    option_c_executive_evidence_gap_rows,
    selective_strategy_aggressive_override_evidence_issue_rows,
    aggressive_strategy_missing_override_evidence_rows,

    /***********************************************************************************************
    Product guardrail exact-value audit.
    ***********************************************************************************************/
    product_guardrail_campaign_run_count,
    product_guardrail_audited_product_count,
    product_guardrail_expected_policy_rows,
    product_guardrail_parameter_snapshot_complete_run_count,
    product_guardrail_parameter_snapshot_issue_run_count,
    product_guardrail_policy_ready_rows,
    missing_product_guardrail_policy_rows,
    product_guardrail_policy_row_count_issue_rows,
    product_guardrail_policy_mismatch_rows,

    /***********************************************************************************************
    Acceptance flags.
    ***********************************************************************************************/
    campaign_registry_ready_flag,
    comparison_registry_ready_flag,
    archive_ready_flag,
    comparison_ready_flag,
    source_consistency_ready_flag,
    evidence_ready_flag,
    parameter_snapshot_ready_flag,
    final_output_conventions_ready_flag,
    option_c_evidence_ready_flag,
    product_guardrail_policy_ready_flag

FROM acceptance_status;
```

Expected result after rerun:

```text
module2_campaign_acceptance_status = MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS
structural_acceptance_ready_flag = true
acceptance_review_focus = ALL_FINAL_ACCEPTANCE_GATES_PASSED
critical_convention_violation_count = 0
final_output_conventions_ready_flag = true
```

If this still returns a nonzero `critical_convention_violation_count`, the individual convention columns now exposed in the final output will show exactly which convention family is driving it.
<!-- END_MESSAGE C040-M02250 -->


---

<a id="c040-m02251"></a>

### C040-M02251

**Andrew** · 2026-05-21T15:37:03.573000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02251 -->
i am in a brand new session.  when i tried to run updated 17.20 , i received this error message: SQL Error [42703]: ERROR: column "aggressive_counteroffer_requested_structure_override_enabled" does not exist
  Position: 50113
  ERROR: column "aggressive_counteroffer_requested_structure_override_enabled" does not exist
  Position: 50113
<!-- END_MESSAGE C040-M02251 -->


---

<a id="c040-m02255"></a>

### C040-M02255

**ChatGPT** · 2026-05-21T15:41:29.673672-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02255 -->
This is **not a new-session/temp-table issue**. It is a **column-name mismatch inside the patched 17.20 block**.

The column:

```sql
aggressive_counteroffer_requested_structure_override_enabled
```

does **not** exist in the archive. The actual Option C field set uses:

```sql
severe_requested_structure_counteroffer_override_enabled
```

as the enablement/control field, and:

```sql
aggressive_counteroffer_requested_structure_override_flag
```

as the row-level aggressive override evidence flag. The archived/validated Option C field family is consistent with that naming: `counteroffer_strategy_variant`, `aggressive_counteroffer_expansion_enabled`, `severe_requested_structure_counteroffer_override_enabled`, the exposure/PTI/EL override enablement fields, `ordinary_counteroffer_candidate_flag`, and `aggressive_counteroffer_requested_structure_override_flag`. fileciteturn26file5 The archive-level Option C gap checks also use that same field family. fileciteturn26file10

## Exact fix

In **Section 17.20**, inside `convention_counts`, find this part:

```sql
        COUNT(*) FILTER (
            WHERE counteroffer_strategy_variant IS NULL
               OR aggressive_counteroffer_expansion_enabled IS NULL
               OR ordinary_counteroffer_candidate_flag IS NULL
               OR aggressive_counteroffer_requested_structure_override_flag IS NULL
               OR aggressive_counteroffer_requested_structure_override_enabled IS NULL
               OR exposure_extreme_counteroffer_override_enabled IS NULL
               OR requested_pti_decline_counteroffer_override_enabled IS NULL
               OR requested_el_decline_counteroffer_override_enabled IS NULL
               OR exposure_policy_stop_counteroffer_override_enabled IS NULL
               OR severe_requested_structure_counteroffer_override_enabled IS NULL
        ) AS option_c_archive_field_gap_rows,
```

Replace it with this:

```sql
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
```

That should resolve the immediate error.

## Better replacement for the whole Option C subsection in 17.20

To reduce the chance of a second mismatch, replace the entire **“Option C field persistence and reason traceability”** subsection inside `convention_counts` with this:

```sql
        /*******************************************************************************************
        Option C field persistence and reason traceability.

        Field naming boundary:
            severe_requested_structure_counteroffer_override_enabled
                = strategy-control enablement field.

            aggressive_counteroffer_requested_structure_override_flag
                = row-level evidence that the applicant entered counteroffer feasibility through the
                  aggressive requested-structure override path.

        There is no archive column named:
            aggressive_counteroffer_requested_structure_override_enabled
        *******************************************************************************************/
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
                    triggered_reason_code_list IS NULL
                 OR (
                        decision_outcome = 'COUNTEROFFER'
                    AND triggered_reason_code_list NOT LIKE
                            '%COUNTEROFFER_AGGRESSIVE_REQUESTED_STRUCTURE_OVERRIDE%'
                    )
                 OR (
                        decision_outcome = 'MANUAL_REVIEW'
                    AND triggered_reason_code_list NOT LIKE
                            '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
                 OR (
                        decision_outcome = 'DECLINE'
                    AND triggered_reason_code_list NOT LIKE
                            '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                    )
              )
        ) AS aggressive_override_reason_trace_gap_rows,

        COUNT(*) FILTER (
            WHERE strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY'
              AND aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS selective_strategy_aggressive_override_rows
```

## Optional quick confirmation

Run this to confirm the archive column names:

```sql
SELECT
    column_name
FROM information_schema.columns
WHERE table_schema = 'credit_decisioning_sim'
  AND table_name = 'strategy_decisions_archive'
  AND (
        column_name LIKE '%counteroffer%override%'
     OR column_name IN (
            'counteroffer_strategy_variant',
            'aggressive_counteroffer_expansion_enabled',
            'ordinary_counteroffer_candidate_flag'
        )
  )
ORDER BY column_name;
```

You should see:

```text
aggressive_counteroffer_requested_structure_override_flag
aggressive_counteroffer_expansion_enabled
exposure_extreme_counteroffer_override_enabled
exposure_policy_stop_counteroffer_override_enabled
ordinary_counteroffer_candidate_flag
requested_el_decline_counteroffer_override_enabled
requested_pti_decline_counteroffer_override_enabled
severe_requested_structure_counteroffer_override_enabled
```

## Rerun guidance

Since you are in a brand-new session:

```text
Apply the 17.20 patch.
Run 17.20 again.
```

You do **not** need to rerun Section 15 or Section 16.9 for this specific error because 17.20 reads persistent archive/evidence tables. Section 17 is the final read-only acceptance layer after campaign completion, Section 15 rerun, and Section 16.9 synchronization. fileciteturn24file18
<!-- END_MESSAGE C040-M02255 -->


---

<a id="c040-m02256"></a>

### C040-M02256

**Andrew** · 2026-05-22T07:57:25.209000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02256 -->
how long should I expect section 17.20 to run?  for perspective, the entire section 1 to 16.8 was runn ing in about 8 minutes.
<!-- END_MESSAGE C040-M02256 -->


---

<a id="c040-m02258"></a>

### C040-M02258

**ChatGPT** · 2026-05-22T08:01:55.453756-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02258 -->
Given your local runtime benchmark, I would expect **Section 17.20 to run somewhere around 2–8 minutes** on a normal local PostgreSQL/DBeaver setup.

It would not surprise me if it runs **10–15 minutes** on a cold cache or slower machine. I would start investigating only if it is still running after **20–30 minutes**, especially if PostgreSQL is not showing CPU or disk activity.

Section 17.20 is read-only, but it is not trivial. It is the final one-row campaign acceptance rollup after the completed archive, Section 15 rerun, and Section 16.9 synchronization. Section 17 is designed to review persistent archive, registry, comparison, validation, evidence, parameter-snapshot, product-policy, and acceptance objects rather than create new strategy output. fileciteturn26file18

The heavy parts are:

```text
1. Archive counts over 1,950,000 rows
2. Active archive final-output convention checks over 1,950,000 rows
3. Comparison readiness across 20 active comparison groups
4. Matched source-field consistency across 20 comparison groups
5. Evidence completeness checks across 39 runs
6. Product-guardrail exact-value JSONB audit
```

The product-guardrail and evidence checks are small. The real cost is the archive scan and matched comparison source-field logic.

Given your campaign shape:

```text
39 runs × 50,000 rows = 1,950,000 archive rows
20 comparison groups × 50,000 matched applications ≈ 1,000,000 matched comparison pairs
```

So Section 17.20 is doing less than a full rerun, but it is scanning and joining enough data that it can feel “long” compared with ordinary QA outputs.

## Practical guidance

I would treat runtime like this:

```text
< 2 minutes:
    Fast / excellent.

2–8 minutes:
    Normal and expected.

8–15 minutes:
    Still plausible, especially in a new session with cold cache.

15–30 minutes:
    Worth monitoring, but not automatically broken.

> 30 minutes:
    Check for lock waits, missing indexes, or a bad plan.
```

Because you are in a **brand-new session**, the first execution may be slower because PostgreSQL has not warmed the relevant archive pages into memory.

## Quick monitor query

In a separate SQL tab, you can run:

```sql
SELECT
    pid,
    state,
    wait_event_type,
    wait_event,
    now() - query_start AS runtime,
    LEFT(query, 250) AS query_snippet
FROM pg_stat_activity
WHERE datname = current_database()
  AND state <> 'idle'
ORDER BY query_start;
```

Interpretation:

```text
state = active
wait_event_type is NULL or normal IO-related:
    Let it run.

wait_event_type = Lock:
    It may be blocked by another session.

runtime > 30 minutes and little/no CPU or IO activity:
    Investigate before waiting much longer.
```

## Bottom line

For your setup, I would **not worry before 10 minutes**. I would **start checking around 15–20 minutes**. If it reaches **30+ minutes**, run the monitor query and look for lock waits or an unusually expensive plan.
<!-- END_MESSAGE C040-M02258 -->


---

<a id="c040-m02260"></a>

### C040-M02260

**Andrew** · 2026-05-22T08:41:11.826000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02260 -->
55 minutes - still says active
<!-- END_MESSAGE C040-M02260 -->


**Attachments in export:** `image(80).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02263"></a>

### C040-M02263

**ChatGPT** · 2026-05-22T08:45:08.357624-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02263 -->
At **55 minutes with `state = active` and `wait_event_type = NULL`**, I would stop it. That does **not** look like a lock wait. It looks like PostgreSQL is actively working through an expensive plan, most likely in the 17.20 comparison/source-consistency or archive-convention CTEs.

Section 17 is the final read-only campaign acceptance layer after the full campaign, Section 15 rerun, and Section 16.9 synchronization, so it should be reviewing persistent objects — not hanging on temp-table dependencies. fileciteturn26file18

## Recommended action

Cancel the running backend, add performance support indexes, analyze the tables, then rerun 17.20.

Use `pg_cancel_backend`, not `pg_terminate_backend`, first.

```sql
SELECT pg_cancel_backend(9404);
```

If it does not cancel after a minute or two, then use:

```sql
SELECT pg_terminate_backend(9404);
```

## Run this performance support block before rerunning 17.20

These indexes are safe, practical final-acceptance support indexes. They target the expensive parts of 17.20: archive slice matching, active registry joins, evidence joins, and matched comparison source-field checks.

```sql
/***************************************************************************************************
SECTION 17.20 PERFORMANCE SUPPORT INDEXES
****************************************************************************************************

PURPOSE:
    Add practical indexes for final campaign acceptance review.

WHY THIS EXISTS:
    Section 17.20 performs archive-wide and comparison-wide read-only acceptance checks across:

        active campaign registry rows,
        active comparison registry rows,
        1,950,000 active campaign archive rows,
        20 matched comparison groups,
        persistent executive evidence,
        validation evidence,
        parameter snapshots,
        and product × score segment evidence.

    Without the right indexes, PostgreSQL may choose expensive repeated scans or nested loops.

BOUNDARY:
    These indexes do not change campaign data.
    They do not modify decisions, archive rows, evidence rows, reason codes, or parameter snapshots.
    They only improve read performance for final acceptance review.

RUN TIMING:
    Run after the campaign is complete and before rerunning Section 17.20.
****************************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_m2_arc_key_app
ON credit_decisioning_sim.strategy_decisions_archive (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id
);

CREATE INDEX IF NOT EXISTS idx_m2_arc_key
ON credit_decisioning_sim.strategy_decisions_archive (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_arc_m1_app
ON credit_decisioning_sim.strategy_decisions_archive (
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    application_id
);

CREATE INDEX IF NOT EXISTS idx_m2_m1_archive_key_app
ON credit_decisioning_sim.synthetic_applications_scenario_archive (
    scenario_set_name,
    scenario_name,
    population_id,
    application_id
);

CREATE INDEX IF NOT EXISTS idx_m2_run_reg_active_key
ON credit_decisioning_sim.strategy_run_campaign_registry (
    registry_active_flag,
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_run_reg_active_id
ON credit_decisioning_sim.strategy_run_campaign_registry (
    registry_active_flag,
    module2_run_id
);

CREATE INDEX IF NOT EXISTS idx_m2_cmp_reg_active_group
ON credit_decisioning_sim.strategy_comparison_campaign_registry (
    registry_active_flag,
    comparison_group_id
);

CREATE INDEX IF NOT EXISTS idx_m2_cmp_reg_active_base
ON credit_decisioning_sim.strategy_comparison_campaign_registry (
    registry_active_flag,
    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_cmp_reg_active_chal
ON credit_decisioning_sim.strategy_comparison_campaign_registry (
    registry_active_flag,
    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_ev_sum_key
ON credit_decisioning_sim.strategy_run_evidence_summary (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_val_ev_key
ON credit_decisioning_sim.strategy_run_validation_evidence (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_param_snap_key
ON credit_decisioning_sim.strategy_run_parameter_snapshot (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

CREATE INDEX IF NOT EXISTS idx_m2_seg_ev_key
ON credit_decisioning_sim.strategy_run_segment_evidence_summary (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);

ANALYZE credit_decisioning_sim.strategy_decisions_archive;
ANALYZE credit_decisioning_sim.synthetic_applications_scenario_archive;
ANALYZE credit_decisioning_sim.strategy_run_campaign_registry;
ANALYZE credit_decisioning_sim.strategy_comparison_campaign_registry;
ANALYZE credit_decisioning_sim.strategy_run_evidence_summary;
ANALYZE credit_decisioning_sim.strategy_run_validation_evidence;
ANALYZE credit_decisioning_sim.strategy_run_parameter_snapshot;
ANALYZE credit_decisioning_sim.strategy_run_segment_evidence_summary;
```

Then rerun **17.20 only**.

## Optional session setting before rerun

If your local machine has reasonable memory, run this before 17.20:

```sql
SET work_mem = '256MB';
```

If you want a guardrail so it does not run indefinitely again:

```sql
SET statement_timeout = '20min';
```

You can reset later with:

```sql
RESET statement_timeout;
RESET work_mem;
```

## Expected runtime after indexes

After the indexes and `ANALYZE`, I would expect 17.20 to run much faster, likely:

```text
1–5 minutes: good
5–10 minutes: still plausible
> 15 minutes: investigate again
```

If it still runs beyond 15 minutes after indexing, the next move should be to split 17.20 into materialized temp helper tables so PostgreSQL does not repeatedly re-plan or rescan the heavy CTEs.
<!-- END_MESSAGE C040-M02263 -->


---

<a id="c040-m02264"></a>

### C040-M02264

**Andrew** · 2026-05-22T09:23:53.091000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02264 -->
let's go ahead and split 17.20 into materialized temp helper tables so PostgreSQL does not repeatedly re-plan or rescan the heavy CTEs.  please give me a full updated 17.20 copy paste.  here is the current 17.20 for reference.
<!-- END_MESSAGE C040-M02264 -->


**Attachments in export:** `Pasted text(224).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_04.md) · [Next](Part_06.md)
