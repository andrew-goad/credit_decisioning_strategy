# Module 2 Decision Simulator Build

## Part 06

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_05.md) · [Next](Part_07.md)

<a id="c038-m00142"></a>

### C038-M00142

**Andrew** · 2026-05-06T14:30:21.558000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00142 -->
This is strong. I agree with the Section 10 Simulated Reason-Code Assignment Layer.

Section 10 should be treated as provisionally accepted after the targeted patches below.

Section 10 correctly:
- consumes tmp_m2_stage_6_final_decision_resolution
- creates tmp_m2_stage_7_reason_code_assignment
- assigns simulated strategy explanation codes after final decision resolution
- preserves final decision_outcome, final decision_path, and decision_resolution_source
- uses a candidate → rank → pivot pattern rather than one opaque CASE block
- creates primary_reason_code, secondary_reason_code, and tertiary_reason_code
- creates primary_reason_family
- creates triggered_reason_code_list
- creates reason_priority_rank
- creates reason_code_count
- gives APPROVE rows APPROVED_AS_REQUESTED
- keeps reason codes outcome-family aligned
- avoids adverse-action / regulatory / customer-notice framing
- does not create the final latest-run strategy_decisions table
- does not insert archive rows
- does not build the full QA framework

Before moving to Section 11, please apply the targeted Section 10 patches below.

Do not rewrite Sections 0–10 in full unless necessary.

================================================================================
1. TARGETED SECTION 10 PATCH — COUNTEROFFER PRODUCT-CAP BINDING CONDITION
================================================================================

In the COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT candidate logic, please revise the product-cap binding condition.

Current logic appears to test something directionally like:

counteroffer_product_cap_amount < counteroffer_raw_max_feasible_amount

That is not the correct binding test because:

counteroffer_raw_max_feasible_amount =
    LEAST(
        requested_amount,
        counteroffer_product_cap_amount,
        counteroffer_pti_target_amount,
        counteroffer_el_cap_amount
    )

Therefore, counteroffer_raw_max_feasible_amount should not exceed counteroffer_product_cap_amount.

The product cap is binding when:

counteroffer_product_cap_amount = counteroffer_raw_max_feasible_amount

Recommended patch:

Use:

counteroffer_product_cap_amount IS NOT NULL
AND counteroffer_raw_max_feasible_amount IS NOT NULL
AND counteroffer_product_cap_amount = counteroffer_raw_max_feasible_amount
AND requested_amount > product_max_approved_amount

This preserves the intended logic:
- requested amount exceeds the product approval cap
- the product cap is one of the binding feasibility constraints

If multiple constraints are equal and binding, multiple candidate reason codes may remain active. That is acceptable because Section 10 ranks reason candidates and preserves secondary / tertiary diagnostics.

================================================================================
2. TARGETED SECTION 10 PATCH — DECLINE REASON FOR HIGH REQUESTED PTI
================================================================================

Please add a DECLINE / POLICY_STOP candidate reason for high requested PTI.

Reason code:

POLICY_STOP_HIGH_REQUESTED_PTI

Recommended family:

POLICY_STOP

Recommended priority rank:

145

Recommended condition:

decision_outcome = 'DECLINE'
AND (
    requested_pti_decline_trigger_flag IS TRUE
    OR (
        preliminary_decision_outcome = 'COUNTEROFFER'
        AND counteroffer_feasibility_pass_flag IS FALSE
        AND failed_counteroffer_resolution = 'DECLINE'
        AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
    )
)

Reason:
- High requested PTI is one of the locked affordability stress / stop conditions.
- If a counteroffer fails because approved PTI still exceeds target and the strategy resolves failed counteroffers to DECLINE, the final no-offer path should be able to explain the affordability constraint directly.
- This remains a simulated strategy explanation code, not an adverse-action reason.

Place it after POLICY_STOP_HIGH_DTI or near the other affordability-related policy-stop reasons.

Do not remove POLICY_STOP_COUNTEROFFER_NOT_FEASIBLE.
That reason can still appear as a secondary or tertiary diagnostic reason when applicable.

================================================================================
3. TARGETED SECTION 10 PATCH — REQUESTED EXPECTED LOSS DECLINE REASON LABEL
================================================================================

If the current Section 10 code uses:

POLICY_STOP_EXPECTED_LOSS_UNRESOLVED

for requested_el_decline_trigger_flag, please rename it to:

POLICY_STOP_HIGH_REQUESTED_EXPECTED_LOSS

Reason:
- This more directly aligns with the locked reason-code taxonomy.
- It distinguishes requested-exposure Expected Loss from approved-exposure Expected Loss.
- It makes the reason code more readable in final strategy output.

Recommended condition:

decision_outcome = 'DECLINE'
AND requested_el_decline_trigger_flag IS TRUE

Do not use this reason for approved Expected Loss cap failures unless the row is specifically explaining requested-exposure Expected Loss pressure.

Approved-exposure Expected Loss issues should remain tied to counteroffer feasibility diagnostics where applicable.

================================================================================
4. TARGETED SECTION 10 PATCH — EXACT COUNTEROFFER FAILURE LABEL ALIGNMENT
================================================================================

Before finalizing Section 10, please confirm that all Section 10 references to Section 8 counteroffer_feasibility_failure_reason values use the exact strings created in Section 8.

Current Section 8 failure reason labels include:

- COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT
- COUNTEROFFER_RAW_AMOUNT_NULL
- COUNTEROFFER_ROUNDED_AMOUNT_NULL
- COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE
- COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT
- COUNTEROFFER_BELOW_PRODUCT_MINIMUM
- COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT
- COUNTEROFFER_EXCEEDS_MAX_REDUCTION
- COUNTEROFFER_EXCEEDS_PRODUCT_CAP
- COUNTEROFFER_PTI_STILL_ABOVE_TARGET
- COUNTEROFFER_APPROVED_EL_ABOVE_CAP
- COUNTEROFFER_FEASIBILITY_UNKNOWN

Important:
If Section 10 currently references:

COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE

but Section 8 actually creates:

COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE

then Section 10 must be patched to use the exact Section 8 value.

Do not create near-match strings.

Reason:
Reason-code assignment should be deterministic and label-aligned. A one-character mismatch can silently prevent the intended candidate reason from firing.

================================================================================
5. TARGETED SECTION 10 PATCH — COUNTEROFFER NOT REDUCED / NOT BELOW REQUESTED
================================================================================

Please add a specific MANUAL_REVIEW candidate reason for the following Section 8 failure reason:

COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT

Recommended reason code:

MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED

Recommended family:

MANUAL_REVIEW

Recommended condition:

decision_outcome = 'MANUAL_REVIEW'
AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'

Reason:
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT is not the same as a below-minimum-offer failure.

It means the feasible rounded counteroffer did not produce a reduced exposure relative to the original request. That is a distinct unresolved counteroffer condition and should not be buried inside MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER.

This improves interpretability for failed-counteroffer review cases.

If failed_counteroffer_resolution = 'DECLINE', the same underlying failure can still be explained by POLICY_STOP_COUNTEROFFER_NOT_FEASIBLE as a broader no-offer path unless we later decide to create a more specific decline reason for this case.

================================================================================
6. SECTION 10 ACCEPTANCE CRITERIA
================================================================================

After these targeted patches, treat Section 10 as accepted if it establishes:

- tmp_m2_stage_7_reason_code_assignment exists
- row count is unchanged from tmp_m2_stage_6_final_decision_resolution
- application_id remains unique
- final decision_outcome is preserved
- final decision_path is preserved
- decision_resolution_source is preserved
- primary_reason_code is populated for every row
- primary_reason_family is populated for every row
- reason_priority_rank is populated for every row
- triggered_reason_code_list is populated for every row
- reason_code_count is positive for every row
- APPROVE rows use APPROVED_AS_REQUESTED
- COUNTEROFFER rows use COUNTEROFFER-family primary reasons
- MANUAL_REVIEW rows use MANUAL_REVIEW-family primary reasons
- DECLINE rows use POLICY_STOP-family primary reasons
- reason-code family aligns to final decision_outcome
- secondary_reason_code and tertiary_reason_code are populated only when additional outcome-family-aligned diagnostics exist
- Section 10 references exact Section 8 / Section 9 labels
- no reason-code field uses adverse-action, regulatory, customer-notice, or fair-lending language
- no final latest-run output table is created
- no archive rows are inserted
- no full QA framework is created

================================================================================
7. NEXT BUILD SCOPE: SECTION 11 ONLY
================================================================================

After the targeted Section 10 patches, please build only:

SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE

Final latest-run table:

credit_decisioning_sim.strategy_decisions

Section 11 should consume:

tmp_m2_stage_7_reason_code_assignment

Do not build:
- strategy_decisions_archive insert logic
- archive reset / replacement logic
- matched strategy comparison queries
- full QA framework
- BRD or Validation Summary documentation

Those belong to later sections.

================================================================================
8. SECTION 11 OBJECTIVE
================================================================================

Section 11 should materialize the final latest-run Module 2 strategy output table.

Section 11 should answer:

“What is the current final simulated strategy output for the selected Module 1 source population / scenario and active Module 2 strategy?”

Section 11 should not answer:

“How do archived strategy runs compare over time?”

Archive persistence and matched strategy comparison should remain separate later sections.

================================================================================
9. LATEST-RUN TABLE DESIGN
================================================================================

Create or replace:

credit_decisioning_sim.strategy_decisions

Recommended grain:

one row per application_id for the selected Module 1 source scenario / population and active Module 2 strategy.

This is the current latest-run output only.

It should not preserve prior runs.
Prior runs should be preserved later in the archive table.

Important:
Section 11 may drop and recreate credit_decisioning_sim.strategy_decisions for clean rerun behavior.

Do not drop or modify credit_decisioning_sim.strategy_decisions_archive in Section 11.

================================================================================
10. EXPLICIT FIELD SELECTION REQUIREMENT
================================================================================

Please use an explicit SELECT list when creating credit_decisioning_sim.strategy_decisions.

Do not use SELECT * for the permanent latest-run output table.

Reason:
The final table schema should be governed, reviewable, and stable.

Temporary staging tables can carry many diagnostics, but the final latest-run table should intentionally expose the fields needed for:
- downstream QA
- archive persistence
- reporting
- review
- documentation
- future Module 2 validation

================================================================================
11. REQUIRED FIELD FAMILIES FOR strategy_decisions
================================================================================

The latest-run table should include the following field families.

--------------------------------------------------------------------------------
1. Module 2 strategy metadata
--------------------------------------------------------------------------------

- module2_model_version
- strategy_set_name
- strategy_name
- strategy_version
- strategy_run_id
- strategy_run_ts
- module1_input_source
- module1_source_table_name

Interpretation:
strategy_run_id and strategy_run_ts are audit metadata. They support traceability, but they do not replace the archive replacement / rerun key.

--------------------------------------------------------------------------------
2. Module 1 lineage
--------------------------------------------------------------------------------

- module1_model_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- anchor_date

Interpretation:
These fields preserve upstream synthetic population and scenario lineage from Module 1.

--------------------------------------------------------------------------------
3. Application lineage
--------------------------------------------------------------------------------

- application_seq
- application_id
- applicant_id
- application_date

--------------------------------------------------------------------------------
4. Product and score segmentation
--------------------------------------------------------------------------------

- product_type
- product_type_policy_key
- score_band
- score_band_policy_key
- credit_score
- product_score_policy_segment

--------------------------------------------------------------------------------
5. Borrower and behavioral profile
--------------------------------------------------------------------------------

- annual_income
- debt_to_income_ratio
- utilization_rate
- tradeline_count
- months_since_oldest_trade
- recent_inquiry_count
- delinquency_count_12m
- major_derogatory_flag
- bankruptcy_flag
- prequalified_flag
- returning_customer_flag

If prequalified_flag or returning_customer_flag were optional source fields and are not available, preserve them as nullable fields if already staged.

--------------------------------------------------------------------------------
6. Requested structure and requested-exposure economics
--------------------------------------------------------------------------------

- requested_amount
- loan_term_months
- base_apr_for_payment_calc
- requested_monthly_payment_proxy
- requested_payment_to_income_ratio
- amount_to_income_ratio
- estimated_pd
- estimated_lgd
- requested_expected_loss_amount

Important commentary:
- estimated_pd remains the finalized Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy.
- requested_expected_loss_amount is the Module 2 alias for Module 1 requested-exposure Expected Loss.

--------------------------------------------------------------------------------
7. Strategy segmentation diagnostics
--------------------------------------------------------------------------------

- strategy_risk_tier
- requested_pti_bucket
- dti_bucket
- requested_exposure_tier
- requested_expected_loss_tier
- mixed_signal_profile_type
- mixed_signal_condition_count
- borderline_profile_flag

--------------------------------------------------------------------------------
8. Rule-trigger diagnostics
--------------------------------------------------------------------------------

Include the major rule flag and count fields needed for audit review, including:

- hard_policy_stop_flag
- hard_policy_stop_count
- synthetic_risk_decline_trigger_flag
- requested_pti_decline_trigger_flag
- dti_decline_trigger_flag
- requested_el_decline_trigger_flag
- requested_exposure_extreme_flag
- exposure_policy_stop_candidate_flag
- counteroffer_candidate_flag
- manual_review_candidate_flag
- clean_approval_candidate_flag
- total_rule_trigger_count

If other trigger fields are important for reason-code traceability, include them as well.

--------------------------------------------------------------------------------
9. Preliminary routing diagnostics
--------------------------------------------------------------------------------

- preliminary_decision_outcome
- preliminary_decision_path
- preliminary_decision_priority_rank
- preliminary_route_reason_family
- preliminary_route_trigger_count
- requires_counteroffer_feasibility_flag
- requires_approved_exposure_calculation_flag

--------------------------------------------------------------------------------
10. Exposure treatment and counteroffer diagnostics
--------------------------------------------------------------------------------

- exposure_treatment_status
- exposure_treatment_path
- counteroffer_feasibility_evaluated_flag
- counteroffer_feasibility_pass_flag
- counteroffer_feasibility_failure_reason
- counteroffer_feasibility_constraint_count
- counteroffer_product_cap_amount
- counteroffer_pti_target_amount
- counteroffer_el_cap_amount
- counteroffer_raw_max_feasible_amount
- counteroffer_min_viable_amount
- counteroffer_rounded_amount

