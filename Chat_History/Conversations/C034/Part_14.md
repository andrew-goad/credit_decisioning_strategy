# Module 1 Synthetic Application Portfolio Build

## Part 14

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_13.md) · [Next](Part_15.md)

<a id="c034-m00534"></a>

### C034-M00534

**ChatGPT** · 2026-04-28T19:59:39.355561-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00534 -->
Yes — let’s push to **B3**, but keep it surgical.

Your current code is B2: the Section 8 header/top narrative now says B1 introduced the architecture and B2 strengthened slopes; the active `pd_saturation` logic uses the B2 formulas `0.55` and `0.20`, with the final 45% governance cap still preserved. fileciteturn92file0

## B3 target

Change only the soft saturation slopes:

```text
B2:
HIGH:    0.30 + ((raw - 0.30) * 0.55)
EXTREME: 0.4375 + ((raw - 0.55) * 0.20)

B3:
HIGH:    0.30 + ((raw - 0.30) * 0.50)
EXTREME: 0.4250 + ((raw - 0.55) * 0.15)
```

At raw PD = `0.55`, B3 maps to:

```text
0.30 + (0.25 * 0.50) = 0.4250
```

That creates more room below the 45% cap while still allowing truly extreme rows to approach the cap.

---

# 1. Top-level header update

## BEFORE

```text
Calibration path:
  - B1 introduced the initial soft saturation architecture
  - B2 strengthened the saturation slopes after validation showed residual
    cap crowding in the weakest segments
```

## AFTER

```text
Calibration path:
  - B1 introduced the initial soft saturation architecture
  - B2 strengthened the saturation slopes after validation showed residual
    cap crowding in the weakest segments
  - B3 applies a final light tightening to further reduce cap crowding while
    preserving monotonic score-band ordering and high-risk differentiation
```

---

# 2. Section 8 governance note update

## BEFORE

```sql
    B1 introduced the initial soft saturation architecture. B2 strengthens the
    saturation slopes after B1 validation showed that too many weak-end rows still
    reached the hard 45% cap.
```

## AFTER

```sql
    B1 introduced the initial soft saturation architecture. B2 strengthened the
    saturation slopes after B1 validation showed that too many weak-end rows still
    reached the hard 45% cap.

    B3 applies one final light tightening after B2 validation showed improvement
    but remaining cap concentration. The objective is not to lower risk broadly;
    it is to preserve more ranking information below the cap while keeping deep
    subprime and other high-risk combinations clearly highest-risk.
```

---

# 3. Replace `pd_saturation_factor_v2`

## BEFORE — B2

```sql
/*
pd_saturation_factor_v2:
  The ratio of saturated PD to raw PD.

Interpretation:
  - 1.000000 means no saturation was applied
  - values below 1.000000 mean high-end raw PD was compressed

B2 calibration note:
  B1 reduced some high-end PD pressure, but validation still showed material
  cap crowding in the weakest score bands. B2 therefore strengthens the soft
  saturation layer while keeping:
    - the same raw PD framework
    - the same zone thresholds
    - the same final 45% governance cap

Audit interpretation:
  This factor allows reviewers to see exactly how strongly the B2 saturation
  layer compressed a row before the final hard floor / cap was applied.
*/
round(
    CASE
        WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN 1.000000

        WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN
            (
                0.300000
                + ((pd_raw_pre_saturation_v2 - 0.300000) * 0.550000)
            )
            / NULLIF(pd_raw_pre_saturation_v2, 0)

        ELSE
            (
                0.437500
                + ((pd_raw_pre_saturation_v2 - 0.550000) * 0.200000)
            )
            / NULLIF(pd_raw_pre_saturation_v2, 0)
    END
,6) AS pd_saturation_factor_v2,
```

## AFTER — B3

```sql
/*
pd_saturation_factor_v2:
  The ratio of saturated PD to raw PD.

Interpretation:
  - 1.000000 means no saturation was applied
  - values below 1.000000 mean high-end raw PD was compressed

B3 calibration note:
  B1 introduced the soft saturation architecture. B2 reduced cap crowding, but
  validation still showed remaining concentration near the 45% hard cap.

  B3 applies a final light tightening while keeping:
    - the same raw PD framework
    - the same zone thresholds
    - the same final 45% governance cap
    - the same audit-visible raw and post-saturation PD fields

Audit interpretation:
  This factor allows reviewers to see exactly how strongly the B3 saturation
  layer compressed a row before the final hard floor / cap was applied.

Expected behavior:
  - fewer rows exactly at estimated_pd = 0.450000
  - more separation below the cap in the weakest score bands
  - no break in monotonic risk ordering
*/
round(
    CASE
        WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN 1.000000

        WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN
            (
                0.300000
                + ((pd_raw_pre_saturation_v2 - 0.300000) * 0.500000)
            )
            / NULLIF(pd_raw_pre_saturation_v2, 0)

        ELSE
            (
                0.425000
                + ((pd_raw_pre_saturation_v2 - 0.550000) * 0.150000)
            )
            / NULLIF(pd_raw_pre_saturation_v2, 0)
    END
,6) AS pd_saturation_factor_v2,
```

---

# 4. Replace `pd_after_saturation_v2`

## BEFORE — B2

```sql
/*
pd_after_saturation_v2:
  Raw PD after the soft high-end saturation layer, but before the final
  hard floor / cap is applied.

Formula design:
  1. raw PD <= 0.30:
       unchanged

  2. 0.30 < raw PD <= 0.55:
       0.30 + ((raw_pd - 0.30) * 0.55)

  3. raw PD > 0.55:
       0.4375 + ((raw_pd - 0.55) * 0.20)

Why these values:
  B1 used a 0.70 HIGH-zone slope and mapped raw PD = 0.55 to 0.475.
  Because final PD is capped at 0.45, this still left too many weak-end rows
  at or near the cap.

  B2 uses a 0.55 HIGH-zone slope:
      0.30 + (0.25 * 0.55) = 0.4375

  This means the top of the HIGH zone now remains below the hard 45% cap.

  For the EXTREME zone, B2 starts from 0.4375 and uses a flatter 0.20 slope.
  This allows the most severe raw-risk rows to still approach or reach the cap,
  but reduces broad cap crowding among rows that are high-risk but not truly
  extreme.

Expected validation result:
  - fewer rows exactly at estimated_pd = 0.450000
  - more spread between roughly 0.35 and 0.45
  - deep subprime should remain riskiest
  - score-band and product risk ordering should remain directionally intact
*/
round(
    CASE
        WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN
            pd_raw_pre_saturation_v2

        WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN
            0.300000
            + ((pd_raw_pre_saturation_v2 - 0.300000) * 0.550000)

        ELSE
            0.437500
            + ((pd_raw_pre_saturation_v2 - 0.550000) * 0.200000)
    END
,6) AS pd_after_saturation_v2
```

## AFTER — B3

```sql
/*
pd_after_saturation_v2:
  Raw PD after the soft high-end saturation layer, but before the final
  hard floor / cap is applied.

Formula design:
  1. raw PD <= 0.30:
       unchanged

  2. 0.30 < raw PD <= 0.55:
       0.30 + ((raw_pd - 0.30) * 0.50)

  3. raw PD > 0.55:
       0.4250 + ((raw_pd - 0.55) * 0.15)

Why these values:
  B1 used a 0.70 HIGH-zone slope and mapped raw PD = 0.55 to 0.475.
  Because final PD is capped at 0.45, that still left substantial weak-end cap
  crowding.

  B2 improved the issue by lowering the HIGH-zone slope to 0.55 and the EXTREME
  slope to 0.20. Validation showed meaningful improvement, but remaining cap
  concentration was still higher than desired for a polished simulation output.

  B3 uses a 0.50 HIGH-zone slope:
      0.30 + (0.25 * 0.50) = 0.4250

  This means the top of the HIGH zone now remains comfortably below the hard
  45% cap, preserving more ranking room before governance capping occurs.

  For the EXTREME zone, B3 starts from 0.4250 and uses a flatter 0.15 slope.
  This still allows the most severe raw-risk rows to approach or reach the cap,
  but makes broad cap crowding less likely.

Expected validation result:
  - materially fewer rows exactly at estimated_pd = 0.450000
  - more spread between roughly 0.35 and 0.45
  - deep subprime remains the riskiest score band
  - subprime remains clearly riskier than near-prime
  - product × score ordering remains directionally coherent
  - expected loss should decline modestly, not collapse
*/
round(
    CASE
        WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN
            pd_raw_pre_saturation_v2

        WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN
            0.300000
            + ((pd_raw_pre_saturation_v2 - 0.300000) * 0.500000)

        ELSE
            0.425000
            + ((pd_raw_pre_saturation_v2 - 0.550000) * 0.150000)
    END
,6) AS pd_after_saturation_v2
```

---

# 5. Do **not** change these

Keep the zone thresholds:

```sql
WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN 'NORMAL'
WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN 'HIGH'
ELSE 'EXTREME'
```

Keep the final governance cap:

```sql
LEAST(
    0.450000,
    GREATEST(
        0.005000,
        pd_after_saturation_v2
    )
)
```

That keeps B3 isolated to calibration slopes only.

---

# B3 validation target

After run, compare:

```text
B1 pct_capped: 17.72%
B2 pct_capped: 15.05%
B3 target:     roughly 12%–13.5%
```

Pass criteria:

```text
- pct_capped materially below B2
- deep subprime avg PD still highest
- subprime avg PD still clearly above near prime
- product × score matrix still directionally ordered
- expected loss declines modestly, not dramatically
```
<!-- END_MESSAGE C034-M00534 -->


---

<a id="c034-m00536"></a>

### C034-M00536

**Andrew** · 2026-04-28T21:40:07.974000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00536 -->
evaluate b3:
<!-- END_MESSAGE C034-M00536 -->


