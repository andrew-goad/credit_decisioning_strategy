# Campaign QA and strategy expansion

## Part 10

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_09.md) · [Next](Part_11.md)

<a id="c040-m02485"></a>

### C040-M02485

**ChatGPT** · 2026-05-27T03:40:16.432506-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02485 -->
You’re right. The rate up/down scenarios are the cleanest and easiest to explain, but they are also the **simplest** Module 1 scenario family. If the Module 1 README collage leans too heavily on rate up/down, it undersells the richer scenario architecture.

The current Module 1 panel plan does three things well:

```text
Panel 1:
    Baseline product × score risk surface

Panel 2:
    Rate-environment transmission chain

Panel 3:
    Matched RATE_UP_200BP attribution
```

That is coherent, but it overweights one scenario family: rate sensitivity. Module 1 is broader than that. The BRD frames Module 1 as a governed scenario-capable simulation engine where credit risk emerges from borrower characteristics, product structure, affordability, and macro conditions, not borrower profile alone. It explicitly models the chain from rate environment through APR, payment, PTI, estimated-PD proxy, and Expected Loss, but the broader goal is controlled scenario-based strategy evaluation across product and risk structures. fileciteturn49file88

## My revised view

I would keep **Panel 1** exactly as planned. It is foundational.

But I would reconsider Panels 2 and 3 so the collage shows more of Module 1’s scenario breadth.

The strongest Module 1 collage story should probably be:

```text
Panel 1:
    Product × Score Risk Surface
    “The baseline population is product-aware and score-aware.”

Panel 2:
    Scenario Lever Matrix
    “Different scenario families stress different parts of the risk engine.”

Panel 3:
    Matched Attribution Deep Dive
    “A selected scenario delta can be traced row-for-row and product × score.”
```

That is stronger than two rate-centric panels.

## Why the other scenarios matter

The rate scenarios show the clean economic chain:

```text
Rate Environment → APR → Payment → PTI → Expected Loss
```

But the other scenario families demonstrate more nuanced simulation capability:

```text
Credit Box Sensitivity:
    Changes score-mix / borrower-risk composition.

Portfolio Mix Sensitivity:
    Changes product structure and therefore exposure / LGD / payment dynamics.

Exposure Intensity Sensitivity:
    Changes requested exposure appetite and balance structure.

LGD Severity Sensitivity:
    Changes loss severity, which can move Expected Loss even when APR / PTI / PD proxy are not the main story.
```

That is more sophisticated than rate up/down. The formal campaign roadmap explicitly includes rate environment, credit box, portfolio mix, exposure intensity, and LGD severity scenario families, plus the later Option C addendum on the Module 2 side. fileciteturn50file16

## Recommended Panel 2 replacement

Instead of the current **Scenario Transmission Chain** line chart, I would use a broader:

```text
Scenario Lever Matrix
```

### What it would show

Rows would be selected Module 1 scenarios, grouped by family:

```text
Rate Environment
Credit Box
Portfolio Mix
Exposure Intensity
LGD Severity
```

Columns would be key portfolio-level deltas versus the appropriate reference scenario:

```text
Δ Avg Requested Amount
Δ Avg APR
Δ Avg Monthly Payment
Δ Avg PTI
Δ Avg synthetic-PD proxy
Δ Avg LGD
Δ Avg Expected Loss
Δ Total Expected Loss
```

Color would show direction / magnitude of movement, and cell labels would show compact values.

### Why this is better

This panel would tell the reader:

> Module 1 is not just a rate shock toy. It is a governed scenario engine with multiple levers: pricing, affordability, borrower mix, product mix, exposure appetite, and severity.

That is a much broader and more accurate Module 1 story.

## Recommended Panel 3 options

Panel 3 should remain a matched attribution panel, because Module 1’s validation story strongly emphasizes deterministic population generation and matched row-level scenario comparison. The validation summary confirms that Module 1 produces reproducible populations using deterministic seeding tied to `population_id` and supports matched row-level scenario comparison without population noise. fileciteturn49file89

But we have a choice about **which** matched attribution to spotlight.

### Option A — Keep RATE_UP_200BP attribution

This is acceptable if we frame it as:

```text
Matched Attribution Deep Dive:
One controlled rate-shock example
```

This works especially if Panel 2 becomes the broad scenario lever matrix. Then Panel 3 is no longer pretending rate shocks are the whole story; it is just a clean matched-comparison example.

### Option B — Use a more interesting non-rate matched attribution

If we have or can generate matched 10.04B / 10.04C-style outputs for another scenario, I would rather spotlight one of these:

```text
HIGH_BALANCE_APPETITE vs exposure baseline
    Best for showing exposure structure and balance appetite.

CREDIT_STRESS_SCORE_MIX vs credit-box baseline
    Best for showing borrower-risk composition pressure.

BROAD_LGD_STRESS vs LGD baseline
    Best for showing pure severity movement.

UNSECURED_GROWTH_MIX vs portfolio-mix baseline
    Best for showing product-mix concentration.
```

My favorite would be **HIGH_BALANCE_APPETITE** if we can get matched attribution data, because it is intuitive, visually interesting, and connects well to both Module 1 exposure structure and the Module 2 high-balance / Option C storyline.

## Practical recommendation

I would revise the Module 1 collage plan to this:

```text
Panel 1:
    Product × Score Risk Surface
    Keep as-is.

Panel 2:
    Scenario Lever Matrix
    Replace the rate-only transmission line chart.
    Use 10.02 portfolio-level scenario summary across all scenario families.

Panel 3:
    Matched Attribution Deep Dive
    Use RATE_UP_200BP if that is the only 10.04B / 10.04C matched attribution export we currently have.
    Use HIGH_BALANCE_APPETITE, CREDIT_STRESS_SCORE_MIX, or BROAD_LGD_STRESS if we can produce the matched attribution export for one of those.
```

That gives the Module 1 README collage a much stronger progression:

```text
1. Baseline realism:
   product × score risk surface

2. Scenario breadth:
   multiple governed scenario levers

3. Matched comparison discipline:
   same applicants, controlled scenario delta, product × score attribution
```

## Data we would need

For the revised Panel 2, we need only 10.02:

```text
scenario_name
scenario_set_name
applications
avg_requested_amount
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_lgd
avg_expected_loss
total_expected_loss
```

For a revised non-rate Panel 3, we would need the equivalent of 10.04B and 10.04C for the chosen scenario pair:

```text
10.04B:
    matched row-level delta summary

10.04C:
    matched row-level delta summary by product and score band
```

If we only have those for `BASELINE_V2 → RATE_UP_200BP`, then keeping the current Panel 3 is fine. The key improvement is making Panel 2 broad enough to show the full Module 1 scenario framework.
<!-- END_MESSAGE C040-M02485 -->


---

<a id="c040-m02487"></a>

### C040-M02487

**Andrew** · 2026-05-27T10:07:30.166000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02487 -->
I see, it looks like the 10.04 queries form module 1 are not kept for each run.  I do not recall what the last 10.04 queries were comparing.  I do see that the most valuable campaign level queries are 10.01, 10.02, and 10.03.  Let's discuss the module 1 panel 1/2/3 again and where we source information and what we should source.  if i need to re-run anything i can also do that.
<!-- END_MESSAGE C040-M02487 -->


**Attachments in export:** `module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv`, `module1_synthetic_application_risk_engine_v2.0_10.02_QA_portfolio_level_scenario_summary_campaign(1).csv`, `module1_synthetic_application_risk_engine_v2.0_10.01_QA_scenario_archive_inventory_campaign(1).csv`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c040-m02494"></a>

### C040-M02494

**ChatGPT** · 2026-05-27T10:16:07.728009-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02494 -->
I agree with your instinct. If we keep both Panel 2 and Panel 3 rate-focused, the Module 1 collage will undersell the campaign. Rate up/down is clean and intuitive, but Module 1’s broader value is that it supports **multiple scenario levers**, not just rate sensitivity.

The strongest Module 1 README collage should use the campaign-level exports as the primary evidence layer:

```text
10.01 = scenario archive inventory / campaign completeness
10.02 = portfolio-level scenario summary / scenario lever comparison
10.03 = product × score scenario summary / segment-level risk and attribution
10.04 = optional matched-row deep dive, but not required for the main collage
```

Module 1’s documented purpose is broader than a rate-shock tool: it is a governed synthetic application and risk modeling engine for pre-production strategy testing without PII, built around the principle that credit risk is shaped by borrower profile, loan structure, affordability, and macro environment. The BRD specifically frames the transmission chain as `Rate Environment → APR → Payment → PTI → estimated-PD proxy → Expected Loss`, but it also emphasizes a broader scenario framework for controlled comparison. fileciteturn49file88 The validation summary also confirms the engine is deterministic, scenario-capable, product/score-aware, and supports matched scenario comparison without population noise. fileciteturn49file89

## Recommended reset: use 10.01 / 10.02 / 10.03 for the main collage

I would **not** rely on 10.04 for the main README collage unless you intentionally rerun it for a selected comparison and preserve the exact comparison metadata. The reason is practical: 10.04 is a matched-pair diagnostic, not a campaign-wide view. If it was only run once near the end, it reflects whatever comparison was active at that time. That is useful, but it is not as clean as the campaign-level 10.01 / 10.02 / 10.03 exports.

The revised Module 1 collage should be:

```text
Panel 1:
    Product × Score Risk Surface
    Source: 10.03

Panel 2:
    Scenario Lever Matrix
    Source: 10.02, with 10.01 used for the KPI strip

Panel 3:
    Scenario Expected-Loss Impact Decomposition
    Source: 10.03
```

This gives the README a much better progression:

```text
1. Baseline risk foundation
2. Full scenario breadth
3. Product-level attribution of scenario impact
```

That is stronger than:

```text
1. Baseline risk surface
2. Rate transmission
3. Rate attribution
```

because the second version over-indexes on the simplest scenario family.

---

# Source role by export

## 10.01 — Scenario archive inventory

Use this as a **KPI strip**, not a main panel.

It should support a header like:

```text
19 governed scenarios | 50,000 applications each | 950,000 archived scenario rows | BASE_POPULATION_V1
```

This tells the reader the Module 1 campaign was not a one-off run. It was a governed archive campaign with scenario slices.

Best use:

```text
Module 1 collage header / subtitle
```

Not best use:

```text
A full chart panel
```

## 10.02 — Portfolio-level scenario summary

This should become the source for **Panel 2**.

It is the best file for showing scenario breadth because it has one row per scenario with:

```text
applications
avg_requested_amount
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_lgd
avg_expected_loss
total_expected_loss
```

This lets us show multiple scenario families in one compact matrix:

```text
Rate Environment
Credit Box
Exposure Intensity
LGD Severity
Portfolio Mix
```

## 10.03 — Product × score scenario summary

This should source **Panel 1** and **Panel 3**.

Panel 1 uses 10.03 for the baseline slice:

```text
BASELINE_V2 × product_type × score_band
```

Panel 3 can use 10.03 more broadly to compute scenario-level product or product × score contributions:

```text
applications × avg_expected_loss = segment total Expected Loss
```

Then compare each scenario against its family reference to show where scenario Expected Loss movement concentrated.

## 10.04 — Matched row-level delta

Use this only if you want a **deep-dive appendix** or a deliberately rerun matched scenario panel.

I would not make 10.04 the main Panel 3 unless we rerun it with an intentionally selected non-rate scenario pair and save it with explicit comparison metadata.

---

# Revised Module 1 panel plan

## Panel 1 — Product × Score Risk Surface

**Keep this exactly as planned.**

```text
Title:
    Product × Score Risk Surface

Source:
    10.03

Filter:
    scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Rows:
    product_type

Columns:
    score_band

Color:
    avg_expected_loss

Cell label:
    avg synthetic-PD proxy
```

Purpose:

```text
Show that the baseline synthetic portfolio is product-aware and score-aware.
```

This panel is still the correct first panel. It proves cross-sectional realism before we talk about scenario movement.

---

## Panel 2 — Scenario Lever Matrix

This should replace the rate-only transmission chart.

### Purpose

Panel 2 should answer:

> **How do different Module 1 scenario families move the portfolio-level risk engine?**

This is the panel that tells the reader Module 1 is not just a rate-shock toy.

### Source

```text
10.02_QA_portfolio_level_scenario_summary_campaign
```

Use 10.01 only for the top KPI strip.

### Rows

Use challenger scenarios grouped by family. I would include these:

```text
Rate Environment:
    RATE_DOWN_200BP
    RATE_UP_200BP
    RATE_UP_300BP

Credit Box:
    PRIME_GROWTH_SCORE_MIX
    NEAR_PRIME_EXPANSION_MIX
    CREDIT_STRESS_SCORE_MIX

Exposure Intensity:
    LOW_BALANCE_CONSERVATIVE_REQUESTS
    HIGH_BALANCE_APPETITE

LGD Severity:
    UNSECURED_SEVERITY_STRESS
    SECURED_SEVERITY_STRESS
    BROAD_LGD_STRESS

Portfolio Mix:
    UNSECURED_GROWTH_MIX
    REVOLVING_LINE_EXPANSION_MIX
    SECURED_BALANCE_GROWTH_MIX
```

Exclude the repeated reference rows from the main matrix, or gray them out if included:

```text
BASELINE_V2
CREDIT_BOX_BASELINE_REFERENCE
EXPOSURE_BASELINE_REFERENCE
LGD_BASELINE_REFERENCE
PORTFOLIO_MIX_BASELINE_REFERENCE
```

### Reference logic

Each scenario should be compared to its family reference:

```text
Rate Environment:
    reference = BASELINE_V2

Credit Box:
    reference = CREDIT_BOX_BASELINE_REFERENCE

Exposure Intensity:
    reference = EXPOSURE_BASELINE_REFERENCE

LGD Severity:
    reference = LGD_BASELINE_REFERENCE

Portfolio Mix:
    reference = PORTFOLIO_MIX_BASELINE_REFERENCE
```

### Columns / metrics

I would use a compact heatmap matrix with these columns:

```text
Δ Avg Requested Amount
Δ Avg APR
Δ Avg Monthly Payment
Δ Avg PTI
Δ Synthetic-PD Proxy
Δ Avg LGD
Δ Avg Expected Loss
Δ Total Expected Loss
```

For readability in a collage, we may reduce to six columns:

```text
Δ Requested $
Δ Payment
Δ PTI
Δ PD Proxy
Δ LGD
Δ Total EL
```

### Visual encoding

```text
Color:
    diverging scale
    blue/green = improvement or reduction
    orange/red = increase or stress

Cell labels:
    compact deltas
```

Example label types:

```text
+$16.0K requested
+2.4pp PTI
+0.28pp PD proxy
+$77.0M Total EL
```

### What this panel demonstrates

```text
Rate scenarios mainly move APR / payment / PTI.
Credit-box scenarios move PD proxy and Expected Loss.
Exposure scenarios move requested amount, payment, PTI, and EL.
LGD scenarios move severity and EL.
Portfolio-mix scenarios change exposure/product structure and total EL.
```

This panel is the main answer to your concern. It shows the full Module 1 scenario architecture.

---

## Panel 3 — Scenario Expected-Loss Impact Decomposition

This should replace the current matched rate-shock attribution panel if we want the collage to be broader.

### Purpose

Panel 3 should answer:

> **When major scenarios move Expected Loss, which products drive the movement?**

This is a value-add versus Panel 2. Panel 2 shows portfolio-level scenario movement. Panel 3 decomposes the Expected Loss movement by product.

### Source

```text
10.03_QA_product_score_scenario_summary_campaign
```

### Required derived metric

For each scenario × product × score band:

```text
segment_total_expected_loss =
    applications × avg_expected_loss
```

Then calculate:

```text
delta_segment_total_expected_loss =
    scenario segment_total_expected_loss
    - family reference segment_total_expected_loss
```

