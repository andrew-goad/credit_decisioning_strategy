# Module 2 Decision Simulator Build

## Part 40

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_39.md) · [Next](Part_41.md)

<a id="c038-m00896"></a>

### C038-M00896

**ChatGPT** · 2026-05-09T22:43:15.230282-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00896 -->
Below is the updated **Section 2** full copy-paste replacement with a stronger instructional layer across the header comments and inline SQL commentary. I preserved the functional logic from your current Section 2 while improving the “how to use / how to interpret / how the SQL works” teaching layer. fileciteturn80file0

```sql
/***************************************************************************************************
SECTION 2 — STRATEGY PARAMETER, PRODUCT POLICY, AND CAMPAIGN REGISTRY FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize the governed configuration layer for Module 2.

    Section 2 answers:

        "What assumptions, thresholds, product-policy controls, source-selection settings, archive
         controls, strategy identifiers, and campaign IDs should this Module 2 run use?"

    In practical credit strategy terms, this section is the strategy-control room.

    Later sections use these parameters to decide:
        which Module 1 population to consume,
        what synthetic-risk thresholds to apply,
        which product-specific affordability limits apply,
        whether counteroffer treatment is allowed,
        how approved exposure should be constrained,
        how failed counteroffers should resolve,
        whether completed output should be archived,
        and how the run should be tied to the formal validation / executive story campaign.

SQL PURPOSE:
    1. Create tmp_module2_strategy_params with exactly one active strategy row.
    2. Create tmp_module2_product_policy_params with exactly one row per supported product.
    3. Store strategy defaults as governed simulation parameters.
    4. Avoid hidden hardcoded thresholds in downstream decision logic.
    5. Create persistent campaign registry tables that map technical scenario / strategy identifiers
       to human-readable run IDs and validation-story groupings.
    6. Create persistent comparison registry tables that support governed baseline / challenger
       strategy comparison by comparison_group_id.
    7. Seed the planned Module 2 campaign roadmap so later validation evidence can tie SQL outputs
       back to stable run IDs.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm the active strategy, risk appetite posture, affordability posture, product guardrails,
        counteroffer controls, and archive settings.

    Model / validation reviewers:
        Confirm that assumptions are explicit, bounded, documented, and traceable.

    SQL reviewers:
        Confirm that downstream logic is parameterized and that persistent registry tables are
        created without modifying latest-run or archive outputs.

    Portfolio / executive reviewers:
        Confirm that campaign IDs and storyline labels support a clean evidence trail from SQL output
        to future README, LinkedIn, executive summary, and Validation Summary artifacts.

WHEN TO RUN THIS SECTION:
    Run Section 2 after Section 1 during a full Module 2 execution.

    Section 2 should be run before:
        Section 3 fail-fast gatekeepers,
        Section 4 Module 1 source selection,
        Section 5 segmentation,
        and all downstream strategy logic.

    Do not assume old temporary parameter tables from a prior session are still valid.

HOW TO MODIFY THIS SECTION FOR A NEW RUN:
    For a new Module 2 strategy run, edit the active strategy row in Section 2.2 first.

    The most common fields to update are:
        strategy_name,
        strategy_run_id,
        module1_input_source,
        source_module1_scenario_set_name,
        source_module1_scenario_name,
        source_population_id,
        synthetic estimated-risk thresholds,
        PTI thresholds,
        DTI thresholds,
        archive_run_flag,
        strategy_archive_reset_mode,
        campaign_registry_required_flag.

    For product-level strategy changes, edit Section 2.4 product policy defaults.

    For run-roadmap / documentation changes, edit Section 2.6 campaign registry rows.

    For Section 13 matched comparison changes, edit Section 2.8 comparison registry rows and the
    active_comparison_flag.

PARAMETER GOVERNANCE PRINCIPLE:
    Downstream CASE logic should consume strategy and product parameters rather than silently
    embedding ungoverned thresholds.

    Users should tune Module 2 first through:
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

    before rewriting downstream decision, routing, exposure, or reason-code logic.

    This is a core governance principle:
        strategy behavior should be visible in a parameter card before it appears in decision logic.

CREDIT RISK CONCEPTS TAUGHT BY THIS SECTION:
    Synthetic estimated-risk thresholds:
        Represent strategy tolerance for the Module 1 estimated_pd field, interpreted as a synthetic
        estimated-PD proxy.

    PTI thresholds:
        Represent payment burden tolerance. PTI is a borrower affordability concept:
            payment obligation / monthly income.

    DTI thresholds:
        Represent existing obligation capacity. In Module 2 V1.0, DTI is not directly corrected by
        reducing requested exposure.

    Requested Expected Loss thresholds:
        Control risk sensitivity using requested-exposure Expected Loss from Module 1.

    Approved Expected Loss caps:
        Control post-treatment approved-exposure economics after Module 2 exposure reduction.

    Counteroffer controls:
        Determine when reduced-exposure treatment is allowed and how conservative that treatment
        must be.

    Archive controls:
        Determine whether the latest-run output becomes governed historical evidence.

    Campaign registry IDs:
        Determine how technical SQL outputs connect to executive and validation documentation.

CAMPAIGN REGISTRY GOVERNANCE PRINCIPLE:
    Module 1 scenario lineage and Module 2 strategy metadata remain the technical source of truth.

    Campaign IDs such as:
        module1_run_id
        module2_run_id
        showcase_id
        comparison_group_id
        validation_evidence_group_id

    are documentation and evidence-linkage metadata.

    They do not replace:
        module1_scenario_set_name
        module1_scenario_name
        population_id
        strategy_set_name
        strategy_name
        strategy_version
        application_id

    They help connect:
        run roadmap
        → SQL output
        → archive slice
        → comparison result
        → executive evidence row
        → validation evidence row
        → parameter snapshot
        → future Validation Summary claim.

SQL DESIGN PRINCIPLE:
    Section 2 uses a mix of temporary and persistent objects.

    Temporary objects:
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

        These exist for the current execution session and drive the current run.

    Persistent registry objects:
        credit_decisioning_sim.strategy_run_campaign_registry
        credit_decisioning_sim.strategy_comparison_campaign_registry

        These persist across runs and provide the governed run roadmap.

    This separation matters:
        parameters drive the current execution;
        registries organize the campaign evidence across executions.

DEFAULT THRESHOLD INTERPRETATION:
    Defaults in this section are initial synthetic strategy defaults.

    They are:
        intended for strategy simulation,
        expected to be reviewed through QA and strategy tuning,
        not production underwriting policy,
        not empirical calibration,
        not a calibrated default model,
        not regulatory policy,
        not real customer treatment logic.

OPERATING GUIDANCE:
    For a formal campaign run:
        1. Confirm the Module 1 source scenario fields.
        2. Confirm the Module 2 strategy identity.
        3. Confirm the current strategy exists in credit_decisioning_sim.strategy_run_campaign_registry.
        4. Confirm any intended Section 13 comparison exists in
           credit_decisioning_sim.strategy_comparison_campaign_registry.
        5. Keep campaign_registry_required_flag = TRUE.
        6. Run Section 3 gatekeepers before building downstream strategy logic.

    For ad hoc development:
        campaign_registry_required_flag may be set to FALSE, but formal validation evidence should
        use registry-matched runs.

INTERPRETATION BOUNDARY:
    Section 2 defines the active strategy posture and campaign roadmap.

    It does not prove the strategy behaved as expected.

    Evidence of actual behavior comes later from:
        Section 11 latest-run output,
        Section 12 archive persistence,
        Section 13 matched comparison,
        Section 14 QA,
        Section 15 strategy frontier,
        Section 16 evidence capture.

BOUNDARY:
    Section 2 defines governed controls and campaign metadata.
    Section 2 does not consume Module 1 rows.
    Section 2 does not create decision outcomes.
    Section 2 does not assign reason codes.
    Section 2 does not calculate approved exposure.
    Section 2 does not calculate approved Expected Loss.
    Section 2 does not insert archive rows.
    Section 2 does not perform matched comparison.
    Section 2 does not perform QA validation.
    Section 2 does not draft written validation conclusions.

COMMON MISUSE TO AVOID:
    Do not treat strategy_run_id as the archive replacement key.
    Do not treat campaign IDs as replacements for technical SQL lineage.
    Do not interpret synthetic estimated-risk thresholds as calibrated production PD cutoffs.
    Do not interpret product-policy values as approved production underwriting limits.
    Do not rewrite downstream CASE logic when a parameter change would answer the business question.
    Do not use formal validation evidence without registry-matched campaign IDs.

***************************************************************************************************/



/***************************************************************************************************
SECTION 2.1 — STRATEGY PARAMETER TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Define the single active Module 2 strategy configuration for the current run.

    This table is the active strategy card.

    It identifies:
        the Module 2 strategy,
        the Module 1 source slice,
        the archive behavior,
        the synthetic-risk appetite,
        the affordability appetite,
        the DTI capacity posture,
        diagnostic buffers,
        policy-stop trigger controls,
        reason-code conventions,
        exposure conventions,
        and the registry requirement for formal evidence capture.

SQL PURPOSE:
    Create a temporary parameter table containing strategy identity, source selection, archive
    controls, thresholds, rule controls, decision conventions, and registry requirements.

WHY THIS TABLE EXISTS:
    Module 2 should be strategy-parameterized rather than hard-coded.

    The same downstream SQL pipeline can simulate different strategies by changing this parameter row
    and the product-policy parameter rows.

CARDINALITY REQUIREMENT:
    Exactly one row should have:
        active_strategy_flag = TRUE

    Section 3 enforces this.

SQL MECHANICS:
    CREATE TEMP TABLE creates a session-scoped table.

    ON COMMIT PRESERVE ROWS keeps the temporary parameter row available across transaction
    boundaries during the same session.

    This is important because the downstream staged SQL blocks read this table repeatedly.

    Section 1 drops this table at the beginning of a clean full run so stale strategy parameters
    cannot leak into the next execution.

CREDIT RISK TEACHING POINT:
    Credit strategy configuration is not just a list of cutoffs.

    A strategy card combines multiple governance dimensions:
        risk appetite,
        affordability appetite,
        DTI capacity,
        product controls,
        archive controls,
        evidence traceability,
        and final output conventions.

****************************************************************************************************/

CREATE TEMP TABLE tmp_module2_strategy_params (
    /***********************************************************************************************
    Active strategy cardinality.

    active_strategy_flag identifies the one strategy row used by the current run.

    Section 3 fails if:
        zero rows are active,
        or more than one row is active.

    This prevents ambiguous strategy execution.
    ***********************************************************************************************/
    active_strategy_flag                         BOOLEAN,


    /***********************************************************************************************
    Strategy identity.

    These fields identify the downstream Module 2 strategy.

    They should not be confused with Module 1 scenario fields.

    module2_model_version:
        version of the Module 2 engine.

    strategy_set_name:
        strategy family / campaign grouping.

    strategy_name:
        specific strategy posture, such as BASELINE_STRATEGY or TIGHTER_SYNTHETIC_RISK_STRATEGY.

    strategy_version:
        version of the strategy definition.

    strategy_run_id and strategy_run_ts:
        audit metadata for traceability.

        These are not archive replacement keys and not matched-comparison keys.
    ***********************************************************************************************/
    module2_model_version                        TEXT,
    strategy_set_name                            TEXT,
    strategy_name                                TEXT,
    strategy_version                             TEXT,
    strategy_run_id                              TEXT,
    strategy_run_ts                              TIMESTAMP,


    /***********************************************************************************************
    Formal campaign registry control.

    campaign_registry_required_flag:
        TRUE means the current technical run key should match exactly one active row in
        credit_decisioning_sim.strategy_run_campaign_registry.

        FALSE allows ad hoc development runs to proceed with fallback evidence metadata.

    This flag does not affect decision logic.
    It only governs evidence traceability expectations.

    Interpretation:
        TRUE is appropriate for formal campaign runs.
        FALSE may be useful during exploratory development, but should not be used for final
        validation-summary evidence unless intentionally documented.
    ***********************************************************************************************/
    campaign_registry_required_flag              BOOLEAN,


    /***********************************************************************************************
    Module 1 source selection.

    module1_input_source:
        LATEST or ARCHIVE.

    source_module1_scenario_set_name:
        required when ARCHIVE is selected.

    source_module1_scenario_name:
        required when ARCHIVE is selected.

    source_population_id:
        required when ARCHIVE is selected.

    Credit risk interpretation:
        These fields decide which upstream synthetic population and risk environment Module 2 will
        consume.

    SQL interpretation:
        Section 4 reads these values to decide which Module 1 table and scenario slice to select.
    ***********************************************************************************************/
    module1_input_source                         TEXT,
    source_module1_scenario_set_name             TEXT,
    source_module1_scenario_name                 TEXT,
    source_population_id                         TEXT,


    /***********************************************************************************************
    Archive controls.

    archive_run_flag:
        TRUE means Section 12 may persist the latest-run output to archive.

        FALSE means Section 12 should skip archive insertion.

    strategy_archive_reset_mode:
        governs what existing archive rows are deleted before inserting the current run, if any.

    These controls do not affect decision outcomes.
    They govern historical persistence.
    ***********************************************************************************************/
    archive_run_flag                             BOOLEAN,
    strategy_archive_reset_mode                  TEXT,


    /***********************************************************************************************
    Global synthetic estimated-risk thresholds.

    estimated_pd is the finalized Module 1 SQL field name.

    These thresholds interpret estimated_pd as the synthetic estimated-PD proxy.

    Credit risk interpretation:
        Lower estimated_pd indicates lower synthetic estimated risk.
        Higher estimated_pd indicates higher synthetic estimated risk.

    Strategy interpretation:
        These thresholds define the global synthetic-risk tolerance posture before product-specific
        exposure treatment is applied downstream.
    ***********************************************************************************************/
    approve_max_estimated_pd_proxy               NUMERIC(12,6),
    counteroffer_max_estimated_pd_proxy          NUMERIC(12,6),
    review_max_estimated_pd_proxy                NUMERIC(12,6),
    decline_min_estimated_pd_proxy               NUMERIC(12,6),


    /***********************************************************************************************
    Global PTI thresholds.

    PTI means payment-to-income ratio.

    Product-specific PTI thresholds drive product PTI segmentation and rules.

    These global values provide high-level consistency controls and fallback context.

    Credit risk interpretation:
        PTI is the affordability bridge from product structure to repayment stress.
    ***********************************************************************************************/
    global_approve_max_pti                       NUMERIC(12,6),
    global_review_max_pti                        NUMERIC(12,6),
    global_decline_min_pti                       NUMERIC(12,6),


    /***********************************************************************************************
    DTI thresholds.

    DTI is debt-to-income ratio.

    DTI reflects existing obligation capacity rather than the requested loan payment alone.

    In Module 2 V1.0, DTI is not directly corrected through counteroffer exposure reduction.

    This means a high-DTI row may still route to review or decline even if requested exposure could
    be reduced.
    ***********************************************************************************************/
    approve_max_dti                              NUMERIC(12,6),
    review_max_dti                               NUMERIC(12,6),
    decline_min_dti                              NUMERIC(12,6),


    /***********************************************************************************************
    Diagnostic segmentation controls.

    borderline_threshold_buffer_pct:
        Governs how close a value must be to a strategy threshold to be tagged as borderline.

        Example:
            0.050000 means "within 5% of the threshold value."

        This is not a production policy tolerance.
        This is a diagnostic segmentation buffer used only to identify threshold-adjacent synthetic
        profiles before decision rules are applied.

    SQL interpretation:
        Section 5 uses this parameter when creating borderline_profile_flag.
    ***********************************************************************************************/
    borderline_threshold_buffer_pct              NUMERIC(12,6),


    /***********************************************************************************************
    Rule-control parameters for Section 6 trigger construction.

    These parameters control simulated trigger flags only.

    They do not assign final decision_outcome.
    They do not create reason codes.
    They do not represent production underwriting policy.

    Section 6 uses them to answer:
        "Which simulated policy conditions are triggered?"

    Later sections answer:
        "Which preliminary route is selected?"
        "Is reduced-exposure treatment feasible?"
        "Which final simulated outcome is assigned?"
        "Which simulated reason codes explain that outcome?"
    ***********************************************************************************************/
    bankruptcy_policy_stop_enabled               BOOLEAN,
    major_derogatory_policy_stop_enabled         BOOLEAN,
    severe_delinquency_policy_stop_enabled       BOOLEAN,
    severe_delinquency_count_threshold           INTEGER,
    high_utilization_review_enabled              BOOLEAN,
    high_utilization_review_threshold            NUMERIC(12,6),
    low_score_review_enabled                     BOOLEAN,
    low_score_review_threshold                   INTEGER,


    /***********************************************************************************************
    Decision convention controls.

    approve_reason_code:
        default simulated primary reason code for clean approvals.

    reason_code_required_flag:
        tells downstream QA that every final row should receive reason-code evidence.

    simulated_offer_exposure_flag_enabled:
        enables the positive-offer exposure convention for APPROVE and COUNTEROFFER rows.

    manual_review_approved_amount_convention:
        expected convention for unresolved manual-review approved exposure.

    decline_approved_amount_convention:
        expected convention for no-offer declined exposure.

    approved_el_decline_convention:
        expected convention for approved Expected Loss on declined rows.

    approved_el_manual_review_convention:
        expected convention for approved Expected Loss on unresolved manual-review rows.

    allow_approved_amount_above_requested_flag:
        protects against approved exposure exceeding requested exposure.
    ***********************************************************************************************/
    approve_reason_code                          TEXT,
    reason_code_required_flag                    BOOLEAN,
    simulated_offer_exposure_flag_enabled        BOOLEAN,
    manual_review_approved_amount_convention     TEXT,
    decline_approved_amount_convention           TEXT,
    approved_el_decline_convention               TEXT,
    approved_el_manual_review_convention         TEXT,
    allow_approved_amount_above_requested_flag   BOOLEAN,


    /***********************************************************************************************
    Final decision-resolution control.

    failed_counteroffer_resolution:
        Governs how preliminary COUNTEROFFER routes resolve when Section 8 determines that no viable
        reduced-exposure treatment exists.

    Allowed values:
        MANUAL_REVIEW
        DECLINE

    Default:
        MANUAL_REVIEW

    Interpretation:
        A failed counteroffer is routed to MANUAL_REVIEW by default because higher-priority hard
        simulated policy stops, severe synthetic estimated-risk, and severe DTI have already routed
        to DECLINE before counteroffer feasibility is evaluated.

    Boundary:
        This is a simulated strategy-control parameter, not production underwriting policy.
    ***********************************************************************************************/
    failed_counteroffer_resolution               TEXT
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 2.2 — INSERT ACTIVE STRATEGY PARAMETER ROW
****************************************************************************************************

PURPOSE:
    Insert the current active Module 2 strategy configuration.

USER ACTION:
    This default row is intentionally editable.

    For a governed strategy test, users should update:
        strategy_set_name,
        strategy_name,
        strategy_version,
        strategy_run_id,
        module1_input_source,
        source Module 1 scenario fields when using ARCHIVE,
        strategy thresholds,
        product policy table values,
        archive controls,
        campaign_registry_required_flag.

CURRENT DEFAULT:
    The default row below is aligned to the currently tested TIGHTER_SYNTHETIC_RISK_STRATEGY on the
    Module 1 BASELINE_V2 archive slice.

    To rerun the baseline strategy for evidence backfill, change:
        strategy_name,
        strategy_run_id,
        synthetic estimated-risk thresholds,
        and any other strategy-specific settings
    back to the baseline strategy values.

AUDIT METADATA NOTE:
    strategy_run_id and strategy_run_ts support traceability.

    They do not replace:
        archive replacement key,
        matched comparison key,
        campaign registry technical key,
        or application-level grain.

SQL MECHANICS:
    The INSERT column list explicitly names every field in tmp_module2_strategy_params.

    This protects against positional mistakes if the table definition changes later.

    The VALUES clause then supplies one active strategy row.

    Section 3 will validate that:
        exactly one active row exists,
        thresholds are ordered correctly,
        settings are valid,
        Module 1 source configuration is usable,
        product policy rows are complete,
        and registry matching is available when required.

CREDIT RISK TEACHING POINT:
    This row defines strategy posture.

    It does not prove the strategy behaves correctly.

    Strategy behavior is observed later through:
        decision distributions,
        approved exposure,
        approved Expected Loss,
        reason-code movement,
        product × score behavior,
        and frontier/evidence outputs.

****************************************************************************************************/

INSERT INTO tmp_module2_strategy_params (
    active_strategy_flag,

    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    campaign_registry_required_flag,

    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,

    archive_run_flag,
    strategy_archive_reset_mode,

    approve_max_estimated_pd_proxy,
    counteroffer_max_estimated_pd_proxy,
    review_max_estimated_pd_proxy,
    decline_min_estimated_pd_proxy,

    global_approve_max_pti,
    global_review_max_pti,
    global_decline_min_pti,

    approve_max_dti,
    review_max_dti,
    decline_min_dti,

    borderline_threshold_buffer_pct,

    bankruptcy_policy_stop_enabled,
    major_derogatory_policy_stop_enabled,
    severe_delinquency_policy_stop_enabled,
    severe_delinquency_count_threshold,
    high_utilization_review_enabled,
    high_utilization_review_threshold,
    low_score_review_enabled,
    low_score_review_threshold,

    approve_reason_code,
    reason_code_required_flag,
    simulated_offer_exposure_flag_enabled,
    manual_review_approved_amount_convention,
    decline_approved_amount_convention,
    approved_el_decline_convention,
    approved_el_manual_review_convention,
    allow_approved_amount_above_requested_flag,

    failed_counteroffer_resolution
)
VALUES (
    /***********************************************************************************************
    Active strategy indicator.

    TRUE marks this as the one active parameter card for the current run.
    ***********************************************************************************************/
    TRUE,

    /***********************************************************************************************
    Module 2 strategy identity.

    This example is currently set to the tighter synthetic-risk challenger.
    ***********************************************************************************************/
    'MODULE2_V1_0',
    'MODULE2_BASELINE_STRATEGY_SET',
    'TIGHTER_SYNTHETIC_RISK_STRATEGY',
    'V1_0',
    'M2-02_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN',
    CURRENT_TIMESTAMP,

    /***********************************************************************************************
    Campaign registry requirement.

    TRUE means Section 3 / Section 16 should expect a formal registry match for the technical run
    key.
    ***********************************************************************************************/
    TRUE,

    /***********************************************************************************************
    Module 1 source selection.

    LATEST:
        Consumes credit_decisioning_sim.synthetic_applications.

    ARCHIVE:
        Consumes a selected slice of credit_decisioning_sim.synthetic_applications_scenario_archive.

    When ARCHIVE is used:
        source_module1_scenario_set_name,
        source_module1_scenario_name,
        and source_population_id must be populated.

    This default consumes the archived Module 1 BASELINE_V2 population.
    ***********************************************************************************************/
    'ARCHIVE',
    'MODULE1_V2_BASELINE_SET',
    'BASELINE_V2',
    'BASE_POPULATION_V1',

    /***********************************************************************************************
    Archive controls.

    archive_run_flag = TRUE:
        the completed latest-run output is eligible for Section 12 archive persistence.

    STRATEGY_SCENARIO_ONLY:
        ordinary rerun mode.

        It replaces only the current strategy / Module 1 scenario / population slice.
    ***********************************************************************************************/
    TRUE,
    'STRATEGY_SCENARIO_ONLY',

    /***********************************************************************************************
    Global synthetic estimated-PD proxy thresholds.

    Equality convention:
        APPROVE eligibility:
            estimated_pd <= approve_max_estimated_pd_proxy

        COUNTEROFFER risk band:
            estimated_pd > approve_max_estimated_pd_proxy
            AND estimated_pd <= counteroffer_max_estimated_pd_proxy

        MANUAL_REVIEW risk band:
            estimated_pd > counteroffer_max_estimated_pd_proxy
            AND estimated_pd < decline_min_estimated_pd_proxy

        DECLINE trigger:
            estimated_pd >= decline_min_estimated_pd_proxy

    These values are synthetic strategy defaults for the tighter synthetic-risk challenger.

    They are not production cutoffs.
    ***********************************************************************************************/
    0.060000,
    0.120000,
    0.250000,
    0.300000,

    /***********************************************************************************************
    Global PTI thresholds.

    Product-specific PTI thresholds are used for product-aware affordability rules.

    These global thresholds provide high-level strategy governance and are validated for ordering in
    Section 3.
    ***********************************************************************************************/
    0.250000,
    0.400000,
    0.550000,

    /***********************************************************************************************
    DTI thresholds.

    DTI is an existing-obligation capacity signal.

    In this default, review_max_dti and decline_min_dti are equal at 0.600000, meaning DTI at or
    above 60% is treated as severe under the downstream DTI flag logic.
    ***********************************************************************************************/
    0.430000,
    0.600000,
    0.600000,

    /***********************************************************************************************
    Borderline diagnostic buffer.

    0.050000 means downstream segmentation tags a profile as threshold-adjacent when a value is
    within 5% of a relevant strategy threshold.

    This is a governed diagnostic parameter, not a production underwriting tolerance and not an
    empirically calibrated cutoff.
    ***********************************************************************************************/
    0.050000,

    /***********************************************************************************************
    Section 6 rule-control defaults.

    These values govern simulated trigger construction only.

    They are not production underwriting rules.
    They are not empirically calibrated policy cutoffs.
    They are not final strategy outcomes.

    severe_delinquency_count_threshold = 4:
        simulated severe delinquency trigger uses delinquency_count_12m >= 4 when enabled.

    high_utilization_review_threshold = 0.850000:
        simulated high-utilization review signal is enabled at or above 85% utilization.

    low_score_review_threshold = 580:
        simulated low-score review signal is enabled below the threshold used downstream.
    ***********************************************************************************************/
    TRUE,
    TRUE,
    TRUE,
    4,
    TRUE,
    0.850000,
    TRUE,
    580,

    /***********************************************************************************************
    Decision convention controls.

    APPROVED_AS_REQUESTED:
        clean approval reason-code convention.

    reason_code_required_flag = TRUE:
        every row should receive reason-code evidence downstream.

    simulated_offer_exposure_flag_enabled = TRUE:
        APPROVE and COUNTEROFFER should be treated as simulated positive offer-exposure outcomes.

    manual_review_approved_amount_convention = NULL_UNRESOLVED:
        manual review remains unresolved.

    decline_approved_amount_convention = ZERO:
        decline follows zero-exposure convention.

    allow_approved_amount_above_requested_flag = FALSE:
        approved amount should not exceed requested amount.
    ***********************************************************************************************/
    'APPROVED_AS_REQUESTED',
    TRUE,
    TRUE,
    'NULL_UNRESOLVED',
    'ZERO',
    'ZERO',
    'NULL_UNRESOLVED',
    FALSE,

    /***********************************************************************************************
    Failed counteroffer resolution default.

    MANUAL_REVIEW is intentionally conservative and audit-readable.

    It avoids silently converting all infeasible reduced-exposure cases into declines after
    higher-priority hard simulated policy stop, severe synthetic estimated-risk, and severe DTI routes
    have already been handled.
    ***********************************************************************************************/
    'MANUAL_REVIEW'
);



/***************************************************************************************************
SECTION 2.3 — PRODUCT POLICY PARAMETER TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Define product-specific affordability thresholds, requested Expected Loss thresholds, approved
    exposure limits, counteroffer controls, manual-review permissions, and rounding rules.

SQL PURPOSE:
    Provide one governed policy row per supported Module 1 product type.

SUPPORTED PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

WHY PRODUCT POLICY PARAMETERS ARE SEPARATE FROM STRATEGY PARAMETERS:
    Global strategy parameters govern cross-product decision posture.

    Product policy parameters govern product-specific affordability, exposure, requested Expected
    Loss, approved Expected Loss, counteroffer, and rounding behavior.

    Keeping these separate allows Module 2 to express product-aware strategy logic without burying
    product controls in downstream CASE expressions.

CREDIT RISK TEACHING POINT:
    Product type is not just a label.

    Product structure influences:
        requested amount,
        repayment behavior,
        loss severity,
        affordability stress,
        counteroffer feasibility,
        approved exposure,
        and Expected Loss.

    A mortgage, auto loan, revolving line, HELOC, and unsecured personal loan should not be governed
    by identical exposure and affordability controls.

SQL MECHANICS:
    The temporary product-policy table is joined to source rows later by product_type_policy_key.

    Section 4 validates that every source product maps to exactly one product-policy row.

    Section 5 carries these product thresholds into the staged data.

    Sections 6 through 9 use these fields to build rule flags, route applications, test exposure
    treatment, and resolve final simulated decisions.

****************************************************************************************************/

CREATE TEMP TABLE tmp_module2_product_policy_params (
    /***********************************************************************************************
    Product identity.

    product_type should match the normalized product_type_policy_key generated in Section 4.
    ***********************************************************************************************/
    product_type                            TEXT,


    /***********************************************************************************************
    Product-specific PTI thresholds.

    These thresholds use requested_payment_to_income_ratio until approved exposure treatment exists.

    product_approve_max_pti:
        requested PTI at or below this level is clean from a product-affordability perspective.

    product_review_max_pti:
        product-level reference point for review-zone affordability behavior.

    product_decline_min_pti:
        severe requested-affordability threshold.

    counteroffer_target_pti:
        target approved PTI used when testing reduced-exposure counteroffer feasibility.
    ***********************************************************************************************/
    product_approve_max_pti                 NUMERIC(12,6),
    product_review_max_pti                  NUMERIC(12,6),
    product_decline_min_pti                 NUMERIC(12,6),
    counteroffer_target_pti                 NUMERIC(12,6),


    /***********************************************************************************************
    Requested Expected Loss thresholds.

    requested_expected_loss_amount is the Module 2 alias for Module 1 expected_loss_amount.

    It is requested-exposure Expected Loss.

    These thresholds are used before approved exposure exists.
    ***********************************************************************************************/
    product_approve_max_requested_el        NUMERIC(18,2),
    product_review_max_requested_el         NUMERIC(18,2),
    product_decline_min_requested_el        NUMERIC(18,2),


    /***********************************************************************************************
    Approved Expected Loss cap.

    product_approved_el_cap is used after exposure treatment is evaluated.

    It does not drive pre-decision requested Expected Loss tiering.

    Section 8 uses this cap to test whether a reduced approved amount can bring approved Expected
    Loss within the product-specific cap.
    ***********************************************************************************************/
    product_approved_el_cap                 NUMERIC(18,2),


    /***********************************************************************************************
    Approved exposure limits.

    product_min_approved_amount:
        minimum viable simulated approved exposure for this product.

    product_max_approved_amount:
        maximum allowed simulated approved exposure for this product.

    These values support both clean approval review and counteroffer feasibility.
    ***********************************************************************************************/
    product_min_approved_amount             NUMERIC(18,2),
    product_max_approved_amount             NUMERIC(18,2),


    /***********************************************************************************************
    Counteroffer and manual-review controls.

    counteroffer_allowed_flag:
        controls whether this product can receive reduced-exposure treatment.

    manual_review_allowed_flag:
        controls whether this product can remain unresolved in manual review.

    product_min_counteroffer_pct:
        minimum allowed percentage of requested amount for a viable counteroffer.

    product_max_exposure_reduction_pct:
        maximum allowed reduction from requested amount.

    exposure_assignment_method:
        method label used by Section 8 exposure-treatment logic.
    ***********************************************************************************************/
    counteroffer_allowed_flag               BOOLEAN,
    manual_review_allowed_flag              BOOLEAN,
    product_min_counteroffer_pct            NUMERIC(12,6),
    product_max_exposure_reduction_pct      NUMERIC(12,6),
    exposure_assignment_method              TEXT,


    /***********************************************************************************************
    Rounding.

    approved_amount_rounding_increment:
        conservative approved-amount rounding increment.

    Section 8 rounds counteroffer amounts down so the final simulated amount does not accidentally
    exceed cap, PTI, or approved Expected Loss constraints.
    ***********************************************************************************************/
    approved_amount_rounding_increment      NUMERIC(18,2)
) ON COMMIT PRESERVE ROWS;



/***************************************************************************************************
SECTION 2.4 — INSERT PRODUCT POLICY DEFAULTS
****************************************************************************************************

DEFAULT INTERPRETATION:
    These are initial simulated strategy defaults.

    They are not:
        production underwriting limits,
        final approved credit policy,
        empirical calibration,
        real customer treatment rules,
        or regulatory thresholds.

PRODUCT POLICY INTERPRETATION:
    Product parameters are intended to make the strategy simulator product-aware.

    Mortgage, HELOC, Auto Loan, Unsecured Personal Loan, and Revolving Line each have distinct:
        affordability tolerances,
        requested Expected Loss thresholds,
        approved Expected Loss caps,
        exposure ranges,
        counteroffer rules,
        and rounding increments.

SQL MECHANICS:
    This INSERT creates five product-policy rows.

    The VALUES block is deliberately explicit.

    Each product row supplies values in the same order as the INSERT column list.

    Section 3 validates:
        one row per supported product,
        no duplicate product rows,
        no unsupported product rows,
        threshold ordering,
        exposure limits,
        and counteroffer policy consistency.

CREDIT RISK TEACHING POINT:
    Product-aware policy matters because the same borrower profile can produce different risk and
    affordability implications depending on product structure.

    Secured installment exposure, secured revolving exposure, unsecured installment exposure, and
    unsecured revolving exposure have different expected loss and affordability behavior.

****************************************************************************************************/

INSERT INTO tmp_module2_product_policy_params (
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
)
VALUES
    /***********************************************************************************************
    MORTGAGE:
        Larger secured exposure.

        Higher PTI tolerance than unsecured products because mortgage structure is long-term and
        secured.

        However, exposure and approved Expected Loss controls remain important because mortgage
        balances can be large.

    SQL note:
        This row supplies one product-policy card for product_type = 'MORTGAGE'.
    ***********************************************************************************************/
    (
        'MORTGAGE',
        0.350000,
        0.450000,
        0.550000,
        0.320000,

        10000.00,
        20000.00,
        40000.00,
        10000.00,

        75000.00,
        800000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        5000.00
    ),

    /***********************************************************************************************
    HELOC:
        Secured revolving exposure.

        PTI tolerance is lower than mortgage but higher than smaller unsecured line-style products.

        Because HELOC exposure can be meaningful and secured by collateral, it needs distinct
        exposure limits and approved Expected Loss controls.
    ***********************************************************************************************/
    (
        'HELOC',
        0.250000,
        0.350000,
        0.450000,
        0.220000,

        8000.00,
        16000.00,
        30000.00,
        7000.00,

        10000.00,
        175000.00,

        TRUE,
        TRUE,
        0.400000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        1000.00
    ),

    /***********************************************************************************************
    AUTO_LOAN:
        Secured installment exposure with moderate structural risk and payment sensitivity.

        Auto loan payment burden is sensitive to requested amount, APR proxy, and term.

        The approved amount rounding increment is smaller than mortgage / HELOC because auto loans
        are naturally smaller-balance products.
    ***********************************************************************************************/
    (
        'AUTO_LOAN',
        0.180000,
        0.280000,
        0.380000,
        0.160000,

        3500.00,
        7000.00,
        12000.00,
        3000.00,

        5000.00,
        65000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    ),

    /***********************************************************************************************
    UNSECURED_PERSONAL_LOAN:
        Smaller unsecured installment exposure.

        Higher loss severity and less collateral support justify tighter affordability tolerance and
        lower approved Expected Loss cap than secured products.
    ***********************************************************************************************/
    (
        'UNSECURED_PERSONAL_LOAN',
        0.150000,
        0.250000,
        0.350000,
        0.130000,

        3000.00,
        6000.00,
        10000.00,
        2500.00,

        1000.00,
        35000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    ),

    /***********************************************************************************************
    REVOLVING_LINE:
        Unsecured revolving exposure with high LGD and APR-sensitive payment proxy upstream.

        Module 2 remains a strategy simulator and not a credit-card billing engine.

        The lower PTI tolerance and lower approved Expected Loss cap reflect the higher-risk nature
        of unsecured revolving exposure in this synthetic strategy framework.
    ***********************************************************************************************/
    (
        'REVOLVING_LINE',
        0.120000,
        0.200000,
        0.300000,
        0.100000,

        2000.00,
        4000.00,
        8000.00,
        1800.00,

        1000.00,
        20000.00,

        TRUE,
        TRUE,
        0.500000,
        0.500000,
        'MOST_CONSERVATIVE_FEASIBLE_AMOUNT',
        500.00
    );



/***************************************************************************************************
SECTION 2.5 — PERSISTENT STRATEGY RUN CAMPAIGN REGISTRY
****************************************************************************************************

BUSINESS PURPOSE:
    Create a persistent roadmap table that maps formal Module 2 campaign runs to stable run IDs,
    showcase IDs, comparison IDs, validation evidence IDs, and documentation labels.

SQL PURPOSE:
    Create or reuse:
        credit_decisioning_sim.strategy_run_campaign_registry

REGISTRY GRAIN:
    One row per planned Module 1 scenario × Module 2 strategy version run.

WHY THIS REGISTRY EXISTS:
    Technical lineage fields are precise but long.

    For validation summaries, README outputs, and executive storytelling, it is easier to reference:

        M2-02

    than:

        MODULE1_V2_BASELINE_SET / BASELINE_V2 / BASE_POPULATION_V1
        +
        MODULE2_BASELINE_STRATEGY_SET / TIGHTER_SYNTHETIC_RISK_STRATEGY / V1_0

    The registry preserves both:
        compact campaign IDs,
        and exact technical identifiers.

SQL MECHANICS:
    CREATE TABLE IF NOT EXISTS creates the registry table only if it is absent.

    module2_run_id is the primary key because it is the compact run identifier.

    A separate unique index enforces uniqueness at the technical run key:
        module1_scenario_set_name,
        module1_scenario_name,
        population_id,
        strategy_set_name,
        strategy_name,
        strategy_version.

    This is important because documentation IDs and SQL lineage should agree.

BOUNDARY:
    The campaign registry does not modify Module 1.
    The campaign registry does not modify strategy decisions.
    The campaign registry does not define archive replacement grain.
    The campaign registry does not define matched comparison grain.
    The campaign registry does not change decision logic.

****************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_campaign_registry (
    /***********************************************************************************************
    Compact run identifiers.

    module1_run_id:
        compact ID for the upstream Module 1 scenario run.

    module2_run_id:
        compact ID for the current Module 2 strategy run.
        This is the primary key for the registry.

    run_sequence_number:
        ordering field used for campaign review and documentation sequence.
    ***********************************************************************************************/
    module1_run_id                         TEXT NOT NULL,
    module2_run_id                         TEXT PRIMARY KEY,
    run_sequence_number                    INTEGER NOT NULL,

    /***********************************************************************************************
    Story and evidence grouping identifiers.

    showcase_id / showcase_name:
        group runs into executive story families.

    comparison_group_id:
        identifies planned matched comparisons in Section 13.

    validation_evidence_group_id:
        identifies the evidence package used later in validation documentation.
    ***********************************************************************************************/
    showcase_id                            TEXT,
    showcase_name                          TEXT,
    comparison_group_id                    TEXT,
    validation_evidence_group_id           TEXT,

    /***********************************************************************************************
    Technical Module 1 lineage.

    These fields identify the upstream synthetic population and scenario.
    ***********************************************************************************************/
    module1_scenario_set_name              TEXT NOT NULL,
    module1_scenario_name                  TEXT NOT NULL,
    population_id                          TEXT NOT NULL,

    /***********************************************************************************************
    Technical Module 2 strategy identity.

    These fields identify the downstream strategy applied to the Module 1 population.
    ***********************************************************************************************/
    strategy_set_name                      TEXT NOT NULL,
    strategy_name                          TEXT NOT NULL,
    strategy_version                       TEXT NOT NULL,

    /***********************************************************************************************
    Story labels describing what changed.
    ***********************************************************************************************/
    module1_parameter_family_changed        TEXT,
    module1_parameter_change_summary        TEXT,

    module2_strategy_family_changed         TEXT,
    module2_parameter_change_summary        TEXT,

    /***********************************************************************************************
    Documentation helper fields.

    These support README, LinkedIn, and future Validation Summary narrative organization.
    ***********************************************************************************************/
    expected_storyline                     TEXT,
    validation_summary_section_hint         TEXT,
    readme_storyline_label                 TEXT,
    linkedin_post_sequence                 INTEGER,

    /***********************************************************************************************
    Registry governance metadata.

    registry_active_flag controls whether the row is available to current matching logic.
    registry_created_ts and registry_updated_ts support audit traceability.
    ***********************************************************************************************/
    registry_active_flag                   BOOLEAN NOT NULL DEFAULT TRUE,
    registry_created_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registry_updated_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/*-----------------------------------------------------------------------------------------------
Technical-key uniqueness index.

Business purpose:
    Prevent two active registry definitions from mapping to the same exact Module 1 scenario /
    population and Module 2 strategy technical key.

SQL purpose:
    Enforce one registry row per technical run key, independent of the compact module2_run_id.
-----------------------------------------------------------------------------------------------*/
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_technical_key
ON credit_decisioning_sim.strategy_run_campaign_registry (
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    strategy_set_name,
    strategy_name,
    strategy_version
);


/*-----------------------------------------------------------------------------------------------
Showcase lookup index.

Business purpose:
    Support fast review of runs grouped by showcase.

SQL purpose:
    Index showcase_id and run_sequence_number for ordered campaign review outputs.
-----------------------------------------------------------------------------------------------*/
CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_showcase
ON credit_decisioning_sim.strategy_run_campaign_registry (
    showcase_id,
    run_sequence_number
);


/*-----------------------------------------------------------------------------------------------
Comparison-group lookup index.

Business purpose:
    Support lookup of runs that participate in a planned comparison group.

SQL purpose:
    Index comparison_group_id and run_sequence_number for Section 13 / documentation support.
-----------------------------------------------------------------------------------------------*/
CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_campaign_registry_comparison_group
ON credit_decisioning_sim.strategy_run_campaign_registry (
    comparison_group_id,
    run_sequence_number
);



/***************************************************************************************************
SECTION 2.6 — SEED / UPDATE STRATEGY RUN CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Seed the formal Module 2 campaign roadmap.

HOW TO USE:
    Users may update labels, expected_storyline, readme_storyline_label, and linkedin_post_sequence
    as the portfolio story evolves.

IMPORTANT:
    These registry rows do not create Module 1 scenarios.
    These registry rows do not execute Module 2 strategies.
    These registry rows only map planned or completed technical runs to stable evidence IDs.

SQL MECHANICS:
    INSERT ... ON CONFLICT (module2_run_id) DO UPDATE is an upsert.

    If the run ID does not exist:
        PostgreSQL inserts it.

    If the run ID already exists:
        PostgreSQL updates the mapped technical fields, story labels, active flag, and updated
        timestamp.

    This makes registry seeding rerunnable.

CREDIT RISK / STORYTELLING STRUCTURE:
    The campaign is organized into showcase groups:
        SC01 — baseline strategy frontier,
        SC02 — rate environment sensitivity,
        SC03 — credit box sensitivity,
        SC04 — portfolio mix sensitivity,
        SC05 — exposure intensity sensitivity,
        SC06 — LGD severity sensitivity.

    This creates a structured executive story rather than a random collection of strategy runs.

****************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_run_campaign_registry (
    module1_run_id,
    module2_run_id,
    run_sequence_number,

    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_parameter_family_changed,
    module1_parameter_change_summary,

    module2_strategy_family_changed,
    module2_parameter_change_summary,

    expected_storyline,
    validation_summary_section_hint,
    readme_storyline_label,
    linkedin_post_sequence,

    registry_active_flag,
    registry_updated_ts
)
VALUES
    /***********************************************************************************************
    SC01 — Baseline Strategy Frontier.

    These rows compare multiple Module 2 strategies on the same Module 1 baseline population.

    This is the cleanest pure Module 2 strategy frontier because Module 1 scenario and population are
    held constant.
    ***********************************************************************************************/
    ('M1-01', 'M2-01', 1, 'SC01', 'Baseline Strategy Frontier', 'CG01', 'VE01',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish the baseline reference strategy output for the Module 1 baseline population.',
     'Baseline reference strategy evidence', 'Baseline strategy reference', 1, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-02', 2, 'SC01', 'Baseline Strategy Frontier', 'CG01', 'VE02',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'RISK_TIGHTENING', 'Tightens synthetic estimated-PD proxy strategy thresholds.',
     'Demonstrate risk-discipline tradeoff: lower simulated offer exposure and approved Expected Loss, with higher no-offer outcomes.',
     'Risk-discipline challenger evidence', 'Tighter synthetic-risk strategy', 2, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-03', 3, 'SC01', 'Baseline Strategy Frontier', 'CG02', 'VE03',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'GROWTH', 'Loosens selected synthetic-risk, PTI, and DTI tolerances for growth-oriented comparison.',
     'Demonstrate growth tradeoff: higher simulated offer exposure and approved amount with measurable risk impact.',
     'Growth challenger evidence', 'Growth-oriented strategy', 3, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-04', 4, 'SC01', 'Baseline Strategy Frontier', 'CG03', 'VE04',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'AFFORDABILITY_TIGHTENING', 'Tightens PTI thresholds and counteroffer target PTI.',
     'Demonstrate affordability discipline and how tighter PTI guardrails affect offer exposure, counteroffers, and review burden.',
     'Affordability challenger evidence', 'Tighter affordability strategy', 4, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-05', 5, 'SC01', 'Baseline Strategy Frontier', 'CG04', 'VE05',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'COUNTEROFFER_MANAGEMENT', 'Emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.',
     'Demonstrate exposure-management tradeoff through counteroffer feasibility and approved exposure reduction.',
     'Counteroffer management evidence', 'Counteroffer-first strategy', 5, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-06', 6, 'SC01', 'Baseline Strategy Frontier', 'CG05', 'VE06',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Demonstrate product-specific risk guardrails and where product-level strategy controls change outcomes.',
     'Product guardrail evidence', 'Product-specific guardrail strategy', 6, TRUE, CURRENT_TIMESTAMP),

    ('M1-01', 'M2-07', 7, 'SC01', 'Baseline Strategy Frontier', 'CG06', 'VE07',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'MANUAL_REVIEW_REDUCTION_STRATEGY', 'V1_0',
     'BASELINE', 'Module 1 baseline scenario using accepted V2.0 defaults.',
     'OPERATIONS_REVIEW_REDUCTION', 'Resolves failed counteroffers to final no-offer outcomes to reduce unresolved manual review.',
     'Demonstrate operational review-burden reduction and the corresponding no-offer tradeoff.',
     'Manual review reduction evidence', 'Manual-review reduction strategy', 7, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC02 — Rate Environment Sensitivity.

    These rows test how upstream rate movement changes affordability, requested structure, synthetic
    estimated-risk proxy behavior, and Module 2 strategy outcomes.

    Rate-up scenarios are useful for affordability stress.
    Rate-down scenarios are useful for growth-opportunity review.
    ***********************************************************************************************/
    ('M1-02', 'M2-08', 8, 'SC02', 'Rate Environment Sensitivity', NULL, 'VE08',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-up scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under a 200 basis-point upstream rate-stress scenario.',
     'Rate stress baseline evidence', 'Rate-up 200bp baseline strategy', 8, TRUE, CURRENT_TIMESTAMP),

    ('M1-03', 'M2-09', 9, 'SC02', 'Rate Environment Sensitivity', NULL, 'VE09',
     'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-down scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under a 200 basis-point upstream rate-relief scenario.',
     'Rate relief baseline evidence', 'Rate-down 200bp baseline strategy', 9, TRUE, CURRENT_TIMESTAMP),

    ('M1-04', 'M2-10', 10, 'SC02', 'Rate Environment Sensitivity', NULL, 'VE10',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 300 basis-point rate-up scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under a stronger 300 basis-point upstream rate-stress scenario.',
     'Rate stress 300bp evidence', 'Rate-up 300bp baseline strategy', 10, TRUE, CURRENT_TIMESTAMP),

    ('M1-02', 'M2-11', 11, 'SC02', 'Rate Environment Sensitivity', 'CG07', 'VE11',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-up scenario.',
     'AFFORDABILITY_TIGHTENING', 'Tightens PTI thresholds and counteroffer target PTI.',
     'Evaluate whether tighter affordability controls improve approved PTI and approved Expected Loss under rate stress.',
     'Rate stress affordability evidence', 'Rate-up 200bp affordability guardrail', 11, TRUE, CURRENT_TIMESTAMP),

    ('M1-04', 'M2-12', 12, 'SC02', 'Rate Environment Sensitivity', 'CG08', 'VE12',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 300 basis-point rate-up scenario.',
     'AFFORDABILITY_TIGHTENING', 'Tightens PTI thresholds and counteroffer target PTI.',
     'Evaluate whether tighter affordability controls are more protective under stronger rate stress.',
     'Strong rate stress affordability evidence', 'Rate-up 300bp affordability guardrail', 12, TRUE, CURRENT_TIMESTAMP),

    ('M1-03', 'M2-13', 13, 'SC02', 'Rate Environment Sensitivity', 'CG09', 'VE13',
     'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'RATE_ENVIRONMENT', 'Module 1 200 basis-point rate-down scenario.',
     'GROWTH', 'Loosens selected synthetic-risk, PTI, and DTI tolerances for growth-oriented comparison.',
     'Evaluate whether rate relief plus growth posture expands simulated offer exposure and approved amount.',
     'Rate relief growth evidence', 'Rate-down 200bp growth strategy', 13, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC03 — Credit Box Sensitivity.

    These rows test how changing the upstream score mix interacts with downstream Module 2 strategy
    posture.

    This supports credit-box expansion and credit-stress storytelling.
    ***********************************************************************************************/
    ('M1-05', 'M2-14', 14, 'SC03', 'Credit Box Sensitivity', NULL, 'VE14',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_BOX_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'BASELINE_REFERENCE', 'Credit-box baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish credit-box sensitivity reference behavior.',
     'Credit-box reference evidence', 'Credit-box baseline reference', 14, TRUE, CURRENT_TIMESTAMP),

    ('M1-06', 'M2-15', 15, 'SC03', 'Credit Box Sensitivity', NULL, 'VE15',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'PRIME_GROWTH_SCORE_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing stronger-score applicant composition.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy performance under stronger credit-box mix.',
     'Prime-growth mix evidence', 'Prime growth score mix', 15, TRUE, CURRENT_TIMESTAMP),

    ('M1-07', 'M2-16', 16, 'SC03', 'Credit Box Sensitivity', NULL, 'VE16',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing near-prime expansion.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under near-prime expansion.',
     'Near-prime expansion baseline evidence', 'Near-prime expansion baseline', 16, TRUE, CURRENT_TIMESTAMP),

    ('M1-07', 'M2-17', 17, 'SC03', 'Credit Box Sensitivity', 'CG10', 'VE17',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing near-prime expansion.',
     'RISK_TIGHTENING', 'Tightens synthetic estimated-PD proxy strategy thresholds.',
     'Evaluate risk-discipline strategy behavior in a near-prime expansion scenario.',
     'Near-prime risk discipline evidence', 'Near-prime expansion risk discipline', 17, TRUE, CURRENT_TIMESTAMP),

    ('M1-07', 'M2-18', 18, 'SC03', 'Credit Box Sensitivity', 'CG11', 'VE18',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing near-prime expansion.',
     'COUNTEROFFER_MANAGEMENT', 'Emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.',
     'Evaluate whether counteroffer-first strategy preserves access while managing exposure in near-prime expansion.',
     'Near-prime counteroffer evidence', 'Near-prime expansion counteroffer strategy', 18, TRUE, CURRENT_TIMESTAMP),

    ('M1-08', 'M2-19', 19, 'SC03', 'Credit Box Sensitivity', NULL, 'VE19',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing weaker-score applicant composition.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under credit-stress score mix.',
     'Credit-stress baseline evidence', 'Credit stress baseline', 19, TRUE, CURRENT_TIMESTAMP),

    ('M1-08', 'M2-20', 20, 'SC03', 'Credit Box Sensitivity', 'CG12', 'VE20',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'SCORE_MIX', 'Module 1 score-mix scenario emphasizing weaker-score applicant composition.',
     'RISK_TIGHTENING', 'Tightens synthetic estimated-PD proxy strategy thresholds.',
     'Evaluate whether risk tightening improves approved Expected Loss behavior under credit-stress mix.',
     'Credit-stress risk discipline evidence', 'Credit stress risk discipline', 20, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC04 — Portfolio Mix Sensitivity.

    These rows test how upstream product mix changes affect downstream strategy behavior.

    Product mix can materially change portfolio approved exposure and Expected Loss.
    ***********************************************************************************************/
    ('M1-09', 'M2-21', 21, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE21',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'PRODUCT_MIX_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Product-mix baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish product-mix sensitivity reference behavior.',
     'Product-mix reference evidence', 'Product mix baseline reference', 21, TRUE, CURRENT_TIMESTAMP),

    ('M1-10', 'M2-22', 22, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE22',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing unsecured growth.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under unsecured-growth product mix.',
     'Unsecured growth baseline evidence', 'Unsecured growth baseline', 22, TRUE, CURRENT_TIMESTAMP),

    ('M1-10', 'M2-23', 23, 'SC04', 'Portfolio Mix Sensitivity', 'CG13', 'VE23',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing unsecured growth.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under unsecured-growth product mix.',
     'Unsecured growth guardrail evidence', 'Unsecured growth product guardrails', 23, TRUE, CURRENT_TIMESTAMP),

    ('M1-11', 'M2-24', 24, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE24',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'SECURED_BALANCE_GROWTH_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing secured balance growth.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under secured-balance growth mix.',
     'Secured balance growth evidence', 'Secured balance growth baseline', 24, TRUE, CURRENT_TIMESTAMP),

    ('M1-12', 'M2-25', 25, 'SC04', 'Portfolio Mix Sensitivity', NULL, 'VE25',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing revolving-line expansion.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy behavior under revolving-line expansion.',
     'Revolving expansion baseline evidence', 'Revolving expansion baseline', 25, TRUE, CURRENT_TIMESTAMP),

    ('M1-12', 'M2-26', 26, 'SC04', 'Portfolio Mix Sensitivity', 'CG14', 'VE26',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'PRODUCT_MIX', 'Module 1 product-mix scenario emphasizing revolving-line expansion.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under revolving-line expansion.',
     'Revolving expansion guardrail evidence', 'Revolving expansion product guardrails', 26, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC05 — Exposure Intensity Sensitivity.

    These rows test how requested-balance intensity affects downstream offer exposure, approved
    exposure, counteroffer treatment, and approved Expected Loss.
    ***********************************************************************************************/
    ('M1-13', 'M2-27', 27, 'SC05', 'Exposure Intensity Sensitivity', NULL, 'VE27',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'EXPOSURE_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Exposure-intensity baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish exposure-intensity reference behavior.',
     'Exposure reference evidence', 'Exposure intensity reference', 27, TRUE, CURRENT_TIMESTAMP),

    ('M1-14', 'M2-28', 28, 'SC05', 'Exposure Intensity Sensitivity', NULL, 'VE28',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Module 1 scenario with higher balance appetite.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under higher requested-exposure intensity.',
     'High balance baseline evidence', 'High balance baseline', 28, TRUE, CURRENT_TIMESTAMP),

    ('M1-14', 'M2-29', 29, 'SC05', 'Exposure Intensity Sensitivity', 'CG15', 'VE29',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Module 1 scenario with higher balance appetite.',
     'COUNTEROFFER_MANAGEMENT', 'Emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.',
     'Evaluate counteroffer-first exposure treatment under high-balance requested-exposure intensity.',
     'High balance counteroffer evidence', 'High balance counteroffer strategy', 29, TRUE, CURRENT_TIMESTAMP),

    ('M1-15', 'M2-30', 30, 'SC05', 'Exposure Intensity Sensitivity', NULL, 'VE30',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'LOW_BALANCE_CONSERVATIVE_REQUESTS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'EXPOSURE_INTENSITY', 'Module 1 scenario with lower-balance conservative requests.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under lower requested-exposure intensity.',
     'Low balance baseline evidence', 'Low balance conservative baseline', 30, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC06 — LGD Severity Sensitivity.

    These rows test how upstream LGD severity changes influence requested and approved Expected Loss
    under baseline and guardrail strategies.
    ***********************************************************************************************/
    ('M1-16', 'M2-31', 31, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE31',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'LGD_BASELINE_REFERENCE', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'LGD baseline reference scenario.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Establish LGD severity sensitivity reference behavior.',
     'LGD reference evidence', 'LGD baseline reference', 31, TRUE, CURRENT_TIMESTAMP),

    ('M1-17', 'M2-32', 32, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE32',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'SECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario stressing secured-product severity.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under secured-product severity stress.',
     'Secured severity evidence', 'Secured severity stress baseline', 32, TRUE, CURRENT_TIMESTAMP),

    ('M1-18', 'M2-33', 33, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE33',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario stressing unsecured-product severity.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under unsecured-product severity stress.',
     'Unsecured severity baseline evidence', 'Unsecured severity stress baseline', 33, TRUE, CURRENT_TIMESTAMP),

    ('M1-18', 'M2-34', 34, 'SC06', 'LGD Severity Sensitivity', 'CG16', 'VE34',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario stressing unsecured-product severity.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under unsecured severity stress.',
     'Unsecured severity guardrail evidence', 'Unsecured severity product guardrails', 34, TRUE, CURRENT_TIMESTAMP),

    ('M1-19', 'M2-35', 35, 'SC06', 'LGD Severity Sensitivity', NULL, 'VE35',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario applying broad LGD stress.',
     'BASELINE', 'Module 2 baseline strategy using accepted V1.0 defaults.',
     'Evaluate baseline strategy under broad LGD severity stress.',
     'Broad LGD stress baseline evidence', 'Broad LGD stress baseline', 35, TRUE, CURRENT_TIMESTAMP),

    ('M1-19', 'M2-36', 36, 'SC06', 'LGD Severity Sensitivity', 'CG17', 'VE36',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'LGD_SEVERITY', 'Module 1 scenario applying broad LGD stress.',
     'PRODUCT_GUARDRAILS', 'Applies tighter guardrails to selected unsecured and revolving products.',
     'Evaluate product guardrails under broad LGD severity stress.',
     'Broad LGD guardrail evidence', 'Broad LGD stress product guardrails', 36, TRUE, CURRENT_TIMESTAMP)

ON CONFLICT (module2_run_id)
DO UPDATE SET
    /***********************************************************************************************
    Upsert behavior:
        If the module2_run_id already exists, refresh the registry metadata to the current planned
        definition.

    This keeps Section 2 rerunnable.
    ***********************************************************************************************/
    module1_run_id = EXCLUDED.module1_run_id,
    run_sequence_number = EXCLUDED.run_sequence_number,
    showcase_id = EXCLUDED.showcase_id,
    showcase_name = EXCLUDED.showcase_name,
    comparison_group_id = EXCLUDED.comparison_group_id,
    validation_evidence_group_id = EXCLUDED.validation_evidence_group_id,
    module1_scenario_set_name = EXCLUDED.module1_scenario_set_name,
    module1_scenario_name = EXCLUDED.module1_scenario_name,
    population_id = EXCLUDED.population_id,
    strategy_set_name = EXCLUDED.strategy_set_name,
    strategy_name = EXCLUDED.strategy_name,
    strategy_version = EXCLUDED.strategy_version,
    module1_parameter_family_changed = EXCLUDED.module1_parameter_family_changed,
    module1_parameter_change_summary = EXCLUDED.module1_parameter_change_summary,
    module2_strategy_family_changed = EXCLUDED.module2_strategy_family_changed,
    module2_parameter_change_summary = EXCLUDED.module2_parameter_change_summary,
    expected_storyline = EXCLUDED.expected_storyline,
    validation_summary_section_hint = EXCLUDED.validation_summary_section_hint,
    readme_storyline_label = EXCLUDED.readme_storyline_label,
    linkedin_post_sequence = EXCLUDED.linkedin_post_sequence,
    registry_active_flag = EXCLUDED.registry_active_flag,
    registry_updated_ts = CURRENT_TIMESTAMP;



/***************************************************************************************************
SECTION 2.7 — PERSISTENT STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************

BUSINESS PURPOSE:
    Define planned baseline-versus-challenger comparisons using stable comparison_group_id values.

SQL PURPOSE:
    Create or reuse:
        credit_decisioning_sim.strategy_comparison_campaign_registry

COMPARISON REGISTRY GRAIN:
    One row per planned comparison_group_id.

WHY THIS REGISTRY EXISTS:
    Section 13 performs matched strategy comparison.

    The comparison registry lets users choose a comparison by ID rather than manually editing
    baseline and challenger strategy names each time.

CREDIT RISK TEACHING POINT:
    Matched strategy comparison should isolate downstream Module 2 strategy effects.

    That means baseline and challenger rows should share:
        module1_scenario_set_name,
        module1_scenario_name,
        population_id.

    The strategy fields should differ.

    If the Module 1 source differs, comparison may reflect upstream population / scenario movement
    rather than downstream strategy movement.

SQL MECHANICS:
    comparison_group_id is the primary key.

    The unique technical index prevents duplicate comparison definitions for the same baseline,
    challenger, and Module 1 scenario / population combination.

BOUNDARY:
    The comparison registry does not mutate archive rows.
    The comparison registry does not recalculate strategy outcomes.
    The comparison registry does not replace archive grain.
    The comparison registry is selection metadata for Section 13 and documentation traceability.

****************************************************************************************************/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_comparison_campaign_registry (
    /***********************************************************************************************
    Comparison identity.
    ***********************************************************************************************/
    comparison_group_id                    TEXT PRIMARY KEY,
    comparison_set_name                    TEXT NOT NULL,

    /***********************************************************************************************
    Showcase metadata.
    ***********************************************************************************************/
    showcase_id                            TEXT,
    showcase_name                          TEXT,

    /***********************************************************************************************
    Compact campaign run IDs for baseline and challenger.
    ***********************************************************************************************/
    baseline_module2_run_id                TEXT,
    challenger_module2_run_id              TEXT,

    /***********************************************************************************************
    Baseline strategy technical key.
    ***********************************************************************************************/
    baseline_strategy_set_name             TEXT NOT NULL,
    baseline_strategy_name                 TEXT NOT NULL,
    baseline_strategy_version              TEXT NOT NULL,

    /***********************************************************************************************
    Challenger strategy technical key.
    ***********************************************************************************************/
    challenger_strategy_set_name           TEXT NOT NULL,
    challenger_strategy_name               TEXT NOT NULL,
    challenger_strategy_version            TEXT NOT NULL,

    /***********************************************************************************************
    Matched Module 1 scenario / population key.

    Baseline and challenger comparison must use the same Module 1 scenario and population in Module 2
    V1.0.
    ***********************************************************************************************/
    module1_scenario_set_name              TEXT NOT NULL,
    module1_scenario_name                  TEXT NOT NULL,
    population_id                          TEXT NOT NULL,

    /***********************************************************************************************
    Documentation helper fields.
    ***********************************************************************************************/
    expected_comparison_storyline          TEXT,
    primary_metric_focus                   TEXT,

    /***********************************************************************************************
    Registry control fields.
    ***********************************************************************************************/
    active_comparison_flag                 BOOLEAN NOT NULL DEFAULT FALSE,
    registry_active_flag                   BOOLEAN NOT NULL DEFAULT TRUE,
    registry_created_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registry_updated_ts                    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


/*-----------------------------------------------------------------------------------------------
Comparison technical-key uniqueness index.

Business purpose:
    Prevent duplicate comparison definitions for the same baseline / challenger / Module 1 scenario
    technical setup.

SQL purpose:
    Enforce uniqueness across the comparison technical fields independent of comparison_group_id.
-----------------------------------------------------------------------------------------------*/
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_comparison_campaign_registry_technical_key
ON credit_decisioning_sim.strategy_comparison_campaign_registry (
    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,
    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);



/***************************************************************************************************
SECTION 2.8 — SEED / UPDATE STRATEGY COMPARISON CAMPAIGN REGISTRY
****************************************************************************************************

PURPOSE:
    Seed planned comparison groups for Section 13 matched strategy comparison and later validation
    narrative.

ACTIVE COMPARISON:
    Exactly one comparison should ordinarily have:
        active_comparison_flag = TRUE

    Section 13 will use the active comparison to populate tmp_m2_strategy_comparison_params.

CURRENT DEFAULT:
    CG01 is active by default because it supports the first baseline strategy frontier story:

        BASELINE_STRATEGY
        versus
        TIGHTER_SYNTHETIC_RISK_STRATEGY
        on
        BASELINE_V2

SQL MECHANICS:
    INSERT ... ON CONFLICT (comparison_group_id) DO UPDATE is an upsert.

    This lets the registry be rerun and refreshed without creating duplicate comparison rows.

CREDIT RISK TEACHING POINT:
    Each comparison has a primary_metric_focus.

    This is not the only metric to review.

    It simply identifies the main analytical lens for the comparison, such as:
        approved Expected Loss reduction,
        offer growth,
        PTI discipline,
        counteroffer management,
        product guardrail effect,
        manual-review reduction.

    A strong strategy review should still evaluate the full tradeoff, not only one metric.

****************************************************************************************************/

INSERT INTO credit_decisioning_sim.strategy_comparison_campaign_registry (
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    expected_comparison_storyline,
    primary_metric_focus,

    active_comparison_flag,
    registry_active_flag,
    registry_updated_ts
)
VALUES
    /***********************************************************************************************
    SC01 comparison group:
        Baseline strategy frontier on the Module 1 BASELINE_V2 population.
    ***********************************************************************************************/
    ('CG01', 'BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-02',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter synthetic-risk strategy on the same Module 1 baseline population.',
     'APPROVED_EXPECTED_LOSS_REDUCTION',
     TRUE, TRUE, CURRENT_TIMESTAMP),

    ('CG02', 'BASELINE_V2_BASELINE_STRATEGY_VS_GROWTH_ORIENTED',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-03',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to growth-oriented strategy on the same Module 1 baseline population.',
     'OFFER_GROWTH',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG03', 'BASELINE_V2_BASELINE_STRATEGY_VS_TIGHTER_AFFORDABILITY',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-04',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter affordability strategy on the same Module 1 baseline population.',
     'APPROVED_PTI_DISCIPLINE',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG04', 'BASELINE_V2_BASELINE_STRATEGY_VS_COUNTEROFFER_FIRST',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-05',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to counteroffer-first exposure strategy on the same Module 1 baseline population.',
     'COUNTEROFFER_EXPOSURE_MANAGEMENT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG05', 'BASELINE_V2_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-06',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrail strategy on the same Module 1 baseline population.',
     'PRODUCT_GUARDRAIL_EFFECT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG06', 'BASELINE_V2_BASELINE_STRATEGY_VS_MANUAL_REVIEW_REDUCTION',
     'SC01', 'Baseline Strategy Frontier',
     'M2-01', 'M2-07',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'MANUAL_REVIEW_REDUCTION_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1',
     'Compare baseline strategy to manual-review reduction strategy on the same Module 1 baseline population.',
     'MANUAL_REVIEW_BURDEN_REDUCTION',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC02 comparison group:
        Rate environment sensitivity comparisons.
    ***********************************************************************************************/
    ('CG07', 'RATE_UP_200BP_BASELINE_STRATEGY_VS_TIGHTER_AFFORDABILITY',
     'SC02', 'Rate Environment Sensitivity',
     'M2-08', 'M2-11',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter affordability strategy under 200bp rate stress.',
     'RATE_STRESS_AFFORDABILITY_GUARDRAIL',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG08', 'RATE_UP_300BP_BASELINE_STRATEGY_VS_TIGHTER_AFFORDABILITY',
     'SC02', 'Rate Environment Sensitivity',
     'M2-10', 'M2-12',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_AFFORDABILITY_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter affordability strategy under 300bp rate stress.',
     'STRONG_RATE_STRESS_AFFORDABILITY_GUARDRAIL',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG09', 'RATE_DOWN_200BP_BASELINE_STRATEGY_VS_GROWTH_ORIENTED',
     'SC02', 'Rate Environment Sensitivity',
     'M2-09', 'M2-13',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'GROWTH_ORIENTED_STRATEGY', 'V1_0',
     'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1',
     'Compare baseline strategy to growth-oriented strategy under 200bp rate relief.',
     'RATE_RELIEF_GROWTH_OPPORTUNITY',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC03 comparison group:
        Credit box sensitivity comparisons.
    ***********************************************************************************************/
    ('CG10', 'NEAR_PRIME_EXPANSION_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
     'SC03', 'Credit Box Sensitivity',
     'M2-16', 'M2-17',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter synthetic-risk strategy under near-prime expansion.',
     'NEAR_PRIME_RISK_DISCIPLINE',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG11', 'NEAR_PRIME_EXPANSION_BASELINE_STRATEGY_VS_COUNTEROFFER_FIRST',
     'SC03', 'Credit Box Sensitivity',
     'M2-16', 'M2-18',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to counteroffer-first strategy under near-prime expansion.',
     'NEAR_PRIME_COUNTEROFFER_MANAGEMENT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG12', 'CREDIT_STRESS_BASELINE_STRATEGY_VS_TIGHTER_SYNTHETIC_RISK',
     'SC03', 'Credit Box Sensitivity',
     'M2-19', 'M2-20',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'TIGHTER_SYNTHETIC_RISK_STRATEGY', 'V1_0',
     'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to tighter synthetic-risk strategy under credit-stress score mix.',
     'CREDIT_STRESS_RISK_DISCIPLINE',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC04 comparison group:
        Product mix sensitivity comparisons.
    ***********************************************************************************************/
    ('CG13', 'UNSECURED_GROWTH_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC04', 'Portfolio Mix Sensitivity',
     'M2-22', 'M2-23',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under unsecured-growth product mix.',
     'UNSECURED_GROWTH_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG14', 'REVOLVING_EXPANSION_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC04', 'Portfolio Mix Sensitivity',
     'M2-25', 'M2-26',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under revolving-line expansion.',
     'REVOLVING_EXPANSION_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC05 comparison group:
        Exposure intensity sensitivity comparisons.
    ***********************************************************************************************/
    ('CG15', 'HIGH_BALANCE_BASELINE_STRATEGY_VS_COUNTEROFFER_FIRST',
     'SC05', 'Exposure Intensity Sensitivity',
     'M2-28', 'M2-29',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY', 'V1_0',
     'MODULE1_V2_EXPOSURE_INTENSITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1',
     'Compare baseline strategy to counteroffer-first strategy under high-balance appetite.',
     'HIGH_BALANCE_COUNTEROFFER_MANAGEMENT',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    /***********************************************************************************************
    SC06 comparison group:
        LGD severity sensitivity comparisons.
    ***********************************************************************************************/
    ('CG16', 'UNSECURED_SEVERITY_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC06', 'LGD Severity Sensitivity',
     'M2-33', 'M2-34',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under unsecured severity stress.',
     'UNSECURED_SEVERITY_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP),

    ('CG17', 'BROAD_LGD_STRESS_BASELINE_STRATEGY_VS_PRODUCT_GUARDRAILS',
     'SC06', 'LGD Severity Sensitivity',
     'M2-35', 'M2-36',
     'MODULE2_BASELINE_STRATEGY_SET', 'BASELINE_STRATEGY', 'V1_0',
     'MODULE2_BASELINE_STRATEGY_SET', 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY', 'V1_0',
     'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1',
     'Compare baseline strategy to product-specific guardrails under broad LGD stress.',
     'BROAD_LGD_PRODUCT_GUARDRAILS',
     FALSE, TRUE, CURRENT_TIMESTAMP)

ON CONFLICT (comparison_group_id)
DO UPDATE SET
    /***********************************************************************************************
    Upsert behavior:
        Refresh comparison registry metadata when the comparison_group_id already exists.
    ***********************************************************************************************/
    comparison_set_name = EXCLUDED.comparison_set_name,
    showcase_id = EXCLUDED.showcase_id,
    showcase_name = EXCLUDED.showcase_name,
    baseline_module2_run_id = EXCLUDED.baseline_module2_run_id,
    challenger_module2_run_id = EXCLUDED.challenger_module2_run_id,
    baseline_strategy_set_name = EXCLUDED.baseline_strategy_set_name,
    baseline_strategy_name = EXCLUDED.baseline_strategy_name,
    baseline_strategy_version = EXCLUDED.baseline_strategy_version,
    challenger_strategy_set_name = EXCLUDED.challenger_strategy_set_name,
    challenger_strategy_name = EXCLUDED.challenger_strategy_name,
    challenger_strategy_version = EXCLUDED.challenger_strategy_version,
    module1_scenario_set_name = EXCLUDED.module1_scenario_set_name,
    module1_scenario_name = EXCLUDED.module1_scenario_name,
    population_id = EXCLUDED.population_id,
    expected_comparison_storyline = EXCLUDED.expected_comparison_storyline,
    primary_metric_focus = EXCLUDED.primary_metric_focus,
    active_comparison_flag = EXCLUDED.active_comparison_flag,
    registry_active_flag = EXCLUDED.registry_active_flag,
    registry_updated_ts = CURRENT_TIMESTAMP;


/*-----------------------------------------------------------------------------------------------
Governance control:
    At most one comparison should be active for Section 13 default comparison selection.

SQL note:
    This is a partial unique index.

    It applies only where active_comparison_flag IS TRUE.

    Therefore many inactive comparison rows can exist, but only one active row is allowed.
-----------------------------------------------------------------------------------------------*/
CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_comparison_campaign_registry_one_active
ON credit_decisioning_sim.strategy_comparison_campaign_registry (active_comparison_flag)
WHERE active_comparison_flag IS TRUE;



/***************************************************************************************************
SECTION 2.9 — REGISTRY SETUP REVIEW OUTPUTS
****************************************************************************************************

PURPOSE:
    Provide lightweight review outputs confirming the current active strategy parameter row and the
    registry mappings available for the current run.

BUSINESS PURPOSE:
    Give the user a quick Section 2 checkpoint before running Section 3 fail-fast gatekeepers and
    downstream strategy logic.

SQL PURPOSE:
    1. Display the active strategy parameter row.
    2. Display the campaign registry row that matches the active strategy technical key.
    3. Display the active comparison registry row used by Section 13.

INTERPRETATION:
    These are setup diagnostics only.

    Section 3 performs formal fail-fast checks.

    Section 13 uses the active comparison registry for matched comparison.

    Section 16 uses the run campaign registry for evidence capture.

WHAT TO REVIEW:
    In the active strategy output:
        Confirm strategy_name, strategy_run_id, Module 1 source fields, archive controls, and
        failed_counteroffer_resolution.

    In the campaign registry match output:
        Confirm module1_run_id, module2_run_id, showcase_id, comparison_group_id,
        validation_evidence_group_id, and expected_storyline.

    In the active comparison output:
        Confirm the selected baseline / challenger pair is the comparison intended for Section 13.

SQL LEARNING POINT:
    These SELECT statements do not mutate data.

    They are read-only review outputs that expose whether Section 2 setup aligns with the intended
    current run.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
2.9A Current active Module 2 strategy parameter row.

Purpose:
    Confirm the single active strategy card driving the current run.

Expected result:
    One row.

If zero or multiple rows appear:
    Section 3 will fail the active-strategy cardinality gatekeeper.
-----------------------------------------------------------------------------------------------*/

SELECT
    active_strategy_flag,
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,
    campaign_registry_required_flag,
    module1_input_source,
    source_module1_scenario_set_name,
    source_module1_scenario_name,
    source_population_id,
    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution
FROM tmp_module2_strategy_params
WHERE active_strategy_flag IS TRUE;



/*-----------------------------------------------------------------------------------------------
2.9B Campaign registry row matching the current active strategy technical key.

Purpose:
    Confirm that the active strategy parameter row maps to a formal campaign registry row.

SQL mechanics:
    The JOIN links the active strategy parameter row to the persistent campaign registry using the
    exact technical key:

        Module 1 scenario set,
        Module 1 scenario name,
        population,
        strategy set,
        strategy name,
        strategy version.

Interpretation:
    If campaign_registry_required_flag = TRUE and this query returns no rows, Section 3 / Section 16
    should treat the run as not formally registry-matched.
-----------------------------------------------------------------------------------------------*/

SELECT
    r.module1_run_id,
    r.module2_run_id,
    r.run_sequence_number,
    r.showcase_id,
    r.showcase_name,
    r.comparison_group_id,
    r.validation_evidence_group_id,
    r.module1_scenario_set_name,
    r.module1_scenario_name,
    r.population_id,
    r.strategy_set_name,
    r.strategy_name,
    r.strategy_version,
    r.module1_parameter_family_changed,
    r.module2_strategy_family_changed,
    r.expected_storyline,
    r.readme_storyline_label,
    r.linkedin_post_sequence,
    r.registry_active_flag
FROM credit_decisioning_sim.strategy_run_campaign_registry r
JOIN tmp_module2_strategy_params sp
    ON sp.active_strategy_flag IS TRUE
   AND r.module1_scenario_set_name = sp.source_module1_scenario_set_name
   AND r.module1_scenario_name = sp.source_module1_scenario_name
   AND r.population_id = sp.source_population_id
   AND r.strategy_set_name = sp.strategy_set_name
   AND r.strategy_name = sp.strategy_name
   AND r.strategy_version = sp.strategy_version;



/*-----------------------------------------------------------------------------------------------
2.9C Active comparison registry row for Section 13 default matched-comparison selection.

Purpose:
    Confirm which comparison group Section 13 should use.

Expected result:
    One active comparison row.

If more than one row is active:
    the partial unique index should prevent that condition when the registry is valid.

Interpretation:
    This output is especially important before running Section 13 matched comparison.
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,
    baseline_module2_run_id,
    challenger_module2_run_id,
    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,
    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    expected_comparison_storyline,
    primary_metric_focus,
    active_comparison_flag,
    registry_active_flag
FROM credit_decisioning_sim.strategy_comparison_campaign_registry
WHERE active_comparison_flag IS TRUE
ORDER BY comparison_group_id;



/***************************************************************************************************
END OF SECTION 2 — STRATEGY PARAMETER, PRODUCT POLICY, AND CAMPAIGN REGISTRY FRAMEWORK

If execution reaches this point:
    1. The active Module 2 strategy parameter row exists.
    2. The product-specific policy parameter table exists.
    3. Product-policy defaults have been inserted.
    4. The persistent strategy run campaign registry exists.
    5. The persistent strategy comparison campaign registry exists.
    6. The campaign registry has been seeded / updated with planned run IDs.
    7. The comparison registry has been seeded / updated with planned comparison IDs.
    8. Stable run IDs and comparison IDs are available for validation-summary traceability.
    9. Review outputs show the current active strategy and registry mappings.

No Module 1 source rows have been consumed.
No strategy outcomes have been assigned.
No preliminary routes have been assigned.
No approved exposure has been calculated.
No approved Expected Loss has been calculated.
No simulated reason codes have been assigned.
No latest-run output has been created.
No archive rows have been inserted.
No QA validation has been performed.
No executive evidence rows have been captured.
No written validation conclusions have been drafted.

Next section:
    Section 3 should run fail-fast strategy, source-selection, product-policy, archive-control, and
    registry gatekeepers before downstream strategy logic is built.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00896 -->


---

<a id="c038-m00898"></a>

### C038-M00898

**Andrew** · 2026-05-09T23:10:55.966000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00898 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 3 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00898 -->


**Attachments in export:** `Pasted text(141).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_39.md) · [Next](Part_41.md)
