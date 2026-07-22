# Enterprise Credit Decisioning Strategy Simulator

## Strategic Intent: Governed Credit Strategy Simulation Without PII

How do you test credit policy, affordability, exposure, expected-loss, counteroffer strategy, and decision-outcome tradeoffs before changing a real credit decisioning system?

I built this project as a two-module, portfolio-grade credit decisioning simulator with an interactive Power BI release-validation layer. It demonstrates how synthetic application generation, governed scenario design, strategy controls, archive-backed comparison, independent reconciliation, validation evidence, and executive-ready reporting can work together in a controlled pre-production environment.

This is not a dashboard-only project. The core system is implemented as governed SQL decision infrastructure; Power BI extends that foundation into an interactive semantic model that connects executive release conclusions to variable- and application-level evidence without exposing PII or using real applicant data.

---

## Repository Navigation

For a detailed file-by-file guide, see:

[`PROJECT_ARTIFACT_MAP.md`](./PROJECT_ARTIFACT_MAP.md)

The artifact map explains the repository structure, current vs historical artifacts, module documentation, sample data, QA outputs, and recommended reviewer paths.

---

## Executive System Overview

The simulator is organized into two completed technical modules:

| Module | Purpose | Core Question |
|---|---|---|
| **Module 1: Synthetic Application & Risk Modeling Engine** | Builds a deterministic synthetic application population, product / score risk surface, scenario archive, and Expected Loss framework. | *Can we create a realistic, governed synthetic risk foundation for strategy testing?* |
| **Module 2: Credit Policy Strategy & Decision Outcome Simulation Engine** | Applies configurable credit strategy controls to Module 1 populations, assigns simulated outcomes, persists archives, compares strategies, and captures evidence. | *How do governed strategy choices move access, exposure, Expected Loss, counteroffers, reviews, and declines?* |

Together, the modules simulate the upstream and downstream credit decisioning chain:

```text
Synthetic Application Population
→ Product / Score / Borrower Profile
→ APR Proxy / Payment / PTI
→ Synthetic Estimated-PD Proxy / LGD / Expected Loss
→ Strategy Controls
→ Product Policy Controls
→ Counteroffer Feasibility
→ Final Simulated Outcome
→ Archive Persistence
→ Matched Comparison
→ Validation Evidence
→ Power BI Release Validation
→ Executive and Application-Level Evidence
```

### Delivery and Evidence Layers

| Layer | Technology | Role |
|---|---|---|
| Simulation, persistence, and embedded QA | **PostgreSQL** | Generates deterministic synthetic populations, executes governed strategy logic, persists archives, and captures validation evidence. |
| Independent release reconciliation | **SAS** | Reconciles final Module 1 V1.0 and V2.0 outputs at the application and variable levels. |
| Interactive validation and reporting | **Power BI Desktop** | Uses Power Query, a relational semantic model, DAX, conditional formatting, and dynamic narratives to connect portfolio-level release conclusions to application-level evidence. |

---

## Module 1: Synthetic Application & Risk Modeling Engine

[![Module 1 Executive Dashboard](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png)](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png)

[Open Module 1 dashboard full size](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png)

**Module 1 builds the governed synthetic risk foundation.**

It creates a deterministic, product-aware, score-aware synthetic application population and models the structural chain from requested exposure through affordability and Expected Loss.

```text
Application
→ Product Structure
→ APR Proxy
→ Monthly Payment Proxy
→ Payment-to-Income Ratio
→ Synthetic Estimated-PD Proxy
→ LGD
→ Expected Loss
```

### Dashboard Evidence

#### 1. Baseline Product × Score Risk Surface

The baseline portfolio is differentiated across both product structure and score quality. Expected Loss is not just a score metric; it is shaped by exposure size, product structure, LGD, affordability, and the synthetic estimated-PD proxy.

#### 2. Scenario Lever Matrix

Module 1 is not only a rate-shock engine. It supports multiple governed scenario families:

- rate environment
- credit-box mix
- exposure intensity
- LGD severity
- portfolio mix

Each scenario is compared against its family reference slice so scenario movement is interpretable.

