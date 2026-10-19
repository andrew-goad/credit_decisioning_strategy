# Module 2 Decision Simulator Build

## Part 05

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_04.md) · [Next](Part_06.md)

<a id="c038-m00126"></a>

### C038-M00126

**Andrew** · 2026-05-06T13:45:27.884000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00126 -->
This is strong. I agree with the Section 8 Approved Exposure and Counteroffer Feasibility Layer.

Section 8 should be treated as provisionally accepted, subject to the pre-flight review below.

Section 8 correctly:
- consumes tmp_m2_stage_4_preliminary_decision_routing
- creates tmp_m2_stage_5_exposure_treatment
- preserves Module 1 lineage and Module 2 strategy metadata
- preserves preliminary routing fields
- calculates preliminary approved exposure treatment
- evaluates counteroffer feasibility
- distinguishes requested exposure from preliminary approved exposure
- calculates preliminary approved payment, approved PTI, and approved Expected Loss
- keeps manual review unresolved
- keeps failed counteroffers unresolved for later final decision resolution
- does not create final decision_outcome
- does not create final decision_path
- does not create final approval / decline / manual review / counteroffer flags
- does not create simulated_offer_exposure_flag
- does not assign reason codes
- does not create latest-run output
- does not insert archive rows
- does not build full QA

Do not rewrite Sections 0–8 unless the pre-flight review identifies a specific dependency issue.

================================================================================
1. SECTION 8 PRE-FLIGHT REVIEW BEFORE SECTION 9
================================================================================

Before writing Section 9, please do a brief targeted pre-flight review of Section 8.

Confirm that Section 8 includes the following output fields:

Exposure treatment fields:
- exposure_treatment_status
- exposure_treatment_path
- approved_amount_preliminary
- counteroffer_amount_preliminary
- exposure_reduction_flag_preliminary
- exposure_reduction_amount_preliminary
- exposure_reduction_pct_preliminary

Approved affordability fields:
- approved_monthly_payment_proxy_preliminary
- approved_payment_to_income_ratio_preliminary

Approved economics fields:
- approved_expected_loss_amount_preliminary
- approved_el_reduction_amount_preliminary
- approved_el_reduction_pct_preliminary

Counteroffer feasibility fields:
- counteroffer_feasibility_evaluated_flag
- counteroffer_feasibility_pass_flag
- counteroffer_feasibility_failure_reason
- counteroffer_feasibility_constraint_count

Counteroffer calculation diagnostics:
- counteroffer_product_cap_amount
- counteroffer_pti_target_amount
- counteroffer_el_cap_amount
- counteroffer_raw_max_feasible_amount
- counteroffer_min_viable_amount
- counteroffer_rounded_amount

Also confirm that Section 8 does NOT create:
- decision_outcome
- decision_path
- approval_flag
- decline_flag
- manual_review_flag
- counteroffer_flag
- simulated_offer_exposure_flag
- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- triggered_reason_code_list
- reason_priority_rank
- final latest-run output table
- archive insert logic

Confirm that Section 8 treatment conventions are internally consistent:

APPROVE preliminary route:
- approved_amount_preliminary = requested_amount
- approved_expected_loss_amount_preliminary = requested_expected_loss_amount
- counteroffer_feasibility_evaluated_flag = FALSE

DECLINE preliminary route:
- approved_amount_preliminary = 0
- approved_expected_loss_amount_preliminary = 0
- counteroffer_feasibility_evaluated_flag = FALSE

MANUAL_REVIEW preliminary route:
- approved_amount_preliminary IS NULL
- approved_expected_loss_amount_preliminary IS NULL
- counteroffer_feasibility_evaluated_flag = FALSE

COUNTEROFFER preliminary route:
- counteroffer_feasibility_evaluated_flag = TRUE
- if counteroffer_feasibility_pass_flag = TRUE, approved_amount_preliminary is populated
- if counteroffer_feasibility_pass_flag = FALSE, approved_amount_preliminary remains NULL and failure reason is populated

If the pre-flight review finds an issue, provide a targeted BEFORE / AFTER patch only.

If no issue is found, explicitly state:

“Section 8 pre-flight review passed; no patch required.”

================================================================================
2. NEXT BUILD SCOPE: SECTION 9 ONLY
================================================================================

After the Section 8 pre-flight review, please build only:

SECTION 9 — FINAL DECISION RESOLUTION LAYER

Recommended staged table:

tmp_m2_stage_6_final_decision_resolution

Section 9 should consume:

tmp_m2_stage_5_exposure_treatment

Section 9 should convert preliminary routing plus Section 8 exposure feasibility into final simulated strategy outcomes.

Do not build:
- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- triggered_reason_code_list
- reason_priority_rank
- final latest-run output table
- archive insert logic
- full QA framework

Those belong to later sections.

================================================================================
3. SECTION 9 OBJECTIVE
================================================================================

Section 9 should answer:

“Given preliminary routing and exposure-treatment feasibility, what is the final simulated strategy outcome for this synthetic applicant?”

Section 9 should create final outcome fields and final exposure economics.

Section 9 should not assign simulated reason codes yet.

Reason-code assignment should remain a separate later layer because reason-code prioritization should use:
- final decision outcome
- final decision path
- preliminary routing diagnostics
- rule trigger diagnostics
- exposure-treatment diagnostics
- counteroffer feasibility diagnostics

================================================================================
4. TARGETED PARAMETER PATCH BEFORE SECTION 9
================================================================================

Before writing Section 9, please add one governed strategy parameter if it does not already exist:

failed_counteroffer_resolution

Recommended default:
MANUAL_REVIEW

Allowed values:
- MANUAL_REVIEW
- DECLINE

Purpose:
Defines how preliminary COUNTEROFFER routes should resolve when Section 8 determines that no viable counteroffer exists.

Default interpretation:
A failed counteroffer is routed to MANUAL_REVIEW by default because:
- higher-priority hard simulated policy stops already route to DECLINE
- severe synthetic estimated-risk already routes to DECLINE
- severe DTI already routes to DECLINE
- a failed counteroffer often reflects unresolved exposure / affordability / approved Expected Loss feasibility rather than an automatic policy stop
- manual review preserves auditability and avoids silently converting all infeasible reduced-exposure cases to declines

Boundary:
This is a simulated strategy-control parameter, not production underwriting policy.

Please add the corresponding Section 3 gatekeeper:
- failed_counteroffer_resolution is non-null
- failed_counteroffer_resolution IN ('MANUAL_REVIEW', 'DECLINE')

If this parameter already exists under another name, identify it and use the existing field rather than adding a duplicate.

================================================================================
5. REQUIRED SECTION 9 OUTPUT FIELDS
================================================================================

Section 9 should preserve all fields from tmp_m2_stage_5_exposure_treatment and add final decision-resolution fields.

Final decision fields:
- decision_outcome
- decision_path
- decision_priority_rank
- decision_resolution_source

Final decision flags:
- approval_flag
- counteroffer_flag
- manual_review_flag
- decline_flag
- simulated_offer_exposure_flag

Final exposure fields:
- approved_amount
- counteroffer_amount
- exposure_reduction_flag
- exposure_reduction_amount
- exposure_reduction_pct

Final affordability fields:
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio

Final economics fields:
- approved_expected_loss_amount
- approved_el_reduction_amount
- approved_el_reduction_pct

Do not add reason-code fields yet.

Do not create the final latest-run output table yet.

================================================================================
6. FINAL DECISION RESOLUTION LOGIC
================================================================================

Use the following final decision resolution hierarchy.

--------------------------------------------------------------------------------
1. Preliminary DECLINE
--------------------------------------------------------------------------------

If preliminary_decision_outcome = 'DECLINE':

- decision_outcome = 'DECLINE'
- decision_path = preliminary_decision_path
- decision_priority_rank = preliminary_decision_priority_rank
- decision_resolution_source = 'PRELIMINARY_DECLINE_CONFIRMED'

Final exposure convention:
- approved_amount = 0
- counteroffer_amount = NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = requested_amount
- exposure_reduction_pct = 1.0
- approved_monthly_payment_proxy = 0
- approved_payment_to_income_ratio = 0
- approved_expected_loss_amount = 0
- approved_el_reduction_amount = requested_expected_loss_amount
- approved_el_reduction_pct =
    CASE
        WHEN requested_expected_loss_amount > 0 THEN 1.0
        ELSE 0
    END
- simulated_offer_exposure_flag = FALSE

--------------------------------------------------------------------------------
2. Preliminary MANUAL_REVIEW
--------------------------------------------------------------------------------

If preliminary_decision_outcome = 'MANUAL_REVIEW':

- decision_outcome = 'MANUAL_REVIEW'
- decision_path = preliminary_decision_path
- decision_priority_rank = preliminary_decision_priority_rank
- decision_resolution_source = 'PRELIMINARY_MANUAL_REVIEW_CONFIRMED'

Final exposure convention:
- approved_amount = NULL
- counteroffer_amount = NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = NULL
- exposure_reduction_pct = NULL
- approved_monthly_payment_proxy = NULL
- approved_payment_to_income_ratio = NULL
- approved_expected_loss_amount = NULL
- approved_el_reduction_amount = NULL
- approved_el_reduction_pct = NULL
- simulated_offer_exposure_flag = FALSE

Manual review remains unresolved by design.

--------------------------------------------------------------------------------
3. Preliminary APPROVE
--------------------------------------------------------------------------------

If preliminary_decision_outcome = 'APPROVE':

- decision_outcome = 'APPROVE'
- decision_path = 'APPROVE_AS_REQUESTED'
- decision_priority_rank = preliminary_decision_priority_rank
- decision_resolution_source = 'PRELIMINARY_APPROVE_CONFIRMED'

Final exposure convention:
- approved_amount = requested_amount
- counteroffer_amount = NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = 0
- exposure_reduction_pct = 0
- approved_monthly_payment_proxy = requested_monthly_payment_proxy
- approved_payment_to_income_ratio = requested_payment_to_income_ratio
- approved_expected_loss_amount = requested_expected_loss_amount
- approved_el_reduction_amount = 0
- approved_el_reduction_pct = 0
- simulated_offer_exposure_flag = TRUE

Important naming convention:
Use decision_path = APPROVE_AS_REQUESTED.

Reserve APPROVED_AS_REQUESTED for the later simulated reason-code layer, where it can be used as the approval primary_reason_code.

--------------------------------------------------------------------------------
4. Preliminary COUNTEROFFER with feasible counteroffer
--------------------------------------------------------------------------------

If preliminary_decision_outcome = 'COUNTEROFFER'
and counteroffer_feasibility_pass_flag = TRUE:

- decision_outcome = 'COUNTEROFFER'
- decision_path = 'COUNTEROFFER_FEASIBLE'
- decision_priority_rank = preliminary_decision_priority_rank
- decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_CONFIRMED'

Final exposure convention:
- approved_amount = approved_amount_preliminary
- counteroffer_amount = counteroffer_amount_preliminary
- exposure_reduction_flag = TRUE
- exposure_reduction_amount = exposure_reduction_amount_preliminary
- exposure_reduction_pct = exposure_reduction_pct_preliminary
- approved_monthly_payment_proxy = approved_monthly_payment_proxy_preliminary
- approved_payment_to_income_ratio = approved_payment_to_income_ratio_preliminary
- approved_expected_loss_amount = approved_expected_loss_amount_preliminary
- approved_el_reduction_amount = approved_el_reduction_amount_preliminary
- approved_el_reduction_pct = approved_el_reduction_pct_preliminary
- simulated_offer_exposure_flag = TRUE

--------------------------------------------------------------------------------
5. Preliminary COUNTEROFFER with infeasible counteroffer
--------------------------------------------------------------------------------

If preliminary_decision_outcome = 'COUNTEROFFER'
and counteroffer_feasibility_pass_flag = FALSE
and failed_counteroffer_resolution = 'MANUAL_REVIEW':

- decision_outcome = 'MANUAL_REVIEW'
- decision_path = 'COUNTEROFFER_NOT_FEASIBLE_REVIEW'
- decision_priority_rank = preliminary_decision_priority_rank
- decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'

Final exposure convention:
- approved_amount = NULL
- counteroffer_amount = NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = NULL
- exposure_reduction_pct = NULL
- approved_monthly_payment_proxy = NULL
- approved_payment_to_income_ratio = NULL
- approved_expected_loss_amount = NULL
- approved_el_reduction_amount = NULL
- approved_el_reduction_pct = NULL
- simulated_offer_exposure_flag = FALSE

If preliminary_decision_outcome = 'COUNTEROFFER'
and counteroffer_feasibility_pass_flag = FALSE
and failed_counteroffer_resolution = 'DECLINE':

- decision_outcome = 'DECLINE'
- decision_path = 'COUNTEROFFER_NOT_FEASIBLE_DECLINE'
- decision_priority_rank = preliminary_decision_priority_rank
- decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'

Final exposure convention:
- approved_amount = 0
- counteroffer_amount = NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = requested_amount
- exposure_reduction_pct = 1.0
- approved_monthly_payment_proxy = 0
- approved_payment_to_income_ratio = 0
- approved_expected_loss_amount = 0
- approved_el_reduction_amount = requested_expected_loss_amount
- approved_el_reduction_pct =
    CASE
        WHEN requested_expected_loss_amount > 0 THEN 1.0
        ELSE 0
    END
- simulated_offer_exposure_flag = FALSE

--------------------------------------------------------------------------------
6. Residual fallback
--------------------------------------------------------------------------------

If no final outcome can be assigned:

- decision_outcome = 'MANUAL_REVIEW'
- decision_path = 'FINAL_RESIDUAL_STRATEGY_REVIEW'
- decision_priority_rank = 99
- decision_resolution_source = 'FINAL_RESIDUAL_FALLBACK'

Final exposure convention:
- approved_amount = NULL
- counteroffer_amount = NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = NULL
- exposure_reduction_pct = NULL
- approved_monthly_payment_proxy = NULL
- approved_payment_to_income_ratio = NULL
- approved_expected_loss_amount = NULL
- approved_el_reduction_amount = NULL
- approved_el_reduction_pct = NULL
- simulated_offer_exposure_flag = FALSE