**Attachments in export:** `module1_synthetic_application_risk_engine_v2.0_9.14_QA_mortgage_transformation_trace_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.13_QA_mortgage_overlay_diagnostics_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.12_QA_pd_saturation_zone_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.12_QA_pd_saturation_diagnostics_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.11_QA_quick_profile_sample_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.10_QA_distribution_sanity_by_product_and_score_band_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.09_QA_large_exposure_but_manageable_affordability_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.09_QA_weaker_credit_but_manageable_pti_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.08_QA_product_x_score_band_matrix_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.05_QA_score_band_profile_summary_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.04_QA_variable_profile_statistics_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.03_QA_score_band_distribution_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.01_QA_record_count_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.02_QA_product_mix_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.06_QA_product_profile_summary_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.07_QA_pti_bucket_summary_b3.csv`, `module1_synthetic_application_risk_engine_v2.0_9.09_QA_strong_credit_but_high_pti_b3.csv`, `Pasted text(53).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m00538"></a>

### C034-M00538

**ChatGPT** · 2026-04-28T21:40:57.688029-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00538 -->
B3 is the **right stopping point**.

## Verdict

**B3 passes.** It achieves the Workstream B objective without breaking mortgage behavior, score-band ordering, product realism, or expected loss credibility.

## Primary B3 win: cap crowding reduced materially

| Run | pct_capped |
|---|---:|
| B1 | 17.72% |
| B2 | 15.05% |
| B3 | **12.86%** |

That is a strong result. B3 reduced cap crowding by roughly **27% relative to B1**, while keeping the hard 45% governance cap intact.

## Score-band behavior still passes

| Score Band | Avg PD | Avg EL |
|---|---:|---:|
| Super Prime | 0.0136 | 690 |
| Prime | 0.0401 | 1,807 |
| Near Prime | 0.1309 | 4,997 |
| Subprime | 0.3593 | 10,081 |
| Deep Subprime | 0.4465 | 9,549 |

The risk ladder remains clean. Deep Subprime is still highest risk, Subprime remains clearly above Near Prime, and expected loss does not collapse.

## Product × score matrix still passes

Deep Subprime PDs remain high but no longer look universally pinned:

| Product | Deep Subprime Avg PD |
|---|---:|
| Mortgage | 0.4490 |
| Personal | 0.4472 |
| HELOC | 0.4468 |
| Auto | 0.4453 |
| Revolving | 0.4439 |

This is exactly what we wanted: high-risk cells remain high-risk, but there is more meaningful dispersion below the cap.

## Mortgage Workstream A remains intact

Mortgage outputs are unchanged from the prior run:

| Metric | Result |
|---|---:|
| Avg mortgage amount | $339,059.67 |
| Avg mortgage PTI | 0.2967 |
| A3 HOT rows | 1,030 |
| A3 NORMAL rows | 14,035 |
| A3 avg HOT factor | 0.994152 |

No regression. A2/A3 remain narrow, auditable, and effective.

## Portfolio-level realism still passes

The core profile remains coherent:

- `estimated_pd` mean: **0.1633**
- median PD: **0.0877**
- max PD: **0.4500**
- expected loss mean: **$4,787.20**
- requested amount median: **$47,251**
- requested amount mean: **$133,329**

This remains a realistic, differentiated synthetic portfolio.

## Final recommendation

Stop at **B3**.

Do **not** push to B4. Further tightening risks over-suppressing the weakest segment and making the engine look too managed. B3 is the balanced calibration point: materially improved dispersion, preserved governance cap, and no broken directional relationships.
<!-- END_MESSAGE C034-M00538 -->


---

<a id="c034-m00540"></a>

### C034-M00540

**Andrew** · 2026-04-28T21:57:11.341000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00540 -->
wonderful! now, was there a workstream C we were going to work on?
<!-- END_MESSAGE C034-M00540 -->


---

<a id="c034-m00541"></a>

### C034-M00541

**ChatGPT** · 2026-04-28T21:57:15.469857-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00541 -->
Yes — and you’re exactly at the right moment to move into it.

## Workstream C = **Scenario Comparison Framework**

This was always the third pillar after:
- **A:** Mortgage realism (A2/A3) ✅ complete  
- **B:** PD dispersion (B1 → B3) ✅ complete  
- **C:** Scenario comparison & attribution ⬅️ next

---

# What Workstream C is (in precise terms)

Workstream C is **not** more modeling.

It is about turning your engine into a **decisioning system** by enabling:

### 1. Apples-to-apples scenario comparison  
Same borrowers (`population_id` constant), different strategies (`scenario_name` changes)

### 2. Attribution of change  
Answering questions like:
- *Why did PD increase?*
- *Was it PTI? APR? product mix?*
- *Which segments drove the change?*

### 3. Audit-ready outputs  
So someone reviewing your work can trace:

```text
Scenario A vs Scenario B → metric differences → driver decomposition
```

---

# Why this is the correct next step

Right now:

- You have a **high-quality synthetic portfolio engine**
- You have **controlled realism and calibration**
- You have **full audit trace at row level**

What you **don’t yet have** is:

> A structured way to compare runs and explain differences

That is exactly what elevates this from:
- “great SQL project”

to:
- **“enterprise decisioning simulator”**

---

# What Workstream C will produce

We will build a standardized comparison layer that outputs:

## 1. Scenario summary table

Example:

| scenario | avg_pd | avg_pti | avg_apr | avg_amount | avg_el |
|---------|--------|--------|--------|------------|--------|
| BASELINE_V2 | 0.1633 | 0.212 | 0.145 | 133k | 4,787 |
| RATE_UP_200 | 0.1821 | 0.248 | 0.165 | 132k | 5,420 |

---

## 2. Delta table (core deliverable)

| metric | baseline | scenario | delta |
|--------|----------|----------|-------|
| avg_pd | 0.1633 | 0.1821 | +0.0188 |
| avg_pti | 0.212 | 0.248 | +0.036 |
| avg_el | 4,787 | 5,420 | +633 |

---

## 3. Driver attribution layer (this is the “elite” part)

Break PD change into components:

```text
Δ PD ≈
  contribution from PTI change
+ contribution from APR change
+ contribution from product mix shift
+ residual
```

This is where your architecture shines because you already expose:

- PTI
- APR
- product_type
- score_band
- PD inputs

---

## 4. Segment-level comparison

Example:

| segment | Δ PD |
|--------|------|
| Mortgage × Subprime | +0.041 |
| Revolving × Near Prime | +0.012 |
| Auto × Prime | +0.005 |

This answers:

> “Where is the risk actually moving?”

---

## 5. Row-level matched comparison (powerful)

Because of deterministic population:

```sql
JOIN baseline b
  ON a.application_id = b.application_id
```

This enables:

- exact borrower-level comparison
- true causal-style analysis (no population noise)

---

# Design philosophy (important)

We will **NOT**:

- rewrite the model
- duplicate logic
- introduce randomness

We will:

- layer comparison on top of your final output table:
  
```sql
credit_decisioning_sim.synthetic_applications
```

---

# Implementation approach (high-level)

Workstream C will be built in **3 structured layers**:

---

## Layer 1 — Persist runs

Modify final table behavior to support multiple runs:

Instead of overwriting:

```sql
DROP TABLE synthetic_applications;
```

We move to:

```sql
INSERT INTO synthetic_applications
```

Key requirement:
```sql
PRIMARY KEY (scenario_name, application_id)
```

---

## Layer 2 — Scenario comparison views

Create reusable views:

### `vw_scenario_summary`
### `vw_scenario_delta`
### `vw_product_score_delta`

---

## Layer 3 — Attribution logic

Create:

### `vw_pd_driver_decomposition`

This is where we quantify:

- PTI effect
- APR effect
- composition effect

---

# What we’ll do next (execution plan)

Next step (I recommend):

### Step 1
Implement **run persistence + scenario alignment**

### Step 2
Build:
- scenario summary
- delta tables

### Step 3
Add:
- segment-level comparison

### Step 4 (final)
Add:
- **driver attribution decomposition**

---

# Final positioning

After Workstream C, your project becomes:

> A deterministic, auditable, scenario-based credit decisioning simulator with explainable outcome attribution

That is exactly how a **Principal / Director-level analytics artifact** should read.

---

If you're ready, next I’ll:

👉 Design **Layer 1 + Layer 2 SQL (with full elite comments, before/after style)** so you can start generating real scenario comparisons immediately.
<!-- END_MESSAGE C034-M00541 -->


---

<a id="c034-m00542"></a>

### C034-M00542

**Andrew** · 2026-04-28T22:02:01.267000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00542 -->
let's talk about how this workstream 3 fits into the broader project goals.  remember this is just module1
<!-- END_MESSAGE C034-M00542 -->


---

<a id="c034-m00543"></a>

### C034-M00543

**ChatGPT** · 2026-04-28T22:02:05.246981-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00543 -->
Good instinct to pause here—this is where projects either stay “very good” or become **cohesive, enterprise-grade systems**.

You’re right to anchor on: **this is only Module 1**.

---

# Where Workstream C fits (precisely)

## Module 1 mission (restate cleanly)

Module 1 is:

> A **deterministic synthetic application + risk modeling engine** that produces a realistic, governed, and fully auditable portfolio.

Up to now:

- **A (Mortgage A2/A3)** → fixed realism of exposure construction  
- **B (PD B1–B3)** → fixed realism and dispersion of risk outcomes  

Those made Module 1:
> **accurate and credible**

---

## What Workstream C adds

Workstream C makes Module 1:

> **useful for decisioning**

Without C, Module 1 answers:

```text
“What does a realistic portfolio look like?”
```

With C, Module 1 answers:

```text
“What happens if I change something?”
```

That is the pivot from:
- **data generator**
→ **decision simulator**

---

# Why this still belongs in Module 1

You might ask:
> “Should scenario comparison be Module 2?”

No — and here’s why.

## Module boundaries (clean architecture)

### Module 1 = **Generation + First-order Analysis**

Includes:
- population generation
- product structuring
- affordability
- PD / LGD / EL
- **scenario comparison (first-order)** ← Workstream C

---

### Module 2 (future) = **Decision Policy / Actions**

Will include:
- approval / decline logic
- cutoffs
- strategy overlays
- remediation / treatment
- behavioral evolution

---

### Key distinction

| Layer | Question answered |
|------|------------------|
| Module 1 | “What is the risk profile under X conditions?” |
| Module 2 | “What decisions should we make given that risk?” |

---

# What Workstream C should (and should NOT) do

## ✅ What it SHOULD do (Module 1 appropriate)

### 1. Enable deterministic scenario comparison

```text
Same borrowers + different parameters → clean comparison
```

### 2. Provide metric deltas

- avg PD
- avg PTI
- expected loss
- product mix

### 3. Provide **segment-level movement**

- product × score
- PTI buckets
- risk buckets

### 4. Provide
<!-- END_MESSAGE C034-M00543 -->


---

<a id="c034-m00544"></a>

### C034-M00544

**Andrew** · 2026-04-28T22:05:15.839000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00544 -->
ok, i agree.  let's proceed to begin outlining how workstream C will fit into the current code structure.  what will we change to achieve workstream C goals?
<!-- END_MESSAGE C034-M00544 -->


---

<a id="c034-m00545"></a>

### C034-M00545

**ChatGPT** · 2026-04-28T22:05:24.735815-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00545 -->
I’ll frame this as an architecture fit first, then translate it into concrete code-structure changes. The key is keeping Module 1 as the generator while adding a lightweight comparison layer around its outputs.
<!-- END_MESSAGE C034-M00545 -->


---

<a id="c034-m00547"></a>

### C034-M00547

**ChatGPT** · 2026-04-28T22:05:38.328927-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00547 -->
Yes. Workstream C fits cleanly, but we should **not** turn Module 1 into a full strategy-decision module. It should add **scenario persistence + comparison QA**, not approval / decline strategy logic.

## Workstream C goal inside Module 1

Module 1 currently produces one final output table and resets it each run. That is appropriate for single-run validation, but not for scenario comparison. The current reset pattern explicitly drops `synthetic_applications` each run, which prevents side-by-side scenario persistence. fileciteturn94file16

Workstream C changes that by adding a controlled way to preserve runs and compare them.

---

# Recommended code-structure changes

## 1. Keep the current final table as the “latest run” table

Do **not** abandon:

```sql
credit_decisioning_sim.synthetic_applications
```

This remains the clean, current-run output table.

That preserves:
- simple QA
- simple GitHub demo flow
- easy user interpretation

---

## 2. Add a new scenario archive table

Add a permanent table such as:

```sql
credit_decisioning_sim.synthetic_applications_scenario_archive
```

Purpose:

```text
Store multiple completed Module 1 runs for apples-to-apples scenario comparison.
```

This table should include the same output fields as `synthetic_applications`, plus:

```sql
scenario_run_id
run_created_ts
```

Recommended key:

```sql
(scenario_name, population_id, application_id)
```

Why:

- `scenario_name` identifies the business scenario
- `population_id` confirms same-population comparison
- `application_id` enables row-level matched comparison

---

## 3. Add a scenario archive control parameter

In Section 2, add something like:

```sql
archive_run_flag BOOLEAN
```

Default:

```sql
TRUE
```

This lets the user decide whether a given run should be preserved for comparison.

---

## 4. Add a new section after final output creation

Add:

```text
SECTION 8.5. SCENARIO ARCHIVE / RUN PERSISTENCE
```

This section would:

1. delete any prior archive rows for the same `scenario_name + population_id`
2. insert the current final table into the archive

Conceptually:

```sql
DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
WHERE scenario_name = (SELECT scenario_name FROM tmp_module1_params)
  AND population_id = (SELECT population_id FROM tmp_module1_params);

