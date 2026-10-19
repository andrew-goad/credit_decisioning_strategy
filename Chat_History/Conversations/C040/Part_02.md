# Campaign QA and strategy expansion

## Part 02

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_01.md) · [Next](Part_03.md)

<a id="c040-m01762"></a>

### C040-M01762

**ChatGPT** · 2026-05-18T18:24:09.917023-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01762 -->
## Section 14.7 through 14.11 QA review verdict

```text
Section 14.7–14.11 QA status: PASS
Synthetic risk behavior: PASS
Requested PTI behavior: PASS
DTI capacity behavior: PASS
Exposure / Expected Loss conventions: PASS
Counteroffer feasibility and final counteroffer behavior: PASS
Option C baseline posture: PASS
Blockers: none
Required changes: none
Hold refinements until full Section 14 review: yes
```

This batch is doing what Section 14 is intended to do: validate latest-run behavior across risk, affordability, DTI, requested exposure, requested/approved Expected Loss, counteroffer treatment, and Option C path behavior while remaining read-only and not recalculating outcomes. fileciteturn13file22

---

## 14.7A — Synthetic risk tier × final decision outcome

```text
Status: PASS
```

The synthetic-risk tier behavior is strongly directional.

Key distribution:

```text
LOW_SYNTHETIC_RISK
    APPROVE          8,941
    COUNTEROFFER     6,026
    MANUAL_REVIEW    2,099
    DECLINE             56

MODERATE_SYNTHETIC_RISK
    APPROVE          1,754
    COUNTEROFFER     3,306
    MANUAL_REVIEW    1,495
    DECLINE            258

ELEVATED_SYNTHETIC_RISK
    APPROVE              0
    COUNTEROFFER     7,979
    MANUAL_REVIEW      290
    DECLINE            414

HIGH_SYNTHETIC_RISK
    APPROVE              0
    COUNTEROFFER     1,756
    MANUAL_REVIEW    3,651
    DECLINE          1,005

SEVERE_SYNTHETIC_RISK
    DECLINE         10,970
```

Important behavior:

```text
Severe synthetic risk resolves entirely to DECLINE.
High synthetic risk has no approvals.
Elevated synthetic risk has no approvals but retains substantial counteroffer treatment.
Low/moderate risk retain approval, counteroffer, and review outcomes.
```

This matches the expected strategy posture.

---

## 14.7B — Synthetic risk tier compact summary

```text
Status: PASS
```

Applications reconcile to 50,000:

```text
LOW_SYNTHETIC_RISK          17,122
MODERATE_SYNTHETIC_RISK      6,813
ELEVATED_SYNTHETIC_RISK      8,683
HIGH_SYNTHETIC_RISK          6,412
SEVERE_SYNTHETIC_RISK       10,970
```

Average synthetic estimated-PD proxy increases by tier:

```text
LOW          0.022501
MODERATE     0.053401
ELEVATED     0.114691
HIGH         0.262232
SEVERE       0.432263
```

Offer-exposure behavior is coherent:

```text
LOW_SYNTHETIC_RISK offer exposure rate       87.41%
MODERATE_SYNTHETIC_RISK offer exposure rate  74.27%
ELEVATED_SYNTHETIC_RISK offer exposure rate  91.89%
HIGH_SYNTHETIC_RISK offer exposure rate      27.39%
SEVERE_SYNTHETIC_RISK offer exposure rate     0.00%
```

The elevated tier’s high counteroffer rate is not a defect. It reflects a strategy posture where elevated synthetic risk often routes into governed reduced-exposure treatment rather than approval or automatic decline.

Optional polish to hold: the column name `approved_expected_loss_rate` likely means approved EL per approved dollar, not approved EL capture versus requested EL. We should collect this with the similar Section 14.4B naming issue and patch all Section 14 rate-label clarifications together later.

---

## 14.7C — Offer versus decline synthetic estimated-risk profile

```text
Status: PASS
```

This is a clean directional check:

```text
simulated_offer_exposure_rows = 29,762
decline_rows = 12,703

avg synthetic estimated-PD proxy, offer rows   = 0.064969
avg synthetic estimated-PD proxy, decline rows = 0.398304

decline_minus_offer_avg_synthetic_estimated_pd_proxy = 0.333336

synthetic_risk_directional_status =
SYNTHETIC_RISK_DIRECTIONALLY_COHERENT
```

This is exactly the intended risk-ordering result.

---

## 14.8A — Requested PTI bucket × final decision outcome

```text
Status: PASS
```

Requested PTI behavior is coherent.

Distribution:

```text
LOW_REQUESTED_PTI
    APPROVE          8,060
    COUNTEROFFER     5,482
    MANUAL_REVIEW    3,786
    DECLINE          2,615

MODERATE_REQUESTED_PTI
    APPROVE          2,635
    COUNTEROFFER     7,439
    MANUAL_REVIEW    2,562
    DECLINE          5,461

ELEVATED_REQUESTED_PTI
    APPROVE              0
    COUNTEROFFER     5,125
    MANUAL_REVIEW      713
    DECLINE          2,872

HIGH_REQUESTED_PTI
    APPROVE              0
    COUNTEROFFER     1,020
    MANUAL_REVIEW      358
    DECLINE            948

SEVERE_REQUESTED_PTI
    APPROVE              0
    COUNTEROFFER         1
    MANUAL_REVIEW      116
    DECLINE            807
```

Important behavior:

```text
No elevated, high, or severe requested-PTI rows resolve to APPROVE.
Severe requested PTI is overwhelmingly DECLINE.
Some high / elevated PTI rows remain eligible for reduced-exposure counteroffer treatment.
```

The one severe-PTI final counteroffer row is not a blocker. It is a very small edge case and appears feasible under product-specific counteroffer constraints.

---

## 14.8B — Requested versus approved PTI by final outcome

```text
Status: PASS
```

PTI conventions are exact:

```text
APPROVE
    row_count = 10,695
    requested PTI = approved PTI
    convention violations = 0

COUNTEROFFER
    row_count = 19,067
    avg requested PTI = 0.185296
    avg approved PTI  = 0.143459
    avg PTI reduction = 0.041837
    counteroffer rows above target PTI = 0

MANUAL_REVIEW
    row_count = 7,535
    approved PTI = NULL
    convention violations = 0

DECLINE
    row_count = 12,703
    approved PTI = 0
    convention violations = 0
```

This is a strong affordability convention pass.

---

## 14.8C — Product-level requested and approved PTI profile

```text
Status: PASS
```

Product-level PTI behavior is coherent:

```text
AUTO_LOAN
    avg requested PTI all rows = 0.125777
    avg approved PTI offer rows = 0.082618
    counteroffer rows above target PTI = 0

HELOC
    avg requested PTI all rows = 0.177672
    avg approved PTI offer rows = 0.104458
    counteroffer rows above target PTI = 0

MORTGAGE
    avg requested PTI all rows = 0.296708
    avg approved PTI offer rows = 0.254325
    counteroffer rows above target PTI = 0

REVOLVING_LINE
    avg requested PTI all rows = 0.062839
    avg approved PTI offer rows = 0.040601
    counteroffer rows above target PTI = 0

UNSECURED_PERSONAL_LOAN
    avg requested PTI all rows = 0.114439
    avg approved PTI offer rows = 0.069459
    counteroffer rows above target PTI = 0
```

Mortgage has the highest requested PTI and remains structurally heavier, but approved-offer PTI is lower than requested PTI. This is expected and consistent with mortgage exposure size.

No issue.

---

## 14.9A — DTI bucket × final decision outcome

```text
Status: PASS
```

DTI behavior is clean:

```text
LOW_DTI
    APPROVE          1,066
    COUNTEROFFER       888
    MANUAL_REVIEW      108
    DECLINE             22

MODERATE_DTI
    APPROVE          9,629
    COUNTEROFFER    13,182
    MANUAL_REVIEW    3,726
    DECLINE          3,083

ELEVATED_DTI
    APPROVE              0
    COUNTEROFFER     4,997
    MANUAL_REVIEW    3,701
    DECLINE          7,423

SEVERE_DTI
    DECLINE          2,175
```

Important behavior:

```text
Severe DTI resolves entirely to DECLINE.
Elevated DTI has no approvals.
Low and moderate DTI can still decline due to other risk / policy conditions.
```

This is coherent.

---

## 14.9B — DTI decline-trigger behavior

```text
Status: PASS
```

Rows with `dti_decline_trigger_flag = TRUE` all resolve to final DECLINE:

```text
TRUE / HARD_POLICY_STOP           726
TRUE / SEVERE_DTI_CAPACITY        445
TRUE / SEVERE_SYNTHETIC_RISK    1,006
total TRUE decline-trigger rows 2,177
```

This is correct. The 2,177 true trigger rows are all decline outcomes, but only 445 use the specific `SEVERE_DTI_CAPACITY` decision path because higher-priority policy stop or severe synthetic-risk routes can win the decision path. That is not a defect; it reflects route priority.

Rows with `dti_decline_trigger_flag = FALSE` can still decline, counteroffer, review, or approve because non-DTI route families apply.

No issue.

---

## 14.9C — Severe DTI non-decline diagnostic sample

```text
Status: PASS
```

The sample is empty:

```text
severe DTI non-decline rows = 0
```

That is the expected result. It confirms severe DTI rows did not leak into approve, counteroffer, or manual review.

---

## 14.10A — Requested versus approved exposure by final decision outcome

```text
Status: PASS
```

All exposure convention violation counts are zero.

Core conventions:

```text
APPROVE
    row_count = 10,695
    avg requested amount = avg approved amount = 113,984.96
    approved amount capture rate = 1.000000

COUNTEROFFER
    row_count = 19,067
    avg requested amount = 176,816.14
    avg approved amount = 136,791.79
    avg exposure reduction = 40,024.36
    avg exposure reduction pct = 0.197860

MANUAL_REVIEW
    row_count = 7,535
    approved amount = NULL / unresolved
    convention violations = 0

DECLINE
    row_count = 12,703
    approved amount = 0
    convention violations = 0
```

This is a clean exposure convention pass.

---

## 14.10B — Requested versus approved Expected Loss by final decision outcome

```text
Status: PASS
```

All Expected Loss convention violation counts are zero.

Core conventions:

```text
APPROVE
    avg requested EL = avg approved EL = 773.063017

COUNTEROFFER
    avg requested EL = 3,474.715662
    avg approved EL = 2,637.215254
    avg approved EL reduction = 837.500408
    avg approved EL reduction pct = 0.197860

MANUAL_REVIEW
    approved EL = NULL / unresolved
    convention violations = 0

DECLINE
    approved EL = 0
    convention violations = 0
```

The counteroffer Expected Loss reduction percentage matches the exposure reduction percentage, which is expected because estimated-PD proxy and LGD remain unchanged and approved exposure is reduced.

Optional polish to hold: `approved_expected_loss_rate` likely means approved EL divided by approved amount, not approved EL capture versus requested EL. We should align that naming with the later Section 12 refinement once we finish all of Section 14.

---

## 14.10C — Requested exposure tier × final decision outcome

```text
Status: PASS
```

Requested exposure tier behavior is coherent:

```text
LOW_REQUESTED_EXPOSURE
    APPROVE          6,027
    COUNTEROFFER     4,536
    MANUAL_REVIEW    3,741
    DECLINE          6,278

WITHIN_PRODUCT_APPROVAL_CAP
    APPROVE          4,668
    COUNTEROFFER     5,626
    MANUAL_REVIEW    2,698
    DECLINE          3,798

ABOVE_PRODUCT_APPROVAL_CAP
    APPROVE              0
    COUNTEROFFER     8,905
    MANUAL_REVIEW    1,096
    DECLINE          2,627
```

The key behavior is clean:

```text
ABOVE_PRODUCT_APPROVAL_CAP / APPROVE = 0
```

Above-cap rows mostly become counteroffers, which is the intended exposure-management behavior.

Optional polish to hold: this output uses `avg_approved_amount_all_apps`, which appears convention-adjusted / zero-filled for unresolved or no-offer outcomes. That is not wrong, but it should eventually get the same note pattern we added in Sections 9, 11, and 12.

---

## 14.10D — Requested Expected Loss tier × final decision outcome

```text
Status: PASS
```

Requested Expected Loss tier behavior is coherent:

```text
LOW_REQUESTED_EL
    APPROVE         10,524
    COUNTEROFFER    10,413
    MANUAL_REVIEW    4,216
    DECLINE          1,005

MODERATE_REQUESTED_EL
    APPROVE            171
    COUNTEROFFER     4,685
    MANUAL_REVIEW    1,310
    DECLINE          2,243

ELEVATED_REQUESTED_EL
    APPROVE              0
    COUNTEROFFER     3,969
    MANUAL_REVIEW      509
    DECLINE          3,413

HIGH_REQUESTED_EL
    APPROVE              0
    COUNTEROFFER         0
    MANUAL_REVIEW    1,413
    DECLINE          4,140

SEVERE_REQUESTED_EL
    APPROVE              0
    COUNTEROFFER         0
    MANUAL_REVIEW       87
    DECLINE          1,902
```

Important behavior:

```text
High and severe requested-EL rows do not resolve to final APPROVE or COUNTEROFFER.
Low and moderate requested-EL rows retain positive-offer access.
Elevated requested-EL rows can still become final counteroffers where feasible.
```

This is a strong Expected Loss validation result.

Optional polish to hold: requested Expected Loss tiers are product-policy-relative; if this section does not already have an interpretation note, we may add one at the end-of-Section-14 refinement pass.

---

## 14.11A — Counteroffer summary

```text
Status: PASS
```

Counteroffer summary reconciles cleanly:

```text
preliminary_counteroffer_rows = 21,286
feasible_counteroffers = 19,067
failed_counteroffers = 2,219
final_counteroffer_rows = 19,067

counteroffer_feasibility_pass_rate = 0.895753
```

Final counteroffers reduce exposure, PTI, and Expected Loss:

```text
avg exposure reduction pct = 0.197860

avg requested PTI = 0.185296
avg approved PTI = 0.143459
avg PTI reduction = 0.041837

avg requested EL = 3,474.715662
avg approved EL = 2,637.215254
avg approved EL reduction pct = 0.197860
```

This confirms counteroffer treatment is functioning as governed reduced-exposure treatment.

---

## 14.11B — Counteroffer feasibility failure reason distribution

```text
Status: PASS
```

Failed counteroffers reconcile to 2,219:

```text
COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT    2,070   93.29%
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT            89    4.01%
COUNTEROFFER_EXCEEDS_MAX_REDUCTION                 60    2.70%
```

This is consistent with the accepted Section 8 / Section 9 counteroffer feasibility pattern.

No issue.

---

## 14.11C — Product × counteroffer feasibility summary

```text
Status: PASS
```

Product-level feasibility behavior is coherent.

Approximate feasibility pass rates:

```text
AUTO_LOAN
    3,167 / 3,552 = 89.16%

HELOC
    1,872 / 1,981 = 94.50%

MORTGAGE
    5,848 / 6,357 = 92.00%

REVOLVING_LINE
    5,231 / 5,948 = 87.95%

UNSECURED_PERSONAL_LOAN
    2,949 / 3,448 = 85.53%
```

Product economics are intuitive:

```text
MORTGAGE has the largest dollar exposure.
REVOLVING_LINE and UNSECURED_PERSONAL_LOAN have high relative exposure-reduction percentages.
HELOC has the highest feasibility pass rate.
UNSECURED_PERSONAL_LOAN has the lowest feasibility pass rate.
```

No issue.

---

## 14.11D — Score band × counteroffer feasibility summary

```text
Status: PASS
```

Score-band feasibility is strongly directional:

```text
SUPER_PRIME
    3,611 / 3,622 = 99.70%

PRIME
    5,657 / 5,716 = 98.97%

NEAR_PRIME
    8,818 / 9,555 = 92.29%

SUBPRIME
    980 / 2,391 = 40.99%

DEEP_SUBPRIME
    1 / 2 = 50.00% but n = 2, so not analytically meaningful
```

This is exactly the desired pattern:

```text
stronger score bands usually pass feasibility;
near-prime remains heavily feasible;
subprime feasibility drops materially;
deep-subprime has essentially no meaningful counteroffer population.
```

No issue.

---

## 14.11E — Final counteroffer convention diagnostic

```text
Status: PASS
```

All convention violations are zero:

```text
counteroffer_without_feasibility_pass_rows = 0
counteroffer_amount_convention_violation_rows = 0
counteroffer_exposure_reduction_convention_violation_rows = 0
counteroffer_affordability_convention_violation_rows = 0
counteroffer_expected_loss_convention_violation_rows = 0
counteroffer_reason_family_violation_rows = 0
```

This is the controlling counteroffer convention check, and it passes cleanly.

---

## 14.11F — Final counteroffer primary reason-code distribution

```text
Status: PASS
```

Final counteroffer reason-code totals reconcile to 19,067:

```text
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT        8,905   46.70%
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT      5,021   26.33%
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK       3,853   20.21%
COUNTEROFFER_EXPECTED_LOSS_LIMIT           1,288    6.76%
```

Reason-code economics are coherent:

```text
PRODUCT_EXPOSURE_LIMIT:
    largest counteroffer reason group; avg exposure reduction pct = 0.240394

AFFORDABILITY_ADJUSTMENT:
    highest requested PTI; approved PTI reduced materially

ELEVATED_SYNTHETIC_RISK:
    smaller average exposure reduction; reason is risk posture rather than large exposure

EXPECTED_LOSS_LIMIT:
    highest requested EL and meaningful EL reduction
```

No issue.

---

## 14.11G — Option C counteroffer strategy split validation diagnostics

```text
Status: PASS
```

