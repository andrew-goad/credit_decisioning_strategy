# Module 2 Decision Simulator Build

## Part 74

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_73.md) · [Next](Part_75.md)

<a id="c038-m01506"></a>

### C038-M01506

**ChatGPT** · 2026-05-12T08:35:00.724666-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01506 -->
Next, update **Section 16**, specifically the **Section 16 opening header** and the **end-of-Section-16.0–16.8 footer**. That is the right next step because Section 16 is the run-level evidence capture layer that consumes Section 14 validation evidence and Section 15 frontier evidence, while Section 16.9 is now the separate post-campaign synchronization layer. fileciteturn215file11 fileciteturn215file7

Replace your current **Section 16 opening header** with this:

```sql
/***************************************************************************************************
SECTION 16 — RUN-LEVEL STRATEGY EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER
****************************************************************************************************

BUSINESS PURPOSE:
    Persist compact, executive-ready evidence for each completed Module 2 strategy run.

    Section 16 answers:

        "For the current completed Module 2 latest-run strategy slice, what evidence should be
         captured so the result can be reviewed, validated, explained, compared, documented, and
         later used in portfolio storytelling?"

    The Module 2 latest-run table and archive table preserve applicant-level simulated strategy
    outputs.

    Section 13 produces matched comparison diagnostics.
    Section 14 produces latest-run validation status evidence.
    Section 15 produces archive-backed frontier evidence.

    Section 16 distills those outputs into persistent evidence tables so the project can support:
        repeatable campaign tracking,
        executive storytelling,
        validation-summary drafting,
        README / portfolio evidence,
        LinkedIn campaign evidence,
        parameter traceability,
        product × score segment traceability,
        and future Module 3 growth / economics design.

IMPORTANT SECTION 16 SCOPE CLARIFICATION:
    Section 16.0–16.8 is run-level evidence capture.

    Section 16.9 is post-campaign frontier evidence synchronization.

    These are related, but they serve different workflow moments.

        Section 16.0–16.8:
            Run after each completed strategy run.

        Section 16.9:
            Run only after the full campaign archive is complete and Section 15 has been rerun from
            the completed archive.

WHY THIS DISTINCTION MATTERS:
    Section 15 is archive-wide.

    Section 16.0–16.8 captures evidence one current run at a time.

    During a full campaign, early evidence rows may be captured before every baseline / challenger
    archive slice exists. After later runs or reruns are completed, Section 15 may produce updated
    frontier labels and baseline-relative reason-code movement fields.

    Section 16.9 refreshes those Section 15-derived frontier fields in persistent executive evidence
    after the completed campaign frontier is available.

SQL PURPOSE:
    1. Identify the current completed latest-run Module 2 strategy slice.
    2. Consume the Section 3 campaign registry match as the preferred run-ID and story-ID source.
    3. Create fallback current-run story metadata only when registry fallback is allowed.
    4. Confirm required Section 14 and Section 15 temporary evidence outputs exist.
    5. Confirm strategy and product-policy parameter tables exist for parameter snapshot capture.
    6. Create persistent evidence tables if they do not already exist.
    7. Add registry-ID columns to existing evidence tables when needed.
    8. Delete prior evidence rows for the current run key only.
    9. Persist Section 14 validation-status evidence for the current run.
    10. Persist the exact active Module 2 strategy parameter card, product-policy card, and run-story
        metadata as JSONB.
    11. Persist current product × score segment evidence.
    12. Persist the current one-row executive evidence summary.
    13. Validate current-run evidence capture through local Section 16.7 gatekeepers.
    14. Display compact export-ready Section 16.8 diagnostics.

PRIMARY INPUTS:
    credit_decisioning_sim.strategy_decisions
        Current completed latest-run Module 2 strategy output.

    tmp_m2_campaign_registry_current_run_match
        Temporary Section 3 campaign registry match helper.

        Preferred source for:
            module1_run_id
            module2_run_id
            run_sequence_number
            showcase_id
            showcase_name
            comparison_group_id
            validation_evidence_group_id
            readme_storyline_label
            linkedin_post_sequence
            validation_summary_section_hint
            run_registry_match_status

    tmp_m2_validation_status_summary
        Temporary Section 14 validation status summary.

    tmp_m2_strategy_frontier_executive_summary
        Temporary Section 15 strategy frontier executive summary.

        Section 16.6 reads this table to carry Section 15-derived frontier posture fields into the
        current one-row executive evidence summary.

    tmp_module2_strategy_params
        Temporary active Module 2 strategy parameter card.

    tmp_module2_product_policy_params
        Temporary active product-policy parameter card.

TEMPORARY OUTPUTS CREATED:
    tmp_m2_current_run_key
    tmp_m2_current_run_story_params

PERSISTENT OUTPUT TABLES CREATED OR REUSED:
    credit_decisioning_sim.strategy_run_evidence_summary
    credit_decisioning_sim.strategy_run_validation_evidence
    credit_decisioning_sim.strategy_run_parameter_snapshot
    credit_decisioning_sim.strategy_run_segment_evidence_summary

EVIDENCE GRAIN:
    The primary run-level evidence grain is:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

    This is the same practical completed-run grain used for archive replacement and strategy evidence
    interpretation.

CAMPAIGN REGISTRY ID ROLE:
    Campaign IDs are documentation and evidence-linkage metadata.

    They help connect:

        run roadmap
        → SQL output
        → archive slice
        → comparison result
        → executive evidence row
        → validation evidence rows
        → parameter snapshot
        → segment evidence
        → future Validation Summary claim
        → README / LinkedIn campaign storyline

    They do not replace the technical SQL run key.

    Technical run key fields remain:

        module1_scenario_set_name
        module1_scenario_name
        population_id
        strategy_set_name
        strategy_name
        strategy_version

WHY SECTION 16 EXISTS:
    During a multi-run scenario / strategy campaign, the user should not have to manually collect key
    results from many separate QA grids after every run.

    Section 16 captures the story in one governed evidence layer:
        What Module 1 scenario was used?
        What Module 2 strategy was applied?
        What campaign run IDs identify this run?
        What showcase and comparison group does this run support?
        What validation evidence group should this run feed?
        What strategy family changed?
        What was expected to happen?
        What were the final simulated outcomes?
        What was the simulated offer-exposure rate?
        What was the approved exposure?
        What was the approved Expected Loss?
        What product and score segments drove the result?
        Which simulated reason codes explain the result?
        Which validation checks passed?
        Which validation checks require interpretation?
        Which validation checks were not applicable?
        What parameter card produced the output?
        What evidence will support later Module 3 growth / economics design?

WHY SECTION 16 USES EVIDENCE TABLES INSTEAD OF THE LATEST-RUN TABLE:
    credit_decisioning_sim.strategy_decisions is replaceable.

    It represents only the current completed latest-run output.

    Evidence tables persist the executive story, validation summary, parameter snapshot, and segment
    profile for completed runs across the campaign.

WHY SECTION 16 DOES NOT WRITE TO THE ARCHIVE:
    Archive persistence is governed by Section 12.

    Section 16 does not insert, delete, update, or repair archive rows.

    Evidence capture and archive persistence are separate governance functions.

WHY DELETE / INSERT IS USED FOR CURRENT-RUN EVIDENCE:
    A strategy slice may be rerun under governed archive replacement behavior.

    Evidence rows should reflect the current accepted version of that run key, not accumulate stale
    duplicates for the same strategy / scenario / population evidence grain.

    Therefore Section 16 deletes and replaces evidence rows only for the current run key in the
    evidence tables.

WHY PARAMETER SNAPSHOTS ARE CAPTURED:
    The active strategy and product-policy tables are temporary.

    Without a persistent parameter snapshot, later documentation may show what happened but not
    exactly which thresholds, product caps, counteroffer controls, archive controls, and registry IDs
    produced the run.

    Section 16.4 snapshots:
        active strategy parameters,
        product-policy parameters,
        run-story / registry metadata,
        and a parameter snapshot hash.

WHY PRODUCT × SCORE SEGMENT EVIDENCE IS CAPTURED:
    The one-row executive evidence summary is intentionally compact.

    Product × score segment evidence preserves the drill-down layer needed to support executive
    interpretation.

    Strategy movement often concentrates in segments such as:
        unsecured / weaker-score applicants,
        revolving / weaker-score applicants,
        secured / stronger-score applicants,
        near-prime product segments,
        or high-balance product segments.

WHY FRONTIER FIELDS COME FROM SECTION 15:
    Section 15 already calculates archive-backed frontier posture, executive quadrant, and
    baseline-relative reason-code movement.

    Section 16.6 carries those fields into persistent evidence rather than recalculating the frontier.

    After the full campaign is complete, Section 16.9 can refresh those fields from a fresh Section
    15 run.

READ / WRITE BOUNDARY:
    Section 16.0–16.8 may create persistent evidence tables.

    Section 16.0–16.8 may delete and replace evidence rows for the current run key only in:

        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

    Section 16.0–16.8 does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive
        credit_decisioning_sim.strategy_run_campaign_registry
        credit_decisioning_sim.strategy_comparison_campaign_registry

MODELING BOUNDARY:
    Section 16 does not recalculate decision_outcome.
    Section 16 does not recalculate decision_path.
    Section 16 does not recalculate approved_amount.
    Section 16 does not recalculate approved_payment_to_income_ratio.
    Section 16 does not recalculate approved_expected_loss_amount.
    Section 16 does not reassign simulated reason codes.
    Section 16 does not modify rule triggers.
    Section 16 does not modify strategy thresholds.
    Section 16 does not modify product-policy thresholds.

MODULE 3 READINESS BOUNDARY:
    Section 16 captures growth-readiness fields such as:
        approved exposure,
        requested exposure,
        APR proxy,
        term,
        product mix,
        score mix,
        approved Expected Loss,
        and simulated offer-exposure rate.

    These fields will be useful for a future Module 3 economics layer.

    Section 16 does not calculate:
        revenue,
        yield,
        funding cost,
        risk-adjusted margin,
        profitability,
        capital,
        pricing optimization,
        net income,
        lifetime value,
        or risk-adjusted return.

INTERPRETATION BOUNDARIES:
    estimated_pd remains the SQL field name from Module 1 and is interpreted as the synthetic
    estimated-PD proxy.

    requested_expected_loss_amount means requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount means simulated approved-exposure Expected Loss after Module 2
    exposure treatment.

    approved_expected_loss_rate is a synthetic strategy evidence metric.
    It is not a production loss-rate forecast.

    simulated_offer_exposure_flag means the simulated strategy produced positive offer exposure
    through APPROVE or COUNTEROFFER.

    simulated_offer_exposure_flag does not imply:
        operational account creation,
        booked exposure,
        funded exposure,
        production approval,
        customer treatment,
        or real applicant treatment.

    Reason codes remain simulated strategy explanation codes.

    They are not:
        customer communications,
        regulatory notices,
        adverse-action reasons,
        fair-lending conclusions,
        or production compliance determinations.

VALIDATION STATUS INTERPRETATION:
    PASS:
        The validation check satisfied the expected behavior.

    REVIEW:
        The pattern should be interpreted before documentation.

        REVIEW does not automatically mean the run is invalid.

    NOT_APPLICABLE:
        The test could not be evaluated in the current run context, usually because a comparison,
        archive slice, or relevant subpopulation is unavailable.

OPERATING GUIDANCE — SINGLE RUN:
    For a single completed strategy run:
        1. Run Section 14.
        2. Run Section 15.
        3. Run Section 16.0–16.8.
        4. Review Section 16.8 outputs.
        5. Stop, or proceed to the next selected run.

OPERATING GUIDANCE — FULL CAMPAIGN:
    For a full campaign:
        1. Run each planned strategy slice through Section 16.8.
        2. After all planned archive slices are complete, rerun Section 15 from the completed archive.
        3. Run Section 16.9 to synchronize Section 15-derived frontier fields into persistent
           executive evidence.
        4. Run Section 17 for final campaign acceptance.

COMMON MISUSE TO AVOID:
    Do not treat Section 16 evidence rows as applicant-level outputs.
    Do not treat campaign IDs as replacements for technical run keys.
    Do not treat Section 16.8 diagnostics as final campaign acceptance.
    Do not run Section 16.9 before rerunning Section 15 from the completed campaign archive.
    Do not interpret Section 16 evidence as production decision evidence.
    Do not interpret Module 3 readiness fields as revenue or profitability results.

***************************************************************************************************/
```