INSERT INTO credit_decisioning_sim.synthetic_applications_scenario_archive
SELECT ...
FROM credit_decisioning_sim.synthetic_applications;
```

This keeps reruns idempotent without destroying other scenarios.

---

## 5. Add Section 10, not more Section 9

Keep Section 9 as **single-run QA**.

Add:

```text
SECTION 10. SCENARIO COMPARISON QA
```

This avoids bloating Section 9.

Section 10 should include:

### 10.1 Scenario inventory

Shows what scenarios are available in the archive.

### 10.2 Portfolio-level scenario comparison

Compares:

- avg requested amount
- avg APR
- avg PTI
- avg PD
- avg LGD
- avg expected loss

### 10.3 Product × score scenario comparison

Compares changes by:

```sql
product_type, score_band
```

### 10.4 Row-level matched comparison

Joins two scenarios on:

```sql
population_id + application_id
```

This is the most important piece because it proves true apples-to-apples comparison.

---

# What we should not do yet

Do **not** add:

- approval logic
- decline logic
- pricing strategy
- cutoffs
- manual review strategy
- optimization logic

Those belong in Module 2.

Workstream C should make Module 1 answer:

> “How did the synthetic risk profile change under a different scenario?”

Module 2 will answer:

> “What decision should we make because of that change?”

---

# Proposed module structure after Workstream C

```text
Section 0  Schema Setup
Section 1  Reset / Clean Rerun
Section 2  User Parameters
Section 3  Validation Gatekeeper
Section 4  Base Application Skeleton
Section 5  Product & Score Assignment
Section 6  Borrower Profile Generation
Section 7  Product Structuring
Section 8  Risk Modeling
Section 8.5 Scenario Archive / Run Persistence
Section 9  Single-Run QA
Section 10 Scenario Comparison QA
```

That is the cleanest fit.
<!-- END_MESSAGE C034-M00547 -->


---

<a id="c034-m00549"></a>

### C034-M00549

**Andrew** · 2026-04-28T22:36:56.489000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00549 -->
I agree with all of this, but i'd like to talk about flexibility.  what if i want an archive for the scenarios i'm testing for project A and then I want a new archive for scenarios I'm testing for project B?  i think we should give users flexible options for that archive table - and also potentially allow for resetting (clearing) it.  thoughts?
<!-- END_MESSAGE C034-M00549 -->


---

<a id="c034-m00550"></a>

### C034-M00550

**ChatGPT** · 2026-04-28T22:37:01.134512-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00550 -->
Yes — that is the right concern. We should **not** make the archive table behave like one universal junk drawer.

I recommend adding a **scenario_set_name** concept.

## Best design

Instead of only:

```sql
scenario_name
population_id
application_id
```

use:

```sql
scenario_set_name
scenario_name
population_id
application_id
```

Where:

```text
scenario_set_name = project / comparison family
scenario_name     = individual run inside that family
```

Example:

```text
scenario_set_name = 'PROJECT_A_RATE_STRESS'
scenario_name     = 'BASELINE_V2'

scenario_set_name = 'PROJECT_A_RATE_STRESS'
scenario_name     = 'RATE_UP_200BP'

scenario_set_name = 'PROJECT_B_CREDIT_TIGHTENING'
scenario_name     = 'BASELINE_V2'

scenario_set_name = 'PROJECT_B_CREDIT_TIGHTENING'
scenario_name     = 'TIGHTER_CREDIT_BOX'
```

This lets users keep multiple scenario families in the same archive table without mixing analyses.

## Add two archive controls to Section 2

I’d add these parameters:

```sql
scenario_set_name TEXT
archive_run_flag BOOLEAN
archive_reset_mode TEXT
```

Recommended values:

```text
archive_run_flag:
  TRUE / FALSE

archive_reset_mode:
  'NONE'          -- preserve existing archive rows
  'SCENARIO_ONLY' -- clear this scenario within this scenario set before inserting
  'SET_ONLY'      -- clear all scenarios in this scenario set
  'ALL'           -- clear entire archive table
