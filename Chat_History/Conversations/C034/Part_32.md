# Module 1 Synthetic Application Portfolio Build

## Part 32

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_31.md) · [Next](Part_33.md)

<a id="c034-m01622"></a>

### C034-M01622

**ChatGPT** · 2026-05-17T16:28:52.817863-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01622 -->
## Updated Section 9 refined QA review verdict

```text
Section 9 refined QA status: PASS
Alias-length cleanup status: PASS
Logic blockers: none
Convention issues: none
Further Section 9 QA changes recommended: none
```

The latest refinements worked. The previously truncated PostgreSQL aliases are now clean, readable, and under the identifier-length limit.

## Alias-length cleanup

The updated exports no longer show PostgreSQL-truncated column names.

The shortened aliases are now present and readable:

```text
9.4.9
    avg_approved_el_non_null_rows
    avg_approved_el_all_rows_convention_adjusted
    avg_approved_el_positive_offer_rows
    total_approved_el_all_rows_convention_adjusted
    avg_approved_pti_positive_offer_rows

9.4.14
    avg_approved_el_non_null_rows
    avg_approved_el_all_rows_convention_adjusted
    avg_approved_el_positive_offer_rows

9.4.19
    avg_approved_pti_non_null_rows
    avg_approved_pti_all_rows_convention_adjusted
    avg_approved_pti_positive_offer_rows

9.4.20
    avg_approved_el_non_null_rows
    avg_approved_el_all_rows_convention_adjusted
    avg_approved_el_positive_offer_rows
    total_approved_el_all_rows_convention_adjusted
```

No aliases appear truncated. This polish issue is resolved.

---

## 9.4.9 — Product × score segment × decision outcome

```text
Status: PASS
Rows: 86 output rows
Product × score segments: 25
Stage-6 rows reconciled: 50,000
```

Outcome totals reconcile exactly:

```text
APPROVE          10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
DECLINE          12,703
```

Final approved-field conventions reconcile cleanly:

```text
positive_offer_rows             29,762
positive_approved_amount_rows   29,762
null_approved_amount_rows        7,535
zero_approved_amount_rows       12,703
```

This confirms:

```text
APPROVE / COUNTEROFFER = simulated positive offer exposure
MANUAL_REVIEW = unresolved NULL approved fields
DECLINE = zero no-offer convention
```

The segment-level percentages also reconcile by product × score segment, with only normal rounding noise around 1.000000.

The all-row convention-adjusted metrics and positive-offer-only metrics are now clearly separated. This output is ready for preservation.

---

## 9.4.14 — Requested Expected Loss tier × decision outcome

```text
Status: PASS
Rows: 15 output rows
Stage-6 rows reconciled: 50,000
```

Tier totals reconcile:

```text
LOW_REQUESTED_EL          26,158
MODERATE_REQUESTED_EL      8,409
ELEVATED_REQUESTED_EL      7,891
HIGH_REQUESTED_EL          5,553
SEVERE_REQUESTED_EL        1,989
```

Outcome totals reconcile:

```text
APPROVE          10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
DECLINE          12,703
```

The final outcome pattern is still coherent:

```text
LOW_REQUESTED_EL
    approval and counteroffer remain broadly available

MODERATE_REQUESTED_EL
    mostly counteroffer / review / decline, with a small approval population

ELEVATED_REQUESTED_EL
    no approvals, but counteroffers still present

HIGH_REQUESTED_EL and SEVERE_REQUESTED_EL
    no final approvals or counteroffers; outcomes resolve to manual review or decline
```

Approved Expected Loss convention counts reconcile:

```text
positive_approved_expected_loss_rows = 29,762
null_approved_expected_loss_rows      = 7,535
zero_approved_expected_loss_rows      = 12,703
```

The product-policy-relative interpretation note remains appropriate and useful.

---

## 9.4.19 — Requested PTI and approved PTI by decision outcome

```text
Status: PASS
Rows: 4 output rows
Stage-6 rows reconciled: 50,000
```

Outcome distribution remains correct:

```text
APPROVE          10,695   21.390%
COUNTEROFFER     19,067   38.134%
MANUAL_REVIEW     7,535   15.070%
DECLINE          12,703   25.406%
```

Approved PTI conventions are exact:

```text
APPROVE
    positive_approved_pti_rows = 10,695
    avg requested PTI = avg approved PTI = 0.086445

COUNTEROFFER
    positive_approved_pti_rows = 19,067
    avg requested PTI = 0.185296
    avg approved PTI = 0.143459
    avg PTI reduction = 0.041837

MANUAL_REVIEW
    null_approved_pti_rows = 7,535

DECLINE
    zero_approved_pti_rows = 12,703
```

The renamed `avg_approved_pti_all_rows_convention_adjusted` is clean and readable. No further change needed.

---

## 9.4.20 — Requested Expected Loss and approved Expected Loss by decision outcome

```text
Status: PASS
Rows: 4 output rows
Stage-6 rows reconciled: 50,000
```

Approved Expected Loss conventions are exact:

```text
APPROVE
    positive approved EL rows = 10,695
    avg requested EL = avg approved EL = 773.063017

COUNTEROFFER
    positive approved EL rows = 19,067
    avg requested EL = 3,474.715662
    avg approved EL = 2,637.215254
    avg EL reduction = 837.500408
    avg EL reduction pct = 0.197860

MANUAL_REVIEW
    null approved EL rows = 7,535

DECLINE
    zero approved EL rows = 12,703
```

The renamed aliases are clean:

```text
avg_approved_el_all_rows_convention_adjusted
total_approved_el_all_rows_convention_adjusted
```

The interpretation note remains strong and prevents confusion between unresolved manual review and no-offer decline conventions.

---

## Final signoff

```text
Updated Section 9 refined QA: ACCEPTED

No blockers.
No row-count reconciliation issues.
No final decision convention issues.
No approved amount convention issues.
No approved PTI convention issues.
No approved Expected Loss convention issues.
No alias truncation issues remaining.
No further Section 9 QA refinements recommended.
```

Section 9 QA is now preservation-ready.
<!-- END_MESSAGE C034-M01622 -->


---

<a id="c034-m01624"></a>

### C034-M01624

**Andrew** · 2026-05-17T16:55:20.640000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01624 -->
review section 10 QA:
<!-- END_MESSAGE C034-M01624 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.6_QA_score_band_x_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.7_QA_product_x_score_x_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.8_QA_counteroffer_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.9_QA_manual_review_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.10_QA_decline_policy_stop_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.11_QA_triggered_reason_code_list_sample_by_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.12_QA_counteroffer_feasibility_failure_reason_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.13_QA_decision_path_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.14_QA_decision_resolution_source_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.15_QA_mixed_signal_profile_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.16_QA_borderline_profile_flag_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.17_QA_reason_code_priority_rank_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.18_QA_option_c_aggressive_counteroffer_override_reason_code_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.19_QA_section_10_readiness_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.1_QA_row_count_and_distinct_application_id_count.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.2_QA_final_decision_outcome_x_primary_reason_family.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.3_QA_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.4_QA_reason_code_count_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.5_QA_product_x_primary_reason_code_distribution.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01634"></a>

### C034-M01634

**ChatGPT** · 2026-05-17T17:02:17.012546-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01634 -->
## M2-01 Section 10 QA review verdict

```text
Section 10 QA status: PASS
Selected run: M2-01
Strategy: BASELINE_STRATEGY
Stage 7 rows: 50,000
Distinct application_id count: 50,000
Reason-code coverage: PASS
Outcome-family alignment: PASS
Reason-code priority ranges: PASS
Decision-path alignment: PASS
Resolution-source alignment: PASS
Option C aggressive override posture: correctly inactive
Blockers: none
```

Section 10 is accepted from a logic and readiness standpoint. It is doing what it should: assigning deterministic simulated strategy explanation codes after Section 9 final decision resolution, without changing final outcomes, approved exposure, approved PTI, approved Expected Loss, or archive state. That is aligned with Section 10’s stated boundary as the simulated reason-code assignment layer. fileciteturn396file36

---

## 1. Row count and grain — 10.4.1

```text
stage7_row_count = 50,000
distinct_application_id_count = 50,000
```

This confirms Section 10 preserved the one-row-per-application grain.

```text
Status: PASS
```

---

## 2. Final decision outcome × primary reason family — 10.4.2

This is the core reason-family alignment check, and it is clean:

```text
APPROVE        → APPROVAL       10,695 / 100%
COUNTEROFFER   → COUNTEROFFER   19,067 / 100%
MANUAL_REVIEW  → MANUAL_REVIEW   7,535 / 100%
DECLINE        → POLICY_STOP    12,703 / 100%
```

No cross-family leakage appears.

```text
Status: PASS
```

---

## 3. Primary reason-code distribution — 10.4.3

The primary reason-code mix reconciles exactly to the Section 9 final outcome counts:

```text
APPROVAL
    APPROVED_AS_REQUESTED                         10,695

COUNTEROFFER
    COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT            8,905
    COUNTEROFFER_AFFORDABILITY_ADJUSTMENT          5,021
    COUNTEROFFER_ELEVATED_SYNTHETIC_RISK           3,853
    COUNTEROFFER_EXPECTED_LOSS_LIMIT               1,288

MANUAL_REVIEW
    MANUAL_REVIEW_FAILED_COUNTEROFFER              2,219
    MANUAL_REVIEW_BORDERLINE_PROFILE               1,926
    MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW            1,790
    MANUAL_REVIEW_DTI_REVIEW                       1,600

POLICY_STOP
    POLICY_STOP_SEVERE_SYNTHETIC_RISK              6,369
    POLICY_STOP_SEVERE_DELINQUENCY                 2,955
    POLICY_STOP_MAJOR_DEROGATORY                   2,107
    POLICY_STOP_BANKRUPTCY                           827
    POLICY_STOP_SEVERE_DTI                           445
```

Total:

```text
50,000 rows
14 distinct primary reason codes
```

This is coherent and interpretable.

```text
Status: PASS
```

A useful observation: `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT = 8,905` matches the Section 9 above-product-cap final counteroffer count. That is good evidence that the product-cap reason logic is behaving as intended.

---

## 4. Reason-code count distribution — 10.4.4

This output is coherent.

Approvals have exactly one reason code:

```text
APPROVE / reason_code_count = 1 / 10,695 rows
```

Non-approval outcomes often have multiple valid explanatory drivers:

```text
COUNTEROFFER reason_code_count ranges from 2 to 6
MANUAL_REVIEW reason_code_count ranges from 2 to 9
DECLINE reason_code_count ranges from 2 to 7
```

That is expected because Section 10 uses a candidate → deduplicate → rank → pivot pattern. A row can have multiple relevant strategy drivers, while the primary reason code reflects the highest-priority explanation.

```text
Status: PASS
```

---

## 5. Product / score / product × score reason diagnostics — 10.4.5 to 10.4.7

These diagnostics are coherent.

Product totals reconcile:

```text
AUTO_LOAN                   9,946
HELOC                       4,962
MORTGAGE                   15,065
REVOLVING_LINE             12,455
UNSECURED_PERSONAL_LOAN     7,572
```

Score-band totals reconcile:

```text
SUPER_PRIME      8,984
PRIME           13,987
NEAR_PRIME      12,073
SUBPRIME         8,902
DEEP_SUBPRIME    6,054
```

Product × score coverage is complete:

```text
25 product × score segments
222 product × score × reason-code rows
```

The reason-code behavior is directionally intuitive:

```text
SUPER_PRIME and PRIME have high approval and counteroffer explanation concentration.
NEAR_PRIME is heavily counteroffer-oriented.
SUBPRIME shifts toward manual review and policy stop reasons.
DEEP_SUBPRIME is overwhelmingly policy-stop driven.
```

```text
Status: PASS
```

One export-readability note: 10.4.5 and 10.4.7 use `avg_approved_amount_all_rows` / all-row approved metrics. That is acceptable, but as with Section 9, a future refinement could add an interpretation note explaining that all-row approved metrics use final outcome conventions.

---

## 6. Counteroffer primary reason distribution — 10.4.8

Counteroffer reason-code behavior is strong:

```text
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT        8,905
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT      5,021
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK       3,853
COUNTEROFFER_EXPECTED_LOSS_LIMIT           1,288
```

These sum exactly to:

```text
19,067 final COUNTEROFFER rows
```

The economics are directionally coherent:

```text
Counteroffer exposure reasons show approved_amount below requested_amount.
Counteroffer affordability reasons show meaningful approved PTI reduction.
Counteroffer Expected Loss reasons show meaningful approved EL reduction.
Elevated synthetic-risk counteroffers have lower average requested amount and smaller reduction percentage, which is plausible because the primary reason is risk posture rather than exposure size.
```

```text
Status: PASS
```

---

## 7. Manual-review primary reason distribution — 10.4.9

Manual-review reason-code behavior is coherent:

```text
MANUAL_REVIEW_FAILED_COUNTEROFFER            2,219
MANUAL_REVIEW_BORDERLINE_PROFILE             1,926
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW          1,790
MANUAL_REVIEW_DTI_REVIEW                     1,600
```

These sum exactly to:

```text
7,535 final MANUAL_REVIEW rows
```

The largest group is failed counteroffers, which matches the Section 9 final resolution behavior for M2-01:

```text
failed_counteroffer_resolution = MANUAL_REVIEW
```

```text
Status: PASS
```

---

## 8. Decline / policy-stop primary reason distribution — 10.4.10

Decline reason-code behavior is coherent:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK       6,369
POLICY_STOP_SEVERE_DELINQUENCY          2,955
POLICY_STOP_MAJOR_DEROGATORY            2,107
POLICY_STOP_BANKRUPTCY                    827
POLICY_STOP_SEVERE_DTI                    445
```

These sum exactly to:

```text
12,703 final DECLINE rows
```

The severe synthetic-risk group has the highest volume, while severe DTI has the highest average DTI. That is directionally correct.

```text
Status: PASS
```

---

## 9. Triggered reason-code sample — 10.4.11

The sample content itself is valid for approval rows:

```text
APPROVE rows show APPROVED_AS_REQUESTED
primary_reason_family = APPROVAL
reason_priority_rank = 900
reason_code_count = 1
```

However, the export file contains **100 APPROVE rows only**, despite the filename saying “sample by outcome.”

This is not a Section 10 logic blocker, but it is a QA-output issue:

```text
Current behavior:
    sample appears to be globally limited to 100 rows and sorted such that only APPROVE rows appear.

Preferred behavior:
    sample N rows per decision_outcome using ROW_NUMBER() OVER (PARTITION BY decision_outcome ...).
