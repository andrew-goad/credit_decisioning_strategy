# Module 2 Decision Simulator Build

## Part 65

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_64.md) · [Next](Part_66.md)

<a id="c038-m01232"></a>

### C038-M01232

**ChatGPT** · 2026-05-10T16:00:10.953083-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01232 -->
According to a document from 2026-05-10, Module 2 is intentionally driven from `tmp_module2_strategy_params`, `tmp_module2_product_policy_params`, and the persistent run / comparison registries. Section 3 then gatekeeps one active strategy row, complete product policy rows, valid source selection, and registry matching before downstream decision logic executes. fileciteturn171file2 fileciteturn171file7

Below is the reposted **Module 2 campaign parameter run guide** using the now-locked Module 1 campaign scenario names, including the corrected:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

---

## 1. Universal Module 2 formal campaign controls

Use these for **every formal Module 2 campaign run** unless the specific row says otherwise.

| Parameter | Value / rule |
|---|---|
| `active_strategy_flag` | `TRUE` for exactly one row |
| `module2_model_version` | `MODULE2_V1_0` |
| `strategy_set_name` | `MODULE2_BASELINE_STRATEGY_SET` |
| `strategy_version` | `V1_0` |
| `strategy_run_id` | Use pattern: `M2-##_STRATEGY_NAME_V1_0_RUN` |
| `strategy_run_ts` | `CURRENT_TIMESTAMP` |
| `campaign_registry_required_flag` | `TRUE` |
| `module1_input_source` | `ARCHIVE` |
| `source_population_id` | `BASE_POPULATION_V1` |
| `archive_run_flag` | `TRUE` |
| `strategy_archive_reset_mode` | `STRATEGY_SCENARIO_ONLY` |
| `approve_reason_code` | `APPROVED_AS_REQUESTED` |
| `reason_code_required_flag` | `TRUE` |
| `simulated_offer_exposure_flag_enabled` | `TRUE` |
| `manual_review_approved_amount_convention` | `NULL_UNRESOLVED` |
| `decline_approved_amount_convention` | `ZERO` |
| `approved_el_decline_convention` | `ZERO` |
| `approved_el_manual_review_convention` | `NULL_UNRESOLVED` |
| `allow_approved_amount_above_requested_flag` | `FALSE` |

For formal runs, `ARCHIVE` input should consume a selected slice of `credit_decisioning_sim.synthetic_applications_scenario_archive`, and Section 3 will require `source_module1_scenario_set_name`, `source_module1_scenario_name`, and `source_population_id` to be populated. fileciteturn172file2

---

## 2. Common Module 2 rule-control parameters

These are not strategy outcomes. They create simulated trigger flags used later by routing, counteroffer feasibility, final decision resolution, and reason-code assignment.

| Parameter | Campaign value |
|---|---:|
| `borderline_threshold_buffer_pct` | `0.050000` |
| `bankruptcy_policy_stop_enabled` | `TRUE` |
| `major_derogatory_policy_stop_enabled` | `TRUE` |
| `severe_delinquency_policy_stop_enabled` | `TRUE` |
| `severe_delinquency_count_threshold` | `4` |
| `high_utilization_review_enabled` | `TRUE` |
| `high_utilization_review_threshold` | `0.850000` |
| `low_score_review_enabled` | `TRUE` |
| `low_score_review_threshold` | `580` |

These rule controls were defined as simulated strategy controls rather than production underwriting policy. fileciteturn172file5

---

## 3. Module 2 strategy profile parameter table

Use this table to update the active row in `tmp_module2_strategy_params` for each run.

| Strategy profile | `strategy_name` | Approve max estimated-PD proxy | Counteroffer max estimated-PD proxy | Review max estimated-PD proxy | Decline min estimated-PD proxy | Global approve PTI | Global review PTI | Global decline PTI | Approve DTI | Review DTI | Decline DTI | `failed_counteroffer_resolution` | Product-policy profile |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| Baseline | `BASELINE_STRATEGY` | `0.080000` | `0.160000` | `0.300000` | `0.350000` | `0.250000` | `0.400000` | `0.550000` | `0.430000` | `0.600000` | `0.600000` | `MANUAL_REVIEW` | Baseline product policy |
| Tighter synthetic risk | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | `0.060000` | `0.120000` | `0.250000` | `0.300000` | `0.250000` | `0.400000` | `0.550000` | `0.430000` | `0.600000` | `0.600000` | `MANUAL_REVIEW` | Baseline product policy |
| Growth oriented | `GROWTH_ORIENTED_STRATEGY` | `0.100000` | `0.200000` | `0.350000` | `0.400000` | `0.280000` | `0.430000` | `0.580000` | `0.460000` | `0.630000` | `0.630000` | `MANUAL_REVIEW` | Growth product policy |
| Tighter affordability | `TIGHTER_AFFORDABILITY_STRATEGY` | `0.080000` | `0.160000` | `0.300000` | `0.350000` | `0.220000` | `0.350000` | `0.500000` | `0.400000` | `0.550000` | `0.550000` | `MANUAL_REVIEW` | Affordability-tight product policy |
| Counteroffer first | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `0.080000` | `0.160000` | `0.300000` | `0.350000` | `0.250000` | `0.400000` | `0.550000` | `0.430000` | `0.600000` | `0.600000` | `MANUAL_REVIEW` | Counteroffer-first product policy |
| Product guardrails | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `0.080000` | `0.160000` | `0.300000` | `0.350000` | `0.250000` | `0.400000` | `0.550000` | `0.430000` | `0.600000` | `0.600000` | `MANUAL_REVIEW` | Product-guardrail policy |
| Manual-review reduction | `MANUAL_REVIEW_REDUCTION_STRATEGY` | `0.080000` | `0.160000` | `0.300000` | `0.350000` | `0.250000` | `0.400000` | `0.550000` | `0.430000` | `0.600000` | `0.600000` | `DECLINE` | Baseline product policy |

The current SQL default example is set to `TIGHTER_SYNTHETIC_RISK_STRATEGY`, with the tighter estimated-PD proxy thresholds shown above, and Section 3 validates threshold ordering and source configuration before the strategy runs. fileciteturn172file2

---

## 4. Baseline product-policy parameter table

Use this as the baseline `tmp_module2_product_policy_params` table unless a strategy profile calls for a product-policy overlay.

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Counteroffer allowed | Manual review allowed | Min counteroffer % | Max exposure reduction % | Assignment method | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|---:|---:|---|---:|
| `MORTGAGE` | `0.350000` | `0.450000` | `0.550000` | `0.320000` | `10000` | `20000` | `40000` | `10000` | `75000` | `800000` | `TRUE` | `TRUE` | `0.500000` | `0.500000` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` | `5000` |
| `HELOC` | `0.250000` | `0.350000` | `0.450000` | `0.220000` | `8000` | `16000` | `30000` | `7000` | `10000` | `175000` | `TRUE` | `TRUE` | `0.400000` | `0.500000` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` | `1000` |
| `AUTO_LOAN` | `0.180000` | `0.280000` | `0.380000` | `0.160000` | `3500` | `7000` | `12000` | `3000` | `5000` | `65000` | `TRUE` | `TRUE` | `0.500000` | `0.500000` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` | `500` |
| `UNSECURED_PERSONAL_LOAN` | `0.150000` | `0.250000` | `0.350000` | `0.130000` | `3000` | `6000` | `10000` | `2500` | `1000` | `35000` | `TRUE` | `TRUE` | `0.500000` | `0.500000` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` | `500` |
| `REVOLVING_LINE` | `0.120000` | `0.200000` | `0.300000` | `0.100000` | `2000` | `4000` | `8000` | `1800` | `1000` | `20000` | `TRUE` | `TRUE` | `0.500000` | `0.500000` | `MOST_CONSERVATIVE_FEASIBLE_AMOUNT` | `500` |

The product-policy table must contain exactly one row for each supported product: `MORTGAGE`, `HELOC`, `AUTO_LOAN`, `UNSECURED_PERSONAL_LOAN`, and `REVOLVING_LINE`; Section 3 validates completeness, threshold ordering, exposure bounds, counteroffer controls, assignment method, and rounding. fileciteturn173file9 fileciteturn174file0

---

## 5. Product-policy overlays by strategy profile

These are the campaign overlays to install in `tmp_module2_product_policy_params` when the selected strategy profile requires product-policy movement.

| Product-policy profile | Used by strategy | Products affected | Parameter movement |
|---|---|---|---|
| Baseline product policy | `BASELINE_STRATEGY`, `TIGHTER_SYNTHETIC_RISK_STRATEGY`, `MANUAL_REVIEW_REDUCTION_STRATEGY` | All products | Use baseline table above |
| Growth product policy | `GROWTH_ORIENTED_STRATEGY` | All products | Increase `product_max_approved_amount` by ~10%; increase `product_approved_el_cap` by ~10%; leave counteroffer controls unchanged |
| Affordability-tight product policy | `TIGHTER_AFFORDABILITY_STRATEGY` | All products | Reduce `product_approve_max_pti`, `product_review_max_pti`, `product_decline_min_pti`, and `counteroffer_target_pti` by ~2–5 percentage points while preserving ordering |
| Counteroffer-first product policy | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | All products, especially higher-balance products | Lower `counteroffer_target_pti`; lower `product_approved_el_cap` by ~15–25%; lower selected `product_max_approved_amount`; keep counteroffer allowed |
| Product-guardrail policy | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | `UNSECURED_PERSONAL_LOAN`, `REVOLVING_LINE` | Tighten unsecured / revolving caps: UPL max approved amount toward `25000–30000`, UPL approved EL cap toward `2000`; revolving max approved amount toward `15000–18000`, revolving approved EL cap toward `1200–1500` |

---

## 6. Full Module 2 campaign run map

For every row below:

```text
module1_input_source               = ARCHIVE
source_population_id               = BASE_POPULATION_V1
strategy_set_name                  = MODULE2_BASELINE_STRATEGY_SET
strategy_version                   = V1_0
campaign_registry_required_flag    = TRUE
archive_run_flag                   = TRUE
strategy_archive_reset_mode        = STRATEGY_SCENARIO_ONLY
```

| M2 run | `source_module1_scenario_set_name` | `source_module1_scenario_name` | `strategy_name` | Product-policy profile | Comparison role |
|---:|---|---|---|---|---|
| M2-01 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `BASELINE_STRATEGY` | Baseline | Baseline for CG01–CG06 |
| M2-02 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Baseline | Challenger CG01 |
| M2-03 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `GROWTH_ORIENTED_STRATEGY` | Growth | Challenger CG02 |
| M2-04 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `TIGHTER_AFFORDABILITY_STRATEGY` | Affordability-tight | Challenger CG03 |
| M2-05 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Counteroffer-first | Challenger CG04 |
| M2-06 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Product guardrail | Challenger CG05 |
| M2-07 | `MODULE1_V2_BASELINE_SET` | `BASELINE_V2` | `MANUAL_REVIEW_REDUCTION_STRATEGY` | Baseline | Challenger CG06 |
| M2-08 | `MODULE1_V2_BASELINE_SET` | `RATE_UP_200BP` | `BASELINE_STRATEGY` | Baseline | Baseline CG07 |
| M2-09 | `MODULE1_V2_BASELINE_SET` | `RATE_DOWN_200BP` | `BASELINE_STRATEGY` | Baseline | Baseline CG09 |
| M2-10 | `MODULE1_V2_BASELINE_SET` | `RATE_UP_300BP` | `BASELINE_STRATEGY` | Baseline | Baseline CG08 |
| M2-11 | `MODULE1_V2_BASELINE_SET` | `RATE_UP_200BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | Affordability-tight | Challenger CG07 |
| M2-12 | `MODULE1_V2_BASELINE_SET` | `RATE_UP_300BP` | `TIGHTER_AFFORDABILITY_STRATEGY` | Affordability-tight | Challenger CG08 |
| M2-13 | `MODULE1_V2_BASELINE_SET` | `RATE_DOWN_200BP` | `GROWTH_ORIENTED_STRATEGY` | Growth | Challenger CG09 |
| M2-14 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `CREDIT_BOX_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Baseline | Credit-box reference |
| M2-15 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `PRIME_GROWTH_SCORE_MIX` | `BASELINE_STRATEGY` | Baseline | Prime-growth baseline |
| M2-16 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `NEAR_PRIME_EXPANSION_MIX` | `BASELINE_STRATEGY` | Baseline | Baseline CG10–CG11 |
| M2-17 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `NEAR_PRIME_EXPANSION_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Baseline | Challenger CG10 |
| M2-18 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `NEAR_PRIME_EXPANSION_MIX` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Counteroffer-first | Challenger CG11 |
| M2-19 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `CREDIT_STRESS_SCORE_MIX` | `BASELINE_STRATEGY` | Baseline | Baseline CG12 |
| M2-20 | `MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET` | `CREDIT_STRESS_SCORE_MIX` | `TIGHTER_SYNTHETIC_RISK_STRATEGY` | Baseline | Challenger CG12 |
| M2-21 | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `PORTFOLIO_MIX_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Baseline | Product-mix reference |
| M2-22 | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `UNSECURED_GROWTH_MIX` | `BASELINE_STRATEGY` | Baseline | Baseline CG13 |
| M2-23 | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `UNSECURED_GROWTH_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Product guardrail | Challenger CG13 |
| M2-24 | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `SECURED_BALANCE_GROWTH_MIX` | `BASELINE_STRATEGY` | Baseline | Secured-balance baseline |
| M2-25 | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `REVOLVING_LINE_EXPANSION_MIX` | `BASELINE_STRATEGY` | Baseline | Baseline CG14 |
| M2-26 | `MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET` | `REVOLVING_LINE_EXPANSION_MIX` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Product guardrail | Challenger CG14 |
| M2-27 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `EXPOSURE_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Baseline | Exposure reference |
| M2-28 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `HIGH_BALANCE_APPETITE` | `BASELINE_STRATEGY` | Baseline | Baseline CG15 |
| M2-29 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `HIGH_BALANCE_APPETITE` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Counteroffer-first | Challenger CG15 |
| M2-30 | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `LOW_BALANCE_CONSERVATIVE_REQUESTS` | `BASELINE_STRATEGY` | Baseline | Low-balance baseline |
| M2-31 | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `LGD_BASELINE_REFERENCE` | `BASELINE_STRATEGY` | Baseline | LGD reference |
| M2-32 | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `SECURED_SEVERITY_STRESS` | `BASELINE_STRATEGY` | Baseline | Secured severity baseline |
| M2-33 | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `UNSECURED_SEVERITY_STRESS` | `BASELINE_STRATEGY` | Baseline | Baseline CG16 |
| M2-34 | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `UNSECURED_SEVERITY_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Product guardrail | Challenger CG16 |
| M2-35 | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `BROAD_LGD_STRESS` | `BASELINE_STRATEGY` | Baseline | Baseline CG17 |
| M2-36 | `MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET` | `BROAD_LGD_STRESS` | `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | Product guardrail | Challenger CG17 |

