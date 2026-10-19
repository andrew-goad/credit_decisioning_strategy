# Module 2 Decision Simulator Build

## Part 02

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_01.md) · [Next](Part_03.md)

<a id="c038-m00052"></a>

### C038-M00052

**ChatGPT** · 2026-05-06T11:08:08.966100-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00052 -->
One implementation clarification before the SQL: I split the previously stated single “review / decline boundary” for requested Expected Loss into separate `product_review_max_requested_el` and `product_decline_min_requested_el` parameters. The defaults preserve the same intent but give later decision logic a cleaner review band before a hard simulated policy stop.

This first build follows Module 1’s governed parameter-layer and fail-fast gatekeeper pattern, while preserving the documented Module 1 boundaries around synthetic data, scenario lineage, the synthetic estimated-PD proxy, and comparative Expected Loss. fileciteturn4file0 It also preserves the validated deterministic / matched-scenario foundation confirmed in the Module 1 Validation Summary. fileciteturn4file1

```sql
/***************************************************************************************************
MODULE 2 — CREDIT POLICY STRATEGY & DECISION OUTCOME SIMULATION ENGINE v1.0
Enterprise Credit Decisioning Strategy Simulator

SQL SCRIPT:
module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0.sql

SECTIONS INCLUDED IN THIS BUILD:
    Section 0 — Executive Purpose, Boundaries, and SQL Section Map
    Section 1 — Schema Setup / Clean Rerun Reset for Module 2 Temporary Objects
    Section 2 — Strategy Parameter Framework and Product Policy Parameter Framework
    Section 3 — Fail-Fast Strategy Parameter Gatekeeper

SECTIONS INTENTIONALLY NOT INCLUDED YET:
    Section 4+ source-selection staging
    derived strategy segments
    rule flags
    decision hierarchy
    reason-code assignment
    approved exposure calculation
    approved Expected Loss calculation
    latest-run final output creation
    archive insert logic
    QA / strategy comparison queries

AUTHORING STANDARD:
    This script is intentionally written as both executable SQL and a governed design artifact.
    Comments explain the business purpose, SQL purpose, modeling boundary, and validation intent
    behind each parameter family and gatekeeper.

POSTGRESQL TARGET:
    PostgreSQL

***************************************************************************************************/


/***************************************************************************************************
SECTION 0 — EXECUTIVE PURPOSE, MODULE 2 BOUNDARIES, AND SQL SECTION MAP
****************************************************************************************************

0.1 MODULE 2 PURPOSE
----------------------------------------------------------------------------------------------------
Module 2 consumes finalized Module 1 synthetic application and risk outputs and applies a governed
simulated credit strategy layer.

The business question answered by later Module 2 sections will be:

    "Under this simulated strategy, what strategy outcome would this synthetic applicant trigger?"

The locked Module 2 v1.0 primary decision_outcome taxonomy is:

    APPROVE
    COUNTEROFFER
    MANUAL_REVIEW
    DECLINE

COUNTEROFFER is a distinct primary decision_outcome.
Detailed counteroffer type will be captured later in decision_path.


0.2 RELATIONSHIP TO MODULE 1
----------------------------------------------------------------------------------------------------
Module 1 remains authoritative and is not redesigned by Module 2.

Module 2 consumes Module 1 outputs such as:

    application_id
    applicant_id
    product_type
    score_band
    credit_score
    requested_amount
    annual_income
    monthly_payment_proxy
    payment_to_income_ratio
    debt_to_income_ratio
    estimated_pd
    estimated_lgd
    expected_loss_amount
    scenario_set_name / module1_scenario_set_name
    scenario_name     / module1_scenario_name
    population_id

Module 2 output naming will later alias:

    Module 1 scenario_set_name     -> module1_scenario_set_name
    Module 1 scenario_name         -> module1_scenario_name
    Module 1 expected_loss_amount  -> requested_expected_loss_amount

This avoids overloading Module 1 scenario terminology with Module 2 strategy terminology.


0.3 ESTIMATED-PD PROXY TERMINOLOGY NOTE
----------------------------------------------------------------------------------------------------
The finalized Module 1 SQL field is named:

    estimated_pd

Module 2 v1.0 consumes that field as-is.

However, in comments, documentation, QA interpretation, and business explanation, estimated_pd must
be interpreted as the:

    synthetic estimated-PD proxy

Module 2 v1.0 does NOT recalculate estimated_pd.
Module 2 v1.0 does NOT create a post-decision risk model.
Module 2 v1.0 does NOT treat estimated_pd as a calibrated production probability of default.

The synthetic estimated-PD proxy is a governed Module 1 risk-translation input used by Module 2 for
policy simulation, segmentation, and approved-exposure Expected Loss calculations.


0.4 REASON-CODE BOUNDARY
----------------------------------------------------------------------------------------------------
Later Module 2 sections will assign simulated reason codes.

These codes are:

    simulated strategy explanation codes
    simulated policy reasons
    decision-path reasons
    policy stop reasons
    review trigger reasons
    counteroffer reasons

They are NOT regulatory adverse-action reasons.
They are NOT compliance-approved customer communication codes.
They are NOT production decision notices.

Reason-code purpose in Module 2:

    strategy transparency
    QA review
    segmentation analysis
    decision-path traceability
    portfolio interpretation


0.5 APPROVED EXPOSURE BOUNDARY
----------------------------------------------------------------------------------------------------
Later Module 2 sections will calculate:

    approved_amount
    counteroffer_amount
    approved_monthly_payment_proxy
    approved_payment_to_income_ratio
    approved_expected_loss_amount

These are simulated strategy outputs only.

Approved exposure in Module 2 means:

    simulated offer exposure under a strategy

It does NOT mean:

    booked account exposure
    real customer approval
    operational account opening
    final underwriting decision

For this reason, the locked inclusion flag is:

    simulated_offer_exposure_flag

Do NOT use:

    booked_exposure_flag

because "booked" can imply real account booking, which is outside the Module 2 boundary.


0.6 LOCKED OUTCOME CONVENTIONS FOR LATER SECTIONS
----------------------------------------------------------------------------------------------------
These conventions are locked here so later CASE logic remains unambiguous.

APPROVE:
    approved_amount                    = requested_amount
    counteroffer_amount                = NULL
    approved_monthly_payment_proxy     = monthly_payment_proxy
    approved_payment_to_income_ratio   = payment_to_income_ratio
    approved_expected_loss_amount      = approved_amount * estimated_pd * estimated_lgd
    simulated_offer_exposure_flag      = TRUE
    primary_reason_code                = APPROVED_AS_REQUESTED

COUNTEROFFER:
    approved_amount                    < requested_amount
    counteroffer_amount                = approved_amount
    exposure_reduction_flag            = TRUE
    exposure_reduction_amount          = requested_amount - approved_amount
    exposure_reduction_pct             = exposure_reduction_amount / NULLIF(requested_amount, 0)
    approved_monthly_payment_proxy     =
        monthly_payment_proxy * approved_amount / NULLIF(requested_amount, 0)
    approved_payment_to_income_ratio   =
        approved_monthly_payment_proxy / NULLIF((annual_income / 12.0), 0)
    approved_expected_loss_amount      = approved_amount * estimated_pd * estimated_lgd
    simulated_offer_exposure_flag      = TRUE

DECLINE:
    approved_amount                    = 0
    counteroffer_amount                = NULL
    approved_monthly_payment_proxy     = 0
    approved_payment_to_income_ratio   = 0
    approved_expected_loss_amount      = 0
    simulated_offer_exposure_flag      = FALSE

MANUAL_REVIEW:
    approved_amount                    = NULL
    counteroffer_amount                = NULL
    approved_monthly_payment_proxy     = NULL
    approved_payment_to_income_ratio   = NULL
    approved_expected_loss_amount      = NULL
    simulated_offer_exposure_flag      = FALSE

Manual review is unresolved by design.


0.7 MODULE 1 SCENARIO METADATA VS MODULE 2 STRATEGY METADATA
----------------------------------------------------------------------------------------------------
Module 1 scenario metadata describes the upstream synthetic population and risk environment:

    module1_scenario_set_name
    module1_scenario_name
    population_id

Module 2 strategy metadata describes the downstream simulated decision strategy:

    strategy_set_name
    strategy_name
    strategy_version
    strategy_run_id
    strategy_run_ts

Do not overload scenario_name to mean decision strategy.


0.8 LOCKED PHYSICAL ARCHITECTURE FOR LATER SECTIONS
----------------------------------------------------------------------------------------------------
Latest-run strategy decision table:

    credit_decisioning_sim.strategy_decisions

Strategy decision archive table:

    credit_decisioning_sim.strategy_decisions_archive

Archive grain:

    one row per application
    x Module 1 scenario
    x Module 2 strategy version

Archive grain fields:

    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
    application_id

Archive replacement / rerun key:

    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

The replacement / rerun key intentionally excludes application_id.
The row-level archive grain additionally includes application_id.


0.9 HIGH-LEVEL SQL SECTION MAP
----------------------------------------------------------------------------------------------------
Section 0  — Executive purpose, boundaries, terminology, and section map
Section 1  — Schema setup and clean reset of temporary Module 2 objects
Section 2  — Strategy parameter framework and product policy parameter framework
Section 3  — Fail-fast strategy parameter gatekeeper

Future sections, not included in this build:

Section 4  — Module 1 source-selection and lineage-normalization layer
Section 5  — Derived strategy segmentation layer
Section 6  — Rule flag construction
Section 7  — Decision hierarchy
Section 8  — Simulated reason-code assignment
Section 9  — Approved exposure calculation
Section 10 — Approved Expected Loss calculation
Section 11 — Latest-run strategy output table creation
Section 12 — Strategy archive persistence
Section 13 — Validation, QA, and Strategy Tuning Pass
Section 14 — Matched strategy comparison queries

***************************************************************************************************/



/***************************************************************************************************
SECTION 1 — SCHEMA SETUP / CLEAN RERUN RESET
****************************************************************************************************

BUSINESS PURPOSE:
    Reuse the dedicated simulation schema established by Module 1 and prepare the current Module 2
    run for a clean parameter and gatekeeper build.

SQL PURPOSE:
    1. Ensure the credit_decisioning_sim schema exists.
    2. Set the search path so permanent simulator objects are resolved consistently.
    3. Drop temporary Module 2 parameter objects from prior attempts.
    4. Drop the latest-run Module 2 output table for clean rerun behavior.
    5. Preserve the Module 2 archive table by default.

GOVERNANCE RATIONALE:
    The latest-run table should represent only the current completed Module 2 strategy output.
    It is safe to drop and recreate in later sections.

    The archive table is different. It is the governed history layer for completed strategy runs
    and must not be dropped casually.

IMPORTANT:
    This first build does NOT create the final strategy_decisions table yet.
    This first build does NOT insert into the strategy_decisions_archive table yet.
    Those actions occur only after the source-selection, decision logic, reason-code, and approved
    exposure layers are built.

***************************************************************************************************/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;


/*-----------------------------------------------------------------------------------------------
Clean reset of temporary Module 2 objects.

These temp tables are parameter and validation objects only. They are safe to drop at the beginning
of each development run because they do not contain persisted strategy decisions.
-----------------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS tmp_module2_strategy_params;
DROP TABLE IF EXISTS tmp_module2_product_policy_params;


/*-----------------------------------------------------------------------------------------------
Clean reset of latest-run Module 2 output.

This table will be recreated in a later section after the decision logic is built. Dropping it now
prevents stale strategy outputs from being mistaken for current results during early development.

The strategy archive table is intentionally NOT dropped here.
-----------------------------------------------------------------------------------------------*/
DROP TABLE IF EXISTS credit_decisioning_sim.strategy_decisions;


/*-----------------------------------------------------------------------------------------------
Archive preservation rule.

Do not drop this table by default:

    credit_decisioning_sim.strategy_decisions_archive

Archive creation and insert logic are intentionally deferred until the final output schema is built.
-----------------------------------------------------------------------------------------------*/



/***************************************************************************************************
SECTION 2 — STRATEGY PARAMETER FRAMEWORK AND PRODUCT POLICY PARAMETER FRAMEWORK
****************************************************************************************************

BUSINESS PURPOSE:
    Centralize all Module 2 v1.0 strategy assumptions before any decision logic is written.

SQL PURPOSE:
    Create temporary parameter tables that later sections will join to Module 1 source outputs.

DESIGN PRINCIPLES:
    Parameterized over hard-coded:
        Strategy thresholds, product exposure limits, and output conventions are declared here.

    Product-aware over generic:
        Product policy parameters differ across Mortgage, HELOC, Auto Loan, Unsecured Personal
        Loan, and Revolving Line.

    Boundary-aware over production-claiming:
        These thresholds are synthetic strategy defaults for simulation. They are not production
        underwriting rules, not empirically calibrated cutoffs, and not customer treatment policy.

    Validation-first over output-only:
        Section 3 will fail fast if these assumptions are incomplete, incoherent, or unsafe.

***************************************************************************************************/


/***************************************************************************************************
SECTION 2.1 — STRATEGY PARAMETER TABLE
****************************************************************************************************

TABLE:
    tmp_module2_strategy_params

GRAIN:
    One active row for the selected strategy run.

WHY ONE ACTIVE ROW:
    A single strategy run must have exactly one strategy identity, one source-selection definition,
    one set of global thresholds, one archive-control convention, and one output-convention set.
    Multiple active rows would create ambiguous decision logic.

PARAMETER FAMILIES:
    1. Strategy identity
    2. Module 1 source selection
    3. Archive controls
    4. Global synthetic estimated-PD proxy thresholds
    5. Global PTI thresholds
    6. DTI thresholds
    7. Decision convention controls

***************************************************************************************************/

CREATE TEMP TABLE tmp_module2_strategy_params (
    /* Strategy identity */
    active_strategy_flag                         BOOLEAN,
    module2_model_version                        TEXT,
    strategy_set_name                            TEXT,
    strategy_name                                TEXT,
    strategy_version                             TEXT,
    strategy_run_id                              TEXT,
    strategy_run_ts                              TIMESTAMPTZ,

    /* Module 1 source selection */
    module1_input_source                         TEXT,
    source_module1_scenario_set_name             TEXT,
    source_module1_scenario_name                 TEXT,
    source_population_id                         TEXT,

    /* Archive controls */
    archive_run_flag                             BOOLEAN,
    strategy_archive_reset_mode                  TEXT,

    /* Global synthetic estimated-PD proxy thresholds */
    approve_max_estimated_pd_proxy               NUMERIC(12,6),
    counteroffer_max_estimated_pd_proxy          NUMERIC(12,6),
    review_max_estimated_pd_proxy                NUMERIC(12,6),
    decline_min_estimated_pd_proxy               NUMERIC(12,6),

    /* Global PTI thresholds */
    global_approve_max_pti                       NUMERIC(12,6),
    global_review_max_pti                        NUMERIC(12,6),
    global_decline_min_pti                       NUMERIC(12,6),

    /* DTI thresholds */
    approve_max_dti                              NUMERIC(12,6),
    review_max_dti                               NUMERIC(12,6),
    decline_min_dti                              NUMERIC(12,6),

    /* Decision convention controls */
    approve_reason_code                          TEXT,
    reason_code_required_flag                    BOOLEAN,
    simulated_offer_exposure_flag_enabled        BOOLEAN,
    manual_review_approved_amount_convention     TEXT,
    decline_approved_amount_convention           TEXT,
    approved_el_decline_convention               TEXT,
    approved_el_manual_review_convention         TEXT,
    allow_approved_amount_above_requested_flag   BOOLEAN
) ON COMMIT PRESERVE ROWS;


/*-----------------------------------------------------------------------------------------------
Default strategy row.

These defaults define an initial baseline simulated strategy. They are deliberately conservative
enough to produce meaningful APPROVE / COUNTEROFFER / MANUAL_REVIEW / DECLINE separation later,
but they are not production policy and are not empirically calibrated cutoffs.

module1_input_source:
    LATEST is the default for initial development and QA.
    ARCHIVE should be used later when comparing strategies against a specific archived Module 1
    scenario slice.

strategy_run_id:
    This is audit metadata. It supports run traceability but does not replace the archive
    replacement / rerun key.

Archive replacement / rerun key, later:
    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id
-----------------------------------------------------------------------------------------------*/

INSERT INTO tmp_module2_strategy_params (
    active_strategy_flag,
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

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

    approve_reason_code,
    reason_code_required_flag,
    simulated_offer_exposure_flag_enabled,
    manual_review_approved_amount_convention,
    decline_approved_amount_convention,
    approved_el_decline_convention,
    approved_el_manual_review_convention,
    allow_approved_amount_above_requested_flag
)
VALUES (
    TRUE,
    'MODULE2_CREDIT_POLICY_STRATEGY_ENGINE_V1_0',
    'MODULE2_BASELINE_STRATEGY_SET',
    'BASELINE_STRATEGY',
    'V1_0',
    'M2_BASELINE_STRATEGY_V1_0_' || TO_CHAR(CLOCK_TIMESTAMP(), 'YYYYMMDDHH24MISSMS'),
    CLOCK_TIMESTAMP(),

    'LATEST',
    NULL,
    NULL,
    NULL,

    TRUE,
    'STRATEGY_SCENARIO_ONLY',

    /* Synthetic estimated-PD proxy thresholds.
       These govern later simulated strategy routing, not production risk scoring. */
    0.120000,  -- Clean approval ceiling for lower-to-moderate synthetic estimated-risk profiles.
    0.300000,  -- Upper synthetic estimated-risk level eligible for reduced exposure treatment.
    0.350000,  -- Upper manual review governance boundary.
    0.350000,  -- Hard simulated risk stop at or above this value.

    /* Global PTI thresholds.
       Product-specific PTI thresholds in the product policy table will override these later. */
    0.200000,  -- Default clean approval PTI ceiling before product override.
    0.500000,  -- Default review-zone PTI upper boundary.
    0.500000,  -- Default severe PTI stop where unresolved.

    /* DTI thresholds.
       DTI is treated as an existing-obligation capacity signal, not as exposure-adjustable PTI. */
    0.430000,  -- Clean approval DTI ceiling.
    0.600000,  -- Manual review DTI upper boundary.
    0.600000,  -- Hard simulated DTI stop at or above this value.

    /* Decision convention controls. */
    'APPROVED_AS_REQUESTED',
    TRUE,
    TRUE,
    'NULL_UNRESOLVED',
    'ZERO',
    'ZERO',
    'NULL_UNRESOLVED',
    FALSE
);



/***************************************************************************************************
SECTION 2.2 — PRODUCT POLICY PARAMETER TABLE
****************************************************************************************************

TABLE:
    tmp_module2_product_policy_params

GRAIN:
    One row per supported Module 1 product_type.

SUPPORTED MODULE 1 PRODUCT SET:
    MORTGAGE
    HELOC
    AUTO_LOAN
    UNSECURED_PERSONAL_LOAN
    REVOLVING_LINE

WHY PRODUCT-SPECIFIC PARAMETERS:
    Module 1 is product-aware. Module 2 must preserve that design principle.

    A mortgage, HELOC, auto loan, unsecured personal loan, and revolving line do not carry the same:
        exposure scale
        payment behavior
        affordability sensitivity
        LGD profile
        Expected Loss tolerance
        counteroffer flexibility

    Therefore, Module 2 strategy parameters must be product-aware rather than generic.

THRESHOLD INTERPRETATION:
    These are initial synthetic strategy defaults intended for simulation and QA tuning.
    They are not production underwriting policy.
    They are not customer treatment rules.
    They are not empirically calibrated cutoffs.

***************************************************************************************************/

CREATE TEMP TABLE tmp_module2_product_policy_params (
    /* Product identity */
    product_type                            TEXT,

    /* Product-specific PTI thresholds */
    product_approve_max_pti                 NUMERIC(12,6),
    product_review_max_pti                  NUMERIC(12,6),
    product_decline_min_pti                 NUMERIC(12,6),
    counteroffer_target_pti                 NUMERIC(12,6),

    /* Requested-exposure Expected Loss thresholds */
    product_approve_max_requested_el         NUMERIC(18,2),
    product_review_max_requested_el          NUMERIC(18,2),
    product_decline_min_requested_el         NUMERIC(18,2),
    product_approved_el_cap                  NUMERIC(18,2),

    /* Approved exposure limits */
    product_min_approved_amount              NUMERIC(18,2),
    product_max_approved_amount              NUMERIC(18,2),

    /* Counteroffer and manual review controls */
    counteroffer_allowed_flag                BOOLEAN,
    manual_review_allowed_flag               BOOLEAN,
    product_min_counteroffer_pct             NUMERIC(12,6),
    product_max_exposure_reduction_pct       NUMERIC(12,6),
    exposure_assignment_method               TEXT,

    /* Approved amount rounding */
    approved_amount_rounding_increment       NUMERIC(18,2)
) ON COMMIT PRESERVE ROWS;


/*-----------------------------------------------------------------------------------------------
Product policy defaults.

PTI defaults:
    Mortgage can support higher PTI than unsecured products because Module 1 mortgage structure
    reflects long-term secured amortization.
    Revolving and unsecured personal loan thresholds are tighter because payment burden can create
    faster affordability pressure.

Expected Loss defaults:
    Requested Expected Loss thresholds are higher for larger secured products and lower for smaller
    or higher-LGD unsecured products.
    The approved EL cap is the later approved-exposure loss appetite after counteroffer treatment.

Exposure defaults:
    Approved exposure caps are lower than or equal to practical product ceilings to allow Module 2
    to simulate exposure treatment independently from the Module 1 requested amount.

Counteroffer defaults:
    Mortgage and auto are less flexible because the requested amount may be tied to an asset purchase.
    HELOC, unsecured personal loan, and revolving line are more flexible because line / amount
    adjustment is more natural in a strategy simulator.
-----------------------------------------------------------------------------------------------*/

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
    (
        'MORTGAGE',
        0.360000, 0.550000, 0.550000, 0.360000,
        15000.00, 25000.00, 35000.00, 15000.00,
        75000.00, 1000000.00,
        TRUE, TRUE,
        0.800000, 0.200000, 'MIN_OF_CAPS',
        1000.00
    ),
    (
        'HELOC',
        0.250000, 0.450000, 0.450000, 0.250000,
        10000.00, 16000.00, 22000.00, 10000.00,
        10000.00, 200000.00,
        TRUE, TRUE,
        0.500000, 0.500000, 'MIN_OF_CAPS',
        500.00
    ),
    (
        'AUTO_LOAN',
        0.180000, 0.400000, 0.400000, 0.180000,
        6000.00, 9000.00, 12000.00, 6000.00,
        5000.00, 65000.00,
        TRUE, TRUE,
        0.750000, 0.250000, 'MIN_OF_CAPS',
        100.00
    ),
    (
        'UNSECURED_PERSONAL_LOAN',
        0.160000, 0.350000, 0.350000, 0.160000,
        6000.00, 9000.00, 12000.00, 6000.00,
        1000.00, 35000.00,
        TRUE, TRUE,
        0.500000, 0.500000, 'MIN_OF_CAPS',
        100.00
    ),
    (
        'REVOLVING_LINE',
        0.120000, 0.300000, 0.300000, 0.120000,
        4500.00, 6500.00, 9000.00, 4500.00,
        1000.00, 25000.00,
        TRUE, TRUE,
        0.500000, 0.500000, 'MIN_OF_CAPS',
        100.00
    );



/***************************************************************************************************
SECTION 3 — FAIL-FAST STRATEGY PARAMETER GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Prevent invalid strategy configuration from producing misleading simulated strategy outcomes.

SQL PURPOSE:
    Run validation checks before any Module 1 source-selection, rule flags, decision hierarchy,
    reason-code assignment, approved exposure calculation, or output creation occurs.

FAIL-FAST PRINCIPLE:
    A failed parameter run is preferable to a completed run with incoherent strategy assumptions.

GATEKEEPER FAMILIES:
    3.1 Strategy parameter cardinality and identity validation
    3.2 Strategy threshold and output-convention validation
    3.3 Product policy parameter validation
    3.4 Source-input validation against Module 1 latest or archive outputs
    3.5 Threshold equality convention documentation for later CASE logic

***************************************************************************************************/


/***************************************************************************************************
SECTION 3.0 — LOCKED THRESHOLD EQUALITY CONVENTIONS FOR LATER CASE LOGIC
****************************************************************************************************

These conventions are documented now so later Section 6 / Section 7 CASE blocks are not ambiguous.

Synthetic estimated-PD proxy:
    APPROVE eligibility:
        estimated_pd <= approve_max_estimated_pd_proxy

    COUNTEROFFER eligibility:
        estimated_pd > approve_max_estimated_pd_proxy
        AND estimated_pd <= counteroffer_max_estimated_pd_proxy

    MANUAL_REVIEW:
        estimated_pd > counteroffer_max_estimated_pd_proxy
        AND estimated_pd < decline_min_estimated_pd_proxy

    DECLINE:
        estimated_pd >= decline_min_estimated_pd_proxy

    Note:
        estimated_pd is the Module 1 SQL column.
        Its interpretation is the synthetic estimated-PD proxy.

PTI:
    APPROVE eligibility:
        payment_to_income_ratio <= product_approve_max_pti

    COUNTEROFFER eligibility:
        payment_to_income_ratio > product_approve_max_pti
        AND counteroffer can reduce approved_payment_to_income_ratio to the target

    MANUAL_REVIEW:
        payment_to_income_ratio > product_approve_max_pti
        AND payment_to_income_ratio < product_decline_min_pti
        where counteroffer is not cleanly viable

    DECLINE:
        payment_to_income_ratio >= product_decline_min_pti
        and no viable counteroffer or intended review path exists

DTI:
    APPROVE eligibility:
        debt_to_income_ratio <= approve_max_dti

    MANUAL_REVIEW:
        debt_to_income_ratio > approve_max_dti
        AND debt_to_income_ratio < decline_min_dti

    DECLINE:
        debt_to_income_ratio >= decline_min_dti

Requested Expected Loss:
    Clean approval must satisfy:
        requested_expected_loss_amount <= product_approve_max_requested_el

    Counteroffer may be considered when:
        requested_expected_loss_amount exceeds clean approval tolerance
        but approved_expected_loss_amount can satisfy product_approved_el_cap

    Decline / review boundary:
        product_review_max_requested_el and product_decline_min_requested_el define the
        intermediate and severe requested-exposure Expected Loss zones for later strategy hierarchy.

***************************************************************************************************/



/***************************************************************************************************
SECTION 3.1 — STRATEGY PARAMETER CARDINALITY, IDENTITY, THRESHOLD, AND CONVENTION VALIDATION
***************************************************************************************************/

DO $$
DECLARE
    v_active_count INTEGER;
    p RECORD;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active strategy row.

    Why this matters:
        The downstream strategy logic must be driven by one and only one active configuration.
        Multiple active strategies would make outputs non-interpretable because one application
        could be evaluated against conflicting thresholds.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_active_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: expected exactly one active strategy parameter row, found %.',
            v_active_count;
    END IF;

    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required strategy identity fields.

    These fields identify the downstream Module 2 strategy. They must remain separate from Module 1
    scenario fields.
    -------------------------------------------------------------------------------------------*/
    IF NULLIF(BTRIM(p.module2_model_version), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: module2_model_version is null or blank.';
    END IF;

    IF NULLIF(BTRIM(p.strategy_set_name), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_set_name is null or blank.';
    END IF;

    IF NULLIF(BTRIM(p.strategy_name), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_name is null or blank.';
    END IF;

    IF NULLIF(BTRIM(p.strategy_version), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_version is null or blank.';
    END IF;

    IF NULLIF(BTRIM(p.strategy_run_id), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_run_id is null or blank.';
    END IF;

    IF p.strategy_run_ts IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: strategy_run_ts is null.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Module 1 source selector.

    module1_input_source controls whether Module 2 reads from:
        LATEST  -> credit_decisioning_sim.synthetic_applications
        ARCHIVE -> credit_decisioning_sim.synthetic_applications_scenario_archive

    Multi-scenario processing is intentionally not designed in Module 2 v1.0 Sections 0-3.
    -------------------------------------------------------------------------------------------*/
    IF p.module1_input_source NOT IN ('LATEST', 'ARCHIVE') THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
            p.module1_input_source;
    END IF;

    IF p.module1_input_source = 'ARCHIVE' THEN
        IF NULLIF(BTRIM(p.source_module1_scenario_set_name), '') IS NULL THEN
            RAISE EXCEPTION
                'Module 2 gatekeeper failure: source_module1_scenario_set_name is required when module1_input_source = ARCHIVE.';
        END IF;

        IF NULLIF(BTRIM(p.source_module1_scenario_name), '') IS NULL THEN
            RAISE EXCEPTION
                'Module 2 gatekeeper failure: source_module1_scenario_name is required when module1_input_source = ARCHIVE.';
        END IF;

        IF NULLIF(BTRIM(p.source_population_id), '') IS NULL THEN
            RAISE EXCEPTION
                'Module 2 gatekeeper failure: source_population_id is required when module1_input_source = ARCHIVE.';
        END IF;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: archive controls.

    Archive reset modes are defined here but archive insert logic is intentionally deferred.

    NONE:
        Preserve existing archive rows. Later insert logic must guard against unintended duplicates.

    STRATEGY_SCENARIO_ONLY:
        Replace only the exact strategy / Module 1 scenario / population slice.

    STRATEGY_SET_ONLY:
        Replace the current strategy set for the selected Module 1 scenario / population.

    ALL:
        Clear the full Module 2 strategy archive. This is powerful and should be used deliberately.
    -------------------------------------------------------------------------------------------*/
    IF p.archive_run_flag IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: archive_run_flag is null.';
    END IF;

    IF p.strategy_archive_reset_mode NOT IN ('NONE', 'STRATEGY_SCENARIO_ONLY', 'STRATEGY_SET_ONLY', 'ALL') THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: invalid strategy_archive_reset_mode: %.',
            p.strategy_archive_reset_mode;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: synthetic estimated-PD proxy thresholds.

    These thresholds govern strategy routing using Module 1 estimated_pd as a synthetic estimated-PD
    proxy input. They do not define a production PD model.
    -------------------------------------------------------------------------------------------*/
    IF p.approve_max_estimated_pd_proxy IS NULL
       OR p.counteroffer_max_estimated_pd_proxy IS NULL
       OR p.review_max_estimated_pd_proxy IS NULL
       OR p.decline_min_estimated_pd_proxy IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: one or more synthetic estimated-PD proxy thresholds are null.';
    END IF;

    IF p.approve_max_estimated_pd_proxy NOT BETWEEN 0 AND 1
       OR p.counteroffer_max_estimated_pd_proxy NOT BETWEEN 0 AND 1
       OR p.review_max_estimated_pd_proxy NOT BETWEEN 0 AND 1
       OR p.decline_min_estimated_pd_proxy NOT BETWEEN 0 AND 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: synthetic estimated-PD proxy thresholds must be between 0 and 1.';
    END IF;

    IF NOT (
        p.approve_max_estimated_pd_proxy < p.counteroffer_max_estimated_pd_proxy
        AND p.counteroffer_max_estimated_pd_proxy <= p.review_max_estimated_pd_proxy
        AND p.review_max_estimated_pd_proxy <= p.decline_min_estimated_pd_proxy
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent synthetic estimated-PD proxy threshold ordering. Required: approve < counteroffer <= review <= decline.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: global PTI thresholds.

    Product-specific PTI thresholds will override these later. Global PTI thresholds remain useful
    as defaults and as a coherence check.
    -------------------------------------------------------------------------------------------*/
    IF p.global_approve_max_pti IS NULL
       OR p.global_review_max_pti IS NULL
       OR p.global_decline_min_pti IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: one or more global PTI thresholds are null.';
    END IF;

    IF p.global_approve_max_pti NOT BETWEEN 0 AND 1.5
       OR p.global_review_max_pti NOT BETWEEN 0 AND 1.5
       OR p.global_decline_min_pti NOT BETWEEN 0 AND 1.5 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: global PTI thresholds must be between 0 and 1.5.';
    END IF;

    IF NOT (
        p.global_approve_max_pti < p.global_review_max_pti
        AND p.global_review_max_pti <= p.global_decline_min_pti
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent global PTI threshold ordering. Required: approve < review <= decline.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DTI thresholds.

    DTI represents existing-obligation capacity from Module 1. In Module 2 v1.0, counteroffer
    logic can reduce PTI by lowering approved exposure, but it does not directly solve existing DTI.
    -------------------------------------------------------------------------------------------*/
    IF p.approve_max_dti IS NULL
       OR p.review_max_dti IS NULL
       OR p.decline_min_dti IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: one or more DTI thresholds are null.';
    END IF;

    IF p.approve_max_dti NOT BETWEEN 0 AND 1
       OR p.review_max_dti NOT BETWEEN 0 AND 1
       OR p.decline_min_dti NOT BETWEEN 0 AND 1 THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: DTI thresholds must be between 0 and 1.';
    END IF;

    IF NOT (
        p.approve_max_dti < p.review_max_dti
        AND p.review_max_dti <= p.decline_min_dti
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent DTI threshold ordering. Required: approve < review <= decline.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: decision output conventions.

    These controls lock the Module 2 v1.0 amount and Expected Loss conventions before output logic
    is written. They ensure later outputs remain internally consistent.
    -------------------------------------------------------------------------------------------*/
    IF NULLIF(BTRIM(p.approve_reason_code), '') IS NULL THEN
        RAISE EXCEPTION 'Module 2 gatekeeper failure: approve_reason_code is null or blank.';
    END IF;

    IF p.approve_reason_code <> 'APPROVED_AS_REQUESTED' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: approve_reason_code must be APPROVED_AS_REQUESTED for Module 2 v1.0.';
    END IF;

    IF p.reason_code_required_flag IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: reason_code_required_flag must be TRUE. Every row must be explainable.';
    END IF;

    IF p.simulated_offer_exposure_flag_enabled IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: simulated_offer_exposure_flag_enabled must be TRUE for Module 2 v1.0.';
    END IF;

    IF p.allow_approved_amount_above_requested_flag IS DISTINCT FROM FALSE THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: allow_approved_amount_above_requested_flag must be FALSE for Module 2 v1.0.';
    END IF;

    IF p.decline_approved_amount_convention <> 'ZERO' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: decline_approved_amount_convention must be ZERO.';
    END IF;

    IF p.manual_review_approved_amount_convention <> 'NULL_UNRESOLVED' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: manual_review_approved_amount_convention must be NULL_UNRESOLVED.';
    END IF;

    IF p.approved_el_decline_convention <> 'ZERO' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: approved_el_decline_convention must be ZERO.';
    END IF;

    IF p.approved_el_manual_review_convention <> 'NULL_UNRESOLVED' THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: approved_el_manual_review_convention must be NULL_UNRESOLVED.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.2 — PRODUCT POLICY PARAMETER VALIDATION
***************************************************************************************************/

DO $$
DECLARE
    v_supported_products TEXT[] := ARRAY[
        'MORTGAGE',
        'HELOC',
        'AUTO_LOAN',
        'UNSECURED_PERSONAL_LOAN',
        'REVOLVING_LINE'
    ];
    v_expected_count INTEGER := 5;
    v_actual_count INTEGER;
    v_bad_list TEXT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one policy row per supported product.

    Why this matters:
        Module 2 decision logic will join each Module 1 application to one product policy row.
        Missing rows create null thresholds. Duplicate rows create row multiplication and ambiguous
        decision outcomes.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_actual_count
    FROM tmp_module2_product_policy_params;

    IF v_actual_count <> v_expected_count THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: expected % product policy rows, found %.',
            v_expected_count,
            v_actual_count;
    END IF;

    SELECT STRING_AGG(COALESCE(product_type, '<NULL>'), ', ' ORDER BY COALESCE(product_type, '<NULL>'))
    INTO v_bad_list
    FROM tmp_module2_product_policy_params
    WHERE product_type IS NULL
       OR product_type <> ALL(v_supported_products);

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: unsupported or null product_type values found in product policy parameters: %.',
            v_bad_list;
    END IF;

    SELECT STRING_AGG(product_type, ', ' ORDER BY product_type)
    INTO v_bad_list
    FROM (
        SELECT product_type
        FROM tmp_module2_product_policy_params
        GROUP BY product_type
        HAVING COUNT(*) <> 1
    ) d;

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: duplicate or non-unique product policy rows found for: %.',
            v_bad_list;
    END IF;

    SELECT STRING_AGG(s.product_type, ', ' ORDER BY s.product_type)
    INTO v_bad_list
    FROM UNNEST(v_supported_products) AS s(product_type)
    LEFT JOIN tmp_module2_product_policy_params p
        ON p.product_type = s.product_type
    WHERE p.product_type IS NULL;

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: missing product policy rows for supported product types: %.',
            v_bad_list;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required product policy thresholds and controls are populated.

    Null thresholds would silently route applications into fallback logic later. This is not allowed.
    -------------------------------------------------------------------------------------------*/
    IF EXISTS (
        SELECT 1
        FROM tmp_module2_product_policy_params
        WHERE product_approve_max_pti IS NULL
           OR product_review_max_pti IS NULL
           OR product_decline_min_pti IS NULL
           OR counteroffer_target_pti IS NULL
           OR product_approve_max_requested_el IS NULL
           OR product_review_max_requested_el IS NULL
           OR product_decline_min_requested_el IS NULL
           OR product_approved_el_cap IS NULL
           OR product_min_approved_amount IS NULL
           OR product_max_approved_amount IS NULL
           OR counteroffer_allowed_flag IS NULL
           OR manual_review_allowed_flag IS NULL
           OR product_min_counteroffer_pct IS NULL
           OR product_max_exposure_reduction_pct IS NULL
           OR NULLIF(BTRIM(exposure_assignment_method), '') IS NULL
           OR approved_amount_rounding_increment IS NULL
    ) THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: one or more required product policy parameters are null or blank.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product PTI threshold ordering.

    Required:
        product_approve_max_pti < product_review_max_pti <= product_decline_min_pti

    Equality is allowed at review <= decline because v1.0 defaults treat the upper review boundary
    and hard-stop boundary as adjacent. Later CASE logic will use strict / inclusive rules documented
    in Section 3.0.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(product_type, ', ' ORDER BY product_type)
    INTO v_bad_list
    FROM tmp_module2_product_policy_params
    WHERE product_approve_max_pti NOT BETWEEN 0 AND 1.5
       OR product_review_max_pti NOT BETWEEN 0 AND 1.5
       OR product_decline_min_pti NOT BETWEEN 0 AND 1.5
       OR counteroffer_target_pti NOT BETWEEN 0 AND 1.5
       OR NOT (
            product_approve_max_pti < product_review_max_pti
            AND product_review_max_pti <= product_decline_min_pti
       );

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent product PTI thresholds for product(s): %. Required: approve < review <= decline, all between 0 and 1.5.',
            v_bad_list;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Expected Loss thresholds.

    Module 1 expected_loss_amount will later be carried forward as requested_expected_loss_amount.
    Module 2 approved_expected_loss_amount will be calculated from approved exposure.

    These product thresholds govern requested-exposure and approved-exposure loss tolerance in the
    simulated strategy layer.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(product_type, ', ' ORDER BY product_type)
    INTO v_bad_list
    FROM tmp_module2_product_policy_params
    WHERE product_approve_max_requested_el < 0
       OR product_review_max_requested_el < 0
       OR product_decline_min_requested_el < 0
       OR product_approved_el_cap < 0
       OR NOT (
            product_approve_max_requested_el <= product_review_max_requested_el
            AND product_review_max_requested_el <= product_decline_min_requested_el
       )
       OR product_approved_el_cap > product_approve_max_requested_el;

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent Expected Loss thresholds for product(s): %. Required: nonnegative, approve <= review <= decline, approved EL cap <= clean approval requested EL tolerance.',
            v_bad_list;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exposure limits.

    Approved exposure cannot be negative and cannot exceed requested exposure in Module 2 v1.0.
    Product exposure caps must therefore be positive, ordered, and meaningful.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(product_type, ', ' ORDER BY product_type)
    INTO v_bad_list
    FROM tmp_module2_product_policy_params
    WHERE product_min_approved_amount <= 0
       OR product_max_approved_amount <= product_min_approved_amount
       OR approved_amount_rounding_increment <= 0;

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent approved exposure limits or rounding increments for product(s): %.',
            v_bad_list;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: counteroffer controls.

    product_min_counteroffer_pct:
        Minimum viable counteroffer as a share of requested amount.

    product_max_exposure_reduction_pct:
        Maximum allowed exposure reduction as a share of requested amount.

    Coherence condition:
        min counteroffer pct + max exposure reduction pct must not exceed 1.
        Otherwise, the strategy would permit reductions below the stated minimum viable offer.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(product_type, ', ' ORDER BY product_type)
    INTO v_bad_list
    FROM tmp_module2_product_policy_params
    WHERE product_min_counteroffer_pct <= 0
       OR product_min_counteroffer_pct > 1
       OR product_max_exposure_reduction_pct < 0
       OR product_max_exposure_reduction_pct >= 1
       OR (product_min_counteroffer_pct + product_max_exposure_reduction_pct) > 1.000000;

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: incoherent counteroffer percentage controls for product(s): %.',
            v_bad_list;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exposure assignment method.

    The method is declared now so later approved amount logic can be parameter-driven and
    explainable instead of hard-coded inside opaque CASE expressions.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(product_type, ', ' ORDER BY product_type)
    INTO v_bad_list
    FROM tmp_module2_product_policy_params
    WHERE exposure_assignment_method NOT IN (
        'MIN_OF_CAPS',
        'AFFORDABILITY_BASED',
        'EL_BASED',
        'PRODUCT_CAP_ONLY'
    );

    IF v_bad_list IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 gatekeeper failure: invalid exposure_assignment_method for product(s): %.',
            v_bad_list;
    END IF;
END $$;



/***************************************************************************************************
SECTION 3.3 — SOURCE-INPUT VALIDATION AGAINST MODULE 1 LATEST OR ARCHIVE OUTPUTS
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that Module 2 can safely consume the selected Module 1 output before decision logic is
    built.

SQL PURPOSE:
    Validate table existence, required fields, source row count, source scenario uniqueness, duplicate
    application_id behavior, and required non-null fields.

WHY THIS EXISTS BEFORE SOURCE-SELECTION STAGING:
    Later Section 4 will build the actual source-selection staging table. This gatekeeper confirms the
    selected source is usable before any strategy outcomes are generated.

SOURCE OPTIONS:
    LATEST:
        credit_decisioning_sim.synthetic_applications

    ARCHIVE:
        credit_decisioning_sim.synthetic_applications_scenario_archive

IMPORTANT NAMING NOTE:
    Module 1 source tables may expose scenario fields as:
        scenario_set_name
        scenario_name

    Module 2 outputs will later alias them as:
        module1_scenario_set_name
        module1_scenario_name

***************************************************************************************************/

DO $$
DECLARE
    p RECORD;

    v_source_schema TEXT := 'credit_decisioning_sim';
    v_source_table TEXT;
    v_source_qualified TEXT;
    v_source_regclass REGCLASS;

    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;

    v_missing_cols TEXT;
    v_row_count BIGINT;
    v_distinct_scenario_count BIGINT;
    v_duplicate_application_count BIGINT;
    v_required_null_count BIGINT;
    v_domain_violation_count BIGINT;

    v_required_null_condition TEXT;
    v_domain_condition TEXT;
BEGIN
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;

    IF p.module1_input_source = 'LATEST' THEN
        v_source_table := 'synthetic_applications';
        v_source_regclass := TO_REGCLASS('credit_decisioning_sim.synthetic_applications');
    ELSE
        v_source_table := 'synthetic_applications_scenario_archive';
        v_source_regclass := TO_REGCLASS('credit_decisioning_sim.synthetic_applications_scenario_archive');
    END IF;

    v_source_qualified := FORMAT('%I.%I', v_source_schema, v_source_table);


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: selected Module 1 source table exists.
    -------------------------------------------------------------------------------------------*/
    IF v_source_regclass IS NULL THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: required Module 1 source table does not exist: %.',
            v_source_qualified;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required non-scenario Module 1 fields are present.

    These fields preserve applicant lineage, product identity, borrower signals, affordability,
    synthetic estimated-PD proxy input, LGD, and requested-exposure Expected Loss.
    -------------------------------------------------------------------------------------------*/
    WITH required_columns AS (
        SELECT UNNEST(ARRAY[
            'application_id',
            'applicant_id',
            'product_type',
            'score_band',
            'credit_score',
            'requested_amount',
            'annual_income',
            'monthly_payment_proxy',
            'payment_to_income_ratio',
            'debt_to_income_ratio',
            'estimated_pd',
            'estimated_lgd',
            'expected_loss_amount',
            'population_id'
        ]) AS column_name
    )
    SELECT STRING_AGG(r.column_name, ', ' ORDER BY r.column_name)
    INTO v_missing_cols
    FROM required_columns r
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = v_source_schema
          AND c.table_name = v_source_table
          AND c.column_name = r.column_name
    );

    IF v_missing_cols IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: required Module 1 field(s) missing from %: %.',
            v_source_qualified,
            v_missing_cols;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: source scenario field names are present.

    Module 1 latest/archive outputs are expected to use scenario_set_name and scenario_name.
    Module 2 can also tolerate pre-aliased module1_scenario_set_name and module1_scenario_name.
    Later source-selection logic will normalize these fields to the Module 2 output names.
    -------------------------------------------------------------------------------------------*/
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'scenario_set_name'
    ) THEN
        v_scenario_set_col := 'scenario_set_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'module1_scenario_set_name'
    ) THEN
        v_scenario_set_col := 'module1_scenario_set_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: % must contain scenario_set_name or module1_scenario_set_name.',
            v_source_qualified;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'scenario_name'
    ) THEN
        v_scenario_name_col := 'scenario_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'module1_scenario_name'
    ) THEN
        v_scenario_name_col := 'module1_scenario_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 source-input gatekeeper failure: % must contain scenario_name or module1_scenario_name.',
            v_source_qualified;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Build reusable null and domain validation conditions.

    Required non-null fields:
        These fields must be populated before simulated strategy outcomes can be assigned.

    Domain validation:
        These checks protect later approved amount and approved Expected Loss calculations from
        impossible negative or out-of-range source values.
    -------------------------------------------------------------------------------------------*/
    SELECT STRING_AGG(FORMAT('%I IS NULL', column_name), ' OR ')
    INTO v_required_null_condition
    FROM UNNEST(ARRAY[
        'application_id',
        'applicant_id',
        'product_type',
        'score_band',
        'credit_score',
        'requested_amount',
        'annual_income',
        'monthly_payment_proxy',
        'payment_to_income_ratio',
        'debt_to_income_ratio',
        'estimated_pd',
        'estimated_lgd',
        'expected_loss_amount',
        'population_id',
        v_scenario_set_col,
        v_scenario_name_col
    ]) AS required(column_name);

    v_domain_condition :=
        'requested_amount <= 0
         OR annual_income <= 0
         OR monthly_payment_proxy < 0
         OR payment_to_income_ratio < 0
         OR debt_to_income_ratio < 0
         OR estimated_pd < 0
         OR estimated_pd > 1
         OR estimated_lgd < 0
         OR estimated_lgd > 1
         OR expected_loss_amount < 0
         OR BTRIM(application_id::TEXT) = ''''
         OR BTRIM(applicant_id::TEXT) = ''''
         OR BTRIM(product_type::TEXT) = ''''
         OR BTRIM(score_band::TEXT) = ''''
         OR BTRIM(population_id::TEXT) = ''''
         OR BTRIM(' || FORMAT('%I', v_scenario_set_col) || '::TEXT) = ''''
         OR BTRIM(' || FORMAT('%I', v_scenario_name_col) || '::TEXT) = ''''';


    IF p.module1_input_source = 'LATEST' THEN

        /*---------------------------------------------------------------------------------------
        LATEST source validation:
            The latest-run Module 1 table must contain rows and must represent exactly one Module 1
            scenario / population for Module 2 v1.0 processing.
        ---------------------------------------------------------------------------------------*/
        EXECUTE FORMAT('SELECT COUNT(*) FROM %s', v_source_qualified)
        INTO v_row_count;

        IF v_row_count = 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected LATEST source table % contains zero rows.',
                v_source_qualified;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM (
                 SELECT DISTINCT %I, %I, population_id
                 FROM %s
             ) s',
             v_scenario_set_col,
             v_scenario_name_col,
             v_source_qualified
        )
        INTO v_distinct_scenario_count;

        IF v_distinct_scenario_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: LATEST source % must represent exactly one Module 1 scenario / population for v1.0 processing. Found % distinct scenario/population combinations.',
                v_source_qualified,
                v_distinct_scenario_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM (
                 SELECT application_id
                 FROM %s
                 GROUP BY application_id
                 HAVING COUNT(*) > 1
             ) d',
             v_source_qualified
        )
        INTO v_duplicate_application_count;

        IF v_duplicate_application_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: LATEST source % contains % duplicate application_id value(s).',
                v_source_qualified,
                v_duplicate_application_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM %s WHERE %s',
            v_source_qualified,
            v_required_null_condition
        )
        INTO v_required_null_count;

        IF v_required_null_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: LATEST source % contains % row(s) with null required Module 1 fields.',
                v_source_qualified,
                v_required_null_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*) FROM %s WHERE %s',
            v_source_qualified,
            v_domain_condition
        )
        INTO v_domain_violation_count;

        IF v_domain_violation_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: LATEST source % contains % row(s) with invalid source value domains for Module 2 strategy simulation.',
                v_source_qualified,
                v_domain_violation_count;
        END IF;

    ELSE

        /*---------------------------------------------------------------------------------------
        ARCHIVE source validation:
            The archive source must select exactly one Module 1 scenario / population slice.
            Multi-scenario processing is intentionally deferred until explicitly designed.
        ---------------------------------------------------------------------------------------*/
        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM %s
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3',
            v_source_qualified,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_row_count
        USING p.source_module1_scenario_set_name,
              p.source_module1_scenario_name,
              p.source_population_id;

        IF v_row_count = 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected ARCHIVE slice contains zero rows for scenario_set=%, scenario=%, population_id=%.',
                p.source_module1_scenario_set_name,
                p.source_module1_scenario_name,
                p.source_population_id;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM (
                 SELECT DISTINCT %I, %I, population_id
                 FROM %s
                 WHERE %I = $1
                   AND %I = $2
                   AND population_id = $3
             ) s',
            v_scenario_set_col,
            v_scenario_name_col,
            v_source_qualified,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_distinct_scenario_count
        USING p.source_module1_scenario_set_name,
              p.source_module1_scenario_name,
              p.source_population_id;

        IF v_distinct_scenario_count <> 1 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected ARCHIVE slice must represent exactly one Module 1 scenario / population. Found %.',
                v_distinct_scenario_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM (
                 SELECT application_id
                 FROM %s
                 WHERE %I = $1
                   AND %I = $2
                   AND population_id = $3
                 GROUP BY application_id
                 HAVING COUNT(*) > 1
             ) d',
            v_source_qualified,
            v_scenario_set_col,
            v_scenario_name_col
        )
        INTO v_duplicate_application_count
        USING p.source_module1_scenario_set_name,
              p.source_module1_scenario_name,
              p.source_population_id;

        IF v_duplicate_application_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected ARCHIVE slice contains % duplicate application_id value(s).',
                v_duplicate_application_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM %s
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3
               AND (%s)',
            v_source_qualified,
            v_scenario_set_col,
            v_scenario_name_col,
            v_required_null_condition
        )
        INTO v_required_null_count
        USING p.source_module1_scenario_set_name,
              p.source_module1_scenario_name,
              p.source_population_id;

        IF v_required_null_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected ARCHIVE slice contains % row(s) with null required Module 1 fields.',
                v_required_null_count;
        END IF;

        EXECUTE FORMAT(
            'SELECT COUNT(*)
             FROM %s
             WHERE %I = $1
               AND %I = $2
               AND population_id = $3
               AND (%s)',
            v_source_qualified,
            v_scenario_set_col,
            v_scenario_name_col,
            v_domain_condition
        )
        INTO v_domain_violation_count
        USING p.source_module1_scenario_set_name,
              p.source_module1_scenario_name,
              p.source_population_id;

        IF v_domain_violation_count > 0 THEN
            RAISE EXCEPTION
                'Module 2 source-input gatekeeper failure: selected ARCHIVE slice contains % row(s) with invalid source value domains for Module 2 strategy simulation.',
                v_domain_violation_count;
        END IF;
    END IF;
END $$;



/***************************************************************************************************
END OF MODULE 2 FIRST SQL BUILD — SECTIONS 0 THROUGH 3 ONLY

If execution reaches this point:
    1. Module 2 schema setup is complete.
    2. Temporary strategy parameters are populated.
    3. Temporary product policy parameters are populated.
    4. Strategy identity controls are valid.
    5. Archive controls are valid.
    6. Threshold ordering is coherent.
    7. Output conventions are locked.
    8. Product policy rows are complete and product-aware.
    9. Selected Module 1 source input exists and is structurally safe to consume.

No decision outcomes have been generated yet.
No reason codes have been assigned yet.
No approved exposure has been calculated yet.
No approved Expected Loss has been calculated yet.
No latest-run strategy output has been created yet.
No strategy archive rows have been inserted yet.

***************************************************************************************************/
```

