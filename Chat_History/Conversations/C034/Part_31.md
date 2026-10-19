# Module 1 Synthetic Application Portfolio Build

## Part 31

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_30.md) · [Next](Part_32.md)

<a id="c034-m01579"></a>

### C034-M01579

**ChatGPT** · 2026-05-17T13:42:52.827764-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01579 -->
## M2-01 Section 8 QA review verdict

```text
Section 8 QA status: PASS
Selected run: M2-01
Strategy: BASELINE_STRATEGY
Stage 5 rows: 50,000
Distinct application_id count: 50,000
Preliminary exposure treatment: coherent
Counteroffer feasibility evaluation: coherent
Approved exposure / PTI / Expected Loss conventions: coherent
Option C aggressive override posture: correctly inactive
Section 8 readiness status: SECTION_8_EXPOSURE_TREATMENT_READY_FOR_FINAL_DECISION_RESOLUTION
Blockers: none
```

Section 8 is behaving as designed. It converts preliminary routing into preliminary approved exposure treatment and counteroffer feasibility evidence, while still avoiding final decision assignment. That matches the Section 8 boundary: it answers what approved exposure treatment is economically and structurally feasible, but it does **not** answer the final simulated strategy outcome. fileciteturn394file37

---

## 1. Preliminary route × exposure treatment status — 8.4.1

The exposure treatment mapping is clean:

```text
APPROVE
    APPROVED_AS_REQUESTED_PRELIMINARY          10,695

COUNTEROFFER
    COUNTEROFFER_FEASIBLE_PRELIMINARY          19,067
    COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY       2,219

MANUAL_REVIEW
    UNRESOLVED_MANUAL_REVIEW                    5,316

DECLINE
    NO_OFFER_PRELIMINARY_DECLINE               12,703
```

This reconciles exactly to:

```text
50,000 rows
```

Interpretation:

```text
Preliminary APPROVE rows receive approved-as-requested treatment.
Preliminary COUNTEROFFER rows are split into feasible and infeasible after exposure treatment.
Preliminary MANUAL_REVIEW rows remain unresolved.
Preliminary DECLINE rows receive no-offer treatment.
```

**Status: PASS**

---

## 2. Exposure treatment path — 8.4.2

The path-level output mirrors 8.4.1 and is internally consistent:

```text
APPROVE_AS_REQUESTED          10,695   21.39%
COUNTEROFFER_FEASIBLE         19,067   38.13%
COUNTEROFFER_NOT_FEASIBLE      2,219    4.44%
MANUAL_REVIEW_UNRESOLVED       5,316   10.63%
NO_OFFER                      12,703   25.41%
```

No unexpected path values appear.

**Status: PASS**

---

## 3. Counteroffer feasibility evaluated flag — 8.4.3

This is exactly right:

```text
counteroffer_feasibility_evaluated_flag = TRUE
    preliminary_decision_outcome = COUNTEROFFER    21,286

counteroffer_feasibility_evaluated_flag = FALSE
    APPROVE         10,695
    MANUAL_REVIEW    5,316
    DECLINE         12,703
```

Interpretation:

```text
Only preliminary COUNTEROFFER rows are sent through counteroffer feasibility testing.
```

No leakage into approve, manual review, or decline rows.

**Status: PASS**

---

## 4. Counteroffer feasibility pass / fail — 8.4.4

The preliminary counteroffer population is:

```text
total preliminary counteroffer rows = 21,286
feasible preliminary counteroffers  = 19,067
infeasible preliminary counteroffers = 2,219
```

Approximate pass rate:

```text
19,067 / 21,286 = 89.58%
```

Approximate fail rate:

```text
2,219 / 21,286 = 10.42%
```

This is plausible and useful. The strategy routes a large counteroffer candidate population into feasibility, but still blocks a meaningful subset where reduced exposure does not meet feasibility constraints.

**Status: PASS**

---

## 5. Counteroffer failure reasons — 8.4.5

Failure reason distribution:

```text
COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT    2,070
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT            89
COUNTEROFFER_EXCEEDS_MAX_REDUCTION                 60
```

This totals exactly:

```text
2,219 failed preliminary counteroffers
```

Interpretation:

```text
The dominant failure reason is minimum requested-percent feasibility.
A small number fail because the rounded counteroffer would not actually reduce the request.
A smaller HELOC-specific set fails maximum exposure-reduction constraints.
```

That is coherent and consistent with a governed counteroffer feasibility layer.

**Status: PASS**

---

## 6. Product × counteroffer feasibility — 8.4.6

Product-level feasibility is coherent.

Approximate pass rates by product:

```text
AUTO_LOAN                  3,167 / 3,552 = 89.16%
HELOC                      1,872 / 1,981 = 94.50%
MORTGAGE                   5,848 / 6,357 = 92.00%
REVOLVING_LINE             5,231 / 5,948 = 87.95%
UNSECURED_PERSONAL_LOAN    2,949 / 3,448 = 85.53%
```

Feasible counteroffers reduce exposure and improve approved PTI / approved Expected Loss. Failed counteroffers correctly show no preliminary approved amount, no preliminary approved PTI, and no preliminary approved Expected Loss.

Product-specific observations:

```text
MORTGAGE has the largest average approved exposure and largest dollar reduction.
REVOLVING_LINE and UNSECURED_PERSONAL_LOAN have higher relative reduction percentages.
HELOC has the highest pass rate.
UNSECURED_PERSONAL_LOAN has the lowest pass rate, which is plausible given smaller caps / minimum amount constraints.
```

**Status: PASS**

---

## 7. Score band × counteroffer feasibility — 8.4.7

Score-band feasibility is directionally strong.

Approximate pass rates:

```text
SUPER_PRIME       3,611 / 3,622 = 99.70%
PRIME             5,657 / 5,716 = 98.97%
NEAR_PRIME        8,818 / 9,555 = 92.29%
SUBPRIME            980 / 2,391 = 40.99%
DEEP_SUBPRIME         1 / 2     = 50.00%   tiny count
```

Interpretation:

```text
Stronger-score counteroffer candidates nearly always pass feasibility.
Near-prime remains mostly feasible.
Subprime feasibility drops materially.
Deep-subprime has only two preliminary counteroffer rows, so the percentage is not analytically meaningful.
```

This is coherent and supports the intended risk-sensitive treatment.

**Status: PASS**

---

## 8. Requested PTI bucket × counteroffer feasibility — 8.4.8

Requested PTI behavior is coherent.

Approximate pass rates:

```text
LOW_REQUESTED_PTI          5,482 / 5,656 = 96.92%
MODERATE_REQUESTED_PTI     7,439 / 8,297 = 89.66%
ELEVATED_REQUESTED_PTI     5,125 / 5,838 = 87.79%
HIGH_REQUESTED_PTI         1,020 / 1,378 = 74.02%
SEVERE_REQUESTED_PTI           1 / 117   =  0.85%
```

Interpretation:

```text
As requested PTI pressure increases, counteroffer feasibility becomes harder.
Severe requested PTI is almost entirely infeasible, which is expected.
```

The one severe-PTI feasible row is not a blocker. It likely reflects product-specific thresholds, rounding, and the fact that feasibility is product-policy-relative.

**Status: PASS**

---

## 9. Strategy risk tier × counteroffer feasibility — 8.4.9

Risk-tier feasibility is coherent.

Approximate pass rates:

```text
LOW_SYNTHETIC_RISK          6,026 / 6,037 = 99.82%
MODERATE_SYNTHETIC_RISK     3,306 / 3,363 = 98.31%
ELEVATED_SYNTHETIC_RISK     7,979 / 8,269 = 96.49%
HIGH_SYNTHETIC_RISK         1,756 / 3,617 = 48.55%
```

There are no severe synthetic-risk preliminary counteroffer rows in this output, which is expected because severe synthetic-risk rows were routed to preliminary decline before Section 8.

Interpretation:

```text
Low, moderate, and elevated synthetic-risk counteroffer candidates usually remain feasible.
High synthetic-risk counteroffer candidates face much tighter feasibility pressure.
```

**Status: PASS**

---

## 10. Requested amount versus preliminary approved amount — 8.4.10

This output is strong.

Key rows:

```text
APPROVED_AS_REQUESTED_PRELIMINARY
    avg requested amount = 113,984.96
    avg approved amount  = 113,984.96
    average reduction    = 0.00%

COUNTEROFFER_FEASIBLE_PRELIMINARY
    avg requested amount = 176,816.14
    avg approved amount  = 136,791.79
    avg dollar reduction = 40,024.36
    avg pct reduction    = 19.786%

COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
    avg requested amount = 136,023.96
    avg approved amount  = NULL / unresolved

NO_OFFER_PRELIMINARY_DECLINE
    avg approved amount = 0

UNRESOLVED_MANUAL_REVIEW
    avg approved amount = NULL / unresolved
```

Interpretation:

```text
Approve preserves requested exposure.
Feasible counteroffer reduces exposure.
Failed counteroffer remains unresolved for Section 9 final resolution.
Manual review remains unresolved.
Preliminary decline follows the no-offer convention.
```

**Status: PASS**

One export-readability note: the totals show `0` for some unresolved / no-offer groups because aggregate totals appear to coalesce null approved amounts to zero. The average columns correctly distinguish `NULL` unresolved rows from zero-exposure no-offer rows.

---

## 11. Requested PTI versus preliminary approved PTI — 8.4.11

This is coherent.

```text
APPROVED_AS_REQUESTED_PRELIMINARY
    requested PTI = approved PTI
    reduction = 0

COUNTEROFFER_FEASIBLE_PRELIMINARY
    avg requested PTI = 0.185296
    avg approved PTI  = 0.143459
    avg PTI reduction = 0.041837

COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
    approved PTI = NULL

NO_OFFER_PRELIMINARY_DECLINE
    approved PTI = 0 by no-offer convention

UNRESOLVED_MANUAL_REVIEW
    approved PTI = NULL
```

Interpretation:

```text
Feasible counteroffers reduce affordability burden.
Failed counteroffers do not receive preliminary approved PTI.
Manual review remains unresolved.
Decline uses no-offer convention.
```

**Status: PASS**

---

## 12. Requested Expected Loss versus preliminary approved Expected Loss — 8.4.12

This is also coherent.

```text
APPROVED_AS_REQUESTED_PRELIMINARY
    requested EL = approved EL

COUNTEROFFER_FEASIBLE_PRELIMINARY
    avg requested EL = 3,474.72
    avg approved EL  = 2,637.22
    avg EL reduction =   837.50
    avg pct reduction = 19.786%

COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
    approved EL = NULL / unresolved

NO_OFFER_PRELIMINARY_DECLINE
    approved EL = 0

UNRESOLVED_MANUAL_REVIEW
    approved EL = NULL / unresolved
```

The counteroffer EL reduction percentage mirrors the exposure reduction percentage, which is expected because approved Expected Loss is computed from approved amount × synthetic estimated-PD proxy × LGD while estimated-PD proxy and LGD remain unchanged in Module 2.

**Status: PASS**

---

## 13. Average exposure reduction by product for feasible counteroffers — 8.4.13

Product-level exposure reduction is coherent:

```text
AUTO_LOAN
    avg reduction =  9,593.03
    avg pct reduction = 15.00%

HELOC
    avg reduction = 41,111.29
    avg pct reduction = 18.67%

MORTGAGE
    avg reduction = 102,739.24
    avg pct reduction = 20.51%

REVOLVING_LINE
    avg reduction =  5,503.85
    avg pct reduction = 21.51%

UNSECURED_PERSONAL_LOAN
    avg reduction =  8,882.07
    avg pct reduction = 21.14%
```

Interpretation:

```text
Mortgage has the largest dollar exposure reduction.
Revolving line and unsecured personal loan have the highest relative reduction percentages.
Auto loans have the lowest average relative reduction.
```

This is sensible given product caps, requested amounts, and minimum/maximum counteroffer constraints.

**Status: PASS**

---

## 14. Counteroffer failures by product and failure reason — 8.4.14

This output is internally consistent. Failed rows by product reconcile exactly to the product false counts in 8.4.6:

```text
AUTO_LOAN                  385
HELOC                      109
MORTGAGE                   509
REVOLVING_LINE             717
UNSECURED_PERSONAL_LOAN    499
total                    2,219
```

Dominant reason:

```text
COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT = 2,070
```

Notable product details:

```text
REVOLVING_LINE has the largest failure count, mostly below minimum requested percent.
MORTGAGE has 83 not-below-requested-amount failures, all around 75,000 requested amount.
HELOC has the only max-reduction failure group, 60 rows.
AUTO_LOAN, REVOLVING_LINE, and UNSECURED_PERSONAL_LOAN each have small not-below-requested amount groups around product minimums.
```

This is coherent. It suggests the failure logic is not random; it is concentrated in interpretable product and feasibility constraints.

**Status: PASS**

---

## 15. Counteroffer feasibility constraint count distribution — 8.4.15

This is clean:

```text
Failed with 1 constraint =   149
Failed with 2 constraints = 2,070
Passed with 0 constraints = 19,067
```

This reconciles exactly to the pass/fail totals.

Interpretation:

```text
Passing rows have zero feasibility constraint failures.
Most failed rows have two binding constraints, consistent with below-minimum-requested-percent failures.
A smaller group has one binding feasibility issue.
```

**Status: PASS**

---

## 16. Section 8 readiness summary — 8.4.16

This is the controlling signoff row, and it passes cleanly:

```text
stage5_row_count = 50,000
distinct_application_id_count = 50,000

exposure_treatment_gap_rows = 0
counteroffer_feasibility_gap_rows = 0
approve_amount_convention_gap_rows = 0
decline_zero_exposure_convention_gap_rows = 0
manual_review_unresolved_convention_gap_rows = 0

preliminary_approve_rows = 10,695
preliminary_counteroffer_rows = 21,286
feasible_preliminary_counteroffer_rows = 19,067
infeasible_preliminary_counteroffer_rows = 2,219
preliminary_manual_review_rows = 5,316
preliminary_decline_rows = 12,703

aggressive_override_candidate_rows = 0
aggressive_override_preliminary_counteroffer_rows = 0
aggressive_override_feasibility_evaluated_rows = 0
aggressive_override_feasible_counteroffer_rows = 0
aggressive_override_failed_counteroffer_rows = 0
aggressive_override_feasibility_gap_rows = 0

section_8_exposure_treatment_status =
    SECTION_8_EXPOSURE_TREATMENT_READY_FOR_FINAL_DECISION_RESOLUTION
```

This is exactly the status needed before Section 9.

**Status: PASS**

---

## 17. Option C aggressive override feasibility diagnostic — 8.4.17

This output is empty, which is correct for M2-01.

M2-01 is:

```text
BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
```

So there should be no aggressive override rows to diagnose.

**Status: PASS / correctly not applicable for baseline**

---

## 18. Option C aggressive override feasibility rollup — 8.4.18

The rollup confirms the correct baseline posture:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive_override_rows = 0
aggressive_override_preliminary_counteroffer_rows = 0
aggressive_override_feasible_rows = 0
aggressive_override_failed_rows = 0
pct_aggressive_override_rows = 0.0
```

The pass-rate and average aggressive-override metrics are NULL because there are zero aggressive override rows. That is correct.

**Status: PASS**

---

# Final Section 8 QA signoff

```text
M2-01 Section 8 QA: ACCEPTED

