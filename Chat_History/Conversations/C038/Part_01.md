# Module 2 Decision Simulator Build

## Part 01

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Next](Part_02.md)

<a id="c038-m00001"></a>

### C038-M00001

**Andrew** · 2026-05-06T09:07:28.399000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00001 -->
Before proposing Module 2 architecture, read the attached Module 1 SQL, BRD, and Validation Summary sufficiently to understand the finalized Module 1 design.

Treat Module 1 outputs, terminology, and boundaries as authoritative.

Do not redesign Module 1 unless explicitly instructed.

Do not reinterpret estimated_pd as a calibrated PD model. In commentary and documentation, estimated_pd should be interpreted as the synthetic estimated-PD proxy.

Naming discipline:
The SQL field name may remain estimated_pd because that is the finalized Module 1 output column.
However, commentary, documentation, and interpretation should refer to it as the synthetic estimated-PD proxy.

Do not treat Module 1 scenario outputs as forecasts.

================================================================================
PROJECT CONTEXT
================================================================================

Project Name:
Enterprise Credit Decisioning Strategy Simulator

Completed Module:
Module 1 — Synthetic Application & Risk Modeling Engine V2.0

Module 1 Status:
FINALIZED, VALIDATED, AND DOCUMENTED.

Attached Module 1 V2.0 artifacts:
1. SQL implementation
2. Business Requirements Document (BRD)
3. Validation Summary

These artifacts are authoritative.

You are assisting me in designing and building the next module of an elite portfolio-grade credit analytics project.

This is NOT a generic SQL exercise. This is a continuation of a governed, audit-ready, enterprise-style decisioning simulator. The quality bar is extremely high.

================================================================================
MODULE 1 SUMMARY
================================================================================

Module 1 produces a governed synthetic application population and risk modeling layer.

It generates:
- synthetic applications
- product type
- score band
- borrower profile variables
- requested amount
- APR proxy
- monthly payment proxy
- payment-to-income ratio (PTI)
- amount-to-income ratio
- estimated-PD proxy
- LGD
- Expected Loss
- scenario archive outputs
- matched scenario comparison outputs

Module 1 is deterministic:
- same population_id + same parameters = same synthetic population
- this enables apples-to-apples scenario comparison

Module 1 is NOT:
- a production underwriting model
- a pricing engine
- a real-customer decision system
- a calibrated PD model
- a credit card billing engine
- a macroeconomic forecasting system
- a fair lending or compliance adjudication framework

Module 1 IS:
- a strategy simulation foundation
- an explainable synthetic risk framework
- a governed pre-production decisioning sandbox
- a portfolio-grade teaching and architecture artifact

================================================================================
MODULE 1 V2.0 WORKSTREAMS COMPLETED
================================================================================

Workstream A — Mortgage Realism:
- Added mortgage A2 amount-to-income tail smoothing
- Added mortgage A3 provisional PTI-aware overlay
- Controlled upper-tail mortgage exposure without collapsing valid high-capacity borrower behavior

Workstream B — Estimated-PD Proxy Dispersion:
- Added soft saturation before the hard estimated-PD proxy cap
- Iterated through B1, B2, and B3
- Reduced cap crowding while preserving monotonic score-band ordering and product-risk coherence

Workstream C — Scenario Comparison Framework:
- Added scenario_set_name and scenario_name
- Added scenario archive persistence
- Added portfolio-level, product × score, and matched row-level scenario comparison
- Validated 50,000-row matched baseline vs rate-stress comparison

Workstream D — Revolving Payment Sensitivity:
- Replaced static revolving payment proxy with APR-sensitive blended proxy
- Restored the transmission chain:
  APR → payment → PTI → estimated-PD proxy → Expected Loss
- Preserved the boundary that this is not a credit-card billing engine

================================================================================
MODULE 2 OBJECTIVE
================================================================================

We are now beginning Module 2.

Working title:
Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine

The purpose of Module 2 is to consume Module 1 outputs and simulate credit strategy outcomes.

Module 2 should answer:
- Given the synthetic applicant and risk profile from Module 1, what strategy outcome would this applicant trigger?
- Would the synthetic applicant be approved, declined, sent to manual review, or receive a simulated counteroffer / partial approval path?
- What simulated policy reason codes explain the outcome?
- What approved amount, counteroffer amount, or exposure treatment would be assigned?
- How do strategy changes affect approval rate, manual review rate, decline rate, counteroffer rate, estimated risk, and Expected Loss?
- Which products, score bands, PTI bands, and affordability segments drive strategy differences?

================================================================================
MODULE 2 CORE DESIGN THESIS
================================================================================

Module 2 should demonstrate that credit strategy outcomes are not determined by one variable alone.

Strategy outcomes should emerge from the interaction of:
- product type
- requested amount
- approved amount / exposure treatment
- score band
- borrower risk signals
- affordability stress
- estimated-PD proxy
- LGD
- Expected Loss
- product-specific policy rules
- strategy configuration
- upstream Module 1 scenario configuration

Module 2 should preserve the Module 1 thesis:

Credit outcomes are shaped by borrower profile, product structure, affordability, risk translation, and governed strategy rules.

Module 2 adds the next layer:

Given a synthetic applicant profile and estimated-risk framework, what simulated strategy outcome is triggered, and why?

================================================================================
MODULE 2 INTERPRETATION BOUNDARY
================================================================================

Module 2 may use terms such as approve, decline, manual review, counteroffer, approved amount, and reason code.

However, these terms must always be interpreted as SIMULATED STRATEGY OUTCOMES on synthetic applicants.

They are NOT:
- production credit decisions
- adverse action notices
- compliance-approved reason codes
- real customer treatment logic
- fair lending conclusions
- regulatory model outputs
- production underwriting policy
- pricing or profitability optimization
- calibrated default forecasts

Correct interpretation:
"Under this simulated strategy, this synthetic applicant would receive this strategy outcome."

Incorrect interpretation:
"This real customer should be approved, declined, priced, or treated this way."

Module 2 should preserve the same boundary discipline as Module 1:
strategy simulation first, production decisioning never.

Preferred language:
- “strategy outcome”
- “synthetic applicant”
- “policy simulation”
- “decision outcome proxy”
- “manual review trigger”
- “decline reason simulation”
- “approved amount proxy”
- “counteroffer simulation”
- “simulated strategy rule”
- “approved-book profile”
- “declined-book profile”

Avoid language like:
- “this customer is declined”
- “production approval decision”
- “final underwriting decision”
- “regulatory compliant decision model”
- “adverse action reason”
- “approved production policy”

Module 2 may expose segments for strategy QA, but it must not draw fair lending, disparate impact, or compliance conclusions.

================================================================================
MODULE 1 SCENARIO VS MODULE 2 STRATEGY NAMING DISCIPLINE
================================================================================

Module 2 must distinguish between upstream Module 1 scenarios and downstream Module 2 strategies.

Module 1 scenario fields describe the synthetic population and upstream risk environment:
- scenario_set_name
- scenario_name
- population_id

Module 2 strategy fields should describe the decision strategy applied to that population:
- strategy_set_name
- strategy_name
- strategy_version

Do not overload scenario_name to mean both upstream Module 1 macro/rate scenario and downstream Module 2 decision strategy.

Recommended architecture:
- preserve Module 1 scenario fields as input lineage
- add Module 2 strategy fields for decision strategy comparison

Recommended naming approach:
- module1_scenario_set_name
- module1_scenario_name
- population_id
- strategy_set_name
- strategy_name
- strategy_version

================================================================================
HOW MODULE 2 SHOULD RELATE TO MODULE 1
================================================================================

Module 2 should consume Module 1 outputs.

Module 2 should not rewrite Module 1.

Likely input source:
credit_decisioning_sim.synthetic_applications
or
credit_decisioning_sim.synthetic_applications_scenario_archive

Input source guidance:

For single-strategy development and QA:
- use credit_decisioning_sim.synthetic_applications

For strategy comparison across Module 1 baseline / stress scenarios:
- prefer credit_decisioning_sim.synthetic_applications_scenario_archive

For strategy comparison across alternative Module 2 strategies:
- preserve the same population_id
- preserve Module 1 scenario lineage
- add Module 2 strategy identifiers

Module 2 must preserve:
- Module 1 scenario lineage
- population_id
- application_id
- applicant_id
- product_type
- score_band
- requested_amount
- estimated_pd
- estimated_lgd
- expected_loss_amount

This ensures that strategy outcomes can be traced back to the exact synthetic population and Module 1 scenario assumptions.

If Module 2 appears to require a field not currently available from Module 1, do not assume a Module 1 change.

First identify the missing field, explain why it is needed, and recommend whether it belongs in:
- Module 1 as a future enhancement
- Module 2 as a derived field
- or documentation only

================================================================================
EXPECTED MODULE 2 SCOPE
================================================================================

Module 2 should likely include:

1. Strategy parameter framework
   - strategy_set_name
   - strategy_name
   - strategy_version
   - source Module 1 scenario fields
   - approval thresholds
   - decline thresholds
   - manual review thresholds
   - counteroffer thresholds
   - product-specific rules
   - risk tolerance settings
   - affordability tolerance settings
   - exposure assignment rules
   - archive controls

2. Decision outcome logic
   - APPROVE
   - DECLINE
   - MANUAL_REVIEW
   - COUNTEROFFER / PARTIAL_APPROVAL treatment, either as a separate outcome or as a decision path

3. Rule hierarchy
   - hard decline checks
   - bankruptcy / major derogatory rules
   - score-band policy rules
   - risk-based decline checks
   - affordability-based decline or review checks
   - exposure limit checks
   - counteroffer / partial approval checks
   - product-specific overrides
   - approval logic

4. Reason code logic
   - primary reason code
   - secondary reason code
   - tertiary reason code
   - reason code family
   - reason priority hierarchy
   - stackable vs mutually exclusive reason logic

5. Approved exposure / counteroffer logic
   - requested_amount from Module 1 remains the input request
   - Module 2 may assign:
     - approved_amount
     - counteroffer_amount
     - exposure_reduction_flag
     - exposure_reduction_amount
     - exposure_reduction_pct
     - line_assignment_tier

6. Approved Expected Loss logic
   - Module 1 expected_loss_amount should remain available as requested-exposure Expected Loss
   - Module 2 should calculate approved_expected_loss_amount using approved exposure
   - Conceptual formula:
     approved_expected_loss_amount = approved_amount × estimated-PD proxy × LGD
   - This distinction is important because requested exposure and approved exposure may differ

7. Strategy comparison framework
   - compare baseline strategy vs tighter strategy
   - compare baseline strategy vs growth-oriented strategy
   - compare baseline strategy vs product-specific strategy
   - compare approval rates
   - compare manual review rates
   - compare decline rates
   - compare counteroffer rates
   - compare approved-book estimated-PD proxy
   - compare approved-book Expected Loss
   - compare approved amount distribution
   - compare outcomes by product, score band, and PTI bucket

8. Validation / QA framework
   - decision distribution
   - approval rate by score band
   - approval rate by product
   - manual review rate by risk tier
   - decline reason distribution
   - counteroffer reason distribution
   - approved vs declined estimated-PD proxy comparison
   - approved vs declined PTI comparison
   - approved-book vs declined-book profile
   - product × score strategy matrix
   - edge-case review
   - matched strategy comparison

================================================================================
MODULE 2 DECISION OUTCOME TAXONOMY
================================================================================

Module 2 should define a clear simulated decision outcome taxonomy.

At minimum, consider:

1. APPROVE
   Applicant passes simulated policy and affordability requirements.

2. DECLINE
   Applicant fails one or more simulated hard policy rules.

3. MANUAL_REVIEW
   Applicant falls into an intermediate or exception zone requiring simulated review.

4. COUNTEROFFER / PARTIAL_APPROVAL
   Applicant is not approved as requested, but a lower approved amount or alternative exposure treatment is assigned.

The architecture should recommend whether COUNTEROFFER is:
- a separate decision_outcome, or
- a decision_path under APPROVE / MANUAL_REVIEW

Please explicitly recommend one approach and explain why.

================================================================================
REASON CODE GOVERNANCE
================================================================================

Module 2 should include a simulated reason-code framework.

Reason codes should explain strategy outcomes in a transparent and auditable way.

However, reason codes are NOT regulatory adverse-action reason codes.

They are simulated strategy explanation codes used for:
- strategy transparency
- QA review
- segmentation analysis
- decision-path traceability
- portfolio interpretation

Reason code design should include:
- primary reason code
- secondary reason code
- tertiary reason code
- reason code family
- reason priority hierarchy
- mutually exclusive vs stackable reason logic
- product-specific reason applicability
- manual-review reason logic
- counteroffer reason logic

Examples may include:
- LOW_SCORE_BAND
- HIGH_PTI
- HIGH_DTI
- HIGH_ESTIMATED_PD_PROXY
- HIGH_EXPECTED_LOSS
- HIGH_UTILIZATION
- RECENT_DELINQUENCY
- MAJOR_DEROGATORY
- BANKRUPTCY_FLAG
- REQUESTED_AMOUNT_EXCEEDS_POLICY_LIMIT
- PRODUCT_POLICY_LIMIT
- COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
- MANUAL_REVIEW_MIXED_SIGNAL_PROFILE
- BORDERLINE_APPROVAL_PROFILE
- PRODUCT_SPECIFIC_EXPOSURE_LIMIT
- APPROVED_WITH_CONSTRAINTS

The assistant should propose a reason-code taxonomy and priority hierarchy before coding.

================================================================================
MODULE 2 STRATEGY COMPARISON REQUIREMENTS
================================================================================

Module 2 should support comparison of alternative strategy configurations.

Examples:
- baseline strategy vs tighter affordability strategy
- baseline strategy vs tighter risk strategy
- baseline strategy vs growth-oriented approval strategy
- baseline strategy vs product-specific exposure strategy

Strategy comparison should evaluate:
- approval rate
- decline rate
- manual review rate
- counteroffer rate
- approved amount distribution
- approved-book requested amount
- approved-book approved amount
- approved-book estimated-PD proxy
- approved-book LGD
- approved-book Expected Loss
- declined-book estimated-PD proxy
- declined-book PTI
- manual-review-book estimated-PD proxy
- manual-review-book PTI
- reason-code distribution
- product-level decision outcomes
- score-band decision outcomes
- PTI-bucket decision outcomes
- product × score-band strategy outcomes
- matched applicant-level strategy deltas

The design should support matched comparison whenever the same Module 1 population_id is used.

================================================================================
MODULE 2 VALIDATION EXPECTATIONS
================================================================================

Module 2 validation should prove that simulated strategy logic behaves as intended.

Validation should include:

1. Structural validation
   - row count preserved from Module 1 input
   - no unintended applicant loss
   - all decisions assigned
   - all flags internally consistent
   - strategy parameters valid
   - archive outputs traceable

2. Decision distribution validation
   - approval / decline / manual review / counteroffer rates
   - decision distribution by product
   - decision distribution by score band
   - decision distribution by PTI bucket
   - decision distribution by risk tier

3. Risk ordering validation
   - approved population should generally show lower estimated-PD proxy than declined population
   - manual review population should show mixed or intermediate risk
   - decline population should show higher policy-rule failure concentration
   - counteroffer population should show elevated exposure or affordability pressure relative to clean approvals

4. Affordability validation
   - higher PTI should generally reduce approval likelihood or increase review / counteroffer likelihood
   - affordability reason codes should concentrate in high-PTI segments
   - counteroffer cases should show improved approved PTI or approved exposure profile when applicable

5. Reason-code validation
   - reason codes should be populated
   - primary reason code should align to the first or most material failed rule
   - reason-code distribution should be interpretable
   - no unexplained null reason codes for declines or manual reviews
   - clean approvals may have a standard approval reason or null decline reasons by design

6. Approved exposure validation
   - approved amount should not exceed requested amount unless explicitly designed
   - counteroffer amount should be lower than requested amount
   - approved Expected Loss should use approved exposure, not requested exposure
   - exposure reduction should be positive for counteroffer / partial approval cases