The persistent campaign registry exists to map the long technical key into stable IDs like `M2-02`, `showcase_id`, `comparison_group_id`, and `validation_evidence_group_id`; those IDs are documentation and evidence-linkage metadata, not replacements for the technical SQL run key. fileciteturn174file10

---

## 7. Comparison registry guide

Use the comparison registry after both sides of a pair are archived. Section 13 is designed to compare archived baseline and challenger strategy slices on the same Module 1 scenario / population, rather than infer comparison context from the replaceable latest-run table. fileciteturn170file18

| Comparison group | Baseline run | Challenger run | Comparison description |
|---|---:|---:|---|
| CG01 | M2-01 | M2-02 | Baseline vs tighter synthetic risk on `BASELINE_V2` |
| CG02 | M2-01 | M2-03 | Baseline vs growth oriented on `BASELINE_V2` |
| CG03 | M2-01 | M2-04 | Baseline vs tighter affordability on `BASELINE_V2` |
| CG04 | M2-01 | M2-05 | Baseline vs counteroffer-first on `BASELINE_V2` |
| CG05 | M2-01 | M2-06 | Baseline vs product guardrails on `BASELINE_V2` |
| CG06 | M2-01 | M2-07 | Baseline vs manual-review reduction on `BASELINE_V2` |
| CG07 | M2-08 | M2-11 | Rate-up 200bp baseline vs tighter affordability |
| CG08 | M2-10 | M2-12 | Rate-up 300bp baseline vs tighter affordability |
| CG09 | M2-09 | M2-13 | Rate-down 200bp baseline vs growth oriented |
| CG10 | M2-16 | M2-17 | Near-prime expansion baseline vs tighter synthetic risk |
| CG11 | M2-16 | M2-18 | Near-prime expansion baseline vs counteroffer-first |
| CG12 | M2-19 | M2-20 | Credit-stress mix baseline vs tighter synthetic risk |
| CG13 | M2-22 | M2-23 | Unsecured growth baseline vs product guardrails |
| CG14 | M2-25 | M2-26 | Revolving expansion baseline vs product guardrails |
| CG15 | M2-28 | M2-29 | High-balance appetite baseline vs counteroffer-first |
| CG16 | M2-33 | M2-34 | Unsecured severity stress baseline vs product guardrails |
| CG17 | M2-35 | M2-36 | Broad LGD stress baseline vs product guardrails |

---

## 8. Strategy profile → run lookup

| Strategy | M2 runs |
|---|---|
| `BASELINE_STRATEGY` | M2-01, M2-08, M2-09, M2-10, M2-14, M2-15, M2-16, M2-19, M2-21, M2-22, M2-24, M2-25, M2-27, M2-28, M2-30, M2-31, M2-32, M2-33, M2-35 |
| `TIGHTER_SYNTHETIC_RISK_STRATEGY` | M2-02, M2-17, M2-20 |
| `GROWTH_ORIENTED_STRATEGY` | M2-03, M2-13 |
| `TIGHTER_AFFORDABILITY_STRATEGY` | M2-04, M2-11, M2-12 |
| `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | M2-05, M2-18, M2-29 |
| `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY` | M2-06, M2-23, M2-26, M2-34, M2-36 |
| `MANUAL_REVIEW_REDUCTION_STRATEGY` | M2-07 |

---

## 9. Recommended execution order

| Phase | Runs |
|---|---|
| Phase 1 — Baseline population pure strategy frontier | M2-01 through M2-07 |
| Phase 2 — Rate sensitivity | M2-08, M2-11; M2-10, M2-12; M2-09, M2-13 |
| Phase 3 — Credit-box sensitivity | M2-14; M2-15; M2-16, M2-17, M2-18; M2-19, M2-20 |
| Phase 4 — Portfolio-mix sensitivity | M2-21; M2-22, M2-23; M2-24; M2-25, M2-26 |
| Phase 5 — Exposure-intensity sensitivity | M2-27; M2-28, M2-29; M2-30 |
| Phase 6 — LGD severity sensitivity | M2-31; M2-32; M2-33, M2-34; M2-35, M2-36 |

---

## 10. After each Module 2 run

After each run, review these in order:

| Step | Review object / section | Purpose |
|---:|---|---|
| 1 | Section 3.5 active strategy and registry diagnostics | Confirm the active row, source scope, thresholds, product policy, and registry match |
| 2 | Section 12 archive diagnostics | Confirm the latest-run slice was archived under the intended replacement key |
| 3 | Section 13, when a pair exists | Confirm matched comparison readiness and source-field consistency |
| 4 | Section 14 validation outputs | Review latest-run structural, product, score, risk, affordability, counteroffer, manual-review, decline, reason-code, and edge-case QA |
| 5 | Section 15 frontier output | Review archive-backed strategy frontier and baseline-relative deltas |
| 6 | Section 16.8 evidence packet | Confirm executive evidence, validation evidence, parameter snapshot, product × score evidence, and registry linkage |

Section 16 snapshots the active strategy parameter card, product-policy card, and run-story metadata as JSONB, then stores a `parameter_snapshot_hash`, which is exactly what we want for campaign evidence traceability. fileciteturn170file5
<!-- END_MESSAGE C038-M01232 -->


---

<a id="c038-m01234"></a>

### C038-M01234

**Andrew** · 2026-05-10T16:33:16.487000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01234 -->
it's hard to know the variable associated with each of these line items.  please update section 2 with line level comments that detail what each variable/parameter is and any pertinent information about populating them. i shouldn't have to scroll to figure out what parameter I am looking at.
<!-- END_MESSAGE C038-M01234 -->


**Attachments in export:** `Pasted text(170).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01242"></a>

### C038-M01242

**ChatGPT** · 2026-05-10T16:39:05.233818-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01242 -->
Using your uploaded Section 2 as the base, the main usability issue is the `VALUES (...)` pattern in the editable parameter inserts: the column names are far above the values, so during campaign execution it is too easy to lose track of what each line controls. fileciteturn176file2

I recommend replacing the two most frequently edited operator-facing blocks, **Section 2.2** and **Section 2.4**, with the versions below. They preserve the same parameter logic, but change the inserts to named `SELECT` statements so each value sits beside its variable name and an inline comment.