#### 3. Scenario Expected-Loss Impact Decomposition

Scenario movement can be decomposed into product-level and product × score drivers, allowing reviewers to understand where risk movement concentrates rather than only seeing aggregate portfolio deltas.

### Module 1 Campaign Scope

```text
19 governed scenarios
50,000 applications each
950,000 archived scenario rows
BASE_POPULATION_V1 matched population discipline
```

### Interactive V1.0 → V2.0 Release Validation in Power BI

To operationalize the automated release-validation layer contemplated in the Module 1 roadmap, I built a Power BI Desktop report that combines the final V1.0 and V2.0 synthetic application outputs with independent SAS reconciliation evidence.

The report preserves the complete 50,000-application denominator and keeps two concepts distinct:

- **21,326 applications affected** by one or more functional changes
- **58,382 application-variable difference records** across seven changed functional variables

[Download the interactive Power BI report](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Module1_V1_V2_Release_Validation.pbix) *(requires Power BI Desktop)*

#### Power BI Executive Summary

[![Module 1 Power BI Release Validation Executive Summary](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png)](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png)

[Open the Power BI Executive Summary preview full size](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png)

The Executive Summary provides a portfolio-level release view with matched-population controls, affected and unaffected application counts, application change rate, variable-change records, and functional changes by variable.

#### Power BI Release Impact Explorer

[![Module 1 Power BI Release Impact Explorer](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png)](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png)

[Open the Power BI Release Impact Explorer preview full size](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png)

The Release Impact Explorer supports Application ID lookup, borrower-context review, V1.0-to-V2.0 functional reconciliation, direction-based conditional formatting, and a dynamic DAX analyst interpretation tied to documented V2.0 workstream themes.

#### Power BI Implementation Highlights

- **Power Query:** ingested and typed the raw V1.0 and V2.0 files, remediated text-formatted numeric fields, merged releases one-to-one on `Application_ID`, calculated row-level deltas and change flags, and preserved staging-query lineage.
- **Semantic model:** related a 50,000-row application comparison fact to a 58,382-row application × changed-variable detail fact using an active `1:*` single-direction relationship.
- **DAX:** created governed KPI measures for matched applications, affected and unaffected populations, change rate, variable-change records, and dynamic application-level analyst interpretation.
- **Report design:** developed separate executive and analyst experiences using KPI cards, interactive input slicers, cross-filtering, conditional formatting, and application-level traceability.
- **Validation discipline:** reconciled every major Power BI metric to the independently verified SAS controls before treating the report as complete.

### Module 1 Anchor Artifacts

| Artifact | Location |
|---|---|
| Module 1 v2.0 BRD | [`Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0.pdf`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0.pdf) |
| Module 1 v2.0 SQL | [`module1_synthetic_application_risk_engine_v2.0.sql`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/src/module1_synthetic_application_risk_engine_v2.0.sql) |
| Module 1 v2.0 Validation Summary | [`Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0.pdf`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0.pdf) |
| Module 1 Executive Dashboard | [`module1_executive_dashboard_preview.png`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png) |
| Power BI Release-Validation Report | [`Module1_V1_V2_Release_Validation.pbix`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Module1_V1_V2_Release_Validation.pbix) |
| Power BI Executive Summary Preview | [`module1_v1_v2_release_validation_executive_summary.png`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png) |
| Power BI Release Impact Explorer Preview | [`module1_v1_v2_release_impact_explorer.png`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png) |
| Module 1 Final Synthetic Applications Sample | [`module1_synthetic_application_risk_engine_v2.0_OUTPUT_synthetic_applications.csv`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/outputs/module1_synthetic_application_risk_engine_v2.0_OUTPUT_synthetic_applications.csv) |
| Module 1 Scenario Archive Sample | [`module1_synthetic_application_risk_engine_v2.0_OUTPUT_RANDOM_SAMPLE_synthetic_applications_scenario_archive.csv`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/outputs/module1_synthetic_application_risk_engine_v2.0_OUTPUT_RANDOM_SAMPLE_synthetic_applications_scenario_archive.csv) |

---

## Module 2: Credit Policy Strategy & Decision Outcome Simulation Engine

