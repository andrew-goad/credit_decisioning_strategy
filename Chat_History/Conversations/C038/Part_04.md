# Module 2 Decision Simulator Build

## Part 04

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_03.md) · [Next](Part_05.md)

<a id="c038-m00116"></a>

### C038-M00116

**ChatGPT** · 2026-05-06T13:02:17.969544-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00116 -->
The Section 6 hardening patch below is narrow: it only adds band-coverage diagnostics and gatekeepers for the two true banding families you identified. It does not impose mutual exclusivity across overlapping trigger families. This keeps Module 2 aligned with Module 1’s governed simulation boundary, where the synthetic estimated-PD proxy and Expected Loss remain comparative simulation constructs rather than calibrated production outputs. fileciteturn4file0 The same staged, validation-first pattern also preserves the deterministic and audit-ready discipline validated in Module 1 V2.0. fileciteturn4file1

---

# 1. Targeted Section 6 hardening patch

## Patch 6.A — Add true banding-family count fields

Add these fields inside the `final_rule_flags AS (...)` CTE in Section 6, before `total_rule_trigger_count`.

### BEFORE

```sql
final_rule_flags AS (
    SELECT
        cad.*,

        (
            cad.hard_policy_stop_count
            + cad.synthetic_risk_trigger_count
            + cad.affordability_trigger_count
            + cad.dti_trigger_count
            + cad.requested_el_trigger_count
            + cad.exposure_trigger_count
            + cad.supplemental_behavioral_review_trigger_count
            + cad.manual_review_mixed_signal_trigger_flag::INT
            + cad.manual_review_borderline_trigger_flag::INT
        ) AS total_rule_trigger_count

    FROM clean_approval_diagnostic cad
)
```

### AFTER

```sql
final_rule_flags AS (
    SELECT
        cad.*,

        /*
        True banding-family coverage diagnostics.

        These count fields are intentionally limited to rule families where exactly one
        band should be active per row.

        They do not force mutual exclusivity across broader trigger families because
        multiple simulated policy signals can validly coexist on the same synthetic
        applicant.
        */
        (
            cad.synthetic_risk_clean_approval_band_flag::INT
            + cad.synthetic_risk_counteroffer_band_flag::INT
            + cad.synthetic_risk_review_band_flag::INT
            + cad.synthetic_risk_decline_trigger_flag::INT
        ) AS synthetic_risk_band_flag_count,

        (
            cad.dti_clean_band_flag::INT
            + cad.dti_review_trigger_flag::INT
            + cad.dti_decline_trigger_flag::INT
        ) AS dti_band_flag_count,

        (
            cad.hard_policy_stop_count
            + cad.synthetic_risk_trigger_count
            + cad.affordability_trigger_count
            + cad.dti_trigger_count
            + cad.requested_el_trigger_count
            + cad.exposure_trigger_count
            + cad.supplemental_behavioral_review_trigger_count
            + cad.manual_review_mixed_signal_trigger_flag::INT
            + cad.manual_review_borderline_trigger_flag::INT
        ) AS total_rule_trigger_count

    FROM clean_approval_diagnostic cad
)
```

---

## Patch 6.B — Add count-field validation for the new banding diagnostics

Add these checks to the existing Section 6.3 count-field gatekeeper.

### BEFORE

```sql
WHERE hard_policy_stop_count IS NULL
   OR synthetic_risk_trigger_count IS NULL
   OR affordability_trigger_count IS NULL
   OR dti_trigger_count IS NULL
```

### AFTER

```sql
WHERE hard_policy_stop_count IS NULL
   OR synthetic_risk_trigger_count IS NULL
   OR affordability_trigger_count IS NULL
   OR dti_trigger_count IS NULL
   OR synthetic_risk_band_flag_count IS NULL
   OR dti_band_flag_count IS NULL
```

And add non-negative checks:

```sql
   OR synthetic_risk_band_flag_count < 0
   OR dti_band_flag_count < 0
```

---

## Patch 6.C — Add local true-band coverage gatekeepers

Add these declarations to the Section 6.3 `DECLARE` block.

```sql
    v_synthetic_risk_band_coverage_violation_count BIGINT;
    v_dti_band_coverage_violation_count BIGINT;
```

Add this gatekeeper block after the rule count-field validation block.

```sql
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: synthetic estimated-risk band coverage.

    The synthetic estimated-risk flags form a true banding family. Every row must occupy exactly
    one synthetic estimated-risk band.

    This does not prevent synthetic-risk triggers from overlapping with affordability, exposure,
    DTI, hard simulated policy stop, counteroffer, or manual-review candidate triggers.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_band_coverage_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE synthetic_risk_band_flag_count <> 1;

    IF v_synthetic_risk_band_coverage_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) do not occupy exactly one synthetic estimated-risk band.',
            v_synthetic_risk_band_coverage_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DTI band coverage.

    DTI is also a true capacity banding family. Every row must occupy exactly one DTI band.

    This does not prevent DTI pressure from coexisting with requested PTI pressure, requested
    Expected Loss pressure, exposure pressure, mixed-signal diagnostics, or other trigger families.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_dti_band_coverage_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE dti_band_flag_count <> 1;

    IF v_dti_band_coverage_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) do not occupy exactly one DTI capacity band.',
            v_dti_band_coverage_violation_count;
    END IF;
```

---

# 2. Section 7 SQL only — Preliminary Decision Routing Layer