No blockers.
No row-count issue.
No application-grain issue.
No exposure-treatment mapping issue.
No counteroffer feasibility evaluation leakage.
No approved-as-requested convention issue.
No preliminary decline zero-exposure convention issue.
No manual-review unresolved convention issue.
No counteroffer feasibility gap.
No Option C aggressive override leakage.
Section 8 is ready for Section 9 final decision resolution.
```

Section 8 is materially strong. It shows the intended transition from preliminary routing into exposure-treatment feasibility, while correctly preserving final outcome resolution for Section 9.

---

# Suggested Section 8 QA refinements

No core logic changes are needed. I would consider two QA/export-only refinements if you want the Section 8 evidence package to be maximally self-explanatory.

## Recommended refinement 1 — add interpretation notes to 8.4.10, 8.4.11, and 8.4.12

These outputs are correct, but the distinction between:

```text
NULL unresolved exposure / PTI / EL
```

and:

```text
zero no-offer convention
```

can be easy to miss in CSV exports.

A hardcoded note would help explain:

```text
COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY and UNRESOLVED_MANUAL_REVIEW keep approved values NULL at this layer.
NO_OFFER_PRELIMINARY_DECLINE uses zero-exposure / zero-EL convention.
Section 9 performs final decision resolution.
```

This is a readability enhancement only.

## Recommended refinement 2 — add pass-rate fields to 8.4.4 or 8.4.16

The pass/fail counts are clear, but a preserved QA export would be easier to read if it included:

```text
counteroffer_feasibility_pass_rate = 0.8958
counteroffer_feasibility_fail_rate = 0.1042
```

This is not required because the counts are already easy to calculate, but it is useful for evidence preservation.

## Optional refinement 3 — add an interpretation note to 8.4.17

Because 8.4.17 is expected to be empty for M2-01, a reviewer might wonder whether the query failed or whether no rows are expected. You could add a preceding rollup like 8.4.18, or simply rely on 8.4.18 as the explanation.

I would **not** change 8.4.17 unless you want every empty-query export to have an explanatory companion.

## Recommendation

```text
Apply only refinement 1 if preserving Section 8 CSV exports is a priority.
Optionally apply refinement 2 for convenience.
Do not change Section 8 core logic.
```

The current Section 8 QA is accepted as-is.
<!-- END_MESSAGE C034-M01579 -->


---

<a id="c034-m01581"></a>

### C034-M01581

**Andrew** · 2026-05-17T13:46:58.459000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01581 -->
proceed with recommended/optional section 8 QA refinements to 8.4.4, 8.4.10-8.4.12, and 8.4.16-8.4.17  give full copy paste.
<!-- END_MESSAGE C034-M01581 -->


---

<a id="c034-m01585"></a>

### C034-M01585

**ChatGPT** · 2026-05-17T13:53:59.672946-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01585 -->
These replacements keep Section 8 as the **preliminary exposure-treatment and counteroffer-feasibility layer**: it calculates preliminary approved exposure, approved PTI proxy, approved Expected Loss, and counteroffer feasibility, but still does not assign final outcomes or reason codes. fileciteturn395file0

Replace the existing **8.4.4, 8.4.10, 8.4.11, 8.4.12, 8.4.16, and 8.4.17** blocks with the full copy-paste versions below.

---

## Replace 8.4.4 with this

```sql
/*-----------------------------------------------------------------------------------------------
8.4.4 Count by counteroffer_feasibility_pass_flag.

Purpose:
    Summarize pass / fail behavior for rows routed to preliminary COUNTEROFFER feasibility testing.

Interpretation:
    counteroffer_feasibility_pass_flag is evaluated only for preliminary COUNTEROFFER rows.

    A TRUE value means Section 8 produced a viable reduced-exposure preliminary counteroffer.

    A FALSE value means Section 8 tested the row but did not produce a viable preliminary
    counteroffer under the governed product cap, minimum amount, minimum counteroffer percent,
    maximum exposure-reduction, approved PTI target, approved Expected Loss cap, and rounding rules.

Documentation note:
    counteroffer_feasibility_pass_rate and counteroffer_feasibility_fail_rate are calculated against
    the preliminary COUNTEROFFER population, not the full 50,000-row strategy population.

Boundary:
    This is a preliminary feasibility diagnostic.

    A passed preliminary counteroffer does not become a final COUNTEROFFER until Section 9.
    A failed preliminary counteroffer remains unresolved until Section 9 applies the governed
    failed_counteroffer_resolution parameter.
-----------------------------------------------------------------------------------------------*/

WITH preliminary_counteroffer_rows AS (
    SELECT *
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
),

counteroffer_feasibility_summary AS (
    SELECT
        counteroffer_feasibility_pass_flag,

        COUNT(*) AS row_count,

        AVG(counteroffer_feasibility_constraint_count)
            AS avg_counteroffer_feasibility_constraint_count,

        AVG(requested_amount)
            AS avg_requested_amount,

        AVG(approved_amount_preliminary)
            AS avg_approved_amount_preliminary,

        AVG(exposure_reduction_amount_preliminary)
            AS avg_exposure_reduction_amount_preliminary,

        AVG(exposure_reduction_pct_preliminary)
            AS avg_exposure_reduction_pct_preliminary,

        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio_preliminary)
            AS avg_approved_payment_to_income_ratio_preliminary,

        AVG(requested_expected_loss_amount)
            AS avg_requested_expected_loss_amount,

        AVG(approved_expected_loss_amount_preliminary)
            AS avg_approved_expected_loss_amount_preliminary

    FROM preliminary_counteroffer_rows

    GROUP BY counteroffer_feasibility_pass_flag
),

total_preliminary_counteroffer_rows AS (
    SELECT COUNT(*) AS total_counteroffer_rows
    FROM preliminary_counteroffer_rows
)

SELECT
    'Pass/fail rates are calculated within preliminary COUNTEROFFER rows only; Section 8 tests feasibility, while Section 9 resolves the final simulated outcome.'::TEXT
        AS interpretation_note,

    s.counteroffer_feasibility_pass_flag,

    s.row_count,

    ROUND(
        s.row_count::NUMERIC
        / NULLIF(t.total_counteroffer_rows, 0),
        6
    ) AS pct_of_preliminary_counteroffer_rows,

    CASE
        WHEN s.counteroffer_feasibility_pass_flag IS TRUE
            THEN ROUND(
                s.row_count::NUMERIC
                / NULLIF(t.total_counteroffer_rows, 0),
                6
            )
        ELSE 0::NUMERIC
    END AS counteroffer_feasibility_pass_rate,

    CASE
        WHEN s.counteroffer_feasibility_pass_flag IS FALSE
            THEN ROUND(
                s.row_count::NUMERIC
                / NULLIF(t.total_counteroffer_rows, 0),
                6
            )
        ELSE 0::NUMERIC
    END AS counteroffer_feasibility_fail_rate,

    s.avg_counteroffer_feasibility_constraint_count,

    s.avg_requested_amount,
    s.avg_approved_amount_preliminary,
    s.avg_exposure_reduction_amount_preliminary,
    s.avg_exposure_reduction_pct_preliminary,

    s.avg_requested_payment_to_income_ratio,
    s.avg_approved_payment_to_income_ratio_preliminary,

    s.avg_requested_expected_loss_amount,
    s.avg_approved_expected_loss_amount_preliminary

FROM counteroffer_feasibility_summary s

CROSS JOIN total_preliminary_counteroffer_rows t

ORDER BY
    CASE
        WHEN s.counteroffer_feasibility_pass_flag IS TRUE THEN 1
        WHEN s.counteroffer_feasibility_pass_flag IS FALSE THEN 2
        ELSE 99
    END;
```

---

## Replace 8.4.10 with this

```sql
/*-----------------------------------------------------------------------------------------------
8.4.10 Requested amount versus preliminary approved amount by exposure_treatment_status.

Purpose:
    Compare requested exposure to preliminary approved exposure by Section 8 exposure-treatment
    status.

Interpretation:
    APPROVED_AS_REQUESTED_PRELIMINARY:
        Preliminary approved amount should equal requested amount.

    COUNTEROFFER_FEASIBLE_PRELIMINARY:
        Preliminary approved amount should be positive and below requested amount.

    COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY:
        Preliminary approved amount remains NULL because no viable reduced-exposure offer was
        produced at this layer.

    UNRESOLVED_MANUAL_REVIEW:
        Preliminary approved amount remains NULL because the row is unresolved.

    NO_OFFER_PRELIMINARY_DECLINE:
        Preliminary approved amount uses the zero-exposure convention.

Documentation note:
    NULL approved values represent unresolved treatment.
    Zero approved values represent no-offer treatment.

Boundary:
    This is a Section 8 preliminary exposure diagnostic.

    Final approved_amount is created in Section 9.
-----------------------------------------------------------------------------------------------*/

SELECT
    'NULL preliminary approved amount means unresolved treatment; zero preliminary approved amount means no-offer convention; Section 9 creates final approved_amount.'::TEXT
        AS interpretation_note,

    CASE exposure_treatment_status
        WHEN 'APPROVED_AS_REQUESTED_PRELIMINARY' THEN 1
        WHEN 'COUNTEROFFER_FEASIBLE_PRELIMINARY' THEN 2
        WHEN 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY' THEN 3
        WHEN 'UNRESOLVED_MANUAL_REVIEW' THEN 4
        WHEN 'NO_OFFER_PRELIMINARY_DECLINE' THEN 5
        ELSE 99
    END AS exposure_treatment_status_rank,

    exposure_treatment_status,
    exposure_treatment_path,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_stage5_rows,

    COUNT(*) FILTER (
        WHERE approved_amount_preliminary IS NULL
    ) AS null_preliminary_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount_preliminary = 0
    ) AS zero_preliminary_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount_preliminary > 0
    ) AS positive_preliminary_approved_amount_rows,

    AVG(requested_amount)
        AS avg_requested_amount,

    AVG(approved_amount_preliminary)
        AS avg_approved_amount_preliminary,

    AVG(requested_amount - approved_amount_preliminary) FILTER (
        WHERE approved_amount_preliminary IS NOT NULL
    ) AS avg_preliminary_exposure_reduction_amount,

    AVG(exposure_reduction_amount_preliminary)
        AS avg_exposure_reduction_amount_preliminary,

    AVG(exposure_reduction_pct_preliminary)
        AS avg_exposure_reduction_pct_preliminary,

    SUM(requested_amount)
        AS total_requested_amount,

    SUM(COALESCE(approved_amount_preliminary, 0))
        AS total_preliminary_approved_amount

FROM tmp_m2_stage_5_exposure_treatment

GROUP BY
    exposure_treatment_status,
    exposure_treatment_path

ORDER BY
    exposure_treatment_status_rank,
    exposure_treatment_status,
    exposure_treatment_path;
```

---

## Replace 8.4.11 with this

```sql
/*-----------------------------------------------------------------------------------------------
8.4.11 Requested PTI versus preliminary approved PTI by exposure_treatment_status.

Purpose:
    Compare requested-structure PTI to preliminary approved PTI by Section 8 exposure-treatment
    status.

Interpretation:
    APPROVED_AS_REQUESTED_PRELIMINARY:
        Preliminary approved PTI should equal requested PTI.

    COUNTEROFFER_FEASIBLE_PRELIMINARY:
        Preliminary approved PTI should generally be lower than requested PTI because exposure is
        reduced.

    COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY:
        Preliminary approved PTI remains NULL because no viable reduced-exposure offer was produced.

    UNRESOLVED_MANUAL_REVIEW:
        Preliminary approved PTI remains NULL because the row is unresolved.

    NO_OFFER_PRELIMINARY_DECLINE:
        Preliminary approved PTI uses the zero no-offer convention.

Documentation note:
    NULL approved PTI means unresolved treatment.
    Zero approved PTI means no-offer treatment.

Boundary:
    This is a Section 8 preliminary affordability diagnostic.

    Final approved_payment_to_income_ratio is created in Section 9.
-----------------------------------------------------------------------------------------------*/

SELECT
    'NULL preliminary approved PTI means unresolved treatment; zero preliminary approved PTI means no-offer convention; Section 9 creates final approved_payment_to_income_ratio.'::TEXT
        AS interpretation_note,

    CASE exposure_treatment_status
        WHEN 'APPROVED_AS_REQUESTED_PRELIMINARY' THEN 1
        WHEN 'COUNTEROFFER_FEASIBLE_PRELIMINARY' THEN 2
        WHEN 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY' THEN 3
        WHEN 'UNRESOLVED_MANUAL_REVIEW' THEN 4
        WHEN 'NO_OFFER_PRELIMINARY_DECLINE' THEN 5
        ELSE 99
    END AS exposure_treatment_status_rank,

    exposure_treatment_status,
    exposure_treatment_path,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_stage5_rows,

    COUNT(*) FILTER (
        WHERE approved_payment_to_income_ratio_preliminary IS NULL
    ) AS null_preliminary_approved_pti_rows,

    COUNT(*) FILTER (
        WHERE approved_payment_to_income_ratio_preliminary = 0
    ) AS zero_preliminary_approved_pti_rows,

    COUNT(*) FILTER (
        WHERE approved_payment_to_income_ratio_preliminary > 0
    ) AS positive_preliminary_approved_pti_rows,

    AVG(requested_payment_to_income_ratio)
        AS avg_requested_payment_to_income_ratio,

    AVG(approved_payment_to_income_ratio_preliminary)
        AS avg_approved_payment_to_income_ratio_preliminary,

    AVG(requested_payment_to_income_ratio - approved_payment_to_income_ratio_preliminary) FILTER (
        WHERE approved_payment_to_income_ratio_preliminary IS NOT NULL
    ) AS avg_preliminary_pti_reduction,

    AVG(requested_monthly_payment_proxy)
        AS avg_requested_monthly_payment_proxy,

    AVG(approved_monthly_payment_proxy_preliminary)
        AS avg_approved_monthly_payment_proxy_preliminary

FROM tmp_m2_stage_5_exposure_treatment

GROUP BY
    exposure_treatment_status,
    exposure_treatment_path

ORDER BY
    exposure_treatment_status_rank,
    exposure_treatment_status,
    exposure_treatment_path;
```

---

## Replace 8.4.12 with this

```sql
/*-----------------------------------------------------------------------------------------------
8.4.12 Requested Expected Loss versus preliminary approved Expected Loss by exposure_treatment_status.

Purpose:
    Compare requested-exposure Expected Loss to preliminary approved-exposure Expected Loss by
    Section 8 exposure-treatment status.

Interpretation:
    APPROVED_AS_REQUESTED_PRELIMINARY:
        Preliminary approved Expected Loss should equal requested Expected Loss.

    COUNTEROFFER_FEASIBLE_PRELIMINARY:
        Preliminary approved Expected Loss should generally be lower than requested Expected Loss
        because exposure is reduced while estimated_pd and estimated_lgd remain unchanged.

    COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY:
        Preliminary approved Expected Loss remains NULL because no viable reduced-exposure offer was
        produced.

    UNRESOLVED_MANUAL_REVIEW:
        Preliminary approved Expected Loss remains NULL because the row is unresolved.

    NO_OFFER_PRELIMINARY_DECLINE:
        Preliminary approved Expected Loss uses the zero no-offer convention.

Documentation note:
    NULL preliminary approved Expected Loss means unresolved treatment.
    Zero preliminary approved Expected Loss means no-offer treatment.

Boundary:
    This is a Section 8 preliminary economics diagnostic.

    Final approved_expected_loss_amount is created in Section 9.
-----------------------------------------------------------------------------------------------*/

SELECT
    'NULL preliminary approved Expected Loss means unresolved treatment; zero preliminary approved Expected Loss means no-offer convention; Section 9 creates final approved_expected_loss_amount.'::TEXT
        AS interpretation_note,

    CASE exposure_treatment_status
        WHEN 'APPROVED_AS_REQUESTED_PRELIMINARY' THEN 1
        WHEN 'COUNTEROFFER_FEASIBLE_PRELIMINARY' THEN 2
        WHEN 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY' THEN 3
        WHEN 'UNRESOLVED_MANUAL_REVIEW' THEN 4
        WHEN 'NO_OFFER_PRELIMINARY_DECLINE' THEN 5
        ELSE 99
    END AS exposure_treatment_status_rank,

    exposure_treatment_status,
    exposure_treatment_path,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(SUM(COUNT(*)) OVER (), 0),
        6
    ) AS pct_of_stage5_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount_preliminary IS NULL
    ) AS null_preliminary_approved_el_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount_preliminary = 0
    ) AS zero_preliminary_approved_el_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount_preliminary > 0
    ) AS positive_preliminary_approved_el_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount_preliminary)
        AS avg_approved_expected_loss_amount_preliminary,

    AVG(requested_expected_loss_amount - approved_expected_loss_amount_preliminary) FILTER (
        WHERE approved_expected_loss_amount_preliminary IS NOT NULL
    ) AS avg_preliminary_expected_loss_reduction_amount,

    AVG(approved_el_reduction_amount_preliminary)
        AS avg_approved_el_reduction_amount_preliminary,

    AVG(approved_el_reduction_pct_preliminary)
        AS avg_approved_el_reduction_pct_preliminary,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount_preliminary, 0))
        AS total_preliminary_approved_expected_loss_amount