Then aggregate by product for the chart:

```text
delta_product_total_expected_loss =
    SUM(delta_segment_total_expected_loss)
```

### Chart type

Use a **diverging stacked horizontal bar chart**.

Rows:

```text
selected scenario levers
```

Stack:

```text
product_type contribution
```

X-axis:

```text
Δ Total Expected Loss ($M)
```

This is better than the old Panel 3 because it can handle both increases and decreases. That matters because several non-rate scenarios reduce total Expected Loss.

### Candidate rows

I would choose the most narrative-heavy scenarios, not necessarily every scenario:

```text
CREDIT_STRESS_SCORE_MIX
PRIME_GROWTH_SCORE_MIX
BROAD_LGD_STRESS
SECURED_SEVERITY_STRESS
HIGH_BALANCE_APPETITE
LOW_BALANCE_CONSERVATIVE_REQUESTS
SECURED_BALANCE_GROWTH_MIX
REVOLVING_LINE_EXPANSION_MIX
UNSECURED_GROWTH_MIX
```

That may be too many for one panel, so we can narrow to six:

```text
CREDIT_STRESS_SCORE_MIX
PRIME_GROWTH_SCORE_MIX
BROAD_LGD_STRESS
HIGH_BALANCE_APPETITE
SECURED_BALANCE_GROWTH_MIX
REVOLVING_LINE_EXPANSION_MIX
```

### Why this is strong

It shows richer scenario stories:

```text
Credit stress:
    large total EL increase driven heavily by weaker score mix and mortgage/product exposure.

Prime growth:
    large total EL decrease from stronger score composition.

Broad LGD stress:
    severity-driven EL increase.

High balance appetite:
    exposure-driven EL increase.

Secured balance growth:
    product-mix and exposure movement.

Revolving expansion:
    product-mix movement that may reduce or shift total EL depending on what it displaces.
```

### Optional right-side callout

Use 10.03 to identify top product × score drivers. Example callout pattern:

```text
Largest product × score movements:
1. Mortgage × Subprime under Credit Stress
2. Mortgage × Subprime under Broad LGD Stress
3. Mortgage × Near Prime under Secured Balance Growth
```

We can compute the exact top drivers when coding.

---

# Should we rerun anything?

For the revised main README collage, **no rerun is required**.

You already have the three best campaign-level sources:

```text
10.01
10.02
10.03
```

Those are stronger for a README hero collage than 10.04 because they summarize the whole Module 1 campaign.

I would rerun 10.04 only if you want one of these two things:

```text
1. A separate appendix / deep-dive chart showing true matched row-level attribution.

2. A non-rate matched comparison spotlight, such as:
       HIGH_BALANCE_APPETITE vs EXPOSURE_BASELINE_REFERENCE
       CREDIT_STRESS_SCORE_MIX vs CREDIT_BOX_BASELINE_REFERENCE
       BROAD_LGD_STRESS vs LGD_BASELINE_REFERENCE
```

If you do rerun 10.04, I would update or manually annotate the export to include:

```text
baseline_scenario_name
comparison_scenario_name
scenario_family
comparison_label
population_id
matched_rows
```

That would prevent the ambiguity you noticed. A matched-pair output without explicit scenario-pair metadata is easy to misinterpret later.

---

# My recommendation

Use this as the final Module 1 collage architecture:

```text
MODULE 1: SYNTHETIC APPLICATION & RISK MODELING ENGINE

Header / KPI strip:
    19 governed scenarios
    50,000 applications each
    950,000 archived scenario rows
    same population_id for controlled comparison

Panel 1:
    Product × Score Risk Surface
    Source: 10.03 baseline slice

Panel 2:
    Scenario Lever Matrix
    Source: 10.02 all scenario families

Panel 3:
    Scenario Expected-Loss Impact Decomposition
    Source: 10.03 scenario × product × score summary
```

This tells a stronger story than the original rate-heavy version:

```text
Panel 1:
    The baseline population is realistic and risk-sensitive.

Panel 2:
    The campaign has multiple governed scenario levers.

Panel 3:
    Scenario Expected Loss movement can be decomposed by product and score structure.
```

That is the cleanest Module 1 companion to your Module 2 collage.
<!-- END_MESSAGE C040-M02494 -->


---

<a id="c040-m02496"></a>

### C040-M02496

**Andrew** · 2026-05-27T10:36:07.369000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02496 -->
I agree and also agree with the optional right side callout for largest product x score movements.  does panel 1 require any changes?
<!-- END_MESSAGE C040-M02496 -->


---

<a id="c040-m02499"></a>

### C040-M02499

**ChatGPT** · 2026-05-27T10:40:05.856168-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02499 -->
No material changes are required for Module 1 Panel 1. I would keep it as the **baseline anchor** for the whole Module 1 collage.

Panel 1 still has a distinct job:

```text
Panel 1:
    What does the baseline synthetic risk surface look like?

Panel 2:
    How do different scenario levers move the portfolio?

Panel 3:
    Which products / score bands drive scenario Expected Loss movement?
```

That sequence is strong. Panel 1 should remain baseline-only because it establishes the cross-sectional realism of the synthetic portfolio before Panels 2 and 3 introduce scenario movement. Module 1’s documented purpose is to create a realistic, explainable, portfolio-scale simulation environment where credit risk emerges from borrower characteristics, product structure, affordability, and macro conditions, so a baseline product × score surface is exactly the right first visual. fileciteturn51file88

## Keep Panel 1 as-is conceptually

I would keep:

```text
Source:
    10.03 product × score scenario summary

Filter:
    scenario_name = BASELINE_V2
    population_id = BASE_POPULATION_V1

Rows:
    product_type

Columns:
    score_band

Color:
    avg_expected_loss

Cell label:
    avg synthetic-PD proxy
```

That panel shows that the baseline synthetic population is not random-looking noise. It is differentiated by both product structure and score quality, which directly supports the Module 1 validation claim that the engine reflects configured product / score composition and coherent financial relationships across exposure, payment burden, affordability, estimated risk, and Expected Loss. fileciteturn51file89

## Minor framing changes I would make

The only changes I would make are wording / framing tweaks so Panel 1 fits the revised three-panel story.

### Current title is fine

```text
Product × Score Risk Surface
```

But in the final collage, I would consider:

```text
Baseline Product × Score Risk Surface
```

That makes it explicit that Panel 1 is the baseline reference, while Panels 2 and 3 are scenario movement.

### Subtitle should emphasize “baseline anchor”

Use language like:

```text
Baseline synthetic portfolio: color = avg Expected Loss; cell label = avg synthetic-PD proxy
```

That is already what you have. I would keep it.

### Footer can be slightly adjusted

Current idea:

```text
The baseline synthetic portfolio is differentiated across both borrower score quality and product structure. Expected Loss is not just a score metric; it is shaped by exposure size, product structure, LGD, affordability, and the synthetic estimated-PD proxy.
```

That remains strong. I might add one short phrase if space allows:

```text
This baseline surface anchors the scenario movement shown in the next panels.
```

But that is optional.

## What I would not change

I would **not** turn Panel 1 into an all-scenario view. That would make it redundant with the new Scenario Lever Matrix.

I would **not** color by synthetic-PD proxy. Expected Loss is the better color metric because it reflects risk plus exposure / product structure.

I would **not** use total Expected Loss in Panel 1. Average Expected Loss is better for the baseline risk surface because it avoids making larger cells look riskier merely because they have more volume.

I would **not** add too many labels. Cell label = synthetic-PD proxy is enough. The colorbar and callout box carry the Expected Loss interpretation.

## One consistency point for Panels 1 and 3

Since Panel 3 will decompose scenario Expected Loss movement by product and score, we should keep the same score-band order across the Module 1 collage:

```text
SUPER_PRIME
PRIME
NEAR_PRIME
SUBPRIME
DEEP_SUBPRIME
```

That will help the reader connect Panel 1’s baseline risk surface to Panel 3’s product × score scenario attribution.

## Final recommendation

```text
Panel 1 status: KEEP
Required changes: none
Optional refinements:
    rename title to “Baseline Product × Score Risk Surface”
    keep the current subtitle
    optionally add “baseline anchor” language to the footer
```

The revised Module 1 collage should therefore be:

```text
Panel 1 — Baseline Product × Score Risk Surface
    Source: 10.03 baseline slice
    Purpose: cross-sectional realism

Panel 2 — Scenario Lever Matrix
    Source: 10.02
    Purpose: full scenario breadth

Panel 3 — Scenario Expected-Loss Impact Decomposition
    Source: 10.03
    Purpose: product / score attribution of scenario movement
```

That gives us a cleaner, broader Module 1 story without sacrificing the strong Panel 1 visual you already built.
<!-- END_MESSAGE C040-M02499 -->


---

<a id="c040-m02500"></a>

### C040-M02500

**Andrew** · 2026-05-27T10:49:29.817000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02500 -->
I updated the panel 1 title.  Let's lock down panel 2 specs now.
<!-- END_MESSAGE C040-M02500 -->


---

<a id="c040-m02506"></a>

### C040-M02506

**ChatGPT** · 2026-05-27T10:56:34.537076-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02506 -->
## Module 1 Panel 2 spec locked: Scenario Lever Matrix

### Panel title

```text
Scenario Lever Matrix
How Governed Scenario Families Move the Risk Engine
```

Recommended subtitle:

```text
Portfolio-level deltas versus each scenario family’s reference slice
```

This panel should replace the rate-only transmission chart. The point is to show that Module 1 is not merely a rate up/down sensitivity engine. It is a broader governed scenario framework that can stress different parts of the synthetic risk chain: rate environment, credit-box composition, exposure appetite, LGD severity, and portfolio mix.

This aligns directly with Module 1’s purpose as a governed, scenario-capable simulation framework where risk emerges from borrower profile, loan structure, affordability, and macro conditions rather than borrower score alone. fileciteturn51file88 The validation summary also supports this framing: Module 1 is deterministic, portfolio-scale, product/score-aware, scenario-capable, and supports controlled comparison using stable populations. fileciteturn51file89

---

# 1. What Panel 2 is trying to demonstrate

Panel 2 should answer:

> **How do different Module 1 scenario families move the portfolio-level risk engine?**

The reader should see that each scenario family stresses a different lever:

```text
Rate Environment:
    APR, payment, PTI

Credit Box:
    synthetic-PD proxy, APR, Expected Loss

Exposure Intensity:
    requested amount, payment, PTI, Expected Loss

LGD Severity:
    LGD and Expected Loss

Portfolio Mix:
    requested amount, APR, payment, LGD, Expected Loss
```

This is the key value-add versus Panel 1. Panel 1 proves the **baseline risk surface**. Panel 2 proves the **scenario framework breadth**.

---

# 2. Data source

Use:

```text
module1_synthetic_application_risk_engine_v2.0_10.02_QA_portfolio_level_scenario_summary_campaign.csv
```

This remains the best source because it is the campaign-level portfolio summary. It already contains one row per scenario with the metrics needed to compare scenario levers.

Required columns:

```text
scenario_set_name
scenario_name
population_id
applications
avg_requested_amount
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_lgd
avg_expected_loss
total_expected_loss
```

Do **not** use 10.04 for Panel 2. 10.04 is matched-pair diagnostic evidence; Panel 2 should be campaign-wide.

---

# 3. Role of 10.01

Use 10.01 only for a top collage KPI strip, not the Panel 2 chart itself.

Recommended KPI strip:

```text
19 governed scenarios | 50,000 applications each | 950,000 archived scenario rows | BASE_POPULATION_V1
```

That tells the reader the scenario matrix is backed by a full governed campaign, not a one-off sample.

---

# 4. Scenario rows

Panel 2 should show **challenger scenario rows only**. Reference rows are used for delta calculations but should not be plotted as ordinary rows.

## Rate Environment

Reference:

```text
BASELINE_V2
```

Rows:

```text
RATE_DOWN_200BP
RATE_UP_200BP
RATE_UP_300BP
```

Display labels:

```text
Rate Down 200bp
Rate Up 200bp
Rate Up 300bp
```

## Credit Box

Reference:

```text
CREDIT_BOX_BASELINE_REFERENCE
```

Rows:

```text
PRIME_GROWTH_SCORE_MIX
NEAR_PRIME_EXPANSION_MIX
CREDIT_STRESS_SCORE_MIX
```

Display labels:

```text
Prime Growth Mix
Near-Prime Expansion
Credit Stress Mix
```

## Exposure Intensity

Reference:

```text
EXPOSURE_BASELINE_REFERENCE
```

Rows:

```text
LOW_BALANCE_CONSERVATIVE_REQUESTS
HIGH_BALANCE_APPETITE
```

Display labels:

```text
Low-Balance Conservative
High-Balance Appetite
```

## LGD Severity

Reference:

```text
LGD_BASELINE_REFERENCE
```

Rows:

```text
UNSECURED_SEVERITY_STRESS
SECURED_SEVERITY_STRESS
BROAD_LGD_STRESS
```

Display labels:

```text
Unsecured Severity
Secured Severity
Broad LGD Stress
```

## Portfolio Mix

Reference:

```text
PORTFOLIO_MIX_BASELINE_REFERENCE
```

Rows:

```text
REVOLVING_LINE_EXPANSION_MIX
UNSECURED_GROWTH_MIX
SECURED_BALANCE_GROWTH_MIX
```

Display labels:

```text
Revolving Expansion
Unsecured Growth
Secured Balance Growth
```

---

# 5. Reference logic

Each scenario should be compared only to its family reference:

```text
Rate Environment:
    BASELINE_V2

Credit Box:
    CREDIT_BOX_BASELINE_REFERENCE

Exposure Intensity:
    EXPOSURE_BASELINE_REFERENCE

LGD Severity:
    LGD_BASELINE_REFERENCE

Portfolio Mix:
    PORTFOLIO_MIX_BASELINE_REFERENCE
```

This matters because it keeps the deltas analytically fair. The chart should not compare every scenario to BASELINE_V2 unless that is the formal reference for that scenario family.

---

# 6. Metrics to show

Lock the panel at **seven columns**.

```text
Δ Avg Requested $
Δ Avg APR
Δ Avg Payment
Δ Avg PTI
Δ Synthetic-PD Proxy
Δ Avg LGD
Δ Total Expected Loss
```

Use compact display units:

```text
Δ Avg Requested $:
    $K

Δ Avg APR:
    percentage points

Δ Avg Payment:
    $

Δ Avg PTI:
    percentage points

Δ Synthetic-PD Proxy:
    percentage points

Δ Avg LGD:
    percentage points

Δ Total Expected Loss:
    $M
```

I would **not** include `avg_expected_loss` in this panel. `total_expected_loss` is more executive-readable and gives a direct sense of portfolio-scale scenario movement. Since all scenarios use 50,000 applications, total EL and average EL are directionally redundant; total EL is the stronger README metric.

---

# 7. Chart type

Use a **diverging heatmap matrix**.

```text
Rows:
    scenario_name grouped by scenario family

Columns:
    seven portfolio-level delta metrics

Cell color:
    normalized signed movement within each metric column

Cell text:
    raw compact delta value
```

The key design principle is **per-column normalization**. Because the columns use different units, one universal color scale would be misleading. Each metric should be normalized within its own column so the color intensity means:

```text
How large is this movement relative to other scenarios for this same metric?
```

not:

```text
How large is this movement relative to every other metric?
```

---

# 8. Color interpretation

Use a diverging color scale:

```text
Blue / cool:
    decrease versus family reference

Neutral / dark:
    little or no movement

Orange / red:
    increase versus family reference
```

Do **not** label the colors as “good” and “bad.” Some positive values mean stress, but others mean exposure appetite or product-mix expansion. The safe interpretation is:

```text
blue = lower than reference
red = higher than reference
```

Then the README can explain what those movements mean.

---

# 9. Row grouping and layout

Rows should be grouped with family headers or a left-side family band:

```text
Rate Environment
Credit Box
Exposure Intensity
LGD Severity
Portfolio Mix
```

Within each family, use a logical narrative order rather than pure alphabetical order:

```text
Rate:
    Rate Down → Rate Up 200 → Rate Up 300

Credit Box:
    Prime Growth → Near-Prime Expansion → Credit Stress

Exposure:
    Low Balance → High Balance

LGD:
    Unsecured Severity → Secured Severity → Broad LGD Stress

Portfolio Mix:
    Revolving Expansion → Unsecured Growth → Secured Balance Growth
```

This ordering makes the matrix read like a campaign story rather than a lookup table.

---

# 10. Cell labels

Use compact labels.

Examples:

```text
+$16.0K
+1.58pp
+$101
+0.91pp
+8.77pp
+10.16pp
+$99.1M
```

For cells that are essentially unchanged:

```text
0
```

or:

```text
—
```

I prefer `0` only when the actual rounded delta is zero, and `—` for intentionally not applicable fields if any appear. For this 10.02 matrix, all selected metrics are applicable.

---

# 11. Right-side interpretation box

Panel 2 should include a compact blue interpretation box, similar to the style used in the existing charts.

Suggested text:

```text
How to read:

Each row compares a scenario
to its family reference.

Blue = lower than reference
Red = higher than reference

Different levers move
different parts of the chain:

Rate → APR / payment / PTI
Credit box → PD proxy / EL
Exposure → amount / PTI / EL
LGD → severity / EL
Mix → product structure / EL
```

This will prevent the reader from treating the matrix as a generic heatmap.

---

# 12. Optional callouts

Use at most two callouts. More than that will make the panel busy.

Recommended callout 1:

```text
Credit Stress:
largest synthetic-PD proxy and EL pressure
```

Recommended callout 2:

```text
Broad LGD Stress:
severity-only movement drives large EL increase
```

Alternative if space is tight:

```text
No direct callout arrows; keep the right-side interpretation box only.
```

My recommendation: use the right-side box and maybe one small callout on `CREDIT_STRESS_SCORE_MIX`.

---

# 13. Caption

Recommended README caption:

```text
The Scenario Lever Matrix compares each challenger scenario to its family reference. Cell labels show portfolio-level deltas, while color intensity shows relative movement within each metric. The matrix demonstrates that Module 1 supports multiple governed scenario levers—not just rate shocks—including credit-box mix, exposure appetite, LGD severity, and portfolio-mix changes.
```

Short collage caption:

```text
Scenario lever matrix: each scenario is compared to its family reference; color shows direction and relative intensity of portfolio movement.
```

---

# 14. What this panel should not do

Do **not** include the family reference rows as ordinary plotted rows.

Do **not** use one global color scale across all metrics.

Do **not** imply that scenario rows are forecasts.

Do **not** call `avg_pd` calibrated PD. Use:

```text
synthetic-PD proxy
```

Do **not** include 10.04 matched-pair rows here.

Do **not** try to show every possible segment. Panel 3 will handle product / score decomposition.

---

# Final locked Panel 2 spec

```text
Panel name:
    Scenario Lever Matrix

Purpose:
    Show that Module 1 supports multiple governed scenario levers and that each
    lever moves a different part of the portfolio risk engine.

Source:
    Section 10.02 portfolio-level scenario summary campaign CSV

Rows:
    Challenger scenarios only, grouped by:
        Rate Environment
        Credit Box
        Exposure Intensity
        LGD Severity
        Portfolio Mix

References:
    RATE scenarios                 → BASELINE_V2
    CREDIT_BOX scenarios           → CREDIT_BOX_BASELINE_REFERENCE
    EXPOSURE scenarios             → EXPOSURE_BASELINE_REFERENCE
    LGD scenarios                  → LGD_BASELINE_REFERENCE
    PORTFOLIO_MIX scenarios        → PORTFOLIO_MIX_BASELINE_REFERENCE

Columns:
    Δ Avg Requested $
    Δ Avg APR
    Δ Avg Payment
    Δ Avg PTI
    Δ Synthetic-PD Proxy
    Δ Avg LGD
    Δ Total Expected Loss

Chart type:
    Diverging heatmap matrix

Color:
    per-column normalized signed movement

Cell text:
    compact raw deltas

Right-side interpretation:
    explain family references and scenario lever meanings

Primary message:
    Module 1 is not only a rate sensitivity tool. It is a governed scenario
    framework where different levers affect pricing, payment burden, affordability,
    synthetic-risk proxy, severity, exposure, product mix, and Expected Loss.
```

This is the correct Panel 2 for the revised Module 1 collage. It solves the concern that rate up/down scenarios are too simple by making the full scenario architecture visible.
<!-- END_MESSAGE C040-M02506 -->


---

<a id="c040-m02507"></a>

### C040-M02507

**Andrew** · 2026-05-27T11:15:52.089000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02507 -->
i agree.  do not generate image. proceed to produce python code to create module 1 updated panel 2.
<!-- END_MESSAGE C040-M02507 -->


---

<a id="c040-m02518"></a>

### C040-M02518

**ChatGPT** · 2026-05-27T11:27:20.198073-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02518 -->
Below is the full-copy Python code for the updated **Module 1 Panel 2 — Scenario Lever Matrix**. It uses hardcoded final 10.02 campaign values and compares each scenario to its own family reference, consistent with the Module 1 scenario framework and synthetic-PD proxy interpretation boundary. fileciteturn54file88turn54file89

```python
"""
Module 1 README Panel 2
Scenario Lever Matrix: How Governed Scenario Families Move the Risk Engine

This version uses hardcoded final-campaign Section 10.02 values.

Panel thesis:
    Module 1 is not only a rate-sensitivity engine.
    It is a governed scenario framework with multiple levers:
        rate environment,
        credit-box composition,
        exposure intensity,
        LGD severity,
        and portfolio mix.

    Each scenario is compared to its own family reference slice so the movement
    is analytically fair and interpretable.

Data source:
    Final campaign Section 10.02:
    Portfolio-level scenario summary.

Chart design:
    Diverging heatmap matrix.

    Rows:
        challenger scenarios grouped by scenario family.

    Columns:
        portfolio-level deltas versus each family reference.

    Cell color:
        per-column normalized signed movement.
        Blue = lower than family reference.
        Red = higher than family reference.
        Dark/neutral = little or no movement.

    Cell text:
        compact raw delta values.

Output:
    assets/module1_scenario_lever_matrix.png
    assets/module1_scenario_lever_matrix.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap, Normalize


# =============================================================================
# 1. OUTPUT SETTINGS
# =============================================================================

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module1_scenario_lever_matrix.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_scenario_lever_matrix.svg"


# =============================================================================
# 2. HARDCODED SECTION 10.02 PORTFOLIO-LEVEL SCENARIO DATA
# =============================================================================

SCENARIO_DATA = [
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "BASELINE_V2",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_DOWN_200BP",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133390.33,
        "avg_apr": 0.1285,
        "avg_monthly_payment": 1385.24,
        "avg_pti": 0.1535,
        "avg_pd": 0.1627,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4765.49,
        "total_expected_loss": 238274612.94,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_UP_200BP",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133208.64,
        "avg_apr": 0.1614,
        "avg_monthly_payment": 1612.00,
        "avg_pti": 0.1741,
        "avg_pd": 0.1639,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4804.46,
        "total_expected_loss": 240223118.88,
    },
    {
        "scenario_set_name": "MODULE1_V2_BASELINE_SET",
        "scenario_name": "RATE_UP_300BP",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133164.06,
        "avg_apr": 0.1685,
        "avg_monthly_payment": 1645.42,
        "avg_pti": 0.1771,
        "avg_pd": 0.1640,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4809.80,
        "total_expected_loss": 240489995.27,
    },

    {
        "scenario_set_name": "MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET",
        "scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET",
        "scenario_name": "CREDIT_STRESS_SCORE_MIX",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 115164.64,
        "avg_apr": 0.1611,
        "avg_monthly_payment": 1399.22,
        "avg_pti": 0.1812,
        "avg_pd": 0.2511,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 6770.82,
        "total_expected_loss": 338541219.20,
    },
    {
        "scenario_set_name": "MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET",
        "scenario_name": "NEAR_PRIME_EXPANSION_MIX",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 129524.27,
        "avg_apr": 0.1487,
        "avg_monthly_payment": 1504.95,
        "avg_pti": 0.1686,
        "avg_pd": 0.1741,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 5257.10,
        "total_expected_loss": 262855231.78,
    },
    {
        "scenario_set_name": "MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET",
        "scenario_name": "PRIME_GROWTH_SCORE_MIX",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 144659.99,
        "avg_apr": 0.1357,
        "avg_monthly_payment": 1573.94,
        "avg_pti": 0.1545,
        "avg_pd": 0.1095,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 3499.56,
        "total_expected_loss": 174978206.48,
    },

    {
        "scenario_set_name": "MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET",
        "scenario_name": "EXPOSURE_BASELINE_REFERENCE",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET",
        "scenario_name": "HIGH_BALANCE_APPETITE",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 149334.38,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1729.54,
        "avg_pti": 0.1886,
        "avg_pd": 0.1662,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 5528.43,
        "total_expected_loss": 276421529.97,
    },
    {
        "scenario_set_name": "MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET",
        "scenario_name": "LOW_BALANCE_CONSERVATIVE_REQUESTS",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 112405.38,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1248.95,
        "avg_pti": 0.1379,
        "avg_pd": 0.1600,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 3972.67,
        "total_expected_loss": 198633575.40,
    },

    {
        "scenario_set_name": "MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET",
        "scenario_name": "BROAD_LGD_STRESS",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.5939,
        "avg_expected_loss": 6360.36,
        "total_expected_loss": 318018204.68,
    },
    {
        "scenario_set_name": "MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET",
        "scenario_name": "LGD_BASELINE_REFERENCE",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET",
        "scenario_name": "SECURED_SEVERITY_STRESS",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.5462,
        "avg_expected_loss": 6198.49,
        "total_expected_loss": 309924288.04,
    },
    {
        "scenario_set_name": "MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET",
        "scenario_name": "UNSECURED_SEVERITY_STRESS",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.5400,
        "avg_expected_loss": 4950.55,
        "total_expected_loss": 247527394.17,
    },

    {
        "scenario_set_name": "MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET",
        "scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 133329.28,
        "avg_apr": 0.1456,
        "avg_monthly_payment": 1510.70,
        "avg_pti": 0.1650,
        "avg_pd": 0.1634,
        "avg_lgd": 0.4923,
        "avg_expected_loss": 4788.67,
        "total_expected_loss": 239433477.53,
    },
    {
        "scenario_set_name": "MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET",
        "scenario_name": "REVOLVING_LINE_EXPANSION_MIX",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 99287.78,
        "avg_apr": 0.1685,
        "avg_monthly_payment": 1236.22,
        "avg_pti": 0.1379,
        "avg_pd": 0.1608,
        "avg_lgd": 0.5785,
        "avg_expected_loss": 4070.50,
        "total_expected_loss": 203524786.78,
    },
    {
        "scenario_set_name": "MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET",
        "scenario_name": "SECURED_BALANCE_GROWTH_MIX",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 172557.54,
        "avg_apr": 0.1228,
        "avg_monthly_payment": 1795.23,
        "avg_pti": 0.1939,
        "avg_pd": 0.1660,
        "avg_lgd": 0.3871,
        "avg_expected_loss": 5626.90,
        "total_expected_loss": 281345022.19,
    },
    {
        "scenario_set_name": "MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET",
        "scenario_name": "UNSECURED_GROWTH_MIX",
        "population_id": "BASE_POPULATION_V1",
        "applications": 50000,
        "avg_requested_amount": 101417.94,
        "avg_apr": 0.1507,
        "avg_monthly_payment": 1319.73,
        "avg_pti": 0.1478,
        "avg_pd": 0.1623,
        "avg_lgd": 0.5487,
        "avg_expected_loss": 4239.83,
        "total_expected_loss": 211991553.31,
    },
]


# =============================================================================
# 3. SCENARIO FAMILY CONFIGURATION
# =============================================================================

SCENARIO_FAMILIES = [
    {
        "family": "Rate Environment",
        "family_label": "Rate\nEnvironment",
        "reference": "BASELINE_V2",
        "scenarios": [
            ("RATE_DOWN_200BP", "Rate Down\n200bp"),
            ("RATE_UP_200BP", "Rate Up\n200bp"),
            ("RATE_UP_300BP", "Rate Up\n300bp"),
        ],
    },
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "reference": "CREDIT_BOX_BASELINE_REFERENCE",
        "scenarios": [
            ("PRIME_GROWTH_SCORE_MIX", "Prime Growth\nMix"),
            ("NEAR_PRIME_EXPANSION_MIX", "Near-Prime\nExpansion"),
            ("CREDIT_STRESS_SCORE_MIX", "Credit Stress\nMix"),
        ],
    },
    {
        "family": "Exposure Intensity",
        "family_label": "Exposure\nIntensity",
        "reference": "EXPOSURE_BASELINE_REFERENCE",
        "scenarios": [
            ("LOW_BALANCE_CONSERVATIVE_REQUESTS", "Low-Balance\nConservative"),
            ("HIGH_BALANCE_APPETITE", "High-Balance\nAppetite"),
        ],
    },
    {
        "family": "LGD Severity",
        "family_label": "LGD\nSeverity",
        "reference": "LGD_BASELINE_REFERENCE",
        "scenarios": [
            ("UNSECURED_SEVERITY_STRESS", "Unsecured\nSeverity"),
            ("SECURED_SEVERITY_STRESS", "Secured\nSeverity"),
            ("BROAD_LGD_STRESS", "Broad LGD\nStress"),
        ],
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "reference": "PORTFOLIO_MIX_BASELINE_REFERENCE",
        "scenarios": [
            ("REVOLVING_LINE_EXPANSION_MIX", "Revolving\nExpansion"),
            ("UNSECURED_GROWTH_MIX", "Unsecured\nGrowth"),
            ("SECURED_BALANCE_GROWTH_MIX", "Secured Balance\nGrowth"),
        ],
    },
]


# =============================================================================
# 4. CHART STYLE SETTINGS
# =============================================================================

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

CONTENT_CENTER_X = 0.50

# Diverging color scale:
#   negative / lower than family reference = blue
#   neutral = near-black
#   positive / higher than family reference = red-orange
DIVERGING_CMAP = LinearSegmentedColormap.from_list(
    "scenario_lever_diverging",
    [
        "#1f5f99",
        "#101010",
        "#d9483b",
    ],
    N=256,
)

DIVERGING_NORM = Normalize(vmin=-1.0, vmax=1.0)


# =============================================================================
# 5. HELPER FUNCTIONS
# =============================================================================

def zeroish(value: float, tolerance: float = 1e-9) -> bool:
    """Return True when a value is close enough to zero for display purposes."""
    return abs(float(value)) <= tolerance


def format_signed_k(value: float) -> str:
    """Format signed thousands of dollars."""
    if abs(value) < 0.05:
        return "0"
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.1f}K"


def format_signed_m(value: float) -> str:
    """Format signed millions of dollars."""
    if abs(value) < 0.05:
        return "0"
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.1f}M"


def format_signed_dollars(value: float) -> str:
    """Format signed dollars."""
    if abs(value) < 0.5:
        return "0"
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.0f}"


def format_signed_pp(value: float, decimals: int = 1) -> str:
    """Format signed percentage-point movement."""
    threshold = 0.05 if decimals == 1 else 0.005
    if abs(value) < threshold:
        return "0"
    sign = "+" if value >= 0 else "-"
    return f"{sign}{abs(value):.{decimals}f}pp"


def text_color_for_rgba(rgba: tuple[float, float, float, float]) -> str:
    """
    Pick black or white text based on background luminance.

    Most cells use white text because the custom colormap is intentionally dark,
    but this keeps labels readable if the palette is later adjusted.
    """
    r, g, b, _ = rgba
    luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return "black" if luminance > 0.60 else "white"


def normalize_column(series: pd.Series) -> pd.Series:
    """
    Normalize one metric column to [-1, 1] based on its own maximum absolute value.

    This is required because each metric has a different unit.
    """
    max_abs = max(abs(series.min()), abs(series.max()))
    if max_abs == 0:
        return pd.Series([0.0] * len(series), index=series.index)
    return series / max_abs


def style_dark_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=8.5)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)


# =============================================================================
# 6. PREPARE DATA
# =============================================================================

scenario_df = pd.DataFrame(SCENARIO_DATA)
scenario_map = scenario_df.set_index("scenario_name").to_dict(orient="index")

required_scenarios = set()
for family in SCENARIO_FAMILIES:
    required_scenarios.add(family["reference"])
    required_scenarios.update([scenario_name for scenario_name, _ in family["scenarios"]])

missing_scenarios = sorted(required_scenarios - set(scenario_map.keys()))
if missing_scenarios:
    raise ValueError(
        "Missing required hardcoded scenario row(s): "
        + ", ".join(missing_scenarios)
    )

row_records = []
group_ranges = []

for family in SCENARIO_FAMILIES:
    start_idx = len(row_records)
    reference = scenario_map[family["reference"]]

    for scenario_name, display_label in family["scenarios"]:
        scenario = scenario_map[scenario_name]

        row_records.append(
            {
                "family": family["family"],
                "family_label": family["family_label"],
                "family_reference": family["reference"],
                "scenario_name": scenario_name,
                "display_label": display_label,

                # Delta metrics in display units.
                "delta_requested_k": (
                    scenario["avg_requested_amount"] - reference["avg_requested_amount"]
                ) / 1000.0,
                "delta_apr_pp": (
                    scenario["avg_apr"] - reference["avg_apr"]
                ) * 100.0,
                "delta_payment": (
                    scenario["avg_monthly_payment"] - reference["avg_monthly_payment"]
                ),
                "delta_pti_pp": (
                    scenario["avg_pti"] - reference["avg_pti"]
                ) * 100.0,
                "delta_pd_proxy_pp": (
                    scenario["avg_pd"] - reference["avg_pd"]
                ) * 100.0,
                "delta_lgd_pp": (
                    scenario["avg_lgd"] - reference["avg_lgd"]
                ) * 100.0,
                "delta_total_el_m": (
                    scenario["total_expected_loss"] - reference["total_expected_loss"]
                ) / 1_000_000.0,
            }
        )

    end_idx = len(row_records) - 1
    group_ranges.append(
        {
            "family": family["family"],
            "family_label": family["family_label"],
            "start": start_idx,
            "end": end_idx,
            "center": (start_idx + end_idx) / 2.0,
        }
    )

plot_df = pd.DataFrame(row_records)

METRIC_SPECS = [
    {
        "column": "delta_requested_k",
        "label": "Δ Avg\nRequested $",
        "formatter": format_signed_k,
    },
    {
        "column": "delta_apr_pp",
        "label": "Δ Avg\nAPR",
        "formatter": lambda value: format_signed_pp(value, decimals=1),
    },
    {
        "column": "delta_payment",
        "label": "Δ Avg\nPayment",
        "formatter": format_signed_dollars,
    },
    {
        "column": "delta_pti_pp",
        "label": "Δ Avg\nPTI",
        "formatter": lambda value: format_signed_pp(value, decimals=1),
    },
    {
        "column": "delta_pd_proxy_pp",
        "label": "Δ Synthetic-\nPD Proxy",
        "formatter": lambda value: format_signed_pp(value, decimals=1),
    },
    {
        "column": "delta_lgd_pp",
        "label": "Δ Avg\nLGD",
        "formatter": lambda value: format_signed_pp(value, decimals=1),
    },
    {
        "column": "delta_total_el_m",
        "label": "Δ Total\nExpected Loss",
        "formatter": format_signed_m,
    },
]

metric_columns = [spec["column"] for spec in METRIC_SPECS]
metric_labels = [spec["label"] for spec in METRIC_SPECS]

raw_matrix = plot_df[metric_columns].copy()

normalized_matrix = pd.DataFrame(index=plot_df.index)
for col in metric_columns:
    normalized_matrix[col] = normalize_column(raw_matrix[col])

label_matrix = []
for _, row in plot_df.iterrows():
    label_row = []
    for spec in METRIC_SPECS:
        label_row.append(spec["formatter"](row[spec["column"]]))
    label_matrix.append(label_row)

label_matrix = np.array(label_matrix, dtype=object)


# =============================================================================
# 7. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(16.0, 8.8), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = scenario lever heatmap
#   right-side figure text = interpretation boxes
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.205, 0.170, 0.565, 0.655])
style_dark_axis(ax)

image = ax.imshow(
    normalized_matrix[metric_columns].to_numpy(),
    cmap=DIVERGING_CMAP,
    norm=DIVERGING_NORM,
    aspect="auto",
)

row_count = len(plot_df)
col_count = len(metric_columns)

# X-axis column labels at top.
ax.set_xticks(np.arange(col_count))
ax.set_xticklabels(
    metric_labels,
    color=TEXT_COLOR,
    fontsize=8.5,
)

ax.tick_params(
    axis="x",
    top=True,
    labeltop=True,
    bottom=False,
    labelbottom=False,
    pad=8,
)

# Y-axis scenario labels.
ax.set_yticks(np.arange(row_count))
ax.set_yticklabels(
    plot_df["display_label"].tolist(),
    color=TEXT_COLOR,
    fontsize=8.4,
)

ax.tick_params(axis="y", pad=7)

# Cell gridlines.
ax.set_xticks(np.arange(-0.5, col_count, 1), minor=True)
ax.set_yticks(np.arange(-0.5, row_count, 1), minor=True)

ax.grid(
    which="minor",
    color=GRID_COLOR,
    linewidth=0.65,
    alpha=0.25,
)

ax.tick_params(which="minor", bottom=False, left=False)

# Group separators and family labels.
for group in group_ranges:
    if group["start"] > 0:
        ax.axhline(
            group["start"] - 0.5,
            color=TEXT_COLOR,
            linewidth=1.0,
            alpha=0.65,
        )

    ax.text(
        -1.50,
        group["center"],
        group["family_label"],
        ha="right",
        va="center",
        fontsize=8.7,
        color=TEXT_COLOR,
        fontweight="bold",
        clip_on=False,
    )

# Cell text labels.
for row_idx in range(row_count):
    for col_idx in range(col_count):
        norm_value = normalized_matrix.iloc[row_idx, col_idx]
        rgba = DIVERGING_CMAP(DIVERGING_NORM(norm_value))
        label_color = text_color_for_rgba(rgba)

        ax.text(
            col_idx,
            row_idx,
            label_matrix[row_idx, col_idx],
            ha="center",
            va="center",
            fontsize=7.3,
            color=label_color,
            fontweight="bold",
        )

# Axis labels.
ax.set_ylabel(
    "Scenario Family / Challenger Scenario",
    color=TEXT_COLOR,
    fontsize=10.0,
    labelpad=54,
)

# Titles.
fig.suptitle(
    "Scenario Lever Matrix",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "How Governed Scenario Families Move the Risk Engine",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "Portfolio-level deltas versus each scenario family’s reference slice",
    ha="center",
    va="center",
    fontsize=9.5,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.35",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Right-side interpretation box.
readout_text = (
    "How to read:\n\n"
    "Each row compares a\n"
    "scenario to its own\n"
    "family reference.\n\n"
    "Blue = lower than reference\n"
    "Red = higher than reference\n"
    "Dark = little movement\n\n"
    "Color intensity is normalized\n"
    "within each metric column.\n\n"
    "This avoids comparing dollars,\n"
    "percent points, and loss dollars\n"
    "on one misleading global scale."
)

fig.text(
    0.805,
    0.610,
    readout_text,
    fontsize=8.4,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.55",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Scenario-lever interpretation box.
lever_text = (
    "Scenario lever meaning:\n\n"
    "Rate → APR / payment / PTI\n"
    "Credit box → PD proxy / EL\n"
    "Exposure → amount / PTI / EL\n"
    "LGD → severity / EL\n"
    "Mix → product structure / EL\n\n"
    "Selected readouts:\n"
    "Credit Stress:\n"
    "  +8.8pp PD proxy | +$99.1M EL\n"
    "Prime Growth:\n"
    "  -5.4pp PD proxy | -$64.5M EL\n"
    "Broad LGD Stress:\n"
    "  +10.2pp LGD | +$78.6M EL"
)

fig.text(
    0.805,
    0.250,
    lever_text,
    fontsize=8.2,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.55",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.82,
    },
)

# Footer caption.
caption = (
    "The Scenario Lever Matrix compares each challenger scenario to its family reference. "
    "Cell labels show raw portfolio-level deltas, while color shows relative movement within each metric. "
    "The matrix demonstrates that Module 1 supports multiple governed scenario levers—not just rate shocks—"
    "including credit-box mix, exposure appetite, LGD severity, and portfolio-mix changes."
)

fig.text(
    CONTENT_CENTER_X,
    0.045,
    "\n".join(textwrap.wrap(caption, width=165)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)


# =============================================================================
# 8. SAVE OUTPUTS
# =============================================================================

fig.savefig(
    OUTPUT_PNG,
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    facecolor=fig.get_facecolor(),
)

plt.close(fig)

print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nScenario lever matrix data used:")
display_cols = [
    "family",
    "scenario_name",
    "family_reference",
    "delta_requested_k",
    "delta_apr_pp",
    "delta_payment",
    "delta_pti_pp",
    "delta_pd_proxy_pp",
    "delta_lgd_pp",
    "delta_total_el_m",
]

print(plot_df[display_cols].to_string(index=False))

print("\nFormatted cell labels:")
for idx, row in plot_df.iterrows():
    formatted = {
        spec["label"].replace("\n", " "): spec["formatter"](row[spec["column"]])
        for spec in METRIC_SPECS
    }
    print(f"{row['scenario_name']}: {formatted}")
```
<!-- END_MESSAGE C040-M02518 -->


