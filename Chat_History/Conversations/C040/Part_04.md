# Campaign QA and strategy expansion

## Part 04

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_03.md) · [Next](Part_05.md)

<a id="c040-m02071"></a>

### C040-M02071

**ChatGPT** · 2026-05-19T21:42:58.183783-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02071 -->
## M2-02 Section 13 refined QA review — remaining outputs

```text
Remaining Section 13 refined QA status: PASS
Full M2-02 Section 13 status: ACCEPTED
Selected comparison: CG01 — Baseline vs Tighter Synthetic Risk
Baseline: M2-01 / BASELINE_STRATEGY
Challenger: M2-02 / TIGHTER_SYNTHETIC_RISK_STRATEGY
Matched application_id count: 50,000
Source-field consistency: SOURCE_FIELDS_MATCH
Option C aggressive override movement: correctly NOT_APPLICABLE
True blockers: none
Further refinements recommended: none
```

Section 13 is behaving correctly as the archive-backed matched comparison framework. It reads completed archived baseline/challenger slices, matches rows by `application_id`, compares downstream Module 2 strategy movement, and separately validates that immutable Module 1 source fields are unchanged. fileciteturn13file29

The refined Section 13 outputs now look preservation-ready.

---

## 13.8A — Primary reason-code distribution by comparison side

```text
Status: PASS
Refinement status: accepted
```

Rows reconcile cleanly:

```text
BASELINE      50,000
CHALLENGER    50,000
total        100,000
```

Reason-family movement is coherent for tighter synthetic-risk discipline:

```text
APPROVAL
    baseline = 10,695
    challenger = 10,086
    delta = -609

COUNTEROFFER
    baseline = 19,067
    challenger = 18,452
    delta = -615

MANUAL_REVIEW
    baseline = 7,535
    challenger = 6,580
    delta = -955

POLICY_STOP
    baseline = 12,703
    challenger = 14,882
    delta = +2,179
```

Largest reason-code movement:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK
    baseline = 6,369
    challenger = 8,623
    delta = +2,254
```

Other meaningful movements:

```text
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW
    delta = +569

COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
    delta = +211

APPROVED_AS_REQUESTED
    delta = -609

MANUAL_REVIEW_FAILED_COUNTEROFFER
    delta = -972

COUNTEROFFER_EXPECTED_LOSS_LIMIT
    delta = -518
```

This is exactly the expected reason-code story for M2-02: tighter synthetic-risk thresholds shift rows away from approvals / counteroffers / manual review and toward synthetic-risk-driven policy stop or review.

No issue.

---

## 13.8B — Primary reason-code migration matrix

```text
Status: PASS
Refinement status: accepted
```

Rows reconcile:

```text
row_count sum = 50,000
changed reason-code rows = 4,637
stable reason-code rows = 45,363
```

Largest stable rows:

```text
APPROVED_AS_REQUESTED → APPROVED_AS_REQUESTED                      10,086
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT → same                          8,905
POLICY_STOP_SEVERE_SYNTHETIC_RISK → same                            6,369
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT → same                        4,682
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK → same                         2,967
POLICY_STOP_SEVERE_DELINQUENCY → same                               2,955
```

Key changed movements:

```text
MANUAL_REVIEW_FAILED_COUNTEROFFER
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    986 rows

COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
    → MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW
    886 rows

MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    613 rows

APPROVED_AS_REQUESTED
    → COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
    564 rows

COUNTEROFFER_EXPECTED_LOSS_LIMIT
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    448 rows
```

This is coherent and useful for storytelling: the challenger does not randomly reshuffle explanations. It shifts reason codes toward synthetic-risk review and synthetic-risk policy stop.

No issue.

---

## 13.8C — Option C aggressive override reason-code movement diagnostic

```text
Status: PASS
Refinement status: accepted
```

The new one-row `NOT_APPLICABLE` behavior is working.

Current status:

```text
OPTION_C_AGGRESSIVE_OVERRIDE_REASON_CODE_MOVEMENT_NOT_APPLICABLE
```

Interpretation note is clear:

```text
No aggressive override reason-code movement exists for this selected comparison.
This is expected for non-Option-C-split comparisons such as baseline versus tighter synthetic-risk.
```

All aggressive override reason-trace fields are zero:

```text
matched_rows = 0
baseline_counteroffer_aggressive_override_reason_rows = 0
challenger_counteroffer_aggressive_override_reason_rows = 0
baseline_manual_review_aggressive_failure_reason_rows = 0
challenger_manual_review_aggressive_failure_reason_rows = 0
baseline_decline_aggressive_failure_reason_rows = 0
challenger_decline_aggressive_failure_reason_rows = 0
```

This is exactly right for CG01 because both strategies are:

```text
NOT_COUNTEROFFER_SPLIT_STRATEGY
```

No issue.

---

## 13.8D — Product × reason-code movement

```text
Status: PASS
```

Rows reconcile:

```text
row_count sum = 50,000
output rows = 139
```

Changed reason-code movement by product:

```text
MORTGAGE                    1,456
REVOLVING_LINE              1,076
AUTO_LOAN                     981
UNSECURED_PERSONAL_LOAN       640
HELOC                         484
```

Top changed movements remain directionally coherent:

```text
REVOLVING_LINE
    MANUAL_REVIEW_FAILED_COUNTEROFFER
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    355 rows

MORTGAGE
    COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
    → MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW
    340 rows

MORTGAGE
    MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    241 rows

MORTGAGE
    COUNTEROFFER_EXPECTED_LOSS_LIMIT
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    200 rows

AUTO_LOAN
    MANUAL_REVIEW_FAILED_COUNTEROFFER
    → POLICY_STOP_SEVERE_SYNTHETIC_RISK
    197 rows
```

This supports the product-level story from batch 1: mortgage and revolving-line segments are important drivers of reason-code movement under tighter synthetic-risk discipline.

No issue.

---

## 13.9A — Simulated offer-exposure flag transition

```text
Status: PASS
Refinement status: accepted
```

Rows reconcile:

```text
row_count sum = 50,000
```

Offer transition profile:

```text
NO_OFFER_EXPOSURE_BOTH       19,679   39.36%
OFFER_EXPOSURE_RETAINED      27,979   55.96%
OFFER_EXPOSURE_REMOVED        1,783    3.57%
OFFER_EXPOSURE_GAINED           559    1.12%
```

Net offer movement:

```text
offer exposure removed = 1,783
offer exposure gained = 559
net offer exposure change = -1,224 rows
```

That reconciles with the overall portfolio delta:

```text
delta_simulated_offer_exposure_rate = -0.02448
```

The route-boundary interpretation note is helpful and accurate. It prevents overreading the 559 offer-gained rows as a contradiction. The net effect remains tighter.

Exposure / EL effects are coherent:

```text
OFFER_EXPOSURE_REMOVED
    delta approved amount = -189.318M
    delta approved EL = -7.980M

OFFER_EXPOSURE_GAINED
    delta approved amount = +40.386M
    delta approved EL = +0.764M

OFFER_EXPOSURE_RETAINED
    delta approved amount = -0.347M
    delta approved EL = -0.008M
```

No issue.

---

## 13.9B — Approved exposure movement by decision migration type

```text
Status: PASS
Refinement status: accepted
```

Rows reconcile:

```text
row_count sum = 50,000
```

Decision migration exposure movement:

```text
OFFER_TO_NO_OFFER_OR_UNRESOLVED_RISK_TIGHTENING
    rows = 1,783
    delta_total_approved_amount = -189.318M
    avg_delta_approved_amount = -106,179.42

NO_OFFER_OR_UNRESOLVED_TO_OFFER_ACCESS_EXPANSION
    rows = 559
    delta_total_approved_amount = +40.386M
    avg_delta_approved_amount = +72,245.97

APPROVE_TO_COUNTEROFFER_EXPOSURE_REDUCTION
    rows = 569
    delta_total_approved_amount = -0.347M
    avg_delta_approved_amount = -609.08

MANUAL_REVIEW_TO_DECLINE_NO_OFFER_TIGHTENING
    rows = 1,599
    delta_total_approved_amount = 0

STABLE_OUTCOME
    rows = 45,490
    delta_total_approved_amount = 0
```

The neutralized migration label is now accepted:

```text
MANUAL_REVIEW_TO_DECLINE_NO_OFFER_TIGHTENING
```

That label fits M2-02 much better than the previous “review burden reduction” wording.

No issue.

---

## 13.9C — Approved Expected Loss movement by decision migration type

```text
Status: PASS
Refinement status: accepted
```

Rows reconcile:

```text
row_count sum = 50,000
```

The Expected Loss naming is now clear:

```text
approved_expected_loss_capture_rate = approved EL / requested EL
approved_el_per_approved_dollar = approved EL / approved amount
```

Expected Loss movement:

```text
OFFER_TO_NO_OFFER_OR_UNRESOLVED_RISK_TIGHTENING
    rows = 1,783
    delta_total_approved_expected_loss_amount = -7.980M
    avg_delta_approved_expected_loss_amount = -4,475.67
    delta_approved_expected_loss_capture_rate = -0.799958

NO_OFFER_OR_UNRESOLVED_TO_OFFER_ACCESS_EXPANSION
    rows = 559
    delta_total_approved_expected_loss_amount = +0.764M
    avg_delta_approved_expected_loss_amount = +1,367.22
    delta_approved_expected_loss_capture_rate = +0.979244

APPROVE_TO_COUNTEROFFER_EXPOSURE_REDUCTION
    rows = 569
    delta_total_approved_expected_loss_amount = -0.008M
    avg_delta_approved_expected_loss_amount = -14.59
    delta_approved_expected_loss_capture_rate = -0.014160

MANUAL_REVIEW_TO_DECLINE_NO_OFFER_TIGHTENING
    rows = 1,599
    delta_total_approved_expected_loss_amount = 0

STABLE_OUTCOME
    rows = 45,490
    delta_total_approved_expected_loss_amount = 0
```

This is a strong comparison result: M2-02 removes far more approved Expected Loss through offer removals than it adds through local offer gains.

No issue.

---

## 13.10A — Matched source-field consistency output

```text
Status: PASS
```

This is the most important governance control in the remaining batch, and it passes cleanly:

```text
readiness_status = READY_FOR_MATCHED_COMPARISON
matched_application_count = 50,000
source_field_mismatch_count = 0
source_consistency_status = SOURCE_FIELDS_MATCH
```

All source mismatch counts are zero:

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
module1_lineage_mismatch_count = 0
```

This proves the comparison is isolating downstream Module 2 strategy effects, not Module 1 source-population drift.

No issue.

---

## 13.10B — Source field mismatch sample

```text
Status: PASS / expected empty
```

The sample is empty because:

```text
source_field_mismatch_count = 0
```

This is the correct result.

No issue.

---

## 13.11 — Compact comparison readiness recap

```text
Status: PASS
Refinement status: accepted
```

The compact recap is clean:

```text
comparison_group_id = CG01
comparison_set_name = Baseline vs Tighter Synthetic Risk
baseline_module2_run_id = M2-01
challenger_module2_run_id = M2-02

baseline_archived_row_count = 50,000
challenger_archived_row_count = 50,000
matched_application_id_count = 50,000
baseline_only_application_id_count = 0
challenger_only_application_id_count = 0

readiness_status = READY_FOR_MATCHED_COMPARISON
source_field_mismatch_count = 0
source_consistency_status = SOURCE_FIELDS_MATCH

section_13_comparison_status =
SECTION_13_READY_FOR_MATCHED_COMPARISON_INTERPRETATION
```

Option C posture remains correctly not applicable:

```text
baseline_counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
challenger_counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY

baseline_aggressive_counteroffer_expansion_enabled = false
challenger_aggressive_counteroffer_expansion_enabled = false

baseline_aggressive_override_rows = 0
challenger_aggressive_override_rows = 0

section_13_option_c_counteroffer_path_status =
OPTION_C_NOT_APPLICABLE_NON_COUNTEROFFER_SPLIT_STRATEGY
```

Ordinary counteroffer movement is coherent:

```text
baseline_ordinary_counteroffer_candidate_rows = 21,286
challenger_ordinary_counteroffer_candidate_rows = 19,699
challenger_new_ordinary_counteroffer_candidate_rows = 1,161

baseline_ordinary_counteroffer_candidate_rate = 0.425720
challenger_ordinary_counteroffer_candidate_rate = 0.393980
```

Interpretation:

```text
M2-02 reduces ordinary counteroffer candidacy overall, but local route-boundary changes still create
some new ordinary counteroffer candidates.
```

The new interpretation note explains that correctly.

No issue.

---

# Final full M2-02 Section 13 refined QA signoff

```text
M2-02 Section 13 refined QA: ACCEPTED

CG01 comparison selector is correct.
Both archive slices are present and valid.
Matched application_id count = 50,000.
Source-field consistency = SOURCE_FIELDS_MATCH.
Portfolio-level deltas are coherent.
Decision migration reconciles.
Reason-code movement reconciles.
Product and product × score movement are coherent.
Offer-exposure transition is coherent.
Approved exposure movement is coherent.
Approved Expected Loss movement is coherent.
Option C aggressive override reason-code movement is correctly NOT_APPLICABLE.
Compact readiness recap is clean.
No further Section 13 refinements recommended.
```

## Executive interpretation of CG01

```text
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY reduces approved exposure and approved Expected Loss
by tightening offer eligibility and shifting more rows into synthetic-risk-driven review or policy stop.

The tradeoff is:
    lower offer exposure,
    lower approved amount,
    lower approved Expected Loss,
    lower offered-population synthetic-risk profile,
    and higher decline rate.
```

This is preservation-ready for the first real matched Module 2 comparison.
<!-- END_MESSAGE C040-M02071 -->


---

<a id="c040-m02073"></a>

### C040-M02073

**Andrew** · 2026-05-19T22:08:42.180000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02073 -->
review key preservation queries from m2-02
<!-- END_MESSAGE C040-M02073 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8B_QA_current_run_executive_evidence_summary_row_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.13_QA_section_12_readiness_summary_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8G_QA_option_c_executive_evidence_review_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8F_QA_registry_linkage_consistency_diagnostic_across_evidence_tables_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8E_QA_parameter_snapshot_diagnostic_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8D_QA_current_run_product_x_score_segment_evidence_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation_m2_02.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02084"></a>

### C040-M02084

**ChatGPT** · 2026-05-19T22:18:35.481876-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02084 -->
## M2-02 key preservation query review verdict