FROM tmp_m2_stage_5_exposure_treatment

GROUP BY
    exposure_treatment_status,
    exposure_treatment_path

ORDER BY
    exposure_treatment_status_rank,
    exposure_treatment_status,
    exposure_treatment_path;
```

---

## Replace 8.4.16 with this

```sql
/*-----------------------------------------------------------------------------------------------
8.4.16 Section 8 readiness summary.

Purpose:
    Provide one compact readiness row before Section 9 final decision resolution.

Expected:
    section_8_exposure_treatment_status =
        SECTION_8_EXPOSURE_TREATMENT_READY_FOR_FINAL_DECISION_RESOLUTION

Interpretation:
    This confirms Section 8 preliminary exposure-treatment outputs are coherent enough for Section 9.

    It does not validate final decision outcomes.
    It does not validate final reason-code assignment.
    It does not validate latest-run materialization.
    It does not validate archive persistence.

Pass / fail-rate note:
    counteroffer_feasibility_pass_rate and counteroffer_feasibility_fail_rate are calculated against
    preliminary COUNTEROFFER rows.

Option C note:
    For non-aggressive strategies, aggressive_override_* counts should normally be zero.

    For AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY, aggressive override rows should be evaluated
    through the same counteroffer feasibility framework as ordinary counteroffer candidates.
-----------------------------------------------------------------------------------------------*/

WITH section_8_readiness AS (
    SELECT
        COUNT(*) AS stage5_row_count,

        COUNT(DISTINCT application_id)
            AS distinct_application_id_count,

        /*******************************************************************************************
        Exposure-treatment status completeness.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE exposure_treatment_status IS NULL
               OR exposure_treatment_path IS NULL
        ) AS exposure_treatment_gap_rows,

        /*******************************************************************************************
        Counteroffer feasibility completeness.

        Only preliminary COUNTEROFFER rows should have feasibility evaluation.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND (
                    counteroffer_feasibility_evaluated_flag IS DISTINCT FROM TRUE
                 OR counteroffer_feasibility_pass_flag IS NULL
                 OR counteroffer_feasibility_constraint_count IS NULL
              )
        ) AS counteroffer_feasibility_gap_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome <> 'COUNTEROFFER'
              AND (
                    counteroffer_feasibility_evaluated_flag IS TRUE
                 OR counteroffer_feasibility_pass_flag IS NOT NULL
                 OR counteroffer_feasibility_failure_reason IS NOT NULL
              )
        ) AS non_counteroffer_feasibility_leakage_rows,

        /*******************************************************************************************
        Preliminary APPROVE convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'APPROVE'
              AND (
                    exposure_treatment_status IS DISTINCT FROM 'APPROVED_AS_REQUESTED_PRELIMINARY'
                 OR approved_amount_preliminary IS DISTINCT FROM requested_amount
                 OR counteroffer_amount_preliminary IS NOT NULL
                 OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
                 OR exposure_reduction_amount_preliminary IS DISTINCT FROM 0::NUMERIC
                 OR exposure_reduction_pct_preliminary IS DISTINCT FROM 0::NUMERIC
                 OR approved_monthly_payment_proxy_preliminary
                        IS DISTINCT FROM requested_monthly_payment_proxy
                 OR approved_payment_to_income_ratio_preliminary
                        IS DISTINCT FROM requested_payment_to_income_ratio
                 OR approved_expected_loss_amount_preliminary
                        IS DISTINCT FROM requested_expected_loss_amount
              )
        ) AS approve_amount_convention_gap_rows,

        /*******************************************************************************************
        Preliminary DECLINE convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'DECLINE'
              AND (
                    exposure_treatment_status IS DISTINCT FROM 'NO_OFFER_PRELIMINARY_DECLINE'
                 OR approved_amount_preliminary IS DISTINCT FROM 0::NUMERIC
                 OR counteroffer_amount_preliminary IS NOT NULL
                 OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
                 OR approved_monthly_payment_proxy_preliminary IS DISTINCT FROM 0::NUMERIC
                 OR approved_payment_to_income_ratio_preliminary IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount_preliminary IS DISTINCT FROM 0::NUMERIC
              )
        ) AS decline_zero_exposure_convention_gap_rows,

        /*******************************************************************************************
        Preliminary MANUAL_REVIEW convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'MANUAL_REVIEW'
              AND (
                    exposure_treatment_status IS DISTINCT FROM 'UNRESOLVED_MANUAL_REVIEW'
                 OR approved_amount_preliminary IS NOT NULL
                 OR counteroffer_amount_preliminary IS NOT NULL
                 OR approved_monthly_payment_proxy_preliminary IS NOT NULL
                 OR approved_payment_to_income_ratio_preliminary IS NOT NULL
                 OR approved_expected_loss_amount_preliminary IS NOT NULL
              )
        ) AS manual_review_unresolved_convention_gap_rows,

        /*******************************************************************************************
        Feasible preliminary COUNTEROFFER convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS TRUE
              AND (
                    exposure_treatment_status IS DISTINCT FROM 'COUNTEROFFER_FEASIBLE_PRELIMINARY'
                 OR approved_amount_preliminary IS NULL
                 OR approved_amount_preliminary <= 0
                 OR approved_amount_preliminary >= requested_amount
                 OR counteroffer_amount_preliminary IS DISTINCT FROM approved_amount_preliminary
                 OR exposure_reduction_flag_preliminary IS DISTINCT FROM TRUE
                 OR exposure_reduction_amount_preliminary IS NULL
                 OR exposure_reduction_amount_preliminary <= 0
                 OR exposure_reduction_pct_preliminary IS NULL
                 OR exposure_reduction_pct_preliminary <= 0
                 OR approved_monthly_payment_proxy_preliminary IS NULL
                 OR approved_payment_to_income_ratio_preliminary IS NULL
                 OR approved_expected_loss_amount_preliminary IS NULL
              )
        ) AS feasible_counteroffer_convention_gap_rows,

        /*******************************************************************************************
        Infeasible preliminary COUNTEROFFER convention.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
              AND (
                    exposure_treatment_status IS DISTINCT FROM 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'
                 OR approved_amount_preliminary IS NOT NULL
                 OR counteroffer_amount_preliminary IS NOT NULL
                 OR approved_monthly_payment_proxy_preliminary IS NOT NULL
                 OR approved_payment_to_income_ratio_preliminary IS NOT NULL
                 OR approved_expected_loss_amount_preliminary IS NOT NULL
                 OR counteroffer_feasibility_failure_reason IS NULL
              )
        ) AS infeasible_counteroffer_convention_gap_rows,

        /*******************************************************************************************
        Route counts.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'APPROVE'
        ) AS preliminary_approve_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
        ) AS preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS TRUE
        ) AS feasible_preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS FALSE
        ) AS infeasible_preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'MANUAL_REVIEW'
        ) AS preliminary_manual_review_rows,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'DECLINE'
        ) AS preliminary_decline_rows,

        /*******************************************************************************************
        Option C aggressive override feasibility checks.
        *******************************************************************************************/
        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS aggressive_override_candidate_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND preliminary_decision_outcome = 'COUNTEROFFER'
        ) AS aggressive_override_preliminary_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND counteroffer_feasibility_evaluated_flag IS TRUE
        ) AS aggressive_override_feasibility_evaluated_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND counteroffer_feasibility_pass_flag IS TRUE
        ) AS aggressive_override_feasible_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND counteroffer_feasibility_pass_flag IS FALSE
        ) AS aggressive_override_failed_counteroffer_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
              AND (
                    preliminary_decision_outcome IS DISTINCT FROM 'COUNTEROFFER'
                 OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM TRUE
                 OR counteroffer_feasibility_pass_flag IS NULL
              )
        ) AS aggressive_override_feasibility_gap_rows

    FROM tmp_m2_stage_5_exposure_treatment
)

SELECT
    'Section 8 readiness validates preliminary exposure-treatment conventions only; final decision, final approved fields, reason codes, latest-run output, and archive persistence occur later.'::TEXT
        AS interpretation_note,

    stage5_row_count,
    distinct_application_id_count,

    exposure_treatment_gap_rows,
    counteroffer_feasibility_gap_rows,
    non_counteroffer_feasibility_leakage_rows,

    approve_amount_convention_gap_rows,
    decline_zero_exposure_convention_gap_rows,
    manual_review_unresolved_convention_gap_rows,
    feasible_counteroffer_convention_gap_rows,
    infeasible_counteroffer_convention_gap_rows,

    preliminary_approve_rows,
    preliminary_counteroffer_rows,
    feasible_preliminary_counteroffer_rows,
    infeasible_preliminary_counteroffer_rows,

    ROUND(
        feasible_preliminary_counteroffer_rows::NUMERIC
        / NULLIF(preliminary_counteroffer_rows, 0),
        6
    ) AS counteroffer_feasibility_pass_rate,

    ROUND(
        infeasible_preliminary_counteroffer_rows::NUMERIC
        / NULLIF(preliminary_counteroffer_rows, 0),
        6
    ) AS counteroffer_feasibility_fail_rate,

    preliminary_manual_review_rows,
    preliminary_decline_rows,

    aggressive_override_candidate_rows,
    aggressive_override_preliminary_counteroffer_rows,
    aggressive_override_feasibility_evaluated_rows,
    aggressive_override_feasible_counteroffer_rows,
    aggressive_override_failed_counteroffer_rows,

    ROUND(
        aggressive_override_feasible_counteroffer_rows::NUMERIC
        / NULLIF(aggressive_override_preliminary_counteroffer_rows, 0),
        6
    ) AS aggressive_override_feasibility_pass_rate,

    ROUND(
        aggressive_override_failed_counteroffer_rows::NUMERIC
        / NULLIF(aggressive_override_preliminary_counteroffer_rows, 0),
        6
    ) AS aggressive_override_feasibility_fail_rate,

    aggressive_override_feasibility_gap_rows,

    CASE
        WHEN stage5_row_count > 0
         AND stage5_row_count = distinct_application_id_count
         AND exposure_treatment_gap_rows = 0
         AND counteroffer_feasibility_gap_rows = 0
         AND non_counteroffer_feasibility_leakage_rows = 0
         AND approve_amount_convention_gap_rows = 0
         AND decline_zero_exposure_convention_gap_rows = 0
         AND manual_review_unresolved_convention_gap_rows = 0
         AND feasible_counteroffer_convention_gap_rows = 0
         AND infeasible_counteroffer_convention_gap_rows = 0
         AND aggressive_override_feasibility_gap_rows = 0
            THEN 'SECTION_8_EXPOSURE_TREATMENT_READY_FOR_FINAL_DECISION_RESOLUTION'

        ELSE 'REVIEW_SECTION_8_EXPOSURE_TREATMENT_BEFORE_FINAL_DECISION_RESOLUTION'
    END AS section_8_exposure_treatment_status

FROM section_8_readiness;
```

---

## Replace 8.4.17 with this

```sql
/*-----------------------------------------------------------------------------------------------
8.4.17 Option C aggressive counteroffer override feasibility diagnostic.

Purpose:
    Review feasibility behavior for rows that entered counteroffer feasibility through the aggressive
    requested-structure override path.

Why this diagnostic returns a row even when no aggressive override rows exist:
    For BASELINE_STRATEGY and non-aggressive strategies, zero aggressive override rows is expected.

    A one-row NOT_APPLICABLE diagnostic is easier to preserve in CSV exports than an empty result set.

Interpretation:
    AGGRESSIVE_OVERRIDE_FEASIBILITY_BREAKDOWN:
        Aggressive override rows exist and are summarized by product, score, risk, requested PTI,
        preliminary route, exposure-treatment status, and feasibility outcome.

    OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS:
        The current strategy did not produce aggressive override rows.

    AGGRESSIVE_OVERRIDE_NO_ROWS_REVIEW_STRATEGY_CONTEXT:
        The current strategy is marked aggressive expansion but no aggressive override rows appeared.
        This may be acceptable for some populations, but should be reviewed.

Boundary:
    This is a Section 8 preliminary feasibility diagnostic.

    It does not create final COUNTEROFFER outcomes.
    It does not assign reason codes.
    It does not modify archive or evidence rows.
-----------------------------------------------------------------------------------------------*/

WITH strategy_context AS (
    SELECT
        MAX(counteroffer_strategy_variant)
            AS counteroffer_strategy_variant,

        COALESCE(
            BOOL_OR(aggressive_counteroffer_expansion_enabled),
            FALSE
        ) AS aggressive_counteroffer_expansion_enabled,

        COUNT(*) AS stage5_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS aggressive_override_rows

    FROM tmp_m2_stage_5_exposure_treatment
),

aggressive_override_breakdown AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,

        preliminary_decision_outcome,
        exposure_treatment_status,
        exposure_treatment_path,

        counteroffer_feasibility_evaluated_flag,
        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason,

        COUNT(*) AS row_count,

        AVG(counteroffer_feasibility_constraint_count)
            AS avg_counteroffer_feasibility_constraint_count,

        AVG(requested_amount)
            AS avg_requested_amount,

        AVG(approved_amount_preliminary)
            AS avg_approved_amount_preliminary,

        AVG(exposure_reduction_pct_preliminary)
            AS avg_exposure_reduction_pct_preliminary,

        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio_preliminary)
            AS avg_approved_payment_to_income_ratio_preliminary,

        AVG(requested_expected_loss_amount)
            AS avg_requested_expected_loss_amount,

        AVG(approved_expected_loss_amount_preliminary)
            AS avg_approved_expected_loss_amount_preliminary

    FROM tmp_m2_stage_5_exposure_treatment

    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE

    GROUP BY
        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,
        preliminary_decision_outcome,
        exposure_treatment_status,
        exposure_treatment_path,
        counteroffer_feasibility_evaluated_flag,
        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason
)

SELECT
    'Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY; zero rows are expected for baseline and non-aggressive strategies.'::TEXT
        AS interpretation_note,

    'AGGRESSIVE_OVERRIDE_FEASIBILITY_BREAKDOWN'::TEXT
        AS option_c_aggressive_override_diagnostic_status,

    sc.counteroffer_strategy_variant,
    sc.aggressive_counteroffer_expansion_enabled,

    b.product_type_policy_key,
    b.score_band_policy_key,
    b.strategy_risk_tier,
    b.requested_pti_bucket,

    b.preliminary_decision_outcome,
    b.exposure_treatment_status,
    b.exposure_treatment_path,

    b.counteroffer_feasibility_evaluated_flag,
    b.counteroffer_feasibility_pass_flag,
    b.counteroffer_feasibility_failure_reason,

    b.row_count,

    ROUND(
        b.row_count::NUMERIC
        / NULLIF(sc.aggressive_override_rows, 0),
        6
    ) AS pct_of_aggressive_override_rows,

    b.avg_counteroffer_feasibility_constraint_count,
    b.avg_requested_amount,
    b.avg_approved_amount_preliminary,
    b.avg_exposure_reduction_pct_preliminary,

    b.avg_requested_payment_to_income_ratio,
    b.avg_approved_payment_to_income_ratio_preliminary,

    b.avg_requested_expected_loss_amount,
    b.avg_approved_expected_loss_amount_preliminary

FROM aggressive_override_breakdown b

CROSS JOIN strategy_context sc

UNION ALL