## What this first build establishes

It creates the Module 2 starting scaffold: schema reuse, clean temporary reset, latest-run reset, strategy parameter table, product policy parameter table, default baseline strategy values, product-specific policy defaults, and fail-fast validation for strategy identity, source inputs, thresholds, exposure controls, archive controls, and output conventions.

It also locks the interpretation boundaries inside the SQL itself: `estimated_pd` is consumed as the Module 1 synthetic estimated-PD proxy, reason codes are simulated strategy explanation codes, and approved exposure is simulated offer exposure rather than booked exposure.

## What it intentionally does not build

It does not build Module 1 source-selection staging, derived strategy segments, rule flags, decision hierarchy, reason-code assignment, approved amount logic, approved Expected Loss logic, final latest-run output, archive insertion, QA queries, or matched strategy comparison.

## Next build step

Next should be **Section 4 — Module 1 Source Selection and Lineage Normalization**: create a staged source table that selects either the latest Module 1 output or one archived Module 1 scenario slice, aliases `scenario_set_name` and `scenario_name` into `module1_scenario_set_name` and `module1_scenario_name`, carries forward required Module 1 fields, and aliases `expected_loss_amount` as `requested_expected_loss_amount`.
<!-- END_MESSAGE C038-M00052 -->


---

<a id="c038-m00053"></a>