Then replace your current **END OF SECTION 16.0–16.8** footer with this:

```sql
/***************************************************************************************************
END OF SECTION 16.0–16.8 — RUN-LEVEL STRATEGY EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER

If execution reaches this point:
    1. Persistent executive run evidence summary has been created or reused.
    2. Persistent validation evidence detail has been created or reused.
    3. Persistent strategy and product-policy parameter snapshot evidence has been created or reused.
    4. Persistent product × score segment evidence summary has been created or reused.
    5. Prior evidence rows for the current run key were replaced in the evidence tables only.
    6. Current Section 14 validation evidence detail was persisted.
    7. Current strategy, product-policy, and story parameter snapshots were persisted.
    8. Current product × score segment evidence was persisted.
    9. Current one-row executive evidence summary was persisted.
    10. Local Section 16 evidence-capture gatekeepers passed.
    11. Section 16.8 evidence diagnostics and export-ready review outputs are available.
    12. Module 3 readiness fields have been captured for future growth / economics design.

Registry evidence now carries:
    module1_run_id
    module2_run_id
    run_sequence_number
    showcase_id
    showcase_name
    comparison_group_id
    validation_evidence_group_id
    readme_storyline_label
    linkedin_post_sequence
    validation_summary_section_hint
    run_registry_match_status

Current-run evidence capture boundary:
    Section 16.0–16.8 may create, delete, and replace persistent evidence rows for the current run
    key only.

    Section 16.0–16.8 does not modify latest-run output rows.
    Section 16.0–16.8 does not modify archive rows.
    Section 16.0–16.8 does not modify campaign registry rows.
    Section 16.0–16.8 does not modify comparison registry rows.
    Section 16.0–16.8 does not modify strategy parameter rows.
    Section 16.0–16.8 does not modify product-policy parameter rows.
    Section 16.0–16.8 does not recalculate decision outcomes.
    Section 16.0–16.8 does not recalculate approved exposure values.
    Section 16.0–16.8 does not recalculate approved Expected Loss values.
    Section 16.0–16.8 does not reassign simulated reason codes.
    Section 16.0–16.8 does not implement revenue, earnings, pricing, funding-cost, profitability,
    capital, or risk-adjusted margin logic.

Workflow guidance:
    For a single run:
        Stop here after reviewing Section 16.8 outputs, or proceed to the next selected run.

    For a full campaign:
        After all planned runs have completed through Section 16.8, rerun Section 15 from the
        completed archive, then run Section 16.9, then run Section 17.

Why Section 16.9 remains separate:
    Section 16.0–16.8 captures the current run's evidence at the time the run is completed.

    Section 16.9 refreshes Section 15-derived frontier fields after the full campaign frontier is
    complete.

    Keeping the steps separate makes the workflow clearer:
        run-level capture first;
        campaign-wide synchronization later.

***************************************************************************************************/
```

After this, the remaining workflow-alignment update is **Section 17**.
<!-- END_MESSAGE C038-M01506 -->


---

<a id="c038-m01508"></a>

### C038-M01508

**Andrew** · 2026-05-12T08:38:15.906000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01508 -->
proceed with the remaining workflow alignment update section 17.
<!-- END_MESSAGE C038-M01508 -->


---

<a id="c038-m01513"></a>

### C038-M01513

**ChatGPT** · 2026-05-12T08:42:16.452718-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01513 -->
According to the current Module 2 SQL file, Section 17 already serves as the final post-campaign control tower and includes checks 17.1–17.20 for archive inventory, registry reconciliation, evidence coverage, comparison readiness, strategy effects, parameter audit, product-guardrail exact-value audit, and final campaign acceptance. fileciteturn216file3 This update is a **workflow-alignment patch**: keep the existing 17.1–17.20 SQL queries unchanged and replace only the **Section 17 opening header** and **END OF SECTION 17 footer**.

### Replace the current Section 17 opening header with this

```sql
/***************************************************************************************************
SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW
****************************************************************************************************

BUSINESS PURPOSE:
    Provide the final post-campaign control tower after all planned Module 2 campaign runs have been
    completed, archived, validated, compared, summarized, synchronized, and captured into persistent
    evidence.

    Section 17 answers:

        "Is the completed Module 2 campaign structurally complete, registry-aligned,
         evidence-complete, convention-clean, comparison-ready, source-consistent,
         parameter-traceable, product-policy-audited, and analytically ready for final
         interpretation?"

WHY THIS SECTION EXISTS:
    Earlier sections execute, validate, archive, compare, summarize, and capture the strategy
    campaign.

        Section 11:
            materializes the latest-run strategy output.

        Section 12:
            persists completed latest-run output into the governed strategy archive.

        Section 13:
            provides archive-backed matched baseline / challenger comparison.

        Section 14:
            validates latest-run behavior and creates validation evidence.

        Section 15:
            summarizes archive-backed strategy frontier tradeoffs.

        Section 16.0–16.8:
            persists run-level executive evidence, validation evidence, parameter snapshots, and
            product × score segment evidence.

        Section 16.9:
            synchronizes fresh Section 15-derived frontier fields into persistent executive evidence
            after the full campaign archive is complete.

    Section 17 is different.

    Section 17 does not create new strategy output.
    Section 17 does not persist new evidence.
    Section 17 does not synchronize frontier evidence.
    Section 17 reviews the completed campaign from persistent archive, registry, comparison,
    validation, parameter-snapshot, product-policy, and evidence objects.

SECTION 17 WORKFLOW POSITION:
    Section 17 is the final read-only acceptance layer.

    It should be run after:

        1. All planned Module 2 campaign runs have completed through Section 16.8.
        2. Section 15 has been rerun once from the completed campaign archive.
        3. Section 16.9 has synchronized fresh Section 15 frontier fields into:
                credit_decisioning_sim.strategy_run_evidence_summary
        4. Section 16 evidence rows exist for all accepted campaign runs.
        5. Any known reruns, repair runs, or product-policy corrections have been completed.

WHY SECTION 16.9 MUST COME BEFORE SECTION 17:
    Section 15 is archive-wide.

    Section 16.0–16.8 captures evidence one run at a time.

    If a baseline or challenger was added or rerun after earlier evidence capture, older executive
    evidence rows may still contain stale Section 15-derived frontier labels.

    Section 16.9 formalizes the refresh so Section 17 evaluates the final synchronized evidence
    state rather than a partially stale campaign evidence layer.

DO NOT RUN SECTION 1 IMMEDIATELY BEFORE SECTION 17:
    Section 1 drops the replaceable latest-run table and temporary objects.

    Section 17 is designed to read persistent archive, registry, comparison, and evidence objects.

    If the user needs to refresh frontier evidence before Section 17:
        rerun Section 15 from the completed archive;
        run Section 16.9;
        then run Section 17.

WHAT SECTION 17 INCLUDES:
    17.1  Archive campaign inventory.
    17.2  Archive slice detail.
    17.3  Archive grain duplicate check.
    17.4  Campaign registry to archive reconciliation.
    17.5  Registry runs missing or mismatched in archive.
    17.6  Archive slices without active campaign registry row.
    17.7  Section 16 evidence coverage summary.
    17.8  Section 16 evidence coverage detail by run.
    17.9  Full-archive final-output convention checks.
    17.10 Validation status summary by campaign run.
    17.11 Validation REVIEW / NOT_APPLICABLE concentration.
    17.12 Comparison registry readiness.
    17.13 Matched comparison source-field consistency.
    17.14 Executive evidence campaign summary.
    17.15 Baseline × challenger delta summary.
    17.16 Product guardrail strategy effect check.
    17.17 Counteroffer-first strategy effect check.
    17.18 Parameter snapshot profile audit.
    17.19 Product guardrail policy exact-value audit.
    17.20 Final Module 2 campaign acceptance rollup.

WHY THE FORMER CAMPAIGN QUERIES 16–20 ARE AT THE END:
    The prior standalone campaign QA queries 16–20 are now represented by the closing Section 17
    checks:

        product guardrail strategy effect check,
        counteroffer-first strategy effect check,
        parameter snapshot profile audit,
        product guardrail policy exact-value audit,
        and final campaign acceptance rollup.

    Section 17 adds earlier campaign-wide completeness, reconciliation, evidence, convention, and
    comparison-readiness checks first, then keeps those strategy-effect and acceptance checks as the
    final executive acceptance layer.

EXPECTED CURRENT FORMAL CAMPAIGN SHAPE:
    active campaign registry runs:
        36

    active comparison groups:
        17

    archived strategy / scenario / population slices:
        36

    archived applicant rows:
        1,800,000

    rows per archived campaign slice:
        50,000

    Section 16 executive evidence rows:
        36

    Section 16 parameter snapshot rows:
        36

    Section 16 validation evidence run count:
        36

    Section 16 segment evidence run count:
        36

    expected product guardrail policy audit rows:
        5 product-guardrail runs × 2 audited products = 10 rows

WHAT TO LOOK FOR IN SECTION 17 RESULTS:
    Archive inventory:
        The campaign should have 36 archived slices, 1,800,000 archived rows, and 50,000 rows per
        slice.

    Archive grain:
        Duplicate archive-grain count should be zero.

    Registry reconciliation:
        Every active campaign registry run should have exactly one matching archived strategy slice.

    Evidence coverage:
        Every accepted campaign run should have executive evidence, validation evidence, parameter
        snapshot evidence, and segment evidence.

    Final-output conventions:
        Full-archive convention violation counts should be zero.

    Validation status:
        PASS rows are expected.
        REVIEW rows should be interpreted before documentation.
        NOT_APPLICABLE rows should be understood in context.

    Comparison readiness:
        All 17 formal comparison groups should be ready after the full campaign archive is complete.

    Source-field consistency:
        Matched baseline and challenger source fields should match so Module 2 strategy deltas are not
        contaminated by Module 1 population drift.

    Executive evidence:
        Frontier labels should reflect the fresh post-campaign Section 15 state after Section 16.9.

    Parameter snapshots:
        Strategy and product-policy payloads should be present and traceable for every accepted run.

    Product guardrail audit:
        Product-guardrail strategy runs should preserve intended exact UPL and revolving-line policy
        values.

    Final acceptance:
        The final Section 17.20 status should ordinarily be:
            MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS

CREDIT RISK CONCEPTS TAUGHT IN THIS SECTION:
    Archive completeness:
        Confirms the campaign has a complete governed history layer.

    Registry reconciliation:
        Confirms documentation run IDs reconcile to technical archive keys.

    Matched comparison:
        Confirms baseline and challenger strategy slices use the same Module 1 scenario, population,
        and immutable source fields so strategy deltas are not contaminated by upstream population
        drift.

    Output conventions:
        Confirms APPROVE, COUNTEROFFER, MANUAL_REVIEW, and DECLINE rows obey final exposure,
        affordability, Expected Loss, simulated offer-exposure, and reason-code conventions.

    Validation status interpretation:
        PASS means the expectation was satisfied.
        REVIEW means the item needs interpretation before documentation.
        NOT_APPLICABLE means the test could not be evaluated in that run context.

    Product guardrails:
        Product-specific tightening should affect intended products and should not unintentionally
        change unaffected products.

    Counteroffer-first treatment:
        A counteroffer-first strategy should increase reduced-exposure treatment and generally reduce
        approved PTI / approved Expected Loss on final counteroffer rows.

    Parameter snapshots:
        Strategy results are not fully governed unless the parameter payload that produced them is
        preserved and audit-readable.

    Frontier synchronization:
        Executive evidence frontier labels should reflect the completed campaign archive, not an
        intermediate pre-rerun or pre-baseline state.

SQL TEACHING POINTS:
    Section 17 uses campaign-wide CTEs and grouped summaries to create an acceptance rollup.

    Important SQL patterns include:
        COUNT(*) FILTER:
            compact conditional counting.

        LEFT JOIN:
            makes missing registry / archive / evidence relationships visible.

        FULL campaign aggregation:
            validates the whole campaign rather than one current latest-run output.

        IS DISTINCT FROM:
            safely detects mismatches even when NULL values are involved.

        CROSS JOIN of one-row CTEs:
            combines independent acceptance dimensions into one final acceptance row.

        CASE-based acceptance status:
            converts many technical checks into one executive-readable final status.

INTERPRETATION BOUNDARIES:
    Section 17 validates campaign evidence quality and strategy-effect directionality.

    Section 17 does not declare production approval.
    Section 17 does not validate real applicant treatment.
    Section 17 does not create customer notices.
    Section 17 does not create adverse-action reasons.
    Section 17 does not make fair-lending conclusions.
    Section 17 does not calculate revenue, margin, funding cost, capital, profitability, or Module 3
    economics.
    Section 17 does not replace the written Validation Summary.

READ-ONLY BOUNDARY:
    Section 17 does not insert rows.
    Section 17 does not delete rows.
    Section 17 does not update rows.
    Section 17 does not modify the latest-run table.
    Section 17 does not modify the archive.
    Section 17 does not modify evidence tables.
    Section 17 does not modify campaign registry tables.
    Section 17 does not modify comparison registry tables.
    Section 17 does not modify strategy parameters.
    Section 17 does not modify product-policy parameters.
    Section 17 does not recalculate decisions.
    Section 17 does not recalculate approved exposure.
    Section 17 does not recalculate approved Expected Loss.
    Section 17 does not reassign simulated reason codes.
    Section 17 does not synchronize frontier evidence.
    Section 17 does not build Module 3 economics.

COMMON MISUSE TO AVOID:
    Do not run Section 17 before completing all planned campaign runs.
    Do not run Section 17 before rerunning Section 15 from the completed archive.
    Do not run Section 17 before running Section 16.9 after campaign reruns.
    Do not interpret REVIEW as automatic failure.
    Do not interpret a clean Section 17 as production approval.
    Do not interpret simulated offer exposure as booked or funded exposure.
    Do not interpret approved Expected Loss as a production loss forecast.
    Do not interpret simulated reason-code movement as customer communication language.
    Do not use Section 17 as a substitute for the written Validation Summary.

***************************************************************************************************/
```