SELECT
    'Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY; zero rows are expected for baseline and non-aggressive strategies.'::TEXT
        AS interpretation_note,

    CASE
        WHEN sc.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
          OR sc.aggressive_counteroffer_expansion_enabled IS TRUE
            THEN 'AGGRESSIVE_OVERRIDE_NO_ROWS_REVIEW_STRATEGY_CONTEXT'
        ELSE 'OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS'
    END AS option_c_aggressive_override_diagnostic_status,

    sc.counteroffer_strategy_variant,
    sc.aggressive_counteroffer_expansion_enabled,

    NULL::TEXT AS product_type_policy_key,
    NULL::TEXT AS score_band_policy_key,
    NULL::TEXT AS strategy_risk_tier,
    NULL::TEXT AS requested_pti_bucket,

    NULL::TEXT AS preliminary_decision_outcome,
    NULL::TEXT AS exposure_treatment_status,
    NULL::TEXT AS exposure_treatment_path,

    NULL::BOOLEAN AS counteroffer_feasibility_evaluated_flag,
    NULL::BOOLEAN AS counteroffer_feasibility_pass_flag,
    NULL::TEXT AS counteroffer_feasibility_failure_reason,

    0::BIGINT AS row_count,

    NULL::NUMERIC AS pct_of_aggressive_override_rows,

    NULL::NUMERIC AS avg_counteroffer_feasibility_constraint_count,
    NULL::NUMERIC AS avg_requested_amount,
    NULL::NUMERIC AS avg_approved_amount_preliminary,
    NULL::NUMERIC AS avg_exposure_reduction_pct_preliminary,

    NULL::NUMERIC AS avg_requested_payment_to_income_ratio,
    NULL::NUMERIC AS avg_approved_payment_to_income_ratio_preliminary,

    NULL::NUMERIC AS avg_requested_expected_loss_amount,
    NULL::NUMERIC AS avg_approved_expected_loss_amount_preliminary

FROM strategy_context sc

WHERE sc.aggressive_override_rows = 0

ORDER BY
    option_c_aggressive_override_diagnostic_status,
    product_type_policy_key NULLS FIRST,
    score_band_policy_key NULLS FIRST,
    strategy_risk_tier NULLS FIRST,
    requested_pti_bucket NULLS FIRST,
    preliminary_decision_outcome NULLS FIRST,
    exposure_treatment_status NULLS FIRST,
    counteroffer_feasibility_pass_flag NULLS FIRST,
    counteroffer_feasibility_failure_reason NULLS FIRST;
```

These changes are QA/export refinements only. They should not change Section 8 staging, Section 9 final decision resolution, latest-run output, archive persistence, validation evidence, or campaign evidence capture.
<!-- END_MESSAGE C034-M01585 -->


---

<a id="c034-m01587"></a>

### C034-M01587

**Andrew** · 2026-05-17T14:03:31.154000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01587 -->
please re-review 8.4.4, 8.4.10-8.4.12, and 8.4.16-8.4.17 QA
<!-- END_MESSAGE C034-M01587 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_8.4.11_QA_requested_pti_versus_preliminary_approved_pti_by_exposure_treatment_status(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_8.4.12_QA_requested_expected_loss_versus_preliminary_approved_expected_loss_by_exposure_treatment_status(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_8.4.16_QA_section_8_readiness_summary(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_8.4.17_QA_option_c_aggressive_counteroffer_override_feasibility_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_8.4.4_QA_count_by_counteroffer_feasibility_pass_flag(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_8.4.10_QA_requested_amount_versus_preliminary_approved_amount_by_exposure_treatment_status(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01591"></a>

### C034-M01591

**ChatGPT** · 2026-05-17T14:06:58.278882-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01591 -->
## Re-review verdict: Section 8 QA refinements

```text
8.4.4:  PASS
8.4.10: PASS
8.4.11: PASS
8.4.12: PASS
8.4.16: PASS
8.4.17: PASS

Refinement status: accepted
Blockers: none
Required further changes: none
Optional refinements: none recommended
```

The refinements worked. The Section 8 QA exports now make the preliminary exposure-treatment layer much easier to preserve and interpret, especially the distinction between:

```text
NULL = unresolved treatment
0 = no-offer convention
positive value = preliminary positive offer exposure
```

This is exactly the right QA framing for Section 8, because final decision resolution occurs later in Section 9.

---

## 8.4.4 — Counteroffer feasibility pass / fail rate

**Status: PASS**

The updated output is clean and much more useful than the prior count-only version.

Key results:

```text
preliminary counteroffer rows = 21,286

counteroffer_feasibility_pass_flag = TRUE
    row_count = 19,067
    pct_of_preliminary_counteroffer_rows = 0.895753
    counteroffer_feasibility_pass_rate = 0.895753
    avg_constraint_count = 0

counteroffer_feasibility_pass_flag = FALSE
    row_count = 2,219
    pct_of_preliminary_counteroffer_rows = 0.104247
    counteroffer_feasibility_fail_rate = 0.104247
    avg_constraint_count = 1.932853
```

Interpretation is strong:

```text
89.58% of preliminary COUNTEROFFER rows pass feasibility.
10.42% fail feasibility.
Passed rows have zero feasibility constraints.
Failed rows average nearly two binding constraints.
```

The note correctly explains that the rates are calculated only within the preliminary counteroffer population, not the full 50,000-row population.

No further change recommended.

---

## 8.4.10 — Requested amount vs preliminary approved amount

**Status: PASS**

The new `interpretation_note`, rank field, and NULL/zero/positive counts make the export self-explanatory.

Key convention checks:

```text
APPROVED_AS_REQUESTED_PRELIMINARY
    row_count = 10,695
    null approved amount rows = 0
    zero approved amount rows = 0
    positive approved amount rows = 10,695
    avg requested amount = avg approved amount
    avg reduction = 0

COUNTEROFFER_FEASIBLE_PRELIMINARY
    row_count = 19,067
    positive approved amount rows = 19,067
    avg requested amount = 176,816.14
    avg approved amount = 136,791.79
    avg reduction = 40,024.36
    avg reduction pct = 19.786%

COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
    row_count = 2,219
    null approved amount rows = 2,219

UNRESOLVED_MANUAL_REVIEW
    row_count = 5,316
    null approved amount rows = 5,316

NO_OFFER_PRELIMINARY_DECLINE
    row_count = 12,703
    zero approved amount rows = 12,703
```

This now clearly distinguishes failed counteroffer / manual review unresolved treatment from decline zero-exposure convention.

No further change recommended.

---

## 8.4.11 — Requested PTI vs preliminary approved PTI

**Status: PASS**

The updated output correctly separates unresolved PTI from zero no-offer PTI.

Key convention checks:

```text
APPROVED_AS_REQUESTED_PRELIMINARY
    row_count = 10,695
    positive approved PTI rows = 10,695
    avg requested PTI = avg approved PTI = 0.086445
    avg PTI reduction = 0

COUNTEROFFER_FEASIBLE_PRELIMINARY
    row_count = 19,067
    positive approved PTI rows = 19,067
    avg requested PTI = 0.185296
    avg approved PTI = 0.143459
    avg PTI reduction = 0.041837

COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
    row_count = 2,219
    null approved PTI rows = 2,219

UNRESOLVED_MANUAL_REVIEW
    row_count = 5,316
    null approved PTI rows = 5,316

NO_OFFER_PRELIMINARY_DECLINE
    row_count = 12,703
    zero approved PTI rows = 12,703
```

The counteroffer PTI reduction is directionally strong and ties cleanly to the exposure reduction.

No further change recommended.

---

## 8.4.12 — Requested Expected Loss vs preliminary approved Expected Loss

**Status: PASS**

The refined output now clearly documents the Expected Loss convention by exposure-treatment status.

Key convention checks:

```text
APPROVED_AS_REQUESTED_PRELIMINARY
    row_count = 10,695
    positive approved EL rows = 10,695
    avg requested EL = avg approved EL = 773.06
    avg EL reduction = 0

COUNTEROFFER_FEASIBLE_PRELIMINARY
    row_count = 19,067
    positive approved EL rows = 19,067
    avg requested EL = 3,474.72
    avg approved EL = 2,637.22
    avg EL reduction = 837.50
    avg EL reduction pct = 19.786%

COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
    row_count = 2,219
    null approved EL rows = 2,219

UNRESOLVED_MANUAL_REVIEW
    row_count = 5,316
    null approved EL rows = 5,316

NO_OFFER_PRELIMINARY_DECLINE
    row_count = 12,703
    zero approved EL rows = 12,703
```

The counteroffer Expected Loss reduction percentage matches the exposure reduction percentage, which is expected because `estimated_pd` and `estimated_lgd` remain unchanged and only approved exposure changes.

No further change recommended.

---

## 8.4.16 — Section 8 readiness summary

**Status: PASS**

The updated readiness summary is excellent.

Core structural checks:

```text
stage5_row_count = 50,000
distinct_application_id_count = 50,000

exposure_treatment_gap_rows = 0
counteroffer_feasibility_gap_rows = 0
non_counteroffer_feasibility_leakage_rows = 0
```

Convention checks:

```text
approve_amount_convention_gap_rows = 0
decline_zero_exposure_convention_gap_rows = 0
manual_review_unresolved_convention_gap_rows = 0
feasible_counteroffer_convention_gap_rows = 0
infeasible_counteroffer_convention_gap_rows = 0
```

Route counts:

```text
preliminary_approve_rows = 10,695
preliminary_counteroffer_rows = 21,286
feasible_preliminary_counteroffer_rows = 19,067
infeasible_preliminary_counteroffer_rows = 2,219
preliminary_manual_review_rows = 5,316
preliminary_decline_rows = 12,703
```

Rates:

```text
counteroffer_feasibility_pass_rate = 0.895753
counteroffer_feasibility_fail_rate = 0.104247
```

Option C baseline posture:

```text
aggressive_override_candidate_rows = 0
aggressive_override_preliminary_counteroffer_rows = 0
aggressive_override_feasibility_evaluated_rows = 0
aggressive_override_feasible_counteroffer_rows = 0
aggressive_override_failed_counteroffer_rows = 0
aggressive_override_feasibility_gap_rows = 0
```

Final readiness status:

```text
SECTION_8_EXPOSURE_TREATMENT_READY_FOR_FINAL_DECISION_RESOLUTION
```

The `NULL` aggressive override pass/fail rates are correct for M2-01 because there are zero aggressive override rows.

No further change recommended.

---

## 8.4.17 — Option C aggressive override feasibility diagnostic

**Status: PASS**

This refinement solved the empty-export problem. Instead of returning no rows for M2-01, the query now returns one explanatory row:

```text
option_c_aggressive_override_diagnostic_status =
OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS

counteroffer_strategy_variant =
NOT_COUNTEROFFER_SPLIT_STRATEGY

aggressive_counteroffer_expansion_enabled =
false

row_count = 0
```

That is the correct baseline result.

The hardcoded note is also clear:

```text
Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY;
zero rows are expected for baseline and non-aggressive strategies.
```

This is much better for CSV preservation because a reviewer can distinguish:

```text
query returned no rows because export failed
```

from:

```text
query returned a deliberate NOT_APPLICABLE row because M2-01 has no aggressive override population
```

No further change recommended.

---

# Final signoff on Section 8 QA refinements

```text
M2-01 Section 8 QA refinements: ACCEPTED

No blockers.
No logic defects.
No convention issues.
No row-count issues.
No Option C leakage.
No additional Section 8 QA refinements recommended.
```

The current Section 8 QA package is now strong for preservation. It clearly documents preliminary exposure treatment, counteroffer feasibility, unresolved treatment, no-offer convention, and the M2-01 non-aggressive Option C posture.
<!-- END_MESSAGE C034-M01591 -->


---

<a id="c034-m01592"></a>

### C034-M01592

**Andrew** · 2026-05-17T14:20:09.206000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01592 -->
review section 9 QA in two batches (due to limit on attachments).  begin with section 9.4.1 thru 9.4.12 QA:
<!-- END_MESSAGE C034-M01592 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.7_QA_product_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.8_QA_score_band_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.9_QA_product_x_score_segment_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.10_QA_synthetic_risk_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.11_QA_requested_pti_bucket_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.12_QA_dti_bucket_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.1_QA_count_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.2_QA_count_by_decision_path.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.3_QA_count_by_decision_resolution_source.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.4_QA_count_by_simulated_offer_exposure_flag.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.5_QA_preliminary_decision_outcome_x_final_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.6_QA_failed_counteroffer_final_resolution_summary.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01597"></a>

### C034-M01597

**ChatGPT** · 2026-05-17T14:24:57.053327-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01597 -->
## M2-01 Section 9 QA review — batch 1, 9.4.1 through 9.4.12

```text
Section 9 QA batch 1 status: PASS
Selected run: M2-01
Strategy: BASELINE_STRATEGY
Stage 6 rows implied: 50,000
Final decision resolution: coherent
Failed counteroffer resolution: coherent
Simulated offer exposure convention: coherent
Approved amount / approved PTI / approved EL conventions: coherent
Blockers in 9.4.1–9.4.12: none
```

Section 9 is behaving as designed: it resolves preliminary routing plus Section 8 counteroffer feasibility into final simulated outcomes, final flags, simulated offer exposure, approved exposure, approved PTI, and approved Expected Loss. It still does **not** assign reason codes; that remains Section 10. fileciteturn396file34

---

## 1. Final decision outcome distribution — 9.4.1

The final outcome mix is clean:

```text
APPROVE          10,695   21.39%
COUNTEROFFER     19,067   38.13%
MANUAL_REVIEW     7,535   15.07%
DECLINE          12,703   25.41%
```

This reconciles to exactly:

```text
50,000 rows
```

The movement from Section 7 / Section 8 is also coherent:

```text
preliminary APPROVE       → final APPROVE
feasible COUNTEROFFER     → final COUNTEROFFER
failed COUNTEROFFER       → final MANUAL_REVIEW under M2-01 default
preliminary MANUAL_REVIEW → final MANUAL_REVIEW
preliminary DECLINE       → final DECLINE
```

**Status: PASS**

---

## 2. Decision path distribution — 9.4.2

Decision paths are coherent:

```text
APPROVE_AS_REQUESTED                    10,695
COUNTEROFFER_FEASIBLE                   19,067
COUNTEROFFER_NOT_FEASIBLE_REVIEW         2,219
MANUAL_REVIEW_CANDIDATE                  5,316
HARD_POLICY_STOP                         5,889
SEVERE_SYNTHETIC_RISK                    6,369
SEVERE_DTI_CAPACITY                        445
```

The paths reconcile to final decisions:

```text
APPROVE:
    APPROVE_AS_REQUESTED = 10,695

COUNTEROFFER:
    COUNTEROFFER_FEASIBLE = 19,067

MANUAL_REVIEW:
    COUNTEROFFER_NOT_FEASIBLE_REVIEW + MANUAL_REVIEW_CANDIDATE
    = 2,219 + 5,316
    = 7,535

DECLINE:
    HARD_POLICY_STOP + SEVERE_SYNTHETIC_RISK + SEVERE_DTI_CAPACITY
    = 5,889 + 6,369 + 445
    = 12,703
```

**Status: PASS**

---

## 3. Decision resolution source — 9.4.3

Resolution sources are clean and explain the Section 9 transition:

```text
PRELIMINARY_APPROVE_ROUTE                    10,695
COUNTEROFFER_FEASIBILITY_PASSED              19,067
COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW     2,219
PRELIMINARY_MANUAL_REVIEW_ROUTE               5,316
PRELIMINARY_DECLINE_ROUTE                    12,703
```

This confirms that the 2,219 infeasible counteroffers were resolved according to the governed `failed_counteroffer_resolution = MANUAL_REVIEW` posture.

**Status: PASS**

---

## 4. Simulated offer exposure flag — 9.4.4

The simulated offer exposure convention is exact:

```text
simulated_offer_exposure_flag = TRUE     29,762
simulated_offer_exposure_flag = FALSE    20,238
```

Reconciliation:

```text
APPROVE + COUNTEROFFER
= 10,695 + 19,067
= 29,762