### C038-M00053

**Andrew** · 2026-05-06T11:25:12.575000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00053 -->
This is a strong first SQL build. I agree with the direction.

Sections 0–3 establish the right foundation:
- Module 2 purpose and boundary framing
- latest-run + archive architecture
- strategy parameter table
- product policy parameter table
- fail-fast gatekeeper logic
- source-input validation
- product-policy validation
- threshold-ordering validation
- archive-control validation
- output-convention validation

Before moving into decision logic, please treat Sections 0–3 as provisionally accepted, subject to the clarifications below.

Do not build decision rules, reason codes, approved amount logic, approved Expected Loss, latest-run final output, archive insert logic, or full QA sections yet.

================================================================================
1. SECTION 0–3 PRE-FLIGHT REVIEW
================================================================================

Before writing Section 4, please do a brief self-review of Sections 0–3 for:

- PostgreSQL syntax consistency
- temporary table names
- strategy parameter column names
- product policy parameter column names
- gatekeeper references to those columns
- source-input validation references
- archive reset mode naming
- estimated-PD proxy terminology
- reason-code boundary language
- approved exposure / approved Expected Loss convention language
- simulated_offer_exposure_flag terminology
- any remaining “booked” or production-decision language

If you find any issue in Sections 0–3, provide a targeted BEFORE / AFTER patch first.

