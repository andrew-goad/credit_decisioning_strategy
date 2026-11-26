# Credit Policy Strategy & Decision Outcome Simulation Engine

**Module 2 v1.0 · Retrospective business requirements · Historical DBeaver campaign**

**Business decision.** When a lender changes its credit policy, which synthetic applicants receive an offer, what size offer can the policy support, and how much exposure, modeled loss and manual review accompany that access? A useful comparison lets a reviewer trace an aggregate difference back to a decision, its inputs and the exact policy settings that produced it.

This document describes the PostgreSQL program used in the historical DBeaver campaign. It reconstructs requirements from the released implementation, its parameter snapshots and its retained campaign outputs at Git commit `65e7cc84528008ea40c6f9bb70a02745df592f4c`. The requirement identifiers below are retrospective reference labels. The research uses synthetic applicants. Funding, repayment, realized losses, profitability, fair-lending conclusions and customer-facing adverse-action notices fall outside the model. [Release scope][scope]

## Who uses the results

| Reader | Question the system must answer | Output to inspect |
| --- | --- | --- |
| Credit strategy analyst | Did a change in underwriting policy move access or merely change the population being compared? | Matched-group registry and source-field checks, then baseline-relative changes. |
| Product or portfolio lead | Which products or score bands drove the change in offer volume, approved dollars and modeled loss? | Run summaries and product-by-score-band evidence. |
| Operations lead | Did fewer declines become offers, or did cases accumulate in the manual-review queue? | Four mutually exclusive final outcomes, review rate, and the transition between final outcomes. |
| Independent reviewer | Can another reviewer recover the selected rules, decision path and acceptance evidence for a run? | Archived application records, ranked reasons, parameter snapshot, validation register and final campaign acceptance. |

## Execution and handoff

**Upstream authority.** Use the Module 1 v2.0 BRD, validation summary and accepted v2.0 source when interpreting the input data contract. The Power BI report reconciles the v1.0-to-v2.0 release comparison across the 50,000 baseline applications. Module 2 has its own campaign controls and acceptance evidence below. [Module 1 v2.0 BRD][m1-brd] · [Module 1 v2.0 validation][m1-validation] · [Power BI release comparison][m1-pbix]

Module 1 supplies a synthetic application with its product, requested terms, payment estimate, affordability, estimated probability-of-default proxy (PD), loss given default (LGD) and requested Expected Loss (EL). Module 2 owns the simulated policy decision. Its latest-run and archive tables record proposed credit exposure. They contain no account booking or subsequent loan performance. [Source contract][source] · [Published decision sample][sample]

The historical workflow used one database session for a run. Section 1 clears temporary objects and the replaceable latest-run output. Section 2 selects the run and creates its parameter cards. Section 3 checks the settings and source. Sections 4–11 build one decision per application. Section 12 persists the selected archive slice. Sections 13–16 compare, qualify and summarize results. Once the campaign is complete, Section 15 is refreshed across the archive, Section 16.9 synchronizes the frontier results into the evidence, and Section 17 assesses the full campaign. Each stage consumes the prior stage’s decision fields or evidence. A completed individual run is insufficient to establish campaign acceptance. [Historical execution sequence][execution] · [Reset scope][reset]

## Requirements and acceptance evidence

| ID | Required behavior | Acceptance criterion and evidence |
| --- | --- | --- |
| BR-01 | Identify a standard run from its campaign ID, source scenario and population, strategy and product-policy profile, and strategy version. Keep the comparison group independently selectable. | A standard run resolves one active configuration and a registry entry. A user selecting a different comparison does not thereby execute a different strategy. [Run selector][selector] · [Run registry][registry] |
| BR-02 | Consume one authorized Module 1 source slice. Retain application identity, source scenario, population and source risk/affordability fields. | The archive slice has the expected row count and distinct application count. Duplicate grain and missing populations are visible as exceptions. [Source filter][filter] · [Archive by run][slices] |
| BR-03 | Apply one compatible strategy and product-policy profile to the five supported products. Reject invalid thresholds and unsupported combinations before decisions are calculated. | Section 3 enforces the strategy bands and decision conventions. The accepted run records the policy actually used. [Gatekeeper][gate] · [Profile compatibility][compat] · [Snapshots][snap] |
| BR-04 | Separate diagnostic segmentation from rule triggers, preliminary routing and final decisions. Keep overlapping triggers observable. | An analyst can trace a case from source fields through triggered rules to one preliminary route. A hard policy stop, severe synthetic risk or severe DTI takes precedence over counteroffer eligibility. [Rule families][rules] · [Route precedence][route] · [Application sample][latest] |
| BR-05 | Allow a lower amount where the product permits a counteroffer and the proposed amount satisfies every feasibility condition after rounding. | The reduced amount is positive, below the request, at or above the permitted floor, within product maximum, and inside the product PTI and EL limits. [Upper and lower bounds][bounds] · [Rounded amount test][feasible] |
| BR-06 | Distinguish ordinary counteroffer eligibility from the aggressive strategy’s override for eligible severe requested-structure cases. | Selective and aggressive variants share the product feasibility rules. The archive separately counts override candidates, successful offers and unresolved candidates. [Strategy split][compat] · [Counteroffer strategy audit][split] |
| BR-07 | Produce exactly one final outcome per application with consistent exposure, approved amount, payment and modeled-loss treatment. | An approval uses the requested amount. A counteroffer uses a feasible reduced amount. Manual review records unresolved approved economics as null. Decline records zero approved amount and EL. [Resolution][resolve] · [Final amount][amount] · [Conventions audit][conventions] |
| BR-08 | Explain the final outcome with deterministic, ranked simulated reasons. | The stored fields identify the primary reason, its family, further reasons where applicable, and their order. The campaign checks completeness and family alignment. [Reason ranking][reason] · [Conventions audit][conventions] |
| BR-09 | Maintain distinct latest-run and archive outputs, and make rerun scope explicit. | A targeted rerun replaces the selected strategy/scenario/population slice. Append-only mode rejects a duplicate key. The completed campaign has zero duplicate archive-grain groups. [Archive replacement][archive] · [Campaign acceptance][accept] |
| BR-10 | Compare only matched applications in a common Module 1 scenario and population when attributing differences to policy. | Verify IDs on both sides, expected counts, and consistency of the source fields checked before interpreting decision or exposure movement. [Comparison registry][comparisons] · [Matched sources][matched] · [Paired deltas][deltas] |
| BR-11 | Preserve evidence at the executive, product-by-score-band, configuration and validation levels, retaining review and non-applicable findings. | Each accepted run has one executive record, one parameter snapshot, 25 product/score cells and 22 validation items in this campaign. A reviewer can distinguish a flagged diagnostic from a missing record. [Run evidence][run] · [Validation by run][reviews] · [Campaign acceptance][accept] |
| BR-12 | Synchronize campaign-wide comparisons after the last run and reconcile formal readiness gates. | Section 17 checks registries, archives, matched inputs, evidence, conventions, aggressive-counteroffer trace and targeted product settings. The retained rollup gives the campaign's structural acceptance status. [Synchronization][sync] · [Guardrail audit][guardrail] · [Final rollup][accept] |