MANUAL_REVIEW + DECLINE
= 7,535 + 12,703
= 20,238
```

This is precisely the expected convention:

```text
APPROVE and COUNTEROFFER = simulated positive offer exposure
MANUAL_REVIEW and DECLINE = no simulated positive offer exposure
```

**Status: PASS**

---

## 5. Preliminary outcome × final outcome — 9.4.5

This is one of the strongest Section 9 checks.

```text
Preliminary APPROVE:
    100.00% → final APPROVE

Preliminary COUNTEROFFER:
    89.58% → final COUNTEROFFER
    10.42% → final MANUAL_REVIEW

Preliminary MANUAL_REVIEW:
    100.00% → final MANUAL_REVIEW

Preliminary DECLINE:
    100.00% → final DECLINE
```

Interpretation:

```text
Only preliminary COUNTEROFFER rows changed outcome after Section 8 feasibility testing.
That is exactly expected.
```

No preliminary APPROVE, MANUAL_REVIEW, or DECLINE leakage is visible.

**Status: PASS**

---

## 6. Failed counteroffer final resolution summary — 9.4.6

The failed counteroffer summary is coherent.

Failed counteroffers:

```text
COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT    2,070
COUNTEROFFER_EXCEEDS_MAX_REDUCTION                 60
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT            89
total failed counteroffers                       2,219
```

All failed counteroffers resolve to:

```text
decision_outcome = MANUAL_REVIEW
decision_path = COUNTEROFFER_NOT_FEASIBLE_REVIEW
decision_resolution_source = COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW
```

The feasible counteroffer context row is also correct:

```text
counteroffer_feasibility_pass_flag = TRUE
decision_outcome = COUNTEROFFER
row_count = 19,067
```

**Status: PASS**

---

## 7. Product × decision outcome — 9.4.7

Product-level final outcomes are coherent.

Approximate final outcome rates:

```text
AUTO_LOAN
    APPROVE 26.87% | COUNTEROFFER 31.84% | MANUAL_REVIEW 16.41% | DECLINE 24.88%

HELOC
    APPROVE 21.73% | COUNTEROFFER 37.73% | MANUAL_REVIEW 13.02% | DECLINE 27.53%

MORTGAGE
    APPROVE 19.90% | COUNTEROFFER 38.82% | MANUAL_REVIEW 14.63% | DECLINE 26.65%

REVOLVING_LINE
    APPROVE 19.98% | COUNTEROFFER 42.00% | MANUAL_REVIEW 14.53% | DECLINE 23.48%

UNSECURED_PERSONAL_LOAN
    APPROVE 19.26% | COUNTEROFFER 38.95% | MANUAL_REVIEW 16.42% | DECLINE 25.38%
```

The exposure / affordability / Expected Loss conventions also read correctly by product:

```text
APPROVE:
    avg approved amount = avg requested amount
    avg approved PTI = avg requested PTI
    avg approved EL = avg requested EL

COUNTEROFFER:
    avg approved amount < avg requested amount
    avg approved PTI < avg requested PTI
    avg approved EL < avg requested EL

MANUAL_REVIEW:
    approved fields are NULL / unresolved

DECLINE:
    approved amount = 0
    approved PTI = 0
    approved EL = 0
```

**Status: PASS**

---

## 8. Score band × decision outcome — 9.4.8

Score-band behavior is strong and directionally intuitive.

Approximate final outcome rates:

```text
SUPER_PRIME
    APPROVE 52.28% | COUNTEROFFER 40.19% | MANUAL_REVIEW  6.96% | DECLINE  0.57%

PRIME
    APPROVE 39.10% | COUNTEROFFER 40.44% | MANUAL_REVIEW 17.70% | DECLINE  2.76%

NEAR_PRIME
    APPROVE  4.38% | COUNTEROFFER 73.04% | MANUAL_REVIEW 12.60% | DECLINE  9.98%

SUBPRIME
    APPROVE  0.00% | COUNTEROFFER 11.01% | MANUAL_REVIEW 32.55% | DECLINE 56.44%

DEEP_SUBPRIME
    APPROVE  0.00% | COUNTEROFFER  0.02% | MANUAL_REVIEW  0.26% | DECLINE 99.72%
```

This is exactly the desired routing gradient:

```text
stronger score bands retain positive-offer exposure;
near-prime heavily uses counteroffer;
subprime shifts toward manual review and decline;
deep subprime is almost entirely decline.
```

**Status: PASS**

---

## 9. Product × score segment × decision outcome — 9.4.9

This output is coherent and reconciles to final totals:

```text
APPROVE          10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
DECLINE          12,703
total            50,000
```

The segmentation coverage is also useful:

```text
25 product × score segments are present.
All 25 segments have DECLINE and MANUAL_REVIEW rows.
21 segments have COUNTEROFFER rows.
15 segments have APPROVE rows.
```

That pattern is expected. Stronger-score segments support approvals, while weaker-score segments may have no approvals and, in some cases, no feasible counteroffers.

One CSV-readability note: this output uses fields such as:

```text
avg_approved_amount_all_rows
avg_approved_expected_loss_all_rows
```

Those appear to apply a zero-fill convention for no-offer/unresolved rows. That is not a logic defect, but it differs from 9.4.7, where manual-review approved fields display as NULL. If we later refine Section 9 QA exports, this is one candidate for an interpretation note.

**Status: PASS, with minor export-interpretation note**

---

## 10. Synthetic risk tier × decision outcome — 9.4.10

Synthetic-risk behavior is strong.

```text
LOW_SYNTHETIC_RISK
    APPROVE  8,941
    COUNTEROFFER 6,026
    MANUAL_REVIEW 2,099
    DECLINE 56

MODERATE_SYNTHETIC_RISK
    APPROVE 1,754
    COUNTEROFFER 3,306
    MANUAL_REVIEW 1,495
    DECLINE 258

ELEVATED_SYNTHETIC_RISK
    APPROVE 0
    COUNTEROFFER 7,979
    MANUAL_REVIEW 290
    DECLINE 414

HIGH_SYNTHETIC_RISK
    APPROVE 0
    COUNTEROFFER 1,756
    MANUAL_REVIEW 3,651
    DECLINE 1,005

SEVERE_SYNTHETIC_RISK
    DECLINE 10,970
```

Key interpretation:

```text
Severe synthetic risk resolves entirely to DECLINE.
Elevated/high risk can still receive counteroffer or manual review depending on other route/feasibility conditions.
Low/moderate risk can still decline due to other rule families such as hard policy stops.
```

This preserves the intended non-mechanical, multi-trigger design.

**Status: PASS**

---

## 11. Requested PTI bucket × decision outcome — 9.4.11

Requested PTI behavior is coherent after final counteroffer feasibility resolution.

```text
LOW_REQUESTED_PTI
    APPROVE 8,060 | COUNTEROFFER 5,482 | MANUAL_REVIEW 3,786 | DECLINE 2,615

MODERATE_REQUESTED_PTI
    APPROVE 2,635 | COUNTEROFFER 7,439 | MANUAL_REVIEW 2,562 | DECLINE 5,461

ELEVATED_REQUESTED_PTI
    APPROVE 0 | COUNTEROFFER 5,125 | MANUAL_REVIEW 713 | DECLINE 2,872

HIGH_REQUESTED_PTI
    APPROVE 0 | COUNTEROFFER 1,020 | MANUAL_REVIEW 358 | DECLINE 948

SEVERE_REQUESTED_PTI
    APPROVE 0 | COUNTEROFFER 1 | MANUAL_REVIEW 116 | DECLINE 807
```

Interpretation:

```text
Higher requested PTI reduces approval availability.
Counteroffer remains available for some elevated/high PTI rows.
Severe PTI mostly resolves to DECLINE, with failed counteroffer rows resolving to MANUAL_REVIEW where applicable.
```

The approved PTI conventions are clean:

```text
APPROVE: approved PTI = requested PTI
COUNTEROFFER: approved PTI < requested PTI
MANUAL_REVIEW: approved PTI = NULL
DECLINE: approved PTI = 0
```

**Status: PASS**

---

## 12. DTI bucket × decision outcome — 9.4.12

DTI behavior is coherent:

```text
LOW_DTI
    APPROVE 1,066 | COUNTEROFFER 888 | MANUAL_REVIEW 108 | DECLINE 22

MODERATE_DTI
    APPROVE 9,629 | COUNTEROFFER 13,182 | MANUAL_REVIEW 3,726 | DECLINE 3,083

ELEVATED_DTI
    APPROVE 0 | COUNTEROFFER 4,997 | MANUAL_REVIEW 3,701 | DECLINE 7,423

SEVERE_DTI
    DECLINE 2,175
```

Key interpretation:

```text
Severe DTI resolves entirely to DECLINE.
Elevated DTI has no approvals, but can still resolve to counteroffer, manual review, or decline.
Low/moderate DTI can still decline due to other trigger families.
```

This aligns with the Section 7 hierarchy and Section 9 final resolution design.

**Status: PASS**

---

# Batch 1 issues / observations

```text
Blockers: none
Logic concerns: none material
Narrative concerns: none material
```

Minor QA-export observation to revisit after batch 2:

```text
9.4.9 uses “all_rows” approved amount / approved EL averages that appear to zero-fill unresolved
manual-review rows and no-offer decline rows. That may be intentional for segment-level aggregate
exposure views, but it should be labeled clearly so reviewers do not confuse zero-filled aggregate
metrics with row-level manual-review conventions.
```

I would wait to decide on Section 9 QA refinements until we review the remaining Section 9 outputs.

---

## Interim Section 9 signoff through 9.4.12

```text
M2-01 Section 9 QA batch 1: ACCEPTED THROUGH 9.4.12

Final outcome distribution is coherent.
Decision paths reconcile to outcomes.
Resolution sources explain the Section 8 → Section 9 transition.
Simulated offer exposure flag reconciles exactly.
Failed counteroffers resolve to MANUAL_REVIEW under M2-01 strategy control.
Product-level final outcomes are coherent.
Score-band final outcomes are directionally strong.
Product × score segment outcomes reconcile.
Synthetic-risk behavior is coherent.
Requested PTI behavior is coherent.
DTI behavior is coherent.
No blocker found.
```
<!-- END_MESSAGE C034-M01597 -->


---

<a id="c034-m01598"></a>

### C034-M01598

**Andrew** · 2026-05-17T14:27:18.213000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01598 -->
review remaining section 9 QA then recommend section 9 QA refinements.
<!-- END_MESSAGE C034-M01598 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.18_QA_average_approved_amount_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.19_QA_average_requested_pti_and_approved_pti_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.20_QA_average_requested_expected_loss_and_approved_expected_loss_by_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.21_QA_section_9_readiness_summary.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.22_QA_option_c_aggressive_counteroffer_override_final_resolution_diagnostic.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.23_QA_option_c_aggressive_counteroffer_override_final_resolution_rollup.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.13_QA_requested_exposure_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.14_QA_requested_expected_loss_tier_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.15_QA_mixed_signal_profile_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.16_QA_borderline_profile_flag_x_decision_outcome.csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.17_QA_average_requested_amount_by_decision_outcome.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01602"></a>

### C034-M01602

**ChatGPT** · 2026-05-17T14:33:58.555511-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01602 -->
## M2-01 Section 9 QA review — batch 2, 9.4.13 through 9.4.23

```text
Section 9 QA batch 2 status: PASS
Section 9 final QA status: ACCEPTED
Selected run: M2-01
Strategy: BASELINE_STRATEGY
Stage 6 rows: 50,000
Distinct application_id count: 50,000
Final decision resolution: coherent
Approved exposure conventions: coherent
Approved PTI conventions: coherent
Approved Expected Loss conventions: coherent
Option C aggressive override posture: correctly inactive
Blockers: none
```

Section 9 is doing what it should: resolving preliminary routing and Section 8 feasibility into final simulated outcomes, final flags, simulated offer-exposure status, approved exposure, approved affordability proxy, and approved Expected Loss. It still correctly leaves reason-code assignment to Section 10. fileciteturn396file34

---

## 1. Requested exposure tier × final decision outcome — 9.4.13

**Status: PASS**

The requested-exposure tier behavior is coherent:

```text
LOW_REQUESTED_EXPOSURE
    APPROVE         6,027
    COUNTEROFFER    4,536
    MANUAL_REVIEW   3,741
    DECLINE         6,278

WITHIN_PRODUCT_APPROVAL_CAP
    APPROVE         4,668
    COUNTEROFFER    5,626
    MANUAL_REVIEW   2,698
    DECLINE         3,798

ABOVE_PRODUCT_APPROVAL_CAP
    APPROVE             0
    COUNTEROFFER    8,905
    MANUAL_REVIEW   1,096
    DECLINE         2,627
```

The most important behavior is clean:

```text
ABOVE_PRODUCT_APPROVAL_CAP has zero approvals.
Above-cap rows primarily resolve to COUNTEROFFER, with some manual review / decline based on feasibility and higher-priority risk controls.
```

This is exactly the intended product-cap / exposure-management behavior.

---

## 2. Requested Expected Loss tier × final decision outcome — 9.4.14

**Status: PASS**

Requested-EL final outcome behavior is coherent:

```text
LOW_REQUESTED_EL
    APPROVE        10,524
    COUNTEROFFER   10,413
    MANUAL_REVIEW   4,216
    DECLINE         1,005

MODERATE_REQUESTED_EL
    APPROVE           171
    COUNTEROFFER    4,685
    MANUAL_REVIEW   1,310
    DECLINE         2,243

ELEVATED_REQUESTED_EL
    APPROVE             0
    COUNTEROFFER    3,969
    MANUAL_REVIEW     509
    DECLINE         3,413

HIGH_REQUESTED_EL
    APPROVE             0
    COUNTEROFFER        0
    MANUAL_REVIEW   1,413
    DECLINE         4,140

SEVERE_REQUESTED_EL
    APPROVE             0
    COUNTEROFFER        0
    MANUAL_REVIEW      87
    DECLINE         1,902
```

This is a strong final-resolution pattern. Low and moderate requested-EL rows retain approvals and counteroffers. High and severe requested-EL rows do not resolve to final counteroffer under M2-01 because any preliminary counteroffer pressure does not survive the feasibility / final-resolution chain.

The final outcome mix is more conservative as requested-EL pressure rises, which is the desired behavior.

---

## 3. Mixed-signal profile × final decision outcome — 9.4.15

**Status: PASS**

Mixed-signal behavior remains nuanced and useful:

```text
NO_MIXED_SIGNAL_PROFILE
    APPROVE        10,695
    COUNTEROFFER   10,957
    MANUAL_REVIEW   5,155
    DECLINE         5,383

LARGE_EXPOSURE_LOW_RISK
    COUNTEROFFER    6,637
    DECLINE            74

WEAK_CREDIT_LOW_PTI
    COUNTEROFFER      821
    MANUAL_REVIEW   2,234
    DECLINE         5,371

MULTIPLE_MIXED_SIGNALS
    COUNTEROFFER      142
    MANUAL_REVIEW     125
    DECLINE         1,478
```

Interpretation:

```text
All final approvals are in the no-mixed-signal population.
Large-exposure / low-risk rows mostly resolve to counteroffer.
Weak-credit / low-PTI rows split across counteroffer, manual review, and decline.
Multiple mixed-signal rows skew toward decline, with some counteroffer/manual review.
```

That is realistic. The mixed-signal profile is not being used as a blunt automatic decision rule; it remains a diagnostic field interacting with the route hierarchy and feasibility layer.

---

## 4. Borderline profile × final decision outcome — 9.4.16

**Status: PASS**

Borderline behavior is strong:

```text
borderline_profile_flag = FALSE
    APPROVE        10,695
    COUNTEROFFER   11,486
    MANUAL_REVIEW   2,031
    DECLINE         5,492

borderline_profile_flag = TRUE
    APPROVE             0
    COUNTEROFFER    7,581
    MANUAL_REVIEW   5,504
    DECLINE         7,211