Do not rewrite the full Sections 0–3 unless a structural correction is needed.

If no issue is found, explicitly state:
“Sections 0–3 pre-flight review passed; no patch required.”

================================================================================
2. LOCK AUDIT METADATA BOUNDARY
================================================================================

Please explicitly preserve this interpretation:

strategy_run_id and strategy_run_ts are audit metadata.

They should:
- support run traceability
- appear in latest-run and archive outputs later
- not replace the archive replacement / rerun key
- not be used as the grain for matched strategy comparison

Because strategy_run_ts may change across reruns, deterministic validation of strategy outcomes should compare business fields and decision fields, excluding purely time-based audit fields unless the test is specifically validating run metadata.

The archive replacement / rerun key remains:

- strategy_set_name
- strategy_name
- strategy_version
- module1_scenario_set_name
- module1_scenario_name
- population_id

The row-level archive grain additionally includes:

- application_id

================================================================================
3. PRODUCT TYPE NORMALIZATION REQUIREMENT
================================================================================

Before downstream product-policy joins are built, Section 4 must confirm that Module 1 product_type values align to Module 2 product policy parameter values.

Module 2 product policy parameters currently use values such as:
- MORTGAGE
- HELOC
- AUTO_LOAN
- UNSECURED_PERSONAL_LOAN
- REVOLVING_LINE