```

```text
Status: PASS for content shown
QA refinement recommended
```

This is the highest-value Section 10 QA refinement because the current sample does not help preserve examples for COUNTEROFFER, MANUAL_REVIEW, or DECLINE.

---

## 10. Counteroffer feasibility failure reason × primary reason code — 10.4.12

This output is clean:

```text
COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT    2,070 → MANUAL_REVIEW_FAILED_COUNTEROFFER
COUNTEROFFER_EXCEEDS_MAX_REDUCTION                 60 → MANUAL_REVIEW_FAILED_COUNTEROFFER
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT            89 → MANUAL_REVIEW_FAILED_COUNTEROFFER
```

These sum to:

```text
2,219 failed counteroffers
```

This aligns perfectly with Section 8 feasibility failure and Section 9 failed-counteroffer final resolution.

```text
Status: PASS
```

---

## 11. Decision path / resolution source × primary reason code — 10.4.13 and 10.4.14

These are both coherent.

Decision paths reconcile cleanly:

```text
APPROVE_AS_REQUESTED                 → APPROVED_AS_REQUESTED
COUNTEROFFER_FEASIBLE                → four COUNTEROFFER reason codes
COUNTEROFFER_NOT_FEASIBLE_REVIEW     → MANUAL_REVIEW_FAILED_COUNTEROFFER
MANUAL_REVIEW_CANDIDATE              → three MANUAL_REVIEW reason codes
HARD_POLICY_STOP                     → bankruptcy / derogatory / delinquency
SEVERE_DTI_CAPACITY                  → POLICY_STOP_SEVERE_DTI
SEVERE_SYNTHETIC_RISK                → POLICY_STOP_SEVERE_SYNTHETIC_RISK
```

Resolution sources also reconcile cleanly:

```text
PRELIMINARY_APPROVE_ROUTE                    → APPROVED_AS_REQUESTED
COUNTEROFFER_FEASIBILITY_PASSED              → COUNTEROFFER reasons
COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW    → MANUAL_REVIEW_FAILED_COUNTEROFFER
PRELIMINARY_MANUAL_REVIEW_ROUTE              → MANUAL_REVIEW reasons
PRELIMINARY_DECLINE_ROUTE                    → POLICY_STOP reasons
```

```text
Status: PASS
```

---

## 12. Mixed-signal and borderline reason diagnostics — 10.4.15 and 10.4.16

Mixed-signal totals reconcile:

```text
NO_MIXED_SIGNAL_PROFILE        32,190
WEAK_CREDIT_LOW_PTI             8,426
LARGE_EXPOSURE_LOW_RISK         6,711
MULTIPLE_MIXED_SIGNALS          1,745
STRONG_CREDIT_HIGH_PTI            539
HIGH_DTI_LOW_REQUESTED_PTI        266
HIGH_RISK_LOW_EXPOSURE            123
```

This remains useful and realistic:

```text
LARGE_EXPOSURE_LOW_RISK is heavily counteroffer-oriented.
WEAK_CREDIT_LOW_PTI splits across counteroffer, manual review, and policy stop.
MULTIPLE_MIXED_SIGNALS skews toward policy stop, with some counteroffer and manual review.
```

Borderline totals reconcile:

```text
borderline_profile_flag = false    29,704
borderline_profile_flag = true     20,296
```

Reason-family split is coherent:

```text
Non-borderline:
    APPROVAL         10,695
    COUNTEROFFER     11,486
    MANUAL_REVIEW     2,031
    POLICY_STOP       5,492

Borderline:
    APPROVAL              0
    COUNTEROFFER       7,581
    MANUAL_REVIEW      5,504
    POLICY_STOP        7,211
```

This is directionally strong: all approvals are non-borderline, while borderline rows concentrate in counteroffer, manual review, and policy stop outcomes.

```text
Status: PASS
```

---

## 13. Reason-code priority rank distribution — 10.4.17

Priority ranges are clean:

```text
POLICY_STOP     100–140
MANUAL_REVIEW   300–370
COUNTEROFFER    500–530
APPROVAL        900
```

The output shows 14 distinct primary reason codes, each with the expected family and rank.

```text
Status: PASS
```

One nuance: the prior targeted patch for `POLICY_STOP_HIGH_REQUESTED_PTI` is not visible as a **primary** reason code in M2-01. That is not automatically an issue, because it may appear only as a secondary / tertiary reason, or may be superseded by higher-priority policy-stop reasons. The current QA package does not conclusively prove whether that candidate reason is appearing in `triggered_reason_code_list`.

---

## 14. Option C aggressive override reason-code diagnostic — 10.4.18

The output is empty.

For M2-01, that is logically correct:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive override rows = 0
```

But for CSV preservation, this has the same issue we fixed in Sections 8 and 9: an empty export can be confused with a failed query or missed export.

```text
Status: PASS / correctly not applicable for M2-01
QA refinement recommended
```

---

## 15. Section 10 readiness summary — 10.4.19

This is the controlling signoff row, and it passes cleanly:

```text
stage7_row_count = 50,000
distinct_application_id_count = 50,000

required_reason_gap_rows = 0
approve_family_gap_rows = 0
counteroffer_family_gap_rows = 0
manual_review_family_gap_rows = 0
decline_family_gap_rows = 0

policy_stop_priority_gap_rows = 0
manual_review_priority_gap_rows = 0
counteroffer_priority_gap_rows = 0
approval_priority_gap_rows = 0

aggressive_override_rows = 0
aggressive_override_reason_code_gap_rows = 0

final_approve_rows = 10,695
final_counteroffer_rows = 19,067
final_manual_review_rows = 7,535
final_decline_rows = 12,703

distinct_primary_reason_code_count = 14

section_10_reason_code_assignment_status =
    SECTION_10_REASON_CODES_READY_FOR_LATEST_RUN_MATERIALIZATION
```

This is the expected Section 10 readiness status before Section 11.

```text
Status: PASS
```

---

# Final Section 10 QA signoff

```text
M2-01 Section 10 QA: ACCEPTED

No blockers.
No row-count issue.
No application-grain issue.
No required reason-code gap.
No outcome-family alignment issue.
No reason-code priority-range issue.
No decision-path alignment issue.
No decision-resolution-source alignment issue.
No failed-counteroffer reason-code issue.
No Option C aggressive override leakage.
Section 10 is ready for Section 11 latest-run materialization.
```

---

# Recommended Section 10 QA refinements

I would not change Section 10 reason-code logic. The logic is working.

I recommend two QA/export refinements:

```text
1. Update 10.4.11 so the triggered reason-code sample returns rows per final decision outcome,
   not only the first 100 rows overall.

2. Update 10.4.18 so it returns one NOT_APPLICABLE row for M2-01 rather than an empty result set.
```

A third optional refinement:

```text
3. Add a triggered-reason-code occurrence diagnostic that counts reason codes appearing anywhere in
   triggered_reason_code_list, not just as primary_reason_code.
```

That third refinement would be useful because it would confirm whether non-primary candidates such as `POLICY_STOP_HIGH_REQUESTED_PTI` are present as secondary / tertiary / triggered reasons even when they do not win primary rank.

My recommendation:

```text
Apply refinements 1 and 2 now.
Consider refinement 3 if you want stronger preservation evidence for the targeted Section 10 patches.
```

Section 10 is accepted either way.
<!-- END_MESSAGE C034-M01634 -->


---

<a id="c034-m01636"></a>

### C034-M01636

**Andrew** · 2026-05-17T17:06:28.257000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01636 -->
10.4.11 is because there is a LIMIT 100;  please provide all recommended and optional section 10 refinements as a full copy paste for each impacted section.
<!-- END_MESSAGE C034-M01636 -->


---

<a id="c034-m01641"></a>

### C034-M01641

**ChatGPT** · 2026-05-17T17:10:27.266717-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01641 -->
Below are the full copy-paste Section 10 QA refinements.

These are **QA/export refinements only**. They do not change the Section 10 reason-code assignment logic, final decision outcomes, latest-run materialization, archive persistence, or evidence capture. Section 10 remains the simulated strategy explanation-code layer using the candidate → deduplicate → rank → pivot pattern after Section 9 final decision resolution. fileciteturn396file35

Apply these three changes:

```text
1. Replace 10.4.11.
2. Add new 10.4.17A after 10.4.17 and before 10.4.18.
3. Replace 10.4.18.
```

---

## Replace 10.4.11 with this

```sql
/*-----------------------------------------------------------------------------------------------
10.4.11 Triggered reason-code list sample by outcome and primary reason code.

Purpose:
    Preserve deterministic examples of triggered reason-code lists for each final decision outcome and
    each primary reason-code theme.

Why this refinement exists:
    The prior version used a global LIMIT 100.

    Because the output was ordered from the beginning of the staged table, the export could show only
    APPROVE rows and fail to preserve examples for COUNTEROFFER, MANUAL_REVIEW, and DECLINE.

    This version samples within each:
        decision_outcome × primary_reason_code

    so all final outcome families and primary reason-code themes are represented.

Sampling design:
    Up to 5 rows are returned for each decision_outcome × primary_reason_code group.

    The sample is deterministic because it orders by application_id.

Interpretation:
    triggered_reason_code_list can contain more explanatory drivers than the primary / secondary /
    tertiary reason-code fields.

    primary_reason_code is the highest-priority simulated strategy explanation code.

    secondary_reason_code and tertiary_reason_code preserve the next two ranked simulated strategy
    explanation codes when available.

Boundary:
    These are simulated strategy explanation codes only.

    They are not customer-facing notices.
    They are not regulatory adverse-action reasons.
    They are not fair-lending conclusions.
-----------------------------------------------------------------------------------------------*/

WITH ranked_reason_code_examples AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY
                decision_outcome,
                primary_reason_code
            ORDER BY
                application_id
        ) AS sample_rank_within_outcome_reason_code,

        application_id,

        decision_outcome,
        decision_path,
        decision_resolution_source,

        primary_reason_family,
        primary_reason_code,
        secondary_reason_code,
        tertiary_reason_code,

        triggered_reason_code_list,
        reason_priority_rank,
        reason_code_count,

        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,
        dti_bucket,
        requested_exposure_tier,
        requested_expected_loss_tier,

        hard_policy_stop_flag,
        counteroffer_candidate_flag,
        ordinary_counteroffer_candidate_flag,
        aggressive_counteroffer_requested_structure_override_flag,
        manual_review_candidate_flag,
        clean_approval_candidate_flag,

        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason,
        failed_counteroffer_resolution,

        requested_amount,
        approved_amount,
        requested_payment_to_income_ratio,
        approved_payment_to_income_ratio,
        requested_expected_loss_amount,
        approved_expected_loss_amount

    FROM tmp_m2_stage_7_reason_code_assignment
)

SELECT
    'Deterministic sample returns up to 5 rows per final decision outcome × primary reason code; this avoids a global LIMIT returning only the first outcome family.'::TEXT
        AS interpretation_note,

    sample_rank_within_outcome_reason_code,

    application_id,

    decision_outcome,
    decision_path,
    decision_resolution_source,

    primary_reason_family,
    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,

    triggered_reason_code_list,
    reason_priority_rank,
    reason_code_count,

    product_type_policy_key,
    score_band_policy_key,
    strategy_risk_tier,
    requested_pti_bucket,
    dti_bucket,
    requested_exposure_tier,
    requested_expected_loss_tier,

    hard_policy_stop_flag,
    counteroffer_candidate_flag,
    ordinary_counteroffer_candidate_flag,
    aggressive_counteroffer_requested_structure_override_flag,
    manual_review_candidate_flag,
    clean_approval_candidate_flag,

    counteroffer_feasibility_pass_flag,
    counteroffer_feasibility_failure_reason,
    failed_counteroffer_resolution,

    requested_amount,
    approved_amount,
    requested_payment_to_income_ratio,
    approved_payment_to_income_ratio,
    requested_expected_loss_amount,
    approved_expected_loss_amount

FROM ranked_reason_code_examples

WHERE sample_rank_within_outcome_reason_code <= 5

ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    primary_reason_family,
    primary_reason_code,
    sample_rank_within_outcome_reason_code,
    application_id;
```

---

## Add new 10.4.17A after 10.4.17 and before 10.4.18

```sql
/*-----------------------------------------------------------------------------------------------
10.4.17A Triggered reason-code occurrence diagnostic.

Purpose:
    Count simulated reason codes that appear anywhere in triggered_reason_code_list, not only as the
    primary reason code.

Why this diagnostic exists:
    primary_reason_code shows the highest-priority explanation.

    triggered_reason_code_list preserves all ranked simulated strategy explanation candidates that
    survived the Section 10 reason-code family filter and deduplication logic.

    Some important reason codes may appear as secondary / tertiary / non-primary drivers and therefore
    may not appear in the primary reason-code distribution.

Example use:
    This diagnostic can confirm whether targeted candidate reason codes such as:

        POLICY_STOP_HIGH_REQUESTED_PTI

    appear anywhere in the triggered reason-code list even when they do not win the primary rank.

Delimiter note:
    The parser supports pipe-delimited or comma-delimited reason-code lists.

    Reason-code tokens are trimmed before counting.

Interpretation:
    triggered_reason_code_occurrence_count:
        Number of row-level appearances in triggered_reason_code_list.

    primary_reason_code_rows:
        Number of rows where the reason code was the primary reason code.

    non_primary_triggered_rows:
        Number of rows where the reason code appeared in the triggered list but did not win primary
        rank.

Boundary:
    This is a QA / preservation diagnostic only.

    It does not change reason-code assignment.
    It does not change reason-code priority.
    It does not modify final decisions.
    It does not modify latest-run or archive rows.
-----------------------------------------------------------------------------------------------*/

WITH stage7_summary AS (
    SELECT
        COUNT(*) AS stage7_row_count
    FROM tmp_m2_stage_7_reason_code_assignment
),

triggered_reason_tokens AS (
    SELECT
        s.application_id,
        s.decision_outcome,
        s.decision_path,
        s.decision_resolution_source,

        s.primary_reason_family,
        s.primary_reason_code,
        s.secondary_reason_code,
        s.tertiary_reason_code,
        s.reason_priority_rank,
        s.reason_code_count,

        NULLIF(BTRIM(t.reason_code_token), '') AS triggered_reason_code

    FROM tmp_m2_stage_7_reason_code_assignment s

    CROSS JOIN LATERAL REGEXP_SPLIT_TO_TABLE(
        COALESCE(s.triggered_reason_code_list, ''),
        '\s*(?:\||,)\s*'
    ) AS t(reason_code_token)
),

clean_triggered_reason_tokens AS (
    SELECT
        application_id,
        decision_outcome,
        decision_path,
        decision_resolution_source,

        primary_reason_family,
        primary_reason_code,
        secondary_reason_code,
        tertiary_reason_code,
        reason_priority_rank,
        reason_code_count,

        triggered_reason_code,

        CASE
            WHEN triggered_reason_code LIKE 'APPROVED_%'
                THEN 'APPROVAL'

            WHEN triggered_reason_code LIKE 'COUNTEROFFER_%'
                THEN 'COUNTEROFFER'

            WHEN triggered_reason_code LIKE 'MANUAL_REVIEW_%'
                THEN 'MANUAL_REVIEW'

            WHEN triggered_reason_code LIKE 'POLICY_STOP_%'
                THEN 'POLICY_STOP'

            ELSE 'UNCLASSIFIED_REASON_FAMILY'
        END AS inferred_reason_family

    FROM triggered_reason_tokens

    WHERE triggered_reason_code IS NOT NULL
),

triggered_reason_summary AS (
    SELECT
        triggered_reason_code,
        inferred_reason_family,

        COUNT(*) AS triggered_reason_code_occurrence_count,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) FILTER (
            WHERE triggered_reason_code = primary_reason_code
        ) AS primary_reason_code_rows,

        COUNT(*) FILTER (
            WHERE triggered_reason_code = secondary_reason_code
        ) AS secondary_reason_code_rows,

        COUNT(*) FILTER (
            WHERE triggered_reason_code = tertiary_reason_code
        ) AS tertiary_reason_code_rows,

        COUNT(*) FILTER (
            WHERE triggered_reason_code IS DISTINCT FROM primary_reason_code
        ) AS non_primary_triggered_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
        ) AS approve_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
        ) AS manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
        ) AS decline_rows,

        MIN(reason_priority_rank) FILTER (
            WHERE triggered_reason_code = primary_reason_code
        ) AS min_primary_reason_priority_rank_when_primary,

        AVG(reason_code_count)
            AS avg_reason_code_count_for_rows_with_reason

    FROM clean_triggered_reason_tokens

    GROUP BY
        triggered_reason_code,
        inferred_reason_family
)

SELECT
    'Counts reason codes anywhere in triggered_reason_code_list, not only primary_reason_code; useful for preserving secondary and tertiary strategy explanation themes.'::TEXT
        AS interpretation_note,

    s.triggered_reason_code,
    s.inferred_reason_family,

    s.triggered_reason_code_occurrence_count,
    s.distinct_application_id_count,

    ROUND(
        s.distinct_application_id_count::NUMERIC
        / NULLIF(t.stage7_row_count, 0),
        6
    ) AS pct_of_stage7_rows_with_reason,

    s.primary_reason_code_rows,
    s.secondary_reason_code_rows,
    s.tertiary_reason_code_rows,
    s.non_primary_triggered_rows,

    s.approve_rows,
    s.counteroffer_rows,
    s.manual_review_rows,
    s.decline_rows,

    s.min_primary_reason_priority_rank_when_primary,
    s.avg_reason_code_count_for_rows_with_reason

FROM triggered_reason_summary s

CROSS JOIN stage7_summary t

ORDER BY
    CASE s.inferred_reason_family
        WHEN 'POLICY_STOP' THEN 1
        WHEN 'MANUAL_REVIEW' THEN 2
        WHEN 'COUNTEROFFER' THEN 3
        WHEN 'APPROVAL' THEN 4
        ELSE 99
    END,
    s.triggered_reason_code_occurrence_count DESC,
    s.triggered_reason_code;
```

