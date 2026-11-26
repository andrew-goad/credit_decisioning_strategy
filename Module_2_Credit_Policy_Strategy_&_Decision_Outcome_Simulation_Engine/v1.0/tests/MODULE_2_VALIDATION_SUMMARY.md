# Credit Decisioning Strategy Simulator
## Module 2 v1.0 | Retrospective validation summary

**Historical DBeaver campaign · PostgreSQL · Historical evidence revision `65e7cc8`**

Andrew R. Goad · Credit strategy, simulator design and analysis · Teaching edition, November 26, 2026

The historical campaign evaluated 39 policy and scenario combinations of 50,000 synthetic applications each. Its final PostgreSQL acceptance record reported **10 of 10 gates ready for analysis**. For this review, the accompanying Python program independently recalculated the published outcome rates, segment totals and selected strategy differences. The exported evidence supports analysis of how a configured credit policy changes simulated decisions and exposure. The effects on actual originations, borrower behavior, defaults and profit remain open. [Final campaign acceptance][accept] · [Complete SQL (raw source)][sql]

### What was tested

Module 2 reads a named Module 1 population and applies a strategy, product policy, counteroffer and routing rules. The unit of decision is an application in a specific strategy and source scenario. Its possible final outcomes are approval as requested, counteroffer, manual review and decline. The simulation counts the first two as offers. An approved amount is simulated exposure and a manual review is an unresolved decision.

| Evidence level | Population | What a reader can establish |
| --- | --- | --- |
| Original PostgreSQL diagnostics | 1,950,000 archived decision evaluations across 39 runs, 19 source slices and 50,000 distinct application IDs | The engine’s historical checks tested archive identity, complete matching, output conventions, parameters and campaign readiness. |
| Independent recalculation from public exports | 39 run summaries, 975 product-by-score cells, 39 parameter snapshots, 858 validation records and 20 comparison groups | Recompute rates from counts, roll segment results to the run totals, subtract baseline from challenger and compare expected policy settings to saved JSON. |
| Independent check of published application rows | 13,583 archive sample rows spanning all 39 runs | Verify outcome/offer flags, amount conventions and primary-reason alignment directly on included records. The selection favors particular paths, so sample frequencies do not estimate portfolio rates. |

This verifier uses the original committed CSVs. The separate teaching explorer includes a compact lookup for all 1,950,000 decisions. Module 1 v2.0 supplies the risk foundation for Module 2. The Power BI workbook compares **Module 1 v1.0 and v2.0**, retaining all 50,000 matched applications, including the 28,674 with no functional change. Module 2 conclusions below come from its own SQL and retained campaign data. [Run outputs][outputs] · [Campaign diagnostic exports][qa]