Section 4 should preserve the original Module 1 product_type value and also create a normalized product policy key.

Required fields:
- product_type
- product_type_policy_key

If Module 1 already outputs product_type values that exactly match the policy table, product_type_policy_key can simply equal product_type.

If Module 1 uses display-style values, Section 4 should normalize them, for example:
- Mortgage → MORTGAGE
- HELOC → HELOC
- Auto Loan → AUTO_LOAN
- Unsecured Personal Loan → UNSECURED_PERSONAL_LOAN
- Revolving Line → REVOLVING_LINE

Do not modify Module 1.

Normalize only inside the Module 2 source-staging layer.

Section 4 should fail fast or clearly flag the issue if any Module 1 product_type cannot be mapped to a supported Module 2 product policy key.

================================================================================
4. NEXT BUILD SCOPE: SECTION 4 ONLY
================================================================================

The next SQL build should be:

SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION

Build only Section 4.

Do not build:
- derived strategy segments
- risk tiers
- affordability tiers
- rule flags
- hard simulated policy stop logic
- counteroffer logic
- decision hierarchy
- reason-code assignment
- approved amount calculation
- approved payment calculation
- approved Expected Loss calculation
- final latest-run output table
- archive insert logic
- full QA queries

Those belong to later sections.

================================================================================
5. SECTION 4 OBJECTIVE
================================================================================

Section 4 should safely consume either:

1. Module 1 latest-run output:
   credit_decisioning_sim.synthetic_applications

or

2. Module 1 scenario archive output:
   credit_decisioning_sim.synthetic_applications_scenario_archive

based on tmp_module2_strategy_params.module1_input_source.

Section 4 should create a staged source table, recommended name:

tmp_m2_stage_1_source_applications

This table should be the clean Module 2 input foundation.

Purpose:
- normalize source lineage
- preserve Module 1 scenario metadata
- preserve application-level identifiers
- preserve requested-structure economics
- preserve Module 1 synthetic estimated-PD proxy and LGD
- alias requested-exposure fields clearly for Module 2
- create product_type_policy_key for later product policy joins

No Module 2 decision outputs should be created in Section 4.

================================================================================
6. REQUIRED SECTION 4 OUTPUT FIELDS
================================================================================

The staged source table should carry forward and normalize the following fields.

Module 1 lineage:
- module1_model_version
- module1_scenario_set_name
- module1_scenario_name
- population_id
- anchor_date
- module1_input_source
- module1_source_table_name

Application lineage:
- application_seq
- application_id
- applicant_id
- application_date

Product / score:
- product_type
- product_type_policy_key
- score_band
- credit_score

Borrower / behavioral fields:
- annual_income
- debt_to_income_ratio
- utilization_rate
- tradeline_count
- months_since_oldest_trade
- recent_inquiry_count
- delinquency_count_12m
- major_derogatory_flag
- bankruptcy_flag

Optional Module 1 relationship / context fields, if available:
- prequalified_flag
- returning_customer_flag

Requested structure from Module 1:
- requested_amount
- loan_term_months
- base_apr_for_payment_calc
- monthly_payment_proxy
- payment_to_income_ratio
- amount_to_income_ratio

Recommended Module 2 aliases for clarity:
- requested_monthly_payment_proxy = monthly_payment_proxy
- requested_payment_to_income_ratio = payment_to_income_ratio
- requested_expected_loss_amount = expected_loss_amount

Module 1 risk economics:
- estimated_pd
- estimated_lgd
- expected_loss_amount

Important interpretation:
- estimated_pd remains the SQL field name from Module 1
- comments must describe it as the synthetic estimated-PD proxy
- expected_loss_amount from Module 1 should be treated as requested-exposure Expected Loss
- requested_expected_loss_amount is the preferred Module 2 name for that value

No Module 2 decision outputs should be created in Section 4.

================================================================================
7. SOURCE SELECTION LOGIC
================================================================================

If module1_input_source = 'LATEST':

- Select from credit_decisioning_sim.synthetic_applications
- Use the existing Module 1 scenario_set_name and scenario_name fields as upstream lineage
- Alias them as:
  - module1_scenario_set_name
  - module1_scenario_name
- Preserve population_id
- Preserve application_id and applicant_id
- Do not require source_module1_scenario_set_name or source_module1_scenario_name
- Confirm that the latest-run table represents exactly one Module 1 scenario / population for the current Module 2 run, unless multi-scenario processing is explicitly designed later

If module1_input_source = 'ARCHIVE':

- Select from credit_decisioning_sim.synthetic_applications_scenario_archive
- Filter to:
  - source_module1_scenario_set_name
  - source_module1_scenario_name
  - source_population_id
- Alias archive scenario fields as:
  - module1_scenario_set_name
  - module1_scenario_name
- Preserve population_id
- Preserve application_id and applicant_id
- Confirm that the selected archive slice contains exactly one Module 1 scenario / population for the current Module 2 run, unless multi-scenario processing is explicitly designed later

The goal is that downstream Module 2 logic does not need to care whether the input came from latest-run or archive.

Downstream logic should read from:

tmp_m2_stage_1_source_applications

not directly from Module 1 tables.

================================================================================
8. SECTION 4 PRODUCT POLICY JOIN / VALIDATION
================================================================================

Section 4 should create product_type_policy_key and perform a lightweight validation join to tmp_module2_product_policy_params.

Recommended approach:
- create product_type_policy_key in Section 4
- perform a lightweight LEFT JOIN to tmp_module2_product_policy_params
- create a product_policy_config_found_flag or equivalent diagnostic field
- fail fast if any staged source row does not map to exactly one product policy row
- defer actual product policy logic to Section 5+

The purpose of this join is only to confirm that every staged source row has a valid product policy configuration available.

Do not apply product policy rules yet.

Do not calculate product-specific caps, counteroffer limits, strategy tiers, or decision flags in Section 4.

================================================================================
9. SECTION 4 LOCAL SANITY CHECKS
================================================================================

At the end of Section 4, include a small local sanity-check query block.

This should not become the full QA framework yet.

Suggested local checks:
1. Row count of tmp_m2_stage_1_source_applications
2. Count distinct application_id
3. Count rows by module1_scenario_set_name, module1_scenario_name, population_id
4. Count rows by module1_input_source and module1_source_table_name
5. Count rows by product_type and product_type_policy_key
6. Count rows with unmapped product_type_policy_key
7. Count rows with missing product policy configuration
8. Count rows with null required source fields
9. Confirm expected_loss_amount has been aliased to requested_expected_loss_amount
10. Confirm monthly_payment_proxy has been aliased to requested_monthly_payment_proxy
11. Confirm payment_to_income_ratio has been aliased to requested_payment_to_income_ratio
12. Confirm estimated_pd is present and documented as the synthetic estimated-PD proxy

These are staging sanity checks only.

Do not build full Section 14 QA yet.

================================================================================
10. SECTION 4 LOCAL FAIL-FAST CHECKS
================================================================================

In addition to sanity-check queries, include local fail-fast checks if appropriate.

Section 4 should fail if:
- staged row count = 0
- duplicate application_id exists in the selected source slice
- any required source field is null where it must be populated
- any product_type cannot be normalized into product_type_policy_key
- any product_type_policy_key does not map to exactly one product policy row
- more than one Module 1 scenario / population appears in the staged source table

These checks protect the decision engine from consuming ambiguous or malformed input.

================================================================================
11. SECTION 4 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard as Module 1 and Sections 0–3.

Section 4 comments should explain:
- why Module 2 consumes Module 1 rather than rewriting Module 1
- why latest-run and archive inputs are both supported
- why Module 1 scenario lineage must be preserved
- why product_type may need a policy key
- why product policy validation happens before policy rules are applied
- why expected_loss_amount is aliased to requested_expected_loss_amount
- why monthly_payment_proxy is aliased to requested_monthly_payment_proxy
- why payment_to_income_ratio is aliased to requested_payment_to_income_ratio
- why estimated_pd remains the column name but is interpreted as synthetic estimated-PD proxy
- why no decision outcomes are created in Section 4
- why product-policy joins in Section 4 are validation-only, not decision logic

================================================================================
12. DELIVERABLE FOR THIS NEXT STEP
================================================================================

Please now provide:

1. Any necessary targeted patch to Sections 0–3, if your pre-flight review finds one.
2. Section 4 SQL only:
   MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION.
3. A short explanation of what Section 4 establishes.
4. A short explanation of what Section 4 intentionally does not build.
5. The recommended next build step after Section 4.

Do not write Sections 5+ yet.
<!-- END_MESSAGE C038-M00053 -->


---

<a id="c038-m00071"></a>

### C038-M00071

**ChatGPT** · 2026-05-06T11:33:41.823830-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00071 -->
## Sections 0–3 pre-flight review

Sections 0–3 pre-flight review found a few targeted hardening items. No structural rewrite is needed.

The parameter tables, column names, gatekeeper references, product-policy values, archive reset mode naming, synthetic estimated-PD proxy terminology, simulated reason-code boundary, approved-exposure boundary, and `simulated_offer_exposure_flag` terminology are directionally consistent with the locked Module 2 design.

The targeted patch below tightens null handling and adds the audit metadata boundary for `strategy_run_id` / `strategy_run_ts`. This preserves Module 1’s deterministic, scenario-comparable design principle and keeps Module 2 aligned to the validated Module 1 boundary that outputs support controlled synthetic strategy simulation, not production decisions or calibrated default modeling. fileciteturn4file0 fileciteturn4file1

---

# 1. Targeted patch to Sections 0–3

## Patch 0–3.A — Add audit metadata boundary to Section 0

### BEFORE

```sql
0.8 LOCKED PHYSICAL ARCHITECTURE FOR LATER SECTIONS
----------------------------------------------------------------------------------------------------
Latest-run strategy decision table:

    credit_decisioning_sim.strategy_decisions
```

### AFTER

```sql
0.8 LOCKED PHYSICAL ARCHITECTURE FOR LATER SECTIONS
----------------------------------------------------------------------------------------------------
Latest-run strategy decision table:

    credit_decisioning_sim.strategy_decisions
```

```sql
0.8A STRATEGY RUN AUDIT METADATA BOUNDARY
----------------------------------------------------------------------------------------------------
strategy_run_id and strategy_run_ts are audit metadata.

They support:
    run traceability
    execution review
    latest-run and archive output auditability

They do NOT replace the archive replacement / rerun key.
They are NOT the grain for matched strategy comparison.

The locked archive replacement / rerun key remains:

    strategy_set_name
    strategy_name
    strategy_version
    module1_scenario_set_name
    module1_scenario_name
    population_id

The row-level archive grain additionally includes:

    application_id

Because strategy_run_ts may change across reruns, deterministic validation of strategy
outcomes should compare business fields and decision fields while excluding purely
time-based audit fields unless the test is specifically validating run metadata.
```

---

## Patch 0–3.B — Harden `module1_input_source` null handling

### BEFORE

```sql
IF p.module1_input_source NOT IN ('LATEST', 'ARCHIVE') THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
        p.module1_input_source;
END IF;
```

### AFTER

```sql
IF p.module1_input_source IS NULL
   OR p.module1_input_source NOT IN ('LATEST', 'ARCHIVE') THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
        COALESCE(p.module1_input_source, '<NULL>');
END IF;
```

---

## Patch 0–3.C — Harden archive reset mode null handling

### BEFORE

```sql
IF p.strategy_archive_reset_mode NOT IN ('NONE', 'STRATEGY_SCENARIO_ONLY', 'STRATEGY_SET_ONLY', 'ALL') THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: invalid strategy_archive_reset_mode: %.',
        p.strategy_archive_reset_mode;
END IF;
```

### AFTER

```sql
IF p.strategy_archive_reset_mode IS NULL
   OR p.strategy_archive_reset_mode NOT IN ('NONE', 'STRATEGY_SCENARIO_ONLY', 'STRATEGY_SET_ONLY', 'ALL') THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: invalid strategy_archive_reset_mode: %.',
        COALESCE(p.strategy_archive_reset_mode, '<NULL>');
END IF;
```

---

## Patch 0–3.D — Harden decision convention text checks

### BEFORE

```sql
IF p.decline_approved_amount_convention <> 'ZERO' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: decline_approved_amount_convention must be ZERO.';
END IF;

IF p.manual_review_approved_amount_convention <> 'NULL_UNRESOLVED' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: manual_review_approved_amount_convention must be NULL_UNRESOLVED.';
END IF;

IF p.approved_el_decline_convention <> 'ZERO' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: approved_el_decline_convention must be ZERO.';
END IF;

IF p.approved_el_manual_review_convention <> 'NULL_UNRESOLVED' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: approved_el_manual_review_convention must be NULL_UNRESOLVED.';
END IF;
```

### AFTER

```sql
IF p.decline_approved_amount_convention IS DISTINCT FROM 'ZERO' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: decline_approved_amount_convention must be ZERO.';
END IF;

IF p.manual_review_approved_amount_convention IS DISTINCT FROM 'NULL_UNRESOLVED' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: manual_review_approved_amount_convention must be NULL_UNRESOLVED.';
END IF;

IF p.approved_el_decline_convention IS DISTINCT FROM 'ZERO' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: approved_el_decline_convention must be ZERO.';
END IF;

IF p.approved_el_manual_review_convention IS DISTINCT FROM 'NULL_UNRESOLVED' THEN
    RAISE EXCEPTION
        'Module 2 gatekeeper failure: approved_el_manual_review_convention must be NULL_UNRESOLVED.';
END IF;
```