```sql
/***************************************************************************************************
SECTION 7 — PRELIMINARY DECISION ROUTING LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Convert overlapping Section 6 simulated rule-trigger flags into one transparent preliminary
    routing outcome per synthetic applicant.

    Section 7 answers:

        "Based on current triggers, what path should this synthetic applicant be routed toward
         before approved exposure / counteroffer feasibility is calculated?"

    Section 7 does NOT answer:

        "What is the final simulated strategy outcome?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_3_rule_flags.
    2. Preserve all prior source, lineage, strategy metadata, threshold, segmentation, and trigger
       fields.
    3. Apply a documented preliminary routing hierarchy.
    4. Create preliminary route fields only.
    5. Validate preliminary routing completeness and internal consistency.
    6. Confirm that no final outcome, reason-code, approved exposure, approved payment, approved
       PTI, approved Expected Loss, latest-run output, or archive logic is created in this section.

WHY THIS IS PRELIMINARY ROUTING, NOT FINAL STRATEGY OUTCOME:
    Section 6 can produce multiple overlapping trigger flags. Section 7 organizes those triggers into
    a single preliminary route so later sections know which processing path is needed.

    Final decision_outcome is deferred because counteroffer and approved-exposure feasibility are not
    yet calculated.

    In particular, a preliminary COUNTEROFFER route means:
        "This row should be sent to counteroffer feasibility logic."

    It does not mean:
        "A viable counteroffer has already been calculated."

COUNTEROFFER FEASIBILITY BOUNDARY:
    Counteroffer viability cannot be finalized until later sections calculate:
        approved_amount
        counteroffer_amount
        approved_monthly_payment_proxy
        approved_payment_to_income_ratio
        approved_expected_loss_amount

    Therefore Section 7 creates:
        requires_counteroffer_feasibility_flag
        requires_approved_exposure_calculation_flag

    but it does not calculate approved exposure.

MANUAL REVIEW BOUNDARY:
    Manual review remains unresolved by design.

    Section 7 may preliminarily route a row to MANUAL_REVIEW, but it does not calculate:
        approved_amount
        approved payment
        approved PTI
        approved Expected Loss

HARD SIMULATED POLICY STOP PRIORITY:
    Hard simulated policy stop triggers receive the highest preliminary routing priority because they
    represent severe configured strategy stops such as bankruptcy flag, major derogatory flag, or
    severe recent delinquency count.

    These are still preliminary routing triggers, not final production decisions.

SYNTHETIC ESTIMATED-RISK BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 7, estimated_pd is still interpreted only as the synthetic estimated-PD proxy.
    It is not recalculated.
    It is not treated as a calibrated production probability of default.

SEVERE SYNTHETIC RISK ROUTING:
    Severe synthetic estimated-risk is not treated as directly solved through exposure reduction in
    Module 2 v1.0. A row at or above the severe synthetic estimated-risk trigger is routed toward a
    preliminary DECLINE path unless a higher-priority hard simulated policy stop has already routed it.

DTI CAPACITY ROUTING:
    DTI reflects existing-obligation capacity. It is not directly fixed by reducing the requested
    exposure in Module 2 v1.0. Severe DTI therefore routes to a preliminary DECLINE path unless a
    higher-priority route has already fired.

REQUESTED-STRUCTURE STRESS ROUTING:
    Requested PTI, requested Expected Loss, and requested exposure stress are based on the original
    Module 1 requested structure. Some of these stresses may be addressable later through exposure
    treatment, but approved-exposure logic has not been built yet.

    If a severe requested-structure trigger is active, no higher-priority route has fired, and the row
    is not already a counteroffer candidate, the row is conservatively routed to preliminary
    MANUAL_REVIEW rather than silently becoming a clean approval.

CLEAN APPROVAL BOUNDARY:
    preliminary APPROVE means "clean approval candidate route."

    It is not final APPROVE because later sections still need to populate:
        approved_amount
        approved_monthly_payment_proxy
        approved_payment_to_income_ratio
        approved_expected_loss_amount

RESIDUAL REVIEW BOUNDARY:
    Unclassified synthetic profiles should not silently become approvals or declines. Residual cases
    route to preliminary MANUAL_REVIEW for audit-readable conservative handling.

REASON-CODE BOUNDARY:
    Section 7 creates no reason codes.

    preliminary_route_reason_family is a route-family diagnostic, not a final reason-code family.
    Primary / secondary / tertiary simulated reason codes are assigned only after final outcome and
    exposure-treatment logic are built.

***************************************************************************************************/



/***************************************************************************************************
SECTION 7.1 — CLEAN RESET OF SECTION 7 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_4_preliminary_decision_routing;



/***************************************************************************************************
SECTION 7.2 — CREATE PRELIMINARY DECISION ROUTING TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_4_preliminary_decision_routing

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_3_rule_flags

OUTPUT:
    All Section 6 fields plus:
        preliminary_decision_outcome
        preliminary_decision_path
        preliminary_decision_priority_rank
        preliminary_route_reason_family
        preliminary_decline_flag
        preliminary_counteroffer_flag
        preliminary_manual_review_flag
        preliminary_approve_flag
        requires_counteroffer_feasibility_flag
        requires_approved_exposure_calculation_flag
        severe_requested_structure_trigger_flag
        severe_requested_structure_trigger_count
        preliminary_route_trigger_count

IMPORTANT:
    This table does not contain final decision_outcome.
    This table does not contain final decision_path.
    This table does not contain final approval / decline / manual review / counteroffer flags.
    This table does not contain approved exposure or approved Expected Loss.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_4_preliminary_decision_routing
ON COMMIT PRESERVE ROWS
AS
WITH route_inputs AS (
    SELECT
        r.*,

        /*
        Severe requested-structure trigger family.

        These triggers reflect severe stress in the original requested structure:
            requested PTI,
            requested-exposure Expected Loss,
            requested exposure tier,
            or exposure policy-stop candidate behavior.

        They are not final outcomes.

        Some requested-structure stress may be addressable through later exposure treatment. However,
        if the row is not already a counteroffer candidate and no higher-priority decline route has
        fired, Section 7 routes the row to preliminary MANUAL_REVIEW rather than allowing a silent
        clean approval.
        */
        (
            r.requested_pti_decline_trigger_flag
            OR r.requested_el_decline_trigger_flag
            OR r.requested_exposure_extreme_flag
            OR r.exposure_policy_stop_candidate_flag
        ) AS severe_requested_structure_trigger_flag,

        (
            r.requested_pti_decline_trigger_flag::INT
            + r.requested_el_decline_trigger_flag::INT
            + (
                r.requested_exposure_extreme_flag
                OR r.exposure_policy_stop_candidate_flag
              )::INT
        ) AS severe_requested_structure_trigger_count,

        /*
        Preliminary route trigger count.

        This count summarizes how many high-level preliminary routing families are active before
        the hierarchy selects one route. It is diagnostic only.

        It intentionally allows values greater than one because overlapping trigger families are
        valid in Section 7.
        */
        (
            r.hard_policy_stop_flag::INT
            + r.synthetic_risk_decline_trigger_flag::INT
            + r.dti_decline_trigger_flag::INT
            + r.counteroffer_candidate_flag::INT
            + (
                r.requested_pti_decline_trigger_flag
                OR r.requested_el_decline_trigger_flag
                OR r.requested_exposure_extreme_flag
                OR r.exposure_policy_stop_candidate_flag
              )::INT
            + r.manual_review_candidate_flag::INT
            + r.clean_approval_candidate_flag::INT
        ) AS preliminary_route_trigger_count

    FROM tmp_m2_stage_3_rule_flags r
),

/*-----------------------------------------------------------------------------------------------
Apply preliminary routing hierarchy.

This CASE block creates one preliminary routing outcome per row.

The hierarchy is intentionally explicit. It does not erase overlapping triggers; it only identifies
the route that downstream sections should process first.
-----------------------------------------------------------------------------------------------*/
preliminary_routed AS (
    SELECT
        ri.*,

        /*
        preliminary_decision_outcome:
            Uses the same four business outcome labels as the final taxonomy, but this field is
            preliminary only.

        Allowed values:
            APPROVE
            COUNTEROFFER
            MANUAL_REVIEW
            DECLINE

        Final decision_outcome is created later.
        */
        CASE
            /* Priority 1 — Hard simulated policy stop route */
            WHEN ri.hard_policy_stop_flag IS TRUE
                THEN 'DECLINE'

            /* Priority 2 — Severe synthetic estimated-risk route */
            WHEN ri.synthetic_risk_decline_trigger_flag IS TRUE
                THEN 'DECLINE'

            /* Priority 3 — Severe DTI capacity route */
            WHEN ri.dti_decline_trigger_flag IS TRUE
                THEN 'DECLINE'

            /* Priority 4 — Counteroffer feasibility route */
            WHEN ri.counteroffer_candidate_flag IS TRUE
                THEN 'COUNTEROFFER'

            /* Priority 5 — Severe requested-structure review route */
            WHEN ri.severe_requested_structure_trigger_flag IS TRUE
             AND ri.counteroffer_candidate_flag IS FALSE
                THEN 'MANUAL_REVIEW'

            /* Priority 6 — Manual review route */
            WHEN ri.manual_review_candidate_flag IS TRUE
                THEN 'MANUAL_REVIEW'

            /* Priority 7 — Clean approval route */
            WHEN ri.clean_approval_candidate_flag IS TRUE
                THEN 'APPROVE'

            /* Priority 8 — Residual strategy review fallback */
            ELSE 'MANUAL_REVIEW'
        END AS preliminary_decision_outcome,


        /*
        preliminary_decision_path:
            Route-level path explaining why the row is being sent toward the preliminary outcome.

        This is not the final decision_path.
        Final decision_path will be assigned after approved exposure, counteroffer feasibility,
        approved payment, approved PTI, approved Expected Loss, and reason-code logic are built.
        */
        CASE
            WHEN ri.hard_policy_stop_flag IS TRUE
                THEN 'HARD_POLICY_STOP'

            WHEN ri.synthetic_risk_decline_trigger_flag IS TRUE
                THEN 'SEVERE_SYNTHETIC_RISK'

            WHEN ri.dti_decline_trigger_flag IS TRUE
                THEN 'SEVERE_DTI_CAPACITY'

            WHEN ri.counteroffer_candidate_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBILITY_CHECK'

            WHEN ri.severe_requested_structure_trigger_flag IS TRUE
             AND ri.counteroffer_candidate_flag IS FALSE
                THEN 'REQUESTED_STRUCTURE_SEVERE_REVIEW'

            WHEN ri.manual_review_candidate_flag IS TRUE
                THEN 'MANUAL_REVIEW_CANDIDATE'

            WHEN ri.clean_approval_candidate_flag IS TRUE
                THEN 'CLEAN_APPROVAL_CANDIDATE'

            ELSE 'RESIDUAL_STRATEGY_REVIEW'
        END AS preliminary_decision_path,


        /*
        preliminary_decision_priority_rank:
            Numeric representation of the preliminary routing hierarchy.

        Lower values indicate higher-priority preliminary routing.
        This is not reason priority.
        */
        CASE
            WHEN ri.hard_policy_stop_flag IS TRUE
                THEN 1

            WHEN ri.synthetic_risk_decline_trigger_flag IS TRUE
                THEN 2

            WHEN ri.dti_decline_trigger_flag IS TRUE
                THEN 3

            WHEN ri.counteroffer_candidate_flag IS TRUE
                THEN 4

            WHEN ri.severe_requested_structure_trigger_flag IS TRUE
             AND ri.counteroffer_candidate_flag IS FALSE
                THEN 5

            WHEN ri.manual_review_candidate_flag IS TRUE
                THEN 6

            WHEN ri.clean_approval_candidate_flag IS TRUE
                THEN 7

            ELSE 8
        END AS preliminary_decision_priority_rank,


        /*
        preliminary_route_reason_family:
            Route-family diagnostic.

        This field supports audit-readable routing review, but it is not a final simulated reason
        code and not a final primary_reason_family.
        */
        CASE
            WHEN ri.hard_policy_stop_flag IS TRUE
                THEN 'HARD_POLICY_STOP'

            WHEN ri.synthetic_risk_decline_trigger_flag IS TRUE
                THEN 'SYNTHETIC_ESTIMATED_RISK'

            WHEN ri.dti_decline_trigger_flag IS TRUE
                THEN 'DTI_CAPACITY'

            WHEN ri.counteroffer_candidate_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBILITY'

            WHEN ri.severe_requested_structure_trigger_flag IS TRUE
             AND ri.counteroffer_candidate_flag IS FALSE
                THEN 'REQUESTED_STRUCTURE_REVIEW'

            WHEN ri.manual_review_candidate_flag IS TRUE
                THEN 'MANUAL_REVIEW'

            WHEN ri.clean_approval_candidate_flag IS TRUE
                THEN 'CLEAN_APPROVAL'

            ELSE 'RESIDUAL_REVIEW'
        END AS preliminary_route_reason_family

    FROM route_inputs ri
),

/*-----------------------------------------------------------------------------------------------
Create preliminary flags and exposure-routing requirements.

These are preliminary routing flags only.

Do not confuse:
    preliminary_approve_flag
with:
    final approval_flag

The final flags are created only after final decision_outcome is assigned.
-----------------------------------------------------------------------------------------------*/
final_preliminary_routing AS (
    SELECT
        pr.*,

        (pr.preliminary_decision_outcome = 'DECLINE') AS preliminary_decline_flag,
        (pr.preliminary_decision_outcome = 'COUNTEROFFER') AS preliminary_counteroffer_flag,
        (pr.preliminary_decision_outcome = 'MANUAL_REVIEW') AS preliminary_manual_review_flag,
        (pr.preliminary_decision_outcome = 'APPROVE') AS preliminary_approve_flag,

        /*
        requires_counteroffer_feasibility_flag:
            TRUE only for preliminary COUNTEROFFER routing.

        This means the row should be evaluated by later counteroffer feasibility logic.
        It does not mean a viable counteroffer has already been determined.
        */
        (pr.preliminary_decision_outcome = 'COUNTEROFFER')
            AS requires_counteroffer_feasibility_flag,

        /*
        requires_approved_exposure_calculation_flag:
            TRUE for preliminary APPROVE and COUNTEROFFER routes because later sections must
            calculate approved exposure fields for both paths.

        FALSE for preliminary DECLINE and MANUAL_REVIEW routes because:
            - DECLINE has no simulated offer exposure;
            - MANUAL_REVIEW is unresolved by design.
        */
        (pr.preliminary_decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
            AS requires_approved_exposure_calculation_flag

    FROM preliminary_routed pr
)

SELECT *
FROM final_preliminary_routing;



/***************************************************************************************************
SECTION 7.3 — LOCAL FAIL-FAST CHECKS FOR PRELIMINARY DECISION ROUTING
****************************************************************************************************

PURPOSE:
    Validate the Section 7 preliminary routing layer before final outcome, reason-code, approved
    exposure, approved payment, approved PTI, or approved Expected Loss logic is built.

IMPORTANT:
    These are local staging gatekeepers only.

    They are not full Module 2 QA.
    They are not final strategy validation.
    They are not reason-code validation.
    They are not approved-exposure validation.

***************************************************************************************************/

DO $$
DECLARE
    v_stage3_count BIGINT;
    v_stage4_count BIGINT;
    v_stage4_distinct_app_count BIGINT;

    v_duplicate_application_count BIGINT;
    v_null_preliminary_field_count BIGINT;
    v_invalid_preliminary_outcome_count BIGINT;
    v_preliminary_flag_reconciliation_failure_count BIGINT;

    v_hard_policy_route_violation_count BIGINT;
    v_synthetic_risk_route_violation_count BIGINT;
    v_dti_route_violation_count BIGINT;
    v_counteroffer_route_violation_count BIGINT;
    v_requested_structure_review_route_violation_count BIGINT;
    v_manual_review_route_violation_count BIGINT;
    v_clean_approval_route_violation_count BIGINT;
    v_residual_route_violation_count BIGINT;

    v_counteroffer_feasibility_flag_violation_count BIGINT;
    v_approved_exposure_requirement_violation_count BIGINT;

    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 6 to Section 7.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage3_count
    FROM tmp_m2_stage_3_rule_flags;

    SELECT COUNT(*)
    INTO v_stage4_count
    FROM tmp_m2_stage_4_preliminary_decision_routing;

    IF v_stage4_count <> v_stage3_count THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: row count changed from Section 6 to Section 7. Stage 3 rows: %, Stage 4 rows: %.',
            v_stage3_count,
            v_stage4_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage4_distinct_app_count
    FROM tmp_m2_stage_4_preliminary_decision_routing;

    IF v_stage4_distinct_app_count <> v_stage4_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_4_preliminary_decision_routing
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 7 failure: application_id uniqueness was not preserved. Stage 4 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage4_count,
            v_stage4_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary routing fields must be complete.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_preliminary_field_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE preliminary_decision_outcome IS NULL
       OR preliminary_decision_path IS NULL
       OR preliminary_decision_priority_rank IS NULL
       OR preliminary_decision_priority_rank <= 0
       OR preliminary_route_reason_family IS NULL
       OR preliminary_decline_flag IS NULL
       OR preliminary_counteroffer_flag IS NULL
       OR preliminary_manual_review_flag IS NULL
       OR preliminary_approve_flag IS NULL
       OR requires_counteroffer_feasibility_flag IS NULL
       OR requires_approved_exposure_calculation_flag IS NULL
       OR severe_requested_structure_trigger_flag IS NULL
       OR severe_requested_structure_trigger_count IS NULL
       OR severe_requested_structure_trigger_count < 0
       OR preliminary_route_trigger_count IS NULL
       OR preliminary_route_trigger_count < 0;

    IF v_null_preliminary_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) have null or invalid preliminary routing fields.',
            v_null_preliminary_field_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary_decision_outcome must be one of the locked taxonomy labels.

    These labels are preliminary routing outcomes only.
    Final decision_outcome is created later.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_invalid_preliminary_outcome_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE preliminary_decision_outcome NOT IN (
        'APPROVE',
        'COUNTEROFFER',
        'MANUAL_REVIEW',
        'DECLINE'
    );

    IF v_invalid_preliminary_outcome_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) have invalid preliminary_decision_outcome values.',
            v_invalid_preliminary_outcome_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: preliminary flags must reconcile to preliminary_decision_outcome.

    Exactly one preliminary flag must be TRUE per row.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_preliminary_flag_reconciliation_failure_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE (
            preliminary_decline_flag::INT
            + preliminary_counteroffer_flag::INT
            + preliminary_manual_review_flag::INT
            + preliminary_approve_flag::INT
          ) <> 1
       OR preliminary_decline_flag
          IS DISTINCT FROM (preliminary_decision_outcome = 'DECLINE')
       OR preliminary_counteroffer_flag
          IS DISTINCT FROM (preliminary_decision_outcome = 'COUNTEROFFER')
       OR preliminary_manual_review_flag
          IS DISTINCT FROM (preliminary_decision_outcome = 'MANUAL_REVIEW')
       OR preliminary_approve_flag
          IS DISTINCT FROM (preliminary_decision_outcome = 'APPROVE');

    IF v_preliminary_flag_reconciliation_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) have preliminary flag reconciliation failures.',
            v_preliminary_flag_reconciliation_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 1 hard simulated policy stop routing.

    Hard simulated policy stop triggers must route to preliminary DECLINE / HARD_POLICY_STOP.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_hard_policy_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE hard_policy_stop_flag IS TRUE
      AND NOT (
            preliminary_decision_outcome = 'DECLINE'
        AND preliminary_decision_path = 'HARD_POLICY_STOP'
        AND preliminary_decision_priority_rank = 1
        AND preliminary_route_reason_family = 'HARD_POLICY_STOP'
      );

    IF v_hard_policy_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 1 hard simulated policy stop routing.',
            v_hard_policy_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 2 severe synthetic estimated-risk routing.

    estimated_pd is the Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE hard_policy_stop_flag IS FALSE
      AND synthetic_risk_decline_trigger_flag IS TRUE
      AND NOT (
            preliminary_decision_outcome = 'DECLINE'
        AND preliminary_decision_path = 'SEVERE_SYNTHETIC_RISK'
        AND preliminary_decision_priority_rank = 2
        AND preliminary_route_reason_family = 'SYNTHETIC_ESTIMATED_RISK'
      );

    IF v_synthetic_risk_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 2 severe synthetic estimated-risk routing.',
            v_synthetic_risk_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 3 severe DTI capacity routing.

    DTI is an existing-obligation capacity signal and is not directly solved by counteroffer in
    Module 2 v1.0.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_dti_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE hard_policy_stop_flag IS FALSE
      AND synthetic_risk_decline_trigger_flag IS FALSE
      AND dti_decline_trigger_flag IS TRUE
      AND NOT (
            preliminary_decision_outcome = 'DECLINE'
        AND preliminary_decision_path = 'SEVERE_DTI_CAPACITY'
        AND preliminary_decision_priority_rank = 3
        AND preliminary_route_reason_family = 'DTI_CAPACITY'
      );

    IF v_dti_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 3 severe DTI capacity routing.',
            v_dti_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 4 counteroffer feasibility routing.

    preliminary COUNTEROFFER must only occur when counteroffer_candidate_flag is TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE (
            hard_policy_stop_flag IS FALSE
        AND synthetic_risk_decline_trigger_flag IS FALSE
        AND dti_decline_trigger_flag IS FALSE
        AND counteroffer_candidate_flag IS TRUE
        AND NOT (
                preliminary_decision_outcome = 'COUNTEROFFER'
            AND preliminary_decision_path = 'COUNTEROFFER_FEASIBILITY_CHECK'
            AND preliminary_decision_priority_rank = 4
            AND preliminary_route_reason_family = 'COUNTEROFFER_FEASIBILITY'
        )
    )
    OR (
            preliminary_decision_outcome = 'COUNTEROFFER'
        AND counteroffer_candidate_flag IS DISTINCT FROM TRUE
    );

    IF v_counteroffer_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 4 counteroffer feasibility routing.',
            v_counteroffer_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 5 severe requested-structure review routing.

    Severe requested-structure stress routes to preliminary MANUAL_REVIEW when no higher route has
    fired and the row is not already a counteroffer candidate.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_requested_structure_review_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE hard_policy_stop_flag IS FALSE
      AND synthetic_risk_decline_trigger_flag IS FALSE
      AND dti_decline_trigger_flag IS FALSE
      AND counteroffer_candidate_flag IS FALSE
      AND severe_requested_structure_trigger_flag IS TRUE
      AND NOT (
            preliminary_decision_outcome = 'MANUAL_REVIEW'
        AND preliminary_decision_path = 'REQUESTED_STRUCTURE_SEVERE_REVIEW'
        AND preliminary_decision_priority_rank = 5
        AND preliminary_route_reason_family = 'REQUESTED_STRUCTURE_REVIEW'
      );

    IF v_requested_structure_review_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 5 severe requested-structure review routing.',
            v_requested_structure_review_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 6 manual review candidate routing.

    Manual review remains unresolved. This is preliminary routing only.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE hard_policy_stop_flag IS FALSE
      AND synthetic_risk_decline_trigger_flag IS FALSE
      AND dti_decline_trigger_flag IS FALSE
      AND counteroffer_candidate_flag IS FALSE
      AND severe_requested_structure_trigger_flag IS FALSE
      AND manual_review_candidate_flag IS TRUE
      AND NOT (
            preliminary_decision_outcome = 'MANUAL_REVIEW'
        AND preliminary_decision_path = 'MANUAL_REVIEW_CANDIDATE'
        AND preliminary_decision_priority_rank = 6
        AND preliminary_route_reason_family = 'MANUAL_REVIEW'
      );

    IF v_manual_review_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 6 manual review candidate routing.',
            v_manual_review_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 7 clean approval candidate routing.

    preliminary APPROVE may only occur when clean_approval_candidate_flag is TRUE.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_clean_approval_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE (
            hard_policy_stop_flag IS FALSE
        AND synthetic_risk_decline_trigger_flag IS FALSE
        AND dti_decline_trigger_flag IS FALSE
        AND counteroffer_candidate_flag IS FALSE
        AND severe_requested_structure_trigger_flag IS FALSE
        AND manual_review_candidate_flag IS FALSE
        AND clean_approval_candidate_flag IS TRUE
        AND NOT (
                preliminary_decision_outcome = 'APPROVE'
            AND preliminary_decision_path = 'CLEAN_APPROVAL_CANDIDATE'
            AND preliminary_decision_priority_rank = 7
            AND preliminary_route_reason_family = 'CLEAN_APPROVAL'
        )
    )
    OR (
            preliminary_decision_outcome = 'APPROVE'
        AND clean_approval_candidate_flag IS DISTINCT FROM TRUE
    );

    IF v_clean_approval_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) violate Priority 7 clean approval candidate routing.',
            v_clean_approval_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Priority 8 residual strategy review routing.

    Residual review should occur only when no higher-priority route applies.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_residual_route_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE preliminary_decision_path = 'RESIDUAL_STRATEGY_REVIEW'
      AND (
            hard_policy_stop_flag IS TRUE
         OR synthetic_risk_decline_trigger_flag IS TRUE
         OR dti_decline_trigger_flag IS TRUE
         OR counteroffer_candidate_flag IS TRUE
         OR severe_requested_structure_trigger_flag IS TRUE
         OR manual_review_candidate_flag IS TRUE
         OR clean_approval_candidate_flag IS TRUE
      );

    IF v_residual_route_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) route to residual strategy review even though a higher-priority route applies.',
            v_residual_route_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: counteroffer feasibility requirement.

    preliminary COUNTEROFFER must require counteroffer feasibility logic.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_feasibility_flag_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE requires_counteroffer_feasibility_flag
          IS DISTINCT FROM (preliminary_decision_outcome = 'COUNTEROFFER');

    IF v_counteroffer_feasibility_flag_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) have invalid requires_counteroffer_feasibility_flag values.',
            v_counteroffer_feasibility_flag_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: approved exposure calculation requirement.

    preliminary APPROVE and preliminary COUNTEROFFER require later approved-exposure calculation.
    preliminary DECLINE and preliminary MANUAL_REVIEW do not.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approved_exposure_requirement_violation_count
    FROM tmp_m2_stage_4_preliminary_decision_routing
    WHERE requires_approved_exposure_calculation_flag
          IS DISTINCT FROM (preliminary_decision_outcome IN ('APPROVE', 'COUNTEROFFER'));

    IF v_approved_exposure_requirement_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: % row(s) have invalid requires_approved_exposure_calculation_flag values.',
            v_approved_exposure_requirement_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: forbidden final-output fields must not exist yet.

    Section 7 is not allowed to create final decisions, reason codes, approved exposure, approved
    payment, approved PTI, or approved Expected Loss.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_4_preliminary_decision_routing'::REGCLASS
      AND attnum > 0
      AND NOT attisdropped
      AND attname IN (
            'decision_outcome',
            'decision_path',
            'approval_flag',
            'decline_flag',
            'manual_review_flag',
            'counteroffer_flag',
            'simulated_offer_exposure_flag',

            'primary_reason_code',
            'secondary_reason_code',
            'tertiary_reason_code',
            'triggered_reason_code_list',
            'reason_priority_rank',
            'primary_reason_family',

            'approved_amount',
            'counteroffer_amount',
            'approved_monthly_payment_proxy',
            'approved_payment_to_income_ratio',
            'approved_expected_loss_amount'
      );

    IF v_forbidden_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 7 failure: forbidden final-output field(s) were created before final decision / reason-code / approved exposure sections.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 7.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 7 preliminary routing layer.

IMPORTANT:
    These are not final strategy validation queries.
    They should not be interpreted as final approval, decline, manual review, or counteroffer rates.

    They are preliminary routing diagnostics only.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
7.4.1 Count by preliminary_decision_outcome.

Interpretation:
    This is preliminary route distribution only, not final decision distribution.
-----------------------------------------------------------------------------------------------*/
SELECT
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY preliminary_decision_outcome
ORDER BY
    CASE preliminary_decision_outcome
        WHEN 'APPROVE' THEN 1
        WHEN 'COUNTEROFFER' THEN 2
        WHEN 'MANUAL_REVIEW' THEN 3
        WHEN 'DECLINE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
7.4.2 Count by preliminary_decision_path.
-----------------------------------------------------------------------------------------------*/
SELECT
    preliminary_decision_path,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY preliminary_decision_path
ORDER BY preliminary_decision_path;


/*-----------------------------------------------------------------------------------------------
7.4.3 Count by preliminary_decision_priority_rank.
-----------------------------------------------------------------------------------------------*/
SELECT
    preliminary_decision_priority_rank,
    preliminary_decision_path,
    preliminary_route_reason_family,
    COUNT(*) AS row_count
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    preliminary_decision_priority_rank,
    preliminary_decision_path,
    preliminary_route_reason_family
ORDER BY
    preliminary_decision_priority_rank,
    preliminary_decision_path;


/*-----------------------------------------------------------------------------------------------
7.4.4 Count by preliminary_route_reason_family.

Interpretation:
    preliminary_route_reason_family is a routing-family diagnostic, not a final reason-code family.
-----------------------------------------------------------------------------------------------*/
SELECT
    preliminary_route_reason_family,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY preliminary_route_reason_family
ORDER BY preliminary_route_reason_family;


/*-----------------------------------------------------------------------------------------------
7.4.5 Product × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    product_type_policy_key,
    preliminary_decision_outcome
ORDER BY
    product_type_policy_key,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.6 Score band × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    score_band_policy_key,
    preliminary_decision_outcome
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.7 Requested PTI bucket × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    requested_pti_bucket,
    preliminary_decision_outcome
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.8 Strategy risk tier × preliminary_decision_outcome.

Interpretation:
    strategy_risk_tier uses estimated_pd as the synthetic estimated-PD proxy input.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    strategy_risk_tier,
    preliminary_decision_outcome
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.9 Requested exposure tier × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_tier,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    requested_exposure_tier,
    preliminary_decision_outcome
ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'WITHIN_PRODUCT_LIMITS' THEN 2
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 4
        ELSE 99
    END,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.10 Requested Expected Loss tier × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_expected_loss_tier,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    requested_expected_loss_tier,
    preliminary_decision_outcome
ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.11 Mixed-signal profile × preliminary_decision_outcome.

Interpretation:
    mixed_signal_profile_type is diagnostic. It is not a final outcome driver by itself.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(preliminary_route_trigger_count) AS avg_preliminary_route_trigger_count
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    mixed_signal_profile_type,
    preliminary_decision_outcome
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
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.12 Borderline profile flag × preliminary_decision_outcome.

Interpretation:
    borderline_profile_flag uses governed proximity logic. It does not automatically create final
    manual review routing.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(preliminary_route_trigger_count) AS avg_preliminary_route_trigger_count
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    borderline_profile_flag,
    preliminary_decision_outcome
ORDER BY
    borderline_profile_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.13 Hard policy stop flag × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    hard_policy_stop_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    hard_policy_stop_flag,
    preliminary_decision_outcome
ORDER BY
    hard_policy_stop_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.14 Synthetic risk decline trigger × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    synthetic_risk_decline_trigger_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    synthetic_risk_decline_trigger_flag,
    preliminary_decision_outcome
ORDER BY
    synthetic_risk_decline_trigger_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.15 DTI decline trigger × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    dti_decline_trigger_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    dti_decline_trigger_flag,
    preliminary_decision_outcome
ORDER BY
    dti_decline_trigger_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.16 Counteroffer candidate flag × preliminary_decision_outcome.

Interpretation:
    preliminary COUNTEROFFER is a routing outcome for later feasibility logic, not a final
    counteroffer outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_candidate_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    counteroffer_candidate_flag,
    preliminary_decision_outcome
ORDER BY
    counteroffer_candidate_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.17 Manual review candidate flag × preliminary_decision_outcome.

Interpretation:
    preliminary MANUAL_REVIEW remains unresolved. Final outcome is not assigned here.
-----------------------------------------------------------------------------------------------*/
SELECT
    manual_review_candidate_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    manual_review_candidate_flag,
    preliminary_decision_outcome
ORDER BY
    manual_review_candidate_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.18 Clean approval candidate flag × preliminary_decision_outcome.

Interpretation:
    preliminary APPROVE is a clean approval candidate route only.
-----------------------------------------------------------------------------------------------*/
SELECT
    clean_approval_candidate_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    clean_approval_candidate_flag,
    preliminary_decision_outcome
ORDER BY
    clean_approval_candidate_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.19 requires_counteroffer_feasibility_flag × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requires_counteroffer_feasibility_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    requires_counteroffer_feasibility_flag,
    preliminary_decision_outcome
ORDER BY
    requires_counteroffer_feasibility_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.20 requires_approved_exposure_calculation_flag × preliminary_decision_outcome.
-----------------------------------------------------------------------------------------------*/
SELECT
    requires_approved_exposure_calculation_flag,
    preliminary_decision_outcome,
    COUNT(*) AS row_count
FROM tmp_m2_stage_4_preliminary_decision_routing
GROUP BY
    requires_approved_exposure_calculation_flag,
    preliminary_decision_outcome
ORDER BY
    requires_approved_exposure_calculation_flag,
    preliminary_decision_outcome;


/*-----------------------------------------------------------------------------------------------
7.4.21 Preliminary route trigger-count profile.

Purpose:
    Shows how many high-level preliminary routing families were active before hierarchy selection.
    This is a staging diagnostic only.
-----------------------------------------------------------------------------------------------*/
SELECT
    MIN(preliminary_route_trigger_count) AS min_preliminary_route_trigger_count,
    AVG(preliminary_route_trigger_count) AS avg_preliminary_route_trigger_count,
    MAX(preliminary_route_trigger_count) AS max_preliminary_route_trigger_count,

    MIN(severe_requested_structure_trigger_count) AS min_severe_requested_structure_trigger_count,
    AVG(severe_requested_structure_trigger_count) AS avg_severe_requested_structure_trigger_count,
    MAX(severe_requested_structure_trigger_count) AS max_severe_requested_structure_trigger_count
FROM tmp_m2_stage_4_preliminary_decision_routing;


/***************************************************************************************************
END OF SECTION 7 — PRELIMINARY DECISION ROUTING LAYER

If execution reaches this point:
    1. tmp_m2_stage_4_preliminary_decision_routing exists.
    2. All Section 6 fields have been preserved.
    3. Module 1 lineage remains attached.
    4. Module 2 strategy metadata remains attached.
    5. preliminary_decision_outcome is populated for every row.
    6. preliminary_decision_path is populated for every row.
    7. preliminary_decision_priority_rank is populated for every row.
    8. preliminary_route_reason_family is populated for every row as a routing-family diagnostic.
    9. Preliminary flags reconcile to preliminary_decision_outcome.
    10. Counteroffer feasibility and approved exposure calculation requirement flags are populated.
    11. Preliminary routing hierarchy is locally validated.

No final decision_outcome has been generated.
No final decision_path has been generated.
No final approval / decline / manual review / counteroffer flags have been created.
No simulated_offer_exposure_flag has been created.
No simulated reason codes have been assigned.
No approved amount has been calculated.
No counteroffer amount has been calculated.
No approved payment proxy has been calculated.
No approved payment-to-income ratio has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No strategy archive rows have been inserted.

***************************************************************************************************/
```