---

<a id="c040-m02519"></a>

### C040-M02519

**Andrew** · 2026-05-27T12:22:32.682000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02519 -->
great work.  now lets lock down module 1 panel 3 spec
<!-- END_MESSAGE C040-M02519 -->


---

<a id="c040-m02522"></a>

### C040-M02522

**ChatGPT** · 2026-05-27T12:29:36.700767-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02522 -->
## Module 1 Panel 3 spec locked: Scenario Expected-Loss Impact Decomposition

### Panel title

```text
Scenario Expected-Loss Impact Decomposition
Product Contribution to Portfolio EL Movement
```

Recommended subtitle:

```text
Selected scenario levers vs family reference | stacked by product contribution
```

This panel should complete the Module 1 collage by showing **where scenario Expected Loss movement comes from**. Panel 1 proves the baseline product × score risk surface. Panel 2 proves that Module 1 has multiple governed scenario levers. Panel 3 should show that those scenario movements can be decomposed into product-level drivers, with product × score detail available for the largest underlying movements.

This fits Module 1’s core design thesis: credit risk is not solely a borrower-profile outcome; it is shaped by product structure, affordability, exposure, macro assumptions, LGD, and the synthetic estimated-PD proxy. fileciteturn54file88 The validation summary also supports this framing by emphasizing deterministic population generation, configured product/score composition, coherent financial relationships, and scenario-capable comparison. fileciteturn54file89

---

# 1. What Panel 3 is trying to demonstrate

Panel 3 should answer:

> **When scenario levers move total Expected Loss, which products are driving that movement?**

The reader should see:

```text
Credit-box scenarios:
    change portfolio risk composition and move EL through score / risk mix.

Exposure scenarios:
    change requested amount, payment burden, PTI, and EL.

LGD scenarios:
    move EL through severity rather than borrower mix or rate pressure.

Portfolio-mix scenarios:
    move EL by shifting product structure and exposure composition.
```

The important point is that Module 1 can explain scenario movement, not just report it.

---

# 2. Value-add versus Panels 1 and 2

```text
Panel 1:
    Baseline cross-sectional risk realism.
    Product × score surface.

Panel 2:
    Campaign scenario breadth.
    How scenario families move portfolio-level metrics.

Panel 3:
    Scenario impact attribution.
    Which products drive the Expected Loss movement.
```

Panel 3 should not repeat the Panel 2 matrix. It should decompose the most interesting scenario movements into product-level contribution.

---

# 3. Data source

Use:

```text
10.03_QA_product_score_scenario_summary_campaign
```

This panel should **not** rely on 10.04.

Reason:

```text
10.03 is campaign-level and covers every scenario × product × score cell.
10.04 is a matched-pair diagnostic and may only reflect the last comparison that was run.
```

Panel 3 can use 10.02 only as a cross-check for exact scenario-level total Expected Loss deltas, but the chart itself should be sourced from 10.03.

---

# 4. Required fields from 10.03

Minimum fields:

```text
scenario_set_name
scenario_name
population_id
product_type
score_band
applications
avg_expected_loss
```

Recommended additional fields to carry:

```text
avg_requested_amount
avg_apr
avg_monthly_payment
avg_pti
avg_pd
avg_lgd
```

Those extra fields are useful for callouts and interpretation but are not required for the main decomposition.

---

# 5. Derived metrics

For each scenario × product × score cell:

```text
segment_total_expected_loss =
    applications × avg_expected_loss
```

For each selected scenario, compare to its family reference:

```text
delta_segment_total_expected_loss =
    scenario_segment_total_expected_loss
    - reference_segment_total_expected_loss
```

Then aggregate by product:

```text
delta_product_total_expected_loss =
    SUM(delta_segment_total_expected_loss)
```

Then aggregate across products for the scenario total:

```text
delta_scenario_total_expected_loss =
    SUM(delta_product_total_expected_loss)
```

If there is minor rounding difference versus 10.02 totals, that is expected if the exported `avg_expected_loss` values are rounded. In that case, use 10.03 for the decomposition and optionally use 10.02 for exact scenario-total labels.

---

# 6. Scenario rows to show

Use selected **non-rate scenario levers**. Rate scenarios are already represented in Panel 2 and are visually less interesting for Panel 3 because their EL deltas are relatively modest.

Lock these seven rows:

```text
Credit Box:
    PRIME_GROWTH_SCORE_MIX
    CREDIT_STRESS_SCORE_MIX

Exposure Intensity:
    LOW_BALANCE_CONSERVATIVE_REQUESTS
    HIGH_BALANCE_APPETITE

LGD Severity:
    BROAD_LGD_STRESS

Portfolio Mix:
    REVOLVING_LINE_EXPANSION_MIX
    SECURED_BALANCE_GROWTH_MIX
```

Display labels:

```text
Prime Growth
Credit Stress
Low-Balance Conservative
High-Balance Appetite
Broad LGD Stress
Revolving Expansion
Secured Balance Growth
```

This set gives the panel both positive and negative movement and captures the main non-rate scenario architecture.

---

# 7. Reference logic

Each selected scenario should be compared to its family reference:

```text
Credit Box:
    CREDIT_BOX_BASELINE_REFERENCE

Exposure Intensity:
    EXPOSURE_BASELINE_REFERENCE

LGD Severity:
    LGD_BASELINE_REFERENCE

Portfolio Mix:
    PORTFOLIO_MIX_BASELINE_REFERENCE
```

Do **not** compare every scenario to `BASELINE_V2`. That would be less analytically clean because the campaign uses family-specific reference slices.

---

# 8. Chart type

Use a **diverging stacked horizontal bar chart**.

### Rows

```text
selected scenarios
```

Grouped visually by scenario family:

