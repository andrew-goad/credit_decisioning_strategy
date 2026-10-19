# Module 2 Decision Simulator Build

## Part 20

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_19.md) · [Next](Part_21.md)

<a id="c038-m00316"></a>

### C038-M00316

**ChatGPT** · 2026-05-07T13:48:38.593691-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00316 -->
## Section 8 QA review — Approved Exposure and Counteroffer Feasibility Layer

**Verdict: PASS with monitoring notes.**

Section 8 is behaving as intended. It preserves the preliminary routing population, applies preliminary exposure treatment conventions correctly, evaluates counteroffer feasibility, calculates preliminary approved amount / approved PTI / approved Expected Loss where appropriate, and keeps failed counteroffers unresolved for Section 9 final decision resolution.

No blocker or high-severity issue is indicated. I do **not** recommend a Section 8 logic patch.

Section 8 is correctly doing this:

```text
Preliminary route
→ exposure treatment convention
→ counteroffer feasibility evaluation
→ preliminary approved amount / approved PTI / approved Expected Loss
```

It is still **not** assigning final `decision_outcome`, final reason codes, archive output, or full QA conclusions.

---

## 1. Exposure treatment status distribution

| Exposure treatment status | Rows | Share | Assessment |
|---|---:|---:|---|
| `APPROVED_AS_REQUESTED_PRELIMINARY` | 11,291 | 22.58% | PASS |
| `COUNTEROFFER_FEASIBLE_PRELIMINARY` | 19,067 | 38.13% | PASS |
| `COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY` | 2,219 | 4.44% | PASS / monitor |
| `NO_OFFER_PRELIMINARY_DECLINE` | 12,703 | 25.41% | PASS |
| `UNRESOLVED_MANUAL_REVIEW` | 4,720 | 9.44% | PASS |

This exactly reconciles to 50,000 rows.

The Section 8 exposure statuses align cleanly to Section 7 preliminary routes:

| Preliminary outcome | Section 8 treatment | Rows |
|---|---|---:|
| `APPROVE` | `APPROVED_AS_REQUESTED_PRELIMINARY` | 11,291 |
| `COUNTEROFFER` | feasible / not feasible | 21,286 |
| `DECLINE` | `NO_OFFER_PRELIMINARY_DECLINE` | 12,703 |
| `MANUAL_REVIEW` | `UNRESOLVED_MANUAL_REVIEW` | 4,720 |

**Assessment: PASS.**

There is no route leakage. Section 8 is treating each preliminary path according to the locked conventions.

---

## 2. Counteroffer feasibility evaluation

| Counteroffer feasibility evaluated | Rows |
|---|---:|
| `TRUE` | 21,286 |
| `FALSE` | 28,714 |

**Assessment: PASS.**

Only preliminary `COUNTEROFFER` rows were evaluated for counteroffer feasibility.

That is exactly correct. Preliminary `APPROVE`, `DECLINE`, and `MANUAL_REVIEW` rows should not receive counteroffer feasibility testing.

---

## 3. Counteroffer feasibility pass rate

| Feasibility result | Rows | Share of preliminary counteroffers |
|---|---:|---:|
| `TRUE` | 19,067 | 89.58% |
| `FALSE` | 2,219 | 10.42% |

**Assessment: PASS / monitor in Section 9.**

The pass rate is high but coherent. Section 7 routed 21,286 rows into counteroffer feasibility, and Section 8 found 19,067 structurally feasible reduced-exposure treatments.

This means most preliminary counteroffer cases can be reduced while satisfying the active feasibility constraints. That is plausible for a baseline strategy with broad counteroffer eligibility and product-specific exposure treatment.

Monitoring note: because `failed_counteroffer_resolution = MANUAL_REVIEW`, the 2,219 failed counteroffers should become final `MANUAL_REVIEW` rows in Section 9 unless a different resolution parameter is applied. Expected final manual-review volume before Section 9 confirmation is therefore approximately:

```text
4,720 preliminary manual review
+ 2,219 failed counteroffers
= 6,939 final manual review rows
```

Section 9 should confirm that.

---

## 4. Counteroffer failure reasons

| Failure reason | Failed rows | Share of failures | Assessment |
|---|---:|---:|---|
| `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT` | 2,070 | 93.29% | PASS / monitor |
| `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` | 89 | 4.01% | PASS |
| `COUNTEROFFER_EXCEEDS_MAX_REDUCTION` | 60 | 2.70% | PASS |

**Assessment: PASS.**

The failure reasons are interpretable. Failed counteroffers are not failing because of missing product configuration, null calculations, product disallowance, approved PTI target failure, or approved Expected Loss cap failure. They are failing because the rounded feasible amount does not produce a viable reduced offer under the minimum offer / maximum reduction framework.

This is a good sign for Section 8 structural integrity:

- Product policy configuration is available.
- Counteroffer calculations are producing numeric values.
- Rounding is working.
- Product cap, PTI target, and approved Expected Loss cap logic appear to be binding before failure classification.
- The failures are concentrated in offer-viability constraints.

The dominant failure reason, `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT`, means the strategy could reduce exposure enough to satisfy constraints, but the resulting offer would fall below the minimum viable percentage of requested amount. That is a business strategy constraint, not a calculation failure.

---

## 5. Counteroffer failure reasons by product

| Product | Failed rows | Main failure pattern |
|---|---:|---|
| `AUTO_LOAN` | 385 | Mostly below minimum requested percent |
| `HELOC` | 109 | Split between below minimum requested percent and max reduction |
| `MORTGAGE` | 509 | Mostly below minimum requested percent; some not below requested |
| `REVOLVING_LINE` | 717 | Mostly below minimum requested percent |
| `UNSECURED_PERSONAL_LOAN` | 499 | Mostly below minimum requested percent |

**Assessment: PASS / monitor product policy tuning later.**

Revolving Line has the largest failed count, followed by Mortgage and Unsecured Personal Loan. That is plausible because those products can be more sensitive to exposure caps, affordability reduction, or minimum viable offer thresholds.

HELOC is the only product with `COUNTEROFFER_EXCEEDS_MAX_REDUCTION`, at 60 rows. That indicates a subset of HELOC preliminary counteroffers would require more reduction than the strategy permits. That is coherent and should be visible later in reason-code and manual-review diagnostics.

No patch is recommended.

---

## 6. Counteroffer feasibility by product

| Product | Feasible | Failed | Pass rate |
|---|---:|---:|---:|
| `AUTO_LOAN` | 3,167 | 385 | 89.16% |
| `HELOC` | 1,872 | 109 | 94.50% |
| `MORTGAGE` | 5,848 | 509 | 92.00% |
| `REVOLVING_LINE` | 5,231 | 717 | 87.94% |
| `UNSECURED_PERSONAL_LOAN` | 2,949 | 499 | 85.53% |

**Assessment: PASS.**

Product pass rates are plausible and differentiated. HELOC and Mortgage pass at higher rates; Unsecured Personal Loan and Revolving Line pass at lower rates, which is directionally intuitive given unsecured / revolving sensitivity and smaller approval caps.

No product shows a pathological result such as 0% feasibility or 100% failure.

---

## 7. Counteroffer feasibility by score band

| Score band | Feasible | Failed | Pass rate | Interpretation |
|---|---:|---:|---:|---|
| `SUPER_PRIME` | 3,611 | 11 | 99.70% | Very strong |
| `PRIME` | 5,657 | 59 | 98.97% | Very strong |
| `NEAR_PRIME` | 8,818 | 737 | 92.29% | Strong |
| `SUBPRIME` | 980 | 1,411 | 40.99% | Feasibility pressure |
| `DEEP_SUBPRIME` | 1 | 1 | 50.00% | Tiny population; do not overinterpret |

**Assessment: PASS / monitor Subprime.**

This is directionally coherent. Stronger score bands have very high counteroffer feasibility. Subprime preliminary counteroffers are much more likely to fail feasibility.

That pattern is appropriate because counteroffer feasibility depends not only on requested exposure but also on the synthetic estimated-PD proxy and approved Expected Loss cap. Weaker segments can become infeasible even after exposure reduction.

This is consistent with the Module 1 risk framework where `estimated_pd` is a synthetic estimated-PD proxy used for relative risk ordering and Expected Loss simulation, not a calibrated production default model. fileciteturn4file1

---

## 8. Counteroffer feasibility by requested PTI bucket

| Requested PTI bucket | Feasible | Failed | Pass rate | Avg approved PTI for feasible rows |
|---|---:|---:|---:|---:|
| `LOW_REQUESTED_PTI` | 11,577 | 755 | 93.88% | 0.0780 |
| `MODERATE_REQUESTED_PTI` | 1,344 | 277 | 82.91% | 0.1681 |
| `ELEVATED_REQUESTED_PTI` | 5,125 | 713 | 87.78% | 0.2549 |
| `HIGH_REQUESTED_PTI` | 1,020 | 358 | 74.02% | 0.2945 |
| `SEVERE_REQUESTED_PTI` | 1 | 116 | 0.85% | 0.3187 |

**Assessment: PASS.**

This is one of the strongest Section 8 validations.

Higher requested PTI pressure clearly reduces feasibility. Severe requested PTI is almost entirely infeasible, with only 1 feasible row.

For feasible counteroffers, approved PTI is materially lower than requested PTI:

- Low requested PTI: approved PTI ~0.078
- Elevated requested PTI: approved PTI ~0.255
- High requested PTI: approved PTI ~0.294
- Severe requested PTI feasible row: approved PTI ~0.319

That confirms the approved payment / approved PTI proportional scaling logic is working as a strategy-simulation proxy. It is reducing exposure and improving affordability for feasible reduced-exposure cases.

---

## 9. Counteroffer feasibility by synthetic risk tier

| Strategy risk tier | Feasible | Failed | Pass rate |
|---|---:|---:|---:|
| `LOW_SYNTHETIC_RISK` | 6,026 | 11 | 99.82% |
| `MODERATE_SYNTHETIC_RISK` | 3,306 | 57 | 98.31% |
| `ELEVATED_SYNTHETIC_RISK` | 7,979 | 290 | 96.49% |
| `HIGH_SYNTHETIC_RISK` | 1,756 | 1,861 | 48.55% |

**Assessment: PASS.**

This is directionally coherent. Low, moderate, and elevated synthetic-risk tiers pass counteroffer feasibility at high rates. High synthetic-risk rows pass at roughly half the rate.

No `SEVERE_SYNTHETIC_RISK` rows appear in counteroffer feasibility because Section 7 routed all severe synthetic-risk rows to preliminary `DECLINE`. That is exactly the accepted hierarchy.

---

## 10. Requested amount vs approved amount

| Exposure treatment status | Rows | Avg requested amount | Avg approved amount preliminary | Assessment |
|---|---:|---:|---:|---|
| `APPROVED_AS_REQUESTED_PRELIMINARY` | 11,291 | 112,594 | 112,594 | PASS |
| `COUNTEROFFER_FEASIBLE_PRELIMINARY` | 19,067 | 176,816 | 136,792 | PASS |
| `COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY` | 2,219 | 136,024 | NULL | PASS |
| `NO_OFFER_PRELIMINARY_DECLINE` | 12,703 | 97,721 | 0 | PASS |
| `UNRESOLVED_MANUAL_REVIEW` | 4,720 | 101,827 | NULL | PASS |

**Assessment: PASS.**

The amount conventions are working:

- Preliminary approve rows preserve requested amount.
- Feasible counteroffer rows reduce approved amount.
- Failed counteroffers remain unresolved with no preliminary approved amount.
- Preliminary decline rows receive zero exposure.
- Manual review remains unresolved with null exposure.

Average feasible counteroffer reduction based on averages is approximately:

```text
176,816 - 136,792 = 40,024
```

That is meaningful but not extreme.

---

## 11. Requested PTI vs approved PTI

| Exposure treatment status | Avg requested PTI | Avg approved PTI preliminary | Assessment |
|---|---:|---:|---|
| `APPROVED_AS_REQUESTED_PRELIMINARY` | 0.0861 | 0.0861 | PASS |
| `COUNTEROFFER_FEASIBLE_PRELIMINARY` | 0.1853 | 0.1435 | PASS |
| `COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY` | 0.2218 | NULL | PASS |
| `NO_OFFER_PRELIMINARY_DECLINE` | 0.2161 | 0 | PASS |
| `UNRESOLVED_MANUAL_REVIEW` | 0.1078 | NULL | PASS |

**Assessment: PASS.**

This confirms the approved PTI proxy is working correctly for feasible counteroffers.

Feasible counteroffers reduce average PTI from:

```text
0.1853 → 0.1435
```

That is a material improvement and supports the Module 2 design thesis that counteroffers can reduce exposure pressure and improve simulated affordability.

Manual review remains unresolved, and decline follows the zero-exposure convention. Both are correct.

---

## 12. Requested Expected Loss vs approved Expected Loss

| Exposure treatment status | Avg requested Expected Loss | Avg approved Expected Loss preliminary | Assessment |
|---|---:|---:|---|
| `APPROVED_AS_REQUESTED_PRELIMINARY` | 765.74 | 765.74 | PASS |
| `COUNTEROFFER_FEASIBLE_PRELIMINARY` | 3,474.72 | 2,637.22 | PASS |
| `COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY` | 9,827.39 | NULL | PASS |
| `NO_OFFER_PRELIMINARY_DECLINE` | 10,475.04 | 0 | PASS |
| `UNRESOLVED_MANUAL_REVIEW` | 2,047.39 | NULL | PASS |

**Assessment: PASS.**

This is a strong Section 8 result.

Feasible counteroffers reduce average Expected Loss from:

```text
3,474.72 → 2,637.22
```

That confirms Section 8 is using approved exposure, not requested exposure, for preliminary approved Expected Loss.

The highest requested Expected Loss populations are preliminary declines and infeasible counteroffers, which is also intuitive.

This preserves the distinction between:

```text
requested_expected_loss_amount = Module 1 requested-exposure Expected Loss
approved_expected_loss_amount_preliminary = Module 2 approved-exposure Expected Loss proxy
```

That distinction is central to Module 2’s architecture and remains consistent with Module 1’s Expected Loss framing as a comparative simulation metric. fileciteturn4file1

---

## 13. Exposure reduction by product for feasible counteroffers

| Product | Feasible counteroffer rows | Avg exposure reduction pct |
|---|---:|---:|
| `AUTO_LOAN` | 3,167 | 15.00% |
| `HELOC` | 1,872 | 18.67% |
| `MORTGAGE` | 5,848 | 20.51% |
| `REVOLVING_LINE` | 5,231 | 21.51% |
| `UNSECURED_PERSONAL_LOAN` | 2,949 | 21.14% |

**Assessment: PASS.**

The exposure reduction pattern is plausible.

Auto Loan reductions are the lowest on average. Revolving Line, Unsecured Personal Loan, and Mortgage show higher reductions. That aligns to product-level exposure caps, affordability pressure, and approved Expected Loss constraints.

No product shows extreme average reductions that would suggest counteroffer logic is collapsing exposure.

---

## 14. Failed counteroffer constraint count

| Failure reason | Failed rows | Avg failed constraint count |
|---|---:|---:|
| `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT` | 2,070 | 2.0 |
| `COUNTEROFFER_EXCEEDS_MAX_REDUCTION` | 60 | 1.0 |
| `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` | 89 | 1.0 |

**Assessment: PASS.**

This is interpretable.

Rows failing due to `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT` average two failed feasibility constraints. That suggests these rows generally fail more than one offer-viability condition, not merely a one-off rounding artifact.

Rows failing due to max reduction or not-below-requested fail one constraint on average, which is also coherent.

---

## 15. Section 8 acceptance conclusion

Section 8 passes.

Accepted evidence:

- The 50,000-row population is preserved.
- Preliminary route-specific exposure treatment status is populated.
- Preliminary `APPROVE` rows preserve requested amount, requested PTI, and requested Expected Loss.
- Preliminary `DECLINE` rows follow the zero-exposure convention.
- Preliminary `MANUAL_REVIEW` rows remain unresolved.
- Only preliminary `COUNTEROFFER` rows receive counteroffer feasibility evaluation.
- 19,067 of 21,286 preliminary counteroffers pass feasibility.
- 2,219 preliminary counteroffers fail feasibility with deterministic failure reasons.
- Feasible counteroffers have positive approved amount below requested amount.
- Feasible counteroffers reduce approved PTI relative to requested PTI.
- Feasible counteroffers reduce approved Expected Loss relative to requested Expected Loss.
- Failed counteroffers remain unresolved for Section 9 final decision resolution.
- No final `decision_outcome` is assigned in Section 8.
- No final decision flags are assigned in Section 8.
- No simulated reason codes are assigned in Section 8.
- No latest-run output table is created in Section 8.
- No archive rows are inserted in Section 8.

## Patch recommendation

No Section 8 logic patch is recommended.

One **COMMENT_ONLY / naming cleanup** item should be queued for the later commentary and artifact-polish pass:

```text
The QA file/query label “feasible_customers” should be renamed to
“feasible_counteroffers” or “feasible_synthetic_applicants.”
```

This does not affect runtime logic, but it would improve boundary discipline because Module 2 outputs are simulated strategy outcomes on synthetic applicants, not real customer treatment.

## Items to monitor in Section 9

1. **Final counteroffer count**  
   Expected final `COUNTEROFFER` count should be 19,067 if Section 9 confirms only feasible counteroffers.

2. **Failed counteroffer resolution**  
   Since `failed_counteroffer_resolution = MANUAL_REVIEW`, the 2,219 failed counteroffers should resolve to final `MANUAL_REVIEW`.