---

# 3. What Section 7 establishes

Section 7 creates:

```text
tmp_m2_stage_4_preliminary_decision_routing
```

It converts overlapping Section 6 trigger flags into exactly one **preliminary route** per application, using the locked hierarchy:

```text
hard simulated policy stop
severe synthetic estimated-risk
severe DTI capacity
counteroffer feasibility check
severe requested-structure review
manual review candidate
clean approval candidate
residual strategy review
```

It also adds preliminary routing flags and identifies whether later counteroffer feasibility or approved-exposure calculation is required.

---

# 4. What Section 7 intentionally does not build

Section 7 does not build final `decision_outcome`, final `decision_path`, final approval / decline / manual review / counteroffer flags, `simulated_offer_exposure_flag`, reason codes, approved amount, counteroffer amount, approved monthly payment proxy, approved payment-to-income ratio, approved Expected Loss, latest-run final output, archive insert logic, or the full QA framework.

The output is preliminary routing only.

---

# 5. Recommended next build step

Next should be:

```text
Section 8 — Approved Exposure and Counteroffer Feasibility Layer
```

That section should calculate approved exposure requirements for preliminary `APPROVE` and preliminary `COUNTEROFFER` routes, including:

```text
approved_amount_preliminary
counteroffer_amount_preliminary
exposure_reduction_flag
exposure_reduction_amount
exposure_reduction_pct
approved_monthly_payment_proxy
approved_payment_to_income_ratio
approved_expected_loss_amount
counteroffer_feasibility_pass_flag
counteroffer_feasibility_failure_reason
```

It should still avoid final reason-code assignment until the final decision outcome is locked.
<!-- END_MESSAGE C038-M00116 -->


---

<a id="c038-m00117"></a>

### C038-M00117

**Andrew** · 2026-05-06T13:20:01.724000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00117 -->
This is strong. I agree with the Section 6 hardening patch direction and the Section 7 Preliminary Decision Routing Layer.

Section 7 should be treated as provisionally accepted, subject to the pre-flight checks below.

Section 7 correctly:
- keeps routing preliminary rather than final
- preserves all prior lineage, segmentation, threshold, and trigger fields
- converts overlapping Section 6 rule flags into one preliminary route
- uses preliminary_decision_outcome rather than final decision_outcome
- keeps COUNTEROFFER as a feasibility route, not a finalized counteroffer
- keeps MANUAL_REVIEW unresolved
- routes hard simulated policy stops, severe synthetic estimated-risk, and severe DTI ahead of counteroffer / review / approval paths
- includes severe requested-structure review routing
- creates preliminary flags only
- creates requires_counteroffer_feasibility_flag
- creates requires_approved_exposure_calculation_flag
- avoids final decision_outcome
- avoids final decision_path
- avoids final approval / decline / manual review / counteroffer flags
- avoids simulated_offer_exposure_flag
- avoids reason codes
- avoids approved amount
- avoids approved payment / approved PTI
- avoids approved Expected Loss
- avoids latest-run output and archive insert logic

Do not rewrite Sections 0–7 unless the pre-flight review identifies a specific dependency issue.

================================================================================
1. SECTION 6 / SECTION 7 PRE-FLIGHT REVIEW BEFORE SECTION 8
================================================================================