```text
Credit Box
Exposure
LGD
Portfolio Mix
```

### X-axis

```text
Δ Total Expected Loss ($M)
```

### Stack

```text
product_type contribution
```

Product stack categories:

```text
MORTGAGE
HELOC
AUTO_LOAN
UNSECURED_PERSONAL_LOAN
REVOLVING_LINE
```

### Diverging logic

```text
Positive product contributions:
    stack to the right of zero.

Negative product contributions:
    stack to the left of zero.
```

This is important. Unlike the prior rate-up attribution panel, this revised chart must support both positive and negative scenario movement.

---

# 9. Product colors and legend

Use a product-type legend:

```text
Mortgage
HELOC
Auto Loan
Unsecured Personal Loan
Revolving Line
```

Keep the colors consistent across all rows. The product colors do not need to imply good/bad; they represent product contribution only.

Color interpretation should be:

```text
position left/right of zero = lower/higher Expected Loss versus reference
color = product type
```

---

# 10. Labels

Use:

```text
bar-end label = total scenario Δ Total Expected Loss
```

Example format:

```text
+$99.1M
-$64.5M
+$78.6M
```

Inside stacked segments, label only material product contributions.

Recommended threshold:

```text
abs(product contribution) >= $10M
```

This keeps the chart readable in a collage.

---

# 11. Right-side callout: largest product × score movements

Include the optional right-side callout. This is a strong addition.

The main bar chart decomposes by product. The right-side callout should show the top product × score movements underneath the product totals.

### Source

Use the same 10.03-derived product × score deltas:

```text
delta_segment_total_expected_loss
```

### Sort

```text
ORDER BY ABS(delta_segment_total_expected_loss) DESC
```

### Display top 5

Suggested format:

```text
Largest product × score movements:

1. Credit Stress
   Mortgage × Subprime: +$XM

2. Broad LGD Stress
   Mortgage × Subprime: +$XM

3. Prime Growth
   Mortgage × Subprime: -$XM

4. Secured Balance Growth
   Mortgage × Near Prime: +$XM

5. High-Balance Appetite
   HELOC × Near Prime: +$XM
```

The exact rows and values should be data-driven from 10.03. Do not hardcode assumptions about which cells will rank highest until the Python calculation confirms them.

---

# 12. Right-side interpretation box

Panel 3 should also include a compact explanation box:

```text
How to read:

Each row compares a scenario
to its family reference.

Bars show Δ Total Expected Loss.

Left of zero = lower EL
Right of zero = higher EL

Stacks show product contribution.

Largest product × score
drivers are listed below.
```

This prevents the reader from treating the panel as a generic stacked bar chart.

---

# 13. Caption

Recommended README caption:

```text
Scenario Expected-Loss Impact Decomposition compares selected scenario levers to their family reference slices. Bars show total Expected Loss movement, stacked by product contribution, while the callout identifies the largest product × score drivers. This shows that Module 1 can explain where scenario risk movement concentrates rather than only reporting aggregate portfolio deltas.
```

Short collage caption:

```text
Scenario EL decomposition: selected scenario deltas versus family references, stacked by product contribution with top product × score drivers called out.
```

---

# 14. What this panel should not do

Do **not** use 10.04 unless we intentionally rerun and preserve a specific matched-pair export.

Do **not** show all scenarios. Panel 2 already covers all scenario families.

Do **not** include rate scenarios unless you want a small “rate scenarios omitted due to modest EL movement” note. The panel should focus on material non-rate levers.

Do **not** stack by score band in the main bar chart. Product contribution is easier to read and more connected to business strategy. Product × score belongs in the callout.

Do **not** use a positive-only stacked chart. This panel must support mixed-sign movement.

Do **not** imply scenario outputs are forecasts. These are controlled synthetic scenario sensitivities.

---

# Final locked Panel 3 spec

```text
Panel name:
    Scenario Expected-Loss Impact Decomposition

Purpose:
    Show which products drive total Expected Loss movement for selected Module 1 scenario levers.

Source:
    Section 10.03 product × score scenario summary campaign CSV

Reference logic:
    CREDIT_BOX scenarios     → CREDIT_BOX_BASELINE_REFERENCE
    EXPOSURE scenarios       → EXPOSURE_BASELINE_REFERENCE
    LGD scenarios            → LGD_BASELINE_REFERENCE
    PORTFOLIO_MIX scenarios  → PORTFOLIO_MIX_BASELINE_REFERENCE

Selected rows:
    PRIME_GROWTH_SCORE_MIX
    CREDIT_STRESS_SCORE_MIX
    LOW_BALANCE_CONSERVATIVE_REQUESTS
    HIGH_BALANCE_APPETITE
    BROAD_LGD_STRESS
    REVOLVING_LINE_EXPANSION_MIX
    SECURED_BALANCE_GROWTH_MIX

Chart type:
    Diverging stacked horizontal bar chart

X-axis:
    Δ Total Expected Loss ($M)

Stack:
    Product contribution

Product stack categories:
    Mortgage
    HELOC
    Auto Loan
    Unsecured Personal Loan
    Revolving Line

Bar-end labels:
    Total scenario Δ Total Expected Loss

Inside labels:
    Product contributions where abs(contribution) >= $10M

Right-side callout:
    Top 5 product × score movements by absolute Δ Total Expected Loss

Primary message:
    Module 1 does not merely generate scenarios; it makes scenario impact attributable.
    Scenario Expected Loss movement can be decomposed into product-level and product × score drivers.
```

This gives the Module 1 collage a clean final arc:

```text
Panel 1:
    Baseline product × score risk surface.

Panel 2:
    Scenario lever matrix across the full campaign.

Panel 3:
    Product-level and product × score attribution of selected scenario EL movement.
```
<!-- END_MESSAGE C040-M02522 -->


---

<a id="c040-m02523"></a>

### C040-M02523

**Andrew** · 2026-05-27T12:35:44.770000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02523 -->
I agree with panel 3 spec.  please do not generate image.  please produce python code.
<!-- END_MESSAGE C040-M02523 -->


---

<a id="c040-m02526"></a>

### C040-M02526

**ChatGPT** · 2026-05-27T12:44:19.851050-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02526 -->
Below is the full-copy Python code for **Module 1 Panel 3 — Scenario Expected-Loss Impact Decomposition**. It reads the campaign-level `10.03` CSV directly because Panel 3 depends on the full scenario × product × score grid, rather than a small hardcoded table. This keeps the decomposition tied to the final exported evidence layer and aligned with Module 1’s validated product/score-aware, scenario-capable framework. fileciteturn54file88turn54file89

