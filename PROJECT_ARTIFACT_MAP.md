# Project Artifact Map

## Start Here

1. `README.md`  
   Executive overview of the full two-module Enterprise Credit Decisioning Strategy Simulator.

2. `Module_1.../v2.0/docs/module1_executive_dashboard_preview.png`  
   Executive dashboard for the synthetic application and risk-modeling foundation.

3. `Module_1.../v2.0/tests/module1_v1_v2_release_validation_executive_summary.png`  
   Static preview of the Power BI Executive Summary page, showing portfolio-level Module 1 V1.0-to-V2.0 release impacts across 50,000 matched applications.

4. `Module_1.../v2.0/tests/module1_v1_v2_release_impact_explorer.png`  
   Static preview of the Power BI Release Impact Explorer, showing application-level reconciliation, borrower context, and dynamic analyst interpretation.

5. `Module_1.../v2.0/tests/Module1_V1_V2_Release_Validation.pbix`  
   Interactive Power BI release-validation report comparing 50,000 matched Module 1 V1.0 and V2.0 applications. Includes portfolio-level release metrics, variable-level impact analysis, application lookup, before-and-after reconciliation, and dynamic analyst interpretation.

6. `Module_2.../v1.0/docs/Enterprise Credit Decisioning Strategy Module 2 Architecture.png`  
   Enterprise architecture for the governed strategy decisioning layer, mapping the complete SQL flow across input foundation, strategy controls, decision logic, final outcomes, and governance / evidence / reuse.

7. `Module_2.../docs/module2_executive_dashboard_preview.png`  
   Executive dashboard for the strategy decisioning layer.

8. `Module_1.../v2.0/src/module1_synthetic_application_risk_engine_v2.0.sql`  
   Final Module 1 SQL implementation.

9. `Module_2.../src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql`  
   Final Module 2 SQL implementation.

---

## Repository Structure

### Module 1 — Synthetic Application & Risk Modeling Engine

#### `v1.0`

Historical baseline version.

- `docs/`  
  Module 1 v1.0 Business Requirements Document.

- `src/`  
  Module 1 v1.0 SQL implementation.

- `outputs/`  
  Final v1.0 synthetic application output.

- `tests/`  
  Module 1 v1.0 Validation Summary and review-query outputs.

#### `v2.0`

Current validated Module 1 release.

- `docs/`  
  Module 1 v2.0 Business Requirements Document and executive dashboard.

- `src/`  
  Module 1 v2.0 SQL implementation.

- `outputs/`  
  Final synthetic application output and compact scenario-archive sample.

- `tests/`  
  Release-validation artifacts, including:
  - Module 1 v2.0 Validation Summary
  - interactive Power BI V1.0-to-V2.0 release-validation report
  - Power BI Executive Summary preview
  - Power BI Release Impact Explorer preview
  - application-level reconciliation evidence
  - review-query outputs supporting release validation

- `tests/review_queries/`  
  Campaign QA outputs and workflow evidence for:
  - campaign
  - workflow A
  - workflow B
  - workflow C
  - workflow D

### Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine

#### `v1.0`

Current Module 2 v1.0 release.

- `docs/`  
  Module 2 enterprise architecture, executive dashboard, and placeholder documentation for the upcoming BRD and Validation Summary.

- `src/`  
  Final Module 2 SQL implementation.

- `outputs/`  
  Compact archive samples, M2-01 latest-run sample, campaign registries, evidence summaries, validation evidence, parameter snapshots, and segment evidence.

- `tests/review_queries/`  
  Campaign QA outputs and per-run evidence for:
  - campaign
  - M2-01 through M2-39

---

## Current vs. Historical Artifacts

