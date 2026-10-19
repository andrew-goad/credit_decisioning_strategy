# Module 2 Decision Simulator Build

## Part 03

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_02.md) · [Next](Part_04.md)

<a id="c038-m00087"></a>

### C038-M00087

**ChatGPT** · 2026-05-06T12:03:58.479675-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00087 -->
The two Section 4 patches below are targeted only. I also include a small Section 2 / Section 3 patch for a governed `borderline_threshold_buffer_pct`, because implementing `borderline_profile_flag` without a parameterized proximity buffer would create hidden threshold logic. This preserves Module 1’s documented boundary that `estimated_pd` is a synthetic estimated-PD proxy and that downstream modules should extend the validated synthetic strategy foundation without reinterpreting Module 1 as production underwriting or calibrated default modeling. fileciteturn4file0 The approach also preserves the matched-scenario and deterministic comparison discipline validated in Module 1 V2.0. fileciteturn4file1

---

# 1. Targeted Section 4 patches

## Patch 4.A — Commentary correction

No structural issue found. This patch simply locks the wording so Section 4 never implies it sources from a Module 2 latest-run table.

### BEFORE

```sql
IMPLEMENTATION NOTE:
    This section uses dynamic SQL because Module 2 can consume either the Module 2 latest-run table
    or a selected Module 1 archive slice.
```

### AFTER

```sql
IMPLEMENTATION NOTE:
    This section uses dynamic SQL because Module 2 can consume either the Module 1 latest-run table
    or a selected Module 1 scenario archive slice.

    Section 4 is the Module 1 → Module 2 handoff layer. At this point, Module 2 is not sourcing
    from any Module 2 latest-run decision output.
```

---

## Patch 4.B — Add Module 2 strategy metadata to `tmp_m2_stage_1_source_applications`

### BEFORE

```sql
selected_source AS (
    SELECT
        src.%1$I::TEXT AS module1_model_version,
        src.%2$I::TEXT AS module1_scenario_set_name,
        src.%3$I::TEXT AS module1_scenario_name,
        src.population_id::TEXT AS population_id,
        src.anchor_date,
        %4$L::TEXT AS module1_input_source,
        %5$L::TEXT AS module1_source_table_name,
```

### AFTER

```sql
selected_source AS (
    SELECT
        /*
        Module 2 strategy metadata.

        These fields identify the downstream simulated decision strategy that will later be
        applied to this Module 1 source population.

        strategy_run_id and strategy_run_ts are audit metadata:
            - they support run traceability;
            - they should appear in latest-run and archive outputs later;
            - they do not replace the archive replacement / rerun key;
            - they are not the grain for matched strategy comparison.
        */
        p.module2_model_version::TEXT AS module2_model_version,
        p.strategy_set_name::TEXT AS strategy_set_name,
        p.strategy_name::TEXT AS strategy_name,
        p.strategy_version::TEXT AS strategy_version,
        p.strategy_run_id::TEXT AS strategy_run_id,
        p.strategy_run_ts AS strategy_run_ts,

        /*
        Module 1 lineage.

        These fields describe the upstream synthetic population and risk-environment scenario.
        They remain separate from Module 2 strategy metadata.
        */
        src.%1$I::TEXT AS module1_model_version,
        src.%2$I::TEXT AS module1_scenario_set_name,
        src.%3$I::TEXT AS module1_scenario_name,
        src.population_id::TEXT AS population_id,
        src.anchor_date,
        %4$L::TEXT AS module1_input_source,
        %5$L::TEXT AS module1_source_table_name,
```

### Additional local fail-fast patch

Add the Module 2 strategy metadata fields to the Section 4.3 null-required-field gatekeeper.

### BEFORE

```sql
WHERE module1_model_version IS NULL
   OR NULLIF(BTRIM(module1_model_version), '') IS NULL
   OR module1_scenario_set_name IS NULL
```

### AFTER

```sql
WHERE module2_model_version IS NULL
   OR NULLIF(BTRIM(module2_model_version), '') IS NULL
   OR strategy_set_name IS NULL
   OR NULLIF(BTRIM(strategy_set_name), '') IS NULL
   OR strategy_name IS NULL
   OR NULLIF(BTRIM(strategy_name), '') IS NULL
   OR strategy_version IS NULL
   OR NULLIF(BTRIM(strategy_version), '') IS NULL
   OR strategy_run_id IS NULL
   OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
   OR strategy_run_ts IS NULL

   OR module1_model_version IS NULL
   OR NULLIF(BTRIM(module1_model_version), '') IS NULL
   OR module1_scenario_set_name IS NULL
```

### Additional Section 4.4 sanity-check patch

Add this lightweight staging sanity check.

```sql
/*-----------------------------------------------------------------------------------------------
4.4.X Module 2 strategy metadata carried into source stage.

Expected:
    exactly one strategy_set_name / strategy_name / strategy_version combination.
    strategy_run_id and strategy_run_ts are audit metadata and should not be used as the matched
    comparison grain.
-----------------------------------------------------------------------------------------------*/
SELECT
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,
    COUNT(*) AS row_count
FROM tmp_m2_stage_1_source_applications
GROUP BY
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version;
```

---

# 2. Targeted Section 2 / Section 3 patch for governed borderline logic

`borderline_profile_flag` requires a governed proximity parameter. This patch adds one rather than hardcoding a hidden 5% or 10% buffer inside Section 5.

## Patch 2.A — Add parameter column to `tmp_module2_strategy_params`

### BEFORE

```sql
/* DTI thresholds */
approve_max_dti                              NUMERIC(12,6),
review_max_dti                               NUMERIC(12,6),
decline_min_dti                              NUMERIC(12,6),

/* Decision convention controls */
approve_reason_code                          TEXT,
```

### AFTER

```sql
/* DTI thresholds */
approve_max_dti                              NUMERIC(12,6),
review_max_dti                               NUMERIC(12,6),
decline_min_dti                              NUMERIC(12,6),

/* Diagnostic segmentation controls */
borderline_threshold_buffer_pct              NUMERIC(12,6),

/*
borderline_threshold_buffer_pct:
    Governs how close a value must be to a strategy threshold to be tagged as borderline.

    Example:
        0.050000 means "within 5% of the threshold value."

    This is not a production policy tolerance.
    This is a diagnostic segmentation buffer used only to identify threshold-adjacent
    synthetic profiles before decision rules are applied.
*/

/* Decision convention controls */
approve_reason_code                          TEXT,
```

## Patch 2.B — Add parameter to insert column list

### BEFORE

```sql
approve_max_dti,
review_max_dti,
decline_min_dti,

approve_reason_code,
reason_code_required_flag,
```

### AFTER

```sql
approve_max_dti,
review_max_dti,
decline_min_dti,

borderline_threshold_buffer_pct,

approve_reason_code,
reason_code_required_flag,
```

## Patch 2.C — Add default value

### BEFORE

```sql
0.430000,  -- Clean approval DTI ceiling.
0.600000,  -- Manual review DTI upper boundary.
0.600000,  -- Hard simulated DTI stop at or above this value.

/* Decision convention controls. */
'APPROVED_AS_REQUESTED',
```

### AFTER

```sql
0.430000,  -- Clean approval DTI ceiling.
0.600000,  -- Manual review DTI upper boundary.
0.600000,  -- Hard simulated DTI stop at or above this value.

/*
Borderline diagnostic buffer.

0.050000 means Section 5 will tag a profile as threshold-adjacent when a value is within
5% of a relevant strategy threshold.

This is a governed diagnostic parameter, not a production underwriting tolerance and not
an empirically calibrated cutoff.
*/
0.050000,

/* Decision convention controls. */
'APPROVED_AS_REQUESTED',
```

## Patch 3.A — Add gatekeeper validation

Place after the DTI threshold validation block in Section 3.1.

```sql
/*-------------------------------------------------------------------------------------------
Gatekeeper: borderline diagnostic buffer.

This parameter exists only to support non-decisioning segmentation in Section 5.
It prevents hidden hardcoded "near threshold" logic from appearing inside downstream CASE blocks.

Allowed range:
    0.000000 to 0.250000

Interpretation:
    0.000000 disables threshold-adjacent borderline tagging.
    Values above 0.250000 are not allowed because they would make too much of the population
    appear borderline and reduce diagnostic usefulness.
-------------------------------------------------------------------------------------------*/
IF p.borderline_threshold_buffer_pct IS NULL
   OR p.borderline_threshold_buffer_pct < 0
   OR p.borderline_threshold_buffer_pct > 0.250000 THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: borderline_threshold_buffer_pct must be between 0 and 0.25.';
END IF;
```

---

# 3. Section 5 SQL only — Derived Strategy Segmentation Layer