```python
"""
Module 1 README Panel 3
Scenario Expected-Loss Impact Decomposition:
Product Contribution to Portfolio EL Movement

This script reads the final-campaign Section 10.03 CSV and derives product-level
Expected Loss contribution deltas for selected non-rate scenario levers.

Panel thesis:
    Module 1 does not merely generate scenarios.
    It makes scenario impact attributable.

    Scenario Expected Loss movement can be decomposed into:
        scenario family
        scenario lever
        product contribution
        product × score-band driver

Data source:
    Final campaign Section 10.03:
    Product × score scenario summary.

Expected input file:
    module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv

Chart design:
    Diverging stacked horizontal bar chart.

    Rows:
        selected non-rate scenario levers.

    X-axis:
        Δ Total Expected Loss ($M)

    Stack:
        product_type contribution.

    Direction:
        left of zero  = lower total Expected Loss versus family reference
        right of zero = higher total Expected Loss versus family reference

    Right-side callout:
        Top product × score movements by absolute Δ Total Expected Loss.

Output:
    assets/module1_scenario_expected_loss_decomposition.png
    assets/module1_scenario_expected_loss_decomposition.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. INPUT / OUTPUT SETTINGS
# =============================================================================

# The script tries these paths in order. Keep the first one for local README use.
CANDIDATE_INPUT_CSVS = [
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv"),
]

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module1_scenario_expected_loss_decomposition.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_scenario_expected_loss_decomposition.svg"


# =============================================================================
# 2. SCENARIO FAMILY / REFERENCE CONFIGURATION
# =============================================================================

# Panel 3 intentionally focuses on selected non-rate scenario levers.
# Rate environment is already visible in the scenario lever matrix.
SELECTED_SCENARIOS = [
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "scenario_name": "PRIME_GROWTH_SCORE_MIX",
        "display_label": "Prime\nGrowth",
        "reference_scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
    },
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "scenario_name": "CREDIT_STRESS_SCORE_MIX",
        "display_label": "Credit\nStress",
        "reference_scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
    },
    {
        "family": "Exposure",
        "family_label": "Exposure\nIntensity",
        "scenario_name": "LOW_BALANCE_CONSERVATIVE_REQUESTS",
        "display_label": "Low-Balance\nConservative",
        "reference_scenario_name": "EXPOSURE_BASELINE_REFERENCE",
    },
    {
        "family": "Exposure",
        "family_label": "Exposure\nIntensity",
        "scenario_name": "HIGH_BALANCE_APPETITE",
        "display_label": "High-Balance\nAppetite",
        "reference_scenario_name": "EXPOSURE_BASELINE_REFERENCE",
    },
    {
        "family": "LGD",
        "family_label": "LGD\nSeverity",
        "scenario_name": "BROAD_LGD_STRESS",
        "display_label": "Broad LGD\nStress",
        "reference_scenario_name": "LGD_BASELINE_REFERENCE",
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "scenario_name": "REVOLVING_LINE_EXPANSION_MIX",
        "display_label": "Revolving\nExpansion",
        "reference_scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "scenario_name": "SECURED_BALANCE_GROWTH_MIX",
        "display_label": "Secured Balance\nGrowth",
        "reference_scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
    },
]

TARGET_POPULATION_ID = "BASE_POPULATION_V1"

PRODUCT_ORDER = [
    "MORTGAGE",
    "HELOC",
    "AUTO_LOAN",
    "UNSECURED_PERSONAL_LOAN",
    "REVOLVING_LINE",
]

PRODUCT_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

PRODUCT_LEGEND_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured Personal Loan",
    "REVOLVING_LINE": "Revolving Line",
}

SCORE_LABELS = {
    "SUPER_PRIME": "Super Prime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near Prime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep Subprime",
}


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
ZERO_LINE_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

CONTENT_CENTER_X = 0.50

PRODUCT_COLORS = {
    "MORTGAGE": "#7fcdbb",
    "HELOC": "#2f84c4",
    "AUTO_LOAN": "#f0a62e",
    "UNSECURED_PERSONAL_LOAN": "#2ca02c",
    "REVOLVING_LINE": "#d95f5f",
}

BAR_ALPHA = 0.90

# Inside-segment labels are only shown when product contribution is material.
SEGMENT_LABEL_THRESHOLD_M = 10.0

# Right-side callout top-N.
TOP_DRIVER_COUNT = 5


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def resolve_input_path(candidate_paths: list[Path]) -> Path:
    """Return the first existing input path."""
    for candidate in candidate_paths:
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        "Could not find the Section 10.03 CSV. Checked:\n"
        + "\n".join(str(path) for path in candidate_paths)
    )


def coerce_numeric(series: pd.Series) -> pd.Series:
    """
    Convert a Series to numeric, allowing for commas / currency symbols if present.
    """
    if pd.api.types.is_numeric_dtype(series):
        return series

    cleaned = (
        series.astype(str)
        .str.replace(",", "", regex=False)
        .str.replace("$", "", regex=False)
        .str.replace("%", "", regex=False)
        .str.strip()
    )

    return pd.to_numeric(cleaned, errors="coerce")


def require_columns(df: pd.DataFrame, required_columns: list[str]) -> None:
    """Raise a clear error if required columns are missing."""
    missing = [column for column in required_columns if column not in df.columns]

    if missing:
        raise ValueError(
            "Input CSV is missing required column(s): "
            + ", ".join(missing)
            + "\n\nAvailable columns:\n"
            + "\n".join(df.columns)
        )


def find_total_el_column(df: pd.DataFrame) -> str | None:
    """
    Prefer a true segment total Expected Loss column if the export has one.
    Otherwise the script derives segment total EL as:
        applications × avg_expected_loss
    """
    candidates = [
        "total_expected_loss",
        "total_expected_loss_amount",
        "segment_total_expected_loss",
        "sum_expected_loss",
        "total_el",
    ]

    for candidate in candidates:
        if candidate in df.columns:
            return candidate

    return None


def format_m(value: float, decimals: int = 1) -> str:
    """Format a value in millions with sign."""
    if abs(value) < 0.05:
        return "$0.0M"

    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}M"


def format_m_compact(value: float) -> str:
    """Compact format for segment labels."""
    if abs(value) < 0.05:
        return "$0M"

    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.0f}M"


def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


def prettify_scenario_name(value: str) -> str:
    """Readable scenario label fallback."""
    return str(value).replace("_", " ").title()


def prettify_product(value: str) -> str:
    """Readable product label fallback."""
    return PRODUCT_LEGEND_LABELS.get(value, str(value).replace("_", " ").title())


def prettify_score(value: str) -> str:
    """Readable score-band label fallback."""
    return SCORE_LABELS.get(value, str(value).replace("_", " ").title())


def text_color_for_hex(hex_color: str) -> str:
    """
    Pick black or white text based on background luminance.

    This keeps inside-segment labels readable.
    """
    hex_color = hex_color.lstrip("#")

    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0

    luminance = 0.299 * r + 0.587 * g + 0.114 * b

    return "black" if luminance > 0.58 else "white"


def style_dark_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)

    ax.xaxis.label.set_color(TEXT_COLOR)
    ax.yaxis.label.set_color(TEXT_COLOR)
    ax.title.set_color(TEXT_COLOR)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)

    ax.grid(
        True,
        axis="x",
        linewidth=0.45,
        alpha=0.28,
        color=GRID_COLOR,
    )


# =============================================================================
# 5. LOAD AND PREPARE INPUT DATA
# =============================================================================

input_csv = resolve_input_path(CANDIDATE_INPUT_CSVS)
raw_df = pd.read_csv(input_csv)

required = [
    "scenario_name",
    "population_id",
    "product_type",
    "score_band",
    "applications",
    "avg_expected_loss",
]

require_columns(raw_df, required)

df = raw_df.copy()

# Population filter keeps the campaign comparison aligned to the same synthetic population.
df = df.loc[df["population_id"] == TARGET_POPULATION_ID].copy()

if df.empty:
    raise ValueError(
        f"No rows found for population_id = {TARGET_POPULATION_ID}."
    )

# Normalize text keys.
for column in ["scenario_name", "population_id", "product_type", "score_band"]:
    df[column] = df[column].astype(str).str.strip()

# Numeric coercion.
df["applications"] = coerce_numeric(df["applications"])
df["avg_expected_loss"] = coerce_numeric(df["avg_expected_loss"])

total_el_col = find_total_el_column(df)

if total_el_col is not None:
    df[total_el_col] = coerce_numeric(df[total_el_col])
    df["segment_total_expected_loss"] = df[total_el_col]
else:
    df["segment_total_expected_loss"] = df["applications"] * df["avg_expected_loss"]

# Guardrails.
if df["applications"].isna().any():
    raise ValueError("applications contains null / nonnumeric values after coercion.")

if df["avg_expected_loss"].isna().any():
    raise ValueError("avg_expected_loss contains null / nonnumeric values after coercion.")

if df["segment_total_expected_loss"].isna().any():
    raise ValueError("segment_total_expected_loss contains null values after derivation.")

# Aggregate in case the export has duplicate rows at the same scenario × product × score grain.
segment_df = (
    df.groupby(
        ["scenario_name", "product_type", "score_band"],
        as_index=False,
    )
    .agg(
        applications=("applications", "sum"),
        segment_total_expected_loss=("segment_total_expected_loss", "sum"),
    )
)

available_scenarios = set(segment_df["scenario_name"].unique())

required_scenarios = set()
for item in SELECTED_SCENARIOS:
    required_scenarios.add(item["scenario_name"])
    required_scenarios.add(item["reference_scenario_name"])

missing_scenarios = sorted(required_scenarios - available_scenarios)

if missing_scenarios:
    raise ValueError(
        "The input Section 10.03 CSV is missing required scenario(s): "
        + ", ".join(missing_scenarios)
    )


# =============================================================================
# 6. BUILD SCENARIO × PRODUCT × SCORE DELTAS
# =============================================================================

delta_records: list[dict] = []

for row_order, scenario_config in enumerate(SELECTED_SCENARIOS):
    scenario_name = scenario_config["scenario_name"]
    reference_name = scenario_config["reference_scenario_name"]

    scenario_slice = segment_df.loc[
        segment_df["scenario_name"] == scenario_name,
        [
            "product_type",
            "score_band",
            "applications",
            "segment_total_expected_loss",
        ],
    ].rename(
        columns={
            "applications": "scenario_applications",
            "segment_total_expected_loss": "scenario_segment_total_expected_loss",
        }
    )

    reference_slice = segment_df.loc[
        segment_df["scenario_name"] == reference_name,
        [
            "product_type",
            "score_band",
            "applications",
            "segment_total_expected_loss",
        ],
    ].rename(
        columns={
            "applications": "reference_applications",
            "segment_total_expected_loss": "reference_segment_total_expected_loss",
        }
    )

    merged = pd.merge(
        scenario_slice,
        reference_slice,
        on=["product_type", "score_band"],
        how="outer",
    )

    merged["scenario_applications"] = merged["scenario_applications"].fillna(0)
    merged["reference_applications"] = merged["reference_applications"].fillna(0)

    merged["scenario_segment_total_expected_loss"] = (
        merged["scenario_segment_total_expected_loss"].fillna(0.0)
    )

    merged["reference_segment_total_expected_loss"] = (
        merged["reference_segment_total_expected_loss"].fillna(0.0)
    )

    merged["delta_segment_total_expected_loss"] = (
        merged["scenario_segment_total_expected_loss"]
        - merged["reference_segment_total_expected_loss"]
    )

    for _, segment_row in merged.iterrows():
        delta_records.append(
            {
                "row_order": row_order,
                "family": scenario_config["family"],
                "family_label": scenario_config["family_label"],
                "scenario_name": scenario_name,
                "display_label": scenario_config["display_label"],
                "reference_scenario_name": reference_name,
                "product_type": segment_row["product_type"],
                "score_band": segment_row["score_band"],
                "scenario_applications": segment_row["scenario_applications"],
                "reference_applications": segment_row["reference_applications"],
                "scenario_segment_total_expected_loss": segment_row[
                    "scenario_segment_total_expected_loss"
                ],
                "reference_segment_total_expected_loss": segment_row[
                    "reference_segment_total_expected_loss"
                ],
                "delta_segment_total_expected_loss": segment_row[
                    "delta_segment_total_expected_loss"
                ],
            }
        )

delta_df = pd.DataFrame(delta_records)

delta_df["delta_segment_total_expected_loss_m"] = (
    delta_df["delta_segment_total_expected_loss"] / 1_000_000.0
)

# Product-level contribution matrix.
product_contrib = (
    delta_df.groupby(
        ["row_order", "family", "family_label", "scenario_name", "display_label", "product_type"],
        as_index=False,
    )
    .agg(
        delta_product_total_expected_loss=("delta_segment_total_expected_loss", "sum")
    )
)

product_contrib["delta_product_total_expected_loss_m"] = (
    product_contrib["delta_product_total_expected_loss"] / 1_000_000.0
)

scenario_totals = (
    product_contrib.groupby(
        ["row_order", "family", "family_label", "scenario_name", "display_label"],
        as_index=False,
    )
    .agg(
        delta_scenario_total_expected_loss=("delta_product_total_expected_loss", "sum")
    )
)

scenario_totals["delta_scenario_total_expected_loss_m"] = (
    scenario_totals["delta_scenario_total_expected_loss"] / 1_000_000.0
)

# Ensure product contribution matrix contains every selected product for every selected scenario.
scenario_rows = scenario_totals[
    ["row_order", "family", "family_label", "scenario_name", "display_label"]
].drop_duplicates()

complete_index = pd.MultiIndex.from_product(
    [
        scenario_rows["row_order"].tolist(),
        PRODUCT_ORDER,
    ],
    names=["row_order", "product_type"],
).to_frame(index=False)

complete_index = complete_index.merge(
    scenario_rows,
    on="row_order",
    how="left",
)

plot_product = complete_index.merge(
    product_contrib[
        [
            "row_order",
            "product_type",
            "delta_product_total_expected_loss_m",
        ]
    ],
    on=["row_order", "product_type"],
    how="left",
)

plot_product["delta_product_total_expected_loss_m"] = (
    plot_product["delta_product_total_expected_loss_m"].fillna(0.0)
)

plot_product = plot_product.sort_values(["row_order"]).reset_index(drop=True)

# Top product × score drivers by absolute movement.
top_segments = (
    delta_df.assign(
        abs_delta_segment_total_expected_loss=lambda x: x[
            "delta_segment_total_expected_loss"
        ].abs()
    )
    .sort_values("abs_delta_segment_total_expected_loss", ascending=False)
    .head(TOP_DRIVER_COUNT)
    .copy()
)

# Group ranges for family labels.
group_ranges = []
for family, group in scenario_totals.groupby("family", sort=False):
    start = int(group["row_order"].min())
    end = int(group["row_order"].max())

    family_label = group["family_label"].iloc[0]

    group_ranges.append(
        {
            "family": family,
            "family_label": family_label,
            "start": start,
            "end": end,
            "center": (start + end) / 2.0,
        }
    )


# =============================================================================
# 7. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(16.0, 8.8), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = diverging stacked horizontal contribution chart
#   right-side figure text = legend + interpretation + top product × score drivers
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.155, 0.170, 0.595, 0.655])
style_dark_axis(ax)

y_positions = list(range(len(scenario_totals)))

# Positive and negative stacks need separate cumulative bases.
positive_base = pd.Series([0.0] * len(scenario_totals), index=scenario_totals["row_order"])
negative_base = pd.Series([0.0] * len(scenario_totals), index=scenario_totals["row_order"])

bar_handles = {}

for product_type in PRODUCT_ORDER:
    product_rows = plot_product.loc[plot_product["product_type"] == product_type].copy()
    product_rows = product_rows.sort_values("row_order")

    color = PRODUCT_COLORS.get(product_type, "#999999")
    label = PRODUCT_LEGEND_LABELS.get(product_type, prettify_product(product_type))

    for _, row in product_rows.iterrows():
        y = int(row["row_order"])
        value = float(row["delta_product_total_expected_loss_m"])

        if abs(value) < 1e-9:
            continue

        if value >= 0:
            left = positive_base.loc[y]
            positive_base.loc[y] += value
        else:
            left = negative_base.loc[y]
            negative_base.loc[y] += value

        bar = ax.barh(
            y,
            value,
            left=left,
            height=0.62,
            color=color,
            alpha=BAR_ALPHA,
            label=label if product_type not in bar_handles else None,
        )

        if product_type not in bar_handles:
            bar_handles[product_type] = bar[0]

        if abs(value) >= SEGMENT_LABEL_THRESHOLD_M:
            ax.text(
                left + value / 2.0,
                y,
                f"{PRODUCT_LEGEND_LABELS.get(product_type, prettify_product(product_type))}\n{format_m_compact(value)}",
                ha="center",
                va="center",
                fontsize=7.2,
                color=text_color_for_hex(color),
                fontweight="bold",
            )

# Scenario total labels at left/right bar ends.
scenario_totals = scenario_totals.sort_values("row_order").reset_index(drop=True)

x_positive_max = max(positive_base.max(), 0.0)
x_negative_min = min(negative_base.min(), 0.0)

x_span = max(abs(x_positive_max), abs(x_negative_min), 1.0)

for _, row in scenario_totals.iterrows():
    y = int(row["row_order"])
    total_m = float(row["delta_scenario_total_expected_loss_m"])

    if total_m >= 0:
        x_text = positive_base.loc[y] + x_span * 0.025
        ha = "left"
    else:
        x_text = negative_base.loc[y] - x_span * 0.025
        ha = "right"

    ax.text(
        x_text,
        y,
        format_m(total_m),
        ha=ha,
        va="center",
        fontsize=8.7,
        color=TEXT_COLOR,
        fontweight="bold",
    )

# Axes and labels.
ax.axvline(
    0,
    color=ZERO_LINE_COLOR,
    linewidth=1.1,
    alpha=0.85,
)

ax.set_yticks(y_positions)
ax.set_yticklabels(
    scenario_totals["display_label"].tolist(),
    color=TEXT_COLOR,
    fontsize=9.0,
)

ax.invert_yaxis()

# Family group separators and labels.
for group in group_ranges:
    if group["start"] > 0:
        ax.axhline(
            group["start"] - 0.5,
            color=TEXT_COLOR,
            linewidth=1.0,
            alpha=0.55,
        )

    ax.text(
        -0.22,
        group["center"],
        group["family_label"],
        transform=ax.get_yaxis_transform(),
        ha="right",
        va="center",
        fontsize=8.5,
        color=TEXT_COLOR,
        fontweight="bold",
        clip_on=False,
    )

ax.set_xlabel(
    "Δ Total Expected Loss ($M)",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylabel(
    "Scenario Family / Selected Scenario Lever",
    color=TEXT_COLOR,
    fontsize=10.2,
    labelpad=72,
)

# Symmetric x-axis limits for mixed-sign comparison.
max_abs = max(abs(x_positive_max), abs(x_negative_min), 1.0)
ax.set_xlim(-max_abs * 1.20, max_abs * 1.20)

ax.xaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:,.0f}M")
)

# Direction note inside chart.
ax.text(
    0.50,
    1.015,
    "Left of zero = lower EL vs reference     |     Right of zero = higher EL vs reference",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=8.4,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.30",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Product legend outside chart.
handles = [bar_handles[p] for p in PRODUCT_ORDER if p in bar_handles]
labels = [PRODUCT_LEGEND_LABELS[p] for p in PRODUCT_ORDER if p in bar_handles]

legend = fig.legend(
    handles,
    labels,
    loc="upper left",
    bbox_to_anchor=(0.785, 0.825),
    fontsize=7.8,
    frameon=True,
    title="Product contribution",
    title_fontsize=8.4,
    ncol=1,
    borderpad=0.55,
    labelspacing=0.35,
    handlelength=1.2,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Titles.
fig.suptitle(
    "Scenario Expected-Loss Impact Decomposition",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Product Contribution to Portfolio EL Movement",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "Selected scenario levers vs family reference | stacked by product contribution",
    ha="center",
    va="center",
    fontsize=9.5,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.35",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Right-side interpretation box.
readout_text = (
    "How to read:\n\n"
    "Each row compares a\n"
    "scenario to its own\n"
    "family reference.\n\n"
    "Bars show Δ Total EL.\n\n"
    "Left = lower EL\n"
    "Right = higher EL\n\n"
    "Stack color = product\n"
    "contribution.\n\n"
    "Inside labels appear only\n"
    "for material product moves."
)

fig.text(
    0.785,
    0.555,
    readout_text,
    fontsize=8.25,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.55",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Top product × score movements.
top_driver_lines = []
for idx, (_, row) in enumerate(top_segments.iterrows(), start=1):
    scenario_display = scenario_totals.loc[
        scenario_totals["scenario_name"] == row["scenario_name"],
        "display_label",
    ]

    if not scenario_display.empty:
        scenario_label = scenario_display.iloc[0].replace("\n", " ")
    else:
        scenario_label = prettify_scenario_name(row["scenario_name"])

    product_label = prettify_product(row["product_type"])
    score_label = prettify_score(row["score_band"])
    delta_m = row["delta_segment_total_expected_loss"] / 1_000_000.0

    top_driver_lines.append(
        f"{idx}. {scenario_label}\n"
        f"   {product_label} × {score_label}: {format_m(delta_m)}"
    )

top_driver_text = (
    "Largest product × score\n"
    "movements:\n\n"
    + "\n\n".join(top_driver_lines)
)

fig.text(
    0.785,
    0.205,
    top_driver_text,
    fontsize=7.65,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.50",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.82,
    },
)

# Footer caption.
caption = (
    "Scenario Expected-Loss Impact Decomposition compares selected scenario levers to their family "
    "reference slices. Bars show total Expected Loss movement, stacked by product contribution, while "
    "the callout identifies the largest product × score drivers. This shows that Module 1 can explain "
    "where scenario risk movement concentrates rather than only reporting aggregate portfolio deltas."
)

fig.text(
    CONTENT_CENTER_X,
    0.045,
    "\n".join(textwrap.wrap(caption, width=165)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)


# =============================================================================
# 8. SAVE OUTPUTS
# =============================================================================

fig.savefig(
    OUTPUT_PNG,
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    facecolor=fig.get_facecolor(),
)

plt.close(fig)


# =============================================================================
# 9. CONSOLE QA / TRACE OUTPUT
# =============================================================================

print(f"Input CSV: {input_csv}")
print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nScenario totals used:")
for _, row in scenario_totals.iterrows():
    print(
        f"{row['family']:<18} | "
        f"{row['scenario_name']:<38} | "
        f"Δ Total EL: {format_m(row['delta_scenario_total_expected_loss_m'])}"
    )

print("\nProduct contribution by scenario:")
for _, row in product_contrib.sort_values(["row_order", "product_type"]).iterrows():
    print(
        f"{row['scenario_name']:<38} | "
        f"{row['product_type']:<26} | "
        f"Δ Product Total EL: {format_m(row['delta_product_total_expected_loss_m'])}"
    )

print("\nTop product × score movements:")
for idx, (_, row) in enumerate(top_segments.iterrows(), start=1):
    print(
        f"{idx}. "
        f"{row['scenario_name']:<38} | "
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Scenario apps: {format_count(row['scenario_applications'])} | "
        f"Reference apps: {format_count(row['reference_applications'])} | "
        f"Δ Segment Total EL: {format_m(row['delta_segment_total_expected_loss'] / 1_000_000.0)}"
    )
```
<!-- END_MESSAGE C040-M02526 -->


---

<a id="c040-m02527"></a>

### C040-M02527

**Andrew** · 2026-05-27T12:53:32.700000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02527 -->
I see. i am using https://colab.research.google.com/ to run my python code.  how do I get that to read a csv? if not possible, let's try to hardcode even though it would be difficult.  advice?
<!-- END_MESSAGE C040-M02527 -->


---

<a id="c040-m02531"></a>

### C040-M02531

**ChatGPT** · 2026-05-27T12:59:20.666285-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02531 -->
Yes — Colab can absolutely read CSVs, and for **Module 1 Panel 3**, reading the CSV is the better approach. I would **not hardcode 10.03 unless we absolutely have to**. Panel 3 depends on the full scenario × product × score grid, so hardcoding would be long, fragile, and easy to mistype.

Colab gives you three practical options.

## Best option for your workflow: upload the CSV into Colab

In Colab, add a code cell near the top of the notebook:

```python
from google.colab import files
uploaded = files.upload()
```

Run it, then choose your CSV file from your computer, for example:

```text
module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv
```

After upload, Colab places the file in the current runtime working directory, usually `/content`. Then your existing Panel 3 code should work if the file name matches one of the candidate paths. Pandas reads local CSV paths directly with `pd.read_csv(...)`; the official pandas docs confirm `read_csv` accepts local paths and URLs. citeturn199662search9

The main downside is that Colab runtime storage is temporary. If the session disconnects or resets, you may need to upload the CSV again.

## Best option for repeatability: put the CSV in Google Drive and mount Drive

This is what I would use once the charts are close to final.

Upload the CSV to a Drive folder, for example:

```text
MyDrive/credit_decisioning_simulator/data/
```

Then in Colab:

```python
from google.colab import drive
drive.mount('/content/drive')
```

Then set:

```python
INPUT_CSV = "/content/drive/MyDrive/credit_decisioning_simulator/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"
```

and read it with:

```python
df = pd.read_csv(INPUT_CSV)
```

Google’s Colab external-data notebook documents using Colab with external data sources including local files and Drive. citeturn199662search2

This is the cleanest method for your chart workflow because you can keep `10.01`, `10.02`, and `10.03` together in one Drive folder and rerun the notebook without re-uploading every time.

## Best option for GitHub reproducibility: read from a raw GitHub CSV URL

Once you are comfortable making the synthetic QA CSV public in the repo, you can store it in something like:

```text
data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv
```

Then read the **raw** GitHub URL:

```python
url = "https://raw.githubusercontent.com/<your-user>/<your-repo>/<branch>/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"
df = pd.read_csv(url)
```

Pandas supports URL inputs to `read_csv`, so this works well for reproducible README chart generation if the repo data file is public. citeturn199662search9

## My recommendation

For now, use **Google Drive mount**. It is the best balance of reliable, repeatable, and not hardcoded.

Use this folder structure:

```text
credit_decisioning_simulator/
    data/
        module1_synthetic_application_risk_engine_v2.0_10.01_QA_scenario_archive_inventory_campaign.csv
        module1_synthetic_application_risk_engine_v2.0_10.02_QA_portfolio_level_scenario_summary_campaign.csv
        module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv
    assets/
        generated chart outputs
    notebooks/
        readme_chart_generation.ipynb
```

Then update the Panel 3 script’s candidate paths to include your Drive path at the top. Something like:

```python
CANDIDATE_INPUT_CSVS = [
    Path("/content/drive/MyDrive/credit_decisioning_simulator/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
]
```

That way, the same notebook works in Colab with Drive and still works locally if the CSV sits next to the notebook.

## Should we hardcode instead?

For Panel 3, I would avoid it. Hardcoding Panel 1 made sense because it was a 25-cell baseline product × score surface. Hardcoding Panel 2 was acceptable because it was a small portfolio-level scenario matrix. But Panel 3 needs many scenario × product × score cells from 10.03. Hardcoding that would make the script long and harder to validate.

Use CSV input for Panel 3. It is the right engineering choice.
<!-- END_MESSAGE C040-M02531 -->


---

<a id="c040-m02533"></a>

### C040-M02533

**Andrew** · 2026-05-27T13:27:24.669000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02533 -->
do not generate an image.  update python code (full copy paste).  the within chart product labels are overlapping.  let's let the legend speak for the products and just lists the dollar amounts when >=$10M absolute delta. for example, in prime growth, instead of Mortgage -$30M just say -$30M.  also, the left hand Credit Box / Exposure Sensitivity / LGD Severity / Portfolio Mix overlaps with the Scenario Family / Selected Scenario Lever text.  Please move the Credit Box ... Portfolio Mix middle aligned between the Scenario Family / Selected Scenario Lever Text and the Prime Growth... Secured Balance Growth texts.  no other changes.
<!-- END_MESSAGE C040-M02533 -->


---

<a id="c040-m02535"></a>

### C040-M02535