Residual fallback is intentionally conservative. Unresolved synthetic profiles should not silently become approvals or declines.

================================================================================
7. FINAL FLAG CONVENTIONS
================================================================================

Section 9 should create final flags using decision_outcome.

Required reconciliation:

APPROVE:
- approval_flag = TRUE
- counteroffer_flag = FALSE
- manual_review_flag = FALSE
- decline_flag = FALSE
- simulated_offer_exposure_flag = TRUE

COUNTEROFFER:
- approval_flag = FALSE
- counteroffer_flag = TRUE
- manual_review_flag = FALSE
- decline_flag = FALSE
- simulated_offer_exposure_flag = TRUE

MANUAL_REVIEW:
- approval_flag = FALSE
- counteroffer_flag = FALSE
- manual_review_flag = TRUE
- decline_flag = FALSE
- simulated_offer_exposure_flag = FALSE

DECLINE:
- approval_flag = FALSE
- counteroffer_flag = FALSE
- manual_review_flag = FALSE
- decline_flag = TRUE
- simulated_offer_exposure_flag = FALSE

Important:
simulated_offer_exposure_flag means the simulated strategy produces a positive offer exposure in the current strategy output.

It does not mean:
- booked account
- funded account
- production approval
- real customer treatment

================================================================================
8. SECTION 9 LOCAL GATEKEEPERS
================================================================================

At the end of Section 9, include local fail-fast checks.

Validate:

--------------------------------------------------------------------------------
1. Structural preservation
--------------------------------------------------------------------------------

- row count is unchanged from tmp_m2_stage_5_exposure_treatment
- application_id remains unique

--------------------------------------------------------------------------------
2. Final decision completeness
--------------------------------------------------------------------------------

- decision_outcome is non-null for every row
- decision_outcome is one of:
  - APPROVE
  - COUNTEROFFER
  - MANUAL_REVIEW
  - DECLINE

- decision_path is non-null for every row
- decision_priority_rank is non-null and positive
- decision_resolution_source is non-null for every row

--------------------------------------------------------------------------------
3. Final flag reconciliation
--------------------------------------------------------------------------------

Exactly one of the following should be TRUE per row:
- approval_flag
- counteroffer_flag
- manual_review_flag
- decline_flag

Each flag should reconcile to decision_outcome:
- approval_flag = TRUE only when decision_outcome = APPROVE
- counteroffer_flag = TRUE only when decision_outcome = COUNTEROFFER
- manual_review_flag = TRUE only when decision_outcome = MANUAL_REVIEW
- decline_flag = TRUE only when decision_outcome = DECLINE

simulated_offer_exposure_flag should reconcile to decision_outcome:
- TRUE only when decision_outcome IN ('APPROVE', 'COUNTEROFFER')
- FALSE when decision_outcome IN ('MANUAL_REVIEW', 'DECLINE')

--------------------------------------------------------------------------------
4. APPROVE final convention checks
--------------------------------------------------------------------------------

For decision_outcome = APPROVE:
- approved_amount = requested_amount
- counteroffer_amount IS NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = 0
- exposure_reduction_pct = 0
- approved_monthly_payment_proxy = requested_monthly_payment_proxy
- approved_payment_to_income_ratio = requested_payment_to_income_ratio
- approved_expected_loss_amount = requested_expected_loss_amount
- approved_el_reduction_amount = 0
- approved_el_reduction_pct = 0
- simulated_offer_exposure_flag = TRUE

--------------------------------------------------------------------------------
5. COUNTEROFFER final convention checks
--------------------------------------------------------------------------------

For decision_outcome = COUNTEROFFER:
- counteroffer_feasibility_pass_flag = TRUE
- approved_amount IS NOT NULL
- approved_amount > 0
- approved_amount < requested_amount
- counteroffer_amount = approved_amount
- exposure_reduction_flag = TRUE
- exposure_reduction_amount = requested_amount - approved_amount
- exposure_reduction_pct = exposure_reduction_amount / NULLIF(requested_amount, 0)
- approved_monthly_payment_proxy IS NOT NULL
- approved_payment_to_income_ratio IS NOT NULL
- approved_expected_loss_amount IS NOT NULL
- approved_expected_loss_amount <= product_approved_el_cap
- approved_payment_to_income_ratio <= counteroffer_target_pti
- simulated_offer_exposure_flag = TRUE

--------------------------------------------------------------------------------
6. MANUAL_REVIEW final convention checks
--------------------------------------------------------------------------------

For decision_outcome = MANUAL_REVIEW:
- approved_amount IS NULL
- counteroffer_amount IS NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount IS NULL
- exposure_reduction_pct IS NULL
- approved_monthly_payment_proxy IS NULL
- approved_payment_to_income_ratio IS NULL
- approved_expected_loss_amount IS NULL
- approved_el_reduction_amount IS NULL
- approved_el_reduction_pct IS NULL
- simulated_offer_exposure_flag = FALSE

--------------------------------------------------------------------------------
7. DECLINE final convention checks
--------------------------------------------------------------------------------

For decision_outcome = DECLINE:
- approved_amount = 0
- counteroffer_amount IS NULL
- exposure_reduction_flag = FALSE
- exposure_reduction_amount = requested_amount
- exposure_reduction_pct = 1.0
- approved_monthly_payment_proxy = 0
- approved_payment_to_income_ratio = 0
- approved_expected_loss_amount = 0
- approved_el_reduction_amount = requested_expected_loss_amount
- approved_el_reduction_pct =
    CASE
        WHEN requested_expected_loss_amount > 0 THEN 1.0
        ELSE 0
    END
- simulated_offer_exposure_flag = FALSE

--------------------------------------------------------------------------------
8. Failed counteroffer resolution checks
--------------------------------------------------------------------------------

For preliminary_decision_outcome = COUNTEROFFER
and counteroffer_feasibility_pass_flag = FALSE:

- if failed_counteroffer_resolution = MANUAL_REVIEW, final decision_outcome should be MANUAL_REVIEW
- if failed_counteroffer_resolution = DECLINE, final decision_outcome should be DECLINE
- final decision_path should clearly identify failed counteroffer resolution

--------------------------------------------------------------------------------
9. No reason-code fields yet
--------------------------------------------------------------------------------

Validate or explicitly confirm:
- no primary_reason_code column exists yet
- no secondary_reason_code column exists yet
- no tertiary_reason_code column exists yet
- no triggered_reason_code_list column exists yet
- no reason_priority_rank column exists yet

Reason codes belong to the next section.

--------------------------------------------------------------------------------
10. No final output / archive yet
--------------------------------------------------------------------------------

Validate or explicitly confirm:
- no final latest-run strategy output table is created yet
- no strategy archive rows are inserted yet

These are Section 9 local staging gatekeepers only, not full Module 2 QA.

================================================================================
9. SECTION 9 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight staging diagnostics.

Suggested checks:

1. Count by decision_outcome
2. Count by decision_path
3. Count by decision_resolution_source
4. Count by simulated_offer_exposure_flag
5. Preliminary decision outcome × final decision outcome
6. Exposure treatment status × final decision outcome
7. Counteroffer feasibility pass flag × final decision outcome
8. Counteroffer feasibility failure reason × final decision outcome
9. Product × decision_outcome
10. Score band × decision_outcome
11. Strategy risk tier × decision_outcome
12. Requested PTI bucket × decision_outcome
13. Requested exposure tier × decision_outcome
14. Requested Expected Loss tier × decision_outcome
15. Mixed-signal profile × decision_outcome
16. Borderline profile flag × decision_outcome
17. Average requested_amount by decision_outcome
18. Average approved_amount by decision_outcome
19. Average requested_payment_to_income_ratio by decision_outcome
20. Average approved_payment_to_income_ratio by decision_outcome
21. Average requested_expected_loss_amount by decision_outcome
22. Average approved_expected_loss_amount by decision_outcome

These are staging diagnostics only.
They should not be interpreted as full final strategy validation yet.

================================================================================
10. SECTION 9 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 9 comments should explain:

- why final decision resolution is separated from preliminary routing
- why Section 8 exposure feasibility is required before final counteroffer resolution
- why failed counteroffers use a governed resolution parameter
- why decision_outcome becomes final here, but reason codes remain deferred
- why APPROVE and COUNTEROFFER are simulated positive offer outcomes
- why MANUAL_REVIEW remains unresolved
- why DECLINE uses the zero-exposure convention
- why simulated_offer_exposure_flag does not imply a booked account
- why requested Expected Loss and approved Expected Loss remain separate
- why estimated_pd remains only the Module 1 synthetic estimated-PD proxy input
- why no reason codes are assigned in Section 9
- why no final latest-run table or archive insert occurs in Section 9

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.
No adverse-action reason-code language.

================================================================================
11. SECTION 9 DELIVERABLE
================================================================================

Please now provide:

1. Any targeted Section 8 patch required by the pre-flight review, if any.
2. Any required targeted Section 2 / Section 3 parameter and gatekeeper patch for failed_counteroffer_resolution.
3. Section 9 SQL only:
   FINAL DECISION RESOLUTION LAYER.
4. A short explanation of what Section 9 establishes.
5. A short explanation of what Section 9 intentionally does not build.
6. The recommended next build step after Section 9.

Do not write Section 10+ yet.
<!-- END_MESSAGE C038-M00126 -->


---

<a id="c038-m00129"></a>

### C038-M00129

**ChatGPT** · 2026-05-06T13:50:33.282362-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00129 -->
Section 8 pre-flight review passed; no patch required.

Section 8 includes all required exposure-treatment, preliminary approved affordability, preliminary approved economics, counteroffer feasibility, and counteroffer calculation diagnostic fields. It does not create final decision fields, final outcome flags, `simulated_offer_exposure_flag`, reason-code fields, the final latest-run table, or archive insert logic. Its treatment conventions for preliminary `APPROVE`, `DECLINE`, `MANUAL_REVIEW`, and `COUNTEROFFER` routes are internally consistent.

The Section 9 build below preserves the Module 1 boundary that `estimated_pd` remains the finalized Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy; Module 2 continues to use it as an input rather than recalculating it. Module 1’s BRD frames the engine as governed synthetic strategy simulation, not production underwriting, calibrated PD modeling, or production loss forecasting, and the validation summary confirms that Module 1 is accepted for controlled synthetic strategy simulation within those boundaries. fileciteturn4file0 fileciteturn4file1

---

# 1. Targeted Section 2 / Section 3 patch for `failed_counteroffer_resolution`

## Patch 2.A — Add parameter column to `tmp_module2_strategy_params`

### BEFORE

```sql
/* Decision convention controls */
approve_reason_code                          TEXT,
reason_code_required_flag                    BOOLEAN,
simulated_offer_exposure_flag_enabled        BOOLEAN,
manual_review_approved_amount_convention     TEXT,
decline_approved_amount_convention           TEXT,
approved_el_decline_convention               TEXT,
approved_el_manual_review_convention         TEXT,
allow_approved_amount_above_requested_flag   BOOLEAN
```

### AFTER

```sql
/* Decision convention controls */
approve_reason_code                          TEXT,
reason_code_required_flag                    BOOLEAN,
simulated_offer_exposure_flag_enabled        BOOLEAN,
manual_review_approved_amount_convention     TEXT,
decline_approved_amount_convention           TEXT,
approved_el_decline_convention               TEXT,
approved_el_manual_review_convention         TEXT,
allow_approved_amount_above_requested_flag   BOOLEAN,

/* Final decision-resolution control */
failed_counteroffer_resolution               TEXT

/*
failed_counteroffer_resolution:
    Governs how preliminary COUNTEROFFER routes resolve when Section 8 determines that no
    viable reduced-exposure treatment exists.

Allowed values:
    MANUAL_REVIEW
    DECLINE

Default:
    MANUAL_REVIEW

Interpretation:
    A failed counteroffer is routed to MANUAL_REVIEW by default because higher-priority
    hard simulated policy stops, severe synthetic estimated-risk, and severe DTI have already
    routed to DECLINE before counteroffer feasibility is evaluated.

Boundary:
    This is a simulated strategy-control parameter, not production underwriting policy.
*/
```

---

## Patch 2.B — Add parameter to the insert column list

### BEFORE

```sql
approved_el_manual_review_convention,
allow_approved_amount_above_requested_flag
```

### AFTER

```sql
approved_el_manual_review_convention,
allow_approved_amount_above_requested_flag,
failed_counteroffer_resolution
```

---

## Patch 2.C — Add default value

### BEFORE

```sql
'ZERO',
'NULL_UNRESOLVED',
FALSE
```

### AFTER

```sql
'ZERO',
'NULL_UNRESOLVED',
FALSE,

/*
Failed counteroffer resolution default.

MANUAL_REVIEW is intentionally conservative and audit-readable. It avoids silently converting
all infeasible reduced-exposure cases into declines after higher-priority hard simulated policy
stop, severe synthetic estimated-risk, and severe DTI routes have already been handled.
*/
'MANUAL_REVIEW'
```

---

## Patch 3.A — Add Section 3 gatekeeper validation

Place this in Section 3.1 after the decision convention controls are validated.

```sql
/*-------------------------------------------------------------------------------------------
Gatekeeper: failed counteroffer resolution.

This parameter governs final decision resolution for preliminary COUNTEROFFER rows where
Section 8 determines that no viable reduced-exposure treatment exists.

Allowed values:
    MANUAL_REVIEW
    DECLINE

Default:
    MANUAL_REVIEW

This is a simulated strategy-control parameter. It is not production underwriting policy.
-------------------------------------------------------------------------------------------*/
IF p.failed_counteroffer_resolution IS NULL
   OR p.failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE') THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: failed_counteroffer_resolution must be MANUAL_REVIEW or DECLINE. Found: %.',
        COALESCE(p.failed_counteroffer_resolution, '<NULL>');
END IF;
```

---

# 2. Section 9 SQL only — Final Decision Resolution Layer