```text
M2-02 key preservation package status: PASS
Archive readiness: PASS
Section 15 frontier evidence: PASS
Section 16 evidence capture: PASS
Registry linkage: PASS
Option C baseline/tighter-risk posture: correctly not applicable
True blockers: none
Recommended minor preservation polish: yes, two narrative notes
Missing recommended key export: 16.7 local evidence capture gatekeepers
```

The attached key preservation outputs are doing what we wanted: they preserve the post-run evidence without requiring the full M2-02 QA set. Section 12 proves archive persistence, Section 15 preserves archive-backed frontier context, and Section 16 preserves executive evidence, validation evidence, segment evidence, parameter snapshot, and registry linkage. Section 13 has already been preserved separately for M2-02 as the first full matched comparison proof package. fileciteturn13file31turn13file23turn13file19turn13file29

---

## 12.8.13 — Section 12 archive readiness summary

```text
Status: PASS
```

M2-02 archived cleanly:

```text
strategy_name = TIGHTER_SYNTHETIC_RISK_STRATEGY
latest_run_row_count = 50,000
latest_run_distinct_application_count = 50,000
archive_inserted_rows = 50,000
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
current_archived_slice_null_archive_ts_rows = 0
duplicate_archive_grain_count = 0
```

Option C persistence checks are clean:

```text
option_c_latest_run_archive_gap_count = 0
option_c_archive_reason_trace_gap_count = 0
aggressive_override_archived_rows = 0
```

Readiness status:

```text
SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA
```

The archive-wide row count moved from 50,000 to 100,000, which is correct because M2-01 and M2-02 are now both archived.

---

## 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
```

This output now shows the first meaningful two-row frontier:

```text
M2-01 BASELINE_STRATEGY
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
```

M2-02 is correctly classified:

```text
frontier_position_type = RISK_DISCIPLINE_FRONTIER_POINT
executive_frontier_quadrant = LOWER_ACCESS_LOWER_APPROVED_EL_RATE
```

M2-02 metrics:

```text
applications = 50,000
approval_rate = 0.201720
counteroffer_rate = 0.369040
manual_review_rate = 0.131600
decline_rate = 0.297640
simulated_offer_exposure_rate = 0.570760
```

M2-02 expected-loss evidence:

```text
total_approved_expected_loss_amount = 51.328M
approved_expected_loss_capture_rate = 0.214371
approved_el_per_approved_dollar = 0.013955
```

Baseline-relative movement:

```text
delta_approval_rate = -0.012180
delta_counteroffer_rate = -0.012300
delta_manual_review_rate = -0.019100
delta_decline_rate = +0.043580
delta_simulated_offer_exposure_rate = -0.024480
delta_total_approved_amount = -149.279M
delta_total_approved_expected_loss_amount = -7.224M
delta_approved_expected_loss_capture_rate = -0.030172
delta_approved_el_per_approved_dollar = -0.001343
```

Reason-code delta driver:

```text
top_reason_code_delta_driver_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK
top_reason_code_delta_population_share = 0.045080
```

This preserves the intended CG01 story very well:

```text
Tighter synthetic-risk discipline reduces approved exposure and approved Expected Loss,
improves the offered-population synthetic-risk profile, and increases declines.
```

---

## 15.8D — Frontier registry linkage diagnostic

```text
Status: PASS
```

Registry linkage is clean:

```text
executive_frontier_rows = 2
registry_matched_rows = 2
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0
registry_linkage_status = FRONTIER_REGISTRY_LINKAGE_READY
```

This confirms both frontier rows are registry-linked.

---

## 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS, with minor narrative-polish recommendation
```

The one-row `NOT_APPLICABLE` export is working:

```text
option_c_frontier_diagnostic_status =
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

That is correct because the archive currently contains:

```text
M2-01 BASELINE_STRATEGY
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
```

and no selective or aggressive Option C strategy rows yet.

Minor polish: the interpretation note still says this is expected for a “single M2-01 baseline archive.” That was true during the M2-01 review, but M2-02 is now archived too. I would update the note later to say:

```text
No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive.
This is expected until selective or aggressive Option C strategy runs are archived.
```

This is not a blocker. It is preservation wording only.

---

## 16.8B — Current-run executive evidence summary row

```text
Status: PASS
```

This is the most important M2-02 preservation row, and it is clean.

Identity and registry linkage:

```text
module1_run_id = M1-01
module2_run_id = M2-02
run_sequence_number = 2
showcase_id = SC01
comparison_group_id = CG01
validation_evidence_group_id = VE02
run_registry_match_status = RUN_REGISTRY_MATCHED
```

Story metadata:

```text
readme_storyline_label = Tighter synthetic-risk challenger
validation_summary_section_hint = Tighter risk evidence
module2_strategy_family_changed = RISK_DISCIPLINE
```

Observed storyline is appropriate:

```text
Strategy reduces simulated offer exposure and approved Expected Loss while improving
offered-population synthetic estimated-risk profile.
```

Core run metrics:

```text
applications = 50,000
approval_rate = 0.201720
counteroffer_rate = 0.369040
manual_review_rate = 0.131600
decline_rate = 0.297640
simulated_offer_exposure_rate = 0.570760
```

Exposure / Expected Loss:

```text
total_requested_amount = 6.666B
total_approved_amount = 3.678B
approved_amount_capture_rate = 0.551717

total_requested_expected_loss_amount = 239.433M
total_approved_expected_loss_amount = 51.328M
approved_expected_loss_capture_rate = 0.214371
approved_el_per_approved_dollar = 0.013955
approved_amount_per_approved_expected_loss_dollar = 71.657405
```

Reason-code story:

```text
top_primary_reason_code = APPROVED_AS_REQUESTED
top_non_approval_primary_reason_code = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
top_policy_stop_primary_reason_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK

top_reason_code_delta_driver_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK
top_reason_code_delta_population_share = 0.045080
```

Validation evidence captured:

```text
validation_pass_count = 18
validation_review_count = 1
validation_not_applicable_count = 3
```

Option C posture:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
ordinary_counteroffer_candidate_rows = 19,699
ordinary_counteroffer_candidate_rate = 0.393980
delta_ordinary_counteroffer_candidate_rate = -0.031740
aggressive_override_rows = 0
```

This is preservation-ready.

---

## 16.8C — Current-run validation items requiring interpretation

```text
Status: PASS, with minor narrative-polish recommendation
```

The output contains:

```text
REVIEW = 1
NOT_APPLICABLE = 3
```

The single `REVIEW` row is expected:

```text
EDGE_CASE_VISIBILITY
mixed_signal_profile_rate = 0.351660
borderline_profile_rate = 0.397320
```

That is a documentation-readiness flag, not a core validation issue.

The three `NOT_APPLICABLE` rows are all Option C-related:

```text
Aggressive override reason-code traceability
Latest-run aggressive override behavior
Matched comparison Option C context
```

For CG01, that is correct because M2-02 is not an Option C split strategy.

Minor polish: the matched-comparison Option C row still says:

```text
Section 13 matched-row context exists but does not expose the Option C comparison fields.
Rerun Section 13 after Option C patches if matched Option C comparison evidence is needed.
```

That wording is a little stale. The better preservation wording would be:

```text
The selected comparison is ready, but both sides are NOT_COUNTEROFFER_SPLIT_STRATEGY;
matched Option C aggressive movement is therefore not applicable for CG01.
```

This is not a blocker. The status is still correct.

---

## 16.8D — Current-run product × score segment evidence

```text
Status: PASS
```

The segment evidence captured the expected full grid:

```text
segment rows = 25
applications sum = 50,000
product count = 5
score-band count = 5
```

Segment behavior is coherent under M2-02:

```text
MORTGAGE_PRIME
    applications = 4,285
    simulated_offer_exposure_rate = 0.793232
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

MORTGAGE_NEAR_PRIME
    applications = 3,644
    simulated_offer_exposure_rate = 0.626784
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

REVOLVING_LINE_NEAR_PRIME
    applications = 3,025
    simulated_offer_exposure_rate = 0.786777
    top reason = COUNTEROFFER_ELEVATED_SYNTHETIC_RISK

MORTGAGE_SUBPRIME
    applications = 2,639
    decline_rate = 0.931034
    top reason = POLICY_STOP_SEVERE_SYNTHETIC_RISK
```

The clarified Expected Loss fields are present:

```text
approved_expected_loss_capture_rate
approved_el_per_approved_dollar
legacy_approved_expected_loss_rate
```

No issue.

---

## 16.8E — Parameter snapshot diagnostic

```text
Status: PASS
```

The parameter snapshot captured correctly:

```text
strategy_params_captured_flag = true
product_policy_params_captured_flag = true
run_story_params_captured_flag = true
```

Registry metadata is correct:

```text
module1_run_id = M1-01
module2_run_id = M2-02
run_sequence_number = 2
showcase_id = SC01
comparison_group_id = CG01
validation_evidence_group_id = VE02
run_registry_match_status = RUN_REGISTRY_MATCHED
```

Parameter snapshot hash is populated:

```text
parameter_snapshot_hash = d2f528a0460771514f0c97975030a2ea
```

No issue.

---

## 16.8F — Registry linkage consistency across evidence tables

```text
Status: PASS
```

All four evidence tables are registry-linked:

```text
strategy_run_evidence_summary             1 row
strategy_run_parameter_snapshot           1 row
strategy_run_segment_evidence_summary    25 rows
strategy_run_validation_evidence         22 rows
```

All objects show:

```text
module2_run_id = M2-02
run_registry_match_status = RUN_REGISTRY_MATCHED
validation_evidence_group_id = VE02
missing_critical_registry_field_rows = 0
registry_linkage_status = REGISTRY_LINKAGE_CAPTURED
```

This is a strong preservation control.

---

## 16.8G — Option C executive evidence review

```text
Status: PASS
```

M2-02 Option C posture is correct:

```text
strategy_name = TIGHTER_SYNTHETIC_RISK_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

Ordinary counteroffer evidence:

```text
ordinary_counteroffer_candidate_rows = 19,699
ordinary_counteroffer_candidate_rate = 0.393980
delta_ordinary_counteroffer_candidate_rate = -0.031740
```

Aggressive override evidence:

```text
aggressive_override_rows = 0
aggressive_override_rate = 0
delta_aggressive_override_rate = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
```

The shortened aggressive-override metric aliases are clean and appropriately NULL:

```text
avg_agr_ovr_co_exposure_reduction_pct = NULL
avg_agr_ovr_co_approved_pti = NULL
avg_agr_ovr_co_approved_el = NULL
```

No issue.

---

# Overall M2-02 preservation package signoff

```text
M2-02 key preservation queries: ACCEPTED

Archive persistence summary: PASS
Frontier executive summary: PASS
Frontier registry linkage: PASS
Option C frontier diagnostic: PASS
Executive evidence summary: PASS
Validation interpretation items: PASS
Product × score segment evidence: PASS
Parameter snapshot: PASS
Evidence-table registry linkage: PASS
Option C executive evidence: PASS
```

## Important note: one recommended export is missing

I do **not** see the **16.7 local evidence capture gatekeepers** CSV in this batch. You did include 16.8F, which confirms the same four evidence table footprints, but I would still preserve 16.7 because it is the explicit local Section 16 gatekeeper output.

Recommended additional export:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.7_QA_local_evidence_capture_gatekeepers_m2_02.csv
```

If you want the leanest package possible, 16.8F is enough to prove registry-linked evidence capture. But since 16.7 was part of the key preservation pack, I would include it for consistency.

---

## Minor wording polish to consider later

No logic changes are needed, but I would eventually polish two comments/status interpretations:

```text
15.8E:
    Replace “single M2-01 baseline archive” with a more general “no selective/aggressive Option C
    rows are archived yet” note.

16.8C:
    Replace the schema-not-available / rerun-Section-13 wording with:
    “CG01 is not an Option C split comparison, so matched Option C movement is not applicable.”
```

These are not blockers. The M2-02 preservation outputs are good enough to save now.
<!-- END_MESSAGE C040-M02084 -->


---

<a id="c040-m02086"></a>

### C040-M02086

**Andrew** · 2026-05-19T22:24:11.947000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02086 -->
here is the code you provided earlier and it does not output 16.7.  also - are you suggesting changes to 15.8E and 16.8C with these comments?  if so - let me know the exact changes to make (full copy paste please): 15.8E:
    Replace “single M2-01 baseline archive” with a more general “no selective/aggressive Option C
    rows are archived yet” note.

16.8C:
    Replace the schema-not-available / rerun-Section-13 wording with:
    “CG01 is not an Option C split comparison, so matched Option C movement is not applicable.”
<!-- END_MESSAGE C040-M02086 -->


**Attachments in export:** `module2_post_run_preservation_key_queries_original_headers(1).sql`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02110"></a>

### C040-M02110

**ChatGPT** · 2026-05-19T22:37:59.473104-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02110 -->
You’re right on both points.

First: **16.7 is not an export query** in the code I provided. It is a PL/pgSQL `DO $$ ... END $$;` gatekeeper, so DBeaver will not produce a result grid / CSV from it. My earlier comment that you were “missing the 16.7 export” was imprecise. The post-run preservation pack does include the 16.7 gatekeeper block, but it does not output rows by design. fileciteturn13file0

I recommend adding a companion export query called:

```text
16.7A — Local evidence capture gatekeeper export
```

That gives you a CSV-ready row while preserving the 16.7 gatekeeper concept.

Second: yes, I am recommending small wording changes to:

```text
15.8E
16.8C
```

These are **preservation/narrative polish only**, not logic fixes.

I updated the post-run preservation query pack here:

[Download updated post-run preservation query pack](sandbox:/mnt/data/module2_post_run_preservation_key_queries_original_headers_UPDATED.sql)

---

# 1. Add this new 16.7A export query after the 16.7 gatekeeper block

Place this immediately after:

```text
END OF SECTION 16.7 — LOCAL EVIDENCE CAPTURE GATEKEEPERS
```

and before:

```text
SECTION 16.8B — CURRENT RUN EXECUTIVE EVIDENCE SUMMARY ROW
```

