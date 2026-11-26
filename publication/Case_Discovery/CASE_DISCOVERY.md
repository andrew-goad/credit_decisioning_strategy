# Find teaching cases in the original campaign

The [saved teaching examples](Returned/teaching_cases.csv) contain 464 selections across 20 comparisons. The [selection receipt](Returned/campaign_provenance.json) records the historical executions used. To repeat selection on a database containing those executions, open [discover_teaching_cases.sql](discover_teaching_cases.sql) in DBeaver and export all rows as UTF-8 CSV with a header and blank SQL nulls. The result carries both case records and full-population counts for the seven questions below.

Each comparison uses the two run IDs, scenario and population listed in the [original comparison registry](https://github.com/andrew-goad/credit_decisioning_strategy/blob/65e7cc84528008ea40c6f9bb70a02745df592f4c/Module_2_Credit_Policy_Strategy_%26_Decision_Outcome_Simulation_Engine/v1.0/outputs/module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0_OUTPUT_strategy_comparison_campaign_registry.csv). The query uses the execution mapping in [the full campaign export](../full_lookup/export_original_campaign.sql). The published timestamp takes precedence for each run. For M2-01 only, the project owner also approved the May 28 refresh. The original and refreshed timestamps are distinguishable in the execution receipt. Thirty-one of those runs participate in registered pairs. A scenario with just two registered strategies can supply cases.

| Question | An application qualifies when |
| --- | --- |
| New offer | Baseline reviewed or declined it and the challenger approved or counteroffered. |
| Lost offer | Baseline approved or counteroffered and the challenger reviewed or declined it. |
| Same counteroffer outcome, different amount | Both decisions were counteroffers and the two recorded approved amounts differed. |
| Ordinary counteroffer candidate receives an offer | The challenger marked the request as an ordinary candidate, did not mark an aggressive override, and made a positive counteroffer below the request. |
| Override candidate ends in review | The challenger marked a requested-structure override and its final decision was manual review. |
| The reason changes for the same outcome | Both decisions had the same final outcome and distinct, populated primary reason codes. |
| An unchanged approval at the requested amount | Both policies approved the full request. |

**Read the denominator first.** A pair qualifies only when each side has 50,000 rows and distinct IDs, matches its registered source slice, matches all 50,000 application IDs across policies and has zero differences across the 13 tested source fields. These cover applicant identity, product, score band, score, income, requested amount, DTI, requested payment, requested PTI, amount-to-income ratio, estimated PD, estimated LGD and requested expected loss. A non-ready pair returns the reason and leaves the lesson count blank. A ready pair with no qualifying case returns **0** and an empty example.

**Read each count once.** The full qualifying count repeats beside up to four examples for that pair/question. Sample selection takes one example per product/score-band cell before taking additional examples from a cell. A fixed hash of pair, question and application ID gives reproducible ordering. One applicant can meet multiple questions, and the same application IDs recur across pairs. Adding lesson counts would double count applicants. The examples illustrate mechanisms, and their order carries no risk or economic ranking.

Use the application ID and two run IDs to look up the underlying rows. The output includes requested terms, risk proxies, both final decisions, both approved amounts, both modeled losses, both primary reasons and recorded paths. A manual-review amount can be blank because the decision is unresolved. A change in reason code identifies a candidate for inspecting decision rules. Establish the mechanism from the underlying rule and its active settings before drawing a causal conclusion.

The query was parsed against the actual Module 2 PostgreSQL 17 archive schema. A separate controlled fixture exercised all seven questions, genuine zero counts, a missing run, input drift and product/score sampling. Those test values describe the fixture. Counts and case selections for the original campaign come from executing the query on that database.