3. **Expected final manual-review count**  
   Expected final `MANUAL_REVIEW` count should be approximately:

   ```text
   4,720 preliminary manual review
   + 2,219 failed counteroffers
   = 6,939
   ```

4. **Expected final decision distribution**  
   Based on Section 8, Section 9 should likely produce:

   | Final outcome | Expected rows |
   |---|---:|
   | `APPROVE` | 11,291 |
   | `COUNTEROFFER` | 19,067 |
   | `MANUAL_REVIEW` | 6,939 |
   | `DECLINE` | 12,703 |

5. **Reason-code implications for failed counteroffers**  
   Section 10 should later assign manual-review reason codes that explain `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT`, `COUNTEROFFER_EXCEEDS_MAX_REDUCTION`, and `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` cases.

Next recommended review: Section 9 final decision resolution QA.
<!-- END_MESSAGE C038-M00316 -->


---

<a id="c038-m00318"></a>

### C038-M00318

**Andrew** · 2026-05-07T14:00:47.694000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00318 -->
review section 9 QA:
<!-- END_MESSAGE C038-M00318 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.4_QA_local_final_decision_resolution_sanity_simulated_offer_exposure.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.5_QA_local_final_decision_resolution_sanity_preliminary_decision_outcome_x_final_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.6_QA_local_final_decision_resolution_sanity_exposure_treatment_status_x_final_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.7_QA_local_final_decision_resolution_sanity_counteroffer_feasibility_pass_x_final_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.8_QA_local_final_decision_resolution_sanity_counteroffer_feasibility_failure_reason_x_final_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.9_QA_local_final_decision_resolution_sanity_product_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.10_QA_local_final_decision_resolution_sanity_score_band_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.11_QA_local_final_decision_resolution_sanity_strategy_risk_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.12_QA_local_final_decision_resolution_sanity_requested_pti_bucket_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.13_QA_local_final_decision_resolution_sanity_requested_exposure_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.14_QA_local_final_decision_resolution_sanity_requested_expected_loss_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.15_QA_local_final_decision_resolution_sanity_mixed_signal_profile_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.16_QA_local_final_decision_resolution_sanity_borderline_profile_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.17_QA_local_final_decision_resolution_sanity_average_requested_amount_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.18_QA_local_final_decision_resolution_sanity_average_approved_amount_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.19_QA_local_final_decision_resolution_sanity_average_requested_and_approved_pti_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.20_QA_local_final_decision_resolution_sanity_average_requested_and_approved_expected_loss_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.1_QA_local_final_decision_resolution_sanity_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.2_QA_local_final_decision_resolution_sanity_decision_path.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.3_QA_local_final_decision_resolution_sanity_decision_resolution_source.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00326"></a>

### C038-M00326

**ChatGPT** · 2026-05-07T14:05:25.215403-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00326 -->
## Section 9 QA review — Final Decision Resolution Layer

**Verdict: PASS with monitoring notes.**

Section 9 is behaving as designed. It correctly resolves preliminary routing plus Section 8 exposure-treatment feasibility into final simulated strategy outcomes.

No blocker, high-severity issue, or logic patch is indicated.

Section 9 is doing the intended conversion:

```text
Preliminary route
+ exposure treatment / counteroffer feasibility
+ failed-counteroffer resolution parameter
→ final simulated decision_outcome
→ final flags
→ final approved exposure and economics
```

It still correctly defers simulated reason-code assignment to Section 10.

---

## 1. Final decision outcome distribution

| Final decision outcome | Rows | Share |
|---|---:|---:|
| `APPROVE` | 11,291 | 22.58% |
| `COUNTEROFFER` | 19,067 | 38.13% |
| `MANUAL_REVIEW` | 6,939 | 13.88% |
| `DECLINE` | 12,703 | 25.41% |

**Assessment: PASS.**

This matches the expected Section 8-to-Section 9 resolution exactly:

```text
APPROVE = 11,291 preliminary approvals
COUNTEROFFER = 19,067 feasible counteroffers
MANUAL_REVIEW = 4,720 preliminary manual reviews + 2,219 failed counteroffers
DECLINE = 12,703 preliminary declines
```

The final distribution is coherent and audit-readable.

---

## 2. Decision path and resolution source

| Decision path | Rows | Assessment |
|---|---:|---|
| `APPROVE_AS_REQUESTED` | 11,291 | PASS |
| `COUNTEROFFER_FEASIBLE` | 19,067 | PASS |
| `COUNTEROFFER_NOT_FEASIBLE_REVIEW` | 2,219 | PASS |
| `HARD_POLICY_STOP` | 5,889 | PASS |
| `MANUAL_REVIEW_CANDIDATE` | 4,720 | PASS |
| `SEVERE_DTI_CAPACITY` | 445 | PASS |
| `SEVERE_SYNTHETIC_RISK` | 6,369 | PASS |

Resolution sources also reconcile:

| Resolution source | Rows |
|---|---:|
| `PRELIMINARY_APPROVE_CONFIRMED` | 11,291 |
| `COUNTEROFFER_FEASIBILITY_CONFIRMED` | 19,067 |
| `COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW` | 2,219 |
| `PRELIMINARY_DECLINE_CONFIRMED` | 12,703 |
| `PRELIMINARY_MANUAL_REVIEW_CONFIRMED` | 4,720 |

**Assessment: PASS.**

The final paths are deterministic and align to the accepted Section 9 hierarchy. Failed counteroffers are resolving to manual review because the active parameter is:

```text
failed_counteroffer_resolution = MANUAL_REVIEW
```

No residual fallback path appears, which is a positive sign for this smoke-test run.

---

## 3. Preliminary-to-final reconciliation

| Preliminary outcome | Final outcome | Rows | Assessment |
|---|---|---:|---|
| `APPROVE` | `APPROVE` | 11,291 | PASS |
| `COUNTEROFFER` | `COUNTEROFFER` | 19,067 | PASS |
| `COUNTEROFFER` | `MANUAL_REVIEW` | 2,219 | PASS |
| `DECLINE` | `DECLINE` | 12,703 | PASS |
| `MANUAL_REVIEW` | `MANUAL_REVIEW` | 4,720 | PASS |

**Assessment: PASS.**

This is exactly the intended resolution behavior:

- clean preliminary approvals become final `APPROVE`;
- feasible preliminary counteroffers become final `COUNTEROFFER`;
- infeasible preliminary counteroffers become final `MANUAL_REVIEW`;
- preliminary declines remain final `DECLINE`;
- preliminary manual reviews remain unresolved final `MANUAL_REVIEW`.

No unexpected outcome migration appears.

---

## 4. Counteroffer feasibility resolution

| Feasibility result | Final outcome | Rows |
|---|---|---:|
| `TRUE` | `COUNTEROFFER` | 19,067 |
| `FALSE` | `MANUAL_REVIEW` | 2,219 |
| `NULL` | `APPROVE` | 11,291 |
| `NULL` | `DECLINE` | 12,703 |
| `NULL` | `MANUAL_REVIEW` | 4,720 |

**Assessment: PASS.**

Only feasible counteroffers become final `COUNTEROFFER`.

All failed counteroffers become final `MANUAL_REVIEW`, consistent with the active failed-counteroffer resolution parameter.

Failure reasons are preserved:

| Counteroffer feasibility failure reason | Final outcome | Rows |
|---|---|---:|
| `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT` | `MANUAL_REVIEW` | 2,070 |
| `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` | `MANUAL_REVIEW` | 89 |
| `COUNTEROFFER_EXCEEDS_MAX_REDUCTION` | `MANUAL_REVIEW` | 60 |

These should become important inputs to Section 10 simulated reason-code assignment.

---

## 5. Simulated offer-exposure flag

| `simulated_offer_exposure_flag` | Rows | Share |
|---|---:|---:|
| `TRUE` | 30,358 | 60.72% |
| `FALSE` | 19,642 | 39.28% |

**Assessment: PASS.**

This reconciles exactly:

```text
TRUE  = APPROVE + COUNTEROFFER = 11,291 + 19,067 = 30,358
FALSE = MANUAL_REVIEW + DECLINE = 6,939 + 12,703 = 19,642
```

The flag is being used correctly as a simulated positive offer-exposure indicator. It does not imply real account creation, funding, operational approval, or real applicant treatment.

---

## 6. Approved amount conventions

| Final outcome | Avg requested amount | Avg approved amount | Assessment |
|---|---:|---:|---|
| `APPROVE` | 112,594 | 112,594 | PASS |
| `COUNTEROFFER` | 176,816 | 136,792 | PASS |
| `MANUAL_REVIEW` | 112,763 | NULL | PASS |
| `DECLINE` | 97,721 | 0 | PASS |

**Assessment: PASS.**

The amount conventions hold:

- `APPROVE` preserves requested amount.
- `COUNTEROFFER` has approved amount below requested amount.
- `MANUAL_REVIEW` remains unresolved with null approved amount.
- `DECLINE` has zero approved amount.

The average counteroffer reduction is approximately:

```text
176,816 - 136,792 = 40,024
```

That is a meaningful but not excessive reduction.

---

## 7. Approved PTI conventions

| Final outcome | Avg requested PTI | Avg approved PTI | Assessment |
|---|---:|---:|---|
| `APPROVE` | 0.0861 | 0.0861 | PASS |
| `COUNTEROFFER` | 0.1853 | 0.1435 | PASS |
| `MANUAL_REVIEW` | 0.1443 | NULL | PASS |
| `DECLINE` | 0.2161 | 0 | PASS |

**Assessment: PASS.**

This confirms that counteroffers reduce simulated approved-payment affordability pressure:

```text
Counteroffer avg requested PTI: 18.53%
Counteroffer avg approved PTI:  14.35%
```

That is a strong validation result for the exposure-treatment logic. The approved PTI proxy is being calculated after exposure treatment, while requested PTI remains the original Module 1 requested-structure PTI.

---

## 8. Approved Expected Loss conventions

| Final outcome | Avg requested Expected Loss | Avg approved Expected Loss | Assessment |
|---|---:|---:|---|
| `APPROVE` | 765.74 | 765.74 | PASS |
| `COUNTEROFFER` | 3,474.72 | 2,637.22 | PASS |
| `MANUAL_REVIEW` | 4,535.33 | NULL | PASS |
| `DECLINE` | 10,475.04 | 0 | PASS |

**Assessment: PASS.**

The Expected Loss conventions hold:

- `APPROVE` preserves requested-exposure Expected Loss.
- `COUNTEROFFER` reduces approved-exposure Expected Loss.
- `MANUAL_REVIEW` remains unresolved.
- `DECLINE` follows the zero-exposure convention.

Counteroffers reduce average Expected Loss by approximately:

```text
3,474.72 - 2,637.22 = 837.50
```

That confirms `approved_expected_loss_amount` is based on approved exposure, not requested exposure.

This remains consistent with the Module 1 boundary that `estimated_pd` is the synthetic estimated-PD proxy used for simulation and Expected Loss comparison, not a calibrated production default model. fileciteturn4file1

---

## 9. Product-level final outcomes

Product-level final outcomes are balanced and interpretable.

| Product | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `AUTO_LOAN` | 2,789 | 3,167 | 1,515 | 2,475 | PASS |
| `HELOC` | 1,126 | 1,872 | 598 | 1,366 | PASS |
| `MORTGAGE` | 3,233 | 5,848 | 1,969 | 4,015 | PASS |
| `REVOLVING_LINE` | 2,603 | 5,231 | 1,696 | 2,925 | PASS |
| `UNSECURED_PERSONAL_LOAN` | 1,540 | 2,949 | 1,161 | 1,922 | PASS |

**Assessment: PASS.**

No product collapses into a single outcome. Product-specific behavior is differentiated:

- Mortgage has the largest counteroffer count, consistent with exposure and affordability treatment.
- Revolving Line and Unsecured Personal Loan have substantial counteroffer volumes, consistent with unsecured / revolving exposure sensitivity.
- Decline averages show the highest synthetic estimated-PD proxy and requested Expected Loss across all products.

This is consistent with the Module 1 design thesis that product structure materially shapes affordability, risk, and Expected Loss behavior. fileciteturn4file1

---

## 10. Score-band final outcomes

| Score band | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `SUPER_PRIME` | 4,947 | 3,611 | 375 | 51 | PASS |
| `PRIME` | 5,784 | 5,657 | 2,160 | 386 | PASS |
| `NEAR_PRIME` | 560 | 8,818 | 1,490 | 1,205 | PASS |
| `SUBPRIME` | 0 | 980 | 2,898 | 5,024 | PASS |
| `DEEP_SUBPRIME` | 0 | 1 | 16 | 6,037 | PASS |

**Assessment: PASS.**

This is directionally strong:

- `SUPER_PRIME` and `PRIME` retain most clean approvals.
- `NEAR_PRIME` becomes mostly counteroffer, with some review and decline.
- `SUBPRIME` shifts heavily to decline and manual review.
- `DEEP_SUBPRIME` is almost entirely decline.

The one Deep Subprime counteroffer and 16 manual reviews are not defects; they are small edge-case populations preserved by the staged risk and feasibility logic. They should be visible later in Section 14 edge-case diagnostics.

---

## 11. Synthetic risk tier final outcomes

| Synthetic risk tier | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `LOW_SYNTHETIC_RISK` | 9,467 | 6,026 | 1,573 | 56 | PASS |
| `MODERATE_SYNTHETIC_RISK` | 1,824 | 3,306 | 1,425 | 258 | PASS |
| `ELEVATED_SYNTHETIC_RISK` | 0 | 7,979 | 290 | 414 | PASS |
| `HIGH_SYNTHETIC_RISK` | 0 | 1,756 | 3,651 | 1,005 | PASS |
| `SEVERE_SYNTHETIC_RISK` | 0 | 0 | 0 | 10,970 | PASS |

**Assessment: PASS.**

This is one of the strongest Section 9 results.

- Severe synthetic risk resolves entirely to final `DECLINE`.
- No high, elevated, or severe synthetic risk rows receive final `APPROVE`.
- Low and moderate synthetic risk tiers contain the clean approval population.
- High synthetic risk moves mostly to manual review, counteroffer, or decline.

This confirms the final decision hierarchy is preserving the synthetic estimated-risk ordering established upstream.

---

## 12. Requested PTI final outcomes

| Requested PTI bucket | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `LOW_REQUESTED_PTI` | 11,008 | 11,577 | 4,953 | 6,787 | PASS |
| `MODERATE_REQUESTED_PTI` | 283 | 1,344 | 799 | 1,289 | PASS |
| `ELEVATED_REQUESTED_PTI` | 0 | 5,125 | 713 | 2,872 | PASS |
| `HIGH_REQUESTED_PTI` | 0 | 1,020 | 358 | 948 | PASS |
| `SEVERE_REQUESTED_PTI` | 0 | 1 | 116 | 807 | PASS |

**Assessment: PASS.**

No elevated, high, or severe requested PTI rows receive final clean approval.

Counteroffers reduce approved PTI across buckets, and severe requested PTI is almost entirely decline or manual review, with one feasible counteroffer. This aligns with the strategy logic.

---

## 13. Requested exposure tier final outcomes

| Requested exposure tier | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `WITHIN_PRODUCT_LIMITS` | 11,291 | 10,162 | 5,843 | 10,076 | PASS |
| `ABOVE_PRODUCT_APPROVAL_CAP` | 0 | 8,905 | 1,096 | 2,627 | PASS |

**Assessment: PASS.**

Above-product-cap rows never become final clean approvals. They resolve to counteroffer, manual review, or decline.

This is exactly the desired exposure-policy behavior.

---

## 14. Requested Expected Loss tier final outcomes

| Requested Expected Loss tier | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `LOW_REQUESTED_EL` | 11,114 | 10,413 | 3,626 | 1,005 | PASS |
| `MODERATE_REQUESTED_EL` | 177 | 4,685 | 1,304 | 2,243 | PASS |
| `ELEVATED_REQUESTED_EL` | 0 | 3,969 | 509 | 3,413 | PASS |
| `HIGH_REQUESTED_EL` | 0 | 0 | 1,413 | 4,140 | PASS |
| `SEVERE_REQUESTED_EL` | 0 | 0 | 87 | 1,902 | PASS |

**Assessment: PASS.**

High and severe requested Expected Loss rows do not receive final clean approval or final counteroffer. They resolve to review or decline.

This is a strong final decision-resolution outcome and confirms that approved-exposure feasibility is filtering high requested-exposure Expected Loss pressure appropriately.

---

## 15. Mixed-signal and borderline final outcomes

Mixed-signal outcomes are interpretable:

| Mixed-signal profile | Key final pattern | Assessment |
|---|---|---|
| `STRONG_CREDIT_HIGH_PTI` | mostly counteroffer | PASS |
| `WEAK_CREDIT_LOW_PTI` | mostly decline / review, some counteroffer | PASS |
| `LARGE_EXPOSURE_LOW_RISK` | mostly counteroffer | PASS |
| `HIGH_RISK_LOW_EXPOSURE` | mostly decline | PASS |
| `HIGH_DTI_LOW_REQUESTED_PTI` | all decline | PASS |
| `MULTIPLE_MIXED_SIGNALS` | mostly decline, some review/counteroffer | PASS |

Borderline rows behave conservatively:

| Borderline flag | Approve | Counteroffer | Manual review | Decline |
|---|---:|---:|---:|---:|
| `FALSE` | 11,291 | 12,509 | 2,650 | 6,213 |
| `TRUE` | 0 | 6,558 | 4,289 | 6,490 |

**Assessment: PASS / monitor.**

No borderline rows receive final clean approval. That is conservative but coherent with the current strategy design.

Borderline rows are not all manually reviewed; many become counteroffers or declines. That confirms final decision resolution is not treating borderline status as a single automatic outcome.