```sql
/***************************************************************************************************
SECTION 16.7A — LOCAL EVIDENCE CAPTURE GATEKEEPER EXPORT
****************************************************************************************************

PURPOSE:
    Provide an exportable one-row summary of the Section 16.7 local evidence capture gatekeepers.

BUSINESS PURPOSE:
    Section 16.7 is a PL/pgSQL fail-fast gatekeeper. It raises exceptions when current-run evidence
    capture is incomplete, but it does not naturally return a result set for CSV preservation.

    This companion export keeps the same evidence-capture logic visible for post-run preservation.

INTERPRETATION:
    Expected status:
        SECTION_16_LOCAL_EVIDENCE_CAPTURE_READY

    This confirms the current run has:
        one executive evidence row,
        complete validation evidence rows,
        one parameter snapshot,
        complete product × score segment evidence rows,
        populated registry linkage,
        populated parameter JSONB payloads,
        and populated Option C executive evidence fields.

BOUNDARY:
    This query reads persistent evidence tables and current-run temporary helpers only.

    It does not insert evidence rows.
    It does not update evidence rows.
    It does not delete evidence rows.
    It does not recalculate decisions, approved exposure, approved Expected Loss, or reason codes.
***************************************************************************************************/

WITH k AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
),

story AS (
    SELECT *
    FROM tmp_m2_current_run_story_params
    LIMIT 1
),

expected_validation AS (
    SELECT COUNT(*) AS expected_validation_rows
    FROM tmp_m2_validation_status_summary
),

expected_segments AS (
    SELECT
        COUNT(DISTINCT (
            sd.product_type_policy_key,
            sd.score_band_policy_key,
            sd.product_score_policy_segment
        )) AS expected_segment_rows
    FROM credit_decisioning_sim.strategy_decisions sd
    JOIN k
        ON sd.strategy_set_name = k.strategy_set_name
       AND sd.strategy_name = k.strategy_name
       AND sd.strategy_version = k.strategy_version
       AND sd.module1_scenario_set_name = k.module1_scenario_set_name
       AND sd.module1_scenario_name = k.module1_scenario_name
       AND sd.population_id = k.population_id
),

executive_evidence AS (
    SELECT
        COUNT(*) AS executive_evidence_rows,

        COUNT(*) FILTER (
            WHERE e.module1_run_id IS NULL
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
               OR e.counteroffer_strategy_variant IS NULL
               OR e.aggressive_counteroffer_expansion_enabled IS NULL
               OR e.ordinary_counteroffer_candidate_rows IS NULL
               OR e.aggressive_override_rows IS NULL
               OR e.option_c_frontier_posture_type IS NULL
        ) AS executive_required_field_gap_rows,

        COUNT(*) FILTER (
            WHERE e.module2_run_id IS DISTINCT FROM s.module2_run_id
               OR e.validation_evidence_group_id IS DISTINCT FROM s.validation_evidence_group_id
               OR e.run_registry_match_status IS DISTINCT FROM s.run_registry_match_status
        ) AS executive_registry_alignment_gap_rows

    FROM credit_decisioning_sim.strategy_run_evidence_summary e
    JOIN k
        ON e.strategy_set_name = k.strategy_set_name
       AND e.strategy_name = k.strategy_name
       AND e.strategy_version = k.strategy_version
       AND e.module1_scenario_set_name = k.module1_scenario_set_name
       AND e.module1_scenario_name = k.module1_scenario_name
       AND e.population_id = k.population_id
    CROSS JOIN story s
),

validation_evidence AS (
    SELECT
        COUNT(*) AS validation_evidence_rows,

        COUNT(DISTINCT (
            v.validation_area,
            v.validation_test_name,
            v.validation_category
        )) AS validation_distinct_key_count,

        COUNT(*) FILTER (
            WHERE v.module1_run_id IS NULL
               OR v.module2_run_id IS NULL
               OR v.validation_evidence_group_id IS NULL
               OR v.run_registry_match_status IS NULL
               OR v.validation_area IS NULL
               OR v.validation_test_name IS NULL
               OR v.validation_category IS NULL
               OR v.validation_status IS NULL
        ) AS validation_required_field_gap_rows,

        COUNT(*) FILTER (
            WHERE v.module2_run_id IS DISTINCT FROM s.module2_run_id
               OR v.validation_evidence_group_id IS DISTINCT FROM s.validation_evidence_group_id
               OR v.run_registry_match_status IS DISTINCT FROM s.run_registry_match_status
        ) AS validation_registry_alignment_gap_rows

    FROM credit_decisioning_sim.strategy_run_validation_evidence v
    JOIN k
        ON v.strategy_set_name = k.strategy_set_name
       AND v.strategy_name = k.strategy_name
       AND v.strategy_version = k.strategy_version
       AND v.module1_scenario_set_name = k.module1_scenario_set_name
       AND v.module1_scenario_name = k.module1_scenario_name
       AND v.population_id = k.population_id
    CROSS JOIN story s
),

parameter_snapshot AS (
    SELECT
        COUNT(*) AS parameter_snapshot_rows,

        COUNT(*) FILTER (
            WHERE p.strategy_params_jsonb IS NULL
               OR p.product_policy_params_jsonb IS NULL
               OR p.run_story_params_jsonb IS NULL
               OR p.parameter_snapshot_hash IS NULL
        ) AS parameter_snapshot_payload_gap_rows,

        COUNT(*) FILTER (
            WHERE p.module2_run_id IS DISTINCT FROM s.module2_run_id
               OR p.validation_evidence_group_id IS DISTINCT FROM s.validation_evidence_group_id
               OR p.run_registry_match_status IS DISTINCT FROM s.run_registry_match_status
        ) AS parameter_registry_alignment_gap_rows

    FROM credit_decisioning_sim.strategy_run_parameter_snapshot p
    JOIN k
        ON p.strategy_set_name = k.strategy_set_name
       AND p.strategy_name = k.strategy_name
       AND p.strategy_version = k.strategy_version
       AND p.module1_scenario_set_name = k.module1_scenario_set_name
       AND p.module1_scenario_name = k.module1_scenario_name
       AND p.population_id = k.population_id
    CROSS JOIN story s
),

segment_evidence AS (
    SELECT
        COUNT(*) AS segment_evidence_rows,

        COUNT(*) FILTER (
            WHERE sg.product_type_policy_key IS NULL
               OR sg.score_band_policy_key IS NULL
               OR sg.product_score_policy_segment IS NULL
               OR sg.applications IS NULL
               OR sg.top_primary_reason_code IS NULL
        ) AS segment_required_field_gap_rows,

        COUNT(*) FILTER (
            WHERE sg.module2_run_id IS DISTINCT FROM s.module2_run_id
               OR sg.validation_evidence_group_id IS DISTINCT FROM s.validation_evidence_group_id
               OR sg.run_registry_match_status IS DISTINCT FROM s.run_registry_match_status
        ) AS segment_registry_alignment_gap_rows

    FROM credit_decisioning_sim.strategy_run_segment_evidence_summary sg
    JOIN k
        ON sg.strategy_set_name = k.strategy_set_name
       AND sg.strategy_name = k.strategy_name
       AND sg.strategy_version = k.strategy_version
       AND sg.module1_scenario_set_name = k.module1_scenario_set_name
       AND sg.module1_scenario_name = k.module1_scenario_name
       AND sg.population_id = k.population_id
    CROSS JOIN story s
)

SELECT
    'Section 16.7 is a fail-fast PL/pgSQL gatekeeper; this companion export provides a CSV-ready one-row summary of the same current-run evidence capture footprint.'::TEXT
        AS interpretation_note,

    s.module1_run_id,
    s.module2_run_id,
    s.run_sequence_number,
    s.showcase_id,
    s.showcase_name,
    s.comparison_group_id,
    s.validation_evidence_group_id,
    s.run_registry_match_status,

    k.strategy_set_name,
    k.strategy_name,
    k.strategy_version,
    k.module1_scenario_set_name,
    k.module1_scenario_name,
    k.population_id,

    ex.executive_evidence_rows,
    ex.executive_required_field_gap_rows,
    ex.executive_registry_alignment_gap_rows,

    ve.validation_evidence_rows,
    ev.expected_validation_rows,
    ve.validation_distinct_key_count,
    ve.validation_required_field_gap_rows,
    ve.validation_registry_alignment_gap_rows,

    ps.parameter_snapshot_rows,
    ps.parameter_snapshot_payload_gap_rows,
    ps.parameter_registry_alignment_gap_rows,

    se.segment_evidence_rows,
    es.expected_segment_rows,
    se.segment_required_field_gap_rows,
    se.segment_registry_alignment_gap_rows,

    CASE
        WHEN ex.executive_evidence_rows = 1
         AND ex.executive_required_field_gap_rows = 0
         AND ex.executive_registry_alignment_gap_rows = 0
         AND ve.validation_evidence_rows = ev.expected_validation_rows
         AND ve.validation_distinct_key_count = ev.expected_validation_rows
         AND ve.validation_required_field_gap_rows = 0
         AND ve.validation_registry_alignment_gap_rows = 0
         AND ps.parameter_snapshot_rows = 1
         AND ps.parameter_snapshot_payload_gap_rows = 0
         AND ps.parameter_registry_alignment_gap_rows = 0
         AND se.segment_evidence_rows = es.expected_segment_rows
         AND se.segment_required_field_gap_rows = 0
         AND se.segment_registry_alignment_gap_rows = 0
            THEN 'SECTION_16_LOCAL_EVIDENCE_CAPTURE_READY'
        ELSE 'REVIEW_SECTION_16_LOCAL_EVIDENCE_CAPTURE'
    END AS section_16_local_evidence_capture_status

FROM k
CROSS JOIN story s
CROSS JOIN expected_validation ev
CROSS JOIN expected_segments es
CROSS JOIN executive_evidence ex
CROSS JOIN validation_evidence ve
CROSS JOIN parameter_snapshot ps
CROSS JOIN segment_evidence se;
```

Export name:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.7A_QA_local_evidence_capture_gatekeeper_export_m2_02.csv
```

---

# 2. Exact 15.8E wording change

In **15.8E**, replace only this line:

```sql
        'No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive. This is expected for a single M2-01 baseline archive and should not be treated as an Option C failure.'::TEXT
            AS interpretation_note,
```

with this:

```sql
        'No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive. This is expected until selective or aggressive Option C strategy runs are archived and should not be treated as an Option C failure.'::TEXT
            AS interpretation_note,
```

That wording works for M2-01, M2-02, and every non-Option-C run before the selective/aggressive Option C strategy rows are archived.

---

# 3. Replace 16.8C with this updated version

This leaves the query logic intact but overrides the stale Option C matched-comparison interpretation when the selected Section 13 comparison is ready but the comparison is not an Option C split comparison.

```sql
/***************************************************************************************************
SECTION 16.8C — CURRENT RUN VALIDATION ITEMS REQUIRING INTERPRETATION
****************************************************************************************************

PURPOSE:
    Display validation evidence rows with REVIEW or NOT_APPLICABLE status for the current run.

BUSINESS PURPOSE:
    Identify the exact validation evidence rows that should be discussed before documentation.

VALIDATION STATUS INTERPRETATION:
    REVIEW:
        The pattern should be interpreted before documentation.

        REVIEW does not automatically mean the strategy run is invalid.

    NOT_APPLICABLE:
        The test depended on unavailable comparison setup, unavailable archive slices, or conditions
        not present in the current run context.

IMPORTANT:
    REVIEW and NOT_APPLICABLE are not automatic failures.

    They are prompts for validation narrative, evidence review, and documentation discipline.

REGISTRY PATCH:
    Validation rows include module2_run_id and validation_evidence_group_id so each item can be
    carried directly into the future Validation Summary.

WHAT TO LOOK FOR:
    validation_area:
        The broad area of the validation framework.

    validation_test_name:
        The specific check or diagnostic.

    observed_value:
        The evidence value captured from Section 14.

    expected_behavior:
        The intended interpretation boundary or expectation.

    interpretation:
        Plain-English guidance for reviewers.

REFINEMENT NOTE:
    For Option C matched-comparison context, this export clarifies the difference between:

        comparison not ready
            The selected Section 13 comparison is missing one side.

        comparison ready but not Option C split
            The comparison exists, but baseline/challenger strategies are not selective/aggressive
            Option C counteroffer split strategies.

    The latter is the expected CG01 posture for M2-01 versus M2-02.

REVIEW TRIGGERS:
    High manual-review rate:
        Explain operational burden and failed-counteroffer resolution behavior.

    High counteroffer concentration:
        Explain reduced-exposure treatment and product / affordability drivers.

    High reason-code concentration:
        Explain whether the concentration is expected for the selected strategy.

    Comparison not ready:
        Explain missing baseline / challenger readiness before writing comparison claims.

SQL MECHANICS:
    JOIN to k:
        Restricts persistent validation evidence to the current run key.

    WHERE validation_status IN (...):
        Shows only the rows requiring interpretation or context.

    ORDER BY:
        Places REVIEW rows before NOT_APPLICABLE rows.

BOUNDARY:
    This query reads persisted validation evidence only.

    It does not rerun Section 14 validation logic.

***************************************************************************************************/