| Area | Current Artifact |
|---|---|
| Module 1 current release | `Module_1.../v2.0/` |
| Module 1 historical baseline | `Module_1.../v1.0/` |
| Module 1 Power BI Executive Summary preview | `Module_1.../v2.0/tests/module1_v1_v2_release_validation_executive_summary.png` |
| Module 1 Power BI Release Impact Explorer preview | `Module_1.../v2.0/tests/module1_v1_v2_release_impact_explorer.png` |
| Module 1 interactive release validation | `Module_1.../v2.0/tests/Module1_V1_V2_Release_Validation.pbix` |
| Module 2 current release | `Module_2.../v1.0/` |
| Module 2 enterprise architecture | `Module_2.../v1.0/docs/Enterprise Credit Decisioning Strategy Module 2 Architecture.png` |
| Module 2 BRD | Coming soon |
| Module 2 Validation Summary | Coming soon |

---

## Power BI Release-Validation Report

The Module 1 Power BI report provides an interactive validation layer over the governed SQL outputs and reconciliation evidence.

### Report artifacts

- `tests/module1_v1_v2_release_validation_executive_summary.png`  
  Static GitHub-viewable preview of the Executive Summary page.

- `tests/module1_v1_v2_release_impact_explorer.png`  
  Static GitHub-viewable preview of the Release Impact Explorer page.

- `tests/Module1_V1_V2_Release_Validation.pbix`  
  Downloadable interactive Power BI Desktop report.

### Report pages

#### `01 | Executive Summary`

Provides a portfolio-level view of the V1.0-to-V2.0 release comparison, including:

- 50,000 matched applications
- affected and unaffected application counts
- application change rate
- total variable-change records
- number of changed functional variables
- functional changes by variable
- executive release interpretation

#### `02 | Release Impact Explorer`

Provides application-level traceability through:

- Application ID lookup
- selected applicant profile
- release status and changed-field count
- V1.0 and V2.0 functional-value comparison
- absolute change analysis
- conditional formatting
- dynamic DAX-based analyst interpretation
- alignment of observed changes to documented Module 1 V2.0 workstream themes

### Power BI capabilities demonstrated

- Power Query ingestion and data-type remediation
- relational semantic-model design
- one-to-many relationship configuration
- centralized DAX measure development
- KPI and executive-summary reporting
- interactive slicers and cross-filtering
- application-level reconciliation
- conditional formatting
- dynamic narrative measures
- executive and analyst-oriented report design
- governed release-validation storytelling

---

## Sample Data Policy

The full simulation archives are intentionally not uploaded in full.

Included CSVs are compact synthetic samples designed for GitHub review:

- Module 1 final synthetic-applications output
- Module 1 scenario-archive random sample
- Module 2 strategy-decisions archive random sample
- Module 2 M2-01 latest-run strategy-decisions sample
- Module 2 campaign-registry outputs
- Module 2 evidence and validation outputs

The Power BI report uses synthetic Module 1 release-comparison and reconciliation data. All records are synthetic and intended exclusively for portfolio demonstration.

---

## Documentation Status

| Area | Artifact | Status | Role |
|---|---|---:|---|
| Module 1 v2.0 | BRD | Complete | Design intent, requirements, governance, and boundaries |
| Module 1 v2.0 | SQL | Complete | Executable synthetic application and risk-modeling implementation |
| Module 1 v2.0 | Validation Summary | Complete | QA-backed validation evidence |
| Module 1 v2.0 | Power BI Executive Summary Preview | Complete | GitHub-viewable portfolio-level release-validation evidence |
| Module 1 v2.0 | Power BI Release Impact Explorer Preview | Complete | GitHub-viewable application-level traceability evidence |
| Module 1 v2.0 | Power BI Release-Validation Report | Complete | Interactive portfolio- and application-level release analysis |
| Module 2 v1.0 | SQL | Complete | Executable strategy and decision-outcome implementation |
| Module 2 v1.0 | Enterprise Architecture | Complete | Full-system SQL flow, controls, outcomes, and evidence architecture |
| Module 2 v1.0 | Executive Dashboard | Complete | Portfolio and README evidence view |
| Module 2 v1.0 | BRD | Coming soon | Planned design-intent and governance anchor |
| Module 2 v1.0 | Validation Summary | Coming soon | Planned validation and evidence anchor |

---

## Suggested Reviewer Paths

### 1. Fast Executive Review

