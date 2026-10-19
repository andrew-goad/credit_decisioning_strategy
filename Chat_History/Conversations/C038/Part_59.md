# Module 2 Decision Simulator Build

## Part 59

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_58.md) · [Next](Part_60.md)

<a id="c038-m01046"></a>

### C038-M01046

**ChatGPT** · 2026-05-10T11:09:42.703110-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01046 -->
Using your uploaded Section 16.4–16.6 as the base, below is a full copy-paste replacement. I preserved the SQL logic and strengthened the instructional commentary around how the evidence layer works, how to interpret each output, and how the SQL mechanics support the run evidence grain. fileciteturn129file1

```sql
/***************************************************************************************************
SECTION 16.4 — CAPTURE CURRENT RUN PARAMETER SNAPSHOT
****************************************************************************************************

BUSINESS PURPOSE:
    Persist the exact active Module 2 strategy parameter card, product-policy parameter card, and
    run-story metadata for the current evidence row.

    Section 16.4 answers:

        "What parameter configuration and campaign registry metadata produced this completed
         strategy run?"

SQL PURPOSE:
    1. Read the one-row current run key from tmp_m2_current_run_key.
    2. Read the one-row current run story metadata from tmp_m2_current_run_story_params.
    3. Snapshot the active Module 2 strategy parameter row as JSONB.
    4. Snapshot all product-policy parameter rows as ordered JSONB.
    5. Snapshot the active run-story metadata row as JSONB.
    6. Generate an evidence_snapshot_id.
    7. Generate a parameter_snapshot_hash.
    8. Insert the parameter snapshot into:
            credit_decisioning_sim.strategy_run_parameter_snapshot

WHY THIS SECTION EXISTS:
    Module 2 strategy outputs are interpretable only if reviewers can trace the run back to the
    exact configuration that produced it.

    The latest-run output tells reviewers what happened.

    The parameter snapshot tells reviewers why that run was configured that way.

    Without Section 16.4, later documentation could preserve outcome metrics but lose the exact
    thresholds, archive controls, product caps, counteroffer controls, registry IDs, and story labels
    that produced those metrics.

REGISTRY PATCH:
    The parameter snapshot stores registry linkage fields explicitly and also stores the full
    run_story_params_jsonb payload.

    This makes each parameter snapshot traceable to:
        module1_run_id,
        module2_run_id,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id,
        readme_storyline_label,
        linkedin_post_sequence,
        validation_summary_section_hint,
        and run_registry_match_status.

CREDIT RISK INTERPRETATION:
    Strategy parameters explain the risk appetite and treatment posture of the run.

    Examples:
        tighter synthetic-risk thresholds explain lower simulated offer exposure;
        tighter PTI thresholds explain higher counteroffer or manual-review pressure;
        product approved-Expected-Loss caps explain exposure reductions;
        failed_counteroffer_resolution explains whether failed counteroffers stay unresolved or
        become final no-offer outcomes.

    Product-policy parameters explain product-specific strategy behavior.

    Examples:
        product caps can explain product-level counteroffer concentration;
        product minimums can explain failed counteroffer feasibility;
        approved Expected Loss caps can explain product × score risk tightening;
        rounding increments can explain final approved amount patterns.

WHY JSONB IS USED:
    JSONB preserves the full parameter card without forcing every parameter into a separate evidence
    table column.

    This matters because strategy parameter tables may evolve across versions.

    JSONB allows the evidence layer to preserve the complete payload even when downstream
    documentation only uses selected fields.

WHY PRODUCT POLICY SNAPSHOT IS ORDERED:
    jsonb_agg(... ORDER BY product_type) makes the product-policy snapshot deterministic.

    Deterministic ordering makes visual comparison, hash comparison, and troubleshooting easier.

PARAMETER SNAPSHOT HASH:
    parameter_snapshot_hash is a fingerprint of:
        active strategy parameters,
        product policy parameters,
        and run-story parameters.

    It helps identify whether two evidence rows were created from the same parameter payload.

    It is not a cryptographic governance control.
    It is not a replacement for the full JSONB payload.
    It should be used as a comparison aid, not as the authoritative parameter record.

EVIDENCE SNAPSHOT ID:
    evidence_snapshot_id includes the current timestamp so each evidence-capture event receives a
    distinct identifier.

    It is audit metadata.

    It is not the run-key grain and should not replace:
        strategy_set_name,
        strategy_name,
        strategy_version,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id.

WHAT TO LOOK FOR AFTER THIS SECTION:
    credit_decisioning_sim.strategy_run_parameter_snapshot should contain one row for the current
    run key after Section 16.4 executes.

    The row should include:
        strategy_params_jsonb,
        product_policy_params_jsonb,
        run_story_params_jsonb,
        parameter_snapshot_hash,
        module2_run_id,
        validation_evidence_group_id,
        and run_registry_match_status.

REVIEW TRIGGERS:
    Missing strategy_params_jsonb:
        active strategy parameter card was not captured.

    Missing product_policy_params_jsonb:
        product-policy configuration was not captured.

    Missing run_story_params_jsonb:
        registry / story metadata was not captured.

    run_registry_match_status not equal to RUN_REGISTRY_MATCHED for a formal campaign run:
        evidence linkage should be reviewed before documentation.

MODULE 3 READINESS:
    This snapshot preserves product policy values that may later support:
        growth analysis,
        economics design,
        pricing proxy interpretation,
        exposure strategy,
        product mix review,
        and profitability design in a future Module 3.

    It does not calculate Module 3 economics.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CTE:
        snapshot_payload builds the one-row payload before insertion.

    to_jsonb:
        Converts a parameter row into a JSONB evidence object.

    jsonb_agg:
        Aggregates multiple product-policy rows into one ordered JSONB array.

    CROSS JOIN:
        Combines the one-row current run key with the one active story row.

    MD5:
        Creates compact fingerprint values for evidence_snapshot_id and parameter_snapshot_hash.

    COALESCE:
        Prevents NULL JSONB text from breaking hash creation.

BOUNDARY:
    Section 16.4 persists parameter evidence only.

    It does not modify active parameters.
    It does not modify latest-run output.
    It does not modify archive output.
    It does not modify campaign registry rows.
    It does not recalculate decisions.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.
    It does not reassign simulated reason codes.
    It does not calculate revenue, earnings, funding cost, profitability, capital, or margin.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.4A Insert current run parameter snapshot.

Business purpose:
    Preserve the exact parameter payload that produced the current run evidence.

SQL logic:
    snapshot_payload builds a one-row payload containing:
        current run key,
        current registry / story metadata,
        active strategy parameter JSON,
        ordered product-policy parameter JSON,
        active run-story metadata JSON.

    The final SELECT inserts the payload and calculates:
        evidence_snapshot_id,
        parameter_snapshot_hash.

How to interpret the inserted row:
    strategy_params_jsonb:
        full active strategy card.

    product_policy_params_jsonb:
        full product policy table as an ordered JSONB array.

    run_story_params_jsonb:
        registry and story metadata used by Section 16 evidence capture.

    parameter_snapshot_hash:
        compact payload comparison fingerprint.

Important:
    CURRENT_TIMESTAMP is used for capture timing.

    It should not be used as matched comparison grain.
-----------------------------------------------------------------------------------------------*/

INSERT INTO credit_decisioning_sim.strategy_run_parameter_snapshot (
    evidence_snapshot_ts,
    evidence_snapshot_id,

    campaign_registry_required_flag,
    registry_match_count,
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
    validation_summary_section_hint,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_params_jsonb,
    product_policy_params_jsonb,
    run_story_params_jsonb,
    parameter_snapshot_hash
)
WITH snapshot_payload AS (
    SELECT
        /*******************************************************************************************
        Current run key.

        tmp_m2_current_run_key must contain exactly one row because Section 16.0 already enforced
        single-run-key cardinality.

        This run key is the technical evidence grain.
        *******************************************************************************************/
        k.*,

        /*******************************************************************************************
        Current run registry / story metadata.

        tmp_m2_current_run_story_params must contain exactly one active row because Section 16.0
        already enforced story-row cardinality.

        These fields connect the technical run to the campaign roadmap and later documentation.
        *******************************************************************************************/
        s.campaign_registry_required_flag,
        s.registry_match_count,
        s.run_registry_match_status,

        s.module1_run_id,
        s.module2_run_id,
        s.run_sequence_number,

        s.showcase_id,
        s.showcase_name,
        s.comparison_group_id,
        s.validation_evidence_group_id,

        s.readme_storyline_label,
        s.linkedin_post_sequence,
        s.validation_summary_section_hint,

        /*******************************************************************************************
        Active strategy parameter snapshot.

        SQL mechanics:
            to_jsonb(sp) converts the active strategy parameter row into a JSONB object.

            LIMIT 1 is safe because Section 3 and Section 16.0 require exactly one active strategy
            parameter row.

        Interpretation:
            This JSONB payload preserves strategy identity, source selection, archive controls,
            registry requirement, thresholds, rule controls, decision conventions, and
            failed-counteroffer behavior.
        *******************************************************************************************/
        (
            SELECT to_jsonb(sp)
            FROM tmp_module2_strategy_params sp
            WHERE sp.active_strategy_flag IS TRUE
            LIMIT 1
        ) AS strategy_params_jsonb,

        /*******************************************************************************************
        Product policy parameter snapshot.

        SQL mechanics:
            jsonb_agg(to_jsonb(pp) ORDER BY pp.product_type) converts all product-policy rows into
            a stable ordered JSONB array.

        Interpretation:
            This preserves product caps, PTI thresholds, approved Expected Loss caps, counteroffer
            controls, and rounding controls.
        *******************************************************************************************/
        (
            SELECT jsonb_agg(to_jsonb(pp) ORDER BY pp.product_type)
            FROM tmp_module2_product_policy_params pp
        ) AS product_policy_params_jsonb,

        /*******************************************************************************************
        Run-story metadata snapshot.

        SQL mechanics:
            to_jsonb(rsp) captures the active story helper row.

        Interpretation:
            This preserves registry match status, formal run IDs, fallback story labels, expected
            storyline, observed storyline placeholder, and validation notes.
        *******************************************************************************************/
        (
            SELECT to_jsonb(rsp)
            FROM tmp_m2_current_run_story_params rsp
            WHERE rsp.active_story_flag IS TRUE
            LIMIT 1
        ) AS run_story_params_jsonb

    FROM tmp_m2_current_run_key k

    CROSS JOIN tmp_m2_current_run_story_params s

    WHERE s.active_story_flag IS TRUE
)

SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    /***********************************************************************************************
    Snapshot event ID.

    SQL mechanics:
        MD5 hashes the technical run key plus CURRENT_TIMESTAMP.

    Interpretation:
        This distinguishes separate evidence-capture events for the same run key.

        It is not the evidence grain.
    ***********************************************************************************************/
    MD5(
        strategy_set_name || '|'
        || strategy_name || '|'
        || strategy_version || '|'
        || module1_scenario_set_name || '|'
        || module1_scenario_name || '|'
        || population_id || '|'
        || CURRENT_TIMESTAMP::TEXT
    ) AS evidence_snapshot_id,

    /***********************************************************************************************
    Registry / campaign evidence fields.

    These values allow the parameter snapshot to be traced directly to the formal run roadmap.
    ***********************************************************************************************/
    campaign_registry_required_flag,
    registry_match_count,
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
    validation_summary_section_hint,

    /***********************************************************************************************
    Run identity and lineage.

    These fields preserve the technical SQL evidence grain alongside the registry metadata.
    ***********************************************************************************************/
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    /***********************************************************************************************
    Full parameter payloads.

    These JSONB objects are the authoritative parameter snapshot evidence.
    ***********************************************************************************************/
    strategy_params_jsonb,
    product_policy_params_jsonb,
    run_story_params_jsonb,

    /***********************************************************************************************
    Parameter payload fingerprint.

    SQL mechanics:
        COALESCE(..., '') protects the hash expression if any JSONB payload is unexpectedly NULL.

    Interpretation:
        The hash supports quick payload comparison across evidence rows.

        The JSONB payloads remain the authoritative evidence.
    ***********************************************************************************************/
    MD5(
        COALESCE(strategy_params_jsonb::TEXT, '')
        || '|'
        || COALESCE(product_policy_params_jsonb::TEXT, '')
        || '|'
        || COALESCE(run_story_params_jsonb::TEXT, '')
    ) AS parameter_snapshot_hash

FROM snapshot_payload;



/***************************************************************************************************
END OF SECTION 16.4 — CURRENT RUN PARAMETER SNAPSHOT

If execution reaches this point:
    1. tmp_m2_current_run_key exists and contains exactly one run key.
    2. tmp_m2_campaign_registry_current_run_match was consumed or safely fallback-initialized.
    3. tmp_m2_current_run_story_params exists and contains exactly one active story row.
    4. Section 16 confirmed the latest-run output exists and is populated.
    5. Section 16 confirmed Section 14 validation summary output is available.
    6. Section 16 confirmed Section 15 frontier executive summary output is available.
    7. Section 16 confirmed strategy and product-policy parameter tables are available.
    8. Section 16 confirmed registry matching when campaign_registry_required_flag = TRUE.
    9. Persistent evidence tables have been created or reused.
    10. Existing persistent evidence tables have been schema-hardened for registry-linkage fields.
    11. Prior evidence rows for the current run key have been deleted from evidence tables only.
    12. Current Section 14 validation evidence detail has been inserted with registry IDs.
    13. Current strategy / product-policy / story parameter snapshot has been inserted with registry
        IDs and full JSONB payloads.

No latest-run output rows have been modified.
No archive rows have been modified.
No strategy decision outcomes have been recalculated.
No approved exposure values have been recalculated.
No approved Expected Loss values have been recalculated.
No simulated reason codes have been reassigned.
No campaign registry rows have been modified.
No Module 3 revenue, earnings, profitability, pricing, funding-cost, or capital logic has been built.

Next Section 16 continuation:
    Section 16.5 should persist product × score segment evidence with the same registry fields, and
    Section 16.6 should persist the one-row executive evidence summary.

***************************************************************************************************/



/***************************************************************************************************
SECTION 16.5 — CAPTURE CURRENT RUN SEGMENT EVIDENCE SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Persist product × score-band evidence for the current completed Module 2 strategy run.

    Section 16.5 answers:

        "Which product × score-band segments drove the current run's access, exposure, approved
         Expected Loss, affordability, synthetic estimated-risk profile, and simulated reason-code
         story?"

SQL PURPOSE:
    1. Read the current latest-run output from credit_decisioning_sim.strategy_decisions.
    2. Read current registry / story metadata from tmp_m2_current_run_story_params.
    3. Group current-run evidence by:
            product_type_policy_key
            score_band_policy_key
            product_score_policy_segment
    4. Calculate segment-level decision counts and rates.
    5. Calculate segment-level requested amount, approved amount, and approved amount capture rate.
    6. Calculate segment-level APR proxy and term fields useful for future Module 3 design.
    7. Calculate segment-level synthetic estimated-risk proxy, LGD, requested Expected Loss,
       approved Expected Loss, and approved Expected Loss rate.
    8. Calculate segment-level requested PTI and approved PTI.
    9. Identify the top primary simulated reason code in each product × score segment.
    10. Identify the top non-approval simulated reason code in each product × score segment.
    11. Insert segment evidence into:
            credit_decisioning_sim.strategy_run_segment_evidence_summary

REGISTRY PATCH:
    Section 16.5 carries formal campaign registry fields into every segment evidence row:

        campaign_registry_required_flag
        registry_match_count
        run_registry_match_status
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

    This allows product × score evidence to be referenced directly in future Validation Summary,
    README storyline, LinkedIn evidence sequence, and comparison campaign documentation.

INPUTS:
    credit_decisioning_sim.strategy_decisions
    tmp_m2_current_run_story_params

OUTPUT:
    credit_decisioning_sim.strategy_run_segment_evidence_summary

TARGET GRAIN:
    One row per current run key
    × product_type_policy_key
    × score_band_policy_key
    × product_score_policy_segment.

WHY PRODUCT × SCORE SEGMENT EVIDENCE MATTERS:
    The one-row executive evidence summary is intentionally compact.

    Senior credit strategy review also needs the companion segment layer because strategy movement
    often concentrates in specific product × score intersections.

    Examples:
        unsecured / weaker-score segments may drive approved Expected Loss;
        revolving / weaker-score segments may drive decline concentration;
        secured / stronger-score segments may drive approved amount;
        near-prime product segments may drive counteroffer behavior.

    Section 16.5 preserves that segment evidence so the executive narrative is supported by a
    drill-down layer rather than a single portfolio average.

CREDIT RISK INTERPRETATION:
    Product × score evidence connects three core credit strategy dimensions:

        product:
            exposure structure, LGD, caps, payment behavior, counteroffer feasibility.

        score band:
            borrower-quality segmentation and synthetic estimated-risk ordering.

        final strategy outcome:
            access, counteroffer, manual review, no-offer, approved exposure, and approved Expected
            Loss.

    This table helps reviewers identify whether the portfolio story is broad-based or concentrated in
    a few segments.

WHAT TO LOOK FOR AFTER THIS SECTION:
    credit_decisioning_sim.strategy_run_segment_evidence_summary should contain one row for every
    product × score segment present in the current latest-run output.

    Segment rows should carry the same:
        module2_run_id,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id,
        and run_registry_match_status
    as the one-row executive evidence summary.

REVIEW TRIGGERS:
    A product × score segment with high approved Expected Loss:
        review product type, score band, approved amount, estimated_pd, estimated_lgd, and reason
        code.

    A product × score segment with high counteroffer rate:
        review product caps, affordability, approved Expected Loss cap, and counteroffer feasibility.

    A product × score segment with high decline rate:
        review policy-stop reason codes and whether the strategy posture explains the no-offer
        concentration.

    A product × score segment with missing top reason code:
        review reason-code completeness.

WHY THIS TABLE IS PERSISTENT:
    Section 14 QA and Section 15 frontier outputs are temporary.

    Section 16 evidence tables preserve the key results across the full scenario / strategy campaign.

    This avoids manually recovering product × score evidence from many QA grids after each run.

MODULE 3 READINESS:
    Product × score segment metrics are expected to be highly useful for future Module 3 economics
    design because revenue, funding cost, utilization, margin, and product profitability assumptions
    are likely to vary by both product and borrower-quality segment.

    Section 16.5 therefore captures:
        APR proxy metrics,
        approved exposure metrics,
        term metrics,
        product × score mix,
        synthetic estimated-risk proxy,
        LGD,
        approved Expected Loss,
        and approved Expected Loss rate.

    Section 16.5 does not calculate revenue, funding cost, profitability, capital, yield, margin, or
    risk-adjusted return.

INTERPRETATION BOUNDARIES:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

    requested_expected_loss_amount is requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount is simulated approved-exposure Expected Loss after Module 2
    exposure treatment.

    simulated_offer_exposure_flag identifies APPROVE and COUNTEROFFER rows only.

    Reason-code fields are simulated strategy explanation codes only.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CTE story:
        Pulls the single active registry / story row into the segment evidence insert.

    CTE segment_summary:
        Aggregates applicant-level latest-run rows to product × score segment grain.

    COUNT(*) FILTER:
        Creates segment-level outcome counts and rates.

    COALESCE:
        Converts no-offer or unresolved approved amounts to zero for all-application impact metrics.

    NULLIF:
        Protects rate and ratio calculations from divide-by-zero.

    ROW_NUMBER:
        Ranks reason codes within each segment so the top reason can be selected deterministically.

    LEFT JOIN:
        Adds reason-code labels without dropping segment rows.

READ-ONLY / PERSISTENCE BOUNDARY:
    Section 16.5 inserts evidence rows into a persistent evidence table.

    It does not modify:
        credit_decisioning_sim.strategy_decisions,
        credit_decisioning_sim.strategy_decisions_archive,
        strategy parameters,
        product policy parameters,
        campaign registry rows,
        decision outcomes,
        approved exposure values,
        approved Expected Loss values,
        or simulated reason codes.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.5A Insert current run product × score segment evidence.

Business purpose:
    Preserve the segment-level companion evidence that supports the one-row executive story.

SQL logic:
    1. story selects the one active registry / story row.
    2. segment_summary aggregates current latest-run rows by product × score segment.
    3. reason_counts calculates reason-code frequency by segment.
    4. top_reason selects the dominant overall reason code per segment.
    5. top_non_approval_reason selects the dominant friction / constraint reason per segment.
    6. The final SELECT inserts one persistent evidence row per segment.

Interpretation:
    This table is the drill-down layer that explains which segments drove portfolio-level results.
-----------------------------------------------------------------------------------------------*/

INSERT INTO credit_decisioning_sim.strategy_run_segment_evidence_summary (
    evidence_snapshot_ts,

    /***********************************************************************************************
    Campaign registry / run-story linkage fields.

    These fields connect segment evidence back to the campaign roadmap, comparison group, validation
    evidence group, README storyline, and LinkedIn sequence.
    ***********************************************************************************************/
    campaign_registry_required_flag,
    registry_match_count,
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
    validation_summary_section_hint,

    /***********************************************************************************************
    Current run identity.
    ***********************************************************************************************/
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    /***********************************************************************************************
    Module 1 scenario / population lineage.
    ***********************************************************************************************/
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    /***********************************************************************************************
    Product × score segment identity.
    ***********************************************************************************************/
    product_type_policy_key,
    score_band_policy_key,
    product_score_policy_segment,

    /***********************************************************************************************
    Segment population and final decision counts.
    ***********************************************************************************************/
    applications,

    approval_count,
    counteroffer_count,
    manual_review_count,
    decline_count,
    offer_count,

    /***********************************************************************************************
    Segment final decision rates.
    ***********************************************************************************************/
    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,

    /***********************************************************************************************
    Segment requested and approved exposure metrics.
    ***********************************************************************************************/
    total_requested_amount,
    total_approved_amount,
    approved_amount_capture_rate,

    avg_requested_amount,
    avg_approved_amount_all_apps,
    avg_approved_amount_offer_rows,

    /***********************************************************************************************
    Segment Module 3 readiness metrics.

    These are APR-proxy and term inputs only.
    They are not revenue, pricing, profitability, or margin outputs.
    ***********************************************************************************************/
    avg_apr_proxy_all_apps,
    avg_apr_proxy_offer_rows,
    requested_amount_weighted_apr_proxy,
    approved_amount_weighted_apr_proxy,

    avg_loan_term_months_offer_rows,
    approved_amount_weighted_term_months,

    /***********************************************************************************************
    Segment synthetic risk, LGD, and Expected Loss metrics.
    ***********************************************************************************************/
    avg_synthetic_estimated_pd_proxy_all_apps,
    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_estimated_lgd_offer_rows,

    total_requested_expected_loss_amount,
    total_approved_expected_loss_amount,
    approved_expected_loss_rate,

    /***********************************************************************************************
    Segment affordability metrics.
    ***********************************************************************************************/
    avg_requested_payment_to_income_ratio,
    avg_approved_payment_to_income_ratio_offer_rows,

    /***********************************************************************************************
    Segment simulated reason-code story fields.
    ***********************************************************************************************/
    top_primary_reason_family,
    top_primary_reason_code,
    top_primary_reason_population_share,

    top_non_approval_primary_reason_family,
    top_non_approval_primary_reason_code,
    top_non_approval_reason_population_share
)
WITH story AS (
    /***********************************************************************************************
    CTE: story

    Purpose:
        Select the one active current-run registry / story row created in Section 16.0.

    Why this CTE exists:
        Segment evidence should carry the same campaign IDs as the executive evidence row,
        validation evidence rows, and parameter snapshot.

    Gatekeeper dependency:
        Section 16.0 validates that exactly one active story row exists.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_current_run_story_params
    WHERE active_story_flag IS TRUE
    LIMIT 1
),

segment_summary AS (
    /***********************************************************************************************
    CTE: segment_summary

    Purpose:
        Collapse the current applicant-level latest-run output into product × score segment metrics.

    Grain:
        One row per current run key × product × score × product_score_policy_segment.

    Metric conventions:
        all-application approved metrics:
            use COALESCE(approved_amount, 0) and COALESCE(approved_expected_loss_amount, 0).

        offer-row metrics:
            use FILTER (WHERE simulated_offer_exposure_flag IS TRUE).

        approved_expected_loss_rate:
            total approved Expected Loss / total approved amount.

        approved_amount_capture_rate:
            total approved amount / total requested amount.

    Boundary:
        This CTE summarizes existing output only.

        It does not recalculate decisions, approved exposure, approved PTI, approved Expected Loss,
        or reason codes.
    ***********************************************************************************************/
    SELECT
        /*******************************************************************************************
        Run identity carried from the latest-run table.
        *******************************************************************************************/
        module2_model_version,
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        strategy_run_ts,

        /*******************************************************************************************
        Module 1 lineage.
        *******************************************************************************************/
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,

        /*******************************************************************************************
        Segment identity.

        product_score_policy_segment is retained so this table can support executive labels without
        recomputing display names later.
        *******************************************************************************************/
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,

        /*******************************************************************************************
        Segment size.

        applications is the denominator for segment-level rates.
        *******************************************************************************************/
        COUNT(*) AS applications,

        /*******************************************************************************************
        Final decision counts.

        offer_count equals APPROVE + COUNTEROFFER because simulated_offer_exposure_flag is TRUE only
        for simulated positive offer-exposure outcomes.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

        /*******************************************************************************************
        Final decision rates.

        SQL mechanics:
            FILTER creates the numerator.
            COUNT(*) creates the segment denominator.
            NULLIF protects against divide-by-zero.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        /*******************************************************************************************
        Requested and approved exposure metrics.

        approved_amount_capture_rate summarizes how much requested exposure survived final simulated
        strategy treatment in the segment.
        *******************************************************************************************/
        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,

        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        /*******************************************************************************************
        APR proxy metrics for future Module 3.

        base_apr_for_payment_calc is preserved as an APR proxy input.

        It is not a pricing optimization result, yield estimate, or revenue calculation.
        *******************************************************************************************/
        AVG(base_apr_for_payment_calc) AS avg_apr_proxy_all_apps,

        AVG(base_apr_for_payment_calc) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_apr_proxy_offer_rows,

        SUM(requested_amount * base_apr_for_payment_calc)
            / NULLIF(SUM(requested_amount), 0) AS requested_amount_weighted_apr_proxy,

        SUM(COALESCE(approved_amount, 0) * base_apr_for_payment_calc)
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0) AS approved_amount_weighted_apr_proxy,

        /*******************************************************************************************
        Term metrics for future Module 3.

        loan_term_months may be NULL or not meaningful for revolving products.

        The weighted term metric therefore protects against NULL term denominators.
        *******************************************************************************************/
        AVG(loan_term_months) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_loan_term_months_offer_rows,

        SUM(COALESCE(approved_amount, 0) * loan_term_months)
            / NULLIF(
                SUM(COALESCE(approved_amount, 0)) FILTER (WHERE loan_term_months IS NOT NULL),
                0
              )
            AS approved_amount_weighted_term_months,

        /*******************************************************************************************
        Synthetic estimated-risk proxy and LGD metrics.

        estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD
        proxy.
        *******************************************************************************************/
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_estimated_lgd_offer_rows,

        /*******************************************************************************************
        Requested and approved Expected Loss metrics.

        requested_expected_loss_amount:
            requested-exposure Expected Loss from Module 1.

        approved_expected_loss_amount:
            approved-exposure Expected Loss after Module 2 final exposure treatment.
        *******************************************************************************************/
        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        /*******************************************************************************************
        Requested versus approved affordability metrics.

        requested_payment_to_income_ratio:
            original requested-structure PTI.

        approved_payment_to_income_ratio:
            final approved-exposure PTI proxy for simulated offer rows.
        *******************************************************************************************/
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY
        module2_model_version,
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        strategy_run_ts,
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment
),

reason_counts AS (
    /***********************************************************************************************
    CTE: reason_counts

    Purpose:
        Count simulated primary reason-code distribution within each product × score segment.

    Why this CTE exists:
        Segment evidence should not only say what happened numerically.

        It should also explain why the segment moved through simulated reason-code evidence.

    Boundary:
        Reason codes are simulated strategy explanation codes only.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,

        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS reason_row_count

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,
        primary_reason_family,
        primary_reason_code
),

top_reason AS (
    /***********************************************************************************************
    CTE: top_reason

    Purpose:
        Rank all primary reason codes within each segment and identify the top overall reason.

    SQL mechanics:
        ROW_NUMBER ranks reason codes by descending row count.

    Deterministic tie-break:
        primary_reason_family, then primary_reason_code.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,
        primary_reason_family,
        primary_reason_code,
        reason_row_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                product_type_policy_key,
                score_band_policy_key,
                product_score_policy_segment
            ORDER BY
                reason_row_count DESC,
                primary_reason_family,
                primary_reason_code
        ) AS reason_rank

    FROM reason_counts
),

top_non_approval_reason AS (
    /***********************************************************************************************
    CTE: top_non_approval_reason

    Purpose:
        Rank non-approval reason codes within each segment.

    Why separate from top_reason:
        The top overall reason is often APPROVED_AS_REQUESTED in high-access segments.

        That is technically correct but may not explain constraints, tightening, or no-offer behavior.

        The top non-approval reason helps explain the primary friction point in the segment.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,
        primary_reason_family,
        primary_reason_code,
        reason_row_count,

        ROW_NUMBER() OVER (
            PARTITION BY
                product_type_policy_key,
                score_band_policy_key,
                product_score_policy_segment
            ORDER BY
                reason_row_count DESC,
                primary_reason_family,
                primary_reason_code
        ) AS reason_rank

    FROM reason_counts

    WHERE primary_reason_family <> 'APPROVAL'
)

SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    /***********************************************************************************************
    Campaign registry / run story fields.

    These fields come from tmp_m2_current_run_story_params, which Section 16.0 builds from the
    campaign registry first and fallback labels second.
    ***********************************************************************************************/
    story.campaign_registry_required_flag,
    story.registry_match_count,
    story.run_registry_match_status,

    story.module1_run_id,
    story.module2_run_id,
    story.run_sequence_number,

    story.showcase_id,
    story.showcase_name,
    story.comparison_group_id,
    story.validation_evidence_group_id,

    story.readme_storyline_label,
    story.linkedin_post_sequence,
    story.validation_summary_section_hint,

    /***********************************************************************************************
    Current run identity.
    ***********************************************************************************************/
    s.module2_model_version,
    s.strategy_set_name,
    s.strategy_name,
    s.strategy_version,
    s.strategy_run_id,
    s.strategy_run_ts,

    /***********************************************************************************************
    Module 1 lineage.
    ***********************************************************************************************/
    s.module1_scenario_set_name,
    s.module1_scenario_name,
    s.population_id,

    /***********************************************************************************************
    Segment identity.
    ***********************************************************************************************/
    s.product_type_policy_key,
    s.score_band_policy_key,
    s.product_score_policy_segment,

    /***********************************************************************************************
    Segment counts and rates.
    ***********************************************************************************************/
    s.applications,

    s.approval_count,
    s.counteroffer_count,
    s.manual_review_count,
    s.decline_count,
    s.offer_count,

    s.approval_rate,
    s.counteroffer_rate,
    s.manual_review_rate,
    s.decline_rate,
    s.simulated_offer_exposure_rate,

    /***********************************************************************************************
    Segment exposure metrics.
    ***********************************************************************************************/
    s.total_requested_amount,
    s.total_approved_amount,
    s.approved_amount_capture_rate,

    s.avg_requested_amount,
    s.avg_approved_amount_all_apps,
    s.avg_approved_amount_offer_rows,

    /***********************************************************************************************
    Segment Module 3 readiness metrics.
    ***********************************************************************************************/
    s.avg_apr_proxy_all_apps,
    s.avg_apr_proxy_offer_rows,
    s.requested_amount_weighted_apr_proxy,
    s.approved_amount_weighted_apr_proxy,

    s.avg_loan_term_months_offer_rows,
    s.approved_amount_weighted_term_months,

    /***********************************************************************************************
    Segment risk and Expected Loss metrics.
    ***********************************************************************************************/
    s.avg_synthetic_estimated_pd_proxy_all_apps,
    s.avg_synthetic_estimated_pd_proxy_offer_rows,
    s.avg_estimated_lgd_offer_rows,

    s.total_requested_expected_loss_amount,
    s.total_approved_expected_loss_amount,
    s.approved_expected_loss_rate,

    /***********************************************************************************************
    Segment affordability metrics.
    ***********************************************************************************************/
    s.avg_requested_payment_to_income_ratio,
    s.avg_approved_payment_to_income_ratio_offer_rows,

    /***********************************************************************************************
    Segment simulated reason-code evidence.

    top_primary_reason_*:
        dominant overall segment explanation.

    top_non_approval_*:
        dominant segment friction / constraint explanation, excluding APPROVAL family reasons.
    ***********************************************************************************************/
    tr.primary_reason_family AS top_primary_reason_family,
    tr.primary_reason_code AS top_primary_reason_code,
    tr.reason_row_count::NUMERIC
        / NULLIF(s.applications, 0) AS top_primary_reason_population_share,

    nr.primary_reason_family AS top_non_approval_primary_reason_family,
    nr.primary_reason_code AS top_non_approval_primary_reason_code,
    nr.reason_row_count::NUMERIC
        / NULLIF(s.applications, 0) AS top_non_approval_reason_population_share

FROM segment_summary s

CROSS JOIN story

LEFT JOIN top_reason tr
    ON tr.product_type_policy_key = s.product_type_policy_key
   AND tr.score_band_policy_key = s.score_band_policy_key
   AND tr.product_score_policy_segment = s.product_score_policy_segment
   AND tr.reason_rank = 1

LEFT JOIN top_non_approval_reason nr
    ON nr.product_type_policy_key = s.product_type_policy_key
   AND nr.score_band_policy_key = s.score_band_policy_key
   AND nr.product_score_policy_segment = s.product_score_policy_segment
   AND nr.reason_rank = 1;



/***************************************************************************************************
SECTION 16.6 — CAPTURE CURRENT RUN EXECUTIVE EVIDENCE SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Insert the one-row executive evidence summary for the current completed Module 2 strategy run.

    Section 16.6 answers:

        "What is the compact executive story of this completed run, including campaign run IDs,
         outcome distribution, simulated offer exposure, approved exposure, approved Expected Loss,
         reason-code story, validation status, segment drivers, frontier posture, and Module 3
         readiness?"

SQL PURPOSE:
    1. Read the current run key from tmp_m2_current_run_key.
    2. Read current registry / story labels from tmp_m2_current_run_story_params.
    3. Read the current archive timestamp for the matching archived slice.
    4. Calculate portfolio-level outcome, exposure, affordability, APR proxy, term, synthetic-risk,
       LGD, and Expected Loss metrics directly from credit_decisioning_sim.strategy_decisions.
    5. Calculate product-level, score-band-level, and product × score driver fields.
    6. Calculate top simulated reason-code story fields.
    7. Summarize Section 14 validation statuses.
    8. Join Section 15 frontier posture fields for the current run.
    9. Calculate baseline-relative segment-delta driver fields where a baseline exists.
    10. Calculate Module 3 readiness flags and gap notes.
    11. Insert exactly one executive evidence row into:
            credit_decisioning_sim.strategy_run_evidence_summary

REGISTRY PATCH:
    Section 16.6 persists formal campaign registry fields in the one-row executive evidence summary:

        campaign_registry_required_flag
        registry_match_count
        run_registry_match_status
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

    These fields make the evidence row directly linkable to the run roadmap, comparison registry,
    future Validation Summary, GitHub README, and LinkedIn campaign sequence.

INPUTS:
    tmp_m2_current_run_key
    tmp_m2_current_run_story_params
    tmp_m2_validation_status_summary
    tmp_m2_strategy_frontier_executive_summary
    credit_decisioning_sim.strategy_decisions
    credit_decisioning_sim.strategy_decisions_archive

OUTPUT:
    credit_decisioning_sim.strategy_run_evidence_summary

TARGET GRAIN:
    One row per current run key:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

WHY MOST METRICS ARE CALCULATED FROM THE LATEST-RUN TABLE:
    Section 16.6 captures the current completed run.

    credit_decisioning_sim.strategy_decisions is the current latest-run output and contains the
    final applicant-level strategy result.

    Calculating portfolio and driver metrics directly from this table ensures that the executive
    evidence row reflects the current latest-run output being captured.

WHY FRONTIER FIELDS COME FROM SECTION 15:
    Section 15 already calculates archive-backed frontier posture, executive quadrant, and
    baseline-relative reason-code movement.

    Section 16.6 carries those fields into persistent evidence rather than recalculating the frontier.

WHY VALIDATION FIELDS COME FROM SECTION 14:
    Section 14 already materializes tmp_m2_validation_status_summary.

    Section 16.6 summarizes those statuses into counts, review-item text, and JSONB evidence so the
    executive row can be traced back to validation evidence.

WHY SEGMENT DRIVER FIELDS ARE CALCULATED HERE:
    The one-row executive evidence summary needs concise driver labels, not full segment tables.

    Section 16.5 stores the full product × score companion table.

    Section 16.6 stores the most important driver labels, such as:
        top approved amount product,
        top approved Expected Loss product,
        top counteroffer product,
        top decline product,
        highest offer-rate score band,
        and largest baseline-relative delta segments.

WHAT TO LOOK FOR AFTER THIS SECTION:
    credit_decisioning_sim.strategy_run_evidence_summary should contain exactly one row for the
    current run key.

    The row should include:
        registry IDs,
        strategy identity,
        Module 1 scenario lineage,
        final outcome counts and rates,
        exposure metrics,
        approved Expected Loss metrics,
        reason-code story fields,
        validation rollup,
        segment drivers,
        frontier posture,
        and Module 3 readiness indicators.

REVIEW TRIGGERS:
    Missing executive evidence row:
        Section 16.6 did not complete or the run key did not match.

    Missing frontier_position_type:
        Section 15 frontier row did not match the current run key.

    Missing validation counts:
        Section 14 validation summary was not available or did not populate.

    Missing module2_run_id on a formal campaign run:
        registry linkage should be reviewed before documentation.

MODULE 3 READINESS:
    Section 16.6 captures whether key future economics inputs exist.

    It does not calculate:
        revenue,
        yield,
        funding cost,
        fee income,
        utilization,
        profitability,
        capital,
        pricing optimization,
        risk-adjusted margin,
        lifetime value,
        or net income.

INTERPRETATION BOUNDARIES:
    approved_expected_loss_rate is a synthetic strategy evidence metric.

    It is not a production loss-rate forecast.

    approved_amount is simulated approved exposure.

    It is not booked exposure, funded exposure, account creation, or production approval.

    Reason codes are simulated strategy explanation codes only.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CTE chain:
        Breaks a complex executive evidence insert into named, interpretable layers.

    CROSS JOIN:
        Combines one-row CTEs into one executive evidence row.

    LEFT JOIN:
        Keeps the evidence insert structurally tolerant if a frontier row is unexpectedly absent.

    COUNT(*) FILTER:
        Calculates outcome-specific counts and rates.

    COALESCE:
        Converts no-offer / unresolved approved metrics to zero for all-application impact measures.

    NULLIF:
        Prevents divide-by-zero in rates and ratios.

    jsonb_object_agg:
        Preserves compact product-level driver evidence inside one executive evidence row.

    STRING_AGG:
        Creates a readable validation-review summary.

    jsonb_agg:
        Preserves validation status details as structured evidence.

READ-ONLY / PERSISTENCE BOUNDARY:
    Section 16.6 inserts one evidence row.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not modify campaign registry rows.
    It does not recalculate decisions.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.
    It does not reassign simulated reason codes.
    It does not modify strategy or product-policy parameters.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.6A Insert one-row current run executive evidence summary.

Business purpose:
    Preserve the compact executive story for the completed run.

SQL logic:
    This INSERT uses a CTE chain to calculate portfolio, product, score-band, product × score,
    reason-code, validation, frontier, baseline-delta, and Module 3 readiness evidence.

Interpretation:
    This is the primary run evidence row for documentation and executive review.

    It should be interpreted together with:
        strategy_run_validation_evidence,
        strategy_run_parameter_snapshot,
        strategy_run_segment_evidence_summary.
-----------------------------------------------------------------------------------------------*/

INSERT INTO credit_decisioning_sim.strategy_run_evidence_summary (
    evidence_snapshot_ts,
    evidence_snapshot_id,

    /***********************************************************************************************
    Campaign registry / story metadata.
    ***********************************************************************************************/
    campaign_registry_required_flag,
    registry_match_count,
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
    validation_summary_section_hint,

    module1_parameter_family_changed,
    module1_parameter_change_summary,
    module2_strategy_family_changed,
    module2_parameter_change_summary,
    expected_storyline,
    observed_storyline,
    validation_notes,

    /***********************************************************************************************
    Module 2 strategy identity.
    ***********************************************************************************************/
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    /***********************************************************************************************
    Output and archive timestamp metadata.
    ***********************************************************************************************/
    latest_output_created_ts,
    archive_inserted_ts,

    /***********************************************************************************************
    Archive and failed-counteroffer controls.
    ***********************************************************************************************/
    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution,

    /***********************************************************************************************
    Module 1 source mode.
    ***********************************************************************************************/
    module1_input_source,
    module1_source_table_name,

    /***********************************************************************************************
    Module 1 lineage.
    ***********************************************************************************************/
    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,

    /***********************************************************************************************
    Structural counts.
    ***********************************************************************************************/
    applications,
    distinct_application_id_count,
    duplicate_application_count,

    /***********************************************************************************************
    Final decision counts.
    ***********************************************************************************************/
    approval_count,
    counteroffer_count,
    manual_review_count,
    decline_count,
    offer_count,

    /***********************************************************************************************
    Final decision rates.
    ***********************************************************************************************/
    approval_rate,
    counteroffer_rate,
    manual_review_rate,
    decline_rate,
    simulated_offer_exposure_rate,
    approval_share_of_offers,
    counteroffer_share_of_offers,

    /***********************************************************************************************
    Requested and approved exposure metrics.
    ***********************************************************************************************/
    total_requested_amount,
    total_approved_amount,
    approved_amount_capture_rate,

    avg_requested_amount,
    avg_approved_amount_all_apps,
    avg_approved_amount_offer_rows,

    total_exposure_reduction_amount,

    /***********************************************************************************************
    Final outcome exposure subpopulation metrics.
    ***********************************************************************************************/
    counteroffer_requested_amount,
    counteroffer_approved_amount,
    counteroffer_exposure_reduction_amount,
    counteroffer_exposure_reduction_pct_avg,

    manual_review_requested_amount,
    manual_review_requested_expected_loss_amount,
    decline_requested_amount,
    decline_requested_expected_loss_amount,

    /***********************************************************************************************
    Affordability metrics.
    ***********************************************************************************************/
    avg_requested_payment_to_income_ratio,
    avg_approved_payment_to_income_ratio_offer_rows,

    /***********************************************************************************************
    Module 3 readiness APR proxy metrics.
    ***********************************************************************************************/
    avg_apr_proxy_all_apps,
    avg_apr_proxy_offer_rows,
    requested_amount_weighted_apr_proxy,
    approved_amount_weighted_apr_proxy,
    requested_amount_x_apr_proxy_sum,
    approved_amount_x_apr_proxy_sum,

    /***********************************************************************************************
    Module 3 readiness term metrics.
    ***********************************************************************************************/
    avg_loan_term_months_offer_rows,
    approved_amount_weighted_term_months,
    term_missing_or_revolving_count,

    /***********************************************************************************************
    Product exposure mix metrics.
    ***********************************************************************************************/
    secured_approved_amount_share,
    unsecured_approved_amount_share,
    revolving_approved_amount_share,
    installment_approved_amount_share,
    mortgage_approved_amount_share,

    product_approved_amount_mix_jsonb,
    product_approved_expected_loss_mix_jsonb,
    product_offer_rate_jsonb,

    /***********************************************************************************************
    Synthetic estimated-risk proxy and LGD metrics.
    ***********************************************************************************************/
    avg_synthetic_estimated_pd_proxy_all_apps,
    avg_synthetic_estimated_pd_proxy_offer_rows,
    avg_synthetic_estimated_pd_proxy_declined_rows,

    avg_estimated_lgd_all_apps,
    avg_estimated_lgd_offer_rows,

    /***********************************************************************************************
    Requested and approved Expected Loss metrics.
    ***********************************************************************************************/
    total_requested_expected_loss_amount,
    total_approved_expected_loss_amount,
    avg_requested_expected_loss_amount,
    avg_approved_expected_loss_all_apps,
    avg_approved_expected_loss_offer_rows,

    requested_expected_loss_rate,
    approved_expected_loss_rate,
    approved_amount_per_approved_expected_loss_dollar,

    /***********************************************************************************************
    Simulated reason-code story fields.
    ***********************************************************************************************/
    top_primary_reason_family,
    top_primary_reason_code,
    top_primary_reason_population_share,

    top_non_approval_primary_reason_family,
    top_non_approval_primary_reason_code,
    top_non_approval_reason_population_share,

    top_policy_stop_primary_reason_family,
    top_policy_stop_primary_reason_code,
    top_policy_stop_reason_population_share,

    top_reason_code_delta_driver_family,
    top_reason_code_delta_driver_code,
    top_reason_code_delta_driver_baseline_share,
    top_reason_code_delta_driver_strategy_share,
    top_reason_code_delta_population_share,

    top_counteroffer_reason_code,
    top_manual_review_reason_code,
    top_decline_reason_code,

    /***********************************************************************************************
    Frontier posture fields from Section 15.
    ***********************************************************************************************/
    frontier_position_type,
    executive_frontier_quadrant,
    frontier_interpretation_note,

    /***********************************************************************************************
    Validation rollup fields from Section 14.
    ***********************************************************************************************/
    validation_pass_count,
    validation_review_count,
    validation_not_applicable_count,
    validation_review_items,
    validation_status_summary_jsonb,

    /***********************************************************************************************
    Product driver fields.
    ***********************************************************************************************/
    top_approved_amount_product,
    top_approved_amount_product_share,
    top_approved_expected_loss_product,
    top_approved_expected_loss_product_share,
    top_counteroffer_product,
    top_decline_product,
    highest_offer_rate_product,
    lowest_offer_rate_product,

    /***********************************************************************************************
    Score-band driver fields.
    ***********************************************************************************************/
    top_approved_amount_score_band,
    top_approved_expected_loss_score_band,
    top_counteroffer_score_band,
    top_decline_score_band,
    highest_offer_rate_score_band,
    lowest_offer_rate_score_band,
    highest_approved_el_rate_score_band,

    /***********************************************************************************************
    Product × score driver fields.
    ***********************************************************************************************/
    top_approved_amount_product_score_segment,
    top_approved_el_product_score_segment,
    top_counteroffer_product_score_segment,
    top_decline_product_score_segment,
    highest_approved_el_rate_product_score_segment,

    /***********************************************************************************************
    Baseline-relative segment movement fields.
    ***********************************************************************************************/
    largest_delta_approved_amount_product,
    largest_delta_approved_el_product,
    largest_delta_offer_rate_score_band,
    largest_delta_decline_rate_score_band,
    largest_delta_approved_el_product_score_segment,

    /***********************************************************************************************
    Module 3 readiness fields.
    ***********************************************************************************************/
    module3_growth_inputs_available_flag,
    module3_growth_input_gap_note,
    module3_revenue_model_required_flag,
    module3_boundary_note
)
WITH current_key AS (
    /***********************************************************************************************
    CTE: current_key

    Purpose:
        Select the single current run key created in Section 16.0.

    Why LIMIT 1 is safe:
        Section 16.0 gatekeeper already validated that tmp_m2_current_run_key contains exactly one
        row.

    Boundary:
        This CTE identifies the run being captured. It does not calculate metrics.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
),

story AS (
    /***********************************************************************************************
    CTE: story

    Purpose:
        Select the single active current-run registry / story metadata row.

    Why this matters:
        Technical identifiers are necessary but not sufficient for executive evidence.

        The story metadata supplies:
            registry match status,
            module1_run_id,
            module2_run_id,
            run_sequence_number,
            showcase_id,
            comparison_group_id,
            validation_evidence_group_id,
            README / LinkedIn labels,
            parameter-family labels,
            expected storyline,
            observed storyline override,
            and validation notes.

    Boundary:
        Story labels do not change decision outcomes or strategy logic.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_m2_current_run_story_params
    WHERE active_story_flag IS TRUE
    LIMIT 1
),

archive_ts AS (
    /***********************************************************************************************
    CTE: archive_ts

    Purpose:
        Retrieve the most recent archive_inserted_ts for the current run key.

    Why MAX is used:
        The archive table is applicant-grain. Every archived row in the same slice should generally
        share the same persistence timestamp, but MAX provides a simple robust audit timestamp.

    Interpretation:
        archive_inserted_ts is evidence traceability metadata.

        It is not a strategy metric and not a comparison grain.
    ***********************************************************************************************/
    SELECT
        MAX(ar.archive_inserted_ts) AS archive_inserted_ts

    FROM credit_decisioning_sim.strategy_decisions_archive ar

    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = k.strategy_name
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id
),

portfolio AS (
    /***********************************************************************************************
    CTE: portfolio

    Purpose:
        Calculate core run-level portfolio evidence directly from the latest-run output.

    Why this CTE is large:
        The executive evidence summary is intended to be a single durable row that avoids forcing the
        reviewer to manually collect metrics from many QA outputs.

    Metric groups:
        structural counts,
        decision counts,
        decision rates,
        requested / approved exposure,
        counteroffer exposure treatment,
        manual-review unresolved exposure,
        decline no-offer exposure,
        requested and approved PTI,
        APR proxy,
        term,
        product mix,
        synthetic estimated-risk proxy,
        LGD,
        requested Expected Loss,
        approved Expected Loss,
        approved Expected Loss rate,
        and approved amount per approved Expected Loss dollar.

    Boundary:
        Metrics are aggregations over existing latest-run outputs.
        No applicant-level fields are recalculated.
    ***********************************************************************************************/
    SELECT
        /*******************************************************************************************
        Structural counts.
        *******************************************************************************************/
        COUNT(*) AS applications,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,
        COUNT(*) - COUNT(DISTINCT application_id) AS duplicate_application_count,

        /*******************************************************************************************
        Final decision counts.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,

        /*******************************************************************************************
        Final decision rates.
        *******************************************************************************************/
        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS approval_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*), 0) AS counteroffer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')::NUMERIC
            / NULLIF(COUNT(*), 0) AS manual_review_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS decline_rate,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS approval_share_of_offers,

        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER')::NUMERIC
            / NULLIF(COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE), 0)
            AS counteroffer_share_of_offers,

        /*******************************************************************************************
        Requested and approved exposure metrics.
        *******************************************************************************************/
        SUM(requested_amount) AS total_requested_amount,
        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(requested_amount), 0) AS approved_amount_capture_rate,

        AVG(requested_amount) AS avg_requested_amount,
        AVG(COALESCE(approved_amount, 0)) AS avg_approved_amount_all_apps,
        AVG(approved_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_amount_offer_rows,

        /*******************************************************************************************
        Exposure-reduction metrics.

        These help explain counteroffer management and no-offer exposure removal.
        *******************************************************************************************/
        SUM(COALESCE(exposure_reduction_amount, 0)) AS total_exposure_reduction_amount,

        SUM(requested_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_requested_amount,

        SUM(approved_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_approved_amount,

        SUM(exposure_reduction_amount) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_exposure_reduction_amount,

        AVG(exposure_reduction_pct) FILTER (WHERE decision_outcome = 'COUNTEROFFER')
            AS counteroffer_exposure_reduction_pct_avg,

        /*******************************************************************************************
        Unresolved manual-review and decline exposure context.

        Manual-review requested values remain useful because manual-review rows are unresolved.

        Decline requested values show the no-offer population's requested exposure and requested
        Expected Loss profile.
        *******************************************************************************************/
        SUM(requested_amount) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_requested_amount,

        SUM(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW')
            AS manual_review_requested_expected_loss_amount,

        SUM(requested_amount) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_requested_amount,

        SUM(requested_expected_loss_amount) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_requested_expected_loss_amount,

        /*******************************************************************************************
        Requested and approved affordability metrics.
        *******************************************************************************************/
        AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,

        AVG(approved_payment_to_income_ratio) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_payment_to_income_ratio_offer_rows,

        /*******************************************************************************************
        APR proxy metrics for Module 3 readiness.

        These are preserved for future economics but are not revenue or profitability calculations.
        *******************************************************************************************/
        AVG(base_apr_for_payment_calc) AS avg_apr_proxy_all_apps,

        AVG(base_apr_for_payment_calc) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_apr_proxy_offer_rows,

        SUM(requested_amount * base_apr_for_payment_calc)
            / NULLIF(SUM(requested_amount), 0)
            AS requested_amount_weighted_apr_proxy,

        SUM(COALESCE(approved_amount, 0) * base_apr_for_payment_calc)
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_amount_weighted_apr_proxy,

        SUM(requested_amount * base_apr_for_payment_calc)
            AS requested_amount_x_apr_proxy_sum,

        SUM(COALESCE(approved_amount, 0) * base_apr_for_payment_calc)
            AS approved_amount_x_apr_proxy_sum,

        /*******************************************************************************************
        Term metrics for Module 3 readiness.

        term_missing_or_revolving_count preserves the fact that term may be unavailable or not
        meaningful for revolving exposure.
        *******************************************************************************************/
        AVG(loan_term_months) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_loan_term_months_offer_rows,

        SUM(COALESCE(approved_amount, 0) * loan_term_months)
            / NULLIF(
                SUM(COALESCE(approved_amount, 0)) FILTER (WHERE loan_term_months IS NOT NULL),
                0
              )
            AS approved_amount_weighted_term_months,

        COUNT(*) FILTER (
            WHERE loan_term_months IS NULL
               OR product_type_policy_key IN ('REVOLVING_LINE')
        ) AS term_missing_or_revolving_count,

        /*******************************************************************************************
        Product approved-exposure composition metrics.

        These fields support future economics interpretation and portfolio mix storytelling.
        *******************************************************************************************/
        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('MORTGAGE', 'HELOC', 'AUTO_LOAN')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS secured_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('REVOLVING_LINE', 'UNSECURED_PERSONAL_LOAN')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS unsecured_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('REVOLVING_LINE', 'HELOC')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS revolving_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key IN ('MORTGAGE', 'AUTO_LOAN', 'UNSECURED_PERSONAL_LOAN')
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS installment_approved_amount_share,

        SUM(COALESCE(approved_amount, 0)) FILTER (
            WHERE product_type_policy_key = 'MORTGAGE'
        ) / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS mortgage_approved_amount_share,

        /*******************************************************************************************
        Synthetic risk and LGD metrics.
        *******************************************************************************************/
        AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy_all_apps,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_declined_rows,

        AVG(estimated_lgd) AS avg_estimated_lgd_all_apps,

        AVG(estimated_lgd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_estimated_lgd_offer_rows,

        /*******************************************************************************************
        Expected Loss metrics.
        *******************************************************************************************/
        SUM(requested_expected_loss_amount) AS total_requested_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,

        AVG(COALESCE(approved_expected_loss_amount, 0))
            AS avg_approved_expected_loss_all_apps,

        AVG(approved_expected_loss_amount) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_approved_expected_loss_offer_rows,

        SUM(requested_expected_loss_amount)
            / NULLIF(SUM(requested_amount), 0)
            AS requested_expected_loss_rate,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate,

        SUM(COALESCE(approved_amount, 0))
            / NULLIF(SUM(COALESCE(approved_expected_loss_amount, 0)), 0)
            AS approved_amount_per_approved_expected_loss_dollar

    FROM credit_decisioning_sim.strategy_decisions
),

product_summary AS (
    /***********************************************************************************************
    CTE: product_summary

    Purpose:
        Summarize current-run outcome, exposure, and approved Expected Loss metrics by product.

    Downstream use:
        product_json and product_drivers use this CTE to populate executive product-mix evidence and
        top product driver fields.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,

        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS offer_rate,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY product_type_policy_key
),

product_totals AS (
    /***********************************************************************************************
    CTE: product_totals

    Purpose:
        Provide denominators for product-level approved amount share and approved Expected Loss share.

    Boundary:
        These totals are current-run totals only.
    ***********************************************************************************************/
    SELECT
        SUM(total_approved_amount) AS total_approved_amount,
        SUM(total_approved_expected_loss_amount) AS total_approved_expected_loss_amount
    FROM product_summary
),

product_json AS (
    /***********************************************************************************************
    CTE: product_json

    Purpose:
        Store compact product-level mix evidence as JSONB.

    Why JSONB:
        JSONB lets the one-row executive evidence record retain product-level detail without adding
        a wide set of product-specific columns for every product.

    Boundary:
        This is structured evidence, not a reporting mart and not Module 3 economics.
    ***********************************************************************************************/
    SELECT
        jsonb_object_agg(
            ps.product_type_policy_key,
            jsonb_build_object(
                'applications', ps.applications,
                'offer_count', ps.offer_count,
                'offer_rate', ps.offer_rate,
                'total_approved_amount', ps.total_approved_amount,
                'approved_amount_share', ps.total_approved_amount / NULLIF(pt.total_approved_amount, 0)
            )
        ) AS product_approved_amount_mix_jsonb,

        jsonb_object_agg(
            ps.product_type_policy_key,
            jsonb_build_object(
                'total_approved_expected_loss_amount', ps.total_approved_expected_loss_amount,
                'approved_expected_loss_share', ps.total_approved_expected_loss_amount / NULLIF(pt.total_approved_expected_loss_amount, 0),
                'approved_expected_loss_rate', ps.approved_expected_loss_rate
            )
        ) AS product_approved_expected_loss_mix_jsonb,

        jsonb_object_agg(
            ps.product_type_policy_key,
            jsonb_build_object(
                'applications', ps.applications,
                'offer_count', ps.offer_count,
                'offer_rate', ps.offer_rate
            )
        ) AS product_offer_rate_jsonb

    FROM product_summary ps
    CROSS JOIN product_totals pt
),

product_drivers AS (
    /***********************************************************************************************
    CTE: product_drivers

    Purpose:
        Identify compact product-level driver labels for the executive evidence row.

    Driver examples:
        product with largest approved amount;
        product with largest approved Expected Loss;
        product with most counteroffers;
        product with most declines;
        product with highest / lowest simulated offer-exposure rate.

    Interpretation:
        These are driver labels for storytelling and validation review.

        They are not strategy recommendations.
    ***********************************************************************************************/
    SELECT
        (SELECT product_type_policy_key
         FROM product_summary
         ORDER BY total_approved_amount DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS top_approved_amount_product,

        (SELECT total_approved_amount / NULLIF((SELECT total_approved_amount FROM product_totals), 0)
         FROM product_summary
         ORDER BY total_approved_amount DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS top_approved_amount_product_share,

        (SELECT product_type_policy_key
         FROM product_summary
         ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS top_approved_expected_loss_product,

        (SELECT total_approved_expected_loss_amount
                / NULLIF((SELECT total_approved_expected_loss_amount FROM product_totals), 0)
         FROM product_summary
         ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS top_approved_expected_loss_product_share,

        (SELECT product_type_policy_key
         FROM product_summary
         ORDER BY counteroffer_count DESC, product_type_policy_key
         LIMIT 1) AS top_counteroffer_product,

        (SELECT product_type_policy_key
         FROM product_summary
         ORDER BY decline_count DESC, product_type_policy_key
         LIMIT 1) AS top_decline_product,

        (SELECT product_type_policy_key
         FROM product_summary
         ORDER BY offer_rate DESC NULLS LAST, product_type_policy_key
         LIMIT 1) AS highest_offer_rate_product,

        (SELECT product_type_policy_key
         FROM product_summary
         ORDER BY offer_rate ASC NULLS LAST, product_type_policy_key
         LIMIT 1) AS lowest_offer_rate_product
),

score_summary AS (
    /***********************************************************************************************
    CTE: score_summary

    Purpose:
        Summarize current-run outcome, exposure, and approved Expected Loss metrics by score band.

    Downstream use:
        score_drivers uses this CTE to identify score-band driver labels.
    ***********************************************************************************************/
    SELECT
        score_band_policy_key,

        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS offer_rate,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY score_band_policy_key
),

score_drivers AS (
    /***********************************************************************************************
    CTE: score_drivers

    Purpose:
        Identify compact score-band driver labels for executive evidence.

    Interpretation:
        These labels identify concentration and movement by credit-quality segment.
    ***********************************************************************************************/
    SELECT
        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY total_approved_amount DESC NULLS LAST, score_band_policy_key
         LIMIT 1) AS top_approved_amount_score_band,

        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, score_band_policy_key
         LIMIT 1) AS top_approved_expected_loss_score_band,

        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY counteroffer_count DESC, score_band_policy_key
         LIMIT 1) AS top_counteroffer_score_band,

        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY decline_count DESC, score_band_policy_key
         LIMIT 1) AS top_decline_score_band,

        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY offer_rate DESC NULLS LAST, score_band_policy_key
         LIMIT 1) AS highest_offer_rate_score_band,

        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY offer_rate ASC NULLS LAST, score_band_policy_key
         LIMIT 1) AS lowest_offer_rate_score_band,

        (SELECT score_band_policy_key
         FROM score_summary
         ORDER BY approved_expected_loss_rate DESC NULLS LAST, score_band_policy_key
         LIMIT 1) AS highest_approved_el_rate_score_band
),

product_score_summary AS (
    /***********************************************************************************************
    CTE: product_score_summary

    Purpose:
        Summarize current-run driver metrics at the product × score level.

    Why this matters:
        Product-only and score-only summaries can hide concentration at their intersection.

        Product × score drivers are often the strongest executive evidence for strategy movement.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_type_policy_key || ' / ' || score_band_policy_key
            AS product_score_policy_segment,

        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) AS offer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        SUM(COALESCE(approved_amount, 0)) AS total_approved_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            AS total_approved_expected_loss_amount,

        SUM(COALESCE(approved_expected_loss_amount, 0))
            / NULLIF(SUM(COALESCE(approved_amount, 0)), 0)
            AS approved_expected_loss_rate

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY
        product_type_policy_key,
        score_band_policy_key
),

product_score_drivers AS (
    /***********************************************************************************************
    CTE: product_score_drivers

    Purpose:
        Identify compact product × score driver labels for the executive evidence row.

    Interpretation:
        These labels identify the segment intersections most important for approved amount, approved
        Expected Loss, counteroffer concentration, decline concentration, and approved Expected Loss
        rate.
    ***********************************************************************************************/
    SELECT
        (SELECT product_score_policy_segment
         FROM product_score_summary
         ORDER BY total_approved_amount DESC NULLS LAST, product_score_policy_segment
         LIMIT 1) AS top_approved_amount_product_score_segment,

        (SELECT product_score_policy_segment
         FROM product_score_summary
         ORDER BY total_approved_expected_loss_amount DESC NULLS LAST, product_score_policy_segment
         LIMIT 1) AS top_approved_el_product_score_segment,

        (SELECT product_score_policy_segment
         FROM product_score_summary
         ORDER BY counteroffer_count DESC, product_score_policy_segment
         LIMIT 1) AS top_counteroffer_product_score_segment,

        (SELECT product_score_policy_segment
         FROM product_score_summary
         ORDER BY decline_count DESC, product_score_policy_segment
         LIMIT 1) AS top_decline_product_score_segment,

        (SELECT product_score_policy_segment
         FROM product_score_summary
         ORDER BY approved_expected_loss_rate DESC NULLS LAST, product_score_policy_segment
         LIMIT 1) AS highest_approved_el_rate_product_score_segment
),

reason_counts AS (
    /***********************************************************************************************
    CTE: reason_counts

    Purpose:
        Count simulated reason-code distribution at the current run level.

    Why this matters:
        The executive evidence row should explain not only rates and amounts, but the reason-code
        drivers behind strategy outcomes.

    Boundary:
        Reason codes are simulated strategy explanation codes only.
    ***********************************************************************************************/
    SELECT
        decision_outcome,
        primary_reason_family,
        primary_reason_code,

        COUNT(*) AS reason_row_count,

        COUNT(*)::NUMERIC
            / NULLIF(SUM(COUNT(*)) OVER (), 0) AS reason_population_share

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY
        decision_outcome,
        primary_reason_family,
        primary_reason_code
),

reason_drivers AS (
    /***********************************************************************************************
    CTE: reason_drivers

    Purpose:
        Identify compact run-level simulated reason-code driver fields.

    Driver fields:
        top overall reason;
        top non-approval reason;
        top policy-stop reason;
        top counteroffer reason;
        top manual-review reason;
        top decline reason.

    Why this matters:
        top_primary_reason_code may often be APPROVED_AS_REQUESTED.

        Non-approval and outcome-specific reason fields better explain friction, constraints, and
        risk-tightening movement.
    ***********************************************************************************************/
    SELECT
        (SELECT primary_reason_family
         FROM reason_counts
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_primary_reason_family,

        (SELECT primary_reason_code
         FROM reason_counts
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_primary_reason_code,

        (SELECT reason_population_share
         FROM reason_counts
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_primary_reason_population_share,

        (SELECT primary_reason_family
         FROM reason_counts
         WHERE decision_outcome <> 'APPROVE'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_non_approval_primary_reason_family,

        (SELECT primary_reason_code
         FROM reason_counts
         WHERE decision_outcome <> 'APPROVE'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_non_approval_primary_reason_code,

        (SELECT reason_population_share
         FROM reason_counts
         WHERE decision_outcome <> 'APPROVE'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_non_approval_reason_population_share,

        (SELECT primary_reason_family
         FROM reason_counts
         WHERE primary_reason_family = 'POLICY_STOP'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_policy_stop_primary_reason_family,

        (SELECT primary_reason_code
         FROM reason_counts
         WHERE primary_reason_family = 'POLICY_STOP'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_policy_stop_primary_reason_code,

        (SELECT reason_population_share
         FROM reason_counts
         WHERE primary_reason_family = 'POLICY_STOP'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_policy_stop_reason_population_share,

        (SELECT primary_reason_code
         FROM reason_counts
         WHERE decision_outcome = 'COUNTEROFFER'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_counteroffer_reason_code,

        (SELECT primary_reason_code
         FROM reason_counts
         WHERE decision_outcome = 'MANUAL_REVIEW'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_manual_review_reason_code,

        (SELECT primary_reason_code
         FROM reason_counts
         WHERE decision_outcome = 'DECLINE'
         ORDER BY reason_row_count DESC, primary_reason_family, primary_reason_code
         LIMIT 1) AS top_decline_reason_code
),

validation_summary AS (
    /***********************************************************************************************
    CTE: validation_summary

    Purpose:
        Roll Section 14 validation rows into executive evidence fields.

    Outputs:
        validation_pass_count;
        validation_review_count;
        validation_not_applicable_count;
        validation_review_items;
        validation_status_summary_jsonb.

    Interpretation:
        REVIEW rows are documentation prompts, not automatic invalidation.

        NOT_APPLICABLE rows identify tests that were not evaluable under the current run context.

    Boundary:
        This CTE summarizes Section 14 output only.

        It does not rerun validation logic.
    ***********************************************************************************************/
    SELECT
        COUNT(*) FILTER (WHERE validation_status = 'PASS') AS validation_pass_count,

        COUNT(*) FILTER (WHERE validation_status = 'REVIEW') AS validation_review_count,

        COUNT(*) FILTER (WHERE validation_status = 'NOT_APPLICABLE')
            AS validation_not_applicable_count,

        STRING_AGG(
            validation_area || ': ' || validation_test_name || ' [' || validation_status || ']',
            ' | '
            ORDER BY validation_area, validation_test_name
        ) FILTER (WHERE validation_status IN ('REVIEW', 'NOT_APPLICABLE'))
            AS validation_review_items,

        jsonb_agg(
            jsonb_build_object(
                'validation_area', validation_area,
                'validation_test_name', validation_test_name,
                'validation_category', validation_category,
                'validation_status', validation_status,
                'observed_value', observed_value,
                'expected_behavior', expected_behavior,
                'interpretation', interpretation
            )
            ORDER BY validation_area, validation_test_name
        ) AS validation_status_summary_jsonb

    FROM tmp_m2_validation_status_summary
),

frontier AS (
    /***********************************************************************************************
    CTE: frontier

    Purpose:
        Bring in Section 15 executive frontier fields for the current run key.

    Why LEFT JOIN is used later:
        The executive evidence row should still be capturable if the frontier row is unexpectedly
        unavailable, although Section 16.0 normally requires the Section 15 object to exist.

    Boundary:
        This CTE reads frontier evidence only.

        It does not recalculate frontier classification.
    ***********************************************************************************************/
    SELECT
        f.*
    FROM tmp_m2_strategy_frontier_executive_summary f
    JOIN current_key k
        ON f.strategy_set_name = k.strategy_set_name
       AND f.strategy_name = k.strategy_name
       AND f.strategy_version = k.strategy_version
       AND f.module1_scenario_set_name = k.module1_scenario_set_name
       AND f.module1_scenario_name = k.module1_scenario_name
       AND f.population_id = k.population_id
    LIMIT 1
),

baseline_product AS (
    /***********************************************************************************************
    CTE: baseline_product

    Purpose:
        Create product-level baseline reference values from the archive.

    Why baseline comes from archive:
        Baseline-relative deltas should compare current latest-run metrics to the archived baseline
        strategy under the same Module 1 scenario / population and strategy set.

    Boundary:
        This CTE does not require the current run to be a challenger.

        Delta fields are later set to NULL for BASELINE_STRATEGY.
    ***********************************************************************************************/
    SELECT
        ar.product_type_policy_key,
        SUM(COALESCE(ar.approved_amount, 0)) AS baseline_total_approved_amount,
        SUM(COALESCE(ar.approved_expected_loss_amount, 0)) AS baseline_total_approved_el

    FROM credit_decisioning_sim.strategy_decisions_archive ar

    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = 'BASELINE_STRATEGY'
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id

    GROUP BY ar.product_type_policy_key
),

current_product AS (
    /***********************************************************************************************
    CTE: current_product

    Purpose:
        Create product-level current-run values from the latest-run table for baseline-relative
        product deltas.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        SUM(COALESCE(approved_amount, 0)) AS current_total_approved_amount,
        SUM(COALESCE(approved_expected_loss_amount, 0)) AS current_total_approved_el

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY product_type_policy_key
),

product_delta AS (
    /***********************************************************************************************
    CTE: product_delta

    Purpose:
        Compare current product exposure and approved Expected Loss to the archived baseline product
        profile.

    Boundary:
        If no baseline exists, this CTE returns no rows and later driver fields become NULL.
    ***********************************************************************************************/
    SELECT
        cp.product_type_policy_key,

        cp.current_total_approved_amount - bp.baseline_total_approved_amount
            AS delta_total_approved_amount,

        cp.current_total_approved_el - bp.baseline_total_approved_el
            AS delta_total_approved_el

    FROM current_product cp

    JOIN baseline_product bp
        ON bp.product_type_policy_key = cp.product_type_policy_key
),

baseline_score AS (
    /***********************************************************************************************
    CTE: baseline_score

    Purpose:
        Create score-band baseline offer-rate and decline-rate reference values from the archive.
    ***********************************************************************************************/
    SELECT
        ar.score_band_policy_key,

        COUNT(*) FILTER (WHERE ar.simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS baseline_offer_rate,

        COUNT(*) FILTER (WHERE ar.decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS baseline_decline_rate

    FROM credit_decisioning_sim.strategy_decisions_archive ar

    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = 'BASELINE_STRATEGY'
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id

    GROUP BY ar.score_band_policy_key
),

current_score AS (
    /***********************************************************************************************
    CTE: current_score

    Purpose:
        Create current score-band offer-rate and decline-rate values from the latest-run table.
    ***********************************************************************************************/
    SELECT
        score_band_policy_key,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS current_offer_rate,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')::NUMERIC
            / NULLIF(COUNT(*), 0) AS current_decline_rate

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY score_band_policy_key
),

score_delta AS (
    /***********************************************************************************************
    CTE: score_delta

    Purpose:
        Compare current offer and decline rates to baseline by score band.
    ***********************************************************************************************/
    SELECT
        cs.score_band_policy_key,
        cs.current_offer_rate - bs.baseline_offer_rate AS delta_offer_rate,
        cs.current_decline_rate - bs.baseline_decline_rate AS delta_decline_rate

    FROM current_score cs

    JOIN baseline_score bs
        ON bs.score_band_policy_key = cs.score_band_policy_key
),

baseline_product_score AS (
    /***********************************************************************************************
    CTE: baseline_product_score

    Purpose:
        Create product × score baseline approved Expected Loss values from the archive.

    Why this matters:
        Product × score approved Expected Loss deltas are often the clearest way to explain where a
        strategy moved risk.
    ***********************************************************************************************/
    SELECT
        ar.product_type_policy_key,
        ar.score_band_policy_key,
        ar.product_type_policy_key || ' / ' || ar.score_band_policy_key
            AS product_score_policy_segment,

        SUM(COALESCE(ar.approved_expected_loss_amount, 0)) AS baseline_total_approved_el

    FROM credit_decisioning_sim.strategy_decisions_archive ar

    JOIN current_key k
        ON ar.strategy_set_name = k.strategy_set_name
       AND ar.strategy_name = 'BASELINE_STRATEGY'
       AND ar.strategy_version = k.strategy_version
       AND ar.module1_scenario_set_name = k.module1_scenario_set_name
       AND ar.module1_scenario_name = k.module1_scenario_name
       AND ar.population_id = k.population_id

    GROUP BY
        ar.product_type_policy_key,
        ar.score_band_policy_key
),

current_product_score AS (
    /***********************************************************************************************
    CTE: current_product_score

    Purpose:
        Create current product × score approved Expected Loss values from the latest-run table.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        score_band_policy_key,
        product_type_policy_key || ' / ' || score_band_policy_key
            AS product_score_policy_segment,

        SUM(COALESCE(approved_expected_loss_amount, 0)) AS current_total_approved_el

    FROM credit_decisioning_sim.strategy_decisions

    GROUP BY
        product_type_policy_key,
        score_band_policy_key
),

product_score_delta AS (
    /***********************************************************************************************
    CTE: product_score_delta

    Purpose:
        Compare current product × score approved Expected Loss to archived baseline.
    ***********************************************************************************************/
    SELECT
        cps.product_score_policy_segment,

        cps.current_total_approved_el - bps.baseline_total_approved_el
            AS delta_total_approved_el

    FROM current_product_score cps

    JOIN baseline_product_score bps
        ON bps.product_type_policy_key = cps.product_type_policy_key
       AND bps.score_band_policy_key = cps.score_band_policy_key
),

delta_drivers AS (
    /***********************************************************************************************
    CTE: delta_drivers

    Purpose:
        Select the largest baseline-relative movement drivers for executive evidence.

    Why baseline rows return NULL:
        A baseline strategy should not report largest baseline-relative deltas against itself.

    Driver fields:
        largest_delta_approved_amount_product,
        largest_delta_approved_el_product,
        largest_delta_offer_rate_score_band,
        largest_delta_decline_rate_score_band,
        largest_delta_approved_el_product_score_segment.

    Interpretation:
        These fields help explain where strategy movement concentrated.
    ***********************************************************************************************/
    SELECT
        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT product_type_policy_key
                FROM product_delta
                ORDER BY
                    ABS(delta_total_approved_amount) DESC NULLS LAST,
                    product_type_policy_key
                LIMIT 1
            )
        END AS largest_delta_approved_amount_product,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT product_type_policy_key
                FROM product_delta
                ORDER BY
                    ABS(delta_total_approved_el) DESC NULLS LAST,
                    product_type_policy_key
                LIMIT 1
            )
        END AS largest_delta_approved_el_product,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT score_band_policy_key
                FROM score_delta
                ORDER BY
                    ABS(delta_offer_rate) DESC NULLS LAST,
                    score_band_policy_key
                LIMIT 1
            )
        END AS largest_delta_offer_rate_score_band,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT score_band_policy_key
                FROM score_delta
                ORDER BY
                    ABS(delta_decline_rate) DESC NULLS LAST,
                    score_band_policy_key
                LIMIT 1
            )
        END AS largest_delta_decline_rate_score_band,

        CASE
            WHEN (SELECT strategy_name FROM current_key LIMIT 1) = 'BASELINE_STRATEGY'
                THEN NULL
            ELSE (
                SELECT product_score_policy_segment
                FROM product_score_delta
                ORDER BY
                    ABS(delta_total_approved_el) DESC NULLS LAST,
                    product_score_policy_segment
                LIMIT 1
            )
        END AS largest_delta_approved_el_product_score_segment
),

module3_readiness AS (
    /***********************************************************************************************
    CTE: module3_readiness

    Purpose:
        Identify whether the current run has the core fields needed to support future Module 3
        growth / economics logic.

    Availability rule:
        TRUE when at least one simulated offer-exposure row has:
            approved amount,
            APR proxy,
            synthetic estimated-PD proxy,
            LGD,
            and approved Expected Loss.

    Boundary:
        This is readiness evidence only.

        It does not calculate revenue, funding cost, fee income, profitability, capital, pricing
        optimization, or risk-adjusted margin.
    ***********************************************************************************************/
    SELECT
        CASE
            WHEN SUM(COALESCE(approved_amount, 0)) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) > 0
             AND COUNT(*) FILTER (
                    WHERE simulated_offer_exposure_flag IS TRUE
                      AND base_apr_for_payment_calc IS NOT NULL
                      AND approved_amount IS NOT NULL
                      AND estimated_pd IS NOT NULL
                      AND estimated_lgd IS NOT NULL
                      AND approved_expected_loss_amount IS NOT NULL
                 ) > 0
                THEN TRUE
            ELSE FALSE
        END AS module3_growth_inputs_available_flag,

        CASE
            WHEN COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE) = 0
                THEN 'No simulated offer-exposure rows are available for future Module 3 economics.'

            WHEN COUNT(*) FILTER (
                    WHERE simulated_offer_exposure_flag IS TRUE
                      AND base_apr_for_payment_calc IS NULL
                 ) > 0
                THEN 'One or more offer rows are missing APR proxy values.'

            WHEN COUNT(*) FILTER (
                    WHERE simulated_offer_exposure_flag IS TRUE
                      AND approved_amount IS NULL
                 ) > 0
                THEN 'One or more offer rows are missing approved_amount values.'

            ELSE 'Core Module 3 readiness inputs are available: approved amount, APR proxy, product, synthetic estimated-PD proxy, LGD, and approved Expected Loss. Utilization, funding cost, fee income, and revenue assumptions remain future Module 3 design inputs.'
        END AS module3_growth_input_gap_note,

        TRUE AS module3_revenue_model_required_flag,

        'Earnings, revenue, funding cost, profitability, and risk-adjusted margin logic are intentionally deferred to Module 3. Section 16 captures readiness inputs only.'::TEXT
            AS module3_boundary_note

    FROM credit_decisioning_sim.strategy_decisions
)

SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    /***********************************************************************************************
    Evidence snapshot ID.

    This identifies the evidence-capture event.

    It is not the run key and should not replace strategy / scenario / population lineage.
    ***********************************************************************************************/
    MD5(
        k.strategy_set_name || '|'
        || k.strategy_name || '|'
        || k.strategy_version || '|'
        || k.module1_scenario_set_name || '|'
        || k.module1_scenario_name || '|'
        || k.population_id || '|'
        || CURRENT_TIMESTAMP::TEXT
    ) AS evidence_snapshot_id,

    /***********************************************************************************************
    Campaign registry / run-story fields.

    These are the primary documentation-linkage fields for run roadmap, Validation Summary, README,
    LinkedIn, and comparison traceability.
    ***********************************************************************************************/
    story.campaign_registry_required_flag,
    story.registry_match_count,
    story.run_registry_match_status,

    story.module1_run_id,
    story.module2_run_id,
    story.run_sequence_number,

    story.showcase_id,
    story.showcase_name,
    story.comparison_group_id,
    story.validation_evidence_group_id,

    story.readme_storyline_label,
    story.linkedin_post_sequence,
    story.validation_summary_section_hint,

    story.module1_parameter_family_changed,
    story.module1_parameter_change_summary,
    story.module2_strategy_family_changed,
    story.module2_parameter_change_summary,
    story.expected_storyline,
    COALESCE(story.observed_storyline, f.frontier_interpretation_note) AS observed_storyline,
    story.validation_notes,

    /***********************************************************************************************
    Module 2 strategy identity.
    ***********************************************************************************************/
    k.module2_model_version,
    k.strategy_set_name,
    k.strategy_name,
    k.strategy_version,
    k.strategy_run_id,
    k.strategy_run_ts,

    /***********************************************************************************************
    Output and archive timestamps.
    ***********************************************************************************************/
    k.latest_output_created_ts,
    ats.archive_inserted_ts,

    /***********************************************************************************************
    Archive and resolution controls.
    ***********************************************************************************************/
    k.archive_run_flag,
    k.strategy_archive_reset_mode,
    k.failed_counteroffer_resolution,

    /***********************************************************************************************
    Module 1 source and lineage.
    ***********************************************************************************************/
    k.module1_input_source,
    k.module1_source_table_name,

    k.module1_model_version,
    k.module1_scenario_set_name,
    k.module1_scenario_name,
    k.population_id,
    k.anchor_date,

    /***********************************************************************************************
    Structural counts.
    ***********************************************************************************************/
    p.applications,
    p.distinct_application_id_count,
    p.duplicate_application_count,

    /***********************************************************************************************
    Final outcome counts.
    ***********************************************************************************************/
    p.approval_count,
    p.counteroffer_count,
    p.manual_review_count,
    p.decline_count,
    p.offer_count,

    /***********************************************************************************************
    Final outcome rates.
    ***********************************************************************************************/
    p.approval_rate,
    p.counteroffer_rate,
    p.manual_review_rate,
    p.decline_rate,
    p.simulated_offer_exposure_rate,
    p.approval_share_of_offers,
    p.counteroffer_share_of_offers,

    /***********************************************************************************************
    Exposure metrics.
    ***********************************************************************************************/
    p.total_requested_amount,
    p.total_approved_amount,
    p.approved_amount_capture_rate,

    p.avg_requested_amount,
    p.avg_approved_amount_all_apps,
    p.avg_approved_amount_offer_rows,

    p.total_exposure_reduction_amount,

    p.counteroffer_requested_amount,
    p.counteroffer_approved_amount,
    p.counteroffer_exposure_reduction_amount,
    p.counteroffer_exposure_reduction_pct_avg,

    p.manual_review_requested_amount,
    p.manual_review_requested_expected_loss_amount,
    p.decline_requested_amount,
    p.decline_requested_expected_loss_amount,

    /***********************************************************************************************
    Affordability metrics.
    ***********************************************************************************************/
    p.avg_requested_payment_to_income_ratio,
    p.avg_approved_payment_to_income_ratio_offer_rows,

    /***********************************************************************************************
    APR proxy and term metrics for Module 3 readiness.
    ***********************************************************************************************/
    p.avg_apr_proxy_all_apps,
    p.avg_apr_proxy_offer_rows,
    p.requested_amount_weighted_apr_proxy,
    p.approved_amount_weighted_apr_proxy,
    p.requested_amount_x_apr_proxy_sum,
    p.approved_amount_x_apr_proxy_sum,

    p.avg_loan_term_months_offer_rows,
    p.approved_amount_weighted_term_months,
    p.term_missing_or_revolving_count,

    /***********************************************************************************************
    Product approved-exposure composition.
    ***********************************************************************************************/
    p.secured_approved_amount_share,
    p.unsecured_approved_amount_share,
    p.revolving_approved_amount_share,
    p.installment_approved_amount_share,
    p.mortgage_approved_amount_share,

    pj.product_approved_amount_mix_jsonb,
    pj.product_approved_expected_loss_mix_jsonb,
    pj.product_offer_rate_jsonb,

    /***********************************************************************************************
    Synthetic risk and LGD metrics.
    ***********************************************************************************************/
    p.avg_synthetic_estimated_pd_proxy_all_apps,
    p.avg_synthetic_estimated_pd_proxy_offer_rows,
    p.avg_synthetic_estimated_pd_proxy_declined_rows,

    p.avg_estimated_lgd_all_apps,
    p.avg_estimated_lgd_offer_rows,

    /***********************************************************************************************
    Expected Loss metrics.
    ***********************************************************************************************/
    p.total_requested_expected_loss_amount,
    p.total_approved_expected_loss_amount,
    p.avg_requested_expected_loss_amount,
    p.avg_approved_expected_loss_all_apps,
    p.avg_approved_expected_loss_offer_rows,

    p.requested_expected_loss_rate,
    p.approved_expected_loss_rate,
    p.approved_amount_per_approved_expected_loss_dollar,

    /***********************************************************************************************
    Top simulated reason-code fields.

    Prefer Section 15 frontier reason fields when available because they may include archive-backed
    frontier context.

    Fall back to current-run reason_drivers when frontier context is NULL.
    ***********************************************************************************************/
    COALESCE(f.top_primary_reason_family, rd.top_primary_reason_family),
    COALESCE(f.top_primary_reason_code, rd.top_primary_reason_code),
    COALESCE(f.top_primary_reason_population_share, rd.top_primary_reason_population_share),

    COALESCE(f.top_non_approval_primary_reason_family, rd.top_non_approval_primary_reason_family),
    COALESCE(f.top_non_approval_primary_reason_code, rd.top_non_approval_primary_reason_code),
    COALESCE(f.top_non_approval_reason_population_share, rd.top_non_approval_reason_population_share),

    COALESCE(f.top_policy_stop_primary_reason_family, rd.top_policy_stop_primary_reason_family),
    COALESCE(f.top_policy_stop_primary_reason_code, rd.top_policy_stop_primary_reason_code),
    COALESCE(f.top_policy_stop_reason_population_share, rd.top_policy_stop_reason_population_share),

    /***********************************************************************************************
    Baseline-relative reason-code movement fields from Section 15.
    ***********************************************************************************************/
    f.top_reason_code_delta_driver_family,
    f.top_reason_code_delta_driver_code,
    f.top_reason_code_delta_driver_baseline_share,
    f.top_reason_code_delta_driver_strategy_share,
    f.top_reason_code_delta_population_share,

    /***********************************************************************************************
    Outcome-specific reason-code highlights.
    ***********************************************************************************************/
    rd.top_counteroffer_reason_code,
    rd.top_manual_review_reason_code,
    rd.top_decline_reason_code,

    /***********************************************************************************************
    Frontier posture fields.
    ***********************************************************************************************/
    f.frontier_position_type,
    f.executive_frontier_quadrant,
    f.frontier_interpretation_note,

    /***********************************************************************************************
    Validation summary fields.
    ***********************************************************************************************/
    vs.validation_pass_count,
    vs.validation_review_count,
    vs.validation_not_applicable_count,
    vs.validation_review_items,
    vs.validation_status_summary_jsonb,

    /***********************************************************************************************
    Product driver fields.
    ***********************************************************************************************/
    pd.top_approved_amount_product,
    pd.top_approved_amount_product_share,
    pd.top_approved_expected_loss_product,
    pd.top_approved_expected_loss_product_share,
    pd.top_counteroffer_product,
    pd.top_decline_product,
    pd.highest_offer_rate_product,
    pd.lowest_offer_rate_product,

    /***********************************************************************************************
    Score-band driver fields.
    ***********************************************************************************************/
    sd.top_approved_amount_score_band,
    sd.top_approved_expected_loss_score_band,
    sd.top_counteroffer_score_band,
    sd.top_decline_score_band,
    sd.highest_offer_rate_score_band,
    sd.lowest_offer_rate_score_band,
    sd.highest_approved_el_rate_score_band,

    /***********************************************************************************************
    Product × score driver fields.
    ***********************************************************************************************/
    psd.top_approved_amount_product_score_segment,
    psd.top_approved_el_product_score_segment,
    psd.top_counteroffer_product_score_segment,
    psd.top_decline_product_score_segment,
    psd.highest_approved_el_rate_product_score_segment,

    /***********************************************************************************************
    Baseline-relative driver fields.
    ***********************************************************************************************/
    dd.largest_delta_approved_amount_product,
    dd.largest_delta_approved_el_product,
    dd.largest_delta_offer_rate_score_band,
    dd.largest_delta_decline_rate_score_band,
    dd.largest_delta_approved_el_product_score_segment,

    /***********************************************************************************************
    Module 3 readiness fields.
    ***********************************************************************************************/
    mr.module3_growth_inputs_available_flag,
    mr.module3_growth_input_gap_note,
    mr.module3_revenue_model_required_flag,
    mr.module3_boundary_note

FROM current_key k

/***************************************************************************************************
The following CROSS JOINs are intentional.

Each CTE is expected to return one row after Section 16.0 gatekeepers and Section 14 / Section 15
dependencies are satisfied.

Together, they assemble one executive evidence row for the current run.
***************************************************************************************************/
CROSS JOIN story
CROSS JOIN archive_ts ats
CROSS JOIN portfolio p
CROSS JOIN product_json pj
CROSS JOIN product_drivers pd
CROSS JOIN score_drivers sd
CROSS JOIN product_score_drivers psd
CROSS JOIN reason_drivers rd
CROSS JOIN validation_summary vs
CROSS JOIN delta_drivers dd
CROSS JOIN module3_readiness mr

/***************************************************************************************************
LEFT JOIN frontier:

The frontier table should contain a matching current-run row after Section 15.

LEFT JOIN keeps evidence capture structurally tolerant if the frontier match is absent, while still
allowing run-level evidence to be inserted with NULL frontier fields.

Section 16.0 already requires tmp_m2_strategy_frontier_executive_summary to exist.
***************************************************************************************************/
LEFT JOIN frontier f
    ON TRUE;



/***************************************************************************************************
END OF SECTION 16.6 — CURRENT RUN EXECUTIVE EVIDENCE SUMMARY

If execution reaches this point:
    1. Product × score segment evidence has been persisted for the current run with registry IDs.
    2. One executive evidence summary row has been inserted for the current run key with registry IDs.
    3. Current run story metadata has been captured.
    4. Current run decision outcomes have been summarized.
    5. Current run simulated offer-exposure metrics have been captured.
    6. Requested exposure, approved exposure, and exposure capture metrics have been captured.
    7. Requested Expected Loss, approved Expected Loss, and approved Expected Loss rate have been
       captured.
    8. Synthetic estimated-PD proxy and LGD evidence has been captured.
    9. APR proxy and term fields have been captured for future Module 3 readiness.
    10. Product, score-band, and product × score driver fields have been captured.
    11. Simulated reason-code story fields have been captured.
    12. Section 14 validation status counts and JSONB detail have been captured.
    13. Section 15 frontier posture fields have been captured when the current run has a matching
        frontier row.
    14. Baseline-relative segment movement driver fields have been captured when a baseline reference
        exists.
    15. Module 3 readiness flags and boundary notes have been captured.
    16. Evidence rows now carry module1_run_id, module2_run_id, showcase_id, comparison_group_id,
        validation_evidence_group_id, README label, LinkedIn sequence, and registry match status.

No latest-run output rows have been modified.
No archive rows have been modified.
No strategy parameter rows have been modified.
No product policy parameter rows have been modified.
No decision outcomes have been recalculated.
No approved exposure values have been recalculated.
No approved Expected Loss values have been recalculated.
No simulated reason codes have been reassigned.
No campaign registry rows have been modified.
No revenue, earnings, funding-cost, pricing, profitability, capital, or risk-adjusted margin logic has
been built.

Next section:
    Section 16.7 should validate that evidence capture produced the expected persistent evidence rows
    for the current run key.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M01046 -->


---

<a id="c038-m01047"></a>

### C038-M01047

**Andrew** · 2026-05-10T11:22:01.127000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M01047 -->
please don't give me a download and keep this elite level! let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 16.4-16.5 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M01047 -->


**Attachments in export:** `Pasted text(164).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_58.md) · [Next](Part_60.md)