---

## 16. Final Section 9 acceptance conclusion

Section 9 passes.

Accepted evidence:

- Final outcome row counts reconcile to 50,000.
- Final outcome distribution matches Section 8 expectations exactly.
- Preliminary approvals become final approvals.
- Feasible counteroffers become final counteroffers.
- Failed counteroffers resolve to final manual review under `failed_counteroffer_resolution = MANUAL_REVIEW`.
- Preliminary declines remain final declines.
- Preliminary manual reviews remain unresolved final manual reviews.
- `simulated_offer_exposure_flag` reconciles exactly to `APPROVE + COUNTEROFFER`.
- `APPROVE` rows preserve requested amount, requested PTI, and requested Expected Loss.
- `COUNTEROFFER` rows reduce approved amount, approved PTI, and approved Expected Loss.
- `MANUAL_REVIEW` rows keep approved exposure and approved economics null.
- `DECLINE` rows follow the zero-exposure convention.
- Product-level outcomes are differentiated and plausible.
- Score-band outcomes are directionally coherent.
- Synthetic risk tier outcomes are strongly ordered.
- Requested PTI, exposure, and requested Expected Loss outcomes align to strategy pressure.
- Mixed-signal and borderline profiles remain visible and explainable.
- No reason codes are assigned in Section 9.
- No latest-run final output table is created in Section 9.
- No archive rows are inserted in Section 9.

## Patch recommendation

No Section 9 patch is recommended.

## Items to monitor in Section 10

1. **Failed counteroffer reason assignment**  
   The 2,219 failed counteroffers should receive manual-review reason codes that clearly distinguish:
   - `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT`
   - `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT`
   - `COUNTEROFFER_EXCEEDS_MAX_REDUCTION`

2. **Counteroffer reason family alignment**  
   The 19,067 final counteroffers should receive `COUNTEROFFER` family primary reasons.

3. **Approval reason convention**  
   The 11,291 final approvals should receive:
   ```text
   APPROVED_AS_REQUESTED
   ```

4. **Decline reason hierarchy**  
   The 12,703 final declines should be explained through hard simulated policy stops, severe synthetic estimated-risk, severe DTI, high requested PTI, high requested Expected Loss, or exposure-limit paths.

5. **Manual-review reason coverage**  
   The 6,939 final manual-review rows should have non-null primary reason codes and should not be explained by approval or policy-stop reason families.

Next recommended review: **Section 10 simulated reason-code assignment QA.**
<!-- END_MESSAGE C038-M00326 -->


---

<a id="c038-m00327"></a>

### C038-M00327

**Andrew** · 2026-05-07T14:16:54.336000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00327 -->
review_section_10 QA:
<!-- END_MESSAGE C038-M00327 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.6_QA_local_staging_sanity_checks_secondary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.7_QA_local_staging_sanity_checks_tertiary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.8_QA_local_staging_sanity_checks_product_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.9_QA_local_staging_sanity_checks_score_band_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.10_QA_local_staging_sanity_checks_strategy_risk_tier_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.11_QA_local_staging_sanity_checks_requested_pti_bucket_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.12_QA_local_staging_sanity_checks_decision_path_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.13_QA_local_staging_sanity_checks_counteroffer_family_failure_reason_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.14_QA_local_staging_sanity_checks_mixed_signal_profile_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.15_QA_local_staging_sanity_checks_borderline_profile_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.16_QA_local_staging_sanity_checks_sample_reason_code_trace.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.1_QA_local_staging_sanity_checks_decision_outcome_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.2_QA_local_staging_sanity_checks_decision_outcome_x_primary_reason_family.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.3_QA_local_staging_sanity_checks_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.4_QA_local_staging_sanity_checks_primary_reason_family.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_10.4.5_QA_local_staging_sanity_checks_average_reason_code_x_decision_outcome.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00335"></a>

### C038-M00335

**ChatGPT** · 2026-05-07T14:20:44.053951-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00335 -->
## Section 10 QA review — Simulated Reason-Code Assignment Layer

**Verdict: PASS with one optional QA-display improvement.**

Section 10 is behaving as designed. It correctly assigns simulated strategy explanation codes after final decision resolution, preserves outcome-family alignment, uses deterministic priority ranking, and keeps approval, counteroffer, manual-review, and policy-stop explanations separated.

No blocker, high-severity issue, or logic patch is indicated.

Section 10 is doing the intended conversion:

```text
Final decision outcome
+ final decision path
+ rule-trigger diagnostics
+ exposure-treatment diagnostics
+ counteroffer feasibility diagnostics
→ simulated strategy explanation codes
```

These are simulated strategy explanation codes only. They are not regulatory adverse-action reasons, customer notices, fair-lending conclusions, or production decision explanations. This remains consistent with Module 1’s boundary discipline around synthetic simulation outputs and the synthetic estimated-PD proxy framework. fileciteturn4file1

---

## 1. Outcome × primary reason-code alignment

**Assessment: PASS.**

Primary reason-code assignment is complete and outcome-aligned.

| Final outcome | Primary reason pattern | Rows | Assessment |
|---|---|---:|---|
| `APPROVE` | `APPROVED_AS_REQUESTED` | 11,291 | PASS |
| `COUNTEROFFER` | four `COUNTEROFFER_*` reasons | 19,067 | PASS |
| `MANUAL_REVIEW` | six `MANUAL_REVIEW_*` reasons | 6,939 | PASS |
| `DECLINE` | five `POLICY_STOP_*` reasons | 12,703 | PASS |

Total rows reconcile to:

```text
11,291 + 19,067 + 6,939 + 12,703 = 50,000
```

No outcome-family leakage is visible in the uploaded QA outputs.

---

## 2. Primary reason-family reconciliation

**Assessment: PASS.**

| Decision outcome | Primary reason family | Rows |
|---|---|---:|
| `APPROVE` | `APPROVAL` | 11,291 |
| `COUNTEROFFER` | `COUNTEROFFER` | 19,067 |
| `MANUAL_REVIEW` | `MANUAL_REVIEW` | 6,939 |
| `DECLINE` | `POLICY_STOP` | 12,703 |

This is exactly the intended Section 10 family alignment:

```text
APPROVE        → APPROVAL
COUNTEROFFER   → COUNTEROFFER
MANUAL_REVIEW  → MANUAL_REVIEW
DECLINE        → POLICY_STOP
```

No patch is recommended.

---

## 3. Primary reason-code distribution

**Assessment: PASS.**

| Primary reason code | Rows | Share |
|---|---:|---:|
| `APPROVED_AS_REQUESTED` | 11,291 | 22.58% |
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 8,905 | 17.81% |
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 6,369 | 12.74% |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 5,021 | 10.04% |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 3,853 | 7.71% |
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 2,961 | 5.92% |
| `POLICY_STOP_RECENT_DELINQUENCY` | 2,955 | 5.91% |
| `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 2,130 | 4.26% |
| `POLICY_STOP_MAJOR_DEROGATORY` | 2,107 | 4.21% |
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 1,288 | 2.58% |
| Other reason codes | remaining rows | smaller shares |

This distribution is interpretable. The largest non-approval reasons are product exposure constraints, severe synthetic estimated-risk policy stops, affordability-based counteroffer treatment, and recent delinquency / major derogatory policy-stop paths.

No single non-approval explanation dominates the output in a way that suggests reason-code collapse.

---

## 4. Approval reason convention

**Assessment: PASS.**

All final approvals receive:

```text
primary_reason_code = APPROVED_AS_REQUESTED
primary_reason_family = APPROVAL
reason_code_count = 1
```

The Section 10 QA shows:

```text
APPROVE rows = 11,291
average reason_code_count = 1.00
min reason_code_count = 1
max reason_code_count = 1
```

That is exactly the locked approval convention.

---

## 5. Counteroffer reason-code behavior

**Assessment: PASS.**

Final counteroffers receive outcome-family-aligned `COUNTEROFFER_*` primary reasons:

| Counteroffer primary reason | Rows | Interpretation |
|---|---:|---|
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 8,905 | Reduced-exposure treatment driven primarily by product cap / exposure limit pressure |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 5,021 | Reduced-exposure treatment driven primarily by requested affordability pressure |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 3,853 | Reduced-exposure treatment driven by elevated synthetic estimated-risk exposure sensitivity |
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 1,288 | Reduced-exposure treatment driven by approved Expected Loss cap pressure |

This is strong. Counteroffer explanations are not generic; they distinguish product exposure, affordability, synthetic risk, and approved Expected Loss constraints.

The counteroffer average reason-code count is:

```text
avg = 1.725
min = 1
max = 5
```

That is appropriate. Many counteroffers have one clear driver, while others carry secondary / tertiary diagnostics where multiple constraints applied.

---

## 6. Manual-review reason-code behavior

**Assessment: PASS.**

Final manual-review rows receive outcome-family-aligned `MANUAL_REVIEW_*` primary reasons:

| Manual-review primary reason | Rows | Interpretation |
|---|---:|---|
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 2,961 | Borderline synthetic-risk / threshold-adjacent review |
| `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 2,130 | Failed counteroffer due minimum viable offer / reduction constraint |
| `MANUAL_REVIEW_MIXED_SIGNAL_PROFILE` | 958 | Mixed-signal unresolved profile |
| `MANUAL_REVIEW_ELEVATED_DTI` | 658 | Existing-obligation capacity review |
| `MANUAL_REVIEW_ELEVATED_SYNTHETIC_RISK` | 143 | Elevated synthetic estimated-risk review |
| `MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED` | 89 | Counteroffer did not produce reduced exposure |

This is exactly what Section 10 should produce. Manual-review reasons explain unresolved strategy handling, not final no-offer policy stops.

The manual-review average reason-code count is:

```text
avg = 3.362
min = 1
max = 9
```

That is higher than other outcomes, but appropriate. Manual-review rows often exist because multiple diagnostics overlap: failed counteroffer, mixed-signal profile, borderline status, elevated synthetic risk, DTI, or requested-structure stress.

---

## 7. Failed counteroffer reason alignment

**Assessment: PASS.**

The Section 10 targeted patch worked.

| Section 8 failure reason | Section 10 primary reason | Rows | Assessment |
|---|---|---:|---|
| `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT` | `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 2,070 | PASS |
| `COUNTEROFFER_EXCEEDS_MAX_REDUCTION` | `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 60 | PASS |
| `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` | `MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED` | 89 | PASS |

The key accepted improvement is visible:

```text
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT
→ MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED
```

That preserves the distinction between “offer not reduced” and “offer below minimum viable amount.”

The secondary reason-code output also shows:

```text
MANUAL_REVIEW_COUNTEROFFER_NOT_FEASIBLE = 2,219
```

That is appropriate as a secondary diagnostic for failed counteroffer rows after the more specific primary reason has been assigned.

---

## 8. Decline / policy-stop reason-code behavior

**Assessment: PASS.**

Final declines receive outcome-family-aligned `POLICY_STOP_*` primary reasons:

| Decline primary reason | Rows | Interpretation |
|---|---:|---|
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 6,369 | Severe synthetic estimated-risk route |
| `POLICY_STOP_RECENT_DELINQUENCY` | 2,955 | Severe delinquency / recent delinquency route |
| `POLICY_STOP_MAJOR_DEROGATORY` | 2,107 | Major derogatory route |
| `POLICY_STOP_BANKRUPTCY_FLAG` | 827 | Bankruptcy policy-stop route |
| `POLICY_STOP_HIGH_DTI` | 445 | Severe DTI capacity route |

This aligns to the accepted priority hierarchy:

```text
hard simulated policy stop
→ severe synthetic estimated-risk
→ severe DTI
→ other policy-stop / requested-structure diagnostics
```

The decline average reason-code count is:

```text
avg = 1.812
min = 1
max = 6
```

That indicates most declines have a clear primary reason, with secondary and tertiary diagnostics where additional policy-stop conditions apply.

---

## 9. Requested PTI / requested Expected Loss candidate behavior

**Assessment: PASS with interpretation note.**

The targeted Section 10 patches for requested PTI and requested Expected Loss are functioning as diagnostic candidates, but they do not appear as primary reasons in this run.

They appear as secondary / tertiary reasons:

```text
POLICY_STOP_HIGH_REQUESTED_PTI
POLICY_STOP_HIGH_REQUESTED_EXPECTED_LOSS
```

This is not a defect. It means higher-priority decline reasons — especially severe synthetic estimated-risk, recent delinquency, major derogatory, bankruptcy, or high DTI — took primary reason priority in final `DECLINE` rows.

That is consistent with the accepted reason hierarchy. Requested PTI and requested Expected Loss still remain visible as additional diagnostics where they apply.

No patch is recommended.

---

## 10. Secondary and tertiary reason-code behavior

**Assessment: PASS.**

Secondary reason codes are populated for rows with additional outcome-family-aligned diagnostics. Null secondary reasons are expected where only one reason applies.

Key secondary diagnostics include:

| Secondary reason code | Rows |
|---|---:|
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 2,400 |
| `MANUAL_REVIEW_COUNTEROFFER_NOT_FEASIBLE` | 2,219 |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 1,836 |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 1,594 |
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 3,572 |
| `POLICY_STOP_HIGH_DTI` | 1,022 |
| `MANUAL_REVIEW_ELEVATED_SYNTHETIC_RISK` | 1,098 |
| `MANUAL_REVIEW_ELEVATED_DTI` | 1,025 |
| `NULL` | 32,426 |

Tertiary diagnostics include:

| Tertiary reason code | Rows |
|---|---:|
| `COUNTEROFFER_MULTIPLE_CONSTRAINTS` | 2,904 |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 1,922 |
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 1,328 |
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 885 |
| `POLICY_STOP_HIGH_REQUESTED_EXPECTED_LOSS` | 784 |
| `NULL` | 38,762 |

This supports the intended design:

```text
primary reason = controlling explanation
secondary / tertiary reasons = additional diagnostics
```

No issue indicated.

---

## 11. Product-level reason-code behavior

**Assessment: PASS.**

Product reason-code patterns are plausible and product-aware.

Examples:

- `MORTGAGE` has `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` as the largest non-approval reason, with 4,230 rows. That is intuitive because mortgage is structurally sensitive to large balance, payment burden, and requested PTI.
- `REVOLVING_LINE` has `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` as the largest non-approval reason, with 3,680 rows.
- `UNSECURED_PERSONAL_LOAN` also shows strong `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` volume, with 1,916 rows.
- `AUTO_LOAN` has a balanced profile across approval, product exposure, synthetic-risk exposure, and policy-stop paths.
- `HELOC` is also product exposure heavy, with 1,262 rows under `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT`.

This is consistent with Module 2’s product-aware thesis and Module 1’s foundation that product structure materially affects exposure, affordability, LGD, and Expected Loss. fileciteturn4file1

---

## 12. Score-band reason-code behavior

**Assessment: PASS.**

Score-band reason-code behavior is directionally strong.

Examples:

- `SUPER_PRIME` is dominated by:
  - `APPROVED_AS_REQUESTED`: 4,947
  - `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT`: 2,909
  - very limited policy-stop activity

- `PRIME` is dominated by:
  - `APPROVED_AS_REQUESTED`: 5,784
  - `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT`: 3,758
  - `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT`: 1,886
  - `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK`: 1,617

- `NEAR_PRIME` shifts heavily into:
  - `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT`: 3,839
  - `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT`: 2,263
  - `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT`: 2,236

- `SUBPRIME` shifts heavily into:
  - `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`: 2,910
  - `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER`: 1,411
  - `POLICY_STOP_RECENT_DELINQUENCY`: 1,065

- `DEEP_SUBPRIME` is overwhelmingly:
  - `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`: 3,459
  - `POLICY_STOP_RECENT_DELINQUENCY`: 1,487
  - `POLICY_STOP_MAJOR_DEROGATORY`: 750
  - `POLICY_STOP_BANKRUPTCY_FLAG`: 341

This is a strong reason-code validation result. Stronger score bands receive approval and exposure-management explanations; weaker score bands receive synthetic-risk and policy-stop explanations. That aligns to the Module 1 validation finding that score-band behavior should preserve directional risk ordering while retaining realistic overlap. fileciteturn4file2

---

## 13. Synthetic risk tier reason-code behavior

**Assessment: PASS.**

Reason-code assignment is coherent by synthetic risk tier:

- `LOW_SYNTHETIC_RISK` is dominated by approvals and product-exposure counteroffers.
- `MODERATE_SYNTHETIC_RISK` contains approvals, affordability/product counteroffers, and borderline review.
- `ELEVATED_SYNTHETIC_RISK` is dominated by counteroffer reasons.
- `HIGH_SYNTHETIC_RISK` is dominated by failed counteroffer review, Expected Loss counteroffers, mixed-signal review, and policy-stop diagnostics.
- `SEVERE_SYNTHETIC_RISK` is entirely in policy-stop family reasons:
  - `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`: 6,369
  - `POLICY_STOP_RECENT_DELINQUENCY`: 2,543
  - `POLICY_STOP_MAJOR_DEROGATORY`: 1,362
  - `POLICY_STOP_BANKRUPTCY_FLAG`: 696

That is exactly the intended behavior. Severe synthetic estimated-risk does not receive approval, counteroffer, or manual-review primary explanation families.

---

## 14. Requested PTI reason-code behavior

**Assessment: PASS.**

Requested PTI reason-code behavior is interpretable:

- Low requested PTI includes approvals, product exposure counteroffers, synthetic-risk exposure counteroffers, and risk-driven policy stops.
- Elevated and high requested PTI are dominated by `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT`.
- Severe requested PTI is dominated by policy-stop reasons, especially severe synthetic estimated-risk and recent delinquency, with 116 failed counteroffer review cases and one feasible counteroffer.