---

## Replace 10.4.18 with this

```sql
/*-----------------------------------------------------------------------------------------------
10.4.18 Option C aggressive counteroffer override reason-code diagnostic.

Purpose:
    Review simulated reason-code behavior for rows that entered counteroffer feasibility through the
    aggressive requested-structure override path.

Why this diagnostic returns a row even when no aggressive override rows exist:
    For BASELINE_STRATEGY and non-aggressive strategies, zero aggressive override rows is expected.

    A one-row NOT_APPLICABLE diagnostic is easier to preserve in CSV exports than an empty result set.

Interpretation:
    AGGRESSIVE_OVERRIDE_REASON_CODE_BREAKDOWN:
        Aggressive override rows exist and are summarized by product, score, risk, requested PTI,
        final outcome, reason-code family, reason-code assignment, and expected aggressive override
        traceability.

    OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS:
        The current strategy did not produce aggressive override rows, which is expected for baseline
        and non-aggressive strategies.

    AGGRESSIVE_OVERRIDE_NO_ROWS_REVIEW_STRATEGY_CONTEXT:
        The current strategy is marked aggressive expansion but no aggressive override rows appeared.
        This may be acceptable for some populations, but should be reviewed.

    AGGRESSIVE_OVERRIDE_REASON_TRACE_PRESENT:
        The expected aggressive override path-specific simulated reason code appears in
        triggered_reason_code_list.

    AGGRESSIVE_OVERRIDE_REASON_TRACE_MISSING_REVIEW:
        An aggressive override row exists, but the expected path-specific simulated reason code is
        missing from triggered_reason_code_list.

Boundary:
    These are simulated strategy explanation codes only.

    They are not customer notices.
    They are not regulatory adverse-action reasons.
    They are not fair-lending conclusions.

    This diagnostic does not modify reason codes, final decisions, latest-run rows, archive rows, or
    evidence rows.
-----------------------------------------------------------------------------------------------*/

WITH strategy_context AS (
    SELECT
        MAX(strategy_name)
            AS strategy_name,

        MAX(counteroffer_strategy_variant)
            AS counteroffer_strategy_variant,

        COALESCE(
            BOOL_OR(aggressive_counteroffer_expansion_enabled),
            FALSE
        ) AS aggressive_counteroffer_expansion_enabled,

        COUNT(*) AS stage7_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS aggressive_override_rows

    FROM tmp_m2_stage_7_reason_code_assignment
),

aggressive_override_rows AS (
    SELECT
        s.*,

        CASE
            WHEN decision_outcome = 'COUNTEROFFER'
                THEN 'COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE'

            WHEN decision_outcome = 'MANUAL_REVIEW'
             AND preliminary_decision_outcome = 'COUNTEROFFER'
             AND counteroffer_feasibility_pass_flag IS FALSE
             AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE'

            WHEN decision_outcome = 'DECLINE'
             AND preliminary_decision_outcome = 'COUNTEROFFER'
             AND counteroffer_feasibility_pass_flag IS FALSE
             AND failed_counteroffer_resolution = 'DECLINE'
                THEN 'POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE'

            ELSE NULL
        END AS expected_aggressive_override_reason_code

    FROM tmp_m2_stage_7_reason_code_assignment s

    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
),

aggressive_override_trace_rows AS (
    SELECT
        a.*,

        CASE
            WHEN expected_aggressive_override_reason_code IS NULL
                THEN 'AGGRESSIVE_OVERRIDE_REASON_TRACE_NOT_EXPECTED_FOR_PATH'

            WHEN POSITION(
                    expected_aggressive_override_reason_code
                    IN COALESCE(triggered_reason_code_list, '')
                 ) > 0
                THEN 'AGGRESSIVE_OVERRIDE_REASON_TRACE_PRESENT'

            ELSE 'AGGRESSIVE_OVERRIDE_REASON_TRACE_MISSING_REVIEW'
        END AS aggressive_override_reason_trace_status

    FROM aggressive_override_rows a
),

aggressive_override_breakdown AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,

        preliminary_decision_outcome,
        exposure_treatment_status,

        decision_outcome,
        decision_path,
        decision_resolution_source,

        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason,
        failed_counteroffer_resolution,

        expected_aggressive_override_reason_code,
        aggressive_override_reason_trace_status,

        primary_reason_family,
        primary_reason_code,
        secondary_reason_code,
        tertiary_reason_code,

        COUNT(*) AS row_count,

        COUNT(*) FILTER (
            WHERE aggressive_override_reason_trace_status =
                  'AGGRESSIVE_OVERRIDE_REASON_TRACE_MISSING_REVIEW'
        ) AS reason_trace_gap_rows,

        AVG(reason_code_count)
            AS avg_reason_code_count,

        AVG(requested_amount)
            AS avg_requested_amount,

        AVG(approved_amount) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_amount_positive_offer_rows,

        AVG(exposure_reduction_pct) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_exposure_reduction_pct_positive_offer_rows,

        AVG(approved_payment_to_income_ratio) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_pti_positive_offer_rows,

        AVG(approved_expected_loss_amount) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_el_positive_offer_rows

    FROM aggressive_override_trace_rows

    GROUP BY
        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,

        preliminary_decision_outcome,
        exposure_treatment_status,

        decision_outcome,
        decision_path,
        decision_resolution_source,

        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason,
        failed_counteroffer_resolution,

        expected_aggressive_override_reason_code,
        aggressive_override_reason_trace_status,

        primary_reason_family,
        primary_reason_code,
        secondary_reason_code,
        tertiary_reason_code
)

SELECT
    'Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY; path-specific override reason traces should appear when aggressive override rows exist.'::TEXT
        AS interpretation_note,

    'AGGRESSIVE_OVERRIDE_REASON_CODE_BREAKDOWN'::TEXT
        AS option_c_aggressive_override_reason_code_status,

    sc.strategy_name,
    sc.counteroffer_strategy_variant,
    sc.aggressive_counteroffer_expansion_enabled,

    b.product_type_policy_key,
    b.score_band_policy_key,
    b.strategy_risk_tier,
    b.requested_pti_bucket,

    b.preliminary_decision_outcome,
    b.exposure_treatment_status,

    b.decision_outcome,
    b.decision_path,
    b.decision_resolution_source,

    b.counteroffer_feasibility_pass_flag,
    b.counteroffer_feasibility_failure_reason,
    b.failed_counteroffer_resolution,

    b.expected_aggressive_override_reason_code,
    b.aggressive_override_reason_trace_status,

    b.primary_reason_family,
    b.primary_reason_code,
    b.secondary_reason_code,
    b.tertiary_reason_code,

    b.row_count,

    ROUND(
        b.row_count::NUMERIC
        / NULLIF(sc.aggressive_override_rows, 0),
        6
    ) AS pct_of_aggressive_override_rows,

    b.reason_trace_gap_rows,
    b.avg_reason_code_count,

    b.avg_requested_amount,
    b.avg_approved_amount_positive_offer_rows,
    b.avg_exposure_reduction_pct_positive_offer_rows,
    b.avg_approved_pti_positive_offer_rows,
    b.avg_approved_el_positive_offer_rows

FROM aggressive_override_breakdown b

CROSS JOIN strategy_context sc

UNION ALL

SELECT
    'Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY; path-specific override reason traces should appear when aggressive override rows exist.'::TEXT
        AS interpretation_note,

    CASE
        WHEN sc.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
          OR sc.aggressive_counteroffer_expansion_enabled IS TRUE
            THEN 'AGGRESSIVE_OVERRIDE_NO_ROWS_REVIEW_STRATEGY_CONTEXT'
        ELSE 'OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS'
    END AS option_c_aggressive_override_reason_code_status,

    sc.strategy_name,
    sc.counteroffer_strategy_variant,
    sc.aggressive_counteroffer_expansion_enabled,

    NULL::TEXT AS product_type_policy_key,
    NULL::TEXT AS score_band_policy_key,
    NULL::TEXT AS strategy_risk_tier,
    NULL::TEXT AS requested_pti_bucket,

    NULL::TEXT AS preliminary_decision_outcome,
    NULL::TEXT AS exposure_treatment_status,

    NULL::TEXT AS decision_outcome,
    NULL::TEXT AS decision_path,
    NULL::TEXT AS decision_resolution_source,

    NULL::BOOLEAN AS counteroffer_feasibility_pass_flag,
    NULL::TEXT AS counteroffer_feasibility_failure_reason,
    NULL::TEXT AS failed_counteroffer_resolution,

    NULL::TEXT AS expected_aggressive_override_reason_code,
    NULL::TEXT AS aggressive_override_reason_trace_status,

    NULL::TEXT AS primary_reason_family,
    NULL::TEXT AS primary_reason_code,
    NULL::TEXT AS secondary_reason_code,
    NULL::TEXT AS tertiary_reason_code,

    0::BIGINT AS row_count,

    NULL::NUMERIC AS pct_of_aggressive_override_rows,

    0::BIGINT AS reason_trace_gap_rows,
    NULL::NUMERIC AS avg_reason_code_count,

    NULL::NUMERIC AS avg_requested_amount,
    NULL::NUMERIC AS avg_approved_amount_positive_offer_rows,
    NULL::NUMERIC AS avg_exposure_reduction_pct_positive_offer_rows,
    NULL::NUMERIC AS avg_approved_pti_positive_offer_rows,
    NULL::NUMERIC AS avg_approved_el_positive_offer_rows

FROM strategy_context sc

WHERE sc.aggressive_override_rows = 0

ORDER BY
    option_c_aggressive_override_reason_code_status,
    product_type_policy_key NULLS FIRST,
    score_band_policy_key NULLS FIRST,
    strategy_risk_tier NULLS FIRST,
    requested_pti_bucket NULLS FIRST,
    decision_outcome NULLS FIRST,
    primary_reason_family NULLS FIRST,
    primary_reason_code NULLS FIRST;
```

These three updates should make Section 10 QA preservation-ready:

```text
10.4.11 now captures examples across all outcomes / reason themes.
10.4.17A now counts all triggered reason-code occurrences, including non-primary drivers.
10.4.18 now produces a deliberate NOT_APPLICABLE row for baseline/non-aggressive runs.
```
<!-- END_MESSAGE C034-M01641 -->


---

<a id="c034-m01642"></a>

### C034-M01642