## What an operator controls

The standard selector defaults to `M2-01`, `BASELINE_STRATEGY` on the archived `BASELINE_V2` source. `selected_module2_run_id` chooses the strategy run. `selected_comparison_group_id` chooses a registered comparison. The Section 13 execution setting accepts `AUTO`, `SKIP` and `REQUIRE`. The default auto-selects when a comparison resolves. A custom experiment supplies its own source identity and editable profile rows. Custom results need explicit registry support to enter the formal campaign record. [Selector and modes][selector] · [Custom run construction][custom]

| Setting family | M2-01 baseline | Meaning and interaction |
| --- | --- | --- |
| Synthetic PD thresholds | Approval maximum 8%, counteroffer maximum 16%, review maximum 30%, decline minimum 35% | Values lie in [0, 1]. The approval maximum must be below the counteroffer maximum, which must be below the review maximum. The review maximum may equal the decline minimum. A tighter-risk profile uses 6%, 12%, 25%, 30%. Other active rules still affect the outcome. |
| Payment-to-income (PTI) and debt-to-income (DTI) | Global PTI 25% / 40% / 55%. DTI 43% / 60% / 60%. In each sequence the entries are approval maximum, review maximum and decline minimum. | Both families accept values from 0 to 2 with enforced ordering. Product PTI thresholds and target PTI provide a product-specific view of affordability. DTI can trigger a higher-priority decline. |
| Stops and review signals | Bankruptcy, major derogatory and severe delinquency stops enabled. Severe delinquency count threshold 4. High-utilization review at 85%, low-score review threshold 580. Borderline buffer 5%. | Settings distinguish mandatory stops from review signals. The SQL bounds the buffer between 0% and 25%. Routing precedence resolves overlapping triggers. |
| Product controls | Five product rows, each with requested EL and PTI bands, approved EL cap, minimum and maximum amounts, minimum viable counteroffer percentage, maximum reduction percentage, rounding increment and permissions. | The same dollar amount can be viable for one product and fail for another. The product guardrail challenger specifically tightens unsecured personal loans and revolving lines. |
| Failed counteroffer | `MANUAL_REVIEW` | `MANUAL_REVIEW` and `DECLINE` are the supported outcomes for a tested, infeasible candidate. Simulated offer exposure requires a final approval or feasible counteroffer. |
| Archive handling | `archive_run_flag = TRUE`, `STRATEGY_SCENARIO_ONLY` | `NONE` rejects an existing replacement key. `STRATEGY_SCENARIO_ONLY` replaces the matching policy and source slice. `STRATEGY_SET_ONLY` covers a broader set on that source. `ALL` authorizes full archive replacement. These choices directly affect prior evidence. |

[Executable baseline and challenger values][defaults] · [Range and ordering checks][gate] · [Five product policies][products] · [Archived M2-01 settings][snap] · [Archive handling][archive]

### Baseline product settings

All dollar figures below are modeled US dollars. These values come from the M2-01 product-policy snapshot. They are configuration values for this historical experiment.

| Product | Approved amount range | Amount rounding | Counteroffer target PTI | Approved EL cap | Minimum counteroffer as % of request | Maximum reduction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Auto Loan | $5,000–$65,000 | $500 | 16% | $3,000 | 50% | 50% |
| HELOC | $10,000–$175,000 | $1,000 | 22% | $7,000 | 40% | 50% |
| Mortgage | $75,000–$800,000 | $5,000 | 32% | $10,000 | 50% | 50% |
| Revolving Line | $1,000–$20,000 | $500 | 10% | $1,800 | 50% | 50% |
| Unsecured Personal Loan | $1,000–$35,000 | $500 | 13% | $2,500 | 50% | 50% |

The floor uses the highest of the product minimum, the percentage floor and the amount implied by the maximum permissible reduction. For example, the baseline HELOC percentage floor alone permits 40% of the request, but the 50% maximum reduction constrains the offer to at least 50% before the dollar minimum is applied. For a hypothetical $100,000 HELOC request with $60,700 affordable under the tightest cap, the $1,000 increment rounds the candidate down to $60,000. A $49,900 cap would round down to $49,000 and fail the $50,000 floor. These examples illustrate the rule and assume the other feasibility checks pass. [Amount calculation][bounds] · [Post-rounding check][feasible]

### Requested-position thresholds by product

The table separates a requested-position threshold from a constraint on a future counteroffer. For example, the baseline auto loan uses an 18% approval PTI threshold and a 16% counteroffer PTI target. An application may therefore enter a different route before the simulator determines the size of a feasible lower offer. Ratios below use monthly payment divided by monthly income. Requested EL thresholds are amounts per application. [Executable product rows][products] · [Parameter snapshots][snap]

| Product | PTI approval max / review max / decline min | Requested EL approval max / review max / decline min |
| --- | ---: | ---: |
| Auto Loan | 18% / 28% / 38% | $3,500 / $7,000 / $12,000 |
| HELOC | 25% / 35% / 45% | $8,000 / $16,000 / $30,000 |
| Mortgage | 35% / 45% / 55% | $10,000 / $20,000 / $40,000 |
| Revolving Line | 12% / 20% / 30% | $2,000 / $4,000 / $8,000 |
| Unsecured Personal Loan | 15% / 25% / 35% | $3,000 / $6,000 / $10,000 |

### A field a reviewer can challenge

**Field.** `decline_min_estimated_pd_proxy` is the minimum synthetic risk threshold used in the severe-risk decline trigger. The baseline value is 0.35. The tighter synthetic-risk strategy uses 0.30. It is a scenario setting applied to a synthetic probability proxy, with values expressed as proportions. The input controls reject a value outside [0, 1] and any value below the corresponding review maximum. They permit equality with the review maximum. [Baseline and tighter strategy values][defaults] · [Threshold gate][gate]