Before writing Section 8, please do a brief targeted pre-flight review of the Section 6 hardening patch and Section 7 routing layer.

Confirm that Section 6 includes:

1. Band-coverage diagnostic fields:
   - synthetic_risk_band_flag_count
   - dti_band_flag_count

2. Local Section 6 gatekeeper validation that fails if:
   - synthetic_risk_band_flag_count <> 1
   - dti_band_flag_count <> 1

3. Any required PL/pgSQL variables are declared if the gatekeeper uses SELECT COUNT(*) INTO variables.

4. The band-coverage checks apply only to true banding families:
   - synthetic estimated-risk band
   - DTI band

5. The checks do NOT force mutual exclusivity across broader overlapping trigger families.

Confirm that Section 7 includes:

1. preliminary_decision_outcome
2. preliminary_decision_path
3. preliminary_decision_priority_rank
4. preliminary_route_reason_family
5. preliminary_decline_flag
6. preliminary_counteroffer_flag
7. preliminary_manual_review_flag
8. preliminary_approve_flag
9. requires_counteroffer_feasibility_flag
10. requires_approved_exposure_calculation_flag

Also confirm that Section 7 does NOT create:
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
- approved_amount
- counteroffer_amount
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount

If the pre-flight review finds an issue, provide a targeted BEFORE / AFTER patch only.

If no issue is found, explicitly state:

“Sections 6 and 7 pre-flight review passed; no patch required.”

================================================================================
2. SECTION 7 ACCEPTANCE CRITERIA
================================================================================

After any pre-flight patch, treat Section 7 as accepted if it establishes:

- tmp_m2_stage_4_preliminary_decision_routing exists
- row count is unchanged from tmp_m2_stage_3_rule_flags
- application_id remains unique
- Module 1 lineage remains preserved
- Module 2 strategy metadata remains preserved
- all Section 6 rule flags remain preserved
- preliminary_decision_outcome is populated for every row
- preliminary_decision_outcome is one of:
  - APPROVE
  - COUNTEROFFER
  - MANUAL_REVIEW
  - DECLINE
- preliminary_decision_path is populated
- preliminary_decision_priority_rank is populated
- preliminary_route_reason_family is populated
- exactly one preliminary outcome flag is true per row
- hard_policy_stop_flag routes to preliminary DECLINE
- severe synthetic estimated-risk routes to preliminary DECLINE unless hard policy stop already routed it
- severe DTI routes to preliminary DECLINE unless a higher-priority route already routed it
- counteroffer_candidate_flag routes to preliminary COUNTEROFFER when no higher-priority decline route applies
- severe requested-structure stress routes to preliminary MANUAL_REVIEW when not already counteroffer-eligible and no higher-priority route applies
- manual_review_candidate_flag routes to preliminary MANUAL_REVIEW when no higher-priority route applies
- clean_approval_candidate_flag routes to preliminary APPROVE when no higher-priority route applies
- residual unclassified rows route to preliminary MANUAL_REVIEW
- preliminary COUNTEROFFER rows require counteroffer feasibility evaluation later
- preliminary APPROVE and preliminary COUNTEROFFER rows require approved exposure calculation later
- no final decision outcome exists yet
- no final flags exist yet
- no reason codes exist yet
- no approved exposure economics exist yet
- no final latest-run strategy table is built yet
- no archive rows are inserted yet

================================================================================
3. NEXT BUILD SCOPE: SECTION 8 ONLY
================================================================================

After the Section 6 / Section 7 pre-flight review, please build only:

SECTION 8 — APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY LAYER

Recommended staged table:

tmp_m2_stage_5_exposure_treatment

Section 8 should consume:

tmp_m2_stage_4_preliminary_decision_routing

Do not build:
- final decision_outcome
- final decision_path
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
- full QA framework

Those belong to later sections.

================================================================================
4. SECTION 8 OBJECTIVE
================================================================================

Section 8 should calculate preliminary approved-exposure economics and counteroffer feasibility.

Section 8 should answer:

“Given the preliminary route, what approved exposure treatment would be economically and structurally feasible?”

Section 8 should not answer:

“What is the final strategy outcome?”

Final decision_outcome should be resolved later, after:
- counteroffer feasibility is evaluated
- approved exposure economics are available
- approved payment and approved PTI are available
- approved Expected Loss is available
- reason-code logic is built

Important:
Section 8 creates preliminary exposure-treatment outputs only.

It should not assign final outcome flags or final reason codes.

================================================================================
5. CORE SECTION 8 OUTPUT FIELDS
================================================================================

Section 8 should preserve all fields from:

tmp_m2_stage_4_preliminary_decision_routing

and add the following fields.

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

Do not create final output fields yet.

================================================================================
6. IMPLEMENTATION STRUCTURE REQUIREMENT
================================================================================

Because PostgreSQL does not allow a SELECT-list alias to be reused in another expression in the same SELECT list, Section 8 should use staged CTEs.

Recommended internal CTE pattern:

1. exposure_inputs
   Preserve Section 7 fields and prepare route-specific context.

2. counteroffer_components
   Calculate:
   - counteroffer_product_cap_amount
   - counteroffer_pti_target_amount
   - counteroffer_el_cap_amount
   - counteroffer_raw_max_feasible_amount
   - counteroffer_min_viable_amount

3. counteroffer_rounding
   Calculate:
   - counteroffer_rounded_amount

4. exposure_amount_assignment
   Assign:
   - approved_amount_preliminary
   - counteroffer_amount_preliminary
   - exposure_reduction fields

5. approved_affordability
   Calculate:
   - approved_monthly_payment_proxy_preliminary
   - approved_payment_to_income_ratio_preliminary

6. approved_economics
   Calculate:
   - approved_expected_loss_amount_preliminary
   - approved_el_reduction_amount_preliminary
   - approved_el_reduction_pct_preliminary

7. counteroffer_feasibility
   Calculate:
   - counteroffer_feasibility_pass_flag
   - counteroffer_feasibility_failure_reason
   - counteroffer_feasibility_constraint_count
   - exposure_treatment_status

This staging is important for readability, auditability, and safe SQL execution.

================================================================================
7. APPROVE ROUTE CONVENTION
================================================================================

For preliminary_decision_outcome = APPROVE:

- approved_amount_preliminary = requested_amount
- counteroffer_amount_preliminary = NULL
- exposure_reduction_flag_preliminary = FALSE
- exposure_reduction_amount_preliminary = 0
- exposure_reduction_pct_preliminary = 0
- approved_monthly_payment_proxy_preliminary = requested_monthly_payment_proxy
- approved_payment_to_income_ratio_preliminary = requested_payment_to_income_ratio
- approved_expected_loss_amount_preliminary = requested_expected_loss_amount
- approved_el_reduction_amount_preliminary = 0
- approved_el_reduction_pct_preliminary = 0
- counteroffer_feasibility_evaluated_flag = FALSE
- counteroffer_feasibility_pass_flag = NULL
- counteroffer_feasibility_failure_reason = NULL
- counteroffer_feasibility_constraint_count = NULL
- exposure_treatment_status = APPROVED_AS_REQUESTED_PRELIMINARY
- exposure_treatment_path = APPROVE_AS_REQUESTED

Important:
This remains preliminary. Final APPROVE is not assigned in Section 8.

================================================================================
8. DECLINE ROUTE CONVENTION
================================================================================

For preliminary_decision_outcome = DECLINE:

- approved_amount_preliminary = 0
- counteroffer_amount_preliminary = NULL
- exposure_reduction_flag_preliminary = FALSE
- exposure_reduction_amount_preliminary = requested_amount
- exposure_reduction_pct_preliminary = 1.0
- approved_monthly_payment_proxy_preliminary = 0
- approved_payment_to_income_ratio_preliminary = 0
- approved_expected_loss_amount_preliminary = 0
- approved_el_reduction_amount_preliminary = requested_expected_loss_amount
- approved_el_reduction_pct_preliminary =
    CASE
        WHEN requested_expected_loss_amount > 0 THEN 1.0
        ELSE 0
    END
- counteroffer_feasibility_evaluated_flag = FALSE
- counteroffer_feasibility_pass_flag = NULL
- counteroffer_feasibility_failure_reason = NULL
- counteroffer_feasibility_constraint_count = NULL
- exposure_treatment_status = NO_OFFER_PRELIMINARY_DECLINE
- exposure_treatment_path = NO_OFFER

Important:
This follows the locked decline exposure convention, but final DECLINE is still not assigned in Section 8.

================================================================================
9. MANUAL REVIEW ROUTE CONVENTION
================================================================================

For preliminary_decision_outcome = MANUAL_REVIEW:

- approved_amount_preliminary = NULL
- counteroffer_amount_preliminary = NULL
- exposure_reduction_flag_preliminary = FALSE
- exposure_reduction_amount_preliminary = NULL
- exposure_reduction_pct_preliminary = NULL
- approved_monthly_payment_proxy_preliminary = NULL
- approved_payment_to_income_ratio_preliminary = NULL
- approved_expected_loss_amount_preliminary = NULL
- approved_el_reduction_amount_preliminary = NULL
- approved_el_reduction_pct_preliminary = NULL
- counteroffer_feasibility_evaluated_flag = FALSE
- counteroffer_feasibility_pass_flag = NULL
- counteroffer_feasibility_failure_reason = NULL
- counteroffer_feasibility_constraint_count = NULL
- exposure_treatment_status = UNRESOLVED_MANUAL_REVIEW
- exposure_treatment_path = MANUAL_REVIEW_UNRESOLVED

Manual review remains unresolved by design.

================================================================================
10. COUNTEROFFER ROUTE CALCULATION
================================================================================

For preliminary_decision_outcome = COUNTEROFFER:

Section 8 should evaluate whether a viable simulated counteroffer exists.

Counteroffer feasibility should use product-specific controls carried forward from prior stages:

- counteroffer_allowed_flag
- product_min_approved_amount
- product_max_approved_amount
- product_min_counteroffer_pct
- product_max_exposure_reduction_pct
- counteroffer_target_pti
- product_approved_el_cap
- approved_amount_rounding_increment

Do not assume a counteroffer is feasible just because preliminary_decision_outcome = COUNTEROFFER.

Important:
COUNTEROFFER at this point means:

“This row should be tested for reduced-exposure feasibility.”

It does not mean:

“A viable counteroffer has already been created.”

================================================================================
11. COUNTEROFFER MAXIMUM FEASIBLE AMOUNT
================================================================================

Calculate the main counteroffer ceiling components.

--------------------------------------------------------------------------------
1. Product cap amount
--------------------------------------------------------------------------------

counteroffer_product_cap_amount =
    LEAST(requested_amount, product_max_approved_amount)

Interpretation:
The approved exposure cannot exceed either the original requested amount or the product-specific maximum approved amount.

--------------------------------------------------------------------------------
2. PTI target amount
--------------------------------------------------------------------------------

If requested_payment_to_income_ratio > 0:

counteroffer_pti_target_amount =
    requested_amount
    * counteroffer_target_pti
    / requested_payment_to_income_ratio

Else:
    requested_amount

Interpretation:
Because approved payment is initially scaled proportionally, this estimates the approved amount that would bring approved PTI to the target PTI.

This remains a strategy-simulation proxy, not a recalculated contractual amortization schedule.

--------------------------------------------------------------------------------
3. Approved Expected Loss cap amount
--------------------------------------------------------------------------------

counteroffer_el_cap_amount =
    product_approved_el_cap / NULLIF(estimated_pd * estimated_lgd, 0)

Interpretation:
This is the maximum approved exposure that can satisfy the approved Expected Loss cap.

Important:
This uses approved-exposure Expected Loss logic. It is appropriate in Section 8 because approved exposure is now being evaluated.

--------------------------------------------------------------------------------
4. Raw maximum feasible amount
--------------------------------------------------------------------------------

counteroffer_raw_max_feasible_amount =
    LEAST(
        requested_amount,
        counteroffer_product_cap_amount,
        counteroffer_pti_target_amount,
        counteroffer_el_cap_amount
    )

Interpretation:
The raw maximum feasible counteroffer amount is the most conservative of:
- requested amount
- product cap
- PTI target amount
- approved Expected Loss cap amount

================================================================================
12. COUNTEROFFER MINIMUM VIABLE AMOUNT
================================================================================

Calculate the minimum viable amount that still represents a meaningful simulated offer and respects the maximum reduction rule.

counteroffer_min_viable_amount =
    GREATEST(
        product_min_approved_amount,
        requested_amount * product_min_counteroffer_pct,
        requested_amount * (1 - product_max_exposure_reduction_pct)
    )

Interpretation:
The counteroffer must not fall below:
- product minimum approved amount
- minimum viable percentage of requested amount
- the floor implied by maximum permitted exposure reduction

================================================================================
13. COUNTEROFFER ROUNDING CONVENTION
================================================================================

Apply approved amount rounding conservatively.

Recommended:

counteroffer_rounded_amount =
    FLOOR(counteroffer_raw_max_feasible_amount / approved_amount_rounding_increment)
    * approved_amount_rounding_increment

Reason:
Rounding down ensures the approved amount does not accidentally exceed:
- product cap
- PTI target
- approved Expected Loss cap

If rounding causes the amount to fall below counteroffer_min_viable_amount, the counteroffer should fail feasibility rather than silently increasing above a constraint.

================================================================================
14. COUNTEROFFER PRELIMINARY APPROVED PAYMENT / PTI / EL
================================================================================

For feasible counteroffer evaluation, calculate preliminary approved economics using the rounded amount.

approved_monthly_payment_proxy_preliminary =
    requested_monthly_payment_proxy
    * counteroffer_rounded_amount
    / NULLIF(requested_amount, 0)

approved_payment_to_income_ratio_preliminary =
    approved_monthly_payment_proxy_preliminary
    / NULLIF((annual_income / 12.0), 0)

approved_expected_loss_amount_preliminary =
    counteroffer_rounded_amount
    * estimated_pd
    * estimated_lgd

Important:
- approved_monthly_payment_proxy_preliminary is a proportional strategy-simulation proxy.
- approved_payment_to_income_ratio_preliminary is the post-exposure-treatment affordability proxy.
- approved_expected_loss_amount_preliminary uses approved exposure, not requested exposure.
- estimated_pd remains the Module 1 synthetic estimated-PD proxy input.
- Module 2 does not recalculate estimated_pd.

================================================================================
15. COUNTEROFFER FEASIBILITY PASS RULE
================================================================================

A counteroffer should pass feasibility only if all of the following are true:

- preliminary_decision_outcome = COUNTEROFFER
- counteroffer_allowed_flag = TRUE
- counteroffer_rounded_amount IS NOT NULL
- counteroffer_rounded_amount > 0
- counteroffer_rounded_amount < requested_amount
- counteroffer_rounded_amount >= product_min_approved_amount
- counteroffer_rounded_amount >= requested_amount * product_min_counteroffer_pct
- counteroffer_rounded_amount >= requested_amount * (1 - product_max_exposure_reduction_pct)
- counteroffer_rounded_amount <= product_max_approved_amount
- approved_payment_to_income_ratio_preliminary <= counteroffer_target_pti
- approved_expected_loss_amount_preliminary <= product_approved_el_cap

If these conditions are satisfied:

- approved_amount_preliminary = counteroffer_rounded_amount
- counteroffer_amount_preliminary = approved_amount_preliminary
- exposure_reduction_flag_preliminary = TRUE
- exposure_reduction_amount_preliminary = requested_amount - approved_amount_preliminary
- exposure_reduction_pct_preliminary =
    exposure_reduction_amount_preliminary / NULLIF(requested_amount, 0)
- counteroffer_feasibility_evaluated_flag = TRUE
- counteroffer_feasibility_pass_flag = TRUE
- exposure_treatment_status = COUNTEROFFER_FEASIBLE_PRELIMINARY
- exposure_treatment_path = COUNTEROFFER_FEASIBLE

If feasibility fails:

- approved_amount_preliminary = NULL
- counteroffer_amount_preliminary = NULL
- exposure_reduction_flag_preliminary = FALSE
- exposure_reduction_amount_preliminary = NULL
- exposure_reduction_pct_preliminary = NULL
- approved_monthly_payment_proxy_preliminary = NULL
- approved_payment_to_income_ratio_preliminary = NULL
- approved_expected_loss_amount_preliminary = NULL
- approved_el_reduction_amount_preliminary = NULL
- approved_el_reduction_pct_preliminary = NULL
- counteroffer_feasibility_evaluated_flag = TRUE
- counteroffer_feasibility_pass_flag = FALSE
- exposure_treatment_status = COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY
- exposure_treatment_path = COUNTEROFFER_NOT_FEASIBLE

Final handling of failed counteroffers should occur later in the final decision-resolution section.

================================================================================
16. COUNTEROFFER FAILURE REASON CONVENTION
================================================================================

For preliminary COUNTEROFFER rows where counteroffer_feasibility_pass_flag = FALSE, populate:

counteroffer_feasibility_failure_reason

Use a clear priority order so the failure reason is deterministic.

Recommended priority order:

1. COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT
   counteroffer_allowed_flag = FALSE

2. COUNTEROFFER_RAW_AMOUNT_NULL
   counteroffer_raw_max_feasible_amount IS NULL

3. COUNTEROFFER_ROUNDED_AMOUNT_NULL
   counteroffer_rounded_amount IS NULL

4. COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE
   counteroffer_rounded_amount <= 0

5. COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT
   counteroffer_rounded_amount >= requested_amount

6. COUNTEROFFER_BELOW_PRODUCT_MINIMUM
   counteroffer_rounded_amount < product_min_approved_amount

7. COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT
   counteroffer_rounded_amount < requested_amount * product_min_counteroffer_pct

8. COUNTEROFFER_EXCEEDS_MAX_REDUCTION
   counteroffer_rounded_amount < requested_amount * (1 - product_max_exposure_reduction_pct)

9. COUNTEROFFER_EXCEEDS_PRODUCT_CAP
   counteroffer_rounded_amount > product_max_approved_amount

10. COUNTEROFFER_PTI_STILL_ABOVE_TARGET
    approved_payment_to_income_ratio_preliminary > counteroffer_target_pti

11. COUNTEROFFER_APPROVED_EL_ABOVE_CAP
    approved_expected_loss_amount_preliminary > product_approved_el_cap

12. COUNTEROFFER_FEASIBILITY_UNKNOWN
    fallback only if none of the above explain the failed feasibility check

For non-counteroffer preliminary routes:
- counteroffer_feasibility_failure_reason = NULL

================================================================================
17. COUNTEROFFER FEASIBILITY CONSTRAINT COUNT
================================================================================

For preliminary COUNTEROFFER rows, calculate:

counteroffer_feasibility_constraint_count

as the number of failed feasibility constraints.

For non-counteroffer preliminary routes:
- counteroffer_feasibility_constraint_count = NULL

Recommended failed-constraint components:
- counteroffer_allowed_flag = FALSE
- counteroffer_rounded_amount IS NULL
- counteroffer_rounded_amount <= 0
- counteroffer_rounded_amount >= requested_amount
- counteroffer_rounded_amount < product_min_approved_amount
- counteroffer_rounded_amount < requested_amount * product_min_counteroffer_pct
- counteroffer_rounded_amount < requested_amount * (1 - product_max_exposure_reduction_pct)
- counteroffer_rounded_amount > product_max_approved_amount
- approved_payment_to_income_ratio_preliminary > counteroffer_target_pti
- approved_expected_loss_amount_preliminary > product_approved_el_cap

Interpretation:
This count is diagnostic only. It helps explain how many feasibility constraints prevented a preliminary COUNTEROFFER route from becoming a viable preliminary exposure treatment.

================================================================================
18. SECTION 8 LOCAL GATEKEEPERS
================================================================================

At the end of Section 8, include local fail-fast checks.

Validate:

1. Structural preservation
- row count is unchanged from tmp_m2_stage_4_preliminary_decision_routing
- application_id remains unique

2. Required field completeness
- exposure_treatment_status is non-null for every row
- exposure_treatment_path is non-null for every row
- counteroffer_feasibility_evaluated_flag is non-null for every row

3. APPROVE preliminary route consistency
For preliminary_decision_outcome = APPROVE:
- approved_amount_preliminary = requested_amount
- counteroffer_amount_preliminary IS NULL
- exposure_reduction_flag_preliminary = FALSE
- exposure_reduction_amount_preliminary = 0
- exposure_reduction_pct_preliminary = 0
- approved_monthly_payment_proxy_preliminary = requested_monthly_payment_proxy
- approved_payment_to_income_ratio_preliminary = requested_payment_to_income_ratio
- approved_expected_loss_amount_preliminary = requested_expected_loss_amount
- counteroffer_feasibility_evaluated_flag = FALSE
- counteroffer_feasibility_pass_flag IS NULL

4. DECLINE preliminary route consistency
For preliminary_decision_outcome = DECLINE:
- approved_amount_preliminary = 0
- counteroffer_amount_preliminary IS NULL
- approved_monthly_payment_proxy_preliminary = 0
- approved_payment_to_income_ratio_preliminary = 0
- approved_expected_loss_amount_preliminary = 0
- counteroffer_feasibility_evaluated_flag = FALSE
- counteroffer_feasibility_pass_flag IS NULL

5. MANUAL_REVIEW preliminary route consistency
For preliminary_decision_outcome = MANUAL_REVIEW:
- approved_amount_preliminary IS NULL
- counteroffer_amount_preliminary IS NULL
- approved_monthly_payment_proxy_preliminary IS NULL
- approved_payment_to_income_ratio_preliminary IS NULL
- approved_expected_loss_amount_preliminary IS NULL
- counteroffer_feasibility_evaluated_flag = FALSE
- counteroffer_feasibility_pass_flag IS NULL

6. COUNTEROFFER preliminary route consistency
For preliminary_decision_outcome = COUNTEROFFER:
- counteroffer_feasibility_evaluated_flag = TRUE
- counteroffer_feasibility_pass_flag IS NOT NULL

For preliminary COUNTEROFFER with counteroffer_feasibility_pass_flag = TRUE:
- approved_amount_preliminary IS NOT NULL
- counteroffer_amount_preliminary = approved_amount_preliminary
- approved_amount_preliminary > 0
- approved_amount_preliminary < requested_amount
- exposure_reduction_flag_preliminary = TRUE
- exposure_reduction_amount_preliminary > 0
- exposure_reduction_pct_preliminary > 0
- approved_amount_preliminary >= product_min_approved_amount
- approved_amount_preliminary <= product_max_approved_amount
- approved_payment_to_income_ratio_preliminary <= counteroffer_target_pti
- approved_expected_loss_amount_preliminary <= product_approved_el_cap
- counteroffer_feasibility_failure_reason IS NULL

For preliminary COUNTEROFFER with counteroffer_feasibility_pass_flag = FALSE:
- approved_amount_preliminary IS NULL
- counteroffer_amount_preliminary IS NULL
- approved_monthly_payment_proxy_preliminary IS NULL
- approved_payment_to_income_ratio_preliminary IS NULL
- approved_expected_loss_amount_preliminary IS NULL
- counteroffer_feasibility_failure_reason IS NOT NULL

7. No final outcome fields yet
Validate or explicitly confirm:
- no final decision_outcome column exists yet
- no final decision_path column exists yet
- no final approval_flag / decline_flag / manual_review_flag / counteroffer_flag exists yet
- no simulated_offer_exposure_flag exists yet
- no reason-code columns exist yet
- no final latest-run table exists yet
- no archive insert logic exists yet

These are Section 8 local staging gatekeepers only, not full Module 2 QA.

================================================================================
19. SECTION 8 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight staging diagnostics.

Suggested checks:

1. Count by preliminary_decision_outcome × exposure_treatment_status
2. Count by exposure_treatment_path
3. Count by counteroffer_feasibility_evaluated_flag
4. Count by counteroffer_feasibility_pass_flag
5. Count by counteroffer_feasibility_failure_reason
6. Product × counteroffer_feasibility_pass_flag
7. Score band × counteroffer_feasibility_pass_flag
8. Requested PTI bucket × counteroffer_feasibility_pass_flag
9. Strategy risk tier × counteroffer_feasibility_pass_flag
10. Average requested_amount vs approved_amount_preliminary by exposure_treatment_status
11. Average requested_payment_to_income_ratio vs approved_payment_to_income_ratio_preliminary by exposure_treatment_status
12. Average requested_expected_loss_amount vs approved_expected_loss_amount_preliminary by exposure_treatment_status
13. Average exposure_reduction_pct_preliminary by product for feasible counteroffers
14. Count of counteroffer failures by product and failure reason
15. Average counteroffer_feasibility_constraint_count for failed counteroffers

These are staging diagnostics only.
They should not be interpreted as final strategy validation.

================================================================================
20. SECTION 8 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 8 comments should explain:

- why approved exposure treatment is separated from preliminary routing
- why preliminary COUNTEROFFER requires feasibility testing
- why preliminary COUNTEROFFER does not guarantee a viable counteroffer
- why approved amount is still preliminary
- why approved payment and approved PTI are strategy-simulation proxies
- why approved Expected Loss is based on approved exposure
- why estimated_pd remains the synthetic estimated-PD proxy input and is not recalculated
- why failed counteroffers are not resolved into final outcomes yet
- why manual review remains unresolved
- why decline rows receive zero preliminary exposure convention but are still not final outcomes yet
- why reason codes are not assigned yet
- why final decision_outcome is not created yet

No silent assumptions.
No unexplained magic numbers.
No production-decision language.
No booked-account language.

================================================================================
21. SECTION 8 DELIVERABLE
================================================================================

Please now provide:

1. Any targeted Section 6 / Section 7 patch required by the pre-flight review, if any.
2. Section 8 SQL only:
   APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY LAYER.
3. A short explanation of what Section 8 establishes.
4. A short explanation of what Section 8 intentionally does not build.
5. The recommended next build step after Section 8.

Do not write Section 9+ yet.
<!-- END_MESSAGE C038-M00117 -->


---

<a id="c038-m00125"></a>

### C038-M00125

**ChatGPT** · 2026-05-06T13:25:45.666663-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00125 -->
Sections 6 and 7 pre-flight review passed; no patch required.

The Section 6 hardening patch includes `synthetic_risk_band_flag_count` and `dti_band_flag_count`, validates both with declared PL/pgSQL variables, and limits mutual-exclusivity enforcement to true banding families only. Section 7 includes the required preliminary routing fields and does not create final decision, reason-code, approved exposure, approved payment, approved PTI, or approved Expected Loss fields.

The Section 8 build below preserves the Module 1 boundary: `estimated_pd` remains the finalized Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy, while `expected_loss_amount` / `requested_expected_loss_amount` remains requested-exposure Expected Loss until Section 8 introduces preliminary approved-exposure economics. This remains a synthetic strategy-simulation layer, not production underwriting, calibrated PD modeling, pricing, or account booking. fileciteturn4file0 Module 1’s validation also confirms the deterministic, scenario-comparable foundation that Module 2 continues to preserve. fileciteturn4file1