```sql
/***************************************************************************************************
SECTION 9 — FINAL DECISION RESOLUTION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Convert preliminary routing plus Section 8 exposure-treatment feasibility into one final simulated
    strategy outcome per synthetic applicant.

    Section 9 answers:

        "Given preliminary routing and exposure-treatment feasibility, what is the final simulated
         strategy outcome for this synthetic applicant?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_5_exposure_treatment.
    2. Preserve all prior source, lineage, strategy metadata, thresholds, segmentation, rule flags,
       preliminary routing, and exposure-treatment diagnostics.
    3. Apply final decision-resolution logic.
    4. Create final outcome fields and final exposure economics.
    5. Create final outcome flags and simulated_offer_exposure_flag.
    6. Validate final decision completeness and internal consistency.
    7. Confirm that reason-code fields, latest-run output creation, and archive persistence are still
       deferred.

WHY FINAL DECISION RESOLUTION IS SEPARATED FROM PRELIMINARY ROUTING:
    Section 7 assigns a preliminary route based on overlapping trigger flags.
    Section 8 determines whether approved exposure or reduced exposure is feasible.

    Section 9 is the first point where both pieces of information are available:
        preliminary route
        exposure-treatment feasibility

    This is why final decision_outcome is created here rather than earlier.

WHY COUNTEROFFER FEASIBILITY IS REQUIRED BEFORE FINAL COUNTEROFFER:
    A preliminary COUNTEROFFER route only means that the row should be tested for reduced-exposure
    feasibility.

    Final COUNTEROFFER requires Section 8 to confirm that the reduced exposure satisfies:
        product cap
        minimum approved amount
        minimum viable counteroffer percentage
        maximum exposure-reduction rule
        approved PTI target
        approved Expected Loss cap

WHY FAILED COUNTEROFFERS USE A GOVERNED RESOLUTION PARAMETER:
    failed_counteroffer_resolution controls whether infeasible preliminary COUNTEROFFER routes become:

        MANUAL_REVIEW
        DECLINE

    Default:
        MANUAL_REVIEW

    Rationale:
        Higher-priority hard simulated policy stops, severe synthetic estimated-risk, and severe DTI
        already route to DECLINE before counteroffer feasibility is evaluated. A failed counteroffer
        often reflects unresolved exposure, affordability, or approved Expected Loss feasibility, so
        MANUAL_REVIEW is the conservative default.

    Boundary:
        This is a simulated strategy-control parameter, not production underwriting policy.

WHY REASON CODES REMAIN DEFERRED:
    Section 9 creates final decision outcomes, but simulated reason-code prioritization should use:

        final decision_outcome
        final decision_path
        preliminary routing diagnostics
        rule trigger diagnostics
        exposure-treatment diagnostics
        counteroffer feasibility diagnostics

    Therefore reason-code assignment is built in the next section.

SIMULATED OFFER EXPOSURE BOUNDARY:
    APPROVE and COUNTEROFFER are simulated positive offer-exposure outcomes.

    simulated_offer_exposure_flag = TRUE means:
        the simulated strategy output includes positive offer exposure for the synthetic applicant.

    It does not mean:
        operational account creation
        funded exposure
        production approval
        real customer treatment

MANUAL REVIEW BOUNDARY:
    MANUAL_REVIEW remains unresolved by design.

    Final MANUAL_REVIEW rows receive NULL approved exposure, NULL approved payment, NULL approved PTI,
    and NULL approved Expected Loss.

DECLINE BOUNDARY:
    DECLINE uses the locked zero-exposure convention.

    Final DECLINE rows receive:
        approved_amount = 0
        approved_expected_loss_amount = 0

    This is a simulated no-offer exposure convention, not a production decision notice.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 9, estimated_pd is still interpreted only as the synthetic estimated-PD proxy.
    Module 2 does not recalculate estimated_pd.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Module 2 alias for Module 1 expected_loss_amount.
        This is requested-exposure Expected Loss.

    approved_expected_loss_amount:
        Final Module 2 approved-exposure Expected Loss.

    The distinction is essential because requested exposure and final approved exposure may differ.

FINAL OUTPUT BOUNDARY:
    Section 9 creates a final decision-resolution staging table only.

    It does not create:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive rows

***************************************************************************************************/



/***************************************************************************************************
SECTION 9.1 — CLEAN RESET OF SECTION 9 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_6_final_decision_resolution;



/***************************************************************************************************
SECTION 9.2 — CREATE FINAL DECISION RESOLUTION TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_6_final_decision_resolution

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_5_exposure_treatment

OUTPUT:
    All Section 8 fields plus:
        decision_outcome
        decision_path
        decision_priority_rank
        decision_resolution_source
        approval_flag
        counteroffer_flag
        manual_review_flag
        decline_flag
        simulated_offer_exposure_flag
        approved_amount
        counteroffer_amount
        exposure_reduction_flag
        exposure_reduction_amount
        exposure_reduction_pct
        approved_monthly_payment_proxy
        approved_payment_to_income_ratio
        approved_expected_loss_amount
        approved_el_reduction_amount
        approved_el_reduction_pct

IMPORTANT:
    This table does not contain simulated reason-code fields.
    Reason-code assignment is intentionally deferred to Section 10.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_6_final_decision_resolution
ON COMMIT PRESERVE ROWS
AS
WITH active_params AS (
    SELECT *
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

/*-----------------------------------------------------------------------------------------------
Attach final decision-resolution parameter.

failed_counteroffer_resolution is attached here so final decision logic does not rely on a hidden
hardcoded treatment for infeasible preliminary COUNTEROFFER routes.
-----------------------------------------------------------------------------------------------*/
decision_inputs AS (
    SELECT
        e.*,
        p.failed_counteroffer_resolution
    FROM tmp_m2_stage_5_exposure_treatment e
    CROSS JOIN active_params p
),

/*-----------------------------------------------------------------------------------------------
Final decision assignment.

This CTE creates final decision fields only.

Reason-code fields are not created here.
Final latest-run output is not created here.
Archive persistence is not created here.
-----------------------------------------------------------------------------------------------*/
decision_assignment AS (
    SELECT
        di.*,

        /*
        decision_outcome:
            Final simulated strategy outcome.

        Allowed values:
            APPROVE
            COUNTEROFFER
            MANUAL_REVIEW
            DECLINE

        This field is final within Module 2 decision-resolution logic, but it remains a simulated
        strategy outcome on synthetic applicants.
        */
        CASE
            WHEN di.preliminary_decision_outcome = 'DECLINE'
                THEN 'DECLINE'

            WHEN di.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW'

            WHEN di.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVE'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS FALSE
             AND di.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS FALSE
             AND di.failed_counteroffer_resolution = 'DECLINE'
                THEN 'DECLINE'

            ELSE 'MANUAL_REVIEW'
        END AS decision_outcome,


        /*
        decision_path:
            Final route label for the simulated strategy outcome.

        Naming discipline:
            APPROVE_AS_REQUESTED is used as the decision path for final approvals.

            APPROVED_AS_REQUESTED remains reserved for the later simulated reason-code layer,
            where it can be used as the approval primary_reason_code.
        */
        CASE
            WHEN di.preliminary_decision_outcome = 'DECLINE'
                THEN di.preliminary_decision_path

            WHEN di.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN di.preliminary_decision_path

            WHEN di.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVE_AS_REQUESTED'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBLE'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS FALSE
             AND di.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'COUNTEROFFER_NOT_FEASIBLE_REVIEW'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS FALSE
             AND di.failed_counteroffer_resolution = 'DECLINE'
                THEN 'COUNTEROFFER_NOT_FEASIBLE_DECLINE'

            ELSE 'FINAL_RESIDUAL_STRATEGY_REVIEW'
        END AS decision_path,


        /*
        decision_priority_rank:
            Carries the preliminary routing rank where a normal route is resolved.
            Uses 99 only for the residual final fallback.
        */
        CASE
            WHEN di.preliminary_decision_outcome IN ('DECLINE', 'MANUAL_REVIEW', 'APPROVE')
                THEN di.preliminary_decision_priority_rank

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS NOT NULL
                THEN di.preliminary_decision_priority_rank

            ELSE 99
        END AS decision_priority_rank,


        /*
        decision_resolution_source:
            Explains how the preliminary route and exposure-treatment feasibility resolved into
            the final simulated strategy outcome.

        This is not a reason code.
        */
        CASE
            WHEN di.preliminary_decision_outcome = 'DECLINE'
                THEN 'PRELIMINARY_DECLINE_CONFIRMED'

            WHEN di.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'PRELIMINARY_MANUAL_REVIEW_CONFIRMED'

            WHEN di.preliminary_decision_outcome = 'APPROVE'
                THEN 'PRELIMINARY_APPROVE_CONFIRMED'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBILITY_CONFIRMED'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS FALSE
             AND di.failed_counteroffer_resolution = 'MANUAL_REVIEW'
                THEN 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'

            WHEN di.preliminary_decision_outcome = 'COUNTEROFFER'
             AND di.counteroffer_feasibility_pass_flag IS FALSE
             AND di.failed_counteroffer_resolution = 'DECLINE'
                THEN 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'

            ELSE 'FINAL_RESIDUAL_FALLBACK'
        END AS decision_resolution_source

    FROM decision_inputs di
),

/*-----------------------------------------------------------------------------------------------
Final exposure economics assignment.

These final fields are derived from final decision_outcome and the Section 8 preliminary exposure
treatment fields.

No reason-code fields are created here.
-----------------------------------------------------------------------------------------------*/
final_exposure_assignment AS (
    SELECT
        da.*,

        /*
        approved_amount:
            Final simulated approved exposure.

        APPROVE:
            requested_amount

        COUNTEROFFER:
            feasible reduced exposure from Section 8

        MANUAL_REVIEW:
            NULL, unresolved by design

        DECLINE:
            0, no simulated offer exposure
        */
        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN da.requested_amount

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.approved_amount_preliminary

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_amount,

        CASE
            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.approved_amount_preliminary
            ELSE NULL::NUMERIC
        END AS counteroffer_amount,

        CASE
            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN TRUE
            ELSE FALSE
        END AS exposure_reduction_flag,

        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.requested_amount - da.approved_amount_preliminary

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN da.requested_amount

            ELSE NULL::NUMERIC
        END AS exposure_reduction_amount,

        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN (da.requested_amount - da.approved_amount_preliminary)
                     / NULLIF(da.requested_amount, 0)

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN 1.0::NUMERIC

            ELSE NULL::NUMERIC
        END AS exposure_reduction_pct,


        /*
        Final approved affordability fields.

        approved_monthly_payment_proxy:
            Simulated proportional payment proxy after final exposure treatment.

        approved_payment_to_income_ratio:
            Simulated post-exposure-treatment affordability ratio.

        These are not contractual payment schedules.
        */
        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN da.requested_monthly_payment_proxy

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.approved_monthly_payment_proxy_preliminary

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_monthly_payment_proxy,

        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN da.requested_payment_to_income_ratio

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.approved_payment_to_income_ratio_preliminary

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_payment_to_income_ratio,


        /*
        Final approved Expected Loss fields.

        requested_expected_loss_amount:
            Module 1 requested-exposure Expected Loss.

        approved_expected_loss_amount:
            Module 2 final approved-exposure Expected Loss.

        estimated_pd remains the Module 1 synthetic estimated-PD proxy input.
        */
        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN da.requested_expected_loss_amount

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.approved_expected_loss_amount_preliminary

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            ELSE NULL::NUMERIC
        END AS approved_expected_loss_amount,

        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN da.requested_expected_loss_amount - da.approved_expected_loss_amount_preliminary

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN da.requested_expected_loss_amount

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_amount,

        CASE
            WHEN da.decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN da.decision_outcome = 'COUNTEROFFER'
                THEN (
                    da.requested_expected_loss_amount - da.approved_expected_loss_amount_preliminary
                ) / NULLIF(da.requested_expected_loss_amount, 0)

            WHEN da.decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN da.decision_outcome = 'DECLINE'
                THEN CASE
                    WHEN da.requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_pct

    FROM decision_assignment da
),

/*-----------------------------------------------------------------------------------------------
Final outcome flags.

These flags reconcile directly to final decision_outcome.

simulated_offer_exposure_flag:
    TRUE for APPROVE and COUNTEROFFER.
    FALSE for MANUAL_REVIEW and DECLINE.

This is a simulated strategy exposure flag only.
It does not imply operational account creation or real customer treatment.
-----------------------------------------------------------------------------------------------*/
final_flags AS (
    SELECT
        fea.*,

        (fea.decision_outcome = 'APPROVE') AS approval_flag,
        (fea.decision_outcome = 'COUNTEROFFER') AS counteroffer_flag,
        (fea.decision_outcome = 'MANUAL_REVIEW') AS manual_review_flag,
        (fea.decision_outcome = 'DECLINE') AS decline_flag,

        (fea.decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
            AS simulated_offer_exposure_flag

    FROM final_exposure_assignment fea
)

SELECT *
FROM final_flags;



/***************************************************************************************************
SECTION 9.3 — LOCAL FAIL-FAST CHECKS FOR FINAL DECISION RESOLUTION
****************************************************************************************************

PURPOSE:
    Validate the Section 9 final decision-resolution layer before simulated reason-code assignment,
    latest-run output creation, or archive persistence is built.

IMPORTANT:
    These are local staging gatekeepers only.

    They are not the full Module 2 QA framework.
    They are not reason-code validation.
    They are not archive validation.

***************************************************************************************************/

DO $$
DECLARE
    v_stage5_count BIGINT;
    v_stage6_count BIGINT;
    v_stage6_distinct_app_count BIGINT;

    v_duplicate_application_count BIGINT;
    v_final_decision_completeness_failure_count BIGINT;
    v_final_flag_reconciliation_failure_count BIGINT;

    v_approve_convention_failure_count BIGINT;
    v_counteroffer_convention_failure_count BIGINT;
    v_manual_review_convention_failure_count BIGINT;
    v_decline_convention_failure_count BIGINT;
    v_failed_counteroffer_resolution_failure_count BIGINT;

    v_forbidden_reason_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 8 to Section 9.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage5_count
    FROM tmp_m2_stage_5_exposure_treatment;

    SELECT COUNT(*)
    INTO v_stage6_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_count <> v_stage5_count THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: row count changed from Section 8 to Section 9. Stage 5 rows: %, Stage 6 rows: %.',
            v_stage5_count,
            v_stage6_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage6_distinct_app_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    IF v_stage6_distinct_app_count <> v_stage6_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_6_final_decision_resolution
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 9 failure: application_id uniqueness was not preserved. Stage 6 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage6_count,
            v_stage6_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final decision fields must be complete and valid.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_final_decision_completeness_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome IS NULL
       OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
       OR decision_path IS NULL
       OR NULLIF(BTRIM(decision_path), '') IS NULL
       OR decision_priority_rank IS NULL
       OR decision_priority_rank <= 0
       OR decision_resolution_source IS NULL
       OR NULLIF(BTRIM(decision_resolution_source), '') IS NULL
       OR failed_counteroffer_resolution IS NULL
       OR failed_counteroffer_resolution NOT IN ('MANUAL_REVIEW', 'DECLINE');

    IF v_final_decision_completeness_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % row(s) have null or invalid final decision-resolution fields.',
            v_final_decision_completeness_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final flags must reconcile to decision_outcome.

    Exactly one final outcome flag must be TRUE per row.
    simulated_offer_exposure_flag must be TRUE only for APPROVE and COUNTEROFFER.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_final_flag_reconciliation_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
          ) <> 1
       OR approval_flag
          IS DISTINCT FROM (decision_outcome = 'APPROVE')
       OR counteroffer_flag
          IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
       OR manual_review_flag
          IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
       OR decline_flag
          IS DISTINCT FROM (decision_outcome = 'DECLINE')
       OR simulated_offer_exposure_flag
          IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'));

    IF v_final_flag_reconciliation_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % row(s) have final flag reconciliation failures.',
            v_final_flag_reconciliation_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final APPROVE convention.

    APPROVE is a simulated approval-as-requested strategy outcome.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approve_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'APPROVE'
      AND (
            approved_amount IS DISTINCT FROM requested_amount
         OR counteroffer_amount IS NOT NULL
         OR exposure_reduction_flag IS DISTINCT FROM FALSE
         OR exposure_reduction_amount IS DISTINCT FROM 0::NUMERIC
         OR exposure_reduction_pct IS DISTINCT FROM 0::NUMERIC
         OR approved_monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
         OR approved_payment_to_income_ratio IS DISTINCT FROM requested_payment_to_income_ratio
         OR approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_amount IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_pct IS DISTINCT FROM 0::NUMERIC
         OR simulated_offer_exposure_flag IS DISTINCT FROM TRUE
         OR decision_path <> 'APPROVE_AS_REQUESTED'
      );

    IF v_approve_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final APPROVE row(s) violate approval-as-requested conventions.',
            v_approve_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final COUNTEROFFER convention.

    COUNTEROFFER requires a feasible Section 8 reduced-exposure treatment.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
         OR approved_amount IS NULL
         OR approved_amount <= 0
         OR approved_amount >= requested_amount
         OR counteroffer_amount IS DISTINCT FROM approved_amount
         OR exposure_reduction_flag IS DISTINCT FROM TRUE
         OR exposure_reduction_amount IS DISTINCT FROM (requested_amount - approved_amount)
         OR exposure_reduction_pct IS DISTINCT FROM (
                exposure_reduction_amount / NULLIF(requested_amount, 0)
            )
         OR approved_monthly_payment_proxy IS NULL
         OR approved_payment_to_income_ratio IS NULL
         OR approved_expected_loss_amount IS NULL
         OR approved_expected_loss_amount > product_approved_el_cap
         OR approved_payment_to_income_ratio > counteroffer_target_pti
         OR approved_amount < product_min_approved_amount
         OR approved_amount > product_max_approved_amount
         OR approved_amount < requested_amount * product_min_counteroffer_pct
         OR approved_amount < requested_amount * (1.0 - product_max_exposure_reduction_pct)
         OR approved_el_reduction_amount IS NULL
         OR simulated_offer_exposure_flag IS DISTINCT FROM TRUE
         OR decision_path <> 'COUNTEROFFER_FEASIBLE'
      );

    IF v_counteroffer_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final COUNTEROFFER row(s) violate feasible counteroffer conventions.',
            v_counteroffer_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final MANUAL_REVIEW convention.

    Manual review remains unresolved by design.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            approved_amount IS NOT NULL
         OR counteroffer_amount IS NOT NULL
         OR exposure_reduction_flag IS DISTINCT FROM FALSE
         OR exposure_reduction_amount IS NOT NULL
         OR exposure_reduction_pct IS NOT NULL
         OR approved_monthly_payment_proxy IS NOT NULL
         OR approved_payment_to_income_ratio IS NOT NULL
         OR approved_expected_loss_amount IS NOT NULL
         OR approved_el_reduction_amount IS NOT NULL
         OR approved_el_reduction_pct IS NOT NULL
         OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
      );

    IF v_manual_review_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final MANUAL_REVIEW row(s) violate unresolved-review conventions.',
            v_manual_review_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final DECLINE convention.

    DECLINE uses the locked zero-exposure convention.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decline_convention_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE decision_outcome = 'DECLINE'
      AND (
            approved_amount IS DISTINCT FROM 0::NUMERIC
         OR counteroffer_amount IS NOT NULL
         OR exposure_reduction_flag IS DISTINCT FROM FALSE
         OR exposure_reduction_amount IS DISTINCT FROM requested_amount
         OR exposure_reduction_pct IS DISTINCT FROM 1.0::NUMERIC
         OR approved_monthly_payment_proxy IS DISTINCT FROM 0::NUMERIC
         OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
         OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_amount IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_pct IS DISTINCT FROM CASE
                WHEN requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                ELSE 0::NUMERIC
            END
         OR simulated_offer_exposure_flag IS DISTINCT FROM FALSE
      );

    IF v_decline_convention_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % final DECLINE row(s) violate zero-exposure conventions.',
            v_decline_convention_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: failed counteroffer resolution.

    Infeasible preliminary COUNTEROFFER rows must resolve according to failed_counteroffer_resolution.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_failed_counteroffer_resolution_failure_count
    FROM tmp_m2_stage_6_final_decision_resolution
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND (
            (
                failed_counteroffer_resolution = 'MANUAL_REVIEW'
                AND NOT (
                    decision_outcome = 'MANUAL_REVIEW'
                    AND decision_path = 'COUNTEROFFER_NOT_FEASIBLE_REVIEW'
                    AND decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW'
                )
            )
            OR
            (
                failed_counteroffer_resolution = 'DECLINE'
                AND NOT (
                    decision_outcome = 'DECLINE'
                    AND decision_path = 'COUNTEROFFER_NOT_FEASIBLE_DECLINE'
                    AND decision_resolution_source = 'COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE'
                )
            )
      );

    IF v_failed_counteroffer_resolution_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: % failed preliminary COUNTEROFFER row(s) do not resolve according to failed_counteroffer_resolution.',
            v_failed_counteroffer_resolution_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: reason-code fields must not exist yet.

    Reason-code assignment belongs to the next section.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_reason_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_6_final_decision_resolution'::REGCLASS
      AND attnum > 0
      AND NOT attisdropped
      AND attname IN (
            'primary_reason_code',
            'secondary_reason_code',
            'tertiary_reason_code',
            'triggered_reason_code_list',
            'reason_priority_rank',
            'primary_reason_family'
      );

    IF v_forbidden_reason_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: reason-code field(s) were created before the reason-code assignment section.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final latest-run output table must not exist yet.

    Section 9 creates a temporary final decision-resolution staging table only.
    The permanent latest-run strategy output is created in a later section.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 9 failure: final latest-run strategy_decisions table exists before the final output section.';
    END IF;

    /*
    Archive note:
        Section 9 contains no INSERT, DELETE, TRUNCATE, or CREATE logic for
        credit_decisioning_sim.strategy_decisions_archive.

        Archive persistence remains deferred to a later section.
    */
END $$;



/***************************************************************************************************
SECTION 9.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 9 final decision-resolution staging layer.

IMPORTANT:
    These are not full Module 2 QA outputs.
    These should not be treated as the final Validation Summary evidence set.

    Full decision distribution, reason-code coverage, approved-book analysis, archive validation,
    and matched strategy comparison QA will be built later.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
9.4.1 Count by decision_outcome.

Interpretation:
    This is the first final simulated strategy outcome distribution, but it remains a staging
    diagnostic until latest-run output and full QA are built.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.2 Count by decision_path.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_path,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_path
ORDER BY decision_path;


/*-----------------------------------------------------------------------------------------------
9.4.3 Count by decision_resolution_source.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_resolution_source,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_resolution_source
ORDER BY decision_resolution_source;


/*-----------------------------------------------------------------------------------------------
9.4.4 Count by simulated_offer_exposure_flag.

Interpretation:
    simulated_offer_exposure_flag = TRUE for APPROVE and COUNTEROFFER.
    It does not imply operational account creation or real customer treatment.
-----------------------------------------------------------------------------------------------*/
SELECT
    simulated_offer_exposure_flag,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY simulated_offer_exposure_flag
ORDER BY simulated_offer_exposure_flag;


/*-----------------------------------------------------------------------------------------------
9.4.5 Preliminary decision outcome × final decision outcome.

Purpose:
    Shows how Section 8 feasibility and Section 9 final resolution changed preliminary routing.
-----------------------------------------------------------------------------------------------*/
SELECT
    preliminary_decision_outcome,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    preliminary_decision_outcome,
    decision_outcome
ORDER BY
    preliminary_decision_outcome,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.6 Exposure treatment status × final decision outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_treatment_status,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    exposure_treatment_status,
    decision_outcome
ORDER BY
    exposure_treatment_status,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.7 Counteroffer feasibility pass flag × final decision outcome.

NULL appears for rows that were not preliminary COUNTEROFFER routes.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_feasibility_pass_flag,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    counteroffer_feasibility_pass_flag,
    decision_outcome
ORDER BY
    counteroffer_feasibility_pass_flag,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.8 Counteroffer feasibility failure reason × final decision outcome.

Interpretation:
    counteroffer_feasibility_failure_reason is a feasibility diagnostic, not a final reason code.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_feasibility_failure_reason,
    decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    counteroffer_feasibility_failure_reason,
    decision_outcome
ORDER BY
    counteroffer_feasibility_failure_reason,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.9 Product × decision_outcome.
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
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    product_type_policy_key,
    decision_outcome
ORDER BY
    product_type_policy_key,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.10 Score band × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.11 Strategy risk tier × decision_outcome.

Interpretation:
    strategy_risk_tier uses estimated_pd as the synthetic estimated-PD proxy input.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.12 Requested PTI bucket × decision_outcome.

Interpretation:
    requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.13 Requested exposure tier × decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount) AS avg_approved_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    requested_exposure_tier,
    decision_outcome
ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'WITHIN_PRODUCT_LIMITS' THEN 2
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 4
        ELSE 99
    END,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.14 Requested Expected Loss tier × decision_outcome.

Interpretation:
    requested_expected_loss_amount uses requested exposure.
    approved_expected_loss_amount uses final approved exposure.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_expected_loss_tier,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    requested_expected_loss_tier,
    decision_outcome
ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.15 Mixed-signal profile × decision_outcome.

Interpretation:
    mixed_signal_profile_type remains diagnostic. It is not a reason code.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_6_final_decision_resolution
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
9.4.16 Borderline profile flag × decision_outcome.

Interpretation:
    borderline_profile_flag uses governed threshold proximity logic. It is not a reason code.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY
    borderline_profile_flag,
    decision_outcome
ORDER BY
    borderline_profile_flag,
    decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.17 Average requested_amount by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    MIN(requested_amount) AS min_requested_amount,
    MAX(requested_amount) AS max_requested_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.18 Average approved_amount by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(approved_amount) AS avg_approved_amount,
    MIN(approved_amount) AS min_approved_amount,
    MAX(approved_amount) AS max_approved_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.19 Average requested_payment_to_income_ratio by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    MIN(requested_payment_to_income_ratio) AS min_requested_payment_to_income_ratio,
    MAX(requested_payment_to_income_ratio) AS max_requested_payment_to_income_ratio
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.20 Average approved_payment_to_income_ratio by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    MIN(approved_payment_to_income_ratio) AS min_approved_payment_to_income_ratio,
    MAX(approved_payment_to_income_ratio) AS max_approved_payment_to_income_ratio
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.21 Average requested_expected_loss_amount by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    MIN(requested_expected_loss_amount) AS min_requested_expected_loss_amount,
    MAX(requested_expected_loss_amount) AS max_requested_expected_loss_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.22 Average approved_expected_loss_amount by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount,
    MIN(approved_expected_loss_amount) AS min_approved_expected_loss_amount,
    MAX(approved_expected_loss_amount) AS max_approved_expected_loss_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
9.4.23 Final offer-exposure profile.

Purpose:
    Summarizes simulated positive offer exposure without implying operational account creation.
-----------------------------------------------------------------------------------------------*/
SELECT
    simulated_offer_exposure_flag,
    COUNT(*) AS row_count,
    SUM(approved_amount) AS total_approved_amount,
    AVG(approved_amount) AS avg_approved_amount,
    SUM(approved_expected_loss_amount) AS total_approved_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM tmp_m2_stage_6_final_decision_resolution
GROUP BY simulated_offer_exposure_flag
ORDER BY simulated_offer_exposure_flag;


/***************************************************************************************************
END OF SECTION 9 — FINAL DECISION RESOLUTION LAYER

If execution reaches this point:
    1. tmp_m2_stage_6_final_decision_resolution exists.
    2. All Section 8 fields have been preserved.
    3. Module 1 lineage remains attached.
    4. Module 2 strategy metadata remains attached.
    5. Final decision_outcome is populated for every row.
    6. Final decision_path is populated for every row.
    7. Final decision_priority_rank is populated for every row.
    8. Final decision_resolution_source is populated for every row.
    9. Final approval / counteroffer / manual review / decline flags reconcile to decision_outcome.
    10. simulated_offer_exposure_flag reconciles to APPROVE and COUNTEROFFER outcomes.
    11. Final approved exposure fields are populated according to outcome convention.
    12. Final approved payment and approved PTI fields are populated according to outcome convention.
    13. Final approved Expected Loss fields are populated according to outcome convention.
    14. Failed counteroffers resolve according to failed_counteroffer_resolution.

No simulated reason codes have been assigned.
No primary_reason_code has been created.
No secondary_reason_code has been created.
No tertiary_reason_code has been created.
No triggered_reason_code_list has been created.
No reason_priority_rank has been created.
No final latest-run strategy output table has been created.
No strategy archive rows have been inserted.

***************************************************************************************************/
```