```sql
/***************************************************************************************************
SECTION 2.2 — INSERT ACTIVE STRATEGY PARAMETER ROW
****************************************************************************************************

PURPOSE:
    Insert the current active Module 2 strategy configuration.

USER ACTION:
    This is the primary operator-edited Module 2 strategy card.

    For each Module 2 campaign run, update this block first.

    The most common fields to change are:
        strategy_name
        strategy_run_id
        source_module1_scenario_set_name
        source_module1_scenario_name
        source_population_id
        synthetic estimated-risk thresholds
        global PTI thresholds
        DTI thresholds
        failed_counteroffer_resolution
        product-policy table values in Section 2.4, when the strategy requires product overlays.

WHY THIS VERSION USES INSERT ... SELECT INSTEAD OF VALUES:
    The original VALUES layout required the user to scroll up to match each value to its column.

    This version keeps every value adjacent to:
        the target variable name,
        the business meaning,
        and the population guidance.

    That makes campaign operation safer.

CURRENT DEFAULT:
    The row below is currently configured as:

        Module 1 source:
            MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1

        Module 2 strategy:
            MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0

        Module 2 run:
            M2-02_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN

    To run another campaign row, change the named values below according to the Module 2 campaign
    run guide.

FORMAL CAMPAIGN REQUIREMENT:
    For formal campaign runs:
        campaign_registry_required_flag = TRUE
        module1_input_source = 'ARCHIVE'
        archive_run_flag = TRUE
        strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY'

    The technical run key must match exactly one active row in:
        credit_decisioning_sim.strategy_run_campaign_registry

TECHNICAL RUN KEY:
    The current strategy run is identified by:

        source_module1_scenario_set_name
        source_module1_scenario_name
        source_population_id
        strategy_set_name
        strategy_name
        strategy_version

    strategy_run_id and strategy_run_ts are traceability metadata.

    They do not replace the archive replacement key, comparison key, registry technical key, or
    application-level grain.

CREDIT RISK TEACHING POINT:
    This row defines strategy posture.

    It does not prove the strategy behaved correctly.

    Strategy behavior is observed later through:
        final decision distribution,
        simulated offer-exposure rate,
        approved exposure,
        approved Expected Loss,
        affordability movement,
        reason-code movement,
        product × score behavior,
        Section 15 frontier evidence,
        and Section 16 executive evidence capture.

****************************************************************************************************/

INSERT INTO tmp_module2_strategy_params (
    active_strategy_flag,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    campaign_registry_required_flag,

    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,

    archive_run_flag,
    strategy_archive_reset_mode,

    approve_max_estimated_pd_proxy,
    counteroffer_max_estimated_pd_proxy,
    review_max_estimated_pd_proxy,
    decline_min_estimated_pd_proxy,

    global_approve_max_pti,
    global_review_max_pti,
    global_decline_min_pti,

    approve_max_dti,
    review_max_dti,
    decline_min_dti,

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
    simulated_offer_exposure_flag_enabled,
    manual_review_approved_amount_convention,
    decline_approved_amount_convention,
    approved_el_decline_convention,
    approved_el_manual_review_convention,
    allow_approved_amount_above_requested_flag,

    failed_counteroffer_resolution
)
SELECT
    /***********************************************************************************************
    active_strategy_flag:
        TRUE marks this row as the one active Module 2 strategy card for the current execution.

    Populate as:
        TRUE for exactly one row.
        FALSE only if you intentionally keep inactive reference rows.

    Section 3 gatekeeper:
        fails if active row count is not exactly one.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS active_strategy_flag,


    /***********************************************************************************************
    module2_model_version:
        Version label for the Module 2 SQL engine.

    Populate as:
        'MODULE2_V1_0' for the current campaign.

    Do not use this as a comparison key by itself.
    ***********************************************************************************************/
    'MODULE2_V1_0'::TEXT AS module2_model_version,


    /***********************************************************************************************
    strategy_set_name:
        Strategy family / campaign grouping.

    Populate as:
        'MODULE2_BASELINE_STRATEGY_SET' for the current Module 2 campaign.

    This is part of:
        archive replacement key,
        matched comparison key,
        evidence-capture key,
        campaign registry technical key.
    ***********************************************************************************************/
    'MODULE2_BASELINE_STRATEGY_SET'::TEXT AS strategy_set_name,


    /***********************************************************************************************
    strategy_name:
        Specific Module 2 strategy posture to run.

    Common campaign values:
        'BASELINE_STRATEGY'
        'TIGHTER_SYNTHETIC_RISK_STRATEGY'
        'GROWTH_ORIENTED_STRATEGY'
        'TIGHTER_AFFORDABILITY_STRATEGY'
        'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
        'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
        'MANUAL_REVIEW_REDUCTION_STRATEGY'

    Update this for each Module 2 run.
    ***********************************************************************************************/
    'TIGHTER_SYNTHETIC_RISK_STRATEGY'::TEXT AS strategy_name,


    /***********************************************************************************************
    strategy_version:
        Version label for the strategy definition.

    Populate as:
        'V1_0' for the current campaign.

    Future strategy versions should be explicitly versioned so archived strategy slices remain
    comparable and auditable.
    ***********************************************************************************************/
    'V1_0'::TEXT AS strategy_version,


    /***********************************************************************************************
    strategy_run_id:
        Human-readable run traceability ID.

    Populate using the Module 2 run guide pattern:
        'M2-##_STRATEGY_NAME_V1_0_RUN'

    Example:
        'M2-02_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN'

    This is audit metadata.
    It is not the archive replacement key.
    ***********************************************************************************************/
    'M2-02_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN'::TEXT AS strategy_run_id,


    /***********************************************************************************************
    strategy_run_ts:
        Timestamp for the current execution.

    Populate as:
        CURRENT_TIMESTAMP for ordinary campaign runs.

    This is audit metadata.
    It is not a comparison key.
    ***********************************************************************************************/
    CURRENT_TIMESTAMP AS strategy_run_ts,


    /***********************************************************************************************
    campaign_registry_required_flag:
        Controls whether the technical run key must match the formal campaign registry.

    Populate as:
        TRUE for formal campaign runs.
        FALSE only for ad hoc development.

    If TRUE:
        Section 3 and Section 16 expect exactly one matching active row in:
            credit_decisioning_sim.strategy_run_campaign_registry
    ***********************************************************************************************/
    TRUE::BOOLEAN AS campaign_registry_required_flag,


    /***********************************************************************************************
    module1_input_source:
        Selects the upstream Module 1 source.

    Allowed values:
        'LATEST'
            consumes credit_decisioning_sim.synthetic_applications.

        'ARCHIVE'
            consumes credit_decisioning_sim.synthetic_applications_scenario_archive.

    Populate as:
        'ARCHIVE' for formal campaign runs so Module 2 consumes a controlled Module 1 scenario slice.
    ***********************************************************************************************/
    'ARCHIVE'::TEXT AS module1_input_source,


    /***********************************************************************************************
    source_module1_scenario_set_name:
        Module 1 scenario-set identifier to consume when module1_input_source = 'ARCHIVE'.

    Populate from the locked Module 1 campaign inventory.

    Examples:
        'MODULE1_V2_BASELINE_SET'
        'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET'
        'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET'
        'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
        'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET'

    This is part of the technical run key.
    ***********************************************************************************************/
    'MODULE1_V2_BASELINE_SET'::TEXT AS source_module1_scenario_set_name,


    /***********************************************************************************************
    source_module1_scenario_name:
        Specific Module 1 scenario slice to consume when module1_input_source = 'ARCHIVE'.

    Populate from the locked Module 1 campaign inventory.

    Examples:
        'BASELINE_V2'
        'RATE_UP_200BP'
        'NEAR_PRIME_EXPANSION_MIX'
        'UNSECURED_GROWTH_MIX'
        'HIGH_BALANCE_APPETITE'
        'BROAD_LGD_STRESS'

    This is part of the technical run key.
    ***********************************************************************************************/
    'BASELINE_V2'::TEXT AS source_module1_scenario_name,


    /***********************************************************************************************
    source_population_id:
        Module 1 population identifier.

    Populate as:
        'BASE_POPULATION_V1' for the current formal campaign.

    Matched comparisons require the same population_id.
    ***********************************************************************************************/
    'BASE_POPULATION_V1'::TEXT AS source_population_id,


    /***********************************************************************************************
    archive_run_flag:
        Controls whether Section 12 persists the completed latest-run output.

    Populate as:
        TRUE for formal campaign runs.

    If FALSE:
        Section 12 skips archive insert.
        Section 13 / 15 / 16 may not have historical evidence for the run.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS archive_run_flag,


    /***********************************************************************************************
    strategy_archive_reset_mode:
        Controls archive replacement behavior before inserting the current latest-run slice.

    Recommended formal campaign value:
        'STRATEGY_SCENARIO_ONLY'

    Meaning:
        Replace only the current:
            strategy_set_name,
            strategy_name,
            strategy_version,
            Module 1 scenario set,
            Module 1 scenario name,
            population_id.

    Other allowed values:
        'NONE'
        'STRATEGY_SET_ONLY'
        'ALL'
    ***********************************************************************************************/
    'STRATEGY_SCENARIO_ONLY'::TEXT AS strategy_archive_reset_mode,


    /***********************************************************************************************
    approve_max_estimated_pd_proxy:
        Global synthetic estimated-PD proxy ceiling for clean approval eligibility.

    Current tighter synthetic-risk value:
        0.060000

    Baseline strategy value:
        0.080000

    Lower values tighten risk appetite.
    ***********************************************************************************************/
    0.060000::NUMERIC(12,6) AS approve_max_estimated_pd_proxy,


    /***********************************************************************************************
    counteroffer_max_estimated_pd_proxy:
        Global synthetic estimated-PD proxy ceiling for counteroffer risk band.

    Current tighter synthetic-risk value:
        0.120000

    Baseline strategy value:
        0.160000

    Rows above approve_max_estimated_pd_proxy and at or below this value may be counteroffer
    candidates if other conditions allow.
    ***********************************************************************************************/
    0.120000::NUMERIC(12,6) AS counteroffer_max_estimated_pd_proxy,


    /***********************************************************************************************
    review_max_estimated_pd_proxy:
        Global synthetic estimated-PD proxy ceiling for review-zone risk band.

    Current tighter synthetic-risk value:
        0.250000

    Baseline strategy value:
        0.300000

    Rows above counteroffer risk tolerance but below decline minimum can route toward review depending
    on the downstream hierarchy.
    ***********************************************************************************************/
    0.250000::NUMERIC(12,6) AS review_max_estimated_pd_proxy,


    /***********************************************************************************************
    decline_min_estimated_pd_proxy:
        Global synthetic estimated-PD proxy floor for severe synthetic-risk decline trigger.

    Current tighter synthetic-risk value:
        0.300000

    Baseline strategy value:
        0.350000

    Rows at or above this threshold are treated as severe synthetic-risk triggers.
    ***********************************************************************************************/
    0.300000::NUMERIC(12,6) AS decline_min_estimated_pd_proxy,


    /***********************************************************************************************
    global_approve_max_pti:
        Global high-level clean approval PTI tolerance.

    PTI:
        payment-to-income ratio.

    Current baseline value:
        0.250000

    Product-specific PTI thresholds in Section 2.4 drive product-aware rules.
    This global value is a strategy-level control and validation reference.
    ***********************************************************************************************/
    0.250000::NUMERIC(12,6) AS global_approve_max_pti,


    /***********************************************************************************************
    global_review_max_pti:
        Global high-level review-zone PTI reference.

    Current baseline value:
        0.400000

    Higher requested PTI indicates greater payment burden.
    ***********************************************************************************************/
    0.400000::NUMERIC(12,6) AS global_review_max_pti,


    /***********************************************************************************************
    global_decline_min_pti:
        Global high-level severe requested-PTI reference.

    Current baseline value:
        0.550000

    Product-specific decline PTI thresholds still drive product-aware behavior.
    ***********************************************************************************************/
    0.550000::NUMERIC(12,6) AS global_decline_min_pti,


    /***********************************************************************************************
    approve_max_dti:
        Existing-obligation DTI ceiling for clean DTI capacity.

    Current baseline value:
        0.430000

    DTI is not directly fixed by reducing requested exposure in Module 2 V1.0.
    ***********************************************************************************************/
    0.430000::NUMERIC(12,6) AS approve_max_dti,


    /***********************************************************************************************
    review_max_dti:
        Existing-obligation DTI review-zone reference.

    Current baseline value:
        0.600000

    This may equal decline_min_dti when the design intentionally creates a direct severe-DTI boundary.
    ***********************************************************************************************/
    0.600000::NUMERIC(12,6) AS review_max_dti,


    /***********************************************************************************************
    decline_min_dti:
        Existing-obligation DTI floor for severe DTI trigger.

    Current baseline value:
        0.600000

    Rows at or above this threshold are treated as severe DTI capacity triggers.
    ***********************************************************************************************/
    0.600000::NUMERIC(12,6) AS decline_min_dti,


    /***********************************************************************************************
    borderline_threshold_buffer_pct:
        Diagnostic buffer for threshold-adjacent profiles.

    Current value:
        0.050000

    Interpretation:
        within 5% of a relevant strategy threshold.

    Used for:
        borderline_profile_flag in Section 5.

    Not a production tolerance.
    ***********************************************************************************************/
    0.050000::NUMERIC(12,6) AS borderline_threshold_buffer_pct,


    /***********************************************************************************************
    bankruptcy_policy_stop_enabled:
        Enables simulated bankruptcy policy-stop trigger.

    Populate as:
        TRUE for current campaign.

    Uses Module 1 bankruptcy_flag downstream.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS bankruptcy_policy_stop_enabled,


    /***********************************************************************************************
    major_derogatory_policy_stop_enabled:
        Enables simulated major-derogatory policy-stop trigger.

    Populate as:
        TRUE for current campaign.

    Uses Module 1 major_derogatory_flag downstream.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS major_derogatory_policy_stop_enabled,


    /***********************************************************************************************
    severe_delinquency_policy_stop_enabled:
        Enables simulated severe-delinquency policy-stop trigger.

    Populate as:
        TRUE for current campaign.

    Uses delinquency_count_12m downstream.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS severe_delinquency_policy_stop_enabled,


    /***********************************************************************************************
    severe_delinquency_count_threshold:
        Delinquency-count threshold for severe-delinquency trigger.

    Current value:
        4

    Downstream interpretation:
        delinquency_count_12m >= 4 when severe_delinquency_policy_stop_enabled = TRUE.
    ***********************************************************************************************/
    4::INTEGER AS severe_delinquency_count_threshold,


    /***********************************************************************************************
    high_utilization_review_enabled:
        Enables supplemental high-utilization review trigger.

    Populate as:
        TRUE for current campaign.

    This is a simulated diagnostic review trigger, not production policy.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS high_utilization_review_enabled,


    /***********************************************************************************************
    high_utilization_review_threshold:
        Utilization threshold for supplemental review trigger.

    Current value:
        0.850000

    Downstream interpretation:
        utilization_ratio >= 85% when high_utilization_review_enabled = TRUE.
    ***********************************************************************************************/
    0.850000::NUMERIC(12,6) AS high_utilization_review_threshold,


    /***********************************************************************************************
    low_score_review_enabled:
        Enables supplemental low-score review trigger.

    Populate as:
        TRUE for current campaign.

    This is a simulated diagnostic review trigger, not production policy.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS low_score_review_enabled,


    /***********************************************************************************************
    low_score_review_threshold:
        Credit-score threshold for supplemental review trigger.

    Current value:
        580

    Downstream interpretation:
        credit_score < 580 when low_score_review_enabled = TRUE.
    ***********************************************************************************************/
    580::INTEGER AS low_score_review_threshold,


    /***********************************************************************************************
    approve_reason_code:
        Required primary reason code for clean APPROVE outcomes.

    Populate as:
        'APPROVED_AS_REQUESTED'

    This is a simulated strategy explanation code.
    It is not customer communication text.
    ***********************************************************************************************/
    'APPROVED_AS_REQUESTED'::TEXT AS approve_reason_code,


    /***********************************************************************************************
    reason_code_required_flag:
        Controls whether reason-code completeness is required downstream.

    Populate as:
        TRUE for formal campaign runs.

    Section 10 and Section 14 expect reason-code evidence for every row.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS reason_code_required_flag,


    /***********************************************************************************************
    simulated_offer_exposure_flag_enabled:
        Controls simulated offer-exposure flag convention.

    Populate as:
        TRUE for current campaign.

    Downstream convention:
        TRUE for APPROVE and COUNTEROFFER.
        FALSE for MANUAL_REVIEW and DECLINE.
    ***********************************************************************************************/
    TRUE::BOOLEAN AS simulated_offer_exposure_flag_enabled,


    /***********************************************************************************************
    manual_review_approved_amount_convention:
        Approved amount convention for final MANUAL_REVIEW rows.

    Populate as:
        'NULL_UNRESOLVED'

    Meaning:
        manual review remains unresolved and does not receive approved exposure.
    ***********************************************************************************************/
    'NULL_UNRESOLVED'::TEXT AS manual_review_approved_amount_convention,


    /***********************************************************************************************
    decline_approved_amount_convention:
        Approved amount convention for final DECLINE rows.

    Populate as:
        'ZERO'

    Meaning:
        decline follows zero-exposure convention.
    ***********************************************************************************************/
    'ZERO'::TEXT AS decline_approved_amount_convention,


    /***********************************************************************************************
    approved_el_decline_convention:
        Approved Expected Loss convention for final DECLINE rows.

    Populate as:
        'ZERO'

    Meaning:
        declined rows have approved_expected_loss_amount = 0.
    ***********************************************************************************************/
    'ZERO'::TEXT AS approved_el_decline_convention,


    /***********************************************************************************************
    approved_el_manual_review_convention:
        Approved Expected Loss convention for final MANUAL_REVIEW rows.

    Populate as:
        'NULL_UNRESOLVED'

    Meaning:
        manual-review rows remain unresolved and do not receive approved Expected Loss.
    ***********************************************************************************************/
    'NULL_UNRESOLVED'::TEXT AS approved_el_manual_review_convention,


    /***********************************************************************************************
    allow_approved_amount_above_requested_flag:
        Controls whether approved exposure may exceed requested exposure.

    Populate as:
        FALSE for current campaign.

    Current Module 2 convention:
        approved exposure should never exceed requested exposure.
    ***********************************************************************************************/
    FALSE::BOOLEAN AS allow_approved_amount_above_requested_flag,


    /***********************************************************************************************
    failed_counteroffer_resolution:
        Final-resolution policy when a preliminary COUNTEROFFER fails feasibility in Section 8.

    Allowed values:
        'MANUAL_REVIEW'
        'DECLINE'

    Common campaign values:
        'MANUAL_REVIEW' for baseline and most challenger strategies.
        'DECLINE' for MANUAL_REVIEW_REDUCTION_STRATEGY.

    This parameter changes final outcome mix and should be documented carefully.
    ***********************************************************************************************/
    'MANUAL_REVIEW'::TEXT AS failed_counteroffer_resolution;
```