```sql
/***************************************************************************************************
SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Translate finalized Module 1 source fields into policy-readable diagnostic segments that can be
    consumed by later Module 2 rule sections.

    Section 5 is a staging and interpretability layer.

    It prepares the data for future strategy rules by creating transparent, non-decisioning segments
    such as synthetic estimated-risk tier, requested PTI bucket, DTI bucket, requested exposure tier,
    requested Expected Loss tier, product × score policy segment, mixed-signal profile type, and
    borderline profile indicator.

SQL PURPOSE:
    1. Read from tmp_m2_stage_1_source_applications.
    2. Preserve all Section 4 fields.
    3. Attach active strategy thresholds from tmp_module2_strategy_params.
    4. Attach product-specific thresholds from tmp_module2_product_policy_params.
    5. Create diagnostic segmentation fields.
    6. Validate that staging row count, application uniqueness, threshold availability, and segment
       completeness are preserved.

SECTION 5 IS NOT A DECISION LAYER:
    Section 5 does not assign:
        decision_outcome
        decision_path
        approval_flag
        decline_flag
        manual_review_flag
        counteroffer_flag
        simulated_offer_exposure_flag
        primary_reason_code
        approved_amount
        approved_monthly_payment_proxy
        approved_payment_to_income_ratio
        approved_expected_loss_amount

WHY SEGMENTATION IS SEPARATED FROM DECISION RULES:
    Segmentation makes later rule logic easier to inspect, explain, and validate. A reviewer should
    be able to see how continuous inputs such as the synthetic estimated-PD proxy, requested PTI,
    DTI, requested amount, and requested Expected Loss were translated into diagnostic tiers before
    any simulated policy stop, review trigger, counteroffer path, or approval outcome is assigned.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In this section it is used only as the:
        synthetic estimated-PD proxy input

    Section 5 does not recalculate estimated_pd.
    Section 5 does not create a post-decision risk model.
    Section 5 does not treat estimated_pd as a calibrated production probability of default.

REQUESTED VS APPROVED STRUCTURE:
    Section 5 uses requested-structure economics from Module 1:
        requested_amount
        requested_monthly_payment_proxy
        requested_payment_to_income_ratio
        requested_expected_loss_amount

    approved_amount, approved_payment_to_income_ratio, and approved_expected_loss_amount do not
    exist yet. They will be calculated only after the decision hierarchy and exposure treatment logic
    are built.

MIXED-SIGNAL BOUNDARY:
    mixed_signal_profile_type is diagnostic only.

    It identifies realistic overlap patterns such as strong credit with high requested PTI or weaker
    credit with manageable requested PTI. It does not automatically drive approval, review, decline,
    or counteroffer outcomes in Section 5.

BORDERLINE BOUNDARY:
    borderline_profile_flag is diagnostic only.

    It uses the governed borderline_threshold_buffer_pct parameter from Section 2. It does not create
    manual review routing in Section 5.

THRESHOLD TRANSPARENCY:
    Section 5 carries forward the relevant global and product thresholds used for segmentation so
    later rule logic is explainable. This avoids hidden policy assumptions and supports audit review.

***************************************************************************************************/



/***************************************************************************************************
SECTION 5.1 — CLEAN RESET OF SECTION 5 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;



/***************************************************************************************************
SECTION 5.2 — CREATE DERIVED STRATEGY SEGMENTATION TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_2_strategy_segments

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_1_source_applications

OUTPUT:
    All Section 4 fields plus:
        strategy and product thresholds
        score_band_policy_key
        strategy_risk_tier
        requested_pti_bucket
        dti_bucket
        requested_exposure_tier
        requested_expected_loss_tier
        product_score_policy_segment
        mixed_signal_profile_type
        mixed_signal_condition_count
        borderline_profile_flag

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_2_strategy_segments
ON COMMIT PRESERVE ROWS
AS
WITH active_params AS (
    SELECT *
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

/*-----------------------------------------------------------------------------------------------
Attach active strategy thresholds and product-specific policy context.

This is not rule application. It is threshold attachment for transparency and later use.

The product policy join is repeated here because Section 5 needs the actual threshold values, while
Section 4 only validated that policy configuration exists.
-----------------------------------------------------------------------------------------------*/
stage_with_thresholds AS (
    SELECT
        s.*,

        /* Global synthetic estimated-PD proxy thresholds */
        p.approve_max_estimated_pd_proxy,
        p.counteroffer_max_estimated_pd_proxy,
        p.review_max_estimated_pd_proxy,
        p.decline_min_estimated_pd_proxy,

        /* Global PTI defaults carried for transparency; product-specific PTI thresholds drive PTI buckets */
        p.global_approve_max_pti,
        p.global_review_max_pti,
        p.global_decline_min_pti,

        /* Global DTI thresholds */
        p.approve_max_dti,
        p.review_max_dti,
        p.decline_min_dti,

        /* Governed diagnostic buffer for threshold-adjacent profiles */
        p.borderline_threshold_buffer_pct,

        /* Product-policy join confirmation */
        pp.product_type AS product_policy_product_type,

        /* Product-specific PTI thresholds */
        pp.product_approve_max_pti,
        pp.product_review_max_pti,
        pp.product_decline_min_pti,
        pp.counteroffer_target_pti,

        /* Product-specific requested-exposure Expected Loss thresholds */
        pp.product_approve_max_requested_el,
        pp.product_review_max_requested_el,
        pp.product_decline_min_requested_el,
        pp.product_approved_el_cap,

        /* Product-specific approved exposure limits */
        pp.product_min_approved_amount,
        pp.product_max_approved_amount,

        /* Counteroffer and manual-review configuration context */
        pp.counteroffer_allowed_flag,
        pp.manual_review_allowed_flag,
        pp.product_min_counteroffer_pct,
        pp.product_max_exposure_reduction_pct,
        pp.exposure_assignment_method,
        pp.approved_amount_rounding_increment,

        /*
        Derived threshold support fields.

        These derived thresholds avoid undocumented magic numbers. Where a diagnostic tier needs
        a low/moderate or elevated/high split inside a governed band, the split is calculated as a
        midpoint between governed thresholds rather than introduced as an ungoverned cutoff.
        */
        (p.approve_max_estimated_pd_proxy / 2.0)
            AS risk_low_moderate_split_estimated_pd_proxy,

        (
            pp.product_approve_max_pti
            + (
                LEAST(pp.product_review_max_pti, pp.product_decline_min_pti)
                - pp.product_approve_max_pti
              ) / 2.0
        ) AS product_pti_elevated_high_split,

        (pp.counteroffer_target_pti / 2.0)
            AS product_pti_low_moderate_split,

        (
            p.approve_max_dti
            + (p.review_max_dti - p.approve_max_dti) / 2.0
        ) AS dti_elevated_high_split,

        (p.approve_max_dti / 2.0)
            AS dti_low_moderate_split,

        (pp.product_approved_el_cap / 2.0)
            AS requested_el_low_moderate_split,

        /*
        Extreme requested-exposure cutoff.

        Formula:
            product_max_approved_amount / (1 - product_max_exposure_reduction_pct)

        Interpretation:
            If a request is above this value, even the maximum allowed exposure reduction would not
            bring the request down to the product approval cap without exceeding the governed
            reduction framework.

        Example:
            If product cap = 100,000 and max reduction = 50%, then a request above 200,000 is
            extreme because reducing it to 100,000 would require more than a 50% reduction.
        */
        (
            pp.product_max_approved_amount
            / NULLIF((1.0 - pp.product_max_exposure_reduction_pct), 0)
        ) AS product_extreme_requested_amount_cutoff,

        /*
        Low-exposure diagnostic cutoff for mixed-signal detection.

        Formula:
            product_min_approved_amount / product_min_counteroffer_pct

        Interpretation:
            This uses governed product parameters to identify requests that are close to the
            product's lower viable exposure range. It is diagnostic only and does not create a
            policy outcome.
        */
        (
            pp.product_min_approved_amount
            / NULLIF(pp.product_min_counteroffer_pct, 0)
        ) AS low_exposure_diagnostic_cutoff

    FROM tmp_m2_stage_1_source_applications s
    CROSS JOIN active_params p
    LEFT JOIN tmp_module2_product_policy_params pp
        ON pp.product_type = s.product_type_policy_key
),

/*-----------------------------------------------------------------------------------------------
Normalize score band for policy-readable segment construction.

Module 1 score_band is preserved exactly as product / borrower lineage.
score_band_policy_key is the normalized Module 2 segmentation key.

No Module 1 field is modified.
-----------------------------------------------------------------------------------------------*/
score_normalized AS (
    SELECT
        t.*,

        TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(t.score_band)), '[^A-Z0-9]+', '_', 'g'))
            AS score_band_normalized_text,

        CASE
            WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(t.score_band)), '[^A-Z0-9]+', '_', 'g'))
                 IN ('SUPER_PRIME', 'SUPERPRIME')
                THEN 'SUPER_PRIME'

            WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(t.score_band)), '[^A-Z0-9]+', '_', 'g'))
                 IN ('PRIME')
                THEN 'PRIME'

            WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(t.score_band)), '[^A-Z0-9]+', '_', 'g'))
                 IN ('NEAR_PRIME', 'NEARPRIME')
                THEN 'NEAR_PRIME'

            WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(t.score_band)), '[^A-Z0-9]+', '_', 'g'))
                 IN ('SUBPRIME', 'SUB_PRIME')
                THEN 'SUBPRIME'

            WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(t.score_band)), '[^A-Z0-9]+', '_', 'g'))
                 IN ('DEEP_SUBPRIME', 'DEEP_SUB_PRIME')
                THEN 'DEEP_SUBPRIME'

            ELSE NULL
        END AS score_band_policy_key

    FROM stage_with_thresholds t
),

/*-----------------------------------------------------------------------------------------------
Create core diagnostic segmentation fields.

These fields are designed to make later strategy logic easier to review. They do not assign
strategy outcomes.
-----------------------------------------------------------------------------------------------*/
core_segments AS (
    SELECT
        n.*,

        /*
        strategy_risk_tier

        Input:
            estimated_pd, interpreted as the synthetic estimated-PD proxy.

        Equality convention:
            <= approve_max_estimated_pd_proxy       remains inside the cleaner approval-risk zone.
            <= counteroffer_max_estimated_pd_proxy  remains inside the reduced-exposure eligibility zone.
            <  decline_min_estimated_pd_proxy       remains below the hard severe-risk stop.
            >= decline_min_estimated_pd_proxy       enters the severe synthetic estimated-risk tier.

        LOW vs MODERATE:
            The low/moderate split uses the midpoint between 0 and approve_max_estimated_pd_proxy.
            This is a diagnostic split inside the clean-risk band, not a separate policy cutoff.
        */
        CASE
            WHEN n.estimated_pd <= n.risk_low_moderate_split_estimated_pd_proxy
                THEN 'LOW_SYNTHETIC_RISK'

            WHEN n.estimated_pd <= n.approve_max_estimated_pd_proxy
                THEN 'MODERATE_SYNTHETIC_RISK'

            WHEN n.estimated_pd <= n.counteroffer_max_estimated_pd_proxy
                THEN 'ELEVATED_SYNTHETIC_RISK'

            WHEN n.estimated_pd < n.decline_min_estimated_pd_proxy
                THEN 'HIGH_SYNTHETIC_RISK'

            WHEN n.estimated_pd >= n.decline_min_estimated_pd_proxy
                THEN 'SEVERE_SYNTHETIC_RISK'

            ELSE NULL
        END AS strategy_risk_tier,


        /*
        requested_pti_bucket

        Input:
            requested_payment_to_income_ratio from Section 4.

        Interpretation:
            This is the original requested-structure PTI from Module 1, not an approved PTI.

        Product-specific thresholds drive the classification because affordability burden differs
        materially by product structure.

        LOW vs MODERATE:
            Uses counteroffer_target_pti / 2.0 as a governed diagnostic split.

        ELEVATED vs HIGH:
            Uses the midpoint between product_approve_max_pti and the lower of
            product_review_max_pti / product_decline_min_pti.
        */
        CASE
            WHEN n.requested_payment_to_income_ratio <= n.product_pti_low_moderate_split
                THEN 'LOW_REQUESTED_PTI'

            WHEN n.requested_payment_to_income_ratio <= n.product_approve_max_pti
                THEN 'MODERATE_REQUESTED_PTI'

            WHEN n.requested_payment_to_income_ratio <= n.product_pti_elevated_high_split
                THEN 'ELEVATED_REQUESTED_PTI'

            WHEN n.requested_payment_to_income_ratio < n.product_decline_min_pti
                THEN 'HIGH_REQUESTED_PTI'

            WHEN n.requested_payment_to_income_ratio >= n.product_decline_min_pti
                THEN 'SEVERE_REQUESTED_PTI'

            ELSE NULL
        END AS requested_pti_bucket,


        /*
        dti_bucket

        Input:
            debt_to_income_ratio from Module 1.

        Interpretation:
            DTI is an existing-obligation capacity signal. Unlike requested PTI, it is not directly
            fixed by reducing the requested exposure through a counteroffer in Module 2 v1.0.
        */
        CASE
            WHEN n.debt_to_income_ratio <= n.dti_low_moderate_split
                THEN 'LOW_DTI'

            WHEN n.debt_to_income_ratio <= n.approve_max_dti
                THEN 'MODERATE_DTI'

            WHEN n.debt_to_income_ratio <= n.dti_elevated_high_split
                THEN 'ELEVATED_DTI'

            WHEN n.debt_to_income_ratio < n.decline_min_dti
                THEN 'HIGH_DTI'

            WHEN n.debt_to_income_ratio >= n.decline_min_dti
                THEN 'SEVERE_DTI'

            ELSE NULL
        END AS dti_bucket,


        /*
        requested_exposure_tier

        Input:
            requested_amount from Module 1.

        Interpretation:
            Requested exposure is not approved exposure. Section 5 does not calculate approved_amount.

        Extreme requested exposure logic:
            ABOVE_PRODUCT_APPROVAL_CAP means the requested amount exceeds the product cap but could
            potentially be reduced within the product's governed maximum exposure-reduction framework.

            EXTREME_REQUESTED_EXPOSURE means the requested amount exceeds the product cap by more
            than the configured exposure-reduction framework can reasonably address.
        */
        CASE
            WHEN n.requested_amount < n.product_min_approved_amount
                THEN 'BELOW_PRODUCT_MINIMUM'

            WHEN n.requested_amount >= n.product_min_approved_amount
                 AND n.requested_amount <= n.product_max_approved_amount
                THEN 'WITHIN_PRODUCT_LIMITS'

            WHEN n.requested_amount > n.product_max_approved_amount
                 AND n.requested_amount <= n.product_extreme_requested_amount_cutoff
                THEN 'ABOVE_PRODUCT_APPROVAL_CAP'

            WHEN n.requested_amount > n.product_extreme_requested_amount_cutoff
                THEN 'EXTREME_REQUESTED_EXPOSURE'

            ELSE NULL
        END AS requested_exposure_tier,


        /*
        requested_expected_loss_tier

        Input:
            requested_expected_loss_amount, which is the Module 2 alias for Module 1
            expected_loss_amount.

        Interpretation:
            requested_expected_loss_amount is requested-exposure Expected Loss.

            approved_expected_loss_amount does not exist yet and is not calculated in Section 5.
        */
        CASE
            WHEN n.requested_expected_loss_amount <= n.requested_el_low_moderate_split
                THEN 'LOW_REQUESTED_EL'

            WHEN n.requested_expected_loss_amount <= n.product_approve_max_requested_el
                THEN 'MODERATE_REQUESTED_EL'

            WHEN n.requested_expected_loss_amount <= n.product_review_max_requested_el
                THEN 'ELEVATED_REQUESTED_EL'

            WHEN n.requested_expected_loss_amount < n.product_decline_min_requested_el
                THEN 'HIGH_REQUESTED_EL'

            WHEN n.requested_expected_loss_amount >= n.product_decline_min_requested_el
                THEN 'SEVERE_REQUESTED_EL'

            ELSE NULL
        END AS requested_expected_loss_tier,


        /*
        product_score_policy_segment

        Construction:
            product_type_policy_key || '_' || score_band_policy_key

        This is a policy-readable diagnostic segment. It does not create a decision outcome.
        */
        CASE
            WHEN n.product_type_policy_key IS NOT NULL
             AND n.score_band_policy_key IS NOT NULL
                THEN n.product_type_policy_key || '_' || n.score_band_policy_key

            ELSE NULL
        END AS product_score_policy_segment

    FROM score_normalized n
),

/*-----------------------------------------------------------------------------------------------
Create mixed-signal diagnostic condition flags.

These are diagnostic segmentation flags only.
They are not approval, decline, review, or counteroffer flags.
-----------------------------------------------------------------------------------------------*/
mixed_signal_inputs AS (
    SELECT
        c.*,

        (
            c.score_band_policy_key IN ('SUPER_PRIME', 'PRIME')
            AND c.requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
        ) AS ms_strong_credit_high_pti_flag,

        (
            c.score_band_policy_key IN ('SUBPRIME', 'DEEP_SUBPRIME')
            AND c.requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS ms_weak_credit_low_pti_flag,

        (
            c.requested_exposure_tier IN ('ABOVE_PRODUCT_APPROVAL_CAP', 'EXTREME_REQUESTED_EXPOSURE')
            AND c.strategy_risk_tier IN ('LOW_SYNTHETIC_RISK', 'MODERATE_SYNTHETIC_RISK')
        ) AS ms_large_exposure_low_risk_flag,

        (
            c.strategy_risk_tier IN ('HIGH_SYNTHETIC_RISK', 'SEVERE_SYNTHETIC_RISK')
            AND c.requested_amount <= c.low_exposure_diagnostic_cutoff
        ) AS ms_high_risk_low_exposure_flag,

        (
            c.dti_bucket IN ('HIGH_DTI', 'SEVERE_DTI')
            AND c.requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS ms_high_dti_low_requested_pti_flag

    FROM core_segments c
),

/*-----------------------------------------------------------------------------------------------
Count mixed-signal conditions.

Priority convention:
    If exactly one mixed-signal condition applies, assign that condition as mixed_signal_profile_type.
    If more than one applies, assign MULTIPLE_MIXED_SIGNALS.
    If none applies, assign NO_MIXED_SIGNAL_PROFILE.

No silent hierarchy is used to choose one condition over another when multiple conditions are present.
-----------------------------------------------------------------------------------------------*/
mixed_signal_counted AS (
    SELECT
        m.*,

        (
            m.ms_strong_credit_high_pti_flag::INT
            + m.ms_weak_credit_low_pti_flag::INT
            + m.ms_large_exposure_low_risk_flag::INT
            + m.ms_high_risk_low_exposure_flag::INT
            + m.ms_high_dti_low_requested_pti_flag::INT
        ) AS mixed_signal_condition_count

    FROM mixed_signal_inputs m
),

/*-----------------------------------------------------------------------------------------------
Create final diagnostic segmentation outputs.

borderline_profile_flag:
    TRUE when a row is within borderline_threshold_buffer_pct of one or more relevant strategy
    thresholds.

    This is a diagnostic profile indicator only. It does not assign MANUAL_REVIEW.
-----------------------------------------------------------------------------------------------*/
final_segments AS (
    SELECT
        mc.*,

        CASE
            WHEN mc.mixed_signal_condition_count = 0
                THEN 'NO_MIXED_SIGNAL_PROFILE'

            WHEN mc.mixed_signal_condition_count > 1
                THEN 'MULTIPLE_MIXED_SIGNALS'

            WHEN mc.ms_strong_credit_high_pti_flag
                THEN 'STRONG_CREDIT_HIGH_PTI'

            WHEN mc.ms_weak_credit_low_pti_flag
                THEN 'WEAK_CREDIT_LOW_PTI'

            WHEN mc.ms_large_exposure_low_risk_flag
                THEN 'LARGE_EXPOSURE_LOW_RISK'

            WHEN mc.ms_high_risk_low_exposure_flag
                THEN 'HIGH_RISK_LOW_EXPOSURE'

            WHEN mc.ms_high_dti_low_requested_pti_flag
                THEN 'HIGH_DTI_LOW_REQUESTED_PTI'

            ELSE NULL
        END AS mixed_signal_profile_type,

        (
            mc.borderline_threshold_buffer_pct > 0
            AND (
                /* Synthetic estimated-PD proxy threshold adjacency */
                ABS(mc.estimated_pd - mc.approve_max_estimated_pd_proxy)
                    <= mc.approve_max_estimated_pd_proxy * mc.borderline_threshold_buffer_pct
                OR ABS(mc.estimated_pd - mc.counteroffer_max_estimated_pd_proxy)
                    <= mc.counteroffer_max_estimated_pd_proxy * mc.borderline_threshold_buffer_pct
                OR ABS(mc.estimated_pd - mc.review_max_estimated_pd_proxy)
                    <= mc.review_max_estimated_pd_proxy * mc.borderline_threshold_buffer_pct
                OR ABS(mc.estimated_pd - mc.decline_min_estimated_pd_proxy)
                    <= mc.decline_min_estimated_pd_proxy * mc.borderline_threshold_buffer_pct

                /* Requested PTI threshold adjacency */
                OR ABS(mc.requested_payment_to_income_ratio - mc.counteroffer_target_pti)
                    <= mc.counteroffer_target_pti * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_payment_to_income_ratio - mc.product_approve_max_pti)
                    <= mc.product_approve_max_pti * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_payment_to_income_ratio - mc.product_review_max_pti)
                    <= mc.product_review_max_pti * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_payment_to_income_ratio - mc.product_decline_min_pti)
                    <= mc.product_decline_min_pti * mc.borderline_threshold_buffer_pct

                /* DTI threshold adjacency */
                OR ABS(mc.debt_to_income_ratio - mc.approve_max_dti)
                    <= mc.approve_max_dti * mc.borderline_threshold_buffer_pct
                OR ABS(mc.debt_to_income_ratio - mc.review_max_dti)
                    <= mc.review_max_dti * mc.borderline_threshold_buffer_pct
                OR ABS(mc.debt_to_income_ratio - mc.decline_min_dti)
                    <= mc.decline_min_dti * mc.borderline_threshold_buffer_pct

                /* Requested-exposure Expected Loss threshold adjacency */
                OR ABS(mc.requested_expected_loss_amount - mc.product_approved_el_cap)
                    <= mc.product_approved_el_cap * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_expected_loss_amount - mc.product_approve_max_requested_el)
                    <= mc.product_approve_max_requested_el * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_expected_loss_amount - mc.product_review_max_requested_el)
                    <= mc.product_review_max_requested_el * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_expected_loss_amount - mc.product_decline_min_requested_el)
                    <= mc.product_decline_min_requested_el * mc.borderline_threshold_buffer_pct

                /* Product exposure threshold adjacency */
                OR ABS(mc.requested_amount - mc.product_min_approved_amount)
                    <= mc.product_min_approved_amount * mc.borderline_threshold_buffer_pct
                OR ABS(mc.requested_amount - mc.product_max_approved_amount)
                    <= mc.product_max_approved_amount * mc.borderline_threshold_buffer_pct
            )
        ) AS borderline_profile_flag

    FROM mixed_signal_counted mc
)

SELECT *
FROM final_segments;



/***************************************************************************************************
SECTION 5.3 — LOCAL FAIL-FAST CHECKS FOR STRATEGY SEGMENTATION STAGE
****************************************************************************************************

PURPOSE:
    Validate the Section 5 staging layer before any rule flags or decision outcomes are created.

These checks are not the full Module 2 QA framework. They protect downstream sections from consuming
incomplete segmentation, missing thresholds, row multiplication, or ambiguous policy configuration.

***************************************************************************************************/

DO $$
DECLARE
    v_stage1_count BIGINT;
    v_stage2_count BIGINT;
    v_stage2_distinct_app_count BIGINT;

    v_null_segment_count BIGINT;
    v_null_threshold_count BIGINT;
    v_bad_policy_config_count BIGINT;
    v_duplicate_application_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 4 to Section 5.

    A row-count change here would indicate accidental row loss or row multiplication during threshold
    attachment or product policy joining.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage1_count
    FROM tmp_m2_stage_1_source_applications;

    SELECT COUNT(*)
    INTO v_stage2_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_count <> v_stage1_count THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: row count changed from Section 4 to Section 5. Stage 1 rows: %, Stage 2 rows: %.',
            v_stage1_count,
            v_stage2_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage2_distinct_app_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_distinct_app_count <> v_stage2_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_2_strategy_segments
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 5 failure: application_id uniqueness was not preserved. Stage 2 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage2_count,
            v_stage2_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: every staged row must still have exactly one product policy configuration.

    This remains validation-only and does not apply product policy rules.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_bad_policy_config_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE product_type_policy_key IS NULL
       OR product_policy_match_count <> 1
       OR product_policy_config_found_flag IS DISTINCT FROM TRUE
       OR product_policy_product_type IS NULL;

    IF v_bad_policy_config_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) do not have exactly one valid product policy configuration.',
            v_bad_policy_config_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required thresholds must be available for every row.

    Later rule sections need these values to remain visible and explainable. Missing thresholds would
    create null CASE behavior or hidden fallback logic.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_threshold_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE approve_max_estimated_pd_proxy IS NULL
       OR counteroffer_max_estimated_pd_proxy IS NULL
       OR review_max_estimated_pd_proxy IS NULL
       OR decline_min_estimated_pd_proxy IS NULL

       OR global_approve_max_pti IS NULL
       OR global_review_max_pti IS NULL
       OR global_decline_min_pti IS NULL

       OR approve_max_dti IS NULL
       OR review_max_dti IS NULL
       OR decline_min_dti IS NULL

       OR borderline_threshold_buffer_pct IS NULL

       OR product_approve_max_pti IS NULL
       OR product_review_max_pti IS NULL
       OR product_decline_min_pti IS NULL
       OR counteroffer_target_pti IS NULL

       OR product_approve_max_requested_el IS NULL
       OR product_review_max_requested_el IS NULL
       OR product_decline_min_requested_el IS NULL
       OR product_approved_el_cap IS NULL

       OR product_min_approved_amount IS NULL
       OR product_max_approved_amount IS NULL
       OR counteroffer_allowed_flag IS NULL
       OR manual_review_allowed_flag IS NULL
       OR product_min_counteroffer_pct IS NULL
       OR product_max_exposure_reduction_pct IS NULL
       OR exposure_assignment_method IS NULL
       OR approved_amount_rounding_increment IS NULL

       OR risk_low_moderate_split_estimated_pd_proxy IS NULL
       OR product_pti_low_moderate_split IS NULL
       OR product_pti_elevated_high_split IS NULL
       OR dti_low_moderate_split IS NULL
       OR dti_elevated_high_split IS NULL
       OR requested_el_low_moderate_split IS NULL
       OR product_extreme_requested_amount_cutoff IS NULL
       OR low_exposure_diagnostic_cutoff IS NULL;

    IF v_null_threshold_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have missing threshold or derived-threshold values.',
            v_null_threshold_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required segmentation fields must be populated.

    These fields are non-decisioning diagnostics, but downstream rule logic should not consume null
    segmentation values.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_segment_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE strategy_risk_tier IS NULL
       OR requested_pti_bucket IS NULL
       OR dti_bucket IS NULL
       OR requested_exposure_tier IS NULL
       OR requested_expected_loss_tier IS NULL
       OR score_band_policy_key IS NULL
       OR product_score_policy_segment IS NULL
       OR mixed_signal_profile_type IS NULL
       OR mixed_signal_condition_count IS NULL
       OR borderline_profile_flag IS NULL;

    IF v_null_segment_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have null required segmentation fields.',
            v_null_segment_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 5.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight local diagnostics for the derived segmentation layer.

IMPORTANT:
    These are not full Module 2 QA outputs.
    They should not be interpreted as final strategy validation.

    Full QA will be built later after decision outcomes, reason codes, approved exposure, approved
    payment, approved Expected Loss, latest-run output, and archive logic exist.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
5.4.1 Row count and application identity count.

Expected:
    staged_row_count = distinct_application_id_count
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS staged_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_2_strategy_segments;


/*-----------------------------------------------------------------------------------------------
5.4.2 Synthetic estimated-risk tier distribution.

Interpretation:
    estimated_pd is the Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY strategy_risk_tier
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.3 Requested PTI bucket distribution.

Interpretation:
    requested_pti_bucket uses requested_payment_to_income_ratio from Module 1 requested structure.
    This is not approved PTI.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_pti_bucket
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.4 DTI bucket distribution.

Interpretation:
    DTI is an existing-obligation capacity signal and is not directly counteroffer-adjustable in
    Module 2 v1.0.
-----------------------------------------------------------------------------------------------*/
SELECT
    dti_bucket,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY dti_bucket
ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.5 Requested exposure tier distribution.

Interpretation:
    Requested exposure is the Module 1 requested_amount.
    Approved exposure does not exist yet.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_tier,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_exposure_tier
ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'WITHIN_PRODUCT_LIMITS' THEN 2
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.6 Requested Expected Loss tier distribution.

Interpretation:
    requested_expected_loss_amount is Module 1 expected_loss_amount renamed for Module 2 clarity.
    approved_expected_loss_amount does not exist yet.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_expected_loss_tier,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_expected_loss_tier
ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.7 Product × score policy segment distribution.

Purpose:
    Confirms that product and score segmentation is available for later strategy rules and reporting.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_score_policy_segment,
    COUNT(*) AS row_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY product_score_policy_segment
ORDER BY product_score_policy_segment;


/*-----------------------------------------------------------------------------------------------
5.4.8 Mixed-signal diagnostic profile distribution.

Interpretation:
    Mixed-signal profiles are diagnostic only. They are not automatic decisions.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY mixed_signal_profile_type
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
    END;


/*-----------------------------------------------------------------------------------------------
5.4.9 Borderline profile diagnostic distribution.

Interpretation:
    borderline_profile_flag identifies threshold-adjacent profiles using the governed
    borderline_threshold_buffer_pct parameter. It does not assign manual review.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_2_strategy_segments
GROUP BY borderline_profile_flag
ORDER BY borderline_profile_flag;


/*-----------------------------------------------------------------------------------------------
5.4.10 Product × synthetic estimated-risk tier summary.

Purpose:
    Staging diagnostic only. This does not validate final strategy decisions.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    product_type_policy_key,
    strategy_risk_tier
ORDER BY
    product_type_policy_key,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.11 Score band × synthetic estimated-risk tier summary.

Purpose:
    Confirms score-band policy keys and risk tiers are available for later strategy interpretation.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    score_band_policy_key,
    strategy_risk_tier
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.12 Requested PTI bucket × synthetic estimated-risk tier summary.

Purpose:
    Confirms that requested affordability burden and synthetic estimated-risk segmentation are both
    available before later rule logic.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    requested_pti_bucket,
    strategy_risk_tier
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/***************************************************************************************************
END OF SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER

If execution reaches this point:
    1. tmp_m2_stage_2_strategy_segments exists.
    2. All Section 4 source fields have been preserved.
    3. Module 1 lineage and Module 2 strategy metadata remain attached.
    4. Global strategy thresholds are attached.
    5. Product-specific policy thresholds are attached.
    6. product_type_policy_key and score_band_policy_key are available.
    7. strategy_risk_tier is populated using estimated_pd as the synthetic estimated-PD proxy input.
    8. requested_pti_bucket is populated using requested-payment PTI and product-specific thresholds.
    9. dti_bucket is populated using global DTI thresholds.
    10. requested_exposure_tier is populated using requested_amount and product exposure parameters.
    11. requested_expected_loss_tier is populated using requested_expected_loss_amount.
    12. product_score_policy_segment is populated.
    13. mixed_signal_profile_type is populated as a diagnostic profile type.
    14. borderline_profile_flag is populated using a governed diagnostic buffer.

No decision outcomes have been generated.
No decision flags have been created.
No reason codes have been assigned.
No approved amount has been calculated.
No approved payment proxy has been calculated.
No approved payment-to-income ratio has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No strategy archive rows have been inserted.

***************************************************************************************************/
```