**Historical source note.** Page 5 of the v1.0 Validation Summary used approximately $373,000 and 33% for mortgage balance and payment-to-income ratio. The September 30 review could not identify the query or denominator for those figures. The saved v1.0 product-profile QA reports 15,065 mortgage applications, a mean requested amount of $344,327 and mean payment-to-income ratio of 29.82%. The v2.0 Validation Summary uses that supported baseline on pages 21 and 41. [September 30 review](https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Chat_History/Conversations/C037/Part_13.md#c037-m00671) · [Saved mortgage QA](https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v1.0/tests/review_queries/module1_synthetic_application_risk_engine_v1.0_9.06_QA_product_profile_summary.csv#L4)

### Business questions and control results

| Question | Test and observation |
| --- | --- |
| Did each policy act on its intended population? | The 39 run registry IDs each matched one executive summary, archive inventory row and parameter snapshot. Source scenario, population, strategy name and strategy version agreed across the four exports. Each archive inventory row reported 50,000 distinct IDs and 50,000 rows. The historical archive-grain diagnostic reported zero duplicate keys. |
| Can a portfolio total be traced to its segments? | For each run, 25 distinct product-by-score cells reconciled to the executive output. Across 39 runs, **390 exact totals** matched, covering application and offer counts, four outcome counts, requested and approved amounts and both expected-loss totals. For every run the four outcomes summed to 50,000, and offers equaled approvals plus counteroffers. All **195 published rates** recalculated exactly from those counts. |
| Were the two sides of a comparison comparable? | All 20 registered comparison IDs linked to their final readiness, source-consistency and delta exports. Each reported 50,000 matched applications with zero baseline-only or challenger-only IDs. The exported mismatch counters, covering items such as score, income, requests, payment, PTI, modeled risk and source lineage, were all zero. The verifier read the counters. Rebuilding those matches from individual records requires the full archive. |
| Did the reported policy effect follow from the evidence? | For all 20 comparisons, approval, counteroffer, manual-review, decline and offer-rate differences matched challenger minus baseline. The same check matched approved-amount and approved expected-loss differences, for **140 exact deltas** in all. |
| Were product guardrails applied as specified? | For five product-guardrail runs, the historical exact-value audit covered revolving lines and unsecured personal loans. Twelve thresholds per product and run gave **120 comparisons**. Every reported expected value agreed with the reported actual value and the saved product-policy JSON. This test covers those two products in the five specified runs. |
| Did final outcomes retain their financial meaning? | The original Section 17.9 full-archive diagnostic recorded zero critical convention violations. Independently, all 13,583 public archive rows had a unique run/application key, the right single outcome flag, the corresponding offer flag and a populated primary reason in the expected family. Approvals preserved requested amount, counteroffers had a positive smaller amount equal to the counteroffer field, manual-review approved amounts were blank, and declines carried zero. |
| Can an aggressive counteroffer candidate be mistaken for an offer? | The original archive inventory recorded 17,886 aggressive-override rows. Of those, 14,847 ended in a counteroffer and 3,039 in manual review. These dispositions sum to the candidate count. The rules treat policy entry, feasibility and the final decision as distinct stages. |

[Archive inventory][inventory] · [Source-field consistency][source] · [Challenger deltas][delta] · [Guardrail audit][guard] · [SQL for final outcome conventions][conventions]

### A comparison that tests the interpretation

**What happened when counteroffer feasibility became more selective?** Comparison CG04 holds the 50,000 applications in `BASELINE_V2` fixed and compares M2-01 with M2-05. The observed differences below use the completed run summaries and the committed comparison evidence.

| Simulated outcome or exposure | M2-01 baseline | M2-05 selective feasibility | Challenger minus baseline |
| --- | ---: | ---: | ---: |
| Approval as requested | 10,695 | 9,374 | −1,321 |
| Counteroffer | 19,067 | 16,917 | −2,150 |
| Manual review | 7,535 | 11,006 | +3,471 |
| Decline | 12,703 | 12,703 | 0 |
| Any offer / 50,000 | 29,762 (59.524%) | 26,291 (52.582%) | −6.942 percentage points |
| Approved amount | $3,827,278,124.10 | $3,463,854,014.82 | −$363,424,109.28 |
| Approved expected loss, modeled | $58,551,692.22 | $50,527,926.46 | −$8,023,765.76 |

The decline count alone would suggest little changed. Yet the selective profile produced 3,471 fewer offers and 3,471 additional manual reviews on the same source population. The archive reports zero aggressive-override rows in both runs. These are **net movements**. An individual transition such as “counteroffer became manual review” requires joining that application across the two runs. The modeled expected-loss reduction accompanies a smaller offer book and gives no measure of realized savings. Amounts in the expected-loss row are rounded to cents for display. [Run-level evidence][summary] · [Baseline and challenger deltas][delta]

### Why readiness coexists with review flags

The final gate answers whether the registered campaign is ready for analysis. The per-run validation record also identifies distributions and incomplete intermediate comparisons that deserve interpretation. Each run retained 22 distinct validation items. Recounting all 858 yields **666 PASS, 55 REVIEW and 137 NOT_APPLICABLE**. Each run’s status counts agree with its executive evidence row. [Detailed validation evidence][validation] · [Campaign status concentrations][concentrations]

| REVIEW diagnostic | Count | Interpretation |
| --- | ---: | --- |
| Mixed-signal and borderline profile visibility | 39 | Every run prompted review of cases with conflicting or borderline signals. Section 14.16 describes how to inspect those cases. This record alone does not establish that every case received manual sign-off. |
| Selected comparison readiness | 9 | At capture, each of these nine rows reported a missing challenger archive, 50,000 baseline-only IDs and zero matches. The later campaign check found all 20 registered comparisons ready. Use the final comparison evidence when interpreting policy differences. |
| Final outcome rate profile | 7 | Runs M2-10, 15, 16, 17, 37, 38 and 39 flagged concentrated distributions. Interpretation calls for the selected scenario, strategy and reason-code mix. The unusual mix warrants business review alongside the reported counts. |

The 137 inapplicable items comprise 39 matched-comparison counteroffer-context checks, 36 aggressive-override reason checks, 33 latest-run override-behavior checks, 19 matched-source checks and 10 selected-comparison readiness checks. These records contribute no positive test evidence for their individual checks. To understand aggressive-override behavior, use the executed strategy-specific checks and the final campaign inventory. [SQL for mixed-signal review][edge] · [Final matched-comparison readiness][ready]

### Acceptance, limitations and reproduction

The ten historical readiness gates cover the campaign registry, comparison registry, archive, comparison matching, source consistency, evidence coverage, parameter snapshots, final outcome conventions, selective/aggressive counteroffer evidence and product guardrails. All ten fields in the retained final row are true. Its recorded disposition is `MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS`. [Final acceptance row][accept]

The original SQL ran from DBeaver. The teaching explorer uses a separate full-campaign extract for applicant transitions. Replaying a historical run would require its PostgreSQL environment and inputs. The current review does not establish live underwriting suitability, validated adverse-action reasons, model calibration against observed defaults or realized business benefits.

#### Run the companion verifier

Use a full teaching checkout containing the [companion verification program](verify_campaign_exports.py). Teaching revision `566e47805488526b63a90dbc0e92f6357f66ce6f` introduced this copy of the verifier. It reads the original campaign CSVs from historical revision `65e7cc8`.

Open PowerShell in the Module 2 v1.0 `tests` folder beside the program and run the following command with Python 3.9 or later. The final argument points to the repository root. The verifier uses the Python standard library.

The PDF also includes a plain-text copy under **Attachments**, named `verify_campaign_exports.py.txt`. If you received the PDF separately, that copy lets you inspect the code. Running it requires the campaign CSVs in the teaching checkout.

```powershell
python .\verify_campaign_exports.py ..\..\..
```

The verifier stops at the first inconsistency and names the affected run, comparison or test where available. It was executed against the pinned checkout. In a separate disposable copy, increasing one segment’s approval count by one produced the expected M2-01 reconciliation failure. A successful repeat verifies the published exports and sampled rows. New database execution requires a separate run.

**Evidence scope.** The historical 10-gate disposition and the retrospective export checks answer distinct questions. The campaign records report structural readiness. Evaluating credit outcomes in practice would require observed performance. [Historical project artifact map][map]

[accept]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.20_QA_final_module_2_campaign_acceptance_rollup_campaign.csv
[sql]: https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql
[outputs]: https://github.com/andrew-goad/credit_decisioning_strategy/tree/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs
[qa]: https://github.com/andrew-goad/credit_decisioning_strategy/tree/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign
[inventory]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.1_QA_module_2_archive_campaign_inventory_campaign.csv
[source]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.13_QA_active_comparison_matched_source_field_consistency_campaign.csv
[delta]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.15_QA_baseline_x_challenger_delta_summary_for_active_comparison_groups_campaign.csv
[guard]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.19_QA_product_guardrail_policy_snapshot_exact_value_audit_campaign.csv
[conventions]: #sql-69982
[summary]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_evidence_summary.csv
[validation]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_validation_evidence.csv
[concentrations]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.11_QA_validation_review_not_applicable_concentration_campaign.csv
[edge]: #sql-46458
[ready]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.12_QA_active_comparison_registry_readiness_campaign.csv
[map]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/PROJECT_ARTIFACT_MAP.md

## Source excerpts

The links in this document open the relevant excerpts below. Source line numbers refer to Module 2 v1.0 at Git commit `65e7cc84528008ea40c6f9bb70a02745df592f4c`. Each block reproduces the stated lines with their common indentation removed for legibility. Open the full SQL in a text editor or DBeaver and use **Go to line** to inspect the wider context. [Download the complete historical SQL](https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql)

### SQL 46458

**Retain mixed signals and edge cases for inspection.**

Lines 46461–46482.

```text
BUSINESS PURPOSE:
    Validate that realistic edge cases remain visible and explainable.

    Section 14.16 answers:

        "Do mixed-signal and threshold-adjacent profiles remain visible, bounded, and explainable
         through staged strategy logic?"

SQL PURPOSE:
    1. Display mixed-signal profile distribution.
    2. Display borderline profile distribution.
    3. Provide targeted edge-case samples.
    4. Keep samples limited so the validation package remains reviewable.

EDGE-CASE BOUNDARY:
    Realistic overlap is not automatically a defect.

    It becomes a review concern only if it:
        dominates the output,
        violates final output conventions,
        or cannot be explained through product structure, borrower profile, affordability, synthetic
        estimated-risk tiering, rule triggers, or exposure-treatment diagnostics.
```

### SQL 69982

**Check final conventions on the active campaign.**

Lines 69985–69998.

```text
BUSINESS PURPOSE:
    Apply final-output convention checks across the archived rows belonging to active campaign
    registry runs.

    Section 17.9 answers:

        "Do the archived rows for the active campaign satisfy the locked final output conventions?"

WHY THIS SECTION IS REGISTRY-SCOPED:
    The strategy archive may contain older development runs, ad hoc custom experiments, inactive
    campaign runs, or historical slices.

    Section 17 acceptance should evaluate the active campaign registry scope, not every historical
    archive row unless the user intentionally activates those runs in the campaign registry.
```

Lines 70000–70012.

```text
CONVENTIONS CHECKED:
    exactly one final decision flag per row;
    simulated_offer_exposure_flag reconciles to APPROVE / COUNTEROFFER;
    APPROVE preserves requested exposure, payment proxy, PTI, and requested Expected Loss;
    COUNTEROFFER has positive reduced exposure and satisfies target PTI / approved EL cap;
    MANUAL_REVIEW remains unresolved;
    DECLINE follows zero-exposure convention;
    simulated reason-code fields are complete;
    primary_reason_family aligns to decision_outcome.

EXPECTED RESULT:
    critical_convention_violation_count = 0
    active_campaign_archive_convention_status = ACTIVE_CAMPAIGN_ARCHIVE_CONVENTIONS_READY
```