```sql
/***************************************************************************************************
SECTION 2.4 — INSERT PRODUCT POLICY DEFAULTS
****************************************************************************************************

DEFAULT INTERPRETATION:
    These are initial simulated product-policy defaults.

    They are not:
        production underwriting limits,
        final approved credit policy,
        empirical calibration,
        real customer treatment rules,
        regulatory thresholds,
        or actual product approval rules.

WHY THIS VERSION USES A NAMED PRODUCT_POLICY_SEED CTE:
    The original VALUES block required the user to scroll to the INSERT column list to determine
    what each number meant.

    This version labels every value with:
        the target variable name,
        the product context,
        and population guidance.

    That makes product-policy campaign edits safer.

PRODUCT POLICY INTERPRETATION:
    Product parameters make the strategy simulator product-aware.

    Each supported product receives distinct:
        affordability thresholds,
        requested Expected Loss thresholds,
        approved Expected Loss caps,
        approved exposure limits,
        counteroffer controls,
        manual-review controls,
        and rounding increments.

SUPPORTED PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

CAMPAIGN EDIT GUIDANCE:
    Use the baseline product policy below for:
        BASELINE_STRATEGY
        TIGHTER_SYNTHETIC_RISK_STRATEGY
        MANUAL_REVIEW_REDUCTION_STRATEGY

    For:
        GROWTH_ORIENTED_STRATEGY
        TIGHTER_AFFORDABILITY_STRATEGY
        COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
        PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY

    edit the relevant named values below before running the strategy.

SQL MECHANICS:
    product_policy_seed creates one named row per product using UNION ALL.

    The final INSERT copies those named columns into tmp_module2_product_policy_params.

    Section 3 validates:
        exactly one row per supported product,
        no unsupported products,
        threshold ordering,
        exposure limits,
        counteroffer settings,
        exposure assignment method,
        and rounding controls.

****************************************************************************************************/

WITH product_policy_seed AS (

    /***********************************************************************************************
    PRODUCT POLICY ROW — MORTGAGE

    Business interpretation:
        Large secured installment exposure.

    Product-policy posture:
        Higher PTI tolerance than unsecured products because mortgage structure is secured and
        long-term.

        Larger approved exposure range, but still constrained by approved Expected Loss cap and
        product max approved amount.
    ***********************************************************************************************/
    SELECT
        /*******************************************************************************************
        product_type:
            Must match product_type_policy_key produced in Section 4.
        *******************************************************************************************/
        'MORTGAGE'::TEXT AS product_type,

        /*******************************************************************************************
        product_approve_max_pti:
            Maximum requested PTI for product-level clean affordability posture.

        Mortgage baseline:
            0.350000
        *******************************************************************************************/
        0.350000::NUMERIC(12,6) AS product_approve_max_pti,

        /*******************************************************************************************
        product_review_max_pti:
            Product-level review-zone PTI reference.

        Mortgage baseline:
            0.450000
        *******************************************************************************************/
        0.450000::NUMERIC(12,6) AS product_review_max_pti,

        /*******************************************************************************************
        product_decline_min_pti:
            Severe requested PTI threshold for product-level affordability stress.

        Mortgage baseline:
            0.550000
        *******************************************************************************************/
        0.550000::NUMERIC(12,6) AS product_decline_min_pti,

        /*******************************************************************************************
        counteroffer_target_pti:
            Target approved PTI used in reduced-exposure feasibility testing.

        Mortgage baseline:
            0.320000
        *******************************************************************************************/
        0.320000::NUMERIC(12,6) AS counteroffer_target_pti,

        /*******************************************************************************************
        product_approve_max_requested_el:
            Requested-exposure Expected Loss threshold for clean product approval posture.

        Mortgage baseline:
            10000.00
        *******************************************************************************************/
        10000.00::NUMERIC(18,2) AS product_approve_max_requested_el,

        /*******************************************************************************************
        product_review_max_requested_el:
            Requested-exposure Expected Loss review-zone reference.

        Mortgage baseline:
            20000.00
        *******************************************************************************************/
        20000.00::NUMERIC(18,2) AS product_review_max_requested_el,

        /*******************************************************************************************
        product_decline_min_requested_el:
            Severe requested-exposure Expected Loss threshold.

        Mortgage baseline:
            40000.00
        *******************************************************************************************/
        40000.00::NUMERIC(18,2) AS product_decline_min_requested_el,

        /*******************************************************************************************
        product_approved_el_cap:
            Approved-exposure Expected Loss cap used in counteroffer feasibility testing.

        Mortgage baseline:
            10000.00
        *******************************************************************************************/
        10000.00::NUMERIC(18,2) AS product_approved_el_cap,

        /*******************************************************************************************
        product_min_approved_amount:
            Minimum viable approved exposure for this product.

        Mortgage baseline:
            75000.00
        *******************************************************************************************/
        75000.00::NUMERIC(18,2) AS product_min_approved_amount,

        /*******************************************************************************************
        product_max_approved_amount:
            Maximum simulated approved exposure for this product.

        Mortgage baseline:
            800000.00
        *******************************************************************************************/
        800000.00::NUMERIC(18,2) AS product_max_approved_amount,

        /*******************************************************************************************
        counteroffer_allowed_flag:
            TRUE allows reduced-exposure treatment for this product.
        *******************************************************************************************/
        TRUE::BOOLEAN AS counteroffer_allowed_flag,

        /*******************************************************************************************
        manual_review_allowed_flag:
            TRUE allows unresolved manual-review outcome for this product.
        *******************************************************************************************/
        TRUE::BOOLEAN AS manual_review_allowed_flag,

        /*******************************************************************************************
        product_min_counteroffer_pct:
            Minimum counteroffer amount as a percentage of requested amount.

        Mortgage baseline:
            0.500000 means counteroffer must be at least 50% of requested amount.
        *******************************************************************************************/
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,

        /*******************************************************************************************
        product_max_exposure_reduction_pct:
            Maximum exposure reduction allowed for a viable counteroffer.

        Mortgage baseline:
            0.500000 means no more than 50% reduction from requested amount.
        *******************************************************************************************/
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,

        /*******************************************************************************************
        exposure_assignment_method:
            Method label used by Section 8 to select the feasible approved amount.

        Current allowed campaign value:
            'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'
        *******************************************************************************************/
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,

        /*******************************************************************************************
        approved_amount_rounding_increment:
            Rounding increment used for approved amount.

        Mortgage baseline:
            5000.00
        *******************************************************************************************/
        5000.00::NUMERIC(18,2) AS approved_amount_rounding_increment


    UNION ALL


    /***********************************************************************************************
    PRODUCT POLICY ROW — HELOC

    Business interpretation:
        Secured revolving exposure.

    Product-policy posture:
        Lower PTI tolerance than mortgage, but higher exposure range than small unsecured products.
    ***********************************************************************************************/
    SELECT
        'HELOC'::TEXT AS product_type,                                  -- product_type
        0.250000::NUMERIC(12,6) AS product_approve_max_pti,             -- clean requested PTI threshold
        0.350000::NUMERIC(12,6) AS product_review_max_pti,              -- review-zone requested PTI reference
        0.450000::NUMERIC(12,6) AS product_decline_min_pti,             -- severe requested PTI threshold
        0.220000::NUMERIC(12,6) AS counteroffer_target_pti,             -- target approved PTI for counteroffer testing

        8000.00::NUMERIC(18,2) AS product_approve_max_requested_el,     -- clean requested Expected Loss threshold
        16000.00::NUMERIC(18,2) AS product_review_max_requested_el,     -- requested Expected Loss review reference
        30000.00::NUMERIC(18,2) AS product_decline_min_requested_el,    -- severe requested Expected Loss threshold
        7000.00::NUMERIC(18,2) AS product_approved_el_cap,              -- approved Expected Loss cap

        10000.00::NUMERIC(18,2) AS product_min_approved_amount,         -- minimum viable approved exposure
        175000.00::NUMERIC(18,2) AS product_max_approved_amount,        -- maximum simulated approved exposure

        TRUE::BOOLEAN AS counteroffer_allowed_flag,                     -- allow reduced-exposure treatment
        TRUE::BOOLEAN AS manual_review_allowed_flag,                    -- allow unresolved manual review
        0.400000::NUMERIC(12,6) AS product_min_counteroffer_pct,        -- minimum counteroffer percentage
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,  -- maximum exposure reduction percentage
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        1000.00::NUMERIC(18,2) AS approved_amount_rounding_increment    -- approved amount rounding increment


    UNION ALL


    /***********************************************************************************************
    PRODUCT POLICY ROW — AUTO_LOAN

    Business interpretation:
        Secured installment exposure with moderate payment sensitivity.

    Product-policy posture:
        Tighter PTI and Expected Loss settings than mortgage because balance sizes are smaller and
        repayment terms are shorter.
    ***********************************************************************************************/
    SELECT
        'AUTO_LOAN'::TEXT AS product_type,                              -- product_type
        0.180000::NUMERIC(12,6) AS product_approve_max_pti,             -- clean requested PTI threshold
        0.280000::NUMERIC(12,6) AS product_review_max_pti,              -- review-zone requested PTI reference
        0.380000::NUMERIC(12,6) AS product_decline_min_pti,             -- severe requested PTI threshold
        0.160000::NUMERIC(12,6) AS counteroffer_target_pti,             -- target approved PTI for counteroffer testing

        3500.00::NUMERIC(18,2) AS product_approve_max_requested_el,     -- clean requested Expected Loss threshold
        7000.00::NUMERIC(18,2) AS product_review_max_requested_el,      -- requested Expected Loss review reference
        12000.00::NUMERIC(18,2) AS product_decline_min_requested_el,    -- severe requested Expected Loss threshold
        3000.00::NUMERIC(18,2) AS product_approved_el_cap,              -- approved Expected Loss cap

        5000.00::NUMERIC(18,2) AS product_min_approved_amount,          -- minimum viable approved exposure
        65000.00::NUMERIC(18,2) AS product_max_approved_amount,         -- maximum simulated approved exposure

        TRUE::BOOLEAN AS counteroffer_allowed_flag,                     -- allow reduced-exposure treatment
        TRUE::BOOLEAN AS manual_review_allowed_flag,                    -- allow unresolved manual review
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,        -- minimum counteroffer percentage
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,  -- maximum exposure reduction percentage
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        500.00::NUMERIC(18,2) AS approved_amount_rounding_increment     -- approved amount rounding increment


    UNION ALL


    /***********************************************************************************************
    PRODUCT POLICY ROW — UNSECURED_PERSONAL_LOAN

    Business interpretation:
        Smaller unsecured installment exposure.

    Product-policy posture:
        Higher loss severity and no collateral support justify tighter PTI tolerance, lower approved
        exposure cap, and lower approved Expected Loss cap.
    ***********************************************************************************************/
    SELECT
        'UNSECURED_PERSONAL_LOAN'::TEXT AS product_type,                -- product_type
        0.150000::NUMERIC(12,6) AS product_approve_max_pti,             -- clean requested PTI threshold
        0.250000::NUMERIC(12,6) AS product_review_max_pti,              -- review-zone requested PTI reference
        0.350000::NUMERIC(12,6) AS product_decline_min_pti,             -- severe requested PTI threshold
        0.130000::NUMERIC(12,6) AS counteroffer_target_pti,             -- target approved PTI for counteroffer testing

        3000.00::NUMERIC(18,2) AS product_approve_max_requested_el,     -- clean requested Expected Loss threshold
        6000.00::NUMERIC(18,2) AS product_review_max_requested_el,      -- requested Expected Loss review reference
        10000.00::NUMERIC(18,2) AS product_decline_min_requested_el,    -- severe requested Expected Loss threshold
        2500.00::NUMERIC(18,2) AS product_approved_el_cap,              -- approved Expected Loss cap

        1000.00::NUMERIC(18,2) AS product_min_approved_amount,          -- minimum viable approved exposure
        35000.00::NUMERIC(18,2) AS product_max_approved_amount,         -- maximum simulated approved exposure

        TRUE::BOOLEAN AS counteroffer_allowed_flag,                     -- allow reduced-exposure treatment
        TRUE::BOOLEAN AS manual_review_allowed_flag,                    -- allow unresolved manual review
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,        -- minimum counteroffer percentage
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,  -- maximum exposure reduction percentage
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        500.00::NUMERIC(18,2) AS approved_amount_rounding_increment     -- approved amount rounding increment


    UNION ALL


    /***********************************************************************************************
    PRODUCT POLICY ROW — REVOLVING_LINE

    Business interpretation:
        Unsecured revolving exposure.

    Product-policy posture:
        Highest structural caution in the baseline product policy because unsecured revolving exposure
        has high LGD and APR-sensitive payment proxy behavior upstream.
    ***********************************************************************************************/
    SELECT
        'REVOLVING_LINE'::TEXT AS product_type,                         -- product_type
        0.120000::NUMERIC(12,6) AS product_approve_max_pti,             -- clean requested PTI threshold
        0.200000::NUMERIC(12,6) AS product_review_max_pti,              -- review-zone requested PTI reference
        0.300000::NUMERIC(12,6) AS product_decline_min_pti,             -- severe requested PTI threshold
        0.100000::NUMERIC(12,6) AS counteroffer_target_pti,             -- target approved PTI for counteroffer testing

        2000.00::NUMERIC(18,2) AS product_approve_max_requested_el,     -- clean requested Expected Loss threshold
        4000.00::NUMERIC(18,2) AS product_review_max_requested_el,      -- requested Expected Loss review reference
        8000.00::NUMERIC(18,2) AS product_decline_min_requested_el,     -- severe requested Expected Loss threshold
        1800.00::NUMERIC(18,2) AS product_approved_el_cap,              -- approved Expected Loss cap

        1000.00::NUMERIC(18,2) AS product_min_approved_amount,          -- minimum viable approved exposure
        20000.00::NUMERIC(18,2) AS product_max_approved_amount,         -- maximum simulated approved exposure

        TRUE::BOOLEAN AS counteroffer_allowed_flag,                     -- allow reduced-exposure treatment
        TRUE::BOOLEAN AS manual_review_allowed_flag,                    -- allow unresolved manual review
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,        -- minimum counteroffer percentage
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,  -- maximum exposure reduction percentage
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        500.00::NUMERIC(18,2) AS approved_amount_rounding_increment     -- approved amount rounding increment
)

INSERT INTO tmp_module2_product_policy_params (
    product_type,

    product_approve_max_pti,
    product_review_max_pti,
    product_decline_min_pti,
    counteroffer_target_pti,

    product_approve_max_requested_el,
    product_review_max_requested_el,
    product_decline_min_requested_el,
    product_approved_el_cap,

    product_min_approved_amount,
    product_max_approved_amount,

    counteroffer_allowed_flag,
    manual_review_allowed_flag,
    product_min_counteroffer_pct,
    product_max_exposure_reduction_pct,
    exposure_assignment_method,
    approved_amount_rounding_increment
)
SELECT
    product_type,

    product_approve_max_pti,
    product_review_max_pti,
    product_decline_min_pti,
    counteroffer_target_pti,

    product_approve_max_requested_el,
    product_review_max_requested_el,
    product_decline_min_requested_el,
    product_approved_el_cap,

    product_min_approved_amount,
    product_max_approved_amount,

    counteroffer_allowed_flag,
    manual_review_allowed_flag,
    product_min_counteroffer_pct,
    product_max_exposure_reduction_pct,
    exposure_assignment_method,
    approved_amount_rounding_increment
FROM product_policy_seed;
```