---

# 4. What Section 5 establishes

Section 5 creates:

```text
tmp_m2_stage_2_strategy_segments
```

It preserves the Section 4 source foundation and adds transparent, non-decisioning segmentation:

```text
strategy_risk_tier
requested_pti_bucket
dti_bucket
requested_exposure_tier
requested_expected_loss_tier
score_band_policy_key
product_score_policy_segment
mixed_signal_profile_type
borderline_profile_flag
```

It also attaches the global and product-specific threshold values needed for later rule logic, so downstream decisions remain explainable and auditable.

---

# 5. What Section 5 intentionally does not build

Section 5 does not create decision outcomes, decision flags, hard simulated policy stop logic, review triggers, counteroffer logic, reason codes, approved amounts, approved payment proxies, approved PTI, approved Expected Loss, final latest-run output, archive insert logic, or the full QA framework.

The segmentation fields are diagnostic preparation only.

---

# 6. Recommended next build step

Next should be:

```text
Section 6 — Rule Flag Construction Layer
```

That section should create deterministic, non-final rule trigger flags such as hard simulated policy stop indicators, synthetic estimated-risk trigger flags, affordability trigger flags, DTI trigger flags, exposure trigger flags, requested Expected Loss trigger flags, counteroffer eligibility diagnostics, and manual-review trigger diagnostics.

It should still avoid assigning final `decision_outcome` until the separate decision hierarchy section.
<!-- END_MESSAGE C038-M00087 -->


---

<a id="c038-m00088"></a>

### C038-M00088

**Andrew** · 2026-05-06T12:25:08.924000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00088 -->
This is strong. I agree with the Section 4 patches and the Section 5 segmentation layer direction.

Section 5 should be treated as provisionally accepted after one targeted patch described below.

It correctly:
- creates tmp_m2_stage_2_strategy_segments
- preserves Module 1 lineage
- preserves Module 2 strategy metadata
- preserves requested-structure economics
- uses estimated_pd only as the finalized Module 1 synthetic estimated-PD proxy input
- attaches relevant global and product thresholds
- creates diagnostic segmentation fields
- adds governed borderline logic instead of hidden threshold buffers
- avoids decision outcomes, reason codes, approved amount, approved payment, approved PTI, approved Expected Loss, latest-run output creation, and archive insertion

Before we move to Section 6, please apply the targeted patch below.

Do not rewrite Sections 0–5 in full unless necessary.

================================================================================
1. TARGETED SECTION 5 PATCH — REQUESTED EXPECTED LOSS LOW/MODERATE SPLIT
================================================================================

In the Section 5 threshold-support fields, please ensure the low/moderate split for requested Expected Loss is based on:

product_approve_max_requested_el / 2.0

not:

product_approved_el_cap / 2.0

Reason:
- product_approve_max_requested_el governs requested-exposure Expected Loss classification.
- product_approved_el_cap governs approved-exposure Expected Loss after exposure treatment.
- Section 5 is still pre-decision and pre-approved-exposure.
- approved_expected_loss_amount does not exist yet.

The requested Expected Loss tier should therefore use requested-exposure thresholds only.

Recommended targeted patch:

BEFORE:

requested_el_low_moderate_split =
    product_approved_el_cap / 2.0

AFTER:

requested_el_low_moderate_split =
    product_approve_max_requested_el / 2.0

Please apply this wherever Section 5 uses the low/moderate split for requested_expected_loss_tier.

Important:
product_approved_el_cap may still be carried forward for transparency and later approved-exposure logic, but it should not drive pre-decision requested Expected Loss tiering.

================================================================================
2. SECTION 5 ACCEPTANCE CRITERIA
================================================================================

After that patch, treat Section 5 as accepted if it establishes:

- tmp_m2_stage_2_strategy_segments exists
- row count is unchanged from tmp_m2_stage_1_source_applications
- application_id remains unique
- Module 1 lineage is preserved
- Module 2 strategy metadata is preserved
- product_type_policy_key remains available
- product policy configuration remains exactly one row per staged application
- estimated_pd is preserved as the Module 1 SQL field and interpreted as the synthetic estimated-PD proxy
- requested_monthly_payment_proxy is preserved from Module 1 monthly_payment_proxy
- requested_payment_to_income_ratio is preserved from Module 1 payment_to_income_ratio
- requested_expected_loss_amount is preserved from Module 1 expected_loss_amount
- strategy_risk_tier is populated
- requested_pti_bucket is populated
- dti_bucket is populated
- requested_exposure_tier is populated
- requested_expected_loss_tier is populated using requested-exposure thresholds
- product_score_policy_segment is populated
- mixed_signal_profile_type is populated
- mixed_signal_condition_count is populated
- borderline_profile_flag is populated using the governed borderline_threshold_buffer_pct parameter
- no decision_outcome is assigned
- no approval / decline / manual review / counteroffer flags are assigned
- no reason codes are assigned
- no approved_amount is calculated
- no approved_monthly_payment_proxy is calculated
- no approved_payment_to_income_ratio is calculated
- no approved_expected_loss_amount is calculated
- no final latest-run output table is created
- no archive rows are inserted

================================================================================
3. NEXT BUILD SCOPE: SECTION 6 ONLY
================================================================================

After the targeted Section 5 patch, please build only:

SECTION 6 — RULE FLAG CONSTRUCTION LAYER

Do not build:
- final decision hierarchy
- decision_outcome
- decision_path
- primary / secondary / tertiary reason codes
- triggered_reason_code_list
- reason_priority_rank
- approved_amount
- counteroffer_amount
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount
- final latest-run output table
- archive insert logic
- full QA framework

Those belong to later sections.

================================================================================
4. SECTION 6 OBJECTIVE
================================================================================

Section 6 should create deterministic, non-final rule trigger flags that prepare for the later decision hierarchy.

Recommended staged table:

tmp_m2_stage_3_rule_flags

Section 6 should read from:

tmp_m2_stage_2_strategy_segments

Section 6 should preserve all prior fields and add transparent trigger flags.