**ChatGPT** · 2026-05-27T13:33:41.425206-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02535 -->
```python
"""
Module 1 README Panel 3
Scenario Expected-Loss Impact Decomposition:
Product Contribution to Portfolio EL Movement

This script reads the final-campaign Section 10.03 CSV and derives product-level
Expected Loss contribution deltas for selected non-rate scenario levers.

Panel thesis:
    Module 1 does not merely generate scenarios.
    It makes scenario impact attributable.

    Scenario Expected Loss movement can be decomposed into:
        scenario family
        scenario lever
        product contribution
        product × score-band driver

Data source:
    Final campaign Section 10.03:
    Product × score scenario summary.

Expected input file:
    module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv

Chart design:
    Diverging stacked horizontal bar chart.

    Rows:
        selected non-rate scenario levers.

    X-axis:
        Δ Total Expected Loss ($M)

    Stack:
        product_type contribution.

    Direction:
        left of zero  = lower total Expected Loss versus family reference
        right of zero = higher total Expected Loss versus family reference

    Right-side callout:
        Top product × score movements by absolute Δ Total Expected Loss.

Output:
    assets/module1_scenario_expected_loss_decomposition.png
    assets/module1_scenario_expected_loss_decomposition.svg
"""

from __future__ import annotations

from pathlib import Path
import textwrap

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick


# =============================================================================
# 1. INPUT / OUTPUT SETTINGS
# =============================================================================

# The script tries these paths in order. Keep the first one for local README use.
CANDIDATE_INPUT_CSVS = [
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv"),
    Path("module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign.csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(1).csv"),
    Path("/mnt/data/module1_synthetic_application_risk_engine_v2.0_10.03_QA_product_score_scenario_summary_campaign(2).csv"),
]

OUTPUT_DIR = Path("assets")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_PNG = OUTPUT_DIR / "module1_scenario_expected_loss_decomposition.png"
OUTPUT_SVG = OUTPUT_DIR / "module1_scenario_expected_loss_decomposition.svg"


# =============================================================================
# 2. SCENARIO FAMILY / REFERENCE CONFIGURATION
# =============================================================================

# Panel 3 intentionally focuses on selected non-rate scenario levers.
# Rate environment is already visible in the scenario lever matrix.
SELECTED_SCENARIOS = [
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "scenario_name": "PRIME_GROWTH_SCORE_MIX",
        "display_label": "Prime\nGrowth",
        "reference_scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
    },
    {
        "family": "Credit Box",
        "family_label": "Credit\nBox",
        "scenario_name": "CREDIT_STRESS_SCORE_MIX",
        "display_label": "Credit\nStress",
        "reference_scenario_name": "CREDIT_BOX_BASELINE_REFERENCE",
    },
    {
        "family": "Exposure",
        "family_label": "Exposure\nIntensity",
        "scenario_name": "LOW_BALANCE_CONSERVATIVE_REQUESTS",
        "display_label": "Low-Balance\nConservative",
        "reference_scenario_name": "EXPOSURE_BASELINE_REFERENCE",
    },
    {
        "family": "Exposure",
        "family_label": "Exposure\nIntensity",
        "scenario_name": "HIGH_BALANCE_APPETITE",
        "display_label": "High-Balance\nAppetite",
        "reference_scenario_name": "EXPOSURE_BASELINE_REFERENCE",
    },
    {
        "family": "LGD",
        "family_label": "LGD\nSeverity",
        "scenario_name": "BROAD_LGD_STRESS",
        "display_label": "Broad LGD\nStress",
        "reference_scenario_name": "LGD_BASELINE_REFERENCE",
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "scenario_name": "REVOLVING_LINE_EXPANSION_MIX",
        "display_label": "Revolving\nExpansion",
        "reference_scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
    },
    {
        "family": "Portfolio Mix",
        "family_label": "Portfolio\nMix",
        "scenario_name": "SECURED_BALANCE_GROWTH_MIX",
        "display_label": "Secured Balance\nGrowth",
        "reference_scenario_name": "PORTFOLIO_MIX_BASELINE_REFERENCE",
    },
]

TARGET_POPULATION_ID = "BASE_POPULATION_V1"

PRODUCT_ORDER = [
    "MORTGAGE",
    "HELOC",
    "AUTO_LOAN",
    "UNSECURED_PERSONAL_LOAN",
    "REVOLVING_LINE",
]

PRODUCT_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured\nPersonal Loan",
    "REVOLVING_LINE": "Revolving\nLine",
}

PRODUCT_LEGEND_LABELS = {
    "MORTGAGE": "Mortgage",
    "HELOC": "HELOC",
    "AUTO_LOAN": "Auto Loan",
    "UNSECURED_PERSONAL_LOAN": "Unsecured Personal Loan",
    "REVOLVING_LINE": "Revolving Line",
}

SCORE_LABELS = {
    "SUPER_PRIME": "Super Prime",
    "PRIME": "Prime",
    "NEAR_PRIME": "Near Prime",
    "SUBPRIME": "Subprime",
    "DEEP_SUBPRIME": "Deep Subprime",
}


# =============================================================================
# 3. CHART STYLE SETTINGS
# =============================================================================

FIG_FACE = "black"
AX_FACE = "black"
TEXT_COLOR = "white"
GRID_COLOR = "white"
ZERO_LINE_COLOR = "white"
CALLOUT_BOX_COLOR = "#4f8fc4"

CONTENT_CENTER_X = 0.50

PRODUCT_COLORS = {
    "MORTGAGE": "#7fcdbb",
    "HELOC": "#2f84c4",
    "AUTO_LOAN": "#f0a62e",
    "UNSECURED_PERSONAL_LOAN": "#2ca02c",
    "REVOLVING_LINE": "#d95f5f",
}

BAR_ALPHA = 0.90

# Inside-segment labels are only shown when product contribution is material.
# Product names are intentionally omitted inside bars; the legend identifies product colors.
SEGMENT_LABEL_THRESHOLD_M = 10.0

# Right-side callout top-N.
TOP_DRIVER_COUNT = 5


# =============================================================================
# 4. HELPER FUNCTIONS
# =============================================================================

def resolve_input_path(candidate_paths: list[Path]) -> Path:
    """Return the first existing input path."""
    for candidate in candidate_paths:
        if candidate.exists():
            return candidate

    raise FileNotFoundError(
        "Could not find the Section 10.03 CSV. Checked:\n"
        + "\n".join(str(path) for path in candidate_paths)
    )


def coerce_numeric(series: pd.Series) -> pd.Series:
    """
    Convert a Series to numeric, allowing for commas / currency symbols if present.
    """
    if pd.api.types.is_numeric_dtype(series):
        return series

    cleaned = (
        series.astype(str)
        .str.replace(",", "", regex=False)
        .str.replace("$", "", regex=False)
        .str.replace("%", "", regex=False)
        .str.strip()
    )

    return pd.to_numeric(cleaned, errors="coerce")


def require_columns(df: pd.DataFrame, required_columns: list[str]) -> None:
    """Raise a clear error if required columns are missing."""
    missing = [column for column in required_columns if column not in df.columns]

    if missing:
        raise ValueError(
            "Input CSV is missing required column(s): "
            + ", ".join(missing)
            + "\n\nAvailable columns:\n"
            + "\n".join(df.columns)
        )


def find_total_el_column(df: pd.DataFrame) -> str | None:
    """
    Prefer a true segment total Expected Loss column if the export has one.
    Otherwise the script derives segment total EL as:
        applications × avg_expected_loss
    """
    candidates = [
        "total_expected_loss",
        "total_expected_loss_amount",
        "segment_total_expected_loss",
        "sum_expected_loss",
        "total_el",
    ]

    for candidate in candidates:
        if candidate in df.columns:
            return candidate

    return None


def format_m(value: float, decimals: int = 1) -> str:
    """Format a value in millions with sign."""
    if abs(value) < 0.05:
        return "$0.0M"

    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.{decimals}f}M"


def format_m_compact(value: float) -> str:
    """Compact format for segment labels."""
    if abs(value) < 0.05:
        return "$0M"

    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):.0f}M"


def format_count(value: float | int) -> str:
    """Format row counts with commas."""
    return f"{int(value):,}"


def prettify_scenario_name(value: str) -> str:
    """Readable scenario label fallback."""
    return str(value).replace("_", " ").title()


def prettify_product(value: str) -> str:
    """Readable product label fallback."""
    return PRODUCT_LEGEND_LABELS.get(value, str(value).replace("_", " ").title())


def prettify_score(value: str) -> str:
    """Readable score-band label fallback."""
    return SCORE_LABELS.get(value, str(value).replace("_", " ").title())


def text_color_for_hex(hex_color: str) -> str:
    """
    Pick black or white text based on background luminance.

    This keeps inside-segment labels readable.
    """
    hex_color = hex_color.lstrip("#")

    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0

    luminance = 0.299 * r + 0.587 * g + 0.114 * b

    return "black" if luminance > 0.58 else "white"


def style_dark_axis(ax: plt.Axes) -> None:
    """Apply shared dark chart styling."""
    ax.set_facecolor(AX_FACE)
    ax.tick_params(colors=TEXT_COLOR, labelsize=9)

    ax.xaxis.label.set_color(TEXT_COLOR)
    ax.yaxis.label.set_color(TEXT_COLOR)
    ax.title.set_color(TEXT_COLOR)

    for spine in ax.spines.values():
        spine.set_color(TEXT_COLOR)
        spine.set_linewidth(0.9)

    ax.grid(
        True,
        axis="x",
        linewidth=0.45,
        alpha=0.28,
        color=GRID_COLOR,
    )


# =============================================================================
# 5. LOAD AND PREPARE INPUT DATA
# =============================================================================

input_csv = resolve_input_path(CANDIDATE_INPUT_CSVS)
raw_df = pd.read_csv(input_csv)

required = [
    "scenario_name",
    "population_id",
    "product_type",
    "score_band",
    "applications",
    "avg_expected_loss",
]

require_columns(raw_df, required)

df = raw_df.copy()

# Population filter keeps the campaign comparison aligned to the same synthetic population.
df = df.loc[df["population_id"] == TARGET_POPULATION_ID].copy()

if df.empty:
    raise ValueError(
        f"No rows found for population_id = {TARGET_POPULATION_ID}."
    )

# Normalize text keys.
for column in ["scenario_name", "population_id", "product_type", "score_band"]:
    df[column] = df[column].astype(str).str.strip()

# Numeric coercion.
df["applications"] = coerce_numeric(df["applications"])
df["avg_expected_loss"] = coerce_numeric(df["avg_expected_loss"])

total_el_col = find_total_el_column(df)

if total_el_col is not None:
    df[total_el_col] = coerce_numeric(df[total_el_col])
    df["segment_total_expected_loss"] = df[total_el_col]
else:
    df["segment_total_expected_loss"] = df["applications"] * df["avg_expected_loss"]

# Guardrails.
if df["applications"].isna().any():
    raise ValueError("applications contains null / nonnumeric values after coercion.")

if df["avg_expected_loss"].isna().any():
    raise ValueError("avg_expected_loss contains null / nonnumeric values after coercion.")

if df["segment_total_expected_loss"].isna().any():
    raise ValueError("segment_total_expected_loss contains null values after derivation.")

# Aggregate in case the export has duplicate rows at the same scenario × product × score grain.
segment_df = (
    df.groupby(
        ["scenario_name", "product_type", "score_band"],
        as_index=False,
    )
    .agg(
        applications=("applications", "sum"),
        segment_total_expected_loss=("segment_total_expected_loss", "sum"),
    )
)

available_scenarios = set(segment_df["scenario_name"].unique())

required_scenarios = set()
for item in SELECTED_SCENARIOS:
    required_scenarios.add(item["scenario_name"])
    required_scenarios.add(item["reference_scenario_name"])

missing_scenarios = sorted(required_scenarios - available_scenarios)

if missing_scenarios:
    raise ValueError(
        "The input Section 10.03 CSV is missing required scenario(s): "
        + ", ".join(missing_scenarios)
    )


# =============================================================================
# 6. BUILD SCENARIO × PRODUCT × SCORE DELTAS
# =============================================================================

delta_records: list[dict] = []

for row_order, scenario_config in enumerate(SELECTED_SCENARIOS):
    scenario_name = scenario_config["scenario_name"]
    reference_name = scenario_config["reference_scenario_name"]

    scenario_slice = segment_df.loc[
        segment_df["scenario_name"] == scenario_name,
        [
            "product_type",
            "score_band",
            "applications",
            "segment_total_expected_loss",
        ],
    ].rename(
        columns={
            "applications": "scenario_applications",
            "segment_total_expected_loss": "scenario_segment_total_expected_loss",
        }
    )

    reference_slice = segment_df.loc[
        segment_df["scenario_name"] == reference_name,
        [
            "product_type",
            "score_band",
            "applications",
            "segment_total_expected_loss",
        ],
    ].rename(
        columns={
            "applications": "reference_applications",
            "segment_total_expected_loss": "reference_segment_total_expected_loss",
        }
    )

    merged = pd.merge(
        scenario_slice,
        reference_slice,
        on=["product_type", "score_band"],
        how="outer",
    )

    merged["scenario_applications"] = merged["scenario_applications"].fillna(0)
    merged["reference_applications"] = merged["reference_applications"].fillna(0)

    merged["scenario_segment_total_expected_loss"] = (
        merged["scenario_segment_total_expected_loss"].fillna(0.0)
    )

    merged["reference_segment_total_expected_loss"] = (
        merged["reference_segment_total_expected_loss"].fillna(0.0)
    )

    merged["delta_segment_total_expected_loss"] = (
        merged["scenario_segment_total_expected_loss"]
        - merged["reference_segment_total_expected_loss"]
    )

    for _, segment_row in merged.iterrows():
        delta_records.append(
            {
                "row_order": row_order,
                "family": scenario_config["family"],
                "family_label": scenario_config["family_label"],
                "scenario_name": scenario_name,
                "display_label": scenario_config["display_label"],
                "reference_scenario_name": reference_name,
                "product_type": segment_row["product_type"],
                "score_band": segment_row["score_band"],
                "scenario_applications": segment_row["scenario_applications"],
                "reference_applications": segment_row["reference_applications"],
                "scenario_segment_total_expected_loss": segment_row[
                    "scenario_segment_total_expected_loss"
                ],
                "reference_segment_total_expected_loss": segment_row[
                    "reference_segment_total_expected_loss"
                ],
                "delta_segment_total_expected_loss": segment_row[
                    "delta_segment_total_expected_loss"
                ],
            }
        )

delta_df = pd.DataFrame(delta_records)

delta_df["delta_segment_total_expected_loss_m"] = (
    delta_df["delta_segment_total_expected_loss"] / 1_000_000.0
)

# Product-level contribution matrix.
product_contrib = (
    delta_df.groupby(
        ["row_order", "family", "family_label", "scenario_name", "display_label", "product_type"],
        as_index=False,
    )
    .agg(
        delta_product_total_expected_loss=("delta_segment_total_expected_loss", "sum")
    )
)

product_contrib["delta_product_total_expected_loss_m"] = (
    product_contrib["delta_product_total_expected_loss"] / 1_000_000.0
)

scenario_totals = (
    product_contrib.groupby(
        ["row_order", "family", "family_label", "scenario_name", "display_label"],
        as_index=False,
    )
    .agg(
        delta_scenario_total_expected_loss=("delta_product_total_expected_loss", "sum")
    )
)

scenario_totals["delta_scenario_total_expected_loss_m"] = (
    scenario_totals["delta_scenario_total_expected_loss"] / 1_000_000.0
)

# Ensure product contribution matrix contains every selected product for every selected scenario.
scenario_rows = scenario_totals[
    ["row_order", "family", "family_label", "scenario_name", "display_label"]
].drop_duplicates()

complete_index = pd.MultiIndex.from_product(
    [
        scenario_rows["row_order"].tolist(),
        PRODUCT_ORDER,
    ],
    names=["row_order", "product_type"],
).to_frame(index=False)

complete_index = complete_index.merge(
    scenario_rows,
    on="row_order",
    how="left",
)

plot_product = complete_index.merge(
    product_contrib[
        [
            "row_order",
            "product_type",
            "delta_product_total_expected_loss_m",
        ]
    ],
    on=["row_order", "product_type"],
    how="left",
)

plot_product["delta_product_total_expected_loss_m"] = (
    plot_product["delta_product_total_expected_loss_m"].fillna(0.0)
)

plot_product = plot_product.sort_values(["row_order"]).reset_index(drop=True)

# Top product × score drivers by absolute movement.
top_segments = (
    delta_df.assign(
        abs_delta_segment_total_expected_loss=lambda x: x[
            "delta_segment_total_expected_loss"
        ].abs()
    )
    .sort_values("abs_delta_segment_total_expected_loss", ascending=False)
    .head(TOP_DRIVER_COUNT)
    .copy()
)

# Group ranges for family labels.
group_ranges = []
for family, group in scenario_totals.groupby("family", sort=False):
    start = int(group["row_order"].min())
    end = int(group["row_order"].max())

    family_label = group["family_label"].iloc[0]

    group_ranges.append(
        {
            "family": family,
            "family_label": family_label,
            "start": start,
            "end": end,
            "center": (start + end) / 2.0,
        }
    )


# =============================================================================
# 7. BUILD CHART
# =============================================================================

fig = plt.figure(figsize=(16.0, 8.8), dpi=160)
fig.patch.set_facecolor(FIG_FACE)

# Manual layout:
#   ax = diverging stacked horizontal contribution chart
#   right-side figure text = legend + interpretation + top product × score drivers
#
# No bbox_inches="tight" is used during export so title / footer centering
# remains visually stable.
ax = fig.add_axes([0.155, 0.170, 0.595, 0.655])
style_dark_axis(ax)

y_positions = list(range(len(scenario_totals)))

# Positive and negative stacks need separate cumulative bases.
positive_base = pd.Series([0.0] * len(scenario_totals), index=scenario_totals["row_order"])
negative_base = pd.Series([0.0] * len(scenario_totals), index=scenario_totals["row_order"])

bar_handles = {}

for product_type in PRODUCT_ORDER:
    product_rows = plot_product.loc[plot_product["product_type"] == product_type].copy()
    product_rows = product_rows.sort_values("row_order")

    color = PRODUCT_COLORS.get(product_type, "#999999")
    label = PRODUCT_LEGEND_LABELS.get(product_type, prettify_product(product_type))

    for _, row in product_rows.iterrows():
        y = int(row["row_order"])
        value = float(row["delta_product_total_expected_loss_m"])

        if abs(value) < 1e-9:
            continue

        if value >= 0:
            left = positive_base.loc[y]
            positive_base.loc[y] += value
        else:
            left = negative_base.loc[y]
            negative_base.loc[y] += value

        bar = ax.barh(
            y,
            value,
            left=left,
            height=0.62,
            color=color,
            alpha=BAR_ALPHA,
            label=label if product_type not in bar_handles else None,
        )

        if product_type not in bar_handles:
            bar_handles[product_type] = bar[0]

        # Keep inside labels compact: the legend identifies product colors.
        if abs(value) >= SEGMENT_LABEL_THRESHOLD_M:
            ax.text(
                left + value / 2.0,
                y,
                format_m_compact(value),
                ha="center",
                va="center",
                fontsize=7.5,
                color=text_color_for_hex(color),
                fontweight="bold",
            )

# Scenario total labels at left/right bar ends.
scenario_totals = scenario_totals.sort_values("row_order").reset_index(drop=True)

x_positive_max = max(positive_base.max(), 0.0)
x_negative_min = min(negative_base.min(), 0.0)

x_span = max(abs(x_positive_max), abs(x_negative_min), 1.0)

for _, row in scenario_totals.iterrows():
    y = int(row["row_order"])
    total_m = float(row["delta_scenario_total_expected_loss_m"])

    if total_m >= 0:
        x_text = positive_base.loc[y] + x_span * 0.025
        ha = "left"
    else:
        x_text = negative_base.loc[y] - x_span * 0.025
        ha = "right"

    ax.text(
        x_text,
        y,
        format_m(total_m),
        ha=ha,
        va="center",
        fontsize=8.7,
        color=TEXT_COLOR,
        fontweight="bold",
    )

# Axes and labels.
ax.axvline(
    0,
    color=ZERO_LINE_COLOR,
    linewidth=1.1,
    alpha=0.85,
)

ax.set_yticks(y_positions)
ax.set_yticklabels(
    scenario_totals["display_label"].tolist(),
    color=TEXT_COLOR,
    fontsize=9.0,
)

ax.invert_yaxis()

# Family group separators and labels.
for group in group_ranges:
    if group["start"] > 0:
        ax.axhline(
            group["start"] - 0.5,
            color=TEXT_COLOR,
            linewidth=1.0,
            alpha=0.55,
        )

    # Family labels are placed between the y-axis label and the scenario row labels.
    ax.text(
        -0.145,
        group["center"],
        group["family_label"],
        transform=ax.get_yaxis_transform(),
        ha="center",
        va="center",
        fontsize=8.5,
        color=TEXT_COLOR,
        fontweight="bold",
        clip_on=False,
    )

ax.set_xlabel(
    "Δ Total Expected Loss ($M)",
    color=TEXT_COLOR,
    fontsize=10.5,
    labelpad=10,
)

ax.set_ylabel(
    "Scenario Family / Selected Scenario Lever",
    color=TEXT_COLOR,
    fontsize=10.2,
    labelpad=72,
)

# Symmetric x-axis limits for mixed-sign comparison.
max_abs = max(abs(x_positive_max), abs(x_negative_min), 1.0)
ax.set_xlim(-max_abs * 1.20, max_abs * 1.20)

ax.xaxis.set_major_formatter(
    mtick.FuncFormatter(lambda value, _: f"${value:,.0f}M")
)

# Direction note inside chart.
ax.text(
    0.50,
    1.015,
    "Left of zero = lower EL vs reference     |     Right of zero = higher EL vs reference",
    transform=ax.transAxes,
    ha="center",
    va="bottom",
    fontsize=8.4,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.30",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Product legend outside chart.
handles = [bar_handles[p] for p in PRODUCT_ORDER if p in bar_handles]
labels = [PRODUCT_LEGEND_LABELS[p] for p in PRODUCT_ORDER if p in bar_handles]

legend = fig.legend(
    handles,
    labels,
    loc="upper left",
    bbox_to_anchor=(0.785, 0.825),
    fontsize=7.8,
    frameon=True,
    title="Product contribution",
    title_fontsize=8.4,
    ncol=1,
    borderpad=0.55,
    labelspacing=0.35,
    handlelength=1.2,
)

legend.get_frame().set_facecolor(AX_FACE)
legend.get_frame().set_edgecolor(TEXT_COLOR)
for text in legend.get_texts():
    text.set_color(TEXT_COLOR)
legend.get_title().set_color(TEXT_COLOR)

# Titles.
fig.suptitle(
    "Scenario Expected-Loss Impact Decomposition",
    fontsize=20,
    fontweight="bold",
    color=TEXT_COLOR,
    x=CONTENT_CENTER_X,
    y=0.970,
)

fig.text(
    CONTENT_CENTER_X,
    0.925,
    "Product Contribution to Portfolio EL Movement",
    ha="center",
    va="center",
    fontsize=12.0,
    color=TEXT_COLOR,
)

fig.text(
    CONTENT_CENTER_X,
    0.888,
    "Selected scenario levers vs family reference | stacked by product contribution",
    ha="center",
    va="center",
    fontsize=9.5,
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.35",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Right-side interpretation box.
readout_text = (
    "How to read:\n\n"
    "Each row compares a\n"
    "scenario to its own\n"
    "family reference.\n\n"
    "Bars show Δ Total EL.\n\n"
    "Left = lower EL\n"
    "Right = higher EL\n\n"
    "Stack color = product\n"
    "contribution.\n\n"
    "Inside labels show only\n"
    "material dollar moves."
)

fig.text(
    0.785,
    0.555,
    readout_text,
    fontsize=8.25,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.55",
        "facecolor": CALLOUT_BOX_COLOR,
        "edgecolor": CALLOUT_BOX_COLOR,
        "alpha": 0.88,
    },
)

# Top product × score movements.
top_driver_lines = []
for idx, (_, row) in enumerate(top_segments.iterrows(), start=1):
    scenario_display = scenario_totals.loc[
        scenario_totals["scenario_name"] == row["scenario_name"],
        "display_label",
    ]

    if not scenario_display.empty:
        scenario_label = scenario_display.iloc[0].replace("\n", " ")
    else:
        scenario_label = prettify_scenario_name(row["scenario_name"])

    product_label = prettify_product(row["product_type"])
    score_label = prettify_score(row["score_band"])
    delta_m = row["delta_segment_total_expected_loss"] / 1_000_000.0

    top_driver_lines.append(
        f"{idx}. {scenario_label}\n"
        f"   {product_label} × {score_label}: {format_m(delta_m)}"
    )

top_driver_text = (
    "Largest product × score\n"
    "movements:\n\n"
    + "\n\n".join(top_driver_lines)
)

fig.text(
    0.785,
    0.205,
    top_driver_text,
    fontsize=7.65,
    va="center",
    ha="left",
    color=TEXT_COLOR,
    bbox={
        "boxstyle": "round,pad=0.50",
        "facecolor": AX_FACE,
        "edgecolor": TEXT_COLOR,
        "alpha": 0.82,
    },
)

# Footer caption.
caption = (
    "Scenario Expected-Loss Impact Decomposition compares selected scenario levers to their family "
    "reference slices. Bars show total Expected Loss movement, stacked by product contribution, while "
    "the callout identifies the largest product × score drivers. This shows that Module 1 can explain "
    "where scenario risk movement concentrates rather than only reporting aggregate portfolio deltas."
)

fig.text(
    CONTENT_CENTER_X,
    0.045,
    "\n".join(textwrap.wrap(caption, width=165)),
    ha="center",
    va="center",
    fontsize=9.0,
    color=TEXT_COLOR,
)


# =============================================================================
# 8. SAVE OUTPUTS
# =============================================================================

fig.savefig(
    OUTPUT_PNG,
    facecolor=fig.get_facecolor(),
)

fig.savefig(
    OUTPUT_SVG,
    facecolor=fig.get_facecolor(),
)

plt.close(fig)


# =============================================================================
# 9. CONSOLE QA / TRACE OUTPUT
# =============================================================================

print(f"Input CSV: {input_csv}")
print(f"Saved PNG: {OUTPUT_PNG}")
print(f"Saved SVG: {OUTPUT_SVG}")

print("\nScenario totals used:")
for _, row in scenario_totals.iterrows():
    print(
        f"{row['family']:<18} | "
        f"{row['scenario_name']:<38} | "
        f"Δ Total EL: {format_m(row['delta_scenario_total_expected_loss_m'])}"
    )

print("\nProduct contribution by scenario:")
for _, row in product_contrib.sort_values(["row_order", "product_type"]).iterrows():
    print(
        f"{row['scenario_name']:<38} | "
        f"{row['product_type']:<26} | "
        f"Δ Product Total EL: {format_m(row['delta_product_total_expected_loss_m'])}"
    )

print("\nTop product × score movements:")
for idx, (_, row) in enumerate(top_segments.iterrows(), start=1):
    print(
        f"{idx}. "
        f"{row['scenario_name']:<38} | "
        f"{row['product_type']:<26} | "
        f"{row['score_band']:<14} | "
        f"Scenario apps: {format_count(row['scenario_applications'])} | "
        f"Reference apps: {format_count(row['reference_applications'])} | "
        f"Δ Segment Total EL: {format_m(row['delta_segment_total_expected_loss'] / 1_000_000.0)}"
    )
```
<!-- END_MESSAGE C040-M02535 -->


---

<a id="c040-m02537"></a>

### C040-M02537

**Andrew** · 2026-05-27T13:46:42.443000-04:00 · active path

<!-- BEGIN_MESSAGE C040-M02537 -->
do not generate image. provide updated python code (full copy paste). much better. for all numbers within the product boxes, let's stick to black text.  For example, in the credit stress row, +$44M, +$14M, +$16M, +$11M, and +$14M within each product box should all be in black text. and the +$99.1M total should remain in white text. no other changes
<!-- END_MESSAGE C040-M02537 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_09.md) · [Next](Part_11.md)