```

Default should be:

```sql
scenario_set_name = 'DEFAULT_SCENARIO_SET'
archive_run_flag  = TRUE
archive_reset_mode = 'SCENARIO_ONLY'
```

## Why this is better

This gives the user four workflows:

### 1. Normal rerun of one scenario

```text
archive_reset_mode = 'SCENARIO_ONLY'
```

Replaces only the current scenario inside the current scenario set.

### 2. Start a fresh project / comparison family

```text
archive_reset_mode = 'SET_ONLY'
```

Clears Project A scenarios, but leaves Project B untouched.

### 3. Full archive reset

```text
archive_reset_mode = 'ALL'
```

Useful when starting over completely.

### 4. Run without archiving

```text
archive_run_flag = FALSE
```

Useful for quick tests.

## Archive key

Use:

```sql
PRIMARY KEY (
    scenario_set_name,
    scenario_name,
    population_id,
    application_id
)
```

That prevents accidental duplicates while supporting multiple projects.

## My recommendation

Implement one shared archive table:

```sql
credit_decisioning_sim.synthetic_applications_scenario_archive
```

with `scenario_set_name` as a first-class partitioning / grouping field.

Do **not** create separate physical archive tables for Project A and Project B. That becomes harder to govern, harder to compare, and harder to document.

This design gives users flexibility **without losing governance**.
<!-- END_MESSAGE C034-M00550 -->


---

<a id="c034-m00551"></a>

### C034-M00551

**Andrew** · 2026-04-28T22:52:40.408000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00551 -->
That sounds excellent.  let's move forward.
<!-- END_MESSAGE C034-M00551 -->


---

<a id="c034-m00552"></a>

### C034-M00552

**ChatGPT** · 2026-04-28T22:52:45.182136-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00552 -->
I’ll keep this as a controlled Module 1 extension: add scenario-set archive controls, create/maintain one governed archive table, and add comparison QA without changing the core generation logic.
<!-- END_MESSAGE C034-M00552 -->


---

<a id="c034-m00554"></a>

### C034-M00554

**ChatGPT** · 2026-04-28T22:52:58.662902-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00554 -->
Excellent. We should implement Workstream C in **four controlled code changes**, without disturbing the B3 model logic.

Current Module 1 already has the right foundation: centralized parameters, deterministic `population_id`, final `synthetic_applications`, and Section 9 QA. Workstream C will add a governed archive layer and a new Section 10 comparison layer on top. fileciteturn95file18

---

## Workstream C implementation map

Add:

1. **Archive controls in Section 2**
2. **Additional validation in Section 3**
3. **New Section 8.5 archive persistence**
4. **New Section 10 scenario comparison QA**

Do **not** change:
- Sections 4–8 modeling logic
- B3 PD saturation formulas
- Section 9 single-run QA

---

# 1. Section 2 — Add archive controls

## Before

```sql
CREATE TEMP TABLE tmp_module1_params (
    scenario_name               TEXT,
    population_id               TEXT,
    application_count           INTEGER,
```

## After

```sql
CREATE TEMP TABLE tmp_module1_params (
    scenario_set_name           TEXT,          -- comparison family / project grouping, e.g. RATE_STRESS_TESTS
    scenario_name               TEXT,          -- individual run label within the scenario set
    archive_run_flag            BOOLEAN,       -- TRUE = store this run in the scenario archive
    archive_reset_mode          TEXT,          -- NONE, SCENARIO_ONLY, SET_ONLY, or ALL

    population_id               TEXT,
    application_count           INTEGER,
```

---

## Section 2 parameter insert

## Before

```sql
INSERT INTO tmp_module1_params VALUES (
    'BASELINE_V2',            -- scenario_name:
                              -- business-facing label for the default run

    'BASE_POPULATION_V1',     -- population_id:
```

## After

```sql
INSERT INTO tmp_module1_params VALUES (
    'MODULE1_V2_BASELINE_SET', -- scenario_set_name:
                               -- comparison family / project grouping.
                               --
                               -- Use this to keep different analysis projects
                               -- separate inside the same archive table.
                               --
                               -- Examples:
                               --   MODULE1_V2_BASELINE_SET
                               --   RATE_STRESS_TESTS
                               --   CREDIT_TIGHTENING_TESTS
                               --   GROWTH_STRATEGY_TESTS

    'BASELINE_V2',            -- scenario_name:
                              -- individual run label within the scenario set.
                              --
                              -- Examples:
                              --   BASELINE_V2
                              --   RATE_UP_200BP
                              --   TIGHTER_CREDIT_BOX
                              --   GROWTH_CASE

    TRUE,                     -- archive_run_flag:
                              -- TRUE  = store this run in the scenario archive
                              -- FALSE = produce only the latest-run output table

    'SCENARIO_ONLY',          -- archive_reset_mode:
                              -- controls how much existing archive history is
                              -- cleared before inserting this run.
                              --
                              -- Valid values:
                              --   NONE
                              --     preserve all existing archive rows and append
                              --     this run. Use only when scenario_name is new.
                              --
                              --   SCENARIO_ONLY
                              --     replace only this scenario inside this
                              --     scenario_set_name + population_id.
                              --     Best default for rerunning a scenario.
                              --
                              --   SET_ONLY
                              --     clear all scenarios in this scenario_set_name
                              --     for this population_id before inserting.
                              --     Use when restarting a comparison family.
                              --
                              --   ALL
                              --     clear the entire scenario archive table.
                              --     Use only when intentionally starting over.

    'BASE_POPULATION_V1',     -- population_id:
```

---

# 2. Section 3 — Add archive-control validation

Add this inside the validation gatekeeper after the date check or after mix checks.

```sql
    -- Validate scenario archive reset mode.
    -- Why this matters:
    -- The archive layer preserves scenario runs across executions. Because it
    -- can delete prior archived results depending on reset mode, we explicitly
    -- validate the requested mode before any synthetic data is generated.
    --
    -- Valid modes:
    --   NONE
    --     do not clear archive rows before inserting
    --   SCENARIO_ONLY
    --     clear only the current scenario inside the current scenario set
    --   SET_ONLY
    --     clear all scenarios in the current scenario set
    --   ALL
    --     clear the entire archive table
    IF p.archive_reset_mode NOT IN ('NONE', 'SCENARIO_ONLY', 'SET_ONLY', 'ALL') THEN
        RAISE EXCEPTION
            'Invalid archive_reset_mode (%): must be NONE, SCENARIO_ONLY, SET_ONLY, or ALL',
            p.archive_reset_mode;
    END IF;

    -- Validate scenario set name.
    -- Why this matters:
    -- scenario_set_name is the project / comparison-family identifier used to
    -- keep unrelated scenario studies from mixing inside the archive.
    IF p.scenario_set_name IS NULL OR length(trim(p.scenario_set_name)) = 0 THEN
        RAISE EXCEPTION
            'Invalid scenario_set_name: value cannot be null or blank';
    END IF;

    -- Validate scenario name.
    -- Why this matters:
    -- scenario_name identifies the individual run inside a scenario set.
    IF p.scenario_name IS NULL OR length(trim(p.scenario_name)) = 0 THEN
        RAISE EXCEPTION
            'Invalid scenario_name: value cannot be null or blank';
    END IF;
```

---

# 3. Final output table — include scenario_set_name

Where final output table is created from `tmp_m1_stage_4_risk`, add `scenario_set_name`.

## Before

```sql
SELECT
    scenario_name,
    population_id,
    anchor_date,
```

## After

```sql
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    anchor_date,
```

To support that, `scenario_set_name`, `archive_run_flag`, and `archive_reset_mode` must be carried forward early just like `scenario_name` and `population_id`.

In Section 4 `seeded`, update:

## Before

```sql
SELECT
    b.*,
    p.scenario_name,
    p.population_id,
    p.portfolio_start_date,
```

## After

```sql
SELECT
    b.*,
    p.scenario_set_name,
    p.scenario_name,
    p.archive_run_flag,
    p.archive_reset_mode,
    p.population_id,
    p.portfolio_start_date,
```

That lets later sections access archive controls without another parameter join.

---

# 4. Add Section 8.5 — Scenario archive persistence

Place this **after final `synthetic_applications` table creation and indexes**, before Section 9.

```sql
/*
================================================================================
SECTION 8.5. SCENARIO ARCHIVE / RUN PERSISTENCE
================================================================================
Purpose:
  Preserve completed Module 1 runs in a governed scenario archive so users can
  compare multiple scenarios without losing the latest-run output table.

Why this section exists:
  The primary output table:
      credit_decisioning_sim.synthetic_applications

  intentionally represents the latest completed run.

  That is ideal for single-run QA, but scenario comparison requires preserving
  multiple completed runs side by side. This archive table provides that
  persistence while still keeping the main output table simple.

Key concept:
  scenario_set_name = comparison family / project grouping
  scenario_name     = individual run inside that family
  population_id     = deterministic borrower population

Examples:
  scenario_set_name = RATE_STRESS_TESTS
      scenario_name = BASELINE_V2
      scenario_name = RATE_UP_200BP

  scenario_set_name = CREDIT_TIGHTENING_TESTS
      scenario_name = BASELINE_V2
      scenario_name = TIGHTER_CREDIT_BOX

Why this design matters:
  A single shared archive table is easier to govern than many project-specific
  physical tables. scenario_set_name provides flexibility without table sprawl.

Reset behavior:
  archive_reset_mode controls how much prior archive history is cleared before
  the current run is inserted.

  NONE:
    Preserve prior archive rows.

  SCENARIO_ONLY:
    Replace only the current scenario within the current scenario set and
    population. This is the recommended default for reruns.

  SET_ONLY:
    Clear all scenarios in the current scenario set for the current population.

  ALL:
    Clear the entire archive table. Use only when intentionally starting over.

Audit note:
  The archive stores the final output columns plus run_created_ts. This allows
  reviewers to confirm when a scenario was archived and compare results across
  deterministic runs.
*/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.synthetic_applications_scenario_archive
(LIKE credit_decisioning_sim.synthetic_applications INCLUDING DEFAULTS);

ALTER TABLE credit_decisioning_sim.synthetic_applications_scenario_archive
ADD COLUMN IF NOT EXISTS scenario_archived_ts TIMESTAMP;

-- Archive reset controller:
-- This DO block reads the current run controls from tmp_module1_params and
-- deletes only the archive rows requested by archive_reset_mode.
DO $$
DECLARE
    p RECORD;
BEGIN
    SELECT * INTO p FROM tmp_module1_params;

    IF p.archive_run_flag = TRUE THEN

        IF p.archive_reset_mode = 'ALL' THEN
            DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive;

        ELSIF p.archive_reset_mode = 'SET_ONLY' THEN
            DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
            WHERE scenario_set_name = p.scenario_set_name
              AND population_id = p.population_id;

        ELSIF p.archive_reset_mode = 'SCENARIO_ONLY' THEN
            DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
            WHERE scenario_set_name = p.scenario_set_name
              AND scenario_name = p.scenario_name
              AND population_id = p.population_id;

        ELSIF p.archive_reset_mode = 'NONE' THEN
            -- Preserve existing archive rows.
            NULL;
        END IF;

    END IF;
END $$;

-- Insert the latest run into the scenario archive only when archive_run_flag is TRUE.
INSERT INTO credit_decisioning_sim.synthetic_applications_scenario_archive
SELECT
    s.*,
    CURRENT_TIMESTAMP AS scenario_archived_ts
FROM credit_decisioning_sim.synthetic_applications s
CROSS JOIN tmp_module1_params p
WHERE p.archive_run_flag = TRUE;

-- Helpful indexes for Section 10 scenario comparison queries.
CREATE INDEX IF NOT EXISTS idx_synth_archive_set_scenario_population
ON credit_decisioning_sim.synthetic_applications_scenario_archive
(scenario_set_name, scenario_name, population_id);

CREATE INDEX IF NOT EXISTS idx_synth_archive_matched_row
ON credit_decisioning_sim.synthetic_applications_scenario_archive
(scenario_set_name, population_id, application_id);

CREATE INDEX IF NOT EXISTS idx_synth_archive_product_score
ON credit_decisioning_sim.synthetic_applications_scenario_archive
(scenario_set_name, scenario_name, population_id, product_type, score_band);
```

One caution: `LIKE synthetic_applications` copies columns, but if you later change final output columns, the archive table may need to be dropped/recreated or altered. For development, that is acceptable.

---

# 5. Add Section 10 — Scenario comparison QA

Place after Section 9.

```sql
/*
================================================================================
SECTION 10. SCENARIO COMPARISON QA
================================================================================
Purpose:
  Compare archived Module 1 scenarios within a selected scenario_set_name.

Why this section matters:
  Module 1 is not only a synthetic portfolio generator. With deterministic
  population_id and archived outputs, it becomes a controlled scenario comparison
  engine.

Important boundary:
  This section does not make approval, decline, pricing, or manual review
  decisions. Those belong in later modules.

  Section 10 answers:
      What changed between scenarios?

  Later modules will answer:
      What decision should we make because of those changes?

How to use:
  1. Run a baseline scenario with archive_run_flag = TRUE
  2. Change scenario_name and one or more parameters
  3. Keep population_id constant for apples-to-apples comparison
  4. Rerun and archive the new scenario
  5. Use the queries below to compare archived results

Key analytical principle:
  Holding population_id constant means each scenario is evaluated on the same
  synthetic borrowers. This removes population noise and makes changes easier
  to attribute to scenario assumptions.
*/

-- 10.1 Scenario archive inventory
-- Purpose:
--   Show which scenario sets and scenarios are currently available for
--   comparison.
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_archived,
    MIN(scenario_archived_ts) AS first_archived_ts,
    MAX(scenario_archived_ts) AS last_archived_ts
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;

-- 10.2 Portfolio-level scenario summary
-- Purpose:
--   Compare major portfolio metrics across scenarios in the same scenario set.
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(estimated_lgd)::numeric, 4) AS avg_lgd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss,
    ROUND(SUM(expected_loss_amount)::numeric, 2) AS total_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;

-- 10.3 Product x score scenario summary
-- Purpose:
--   Show where scenario differences concentrate by product and score band.
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band
ORDER BY
    scenario_set_name,
    population_id,
    product_type,
    score_band,
    scenario_name;
```

For row-level deltas, we should add a parameterized comparison once you decide the two scenario names you want to compare. I recommend making that a small temp table in Section 10:

```sql
CREATE TEMP TABLE tmp_module1_compare_scenarios AS
SELECT
    'MODULE1_V2_BASELINE_SET'::TEXT AS scenario_set_name,
    'BASE_POPULATION_V1'::TEXT      AS population_id,
    'BASELINE_V2'::TEXT             AS baseline_scenario_name,
    'RATE_UP_200BP'::TEXT           AS comparison_scenario_name;
```

Then we can write matched-row comparison queries using that control table.

---

## Implementation order

Do this in order:

1. Add Section 2 archive fields.
2. Add Section 3 validation checks.
3. Carry archive fields through `seeded`.
4. Add `scenario_set_name` to final output.
5. Add Section 8.5 archive persistence.
6. Run baseline.
7. Change `scenario_name` / parameters.
8. Run comparison scenario.
9. Add Section 10 matched comparison queries.

This keeps Workstream C clean and controlled.
<!-- END_MESSAGE C034-M00554 -->


---

<a id="c034-m00556"></a>

### C034-M00556

**Andrew** · 2026-04-29T09:41:12.671000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00556 -->
your suggestions are not maintaining our elite level of commentary:  here was what we had for the parameter table definition and your change 1 misses important comments we had, and does not add sufficient commentary for the changes (full code also attached).   -- ============================================================================= 
-- PARAMETER TABLE DEFINITION
-- =============================================================================
-- SQL teaching note:
-- This temporary table acts as a single-row configuration object.
-- Data types are chosen based on intended use:
--   TEXT    = labels / identifiers
--   INTEGER = counts or whole-number controls
--   DATE    = simulation timing fields
--   NUMERIC = financial amounts, rates, and ratios where decimal precision matters
--
-- Why use a temp table?
-- A temporary table keeps the parameter layer explicit and queryable during the
-- session without creating permanent metadata objects in the target schema.

CREATE TEMP TABLE tmp_module1_params (
    scenario_name               TEXT,          -- business-facing run label, e.g. BASELINE or RATE_STRESS_UP_200BP

    -- population_id:
    -- deterministic identifier for the synthetic population.
    -- Same population_id + same parameters = same borrower population.
    population_id               TEXT,

    -- application_count:
    -- number of synthetic applications to generate.
    application_count           INTEGER,
<!-- END_MESSAGE C034-M00556 -->


**Attachments in export:** `Pasted text(54).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m00557"></a>

### C034-M00557

**ChatGPT** · 2026-04-29T09:41:20.398201-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00557 -->
You’re right. My Change 1 was too thin and would downgrade the instructional quality.

Replace the **PARAMETER TABLE DEFINITION** block with this instead. It preserves the original teaching comments and adds archive-specific commentary at the same standard. Current code still has the original parameter definition without archive controls. fileciteturn95file0

```sql
-- =============================================================================
-- PARAMETER TABLE DEFINITION
-- =============================================================================
-- SQL teaching note:
-- This temporary table acts as a single-row configuration object.
-- Data types are chosen based on intended use:
--   TEXT    = labels / identifiers
--   BOOLEAN = true / false execution switches
--   INTEGER = counts or whole-number controls
--   DATE    = simulation timing fields
--   NUMERIC = financial amounts, rates, and ratios where decimal precision matters
--
-- Why use a temp table?
-- A temporary table keeps the parameter layer explicit and queryable during the
-- session without creating permanent metadata objects in the target schema.
--
-- Workstream C teaching note:
-- Module 1 now supports scenario archiving for comparison analysis. This does
-- not change how the synthetic population is generated. Instead, it adds
-- governance around how completed runs are grouped, preserved, replaced, or
-- cleared from the scenario archive.
--
-- Key distinction:
--   scenario_set_name = comparison family / project grouping
--   scenario_name     = individual run within that comparison family
--
-- Example:
--   scenario_set_name = RATE_STRESS_TESTS
--     scenario_name   = BASELINE_V2
--     scenario_name   = RATE_UP_200BP
--
--   scenario_set_name = CREDIT_TIGHTENING_TESTS
--     scenario_name   = BASELINE_V2
--     scenario_name   = TIGHTER_CREDIT_BOX
--
-- This allows users to maintain multiple scenario studies in one governed
-- archive table without creating separate physical tables for each project.

CREATE TEMP TABLE tmp_module1_params (
    -- scenario_set_name:
    -- comparison family / project grouping for archived scenario runs.
    --
    -- Why this exists:
    -- A user may want one archive grouping for rate stress tests, another for
    -- credit tightening tests, and another for growth strategy tests. Keeping
    -- scenario_set_name separate from scenario_name prevents unrelated scenario
    -- studies from being mixed together.
    --
    -- Practical examples:
    --   MODULE1_V2_BASELINE_SET
    --   RATE_STRESS_TESTS
    --   CREDIT_TIGHTENING_TESTS
    --   GROWTH_STRATEGY_TESTS
    scenario_set_name           TEXT,

    -- scenario_name:
    -- business-facing run label inside the scenario set, e.g.
    -- BASELINE_V2, RATE_UP_200BP, TIGHTER_CREDIT_BOX.
    --
    -- Why this matters:
    -- scenario_name identifies the individual strategy / assumption set being
    -- tested. When population_id is held constant, different scenario_name
    -- values can be compared against the same synthetic borrowers.
    scenario_name               TEXT,

    -- archive_run_flag:
    -- controls whether this completed run should be inserted into the permanent
    -- scenario archive table.
    --
    -- TRUE:
    --   store the latest completed run for scenario comparison.
    --
    -- FALSE:
    --   create only the latest-run output table and do not preserve it in the
    --   scenario archive. Useful for quick development tests.
    archive_run_flag            BOOLEAN,

    -- archive_reset_mode:
    -- controls how much existing archive history is cleared before inserting
    -- the current run.
    --
    -- Valid values:
    --   NONE
    --     Do not delete archive rows before inserting. Best used only when the
    --     current scenario_name is new and has not already been archived.
    --
    --   SCENARIO_ONLY
    --     Delete only this scenario_name within this scenario_set_name and
    --     population_id before inserting. This is the safest default for reruns
    --     because it prevents duplicate scenario rows while preserving other
    --     scenarios in the same comparison family.
    --
    --   SET_ONLY
    --     Delete all scenarios within this scenario_set_name and population_id.
    --     Use when restarting a comparison family while preserving other
    --     unrelated scenario sets.
    --
    --   ALL
    --     Delete the entire archive table before inserting. Use only when
    --     intentionally resetting all archived Module 1 scenario history.
    archive_reset_mode          TEXT,

    -- population_id:
    -- deterministic identifier for the synthetic population.
    -- Same population_id + same parameters = same borrower population.
    --
    -- Workstream C note:
    -- For apples-to-apples scenario comparison, keep population_id constant
    -- across scenarios. That ensures scenario differences are caused by changed
    -- assumptions, not by a different synthetic borrower population.
    population_id               TEXT,

    -- application_count:
    -- number of synthetic applications to generate.
    application_count           INTEGER,

    -- portfolio window / reporting context
    portfolio_start_date        DATE,          -- first date in simulated application window
    portfolio_end_date          DATE,          -- last date in simulated application window
    anchor_date                 DATE,          -- reporting reference date for the run

    -- PRODUCT MIX (must sum to 1.00)
    -- These weights control portfolio composition by product type.
    pct_mortgage                NUMERIC(12,6),
    pct_revolving               NUMERIC(12,6),
    pct_auto                    NUMERIC(12,6),
    pct_personal_loan           NUMERIC(12,6),
    pct_heloc                   NUMERIC(12,6),

    -- SCORE BAND MIX (must sum to 1.00)
    -- These weights control borrower quality composition.
    pct_super_prime             NUMERIC(12,6),
    pct_prime                   NUMERIC(12,6),
    pct_near_prime              NUMERIC(12,6),
    pct_subprime                NUMERIC(12,6),
    pct_deep_subprime           NUMERIC(12,6),

    -- RATE ENVIRONMENT
    -- Basis-point shift applied on top of product base APRs.
    rate_shift_bps              INTEGER,

    -- HARD BOUNDS / CORE LIMITS
    -- These are governance rails, not primary business levers.
    min_credit_score            INTEGER,
    max_credit_score            INTEGER,
    min_income                  NUMERIC(18,2),
    max_income                  NUMERIC(18,2),
    min_dti                     NUMERIC(12,4),
    max_dti                     NUMERIC(12,4),
    min_utilization             NUMERIC(12,4),
    max_utilization             NUMERIC(12,4),

    -- PRODUCT AMOUNT BOUNDS
    -- Floor / ceiling values used to generate product-consistent amount anchors.
    min_personal_amt            NUMERIC(18,2),
    max_personal_amt            NUMERIC(18,2),
    min_auto_amt                NUMERIC(18,2),
    max_auto_amt                NUMERIC(18,2),
    min_revolving_amt           NUMERIC(18,2),
    max_revolving_amt           NUMERIC(18,2),
    min_heloc_amt               NUMERIC(18,2),
    max_heloc_amt               NUMERIC(18,2),
    min_mortgage_amt            NUMERIC(18,2),
    max_mortgage_amt            NUMERIC(18,2),

    -- PRODUCT BASE RATES (APR proxies before risk premium and macro shift)
    -- These are affordability anchors, not final pricing offers.
    base_rate_mortgage          NUMERIC(12,6),
    base_rate_auto              NUMERIC(12,6),
    base_rate_personal          NUMERIC(12,6),
    base_rate_revolving         NUMERIC(12,6),
    base_rate_heloc             NUMERIC(12,6),

    -- PRODUCT LGD ASSUMPTIONS
    -- Product-level loss severity assumptions used in expected loss.
    lgd_mortgage                NUMERIC(12,6),
    lgd_auto                    NUMERIC(12,6),
    lgd_personal                NUMERIC(12,6),
    lgd_revolving               NUMERIC(12,6),
    lgd_heloc                   NUMERIC(12,6)
);
```

And yes: when we update the `INSERT INTO tmp_module1_params VALUES (...)`, we need the same level of commentary there too.
<!-- END_MESSAGE C034-M00557 -->


---

<a id="c034-m00559"></a>

### C034-M00559

**Andrew** · 2026-04-29T10:31:58.498000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00559 -->
review INSERT INTO tmp_module1_params to make sure commentary is elite and change 2 is incorporated.  current INSERT INTO tmp_module1_params: 
<!-- END_MESSAGE C034-M00559 -->


**Attachments in export:** `Pasted text(55).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m00560"></a>

### C034-M00560

**ChatGPT** · 2026-04-29T10:32:04.645647-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00560 -->
Yes — current `INSERT INTO tmp_module1_params` needs to be expanded to match the new parameter table structure. It currently starts with `scenario_name`, then `population_id`, so it does **not yet incorporate Workstream C archive controls.** fileciteturn96file0

Replace your current `INSERT INTO tmp_module1_params VALUES (...)` with this:

```sql
INSERT INTO tmp_module1_params VALUES (
    'MODULE1_V2_BASELINE_SET', -- scenario_set_name:
                               -- comparison family / project grouping for archived runs.
                               --
                               -- Why this matters:
                               -- scenario_set_name lets users keep separate scenario studies
                               -- inside one governed archive table without creating separate
                               -- physical tables for every project.
                               --
                               -- Practical examples:
                               --   RATE_STRESS_TESTS
                               --   CREDIT_TIGHTENING_TESTS
                               --   GROWTH_STRATEGY_TESTS
                               --
                               -- Best practice:
                               -- Keep this constant for scenarios that should be compared
                               -- together. Change it when starting a separate comparison family.

    'BASELINE_V2',             -- scenario_name:
                               -- individual run label inside the scenario set.
                               --
                               -- Why this matters:
                               -- scenario_name identifies the specific assumption set being
                               -- tested, such as BASELINE_V2, RATE_UP_200BP, or
                               -- TIGHTER_CREDIT_BOX.
                               --
                               -- Workstream C note:
                               -- For apples-to-apples comparison, run a baseline scenario and
                               -- one or more alternative scenarios under the same
                               -- scenario_set_name and population_id.

    TRUE,                      -- archive_run_flag:
                               -- TRUE  = insert this completed run into the scenario archive
                               -- FALSE = produce only the latest-run output table.
                               --
                               -- Use TRUE for comparison-ready runs.
                               -- Use FALSE for quick development tests that should not be
                               -- preserved in the archive.

    'SCENARIO_ONLY',           -- archive_reset_mode:
                               -- controls how much existing archive history is cleared before
                               -- this run is inserted.
                               --
                               -- Valid values:
                               --   NONE
                               --     preserve existing archive rows. Use only when inserting a
                               --     brand-new scenario_name.
                               --
                               --   SCENARIO_ONLY
                               --     replace only this scenario within the same
                               --     scenario_set_name + population_id. This is the safest
                               --     default for rerunning a scenario.
                               --
                               --   SET_ONLY
                               --     clear all scenarios within this scenario_set_name and
                               --     population_id. Use when restarting a comparison family.
                               --
                               --   ALL
                               --     clear the entire archive table. Use only when intentionally
                               --     resetting all archived scenario history.

    'BASE_POPULATION_V1',      -- population_id:
                               -- deterministic identity for this borrower population.
                               --
                               -- CRITICAL:
                               --   Keep this constant when comparing V1 vs V2, baseline vs
                               --   stress, or any scenario set where you want the exact same
                               --   borrowers.
                               --
                               --   Change this value ONLY when intentionally generating a new
                               --   synthetic population.

    50000,                     -- application_count:
                               -- number of synthetic applications to generate.
                               --
                               -- Guidance:
                               --   500     = smoke test
                               --   5,000   = development validation
                               --   10,000  = stronger calibration review
                               --   50,000  = full portfolio validation
```

Then keep the rest of your existing values from:

```sql
DATE '2025-01-01',
...
```

through the LGD values unchanged.
<!-- END_MESSAGE C034-M00560 -->


---

<a id="c034-m00562"></a>

### C034-M00562

**Andrew** · 2026-04-29T11:04:12.190000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00562 -->
I feel like this section 10 could be more commented - following elite commentary pattern we established in section 9: /*
================================================================================
SECTION 10. SCENARIO COMPARISON QA
================================================================================
Purpose:
  Compare archived Module 1 scenarios within a selected scenario_set_name.

Why this section matters:
  Module 1 is not only a synthetic portfolio generator. With deterministic
  population_id and archived outputs, it becomes a controlled scenario comparison
  engine.

Important boundary:
  This section does not make approval, decline, pricing, or manual review
  decisions. Those belong in later modules.

  Section 10 answers:
      What changed between scenarios?

  Later modules will answer:
      What decision should we make because of those changes?

How to use:
  1. Run a baseline scenario with archive_run_flag = TRUE
  2. Change scenario_name and one or more parameters
  3. Keep population_id constant for apples-to-apples comparison
  4. Rerun and archive the new scenario
  5. Use the queries below to compare archived results

Key analytical principle:
  Holding population_id constant means each scenario is evaluated on the same
  synthetic borrowers. This removes population noise and makes changes easier
  to attribute to scenario assumptions.
*/

-- 10.1 Scenario archive inventory
-- Purpose:
--   Show which scenario sets and scenarios are currently available for
--   comparison.
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_archived,
    MIN(scenario_archived_ts) AS first_archived_ts,
    MAX(scenario_archived_ts) AS last_archived_ts
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;

-- 10.2 Portfolio-level scenario summary
-- Purpose:
--   Compare major portfolio metrics across scenarios in the same scenario set.
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(estimated_lgd)::numeric, 4) AS avg_lgd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss,
    ROUND(SUM(expected_loss_amount)::numeric, 2) AS total_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;

-- 10.3 Product x score scenario summary
-- Purpose:
--   Show where scenario differences concentrate by product and score band.
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band
ORDER BY
    scenario_set_name,
    population_id,
    product_type,
    score_band,
    scenario_name;
<!-- END_MESSAGE C034-M00562 -->


---

<a id="c034-m00563"></a>

### C034-M00563

**ChatGPT** · 2026-04-29T11:04:15.586640-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00563 -->
You’re right — this is **good**, but not yet at the same level as Section 9. Section 9 teaches the reader *how to interpret outputs*, not just what they are. Section 10 should do the same.

Below is a **fully upgraded Section 10** that matches your elite commentary standard: more teaching, clearer interpretation guidance, and explicit analytical framing.

---

```sql
/*
================================================================================
SECTION 10. SCENARIO COMPARISON QA
================================================================================
Purpose:
  Compare archived Module 1 scenarios within a selected scenario_set_name.

Why this section matters:
  Module 1 is not only a synthetic portfolio generator. With deterministic
  population_id and archived outputs, it becomes a controlled scenario comparison
  engine.

  Section 9 answered:
      "Is this single scenario internally consistent and realistic?"

  Section 10 answers:
      "How do two or more scenarios differ, and where are those differences coming from?"

Important boundary:
  This section does NOT make approval, decline, pricing, or manual review
  decisions. Those belong in later modules.

  Section 10 is strictly diagnostic and comparative.

  It answers:
      What changed between scenarios?
      Where did those changes occur (product, score, affordability)?
      How large are those changes at portfolio and segment levels?

  Later modules will answer:
      What decision should we make because of those changes?

--------------------------------------------------------------------------------
HOW TO USE THIS SECTION
--------------------------------------------------------------------------------
1. Run a baseline scenario with:
       archive_run_flag = TRUE

2. Modify one or more parameters:
       - rate_shift_bps
       - product mix
       - score mix
       - affordability assumptions
       - etc.

3. Change scenario_name to reflect the new assumption set.

4. Keep population_id CONSTANT.
   This is critical for apples-to-apples comparison.

5. Rerun and archive the new scenario.

6. Use the queries below to compare results.

--------------------------------------------------------------------------------
KEY ANALYTICAL PRINCIPLE
--------------------------------------------------------------------------------
Holding population_id constant ensures that:

  - The same synthetic borrowers appear in every scenario
  - Differences in results are caused by parameter changes
  - NOT by differences in the underlying population

This allows:
  - clean attribution of change
  - true scenario comparison rather than distribution comparison

--------------------------------------------------------------------------------
HOW TO INTERPRET RESULTS
--------------------------------------------------------------------------------
Read Section 10 outputs in layers:

  Layer 1 (10.2):
    Portfolio-level movement
    → "Did risk go up or down overall?"

  Layer 2 (10.3):
    Segment-level movement
    → "Where did the change happen?"

  (Optional future extension)
  Layer 3:
    Row-level matched comparison
    → "Which borrowers changed and why?"

--------------------------------------------------------------------------------
COMMON PITFALLS TO AVOID
--------------------------------------------------------------------------------
1. Changing population_id between scenarios:
     This invalidates comparisons.

2. Using archive_reset_mode = ALL unintentionally:
     This deletes prior scenarios needed for comparison.

3. Comparing scenarios across different scenario_set_name values:
     These are intended to represent separate analysis families.

4. Interpreting small differences as signal:
     Always look for consistent directional movement across segments.

--------------------------------------------------------------------------------
*/


-- =============================================================================
-- 10.1 SCENARIO ARCHIVE INVENTORY
-- =============================================================================
-- Purpose:
--   Show which scenario sets, scenarios, and populations are available.
--
-- Why this matters:
--   Before comparing anything, confirm:
--     - which scenarios exist
--     - which population_id they use
--     - whether they are directly comparable
--
-- Interpretation guidance:
--   - rows_archived should match application_count for each scenario
--   - multiple scenario_name values under the same scenario_set_name
--     represent a valid comparison group
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_archived,
    MIN(scenario_archived_ts) AS first_archived_ts,
    MAX(scenario_archived_ts) AS last_archived_ts
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;


-- =============================================================================
-- 10.2 PORTFOLIO-LEVEL SCENARIO SUMMARY
-- =============================================================================
-- Purpose:
--   Compare major portfolio metrics across scenarios.
--
-- What this shows:
--   First-order impact of parameter changes.
--
-- Key metrics:
--   avg_requested_amount → exposure level
--   avg_apr              → pricing / rate environment
--   avg_pti              → affordability pressure
--   avg_pd               → risk level
--   avg_expected_loss    → financial impact
--
-- Interpretation guidance:
--   - If avg_pti increases, expect avg_pd to increase (directionally)
--   - If avg_apr increases, payment burden should increase
--   - Expected loss should reflect both exposure AND PD changes
--
-- Example read:
--   "Scenario B increased avg PD by +180 bps, driven by a +3.5% increase
--    in PTI and slightly higher APR."
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(estimated_lgd)::numeric, 4) AS avg_lgd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss,
    ROUND(SUM(expected_loss_amount)::numeric, 2) AS total_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;


-- =============================================================================
-- 10.3 PRODUCT × SCORE SCENARIO SUMMARY
-- =============================================================================
-- Purpose:
--   Identify where scenario differences concentrate across segments.
--
-- Why this matters:
--   Portfolio averages can hide where risk is actually moving.
--
-- This query answers:
--   - Which product segments changed the most?
--   - Which score bands are driving risk changes?
--   - Are changes broad-based or concentrated?
--
-- Interpretation guidance:
--   Look for:
--     - consistent increases across all segments → macro effect
--     - isolated spikes (e.g., Subprime Revolving) → targeted sensitivity
--     - divergence between products → structural differences
--
-- Example read:
--   "Most of the PD increase came from Subprime Revolving and
--    Near Prime Personal Loans, suggesting the rate shift is
--    disproportionately affecting unsecured exposure."
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band
ORDER BY
    scenario_set_name,
    population_id,
    product_type,
    score_band,
    scenario_name;
```

---

## What improved (and why this now matches your standard)

- **Clear analytical layers (portfolio → segment)**
- **Explicit interpretation guidance per query**
- **Common pitfalls called out (huge for credibility)**
- **Narrative continuity with Section 9**
- **Concrete “how to read this” examples**

---

If you want next step at the same level:

👉 We should add **10.4: matched row-level comparison (baseline vs scenario)**  
That’s the piece that will really make this feel *enterprise-grade*.
<!-- END_MESSAGE C034-M00563 -->


---

<a id="c034-m00564"></a>

### C034-M00564

**Andrew** · 2026-04-29T11:07:52.098000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00564 -->
let's add: 10.4: matched row-level comparison (baseline vs scenario)
<!-- END_MESSAGE C034-M00564 -->


---

<a id="c034-m00565"></a>

### C034-M00565

**ChatGPT** · 2026-04-29T11:08:05.094113-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00565 -->
Yes — add this after **10.3**.

```sql
-- =============================================================================
-- 10.4 MATCHED ROW-LEVEL SCENARIO COMPARISON
-- =============================================================================
-- Purpose:
--   Compare two archived scenarios borrower-by-borrower using the same
--   population_id and application_id.
--
-- Why this matters:
--   Portfolio-level and segment-level summaries show what changed in aggregate.
--   A matched row-level comparison shows how the same synthetic borrowers moved
--   between scenarios.
--
-- Key analytical principle:
--   Because population_id is deterministic, each application_id represents the
--   same synthetic borrower across scenarios when population_id is held constant.
--
-- This allows true apples-to-apples comparison:
--   baseline borrower A  →  comparison borrower A
--   baseline borrower B  →  comparison borrower B
--   baseline borrower C  →  comparison borrower C
--
-- What this query helps answer:
--   - Which individual rows experienced the largest PD increase?
--   - Which rows experienced the largest expected loss increase?
--   - Did payment burden increase for the same borrowers?
--   - Are changes concentrated in specific products or score bands?
--
-- Important boundary:
--   This is still diagnostic analysis. It does not approve, decline, reprice,
--   or assign treatments. Those decision layers belong in later modules.
--
-- How to use:
--   Update the values in tmp_module1_compare_scenarios below to identify:
--     - the scenario_set_name to compare within
--     - the shared population_id
--     - the baseline scenario
--     - the comparison scenario
--
-- Example:
--   baseline_scenario_name   = BASELINE_V2
--   comparison_scenario_name = RATE_UP_200BP
--
-- Interpretation guidance:
--   Positive deltas mean the comparison scenario increased the metric.
--   Negative deltas mean the comparison scenario reduced the metric.
--
--   For example:
--     delta_pti = +0.0250
--       means the borrower’s payment-to-income burden increased by 2.5
--       percentage points in the comparison scenario.
--
--     delta_pd = +0.0180
--       means estimated PD increased by 1.8 percentage points.
--
--     delta_expected_loss = +500.00
--       means expected loss increased by $500 for that matched borrower.

DROP TABLE IF EXISTS tmp_module1_compare_scenarios;

CREATE TEMP TABLE tmp_module1_compare_scenarios AS
SELECT
    'MODULE1_V2_BASELINE_SET'::TEXT AS scenario_set_name,
    'BASE_POPULATION_V1'::TEXT      AS population_id,
    'BASELINE_V2'::TEXT             AS baseline_scenario_name,
    'RATE_UP_200BP'::TEXT           AS comparison_scenario_name;


-- 10.4A Matched row-level delta sample
-- Purpose:
--   Show the largest borrower-level expected loss increases between the baseline
--   and comparison scenarios.
--
-- Why order by delta_expected_loss descending?
--   Expected loss combines:
--     exposure × PD × LGD
--
--   Sorting by expected loss change highlights the rows with the greatest
--   financial movement, not just the greatest risk-rate movement.
--
-- What to look for:
--   - Are the largest increases concentrated in high-PTI borrowers?
--   - Are they concentrated in weaker score bands?
--   - Are certain products more sensitive than others?
--   - Do PD and PTI move together in a sensible direction?

SELECT
    b.scenario_set_name,
    b.population_id,
    b.application_id,
    b.applicant_id,

    b.product_type,
    b.score_band,

    b.requested_amount AS baseline_requested_amount,
    c.requested_amount AS comparison_requested_amount,
    ROUND((c.requested_amount - b.requested_amount)::numeric, 2) AS delta_requested_amount,

    b.base_apr_for_payment_calc AS baseline_apr,
    c.base_apr_for_payment_calc AS comparison_apr,
    ROUND((c.base_apr_for_payment_calc - b.base_apr_for_payment_calc)::numeric, 4) AS delta_apr,

    b.monthly_payment_proxy AS baseline_monthly_payment,
    c.monthly_payment_proxy AS comparison_monthly_payment,
    ROUND((c.monthly_payment_proxy - b.monthly_payment_proxy)::numeric, 2) AS delta_monthly_payment,

    b.payment_to_income_ratio AS baseline_pti,
    c.payment_to_income_ratio AS comparison_pti,
    ROUND((c.payment_to_income_ratio - b.payment_to_income_ratio)::numeric, 4) AS delta_pti,

    b.estimated_pd AS baseline_pd,
    c.estimated_pd AS comparison_pd,
    ROUND((c.estimated_pd - b.estimated_pd)::numeric, 4) AS delta_pd,

    b.expected_loss_amount AS baseline_expected_loss,
    c.expected_loss_amount AS comparison_expected_loss,
    ROUND((c.expected_loss_amount - b.expected_loss_amount)::numeric, 2) AS delta_expected_loss

FROM credit_decisioning_sim.synthetic_applications_scenario_archive b
JOIN credit_decisioning_sim.synthetic_applications_scenario_archive c
  ON  b.scenario_set_name = c.scenario_set_name
  AND b.population_id = c.population_id
  AND b.application_id = c.application_id
CROSS JOIN tmp_module1_compare_scenarios p
WHERE b.scenario_set_name = p.scenario_set_name
  AND b.population_id = p.population_id
  AND b.scenario_name = p.baseline_scenario_name
  AND c.scenario_name = p.comparison_scenario_name
ORDER BY
    delta_expected_loss DESC
LIMIT 50;


-- 10.4B Matched row-level delta summary
-- Purpose:
--   Summarize borrower-level movements between the baseline and comparison
--   scenarios.
--
-- Why this matters:
--   The sample query above shows individual high-impact rows. This query
--   summarizes the full matched population.
--
-- What this tells reviewers:
--   - how many borrowers were matched
--   - average metric movement
--   - how many rows increased or decreased in PD
--   - how many rows increased or decreased in expected loss
--
-- Interpretation guidance:
--   matched_rows should equal application_count when:
--     - both scenarios used the same population_id
--     - both scenarios were fully archived
--     - no scenario rows were accidentally cleared

WITH matched_rows AS (
    SELECT
        b.application_id,
        b.product_type,
        b.score_band,

        c.requested_amount - b.requested_amount AS delta_requested_amount,
        c.base_apr_for_payment_calc - b.base_apr_for_payment_calc AS delta_apr,
        c.monthly_payment_proxy - b.monthly_payment_proxy AS delta_monthly_payment,
        c.payment_to_income_ratio - b.payment_to_income_ratio AS delta_pti,
        c.estimated_pd - b.estimated_pd AS delta_pd,
        c.expected_loss_amount - b.expected_loss_amount AS delta_expected_loss

    FROM credit_decisioning_sim.synthetic_applications_scenario_archive b
    JOIN credit_decisioning_sim.synthetic_applications_scenario_archive c
      ON  b.scenario_set_name = c.scenario_set_name
      AND b.population_id = c.population_id
      AND b.application_id = c.application_id
    CROSS JOIN tmp_module1_compare_scenarios p
    WHERE b.scenario_set_name = p.scenario_set_name
      AND b.population_id = p.population_id
      AND b.scenario_name = p.baseline_scenario_name
      AND c.scenario_name = p.comparison_scenario_name
)

SELECT
    COUNT(*) AS matched_rows,

    ROUND(AVG(delta_requested_amount)::numeric, 2) AS avg_delta_requested_amount,
    ROUND(AVG(delta_apr)::numeric, 4) AS avg_delta_apr,
    ROUND(AVG(delta_monthly_payment)::numeric, 2) AS avg_delta_monthly_payment,
    ROUND(AVG(delta_pti)::numeric, 4) AS avg_delta_pti,
    ROUND(AVG(delta_pd)::numeric, 4) AS avg_delta_pd,
    ROUND(AVG(delta_expected_loss)::numeric, 2) AS avg_delta_expected_loss,

    COUNT(*) FILTER (WHERE delta_pd > 0) AS rows_pd_increased,
    COUNT(*) FILTER (WHERE delta_pd < 0) AS rows_pd_decreased,
    COUNT(*) FILTER (WHERE delta_pd = 0) AS rows_pd_unchanged,

    COUNT(*) FILTER (WHERE delta_expected_loss > 0) AS rows_el_increased,
    COUNT(*) FILTER (WHERE delta_expected_loss < 0) AS rows_el_decreased,
    COUNT(*) FILTER (WHERE delta_expected_loss = 0) AS rows_el_unchanged

FROM matched_rows;


-- 10.4C Matched row-level delta summary by product and score band
-- Purpose:
--   Aggregate matched borrower changes by product and score segment.
--
-- Why this matters:
--   This bridges row-level comparison and executive segment reporting.
--
-- This query answers:
--   - Which product × score cells drove the change?
--   - Did weaker score bands experience larger PD movement?
--   - Did secured and unsecured products react differently?
--
-- Interpretation guidance:
--   This is often the most useful comparison view for strategy discussion.
--   It shows not only that the scenario changed outcomes, but where the change
--   was concentrated.

WITH matched_rows AS (
    SELECT
        b.application_id,
        b.product_type,
        b.score_band,

        c.requested_amount - b.requested_amount AS delta_requested_amount,
        c.base_apr_for_payment_calc - b.base_apr_for_payment_calc AS delta_apr,
        c.monthly_payment_proxy - b.monthly_payment_proxy AS delta_monthly_payment,
        c.payment_to_income_ratio - b.payment_to_income_ratio AS delta_pti,
        c.estimated_pd - b.estimated_pd AS delta_pd,
        c.expected_loss_amount - b.expected_loss_amount AS delta_expected_loss

    FROM credit_decisioning_sim.synthetic_applications_scenario_archive b
    JOIN credit_decisioning_sim.synthetic_applications_scenario_archive c
      ON  b.scenario_set_name = c.scenario_set_name
      AND b.population_id = c.population_id
      AND b.application_id = c.application_id
    CROSS JOIN tmp_module1_compare_scenarios p
    WHERE b.scenario_set_name = p.scenario_set_name
      AND b.population_id = p.population_id
      AND b.scenario_name = p.baseline_scenario_name
      AND c.scenario_name = p.comparison_scenario_name
)

SELECT
    product_type,
    score_band,
    COUNT(*) AS matched_rows,

    ROUND(AVG(delta_requested_amount)::numeric, 2) AS avg_delta_requested_amount,
    ROUND(AVG(delta_apr)::numeric, 4) AS avg_delta_apr,
    ROUND(AVG(delta_monthly_payment)::numeric, 2) AS avg_delta_monthly_payment,
    ROUND(AVG(delta_pti)::numeric, 4) AS avg_delta_pti,
    ROUND(AVG(delta_pd)::numeric, 4) AS avg_delta_pd,
    ROUND(AVG(delta_expected_loss)::numeric, 2) AS avg_delta_expected_loss,

    ROUND(SUM(delta_expected_loss)::numeric, 2) AS total_delta_expected_loss

FROM matched_rows
GROUP BY
    product_type,
    score_band
ORDER BY
    product_type,
    CASE score_band
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 6
    END;
```

This is the right **10.4** foundation. It gives you:

- row-level matched samples  
- full matched-population summary  
- product × score attribution bridge  

I’d add this before moving to any more advanced driver decomposition.
<!-- END_MESSAGE C034-M00565 -->


---

<a id="c034-m00568"></a>

### C034-M00568

**Andrew** · 2026-04-29T12:08:28.993000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00568 -->
ok, i assume to run this, we need to run the code twice - once for BASELINE_V2 and again for RATE_UP_200BP.  please give me run instructions and also evaluate the full V2 code, including comments/headers: 
<!-- END_MESSAGE C034-M00568 -->


**Attachments in export:** `Pasted text(56).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m00571"></a>

### C034-M00571

**ChatGPT** · 2026-04-29T12:08:53.928891-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00571 -->
Yes — to use **10.4 matched row-level comparison**, you need to run the full script **twice**:

1. once as `BASELINE_V2`
2. once as `RATE_UP_200BP`

Both runs must use the same:

```sql
scenario_set_name = 'MODULE1_V2_BASELINE_SET'
population_id     = 'BASE_POPULATION_V1'
archive_run_flag  = TRUE
```

Your current code includes the archive table, `scenario_archived_ts`, archive reset logic, archive indexes, and the Section 10 matched-row comparison control table for `BASELINE_V2` vs `RATE_UP_200BP`. fileciteturn99file0turn99file5

## Run instructions

### Run 1 — Baseline

Use these parameter values:

```sql
'MODULE1_V2_BASELINE_SET', -- scenario_set_name
'BASELINE_V2',             -- scenario_name
TRUE,                      -- archive_run_flag
'SCENARIO_ONLY',           -- archive_reset_mode
'BASE_POPULATION_V1',      -- population_id
...
0,                         -- rate_shift_bps
```

Run Sections **0 through 8.5**.

Then run:

```sql
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_archived
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id;
```

You should see `BASELINE_V2` with `50,000` rows.

### Run 2 — Rate stress scenario

Change only:

```sql
'RATE_UP_200BP',           -- scenario_name
...
200,                       -- rate_shift_bps
```

Keep these unchanged:

```sql
'MODULE1_V2_BASELINE_SET', -- scenario_set_name
TRUE,                      -- archive_run_flag
'SCENARIO_ONLY',           -- archive_reset_mode
'BASE_POPULATION_V1',      -- population_id
50000,                     -- application_count
```

Run Sections **0 through 8.5** again.

Then run the inventory query again. You should see:

```text
BASELINE_V2       50,000
RATE_UP_200BP     50,000
```

### Then run Section 10

Run Section 10 after both scenarios are archived. Your `tmp_module1_compare_scenarios` is already configured to compare:

```sql
'BASELINE_V2'   AS baseline_scenario_name,
'RATE_UP_200BP' AS comparison_scenario_name
```

That matches the two-run approach. fileciteturn98file3

---

## Important execution note

Do **not** use:

```sql
archive_reset_mode = 'ALL'
```

on Run 2. That would delete the baseline archive before inserting the rate-up scenario.

Use:

```sql
'SCENARIO_ONLY'
```

for both runs.

---

# Full V2 code evaluation

Overall: **the code is in strong shape and ready for the two-run scenario comparison test.** The core structure is correct:

- Section 8.5 persists scenario runs instead of overwriting all comparison history.
- `SCENARIO_ONLY` correctly deletes only the current scenario within the same set and population.
- Section 10 has the right comparison structure: inventory, portfolio summary, product × score summary, and matched row-level comparison.
- `scenario_set_name`, `scenario_name`, and `population_id` are the correct comparison keys.

I see **three documentation refinements** I would make before calling this final-final.

## 1. Top header Section E is now stale

Current Section 5.E says scenario comparison is a “future enhancement.” But Workstream C is now implemented.

### Replace this heading

```text
E. Structured foundation for scenario comparison
```

### With

```text
E. Scenario comparison framework and archive persistence
```

### Replace the paragraph with

```text
   V2 now includes a governed scenario archive and comparison QA framework that
   allows multiple completed Module 1 runs to be preserved and compared.

   This framework supports:

     - scenario_set_name for separating comparison families
     - scenario_name for labeling individual runs
     - archive_reset_mode for controlled archive replacement / clearing
     - deterministic population alignment via population_id
     - portfolio-level, segment-level, and matched row-level comparison outputs

   Result:
     Module 1 now supports controlled apples-to-apples scenario comparison while
     preserving its boundary as a synthetic application and risk modeling engine.
```

## 2. Section 2 still says parameters fall into five groups

Your updated parameter table now adds archive controls, so the Section 2 overview should say **six groups**, not five. The current text still lists five groups. fileciteturn99file6

Add this as the new first group:

```text
  1. SCENARIO ARCHIVE / COMPARISON CONTROLS
     Controls how runs are grouped, archived, replaced, or cleared for
     scenario comparison.

  2. RUN IDENTITY / REPRODUCIBILITY
     Controls how the run is labeled and whether the same synthetic population
     is regenerated consistently.
```

Then renumber the rest.

## 3. Section 10 header says row-level comparison is optional future extension

Now that 10.4 exists, update this part.

### Before

```text
  (Optional future extension)
  Layer 3:
    Row-level matched comparison
    → "Which borrowers changed and why?"
```

### After

```text
  Layer 3 (10.4):
    Row-level matched comparison
    → "Which borrowers changed and why?"
```

---

## One possible technical issue to watch

Your archive table is created with:

```sql
CREATE TABLE IF NOT EXISTS ... (LIKE synthetic_applications INCLUDING DEFAULTS);
ALTER TABLE ... ADD COLUMN IF NOT EXISTS scenario_archived_ts TIMESTAMP;
```

That is fine for first creation. But if you later add columns to `synthetic_applications`, an existing archive table will not automatically inherit those new columns. For current testing, this is fine. For long-term GitHub documentation, add a short note in Section 8.5:

```sql
-- Development note:
-- If the final output schema changes during future development, recreate or
-- alter the archive table so its columns remain aligned with synthetic_applications.
```

## Final verdict

Proceed with the two-run test.

Use:

```text
Run 1: BASELINE_V2, rate_shift_bps = 0
Run 2: RATE_UP_200BP, rate_shift_bps = 200
Then: Section 10
```

The code is structurally ready. Only the three commentary updates above are needed for full narrative alignment.
<!-- END_MESSAGE C034-M00571 -->


---

<a id="c034-m00573"></a>

### C034-M00573

**Andrew** · 2026-04-29T13:15:40.825000-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00573 -->
evaluate results:
<!-- END_MESSAGE C034-M00573 -->


**Attachments in export:** `module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_c1.csv`, `module1_synthetic_application_risk_engine_v2.0_10.02_QA_portfolio_level_scenario_summary_c1.csv`, `module1_synthetic_application_risk_engine_v2.0_10.01_QA_scenario_archive_inventory_c1.csv`, `module1_synthetic_application_risk_engine_v2.0_10.04C_QA_matched_row_level_delta_summary_by_product_and_score_band_c1.csv`, `module1_synthetic_application_risk_engine_v2.0_10.04B_QA_matched_row_level_delta_summary_c1.csv`, `module1_synthetic_application_risk_engine_v2.0_10.04A_QA_matched_row_level_delta_sample_c1.csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c034-m00574"></a>

### C034-M00574

**ChatGPT** · 2026-04-29T13:15:46.761843-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00574 -->
I’ll review the C1 outputs across archive integrity, portfolio deltas, segment deltas, and matched row-level behavior to confirm the scenario framework is working—not just running.
<!-- END_MESSAGE C034-M00574 -->


---

<a id="c034-m00577"></a>

### C034-M00577

**ChatGPT** · 2026-04-29T13:16:47.914836-04:00 · active path

<!-- BEGIN_MESSAGE C034-M00577 -->
C1 **passes**. The scenario comparison framework is working correctly and producing analytically coherent results.

## 1. Archive integrity: pass

Both scenarios archived correctly:

| Scenario | Rows |
|---|---:|
| `BASELINE_V2` | 50,000 |
| `RATE_UP_200BP` | 50,000 |

Same `scenario_set_name`, same `population_id`, same row count. That confirms the archive logic and apples-to-apples setup are working.

## 2. Portfolio-level comparison: pass

| Metric | Baseline | Rate +200bp | Delta |
|---|---:|---:|---:|
| Avg APR | 0.1456 | 0.1614 | +0.0158 |
| Avg monthly payment | 1,509.44 | 1,607.24 | +97.80 |
| Avg PTI | 0.1646 | 0.1732 | +0.0086 |
| Avg PD | 0.1633 | 0.1637 | +0.0004 |
| Avg EL | 4,787.20 | 4,802.03 | +14.83 |
| Total EL | 239.36M | 240.10M | +741K |

This is exactly the expected narrative: a rate shock increases APR, payment burden, PTI, and expected loss, but does not dramatically reshape the portfolio.

## 3. Matched row-level comparison: pass

Matched rows:

```text
50,000
```

That is the most important C1 validation result. It proves the join is truly matching the same synthetic borrowers across scenarios.

Key row-level deltas:

| Metric | Avg Delta |
|---|---:|
| Requested amount | -120.64 |
| APR | +0.0158 |
| Monthly payment | +97.80 |
| PTI | +0.0086 |
| PD | +0.0004 |
| Expected loss | +14.82 |

The small negative requested amount delta is not a defect. It is explainable: the rate-up scenario increases provisional payment pressure, which can trigger slightly stronger mortgage affordability dampening. That is a good sign that A3 is interacting realistically with the rate environment.

## 4. Product-level interpretation: strong

The biggest payment/PTI sensitivity appears in secured longer-duration products:

| Product | Avg Δ Payment | Avg Δ PTI | Avg Δ PD | Total Δ EL |
|---|---:|---:|---:|---:|
| Mortgage | +228.81 | +0.0185 | +0.0003 | +167.6K |
| HELOC | +160.60 | +0.0153 | +0.0016 | +340.8K |
| Auto | +43.21 | +0.0052 | +0.0007 | +155.8K |
| Personal | +28.60 | +0.0034 | +0.0004 | +77.1K |
| Revolving | +0.00 | +0.0000 | +0.0000 | 0 |

The revolving result is explainable because the current revolving payment proxy is not APR-sensitive. That is not wrong, but it is worth documenting as a Module 1 limitation or future enhancement if you want rate shocks to affect revolving minimum payments.

## 5. 10.4A sample: excellent diagnostic value

The largest row-level EL increases are concentrated in HELOC and mortgage near-prime borrowers with meaningful PTI movement. That is intuitive: large balances + rate shock + payment burden translate into higher PD and EL.

Example pattern from the sample:

```text
HELOC / NEAR_PRIME
APR +0.0200
PTI +0.029–0.032
PD +0.034–0.038
EL +~2,100 to +2,285
```

That is exactly the type of story Section 10 was designed to reveal.

## Final verdict

Workstream C1 is successful.

Status:

```text
Archive persistence: PASS
Scenario inventory: PASS
Portfolio scenario summary: PASS
Product × score comparison: PASS
Matched row-level comparison: PASS
Analytical coherence: PASS
```

Only recommendation: add a short note in Section 10 or future enhancements that **revolving payment is currently not rate-sensitive**, so rate stress impacts revolving APR but not revolving payment/PTI under the current Module 1 design.
<!-- END_MESSAGE C034-M00577 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_13.md) · [Next](Part_15.md)
