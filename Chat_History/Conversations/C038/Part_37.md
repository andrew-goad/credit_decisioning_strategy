# Module 2 Decision Simulator Build

## Part 37

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_36.md) · [Next](Part_38.md)

<a id="c038-m00868"></a>

### C038-M00868

**ChatGPT** · 2026-05-09T20:15:15.093204-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00868 -->
Below is the patched **Sections 16.5 and 16.6** full copy-paste replacement. This installs the registry-consumption patch so the same registry fields captured in Sections 16.0–16.4 are now also carried into **segment evidence** and the **one-row executive evidence summary**. I used your provided Section 16.5–16.6 chunk as the base. fileciteturn77file5

```sql
/***************************************************************************************************
SECTION 16.5 — CAPTURE CURRENT RUN SEGMENT EVIDENCE SUMMARY
****************************************************************************************************

BUSINESS PURPOSE:
    Persist product × score-band evidence for the current completed Module 2 strategy run.

    Section 16.5 answers:

        "Which product × score-band segments drove the current run’s access, exposure, approved
         Expected Loss, affordability, synthetic estimated-risk profile, and simulated reason-code
         story?"

SQL PURPOSE:
    1. Read the current latest-run output from credit_decisioning_sim.strategy_decisions.
    2. Read current registry / story metadata from tmp_m2_current_run_story_params.
    3. Group current-run evidence by product_type_policy_key × score_band_policy_key ×
       product_score_policy_segment.
    4. Calculate segment-level decision counts and rates.
    5. Calculate segment-level requested amount, approved amount, and approved amount capture rate.
    6. Calculate segment-level APR proxy and term fields useful for future Module 3 design.
    7. Calculate segment-level synthetic estimated-risk proxy, LGD, requested Expected Loss, approved
       Expected Loss, and approved Expected Loss rate.
    8. Calculate segment-level requested PTI and approved PTI.
    9. Identify the top primary simulated reason code in each product × score segment.
    10. Identify the top non-approval simulated reason code in each product × score segment.
    11. Insert segment evidence into:
            credit_decisioning_sim.strategy_run_segment_evidence_summary

REGISTRY PATCH:
    Section 16.5 now carries formal campaign registry fields into every segment evidence row:

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

    This allows product × score evidence to be referenced directly in the future Validation Summary,
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

WHY THIS TABLE IS PERSISTENT:
    Section 14 QA and Section 15 frontier outputs are temporary.

    Section 16 evidence tables preserve the key results across the full scenario / strategy campaign.

    This avoids having to manually recover product × score evidence from many QA grids after each run.

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

READ-ONLY / PERSISTENCE BOUNDARY:
    Section 16.5 inserts evidence rows into a persistent evidence table.

    It does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive
        strategy parameters
        product policy parameters
        decision outcomes
        approved exposure values
        approved Expected Loss values
        simulated reason codes

***************************************************************************************************/

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
        Segment evidence should carry the same campaign IDs as the executive evidence row and
        validation evidence rows.

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

    Why this CTE exists:
        This is the metric foundation for the persistent segment evidence table.

    Metric conventions:
        all-app approved metrics:
            use COALESCE(approved_amount, 0) and COALESCE(approved_expected_loss_amount, 0)

        offer-row metrics:
            use FILTER (WHERE simulated_offer_exposure_flag IS TRUE)

        approved_expected_loss_rate:
            total approved Expected Loss / total approved amount

        approved_amount_capture_rate:
            total approved amount / total requested amount

    Boundary:
        This CTE summarizes existing output only.
        It does not recalculate decisions, approved exposure, or approved Expected Loss.
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
        *******************************************************************************************/
        product_type_policy_key,
        score_band_policy_key,
        product_score_policy_segment,

        /*******************************************************************************************
        Segment size.
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

        NULLIF protects against divide-by-zero if a segment is unexpectedly empty.
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
        It is not a pricing optimization result.
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

        approved_payment_to_income_ratio exists only for simulated positive offer-exposure rows.
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

    Ordering:
        highest count first;
        then deterministic tie-break by reason family and reason code.
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
    Section 16.6 now persists formal campaign registry fields in the one-row executive evidence
    summary:

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

READ-ONLY / PERSISTENCE BOUNDARY:
    Section 16.6 inserts one evidence row.

    It does not modify latest-run rows.
    It does not modify archive rows.
    It does not recalculate decisions.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.
    It does not reassign simulated reason codes.
    It does not modify strategy or product-policy parameters.

***************************************************************************************************/

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
        Decline requested values show the no-offer population’s requested exposure and requested
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
        These labels identify the segment intersections most important for approved amount,
        approved Expected Loss, counteroffer concentration, decline concentration, and approved
        Expected Loss rate.
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
        COUNT(*) FILTER (WHERE validation_status = 'NOT_APPLICABLE') AS validation_not_applicable_count,

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
        This CTE reads frontier evidence only. It does not recalculate frontier classification.
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
        This CTE does not require the current run to be a challenger. Delta fields are later set to
        NULL for BASELINE_STRATEGY.
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

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00868 -->


---

<a id="c038-m00869"></a>

### C038-M00869

**Andrew** · 2026-05-09T20:17:14.806000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00869 -->
let's patch section 16.7 and 16.8.  please give me the updated full copy paste with the patch installed:
<!-- END_MESSAGE C038-M00869 -->


**Attachments in export:** `Pasted text(137).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_36.md) · [Next](Part_38.md)