Important: low requested PTI rows can still have policy-stop reasons because low new-payment burden does not override severe synthetic risk, recent delinquency, major derogatory, bankruptcy, or high DTI. That is correct.

---

## 15. Mixed-signal reason-code behavior

**Assessment: PASS.**

Mixed-signal reason-code patterns are highly interpretable:

| Mixed-signal profile | Dominant explanation pattern | Assessment |
|---|---|---|
| `STRONG_CREDIT_HIGH_PTI` | Mostly `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | PASS |
| `LARGE_EXPOSURE_LOW_RISK` | Mostly `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | PASS |
| `WEAK_CREDIT_LOW_PTI` | Mostly `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`, recent delinquency, mixed-signal review, failed counteroffer review | PASS |
| `HIGH_DTI_LOW_REQUESTED_PTI` | Mostly `POLICY_STOP_HIGH_DTI` | PASS |
| `HIGH_RISK_LOW_EXPOSURE` | Mostly severe synthetic-risk / policy-stop explanations | PASS |
| `MULTIPLE_MIXED_SIGNALS` | Mostly severe synthetic-risk / policy-stop and some product exposure / review reasons | PASS |
| `NO_MIXED_SIGNAL_PROFILE` | Broad expected distribution across approvals, counteroffers, policy stops, and review | PASS |

This is strong evidence that Section 10 is not assigning generic reasons to all edge cases. It is preserving the distinct business interpretation of different mixed-signal patterns.

---

## 16. Borderline reason-code behavior

**Assessment: PASS.**

Borderline and non-borderline profiles behave coherently.

For `borderline_profile_flag = TRUE`, the largest reason codes include:

| Primary reason code | Rows |
|---|---:|
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 3,516 |
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 2,961 |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 2,696 |
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 2,098 |
| `POLICY_STOP_RECENT_DELINQUENCY` | 1,385 |
| `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 1,308 |

This is appropriate. Borderline status contributes to manual-review explanation where final outcome is manual review, but it does not override final counteroffer or policy-stop paths.

For `borderline_profile_flag = FALSE`, approvals dominate, which aligns with Section 9’s final outcome pattern.

---

## 17. Sample reason trace

**Assessment: PASS with optional QA-display improvement.**

The uploaded sample reason trace shows correctly populated fields:

```text
application_id
product_type_policy_key
score_band_policy_key
decision_outcome
decision_path
decision_resolution_source
primary_reason_code
secondary_reason_code
tertiary_reason_code
primary_reason_family
reason_priority_rank
reason_code_count
triggered_reason_code_list
```

The displayed sample appears to be dominated by early `APPROVE` rows because it is likely ordered by `application_id` or generated from the first rows encountered. That is not a logic problem.

**Optional QA-display enhancement for later:** revise the sample trace query to return a stratified sample, such as 10 rows per `decision_outcome`, so approval, counteroffer, manual-review, and decline traces are all visible in one QA output.

This is optional and not required before proceeding.

---

## Section 10 acceptance conclusion

Section 10 passes.

Accepted evidence:

- `tmp_m2_stage_7_reason_code_assignment` is populated.
- Final decision outcomes are preserved.
- Primary reason codes are populated for all 50,000 rows.
- Primary reason families reconcile exactly to final decision outcomes.
- `APPROVE` rows receive `APPROVED_AS_REQUESTED`.
- `COUNTEROFFER` rows receive only `COUNTEROFFER` family primary reasons.
- `MANUAL_REVIEW` rows receive only `MANUAL_REVIEW` family primary reasons.
- `DECLINE` rows receive only `POLICY_STOP` family primary reasons.
- Failed counteroffer reasons map correctly to manual-review explanations.
- `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` correctly maps to `MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED`.
- Requested PTI and requested Expected Loss policy-stop diagnostics appear in secondary / tertiary reason codes when higher-priority primary reasons control.
- Secondary and tertiary reason codes provide useful additional diagnostics.
- Product-level reason-code behavior is interpretable.
- Score-band reason-code behavior is directionally coherent.
- Synthetic risk tier reason-code behavior is strongly ordered.
- Mixed-signal and borderline reason-code behavior is explainable.
- No final output table is created in Section 10.
- No archive rows are inserted in Section 10.
- No approved exposure or Expected Loss values are recalculated in Section 10.

## Patch recommendation

No Section 10 logic patch is recommended.

Optional future QA-display patch only:

```text
Revise the sample reason-code trace query to return stratified examples by decision_outcome.
```

That would improve reviewer usability but is not required for runtime acceptance.

## Next recommended review

Proceed to **Section 11 latest-run strategy decision output table QA**.

The main Section 11 checks should confirm:

1. `credit_decisioning_sim.strategy_decisions` exists.
2. Row count remains 50,000.
3. `application_id` remains unique.
4. Section 10 reason-code fields are carried into the latest-run output.
5. Final decision flags reconcile to `decision_outcome`.
6. Approved amount conventions still hold after materialization.
7. Approved Expected Loss conventions still hold after materialization.
8. `archive_run_flag = FALSE` remains present for this smoke test.
9. No archive insert occurred yet.
<!-- END_MESSAGE C038-M00335 -->


---

<a id="c038-m00336"></a>

### C038-M00336

**Andrew** · 2026-05-07T14:40:51.317000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00336 -->
review section 11 QA: 
<!-- END_MESSAGE C038-M00336 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.4_QA_local_latest_run_sanity_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.5_QA_local_latest_run_sanity_primary_reason_family.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.6_QA_local_latest_run_sanity_product_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.7_QA_local_latest_run_sanity_score_band_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.8_QA_local_latest_run_sanity_product_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.9_QA_local_latest_run_sanity_score_band_x_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.10_QA_local_latest_run_sanity_strategy_risk_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.11_QA_local_latest_run_sanity_requested_pti_bucket_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.12_QA_local_latest_run_sanity_mixed_signal_profile_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.13_QA_local_latest_run_sanity_borderline_profile_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.14_QA_local_latest_run_sanity_average_requested_and approved_amount_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.15_QA_local_latest_run_sanity_average_requested_and approved_pti_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.16_QA_local_latest_run_sanity_average_requested_and approved_expected_loss_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.17_QA_local_latest_run_sanity_simulated_offer_exposure_profile.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.1_QA_local_latest_run_sanity_row_application_count.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.2_QA_local_latest_run_sanity_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.3_QA_local_latest_run_sanity_decision_path.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00344"></a>

### C038-M00344

**ChatGPT** · 2026-05-07T14:44:08.525560-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00344 -->
## Section 11 QA review — Latest-Run Strategy Decision Output Table

**Verdict: PASS with one small follow-up confirmation before Section 12.**

Section 11 is behaving as intended. It successfully materializes the accepted Section 10 reason-code assignment layer into the permanent latest-run output table:

```sql
credit_decisioning_sim.strategy_decisions
```

No blocker, high-severity issue, or logic patch is indicated.

The Section 11 QA confirms that the final latest-run table preserved the 50,000-row population, retained unique `application_id` grain, carried final decision outcomes and reason codes, preserved approved exposure conventions, and produced coherent simulated offer-exposure summaries.

---

## 1. Latest-run row integrity

| QA area | Observed result | Assessment |
|---|---:|---|
| Latest-run row count | 50,000 | PASS |
| Distinct `application_id` count | 50,000 | PASS |
| Duplicate application rows | 0 implied | PASS |
| `latest_output_created_ts` | single timestamp across output | PASS |

The latest-run table is unique at `application_id` and preserves the expected 50,000-row Module 1 archive baseline population.

The single `latest_output_created_ts` value is appropriate. It is audit metadata showing when the latest-run table was materialized. It should not be treated as deterministic strategy comparison evidence.

---

## 2. Final decision outcome distribution

| Decision outcome | Rows | Share |
|---|---:|---:|
| `APPROVE` | 11,291 | 22.58% |
| `COUNTEROFFER` | 19,067 | 38.13% |
| `MANUAL_REVIEW` | 6,939 | 13.88% |
| `DECLINE` | 12,703 | 25.41% |

**Assessment: PASS.**

This exactly matches the accepted Section 9 final decision distribution. Section 11 did not lose, duplicate, or alter final outcome rows during permanent table materialization.

---

## 3. Final decision path distribution

| Decision path | Rows | Assessment |
|---|---:|---|
| `APPROVE_AS_REQUESTED` | 11,291 | PASS |
| `COUNTEROFFER_FEASIBLE` | 19,067 | PASS |
| `COUNTEROFFER_NOT_FEASIBLE_REVIEW` | 2,219 | PASS |
| `HARD_POLICY_STOP` | 5,889 | PASS |
| `MANUAL_REVIEW_CANDIDATE` | 4,720 | PASS |
| `SEVERE_DTI_CAPACITY` | 445 | PASS |
| `SEVERE_SYNTHETIC_RISK` | 6,369 | PASS |

The permanent output preserves the final decision path taxonomy from Section 9. No unexpected path appears.

---

## 4. Reason-code preservation

**Assessment: PASS.**

Primary reason families reconcile exactly to final decision outcomes:

| Primary reason family | Rows | Expected outcome family |
|---|---:|---|
| `APPROVAL` | 11,291 | `APPROVE` |
| `COUNTEROFFER` | 19,067 | `COUNTEROFFER` |
| `MANUAL_REVIEW` | 6,939 | `MANUAL_REVIEW` |
| `POLICY_STOP` | 12,703 | `DECLINE` |

Primary reason-code distribution is also preserved from Section 10:

| Primary reason code | Rows |
|---|---:|
| `APPROVED_AS_REQUESTED` | 11,291 |
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 8,905 |
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 6,369 |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 5,021 |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 3,853 |
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 2,961 |
| `POLICY_STOP_RECENT_DELINQUENCY` | 2,955 |
| `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 2,130 |
| `POLICY_STOP_MAJOR_DEROGATORY` | 2,107 |
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 1,288 |
| Other reason codes | smaller populations |

This confirms Section 11 carried the simulated strategy explanation codes into the latest-run output table.

Reason codes remain simulated strategy explanation codes. They are not regulatory adverse-action reasons, customer notices, fair-lending conclusions, or production decision explanations. That boundary remains aligned with the Module 1 synthetic simulation discipline and the requirement that `estimated_pd` be interpreted as a synthetic estimated-PD proxy rather than a calibrated PD model. fileciteturn4file1

---

## 5. Product × final decision outcome

| Product | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `AUTO_LOAN` | 2,789 | 3,167 | 1,515 | 2,475 | PASS |
| `HELOC` | 1,126 | 1,872 | 598 | 1,366 | PASS |
| `MORTGAGE` | 3,233 | 5,848 | 1,969 | 4,015 | PASS |
| `REVOLVING_LINE` | 2,603 | 5,231 | 1,696 | 2,925 | PASS |
| `UNSECURED_PERSONAL_LOAN` | 1,540 | 2,949 | 1,161 | 1,922 | PASS |

Product-level outcomes remain differentiated and plausible.

No product collapses into a single outcome. Mortgage, Revolving Line, and Unsecured Personal Loan have substantial counteroffer volume, which is consistent with the product-aware exposure / affordability / Expected Loss framework. Module 1 established product structure as a major driver of exposure, payment burden, PTI, LGD, and Expected Loss behavior; Section 11 preserves that downstream strategy differentiation. fileciteturn4file1

---

## 6. Score-band × final decision outcome

| Score band | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `SUPER_PRIME` | 4,947 | 3,611 | 375 | 51 | PASS |
| `PRIME` | 5,784 | 5,657 | 2,160 | 386 | PASS |
| `NEAR_PRIME` | 560 | 8,818 | 1,490 | 1,205 | PASS |
| `SUBPRIME` | 0 | 980 | 2,898 | 5,024 | PASS |
| `DEEP_SUBPRIME` | 0 | 1 | 16 | 6,037 | PASS |

This is directionally strong.

Stronger score bands show higher approval and simulated offer-exposure outcomes. Weaker score bands show higher manual-review and decline outcomes. The small Deep Subprime counteroffer / manual-review population remains an edge-case population, not a structural issue.

This is consistent with Module 1 validation, which confirmed directional score-band ordering while preserving realistic mixed-signal overlap. fileciteturn4file2

---

## 7. Synthetic estimated-risk tier × final decision outcome

| Synthetic risk tier | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `LOW_SYNTHETIC_RISK` | 9,467 | 6,026 | 1,573 | 56 | PASS |
| `MODERATE_SYNTHETIC_RISK` | 1,824 | 3,306 | 1,425 | 258 | PASS |
| `ELEVATED_SYNTHETIC_RISK` | 0 | 7,979 | 290 | 414 | PASS |
| `HIGH_SYNTHETIC_RISK` | 0 | 1,756 | 3,651 | 1,005 | PASS |
| `SEVERE_SYNTHETIC_RISK` | 0 | 0 | 0 | 10,970 | PASS |

This is one of the strongest Section 11 validation outputs.

No severe synthetic risk row receives approval, counteroffer, or manual review in the latest-run output. Severe synthetic risk is entirely final `DECLINE`, as designed.

The average synthetic estimated-PD proxy values by outcome remain directionally ordered within risk tiers. Section 11 therefore preserves the final risk-ordering behavior accepted in Sections 7–10.

---

## 8. Requested PTI bucket × final decision outcome

| Requested PTI bucket | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `LOW_REQUESTED_PTI` | 11,008 | 11,577 | 4,953 | 6,787 | PASS |
| `MODERATE_REQUESTED_PTI` | 283 | 1,344 | 799 | 1,289 | PASS |
| `ELEVATED_REQUESTED_PTI` | 0 | 5,125 | 713 | 2,872 | PASS |
| `HIGH_REQUESTED_PTI` | 0 | 1,020 | 358 | 948 | PASS |
| `SEVERE_REQUESTED_PTI` | 0 | 1 | 116 | 807 | PASS |

No elevated, high, or severe requested PTI rows receive final clean approval. That is a coherent strategy outcome.

Counteroffer rows reduce approved PTI materially across PTI buckets. For example:

| Outcome | Avg requested PTI | Avg approved PTI for offer rows |
|---|---:|---:|
| `APPROVE` | 0.0861 | 0.0861 |
| `COUNTEROFFER` | 0.1853 | 0.1435 |

This confirms Section 11 preserved the distinction between:

```text
requested_payment_to_income_ratio
approved_payment_to_income_ratio
```

Manual-review rows remain unresolved, and decline rows have no simulated offer exposure.

---

## 9. Mixed-signal and borderline outcomes

### Mixed-signal profiles

| Mixed-signal profile | Main outcome pattern | Assessment |
|---|---|---|
| `NO_MIXED_SIGNAL_PROFILE` | approvals, counteroffers, reviews, declines | PASS |
| `STRONG_CREDIT_HIGH_PTI` | mostly counteroffer | PASS |
| `WEAK_CREDIT_LOW_PTI` | mostly decline / manual review, some counteroffer | PASS |
| `LARGE_EXPOSURE_LOW_RISK` | mostly counteroffer | PASS |
| `HIGH_RISK_LOW_EXPOSURE` | mostly decline | PASS |
| `HIGH_DTI_LOW_REQUESTED_PTI` | all decline | PASS |
| `MULTIPLE_MIXED_SIGNALS` | mostly decline, some manual review / counteroffer | PASS |

The mixed-signal distribution remains explainable after permanent materialization.

### Borderline profile flag

| Borderline flag | Approve | Counteroffer | Manual review | Decline |
|---|---:|---:|---:|---:|
| `FALSE` | 11,291 | 12,509 | 2,650 | 6,213 |
| `TRUE` | 0 | 6,558 | 4,289 | 6,490 |

Borderline rows remain conservatively handled. None receive clean approval; they resolve to counteroffer, manual review, or decline.

**Assessment: PASS.**

---

## 10. Approved amount conventions

| Decision outcome | Rows | Avg requested amount | Avg approved amount all apps | Avg approved amount offer rows | Assessment |
|---|---:|---:|---:|---:|---|
| `APPROVE` | 11,291 | 112,594 | 112,594 | 112,594 | PASS |
| `COUNTEROFFER` | 19,067 | 176,816 | 136,792 | 136,792 | PASS |
| `MANUAL_REVIEW` | 6,939 | 112,763 | 0 | NULL | PASS |
| `DECLINE` | 12,703 | 97,721 | 0 | NULL | PASS |

The average values reflect the Section 11 QA metric convention:

```text
avg_approved_amount_all_apps = AVG(COALESCE(approved_amount, 0))
```

That means manual-review rows are treated as zero only for all-application summary math. The source convention remains that manual-review approved exposure is unresolved and should be stored as `NULL`.

**Assessment: PASS.**

---

## 11. Approved Expected Loss conventions

| Decision outcome | Avg requested Expected Loss | Avg approved Expected Loss all apps | Avg approved Expected Loss offer rows | Assessment |
|---|---:|---:|---:|---|
| `APPROVE` | 765.74 | 765.74 | 765.74 | PASS |
| `COUNTEROFFER` | 3,474.72 | 2,637.22 | 2,637.22 | PASS |
| `MANUAL_REVIEW` | 4,535.33 | 0 | NULL | PASS |
| `DECLINE` | 10,475.04 | 0 | NULL | PASS |

This confirms that Section 11 preserved the expected distinction:

```text
requested_expected_loss_amount = requested-exposure Expected Loss from Module 1
approved_expected_loss_amount  = approved-exposure Expected Loss after Module 2 exposure treatment
```

For counteroffers, approved Expected Loss is lower than requested Expected Loss:

```text
3,474.72 → 2,637.22
```

That confirms approved exposure treatment is reflected in final latest-run economics.