**Andrew** · 2026-05-17T17:26:33.705000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01642 -->
pleased re-review refined section 10 QA:
<!-- END_MESSAGE C034-M01642 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.17A_QA_triggered_reason_code_occurrence_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.18_QA_option_c_aggressive_counteroffer_override_reason_code_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.11_QA_triggered_reason_code_list_sample_by_outcome(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01647"></a>

### C034-M01647

**ChatGPT** · 2026-05-17T17:31:56.119317-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01647 -->
## Refined Section 10 QA re-review verdict

```text
Section 10 refined QA status: PASS
10.4.11 sample refinement: PASS
10.4.17A triggered reason-code occurrence diagnostic: PASS
10.4.18 Option C not-applicable export behavior: PASS
Blockers: none
Required logic changes: none
Recommended minor polish: one comment / label-harmonization check
```

Section 10 remains accepted. The refined QA outputs now better preserve reason-code evidence across all final outcome families, primary reason-code themes, secondary / tertiary reason-code themes, and Option C not-applicable context. This is aligned with Section 10’s role as the simulated strategy explanation-code layer after Section 9 final decision resolution. fileciteturn396file35

---

## 10.4.11 — Triggered reason-code list sample by outcome

```text
Status: PASS
Output rows: 70
Sampling design: working correctly
```

The prior issue was that a global `LIMIT 100` could return only early-sorted outcome rows. The refined version fixed that.

The output now returns **up to 5 rows per final decision outcome × primary reason code**:

```text
APPROVE           5 rows
COUNTEROFFER     20 rows
MANUAL_REVIEW    20 rows
DECLINE          25 rows
```

That reconciles to:

```text
14 primary reason-code themes × 5 sample rows each = 70 rows
```

Coverage is complete across all observed primary reason codes:

```text
APPROVE
    APPROVED_AS_REQUESTED

COUNTEROFFER
    COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
    COUNTEROFFER_ELEVATED_SYNTHETIC_RISK
    COUNTEROFFER_EXPECTED_LOSS_LIMIT
    COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT

MANUAL_REVIEW
    MANUAL_REVIEW_BORDERLINE_PROFILE
    MANUAL_REVIEW_DTI_REVIEW
    MANUAL_REVIEW_FAILED_COUNTEROFFER
    MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW

DECLINE
    POLICY_STOP_BANKRUPTCY
    POLICY_STOP_MAJOR_DEROGATORY
    POLICY_STOP_SEVERE_DELINQUENCY
    POLICY_STOP_SEVERE_DTI
    POLICY_STOP_SEVERE_SYNTHETIC_RISK
```

This output is now preservation-ready. It gives representative row-level examples for every primary explanation theme instead of only showing approvals.

---

## 10.4.17A — Triggered reason-code occurrence diagnostic

```text
Status: PASS
Output reason-code rows: 25
Total triggered reason-code occurrences: 126,833
Primary reason-code rows: 50,000
```

This diagnostic is doing exactly what we wanted. It counts reason codes appearing anywhere in `triggered_reason_code_list`, not just the winning `primary_reason_code`.

The key reconciliation is strong:

```text
primary_reason_code_rows total = 50,000
```

That confirms every application has exactly one primary reason code, while the larger total occurrence count reflects multiple triggered reason codes per row. That is expected under the Section 10 candidate → rank → pivot design.

Examples of useful non-primary evidence now visible:

```text
POLICY_STOP_NO_OFFER
    occurrence_count = 12,703
    primary_reason_code_rows = 0
    non_primary_triggered_rows = 12,703

COUNTEROFFER_FEASIBLE_REDUCED_EXPOSURE
    occurrence_count = 19,067
    primary_reason_code_rows = 0
    non_primary_triggered_rows = 19,067

MANUAL_REVIEW_RESIDUAL_STRATEGY_REVIEW
    occurrence_count = 7,535
    primary_reason_code_rows = 0
    non_primary_triggered_rows = 7,535

COUNTEROFFER_MULTIPLE_CONSTRAINTS
    occurrence_count = 5,269
    primary_reason_code_rows = 0
    non_primary_triggered_rows = 5,269
```

The diagnostic also confirms that lower-priority / secondary policy-stop and review themes are preserved:

```text
POLICY_STOP_REQUESTED_EL_SEVERE
    occurrence_count = 1,902

POLICY_STOP_REQUESTED_PTI_SEVERE
    occurrence_count = 807

MANUAL_REVIEW_EXPECTED_LOSS_REVIEW
    occurrence_count = 2,009

MANUAL_REVIEW_AFFORDABILITY_REVIEW
    occurrence_count = 1,187

MANUAL_REVIEW_SEVERE_REQUESTED_STRUCTURE
    occurrence_count = 202
```

This is a meaningful improvement because it shows that the reason-code layer is not hiding non-primary strategy drivers.

---

## 10.4.18 — Option C aggressive override reason-code diagnostic

```text
Status: PASS
Output rows: 1
Diagnostic status: OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS
```

The refinement worked correctly. Instead of returning an empty export for M2-01, the query now returns a deliberate not-applicable row:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
row_count = 0
reason_trace_gap_rows = 0
```

That is the correct baseline posture. M2-01 should not have aggressive override rows, and the export now makes that explicit.

This is consistent with the broader Option C design: aggressive override rows are expected only under `AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY`, not baseline.

---

## Minor polish recommendation

The only thing I would polish is a **comment / label harmonization issue** in 10.4.17A.

Your output shows the requested-PTI policy-stop code as:

```text
POLICY_STOP_REQUESTED_PTI_SEVERE
```

That is a clear and good label. If the 10.4.17A comment still says:

```text
POLICY_STOP_HIGH_REQUESTED_PTI
```

change the comment example to:

```text
POLICY_STOP_REQUESTED_PTI_SEVERE
```

No logic change is needed. This is just to keep the QA commentary aligned with the actual reason-code vocabulary.

---

## Final signoff

```text
Refined Section 10 QA: ACCEPTED

No blockers.
No row-count issues.
No primary reason-code coverage issue.
No outcome-family coverage issue.
No triggered reason-code occurrence issue.
No Option C baseline-posture issue.
No additional Section 10 QA logic refinements recommended.
```

Section 10 QA is now preservation-ready.
<!-- END_MESSAGE C034-M01647 -->


---

<a id="c034-m01649"></a>

### C034-M01649

**Andrew** · 2026-05-17T18:15:03.972000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01649 -->
review section 11 QA:
<!-- END_MESSAGE C034-M01649 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.6_QA_count_by_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.7_QA_product_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.8_QA_score_band_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.9_QA_product_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.10_QA_score_band_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.11_QA_strategy_risk_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.12_QA_requested_pti_bucket_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.13_QA_mixed_signal_profile_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.14_QA_requested_versus_approved_exposure_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.15_QA_requested_versus_approved_pti_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.16_QA_requested_versus_approved_expected_loss_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.17_QA_simulated_offer_exposure_profile.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.18_QA_section_11_readiness_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.1_QA_latest_run_row_count_and_distinct_application_id_count.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.2_QA_latest_run_strategy_identity_and_module_1_lineage.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.3_QA_count_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.4_QA_count_by_decision_path.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.5_QA_option_c_counteroffer_strategy_split_latest_run_diagnostic.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01659"></a>

### C034-M01659

**ChatGPT** · 2026-05-17T18:20:37.163323-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01659 -->
## M2-01 Section 11 QA review verdict

```text
Section 11 QA status: NOT FULLY SIGNED OFF YET
Core latest-run output: PASS
Latest-run row grain: PASS
Strategy / Module 1 lineage: PASS
Decision outcomes: PASS
Reason-code preservation: PASS
Option C field preservation: PASS
Amount / PTI / Expected Loss behavior: substantively PASS
Readiness summary: REVIEW due to one QA-convention bug
Blocker type: QA readiness check false positive, not a data/output defect
Required action: patch 11.5.18 approved Expected Loss convention check
```

Section 11 is the latest-run materialization layer: it consumes `tmp_m2_stage_7_reason_code_assignment`, creates `credit_decisioning_sim.strategy_decisions`, uses an explicit output field list, preserves Module 1 lineage, Module 2 strategy metadata, decision fields, exposure fields, reason-code fields, and Option C counteroffer path evidence before archive persistence. fileciteturn396file31

The latest-run output itself looks good. The issue is isolated to the **11.5.18 readiness summary**.

---

## 1. Structural latest-run checks — PASS

**11.5.1** confirms:

```text
latest_run_rows = 50,000
distinct_application_id_count = 50,000
```

This is exactly the expected M2-01 row grain.

**11.5.2** confirms one clean strategy / source slice:

```text
strategy_name = BASELINE_STRATEGY
strategy_run_id = M2-01_BASELINE_STRATEGY_V1_0_RUN
archive_run_flag = true
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
failed_counteroffer_resolution = MANUAL_REVIEW
module1_input_source = ARCHIVE
module1_scenario_set_name = MODULE1_V2_BASELINE_SET
module1_scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1
row_count = 50,000
distinct_application_id_count = 50,000
```

**Status: PASS**

---

## 2. Final decision distribution — PASS

**11.5.3** final outcomes reconcile to 50,000:

```text
APPROVE          10,695   21.39%
COUNTEROFFER     19,067   38.13%
MANUAL_REVIEW     7,535   15.07%
DECLINE          12,703   25.41%
```

**11.5.4** decision paths reconcile cleanly:

```text
APPROVE_AS_REQUESTED                    10,695
COUNTEROFFER_FEASIBLE                   19,067
COUNTEROFFER_NOT_FEASIBLE_REVIEW         2,219
MANUAL_REVIEW_CANDIDATE                  5,316
HARD_POLICY_STOP                         5,889
SEVERE_SYNTHETIC_RISK                    6,369
SEVERE_DTI_CAPACITY                        445
```

The paths map correctly to final outcomes.

**Status: PASS**

---

## 3. Option C latest-run preservation — PASS

**11.5.5** confirms the correct M2-01 baseline posture:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive_override_rows = 0
```

Ordinary counteroffer evidence is preserved:

```text
ordinary_counteroffer_candidate_rows = 21,286
```

Aggressive override evidence is correctly inactive:

```text
aggressive_override_rows = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
```

**Status: PASS**

Minor export note only: in **11.5.5**, the column name `latest_run_rows` is really a grouped row count by outcome / reason-code combination. It is not wrong, but `group_row_count` or `latest_run_group_rows` would be clearer. This is optional.

---

## 4. Primary reason-code preservation — PASS

**11.5.6** preserves the Section 10 reason-code distribution:

```text
APPROVED_AS_REQUESTED                         10,695

COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT            8,905
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT          5,021
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK           3,853
COUNTEROFFER_EXPECTED_LOSS_LIMIT               1,288

MANUAL_REVIEW_FAILED_COUNTEROFFER              2,219
MANUAL_REVIEW_BORDERLINE_PROFILE               1,926
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW            1,790
MANUAL_REVIEW_DTI_REVIEW                       1,600

POLICY_STOP_SEVERE_SYNTHETIC_RISK              6,369
POLICY_STOP_SEVERE_DELINQUENCY                 2,955
POLICY_STOP_MAJOR_DEROGATORY                   2,107
POLICY_STOP_BANKRUPTCY                           827
POLICY_STOP_SEVERE_DTI                           445
```

Totals reconcile to 50,000.

**Status: PASS**

---

## 5. Product, score, risk, PTI, and mixed-signal diagnostics — PASS

The segment diagnostics are coherent:

```text
11.5.7  product × decision outcome: PASS
11.5.8  score band × decision outcome: PASS
11.5.9  product × primary reason code: PASS
11.5.10 score band × primary reason code: PASS
11.5.11 strategy risk tier × decision outcome: PASS
11.5.12 requested PTI bucket × decision outcome: PASS
11.5.13 mixed-signal profile × decision outcome: PASS
```

Key directional checks are good:

```text
Severe synthetic-risk rows resolve entirely to DECLINE.
Approvals concentrate in low/moderate risk and non-mixed-signal rows.
Counteroffers remain strong in near-prime / exposure-constrained segments.
Manual review remains unresolved.
Decline uses zero approved exposure / zero approved Expected Loss convention.
```

**Status: PASS**

---

## 6. Requested versus approved exposure / PTI / Expected Loss — substantively PASS

**11.5.14** exposure convention:

```text
APPROVE:
    avg requested amount = avg approved amount

COUNTEROFFER:
    avg requested amount = 176,816.14
    avg approved amount = 136,791.79
    avg exposure reduction = 40,024.36
    avg exposure reduction pct = 19.786%

MANUAL_REVIEW:
    approved amount = NULL

DECLINE:
    approved amount = 0
```

**11.5.15** PTI convention:

```text
APPROVE:
    approved PTI = requested PTI

COUNTEROFFER:
    requested PTI = 0.185296
    approved PTI = 0.143459
    PTI reduction = 0.041837

MANUAL_REVIEW:
    approved PTI = NULL

DECLINE:
    approved PTI = 0
```

**11.5.16** Expected Loss convention:

```text
APPROVE:
    requested EL = approved EL = 773.063017 average

COUNTEROFFER:
    requested EL = 3,474.715662 average
    approved EL = 2,637.215254 average

MANUAL_REVIEW:
    approved EL = NULL

DECLINE:
    approved EL = 0
```

**11.5.17** simulated offer exposure profile reconciles:

```text
simulated_offer_exposure_flag = TRUE     29,762
simulated_offer_exposure_flag = FALSE    20,238
```

That equals:

```text
APPROVE + COUNTEROFFER = 10,695 + 19,067 = 29,762
MANUAL_REVIEW + DECLINE = 7,535 + 12,703 = 20,238
```

**Status: PASS**

---

## 7. Readiness summary — BLOCKER / QA false positive

**11.5.18** returns:

```text
section_11_latest_run_output_status =
REVIEW_SECTION_11_LATEST_RUN_OUTPUT_BEFORE_ARCHIVE_PERSISTENCE
```

The cause is:

```text
approved_expected_loss_convention_gap_rows = 10,695
```

That equals exactly the number of final `APPROVE` rows.

Everything else important is clean:

```text
latest_run_row_count = 50,000
distinct_application_id_count = 50,000
distinct_strategy_identity_count = 1
distinct_module1_scenario_population_count = 1
required_metadata_gap_rows = 0
latest_output_created_ts_null_rows = 0
final_decision_gap_rows = 0
final_flag_reconciliation_gap_rows = 0
simulated_offer_exposure_flag_gap_rows = 0
approved_amount_convention_gap_rows = 0
reason_code_gap_rows = 0
reason_family_alignment_gap_rows = 0
option_c_field_gap_rows = 0
aggressive_override_reason_trace_gap_rows = 0
```

### Diagnosis

This looks like a **readiness-query bug**, not a latest-run output bug.

The readiness query appears to be recomputing approved Expected Loss for `APPROVE` rows as:

```sql
approved_amount * estimated_pd * estimated_lgd
```

But the Module 2 output convention for `APPROVE` is simpler and more stable:

```text
APPROVE preserves requested exposure.
APPROVE preserves requested Expected Loss.
```

Your QA outputs prove that for `APPROVE` rows:

```text
avg_requested_expected_loss_amount = 773.063017
avg_approved_expected_loss_amount = 773.063017
```

So the 10,695 gap rows are almost certainly caused by a mismatch between a recomputed formula and the stored Module 1 requested Expected Loss value, likely due to precision / rounding lineage. Section 11 should validate the **business convention**, not falsely reject all approvals.

---

# Required Section 11 patch

Patch **11.5.18** only.

Inside the `latest_run_summary` CTE, find the current block that creates:

```sql
approved_expected_loss_convention_gap_rows
```

Replace that metric with this version:

```sql
        /*******************************************************************************************
        Approved Expected Loss convention checks.

        APPROVE:
            approved_expected_loss_amount should preserve requested_expected_loss_amount.

            Do not recompute APPROVE Expected Loss from approved_amount × estimated_pd × estimated_lgd
            inside this readiness check, because requested_expected_loss_amount is the governed
            Module 1 requested-exposure Expected Loss carried into Module 2.

        COUNTEROFFER:
            approved_expected_loss_amount should be positive and below requested_expected_loss_amount.

            This confirms that reduced exposure lowered approved-exposure Expected Loss.

        MANUAL_REVIEW:
            approved_expected_loss_amount should remain NULL.

        DECLINE:
            approved_expected_loss_amount should be zero.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                    AND approved_expected_loss_amount
                        IS DISTINCT FROM requested_expected_loss_amount
                  )
               OR (
                    decision_outcome = 'COUNTEROFFER'
                    AND (
                            approved_expected_loss_amount IS NULL
                         OR approved_expected_loss_amount <= 0
                         OR approved_expected_loss_amount >= requested_expected_loss_amount
                    )
                  )
               OR (
                    decision_outcome = 'MANUAL_REVIEW'
                    AND approved_expected_loss_amount IS NOT NULL
                  )
               OR (
                    decision_outcome = 'DECLINE'
                    AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
                  )
        ) AS approved_expected_loss_convention_gap_rows,
```

After this patch, **11.5.18** should return:

```text
approved_expected_loss_convention_gap_rows = 0
section_11_latest_run_output_status =
SECTION_11_LATEST_RUN_OUTPUT_READY_FOR_ARCHIVE_PERSISTENCE
```

---

## Recommended rerun path

You do **not** need to rebuild the whole M2-01 output for this.

Run only:

```text
11.5.18 Section 11 readiness summary
```

against the already-materialized:

```sql
credit_decisioning_sim.strategy_decisions
```

If the patched readiness row passes, then Section 11 can be signed off.

---

## Final Section 11 review status

```text
M2-01 Section 11 QA: CONDITIONALLY ACCEPTED

Core output is clean.
Latest-run table is structurally correct.
Lineage is correct.
Decision outcomes are correct.
Reason-code preservation is correct.
Option C latest-run fields are present and correct.
Amount / PTI / Expected Loss behavior is substantively correct.

Not fully signed off until:
    11.5.18 approved Expected Loss convention check is patched
    and readiness status returns:
        SECTION_11_LATEST_RUN_OUTPUT_READY_FOR_ARCHIVE_PERSISTENCE
```
<!-- END_MESSAGE C034-M01659 -->


---

<a id="c034-m01660"></a>

### C034-M01660

**Andrew** · 2026-05-17T18:27:54.601000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01660 -->
review 11.5.18 readiness QA again.  then provide full copy paste for all section 11 QA refinements (recommendeed and optional)
<!-- END_MESSAGE C034-M01660 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.18_QA_section_11_readiness_summary(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01671"></a>

### C034-M01671

**ChatGPT** · 2026-05-17T18:36:33.201821-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01671 -->
According to a document from 2026-05-17, Section 11 is the permanent latest-run materialization layer: it creates `credit_decisioning_sim.strategy_decisions`, preserves final simulated outcomes, approved exposure/economics, reason-code fields, and Option C ordinary/aggressive counteroffer path evidence for downstream archive, QA, frontier, and evidence capture. fileciteturn400file5

## 11.5.18 re-review verdict

Your updated **11.5.18 readiness QA now passes**.

```text
latest_run_row_count = 50,000
distinct_application_id_count = 50,000
distinct_strategy_identity_count = 1
distinct_module1_scenario_population_count = 1

required_metadata_gap_rows = 0
latest_output_created_ts_null_rows = 0
final_decision_gap_rows = 0
final_flag_reconciliation_gap_rows = 0
simulated_offer_exposure_flag_gap_rows = 0
approved_amount_convention_gap_rows = 0
approved_expected_loss_convention_gap_rows = 0
reason_code_gap_rows = 0
reason_family_alignment_gap_rows = 0
option_c_field_gap_rows = 0
aggressive_override_reason_trace_gap_rows = 0

section_11_latest_run_output_status =
SECTION_11_LATEST_RUN_OUTPUT_READY_FOR_ARCHIVE_PERSISTENCE
```

Section 11 is now signed off from the QA-readiness standpoint. The approved Expected Loss false positive is resolved.

Below are the full copy-paste Section 11 QA refinements I recommend preserving.

---

# Replace 11.5.5 with this

```sql
/*-----------------------------------------------------------------------------------------------
11.5.5 Option C counteroffer strategy split latest-run diagnostic.

Purpose:
    Show how the latest-run output preserved ordinary versus aggressive counteroffer path evidence.

Why this matters:
    Option C introduces two counteroffer postures:

        SELECTIVE_FEASIBILITY
            ordinary governed counteroffer candidates only.

        AGGRESSIVE_EXPANSION
            ordinary candidates plus governed aggressive requested-structure override candidates.

    This diagnostic confirms whether the latest-run table preserved that evidence after permanent
    materialization.

Export note:
    latest_run_group_rows is a grouped row count by strategy / outcome / reason-code combination.

    It is not the total latest-run row count.

Boundary:
    This is latest-run output diagnostics only.

    It is not archive validation.
    It is not matched comparison.
    It is not full QA.
-----------------------------------------------------------------------------------------------*/

SELECT
    'latest_run_group_rows is grouped by strategy, outcome, reason family, and primary reason code; it is not the total latest-run row count.'::TEXT
        AS interpretation_note,

    strategy_name,
    counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled,

    decision_outcome,
    primary_reason_family,
    primary_reason_code,

    COUNT(*) AS latest_run_group_rows,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_latest_run,

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

    COUNT(*) FILTER (
        WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND COALESCE(triggered_reason_code_list, '') LIKE
                '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
    ) AS aggressive_override_counteroffer_reason_rows,

    COUNT(*) FILTER (
        WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND COALESCE(triggered_reason_code_list, '') LIKE
                '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
    ) AS aggressive_override_manual_review_reason_rows,

    COUNT(*) FILTER (
        WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND COALESCE(triggered_reason_code_list, '') LIKE
                '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
    ) AS aggressive_override_decline_reason_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY
    strategy_name,
    counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled,
    decision_outcome,
    primary_reason_family,
    primary_reason_code

ORDER BY
    strategy_name,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    latest_run_group_rows DESC,
    primary_reason_code;
```

---

# Replace 11.5.14 with this

```sql
/*-----------------------------------------------------------------------------------------------
11.5.14 Requested versus approved exposure by decision_outcome.

Purpose:
    Review final exposure assignment conventions in the latest-run output.

Expected:
    APPROVE:
        approved_amount should equal requested_amount.

    COUNTEROFFER:
        approved_amount should be positive and below requested_amount.

    MANUAL_REVIEW:
        approved_amount should remain NULL because the simulated outcome is unresolved.

    DECLINE:
        approved_amount should be zero because Module 2 uses the no-offer zero-exposure convention.

Documentation note:
    NULL approved amount means unresolved treatment.
    Zero approved amount means no-offer treatment.
    Positive approved amount means simulated positive offer exposure.

Boundary:
    This is a latest-run output diagnostic.

    It does not modify latest-run rows.
    It does not validate archive persistence.
-----------------------------------------------------------------------------------------------*/

SELECT
    'NULL approved amount means unresolved MANUAL_REVIEW; zero approved amount means no-offer DECLINE convention; positive approved amount means simulated positive offer exposure.'::TEXT
        AS interpretation_note,

    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END AS decision_outcome_rank,

    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_latest_run,

    COUNT(*) FILTER (
        WHERE approved_amount IS NULL
    ) AS null_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount = 0
    ) AS zero_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount > 0
    ) AS positive_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS simulated_offer_exposure_rows,

    AVG(requested_amount)
        AS avg_requested_amount,

    AVG(approved_amount)
        AS avg_approved_amount_non_null_rows,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_rows_convention_adjusted,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    AVG(requested_amount - approved_amount) FILTER (
        WHERE approved_amount IS NOT NULL
    ) AS avg_exposure_difference_for_non_null_approved_rows,

    AVG(exposure_reduction_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_exposure_reduction_amount_positive_offer_rows,

    AVG(exposure_reduction_pct) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_exposure_reduction_pct_positive_offer_rows,

    SUM(requested_amount)
        AS total_requested_amount,

    SUM(COALESCE(approved_amount, 0))
        AS total_approved_amount_all_rows_convention_adjusted

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

# Replace 11.5.15 with this

```sql
/*-----------------------------------------------------------------------------------------------
11.5.15 Requested versus approved PTI by decision_outcome.

Purpose:
    Review final affordability treatment in the latest-run output.

Expected:
    APPROVE:
        approved_payment_to_income_ratio should equal requested_payment_to_income_ratio.

    COUNTEROFFER:
        approved_payment_to_income_ratio should generally be lower than requested PTI because
        exposure is reduced.

    MANUAL_REVIEW:
        approved_payment_to_income_ratio should remain NULL because the simulated outcome is
        unresolved.

    DECLINE:
        approved_payment_to_income_ratio should be zero because Module 2 uses the no-offer
        zero-exposure convention.

Documentation note:
    NULL approved PTI means unresolved treatment.
    Zero approved PTI means no-offer treatment.
    Positive approved PTI means simulated positive offer exposure.

Boundary:
    approved_payment_to_income_ratio is a strategy-simulation affordability proxy.

    This is a latest-run output diagnostic.
-----------------------------------------------------------------------------------------------*/

SELECT
    'NULL approved PTI means unresolved MANUAL_REVIEW; zero approved PTI means no-offer DECLINE convention; positive approved PTI means simulated positive offer exposure.'::TEXT
        AS interpretation_note,

    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END AS decision_outcome_rank,

    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_latest_run,

    COUNT(*) FILTER (
        WHERE approved_payment_to_income_ratio IS NULL
    ) AS null_approved_pti_rows,

    COUNT(*) FILTER (
        WHERE approved_payment_to_income_ratio = 0
    ) AS zero_approved_pti_rows,

    COUNT(*) FILTER (
        WHERE approved_payment_to_income_ratio > 0
    ) AS positive_approved_pti_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS simulated_offer_exposure_rows,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio)
        AS avg_approved_pti_non_null_rows,

    AVG(COALESCE(approved_payment_to_income_ratio, 0))
        AS avg_approved_pti_all_rows_convention_adjusted,

    AVG(approved_payment_to_income_ratio) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_pti_positive_offer_rows,

    AVG(requested_payment_to_income_ratio - approved_payment_to_income_ratio) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_pti_reduction_positive_offer_rows,

    AVG(requested_monthly_payment_proxy)
        AS avg_requested_monthly_payment_proxy,

    AVG(approved_monthly_payment_proxy)
        AS avg_approved_monthly_payment_proxy_non_null_rows,

    AVG(approved_monthly_payment_proxy) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_monthly_payment_proxy_positive_offer_rows

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

# Replace 11.5.16 with this

```sql
/*-----------------------------------------------------------------------------------------------
11.5.16 Requested versus approved Expected Loss by decision_outcome.

Purpose:
    Review final requested-exposure Expected Loss versus approved-exposure Expected Loss in the
    latest-run output.

Expected:
    APPROVE:
        approved_expected_loss_amount should equal requested_expected_loss_amount.

    COUNTEROFFER:
        approved_expected_loss_amount should generally be lower than requested Expected Loss because
        approved exposure is reduced while estimated_pd and estimated_lgd remain unchanged.

    MANUAL_REVIEW:
        approved_expected_loss_amount should remain NULL because the simulated outcome is unresolved.

    DECLINE:
        approved_expected_loss_amount should be zero because Module 2 uses the no-offer
        zero-exposure convention.

Documentation note:
    NULL approved Expected Loss means unresolved treatment.
    Zero approved Expected Loss means no-offer treatment.
    Positive approved Expected Loss means simulated positive offer exposure.

Alias-length note:
    PostgreSQL truncates identifiers longer than 63 bytes.

    This QA export therefore uses shorter approved Expected Loss aliases such as:
        avg_approved_el_all_rows_convention_adjusted
        total_approved_el_all_rows_convention_adjusted

Boundary:
    approved_expected_loss_amount is a synthetic strategy simulation metric, not a production loss
    forecast.
-----------------------------------------------------------------------------------------------*/

SELECT
    'NULL approved Expected Loss means unresolved MANUAL_REVIEW; zero approved Expected Loss means no-offer DECLINE convention; positive approved Expected Loss means simulated positive offer exposure.'::TEXT
        AS interpretation_note,

    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END AS decision_outcome_rank,

    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_latest_run,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount IS NULL
    ) AS null_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount = 0
    ) AS zero_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount > 0
    ) AS positive_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS simulated_offer_exposure_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_el_non_null_rows,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_el_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_positive_offer_rows,

    AVG(requested_expected_loss_amount - approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_el_reduction_positive_offer_rows,

    AVG(approved_el_reduction_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_reduction_amount_positive_offer_rows,

    AVG(approved_el_reduction_pct) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_reduction_pct_positive_offer_rows,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_el_all_rows_convention_adjusted

FROM credit_decisioning_sim.strategy_decisions

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

# Replace 11.5.17 with this

```sql
/*-----------------------------------------------------------------------------------------------
11.5.17 Simulated offer-exposure profile.

Purpose:
    Review positive simulated offer exposure in the latest-run output.

Expected:
    simulated_offer_exposure_flag = TRUE only for APPROVE and COUNTEROFFER.

Interpretation:
    APPROVE and COUNTEROFFER are simulated positive offer outcomes.

    MANUAL_REVIEW remains unresolved.
    DECLINE follows the no-offer zero-exposure convention.

Documentation note:
    All-row convention-adjusted metrics use COALESCE for portfolio-level aggregation.

    Positive-offer-only metrics isolate APPROVE and COUNTEROFFER exposure behavior.

Boundary:
    This is simulated positive offer exposure, not booked, funded, or operational exposure.
-----------------------------------------------------------------------------------------------*/

SELECT
    'simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER; all-row metrics use final outcome conventions, while positive-offer metrics isolate simulated offer exposure.'::TEXT
        AS interpretation_note,

    simulated_offer_exposure_flag,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_latest_run,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
    ) AS approve_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
    ) AS counteroffer_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
    ) AS manual_review_rows,

    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
    ) AS decline_rows,

    COUNT(*) FILTER (
        WHERE approved_amount IS NULL
    ) AS null_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount = 0
    ) AS zero_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount > 0
    ) AS positive_approved_amount_rows,

    AVG(requested_amount)
        AS avg_requested_amount,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_rows_convention_adjusted,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_el_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_positive_offer_rows,

    SUM(requested_amount)
        AS total_requested_amount,

    SUM(COALESCE(approved_amount, 0))
        AS total_approved_amount_all_rows_convention_adjusted,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_el_all_rows_convention_adjusted