The M2-01 baseline Option C posture is correct:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive_override_rows = 0
```

Ordinary counteroffer evidence is preserved across grouped rows:

```text
ordinary counteroffer candidate rows in final COUNTEROFFER groups = 19,067
ordinary counteroffer candidate rows in MANUAL_REVIEW_FAILED_COUNTEROFFER = 2,219

total ordinary counteroffer candidate rows = 21,286
```

Aggressive override evidence is correctly inactive:

```text
aggressive_override_rows = 0
aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
aggressive_override_reason_trace_rows = 0
```

This matches the accepted M2-01 baseline state.

Optional polish to hold: the column `latest_run_rows` is grouped by outcome / reason-code group, not total latest-run rows. We already addressed similar language in Section 11 and Section 12; we may want to apply the same note or alias cleanup in Section 14.11G after the full Section 14 review.

---

# Batch verdict for Section 14.7–14.11

```text
M2-01 Section 14.7–14.11 QA: ACCEPTED

Synthetic risk ordering is coherent.
Offer rows have much lower synthetic estimated-PD proxy than decline rows.
Requested PTI behavior is coherent.
Approved PTI conventions pass.
Product-level PTI behavior is coherent.
DTI behavior is coherent.
Severe DTI rows do not leak into non-decline outcomes.
Requested versus approved exposure conventions pass.
Requested versus approved Expected Loss conventions pass.
Above-cap exposure rows do not resolve to approval.
High/severe requested-EL rows do not resolve to approval or counteroffer.
Counteroffer feasibility summary reconciles.
Counteroffer failure reasons reconcile.
Product and score-band counteroffer feasibility behavior is coherent.
Final counteroffer convention checks pass.
Option C baseline posture is correct.
No blocker found.
```

## Refinement candidates to hold until full Section 14 is complete

I would not patch anything yet, per your plan. I would track these for a possible end-of-Section-14 cleanup pass:

```text
1. Clarify approved_expected_loss_rate naming where it means approved EL / approved amount.
   Seen in:
       14.4B
       14.7B
       14.10B

2. Add or standardize interpretation notes for all-row convention-adjusted approved amount / EL metrics.
   Seen in:
       14.10C
       14.10D
       likely other Section 14 grids

3. Add or standardize product-policy-relative notes for requested exposure tier and requested EL tier outputs.
   Relevant to:
       14.10C
       14.10D

4. Clarify grouped-row count naming in 14.11G.
   latest_run_rows may be better as grouped_latest_run_rows or paired with an interpretation_note.
```

None of those are logic blockers. They are export-readability refinements only.
<!-- END_MESSAGE C040-M01762 -->


---

<a id="c040-m01763"></a>

### C040-M01763

**Andrew** · 2026-05-18T19:17:50.589000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01763 -->
continue to save refinements for when we are done with full section 14 QA.  here is the third batch to review.  please review 14.12 to 14.15 QA:
<!-- END_MESSAGE C040-M01763 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13C_QA_decline_zero_exposure_convention_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13D_QA_product_x_score_decline_concentration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13E_QA_final_decline_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.14A_QA_reason_code_completeness_and_family_alignment_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.14B_QA_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.14C_QA_reason_code_count_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.14D_QA_product_x_score_x_primary_reason_code_concentration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.14E_QA_top_primary_reason_code_concentration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.15A_QA_simulated_offer_exposure_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.15B_QA_product_x_score_composition_of_simulated_offer_exposure_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.15C_QA_offer_exposure_reason_code_profile.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12A_QA_manual_review_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12B_QA_manual_review_path_and_primary_reason_code_distibution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12C_QA_manual_review_unresolved_convention_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12D_QA_product_x_score_manual_review_concentration.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13A_QA_decline_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13B_QA_decline_path_and_primary_reason_code_distribution.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01768"></a>

### C040-M01768

**ChatGPT** · 2026-05-18T19:26:10.501395-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01768 -->
## Section 14.12 through 14.15 QA review verdict

```text
Section 14.12–14.15 QA status: PASS
Manual-review unresolved behavior: PASS
Decline / zero-exposure behavior: PASS
Reason-code completeness and alignment: PASS
Reason-code concentration: PASS
Simulated offer-exposure behavior: PASS
Blockers: none
Required changes now: none
Refinements: continue holding until full Section 14 QA is complete
```

This batch is clean. Section 14 remains the read-only validation layer for the completed latest-run output, and these diagnostics are validating manual review, decline, reason-code coverage, simulated offer exposure, and concentration patterns without changing latest-run or archive rows. fileciteturn13file22

---

## 14.12A — Manual review summary

```text
Status: PASS
```

Manual-review rows reconcile exactly:

```text
final_manual_review_rows = 7,535

preliminary_manual_review_rows = 5,316
failed_counteroffer_to_manual_review_rows = 2,219

5,316 + 2,219 = 7,535
```

This confirms the two expected manual-review sources:

```text
1. Rows that were preliminary MANUAL_REVIEW.
2. Failed preliminary counteroffers resolved to MANUAL_REVIEW under M2-01.
```

Additional metrics are coherent:

```text
avg_total_rule_trigger_count_for_manual_review_rows = 5.052555
avg_requested_amount_for_manual_review_rows = 110,774.98
avg_requested_pti_for_manual_review_rows = 0.139151
avg_requested_expected_loss_for_manual_review_rows = 4,226.77
```

No issue.

---

## 14.12B — Manual review path and primary reason-code distribution

```text
Status: PASS
```

Manual-review reason-code distribution reconciles to 7,535 rows:

```text
MANUAL_REVIEW_FAILED_COUNTEROFFER        2,219   29.45%
MANUAL_REVIEW_BORDERLINE_PROFILE         1,926   25.56%
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW      1,790   23.76%
MANUAL_REVIEW_DTI_REVIEW                 1,600   21.23%
```

This is coherent.

The failed-counteroffer group has the highest average trigger pressure and Expected Loss:

```text
avg_total_rule_trigger_count = 10.756647
avg_requested_expected_loss_amount = 9,827.39
```

That is expected because these rows first entered counteroffer feasibility and then failed feasibility constraints.

The `MANUAL_REVIEW_BORDERLINE_PROFILE` group has a lower average trigger count:

```text
avg_total_rule_trigger_count = 1.000000
```

That is also expected because borderline profile itself can drive review posture.

No issue.

---

## 14.12C — Manual review unresolved convention diagnostic

```text
Status: PASS
```

All unresolved-convention violations are zero:

```text
manual_review_approved_amount_violation_rows = 0
manual_review_counteroffer_amount_violation_rows = 0
manual_review_approved_payment_violation_rows = 0
manual_review_approved_pti_violation_rows = 0
manual_review_approved_expected_loss_violation_rows = 0
manual_review_offer_exposure_flag_violation_rows = 0
manual_review_reason_family_violation_rows = 0
```

This confirms the locked convention:

```text
MANUAL_REVIEW remains unresolved.
approved_amount = NULL
counteroffer_amount = NULL
approved payment / PTI / EL = NULL
simulated_offer_exposure_flag = FALSE
primary_reason_family = MANUAL_REVIEW
```

No issue.

---

## 14.12D — Product × score manual-review concentration

```text
Status: PASS
```

Manual-review rows reconcile:

```text
sum(manual_review_rows) = 7,535
```

Top manual-review concentration segments are intuitive:

```text
REVOLVING_LINE / SUBPRIME
    manual_review_rate = 43.11%

AUTO_LOAN / SUBPRIME
    manual_review_rate = 36.33%

UNSECURED_PERSONAL_LOAN / SUBPRIME
    manual_review_rate = 35.76%

HELOC / SUBPRIME
    manual_review_rate = 27.74%

MORTGAGE / SUBPRIME
    manual_review_rate = 21.11%
```

This is directionally coherent. Subprime segments carry the highest manual-review concentration, especially where counteroffer feasibility, review pressure, or risk/affordability flags accumulate.

No issue.

---

## 14.13A — Decline summary

```text
Status: PASS
```

Decline rows reconcile:

```text
final_decline_rows = 12,703
```

Key decline trigger counts:

```text
hard_policy_stop_decline_rows = 5,889
synthetic_risk_decline_trigger_rows = 10,970
dti_decline_trigger_rows = 2,177
failed_counteroffer_to_decline_rows = 0
```

The trigger counts intentionally overlap and should not be summed to equal final declines. A decline row can carry multiple severe conditions, but only one final `decision_path` and one primary reason code.

M2-01’s failed-counteroffer policy remains correct:

```text
failed_counteroffer_to_decline_rows = 0
```

because M2-01 resolves failed counteroffers to manual review.

Decline risk profile is appropriately severe:

```text
avg_synthetic_estimated_pd_proxy_for_declines = 0.398304
avg_dti_for_declines = 0.499601
avg_requested_pti_for_declines = 0.216139
avg_requested_expected_loss_for_declines = 10,475.04
avg_total_rule_trigger_count_for_declines = 9.785720
```

No issue.

---

## 14.13B — Decline path and primary reason-code distribution

```text
Status: PASS
```

Decline reason-code distribution reconciles to 12,703 rows:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK      6,369   50.14%
POLICY_STOP_SEVERE_DELINQUENCY         2,955   23.26%
POLICY_STOP_MAJOR_DEROGATORY           2,107   16.59%
POLICY_STOP_BANKRUPTCY                   827    6.51%
POLICY_STOP_SEVERE_DTI                   445    3.50%
```

This is coherent.

The `POLICY_STOP_SEVERE_DTI` group has the highest average DTI:

```text
avg_debt_to_income_ratio = 0.637688
```

The severe synthetic-risk group has the highest synthetic risk concentration:

```text
avg_synthetic_estimated_pd_proxy = 0.424372
```

No issue.

---

## 14.13C — Decline zero-exposure convention diagnostic

```text
Status: PASS
```

All decline convention violations are zero:

```text
decline_approved_amount_violation_rows = 0
decline_counteroffer_amount_violation_rows = 0
decline_approved_payment_violation_rows = 0
decline_approved_pti_violation_rows = 0
decline_approved_expected_loss_violation_rows = 0
decline_offer_exposure_flag_violation_rows = 0
decline_reason_family_violation_rows = 0
```

This confirms the locked convention:

```text
DECLINE uses zero-exposure convention.
approved_amount = 0
approved payment / PTI / EL = 0
counteroffer_amount = NULL
simulated_offer_exposure_flag = FALSE
primary_reason_family = POLICY_STOP
```

No issue.

---

## 14.13D — Product × score decline concentration

```text
Status: PASS
```

Decline rows reconcile:

```text
sum(decline_rows) = 12,703
```

Deep-subprime behavior is exactly as expected:

```text
MORTGAGE / DEEP_SUBPRIME
    decline_rate = 99.94%

UNSECURED_PERSONAL_LOAN / DEEP_SUBPRIME
    decline_rate = 99.89%

REVOLVING_LINE / DEEP_SUBPRIME
    decline_rate = 99.67%

HELOC / DEEP_SUBPRIME
    decline_rate = 99.55%

AUTO_LOAN / DEEP_SUBPRIME
    decline_rate = 99.44%
```

Subprime also shows materially elevated decline concentration:

```text
MORTGAGE / SUBPRIME       = 67.15%
HELOC / SUBPRIME          = 62.86%
UNSECURED / SUBPRIME      = 56.47%
AUTO_LOAN / SUBPRIME      = 51.96%
REVOLVING_LINE / SUBPRIME = 44.64%
```

This is directionally strong. Weak score segments are properly decline-heavy, while stronger segments have low decline rates.

No issue.

---

## 14.13E — Final decline primary reason-code distribution

```text
Status: PASS
```

This agrees with 14.13B and is coherent:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK      6,369
POLICY_STOP_SEVERE_DELINQUENCY         2,955
POLICY_STOP_MAJOR_DEROGATORY           2,107
POLICY_STOP_BANKRUPTCY                   827
POLICY_STOP_SEVERE_DTI                   445
```

The reason-code economics are also directionally appropriate:

```text
SEVERE_SYNTHETIC_RISK:
    high avg synthetic estimated-PD proxy = 0.424372

SEVERE_DTI:
    highest avg DTI = 0.637688

SEVERE_DELINQUENCY / BANKRUPTCY:
    high rule-trigger pressure and high requested Expected Loss
```

No issue.

---

## 14.14A — Reason-code completeness and family alignment diagnostic

```text
Status: PASS
```

All reason-code integrity checks are zero:

```text
missing_primary_reason_code_rows = 0
missing_primary_reason_family_rows = 0
missing_triggered_reason_code_list_rows = 0
invalid_reason_priority_rank_rows = 0
invalid_reason_code_count_rows = 0

approve_reason_family_alignment_violation_rows = 0
counteroffer_reason_family_alignment_violation_rows = 0
manual_review_reason_family_alignment_violation_rows = 0
decline_reason_family_alignment_violation_rows = 0
```

This is the primary reason-code integrity gate in this batch, and it passes cleanly.

No issue.

---

## 14.14B — Primary reason-code distribution

```text
Status: PASS
```

Primary reason-code rows reconcile:

```text
row_count sum = 50,000
```

Distribution remains the accepted M2-01 profile:

```text
APPROVED_AS_REQUESTED                         10,695   21.39%
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT            8,905   17.81%
POLICY_STOP_SEVERE_SYNTHETIC_RISK              6,369   12.74%
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT          5,021   10.04%
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK           3,853    7.71%
POLICY_STOP_SEVERE_DELINQUENCY                 2,955    5.91%
MANUAL_REVIEW_FAILED_COUNTEROFFER              2,219    4.44%
POLICY_STOP_MAJOR_DEROGATORY                   2,107    4.21%
MANUAL_REVIEW_BORDERLINE_PROFILE               1,926    3.85%
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW            1,790    3.58%
MANUAL_REVIEW_DTI_REVIEW                       1,600    3.20%
COUNTEROFFER_EXPECTED_LOSS_LIMIT               1,288    2.58%
POLICY_STOP_BANKRUPTCY                           827    1.65%
POLICY_STOP_SEVERE_DTI                           445    0.89%
```

No issue.

Optional polish to hold: the all-row approved amount / Expected Loss columns use final-output conventions. That is acceptable, but a note could be added later to clarify unresolved manual review and zero decline treatment.

---

## 14.14C — Reason-code count distribution

```text
Status: PASS
```

Rows reconcile:

```text
row_count sum = 50,000
```

Reason-code count behavior is coherent:

```text
APPROVE:
    reason_code_count = 1 for 100% of rows

COUNTEROFFER:
    reason_code_count ranges from 2 to 6

MANUAL_REVIEW:
    reason_code_count ranges from 2 to 9

DECLINE:
    reason_code_count ranges from 2 to 7
```

This is expected. Approvals are clean, while counteroffer, manual review, and decline rows often carry multiple rule/explanation drivers.

No issue.

---

## 14.14D — Product × score × primary reason-code concentration

```text
Status: PASS
```

Rows reconcile:

```text
row_count sum = 50,000
product × score segments = 25
primary reason-code rows = 222
```

This output provides a granular explanation layer and behaves coherently.

Examples:

```text
AUTO_LOAN / SUPER_PRIME:
    APPROVED_AS_REQUESTED = 63.49%
    COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT = 28.28%

AUTO_LOAN / PRIME:
    APPROVED_AS_REQUESTED = 48.32%
    COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT = 24.79%

AUTO_LOAN / NEAR_PRIME:
    COUNTEROFFER_ELEVATED_SYNTHETIC_RISK = 37.57%
```

This confirms the reason-code profile shifts as score quality weakens and as strategy treatment changes from approval to counteroffer/review/decline.

No issue.

---

## 14.14E — Top primary reason-code concentration

```text
Status: PASS
```

The top primary reason code is:

```text
APPROVED_AS_REQUESTED
```

with:

```text
top_primary_reason_code_rows = 10,695
top_primary_reason_code_share = 0.2139
```

Status:

```text
PRIMARY_REASON_CODE_CONCENTRATION_WITHIN_REVIEW_BOUNDS
```

This is acceptable. The top reason code is only 21.39% of the portfolio, so reason-code concentration is not excessive.

No issue.

---

## 14.15A — Simulated offer exposure summary

```text
Status: PASS
```

Rows reconcile:

```text
simulated_offer_exposure_flag = TRUE     29,762   59.52%
simulated_offer_exposure_flag = FALSE    20,238   40.48%
```

This exactly matches:

```text
APPROVE + COUNTEROFFER = 10,695 + 19,067 = 29,762
MANUAL_REVIEW + DECLINE = 7,535 + 12,703 = 20,238
```

Offer exposure rows are materially stronger:

```text
avg_credit_score:
    offer exposure = 727.80
    no offer exposure = 620.15

avg_synthetic_estimated_pd_proxy:
    offer exposure = 0.064969
    no offer exposure = 0.308069

avg_requested_expected_loss_amount:
    offer exposure = 2,503.87
    no offer exposure = 8,148.69