---

# 3. What Section 9 establishes

Section 9 creates:

```text
tmp_m2_stage_6_final_decision_resolution
```

It resolves preliminary routing plus Section 8 exposure feasibility into final simulated strategy outcomes:

```text
APPROVE
COUNTEROFFER
MANUAL_REVIEW
DECLINE
```

It also creates final flags, final approved exposure fields, final approved payment / PTI fields, final approved Expected Loss fields, and `simulated_offer_exposure_flag`.

---

# 4. What Section 9 intentionally does not build

Section 9 does not assign simulated reason codes, create the final latest-run table, insert archive rows, or build the full QA framework.

Reason-code assignment is intentionally deferred so it can use final decision outcomes, final decision paths, rule triggers, preliminary routing diagnostics, and exposure-treatment diagnostics.

---

# 5. Recommended next build step

Next should be:

```text
Section 10 — Simulated Reason-Code Assignment Layer
```

That section should add:

```text
primary_reason_code
secondary_reason_code
tertiary_reason_code
primary_reason_family
triggered_reason_code_list
reason_priority_rank
```

It should use deterministic priority logic, and it should preserve the boundary that these are simulated strategy explanation codes, not regulatory adverse-action reason codes.
<!-- END_MESSAGE C038-M00129 -->


---

<a id="c038-m00130"></a>