--------------------------------------------------------------------------------
11. Final decision outcome fields
--------------------------------------------------------------------------------

- decision_outcome
- decision_path
- decision_priority_rank
- decision_resolution_source

--------------------------------------------------------------------------------
12. Final decision flags
--------------------------------------------------------------------------------

- approval_flag
- counteroffer_flag
- manual_review_flag
- decline_flag
- simulated_offer_exposure_flag

--------------------------------------------------------------------------------
13. Final approved exposure and economics
--------------------------------------------------------------------------------

- approved_amount
- counteroffer_amount
- exposure_reduction_flag
- exposure_reduction_amount
- exposure_reduction_pct
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount
- approved_el_reduction_amount
- approved_el_reduction_pct

--------------------------------------------------------------------------------
14. Simulated reason-code fields
--------------------------------------------------------------------------------

- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- primary_reason_family
- triggered_reason_code_list
- reason_priority_rank
- reason_code_count

--------------------------------------------------------------------------------
15. Latest-run audit timestamp
--------------------------------------------------------------------------------

- latest_output_created_ts

Recommended expression:

CURRENT_TIMESTAMP AS latest_output_created_ts

Interpretation:
latest_output_created_ts records when the latest-run table was materialized.

It is audit metadata.
It is not deterministic comparison evidence.

Matched strategy comparison should exclude timestamp fields unless the test is specifically validating run metadata.

================================================================================
12. LATEST-RUN OUTPUT CONVENTIONS
================================================================================

Section 11 should preserve the locked interpretation:

- APPROVE and COUNTEROFFER are simulated positive offer-exposure outcomes.
- MANUAL_REVIEW is unresolved by design.
- DECLINE follows the zero-exposure convention.
- simulated_offer_exposure_flag does not imply real booking, funded exposure, production approval, or customer treatment.
- approved_expected_loss_amount is a simulated approved-exposure Expected Loss measure, not a production loss forecast.
- reason codes are simulated strategy explanation codes, not adverse-action reasons.
- estimated_pd remains the Module 1 synthetic estimated-PD proxy input and is not recalculated in Module 2.

================================================================================
13. SECTION 11 LOCAL GATEKEEPERS
================================================================================

At the end of Section 11, include local fail-fast checks.

Validate:

--------------------------------------------------------------------------------
1. General table integrity
--------------------------------------------------------------------------------

- credit_decisioning_sim.strategy_decisions exists
- row count matches tmp_m2_stage_7_reason_code_assignment
- application_id remains unique
- latest_output_created_ts is non-null

--------------------------------------------------------------------------------
2. Metadata and lineage integrity
--------------------------------------------------------------------------------

- strategy_set_name is non-null
- strategy_name is non-null
- strategy_version is non-null
- strategy_run_id is non-null
- strategy_run_ts is non-null
- module1_scenario_set_name is non-null
- module1_scenario_name is non-null
- population_id is non-null

--------------------------------------------------------------------------------
3. Final decision integrity
--------------------------------------------------------------------------------

- decision_outcome is non-null
- decision_outcome IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
- decision_path is non-null
- decision_resolution_source is non-null
- exactly one of approval_flag, counteroffer_flag, manual_review_flag, decline_flag is TRUE per row

--------------------------------------------------------------------------------
4. Simulated offer-exposure flag integrity
--------------------------------------------------------------------------------

- simulated_offer_exposure_flag = TRUE only when decision_outcome IN ('APPROVE', 'COUNTEROFFER')
- simulated_offer_exposure_flag = FALSE when decision_outcome IN ('MANUAL_REVIEW', 'DECLINE')

--------------------------------------------------------------------------------
5. Amount / exposure integrity
--------------------------------------------------------------------------------

- approved_amount is not negative where populated
- approved_amount <= requested_amount where approved_amount is not null
- APPROVE rows have approved_amount = requested_amount
- COUNTEROFFER rows have approved_amount < requested_amount
- MANUAL_REVIEW rows have approved_amount IS NULL
- DECLINE rows have approved_amount = 0

--------------------------------------------------------------------------------
6. Expected Loss integrity
--------------------------------------------------------------------------------

- requested_expected_loss_amount is non-null
- approved_expected_loss_amount is non-negative where populated
- APPROVE rows have approved_expected_loss_amount = requested_expected_loss_amount
- COUNTEROFFER rows have approved_expected_loss_amount <= requested_expected_loss_amount
- MANUAL_REVIEW rows have approved_expected_loss_amount IS NULL
- DECLINE rows have approved_expected_loss_amount = 0

--------------------------------------------------------------------------------
7. Reason-code integrity
--------------------------------------------------------------------------------

- primary_reason_code is non-null
- primary_reason_family aligns to decision_outcome
- reason_code_count >= 1
- triggered_reason_code_list is non-null
- no reason code contains ADVERSE_ACTION
- no reason code contains REGULATORY
- no reason code contains CUSTOMER_NOTICE
- no reason code contains FAIR_LENDING

--------------------------------------------------------------------------------
8. Archive boundary
--------------------------------------------------------------------------------

- no strategy_decisions_archive insert occurs in Section 11
- archive persistence remains deferred to the next section

These are latest-run output gatekeepers only.

They are not the full Module 2 QA framework.

================================================================================
14. SECTION 11 INDEXES
================================================================================

Create practical indexes for latest-run QA and review.

Recommended indexes:

- application_id
- strategy_set_name, strategy_name, strategy_version
- module1_scenario_set_name, module1_scenario_name, population_id
- decision_outcome
- product_type_policy_key, decision_outcome
- score_band_policy_key, decision_outcome
- primary_reason_code
- simulated_offer_exposure_flag

These indexes support QA, reporting, and later archive comparison logic.

================================================================================
15. SECTION 11 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight latest-run diagnostics.

Suggested checks:

1. Latest-run row count and distinct application_id count
2. Count by decision_outcome
3. Count by decision_path
4. Count by primary_reason_code
5. Count by primary_reason_family
6. Product × decision_outcome
7. Score band × decision_outcome
8. Product × primary_reason_code
9. Score band × primary_reason_code
10. Strategy risk tier × decision_outcome
11. Requested PTI bucket × decision_outcome
12. Mixed-signal profile × decision_outcome
13. Borderline profile flag × decision_outcome
14. Average requested_amount vs approved_amount by decision_outcome
15. Average requested_payment_to_income_ratio vs approved_payment_to_income_ratio by decision_outcome
16. Average requested_expected_loss_amount vs approved_expected_loss_amount by decision_outcome
17. Simulated offer-exposure profile:
    - row count
    - total approved_amount
    - average estimated_pd
    - average approved_expected_loss_amount
    - grouped by simulated_offer_exposure_flag

These are latest-run output diagnostics.

They are still not the full Module 2 QA framework.

================================================================================
16. SECTION 11 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 11 comments should explain:

- why latest-run output is separated from staging tables
- why latest-run output is replaced each run
- why archive persistence is deferred
- why explicit output-field selection is used instead of SELECT *
- why requested_expected_loss_amount and approved_expected_loss_amount are both preserved
- why estimated_pd remains the synthetic estimated-PD proxy field
- why simulated_offer_exposure_flag does not imply booked exposure
- why reason codes are simulated strategy explanation codes
- why latest_output_created_ts is audit metadata, not deterministic comparison evidence
- why Section 11 is not the full QA framework
- why strategy archive persistence belongs in a later section

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.
No adverse-action reason-code language.

================================================================================
17. DELIVERABLE FOR THIS NEXT STEP
================================================================================

Please now provide:

1. Targeted Section 10 patches only:
   - counteroffer product-cap binding condition
   - POLICY_STOP_HIGH_REQUESTED_PTI candidate reason
   - requested Expected Loss reason-code label alignment
   - exact counteroffer failure label alignment
   - MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED candidate reason, if applicable

2. Section 11 SQL only:
   LATEST-RUN STRATEGY DECISION OUTPUT TABLE.

3. A short explanation of what Section 11 establishes.

4. A short explanation of what Section 11 intentionally does not build.

5. The recommended next build step after Section 11.

Do not write Section 12+ yet.
<!-- END_MESSAGE C038-M00142 -->


---

<a id="c038-m00145"></a>

### C038-M00145

**ChatGPT** · 2026-05-06T14:36:11.306237-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00145 -->
Section 10 remains accepted after the targeted patches below. The patches preserve the Module 2 boundary that reason codes are simulated strategy explanation codes only, not regulatory or customer-notice logic. Module 2 continues to consume Module 1 outputs as authoritative, including `estimated_pd` as the synthetic estimated-PD proxy and `requested_expected_loss_amount` as requested-exposure Expected Loss. fileciteturn4file0 The latest-run output design also preserves the deterministic, scenario-comparable lineage discipline validated in Module 1 V2.0. fileciteturn4file1

---

# 1. Targeted Section 10 patches only

## Patch 10.A — Counteroffer product-cap binding condition

Replace the product-cap binding condition inside the `COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT` candidate block.

### BEFORE

```sql
OR (
       counteroffer_product_cap_amount IS NOT NULL
   AND counteroffer_raw_max_feasible_amount IS NOT NULL
   AND counteroffer_product_cap_amount < counteroffer_raw_max_feasible_amount
)
```

### AFTER

```sql
OR (
       counteroffer_product_cap_amount IS NOT NULL
   AND counteroffer_raw_max_feasible_amount IS NOT NULL
   AND counteroffer_product_cap_amount = counteroffer_raw_max_feasible_amount
   AND requested_amount > product_max_approved_amount
)
```

This confirms that the requested amount exceeds the product approval cap and that the product cap is one of the binding reduced-exposure feasibility constraints.

---

## Patch 10.B — Add DECLINE reason for high requested PTI

Add this `UNION ALL` block after `POLICY_STOP_HIGH_DTI`.

```sql
UNION ALL

SELECT
    application_id,
    'POLICY_STOP_HIGH_REQUESTED_PTI',
    'POLICY_STOP',
    145,
    'requested_pti_decline_or_counteroffer_pti_failure_to_decline'
FROM reason_candidate_base
WHERE decision_outcome = 'DECLINE'
  AND (
        requested_pti_decline_trigger_flag IS TRUE
     OR (
            preliminary_decision_outcome = 'COUNTEROFFER'
        AND counteroffer_feasibility_pass_flag IS FALSE
        AND failed_counteroffer_resolution = 'DECLINE'
        AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
        )
  )
```

Also patch the `POLICY_STOP_RESIDUAL_DECLINE` fallback exclusion block to include this condition.

### BEFORE

```sql
OR dti_decline_trigger_flag IS TRUE
OR decision_path = 'SEVERE_DTI_CAPACITY'
OR (
       preliminary_decision_outcome = 'COUNTEROFFER'
   AND counteroffer_feasibility_pass_flag IS FALSE
   AND failed_counteroffer_resolution = 'DECLINE'
   )
OR requested_el_decline_trigger_flag IS TRUE
```

### AFTER

```sql
OR dti_decline_trigger_flag IS TRUE
OR decision_path = 'SEVERE_DTI_CAPACITY'
OR requested_pti_decline_trigger_flag IS TRUE
OR (
       preliminary_decision_outcome = 'COUNTEROFFER'
   AND counteroffer_feasibility_pass_flag IS FALSE
   AND failed_counteroffer_resolution = 'DECLINE'
   AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
   )
OR (
       preliminary_decision_outcome = 'COUNTEROFFER'
   AND counteroffer_feasibility_pass_flag IS FALSE
   AND failed_counteroffer_resolution = 'DECLINE'
   )
OR requested_el_decline_trigger_flag IS TRUE
```

---

## Patch 10.C — Requested Expected Loss reason-code label alignment

### BEFORE

```sql
SELECT
    application_id,
    'POLICY_STOP_EXPECTED_LOSS_UNRESOLVED',
    'POLICY_STOP',
    160,
    'requested_el_decline_trigger'
FROM reason_candidate_base
WHERE decision_outcome = 'DECLINE'
  AND requested_el_decline_trigger_flag IS TRUE
```

### AFTER

```sql
SELECT
    application_id,
    'POLICY_STOP_HIGH_REQUESTED_EXPECTED_LOSS',
    'POLICY_STOP',
    160,
    'requested_el_decline_trigger'
FROM reason_candidate_base
WHERE decision_outcome = 'DECLINE'
  AND requested_el_decline_trigger_flag IS TRUE
```

This keeps the reason label tied to requested-exposure Expected Loss rather than approved-exposure Expected Loss.

---

## Patch 10.D — Exact counteroffer failure label alignment

Using the current Section 8 label inventory, patch any Section 10 reference to the non-positive rounded amount failure.

### BEFORE

```sql
'COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE'
```

### AFTER

```sql
'COUNTEROFFER_ROUNDED_AMOUNT_NONPOSITIVE'
```

The affected block is the `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER` condition.

---

## Patch 10.E — Add specific manual-review reason for counteroffer not reduced

Add this `UNION ALL` block after `MANUAL_REVIEW_COUNTEROFFER_APPROVED_EL_ABOVE_CAP` and before `MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER`.

```sql
UNION ALL

SELECT
    application_id,
    'MANUAL_REVIEW_COUNTEROFFER_NOT_REDUCED',
    'MANUAL_REVIEW',
    312,
    'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'
FROM reason_candidate_base
WHERE decision_outcome = 'MANUAL_REVIEW'
  AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'
```

This separates “not reduced below requested amount” from below-minimum-offer failures.

---

# 2. Section 11 SQL only — Latest-Run Strategy Decision Output Table