### Enterprise Architecture

[![Enterprise Credit Decisioning Strategy Module 2 Architecture](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png)](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png)

[Open the Module 2 enterprise architecture full size](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png)

The architecture maps the complete Module 2 SQL flow across five connected layers:

```text
Input Foundation
→ Strategy Controls
→ Decision Logic Engine
→ Final Outcomes
→ Governance, Evidence, and Reuse
```

It connects the Module 1 source population to strategy profiles, policy thresholds, product guardrails, counteroffer controls, diagnostic segmentation, rule triggers, routing, exposure treatment, final outcome resolution, reason-code assignment, archive persistence, matched comparison, validation QA, frontier analysis, and evidence capture.

### Executive Dashboard

[![Module 2 Executive Dashboard](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png)](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png)

[Open Module 2 dashboard full size](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png)

**Module 2 applies governed strategy controls to the Module 1 risk foundation.**

It simulates how different credit strategy postures affect offer exposure, approved amount, approved Expected Loss, counteroffer treatment, manual-review burden, decline routing, and explanation-code transparency.

```text
Module 1 Applicant / Product / Risk Profile
→ Module 2 Strategy Controls
→ Product Policy Controls
→ Diagnostic Segmentation
→ Rule Trigger Flags
→ Ordinary vs Aggressive Counteroffer Path Evidence
→ Preliminary Routing
→ Approved Exposure and Counteroffer Feasibility
→ Final Simulated Outcome
→ Simulated Strategy Explanation Codes
→ Latest-Run Output
→ Archive Persistence
→ Matched Strategy Comparison
→ Validation / QA Evidence
→ Strategy Frontier Summary
→ Executive Evidence Capture
→ Post-Campaign Acceptance
```

### Dashboard Evidence

#### 1. Strategy Frontier

The frontier chart shows where representative strategies sit on access versus approved Expected-Loss density.

This makes the strategy tradeoff visible:

```text
More access
vs.
approved-risk density
```

#### 2. Baseline-Relative Tradeoffs

The baseline-relative view shows how selected challenger strategies move:

- simulated offer exposure
- approved amount
- approved Expected Loss

relative to the M2-01 baseline on the same `BASELINE_V2` synthetic applicant population.

#### 3. Counteroffer Governance

The counteroffer governance section shows the operational split between:

- selective counteroffer feasibility
- aggressive counteroffer expansion

It illustrates how selective feasibility reduces counteroffer / offer exposure and shifts borderline cases to manual review, while aggressive expansion routes more severe requested structures through governed feasibility safeguards.

### Module 2 Campaign Scope

```text
39 governed strategy runs
50,000 applicants each
1.95M archived strategy decisions
20 matched comparison groups
7 scenario families
```

### Module 2 Anchor Artifacts