```

Key interpretation:

```text
All final approvals are non-borderline.
Borderline rows still retain meaningful final counteroffer volume.
Borderline rows are materially more likely to resolve to manual review or decline.
```

That is exactly the right behavior for a borderline diagnostic: it adds pressure and interpretability without automatically becoming a final route by itself.

---

## 5. Average requested amount by final decision outcome — 9.4.17

**Status: PASS**

The requested-amount profile is coherent:

```text
APPROVE
    row_count = 10,695
    avg_requested_amount = 113,984.96

COUNTEROFFER
    row_count = 19,067
    avg_requested_amount = 176,816.14

MANUAL_REVIEW
    row_count = 7,535
    avg_requested_amount = 110,774.98

DECLINE
    row_count = 12,703
    avg_requested_amount = 97,721.17
```

Interpretation:

```text
Final counteroffers carry the highest average requested amount.
Approvals are lower on average than counteroffers.
Manual reviews and declines are not simply high-dollar exposure categories; they are driven by risk, feasibility, and policy pressure.
```

No issue found.

---

## 6. Average approved amount by final decision outcome — 9.4.18

**Status: PASS**

Approved-amount conventions are clean:

```text
APPROVE
    avg_approved_amount = 113,984.96
    total_approved_amount = 1.219B

COUNTEROFFER
    avg_approved_amount = 136,791.79
    total_approved_amount = 2.608B

MANUAL_REVIEW
    avg_approved_amount = NULL
    total_approved_amount = 0

DECLINE
    avg_approved_amount = 0
    total_approved_amount = 0
```

This correctly distinguishes:

```text
MANUAL_REVIEW = unresolved / NULL approved amount
DECLINE = no-offer / zero approved amount
```

The `total_approved_amount = 0` for manual review is fine if the query uses `SUM(COALESCE(approved_amount, 0))`, but the export should label or explain that convention so a reviewer does not confuse unresolved NULLs with true zero-offer outcomes.

---

## 7. Requested PTI and approved PTI by final decision outcome — 9.4.19

**Status: PASS**

PTI conventions are clean:

```text
APPROVE
    avg_requested_pti = 0.086445
    avg_approved_pti = 0.086445
    avg_pti_reduction = 0

COUNTEROFFER
    avg_requested_pti = 0.185296
    avg_approved_pti = 0.143459
    avg_pti_reduction = 0.041837

MANUAL_REVIEW
    avg_requested_pti = 0.139151
    avg_approved_pti = NULL

DECLINE
    avg_requested_pti = 0.216139
    avg_approved_pti = 0
```

Interpretation:

```text
Approvals preserve requested PTI.
Counteroffers reduce approved PTI.
Manual reviews remain unresolved.
Declines use the zero no-offer convention.
```

This is exactly aligned with the Module 2 amount / affordability conventions.

---

## 8. Requested Expected Loss and approved Expected Loss by final decision outcome — 9.4.20

**Status: PASS**

Expected Loss behavior is strong:

```text
APPROVE
    avg_requested_EL = 773.06
    avg_approved_EL = 773.06

COUNTEROFFER
    avg_requested_EL = 3,474.72
    avg_approved_EL = 2,637.22

MANUAL_REVIEW
    avg_requested_EL = 4,226.77
    avg_approved_EL = NULL
    total_approved_EL = 0

DECLINE
    avg_requested_EL = 10,475.04
    avg_approved_EL = 0
```

Interpretation:

```text
Approvals preserve requested-exposure Expected Loss.
Counteroffers reduce approved-exposure Expected Loss.
Manual review remains unresolved.
Decline uses zero approved Expected Loss convention.
```

This is a clean final-economics result.

---

## 9. Section 9 readiness summary — 9.4.21

**Status: PASS**

This is the controlling Section 9 signoff row, and it passes cleanly:

```text
stage6_row_count = 50,000
distinct_application_id_count = 50,000

final_decision_gap_rows = 0
final_flag_reconciliation_gap_rows = 0
simulated_offer_exposure_flag_gap_rows = 0

approve_amount_convention_gap_rows = 0
counteroffer_convention_gap_rows = 0
manual_review_unresolved_convention_gap_rows = 0
decline_zero_exposure_convention_gap_rows = 0

failed_counteroffer_to_review_gap_rows = 0
failed_counteroffer_to_decline_gap_rows = 0

aggressive_override_candidate_rows = 0
aggressive_override_final_resolution_gap_rows = 0

final_approve_rows = 10,695
final_counteroffer_rows = 19,067
final_manual_review_rows = 7,535
final_decline_rows = 12,703
simulated_offer_exposure_rows = 29,762

section_9_final_decision_resolution_status =
    SECTION_9_FINAL_DECISION_RESOLUTION_READY_FOR_REASON_CODE_ASSIGNMENT
```

This is the exact status needed before Section 10.

---

## 10. Option C aggressive override final-resolution diagnostic — 9.4.22

**Status: PASS / correctly empty for M2-01**

The diagnostic returns no rows. That is expected for M2-01 because:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false
aggressive override rows = 0
```

This is not a logic issue. It is an export/readability issue only: empty CSVs can be hard to preserve and interpret later.

---

## 11. Option C aggressive override final-resolution rollup — 9.4.23

**Status: PASS**

The rollup confirms the correct baseline posture:

```text
strategy_name = BASELINE_STRATEGY
counteroffer_strategy_variant = NOT_COUNTEROFFER_SPLIT_STRATEGY
aggressive_counteroffer_expansion_enabled = false

aggressive_override_rows = 0
aggressive_override_feasible_rows = 0
aggressive_override_failed_rows = 0

aggressive_override_final_counteroffer_rows = 0
aggressive_override_final_manual_review_rows = 0
aggressive_override_final_decline_rows = 0
```

All aggressive override rates and averages are NULL because there is no aggressive override population. That is correct.

---

# Final Section 9 QA signoff

```text
M2-01 Section 9 QA: ACCEPTED

No blockers.
No row-count issue.
No application-grain issue.
No final-decision gap.
No final-flag reconciliation issue.
No simulated offer-exposure convention issue.
No approval amount convention issue.
No counteroffer convention issue.
No manual-review unresolved convention issue.
No decline zero-exposure convention issue.
No failed-counteroffer resolution issue.
No Option C aggressive override leakage.
Section 9 is ready for Section 10 reason-code assignment.
```

---

# Recommended Section 9 QA refinements

I would not change Section 9 logic. The final-decision layer is working. The refinements below are QA/export readability improvements only.

## Recommended refinement 1 — add interpretation notes to 9.4.18, 9.4.19, and 9.4.20

These outputs are correct, but they would benefit from the same clarity we added in Section 8:

```text
NULL = unresolved manual-review treatment
0 = no-offer decline convention
positive value = simulated positive offer exposure
```

Recommended target outputs:

```text
9.4.18 average approved amount by decision outcome
9.4.19 average requested PTI and approved PTI by decision outcome
9.4.20 average requested Expected Loss and approved Expected Loss by decision outcome
```

Add a hardcoded `interpretation_note` column and null/zero/positive approved-field counts. This will make the CSVs self-explanatory.

## Recommended refinement 2 — update 9.4.22 to return one NOT_APPLICABLE row when no aggressive override rows exist

Right now 9.4.22 returns an empty result for M2-01. That is logically correct, but poor for preservation.

I recommend changing 9.4.22 so it returns one row like:

```text
option_c_aggressive_override_final_resolution_status =
OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS
```

This should mirror the refinement we made to Section 8.4.17.

## Recommended refinement 3 — add interpretation note to 9.4.9 product × score segment output

9.4.9 is useful, but it uses “all rows” approved amount / approved EL averages that appear to zero-fill no-offer or unresolved rows. That can be valid for segment-level portfolio exposure summaries, but it should be explicit.

Recommended note:

```text
All-row approved exposure metrics use no-offer / unresolved conventions for portfolio-level segment aggregation; positive-offer-only averages should be interpreted separately from all-row averages.
```

If you want a stronger improvement, add:

```text
positive_offer_rows
avg_approved_amount_positive_offer_rows
avg_approved_expected_loss_positive_offer_rows
null_approved_amount_rows
zero_approved_amount_rows
```

That would prevent any confusion between unresolved manual-review rows and true zero-exposure decline rows.

## Optional refinement 4 — add product-relative interpretation notes to 9.4.13 and 9.4.14

This is lower priority, but consistent with the improvements we made in Section 5:

```text
9.4.13 requested exposure tier × decision outcome
9.4.14 requested Expected Loss tier × decision outcome
```

Add a note that requested exposure tier and requested Expected Loss tier are product-policy-relative. This helps explain why aggregate averages can look counterintuitive when product mix differs across tiers.

## My recommendation

Apply these three refinements:

```text
1. 9.4.18–9.4.20: add interpretation_note and null/zero/positive approved-field counts.
2. 9.4.22: return a one-row NOT_APPLICABLE diagnostic instead of an empty export.
3. 9.4.9: add interpretation_note and positive-offer-only approved exposure / EL metrics.
```

Optional but not necessary:

```text
4. Add product-relative notes to 9.4.13 and 9.4.14.
```

After those refinements, Section 9 QA will be highly preservation-friendly and aligned with the elite portfolio documentation standard.
<!-- END_MESSAGE C034-M01602 -->


---

<a id="c034-m01604"></a>

### C034-M01604

**Andrew** · 2026-05-17T14:36:10.290000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01604 -->
perform all recommended and optional section 9 qa refinement.  provide full copy paste for all updated sections.
<!-- END_MESSAGE C034-M01604 -->


---

<a id="c034-m01606"></a>

### C034-M01606

**ChatGPT** · 2026-05-17T14:42:57.149611-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01606 -->
Below are the full copy-paste replacements for the **recommended + optional Section 9 QA refinements**. These are QA/export refinements only; they do not change Section 9 final decision logic. Section 9’s core boundary remains final simulated outcome resolution after preliminary routing and exposure feasibility, while reason-code assignment remains deferred to Section 10. fileciteturn396file34

Replace these existing blocks:

```text
9.4.9
9.4.13
9.4.14
9.4.18
9.4.19
9.4.20
9.4.22
```

with the versions below.

---

## Replace 9.4.9 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.9 Product × score segment × decision_outcome.

Purpose:
    Review final outcome behavior at the product × score segment grain.

Why this refinement exists:
    Product × score segment output is often used later for executive evidence, README narrative,
    validation-summary support, and Module 3 planning.

    Segment-level all-row approved exposure metrics can be useful for portfolio impact, but they
    should be clearly distinguished from positive-offer-only metrics.

Interpretation:
    all_rows_convention_adjusted metrics:
        Use Module 2 final outcome conventions for segment-level portfolio aggregation.

        MANUAL_REVIEW rows are unresolved and have NULL approved fields.
        DECLINE rows use the zero-exposure / zero-Expected-Loss convention.

        COALESCE is used only for all-row portfolio impact metrics.

    positive_offer metrics:
        Include only APPROVE and COUNTEROFFER rows where simulated_offer_exposure_flag = TRUE.

        These are the correct metrics for interpreting approved exposure and approved Expected Loss
        among simulated positive offers.

Boundary:
    This is a Section 9 final-decision QA diagnostic.

    It does not assign reason codes.
    It does not modify latest-run output.
    It does not modify archive rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    'All-row approved exposure metrics use final outcome conventions for portfolio aggregation; positive-offer-only metrics separately isolate APPROVE and COUNTEROFFER exposure behavior.'::TEXT
        AS interpretation_note,

    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY
                    product_type_policy_key,
                    score_band_policy_key,
                    product_score_policy_segment
            ),
            0
        ),
        6
    ) AS pct_of_product_score_segment_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS positive_offer_rows,

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

    AVG(approved_amount)
        AS avg_approved_amount_non_null_rows,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_rows_convention_adjusted,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    SUM(requested_amount)
        AS total_requested_amount,

    SUM(COALESCE(approved_amount, 0))
        AS total_approved_amount_all_rows_convention_adjusted,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_expected_loss_amount_non_null_rows,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_amount_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_expected_loss_amount_positive_offer_rows,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount_all_rows_convention_adjusted,

    AVG(approved_payment_to_income_ratio) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_payment_to_income_ratio_positive_offer_rows,

    AVG(estimated_pd)
        AS avg_synthetic_estimated_pd_proxy,

    AVG(estimated_lgd)
        AS avg_estimated_lgd

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    decision_outcome

ORDER BY
    product_type_policy_key,
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    score_band_policy_key,
    product_score_policy_segment,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;
```

---

## Replace 9.4.13 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.13 Requested exposure tier × decision_outcome.

Purpose:
    Review how product-policy-relative requested exposure tiers resolve into final simulated
    decision outcomes.

Why this diagnostic needs an interpretation note:
    requested_exposure_tier is product-policy-relative.

    A requested amount can be considered above cap for one product while still being well within cap
    for another product.

    Therefore, portfolio-level requested amount averages by tier may look counterintuitive unless
    product context is considered.

Interpretation:
    LOW_REQUESTED_EXPOSURE:
        Requested exposure is low relative to the applicable product policy.

    WITHIN_PRODUCT_APPROVAL_CAP:
        Requested exposure is within the product approval cap.

    ABOVE_PRODUCT_APPROVAL_CAP:
        Requested exposure exceeds the product approval cap and should not resolve to final APPROVE.

Boundary:
    This is a final decision QA diagnostic.

    It does not change exposure tiering.
    It does not change final decisions.
-----------------------------------------------------------------------------------------------*/

SELECT
    'Requested exposure tiers are product-policy-relative; aggregate averages can look counterintuitive because product caps and requested amount distributions differ by product.'::TEXT
        AS interpretation_note,

    CASE requested_exposure_tier
        WHEN 'LOW_REQUESTED_EXPOSURE' THEN 1
        WHEN 'WITHIN_PRODUCT_APPROVAL_CAP' THEN 2
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 3
        ELSE 99
    END AS requested_exposure_tier_rank,

    requested_exposure_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY requested_exposure_tier
            ),
            0
        ),
        6
    ) AS pct_of_requested_exposure_tier_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS positive_offer_rows,

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

    AVG(approved_amount)
        AS avg_approved_amount_non_null_rows,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_rows_convention_adjusted,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_expected_loss_amount_positive_offer_rows,

    COUNT(DISTINCT product_type_policy_key)
        AS distinct_product_type_policy_key_count

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    requested_exposure_tier,
    decision_outcome

ORDER BY
    requested_exposure_tier_rank,
    requested_exposure_tier,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;
```

---

## Replace 9.4.14 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.14 Requested Expected Loss tier × decision_outcome.

Purpose:
    Review how product-policy-relative requested Expected Loss tiers resolve into final simulated
    decision outcomes.

Why this diagnostic needs an interpretation note:
    requested_expected_loss_tier is product-policy-relative.

    Product-specific requested-EL thresholds, product mix, requested amount, estimated-LGD, and
    synthetic estimated-PD proxy can make aggregate tier-level averages appear non-monotonic.

    This is not automatically a defect.

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount is final simulated approved-exposure Expected Loss after Module 2
    final decision resolution.

Boundary:
    This is a final decision QA diagnostic.

    It does not change requested Expected Loss tiering.
    It does not change final decisions.
-----------------------------------------------------------------------------------------------*/

SELECT
    'Requested Expected Loss tiers are product-policy-relative; aggregate tier averages can overlap or appear non-monotonic when product mix, LGD, requested amount, and product-specific thresholds differ by tier.'::TEXT
        AS interpretation_note,

    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END AS requested_expected_loss_tier_rank,

    requested_expected_loss_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY requested_expected_loss_tier
            ),
            0
        ),
        6
    ) AS pct_of_requested_expected_loss_tier_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS positive_offer_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount IS NULL
    ) AS null_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount = 0
    ) AS zero_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount > 0
    ) AS positive_approved_expected_loss_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_expected_loss_amount_non_null_rows,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_amount_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_expected_loss_amount_positive_offer_rows,

    AVG(requested_amount)
        AS avg_requested_amount,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    AVG(estimated_pd)
        AS avg_synthetic_estimated_pd_proxy,

    AVG(estimated_lgd)
        AS avg_estimated_lgd,

    COUNT(DISTINCT product_type_policy_key)
        AS distinct_product_type_policy_key_count

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    requested_expected_loss_tier,
    decision_outcome