---

# 2. Section 4 SQL only — Module 1 source selection and lineage normalization

```sql
/***************************************************************************************************
SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION
****************************************************************************************************

BUSINESS PURPOSE:
    Consume finalized Module 1 outputs as the authoritative synthetic application and risk foundation
    for Module 2 strategy simulation.

    Module 2 does not regenerate the synthetic population.
    Module 2 does not rewrite Module 1 product, affordability, risk, LGD, or Expected Loss logic.
    Module 2 does not recalculate estimated_pd.

    Instead, Module 2 stages a clean, normalized input layer that downstream strategy logic can use
    without caring whether the source came from the Module 1 latest-run table or the Module 1 scenario
    archive.

SQL PURPOSE:
    1. Select exactly one Module 1 source slice based on tmp_module2_strategy_params.
    2. Normalize Module 1 scenario lineage into Module 2 naming:
            scenario_set_name -> module1_scenario_set_name
            scenario_name     -> module1_scenario_name
    3. Preserve application-level identifiers and borrower / product / affordability / risk fields.
    4. Alias Module 1 requested-structure fields for Module 2 clarity:
            monthly_payment_proxy     -> requested_monthly_payment_proxy
            payment_to_income_ratio   -> requested_payment_to_income_ratio
            expected_loss_amount      -> requested_expected_loss_amount
    5. Preserve estimated_pd as the finalized Module 1 SQL field while documenting it as the
       synthetic estimated-PD proxy.
    6. Create product_type_policy_key for later joins to Module 2 product policy parameters.
    7. Validate that every staged source row maps to exactly one Module 2 product policy row.

BOUNDARY NOTES:
    Section 4 creates no Module 2 decision outcomes.
    Section 4 creates no rule flags.
    Section 4 creates no reason codes.
    Section 4 creates no approved amount.
    Section 4 creates no approved Expected Loss.
    Section 4 performs no policy rule application.

    Product policy validation in this section is intentionally lightweight. It confirms that a product
    policy configuration exists for each staged row, but it does not apply product caps, PTI thresholds,
    counteroffer rules, review rules, or policy stop rules.

WHY LATEST AND ARCHIVE INPUTS ARE BOTH SUPPORTED:
    LATEST supports single-run development, debugging, and immediate QA against the current Module 1
    output table.

    ARCHIVE supports governed strategy comparison against a specific preserved Module 1 scenario slice.
    This matters because matched strategy comparison requires preserving Module 1 scenario lineage and
    population_id.

WHY PRODUCT_TYPE_POLICY_KEY EXISTS:
    Module 1 product_type values may already be normalized codes such as MORTGAGE or AUTO_LOAN.
    Some future Module 1 or demonstration outputs may use display-style values such as Mortgage or
    Auto Loan.

    Module 2 should not modify Module 1. Instead, Section 4 preserves the original product_type and
    creates product_type_policy_key as the normalized join key used by Module 2 product policy
    parameters.

WHY EXPECTED LOSS IS ALIASED:
    Module 1 expected_loss_amount is calculated from requested exposure:

        requested_amount * synthetic estimated-PD proxy * LGD

    Module 2 will later calculate approved_expected_loss_amount from approved exposure.

    Therefore, Module 1 expected_loss_amount is carried forward as requested_expected_loss_amount
    so downstream reporting can distinguish requested-exposure Expected Loss from approved-exposure
    Expected Loss.

WHY PAYMENT AND PTI ARE ALIASED:
    Module 1 monthly_payment_proxy and payment_to_income_ratio describe the original requested
    structure.

    Module 2 will later calculate approved_monthly_payment_proxy and
    approved_payment_to_income_ratio after simulated exposure treatment.

    Therefore, Section 4 aliases:
        monthly_payment_proxy   -> requested_monthly_payment_proxy
        payment_to_income_ratio -> requested_payment_to_income_ratio

WHY ESTIMATED_PD IS NOT RENAMED IN SQL:
    estimated_pd is the finalized Module 1 SQL field name.
    Module 2 preserves that field name for lineage and compatibility.

    In commentary and interpretation, estimated_pd means the synthetic estimated-PD proxy.
    It is not a calibrated production probability of default.

***************************************************************************************************/


/***************************************************************************************************
SECTION 4.1 — CLEAN RESET OF SECTION 4 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_1_source_applications;



/***************************************************************************************************
SECTION 4.2 — CREATE NORMALIZED MODULE 1 SOURCE STAGE
****************************************************************************************************

IMPLEMENTATION NOTE:
    This section uses dynamic SQL because Module 2 can consume either the Module 1 latest-run table
    or a selected Module 1 archive slice.

    It also tolerates either of the following source naming patterns for scenario lineage:

        scenario_set_name / scenario_name
        module1_scenario_set_name / module1_scenario_name

    The staged output always uses:

        module1_scenario_set_name
        module1_scenario_name

***************************************************************************************************/

DO $$
DECLARE
    p RECORD;

    v_source_schema TEXT := 'credit_decisioning_sim';
    v_source_table TEXT;
    v_source_qualified TEXT;

    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;
    v_model_version_col TEXT;

    v_prequalified_expr TEXT;
    v_returning_customer_expr TEXT;

    v_missing_cols TEXT;
    v_sql TEXT;
BEGIN
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;

    IF p.module1_input_source = 'LATEST' THEN
        v_source_table := 'synthetic_applications';
    ELSIF p.module1_input_source = 'ARCHIVE' THEN
        v_source_table := 'synthetic_applications_scenario_archive';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
            COALESCE(p.module1_input_source, '<NULL>');
    END IF;

    v_source_qualified := FORMAT('%I.%I', v_source_schema, v_source_table);


    /*-------------------------------------------------------------------------------------------
    Resolve Module 1 scenario lineage field names.

    Module 1 finalized outputs use scenario_set_name and scenario_name.
    Module 2 can also tolerate already-normalized module1_scenario_set_name and module1_scenario_name.
    Downstream Module 2 logic should read only the normalized names created by this stage.
    -------------------------------------------------------------------------------------------*/
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'scenario_set_name'
    ) THEN
        v_scenario_set_col := 'scenario_set_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'module1_scenario_set_name'
    ) THEN
        v_scenario_set_col := 'module1_scenario_set_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % must contain scenario_set_name or module1_scenario_set_name.',
            v_source_qualified;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'scenario_name'
    ) THEN
        v_scenario_name_col := 'scenario_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'module1_scenario_name'
    ) THEN
        v_scenario_name_col := 'module1_scenario_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % must contain scenario_name or module1_scenario_name.',
            v_source_qualified;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Resolve Module 1 model-version lineage.

    The finalized Module 1 latest-run output uses model_version.
    Module 2 stages this as module1_model_version.

    If a future source already exposes module1_model_version, this stage can consume it directly.
    -------------------------------------------------------------------------------------------*/
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'model_version'
    ) THEN
        v_model_version_col := 'model_version';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'module1_model_version'
    ) THEN
        v_model_version_col := 'module1_model_version';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % must contain model_version or module1_model_version.',
            v_source_qualified;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Optional relationship / context fields.

    These fields exist in the finalized Module 1 V2.0 output. They remain optional here because
    Module 2 v1.0 should not fail solely because a future source omits relationship-context fields.
    -------------------------------------------------------------------------------------------*/
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'prequalified_flag'
    ) THEN
        v_prequalified_expr := 'src.prequalified_flag';
    ELSE
        v_prequalified_expr := 'NULL::BOOLEAN';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_schema
          AND table_name = v_source_table
          AND column_name = 'returning_customer_flag'
    ) THEN
        v_returning_customer_expr := 'src.returning_customer_flag';
    ELSE
        v_returning_customer_expr := 'NULL::BOOLEAN';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Expanded Section 4 required source-field check.

    Section 3 already validates the minimum Module 1 fields needed to protect the parameter layer.
    Section 4 now validates the fuller staged input shape needed for downstream Module 2 logic.

    loan_term_months is included as a source field, but later nullability treatment recognizes that
    revolving products may not have a fixed amortizing term.
    -------------------------------------------------------------------------------------------*/
    WITH required_columns AS (
        SELECT UNNEST(ARRAY[
            'anchor_date',
            'application_seq',
            'application_id',
            'applicant_id',
            'application_date',
            'product_type',
            'score_band',
            'credit_score',
            'annual_income',
            'debt_to_income_ratio',
            'utilization_rate',
            'tradeline_count',
            'months_since_oldest_trade',
            'recent_inquiry_count',
            'delinquency_count_12m',
            'major_derogatory_flag',
            'bankruptcy_flag',
            'requested_amount',
            'loan_term_months',
            'base_apr_for_payment_calc',
            'monthly_payment_proxy',
            'payment_to_income_ratio',
            'amount_to_income_ratio',
            'estimated_pd',
            'estimated_lgd',
            'expected_loss_amount',
            'population_id'
        ]) AS column_name
    )
    SELECT STRING_AGG(r.column_name, ', ' ORDER BY r.column_name)
    INTO v_missing_cols
    FROM required_columns r
    WHERE NOT EXISTS (
        SELECT 1
        FROM information_schema.columns c
        WHERE c.table_schema = v_source_schema
          AND c.table_name = v_source_table
          AND c.column_name = r.column_name
    );

    IF v_missing_cols IS NOT NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: required staging field(s) missing from %: %.',
            v_source_qualified,
            v_missing_cols;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Build the staged source table.

    product_type normalization approach:
        1. Preserve original product_type exactly as supplied by Module 1.
        2. Convert display-style values into a normalized product_type_policy_key.
        3. Use product_type_policy_key only for Module 2 product policy joins.

    Product policy join:
        The lateral subquery counts matching product policy rows.
        This avoids row multiplication even if a future parameter error creates duplicate policy rows.
        Section 4 then fails if the match count is not exactly one.

    No decision logic is created here.
    -------------------------------------------------------------------------------------------*/
    v_sql := FORMAT($SQL$
        CREATE TEMP TABLE tmp_m2_stage_1_source_applications
        ON COMMIT PRESERVE ROWS
        AS
        WITH active_params AS (
            SELECT *
            FROM tmp_module2_strategy_params
            WHERE active_strategy_flag IS TRUE
            LIMIT 1
        ),
        selected_source AS (
            SELECT
                src.%1$I::TEXT AS module1_model_version,
                src.%2$I::TEXT AS module1_scenario_set_name,
                src.%3$I::TEXT AS module1_scenario_name,
                src.population_id::TEXT AS population_id,
                src.anchor_date,
                %4$L::TEXT AS module1_input_source,
                %5$L::TEXT AS module1_source_table_name,

                src.application_seq,
                src.application_id::TEXT AS application_id,
                src.applicant_id::TEXT AS applicant_id,
                src.application_date,

                src.product_type::TEXT AS product_type,
                src.score_band::TEXT AS score_band,
                src.credit_score,

                src.annual_income,
                src.debt_to_income_ratio,
                src.utilization_rate,
                src.tradeline_count,
                src.months_since_oldest_trade,
                src.recent_inquiry_count,
                src.delinquency_count_12m,
                src.major_derogatory_flag,
                src.bankruptcy_flag,

                %6$s AS prequalified_flag,
                %7$s AS returning_customer_flag,

                src.requested_amount,
                src.loan_term_months,
                src.base_apr_for_payment_calc,
                src.monthly_payment_proxy,
                src.payment_to_income_ratio,
                src.amount_to_income_ratio,

                src.monthly_payment_proxy AS requested_monthly_payment_proxy,
                src.payment_to_income_ratio AS requested_payment_to_income_ratio,
                src.expected_loss_amount AS requested_expected_loss_amount,

                /*
                estimated_pd:
                    Finalized Module 1 SQL field name.

                Interpretation:
                    synthetic estimated-PD proxy.

                Boundary:
                    This is not recalculated in Module 2 Section 4.
                    This is not a calibrated production probability of default.
                */
                src.estimated_pd,
                src.estimated_lgd,
                src.expected_loss_amount

            FROM %8$s src
            CROSS JOIN active_params p
            %9$s
        ),
        normalized_product AS (
            SELECT
                s.*,

                /*
                product_type_policy_key:
                    Normalized product key used by Module 2 product policy parameters.

                This preserves original Module 1 product_type while giving Module 2 a stable policy
                join key. If Module 1 already outputs normalized product codes, the key will equal
                product_type.
                */
                CASE
                    WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(s.product_type)), '[^A-Z0-9]+', '_', 'g'))
                         IN ('MORTGAGE')
                        THEN 'MORTGAGE'

                    WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(s.product_type)), '[^A-Z0-9]+', '_', 'g'))
                         IN ('HELOC', 'HOME_EQUITY_LINE_OF_CREDIT', 'HOME_EQUITY_LINE')
                        THEN 'HELOC'

                    WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(s.product_type)), '[^A-Z0-9]+', '_', 'g'))
                         IN ('AUTO_LOAN', 'AUTO', 'AUTOLOAN', 'VEHICLE_LOAN')
                        THEN 'AUTO_LOAN'

                    WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(s.product_type)), '[^A-Z0-9]+', '_', 'g'))
                         IN ('UNSECURED_PERSONAL_LOAN', 'PERSONAL_LOAN', 'UNSECURED_LOAN')
                        THEN 'UNSECURED_PERSONAL_LOAN'

                    WHEN TRIM(BOTH '_' FROM REGEXP_REPLACE(UPPER(BTRIM(s.product_type)), '[^A-Z0-9]+', '_', 'g'))
                         IN ('REVOLVING_LINE', 'REVOLVING', 'CREDIT_CARD', 'CREDIT_CARD_LINE', 'REVOLVING_CREDIT_LINE')
                        THEN 'REVOLVING_LINE'

                    ELSE NULL
                END AS product_type_policy_key

            FROM selected_source s
        )
        SELECT
            n.*,

            /*
            Validation-only product policy diagnostics.

            product_policy_match_count:
                Number of Module 2 product policy parameter rows that match the normalized product key.

            product_policy_config_found_flag:
                TRUE only when exactly one product policy row is available.

            These are not decision outputs.
            These do not apply product policy rules.
            They only protect downstream sections from unmapped or ambiguous product logic.
            */
            ppm.product_policy_match_count,
            (ppm.product_policy_match_count = 1) AS product_policy_config_found_flag

        FROM normalized_product n
        LEFT JOIN LATERAL (
            SELECT COUNT(*)::INT AS product_policy_match_count
            FROM tmp_module2_product_policy_params pp
            WHERE pp.product_type = n.product_type_policy_key
        ) ppm ON TRUE
    $SQL$,
        v_model_version_col,
        v_scenario_set_col,
        v_scenario_name_col,
        p.module1_input_source,
        v_source_qualified,
        v_prequalified_expr,
        v_returning_customer_expr,
        v_source_qualified,
        CASE
            WHEN p.module1_input_source = 'ARCHIVE' THEN
                FORMAT(
                    'WHERE src.%I = %L
                       AND src.%I = %L
                       AND src.population_id = %L',
                    v_scenario_set_col,
                    p.source_module1_scenario_set_name,
                    v_scenario_name_col,
                    p.source_module1_scenario_name,
                    p.source_population_id
                )
            ELSE
                ''
        END
    );

    EXECUTE v_sql;
END $$;



/***************************************************************************************************
SECTION 4.3 — LOCAL FAIL-FAST CHECKS FOR STAGED MODULE 1 SOURCE
****************************************************************************************************

BUSINESS PURPOSE:
    Prevent downstream decision strategy logic from consuming ambiguous, unmapped, or malformed
    staged input.

SQL PURPOSE:
    Validate the staged table after source selection and normalization.

WHY THESE CHECKS ARE LOCAL TO SECTION 4:
    Section 3 validates the selected Module 1 source table before staging.
    Section 4 validates the actual staged table that downstream Module 2 logic will consume.

***************************************************************************************************/

DO $$
DECLARE
    v_row_count BIGINT;
    v_distinct_application_count BIGINT;
    v_duplicate_application_count BIGINT;
    v_distinct_scenario_count BIGINT;

    v_null_required_count BIGINT;
    v_domain_violation_count BIGINT;
    v_unmapped_product_count BIGINT;
    v_bad_policy_match_count BIGINT;

    v_alias_mismatch_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: staged row count must be positive.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_row_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_row_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: one staged row per application_id.

    Downstream Module 2 strategy outcomes are assigned one row per application per strategy run.
    Duplicate application_id values would create duplicate strategy outcomes and invalidate matched
    strategy comparison.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_distinct_application_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_distinct_application_count <> v_row_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_1_source_applications
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source has % rows but % distinct application_id values. Duplicate application_id group count: %.',
            v_row_count,
            v_distinct_application_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one Module 1 scenario / population in the staged table.

    Multi-scenario processing is intentionally not part of Module 2 v1.0 Section 4.
    This prevents downstream strategy logic from accidentally mixing Module 1 scenarios.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_distinct_scenario_count
    FROM (
        SELECT DISTINCT
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        FROM tmp_m2_stage_1_source_applications
    ) s;

    IF v_distinct_scenario_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source must contain exactly one Module 1 scenario / population. Found %.',
            v_distinct_scenario_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required staged fields must be populated.

    prequalified_flag and returning_customer_flag are intentionally excluded because they are optional
    relationship / context fields.

    loan_term_months is conditionally required:
        required for all products except REVOLVING_LINE, because revolving lines do not require a
        fixed amortizing term in the Module 1 design.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_required_count
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
       OR module1_source_table_name IS NULL

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
            product_type_policy_key <> 'REVOLVING_LINE'
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

    IF v_null_required_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source contains % row(s) with null required staged fields.',
            v_null_required_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: core staged value domains.

    These checks protect downstream approved exposure and approved Expected Loss calculations.

    estimated_pd remains the Module 1 SQL field name and is interpreted as the synthetic
    estimated-PD proxy.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_domain_violation_count
    FROM tmp_m2_stage_1_source_applications
    WHERE requested_amount <= 0
       OR annual_income <= 0
       OR monthly_payment_proxy < 0
       OR requested_monthly_payment_proxy < 0
       OR payment_to_income_ratio < 0
       OR requested_payment_to_income_ratio < 0
       OR amount_to_income_ratio < 0
       OR debt_to_income_ratio < 0
       OR utilization_rate < 0
       OR estimated_pd < 0
       OR estimated_pd > 1
       OR estimated_lgd < 0
       OR estimated_lgd > 1
       OR expected_loss_amount < 0
       OR requested_expected_loss_amount < 0;

    IF v_domain_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: staged source contains % row(s) with invalid value domains.',
            v_domain_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product_type must normalize to a supported Module 2 product policy key.

    Module 1 is not modified. Any display-style product names are normalized only inside this
    Module 2 staging layer.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_unmapped_product_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_type_policy_key IS NULL;

    IF v_unmapped_product_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) have product_type values that cannot be normalized into a supported product_type_policy_key.',
            v_unmapped_product_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product policy configuration must match exactly one policy row.

    This is validation-only. It confirms policy configuration availability but does not apply any
    product-specific policy rule.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_bad_policy_match_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_policy_match_count <> 1
       OR product_policy_config_found_flag IS DISTINCT FROM TRUE;

    IF v_bad_policy_match_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) do not map to exactly one Module 2 product policy configuration.',
            v_bad_policy_match_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Module 2 aliases must match original Module 1 requested-structure values.

    These aliases are naming clarity controls only. Section 4 should not change the underlying
    Module 1 economics.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_alias_mismatch_count
    FROM tmp_m2_stage_1_source_applications
    WHERE requested_expected_loss_amount IS DISTINCT FROM expected_loss_amount
       OR requested_monthly_payment_proxy IS DISTINCT FROM monthly_payment_proxy
       OR requested_payment_to_income_ratio IS DISTINCT FROM payment_to_income_ratio;

    IF v_alias_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) have alias mismatches between Module 1 fields and Module 2 requested-structure aliases.',
            v_alias_mismatch_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 4.4 — LOCAL STAGING SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight local staging checks after Section 4 completes.

IMPORTANT:
    These are not the full Module 2 QA framework.
    They are staging sanity checks only.

    Full decision distribution, risk ordering, affordability sensitivity, reason-code coverage,
    approved exposure, archive validation, and matched strategy comparison QA will be built later.

***************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
4.4.1 Staged row count and application identity count.

Expected:
    row_count = distinct_application_id_count
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS staged_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_1_source_applications;


/*-----------------------------------------------------------------------------------------------
4.4.2 Module 1 scenario / population lineage.

Expected:
    exactly one row in this output for Module 2 v1.0 single-scenario processing.
-----------------------------------------------------------------------------------------------*/
SELECT
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    COUNT(*) AS row_count
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
4.4.3 Source-input lineage.

Expected:
    one module1_input_source and one module1_source_table_name.
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
4.4.4 Product normalization summary.

Purpose:
    Confirm original Module 1 product_type values and their normalized Module 2 product policy keys.
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
4.4.5 Product mapping and product policy configuration diagnostics.

Expected:
    unmapped_product_type_policy_key_rows = 0
    missing_or_ambiguous_product_policy_rows = 0
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) FILTER (WHERE product_type_policy_key IS NULL) AS unmapped_product_type_policy_key_rows,
    COUNT(*) FILTER (
        WHERE product_policy_match_count <> 1
           OR product_policy_config_found_flag IS DISTINCT FROM TRUE
    ) AS missing_or_ambiguous_product_policy_rows
FROM tmp_m2_stage_1_source_applications;


/*-----------------------------------------------------------------------------------------------
4.4.6 Required source-field null check.

Expected:
    null_required_field_rows = 0

Note:
    loan_term_months is conditionally required for non-revolving products.
    prequalified_flag and returning_customer_flag are optional relationship-context fields.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS null_required_field_rows
FROM tmp_m2_stage_1_source_applications
WHERE module1_model_version IS NULL
   OR module1_scenario_set_name IS NULL
   OR module1_scenario_name IS NULL
   OR population_id IS NULL
   OR anchor_date IS NULL
   OR application_seq IS NULL
   OR application_id IS NULL
   OR applicant_id IS NULL
   OR application_date IS NULL
   OR product_type IS NULL
   OR product_type_policy_key IS NULL
   OR score_band IS NULL
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
        product_type_policy_key <> 'REVOLVING_LINE'
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
4.4.7 Alias confirmation for requested-exposure economics.

Expected:
    all mismatch counts = 0

Interpretation:
    requested_expected_loss_amount is the Module 2-preferred alias for Module 1
    expected_loss_amount because Module 1 Expected Loss is calculated on requested exposure.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) FILTER (
        WHERE requested_expected_loss_amount IS DISTINCT FROM expected_loss_amount
    ) AS requested_expected_loss_alias_mismatch_rows,

    COUNT(*) FILTER (
        WHERE requested_monthly_payment_proxy IS DISTINCT FROM monthly_payment_proxy
    ) AS requested_monthly_payment_alias_mismatch_rows,

    COUNT(*) FILTER (
        WHERE requested_payment_to_income_ratio IS DISTINCT FROM payment_to_income_ratio
    ) AS requested_pti_alias_mismatch_rows
FROM tmp_m2_stage_1_source_applications;


/*-----------------------------------------------------------------------------------------------
4.4.8 Synthetic estimated-PD proxy source check.

estimated_pd:
    Finalized Module 1 SQL field name.

Interpretation:
    synthetic estimated-PD proxy.

Expected:
    rows_with_null_estimated_pd = 0
    min and max should remain within 0 to 1 due to Section 3 and Section 4 gatekeepers.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) FILTER (WHERE estimated_pd IS NULL) AS rows_with_null_estimated_pd,
    MIN(estimated_pd) AS min_synthetic_estimated_pd_proxy,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    MAX(estimated_pd) AS max_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_1_source_applications;


/*-----------------------------------------------------------------------------------------------
4.4.9 Requested-exposure Expected Loss source check.

expected_loss_amount:
    Module 1 requested-exposure Expected Loss.

requested_expected_loss_amount:
    Module 2 alias for the same requested-exposure Expected Loss value.

approved_expected_loss_amount:
    Not created in Section 4. It will be calculated later from approved exposure.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS row_count,
    MIN(requested_expected_loss_amount) AS min_requested_expected_loss_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    MAX(requested_expected_loss_amount) AS max_requested_expected_loss_amount
FROM tmp_m2_stage_1_source_applications;


/***************************************************************************************************
END OF SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION

If execution reaches this point:
    1. The selected Module 1 source has been staged into tmp_m2_stage_1_source_applications.
    2. Module 1 scenario lineage has been normalized to module1_scenario_set_name and
       module1_scenario_name.
    3. population_id and application_id have been preserved.
    4. expected_loss_amount has been aliased as requested_expected_loss_amount.
    5. monthly_payment_proxy has been aliased as requested_monthly_payment_proxy.
    6. payment_to_income_ratio has been aliased as requested_payment_to_income_ratio.
    7. estimated_pd has been preserved as the finalized Module 1 SQL field and remains interpreted
       as the synthetic estimated-PD proxy.
    8. product_type has been preserved and product_type_policy_key has been created.
    9. Every staged row has been validated to map to exactly one product policy configuration.

No decision outcomes have been generated.
No reason codes have been assigned.
No approved amount has been calculated.
No approved payment proxy has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No strategy archive rows have been inserted.

***************************************************************************************************/
```