```sql
/***************************************************************************************************
SECTION 8 — APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Evaluate preliminary approved-exposure economics for synthetic applicants after Section 7 has
    assigned a preliminary route.

    Section 8 answers:

        "Given the preliminary route, what approved exposure treatment would be economically and
         structurally feasible?"

    Section 8 does NOT answer:

        "What is the final simulated strategy outcome?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_4_preliminary_decision_routing.
    2. Preserve all prior source, lineage, strategy metadata, segmentation, threshold, trigger, and
       preliminary routing fields.
    3. Calculate preliminary exposure-treatment fields.
    4. Evaluate whether a preliminary COUNTEROFFER route has a feasible reduced-exposure treatment.
    5. Calculate preliminary approved payment, approved PTI, and approved Expected Loss only where
       the preliminary route supports exposure treatment.
    6. Validate exposure-treatment consistency without creating final decision outcomes or reason
       codes.

WHY APPROVED EXPOSURE TREATMENT IS SEPARATED FROM PRELIMINARY ROUTING:
    Section 7 identifies the route a synthetic applicant should follow based on rule triggers.
    Section 8 evaluates whether the exposure treatment implied by that route can be calculated
    coherently.

    This separation matters most for preliminary COUNTEROFFER rows.

    A preliminary COUNTEROFFER route means:
        "This row should be tested for reduced-exposure feasibility."

    It does not mean:
        "A viable counteroffer has already been created."

COUNTEROFFER FEASIBILITY BOUNDARY:
    A preliminary COUNTEROFFER is feasible only if a reduced amount can satisfy all configured
    structural constraints:

        product maximum approved amount
        product minimum approved amount
        minimum viable counteroffer percentage
        maximum exposure-reduction rule
        approved PTI target
        approved Expected Loss cap

    Section 8 calculates these feasibility checks but does not assign final decision_outcome.

APPROVED AMOUNT BOUNDARY:
    approved_amount_preliminary is a preliminary strategy-simulation exposure field.

    It is not:
        a booked account balance
        a production credit limit
        a real customer offer
        a final underwriting decision

APPROVED PAYMENT AND APPROVED PTI BOUNDARY:
    approved_monthly_payment_proxy_preliminary is calculated using proportional scaling:

        requested_monthly_payment_proxy
        * approved_amount_preliminary
        / requested_amount

    This is a strategy-simulation proxy, not a recalculated contractual payment schedule.

    approved_payment_to_income_ratio_preliminary is the post-exposure-treatment affordability proxy:

        approved_monthly_payment_proxy_preliminary / monthly income

    It is distinct from requested_payment_to_income_ratio, which comes from the original Module 1
    requested structure.

APPROVED EXPECTED LOSS BOUNDARY:
    approved_expected_loss_amount_preliminary is calculated from preliminary approved exposure:

        approved_amount_preliminary * estimated_pd * estimated_lgd

    estimated_pd remains the finalized Module 1 SQL field name and is interpreted only as the
    synthetic estimated-PD proxy.

    Module 2 does not recalculate estimated_pd.

REQUESTED VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount:
        Module 2 alias for Module 1 expected_loss_amount.
        This is requested-exposure Expected Loss.

    approved_expected_loss_amount_preliminary:
        Section 8 preliminary approved-exposure Expected Loss.

    This distinction is essential because requested exposure and preliminary approved exposure may
    differ after exposure treatment.

MANUAL REVIEW BOUNDARY:
    Manual review remains unresolved by design.

    For preliminary MANUAL_REVIEW rows, Section 8 does not calculate approved amount, approved
    payment, approved PTI, or approved Expected Loss.

DECLINE BOUNDARY:
    Preliminary DECLINE rows receive the locked zero-exposure convention for preliminary exposure
    treatment, but final DECLINE is not assigned in Section 8.

REASON-CODE BOUNDARY:
    Section 8 creates no reason codes.

    Failed counteroffer feasibility receives counteroffer_feasibility_failure_reason, which is a
    feasibility diagnostic. It is not a final primary reason code, secondary reason code, tertiary
    reason code, or regulatory adverse-action reason.

FINAL OUTCOME BOUNDARY:
    Section 8 creates no final decision_outcome, final decision_path, final flags, latest-run output
    table, or archive insert logic.

***************************************************************************************************/



/***************************************************************************************************
SECTION 8.1 — CLEAN RESET OF SECTION 8 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_5_exposure_treatment;



/***************************************************************************************************
SECTION 8.2 — CREATE APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_5_exposure_treatment

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_4_preliminary_decision_routing

OUTPUT:
    All Section 7 fields plus:
        exposure_treatment_status
        exposure_treatment_path
        approved_amount_preliminary
        counteroffer_amount_preliminary
        exposure_reduction_flag_preliminary
        exposure_reduction_amount_preliminary
        exposure_reduction_pct_preliminary
        approved_monthly_payment_proxy_preliminary
        approved_payment_to_income_ratio_preliminary
        approved_expected_loss_amount_preliminary
        approved_el_reduction_amount_preliminary
        approved_el_reduction_pct_preliminary
        counteroffer_feasibility_evaluated_flag
        counteroffer_feasibility_pass_flag
        counteroffer_feasibility_failure_reason
        counteroffer_feasibility_constraint_count
        counteroffer_product_cap_amount
        counteroffer_pti_target_amount
        counteroffer_el_cap_amount
        counteroffer_raw_max_feasible_amount
        counteroffer_min_viable_amount
        counteroffer_rounded_amount

IMPORTANT:
    This table does not contain final decision_outcome.
    This table does not contain final decision_path.
    This table does not contain final approval / decline / manual review / counteroffer flags.
    This table does not contain simulated_offer_exposure_flag.
    This table does not contain final reason codes.

IMPLEMENTATION NOTE:
    PostgreSQL does not allow a SELECT-list alias to be safely reused in another expression from
    the same SELECT list. Section 8 therefore uses staged CTEs so each calculation layer can be
    audited independently and reused safely downstream.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_5_exposure_treatment
ON COMMIT PRESERVE ROWS
AS
WITH exposure_inputs AS (
    SELECT
        r.*
    FROM tmp_m2_stage_4_preliminary_decision_routing r
),

/*-----------------------------------------------------------------------------------------------
Counteroffer component calculation.

These components are calculated only for preliminary COUNTEROFFER rows. For all other preliminary
routes, counteroffer calculation diagnostics are intentionally NULL.

counteroffer_product_cap_amount:
    LEAST(requested_amount, product_max_approved_amount)

counteroffer_pti_target_amount:
    requested_amount * counteroffer_target_pti / requested_payment_to_income_ratio

    If requested_payment_to_income_ratio is zero, requested_amount is used because there is no
    requested PTI pressure to scale down from.

counteroffer_el_cap_amount:
    product_approved_el_cap / NULLIF(estimated_pd * estimated_lgd, 0)

    This introduces approved-exposure Expected Loss logic. It is appropriate here because Section 8
    is the first exposure-treatment layer.

counteroffer_min_viable_amount:
    GREATEST(
        product_min_approved_amount,
        requested_amount * product_min_counteroffer_pct,
        requested_amount * (1 - product_max_exposure_reduction_pct)
    )

    This prevents trivial reduced-exposure outputs and enforces the maximum reduction framework.
-----------------------------------------------------------------------------------------------*/
counteroffer_components AS (
    SELECT
        ei.application_id,

        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN LEAST(ei.requested_amount, ei.product_max_approved_amount)
            ELSE NULL
        END AS counteroffer_product_cap_amount,

        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ei.requested_payment_to_income_ratio > 0
                THEN ei.requested_amount
                     * ei.counteroffer_target_pti
                     / ei.requested_payment_to_income_ratio

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND ei.requested_payment_to_income_ratio = 0
                THEN ei.requested_amount

            ELSE NULL
        END AS counteroffer_pti_target_amount,

        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN ei.product_approved_el_cap / NULLIF((ei.estimated_pd * ei.estimated_lgd), 0)
            ELSE NULL
        END AS counteroffer_el_cap_amount,

        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN GREATEST(
                    ei.product_min_approved_amount,
                    ei.requested_amount * ei.product_min_counteroffer_pct,
                    ei.requested_amount * (1.0 - ei.product_max_exposure_reduction_pct)
                )
            ELSE NULL
        END AS counteroffer_min_viable_amount

    FROM exposure_inputs ei
),

/*-----------------------------------------------------------------------------------------------
Raw maximum feasible counteroffer amount.

The raw maximum feasible amount is the most conservative of:
    requested amount
    product cap amount
    PTI target amount
    approved Expected Loss cap amount

A NULL component produces a NULL raw feasible amount because silent fallback would hide an
unresolved feasibility constraint.
-----------------------------------------------------------------------------------------------*/
counteroffer_raw_feasible AS (
    SELECT
        cc.application_id,
        cc.counteroffer_product_cap_amount,
        cc.counteroffer_pti_target_amount,
        cc.counteroffer_el_cap_amount,
        cc.counteroffer_min_viable_amount,

        CASE
            WHEN cc.counteroffer_product_cap_amount IS NULL
              OR cc.counteroffer_pti_target_amount IS NULL
              OR cc.counteroffer_el_cap_amount IS NULL
                THEN NULL
            ELSE LEAST(
                ei.requested_amount,
                cc.counteroffer_product_cap_amount,
                cc.counteroffer_pti_target_amount,
                cc.counteroffer_el_cap_amount
            )
        END AS counteroffer_raw_max_feasible_amount

    FROM counteroffer_components cc
    JOIN exposure_inputs ei
        ON ei.application_id = cc.application_id
),

/*-----------------------------------------------------------------------------------------------
Counteroffer rounding.

Rounding convention:
    FLOOR(raw amount / rounding increment) * rounding increment

Reason:
    Rounding down ensures the preliminary approved exposure does not accidentally exceed product cap,
    PTI target, or approved Expected Loss cap.

If rounding down causes the amount to fall below the minimum viable amount, the counteroffer fails
feasibility rather than being silently increased above a constraint.
-----------------------------------------------------------------------------------------------*/
counteroffer_rounding AS (
    SELECT
        crf.application_id,
        crf.counteroffer_product_cap_amount,
        crf.counteroffer_pti_target_amount,
        crf.counteroffer_el_cap_amount,
        crf.counteroffer_raw_max_feasible_amount,
        crf.counteroffer_min_viable_amount,

        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND crf.counteroffer_raw_max_feasible_amount IS NOT NULL
             AND ei.approved_amount_rounding_increment > 0
                THEN FLOOR(
                    crf.counteroffer_raw_max_feasible_amount
                    / ei.approved_amount_rounding_increment
                ) * ei.approved_amount_rounding_increment

            ELSE NULL
        END AS counteroffer_rounded_amount

    FROM counteroffer_raw_feasible crf
    JOIN exposure_inputs ei
        ON ei.application_id = crf.application_id
),

/*-----------------------------------------------------------------------------------------------
Exposure amount assignment for evaluation.

This CTE creates candidate exposure amounts used to calculate preliminary affordability and
preliminary economics.

Final output fields are assigned later after counteroffer feasibility is evaluated.

Candidate conventions:
    APPROVE:
        requested amount

    DECLINE:
        zero exposure

    MANUAL_REVIEW:
        NULL because manual review is unresolved

    COUNTEROFFER:
        rounded counteroffer amount for feasibility testing
-----------------------------------------------------------------------------------------------*/
exposure_amount_assignment AS (
    SELECT
        ei.application_id,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_amount

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
                THEN cr.counteroffer_rounded_amount

            ELSE NULL::NUMERIC
        END AS approved_amount_candidate_for_evaluation

    FROM exposure_inputs ei
    LEFT JOIN counteroffer_rounding cr
        ON cr.application_id = ei.application_id
),

/*-----------------------------------------------------------------------------------------------
Approved affordability proxy calculation for evaluation.

The proportional payment formula is a strategy-simulation proxy:

    requested_monthly_payment_proxy
    * approved_amount_candidate_for_evaluation
    / requested_amount

This is not a recalculated contractual payment schedule.
-----------------------------------------------------------------------------------------------*/
approved_affordability AS (
    SELECT
        eaa.application_id,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_monthly_payment_proxy

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND eaa.approved_amount_candidate_for_evaluation IS NOT NULL
                THEN ei.requested_monthly_payment_proxy
                     * eaa.approved_amount_candidate_for_evaluation
                     / NULLIF(ei.requested_amount, 0)

            ELSE NULL::NUMERIC
        END AS approved_monthly_payment_proxy_candidate,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_payment_to_income_ratio

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND eaa.approved_amount_candidate_for_evaluation IS NOT NULL
                THEN (
                    ei.requested_monthly_payment_proxy
                    * eaa.approved_amount_candidate_for_evaluation
                    / NULLIF(ei.requested_amount, 0)
                ) / NULLIF((ei.annual_income / 12.0), 0)

            ELSE NULL::NUMERIC
        END AS approved_payment_to_income_ratio_candidate

    FROM exposure_amount_assignment eaa
    JOIN exposure_inputs ei
        ON ei.application_id = eaa.application_id
),

/*-----------------------------------------------------------------------------------------------
Approved economics calculation for evaluation.

approved_expected_loss_amount_candidate:
    approved exposure candidate * synthetic estimated-PD proxy * LGD

estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy.
It is not recalculated in Module 2.
-----------------------------------------------------------------------------------------------*/
approved_economics AS (
    SELECT
        eaa.application_id,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_expected_loss_amount

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND eaa.approved_amount_candidate_for_evaluation IS NOT NULL
                THEN eaa.approved_amount_candidate_for_evaluation
                     * ei.estimated_pd
                     * ei.estimated_lgd

            ELSE NULL::NUMERIC
        END AS approved_expected_loss_amount_candidate

    FROM exposure_amount_assignment eaa
    JOIN exposure_inputs ei
        ON ei.application_id = eaa.application_id
),

/*-----------------------------------------------------------------------------------------------
Counteroffer feasibility base.

This CTE calculates:
    counteroffer_feasibility_evaluated_flag
    counteroffer_feasibility_pass_flag
    counteroffer_feasibility_constraint_count

For non-counteroffer preliminary routes:
    evaluated flag = FALSE
    pass flag = NULL
    constraint count = NULL

The pass flag is deliberately strict. All configured constraints must be satisfied.
-----------------------------------------------------------------------------------------------*/
counteroffer_feasibility_base AS (
    SELECT
        ei.application_id,

        (ei.preliminary_decision_outcome = 'COUNTEROFFER')
            AS counteroffer_feasibility_evaluated_flag,

        CASE
            WHEN ei.preliminary_decision_outcome <> 'COUNTEROFFER'
                THEN NULL::BOOLEAN

            WHEN ei.counteroffer_allowed_flag IS TRUE
             AND cr.counteroffer_rounded_amount IS NOT NULL
             AND cr.counteroffer_rounded_amount > 0
             AND cr.counteroffer_rounded_amount < ei.requested_amount
             AND cr.counteroffer_rounded_amount >= ei.product_min_approved_amount
             AND cr.counteroffer_rounded_amount >= ei.requested_amount * ei.product_min_counteroffer_pct
             AND cr.counteroffer_rounded_amount >= ei.requested_amount * (1.0 - ei.product_max_exposure_reduction_pct)
             AND cr.counteroffer_rounded_amount <= ei.product_max_approved_amount
             AND aa.approved_payment_to_income_ratio_candidate IS NOT NULL
             AND aa.approved_payment_to_income_ratio_candidate <= ei.counteroffer_target_pti
             AND ae.approved_expected_loss_amount_candidate IS NOT NULL
             AND ae.approved_expected_loss_amount_candidate <= ei.product_approved_el_cap
                THEN TRUE

            ELSE FALSE
        END AS counteroffer_feasibility_pass_flag,

        CASE
            WHEN ei.preliminary_decision_outcome <> 'COUNTEROFFER'
                THEN NULL::INTEGER

            ELSE
                (
                    CASE WHEN ei.counteroffer_allowed_flag IS DISTINCT FROM TRUE THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NULL THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NOT NULL
                             AND cr.counteroffer_rounded_amount <= 0 THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NOT NULL
                             AND cr.counteroffer_rounded_amount >= ei.requested_amount THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NOT NULL
                             AND cr.counteroffer_rounded_amount < ei.product_min_approved_amount THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NOT NULL
                             AND cr.counteroffer_rounded_amount < ei.requested_amount * ei.product_min_counteroffer_pct THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NOT NULL
                             AND cr.counteroffer_rounded_amount < ei.requested_amount * (1.0 - ei.product_max_exposure_reduction_pct) THEN 1 ELSE 0 END
                    + CASE WHEN cr.counteroffer_rounded_amount IS NOT NULL
                             AND cr.counteroffer_rounded_amount > ei.product_max_approved_amount THEN 1 ELSE 0 END
                    + CASE WHEN aa.approved_payment_to_income_ratio_candidate IS NOT NULL
                             AND aa.approved_payment_to_income_ratio_candidate > ei.counteroffer_target_pti THEN 1 ELSE 0 END
                    + CASE WHEN ae.approved_expected_loss_amount_candidate IS NOT NULL
                             AND ae.approved_expected_loss_amount_candidate > ei.product_approved_el_cap THEN 1 ELSE 0 END
                )
        END AS counteroffer_feasibility_constraint_count

    FROM exposure_inputs ei
    LEFT JOIN counteroffer_rounding cr
        ON cr.application_id = ei.application_id
    LEFT JOIN approved_affordability aa
        ON aa.application_id = ei.application_id
    LEFT JOIN approved_economics ae
        ON ae.application_id = ei.application_id
),

/*-----------------------------------------------------------------------------------------------
Counteroffer feasibility failure reason.

This field is a feasibility diagnostic only.

It is not:
    primary_reason_code
    secondary_reason_code
    tertiary_reason_code
    regulatory adverse-action reason
    final policy reason

The priority order is deterministic so failed preliminary counteroffer routes are explainable.
-----------------------------------------------------------------------------------------------*/
counteroffer_feasibility AS (
    SELECT
        cfb.application_id,
        cfb.counteroffer_feasibility_evaluated_flag,
        cfb.counteroffer_feasibility_pass_flag,
        cfb.counteroffer_feasibility_constraint_count,

        CASE
            WHEN ei.preliminary_decision_outcome <> 'COUNTEROFFER'
                THEN NULL

            WHEN cfb.counteroffer_feasibility_pass_flag IS TRUE
                THEN NULL

            WHEN ei.counteroffer_allowed_flag IS DISTINCT FROM TRUE
                THEN 'COUNTEROFFER_NOT_ALLOWED_BY_PRODUCT'

            WHEN cr.counteroffer_raw_max_feasible_amount IS NULL
                THEN 'COUNTEROFFER_RAW_AMOUNT_NULL'

            WHEN cr.counteroffer_rounded_amount IS NULL
                THEN 'COUNTEROFFER_ROUNDED_AMOUNT_NULL'

            WHEN cr.counteroffer_rounded_amount <= 0
                THEN 'COUNTEROFFER_ROUNDED_AMOUNT_NON_POSITIVE'

            WHEN cr.counteroffer_rounded_amount >= ei.requested_amount
                THEN 'COUNTEROFFER_NOT_BELOW_REQUESTED_AMOUNT'

            WHEN cr.counteroffer_rounded_amount < ei.product_min_approved_amount
                THEN 'COUNTEROFFER_BELOW_PRODUCT_MINIMUM'

            WHEN cr.counteroffer_rounded_amount < ei.requested_amount * ei.product_min_counteroffer_pct
                THEN 'COUNTEROFFER_BELOW_MINIMUM_REQUESTED_PERCENT'

            WHEN cr.counteroffer_rounded_amount < ei.requested_amount * (1.0 - ei.product_max_exposure_reduction_pct)
                THEN 'COUNTEROFFER_EXCEEDS_MAX_REDUCTION'

            WHEN cr.counteroffer_rounded_amount > ei.product_max_approved_amount
                THEN 'COUNTEROFFER_EXCEEDS_PRODUCT_CAP'

            WHEN aa.approved_payment_to_income_ratio_candidate > ei.counteroffer_target_pti
                THEN 'COUNTEROFFER_PTI_STILL_ABOVE_TARGET'

            WHEN ae.approved_expected_loss_amount_candidate > ei.product_approved_el_cap
                THEN 'COUNTEROFFER_APPROVED_EL_ABOVE_CAP'

            ELSE 'COUNTEROFFER_FEASIBILITY_UNKNOWN'
        END AS counteroffer_feasibility_failure_reason

    FROM counteroffer_feasibility_base cfb
    JOIN exposure_inputs ei
        ON ei.application_id = cfb.application_id
    LEFT JOIN counteroffer_rounding cr
        ON cr.application_id = cfb.application_id
    LEFT JOIN approved_affordability aa
        ON aa.application_id = cfb.application_id
    LEFT JOIN approved_economics ae
        ON ae.application_id = cfb.application_id
),

/*-----------------------------------------------------------------------------------------------
Final Section 8 exposure-treatment fields.

These are still preliminary fields.

Final decision_outcome and final reason codes are not created here.
-----------------------------------------------------------------------------------------------*/
final_exposure_treatment AS (
    SELECT
        ei.*,

        /* Counteroffer calculation diagnostics */
        cr.counteroffer_product_cap_amount,
        cr.counteroffer_pti_target_amount,
        cr.counteroffer_el_cap_amount,
        cr.counteroffer_raw_max_feasible_amount,
        cr.counteroffer_min_viable_amount,
        cr.counteroffer_rounded_amount,

        /* Counteroffer feasibility diagnostics */
        cf.counteroffer_feasibility_evaluated_flag,
        cf.counteroffer_feasibility_pass_flag,
        cf.counteroffer_feasibility_failure_reason,
        cf.counteroffer_feasibility_constraint_count,

        /* Exposure treatment status */
        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVED_AS_REQUESTED_PRELIMINARY'

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 'NO_OFFER_PRELIMINARY_DECLINE'

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'UNRESOLVED_MANUAL_REVIEW'

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBLE_PRELIMINARY'

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS FALSE
                THEN 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'

            ELSE 'EXPOSURE_TREATMENT_UNKNOWN'
        END AS exposure_treatment_status,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN 'APPROVE_AS_REQUESTED'

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 'NO_OFFER'

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN 'MANUAL_REVIEW_UNRESOLVED'

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN 'COUNTEROFFER_FEASIBLE'

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS FALSE
                THEN 'COUNTEROFFER_NOT_FEASIBLE'

            ELSE 'EXPOSURE_TREATMENT_UNKNOWN'
        END AS exposure_treatment_path,


        /* Preliminary approved amount and counteroffer amount */
        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_amount

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN cr.counteroffer_rounded_amount

            ELSE NULL::NUMERIC
        END AS approved_amount_preliminary,

        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN cr.counteroffer_rounded_amount
            ELSE NULL::NUMERIC
        END AS counteroffer_amount_preliminary,


        /* Preliminary exposure reduction fields */
        CASE
            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN TRUE
            ELSE FALSE
        END AS exposure_reduction_flag_preliminary,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN ei.requested_amount

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN ei.requested_amount - cr.counteroffer_rounded_amount

            ELSE NULL::NUMERIC
        END AS exposure_reduction_amount_preliminary,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 1.0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN (ei.requested_amount - cr.counteroffer_rounded_amount)
                     / NULLIF(ei.requested_amount, 0)

            ELSE NULL::NUMERIC
        END AS exposure_reduction_pct_preliminary,


        /* Preliminary approved payment and PTI */
        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_monthly_payment_proxy

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN aa.approved_monthly_payment_proxy_candidate

            ELSE NULL::NUMERIC
        END AS approved_monthly_payment_proxy_preliminary,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_payment_to_income_ratio

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN aa.approved_payment_to_income_ratio_candidate

            ELSE NULL::NUMERIC
        END AS approved_payment_to_income_ratio_preliminary,


        /* Preliminary approved Expected Loss and EL reduction */
        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN ei.requested_expected_loss_amount

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN ae.approved_expected_loss_amount_candidate

            ELSE NULL::NUMERIC
        END AS approved_expected_loss_amount_preliminary,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN ei.requested_expected_loss_amount

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN ei.requested_expected_loss_amount
                     - ae.approved_expected_loss_amount_candidate

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_amount_preliminary,

        CASE
            WHEN ei.preliminary_decision_outcome = 'APPROVE'
                THEN 0::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'DECLINE'
                THEN CASE
                    WHEN ei.requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                    ELSE 0::NUMERIC
                END

            WHEN ei.preliminary_decision_outcome = 'MANUAL_REVIEW'
                THEN NULL::NUMERIC

            WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
             AND cf.counteroffer_feasibility_pass_flag IS TRUE
                THEN (
                    ei.requested_expected_loss_amount
                    - ae.approved_expected_loss_amount_candidate
                ) / NULLIF(ei.requested_expected_loss_amount, 0)

            ELSE NULL::NUMERIC
        END AS approved_el_reduction_pct_preliminary

    FROM exposure_inputs ei
    LEFT JOIN counteroffer_rounding cr
        ON cr.application_id = ei.application_id
    LEFT JOIN approved_affordability aa
        ON aa.application_id = ei.application_id
    LEFT JOIN approved_economics ae
        ON ae.application_id = ei.application_id
    LEFT JOIN counteroffer_feasibility cf
        ON cf.application_id = ei.application_id
)

SELECT *
FROM final_exposure_treatment;



/***************************************************************************************************
SECTION 8.3 — LOCAL FAIL-FAST CHECKS FOR EXPOSURE TREATMENT STAGE
****************************************************************************************************

PURPOSE:
    Validate the Section 8 exposure-treatment layer before final decision outcome, reason-code,
    latest-run output, or archive logic is built.

IMPORTANT:
    These are local staging gatekeepers only.

    They are not full Module 2 QA.
    They are not final decision validation.
    They are not reason-code validation.
    They are not archive validation.

***************************************************************************************************/

DO $$
DECLARE
    v_stage4_count BIGINT;
    v_stage5_count BIGINT;
    v_stage5_distinct_app_count BIGINT;

    v_duplicate_application_count BIGINT;
    v_required_field_failure_count BIGINT;

    v_approve_route_failure_count BIGINT;
    v_decline_route_failure_count BIGINT;
    v_manual_review_route_failure_count BIGINT;
    v_counteroffer_eval_failure_count BIGINT;
    v_counteroffer_pass_failure_count BIGINT;
    v_counteroffer_fail_failure_count BIGINT;

    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 7 to Section 8.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage4_count
    FROM tmp_m2_stage_4_preliminary_decision_routing;

    SELECT COUNT(*)
    INTO v_stage5_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_count <> v_stage4_count THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: row count changed from Section 7 to Section 8. Stage 4 rows: %, Stage 5 rows: %.',
            v_stage4_count,
            v_stage5_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage5_distinct_app_count
    FROM tmp_m2_stage_5_exposure_treatment;

    IF v_stage5_distinct_app_count <> v_stage5_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_5_exposure_treatment
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 8 failure: application_id uniqueness was not preserved. Stage 5 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage5_count,
            v_stage5_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required exposure-treatment fields must be populated.

    Manual review and failed counteroffer rows may intentionally have NULL exposure economics, but
    route-status fields and feasibility evaluation indicators must still be complete.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_required_field_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE exposure_treatment_status IS NULL
       OR exposure_treatment_path IS NULL
       OR counteroffer_feasibility_evaluated_flag IS NULL;

    IF v_required_field_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % row(s) have null required exposure-treatment status fields.',
            v_required_field_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: APPROVE preliminary route consistency.

    Preliminary APPROVE rows are approved as requested for exposure-treatment purposes, but final
    APPROVE is still not assigned in Section 8.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_approve_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'APPROVE'
      AND (
            approved_amount_preliminary IS DISTINCT FROM requested_amount
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR exposure_reduction_pct_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_monthly_payment_proxy_preliminary IS DISTINCT FROM requested_monthly_payment_proxy
         OR approved_payment_to_income_ratio_preliminary IS DISTINCT FROM requested_payment_to_income_ratio
         OR approved_expected_loss_amount_preliminary IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_pct_preliminary IS DISTINCT FROM 0::NUMERIC
         OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM FALSE
         OR counteroffer_feasibility_pass_flag IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR counteroffer_feasibility_constraint_count IS NOT NULL
         OR exposure_treatment_status <> 'APPROVED_AS_REQUESTED_PRELIMINARY'
         OR exposure_treatment_path <> 'APPROVE_AS_REQUESTED'
      );

    IF v_approve_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary APPROVE row(s) violate exposure-treatment conventions.',
            v_approve_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DECLINE preliminary route consistency.

    Preliminary DECLINE rows use the locked zero-exposure convention, but final DECLINE is still
    not assigned in Section 8.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_decline_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'DECLINE'
      AND (
            approved_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS DISTINCT FROM requested_amount
         OR exposure_reduction_pct_preliminary IS DISTINCT FROM 1.0::NUMERIC
         OR approved_monthly_payment_proxy_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_payment_to_income_ratio_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_expected_loss_amount_preliminary IS DISTINCT FROM 0::NUMERIC
         OR approved_el_reduction_amount_preliminary IS DISTINCT FROM requested_expected_loss_amount
         OR approved_el_reduction_pct_preliminary IS DISTINCT FROM CASE
                WHEN requested_expected_loss_amount > 0 THEN 1.0::NUMERIC
                ELSE 0::NUMERIC
            END
         OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM FALSE
         OR counteroffer_feasibility_pass_flag IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR counteroffer_feasibility_constraint_count IS NOT NULL
         OR exposure_treatment_status <> 'NO_OFFER_PRELIMINARY_DECLINE'
         OR exposure_treatment_path <> 'NO_OFFER'
      );

    IF v_decline_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary DECLINE row(s) violate zero-exposure conventions.',
            v_decline_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: MANUAL_REVIEW preliminary route consistency.

    Manual review remains unresolved by design. It should not receive preliminary approved exposure
    economics.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_route_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'MANUAL_REVIEW'
      AND (
            approved_amount_preliminary IS NOT NULL
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS NOT NULL
         OR exposure_reduction_pct_preliminary IS NOT NULL
         OR approved_monthly_payment_proxy_preliminary IS NOT NULL
         OR approved_payment_to_income_ratio_preliminary IS NOT NULL
         OR approved_expected_loss_amount_preliminary IS NOT NULL
         OR approved_el_reduction_amount_preliminary IS NOT NULL
         OR approved_el_reduction_pct_preliminary IS NOT NULL
         OR counteroffer_feasibility_evaluated_flag IS DISTINCT FROM FALSE
         OR counteroffer_feasibility_pass_flag IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR counteroffer_feasibility_constraint_count IS NOT NULL
         OR exposure_treatment_status <> 'UNRESOLVED_MANUAL_REVIEW'
         OR exposure_treatment_path <> 'MANUAL_REVIEW_UNRESOLVED'
      );

    IF v_manual_review_route_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary MANUAL_REVIEW row(s) violate unresolved-review conventions.',
            v_manual_review_route_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: COUNTEROFFER preliminary route must be evaluated.

    A preliminary COUNTEROFFER route is not automatically feasible. Section 8 must explicitly
    evaluate feasibility and populate pass / fail.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_eval_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND (
            counteroffer_feasibility_evaluated_flag IS DISTINCT FROM TRUE
         OR counteroffer_feasibility_pass_flag IS NULL
         OR exposure_treatment_status NOT IN (
                'COUNTEROFFER_FEASIBLE_PRELIMINARY',
                'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'
            )
         OR exposure_treatment_path NOT IN (
                'COUNTEROFFER_FEASIBLE',
                'COUNTEROFFER_NOT_FEASIBLE'
            )
      );

    IF v_counteroffer_eval_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % preliminary COUNTEROFFER row(s) were not fully evaluated for feasibility.',
            v_counteroffer_eval_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: feasible preliminary counteroffer consistency.

    A feasible preliminary counteroffer must produce a positive approved amount below the requested
    amount and must satisfy product, reduction, approved PTI, and approved Expected Loss constraints.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_pass_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS TRUE
      AND (
            approved_amount_preliminary IS NULL
         OR counteroffer_amount_preliminary IS DISTINCT FROM approved_amount_preliminary
         OR approved_amount_preliminary <= 0
         OR approved_amount_preliminary >= requested_amount
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM TRUE
         OR exposure_reduction_amount_preliminary <= 0
         OR exposure_reduction_pct_preliminary <= 0
         OR approved_amount_preliminary < product_min_approved_amount
         OR approved_amount_preliminary < requested_amount * product_min_counteroffer_pct
         OR approved_amount_preliminary < requested_amount * (1.0 - product_max_exposure_reduction_pct)
         OR approved_amount_preliminary > product_max_approved_amount
         OR approved_payment_to_income_ratio_preliminary IS NULL
         OR approved_payment_to_income_ratio_preliminary > counteroffer_target_pti
         OR approved_expected_loss_amount_preliminary IS NULL
         OR approved_expected_loss_amount_preliminary > product_approved_el_cap
         OR approved_monthly_payment_proxy_preliminary IS NULL
         OR approved_el_reduction_amount_preliminary IS NULL
         OR approved_el_reduction_pct_preliminary IS NULL
         OR counteroffer_feasibility_failure_reason IS NOT NULL
         OR exposure_treatment_status <> 'COUNTEROFFER_FEASIBLE_PRELIMINARY'
         OR exposure_treatment_path <> 'COUNTEROFFER_FEASIBLE'
      );

    IF v_counteroffer_pass_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % feasible preliminary COUNTEROFFER row(s) violate approved-exposure feasibility conventions.',
            v_counteroffer_pass_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: infeasible preliminary counteroffer consistency.

    Failed preliminary counteroffers remain unresolved for final handling. They should not carry
    preliminary approved exposure economics.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_fail_failure_count
    FROM tmp_m2_stage_5_exposure_treatment
    WHERE preliminary_decision_outcome = 'COUNTEROFFER'
      AND counteroffer_feasibility_pass_flag IS FALSE
      AND (
            approved_amount_preliminary IS NOT NULL
         OR counteroffer_amount_preliminary IS NOT NULL
         OR exposure_reduction_flag_preliminary IS DISTINCT FROM FALSE
         OR exposure_reduction_amount_preliminary IS NOT NULL
         OR exposure_reduction_pct_preliminary IS NOT NULL
         OR approved_monthly_payment_proxy_preliminary IS NOT NULL
         OR approved_payment_to_income_ratio_preliminary IS NOT NULL
         OR approved_expected_loss_amount_preliminary IS NOT NULL
         OR approved_el_reduction_amount_preliminary IS NOT NULL
         OR approved_el_reduction_pct_preliminary IS NOT NULL
         OR counteroffer_feasibility_failure_reason IS NULL
         OR counteroffer_feasibility_constraint_count IS NULL
         OR counteroffer_feasibility_constraint_count < 1
         OR exposure_treatment_status <> 'COUNTEROFFER_NOT_FEASIBLE_PRELIMINARY'
         OR exposure_treatment_path <> 'COUNTEROFFER_NOT_FEASIBLE'
      );

    IF v_counteroffer_fail_failure_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: % infeasible preliminary COUNTEROFFER row(s) violate failed-feasibility conventions.',
            v_counteroffer_fail_failure_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: forbidden final-output fields must not exist yet.

    Section 8 is not allowed to create final decisions, final flags, simulated offer exposure flags,
    final reason codes, latest-run output, or archive persistence.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_5_exposure_treatment'::REGCLASS
      AND attnum > 0
      AND NOT attisdropped
      AND attname IN (
            'decision_outcome',
            'decision_path',
            'approval_flag',
            'decline_flag',
            'manual_review_flag',
            'counteroffer_flag',
            'simulated_offer_exposure_flag',

            'primary_reason_code',
            'secondary_reason_code',
            'tertiary_reason_code',
            'triggered_reason_code_list',
            'reason_priority_rank',
            'primary_reason_family',

            'approved_amount',
            'counteroffer_amount',
            'approved_monthly_payment_proxy',
            'approved_payment_to_income_ratio',
            'approved_expected_loss_amount'
      );

    IF v_forbidden_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: forbidden final-output field(s) were created before final decision / reason-code sections.';
    END IF;

    IF TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 8 failure: final latest-run strategy_decisions table exists before final output section.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 8.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 8 exposure-treatment layer.

IMPORTANT:
    These are not final strategy validation queries.
    They should not be interpreted as final approval, decline, manual review, or counteroffer rates.

    They are staging diagnostics only.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
8.4.1 Preliminary route × exposure treatment status.

Interpretation:
    This is preliminary exposure-treatment routing, not final decision distribution.
-----------------------------------------------------------------------------------------------*/
SELECT
    preliminary_decision_outcome,
    exposure_treatment_status,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY
    preliminary_decision_outcome,
    exposure_treatment_status
ORDER BY
    preliminary_decision_outcome,
    exposure_treatment_status;


/*-----------------------------------------------------------------------------------------------
8.4.2 Count by exposure_treatment_path.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_treatment_path,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_path
ORDER BY exposure_treatment_path;


/*-----------------------------------------------------------------------------------------------
8.4.3 Count by counteroffer_feasibility_evaluated_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_feasibility_evaluated_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY counteroffer_feasibility_evaluated_flag
ORDER BY counteroffer_feasibility_evaluated_flag;


/*-----------------------------------------------------------------------------------------------
8.4.4 Count by counteroffer_feasibility_pass_flag.

NULL appears for non-counteroffer preliminary routes.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY counteroffer_feasibility_pass_flag
ORDER BY counteroffer_feasibility_pass_flag;


/*-----------------------------------------------------------------------------------------------
8.4.5 Count by counteroffer_feasibility_failure_reason.

Interpretation:
    This is a feasibility diagnostic for preliminary COUNTEROFFER rows only. It is not a final
    reason code.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS row_count
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY counteroffer_feasibility_failure_reason
ORDER BY counteroffer_feasibility_failure_reason;


/*-----------------------------------------------------------------------------------------------
8.4.6 Product × counteroffer feasibility pass flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount_preliminary) AS avg_approved_amount_preliminary
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag
ORDER BY
    product_type_policy_key,
    counteroffer_feasibility_pass_flag;


/*-----------------------------------------------------------------------------------------------
8.4.7 Score band × counteroffer feasibility pass flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    score_band_policy_key,
    counteroffer_feasibility_pass_flag
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    counteroffer_feasibility_pass_flag;


/*-----------------------------------------------------------------------------------------------
8.4.8 Requested PTI bucket × counteroffer feasibility pass flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio_preliminary) AS avg_approved_payment_to_income_ratio_preliminary
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    requested_pti_bucket,
    counteroffer_feasibility_pass_flag
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    counteroffer_feasibility_pass_flag;


/*-----------------------------------------------------------------------------------------------
8.4.9 Strategy risk tier × counteroffer feasibility pass flag.

estimated_pd is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    counteroffer_feasibility_pass_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY
    strategy_risk_tier,
    counteroffer_feasibility_pass_flag
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END,
    counteroffer_feasibility_pass_flag;


/*-----------------------------------------------------------------------------------------------
8.4.10 Average requested amount versus preliminary approved amount by exposure treatment status.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_treatment_status,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount_preliminary) AS avg_approved_amount_preliminary,
    AVG(exposure_reduction_amount_preliminary) AS avg_exposure_reduction_amount_preliminary,
    AVG(exposure_reduction_pct_preliminary) AS avg_exposure_reduction_pct_preliminary
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_status
ORDER BY exposure_treatment_status;


/*-----------------------------------------------------------------------------------------------
8.4.11 Average requested PTI versus preliminary approved PTI by exposure treatment status.

Interpretation:
    requested_payment_to_income_ratio is the original Module 1 requested-structure PTI.
    approved_payment_to_income_ratio_preliminary is the post-exposure-treatment affordability proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_treatment_status,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(approved_payment_to_income_ratio_preliminary) AS avg_approved_payment_to_income_ratio_preliminary
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_status
ORDER BY exposure_treatment_status;


/*-----------------------------------------------------------------------------------------------
8.4.12 Average requested Expected Loss versus preliminary approved Expected Loss by treatment status.

Interpretation:
    requested_expected_loss_amount uses requested exposure.
    approved_expected_loss_amount_preliminary uses preliminary approved exposure.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_treatment_status,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    AVG(approved_expected_loss_amount_preliminary) AS avg_approved_expected_loss_amount_preliminary,
    AVG(approved_el_reduction_amount_preliminary) AS avg_approved_el_reduction_amount_preliminary,
    AVG(approved_el_reduction_pct_preliminary) AS avg_approved_el_reduction_pct_preliminary
FROM tmp_m2_stage_5_exposure_treatment
GROUP BY exposure_treatment_status
ORDER BY exposure_treatment_status;


/*-----------------------------------------------------------------------------------------------
8.4.13 Average exposure reduction percentage by product for feasible preliminary counteroffers.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    COUNT(*) AS feasible_counteroffer_rows,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(approved_amount_preliminary) AS avg_approved_amount_preliminary,
    AVG(exposure_reduction_pct_preliminary) AS avg_exposure_reduction_pct_preliminary,
    MIN(exposure_reduction_pct_preliminary) AS min_exposure_reduction_pct_preliminary,
    MAX(exposure_reduction_pct_preliminary) AS max_exposure_reduction_pct_preliminary
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS TRUE
GROUP BY product_type_policy_key
ORDER BY product_type_policy_key;


/*-----------------------------------------------------------------------------------------------
8.4.14 Counteroffer failures by product and failure reason.

Interpretation:
    counteroffer_feasibility_failure_reason is a preliminary feasibility diagnostic only.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    counteroffer_feasibility_failure_reason,
    COUNT(*) AS failed_counteroffer_rows,
    AVG(counteroffer_feasibility_constraint_count) AS avg_counteroffer_feasibility_constraint_count
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE
GROUP BY
    product_type_policy_key,
    counteroffer_feasibility_failure_reason
ORDER BY
    product_type_policy_key,
    counteroffer_feasibility_failure_reason;


/*-----------------------------------------------------------------------------------------------
8.4.15 Average counteroffer feasibility constraint count for failed counteroffers.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS failed_counteroffer_rows,
    AVG(counteroffer_feasibility_constraint_count) AS avg_counteroffer_feasibility_constraint_count,
    MIN(counteroffer_feasibility_constraint_count) AS min_counteroffer_feasibility_constraint_count,
    MAX(counteroffer_feasibility_constraint_count) AS max_counteroffer_feasibility_constraint_count
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
  AND counteroffer_feasibility_pass_flag IS FALSE;


/*-----------------------------------------------------------------------------------------------
8.4.16 Counteroffer calculation component profile.

Purpose:
    Provides quick diagnostics on which counteroffer ceilings are binding candidates before final
    decision resolution.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    COUNT(*) AS preliminary_counteroffer_rows,
    AVG(counteroffer_product_cap_amount) AS avg_counteroffer_product_cap_amount,
    AVG(counteroffer_pti_target_amount) AS avg_counteroffer_pti_target_amount,
    AVG(counteroffer_el_cap_amount) AS avg_counteroffer_el_cap_amount,
    AVG(counteroffer_raw_max_feasible_amount) AS avg_counteroffer_raw_max_feasible_amount,
    AVG(counteroffer_min_viable_amount) AS avg_counteroffer_min_viable_amount,
    AVG(counteroffer_rounded_amount) AS avg_counteroffer_rounded_amount
FROM tmp_m2_stage_5_exposure_treatment
WHERE preliminary_decision_outcome = 'COUNTEROFFER'
GROUP BY product_type_policy_key
ORDER BY product_type_policy_key;


/***************************************************************************************************
END OF SECTION 8 — APPROVED EXPOSURE AND COUNTEROFFER FEASIBILITY LAYER

If execution reaches this point:
    1. tmp_m2_stage_5_exposure_treatment exists.
    2. All Section 7 fields have been preserved.
    3. Module 1 lineage remains attached.
    4. Module 2 strategy metadata remains attached.
    5. Preliminary routing fields remain attached.
    6. Preliminary approved exposure treatment fields have been calculated.
    7. Preliminary approved payment and approved PTI proxies have been calculated where applicable.
    8. Preliminary approved Expected Loss has been calculated where applicable.
    9. Counteroffer feasibility has been evaluated for preliminary COUNTEROFFER rows.
    10. Failed preliminary counteroffers have deterministic feasibility failure diagnostics.
    11. Manual review remains unresolved.
    12. Final decision_outcome has not been created.
    13. Final reason codes have not been assigned.
    14. Latest-run final strategy output has not been created.
    15. Strategy archive rows have not been inserted.

***************************************************************************************************/
```