ORDER BY
    requested_expected_loss_tier_rank,
    requested_expected_loss_tier,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;
```

---

## Replace 9.4.18 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.18 Average approved_amount by decision_outcome.

Purpose:
    Summarize requested amount and final approved amount conventions by final decision outcome.

Interpretation:
    APPROVE:
        approved_amount should equal requested_amount.

    COUNTEROFFER:
        approved_amount should be positive and below requested_amount.

    MANUAL_REVIEW:
        approved_amount should remain NULL because the simulated outcome is unresolved.

    DECLINE:
        approved_amount should be zero because Module 2 uses the no-offer zero-exposure convention.

Documentation note:
    NULL approved values represent unresolved treatment.
    Zero approved values represent no-offer treatment.
    Positive approved values represent simulated positive offer exposure.

Boundary:
    This is a final outcome QA diagnostic.

    It does not create or modify final approved amount.
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
    ) AS pct_of_stage6_rows,

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
    ) AS avg_exposure_difference_for_non_null_approved_amount_rows,

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

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

## Replace 9.4.19 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.19 Average requested PTI and approved PTI by decision_outcome.

Purpose:
    Summarize requested-structure PTI and final approved PTI conventions by final decision outcome.

Interpretation:
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
    NULL approved PTI represents unresolved treatment.
    Zero approved PTI represents no-offer treatment.
    Positive approved PTI represents simulated positive offer exposure.

Boundary:
    This is a final outcome QA diagnostic.

    It does not create or modify approved PTI.
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
    ) AS pct_of_stage6_rows,

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
        AS avg_approved_payment_to_income_ratio_non_null_rows,

    AVG(COALESCE(approved_payment_to_income_ratio, 0))
        AS avg_approved_payment_to_income_ratio_all_rows_convention_adjusted,

    AVG(approved_payment_to_income_ratio) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_payment_to_income_ratio_positive_offer_rows,

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

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

## Replace 9.4.20 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.20 Average requested Expected Loss and approved Expected Loss by decision_outcome.

Purpose:
    Summarize requested-exposure Expected Loss and final approved-exposure Expected Loss conventions
    by final decision outcome.

Interpretation:
    APPROVE:
        approved_expected_loss_amount should equal requested_expected_loss_amount.

    COUNTEROFFER:
        approved_expected_loss_amount should generally be lower than requested Expected Loss because
        approved exposure is reduced while estimated_pd and estimated_lgd remain unchanged.

    MANUAL_REVIEW:
        approved_expected_loss_amount should remain NULL because the simulated outcome is unresolved.

    DECLINE:
        approved_expected_loss_amount should be zero because Module 2 uses the no-offer zero-exposure
        convention.

Documentation note:
    NULL approved Expected Loss represents unresolved treatment.
    Zero approved Expected Loss represents no-offer treatment.
    Positive approved Expected Loss represents simulated positive offer exposure.

Boundary:
    This is a final outcome QA diagnostic.

    It does not create or modify approved Expected Loss.
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
    ) AS pct_of_stage6_rows,

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
        AS avg_approved_expected_loss_amount_non_null_rows,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_expected_loss_amount_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_expected_loss_amount_positive_offer_rows,

    AVG(requested_expected_loss_amount - approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_expected_loss_reduction_positive_offer_rows,

    AVG(approved_el_reduction_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_reduction_amount_positive_offer_rows,

    AVG(approved_el_reduction_pct) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_reduction_pct_positive_offer_rows,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_expected_loss_amount_all_rows_convention_adjusted

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

## Replace 9.4.22 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.22 Option C aggressive counteroffer override final resolution diagnostic.

Purpose:
    Review final outcome behavior for rows that entered counteroffer feasibility through the
    aggressive requested-structure override path.

Why this diagnostic returns a row even when no aggressive override rows exist:
    For BASELINE_STRATEGY and non-aggressive strategies, zero aggressive override rows is expected.

    A one-row NOT_APPLICABLE diagnostic is easier to preserve in CSV exports than an empty result set.

Interpretation:
    AGGRESSIVE_OVERRIDE_FINAL_RESOLUTION_BREAKDOWN:
        Aggressive override rows exist and are summarized by product, score, risk tier, requested PTI,
        counteroffer feasibility, failed-counteroffer resolution, and final decision outcome.

    OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS:
        The current strategy did not produce aggressive override rows, which is expected for baseline
        and non-aggressive strategies.

    AGGRESSIVE_OVERRIDE_NO_ROWS_REVIEW_STRATEGY_CONTEXT:
        The current strategy is marked aggressive expansion but no aggressive override rows appeared.
        This may be acceptable for some populations, but should be reviewed.

Boundary:
    This is a Section 9 final-resolution QA diagnostic.

    It does not assign reason codes.
    It does not modify latest-run output.
    It does not modify archive rows.
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

        COUNT(*) AS stage6_rows,

        COUNT(*) FILTER (
            WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE
        ) AS aggressive_override_rows

    FROM tmp_m2_stage_6_final_decision_resolution
),

aggressive_override_breakdown AS (
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,

        preliminary_decision_outcome,
        preliminary_decision_path,

        exposure_treatment_status,
        exposure_treatment_path,

        counteroffer_feasibility_evaluated_flag,
        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason,

        failed_counteroffer_resolution,

        decision_outcome,
        decision_path,
        decision_resolution_source,
        simulated_offer_exposure_flag,

        COUNT(*) AS row_count,

        AVG(counteroffer_feasibility_constraint_count)
            AS avg_counteroffer_feasibility_constraint_count,

        AVG(requested_amount)
            AS avg_requested_amount,

        AVG(approved_amount)
            AS avg_approved_amount_non_null_rows,

        AVG(approved_amount) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_amount_positive_offer_rows,

        AVG(exposure_reduction_pct) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_exposure_reduction_pct_positive_offer_rows,

        AVG(requested_payment_to_income_ratio)
            AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_payment_to_income_ratio_positive_offer_rows,

        AVG(requested_expected_loss_amount)
            AS avg_requested_expected_loss_amount,

        AVG(approved_expected_loss_amount) FILTER (
            WHERE simulated_offer_exposure_flag IS TRUE
        ) AS avg_approved_expected_loss_amount_positive_offer_rows

    FROM tmp_m2_stage_6_final_decision_resolution

    WHERE aggressive_counteroffer_requested_structure_override_flag IS TRUE

    GROUP BY
        product_type_policy_key,
        score_band_policy_key,
        strategy_risk_tier,
        requested_pti_bucket,
        preliminary_decision_outcome,
        preliminary_decision_path,
        exposure_treatment_status,
        exposure_treatment_path,
        counteroffer_feasibility_evaluated_flag,
        counteroffer_feasibility_pass_flag,
        counteroffer_feasibility_failure_reason,
        failed_counteroffer_resolution,
        decision_outcome,
        decision_path,
        decision_resolution_source,
        simulated_offer_exposure_flag
)

SELECT
    'Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY; zero rows are expected for baseline and non-aggressive strategies.'::TEXT
        AS interpretation_note,

    'AGGRESSIVE_OVERRIDE_FINAL_RESOLUTION_BREAKDOWN'::TEXT
        AS option_c_aggressive_override_final_resolution_status,

    sc.strategy_name,
    sc.counteroffer_strategy_variant,
    sc.aggressive_counteroffer_expansion_enabled,

    b.product_type_policy_key,
    b.score_band_policy_key,
    b.strategy_risk_tier,
    b.requested_pti_bucket,

    b.preliminary_decision_outcome,
    b.preliminary_decision_path,

    b.exposure_treatment_status,
    b.exposure_treatment_path,

    b.counteroffer_feasibility_evaluated_flag,
    b.counteroffer_feasibility_pass_flag,
    b.counteroffer_feasibility_failure_reason,

    b.failed_counteroffer_resolution,

    b.decision_outcome,
    b.decision_path,
    b.decision_resolution_source,
    b.simulated_offer_exposure_flag,

    b.row_count,

    ROUND(
        b.row_count::NUMERIC
        / NULLIF(sc.aggressive_override_rows, 0),
        6
    ) AS pct_of_aggressive_override_rows,

    b.avg_counteroffer_feasibility_constraint_count,

    b.avg_requested_amount,
    b.avg_approved_amount_non_null_rows,
    b.avg_approved_amount_positive_offer_rows,
    b.avg_exposure_reduction_pct_positive_offer_rows,

    b.avg_requested_payment_to_income_ratio,
    b.avg_approved_payment_to_income_ratio_positive_offer_rows,

    b.avg_requested_expected_loss_amount,
    b.avg_approved_expected_loss_amount_positive_offer_rows

FROM aggressive_override_breakdown b

CROSS JOIN strategy_context sc

UNION ALL

SELECT
    'Aggressive override rows are expected only for AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY; zero rows are expected for baseline and non-aggressive strategies.'::TEXT
        AS interpretation_note,

    CASE
        WHEN sc.counteroffer_strategy_variant = 'AGGRESSIVE_EXPANSION'
          OR sc.aggressive_counteroffer_expansion_enabled IS TRUE
            THEN 'AGGRESSIVE_OVERRIDE_NO_ROWS_REVIEW_STRATEGY_CONTEXT'
        ELSE 'OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS'
    END AS option_c_aggressive_override_final_resolution_status,

    sc.strategy_name,
    sc.counteroffer_strategy_variant,
    sc.aggressive_counteroffer_expansion_enabled,

    NULL::TEXT AS product_type_policy_key,
    NULL::TEXT AS score_band_policy_key,
    NULL::TEXT AS strategy_risk_tier,
    NULL::TEXT AS requested_pti_bucket,

    NULL::TEXT AS preliminary_decision_outcome,
    NULL::TEXT AS preliminary_decision_path,

    NULL::TEXT AS exposure_treatment_status,
    NULL::TEXT AS exposure_treatment_path,

    NULL::BOOLEAN AS counteroffer_feasibility_evaluated_flag,
    NULL::BOOLEAN AS counteroffer_feasibility_pass_flag,
    NULL::TEXT AS counteroffer_feasibility_failure_reason,

    NULL::TEXT AS failed_counteroffer_resolution,

    NULL::TEXT AS decision_outcome,
    NULL::TEXT AS decision_path,
    NULL::TEXT AS decision_resolution_source,
    NULL::BOOLEAN AS simulated_offer_exposure_flag,

    0::BIGINT AS row_count,

    NULL::NUMERIC AS pct_of_aggressive_override_rows,

    NULL::NUMERIC AS avg_counteroffer_feasibility_constraint_count,

    NULL::NUMERIC AS avg_requested_amount,
    NULL::NUMERIC AS avg_approved_amount_non_null_rows,
    NULL::NUMERIC AS avg_approved_amount_positive_offer_rows,
    NULL::NUMERIC AS avg_exposure_reduction_pct_positive_offer_rows,

    NULL::NUMERIC AS avg_requested_payment_to_income_ratio,
    NULL::NUMERIC AS avg_approved_payment_to_income_ratio_positive_offer_rows,

    NULL::NUMERIC AS avg_requested_expected_loss_amount,
    NULL::NUMERIC AS avg_approved_expected_loss_amount_positive_offer_rows

FROM strategy_context sc

WHERE sc.aggressive_override_rows = 0

ORDER BY
    option_c_aggressive_override_final_resolution_status,
    product_type_policy_key NULLS FIRST,
    score_band_policy_key NULLS FIRST,
    strategy_risk_tier NULLS FIRST,
    requested_pti_bucket NULLS FIRST,
    decision_outcome NULLS FIRST,
    counteroffer_feasibility_pass_flag NULLS FIRST,
    counteroffer_feasibility_failure_reason NULLS FIRST;
```

These changes make Section 9 preservation-friendly in the same way we improved Sections 5, 6, 7, and 8: each CSV now carries enough interpretation context to prevent reviewers from confusing unresolved `NULL` outcomes, no-offer zero conventions, positive-offer exposure metrics, and product-policy-relative tiers.
<!-- END_MESSAGE C034-M01606 -->


---

<a id="c034-m01607"></a>

### C034-M01607