### Replace the current END OF SECTION 17 footer with this

```sql
/***************************************************************************************************
END OF SECTION 17 — POST-CAMPAIGN ACCEPTANCE, EXPORT, PARAMETER AUDIT, AND STRATEGY EFFECT REVIEW

If execution reaches this point:
    1. Archive campaign inventory has been reviewed.
    2. Archive slice detail has been displayed.
    3. Archive grain duplicates have been checked.
    4. Campaign registry rows have been reconciled to archive slices.
    5. Registry/archive missing or mismatch detail has been displayed.
    6. Orphan archive slices have been checked.
    7. Section 16 evidence coverage has been summarized.
    8. Section 16 evidence detail has been displayed by run.
    9. Full-archive final-output conventions have been checked.
    10. Validation status has been summarized by campaign run.
    11. Validation REVIEW / NOT_APPLICABLE concentration has been reviewed.
    12. Comparison registry readiness has been checked.
    13. Matched comparison source-field consistency has been checked.
    14. Executive evidence campaign summary has been displayed.
    15. Baseline × challenger deltas have been displayed.
    16. Product guardrail strategy effects have been reviewed.
    17. Counteroffer-first strategy effects have been reviewed.
    18. Parameter snapshot completeness has been reviewed.
    19. Product guardrail policy snapshots have been compared to intended canonical values.
    20. Final campaign acceptance has been summarized in one status row.

Interpretation of final acceptance:
    MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        Archive, registry, evidence, convention, comparison, source-consistency, and audited
        product-policy checks are clean.

        This means the campaign SQL evidence is structurally ready for executive interpretation,
        README drafting, LinkedIn storytelling, and written Validation Summary drafting within the
        documented simulation boundaries.

    STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        Structural, archive, evidence, convention, comparison, and source-consistency checks are
        clean, but at least one audited product-guardrail parameter snapshot does not match intended
        canonical values.

        This status means the campaign may be structurally complete, but the product-guardrail
        parameter evidence should be reviewed before final interpretation.

    REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        One or more structural, archive, registry, evidence, convention, comparison, source-field,
        or parameter checks require review.

        This status means final documentation should pause until the specific Section 17 diagnostic
        query identifying the issue has been reviewed.

Recommended post-Section 17 workflow:
    If module2_campaign_acceptance_status = MODULE_2_CAMPAIGN_RESULTS_READY_FOR_ANALYSIS:
        1. Preserve the Section 17 outputs.
        2. Use Section 17.20 as the final campaign acceptance row.
        3. Use Section 17.14–17.17 for executive narrative development.
        4. Use Section 17.18–17.19 for parameter governance evidence.
        5. Proceed to written Validation Summary / README / LinkedIn drafting.

    If module2_campaign_acceptance_status = STRUCTURAL_ACCEPTANCE_PASS_BUT_PRODUCT_GUARDRAIL_POLICY_REVIEW_REQUIRED:
        1. Review Section 17.19.
        2. Confirm whether the product-guardrail parameter snapshot mismatch is expected or erroneous.
        3. Rerun affected campaign slices if needed.
        4. Rerun Section 15.
        5. Rerun Section 16.9.
        6. Rerun Section 17.

    If module2_campaign_acceptance_status = REVIEW_MODULE_2_CAMPAIGN_RESULTS_BEFORE_ANALYSIS:
        1. Identify which Section 17 diagnostic query produced the review condition.
        2. Correct archive, registry, comparison, evidence, source-consistency, validation, or
           parameter issues as needed.
        3. Rerun affected campaign slices only if the issue affects accepted strategy output.
        4. Rerun Section 15 after archive-changing corrections.
        5. Rerun Section 16.9 after a fresh Section 15 run.
        6. Rerun Section 17.

Read-only boundary:
    Section 17 did not insert archive rows.
    Section 17 did not delete archive rows.
    Section 17 did not update archive rows.
    Section 17 did not modify latest-run rows.
    Section 17 did not modify evidence rows.
    Section 17 did not modify campaign registry rows.
    Section 17 did not modify comparison registry rows.
    Section 17 did not modify strategy parameter rows.
    Section 17 did not modify product-policy parameter rows.
    Section 17 did not synchronize frontier evidence.
    Section 17 did not recalculate decision outcomes.
    Section 17 did not recalculate approved exposure values.
    Section 17 did not recalculate approved Expected Loss values.
    Section 17 did not reassign simulated reason codes.
    Section 17 did not implement revenue logic.
    Section 17 did not implement earnings logic.
    Section 17 did not implement pricing optimization logic.
    Section 17 did not implement funding-cost logic.
    Section 17 did not implement profitability logic.
    Section 17 did not implement capital logic.
    Section 17 did not implement risk-adjusted margin logic.

Final documentation boundary:
    Section 17 provides SQL evidence acceptance.

    It does not itself draft:
        BRD text,
        written Validation Summary conclusions,
        README narrative,
        LinkedIn posts,
        production policy recommendations,
        model validation approval,
        fair-lending conclusions,
        customer communications,
        or operational implementation instructions.

Final campaign workflow checkpoint:
    Full-campaign SQL workflow is complete only after:

        all planned runs through Section 16.8
        → fresh Section 15
        → Section 16.9 synchronization
        → Section 17 final acceptance

***************************************************************************************************/
```

This keeps the existing 17.1–17.20 diagnostics intact while making Section 17 explicitly depend on the finalized **Section 15 → Section 16.9 → Section 17** workflow.
<!-- END_MESSAGE C038-M01513 -->


---

<a id="c038-m01515"></a>

### C038-M01515

**Andrew** · 2026-05-12T08:53:49.886000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01515 -->
thanks.  all that is implemented.  what is next for our pass process map?
<!-- END_MESSAGE C038-M01515 -->


---

<a id="c038-m01518"></a>

### C038-M01518

**ChatGPT** · 2026-05-12T08:55:47.606301-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01518 -->
Next in the pass process map is the **sequential commentary / compatibility tightening pass for Sections 4–14**, starting with **Section 4**.

We have now completed the major workflow architecture pass:

```text
Completed:
    Section 0 / 1 workflow and job-aid update
    Redesigned Section 2 run selector / profile catalog / registry framework
    Updated Section 3 gatekeepers
    Section 15 workflow alignment
    Section 16 run-level evidence workflow alignment
    New Section 16.9 post-campaign frontier evidence synchronization
    Section 17 final acceptance workflow alignment
```

That means the next pass is no longer about big workflow architecture. It is about making the operational pipeline sharper, clearer, and fully aligned with the new profile-driven Section 2 and Section 3 gatekeeper design.

## Recommended next pass

```text
PASS 4 — Operational pipeline commentary and compatibility tightening

Start:
    Section 4 — Module 1 Source Selection and Lineage Normalization

Then continue:
    Section 5 — Derived Strategy Segmentation
    Section 6 — Rule Flag Construction
    Section 7 — Preliminary Decision Routing
    Section 8 — Approved Exposure and Counteroffer Feasibility
    Section 9 — Final Decision Resolution
    Section 10 — Simulated Reason-Code Assignment
    Section 11 — Latest-Run Output
    Section 12 — Archive Persistence
    Section 13 — Matched Strategy Comparison
    Section 14 — Validation / QA
```

Section 4 is the right next update because it is the first operational section after the redesigned gatekeepers. It consumes the active strategy parameters, product-policy parameters, source-selection scope from Section 3, and campaign registry helper from Section 3; it then creates `tmp_m2_stage_1_source_applications`, the foundation for all downstream staging. fileciteturn218file31

## Why Section 4 should be next