Use this path to understand the system story, dashboard evidence, release impact, and current artifact status.

1. Read the root `README.md`.

2. Open the Module 1 executive dashboard:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png`

3. Open the Power BI Executive Summary preview:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png`

4. Open the Power BI Release Impact Explorer preview:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png`

5. Download and open the interactive Module 1 Power BI release-validation report:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/Module1_V1_V2_Release_Validation.pbix`

6. Review the report’s Executive Summary for portfolio-level V1.0-to-V2.0 release impact.

7. Use the Release Impact Explorer to inspect individual applications, reconcile functional values, and review the dynamic analyst interpretation.

8. Open the Module 2 enterprise architecture:  
   `Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise Credit Decisioning Strategy Module 2 Architecture.png`

9. Open the Module 2 executive dashboard:  
   `Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png`

10. Review the Module 1 v2.0 BRD:  
    `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/docs/Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0.pdf`

11. Review the Module 1 v2.0 Validation Summary:  
    `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0.pdf`

12. Note the Module 2 documentation status:
    - Module 2 BRD placeholder is present and marked coming soon.
    - Module 2 Validation Summary placeholder is present and marked coming soon.

### 2. Technical / Architecture Review

Use this path to inspect how the design is implemented and translated into an analytical reporting layer.

1. Start with the Module 1 v2.0 BRD to understand design intent, boundaries, workstreams, and requirements.

2. Review the Module 1 v2.0 SQL implementation:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/src/module1_synthetic_application_risk_engine_v2.0.sql`

3. Review the Module 1 v2.0 Validation Summary to connect design claims to QA evidence.

4. Review the Power BI screenshots:
   - `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png`
   - `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png`

5. Open the Module 1 Power BI release-validation report and review:
   - the two-table semantic model
   - the Application ID relationship
   - centralized DAX measures
   - portfolio-level release KPIs
   - variable-level reconciliation
   - dynamic application interpretation

6. Review Module 1 outputs and scenario-archive samples.

7. Review the Module 2 enterprise architecture:  
   `Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0/docs/Enterprise Credit Decisioning Strategy Module 2 Architecture.png`

8. Review the Module 2 SQL implementation:  
   `Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql`

9. Review Module 2 campaign-registry outputs.

10. Review Module 2 evidence outputs:
   - strategy-run evidence summary
   - validation evidence
   - parameter snapshots
   - product × score-segment evidence

11. Review Module 2 random-sample outputs:
    - strategy-decisions archive sample
    - M2-01 latest-run strategy-decisions sample

12. Note that the Module 2 BRD and Validation Summary are intentionally marked as coming soon and will become the formal design and validation anchors for Module 2.

### 3. Governance / Validation Review

Use this path to evaluate auditability, traceability, controlled release comparison, and evidence discipline.

1. Review the Module 1 v2.0 BRD.

2. Review the Module 1 v2.0 Validation Summary.

3. Review the Power BI Executive Summary preview:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_validation_executive_summary.png`

4. Review the Power BI Release Impact Explorer preview:  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/module1_v1_v2_release_impact_explorer.png`

5. Open the Power BI release-validation report and confirm:
   - 50,000 matched applications
   - one-to-one population reconciliation
   - affected and unaffected population totals
   - variable-change totals
   - application-level V1.0 and V2.0 traceability
   - dynamic interpretation of observed release impacts

6. Review the Module 1 scenario-archive sample and QA review outputs.

7. Review the Module 2 enterprise architecture to connect the staged SQL sections to strategy controls, decision logic, outcomes, archive persistence, comparison, QA, and acceptance.

8. Review Module 2 SQL Sections 0–17, especially:
   - strategy profile and run-selector framework
   - archive persistence
   - matched comparison
   - validation and QA
   - frontier summary
   - evidence capture
   - post-campaign acceptance

9. Review Module 2 evidence-output CSVs.

10. Review Module 2 campaign QA outputs for M2-01 through M2-39.

11. Note the Module 2 BRD and Validation Summary placeholders as planned final governance anchors.