WITH k AS (
    /***********************************************************************************************
    Current run key.

    Used to scope the persistent validation evidence table to the current completed run.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
)

SELECT
    /***********************************************************************************************
    Campaign registry / validation evidence linkage.

    These fields let each validation row be tied directly to the formal campaign run and Validation
    Summary evidence group.
    ***********************************************************************************************/
    e.module1_run_id,
    e.module2_run_id,
    e.run_sequence_number,
    e.showcase_id,
    e.showcase_name,
    e.comparison_group_id,
    e.validation_evidence_group_id,
    e.validation_summary_section_hint,
    e.run_registry_match_status,

    /***********************************************************************************************
    Validation evidence detail.

    These are the fields most directly reusable in a future written Validation Summary.
    ***********************************************************************************************/
    e.validation_area,
    e.validation_test_name,
    e.validation_category,
    e.validation_status,
    e.observed_value,
    e.expected_behavior,

    CASE
        WHEN e.validation_area = 'Option C counteroffer split'
         AND e.validation_test_name = 'Matched comparison Option C context'
         AND e.validation_status = 'NOT_APPLICABLE'
         AND e.observed_value LIKE '%comparison_readiness_status=READY_FOR_MATCHED_COMPARISON%'
            THEN 'The selected Section 13 comparison is ready, but this is not an Option C counteroffer split comparison; matched Option C aggressive movement is therefore not applicable for this comparison.'

        WHEN e.validation_area = 'Option C counteroffer split'
         AND e.validation_test_name = 'Matched comparison Option C context'
         AND e.validation_status = 'NOT_APPLICABLE'
         AND e.observed_value LIKE '%comparison_readiness_status=NOT_READY%'
            THEN 'Option C matched-comparison context is not applicable because the selected Section 13 comparison is not ready; archive the missing comparison slice and rerun Section 13 before interpreting matched Option C movement.'

        ELSE e.interpretation
    END AS interpretation

FROM credit_decisioning_sim.strategy_run_validation_evidence e

JOIN k
    ON e.strategy_set_name = k.strategy_set_name
   AND e.strategy_name = k.strategy_name
   AND e.strategy_version = k.strategy_version
   AND e.module1_scenario_set_name = k.module1_scenario_set_name
   AND e.module1_scenario_name = k.module1_scenario_name
   AND e.population_id = k.population_id

WHERE e.validation_status IN ('REVIEW', 'NOT_APPLICABLE')

ORDER BY
    CASE e.validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        ELSE 99
    END,
    e.validation_area,
    e.validation_test_name;
```

---

## Bottom line

For the lean preservation pack, I would now save:

```text
12.8.13
15.7A
15.8D
15.8E
16.7A
16.8B
16.8C
16.8D
16.8E
16.8F
16.8G
```

And for M2-02 specifically, continue saving the full Section 13 suite because it is the first complete matched comparison proof package.
<!-- END_MESSAGE C040-M02110 -->


---

<a id="c040-m02112"></a>

### C040-M02112

**Andrew** · 2026-05-19T22:44:25.787000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02112 -->
before adding that 16.7A as you call it, please note we already have this file being exported in the main 16.7 (see M2-01 version attached). we should align with the main code or update the main code.
<!-- END_MESSAGE C040-M02112 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.7_QA_local_evidence_capture_gatekeepers(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02130"></a>

### C040-M02130

**ChatGPT** · 2026-05-19T22:54:32.977578-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02130 -->
You are right. Do **not** add a new `16.7A`.

The file you attached is the existing evidence-object row-count export. In the main code, that output is the **Section 16.8A — Evidence Object Row-Count Diagnostic for Current Run** query, even though the exported filename says `16.7_QA_local_evidence_capture_gatekeepers`. Section 16.7 itself is the fail-fast gatekeeper; Section 16.8 displays export-ready diagnostics after the gatekeeper passes. That aligns with the Section 16 design: Section 16.0–16.8 captures run-level evidence, validates local capture, then displays compact export-ready diagnostics. fileciteturn13file19

So the right fix is:

```text
Do not add 16.7A.
Keep the main code’s existing 16.8A query.
Add that same 16.8A query to the post-run preservation pack.
Apply the 15.8E and 16.8C wording refinements in the main code and preservation pack.
```

I prepared the aligned files here:

[Download updated full Module 2 code with Section 15.8E / 16.8C wording aligned](sandbox:/mnt/data/module2_v1_0_latest_section13_section16_polish_aligned.txt)

[Download updated post-run preservation pack aligned to the main code](sandbox:/mnt/data/module2_post_run_preservation_key_queries_original_headers_ALIGNED.sql)

[Download standalone Section 16.8A export query copied from main code](sandbox:/mnt/data/section16_8A_export_query_from_main.sql)

[Download standalone Section 16.8C wording patch](sandbox:/mnt/data/section16_8C_option_c_interpretation_patch.sql)

[Download standalone Section 15.8E interpretation-note patch](sandbox:/mnt/data/section15_8E_interpretation_note_patch.sql)

## Exact 15.8E change

In **15.8E**, replace the old not-applicable interpretation note with this:

```sql
        'No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive. This is expected until selective or aggressive Option C strategy runs are archived and should not be treated as an Option C failure.'::TEXT
            AS interpretation_note,
```

This fixes the stale M2-01-only wording.

## Exact Section 16.8C change

Replace **16.8C** with the block in this file:

[Download standalone Section 16.8C wording patch](sandbox:/mnt/data/section16_8C_option_c_interpretation_patch.sql)

The important logic change is this `CASE` override:

```sql
    CASE
        WHEN e.validation_area = 'Option C counteroffer split'
         AND e.validation_test_name = 'Matched comparison Option C context'
         AND e.validation_status = 'NOT_APPLICABLE'
         AND e.observed_value LIKE '%comparison_readiness_status=READY_FOR_MATCHED_COMPARISON%'
            THEN 'The selected Section 13 comparison is ready, but this is not an Option C counteroffer split comparison; matched Option C aggressive movement is therefore not applicable for this comparison.'

        WHEN e.validation_area = 'Option C counteroffer split'
         AND e.validation_test_name = 'Matched comparison Option C context'
         AND e.validation_status = 'NOT_APPLICABLE'
         AND e.observed_value LIKE '%comparison_readiness_status=NOT_READY%'
            THEN 'Option C matched-comparison context is not applicable because the selected Section 13 comparison is not ready; archive the missing comparison slice and rerun Section 13 before interpreting matched Option C movement.'

        ELSE e.interpretation
    END AS interpretation
```

That preserves the M2-01 behavior and improves the M2-02 / CG01 behavior:

```text
M2-01:
    comparison not ready → not applicable because challenger missing

M2-02:
    comparison ready, but not Option C split → not applicable because CG01 is not an Option C comparison
```

## How to export the evidence gatekeeper going forward

Use the existing main-code query:

```text
SECTION 16.8A — EVIDENCE OBJECT ROW-COUNT DIAGNOSTIC FOR CURRENT RUN
```

Recommended export name:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8A_QA_evidence_object_row_count_diagnostic_for_current_run_m2_02.csv
```

If you prefer to preserve the old filename for continuity, that is fine:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.7_QA_local_evidence_capture_gatekeepers_m2_02.csv
```

But the cleaner long-term naming is `16.8A`, because that is the section header in the main code.

## Updated lean preservation list

Use this list for remaining runs:

```text
12.8.13
15.7A
15.8D
15.8E
16.8A
16.8B
16.8C
16.8D
16.8E
16.8F
16.8G
```

For M2-02 specifically, also keep the full Section 13 suite, as planned.
<!-- END_MESSAGE C040-M02130 -->


---

<a id="c040-m02131"></a>

### C040-M02131

**Andrew** · 2026-05-19T23:41:21.661000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02131 -->
review updated m2-02 key queries again
<!-- END_MESSAGE C040-M02131 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8E_QA_parameter_snapshot_diagnostic_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8D_QA_current_run_product_x_score_segment_evidence_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8B_QA_current_run_executive_evidence_summary_row_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8A_QA_evidence_object_row_count_diagnostic_for_current_run_m2_02.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.13_QA_section_12_readiness_summary_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8G_QA_option_c_executive_evidence_review_m2_02(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8F_QA_registry_linkage_consistency_diagnostic_across_evidence_tables_m2_02(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02138"></a>

### C040-M02138

**ChatGPT** · 2026-05-19T23:48:55.752259-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02138 -->
## M2-02 updated key preservation query review verdict

```text
M2-02 key preservation package status: PASS
Archive readiness: PASS
Frontier evidence: PASS
Evidence capture: PASS
Validation interpretation evidence: PASS
Parameter snapshot: PASS
Registry linkage: PASS
Option C posture: correctly not applicable
16.8A evidence object export: included and accepted
Blockers: none
Further refinements recommended: none
```

The updated preservation pack is now aligned with the main-code structure: Section 12 proves archive persistence, Section 15 preserves archive-backed frontier context, and Section 16 preserves persistent run-level evidence. Section 16.8A is now included as the exportable evidence-object row-count diagnostic, which is the right main-code-aligned replacement for the earlier `16.7` export concern. Section 16 is explicitly the run-level evidence capture layer, while Section 15 is the archive-backed frontier layer and Section 12 is the archive persistence layer. fileciteturn13file19 fileciteturn13file23 fileciteturn13file31

---

## 12.8.13 — Section 12 readiness summary

```text
Status: PASS
```

M2-02 archive persistence is clean:

```text
strategy_name = TIGHTER_SYNTHETIC_RISK_STRATEGY
latest_run_row_count = 50,000
latest_run_distinct_application_count = 50,000
archive_inserted_rows = 50,000
archive_row_count_before = 50,000
archive_row_count_after = 100,000
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
current_archived_slice_null_archive_ts_rows = 0
duplicate_archive_grain_count = 0
```

Option C archive fidelity checks are clean:

```text
option_c_latest_run_archive_gap_count = 0
option_c_archive_reason_trace_gap_count = 0
aggressive_override_archived_rows = 0
```

Final status:

```text
SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA
```

The `before_after_inventory_diff_count = 1` remains expected because M2-02 inserted a new archive slice, increasing the archive from 50,000 M2-01 rows to 100,000 total archived rows.

---

## 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
```

The frontier summary now correctly shows a two-row SC01 frontier:

```text
M2-01 BASELINE_STRATEGY
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
```

M2-02 is classified correctly:

```text
frontier_position_type = RISK_DISCIPLINE_FRONTIER_POINT
executive_frontier_quadrant = LOWER_ACCESS_LOWER_APPROVED_EL_RATE
```

M2-02 core metrics:

```text
applications = 50,000
approval_rate = 0.201720
counteroffer_rate = 0.369040
manual_review_rate = 0.131600
decline_rate = 0.297640
simulated_offer_exposure_rate = 0.570760
```

M2-02 economics:

```text
total_approved_amount = 3.678B
total_approved_expected_loss_amount = 51.328M
approved_expected_loss_capture_rate = 0.214371
approved_el_per_approved_dollar = 0.013955
```

Baseline-relative deltas are coherent:

```text
delta_approval_rate = -0.012180
delta_counteroffer_rate = -0.012300
delta_manual_review_rate = -0.019100
delta_decline_rate = +0.043580
delta_simulated_offer_exposure_rate = -0.024480
delta_total_approved_amount = -149.279M
delta_total_approved_expected_loss_amount = -7.224M
delta_approved_expected_loss_capture_rate = -0.030172
delta_approved_el_per_approved_dollar = -0.001343
```

Reason-code movement story is captured:

```text
top_reason_code_delta_driver_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK
top_reason_code_delta_population_share = 0.045080
```

This is preservation-ready and supports the M2-02 story: tighter synthetic-risk discipline reduces offer exposure, approved amount, and approved Expected Loss while increasing declines.

---

## 15.8D — Frontier registry linkage diagnostic

```text
Status: PASS
```

Registry linkage is clean:

```text
executive_frontier_rows = 2
registry_matched_rows = 2
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0
registry_linkage_status = FRONTIER_REGISTRY_LINKAGE_READY
```

This confirms both M2-01 and M2-02 frontier rows are registry-linked.

---

## 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS
Wording refinement: accepted
```

The updated general-purpose wording is now correct:

```text
No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive.
This is expected until selective or aggressive Option C strategy runs are archived and should not be treated as an Option C failure.
```

Diagnostic status:

```text
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

This is correct for the current archive state:

```text
M2-01 = BASELINE_STRATEGY
M2-02 = TIGHTER_SYNTHETIC_RISK_STRATEGY
```

No selective or aggressive Option C runs have been archived yet, so this one-row `NOT_APPLICABLE` diagnostic is exactly what we want for preservation.

---

## 16.8A — Evidence object row-count diagnostic for current run

```text
Status: PASS
New export included: yes
```

This resolves the earlier preservation-pack gap. The export shows the expected Section 16 evidence footprint:

```text
strategy_run_evidence_summary              1 row
strategy_run_parameter_snapshot            1 row
strategy_run_segment_evidence_summary     25 rows
strategy_run_validation_evidence          22 rows
```

Registry linkage is present:

```text
module1_run_id = M1-01
module2_run_id = M2-02
run_sequence_number = 2
showcase_id = SC01
comparison_group_id = CG01
validation_evidence_group_id = VE02
run_registry_match_status = RUN_REGISTRY_MATCHED
```

This is the right export to preserve instead of creating a new `16.7A`.

---

## 16.8B — Current-run executive evidence summary row

```text
Status: PASS
```

The executive evidence row is clean and preservation-ready.

Run identity:

```text
module2_run_id = M2-02
strategy_name = TIGHTER_SYNTHETIC_RISK_STRATEGY
run_sequence_number = 2
showcase_id = SC01
comparison_group_id = CG01
validation_evidence_group_id = VE02
```

Core metrics:

```text
applications = 50,000
approval_rate = 0.201720
counteroffer_rate = 0.369040
manual_review_rate = 0.131600
decline_rate = 0.297640
simulated_offer_exposure_rate = 0.570760
```

Expected Loss fields are clean and aligned with the terminology cleanup:

```text
total_requested_expected_loss_amount = 239.433M
total_approved_expected_loss_amount = 51.328M
approved_expected_loss_capture_rate = 0.214371
approved_el_per_approved_dollar = 0.013955
legacy_approved_expected_loss_rate = 0.013955
```

Validation rollup:

```text
validation_pass_count = 18
validation_review_count = 1
validation_not_applicable_count = 3
```

Frontier and reason-code story:

```text
frontier_position_type = RISK_DISCIPLINE_FRONTIER_POINT
executive_frontier_quadrant = LOWER_ACCESS_LOWER_APPROVED_EL_RATE
top_reason_code_delta_driver_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK
top_reason_code_delta_population_share = 0.045080
```

Option C posture remains correct:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
ordinary_counteroffer_candidate_rows = 19,699
ordinary_counteroffer_candidate_rate = 0.393980
delta_ordinary_counteroffer_candidate_rate = -0.031740
aggressive_override_rows = 0
```

No issue.

---

## 16.8C — Current-run validation items requiring interpretation

```text
Status: PASS
Wording refinement: accepted
```

The output now has the correct shape:

```text
REVIEW = 1
NOT_APPLICABLE = 3
```

The single `REVIEW` row is expected:

```text
EDGE_CASE_VISIBILITY
mixed_signal_profile_rate = 0.351660
borderline_profile_rate = 0.397320
```

The three `NOT_APPLICABLE` rows are Option C-related and correct for M2-02:

```text
Aggressive override reason-code traceability
Latest-run aggressive override behavior
Matched comparison Option C context
```

The updated matched-comparison interpretation is now correct for CG01:

```text
The selected Section 13 comparison is ready, but this is not an Option C counteroffer split comparison; matched Option C aggressive movement is therefore not applicable for this comparison.
```

This is much better than the old schema-oriented wording. It correctly distinguishes:

```text
comparison ready
but
not an Option C split comparison
```

No further change recommended.

---

## 16.8D — Current-run product × score segment evidence

```text
Status: PASS
```

The segment evidence captured the expected 25 product × score rows:

```text
segment rows = 25
applications sum = 50,000
```

The refined Expected Loss fields are present:

```text
approved_expected_loss_capture_rate
approved_el_per_approved_dollar
legacy_approved_expected_loss_rate
```

Segment behavior is coherent. Examples:

```text
MORTGAGE_NEAR_PRIME
    applications = 3,644
    simulated_offer_exposure_rate = 0.626784
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

MORTGAGE_PRIME
    applications = 4,285
    simulated_offer_exposure_rate = 0.793232
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

REVOLVING_LINE_NEAR_PRIME
    applications = 3,025
    simulated_offer_exposure_rate = 0.786777
    top reason = COUNTEROFFER_ELEVATED_SYNTHETIC_RISK

AUTO_LOAN_NEAR_PRIME
    applications = 2,390
    simulated_offer_exposure_rate = 0.760669
    top reason = COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
```

The five NULL `approved_el_per_approved_dollar` rows are expected zero-approved-exposure cells, not defects.

---

## 16.8E — Parameter snapshot diagnostic

```text
Status: PASS
```

The parameter snapshot captured successfully:

```text
strategy_params_captured_flag = true
product_policy_params_captured_flag = true
run_story_params_captured_flag = true
```

Registry identity is clean:

```text
module1_run_id = M1-01
module2_run_id = M2-02
run_sequence_number = 2
showcase_id = SC01
comparison_group_id = CG01
validation_evidence_group_id = VE02
run_registry_match_status = RUN_REGISTRY_MATCHED
```

Parameter snapshot hash is populated:

```text
parameter_snapshot_hash = ba7bb01530981ab186e9ccff03fdf0cb
```

No issue.

---

## 16.8F — Registry linkage consistency across evidence tables

```text
Status: PASS
```

All four evidence tables are linked cleanly:

```text
strategy_run_evidence_summary              1 row
strategy_run_parameter_snapshot            1 row
strategy_run_segment_evidence_summary     25 rows
strategy_run_validation_evidence          22 rows
```

All objects show:

```text
module2_run_id = M2-02
run_registry_match_status = RUN_REGISTRY_MATCHED
validation_evidence_group_id = VE02
missing_critical_registry_field_rows = 0
registry_linkage_status = REGISTRY_LINKAGE_CAPTURED
```

This is a clean evidence-governance pass.

---

## 16.8G — Option C executive evidence review

```text
Status: PASS
```

M2-02 Option C posture is correct:

```text
strategy_name = TIGHTER_SYNTHETIC_RISK_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

Ordinary counteroffer evidence:

```text
ordinary_counteroffer_candidate_rows = 19,699
ordinary_counteroffer_candidate_rate = 0.393980
delta_ordinary_counteroffer_candidate_rate = -0.031740
```

Aggressive override evidence is correctly inactive:

```text
aggressive_override_rows = 0
aggressive_override_rate = 0
delta_aggressive_override_rate = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
```

Short aliases are clean:

```text
avg_agr_ovr_co_exposure_reduction_pct = NULL
avg_agr_ovr_co_approved_pti = NULL
avg_agr_ovr_co_approved_el = NULL
```

No issue.

---

# Final updated M2-02 key preservation signoff

```text
M2-02 updated key preservation queries: ACCEPTED

12.8.13 archive readiness: PASS
15.7A executive frontier summary: PASS
15.8D frontier registry linkage: PASS
15.8E Option C frontier diagnostic: PASS
16.8A evidence object row-count diagnostic: PASS
16.8B executive evidence summary: PASS
16.8C validation interpretation items: PASS
16.8D product × score segment evidence: PASS
16.8E parameter snapshot: PASS
16.8F evidence registry linkage: PASS
16.8G Option C executive evidence: PASS

No blockers.
No missing recommended key export.
No stale M2-01-only 15.8E wording.
No stale schema-not-available 16.8C interpretation issue.
No further refinements recommended.
```

The updated M2-02 key preservation package is now clean and ready to save.
<!-- END_MESSAGE C040-M02138 -->


---

<a id="c040-m02139"></a>

### C040-M02139

**Andrew** · 2026-05-19T23:53:38.155000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02139 -->
thanks.  i also updated these two files for m2-01 since we had logic changes:
<!-- END_MESSAGE C040-M02139 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation(3).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02143"></a>

### C040-M02143

**ChatGPT** · 2026-05-19T23:57:12.091084-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02143 -->
## Updated M2-01 replacement files review

```text
M2-01 updated preservation files: ACCEPTED
15.8E wording update: PASS
16.8C interpretation update: PASS
Blockers: none
Further changes needed: none
```

Both updated M2-01 files are correct and should replace the older versions in your GitHub preservation package.

---

## 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS
```

The updated wording is now generalized correctly:

```text
No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive.
This is expected until selective or aggressive Option C strategy runs are archived and should not be treated as an Option C failure.
```

This fixes the stale M2-01-only language.

The diagnostic status remains correct:

```text
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

The row is also structurally correct for M2-01 preservation:

```text
applications = 0
ordinary_counteroffer_candidate_rows = 0
aggressive_override_rows = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
option_c_frontier_posture_type = OPTION_C_FRONTIER_NOT_APPLICABLE_FRONTIER_POINT
```

Important interpretation remains:

```text
This does not mean M2-01 had zero ordinary counteroffer candidates.
It means no selective/aggressive Option C frontier strategy rows are archived yet.
```

The standalone M2-01 evidence still correctly shows:

```text
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
```

Section 15 is the archive-wide strategy frontier layer, so this `NOT_APPLICABLE` row is the right preservation behavior until selective/aggressive Option C runs are archived. fileciteturn13file23

---

## 16.8C — Current-run validation items requiring interpretation

```text
Status: PASS
```

The updated M2-01 16.8C output has the expected six rows:

```text
REVIEW = 2
NOT_APPLICABLE = 4
```

The two `REVIEW` rows are expected and non-blocking:

```text
EDGE_CASE_VISIBILITY
    mixed_signal_profile_rate = 0.356200
    borderline_profile_rate = 0.405920

MATCHED_COMPARISON_READINESS
    readiness_status = NOT_READY_CHALLENGER_ARCHIVE_MISSING
    matched_application_id_count = 0
```

That is correct for the original M2-01 baseline preservation state: M2-01 is valid, but the selected comparison is not ready until the challenger slice exists.

The four `NOT_APPLICABLE` rows are also correct:

```text
MATCHED_SOURCE_CONSISTENCY
    not applicable because matched comparison is not ready

Option C aggressive override reason-code traceability
    not applicable because aggressive_override_rows = 0

Option C latest-run aggressive override behavior
    not applicable because M2-01 is NOT_COUNTEROFFER_SPLIT_STRATEGY

Option C matched comparison context
    not applicable because the selected Section 13 comparison is not ready
```

The updated interpretation for the matched Option C context is now correct for M2-01:

```text
Option C matched-comparison context is not applicable because the selected Section 13 comparison is not ready; archive the missing comparison slice and rerun Section 13 before interpreting matched Option C movement.
```

That is the right branch for M2-01. For M2-02, the other branch correctly says the comparison is ready but not an Option C split comparison. Section 16 is the persistent run-level evidence layer, and this output now preserves the correct validation interpretation context for the run. fileciteturn13file19

---

## Final preservation recommendation

Replace the older M2-01 versions with these two updated files:

```text
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic(2).csv

module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation(3).csv
```

For GitHub naming consistency, I would rename them without the parenthetical suffixes, for example:

```text
module2_M2-01_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic.csv

module2_M2-01_16.8C_QA_current_run_validation_items_requiring_interpretation.csv
```

Final status:

```text
M2-01 updated preservation replacements: ACCEPTED

15.8E stale wording fixed.
16.8C matched Option C interpretation fixed.
No additional M2-01 re-export required for these two logic changes.
```
<!-- END_MESSAGE C040-M02143 -->


---

<a id="c040-m02145"></a>

### C040-M02145

**Andrew** · 2026-05-20T00:16:36.963000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02145 -->
m2-03 key queries:
<!-- END_MESSAGE C040-M02145 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8E_QA_parameter_snapshot_diagnostic_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8D_QA_current_run_product_x_score_segment_evidence_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8B_QA_current_run_executive_evidence_summary_row_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8A_QA_evidence_object_row_count_diagnostic_for_current_run_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.13_QA_section_12_readiness_summary_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8G_QA_option_c_executive_evidence_review_m2_03.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8F_QA_registry_linkage_consistency_diagnostic_across_evidence_tables_m2_03.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02152"></a>

### C040-M02152

**ChatGPT** · 2026-05-20T00:22:49.431048-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02152 -->
## M2-03 key preservation query review verdict

```text
M2-03 key preservation package status: PASS
Run: M2-03 — GROWTH_ORIENTED_STRATEGY
Showcase: SC01 — Baseline Strategy Frontier
Comparison group: CG02
Archive readiness: PASS
Frontier evidence: PASS
Evidence capture: PASS
Validation interpretation evidence: PASS
Parameter snapshot: PASS
Registry linkage: PASS
Option C posture: correctly not applicable
Blockers: none
Further refinements recommended: none
```

The key preservation package is clean. Section 12 confirms archive persistence, Section 15 preserves the archive-backed frontier view, and Section 16 captures persistent run-level executive, validation, parameter, and segment evidence. fileciteturn13file31 fileciteturn13file23 fileciteturn13file19

---

## 12.8.13 — Section 12 archive readiness summary

```text
Status: PASS
```

M2-03 archived cleanly:

```text
strategy_name = GROWTH_ORIENTED_STRATEGY
latest_run_row_count = 50,000
latest_run_distinct_application_count = 50,000
archive_inserted_rows = 50,000
archive_row_count_before = 100,000
archive_row_count_after = 150,000
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
current_archived_slice_null_archive_ts_rows = 0
duplicate_archive_grain_count = 0
```

Option C archive checks are clean:

```text
option_c_latest_run_archive_gap_count = 0
option_c_archive_reason_trace_gap_count = 0
aggressive_override_archived_rows = 0
```

Final status:

```text
SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA
```

The archive movement is correct: the archive grew from 100,000 rows to 150,000 rows because M2-01, M2-02, and M2-03 are now archived.

---

## 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
```

The frontier summary now has three SC01 rows:

```text
M2-01 BASELINE_STRATEGY
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
M2-03 GROWTH_ORIENTED_STRATEGY
```

M2-03 is correctly classified:

```text
frontier_position_type = GROWTH_ORIENTED_FRONTIER_POINT
executive_frontier_quadrant = HIGH_ACCESS_HIGHER_APPROVED_EL_RATE
```

M2-03 core metrics:

```text
applications = 50,000
approval_rate = 0.273840
counteroffer_rate = 0.348660
manual_review_rate = 0.158060
decline_rate = 0.219440
simulated_offer_exposure_rate = 0.622500
```

Baseline-relative movement is coherent for a growth strategy:

```text
delta_approval_rate = +0.059940
delta_counteroffer_rate = -0.032680
delta_decline_rate = -0.034620
delta_total_approved_amount = +238.420M
delta_total_approved_expected_loss_amount = +8.675M
```

Expected Loss tradeoff:

```text
approved_expected_loss_capture_rate = 0.280775
approved_el_per_approved_dollar = 0.016535
```

Frontier ranking is directionally correct:

```text
offer_access_rank_desc = 1
approved_amount_rank_desc = 1
total_approved_expected_loss_rank_asc = 3
approved_el_per_approved_dollar_rank_asc = 3
```

That is exactly the growth story:

```text
M2-03 expands access and approved amount, but carries higher approved Expected Loss and higher approved EL per approved dollar than the baseline and tighter-risk challenger.
```

No issue.

---

## 15.8D — Frontier registry linkage diagnostic

```text
Status: PASS
```

Registry linkage is clean across the three frontier rows:

```text
executive_frontier_rows = 3
registry_matched_rows = 3
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0
registry_linkage_status = FRONTIER_REGISTRY_LINKAGE_READY
```

No issue.

---

## 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS
```

The one-row `NOT_APPLICABLE` behavior remains correct:

```text
option_c_frontier_diagnostic_status =
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

The interpretation note is now appropriately generalized:

```text
No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive.
This is expected until selective or aggressive Option C strategy runs are archived and should not be treated as an Option C failure.
```

This is correct because the currently archived runs are:

```text
M2-01 BASELINE_STRATEGY
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
M2-03 GROWTH_ORIENTED_STRATEGY
```

No selective/aggressive Option C strategy rows are archived yet. No issue.

---

## 16.8A — Evidence object row-count diagnostic for current run

```text
Status: PASS
```

The evidence footprint is exactly right:

```text
strategy_run_evidence_summary              1 row
strategy_run_parameter_snapshot            1 row
strategy_run_segment_evidence_summary     25 rows
strategy_run_validation_evidence          22 rows
```

Registry metadata is clean:

```text
module1_run_id = M1-01
module2_run_id = M2-03
run_sequence_number = 3
showcase_id = SC01
comparison_group_id = CG02
validation_evidence_group_id = VE03
run_registry_match_status = RUN_REGISTRY_MATCHED
```

No issue.

---

## 16.8B — Current-run executive evidence summary row

```text
Status: PASS
```

This is the primary M2-03 preservation row, and it is clean.

Identity:

```text
module2_run_id = M2-03
strategy_name = GROWTH_ORIENTED_STRATEGY
run_sequence_number = 3
showcase_id = SC01
comparison_group_id = CG02
validation_evidence_group_id = VE03
readme_storyline_label = Growth-oriented challenger
validation_summary_section_hint = Growth strategy evidence
module2_strategy_family_changed = GROWTH
```

Observed storyline:

```text
Strategy expands simulated offer exposure and approved amount with measurable approved Expected Loss tradeoff.
```

Core metrics:

```text
applications = 50,000
approval_rate = 0.273840
counteroffer_rate = 0.348660
manual_review_rate = 0.158060
decline_rate = 0.219440
simulated_offer_exposure_rate = 0.622500
```

Exposure / Expected Loss:

```text
total_approved_amount = 4.066B
total_approved_expected_loss_amount = 67.227M
approved_expected_loss_capture_rate = 0.280775
approved_el_per_approved_dollar = 0.016535
approved_amount_per_approved_expected_loss_dollar = 60.478
```

Reason-code movement:

```text
top_reason_code_delta_driver_code = APPROVED_AS_REQUESTED
top_reason_code_delta_population_share = 0.059940
```

That is the right growth-challenger signal: the primary delta driver is more approvals as requested.

Validation rollup:

```text
validation_pass_count = 18
validation_review_count = 1
validation_not_applicable_count = 3
```

Option C posture:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
ordinary_counteroffer_candidate_rows = 20,080
ordinary_counteroffer_candidate_rate = 0.401600
delta_ordinary_counteroffer_candidate_rate = -0.024120
aggressive_override_rows = 0
```

The ordinary counteroffer candidate rate declines versus baseline, which is coherent because the growth strategy increases approvals and shifts some rows out of counteroffer candidacy.

No issue.

---

## 16.8C — Current-run validation items requiring interpretation

```text
Status: PASS
```

The output contains the expected shape:

```text
REVIEW = 1
NOT_APPLICABLE = 3
```

The single `REVIEW` row is expected:

```text
EDGE_CASE_VISIBILITY
mixed_signal_profile_rate = 0.340760
borderline_profile_rate = 0.389080
```

This is a documentation-readiness flag, not a validation failure.

The three `NOT_APPLICABLE` rows are Option C-related and correct for M2-03:

```text
Aggressive override reason-code traceability
Latest-run aggressive override behavior
Matched comparison Option C context
```

The matched-comparison Option C wording is also correct:

```text
The selected Section 13 comparison is ready, but this is not an Option C counteroffer split comparison; matched Option C aggressive movement is therefore not applicable for this comparison.
```

No issue.

---

## 16.8D — Current-run product × score segment evidence

```text
Status: PASS
```

The segment grid captured correctly:

```text
segment rows = 25
applications sum = 50,000
products = 5
score bands = 5
```

The refined Expected Loss fields are present:

```text
approved_expected_loss_capture_rate
approved_el_per_approved_dollar
legacy_approved_expected_loss_rate
```

Segment behavior is coherent for a growth strategy. Top approved-amount segments are mortgage-heavy:

```text
MORTGAGE_PRIME
    applications = 4,285
    simulated_offer_exposure_rate = 0.834306
    total_approved_amount = 1.285B
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

MORTGAGE_SUPER_PRIME
    applications = 2,747
    simulated_offer_exposure_rate = 0.893702
    total_approved_amount = 1.044B
    top reason = APPROVED_AS_REQUESTED

MORTGAGE_NEAR_PRIME
    applications = 3,644
    simulated_offer_exposure_rate = 0.803238
    total_approved_amount = 773.375M
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
```

Top approved-Expected-Loss segments are also intuitive:

```text
MORTGAGE_NEAR_PRIME
    total_approved_expected_loss_amount = 21.780M

MORTGAGE_PRIME
    total_approved_expected_loss_amount = 12.424M

MORTGAGE_SUBPRIME
    total_approved_expected_loss_amount = 6.150M

HELOC_NEAR_PRIME
    total_approved_expected_loss_amount = 3.881M

MORTGAGE_SUPER_PRIME
    total_approved_expected_loss_amount = 3.543M
```

Deep-subprime rows remain appropriately decline-heavy, though growth creates a small amount of positive offer exposure in some deep-subprime non-mortgage cells:

```text
AUTO_LOAN_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.007258
    decline_rate = 0.968548

REVOLVING_LINE_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.006640
    decline_rate = 0.962815

UNSECURED_PERSONAL_LOAN_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.005605
    decline_rate = 0.983184

HELOC_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.001502
    decline_rate = 0.972973

MORTGAGE_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.000000
    decline_rate = 0.996571
```

That is acceptable for a growth-oriented strategy because the exposure remains tiny and the decline concentration remains very high.

No issue.

---

## 16.8E — Parameter snapshot diagnostic

```text
Status: PASS
```

Parameter snapshot captured correctly:

```text
strategy_params_captured_flag = true
product_policy_params_captured_flag = true
run_story_params_captured_flag = true
```

Registry linkage is clean:

```text
module1_run_id = M1-01
module2_run_id = M2-03
run_sequence_number = 3
showcase_id = SC01
comparison_group_id = CG02
validation_evidence_group_id = VE03
run_registry_match_status = RUN_REGISTRY_MATCHED
```

Parameter snapshot hash is populated:

```text
parameter_snapshot_hash = 5f8e72799f81b047eb116e8e1b88b424
```

No issue.

---

## 16.8F — Registry linkage consistency across evidence tables

```text
Status: PASS
```

All four evidence objects are linked cleanly:

```text
strategy_run_evidence_summary              1 row
strategy_run_parameter_snapshot            1 row
strategy_run_segment_evidence_summary     25 rows
strategy_run_validation_evidence          22 rows
```

All objects show:

```text
module2_run_id = M2-03
run_registry_match_status = RUN_REGISTRY_MATCHED
validation_evidence_group_id = VE03
missing_critical_registry_field_rows = 0
registry_linkage_status = REGISTRY_LINKAGE_CAPTURED
```

No issue.

---

## 16.8G — Option C executive evidence review

```text
Status: PASS
```

M2-03 Option C posture is correct:

```text
strategy_name = GROWTH_ORIENTED_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

Ordinary counteroffer evidence:

```text
ordinary_counteroffer_candidate_rows = 20,080
ordinary_counteroffer_candidate_rate = 0.401600
delta_ordinary_counteroffer_candidate_rate = -0.024120
```

Aggressive override evidence is correctly inactive:

```text
aggressive_override_rows = 0
aggressive_override_rate = 0
delta_aggressive_override_rate = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
```

Short aliases are clean:

```text
avg_agr_ovr_co_exposure_reduction_pct = NULL
avg_agr_ovr_co_approved_pti = NULL
avg_agr_ovr_co_approved_el = NULL
```

No issue.

---

# Final M2-03 key preservation signoff

```text
M2-03 key preservation queries: ACCEPTED

12.8.13 archive readiness: PASS
15.7A executive frontier summary: PASS
15.8D frontier registry linkage: PASS
15.8E Option C frontier diagnostic: PASS
16.8A evidence object row-count diagnostic: PASS
16.8B executive evidence summary: PASS
16.8C validation interpretation items: PASS
16.8D product × score segment evidence: PASS
16.8E parameter snapshot: PASS
16.8F evidence registry linkage: PASS
16.8G Option C executive evidence: PASS

No blockers.
No missing key export.
No stale wording issue.
No Option C leakage.
No registry-linkage issue.
No further refinements recommended.
```

## M2-03 preservation narrative

```text
M2-03 GROWTH_ORIENTED_STRATEGY expands access and approved exposure relative to baseline.

The benefit:
    higher approval rate,
    higher simulated offer-exposure rate,
    lower decline rate,
    higher total approved amount.

The tradeoff:
    higher total approved Expected Loss,
    higher approved Expected Loss capture rate,
    higher approved EL per approved dollar.

The primary reason-code delta driver is APPROVED_AS_REQUESTED, which supports the growth-oriented storyline.
```

This package is clean to save.
<!-- END_MESSAGE C040-M02152 -->


---

<a id="c040-m02154"></a>

### C040-M02154

**Andrew** · 2026-05-20T00:37:41.939000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02154 -->
m2-04 key queries
<!-- END_MESSAGE C040-M02154 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8F_QA_registry_linkage_consistency_diagnostic_across_evidence_tables_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8E_QA_parameter_snapshot_diagnostic_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8D_QA_current_run_product_x_score_segment_evidence_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8C_QA_current_run_validation_items_requiring_interpretation_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8B_QA_current_run_executive_evidence_summary_row_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8A_QA_evidence_object_row_count_diagnostic_for_current_run_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.13_QA_section_12_readiness_summary_m2_04.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.8G_QA_option_c_executive_evidence_review_m2_04.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02158"></a>

### C040-M02158

**ChatGPT** · 2026-05-20T00:47:58.219153-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02158 -->
## M2-04 key preservation query review verdict

```text
M2-04 key preservation package status: PASS
Run: M2-04 — TIGHTER_AFFORDABILITY_STRATEGY
Showcase: SC01 — Baseline Strategy Frontier
Comparison group: CG03
Archive readiness: PASS
Frontier evidence: PASS
Evidence capture: PASS
Validation interpretation evidence: PASS
Parameter snapshot: PASS
Registry linkage: PASS
Option C posture: correctly not applicable
Blockers: none
Further refinements recommended: none
```

The M2-04 preservation package is clean. Section 12 confirms archive persistence, Section 15 preserves archive-backed frontier context, and Section 16 captures persistent run-level executive, validation, parameter, and segment evidence. fileciteturn13file31 fileciteturn13file23 fileciteturn13file19

---

## 12.8.13 — Section 12 archive readiness summary

```text
Status: PASS
```

M2-04 archived cleanly:

```text
strategy_name = TIGHTER_AFFORDABILITY_STRATEGY
latest_run_row_count = 50,000
latest_run_distinct_application_count = 50,000
archive_inserted_rows = 50,000
archive_row_count_before = 150,000
archive_row_count_after = 200,000
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
current_archived_slice_null_archive_ts_rows = 0
duplicate_archive_grain_count = 0
```

Option C archive checks are clean:

```text
option_c_latest_run_archive_gap_count = 0
option_c_archive_reason_trace_gap_count = 0
aggressive_override_archived_rows = 0
```

Final status:

```text
SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA
```

The archive movement is correct. The archive grew from 150,000 rows to 200,000 rows because M2-01 through M2-04 are now archived.

---

## 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
```

The frontier summary now has four SC01 rows:

```text
M2-01 BASELINE_STRATEGY
M2-02 TIGHTER_SYNTHETIC_RISK_STRATEGY
M2-03 GROWTH_ORIENTED_STRATEGY
M2-04 TIGHTER_AFFORDABILITY_STRATEGY
```

M2-04 is classified as:

```text
frontier_position_type = BALANCED_OR_MIXED_FRONTIER_POINT
executive_frontier_quadrant = LOWER_ACCESS_HIGHER_APPROVED_EL_RATE
```

That classification is appropriate. M2-04 lowers approved exposure and total approved Expected Loss, but it does not improve every risk-efficiency metric versus baseline.

M2-04 core metrics:

```text
applications = 50,000
approval_rate = 0.179200
counteroffer_rate = 0.386320
manual_review_rate = 0.166300
decline_rate = 0.268180
simulated_offer_exposure_rate = 0.565520
```

Baseline-relative movement:

```text
delta_approval_rate = -0.034700
delta_counteroffer_rate = +0.004980
delta_manual_review_rate = +0.015600
delta_decline_rate = +0.014120
delta_simulated_offer_exposure_rate = -0.029720
delta_total_approved_amount = -257.845M
delta_total_approved_expected_loss_amount = -3.532M
```

Affordability and Expected Loss evidence:

```text
avg_approved_payment_to_income_ratio_offer_rows = 0.120288
baseline avg approved PTI offer rows ≈ 0.122971
PTI movement = lower / tighter

approved_expected_loss_capture_rate = 0.229791
approved_el_per_approved_dollar = 0.015414
```

Interpretation:

```text
M2-04 delivers affordability discipline primarily by reducing approval volume and approved exposure.
It lowers total approved Expected Loss versus baseline, but approved EL per approved dollar is slightly higher than baseline.
That makes the frontier classification mixed rather than clean risk-discipline.
```

Reason-code delta driver is coherent:

```text
top_reason_code_delta_driver_code = APPROVED_AS_REQUESTED
top_reason_code_delta_population_share = -0.034700
```

This means the largest movement is fewer approvals-as-requested, which fits a tighter affordability strategy.

No issue.

---

## 15.8D — Frontier registry linkage diagnostic

```text
Status: PASS
```

Registry linkage is clean across the four frontier rows:

```text
executive_frontier_rows = 4
registry_matched_rows = 4
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0
registry_linkage_status = FRONTIER_REGISTRY_LINKAGE_READY
```

No issue.

---

## 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS
```

The one-row `NOT_APPLICABLE` behavior remains correct:

```text
option_c_frontier_diagnostic_status =
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

The generalized note is correct:

```text
No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive.
This is expected until selective or aggressive Option C strategy runs are archived and should not be treated as an Option C failure.
```

This is correct because the currently archived runs are M2-01 through M2-04, none of which are selective/aggressive Option C runs.

No issue.

---

## 16.8A — Evidence object row-count diagnostic for current run

```text
Status: PASS
```

The evidence footprint is exactly right:

```text
strategy_run_evidence_summary              1 row
strategy_run_parameter_snapshot            1 row
strategy_run_segment_evidence_summary     25 rows
strategy_run_validation_evidence          22 rows
```

Registry metadata is clean:

```text
module1_run_id = M1-01
module2_run_id = M2-04
run_sequence_number = 4
showcase_id = SC01
comparison_group_id = CG03
validation_evidence_group_id = VE04
run_registry_match_status = RUN_REGISTRY_MATCHED
```

No issue.

---

## 16.8B — Current-run executive evidence summary row

```text
Status: PASS
```

This is the primary M2-04 preservation row, and it is clean.

Identity:

```text
module2_run_id = M2-04
strategy_name = TIGHTER_AFFORDABILITY_STRATEGY
run_sequence_number = 4
showcase_id = SC01
comparison_group_id = CG03
validation_evidence_group_id = VE04
readme_storyline_label = Tighter affordability challenger
validation_summary_section_hint = Affordability evidence
module2_strategy_family_changed = AFFORDABILITY_DISCIPLINE
```

Expected storyline:

```text
Demonstrate affordability discipline and how tighter PTI guardrails affect offer exposure,
counteroffers, and review burden.
```

Observed storyline:

```text
Strategy shows mixed tradeoffs requiring segment-level and reason-code review.
```

That observed storyline is appropriate. The strategy does reduce offer exposure, approved amount, total approved Expected Loss, and approved PTI, but it also increases manual-review and decline burden, and approved EL per approved dollar is slightly higher than baseline.

Core metrics:

```text
applications = 50,000
approval_rate = 0.179200
counteroffer_rate = 0.386320
manual_review_rate = 0.166300
decline_rate = 0.268180
simulated_offer_exposure_rate = 0.565520
```

Exposure / Expected Loss:

```text
total_approved_amount = 3.569B
approved_amount_capture_rate = 0.535431

total_requested_expected_loss_amount = 239.433M
total_approved_expected_loss_amount = 55.020M
approved_expected_loss_capture_rate = 0.229791
approved_el_per_approved_dollar = 0.015414
approved_amount_per_approved_expected_loss_dollar = 64.876
```

Reason-code movement:

```text
top_reason_code_delta_driver_code = APPROVED_AS_REQUESTED
top_reason_code_delta_population_share = -0.034700
```

Validation rollup:

```text
validation_pass_count = 18
validation_review_count = 1
validation_not_applicable_count = 3
```

Option C posture:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
ordinary_counteroffer_candidate_rows = 21,672
ordinary_counteroffer_candidate_rate = 0.433440
delta_ordinary_counteroffer_candidate_rate = +0.007720
aggressive_override_rows = 0
```

This is preservation-ready.

---

## 16.8C — Current-run validation items requiring interpretation

```text
Status: PASS
```

The output has the expected shape:

```text
REVIEW = 1
NOT_APPLICABLE = 3
```

The single `REVIEW` row is expected:

```text
EDGE_CASE_VISIBILITY
mixed_signal_profile_rate = 0.340860
borderline_profile_rate = 0.431840
```

This is a documentation-readiness flag, not a validation failure.

The three `NOT_APPLICABLE` rows are Option C-related and correct for M2-04:

```text
Aggressive override reason-code traceability
Latest-run aggressive override behavior
Matched comparison Option C context
```

The matched-comparison Option C interpretation is correct:

```text
The selected Section 13 comparison is ready, but this is not an Option C counteroffer split comparison; matched Option C aggressive movement is therefore not applicable for this comparison.
```

No issue.

---

## 16.8D — Current-run product × score segment evidence

```text
Status: PASS
```

The segment grid captured correctly:

```text
segment rows = 25
applications sum = 50,000
products = 5
score bands = 5
```

The refined Expected Loss fields are present:

```text
approved_expected_loss_capture_rate
approved_el_per_approved_dollar
legacy_approved_expected_loss_rate
```

Segment behavior is coherent for a tighter affordability strategy. The top approved amount segments remain mortgage-heavy:

```text
MORTGAGE_PRIME
    applications = 4,285
    simulated_offer_exposure_rate = 0.761260
    total_approved_amount = 1.117B
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

MORTGAGE_SUPER_PRIME
    applications = 2,747
    simulated_offer_exposure_rate = 0.854387
    total_approved_amount = 961.470M
    top reason = APPROVED_AS_REQUESTED

MORTGAGE_NEAR_PRIME
    applications = 3,644
    simulated_offer_exposure_rate = 0.760428
    total_approved_amount = 674.774M
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
```

Top approved-Expected-Loss segments are also intuitive:

```text
MORTGAGE_NEAR_PRIME
    total_approved_expected_loss_amount = 18.585M
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

MORTGAGE_PRIME
    total_approved_expected_loss_amount = 10.782M
    top reason = COUNTEROFFER_AFFORDABILITY_ADJUSTMENT

HELOC_NEAR_PRIME
    total_approved_expected_loss_amount = 3.367M
    top reason = COUNTEROFFER_ELEVATED_SYNTHETIC_RISK

MORTGAGE_SUPER_PRIME
    total_approved_expected_loss_amount = 3.260M
    top reason = APPROVED_AS_REQUESTED

AUTO_LOAN_NEAR_PRIME
    total_approved_expected_loss_amount = 3.235M
    top reason = COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
```

Deep-subprime behavior remains appropriately no-offer / decline-heavy:

```text
AUTO_LOAN_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.000000
    decline_rate = 0.994355

HELOC_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.000000
    decline_rate = 0.995495

MORTGAGE_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.000000
    decline_rate = 0.999429

UNSECURED_PERSONAL_LOAN_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.000000
    decline_rate = 0.998879

REVOLVING_LINE_DEEP_SUBPRIME
    simulated_offer_exposure_rate = 0.000664
    decline_rate = 0.996680
```

The one tiny revolving deep-subprime positive-offer cell is not a blocker; it is one row and remains consistent with the broader decline-heavy segment profile.

No issue.

---

## 16.8E — Parameter snapshot diagnostic

```text
Status: PASS
```

Parameter snapshot captured correctly:

```text
strategy_params_captured_flag = true
product_policy_params_captured_flag = true
run_story_params_captured_flag = true
```

Registry linkage is clean:

```text
module1_run_id = M1-01
module2_run_id = M2-04
run_sequence_number = 4
showcase_id = SC01
comparison_group_id = CG03
validation_evidence_group_id = VE04
run_registry_match_status = RUN_REGISTRY_MATCHED
```

Parameter snapshot hash is populated:

```text
parameter_snapshot_hash = 5107309c1698677b8129f7ff32ec00ab
```

No issue.

---

## 16.8F — Registry linkage consistency across evidence tables

```text
Status: PASS
```

All four evidence objects are linked cleanly:

```text
strategy_run_evidence_summary              1 row
strategy_run_parameter_snapshot            1 row
strategy_run_segment_evidence_summary     25 rows
strategy_run_validation_evidence          22 rows
```

All objects show:

```text
module2_run_id = M2-04
run_registry_match_status = RUN_REGISTRY_MATCHED
validation_evidence_group_id = VE04
missing_critical_registry_field_rows = 0
registry_linkage_status = REGISTRY_LINKAGE_CAPTURED
```

No issue.

---

## 16.8G — Option C executive evidence review

```text
Status: PASS
```

M2-04 Option C posture is correct:

```text
strategy_name = TIGHTER_AFFORDABILITY_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

Ordinary counteroffer evidence:

```text
ordinary_counteroffer_candidate_rows = 21,672
ordinary_counteroffer_candidate_rate = 0.433440
delta_ordinary_counteroffer_candidate_rate = +0.007720
```

Aggressive override evidence is correctly inactive:

```text
aggressive_override_rows = 0
aggressive_override_rate = 0
delta_aggressive_override_rate = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
```

Short aliases are clean:

```text
avg_agr_ovr_co_exposure_reduction_pct = NULL
avg_agr_ovr_co_approved_pti = NULL
avg_agr_ovr_co_approved_el = NULL
```

No issue.

---

# Final M2-04 key preservation signoff

```text
M2-04 key preservation queries: ACCEPTED

12.8.13 archive readiness: PASS
15.7A executive frontier summary: PASS
15.8D frontier registry linkage: PASS
15.8E Option C frontier diagnostic: PASS
16.8A evidence object row-count diagnostic: PASS
16.8B executive evidence summary: PASS
16.8C validation interpretation items: PASS
16.8D product × score segment evidence: PASS
16.8E parameter snapshot: PASS
16.8F evidence registry linkage: PASS
16.8G Option C executive evidence: PASS

No blockers.
No missing key export.
No stale wording issue.
No Option C leakage.
No registry-linkage issue.
No further refinements recommended.
```

## M2-04 preservation narrative

```text
M2-04 TIGHTER_AFFORDABILITY_STRATEGY shows affordability discipline through lower offer exposure,
lower approved amount, lower total approved Expected Loss, and lower average approved PTI for offer rows.

The tradeoff:
    lower approval rate,
    higher manual-review rate,
    higher decline rate,
    lower total approved exposure,
    lower total approved Expected Loss,
    but slightly higher approved EL per approved dollar versus baseline.

The result is appropriately classified as a mixed frontier point rather than a clean risk-discipline win.
```

This package is clean to save.
<!-- END_MESSAGE C040-M02158 -->


---

<a id="c040-m02160"></a>

### C040-M02160

**Andrew** · 2026-05-20T00:58:13.776000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02160 -->
thank you.  for remaining queries, i will complete M2-05 through M2-39 runs - then re-run section 15, following by section 16.9 through section 17.  i will then pass the section 16.9 through section 17 output for review.  if we need to dig deeper, we can then pull up these individual key queries.
<!-- END_MESSAGE C040-M02160 -->


---

<a id="c040-m02161"></a>

### C040-M02161

**ChatGPT** · 2026-05-20T01:00:30.889855-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02161 -->
That is the right workflow.

Run:

```text
M2-05 through M2-39
→ each through Section 16.8
→ then rerun Section 15 once from the completed archive
→ then run Section 16.9
→ then run Section 17
```

That sequence matches the intended full-campaign workflow: Section 15 is archive-wide, Section 16.0–16.8 captures evidence one run at a time, Section 16.9 refreshes Section 15-derived frontier fields after the completed archive is available, and Section 17 is the final read-only campaign acceptance layer. fileciteturn13file21 fileciteturn13file18

A few execution cautions:

```text
1. Do not run Section 1 immediately before Section 16.9 unless you rerun Section 15 afterward.

2. Section 16.9 needs the fresh Section 15 temp table:
       tmp_m2_strategy_frontier_executive_summary

3. After all 39 runs, expected archive scale should be:
       39 × 50,000 = 1,950,000 archived rows
   assuming every active campaign run remains 50,000 rows.

4. Evidence tables should have one executive row and one parameter snapshot per active campaign run.

5. Segment evidence should have complete product × score evidence per active campaign run.

6. Validation evidence should be judged dynamically by Section 17, not by a hardcoded row count.
```

For the remaining individual runs, saving only the key preservation package is enough. The full M2-01 QA package and full M2-02 Section 13 package already prove the detailed QA and comparison logic. For M2-05 onward, if anything looks unusual, we can pull the key query package first, then drill into the full section-specific QA only if needed.

The spots I would watch most closely as you continue:

```text
M2-05:
    first SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY run.
    15.8E and 16.8G should stop being purely NOT_APPLICABLE for Option C selective frontier context.

M2-06:
    first PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY run.
    Later Section 17 product-guardrail checks become important.

M2-07:
    MANUAL_REVIEW_REDUCTION_STRATEGY.
    Watch manual-review-to-decline movement and failed-counteroffer resolution.

M2-37 through M2-39:
    AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY.
    These are the most important Option C aggressive evidence runs.
    Watch aggressive_override_rows, final aggressive override outcomes, and aggressive override reason traceability.
```

When you send the final outputs, I would start with:

```text
Section 16.9 outputs
Section 17.1 through 17.8
Section 17.9 through 17.15
Section 17.16 through end
```

That batching should keep the review manageable. If Section 17 flags anything, we can then pull the individual run key queries for the affected `module2_run_id`.
<!-- END_MESSAGE C040-M02161 -->


---

<a id="c040-m02163"></a>

### C040-M02163

**Andrew** · 2026-05-20T23:15:32.663000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02163 -->
the campaign ran successfully through M-39 section 16.8.  I then re-ran section 15 successfully.  upon running section 16.9, I encountered the following error: SQL Error [P0001]: ERROR: Module 2 Section 16.9 failure: strategy_run_evidence_summary is missing required column(s): avg_agr_ovr_co_approved_el, avg_agr_ovr_co_approved_pti, avg_agr_ovr_co_exposure_reduction_pct.
  Where: PL/pgSQL function inline_code_block line 103 at RAISE
  ERROR: Module 2 Section 16.9 failure: strategy_run_evidence_summary is missing required column(s): avg_agr_ovr_co_approved_el, avg_agr_ovr_co_approved_pti, avg_agr_ovr_co_exposure_reduction_pct.
  Where: PL/pgSQL function inline_code_block line 103 at RAISE    - please make sure all the refinements we made are baked into the section 16.9 and section 17 code.
<!-- END_MESSAGE C040-M02163 -->


---

<a id="c040-m02182"></a>

### C040-M02182

**ChatGPT** · 2026-05-20T23:27:57.356977-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02182 -->
You diagnosed it correctly: this is from the aggressive-override alias refinements.

The issue is **not** that `strategy_run_evidence_summary` needs these short columns:

```text
avg_agr_ovr_co_approved_el
avg_agr_ovr_co_approved_pti
avg_agr_ovr_co_exposure_reduction_pct
```

It does **not**. Those are the shortened **Section 15 temporary frontier aliases**.

The persistent Section 16 evidence table should continue to use the long persistent evidence names:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
avg_approved_pti_for_aggressive_override_counteroffers
avg_approved_el_for_aggressive_override_counteroffers
```

That is the contract we previously locked: Section 15 uses the short source aliases, while Section 16 persistent evidence keeps the long evidence-table columns. fileciteturn14file0

I created the corrected full code and a standalone replacement for Section 16.9B.

[Download corrected full Module 2 code](sandbox:/mnt/data/module2_v1_0_latest_section16_9_and_17_refinements_aligned.txt)

[Download corrected Section 16.9B only](sandbox:/mnt/data/section16_9B_corrected_preflight_gatekeepers.sql)

[Download validation notes](sandbox:/mnt/data/section16_9_section17_alias_alignment_validation_notes.sql)

## What was wrong

In **Section 16.9B**, the first required-column check is checking the persistent table:

```sql
credit_decisioning_sim.strategy_run_evidence_summary
```

That check was incorrectly looking for the shortened Section 15 aliases:

```sql
('avg_agr_ovr_co_exposure_reduction_pct'),
('avg_agr_ovr_co_approved_pti'),
('avg_agr_ovr_co_approved_el'),
```

Those columns do not belong in the persistent evidence table, so Section 16.9 correctly failed.

## Exact correction in Section 16.9B

In the **first** required-column list in Section 16.9B — the one under:

```text
Confirm required columns exist in the persistent executive evidence table.
```

replace this:

```sql
                ('avg_agr_ovr_co_exposure_reduction_pct'),
                ('avg_agr_ovr_co_approved_pti'),
                ('avg_agr_ovr_co_approved_el'),
```

with this:

```sql
                ('avg_exposure_reduction_pct_for_aggressive_override_counteroffers'),
                ('avg_approved_pti_for_aggressive_override_counteroffers'),
                ('avg_approved_el_for_aggressive_override_counteroffers'),
```

Do **not** change the second required-column list in Section 16.9B. The second list checks the fresh Section 15 table:

```sql
tmp_m2_strategy_frontier_executive_summary
```

and that one should still require:

```sql
                ('avg_agr_ovr_co_exposure_reduction_pct'),
                ('avg_agr_ovr_co_approved_pti'),
                ('avg_agr_ovr_co_approved_el'),
```

Section 16.9 depends on a fresh Section 15 run and synchronizes Section 15-derived frontier fields into persistent executive evidence after the completed campaign archive exists. fileciteturn13file21

## Section 17 check

I checked Section 17 alignment as well. Section 17 reads the persistent evidence table, so it should use the long persistent names. It already does:

```sql
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
avg_approved_pti_for_aggressive_override_counteroffers
avg_approved_el_for_aggressive_override_counteroffers
```

No Section 17 patch is needed for this alias issue. Section 17 is the final read-only campaign acceptance layer after all runs, Section 15 rerun, and Section 16.9 synchronization. fileciteturn13file18

## Rerun guidance

After applying the corrected file or replacing Section 16.9B:

```text
1. Do not rerun Sections 1–14.
2. Keep the same SQL session if possible.
3. Confirm Section 15 was rerun from the completed campaign archive.
4. Rerun Section 16.9 from the beginning.
5. Then run Section 17.
```

The important temporary table is:

```text
tmp_m2_strategy_frontier_executive_summary
```

If your session was closed, rerun Section 15 first, then Section 16.9.
<!-- END_MESSAGE C040-M02182 -->


---

<a id="c040-m02183"></a>

### C040-M02183

**Andrew** · 2026-05-20T23:36:00.182000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02183 -->
after swapping in your corrected 16.9B, I still encountered the following error: SQL Error [P0001]: ERROR: Module 2 Section 16.9 failure: strategy_run_evidence_summary is missing required column(s): avg_exposure_reduction_pct_for_aggressive_override_counteroffers.
  Where: PL/pgSQL function inline_code_block line 103 at RAISE
  ERROR: Module 2 Section 16.9 failure: strategy_run_evidence_summary is missing required column(s): avg_exposure_reduction_pct_for_aggressive_override_counteroffers.
  Where: PL/pgSQL function inline_code_block line 103 at RAISE
<!-- END_MESSAGE C040-M02183 -->


---

<a id="c040-m02189"></a>

### C040-M02189

**ChatGPT** · 2026-05-20T23:46:51.913132-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02189 -->
You found the real issue: this is **PostgreSQL identifier truncation**, not a missing evidence-field design problem.

The name:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
```

is **64 characters**.

PostgreSQL unquoted identifiers are limited to **63 bytes**, so the physical column that actually exists is:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffer
```

without the final `s`.

The Section 16.9B preflight was comparing literal text against `pg_attribute.attname`, so PostgreSQL did **not** truncate the string for you. That is why it reported the plural column as missing even though the intended physical column exists. The retrieved current Section 16.9B code shows the preflight checking the persistent evidence table against literal required-column names, including the overlong plural name. fileciteturn16file4

I corrected this properly in the updated files below.

[Download corrected full Module 2 code with Section 16.9 / 17 alias alignment](sandbox:/mnt/data/module2_v1_0_section16_9_physical_alias_patch_applied.txt)

[Download corrected Section 16.9B only](sandbox:/mnt/data/section16_9B_physical_alias_corrected.sql)

[Download corrected full Section 16.9 only](sandbox:/mnt/data/section16_9_full_physical_alias_corrected.sql)

[Download validation notes](sandbox:/mnt/data/section16_9_physical_alias_validation_notes.txt)

## What changed

I made the physical persistent evidence-table column name explicit:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffer
```

and kept the Section 15 temporary frontier alias as:

```text
avg_agr_ovr_co_exposure_reduction_pct
```

The corrected contract is now:

```text
Persistent Section 16 evidence table:
    avg_exposure_reduction_pct_for_aggressive_override_counteroffer
    avg_approved_pti_for_aggressive_override_counteroffers
    avg_approved_el_for_aggressive_override_counteroffers

Fresh Section 15 temporary frontier table:
    avg_agr_ovr_co_exposure_reduction_pct
    avg_agr_ovr_co_approved_pti
    avg_agr_ovr_co_approved_el
```

The important distinction is that only the exposure-reduction field was too long. The PTI and EL field names are under PostgreSQL’s identifier limit and remain plural.

---

## Exact Section 16.9B correction

In the **persistent evidence-table required-column list**, use:

```sql
                ('avg_exposure_reduction_pct_for_aggressive_override_counteroffer'),
                ('avg_approved_pti_for_aggressive_override_counteroffers'),
                ('avg_approved_el_for_aggressive_override_counteroffers'),
```

In the **fresh Section 15 frontier required-column list**, use:

```sql
                ('avg_agr_ovr_co_exposure_reduction_pct'),
                ('avg_agr_ovr_co_approved_pti'),
                ('avg_agr_ovr_co_approved_el'),
```

The bug was that the persistent evidence-table check was looking for the overlong plural name, and the fresh frontier check in the version you ran was also still looking for long names instead of the short Section 15 aliases. The current Section 16.9B preflight explicitly checks both the persistent evidence table and the fresh Section 15 frontier table, so both lists need to be aligned. fileciteturn16file4

---

## Quick schema confirmation query

Before rerunning Section 16.9, you can confirm the physical column names with:

```sql
SELECT
    column_name,
    LENGTH(column_name) AS column_name_length
FROM information_schema.columns
WHERE table_schema = 'credit_decisioning_sim'
  AND table_name = 'strategy_run_evidence_summary'
  AND column_name LIKE '%aggressive_override_counteroffer%'
ORDER BY column_name;
```

Expected relevant result:

```text
avg_approved_el_for_aggressive_override_counteroffers
avg_approved_pti_for_aggressive_override_counteroffers
avg_exposure_reduction_pct_for_aggressive_override_counteroffer
```

If the singular exposure-reduction column is somehow missing, run this once:

```sql
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
ADD COLUMN IF NOT EXISTS avg_exposure_reduction_pct_for_aggressive_override_counteroffer NUMERIC;
```

But based on your error, the table most likely already has the singular physical column; the preflight was just checking for the wrong literal string.

---

## Section 16.9 / Section 17 alignment

I also normalized the overlong exposure-reduction identifier throughout the updated full code so it no longer refers to:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
```

The corrected file has:

```text
old overlong plural references = 0
physical singular persistent references = 17
Section 15 short alias references = 22
```

Section 17 was less likely to fail from this specific issue because unquoted SQL references are parsed and truncated by PostgreSQL, but any literal metadata checks need to use the true physical name. I updated the full file so Section 17 comments / references are aligned with the physical persistent evidence field as well. Section 17 is the final read-only acceptance layer after Section 15 and Section 16.9, so it should read persistent evidence consistently. fileciteturn15file18

---

## Rerun guidance

Use the corrected full file, or replace Section 16.9B with the corrected version and keep your current session.

Then run:

```text
Section 16.9 from the beginning
```

Do **not** rerun Sections 1–14. If the session is still open and Section 15 was just rerun, the required temp table should still exist:

```text
tmp_m2_strategy_frontier_executive_summary
```

If the SQL session was closed, rerun:

```text
Section 15
then Section 16.9
then Section 17
```
<!-- END_MESSAGE C040-M02189 -->


---

<a id="c040-m02191"></a>

### C040-M02191

**Andrew** · 2026-05-21T01:33:25.560000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02191 -->
section 17 error: SQL Error [42702]: ERROR: column reference "audited_product_count" is ambiguous
  Position: 74760
  ERROR: column reference "audited_product_count" is ambiguous
  Position: 74760    - i think near the end of section 17.  perhaps 17.20 or nearby 
<!-- END_MESSAGE C040-M02191 -->


---

<a id="c040-m02197"></a>

### C040-M02197

**ChatGPT** · 2026-05-21T01:41:12.555948-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02197 -->
You were right: this is in **Section 17.20**, not Section 17.19.

The issue is not data-related. It is a SQL naming issue inside the final acceptance rollup. `audited_product_count` was carried into `acceptance_inputs` twice: once in the dynamic expected-campaign-shape block and again in the product-guardrail audit block. When `acceptance_status` later selected `ai.*`, the downstream reference to `audited_product_count` became ambiguous. The same pattern also existed for `expected_product_guardrail_policy_rows`, so I fixed both to prevent the next ambiguity. fileciteturn20file0turn20file5

## Corrected files

[Download corrected full Module 2 code](sandbox:/mnt/data/module2_v1_0_section17_20_audited_product_count_fix_applied.txt)

[Download corrected Section 17.20 only](sandbox:/mnt/data/section17_20_corrected_final_acceptance_rollup.sql)

## What changed

In **Section 17.20**, I kept the dynamic expected-campaign field as:

```sql
audited_product_count
```

Then I renamed the duplicate product-guardrail audit fields to:

```sql
product_guardrail_audited_product_count
product_guardrail_expected_policy_rows
```

So the final acceptance output now has both concepts without duplicate column names.

## Manual patch, if you prefer not to replace the full file

In **Section 17.20**, inside `acceptance_inputs`, replace the product-guardrail audit block with:

```sql
        /*******************************************************************************************
        Product guardrail exact-value audit.
        *******************************************************************************************/
        pga.product_guardrail_campaign_run_count,
        pga.audited_product_count AS product_guardrail_audited_product_count,
        pga.product_guardrail_parameter_snapshot_complete_run_count,
        pga.product_guardrail_parameter_snapshot_issue_run_count,
        pga.expected_product_guardrail_policy_rows AS product_guardrail_expected_policy_rows,
        pga.product_guardrail_policy_ready_rows,
        pga.missing_product_guardrail_policy_rows,
        pga.product_guardrail_policy_row_count_issue_rows,
        pga.product_guardrail_policy_mismatch_rows,
```

Then, in the final `SELECT` product-guardrail block, replace:

```sql
    product_guardrail_campaign_run_count,
    audited_product_count,
    product_guardrail_parameter_snapshot_complete_run_count,
```

with:

```sql
    product_guardrail_campaign_run_count,
    product_guardrail_audited_product_count,
    product_guardrail_expected_policy_rows,
    product_guardrail_parameter_snapshot_complete_run_count,
```

## Rerun guidance

No need to rerun Sections 1–16.9 for this issue.

After applying the patch:

```text
Rerun Section 17.20, or rerun Section 17 from the start if you want the full final output sequence again.
```

Section 17.19 can stay as-is. The ambiguity was caused by duplicated output names in the Section 17.20 rollup CTE, not by the standalone product-guardrail exact-value audit query.
<!-- END_MESSAGE C040-M02197 -->


---

<a id="c040-m02199"></a>

### C040-M02199

**Andrew** · 2026-05-21T08:08:12.642000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02199 -->
my session disconnected.  do I need to re-run anything before running section 17?
<!-- END_MESSAGE C040-M02199 -->


---

<a id="c040-m02200"></a>

### C040-M02200

**ChatGPT** · 2026-05-21T08:11:34.105376-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02200 -->
You should **not need to rerun anything before Section 17** as long as **Section 16.9 completed successfully and committed** before the disconnect.

The session disconnect only drops temporary tables. Section 17 is intended to be the final **read-only acceptance layer** that reviews the completed campaign from persistent archive, registry, comparison, validation, parameter-snapshot, product-policy, and evidence objects. It is meant to run after all campaign runs are archived, Section 15 has been rerun once, and Section 16.9 has synchronized frontier fields into persistent executive evidence. fileciteturn19file18

## What to do now

Apply the corrected **Section 17.20** patch, then run:

```text
Section 17 only
```

Preferably rerun:

```text
Section 17.1 through Section 17.20
```

rather than only 17.20, so you get a clean full Section 17 output package in the new session.

## What you do not need to rerun

Do **not** rerun:

```text
Sections 1–14
Section 15
Section 16.9
```

provided Section 16.9 already completed successfully. Section 16.9 writes its synchronization results into the persistent table:

```text
credit_decisioning_sim.strategy_run_evidence_summary
```

So once it completed and committed, Section 17 can read the persistent synchronized evidence without needing the old temp tables.

## When you would need to rerun Section 15 + 16.9

You would need to rerun Section 15 and Section 16.9 only if either of these is true:

```text
1. Section 16.9 did not actually complete successfully.
2. Your SQL client had autocommit OFF and the disconnect rolled back the Section 16.9 update.
```

If that happened, the required sequence would be:

```text
Rerun Section 15
→ rerun Section 16.9
→ run Section 17
```

That is because Section 16.9 depends on the fresh Section 15 temporary table:

```text
tmp_m2_strategy_frontier_executive_summary
```

and that temp table is gone after a session disconnect. The code comments explicitly state that Section 16.9 depends on a fresh Section 15 run and that Section 15 creates `tmp_m2_strategy_frontier_executive_summary`. fileciteturn20file7

## Quick persistent sanity check before Section 17

Run this if you want reassurance that the evidence layer is still present after the disconnect:

```sql
SELECT
    COUNT(*) AS active_campaign_runs
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE registry_active_flag IS TRUE;
```

Expected:

```text
39
```

Then:

```sql
SELECT
    COUNT(*) AS executive_evidence_rows
FROM credit_decisioning_sim.strategy_run_evidence_summary e
JOIN credit_decisioning_sim.strategy_run_campaign_registry r
    ON e.strategy_set_name = r.strategy_set_name
   AND e.strategy_name = r.strategy_name
   AND e.strategy_version = r.strategy_version
   AND e.module1_scenario_set_name = r.module1_scenario_set_name
   AND e.module1_scenario_name = r.module1_scenario_name
   AND e.population_id = r.population_id
WHERE r.registry_active_flag IS TRUE;
```

Expected:

```text
39
```

And:

```sql
SELECT
    COUNT(*) AS evidence_rows_with_frontier_fields
FROM credit_decisioning_sim.strategy_run_evidence_summary e
JOIN credit_decisioning_sim.strategy_run_campaign_registry r
    ON e.strategy_set_name = r.strategy_set_name
   AND e.strategy_name = r.strategy_name
   AND e.strategy_version = r.strategy_version
   AND e.module1_scenario_set_name = r.module1_scenario_set_name
   AND e.module1_scenario_name = r.module1_scenario_name
   AND e.population_id = r.population_id
WHERE r.registry_active_flag IS TRUE
  AND e.frontier_position_type IS NOT NULL
  AND e.executive_frontier_quadrant IS NOT NULL
  AND e.frontier_interpretation_note IS NOT NULL;
```

Expected:

```text
39
```

If those pass, proceed directly to Section 17.

## Important warning

Do **not** run Section 1 before Section 17. Section 1 is designed to reset temporary objects and the replaceable latest-run output table; it is not needed for Section 17 and could create confusion. The code specifically warns not to run Section 1 immediately before Section 16.9 unless Section 15 is rerun afterward, because Section 16.9 depends on the fresh Section 15 temp output. fileciteturn20file16

## Bottom line

```text
If Section 16.9 completed and committed:
    Run Section 17 only.

If Section 16.9 may have rolled back:
    Rerun Section 15,
    rerun Section 16.9,
    then run Section 17.

Do not rerun Sections 1–14.
```

Given that you reached a Section 17.20 error, Section 16.9 most likely completed. I would run the quick persistent sanity checks, then rerun Section 17 with the corrected 17.20 block.
<!-- END_MESSAGE C040-M02200 -->


---

<a id="c040-m02202"></a>

### C040-M02202

**Andrew** · 2026-05-21T10:27:02.656000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02202 -->
the full campaign is complete.  these next 3 prompts will focus on QA review for section 15, section 16.9, and section 17.  here is section 15 QA following the final campaign section 15 re-run.  
<!-- END_MESSAGE C040-M02202 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8C_QA_frontier_reason_code_storytelling_diagnostic_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8B_QA_frontier_baseline_availability_diagnostic_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8A_QA_frontier_object_row_count_diagnostic_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.6A_QA_segment_level_frontier_highlights_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.5A_QA_strategy_frontier_classification_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.4A_QA_strategy_efficiency_metrics_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.3A_QA_baseline_relative_frontier_delta_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.2A_QA_core_strategy_frontier_summary_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.1A_QA_archive_frontier_inventory_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0A.2_QA_campaign_registry_map_review_output_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0_QA_frontier_scope_and_archive_readiness_snapshot_campaign.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic_campaign.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_03.md) · [Next](Part_05.md)