7. Strategy comparison validation
   - tighter strategies should reduce approval rates or approved exposure
   - growth strategies should increase approvals or exposure, but with measurable risk tradeoffs
   - matched strategy comparison should isolate strategy effects from population changes

8. Edge-case validation
   - strong-credit/high-PTI cases
   - weak-credit/low-PTI cases
   - high-risk/low-requested-amount cases
   - large-exposure/low-risk cases
   - manual-review borderline cases
   - counteroffer borderline cases

================================================================================
MODULE 2 PARAMETER GATEKEEPER EXPECTATIONS
================================================================================

Module 2 should include fail-fast validation gatekeepers similar to Module 1.

Gatekeepers should validate, at minimum:
- exactly one active strategy parameter row when running a single strategy
- non-null strategy_set_name
- non-null strategy_name
- non-null strategy_version
- valid source Module 1 scenario identifiers where applicable
- threshold ordering is coherent
- approval thresholds are not stricter than decline thresholds unless explicitly designed
- PTI thresholds are within governed ranges
- estimated-PD proxy thresholds are within 0 to 1
- LGD thresholds are within 0 to 1 where used
- approved amount rules do not create negative exposure
- counteroffer rules do not produce approved_amount greater than requested_amount
- archive reset mode is valid if archive persistence is used

Gatekeepers should prevent invalid strategy configuration before decision outcomes are generated.

================================================================================
DESIGN PRINCIPLES TO PRESERVE
================================================================================

Module 2 must preserve the same design principles as Module 1:

1. Parameterized over hard-coded
2. Explainable over opaque
3. Deterministic over non-reproducible
4. Product-aware over generic
5. Scenario-comparable over isolated
6. Governed over ad hoc
7. Modular over monolithic
8. Teaching-oriented and audit-ready
9. Boundary-aware over production-claiming
10. Validation-first over output-only

================================================================================
SQL STYLE REQUIREMENTS
================================================================================

When we begin coding, the SQL must match the elite commentary level established in Module 1.

Requirements:
- PostgreSQL
- highly structured sections
- clear headers and subheaders
- extensive teaching comments
- every hardcoded threshold must be explained
- every CASE block should explain business logic and SQL logic
- every output field should be interpretable
- validation gates should fail fast
- audit fields should preserve decision paths
- no unexplained magic numbers
- no opaque strategy rules
- no silent assumptions
- compact SQL names are acceptable, but interpretation boundaries must be documented

When suggesting changes:
- provide exact BEFORE / AFTER blocks
- preserve existing valuable comments
- do not simplify commentary unless asked
- do not skip governance logic
- do not give vague recommendations

================================================================================
DOCUMENTATION STYLE REQUIREMENTS
================================================================================

Eventually, Module 2 should have its own:
1. BRD
2. Validation Summary

Both should match the Module 1 V2.0 artifact quality:
- board-ready
- audit-ready
- blue-theme professional style
- executive-readable
- technically precise
- evidence-driven
- explicit boundaries
- validation proof
- traceability

But we should design the architecture and code first.

Do not draft the Module 2 BRD or Validation Summary yet.

First, help design and validate the Module 2 architecture and SQL implementation.
Documentation will be produced later after the design and validation evidence are established.

================================================================================
MODULE 2 OUTPUT CONSISTENCY REQUIREMENTS
================================================================================

Module 2 should enforce clear consistency between decision outcomes, decision paths,
flags, approved amount, and approved Expected Loss.

At minimum, the architecture should define:

1. Decision outcome consistency
   - exactly one primary decision_outcome should be assigned per application per strategy run
   - decision_outcome should be one of the approved taxonomy values
   - flags such as approval_flag, decline_flag, manual_review_flag, and counteroffer_flag
     must reconcile back to decision_outcome and decision_path

2. Approved amount consistency
   - APPROVE outcomes should generally have approved_amount > 0
   - DECLINE outcomes should generally have approved_amount = 0 unless explicitly designed otherwise
   - COUNTEROFFER / PARTIAL_APPROVAL outcomes should have approved_amount < requested_amount
   - MANUAL_REVIEW outcomes should have a clearly documented approved_amount treatment:
       a. approved_amount = null pending review, or
       b. approved_amount = proposed amount pending review
     The architecture should recommend one approach and explain why.

3. Approved Expected Loss consistency
   - Module 1 expected_loss_amount should remain available as requested-exposure Expected Loss
   - Module 2 approved_expected_loss_amount should be calculated from approved exposure
   - Conceptual formula:
       approved_expected_loss_amount = approved_amount × estimated-PD proxy × LGD
   - declined or unresolved records should have a clearly documented approved_expected_loss_amount convention

4. Archive grain consistency
   - latest-run table should contain the current strategy output for the selected Module 1 input population / scenario
   - strategy archive table should preserve one row per application per Module 1 scenario per Module 2 strategy
   - archive design should support matched comparison across strategies without losing Module 1 scenario lineage

================================================================================
PREFERRED MODULE 2 DEVELOPMENT APPROACH
================================================================================

Do not start coding immediately.

Start by designing Module 2 architecture.

First response should include:

1. Recommended Module 2 name
2. Strategic purpose
3. What Module 2 includes
4. What Module 2 excludes
5. Relationship to Module 1
6. Module 1 scenario vs Module 2 strategy naming recommendation
7. Recommended latest-run table and archive-table architecture
8. Proposed SQL section structure
9. Proposed strategy output table design
10. Proposed parameter framework
11. Proposed decision outcome taxonomy
12. Recommendation on counteroffer as outcome vs decision path
13. Proposed decision hierarchy
14. Proposed reason-code framework
15. Proposed approved exposure / approved Expected Loss framework
16. Proposed strategy comparison framework
17. Proposed validation framework
18. Recommended workstreams
19. Key design tradeoffs
20. Recommended first coding step
21. Text-based architecture flow diagram showing:
    Module 1 output → Module 2 strategy parameter layer → decision logic → reason codes → approved exposure → strategy archive → QA

Use clear recommendations. If there are options, rank them and recommend one.

Do not provide generic advice. I want a serious, enterprise-grade architecture proposal.

In the first response, explicitly address the following design decision:

Should Module 2 use:
A. one output row per application per strategy,
B. one output row per application per strategy per Module 1 scenario,
C. or a separate latest-run table plus strategy archive table?

Please recommend one architecture.

Preference:
Use a latest-run strategy decision table plus a strategy decision archive table, mirroring Module 1’s latest-output plus scenario-archive pattern.

================================================================================
FINAL GUARDRAILS BEFORE STARTING
================================================================================

Do not draft the Module 2 BRD or Validation Summary yet.
First, help design and validate the Module 2 architecture and SQL implementation.
Documentation will be produced later after the design and validation evidence are established.

Naming discipline:
The SQL field name may remain estimated_pd because that is the finalized Module 1 output column.
However, commentary, documentation, and interpretation should refer to it as the synthetic estimated-PD proxy.

Module 2 may expose segments for strategy QA, but it must not draw fair lending, disparate impact, or compliance conclusions.

If Module 2 appears to require a field not currently available from Module 1, do not assume a Module 1 change.
First identify the missing field, explain why it is needed, and recommend whether it belongs in:
- Module 1 as a future enhancement
- Module 2 as a derived field
- or documentation only

In the first response, include a text-based architecture flow diagram showing:
Module 1 output → Module 2 strategy parameter layer → decision logic → reason codes → approved exposure → strategy archive → QA.

================================================================================
QUALITY BAR
================================================================================

The expected level is:
- senior credit strategy analytics
- enterprise SQL architecture
- model governance awareness
- audit-ready documentation
- portfolio-grade explainability

This should look like something a Director / Principal-level analytics candidate could present in a portfolio, architecture walkthrough, or interview.

================================================================================
START NOW
================================================================================

Please propose the Module 2 architecture and workstream plan.

Do not write code yet.

Focus on designing the module correctly before implementation.

Critical design requirements to address:
- Distinguish Module 1 scenario metadata from Module 2 strategy metadata.
- Recommend whether Module 2 should have both a latest-run table and a strategy archive table.
- Define a decision outcome taxonomy before coding.
- Define whether counteroffer is a distinct decision outcome or a decision path.
- Define a simulated reason-code framework, while explicitly stating these are not regulatory adverse-action reason codes.
- Define how approved amount and approved Expected Loss should be calculated.
- Define approved-book, declined-book, manual-review-book, and counteroffer-book reporting.
- Define validation checks for decision distribution, risk ordering, affordability sensitivity, reason-code coverage, approved exposure, and matched strategy comparison.
- Preserve Module 1 boundaries: synthetic simulation only, no production underwriting, no calibrated PD, no pricing, no fair lending conclusions.
<!-- END_MESSAGE C038-M00001 -->


**Attachments in export:** `module1_synthetic_application_risk_engine_v2.0(21).sql`, `Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0(9).pdf`, `Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0(13).pdf`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00018"></a>

### C038-M00018

**ChatGPT** · 2026-05-06T09:14:43.706523-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00018 -->
## Executive recommendation

**Build Module 2 as: _Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine v1.0_.**

The recommended architecture is **Option C: a latest-run strategy decision table plus a strategy decision archive table**, with the archive grain defined as:

> **one row per application × Module 1 scenario × Module 2 strategy version**

This mirrors Module 1’s latest-output plus scenario-archive pattern while extending it cleanly into downstream strategy comparison. The latest table supports fast development, QA, and walkthroughs. The archive table supports governed matched comparison across alternative strategies and across upstream Module 1 scenarios.

Module 1 should remain frozen. Module 2 should consume its finalized outputs, preserve its scenario lineage, and add a strategy layer on top. Module 1’s SQL output already preserves scenario metadata, applicant identifiers, product and score variables, affordability metrics, the `estimated_pd` SQL column, LGD, and requested-exposure Expected Loss; the Module 1 BRD separately establishes scenario comparison around `scenario_set_name`, `scenario_name`, and `population_id`; and the validation summary confirms deterministic matched comparison as a validated Module 1 capability. fileciteturn1file13 fileciteturn2file2 fileciteturn0file1

---

# 1. Recommended Module 2 name

**Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine v1.0**

This name is strong because it clearly signals:

| Name Component | Why It Matters |
|---|---|
| **Credit Policy Strategy** | Establishes that this is a simulated policy layer, not a model rebuild. |
| **Decision Outcome** | Focuses on the strategy outcome: approve, decline, manual review, counteroffer. |
| **Simulation Engine** | Preserves the synthetic, pre-production boundary. |
| **v1.0** | Establishes this as the first governed release of the downstream strategy layer. |

The shorter working table-family name should be:

```text
credit_decisioning_sim.strategy_decisions
credit_decisioning_sim.strategy_decisions_archive
```

---

# 2. Strategic purpose

Module 2 should answer:

> **Under a governed simulated strategy, what strategy outcome would each synthetic applicant receive, why, and with what approved exposure treatment?**

It extends the Module 1 chain:

```text
Application → Product Structure → APR → Payment → PTI → synthetic estimated-PD proxy → Expected Loss
```

into the Module 2 chain:

```text
Synthetic Applicant Profile
→ Simulated Strategy Rules
→ Decision Outcome Proxy
→ Simulated Reason Codes
→ Approved Exposure Proxy
→ Approved Expected Loss
→ Strategy Comparison
```

The key strategic thesis should be:

> **Strategy outcomes are not determined by one variable alone. They emerge from the interaction of product type, score band, borrower risk signals, affordability stress, requested exposure, the synthetic estimated-PD proxy, LGD, Expected Loss, and product-specific simulated policy rules.**

---

# 3. What Module 2 includes

Module 2 should include the following governed components:

| Component | Purpose |
|---|---|
| **Strategy parameter framework** | Defines strategy metadata, thresholds, product-specific limits, exposure treatment, and archive behavior. |
| **Input lineage layer** | Pulls Module 1 latest or archived outputs and renames Module 1 scenario fields for clarity. |
| **Derived segmentation layer** | Builds Module 2 risk tier, affordability tier, PTI bucket, exposure tier, and policy bands. |
| **Decision rule layer** | Applies hard decline, manual review, counteroffer, and approval logic. |
| **Reason-code simulation layer** | Assigns transparent simulated reason codes with priority hierarchy. |
| **Approved exposure layer** | Calculates approved amount, counteroffer amount, exposure reduction, and line assignment tier. |
| **Approved Expected Loss layer** | Calculates approved-exposure Expected Loss separately from Module 1 requested-exposure Expected Loss. |
| **Latest output table** | Stores the current strategy run. |
| **Strategy archive table** | Preserves completed strategy runs for matched comparison. |
| **Validation and QA framework** | Confirms structural integrity, decision distributions, risk ordering, reason-code coverage, exposure consistency, and matched strategy deltas. |

---

# 4. What Module 2 excludes

Module 2 should explicitly exclude:

| Exclusion | Boundary |
|---|---|
| Production underwriting | No real customer decisions. |
| Regulatory adverse-action logic | Reason codes are simulated strategy explanation codes only. |
| Pricing optimization | APR remains a Module 1 burden-estimation proxy, not a price offer. |
| Calibrated default modeling | `estimated_pd` remains the SQL column name, but interpretation is the **synthetic estimated-PD proxy**. |
| Fair lending conclusions | Segments may support QA, but no disparate-impact or compliance conclusions should be drawn. |
| Real account booking | Approved amount is an approved exposure proxy, not actual booked exposure. |
| Macroeconomic forecasting | Module 1 scenarios are controlled sensitivity assumptions, not forecasts. |
| Collateral valuation policy | Module 1 does not produce LTV or collateral value; Module 2 should not invent them. |

This preserves the Module 1 BRD boundary that production underwriting, customer-level decisions, calibrated probability-of-default modeling, production pricing, regulatory validation, fair lending adjudication, and financial reporting are explicit non-uses. fileciteturn1file15

---

# 5. Relationship to Module 1

Module 2 should consume Module 1 outputs without rewriting Module 1.

## Recommended input sources

| Use Case | Recommended Source |
|---|---|
| Single-strategy development and QA | `credit_decisioning_sim.synthetic_applications` |
| Strategy comparison across Module 1 baseline / stress scenarios | `credit_decisioning_sim.synthetic_applications_scenario_archive` |
| Matched strategy comparison under the same Module 1 scenario | Either source is acceptable, but archive is preferred once strategy runs are persisted. |

## Required Module 1 fields to preserve

Module 2 should carry forward at minimum:

```text
model_version                      → module1_model_version
scenario_set_name                  → module1_scenario_set_name
scenario_name                      → module1_scenario_name
population_id
anchor_date
application_seq
application_id
applicant_id
application_date
product_type
score_band
credit_score
annual_income
debt_to_income_ratio
utilization_rate
tradeline_count
months_since_oldest_trade
recent_inquiry_count
delinquency_count_12m
major_derogatory_flag
bankruptcy_flag
requested_amount
loan_term_months
base_apr_for_payment_calc
monthly_payment_proxy
payment_to_income_ratio
amount_to_income_ratio
estimated_pd
estimated_lgd
expected_loss_amount
```

In Module 2 commentary, `estimated_pd` should always be described as the **synthetic estimated-PD proxy**, not a calibrated probability of default.

---

# 6. Module 1 scenario vs Module 2 strategy naming recommendation

Module 2 must not overload `scenario_name`.

Module 1 scenario fields describe the upstream synthetic population and risk environment. Module 2 strategy fields describe the downstream simulated decision strategy.

## Recommended naming

| Layer | Field | Meaning |
|---|---|---|
| Module 1 | `module1_scenario_set_name` | Upstream scenario family. |
| Module 1 | `module1_scenario_name` | Upstream scenario / assumption set. |
| Module 1 | `population_id` | Deterministic synthetic population anchor. |
| Module 2 | `strategy_set_name` | Downstream strategy comparison family. |
| Module 2 | `strategy_name` | Specific simulated decision strategy. |
| Module 2 | `strategy_version` | Versioned strategy configuration. |
| Module 2 | `strategy_run_id` | Optional deterministic or timestamped run identifier for traceability. |

This gives clean lineage such as:

```text
module1_scenario_set_name = MODULE1_V2_BASELINE_SET
module1_scenario_name     = BASELINE_V2
population_id             = BASE_POPULATION_V1

strategy_set_name         = MODULE2_BASELINE_POLICY_TESTS
strategy_name             = BASELINE_STRATEGY
strategy_version          = V1_0
```

---

# 7. Recommended latest-run and archive-table architecture

## Explicit decision: Option C is the correct architecture

| Option | Assessment | Recommendation |
|---|---|---|
| **A. One output row per application per strategy** | Insufficient because it can lose Module 1 scenario lineage or blur upstream scenario effects. | Do not use as the main architecture. |
| **B. One output row per application per strategy per Module 1 scenario** | Correct archive grain, but incomplete because it lacks a clean latest-run working table. | Use as the archive grain, not the whole architecture. |
| **C. Latest-run table plus strategy archive table** | Best balance of development usability, auditability, and matched comparison. Mirrors Module 1. | **Recommended.** |

## Recommended physical tables

### Latest-run table

```text
credit_decisioning_sim.strategy_decisions
```

Purpose:

```text
Current Module 2 strategy output for the selected Module 1 input and selected strategy.
```

Grain:

```text
one row per application for the current strategy run
```

Usage:

```text
single-run QA
development validation
portfolio walkthrough
debugging
```

### Archive table

```text
credit_decisioning_sim.strategy_decisions_archive
```

Purpose:

```text
Persistent strategy-decision archive for comparison across Module 2 strategies and Module 1 scenarios.
```

Recommended archive grain:

```text
one row per application
per module1_scenario_set_name
per module1_scenario_name
per population_id
per strategy_set_name
per strategy_name
per strategy_version
```

This archive grain supports:

```text
same Module 1 scenario + same population_id + different strategy_name
→ isolates downstream strategy effect

same Module 2 strategy + same population_id + different Module 1 scenario
→ isolates upstream scenario sensitivity

different Module 1 scenario + different Module 2 strategy
→ combined scenario / strategy effect, useful but less clean
```

---

# 8. Proposed SQL section structure

Module 2 SQL should follow a governed staged structure similar to Module 1.

| Section | Name | Purpose |
|---:|---|---|
| 0 | Executive purpose and boundary notes | Establish synthetic strategy simulation boundary. |
| 1 | Schema setup and latest-output reset | Prepare latest-run output safely. |
| 2 | Strategy parameter framework | Define one active strategy row and product policy matrix. |
| 3 | Strategy parameter gatekeeper | Fail fast on invalid metadata, thresholds, source selectors, and exposure rules. |
| 4 | Module 1 source selection | Load latest or archived Module 1 outputs and rename scenario fields. |
| 5 | Derived strategy segments | Build risk tier, PTI bucket, DTI bucket, affordability tier, and exposure tier. |
| 6 | Product-specific policy limits | Attach product caps, minimum amounts, counteroffer limits, and threshold overrides. |
| 7 | Rule flag construction | Calculate all hard decline, review, counteroffer, and approval trigger flags. |
| 8 | Decision hierarchy | Assign exactly one `decision_outcome` and one `decision_path`. |
| 9 | Simulated reason-code assignment | Assign primary, secondary, tertiary reason codes and reason family. |
| 10 | Approved exposure calculation | Calculate approved amount, counteroffer amount, exposure reduction, approved PTI proxy. |
| 11 | Approved Expected Loss calculation | Calculate approved-exposure Expected Loss. |
| 12 | Final latest-run table build | Create `strategy_decisions`. |
| 13 | Strategy archive persistence | Insert into `strategy_decisions_archive` under governed reset mode. |
| 14 | QA / validation queries | Validate row counts, flags, distributions, risk ordering, reasons, exposure. |
| 15 | Strategy comparison QA | Matched strategy deltas by portfolio, product, score band, PTI bucket, and row. |

---

# 9. Proposed strategy output table design

The latest and archive tables should expose both business-facing outputs and audit fields.

## Core output fields

| Field Group | Fields |
|---|---|
| Module 2 metadata | `module2_model_version`, `strategy_set_name`, `strategy_name`, `strategy_version`, `strategy_run_id`, `strategy_created_ts` |
| Module 1 lineage | `module1_model_version`, `module1_scenario_set_name`, `module1_scenario_name`, `population_id`, `anchor_date` |
| Applicant lineage | `application_seq`, `application_id`, `applicant_id`, `application_date` |
| Product / score | `product_type`, `score_band`, `credit_score` |
| Borrower signals | `annual_income`, `debt_to_income_ratio`, `utilization_rate`, `tradeline_count`, `months_since_oldest_trade`, `recent_inquiry_count`, `delinquency_count_12m`, `major_derogatory_flag`, `bankruptcy_flag` |
| Requested structure | `requested_amount`, `loan_term_months`, `base_apr_for_payment_calc`, `monthly_payment_proxy`, `payment_to_income_ratio`, `amount_to_income_ratio` |
| Module 1 risk economics | `estimated_pd`, `estimated_lgd`, `requested_expected_loss_amount` |
| Derived tiers | `strategy_risk_tier`, `affordability_tier`, `pti_bucket`, `dti_bucket`, `exposure_tier`, `policy_segment` |
| Rule flags | `hard_decline_trigger_flag`, `risk_decline_trigger_flag`, `affordability_decline_trigger_flag`, `exposure_limit_trigger_flag`, `manual_review_trigger_flag`, `counteroffer_eligible_flag` |
| Decision outputs | `decision_outcome`, `decision_path`, `approval_flag`, `decline_flag`, `manual_review_flag`, `counteroffer_flag`, `positive_offer_flag` |
| Reason codes | `primary_reason_code`, `secondary_reason_code`, `tertiary_reason_code`, `primary_reason_family`, `triggered_reason_code_list` |
| Approved exposure | `approved_amount`, `counteroffer_amount`, `exposure_reduction_flag`, `exposure_reduction_amount`, `exposure_reduction_pct`, `line_assignment_tier` |
| Approved affordability | `approved_monthly_payment_proxy`, `approved_payment_to_income_ratio` |
| Approved economics | `approved_expected_loss_amount`, `approved_el_reduction_amount`, `approved_el_reduction_pct` |
| Archive audit | `strategy_archived_ts` in archive only |

Important naming recommendation:

```text
expected_loss_amount from Module 1 should be carried forward as requested_expected_loss_amount.
```

That avoids ambiguity once Module 2 calculates approved-exposure Expected Loss.

---

# 10. Proposed parameter framework

Module 2 should use a two-layer parameter design.

## Layer 1 — Strategy run parameters

One active row per run:

```text
tmp_module2_strategy_params
```

Recommended fields:

| Parameter | Purpose |
|---|---|
| `strategy_set_name` | Strategy comparison family. |
| `strategy_name` | Specific simulated strategy. |
| `strategy_version` | Version of the strategy rules. |
| `module1_input_source` | `LATEST` or `ARCHIVE`. |
| `source_module1_scenario_set_name` | Required when using Module 1 archive. |
| `source_module1_scenario_name` | Required when using Module 1 archive. |
| `source_population_id` | Required for archive-based matched comparison. |
| `archive_run_flag` | Whether to persist strategy run. |
| `strategy_archive_reset_mode` | Archive reset behavior. |
| `global_approve_max_estimated_pd_proxy` | Clean approval synthetic estimated-PD proxy ceiling. |
| `global_review_max_estimated_pd_proxy` | Manual review synthetic estimated-PD proxy ceiling. |
| `global_decline_min_estimated_pd_proxy` | Hard decline synthetic estimated-PD proxy floor. |
| `global_approve_max_pti` | Clean approval PTI ceiling. |
| `global_review_max_pti` | Manual review PTI ceiling. |
| `global_decline_min_pti` | Hard affordability decline PTI threshold. |
| `global_approve_max_dti` | Clean approval DTI ceiling. |
| `global_decline_min_dti` | Hard DTI decline threshold. |
| `max_exposure_reduction_pct` | Counteroffer governance rail. |
| `min_counteroffer_amount_pct` | Prevents trivial partial approvals. |
| `manual_review_enabled_flag` | Allows review path to be switched on/off. |
| `counteroffer_enabled_flag` | Allows counteroffer path to be switched on/off. |

## Layer 2 — Product policy matrix

One row per product:

```text
tmp_module2_product_policy_params
```

Recommended fields:

| Parameter | Purpose |
|---|---|
| `product_type` | Product-specific rule join key. |
| `product_min_approved_amount` | Minimum viable approved exposure. |
| `product_max_approved_amount` | Product policy exposure cap. |
| `product_approve_max_pti` | Product-specific clean approval PTI ceiling. |
| `product_review_max_pti` | Product-specific review PTI ceiling. |
| `product_decline_min_pti` | Product-specific hard affordability decline threshold. |
| `product_approve_max_estimated_pd_proxy` | Product-specific clean approval risk ceiling. |
| `product_review_max_estimated_pd_proxy` | Product-specific review threshold. |
| `product_decline_min_estimated_pd_proxy` | Product-specific hard risk decline threshold. |
| `product_max_expected_loss` | Requested-exposure Expected Loss policy tolerance. |
| `counteroffer_allowed_flag` | Whether product supports partial approval simulation. |
| `manual_review_allowed_flag` | Whether product supports review path. |
| `exposure_assignment_method` | `REQUESTED`, `CAP_BASED`, `AFFORDABILITY_BASED`, `RISK_TIER_BASED`, or blended. |

## Gatekeeper expectations

The parameter gatekeeper should fail fast if:

```text
- strategy parameter row count <> 1
- strategy_set_name, strategy_name, or strategy_version is null or blank
- module1_input_source is not LATEST or ARCHIVE
- archive selectors are missing when module1_input_source = ARCHIVE
- input source returns zero rows
- selected Module 1 source has duplicate application_id rows for the run grain
- threshold ordering is incoherent
- synthetic estimated-PD proxy thresholds are outside 0–1
- PTI and DTI thresholds are outside governed ranges
- approved amount caps are negative or below minimums
- counteroffer settings can produce approved_amount > requested_amount
- archive reset mode is invalid
```

---

# 11. Proposed decision outcome taxonomy

Module 2 should assign **exactly one** primary `decision_outcome` per application per strategy run.

Recommended taxonomy:

| `decision_outcome` | Meaning |
|---|---|
| `APPROVE` | Synthetic applicant passes simulated policy as requested. |
| `COUNTEROFFER` | Synthetic applicant does not pass as requested, but receives a lower approved exposure proxy. |
| `MANUAL_REVIEW` | Synthetic applicant falls into a governed exception or borderline zone requiring simulated review. |
| `DECLINE` | Synthetic applicant fails one or more hard simulated policy rules. |

Recommended supporting field:

```text
decision_path
```

Example values:

```text
APPROVE_AS_REQUESTED
DECLINE_HARD_POLICY
DECLINE_RISK_POLICY
DECLINE_AFFORDABILITY_POLICY
DECLINE_EXPOSURE_POLICY
MANUAL_REVIEW_RISK_BORDERLINE
MANUAL_REVIEW_AFFORDABILITY_BORDERLINE
MANUAL_REVIEW_MIXED_SIGNAL_PROFILE
COUNTEROFFER_AFFORDABILITY_REDUCTION
COUNTEROFFER_PRODUCT_LIMIT
COUNTEROFFER_RISK_LIMIT
```

---

# 12. Recommendation: counteroffer as outcome vs decision path

**Recommendation: Treat `COUNTEROFFER` as a distinct `decision_outcome`, with detailed counteroffer reason captured in `decision_path`.**

Ranked options:

| Option | Assessment |
|---|---|
| **1. Counteroffer as distinct outcome** | Best for reporting counteroffer rate, counteroffer-book risk, exposure reduction, and approved Expected Loss impact. Recommended. |
| **2. Counteroffer as decision path under APPROVE** | Blurs clean approvals with reduced-exposure offers and complicates approval-rate interpretation. |
| **3. Counteroffer as decision path under MANUAL_REVIEW** | Useful only if all partial approvals require review; too restrictive for this simulator. |

Recommended flag convention:

| Field | Logic |
|---|---|
| `approval_flag` | `decision_outcome = 'APPROVE'` |
| `counteroffer_flag` | `decision_outcome = 'COUNTEROFFER'` |
| `manual_review_flag` | `decision_outcome = 'MANUAL_REVIEW'` |
| `decline_flag` | `decision_outcome = 'DECLINE'` |
| `positive_offer_flag` | `decision_outcome IN ('APPROVE', 'COUNTEROFFER')` |

This avoids double-counting while still allowing “positive offer” reporting when needed.

---

# 13. Proposed decision hierarchy

The rule hierarchy should be deterministic and priority-based.

## Recommended hierarchy

| Priority | Rule Family | Treatment |
|---:|---|---|
| 1 | Input integrity failure | Exclude only if structural source problem; otherwise fail gatekeeper before decisioning. |
| 2 | Hard adverse simulated policy rules | `DECLINE` |
| 3 | Hard synthetic estimated-risk rules | `DECLINE` |
| 4 | Hard affordability rules | `DECLINE` |
| 5 | Non-negotiable product exposure limit failure | `DECLINE` if no valid lower exposure can be offered. |
| 6 | Counteroffer eligibility | `COUNTEROFFER` if lower exposure resolves affordability or exposure pressure. |
| 7 | Manual review borderline rules | `MANUAL_REVIEW` |
| 8 | Clean approval rules | `APPROVE` |
| 9 | Fallback | `MANUAL_REVIEW` with governance reason if no rule cleanly classifies. |

## Hard decline examples

```text
bankruptcy_flag = TRUE
major_derogatory_flag = TRUE under configured strategy
delinquency_count_12m above hard threshold
score_band below product minimum
synthetic estimated-PD proxy above hard risk threshold
requested-exposure Expected Loss above hard threshold
PTI above hard affordability threshold and no valid counteroffer
DTI above hard capacity threshold
requested amount exceeds product limit and counteroffer is not allowed or not viable
```

## Manual review examples

```text
strong score band but high PTI
weak score band but low PTI and low requested amount
high requested amount but low synthetic estimated-PD proxy
borderline synthetic estimated-PD proxy near threshold
borderline PTI near threshold
mixed signal profile
```

## Counteroffer examples

```text
requested amount exceeds product cap but reduced amount is viable
PTI exceeds clean approval threshold but lower exposure brings approved PTI within tolerance
requested-exposure Expected Loss exceeds tolerance but reduced exposure brings approved Expected Loss within tolerance
risk tier supports exposure, but not the full requested amount
```

---

# 14. Proposed simulated reason-code framework

Reason codes should be explicitly framed as:

> **simulated strategy explanation codes for synthetic applicants, not regulatory adverse-action reason codes.**

They are used for transparency, QA, segmentation, and decision-path traceability.

## Recommended fields

```text
primary_reason_code
secondary_reason_code
tertiary_reason_code
primary_reason_family
triggered_reason_code_list
reason_priority_rank
```

## Reason-code taxonomy

| Family | Example Codes | Typical Outcomes |
|---|---|---|
| Hard policy | `BANKRUPTCY_FLAG`, `MAJOR_DEROGATORY`, `RECENT_DELINQUENCY`, `LOW_SCORE_BAND` | Decline |
| Risk | `HIGH_SYNTHETIC_ESTIMATED_PD_PROXY`, `HIGH_EXPECTED_LOSS`, `HIGH_UTILIZATION` | Decline, review, counteroffer |
| Affordability | `HIGH_PTI`, `HIGH_DTI`, `HIGH_AMOUNT_TO_INCOME` | Decline, review, counteroffer |
| Exposure | `REQUESTED_AMOUNT_EXCEEDS_POLICY_LIMIT`, `PRODUCT_POLICY_LIMIT`, `PRODUCT_SPECIFIC_EXPOSURE_LIMIT` | Counteroffer, decline |
| Counteroffer | `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT`, `COUNTEROFFER_EXPOSURE_LIMIT`, `COUNTEROFFER_RISK_LIMIT` | Counteroffer |
| Manual review | `MANUAL_REVIEW_MIXED_SIGNAL_PROFILE`, `BORDERLINE_APPROVAL_PROFILE`, `HIGH_EXPOSURE_LOW_RISK_REVIEW`, `WEAK_SCORE_LOW_PTI_REVIEW` | Manual review |
| Approval | `APPROVED_AS_REQUESTED`, `APPROVED_CLEAN_PROFILE`, `APPROVED_WITH_MONITORING_FLAG` | Approve |