**Downstream consequence.** For a case meeting the severe-risk decline trigger, preliminary routing checks that trigger before counteroffer candidacy. Reducing the requested amount can address payment burden or modeled EL but cannot clear this decline route. To interpret a change in the affected population, compare M2-01 to M2-02 on their registered common source, then examine final outcomes by product and score band. A single risk threshold cannot explain cases also affected by other rules. [Routing order][route] · [Registered comparisons][comparisons] · [Paired deltas][deltas]

## What happens to an application

1. **Establish the requested position.** Normalize the product key and carry through the source scenario, requested amount and payment, income, credit score, PTI, DTI, synthetic PD, LGD and requested EL. Segment and flag the request under the selected profile. Record which evidence came from Module 1 and which flags were generated by Module 2. [Source selection][source] · [Segmentation][segments]
2. **Apply the route hierarchy.** Hard policy stop, severe synthetic PD and severe DTI lead to a preliminary decline. An eligible counteroffer candidate goes to feasibility. Severe structure pressure without eligibility and other review candidates go to manual review. Clean approval candidates proceed to approval. The fallback also sends the case to review. [Ordered routing][route]
3. **Size and test a counteroffer.** Compare the request/product maximum, the amount that can meet target PTI, and the exposure consistent with the approved EL cap. Scale payment with the proposed amount. Calculate the test EL as proposed amount × synthetic PD × LGD. Round the binding amount down to the product increment, recheck the floor and ceilings, and apply the configured failed-counteroffer disposition. [Amount calculation][bounds] · [Payment and EL test][feasible] · [Final disposition][resolve]
4. **Preserve the explanation and movement.** Write the final outcome, approved economics and ranked reason fields alongside upstream triggers. Distinguish a change in offer count from a change in offer size. A proposed counteroffer may reduce exposure with no change in decline count. [Reason fields][reason] · [Decision archive sample][sample]

## A worked requirement trace

The selective and aggressive counteroffer experiments show why BR-06 cannot be tested by looking only at the total decline count. Both use the same 50,000 applications from `BASELINE_V2` and the same counteroffer product-policy profile. Their strategies differ in which cases reach feasibility testing. [Run registry][registry] · [Comparison evidence][split]

| Final outcome | M2-01 baseline | M2-05 selective feasibility | M2-37 aggressive expansion |
| --- | ---: | ---: | ---: |
| Approve as requested | 10,695 | 9,374 | 9,374 |
| Counteroffer | 19,067 | 16,917 | 20,977 |
| Manual review | 7,535 | 11,006 | 6,946 |
| Decline | 12,703 | 12,703 | 12,703 |

From M2-05 to M2-37, 4,060 more applications received a counteroffer, while the number requiring manual review fell by the same amount. The decline count stayed at 12,703. The aggressive strategy tested 4,614 override candidates, of whom 4,067 became counteroffers and 547 ended in review. The 4,060 is a **net difference between runs**. The 4,067 is a **count within the aggressive run’s override path**. The two answer different questions. Cross-check the aggregate with the separate override fields before describing what moved. [Run evidence][run] · [Option C matched checks][split]

## SQL implementation map

The release uses sections 1–17 of one Module 2 program. Section 0 documents the model boundary. Each section link opens a local excerpt. Use the line numbers in the appendix to inspect the surrounding statements in the complete raw source.