```sql
/***************************************************************************************************
SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Materialize the current final Module 2 simulated strategy output for the selected Module 1 source
    scenario / population and the active Module 2 strategy.

    Section 11 answers:

        "What is the current final simulated strategy output for this selected synthetic population
         and active strategy?"

SQL PURPOSE:
    1. Consume tmp_m2_stage_7_reason_code_assignment.
    2. Create credit_decisioning_sim.strategy_decisions as the latest-run strategy output table.
    3. Use an explicit SELECT list so the permanent latest-run schema is governed and reviewable.
    4. Preserve Module 1 lineage, Module 2 strategy metadata, final decisions, final exposure
       economics, simulated reason codes, and key diagnostics.
    5. Create practical indexes for latest-run QA and review.
    6. Validate latest-run table integrity through local fail-fast gatekeepers.
    7. Keep archive persistence deferred to a later section.

WHY LATEST-RUN OUTPUT IS SEPARATED FROM STAGING TABLES:
    Temporary staging tables are designed to support implementation, debugging, and audit inspection.
    The latest-run table is the curated current output used for downstream QA, reporting, review, and
    future archive persistence.

WHY LATEST-RUN OUTPUT IS REPLACED EACH RUN:
    credit_decisioning_sim.strategy_decisions represents the current strategy run only.
    It should not preserve prior runs.

    Prior completed runs will be preserved later through:
        credit_decisioning_sim.strategy_decisions_archive

    This mirrors the Module 1 latest-output plus archive pattern.

ARCHIVE BOUNDARY:
    Section 11 does not create, reset, delete from, or insert into:
        credit_decisioning_sim.strategy_decisions_archive

    Archive replacement / rerun logic remains deferred to a later section.

WHY EXPLICIT FIELD SELECTION IS USED:
    The permanent latest-run output schema should be stable, governed, and reviewable.

    Temporary staging tables may carry many intermediate diagnostics. The final latest-run table should
    expose the fields needed for:
        downstream QA,
        archive persistence,
        reporting,
        review,
        documentation,
        and future validation.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Module 2 alias for Module 1 expected_loss_amount.
        This is requested-exposure Expected Loss.

    approved_expected_loss_amount:
        Module 2 final approved-exposure Expected Loss.

    Both are preserved because exposure treatment can change loss economics.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 11 and all downstream interpretation, estimated_pd means:
        synthetic estimated-PD proxy

    Module 2 does not recalculate estimated_pd.

SIMULATED OFFER EXPOSURE BOUNDARY:
    simulated_offer_exposure_flag = TRUE for APPROVE and COUNTEROFFER outcomes.

    It means:
        the simulated strategy output includes positive offer exposure for the synthetic applicant.

    It does not mean:
        operational account creation,
        funded exposure,
        production approval,
        or real customer treatment.

REASON-CODE BOUNDARY:
    primary_reason_code, secondary_reason_code, tertiary_reason_code, and triggered_reason_code_list
    are simulated strategy explanation codes.

    They support:
        transparency,
        QA review,
        strategy interpretation,
        portfolio diagnostics,
        and decision-path traceability.

    They are not regulatory or customer-notice reason codes.

LATEST_OUTPUT_CREATED_TS:
    latest_output_created_ts records when the latest-run table was materialized.

    It is audit metadata.
    It is not deterministic comparison evidence.

    Matched strategy comparison should exclude timestamp fields unless the test is specifically
    validating run metadata.

SECTION 11 IS NOT THE FULL QA FRAMEWORK:
    Section 11 includes local latest-run gatekeepers and lightweight diagnostics only.

    Full Module 2 QA, archive validation, and matched strategy comparison will be built later.

***************************************************************************************************/



/***************************************************************************************************
SECTION 11.1 — CLEAN RESET OF LATEST-RUN STRATEGY OUTPUT TABLE
****************************************************************************************************

This reset is limited to the latest-run output table.

It does not modify the strategy archive.

***************************************************************************************************/

DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 11.2 — CREATE LATEST-RUN STRATEGY DECISION OUTPUT TABLE
****************************************************************************************************

TABLE:
    credit_decisioning_sim.strategy_decisions

GRAIN:
    One row per application_id for the selected Module 1 source scenario / population and active
    Module 2 strategy.

INPUT:
    tmp_m2_stage_7_reason_code_assignment

OUTPUT:
    Curated final latest-run Module 2 strategy decision output.

***************************************************************************************************/

CREATE TABLE credit_decisioning_sim.strategy_decisions AS
SELECT
    /***********************************************************************************************
    1. MODULE 2 STRATEGY METADATA
    ***********************************************************************************************/
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,
    failed_counteroffer_resolution,
    module1_input_source,
    module1_source_table_name,


    /***********************************************************************************************
    2. MODULE 1 LINEAGE
    ***********************************************************************************************/
    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,


    /***********************************************************************************************
    3. APPLICATION LINEAGE
    ***********************************************************************************************/
    application_seq,
    application_id,
    applicant_id,
    application_date,


    /***********************************************************************************************
    4. PRODUCT AND SCORE SEGMENTATION
    ***********************************************************************************************/
    product_type,
    product_type_policy_key,
    score_band,
    score_band_policy_key,
    credit_score,
    product_score_policy_segment,


    /***********************************************************************************************
    5. BORROWER AND BEHAVIORAL PROFILE
    ***********************************************************************************************/
    annual_income,
    debt_to_income_ratio,
    utilization_rate,
    tradeline_count,
    months_since_oldest_trade,
    recent_inquiry_count,
    delinquency_count_12m,
    major_derogatory_flag,
    bankruptcy_flag,
    prequalified_flag,
    returning_customer_flag,


    /***********************************************************************************************
    6. REQUESTED STRUCTURE AND REQUESTED-EXPOSURE ECONOMICS

    estimated_pd:
        Finalized Module 1 SQL field name.
        Interpreted as the synthetic estimated-PD proxy.

    requested_expected_loss_amount:
        Module 2 alias for Module 1 requested-exposure Expected Loss.
    ***********************************************************************************************/
    requested_amount,
    loan_term_months,
    base_apr_for_payment_calc,
    requested_monthly_payment_proxy,
    requested_payment_to_income_ratio,
    amount_to_income_ratio,
    estimated_pd,
    estimated_lgd,
    requested_expected_loss_amount,


    /***********************************************************************************************
    7. STRATEGY SEGMENTATION DIAGNOSTICS
    ***********************************************************************************************/
    strategy_risk_tier,
    requested_pti_bucket,
    dti_bucket,
    requested_exposure_tier,
    requested_expected_loss_tier,
    mixed_signal_profile_type,
    mixed_signal_condition_count,
    borderline_profile_flag,


    /***********************************************************************************************
    8. RULE-TRIGGER DIAGNOSTICS

    These are diagnostic trigger fields, not final reason codes.
    They support audit review and reason-code traceability.
    ***********************************************************************************************/

    /* Hard simulated policy stop diagnostics */
    bankruptcy_policy_stop_flag,
    major_derogatory_policy_stop_flag,
    severe_delinquency_policy_stop_flag,
    hard_policy_stop_flag,
    hard_policy_stop_count,

    /* Synthetic estimated-risk trigger diagnostics */
    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag,
    synthetic_risk_trigger_count,
    synthetic_risk_band_flag_count,

    /* Requested affordability trigger diagnostics */
    requested_pti_clean_band_flag,
    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag,
    affordability_trigger_count,

    /* DTI capacity trigger diagnostics */
    dti_clean_band_flag,
    dti_review_trigger_flag,
    dti_decline_trigger_flag,
    dti_trigger_count,
    dti_band_flag_count,

    /* Requested Expected Loss trigger diagnostics */
    requested_el_clean_band_flag,
    requested_el_counteroffer_candidate_flag,
    requested_el_review_trigger_flag,
    requested_el_decline_trigger_flag,
    requested_el_trigger_count,

    /* Requested exposure trigger diagnostics */
    requested_exposure_below_product_minimum_flag,
    requested_exposure_within_product_limit_flag,
    requested_exposure_above_product_cap_flag,
    requested_exposure_extreme_flag,
    exposure_counteroffer_candidate_flag,
    exposure_policy_stop_candidate_flag,
    exposure_trigger_count,

    /* Counteroffer candidate diagnostics */
    counteroffer_allowed_by_product_flag,
    counteroffer_risk_band_eligible_flag,
    counteroffer_affordability_candidate_flag,
    counteroffer_exposure_candidate_flag,
    counteroffer_expected_loss_candidate_flag,
    counteroffer_candidate_flag,
    counteroffer_candidate_trigger_count,

    /* Manual-review candidate diagnostics */
    manual_review_allowed_by_product_flag,
    manual_review_risk_trigger_flag,
    manual_review_affordability_trigger_flag,
    manual_review_dti_trigger_flag,
    manual_review_expected_loss_trigger_flag,
    manual_review_mixed_signal_trigger_flag,
    manual_review_borderline_trigger_flag,
    manual_review_candidate_flag,
    manual_review_candidate_trigger_count,

    /* Supplemental behavioral review diagnostics */
    high_utilization_review_trigger_flag,
    low_score_review_trigger_flag,
    supplemental_behavioral_review_trigger_flag,
    supplemental_behavioral_review_trigger_count,

    /* Clean candidate and aggregate trigger burden */
    clean_approval_candidate_flag,
    total_rule_trigger_count,


    /***********************************************************************************************
    9. PRELIMINARY ROUTING DIAGNOSTICS
    ***********************************************************************************************/
    preliminary_decision_outcome,
    preliminary_decision_path,
    preliminary_decision_priority_rank,
    preliminary_route_reason_family,
    preliminary_route_trigger_count,
    severe_requested_structure_trigger_flag,
    severe_requested_structure_trigger_count,
    requires_counteroffer_feasibility_flag,
    requires_approved_exposure_calculation_flag,


    /***********************************************************************************************
    10. EXPOSURE TREATMENT AND COUNTEROFFER DIAGNOSTICS
    ***********************************************************************************************/
    exposure_treatment_status,
    exposure_treatment_path,

    counteroffer_feasibility_evaluated_flag,
    counteroffer_feasibility_pass_flag,
    counteroffer_feasibility_failure_reason,
    counteroffer_feasibility_constraint_count,

    counteroffer_product_cap_amount,
    counteroffer_pti_target_amount,
    counteroffer_el_cap_amount,
    counteroffer_raw_max_feasible_amount,
    counteroffer_min_viable_amount,
    counteroffer_rounded_amount,


    /***********************************************************************************************
    11. FINAL DECISION OUTCOME FIELDS
    ***********************************************************************************************/
    decision_outcome,
    decision_path,
    decision_priority_rank,
    decision_resolution_source,


    /***********************************************************************************************
    12. FINAL DECISION FLAGS
    ***********************************************************************************************/
    approval_flag,
    counteroffer_flag,
    manual_review_flag,
    decline_flag,
    simulated_offer_exposure_flag,


    /***********************************************************************************************
    13. FINAL APPROVED EXPOSURE AND ECONOMICS

    approved_expected_loss_amount:
        Final Module 2 approved-exposure Expected Loss.

    It is distinct from requested_expected_loss_amount.
    ***********************************************************************************************/
    approved_amount,
    counteroffer_amount,
    exposure_reduction_flag,
    exposure_reduction_amount,
    exposure_reduction_pct,

    approved_monthly_payment_proxy,
    approved_payment_to_income_ratio,

    approved_expected_loss_amount,
    approved_el_reduction_amount,
    approved_el_reduction_pct,


    /***********************************************************************************************
    14. SIMULATED REASON-CODE FIELDS

    These are simulated strategy explanation codes used for audit and QA review.
    ***********************************************************************************************/
    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    primary_reason_family,
    triggered_reason_code_list,
    reason_priority_rank,
    reason_code_count,


    /***********************************************************************************************
    15. LATEST-RUN AUDIT TIMESTAMP

    Audit metadata only.
    Not deterministic comparison evidence.
    ***********************************************************************************************/
    CURRENT_TIMESTAMP AS latest_output_created_ts

FROM tmp_m2_stage_7_reason_code_assignment;



/***************************************************************************************************
SECTION 11.3 — LATEST-RUN INDEXES
****************************************************************************************************

PURPOSE:
    Add practical indexes for latest-run QA, reporting, review, and later archive preparation.

These indexes support common review paths:
    application lookup
    strategy identity filtering
    Module 1 lineage filtering
    decision outcome summaries
    product / score outcome summaries
    reason-code diagnostics
    simulated offer-exposure summaries

***************************************************************************************************/

CREATE UNIQUE INDEX idx_m2_strategy_decisions_application_id
    ON credit_decisioning_sim.strategy_decisions (application_id);

CREATE INDEX idx_m2_strategy_decisions_strategy_identity
    ON credit_decisioning_sim.strategy_decisions (
        strategy_set_name,
        strategy_name,
        strategy_version
    );

CREATE INDEX idx_m2_strategy_decisions_module1_lineage
    ON credit_decisioning_sim.strategy_decisions (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

CREATE INDEX idx_m2_strategy_decisions_decision_outcome
    ON credit_decisioning_sim.strategy_decisions (decision_outcome);

CREATE INDEX idx_m2_strategy_decisions_product_decision
    ON credit_decisioning_sim.strategy_decisions (
        product_type_policy_key,
        decision_outcome
    );

CREATE INDEX idx_m2_strategy_decisions_score_decision
    ON credit_decisioning_sim.strategy_decisions (
        score_band_policy_key,
        decision_outcome
    );

CREATE INDEX idx_m2_strategy_decisions_primary_reason
    ON credit_decisioning_sim.strategy_decisions (primary_reason_code);

CREATE INDEX idx_m2_strategy_decisions_offer_exposure
    ON credit_decisioning_sim.strategy_decisions (simulated_offer_exposure_flag);



/***************************************************************************************************
SECTION 11.4 — LOCAL FAIL-FAST CHECKS FOR LATEST-RUN OUTPUT
****************************************************************************************************

PURPOSE:
    Validate the permanent latest-run strategy output before archive persistence or full QA is built.

IMPORTANT:
    These are latest-run output gatekeepers only.

    They are not:
        the full Module 2 QA framework,
        archive validation,
        matched strategy comparison,
        or documentation evidence.

***************************************************************************************************/

DO $$
DECLARE
    v_stage7_count BIGINT;
    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;

    v_duplicate_application_count BIGINT;
    v_metadata_lineage_failure_count BIGINT;
    v_decision_integrity_failure_count BIGINT;
    v_offer_flag_failure_count BIGINT;
    v_amount_integrity_failure_count BIGINT;
    v_el_integrity_failure_count BIGINT;
    v_reason_integrity_failure_count BIGINT;
    v_latest_ts_failure_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run table must exist.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: credit_decisioning_sim.strategy_decisions was not created.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must match Section 10 reason-code staging.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage7_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    SELECT COUNT(*)
    INTO v_latest_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count <> v_stage7_count THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: latest-run row count does not match Section 10 staging. Stage 7 rows: %, latest rows: %.',
            v_stage7_count,
            v_latest_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_distinct_app_count <> v_latest_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM credit_decisioning_sim.strategy_decisions
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 11 failure: application_id uniqueness was not preserved. Latest rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_latest_count,
            v_latest_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest output timestamp must be populated.

    latest_output_created_ts is audit metadata only.
    It should not be used as deterministic comparison evidence.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_ts_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE latest_output_created_ts IS NULL;

    IF v_latest_ts_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have null latest_output_created_ts.',
            v_latest_ts_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: strategy metadata and Module 1 lineage must be populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_metadata_lineage_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE NULLIF(BTRIM(strategy_set_name), '') IS NULL
       OR NULLIF(BTRIM(strategy_name), '') IS NULL
       OR NULLIF(BTRIM(strategy_version), '') IS NULL
       OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
       OR strategy_run_ts IS NULL
       OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
       OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
       OR NULLIF(BTRIM(population_id), '') IS NULL
       OR NULLIF(BTRIM(module2_model_version), '') IS NULL
       OR NULLIF(BTRIM(module1_model_version), '') IS NULL;

    IF v_metadata_lineage_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have missing strategy metadata or Module 1 lineage fields.',
            v_metadata_lineage_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final decision fields and final flags must be complete and reconciled.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decision_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL
       OR decision_priority_rank IS NULL
       OR decision_priority_rank <= 0
       OR (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
          ) <> 1
       OR approval_flag IS DISTINCT FROM (decision_outcome = 'APPROVE')
       OR counteroffer_flag IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
       OR manual_review_flag IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
       OR decline_flag IS DISTINCT FROM (decision_outcome = 'DECLINE');

    IF v_decision_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have final decision or flag integrity failures.',
            v_decision_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated_offer_exposure_flag must reconcile to final decision_outcome.

    TRUE:
        APPROVE, COUNTEROFFER

    FALSE:
        MANUAL_REVIEW, DECLINE
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_offer_flag_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE simulated_offer_exposure_flag
          IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'));

    IF v_offer_flag_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have simulated_offer_exposure_flag reconciliation failures.',
            v_offer_flag_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final amount and exposure conventions.

    approved_amount must never exceed requested_amount in Module 2 v1.0.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_amount_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE (approved_amount IS NOT NULL AND approved_amount < 0)
       OR (approved_amount IS NOT NULL AND approved_amount > requested_amount)

       OR (
            decision_outcome = 'APPROVE'
            AND (
                approved_amount IS DISTINCT FROM requested_amount
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_flag IS DISTINCT FROM FALSE
             OR exposure_reduction_amount IS DISTINCT FROM 0::NUMERIC
             OR exposure_reduction_pct IS DISTINCT FROM 0::NUMERIC
            )
       )

       OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
             OR exposure_reduction_flag IS DISTINCT FROM TRUE
             OR exposure_reduction_amount IS DISTINCT FROM (requested_amount - approved_amount)
             OR exposure_reduction_pct IS DISTINCT FROM (
                    exposure_reduction_amount / NULLIF(requested_amount, 0)
                )
            )
       )

       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND (
                approved_amount IS NOT NULL
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_flag IS DISTINCT FROM FALSE
             OR exposure_reduction_amount IS NOT NULL
             OR exposure_reduction_pct IS NOT NULL
            )
       )

       OR (
            decision_outcome = 'DECLINE'
            AND (
                approved_amount IS DISTINCT FROM 0::NUMERIC
             OR counteroffer_amount IS NOT NULL
             OR exposure_reduction_flag IS DISTINCT FROM FALSE
             OR exposure_reduction_amount IS DISTINCT FROM requested_amount
             OR exposure_reduction_pct IS DISTINCT FROM 1.0::NUMERIC
            )
       );

    IF v_amount_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have amount or exposure convention failures.',
            v_amount_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: requested and approved Expected Loss conventions.

    requested_expected_loss_amount is requested-exposure Expected Loss.
    approved_expected_loss_amount is approved-exposure Expected Loss.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_el_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE requested_expected_loss_amount IS NULL
       OR requested_expected_loss_amount < 0
       OR (approved_expected_loss_amount IS NOT NULL AND approved_expected_loss_amount < 0)

       OR (
            decision_outcome = 'APPROVE'
            AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
       )

       OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount > requested_expected_loss_amount
            )
       )

       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND approved_expected_loss_amount IS NOT NULL
       )

       OR (
            decision_outcome = 'DECLINE'
            AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
       );

    IF v_el_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have requested / approved Expected Loss convention failures.',
            v_el_integrity_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: simulated reason-code integrity.

    Reason codes are simulated strategy explanation codes only.

    This check prevents forbidden terminology from appearing in reason-code values.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_reason_integrity_failure_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE primary_reason_code IS NULL
       OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
       OR primary_reason_family IS NULL
       OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
       OR reason_code_count IS NULL
       OR reason_code_count < 1
       OR triggered_reason_code_list IS NULL
       OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL

       OR (
            decision_outcome = 'APPROVE'
            AND NOT (
                primary_reason_code = 'APPROVED_AS_REQUESTED'
                AND primary_reason_family = 'APPROVAL'
            )
       )

       OR (
            decision_outcome = 'COUNTEROFFER'
            AND NOT (
                primary_reason_family = 'COUNTEROFFER'
                AND primary_reason_code LIKE 'COUNTEROFFER_%'
            )
       )

       OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND NOT (
                primary_reason_family = 'MANUAL_REVIEW'
                AND primary_reason_code LIKE 'MANUAL_REVIEW_%'
            )
       )

       OR (
            decision_outcome = 'DECLINE'
            AND NOT (
                primary_reason_family = 'POLICY_STOP'
                AND primary_reason_code LIKE 'POLICY_STOP_%'
            )
       )

       OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%ADVERSE_ACTION%'
       OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%ADVERSE_ACTION%'
       OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%ADVERSE_ACTION%'
       OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%ADVERSE_ACTION%'

       OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%REGULATORY%'
       OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%REGULATORY%'
       OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%REGULATORY%'
       OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%REGULATORY%'

       OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%CUSTOMER_NOTICE%'
       OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%CUSTOMER_NOTICE%'
       OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%CUSTOMER_NOTICE%'
       OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%CUSTOMER_NOTICE%'

       OR UPPER(COALESCE(primary_reason_code, '')) LIKE '%FAIR_LENDING%'
       OR UPPER(COALESCE(secondary_reason_code, '')) LIKE '%FAIR_LENDING%'
       OR UPPER(COALESCE(tertiary_reason_code, '')) LIKE '%FAIR_LENDING%'
       OR UPPER(COALESCE(triggered_reason_code_list, '')) LIKE '%FAIR_LENDING%';

    IF v_reason_integrity_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 11 failure: % row(s) have simulated reason-code integrity failures.',
            v_reason_integrity_failure_count;
    END IF;

    /*
    Archive boundary:
        Section 11 does not execute any DML against
        credit_decisioning_sim.strategy_decisions_archive.

        Archive persistence remains deferred to Section 12.
    */
END $$;



/***************************************************************************************************
SECTION 11.5 — LOCAL LATEST-RUN SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the latest-run strategy output table.

IMPORTANT:
    These are latest-run output diagnostics only.

    They are not:
        the full Module 2 QA framework,
        archive validation,
        matched strategy comparison,
        or documentation evidence.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
11.5.1 Latest-run row count and application identity count.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS latest_run_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
11.5.2 Count by final decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_latest_run
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY
    CASE decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
11.5.3 Count by final decision_path.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_path,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_latest_run
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_path
ORDER BY decision_path;


/*-----------------------------------------------------------------------------------------------
11.5.4 Count by primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    primary_reason_code,
    primary_reason_family,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_latest_run
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    primary_reason_code,
    primary_reason_family
ORDER BY
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
11.5.5 Count by primary_reason_family.
-----------------------------------------------------------------------------------------------*/
SELECT
    primary_reason_family,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_latest_run
FROM credit_decisioning_sim.strategy_decisions
GROUP BY primary_reason_family
ORDER BY primary_reason_family;


/*-----------------------------------------------------------------------------------------------
11.5.6 Product × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    product_type_policy_key,
    decision_outcome
ORDER BY
    product_type_policy_key,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.7 Score band × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    score_band_policy_key,
    decision_outcome
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.8 Product × primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    primary_reason_code,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    product_type_policy_key,
    primary_reason_code
ORDER BY
    product_type_policy_key,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
11.5.9 Score band × primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    primary_reason_code,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    score_band_policy_key,
    primary_reason_code
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
11.5.10 Strategy risk tier × decision_outcome.

estimated_pd is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    strategy_risk_tier,
    decision_outcome
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.11 Requested PTI bucket × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    requested_pti_bucket,
    decision_outcome
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.12 Mixed-signal profile × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    mixed_signal_profile_type,
    decision_outcome
ORDER BY
    CASE mixed_signal_profile_type
        WHEN 'NO_MIXED_SIGNAL_PROFILE' THEN 1
        WHEN 'STRONG_CREDIT_HIGH_PTI' THEN 2
        WHEN 'WEAK_CREDIT_LOW_PTI' THEN 3
        WHEN 'LARGE_EXPOSURE_LOW_RISK' THEN 4
        WHEN 'HIGH_RISK_LOW_EXPOSURE' THEN 5
        WHEN 'HIGH_DTI_LOW_REQUESTED_PTI' THEN 6
        WHEN 'MULTIPLE_MIXED_SIGNALS' THEN 7
        ELSE 99
    END,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.13 Borderline profile flag × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM credit_decisioning_sim.strategy_decisions
GROUP BY
    borderline_profile_flag,
    decision_outcome
ORDER BY
    borderline_profile_flag,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.14 Average requested_amount versus approved_amount by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount,
    MIN(requested_amount) AS min_requested_amount,
    MAX(requested_amount) AS max_requested_amount,
    MIN(approved_amount) AS min_approved_amount,
    MAX(approved_amount) AS max_approved_amount
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.15 Average requested PTI versus approved PTI by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.16 Average requested Expected Loss versus approved Expected Loss by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount,
    AVG(approved_el_reduction_amount) AS avg_approved_el_reduction_amount,
    AVG(approved_el_reduction_pct) AS avg_approved_el_reduction_pct
FROM credit_decisioning_sim.strategy_decisions
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
11.5.17 Simulated offer-exposure profile.

Interpretation:
    simulated_offer_exposure_flag = TRUE means APPROVE or COUNTEROFFER simulated positive
    offer exposure.

    It does not imply operational account creation or real customer treatment.
-----------------------------------------------------------------------------------------------*/
SELECT
    simulated_offer_exposure_flag,
    COUNT(*) AS row_count,
    SUM(approved_amount) AS total_approved_amount,
    AVG(approved_amount) AS avg_approved_amount,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    SUM(approved_expected_loss_amount) AS total_approved_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM credit_decisioning_sim.strategy_decisions
GROUP BY simulated_offer_exposure_flag
ORDER BY simulated_offer_exposure_flag;


/***************************************************************************************************
END OF SECTION 11 — LATEST-RUN STRATEGY DECISION OUTPUT TABLE

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions exists.
    2. The latest-run output has one row per application_id.
    3. Module 1 lineage is preserved.
    4. Module 2 strategy metadata is preserved.
    5. Final decision outcomes and final flags are populated.
    6. simulated_offer_exposure_flag reconciles to APPROVE and COUNTEROFFER.
    7. requested_expected_loss_amount and approved_expected_loss_amount are both preserved.
    8. estimated_pd remains preserved as the Module 1 SQL field and is interpreted as the
       synthetic estimated-PD proxy.
    9. Simulated strategy explanation codes are populated.
    10. Latest-run indexes have been created.
    11. Latest-run local gatekeepers have passed.

No strategy archive rows have been inserted.
No archive replacement / rerun logic has been executed.
No matched strategy comparison queries have been created.
No full Module 2 QA framework has been created.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

---

# 3. What Section 11 establishes

Section 11 creates the permanent latest-run output table:

```text
credit_decisioning_sim.strategy_decisions
```

It materializes the current final simulated strategy output for the selected Module 1 scenario / population and the active Module 2 strategy. It preserves lineage, decisions, final exposure economics, reason-code fields, diagnostics, and audit metadata with an explicit governed output schema.

---

# 4. What Section 11 intentionally does not build

Section 11 does not insert archive rows, perform archive replacement / rerun logic, build matched strategy comparison queries, build the full QA framework, or draft BRD / Validation Summary documentation.

Archive persistence remains separate by design.

---

# 5. Recommended next build step

Next should be:

```text
Section 12 — Strategy Decision Archive Persistence Layer
```

That section should create or reuse:

```text
credit_decisioning_sim.strategy_decisions_archive
```

and implement the locked archive replacement / rerun key:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
```