These two replacements should make the main campaign-editable variables self-identifying at the line where you edit them, instead of forcing you to cross-reference the column list.
<!-- END_MESSAGE C038-M01242 -->


---

<a id="c038-m01244"></a>

### C038-M01244

**Andrew** · 2026-05-10T18:09:48.680000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01244 -->
can you provide specific recommendations for the affordability-tight product policy parameter values instead of saying reduce by ~2-5% while preserving ordering?  do the same for counteroffer-first product policy and product guardrail policy.
<!-- END_MESSAGE C038-M01244 -->


---

<a id="c038-m01248"></a>

### C038-M01248

**ChatGPT** · 2026-05-10T18:12:32.943719-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01248 -->
Yes. I would replace the vague overlay language with **specific product-policy profiles**. These values are designed to be campaign-operable: you can copy them into Section 2.4 when the active `strategy_name` calls for that profile.

The logic is consistent with your Module 2 design: Section 2 centralizes product-policy controls, Section 8 uses those controls for counteroffer feasibility, and Section 14 validates final counteroffer / exposure / PTI / Expected Loss behavior. fileciteturn177file0 fileciteturn177file47 fileciteturn177file14

## 1. Baseline product policy reference

Use this as the unchanged reference.

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Min counteroffer % | Max exposure reduction % | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `MORTGAGE` | 0.350000 | 0.450000 | 0.550000 | 0.320000 | 10000 | 20000 | 40000 | 10000 | 75000 | 800000 | 0.500000 | 0.500000 | 5000 |
| `HELOC` | 0.250000 | 0.350000 | 0.450000 | 0.220000 | 8000 | 16000 | 30000 | 7000 | 10000 | 175000 | 0.400000 | 0.500000 | 1000 |
| `AUTO_LOAN` | 0.180000 | 0.280000 | 0.380000 | 0.160000 | 3500 | 7000 | 12000 | 3000 | 5000 | 65000 | 0.500000 | 0.500000 | 500 |
| `UNSECURED_PERSONAL_LOAN` | 0.150000 | 0.250000 | 0.350000 | 0.130000 | 3000 | 6000 | 10000 | 2500 | 1000 | 35000 | 0.500000 | 0.500000 | 500 |
| `REVOLVING_LINE` | 0.120000 | 0.200000 | 0.300000 | 0.100000 | 2000 | 4000 | 8000 | 1800 | 1000 | 20000 | 0.500000 | 0.500000 | 500 |

---

# 2. Affordability-tight product policy

Use this profile for:

```text
TIGHTER_AFFORDABILITY_STRATEGY
```

## Design intent

This profile should isolate **affordability discipline**. It tightens product PTI thresholds and counteroffer target PTI while leaving exposure caps and Expected Loss thresholds unchanged.

That gives you a clean read on:

```text
What happens when the strategy is stricter about payment burden, without also tightening product exposure caps or Expected Loss caps?
```

## Recommended exact values

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Min counteroffer % | Max exposure reduction % | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `MORTGAGE` | 0.320000 | 0.420000 | 0.520000 | 0.290000 | 10000 | 20000 | 40000 | 10000 | 75000 | 800000 | 0.500000 | 0.500000 | 5000 |
| `HELOC` | 0.220000 | 0.320000 | 0.420000 | 0.190000 | 8000 | 16000 | 30000 | 7000 | 10000 | 175000 | 0.400000 | 0.500000 | 1000 |
| `AUTO_LOAN` | 0.160000 | 0.250000 | 0.350000 | 0.140000 | 3500 | 7000 | 12000 | 3000 | 5000 | 65000 | 0.500000 | 0.500000 | 500 |
| `UNSECURED_PERSONAL_LOAN` | 0.130000 | 0.220000 | 0.320000 | 0.110000 | 3000 | 6000 | 10000 | 2500 | 1000 | 35000 | 0.500000 | 0.500000 | 500 |
| `REVOLVING_LINE` | 0.100000 | 0.180000 | 0.280000 | 0.080000 | 2000 | 4000 | 8000 | 1800 | 1000 | 20000 | 0.500000 | 0.500000 | 500 |

## Expected behavior

This should generally increase:

```text
manual-review pressure
counteroffer pressure
PTI-related reason-code concentration
affordability REVIEW diagnostics
```

It should generally reduce or constrain:

```text
approval rate
approved PTI on offer rows
simulated offer exposure in high-PTI segments
```

---

# 3. Counteroffer-first product policy

Use this profile for:

```text
COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
```

## Design intent

This profile should push more rows toward **reduced-exposure treatment** instead of clean approval, while still keeping counteroffers feasible.

The important design choice is that we do **not** simply tighten everything. If the caps are too tight and the counteroffer feasibility rules are too restrictive, preliminary counteroffers will fail and route to `MANUAL_REVIEW` or `DECLINE`. So this profile tightens approved exposure and approved Expected Loss, but also allows somewhat larger reductions.

## Recommended exact values

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Min counteroffer % | Max exposure reduction % | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `MORTGAGE` | 0.330000 | 0.450000 | 0.550000 | 0.300000 | 8500 | 18000 | 40000 | 8000 | 75000 | 700000 | 0.400000 | 0.600000 | 5000 |
| `HELOC` | 0.235000 | 0.350000 | 0.450000 | 0.200000 | 6800 | 14500 | 30000 | 5600 | 10000 | 150000 | 0.350000 | 0.600000 | 1000 |
| `AUTO_LOAN` | 0.170000 | 0.280000 | 0.380000 | 0.145000 | 3000 | 6300 | 12000 | 2400 | 5000 | 57500 | 0.450000 | 0.550000 | 500 |
| `UNSECURED_PERSONAL_LOAN` | 0.140000 | 0.250000 | 0.350000 | 0.115000 | 2500 | 5400 | 10000 | 2000 | 1000 | 30000 | 0.400000 | 0.600000 | 500 |
| `REVOLVING_LINE` | 0.110000 | 0.200000 | 0.300000 | 0.090000 | 1700 | 3600 | 8000 | 1400 | 1000 | 17500 | 0.400000 | 0.600000 | 500 |

## Expected behavior

This should generally increase:

```text
counteroffer rate
counteroffer share of offers
exposure reduction amount
counteroffer reason-code concentration
approved amount capture discipline
```

It should generally reduce:

```text
clean approval rate
average approved amount on offer rows
approved Expected Loss
approved PTI on counteroffer rows
```

## Important QA focus

For this strategy, watch Section 14.11 closely. You want more counteroffer behavior, but you do **not** want an explosion of failed preliminary counteroffers.

Strong review triggers:

```text
high failed_counteroffers
low counteroffer_feasibility_pass_rate
COUNTEROFFER_BELOW_PRODUCT_MINIMUM concentration
COUNTEROFFER_PTI_STILL_ABOVE_TARGET concentration
COUNTEROFFER_APPROVED_EL_ABOVE_PRODUCT_CAP concentration
```

---

# 4. Product-specific guardrail policy

Use this profile for:

```text
PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
```

## Design intent

This profile should isolate product-specific tightening for unsecured / revolving risk pools.

Keep these products at baseline:

```text
MORTGAGE
HELOC
AUTO_LOAN
```

Tighten these products:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

This gives you a clean story:

```text
What happens when the strategy adds product-specific guardrails to higher-LGD unsecured and revolving exposure, while leaving secured and auto products largely unchanged?
```

## Recommended exact values

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Min counteroffer % | Max exposure reduction % | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `MORTGAGE` | 0.350000 | 0.450000 | 0.550000 | 0.320000 | 10000 | 20000 | 40000 | 10000 | 75000 | 800000 | 0.500000 | 0.500000 | 5000 |
| `HELOC` | 0.250000 | 0.350000 | 0.450000 | 0.220000 | 8000 | 16000 | 30000 | 7000 | 10000 | 175000 | 0.400000 | 0.500000 | 1000 |
| `AUTO_LOAN` | 0.180000 | 0.280000 | 0.380000 | 0.160000 | 3500 | 7000 | 12000 | 3000 | 5000 | 65000 | 0.500000 | 0.500000 | 500 |
| `UNSECURED_PERSONAL_LOAN` | 0.130000 | 0.220000 | 0.320000 | 0.110000 | 2500 | 5000 | 8500 | 2000 | 1000 | 27500 | 0.500000 | 0.500000 | 500 |
| `REVOLVING_LINE` | 0.100000 | 0.180000 | 0.280000 | 0.080000 | 1500 | 3200 | 6500 | 1400 | 1000 | 16000 | 0.500000 | 0.500000 | 500 |

## Expected behavior

This should generally increase tightening specifically in:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

You should expect movement in:

```text
unsecured approved amount share
revolving approved amount share
unsecured / revolving approved Expected Loss
product-specific counteroffer rates
product-specific decline rates
product-specific policy-stop or guardrail reason codes
```

You should **not** expect major direct changes in:

```text
MORTGAGE
HELOC
AUTO_LOAN
```

unless the broader strategy thresholds also move.

---

# 5. Profile summary table

| Profile | Main lever | Tightens PTI? | Tightens requested EL? | Tightens approved EL cap? | Tightens max approved amount? | Makes counteroffers easier? | Best used for |
|---|---|---:|---:|---:|---:|---:|---|
| Baseline | Reference | No | No | No | No | Neutral | Baseline comparison |
| Affordability-tight | PTI discipline | Yes | No | No | No | Neutral | Rate stress / affordability pressure |
| Counteroffer-first | Reduced-exposure treatment | Mildly | Yes | Yes | Yes | Yes | Exposure management / preserving access through smaller offers |
| Product guardrail | Product-specific unsecured / revolving controls | Yes for UPL + revolving | Yes for UPL + revolving | Yes for UPL + revolving | Yes for UPL + revolving | Neutral | Unsecured growth, revolving expansion, LGD stress |

---

# 6. How I would document these in Section 2

I would add a short profile note above Section 2.4:

```text
PRODUCT POLICY PROFILE SELECTION GUIDE

Use BASELINE_PRODUCT_POLICY for:
    BASELINE_STRATEGY
    TIGHTER_SYNTHETIC_RISK_STRATEGY
    MANUAL_REVIEW_REDUCTION_STRATEGY

Use AFFORDABILITY_TIGHT_PRODUCT_POLICY for:
    TIGHTER_AFFORDABILITY_STRATEGY

Use COUNTEROFFER_FIRST_PRODUCT_POLICY for:
    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY

Use PRODUCT_GUARDRAIL_POLICY for:
    PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
```

Then, when running each strategy, replace the Section 2.4 product values with the exact profile table above.
<!-- END_MESSAGE C038-M01248 -->


---

<a id="c038-m01249"></a>

### C038-M01249

**Andrew** · 2026-05-10T19:09:49.509000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01249 -->
help me trouble shoot this error while trying to run M2-29: SQL Error [P0001]: ERROR: Module 2 Section 3 failure: campaign_registry_required_flag = TRUE but current run key did not match exactly one active campaign registry row. Match status: RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW.
  Where: PL/pgSQL function inline_code_block line 33 at RAISE
  ERROR: Module 2 Section 3 failure: campaign_registry_required_flag = TRUE but current run key did not match exactly one active campaign registry row. Match status: RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW.
  Where: PL/pgSQL function inline_code_block line 33 at RAISE
<!-- END_MESSAGE C038-M01249 -->


---

<a id="c038-m01254"></a>

### C038-M01254

**ChatGPT** · 2026-05-10T19:12:39.064788-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01254 -->
According to a document from 2026-05-10, this is almost certainly a **scenario-set-name mismatch in the campaign registry**, not a problem with the M2-29 product-policy values.

Section 3 is doing exactly what we designed it to do: when `campaign_registry_required_flag = TRUE`, the active technical run key must match **exactly one active row** in `credit_decisioning_sim.strategy_run_campaign_registry`; otherwise it raises the failure you saw. The fail-fast logic explicitly raises this error when `registry_match_count <> 1`. fileciteturn178file3

For **M2-29**, your active parameter row is probably using the corrected locked Module 1 scenario set:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