## Recommended reason priority

| Priority | Reason Code |
|---:|---|
| 1 | `BANKRUPTCY_FLAG` |
| 2 | `MAJOR_DEROGATORY` |
| 3 | `RECENT_DELINQUENCY` |
| 4 | `LOW_SCORE_BAND` |
| 5 | `HIGH_SYNTHETIC_ESTIMATED_PD_PROXY` |
| 6 | `HIGH_EXPECTED_LOSS` |
| 7 | `HIGH_PTI` |
| 8 | `HIGH_DTI` |
| 9 | `HIGH_AMOUNT_TO_INCOME` |
| 10 | `REQUESTED_AMOUNT_EXCEEDS_POLICY_LIMIT` |
| 11 | `PRODUCT_POLICY_LIMIT` |
| 12 | `COUNTEROFFER_AFFORDABILITY_ADJUSTMENT` |
| 13 | `COUNTEROFFER_EXPOSURE_LIMIT` |
| 14 | `MANUAL_REVIEW_MIXED_SIGNAL_PROFILE` |
| 15 | `BORDERLINE_APPROVAL_PROFILE` |
| 16 | `APPROVED_AS_REQUESTED` |

Design principle:

```text
All triggered reasons may be stackable.
The primary, secondary, and tertiary reason codes are selected by deterministic priority.
The reason family is inherited from the primary reason code.
```

---

# 15. Proposed approved exposure and approved Expected Loss framework

Module 2 should distinguish three exposure concepts:

| Concept | Field | Meaning |
|---|---|---|
| Requested exposure | `requested_amount` | Module 1 requested amount. |
| Approved exposure proxy | `approved_amount` | Module 2 simulated approved exposure. |
| Counteroffer exposure proxy | `counteroffer_amount` | Lower exposure assigned under counteroffer outcome. |

## Recommended amount conventions

| Outcome | `approved_amount` | `counteroffer_amount` | Rationale |
|---|---:|---:|---|
| `APPROVE` | `requested_amount` | `NULL` | Approved as requested. |
| `COUNTEROFFER` | lower than `requested_amount` | same as `approved_amount` | Partial approval / counteroffer simulation. |
| `DECLINE` | `0` | `NULL` | No approved exposure under simulated strategy. |
| `MANUAL_REVIEW` | `NULL` | `NULL` | Pending simulated review; do not treat as booked exposure. |

## Manual review convention

**Recommendation: `approved_amount = NULL` for `MANUAL_REVIEW`.**

Reason:

```text
Manual review is unresolved by design.
Assigning approved_amount = 0 would make review look like decline.
Assigning a proposed amount would make review look partially booked.
NULL preserves the pending-review interpretation.
```

Optional future field:

```text
review_proposed_amount_proxy
```

This can be added later if the module needs to show a proposed amount pending review, but it should not be used in approved-book calculations.

## Approved payment proxy

For counteroffers and approved exposure, Module 2 should derive:

```text
approved_monthly_payment_proxy
```

Recommended initial method:

```text
approved_monthly_payment_proxy
=
monthly_payment_proxy × approved_amount / requested_amount
```

This is appropriate because Module 1 payment formulas scale with exposure for the current product proxy design. It also avoids rewriting Module 1’s product payment mechanics.

## Approved PTI proxy

```text
approved_payment_to_income_ratio
=
approved_monthly_payment_proxy / (annual_income / 12)
```

## Approved Expected Loss

Module 1 requested-exposure Expected Loss remains available as:

```text
requested_expected_loss_amount
```

Module 2 calculates:

```text
approved_expected_loss_amount
=
approved_amount × estimated_pd × estimated_lgd
```

Interpretation note:

```text
estimated_pd is the SQL field name, but the business interpretation is the synthetic estimated-PD proxy.
```

Recommended approved Expected Loss conventions:

| Outcome | `approved_expected_loss_amount` |
|---|---:|
| `APPROVE` | `approved_amount × synthetic estimated-PD proxy × LGD` |
| `COUNTEROFFER` | `approved_amount × synthetic estimated-PD proxy × LGD` |
| `DECLINE` | `0` |
| `MANUAL_REVIEW` | `NULL` |

This creates a clean distinction between:

```text
requested-exposure Expected Loss
approved-exposure Expected Loss
unresolved-review exposure
```

---

# 16. Approved-book, declined-book, manual-review-book, and counteroffer-book reporting

Module 2 should define four mutually exclusive reporting books.

| Book | Definition | Core Use |
|---|---|---|
| Approved-book profile | `decision_outcome = 'APPROVE'` | Clean approvals as requested. |
| Counteroffer-book profile | `decision_outcome = 'COUNTEROFFER'` | Partial approval / reduced exposure strategy outcomes. |
| Manual-review-book profile | `decision_outcome = 'MANUAL_REVIEW'` | Borderline or mixed-signal synthetic applicants. |
| Declined-book profile | `decision_outcome = 'DECLINE'` | Hard simulated policy failures. |

Also define:

```text
positive_offer_book = APPROVE + COUNTEROFFER
```

This supports executive reporting without contaminating clean approval-rate metrics.

## Required reporting metrics by book

Each book should report:

```text
application count
book share
average requested amount
average approved amount
average exposure reduction amount
average exposure reduction pct
average PTI
average approved PTI
average synthetic estimated-PD proxy
average LGD
average requested-exposure Expected Loss
average approved-exposure Expected Loss
total approved amount
total approved Expected Loss
primary reason-code distribution
product mix
score-band mix
PTI-bucket mix
```

---

# 17. Proposed strategy comparison framework

Module 2 should support three comparison modes.

## Mode 1 — Strategy-only comparison

```text
same module1_scenario_set_name
same module1_scenario_name
same population_id
different strategy_name / strategy_version
```

This is the cleanest comparison because the synthetic population and upstream Module 1 scenario are held constant.

It answers:

```text
What changed because the strategy changed?
```

## Mode 2 — Module 1 scenario sensitivity under same strategy

```text
same population_id
same strategy_name / strategy_version
different module1_scenario_name
```

This answers:

```text
How does the same strategy behave under different upstream Module 1 scenario assumptions?
```

Important boundary:

```text
These are controlled scenario assumptions, not forecasts.
```

## Mode 3 — Combined scenario and strategy comparison

```text
different module1_scenario_name
different strategy_name
same population_id
```

This is useful but less analytically clean. It should be labeled as combined-effect analysis.

## Required comparison outputs

| Comparison View | Metrics |
|---|---|
| Portfolio-level | approval rate, counteroffer rate, manual review rate, decline rate, total approved amount, total approved Expected Loss |
| Product-level | outcome distribution, approved amount, approved Expected Loss by product |
| Score-band-level | approval / decline / review / counteroffer rates by score band |
| PTI-bucket-level | affordability sensitivity and counteroffer concentration |
| Product × score matrix | strategy effect concentrations |
| Reason-code distribution | primary reason and reason family shifts |
| Matched row-level deltas | outcome migration, approved amount delta, approved Expected Loss delta |
| Outcome migration matrix | e.g., `APPROVE → DECLINE`, `APPROVE → COUNTEROFFER`, `MANUAL_REVIEW → APPROVE` |

---

# 18. Proposed validation framework

Module 2 validation should be built before calibration is treated as complete.

## A. Structural validation

Required checks:

```text
input row count = output row count
one output row per application per strategy run
no duplicate application_id within latest-run grain
all decision_outcome values populated
decision_outcome is in approved taxonomy
all flags reconcile to decision_outcome
Module 1 lineage preserved
strategy metadata populated
archive rows traceable
```

## B. Decision distribution validation

Report:

```text
approval rate
counteroffer rate
manual review rate
decline rate
outcome distribution by product
outcome distribution by score band
outcome distribution by PTI bucket
outcome distribution by strategy risk tier
```

Expected behavior:

```text
stronger score bands should generally show higher approval rates
weaker score bands should generally show higher decline or review rates
higher PTI buckets should generally show lower approval rates and higher review / counteroffer / decline rates
```

## C. Risk ordering validation

Compare the synthetic estimated-PD proxy across books:

```text
approved-book average synthetic estimated-PD proxy
counteroffer-book average synthetic estimated-PD proxy
manual-review-book average synthetic estimated-PD proxy
declined-book average synthetic estimated-PD proxy
```

Expected pattern:

```text
APPROVE generally lowest
COUNTEROFFER elevated versus clean approvals
MANUAL_REVIEW intermediate / mixed
DECLINE generally highest
```

## D. Affordability validation

Required checks:

```text
approval rate by PTI bucket
counteroffer rate by PTI bucket
manual review rate by PTI bucket
decline rate by PTI bucket
primary affordability reason distribution by PTI bucket
requested PTI versus approved PTI for counteroffers
```

Expected behavior:

```text
high-PTI synthetic applicants should concentrate in review, counteroffer, or decline outcomes
counteroffers should reduce approved PTI versus requested PTI
affordability reason codes should concentrate in high-PTI and high-DTI groups
```

## E. Reason-code validation

Required checks:

```text
declines have non-null primary reason code
manual reviews have non-null primary reason code
counteroffers have non-null primary reason code
clean approvals either have APPROVED_AS_REQUESTED or documented null reason convention
primary reason aligns with highest-priority triggered rule
secondary and tertiary reasons do not duplicate primary reason
reason-code family distribution is interpretable
```

## F. Approved exposure validation

Required checks:

```text
approved_amount <= requested_amount
APPROVE has approved_amount > 0
DECLINE has approved_amount = 0
MANUAL_REVIEW has approved_amount IS NULL
COUNTEROFFER has approved_amount > 0 and approved_amount < requested_amount
exposure_reduction_flag = TRUE only when approved_amount < requested_amount
exposure_reduction_amount > 0 for counteroffers
approved_expected_loss_amount uses approved exposure
requested_expected_loss_amount remains unchanged from Module 1
```

## G. Strategy comparison validation

Required checks:

```text
matched row count equals input application count when population_id and Module 1 scenario are held constant
tighter risk strategy reduces approval rate or approved exposure
tighter affordability strategy increases counteroffer / manual review / decline pressure in high-PTI buckets
growth strategy increases approval or approved exposure with measurable risk tradeoff
reason-code distribution shifts in expected direction
approved-book synthetic estimated-PD proxy and approved Expected Loss tradeoffs are visible
```

## H. Edge-case validation

Review targeted populations:

```text
strong credit / high PTI
weak credit / low PTI
high synthetic estimated-PD proxy / low requested amount
large requested amount / low synthetic estimated-PD proxy
high utilization / otherwise strong profile
bankruptcy flag cases
major derogatory cases
borderline counteroffer cases
borderline manual review cases
```

---

# 19. Recommended workstreams

## Workstream A — Strategy parameter and gatekeeper framework

Build the strategy parameter layer first.

Deliverables:

```text
strategy metadata
source selection controls
threshold parameters
product policy matrix
archive controls
fail-fast gatekeeper
```

Acceptance criteria:

```text
bad strategy metadata fails before output generation
bad thresholds fail before output generation
bad source selectors fail before output generation
```

## Workstream B — Input lineage and derived segmentation

Deliverables:

```text
Module 1 source selector
renamed Module 1 scenario fields
risk tier
PTI bucket
DTI bucket
affordability tier
exposure tier
```

Acceptance criteria:

```text
row count preserved
Module 1 lineage preserved
all derived tiers populated
```

## Workstream C — Decision hierarchy

Deliverables:

```text
hard decline flags
risk flags
affordability flags
exposure flags
manual review flags
counteroffer eligibility flags
single decision_outcome assignment
decision_path assignment
```

Acceptance criteria:

```text
exactly one decision outcome per row
flags reconcile to outcome
outcome distribution is plausible
```

## Workstream D — Reason-code simulation framework

Deliverables:

```text
reason taxonomy
reason priority hierarchy
primary / secondary / tertiary reason assignment
reason family
triggered reason list
```

Acceptance criteria:

```text
no unexplained declines
no unexplained manual reviews
counteroffers have counteroffer-relevant reason codes
reason priority behaves deterministically
```

## Workstream E — Approved exposure and approved Expected Loss

Deliverables:

```text
approved_amount
counteroffer_amount
approved monthly payment proxy
approved PTI proxy
approved_expected_loss_amount
exposure reduction metrics
line assignment tier
```

Acceptance criteria:

```text
approved amount rules are internally consistent
counteroffer cases show lower approved amount than requested amount
approved Expected Loss uses approved exposure
```

## Workstream F — Archive and strategy comparison

Deliverables:

```text
strategy_decisions_archive
archive reset controls
matched strategy comparison queries
portfolio / segment / row-level deltas
outcome migration matrix
```

Acceptance criteria:

```text
archive grain is correct
matched rows equal source population when expected
strategy deltas isolate strategy effects
```

## Workstream G — Validation and calibration pass

Deliverables:

```text
baseline strategy QA
tighter affordability strategy QA
tighter risk strategy QA
growth strategy QA
product-specific exposure strategy QA
edge-case review
```

Acceptance criteria:

```text
strategy behavior is directional, explainable, and stable
no structural validation failures
no hidden Module 1 reinterpretation
```

---

# 20. Key design tradeoffs

| Tradeoff | Recommendation | Rationale |
|---|---|---|
| Latest table only vs archive | Use both | Latest is efficient for QA; archive is required for governed comparison. |
| Counteroffer as outcome vs path | Counteroffer as distinct outcome | Clean counteroffer-rate and exposure-reduction reporting. |
| Manual review approved amount | `NULL` | Preserves pending-review interpretation. |
| Decline approved Expected Loss | `0` | No approved exposure under simulated strategy. |
| Manual review approved Expected Loss | `NULL` | Unresolved outcome should not be treated as booked exposure. |
| Product policy matrix vs global thresholds only | Use both | Global defaults plus product overrides preserve product-aware strategy behavior. |
| Reason codes hard-coded in CASE only vs governed priority framework | Use governed priority framework | Improves auditability and deterministic explanation logic. |
| Recalculate payment from scratch vs proportional approved payment proxy | Use proportional approved payment proxy initially | Avoids rewriting Module 1 product mechanics while allowing approved PTI simulation. |
| Add new Module 1 fields now vs derive in Module 2 | Derive in Module 2 where possible | Preserves finalized Module 1 boundary. |

---

# 21. Missing-field assessment

No Module 1 redesign is required for the initial Module 2 build.

| Potential Need | Available in Module 1? | Recommendation |
|---|---:|---|
| Approved PTI | Not directly | Derive in Module 2 using approved payment proxy. |
| Approved monthly payment | Not directly | Derive in Module 2 proportionally from Module 1 payment proxy. |
| Risk tier | Not directly | Derive in Module 2 from the synthetic estimated-PD proxy and strategy thresholds. |
| Affordability tier | Not directly | Derive in Module 2 from PTI / DTI. |
| Product policy cap | Not directly | Module 2 parameter field. |
| Collateral value / LTV | No | Future Module 1 enhancement only if secured-product collateral strategy becomes required. |
| Employment / verification signals | No | Future enhancement only; not needed for initial strategy simulator. |
| Protected class attributes | No | Do not add for Module 2; fair lending analysis is out of scope. |
| Observed performance outcomes | No | Not needed; Module 2 is not calibration or validation against real defaults. |

---

# 22. Recommended first coding step

The first coding step should be:

> **Build the Module 2 parameter layer, source-selection layer, and fail-fast gatekeeper before writing any decision logic.**

That means the first implementation should establish:

```text
tmp_module2_strategy_params
tmp_module2_product_policy_params
strategy metadata validation
Module 1 source selector validation
threshold-ordering validation
archive-control validation
input row-count validation
Module 1 scenario lineage renaming
```

Only after that should we build the rule flags, reason-code hierarchy, approved exposure logic, and final output table.