### C038-M00130

**Andrew** · 2026-05-06T14:06:57.573000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00130 -->
This is strong. I agree with the Section 9 Final Decision Resolution Layer.

Section 9 should be treated as provisionally accepted, subject to the pre-flight review below.

Section 9 correctly:
- adds the governed failed_counteroffer_resolution parameter
- resolves preliminary routing plus Section 8 exposure feasibility into final simulated strategy outcomes
- creates final decision_outcome
- creates final decision_path
- creates decision_priority_rank
- creates decision_resolution_source
- creates final approval_flag, counteroffer_flag, manual_review_flag, and decline_flag
- creates simulated_offer_exposure_flag
- creates final approved_amount and counteroffer_amount
- creates final approved_monthly_payment_proxy and approved_payment_to_income_ratio
- creates final approved_expected_loss_amount
- preserves requested_expected_loss_amount as requested-exposure Expected Loss
- preserves preliminary routing diagnostics
- preserves counteroffer feasibility diagnostics
- keeps MANUAL_REVIEW unresolved
- uses the locked zero-exposure convention for DECLINE
- does not assign reason codes
- does not create the final latest-run output table
- does not insert archive rows
- does not build the full QA framework

Do not rewrite Sections 0–9 unless the pre-flight review identifies a specific dependency issue.

================================================================================
1. SECTION 9 PRE-FLIGHT REVIEW BEFORE SECTION 10
================================================================================

Before writing Section 10, please do a targeted pre-flight review of Section 9.

Confirm that Section 9 includes the following final decision fields:

- decision_outcome
- decision_path
- decision_priority_rank
- decision_resolution_source

Confirm that Section 9 includes the following final flags:

- approval_flag
- counteroffer_flag
- manual_review_flag
- decline_flag
- simulated_offer_exposure_flag

Confirm that Section 9 includes the following final exposure fields:

- approved_amount
- counteroffer_amount
- exposure_reduction_flag
- exposure_reduction_amount
- exposure_reduction_pct

Confirm that Section 9 includes the following final affordability fields:

- approved_monthly_payment_proxy
- approved_payment_to_income_ratio

Confirm that Section 9 includes the following final economics fields:

- approved_expected_loss_amount
- approved_el_reduction_amount
- approved_el_reduction_pct

Also confirm that Section 9 does NOT create:

- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- triggered_reason_code_list
- primary_reason_family
- reason_priority_rank
- reason_code_count
- final latest-run output table
- archive insert logic
- full QA framework

If the pre-flight review finds an issue, provide a targeted BEFORE / AFTER patch only.

If no issue is found, explicitly state:

“Section 9 pre-flight review passed; no patch required.”

================================================================================
2. LABEL ALIGNMENT REQUIREMENT BEFORE SECTION 10
================================================================================

Before writing Section 10, please list the exact string values currently created by Sections 8 and 9 for:

Section 8:
- counteroffer_feasibility_failure_reason
- exposure_treatment_status
- exposure_treatment_path

Section 9:
- decision_outcome
- decision_path
- decision_resolution_source

Reason:
Section 10 should not invent new string labels that are close but not identical to prior section values.

For example, if Section 8 uses:

- COUNTEROFFER_PTI_STILL_ABOVE_TARGET

then Section 10 should reference that exact string, not a similar alternative such as:

- COUNTEROFFER_EXCEEDS_TARGET_PTI

Likewise, if Section 8 uses:

- COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT

then Section 10 should not reference:

- COUNTEROFFER_BELOW_MINIMUM_REQUEST_PERCENT

unless the earlier Section 8 label is patched.

Important:
If you find label mismatches, provide a targeted label-alignment patch before writing Section 10.

Do not proceed with reason-code assignment using inconsistent labels.

================================================================================
3. NEXT BUILD SCOPE: SECTION 10 ONLY
================================================================================

After the Section 9 pre-flight review and label-alignment review, please build only:

SECTION 10 — SIMULATED REASON-CODE ASSIGNMENT LAYER

Recommended staged table:

tmp_m2_stage_7_reason_code_assignment

Section 10 should consume:

tmp_m2_stage_6_final_decision_resolution

Do not build:
- final latest-run strategy_decisions table
- archive insert logic
- full QA framework
- matched strategy comparison queries
- BRD or Validation Summary documentation

Those belong to later sections.

================================================================================
4. SECTION 10 OBJECTIVE
================================================================================

Section 10 should assign simulated strategy explanation codes based on:

- final decision_outcome
- final decision_path
- decision_resolution_source
- preliminary routing diagnostics
- Section 6 rule-trigger flags
- Section 8 counteroffer feasibility diagnostics
- exposure-treatment diagnostics
- mixed-signal diagnostics
- borderline diagnostics

Section 10 should answer:

“Why did this synthetic applicant receive this simulated strategy outcome?”

Section 10 should not answer:

“Was this a regulatory adverse-action reason?”

Reason codes in Module 2 are simulated strategy explanation codes only.

They support:
- transparency
- QA review
- strategy interpretation
- portfolio diagnostics
- decision-path traceability

They do not support:
- production adverse-action notices
- regulatory compliance conclusions
- fair lending conclusions
- customer communication
- real-world underwriting decisions

================================================================================
5. REASON-CODE BOUNDARY
================================================================================

Reason codes are NOT:
- adverse-action reasons
- regulatory decision notices
- compliance-approved reason codes
- production customer communications
- fair lending conclusions
- final underwriting explanations for real applicants

Reason codes ARE:
- simulated strategy explanation codes
- audit and QA aids
- decision-path transparency fields
- segmentation and portfolio interpretation fields
- synthetic policy-simulation diagnostics

Please use neutral language throughout Section 10.

Preferred terms:
- simulated reason code
- strategy explanation code
- policy stop reason
- review trigger reason
- counteroffer reason
- approval explanation code

Avoid:
- adverse action
- regulatory reason
- customer notice
- compliance reason
- real customer treatment

================================================================================
6. REQUIRED SECTION 10 OUTPUT FIELDS
================================================================================

Section 10 should preserve all fields from tmp_m2_stage_6_final_decision_resolution and add:

- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- primary_reason_family
- triggered_reason_code_list
- reason_priority_rank
- reason_code_count

The reason-code fields should be deterministic and auditable.

Do not create final latest-run output yet.

Do not insert archive rows yet.

================================================================================
7. REASON-CODE IMPLEMENTATION PATTERN
================================================================================

Please avoid one giant opaque CASE block if possible.

Recommended implementation pattern:

1. reason_candidate_base
   Preserve the Section 9 final decision record.

2. reason_candidates
   Create one row per application_id per candidate simulated reason code.

   Suggested fields:
   - application_id
   - candidate_reason_code
   - candidate_reason_family
   - candidate_reason_priority_rank
   - candidate_reason_source

3. ranked_reasons
   Use ROW_NUMBER() over each application_id ordered by:
   - candidate_reason_priority_rank
   - candidate_reason_code

4. reason_pivot
   Pivot the ranked candidate reasons into:
   - primary_reason_code
   - secondary_reason_code
   - tertiary_reason_code
   - primary_reason_family
   - reason_priority_rank
   - triggered_reason_code_list
   - reason_code_count

5. final reason-code assignment table
   Join reason_pivot back to tmp_m2_stage_6_final_decision_resolution.

Reason:
This pattern keeps reason-code assignment transparent, auditable, and extensible.

Important:
Reason-code candidates should be filtered by final decision_outcome so the primary reason always belongs to the correct outcome family.

================================================================================
8. REASON PRIORITY RANKING CONVENTION
================================================================================

Use deterministic priority ranges by outcome family.

Recommended ranges:

DECLINE:
- 100–199

MANUAL_REVIEW:
- 300–399

COUNTEROFFER:
- 500–599

APPROVAL:
- 900–999

Reason:
This makes the ranking structure auditable and prevents mixed interpretation across outcomes.

The primary reason should be the lowest candidate_reason_priority_rank for the row after outcome-specific filtering.

reason_priority_rank should equal the primary candidate_reason_priority_rank.

================================================================================
9. APPROVE REASON-CODE CONVENTION
================================================================================

For final decision_outcome = APPROVE:

Required primary reason:
- APPROVED_AS_REQUESTED

Recommended family:
- APPROVAL

Recommended priority rank:
- 900

Expected behavior:
- primary_reason_code = APPROVED_AS_REQUESTED
- primary_reason_family = APPROVAL
- secondary_reason_code = NULL
- tertiary_reason_code = NULL
- triggered_reason_code_list should include APPROVED_AS_REQUESTED
- reason_code_count should equal 1 unless we explicitly design approval diagnostics later

APPROVE rows should not receive decline, counteroffer, or manual-review reason codes.

================================================================================
10. COUNTEROFFER REASON-CODE CONVENTION
================================================================================

For final decision_outcome = COUNTEROFFER:

Primary reason should explain the main driver of reduced-exposure treatment.

Recommended candidate reason codes, in priority order:

1. COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
   Use when:
   - exposure_counteroffer_candidate_flag = TRUE
   - requested_exposure_above_product_cap_flag = TRUE
   - or exposure_treatment_path indicates product-cap constraint

2. COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
   Use when:
   - counteroffer_affordability_candidate_flag = TRUE
   - requested_pti_counteroffer_candidate_flag = TRUE
   - or approved exposure was reduced to satisfy counteroffer_target_pti

3. COUNTEROFFER_EXPECTED_LOSS_LIMIT
   Use when:
   - counteroffer_expected_loss_candidate_flag = TRUE
   - or approved exposure was reduced to satisfy product_approved_el_cap

4. COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT
   Use when:
   - counteroffer_risk_band_eligible_flag = TRUE
   - or the counteroffer route was driven by elevated synthetic estimated-risk but not severe-risk decline

5. COUNTEROFFER_MULTIPLE_CONSTRAINTS
   Use when multiple counteroffer candidate families are active.

Important:
COUNTEROFFER_MULTIPLE_CONSTRAINTS should generally be secondary or tertiary unless we explicitly decide it should override specific drivers.

Recommended family:
- COUNTEROFFER

COUNTEROFFER rows should not receive approval, manual-review, or decline primary reason codes.

================================================================================
11. MANUAL REVIEW REASON-CODE CONVENTION
================================================================================

For final decision_outcome = MANUAL_REVIEW:

Primary reason should explain why the record remains unresolved.

Important refinement:
Specific failed-counteroffer reasons should rank above the generic failed-counteroffer reason.

Recommended candidate reason codes, in priority order:

1. MANUAL_REVIEW_COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT
   Use when:
   - counteroffer_feasibility_failure_reason = COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT

2. MANUAL_REVIEW_COUNTEROFFER_PTI_TARGET_NOT_MET
   Use when:
   - counteroffer_feasibility_failure_reason = COUNTEROFFER_PTI_STILL_ABOVE_TARGET

3. MANUAL_REVIEW_COUNTEROFFER_APPROVED_EL_ABOVE_CAP
   Use when:
   - counteroffer_feasibility_failure_reason = COUNTEROFFER_APPROVED_EL_ABOVE_CAP

4. MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER
   Use when counteroffer_feasibility_failure_reason indicates:
   - COUNTEROFFER_ROUNDED_AMOUNT_NULL
   - COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE
   - COUNTEROFFER_BELOW_PRODUCT_MINIMUM
   - COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT
   - COUNTEROFFER_EXCEEDS_MAX_REDUCTION

5. MANUAL_REVIEW_COUNTEROFFER_NOT_FEASIBLE
   Use when:
   - preliminary_decision_outcome = COUNTEROFFER
   - counteroffer_feasibility_pass_flag = FALSE
   - failed_counteroffer_resolution = MANUAL_REVIEW
   - and no more specific failed-counteroffer reason above applies

6. MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK
   Use when:
   - manual_review_borderline_trigger_flag = TRUE
   - or borderline_profile_flag = TRUE and strategy_risk_tier is elevated / high

7. MANUAL_REVIEW_BORDERLINE_AFFORDABILITY
   Use when:
   - borderline_profile_flag = TRUE and requested_pti_bucket is elevated / high