But the registry row in the retrieved Module 2 code still shows M2-29 using the older name:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SET
```

The retrieved M2-29 registry row is:

```text
module1_run_id: M1-14
module2_run_id: M2-29
module1_scenario_set_name: MODULE1_V2_EXPOSURE_INTENSITY_SET
module1_scenario_name: HIGH_BALANCE_APPETITE
strategy_name: COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
```

That old scenario-set value would cause `RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW` once your active strategy params use the corrected `_SENSITIVITY_SET` name. fileciteturn178file6

## Expected M2-29 technical run key

For M2-29, the active strategy row and campaign registry row should match this exactly:

```text
source_module1_scenario_set_name / module1_scenario_set_name:
    MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET

source_module1_scenario_name / module1_scenario_name:
    HIGH_BALANCE_APPETITE

source_population_id / population_id:
    BASE_POPULATION_V1

strategy_set_name:
    MODULE2_BASELINE_STRATEGY_SET

strategy_name:
    COUNTEROFFER_FIRST_EXPOSURE_STRATEGY

strategy_version:
    V1_0
```

## Step 1 — Confirm the active strategy parameter row

Run this after Section 2 and before Section 3:

```sql
SELECT
    active_strategy_flag,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,

    campaign_registry_required_flag,

    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,

    archive_run_flag,
    strategy_archive_reset_mode
FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;
```

For M2-29, confirm you see:

```text
strategy_name = COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
source_module1_scenario_set_name = MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
source_module1_scenario_name = HIGH_BALANCE_APPETITE
source_population_id = BASE_POPULATION_V1
campaign_registry_required_flag = TRUE
```

## Step 2 — Inspect the persistent registry row for M2-29

```sql
SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,

    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    registry_active_flag,
    registry_created_ts,
    registry_updated_ts
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id = 'M2-29';
```

If this shows:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SET
```

instead of:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

that is the cause.

## Step 3 — Run the exact match diagnostic

This tells you whether the active parameter row can match the registry.

```sql
WITH active_run_key AS (
    SELECT
        source_module1_scenario_set_name AS module1_scenario_set_name,
        source_module1_scenario_name AS module1_scenario_name,
        source_population_id AS population_id,

        strategy_set_name,
        strategy_name,
        strategy_version,

        campaign_registry_required_flag
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
),

registry_matches AS (
    SELECT
        r.*
    FROM credit_decisioning_sim.strategy_run_campaign_registry r
    JOIN active_run_key k
        ON r.module1_scenario_set_name = k.module1_scenario_set_name
       AND r.module1_scenario_name = k.module1_scenario_name
       AND r.population_id = k.population_id
       AND r.strategy_set_name = k.strategy_set_name
       AND r.strategy_name = k.strategy_name
       AND r.strategy_version = k.strategy_version
    WHERE r.registry_active_flag IS TRUE
)

SELECT
    k.module1_scenario_set_name AS active_param_module1_scenario_set_name,
    k.module1_scenario_name AS active_param_module1_scenario_name,
    k.population_id AS active_param_population_id,
    k.strategy_set_name AS active_param_strategy_set_name,
    k.strategy_name AS active_param_strategy_name,
    k.strategy_version AS active_param_strategy_version,
    k.campaign_registry_required_flag,

    COUNT(r.*) AS exact_active_registry_match_count,

    CASE
        WHEN COUNT(r.*) = 1
            THEN 'RUN_REGISTRY_MATCHED'
        WHEN COUNT(r.*) = 0 AND k.campaign_registry_required_flag IS TRUE
            THEN 'RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW'
        WHEN COUNT(r.*) > 1
            THEN 'RUN_REGISTRY_DUPLICATE_MATCH_REVIEW_REQUIRED'
        ELSE 'RUN_REGISTRY_MATCH_STATUS_REVIEW'
    END AS diagnostic_match_status
FROM active_run_key k
LEFT JOIN registry_matches r
    ON TRUE
GROUP BY
    k.module1_scenario_set_name,
    k.module1_scenario_name,
    k.population_id,
    k.strategy_set_name,
    k.strategy_name,
    k.strategy_version,
    k.campaign_registry_required_flag;
```

Expected after the fix:

```text
exact_active_registry_match_count = 1
diagnostic_match_status = RUN_REGISTRY_MATCHED
```

## Step 4 — Patch SC05 campaign registry rows

Because we standardized SC05 to:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

patch all SC05 M2 rows, not just M2-29.

```sql
BEGIN;

/* Preview current SC05 campaign registry rows. */
SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
ORDER BY run_sequence_number;


/* Patch old SC05 scenario-set name to canonical scenario-set name. */
UPDATE credit_decisioning_sim.strategy_run_campaign_registry
SET
    module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET',
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
  AND module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SET'
RETURNING
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag;


/* Verify patched SC05 campaign registry rows. */
SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
ORDER BY run_sequence_number;

COMMIT;
```

Important: also patch the **canonical Section 2.6 SQL text**. If Section 2.6 still contains the old string, rerunning the full script can upsert the old value back into the registry. Section 2.6 uses `INSERT ... ON CONFLICT (module2_run_id) DO UPDATE`, so the script itself can overwrite your manual database patch if the SQL file still has the old value. The registry seeding block is intentionally rerunnable and updates existing run IDs when they already exist. fileciteturn178file0

In Section 2.6, replace this for M2-27 through M2-30:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SET'
```

with:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
```

## Step 5 — Patch CG15 comparison registry too

This does not cause the Section 3 error, but it will matter later for Section 13 matched comparison.

```sql
BEGIN;

/* Preview CG15. */
SELECT
    comparison_group_id,
    comparison_set_name,
    baseline_module2_run_id,
    challenger_module2_run_id,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    baseline_strategy_name,
    challenger_strategy_name,
    active_comparison_flag,
    registry_active_flag
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE comparison_group_id = 'CG15';


/* Patch CG15 to canonical SC05 scenario-set name. */
UPDATE credit_decisioning_sim.strategy_comparison_campaign_registry
SET
    module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET',
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE comparison_group_id = 'CG15'
  AND module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SET'
RETURNING
    comparison_group_id,
    comparison_set_name,
    baseline_module2_run_id,
    challenger_module2_run_id,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    baseline_strategy_name,
    challenger_strategy_name,
    active_comparison_flag,
    registry_active_flag;

COMMIT;
```

The comparison registry is the governed selection layer for Section 13; it stores `comparison_group_id`, baseline/challenger run IDs, baseline/challenger strategy keys, and the matched Module 1 scenario / population key. fileciteturn179file6

Also patch the **canonical Section 2.8 / comparison registry seed** for CG15 if it still uses the old name.

## Step 6 — Confirm the Module 1 source archive exists

Since M2-29 consumes `HIGH_BALANCE_APPETITE`, make sure the corrected Module 1 archive slice exists:

```sql
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS archived_rows
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
  AND scenario_name = 'HIGH_BALANCE_APPETITE'
  AND population_id = 'BASE_POPULATION_V1'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id;
```

Expected:

```text
archived_rows = 50000
```

## Step 7 — Rerun from Section 1 or Section 2

After patching the canonical SQL and/or the live registry table, rerun the Module 2 file. Section 3 should now match M2-29 to one active campaign registry row.

For M2-29, the critical fields should reconcile as:

```text
tmp_module2_strategy_params:
    source_module1_scenario_set_name = MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
    source_module1_scenario_name     = HIGH_BALANCE_APPETITE
    source_population_id             = BASE_POPULATION_V1
    strategy_set_name                = MODULE2_BASELINE_STRATEGY_SET
    strategy_name                    = COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
    strategy_version                 = V1_0

strategy_run_campaign_registry:
    module1_scenario_set_name        = MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
    module1_scenario_name            = HIGH_BALANCE_APPETITE
    population_id                    = BASE_POPULATION_V1
    strategy_set_name                = MODULE2_BASELINE_STRATEGY_SET
    strategy_name                    = COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
    strategy_version                 = V1_0
    registry_active_flag             = TRUE
```

The most likely fix is: **replace the old SC05 scenario-set name in Section 2.6 and Section 2.8, then rerun.**
<!-- END_MESSAGE C038-M01254 -->


---

<a id="c038-m01255"></a>

### C038-M01255

**Andrew** · 2026-05-10T19:16:35.711000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01255 -->
module1 archive has: MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET and HIGH_BALANCE_APPETITE - which is what I had in my module 2.2 parameter section.
<!-- END_MESSAGE C038-M01255 -->


---

<a id="c038-m01258"></a>

### C038-M01258

**ChatGPT** · 2026-05-10T19:19:00.887715-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01258 -->
According to a document from 2026-05-10, that narrows the issue: if the Module 1 archive has `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET / HIGH_BALANCE_APPETITE` and your Section 2.2 active strategy parameter row has the same values, then the problem is almost certainly the **persistent Module 2 campaign registry row**, not the Module 1 archive or the active source-selection parameters.

Section 3 is failing before Module 2 consumes the Module 1 archive. It checks whether the active technical run key matches exactly one active row in `credit_decisioning_sim.strategy_run_campaign_registry`. The registry table is keyed by the technical fields `module1_scenario_set_name`, `module1_scenario_name`, `population_id`, `strategy_set_name`, `strategy_name`, and `strategy_version`, with `module2_run_id` as the compact run identifier. fileciteturn181file8

The key detail: your uploaded registry seed still shows SC05 rows using the old scenario set name in at least the comparison registry, and an earlier patched registry seed shows M2-29 itself using the old value:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SET
```

instead of:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

For M2-29, the retrieved seed row shows:

```text
M2-29
HIGH_BALANCE_APPETITE
COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
MODULE1_V2_EXPOSURE_INTENSITY_SET
```

which would not match your corrected Section 2.2 active key. fileciteturn182file15

Also, Section 2.6 uses `INSERT ... ON CONFLICT (module2_run_id) DO UPDATE`, meaning if the canonical SQL still contains the old SC05 value, rerunning Section 2 can overwrite a manual database patch and put the old value back into the persistent registry. fileciteturn181file0

## Run this first: exact active parameter vs registry diagnostic

Run this after Section 2 and before Section 3, in the same session where the temp table exists.

```sql
/***************************************************************************************************
M2-29 REGISTRY MATCH DIAGNOSTIC

Purpose:
    Compare the active tmp_module2_strategy_params technical run key to the persistent M2-29
    campaign registry row.

Expected:
    All mismatch flags should be FALSE.
    exact_active_registry_match_count should be 1.
***************************************************************************************************/

WITH active_params AS (
    SELECT
        source_module1_scenario_set_name,
        source_module1_scenario_name,
        source_population_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        campaign_registry_required_flag
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
),

m2_29_registry AS (
    SELECT
        module1_run_id,
        module2_run_id,
        run_sequence_number,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        registry_active_flag
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE module2_run_id = 'M2-29'
),

exact_registry_match AS (
    SELECT
        COUNT(*) AS exact_active_registry_match_count
    FROM credit_decisioning_sim.strategy_run_campaign_registry r
    CROSS JOIN active_params p
    WHERE r.registry_active_flag IS TRUE
      AND r.module1_scenario_set_name = p.source_module1_scenario_set_name
      AND r.module1_scenario_name = p.source_module1_scenario_name
      AND r.population_id = p.source_population_id
      AND r.strategy_set_name = p.strategy_set_name
      AND r.strategy_name = p.strategy_name
      AND r.strategy_version = p.strategy_version
)

SELECT
    p.strategy_run_id,
    p.campaign_registry_required_flag,

    r.module2_run_id,
    r.registry_active_flag,

    p.source_module1_scenario_set_name AS active_param_scenario_set_name,
    r.module1_scenario_set_name AS registry_scenario_set_name,
    r.module1_scenario_set_name IS DISTINCT FROM p.source_module1_scenario_set_name
        AS scenario_set_name_mismatch,

    p.source_module1_scenario_name AS active_param_scenario_name,
    r.module1_scenario_name AS registry_scenario_name,
    r.module1_scenario_name IS DISTINCT FROM p.source_module1_scenario_name
        AS scenario_name_mismatch,

    p.source_population_id AS active_param_population_id,
    r.population_id AS registry_population_id,
    r.population_id IS DISTINCT FROM p.source_population_id
        AS population_id_mismatch,

    p.strategy_set_name AS active_param_strategy_set_name,
    r.strategy_set_name AS registry_strategy_set_name,
    r.strategy_set_name IS DISTINCT FROM p.strategy_set_name
        AS strategy_set_name_mismatch,

    p.strategy_name AS active_param_strategy_name,
    r.strategy_name AS registry_strategy_name,
    r.strategy_name IS DISTINCT FROM p.strategy_name
        AS strategy_name_mismatch,

    p.strategy_version AS active_param_strategy_version,
    r.strategy_version AS registry_strategy_version,
    r.strategy_version IS DISTINCT FROM p.strategy_version
        AS strategy_version_mismatch,

    e.exact_active_registry_match_count,

    CASE
        WHEN e.exact_active_registry_match_count = 1
            THEN 'RUN_REGISTRY_MATCHED'
        WHEN e.exact_active_registry_match_count = 0
            THEN 'RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW'
        ELSE 'RUN_REGISTRY_DUPLICATE_MATCH_REVIEW_REQUIRED'
    END AS diagnostic_match_status

FROM active_params p
LEFT JOIN m2_29_registry r
    ON TRUE
CROSS JOIN exact_registry_match e;
```

The likely bad output will be:

```text
scenario_set_name_mismatch = true
registry_scenario_set_name = MODULE1_V2_EXPOSURE_INTENSITY_SET
active_param_scenario_set_name = MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
exact_active_registry_match_count = 0
```

## Patch the live campaign registry

If that diagnostic confirms the mismatch, patch the SC05 registry rows:

```sql
BEGIN;

/* Preview current SC05 rows. */
SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
ORDER BY run_sequence_number;