Expected Loss remains a comparative simulation metric, not a production loss forecast. That boundary is consistent with Module 1’s Expected Loss interpretation discipline. fileciteturn4file1

---

## 12. Simulated offer-exposure profile

| `simulated_offer_exposure_flag` | Rows | Total approved amount | Avg synthetic estimated-PD proxy | Total approved Expected Loss | Avg approved Expected Loss |
|---|---:|---:|---:|---:|---:|
| `FALSE` | 19,642 | 0 | 0.3166 | 0 | 0 |
| `TRUE` | 30,358 | 3.8795B | 0.0642 | 58.93M | 1,941.16 |

**Assessment: PASS.**

This is a strong latest-run validation output.

Rows with simulated offer exposure are substantially lower risk on average:

```text
Offer rows avg synthetic estimated-PD proxy:     0.0642
Non-offer rows avg synthetic estimated-PD proxy: 0.3166
```

This confirms that the final latest-run output preserves risk ordering between simulated positive offer-exposure outcomes and non-offer / unresolved outcomes.

Important boundary: `simulated_offer_exposure_flag = TRUE` means the simulated strategy produces positive offer exposure for `APPROVE` or `COUNTEROFFER`. It does not imply booked exposure, funded exposure, operational approval, or real applicant treatment.

---

## 13. Section 11 acceptance conclusion

Section 11 passes.

Accepted evidence:

- `credit_decisioning_sim.strategy_decisions` exists.
- Latest-run row count is 50,000.
- Distinct `application_id` count is 50,000.
- Final decision outcome distribution is preserved from Section 9.
- Final decision paths are preserved.
- Simulated reason-code fields are preserved from Section 10.
- Primary reason families align to final decision outcomes.
- Product-level decision outcomes remain differentiated.
- Score-band outcomes remain directionally coherent.
- Synthetic estimated-risk tier outcomes remain strongly ordered.
- Requested PTI bucket outcomes remain affordability-sensitive.
- Mixed-signal and borderline profiles remain visible and explainable.
- Approved amount conventions hold in latest-run summary.
- Approved PTI conventions hold for simulated offer-exposure rows.
- Approved Expected Loss conventions hold in latest-run summary.
- Simulated offer-exposure profile is coherent and lower-risk than non-offer / unresolved outcomes.
- `latest_output_created_ts` is populated.
- No Section 11 logic patch is recommended.

---

## Follow-up confirmation before Section 12

The uploaded Section 11 QA files do not visibly show the archive-control fields. Since Section 11 was patched to include them, run or send this quick check before reviewing Section 12:

```sql
SELECT
    archive_run_flag,
    strategy_archive_reset_mode,
    COUNT(*) AS latest_run_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    archive_run_flag,
    strategy_archive_reset_mode;
```

Expected for this smoke test:

```text
archive_run_flag = FALSE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
latest_run_rows = 50,000
```

This is not a logic patch. It is just the final confirmation that the latest-run output carries the archive controls needed for Section 12 archive-off behavior.

## Patch recommendation

No Section 11 logic patch is recommended.

Optional QA-display enhancement later:

```text
Add archive_run_flag / strategy_archive_reset_mode to the Section 11 local sanity output set
if not already present in the visible QA extract.
```

That would make archive-control verification more convenient, but it is not required for Section 11 acceptance.
<!-- END_MESSAGE C038-M00344 -->


---

<a id="c038-m00345"></a>

### C038-M00345

**Andrew** · 2026-05-07T14:46:23.900000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00345 -->
I notice that section 12 QA appear to be blank (at least the first few I spot checked).  This is likely due to our archive_run_flag = FALSE.  results of your follow-up confirmation before section 12: 
<!-- END_MESSAGE C038-M00345 -->


**Attachments in export:** `image(66).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00347"></a>

### C038-M00347

**ChatGPT** · 2026-05-07T14:48:05.096005-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00347 -->
This confirms the Section 11 archive-control patch is present and behaving correctly.

Your latest-run output has:

```text
archive_run_flag = FALSE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
latest_run_rows = 50,000
```

So for this smoke test, **Section 12 blank archive QA outputs are expected**, not a failure.

## Interpretation

Because:

```text
archive_run_flag = FALSE
```

Section 12 should:

```text
not delete archive rows
not insert archive rows
not replace any archive slice
leave strategy_decisions_archive unchanged
```

The reset mode still appears as:

```text
STRATEGY_SCENARIO_ONLY
```

but it is inactive while `archive_run_flag = FALSE`.

So the correct interpretation is:

```text
Module 2 latest-run output was created successfully.
Archive persistence was intentionally skipped.
Section 12 archive-slice outputs may be blank because no current run was archived.
```

## Section 11 follow-up confirmation

**PASS.**

This resolves the follow-up item from Section 11:

- `archive_run_flag` is carried into `credit_decisioning_sim.strategy_decisions`
- `strategy_archive_reset_mode` is carried into `credit_decisioning_sim.strategy_decisions`
- all 50,000 latest-run rows share the same archive-control configuration
- the current run is explicitly archive-disabled

## Section 12 review posture for this smoke test

For the archive-off smoke test, Section 12 should be evaluated only on **skip behavior**, not archive insertion behavior.

Expected Section 12 archive-off results:

| Check | Expected |
|---|---|
| latest-run table exists | PASS |
| latest-run row count | 50,000 |
| `archive_run_flag` | `FALSE` |
| archive delete | should not occur |
| archive insert | should not occur |
| current archived slice | may be blank |
| archive inventory | may be blank if archive table has no prior rows |

## Optional confirmation query

Run this if you want one clean Section 12 archive-off confirmation:

```sql
SELECT
    sd.archive_run_flag,
    sd.strategy_archive_reset_mode,
    sd.strategy_set_name,
    sd.strategy_name,
    sd.strategy_version,
    sd.module1_scenario_set_name,
    sd.module1_scenario_name,
    sd.population_id,
    COUNT(*) AS latest_run_rows,
    COUNT(ar.application_id) AS archived_rows_for_current_replacement_key
FROM credit_decisioning_sim.strategy_decisions sd
LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = sd.strategy_set_name
   AND ar.strategy_name = sd.strategy_name
   AND ar.strategy_version = sd.strategy_version
   AND ar.module1_scenario_set_name = sd.module1_scenario_set_name
   AND ar.module1_scenario_name = sd.module1_scenario_name
   AND ar.population_id = sd.population_id
GROUP BY
    sd.archive_run_flag,
    sd.strategy_archive_reset_mode,
    sd.strategy_set_name,
    sd.strategy_name,
    sd.strategy_version,
    sd.module1_scenario_set_name,
    sd.module1_scenario_name,
    sd.population_id;
```

For the current archive-off smoke test, a result like this is acceptable:

```text
archive_run_flag = FALSE
latest_run_rows = 50,000
archived_rows_for_current_replacement_key = 0
```

If `archived_rows_for_current_replacement_key` is greater than zero, that still is not automatically a failure; it may reflect archive rows created before this archive-off run. To prove no mutation, compare archive row counts before and after a run.

## Recommendation

Treat Sections 11 and 12 as passing for the **LATEST/ARCHIVE-source baseline smoke test with archive disabled**.

Next controlled test should be:

```text
same Module 1 archive source = BASELINE_V2
same Module 2 baseline strategy
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

That will validate actual Section 12 archive insert / replacement behavior.
<!-- END_MESSAGE C038-M00347 -->


---

<a id="c038-m00349"></a>

### C038-M00349

**Andrew** · 2026-05-07T14:49:44.011000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00349 -->
are you recommending that I re-run the code but change: same Module 1 archive source = BASELINE_V2
same Module 2 baseline strategy
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY    before proceeding to test sections 12-14?
<!-- END_MESSAGE C038-M00349 -->


---

<a id="c038-m00351"></a>

### C038-M00351

**ChatGPT** · 2026-05-07T14:50:48.273030-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00351 -->
Yes. For **Section 12 testing**, I recommend rerunning the same Module 2 baseline strategy against the same Module 1 archived `BASELINE_V2` source, but with archive persistence enabled.

Your current run proves Sections 3–11 for the latest-run output. It does **not** fully test Section 12 because:

```text
archive_run_flag = FALSE
```

So Section 12 correctly skips archive insert/delete behavior, which is why the Section 12 QA outputs appear blank or limited.

## Recommended next run

Use the same source and strategy:

```text
module1_input_source = 'ARCHIVE'
source_module1_scenario_set_name = 'MODULE1_V2_BASELINE_SET'
source_module1_scenario_name = 'BASELINE_V2'
source_population_id = 'BASE_POPULATION_V1'

strategy_set_name = 'MODULE2_BASELINE_STRATEGY_SET'
strategy_name = 'BASELINE_STRATEGY'
strategy_version = 'V1_0'
```

Change only the archive controls:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY'
```

Keep:

```text
failed_counteroffer_resolution = 'MANUAL_REVIEW'
```

and keep all strategy thresholds unchanged.

## Why this is the right next step

This run will test whether Section 12 can:

```text
create / reuse strategy_decisions_archive
delete only the current replacement-key slice if it exists
insert the current latest-run output
preserve archive grain uniqueness
populate archive_inserted_ts
prove archived rows match latest-run decision / exposure / economics / reason-code fields
```

The expected archived slice should be:

```text
strategy_set_name            = MODULE2_BASELINE_STRATEGY_SET
strategy_name                = BASELINE_STRATEGY
strategy_version             = V1_0
module1_scenario_set_name    = MODULE1_V2_BASELINE_SET
module1_scenario_name        = BASELINE_V2
population_id                = BASE_POPULATION_V1
row count                    = 50,000
distinct application_id      = 50,000
```

## Should you test Sections 12–14 before rerunning?

For **Section 12**, no. The archive-off run already confirmed skip behavior, but it cannot validate archive persistence.

For **Section 13**, not yet for matched comparison. After this archive-enabled run, Section 13 can show archive inventory for the baseline strategy, but matched baseline-vs-challenger comparison will not be ready until you archive a second Module 2 strategy on the same Module 1 scenario / population.

For **Section 14**, you can review latest-run QA now, but I recommend waiting until after the archive-enabled baseline run. That way Section 14’s archive-readiness recap has meaningful archived-slice evidence.

## Recommended order now

1. Rerun with the same Module 1 archived `BASELINE_V2` source and same Module 2 baseline strategy.
2. Change only:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY'
```

3. Review Section 12 archive QA.
4. Review Section 14 latest-run QA and archive-readiness recap.
5. Then create a challenger strategy using parameter changes only.
6. Archive the challenger.
7. Then run Section 13 matched strategy comparison.
<!-- END_MESSAGE C038-M00351 -->


---

<a id="c038-m00353"></a>

### C038-M00353

**Andrew** · 2026-05-07T14:52:36.653000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00353 -->
will I need to re-export/test sections 3-11 following changing the archive_run_flag to TRUE?  or should we expect those QA outputs to remain exactly the same?
<!-- END_MESSAGE C038-M00353 -->


---

<a id="c038-m00355"></a>

### C038-M00355

**ChatGPT** · 2026-05-07T14:53:48.543310-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00355 -->
No, you should **not need to re-export and fully re-review Sections 3–11** after changing only:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

You should expect the **business strategy outputs from Sections 4–11 to remain the same**, with only audit/control metadata changing.

## What should change

These fields should change or may change:

```text
archive_run_flag: FALSE → TRUE
strategy_run_ts: may change if generated at runtime
latest_output_created_ts: will change because strategy_decisions is recreated
archive_inserted_ts: will populate in Section 12 after archive insert
```

Section 3 parameter QA will also show:

```text
archive_run_flag = TRUE
```

instead of:

```text
archive_run_flag = FALSE
```

Section 11 latest-run output should carry:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

## What should not change

If no thresholds, strategy identity, source selection, product policy parameters, or decision logic changed, these should remain identical:

```text
row count
application_id set
Module 1 source lineage
product distribution
score distribution
segmentation distributions
rule-trigger distributions
preliminary routing distribution
counteroffer feasibility distribution
final decision_outcome distribution
decision_path distribution
approved_amount values
approved_payment_to_income_ratio values
approved_expected_loss_amount values
primary_reason_code distribution
reason family alignment
simulated_offer_exposure_flag distribution
```

So you do **not** need to re-send full Section 3–11 QA unless one of the quick regression checks below changes unexpectedly.

## Recommended lightweight regression before Section 12 review

Before rerunning with archive enabled, optionally snapshot the current latest-run output:

```sql
DROP TABLE IF EXISTS tmp_m2_smoke_archive_off_snapshot;

CREATE TEMP TABLE tmp_m2_smoke_archive_off_snapshot AS
SELECT
    application_id,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    approval_flag,
    counteroffer_flag,
    manual_review_flag,
    decline_flag,
    simulated_offer_exposure_flag,
    approved_amount,
    counteroffer_amount,
    exposure_reduction_flag,
    exposure_reduction_amount,
    exposure_reduction_pct,
    approved_monthly_payment_proxy,
    approved_payment_to_income_ratio,
    requested_expected_loss_amount,
    approved_expected_loss_amount,
    approved_el_reduction_amount,
    approved_el_reduction_pct,
    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    primary_reason_family,
    triggered_reason_code_list,
    reason_priority_rank,
    reason_code_count
FROM credit_decisioning_sim.strategy_decisions;
```

Then rerun Module 2 with:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

After rerun, compare business outputs:

```sql
SELECT
    COUNT(*) AS changed_business_output_rows
FROM tmp_m2_smoke_archive_off_snapshot b
JOIN credit_decisioning_sim.strategy_decisions a
    ON a.application_id = b.application_id
WHERE a.decision_outcome IS DISTINCT FROM b.decision_outcome
   OR a.decision_path IS DISTINCT FROM b.decision_path
   OR a.decision_resolution_source IS DISTINCT FROM b.decision_resolution_source
   OR a.approval_flag IS DISTINCT FROM b.approval_flag
   OR a.counteroffer_flag IS DISTINCT FROM b.counteroffer_flag
   OR a.manual_review_flag IS DISTINCT FROM b.manual_review_flag
   OR a.decline_flag IS DISTINCT FROM b.decline_flag
   OR a.simulated_offer_exposure_flag IS DISTINCT FROM b.simulated_offer_exposure_flag
   OR a.approved_amount IS DISTINCT FROM b.approved_amount
   OR a.counteroffer_amount IS DISTINCT FROM b.counteroffer_amount
   OR a.exposure_reduction_flag IS DISTINCT FROM b.exposure_reduction_flag
   OR a.exposure_reduction_amount IS DISTINCT FROM b.exposure_reduction_amount
   OR a.exposure_reduction_pct IS DISTINCT FROM b.exposure_reduction_pct
   OR a.approved_monthly_payment_proxy IS DISTINCT FROM b.approved_monthly_payment_proxy
   OR a.approved_payment_to_income_ratio IS DISTINCT FROM b.approved_payment_to_income_ratio
   OR a.requested_expected_loss_amount IS DISTINCT FROM b.requested_expected_loss_amount
   OR a.approved_expected_loss_amount IS DISTINCT FROM b.approved_expected_loss_amount
   OR a.approved_el_reduction_amount IS DISTINCT FROM b.approved_el_reduction_amount
   OR a.approved_el_reduction_pct IS DISTINCT FROM b.approved_el_reduction_pct
   OR a.primary_reason_code IS DISTINCT FROM b.primary_reason_code
   OR a.secondary_reason_code IS DISTINCT FROM b.secondary_reason_code
   OR a.tertiary_reason_code IS DISTINCT FROM b.tertiary_reason_code
   OR a.primary_reason_family IS DISTINCT FROM b.primary_reason_family
   OR a.triggered_reason_code_list IS DISTINCT FROM b.triggered_reason_code_list
   OR a.reason_priority_rank IS DISTINCT FROM b.reason_priority_rank
   OR a.reason_code_count IS DISTINCT FROM b.reason_code_count;
```

Expected:

```text
changed_business_output_rows = 0
```

## Minimum checks to re-run after archive-enabled rerun

Run these instead of re-exporting all Section 3–11 QA.

### 1. Archive controls changed as intended

```sql
SELECT
    archive_run_flag,
    strategy_archive_reset_mode,
    COUNT(*) AS latest_run_rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    archive_run_flag,
    strategy_archive_reset_mode;
```

Expected:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
latest_run_rows = 50,000
```

### 2. Final decision distribution still matches

```sql
SELECT
    decision_outcome,
    COUNT(*) AS rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;
```

Expected same as before:

```text
APPROVE        11,291
COUNTEROFFER   19,067
DECLINE        12,703
MANUAL_REVIEW   6,939
```

### 3. Reason family still aligns

```sql
SELECT
    decision_outcome,
    primary_reason_family,
    COUNT(*) AS rows
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    decision_outcome,
    primary_reason_family
ORDER BY
    decision_outcome,
    primary_reason_family;