8. MANUAL_REVIEW_MIXED_SIGNAL_PROFILE
   Use when:
   - manual_review_mixed_signal_trigger_flag = TRUE
   - or mixed_signal_profile_type is not NO_MIXED_SIGNAL_PROFILE

9. MANUAL_REVIEW_REQUESTED_STRUCTURE
   Use when:
   - severe_requested_structure_trigger_flag = TRUE
   - or requested exposure / requested PTI / requested EL structure is elevated but not a hard stop

10. MANUAL_REVIEW_ELEVATED_SYNTHETIC_RISK
    Use when:
    - manual_review_risk_trigger_flag = TRUE

11. MANUAL_REVIEW_ELEVATED_DTI
    Use when:
    - manual_review_dti_trigger_flag = TRUE

12. MANUAL_REVIEW_EXPECTED_LOSS
    Use when:
    - manual_review_expected_loss_trigger_flag = TRUE

13. MANUAL_REVIEW_RESIDUAL_STRATEGY_REVIEW
    Use for residual manual-review fallback rows.

Recommended family:
- MANUAL_REVIEW

MANUAL_REVIEW rows should not receive approval, counteroffer, or decline primary reason codes.

================================================================================
12. DECLINE REASON-CODE CONVENTION
================================================================================

For final decision_outcome = DECLINE:

Primary reason should explain the simulated policy stop or final no-offer path.

Recommended candidate reason codes, in priority order:

1. POLICY_STOP_BANKRUPTCY_FLAG
   Use when:
   - bankruptcy_policy_stop_flag = TRUE

2. POLICY_STOP_MAJOR_DEROGATORY
   Use when:
   - major_derogatory_policy_stop_flag = TRUE

3. POLICY_STOP_RECENT_DELINQUENCY
   Use when:
   - severe_delinquency_policy_stop_flag = TRUE

4. POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY
   Use when:
   - synthetic_risk_decline_trigger_flag = TRUE
   - or decision_path = SEVERE_SYNTHETIC_RISK

5. POLICY_STOP_HIGH_DTI
   Use when:
   - dti_decline_trigger_flag = TRUE
   - or decision_path = SEVERE_DTI_CAPACITY

6. POLICY_STOP_COUNTEROFFER_NOT_FEASIBLE
   Use when:
   - preliminary_decision_outcome = COUNTEROFFER
   - counteroffer_feasibility_pass_flag = FALSE
   - failed_counteroffer_resolution = DECLINE

7. POLICY_STOP_EXPECTED_LOSS_UNRESOLVED
   Use when:
   - requested_el_decline_trigger_flag = TRUE
   - and no higher-priority decline reason applies

8. POLICY_STOP_EXPOSURE_LIMIT_UNRESOLVED
   Use when:
   - requested_exposure_extreme_flag = TRUE
   - or exposure_policy_stop_candidate_flag = TRUE
   - and no higher-priority decline reason applies

9. POLICY_STOP_RESIDUAL_DECLINE
   Use only as a fallback if decision_outcome = DECLINE and no other decline reason applies.

Recommended family:
- POLICY_STOP

DECLINE rows should not receive approval or counteroffer primary reason codes.

================================================================================
13. TRIGGERED REASON LIST CONVENTION
================================================================================

triggered_reason_code_list should include all candidate reason codes that apply to the row after filtering to the final decision_outcome family.

Recommended implementation:
- Use STRING_AGG(candidate_reason_code, ' | ' ORDER BY candidate_reason_priority_rank, candidate_reason_code)

Reason:
The list should be deterministic, readable, and useful for QA.

================================================================================
14. SECONDARY AND TERTIARY REASON CONVENTION
================================================================================

For each row:

- primary_reason_code = candidate reason rank 1
- secondary_reason_code = candidate reason rank 2
- tertiary_reason_code = candidate reason rank 3

If fewer than three candidate reasons exist:
- unused fields should be NULL

Interpretation:
Secondary and tertiary reasons provide additional diagnostics only.

They do not change the final decision_outcome.

================================================================================
15. SECTION 10 LOCAL GATEKEEPERS
================================================================================

At the end of Section 10, include local fail-fast checks.

Validate:

1. Structural preservation
- row count is unchanged from tmp_m2_stage_6_final_decision_resolution
- application_id remains unique

2. Required reason-code completeness
- primary_reason_code is non-null for every row
- primary_reason_family is non-null for every row
- reason_priority_rank is non-null for every row
- triggered_reason_code_list is non-null for every row
- reason_code_count is non-null and >= 1 for every row

3. Decision-outcome alignment
For decision_outcome = APPROVE:
- primary_reason_code = APPROVED_AS_REQUESTED
- primary_reason_family = APPROVAL
- reason_code_count = 1 unless approval diagnostics are explicitly added

For decision_outcome = COUNTEROFFER:
- primary_reason_family = COUNTEROFFER
- primary_reason_code starts with COUNTEROFFER_

For decision_outcome = MANUAL_REVIEW:
- primary_reason_family = MANUAL_REVIEW
- primary_reason_code starts with MANUAL_REVIEW_

For decision_outcome = DECLINE:
- primary_reason_family = POLICY_STOP
- primary_reason_code starts with POLICY_STOP_

4. Outcome-family leakage prevention
- APPROVE rows should not have primary counteroffer, manual-review, or policy-stop reasons
- COUNTEROFFER rows should not have primary approval, manual-review, or policy-stop reasons
- MANUAL_REVIEW rows should not have primary approval, counteroffer, or policy-stop reasons
- DECLINE rows should not have primary approval, counteroffer, or manual-review reasons

5. No final output / archive yet
Validate or explicitly confirm:
- no final latest-run strategy output table is created yet
- no strategy archive rows are inserted yet

These are Section 10 local staging gatekeepers only, not full Module 2 QA.

================================================================================
16. SECTION 10 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight staging diagnostics.

Suggested checks:

1. Count by decision_outcome × primary_reason_code
2. Count by decision_outcome × primary_reason_family
3. Count by primary_reason_code
4. Count by primary_reason_family
5. Average reason_code_count by decision_outcome
6. Count by secondary_reason_code
7. Count by tertiary_reason_code
8. Product × primary_reason_code
9. Score band × primary_reason_code
10. Strategy risk tier × primary_reason_code
11. Requested PTI bucket × primary_reason_code
12. Decision path × primary_reason_code
13. Counteroffer feasibility failure reason × primary_reason_code
14. Mixed-signal profile × primary_reason_code
15. Borderline profile flag × primary_reason_code

These are staging diagnostics only.
They should not be interpreted as full final strategy validation yet.

================================================================================
17. SECTION 10 COMMENTARY QUALITY
================================================================================

Please maintain the elite commentary standard.

Section 10 comments should explain:

- why reason-code assignment is separated from final decision resolution
- why reason codes are simulated strategy explanation codes only
- why reason codes are not regulatory adverse-action reasons
- why outcome-specific filtering is required
- why the candidate / ranking / pivot pattern is used instead of one opaque CASE block
- why approvals receive APPROVED_AS_REQUESTED
- why counteroffer reasons explain reduced-exposure treatment
- why manual-review reasons explain unresolved strategy handling
- why decline reasons explain simulated policy stop / no-offer paths
- why triggered_reason_code_list is useful for QA and audit review
- why secondary and tertiary reasons are diagnostic only
- why no latest-run output table or archive insert occurs in Section 10

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.
No adverse-action reason-code language.

================================================================================
18. SECTION 10 DELIVERABLE
================================================================================

Please now provide:

1. Any targeted Section 9 patch required by the pre-flight review, if any.
2. Any targeted label-alignment patch required before Section 10, if any.
3. Section 10 SQL only:
   SIMULATED REASON-CODE ASSIGNMENT LAYER.
4. A short explanation of what Section 10 establishes.
5. A short explanation of what Section 10 intentionally does not build.
6. The recommended next build step after Section 10.

Do not write Section 11+ yet.
<!-- END_MESSAGE C038-M00130 -->


---

<a id="c038-m00140"></a>

### C038-M00140

**ChatGPT** · 2026-05-06T14:12:16.272059-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00140 -->
Section 9 pre-flight review passed; no patch required.

Section 9 includes the required final decision fields, final flags, final exposure fields, final affordability fields, and final approved-exposure economics. It does not create reason-code fields, the final latest-run output table, archive insert logic, or the full QA framework.

Module 2 continues to preserve Module 1’s documented boundary: `estimated_pd` remains the finalized SQL field name but is interpreted as the synthetic estimated-PD proxy, and Expected Loss remains a comparative simulation construct rather than a production forecast. fileciteturn4file0 Module 1’s validated deterministic, matched-scenario foundation remains the lineage base for these downstream simulated strategy outcomes. fileciteturn4file1

---

## Label-alignment review before Section 10

No label mismatch found; no patch required.

### Section 8 labels currently created

`counteroffer_feasibility_failure_reason` values:

```text
COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT
COUNTEROFFER_RAW_AMOUNT_NULL
COUNTEROFFER_ROUNDED_AMOUNT_NULL
COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE
COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT
COUNTEROFFER_BELOW_PRODUCT_MINIMUM
COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT
COUNTEROFFER_EXCEEDS_MAX_REDUCTION
COUNTEROFFER_EXCEEDS_PRODUCT_CAP
COUNTEROFFER_PTI_STILL_ABOVE_TARGET
COUNTEROFFER_APPROVED_EL_ABOVE_CAP
COUNTEROFFER_FEASIBILITY_UNKNOWN
```

`exposure_treatment_status` values:

```text
APPROVED_AS_REQUESTED_PRELIMINARY
NO_OFFER_PRELIMINARY_DECLINE
UNRESOLVED_MANUAL_REVIEW
COUNTEROFFER_FEASIBLE_PRELIMINARY
COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
EXPOSURE_TREATMENT_UNKNOWN
```

`exposure_treatment_path` values:

```text
APPROVE_AS_REQUESTED
NO_OFFER
MANUAL_REVIEW_UNRESOLVED
COUNTEROFFER_FEASIBLE
COUNTEROFFER_NOT_FEASIBLE
EXPOSURE_TREATMENT_UNKNOWN
```

### Section 9 labels currently created

`decision_outcome` values:

```text
APPROVE
COUNTEROFFER
MANUAL_REVIEW
DECLINE
```

`decision_path` values:

```text
HARD_POLICY_STOP
SEVERE_SYNTHETIC_RISK
SEVERE_DTI_CAPACITY
REQUESTED_STRUCTURE_SEVERE_REVIEW
MANUAL_REVIEW_CANDIDATE
RESIDUAL_STRATEGY_REVIEW
APPROVE_AS_REQUESTED
COUNTEROFFER_FEASIBLE
COUNTEROFFER_NOT_FEASIBLE_REVIEW
COUNTEROFFER_NOT_FEASIBLE_DECLINE
FINAL_RESIDUAL_STRATEGY_REVIEW
```

`decision_resolution_source` values:

```text
PRELIMINARY_DECLINE_CONFIRMED
PRELIMINARY_MANUAL_REVIEW_CONFIRMED
PRELIMINARY_APPROVE_CONFIRMED
COUNTEROFFER_FEASIBILITY_CONFIRMED
COUNTEROFFER_FEASIBILITY_FAILED_TO_REVIEW
COUNTEROFFER_FEASIBILITY_FAILED_TO_DECLINE
FINAL_RESIDUAL_FALLBACK
```

---