/* Patch SC05 to the canonical scenario set name. */
UPDATE credit_decisioning_sim.strategy_run_campaign_registry
SET
    module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET',
    registry_active_flag = TRUE,
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
  AND module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SET'
RETURNING
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag;

COMMIT;
```

Then patch CG15 too, because Section 13 comparison will need it later:

```sql
BEGIN;

UPDATE credit_decisioning_sim.strategy_comparison_campaign_registry
SET
    module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET',
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE comparison_group_id = 'CG15'
  AND module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SET'
RETURNING
    comparison_group_id,
    baseline_module2_run_id,
    challenger_module2_run_id,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    baseline_strategy_name,
    challenger_strategy_name,
    active_comparison_flag,
    registry_active_flag;

COMMIT;
```

## Patch the canonical SQL too

Do not rely only on the database update. Patch Section 2.6 and Section 2.8 in the SQL file, otherwise rerunning the full file can re-upsert the old value.

Replace every SC05 occurrence of:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SET'
```

with:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
```

At minimum, this applies to:

```text
M2-27
M2-28
M2-29
M2-30
CG15
```

Your Section 2.2 and Module 1 archive can both be correct and Section 3 can still fail if Section 2.6’s persistent registry row is stale. Section 3 is matching the active run key against the registry; it is not simply checking that the Module 1 archive slice exists.

After patching, rerun the exact diagnostic. You want:

```text
exact_active_registry_match_count = 1
diagnostic_match_status = RUN_REGISTRY_MATCHED
```

Then rerun Section 3.
<!-- END_MESSAGE C038-M01258 -->


---

<a id="c038-m01259"></a>

### C038-M01259

**Andrew** · 2026-05-10T19:23:15.783000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01259 -->
results attached
<!-- END_MESSAGE C038-M01259 -->


**Attachments in export:** `_M2_29_REGISTRY_MATCH_DIAGNOSTIC_Purpose_Compare_the_active_tmp__202605101922.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m01261"></a>

### C038-M01261

**ChatGPT** · 2026-05-10T19:25:53.161148-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01261 -->
The attached diagnostic confirms the cause exactly: **your active Section 2.2 parameter row is correct, but the persistent campaign registry row for M2-29 is still using the old SC05 scenario-set name**. The only mismatch is `scenario_set_name`; everything else matches. fileciteturn182file0

Your diagnostic shows:

| Field | Active parameter value | Registry value | Status |
|---|---|---|---|
| Scenario set | `MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET` | `MODULE1_V2_EXPOSURE_INTENSITY_SET` | **Mismatch** |
| Scenario name | `HIGH_BALANCE_APPETITE` | `HIGH_BALANCE_APPETITE` | Match |
| Population | `BASE_POPULATION_V1` | `BASE_POPULATION_V1` | Match |
| Strategy set | `MODULE2_BASELINE_STRATEGY_SET` | `MODULE2_BASELINE_STRATEGY_SET` | Match |
| Strategy name | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | `COUNTEROFFER_FIRST_EXPOSURE_STRATEGY` | Match |
| Strategy version | `V1_0` | `V1_0` | Match |

The decisive fields are:

```text
scenario_set_name_mismatch = TRUE
exact_active_registry_match_count = 0
diagnostic_match_status = RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW
```

So the error is not Module 1 archive availability and not the active M2-29 strategy parameters. It is the **M2-29 campaign registry row** still carrying:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SET
```

instead of:

```text
MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET
```

## Patch the live registry rows

Run this:

```sql
BEGIN;

/*-----------------------------------------------------------------------------------------------
Preview current SC05 Module 2 campaign registry rows.

Expected before patch:
    M2-27 through M2-30 may still show MODULE1_V2_EXPOSURE_INTENSITY_SET.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
ORDER BY run_sequence_number;


/*-----------------------------------------------------------------------------------------------
Patch SC05 campaign registry rows to the canonical scenario-set name.
-----------------------------------------------------------------------------------------------*/

UPDATE credit_decisioning_sim.strategy_run_campaign_registry
SET
    module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET',
    registry_active_flag = TRUE,
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
  AND module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SET'
RETURNING
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag;


/*-----------------------------------------------------------------------------------------------
Verify patched SC05 campaign registry rows.

Expected after patch:
    M2-27 through M2-30 should show MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id IN ('M2-27', 'M2-28', 'M2-29', 'M2-30')
ORDER BY run_sequence_number;

COMMIT;
```

## Patch CG15 comparison registry too

This will not fix the Section 3 failure directly, but it prevents Section 13 from failing or selecting the wrong comparison later.

```sql
BEGIN;

/* Preview CG15 before patch. */
SELECT
    comparison_group_id,
    comparison_set_name,
    baseline_module2_run_id,
    challenger_module2_run_id,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    baseline_strategy_name,
    challenger_strategy_name,
    active_comparison_flag,
    registry_active_flag
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE comparison_group_id = 'CG15';


/* Patch CG15 to canonical SC05 scenario-set name. */
UPDATE credit_decisioning_sim.strategy_comparison_campaign_registry
SET
    module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET',
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE comparison_group_id = 'CG15'
  AND module1_scenario_set_name = 'MODULE1_V2_EXPOSURE_INTENSITY_SET'
RETURNING
    comparison_group_id,
    comparison_set_name,
    baseline_module2_run_id,
    challenger_module2_run_id,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    baseline_strategy_name,
    challenger_strategy_name,
    active_comparison_flag,
    registry_active_flag;

COMMIT;
```

## Patch the canonical SQL file too

This is important. If Section 2.6 / Section 2.8 in your SQL file still contains the old SC05 string, rerunning the full file can re-seed or update the persistent registry back to the wrong value.

Search the full Module 2 SQL for:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SET'
```

Replace every SC05 occurrence with:

```sql
'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET'
```

At minimum, update:

```text
M2-27
M2-28
M2-29
M2-30
CG15
```

## Rerun the diagnostic

After the live patch and canonical SQL patch, rerun the M2-29 diagnostic. Expected result:

```text
scenario_set_name_mismatch = FALSE
exact_active_registry_match_count = 1
diagnostic_match_status = RUN_REGISTRY_MATCHED
```

Then rerun Section 3. The prior failure should clear.
<!-- END_MESSAGE C038-M01261 -->


---

<a id="c038-m01263"></a>

### C038-M01263

**Andrew** · 2026-05-10T19:59:43.499000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01263 -->
please give me exact parameter values for this again.  I'm not sure what you had above is accurate: Product-guardrail policy
PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY
UNSECURED_PERSONAL_LOAN, REVOLVING_LINE
Tighten unsecured / revolving caps: UPL max approved amount toward 25000–30000, UPL approved EL cap toward 2000; revolving max approved amount toward 15000–18000, revolving approved EL cap toward 1200–1500
<!-- END_MESSAGE C038-M01263 -->


---

<a id="c038-m01265"></a>

### C038-M01265

**ChatGPT** · 2026-05-10T20:01:59.217488-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01265 -->
Yes. For **`PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY`**, I would use the following as the **exact canonical product-guardrail policy**.

Important first point: this policy is **not** for M2-29. M2-29 is:

```text
COUNTEROFFER_FIRST_EXPOSURE_STRATEGY
```

The **product-guardrail policy** should be used for:

```text
M2-06
M2-23
M2-26
M2-34
M2-36
```

The design intent is to keep the secured / auto products at baseline and tighten only:

```text
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

That keeps the test clean: the strategy is asking, “What happens when we apply product-specific guardrails to higher-LGD unsecured and revolving exposure?” Section 2 is the governed product-policy layer, Section 8 uses those product controls for exposure and counteroffer feasibility, and Section 14 validates the final counteroffer / affordability / approved Expected Loss conventions. fileciteturn182file0 fileciteturn182file56 fileciteturn182file14

## Exact product-guardrail policy values

| Product | Approve PTI | Review PTI | Decline PTI | Counteroffer target PTI | Approve max requested EL | Review max requested EL | Decline min requested EL | Approved EL cap | Min approved amount | Max approved amount | Min counteroffer % | Max exposure reduction % | Rounding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `MORTGAGE` | `0.350000` | `0.450000` | `0.550000` | `0.320000` | `10000.00` | `20000.00` | `40000.00` | `10000.00` | `75000.00` | `800000.00` | `0.500000` | `0.500000` | `5000.00` |
| `HELOC` | `0.250000` | `0.350000` | `0.450000` | `0.220000` | `8000.00` | `16000.00` | `30000.00` | `7000.00` | `10000.00` | `175000.00` | `0.400000` | `0.500000` | `1000.00` |
| `AUTO_LOAN` | `0.180000` | `0.280000` | `0.380000` | `0.160000` | `3500.00` | `7000.00` | `12000.00` | `3000.00` | `5000.00` | `65000.00` | `0.500000` | `0.500000` | `500.00` |
| `UNSECURED_PERSONAL_LOAN` | `0.130000` | `0.220000` | `0.320000` | `0.110000` | `2500.00` | `5000.00` | `8500.00` | `2000.00` | `1000.00` | `27500.00` | `0.500000` | `0.500000` | `500.00` |
| `REVOLVING_LINE` | `0.100000` | `0.180000` | `0.280000` | `0.080000` | `1500.00` | `3200.00` | `6500.00` | `1400.00` | `1000.00` | `16000.00` | `0.500000` | `0.500000` | `500.00` |

## What changed versus baseline

Only these two products change:

| Product | Field | Baseline | Product-guardrail value |
|---|---|---:|---:|
| `UNSECURED_PERSONAL_LOAN` | Approve PTI | `0.150000` | `0.130000` |
| `UNSECURED_PERSONAL_LOAN` | Review PTI | `0.250000` | `0.220000` |
| `UNSECURED_PERSONAL_LOAN` | Decline PTI | `0.350000` | `0.320000` |
| `UNSECURED_PERSONAL_LOAN` | Counteroffer target PTI | `0.130000` | `0.110000` |
| `UNSECURED_PERSONAL_LOAN` | Approve max requested EL | `3000.00` | `2500.00` |
| `UNSECURED_PERSONAL_LOAN` | Review max requested EL | `6000.00` | `5000.00` |
| `UNSECURED_PERSONAL_LOAN` | Decline min requested EL | `10000.00` | `8500.00` |
| `UNSECURED_PERSONAL_LOAN` | Approved EL cap | `2500.00` | `2000.00` |
| `UNSECURED_PERSONAL_LOAN` | Max approved amount | `35000.00` | `27500.00` |
| `REVOLVING_LINE` | Approve PTI | `0.120000` | `0.100000` |
| `REVOLVING_LINE` | Review PTI | `0.200000` | `0.180000` |
| `REVOLVING_LINE` | Decline PTI | `0.300000` | `0.280000` |
| `REVOLVING_LINE` | Counteroffer target PTI | `0.100000` | `0.080000` |
| `REVOLVING_LINE` | Approve max requested EL | `2000.00` | `1500.00` |
| `REVOLVING_LINE` | Review max requested EL | `4000.00` | `3200.00` |
| `REVOLVING_LINE` | Decline min requested EL | `8000.00` | `6500.00` |
| `REVOLVING_LINE` | Approved EL cap | `1800.00` | `1400.00` |
| `REVOLVING_LINE` | Max approved amount | `20000.00` | `16000.00` |

I would **not** change `product_min_counteroffer_pct` or `product_max_exposure_reduction_pct` for this profile. Keeping those at baseline isolates the test to **product guardrails**, not counteroffer mechanics.

## Copy-paste product policy seed for `PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY`

Use this as the exact Section 2.4 product-policy profile when running product-guardrail strategy runs.

```sql
WITH product_policy_seed AS (

    SELECT
        'MORTGAGE'::TEXT AS product_type,

        0.350000::NUMERIC(12,6) AS product_approve_max_pti,
        0.450000::NUMERIC(12,6) AS product_review_max_pti,
        0.550000::NUMERIC(12,6) AS product_decline_min_pti,
        0.320000::NUMERIC(12,6) AS counteroffer_target_pti,

        10000.00::NUMERIC(18,2) AS product_approve_max_requested_el,
        20000.00::NUMERIC(18,2) AS product_review_max_requested_el,
        40000.00::NUMERIC(18,2) AS product_decline_min_requested_el,
        10000.00::NUMERIC(18,2) AS product_approved_el_cap,

        75000.00::NUMERIC(18,2) AS product_min_approved_amount,
        800000.00::NUMERIC(18,2) AS product_max_approved_amount,

        TRUE::BOOLEAN AS counteroffer_allowed_flag,
        TRUE::BOOLEAN AS manual_review_allowed_flag,
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        5000.00::NUMERIC(18,2) AS approved_amount_rounding_increment

    UNION ALL

    SELECT
        'HELOC'::TEXT AS product_type,

        0.250000::NUMERIC(12,6) AS product_approve_max_pti,
        0.350000::NUMERIC(12,6) AS product_review_max_pti,
        0.450000::NUMERIC(12,6) AS product_decline_min_pti,
        0.220000::NUMERIC(12,6) AS counteroffer_target_pti,

        8000.00::NUMERIC(18,2) AS product_approve_max_requested_el,
        16000.00::NUMERIC(18,2) AS product_review_max_requested_el,
        30000.00::NUMERIC(18,2) AS product_decline_min_requested_el,
        7000.00::NUMERIC(18,2) AS product_approved_el_cap,

        10000.00::NUMERIC(18,2) AS product_min_approved_amount,
        175000.00::NUMERIC(18,2) AS product_max_approved_amount,

        TRUE::BOOLEAN AS counteroffer_allowed_flag,
        TRUE::BOOLEAN AS manual_review_allowed_flag,
        0.400000::NUMERIC(12,6) AS product_min_counteroffer_pct,
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        1000.00::NUMERIC(18,2) AS approved_amount_rounding_increment

    UNION ALL

    SELECT
        'AUTO_LOAN'::TEXT AS product_type,

        0.180000::NUMERIC(12,6) AS product_approve_max_pti,
        0.280000::NUMERIC(12,6) AS product_review_max_pti,
        0.380000::NUMERIC(12,6) AS product_decline_min_pti,
        0.160000::NUMERIC(12,6) AS counteroffer_target_pti,

        3500.00::NUMERIC(18,2) AS product_approve_max_requested_el,
        7000.00::NUMERIC(18,2) AS product_review_max_requested_el,
        12000.00::NUMERIC(18,2) AS product_decline_min_requested_el,
        3000.00::NUMERIC(18,2) AS product_approved_el_cap,

        5000.00::NUMERIC(18,2) AS product_min_approved_amount,
        65000.00::NUMERIC(18,2) AS product_max_approved_amount,

        TRUE::BOOLEAN AS counteroffer_allowed_flag,
        TRUE::BOOLEAN AS manual_review_allowed_flag,
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        500.00::NUMERIC(18,2) AS approved_amount_rounding_increment

    UNION ALL

    SELECT
        'UNSECURED_PERSONAL_LOAN'::TEXT AS product_type,

        0.130000::NUMERIC(12,6) AS product_approve_max_pti,
        0.220000::NUMERIC(12,6) AS product_review_max_pti,
        0.320000::NUMERIC(12,6) AS product_decline_min_pti,
        0.110000::NUMERIC(12,6) AS counteroffer_target_pti,

        2500.00::NUMERIC(18,2) AS product_approve_max_requested_el,
        5000.00::NUMERIC(18,2) AS product_review_max_requested_el,
        8500.00::NUMERIC(18,2) AS product_decline_min_requested_el,
        2000.00::NUMERIC(18,2) AS product_approved_el_cap,

        1000.00::NUMERIC(18,2) AS product_min_approved_amount,
        27500.00::NUMERIC(18,2) AS product_max_approved_amount,

        TRUE::BOOLEAN AS counteroffer_allowed_flag,
        TRUE::BOOLEAN AS manual_review_allowed_flag,
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        500.00::NUMERIC(18,2) AS approved_amount_rounding_increment

    UNION ALL

    SELECT
        'REVOLVING_LINE'::TEXT AS product_type,

        0.100000::NUMERIC(12,6) AS product_approve_max_pti,
        0.180000::NUMERIC(12,6) AS product_review_max_pti,
        0.280000::NUMERIC(12,6) AS product_decline_min_pti,
        0.080000::NUMERIC(12,6) AS counteroffer_target_pti,

        1500.00::NUMERIC(18,2) AS product_approve_max_requested_el,
        3200.00::NUMERIC(18,2) AS product_review_max_requested_el,
        6500.00::NUMERIC(18,2) AS product_decline_min_requested_el,
        1400.00::NUMERIC(18,2) AS product_approved_el_cap,

        1000.00::NUMERIC(18,2) AS product_min_approved_amount,
        16000.00::NUMERIC(18,2) AS product_max_approved_amount,

        TRUE::BOOLEAN AS counteroffer_allowed_flag,
        TRUE::BOOLEAN AS manual_review_allowed_flag,
        0.500000::NUMERIC(12,6) AS product_min_counteroffer_pct,
        0.500000::NUMERIC(12,6) AS product_max_exposure_reduction_pct,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT AS exposure_assignment_method,
        500.00::NUMERIC(18,2) AS approved_amount_rounding_increment
)