FROM credit_decisioning_sim.strategy_decisions

GROUP BY simulated_offer_exposure_flag

ORDER BY simulated_offer_exposure_flag DESC;
```

---

# Replace 11.5.18 with this

```sql
/*-----------------------------------------------------------------------------------------------
11.5.18 Section 11 readiness summary.

Purpose:
    Provide one compact readiness row for latest-run materialization.

Expected:
    section_11_latest_run_output_status =
        SECTION_11_LATEST_RUN_OUTPUT_READY_FOR_ARCHIVE_PERSISTENCE

Interpretation:
    This confirms only that Section 11 is ready for Section 12.

    It does not validate archive persistence, matched comparison, Section 14 QA, Section 15 frontier,
    or Section 16 evidence capture.

Approved Expected Loss convention:
    APPROVE:
        approved_expected_loss_amount should preserve requested_expected_loss_amount.

        Do not recompute APPROVE Expected Loss from approved_amount × estimated_pd × estimated_lgd
        inside this readiness check, because requested_expected_loss_amount is the governed Module 1
        requested-exposure Expected Loss carried into Module 2.

    COUNTEROFFER:
        approved_expected_loss_amount should be positive and below requested_expected_loss_amount.

    MANUAL_REVIEW:
        approved_expected_loss_amount should remain NULL.

    DECLINE:
        approved_expected_loss_amount should be zero.

Option C readiness interpretation:
    The compact readiness row also confirms that the latest-run output preserved:

        ordinary_counteroffer_candidate_flag
        aggressive_counteroffer_requested_structure_override_flag
        counteroffer_strategy_variant
        aggressive_counteroffer_expansion_enabled

    and that aggressive override rows retain the expected path-specific simulated reason-code
    evidence.

Boundary:
    These checks do not reinterpret the strategy result.
    They only confirm that Section 11 preserved the completed Section 10 evidence.
-----------------------------------------------------------------------------------------------*/