with row-level archive grain additionally including:

```text
application_id
```
<!-- END_MESSAGE C038-M00145 -->


---

<a id="c038-m00147"></a>

### C038-M00147

**Andrew** · 2026-05-06T14:59:41.662000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00147 -->
This is strong. I agree with the Section 10 targeted patches and the Section 11 Latest-Run Strategy Decision Output Table.

Section 11 correctly:
- consumes tmp_m2_stage_7_reason_code_assignment
- creates credit_decisioning_sim.strategy_decisions
- uses an explicit SELECT list instead of SELECT *
- preserves Module 2 strategy metadata
- preserves Module 1 lineage
- preserves application lineage
- preserves borrower, product, requested-structure, affordability, estimated-risk, LGD, and requested Expected Loss fields
- preserves strategy segmentation diagnostics
- preserves rule-trigger diagnostics
- preserves preliminary routing diagnostics
- preserves exposure treatment and counteroffer feasibility diagnostics
- creates final decision outcome fields
- creates final decision flags
- creates final approved exposure and approved economics fields
- creates simulated reason-code fields
- adds latest_output_created_ts as audit metadata
- creates practical indexes
- includes latest-run local gatekeepers and sanity checks
- does not insert archive rows
- does not build matched strategy comparison
- does not build the full Module 2 QA framework

Treat Section 11 as accepted, subject to the targeted patches below.

Do not rewrite Sections 0–11 in full unless necessary.

================================================================================
1. TARGETED SECTION 11 PATCH — ADD ARCHIVE CONTROL FIELDS TO LATEST-RUN OUTPUT
================================================================================