INSERT INTO tmp_module2_product_policy_params (
    product_type,

    product_approve_max_pti,
    product_review_max_pti,
    product_decline_min_pti,
    counteroffer_target_pti,

    product_approve_max_requested_el,
    product_review_max_requested_el,
    product_decline_min_requested_el,
    product_approved_el_cap,

    product_min_approved_amount,
    product_max_approved_amount,

    counteroffer_allowed_flag,
    manual_review_allowed_flag,
    product_min_counteroffer_pct,
    product_max_exposure_reduction_pct,
    exposure_assignment_method,
    approved_amount_rounding_increment
)
SELECT
    product_type,

    product_approve_max_pti,
    product_review_max_pti,
    product_decline_min_pti,
    counteroffer_target_pti,

    product_approve_max_requested_el,
    product_review_max_requested_el,
    product_decline_min_requested_el,
    product_approved_el_cap,

    product_min_approved_amount,
    product_max_approved_amount,

    counteroffer_allowed_flag,
    manual_review_allowed_flag,
    product_min_counteroffer_pct,
    product_max_exposure_reduction_pct,
    exposure_assignment_method,
    approved_amount_rounding_increment
FROM product_policy_seed;
```

For this strategy, keep the **strategy-level global thresholds** at the baseline values. The product-specific effect should come from the product-policy rows, not from changing global synthetic-risk thresholds.
<!-- END_MESSAGE C038-M01265 -->


---

<a id="c038-m01267"></a>

### C038-M01267

**Andrew** · 2026-05-11T09:02:23.130000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01267 -->
while running m2-21: SQL Error [P0001]: ERROR: Module 2 Section 3 failure: campaign_registry_required_flag = TRUE but current run key did not match exactly one active campaign registry row. Match status: RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW.
  Where: PL/pgSQL function inline_code_block line 33 at RAISE
  ERROR: Module 2 Section 3 failure: campaign_registry_required_flag = TRUE but current run key did not match exactly one active campaign registry row. Match status: RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW.
  Where: PL/pgSQL function inline_code_block line 33 at RAISE
<!-- END_MESSAGE C038-M01267 -->


---

<a id="c038-m01270"></a>

### C038-M01270

**ChatGPT** · 2026-05-11T09:04:13.811488-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01270 -->
According to a document from 2026-05-10, this M2-21 error is almost certainly the same class of issue as M2-29: **the active Section 2.2 run key does not exactly match the persistent campaign registry row**. For M2-21, the likely mismatch is the **Module 1 scenario name**.

Your locked Module 1 archive uses:

```text
MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET
PORTFOLIO_MIX_BASELINE_REFERENCE
BASE_POPULATION_V1
```

But your current Module 2 campaign registry seed still shows **M2-21** as:

```text
MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET
PRODUCT_MIX_BASELINE_REFERENCE
BASE_POPULATION_V1
```

That `PRODUCT_MIX_BASELINE_REFERENCE` value will not match if your active Section 2.2 parameter row correctly uses `PORTFOLIO_MIX_BASELINE_REFERENCE`. The retrieved M2-21 registry seed explicitly shows `PRODUCT_MIX_BASELINE_REFERENCE` for M2-21. fileciteturn183file3

Section 3 is failing correctly because formal campaign runs require the current technical run key to match exactly one active row in `credit_decisioning_sim.strategy_run_campaign_registry`; the Section 3 gatekeeper is designed to stop the run when registry linkage is missing. fileciteturn182file29

## Expected M2-21 run key

For M2-21, these values should match exactly between Section 2.2 and `strategy_run_campaign_registry`:

```text
source_module1_scenario_set_name / module1_scenario_set_name:
    MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET

source_module1_scenario_name / module1_scenario_name:
    PORTFOLIO_MIX_BASELINE_REFERENCE

source_population_id / population_id:
    BASE_POPULATION_V1

strategy_set_name:
    MODULE2_BASELINE_STRATEGY_SET

strategy_name:
    BASELINE_STRATEGY

strategy_version:
    V1_0
```

## Run this diagnostic first

Run this after Section 2 and before Section 3:

```sql
/***************************************************************************************************
M2-21 REGISTRY MATCH DIAGNOSTIC

Purpose:
    Compare the active tmp_module2_strategy_params technical run key to the persistent M2-21
    campaign registry row.

Expected:
    All mismatch flags should be FALSE.
    exact_active_registry_match_count should be 1.
***************************************************************************************************/

WITH active_params AS (
    SELECT
        source_module1_scenario_set_name,
        source_module1_scenario_name,
        source_population_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        campaign_registry_required_flag
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
),

m2_21_registry AS (
    SELECT
        module1_run_id,
        module2_run_id,
        run_sequence_number,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        registry_active_flag
    FROM credit_decisioning_sim.strategy_run_campaign_registry
    WHERE module2_run_id = 'M2-21'
),

exact_registry_match AS (
    SELECT
        COUNT(*) AS exact_active_registry_match_count
    FROM credit_decisioning_sim.strategy_run_campaign_registry r
    CROSS JOIN active_params p
    WHERE r.registry_active_flag IS TRUE
      AND r.module1_scenario_set_name = p.source_module1_scenario_set_name
      AND r.module1_scenario_name = p.source_module1_scenario_name
      AND r.population_id = p.source_population_id
      AND r.strategy_set_name = p.strategy_set_name
      AND r.strategy_name = p.strategy_name
      AND r.strategy_version = p.strategy_version
)

SELECT
    p.strategy_run_id,
    p.campaign_registry_required_flag,

    r.module2_run_id,
    r.registry_active_flag,

    p.source_module1_scenario_set_name AS active_param_scenario_set_name,
    r.module1_scenario_set_name AS registry_scenario_set_name,
    r.module1_scenario_set_name IS DISTINCT FROM p.source_module1_scenario_set_name
        AS scenario_set_name_mismatch,

    p.source_module1_scenario_name AS active_param_scenario_name,
    r.module1_scenario_name AS registry_scenario_name,
    r.module1_scenario_name IS DISTINCT FROM p.source_module1_scenario_name
        AS scenario_name_mismatch,

    p.source_population_id AS active_param_population_id,
    r.population_id AS registry_population_id,
    r.population_id IS DISTINCT FROM p.source_population_id
        AS population_id_mismatch,

    p.strategy_set_name AS active_param_strategy_set_name,
    r.strategy_set_name AS registry_strategy_set_name,
    r.strategy_set_name IS DISTINCT FROM p.strategy_set_name
        AS strategy_set_name_mismatch,

    p.strategy_name AS active_param_strategy_name,
    r.strategy_name AS registry_strategy_name,
    r.strategy_name IS DISTINCT FROM p.strategy_name
        AS strategy_name_mismatch,

    p.strategy_version AS active_param_strategy_version,
    r.strategy_version AS registry_strategy_version,
    r.strategy_version IS DISTINCT FROM p.strategy_version
        AS strategy_version_mismatch,

    e.exact_active_registry_match_count,

    CASE
        WHEN e.exact_active_registry_match_count = 1
            THEN 'RUN_REGISTRY_MATCHED'
        WHEN e.exact_active_registry_match_count = 0
            THEN 'RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW'
        ELSE 'RUN_REGISTRY_DUPLICATE_MATCH_REVIEW_REQUIRED'
    END AS diagnostic_match_status

FROM active_params p
LEFT JOIN m2_21_registry r
    ON TRUE
CROSS JOIN exact_registry_match e;
```

Expected bad result before patch:

```text
scenario_name_mismatch = TRUE
registry_scenario_name = PRODUCT_MIX_BASELINE_REFERENCE
active_param_scenario_name = PORTFOLIO_MIX_BASELINE_REFERENCE
exact_active_registry_match_count = 0
```

## Patch the live campaign registry

```sql
BEGIN;

/*-----------------------------------------------------------------------------------------------
Preview current M2-21 campaign registry row.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id = 'M2-21';


/*-----------------------------------------------------------------------------------------------
Patch M2-21 to the locked Module 1 scenario name.

This aligns the registry row to the actual Module 1 archive slice:
    PORTFOLIO_MIX_BASELINE_REFERENCE
-----------------------------------------------------------------------------------------------*/

UPDATE credit_decisioning_sim.strategy_run_campaign_registry
SET
    module1_scenario_name = 'PORTFOLIO_MIX_BASELINE_REFERENCE',
    registry_active_flag = TRUE,
    registry_updated_ts = CURRENT_TIMESTAMP
WHERE module2_run_id = 'M2-21'
  AND module1_scenario_name = 'PRODUCT_MIX_BASELINE_REFERENCE'
RETURNING
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag;


/*-----------------------------------------------------------------------------------------------
Verify patched M2-21 campaign registry row.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version,
    registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry
WHERE module2_run_id = 'M2-21';

COMMIT;
```

## Patch the canonical SQL file too

Search your full Module 2 SQL for:

```sql
'PRODUCT_MIX_BASELINE_REFERENCE'
```

Replace the M2-21 occurrence with:

```sql
'PORTFOLIO_MIX_BASELINE_REFERENCE'
```

At minimum, patch the M2-21 registry seed row in Section 2.6. I would also patch any fallback-label / reference-list mentions so the canonical naming stays consistent.

## Confirm Module 1 archive source exists

```sql
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS archived_rows
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_set_name = 'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET'
  AND scenario_name = 'PORTFOLIO_MIX_BASELINE_REFERENCE'
  AND population_id = 'BASE_POPULATION_V1'
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id;
```

Expected:

```text
archived_rows = 50000
```

## Rerun diagnostic, then Section 3

After the live registry patch and canonical SQL patch, rerun the M2-21 diagnostic. You want:

```text
scenario_name_mismatch = FALSE
exact_active_registry_match_count = 1
diagnostic_match_status = RUN_REGISTRY_MATCHED
```

Then rerun Section 3. The error should clear.
<!-- END_MESSAGE C038-M01270 -->


---

<a id="c038-m01271"></a>

### C038-M01271

**Andrew** · 2026-05-11T12:25:04.847000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01271 -->
all campaign runs are complete.  please provide me queries that you'd like to see to test the results
<!-- END_MESSAGE C038-M01271 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_64.md) · [Next](Part_66.md)