---

# 3. What Section 4 establishes

Section 4 creates the clean Module 2 source foundation:

```text
tmp_m2_stage_1_source_applications
```

It normalizes Module 1 lineage, preserves application identifiers, carries forward borrower / product / affordability / risk fields, aliases requested-exposure economics for Module 2 clarity, preserves `estimated_pd` as the Module 1 synthetic estimated-PD proxy input, and creates `product_type_policy_key` for later product-policy joins.

It also confirms that the staged input contains exactly one Module 1 scenario / population, no duplicate `application_id` values, no missing required source fields, and exactly one product policy configuration per staged row.

---

# 4. What Section 4 intentionally does not build

Section 4 does not build derived risk tiers, affordability tiers, rule flags, hard simulated policy stop logic, counteroffer logic, decision hierarchy, reason-code assignment, approved amount logic, approved payment logic, approved Expected Loss, latest-run final output, archive insert logic, or full QA.

The product policy join is validation-only. It confirms that product policy configuration is available; it does not apply policy rules.

---

# 5. Recommended next build step

Next should be **Section 5 — Derived Strategy Segmentation Layer**.

That section should derive non-decisioning segmentation fields only, such as:

```text
synthetic estimated-risk tier
requested PTI bucket
DTI bucket
requested exposure tier
requested Expected Loss tier
affordability tier
product × score policy segment
```

It should still avoid final decision outcomes, reason codes, approved amount, and approved Expected Loss until the rule-flag and decision-hierarchy sections are built.
<!-- END_MESSAGE C038-M00071 -->


---

<a id="c038-m00073"></a>

### C038-M00073

**Andrew** · 2026-05-06T11:56:15.543000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00073 -->
This is a strong Section 4 build. I agree with the direction.

Section 4 is directionally correct and should be treated as provisionally accepted after the targeted patches below.

It correctly:
- consumes Module 1 latest-run or archive output
- normalizes Module 1 scenario lineage into Module 2 naming
- preserves application and applicant identifiers
- preserves borrower, product, affordability, and risk fields
- aliases requested-exposure economics for Module 2 clarity
- creates product_type_policy_key
- validates product-policy configuration availability
- avoids decision outcomes, reason codes, approved amount, approved Expected Loss, archive insert logic, and full QA

Before we move to Section 5, please make two targeted Section 4 patches.

Do not rewrite Sections 0–4 in full unless absolutely necessary.

================================================================================
1. TARGETED PATCH TO SECTION 4 COMMENTARY
================================================================================

In the Section 4 implementation note, please correct any wording that says Module 2 can consume the “Module 2 latest-run table.”

It should say:

Module 2 can consume either:
- the Module 1 latest-run table; or
- a selected Module 1 scenario archive slice.