Please add the following fields to credit_decisioning_sim.strategy_decisions:

- archive_run_flag
- strategy_archive_reset_mode

Recommended placement:
Add them within the Module 2 strategy metadata field family, near:

- module2_model_version
- strategy_set_name
- strategy_name
- strategy_version
- strategy_run_id
- strategy_run_ts
- failed_counteroffer_resolution
- module1_input_source
- module1_source_table_name

Reason:
These fields are strategy-run controls. Including them in the latest-run output improves audit traceability and makes Section 12 archive persistence easier to validate.

Interpretation:
- archive_run_flag indicates whether the active strategy run is intended to be archived
- strategy_archive_reset_mode indicates how archive replacement / cleanup should be handled
- neither field is part of the row-level application grain
- neither field replaces the locked archive replacement / rerun key

Please also add a local gatekeeper to Section 11 confirming:
- archive_run_flag is not null
- strategy_archive_reset_mode is non-null and one of:
  - NONE
  - STRATEGY_SCENARIO_ONLY
  - STRATEGY_SET_ONLY
  - ALL

================================================================================
2. TARGETED SECTION 11 PATCH — EXACTLY ONE FINAL FLAG CHECK
================================================================================

Please tighten the final decision-flag gatekeeper.

Current logic appears to fail when the sum of final flags is greater than 1.

Please revise the count test so it fails whenever the sum of final decision flags is not exactly 1.

Required logic:

Exactly one of the following must be TRUE for every row:
- approval_flag
- counteroffer_flag
- manual_review_flag
- decline_flag

Recommended condition:

COALESCE(approval_flag::INT, 0)
+ COALESCE(counteroffer_flag::INT, 0)
+ COALESCE(manual_review_flag::INT, 0)
+ COALESCE(decline_flag::INT, 0) <> 1

Reason:
The locked taxonomy requires exactly one final simulated strategy outcome per row. The existing outcome-specific reconciliation is helpful, but the direct flag-count test should explicitly enforce exactly one final flag.

================================================================================
3. SECTION 11 ACCEPTANCE CRITERIA
================================================================================

After the two targeted patches, treat Section 11 as accepted if:

- credit_decisioning_sim.strategy_decisions exists
- row count matches tmp_m2_stage_7_reason_code_assignment
- application_id remains unique
- Module 2 strategy metadata is populated
- archive_run_flag and strategy_archive_reset_mode are populated
- Module 1 lineage is populated
- final decision_outcome is populated
- final decision flags reconcile to decision_outcome
- exactly one final decision flag is TRUE per row
- simulated_offer_exposure_flag is TRUE only for APPROVE and COUNTEROFFER
- simulated_offer_exposure_flag is FALSE for MANUAL_REVIEW and DECLINE
- approved_amount conventions hold by decision_outcome
- approved_expected_loss_amount conventions hold by decision_outcome
- primary_reason_code is populated for every row
- primary_reason_family aligns to decision_outcome
- no prohibited reason-code language appears
- latest_output_created_ts is populated
- no archive rows are inserted
- no matched strategy comparison logic is created
- no full QA framework is created

================================================================================
4. NEXT BUILD SCOPE: SECTION 12 ONLY
================================================================================

After the targeted Section 11 patches, please build only:

SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER

Archive table:

credit_decisioning_sim.strategy_decisions_archive

Section 12 should consume:

credit_decisioning_sim.strategy_decisions

Do not build:
- matched strategy comparison queries
- full Module 2 QA framework
- BRD documentation
- Validation Summary documentation
- dashboard or reporting artifacts

Those belong to later sections.

================================================================================
5. SECTION 12 OBJECTIVE
================================================================================

Section 12 should persist completed latest-run strategy outputs into a governed archive table.

Section 12 should answer:

“Should this completed Module 2 strategy run be archived, and if so, how should existing archive rows be handled before inserting the current latest-run output?”

Section 12 should not answer:

“How do two archived strategies compare?”

Matched strategy comparison belongs to a later section.

Important:
Section 12 must not recalculate:
- decision_outcome
- approved exposure
- approved Expected Loss
- reason codes
- any strategy result

It should persist the already-materialized latest-run output.

================================================================================
6. ARCHIVE GRAIN AND REPLACEMENT KEY
================================================================================

Preserve the locked archive grain:

one row per application × Module 1 scenario × Module 2 strategy version

Archive grain fields:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

Archive replacement / rerun key:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

The row-level archive grain additionally includes:
- application_id

Do not use strategy_run_id, strategy_run_ts, latest_output_created_ts, or archive_inserted_ts as the archive replacement key.

Interpretation:
- strategy_run_id and strategy_run_ts are audit metadata
- latest_output_created_ts is latest-output materialization metadata
- archive_inserted_ts is archive persistence metadata
- none of these should define matched strategy comparison grain

================================================================================
7. ARCHIVE TABLE DESIGN
================================================================================

Create the archive table if it does not already exist.

Recommended structure:
- all fields from credit_decisioning_sim.strategy_decisions
- plus archive_inserted_ts

Suggested archive timestamp field:
- archive_inserted_ts

Interpretation:
- latest_output_created_ts identifies when the latest-run output table was materialized
- archive_inserted_ts identifies when that latest-run output was persisted to archive
- neither timestamp should be used as the archive replacement / rerun key
- deterministic strategy comparison should exclude timestamp fields unless specifically validating run metadata

Recommended implementation:
Use:

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_decisions_archive
(LIKE credit_decisioning_sim.strategy_decisions INCLUDING DEFAULTS);

Then:

ALTER TABLE credit_decisioning_sim.strategy_decisions_archive
ADD COLUMN IF NOT EXISTS archive_inserted_ts TIMESTAMP;

Important development note:
If the latest-run output schema changes later, the archive table may need to be altered or recreated so the archive schema remains aligned with credit_decisioning_sim.strategy_decisions.

For V1.0 Module 2 development, Section 12 should include a schema-alignment commentary note and practical gatekeepers, but it does not need to build a fully dynamic schema migration system.

================================================================================
8. ARCHIVE CONTROL LOGIC
================================================================================

Section 12 should read archive controls from the latest-run output:

- archive_run_flag
- strategy_archive_reset_mode

Allowed strategy_archive_reset_mode values:
- NONE
- STRATEGY_SCENARIO_ONLY
- STRATEGY_SET_ONLY
- ALL

Before applying archive behavior, Section 12 should confirm that the latest-run table contains exactly one archive-control configuration:

- one archive_run_flag value
- one strategy_archive_reset_mode value
- one archive replacement / rerun key

This prevents a mixed latest-run output from creating ambiguous archive behavior.

Recommended behavior:

--------------------------------------------------------------------------------
1. archive_run_flag = FALSE
--------------------------------------------------------------------------------

- Do not insert archive rows.
- Do not delete archive rows.
- Leave existing archive untouched.
- Emit a lightweight diagnostic showing that archive persistence was skipped.

Reason:
Users may want to run development or smoke-test strategies without preserving them in the archive.

--------------------------------------------------------------------------------
2. archive_run_flag = TRUE and strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY
--------------------------------------------------------------------------------

Before inserting current latest-run rows, delete existing archive rows matching the full archive replacement / rerun key:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

Then insert one archive row per application_id from credit_decisioning_sim.strategy_decisions.

This should be the ordinary rerun behavior.

Reason:
It replaces only the current strategy run for the selected Module 1 scenario and population without disturbing other strategies, strategy versions, scenarios, or populations.

--------------------------------------------------------------------------------
3. archive_run_flag = TRUE and strategy_archive_reset_mode = STRATEGY_SET_ONLY
--------------------------------------------------------------------------------

Before inserting current latest-run rows, delete existing archive rows matching:

- strategy_set_name
- module1_scenario_set_name
- module1_scenario_name
- population_id

This clears all strategy_name / strategy_version outputs within the same strategy set for the selected Module 1 scenario and population.

Do not delete unrelated Module 1 scenarios or unrelated populations.

Reason:
This mode supports restarting a strategy comparison family while preserving unrelated analysis families.

--------------------------------------------------------------------------------
4. archive_run_flag = TRUE and strategy_archive_reset_mode = ALL
--------------------------------------------------------------------------------

Delete all rows from credit_decisioning_sim.strategy_decisions_archive before inserting current latest-run rows.

Commentary should clearly state that ALL is a broad reset option and should be used intentionally.

Reason:
This is a complete archive reset, not an ordinary rerun mode.

--------------------------------------------------------------------------------
5. archive_run_flag = TRUE and strategy_archive_reset_mode = NONE
--------------------------------------------------------------------------------

Do not delete existing archive rows before insert.

However, Section 12 should fail if rows already exist for the current archive replacement / rerun key.

Reason:
NONE means “append only if this is a new archived strategy slice.”
It should not silently duplicate an existing strategy / scenario / population run.

================================================================================
9. ARCHIVE INSERT LOGIC
================================================================================

When archive_run_flag = TRUE, insert all rows from:

credit_decisioning_sim.strategy_decisions

into:

credit_decisioning_sim.strategy_decisions_archive

Add:

CURRENT_TIMESTAMP AS archive_inserted_ts

Recommended implementation principle:
Use an explicit insert column list where practical.

Reason:
An explicit column list makes archive persistence auditable and protects against silent schema-order issues.

If the SQL uses a simplified insert pattern because the archive table was created with LIKE, the commentary should still explain the schema dependency.

================================================================================
10. ARCHIVE INDEXES
================================================================================

Create practical indexes for archive inventory, scenario / strategy comparison, and row-level matching.

Recommended indexes:

1. Current archive replacement / rerun key:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

2. Row-level archive grain:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

3. Module 1 scenario lineage:
- module1_scenario_set_name
- module1_scenario_name
- population_id

4. Strategy comparison:
- strategy_set_name
- strategy_name
- strategy_version

5. Reporting indexes:
- decision_outcome
- primary_reason_code
- product_type_policy_key
- score_band_policy_key
- simulated_offer_exposure_flag

Recommended uniqueness control:
If feasible, create a unique index on the full archive row-level grain:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

Reason:
The archive should not contain duplicate rows for the same application under the same Module 1 scenario and Module 2 strategy version.

If a unique index is not used, Section 12 gatekeepers must still enforce no duplicates after insert.

================================================================================
11. SECTION 12 LOCAL GATEKEEPERS
================================================================================

At the end of Section 12, include local fail-fast checks.

Validate:

--------------------------------------------------------------------------------
1. Latest-run source integrity
--------------------------------------------------------------------------------

- credit_decisioning_sim.strategy_decisions exists
- latest-run table row count > 0
- application_id is unique in latest-run table
- archive_run_flag is non-null for every latest-run row
- strategy_archive_reset_mode is non-null for every latest-run row
- exactly one archive_run_flag value exists in the latest-run table
- exactly one strategy_archive_reset_mode value exists in the latest-run table
- exactly one archive replacement / rerun key exists in the latest-run table

--------------------------------------------------------------------------------
2. Archive table existence
--------------------------------------------------------------------------------

- credit_decisioning_sim.strategy_decisions_archive exists after Section 12 setup
- archive_inserted_ts column exists

--------------------------------------------------------------------------------
3. Archive skip behavior
--------------------------------------------------------------------------------

If archive_run_flag = FALSE:
- no archive delete should occur
- no archive insert should occur
- existing archive row count should remain unchanged

If direct pre/post row-count validation is too complex inside the SQL, provide a diagnostic query confirming archive_run_flag = FALSE and that Section 12 skipped persistence.

--------------------------------------------------------------------------------
4. Archive insert behavior
--------------------------------------------------------------------------------

If archive_run_flag = TRUE:
- current archived slice row count equals latest-run row count after insert
- current archived slice distinct application_id count equals latest-run distinct application_id count
- archive_inserted_ts is non-null for all current archived slice rows
- no duplicate application_id exists within the current archived slice

Current archived slice means rows matching:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

--------------------------------------------------------------------------------
5. Archive mode behavior
--------------------------------------------------------------------------------

If strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY:
- the current replacement key should contain exactly one archived row per latest-run application_id after insert

If strategy_archive_reset_mode = STRATEGY_SET_ONLY:
- prior rows for the selected strategy_set_name + Module 1 scenario + population should be removed before inserting current rows
- unrelated strategy_set_name values should remain untouched
- unrelated Module 1 scenarios should remain untouched
- unrelated population_id values should remain untouched

If strategy_archive_reset_mode = ALL:
- archive should contain only post-reset rows inserted after the ALL reset, unless additional rows are inserted later in the same session

If strategy_archive_reset_mode = NONE:
- Section 12 should fail before insert if the current replacement key already exists
- if no existing replacement key exists, insert should proceed normally

--------------------------------------------------------------------------------
6. Archive grain integrity
--------------------------------------------------------------------------------

Validate no duplicate rows exist at the archive row-level grain:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

--------------------------------------------------------------------------------
7. Boundary checks
--------------------------------------------------------------------------------

Validate or explicitly confirm:
- Section 12 does not recalculate decision_outcome
- Section 12 does not recalculate approved_amount
- Section 12 does not recalculate approved_expected_loss_amount
- Section 12 does not reassign reason codes
- Section 12 does not build matched strategy comparison queries
- Section 12 does not build the full QA framework

These are archive-persistence gatekeepers only.

================================================================================
12. SECTION 12 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight archive diagnostics.

Suggested checks:

1. Archive inventory by:
   - strategy_set_name
   - strategy_name
   - strategy_version
   - module1_scenario_set_name
   - module1_scenario_name
   - population_id

2. Current archived slice row count and distinct application_id count

3. Current archived slice count by decision_outcome

4. Current archived slice count by primary_reason_code

5. Current archived slice product × decision_outcome

6. Current archived slice score band × decision_outcome

7. Current archived slice simulated_offer_exposure_flag profile

8. Current archived slice requested_amount vs approved_amount by decision_outcome

9. Current archived slice requested_expected_loss_amount vs approved_expected_loss_amount by decision_outcome

10. Archive timestamp summary:
    - min archive_inserted_ts
    - max archive_inserted_ts
    for the current replacement key

11. Archive mode diagnostic:
    - archive_run_flag
    - strategy_archive_reset_mode
    - latest-run row count
    - current archived slice row count

These are archive diagnostics only.

They are not the full Module 2 QA framework and not matched strategy comparison.