```

This is a strong directional validation.

No issue.

---

## 14.15B — Product × score composition of simulated offer exposure rows

```text
Status: PASS
```

The product × score offer exposure profile is coherent.

Strong segments show high simulated offer exposure rates:

```text
REVOLVING_LINE / SUPER_PRIME = 95.16%
HELOC / SUPER_PRIME = 94.22%
UNSECURED_PERSONAL_LOAN / SUPER_PRIME = 93.31%
AUTO_LOAN / SUPER_PRIME = 93.28%
MORTGAGE / SUPER_PRIME = 88.82%
```

Prime and near-prime segments retain substantial offer exposure:

```text
Prime segments generally around 76%–83%
Near-prime segments generally around 75%–81%
```

Subprime segments drop sharply:

```text
AUTO_LOAN / SUBPRIME = 11.71%
HELOC / SUBPRIME = 9.40%
MORTGAGE / SUBPRIME = 11.75%
REVOLVING_LINE / SUBPRIME = 12.25%
UNSECURED_PERSONAL_LOAN / SUBPRIME = 7.77%
```

Deep-subprime segments have essentially zero offer exposure:

```text
REVOLVING_LINE / DEEP_SUBPRIME = 1 row / 0.0664%
all other deep-subprime product segments = 0
```

This is directionally excellent.

No issue.

Optional polish to hold: `NaN` is expected in offer-only metrics when there are zero offer rows. If we later polish Section 14 exports, we may add an interpretation note explaining that offer-row averages are NULL/NaN for zero-offer segments.

---

## 14.15C — Offer exposure reason-code profile

```text
Status: PASS
```

Rows reconcile:

```text
row_count sum = 50,000
```

Offer exposure side:

```text
APPROVED_AS_REQUESTED                         10,695
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT            8,905
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT          5,021
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK           3,853
COUNTEROFFER_EXPECTED_LOSS_LIMIT               1,288

total offer rows = 29,762
```

No-offer side:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK              6,369
POLICY_STOP_SEVERE_DELINQUENCY                 2,955
MANUAL_REVIEW_FAILED_COUNTEROFFER              2,219
POLICY_STOP_MAJOR_DEROGATORY                   2,107
MANUAL_REVIEW_BORDERLINE_PROFILE               1,926
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW            1,790
MANUAL_REVIEW_DTI_REVIEW                       1,600
POLICY_STOP_BANKRUPTCY                           827
POLICY_STOP_SEVERE_DTI                           445

total non-offer rows = 20,238
```

This is exactly the expected reason-code split:

```text
Offer exposure = APPROVAL + COUNTEROFFER families
No offer exposure = MANUAL_REVIEW + POLICY_STOP families
```

No issue.

---

# Batch verdict for Section 14.12–14.15

```text
M2-01 Section 14.12–14.15 QA: ACCEPTED

Manual-review row count reconciles.
Failed counteroffers resolve to manual review as expected for M2-01.
Manual-review unresolved conventions pass.
Manual-review concentration by product × score is coherent.
Decline rows reconcile.
Decline reason codes are coherent.
Decline zero-exposure conventions pass.
Deep-subprime decline concentration is appropriately high.
Reason-code completeness and family alignment pass.
Primary reason-code distribution reconciles to 50,000.
Reason-code count distribution is coherent.
Top reason-code concentration is within review bounds.
Simulated offer exposure reconciles exactly to APPROVE + COUNTEROFFER.
Offer rows are materially stronger than non-offer rows.
Product × score offer exposure composition is directionally strong.
Offer exposure reason-code profile is coherent.
No blocker found.
```

## Refinement candidates to continue holding

No immediate patch. Track these for the end-of-Section-14 cleanup pass:

```text
1. Add / standardize notes for all-row convention-adjusted approved amount / EL metrics.
   Seen again in:
       14.14B
       14.15C

2. Add / standardize notes for offer-only metrics returning NaN where zero offer rows exist.
   Seen in:
       14.15B

3. Consider renaming / clarifying any “rate” fields that mean approved EL per approved dollar
   rather than capture rate versus requested EL.
   Already tracked from:
       14.4B
       14.7B
       14.10B

4. Filename typo only:
       14.12B file name says “distibution”
   This is not a SQL logic issue, but we can fix the export label / comment later if desired.
```

Section 14.12–14.15 is accepted.
<!-- END_MESSAGE C040-M01768 -->


---

<a id="c040-m01770"></a>

### C040-M01770

**Andrew** · 2026-05-18T19:33:58.340000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01770 -->
continue to save refinements for when we are done with full section 14 QA. here is the final batch to review. please review 14.16 to 14.20 QA.  when done, summarize section 14 QA refinement recommendations + optional.
<!-- END_MESSAGE C040-M01770 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16H_QA_multiple_mixed_signal_profiles.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16I_QA_borderline_profiles.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16J_QA_counteroffer_cases_with_large_exposure_reductions.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.17_QA_final_output_convention_validation.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.18A_QA_archive_readiness_context_for_current_latest_run_slice.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.18B_QA_selected_comparison_readiness_context.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.18C_QA_matched_source_field_consistency_context.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.18D_QA_option_c_matched_comparison_context.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.20A_QA_full_validation_status_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.20B_QA_validation_status_rollup.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.20C_QA_review_and_not_applicable_validation_items.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.20D_QA_section_14_completion_status.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16A_QA_mixed_signal_profile_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16B_QA_borderline_profile_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16C_QA_strong_credit_high_requested_pti_sample.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16D_QA_weak_credit_low_requested_pti_sample.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16E_QA_large_exposure_low_synthetic_risk_sample.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16F_QA_high_synthetic_risk_low_exposure_sample.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16G_QA_high_dti_low_requested_pti_sample.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01777"></a>

### C040-M01777

**ChatGPT** · 2026-05-18T19:41:36.766671-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01777 -->
## Section 14.16 through 14.20 QA review verdict

```text
Section 14.16–14.20 QA status: PASS
Section 14 full QA status: ACCEPTED
Section 14 validation summary status: READY_FOR_EVIDENCE_CAPTURE
Blockers: none
Required logic changes: none
Refinements: export-readability / narrative clarity only
```

Section 14 remains correctly scoped as the read-only validation and QA framework for the completed latest-run Module 2 output. It validates structural integrity, final-output conventions, segment behavior, counteroffer behavior, manual review, decline behavior, reason-code coverage, simulated offer exposure, archive context, optional matched-comparison context, and then materializes the compact validation spine consumed by Section 16. fileciteturn13file22

---

# 14.16 — Mixed-signal, borderline, and edge-case diagnostics

## 14.16A — Mixed-signal profile distribution

```text
Status: PASS / expected REVIEW in validation summary
```

The mixed-signal profile output reconciles to 50,000 rows.

Distribution:

```text
NO_MIXED_SIGNAL_PROFILE          32,190   64.38%
WEAK_CREDIT_LOW_PTI               8,426   16.85%
LARGE_EXPOSURE_LOW_RISK           6,711   13.42%
MULTIPLE_MIXED_SIGNALS            1,745    3.49%
STRONG_CREDIT_HIGH_PTI              539    1.08%
HIGH_DTI_LOW_REQUESTED_PTI          266    0.53%
HIGH_RISK_LOW_EXPOSURE              123    0.25%
```

The behavior is coherent:

```text
NO_MIXED_SIGNAL_PROFILE
    approval_rate = 33.22%
    simulated_offer_exposure_rate = 67.26%

LARGE_EXPOSURE_LOW_RISK
    counteroffer_rate = 98.90%
    decline_rate = 1.10%

STRONG_CREDIT_HIGH_PTI
    counteroffer_rate = 94.62%

WEAK_CREDIT_LOW_PTI
    decline_rate = 63.74%
    manual_review_rate = 26.51%

HIGH_RISK_LOW_EXPOSURE
    decline_rate = 95.94%

HIGH_DTI_LOW_REQUESTED_PTI
    decline_rate = 100.00%

MULTIPLE_MIXED_SIGNALS
    decline_rate = 84.70%
```

This is a good mixed-signal profile: the engine is not artificially rigid, but higher-risk mixed profiles are still governed appropriately.

The validation summary’s `REVIEW` status for mixed-signal / borderline visibility is not a blocker. It means the rate is large enough to document, not that the run failed.

---

## 14.16B — Borderline profile distribution

```text
Status: PASS / expected REVIEW in validation summary
```

Borderline behavior is coherent:

```text
borderline_profile_flag = TRUE
    row_count = 20,296
    approval_rate = 0.00%
    counteroffer_rate = 37.35%
    manual_review_rate = 27.12%
    decline_rate = 35.53%
    simulated_offer_exposure_rate = 37.35%

borderline_profile_flag = FALSE
    row_count = 29,704
    approval_rate = 36.01%
    counteroffer_rate = 38.67%
    manual_review_rate = 6.84%
    decline_rate = 18.49%
    simulated_offer_exposure_rate = 74.67%
```

This is directionally strong:

```text
All approvals are non-borderline.
Borderline rows can still receive counteroffers.
Borderline rows carry much higher manual-review and decline pressure.
```

No logic issue.

---

## 14.16C — Strong credit / high requested PTI sample

```text
Status: PASS
```

The sample is coherent.

Observed sample pattern:

```text
score band = PRIME
product = MORTGAGE
credit_score range = 719–759
avg requested PTI = 0.525853
avg synthetic estimated-PD proxy = 0.052626
decision_outcome:
    COUNTEROFFER = 24
    DECLINE = 1
```

The dominant reason codes are:

```text
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
```

This is exactly the expected behavior for strong-credit but high-PTI mortgage applicants: the strategy mostly preserves access through counteroffer rather than approval-as-requested.

The one decline is a hard-policy-stop row, which is acceptable.

---

## 14.16D — Weak credit / low requested PTI sample

```text
Status: PASS, with optional label-clarity note
```

The sample shows weak credit rows that still carry manageable-to-moderate requested PTI characteristics.

Observed sample pattern:

```text
credit_score range = 501–615
synthetic estimated-PD proxy = 0.450000 for all sample rows
decision_outcome = DECLINE for all 25 sample rows
```

Reason-code distribution:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK    11
POLICY_STOP_SEVERE_DELINQUENCY       10
POLICY_STOP_BANKRUPTCY                3
POLICY_STOP_MAJOR_DEROGATORY          1
```

This validates an important behavior:

```text
Manageable requested PTI does not override severe synthetic-risk or hard policy-stop logic.
```

Optional polish: the label says `weak credit low requested PTI`, but many sample rows show `MODERATE_REQUESTED_PTI`. If the logic intentionally captures weak credit with low-or-manageable PTI, the sample label could be clarified later.

---

## 14.16E — Large exposure / low synthetic risk sample

```text
Status: PASS
```

The sample is excellent.

Observed sample pattern:

```text
product = MORTGAGE
score_band = SUPER_PRIME
requested_exposure_tier = ABOVE_PRODUCT_APPROVAL_CAP
strategy_risk_tier = LOW_SYNTHETIC_RISK
avg requested amount = 998,625.71
avg approved amount = 785,600.00
avg synthetic estimated-PD proxy = 0.017527
decision_outcome = COUNTEROFFER for all 25 sample rows
primary_reason_code = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT for all 25 rows
```

This is exactly the desired edge-case behavior:

```text
Low risk does not automatically approve excessive exposure.
Large exposure is handled through product-cap counteroffer treatment.
```

---

## 14.16F — High synthetic risk / low exposure sample

```text
Status: PASS
```

The sample is coherent.

Observed sample pattern:

```text
requested amount range = 1,000.00–2,400.41
strategy_risk_tier = SEVERE_SYNTHETIC_RISK
synthetic estimated-PD proxy = 0.450000
decision_outcome = DECLINE for all 25 sample rows
```

Reason-code distribution:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK    12
POLICY_STOP_MAJOR_DEROGATORY          7
POLICY_STOP_BANKRUPTCY                3
POLICY_STOP_SEVERE_DELINQUENCY        3
```

This validates the opposite edge case:

```text
Low requested exposure does not override severe risk / policy-stop conditions.
```

No issue.

---

## 14.16G — High DTI / low requested PTI sample

```text
Status: PASS
```

The sample is coherent.

Observed sample pattern:

```text
debt_to_income_ratio = 0.700000 for all sample rows
requested PTI range = 0.006817–0.043586
requested_pti_bucket = LOW_REQUESTED_PTI for all rows
decision_outcome = DECLINE for all 25 sample rows
```

Reason-code distribution:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK    16
POLICY_STOP_SEVERE_DTI                4
POLICY_STOP_BANKRUPTCY                3
POLICY_STOP_SEVERE_DELINQUENCY        2
```

This is an important validation result:

```text
Low requested PTI does not override severe existing-obligation DTI capacity concerns.
```

No issue.

---

## 14.16H — Multiple mixed-signal profiles

```text
Status: PASS
```

The sample is coherent.

Observed sample pattern:

```text
mixed_signal_profile_type = MULTIPLE_MIXED_SIGNALS
decision_outcome = DECLINE for all 25 sample rows
strategy_risk_tier = SEVERE_SYNTHETIC_RISK for all 25 sample rows
```

Primary reasons:

```text
POLICY_STOP_SEVERE_DELINQUENCY       10
POLICY_STOP_MAJOR_DEROGATORY          9
POLICY_STOP_BANKRUPTCY                5
POLICY_STOP_SEVERE_SYNTHETIC_RISK     1
```

This supports the Section 14 story that multiple mixed signals skew toward no-offer outcomes.

No issue.

---

## 14.16I — Borderline profiles

```text
Status: PASS
```

The sample is coherent.

Observed sample pattern:

```text
borderline_profile_flag = TRUE for all rows
score_band = DEEP_SUBPRIME for all rows
strategy_risk_tier = SEVERE_SYNTHETIC_RISK for all rows
decision_outcome = DECLINE for all rows
```

Primary reasons:

```text
POLICY_STOP_BANKRUPTCY               12
POLICY_STOP_MAJOR_DEROGATORY         10
POLICY_STOP_SEVERE_DELINQUENCY        2
POLICY_STOP_SEVERE_SYNTHETIC_RISK     1
```

This sample is severe enough that decline is expected. No issue.

---

## 14.16J — Counteroffer cases with large exposure reductions

```text
Status: PASS
```

The sample validates large reduced-exposure counteroffer behavior.

Observed sample pattern:

```text
row_count = 25
avg requested amount = 87,344.54
avg approved amount = 43,700.00
avg exposure reduction pct = 49.98%
decision_outcome = COUNTEROFFER for all rows
```

Reason-code distribution:

```text
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT       20
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT      4
COUNTEROFFER_EXPECTED_LOSS_LIMIT           1
```

This is coherent. The large-reduction sample is behaving as governed counteroffer treatment, not as uncontrolled approval.

No issue.

---

# 14.17 — Final output convention validation

```text
Status: PASS
```

This is one of the strongest Section 14 controls.

All convention violation counts are zero:

```text
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
reason_code_completeness_violation_rows = 0
reason_family_alignment_violation_rows = 0
```

This confirms all locked final-output conventions:

```text
APPROVE preserves requested exposure / PTI / Expected Loss.
COUNTEROFFER uses feasible reduced exposure.
MANUAL_REVIEW remains unresolved.
DECLINE uses zero-exposure convention.
Reason-code payloads are complete and outcome-family aligned.
```

No issue.

---

# 14.18 — Archive and comparison context

## 14.18A — Archive readiness context for current latest-run slice

```text
Status: PASS
```

The current M2-01 latest-run slice is archived:

```text
archive_table_exists = true
archive_inserted_ts_column_exists = true
latest_run_rows = 50,000
latest_run_distinct_application_id_count = 50,000
current_archived_slice_rows = 50,000
current_archived_slice_distinct_application_id_count = 50,000
current_archived_slice_null_archive_ts_rows = 0

archive_readiness_status =
CURRENT_LATEST_RUN_SLICE_ARCHIVED
```

This matches accepted Section 12.

No issue.

---

## 14.18B — Selected comparison readiness context

```text
Status: PASS / expected REVIEW
```

The selected comparison context correctly shows:

```text
comparison_group_id = CG01
comparison_set_name = Baseline vs Tighter Synthetic Risk
baseline_module2_run_id = M2-01
challenger_module2_run_id = M2-02

baseline_archived_row_count = 50,000
challenger_archived_row_count = 0
matched_application_id_count = 0

readiness_status =
NOT_READY_CHALLENGER_ARCHIVE_MISSING
```

This is expected because M2-02 is not archived yet.

This is not a blocker for M2-01 latest-run validation. It only means baseline/challenger deltas should not be interpreted yet. Section 13 is explicitly the archive-backed comparison layer and should not infer comparison results when the challenger slice is missing. fileciteturn13file26

---

## 14.18C — Matched source-field consistency context

```text
Status: PASS / expected NOT_APPLICABLE
```

Because the comparison is not ready, source consistency is correctly marked:

```text
source_consistency_status =
NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON

matched_application_count = 0
source_field_mismatch_count = 0
```

Important interpretation:

```text
This does not mean source consistency passed for a matched comparison.
It means no matched comparison exists yet.
```

No issue.

---

## 14.18D — Option C matched comparison context

```text
Status: PASS / expected NOT_APPLICABLE
```

The output shows:

```text
option_c_context_available = false
option_c_matched_row_count = 0
baseline_ordinary_counteroffer_candidate_rows = 0
challenger_ordinary_counteroffer_candidate_rows = 0
baseline_aggressive_override_rows = 0
challenger_aggressive_override_rows = 0