**Andrew** · 2026-05-17T14:58:49.207000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01607 -->
review updated section 9 refined QA:
<!-- END_MESSAGE C034-M01607 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.13_QA_requested_exposure_tier_x_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.14_QA_requested_expected_loss_tier_x_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.18_QA_average_approved_amount_by_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.19_QA_average_requested_pti_and_approved_pti_by_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.20_QA_average_requested_expected_loss_and_approved_expected_loss_by_decision_outcome(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.22_QA_option_c_aggressive_counteroffer_override_final_resolution_diagnostic(1).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.9_QA_product_x_score_segment_x_decision_outcome(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m01612"></a>

### C034-M01612

**ChatGPT** · 2026-05-17T15:04:25.350794-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01612 -->
## Updated Section 9 refined QA review verdict

```text
Section 9 refined QA status: PASS
Refinement status: accepted
Logic blockers: none
Convention issues: none
Required logic changes: none
High-value export polish: shorten 3 long column aliases to avoid PostgreSQL 63-character truncation
```

The refined Section 9 QA outputs are materially better. They now clearly distinguish:

```text
NULL = unresolved MANUAL_REVIEW treatment
0 = no-offer DECLINE convention
positive value = simulated positive offer exposure
all-row convention-adjusted metrics = portfolio aggregation view
positive-offer-only metrics = APPROVE / COUNTEROFFER exposure view
```

That is aligned with Section 9’s role as the final simulated outcome-resolution layer before reason-code assignment. Section 9 resolves final decision outcomes, final decision flags, simulated offer exposure, approved exposure, approved affordability proxy, and approved Expected Loss, while reason-code assignment remains Section 10. fileciteturn396file34

---

## 9.4.9 — Product × score segment × decision outcome

```text
Status: PASS
Rows: 50,000
Product × score segments: 25
Output rows: 86
```

The refined output works well. It now separates all-row convention-adjusted approved metrics from positive-offer-only metrics.

Reconciliation is clean:

```text
APPROVE          10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
DECLINE          12,703
total            50,000
```

Approved-field convention reconciliation is also clean:

```text
positive_offer_rows                  29,762
positive_approved_amount_rows         29,762
null_approved_amount_rows              7,535
zero_approved_amount_rows             12,703
```

By final decision:

```text
APPROVE / COUNTEROFFER
    positive approved amount rows only

MANUAL_REVIEW
    null approved amount rows only

DECLINE
    zero approved amount rows only
```

This is exactly the final-output convention expected for Section 9. The added interpretation note is valuable and should remain.

**Only polish item:** one long column alias is truncated by PostgreSQL:

```text
total_approved_expected_loss_amount_all_rows_convention_adjuste
```

That should be shortened before final CSV preservation.

---

## 9.4.13 — Requested exposure tier × decision outcome

```text
Status: PASS
Rows: 50,000
```

Tier totals reconcile:

```text
LOW_REQUESTED_EXPOSURE          20,582
WITHIN_PRODUCT_APPROVAL_CAP     16,790
ABOVE_PRODUCT_APPROVAL_CAP      12,628
```

Outcome totals reconcile:

```text
APPROVE          10,695
COUNTEROFFER     19,067
MANUAL_REVIEW     7,535
DECLINE          12,703
```

The most important behavior is clean:

```text
ABOVE_PRODUCT_APPROVAL_CAP / APPROVE = 0
```

Above-cap rows resolve as expected:

```text
COUNTEROFFER     8,905
MANUAL_REVIEW    1,096
DECLINE          2,627
```

The new interpretation note correctly explains that requested exposure tiers are product-policy-relative. That note is useful because the average requested amounts can look counterintuitive without product context.

No further change recommended.

---

## 9.4.14 — Requested Expected Loss tier × decision outcome

```text
Status: PASS
Rows: 50,000
```

Tier totals reconcile:

```text
LOW_REQUESTED_EL          26,158
MODERATE_REQUESTED_EL      8,409
ELEVATED_REQUESTED_EL      7,891
HIGH_REQUESTED_EL          5,553
SEVERE_REQUESTED_EL        1,989
```

The final outcome pattern is coherent:

```text
LOW_REQUESTED_EL
    APPROVE / COUNTEROFFER / MANUAL_REVIEW / DECLINE all present

MODERATE_REQUESTED_EL
    small APPROVE population, large COUNTEROFFER population, some MANUAL_REVIEW / DECLINE

ELEVATED_REQUESTED_EL
    no APPROVE, but still some COUNTEROFFER

HIGH_REQUESTED_EL
    no APPROVE or COUNTEROFFER; MANUAL_REVIEW / DECLINE only

SEVERE_REQUESTED_EL
    no APPROVE or COUNTEROFFER; mostly DECLINE with small MANUAL_REVIEW
```

The product-policy-relative interpretation note is doing useful work here. It explains why requested Expected Loss tier averages can overlap or appear non-monotonic when product mix, LGD, requested amount, and product-specific thresholds differ.

No further change recommended.

---

## 9.4.18 — Average approved amount by decision outcome

```text
Status: PASS
Rows: 50,000
```

The refined output is clean and self-explanatory.

Approved amount convention:

```text
APPROVE
    row_count = 10,695
    positive_approved_amount_rows = 10,695

COUNTEROFFER
    row_count = 19,067
    positive_approved_amount_rows = 19,067

MANUAL_REVIEW
    row_count = 7,535
    null_approved_amount_rows = 7,535

DECLINE
    row_count = 12,703
    zero_approved_amount_rows = 12,703
```

The interpretation note now prevents the common misread where `total_approved_amount = 0` for manual review might be confused with a true zero-offer outcome. The output now makes clear that manual review is unresolved, while decline is zero-offer.

No further change recommended.

---

## 9.4.19 — Requested PTI and approved PTI by decision outcome

```text
Status: PASS
Rows: 50,000
```

Approved PTI convention:

```text
APPROVE
    positive_approved_pti_rows = 10,695

COUNTEROFFER
    positive_approved_pti_rows = 19,067

MANUAL_REVIEW
    null_approved_pti_rows = 7,535

DECLINE
    zero_approved_pti_rows = 12,703
```

This cleanly documents:

```text
APPROVE preserves requested PTI
COUNTEROFFER reduces approved PTI
MANUAL_REVIEW remains unresolved
DECLINE follows zero no-offer convention
```

**Only polish item:** one long column alias is truncated:

```text
avg_approved_payment_to_income_ratio_all_rows_convention_adjust
```

Shorten it before final CSV preservation.

---

## 9.4.20 — Requested Expected Loss and approved Expected Loss by decision outcome

```text
Status: PASS
Rows: 50,000
```

Approved Expected Loss convention:

```text
APPROVE
    positive_approved_expected_loss_rows = 10,695

COUNTEROFFER
    positive_approved_expected_loss_rows = 19,067

MANUAL_REVIEW
    null_approved_expected_loss_rows = 7,535

DECLINE
    zero_approved_expected_loss_rows = 12,703
```

The economics are coherent:

```text
APPROVE
    requested EL = approved EL

COUNTEROFFER
    approved EL < requested EL

MANUAL_REVIEW
    approved EL = NULL

DECLINE
    approved EL = 0
```

The interpretation note is strong and should remain.

**Only polish item:** one long column alias is truncated:

```text
total_approved_expected_loss_amount_all_rows_convention_adjuste
```

Shorten it before final CSV preservation.

---

## 9.4.22 — Option C aggressive override final-resolution diagnostic

```text
Status: PASS
Rows: 1 deliberate NOT_APPLICABLE row
```

This refinement worked exactly as intended.

The output now returns:

```text
option_c_aggressive_override_final_resolution_status =
OPTION_C_NOT_APPLICABLE_NO_AGGRESSIVE_OVERRIDE_ROWS

strategy_name =
BASELINE_STRATEGY

counteroffer_strategy_variant =
NOT_COUNTEROFFER_SPLIT_STRATEGY

aggressive_counteroffer_expansion_enabled =
false

row_count = 0
```

This is the correct M2-01 baseline posture. It is much better than an empty export because the CSV now proves the query ran and that zero aggressive override rows are expected for baseline.

No further change recommended.

---

# One export-polish recommendation

The only issue I see is **PostgreSQL alias truncation** on a few long QA column names. This is not a logic blocker, but it is worth fixing before final preservation because truncated column names look unpolished in CSVs.

Use shorter aliases like these:

```sql
-- 9.4.9 and 9.4.20
AS total_approved_el_all_rows_convention_adjusted

-- 9.4.19
AS avg_approved_pti_all_rows_convention_adjusted
```

Specifically, replace:

```sql
AS total_approved_expected_loss_amount_all_rows_convention_adjusted
```

with:

```sql
AS total_approved_el_all_rows_convention_adjusted
```

and replace:

```sql
AS avg_approved_payment_to_income_ratio_all_rows_convention_adjusted
```

with:

```sql
AS avg_approved_pti_all_rows_convention_adjusted
```

You could also optionally shorten:

```sql
avg_approved_expected_loss_amount_all_rows_convention_adjusted
```

to:

```sql
avg_approved_el_all_rows_convention_adjusted
```

That one did not truncate in the observed output, but shortening it would improve consistency.

---

## Final signoff

```text
Updated Section 9 refined QA: ACCEPTED

No blockers.
No final-decision logic issues.
No row-count reconciliation issues.
No approved amount convention issues.
No approved PTI convention issues.
No approved Expected Loss convention issues.
No Option C baseline-posture issue.
Only recommended cleanup: shorten 3 long export aliases to avoid PostgreSQL identifier truncation.
```
<!-- END_MESSAGE C034-M01612 -->


---

<a id="c034-m01614"></a>

### C034-M01614

**Andrew** · 2026-05-17T16:07:07.040000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01614 -->
please update the qa's related to this and provide full copy paste for those sections: One export-polish recommendation

The only issue I see is PostgreSQL alias truncation on a few long QA column names. This is not a logic blocker, but it is worth fixing before final preservation because truncated column names look unpolished in CSVs.

Use shorter aliases like these:

-- 9.4.9 and 9.4.20
AS total_approved_el_all_rows_convention_adjusted

-- 9.4.19
AS avg_approved_pti_all_rows_convention_adjusted

Specifically, replace:

AS total_approved_expected_loss_amount_all_rows_convention_adjusted

with:

AS total_approved_el_all_rows_convention_adjusted

and replace:

AS avg_approved_payment_to_income_ratio_all_rows_convention_adjusted

with:

AS avg_approved_pti_all_rows_convention_adjusted

You could also optionally shorten:

avg_approved_expected_loss_amount_all_rows_convention_adjusted

to:

avg_approved_el_all_rows_convention_adjusted

That one did not truncate in the observed output, but shortening it would improve consistency.
<!-- END_MESSAGE C034-M01614 -->


---

<a id="c034-m01616"></a>

### C034-M01616

**ChatGPT** · 2026-05-17T16:10:56.944354-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01616 -->
Below are the full copy-paste replacements for the QA sections affected by the PostgreSQL alias-length cleanup.

Replace these four sections:

```text
9.4.9
9.4.14
9.4.19
9.4.20
```

The changes are export-polish only. They shorten long aliases so PostgreSQL does not truncate CSV column names.

---

## Replace 9.4.9 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.9 Product × score segment × decision_outcome.

Purpose:
    Review final outcome behavior at the product × score segment grain.

Why this refinement exists:
    Product × score segment output is often used later for executive evidence, README narrative,
    validation-summary support, and Module 3 planning.

    Segment-level all-row approved exposure metrics can be useful for portfolio impact, but they
    should be clearly distinguished from positive-offer-only metrics.

Alias-length note:
    PostgreSQL truncates identifiers longer than 63 bytes.

    This QA export therefore uses shorter Expected Loss aliases such as:
        avg_approved_el_all_rows_convention_adjusted
        total_approved_el_all_rows_convention_adjusted

    instead of longer aliases that would be truncated in CSV exports.

Interpretation:
    all_rows_convention_adjusted metrics:
        Use Module 2 final outcome conventions for segment-level portfolio aggregation.

        MANUAL_REVIEW rows are unresolved and have NULL approved fields.
        DECLINE rows use the zero-exposure / zero-Expected-Loss convention.

        COALESCE is used only for all-row portfolio impact metrics.

    positive_offer metrics:
        Include only APPROVE and COUNTEROFFER rows where simulated_offer_exposure_flag = TRUE.

        These are the correct metrics for interpreting approved exposure and approved Expected Loss
        among simulated positive offers.

Boundary:
    This is a Section 9 final-decision QA diagnostic.

    It does not assign reason codes.
    It does not modify latest-run output.
    It does not modify archive rows.
-----------------------------------------------------------------------------------------------*/

SELECT
    'All-row approved exposure metrics use final outcome conventions for portfolio aggregation; positive-offer-only metrics separately isolate APPROVE and COUNTEROFFER exposure behavior.'::TEXT
        AS interpretation_note,

    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY
                    product_type_policy_key,
                    score_band_policy_key,
                    product_score_policy_segment
            ),
            0
        ),
        6
    ) AS pct_of_product_score_segment_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS positive_offer_rows,

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

    AVG(approved_amount)
        AS avg_approved_amount_non_null_rows,

    AVG(COALESCE(approved_amount, 0))
        AS avg_approved_amount_all_rows_convention_adjusted,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    SUM(requested_amount)
        AS total_requested_amount,

    SUM(COALESCE(approved_amount, 0))
        AS total_approved_amount_all_rows_convention_adjusted,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_el_non_null_rows,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_el_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_positive_offer_rows,

    SUM(requested_expected_loss_amount)
        AS total_requested_expected_loss_amount,

    SUM(COALESCE(approved_expected_loss_amount, 0))
        AS total_approved_el_all_rows_convention_adjusted,

    AVG(approved_payment_to_income_ratio) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_pti_positive_offer_rows,

    AVG(estimated_pd)
        AS avg_synthetic_estimated_pd_proxy,

    AVG(estimated_lgd)
        AS avg_estimated_lgd

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,
    decision_outcome

ORDER BY
    product_type_policy_key,
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    score_band_policy_key,
    product_score_policy_segment,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;
```

---

## Replace 9.4.14 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.14 Requested Expected Loss tier × decision_outcome.

Purpose:
    Review how product-policy-relative requested Expected Loss tiers resolve into final simulated
    decision outcomes.

Why this diagnostic needs an interpretation note:
    requested_expected_loss_tier is product-policy-relative.

    Product-specific requested-EL thresholds, product mix, requested amount, estimated-LGD, and
    synthetic estimated-PD proxy can make aggregate tier-level averages appear non-monotonic.

    This is not automatically a defect.

Alias-length note:
    PostgreSQL truncates identifiers longer than 63 bytes.

    This QA export therefore uses shorter approved Expected Loss aliases such as:
        avg_approved_el_all_rows_convention_adjusted
        avg_approved_el_positive_offer_rows

Interpretation:
    requested_expected_loss_amount is requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount is final simulated approved-exposure Expected Loss after Module 2
    final decision resolution.

Boundary:
    This is a final decision QA diagnostic.

    It does not change requested Expected Loss tiering.
    It does not change final decisions.
-----------------------------------------------------------------------------------------------*/

SELECT
    'Requested Expected Loss tiers are product-policy-relative; aggregate tier averages can overlap or appear non-monotonic when product mix, LGD, requested amount, and product-specific thresholds differ by tier.'::TEXT
        AS interpretation_note,

    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END AS requested_expected_loss_tier_rank,

    requested_expected_loss_tier,
    decision_outcome,

    COUNT(*) AS row_count,

    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY requested_expected_loss_tier
            ),
            0
        ),
        6
    ) AS pct_of_requested_expected_loss_tier_rows,

    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS positive_offer_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount IS NULL
    ) AS null_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount = 0
    ) AS zero_approved_expected_loss_rows,

    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount > 0
    ) AS positive_approved_expected_loss_rows,

    AVG(requested_expected_loss_amount)
        AS avg_requested_expected_loss_amount,

    AVG(approved_expected_loss_amount)
        AS avg_approved_el_non_null_rows,

    AVG(COALESCE(approved_expected_loss_amount, 0))
        AS avg_approved_el_all_rows_convention_adjusted,

    AVG(approved_expected_loss_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_el_positive_offer_rows,

    AVG(requested_amount)
        AS avg_requested_amount,

    AVG(approved_amount) FILTER (
        WHERE simulated_offer_exposure_flag IS TRUE
    ) AS avg_approved_amount_positive_offer_rows,

    AVG(estimated_pd)
        AS avg_synthetic_estimated_pd_proxy,

    AVG(estimated_lgd)
        AS avg_estimated_lgd,

    COUNT(DISTINCT product_type_policy_key)
        AS distinct_product_type_policy_key_count

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY
    requested_expected_loss_tier,
    decision_outcome

ORDER BY
    requested_expected_loss_tier_rank,
    requested_expected_loss_tier,
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;
```

---

## Replace 9.4.19 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.19 Average requested PTI and approved PTI by decision_outcome.

Purpose:
    Summarize requested-structure PTI and final approved PTI conventions by final decision outcome.

Interpretation:
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

Alias-length note:
    PostgreSQL truncates identifiers longer than 63 bytes.

    This QA export therefore uses:
        avg_approved_pti_all_rows_convention_adjusted

    instead of the longer approved-payment-to-income-ratio alias.

Documentation note:
    NULL approved PTI represents unresolved treatment.
    Zero approved PTI represents no-offer treatment.
    Positive approved PTI represents simulated positive offer exposure.

Boundary:
    This is a final outcome QA diagnostic.

    It does not create or modify approved PTI.
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
    ) AS pct_of_stage6_rows,

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

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

---

## Replace 9.4.20 with this

```sql
/*-----------------------------------------------------------------------------------------------
9.4.20 Average requested Expected Loss and approved Expected Loss by decision_outcome.

Purpose:
    Summarize requested-exposure Expected Loss and final approved-exposure Expected Loss conventions
    by final decision outcome.

Interpretation:
    APPROVE:
        approved_expected_loss_amount should equal requested_expected_loss_amount.

    COUNTEROFFER:
        approved_expected_loss_amount should generally be lower than requested Expected Loss because
        approved exposure is reduced while estimated_pd and estimated_lgd remain unchanged.

    MANUAL_REVIEW:
        approved_expected_loss_amount should remain NULL because the simulated outcome is unresolved.

    DECLINE:
        approved_expected_loss_amount should be zero because Module 2 uses the no-offer zero-exposure
        convention.

Alias-length note:
    PostgreSQL truncates identifiers longer than 63 bytes.

    This QA export therefore uses shorter approved Expected Loss aliases such as:
        avg_approved_el_all_rows_convention_adjusted
        total_approved_el_all_rows_convention_adjusted

Documentation note:
    NULL approved Expected Loss represents unresolved treatment.
    Zero approved Expected Loss represents no-offer treatment.
    Positive approved Expected Loss represents simulated positive offer exposure.

Boundary:
    This is a final outcome QA diagnostic.

    It does not create or modify approved Expected Loss.
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
    ) AS pct_of_stage6_rows,

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

FROM tmp_m2_stage_6_final_decision_resolution

GROUP BY decision_outcome

ORDER BY decision_outcome_rank;
```

These four replacements should eliminate the observed truncation while keeping the Section 9 QA narrative and metrics intact.
<!-- END_MESSAGE C034-M01616 -->


---

<a id="c034-m01617"></a>

### C034-M01617

**Andrew** · 2026-05-17T16:24:18.793000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M01617 -->
review updated section 9 QA refined:
<!-- END_MESSAGE C034-M01617 -->


**Attachments in export:** `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.20_QA_average_requested_expected_loss_and_approved_expected_loss_by_decision_outcome(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.19_QA_average_requested_pti_and_approved_pti_by_decision_outcome(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.9_QA_product_x_score_segment_x_decision_outcome(2).csv`, `module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_9.4.14_QA_requested_expected_loss_tier_x_decision_outcome(2).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_30.md) · [Next](Part_32.md)