================================================================================
13. SECTION 12 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 12 comments should explain:

- why latest-run output and archive persistence are separate
- why archive persistence should not recalculate outcomes
- why archive grain includes application_id
- why archive replacement key excludes application_id
- why strategy_run_id and strategy_run_ts are audit metadata, not replacement keys
- why latest_output_created_ts and archive_inserted_ts are audit metadata, not deterministic comparison evidence
- why archive_run_flag = FALSE skips persistence without modifying archive history
- why NONE mode should fail if the same replacement key already exists
- why STRATEGY_SCENARIO_ONLY is the ordinary rerun mode
- why STRATEGY_SET_ONLY is broader and should be used intentionally
- why ALL is the broadest reset mode and should be used cautiously
- why archive table schema alignment matters
- why matched strategy comparison is deferred to a later section

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.
No adverse-action reason-code language.

================================================================================
14. SECTION 12 DELIVERABLE
================================================================================

Please now provide:

1. Targeted Section 11 patches only:
   - add archive_run_flag and strategy_archive_reset_mode to the latest-run output
   - tighten the final decision-flag count gatekeeper to exactly one TRUE flag

2. Section 12 SQL only:
   STRATEGY DECISION ARCHIVE PERSISTENCE LAYER.

3. A short explanation of what Section 12 establishes.

4. A short explanation of what Section 12 intentionally does not build.

5. The recommended next build step after Section 12.

Do not write Section 13+ yet.
<!-- END_MESSAGE C038-M00147 -->


---

<a id="c038-m00163"></a>

### C038-M00163

**ChatGPT** · 2026-05-06T15:05:48.726384-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00163 -->
Section 11 is accepted with the two targeted patches below. Section 12 then adds governed archive persistence without recalculating any strategy result. This preserves the Module 1 pattern: latest-run output is replaceable, while archive output is the governed history layer for matched comparison. Module 1’s BRD and Validation Summary establish the underlying synthetic, deterministic, scenario-comparable boundary that Module 2 continues to preserve. fileciteturn4file0 fileciteturn4file1

---

# 1. Targeted Section 11 patches only

## Patch 11.A — Add archive controls to latest-run output

### BEFORE

```sql
CREATE TABLE credit_decisioning_sim.strategy_decisions AS
SELECT
```

### AFTER

```sql
CREATE TABLE credit_decisioning_sim.strategy_decisions AS
WITH active_archive_controls AS (
    SELECT
        archive_run_flag,
        strategy_archive_reset_mode
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
)
SELECT
```

Then add the two archive-control fields inside the **Module 2 strategy metadata** field family.

### BEFORE

```sql
module2_model_version,
strategy_set_name,
strategy_name,
strategy_version,
strategy_run_id,
strategy_run_ts,
failed_counteroffer_resolution,
module1_input_source,
module1_source_table_name,
```

### AFTER

```sql
module2_model_version,
strategy_set_name,
strategy_name,
strategy_version,
strategy_run_id,
strategy_run_ts,
failed_counteroffer_resolution,

/*
Archive controls.

These fields support archive persistence auditability in Section 12.
They are not part of the application-level grain.
They do not replace the archive replacement / rerun key.
*/
aac.archive_run_flag,
aac.strategy_archive_reset_mode,

module1_input_source,
module1_source_table_name,
```

And patch the `FROM` clause.

### BEFORE

```sql
FROM tmp_m2_stage_7_reason_code_assignment;
```

### AFTER

```sql
FROM tmp_m2_stage_7_reason_code_assignment r
CROSS JOIN active_archive_controls aac;
```

Add this local Section 11 gatekeeper after the metadata / lineage check.

```sql
/*-------------------------------------------------------------------------------------------
Gatekeeper: archive controls must be populated and valid in latest-run output.

archive_run_flag and strategy_archive_reset_mode are strategy-run controls used by
Section 12 archive persistence. They are audit and control fields, not row-level application
grain and not archive replacement keys.
-------------------------------------------------------------------------------------------*/
SELECT COUNT(*)
INTO v_archive_control_failure_count
FROM credit_decisioning_sim.strategy_decisions
WHERE archive_run_flag IS NULL
   OR strategy_archive_reset_mode IS NULL
   OR strategy_archive_reset_mode NOT IN (
        'NONE',
        'STRATEGY_SCENARIO_ONLY',
        'STRATEGY_SET_ONLY',
        'ALL'
   );

IF v_archive_control_failure_count > 0 THEN
    RAISE EXCEPTION
        'Module 2 Section 11 failure: % row(s) have missing or invalid archive control fields.',
        v_archive_control_failure_count;
END IF;
```

Add the variable to the Section 11.4 `DECLARE` block.

```sql
    v_archive_control_failure_count BIGINT;
```

---

## Patch 11.B — Exactly one final flag check

If your local Section 11 already uses the condition below, no code change is needed. This is the locked version.

### BEFORE

```sql
OR (
     COALESCE(approval_flag::INT, 0)
     + COALESCE(counteroffer_flag::INT, 0)
     + COALESCE(manual_review_flag::INT, 0)
     + COALESCE(decline_flag::INT, 0)
   ) > 1
```

### AFTER

```sql
OR (
     COALESCE(approval_flag::INT, 0)
     + COALESCE(counteroffer_flag::INT, 0)
     + COALESCE(manual_review_flag::INT, 0)
     + COALESCE(decline_flag::INT, 0)
   ) <> 1
```

---

# 2. Section 12 SQL only — Strategy Decision Archive Persistence Layer