WITH latest_run_summary AS (
    SELECT
        /*******************************************************************************************
        Latest-run row-count and grain checks.
        *******************************************************************************************/
        COUNT(*) AS latest_run_row_count,

        COUNT(DISTINCT application_id)
            AS distinct_application_id_count,

        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version
        )) AS distinct_strategy_identity_count,

        COUNT(DISTINCT (
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS distinct_module1_scenario_population_count,

        /*******************************************************************************************
        Required metadata checks.

        These fields support latest-run traceability and downstream archive / evidence logic.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE module2_model_version IS NULL
               OR strategy_set_name IS NULL
               OR strategy_name IS NULL
               OR strategy_version IS NULL
               OR strategy_run_id IS NULL
               OR strategy_run_ts IS NULL
               OR archive_run_flag IS NULL
               OR strategy_archive_reset_mode IS NULL
               OR module1_input_source IS NULL
               OR module1_source_table_name IS NULL
               OR module1_scenario_set_name IS NULL
               OR module1_scenario_name IS NULL
               OR population_id IS NULL
        ) AS required_metadata_gap_rows,

        COUNT(*) FILTER (
            WHERE latest_output_created_ts IS NULL
        ) AS latest_output_created_ts_null_rows,

        /*******************************************************************************************
        Final decision completeness checks.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE decision_outcome IS NULL
               OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
               OR decision_path IS NULL
               OR decision_resolution_source IS NULL
        ) AS final_decision_gap_rows,

        COUNT(*) FILTER (
            WHERE (
                    COALESCE(approval_flag::INT, 0)
                    + COALESCE(counteroffer_flag::INT, 0)
                    + COALESCE(manual_review_flag::INT, 0)
                    + COALESCE(decline_flag::INT, 0)
                  ) <> 1
        ) AS final_flag_reconciliation_gap_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_gap_rows,

        /*******************************************************************************************
        Approved amount convention checks.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                    AND approved_amount IS DISTINCT FROM requested_amount
                  )
               OR (
                    decision_outcome = 'COUNTEROFFER'
                    AND (
                            approved_amount IS NULL
                         OR approved_amount <= 0
                         OR approved_amount >= requested_amount
                         OR counteroffer_amount IS DISTINCT FROM approved_amount
                    )
                  )
               OR (
                    decision_outcome = 'MANUAL_REVIEW'
                    AND (
                            approved_amount IS NOT NULL
                         OR counteroffer_amount IS NOT NULL
                    )
                  )
               OR (
                    decision_outcome = 'DECLINE'
                    AND (
                            approved_amount IS DISTINCT FROM 0::NUMERIC
                         OR counteroffer_amount IS NOT NULL
                    )
                  )
        ) AS approved_amount_convention_gap_rows,

        /*******************************************************************************************
        Approved Expected Loss convention checks.

        APPROVE:
            approved_expected_loss_amount should preserve requested_expected_loss_amount.

        COUNTEROFFER:
            approved_expected_loss_amount should be positive and below requested_expected_loss_amount.

        MANUAL_REVIEW:
            approved_expected_loss_amount should remain NULL.

        DECLINE:
            approved_expected_loss_amount should be zero.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                    AND approved_expected_loss_amount
                        IS DISTINCT FROM requested_expected_loss_amount
                  )
               OR (
                    decision_outcome = 'COUNTEROFFER'
                    AND (
                            approved_expected_loss_amount IS NULL
                         OR approved_expected_loss_amount <= 0
                         OR approved_expected_loss_amount >= requested_expected_loss_amount
                    )
                  )
               OR (
                    decision_outcome = 'MANUAL_REVIEW'
                    AND approved_expected_loss_amount IS NOT NULL
                  )
               OR (
                    decision_outcome = 'DECLINE'
                    AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
                  )
        ) AS approved_expected_loss_convention_gap_rows,

        /*******************************************************************************************
        Reason-code completeness and outcome-family alignment.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR primary_reason_family IS NULL
               OR triggered_reason_code_list IS NULL
               OR reason_priority_rank IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
        ) AS reason_code_gap_rows,

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
        ) AS reason_family_alignment_gap_rows,

        /*******************************************************************************************
        Final outcome distribution.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE decision_outcome = 'APPROVE'
        ) AS approve_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
        ) AS counteroffer_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
        ) AS manual_review_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
        ) AS decline_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS simulated_offer_exposure_rows,

        /*******************************************************************************************
        Option C counteroffer split latest-run readiness checks.
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
        ) AS option_c_field_gap_rows,

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

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'COUNTEROFFER'
              AND COALESCE(triggered_reason_code_list, '') LIKE
                    '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
        ) AS aggressive_override_counteroffer_reason_trace_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'MANUAL_REVIEW'
              AND preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
              AND failed_counteroffer_resolution = 'MANUAL_REVIEW'
              AND COALESCE(triggered_reason_code_list, '') LIKE
                    '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
        ) AS aggressive_override_manual_review_reason_trace_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND decision_outcome = 'DECLINE'
              AND preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
              AND failed_counteroffer_resolution = 'DECLINE'
              AND COALESCE(triggered_reason_code_list, '') LIKE
                    '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
        ) AS aggressive_override_decline_reason_trace_rows,

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
        ) AS aggressive_override_reason_trace_gap_rows

    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    latest_run_row_count,
    distinct_application_id_count,

    distinct_strategy_identity_count,
    distinct_module1_scenario_population_count,

    required_metadata_gap_rows,
    latest_output_created_ts_null_rows,

    final_decision_gap_rows,
    final_flag_reconciliation_gap_rows,
    simulated_offer_exposure_flag_gap_rows,

    approved_amount_convention_gap_rows,
    approved_expected_loss_convention_gap_rows,

    reason_code_gap_rows,
    reason_family_alignment_gap_rows,

    approve_rows,
    counteroffer_rows,
    manual_review_rows,
    decline_rows,
    simulated_offer_exposure_rows,

    option_c_field_gap_rows,
    ordinary_counteroffer_candidate_rows,
    aggressive_override_rows,
    aggressive_override_final_counteroffer_rows,
    aggressive_override_final_manual_review_rows,
    aggressive_override_final_decline_rows,
    aggressive_override_counteroffer_reason_trace_rows,
    aggressive_override_manual_review_reason_trace_rows,
    aggressive_override_decline_reason_trace_rows,
    aggressive_override_reason_trace_gap_rows,

    CASE
        WHEN latest_run_row_count > 0
         AND latest_run_row_count = distinct_application_id_count
         AND distinct_strategy_identity_count = 1
         AND distinct_module1_scenario_population_count = 1
         AND required_metadata_gap_rows = 0
         AND latest_output_created_ts_null_rows = 0
         AND final_decision_gap_rows = 0
         AND final_flag_reconciliation_gap_rows = 0
         AND simulated_offer_exposure_flag_gap_rows = 0
         AND approved_amount_convention_gap_rows = 0
         AND approved_expected_loss_convention_gap_rows = 0
         AND reason_code_gap_rows = 0
         AND reason_family_alignment_gap_rows = 0
         AND option_c_field_gap_rows = 0
         AND aggressive_override_reason_trace_gap_rows = 0
            THEN 'SECTION_11_LATEST_RUN_OUTPUT_READY_FOR_ARCHIVE_PERSISTENCE'

        ELSE 'REVIEW_SECTION_11_LATEST_RUN_OUTPUT_BEFORE_ARCHIVE_PERSISTENCE'
    END AS section_11_latest_run_output_status

FROM latest_run_summary;
```

## Final Section 11 QA status

```text
M2-01 Section 11 QA: ACCEPTED

11.5.18 readiness: PASS
Core latest-run output: PASS
Option C preservation: PASS
Approved amount convention: PASS
Approved Expected Loss convention: PASS
Reason-code coverage: PASS
Ready for Section 12 archive persistence: YES
```

These refinements are QA/export-only. They do not change latest-run materialization logic, archive persistence, decisions, exposure calculations, Expected Loss calculations, or reason-code assignment.
<!-- END_MESSAGE C034-M01671 -->


---

<a id="c034-m01673"></a>

### C034-M01673

**Andrew** · 2026-05-17T19:17:38.536000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01673 -->
review these refined section 11 QA: 
<!-- END_MESSAGE C034-M01673 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.5_QA_option_c_counteroffer_strategy_split_latest_run_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.14_QA_requested_versus_approved_exposure_by_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.15_QA_requested_versus_approved_pti_by_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.16_QA_requested_versus_approved_expected_loss_by_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.17_QA_simulated_offer_exposure_profile(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.18_QA_section_11_readiness_summary(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01675"></a>

### C034-M01675

**ChatGPT** · 2026-05-17T19:21:09.166980-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01675 -->
## Refined Section 11 QA review verdict

```text
Section 11 refined QA status: PASS
Latest-run materialization status: ACCEPTED
Ready for Section 12 archive persistence: YES
Blockers: none
Required changes: none
Further Section 11 QA refinements recommended: none
```

The refined Section 11 QA package is now clean. The earlier 11.5.18 false-positive on approved Expected Loss convention has been resolved, and the export-readability refinements are working as intended.

---

## 11.5.5 — Option C counteroffer strategy split latest-run diagnostic

```text
Status: PASS
```

The new `interpretation_note` is helpful and correctly clarifies that:

```text
latest_run_group_rows = grouped row count
not total latest-run row count
```

The output is correct for M2-01 baseline:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

Ordinary counteroffer evidence is preserved:

```text
ordinary_counteroffer_candidate_rows = 21,286
```

Aggressive override evidence is correctly inactive:

```text
aggressive_override_rows = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
aggressive_override_reason trace rows = 0
```

The grouped reason-code/outcome counts also reconcile to the final latest-run distribution:

```text
APPROVE          10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
DECLINE          12,703
total            50,000
```

No further change recommended.

---

## 11.5.14 — Requested versus approved exposure by decision outcome

```text
Status: PASS
```

The refined output now clearly distinguishes unresolved, no-offer, and positive-offer exposure treatment.

Approved amount conventions are exact:

```text
APPROVE
    row_count = 10,695
    positive_approved_amount_rows = 10,695
    avg requested amount = avg approved amount = 113,984.96

COUNTEROFFER
    row_count = 19,067
    positive_approved_amount_rows = 19,067
    avg requested amount = 176,816.14
    avg approved amount = 136,791.79
    avg exposure reduction = 40,024.36
    avg exposure reduction pct = 0.19786

MANUAL_REVIEW
    row_count = 7,535
    null_approved_amount_rows = 7,535

DECLINE
    row_count = 12,703
    zero_approved_amount_rows = 12,703
```

The note correctly explains:

```text
NULL = unresolved MANUAL_REVIEW
0 = no-offer DECLINE convention
positive = simulated positive offer exposure
```

No further change recommended.

---

## 11.5.15 — Requested versus approved PTI by decision outcome

```text
Status: PASS
```

Approved PTI conventions are exact:

```text
APPROVE
    positive_approved_pti_rows = 10,695
    avg requested PTI = avg approved PTI = 0.086445

COUNTEROFFER
    positive_approved_pti_rows = 19,067
    avg requested PTI = 0.185296
    avg approved PTI = 0.143459
    avg PTI reduction = 0.041837

MANUAL_REVIEW
    null_approved_pti_rows = 7,535

DECLINE
    zero_approved_pti_rows = 12,703
```

The shortened alias pattern is also clean:

```text
avg_approved_pti_non_null_rows
avg_approved_pti_all_rows_convention_adjusted
avg_approved_pti_positive_offer_rows
```

No truncation or interpretation issue remains.

No further change recommended.

---

## 11.5.16 — Requested versus approved Expected Loss by decision outcome

```text
Status: PASS
```

Approved Expected Loss conventions are exact:

```text
APPROVE
    positive_approved_expected_loss_rows = 10,695
    avg requested EL = avg approved EL = 773.063017

COUNTEROFFER
    positive_approved_expected_loss_rows = 19,067
    avg requested EL = 3,474.715662
    avg approved EL = 2,637.215254
    avg EL reduction = 837.500408
    avg EL reduction pct = 0.19786

MANUAL_REVIEW
    null_approved_expected_loss_rows = 7,535

DECLINE
    zero_approved_expected_loss_rows = 12,703
```

The approved Expected Loss readiness issue is resolved because the convention now validates the business rule correctly:

```text
APPROVE preserves requested Expected Loss.
COUNTEROFFER reduces approved Expected Loss.
MANUAL_REVIEW remains NULL.
DECLINE uses zero.
```

The shorter aliases are clean and preservation-ready:

```text
avg_approved_el_non_null_rows
avg_approved_el_all_rows_convention_adjusted
avg_approved_el_positive_offer_rows
total_approved_el_all_rows_convention_adjusted
```

No further change recommended.

---

## 11.5.17 — Simulated offer exposure profile

```text
Status: PASS
```

The output reconciles exactly:

```text
simulated_offer_exposure_flag = true
    row_count = 29,762
    approve_rows = 10,695
    counteroffer_rows = 19,067
    positive_approved_amount_rows = 29,762

simulated_offer_exposure_flag = false
    row_count = 20,238
    manual_review_rows = 7,535
    decline_rows = 12,703
    null_approved_amount_rows = 7,535
    zero_approved_amount_rows = 12,703
```

This confirms the intended convention:

```text
APPROVE + COUNTEROFFER = simulated positive offer exposure
MANUAL_REVIEW + DECLINE = no simulated positive offer exposure
```

The all-row convention-adjusted metrics and positive-offer-only metrics are clearly separated. No further change recommended.

---

## 11.5.18 — Section 11 readiness summary

```text
Status: PASS
```

This is the controlling signoff row, and it now returns the expected status:

```text
section_11_latest_run_output_status =
SECTION_11_LATEST_RUN_OUTPUT_READY_FOR_ARCHIVE_PERSISTENCE
```

Core checks:

```text
latest_run_row_count = 50,000
distinct_application_id_count = 50,000
distinct_strategy_identity_count = 1
distinct_module1_scenario_population_count = 1

required_metadata_gap_rows = 0
latest_output_created_ts_null_rows = 0
final_decision_gap_rows = 0
final_flag_reconciliation_gap_rows = 0
simulated_offer_exposure_flag_gap_rows = 0
approved_amount_convention_gap_rows = 0
approved_expected_loss_convention_gap_rows = 0
reason_code_gap_rows = 0
reason_family_alignment_gap_rows = 0
option_c_field_gap_rows = 0
aggressive_override_reason_trace_gap_rows = 0
```

Outcome counts reconcile:

```text
approve_rows = 10,695
counteroffer_rows = 19,067
manual_review_rows = 7,535
decline_rows = 12,703
simulated_offer_exposure_rows = 29,762
```

Option C latest-run preservation is clean:

```text
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
aggressive_override_reason_trace_gap_rows = 0
```

No further change recommended.

---

## Final Section 11 signoff

```text
M2-01 Section 11 QA: ACCEPTED

No blockers.
No row-count issue.
No application-grain issue.
No strategy-identity issue.
No Module 1 lineage issue.
No metadata gap.
No final-decision gap.
No final-flag reconciliation issue.
No simulated offer-exposure issue.
No approved amount convention issue.
No approved Expected Loss convention issue.
No reason-code coverage issue.
No reason-family alignment issue.
No Option C preservation issue.
No aggressive override leakage.
Ready for Section 12 archive persistence.
```

Section 11 refined QA is preservation-ready.
<!-- END_MESSAGE C034-M01675 -->


---

<a id="c034-m01677"></a>

### C034-M01677

**Andrew** · 2026-05-17T19:39:37.862000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01677 -->
review section 12 QA:
<!-- END_MESSAGE C034-M01677 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.6_QA_current_archived_slice_row_count_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.7_QA_current_archived_slice_decision_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.8_QA_current_archived_slice_product_x_decision_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.9_QA_current_archived_slice_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.10_QA_current_archived_slice_requested_versus_approved_exposure_expected_loss_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.11_QA_option_c_counteroffer_split_archive_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.12_QA_archive_mode_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.13_QA_section_12_readiness_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.1_QA_archive_inventory_by_strategy_module_1_scenario_population.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.2_QA_latest_run_identity_prepared_for_archive.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.3_QA_archive_persistence_audit_row.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.4_QA_archive_before_after_inventory_movement.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.5_QA_archive_row_level_grain_duplicate_diagnostic.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01684"></a>

### C034-M01684

**ChatGPT** · 2026-05-17T19:44:47.687284-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01684 -->
## M2-01 Section 12 QA review verdict

```text
Section 12 QA status: PASS
Archive persistence status: ACCEPTED
Selected run: M2-01
Strategy: BASELINE_STRATEGY
Archive mode: STRATEGY_SCENARIO_ONLY
Latest-run rows: 50,000
Archived current-slice rows: 50,000
Distinct archived application_id count: 50,000
Archive-grain duplicate count: 0
Latest-run/archive Option C mismatch count: 0
Option C aggressive override posture: correctly inactive
Section 12 readiness status: SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA
Blockers: none
```

Section 12 is doing what it should: preserving the completed Section 11 latest-run output into the governed archive without recalculating decisions, exposure, Expected Loss, reason codes, or Option C path fields. Its stated purpose is archive persistence after Section 11 latest-run materialization, using the archive as governed historical evidence for later comparison, validation, frontier review, and evidence capture. fileciteturn401file28

---

## 1. Archive inventory — 12.8.1

**Status: PASS**

The archive inventory shows exactly one archived slice:

```text
strategy_set_name = MODULE2_BASELINE_STRATEGY_SET
strategy_name = BASELINE_STRATEGY
strategy_version = V1_0
module1_scenario_set_name = MODULE1_V2_BASELINE_SET
module1_scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1
archived_rows = 50,000
distinct_application_id_count = 50,000
```

This is correct for M2-01 after a fresh Module 2 archive reset and rerun.

---

## 2. Latest-run identity prepared for archive — 12.8.2

**Status: PASS**

The latest-run archive identity is clean:

```text
module2_model_version = MODULE2_V1_0
strategy_name = BASELINE_STRATEGY
strategy_run_id = M2-01_BASELINE_STRATEGY_V1_0_RUN
archive_run_flag = true
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
module1_input_source = ARCHIVE
module1_source_table_name = credit_decisioning_sim.synthetic_applications_scenario_archive
module1_scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1
latest_run_rows = 50,000
distinct_application_id_count = 50,000
```

This confirms Section 12 was archiving the correct latest-run slice.

---

## 3. Archive persistence audit row — 12.8.3

**Status: PASS**

The audit row is coherent:

```text
archive_run_flag = true
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
latest_run_row_count = 50,000
latest_run_distinct_application_count = 50,000
archive_row_count_before = 0
archive_deleted_rows = 0
archive_inserted_rows = 50,000
archive_row_count_after = 50,000
archive_action = ARCHIVE_REPLACED_STRATEGY_SCENARIO_ONLY
```

The action label is acceptable. Because this was a fresh archive state, there were no prior rows to delete, but the selected archive behavior was still the governed strategy-scenario replacement mode.

---

## 4. Archive before/after inventory movement — 12.8.4

**Status: PASS**

The before/after movement is exactly expected for a first archive insert:

```text
before_row_count = 0
after_row_count = 50,000
row_count_delta = 50,000
```

No concern.

---

## 5. Archive row-level duplicate diagnostic — 12.8.5

**Status: PASS**

```text
duplicate_archive_grain_count = 0
```

This confirms no duplicate rows exist at the archive row-level grain for the archived strategy/scenario/population/application key.

---

## 6. Current archived slice row count diagnostic — 12.8.6

**Status: PASS**

```text
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
```

This is the strongest basic archive integrity check. The current archived M2-01 slice matches the expected one-row-per-application population.

---

## 7. Current archived slice decision distribution — 12.8.7

**Status: PASS**

The archived decision distribution matches the latest-run / Section 11 output:

```text
APPROVE          10,695   21.39%
COUNTEROFFER     19,067   38.13%
MANUAL_REVIEW     7,535   15.07%
DECLINE          12,703   25.41%
```

The amount and Expected Loss conventions are preserved:

```text
APPROVE:
    approved amount = requested amount
    approved Expected Loss = requested Expected Loss

COUNTEROFFER:
    approved amount < requested amount
    approved Expected Loss < requested Expected Loss

MANUAL_REVIEW:
    approved amount = NULL
    approved Expected Loss = NULL

DECLINE:
    approved amount = 0
    approved Expected Loss = 0
```

No persistence distortion is visible.

---

## 8. Product × decision distribution — 12.8.8

**Status: PASS**

Product-level archive behavior is coherent and matches prior Section 9 / 11 patterns.

Examples:

```text
AUTO_LOAN:
    APPROVE 2,672
    COUNTEROFFER 3,167
    MANUAL_REVIEW 1,632
    DECLINE 2,475

MORTGAGE:
    APPROVE 2,998
    COUNTEROFFER 5,848
    MANUAL_REVIEW 2,204
    DECLINE 4,015

REVOLVING_LINE:
    APPROVE 2,489
    COUNTEROFFER 5,231
    MANUAL_REVIEW 1,810
    DECLINE 2,925
```

Counteroffer rows preserve reduced exposure / reduced PTI / reduced approved Expected Loss. Manual-review rows remain NULL, and decline rows remain zero.

No product-level archive issue found.

---

## 9. Archived primary reason-code distribution — 12.8.9

**Status: PASS**

The archived reason-code distribution reconciles to 50,000 rows and matches the Section 10 / Section 11 reason-code profile:

```text
APPROVED_AS_REQUESTED                         10,695

COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT            8,905
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT          5,021
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK           3,853
COUNTEROFFER_EXPECTED_LOSS_LIMIT               1,288

MANUAL_REVIEW_FAILED_COUNTEROFFER              2,219
MANUAL_REVIEW_BORDERLINE_PROFILE               1,926
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW            1,790
MANUAL_REVIEW_DTI_REVIEW                       1,600

POLICY_STOP_SEVERE_SYNTHETIC_RISK              6,369
POLICY_STOP_SEVERE_DELINQUENCY                 2,955
POLICY_STOP_MAJOR_DEROGATORY                   2,107
POLICY_STOP_BANKRUPTCY                           827
POLICY_STOP_SEVERE_DTI                           445
```

Reason-code preservation is clean.

---

## 10. Archived requested vs approved exposure / Expected Loss summary — 12.8.10

**Status: PASS**

The archived slice summary is coherent:

```text
current_archived_slice_rows = 50,000

total_requested_amount = 6.666B
total_approved_amount = 3.827B
approved_amount_capture_rate = 0.574109

total_requested_expected_loss_amount = 239.433M
total_approved_expected_loss_amount = 58.552M
approved_expected_loss_rate = 0.015299

avg_requested_payment_to_income_ratio = 0.165034
avg_approved_payment_to_income_ratio_offer_rows = 0.122971
```

Interpretation:

```text
Approved exposure is materially lower than requested exposure because manual review / decline rows do not carry positive approved exposure and counteroffers reduce exposure.

Approved Expected Loss is materially lower than requested Expected Loss because final offer exposure is restricted to APPROVE / COUNTEROFFER and counteroffers reduce approved exposure.
```

No issue found.

One minor readability note: `approved_expected_loss_rate` appears to behave like approved EL divided by approved amount, not approved EL divided by requested EL. That is acceptable if intentional, but the name could be clearer if you later refine Section 12 exports.

---

## 11. Option C archive diagnostic — 12.8.11

**Status: PASS**

M2-01 baseline posture is correctly preserved:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive_override_rows = 0
```

Ordinary counteroffer candidate evidence is preserved by reason-code group:

```text
COUNTEROFFER rows:
    ordinary counteroffer candidate rows = 19,067

MANUAL_REVIEW_FAILED_COUNTEROFFER:
    ordinary counteroffer candidate rows = 2,219
```

Together:

```text
ordinary counteroffer candidate rows = 21,286
```

Aggressive override rows remain zero across all outcome / reason-code groups, which is correct for baseline.

---

## 12. Archive mode diagnostic — 12.8.12

**Status: PASS**

The archive mode diagnostic matches the audit row:

```text
archive_run_flag = true
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
latest_run_row_count = 50,000
archive_inserted_rows = 50,000
archive_row_count_after = 50,000
archive_action = ARCHIVE_REPLACED_STRATEGY_SCENARIO_ONLY
```

This confirms the archive action is governed and traceable.

---

## 13. Section 12 readiness summary — 12.8.13

**Status: PASS**

This is the controlling signoff row, and it passes:

```text
section_12_archive_persistence_status =
SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA
```

Core checks:

```text
latest_run_row_count = 50,000
latest_run_distinct_application_count = 50,000
archive_inserted_rows = 50,000
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
current_archived_slice_null_archive_ts_rows = 0
duplicate_archive_grain_count = 0
option_c_latest_run_archive_gap_count = 0
option_c_archive_reason_trace_gap_count = 0
aggressive_override_archived_rows = 0
```

The only value that may look odd at first glance is:

```text
before_after_inventory_diff_count = 1
```

That is **not a blocker**. For M2-01 after a fresh Module 2 reset, one archive inventory row changed because the archive moved from:

```text
0 rows → 50,000 rows
```

The readiness logic correctly does not treat that as a failure for `archive_run_flag = true`.

---

# Final Section 12 signoff

```text
M2-01 Section 12 QA: ACCEPTED

No blockers.
No archive row-count issue.
No archive grain duplicate issue.
No latest-run/archive row-count mismatch.
No current archived-slice application_id issue.
No archive timestamp issue.
No final-output convention issue visible in archive.
No reason-code preservation issue.
No Option C field persistence issue.
No aggressive override leakage.
Ready for Section 13 comparison framework and Section 14 QA.
```

For M2-01 specifically, Section 13 comparison readiness will still depend on whether the relevant challenger slice, such as M2-02 for CG01, has also been archived. But the **M2-01 archive slice itself is ready**.

---

## Recommended Section 12 QA refinements

No logic changes are needed.

I would consider three export-readability refinements only:

```text
1. 12.8.10:
   Rename or explain approved_expected_loss_rate if it represents approved EL / approved amount
   rather than approved EL / requested EL.

2. 12.8.11:
   Add an interpretation_note explaining that archived_rows is grouped by outcome / reason code, and
   that ordinary_counteroffer_candidate_rows should be summed across groups for total ordinary
   counteroffer candidate evidence.

3. 12.8.13:
   Add an interpretation_note explaining that before_after_inventory_diff_count can be nonzero during
   archive_run_flag = TRUE because archive insertion/replacement is expected to move inventory.
```

I would treat these as optional polish only. The Section 12 QA package is accepted as-is.
<!-- END_MESSAGE C034-M01684 -->


---

<a id="c034-m01686"></a>

### C034-M01686

**Andrew** · 2026-05-17T20:02:03.473000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01686 -->
please implement and give me full section copy pastes: I would consider three export-readability refinements only:

1. 12.8.10:
   Rename or explain approved_expected_loss_rate if it represents approved EL / approved amount
   rather than approved EL / requested EL.

2. 12.8.11:
   Add an interpretation_note explaining that archived_rows is grouped by outcome / reason code, and
   that ordinary_counteroffer_candidate_rows should be summed across groups for total ordinary
   counteroffer candidate evidence.

3. 12.8.13:
   Add an interpretation_note explaining that before_after_inventory_diff_count can be nonzero during
   archive_run_flag = TRUE because archive insertion/replacement is expected to move inventory.
<!-- END_MESSAGE C034-M01686 -->


---

<a id="c034-m01691"></a>

### C034-M01691

**ChatGPT** · 2026-05-17T20:07:55.784897-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01691 -->
According to a document from **2026-05-17**, Section 12.8 is the local archive-persistence sanity-check section, covering the current archived slice exposure / Expected Loss summary, Option C ordinary-versus-aggressive archive diagnostics, archive mode diagnostic, and one compact readiness row. fileciteturn403file0

Below are full copy-paste replacements for:

```text
12.8.10
12.8.11
12.8.13
```

---

## Replace 12.8.10 with this

```sql
/*-----------------------------------------------------------------------------------------------
12.8.10 Current archived slice requested versus approved exposure / Expected Loss summary.

Purpose:
    Review portfolio-impact metrics in the archived current slice.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss.
    approved_expected_loss_amount is approved-exposure Expected Loss.
    archive_inserted_ts is archive persistence metadata.

Why this refinement exists:
    The prior approved_expected_loss_rate field could be misread.

    This export now separates:

        approved_expected_loss_capture_rate:
            approved Expected Loss / requested Expected Loss

        approved_el_per_approved_dollar:
            approved Expected Loss / approved amount

    This makes clear whether the metric is measuring retained Expected Loss versus requested
    Expected Loss or approved Expected Loss density per approved exposure dollar.

Documentation note:
    All-row approved exposure and approved Expected Loss metrics use final outcome conventions:

        APPROVE and COUNTEROFFER:
            positive simulated offer exposure.

        MANUAL_REVIEW:
            unresolved NULL approved exposure / Expected Loss.

        DECLINE:
            zero approved exposure / Expected Loss.

Boundary:
    This is an archive persistence diagnostic.

    It does not recalculate decisions.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.
    It does not modify archive rows.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    'approved_expected_loss_capture_rate = approved EL / requested EL; approved_el_per_approved_dollar = approved EL / approved amount. Both use archived final-output conventions.'::TEXT
        AS interpretation_note,

    COUNT(*) AS current_archived_slice_rows,

    COUNT(DISTINCT ar.application_id)
        AS current_archived_slice_distinct_application_id_count,

    COUNT(*) FILTER (
        WHERE ar.simulated_offer_exposure_flag IS TRUE
    ) AS simulated_offer_exposure_rows,

    COUNT(*) FILTER (
        WHERE ar.decision_outcome = 'APPROVE'
    ) AS approve_rows,

    COUNT(*) FILTER (
        WHERE ar.decision_outcome = 'COUNTEROFFER'
    ) AS counteroffer_rows,

    COUNT(*) FILTER (
        WHERE ar.decision_outcome = 'MANUAL_REVIEW'
    ) AS manual_review_rows,

    COUNT(*) FILTER (
        WHERE ar.decision_outcome = 'DECLINE'
    ) AS decline_rows,

    SUM(ar.requested_amount)
        AS total_requested_amount,

    SUM(COALESCE(ar.approved_amount, 0))
        AS total_approved_amount,

    SUM(COALESCE(ar.approved_amount, 0))
        / NULLIF(SUM(ar.requested_amount), 0)
        AS approved_amount_capture_rate,

    SUM(ar.requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount,

    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        / NULLIF(SUM(ar.requested_expected_loss_amount), 0)
        AS approved_expected_loss_capture_rate,

    SUM(COALESCE(ar.approved_expected_loss_amount, 0))
        / NULLIF(SUM(COALESCE(ar.approved_amount, 0)), 0)
        AS approved_el_per_approved_dollar,

    AVG(ar.requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(ar.approved_payment_to_income_ratio)
        FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_pti_offer_rows,

    AVG(ar.requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(ar.approved_expected_loss_amount)
        FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)
        AS avg_approved_el_offer_rows,

    MIN(ar.latest_output_created_ts)
        AS min_latest_output_created_ts,

    MAX(ar.latest_output_created_ts)
        AS max_latest_output_created_ts,

    MIN(ar.archive_inserted_ts)
        AS min_archive_inserted_ts,

    MAX(ar.archive_inserted_ts)
        AS max_archive_inserted_ts

FROM archive_context a

JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id;
```

---

## Replace 12.8.11 with this

```sql
/*-----------------------------------------------------------------------------------------------
12.8.11 Option C counteroffer split archive diagnostic.

Purpose:
    Confirm that the current archived slice preserved ordinary versus aggressive counteroffer path
    evidence.

Interpretation:
    SELECTIVE_FEASIBILITY should generally show no aggressive override rows.

    AGGRESSIVE_EXPANSION may show aggressive override rows split across:
        final COUNTEROFFER,
        final MANUAL_REVIEW,
        and final DECLINE depending on feasibility and failed_counteroffer_resolution.

Why this refinement exists:
    This query groups by outcome and reason-code fields.

    Therefore:
        archived_rows is a grouped row count.
        ordinary_counteroffer_candidate_rows should be summed across groups to obtain the total
        ordinary counteroffer candidate evidence for the archived slice.

    The same is true for aggressive override rows and path-specific aggressive override reason-trace
    counts.

Boundary:
    This is archive persistence evidence only.

    It does not perform matched strategy comparison.
    It does not perform full QA.
    It does not recalculate decisions.
    It does not modify archive rows.
-----------------------------------------------------------------------------------------------*/

WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
)

SELECT
    'archived_rows is grouped by outcome and reason code; sum ordinary_counteroffer_candidate_rows across groups to obtain total ordinary counteroffer candidate evidence for the archived slice.'::TEXT
        AS interpretation_note,

    ar.strategy_name,
    ar.strategy_version,
    ar.module1_scenario_set_name,
    ar.module1_scenario_name,
    ar.population_id,
    ar.counteroffer_strategy_variant,
    ar.aggressive_counteroffer_expansion_enabled,

    ar.decision_outcome,
    ar.primary_reason_family,
    ar.primary_reason_code,

    COUNT(*) AS archived_rows,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_current_archived_slice,

    COUNT(*) FILTER (
        WHERE ar.ordinary_counteroffer_candidate_flag IS TRUE
    ) AS ordinary_counteroffer_candidate_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
    ) AS aggressive_override_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND ar.decision_outcome = 'COUNTEROFFER'
    ) AS aggressive_override_final_counteroffer_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND ar.decision_outcome = 'MANUAL_REVIEW'
    ) AS aggressive_override_final_manual_review_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND ar.decision_outcome = 'DECLINE'
    ) AS aggressive_override_final_decline_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND ar.decision_outcome = 'COUNTEROFFER'
          AND COALESCE(ar.triggered_reason_code_list, '') LIKE
                '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
    ) AS aggressive_override_counteroffer_reason_trace_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND ar.decision_outcome = 'MANUAL_REVIEW'
          AND ar.preliminary_decision_outcome = 'COUNTEROFFER'
          AND ar.counteroffer_feasibility_pass_flag IS FALSE
          AND ar.failed_counteroffer_resolution = 'MANUAL_REVIEW'
          AND COALESCE(ar.triggered_reason_code_list, '') LIKE
                '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
    ) AS aggressive_override_manual_review_reason_trace_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND ar.decision_outcome = 'DECLINE'
          AND ar.preliminary_decision_outcome = 'COUNTEROFFER'
          AND ar.counteroffer_feasibility_pass_flag IS FALSE
          AND ar.failed_counteroffer_resolution = 'DECLINE'
          AND COALESCE(ar.triggered_reason_code_list, '') LIKE
                '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
    ) AS aggressive_override_decline_reason_trace_rows,

    COUNT(*) FILTER (
        WHERE ar.aggressive_counteroffer_requested_structure_override_flag IS TRUE
          AND (
                (
                    ar.decision_outcome = 'COUNTEROFFER'
                    AND COALESCE(ar.triggered_reason_code_list, '') NOT LIKE
                        '%COUNTEROFFER_AGGRESSIVE_EXPANSION_OVERRIDE%'
                )
             OR (
                    ar.decision_outcome = 'MANUAL_REVIEW'
                    AND ar.preliminary_decision_outcome = 'COUNTEROFFER'
                    AND ar.counteroffer_feasibility_pass_flag IS FALSE
                    AND ar.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                    AND COALESCE(ar.triggered_reason_code_list, '') NOT LIKE
                        '%MANUAL_REVIEW_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                )
             OR (
                    ar.decision_outcome = 'DECLINE'
                    AND ar.preliminary_decision_outcome = 'COUNTEROFFER'
                    AND ar.counteroffer_feasibility_pass_flag IS FALSE
                    AND ar.failed_counteroffer_resolution = 'DECLINE'
                    AND COALESCE(ar.triggered_reason_code_list, '') NOT LIKE
                        '%POLICY_STOP_AGGRESSIVE_COUNTEROFFER_NOT_FEASIBLE%'
                )
          )
    ) AS aggressive_override_reason_trace_gap_rows

FROM archive_context a

JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id

GROUP BY
    ar.strategy_name,
    ar.strategy_version,
    ar.module1_scenario_set_name,
    ar.module1_scenario_name,
    ar.population_id,
    ar.counteroffer_strategy_variant,
    ar.aggressive_counteroffer_expansion_enabled,
    ar.decision_outcome,
    ar.primary_reason_family,
    ar.primary_reason_code

ORDER BY
    ar.strategy_name,
    CASE ar.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END,
    CASE ar.primary_reason_family
        WHEN 'APPROVAL' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'POLICY_STOP' THEN 4
        ELSE 99
    END,
    archived_rows DESC,
    ar.primary_reason_code;
```

---

## Replace 12.8.13 with this

```sql
/*-----------------------------------------------------------------------------------------------
12.8.13 Section 12 readiness summary.

Purpose:
    Provide one compact readiness row for archive persistence.

Expected:
    If archive_run_flag = TRUE:
        SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA

    If archive_run_flag = FALSE:
        SECTION_12_ARCHIVE_PERSISTENCE_SKIPPED_BY_CONTROL

Interpretation:
    This confirms only Section 12 archive persistence status.

    It does not validate Section 13 comparison readiness.
    It does not validate Section 14 QA.
    It does not validate Section 15 frontier completeness.
    It does not validate Section 16 evidence capture.

Inventory movement interpretation:
    before_after_inventory_diff_count can be nonzero when archive_run_flag = TRUE.

    During archive insertion or replacement, inventory movement is expected.

    Example:
        A fresh M2-01 archive insert can move the current key from 0 rows to 50,000 rows.

    That movement is not a failure when archive_run_flag = TRUE.

    For archive_run_flag = FALSE, before_after_inventory_diff_count should remain zero because
    Section 12 should not insert or delete archive rows.

Implementation note:
    Option C archive diagnostics are aggregate checks.

    They are not physical columns on credit_decisioning_sim.strategy_decisions_archive.

    Therefore this readiness summary calculates:
        option_c_latest_run_archive_gap_count
        option_c_archive_reason_trace_gap_count
        aggressive_override_archived_rows
        aggressive_override_archived_counteroffer_rows
        aggressive_override_archived_manual_review_rows
        aggressive_override_archived_decline_rows

    from the current archived slice and the latest-run table.
-----------------------------------------------------------------------------------------------*/

WITH audit_row AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1
),