```

Expected:

```text
APPROVE        APPROVAL        11,291
COUNTEROFFER   COUNTEROFFER    19,067
DECLINE        POLICY_STOP     12,703
MANUAL_REVIEW  MANUAL_REVIEW    6,939
```

### 4. Section 12 archive slice inserted

```sql
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS archived_rows,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,
    MIN(archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(archive_inserted_ts) AS max_archive_inserted_ts
FROM credit_decisioning_sim.strategy_decisions_archive
WHERE strategy_set_name = 'MODULE2_BASELINE_STRATEGY_SET'
  AND strategy_name = 'BASELINE_STRATEGY'
  AND strategy_version = 'V1_0'
  AND module1_scenario_set_name = 'MODULE1_V2_BASELINE_SET'
  AND module1_scenario_name = 'BASELINE_V2'
  AND population_id = 'BASE_POPULATION_V1'
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;
```

Expected:

```text
archived_rows = 50,000
distinct_application_id_count = 50,000
archive_inserted_ts populated
```

## Recommendation

Proceed with the archive-enabled rerun. Do **not** fully re-review Sections 3–11 unless the lightweight regression finds a mismatch.

After the rerun, send the **Section 12 archive QA outputs** first. Then we can review Section 14 with archive readiness now populated.
<!-- END_MESSAGE C038-M00355 -->


---

<a id="c038-m00357"></a>

### C038-M00357

**Andrew** · 2026-05-08T07:53:28.399000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00357 -->
good morning, these were the only section 3-11 QA to change with only the time stamp and archive_run_flag changing (3.3; 4.4.3; 11.5.1).  i confirmed we got the same outcomes in 11.5.17.  would you agree that I would not see those archive_run_flag and time stamp changing in any other section 3-11 QA?  next, i'll review and send section 12 QA
<!-- END_MESSAGE C038-M00357 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_4.4.3_QA_local_source_staging_sanity_module_2_strategy_metadata(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_11.5.1_QA_local_latest_run_sanity_row_application_count(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_3.3_QA_threshold_equality_convention_documentation(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00361"></a>

### C038-M00361

**ChatGPT** · 2026-05-08T07:54:58.971169-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00361 -->
Good morning. Yes, I agree.

Given that the only parameter change was:

```text
archive_run_flag: FALSE → TRUE
strategy_archive_reset_mode: unchanged at STRATEGY_SCENARIO_ONLY
```

and the source, strategy identity, thresholds, product policy parameters, and decision logic were unchanged, the only Section 3–11 QA outputs I would expect to change are the ones that explicitly display **archive controls or run timestamps**.

From the files you sent, the observed changes are exactly the expected ones:

```text
3.3
- archive_run_flag changed to TRUE
- strategy_run_ts changed

4.4.3
- strategy_run_ts changed

11.5.1
- latest_output_created_ts changed
```

Those are audit/control metadata changes, not strategy-outcome changes.

I would **not** expect the following Section 3–11 outputs to change:

```text
row counts
application_id uniqueness
Module 1 source lineage
product distribution
score-band distribution
segmentation buckets
rule-trigger counts
preliminary routing distribution
counteroffer feasibility results
final decision_outcome distribution
decision_path distribution
approved_amount values
approved_payment_to_income_ratio values
approved_expected_loss_amount values
primary_reason_code distribution
primary_reason_family alignment
simulated_offer_exposure_flag distribution
```

Your confirmation that `11.5.17` produced the same simulated offer-exposure profile is strong evidence that the business outputs remained stable.

One small nuance: `archive_run_flag` may also appear in any QA query that explicitly selects it from `strategy_decisions`. If a Section 11 sanity query includes archive controls, that query would change from `FALSE` to `TRUE`. But that is still expected metadata movement, not outcome movement.

So the conclusion is:

```text
Sections 3–11 remain accepted.
The archive-enabled rerun changed only expected audit/control metadata.
No re-review of Sections 3–11 is needed before Section 12.
```

For Section 12, the key things I’ll look for are:

```text
archived slice row count = 50,000
distinct archived application_id count = 50,000
archive_inserted_ts populated
archive grain duplicate count = 0
latest-run vs archive persistence mismatch count = 0
replacement key matches:
  MODULE2_BASELINE_STRATEGY_SET
  BASELINE_STRATEGY
  V1_0
  MODULE1_V2_BASELINE_SET
  BASELINE_V2
  BASE_POPULATION_V1
```

Send the Section 12 QA when ready.
<!-- END_MESSAGE C038-M00361 -->


---

<a id="c038-m00363"></a>

### C038-M00363

**Andrew** · 2026-05-08T08:05:01.399000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00363 -->
please review section 12 QA (note, I ran this twice due to network disconnection.  hence the 12.8.11 diagnostic shows 50k deleted): 
<!-- END_MESSAGE C038-M00363 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.5_QA_local_archive_sanity_current_archived_slice_product_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.6_QA_local_archive_sanity_current_archived_slice_score_band_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.7_QA_local_archive_sanity_current_archived_slice_simulated_offer_exposure_flag_profile.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.8_QA_local_archive_sanity_current_archived_slice_requested_and approved_amount_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.9_QA_local_archive_sanity_current_archived_slice_requested_and approved_expected_loss_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.10_QA_local_archive_sanity_archive_timestamp_summary_for_current_replacement_key.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.11_QA_local_archive_sanity_archive_mode_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.1_QA_local_archive_sanity_archive_inventory_by_strategy_and_module_1_scenario.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.2_QA_local_archive_sanity_current_archived_slice_row_application_count.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.3_QA_local_archive_sanity_current_archived_slice_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_12.8.4_QA_local_archive_sanity_current_archived_slice_primary_reason_code.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00368"></a>

### C038-M00368

**ChatGPT** · 2026-05-08T08:07:03.597609-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00368 -->
## Section 12 QA review — Strategy Decision Archive Persistence Layer

**Verdict: PASS.**

Section 12 is behaving correctly for the archive-enabled baseline run:

```text
module1_input_source = ARCHIVE
module1_scenario_set_name = MODULE1_V2_BASELINE_SET
module1_scenario_name = BASELINE_V2
population_id = BASE_POPULATION_V1

strategy_set_name = MODULE2_BASELINE_STRATEGY_SET
strategy_name = BASELINE_STRATEGY
strategy_version = V1_0

archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

The archive output now contains exactly one archived baseline Module 2 strategy slice for the selected Module 1 baseline scenario. No logic patch is recommended.

Your note about the network disconnection explains the `50,000` deleted rows in `12.8.11`. That diagnostic is not a failure. It shows that `STRATEGY_SCENARIO_ONLY` replacement worked as designed on rerun: delete the existing current replacement-key slice, then insert the refreshed latest-run output.

---

## 1. Archive inventory

Section 12 archive inventory shows one archived strategy slice:

| Field | Observed |
|---|---|
| `strategy_set_name` | `MODULE2_BASELINE_STRATEGY_SET` |
| `strategy_name` | `BASELINE_STRATEGY` |
| `strategy_version` | `V1_0` |
| `module1_scenario_set_name` | `MODULE1_V2_BASELINE_SET` |
| `module1_scenario_name` | `BASELINE_V2` |
| `population_id` | `BASE_POPULATION_V1` |
| Archived rows | `50,000` |
| Distinct `application_id` count | `50,000` |

**Assessment: PASS.**

This confirms the archive slice is at the correct locked grain:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

and the replacement / rerun key excludes `application_id`, as designed.

---

## 2. Current archived slice row count

| QA area | Observed | Assessment |
|---|---:|---|
| Current archived slice rows | 50,000 | PASS |
| Current archived slice distinct `application_id` count | 50,000 | PASS |
| Duplicate application rows in current slice | implied 0 | PASS |

This validates the current archived slice row-level integrity.

There is no evidence of partial insertion from the network interruption. The rerun produced a clean 50,000-row archived slice.

---

## 3. Archive mode diagnostic

The diagnostic shows:

| Field | Observed |
|---|---:|
| `archive_run_flag` | `TRUE` |
| `strategy_archive_reset_mode` | `STRATEGY_SCENARIO_ONLY` |
| Latest-run row count | `50,000` |
| Latest-run distinct application count | `50,000` |
| Archive row count before | `50,000` |
| Archive deleted rows | `50,000` |
| Archive inserted rows | `50,000` |
| Archive row count after | `50,000` |
| Archive action | `ARCHIVE_REPLACED_STRATEGY_SCENARIO_ONLY` |

**Assessment: PASS.**

The `50,000` deleted rows are expected because you ran the same replacement key more than once. `STRATEGY_SCENARIO_ONLY` is the ordinary rerun mode, and the behavior should be:

```text
delete existing rows for this strategy + Module 1 scenario + population
insert current latest-run rows
```

That is exactly what happened.

This is actually a strong archive-governance result: it proves Section 12 can replace the current strategy/scenario slice cleanly rather than silently duplicating rows.

---

## 4. Archive timestamps

The timestamp summary shows:

| Field | Observed |
|---|---:|
| `min_archive_inserted_ts` | `2026-05-08 07:32:28.040` |
| `max_archive_inserted_ts` | `2026-05-08 07:32:28.040` |
| Current archived slice row count | `50,000` |

**Assessment: PASS.**

A single `archive_inserted_ts` for the current replacement-key slice is expected. It means the 50,000 rows were inserted as one archive persistence event.

Reminder: `archive_inserted_ts` is audit metadata. It should not be used as the archive replacement key or as deterministic strategy comparison evidence.

---

## 5. Archived decision outcome distribution

| Decision outcome | Archived rows |
|---|---:|
| `APPROVE` | 11,291 |
| `COUNTEROFFER` | 19,067 |
| `MANUAL_REVIEW` | 6,939 |
| `DECLINE` | 12,703 |

**Assessment: PASS.**

This exactly matches the accepted Section 9–11 final decision distribution. Section 12 persisted the latest-run outcomes without changing them.

Expected reconciliation:

```text
APPROVE       = 11,291
COUNTEROFFER  = 19,067
MANUAL_REVIEW = 6,939
DECLINE       = 12,703
Total         = 50,000
```

---

## 6. Archived primary reason-code distribution

The archived primary reason-code distribution matches the accepted Section 10 / Section 11 pattern:

| Primary reason family | Rows |
|---|---:|
| `APPROVAL` | 11,291 |
| `COUNTEROFFER` | 19,067 |
| `MANUAL_REVIEW` | 6,939 |
| `POLICY_STOP` | 12,703 |

Key reason codes are also preserved:

| Primary reason code | Rows |
|---|---:|
| `APPROVED_AS_REQUESTED` | 11,291 |
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 8,905 |
| `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` | 6,369 |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 5,021 |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 3,853 |
| `MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK` | 2,961 |
| `POLICY_STOP_RECENT_DELINQUENCY` | 2,955 |
| `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` | 2,130 |
| `POLICY_STOP_MAJOR_DEROGATORY` | 2,107 |
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 1,288 |

**Assessment: PASS.**

Section 12 did not recalculate or alter simulated reason codes. It persisted the already-materialized latest-run outputs.

---

## 7. Product × decision outcome in archive

| Product | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `AUTO_LOAN` | 2,789 | 3,167 | 1,515 | 2,475 | PASS |
| `HELOC` | 1,126 | 1,872 | 598 | 1,366 | PASS |
| `MORTGAGE` | 3,233 | 5,848 | 1,969 | 4,015 | PASS |
| `REVOLVING_LINE` | 2,603 | 5,231 | 1,696 | 2,925 | PASS |
| `UNSECURED_PERSONAL_LOAN` | 1,540 | 2,949 | 1,161 | 1,922 | PASS |

This matches the accepted latest-run Section 11 distribution.

No product-level drift was introduced by archive persistence.

---

## 8. Score band × decision outcome in archive

| Score band | Approve | Counteroffer | Manual review | Decline | Assessment |
|---|---:|---:|---:|---:|---|
| `SUPER_PRIME` | 4,947 | 3,611 | 375 | 51 | PASS |
| `PRIME` | 5,784 | 5,657 | 2,160 | 386 | PASS |
| `NEAR_PRIME` | 560 | 8,818 | 1,490 | 1,205 | PASS |
| `SUBPRIME` | 0 | 980 | 2,898 | 5,024 | PASS |
| `DEEP_SUBPRIME` | 0 | 1 | 16 | 6,037 | PASS |

**Assessment: PASS.**

The archive preserves the score-band decision distribution accepted in Section 11. Stronger score bands retain higher positive offer-exposure outcomes; weaker score bands show higher review / decline outcomes.

---

## 9. Simulated offer-exposure profile in archive

| `simulated_offer_exposure_flag` | Rows | Total approved amount | Avg synthetic estimated-PD proxy | Total approved Expected Loss | Avg approved Expected Loss |
|---|---:|---:|---:|---:|---:|
| `FALSE` | 19,642 | 0 | 0.316622 | 0 | 0 |
| `TRUE` | 30,358 | 3.8795B | 0.064207 | 58.93M | 1,941.16 |

**Assessment: PASS.**

This matches the accepted Section 11 simulated offer-exposure profile.

The archived simulated offer-exposure rows are materially lower-risk on average than non-offer / unresolved rows:

```text
Offer rows avg synthetic estimated-PD proxy:     0.064207
Non-offer rows avg synthetic estimated-PD proxy: 0.316622
```

Boundary remains important: `simulated_offer_exposure_flag = TRUE` means simulated positive offer exposure only. It does not imply booked exposure, funded exposure, production approval, or real applicant treatment.

---

## 10. Archived requested vs approved amount conventions

| Decision outcome | Rows | Avg requested amount | Avg approved amount all apps | Avg approved amount offer rows | Avg exposure reduction amount | Avg exposure reduction pct |
|---|---:|---:|---:|---:|---:|---:|
| `APPROVE` | 11,291 | 112,594 | 112,594 | 112,594 | 0 | 0.00000 |
| `COUNTEROFFER` | 19,067 | 176,816 | 136,792 | 136,792 | 40,024 | 0.19786 |
| `MANUAL_REVIEW` | 6,939 | 112,763 | 0 | NULL | NULL | NULL |
| `DECLINE` | 12,703 | 97,721 | 0 | NULL | 97,721 | 1.00000 |

**Assessment: PASS.**

The archived amount conventions match the latest-run output:

- `APPROVE`: approved amount equals requested amount.
- `COUNTEROFFER`: approved amount is below requested amount.
- `MANUAL_REVIEW`: unresolved; approved amount remains null in the source and appears as zero only in all-app aggregate metrics using `COALESCE`.
- `DECLINE`: zero-exposure convention.

No archive transformation issue is indicated.

---

## 11. Archived requested vs approved Expected Loss conventions

| Decision outcome | Avg requested Expected Loss | Avg approved Expected Loss all apps | Avg approved Expected Loss offer rows | Avg approved EL reduction amount | Avg approved EL reduction pct |
|---|---:|---:|---:|---:|---:|
| `APPROVE` | 765.74 | 765.74 | 765.74 | 0 | 0.00000 |
| `COUNTEROFFER` | 3,474.72 | 2,637.22 | 2,637.22 | 837.50 | 0.19786 |
| `MANUAL_REVIEW` | 4,535.33 | 0 | NULL | NULL | NULL |
| `DECLINE` | 10,475.04 | 0 | NULL | 10,475.04 | 1.00000 |

**Assessment: PASS.**

The archive preserves the distinction between:

```text
requested_expected_loss_amount = requested-exposure Expected Loss
approved_expected_loss_amount  = approved-exposure Expected Loss
```

For counteroffers, approved Expected Loss is reduced by the same average exposure-reduction percentage:

```text
avg exposure reduction pct      = 0.19786
avg approved EL reduction pct   = 0.19786
```

That is expected because approved Expected Loss is proportional to approved exposure using the Module 1 synthetic estimated-PD proxy and LGD.

---

## 12. Network disconnection / rerun interpretation

Your note is important and the diagnostic confirms the expected behavior.

Because the run was executed twice under:

```text
archive_run_flag = TRUE
strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
```

the second execution should show:

```text
archive_row_count_before = 50,000
archive_deleted_rows     = 50,000
archive_inserted_rows    = 50,000
archive_row_count_after  = 50,000
```

That is exactly what the diagnostic shows.

This is **not** evidence of duplicate archive rows. It is evidence that the replacement mode worked.

If duplicates existed, we would expect one of the following problems:

```text
current archived slice row count > 50,000
distinct application_id count < row count
archive row count after > 50,000 for the same replacement key
```

None of those appear in the uploaded QA outputs.

---

## Section 12 acceptance conclusion

Section 12 passes.

Accepted evidence:

- `credit_decisioning_sim.strategy_decisions_archive` contains the current baseline strategy slice.
- Current archived slice row count is 50,000.
- Current archived slice distinct `application_id` count is 50,000.
- Archive replacement key is correct:
  - `MODULE2_BASELINE_STRATEGY_SET`
  - `BASELINE_STRATEGY`
  - `V1_0`
  - `MODULE1_V2_BASELINE_SET`
  - `BASELINE_V2`
  - `BASE_POPULATION_V1`
- `archive_inserted_ts` is populated.
- `STRATEGY_SCENARIO_ONLY` replacement behavior worked as designed.
- The rerun deleted 50,000 prior rows for the same replacement key and inserted 50,000 refreshed rows.
- Archived decision outcomes match latest-run accepted outcomes.
- Archived reason-code distribution matches latest-run accepted reason-code distribution.
- Product × decision and score × decision distributions are preserved.
- Simulated offer-exposure profile is preserved.
- Approved amount conventions are preserved.
- Approved Expected Loss conventions are preserved.
- No evidence of duplicate archive grain appears in the uploaded QA.
- No evidence of archive mutation beyond the intended replacement-key slice appears in the uploaded QA.

## Patch recommendation

No Section 12 logic patch is recommended.

## Optional confirmation before moving on

If you want one final hard confirmation that the archive row-level grain is unique, run:

```sql
SELECT
    COUNT(*) AS duplicate_archive_grain_rows
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
) x;
```

Expected:

```text
duplicate_archive_grain_rows = 0
```

Given the uploaded row-count and distinct-application outputs, I expect this to pass.

## Recommended next step

Proceed to Section 14 latest-run QA and archive-readiness recap if you want to complete validation of the baseline strategy run.

Section 13 matched comparison will not be fully ready until a **challenger Module 2 strategy** is archived under the same Module 1 scenario and population.
<!-- END_MESSAGE C038-M00368 -->


---

<a id="c038-m00369"></a>

### C038-M00369

**Andrew** · 2026-05-08T08:28:26.428000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00369 -->
review section 14.1 through 14.6 QA: 
<!-- END_MESSAGE C038-M00369 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.2_QA_module_2_validation_row_application_count_by_module_1_input_source.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.2_QA_module_2_validation_duplicate_application_diagnostic_expected_result_zero_rows.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.2_QA_module_2_validation_required_field_completeness_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.3_QA_module_2_validation_decision_outcome_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.3_QA_module_2_validation_final_decision_flag_reconciliation_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.3_QA_module_2_validation_preliminary_route_to_final_outcome_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.4_QA_module_2_validation_product_level_strategy_qa.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.4_QA_module_2_validation_product_level_decision_rate_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.4_QA_module_2_validation_product_level_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.5_QA_module_2_validation_score_band_strategy_qa.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.5_QA_module_2_validation_score_band_decision_rate_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.5_QA_module_2_validation_score_band_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.6_QA_module_2_validation_product_x_score_decision.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.6_QA_module_2_validation_product_x_score_x_decision_outcome_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.6_QA_module_2_validation_product_x_score_x_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.1_QA_module_2_validation_scope_and_boundary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.1_QA_module_2_validation_latest_run_strategy_and_module_1_lineage_scope.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.2_QA_module_2_validation_latest_run_structural_integrity_summary.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00380"></a>

### C038-M00380

**ChatGPT** · 2026-05-08T08:32:07.359490-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00380 -->
## Section 14.1–14.6 QA review — Module 2 validation diagnostics

**Verdict: PASS.**

Sections 14.1 through 14.6 are behaving as intended. The latest-run validation scope is clean, structural integrity holds, final outcomes reconcile, product-level behavior is interpretable, score-band ordering is directionally strong, and the product × score matrix provides a usable validation view.

No blocker, high-severity issue, or logic patch is indicated.

This is the right validation pattern: Section 14 is not just confirming that the SQL ran; it is confirming that the completed latest-run output is structurally valid, outcome-complete, product-aware, score-aware, risk-ordered, and explainable. That mirrors the Module 1 validation philosophy that QA should prove coherent behavior across portfolio, product, score, affordability, and diagnostic layers rather than relying on execution success alone. fileciteturn4file1 fileciteturn4file2

---

## 14.1 — Validation scope and boundary

**Assessment: PASS.**

| QA area | Observed result | Assessment |
|---|---:|---|
| Latest-run rows | 50,000 | PASS |
| Distinct `application_id` count | 50,000 | PASS |
| Distinct strategy count | 1 | PASS |
| Distinct Module 1 scenario / population count | 1 | PASS |
| Validation scope status | `LATEST_RUN_SCOPE_READY_FOR_QA_REVIEW` | PASS |

The latest-run scope is clean and validation-ready.

The lineage output confirms the correct execution context:

```text
Module 2 strategy:
MODULE2_BASELINE_STRATEGY_SET / BASELINE_STRATEGY / V1_0

Module 1 source:
ARCHIVE
credit_decisioning_sim.synthetic_applications_scenario_archive

Module 1 scenario:
MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

archive_run_flag:
TRUE
```

This is exactly the intended archive-enabled baseline configuration.

---

## 14.2 — Latest-run structural integrity

**Assessment: PASS.**

| QA area | Observed result | Assessment |
|---|---:|---|
| Total rows | 50,000 | PASS |
| Distinct `application_id` count | 50,000 | PASS |
| Duplicate application rows | 0 | PASS |
| Distinct strategy versions | 1 | PASS |
| Distinct Module 1 scenario / population slices | 1 | PASS |
| Null `application_id` rows | 0 | PASS |
| Null `applicant_id` rows | 0 | PASS |
| Null strategy metadata rows | 0 | PASS |
| Null Module 1 lineage rows | 0 | PASS |
| Null decision outcome rows | 0 | PASS |
| Null primary reason code rows | 0 | PASS |
| Null requested Expected Loss rows | 0 | PASS |
| Duplicate application diagnostic | zero rows returned | PASS |
| Required field missing counts | all 0 | PASS |

This confirms the latest-run output is structurally sound.

No required field gaps are visible. The latest-run table is unique at the application level, scoped to one strategy, and scoped to one Module 1 scenario / population.

---

## 14.3 — Decision outcome distribution and final flag reconciliation

**Assessment: PASS.**

| Decision outcome | Rows | Population share |
|---|---:|---:|
| `APPROVE` | 11,291 | 22.58% |
| `COUNTEROFFER` | 19,067 | 38.13% |
| `MANUAL_REVIEW` | 6,939 | 13.88% |
| `DECLINE` | 12,703 | 25.41% |

The final flag reconciliation output shows:

```text
final_decision_flag_count = 1
row_count = 50,000
```

That is exactly the locked taxonomy requirement: every row has exactly one final simulated strategy outcome.

The preliminary-to-final reconciliation is also correct:

| Preliminary outcome | Final outcome | Rows | Interpretation |
|---|---|---:|---|
| `APPROVE` | `APPROVE` | 11,291 | confirmed approval route |
| `COUNTEROFFER` | `COUNTEROFFER` | 19,067 | feasible counteroffers confirmed |
| `COUNTEROFFER` | `MANUAL_REVIEW` | 2,219 | infeasible counteroffers routed to review |
| `MANUAL_REVIEW` | `MANUAL_REVIEW` | 4,720 | unresolved review confirmed |
| `DECLINE` | `DECLINE` | 12,703 | preliminary decline confirmed |

This matches the accepted Section 8 and Section 9 behavior.

---

## 14.4 — Product-level strategy QA

**Assessment: PASS.**

Product-level decision rates are differentiated and plausible.

| Product | Applications | Approval rate | Counteroffer rate | Manual review rate | Decline rate | Simulated offer-exposure rate |
|---|---:|---:|---:|---:|---:|---:|
| `AUTO_LOAN` | 9,946 | 28.04% | 31.84% | 15.23% | 24.88% | 59.88% |
| `HELOC` | 4,962 | 22.69% | 37.73% | 12.05% | 27.53% | 60.42% |
| `MORTGAGE` | 15,065 | 21.46% | 38.82% | 13.07% | 26.65% | 60.28% |
| `REVOLVING_LINE` | 12,455 | 20.90% | 42.00% | 13.62% | 23.48% | 62.90% |
| `UNSECURED_PERSONAL_LOAN` | 7,572 | 20.34% | 38.95% | 15.33% | 25.38% | 59.28% |

Product-level behavior is not flat or generic:

- `REVOLVING_LINE` has the highest counteroffer rate and simulated offer-exposure rate.
- `MORTGAGE` shows high counteroffer volume and high requested PTI, consistent with large-balance affordability treatment.
- `AUTO_LOAN` has the highest approval rate.
- `HELOC` and `MORTGAGE` show larger requested exposure and product-aware approved exposure behavior.
- `UNSECURED_PERSONAL_LOAN` shows meaningful review and decline volume, consistent with unsecured exposure sensitivity.

Primary reason-code patterns are also product-aware:

- `MORTGAGE` is led by `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT`, which is intuitive for large-payment products.
- `REVOLVING_LINE`, `HELOC`, and `UNSECURED_PERSONAL_LOAN` show strong `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` patterns.
- Decline reasons are concentrated in synthetic estimated-risk and policy-stop families, not arbitrary product labels.

This supports the Module 2 thesis that strategy outcomes emerge from product structure, affordability, risk translation, exposure treatment, and policy simulation rules.

---

## 14.5 — Score-band strategy QA

**Assessment: PASS.**

Score-band ordering is directionally strong.

| Score band | Applications | Avg synthetic estimated-PD proxy | Approval rate | Counteroffer rate | Manual review rate | Decline rate | Simulated offer-exposure rate |
|---|---:|---:|---:|---:|---:|---:|---:|
| `SUPER_PRIME` | 8,984 | 0.0135 | 55.06% | 40.19% | 4.17% | 0.57% | 95.26% |
| `PRIME` | 13,987 | 0.0401 | 41.35% | 40.44% | 15.44% | 2.76% | 81.80% |
| `NEAR_PRIME` | 12,073 | 0.1309 | 4.64% | 73.04% | 12.34% | 9.98% | 77.68% |
| `SUBPRIME` | 8,902 | 0.3596 | 0.00% | 11.01% | 32.55% | 56.44% | 11.01% |
| `DEEP_SUBPRIME` | 6,054 | 0.4466 | 0.00% | 0.02% | 0.26% | 99.72% | 0.02% |

This is a strong validation result.

Key patterns:

- Average synthetic estimated-PD proxy increases cleanly from `SUPER_PRIME` to `DEEP_SUBPRIME`.
- Approval rates decline sharply as score quality weakens.
- Decline rates increase sharply as score quality weakens.
- `NEAR_PRIME` is mostly counteroffer, which is plausible for a middle-risk strategy zone.
- `SUBPRIME` and `DEEP_SUBPRIME` are dominated by decline and manual review.
- `DEEP_SUBPRIME` is almost entirely decline, with only one counteroffer and 16 manual-review rows.

The small Deep Subprime non-decline population remains an edge-case population. It is not a defect; it reflects the accepted design that realistic synthetic portfolios preserve limited overlap and exceptions. Module 1 validation similarly emphasizes directional ordering with mixed-signal realism rather than rigid deterministic segmentation. fileciteturn4file2

Reason-code behavior by score band is also coherent:

- `SUPER_PRIME` is dominated by approvals and product-exposure counteroffers.
- `PRIME` is dominated by approvals, product-exposure counteroffers, affordability counteroffers, and borderline review.
- `NEAR_PRIME` is dominated by counteroffer reasons.
- `SUBPRIME` is dominated by synthetic-risk policy stops, failed-counteroffer review, and mixed-signal review.
- `DEEP_SUBPRIME` is dominated by synthetic-risk, delinquency, derogatory, and bankruptcy policy-stop reasons.

No score-band QA issue is indicated.

---

## 14.6 — Product × score decision matrix

**Assessment: PASS.**

The product × score matrix is one of the strongest validation outputs so far.

The matrix confirms:

```text
25 product × score combinations populated
86 product × score × outcome rows
232 product × score × primary reason-code rows
```

That means the validation layer has enough segment density to support product-aware and score-aware interpretation.

### Directional segment behavior

Across every product:

- `SUPER_PRIME` and `PRIME` show high simulated offer-exposure rates.
- `NEAR_PRIME` shifts heavily into counteroffer.
- `SUBPRIME` shifts heavily into manual review and decline.
- `DEEP_SUBPRIME` is almost entirely decline.

Examples:

| Product × score | Approval rate | Counteroffer rate | Decline rate | Interpretation |
|---|---:|---:|---:|---|
| `AUTO_LOAN / SUPER_PRIME` | 66.29% | 29.79% | 0.62% | strong offer profile |
| `AUTO_LOAN / DEEP_SUBPRIME` | 0.00% | 0.00% | 99.44% | severe-risk no-offer profile |
| `MORTGAGE / SUPER_PRIME` | 58.35% | 33.78% | 0.40% | strong but product-affordability sensitive |
| `MORTGAGE / NEAR_PRIME` | 1.40% | 74.78% | 10.13% | exposure / affordability strategy zone |
| `REVOLVING_LINE / NEAR_PRIME` | 5.09% | 75.60% | 10.61% | counteroffer-heavy middle-risk segment |
| `UNSECURED_PERSONAL_LOAN / SUBPRIME` | 0.00% | 7.77% | 56.47% | weak-score unsecured pressure |

This is exactly what a product-aware strategy simulator should show: product type changes the structure of the outcome, but score quality still imposes strong directional risk ordering.

### Product × score reason-code behavior

Reason-code distribution by product × score is also strong:

- Stronger product × score segments show `APPROVED_AS_REQUESTED` and `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT`.
- Middle-risk segments show `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT`, `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT`, and `COUNTEROFFER_EXPECTED_LOSS_LIMIT`.
- Weaker product × score segments show `POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`, `POLICY_STOP_RECENT_DELINQUENCY`, `POLICY_STOP_MAJOR_DEROGATORY`, and `POLICY_STOP_BANKRUPTCY_FLAG`.

This confirms that Section 14.6 is not just showing rates; it is also showing explainability by segment.

---

## Key interpretation notes

### 1. Manual-review approved metrics showing zero in all-app summaries are expected

In Section 14 outputs, some all-application metrics use:

```sql
COALESCE(approved_amount, 0)
COALESCE(approved_expected_loss_amount, 0)
```

So manual-review rows appear as zero in all-application aggregates.

That does **not** mean manual-review rows have booked or approved exposure. The stored convention remains:

```text
MANUAL_REVIEW approved_amount = NULL
MANUAL_REVIEW approved_expected_loss_amount = NULL
```

The zero only appears in aggregate all-app metrics for portfolio-impact math.

### 2. `estimated_pd` continues to behave correctly as a synthetic estimated-PD proxy

Across Sections 14.4–14.6, average `estimated_pd` values are directionally ordered by score and outcome. This supports the strategy simulation use case, but it does not convert `estimated_pd` into a calibrated production PD model. That boundary remains intact.

### 3. Product × score behavior is realistic, not rigid

The matrix preserves overlap:

- strong segments can receive counteroffers due to product exposure or affordability;
- middle-risk segments can receive counteroffers instead of automatic declines;
- weak segments can contain tiny non-decline edge populations;
- product structure changes the shape of outcomes within a score band.

That is desirable for a strategy simulator.

---

## Section 14.1–14.6 acceptance conclusion

Sections 14.1 through 14.6 pass.

Accepted evidence:

- Latest-run validation scope is clean.
- One Module 2 strategy is present.
- One Module 1 scenario / population slice is present.
- Source is correctly the Module 1 archive baseline slice.
- Latest-run row count is 50,000.
- `application_id` remains unique.
- Duplicate diagnostic returns zero rows.
- Required field completeness checks return zero missing rows.
- Final decision outcomes are populated.
- Exactly one final decision flag is true per row.
- Preliminary-to-final outcome reconciliation is correct.
- Product-level decision behavior is differentiated and interpretable.
- Product-level reason-code behavior is coherent.
- Score-band decision behavior is directionally risk-ordered.
- Score-band reason-code behavior is coherent.
- Product × score matrix is fully populated.
- Product × score outcomes show expected interaction between product structure and score quality.
- Product × score reason-code outputs are explainable.
- No latest-run or archive rows are modified by Section 14.
- No decisions, reason codes, approved exposure, or approved Expected Loss values are recalculated in Section 14.

## Patch recommendation

No Section 14.1–14.6 logic patch is recommended.

## Monitoring items for the next Section 14 QA batch

For Sections 14.7 onward, I would focus on:

1. **Synthetic risk ordering:** confirm offered rows have lower average synthetic estimated-PD proxy than declined rows.
2. **Affordability sensitivity:** confirm higher requested PTI buckets show reduced approval and increased counteroffer / review / decline behavior.
3. **DTI capacity:** confirm high DTI reduces clean approval and increases decline / review routing.
4. **Counteroffer validation:** confirm counteroffers reduce approved amount, approved PTI, and approved Expected Loss.
5. **Manual review diagnostics:** confirm manual review remains unresolved and reason-code aligned.
6. **Reason-code coverage:** confirm no missing reason codes and no outcome-family leakage.
7. **Validation status summary:** confirm expected PASS / REVIEW / NOT_APPLICABLE classifications.
<!-- END_MESSAGE C038-M00380 -->


---

<a id="c038-m00381"></a>

### C038-M00381

**Andrew** · 2026-05-08T09:29:53.748000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00381 -->
review sections 14.7-14.11 QA:
<!-- END_MESSAGE C038-M00381 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.9_QA_module_2_validation_dti_capacity.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.9_QA_module_2_validation_dti_decline_trigger_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.9_QA_module_2_validation_dti_sensitivity_status_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10_QA_module_2_validation_approved_exposure_x_expected_loss.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10_QA_module_2_validation_final_approved_exposure_convention_expected_result_all_violation_counts_zero.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10_QA_module_2_validation_final_approved_expected_loss_convention_expected_result_all_violation_counts_zero.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.10_QA_module_2_validation_product_level_requested_versus_approved_exposure_and_expected_loss.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11A_QA_module_2_validation_counteroffer_validation_diagnostics.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11B_QA_module_2_validation_counteroffer_feasibility_failure_reason_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11C_QA_module_2_validation_product_x_counteroffer_feasibility.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11D_QA_module_2_validation_score_band_x_counteroffer_feasibility.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11E_QA_module_2_validation_final_counteroffer_convention_expected_result_all_violation_counts_zero.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.11F_QA_module_2_validation_counteroffer_primary_reason_code_distribution.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.7_QA_module_2_validation_synthetic_risk_ordering_qa.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.7_QA_module_2_validation_compact_synthetic_risk_tier_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.7_QA_module_2_validation_offered_versus_declined_synthetic_estimated_risk_comparison.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.8_QA_module_2_validation_requested_pti_affordability_sensitivity.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.8_QA_module_2_validation_afforability_sensitivity_status_check.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.8_QA_module_2_validation_counteroffer_pti_improvement_diagnostic.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00383"></a>

### C038-M00383

**ChatGPT** · 2026-05-08T09:35:56.063788-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00383 -->
## Section 14.7–14.11 QA review — Risk ordering, affordability, DTI, exposure economics, and counteroffer diagnostics

**Verdict: PASS with monitoring notes only.**

Sections 14.7 through 14.11 are behaving as intended. The outputs validate that the completed latest-run Module 2 strategy output is directionally risk-ordered, affordability-sensitive, DTI-sensitive, exposure-convention compliant, Expected Loss compliant, and counteroffer-feasibility aligned.

No blocker, high-severity issue, or logic patch is indicated.

These sections provide strong validation evidence that Module 2 is preserving the accepted simulation boundary: `estimated_pd` remains the Module 1 synthetic estimated-PD proxy, requested Expected Loss remains requested-exposure Expected Loss, and approved Expected Loss reflects Module 2 approved-exposure treatment. This is consistent with Module 1’s established validation posture: directional coherence and explainability matter here, not empirical calibration claims. fileciteturn4file1 fileciteturn4file2

---

# 14.7 — Synthetic risk ordering QA

**Assessment: PASS.**

The synthetic risk tier summary is strongly ordered.

| Synthetic risk tier | Applications | Avg synthetic estimated-PD proxy | Approval rate | Counteroffer rate | Manual review rate | Decline rate | Simulated offer-exposure rate |
|---|---:|---:|---:|---:|---:|---:|---:|
| `LOW_SYNTHETIC_RISK` | 17,122 | 0.0225 | 55.29% | 35.19% | 9.19% | 0.33% | 90.49% |
| `MODERATE_SYNTHETIC_RISK` | 6,813 | 0.0534 | 26.77% | 48.52% | 20.92% | 3.79% | 75.30% |
| `ELEVATED_SYNTHETIC_RISK` | 8,683 | 0.1147 | 0.00% | 91.89% | 3.34% | 4.77% | 91.89% |
| `HIGH_SYNTHETIC_RISK` | 6,412 | 0.2622 | 0.00% | 27.39% | 56.94% | 15.67% | 27.39% |
| `SEVERE_SYNTHETIC_RISK` | 10,970 | 0.4323 | 0.00% | 0.00% | 0.00% | 100.00% | 0.00% |

This is a clean validation result:

- average synthetic estimated-PD proxy increases tier by tier;
- `SEVERE_SYNTHETIC_RISK` routes entirely to final `DECLINE`;
- `LOW_SYNTHETIC_RISK` and `MODERATE_SYNTHETIC_RISK` retain meaningful approval and offer-exposure rates;
- `ELEVATED_SYNTHETIC_RISK` is primarily a counteroffer zone;
- `HIGH_SYNTHETIC_RISK` is mostly manual review, counteroffer, or decline, with no clean approvals.

The offered-versus-declined comparison is also strong:

| Population | Rows | Avg synthetic estimated-PD proxy |
|---|---:|---:|
| Simulated offer exposure | 30,358 | 0.0642 |
| Manual review | 6,939 | 0.1671 |
| Decline | 12,703 | 0.3983 |

The reported status is:

```text
SYNTHETIC_RISK_ORDERING_DIRECTIONALLY_ALIGNED
```

That is exactly the expected Section 14.7 result.

**Monitoring note:** Within `HIGH_SYNTHETIC_RISK`, manual-review rows have slightly higher average synthetic estimated-PD proxy than decline rows. That is not a defect. Final outcomes are not determined by the synthetic estimated-PD proxy alone; hard simulated policy stops, DTI, counteroffer feasibility, exposure treatment, requested Expected Loss, and reason hierarchy all interact. The severe-risk tier remains fully declined, which is the key risk-ordering control.

---

# 14.8 — Requested PTI / affordability sensitivity QA

**Assessment: PASS.**

Requested PTI behavior is highly coherent.

| Requested PTI bucket | Approval rate | Counteroffer rate | Manual review rate | Decline rate | Simulated offer-exposure rate |
|---|---:|---:|---:|---:|---:|
| `LOW_REQUESTED_PTI` | 32.07% | 33.73% | 14.43% | 19.77% | 65.80% |
| `MODERATE_REQUESTED_PTI` | 7.62% | 36.18% | 21.51% | 34.70% | 43.80% |
| `ELEVATED_REQUESTED_PTI` | 0.00% | 58.84% | 8.19% | 32.97% | 58.84% |
| `HIGH_REQUESTED_PTI` | 0.00% | 43.85% | 15.39% | 40.76% | 43.85% |
| `SEVERE_REQUESTED_PTI` | 0.00% | 0.11% | 12.55% | 87.34% | 0.11% |

The affordability sensitivity status check reports:

```text
REQUESTED_PTI_AFFORDABILITY_SENSITIVITY_DIRECTIONALLY_ALIGNED
```

The comparison is clear:

```text
Low/moderate requested PTI approval rate = 29.68%
High/severe requested PTI approval rate  = 0.00%
```

That is a strong validation result.

The counteroffer PTI improvement diagnostic is also clean:

| Metric | Value |
|---|---:|
| Final counteroffer rows | 19,067 |
| Avg requested PTI for counteroffers | 0.1853 |
| Avg approved PTI for counteroffers | 0.1435 |
| Avg PTI reduction | 0.0418 |
| Counteroffer rows without PTI improvement | 0 |

This confirms that final counteroffers improve the approved payment-to-income profile relative to the original requested structure.

**Interpretation note:** Low requested PTI rows still include declines and manual reviews. That is expected. Low requested PTI does not override hard simulated policy stops, severe synthetic estimated-risk, severe DTI, or other risk signals. Section 14.8 validates that affordability matters; it does not imply affordability is the only driver.

---

# 14.9 — DTI capacity QA

**Assessment: PASS.**

DTI behavior is coherent and strongly directional.

| DTI bucket | Approval rate | Counteroffer rate | Manual review rate | Decline rate | Simulated offer-exposure rate |
|---|---:|---:|---:|---:|---:|
| `LOW_DTI` | 53.79% | 42.61% | 2.54% | 1.06% | 96.40% |
| `MODERATE_DTI` | 34.33% | 44.50% | 10.75% | 10.41% | 78.84% |
| `ELEVATED_DTI` | 0.00% | 31.00% | 22.96% | 46.04% | 31.00% |
| `SEVERE_DTI` | 0.00% | 0.00% | 0.00% | 100.00% | 0.00% |

The DTI sensitivity check reports:

```text
DTI_CAPACITY_SENSITIVITY_DIRECTIONALLY_ALIGNED
```

The key comparison is:

```text
Low/moderate DTI approval rate = 35.61%
High/severe DTI approval rate  = 0.00%
```

This is exactly the intended behavior. DTI remains an existing-obligation capacity signal and is not directly fixed through counteroffer in Module 2 v1.0.

The DTI decline-trigger diagnostic also passes:

- all `dti_decline_trigger_flag = TRUE` rows resolve to final `DECLINE`;
- some are explained by higher-priority hard policy stop or severe synthetic-risk reasons;
- 445 rows receive the specific `POLICY_STOP_HIGH_DTI` primary reason via `SEVERE_DTI_CAPACITY`.

That is correct hierarchy behavior. A severe DTI row can be declined for bankruptcy, major derogatory, recent delinquency, or severe synthetic risk if those higher-priority routes fire first.

**Monitoring note:** `HIGH_DTI` remains absent because the configured DTI review and decline thresholds leave no separate high-but-not-severe DTI interval. That was already observed in Section 5 and is parameter-consistent, not a defect.

---

# 14.10 — Approved exposure and Expected Loss QA

**Assessment: PASS.**

The final approved exposure and Expected Loss conventions are fully intact.

## Outcome-level exposure and economics

| Final outcome | Rows | Avg requested amount | Avg approved amount all apps | Avg approved amount offer rows | Avg requested Expected Loss | Avg approved Expected Loss all apps | Avg approved Expected Loss offer rows |
|---|---:|---:|---:|---:|---:|---:|---:|
| `APPROVE` | 11,291 | 112,594 | 112,594 | 112,594 | 765.74 | 765.74 | 765.74 |
| `COUNTEROFFER` | 19,067 | 176,816 | 136,792 | 136,792 | 3,474.72 | 2,637.22 | 2,637.22 |
| `MANUAL_REVIEW` | 6,939 | 112,763 | 0 | NULL | 4,535.33 | 0 | NULL |
| `DECLINE` | 12,703 | 97,721 | 0 | NULL | 10,475.04 | 0 | NULL |

The convention checks all return zero violations:

```text
approved amount convention violation rows = 0 across all outcomes
approved Expected Loss convention violation rows = 0 across all outcomes
negative approved amount rows = 0
approved amount above requested amount rows = 0
negative approved Expected Loss rows = 0
```

This is a major acceptance point.

## Counteroffer economics

Counteroffers reduce exposure and expected loss:

```text
Avg requested amount:             176,816
Avg approved amount:              136,792
Avg exposure reduction pct:        19.786%

Avg requested Expected Loss:       3,474.72
Avg approved Expected Loss:        2,637.22
Avg approved EL reduction pct:     19.786%
```

The matching reduction percentages are expected because approved Expected Loss is proportional to approved exposure:

```text
approved_amount × estimated_pd × estimated_lgd
```

using the synthetic estimated-PD proxy and LGD already carried from Module 1.

**Monitoring note:** The minimum counteroffer exposure reduction percentage is very small, approximately `0.000004`. That is not a violation because the amount is still below the requested amount, but it is a useful future QA-monitoring item. If the strategy owner wants counteroffers to represent a more material reduction, that should be handled through governed counteroffer parameters, not downstream CASE rewrites.

## Product-level exposure and Expected Loss

Product-level summaries remain coherent:

| Product | Applications | Simulated offer-exposure rate | Total requested amount | Total approved amount | Total requested Expected Loss | Total approved Expected Loss |
|---|---:|---:|---:|---:|---:|---:|
| `AUTO_LOAN` | 9,946 | 59.88% | 432.32M | 243.44M | 30.07M | 6.03M |
| `HELOC` | 4,962 | 60.42% | 697.28M | 374.50M | 29.33M | 6.01M |
| `MORTGAGE` | 15,065 | 60.28% | 5.11B | 3.04B | 130.19M | 37.87M |
| `REVOLVING_LINE` | 12,455 | 62.90% | 215.55M | 113.99M | 26.76M | 5.08M |
| `UNSECURED_PERSONAL_LOAN` | 7,572 | 59.28% | 213.37M | 107.74M | 23.08M | 3.94M |

Mortgage appropriately dominates total requested and approved exposure. That is product-structure driven and consistent with the Module 1 product behavior framework, where product type drives exposure, payment burden, LGD, and Expected Loss behavior. fileciteturn4file1

---

# 14.11 — Counteroffer validation diagnostics

**Assessment: PASS.**

Counteroffer diagnostics remain aligned with Sections 8–10.

## Counteroffer summary

| Metric | Value |
|---|---:|
| Final counteroffer rows | 19,067 |
| Preliminary counteroffer rows | 21,286 |
| Feasible counteroffers | 19,067 |
| Failed counteroffers | 2,219 |
| Feasibility pass rate | 89.58% |
| Avg exposure reduction pct | 19.79% |
| Avg requested PTI | 18.53% |
| Avg approved PTI | 14.35% |
| Avg PTI reduction | 4.18 percentage points |
| Avg requested Expected Loss | 3,474.72 |
| Avg approved Expected Loss | 2,637.22 |
| Avg approved EL reduction pct | 19.79% |

This validates that final `COUNTEROFFER` rows are feasible reduced-exposure outcomes.

## Counteroffer failure reasons

| Failure reason | Rows | Share of failed preliminary counteroffers |
|---|---:|---:|
| `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT` | 2,070 | 93.29% |
| `COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT` | 89 | 4.01% |
| `COUNTEROFFER_EXCEEDS_MAX_REDUCTION` | 60 | 2.70% |

This is coherent and matches earlier Section 8 / Section 10 findings.

Most failures are driven by the minimum viable offer framework rather than missing configuration or calculation nulls. That is a business-rule feasibility constraint, not a calculation failure.

## Product × counteroffer feasibility

| Product | Feasible | Failed | Pass rate |
|---|---:|---:|---:|
| `AUTO_LOAN` | 3,167 | 385 | 89.16% |
| `HELOC` | 1,872 | 109 | 94.50% |
| `MORTGAGE` | 5,848 | 509 | 92.00% |
| `REVOLVING_LINE` | 5,231 | 717 | 87.94% |
| `UNSECURED_PERSONAL_LOAN` | 2,949 | 499 | 85.53% |

Product differentiation is reasonable. Unsecured Personal Loan and Revolving Line have the lowest feasibility pass rates, which is intuitive given their unsecured / revolving exposure sensitivity.

## Score band × counteroffer feasibility

| Score band | Feasible | Failed | Pass rate |
|---|---:|---:|---:|
| `SUPER_PRIME` | 3,611 | 11 | 99.70% |
| `PRIME` | 5,657 | 59 | 98.97% |
| `NEAR_PRIME` | 8,818 | 737 | 92.29% |
| `SUBPRIME` | 980 | 1,411 | 40.99% |
| `DEEP_SUBPRIME` | 1 | 1 | 50.00% |

This is directionally strong:

- stronger score bands almost always pass feasibility;
- Near Prime remains mostly feasible;
- Subprime has significant feasibility pressure;
- Deep Subprime has only two preliminary counteroffer rows, so the 50% pass rate should not be overinterpreted.

## Final counteroffer convention checks

All violation counts are zero:

```text
final_counteroffer_without_feasibility_pass_rows = 0
final_counteroffer_amount_violation_rows = 0
final_counteroffer_amount_mismatch_rows = 0
final_counteroffer_exposure_reduction_flag_violation_rows = 0
final_counteroffer_approved_pti_above_target_rows = 0
final_counteroffer_approved_el_above_product_cap_rows = 0
final_counteroffer_reason_family_violation_rows = 0
```

This is the core Section 14.11 acceptance result.

## Counteroffer primary reason-code distribution

| Primary reason code | Final counteroffer rows | Share |
|---|---:|---:|
| `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` | 8,905 | 46.70% |
| `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` | 5,021 | 26.33% |
| `COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT` | 3,853 | 20.21% |
| `COUNTEROFFER_EXPECTED_LOSS_LIMIT` | 1,288 | 6.76% |

This is strong explanation-code coverage. Counteroffer reasons are not generic; they distinguish exposure limit, affordability adjustment, synthetic-risk exposure limit, and approved Expected Loss constraints.

---

# Section 14.7–14.11 acceptance conclusion

Sections 14.7 through 14.11 pass.

Accepted evidence:

- Synthetic estimated-risk tiers are directionally ordered.
- Offered rows have materially lower average synthetic estimated-PD proxy than declined rows.
- Manual-review rows sit between offer and decline rows on average synthetic estimated-risk.
- Requested PTI sensitivity is directionally aligned.
- High/severe requested PTI buckets have zero approval rate.
- Counteroffers reduce approved PTI relative to requested PTI.
- DTI sensitivity is directionally aligned.
- Severe DTI rows resolve entirely to final decline.
- Approved amount convention checks return zero violations.
- Approved Expected Loss convention checks return zero violations.
- Counteroffers reduce approved amount and approved Expected Loss.
- Manual review remains unresolved.
- Decline follows the zero-exposure convention.
- Product-level requested versus approved exposure behavior is coherent.
- Counteroffer feasibility pass rate is interpretable.
- Failed counteroffers have deterministic, explainable failure reasons.
- Product and score-band counteroffer feasibility behavior is directionally coherent.
- Final counteroffer convention checks return zero violations.
- Counteroffer primary reason-code distribution is outcome-family aligned and interpretable.
- No decisions, reason codes, approved exposure, or Expected Loss values are recalculated by Section 14.

## Patch recommendation

No Section 14.7–14.11 logic patch is recommended.

## Monitoring notes for final QA evidence

Two items should be carried forward as **review notes**, not defects:

1. **Very small minimum counteroffer reduction**
   - Minimum counteroffer exposure reduction percentage is approximately `0.000004`.
   - This passes current rules because approved amount is still below requested amount.
   - If a more material reduction is desired, tune governed counteroffer parameters later.

2. **Counteroffer failure concentration**
   - 93.29% of failed preliminary counteroffers fail due to `COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT`.
   - This is explainable and currently acceptable.
   - It should be mentioned in the Validation Summary as evidence that infeasible counteroffers are primarily constrained by the minimum viable offer framework.

Next review batch should cover **Sections 14.12–14.19**: manual review diagnostics, decline / policy-stop diagnostics, reason-code coverage, simulated offer-exposure profile, edge cases, final convention validation, archive readiness, and validation status summary.
<!-- END_MESSAGE C038-M00383 -->


---

<a id="c038-m00385"></a>

### C038-M00385

**Andrew** · 2026-05-08T11:02:54.457000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00385 -->
review section 14.12 - 14.13 QA:
<!-- END_MESSAGE C038-M00385 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13A_QB_module_2_validation_decline_policy_stop_validation_diagnostics.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13B_QB_module_2_validation_declines_by_decision_path.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13C_QB_module_2_validation_declines_by_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13D_QB_module_2_validation_hard_simulated_policy_stop_flags_among_declines.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13E_QB_module_2_validation_decline_driver_diagnostic_by_major_trigger_family.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13F_QB_module_2_validation_decline_zero_exposure_convention_expected_result_all_violation_counts_zero.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.13G_QB_module_2_validation_decline_decline_reason_family_alignment_check_expected_result_all_violation_counts_zero.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12A_QA_module_2_validation_manual_review_validation_diagnostics.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12B_QB_module_2_validation_manual_review_by_decision_path.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12C_QB_module_2_validation_manual_review_by_primary_reason_code.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12D_QB_module_2_validation_mixed_signal_profile_x_manual_review_count.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12E_QB_module_2_validation_borderline_profile_x_manual_review_count.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12F_QB_module_2_validation_failed_counteroffer_to_manual_review_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_14.12G_QB_module_2_validation_manual_review_unresolved_exposure_convention_expected_result_all_violation_counts_zero.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_19.md) · [Next](Part_21.md)