Important:
Section 6 is not the decision hierarchy.
A row may have multiple trigger flags.
Final prioritization happens later.

Purpose:
Section 6 should convert the diagnostic segmentation layer into auditable rule-trigger indicators.

It should answer:
“Which simulated policy conditions are triggered?”

It should not answer:
“What is the final strategy outcome?”

================================================================================
5. PARAMETER PATCH BEFORE SECTION 6, IF NEEDED
================================================================================

If Section 6 requires new governed parameters, provide a targeted Section 2 / Section 3 patch before writing Section 6.

Do not silently hard-code new policy controls.

Recommended new rule-control parameters, if not already present:

- bankruptcy_policy_stop_enabled
- major_derogatory_policy_stop_enabled
- severe_delinquency_policy_stop_enabled
- severe_delinquency_count_threshold
- high_utilization_review_enabled
- high_utilization_review_threshold
- low_score_review_enabled
- low_score_review_threshold

Suggested defaults:

bankruptcy_policy_stop_enabled = TRUE
major_derogatory_policy_stop_enabled = TRUE
severe_delinquency_policy_stop_enabled = TRUE
severe_delinquency_count_threshold = 4
high_utilization_review_enabled = TRUE
high_utilization_review_threshold = 0.85
low_score_review_enabled = TRUE
low_score_review_threshold = 580

These are simulated strategy controls, not production underwriting policy.

Gatekeepers should validate:
- boolean rule controls are not null
- severe_delinquency_count_threshold is a non-negative integer
- high_utilization_review_threshold is between 0 and 1
- low_score_review_threshold is within a plausible score range, such as 300 to 850

If you recommend different defaults, explain why before coding them.

================================================================================
6. REQUIRED SECTION 6 RULE FLAG FAMILIES
================================================================================

Please create rule flags across these families.

--------------------------------------------------------------------------------
1. Hard simulated policy stop flags
--------------------------------------------------------------------------------

Suggested fields:
- bankruptcy_policy_stop_flag
- major_derogatory_policy_stop_flag
- severe_delinquency_policy_stop_flag
- hard_policy_stop_flag
- hard_policy_stop_count

Purpose:
Identify severe simulated policy stop conditions before final decision hierarchy.

Important:
These are simulated policy stop flags, not production underwriting decisions.
They do not assign DECLINE yet.

--------------------------------------------------------------------------------
2. Synthetic estimated-risk flags
--------------------------------------------------------------------------------

Suggested fields:
- synthetic_risk_clean_approval_band_flag
- synthetic_risk_counteroffer_band_flag
- synthetic_risk_review_band_flag
- synthetic_risk_decline_trigger_flag

Use Module 1 estimated_pd as the synthetic estimated-PD proxy input.

Do not recalculate estimated_pd.

--------------------------------------------------------------------------------
3. Requested affordability flags
--------------------------------------------------------------------------------

Suggested fields:
- requested_pti_clean_band_flag
- requested_pti_counteroffer_candidate_flag
- requested_pti_review_trigger_flag
- requested_pti_decline_trigger_flag

Use requested_payment_to_income_ratio and product-specific PTI thresholds.

Important:
These flags use requested-structure affordability from Module 1.
Approved PTI does not exist yet.

--------------------------------------------------------------------------------
4. DTI capacity flags
--------------------------------------------------------------------------------

Suggested fields:
- dti_clean_band_flag
- dti_review_trigger_flag
- dti_decline_trigger_flag

DTI is an existing-obligation capacity signal.
It should not be treated as directly fixed by counteroffer in Module 2 v1.0.

--------------------------------------------------------------------------------
5. Requested Expected Loss flags
--------------------------------------------------------------------------------

Suggested fields:
- requested_el_clean_band_flag
- requested_el_counteroffer_candidate_flag
- requested_el_review_trigger_flag
- requested_el_decline_trigger_flag

Use requested_expected_loss_amount and product-specific requested-exposure Expected Loss thresholds.

Important:
These flags must use requested-exposure Expected Loss.
approved_expected_loss_amount does not exist yet.

--------------------------------------------------------------------------------
6. Exposure flags
--------------------------------------------------------------------------------

Suggested fields:
- requested_exposure_within_product_limit_flag
- requested_exposure_above_product_cap_flag
- requested_exposure_extreme_flag
- exposure_counteroffer_candidate_flag
- exposure_policy_stop_candidate_flag

Important:
Above-cap exposure may be counteroffer-eligible.
Extreme exposure may become a policy stop or unresolved review depending on later hierarchy.

Section 6 should not calculate the counteroffer amount yet.

--------------------------------------------------------------------------------
7. Counteroffer candidate flags
--------------------------------------------------------------------------------

Suggested fields:
- counteroffer_allowed_by_product_flag
- counteroffer_affordability_candidate_flag
- counteroffer_exposure_candidate_flag
- counteroffer_expected_loss_candidate_flag
- counteroffer_risk_band_eligible_flag
- counteroffer_candidate_flag

Important:
Section 6 should identify counteroffer candidates only.

It should not:
- calculate approved_amount
- calculate counteroffer_amount
- decide that the counteroffer is viable
- assign COUNTEROFFER as decision_outcome

Final counteroffer feasibility belongs to the approved exposure / counteroffer calculation section.

--------------------------------------------------------------------------------
8. Manual review candidate flags
--------------------------------------------------------------------------------

Suggested fields:
- manual_review_allowed_by_product_flag
- manual_review_risk_trigger_flag
- manual_review_affordability_trigger_flag
- manual_review_dti_trigger_flag
- manual_review_expected_loss_trigger_flag
- manual_review_mixed_signal_trigger_flag
- manual_review_borderline_trigger_flag
- manual_review_candidate_flag

Important:
Section 6 can identify manual-review candidates, but it should not assign MANUAL_REVIEW as the final decision_outcome.

Manual review remains unresolved until the final decision hierarchy.

--------------------------------------------------------------------------------
9. Supplemental behavioral review flags
--------------------------------------------------------------------------------

Because Section 6 may introduce high-utilization and low-score review controls, please include explicit flags for them if the parameters are added.

Suggested fields:
- high_utilization_review_trigger_flag
- low_score_review_trigger_flag
- supplemental_behavioral_review_trigger_flag
- supplemental_behavioral_review_trigger_count

Purpose:
Capture additional strategy-review signals that do not necessarily create hard policy stops but may contribute to review or decision hierarchy logic later.

Important:
These are still trigger flags only, not reason codes and not final outcomes.

--------------------------------------------------------------------------------
10. Clean approval candidate diagnostic flag
--------------------------------------------------------------------------------

Suggested field:
- clean_approval_candidate_flag

This should be diagnostic only.

It may identify rows that appear clean across all major dimensions, but it should not assign APPROVE.

Recommended definition:
clean_approval_candidate_flag should be TRUE only when the row has no major trigger families active.

At minimum, it should not be TRUE when:
- hard_policy_stop_flag = TRUE
- synthetic_risk_decline_trigger_flag = TRUE
- requested_pti_decline_trigger_flag = TRUE
- dti_decline_trigger_flag = TRUE
- requested_el_decline_trigger_flag = TRUE
- requested_exposure_extreme_flag = TRUE
- counteroffer_candidate_flag = TRUE
- manual_review_candidate_flag = TRUE

This prevents clean approval diagnostics from conflicting with material simulated policy triggers.

================================================================================
7. RULE COUNT FIELDS
================================================================================

Please add transparent count fields that summarize how many trigger families were activated.

Suggested fields:
- hard_policy_stop_count
- synthetic_risk_trigger_count
- affordability_trigger_count
- dti_trigger_count
- requested_el_trigger_count
- exposure_trigger_count
- counteroffer_candidate_trigger_count
- manual_review_candidate_trigger_count
- supplemental_behavioral_review_trigger_count
- total_rule_trigger_count

These are diagnostic counts only.
They do not assign outcomes.

Please make sure counts are numeric, non-null, and non-negative.

================================================================================
8. NO REASON CODES YET
================================================================================

Do not assign:
- primary_reason_code
- secondary_reason_code
- tertiary_reason_code
- triggered_reason_code_list
- reason_priority_rank
- primary_reason_family

Reason-code assignment belongs to a later section after decision hierarchy is built.

If you want to create internal trigger labels for QA, keep them as diagnostic trigger fields only, not reason codes.

================================================================================
9. SECTION 6 LOCAL GATEKEEPERS
================================================================================

At the end of Section 6, include local fail-fast checks.

Validate:

- row count is unchanged from tmp_m2_stage_2_strategy_segments
- application_id remains unique
- all required rule flags are non-null
- all rule count fields are non-null
- all rule count fields are non-negative
- clean_approval_candidate_flag is not simultaneously true with hard_policy_stop_flag
- clean_approval_candidate_flag is not simultaneously true with synthetic_risk_decline_trigger_flag
- clean_approval_candidate_flag is not simultaneously true with requested_pti_decline_trigger_flag
- clean_approval_candidate_flag is not simultaneously true with dti_decline_trigger_flag
- clean_approval_candidate_flag is not simultaneously true with requested_el_decline_trigger_flag
- clean_approval_candidate_flag is not simultaneously true with requested_exposure_extreme_flag
- clean_approval_candidate_flag is not simultaneously true with counteroffer_candidate_flag
- clean_approval_candidate_flag is not simultaneously true with manual_review_candidate_flag
- counteroffer_candidate_flag is not true when counteroffer_allowed_by_product_flag is false
- manual_review_candidate_flag is not true when manual_review_allowed_by_product_flag is false
- synthetic_risk_decline_trigger_flag is true when estimated_pd >= decline_min_estimated_pd_proxy
- requested_pti_decline_trigger_flag is true when requested_payment_to_income_ratio >= product_decline_min_pti
- dti_decline_trigger_flag is true when debt_to_income_ratio >= decline_min_dti
- requested_el_decline_trigger_flag is true when requested_expected_loss_amount >= product_decline_min_requested_el
- no decision_outcome field is created yet
- no approved_amount field is created yet
- no approved_expected_loss_amount field is created yet
- no reason-code fields are created yet

These are Section 6 local staging gatekeepers only, not full Module 2 QA.

================================================================================
10. SECTION 6 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight staging diagnostics.

Suggested checks:

1. Count by hard_policy_stop_flag
2. Count by bankruptcy_policy_stop_flag
3. Count by major_derogatory_policy_stop_flag
4. Count by severe_delinquency_policy_stop_flag
5. Count by synthetic_risk_decline_trigger_flag
6. Count by requested_pti_decline_trigger_flag
7. Count by dti_decline_trigger_flag
8. Count by requested_el_decline_trigger_flag
9. Count by requested_exposure_above_product_cap_flag
10. Count by requested_exposure_extreme_flag
11. Count by exposure_counteroffer_candidate_flag
12. Count by counteroffer_candidate_flag
13. Count by manual_review_candidate_flag
14. Count by high_utilization_review_trigger_flag, if implemented
15. Count by low_score_review_trigger_flag, if implemented
16. Count by clean_approval_candidate_flag
17. Product × hard_policy_stop_flag summary
18. Product × counteroffer_candidate_flag summary
19. Score band × synthetic risk trigger summary
20. Requested PTI bucket × affordability trigger summary
21. Mixed-signal profile × manual review candidate summary
22. Borderline profile × manual review candidate summary

These are staging diagnostics only.
They should not be interpreted as final decision validation.

================================================================================
11. SECTION 6 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 6 comments should explain:

- why rule flags are separated from final decision hierarchy
- why multiple rule flags can coexist on the same synthetic applicant
- why final prioritization happens later
- why hard simulated policy stop flags are not yet final declines
- why estimated_pd is still only the synthetic estimated-PD proxy input
- why requested PTI uses the original requested structure
- why DTI remains an existing-obligation signal and is not counteroffer-adjustable
- why requested Expected Loss uses requested exposure
- why approved Expected Loss does not exist yet
- why counteroffer flags are only candidate indicators
- why manual review flags are only candidate indicators
- why clean_approval_candidate_flag is diagnostic only
- why high-utilization and low-score review flags, if implemented, are strategy diagnostics rather than production underwriting rules
- why no reason codes are assigned in Section 6
- why no decision outcomes are assigned in Section 6
- why no approved amount, approved payment, approved PTI, or approved Expected Loss is calculated in Section 6

No silent assumptions.
No unexplained magic numbers.
No production-decision language.

================================================================================
12. SECTION 6 DELIVERABLE
================================================================================

Please now provide:

1. The targeted Section 5 requested Expected Loss split patch only.
2. Any required targeted Section 2 / Section 3 parameter and gatekeeper patch for Section 6 rule-control parameters.
3. Section 6 SQL only:
   RULE FLAG CONSTRUCTION LAYER.
4. A short explanation of what Section 6 establishes.
5. A short explanation of what Section 6 intentionally does not build.
6. The recommended next build step after Section 6.

Do not write Sections 7+ yet.
<!-- END_MESSAGE C038-M00088 -->


---

<a id="c038-m00108"></a>

### C038-M00108

**ChatGPT** · 2026-05-06T12:31:38.231242-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00108 -->
The targeted Section 5 patch is appropriate. `product_approved_el_cap` should remain available for later approved-exposure logic, but pre-decision requested Expected Loss tiering should be based on requested-exposure thresholds only. This preserves the Module 1 distinction that Expected Loss is calculated from requested exposure and the synthetic estimated-PD proxy, while Module 2 approved Expected Loss will be introduced later as a separate approved-exposure calculation. fileciteturn4file0

---

# 1. Targeted Section 5 patch — requested Expected Loss low/moderate split

## BEFORE

```sql
(pp.product_approved_el_cap / 2.0)
    AS requested_el_low_moderate_split,
```

## AFTER

```sql
/*
Requested Expected Loss low / moderate diagnostic split.

This split must use the requested-exposure clean approval threshold because Section 5 is
still pre-decision and pre-approved-exposure.

product_approved_el_cap remains carried forward for transparency and for later
approved-exposure logic, but it should not drive requested-exposure tiering.
*/
(pp.product_approve_max_requested_el / 2.0)
    AS requested_el_low_moderate_split,
```

No other Section 5 rewrite is required.

---

# 2. Targeted Section 2 / Section 3 patch for Section 6 rule-control parameters

The suggested Section 6 rule controls are needed. Without them, Section 6 would have to hard-code behavioral review and hard simulated policy stop rules.

The defaults below use the values you proposed. They are treated as simulated strategy controls, not production underwriting policy.

---

## Patch 2.A — Add Section 6 rule-control columns to `tmp_module2_strategy_params`

### BEFORE

```sql
/* Diagnostic segmentation controls */
borderline_threshold_buffer_pct              NUMERIC(12,6),

/* Decision convention controls */
approve_reason_code                          TEXT,
```

### AFTER

```sql
/* Diagnostic segmentation controls */
borderline_threshold_buffer_pct              NUMERIC(12,6),

/* Rule-control parameters for Section 6 trigger construction */
bankruptcy_policy_stop_enabled               BOOLEAN,
major_derogatory_policy_stop_enabled         BOOLEAN,
severe_delinquency_policy_stop_enabled       BOOLEAN,
severe_delinquency_count_threshold           INTEGER,
high_utilization_review_enabled              BOOLEAN,
high_utilization_review_threshold            NUMERIC(12,6),
low_score_review_enabled                     BOOLEAN,
low_score_review_threshold                   INTEGER,

/*
Rule-control interpretation:
    These parameters control simulated trigger flags only.

    They do not assign final decision_outcome.
    They do not create reason codes.
    They do not represent production underwriting policy.

    Section 6 uses them to answer:
        "Which simulated policy conditions are triggered?"

    Later decision hierarchy sections will answer:
        "Which final simulated strategy outcome is assigned?"
*/

/* Decision convention controls */
approve_reason_code                          TEXT,
```