The redesigned Section 2 now makes the run profile-driven through `selected_module2_run_id`, strategy profiles, product-policy profiles, campaign registry, and auto-derived comparison selection. fileciteturn218file1 Section 3 now validates that setup before source staging. Section 4 needs commentary that clearly explains how the validated source-scope contract becomes the actual Module 2 input layer.

The main Section 4 goals should be:

```text
1. Align commentary to the new Section 2 / Section 3 architecture.
2. Explain how Module 1 source lineage becomes Module 2 lineage.
3. Explain how LATEST vs ARCHIVE source selection works.
4. Explain why formal campaign runs should usually use ARCHIVE.
5. Explain why campaign IDs are not inserted into applicant-level staging rows.
6. Explain how product_type becomes product_type_policy_key.
7. Explain why product-policy joins in Section 4 are validation-only.
8. Explain what to look for in Section 4 outputs.
9. Keep the comments sharp — not bloated.
```

## Suggested one-section-at-a-time sequence

I recommend we proceed like this:

```text
Next response:
    Full copy-paste patch for Section 4 only.

Then:
    Section 5 only.
    Section 6 only.
    Section 7 only.
    Section 8 only.
    Section 9 only.
    Section 10 only.
    Section 11 only.
    Section 12 only.
    Section 13 only.
    Section 14 only.
```

For Sections 4–14, I would avoid major redesign unless we find a real compatibility issue. Most of these sections already have strong staging separation. The pass should focus on elite commentary, clearer run interpretation, and alignment with the new run selector / profile catalog framework.

After that pass, the next map item would be:

```text
PASS 5 — Full integrated run test and final polish
    1. Run M2-01 baseline smoke test.
    2. Run one challenger smoke test, ideally M2-29 or M2-36.
    3. Confirm Sections 1–17 still run cleanly.
    4. Re-check Section 17 final acceptance.
    5. Freeze the SQL as final candidate.
```

So the next concrete deliverable should be:

```text
Updated Section 4 — full copy-paste patch only.
```
<!-- END_MESSAGE C038-M01518 -->


---

<a id="c038-m01519"></a>

### C038-M01519

**Andrew** · 2026-05-12T08:57:36.842000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01519 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 4 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01519 -->


---

<a id="c038-m01526"></a>

### C038-M01526

**ChatGPT** · 2026-05-12T09:08:06.097313-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01526 -->
Proceeding with **Pass 4 — Section 4 only**. This patch keeps Section 4 as the Module 1 → Module 2 source-staging layer, aligned to the redesigned Section 2 active parameter cards and the Section 3 source-scope / campaign-registry helper contract. fileciteturn218file1 fileciteturn219file17