```sql
/***************************************************************************************************
SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Persist completed latest-run Module 2 strategy outputs into a governed archive table.

    Section 12 answers:

        "Should this completed Module 2 strategy run be archived, and if so, how should existing
         archive rows be handled before inserting the current latest-run output?"

SQL PURPOSE:
    1. Consume credit_decisioning_sim.strategy_decisions.
    2. Create or reuse credit_decisioning_sim.strategy_decisions_archive.
    3. Validate latest-run archive controls.
    4. Apply governed archive reset / replacement behavior.
    5. Insert the current latest-run output into the archive when archive_run_flag = TRUE.
    6. Add archive_inserted_ts as archive persistence audit metadata.
    7. Validate archive grain, current slice integrity, and archive-control behavior.
    8. Create practical archive indexes.
    9. Provide lightweight archive diagnostics.

SECTION 12 DOES NOT RECALCULATE STRATEGY RESULTS:
    Section 12 does not recalculate:
        decision_outcome
        decision_path
        approved_amount
        approved_expected_loss_amount
        reason codes
        trigger flags
        segmentation fields
        counteroffer feasibility

    It persists the already-materialized latest-run output.

WHY LATEST-RUN OUTPUT AND ARCHIVE PERSISTENCE ARE SEPARATE:
    credit_decisioning_sim.strategy_decisions is the current latest-run output.
    It is replaced each run.

    credit_decisioning_sim.strategy_decisions_archive is the governed history layer.
    It supports completed-run retention and later matched strategy comparison.

ARCHIVE GRAIN:
    One row per application
    × Module 1 scenario
    × Module 2 strategy version

Archive row-level grain fields:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id

ARCHIVE REPLACEMENT / RERUN KEY:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

WHY APPLICATION_ID IS EXCLUDED FROM THE REPLACEMENT KEY:
    The replacement key identifies the completed strategy / scenario / population slice.
    application_id identifies each row within that slice.

AUDIT METADATA BOUNDARY:
    strategy_run_id:
        run traceability metadata.

    strategy_run_ts:
        run timestamp metadata.

    latest_output_created_ts:
        latest-run table materialization metadata.

    archive_inserted_ts:
        archive persistence metadata.

    None of these timestamp or run-audit fields define the archive replacement key.
    None of them should define matched strategy comparison grain.

ARCHIVE CONTROL MODES:
    archive_run_flag = FALSE:
        Skip archive persistence.
        Do not delete archive rows.
        Do not insert archive rows.

    strategy_archive_reset_mode = NONE:
        Do not delete existing archive rows before insert.
        Fail if the current replacement key already exists.

    strategy_archive_reset_mode = STRATEGY_SCENARIO_ONLY:
        Ordinary rerun mode.
        Replace only the current strategy / Module 1 scenario / population slice.

    strategy_archive_reset_mode = STRATEGY_SET_ONLY:
        Broader reset mode.
        Replace all strategy_name / strategy_version outputs within the current strategy_set_name
        for the selected Module 1 scenario and population.

    strategy_archive_reset_mode = ALL:
        Broadest reset mode.
        Delete all archive rows before inserting the current latest-run output.

SCHEMA ALIGNMENT NOTE:
    The archive table is created from the current latest-run output schema when it does not exist.

    If the latest-run schema changes after the archive already exists, the archive table may need to
    be altered or recreated so both schemas remain aligned. Section 12 includes practical schema
    alignment gatekeepers, but it does not attempt to build a full dynamic schema migration system.

MATCHED COMPARISON BOUNDARY:
    Section 12 persists archive rows.
    It does not compare archived strategies.
    Matched strategy comparison is built in a later section.

***************************************************************************************************/



/***************************************************************************************************
SECTION 12.1 — LATEST-RUN SOURCE INTEGRITY AND ARCHIVE-CONTROL PREFLIGHT
****************************************************************************************************/

DO $$
DECLARE
    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;
    v_archive_control_null_count BIGINT;
    v_archive_control_invalid_count BIGINT;
    v_archive_flag_value_count BIGINT;
    v_archive_mode_value_count BIGINT;
    v_archive_key_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must exist.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: credit_decisioning_sim.strategy_decisions does not exist.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output must contain rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run strategy_decisions table contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run application_id must be unique.

    Section 12 archive persistence assumes one latest-run row per application_id.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_distinct_app_count <> v_latest_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM credit_decisioning_sim.strategy_decisions
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run application_id is not unique. Latest rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_latest_count,
            v_latest_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls must be populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_control_null_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE archive_run_flag IS NULL
       OR strategy_archive_reset_mode IS NULL
       OR NULLIF(BTRIM(strategy_archive_reset_mode), '') IS NULL;

    IF v_archive_control_null_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % latest-run row(s) have null archive controls.',
            v_archive_control_null_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive reset mode must be valid.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_control_invalid_count
    FROM credit_decisioning_sim.strategy_decisions
    WHERE strategy_archive_reset_mode NOT IN (
        'NONE',
        'STRATEGY_SCENARIO_ONLY',
        'STRATEGY_SET_ONLY',
        'ALL'
    );

    IF v_archive_control_invalid_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: % latest-run row(s) have invalid strategy_archive_reset_mode values.',
            v_archive_control_invalid_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run table must contain exactly one archive control configuration.

    A mixed latest-run output would make archive behavior ambiguous.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT archive_run_flag)
    INTO v_archive_flag_value_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_archive_flag_value_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % distinct archive_run_flag values. Expected exactly one.',
            v_archive_flag_value_count;
    END IF;

    SELECT COUNT(DISTINCT strategy_archive_reset_mode)
    INTO v_archive_mode_value_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_archive_mode_value_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % distinct strategy_archive_reset_mode values. Expected exactly one.',
            v_archive_mode_value_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run table must contain exactly one archive replacement / rerun key.

    The latest-run output should represent one strategy / Module 1 scenario / population slice.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_key_count
    FROM (
        SELECT DISTINCT
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        FROM credit_decisioning_sim.strategy_decisions
    ) k;

    IF v_archive_key_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run output contains % archive replacement keys. Expected exactly one.',
            v_archive_key_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.2 — ARCHIVE TABLE SETUP AND SCHEMA ALIGNMENT CHECK
****************************************************************************************************

Archive table design:
    all fields from credit_decisioning_sim.strategy_decisions
    plus archive_inserted_ts

archive_inserted_ts:
    Audit metadata indicating when the latest-run output was persisted to archive.

***************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_decisions_archive
(LIKE credit_decisioning_sim.strategy_decisions INCLUDING DEFAULTS);

ALTER TABLE credit_decisioning_sim.strategy_decisions_archive
ADD COLUMN IF NOT EXISTS archive_inserted_ts TIMESTAMP;


/*-----------------------------------------------------------------------------------------------
Practical schema-alignment gatekeeper.

If the archive already existed before the latest-run schema changed, it may be missing columns.
This gatekeeper fails clearly rather than silently inserting misaligned rows.
-----------------------------------------------------------------------------------------------*/
DO $$
DECLARE
    v_missing_archive_columns TEXT;
    v_archive_inserted_ts_exists BOOLEAN;
BEGIN
    SELECT STRING_AGG(l.column_name, ', ' ORDER BY l.ordinal_position)
    INTO v_missing_archive_columns
    FROM information_schema.columns l
    WHERE l.table_schema = 'credit_decisioning_sim'
      AND l.table_name = 'strategy_decisions'
      AND NOT EXISTS (
            SELECT 1
            FROM information_schema.columns a
            WHERE a.table_schema = 'credit_decisioning_sim'
              AND a.table_name = 'strategy_decisions_archive'
              AND a.column_name = l.column_name
      );

    IF v_missing_archive_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive is missing latest-run column(s): %. Align or recreate the archive table before persistence.',
            v_missing_archive_columns;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'credit_decisioning_sim'
          AND table_name = 'strategy_decisions_archive'
          AND column_name = 'archive_inserted_ts'
    )
    INTO v_archive_inserted_ts_exists;

    IF v_archive_inserted_ts_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive is missing archive_inserted_ts.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 12.3 — ARCHIVE INVENTORY SNAPSHOT BEFORE PERSISTENCE
****************************************************************************************************

Purpose:
    Capture archive inventory before any delete / insert behavior so Section 12 can validate that
    archive reset modes do not unintentionally affect unrelated strategy slices.

***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_archive_inventory_before;

CREATE TEMP TABLE tmp_m2_archive_inventory_before
ON COMMIT PRESERVE ROWS
AS
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions_archive
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;


DROP TABLE IF EXISTS tmp_m2_archive_persistence_audit;

CREATE TEMP TABLE tmp_m2_archive_persistence_audit (
    archive_run_flag                    BOOLEAN,
    strategy_archive_reset_mode          TEXT,

    strategy_set_name                    TEXT,
    strategy_name                        TEXT,
    strategy_version                     TEXT,
    module1_scenario_set_name            TEXT,
    module1_scenario_name                TEXT,
    population_id                        TEXT,

    latest_run_row_count                 BIGINT,
    latest_run_distinct_application_count BIGINT,

    archive_row_count_before             BIGINT,
    archive_deleted_rows                 BIGINT,
    archive_inserted_rows                BIGINT,
    archive_row_count_after              BIGINT,

    archive_action                       TEXT,
    archive_action_ts                    TIMESTAMP
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 12.4 — APPLY ARCHIVE CONTROL LOGIC
****************************************************************************************************/

DO $$
DECLARE
    v_archive_run_flag BOOLEAN;
    v_strategy_archive_reset_mode TEXT;

    v_strategy_set_name TEXT;
    v_strategy_name TEXT;
    v_strategy_version TEXT;
    v_module1_scenario_set_name TEXT;
    v_module1_scenario_name TEXT;
    v_population_id TEXT;

    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_archive_before_count BIGINT;
    v_archive_after_count BIGINT;
    v_existing_key_count BIGINT;

    v_deleted_rows BIGINT := 0;
    v_inserted_rows BIGINT := 0;

    v_archive_action TEXT;
    v_insert_columns TEXT;
    v_select_columns TEXT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Read the single archive-control configuration and archive replacement key from latest-run output.
    Section 12.1 has already validated that exactly one such configuration exists.
    -------------------------------------------------------------------------------------------*/
    SELECT
        archive_run_flag,
        strategy_archive_reset_mode,
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    INTO
        v_archive_run_flag,
        v_strategy_archive_reset_mode,
        v_strategy_set_name,
        v_strategy_name,
        v_strategy_version,
        v_module1_scenario_set_name,
        v_module1_scenario_name,
        v_population_id
    FROM (
        SELECT DISTINCT
            archive_run_flag,
            strategy_archive_reset_mode,
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        FROM credit_decisioning_sim.strategy_decisions
    ) k;

    SELECT
        COUNT(*),
        COUNT(DISTINCT application_id)
    INTO
        v_latest_count,
        v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    SELECT COUNT(*)
    INTO v_archive_before_count
    FROM credit_decisioning_sim.strategy_decisions_archive;


    /*-------------------------------------------------------------------------------------------
    archive_run_flag = FALSE:
        Skip archive persistence.
        Do not delete archive rows.
        Do not insert archive rows.
    -------------------------------------------------------------------------------------------*/
    IF v_archive_run_flag IS FALSE THEN
        v_archive_action := 'ARCHIVE_PERSISTENCE_SKIPPED_ARCHIVE_RUN_FLAG_FALSE';
        v_deleted_rows := 0;
        v_inserted_rows := 0;

        RAISE NOTICE
            'Module 2 Section 12: archive persistence skipped because archive_run_flag = FALSE. Existing archive rows preserved.';


    ELSE
        /*---------------------------------------------------------------------------------------
        archive_run_flag = TRUE:
            Apply governed reset mode before inserting current latest-run rows.
        ---------------------------------------------------------------------------------------*/

        IF v_strategy_archive_reset_mode = 'NONE' THEN
            /*-----------------------------------------------------------------------------------
            NONE:
                Append only if the current replacement key does not already exist.
                This prevents silent duplicate archive slices.
            -----------------------------------------------------------------------------------*/
            SELECT COUNT(*)
            INTO v_existing_key_count
            FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = v_strategy_set_name
              AND strategy_name = v_strategy_name
              AND strategy_version = v_strategy_version
              AND module1_scenario_set_name = v_module1_scenario_set_name
              AND module1_scenario_name = v_module1_scenario_name
              AND population_id = v_population_id;

            IF v_existing_key_count > 0 THEN
                RAISE EXCEPTION
                    'Module 2 Section 12 failure: strategy_archive_reset_mode = NONE, but % archive row(s) already exist for the current replacement key.',
                    v_existing_key_count;
            END IF;

            v_archive_action := 'ARCHIVE_INSERT_WITHOUT_DELETE_NONE_MODE';
            v_deleted_rows := 0;


        ELSIF v_strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY' THEN
            /*-----------------------------------------------------------------------------------
            STRATEGY_SCENARIO_ONLY:
                Ordinary rerun mode.
                Replace only the exact strategy / Module 1 scenario / population slice.
            -----------------------------------------------------------------------------------*/
            DELETE FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = v_strategy_set_name
              AND strategy_name = v_strategy_name
              AND strategy_version = v_strategy_version
              AND module1_scenario_set_name = v_module1_scenario_set_name
              AND module1_scenario_name = v_module1_scenario_name
              AND population_id = v_population_id;

            GET DIAGNOSTICS v_deleted_rows = ROW_COUNT;
            v_archive_action := 'ARCHIVE_REPLACED_STRATEGY_SCENARIO_ONLY';


        ELSIF v_strategy_archive_reset_mode = 'STRATEGY_SET_ONLY' THEN
            /*-----------------------------------------------------------------------------------
            STRATEGY_SET_ONLY:
                Broader reset mode.
                Clears all strategy_name / strategy_version outputs within the same strategy set
                for the selected Module 1 scenario and population.
            -----------------------------------------------------------------------------------*/
            DELETE FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = v_strategy_set_name
              AND module1_scenario_set_name = v_module1_scenario_set_name
              AND module1_scenario_name = v_module1_scenario_name
              AND population_id = v_population_id;

            GET DIAGNOSTICS v_deleted_rows = ROW_COUNT;
            v_archive_action := 'ARCHIVE_REPLACED_STRATEGY_SET_ONLY';


        ELSIF v_strategy_archive_reset_mode = 'ALL' THEN
            /*-----------------------------------------------------------------------------------
            ALL:
                Broad reset mode.
                Deletes all archive rows before inserting the current latest-run output.

                Use intentionally.
            -----------------------------------------------------------------------------------*/
            DELETE FROM credit_decisioning_sim.strategy_decisions_archive;

            GET DIAGNOSTICS v_deleted_rows = ROW_COUNT;
            v_archive_action := 'ARCHIVE_FULL_RESET_ALL_MODE';


        ELSE
            RAISE EXCEPTION
                'Module 2 Section 12 failure: unsupported strategy_archive_reset_mode: %.',
                v_strategy_archive_reset_mode;
        END IF;


        /*---------------------------------------------------------------------------------------
        Insert current latest-run rows into archive.

        The dynamic column list is derived from the latest-run table schema so the INSERT is explicit
        and does not depend on physical column order. archive_inserted_ts is added separately.
        ---------------------------------------------------------------------------------------*/
        SELECT
            STRING_AGG(FORMAT('%I', column_name), ', ' ORDER BY ordinal_position),
            STRING_AGG(FORMAT('sd.%I', column_name), ', ' ORDER BY ordinal_position)
        INTO
            v_insert_columns,
            v_select_columns
        FROM information_schema.columns
        WHERE table_schema = 'credit_decisioning_sim'
          AND table_name = 'strategy_decisions';

        EXECUTE FORMAT(
            'INSERT INTO credit_decisioning_sim.strategy_decisions_archive (%s, archive_inserted_ts)
             SELECT %s, CURRENT_TIMESTAMP
             FROM credit_decisioning_sim.strategy_decisions sd',
            v_insert_columns,
            v_select_columns
        );

        GET DIAGNOSTICS v_inserted_rows = ROW_COUNT;
    END IF;


    SELECT COUNT(*)
    INTO v_archive_after_count
    FROM credit_decisioning_sim.strategy_decisions_archive;


    INSERT INTO tmp_m2_archive_persistence_audit (
        archive_run_flag,
        strategy_archive_reset_mode,

        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        latest_run_row_count,
        latest_run_distinct_application_count,

        archive_row_count_before,
        archive_deleted_rows,
        archive_inserted_rows,
        archive_row_count_after,

        archive_action,
        archive_action_ts
    )
    VALUES (
        v_archive_run_flag,
        v_strategy_archive_reset_mode,

        v_strategy_set_name,
        v_strategy_name,
        v_strategy_version,
        v_module1_scenario_set_name,
        v_module1_scenario_name,
        v_population_id,

        v_latest_count,
        v_latest_distinct_app_count,

        v_archive_before_count,
        v_deleted_rows,
        v_inserted_rows,
        v_archive_after_count,

        v_archive_action,
        CURRENT_TIMESTAMP
    );
END $$;



/***************************************************************************************************
SECTION 12.5 — ARCHIVE INVENTORY SNAPSHOT AFTER PERSISTENCE
***************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_archive_inventory_after;

CREATE TEMP TABLE tmp_m2_archive_inventory_after
ON COMMIT PRESERVE ROWS
AS
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count
FROM credit_decisioning_sim.strategy_decisions_archive
GROUP BY
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/***************************************************************************************************
SECTION 12.6 — LOCAL FAIL-FAST CHECKS FOR ARCHIVE PERSISTENCE
****************************************************************************************************

PURPOSE:
    Validate archive persistence behavior before matched comparison or full QA is built.

These checks validate:
    latest-run source integrity,
    archive table existence,
    archive skip behavior,
    archive insert behavior,
    archive mode behavior,
    archive grain integrity,
    and persistence fidelity.

***************************************************************************************************/

DO $$
DECLARE
    a RECORD;

    v_archive_table_exists BOOLEAN;
    v_archive_inserted_ts_exists BOOLEAN;

    v_latest_count BIGINT;
    v_latest_distinct_app_count BIGINT;
    v_current_archive_count BIGINT;
    v_current_archive_distinct_app_count BIGINT;
    v_current_archive_null_ts_count BIGINT;
    v_current_archive_duplicate_app_count BIGINT;

    v_archive_duplicate_grain_count BIGINT;
    v_inventory_diff_count BIGINT;
    v_after_inventory_group_count BIGINT;
    v_persistence_mismatch_count BIGINT;
BEGIN
    SELECT *
    INTO a
    FROM tmp_m2_archive_persistence_audit
    LIMIT 1;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive table and archive_inserted_ts must exist.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NOT NULL
    INTO v_archive_table_exists;

    IF v_archive_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: strategy_decisions_archive does not exist after archive setup.';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'credit_decisioning_sim'
          AND table_name = 'strategy_decisions_archive'
          AND column_name = 'archive_inserted_ts'
    )
    INTO v_archive_inserted_ts_exists;

    IF v_archive_inserted_ts_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive_inserted_ts column does not exist after archive setup.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run source integrity remains valid.
    -------------------------------------------------------------------------------------------*/
    SELECT
        COUNT(*),
        COUNT(DISTINCT application_id)
    INTO
        v_latest_count,
        v_latest_distinct_app_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run table contains zero rows during archive gatekeeper.';
    END IF;

    IF v_latest_distinct_app_count <> v_latest_count THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: latest-run application_id uniqueness failed during archive gatekeeper.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive_run_flag = FALSE skip behavior.

    Skip mode should not delete or insert archive rows.
    Existing archive inventory should remain unchanged.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS FALSE THEN
        IF a.archive_deleted_rows <> 0
           OR a.archive_inserted_rows <> 0
           OR a.archive_row_count_after <> a.archive_row_count_before THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive_run_flag = FALSE but archive row counts changed.';
        END IF;

        SELECT COUNT(*)
        INTO v_inventory_diff_count
        FROM (
            SELECT
                COALESCE(b.strategy_set_name, aft.strategy_set_name) AS strategy_set_name,
                COALESCE(b.strategy_name, aft.strategy_name) AS strategy_name,
                COALESCE(b.strategy_version, aft.strategy_version) AS strategy_version,
                COALESCE(b.module1_scenario_set_name, aft.module1_scenario_set_name) AS module1_scenario_set_name,
                COALESCE(b.module1_scenario_name, aft.module1_scenario_name) AS module1_scenario_name,
                COALESCE(b.population_id, aft.population_id) AS population_id,
                COALESCE(b.row_count, 0) AS before_row_count,
                COALESCE(aft.row_count, 0) AS after_row_count
            FROM tmp_m2_archive_inventory_before b
            FULL OUTER JOIN tmp_m2_archive_inventory_after aft
                ON aft.strategy_set_name = b.strategy_set_name
               AND aft.strategy_name = b.strategy_name
               AND aft.strategy_version = b.strategy_version
               AND aft.module1_scenario_set_name = b.module1_scenario_set_name
               AND aft.module1_scenario_name = b.module1_scenario_name
               AND aft.population_id = b.population_id
        ) d
        WHERE before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive inventory changed even though archive_run_flag = FALSE.';
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive_run_flag = TRUE insert behavior.

    The current archived slice should contain exactly one row per latest-run application_id.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS TRUE THEN
        SELECT
            COUNT(*),
            COUNT(DISTINCT application_id)
        INTO
            v_current_archive_count,
            v_current_archive_distinct_app_count
        FROM credit_decisioning_sim.strategy_decisions_archive
        WHERE strategy_set_name = a.strategy_set_name
          AND strategy_name = a.strategy_name
          AND strategy_version = a.strategy_version
          AND module1_scenario_set_name = a.module1_scenario_set_name
          AND module1_scenario_name = a.module1_scenario_name
          AND population_id = a.population_id;

        IF v_current_archive_count <> v_latest_count THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: current archived slice row count (%) does not match latest-run row count (%).',
                v_current_archive_count,
                v_latest_count;
        END IF;

        IF v_current_archive_distinct_app_count <> v_latest_distinct_app_count THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: current archived slice distinct application_id count (%) does not match latest-run distinct application_id count (%).',
                v_current_archive_distinct_app_count,
                v_latest_distinct_app_count;
        END IF;

        SELECT COUNT(*)
        INTO v_current_archive_null_ts_count
        FROM credit_decisioning_sim.strategy_decisions_archive
        WHERE strategy_set_name = a.strategy_set_name
          AND strategy_name = a.strategy_name
          AND strategy_version = a.strategy_version
          AND module1_scenario_set_name = a.module1_scenario_set_name
          AND module1_scenario_name = a.module1_scenario_name
          AND population_id = a.population_id
          AND archive_inserted_ts IS NULL;

        IF v_current_archive_null_ts_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: % current archived slice row(s) have null archive_inserted_ts.',
                v_current_archive_null_ts_count;
        END IF;

        SELECT COUNT(*)
        INTO v_current_archive_duplicate_app_count
        FROM (
            SELECT application_id
            FROM credit_decisioning_sim.strategy_decisions_archive
            WHERE strategy_set_name = a.strategy_set_name
              AND strategy_name = a.strategy_name
              AND strategy_version = a.strategy_version
              AND module1_scenario_set_name = a.module1_scenario_set_name
              AND module1_scenario_name = a.module1_scenario_name
              AND population_id = a.population_id
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        IF v_current_archive_duplicate_app_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: current archived slice contains % duplicate application_id group(s).',
                v_current_archive_duplicate_app_count;
        END IF;


        /*---------------------------------------------------------------------------------------
        Gatekeeper: persisted archive rows must match latest-run values for core final outputs.

        This confirms Section 12 persisted the already-materialized strategy result rather than
        recalculating or altering it.
        ---------------------------------------------------------------------------------------*/
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

        IF v_persistence_mismatch_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: % archived row(s) do not match latest-run core decision / exposure / reason-code fields.',
                v_persistence_mismatch_count;
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive mode behavior — preserve unrelated archive inventory where applicable.
    -------------------------------------------------------------------------------------------*/
    IF a.archive_run_flag IS TRUE
       AND a.strategy_archive_reset_mode IN ('NONE', 'STRATEGY_SCENARIO_ONLY') THEN

        SELECT COUNT(*)
        INTO v_inventory_diff_count
        FROM (
            SELECT
                COALESCE(b.strategy_set_name, aft.strategy_set_name) AS strategy_set_name,
                COALESCE(b.strategy_name, aft.strategy_name) AS strategy_name,
                COALESCE(b.strategy_version, aft.strategy_version) AS strategy_version,
                COALESCE(b.module1_scenario_set_name, aft.module1_scenario_set_name) AS module1_scenario_set_name,
                COALESCE(b.module1_scenario_name, aft.module1_scenario_name) AS module1_scenario_name,
                COALESCE(b.population_id, aft.population_id) AS population_id,
                COALESCE(b.row_count, 0) AS before_row_count,
                COALESCE(aft.row_count, 0) AS after_row_count
            FROM tmp_m2_archive_inventory_before b
            FULL OUTER JOIN tmp_m2_archive_inventory_after aft
                ON aft.strategy_set_name = b.strategy_set_name
               AND aft.strategy_name = b.strategy_name
               AND aft.strategy_version = b.strategy_version
               AND aft.module1_scenario_set_name = b.module1_scenario_set_name
               AND aft.module1_scenario_name = b.module1_scenario_name
               AND aft.population_id = b.population_id
        ) d
        WHERE NOT (
                strategy_set_name = a.strategy_set_name
            AND strategy_name = a.strategy_name
            AND strategy_version = a.strategy_version
            AND module1_scenario_set_name = a.module1_scenario_set_name
            AND module1_scenario_name = a.module1_scenario_name
            AND population_id = a.population_id
        )
          AND before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive inventory outside the current replacement key changed under mode %.',
                a.strategy_archive_reset_mode;
        END IF;
    END IF;


    IF a.archive_run_flag IS TRUE
       AND a.strategy_archive_reset_mode = 'STRATEGY_SET_ONLY' THEN

        SELECT COUNT(*)
        INTO v_inventory_diff_count
        FROM (
            SELECT
                COALESCE(b.strategy_set_name, aft.strategy_set_name) AS strategy_set_name,
                COALESCE(b.strategy_name, aft.strategy_name) AS strategy_name,
                COALESCE(b.strategy_version, aft.strategy_version) AS strategy_version,
                COALESCE(b.module1_scenario_set_name, aft.module1_scenario_set_name) AS module1_scenario_set_name,
                COALESCE(b.module1_scenario_name, aft.module1_scenario_name) AS module1_scenario_name,
                COALESCE(b.population_id, aft.population_id) AS population_id,
                COALESCE(b.row_count, 0) AS before_row_count,
                COALESCE(aft.row_count, 0) AS after_row_count
            FROM tmp_m2_archive_inventory_before b
            FULL OUTER JOIN tmp_m2_archive_inventory_after aft
                ON aft.strategy_set_name = b.strategy_set_name
               AND aft.strategy_name = b.strategy_name
               AND aft.strategy_version = b.strategy_version
               AND aft.module1_scenario_set_name = b.module1_scenario_set_name
               AND aft.module1_scenario_name = b.module1_scenario_name
               AND aft.population_id = b.population_id
        ) d
        WHERE NOT (
                strategy_set_name = a.strategy_set_name
            AND module1_scenario_set_name = a.module1_scenario_set_name
            AND module1_scenario_name = a.module1_scenario_name
            AND population_id = a.population_id
        )
          AND before_row_count <> after_row_count;

        IF v_inventory_diff_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: archive inventory outside the selected strategy set / scenario / population changed under STRATEGY_SET_ONLY mode.';
        END IF;
    END IF;


    IF a.archive_run_flag IS TRUE
       AND a.strategy_archive_reset_mode = 'ALL' THEN

        SELECT COUNT(*)
        INTO v_after_inventory_group_count
        FROM tmp_m2_archive_inventory_after;

        IF v_after_inventory_group_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 Section 12 failure: ALL reset mode should leave exactly one archive inventory group after current insert. Found %.',
                v_after_inventory_group_count;
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive row-level grain must be unique across the full archive.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_archive_duplicate_grain_count
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

    IF v_archive_duplicate_grain_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 12 failure: archive contains % duplicate row-level grain group(s).',
            v_archive_duplicate_grain_count;
    END IF;

    /*
    Boundary confirmation:
        Section 12 does not recalculate decision_outcome.
        Section 12 does not recalculate approved_amount.
        Section 12 does not recalculate approved_expected_loss_amount.
        Section 12 does not reassign simulated reason codes.
        Section 12 does not build matched strategy comparison queries.
        Section 12 does not build the full Module 2 QA framework.
    */
END $$;



/***************************************************************************************************
SECTION 12.7 — ARCHIVE INDEXES
****************************************************************************************************

PURPOSE:
    Support archive inventory, replacement-key lookup, row-level matching, strategy comparison,
    and reporting diagnostics.

***************************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_replacement_key
    ON credit_decisioning_sim.strategy_decisions_archive (
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

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

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_module1_lineage
    ON credit_decisioning_sim.strategy_decisions_archive (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_strategy_identity
    ON credit_decisioning_sim.strategy_decisions_archive (
        strategy_set_name,
        strategy_name,
        strategy_version
    );

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_decision_outcome
    ON credit_decisioning_sim.strategy_decisions_archive (decision_outcome);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_primary_reason
    ON credit_decisioning_sim.strategy_decisions_archive (primary_reason_code);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_product
    ON credit_decisioning_sim.strategy_decisions_archive (product_type_policy_key);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_score_band
    ON credit_decisioning_sim.strategy_decisions_archive (score_band_policy_key);

CREATE INDEX IF NOT EXISTS idx_m2_strategy_archive_offer_exposure
    ON credit_decisioning_sim.strategy_decisions_archive (simulated_offer_exposure_flag);



/***************************************************************************************************
SECTION 12.8 — LOCAL ARCHIVE SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight archive diagnostics.

IMPORTANT:
    These are archive diagnostics only.

    They are not:
        matched strategy comparison,
        full Module 2 QA,
        or documentation evidence.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
12.8.1 Archive inventory by strategy and Module 1 scenario.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS archived_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count,
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
12.8.2 Current archived slice row count and distinct application_id count.

Returns rows only when archive_run_flag = TRUE for the current latest-run persistence action.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,
    COUNT(ar.*) AS current_archived_slice_row_count,
    COUNT(DISTINCT ar.application_id) AS current_archived_slice_distinct_application_id_count
FROM archive_context a
LEFT JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY
    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id;


/*-----------------------------------------------------------------------------------------------
12.8.3 Current archived slice count by decision_outcome.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.decision_outcome,
    COUNT(*) AS row_count
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY ar.decision_outcome
ORDER BY
    CASE ar.decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
12.8.4 Current archived slice count by primary_reason_code.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.primary_reason_code,
    ar.primary_reason_family,
    COUNT(*) AS row_count
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY
    ar.primary_reason_code,
    ar.primary_reason_family
ORDER BY
    ar.primary_reason_family,
    ar.primary_reason_code;


/*-----------------------------------------------------------------------------------------------
12.8.5 Current archived slice product × decision_outcome.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.product_type_policy_key,
    ar.decision_outcome,
    COUNT(*) AS row_count,
    AVG(ar.estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(ar.approved_amount) AS avg_approved_amount,
    AVG(ar.approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY
    ar.product_type_policy_key,
    ar.decision_outcome
ORDER BY
    ar.product_type_policy_key,
    ar.decision_outcome;


/*-----------------------------------------------------------------------------------------------
12.8.6 Current archived slice score band × decision_outcome.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.score_band_policy_key,
    ar.decision_outcome,
    COUNT(*) AS row_count,
    AVG(ar.estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY
    ar.score_band_policy_key,
    ar.decision_outcome
ORDER BY
    CASE ar.score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    ar.decision_outcome;


/*-----------------------------------------------------------------------------------------------
12.8.7 Current archived slice simulated_offer_exposure_flag profile.

Interpretation:
    simulated_offer_exposure_flag indicates simulated positive offer exposure for APPROVE and
    COUNTEROFFER outcomes. It does not imply operational account creation or real customer treatment.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.simulated_offer_exposure_flag,
    COUNT(*) AS row_count,
    SUM(ar.approved_amount) AS total_approved_amount,
    AVG(ar.estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    SUM(ar.approved_expected_loss_amount) AS total_approved_expected_loss_amount,
    AVG(ar.approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY ar.simulated_offer_exposure_flag
ORDER BY ar.simulated_offer_exposure_flag;


/*-----------------------------------------------------------------------------------------------
12.8.8 Current archived slice requested_amount versus approved_amount by decision_outcome.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.decision_outcome,
    COUNT(*) AS row_count,
    AVG(ar.requested_amount) AS avg_requested_amount,
    AVG(ar.approved_amount) AS avg_approved_amount,
    AVG(ar.exposure_reduction_amount) AS avg_exposure_reduction_amount,
    AVG(ar.exposure_reduction_pct) AS avg_exposure_reduction_pct
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY ar.decision_outcome
ORDER BY ar.decision_outcome;


/*-----------------------------------------------------------------------------------------------
12.8.9 Current archived slice requested Expected Loss versus approved Expected Loss by decision_outcome.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    ar.decision_outcome,
    COUNT(*) AS row_count,
    AVG(ar.requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(ar.approved_expected_loss_amount) AS avg_approved_expected_loss_amount,
    AVG(ar.approved_el_reduction_amount) AS avg_approved_el_reduction_amount,
    AVG(ar.approved_el_reduction_pct) AS avg_approved_el_reduction_pct
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE
GROUP BY ar.decision_outcome
ORDER BY ar.decision_outcome;


/*-----------------------------------------------------------------------------------------------
12.8.10 Archive timestamp summary for current replacement key.
-----------------------------------------------------------------------------------------------*/
WITH archive_context AS (
    SELECT *
    FROM tmp_m2_archive_persistence_audit
)
SELECT
    MIN(ar.archive_inserted_ts) AS min_archive_inserted_ts,
    MAX(ar.archive_inserted_ts) AS max_archive_inserted_ts,
    COUNT(*) AS current_archived_slice_row_count
FROM archive_context a
JOIN credit_decisioning_sim.strategy_decisions_archive ar
    ON ar.strategy_set_name = a.strategy_set_name
   AND ar.strategy_name = a.strategy_name
   AND ar.strategy_version = a.strategy_version
   AND ar.module1_scenario_set_name = a.module1_scenario_set_name
   AND ar.module1_scenario_name = a.module1_scenario_name
   AND ar.population_id = a.population_id
WHERE a.archive_run_flag IS TRUE;


/*-----------------------------------------------------------------------------------------------
12.8.11 Archive mode diagnostic.

This is the clearest diagnostic for whether Section 12 skipped, replaced, reset, or inserted.
-----------------------------------------------------------------------------------------------*/
SELECT
    archive_run_flag,
    strategy_archive_reset_mode,
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    latest_run_row_count,
    latest_run_distinct_application_count,
    archive_row_count_before,
    archive_deleted_rows,
    archive_inserted_rows,
    archive_row_count_after,
    archive_action,
    archive_action_ts
FROM tmp_m2_archive_persistence_audit;


/***************************************************************************************************
END OF SECTION 12 — STRATEGY DECISION ARCHIVE PERSISTENCE LAYER

If execution reaches this point:
    1. credit_decisioning_sim.strategy_decisions_archive exists.
    2. archive_inserted_ts exists.
    3. latest-run archive controls are populated and unambiguous.
    4. archive_run_flag = FALSE skips persistence without deleting or inserting archive rows.
    5. archive_run_flag = TRUE persists latest-run rows according to strategy_archive_reset_mode.
    6. STRATEGY_SCENARIO_ONLY replaces only the current replacement key.
    7. STRATEGY_SET_ONLY replaces the selected strategy set for the selected Module 1 scenario and population.
    8. ALL resets the full archive before inserting the current latest-run output.
    9. NONE inserts only when the current replacement key does not already exist.
    10. Archive row-level grain is protected by a unique index.
    11. Archive diagnostics are available for inventory and current-slice review.

No matched strategy comparison queries have been created.
No full Module 2 QA framework has been created.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

---

# 3. What Section 12 establishes

Section 12 creates or reuses:

```text
credit_decisioning_sim.strategy_decisions_archive
```

It persists the current latest-run strategy output into the archive when `archive_run_flag = TRUE`, using the locked replacement key:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
```

It preserves one archived row per application by adding `application_id` to the row-level archive grain.

---

# 4. What Section 12 intentionally does not build

Section 12 does not build matched strategy comparison, full Module 2 QA, dashboard outputs, BRD documentation, or Validation Summary documentation.

It also does not recalculate decisions, approved exposure, approved Expected Loss, or reason codes.

---

# 5. Recommended next build step

Next should be:

```text
Section 13 — Archive Inventory and Matched Strategy Comparison Framework
```

That section should compare archived Module 2 strategy runs using the locked archive grain, including matched row-level deltas by `application_id` while preserving Module 1 scenario lineage and Module 2 strategy metadata.
<!-- END_MESSAGE C038-M00163 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_05.md) · [Next](Part_07.md)
