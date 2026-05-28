# Project Artifact Map

## Start Here

1. `README.md`  
   Executive overview of the full two-module simulator.

2. `Module_1.../v2.0/docs/module1_executive_dashboard_preview.png`  
   Executive dashboard for the synthetic risk foundation.

3. `Module_2.../docs/module2_executive_dashboard_preview.png`  
   Executive dashboard for the strategy decisioning layer.

4. `Module_1.../v2.0/src/module1_synthetic_application_risk_engine_v2.0.sql`  
   Final Module 1 SQL implementation.

5. `Module_2.../src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql`  
   Final Module 2 SQL implementation.

---

## Repository Structure

### Module 1 — Synthetic Application & Risk Modeling Engine

#### `v1.0`
Historical baseline version.

- `docs/`  
  Module 1 v1.0 BRD.

- `src/`  
  Module 1 v1.0 SQL implementation.

- `outputs/`  
  Final v1.0 synthetic application output.

- `tests/`  
  Module 1 v1.0 validation summary and review query outputs.

#### `v2.0`
Current validated Module 1 release.

- `docs/`  
  Module 1 v2.0 BRD and executive dashboard.

- `src/`  
  Module 1 v2.0 SQL implementation.

- `outputs/`  
  Final synthetic application output and compact scenario archive sample.

- `tests/review_queries/`  
  Campaign QA outputs and workflow evidence for:
  - campaign
  - workflow A
  - workflow B
  - workflow C
  - workflow D

---

### Module 2 — Credit Policy Strategy & Decision Outcome Simulation Engine

#### `v1.0`
Current Module 2 v1.0 release.

- `docs/`  
  Module 2 executive dashboard and placeholder documentation for upcoming BRD / Validation Summary.

- `src/`  
  Final Module 2 SQL implementation.

- `outputs/`  
  Compact archive samples, M2-01 latest-run sample, campaign registries, evidence summaries, validation evidence, parameter snapshots, and segment evidence.

- `tests/review_queries/`  
  Campaign QA outputs and per-run evidence for:
  - campaign
  - M2-01 through M2-39

---

## Current vs Historical Artifacts

| Area | Current Artifact |
|---|---|
| Module 1 current release | `Module_1.../v2.0/` |
| Module 1 historical baseline | `Module_1.../v1.0/` |
| Module 2 current release | `Module_2.../v1.0/` |
| Module 2 BRD | Coming soon |
| Module 2 Validation Summary | Coming soon |

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

All data is synthetic and intended for portfolio demonstration only.

---

## Documentation Status

| Area | Artifact | Status | Role |
|---|---|---:|---|
| Module 1 v2.0 | BRD | Complete | Design intent, requirements, governance, and boundaries |
| Module 1 v2.0 | SQL | Complete | Executable implementation |
| Module 1 v2.0 | Validation Summary | Complete | QA-backed validation evidence |
| Module 2 v1.0 | SQL | Complete | Executable implementation |
| Module 2 v1.0 | Executive Dashboard | Complete | Portfolio / README evidence view |
| Module 2 v1.0 | BRD | Coming soon | Planned design-intent and governance anchor |
| Module 2 v1.0 | Validation Summary | Coming soon | Planned validation and evidence anchor |

---

## Suggested Reviewer Paths

### 1. Fast Executive Review

Use this path to understand the system story, dashboard evidence, and current artifact status.

1. Read the root `README.md`
2. Open the Module 1 executive dashboard  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/docs/module1_executive_dashboard_preview.png`
3. Open the Module 2 executive dashboard  
   `Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0/docs/module2_executive_dashboard_preview.png`
4. Review the Module 1 v2.0 BRD  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/docs/Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0.pdf`
5. Review the Module 1 v2.0 Validation Summary  
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/tests/Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0.pdf`
6. Note Module 2 documentation status:
   - Module 2 BRD placeholder is present and marked coming soon
   - Module 2 Validation Summary placeholder is present and marked coming soon

### 2. Technical / Architecture Review

Use this path to inspect how the design is implemented.

1. Start with the Module 1 v2.0 BRD to understand design intent, boundaries, and requirements.
2. Review the Module 1 v2.0 SQL implementation.
   `Module_1_Synthetic_Application_&_Risk_Modeling_Engine/v2.0/src/module1_synthetic_application_risk_engine_v2.0.sql`
3. Review the Module 1 v2.0 Validation Summary to connect design claims to QA evidence.
4. Review Module 1 outputs and scenario archive samples.
5. Review the Module 2 SQL implementation.
   `Module_2_Credit_Policy_Strategy_&_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql`
6. Review Module 2 campaign registry outputs.
7. Review Module 2 evidence outputs:
   - strategy run evidence summary
   - validation evidence
   - parameter snapshots
   - product × score segment evidence
8. Review Module 2 random sample outputs:
   - strategy decisions archive sample
   - M2-01 latest-run strategy decisions sample
9. Note that Module 2 BRD and Validation Summary are intentionally marked as coming soon and will become the formal design / validation anchors for Module 2.

### 3. Governance / Validation Review

Use this path to evaluate auditability, traceability, and evidence discipline.

1. Review the Module 1 v2.0 BRD.
2. Review the Module 1 v2.0 Validation Summary.
3. Review Module 1 scenario archive sample and QA review outputs.
4. Review Module 2 SQL Sections 0–17, especially:
   - strategy profile and run selector framework
   - archive persistence
   - matched comparison
   - validation / QA
   - frontier summary
   - evidence capture
   - post-campaign acceptance
5. Review Module 2 evidence output CSVs.
6. Review Module 2 campaign QA outputs for M2-01 through M2-39.
7. Note Module 2 BRD and Validation Summary placeholders as planned final governance anchors.