| SQL section | Business function | Handoff |
| ---: | --- | --- |
| [1](#sql-1134) | Reset the analytical session | Remove obsolete temporary state and replace the latest-run table. Preserve the archive, registries and historical evidence. |
| [2](#sql-1508) | Select a run, profile and comparison | Resolve operator settings against catalogs and produce strategy and product-policy parameter cards. |
| [3](#sql-5660) | Prove readiness | Check selectors, compatible profiles, supported products, numeric bounds and source availability before processing. |
| [4](#sql-8208) | Select Module 1 inputs | Normalize the chosen latest output or archive slice and carry source identity into individual application records. |
| [5](#sql-10234) | Create diagnostic segments | Attach strategy context and classify risk, affordability, exposure and requested loss to support interpretation. |
| [6](#sql-12717) | Construct rule flags | Retain individual rule triggers, stops, review markers and ordinary or override eligibility. |
| [7](#sql-16392) | Choose a preliminary route | Apply ordered rules and assign a route for treatment. |
| [8](#sql-19015) | Apply exposure and affordability treatment | Calculate a candidate amount and check feasibility after rounding. |
| [9](#sql-22324) | Resolve the final decision | Apply the failed-counteroffer action and lock outcome-specific amounts, payment and expected loss. |
| [10](#sql-26128) | Assign simulated reasons | Rank decision-aligned reason candidates and retain the primary and supporting explanations. |
| [11](#sql-29364) | Write the latest-run output | Expose one decision per application for diagnostics and export. |
| [12](#sql-32935) | Persist to the strategy archive | Respect the archive flag and configured replacement scope, then reconcile the slice. |
| [13](#sql-36644) | Compare matched strategy runs | Select a common population and compare baseline and challenger archive members. |
| [14](#sql-40909) | Validate current-run behavior | Check grain, economics, routing, explanations and expected diagnostic behavior. |
| [15](#sql-49072) | Calculate the strategy frontier | Compare access, approved amount and modeled EL across archived strategy runs and segments. |
| [16](#sql-55066) | Capture evidence by run | Persist the executive summary, validation items, product/score evidence and settings. Section 16.9 later refreshes the campaign-wide frontier fields. |
| [17](#sql-67457) | Close the campaign | Audit registered slices, comparison pairs, conventions, evidence coverage and parameter values. Export the final readiness assessment. |

## Evidence handoff and limits

| Output | Grain | How to use it |
| --- | --- | --- |
| `strategy_decisions` | One row per application in the latest executed run | Inspect one decision path and its supporting fields. A subsequent run replaces this output. The repository includes a stratified M2-01 extract. [Latest-run sample][latest] |
| `strategy_decisions_archive` | One row per application within a specific strategy version and Module 1 source slice | Recover the population for comparisons. The original row-level CSV exports are samples. The teaching explorer retains compact decisions for every application and run. Use published campaign evidence for totals and the preserved PostgreSQL archive for a new full-population row-level reconciliation. [Archive sample][sample] · [Archive slice detail][slices] |
| Run and comparison registries | One record per defined run or comparison | Recover what was selected and what must be held constant. The 39 runs produce 1,950,000 decision evaluations. Each run evaluates 50,000 applications. [Run registry][registry] · [Comparison registry][comparisons] |
| Evidence tables | Executive record and parameter snapshot per run, validation item per run, product-by-score cell per run | Reproduce portfolio findings with retained figures and distinguish structural readiness from interpretive review. [Executive evidence][run] · [Parameter snapshots][snap] · [Validation evidence][reviews] |
| Campaign closeout | One final readiness rollup with detail tables by control | The retained output reports all ten final gates ready. It establishes completeness and control performance against synthetic campaign requirements. Observed future borrower outcomes would be needed to assess predictive or commercial performance. [Acceptance rollup][accept] |

**Scope of the requirements.** These retrospective requirements describe the released operating contract and its key business rules. The settings, figures and comparisons come from the retained historical records. The published validation uses the campaign exports. A new execution would be needed to assess operation in another database environment.

[scope]: #sql-183
[execution]: #sql-478
[reset]: #sql-1134
[selector]: #sql-1663
[source]: #sql-8288
[filter]: #sql-9074
[gate]: #sql-6420
[compat]: #sql-3283
[rules]: #sql-12717
[route]: #sql-17067
[bounds]: #sql-19644
[feasible]: #sql-19845
[resolve]: #sql-23059
[amount]: #sql-23345
[reason]: #sql-27339
[archive]: #sql-34160
[custom]: #sql-3743
[defaults]: #sql-2102
[products]: #sql-3128
[segments]: #sql-10234
[sample]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_RANDOM_SAMPLE_strategy_decisions_archive.csv
[latest]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_RANDOM_SAMPLE_strategy_decisions_m2_01.csv
[registry]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_campaign_registry.csv
[snap]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_parameter_snapshot.csv
[run]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_run_evidence_summary.csv
[comparisons]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_comparison_campaign_registry.csv
[matched]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.13_QA_active_comparison_matched_source_field_consistency_campaign.csv
[slices]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.2_QA_module_2_archive_slice_detail_campaign.csv
[split]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.17_QA_option_c_counteroffer_strategy_split_effect_check_campaign.csv
[conventions]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.9_QA_active_campaign_archive_final_output_convention_checks_campaign.csv
[accept]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.20_QA_final_module_2_campaign_acceptance_rollup_campaign.csv
[deltas]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.15_QA_baseline_x_challenger_delta_summary_for_active_comparison_groups_campaign.csv
[reviews]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.10_QA_validation_status_summary_by_active_campaign_run_campaign.csv
[sync]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_16.9G.1_QA_synchronization_status_summary_campaign.csv
[guardrail]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/tests/review_queries/campaign/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_17.19_QA_product_guardrail_policy_snapshot_exact_value_audit_campaign.csv
[m1-brd]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/docs/Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0.pdf
[m1-validation]: https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0.pdf
[m1-pbix]: https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_1_Synthetic_Application_%26_Risk_Modeling_Engine/v2.0/tests/Module1_V1_V2_Release_Validation.pbix

## Source excerpts

The links in this document open the relevant excerpts below. Source line numbers refer to Module 2 v1.0 at Git commit `65e7cc84528008ea40c6f9bb70a02745df592f4c`. Each block reproduces the stated lines with their common indentation removed for legibility. Open the full SQL in a text editor or DBeaver and use **Go to line** to inspect the wider context. [Download the complete historical SQL](https://raw.githubusercontent.com/andrew-goad/credit_decisioning_strategy/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/src/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql)

### SQL 183

**Model boundary.**

Lines 185–199.

```text
Module 2 is:

    1. A governed synthetic strategy outcome simulator.
    2. A downstream strategy layer that consumes Module 1 synthetic outputs.
    3. A parameterized credit policy simulation framework.
    4. A strategy and product-policy control framework.
    5. A staged decision-outcome architecture.
    6. A simulated approved-exposure and counteroffer feasibility engine.
    7. A simulated strategy explanation-code framework.
    8. A latest-run and archive persistence framework.
    9. A matched strategy comparison framework.
    10. A QA and validation evidence framework.
    11. A strategy frontier and executive evidence framework.
    12. A post-campaign frontier evidence synchronization framework.
    13. A post-campaign acceptance and parameter-audit framework.
```

Lines 205–219.

```text
Module 2 is not:

    1. An operational underwriting engine.
    2. A real applicant decision system.
    3. A customer communication framework.
    4. A regulatory notice framework.
    5. A fair-lending conclusion engine.
    6. A production pricing engine.
    7. A profitability model.
    8. A revenue model.
    9. A funding-cost model.
    10. A capital model.
    11. An empirically calibrated default model.
    12. An account-creation or funded-exposure process.
    13. A servicing, billing, or lifecycle performance system.
```

### SQL 478

**Run sequence.**

Lines 486–501.

```text
Use this workflow for one governed Module 2 run.

    1. Run Section 1.
        Resets temporary objects and the replaceable latest-run table.

    2. Configure Section 2.
        Select the intended Module 2 run or strategy configuration.

        Default starting point:
            BASELINE_STRATEGY on BASELINE_V2.

    3. Run Section 3.
        Fails fast if strategy configuration, product policy, source selection, registry linkage, or
        Option C counteroffer controls are invalid.

    4. Run Sections 4–11.
```

Lines 551–562.

```text

    4. Run Section 17.
        Performs final post-campaign archive, registry, comparison, validation, evidence, parameter,
        product-policy, Option C evidence-readiness, and acceptance checks.

Why the Section 15 → Section 16.9 → Section 17 sequence matters:
    Section 15 is archive-wide.
    Section 16 captures evidence one run at a time.
    After a full campaign or rerun, earlier evidence rows may need frontier labels refreshed from the
    final completed archive.
    Section 16.9 formalizes that refresh so users do not need an informal patch.
    Section 17 evaluates the final synchronized evidence layer.
```

### SQL 1134

**Reset and preserve the archive.**

Lines 1137–1149.

```text
BUSINESS PURPOSE:
    Establish the dedicated simulation schema and reset transient Module 2 execution objects so a
    full Module 2 run starts from a clean, interpretable state.

    Section 1 answers:

        "What execution artifacts should be cleared before a new full Module 2 strategy run begins,
         and what governed history should be preserved?"

SQL PURPOSE:
    1. Create or reuse the dedicated simulation schema.
    2. Set the search path for convenient object resolution.
    3. Drop temporary Module 2 selector, parameter, staging, comparison, validation, frontier,
```

Lines 1209–1218.

```text
    The campaign registry and Section 16 evidence tables support run-roadmap traceability,
    validation-summary linkage, parameter snapshots, executive story capture, and product × score
    evidence.

    They are persistent governance artifacts, not transient execution staging tables.

    Section 16 handles evidence replacement at the current run key. Section 1 should not destroy
    historical evidence or campaign registry metadata.

BOUNDARY:
```

### SQL 1508

**Strategy Profile, Product Policy Profile, Campaign Registry, And Run Selector Framework.**

Lines 1511–1521.

```text
BUSINESS PURPOSE:
    Centralize the governed configuration layer for Module 2.

    Section 2 answers:

        "Which Module 2 run, strategy profile, product-policy profile, Module 1 source slice,
         archive behavior, registry IDs, comparison IDs, and Section 13 comparison-execution mode
         should this execution use?"

DESIGN CHANGE IN THIS VERSION:
    Section 2 is now profile-driven.
```

### SQL 1663

**Select a run and a comparison.**

Lines 1663–1681.

```text
SECTION 2.1 — OPERATOR RUN SELECTOR
****************************************************************************************************

USER ACTION:
    For a standard campaign run, edit selected_module2_run_id.

    This one field controls which formal Module 2 campaign run is executed.

DEFAULT:
    selected_module2_run_id = 'M2-01'

    This selects:
        M2-01
        BASELINE_V2
        BASELINE_STRATEGY
        BASELINE_PRODUCT_POLICY

IMPORTANT:
    BASELINE_STRATEGY is the default reference strategy.
```

### SQL 2102

**Risk cutoffs and baseline configuration.**

Lines 2102–2119.

```text
KEY STRATEGY PARAMETER FAMILIES:

    Synthetic estimated-risk thresholds:
        Fields:
            approve_max_estimated_pd_proxy
            counteroffer_max_estimated_pd_proxy
            review_max_estimated_pd_proxy
            decline_min_estimated_pd_proxy

        Baseline default:
            BASELINE_STRATEGY = 0.080000 / 0.160000 / 0.300000 / 0.350000

        Campaign challenger examples:
            TIGHTER_SYNTHETIC_RISK_STRATEGY = 0.060000 / 0.120000 / 0.250000 / 0.300000
            GROWTH_ORIENTED_STRATEGY        = 0.100000 / 0.200000 / 0.350000 / 0.400000

        Credit risk concept:
            Lower values tighten synthetic-risk appetite.
```

Lines 2209–2215.

```text
'STRATEGY_SCENARIO_ONLY'::TEXT,

0.080000::NUMERIC(12,6),
0.160000::NUMERIC(12,6),
0.300000::NUMERIC(12,6),
0.350000::NUMERIC(12,6),

```

### SQL 3128

**Five baseline product policies.**

Lines 3137–3141.

```text
('BASELINE_PRODUCT_POLICY'::TEXT,'MORTGAGE'::TEXT,0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.550000::NUMERIC(12,6),0.320000::NUMERIC(12,6),10000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),40000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),75000.00::NUMERIC(18,2),800000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,5000.00::NUMERIC(18,2)),
('BASELINE_PRODUCT_POLICY'::TEXT,'HELOC'::TEXT,0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.450000::NUMERIC(12,6),0.220000::NUMERIC(12,6),8000.00::NUMERIC(18,2),16000.00::NUMERIC(18,2),30000.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),175000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.400000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,1000.00::NUMERIC(18,2)),
('BASELINE_PRODUCT_POLICY'::TEXT,'AUTO_LOAN'::TEXT,0.180000::NUMERIC(12,6),0.280000::NUMERIC(12,6),0.380000::NUMERIC(12,6),0.160000::NUMERIC(12,6),3500.00::NUMERIC(18,2),7000.00::NUMERIC(18,2),12000.00::NUMERIC(18,2),3000.00::NUMERIC(18,2),5000.00::NUMERIC(18,2),65000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
('BASELINE_PRODUCT_POLICY'::TEXT,'UNSECURED_PERSONAL_LOAN'::TEXT,0.150000::NUMERIC(12,6),0.250000::NUMERIC(12,6),0.350000::NUMERIC(12,6),0.130000::NUMERIC(12,6),3000.00::NUMERIC(18,2),6000.00::NUMERIC(18,2),10000.00::NUMERIC(18,2),2500.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),35000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
('BASELINE_PRODUCT_POLICY'::TEXT,'REVOLVING_LINE'::TEXT,0.120000::NUMERIC(12,6),0.200000::NUMERIC(12,6),0.300000::NUMERIC(12,6),0.100000::NUMERIC(12,6),2000.00::NUMERIC(18,2),4000.00::NUMERIC(18,2),8000.00::NUMERIC(18,2),1800.00::NUMERIC(18,2),1000.00::NUMERIC(18,2),20000.00::NUMERIC(18,2),TRUE::BOOLEAN,TRUE::BOOLEAN,0.500000::NUMERIC(12,6),0.500000::NUMERIC(12,6),'MOST_CONSERVATIVE_FEASIBLE_AMOUNT'::TEXT,500.00::NUMERIC(18,2)),
```

Lines 3234–3257.

```text
) AS v(
    product_policy_profile_code,
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
);
```

### SQL 3283

**Compatible strategy and product profiles.**

Lines 3283–3292.

```text
          - Aggressive expansion sends more severe requested-structure cases into the same
            governed counteroffer feasibility framework.

    Section 3 will validate these pairings before applicant-level logic runs.

SQL TEACHING POINT:
    This map is a small control table.

    It makes compatibility testable instead of relying on comments alone.

```

Lines 3314–3327.

```text
    COUNTEROFFER_FIRST_PROFILE.

    Formal campaign counteroffer strategy rows should use:
        SELECTIVE_COUNTEROFFER_FEASIBILITY_PROFILE
        AGGRESSIVE_COUNTEROFFER_EXPANSION_PROFILE

Product-policy note:
    COUNTEROFFER_FIRST_PRODUCT_POLICY remains valid because it represents the shared
    product-level reduced-exposure feasibility math used by both Option C strategies.

    The strategy split is routing posture, not product-level feasibility math.
*/
('COUNTEROFFER_FIRST_PROFILE'::TEXT, 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'::TEXT, 'COUNTEROFFER_FIRST_PRODUCT_POLICY'::TEXT, FALSE::BOOLEAN),
('PRODUCT_GUARDRAIL_PROFILE'::TEXT, 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'::TEXT, 'PRODUCT_GUARDRAIL_PRODUCT_POLICY'::TEXT, TRUE::BOOLEAN),
```

### SQL 3743

**Resolve the selected configuration.**

Lines 3743–3761.

```text
CREATE TEMP TABLE tmp_m2_selected_run_config
ON COMMIT PRESERVE ROWS
AS
WITH op AS (
    SELECT *
    FROM tmp_m2_operator_run_selector
    WHERE active_selector_flag IS TRUE
    LIMIT 1
),

standard_run AS (
    SELECT
        op.run_mode,

        c.module2_run_id,
        c.run_sequence_number,
        c.module1_run_id,

        c.showcase_id,
```

Lines 3824–3836.

```text
        op.custom_validation_summary_section_hint AS validation_summary_section_hint,
        op.custom_readme_storyline_label AS readme_storyline_label,
        op.custom_linkedin_post_sequence AS linkedin_post_sequence,

        FALSE AS registry_active_flag

    FROM op

    WHERE op.run_mode = 'CUSTOM'
)

SELECT *
FROM standard_run
```

### SQL 5660

**Fail-Fast Strategy Parameter, Source, Product Policy, Profile, And Registry Gatekeeper.**

Lines 5663–5673.

```text
BUSINESS PURPOSE:
    Stop invalid Module 2 configuration before applicant-level strategy logic runs.

    Section 3 answers:

        "Is the selected Module 2 run configured well enough to proceed into Module 1 source staging,
         strategy segmentation, rule construction, preliminary routing, exposure treatment, final
         decision resolution, archive persistence, comparison review, QA, frontier analysis, and
         evidence capture?"

WHY THIS SECTION CHANGED:
```

### SQL 6420

**Validate default-probability thresholds.**

Lines 6421–6444.

```text
IF p.approve_max_estimated_pd_proxy IS NULL
   OR p.counteroffer_max_estimated_pd_proxy IS NULL
   OR p.review_max_estimated_pd_proxy IS NULL
   OR p.decline_min_estimated_pd_proxy IS NULL
   OR p.approve_max_estimated_pd_proxy < 0
   OR p.counteroffer_max_estimated_pd_proxy < 0
   OR p.review_max_estimated_pd_proxy < 0
   OR p.decline_min_estimated_pd_proxy < 0
   OR p.approve_max_estimated_pd_proxy > 1
   OR p.counteroffer_max_estimated_pd_proxy > 1
   OR p.review_max_estimated_pd_proxy > 1
   OR p.decline_min_estimated_pd_proxy > 1 THEN
    RAISE EXCEPTION
        'Module 2 Section 3 failure: synthetic estimated-risk thresholds must be populated and between 0 and 1.';
END IF;

IF NOT (
    p.approve_max_estimated_pd_proxy < p.counteroffer_max_estimated_pd_proxy
    AND p.counteroffer_max_estimated_pd_proxy < p.review_max_estimated_pd_proxy
    AND p.review_max_estimated_pd_proxy <= p.decline_min_estimated_pd_proxy
) THEN
    RAISE EXCEPTION
        'Module 2 Section 3 failure: synthetic estimated-risk threshold ordering is invalid.';
END IF;
```

### SQL 8208

**Module 1 Source Selection And Lineage Normalization.**

Lines 8211–8221.

```text
BUSINESS PURPOSE:
    Safely consume the validated Module 1 source slice and create the clean Module 2 input
    foundation.

    Section 4 answers:

        "Which Module 1 synthetic applicant population is the current Module 2 strategy run using,
         and has that source been normalized into a stable Module 2 staging shape?"

    This section is the formal Module 1 → Module 2 handoff layer.

```

### SQL 8288

**Select the Module 1 source.**

Lines 8288–8302.

```text
INPUTS:
    tmp_module2_strategy_params
        Active Module 2 strategy parameter card generated by Section 2.

    tmp_module2_product_policy_params
        Active product-specific policy parameter card generated by Section 2.

    tmp_m2_source_selection_scope
        Effective Module 1 source-scope helper created by Section 3.

    tmp_m2_campaign_registry_current_run_match
        Campaign registry match helper created by Section 3.

    credit_decisioning_sim.synthetic_applications
        Module 1 latest-run output, used when module1_input_source = 'LATEST'.
```

Lines 8375–8386.

```text
        REVOLVING_LINE

    Section 4 preserves the original product_type and derives product_type_policy_key for later
    strategy joins.

    Module 1 is not modified.

WHY PRODUCT-POLICY VALIDATION HAPPENS BEFORE POLICY RULES:
    Downstream strategy rules are product-aware.

    A missing product-policy configuration would make decision logic ambiguous, so Section 4 fails
    before strategy segmentation, rule flags, or decisions are created.
```

### SQL 9074

**Filter the archive by scenario and population.**

Lines 9089–9103.

```text
    LATEST:
        Consume the entire latest-run Module 1 table after Section 3 confirms it contains
        exactly one scenario / population slice.

    ARCHIVE:
        Consume only the selected Module 1 scenario set, scenario name, and population_id.
    ***********************************************************************************/
    WHERE p.module1_input_source = 'LATEST'
       OR (
            p.module1_input_source = 'ARCHIVE'
        AND %s = p.source_module1_scenario_set_name
        AND %s = p.source_module1_scenario_name
        AND src.population_id::TEXT = p.source_population_id
       )
),
```

### SQL 10234

**Build diagnostic segments.**

Lines 10237–10250.

```text
BUSINESS PURPOSE:
    Create a non-decisioning strategy segmentation layer that translates continuous and categorical
    Module 1 inputs into policy-readable diagnostic segments.

    Section 5 answers:

        "How should this synthetic applicant be described for strategy-rule interpretation?"

    Section 5 does not answer:

        "What final simulated strategy outcome should this synthetic applicant receive?"

    This section is the applicant-description layer.

```

### SQL 12717

**Build overlapping rule flags.**

Lines 12720–12735.

```text
BUSINESS PURPOSE:
    Convert Section 5 diagnostic segments into deterministic, auditable simulated rule-trigger flags.

    Section 6 answers:

        "Which simulated policy, risk, affordability, exposure, Expected Loss, counteroffer,
         manual-review, and supplemental review conditions are triggered for this synthetic
         applicant?"

    Section 6 does not answer:

        "What is the final simulated strategy outcome?"

    Section 6 is the trigger-evidence layer.

    It does not decide the applicant. It identifies the signals that later routing, exposure
```

### SQL 16392

**Preliminary Decision Routing Layer.**

Lines 16395–16405.

```text
BUSINESS PURPOSE:
    Convert overlapping Section 6 rule-trigger flags into one transparent preliminary strategy route.

    Section 7 answers:

        "Based on current simulated strategy triggers, what path should this synthetic applicant be
         routed toward before approved exposure, approved affordability, approved Expected Loss, and
         counteroffer feasibility are evaluated?"

    Section 7 does not answer:

```

### SQL 17067

**Apply decision precedence.**

Lines 17080–17103.

```text
CASE
    WHEN ri.hard_policy_stop_flag IS TRUE
        THEN 'DECLINE'

    WHEN ri.synthetic_risk_decline_trigger_flag IS TRUE
        THEN 'DECLINE'

    WHEN ri.dti_decline_trigger_flag IS TRUE
        THEN 'DECLINE'

    WHEN ri.counteroffer_candidate_flag IS TRUE
        THEN 'COUNTEROFFER'

    WHEN ri.severe_requested_structure_trigger_flag IS TRUE
     AND ri.counteroffer_candidate_flag IS DISTINCT FROM TRUE
        THEN 'MANUAL_REVIEW'

    WHEN ri.manual_review_candidate_flag IS TRUE
        THEN 'MANUAL_REVIEW'

    WHEN ri.clean_approval_candidate_flag IS TRUE
        THEN 'APPROVE'

    ELSE 'MANUAL_REVIEW'
```

### SQL 19015

**Approved Exposure And Counteroffer Feasibility Layer.**

Lines 19018–19028.

```text
BUSINESS PURPOSE:
    Calculate preliminary approved-exposure economics and counteroffer feasibility after preliminary
    routing has identified which rows require exposure treatment.

    Section 8 answers:

        "Given the preliminary route, what approved exposure treatment would be economically and
         structurally feasible?"

    Section 8 does not answer:

```

### SQL 19644

**Size the candidate against constraints.**

Lines 19694–19705.

```text
CASE
    WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
     AND ei.requested_payment_to_income_ratio > 0
        THEN ei.requested_amount
             * ei.counteroffer_target_pti
             / NULLIF(ei.requested_payment_to_income_ratio, 0)

    WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
        THEN ei.requested_amount

    ELSE NULL::NUMERIC
END AS counteroffer_pti_target_amount,
```

Lines 19720–19730.

```text
CASE
    WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
     AND (ei.estimated_pd * ei.estimated_lgd) > 0
        THEN ei.product_approved_el_cap
             / NULLIF((ei.estimated_pd * ei.estimated_lgd), 0)

    WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
        THEN LEAST(ei.requested_amount, ei.product_max_approved_amount)

    ELSE NULL::NUMERIC
END AS counteroffer_el_cap_amount,
```

Lines 19747–19755.

```text
CASE
    WHEN ei.preliminary_decision_outcome = 'COUNTEROFFER'
        THEN GREATEST(
            ei.product_min_approved_amount,
            ei.requested_amount * ei.product_min_counteroffer_pct,
            ei.requested_amount * (1.0 - ei.product_max_exposure_reduction_pct)
        )
    ELSE NULL::NUMERIC
END AS counteroffer_min_viable_amount
```

Lines 19776–19785.

```text

CASE
    WHEN cc.preliminary_decision_outcome = 'COUNTEROFFER'
        THEN LEAST(
            cc.counteroffer_product_cap_amount,
            cc.counteroffer_pti_target_amount,
            cc.counteroffer_el_cap_amount
        )
    ELSE NULL::NUMERIC
END AS counteroffer_raw_max_feasible_amount
```

Lines 19808–19816.

```text
CASE
    WHEN cr.preliminary_decision_outcome = 'COUNTEROFFER'
     AND cr.counteroffer_raw_max_feasible_amount IS NOT NULL
     AND cr.approved_amount_rounding_increment > 0
        THEN FLOOR(
                cr.counteroffer_raw_max_feasible_amount
                / NULLIF(cr.approved_amount_rounding_increment, 0)
             )
             * cr.approved_amount_rounding_increment
```

### SQL 19845

**Check the rounded counteroffer.**

Lines 19913–19929.

```text
CASE
    WHEN cte.preliminary_decision_outcome <> 'COUNTEROFFER'
        THEN NULL::BOOLEAN

    ELSE (
        cte.counteroffer_allowed_flag IS TRUE
        AND cte.counteroffer_rounded_amount IS NOT NULL
        AND cte.counteroffer_rounded_amount > 0
        AND cte.counteroffer_rounded_amount < cte.requested_amount
        AND cte.counteroffer_rounded_amount >= cte.product_min_approved_amount
        AND cte.counteroffer_rounded_amount >= cte.requested_amount * cte.product_min_counteroffer_pct
        AND cte.counteroffer_rounded_amount >= cte.requested_amount * (1.0 - cte.product_max_exposure_reduction_pct)
        AND cte.counteroffer_rounded_amount <= cte.product_max_approved_amount
        AND cte.counteroffer_test_payment_to_income_ratio <= cte.counteroffer_target_pti
        AND cte.counteroffer_test_expected_loss_amount <= cte.product_approved_el_cap
    )
END AS counteroffer_feasibility_pass_flag,
```

### SQL 22324

**Final Decision Resolution Layer.**

Lines 22327–22337.

```text
BUSINESS PURPOSE:
    Resolve preliminary routing plus exposure-treatment feasibility into final simulated strategy
    outcomes for each synthetic applicant.

    Section 9 answers:

        "Given preliminary routing and exposure-treatment feasibility, what is the final simulated
         strategy outcome for this synthetic applicant?"

    Section 9 does not answer:

```

### SQL 23059

**Resolve each final outcome.**

Lines 23129–23152.

```text
CASE
    WHEN ri.preliminary_decision_outcome = 'APPROVE'
        THEN 'APPROVE'

    WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
     AND ri.counteroffer_feasibility_pass_flag IS TRUE
        THEN 'COUNTEROFFER'

    WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
     AND ri.counteroffer_feasibility_pass_flag IS FALSE
     AND ri.failed_counteroffer_resolution = 'MANUAL_REVIEW'
        THEN 'MANUAL_REVIEW'

    WHEN ri.preliminary_decision_outcome = 'COUNTEROFFER'
     AND ri.counteroffer_feasibility_pass_flag IS FALSE
     AND ri.failed_counteroffer_resolution = 'DECLINE'
        THEN 'DECLINE'

    WHEN ri.preliminary_decision_outcome = 'MANUAL_REVIEW'
        THEN 'MANUAL_REVIEW'

    WHEN ri.preliminary_decision_outcome = 'DECLINE'
        THEN 'DECLINE'

```

### SQL 23345

**Assign the approved amount.**

Lines 23379–23393.

```text
CASE
    WHEN df.decision_outcome = 'APPROVE'
        THEN df.requested_amount

    WHEN df.decision_outcome = 'COUNTEROFFER'
        THEN df.approved_amount_preliminary

    WHEN df.decision_outcome = 'MANUAL_REVIEW'
        THEN NULL::NUMERIC

    WHEN df.decision_outcome = 'DECLINE'
        THEN 0::NUMERIC

    ELSE NULL::NUMERIC
END AS approved_amount,
```

### SQL 26128

**Simulated Reason-Code Assignment Layer.**

Lines 26131–26141.

```text
BUSINESS PURPOSE:
    Assign deterministic simulated strategy explanation codes after final decision resolution.

    Section 10 answers:

        "Why did this synthetic applicant receive this simulated strategy outcome?"

    Section 10 does not answer:

        "What real applicant communication would be sent?"
        "What regulatory notice would be produced?"
```

### SQL 27339

**Assign deterministic reasons.**

Lines 27351–27372.

```text
SELECT
    rr.application_id,

    MAX(CASE WHEN rr.reason_rank = 1 THEN rr.candidate_reason_code END)
        AS primary_reason_code,

    MAX(CASE WHEN rr.reason_rank = 2 THEN rr.candidate_reason_code END)
        AS secondary_reason_code,

    MAX(CASE WHEN rr.reason_rank = 3 THEN rr.candidate_reason_code END)
        AS tertiary_reason_code,

    MAX(CASE WHEN rr.reason_rank = 1 THEN rr.candidate_reason_family END)
        AS primary_reason_family,

    STRING_AGG(
        rr.candidate_reason_code,
        '|' ORDER BY
            rr.reason_rank,
            rr.candidate_reason_priority_rank,
            rr.candidate_reason_code
    ) AS triggered_reason_code_list,
```

### SQL 29364

**Latest-Run Strategy Decision Output Table.**

Lines 29367–29377.

```text
BUSINESS PURPOSE:
    Materialize the completed Module 2 latest-run strategy output table.

    Section 11 answers:

        "What is the current final simulated strategy output for the selected Module 1 source
         population / scenario and active Module 2 strategy?"

    Section 11 does not answer:

        "What historical strategy runs exist?"
```

### SQL 32935

**Strategy Decision Archive Persistence Layer.**

Lines 32938–32948.

```text
BUSINESS PURPOSE:
    Persist completed latest-run Module 2 strategy outputs into the governed strategy archive.

    Section 12 answers:

        "Should this completed Module 2 latest-run strategy output become governed historical
         evidence, and if so, how should the archive handle prior rows for the same strategy /
         Module 1 scenario / population slice?"

    Section 12 is the history-control layer.

```

### SQL 34160

**Apply the archive replacement scope.**

Lines 34198–34204.

```text
IF v_existing_key_count > 0 THEN
    RAISE EXCEPTION
        'Module 2 Section 12 failure: strategy_archive_reset_mode = NONE but archive already contains % row(s) for the current replacement key.',
        v_existing_key_count;
END IF;

v_archive_action := 'ARCHIVE_INSERTED_NONE_MODE_NO_PRIOR_KEY';
```

Lines 34207–34226.

```text
ELSIF v_strategy_archive_reset_mode = 'STRATEGY_SCENARIO_ONLY' THEN
    /*-----------------------------------------------------------------------------------
    STRATEGY_SCENARIO_ONLY:
        Ordinary governed rerun behavior.

        Deletes only the prior archived rows for the current:
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id.
    -----------------------------------------------------------------------------------*/
    DELETE FROM credit_decisioning_sim.strategy_decisions_archive
    WHERE strategy_set_name = v_strategy_set_name
      AND strategy_name = v_strategy_name
      AND strategy_version = v_strategy_version
      AND module1_scenario_set_name = v_module1_scenario_set_name
      AND module1_scenario_name = v_module1_scenario_name
      AND population_id = v_population_id;
```

### SQL 36644

**Archive Inventory And Matched Strategy Comparison Framework.**

Lines 36647–36657.

```text
BUSINESS PURPOSE:
    Provide read-only archive inventory and governed matched strategy comparison diagnostics.

    Section 13 answers:

        "How do two archived Module 2 strategy runs differ when applied to the same Module 1
         scenario and population?"

    Section 13 does not answer:

        "Is the current latest-run output valid?"
```

### SQL 40909

**Module 2 Validation, Qa, And Strategy Outcome Diagnostics.**

Lines 40912–40922.

```text
BUSINESS PURPOSE:
    Provide the full read-only QA and validation evidence framework for the completed latest-run
    Module 2 strategy output.

    Section 14 answers:

        "Does this completed Module 2 strategy run behave coherently, consistently, explainably,
         and within the documented simulation boundaries?"

    Section 14 also creates the validation evidence foundation for later:
        validation-summary drafting,
```

### SQL 49072

**Strategy Frontier Summary And Executive Comparison View.**

Lines 49075–49085.

```text
BUSINESS PURPOSE:
    Provide an executive-ready, archive-backed strategy frontier view across completed Module 2
    strategy outputs.

    Section 15 answers:

        "Across archived Module 1 scenario × Module 2 strategy slices, what are the portfolio-level
         tradeoffs between simulated offer exposure, approved amount, approved Expected Loss,
         affordability, synthetic estimated-risk profile, counteroffer usage, Option C ordinary-versus-
         aggressive counteroffer path behavior, manual-review burden, decline rate, product behavior,
         score-band behavior, and simulated reason-code movement?"
```

### SQL 55066

**Run-Level Strategy Evidence Capture And Executive Story Register.**

Lines 55069–55079.

```text
BUSINESS PURPOSE:
    Persist compact, executive-ready evidence for each completed Module 2 strategy run.

    Section 16 answers:

        "For the current completed Module 2 latest-run strategy slice, what evidence should be
         captured so the result can be reviewed, validated, explained, compared, documented, and
         later used in portfolio storytelling?"

    The Module 2 latest-run table and archive table preserve applicant-level simulated strategy
    outputs.
```

### SQL 67457

**Post-Campaign Acceptance, Export, Parameter Audit, And Strategy Effect Review.**

Lines 67460–67470.

```text
BUSINESS PURPOSE:
    Provide the final post-campaign control tower after all planned Module 2 campaign runs have been
    completed, archived, validated, compared, summarized, synchronized, and captured into persistent
    evidence.

    Section 17 answers:

        "Is the completed Module 2 campaign structurally complete, registry-aligned,
         evidence-complete, convention-clean, comparison-ready, source-consistent,
         parameter-traceable, product-policy-audited, and analytically ready for final
         interpretation?"
```