---

## Patch 2.B — Add columns to the strategy parameter insert list

### BEFORE

```sql
borderline_threshold_buffer_pct,

approve_reason_code,
reason_code_required_flag,
```

### AFTER

```sql
borderline_threshold_buffer_pct,

bankruptcy_policy_stop_enabled,
major_derogatory_policy_stop_enabled,
severe_delinquency_policy_stop_enabled,
severe_delinquency_count_threshold,
high_utilization_review_enabled,
high_utilization_review_threshold,
low_score_review_enabled,
low_score_review_threshold,

approve_reason_code,
reason_code_required_flag,
```

---

## Patch 2.C — Add default values to the active strategy row

### BEFORE

```sql
/*
Borderline diagnostic buffer.

0.050000 means Section 5 will tag a profile as threshold-adjacent when a value is within
5% of a relevant strategy threshold.

This is a governed diagnostic parameter, not a production underwriting tolerance and not
an empirically calibrated cutoff.
*/
0.050000,

/* Decision convention controls. */
'APPROVED_AS_REQUESTED',
```

### AFTER

```sql
/*
Borderline diagnostic buffer.

0.050000 means Section 5 will tag a profile as threshold-adjacent when a value is within
5% of a relevant strategy threshold.

This is a governed diagnostic parameter, not a production underwriting tolerance and not
an empirically calibrated cutoff.
*/
0.050000,

/*
Section 6 rule-control defaults.

These values govern simulated trigger construction only.

They are not production underwriting rules.
They are not empirically calibrated policy cutoffs.
They are not final strategy outcomes.
*/
TRUE,       -- bankruptcy_policy_stop_enabled
TRUE,       -- major_derogatory_policy_stop_enabled
TRUE,       -- severe_delinquency_policy_stop_enabled
4,          -- severe_delinquency_count_threshold
TRUE,       -- high_utilization_review_enabled
0.850000,   -- high_utilization_review_threshold
TRUE,       -- low_score_review_enabled
580,        -- low_score_review_threshold

/* Decision convention controls. */
'APPROVED_AS_REQUESTED',
```

---

## Patch 3.A — Add Section 6 rule-control gatekeeper validation

Place this after the `borderline_threshold_buffer_pct` gatekeeper in Section 3.1.

```sql
/*-------------------------------------------------------------------------------------------
Gatekeeper: Section 6 rule-control parameters.

These parameters govern simulated rule trigger flags only. They do not create final strategy
outcomes, reason codes, approved amounts, or approved Expected Loss.

The purpose of this gatekeeper is to prevent hidden or invalid trigger logic from entering
Section 6.

Default interpretation:
    bankruptcy_policy_stop_enabled:
        Allows bankruptcy_flag to create a hard simulated policy stop trigger.

    major_derogatory_policy_stop_enabled:
        Allows major_derogatory_flag to create a hard simulated policy stop trigger.

    severe_delinquency_policy_stop_enabled:
        Allows delinquency_count_12m at or above the configured threshold to create a hard
        simulated policy stop trigger.

    high_utilization_review_enabled:
        Allows high utilization to create a supplemental behavioral review trigger.

    low_score_review_enabled:
        Allows low credit score to create a supplemental behavioral review trigger.

These are strategy-simulation controls, not production underwriting policy.
-------------------------------------------------------------------------------------------*/
IF p.bankruptcy_policy_stop_enabled IS NULL
   OR p.major_derogatory_policy_stop_enabled IS NULL
   OR p.severe_delinquency_policy_stop_enabled IS NULL
   OR p.high_utilization_review_enabled IS NULL
   OR p.low_score_review_enabled IS NULL THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: Section 6 boolean rule-control parameters must not be null.';
END IF;

IF p.severe_delinquency_count_threshold IS NULL
   OR p.severe_delinquency_count_threshold < 0 THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: severe_delinquency_count_threshold must be a non-negative integer.';
END IF;

IF p.high_utilization_review_threshold IS NULL
   OR p.high_utilization_review_threshold < 0
   OR p.high_utilization_review_threshold > 1 THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: high_utilization_review_threshold must be between 0 and 1.';
END IF;

IF p.low_score_review_threshold IS NULL
   OR p.low_score_review_threshold < 300
   OR p.low_score_review_threshold > 850 THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: low_score_review_threshold must be between 300 and 850.';
END IF;
```

---

# 3. Section 6 SQL only — Rule Flag Construction Layer