latest_run_current AS (
    SELECT
        sd.*
    FROM credit_decisioning_sim.strategy_decisions sd

    JOIN audit_row a
        ON a.strategy_set_name = sd.strategy_set_name
       AND a.strategy_name = sd.strategy_name
       AND a.strategy_version = sd.strategy_version
       AND a.module1_scenario_set_name = sd.module1_scenario_set_name
       AND a.module1_scenario_name = sd.module1_scenario_name
       AND a.population_id = sd.population_id
),

archive_current AS (
    SELECT
        ar.*
    FROM credit_decisioning_sim.strategy_decisions_archive ar

    JOIN audit_row a
        ON ar.strategy_set_name = a.strategy_set_name
       AND ar.strategy_name = a.strategy_name
       AND ar.strategy_version = a.strategy_version
       AND ar.module1_scenario_set_name = a.module1_scenario_set_name
       AND ar.module1_scenario_name = a.module1_scenario_name
       AND ar.population_id = a.population_id
),

latest_archive_compare AS (
    SELECT
        COALESCE(l.application_id, ar.application_id)
            AS application_id,

        l.application_id AS latest_application_id,
        ar.application_id AS archived_application_id,

        /*******************************************************************************************
        Option C latest-run versus archive field mismatch flag.

        This compares row-level Option C evidence between the latest-run table and the archived
        current slice.

        Row absence on either side is also treated as a gap.
        *******************************************************************************************/
        CASE
            WHEN l.application_id IS NULL
              OR ar.application_id IS NULL
                THEN TRUE

            WHEN l.counteroffer_strategy_variant
                    IS DISTINCT FROM ar.counteroffer_strategy_variant
              OR l.aggressive_counteroffer_expansion_enabled
                    IS DISTINCT FROM ar.aggressive_counteroffer_expansion_enabled
              OR l.severe_requested_structure_counteroffer_override_enabled
                    IS DISTINCT FROM ar.severe_requested_structure_counteroffer_override_enabled
              OR l.exposure_extreme_counteroffer_override_enabled
                    IS DISTINCT FROM ar.exposure_extreme_counteroffer_override_enabled
              OR l.exposure_policy_stop_counteroffer_override_enabled
                    IS DISTINCT FROM ar.exposure_policy_stop_counteroffer_override_enabled
              OR l.requested_pti_decline_counteroffer_override_enabled
                    IS DISTINCT FROM ar.requested_pti_decline_counteroffer_override_enabled
              OR l.requested_el_decline_counteroffer_override_enabled
                    IS DISTINCT FROM ar.requested_el_decline_counteroffer_override_enabled
              OR l.ordinary_counteroffer_candidate_flag
                    IS DISTINCT FROM ar.ordinary_counteroffer_candidate_flag
              OR l.aggressive_counteroffer_requested_structure_override_flag
                    IS DISTINCT FROM ar.aggressive_counteroffer_requested_structure_override_flag
                THEN TRUE

            ELSE FALSE
        END AS option_c_latest_run_archive_gap_flag

    FROM latest_run_current l

    FULL OUTER JOIN archive_current ar
        ON ar.application_id = l.application_id
),