| Artifact | Location |
|---|---|
| Module 2 Enterprise Architecture | [`Enterprise Credit Decisioning Strategy Module 2 Architecture.png`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png) |
| Module 2 v1.0 SQL | [`module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql) |
| Module 2 Executive Dashboard | [`module2_executive_dashboard_preview.png`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png) |
| Module 2 Strategy Decisions Archive Sample | [`module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_RANDOM_SAMPLE_strategy_decisions_archive.csv`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_RANDOM_SAMPLE_strategy_decisions_archive.csv) |
| Module 2 M2-01 Latest-Run Strategy Decisions Sample | [`module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_RANDOM_SAMPLE_strategy_decisions_m2_01.csv`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_RANDOM_SAMPLE_strategy_decisions_m2_01.csv) |
| Module 2 Strategy Run Campaign Registry | [`module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_campaign_registry.csv`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_campaign_registry.csv) |
| Module 2 Strategy Comparison Campaign Registry | [`module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_comparison_campaign_registry.csv`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_comparison_campaign_registry.csv) |
| Module 2 BRD Placeholder | [`module2_brd_placeholder_coming_soon`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_brd_placeholder_coming_soon) |
| Module 2 Validation Summary Placeholder | [`module2_validation_summary_placeholder_coming_soon`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/module2_validation_summary_placeholder_coming_soon) |

---

## Decisioning Framework

This project is designed around a staged decision-system architecture rather than a single opaque output table.

### 1. Synthetic Risk Foundation

Module 1 creates a governed synthetic application population with:

- product type
- score band
- borrower profile variables
- requested amount
- APR proxy
- monthly payment proxy
- payment-to-income ratio
- amount-to-income ratio
- synthetic estimated-PD proxy
- LGD
- Expected Loss
- scenario archive outputs
- matched scenario comparison support

### 2. Strategy Simulation Layer

Module 2 consumes Module 1 outputs and applies:

- strategy profile selection
- product policy controls
- segmentation logic
- rule trigger flags
- preliminary routing
- counteroffer feasibility
- approved exposure treatment
- final simulated outcomes
- simulated reason codes
- archive persistence
- matched strategy comparison
- validation and executive evidence capture

### 3. Archive-Backed Comparison

Both modules preserve archive outputs so strategy and scenario movement can be reviewed without relying on one-off extracts.

The design emphasizes:

- matched population discipline
- deterministic reproducibility
- explicit lineage fields
- latest-run versus archive separation
- governed rerun / replacement keys
- persistent evidence tables
- validation-ready diagnostics
- post-campaign acceptance checks

---

## Executive Interpretation

### Credit strategy is not a score cutoff.

The project shows how borrower profile, product structure, affordability, exposure, LGD, and strategy posture interact to create final simulated outcomes.

### Synthetic does not mean simplistic.

The Module 1 population is deterministic, product-aware, score-aware, scenario-capable, and structured to support controlled comparisons without real applicant data.

### Strategy tradeoffs are measurable.

Module 2 makes access, approved exposure, approved Expected Loss, counteroffer usage, manual review, decline routing, and reason-code movement visible in one governed framework.

### Matched comparison prevents false conclusions.

Strategy comparisons hold Module 1 scenario and population constant so downstream movement can be interpreted as strategy effect rather than source-population drift.

### Evidence matters as much as output.

The system includes QA, archive inventory, frontier summaries, parameter snapshots, segment evidence, validation evidence, and final acceptance checks.

---

## Technical Rigor and Architecture

- **PostgreSQL-first simulation engine**  
  The core system is built in SQL to demonstrate enterprise-style decision logic, staging, archive persistence, comparison, and evidence capture.

- **Staged architecture over monolithic logic**  
  The pipeline separates source staging, segmentation, rule flags, routing, exposure treatment, final decision resolution, reason-code assignment, archive persistence, comparison, QA, and evidence capture.

- **Latest-run plus archive pattern**  
  Both modules distinguish replaceable current-run output from governed archive history.

- **Deterministic reproducibility**  
  Module 1 uses stable population identifiers and deterministic logic to support apples-to-apples scenario comparison.

- **Transparent strategy controls**  
  Module 2 uses governed strategy and product-policy profiles rather than hidden ad hoc logic.

- **Matched comparison discipline**  
  Baseline and challenger comparisons preserve Module 1 source-field consistency so observed deltas isolate downstream strategy movement.

- **Power BI semantic and validation layer**  
  Power Query integrates final release outputs and SAS reconciliation evidence; a controlled one-to-many semantic model and centralized DAX measures support executive KPIs, application-level traceability, conditional formatting, interactive lookup, and dynamic analyst interpretation.

- **Validation and acceptance discipline**  
  QA and acceptance sections check row grain, lineage, archive completeness, convention integrity, evidence coverage, comparison readiness, source consistency, parameter snapshots, product-policy audit behavior, and source-to-report reconciliation.

---

## Repository Map

```text
credit_decisioning_strategy/
│
├── README.md
├── PROJECT_ARTIFACT_MAP.md
│
├── Module_1_Synthetic_Application_&_Risk_Modeling_Engine/
│   ├── v1.0/
│   │   ├── docs/
│   │   ├── outputs/
│   │   ├── src/
│   │   └── tests/
│   │
│   └── v2.0/
│       ├── docs/
│       ├── outputs/
│       ├── src/
│       └── tests/
│           ├── Module1_V1_V2_Release_Validation.pbix
│           ├── module1_v1_v2_release_validation_executive_summary.png
│           ├── module1_v1_v2_release_impact_explorer.png
│           └── review_queries/
│
└── Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/
    └── v1.0/
        ├── docs/
        │   ├── Enterprise Credit Decisioning Strategy Module 2 Architecture.png
        │   └── module2_executive_dashboard_preview.png
        ├── outputs/
        ├── src/
        └── tests/
```

For the full repository navigation guide, see:

[`PROJECT_ARTIFACT_MAP.md`](./PROJECT_ARTIFACT_MAP.md)

---

## Suggested Reviewer Paths

### Fast Executive Review

Use this path to understand the system story, release evidence, and current artifact status.

1. Read this root `README.md`.
2. Open the Module 1 executive dashboard.
3. Review the Power BI Executive Summary preview:  
   [`module1_v1_v2_release_validation_executive_summary.png`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png)
4. Review the Power BI Release Impact Explorer preview:  
   [`module1_v1_v2_release_impact_explorer.png`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png)
5. Download the interactive Power BI report for application-level exploration:  
   [`Module1_V1_V2_Release_Validation.pbix`](./Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Module1_V1_V2_Release_Validation.pbix)
6. Open the Module 2 enterprise architecture:  
   [`Enterprise Credit Decisioning Strategy Module 2 Architecture.png`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png)
7. Open the Module 2 executive dashboard.
8. Review the Module 1 v2.0 BRD and Validation Summary.
9. Review the Module 2 SQL executive snapshot and section map.
10. Note Module 2 documentation status:
   - Module 2 BRD placeholder is present and marked coming soon.
   - Module 2 Validation Summary placeholder is present and marked coming soon.

### Technical / Architecture Review

Use this path to inspect how the design is implemented and translated into an analytical product.

1. Start with the Module 1 v2.0 BRD to understand design intent, boundaries, workstreams, and requirements.
2. Review the Module 1 v2.0 SQL implementation.
3. Review the Module 1 v2.0 Validation Summary to connect design claims to QA evidence.
4. Open the Power BI report and inspect:
   - Power Query staging, typing, merge, delta, and change-flag logic
   - the 50,000-row `FactReleaseComparison` table
   - the 58,382-row `FactReconciliationDetail` table
   - the active `Application_ID` one-to-many relationship
   - centralized DAX measures and dynamic analyst interpretation
   - executive and application-level report experiences
5. Review Module 1 outputs and scenario archive samples.
6. Review the Module 2 enterprise architecture:  
   [`Enterprise Credit Decisioning Strategy Module 2 Architecture.png`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png)
7. Review the Module 2 SQL implementation.
8. Review Module 2 campaign registry outputs.
9. Review Module 2 evidence outputs:
   - strategy run evidence summary
   - validation evidence
   - parameter snapshots
   - product × score segment evidence
10. Review Module 2 random sample outputs:
   - strategy decisions archive sample
   - M2-01 latest-run strategy decisions sample
11. Note that Module 2 BRD and Validation Summary are intentionally marked as coming soon and will become the formal design and validation anchors for Module 2.

### Governance / Validation Review

Use this path to evaluate auditability, traceability, controlled release comparison, and evidence discipline.

1. Review the Module 1 v2.0 BRD.
2. Review the Module 1 v2.0 Validation Summary.
3. Review the Power BI Executive Summary and Release Impact Explorer screenshots.
4. Open the Power BI report and confirm:
   - 50,000 matched applications
   - 21,326 affected applications and 28,674 unaffected applications
   - 42.65% application change rate
   - 58,382 application-variable difference records
   - exact variable-level reconciliation totals
   - application-level V1.0-to-V2.0 traceability
   - dynamic interpretation tied to documented workstream themes
5. Review Module 1 scenario archive samples and QA review outputs.
6. Review the Module 2 enterprise architecture:  
   [`Enterprise Credit Decisioning Strategy Module 2 Architecture.png`](./Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise%20Credit%20Decisioning%20Strategy%20Module%202%20Architecture.png)
7. Review Module 2 SQL Sections 0–17, especially:
   - strategy profile and run selector framework
   - archive persistence
   - matched comparison
   - validation / QA
   - frontier summary
   - evidence capture
   - post-campaign acceptance
8. Review Module 2 evidence output CSVs.
9. Review Module 2 campaign QA outputs for M2-01 through M2-39.
10. Note Module 2 BRD and Validation Summary placeholders as planned final governance anchors.

---

## Sample Data Policy

The full simulation archives are intentionally not uploaded in full.

Included CSVs are compact synthetic samples designed for GitHub review:

- Module 1 final synthetic applications output
- Module 1 scenario archive random sample
- Module 2 strategy decisions archive random sample
- Module 2 M2-01 latest-run strategy decisions sample
- Module 2 campaign registry outputs
- Module 2 evidence and validation outputs

The Power BI Desktop report analyzes synthetic Module 1 release outputs and reconciliation evidence. GitHub-viewable PNG previews are included because `.pbix` files are downloadable binary artifacts rather than browser-rendered reports.

All data is synthetic and intended for portfolio demonstration only.

---

## Data, Privacy, and Interpretation Boundaries

All data in this repository is synthetic or sampled from synthetic simulation archives.

This project does **not** use real applicant data, production credit policy, proprietary underwriting thresholds, customer communications, or operational decisioning output.

Important interpretation boundaries:

- `estimated_pd` should be interpreted as a **synthetic estimated-PD proxy**, not a calibrated production default model.
- Scenario outputs are controlled synthetic sensitivities, not market forecasts.
- Module 2 outcomes are simulated strategy outcomes, not real underwriting decisions.
- Reason codes are simulated strategy explanation codes, not customer adverse-action notices.
- Approved exposure and approved Expected Loss are simulation artifacts, not booked loans or funded accounts.
- Power BI release metrics describe controlled differences between synthetic V1.0 and V2.0 outputs; they are not production monitoring or regulatory validation results.

---

## Current Artifact Status

| Area | Artifact | Status | Role |
|---|---|---:|---|
| Module 1 v1.0 | BRD | Complete | Historical baseline design artifact |
| Module 1 v1.0 | SQL | Complete | Historical baseline implementation |
| Module 1 v1.0 | Validation Summary | Complete | Historical validation evidence |
| Module 1 v2.0 | BRD | Complete | Current design intent, requirements, governance, and boundaries |
| Module 1 v2.0 | SQL | Complete | Current executable implementation |
| Module 1 v2.0 | Validation Summary | Complete | QA-backed validation evidence |
| Module 1 v2.0 | Executive Dashboard | Complete | README / executive evidence view |
| Module 1 v2.0 | Power BI Executive Summary Preview | Complete | Browser-viewable portfolio-level release-validation evidence |
| Module 1 v2.0 | Power BI Release Impact Explorer Preview | Complete | Browser-viewable application-level traceability evidence |
| Module 1 v2.0 | Power BI Release-Validation Report | Complete | Interactive Power Query, semantic-model, DAX, and report-design artifact |
| Module 2 v1.0 | SQL | Complete | Current executable implementation |
| Module 2 v1.0 | Enterprise Architecture | Complete | Full-system SQL architecture, control flow, outcomes, governance, and evidence map |
| Module 2 v1.0 | Executive Dashboard | Complete | README / executive evidence view |
| Module 2 v1.0 | BRD | Coming soon | Planned design-intent and governance anchor |
| Module 2 v1.0 | Validation Summary | Coming soon | Planned validation and evidence anchor |

---

## Philosophy: No Black-Box Strategy Claims

A strategy result should not be treated as a black-box label.

This project is designed to show the underlying chain:

```text
Source population
→ risk profile
→ scenario assumptions
→ strategy controls
→ rule triggers
→ exposure treatment
→ final outcome
→ reason-code traceability
→ archive-backed comparison
→ Power BI release validation
→ executive and application-level evidence
```

The objective is not merely to produce outputs. The objective is to make the logic, assumptions, tradeoffs, and evidence visible enough for a reviewer to understand why the outputs exist.

---

## Author

**Andrew R. Goad**

Built as a portfolio-grade governed credit analytics, decision-system design, and Power BI release-validation artifact.