This sequencing prevents the most common architecture failure: building decision rules before the run grain, lineage, and governance controls are fixed.

---

# 23. Text-based architecture flow diagram

```text
┌────────────────────────────────────────────────────────────────────┐
│ MODULE 1 OUTPUT                                                     │
│ credit_decisioning_sim.synthetic_applications                       │
│ or                                                                 │
│ credit_decisioning_sim.synthetic_applications_scenario_archive       │
│                                                                    │
│ Carries:                                                           │
│ scenario_set_name, scenario_name, population_id, application_id,     │
│ product_type, score_band, requested_amount, PTI, DTI, utilization,   │
│ delinquency flags, bankruptcy flag, estimated_pd, LGD, Expected Loss │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ MODULE 2 STRATEGY PARAMETER LAYER                                  │
│ tmp_module2_strategy_params                                         │
│ tmp_module2_product_policy_params                                   │
│                                                                    │
│ Adds:                                                              │
│ strategy_set_name, strategy_name, strategy_version, thresholds,      │
│ product limits, counteroffer settings, archive controls             │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ SOURCE SELECTION + LINEAGE NORMALIZATION                           │
│                                                                    │
│ scenario_set_name → module1_scenario_set_name                       │
│ scenario_name     → module1_scenario_name                           │
│ population_id preserved                                             │
│ application_id preserved                                            │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ DERIVED SEGMENTATION                                                │
│                                                                    │
│ strategy risk tier                                                  │
│ PTI bucket                                                          │
│ DTI bucket                                                          │
│ affordability tier                                                  │
│ exposure tier                                                       │
│ product policy segment                                              │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ DECISION LOGIC                                                      │
│                                                                    │
│ hard decline checks                                                 │
│ synthetic estimated-risk checks                                     │
│ affordability checks                                                │
│ exposure limit checks                                               │
│ counteroffer eligibility                                            │
│ manual review triggers                                              │
│ approval assignment                                                 │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ SIMULATED REASON CODES                                              │
│                                                                    │
│ primary_reason_code                                                 │
│ secondary_reason_code                                               │
│ tertiary_reason_code                                                │
│ primary_reason_family                                               │
│ triggered_reason_code_list                                          │
│                                                                    │
│ Not regulatory adverse-action reason codes                          │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ APPROVED EXPOSURE + APPROVED EXPECTED LOSS                          │
│                                                                    │
│ approved_amount                                                     │
│ counteroffer_amount                                                 │
│ exposure_reduction_flag                                             │
│ approved_monthly_payment_proxy                                      │
│ approved_payment_to_income_ratio                                    │
│ approved_expected_loss_amount                                       │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ LATEST-RUN STRATEGY OUTPUT                                          │
│ credit_decisioning_sim.strategy_decisions                           │
│                                                                    │
│ One row per application for current Module 2 strategy run           │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ STRATEGY ARCHIVE                                                    │
│ credit_decisioning_sim.strategy_decisions_archive                   │
│                                                                    │
│ One row per application × Module 1 scenario × strategy version      │
└────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌────────────────────────────────────────────────────────────────────┐
│ QA + STRATEGY COMPARISON                                            │
│                                                                    │
│ decision distribution                                                │
│ risk ordering                                                        │
│ affordability sensitivity                                            │
│ reason-code coverage                                                │
│ approved exposure validation                                         │
│ approved-book / declined-book / review-book / counteroffer-book QA   │
│ matched applicant-level strategy deltas                              │
└────────────────────────────────────────────────────────────────────┘
```

This architecture preserves Module 1’s governed synthetic simulation foundation and adds a clean downstream layer for simulated strategy outcomes, reason-code traceability, exposure treatment, approved Expected Loss, and matched strategy comparison.
<!-- END_MESSAGE C038-M00018 -->


---

<a id="c038-m00019"></a>

### C038-M00019

**Andrew** · 2026-05-06T10:27:44.559000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00019 -->
I agree with the overall Module 2 architecture direction.

Before we move to SQL, please lock the following design decisions and then restate the final Module 2 architecture briefly.

Do not write full code yet.

================================================================================
1. ARCHITECTURE
================================================================================

Use the latest-run strategy decision table plus strategy decision archive table.

This should mirror the Module 1 pattern:
- latest-run table for current strategy output and QA
- archive table for preserving completed strategy runs and enabling matched comparison

Archive grain should be:

one row per application × Module 1 scenario × Module 2 strategy version

In practical terms, the archive grain should include:
- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- application_id

Please also explicitly define the archive replacement / rerun key as:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

The row-level archive grain should additionally include application_id.

================================================================================
2. NAMING
================================================================================

Preserve Module 1 scenario fields as upstream lineage:

- module1_scenario_set_name
- module1_scenario_name
- population_id

Use Module 2 strategy fields for downstream strategy:

- strategy_set_name
- strategy_name
- strategy_version

Do not overload scenario_name.

Module 1 scenario metadata describes the synthetic population and upstream risk environment.
Module 2 strategy metadata describes the simulated decision strategy applied to that population.

================================================================================
3. ESTIMATED-PD PROXY BOUNDARY
================================================================================

Module 2 should not recalculate the synthetic estimated-PD proxy in the initial v1.0 build.

Module 2 should consume the Module 1 field:

- estimated_pd

as the finalized Module 1 synthetic estimated-PD proxy input.

The SQL column name may remain estimated_pd because that is the finalized Module 1 output field. However, comments, documentation, and interpretation should refer to it as the synthetic estimated-PD proxy.

Module 2 may calculate:
- approved_amount
- approved_monthly_payment_proxy
- approved_payment_to_income_ratio
- approved_expected_loss_amount

But Module 2 should not create a new post-decision risk model unless we explicitly design a future post-decision risk adjustment layer.

================================================================================
4. DECISION OUTCOME TAXONOMY
================================================================================

Use exactly four primary decision_outcome values:

- APPROVE
- COUNTEROFFER
- MANUAL_REVIEW
- DECLINE

Counteroffer should be a distinct decision_outcome.

Detailed counteroffer type should be captured in decision_path.

This allows reporting to separate:
- clean approvals
- counteroffers / partial approvals
- manual reviews
- declines

Also include a simulated_offer_exposure_flag, where:
- APPROVE = TRUE
- COUNTEROFFER = TRUE
- MANUAL_REVIEW = FALSE / unresolved
- DECLINE = FALSE

This flag should support approved-book / offer-exposure reporting while preserving the boundary that these are simulated strategy outcomes, not real booked accounts.

================================================================================
5. AMOUNT AND EXPECTED LOSS CONVENTIONS
================================================================================

Please explicitly define the amount and Expected Loss convention for each outcome.

APPROVE:
- approved_amount = requested_amount
- counteroffer_amount = NULL
- approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd

COUNTEROFFER:
- approved_amount < requested_amount
- counteroffer_amount = approved_amount
- approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd
- exposure_reduction_flag = TRUE
- exposure_reduction_amount = requested_amount - approved_amount
- exposure_reduction_pct = exposure_reduction_amount / NULLIF(requested_amount, 0)

DECLINE:
- approved_amount = 0
- counteroffer_amount = NULL
- approved_expected_loss_amount = 0
- do not treat decline as booked exposure

MANUAL_REVIEW:
- approved_amount = NULL
- counteroffer_amount = NULL
- approved_expected_loss_amount = NULL
- do not treat manual review as booked or approved exposure

Manual review is unresolved by design.

================================================================================
6. MANUAL REVIEW DIAGNOSTICS
================================================================================

If useful, propose optional diagnostic fields such as:

- review_path
- review_reason_family
- review_recommended_amount
- review_priority_tier

But do not include them unless they add clear value to Module 2 v1.0.

The default should be to keep Module 2 v1.0 focused and audit-readable.

================================================================================
7. APPROVED PAYMENT AND APPROVED PTI PROXY
================================================================================

If using proportional scaling, define:

approved_monthly_payment_proxy =
    monthly_payment_proxy × approved_amount / NULLIF(requested_amount, 0)

Document this as a strategy-simulation proxy, not a recalculated contractual payment schedule.

Also define:

approved_payment_to_income_ratio =
    approved_monthly_payment_proxy / NULLIF((annual_income / 12.0), 0)

where monthly income is derived from the Module 1 annual_income field.

This is useful because counteroffers should reduce exposure and should generally improve approved-payment affordability relative to the original requested structure.

Please explicitly preserve the distinction between:
- original requested PTI from Module 1
- approved payment-to-income ratio from Module 2 after exposure treatment

Outcome-specific convention:

APPROVE:
- approved_monthly_payment_proxy = monthly_payment_proxy
- approved_payment_to_income_ratio = payment_to_income_ratio

COUNTEROFFER:
- approved_monthly_payment_proxy = monthly_payment_proxy × approved_amount / NULLIF(requested_amount, 0)
- approved_payment_to_income_ratio = approved_monthly_payment_proxy / NULLIF((annual_income / 12.0), 0)

DECLINE:
- approved_monthly_payment_proxy = 0
- approved_payment_to_income_ratio = 0

MANUAL_REVIEW:
- approved_monthly_payment_proxy = NULL
- approved_payment_to_income_ratio = NULL

================================================================================
8. REASON-CODE CONVENTION
================================================================================

Use neutral simulation language.

Do not use “adverse action” framing.

Preferred language:
- simulated reason code
- simulated policy reason
- strategy explanation code
- decision-path reason
- policy stop reason
- review trigger reason
- counteroffer reason

Reason codes are not regulatory adverse-action reason codes.

Before coding, please define the convention for approvals.

My preference:
- APPROVE rows receive primary_reason_code = APPROVED_AS_REQUESTED
- COUNTEROFFER rows receive a counteroffer-related reason code
- MANUAL_REVIEW rows receive a review-trigger reason code
- DECLINE rows receive a policy-stop reason code

This keeps every row explainable and makes QA easier.

Please confirm whether you agree with that convention.

================================================================================
9. THRESHOLD HIERARCHY
================================================================================

Before coding, define exact threshold-ordering rules and proposed default thresholds for:

- synthetic estimated-PD proxy thresholds
- PTI thresholds
- DTI thresholds
- Expected Loss thresholds
- product exposure caps
- counteroffer minimum viable amount
- manual review bands
- approval bands
- decline bands

Please explain each threshold in business terms.

For example:
- what behavior it is intended to capture
- why the value is plausible
- how it relates to approval / review / decline
- how it should be validated

These thresholds should be treated as initial simulated strategy defaults, not production underwriting policy.

Do not silently embed thresholds in SQL without a parameter dictionary and commentary.

================================================================================
10. PARAMETER DICTIONARY
================================================================================

Before coding, provide a compact strategy parameter dictionary with:

- parameter_name
- data_type
- default_value
- allowed_range
- parameter_scope
- product_applicability
- purpose
- gatekeeper_rule
- business_interpretation

This should include parameters for:
- strategy identity
- source Module 1 scenario selection
- archive controls
- approval thresholds
- manual review thresholds
- decline thresholds
- counteroffer thresholds
- product-specific exposure rules
- approved amount rules
- approved Expected Loss rules

================================================================================
11. STRATEGY PARAMETER GATEKEEPER
================================================================================

Module 2 should include a fail-fast strategy parameter gatekeeper.

At minimum, the gatekeeper should validate:

- exactly one active strategy parameter row for a single strategy run
- strategy_set_name is not null or blank
- strategy_name is not null or blank
- strategy_version is not null or blank
- source Module 1 scenario fields are valid
- archive reset mode is valid
- threshold values are inside governed ranges
- threshold ordering is coherent
- counteroffer rules cannot create approved_amount greater than requested_amount
- approved amount cannot be negative
- approved Expected Loss cannot be negative
- decision outcome conventions remain internally consistent

================================================================================
12. WORKSTREAM NAMING
================================================================================

Rename “Validation and calibration pass” to:

Validation, QA, and Strategy Tuning Pass

Avoid the word calibration unless we are explicitly discussing empirical calibration, which Module 2 is not doing.

Module 2 should tune simulated strategy behavior, not calibrate real-world underwriting performance.

================================================================================
13. OUTPUT CONSISTENCY REQUIREMENTS
================================================================================

Before coding, lock the following output consistency rules:

- every row must have exactly one primary decision_outcome
- approval_flag, decline_flag, manual_review_flag, and counteroffer_flag must reconcile to decision_outcome
- APPROVE and COUNTEROFFER should be distinguishable but can both feed simulated_offer_exposure_flag
- approved_amount must not exceed requested_amount unless explicitly designed
- counteroffer_amount must equal approved_amount for COUNTEROFFER rows
- DECLINE rows should have approved_amount = 0
- MANUAL_REVIEW rows should have approved_amount = NULL
- approved_expected_loss_amount should use approved exposure, not requested exposure
- Module 1 expected_loss_amount should remain available as requested-exposure Expected Loss
- Module 1 expected_loss_amount should be renamed or aliased as requested_expected_loss_amount in Module 2 outputs to avoid ambiguity

================================================================================
14. ADDITIONAL OUTPUT AND SOURCE-CONTROL CONVENTIONS
================================================================================

Please also lock the following conventions before coding.

1. Avoid recalibration language
   Module 2 should not create a new post-decision risk model unless we explicitly design a future post-decision risk adjustment layer.
   Avoid the phrase risk recalibration unless we are explicitly discussing empirical calibration, which Module 2 is not doing.

2. Strategy run audit metadata
   Include strategy_run_ts or strategy_run_id as audit metadata.
   This should support run traceability but should not replace the archive replacement / rerun key.

3. Approved-book / offer-exposure inclusion flag
   Include simulated_offer_exposure_flag:
   - APPROVE = TRUE
   - COUNTEROFFER = TRUE
   - MANUAL_REVIEW = FALSE / unresolved
   - DECLINE = FALSE

   This flag should be used for approved-book reporting and approved exposure summaries.
   It should not imply real account booking.

4. Source-input gatekeepers
   The strategy parameter gatekeeper should also validate:
   - selected Module 1 source table contains rows
   - selected Module 1 source has no duplicate application_id values for the selected population / scenario
   - required Module 1 input fields are non-null where required
   - if using the Module 1 scenario archive, exactly one Module 1 scenario is selected unless multi-scenario processing is explicitly designed

================================================================================
15. NEXT STEP
================================================================================

After incorporating these clarifications, please:

1. Briefly restate the locked Module 2 architecture.
2. Provide the compact strategy parameter dictionary.
3. Define the threshold hierarchy and default threshold recommendations.
4. Propose the first SQL build step only.

Do not write the full SQL module yet.
<!-- END_MESSAGE C038-M00019 -->


---

<a id="c038-m00037"></a>

### C038-M00037

**ChatGPT** · 2026-05-06T10:35:01.498260-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00037 -->
# Locked Module 2 design decisions

Module 2 will be built as **Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine v1.0**.

It will consume finalized Module 1 outputs as authoritative, including the SQL field `estimated_pd`, interpreted only as the **synthetic estimated-PD proxy**. Module 2 will not recalculate that proxy, will not create a post-decision risk model in v1.0, and will not reinterpret Module 1 scenarios as forecasts. This is consistent with Module 1’s documented boundary as a governed synthetic strategy simulation foundation, not a production underwriting system, calibrated default model, pricing engine, or forecasting framework. fileciteturn4file0 The validation summary confirms that Module 1 is deterministic, scenario-capable, and accepted for controlled synthetic strategy simulation within documented boundaries. fileciteturn4file1

---

## 1. Final locked architecture

### Recommended physical architecture

Use both:

```text
credit_decisioning_sim.strategy_decisions
credit_decisioning_sim.strategy_decisions_archive
```

### Latest-run table

```text
credit_decisioning_sim.strategy_decisions
```

Purpose:

```text
Current Module 2 strategy output for the selected Module 1 input population / scenario.
```

Use cases:

```text
single-strategy QA
development validation
strategy walkthrough
debugging
```

Grain:

```text
one row per application for the current strategy run
```

### Strategy archive table

```text
credit_decisioning_sim.strategy_decisions_archive
```

Purpose:

```text
Persistent strategy-decision archive for completed Module 2 strategy runs.
```