option_c_comparison_context_status =
OPTION_C_NOT_APPLICABLE_SECTION_13_MATCHED_ROWS_SCHEMA_NOT_AVAILABLE
```

This is acceptable for the current M2-01-only state. It does not contradict the accepted standalone latest-run facts:

```text
M2-01 ordinary_counteroffer_candidate_rows = 21,286
M2-01 aggressive_override_rows = 0
```

14.18D is evaluating matched-comparison context, not standalone latest-run Option C behavior.

One refinement candidate remains: when the selected comparison is already `NOT_READY_CHALLENGER_ARCHIVE_MISSING`, the interpretation could be clearer if the Option C matched-comparison context says comparison-not-ready first and schema-not-available second. That is narrative polish, not logic failure.

---

# 14.19 and 14.20 — Validation status summary

Section 14.19 creates `tmp_m2_validation_status_summary`, the compact validation-evidence spine consumed later by Section 16. It is expected to use only `PASS`, `REVIEW`, and `NOT_APPLICABLE` status values and does not modify latest-run, archive, or persistent evidence rows. fileciteturn13file23

## 14.20A — Full validation status summary

```text
Status: PASS
```

The full validation summary contains 22 rows:

```text
PASS = 16
REVIEW = 2
NOT_APPLICABLE = 4
```

The `PASS` rows include the core validation families:

```text
STRUCTURAL_INTEGRITY
FINAL_OUTPUT_CONVENTIONS
DECISION_DISTRIBUTION
PRODUCT_BEHAVIOR
SYNTHETIC_RISK_ORDERING
AFFORDABILITY_PTI
DTI_CAPACITY
EXPOSURE_EXPECTED_LOSS
COUNTEROFFER_VALIDATION
MANUAL_REVIEW_VALIDATION
DECLINE_POLICY_STOP_VALIDATION
REASON_CODE_COVERAGE
REASON_CODE_CONCENTRATION
OFFER_EXPOSURE_PROFILE
ARCHIVE_READINESS
Option C latest-run field preservation
```

The two `REVIEW` rows are expected and non-blocking:

```text
EDGE_CASE_VISIBILITY
MATCHED_COMPARISON_READINESS
```

The four `NOT_APPLICABLE` rows are expected for M2-01 baseline / missing challenger context:

```text
MATCHED_SOURCE_CONSISTENCY
Option C aggressive override reason-code traceability
Option C latest-run aggressive override behavior
Option C matched comparison context
```

No issue.

---

## 14.20B — Validation status rollup

```text
Status: PASS
```

Rollup:

```text
PASS              16
REVIEW             2
NOT_APPLICABLE     4
```

This is acceptable because the completion gate distinguishes core validation issues from expected context limitations.

No issue.

---

## 14.20C — Review and not-applicable validation items

```text
Status: PASS
```

The two `REVIEW` rows are correctly interpretable:

```text
EDGE_CASE_VISIBILITY
    mixed_signal_profile_rate = 35.62%
    borderline_profile_rate = 40.592%

MATCHED_COMPARISON_READINESS
    readiness_status = NOT_READY_CHALLENGER_ARCHIVE_MISSING
    matched_application_id_count = 0
    baseline_only_application_id_count = 50,000
```

Neither is a core latest-run blocker.

The `NOT_APPLICABLE` rows are also appropriate:

```text
Matched source consistency:
    comparison not ready

Aggressive override reason-code traceability:
    aggressive_override_rows = 0

Latest-run aggressive override behavior:
    active strategy is NOT_COUNTEROFFER_SPLIT_STRATEGY

Matched comparison Option C context:
    no usable Option C matched-comparison context yet
```

No issue.

---

## 14.20D — Section 14 completion status

```text
Status: PASS
```

The controlling completion row is clean:

```text
validation_status_rows = 22
pass_rows = 16
review_rows = 2
not_applicable_rows = 4
core_validation_review_rows = 0

section_14_validation_status =
SECTION_14_VALIDATION_SUMMARY_READY_FOR_EVIDENCE_CAPTURE
```

This is the correct final Section 14 status for M2-01.

---

# Final Section 14 signoff

```text
M2-01 Section 14 QA: ACCEPTED

No structural blocker.
No final-output convention blocker.
No amount convention blocker.
No PTI convention blocker.
No Expected Loss convention blocker.
No counteroffer convention blocker.
No manual-review convention blocker.
No decline convention blocker.
No reason-code coverage blocker.
No archive-readiness blocker.
No Option C latest-run preservation blocker.
Comparison readiness is correctly REVIEW because M2-02 is not yet archived.
Matched source consistency is correctly NOT_APPLICABLE because matched comparison is not ready.
Option C aggressive override diagnostics are correctly NOT_APPLICABLE for M2-01 baseline.
Section 14 validation summary is ready for Section 16 evidence capture.
```

---

# Section 14 refinement recommendations to save for cleanup

No logic changes are required. These are export-readability / narrative-clarity refinements only.

## Recommended refinements

### 1. Clarify `approved_expected_loss_rate` naming

Observed in:

```text
14.4B
14.7B
14.10B
14.20A observed_value text
```

Issue:

```text
approved_expected_loss_rate
```

appears to mean:

```text
approved Expected Loss / approved amount
```

not:

```text
approved Expected Loss / requested Expected Loss
```

Recommended cleanup:

```text
approved_expected_loss_rate → approved_el_per_approved_dollar
```

Where useful, also add:

```text
approved_expected_loss_capture_rate = approved EL / requested EL
```

This mirrors the Section 12.8.10 refinement we already accepted.

---

### 2. Standardize convention-adjusted metric notes

Observed in:

```text
14.10C
14.10D
14.14B
14.15C
```

Issue:

Some outputs include all-row approved exposure or approved Expected Loss metrics that use final-output conventions:

```text
APPROVE / COUNTEROFFER = positive approved values
MANUAL_REVIEW = NULL / unresolved
DECLINE = zero no-offer convention
```

Recommended cleanup:

Add `interpretation_note` fields explaining:

```text
All-row approved metrics use final-output conventions.
Positive-offer-only metrics isolate APPROVE and COUNTEROFFER behavior.
Manual review remains unresolved.
Decline uses zero-exposure / zero-Expected-Loss convention.
```

---

### 3. Add product-policy-relative tier notes

Relevant to:

```text
14.10C requested exposure tier × final decision outcome
14.10D requested Expected Loss tier × final decision outcome
```

Recommended note:

```text
Requested exposure and requested Expected Loss tiers are product-policy-relative; aggregate tier
averages can overlap or appear non-monotonic because product mix, LGD, requested amount, and
product-specific thresholds differ.
```

This aligns Section 14 with the tier-interpretation improvements already added to Sections 5 and 9.

---

### 4. Clarify grouped row count naming in Option C diagnostics

Observed in:

```text
14.11G
```

Issue:

```text
latest_run_rows
```

is grouped by outcome / reason-code combination, not total latest-run rows.

Recommended cleanup:

Either rename:

```text
latest_run_rows → latest_run_group_rows
```

or add an interpretation note:

```text
latest_run_rows is grouped by outcome and reason-code fields; sum across rows to obtain total
ordinary counteroffer candidate evidence.
```

This mirrors the cleanup already accepted in Sections 11 and 12.

---

### 5. Improve 14.18D / 14.20C comparison-not-ready wording

Current status:

```text
OPTION_C_NOT_APPLICABLE_SECTION_13_MATCHED_ROWS_SCHEMA_NOT_AVAILABLE
```

This is not wrong, but in the current M2-01 state the more important context is:

```text
selected comparison is not ready because M2-02 is missing
```

Recommended cleanup:

When `readiness_status = NOT_READY_CHALLENGER_ARCHIVE_MISSING`, let the interpretation say:

```text
Option C matched-comparison context is not applicable because the selected comparison is not ready.
```

Then reserve the schema-not-available message for cases where comparison context is otherwise available but the matched-row object does not expose Option C fields.

This is not urgent, but it would prevent reviewer confusion.

---

### 6. Add an edge-case visibility interpretation note

Relevant to:

```text
14.16A
14.16B
14.20C
```

Recommended note:

```text
REVIEW means mixed-signal / borderline concentration should be interpreted before documentation; it
does not mean the latest-run output failed core validation.
```

This would make the validation rollup easier to read.

---

## Optional refinements

### A. Rename typo in 14.12B file/comment label

Current filename text includes:

```text
distibution
```

Optional cleanup:

```text
distribution
```

This is cosmetic only.

---

### B. Clarify 14.16D label

Current label:

```text
weak_credit_low_requested_pti_sample
```

But the sample includes both `LOW_REQUESTED_PTI` and `MODERATE_REQUESTED_PTI`.

Optional cleanup:

```text
weak_credit_manageable_requested_pti_sample
```

or add an interpretation note clarifying that this sample is intended to show weak credit with non-severe requested PTI pressure.

---

### C. Add sample-rank fields and interpretation notes to 14.16C–14.16J

The edge-case samples are useful. For preservation, they would be even clearer if each sample output included:

```text
interpretation_note
sample_rank
```

This is optional because the current samples are already analytically readable.

---

### D. Add NaN / NULL note for zero-offer segment averages

Observed in:

```text
14.15B
```

Optional note:

```text
Offer-row averages are NULL / NaN for segments with zero simulated offer-exposure rows.
```

This would help future CSV readers.

---

# Recommended implementation order

I would patch Section 14 refinements in this order:

```text
1. Fix approved_expected_loss_rate naming / notes.
2. Add convention-adjusted metric interpretation notes.
3. Add product-policy-relative tier notes.
4. Clarify grouped row count naming in 14.11G.
5. Clarify comparison-not-ready wording in 14.18D / 14.20C.
6. Add edge-case REVIEW interpretation note.
```

Then optionally:

```text
7. Fix 14.12B typo.
8. Rename / clarify 14.16D.
9. Add sample_rank / interpretation_note to 14.16C–14.16J.
10. Add NaN / zero-offer note to 14.15B.
```

Final operational status:

```text
Section 14 is accepted now.
Refinements are not blockers.
Section 14 evidence spine is ready for Section 16.
```


<!-- END_MESSAGE C040-M01777 -->


---

<a id="c040-m01779"></a>

### C040-M01779

**Andrew** · 2026-05-18T20:04:21.492000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01779 -->
I approve: I would patch Section 14 refinements in this order:

1. Fix approved_expected_loss_rate naming / notes.
2. Add convention-adjusted metric interpretation notes.
3. Add product-policy-relative tier notes.
4. Clarify grouped row count naming in 14.11G.
5. Clarify comparison-not-ready wording in 14.18D / 14.20C.
6. Add edge-case REVIEW interpretation note.

Then optionally:

7. Fix 14.12B typo.
8. Rename / clarify 14.16D.
9. Add sample_rank / interpretation_note to 14.16C–14.16J.
10. Add NaN / zero-offer note to 14.15B.       please provide all sections that are updated as single, full section copy pastes.  current section 14 code attached.
<!-- END_MESSAGE C040-M01779 -->


**Attachments in export:** `Pasted text(222).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01802"></a>

### C040-M01802

**ChatGPT** · 2026-05-18T20:18:39.021030-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01802 -->
Done — I packaged the approved Section 14 refinement replacements into one full copy-paste SQL file.

The attached replacement file includes full updated sections for:

```text
14.4B
14.7B
14.10B
14.10C
14.10D
14.11G
14.12B
14.14B
14.15B
14.15C
14.16A
14.16B
14.16C
14.16D
14.16E
14.16F
14.16G
14.16H
14.16I
14.16J
14.18D
14.19
14.20C
```

These refinements preserve Section 14’s read-only validation boundary and keep `tmp_m2_validation_status_summary` as the compact validation-evidence spine consumed by Section 16. fileciteturn13file0turn13file23turn13file24

[Download the full Section 14 refinement replacement sections](sandbox:/mnt/data/section14_refinement_replacement_sections.sql)

Implementation notes:

```text
1. Replace each matching section in your current Section 14 with the corresponding block in the file.
2. 14.19 is included as a full replacement because several downstream validation summary rows depend on its wording and metric names.
3. These are QA/export-readability refinements only.
4. They do not change latest-run materialization, archive persistence, decision logic, approved exposure, approved PTI, approved Expected Loss, or reason-code assignment.
```

The main changes are:

```text
approved_expected_loss_rate
    replaced / clarified as:
        approved_expected_loss_capture_rate
        approved_el_per_approved_dollar

all-row approved metrics
    now include interpretation notes for final-output conventions

requested exposure / requested EL tier outputs
    now include product-policy-relative interpretation notes

14.11G
    latest_run_rows clarified as latest_run_group_rows

14.18D / 14.20C
    comparison-not-ready wording clarified for the M2-01-only state

14.16A / 14.16B / 14.20C
    REVIEW status clarified as documentation-readiness context, not a core validation failure

14.16C–14.16J
    sample_rank and interpretation_note added

14.12B
    “distribution” spelling cleaned up

14.16D
    renamed / clarified as weak credit with manageable requested PTI

14.15B
    NULL / NaN offer-row average behavior clarified for zero-offer segments
```
<!-- END_MESSAGE C040-M01802 -->


---

<a id="c040-m01803"></a>

### C040-M01803