```sql
/***************************************************************************************************
SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION
****************************************************************************************************

BUSINESS PURPOSE:
    Safely consume the validated Module 1 source slice and create the clean Module 2 input
    foundation.

    Section 4 answers:

        "Which Module 1 synthetic applicant population is the current Module 2 strategy run using,
         and has that source been normalized into a stable Module 2 staging shape?"

    This section is the formal Module 1 → Module 2 handoff layer.

    It converts the selected Module 1 latest-run table or selected Module 1 scenario archive slice
    into a governed Module 2 staging table with one row per synthetic application.

WHY THIS SECTION MATTERS:
    Every downstream Module 2 stage depends on this source-stage table.

    If Section 4 stages the wrong Module 1 scenario, mixes populations, fails to preserve lineage,
    or mis-normalizes product type, then later strategy segmentation, rule flags, routing,
    counteroffer feasibility, final decisions, reason codes, archive persistence, validation,
    comparison, frontier analysis, and evidence capture can all become misleading.

SQL PURPOSE:
    1. Confirm the Section 2 active strategy and product-policy parameter cards exist.
    2. Confirm the Section 3 source-scope helper exists.
    3. Confirm the Section 3 campaign-registry match helper exists.
    4. Read the effective Module 1 source table and scenario lineage columns from
       tmp_m2_source_selection_scope.
    5. Select the correct Module 1 input source:
            credit_decisioning_sim.synthetic_applications
        or:
            credit_decisioning_sim.synthetic_applications_scenario_archive.
    6. Detect required source-column aliases such as model_version / module1_model_version and
       base_apr_for_payment_calc / base_apr_for_payment_calculation.
    7. Normalize upstream Module 1 scenario lineage into stable Module 2 names:
            module1_scenario_set_name
            module1_scenario_name
            population_id.
    8. Preserve application-level identifiers.
    9. Preserve borrower, product, affordability, requested-structure, and risk-economics fields.
    10. Preserve Module 2 strategy identity fields in the staged input.
    11. Alias requested-exposure economics clearly for Module 2:
            requested_monthly_payment_proxy
            requested_payment_to_income_ratio
            requested_expected_loss_amount.
    12. Create product_type_policy_key for later product-policy joins.
    13. Validate that every staged source row maps to exactly one product-policy configuration.
    14. Confirm the staged source agrees with the Section 3 source-selection contract.
    15. Confirm that Section 4 does not create decision, reason-code, or approved-exposure fields.
    16. Display source-staging review outputs before Section 5 segmentation begins.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the selected Module 1 scenario / population is the intended upstream population
        for the current Module 2 strategy.

    Model governance / validation reviewers:
        Confirm that Module 1 lineage is preserved and not overwritten by Module 2 strategy metadata
        or campaign IDs.

    SQL reviewers:
        Confirm that dynamic SQL is used only to handle source-table and column-name variability,
        while the staged output schema remains fixed and governed.

    Portfolio / executive reviewers:
        Confirm that the run is traceable to the correct Module 1 scenario and Module 2 strategy
        before downstream outcomes are interpreted.

WHEN TO RUN THIS SECTION:
    Run Section 4 after:
        Section 2 profile-driven run selection and active parameter-card generation;
        Section 3 fail-fast strategy / source / product-policy / registry gatekeepers.

    Do not run Section 4 before Section 3.

    Section 4 intentionally consumes the source-scope contract created by Section 3.

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

    credit_decisioning_sim.synthetic_applications_scenario_archive
        Module 1 scenario archive, used when module1_input_source = 'ARCHIVE'.

OUTPUT:
    tmp_m2_stage_1_source_applications

OUTPUT GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

WHY MODULE 2 CONSUMES MODULE 1 RATHER THAN REWRITING MODULE 1:
    Module 1 is finalized, validated, and authoritative for synthetic applicant generation,
    product structure, affordability proxy, estimated-PD proxy, LGD, and requested-exposure Expected
    Loss.

    Module 2 consumes Module 1 outputs as the synthetic applicant and risk foundation.

    Module 2 does not redesign the synthetic population.
    Module 2 does not recalculate estimated_pd.
    Module 2 does not reinterpret Module 1 scenario outputs as forecasts.
    Module 2 does not replace Module 1 scenario lineage.

WHY LATEST-RUN AND ARCHIVE INPUTS ARE BOTH SUPPORTED:
    LATEST input supports single-strategy development, smoke testing, and immediate QA against the
    current Module 1 latest-run table.

    ARCHIVE input supports controlled strategy comparison across completed Module 1 scenario slices
    while preserving upstream Module 1 lineage.

    For formal scenario / strategy campaigns, ARCHIVE input is preferred because it preserves the
    exact upstream scenario slice used for matched comparison.

WHY MODULE 1 SCENARIO LINEAGE MUST BE PRESERVED:
    Module 1 scenario fields describe the upstream synthetic population and risk environment.

    Module 2 strategy fields describe the downstream simulated strategy applied to that population.

    These concepts must not be overloaded.

    The same Module 2 strategy may be applied to many Module 1 scenarios.
    The same Module 1 scenario may be evaluated under many Module 2 strategies.

WHY CAMPAIGN IDS ARE NOT ADDED TO EVERY STAGED ROW:
    Campaign IDs such as module1_run_id, module2_run_id, showcase_id, comparison_group_id, and
    validation_evidence_group_id are evidence-linkage metadata.

    They help connect SQL outputs to the run roadmap, Validation Summary, README, and LinkedIn
    campaign story.

    They do not replace:
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_set_name,
        strategy_name,
        strategy_version,
        application_id.

    Section 3 confirms the registry match.
    Section 16 persists campaign IDs into evidence tables.

    Section 4 preserves technical lineage and applicant-level source fields only.

WHY PRODUCT_TYPE MAY NEED A POLICY KEY:
    Module 1 may output product_type in a normalized code format or a display-style format.

    Module 2 product-policy parameters use normalized product keys:
        MORTGAGE
        HELOC
        AUTO_LOAN
        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

    Section 4 preserves the original product_type and derives product_type_policy_key for later
    strategy joins.

    Module 1 is not modified.

WHY PRODUCT-POLICY VALIDATION HAPPENS BEFORE POLICY RULES:
    Downstream strategy rules are product-aware.

    A missing product-policy configuration would make decision logic ambiguous, so Section 4 fails
    before strategy segmentation, rule flags, or decisions are created.

WHY REQUESTED-STRUCTURE ALIASES ARE CREATED:
    Module 1 monthly_payment_proxy and payment_to_income_ratio describe the original requested
    structure.

    Module 2 later calculates approved_monthly_payment_proxy and approved_payment_to_income_ratio
    after exposure treatment.

    Creating requested_* aliases now prevents ambiguity.

WHY EXPECTED_LOSS_AMOUNT IS ALIASED:
    Module 1 expected_loss_amount is requested-exposure Expected Loss.

    Module 2 carries it as:
        requested_expected_loss_amount

    Module 2 later calculates:
        approved_expected_loss_amount

    This distinction matters because a counteroffer may reduce approved exposure and therefore reduce
    approved Expected Loss without changing the original requested-exposure Expected Loss.

WHY ESTIMATED_PD REMAINS THE COLUMN NAME:
    estimated_pd is the finalized Module 1 SQL output column.

    In all interpretation, comments, QA, and documentation, estimated_pd means the synthetic
    estimated-PD proxy.

    Module 2 V1.0 does not recalculate estimated_pd.

WHY NO DECISION OUTCOMES ARE CREATED IN SECTION 4:
    Section 4 is a source-staging and lineage-normalization layer only.

    It does not create:
        decision_outcome
        decision_path
        approval_flag
        decline_flag
        manual_review_flag
        counteroffer_flag
        simulated_offer_exposure_flag
        reason codes
        approved_amount
        approved monthly payment
        approved PTI
        approved Expected Loss

WHY PRODUCT-POLICY JOIN IN SECTION 4 IS VALIDATION-ONLY:
    Section 4 confirms product-policy configuration availability.

    It does not apply:
        product caps,
        counteroffer limits,
        PTI rules,
        requested Expected Loss rules,
        approved Expected Loss rules,
        or final strategy treatment.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    Dynamic SQL:
        Used because the selected source table and scenario column names can vary between latest-run
        and archive outputs.

    FORMAT:
        Used to safely build SQL text with identifier and literal placeholders.

    %I in FORMAT:
        Safely quotes SQL identifiers, such as schema names, table names, and column names.

    %L in FORMAT:
        Safely quotes SQL literal values, such as the source table name stored in the staged output.

    CROSS JOIN active_strategy_params:
        Attaches the single active strategy identity to every selected Module 1 source row.

    CASE normalization:
        Converts display-style product labels into governed Module 2 product-policy keys.

    LEFT JOIN product_policy_match:
        Validates product-policy availability without applying product-policy rules yet.

    CREATE TEMP TABLE ... ON COMMIT PRESERVE ROWS:
        Creates a session-scoped staging table that remains available to downstream sections in the
        same execution session.

GOVERNANCE ROLE:
    Section 4 protects source lineage, source grain, product mapping, and requested-exposure
    interpretation before downstream strategy logic begins.

TESTING RELEVANCE:
    Section 4 diagnostics confirm:
        selected source row count,
        application_id uniqueness,
        Section 3 source-scope agreement,
        Module 1 scenario lineage,
        Module 2 strategy identity,
        campaign registry match visibility,
        product normalization,
        product-policy configuration availability,
        requested-field aliasing,
        and estimated_pd availability.

DOWNSTREAM DEPENDENCY:
    Section 5 consumes tmp_m2_stage_1_source_applications.

    All downstream Module 2 logic should read from the staged source table, not directly from Module 1
    latest-run or archive tables.

COMMON MISUSE TO AVOID:
    Do not use Section 4 output as final strategy output.
    Do not interpret Section 4 as assigning decisions.
    Do not add approved exposure fields in Section 4.
    Do not add reason codes in Section 4.
    Do not replace Module 1 lineage with campaign IDs.
    Do not compare Module 2 strategies unless Module 1 scenario and population are controlled.

***************************************************************************************************/



/***************************************************************************************************
SECTION 4.1 — CLEAN RESET OF SECTION 4 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 4 staging object before rebuilding the Module 1 → Module 2 handoff layer.

SQL PURPOSE:
    Remove only the temporary source-stage table from the current session.

WHY THIS MATTERS:
    A partial rerun should not allow stale source-stage rows to remain available to Section 5.

    Section 5 assumes tmp_m2_stage_1_source_applications reflects the current active strategy
    parameter card and the current selected Module 1 source.

SQL MECHANICS:
    DROP TABLE IF EXISTS prevents the statement from failing when the temp table does not yet exist.

BOUNDARY:
    This drop affects only the temporary source-stage object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_1_source_applications;



/***************************************************************************************************
SECTION 4.2 — CREATE MODULE 1 SOURCE-STAGING TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_1_source_applications

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

SOURCE OPTIONS:
    LATEST:
        credit_decisioning_sim.synthetic_applications

    ARCHIVE:
        credit_decisioning_sim.synthetic_applications_scenario_archive
        filtered to:
            source_module1_scenario_set_name
            source_module1_scenario_name
            source_population_id

IMPORTANT:
    Downstream Module 2 stages should read from:

        tmp_m2_stage_1_source_applications

    They should not read directly from Module 1 tables.

WHY THIS VERSION CONSUMES SECTION 3 SOURCE SCOPE:
    Section 3 already validated source table existence, source scenario-lineage column names,
    selected row count, selected distinct application count, and required source fields.

    Section 4 uses that validated source-scope contract rather than independently inventing a new
    source selection.

DYNAMIC SQL BOUNDARY:
    Dynamic SQL is used only because the selected source table and selected source lineage column
    names can vary.

    The output schema remains fixed and governed.

****************************************************************************************************/

DO $$
DECLARE
    p RECORD;
    ss RECORD;

    v_required_temp_missing_count BIGINT;
    v_required_temp_missing_names TEXT;

    v_active_strategy_count BIGINT;
    v_product_policy_count BIGINT;
    v_source_scope_count BIGINT;

    v_source_table_schema TEXT;
    v_source_table_name TEXT;
    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;

    v_module1_model_version_expr TEXT;
    v_anchor_date_expr TEXT;
    v_application_seq_expr TEXT;
    v_application_date_expr TEXT;
    v_loan_term_months_expr TEXT;
    v_base_apr_expr TEXT;
    v_prequalified_flag_expr TEXT;
    v_returning_customer_flag_expr TEXT;

    v_create_sql TEXT;
BEGIN
    /***********************************************************************************************
    4.2A Required temporary object existence.

    SQL teaching point:
        TO_REGCLASS('pg_temp.<table_name>') checks for temporary table availability in the current
        session.

    Business purpose:
        Section 4 should not silently run from stale or missing setup objects.
    ***********************************************************************************************/
    WITH required_temp_objects AS (
        SELECT *
        FROM (
            VALUES
                ('tmp_module2_strategy_params'),
                ('tmp_module2_product_policy_params'),
                ('tmp_m2_source_selection_scope'),
                ('tmp_m2_campaign_registry_current_run_match')
        ) AS v(table_name)
    ),

    missing_temp_objects AS (
        SELECT table_name
        FROM required_temp_objects
        WHERE TO_REGCLASS('pg_temp.' || table_name) IS NULL
    )

    SELECT
        COUNT(*),
        STRING_AGG(table_name, ', ' ORDER BY table_name)
    INTO
        v_required_temp_missing_count,
        v_required_temp_missing_names
    FROM missing_temp_objects;

    IF v_required_temp_missing_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: required temporary object(s) missing: %. Run Sections 2 and 3 before Section 4.',
            v_required_temp_missing_names;
    END IF;


    /***********************************************************************************************
    4.2B Active strategy and product-policy preflight.

    Business purpose:
        Section 4 stages source rows for one active Module 2 strategy only.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;

    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;

    SELECT COUNT(*)
    INTO v_product_policy_count
    FROM tmp_module2_product_policy_params;

    IF v_product_policy_count <> 5 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: expected 5 active product-policy rows, found %.',
            v_product_policy_count;
    END IF;


    /***********************************************************************************************
    4.2C Source-scope preflight.

    Business purpose:
        Section 3 determines and validates the effective source scope.
        Section 4 consumes that contract.

    Expected:
        exactly one row in tmp_m2_source_selection_scope.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_source_scope_count
    FROM tmp_m2_source_selection_scope;

    IF v_source_scope_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: expected exactly one source-scope row from Section 3, found %.',
            v_source_scope_count;
    END IF;

    SELECT *
    INTO ss
    FROM tmp_m2_source_selection_scope
    LIMIT 1;

    v_source_table_schema := ss.source_table_schema;
    v_source_table_name := ss.source_table_name;
    v_scenario_set_col := ss.source_scenario_set_column_name;
    v_scenario_name_col := ss.source_scenario_name_column_name;


    /***********************************************************************************************
    4.2D Detect Module 1 source-column aliases.

    Section 3 validated these conceptually.

    Section 4 must still build expressions for the actual selected source table.
    ***********************************************************************************************/
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'module1_model_version'
    ) THEN
        v_module1_model_version_expr := 'src.module1_model_version::TEXT';

    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'model_version'
    ) THEN
        v_module1_model_version_expr := 'src.model_version::TEXT';

    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain module1_model_version or model_version.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'anchor_date'
    ) THEN
        v_anchor_date_expr := 'src.anchor_date::DATE';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain anchor_date.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'application_seq'
    ) THEN
        v_application_seq_expr := 'src.application_seq::INTEGER';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain application_seq.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'application_date'
    ) THEN
        v_application_date_expr := 'src.application_date::DATE';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain application_date.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'loan_term_months'
    ) THEN
        v_loan_term_months_expr := 'src.loan_term_months::INTEGER';
    ELSE
        v_loan_term_months_expr := 'NULL::INTEGER';
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'base_apr_for_payment_calc'
    ) THEN
        v_base_apr_expr := 'src.base_apr_for_payment_calc::NUMERIC';

    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'base_apr_for_payment_calculation'
    ) THEN
        v_base_apr_expr := 'src.base_apr_for_payment_calculation::NUMERIC';

    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain base_apr_for_payment_calc or base_apr_for_payment_calculation.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'prequalified_flag'
    ) THEN
        v_prequalified_flag_expr :=
            'CASE
                 WHEN LOWER(src.prequalified_flag::TEXT) IN (''true'', ''t'', ''1'', ''yes'', ''y'') THEN TRUE
                 WHEN LOWER(src.prequalified_flag::TEXT) IN (''false'', ''f'', ''0'', ''no'', ''n'') THEN FALSE
                 ELSE NULL::BOOLEAN
             END';
    ELSE
        v_prequalified_flag_expr := 'NULL::BOOLEAN';
    END IF;


    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'returning_customer_flag'
    ) THEN
        v_returning_customer_flag_expr :=
            'CASE
                 WHEN LOWER(src.returning_customer_flag::TEXT) IN (''true'', ''t'', ''1'', ''yes'', ''y'') THEN TRUE
                 WHEN LOWER(src.returning_customer_flag::TEXT) IN (''false'', ''f'', ''0'', ''no'', ''n'') THEN FALSE
                 ELSE NULL::BOOLEAN
             END';
    ELSE
        v_returning_customer_flag_expr := 'NULL::BOOLEAN';
    END IF;


    /***********************************************************************************************
    4.2E Build the governed source-stage table.

    SQL teaching point:
        The dynamic part chooses source table / source column aliases.
        The output field list remains explicit and fixed.

    Boundary:
        No decisions, reason codes, approved exposure, approved PTI, or approved Expected Loss fields
        are created here.
    ***********************************************************************************************/
    v_create_sql := FORMAT($sql$
        CREATE TEMP TABLE tmp_m2_stage_1_source_applications
        ON COMMIT PRESERVE ROWS
        AS
        WITH active_strategy_params AS (
            SELECT
                module2_model_version,
                strategy_set_name,
                strategy_name,
                strategy_version,
                strategy_run_id,
                strategy_run_ts,

                module1_input_source,
                source_module1_scenario_set_name,
                source_module1_scenario_name,
                source_population_id
            FROM tmp_module2_strategy_params
            WHERE active_strategy_flag IS TRUE
            LIMIT 1
        ),

        source_rows AS (
            SELECT
                /*******************************************************************************
                Module 2 strategy identity.

                These fields describe the downstream strategy being applied.
                They are not Module 1 scenario fields.
                *******************************************************************************/
                p.module2_model_version,
                p.strategy_set_name,
                p.strategy_name,
                p.strategy_version,
                p.strategy_run_id,
                p.strategy_run_ts,

                /*******************************************************************************
                Module 1 source metadata and normalized lineage.

                module1_source_table_name is audit metadata showing where rows came from.
                module1_scenario_set_name / module1_scenario_name / population_id define the
                upstream synthetic population and scenario environment.
                *******************************************************************************/
                p.module1_input_source,
                %L::TEXT AS module1_source_table_name,

                %s AS module1_model_version,
                %s AS module1_scenario_set_name,
                %s AS module1_scenario_name,
                src.population_id::TEXT AS population_id,
                %s AS anchor_date,

                /*******************************************************************************
                Application identifiers.

                Section 4 preserves the Module 1 application grain.
                Section 4 does not create new application IDs.
                *******************************************************************************/
                %s AS application_seq,
                src.application_id::TEXT AS application_id,
                src.applicant_id::TEXT AS applicant_id,
                %s AS application_date,

                /*******************************************************************************
                Product fields.

                product_type preserves the original Module 1 value.

                product_type_policy_key normalizes display-style product labels into the governed
                Module 2 product-policy key used by later sections.
                *******************************************************************************/
                src.product_type::TEXT AS product_type,

                CASE
                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('MORTGAGE', 'MORTGAGE_LOAN', 'HOME_LOAN')
                        THEN 'MORTGAGE'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('HELOC', 'HOME_EQUITY_LINE_OF_CREDIT', 'HOME_EQUITY_LINE')
                        THEN 'HELOC'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('AUTO_LOAN', 'AUTO', 'AUTO_FINANCE', 'VEHICLE_LOAN')
                        THEN 'AUTO_LOAN'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('UNSECURED_PERSONAL_LOAN', 'PERSONAL_LOAN', 'UNSECURED_LOAN', 'UPL')
                        THEN 'UNSECURED_PERSONAL_LOAN'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('REVOLVING_LINE', 'REVOLVING', 'CREDIT_CARD', 'REVOLVING_CREDIT_LINE')
                        THEN 'REVOLVING_LINE'

                    ELSE UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                END AS product_type_policy_key,

                /*******************************************************************************
                Borrower quality and behavior fields.

                These are Module 1 applicant-profile fields.
                Section 4 preserves them for later segmentation and rule-trigger logic.
                *******************************************************************************/
                src.score_band::TEXT AS score_band,
                src.credit_score::INTEGER AS credit_score,

                src.annual_income::NUMERIC AS annual_income,
                src.debt_to_income_ratio::NUMERIC AS debt_to_income_ratio,
                src.utilization_rate::NUMERIC AS utilization_rate,
                src.tradeline_count::INTEGER AS tradeline_count,
                src.months_since_oldest_trade::INTEGER AS months_since_oldest_trade,
                src.recent_inquiry_count::INTEGER AS recent_inquiry_count,
                src.delinquency_count_12m::INTEGER AS delinquency_count_12m,

                CASE
                    WHEN LOWER(src.major_derogatory_flag::TEXT) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
                    WHEN LOWER(src.major_derogatory_flag::TEXT) IN ('false', 'f', '0', 'no', 'n') THEN FALSE
                    ELSE NULL::BOOLEAN
                END AS major_derogatory_flag,

                CASE
                    WHEN LOWER(src.bankruptcy_flag::TEXT) IN ('true', 't', '1', 'yes', 'y') THEN TRUE
                    WHEN LOWER(src.bankruptcy_flag::TEXT) IN ('false', 'f', '0', 'no', 'n') THEN FALSE
                    ELSE NULL::BOOLEAN
                END AS bankruptcy_flag,

                %s AS prequalified_flag,
                %s AS returning_customer_flag,

                /*******************************************************************************
                Requested structure fields.

                These are the original requested product structure from Module 1.
                Approved exposure does not exist yet.
                *******************************************************************************/
                src.requested_amount::NUMERIC AS requested_amount,
                %s AS loan_term_months,
                %s AS base_apr_for_payment_calc,

                src.monthly_payment_proxy::NUMERIC AS monthly_payment_proxy,
                src.payment_to_income_ratio::NUMERIC AS payment_to_income_ratio,
                src.amount_to_income_ratio::NUMERIC AS amount_to_income_ratio,

                /*******************************************************************************
                Module 2 requested-structure aliases.

                These aliases make the requested-vs-approved distinction explicit for later sections.
                *******************************************************************************/
                src.monthly_payment_proxy::NUMERIC AS requested_monthly_payment_proxy,
                src.payment_to_income_ratio::NUMERIC AS requested_payment_to_income_ratio,

                /*******************************************************************************
                Synthetic risk and requested-exposure Expected Loss fields.

                estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic
                estimated-PD proxy.
                *******************************************************************************/
                src.estimated_pd::NUMERIC AS estimated_pd,
                src.estimated_lgd::NUMERIC AS estimated_lgd,
                src.expected_loss_amount::NUMERIC AS expected_loss_amount,
                src.expected_loss_amount::NUMERIC AS requested_expected_loss_amount

            FROM %I.%I src

            /***********************************************************************************
            CROSS JOIN active strategy identity.

            The active strategy parameter card contains exactly one row due to Section 3.
            CROSS JOIN attaches that strategy identity to every selected Module 1 source row.
            ***********************************************************************************/
            CROSS JOIN active_strategy_params p

            /***********************************************************************************
            Source filter logic.

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

        product_policy_match AS (
            /***********************************************************************************
            CTE: product_policy_match

            Purpose:
                Count product-policy rows by product type.

            Why:
                Section 4 validates product-policy availability but does not apply product-policy
                rules yet.
            ***********************************************************************************/
            SELECT
                product_type,
                COUNT(*) AS product_policy_match_count
            FROM tmp_module2_product_policy_params
            GROUP BY product_type
        )

        SELECT
            sr.*,

            /***********************************************************************************
            Product-policy match diagnostics.

            product_policy_match_count:
                How many product-policy rows matched this normalized product key.

            product_policy_config_found_flag:
                TRUE only when exactly one matching policy row exists.

            These fields support Section 4.3 validation and Section 4.4 review.
            ***********************************************************************************/
            COALESCE(pp.product_policy_match_count, 0) AS product_policy_match_count,

            (
                COALESCE(pp.product_policy_match_count, 0) = 1
            ) AS product_policy_config_found_flag

        FROM source_rows sr

        LEFT JOIN product_policy_match pp
            ON pp.product_type = sr.product_type_policy_key;
    $sql$,
        v_source_table_schema || '.' || v_source_table_name,

        v_module1_model_version_expr,
        FORMAT('src.%I::TEXT', v_scenario_set_col),
        FORMAT('src.%I::TEXT', v_scenario_name_col),
        v_anchor_date_expr,

        v_application_seq_expr,
        v_application_date_expr,

        v_prequalified_flag_expr,
        v_returning_customer_flag_expr,

        v_loan_term_months_expr,
        v_base_apr_expr,

        v_source_table_schema,
        v_source_table_name,

        FORMAT('src.%I::TEXT', v_scenario_set_col),
        FORMAT('src.%I::TEXT', v_scenario_name_col)
    );

    /***********************************************************************************************
    4.2F Execute the dynamic CREATE TEMP TABLE statement.

    Boundary:
        This creates only the Section 4 source-stage table.

        It does not create decisions, reason codes, approved exposure, latest-run output, archive
        rows, or evidence rows.
    ***********************************************************************************************/
    EXECUTE v_create_sql;
END $$;



/***************************************************************************************************
SECTION 4.3 — LOCAL FAIL-FAST CHECKS FOR SOURCE STAGING
****************************************************************************************************

BUSINESS PURPOSE:
    Protect the decision engine from consuming ambiguous or malformed source input.

    Section 4.3 answers:

        "Did Section 4 create a clean, one-row-per-application source stage with correct lineage,
         required fields, supported product mappings, and no premature decision fields?"

SQL PURPOSE:
    1. Confirm the staged source table exists and contains rows.
    2. Confirm application_id uniqueness.
    3. Confirm exactly one Module 1 scenario / population slice.
    4. Confirm staged source agrees with Section 3 source-selection scope.
    5. Confirm Module 2 strategy identity metadata is populated.
    6. Confirm required source fields are populated.
    7. Confirm product_type_policy_key is supported.
    8. Confirm each product_type_policy_key maps to exactly one active product-policy row.
    9. Confirm Section 4 did not create final decision, reason-code, or approved-exposure fields.

INTERPRETATION:
    These checks validate source staging only.

    They do not validate:
        strategy segmentation,
        rule triggers,
        preliminary routing,
        approved exposure,
        counteroffer feasibility,
        final decision outcomes,
        simulated reason codes,
        latest-run output,
        archive persistence,
        matched comparison,
        Section 14 QA,
        Section 15 frontier,
        or Section 16 evidence capture.

****************************************************************************************************/

DO $$
DECLARE
    v_stage_table_exists BOOLEAN;

    v_stage_row_count BIGINT;
    v_distinct_application_count BIGINT;
    v_duplicate_application_group_count BIGINT;

    v_scenario_population_count BIGINT;
    v_source_scope_count BIGINT;
    v_source_scope_mismatch_count BIGINT;

    v_strategy_metadata_null_count BIGINT;
    v_null_required_field_count BIGINT;
    v_unmapped_product_type_count BIGINT;
    v_missing_product_policy_count BIGINT;
    v_multiple_product_policy_count BIGINT;
    v_forbidden_column_count BIGINT;
BEGIN
    /***********************************************************************************************
    Gatekeeper: staged source table must exist.
    ***********************************************************************************************/
    SELECT TO_REGCLASS('pg_temp.tmp_m2_stage_1_source_applications') IS NOT NULL
    INTO v_stage_table_exists;

    IF v_stage_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_stage_1_source_applications does not exist.';
    END IF;


    /***********************************************************************************************
    Gatekeeper: staged source table must contain rows.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_stage_row_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_stage_row_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /***********************************************************************************************
    Gatekeeper: application_id must remain unique.

    Module 2 V1.0 expects one staged row per synthetic application for the selected Module 1 source
    slice.
    ***********************************************************************************************/
    SELECT COUNT(DISTINCT application_id)
    INTO v_distinct_application_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_distinct_application_count <> v_stage_row_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_group_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_1_source_applications
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source contains duplicate application_id values. Rows=%, distinct application_id=%, duplicate groups=%.',
            v_stage_row_count,
            v_distinct_application_count,
            v_duplicate_application_group_count;
    END IF;


    /***********************************************************************************************
    Gatekeeper: exactly one Module 1 scenario / population slice.

    Multi-scenario processing is intentionally not built in Module 2 V1.0.
    ***********************************************************************************************/
    SELECT COUNT(DISTINCT (
        module1_scenario_set_name,
        module1_scenario_name,
        population_id
    ))
    INTO v_scenario_population_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_scenario_population_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source contains % Module 1 scenario / population combinations. Expected exactly one.',
            v_scenario_population_count;
    END IF;


    /***********************************************************************************************
    Gatekeeper: staged source must align with Section 3 source-scope contract.

    Business purpose:
        Ensure Section 4 staged exactly the source Section 3 validated.

    SQL mechanics:
        Compare source mode, source table, scenario lineage, population, row count, and distinct
        application count.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_source_scope_count
    FROM tmp_m2_source_selection_scope;

    IF v_source_scope_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: expected exactly one tmp_m2_source_selection_scope row, found %.',
            v_source_scope_count;
    END IF;

    SELECT COUNT(*)
    INTO v_source_scope_mismatch_count
    FROM tmp_m2_source_selection_scope ss
    CROSS JOIN (
        SELECT
            module1_input_source,
            module1_source_table_name,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id,
            COUNT(*) AS staged_row_count,
            COUNT(DISTINCT application_id) AS staged_distinct_application_id_count
        FROM tmp_m2_stage_1_source_applications
        GROUP BY
            module1_input_source,
            module1_source_table_name,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        LIMIT 1
    ) st
    WHERE ss.module1_input_source IS DISTINCT FROM st.module1_input_source
       OR (ss.source_table_schema || '.' || ss.source_table_name) IS DISTINCT FROM st.module1_source_table_name
       OR ss.effective_module1_scenario_set_name IS DISTINCT FROM st.module1_scenario_set_name
       OR ss.effective_module1_scenario_name IS DISTINCT FROM st.module1_scenario_name
       OR ss.effective_population_id IS DISTINCT FROM st.population_id
       OR ss.selected_row_count IS DISTINCT FROM st.staged_row_count
       OR ss.selected_distinct_application_id_count IS DISTINCT FROM st.staged_distinct_application_id_count;

    IF v_source_scope_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source does not align to tmp_m2_source_selection_scope from Section 3.';
    END IF;


    /***********************************************************************************************
    Gatekeeper: Module 2 strategy metadata must be present.

    Business purpose:
        Every downstream stage must remain traceable to the active Module 2 strategy.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_strategy_metadata_null_count
    FROM tmp_m2_stage_1_source_applications
    WHERE module2_model_version IS NULL
       OR NULLIF(BTRIM(module2_model_version), '') IS NULL
       OR strategy_set_name IS NULL
       OR NULLIF(BTRIM(strategy_set_name), '') IS NULL
       OR strategy_name IS NULL
       OR NULLIF(BTRIM(strategy_name), '') IS NULL
       OR strategy_version IS NULL
       OR NULLIF(BTRIM(strategy_version), '') IS NULL
       OR strategy_run_id IS NULL
       OR NULLIF(BTRIM(strategy_run_id), '') IS NULL
       OR strategy_run_ts IS NULL;

    IF v_strategy_metadata_null_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) have missing Module 2 strategy metadata.',
            v_strategy_metadata_null_count;
    END IF;


    /***********************************************************************************************
    Gatekeeper: required source fields must be populated.

    Optional relationship fields intentionally excluded:
        prequalified_flag
        returning_customer_flag

    Product-specific term convention:
        loan_term_months is required for fixed-term / term-reference products, but it is not required
        for REVOLVING_LINE.

        A NULL loan_term_months value for REVOLVING_LINE is expected source behavior, not a malformed
        source row.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_null_required_field_count
    FROM tmp_m2_stage_1_source_applications
    WHERE module1_model_version IS NULL
       OR NULLIF(BTRIM(module1_model_version), '') IS NULL
       OR module1_scenario_set_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
       OR module1_scenario_name IS NULL
       OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
       OR population_id IS NULL
       OR NULLIF(BTRIM(population_id), '') IS NULL
       OR anchor_date IS NULL
       OR module1_input_source IS NULL
       OR NULLIF(BTRIM(module1_input_source), '') IS NULL
       OR module1_source_table_name IS NULL
       OR NULLIF(BTRIM(module1_source_table_name), '') IS NULL

       OR application_seq IS NULL
       OR application_id IS NULL
       OR NULLIF(BTRIM(application_id), '') IS NULL
       OR applicant_id IS NULL
       OR NULLIF(BTRIM(applicant_id), '') IS NULL
       OR application_date IS NULL

       OR product_type IS NULL
       OR NULLIF(BTRIM(product_type), '') IS NULL
       OR product_type_policy_key IS NULL
       OR NULLIF(BTRIM(product_type_policy_key), '') IS NULL
       OR score_band IS NULL
       OR NULLIF(BTRIM(score_band), '') IS NULL
       OR credit_score IS NULL

       OR annual_income IS NULL
       OR debt_to_income_ratio IS NULL
       OR utilization_rate IS NULL
       OR tradeline_count IS NULL
       OR months_since_oldest_trade IS NULL
       OR recent_inquiry_count IS NULL
       OR delinquency_count_12m IS NULL
       OR major_derogatory_flag IS NULL
       OR bankruptcy_flag IS NULL

       OR requested_amount IS NULL

       OR (
            COALESCE(product_type_policy_key, '__UNMAPPED__') <> 'REVOLVING_LINE'
            AND loan_term_months IS NULL
       )

       OR base_apr_for_payment_calc IS NULL
       OR monthly_payment_proxy IS NULL
       OR payment_to_income_ratio IS NULL
       OR amount_to_income_ratio IS NULL
       OR requested_monthly_payment_proxy IS NULL
       OR requested_payment_to_income_ratio IS NULL
       OR requested_expected_loss_amount IS NULL

       OR estimated_pd IS NULL
       OR estimated_lgd IS NULL
       OR expected_loss_amount IS NULL;

    IF v_null_required_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) have null required source or lineage fields.',
            v_null_required_field_count;
    END IF;


    /***********************************************************************************************
    Gatekeeper: every product_type must normalize into a supported product_type_policy_key.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_unmapped_product_type_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_type_policy_key IS NULL
       OR product_type_policy_key NOT IN (
            'MORTGAGE',
            'HELOC',
            'AUTO_LOAN',
            'UNSECURED_PERSONAL_LOAN',
            'REVOLVING_LINE'
       );

    IF v_unmapped_product_type_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) have product_type values that cannot be normalized to supported Module 2 product-policy keys.',
            v_unmapped_product_type_count;
    END IF;


    /***********************************************************************************************
    Gatekeeper: every staged product key must map to exactly one product-policy row.

    Boundary:
        Section 4 does not apply product-policy rules.
        It only validates that product-policy configuration is available.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_missing_product_policy_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_policy_match_count = 0
       OR product_policy_config_found_flag IS DISTINCT FROM TRUE;

    IF v_missing_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) do not map to a product-policy configuration.',
            v_missing_product_policy_count;
    END IF;

    SELECT COUNT(*)
    INTO v_multiple_product_policy_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_policy_match_count > 1;

    IF v_multiple_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) map to more than one product-policy configuration.',
            v_multiple_product_policy_count;
    END IF;


    /***********************************************************************************************
    Gatekeeper: Section 4 must not create decision, reason-code, or approved-exposure fields.

    Business purpose:
        Protect the staged architecture.

    SQL mechanics:
        pg_attribute inspects the physical columns on the temp table.
    ***********************************************************************************************/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_1_source_applications'::REGCLASS
      AND attnum > 0
      AND NOT attisdropped
      AND attname IN (
            'decision_outcome',
            'decision_path',
            'approval_flag',
            'decline_flag',
            'manual_review_flag',
            'counteroffer_flag',
            'simulated_offer_exposure_flag',

            'primary_reason_code',
            'secondary_reason_code',
            'tertiary_reason_code',
            'triggered_reason_code_list',
            'reason_priority_rank',
            'primary_reason_family',

            'approved_amount',
            'counteroffer_amount',
            'approved_monthly_payment_proxy',
            'approved_payment_to_income_ratio',
            'approved_expected_loss_amount'
      );

    IF v_forbidden_column_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: forbidden decision, reason-code, or approved-exposure field(s) were created in source staging.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 4.4 — LOCAL SOURCE-STAGING SANITY CHECKS
****************************************************************************************************

BUSINESS PURPOSE:
    Provide lightweight staging diagnostics for source selection and lineage normalization.

    Section 4.4 answers:

        "What did Section 4 stage, and does the staged source look ready for Section 5?"

SQL PURPOSE:
    Display review outputs for:
        row count,
        source-scope alignment,
        Module 1 lineage,
        Module 2 strategy identity,
        campaign registry linkage,
        source input type,
        product normalization,
        product-policy configuration match,
        required-field completeness,
        requested Expected Loss aliasing,
        requested monthly payment aliasing,
        requested PTI aliasing,
        and estimated_pd availability.

INTERPRETATION:
    These are Section 4 sanity checks only.

    They are not:
        full Module 2 QA,
        final decision validation,
        reason-code validation,
        approved-exposure validation,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        or Validation Summary evidence by themselves.

HOW TO USE:
    Review Section 4.4 before running Section 5 when changing:
        Module 1 source selection,
        Module 1 scenario source,
        product type labels,
        product-policy rows,
        or source-table schema.

SQL TEACHING POINT:
    Most queries here are aggregation checks.

    They help confirm grain and lineage before more complex downstream transformations occur.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
4.4.0 Section 3 source-selection scope carried into Section 4.

Purpose:
    Display the effective source scope validated by Section 3.

Expected:
    exactly one row.

Interpretation:
    This is the source-scope contract that Section 4 staging should match.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_input_source,
    source_table_schema,
    source_table_name,
    source_scenario_set_column_name,
    source_scenario_name_column_name,

    effective_module1_scenario_set_name,
    effective_module1_scenario_name,
    effective_population_id,

    selected_row_count,
    selected_distinct_application_id_count,
    duplicate_application_group_count,
    null_required_field_row_count
FROM tmp_m2_source_selection_scope;



/*-----------------------------------------------------------------------------------------------
4.4.1 Row count and distinct application_id count.

Purpose:
    Confirm staged source grain.

Expected:
    staged_row_count = distinct_application_id_count.

Interpretation:
    If these differ, the staged source is not unique at application_id and downstream decision
    outcomes would be duplicated.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS staged_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_1_source_applications;



/*-----------------------------------------------------------------------------------------------
4.4.2 Module 1 scenario / population lineage.

Purpose:
    Confirm the upstream Module 1 scenario and population staged for the current Module 2 run.

Expected:
    exactly one row in this output for Module 2 V1.0 single-slice processing.

Credit risk interpretation:
    These fields define the upstream scenario environment.

    They should not be confused with Module 2 strategy fields.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_1_source_applications
GROUP BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
ORDER BY
    module1_scenario_set_name,
    module1_scenario_name,
    population_id;



/*-----------------------------------------------------------------------------------------------
4.4.3 Module 2 strategy identity carried into source stage.

Purpose:
    Confirm the downstream Module 2 strategy identity attached to the staged source rows.

Expected:
    exactly one row.

Interpretation:
    These fields describe the strategy being applied.

    They do not describe the upstream Module 1 scenario.
-----------------------------------------------------------------------------------------------*/

SELECT
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,
    COUNT(*) AS row_count
FROM tmp_m2_stage_1_source_applications
GROUP BY
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts
ORDER BY
    strategy_set_name,
    strategy_name,
    strategy_version;



/*-----------------------------------------------------------------------------------------------
4.4.3A Campaign registry linkage available for evidence capture.

Purpose:
    Confirm that the technical Module 1 scenario × Module 2 strategy identity staged in Section 4
    aligns with the registry match created in Section 3.

Interpretation:
    Section 4 does not carry campaign IDs into every staged row.

    Section 16 consumes the registry match to persist campaign IDs into evidence tables.
-----------------------------------------------------------------------------------------------*/

SELECT
    run_registry_match_status,
    module1_run_id,
    module2_run_id,
    run_sequence_number,
    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,
    readme_storyline_label,
    linkedin_post_sequence,
    validation_summary_section_hint
FROM tmp_m2_campaign_registry_current_run_match;



/*-----------------------------------------------------------------------------------------------
4.4.4 Source input type and source table.

Purpose:
    Confirm whether Section 4 consumed Module 1 LATEST output or an ARCHIVE slice.

Expected:
    exactly one row.

Interpretation:
    Formal campaign runs should usually use ARCHIVE input so Module 2 strategies can be applied to
    controlled completed Module 1 scenario slices.
-----------------------------------------------------------------------------------------------*/

SELECT
    module1_input_source,
    module1_source_table_name,
    COUNT(*) AS row_count
FROM tmp_m2_stage_1_source_applications
GROUP BY
    module1_input_source,
    module1_source_table_name
ORDER BY
    module1_input_source,
    module1_source_table_name;



/*-----------------------------------------------------------------------------------------------
4.4.5 Product type normalization review.

Purpose:
    Confirm that original Module 1 product values normalize cleanly to Module 2 policy keys.

product_type:
    original Module 1 value.

product_type_policy_key:
    normalized Module 2 policy join key.

Expected:
    each product_type maps to one supported product_type_policy_key.

Credit risk interpretation:
    Product type is a structural risk driver.

    It affects exposure, payment behavior, LGD, affordability, and counteroffer feasibility.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type,
    product_type_policy_key,
    COUNT(*) AS row_count
FROM tmp_m2_stage_1_source_applications
GROUP BY
    product_type,
    product_type_policy_key
ORDER BY
    product_type_policy_key,
    product_type;



/*-----------------------------------------------------------------------------------------------
4.4.6 Unmapped product_type count.

Purpose:
    Confirm no source products failed product-key normalization.

Expected:
    zero.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS unmapped_product_type_rows
FROM tmp_m2_stage_1_source_applications
WHERE product_type_policy_key IS NULL
   OR product_type_policy_key NOT IN (
        'MORTGAGE',
        'HELOC',
        'AUTO_LOAN',
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
   );



/*-----------------------------------------------------------------------------------------------
4.4.7 Product-policy configuration match.

Purpose:
    Confirm every staged product key maps to exactly one product-policy configuration.

Expected:
    product_policy_config_found_flag = TRUE for every staged row.
    product_policy_match_count = 1 for each product_type_policy_key.

Boundary:
    This confirms product-policy availability only.

    It does not apply product-policy rules yet.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    product_policy_match_count,
    product_policy_config_found_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_1_source_applications
GROUP BY
    product_type_policy_key,
    product_policy_match_count,
    product_policy_config_found_flag
ORDER BY
    product_type_policy_key,
    product_policy_match_count,
    product_policy_config_found_flag;



/*-----------------------------------------------------------------------------------------------
4.4.8 Required source-field null diagnostic.

Purpose:
    Provide review visibility into the Section 4.3 required-field fail-fast logic.

Expected:
    null_required_source_or_lineage_rows = 0.

Interpretation:
    This diagnostic mirrors the Section 4.3 fail-fast check for review visibility.

SQL mechanics:
    The revolving-line loan_term_months exception is repeated here to match the gatekeeper.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS null_required_source_or_lineage_rows
FROM tmp_m2_stage_1_source_applications
WHERE module1_model_version IS NULL
   OR NULLIF(BTRIM(module1_model_version), '') IS NULL
   OR module1_scenario_set_name IS NULL
   OR NULLIF(BTRIM(module1_scenario_set_name), '') IS NULL
   OR module1_scenario_name IS NULL
   OR NULLIF(BTRIM(module1_scenario_name), '') IS NULL
   OR population_id IS NULL
   OR NULLIF(BTRIM(population_id), '') IS NULL
   OR anchor_date IS NULL
   OR module1_input_source IS NULL
   OR NULLIF(BTRIM(module1_input_source), '') IS NULL
   OR module1_source_table_name IS NULL
   OR NULLIF(BTRIM(module1_source_table_name), '') IS NULL

   OR application_seq IS NULL
   OR application_id IS NULL
   OR NULLIF(BTRIM(application_id), '') IS NULL
   OR applicant_id IS NULL
   OR NULLIF(BTRIM(applicant_id), '') IS NULL
   OR application_date IS NULL

   OR product_type IS NULL
   OR NULLIF(BTRIM(product_type), '') IS NULL
   OR product_type_policy_key IS NULL
   OR NULLIF(BTRIM(product_type_policy_key), '') IS NULL
   OR score_band IS NULL
   OR NULLIF(BTRIM(score_band), '') IS NULL
   OR credit_score IS NULL

   OR annual_income IS NULL
   OR debt_to_income_ratio IS NULL
   OR utilization_rate IS NULL
   OR tradeline_count IS NULL
   OR months_since_oldest_trade IS NULL
   OR recent_inquiry_count IS NULL
   OR delinquency_count_12m IS NULL
   OR major_derogatory_flag IS NULL
   OR bankruptcy_flag IS NULL

   OR requested_amount IS NULL

   OR (
        COALESCE(product_type_policy_key, '__UNMAPPED__') <> 'REVOLVING_LINE'
        AND loan_term_months IS NULL
   )

   OR base_apr_for_payment_calc IS NULL
   OR monthly_payment_proxy IS NULL
   OR payment_to_income_ratio IS NULL
   OR amount_to_income_ratio IS NULL
   OR requested_monthly_payment_proxy IS NULL
   OR requested_payment_to_income_ratio IS NULL
   OR requested_expected_loss_amount IS NULL

   OR estimated_pd IS NULL
   OR estimated_lgd IS NULL
   OR expected_loss_amount IS NULL;



/*-----------------------------------------------------------------------------------------------
4.4.9 Requested Expected Loss alias confirmation.

Purpose:
    Confirm that Module 1 expected_loss_amount was preserved and aliased into
    requested_expected_loss_amount.

Expected:
    requested_expected_loss_mismatch_rows = 0.

Interpretation:
    requested_expected_loss_amount is the requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is created later after exposure treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS requested_expected_loss_mismatch_rows,
    AVG(expected_loss_amount) AS avg_module1_expected_loss_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    SUM(expected_loss_amount) AS total_module1_expected_loss_amount,
    SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount
FROM tmp_m2_stage_1_source_applications
WHERE expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount;



/*-----------------------------------------------------------------------------------------------
4.4.10 Requested payment and requested PTI alias confirmation.

Purpose:
    Confirm that Module 1 requested-structure affordability fields were preserved and aliased.

Expected:
    requested_monthly_payment_mismatch_rows = 0.
    requested_pti_mismatch_rows = 0.

Interpretation:
    requested_* fields describe the original requested structure.

    approved_* fields are created later only after exposure treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) FILTER (
        WHERE monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
    ) AS requested_monthly_payment_mismatch_rows,

    COUNT(*) FILTER (
        WHERE payment_to_income_ratio IS DISTINCT FROM requested_payment_to_income_ratio
    ) AS requested_pti_mismatch_rows,

    AVG(monthly_payment_proxy) AS avg_module1_monthly_payment_proxy,
    AVG(requested_monthly_payment_proxy) AS avg_requested_monthly_payment_proxy,

    AVG(payment_to_income_ratio) AS avg_module1_payment_to_income_ratio,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_1_source_applications;



/*-----------------------------------------------------------------------------------------------
4.4.11 Synthetic estimated-PD proxy availability and range.

Purpose:
    Confirm estimated_pd is populated and bounded as a synthetic estimated-risk proxy.

Expected:
    null_estimated_pd_rows = 0.
    estimated_pd_out_of_range_rows = 0.

Boundary:
    Section 4 does not recalculate estimated_pd.

    It preserves the Module 1 field for downstream segmentation and rule-trigger logic.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS staged_rows,

    COUNT(*) FILTER (
        WHERE estimated_pd IS NULL
    ) AS null_estimated_pd_rows,

    COUNT(*) FILTER (
        WHERE estimated_pd < 0
           OR estimated_pd > 1
    ) AS estimated_pd_out_of_range_rows,

    MIN(estimated_pd) AS min_synthetic_estimated_pd_proxy,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    MAX(estimated_pd) AS max_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_1_source_applications;



/*-----------------------------------------------------------------------------------------------
4.4.12 Section 4 readiness summary.

Purpose:
    Provide one compact readiness row for the Module 1 → Module 2 handoff.

Expected:
    section_4_source_staging_status = SECTION_4_SOURCE_STAGING_READY_FOR_SEGMENTATION

Interpretation:
    This does not validate final strategy outcomes.

    It confirms only that Section 4 created a clean source-staging layer for Section 5.
-----------------------------------------------------------------------------------------------*/

WITH stage_summary AS (
    SELECT
        COUNT(*) AS staged_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(DISTINCT (
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS distinct_module1_scenario_population_count,

        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version
        )) AS distinct_module2_strategy_count,

        COUNT(*) FILTER (
            WHERE product_policy_config_found_flag IS DISTINCT FROM TRUE
        ) AS product_policy_config_gap_rows,

        COUNT(*) FILTER (
            WHERE expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
        ) AS requested_expected_loss_alias_mismatch_rows,

        COUNT(*) FILTER (
            WHERE monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
               OR payment_to_income_ratio IS DISTINCT FROM requested_payment_to_income_ratio
        ) AS requested_payment_or_pti_alias_mismatch_rows,

        COUNT(*) FILTER (
            WHERE estimated_pd IS NULL
               OR estimated_pd < 0
               OR estimated_pd > 1
        ) AS estimated_pd_problem_rows
    FROM tmp_m2_stage_1_source_applications
)

SELECT
    staged_rows,
    distinct_application_id_count,
    distinct_module1_scenario_population_count,
    distinct_module2_strategy_count,
    product_policy_config_gap_rows,
    requested_expected_loss_alias_mismatch_rows,
    requested_payment_or_pti_alias_mismatch_rows,
    estimated_pd_problem_rows,

    CASE
        WHEN staged_rows > 0
         AND staged_rows = distinct_application_id_count
         AND distinct_module1_scenario_population_count = 1
         AND distinct_module2_strategy_count = 1
         AND product_policy_config_gap_rows = 0
         AND requested_expected_loss_alias_mismatch_rows = 0
         AND requested_payment_or_pti_alias_mismatch_rows = 0
         AND estimated_pd_problem_rows = 0
            THEN 'SECTION_4_SOURCE_STAGING_READY_FOR_SEGMENTATION'
        ELSE 'REVIEW_SECTION_4_SOURCE_STAGING_BEFORE_SEGMENTATION'
    END AS section_4_source_staging_status
FROM stage_summary;



/***************************************************************************************************
END OF SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION

If execution reaches this point:
    1. The validated Section 3 source-scope contract was consumed.
    2. The selected Module 1 source table was read.
    3. Module 1 scenario lineage was normalized into stable Module 2 lineage fields.
    4. Module 2 strategy identity was attached to each staged source row.
    5. Application-level identifiers were preserved.
    6. Borrower, product, affordability, requested-structure, and risk-economics fields were
       preserved.
    7. Requested monthly payment, requested PTI, and requested Expected Loss aliases were created.
    8. product_type_policy_key was normalized for product-policy-aware downstream strategy logic.
    9. Product-policy configuration availability was validated.
    10. The staged source was confirmed unique at application_id.
    11. The staged source was confirmed to contain exactly one Module 1 scenario / population slice.
    12. The staged source was confirmed to align with tmp_m2_source_selection_scope.
    13. Section 4 did not create decision, reason-code, or approved-exposure fields.
    14. Source-staging diagnostics are available for review.

Section 4 established:
    1. The clean Module 1 → Module 2 handoff layer.
    2. The applicant-grain source table used by downstream strategy logic.
    3. Technical separation between Module 1 scenario lineage and Module 2 strategy identity.
    4. Product key normalization for later product-policy joins.
    5. Requested-vs-approved terminology discipline.

No strategy segmentation has been created.
No rule flags have been assigned.
No preliminary routing has been assigned.
No approved exposure has been calculated.
No approved Expected Loss has been calculated.
No final decision_outcome has been assigned.
No simulated reason codes have been assigned.
No latest-run output has been created.
No archive rows have been inserted.
No matched comparison has been performed.
No Section 14 QA validation has been performed.
No Section 15 frontier has been calculated.
No Section 16 evidence has been captured.
No revenue, pricing, profitability, funding-cost, capital, or risk-adjusted margin logic has been implemented.

Next:
    Run Section 5 to create the derived strategy segmentation layer from
    tmp_m2_stage_1_source_applications.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01526 -->


---

<a id="c038-m01528"></a>

### C038-M01528

**Andrew** · 2026-05-12T09:15:50.006000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01528 -->
proceed with pass 4 - operational pipeline commentary and compatibility tightening (section 5 - module 1 source selection and lineage normalization)
<!-- END_MESSAGE C038-M01528 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_73.md) · [Next](Part_75.md)