Archive grain:

```text
one row per application
× Module 1 scenario
× Module 2 strategy version
```

Practical archive grain fields:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
application_id
```

### Archive replacement / rerun key

The locked archive replacement key is:

```text
strategy_set_name
strategy_name
strategy_version
module1_scenario_set_name
module1_scenario_name
population_id
```

The row-level archive grain additionally includes:

```text
application_id
```

This means a rerun of the same strategy against the same Module 1 scenario and population should replace rows matching the replacement key, then insert one row per `application_id`.

---

## 2. Final naming convention

Do not overload `scenario_name`.

| Layer | Field | Meaning |
|---|---|---|
| Module 1 lineage | `module1_scenario_set_name` | Upstream synthetic population / risk-environment scenario family |
| Module 1 lineage | `module1_scenario_name` | Upstream Module 1 scenario name |
| Module 1 lineage | `population_id` | Deterministic synthetic population anchor |
| Module 2 strategy | `strategy_set_name` | Downstream decision-strategy comparison family |
| Module 2 strategy | `strategy_name` | Specific simulated decision strategy |
| Module 2 strategy | `strategy_version` | Versioned strategy configuration |

Locked interpretation:

```text
Module 1 scenario metadata describes the synthetic population and upstream risk environment.

Module 2 strategy metadata describes the simulated decision strategy applied to that population.
```

---

## 3. Locked decision outcome taxonomy

Use exactly four primary `decision_outcome` values:

```text
APPROVE
COUNTEROFFER
MANUAL_REVIEW
DECLINE
```

`COUNTEROFFER` is locked as a **distinct decision outcome**, not merely a path under `APPROVE`.

Detailed counteroffer type will be captured in:

```text
decision_path
```

Examples:

```text
COUNTEROFFER_AFFORDABILITY_REDUCTION
COUNTEROFFER_PRODUCT_LIMIT
COUNTEROFFER_EXPECTED_LOSS_LIMIT
COUNTEROFFER_RISK_EXPOSURE_LIMIT
```

### Locked flag convention

| Outcome | `approval_flag` | `counteroffer_flag` | `manual_review_flag` | `decline_flag` | `simulated_offer_exposure_flag` |
|---|---:|---:|---:|---:|---:|
| `APPROVE` | TRUE | FALSE | FALSE | FALSE | TRUE |
| `COUNTEROFFER` | FALSE | TRUE | FALSE | FALSE | TRUE |
| `MANUAL_REVIEW` | FALSE | FALSE | TRUE | FALSE | FALSE |
| `DECLINE` | FALSE | FALSE | FALSE | TRUE | FALSE |

`simulated_offer_exposure_flag` supports offer-exposure and approved-book reporting. It does **not** imply real booked accounts.

---

## 4. Locked amount, payment, PTI, and Expected Loss conventions

Module 1 `expected_loss_amount` will be carried forward in Module 2 as:

```text
requested_expected_loss_amount
```

Module 2 will calculate:

```text
approved_expected_loss_amount
=
approved_amount × estimated_pd × estimated_lgd
```

Interpretation note:

```text
estimated_pd is the finalized Module 1 SQL field name.
In Module 2 commentary and documentation, it means the synthetic estimated-PD proxy.
```

### Outcome-level conventions

| Outcome | `approved_amount` | `counteroffer_amount` | `approved_expected_loss_amount` | Exposure interpretation |
|---|---:|---:|---:|---|
| `APPROVE` | `requested_amount` | `NULL` | `approved_amount × estimated_pd × estimated_lgd` | Simulated approval as requested |
| `COUNTEROFFER` | `< requested_amount` | `approved_amount` | `approved_amount × estimated_pd × estimated_lgd` | Simulated reduced exposure |
| `DECLINE` | `0` | `NULL` | `0` | Not booked / no offer exposure |
| `MANUAL_REVIEW` | `NULL` | `NULL` | `NULL` | Unresolved by design |

### Counteroffer exposure fields

For `COUNTEROFFER` rows:

```text
exposure_reduction_flag   = TRUE
exposure_reduction_amount = requested_amount - approved_amount
exposure_reduction_pct    = exposure_reduction_amount / NULLIF(requested_amount, 0)
```

For non-counteroffer rows, the exposure reduction fields should reconcile to the outcome convention.

---

## 5. Locked approved payment and approved PTI proxy convention

Module 2 will preserve the distinction between:

```text
Module 1 original requested PTI
Module 2 approved payment-to-income ratio after exposure treatment
```

Module 1 field:

```text
payment_to_income_ratio
```

Module 2 field:

```text
approved_payment_to_income_ratio
```

### Formula

```text
approved_monthly_payment_proxy =
    monthly_payment_proxy × approved_amount / NULLIF(requested_amount, 0)
```

This is a **strategy-simulation proxy**, not a recalculated contractual payment schedule.

```text
approved_payment_to_income_ratio =
    approved_monthly_payment_proxy / NULLIF((annual_income / 12.0), 0)
```

### Outcome-level payment convention

| Outcome | `approved_monthly_payment_proxy` | `approved_payment_to_income_ratio` |
|---|---:|---:|
| `APPROVE` | `monthly_payment_proxy` | `payment_to_income_ratio` |
| `COUNTEROFFER` | `monthly_payment_proxy × approved_amount / NULLIF(requested_amount, 0)` | `approved_monthly_payment_proxy / NULLIF((annual_income / 12.0), 0)` |
| `DECLINE` | `0` | `0` |
| `MANUAL_REVIEW` | `NULL` | `NULL` |

---

## 6. Manual review diagnostics

For Module 2 v1.0, keep the final output focused and audit-readable.

Recommended v1.0 approach:

```text
Do not add separate review_path, review_reason_family, review_recommended_amount,
or review_priority_tier fields in the first final output design.
```

Reason:

```text
decision_path, primary_reason_code, primary_reason_family, and triggered_reason_code_list
already explain manual review routing.
```

Optional future diagnostic if review outcomes become too heterogeneous:

```text
review_priority_tier
```

This could be added later if QA shows the manual-review book needs high / medium / low review severity segmentation.

---

## 7. Reason-code convention

I agree with your preferred convention.

Every row should receive a populated `primary_reason_code`.

These are **simulated strategy explanation codes**, not regulatory adverse-action reason codes.

| Outcome | Primary reason-code convention |
|---|---|
| `APPROVE` | `APPROVED_AS_REQUESTED` |
| `COUNTEROFFER` | Counteroffer-related reason code |
| `MANUAL_REVIEW` | Review-trigger reason code |
| `DECLINE` | Policy-stop reason code |

Recommended examples:

```text
APPROVED_AS_REQUESTED

COUNTEROFFER_AFFORDABILITY_ADJUSTMENT
COUNTEROFFER_PRODUCT_EXPOSURE_LIMIT
COUNTEROFFER_EXPECTED_LOSS_LIMIT

MANUAL_REVIEW_BORDERLINE_SYNTHETIC_RISK
MANUAL_REVIEW_BORDERLINE_AFFORDABILITY
MANUAL_REVIEW_MIXED_SIGNAL_PROFILE
MANUAL_REVIEW_HIGH_EXPOSURE_LOW_RISK

POLICY_STOP_BANKRUPTCY_FLAG
POLICY_STOP_MAJOR_DEROGATORY
POLICY_STOP_RECENT_DELINQUENCY
POLICY_STOP_HIGH_SYNTHETIC_ESTIMATED_PD_PROXY
POLICY_STOP_HIGH_PTI_UNRESOLVED
POLICY_STOP_HIGH_DTI
POLICY_STOP_HIGH_EXPECTED_LOSS_UNRESOLVED
POLICY_STOP_EXPOSURE_LIMIT_UNRESOLVED
```

Reason-code fields:

```text
primary_reason_code
secondary_reason_code
tertiary_reason_code
primary_reason_family
triggered_reason_code_list
reason_priority_rank
```

---

# 8. Threshold hierarchy and default recommendations

These are initial simulated strategy defaults only. They are not production underwriting policy.

## 8.1 Global threshold-ordering rules

### Synthetic estimated-PD proxy thresholds

For lower-is-better risk thresholds:

```text
approve_max_estimated_pd_proxy
<
counteroffer_max_estimated_pd_proxy
<=
review_max_estimated_pd_proxy
<=
decline_min_estimated_pd_proxy
```

Locked default:

| Threshold | Default | Business behavior |
|---|---:|---|
| `approve_max_estimated_pd_proxy` | `0.1200` | Clean approval ceiling for low-to-moderate synthetic estimated-risk profiles |
| `counteroffer_max_estimated_pd_proxy` | `0.3000` | Maximum synthetic estimated-risk level eligible for reduced-exposure treatment |
| `review_max_estimated_pd_proxy` | `0.3500` | Upper boundary for simulated manual review |
| `decline_min_estimated_pd_proxy` | `0.3500` | Hard simulated risk stop at or above this level |

Business rationale:

```text
The 12% clean-approval ceiling keeps clean approvals concentrated in stronger and moderate-risk profiles.
The 30% counteroffer ceiling allows reduced exposure for elevated but not severe synthetic estimated-risk profiles.
The 35% hard-stop boundary creates a severe-risk region aligned to Module 1’s high-risk tail while preserving the synthetic proxy boundary.
```

Validation expectation:

```text
APPROVE book should have the lowest average synthetic estimated-PD proxy.
COUNTEROFFER book should be elevated versus clean approvals.
MANUAL_REVIEW should be intermediate / mixed.
DECLINE should generally have the highest synthetic estimated-PD proxy.
```

---

## 8.2 PTI thresholds

Product-specific PTI thresholds should override global defaults because Module 1 product behavior is intentionally product-aware.

Global defaults:

| Threshold | Default | Business behavior |
|---|---:|---|
| `global_approve_max_pti` | `0.2000` | Clean approval affordability ceiling before product override |
| `global_review_max_pti` | `0.5000` | Maximum review zone before hard unresolved affordability stop |
| `global_decline_min_pti` | `0.5000` | Severe affordability stress threshold |
| `counteroffer_target_pti` | Product-specific | Target approved PTI after exposure reduction |

Product-specific defaults:

| Product | Approve max PTI | Review max PTI | Decline min PTI | Counteroffer target PTI |
|---|---:|---:|---:|---:|
| `MORTGAGE` | `0.3600` | `0.5500` | `0.5500` | `0.3600` |
| `HELOC` | `0.2500` | `0.4500` | `0.4500` | `0.2500` |
| `AUTO_LOAN` | `0.1800` | `0.4000` | `0.4000` | `0.1800` |
| `UNSECURED_PERSONAL_LOAN` | `0.1600` | `0.3500` | `0.3500` | `0.1600` |
| `REVOLVING_LINE` | `0.1200` | `0.3000` | `0.3000` | `0.1200` |

Business rationale:

```text
Mortgage can support higher PTI than unsecured revolving because Module 1 mortgage structure uses long amortization and secured exposure.
Revolving and personal-loan PTI thresholds are tighter because shorter-term or unsecured payment burden can create faster affordability pressure.
HELOC sits between mortgage and revolving because it is secured but still line-like.
```

Validation expectation:

```text
High-PTI rows should show lower clean approval rates and higher review / counteroffer / decline rates.
Counteroffer rows should show lower approved PTI than original requested PTI.
Affordability reason codes should concentrate in high-PTI segments.
```

---

## 8.3 DTI thresholds

DTI is treated as a borrower-capacity signal, not something corrected by reducing the requested exposure in Module 2 v1.0.

Default:

| Threshold | Default | Business behavior |
|---|---:|---|
| `approve_max_dti` | `0.4300` | Clean approval existing-obligation capacity ceiling |
| `review_max_dti` | `0.6000` | Manual review zone for elevated existing obligations |
| `decline_min_dti` | `0.6000` | Hard capacity stop for severe DTI |

Business rationale:

```text
DTI captures existing debt burden from Module 1.
Unlike PTI, reducing the requested amount does not directly solve existing DTI in Module 2 v1.0.
Therefore high DTI routes to review or decline, not counteroffer by default.
```

Validation expectation:

```text
High-DTI applicants should concentrate in manual review and decline outcomes.
Clean approvals should show lower average DTI than declines.
```

---

## 8.4 Requested Expected Loss thresholds

Module 1 `expected_loss_amount` should be aliased as:

```text
requested_expected_loss_amount
```

Product-specific requested-exposure Expected Loss thresholds:

| Product | Clean approval max requested EL | Review / decline boundary | Approved EL cap |
|---|---:|---:|---:|
| `MORTGAGE` | `$15,000` | `$35,000` | `$15,000` |
| `HELOC` | `$10,000` | `$22,000` | `$10,000` |
| `AUTO_LOAN` | `$6,000` | `$12,000` | `$6,000` |
| `UNSECURED_PERSONAL_LOAN` | `$6,000` | `$12,000` | `$6,000` |
| `REVOLVING_LINE` | `$4,500` | `$9,000` | `$4,500` |

Business rationale:

```text
Expected Loss is exposure × synthetic estimated-PD proxy × LGD.
Large secured products can carry higher dollar EL tolerance because exposure is structurally larger.
Unsecured and revolving products receive lower EL limits because LGD is higher and exposure should be more tightly governed.
```

Validation expectation:

```text
Clean approvals should generally have lower requested-exposure Expected Loss.
Counteroffers should reduce approved-exposure Expected Loss versus requested-exposure Expected Loss.
Declines should show concentration in high requested-exposure Expected Loss and unresolved risk/exposure pressure.
```

---

## 8.5 Product exposure caps

Product-specific simulated approved exposure caps:

| Product | Minimum approved amount | Maximum approved amount | Counteroffer minimum % of requested | Max exposure reduction % |
|---|---:|---:|---:|---:|
| `MORTGAGE` | `$75,000` | `$1,000,000` | `80%` | `20%` |
| `HELOC` | `$10,000` | `$200,000` | `50%` | `50%` |
| `AUTO_LOAN` | `$5,000` | `$65,000` | `75%` | `25%` |
| `UNSECURED_PERSONAL_LOAN` | `$1,000` | `$35,000` | `50%` | `50%` |
| `REVOLVING_LINE` | `$1,000` | `$25,000` | `50%` | `50%` |

Business rationale:

```text
Mortgage and auto counteroffers are less flexible because the requested credit may be tied to a specific asset purchase.
Revolving, HELOC, and personal-loan exposures are more naturally line / amount adjustable in a simulation.
Product caps prevent approved exposure from simply mirroring requested amount when strategy appetite is lower.
```

Validation expectation:

```text
approved_amount must never exceed requested_amount.
COUNTEROFFER rows must show approved_amount < requested_amount.
Counteroffer amounts must remain above minimum viable product amounts and minimum requested-percentage rules.
```

---

## 8.6 Approval / review / decline bands

### Clean approval band

A row is eligible for `APPROVE` when:

```text
no hard policy stop
synthetic estimated-PD proxy <= product/global clean approval threshold
PTI <= product clean approval threshold
DTI <= clean approval threshold
requested_expected_loss_amount <= product clean approval EL threshold
requested_amount <= product max approved amount
```

### Counteroffer band

A row is eligible for `COUNTEROFFER` when:

```text
not hard decline
counteroffer_allowed_flag = TRUE
synthetic estimated-PD proxy <= counteroffer_max_estimated_pd_proxy
requested_amount, PTI, or requested_expected_loss_amount exceeds clean approval tolerance
a lower approved_amount can satisfy:
    product max approved amount
    counteroffer target PTI
    approved EL cap
    product minimum approved amount
    minimum viable counteroffer percentage