**Andrew** · 2026-05-18T21:43:27.947000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01803 -->
please review updated, refined section 14 QA from 14.4B thru 14.16J.  Will deliver remaining refined QA updates in next prompt
<!-- END_MESSAGE C040-M01803 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16H_QA_multiple_mixed_signal_profiles(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16G_QA_high_dti_low_requested_pti_sample(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16F_QA_high_synthetic_risk_low_exposure_sample(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16E_QA_large_exposure_low_synthetic_risk_sample(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16D_QA_weak_credit_low_requested_pti_sample(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16C_QA_strong_credit_high_requested_pti_sample(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16B_QA_borderline_profile_distribution(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16A_QA_mixed_signal_profile_distribution(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.15C_QA_offer_exposure_reason_code_profile(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.15B_QA_product_x_score_composition_of_simulated_offer_exposure_rows(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.14B_QA_primary_reason_code_distribution(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12B_QA_manual_review_path_and_primary_reason_code_distibution(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11G_QA_option_c_counteroffer_strategy_split_validation_diagnostics(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10D_QA_requested_expected_loss_tier_x_final_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10C_QA_requested_exposure_tier_x_final_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10B_QA_requested_versus_approved_expected_loss_by_final_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.7B_QA_synthetic_risk_tier_compact_summary(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.4B_QA_product_level_decision_rate_summary(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16J_QA_counteroffer_cases_with_large_exposure_reductions(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16I_QA_borderline_profiles(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01815"></a>

### C040-M01815

**ChatGPT** · 2026-05-18T21:51:15.338984-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01815 -->
## Refined Section 14 QA review — 14.4B through 14.16J

```text
Review status: MOSTLY PASS
Accepted outputs: 14.4B, 14.7B, 14.10B, 14.10C, 14.10D, 14.11G, 14.12B,
                  14.14B, 14.15B, 14.15C, 14.16A, 14.16B,
                  14.16C, 14.16D, 14.16E, 14.16F, 14.16G,
                  14.16I, 14.16J

Needs correction: 14.16H

Core latest-run logic issue: none
QA/export issue: 14.16H appears to duplicate 14.16G
Section 14 final signoff: not yet, pending 14.16H correction and remaining refined QA batch
```

Section 14 remains correctly scoped as the read-only validation framework for the completed latest-run output, including product, score, risk, PTI, DTI, exposure, Expected Loss, counteroffer, manual-review, decline, reason-code, mixed-signal, borderline, archive-readiness, comparison-readiness, and Option C context diagnostics. fileciteturn13file23

---

# Accepted refined outputs

## 14.4B — Product-level decision rate summary

```text
Status: PASS
```

The `approved_expected_loss_rate` ambiguity is fixed.

The output now cleanly separates:

```text
approved_expected_loss_capture_rate = approved EL / requested EL
approved_el_per_approved_dollar = approved EL / approved amount
```

Product counts reconcile to 50,000:

```text
AUTO_LOAN                   9,946
HELOC                       4,962
MORTGAGE                   15,065
REVOLVING_LINE             12,455
UNSECURED_PERSONAL_LOAN     7,572
```

No alias truncation. No further change recommended.

---

## 14.7B — Synthetic risk tier compact summary

```text
Status: PASS
```

The Expected Loss metric naming is fixed here as well:

```text
approved_expected_loss_capture_rate
approved_el_per_approved_dollar
```

Risk-tier applications reconcile to 50,000:

```text
LOW_SYNTHETIC_RISK          17,122
MODERATE_SYNTHETIC_RISK      6,813
ELEVATED_SYNTHETIC_RISK      8,683
HIGH_SYNTHETIC_RISK          6,412
SEVERE_SYNTHETIC_RISK       10,970
```

The severe-risk row correctly shows:

```text
simulated_offer_exposure_rate = 0
total_approved_amount = 0
approved_el_per_approved_dollar = NULL / NaN
```

That is expected because there is no approved exposure in the severe-risk tier.

No further change recommended.

---

## 14.10B — Requested versus approved Expected Loss by final decision outcome

```text
Status: PASS
```

The refined output is strong. It now has the right interpretation note and clean convention counts.

Expected Loss conventions are exact:

```text
APPROVE
    row_count = 10,695
    positive_approved_expected_loss_rows = 10,695
    approved_expected_loss_capture_rate = 1.000000
    convention violations = 0

COUNTEROFFER
    row_count = 19,067
    positive_approved_expected_loss_rows = 19,067
    approved_expected_loss_capture_rate = 0.758973
    approved_el_per_approved_dollar = 0.019279
    convention violations = 0

MANUAL_REVIEW
    row_count = 7,535
    null_approved_expected_loss_rows = 7,535
    convention violations = 0

DECLINE
    row_count = 12,703
    zero_approved_expected_loss_rows = 12,703
    convention violations = 0
```

No further change recommended.

---

## 14.10C — Requested exposure tier × final decision outcome

```text
Status: PASS
```

The product-policy-relative interpretation note is present and useful.

Row counts reconcile to 50,000:

```text
LOW_REQUESTED_EXPOSURE          20,582
WITHIN_PRODUCT_APPROVAL_CAP     16,790
ABOVE_PRODUCT_APPROVAL_CAP      12,628
```

The key strategy behavior remains clean:

```text
ABOVE_PRODUCT_APPROVAL_CAP / APPROVE = 0
```

All-row and positive-offer metrics are now more understandable because the note explains the final-output convention.

No further change recommended.

---

## 14.10D — Requested Expected Loss tier × final decision outcome

```text
Status: PASS
```

The requested Expected Loss tier interpretation note is present and appropriate.

Tier counts reconcile to 50,000:

```text
LOW_REQUESTED_EL          26,158
MODERATE_REQUESTED_EL      8,409
ELEVATED_REQUESTED_EL      7,891
HIGH_REQUESTED_EL          5,553
SEVERE_REQUESTED_EL        1,989
```

The outcome behavior remains coherent:

```text
HIGH_REQUESTED_EL / APPROVE = 0
HIGH_REQUESTED_EL / COUNTEROFFER = 0

SEVERE_REQUESTED_EL / APPROVE = 0
SEVERE_REQUESTED_EL / COUNTEROFFER = 0
```

No further change recommended.

---

## 14.11G — Option C counteroffer strategy split validation diagnostics

```text
Status: PASS
```

The grouped-row naming cleanup worked:

```text
latest_run_group_rows
```

replaces the prior ambiguous `latest_run_rows`.

The grouped rows reconcile to 50,000:

```text
sum(latest_run_group_rows) = 50,000
```

Ordinary counteroffer evidence reconciles:

```text
final COUNTEROFFER ordinary rows = 19,067
failed counteroffer → MANUAL_REVIEW ordinary rows = 2,219

total ordinary_counteroffer_candidate_rows = 21,286
```

M2-01 baseline Option C posture is correct:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive_override_rows = 0
```

No further change recommended.

---

## 14.12B — Manual review path and primary reason-code distribution

```text
Status: PASS
```

The content is clean:

```text
row_count sum = 7,535
```

Manual-review reason-code distribution remains correct:

```text
MANUAL_REVIEW_FAILED_COUNTEROFFER        2,219
MANUAL_REVIEW_BORDERLINE_PROFILE         1,926
MANUAL_REVIEW_SYNTHETIC_RISK_REVIEW      1,790
MANUAL_REVIEW_DTI_REVIEW                 1,600
```

The interpretation note is helpful.

One tiny residual item: the exported filename still says:

```text
distibution
```

rather than:

```text
distribution
```

That is not a SQL logic issue. It may just be the saved CSV filename / DBeaver export label. The output itself is acceptable.

---

## 14.14B — Primary reason-code distribution

```text
Status: PASS
```

The convention-adjusted metric note is present and useful.

Rows reconcile:

```text
row_count sum = 50,000
primary reason codes = 14
```

Reason-code family totals remain correct:

```text
APPROVAL         10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
POLICY_STOP      12,703
```

No further change recommended.

---

## 14.15B — Product × score composition of simulated offer exposure rows

```text
Status: PASS
```

The NULL / NaN interpretation note is present:

```text
Offer-row averages are NULL / NaN for segments with zero simulated offer-exposure rows.
```

That fixed the prior readability issue.

Offer exposure reconciles:

```text
sum(simulated_offer_exposure_rows) = 29,762
```

Deep-subprime zero-offer cells now read correctly because NULL / NaN offer-row averages are explicitly explained.

No further change recommended.

---

## 14.15C — Offer exposure reason-code profile

```text
Status: PASS
```

The convention-adjusted metric note is present.

Rows reconcile:

```text
row_count sum = 50,000
```

Offer side:

```text
APPROVED_AS_REQUESTED                         10,695
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT            8,905
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT          5,021
COUNTEROFFER_ELEVATED_SYNTHETIC_RISK           3,853
COUNTEROFFER_EXPECTED_LOSS_LIMIT               1,288

total offer rows = 29,762
```

No-offer side remains:

```text
MANUAL_REVIEW + POLICY_STOP rows = 20,238
```

No further change recommended.

---

## 14.16A — Mixed-signal profile distribution

```text
Status: PASS
```

The REVIEW interpretation note is now doing exactly what we wanted:

```text
Mixed-signal REVIEW means concentration should be interpreted before documentation;
it is not a core validation failure by itself.
```

Rows reconcile:

```text
row_count sum = 50,000
```

Distribution remains coherent:

```text
NO_MIXED_SIGNAL_PROFILE          32,190
WEAK_CREDIT_LOW_PTI               8,426
LARGE_EXPOSURE_LOW_RISK           6,711
MULTIPLE_MIXED_SIGNALS            1,745
STRONG_CREDIT_HIGH_PTI              539
HIGH_DTI_LOW_REQUESTED_PTI          266
HIGH_RISK_LOW_EXPOSURE              123
```

No further change recommended.

---

## 14.16B — Borderline profile distribution

```text
Status: PASS
```

The REVIEW interpretation note is clear:

```text
Borderline-profile REVIEW means threshold-adjacent concentration should be interpreted before documentation;
it is not a core validation failure by itself.
```

Rows reconcile:

```text
TRUE     20,296
FALSE    29,704
total    50,000
```

No further change recommended.

---

# Edge-case samples

## 14.16C — Strong credit / high requested PTI sample

```text
Status: PASS
```

The sample-rank and interpretation-note refinements worked.

Sample behavior:

```text
sample rows = 25
COUNTEROFFER = 24
DECLINE = 1
```

Reason-code mix:

```text
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT      13
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT        11
POLICY_STOP_MAJOR_DEROGATORY                1
```

This is coherent: strong credit with high requested PTI mostly resolves through counteroffer rather than automatic approval.

---

## 14.16D — Weak credit / manageable requested PTI sample

```text
Status: PASS
```

The new interpretation note fixed the earlier label issue:

```text
Weak credit with manageable requested PTI validates that low PTI does not override severe synthetic-risk or policy-stop logic.
```

Sample behavior:

```text
DECLINE = 25
strategy_risk_tier = SEVERE_SYNTHETIC_RISK
```

Reason-code mix:

```text
POLICY_STOP_SEVERE_SYNTHETIC_RISK      11
POLICY_STOP_SEVERE_DELINQUENCY         10
POLICY_STOP_BANKRUPTCY                  3
POLICY_STOP_MAJOR_DEROGATORY            1
```

The exported filename still says `weak_credit_low_requested_pti_sample`, but the output content now correctly clarifies “manageable requested PTI.” That is acceptable unless you want the filename/comment label changed too.

---

## 14.16E — Large exposure / low synthetic risk sample

```text
Status: PASS
```

Sample behavior:

```text
sample rows = 25
decision_outcome = COUNTEROFFER for all rows
requested_exposure_tier = ABOVE_PRODUCT_APPROVAL_CAP
strategy_risk_tier = LOW_SYNTHETIC_RISK
primary_reason_code = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT for all rows
```

This validates that low risk does not override exposure guardrails. No further change recommended.

---

## 14.16F — High synthetic risk / low exposure sample

```text
Status: PASS
```

Sample behavior:

```text
sample rows = 25
decision_outcome = DECLINE for all rows
strategy_risk_tier = SEVERE_SYNTHETIC_RISK
requested_exposure_tier = LOW_REQUESTED_EXPOSURE
```

This validates that small requested amount does not override severe synthetic risk / policy-stop logic.

No further change recommended.

---

## 14.16G — High DTI / low requested PTI sample

```text
Status: PASS
```

Sample behavior:

```text
sample rows = 25
decision_outcome = DECLINE for all rows
dti_bucket = SEVERE_DTI
requested_pti_bucket = LOW_REQUESTED_PTI
```

This validates that existing-obligation DTI pressure and requested-structure PTI can move differently.

No further change recommended.

---

## 14.16H — Multiple mixed-signal profiles

```text
Status: REVIEW / NEEDS CORRECTION
```

This output appears to be wrong.

The file name says:

```text
14.16H_QA_multiple_mixed_signal_profiles
```

but the exported columns and rows match **14.16G high DTI / low requested PTI**:

```text
interpretation_note =
High DTI with low requested PTI validates that existing-obligation capacity and requested-structure affordability can move differently.

columns include:
    debt_to_income_ratio
    requested_payment_to_income_ratio
    dti_bucket
    requested_pti_bucket

rows:
    same high-DTI / low-requested-PTI pattern as 14.16G
```

Expected 14.16H should show:

```text
multiple mixed-signal profile rows
likely mixed_signal_profile_type = MULTIPLE_MIXED_SIGNALS
and an interpretation note about multiple mixed-signal profiles
```

This is not a model-output defect. It is a QA query/export defect, likely a copy-paste issue in the refined 14.16H block.

Recommended action:

```text
Do not accept 14.16H yet.
Patch / rerun / re-export 14.16H so it samples MULTIPLE_MIXED_SIGNALS rows.
```

---

## 14.16I — Borderline profiles

```text
Status: PASS
```

Sample behavior:

```text
sample rows = 25
borderline_profile_flag = true for all rows
decision_outcome = DECLINE for all rows
strategy_risk_tier = SEVERE_SYNTHETIC_RISK
```

Reason-code mix:

```text
POLICY_STOP_BANKRUPTCY                 12
POLICY_STOP_MAJOR_DEROGATORY           10
POLICY_STOP_SEVERE_DELINQUENCY          2
POLICY_STOP_SEVERE_SYNTHETIC_RISK       1
```

The interpretation note is useful and correct.

No further change recommended.

---

## 14.16J — Counteroffer cases with large exposure reductions

```text
Status: PASS, with one optional readability note
```

Sample behavior is coherent:

```text
sample rows = 25
primary reason families are counteroffer-coded
exposure_reduction_pct = 0.50 in the top sample rows
approved_amount = counteroffer_amount
approved_expected_loss_amount < requested_expected_loss_amount
```

Reason-code mix:

```text
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT        20
COUNTEROFFER_AFFORDABILITY_ADJUSTMENT       4
COUNTEROFFER_EXPECTED_LOSS_LIMIT            1
```

Optional readability note: the refined output no longer includes `decision_outcome`. Since this is explicitly a final counteroffer sample, the query presumably filters to `decision_outcome = 'COUNTEROFFER'`, but preserving `decision_outcome` in the SELECT would make the CSV self-validating.

This is optional. It is not a blocker because the fields and reason codes clearly show feasible counteroffer behavior.

---

# Batch-level conclusion

```text
Refined Section 14 QA, 14.4B through 14.16J:

Accepted:
    14.4B
    14.7B
    14.10B
    14.10C
    14.10D
    14.11G
    14.12B
    14.14B
    14.15B
    14.15C
    14.16A
    14.16B
    14.16C
    14.16D
    14.16E
    14.16F
    14.16G
    14.16I
    14.16J

Needs correction:
    14.16H

Core validation impact:
    No core M2-01 latest-run logic issue found.
    14.16H is a QA/export implementation issue only.
```

## Recommended next action

Before final Section 14 refined QA signoff, rerun corrected 14.16H.

The corrected 14.16H should return a sample of:

```text
mixed_signal_profile_type = MULTIPLE_MIXED_SIGNALS
```

with a note such as:

```text
Multiple mixed-signal rows should be reviewed as overlapping edge-case profiles; their existence is expected and should be interpreted, not treated as a core validation failure.
```

Everything else in this refined batch is accepted.
<!-- END_MESSAGE C040-M01815 -->


---

<a id="c040-m01816"></a>

### C040-M01816

**Andrew** · 2026-05-18T21:55:30.736000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01816 -->
review final refined section 14 QA, including corrected 14.16H.
<!-- END_MESSAGE C040-M01816 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.20C_QA_review_and_not_applicable_validation_items(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.18D_QA_option_c_matched_comparison_context(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.16H_QA_multiple_mixed_signal_profiles(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01822"></a>

### C040-M01822

**ChatGPT** · 2026-05-18T22:01:13.582607-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01822 -->
## Final refined Section 14 QA review verdict

```text
Final refined Section 14 QA status: ALMOST ACCEPTED
Corrected 14.16H status: PASS
14.20C refined validation-status context: PASS
14.18D uploaded refined export: REVIEW / wrong export attached
Core latest-run validation issue: none
SQL logic issue found: none confirmed
Remaining action: re-export 14.18D Option C matched-comparison context
```

Section 14 remains correctly scoped as the read-only validation framework for the completed latest-run output, and it creates the compact validation-evidence spine consumed by Section 16. fileciteturn13file23turn13file24

The corrected **14.16H** is now clean. The only remaining issue is that the uploaded **14.18D** file does not appear to be the Option C matched-comparison context output; it appears to be a duplicate/mis-export of the large exposure-reduction counteroffer sample.

---

# 14.16H — Multiple mixed-signal profiles

```text
Status: PASS
Correction accepted: yes
```

The corrected 14.16H now returns the expected sample:

```text
row_count = 25
mixed_signal_profile_type = MULTIPLE_MIXED_SIGNALS for all 25 rows
mixed_signal_condition_count = 3 for all 25 rows
```

The sample is no longer duplicating the high-DTI / low-requested-PTI diagnostic.

Observed sample profile:

```text
decision_outcome = DECLINE for all 25 rows
strategy_risk_tier = SEVERE_SYNTHETIC_RISK for all 25 rows
score_band_policy_key = DEEP_SUBPRIME for all 25 rows
dti_bucket = SEVERE_DTI for all 25 rows
requested_exposure_tier = LOW_REQUESTED_EXPOSURE for all 25 rows
```

Primary reason-code distribution:

```text
POLICY_STOP_SEVERE_DELINQUENCY         10
POLICY_STOP_MAJOR_DEROGATORY            9
POLICY_STOP_BANKRUPTCY                  5
POLICY_STOP_SEVERE_SYNTHETIC_RISK       1
```

This is now exactly the intended edge-case sample. It validates that multiple mixed-signal profiles are explainable through overlapping severe-risk, DTI, requested-structure, exposure, and Expected Loss signals.

The `sample_rank` field is present and clean:

```text
sample_rank min = 1
sample_rank max = 25
sample_rank unique = true
```

No further change recommended for 14.16H.

---

# 14.18D — Option C matched comparison context

```text
Status: REVIEW / wrong uploaded export
```

The uploaded file named:

```text
14.18D_QA_option_c_matched_comparison_context(1).csv
```

does **not** contain the Option C matched-comparison context fields.

Instead, it contains columns and rows from the large exposure-reduction counteroffer sample:

```text
interpretation_note =
Large exposure-reduction counteroffers should be feasible reduced-exposure outcomes, not uncontrolled approvals.

sample_rank
application_id
product_type_policy_key
requested_amount
approved_amount
counteroffer_amount
exposure_reduction_pct
requested_payment_to_income_ratio
approved_payment_to_income_ratio
requested_expected_loss_amount
approved_expected_loss_amount
primary_reason_code
```

That is the 14.16J-style output, not the expected 14.18D output.

Expected 14.18D should contain fields like:

```text
option_c_context_available
option_c_matched_row_count
baseline_counteroffer_strategy_variant
challenger_counteroffer_strategy_variant
baseline_ordinary_counteroffer_candidate_rows
challenger_ordinary_counteroffer_candidate_rows
baseline_aggressive_override_rows
challenger_aggressive_override_rows
option_c_comparison_context_status
```

For the current M2-01 state, the expected result should still be comparison-not-ready / not-applicable because M2-02 is not archived yet. But I cannot accept the attached 14.18D refined export because it is not the 14.18D query result.

This looks like an export mix-up, not a SQL logic failure.

Recommended action:

```text
Rerun / re-export 14.18D only.
Attach the corrected 14.18D CSV.
```

---

# 14.20C — Review and not-applicable validation items

```text
Status: PASS
```

The refined 14.20C output is strong and now carries the context notes we wanted.

It returns:

```text
rows = 6
REVIEW = 2
NOT_APPLICABLE = 4
```

The two `REVIEW` rows are expected and non-blocking:

```text
EDGE_CASE_VISIBILITY
MATCHED_COMPARISON_READINESS
```

The refined edge-case note is clear:

```text
REVIEW means mixed-signal / borderline concentration should be interpreted before documentation;
it is not a final-output convention failure.
```

The comparison-readiness note is also clear:

```text
Comparison context depends on Section 13 readiness; if the challenger archive slice is missing,
this is expected for M2-01 and not a latest-run validation blocker.
```

The four `NOT_APPLICABLE` rows are appropriate:

```text
MATCHED_SOURCE_CONSISTENCY
Option C aggressive override reason-code traceability
Option C latest-run aggressive override behavior
Option C matched comparison Option C context
```

The Option C matched-comparison interpretation is now much clearer:

```text
Option C matched-comparison context is not applicable because the selected Section 13 comparison
is not ready. Archive the challenger slice and rerun Section 13 before interpreting matched Option C movement.
```

This is exactly the clarification we wanted for M2-01, where CG01 is not ready because M2-02 is missing.

No further change recommended for 14.20C.

---

# Final refined Section 14 status

```text
Accepted:
    14.16H corrected multiple mixed-signal sample
    14.20C refined REVIEW / NOT_APPLICABLE explanation

Needs re-export:
    14.18D Option C matched comparison context

Core Section 14 validation:
    Still accepted

Remaining issue type:
    QA export attachment mismatch, not latest-run logic
```

## Operational signoff

```text
M2-01 Section 14 refined QA: ACCEPTED EXCEPT FOR 14.18D RE-EXPORT

No core validation blocker.
No final-output convention issue.
No reason-code coverage issue.
No edge-case diagnostic issue after corrected 14.16H.
No Section 14.20C validation-status interpretation issue.
Only remaining item: re-export 14.18D because the attached file is not the 14.18D output.
```

Once corrected 14.18D is attached and shows the expected comparison-not-ready / Option C not-applicable context, Section 14 refined QA can be fully signed off.
<!-- END_MESSAGE C040-M01822 -->


---

<a id="c040-m01823"></a>

### C040-M01823

**Andrew** · 2026-05-18T22:06:02.636000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01823 -->
review 14.18D corrected
<!-- END_MESSAGE C040-M01823 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.18D_QA_option_c_matched_comparison_context(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01824"></a>

### C040-M01824

**ChatGPT** · 2026-05-18T22:07:53.367937-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01824 -->
## Corrected 14.18D review verdict

```text
14.18D corrected QA status: PASS
Prior export issue: resolved
Core Section 14 validation issue: none
Remaining Section 14 blocker: none
Final refined Section 14 QA status: ACCEPTED
```

The corrected 14.18D output is now the right query result. It is no longer the mistaken large exposure-reduction counteroffer sample.

Section 14’s purpose is to validate the completed latest-run output, preserve a read-only QA boundary, and materialize the validation-evidence spine consumed later by Section 16. The corrected 14.18D now fits that boundary: it summarizes matched-comparison Option C context without modifying latest-run, archive, comparison, or evidence rows. fileciteturn13file0

---

## 14.18D — Option C matched comparison context

```text
Status: PASS
Rows: 1
```

The current output correctly reflects the M2-01-only campaign state:

```text
selected_comparison_readiness_status =
NOT_READY_CHALLENGER_ARCHIVE_MISSING

option_c_context_available =
false

option_c_matched_row_count =
0
```

This is exactly expected because:

```text
M2-01 baseline archive exists.
M2-02 challenger archive does not yet exist.
CG01 matched comparison is not ready.
```

The Option C matched-comparison fields are therefore correctly zero or NULL / NaN:

```text
baseline_ordinary_counteroffer_candidate_rows = 0
challenger_ordinary_counteroffer_candidate_rows = 0
baseline_aggressive_override_rows = 0
challenger_aggressive_override_rows = 0
challenger_new_aggressive_override_rows = 0
challenger_aggressive_override_final_counteroffer_rows = 0
challenger_aggressive_override_final_manual_review_rows = 0
challenger_aggressive_override_final_decline_rows = 0
```

These zeros do **not** contradict the accepted standalone M2-01 latest-run facts:

```text
M2-01 ordinary_counteroffer_candidate_rows = 21,286
M2-01 aggressive_override_rows = 0
```

14.18D is a **matched-comparison context** output, not a standalone latest-run Option C diagnostic.

---

## Status wording check

The refined wording now works well.

The interpretation note says:

```text
Option C matched-comparison context is not applicable because the selected Section 13 comparison is not ready; archive the challenger slice and rerun Section 13 before interpreting matched Option C movement.
```

The final interpreted status is also clear:

```text
interpreted_option_c_comparison_context_status =
OPTION_C_NOT_APPLICABLE_COMPARISON_NOT_READY
```

The lower-level raw status still says:

```text
option_c_comparison_context_status =
OPTION_C_NOT_APPLICABLE_SECTION_13_MATCHED_ROWS_SCHEMA_NOT_AVAILABLE
```

That is acceptable because the new interpreted status and interpretation note clarify the business meaning. For documentation and validation-summary narrative, use:

```text
OPTION_C_NOT_APPLICABLE_COMPARISON_NOT_READY
```

rather than the lower-level schema-oriented status.

---

# Final Section 14 refined QA signoff

```text
M2-01 Section 14 refined QA: ACCEPTED

14.16H corrected: PASS
14.18D corrected: PASS
14.20C refined context: PASS

No structural blocker.
No final-output convention blocker.
No amount / PTI / Expected Loss convention blocker.
No counteroffer convention blocker.
No manual-review convention blocker.
No decline convention blocker.
No reason-code coverage blocker.
No archive-readiness blocker.
No Option C latest-run preservation blocker.
No matched-comparison-context blocker.

Comparison readiness remains REVIEW / NOT_APPLICABLE only because M2-02 is not archived yet.
This is expected and not a latest-run validation failure.
```

Section 14 is ready for downstream evidence capture.
<!-- END_MESSAGE C040-M01824 -->


---

<a id="c040-m01826"></a>

### C040-M01826

**Andrew** · 2026-05-18T22:21:57.245000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01826 -->
review section 15 QA:
<!-- END_MESSAGE C040-M01826 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8C_QA_frontier_reason_code_storytelling_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8B_QA_frontier_baseline_availability_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8A_QA_frontier_object_row_count_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.6A_QA_segment_level_frontier_highlights_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.5A_QA_strategy_frontier_classification_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.4A_QA_strategy_efficiency_metrics_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.3A_QA_baseline_relative_frontier_delta_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.2A_QA_core_strategy_frontier_summary_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.1A_QA_archive_frontier_inventory_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0A.2_QA_campaign_registry_map_review_output.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0_QA_frontier_scope_and_archive_readiness_snapshot(3).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01836"></a>

### C040-M01836

**ChatGPT** · 2026-05-18T22:30:33.001975-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01836 -->
## Section 15 QA review verdict

```text
Section 15 QA status: PASS FOR CURRENT M2-01 STATE
M2-01 archive status: VALID
Archived frontier slice count: 1
Frontier interpretation: INVENTORY-ONLY / BASELINE REFERENCE POINT
True blockers: none
Expected limitation: no meaningful challenger frontier yet because only M2-01 is archived
Ready for Section 16 current-run evidence capture: yes
```

Section 15 is the archive-wide strategy frontier control tower. It summarizes completed archived strategy slices and is designed to show tradeoffs across offer exposure, approved amount, approved Expected Loss, affordability, synthetic estimated-risk profile, counteroffer behavior, manual-review burden, decline rate, product/score behavior, reason-code movement, and Option C ordinary/aggressive counteroffer path behavior. With only M2-01 archived, Section 15 should produce a valid baseline reference point, but it should not yet produce a meaningful multi-strategy frontier. fileciteturn13file21

---

# 15.0 — Frontier scope and archive readiness snapshot

```text
Status: PASS
```

The frontier scope is exactly what we expect for the current campaign state:

```text
archived_rows = 50,000
distinct_archived_application_ids = 50,000
archived_strategy_scenario_slice_count = 1
module1_scenario_population_slice_count = 1
module2_strategy_version_count = 1

frontier_scope_status =
FRONTIER_INVENTORY_ONLY_SINGLE_ARCHIVED_SLICE
```

This is not a blocker. It correctly says the archive contains one valid completed slice, not a completed campaign frontier.

Interpretation:

```text
M2-01 is valid.
Section 15 is currently limited to inventory-only / baseline-reference frontier context.
Full frontier interpretation requires additional archived strategies.
```

---

# 15.0A.2 — Campaign registry map review output

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

Strategy mix in the formal campaign registry is coherent:

```text
BASELINE_STRATEGY                              19
PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY             5
TIGHTER_AFFORDABILITY_STRATEGY                  3
TIGHTER_SYNTHETIC_RISK_STRATEGY                 3
AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY      3
SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY     3
GROWTH_ORIENTED_STRATEGY                        2
MANUAL_REVIEW_REDUCTION_STRATEGY                1
```

Important interpretation:

```text
This confirms the 39-run campaign registry is mapped and ready.
It does not mean all 39 runs are archived yet.
```

No issue.

---

# 15.1A — Archive frontier inventory review output

```text
Status: PASS
```

The archive inventory contains the expected M2-01 baseline slice:

```text
strategy_name = BASELINE_STRATEGY
module1_scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1

archived_row_count = 50,000
distinct_application_id_count = 50,000
duplicate_application_row_count = 0
```

Decision counts match accepted M2-01 output:

```text
approval_count = 10,695
counteroffer_count = 19,067
manual_review_count = 7,535
decline_count = 12,703
simulated_offer_exposure_count = 29,762
```

No issue.

---

# 15.2A — Core strategy frontier summary

```text
Status: PASS
```

The core frontier row is internally consistent.

Core counts and rates:

```text
applications = 50,000

approval_rate = 0.213900
counteroffer_rate = 0.381340
manual_review_rate = 0.150700
decline_rate = 0.254060
simulated_offer_exposure_rate = 0.595240
```

Offer composition:

```text
approval_share_of_offers = 0.359351
counteroffer_share_of_offers = 0.640649
```

Exposure / Expected Loss metrics:

```text
total_requested_amount = 6.666B
total_approved_amount = 3.827B
avg_approved_amount_offer_rows = 128,596.13

total_requested_expected_loss_amount = 239.433M
total_approved_expected_loss_amount = 58.552M
avg_approved_expected_loss_offer_rows = 1,967.33
```

Risk and affordability:

```text
avg_synthetic_estimated_pd_proxy_all_apps = 0.163366
avg_synthetic_estimated_pd_proxy_offer_rows = 0.064969
avg_synthetic_estimated_pd_proxy_declined_rows = 0.398304

avg_approved_payment_to_income_ratio_offer_rows = 0.122971
```

Option C baseline posture is correct:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
```

Reason-code story is coherent:

```text
top primary reason = APPROVED_AS_REQUESTED
top non-approval reason = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
top policy-stop reason = POLICY_STOP_SEVERE_SYNTHETIC_RISK
```

No issue.

---

# 15.3A — Baseline-relative frontier delta review

```text
Status: PASS
```

This output behaves correctly for a baseline self-reference row.

Baseline availability:

```text
baseline_available_flag = true
baseline_strategy_name = BASELINE_STRATEGY
baseline_applications = 50,000
```

All baseline-relative deltas are zero, as expected:

```text
delta_approval_rate = 0
delta_counteroffer_rate = 0
delta_manual_review_rate = 0
delta_decline_rate = 0
delta_simulated_offer_exposure_rate = 0
delta_total_approved_amount = 0
delta_total_approved_expected_loss_amount = 0
delta_approved_expected_loss_rate = 0
delta_ordinary_counteroffer_candidate_rate = 0
delta_aggressive_override_rate = 0
```

The reason-code delta driver fields are NULL / NaN, which is correct for the baseline reference point:

```text
top_reason_code_delta_driver_code = NULL
top_reason_code_delta_population_share = NULL
```

No issue.

---

# 15.4A — Strategy efficiency metrics

```text
Status: PASS
```

Efficiency metrics are available:

```text
frontier_efficiency_metric_status =
FRONTIER_EFFICIENCY_METRICS_AVAILABLE
```

The baseline row shows:

```text
positive_offer_access_rate = 0.595240
manual_review_burden_rate = 0.150700
no_offer_outcome_rate = 0.254060

frontier_approved_expected_loss_rate = 0.015299
approved_amount_per_approved_expected_loss_dollar = 65.365799
offer_rate_per_approved_expected_loss_rate_unit = 38.908338
applications_per_million_approved_expected_loss = 853.946284
```

Interpretation:

```text
These metrics are valid for M2-01.
They are not yet comparative frontier rankings because only one archived strategy slice exists.
```

No issue.

---

# 15.5A — Strategy frontier classification

```text
Status: PASS
```

The classification is correct:

```text
frontier_position_type =
BASELINE_REFERENCE_POINT

frontier_interpretation_note =
Reference point for same Module 1 scenario / population / strategy set.

executive_frontier_quadrant =
BASELINE_REFERENCE_QUADRANT
```

Option C posture is also correct:

```text
option_c_frontier_posture_type =
OPTION_C_NOT_APPLICABLE_FRONTIER_POINT

option_c_frontier_interpretation_note =
This archived strategy slice is not part of the Option C counteroffer split.
```

This is exactly the expected classification for M2-01 baseline.

No issue.

---

# 15.6A — Segment-level frontier highlights

```text
Status: PASS
```

The segment table is coherent:

```text
row_count = 35

PRODUCT rows = 5
SCORE_BAND rows = 5
PRODUCT_X_SCORE rows = 25
```

Each segment level reconciles independently to 50,000 rows:

```text
PRODUCT applications sum = 50,000
SCORE_BAND applications sum = 50,000
PRODUCT_X_SCORE applications sum = 50,000
```

That is correct. The total across all segment levels is not supposed to sum to 50,000 because the table contains three different grains.

Key segment behavior is directionally strong:

```text
SUPER_PRIME simulated_offer_exposure_rate = 0.924755
PRIME simulated_offer_exposure_rate = 0.795453
NEAR_PRIME simulated_offer_exposure_rate = 0.774207
SUBPRIME simulated_offer_exposure_rate = 0.110088
DEEP_SUBPRIME simulated_offer_exposure_rate = 0.000165
```

Product behavior is also coherent:

```text
AUTO_LOAN has the highest approval rate among product-level rows.
REVOLVING_LINE has the highest counteroffer rate among product-level rows.
MORTGAGE and HELOC show heavier approved-dollar / secured-exposure behavior.
UNSECURED and REVOLVING carry higher approved Expected Loss density.
```

Deep-subprime product × score cells show `NaN` approved Expected Loss rate where no offer rows exist. That is expected.

No issue.

---

# 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
```

This is the key Section 15 output for Section 16 current-run evidence capture, and it is clean.

Registry linkage:

```text
frontier_registry_match_status = FRONTIER_REGISTRY_MATCHED
frontier_registry_match_count = 1

module1_run_id = M1-01
module2_run_id = M2-01
run_sequence_number = 1
showcase_id = SC01
validation_evidence_group_id = VE01
```

Frontier posture:

```text
frontier_position_type = BASELINE_REFERENCE_POINT
executive_frontier_quadrant = BASELINE_REFERENCE_QUADRANT
baseline_available_flag = true
```

Option C posture:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
option_c_frontier_posture_type = OPTION_C_NOT_APPLICABLE_FRONTIER_POINT
```

Ranks are all `1`, which is expected because there is only one archived frontier row:

```text
offer_access_rank_desc = 1
approved_amount_rank_desc = 1
total_approved_expected_loss_rank_asc = 1
approved_expected_loss_rate_rank_asc = 1
offer_risk_profile_rank_asc = 1
manual_review_burden_rank_asc = 1
decline_burden_rank_asc = 1
```

Interpretation:

```text
This row is valid for M2-01 evidence capture.
It is not yet meaningful as a cross-strategy frontier ranking.
```

No issue.

---

# 15.8A — Frontier object row-count diagnostic

```text
Status: PASS
```

Temporary object counts are exactly what we expect for a one-slice frontier run:

```text
tmp_m2_strategy_frontier_campaign_registry_map = 39
tmp_m2_strategy_frontier_inventory = 1
tmp_m2_strategy_frontier_summary = 1
tmp_m2_strategy_frontier_baseline_deltas = 1
tmp_m2_strategy_frontier_efficiency = 1
tmp_m2_strategy_frontier_classification = 1
tmp_m2_strategy_frontier_segment_highlights = 35
tmp_m2_strategy_frontier_executive_summary = 1
```

No issue.

---

# 15.8B — Frontier baseline availability diagnostic

```text
Status: PASS
```

Baseline references are available for the current frontier row:

```text
frontier_rows = 1
rows_with_baseline_reference = 1
rows_without_baseline_reference = 0

baseline_reference_status =
BASELINE_REFERENCES_AVAILABLE_FOR_ALL_FRONTIER_ROWS
```

Because the only row is the baseline itself, this is expected.

No issue.

---

# 15.8C — Frontier reason-code storytelling diagnostic

```text
Status: PASS
```

The reason-code storytelling row is correct:

```text
frontier_position_type = BASELINE_REFERENCE_POINT
executive_frontier_quadrant = BASELINE_REFERENCE_QUADRANT

top_primary_reason_code = APPROVED_AS_REQUESTED
top_primary_reason_population_share = 0.213900

top_non_approval_primary_reason_code = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
top_non_approval_reason_population_share = 0.178100

top_policy_stop_primary_reason_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK
top_policy_stop_reason_population_share = 0.127380
```

Baseline-relative reason-code delta fields are NULL / NaN, which is correct for a baseline self-reference point.

No issue.

---

# 15.8D — Frontier registry linkage diagnostic

```text
Status: PASS
```

Registry linkage is clean:

```text
executive_frontier_rows = 1
registry_matched_rows = 1
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0

registry_linkage_status =
FRONTIER_REGISTRY_LINKAGE_READY
```

No issue.

---

# 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS / expected empty for M2-01, but preservation refinement recommended
```

The output is empty.

That is logically acceptable for the current state because there are no archived selective/aggressive Option C strategy slices yet. The only archived slice is:

```text
BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

So there is no Option C split frontier to diagnose yet.

However, based on the preservation standard we applied in Sections 8, 9, 10, and 12, I would recommend changing 15.8E to return a one-row `NOT_APPLICABLE` diagnostic when no Option C frontier rows exist. This would make the CSV prove the query ran and that Option C was not applicable, rather than producing an empty export that could be confused with a missed query.

Recommended future status text:

```text
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

This is not a blocker.

---

# Final Section 15 current-state signoff

```text
M2-01 Section 15 QA: ACCEPTED FOR CURRENT ARCHIVE STATE

No archive row-count issue.
No application-grain issue.
No registry linkage issue.
No baseline-reference issue.
No baseline-delta issue.
No frontier classification issue.
No executive summary issue.
No Option C leakage.
No true blocker found.

Current limitation:
    Only M2-01 is archived, so Section 15 is inventory-only / baseline-reference.
    Full frontier interpretation requires additional archived campaign runs.
```

## Operational interpretation

Section 15 is valid for **current-run evidence capture**:

```text
Section 16 can consume tmp_m2_strategy_frontier_executive_summary for M2-01.
```

But Section 15 is not yet final-campaign frontier evidence:

```text
After more campaign runs are archived — and especially after all planned runs are complete —
rerun Section 15 from the completed archive before Section 16.9 and Section 17.
```

That workflow is consistent with the documented design: Section 15 creates archive-wide temporary frontier outputs, Section 16 captures run-level evidence, and Section 16.9 later synchronizes fresh Section 15-derived frontier fields into persistent executive evidence after the full campaign archive is complete. fileciteturn13file21

---

# Section 15 refinement recommendations

No logic changes are required. I would make the following export-readability refinements before final preservation.

## Recommended refinements

### 1. Clarify or rename `approved_expected_loss_rate`

Observed in:

```text
15.2A
15.3A
15.5A
15.6A
15.7A
```

And as:

```text
frontier_approved_expected_loss_rate
```

in:

```text
15.4A
```

This appears to mean:

```text
approved Expected Loss / approved amount
```

not:

```text
approved Expected Loss / requested Expected Loss
```

Recommended naming:

```text
approved_el_per_approved_dollar
```

Optionally also add:

```text
approved_expected_loss_capture_rate =
    total_approved_expected_loss_amount / total_requested_expected_loss_amount
```

This would align Section 15 with the cleanup already accepted in Sections 12 and 14.

---

### 2. Shorten the aggressive override exposure-reduction alias

Current exported alias is exactly at the PostgreSQL 63-character identifier boundary:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffer
```

It appears to have been truncated from a plural form.

Recommended shorter alias:

```text
avg_agr_ovr_co_exposure_reduction_pct
```

This would align with the shorter Section 16/16.9 alias pattern we already adopted.

---

### 3. Add a one-row NOT_APPLICABLE export for 15.8E

Current 15.8E is empty for M2-01.

Recommended behavior:

```text
If no SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist,
return one row with:
    option_c_frontier_diagnostic_status =
        OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

This is preservation-friendly and consistent with prior refinements.

---

## Optional refinements

### A. Add a single-slice frontier interpretation note

Relevant to:

```text
15.0
15.4A
15.5A
15.7A
```

Recommended note:

```text
Single archived-slice frontier outputs are valid for baseline evidence capture, but rank and
delta fields are not comparative until additional strategy slices are archived.
```

---

### B. Add a segment-grain note to 15.6A

Recommended note:

```text
PRODUCT, SCORE_BAND, and PRODUCT_X_SCORE rows are separate segment grains; each grain can sum to the
full archived population independently.
```

This prevents future reviewers from mistakenly summing all 35 rows together.

---

### C. Add a NULL / NaN offer-metric note for zero-offer segments

Relevant to deep-subprime product × score rows in 15.6A.

Recommended note:

```text
Offer-row averages and approved EL rates are NULL / NaN for segments with no simulated positive
offer exposure.
```

---

## Recommended implementation order

```text
1. Rename / clarify approved_expected_loss_rate fields.
2. Shorten the aggressive override exposure-reduction alias.
3. Add NOT_APPLICABLE row behavior to 15.8E.
4. Add single-slice frontier note where helpful.
5. Add segment-grain and zero-offer notes to 15.6A.
```

Section 15 is accepted now. These refinements are documentation/export polish, not blockers.
<!-- END_MESSAGE C040-M01836 -->


---

<a id="c040-m01837"></a>

### C040-M01837

**Andrew** · 2026-05-18T22:34:31.608000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01837 -->
perform all recommended and optional refinements for section 15 QA.  provide back full copy paste for each updated section.  Here is current section 15 code:
<!-- END_MESSAGE C040-M01837 -->


**Attachments in export:** `Pasted text(223).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01851"></a>

### C040-M01851

**ChatGPT** · 2026-05-18T22:46:58.486935-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01851 -->
Done. I created two SQL artifacts:

[Download the updated Section 15 replacement sections only](sandbox:/mnt/data/section15_refinement_replacement_sections_only.sql)

[Download the full refined Section 15 SQL](sandbox:/mnt/data/section15_refined_full.sql)

I used your current Section 15 code as the source and applied the approved recommended + optional QA refinements. fileciteturn13file0

## Updated sections included

The replacement-sections file contains full copy-paste blocks for:

```text
15.0
15.2
15.3
15.4
15.5
15.6
15.7
15.8E
```

## Main implementation choices

I added clearer Expected Loss metric naming:

```text
approved_expected_loss_capture_rate
    = approved EL / requested EL

approved_el_per_approved_dollar
    = approved EL / approved amount
```

I intentionally retained:

```text
approved_expected_loss_rate
```

as a backward-compatible alias for:

```text
approved_el_per_approved_dollar
```

That should reduce the chance of breaking Section 16 / 16.9 dependencies that may still refer to the historical field name.

I also shortened the aggressive override average metric aliases to:

```text
avg_agr_ovr_co_exposure_reduction_pct
avg_agr_ovr_co_approved_pti
avg_agr_ovr_co_approved_el
```

And I updated `15.8E` so it returns a deliberate one-row `NOT_APPLICABLE` diagnostic when no selective/aggressive Option C frontier rows exist, instead of returning an empty export.

## Recommended usage

Use either:

```text
Option 1:
    Replace only the sections in section15_refinement_replacement_sections_only.sql.

Option 2:
    Replace the full Section 15 with section15_refined_full.sql.
```

After replacing, rerun Section 15 from the beginning so the temporary frontier tables are rebuilt in the right order.
<!-- END_MESSAGE C040-M01851 -->


---

<a id="c040-m01852"></a>

### C040-M01852

**Andrew** · 2026-05-19T07:05:03.281000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01852 -->
when running the refined section 15 this morning (also should note I did not re-run section 1-14 - and it is a new session, so perhaps that is a cause), I encountered this error: SQL Error [0A000]: ERROR: invalid UNION/INTERSECT/EXCEPT ORDER BY clause
  Detail: Only result column names can be used, not expressions or functions.
  Hint: Add the expression/function to every SELECT, or move the UNION into a FROM clause.
  Position: 6070
  ERROR: invalid UNION/INTERSECT/EXCEPT ORDER BY clause
  Detail: Only result column names can be used, not expressions or functions.
  Hint: Add the expression/function to every SELECT, or move the UNION into a FROM clause.
  Position: 6070
<!-- END_MESSAGE C040-M01852 -->


---

<a id="c040-m01857"></a>

### C040-M01857

**ChatGPT** · 2026-05-19T07:12:20.517394-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01857 -->
This error is **not caused by the new SQL session**. A new session can matter for temporary tables, but this specific error is a PostgreSQL syntax rule issue in the refined Section 15 code.

The likely culprit is the refined **15.8E** block. It uses:

```sql
SELECT *
FROM option_c_frontier_rows

UNION ALL

SELECT *
FROM not_applicable_row

ORDER BY
    module1_scenario_set_name NULLS FIRST,
    module1_scenario_name NULLS FIRST,
    population_id NULLS FIRST,
    CASE
        WHEN strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY' THEN 1
        WHEN strategy_name = 'AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY' THEN 2
        ELSE 3
    END,
    strategy_name NULLS FIRST;
```

PostgreSQL does not allow arbitrary expressions like that `CASE` expression directly in the `ORDER BY` of a `UNION` query. It only allows result column names or ordinal positions at that level. Section 15’s role is the archive-wide frontier summary used later by Section 16 and Section 16.9, so this should be fixed cleanly rather than worked around in DBeaver. fileciteturn13file0

Replace **15.8E only** with the corrected version below.

---

## Replace Section 15.8E with this

```sql
/***************************************************************************************************
SECTION 15.8E — OPTION C COUNTEROFFER STRATEGY SPLIT FRONTIER DIAGNOSTIC
****************************************************************************************************

PURPOSE:
    Summarize archive-wide Option C frontier behavior.

BUSINESS PURPOSE:
    Confirm whether archived frontier points preserve the selective-versus-aggressive counteroffer
    strategy split evidence needed for executive interpretation.

WHY THIS REFINEMENT EXISTS:
    When no SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist, the prior diagnostic
    returned an empty export.

    A deliberate one-row NOT_APPLICABLE export is easier to preserve and review because it proves the
    query ran and that Option C frontier evidence is not yet available in the current archive.

POSTGRESQL UNION ORDER-BY NOTE:
    PostgreSQL does not allow arbitrary expressions or CASE statements directly in the ORDER BY clause
    of a UNION / UNION ALL query unless those expressions are present as result columns.

    This diagnostic therefore creates a combined CTE first, then applies the final ORDER BY from an
    outer SELECT.

INTERPRETATION:
    SELECTIVE_FEASIBILITY should generally show:
        aggressive_override_rows = 0

    AGGRESSIVE_EXPANSION may show:
        aggressive_override_rows > 0

    Aggressive override rows may resolve to:
        final COUNTEROFFER,
        final MANUAL_REVIEW,
        or final DECLINE

    depending on Section 8 feasibility and Section 9 final-resolution behavior.

BOUNDARY:
    This is archive-wide frontier evidence only.

    It does not decide whether aggressive expansion is better.
    It does not perform matched row-level comparison.
    It does not replace Section 13 or Section 14.
****************************************************************************************************/

WITH option_c_frontier_rows AS (
    SELECT
        'OPTION_C_FRONTIER_ROWS_AVAILABLE'::TEXT
            AS option_c_frontier_diagnostic_status,

        'Option C selective/aggressive frontier rows exist in the archive. Review ordinary candidate, aggressive override, final outcome, approved exposure, approved PTI, and approved Expected Loss behavior before drafting strategy narrative.'::TEXT
            AS interpretation_note,

        strategy_set_name,
        strategy_name,
        strategy_version,

        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        counteroffer_strategy_variant,
        aggressive_counteroffer_expansion_enabled,

        applications,

        ordinary_counteroffer_candidate_rows,
        ordinary_counteroffer_candidate_rate,

        aggressive_override_rows,
        aggressive_override_rate,

        aggressive_override_final_counteroffer_rows,
        aggressive_override_final_counteroffer_rate,

        aggressive_override_final_manual_review_rows,
        aggressive_override_final_manual_review_rate,

        aggressive_override_final_decline_rows,
        aggressive_override_final_decline_rate,

        delta_aggressive_override_rate,
        delta_aggressive_override_final_counteroffer_rate,

        avg_agr_ovr_co_exposure_reduction_pct,
        avg_agr_ovr_co_approved_pti,
        avg_agr_ovr_co_approved_el,

        option_c_frontier_posture_type,
        option_c_frontier_interpretation_note

    FROM tmp_m2_strategy_frontier_executive_summary

    WHERE strategy_name IN (
            'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY',
            'AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY'
        )
       OR counteroffer_strategy_variant IN (
            'SELECTIVE_FEASIBILITY',
            'AGGRESSIVE_EXPANSION'
        )
       OR aggressive_override_rows > 0
),

not_applicable_row AS (
    SELECT
        'OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS'::TEXT
            AS option_c_frontier_diagnostic_status,

        'No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive. This is expected for a single M2-01 baseline archive and should not be treated as an Option C failure.'::TEXT
            AS interpretation_note,

        NULL::TEXT AS strategy_set_name,
        NULL::TEXT AS strategy_name,
        NULL::TEXT AS strategy_version,

        NULL::TEXT AS module1_scenario_set_name,
        NULL::TEXT AS module1_scenario_name,
        NULL::TEXT AS population_id,

        NULL::TEXT AS counteroffer_strategy_variant,
        NULL::BOOLEAN AS aggressive_counteroffer_expansion_enabled,

        0::BIGINT AS applications,

        0::BIGINT AS ordinary_counteroffer_candidate_rows,
        NULL::NUMERIC AS ordinary_counteroffer_candidate_rate,

        0::BIGINT AS aggressive_override_rows,
        NULL::NUMERIC AS aggressive_override_rate,

        0::BIGINT AS aggressive_override_final_counteroffer_rows,
        NULL::NUMERIC AS aggressive_override_final_counteroffer_rate,

        0::BIGINT AS aggressive_override_final_manual_review_rows,
        NULL::NUMERIC AS aggressive_override_final_manual_review_rate,

        0::BIGINT AS aggressive_override_final_decline_rows,
        NULL::NUMERIC AS aggressive_override_final_decline_rate,

        NULL::NUMERIC AS delta_aggressive_override_rate,
        NULL::NUMERIC AS delta_aggressive_override_final_counteroffer_rate,

        NULL::NUMERIC AS avg_agr_ovr_co_exposure_reduction_pct,
        NULL::NUMERIC AS avg_agr_ovr_co_approved_pti,
        NULL::NUMERIC AS avg_agr_ovr_co_approved_el,

        'OPTION_C_FRONTIER_NOT_APPLICABLE_FRONTIER_POINT'::TEXT
            AS option_c_frontier_posture_type,

        'No Option C selective or aggressive strategy frontier point is archived yet. Rerun Section 15 after M2-05 / M2-18 / M2-29 or M2-37 / M2-38 / M2-39 are archived to review Option C frontier behavior.'::TEXT
            AS option_c_frontier_interpretation_note

    WHERE NOT EXISTS (
        SELECT 1
        FROM option_c_frontier_rows
    )
),

combined_option_c_frontier_diagnostic AS (
    SELECT *
    FROM option_c_frontier_rows

    UNION ALL

    SELECT *
    FROM not_applicable_row
)

SELECT
    option_c_frontier_diagnostic_status,
    interpretation_note,

    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    counteroffer_strategy_variant,
    aggressive_counteroffer_expansion_enabled,

    applications,

    ordinary_counteroffer_candidate_rows,
    ordinary_counteroffer_candidate_rate,

    aggressive_override_rows,
    aggressive_override_rate,

    aggressive_override_final_counteroffer_rows,
    aggressive_override_final_counteroffer_rate,

    aggressive_override_final_manual_review_rows,
    aggressive_override_final_manual_review_rate,

    aggressive_override_final_decline_rows,
    aggressive_override_final_decline_rate,

    delta_aggressive_override_rate,
    delta_aggressive_override_final_counteroffer_rate,

    avg_agr_ovr_co_exposure_reduction_pct,
    avg_agr_ovr_co_approved_pti,
    avg_agr_ovr_co_approved_el,

    option_c_frontier_posture_type,
    option_c_frontier_interpretation_note

FROM combined_option_c_frontier_diagnostic

ORDER BY
    module1_scenario_set_name NULLS FIRST,
    module1_scenario_name NULLS FIRST,
    population_id NULLS FIRST,
    CASE
        WHEN strategy_name = 'SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY' THEN 1
        WHEN strategy_name = 'AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY' THEN 2
        ELSE 3
    END,
    strategy_name NULLS FIRST;
```

---

## What to rerun

After replacing 15.8E, rerun **Section 15 from the beginning**.

You do **not** need to rerun Sections 1–14 solely because of this syntax error, assuming these permanent tables still exist and contain the accepted M2-01 output:

```sql
credit_decisioning_sim.strategy_decisions
credit_decisioning_sim.strategy_decisions_archive
credit_decisioning_sim.strategy_run_campaign_registry
credit_decisioning_sim.strategy_comparison_campaign_registry
```

A new SQL session mainly matters because temporary tables from earlier sections disappear. Section 15 creates its own temporary frontier tables, so rerunning Section 15 from its start is the right fix. Section 16, however, should be run in a session where both Section 14’s `tmp_m2_validation_status_summary` and Section 15’s `tmp_m2_strategy_frontier_executive_summary` exist.
<!-- END_MESSAGE C040-M01857 -->


---

<a id="c040-m01859"></a>

### C040-M01859

**Andrew** · 2026-05-19T07:22:00.570000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01859 -->
review updated section 15 QA following refinements:
<!-- END_MESSAGE C040-M01859 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.4A_QA_strategy_efficiency_metrics_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.5A_QA_strategy_frontier_classification_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.6A_QA_segment_level_frontier_highlights_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.7A_QA_executive_ready_strategy_frontier_summary_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8A_QA_frontier_object_row_count_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8B_QA_frontier_baseline_availability_diagnostic(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8C_QA_frontier_reason_code_storytelling_diagnostic(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8D_QA_frontier_registry_linkage_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.8E_QA_option_c_counteroffer_strategy_split_frontier_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0_QA_frontier_scope_and_archive_readiness_snapshot(4).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.0A.2_QA_campaign_registry_map_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.1A_QA_archive_frontier_inventory_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.2A_QA_core_strategy_frontier_summary_review_output(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_15.3A_QA_baseline_relative_frontier_delta_review_output(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01866"></a>

### C040-M01866

**ChatGPT** · 2026-05-19T07:30:09.811339-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01866 -->
## Updated refined Section 15 QA review verdict

```text
Section 15 refined QA status: PASS
M2-01 archive frontier status: ACCEPTED FOR CURRENT SINGLE-SLICE STATE
Refinement status: accepted
True blockers: none
Required changes: none
Ready for Section 16 evidence capture: yes, assuming Section 14 and Section 15 temp outputs exist in the same session
```

Section 15 is working as intended for the current M2-01-only archive state. It is the archive-backed strategy frontier layer: it summarizes archived strategy slices and prepares executive-ready frontier evidence, but it is not meant to produce a meaningful multi-strategy frontier until more campaign runs are archived. fileciteturn13file22

---

## 15.0 — Frontier scope and archive readiness snapshot

```text
Status: PASS
Refinement accepted: yes
```

The new single-slice interpretation note is present and useful:

```text
Single archived-slice frontier outputs are valid for baseline evidence capture,
but strategy tradeoff interpretation is inventory-only until additional archived
strategy slices exist.
```

Current scope remains correct:

```text
archived_rows = 50,000
distinct_archived_application_ids = 50,000
archived_strategy_scenario_slice_count = 1
module1_scenario_population_slice_count = 1
module2_strategy_version_count = 1

frontier_scope_status =
FRONTIER_INVENTORY_ONLY_SINGLE_ARCHIVED_SLICE
```

No issue.

---

## 15.0A.2 — Campaign registry map review output

```text
Status: PASS
```

The registry map remains clean:

```text
registry rows = 39
registry_match_count = 1 for all 39 rows
frontier_registry_match_status = FRONTIER_REGISTRY_MATCHED for all 39 rows
```

This confirms the full 39-run campaign registry is intact and mapped, even though only M2-01 is currently archived.

No issue.

---

## 15.1A — Archive frontier inventory review output

```text
Status: PASS
```

The archived M2-01 baseline slice remains valid:

```text
archived_row_count = 50,000
distinct_application_id_count = 50,000
duplicate_application_row_count = 0
```

Decision counts still match the accepted M2-01 profile:

```text
approval_count = 10,695
counteroffer_count = 19,067
manual_review_count = 7,535
decline_count = 12,703
simulated_offer_exposure_count = 29,762
```

No issue.

---

## 15.2A — Core strategy frontier summary

```text
Status: PASS
Refinement accepted: yes
```

The Expected Loss naming refinement worked. The output now clearly separates:

```text
approved_expected_loss_capture_rate = approved EL / requested EL
approved_el_per_approved_dollar = approved EL / approved amount
```

Observed values:

```text
total_requested_expected_loss_amount = 239.433M
total_approved_expected_loss_amount = 58.552M
approved_expected_loss_capture_rate = 0.244543
approved_el_per_approved_dollar = 0.015299
```

The backward-compatible field remains:

```text
approved_expected_loss_rate = 0.015299
```

That is acceptable because it matches `approved_el_per_approved_dollar`. For documentation, use the clearer new field names.

Option C baseline posture is correct:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
```

The shortened aggressive override aliases are present and not truncated:

```text
avg_agr_ovr_co_exposure_reduction_pct
avg_agr_ovr_co_approved_pti
avg_agr_ovr_co_approved_el
```

They are correctly NULL / NaN for M2-01 because there are no aggressive override rows.

No issue.

---

## 15.3A — Baseline-relative frontier delta review

```text
Status: PASS
Refinement accepted: yes
```

The baseline-relative note is present and useful:

```text
Baseline-relative deltas are meaningful only when a non-baseline strategy has a matching
baseline reference; baseline self-reference rows should show zero deltas.
```

The current row behaves exactly as expected:

```text
baseline_available_flag = true
baseline_strategy_name = BASELINE_STRATEGY
applications = 50,000
baseline_applications = 50,000
```

All baseline-relative deltas are zero:

```text
delta_approval_rate = 0
delta_counteroffer_rate = 0
delta_manual_review_rate = 0
delta_decline_rate = 0
delta_simulated_offer_exposure_rate = 0
delta_total_approved_amount = 0
delta_total_approved_expected_loss_amount = 0
delta_approved_expected_loss_capture_rate = 0
delta_approved_el_per_approved_dollar = 0
delta_approved_expected_loss_rate = 0
delta_ordinary_counteroffer_candidate_rate = 0
delta_aggressive_override_rate = 0
```

No issue.

---

## 15.4A — Strategy efficiency metrics

```text
Status: PASS
Refinement accepted: yes
```

The efficiency metrics are available:

```text
frontier_efficiency_metric_status =
FRONTIER_EFFICIENCY_METRICS_AVAILABLE
```

The refined names are clearer:

```text
frontier_approved_expected_loss_capture_rate = 0.244543
frontier_approved_el_per_approved_dollar = 0.015299
frontier_approved_expected_loss_rate = 0.015299
```

The renamed offer-rate efficiency field is also clearer:

```text
offer_rate_per_approved_el_per_approved_dollar_unit = 38.908338
```

Core efficiency values remain coherent:

```text
positive_offer_access_rate = 0.595240
manual_review_burden_rate = 0.150700
no_offer_outcome_rate = 0.254060
approved_amount_per_approved_expected_loss_dollar = 65.365799
applications_per_million_approved_expected_loss = 853.946284
```

No issue.

---

## 15.5A — Strategy frontier classification

```text
Status: PASS
Refinement accepted: yes
```

The classification note is present and appropriate:

```text
Classification labels are diagnostic review aids; single-slice baseline rows are reference points,
not comparative frontier winners.
```

Current classification remains correct:

```text
frontier_position_type = BASELINE_REFERENCE_POINT
executive_frontier_quadrant = BASELINE_REFERENCE_QUADRANT
```

Option C posture remains correct:

```text
option_c_frontier_posture_type =
OPTION_C_NOT_APPLICABLE_FRONTIER_POINT

option_c_frontier_interpretation_note =
This archived strategy slice is not part of the Option C counteroffer split.
```

No issue.

---

## 15.6A — Segment-level frontier highlights

```text
Status: PASS
Refinement accepted: yes
```

The new segment-grain / zero-offer interpretation note is exactly right:

```text
PRODUCT, SCORE_BAND, and PRODUCT_X_SCORE rows are separate segment grains; each grain can
sum to the full archived population independently. Offer-row averages and approved EL metrics
are NULL / NaN where no simulated positive offer rows exist.
```

Segment rows are correct:

```text
PRODUCT rows = 5
SCORE_BAND rows = 5
PRODUCT_X_SCORE rows = 25
total rows = 35
```

Each grain independently reconciles to 50,000:

```text
PRODUCT applications sum = 50,000
SCORE_BAND applications sum = 50,000
PRODUCT_X_SCORE applications sum = 50,000
```

Deep-subprime zero-offer handling is now clearly documented. For example:

```text
AUTO_LOAN / DEEP_SUBPRIME:
    simulated_offer_exposure_rate = 0
    approved_expected_loss_capture_rate = 0
    approved_el_per_approved_dollar = NULL / NaN

MORTGAGE / DEEP_SUBPRIME:
    simulated_offer_exposure_rate = 0
    approved_expected_loss_capture_rate = 0
    approved_el_per_approved_dollar = NULL / NaN
```

The one `REVOLVING_LINE / DEEP_SUBPRIME` offer row still produces a non-null approved EL density, which is expected because that segment has a tiny positive offer population.

No issue.

---

## 15.7A — Executive-ready strategy frontier summary

```text
Status: PASS
Refinement accepted: yes
```

This remains the key Section 15 output for Section 16 current-run evidence capture.

Registry linkage is clean:

```text
frontier_registry_match_status = FRONTIER_REGISTRY_MATCHED
frontier_registry_match_count = 1
module1_run_id = M1-01
module2_run_id = M2-01
validation_evidence_group_id = VE01
```

Frontier posture is correct:

```text
frontier_position_type = BASELINE_REFERENCE_POINT
executive_frontier_quadrant = BASELINE_REFERENCE_QUADRANT
```

The refined Expected Loss fields are present:

```text
approved_expected_loss_capture_rate = 0.244543
approved_el_per_approved_dollar = 0.015299
approved_expected_loss_rate = 0.015299
delta_approved_expected_loss_capture_rate = 0
delta_approved_el_per_approved_dollar = 0
delta_approved_expected_loss_rate = 0
```

Option C current-state fields are correct:

```text
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
option_c_frontier_posture_type = OPTION_C_NOT_APPLICABLE_FRONTIER_POINT
```

No column aliases appear truncated. No issue.

---

## 15.8A — Frontier object row-count diagnostic

```text
Status: PASS
```

Temporary frontier objects have the expected row counts:

```text
tmp_m2_strategy_frontier_campaign_registry_map = 39
tmp_m2_strategy_frontier_inventory = 1
tmp_m2_strategy_frontier_summary = 1
tmp_m2_strategy_frontier_baseline_deltas = 1
tmp_m2_strategy_frontier_efficiency = 1
tmp_m2_strategy_frontier_classification = 1
tmp_m2_strategy_frontier_segment_highlights = 35
tmp_m2_strategy_frontier_executive_summary = 1
```

No issue.

---

## 15.8B — Frontier baseline availability diagnostic

```text
Status: PASS
```

Baseline reference availability is correct:

```text
frontier_rows = 1
rows_with_baseline_reference = 1
rows_without_baseline_reference = 0

baseline_reference_status =
BASELINE_REFERENCES_AVAILABLE_FOR_ALL_FRONTIER_ROWS
```

No issue.

---

## 15.8C — Frontier reason-code storytelling diagnostic

```text
Status: PASS
```

Reason-code storytelling remains coherent:

```text
top_primary_reason_code = APPROVED_AS_REQUESTED
top_primary_reason_population_share = 0.213900

top_non_approval_primary_reason_code = COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
top_non_approval_reason_population_share = 0.178100

top_policy_stop_primary_reason_code = POLICY_STOP_SEVERE_SYNTHETIC_RISK
top_policy_stop_reason_population_share = 0.127380
```

Baseline-relative reason-code delta fields are NULL / NaN, which is expected for the baseline reference row.

No issue.

---

## 15.8D — Frontier registry linkage diagnostic

```text
Status: PASS
```

Registry linkage is clean:

```text
executive_frontier_rows = 1
registry_matched_rows = 1
registry_missing_rows = 0
registry_duplicate_review_rows = 0
missing_module2_run_id_rows = 0
missing_validation_evidence_group_id_rows = 0

registry_linkage_status =
FRONTIER_REGISTRY_LINKAGE_READY
```

No issue.

---

## 15.8E — Option C counteroffer strategy split frontier diagnostic

```text
Status: PASS
Refinement accepted: yes
```

The PostgreSQL `UNION` / `ORDER BY` issue is resolved, and the preservation-friendly one-row output now works.

Current diagnostic status:

```text
OPTION_C_FRONTIER_NOT_APPLICABLE_NO_SELECTIVE_OR_AGGRESSIVE_ROWS
```

Interpretation note:

```text
No SELECTIVE_FEASIBILITY or AGGRESSIVE_EXPANSION frontier rows exist in the current archive.
This is expected for a single M2-01 baseline archive and should not be treated as an Option C failure.
```

Current row values are correct:

```text
applications = 0
ordinary_counteroffer_candidate_rows = 0
aggressive_override_rows = 0
aggressive_override final outcome rows = 0
avg aggressive override metrics = NULL / NaN
```

This output should not be interpreted as saying M2-01 has zero ordinary counteroffer candidate rows. It is an **Option C selective/aggressive frontier diagnostic** only. The standalone M2-01 frontier row still correctly shows:

```text
ordinary_counteroffer_candidate_rows = 21,286
aggressive_override_rows = 0
```

No issue.

---

# Final Section 15 refined QA signoff

```text
M2-01 Section 15 refined QA: ACCEPTED

No syntax issue remains.
No archive row-count issue.
No application-grain issue.
No registry linkage issue.
No baseline-reference issue.
No baseline-delta issue.
No frontier classification issue.
No executive summary issue.
No Option C leakage.
No alias truncation issue.
No empty Option C frontier diagnostic issue.
```

## Current-state interpretation

```text
M2-01 archive slice is valid.
Section 15 is valid for current-run evidence capture.
Frontier interpretation is inventory-only / baseline-reference until additional archived slices exist.
```

The single-slice limitation is expected:

```text
archived_strategy_scenario_slice_count = 1
frontier_scope_status = FRONTIER_INVENTORY_ONLY_SINGLE_ARCHIVED_SLICE
```

After more campaign runs are archived, especially after the full campaign, Section 15 should be rerun from the completed archive before Section 16.9 and Section 17.

---

## Operational note before Section 16

Because you reran Section 15 in a new session, confirm Section 14’s temp output still exists before running Section 16:

```sql
tmp_m2_validation_status_summary
```

Section 16 needs both:

```sql
tmp_m2_validation_status_summary
tmp_m2_strategy_frontier_executive_summary
```

So before Section 16, the safest path is:

```text
1. Rerun Section 14 if tmp_m2_validation_status_summary is not present.
2. Rerun Section 15 if tmp_m2_strategy_frontier_executive_summary is not present.
3. Then run Section 16.
```

No need to rerun Sections 1–13 solely for Section 16, assuming the permanent latest-run and archive tables remain populated and valid.
<!-- END_MESSAGE C040-M01866 -->


---

<a id="c040-m01868"></a>

### C040-M01868

**Andrew** · 2026-05-19T08:00:58.561000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01868 -->
i reran the code from the top and while running section 16, I encountered the following error: SQL Error [42703]: ERROR: column f.avg_exposure_reduction_pct_for_aggressive_override_counteroffer does not exist
  Position: 103030
  ERROR: column f.avg_exposure_reduction_pct_for_aggressive_override_counteroffer does not exist
  Position: 103030
       I believe that we changed this in one of our enhancements/refinements during this QA pass.  full current code attached. 
<!-- END_MESSAGE C040-M01868 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(10).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m01879"></a>

### C040-M01879

**ChatGPT** · 2026-05-19T08:09:35.889102-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01879 -->
This is exactly the alias change from our Section 15 refinements. It is **not** caused by the new SQL session.

Section 15 now outputs these shortened aggressive-override average metric aliases:

```text
avg_agr_ovr_co_exposure_reduction_pct
avg_agr_ovr_co_approved_pti
avg_agr_ovr_co_approved_el
```

But Section 16 is still trying to read the old Section 15 frontier-source names:

```text
f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers
f.avg_approved_pti_for_aggressive_override_counteroffers
f.avg_approved_el_for_aggressive_override_counteroffers
```

Section 16 is designed to consume the Section 15 temporary frontier executive summary and persist it into run-level evidence, so the Section 16 source references need to match the new Section 15 aliases. fileciteturn13file19turn13file23

I prepared a patched full code file here:

[Download patched full Module 2 code with the Section 16 / Section 15 alias fix applied](sandbox:/mnt/data/module2_v1_0_section16_section15_alias_patch_applied.txt)

And a small patch-instructions file here:

[Download Section 16 alias patch instructions](sandbox:/mnt/data/section16_section15_alias_patch_instructions.sql)

## What to change manually

### 1. In Section 16.6, replace this block

```sql
    f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers,
    f.avg_approved_pti_for_aggressive_override_counteroffers,
    f.avg_approved_el_for_aggressive_override_counteroffers,
```

with this:

```sql
    f.avg_agr_ovr_co_exposure_reduction_pct
        AS avg_exposure_reduction_pct_for_aggressive_override_counteroffers,

    f.avg_agr_ovr_co_approved_pti
        AS avg_approved_pti_for_aggressive_override_counteroffers,

    f.avg_agr_ovr_co_approved_el
        AS avg_approved_el_for_aggressive_override_counteroffers,
```

Important: the **persistent evidence table column names can stay long**. We are only changing the Section 15 source fields being read from `f`.

---

### 2. In Section 16.9B, update only the fresh Section 15 frontier required-column list

Find the block under:

```text
Confirm required columns exist in the fresh Section 15 frontier summary.
```

In that block only, replace:

```sql
                ('avg_exposure_reduction_pct_for_aggressive_override_counteroffers'),
                ('avg_approved_pti_for_aggressive_override_counteroffers'),
                ('avg_approved_el_for_aggressive_override_counteroffers'),
```

with:

```sql
                ('avg_agr_ovr_co_exposure_reduction_pct'),
                ('avg_agr_ovr_co_approved_pti'),
                ('avg_agr_ovr_co_approved_el'),
```

Do **not** change the earlier required-column list for:

```text
credit_decisioning_sim.strategy_run_evidence_summary
```

That persistent evidence table should still require the long column names.

---

### 3. In Section 16.9C and the post-update mismatch check, replace only the `f.` source references

Use these exact find/replace operations:

```text
Find:
    f.avg_exposure_reduction_pct_for_aggressive_override_counteroffers

Replace with:
    f.avg_agr_ovr_co_exposure_reduction_pct
```

```text
Find:
    f.avg_approved_pti_for_aggressive_override_counteroffers

Replace with:
    f.avg_agr_ovr_co_approved_pti
```

```text
Find:
    f.avg_approved_el_for_aggressive_override_counteroffers

Replace with:
    f.avg_agr_ovr_co_approved_el
```

This should fix both the pre-update candidate table and the post-update verification logic.

---

## What not to change

Do **not** rename these persistent evidence columns:

```text
avg_exposure_reduction_pct_for_aggressive_override_counteroffers
avg_approved_pti_for_aggressive_override_counteroffers
avg_approved_el_for_aggressive_override_counteroffers
```

Those can remain in:

```text
credit_decisioning_sim.strategy_run_evidence_summary
INSERT target column list
ALTER TABLE ADD COLUMN logic
Section 16.8 evidence review outputs
Section 17 evidence checks
```

The contract is now:

```text
Section 15 temporary frontier source fields:
    avg_agr_ovr_co_exposure_reduction_pct
    avg_agr_ovr_co_approved_pti
    avg_agr_ovr_co_approved_el

Persistent Section 16 evidence fields:
    avg_exposure_reduction_pct_for_aggressive_override_counteroffers
    avg_approved_pti_for_aggressive_override_counteroffers
    avg_approved_el_for_aggressive_override_counteroffers
```

## What to rerun

After applying the patch:

```text
If your current SQL session is still open:
    rerun Section 16 from Section 16.0.

If the session was closed:
    rerun Section 14, Section 15, then Section 16.
```

You do not need to rerun Sections 1–13 solely for this alias issue, assuming the latest-run and archive tables still contain the accepted M2-01 output. Section 16.2 should safely delete/replace current-run evidence rows before reinserting them.
<!-- END_MESSAGE C040-M01879 -->


---

<a id="c040-m01880"></a>

### C040-M01880

**Andrew** · 2026-05-19T09:15:48.990000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M01880 -->
when running the full updated code, encountered the following error in section 16: SQL Error [42804]: ERROR: column "aggressive_counteroffer_expansion_enabled" is of type boolean but expression is of type numeric
  Hint: You will need to rewrite or cast the expression.
  Position: 96944
  ERROR: column "aggressive_counteroffer_expansion_enabled" is of type boolean but expression is of type numeric
  Hint: You will need to rewrite or cast the expression.
  Position: 96944
<!-- END_MESSAGE C040-M01880 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_01.md) · [Next](Part_03.md)