```sql
/***************************************************************************************************
SECTION 10 — SIMULATED REASON-CODE ASSIGNMENT LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Assign deterministic simulated strategy explanation codes after final decision resolution.

    Section 10 answers:

        "Why did this synthetic applicant receive this simulated strategy outcome?"

    Section 10 does NOT answer:

        "What should be communicated to a real customer?"
        "What is the regulatory explanation for a real decision?"
        "What is the compliance-approved reason for an operational credit action?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_6_final_decision_resolution.
    2. Preserve all prior source, lineage, strategy metadata, thresholds, segmentation, rule flags,
       preliminary routing diagnostics, exposure-treatment diagnostics, and final decision fields.
    3. Create one candidate simulated reason-code row per applicable rule / route / treatment driver.
    4. Filter reason-code candidates by final decision_outcome family.
    5. Rank candidate reasons deterministically using governed priority ranges.
    6. Pivot ranked candidates into:
            primary_reason_code
            secondary_reason_code
            tertiary_reason_code
            primary_reason_family
            triggered_reason_code_list
            reason_priority_rank
            reason_code_count
    7. Validate reason-code completeness, outcome-family alignment, and staging integrity.
    8. Confirm that latest-run output creation and archive persistence remain deferred.

WHY REASON-CODE ASSIGNMENT IS SEPARATED FROM FINAL DECISION RESOLUTION:
    Section 9 creates final simulated strategy outcomes and final exposure economics.
    Section 10 explains those outcomes.

    Keeping explanation logic separate allows the reason-code layer to use:
        final decision_outcome
        final decision_path
        decision_resolution_source
        Section 6 trigger flags
        Section 7 preliminary routing diagnostics
        Section 8 counteroffer feasibility diagnostics
        final exposure-treatment fields
        mixed-signal diagnostics
        borderline diagnostics

    This makes reason-code assignment transparent and extensible.

REASON-CODE BOUNDARY:
    The fields created in Section 10 are simulated strategy explanation codes.

    They are used for:
        strategy transparency
        QA review
        decision-path traceability
        segmentation diagnostics
        portfolio interpretation

    They are not:
        production customer communications
        compliance-approved customer notices
        real-world underwriting explanations
        fair lending conclusions
        customer-level treatment logic

OUTCOME-SPECIFIC FILTERING:
    Candidate reasons are filtered by final decision_outcome family so that:

        APPROVE rows receive APPROVAL reasons.
        COUNTEROFFER rows receive COUNTEROFFER reasons.
        MANUAL_REVIEW rows receive MANUAL_REVIEW reasons.
        DECLINE rows receive POLICY_STOP reasons.

    This prevents reason-family leakage and ensures the primary reason aligns with the final simulated
    strategy outcome.

IMPLEMENTATION PATTERN:
    Section 10 intentionally avoids one large opaque CASE block.

    Instead, it uses:
        reason_candidate_base
        reason_candidates_raw
        reason_candidates
        ranked_reasons
        reason_pivot
        final_reason_assignment

    This pattern is more auditable because every candidate reason has:
        a code,
        a family,
        a priority rank,
        and a source explanation.

REASON PRIORITY RANGES:
    DECLINE / POLICY_STOP reasons:
        100–199

    MANUAL_REVIEW reasons:
        300–399

    COUNTEROFFER reasons:
        500–599

    APPROVAL reasons:
        900–999

    Lower numeric rank means higher priority.

TRIGGERED REASON LIST:
    triggered_reason_code_list contains all applicable candidate reason codes after filtering to the
    final decision_outcome family.

    The list is deterministic:

        STRING_AGG(candidate_reason_code, ' | '
                   ORDER BY candidate_reason_priority_rank, candidate_reason_code)

SECONDARY AND TERTIARY REASONS:
    secondary_reason_code and tertiary_reason_code are additional diagnostics only.
    They do not change decision_outcome.
    They do not change decision_path.
    They do not change approved exposure.

LATEST-RUN / ARCHIVE BOUNDARY:
    Section 10 creates only a temporary reason-code staging table.

    It does not create:
        credit_decisioning_sim.strategy_decisions

    It does not insert rows into:
        credit_decisioning_sim.strategy_decisions_archive

***************************************************************************************************/



/***************************************************************************************************
SECTION 10.1 — CLEAN RESET OF SECTION 10 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_7_reason_code_assignment;



/***************************************************************************************************
SECTION 10.2 — CREATE SIMULATED REASON-CODE ASSIGNMENT TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_7_reason_code_assignment

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_6_final_decision_resolution

OUTPUT:
    All Section 9 fields plus:
        primary_reason_code
        secondary_reason_code
        tertiary_reason_code
        primary_reason_family
        triggered_reason_code_list
        reason_priority_rank
        reason_code_count

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_7_reason_code_assignment
ON COMMIT PRESERVE ROWS
AS
WITH reason_candidate_base AS (
    SELECT
        f.*
    FROM tmp_m2_stage_6_final_decision_resolution f
),

/*-----------------------------------------------------------------------------------------------
Create candidate simulated reason codes.

Each SELECT block is outcome-family specific.

This prevents rows from receiving a primary reason that belongs to a different final outcome family.
For example:
    APPROVE rows cannot receive POLICY_STOP reasons.
    DECLINE rows cannot receive APPROVAL reasons.
    COUNTEROFFER rows cannot receive MANUAL_REVIEW reasons.
    MANUAL_REVIEW rows cannot receive COUNTEROFFER primary reasons.

candidate_reason_source documents why the candidate was created.
It is a diagnostic source label, not a final reason-code field.
-----------------------------------------------------------------------------------------------*/
reason_candidates_raw AS (

    /***********************************************************************************************
    APPROVAL REASONS — PRIORITY 900–999
    ***********************************************************************************************/

    SELECT
        application_id,
        'APPROVED_AS_REQUESTED'::TEXT AS candidate_reason_code,
        'APPROVAL'::TEXT AS candidate_reason_family,
        900::INTEGER AS candidate_reason_priority_rank,
        'decision_outcome_APPROVE'::TEXT AS candidate_reason_source
    FROM reason_candidate_base
    WHERE decision_outcome = 'APPROVE'



    /***********************************************************************************************
    COUNTEROFFER REASONS — PRIORITY 500–599

    These reasons explain why final COUNTEROFFER rows received reduced-exposure treatment.

    COUNTEROFFER_MULTIPLE_CONSTRAINTS is intentionally lower priority than specific counteroffer
    drivers so it generally appears as a secondary or tertiary diagnostic when multiple driver
    families are active.
    ***********************************************************************************************/

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT',
        'COUNTEROFFER',
        500,
        'exposure_counteroffer_candidate_or_product_cap_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            exposure_counteroffer_candidate_flag IS TRUE
         OR requested_exposure_above_product_cap_flag IS TRUE
         OR (
                counteroffer_product_cap_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_product_cap_amount = counteroffer_raw_max_feasible_amount
            AND requested_amount > product_max_approved_amount
         )
      )

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_AFFORDABILITY_ADJUSTMENT',
        'COUNTEROFFER',
        510,
        'requested_pti_counteroffer_candidate_or_pti_target_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_affordability_candidate_flag IS TRUE
         OR requested_pti_counteroffer_candidate_flag IS TRUE
         OR (
                counteroffer_pti_target_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_pti_target_amount = counteroffer_raw_max_feasible_amount
         )
      )

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_EXPECTED_LOSS_LIMIT',
        'COUNTEROFFER',
        520,
        'requested_el_counteroffer_candidate_or_approved_el_cap_binding'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_expected_loss_candidate_flag IS TRUE
         OR (
                counteroffer_el_cap_amount IS NOT NULL
            AND counteroffer_raw_max_feasible_amount IS NOT NULL
            AND counteroffer_el_cap_amount = counteroffer_raw_max_feasible_amount
         )
      )

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_SYNTHETIC_RISK_EXPOSURE_LIMIT',
        'COUNTEROFFER',
        530,
        'counteroffer_risk_band_eligible'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND counteroffer_risk_band_eligible_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'COUNTEROFFER_MULTIPLE_CONSTRAINTS',
        'COUNTEROFFER',
        580,
        'multiple_counteroffer_candidate_families'
    FROM reason_candidate_base
    WHERE decision_outcome = 'COUNTEROFFER'
      AND counteroffer_candidate_trigger_count > 1



    /***********************************************************************************************
    MANUAL REVIEW REASONS — PRIORITY 300–399

    These reasons explain why the final row remains unresolved under simulated strategy handling.

    Specific failed-counteroffer feasibility diagnostics rank above generic failed-counteroffer
    review routing. This preserves useful counteroffer feasibility traceability.
    ***********************************************************************************************/

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT',
        'MANUAL_REVIEW',
        300,
        'COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT'

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_PTI_TARGET_NOT_MET',
        'MANUAL_REVIEW',
        305,
        'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_APPROVED_EL_ABOVE_CAP',
        'MANUAL_REVIEW',
        310,
        'COUNTEROFFER_APPROVED_EL_ABOVE_CAP'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason = 'COUNTEROFFER_APPROVED_EL_ABOVE_CAP'

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_BELOW_MINIMUM_OFFER',
        'MANUAL_REVIEW',
        315,
        'counteroffer_amount_below_minimum_or_reduction_floor'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND counteroffer_feasibility_failure_reason IN (
            'COUNTEROFFER_ROUNDED_AMOUNT_NULL',
            'COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE',
            'COUNTEROFFER_BELOW_PRODUCT_MINIMUM',
            'COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT',
            'COUNTEROFFER_EXCEEDS_MAX_REDUCTION'
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_COUNTEROFFER_NOT_FEASIBLE',
        'MANUAL_REVIEW',
        320,
        'generic_failed_counteroffer_to_review'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND failed_counteroffer_resolution = 'MANUAL_REVIEW'

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK',
        'MANUAL_REVIEW',
        330,
        'borderline_synthetic_estimated_risk'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_borderline_trigger_flag IS TRUE
         OR (
                borderline_profile_flag IS TRUE
            AND strategy_risk_tier IN (
                    'ELEVATED_SYNTHETIC_RISK',
                    'HIGH_SYNTHETIC_RISK'
                )
         )
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_BORDERLINE_AFFORDABILITY',
        'MANUAL_REVIEW',
        340,
        'borderline_requested_affordability'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND borderline_profile_flag IS TRUE
      AND requested_pti_bucket IN (
            'ELEVATED_REQUESTED_PTI',
            'HIGH_REQUESTED_PTI',
            'SEVERE_REQUESTED_PTI'
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_MIXED_SIGNAL_PROFILE',
        'MANUAL_REVIEW',
        350,
        'mixed_signal_profile'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            manual_review_mixed_signal_trigger_flag IS TRUE
         OR mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_REQUESTED_STRUCTURE',
        'MANUAL_REVIEW',
        360,
        'requested_structure_stress'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            severe_requested_structure_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR exposure_policy_stop_candidate_flag IS TRUE
         OR requested_exposure_tier IN (
                'ABOVE_PRODUCT_APPROVAL_CAP',
                'EXTREME_REQUESTED_EXPOSURE'
            )
         OR requested_pti_bucket IN (
                'HIGH_REQUESTED_PTI',
                'SEVERE_REQUESTED_PTI'
            )
         OR requested_expected_loss_tier IN (
                'HIGH_REQUESTED_EL',
                'SEVERE_REQUESTED_EL'
            )
      )

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_ELEVATED_SYNTHETIC_RISK',
        'MANUAL_REVIEW',
        370,
        'manual_review_risk_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND manual_review_risk_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_ELEVATED_DTI',
        'MANUAL_REVIEW',
        380,
        'manual_review_dti_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND manual_review_dti_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_EXPECTED_LOSS',
        'MANUAL_REVIEW',
        385,
        'manual_review_expected_loss_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND manual_review_expected_loss_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_SUPPLEMENTAL_BEHAVIORAL_SIGNAL',
        'MANUAL_REVIEW',
        390,
        'supplemental_behavioral_review_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND supplemental_behavioral_review_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'MANUAL_REVIEW_RESIDUAL_STRATEGY_REVIEW',
        'MANUAL_REVIEW',
        399,
        'residual_manual_review_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            decision_path IN (
                'RESIDUAL_STRATEGY_REVIEW',
                'FINAL_RESIDUAL_STRATEGY_REVIEW'
            )
         OR decision_resolution_source = 'FINAL_RESIDUAL_FALLBACK'
      )



    /***********************************************************************************************
    DECLINE / POLICY STOP REASONS — PRIORITY 100–199

    These reasons explain final no-offer simulated policy stop paths.

    These are simulated policy stop reasons for synthetic applicants.
    They are not production customer notices or regulatory customer communication codes.
    ***********************************************************************************************/

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_BANKRUPTCY_FLAG',
        'POLICY_STOP',
        100,
        'bankruptcy_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND bankruptcy_policy_stop_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_MAJOR_DEROGATORY',
        'POLICY_STOP',
        110,
        'major_derogatory_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND major_derogatory_policy_stop_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_RECENT_DELINQUENCY',
        'POLICY_STOP',
        120,
        'severe_delinquency_policy_stop_flag'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND severe_delinquency_policy_stop_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY',
        'POLICY_STOP',
        130,
        'synthetic_risk_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            synthetic_risk_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_SYNTHETIC_RISK'
      )

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_HIGH_DTI',
        'POLICY_STOP',
        140,
        'dti_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            dti_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_DTI_CAPACITY'
      )

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_COUNTEROFFER_NOT_FEASIBLE',
        'POLICY_STOP',
        150,
        'failed_counteroffer_resolution_to_decline'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND failed_counteroffer_resolution = 'DECLINE'

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_EXPECTED_LOSS_UNRESOLVED',
        'POLICY_STOP',
        160,
        'requested_el_decline_trigger'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND requested_el_decline_trigger_flag IS TRUE

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_EXPOSURE_LIMIT_UNRESOLVED',
        'POLICY_STOP',
        170,
        'requested_exposure_policy_stop_candidate'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND (
            requested_exposure_extreme_flag IS TRUE
         OR exposure_policy_stop_candidate_flag IS TRUE
      )

    UNION ALL

    SELECT
        application_id,
        'POLICY_STOP_RESIDUAL_DECLINE',
        'POLICY_STOP',
        199,
        'residual_decline_fallback'
    FROM reason_candidate_base
    WHERE decision_outcome = 'DECLINE'
      AND NOT (
            bankruptcy_policy_stop_flag IS TRUE
         OR major_derogatory_policy_stop_flag IS TRUE
         OR severe_delinquency_policy_stop_flag IS TRUE
         OR synthetic_risk_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_SYNTHETIC_RISK'
         OR dti_decline_trigger_flag IS TRUE
         OR decision_path = 'SEVERE_DTI_CAPACITY'
         OR (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND counteroffer_feasibility_pass_flag IS FALSE
            AND failed_counteroffer_resolution = 'DECLINE'
            )
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR exposure_policy_stop_candidate_flag IS TRUE
      )
),

/*-----------------------------------------------------------------------------------------------
Deduplicate reason candidates.

A row can satisfy the same candidate reason through multiple related diagnostics. Deduplication keeps
the triggered reason list readable while preserving deterministic ranking.
-----------------------------------------------------------------------------------------------*/
reason_candidates AS (
    SELECT DISTINCT
        application_id,
        candidate_reason_code,
        candidate_reason_family,
        candidate_reason_priority_rank,
        candidate_reason_source
    FROM reason_candidates_raw
),

/*-----------------------------------------------------------------------------------------------
Rank candidate reasons.

The primary reason is the lowest-ranked candidate reason within the final decision_outcome family.
Ties are resolved alphabetically by candidate_reason_code for deterministic output.
-----------------------------------------------------------------------------------------------*/
ranked_reasons AS (
    SELECT
        rc.*,

        ROW_NUMBER() OVER (
            PARTITION BY rc.application_id
            ORDER BY
                rc.candidate_reason_priority_rank,
                rc.candidate_reason_code
        ) AS reason_row_number

    FROM reason_candidates rc
),

/*-----------------------------------------------------------------------------------------------
Pivot ranked reason candidates back to one row per application_id.

triggered_reason_code_list contains all candidate codes after final-outcome family filtering.
secondary_reason_code and tertiary_reason_code are diagnostic only.
-----------------------------------------------------------------------------------------------*/
reason_pivot AS (
    SELECT
        application_id,

        MAX(candidate_reason_code) FILTER (WHERE reason_row_number = 1)
            AS primary_reason_code,

        MAX(candidate_reason_code) FILTER (WHERE reason_row_number = 2)
            AS secondary_reason_code,

        MAX(candidate_reason_code) FILTER (WHERE reason_row_number = 3)
            AS tertiary_reason_code,

        MAX(candidate_reason_family) FILTER (WHERE reason_row_number = 1)
            AS primary_reason_family,

        MAX(candidate_reason_priority_rank) FILTER (WHERE reason_row_number = 1)
            AS reason_priority_rank,

        STRING_AGG(
            candidate_reason_code,
            ' | '
            ORDER BY candidate_reason_priority_rank, candidate_reason_code
        ) AS triggered_reason_code_list,

        COUNT(*)::INTEGER AS reason_code_count

    FROM ranked_reasons
    GROUP BY application_id
),

/*-----------------------------------------------------------------------------------------------
Final Section 10 staging table.

This preserves all final decision-resolution fields and adds simulated reason-code assignment fields.
-----------------------------------------------------------------------------------------------*/
final_reason_assignment AS (
    SELECT
        b.*,

        rp.primary_reason_code,
        rp.secondary_reason_code,
        rp.tertiary_reason_code,
        rp.primary_reason_family,
        rp.triggered_reason_code_list,
        rp.reason_priority_rank,
        rp.reason_code_count

    FROM reason_candidate_base b
    LEFT JOIN reason_pivot rp
        ON rp.application_id = b.application_id
)

SELECT *
FROM final_reason_assignment;



/***************************************************************************************************
SECTION 10.3 — LOCAL FAIL-FAST CHECKS FOR SIMULATED REASON-CODE ASSIGNMENT
****************************************************************************************************

PURPOSE:
    Validate the Section 10 reason-code staging layer before latest-run output creation, archive
    persistence, full QA, or matched strategy comparison are built.

IMPORTANT:
    These are local staging gatekeepers only.

    They are not:
        full Module 2 QA
        archive validation
        matched strategy comparison
        final documentation evidence

***************************************************************************************************/

DO $$
DECLARE
    v_stage6_count BIGINT;
    v_stage7_count BIGINT;
    v_stage7_distinct_app_count BIGINT;

    v_duplicate_application_count BIGINT;
    v_required_reason_failure_count BIGINT;
    v_approval_reason_failure_count BIGINT;
    v_counteroffer_reason_failure_count BIGINT;
    v_manual_review_reason_failure_count BIGINT;
    v_decline_reason_failure_count BIGINT;
    v_family_leakage_failure_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 9 to Section 10.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage6_count
    FROM tmp_m2_stage_6_final_decision_resolution;

    SELECT COUNT(*)
    INTO v_stage7_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    IF v_stage7_count <> v_stage6_count THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: row count changed from Section 9 to Section 10. Stage 6 rows: %, Stage 7 rows: %.',
            v_stage6_count,
            v_stage7_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage7_distinct_app_count
    FROM tmp_m2_stage_7_reason_code_assignment;

    IF v_stage7_distinct_app_count <> v_stage7_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_7_reason_code_assignment
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 10 failure: application_id uniqueness was not preserved. Stage 7 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage7_count,
            v_stage7_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required reason-code fields must be complete.

    Every row must be explainable.
    APPROVE rows receive APPROVED_AS_REQUESTED.
    Non-approval rows receive an outcome-family-aligned strategy explanation code.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE primary_reason_code IS NULL
       OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
       OR primary_reason_family IS NULL
       OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
       OR reason_priority_rank IS NULL
       OR reason_priority_rank <= 0
       OR triggered_reason_code_list IS NULL
       OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
       OR reason_code_count IS NULL
       OR reason_code_count < 1;

    IF v_required_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have missing or invalid required simulated reason-code fields.',
            v_required_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: APPROVE reason convention.

    APPROVE rows should receive exactly one approval explanation code unless approval diagnostics are
    explicitly expanded in a future design.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approval_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'APPROVE'
      AND (
            primary_reason_code <> 'APPROVED_AS_REQUESTED'
         OR primary_reason_family <> 'APPROVAL'
         OR reason_priority_rank <> 900
         OR secondary_reason_code IS NOT NULL
         OR tertiary_reason_code IS NOT NULL
         OR triggered_reason_code_list <> 'APPROVED_AS_REQUESTED'
         OR reason_code_count <> 1
      );

    IF v_approval_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % APPROVE row(s) violate approval reason-code conventions.',
            v_approval_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: COUNTEROFFER reason convention.

    Final COUNTEROFFER rows must receive a COUNTEROFFER-family primary reason.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'COUNTEROFFER'
      AND (
            primary_reason_family <> 'COUNTEROFFER'
         OR primary_reason_code NOT LIKE 'COUNTEROFFER_%'
      );

    IF v_counteroffer_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % COUNTEROFFER row(s) violate counteroffer reason-code conventions.',
            v_counteroffer_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: MANUAL_REVIEW reason convention.

    Final MANUAL_REVIEW rows must receive a MANUAL_REVIEW-family primary reason.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'MANUAL_REVIEW'
      AND (
            primary_reason_family <> 'MANUAL_REVIEW'
         OR primary_reason_code NOT LIKE 'MANUAL_REVIEW_%'
      );

    IF v_manual_review_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % MANUAL_REVIEW row(s) violate manual-review reason-code conventions.',
            v_manual_review_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DECLINE reason convention.

    Final DECLINE rows must receive a POLICY_STOP-family primary reason.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decline_reason_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE decision_outcome = 'DECLINE'
      AND (
            primary_reason_family <> 'POLICY_STOP'
         OR primary_reason_code NOT LIKE 'POLICY_STOP_%'
      );

    IF v_decline_reason_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % DECLINE row(s) violate policy-stop reason-code conventions.',
            v_decline_reason_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: primary reason-family leakage prevention.

    This validates the primary reason-code family against the final decision_outcome.
    Secondary and tertiary reason codes are also generated only after final-outcome family filtering.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_family_leakage_failure_count
    FROM tmp_m2_stage_7_reason_code_assignment
    WHERE (
            decision_outcome = 'APPROVE'
            AND (
                primary_reason_code LIKE 'COUNTEROFFER_%'
                OR primary_reason_code LIKE 'MANUAL_REVIEW_%'
                OR primary_reason_code LIKE 'POLICY_STOP_%'
            )
    )
    OR (
            decision_outcome = 'COUNTEROFFER'
            AND (
                primary_reason_code = 'APPROVED_AS_REQUESTED'
                OR primary_reason_code LIKE 'MANUAL_REVIEW_%'
                OR primary_reason_code LIKE 'POLICY_STOP_%'
            )
    )
    OR (
            decision_outcome = 'MANUAL_REVIEW'
            AND (
                primary_reason_code = 'APPROVED_AS_REQUESTED'
                OR primary_reason_code LIKE 'COUNTEROFFER_%'
                OR primary_reason_code LIKE 'POLICY_STOP_%'
            )
    )
    OR (
            decision_outcome = 'DECLINE'
            AND (
                primary_reason_code = 'APPROVED_AS_REQUESTED'
                OR primary_reason_code LIKE 'COUNTEROFFER_%'
                OR primary_reason_code LIKE 'MANUAL_REVIEW_%'
            )
    );

    IF v_family_leakage_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: % row(s) have primary reason-code family leakage across final decision outcomes.',
            v_family_leakage_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: final latest-run output table must not exist yet.

    Section 10 creates a temporary reason-code staging table only.
    The permanent latest-run strategy output is created in a later section.
    -------------------------------------------------------------------------------------------*/
    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 10 failure: final latest-run strategy_decisions table exists before the final output section.';
    END IF;

    /*
    Archive note:
        Section 10 contains no INSERT, DELETE, TRUNCATE, or CREATE logic for
        credit_decisioning_sim.strategy_decisions_archive.

        Archive persistence remains deferred to a later section.
    */
END $$;



/***************************************************************************************************
SECTION 10.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 10 reason-code assignment layer.

IMPORTANT:
    These are not full Module 2 QA outputs.
    They should not be treated as the final Validation Summary evidence set.

    Full decision distribution, reason-code coverage, approved-book analysis, archive validation,
    and matched strategy comparison QA will be built later.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
10.4.1 Count by decision_outcome × primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    primary_reason_code,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_outcome,
    primary_reason_code
ORDER BY
    decision_outcome,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.2 Count by decision_outcome × primary_reason_family.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    primary_reason_family,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_outcome,
    primary_reason_family
ORDER BY
    decision_outcome,
    primary_reason_family;


/*-----------------------------------------------------------------------------------------------
10.4.3 Count by primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    primary_reason_code,
    primary_reason_family,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    primary_reason_code,
    primary_reason_family
ORDER BY
    primary_reason_family,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.4 Count by primary_reason_family.
-----------------------------------------------------------------------------------------------*/
SELECT
    primary_reason_family,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY primary_reason_family
ORDER BY primary_reason_family;


/*-----------------------------------------------------------------------------------------------
10.4.5 Average reason_code_count by decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_outcome,
    COUNT(*) AS row_count,
    AVG(reason_code_count) AS avg_reason_code_count,
    MIN(reason_code_count) AS min_reason_code_count,
    MAX(reason_code_count) AS max_reason_code_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY decision_outcome
ORDER BY decision_outcome;


/*-----------------------------------------------------------------------------------------------
10.4.6 Count by secondary_reason_code.

NULL means fewer than two applicable simulated reason-code candidates.
-----------------------------------------------------------------------------------------------*/
SELECT
    secondary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY secondary_reason_code
ORDER BY secondary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.7 Count by tertiary_reason_code.

NULL means fewer than three applicable simulated reason-code candidates.
-----------------------------------------------------------------------------------------------*/
SELECT
    tertiary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY tertiary_reason_code
ORDER BY tertiary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.8 Product × primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount) AS avg_approved_expected_loss_amount
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    product_type_policy_key,
    primary_reason_code
ORDER BY
    product_type_policy_key,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.9 Score band × primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_7_reason_code_assignment
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
10.4.10 Strategy risk tier × primary_reason_code.

estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    strategy_risk_tier,
    primary_reason_code
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.11 Requested PTI bucket × primary_reason_code.

requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio) AS avg_approved_payment_to_income_ratio
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    requested_pti_bucket,
    primary_reason_code
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.12 Decision path × primary_reason_code.
-----------------------------------------------------------------------------------------------*/
SELECT
    decision_path,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    decision_path,
    primary_reason_code
ORDER BY
    decision_path,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.13 Counteroffer feasibility failure reason × primary_reason_code.

counteroffer_feasibility_failure_reason is a feasibility diagnostic, not a final reason code.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_feasibility_failure_reason,
    primary_reason_code,
    COUNT(*) AS row_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    counteroffer_feasibility_failure_reason,
    primary_reason_code
ORDER BY
    counteroffer_feasibility_failure_reason,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.14 Mixed-signal profile × primary_reason_code.

mixed_signal_profile_type remains diagnostic.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(reason_code_count) AS avg_reason_code_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    mixed_signal_profile_type,
    primary_reason_code
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
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.15 Borderline profile flag × primary_reason_code.

borderline_profile_flag uses governed threshold proximity logic and remains diagnostic.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    primary_reason_code,
    COUNT(*) AS row_count,
    AVG(reason_code_count) AS avg_reason_code_count
FROM tmp_m2_stage_7_reason_code_assignment
GROUP BY
    borderline_profile_flag,
    primary_reason_code
ORDER BY
    borderline_profile_flag,
    primary_reason_code;


/*-----------------------------------------------------------------------------------------------
10.4.16 Sample reason-code trace.

Purpose:
    Provides a small row-level trace to confirm that reason-code assignment is readable and aligned
    to final decision outcome.

This is a staging diagnostic only.
-----------------------------------------------------------------------------------------------*/
SELECT
    application_id,
    product_type_policy_key,
    score_band_policy_key,
    decision_outcome,
    decision_path,
    decision_resolution_source,
    primary_reason_code,
    secondary_reason_code,
    tertiary_reason_code,
    primary_reason_family,
    reason_priority_rank,
    reason_code_count,
    triggered_reason_code_list
FROM tmp_m2_stage_7_reason_code_assignment
ORDER BY
    decision_outcome,
    primary_reason_code,
    application_id
LIMIT 50;


/***************************************************************************************************
END OF SECTION 10 — SIMULATED REASON-CODE ASSIGNMENT LAYER

If execution reaches this point:
    1. tmp_m2_stage_7_reason_code_assignment exists.
    2. All Section 9 fields have been preserved.
    3. Module 1 lineage remains attached.
    4. Module 2 strategy metadata remains attached.
    5. Final decision outcomes remain attached.
    6. Final exposure economics remain attached.
    7. primary_reason_code is populated for every row.
    8. secondary_reason_code and tertiary_reason_code are populated when additional diagnostics exist.
    9. primary_reason_family aligns to final decision_outcome.
    10. triggered_reason_code_list is deterministic and outcome-family filtered.
    11. reason_priority_rank equals the primary candidate reason priority rank.
    12. reason_code_count is populated and positive for every row.

No final latest-run strategy output table has been created.
No strategy archive rows have been inserted.
No full Module 2 QA framework has been created.
No matched strategy comparison queries have been created.
No BRD or Validation Summary documentation has been drafted.

***************************************************************************************************/
```

---

## What Section 10 establishes

Section 10 creates:

```text
tmp_m2_stage_7_reason_code_assignment
```

It assigns deterministic simulated strategy explanation codes using a candidate → ranking → pivot pattern. Every row receives a `primary_reason_code`, `primary_reason_family`, `triggered_reason_code_list`, `reason_priority_rank`, and `reason_code_count`.

It also adds secondary and tertiary diagnostic reason codes where multiple outcome-aligned reason candidates apply.

## What Section 10 intentionally does not build

Section 10 does not create the final latest-run `strategy_decisions` table, insert archive rows, build matched strategy comparison queries, or create the full QA framework.

It also does not draft the Module 2 BRD or Validation Summary.

## Recommended next build step

Next should be:

```text
Section 11 — Latest-Run Strategy Decision Output Table
```

That section should create:

```text
credit_decisioning_sim.strategy_decisions
```

using the fully staged Section 10 output, with one row per application for the current strategy run and the locked final fields needed for downstream QA and archive persistence.
<!-- END_MESSAGE C038-M00140 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_04.md) · [Next](Part_06.md)