```

### Manual review band

A row is eligible for `MANUAL_REVIEW` when:

```text
not hard decline
not clean approval
not valid counteroffer
profile falls into a borderline or mixed-signal zone
```

Examples:

```text
borderline synthetic estimated-risk profile
borderline PTI
elevated DTI
large exposure but low synthetic estimated-risk profile
weak score / low PTI mixed-signal profile
strong score / high PTI mixed-signal profile
```

### Decline band

A row receives `DECLINE` when:

```text
hard policy stop exists
or severe synthetic estimated-risk threshold is reached
or severe affordability / DTI / EL / exposure issue is unresolved
or no viable counteroffer exists where one would be required
```

---

# 9. Compact strategy parameter dictionary

## 9.1 Strategy identity, source selection, and archive controls

| parameter_name | data_type | default_value | allowed_range | parameter_scope | product_applicability | purpose | gatekeeper_rule | business_interpretation |
|---|---|---:|---|---|---|---|---|---|
| `active_strategy_flag` | BOOLEAN | TRUE | TRUE/FALSE | Strategy run | All | Identifies active strategy row | Exactly one TRUE row | Ensures one governed strategy config drives the run |
| `module2_model_version` | TEXT | `V1.0` | Nonblank | Strategy run | All | Output version label | Non-null / nonblank | Separates Module 2 releases |
| `strategy_set_name` | TEXT | `MODULE2_BASELINE_STRATEGY_SET` | Nonblank | Strategy run | All | Strategy comparison family | Non-null / nonblank | Groups related downstream strategies |
| `strategy_name` | TEXT | `BASELINE_STRATEGY` | Nonblank | Strategy run | All | Specific simulated strategy | Non-null / nonblank | Identifies the downstream decision strategy |
| `strategy_version` | TEXT | `V1_0` | Nonblank | Strategy run | All | Versioned strategy config | Non-null / nonblank | Supports governed reruns and strategy comparison |
| `strategy_run_id` | TEXT | Generated | Nonblank | Audit | All | Run traceability | Generated or nonblank | Audit metadata; does not replace archive rerun key |
| `strategy_run_ts` | TIMESTAMP | `CURRENT_TIMESTAMP` | Valid timestamp | Audit | All | Run timestamp | Non-null in output | Audit metadata only |
| `module1_input_source` | TEXT | `LATEST` | `LATEST`, `ARCHIVE` | Source control | All | Selects Module 1 source table | Must be valid enum | Supports development from latest and comparison from archive |
| `source_module1_scenario_set_name` | TEXT | NULL | Nonblank if archive | Source control | All | Selects Module 1 scenario set | Required if source = `ARCHIVE` | Preserves upstream scenario lineage |
| `source_module1_scenario_name` | TEXT | NULL | Nonblank if archive | Source control | All | Selects Module 1 scenario | Required if source = `ARCHIVE` | Prevents scenario ambiguity |
| `source_population_id` | TEXT | NULL | Nonblank if archive | Source control | All | Selects deterministic population | Required if source = `ARCHIVE` | Enables matched strategy comparison |
| `archive_run_flag` | BOOLEAN | TRUE | TRUE/FALSE | Archive control | All | Controls archive persistence | Non-null | Determines whether run is archived |
| `strategy_archive_reset_mode` | TEXT | `STRATEGY_SCENARIO_ONLY` | `NONE`, `STRATEGY_SCENARIO_ONLY`, `STRATEGY_SET_ONLY`, `ALL` | Archive control | All | Controls archive replacement | Must be valid enum | Default replaces exact rerun key only |

---

## 9.2 Risk, affordability, DTI, and Expected Loss thresholds

| parameter_name | data_type | default_value | allowed_range | parameter_scope | product_applicability | purpose | gatekeeper_rule | business_interpretation |
|---|---|---:|---|---|---|---|---|---|
| `approve_max_estimated_pd_proxy` | NUMERIC | `0.1200` | `0`–`1` | Global | All | Clean approval synthetic estimated-risk ceiling | `< counteroffer_max_estimated_pd_proxy` | Low-to-moderate synthetic estimated-risk approval band |
| `counteroffer_max_estimated_pd_proxy` | NUMERIC | `0.3000` | `0`–`1` | Global | Counteroffer-eligible products | Maximum synthetic estimated-risk level for reduced exposure | `>= approve_max` and `<= review_max` | Allows partial approval only before severe-risk region |
| `review_max_estimated_pd_proxy` | NUMERIC | `0.3500` | `0`–`1` | Global | All | Manual-review synthetic estimated-risk ceiling | `<= decline_min` | Borderline risk review band |
| `decline_min_estimated_pd_proxy` | NUMERIC | `0.3500` | `0`–`1` | Global | All | Hard simulated risk stop | `>= review_max` | Severe synthetic estimated-risk region |
| `global_approve_max_pti` | NUMERIC | `0.2000` | `0`–`1.50` | Global | All | Default clean approval PTI ceiling | `< global_review_max_pti` | Default affordability approval limit |
| `global_review_max_pti` | NUMERIC | `0.5000` | `0`–`1.50` | Global | All | Default PTI review ceiling | `<= global_decline_min_pti` | Elevated but reviewable affordability stress |
| `global_decline_min_pti` | NUMERIC | `0.5000` | `0`–`1.50` | Global | All | Severe unresolved PTI stop | `>= global_review_max_pti` | Severe affordability stress |
| `approve_max_dti` | NUMERIC | `0.4300` | `0`–`1` | Global | All | Clean approval DTI ceiling | `< review_max_dti` | Existing-obligation capacity approval limit |
| `review_max_dti` | NUMERIC | `0.6000` | `0`–`1` | Global | All | DTI review ceiling | `<= decline_min_dti` | Elevated DTI review band |
| `decline_min_dti` | NUMERIC | `0.6000` | `0`–`1` | Global | All | Hard DTI stop | `>= review_max_dti` | Severe existing-obligation pressure |
| `product_approve_max_requested_el` | NUMERIC | Product matrix | `>= 0` | Product | Product-specific | Clean approval requested-exposure EL ceiling | `< product_review_max_requested_el` | Caps requested-exposure loss tolerance |
| `product_review_max_requested_el` | NUMERIC | Product matrix | `>= 0` | Product | Product-specific | Review / decline requested EL boundary | `<= product_decline_min_requested_el` | High requested-exposure EL review zone |
| `product_decline_min_requested_el` | NUMERIC | Product matrix | `>= 0` | Product | Product-specific | Hard unresolved requested EL stop | `>= product_review_max_requested_el` | Severe loss proxy pressure |
| `product_approved_el_cap` | NUMERIC | Product matrix | `>= 0` | Product | Product-specific | Approved-book EL cap after exposure treatment | Nonnegative | Ensures approved exposure respects simulated EL appetite |

---

## 9.3 Product exposure and counteroffer rules

| parameter_name | data_type | default_value | allowed_range | parameter_scope | product_applicability | purpose | gatekeeper_rule | business_interpretation |
|---|---|---:|---|---|---|---|---|---|
| `product_min_approved_amount` | NUMERIC | Product matrix | `> 0` | Product | Product-specific | Minimum viable approved exposure | `< product_max_approved_amount` | Prevents trivial or invalid approvals |
| `product_max_approved_amount` | NUMERIC | Product matrix | `> 0` | Product | Product-specific | Product exposure cap | `> product_min_approved_amount` | Simulated product-level exposure appetite |
| `counteroffer_allowed_flag` | BOOLEAN | TRUE | TRUE/FALSE | Product | Product-specific | Enables reduced-exposure treatment | Non-null | Allows product-aware partial approval simulation |
| `manual_review_allowed_flag` | BOOLEAN | TRUE | TRUE/FALSE | Product | Product-specific | Enables review routing | Non-null | Allows product-aware manual review |
| `product_min_counteroffer_pct` | NUMERIC | Product matrix | `0`–`1` | Product | Product-specific | Minimum counteroffer as % of request | `> 0` and `<= 1` | Prevents non-meaningful partial approvals |
| `product_max_exposure_reduction_pct` | NUMERIC | Product matrix | `0`–`1` | Product | Product-specific | Maximum allowed exposure reduction | `= 1 - min_counteroffer_pct` or coherent with it | Prevents excessive simulated reductions |
| `counteroffer_target_pti` | NUMERIC | Product matrix | `0`–`1.50` | Product | Product-specific | Target approved PTI after reduction | `<= product_approve_max_pti` | Counteroffer should improve affordability |
| `exposure_assignment_method` | TEXT | `MIN_OF_CAPS` | `MIN_OF_CAPS`, `AFFORDABILITY_BASED`, `EL_BASED`, `PRODUCT_CAP_ONLY` | Product | Product-specific | Chooses approved amount method | Valid enum | Keeps amount assignment explainable |
| `approved_amount_rounding_increment` | NUMERIC | `$100` | `>= 1` | Global/Product | All | Rounds approved amount | Positive | Avoids unnatural dollar precision |
| `allow_approved_amount_above_requested_flag` | BOOLEAN | FALSE | FALSE for v1.0 | Global | All | Controls over-request approvals | Must be FALSE in v1.0 | Preserves approved amount ≤ requested amount |

---

## 9.4 Decision convention and output consistency controls

| parameter_name | data_type | default_value | allowed_range | parameter_scope | product_applicability | purpose | gatekeeper_rule | business_interpretation |
|---|---|---:|---|---|---|---|---|---|
| `manual_review_approved_amount_convention` | TEXT | `NULL_UNRESOLVED` | `NULL_UNRESOLVED` | Global | All | Controls manual review amount treatment | Must equal `NULL_UNRESOLVED` in v1.0 | Manual review is unresolved, not booked |
| `decline_approved_amount_convention` | TEXT | `ZERO` | `ZERO` | Global | All | Controls decline amount treatment | Must equal `ZERO` | Declines have no approved exposure |
| `approve_reason_code` | TEXT | `APPROVED_AS_REQUESTED` | Nonblank | Global | All | Approval reason convention | Non-null | Every row remains explainable |
| `reason_code_required_flag` | BOOLEAN | TRUE | TRUE | Global | All | Requires reason population | Must be TRUE | No unexplained outcomes |
| `simulated_offer_exposure_flag_enabled` | BOOLEAN | TRUE | TRUE | Global | All | Enables offer-exposure reporting | Must be TRUE | APPROVE + COUNTEROFFER exposure reporting |
| `approved_el_decline_convention` | TEXT | `ZERO` | `ZERO` | Global | All | Decline approved EL treatment | Must equal `ZERO` | No approved exposure for declines |
| `approved_el_manual_review_convention` | TEXT | `NULL_UNRESOLVED` | `NULL_UNRESOLVED` | Global | All | Manual review approved EL treatment | Must equal `NULL_UNRESOLVED` | Unresolved exposure should not be treated as booked |

---

# 10. Strategy parameter gatekeeper requirements

The Module 2 SQL should fail fast before generating decision outcomes if any of the following fail.

## Parameter-cardinality gatekeepers

```text
exactly one active strategy parameter row
strategy_set_name non-null and nonblank
strategy_name non-null and nonblank
strategy_version non-null and nonblank
valid module2_model_version
valid strategy_run_id / strategy_run_ts generation
```

## Source-input gatekeepers

```text
module1_input_source in ('LATEST', 'ARCHIVE')
selected Module 1 source table contains rows
selected Module 1 source has no duplicate application_id values for the selected population / scenario
required Module 1 fields are present and non-null where required
if using Module 1 archive, exactly one Module 1 scenario is selected unless multi-scenario processing is explicitly designed
module1_scenario_set_name, module1_scenario_name, population_id are preserved in output
```

Required Module 1 input fields:

```text
application_id
applicant_id
product_type
score_band
requested_amount
annual_income
monthly_payment_proxy
payment_to_income_ratio
debt_to_income_ratio
estimated_pd
estimated_lgd
expected_loss_amount
population_id
scenario_set_name or module1_scenario_set_name
scenario_name or module1_scenario_name
```

## Threshold gatekeepers

```text
all synthetic estimated-PD proxy thresholds between 0 and 1
approve_max_estimated_pd_proxy < counteroffer_max_estimated_pd_proxy
counteroffer_max_estimated_pd_proxy <= review_max_estimated_pd_proxy
review_max_estimated_pd_proxy <= decline_min_estimated_pd_proxy

PTI thresholds within governed range
approve_max_pti < review_max_pti
review_max_pti <= decline_min_pti

DTI thresholds between 0 and 1
approve_max_dti < review_max_dti
review_max_dti <= decline_min_dti

Expected Loss thresholds nonnegative
product_approve_max_requested_el < product_review_max_requested_el
product_review_max_requested_el <= product_decline_min_requested_el
product_approved_el_cap <= product_approve_max_requested_el unless explicitly overridden
```

## Exposure and counteroffer gatekeepers

```text
product_min_approved_amount > 0
product_max_approved_amount > product_min_approved_amount
product_min_counteroffer_pct > 0 and <= 1
product_max_exposure_reduction_pct >= 0 and < 1
approved_amount cannot be negative
approved_amount cannot exceed requested_amount in v1.0
counteroffer_amount must equal approved_amount for COUNTEROFFER rows
counteroffer rows must have approved_amount < requested_amount
decline rows must have approved_amount = 0
manual review rows must have approved_amount IS NULL
approved_expected_loss_amount cannot be negative
```

## Archive gatekeepers

```text
strategy_archive_reset_mode is valid
archive replacement / rerun key is fully populated before archive insert
archive replacement key does not include application_id
row-level archive grain includes application_id
archive insert creates one row per application_id for the selected replacement key
```

---

# 11. Output consistency rules locked for v1.0

```text
Every row must have exactly one decision_outcome.

decision_outcome must be one of:
APPROVE, COUNTEROFFER, MANUAL_REVIEW, DECLINE.

approval_flag, decline_flag, manual_review_flag, and counteroffer_flag must reconcile to decision_outcome.

APPROVE and COUNTEROFFER remain distinguishable outcomes.

APPROVE and COUNTEROFFER both feed simulated_offer_exposure_flag = TRUE.

MANUAL_REVIEW and DECLINE feed simulated_offer_exposure_flag = FALSE.

approved_amount must not exceed requested_amount.

counteroffer_amount must equal approved_amount for COUNTEROFFER rows.

DECLINE rows must have approved_amount = 0.

MANUAL_REVIEW rows must have approved_amount IS NULL.

approved_expected_loss_amount must use approved exposure, not requested exposure.