## What Section 8 establishes

Section 8 creates:

```text
tmp_m2_stage_5_exposure_treatment
```

It calculates preliminary exposure-treatment economics for preliminary `APPROVE`, `DECLINE`, `MANUAL_REVIEW`, and `COUNTEROFFER` routes. It also tests whether preliminary `COUNTEROFFER` rows can produce a viable reduced-exposure amount under product cap, PTI target, approved Expected Loss cap, minimum amount, minimum percentage, and maximum reduction constraints.

## What Section 8 intentionally does not build

Section 8 does not create final `decision_outcome`, final `decision_path`, final outcome flags, `simulated_offer_exposure_flag`, simulated reason codes, final latest-run output, archive insert logic, or the full QA framework.

The approved exposure, approved payment, approved PTI, and approved Expected Loss fields are still preliminary.

## Recommended next build step

Next should be:

```text
Section 9 — Final Decision Resolution Layer
```

That section should convert preliminary routing plus Section 8 exposure feasibility into final:

```text
decision_outcome
decision_path
approval_flag
counteroffer_flag
manual_review_flag
decline_flag
simulated_offer_exposure_flag
```

Reason-code assignment should still remain separate unless you explicitly choose to combine final decision resolution and reason-code prioritization.
<!-- END_MESSAGE C038-M00125 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_03.md) · [Next](Part_05.md)