```sql
/***************************************************************************************************
SECTION 6 — RULE FLAG CONSTRUCTION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Convert the Section 5 diagnostic segmentation layer into transparent, deterministic simulated
    rule-trigger indicators.

    Section 6 answers:

        "Which simulated policy conditions are triggered?"

    Section 6 does NOT answer:

        "What is the final strategy outcome?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_2_strategy_segments.
    2. Preserve all prior source, lineage, strategy metadata, threshold, and segmentation fields.
    3. Attach Section 6 rule-control parameters from tmp_module2_strategy_params.
    4. Create auditable trigger flags across major simulated policy families.
    5. Create diagnostic rule-trigger counts.
    6. Validate that rule flags are complete, internally coherent, and non-final.

WHY RULE FLAGS ARE SEPARATED FROM FINAL DECISION HIERARCHY:
    A synthetic applicant can trigger multiple simulated policy conditions at once.

    Example:
        A row may have elevated requested PTI, high DTI, severe requested Expected Loss, and a
        mixed-signal profile at the same time.

    Section 6 preserves those overlapping signals.

    Later sections will determine:
        - final decision hierarchy;
        - decision_outcome;
        - decision_path;
        - reason-code priority;
        - approved amount;
        - counteroffer amount;
        - approved payment;
        - approved payment-to-income ratio;
        - approved Expected Loss.

SECTION 6 IS NOT A DECISION LAYER:
    This section does not assign:
        decision_outcome
        decision_path
        approval_flag
        decline_flag
        manual_review_flag
        counteroffer_flag
        primary_reason_code
        secondary_reason_code
        tertiary_reason_code
        triggered_reason_code_list
        reason_priority_rank
        approved_amount
        counteroffer_amount
        approved_monthly_payment_proxy
        approved_payment_to_income_ratio
        approved_expected_loss_amount

BOUNDARY LANGUAGE:
    Hard simulated policy stop flags are not final declines.
    Manual review candidate flags are not final manual review outcomes.
    Counteroffer candidate flags are not final counteroffers.
    Clean approval candidate flags are diagnostic only and are not approvals.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field name.

    In Section 6, it is used only as the:
        synthetic estimated-PD proxy input

    Section 6 does not recalculate estimated_pd.
    Section 6 does not create a post-decision risk model.
    Section 6 does not treat estimated_pd as a calibrated production probability of default.

REQUESTED VS APPROVED EXPOSURE:
    Section 6 uses requested exposure and requested-structure affordability only.

    requested_amount:
        Module 1 requested exposure.

    requested_payment_to_income_ratio:
        Module 1 requested-structure PTI, aliased in Module 2 for clarity.

    requested_expected_loss_amount:
        Module 1 requested-exposure Expected Loss, aliased in Module 2 for clarity.

    approved_amount:
        Not calculated in Section 6.

    approved_expected_loss_amount:
        Not calculated in Section 6.

COUNTEROFFER BOUNDARY:
    Counteroffer flags in Section 6 identify candidate conditions only.

    They do not:
        calculate approved_amount;
        calculate counteroffer_amount;
        decide whether the counteroffer is viable;
        assign COUNTEROFFER as decision_outcome.

MANUAL REVIEW BOUNDARY:
    Manual review flags in Section 6 identify candidate conditions only.

    They do not:
        assign MANUAL_REVIEW as decision_outcome;
        create a review disposition;
        calculate any proposed approved amount.

REASON-CODE BOUNDARY:
    Section 6 creates no reason codes.

    Reason-code assignment belongs later, after final decision hierarchy is built, because
    reason priority depends on final strategy outcome and rule hierarchy.

***************************************************************************************************/



/***************************************************************************************************
SECTION 6.1 — CLEAN RESET OF SECTION 6 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;



/***************************************************************************************************
SECTION 6.2 — CREATE RULE FLAG STAGING TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_3_rule_flags

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_2_strategy_segments

OUTPUT:
    All Section 5 fields plus:
        hard simulated policy stop flags
        synthetic estimated-risk trigger flags
        requested affordability trigger flags
        DTI capacity trigger flags
        requested Expected Loss trigger flags
        requested exposure trigger flags
        counteroffer candidate flags
        manual review candidate flags
        supplemental behavioral review trigger flags
        clean approval candidate diagnostic flag
        rule-trigger count fields

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_3_rule_flags
ON COMMIT PRESERVE ROWS
AS
WITH active_params AS (
    SELECT *
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

/*-----------------------------------------------------------------------------------------------
Attach Section 6 rule-control parameters.

These parameters are strategy-simulation controls. They do not create final outcomes.
-----------------------------------------------------------------------------------------------*/
base_with_rule_controls AS (
    SELECT
        s.*,

        p.bankruptcy_policy_stop_enabled,
        p.major_derogatory_policy_stop_enabled,
        p.severe_delinquency_policy_stop_enabled,
        p.severe_delinquency_count_threshold,
        p.high_utilization_review_enabled,
        p.high_utilization_review_threshold,
        p.low_score_review_enabled,
        p.low_score_review_threshold

    FROM tmp_m2_stage_2_strategy_segments s
    CROSS JOIN active_params p
),

/*-----------------------------------------------------------------------------------------------
Product permission flags.

These flags expose whether the product policy configuration allows counteroffer or manual review
routing later.

They are not outcomes.
They are not final decision paths.
-----------------------------------------------------------------------------------------------*/
product_permissions AS (
    SELECT
        b.*,

        (b.counteroffer_allowed_flag IS TRUE) AS counteroffer_allowed_by_product_flag,
        (b.manual_review_allowed_flag IS TRUE) AS manual_review_allowed_by_product_flag

    FROM base_with_rule_controls b
),

/*-----------------------------------------------------------------------------------------------
Hard simulated policy stop flags.

These flags identify severe simulated policy stop conditions.

Important:
    They do not assign DECLINE.
    They do not create policy stop reason codes.
    They only preserve the fact that a severe simulated condition was triggered.

Final prioritization happens later.
-----------------------------------------------------------------------------------------------*/
hard_policy_flags AS (
    SELECT
        pp.*,

        (
            pp.bankruptcy_policy_stop_enabled IS TRUE
            AND pp.bankruptcy_flag IS TRUE
        ) AS bankruptcy_policy_stop_flag,

        (
            pp.major_derogatory_policy_stop_enabled IS TRUE
            AND pp.major_derogatory_flag IS TRUE
        ) AS major_derogatory_policy_stop_flag,

        (
            pp.severe_delinquency_policy_stop_enabled IS TRUE
            AND pp.delinquency_count_12m >= pp.severe_delinquency_count_threshold
        ) AS severe_delinquency_policy_stop_flag

    FROM product_permissions pp
),

hard_policy_counted AS (
    SELECT
        h.*,

        (
            h.bankruptcy_policy_stop_flag::INT
            + h.major_derogatory_policy_stop_flag::INT
            + h.severe_delinquency_policy_stop_flag::INT
        ) AS hard_policy_stop_count,

        (
            h.bankruptcy_policy_stop_flag
            OR h.major_derogatory_policy_stop_flag
            OR h.severe_delinquency_policy_stop_flag
        ) AS hard_policy_stop_flag

    FROM hard_policy_flags h
),

/*-----------------------------------------------------------------------------------------------
Synthetic estimated-risk flags.

Input:
    estimated_pd, interpreted as the synthetic estimated-PD proxy.

Equality convention:
    Clean band:
        estimated_pd <= approve_max_estimated_pd_proxy

    Counteroffer risk band:
        estimated_pd > approve_max_estimated_pd_proxy
        AND estimated_pd <= counteroffer_max_estimated_pd_proxy

    Review band:
        estimated_pd > counteroffer_max_estimated_pd_proxy
        AND estimated_pd < decline_min_estimated_pd_proxy

    Decline trigger:
        estimated_pd >= decline_min_estimated_pd_proxy

Important:
    synthetic_risk_decline_trigger_flag is not a final DECLINE outcome.
    It is a trigger that later decision hierarchy may prioritize.
-----------------------------------------------------------------------------------------------*/
synthetic_risk_flags AS (
    SELECT
        hpc.*,

        (
            hpc.estimated_pd <= hpc.approve_max_estimated_pd_proxy
        ) AS synthetic_risk_clean_approval_band_flag,

        (
            hpc.estimated_pd > hpc.approve_max_estimated_pd_proxy
            AND hpc.estimated_pd <= hpc.counteroffer_max_estimated_pd_proxy
        ) AS synthetic_risk_counteroffer_band_flag,

        (
            hpc.estimated_pd > hpc.counteroffer_max_estimated_pd_proxy
            AND hpc.estimated_pd < hpc.decline_min_estimated_pd_proxy
        ) AS synthetic_risk_review_band_flag,

        (
            hpc.estimated_pd >= hpc.decline_min_estimated_pd_proxy
        ) AS synthetic_risk_decline_trigger_flag

    FROM hard_policy_counted hpc
),

synthetic_risk_counted AS (
    SELECT
        r.*,

        (
            r.synthetic_risk_counteroffer_band_flag::INT
            + r.synthetic_risk_review_band_flag::INT
            + r.synthetic_risk_decline_trigger_flag::INT
        ) AS synthetic_risk_trigger_count

    FROM synthetic_risk_flags r
),

/*-----------------------------------------------------------------------------------------------
Requested affordability, DTI, requested Expected Loss, and exposure flags.

Requested affordability:
    Uses requested_payment_to_income_ratio from Module 1 requested structure.
    approved_payment_to_income_ratio does not exist yet.

DTI:
    Uses debt_to_income_ratio as an existing-obligation capacity signal.
    DTI is not directly fixed by a counteroffer in Module 2 v1.0.

Requested Expected Loss:
    Uses requested_expected_loss_amount, the Module 2 alias for Module 1 expected_loss_amount.
    approved_expected_loss_amount does not exist yet.

Exposure:
    Uses requested_amount and Section 5 requested_exposure_tier.
    approved_amount and counteroffer_amount do not exist yet.
-----------------------------------------------------------------------------------------------*/
core_policy_condition_flags AS (
    SELECT
        rc.*,

        /* Requested PTI flags */
        (
            rc.requested_payment_to_income_ratio <= rc.product_approve_max_pti
        ) AS requested_pti_clean_band_flag,

        (
            rc.requested_payment_to_income_ratio > rc.product_approve_max_pti
        ) AS requested_pti_counteroffer_candidate_flag,

        (
            rc.requested_payment_to_income_ratio > rc.product_approve_max_pti
            AND rc.requested_payment_to_income_ratio < rc.product_decline_min_pti
        ) AS requested_pti_review_trigger_flag,

        (
            rc.requested_payment_to_income_ratio >= rc.product_decline_min_pti
        ) AS requested_pti_decline_trigger_flag,


        /* DTI capacity flags */
        (
            rc.debt_to_income_ratio <= rc.approve_max_dti
        ) AS dti_clean_band_flag,

        (
            rc.debt_to_income_ratio > rc.approve_max_dti
            AND rc.debt_to_income_ratio < rc.decline_min_dti
        ) AS dti_review_trigger_flag,

        (
            rc.debt_to_income_ratio >= rc.decline_min_dti
        ) AS dti_decline_trigger_flag,


        /* Requested Expected Loss flags */
        (
            rc.requested_expected_loss_amount <= rc.product_approve_max_requested_el
        ) AS requested_el_clean_band_flag,

        (
            rc.requested_expected_loss_amount > rc.product_approve_max_requested_el
        ) AS requested_el_counteroffer_candidate_flag,

        (
            rc.requested_expected_loss_amount > rc.product_review_max_requested_el
            AND rc.requested_expected_loss_amount < rc.product_decline_min_requested_el
        ) AS requested_el_review_trigger_flag,

        (
            rc.requested_expected_loss_amount >= rc.product_decline_min_requested_el
        ) AS requested_el_decline_trigger_flag,


        /* Requested exposure flags */
        (
            rc.requested_exposure_tier = 'BELOW_PRODUCT_MINIMUM'
        ) AS requested_exposure_below_product_minimum_flag,

        (
            rc.requested_exposure_tier = 'WITHIN_PRODUCT_LIMITS'
        ) AS requested_exposure_within_product_limit_flag,

        (
            rc.requested_exposure_tier = 'ABOVE_PRODUCT_APPROVAL_CAP'
        ) AS requested_exposure_above_product_cap_flag,

        (
            rc.requested_exposure_tier = 'EXTREME_REQUESTED_EXPOSURE'
        ) AS requested_exposure_extreme_flag,

        (
            rc.requested_exposure_tier = 'ABOVE_PRODUCT_APPROVAL_CAP'
            AND rc.counteroffer_allowed_by_product_flag
        ) AS exposure_counteroffer_candidate_flag,

        (
            rc.requested_exposure_tier IN (
                'BELOW_PRODUCT_MINIMUM',
                'EXTREME_REQUESTED_EXPOSURE'
            )
        ) AS exposure_policy_stop_candidate_flag

    FROM synthetic_risk_counted rc
),

core_policy_condition_counted AS (
    SELECT
        c.*,

        /*
        Count interpretation:
            These are diagnostic trigger counts, not final decision counts.

            Some flags can coexist by design.
        */
        (
            c.requested_pti_counteroffer_candidate_flag::INT
            + c.requested_pti_review_trigger_flag::INT
            + c.requested_pti_decline_trigger_flag::INT
        ) AS affordability_trigger_count,

        (
            c.dti_review_trigger_flag::INT
            + c.dti_decline_trigger_flag::INT
        ) AS dti_trigger_count,

        (
            c.requested_el_counteroffer_candidate_flag::INT
            + c.requested_el_review_trigger_flag::INT
            + c.requested_el_decline_trigger_flag::INT
        ) AS requested_el_trigger_count,

        (
            c.requested_exposure_below_product_minimum_flag::INT
            + c.requested_exposure_above_product_cap_flag::INT
            + c.requested_exposure_extreme_flag::INT
        ) AS exposure_trigger_count

    FROM core_policy_condition_flags c
),

/*-----------------------------------------------------------------------------------------------
Supplemental behavioral review flags.

These are strategy diagnostics only.

high_utilization_review_trigger_flag:
    Uses utilization_rate and high_utilization_review_threshold.

low_score_review_trigger_flag:
    Uses credit_score and low_score_review_threshold.

Default low_score_review_threshold:
    580

Equality convention:
    credit_score < low_score_review_threshold

    With the default value of 580, this aligns primarily to the deep-subprime score range
    while preserving the threshold as a governed strategy parameter.

These flags do not assign MANUAL_REVIEW.
They do not create reason codes.
-----------------------------------------------------------------------------------------------*/
supplemental_behavioral_flags AS (
    SELECT
        cpc.*,

        (
            cpc.high_utilization_review_enabled IS TRUE
            AND cpc.utilization_rate >= cpc.high_utilization_review_threshold
        ) AS high_utilization_review_trigger_flag,

        (
            cpc.low_score_review_enabled IS TRUE
            AND cpc.credit_score < cpc.low_score_review_threshold
        ) AS low_score_review_trigger_flag

    FROM core_policy_condition_counted cpc
),

supplemental_behavioral_counted AS (
    SELECT
        sb.*,

        (
            sb.high_utilization_review_trigger_flag::INT
            + sb.low_score_review_trigger_flag::INT
        ) AS supplemental_behavioral_review_trigger_count,

        (
            sb.high_utilization_review_trigger_flag
            OR sb.low_score_review_trigger_flag
        ) AS supplemental_behavioral_review_trigger_flag

    FROM supplemental_behavioral_flags sb
),

/*-----------------------------------------------------------------------------------------------
Counteroffer candidate flags.

These flags identify conditions that may later support a COUNTEROFFER outcome.

Important:
    Section 6 does not calculate approved_amount.
    Section 6 does not calculate counteroffer_amount.
    Section 6 does not calculate approved_payment_to_income_ratio.
    Section 6 does not calculate approved_expected_loss_amount.
    Section 6 does not decide that a counteroffer is viable.

counteroffer_risk_band_eligible_flag:
    TRUE when the synthetic estimated-PD proxy is within the configured counteroffer-eligible
    risk range and no hard simulated policy stop trigger is present.

A low-risk applicant with high requested PTI may still be counteroffer-eligible because the
risk gate is a ceiling, not a requirement to be in the elevated-risk band.
-----------------------------------------------------------------------------------------------*/
counteroffer_risk_eligibility AS (
    SELECT
        sbc.*,

        (
            sbc.counteroffer_allowed_by_product_flag
            AND sbc.hard_policy_stop_flag IS FALSE
            AND sbc.estimated_pd <= sbc.counteroffer_max_estimated_pd_proxy
        ) AS counteroffer_risk_band_eligible_flag

    FROM supplemental_behavioral_counted sbc
),

counteroffer_candidate_inputs AS (
    SELECT
        ce.*,

        (
            ce.counteroffer_allowed_by_product_flag
            AND ce.counteroffer_risk_band_eligible_flag
            AND ce.requested_pti_counteroffer_candidate_flag
        ) AS counteroffer_affordability_candidate_flag,

        (
            ce.counteroffer_allowed_by_product_flag
            AND ce.counteroffer_risk_band_eligible_flag
            AND ce.exposure_counteroffer_candidate_flag
        ) AS counteroffer_exposure_candidate_flag,

        (
            ce.counteroffer_allowed_by_product_flag
            AND ce.counteroffer_risk_band_eligible_flag
            AND ce.requested_el_counteroffer_candidate_flag
        ) AS counteroffer_expected_loss_candidate_flag

    FROM counteroffer_risk_eligibility ce
),

counteroffer_candidate_counted AS (
    SELECT
        cci.*,

        (
            cci.counteroffer_affordability_candidate_flag::INT
            + cci.counteroffer_exposure_candidate_flag::INT
            + cci.counteroffer_expected_loss_candidate_flag::INT
        ) AS counteroffer_candidate_trigger_count,

        (
            cci.counteroffer_affordability_candidate_flag
            OR cci.counteroffer_exposure_candidate_flag
            OR cci.counteroffer_expected_loss_candidate_flag
        ) AS counteroffer_candidate_flag

    FROM counteroffer_candidate_inputs cci
),

/*-----------------------------------------------------------------------------------------------
Manual review candidate flags.

These flags identify conditions that may later support a MANUAL_REVIEW outcome.

Important:
    Section 6 does not assign MANUAL_REVIEW.
    Section 6 does not calculate a review amount.
    Section 6 does not create review reason codes.

manual_review_candidate_flag:
    TRUE when one or more review-style trigger conditions are active, manual review is allowed
    by product, and no hard simulated policy stop trigger is present.
-----------------------------------------------------------------------------------------------*/
manual_review_candidate_inputs AS (
    SELECT
        ccc.*,

        (
            ccc.manual_review_allowed_by_product_flag
            AND ccc.hard_policy_stop_flag IS FALSE
            AND ccc.synthetic_risk_review_band_flag
        ) AS manual_review_risk_trigger_flag,

        (
            ccc.manual_review_allowed_by_product_flag
            AND ccc.hard_policy_stop_flag IS FALSE
            AND ccc.requested_pti_review_trigger_flag
        ) AS manual_review_affordability_trigger_flag,

        (
            ccc.manual_review_allowed_by_product_flag
            AND ccc.hard_policy_stop_flag IS FALSE
            AND ccc.dti_review_trigger_flag
        ) AS manual_review_dti_trigger_flag,

        (
            ccc.manual_review_allowed_by_product_flag
            AND ccc.hard_policy_stop_flag IS FALSE
            AND ccc.requested_el_review_trigger_flag
        ) AS manual_review_expected_loss_trigger_flag,

        (
            ccc.manual_review_allowed_by_product_flag
            AND ccc.hard_policy_stop_flag IS FALSE
            AND ccc.mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
        ) AS manual_review_mixed_signal_trigger_flag,

        (
            ccc.manual_review_allowed_by_product_flag
            AND ccc.hard_policy_stop_flag IS FALSE
            AND ccc.borderline_profile_flag IS TRUE
        ) AS manual_review_borderline_trigger_flag

    FROM counteroffer_candidate_counted ccc
),

manual_review_candidate_counted AS (
    SELECT
        mri.*,

        (
            mri.manual_review_risk_trigger_flag::INT
            + mri.manual_review_affordability_trigger_flag::INT
            + mri.manual_review_dti_trigger_flag::INT
            + mri.manual_review_expected_loss_trigger_flag::INT
            + mri.manual_review_mixed_signal_trigger_flag::INT
            + mri.manual_review_borderline_trigger_flag::INT
            + CASE
                WHEN mri.manual_review_allowed_by_product_flag
                 AND mri.hard_policy_stop_flag IS FALSE
                    THEN mri.supplemental_behavioral_review_trigger_count
                ELSE 0
              END
        ) AS manual_review_candidate_trigger_count,

        (
            mri.manual_review_allowed_by_product_flag
            AND mri.hard_policy_stop_flag IS FALSE
            AND (
                mri.manual_review_risk_trigger_flag
                OR mri.manual_review_affordability_trigger_flag
                OR mri.manual_review_dti_trigger_flag
                OR mri.manual_review_expected_loss_trigger_flag
                OR mri.manual_review_mixed_signal_trigger_flag
                OR mri.manual_review_borderline_trigger_flag
                OR mri.supplemental_behavioral_review_trigger_flag
            )
        ) AS manual_review_candidate_flag

    FROM manual_review_candidate_inputs mri
),

/*-----------------------------------------------------------------------------------------------
Clean approval candidate diagnostic flag.

This is diagnostic only.

clean_approval_candidate_flag identifies rows that appear clean across major simulated trigger
families before final decision hierarchy is applied.

It does not assign APPROVE.

The flag is deliberately conservative. It cannot be TRUE when material trigger families are active.
-----------------------------------------------------------------------------------------------*/
clean_approval_diagnostic AS (
    SELECT
        mrc.*,

        (
            mrc.hard_policy_stop_flag IS FALSE
            AND mrc.synthetic_risk_clean_approval_band_flag IS TRUE
            AND mrc.requested_pti_clean_band_flag IS TRUE
            AND mrc.dti_clean_band_flag IS TRUE
            AND mrc.requested_el_clean_band_flag IS TRUE
            AND mrc.requested_exposure_within_product_limit_flag IS TRUE
            AND mrc.synthetic_risk_decline_trigger_flag IS FALSE
            AND mrc.requested_pti_decline_trigger_flag IS FALSE
            AND mrc.dti_decline_trigger_flag IS FALSE
            AND mrc.requested_el_decline_trigger_flag IS FALSE
            AND mrc.requested_exposure_extreme_flag IS FALSE
            AND mrc.counteroffer_candidate_flag IS FALSE
            AND mrc.manual_review_candidate_flag IS FALSE
            AND mrc.supplemental_behavioral_review_trigger_flag IS FALSE
        ) AS clean_approval_candidate_flag

    FROM manual_review_candidate_counted mrc
),

/*-----------------------------------------------------------------------------------------------
Total rule-trigger count.

Design choice:
    total_rule_trigger_count sums base trigger signals and selected diagnostic review signals.

    It intentionally does not add counteroffer_candidate_trigger_count and
    manual_review_candidate_trigger_count directly, because those are composite candidate counts
    derived from some of the same underlying conditions.

    This avoids overstating the total trigger burden through double-counting.
-----------------------------------------------------------------------------------------------*/
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

SELECT *
FROM final_rule_flags;



/***************************************************************************************************
SECTION 6.3 — LOCAL FAIL-FAST CHECKS FOR RULE FLAG STAGING
****************************************************************************************************

PURPOSE:
    Validate the Section 6 rule-flag layer before final decision hierarchy is created.

IMPORTANT:
    These are local staging gatekeepers only.

    They are not full Module 2 QA.
    They are not final decision validation.
    They are not reason-code validation.
    They are not approved-exposure validation.

***************************************************************************************************/

DO $$
DECLARE
    v_stage2_count BIGINT;
    v_stage3_count BIGINT;
    v_stage3_distinct_app_count BIGINT;

    v_duplicate_application_count BIGINT;
    v_null_rule_flag_count BIGINT;
    v_bad_count_field_count BIGINT;
    v_clean_conflict_count BIGINT;
    v_counteroffer_permission_violation_count BIGINT;
    v_manual_review_permission_violation_count BIGINT;

    v_synthetic_risk_decline_mismatch_count BIGINT;
    v_pti_decline_mismatch_count BIGINT;
    v_dti_decline_mismatch_count BIGINT;
    v_requested_el_decline_mismatch_count BIGINT;

    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 5 to Section 6.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage2_count
    FROM tmp_m2_stage_2_strategy_segments;

    SELECT COUNT(*)
    INTO v_stage3_count
    FROM tmp_m2_stage_3_rule_flags;

    IF v_stage3_count <> v_stage2_count THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: row count changed from Section 5 to Section 6. Stage 2 rows: %, Stage 3 rows: %.',
            v_stage2_count,
            v_stage3_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage3_distinct_app_count
    FROM tmp_m2_stage_3_rule_flags;

    IF v_stage3_distinct_app_count <> v_stage3_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_3_rule_flags
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 6 failure: application_id uniqueness was not preserved. Stage 3 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage3_count,
            v_stage3_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: all required rule flags must be non-null.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_rule_flag_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE bankruptcy_policy_stop_flag IS NULL
       OR major_derogatory_policy_stop_flag IS NULL
       OR severe_delinquency_policy_stop_flag IS NULL
       OR hard_policy_stop_flag IS NULL

       OR synthetic_risk_clean_approval_band_flag IS NULL
       OR synthetic_risk_counteroffer_band_flag IS NULL
       OR synthetic_risk_review_band_flag IS NULL
       OR synthetic_risk_decline_trigger_flag IS NULL

       OR requested_pti_clean_band_flag IS NULL
       OR requested_pti_counteroffer_candidate_flag IS NULL
       OR requested_pti_review_trigger_flag IS NULL
       OR requested_pti_decline_trigger_flag IS NULL

       OR dti_clean_band_flag IS NULL
       OR dti_review_trigger_flag IS NULL
       OR dti_decline_trigger_flag IS NULL

       OR requested_el_clean_band_flag IS NULL
       OR requested_el_counteroffer_candidate_flag IS NULL
       OR requested_el_review_trigger_flag IS NULL
       OR requested_el_decline_trigger_flag IS NULL

       OR requested_exposure_below_product_minimum_flag IS NULL
       OR requested_exposure_within_product_limit_flag IS NULL
       OR requested_exposure_above_product_cap_flag IS NULL
       OR requested_exposure_extreme_flag IS NULL
       OR exposure_counteroffer_candidate_flag IS NULL
       OR exposure_policy_stop_candidate_flag IS NULL

       OR counteroffer_allowed_by_product_flag IS NULL
       OR counteroffer_risk_band_eligible_flag IS NULL
       OR counteroffer_affordability_candidate_flag IS NULL
       OR counteroffer_exposure_candidate_flag IS NULL
       OR counteroffer_expected_loss_candidate_flag IS NULL
       OR counteroffer_candidate_flag IS NULL

       OR manual_review_allowed_by_product_flag IS NULL
       OR manual_review_risk_trigger_flag IS NULL
       OR manual_review_affordability_trigger_flag IS NULL
       OR manual_review_dti_trigger_flag IS NULL
       OR manual_review_expected_loss_trigger_flag IS NULL
       OR manual_review_mixed_signal_trigger_flag IS NULL
       OR manual_review_borderline_trigger_flag IS NULL
       OR manual_review_candidate_flag IS NULL

       OR high_utilization_review_trigger_flag IS NULL
       OR low_score_review_trigger_flag IS NULL
       OR supplemental_behavioral_review_trigger_flag IS NULL

       OR clean_approval_candidate_flag IS NULL;

    IF v_null_rule_flag_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have null required rule flags.',
            v_null_rule_flag_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: all rule count fields must be populated and non-negative.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_bad_count_field_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE hard_policy_stop_count IS NULL
       OR synthetic_risk_trigger_count IS NULL
       OR affordability_trigger_count IS NULL
       OR dti_trigger_count IS NULL
       OR requested_el_trigger_count IS NULL
       OR exposure_trigger_count IS NULL
       OR counteroffer_candidate_trigger_count IS NULL
       OR manual_review_candidate_trigger_count IS NULL
       OR supplemental_behavioral_review_trigger_count IS NULL
       OR total_rule_trigger_count IS NULL
       OR hard_policy_stop_count < 0
       OR synthetic_risk_trigger_count < 0
       OR affordability_trigger_count < 0
       OR dti_trigger_count < 0
       OR requested_el_trigger_count < 0
       OR exposure_trigger_count < 0
       OR counteroffer_candidate_trigger_count < 0
       OR manual_review_candidate_trigger_count < 0
       OR supplemental_behavioral_review_trigger_count < 0
       OR total_rule_trigger_count < 0;

    IF v_bad_count_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have null or negative rule count fields.',
            v_bad_count_field_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: clean approval candidate cannot conflict with material trigger families.

    This does not assign APPROVE. It only ensures the diagnostic clean candidate flag remains
    internally coherent.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_clean_conflict_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE clean_approval_candidate_flag IS TRUE
      AND (
            hard_policy_stop_flag IS TRUE
         OR synthetic_risk_decline_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
         OR dti_decline_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR counteroffer_candidate_flag IS TRUE
         OR manual_review_candidate_flag IS TRUE
      );

    IF v_clean_conflict_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have clean_approval_candidate_flag = TRUE while material trigger families are active.',
            v_clean_conflict_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: counteroffer candidate cannot be true when product disallows counteroffers.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_permission_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE counteroffer_candidate_flag IS TRUE
      AND counteroffer_allowed_by_product_flag IS FALSE;

    IF v_counteroffer_permission_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have counteroffer_candidate_flag = TRUE when counteroffer is not allowed by product.',
            v_counteroffer_permission_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: manual review candidate cannot be true when product disallows manual review.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_permission_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE manual_review_candidate_flag IS TRUE
      AND manual_review_allowed_by_product_flag IS FALSE;

    IF v_manual_review_permission_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have manual_review_candidate_flag = TRUE when manual review is not allowed by product.',
            v_manual_review_permission_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: threshold equality convention checks.

    These checks confirm that key trigger flags match the locked threshold convention.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE synthetic_risk_decline_trigger_flag
          IS DISTINCT FROM (estimated_pd >= decline_min_estimated_pd_proxy);

    IF v_synthetic_risk_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) violate synthetic risk decline trigger equality convention.',
            v_synthetic_risk_decline_mismatch_count;
    END IF;

    SELECT COUNT(*)
    INTO v_pti_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE requested_pti_decline_trigger_flag
          IS DISTINCT FROM (requested_payment_to_income_ratio >= product_decline_min_pti);

    IF v_pti_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) violate requested PTI decline trigger equality convention.',
            v_pti_decline_mismatch_count;
    END IF;

    SELECT COUNT(*)
    INTO v_dti_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE dti_decline_trigger_flag
          IS DISTINCT FROM (debt_to_income_ratio >= decline_min_dti);

    IF v_dti_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) violate DTI decline trigger equality convention.',
            v_dti_decline_mismatch_count;
    END IF;

    SELECT COUNT(*)
    INTO v_requested_el_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE requested_el_decline_trigger_flag
          IS DISTINCT FROM (requested_expected_loss_amount >= product_decline_min_requested_el);

    IF v_requested_el_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) violate requested Expected Loss decline trigger equality convention.',
            v_requested_el_decline_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: forbidden final-output fields must not exist yet.

    Section 6 is not allowed to create final decisions, reason codes, approved exposure, approved
    payment, approved PTI, or approved Expected Loss.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_3_rule_flags'::REGCLASS
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
            'Module 2 Section 6 failure: forbidden final-output field(s) were created before the decision hierarchy / approved exposure sections.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 6.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 6 rule flag layer.

IMPORTANT:
    These are not final strategy validation queries.
    They should not be interpreted as approval, decline, manual review, or counteroffer rates.

    They are staging diagnostics only.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
6.4.1 Row count and application identity count.

Expected:
    staged_row_count = distinct_application_id_count
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS staged_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_3_rule_flags;


/*-----------------------------------------------------------------------------------------------
6.4.2 Count by hard_policy_stop_flag.

Interpretation:
    This is not a decline rate. It is a simulated hard policy stop trigger diagnostic.
-----------------------------------------------------------------------------------------------*/
SELECT
    hard_policy_stop_flag,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS pct_of_stage
FROM tmp_m2_stage_3_rule_flags
GROUP BY hard_policy_stop_flag
ORDER BY hard_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.3 Count by bankruptcy_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    bankruptcy_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY bankruptcy_policy_stop_flag
ORDER BY bankruptcy_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.4 Count by major_derogatory_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    major_derogatory_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY major_derogatory_policy_stop_flag
ORDER BY major_derogatory_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.5 Count by severe_delinquency_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    severe_delinquency_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY severe_delinquency_policy_stop_flag
ORDER BY severe_delinquency_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.6 Count by synthetic_risk_decline_trigger_flag.

Interpretation:
    estimated_pd is the Module 1 SQL field and is interpreted as the synthetic estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    synthetic_risk_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY synthetic_risk_decline_trigger_flag
ORDER BY synthetic_risk_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.7 Count by requested_pti_decline_trigger_flag.

Interpretation:
    requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_pti_decline_trigger_flag
ORDER BY requested_pti_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.8 Count by dti_decline_trigger_flag.

Interpretation:
    DTI is an existing-obligation capacity signal and is not directly counteroffer-adjustable in
    Module 2 v1.0.
-----------------------------------------------------------------------------------------------*/
SELECT
    dti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY dti_decline_trigger_flag
ORDER BY dti_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.9 Count by requested_el_decline_trigger_flag.

Interpretation:
    requested_expected_loss_amount uses requested exposure.
    approved_expected_loss_amount does not exist yet.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_el_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_el_decline_trigger_flag
ORDER BY requested_el_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.10 Count by requested_exposure_above_product_cap_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_above_product_cap_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_exposure_above_product_cap_flag
ORDER BY requested_exposure_above_product_cap_flag;


/*-----------------------------------------------------------------------------------------------
6.4.11 Count by requested_exposure_extreme_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_extreme_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_exposure_extreme_flag
ORDER BY requested_exposure_extreme_flag;


/*-----------------------------------------------------------------------------------------------
6.4.12 Count by exposure_counteroffer_candidate_flag.

Interpretation:
    This is not a final counteroffer rate. It only identifies above-cap exposure that may later be
    considered for reduced exposure treatment.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_counteroffer_candidate_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY exposure_counteroffer_candidate_flag
ORDER BY exposure_counteroffer_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.13 Count by counteroffer_candidate_flag.

Interpretation:
    This is not a COUNTEROFFER decision outcome. Final counteroffer feasibility and amount logic are
    not built yet.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY counteroffer_candidate_flag
ORDER BY counteroffer_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.14 Count by manual_review_candidate_flag.

Interpretation:
    This is not a MANUAL_REVIEW decision outcome. Final manual review routing is not built yet.
-----------------------------------------------------------------------------------------------*/
SELECT
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY manual_review_candidate_flag
ORDER BY manual_review_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.15 Count by high_utilization_review_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    high_utilization_review_trigger_flag,
    COUNT(*) AS row_count,
    AVG(utilization_rate) AS avg_utilization_rate
FROM tmp_m2_stage_3_rule_flags
GROUP BY high_utilization_review_trigger_flag
ORDER BY high_utilization_review_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.16 Count by low_score_review_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    low_score_review_trigger_flag,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score
FROM tmp_m2_stage_3_rule_flags
GROUP BY low_score_review_trigger_flag
ORDER BY low_score_review_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.17 Count by clean_approval_candidate_flag.

Interpretation:
    This is not an APPROVE decision outcome. It is a diagnostic flag for rows with no major trigger
    families active.
-----------------------------------------------------------------------------------------------*/
SELECT
    clean_approval_candidate_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY clean_approval_candidate_flag
ORDER BY clean_approval_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.18 Product × hard_policy_stop_flag summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    hard_policy_stop_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    product_type_policy_key,
    hard_policy_stop_flag
ORDER BY
    product_type_policy_key,
    hard_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.19 Product × counteroffer_candidate_flag summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    product_type_policy_key,
    counteroffer_candidate_flag
ORDER BY
    product_type_policy_key,
    counteroffer_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.20 Score band × synthetic risk trigger summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    score_band_policy_key,
    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    synthetic_risk_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.21 Requested PTI bucket × affordability trigger summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    requested_pti_clean_band_flag,
    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    requested_pti_bucket,
    requested_pti_clean_band_flag,
    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
6.4.22 Mixed-signal profile × manual review candidate summary.

Interpretation:
    Mixed-signal profiles are diagnostic only. They are not automatic manual review outcomes.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    mixed_signal_profile_type,
    manual_review_candidate_flag
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
    manual_review_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.23 Borderline profile × manual review candidate summary.

Interpretation:
    borderline_profile_flag uses governed threshold proximity logic. It does not assign
    MANUAL_REVIEW in Section 6.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    borderline_profile_flag,
    manual_review_candidate_flag
ORDER BY
    borderline_profile_flag,
    manual_review_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.24 Rule trigger count profile.

Purpose:
    Confirms count fields are populated and provides a quick view of trigger burden before final
    decision hierarchy.
-----------------------------------------------------------------------------------------------*/
SELECT
    MIN(hard_policy_stop_count) AS min_hard_policy_stop_count,
    AVG(hard_policy_stop_count) AS avg_hard_policy_stop_count,
    MAX(hard_policy_stop_count) AS max_hard_policy_stop_count,

    MIN(synthetic_risk_trigger_count) AS min_synthetic_risk_trigger_count,
    AVG(synthetic_risk_trigger_count) AS avg_synthetic_risk_trigger_count,
    MAX(synthetic_risk_trigger_count) AS max_synthetic_risk_trigger_count,

    MIN(affordability_trigger_count) AS min_affordability_trigger_count,
    AVG(affordability_trigger_count) AS avg_affordability_trigger_count,
    MAX(affordability_trigger_count) AS max_affordability_trigger_count,

    MIN(total_rule_trigger_count) AS min_total_rule_trigger_count,
    AVG(total_rule_trigger_count) AS avg_total_rule_trigger_count,
    MAX(total_rule_trigger_count) AS max_total_rule_trigger_count
FROM tmp_m2_stage_3_rule_flags;


/***************************************************************************************************
END OF SECTION 6 — RULE FLAG CONSTRUCTION LAYER

If execution reaches this point:
    1. tmp_m2_stage_3_rule_flags exists.
    2. All Section 5 fields have been preserved.
    3. Module 1 lineage remains attached.
    4. Module 2 strategy metadata remains attached.
    5. estimated_pd remains preserved as the finalized Module 1 SQL field and is interpreted as the
       synthetic estimated-PD proxy.
    6. Requested-structure economics remain preserved.
    7. Hard simulated policy stop flags are populated.
    8. Synthetic estimated-risk trigger flags are populated.
    9. Requested PTI trigger flags are populated.
    10. DTI capacity trigger flags are populated.
    11. Requested Expected Loss trigger flags are populated.
    12. Requested exposure trigger flags are populated.
    13. Counteroffer candidate flags are populated.
    14. Manual review candidate flags are populated.
    15. Supplemental behavioral review trigger flags are populated.
    16. clean_approval_candidate_flag is populated as a diagnostic only.
    17. Rule count fields are populated and non-negative.

No final decision outcomes have been generated.
No final decision flags have been created.
No reason codes have been assigned.
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

# 4. What Section 6 establishes

Section 6 creates:

```text
tmp_m2_stage_3_rule_flags
```

It converts Section 5’s diagnostic segmentation layer into auditable trigger indicators across:

```text
hard simulated policy stops
synthetic estimated-risk triggers
requested affordability triggers
DTI capacity triggers
requested Expected Loss triggers
requested exposure triggers
counteroffer candidate conditions
manual review candidate conditions
supplemental behavioral review triggers
clean approval candidate diagnostics
```

It also adds rule-trigger count fields, while preserving the principle that multiple triggers can coexist on the same synthetic applicant.

---

# 5. What Section 6 intentionally does not build

Section 6 does not assign:

```text
decision_outcome
decision_path
approval_flag
decline_flag
manual_review_flag
counteroffer_flag
primary_reason_code
secondary_reason_code
tertiary_reason_code
triggered_reason_code_list
approved_amount
counteroffer_amount
approved_monthly_payment_proxy
approved_payment_to_income_ratio
approved_expected_loss_amount
```

It identifies triggered simulated conditions only. Final prioritization belongs to the decision hierarchy section.

---

# 6. Recommended next build step

Next should be:

```text
Section 7 — Decision Hierarchy and Preliminary Outcome Assignment
```

That section should convert overlapping Section 6 trigger flags into exactly one primary `decision_outcome` per application:

```text
APPROVE
COUNTEROFFER
MANUAL_REVIEW
DECLINE
```

It should also create `decision_path`, but still defer reason-code priority assignment and approved exposure calculation unless we explicitly decide to combine them.
<!-- END_MESSAGE C038-M00108 -->


---

<a id="c038-m00109"></a>

### C038-M00109

**Andrew** · 2026-05-06T12:56:54.302000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00109 -->
This is strong. I agree with the Section 5 patch, the governed Section 6 rule-control parameter patch, and the Section 6 Rule Flag Construction Layer.

Section 6 should be treated as provisionally accepted after one targeted hardening patch.

Section 6 correctly:
- converts Section 5 segmentation into transparent rule-trigger flags
- preserves Module 1 estimated_pd as the synthetic estimated-PD proxy input
- separates hard simulated policy stop triggers from later decision hierarchy
- creates synthetic risk, affordability, DTI, requested Expected Loss, exposure, counteroffer, manual review, supplemental behavior, and clean-approval diagnostic flags
- creates rule-trigger count fields
- avoids final decision outcomes
- avoids reason codes
- avoids approved amount logic
- avoids approved payment / approved PTI logic
- avoids approved Expected Loss logic
- avoids final output and archive logic

Before moving forward, please make the targeted Section 6 hardening patch below, then build Section 7 only.

Do not rewrite Sections 0–6 in full unless necessary.

================================================================================
1. TARGETED SECTION 6 HARDENING PATCH
================================================================================

Please add a small local gatekeeper patch to Section 6 to confirm that certain true banding families are mutually exclusive and complete.

This is a local Section 6 quality-control patch only.

--------------------------------------------------------------------------------
1A. Synthetic estimated-risk band coverage
--------------------------------------------------------------------------------

Exactly one of the following should be true for every row:

- synthetic_risk_clean_approval_band_flag
- synthetic_risk_counteroffer_band_flag
- synthetic_risk_review_band_flag
- synthetic_risk_decline_trigger_flag

Add either a diagnostic count field or local gatekeeper logic such as:

synthetic_risk_band_flag_count

The local gatekeeper should fail if synthetic_risk_band_flag_count <> 1.

Reason:
The synthetic estimated-risk tier is a true banding family. A row should occupy exactly one synthetic estimated-risk band.

--------------------------------------------------------------------------------
1B. DTI band coverage
--------------------------------------------------------------------------------

Exactly one of the following should be true for every row:

- dti_clean_band_flag
- dti_review_trigger_flag
- dti_decline_trigger_flag

Add either a diagnostic count field or local gatekeeper logic such as:

dti_band_flag_count

The local gatekeeper should fail if dti_band_flag_count <> 1.

Reason:
DTI is also a true capacity banding family. A row should occupy exactly one DTI band.

--------------------------------------------------------------------------------
1C. Do NOT force mutual exclusivity across all trigger families
--------------------------------------------------------------------------------

Important:
Do not force mutual exclusivity across all rule-trigger families.

For example:
- counteroffer_candidate_flag may coexist with requested PTI pressure
- manual_review_candidate_flag may coexist with borderline_profile_flag
- hard_policy_stop_flag may coexist with other diagnostic triggers
- requested affordability, requested Expected Loss, exposure, and mixed-signal triggers may overlap by design

Section 6 is a rule-trigger layer, not a final decision hierarchy.

The purpose of this patch is to harden true banding families only, not to erase valid overlapping strategy signals.

================================================================================
2. NEXT BUILD SCOPE: SECTION 7 ONLY
================================================================================

After the Section 6 hardening patch, please build only:

SECTION 7 — PRELIMINARY DECISION ROUTING LAYER

Recommended staged table:

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
- approved_amount
- counteroffer_amount
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount
- final latest-run output table
- archive insert logic
- full QA framework

Those belong to later sections.

================================================================================
3. SECTION 7 OBJECTIVE
================================================================================

Section 7 should consume:

tmp_m2_stage_3_rule_flags

and create a transparent preliminary routing layer that converts overlapping Section 6 triggers into one preliminary route.

Section 7 should answer:

“Based on current triggers, what path should this synthetic applicant be routed toward before approved exposure / counteroffer feasibility is calculated?”

Section 7 should not answer:

“What is the final strategy outcome?”

Important:
Section 7 is preliminary routing only.

Final decision_outcome will be created later after:
- approved exposure logic
- counteroffer feasibility logic
- approved payment logic
- approved PTI logic
- approved Expected Loss logic
- reason-code assignment

are built.

================================================================================
4. PRELIMINARY OUTCOME VALUES
================================================================================

Use the same four business outcome labels, but store them in:

preliminary_decision_outcome

Allowed values:
- APPROVE
- COUNTEROFFER
- MANUAL_REVIEW
- DECLINE

Important:
These are preliminary routing outcomes only.

They should not be interpreted as final strategy outcomes.

Final decision_outcome will be created later after approved exposure, approved PTI, approved Expected Loss, and counteroffer feasibility logic are complete.

================================================================================
5. PRELIMINARY ROUTING HIERARCHY
================================================================================

Please use a clear priority hierarchy.

Recommended hierarchy:

--------------------------------------------------------------------------------
Priority 1 — Hard simulated policy stop route
--------------------------------------------------------------------------------

If hard_policy_stop_flag = TRUE:

- preliminary_decision_outcome = DECLINE
- preliminary_decision_path = HARD_POLICY_STOP
- preliminary_decision_priority_rank = 1
- preliminary_route_reason_family = HARD_POLICY_STOP

Examples:
- bankruptcy policy stop
- major derogatory policy stop
- severe delinquency policy stop

Important:
This is still preliminary routing. It is not yet final decision_outcome.

--------------------------------------------------------------------------------
Priority 2 — Severe synthetic estimated-risk route
--------------------------------------------------------------------------------

If synthetic_risk_decline_trigger_flag = TRUE
and no higher-priority route has fired:

- preliminary_decision_outcome = DECLINE
- preliminary_decision_path = SEVERE_SYNTHETIC_RISK
- preliminary_decision_priority_rank = 2
- preliminary_route_reason_family = SYNTHETIC_ESTIMATED_RISK

Reason:
Synthetic estimated-risk severity is not corrected through exposure reduction in Module 2 v1.0.

Important:
Use Module 1 estimated_pd only as the synthetic estimated-PD proxy input.
Do not recalculate estimated_pd.

--------------------------------------------------------------------------------
Priority 3 — Severe DTI capacity route
--------------------------------------------------------------------------------

If dti_decline_trigger_flag = TRUE
and no higher-priority route has fired:

- preliminary_decision_outcome = DECLINE
- preliminary_decision_path = SEVERE_DTI_CAPACITY
- preliminary_decision_priority_rank = 3
- preliminary_route_reason_family = DTI_CAPACITY

Reason:
DTI reflects existing-obligation capacity and is not directly solved through a counteroffer in Module 2 v1.0.

--------------------------------------------------------------------------------
Priority 4 — Counteroffer feasibility route
--------------------------------------------------------------------------------

If counteroffer_candidate_flag = TRUE
and no higher-priority decline route has fired:

- preliminary_decision_outcome = COUNTEROFFER
- preliminary_decision_path = COUNTEROFFER_FEASIBILITY_CHECK
- preliminary_decision_priority_rank = 4
- preliminary_route_reason_family = COUNTEROFFER_FEASIBILITY
- requires_counteroffer_feasibility_flag = TRUE
- requires_approved_exposure_calculation_flag = TRUE

Important:
This does not prove the counteroffer is viable.

It only routes the row to later approved-exposure / counteroffer feasibility logic.

Counteroffer viability cannot be finalized until the later section calculates:
- approved_amount
- counteroffer_amount
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount

--------------------------------------------------------------------------------
Priority 5 — Severe requested-structure review route
--------------------------------------------------------------------------------

If any severe requested-structure trigger is active
and no higher-priority route has fired
and counteroffer_candidate_flag is not TRUE:

Examples:
- requested_pti_decline_trigger_flag = TRUE
- requested_el_decline_trigger_flag = TRUE
- requested_exposure_extreme_flag = TRUE
- exposure_policy_stop_candidate_flag = TRUE

Then route:

- preliminary_decision_outcome = MANUAL_REVIEW
- preliminary_decision_path = REQUESTED_STRUCTURE_SEVERE_REVIEW
- preliminary_decision_priority_rank = 5
- preliminary_route_reason_family = REQUESTED_STRUCTURE_REVIEW

Reason:
Requested PTI, requested Expected Loss, and requested exposure stress may be addressable through exposure treatment in some cases, but approved-exposure logic has not been built yet.

If the row is not already a counteroffer candidate and is not routed by a higher-priority decline rule, it should not silently become a clean approval.

Manual review is the safest preliminary route for severe requested-structure stress that remains unresolved at this stage.

--------------------------------------------------------------------------------
Priority 6 — Manual review route
--------------------------------------------------------------------------------

If manual_review_candidate_flag = TRUE
and no higher-priority route has fired:

- preliminary_decision_outcome = MANUAL_REVIEW
- preliminary_decision_path = MANUAL_REVIEW_CANDIDATE
- preliminary_decision_priority_rank = 6
- preliminary_route_reason_family = MANUAL_REVIEW

Manual review remains unresolved.

Section 7 should not calculate approved amount or approved Expected Loss for manual-review rows.

--------------------------------------------------------------------------------
Priority 7 — Clean approval route
--------------------------------------------------------------------------------

If clean_approval_candidate_flag = TRUE
and no higher-priority route has fired:

- preliminary_decision_outcome = APPROVE
- preliminary_decision_path = CLEAN_APPROVAL_CANDIDATE
- preliminary_decision_priority_rank = 7
- preliminary_route_reason_family = CLEAN_APPROVAL
- requires_approved_exposure_calculation_flag = TRUE

Reason:
Even clean approvals still need approved amount / approved Expected Loss fields populated later.

Important:
This is preliminary approval routing only, not final APPROVE.

--------------------------------------------------------------------------------
Priority 8 — Residual strategy review fallback
--------------------------------------------------------------------------------

If no route is assigned by the above:

- preliminary_decision_outcome = MANUAL_REVIEW
- preliminary_decision_path = RESIDUAL_STRATEGY_REVIEW
- preliminary_decision_priority_rank = 8
- preliminary_route_reason_family = RESIDUAL_REVIEW

Reason:
Unclassified synthetic profiles should not silently become approvals or declines.

Residual review is intentionally conservative and audit-readable.

================================================================================
6. SECTION 7 OUTPUT REQUIREMENTS
================================================================================

Section 7 should preserve all prior fields and add:

Core preliminary routing fields:
- preliminary_decision_outcome
- preliminary_decision_path
- preliminary_decision_priority_rank
- preliminary_route_reason_family

Preliminary flags:
- preliminary_decline_flag
- preliminary_counteroffer_flag
- preliminary_manual_review_flag
- preliminary_approve_flag

Exposure-routing flags:
- requires_counteroffer_feasibility_flag
- requires_approved_exposure_calculation_flag

Optional diagnostic field:
- preliminary_route_trigger_count

Do not add:
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
- approved_amount
- counteroffer_amount
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount

================================================================================
7. SECTION 7 LOCAL GATEKEEPERS
================================================================================

At the end of Section 7, include local fail-fast checks.

Validate:

1. Structural preservation
- row count is unchanged from tmp_m2_stage_3_rule_flags
- application_id remains unique

2. Preliminary routing completeness
- preliminary_decision_outcome is non-null for every row
- preliminary_decision_outcome is one of:
  - APPROVE
  - COUNTEROFFER
  - MANUAL_REVIEW
  - DECLINE

- preliminary_decision_path is non-null for every row
- preliminary_decision_priority_rank is non-null and positive
- preliminary_route_reason_family is non-null for every row

3. Preliminary flag reconciliation
Exactly one of the following should be TRUE per row:
- preliminary_decline_flag
- preliminary_counteroffer_flag
- preliminary_manual_review_flag
- preliminary_approve_flag

And each flag should reconcile to preliminary_decision_outcome:
- preliminary_decline_flag = TRUE only when preliminary_decision_outcome = DECLINE
- preliminary_counteroffer_flag = TRUE only when preliminary_decision_outcome = COUNTEROFFER
- preliminary_manual_review_flag = TRUE only when preliminary_decision_outcome = MANUAL_REVIEW
- preliminary_approve_flag = TRUE only when preliminary_decision_outcome = APPROVE

4. Priority hierarchy enforcement
- hard_policy_stop_flag = TRUE always routes to preliminary_decision_outcome = DECLINE and preliminary_decision_path = HARD_POLICY_STOP
- synthetic_risk_decline_trigger_flag = TRUE routes to DECLINE unless hard_policy_stop_flag already routed it
- dti_decline_trigger_flag = TRUE routes to DECLINE unless hard policy stop or severe synthetic risk already routed it
- preliminary_decision_outcome = COUNTEROFFER only when counteroffer_candidate_flag = TRUE
- preliminary_decision_outcome = APPROVE only when clean_approval_candidate_flag = TRUE
- residual strategy review should only occur when no higher-priority route applies

5. Feasibility-routing flags
- preliminary_decision_outcome = COUNTEROFFER requires requires_counteroffer_feasibility_flag = TRUE
- preliminary_decision_outcome IN (APPROVE, COUNTEROFFER) requires requires_approved_exposure_calculation_flag = TRUE
- preliminary_decision_outcome IN (DECLINE, MANUAL_REVIEW) should not require approved exposure calculation

6. No final outcome fields yet
Validate or explicitly confirm:
- no final decision_outcome column exists yet
- no final decision_path column exists yet
- no final approval_flag / decline_flag / manual_review_flag / counteroffer_flag exists yet
- no simulated_offer_exposure_flag exists yet
- no reason-code columns exist yet
- no approved amount fields exist yet
- no approved payment fields exist yet
- no approved Expected Loss fields exist yet

These are Section 7 local staging gatekeepers only, not full Module 2 QA.

================================================================================
8. SECTION 7 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight staging diagnostics.

Suggested checks:

1. Count by preliminary_decision_outcome
2. Count by preliminary_decision_path
3. Count by preliminary_decision_priority_rank
4. Count by preliminary_route_reason_family
5. Product × preliminary_decision_outcome
6. Score band × preliminary_decision_outcome
7. Requested PTI bucket × preliminary_decision_outcome
8. Strategy risk tier × preliminary_decision_outcome
9. Requested exposure tier × preliminary_decision_outcome
10. Requested Expected Loss tier × preliminary_decision_outcome
11. Mixed-signal profile × preliminary_decision_outcome
12. Borderline profile flag × preliminary_decision_outcome
13. Hard policy stop flag × preliminary_decision_outcome
14. Synthetic risk decline trigger × preliminary_decision_outcome
15. DTI decline trigger × preliminary_decision_outcome
16. Counteroffer candidate flag × preliminary_decision_outcome
17. Manual review candidate flag × preliminary_decision_outcome
18. Clean approval candidate flag × preliminary_decision_outcome
19. requires_counteroffer_feasibility_flag × preliminary_decision_outcome
20. requires_approved_exposure_calculation_flag × preliminary_decision_outcome

These are staging diagnostics only.
They should not be interpreted as final decision validation.

================================================================================
9. SECTION 7 COMMENTARY QUALITY
================================================================================

Please maintain the elite commentary standard.

Section 7 comments should explain:

- why this is preliminary routing, not final decisioning
- why final decision_outcome is deferred
- why counteroffer feasibility cannot be finalized before approved exposure logic
- why hard simulated policy stops override other triggers
- why severe synthetic estimated-risk is not solved by exposure reduction in Module 2 v1.0
- why severe DTI is treated as an existing-obligation capacity issue
- why severe requested-structure stress may require counteroffer feasibility or unresolved review
- why manual review remains unresolved
- why clean approval is still only preliminary before final approved amount and approved Expected Loss fields are populated
- why residual unclassified cases route to manual review instead of silent approval
- why no reason codes are assigned yet
- why no approved amount, approved payment, approved PTI, or approved Expected Loss is calculated yet
- why preliminary routing supports auditability without overstating final decision logic

No silent assumptions.
No unexplained magic numbers.
No production-decision language.

================================================================================
10. SECTION 7 DELIVERABLE
================================================================================

Please now provide:

1. Targeted Section 6 hardening patch only:
   - synthetic estimated-risk band coverage gatekeeper
   - DTI band coverage gatekeeper

2. Section 7 SQL only:
   PRELIMINARY DECISION ROUTING LAYER.

3. A short explanation of what Section 7 establishes.

4. A short explanation of what Section 7 intentionally does not build.

5. The recommended next build step after Section 7.

Do not write Section 8+ yet.
<!-- END_MESSAGE C038-M00109 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_02.md) · [Next](Part_04.md)