Module 1 expected_loss_amount must remain available as requested_expected_loss_amount.
```

---

# 12. Reporting book definitions

| Reporting book | Definition | Main use |
|---|---|---|
| Approved-book profile | `decision_outcome = 'APPROVE'` | Clean approvals as requested |
| Counteroffer-book profile | `decision_outcome = 'COUNTEROFFER'` | Reduced-exposure / partial approval simulation |
| Manual-review-book profile | `decision_outcome = 'MANUAL_REVIEW'` | Unresolved borderline profiles |
| Declined-book profile | `decision_outcome = 'DECLINE'` | Simulated policy-stop population |
| Offer-exposure book | `simulated_offer_exposure_flag = TRUE` | APPROVE + COUNTEROFFER exposure summaries |

Offer-exposure reporting must be described as simulated strategy exposure, not real account booking.

---

# 13. Renamed workstream

Use:

```text
Validation, QA, and Strategy Tuning Pass
```

Avoid:

```text
Validation and calibration pass
risk recalibration
```

Module 2 v1.0 tunes simulated strategy behavior. It does not calibrate real-world underwriting performance.

---

# 14. First SQL build step only

The first SQL build step should be:

```text
Build Module 2 Sections 0–3 only:
schema setup, clean latest-run reset, strategy parameter tables,
product policy parameter table, and fail-fast gatekeeper.
```

Do not build decision logic yet.

This first build should establish:

```text
credit_decisioning_sim schema reuse
drop / recreate latest-run strategy_decisions placeholder only if appropriate
tmp_module2_strategy_params
tmp_module2_product_policy_params
parameter-cardinality gatekeeper
strategy identity gatekeeper
source-selection gatekeeper
threshold-ordering gatekeeper
exposure-rule gatekeeper
archive-control gatekeeper
```

Once that passes cleanly, the next step will be the Module 1 source-selection and lineage-normalization layer.
<!-- END_MESSAGE C038-M00037 -->


---

<a id="c038-m00039"></a>

### C038-M00039

**Andrew** · 2026-05-06T11:00:16.831000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00039 -->
This is directionally strong. I agree with the locked architecture, naming convention, decision outcome taxonomy, amount / Expected Loss conventions, reason-code framing, threshold hierarchy, parameter dictionary direction, and the recommendation that the first SQL build should be Sections 0–3 only.

Let’s proceed to the first SQL build, but please follow the constraints below exactly.

Do not build decision logic yet.

================================================================================
1. CONFIRMED LOCKED DESIGN
================================================================================

Please treat the following as locked for Module 2 v1.0:

1. Physical architecture
   - latest-run table:
     credit_decisioning_sim.strategy_decisions

   - archive table:
     credit_decisioning_sim.strategy_decisions_archive

2. Archive grain
   one row per application × Module 1 scenario × Module 2 strategy version

3. Archive grain fields
   - strategy_set_name
   - strategy_name
   - strategy_version
   - module1_scenario_set_name
   - module1_scenario_name
   - population_id
   - application_id

4. Archive replacement / rerun key
   - strategy_set_name
   - strategy_name
   - strategy_version
   - module1_scenario_set_name
   - module1_scenario_name
   - population_id

   The row-level archive grain additionally includes application_id.

5. Module 1 scenario metadata
   - module1_scenario_set_name
   - module1_scenario_name
   - population_id

6. Module 2 strategy metadata
   - strategy_set_name
   - strategy_name
   - strategy_version
   - strategy_run_id
   - strategy_run_ts

7. Decision outcome taxonomy
   Use exactly:
   - APPROVE
   - COUNTEROFFER
   - MANUAL_REVIEW
   - DECLINE

8. Counteroffer treatment
   COUNTEROFFER is a distinct decision_outcome.
   More detailed counteroffer type belongs in decision_path.

9. Manual review treatment
   MANUAL_REVIEW is unresolved by design:
   - approved_amount = NULL
   - approved_expected_loss_amount = NULL
   - approved_monthly_payment_proxy = NULL
   - approved_payment_to_income_ratio = NULL

10. Estimated-PD proxy boundary
    Module 2 consumes Module 1 estimated_pd as the finalized synthetic estimated-PD proxy.
    Module 2 does not recalculate estimated_pd and does not create a new post-decision risk model in v1.0.

11. Reason-code boundary
    Reason codes are simulated strategy explanation codes.
    They are not regulatory adverse-action reason codes.

12. Language boundary
    Use neutral simulation language:
    - hard simulated policy stop rules
    - simulated policy exclusion rules
    - policy stop reason
    - review trigger reason
    - counteroffer reason

    Avoid:
    - adverse-action terminology
    - production underwriting language
    - booked-account language

================================================================================
2. FIRST SQL BUILD SCOPE
================================================================================

Build only Module 2 SQL Sections 0–3.

The first SQL build should include:

Section 0:
- Executive purpose header
- Module 2 boundary notes
- Estimated-PD proxy terminology note
- Relationship to Module 1
- High-level SQL section map
- Explicit note that Module 2 v1.0 does not recalculate estimated_pd
- Explicit note that reason codes are simulated strategy explanation codes, not regulatory adverse-action reasons
- Explicit note that approved exposure is simulated offer exposure, not booked exposure

Section 1:
- Schema setup / schema reuse
- Clean reset of temporary Module 2 objects
- Drop latest-run output table only if appropriate for clean rerun
- Do not drop the archive table by default
- Do not create final decision output logic yet

Section 2:
- Strategy parameter framework
- Product policy parameter framework
- Strategy identity parameters
- Module 1 source selection parameters
- Archive control parameters
- Threshold parameters
- Product exposure / counteroffer parameters
- Decision convention parameters

Section 3:
- Fail-fast strategy parameter gatekeeper
- Parameter-cardinality validation
- Source-input validation
- Product-policy parameter validation
- Threshold-ordering validation
- Exposure / counteroffer validation
- Archive-control validation
- Output-convention validation

Do not build:
- Module 1 source-selection staging table
- derived strategy segments
- rule flags
- decision hierarchy
- reason-code assignment
- approved exposure calculation
- approved Expected Loss calculation
- latest-run final output table
- archive insert logic
- QA queries

Those come later.

================================================================================
3. PARAMETER TABLE DESIGN
================================================================================

Use temporary parameter tables for the first build.

Recommended parameter tables:

1. tmp_module2_strategy_params
   One active row for the selected strategy run.

2. tmp_module2_product_policy_params
   One row per supported product type.

Use Module 1’s product set:
- MORTGAGE
- HELOC
- AUTO_LOAN
- UNSECURED_PERSONAL_LOAN
- REVOLVING_LINE

The first build should ensure the parameter structure is complete enough to support later strategy logic, even though decision logic is not built yet.

================================================================================
4. REQUIRED STRATEGY PARAMETER FIELDS
================================================================================

At minimum, tmp_module2_strategy_params should include:

Strategy identity:
- active_strategy_flag
- module2_model_version
- strategy_set_name
- strategy_name
- strategy_version
- strategy_run_id
- strategy_run_ts

Module 1 source selection:
- module1_input_source
- source_module1_scenario_set_name
- source_module1_scenario_name
- source_population_id

Archive controls:
- archive_run_flag
- strategy_archive_reset_mode

Global estimated-risk thresholds:
- approve_max_estimated_pd_proxy
- counteroffer_max_estimated_pd_proxy
- review_max_estimated_pd_proxy
- decline_min_estimated_pd_proxy

Global PTI thresholds:
- global_approve_max_pti
- global_review_max_pti
- global_decline_min_pti

DTI thresholds:
- approve_max_dti
- review_max_dti
- decline_min_dti

Decision convention controls:
- approve_reason_code
- reason_code_required_flag
- simulated_offer_exposure_flag_enabled
- manual_review_approved_amount_convention
- decline_approved_amount_convention
- approved_el_decline_convention
- approved_el_manual_review_convention
- allow_approved_amount_above_requested_flag

================================================================================
5. REQUIRED PRODUCT POLICY PARAMETER FIELDS
================================================================================

At minimum, tmp_module2_product_policy_params should include:

Product identity:
- product_type

Product-specific PTI thresholds:
- product_approve_max_pti
- product_review_max_pti
- product_decline_min_pti
- counteroffer_target_pti

Requested Expected Loss thresholds:
- product_approve_max_requested_el
- product_review_max_requested_el
- product_decline_min_requested_el
- product_approved_el_cap

Approved exposure limits:
- product_min_approved_amount
- product_max_approved_amount

Counteroffer controls:
- counteroffer_allowed_flag
- manual_review_allowed_flag
- product_min_counteroffer_pct
- product_max_exposure_reduction_pct
- exposure_assignment_method

Other:
- approved_amount_rounding_increment

================================================================================
6. THRESHOLD EQUALITY RULES
================================================================================

Please explicitly document threshold equality handling in Section 3 comments.

Use this convention unless you see a strong reason to recommend otherwise:

Estimated-PD proxy:
- APPROVE if estimated_pd <= approve_max_estimated_pd_proxy
- COUNTEROFFER eligibility if estimated_pd > approve_max_estimated_pd_proxy
  and estimated_pd <= counteroffer_max_estimated_pd_proxy
- MANUAL_REVIEW if estimated_pd > counteroffer_max_estimated_pd_proxy
  and estimated_pd < decline_min_estimated_pd_proxy
- DECLINE if estimated_pd >= decline_min_estimated_pd_proxy

PTI:
- APPROVE if PTI <= product_approve_max_pti
- COUNTEROFFER eligibility if PTI > product_approve_max_pti and counteroffer can reduce approved PTI to target
- MANUAL_REVIEW if PTI > product_approve_max_pti and PTI < product_decline_min_pti where counteroffer is not cleanly viable
- DECLINE if PTI >= product_decline_min_pti and no viable counteroffer or review path is intended

DTI:
- APPROVE if DTI <= approve_max_dti
- MANUAL_REVIEW if DTI > approve_max_dti and DTI < decline_min_dti
- DECLINE if DTI >= decline_min_dti

Expected Loss:
- clean approval must satisfy product_approve_max_requested_el
- counteroffer may be considered when requested_expected_loss_amount exceeds clean approval tolerance but approved_expected_loss_amount can satisfy product_approved_el_cap
- decline / review boundary should use product_decline_min_requested_el and strategy hierarchy

This equality convention should be documented now so later CASE logic is not ambiguous.

================================================================================
7. DEFAULT THRESHOLDS
================================================================================

Use the default thresholds you recommended as initial simulated strategy defaults, not production policy.

Please include comments that these are:
- synthetic strategy defaults
- intended for simulation
- expected to be tuned through QA and validation
- not production underwriting policy
- not empirically calibrated cutoffs

If you need to slightly adjust any recommended default for internal consistency, explain the adjustment before coding it.

================================================================================
8. SOURCE-INPUT GATEKEEPERS
================================================================================

Section 3 should validate source inputs before any decision logic is built.

Gatekeepers should check:

- module1_input_source is one of:
  LATEST
  ARCHIVE

If module1_input_source = LATEST:
- credit_decisioning_sim.synthetic_applications exists
- source table contains rows
- required Module 1 fields are present
- required Module 1 fields are non-null where required
- selected latest-run table represents exactly one Module 1 scenario / population unless multi-scenario processing is explicitly designed later
- no duplicate application_id values exist for the selected latest-run population / scenario

If module1_input_source = ARCHIVE:
- credit_decisioning_sim.synthetic_applications_scenario_archive exists
- source_module1_scenario_set_name is non-null and nonblank
- source_module1_scenario_name is non-null and nonblank
- source_population_id is non-null and nonblank
- exactly one Module 1 scenario is selected unless multi-scenario processing is explicitly designed later
- selected archive slice contains rows
- selected archive slice has no duplicate application_id values
- required Module 1 fields are present
- required Module 1 fields are non-null where required

Required Module 1 fields should include at least:
- application_id
- applicant_id
- product_type
- score_band
- credit_score
- requested_amount
- annual_income
- monthly_payment_proxy
- payment_to_income_ratio
- debt_to_income_ratio
- estimated_pd
- estimated_lgd
- expected_loss_amount
- population_id
- scenario_set_name or module1_scenario_set_name
- scenario_name or module1_scenario_name

Important:
For Module 2 output naming, source scenario_set_name should be aliased as module1_scenario_set_name, and source scenario_name should be aliased as module1_scenario_name in later source-selection logic.

================================================================================
9. PRODUCT-POLICY PARAMETER GATEKEEPERS
================================================================================

Section 3 should validate:

- exactly one product policy row per supported product type
- no unsupported product types
- no duplicate product_type rows
- all required product policy thresholds are non-null
- product_min_approved_amount > 0
- product_max_approved_amount > product_min_approved_amount
- product_min_counteroffer_pct between 0 and 1
- product_max_exposure_reduction_pct between 0 and 1
- counteroffer_target_pti between 0 and 1.5
- product_approve_max_pti < product_review_max_pti
- product_review_max_pti <= product_decline_min_pti
- requested Expected Loss thresholds are non-negative
- product_approve_max_requested_el <= product_review_max_requested_el
- product_review_max_requested_el <= product_decline_min_requested_el
- product_approved_el_cap is non-negative
- approved_amount_rounding_increment > 0

================================================================================
10. STRATEGY PARAMETER GATEKEEPERS
================================================================================

Section 3 should validate:

- exactly one active strategy parameter row
- strategy_set_name is non-null and nonblank
- strategy_name is non-null and nonblank
- strategy_version is non-null and nonblank
- module2_model_version is non-null and nonblank
- strategy_run_id is non-null and nonblank
- strategy_run_ts is non-null
- archive_run_flag is not null
- strategy_archive_reset_mode is one of:
  NONE
  STRATEGY_SCENARIO_ONLY
  STRATEGY_SET_ONLY
  ALL

Estimated-PD proxy thresholds:
- all values between 0 and 1
- approve_max_estimated_pd_proxy < counteroffer_max_estimated_pd_proxy
- counteroffer_max_estimated_pd_proxy <= review_max_estimated_pd_proxy
- review_max_estimated_pd_proxy <= decline_min_estimated_pd_proxy

PTI thresholds:
- all values between 0 and 1.5
- global_approve_max_pti < global_review_max_pti
- global_review_max_pti <= global_decline_min_pti

DTI thresholds:
- all values between 0 and 1
- approve_max_dti < review_max_dti
- review_max_dti <= decline_min_dti

Decision convention controls:
- allow_approved_amount_above_requested_flag = FALSE for Module 2 v1.0
- decline_approved_amount_convention = ZERO
- manual_review_approved_amount_convention = NULL_UNRESOLVED
- approved_el_decline_convention = ZERO
- approved_el_manual_review_convention = NULL_UNRESOLVED
- reason_code_required_flag = TRUE

================================================================================
11. OUTPUT TERMINOLOGY AND CONVENTIONS TO PRESERVE
================================================================================

Even though the final output table will be built later, Section 0 / comments should lock these terminology conventions:

Module 1 expected_loss_amount should be carried into Module 2 as:
- requested_expected_loss_amount

Module 2 calculated Expected Loss should be:
- approved_expected_loss_amount

Module 1 payment_to_income_ratio should remain the original requested-structure PTI.

Module 2 calculated payment-to-income ratio should be:
- approved_payment_to_income_ratio

Do not introduce a separate approved_pti field unless explicitly used as a documented alias.
Preferred output field:
- approved_payment_to_income_ratio

Use:
- simulated_offer_exposure_flag

Do not use:
- booked_exposure_flag

Reason:
“booked” can imply real account booking, which is outside the Module 2 simulation boundary.

Outcome conventions to preserve for later Sections 4+:

APPROVE:
- approved_amount = requested_amount
- counteroffer_amount = NULL
- approved_monthly_payment_proxy = monthly_payment_proxy
- approved_payment_to_income_ratio = payment_to_income_ratio
- approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd
- simulated_offer_exposure_flag = TRUE
- primary_reason_code = APPROVED_AS_REQUESTED

COUNTEROFFER:
- approved_amount < requested_amount
- counteroffer_amount = approved_amount
- exposure_reduction_flag = TRUE
- exposure_reduction_amount = requested_amount - approved_amount
- exposure_reduction_pct = exposure_reduction_amount / NULLIF(requested_amount, 0)
- approved_monthly_payment_proxy = monthly_payment_proxy × approved_amount / NULLIF(requested_amount, 0)
- approved_payment_to_income_ratio = approved_monthly_payment_proxy / NULLIF((annual_income / 12.0), 0)
- approved_expected_loss_amount = approved_amount × estimated_pd × estimated_lgd
- simulated_offer_exposure_flag = TRUE

DECLINE:
- approved_amount = 0
- counteroffer_amount = NULL
- approved_monthly_payment_proxy = 0
- approved_payment_to_income_ratio = 0
- approved_expected_loss_amount = 0
- simulated_offer_exposure_flag = FALSE

MANUAL_REVIEW:
- approved_amount = NULL
- counteroffer_amount = NULL
- approved_monthly_payment_proxy = NULL
- approved_payment_to_income_ratio = NULL
- approved_expected_loss_amount = NULL
- simulated_offer_exposure_flag = FALSE
- unresolved by design

================================================================================
12. SQL COMMENTARY QUALITY
================================================================================

The SQL must match Module 1 commentary quality.

Please include comments explaining:

- business purpose
- SQL purpose
- why each parameter family exists
- why each gatekeeper exists
- what each threshold family controls
- why Module 2 does not recalculate estimated_pd
- why reason codes are simulated strategy explanation codes, not adverse-action reasons
- why approved amount and approved Expected Loss are simulation outputs
- why source selection must preserve Module 1 lineage
- why simulated_offer_exposure_flag is used instead of booked_exposure_flag

No silent assumptions.
No unexplained magic numbers.
No generic comments.

================================================================================
13. DELIVERABLE FOR THIS NEXT STEP
================================================================================

Please now write the first SQL build only:

Module 2 Sections 0–3.

Do not write Sections 4+ yet.

The output should be a coherent SQL script section that can become the beginning of:

module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql

After the SQL, briefly list:
- what this first build establishes
- what it intentionally does not yet build
- what the next build step should be
<!-- END_MESSAGE C038-M00039 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Next](Part_02.md)