Reason:
Section 4 is the Module 1 → Module 2 handoff layer. It should never imply that Module 2 is sourcing from a Module 2 latest-run table at this point.

================================================================================
2. TARGETED PATCH TO SECTION 4 STAGED OUTPUT
================================================================================

Please add Module 2 strategy metadata from tmp_module2_strategy_params into tmp_m2_stage_1_source_applications.

The staged source table should include:

- module2_model_version
- strategy_set_name
- strategy_name
- strategy_version
- strategy_run_id
- strategy_run_ts

These fields should come from the single active strategy parameter row.

Reason:
Every downstream Module 2 stage should carry both:
- Module 1 source lineage; and
- Module 2 strategy lineage.

This keeps traceability clean and prevents later stages from needing to rejoin strategy metadata repeatedly.

Important:
strategy_run_id and strategy_run_ts are audit metadata.
They should support run traceability but should not replace the archive replacement / rerun key.

================================================================================
3. SECTION 4 ACCEPTANCE CRITERIA
================================================================================

After the two targeted patches, Section 4 should be treated as accepted if it establishes:

- one staged row per application_id
- exactly one Module 1 scenario / population slice
- preserved Module 1 scenario lineage
- preserved Module 2 strategy metadata
- preserved application and applicant identifiers
- preserved borrower, product, requested-structure, affordability, and risk fields
- product_type_policy_key created
- every product_type maps to exactly one product policy row
- expected_loss_amount aliased as requested_expected_loss_amount
- monthly_payment_proxy aliased as requested_monthly_payment_proxy
- payment_to_income_ratio aliased as requested_payment_to_income_ratio
- estimated_pd preserved as the Module 1 SQL field and interpreted as the synthetic estimated-PD proxy
- no decision outcomes created
- no decision flags created
- no reason codes assigned
- no approved amount calculated
- no approved payment calculated
- no approved PTI calculated
- no approved Expected Loss calculated
- no final latest-run strategy output created
- no archive rows inserted

================================================================================
4. NEXT BUILD SCOPE: SECTION 5 ONLY
================================================================================

After making the Section 4 patches, please build only:

SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER

Do not build:
- rule flags
- hard simulated policy stop logic
- decline logic
- counteroffer logic
- decision hierarchy
- reason-code assignment
- approved amount calculation
- approved payment calculation
- approved PTI calculation
- approved Expected Loss calculation
- final latest-run output table
- archive insert logic
- full QA framework

Those belong to later sections.

================================================================================
5. SECTION 5 OBJECTIVE
================================================================================

Section 5 should create a non-decisioning segmentation layer that prepares the data for later strategy rules.

Recommended staged table:

tmp_m2_stage_2_strategy_segments

Section 5 should derive interpretable strategy segmentation fields only.

It should not assign decision outcomes.

It should not create approval, decline, manual review, or counteroffer flags.

It should not assign reason codes.

It should not calculate approved exposure.

It should not calculate approved Expected Loss.

Purpose:
Section 5 should translate continuous and categorical Module 1 inputs into policy-readable diagnostic segments that later rule sections can consume.

This is a staging and interpretability layer, not a decision layer.

================================================================================
6. REQUIRED SECTION 5 INPUT
================================================================================

Section 5 should read from:

tmp_m2_stage_1_source_applications

It should preserve all Section 4 fields and add segmentation fields.

It may join to:
- tmp_module2_strategy_params
- tmp_module2_product_policy_params

Purpose of those joins:
- attach threshold values needed for segmentation
- expose product-specific policy context
- support later rule logic

Do not apply final policy outcomes yet.

================================================================================
7. REQUIRED SECTION 5 OUTPUT FIELDS
================================================================================

Please create the following derived segmentation fields.

--------------------------------------------------------------------------------
1. Synthetic estimated-risk tier
--------------------------------------------------------------------------------

Field:
- strategy_risk_tier

Suggested values:
- LOW_SYNTHETIC_RISK
- MODERATE_SYNTHETIC_RISK
- ELEVATED_SYNTHETIC_RISK
- HIGH_SYNTHETIC_RISK
- SEVERE_SYNTHETIC_RISK

This tier should use Module 1 estimated_pd as the synthetic estimated-PD proxy input.

Do not recalculate estimated_pd.

Recommended threshold logic should use the existing strategy parameters:

- approve_max_estimated_pd_proxy
- counteroffer_max_estimated_pd_proxy
- review_max_estimated_pd_proxy
- decline_min_estimated_pd_proxy

Please document equality handling clearly.

--------------------------------------------------------------------------------
2. Requested PTI bucket
--------------------------------------------------------------------------------

Field:
- requested_pti_bucket

Suggested values:
- LOW_REQUESTED_PTI
- MODERATE_REQUESTED_PTI
- ELEVATED_REQUESTED_PTI
- HIGH_REQUESTED_PTI
- SEVERE_REQUESTED_PTI

This should use requested_payment_to_income_ratio from Section 4.

Requested PTI buckets should use product-specific PTI thresholds where available:

- product_approve_max_pti
- product_review_max_pti
- product_decline_min_pti
- counteroffer_target_pti

Do not use a generic one-size-fits-all PTI classification unless the product-specific threshold is missing, which should be treated as a gatekeeper failure.

--------------------------------------------------------------------------------
3. DTI bucket
--------------------------------------------------------------------------------

Field:
- dti_bucket

Suggested values:
- LOW_DTI
- MODERATE_DTI
- ELEVATED_DTI
- HIGH_DTI
- SEVERE_DTI

This should use debt_to_income_ratio.

DTI bucket logic should use the global DTI thresholds:

- approve_max_dti
- review_max_dti
- decline_min_dti

Important interpretation:
DTI is an existing-obligation capacity signal. It is not directly fixed by a counteroffer in Module 2 v1.0.

--------------------------------------------------------------------------------
4. Requested exposure tier
--------------------------------------------------------------------------------

Field:
- requested_exposure_tier

Suggested values:
- BELOW_PRODUCT_MINIMUM
- WITHIN_PRODUCT_LIMITS
- ABOVE_PRODUCT_APPROVAL_CAP
- EXTREME_REQUESTED_EXPOSURE

This should use:
- requested_amount
- product_min_approved_amount
- product_max_approved_amount
- product_max_exposure_reduction_pct

Please define the tier logic explicitly.

Recommended interpretation:
- BELOW_PRODUCT_MINIMUM:
    requested_amount < product_min_approved_amount

- WITHIN_PRODUCT_LIMITS:
    requested_amount between product_min_approved_amount and product_max_approved_amount

- ABOVE_PRODUCT_APPROVAL_CAP:
    requested_amount > product_max_approved_amount, but potentially reducible through a counteroffer within the allowed exposure-reduction constraint

- EXTREME_REQUESTED_EXPOSURE:
    requested_amount is above the product cap by more than the allowed exposure-reduction framework can reasonably address

If you use a formula to distinguish ABOVE_PRODUCT_APPROVAL_CAP from EXTREME_REQUESTED_EXPOSURE, explain it clearly and do not introduce an undocumented magic number.

--------------------------------------------------------------------------------
5. Requested Expected Loss tier
--------------------------------------------------------------------------------

Field:
- requested_expected_loss_tier

Suggested values:
- LOW_REQUESTED_EL
- MODERATE_REQUESTED_EL
- ELEVATED_REQUESTED_EL
- HIGH_REQUESTED_EL
- SEVERE_REQUESTED_EL

This should use requested_expected_loss_amount and product-specific Expected Loss thresholds:

- product_approve_max_requested_el
- product_review_max_requested_el
- product_decline_min_requested_el
- product_approved_el_cap

Important:
requested_expected_loss_amount comes from Module 1 requested exposure.
approved_expected_loss_amount does not exist yet and should not be calculated in Section 5.

--------------------------------------------------------------------------------
6. Product × score policy segment
--------------------------------------------------------------------------------

Field:
- product_score_policy_segment

Recommended construction:
product_type_policy_key || '_' || score_band

If score_band normalization is necessary, preserve original score_band and create a score_band_policy_key.

If Module 1 score_band values already match the expected format, use score_band directly.

Do not modify Module 1.

--------------------------------------------------------------------------------
7. Mixed-signal profile type
--------------------------------------------------------------------------------

Field:
- mixed_signal_profile_type

Suggested values:
- STRONG_CREDIT_HIGH_PTI
- WEAK_CREDIT_LOW_PTI
- LARGE_EXPOSURE_LOW_RISK
- HIGH_RISK_LOW_EXPOSURE
- HIGH_DTI_LOW_REQUESTED_PTI
- MULTIPLE_MIXED_SIGNALS
- NO_MIXED_SIGNAL_PROFILE

This should be diagnostic only.

It should not drive final decisions in Section 5.

Please define priority handling.

Recommended approach:
- If exactly one mixed-signal condition applies, assign that type.
- If more than one applies, assign MULTIPLE_MIXED_SIGNALS.
- If none applies, assign NO_MIXED_SIGNAL_PROFILE.

Do not silently choose one mixed-signal condition over another without documenting the priority convention.

--------------------------------------------------------------------------------
8. Borderline profile indicator
--------------------------------------------------------------------------------

Field:
- borderline_profile_flag

This should identify profiles close to strategy thresholds but should not assign manual review yet.

Important:
Do not introduce a hidden hardcoded borderline buffer.

If borderline_profile_flag requires a proximity buffer, either:

A. Use an existing strategy parameter if one already exists; or

B. Provide a targeted Section 2 / Section 3 patch adding a parameter such as:
   - borderline_threshold_buffer_pct

with a clear gatekeeper rule and commentary; or

C. Omit borderline_profile_flag from Module 2 v1.0 and document it as a future enhancement.

Preferred approach:
If the current parameter framework does not already contain a governed borderline buffer, provide a targeted patch adding one before implementing borderline_profile_flag.

Do not create a 5%, 10%, or similar threshold-adjacent rule without a governed parameter and commentary.

================================================================================
8. THRESHOLD ATTACHMENT REQUIREMENT
================================================================================

Section 5 should attach or carry forward the relevant threshold values used to create segmentation.

This may include:

Global thresholds:
- approve_max_estimated_pd_proxy
- counteroffer_max_estimated_pd_proxy
- review_max_estimated_pd_proxy
- decline_min_estimated_pd_proxy
- global_approve_max_pti
- global_review_max_pti
- global_decline_min_pti
- approve_max_dti
- review_max_dti
- decline_min_dti

Product thresholds:
- product_approve_max_pti
- product_review_max_pti
- product_decline_min_pti
- counteroffer_target_pti
- product_approve_max_requested_el
- product_review_max_requested_el
- product_decline_min_requested_el
- product_approved_el_cap
- product_min_approved_amount
- product_max_approved_amount
- counteroffer_allowed_flag
- manual_review_allowed_flag
- product_min_counteroffer_pct
- product_max_exposure_reduction_pct
- exposure_assignment_method
- approved_amount_rounding_increment

Reason:
Later rule logic should be explainable because the thresholds used for segmentation and strategy rules are visible in the staged data.

================================================================================
9. SECTION 5 LOCAL GATEKEEPERS
================================================================================

At the end of Section 5, include local fail-fast checks.

These should validate:

- row count is unchanged from tmp_m2_stage_1_source_applications
- application_id remains unique
- no null strategy_risk_tier
- no null requested_pti_bucket
- no null dti_bucket
- no null requested_exposure_tier
- no null requested_expected_loss_tier
- no null product_score_policy_segment
- no null mixed_signal_profile_type
- no null product_type_policy_key
- all rows still have exactly one matching product policy configuration
- all required threshold values are available for every row

If borderline_profile_flag is implemented:
- no null borderline_profile_flag
- borderline threshold buffer parameter is present, validated, and documented

If borderline_profile_flag is not implemented:
- explicitly state it is deferred and do not include it in the local gatekeeper checks.

Do not turn these into the full QA framework yet.
These are Section 5 local staging gatekeepers only.

================================================================================
10. SECTION 5 LOCAL SANITY CHECKS
================================================================================

After local gatekeepers, include lightweight sanity-check queries.

Suggested outputs:

1. Row count and distinct application_id count
2. Count by strategy_risk_tier
3. Count by requested_pti_bucket
4. Count by dti_bucket
5. Count by requested_exposure_tier
6. Count by requested_expected_loss_tier
7. Count by product_score_policy_segment
8. Count by mixed_signal_profile_type
9. Count by borderline_profile_flag, if implemented
10. Product × strategy_risk_tier summary
11. Score band × strategy_risk_tier summary
12. PTI bucket × strategy_risk_tier summary

These are staging diagnostics only.

They should not be interpreted as final strategy validation.

================================================================================
11. SECTION 5 COMMENTARY QUALITY
================================================================================

Please keep the same elite commentary standard.

Section 5 comments should explain:

- why segmentation is separated from decision rules
- why estimated_pd is used only as the synthetic estimated-PD proxy input
- why PTI buckets use the requested structure from Module 1
- why DTI remains a borrower-capacity signal rather than a counteroffer-adjustable field
- why requested exposure and approved exposure are separate concepts
- why requested_expected_loss_amount is used before approved_expected_loss_amount exists
- why mixed-signal profiles are diagnostic and not automatic decisions
- why borderline logic requires governed parameterization if implemented
- why threshold values are attached for transparency
- why no decision outcomes are created in Section 5
- why no reason codes are assigned in Section 5
- why no approved amount or approved Expected Loss is calculated in Section 5

================================================================================
12. DELIVERABLE FOR THIS NEXT STEP
================================================================================

Please now provide:

1. Targeted Section 4 patches only:
   - commentary correction from “Module 2 latest-run table” to “Module 1 latest-run table”
   - addition of Module 2 strategy metadata into tmp_m2_stage_1_source_applications

2. If borderline_profile_flag requires a new governed parameter, provide a targeted Section 2 / Section 3 patch before Section 5.

3. Section 5 SQL only:
   DERIVED STRATEGY SEGMENTATION LAYER.

4. A short explanation of what Section 5 establishes.

5. A short explanation of what Section 5 intentionally does not build.

6. The recommended next build step after Section 5.

Do not write Sections 6+ yet.
<!-- END_MESSAGE C038-M00073 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_01.md) · [Next](Part_03.md)