current_archive AS (
    SELECT
        a.archive_run_flag,
        a.strategy_archive_reset_mode,
        a.strategy_set_name,
        a.strategy_name,
        a.strategy_version,
        a.module1_scenario_set_name,
        a.module1_scenario_name,
        a.population_id,

        /*******************************************************************************************
        Current archived slice structural counts.
        *******************************************************************************************/
        (
            SELECT COUNT(*)
            FROM archive_current
        ) AS current_archived_slice_rows,

        (
            SELECT COUNT(DISTINCT application_id)
            FROM archive_current
        ) AS current_archived_slice_distinct_application_id_count,

        (
            SELECT COUNT(*)
            FROM archive_current
            WHERE archive_inserted_ts IS NULL
        ) AS current_archived_slice_null_archive_ts_rows,

        /*******************************************************************************************
        Option C latest-run versus archive persistence fidelity.

        This is evaluated only when archive_run_flag = TRUE.

        If archive_run_flag = FALSE, Section 12 intentionally skipped persistence, so latest-run
        versus archive equality is not required.
        *******************************************************************************************/
        CASE
            WHEN a.archive_run_flag IS TRUE
                THEN (
                    SELECT COUNT(*)
                    FROM latest_archive_compare
                    WHERE option_c_latest_run_archive_gap_flag IS TRUE
                )
            ELSE 0
        END AS option_c_latest_run_archive_gap_count,

        /*******************************************************************************************
        Option C aggressive override reason-trace preservation.

        These checks operate on the archived current slice.

        They confirm that aggressive override rows retained path-specific simulated reason-code
        evidence after archive persistence.
        *******************************************************************************************/
        CASE
            WHEN a.archive_run_flag IS TRUE
                THEN (
                    SELECT COUNT(*)
                    FROM archive_current
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
                )
            ELSE 0
        END AS option_c_archive_reason_trace_gap_count,

        CASE
            WHEN a.archive_run_flag IS TRUE
                THEN (
                    SELECT COUNT(*)
                    FROM archive_current
                    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
                )
            ELSE 0
        END AS aggressive_override_archived_rows,

        CASE
            WHEN a.archive_run_flag IS TRUE
                THEN (
                    SELECT COUNT(*)
                    FROM archive_current
                    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
                      AND decision_outcome = 'COUNTEROFFER'
                )
            ELSE 0
        END AS aggressive_override_archived_counteroffer_rows,

        CASE
            WHEN a.archive_run_flag IS TRUE
                THEN (
                    SELECT COUNT(*)
                    FROM archive_current
                    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
                      AND decision_outcome = 'MANUAL_REVIEW'
                )
            ELSE 0
        END AS aggressive_override_archived_manual_review_rows,

        CASE
            WHEN a.archive_run_flag IS TRUE
                THEN (
                    SELECT COUNT(*)
                    FROM archive_current
                    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
                      AND decision_outcome = 'DECLINE'
                )
            ELSE 0
        END AS aggressive_override_archived_decline_rows

    FROM audit_row a
),

archive_duplicates AS (
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

inventory_diff AS (
    SELECT COUNT(*) AS before_after_inventory_diff_count
    FROM (
        SELECT
            COALESCE(b.strategy_set_name, a.strategy_set_name)
                AS strategy_set_name,

            COALESCE(b.strategy_name, a.strategy_name)
                AS strategy_name,

            COALESCE(b.strategy_version, a.strategy_version)
                AS strategy_version,

            COALESCE(b.module1_scenario_set_name, a.module1_scenario_set_name)
                AS module1_scenario_set_name,

            COALESCE(b.module1_scenario_name, a.module1_scenario_name)
                AS module1_scenario_name,

            COALESCE(b.population_id, a.population_id)
                AS population_id,

            COALESCE(b.row_count, 0)
                AS before_row_count,

            COALESCE(a.row_count, 0)
                AS after_row_count

        FROM tmp_m2_archive_inventory_before b

        FULL OUTER JOIN tmp_m2_archive_inventory_after a
            ON a.strategy_set_name = b.strategy_set_name
           AND a.strategy_name = b.strategy_name
           AND a.strategy_version = b.strategy_version
           AND a.module1_scenario_set_name = b.module1_scenario_set_name
           AND a.module1_scenario_name = b.module1_scenario_name
           AND a.population_id = b.population_id
    ) x
    WHERE before_row_count <> after_row_count
)

SELECT
    'before_after_inventory_diff_count can be nonzero when archive_run_flag = TRUE because archive insertion or replacement is expected to move inventory; it should remain zero only when archive persistence is skipped.'::TEXT
        AS interpretation_note,

    a.archive_run_flag,
    a.strategy_archive_reset_mode,

    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,

    a.latest_run_row_count,
    a.latest_run_distinct_application_count,

    a.archive_row_count_before,
    a.archive_deleted_rows,
    a.archive_inserted_rows,
    a.archive_row_count_after,
    a.archive_action,

    ca.current_archived_slice_rows,
    ca.current_archived_slice_distinct_application_id_count,
    ca.current_archived_slice_null_archive_ts_rows,

    ad.duplicate_archive_grain_count,
    inv.before_after_inventory_diff_count,

    ca.option_c_latest_run_archive_gap_count,
    ca.option_c_archive_reason_trace_gap_count,
    ca.aggressive_override_archived_rows,
    ca.aggressive_override_archived_counteroffer_rows,
    ca.aggressive_override_archived_manual_review_rows,
    ca.aggressive_override_archived_decline_rows,

    CASE
        WHEN a.archive_run_flag IS FALSE
         AND a.archive_deleted_rows = 0
         AND a.archive_inserted_rows = 0
         AND a.archive_row_count_after = a.archive_row_count_before
         AND inv.before_after_inventory_diff_count = 0
            THEN 'SECTION_12_ARCHIVE_PERSISTENCE_SKIPPED_BY_CONTROL'

        WHEN a.archive_run_flag IS TRUE
         AND a.archive_inserted_rows = a.latest_run_row_count
         AND ca.current_archived_slice_rows = a.latest_run_row_count
         AND ca.current_archived_slice_distinct_application_id_count = a.latest_run_row_count
         AND ca.current_archived_slice_null_archive_ts_rows = 0
         AND ca.option_c_latest_run_archive_gap_count = 0
         AND ca.option_c_archive_reason_trace_gap_count = 0
         AND ad.duplicate_archive_grain_count = 0
            THEN 'SECTION_12_ARCHIVE_PERSISTENCE_READY_FOR_COMPARISON_AND_QA'

        ELSE 'REVIEW_SECTION_12_ARCHIVE_PERSISTENCE_BEFORE_COMPARISON_OR_QA'
    END AS section_12_archive_persistence_status

FROM audit_row a

CROSS JOIN current_archive ca
CROSS JOIN archive_duplicates ad
CROSS JOIN inventory_diff inv;
```

These are export-readability refinements only. They should not change archive persistence, archive replacement behavior, row-level fidelity checks, or downstream comparison behavior.
<!-- END_MESSAGE C034-M01691 -->


---

<a id="c034-m01692"></a>

### C034-M01692

**Andrew** · 2026-05-17T21:03:18.180000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01692 -->
please review section 12 refined QA:
<!-- END_MESSAGE C034-M01692 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.11_QA_option_c_counteroffer_split_archive_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.13_QA_section_12_readiness_summary(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.10_QA_current_archived_slice_requested_versus_approved_exposure_expected_loss_summary(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_31.md) · [Next](Part_33.md)
