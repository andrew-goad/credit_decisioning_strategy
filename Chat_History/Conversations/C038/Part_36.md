# Module 2 Decision Simulator Build

## Part 36

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_35.md) · [Next](Part_37.md)

<a id="c038-m00852"></a>

### C038-M00852

**ChatGPT** · 2026-05-09T20:00:57.242719-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00852 -->
Below is the patched **Section 16 header through Section 16.4** copy-paste replacement. This version installs the registry-consumption patch so Section 16 now uses `tmp_m2_campaign_registry_current_run_match` as the primary source for run IDs and campaign evidence IDs, with fallback story metadata only when registry fallback is allowed. I used your provided Section 16 through 16.4 as the base. fileciteturn74file0

```sql
/***************************************************************************************************
SECTION 16 — STRATEGY RUN EVIDENCE CAPTURE AND EXECUTIVE STORY REGISTER
****************************************************************************************************

BUSINESS PURPOSE:
    Persist a compact, executive-ready evidence record for each completed Module 2 strategy run.

    Section 16 answers:

        "How do we capture the key evidence from this completed Module 2 run so the result can be
         reviewed, validated, explained, compared, and later used in portfolio storytelling?"

    The Module 2 latest-run table and archive table preserve row-level simulated strategy outputs.

    Section 13 produces matched comparison diagnostics.
    Section 14 produces validation status evidence.
    Section 15 produces strategy frontier evidence.

    Section 16 distills those outputs into persistent evidence tables so the project can support:
        repeatable run tracking,
        executive storytelling,
        validation-summary drafting,
        README / portfolio evidence,
        LinkedIn campaign evidence,
        parameter traceability,
        product × score segment traceability,
        and future Module 3 growth / economics design.

SQL PURPOSE:
    1. Identify the current completed latest-run Module 2 strategy slice.
    2. Consume the Section 3 campaign registry match as the primary run-ID and story-ID source.
    3. Create fallback current-run story metadata only when registry fallback is allowed.
    4. Confirm required Section 14 and Section 15 temporary evidence outputs exist.
    5. Confirm strategy and product-policy parameter tables exist for parameter snapshot capture.
    6. Create persistent evidence tables if they do not already exist.
    7. Add registry-ID columns to existing evidence tables when needed.
    8. Delete prior evidence rows for the current run key only.
    9. Persist Section 14 validation-status evidence for the current run.
    10. Persist the exact active Module 2 strategy parameter card, product-policy card, and run-story
        metadata as JSONB.
    11. Preserve the current run key so later Section 16 blocks can insert executive and segment
        evidence against the same grain.

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
        Temporary Section 15 strategy frontier summary.

    tmp_module2_strategy_params
        Temporary active Module 2 strategy parameter card.

    tmp_module2_product_policy_params
        Temporary active product-policy parameter card.

TEMPORARY OUTPUTS CREATED IN THIS CHUNK:
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

    This is the same practical completed-run grain used for archive replacement and strategy
    evidence interpretation.

CAMPAIGN REGISTRY ID ROLE:
    Campaign IDs are documentation and evidence-linkage metadata.

    They help connect:

        run roadmap
        → SQL output
        → archive slice
        → comparison result
        → executive evidence row
        → validation evidence row
        → parameter snapshot
        → future Validation Summary claim

    They do not replace the technical SQL run key.

    Technical run key fields remain:

        module1_scenario_set_name
        module1_scenario_name
        population_id
        strategy_set_name
        strategy_name
        strategy_version

WHY SECTION 16 EXISTS:
    During a multi-run scenario / strategy campaign, the user should not have to manually collect
    key results from many separate QA grids after every run.

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
    Archive persistence is already governed by Section 12.

    Section 16 does not insert, delete, update, or repair archive rows.

    Evidence capture and archive persistence are separate governance functions.

WHY DELETE / INSERT IS USED FOR EVIDENCE:
    A strategy slice may be rerun under governed archive replacement behavior.

    Evidence rows should reflect the current accepted version of that run key, not accumulate stale
    duplicates for the same strategy / scenario / population evidence grain.

    Therefore Section 16 deletes and replaces evidence rows only for the current run key in the
    evidence tables.

READ-ONLY / PERSISTENCE BOUNDARY:
    Section 16 does not modify:
        credit_decisioning_sim.strategy_decisions
        credit_decisioning_sim.strategy_decisions_archive

    Section 16 does create and maintain separate evidence tables:
        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

    Section 16 deletes and replaces evidence rows only for the current run key in these evidence
    tables.

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
        or lifetime value.

INTERPRETATION BOUNDARIES:
    estimated_pd remains the SQL field name from Module 1 and is interpreted as the synthetic
    estimated-PD proxy.

    requested_expected_loss_amount means requested-exposure Expected Loss from Module 1.

    approved_expected_loss_amount means simulated approved-exposure Expected Loss after Module 2
    exposure treatment.

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
        The validation expectation was satisfied.

    REVIEW:
        The pattern should be interpreted before documentation.
        REVIEW does not automatically mean the strategy run is invalid.

    NOT_APPLICABLE:
        The validation test depends on conditions not present in the current run context.

GOVERNANCE ROLE:
    Section 16 turns SQL QA and comparison outputs into durable evidence.

    It supports:
        traceability,
        validation-summary drafting,
        executive review,
        README results,
        LinkedIn story development,
        campaign-run auditability,
        and future Module 3 design.

COMMON MISUSE TO AVOID:
    Do not treat evidence rows as replacement for the archive.
    Do not treat evidence rows as raw applicant-level output.
    Do not interpret Section 16 as recalculating strategy results.
    Do not interpret campaign IDs as replacing technical SQL lineage.
    Do not interpret simulated offer exposure as booked exposure.
    Do not interpret reason-code evidence as customer communication language.
    Do not interpret Module 3 readiness fields as revenue or profitability results.

***************************************************************************************************/



/***************************************************************************************************
SECTION 16.0 — CURRENT RUN KEY, REGISTRY STORY METADATA, AND EVIDENCE CAPTURE GATEKEEPER
****************************************************************************************************

BUSINESS PURPOSE:
    Identify the current latest-run Module 2 strategy slice and confirm that evidence capture can be
    performed safely.

    Section 16.0 answers:

        "Which completed strategy run is being captured, what campaign registry IDs identify it,
         and are the upstream validation, frontier, strategy-parameter, product-policy, and story
         helper objects available?"

SQL PURPOSE:
    1. Create tmp_m2_current_run_key from credit_decisioning_sim.strategy_decisions.
    2. Confirm or create a safe temporary campaign-registry match helper.
    3. Create tmp_m2_current_run_story_params using campaign registry values first.
    4. Use fallback story metadata only where registry fallback is allowed.
    5. Validate that credit_decisioning_sim.strategy_decisions exists and is populated.
    6. Validate that the latest-run table resolves to exactly one run key.
    7. Validate that tmp_m2_validation_status_summary exists.
    8. Validate that tmp_m2_strategy_frontier_executive_summary exists.
    9. Validate that tmp_module2_strategy_params exists.
    10. Validate that tmp_module2_product_policy_params exists.
    11. Validate that exactly one active story-parameter row exists.
    12. Validate registry match status when campaign_registry_required_flag = TRUE.

TEMPORARY OUTPUTS:
    tmp_m2_current_run_key
    tmp_m2_current_run_story_params

CURRENT RUN KEY GRAIN:
    One row representing the current completed latest-run strategy slice:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

WHY CURRENT RUN KEY MUST HAVE EXACTLY ONE ROW:
    Section 16 evidence tables are run-level evidence outputs.

    A mixed latest-run table containing multiple strategies, multiple scenarios, or multiple
    populations would make evidence capture ambiguous.

    Section 16 therefore fails fast if tmp_m2_current_run_key does not contain exactly one row.

WHY CAMPAIGN REGISTRY METADATA IS PRIMARY:
    Formal campaign evidence should tie SQL output to stable run-roadmap IDs.

    Registry IDs make the later Validation Summary easier to trace because they connect:
        technical run key,
        module1_run_id,
        module2_run_id,
        showcase_id,
        comparison_group_id,
        validation_evidence_group_id,
        README storyline label,
        LinkedIn post sequence,
        and validation-summary section hint.

WHY FALLBACK STORY LABELS STILL EXIST:
    Formal campaign registry metadata may not be available during ad hoc development.

    Fallback labels allow evidence capture to proceed only when the strategy parameter allows registry
    fallback.

    For formal campaign documentation, registry-matched evidence is preferred.

DEPENDENCY BOUNDARY:
    Section 16 depends on Section 14 and Section 15 outputs.

    Section 16 does not rebuild those outputs.

    If tmp_m2_validation_status_summary or tmp_m2_strategy_frontier_executive_summary is missing,
    Section 16 fails clearly rather than capturing incomplete evidence.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.0A Reset current-run evidence helper objects.

Business purpose:
    Remove prior current-run helper objects so Section 16 captures the current latest-run output
    rather than a stale helper table from an earlier session.

SQL purpose:
    Drop only temporary Section 16 helper objects.

Important:
    This section does not drop tmp_m2_campaign_registry_current_run_match.

    That helper is created in Section 3 and is the preferred registry source for evidence IDs.
    If the helper is missing, Section 16.0C creates a safe fallback helper so ad hoc development can
    still proceed when registry fallback is allowed.

Boundary:
    This does not delete persistent evidence rows.
    Evidence replacement is handled later by Section 16.2 using the current run key.
-----------------------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS tmp_m2_current_run_key;
DROP TABLE IF EXISTS tmp_m2_current_run_story_params;



/*-----------------------------------------------------------------------------------------------
16.0B Materialize the current latest-run key.

Business purpose:
    Convert the current latest-run output into a one-row run key that all Section 16 evidence inserts
    can join against.

SQL purpose:
    Pull distinct strategy, Module 1 lineage, archive-control, source, and timestamp fields from the
    latest-run output.

Inline logic:
    SELECT DISTINCT is used because the latest-run table is applicant-grain.

    Every applicant row should carry the same strategy identity and Module 1 scenario lineage.

    If more than one distinct run key exists, the gatekeeper below fails.
-----------------------------------------------------------------------------------------------*/

CREATE TEMP TABLE tmp_m2_current_run_key
ON COMMIT PRESERVE ROWS
AS
SELECT DISTINCT
    /***********************************************************************************************
    Module 2 strategy identity.

    These fields identify the downstream strategy being captured.
    ***********************************************************************************************/
    module2_model_version,
    strategy_set_name,
    strategy_name,
    strategy_version,
    strategy_run_id,
    strategy_run_ts,

    /***********************************************************************************************
    Archive and final-resolution controls.

    These fields explain how the run was persisted and how failed counteroffers were resolved.
    ***********************************************************************************************/
    archive_run_flag,
    strategy_archive_reset_mode,
    failed_counteroffer_resolution,

    /***********************************************************************************************
    Module 1 source mode.

    These fields document whether Module 2 consumed latest-run Module 1 output or an archived Module
    1 scenario slice.
    ***********************************************************************************************/
    module1_input_source,
    module1_source_table_name,

    /***********************************************************************************************
    Module 1 lineage.

    These fields identify the upstream synthetic population and scenario environment.
    ***********************************************************************************************/
    module1_model_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    anchor_date,

    /***********************************************************************************************
    Latest-run materialization timestamp.

    Audit metadata only.
    This is not a strategy-comparison key.
    ***********************************************************************************************/
    latest_output_created_ts

FROM credit_decisioning_sim.strategy_decisions;



/*-----------------------------------------------------------------------------------------------
16.0C Ensure current-run campaign registry helper is available.

Business purpose:
    Make Section 16 robust whether it is run immediately after Section 3 or during ad hoc evidence
    refresh work.

SQL purpose:
    If tmp_m2_campaign_registry_current_run_match does not exist, create a temporary fallback helper
    with the registry fields Section 16 expects.

    If the helper exists but lacks newer registry fields, add those fields.

    If the helper has no rows, insert one fallback status row scoped to the current run key.

Formal campaign behavior:
    If campaign_registry_required_flag = TRUE, the gatekeeper below still requires:

        run_registry_match_status = 'RUN_REGISTRY_MATCHED'

    Therefore this fallback helper does not hide missing formal registry mapping.

Ad hoc behavior:
    If campaign_registry_required_flag = FALSE, fallback metadata is allowed and evidence capture can
    proceed with explicit fallback status.
-----------------------------------------------------------------------------------------------*/

DO $$
BEGIN
    /***********************************************************************************************
    Create a safe fallback registry helper only when Section 3 did not create one in the current
    session.

    The table shape mirrors the fields Section 16 consumes.
    ***********************************************************************************************/
    IF COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_campaign_registry_current_run_match'),
        TO_REGCLASS('tmp_m2_campaign_registry_current_run_match')
    ) IS NULL THEN

        CREATE TEMP TABLE tmp_m2_campaign_registry_current_run_match (
            campaign_registry_required_flag         BOOLEAN,

            module1_scenario_set_name              TEXT,
            module1_scenario_name                  TEXT,
            population_id                          TEXT,

            strategy_set_name                      TEXT,
            strategy_name                          TEXT,
            strategy_version                       TEXT,

            registry_match_count                   BIGINT,
            run_registry_match_status              TEXT,

            module1_run_id                         TEXT,
            module2_run_id                         TEXT,
            run_sequence_number                    INTEGER,

            showcase_id                            TEXT,
            showcase_name                          TEXT,
            comparison_group_id                    TEXT,
            validation_evidence_group_id           TEXT,

            module1_parameter_family_changed        TEXT,
            module1_parameter_change_summary        TEXT,

            module2_strategy_family_changed         TEXT,
            module2_parameter_change_summary        TEXT,

            expected_storyline                     TEXT,
            validation_summary_section_hint         TEXT,
            readme_storyline_label                 TEXT,
            linkedin_post_sequence                 INTEGER
        ) ON COMMIT PRESERVE ROWS;
    END IF;


    /***********************************************************************************************
    Schema hardening for the temporary registry helper.

    This protects Section 16 if the helper was created by an earlier version of Section 3 that did
    not yet carry all registry-story fields.
    ***********************************************************************************************/
    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module1_scenario_set_name TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module1_scenario_name TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS population_id TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS strategy_set_name TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS strategy_name TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS strategy_version TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module1_run_id TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module2_run_id TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS showcase_id TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS showcase_name TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module1_parameter_family_changed TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module1_parameter_change_summary TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module2_strategy_family_changed TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS module2_parameter_change_summary TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS expected_storyline TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;

    ALTER TABLE tmp_m2_campaign_registry_current_run_match
        ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;


    /***********************************************************************************************
    Insert a fallback row only if the helper is empty.

    This preserves Section 3 output when it exists.

    The fallback status remains explicit so evidence rows clearly show whether registry matching was
    available.
    ***********************************************************************************************/
    IF NOT EXISTS (
        SELECT 1
        FROM tmp_m2_campaign_registry_current_run_match
    ) THEN
        INSERT INTO tmp_m2_campaign_registry_current_run_match (
            campaign_registry_required_flag,

            module1_scenario_set_name,
            module1_scenario_name,
            population_id,

            strategy_set_name,
            strategy_name,
            strategy_version,

            registry_match_count,
            run_registry_match_status
        )
        SELECT
            COALESCE(p.campaign_registry_required_flag, FALSE),

            k.module1_scenario_set_name,
            k.module1_scenario_name,
            k.population_id,

            k.strategy_set_name,
            k.strategy_name,
            k.strategy_version,

            0::BIGINT AS registry_match_count,

            CASE
                WHEN COALESCE(p.campaign_registry_required_flag, FALSE) IS TRUE
                    THEN 'RUN_REGISTRY_NOT_FOUND_REQUIRED_REVIEW'
                ELSE 'RUN_REGISTRY_NOT_FOUND_FALLBACK_ALLOWED'
            END AS run_registry_match_status

        FROM tmp_m2_current_run_key k

        CROSS JOIN (
            SELECT
                campaign_registry_required_flag
            FROM tmp_module2_strategy_params
            WHERE active_strategy_flag IS TRUE
            LIMIT 1
        ) p

        LIMIT 1;
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
16.0D Build temporary current-run story metadata.

Business purpose:
    Attach human-readable campaign / story labels to the technical run key.

Patch behavior:
    Registry fields from tmp_m2_campaign_registry_current_run_match are now the primary source.

    Fallback labels are used only where registry fields are NULL.

SQL purpose:
    Derive run IDs, showcase labels, parameter-family labels, expected storylines, documentation
    labels, validation evidence IDs, and registry match status.

Why this is still temporary:
    The purpose is evidence capture support.

    It does not modify the archive.
    It does not modify strategy decisions.
    It does not change strategy thresholds.

Design note:
    Formal campaign runs should show:

        run_registry_match_status = 'RUN_REGISTRY_MATCHED'

    Ad hoc runs may show fallback status only when the active strategy allows registry fallback.
-----------------------------------------------------------------------------------------------*/

CREATE TEMP TABLE tmp_m2_current_run_story_params
ON COMMIT PRESERVE ROWS
AS
WITH k AS (
    SELECT *
    FROM tmp_m2_current_run_key
    LIMIT 1
),

reg AS (
    SELECT *
    FROM tmp_m2_campaign_registry_current_run_match
    LIMIT 1
),

fallback_labels AS (
    SELECT
        /*******************************************************************************************
        Fallback showcase label.

        Used only if registry showcase_name is unavailable.
        *******************************************************************************************/
        CASE
            WHEN k.module1_scenario_name IN (
                    'BASELINE_V2',
                    'CREDIT_BOX_BASELINE_REFERENCE',
                    'PRODUCT_MIX_BASELINE_REFERENCE',
                    'EXPOSURE_BASELINE_REFERENCE',
                    'LGD_BASELINE_REFERENCE'
                 )
                THEN 'BASELINE_REFERENCE'

            WHEN k.module1_scenario_name ILIKE '%RATE%'
                THEN 'RATE_SENSITIVITY_SHOWCASE'

            WHEN k.module1_scenario_name ILIKE '%SCORE%'
              OR k.module1_scenario_name ILIKE '%PRIME%'
              OR k.module1_scenario_name ILIKE '%CREDIT_STRESS%'
                THEN 'CREDIT_BOX_SHOWCASE'

            WHEN k.module1_scenario_name ILIKE '%MIX%'
                THEN 'PORTFOLIO_MIX_SHOWCASE'

            WHEN k.module1_scenario_name ILIKE '%BALANCE%'
              OR k.module1_scenario_name ILIKE '%EXPOSURE%'
                THEN 'EXPOSURE_INTENSITY_SHOWCASE'

            WHEN k.module1_scenario_name ILIKE '%LGD%'
              OR k.module1_scenario_name ILIKE '%SEVERITY%'
                THEN 'SEVERITY_SENSITIVITY_SHOWCASE'

            ELSE 'UNCLASSIFIED_SHOWCASE'
        END AS fallback_showcase_name,


        /*******************************************************************************************
        Fallback Module 1 parameter family.

        Used only if registry module1_parameter_family_changed is unavailable.
        *******************************************************************************************/
        CASE
            WHEN k.module1_scenario_name ILIKE '%RATE_UP%'
              OR k.module1_scenario_name ILIKE '%RATE_DOWN%'
                THEN 'RATE_ENVIRONMENT'

            WHEN k.module1_scenario_name ILIKE '%SCORE%'
              OR k.module1_scenario_name ILIKE '%PRIME%'
              OR k.module1_scenario_name ILIKE '%CREDIT_STRESS%'
                THEN 'SCORE_MIX'

            WHEN k.module1_scenario_name ILIKE '%PRODUCT%'
              OR k.module1_scenario_name ILIKE '%UNSECURED%'
              OR k.module1_scenario_name ILIKE '%REVOLVING%'
              OR k.module1_scenario_name ILIKE '%SECURED%'
                THEN 'PRODUCT_MIX'

            WHEN k.module1_scenario_name ILIKE '%BALANCE%'
              OR k.module1_scenario_name ILIKE '%EXPOSURE%'
                THEN 'EXPOSURE_INTENSITY'

            WHEN k.module1_scenario_name ILIKE '%LGD%'
              OR k.module1_scenario_name ILIKE '%SEVERITY%'
                THEN 'LGD_SEVERITY'

            ELSE 'BASELINE_OR_UNCLASSIFIED'
        END AS fallback_module1_parameter_family_changed,


        /*******************************************************************************************
        Fallback Module 1 parameter summary.

        Used only if registry module1_parameter_change_summary is unavailable.
        *******************************************************************************************/
        CASE
            WHEN k.module1_scenario_name = 'BASELINE_V2'
                THEN 'Module 1 baseline scenario using accepted V2.0 defaults.'

            WHEN k.module1_scenario_name ILIKE '%RATE_UP%'
                THEN 'Module 1 rate-up sensitivity scenario.'

            WHEN k.module1_scenario_name ILIKE '%RATE_DOWN%'
                THEN 'Module 1 rate-down sensitivity scenario.'

            WHEN k.module1_scenario_name ILIKE '%PRIME%'
                THEN 'Module 1 score-mix scenario emphasizing prime or near-prime composition.'

            WHEN k.module1_scenario_name ILIKE '%UNSECURED%'
                THEN 'Module 1 product-mix or severity scenario emphasizing unsecured exposure.'

            WHEN k.module1_scenario_name ILIKE '%REVOLVING%'
                THEN 'Module 1 product-mix scenario emphasizing revolving exposure.'

            WHEN k.module1_scenario_name ILIKE '%SEVERITY%'
              OR k.module1_scenario_name ILIKE '%LGD%'
                THEN 'Module 1 LGD / severity sensitivity scenario.'

            ELSE 'Module 1 scenario parameter change summary not manually specified.'
        END AS fallback_module1_parameter_change_summary,


        /*******************************************************************************************
        Fallback Module 2 strategy family.

        Used only if registry module2_strategy_family_changed is unavailable.
        *******************************************************************************************/
        CASE
            WHEN k.strategy_name = 'BASELINE_STRATEGY'
                THEN 'BASELINE'

            WHEN k.strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY'
                THEN 'RISK_TIGHTENING'

            WHEN k.strategy_name = 'GROWTH_ORIENTED_STRATEGY'
                THEN 'GROWTH'

            WHEN k.strategy_name = 'TIGHTER_AFFORDABILITY_STRATEGY'
                THEN 'AFFORDABILITY_TIGHTENING'

            WHEN k.strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
                THEN 'COUNTEROFFER_MANAGEMENT'

            WHEN k.strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
                THEN 'PRODUCT_GUARDRAILS'

            WHEN k.strategy_name = 'MANUAL_REVIEW_REDUCTION_STRATEGY'
                THEN 'OPERATIONS_REVIEW_REDUCTION'

            ELSE 'UNCLASSIFIED_STRATEGY'
        END AS fallback_module2_strategy_family_changed,


        /*******************************************************************************************
        Fallback Module 2 parameter summary.

        Used only if registry module2_parameter_change_summary is unavailable.
        *******************************************************************************************/
        CASE
            WHEN k.strategy_name = 'BASELINE_STRATEGY'
                THEN 'Module 2 baseline strategy using accepted V1.0 defaults.'

            WHEN k.strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY'
                THEN 'Module 2 strategy tightens synthetic estimated-PD proxy tolerance thresholds.'

            WHEN k.strategy_name = 'GROWTH_ORIENTED_STRATEGY'
                THEN 'Module 2 strategy loosens selected synthetic-risk, PTI, and DTI tolerances for growth-oriented comparison.'

            WHEN k.strategy_name = 'TIGHTER_AFFORDABILITY_STRATEGY'
                THEN 'Module 2 strategy tightens PTI thresholds and counteroffer target PTI.'

            WHEN k.strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
                THEN 'Module 2 strategy emphasizes reduced-exposure treatment through tighter approved amount, approved EL, and PTI constraints.'

            WHEN k.strategy_name = 'PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY'
                THEN 'Module 2 strategy applies tighter guardrails to selected unsecured / revolving products.'

            WHEN k.strategy_name = 'MANUAL_REVIEW_REDUCTION_STRATEGY'
                THEN 'Module 2 strategy resolves failed counteroffers to final no-offer outcomes to reduce unresolved manual review.'

            ELSE 'Module 2 strategy parameter change summary not manually specified.'
        END AS fallback_module2_parameter_change_summary,


        /*******************************************************************************************
        Fallback expected storyline.

        Used only if registry expected_storyline is unavailable.
        *******************************************************************************************/
        CASE
            WHEN k.strategy_name = 'BASELINE_STRATEGY'
                THEN 'Establish reference strategy behavior for this Module 1 scenario.'

            WHEN k.strategy_name = 'TIGHTER_SYNTHETIC_RISK_STRATEGY'
                THEN 'Demonstrate risk-discipline tradeoff: lower simulated offer exposure and approved Expected Loss, with higher decline rate.'

            WHEN k.strategy_name = 'GROWTH_ORIENTED_STRATEGY'
                THEN 'Demonstrate growth tradeoff: higher simulated offer exposure and approved amount, with measurable risk impact.'

            WHEN k.strategy_name = 'COUNTEROFFER_FIRST_EXPOSURE_STRATEGY'
                THEN 'Demonstrate exposure-management tradeoff through reduced approved amount, improved PTI, and lower approved Expected Loss.'

            ELSE 'Expected storyline not manually specified.'
        END AS fallback_expected_storyline

    FROM k
)

SELECT
    /***********************************************************************************************
    One active story row is expected.

    The Section 16 gatekeeper validates this cardinality.
    ***********************************************************************************************/
    TRUE AS active_story_flag,


    /***********************************************************************************************
    Registry governance status.

    These fields make evidence rows clear about whether they are registry-matched or fallback-based.
    ***********************************************************************************************/
    COALESCE(reg.campaign_registry_required_flag, FALSE) AS campaign_registry_required_flag,
    COALESCE(reg.registry_match_count, 0) AS registry_match_count,
    COALESCE(reg.run_registry_match_status, 'RUN_REGISTRY_NOT_AVAILABLE_SECTION3_NOT_RUN')
        AS run_registry_match_status,


    /***********************************************************************************************
    Campaign run IDs.

    Registry values are preferred.

    Fallback values are readable but should not be used as final campaign evidence IDs when formal
    registry matching is required.
    ***********************************************************************************************/
    COALESCE(reg.module1_run_id, k.module1_scenario_name) AS module1_run_id,

    COALESCE(
        reg.module2_run_id,
        k.module1_scenario_name || '__' || k.strategy_name
    ) AS module2_run_id,

    reg.run_sequence_number,


    /***********************************************************************************************
    Showcase and comparison identifiers.

    These fields support README, LinkedIn, comparison, and Validation Summary linkage.
    ***********************************************************************************************/
    reg.showcase_id,
    COALESCE(reg.showcase_name, f.fallback_showcase_name) AS showcase_name,
    reg.comparison_group_id,
    reg.validation_evidence_group_id,

    reg.readme_storyline_label,
    reg.linkedin_post_sequence,
    reg.validation_summary_section_hint,


    /***********************************************************************************************
    Module 1 scenario story fields.

    Registry values are preferred because they align to the formal campaign roadmap.
    ***********************************************************************************************/
    COALESCE(
        reg.module1_parameter_family_changed,
        f.fallback_module1_parameter_family_changed
    ) AS module1_parameter_family_changed,

    COALESCE(
        reg.module1_parameter_change_summary,
        f.fallback_module1_parameter_change_summary
    ) AS module1_parameter_change_summary,


    /***********************************************************************************************
    Module 2 strategy story fields.

    Registry values are preferred because they align to the formal campaign roadmap.
    ***********************************************************************************************/
    COALESCE(
        reg.module2_strategy_family_changed,
        f.fallback_module2_strategy_family_changed
    ) AS module2_strategy_family_changed,

    COALESCE(
        reg.module2_parameter_change_summary,
        f.fallback_module2_parameter_change_summary
    ) AS module2_parameter_change_summary,


    /***********************************************************************************************
    Expected storyline.

    Registry value is preferred.
    Fallback value remains available for development runs.
    ***********************************************************************************************/
    COALESCE(reg.expected_storyline, f.fallback_expected_storyline) AS expected_storyline,


    /***********************************************************************************************
    Reviewer-populated narrative fields.

    These intentionally start NULL.

    observed_storyline may be filled from Section 15 frontier interpretation in Section 16.6.
    validation_notes may be manually populated later after QA review.
    ***********************************************************************************************/
    NULL::TEXT AS observed_storyline,
    NULL::TEXT AS validation_notes

FROM k
LEFT JOIN reg
    ON TRUE
CROSS JOIN fallback_labels f
LIMIT 1;



/*-----------------------------------------------------------------------------------------------
16.0E Evidence capture fail-fast gatekeeper.

Business purpose:
    Prevent incomplete or ambiguous evidence capture.

Why fail fast:
    Evidence capture is persistent.

    It is better to stop than to create evidence rows with:
        no latest-run output,
        multiple run keys,
        missing validation summary,
        missing frontier summary,
        missing parameter tables,
        ambiguous story metadata,
        or missing required campaign registry mapping.

SQL logic:
    This block validates object existence, row counts, run-key cardinality, dependency availability,
    story-row cardinality, and registry match requirements before Section 16 creates or replaces
    persistent evidence rows.
-----------------------------------------------------------------------------------------------*/

DO $$
DECLARE
    v_latest_table_exists BOOLEAN;
    v_latest_row_count BIGINT;
    v_current_key_count BIGINT;
    v_validation_summary_exists BOOLEAN;
    v_frontier_summary_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;
    v_product_policy_params_exists BOOLEAN;
    v_story_param_count BIGINT;

    v_campaign_registry_required_flag BOOLEAN;
    v_run_registry_match_status TEXT;
    v_registry_match_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output table must exist.

    Section 16 captures evidence from the completed latest-run output created in Section 11.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions') IS NOT NULL
    INTO v_latest_table_exists;

    IF v_latest_table_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: credit_decisioning_sim.strategy_decisions does not exist.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: latest-run output must contain rows.

    Evidence capture from an empty latest-run output would create misleading documentation artifacts.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_latest_row_count
    FROM credit_decisioning_sim.strategy_decisions;

    IF v_latest_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: latest-run strategy_decisions table contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: current run key must resolve to exactly one strategy / scenario / population slice.

    If this count is greater than one, the latest-run table is mixed and Section 16 cannot safely
    create one evidence record.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_current_key_count
    FROM tmp_m2_current_run_key;

    IF v_current_key_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: expected exactly one current latest-run strategy / Module 1 scenario / population key, found %.',
            v_current_key_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 14 validation summary must exist.

    Section 16 does not rebuild validation evidence. It persists Section 14 output.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_validation_status_summary'),
        TO_REGCLASS('tmp_m2_validation_status_summary')
    ) IS NOT NULL
    INTO v_validation_summary_exists;

    IF v_validation_summary_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_m2_validation_status_summary is required before evidence capture.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 15 frontier executive summary must exist.

    Section 16 later uses frontier fields for executive story capture. Failing here prevents partial
    evidence capture without frontier context.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_frontier_executive_summary'),
        TO_REGCLASS('tmp_m2_strategy_frontier_executive_summary')
    ) IS NOT NULL
    INTO v_frontier_summary_exists;

    IF v_frontier_summary_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_m2_strategy_frontier_executive_summary is required before evidence capture.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: active strategy parameter card must exist.

    Section 16 snapshots the parameter card so future documentation can trace evidence back to the
    exact strategy configuration.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_strategy_params'),
        TO_REGCLASS('tmp_module2_strategy_params')
    ) IS NOT NULL
    INTO v_strategy_params_exists;

    IF v_strategy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_module2_strategy_params is required for parameter snapshot capture.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product-policy parameter card must exist.

    Product-policy parameters are critical for explaining approved exposure, counteroffer feasibility,
    approved Expected Loss, and product × score segment evidence.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_product_policy_params'),
        TO_REGCLASS('tmp_module2_product_policy_params')
    ) IS NOT NULL
    INTO v_product_policy_params_exists;

    IF v_product_policy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: tmp_module2_product_policy_params is required for product-policy parameter snapshot capture.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active story-parameter row.

    The story helper should produce one and only one evidence-story row for the current run key.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_story_param_count
    FROM tmp_m2_current_run_story_params
    WHERE active_story_flag IS TRUE;

    IF v_story_param_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: expected exactly one active story-parameter row, found %.',
            v_story_param_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: registry match status when formal campaign registry is required.

    Formal campaign evidence should not silently fall back to generated labels.

    If campaign_registry_required_flag = TRUE, Section 16 requires:
        run_registry_match_status = RUN_REGISTRY_MATCHED
        registry_match_count = 1

    This protects the connection from code output to validation-summary IDs.
    -------------------------------------------------------------------------------------------*/
    SELECT
        COALESCE(campaign_registry_required_flag, FALSE),
        COALESCE(registry_match_count, 0),
        COALESCE(run_registry_match_status, '<NULL>')
    INTO
        v_campaign_registry_required_flag,
        v_registry_match_count,
        v_run_registry_match_status
    FROM tmp_m2_current_run_story_params
    WHERE active_story_flag IS TRUE
    LIMIT 1;

    IF v_campaign_registry_required_flag IS TRUE
       AND (
            v_run_registry_match_status <> 'RUN_REGISTRY_MATCHED'
            OR v_registry_match_count <> 1
       ) THEN
        RAISE EXCEPTION
            'Module 2 Section 16 failure: formal campaign registry is required, but current run is not registry-matched. Status: %, match count: %.',
            v_run_registry_match_status,
            v_registry_match_count;
    END IF;
END $$;



/***************************************************************************************************
SECTION 16.1 — CREATE PERSISTENT EVIDENCE TABLES
****************************************************************************************************

BUSINESS PURPOSE:
    Create persistent tables that preserve run-level executive evidence, validation evidence,
    parameter snapshots, and product × score segment evidence.

    Section 16.1 answers:

        "Where will the project store durable evidence for this completed strategy run?"

SQL PURPOSE:
    1. Create credit_decisioning_sim.strategy_run_evidence_summary if it does not exist.
    2. Create credit_decisioning_sim.strategy_run_validation_evidence if it does not exist.
    3. Create credit_decisioning_sim.strategy_run_parameter_snapshot if it does not exist.
    4. Create credit_decisioning_sim.strategy_run_segment_evidence_summary if it does not exist.
    5. Add campaign registry ID columns to existing evidence tables when needed.
    6. Create practical evidence-table indexes.

PERSISTENT TABLE PURPOSES:
    strategy_run_evidence_summary:
        One row per completed strategy / Module 1 scenario / population run.
        Stores executive story, outcome metrics, exposure metrics, risk metrics, validation counts,
        frontier classification, reason-code story fields, run registry fields, comparison IDs, and
        Module 3 readiness flags.

    strategy_run_validation_evidence:
        One row per completed run × validation test.
        Stores Section 14 validation status details plus run registry identifiers.

    strategy_run_parameter_snapshot:
        One row per completed run.
        Stores JSONB snapshots of active strategy parameters, product policy parameters, and run-story
        metadata plus run registry identifiers.

    strategy_run_segment_evidence_summary:
        One row per completed run × product_type_policy_key × score_band_policy_key.
        Stores segment evidence for product × score storytelling and future strategy analysis plus
        run registry identifiers.

GRAIN:
    Main executive evidence:
        one row per Module 1 scenario × Module 2 strategy version

    Validation evidence:
        one row per run × validation test

    Parameter snapshot:
        one row per run

    Segment evidence:
        one row per run × product_type_policy_key × score_band_policy_key

WHY CREATE TABLE IF NOT EXISTS IS USED:
    Evidence tables should persist across the campaign.

    They should not be dropped during ordinary reruns.

SCHEMA EVOLUTION NOTE:
    CREATE TABLE IF NOT EXISTS does not alter existing table schemas.

    This patched section therefore also includes ALTER TABLE ADD COLUMN IF NOT EXISTS statements to
    add registry-linkage fields to evidence tables that may already exist from a prior Section 16
    version.

BOUNDARY:
    This section creates and hardens evidence tables only.

    It does not insert evidence rows yet.
    It does not modify latest-run output.
    It does not modify archive output.
    It does not calculate strategy metrics.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.1A Create one-row executive evidence summary table.

Business purpose:
    Store the executive story and primary run-level metrics for each completed run.

Column grouping:
    Columns are intentionally grouped by evidence identity, registry metadata, story metadata,
    strategy identity, Module 1 lineage, outcome metrics, exposure metrics, growth-readiness fields,
    risk / Expected Loss metrics, reason-code fields, frontier fields, validation summary fields,
    segment driver fields, and Module 3 readiness fields.
-----------------------------------------------------------------------------------------------*/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_evidence_summary (
    /***********************************************************************************************
    Evidence snapshot identity.

    evidence_snapshot_id is generated at capture time.
    It supports traceability but is not the run-key grain.
    ***********************************************************************************************/
    evidence_snapshot_ts TIMESTAMP,
    evidence_snapshot_id TEXT,

    /***********************************************************************************************
    Campaign registry and story metadata.

    These fields link SQL evidence to the run roadmap, README / LinkedIn storyline, and Validation
    Summary structure.
    ***********************************************************************************************/
    campaign_registry_required_flag BOOLEAN,
    registry_match_count BIGINT,
    run_registry_match_status TEXT,

    module1_run_id TEXT,
    module2_run_id TEXT,
    run_sequence_number INTEGER,

    showcase_id TEXT,
    showcase_name TEXT,
    comparison_group_id TEXT,
    validation_evidence_group_id TEXT,

    readme_storyline_label TEXT,
    linkedin_post_sequence INTEGER,
    validation_summary_section_hint TEXT,

    module1_parameter_family_changed TEXT,
    module1_parameter_change_summary TEXT,
    module2_strategy_family_changed TEXT,
    module2_parameter_change_summary TEXT,
    expected_storyline TEXT,
    observed_storyline TEXT,
    validation_notes TEXT,

    /***********************************************************************************************
    Module 2 strategy identity.
    ***********************************************************************************************/
    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    /***********************************************************************************************
    Output / archive timestamp metadata.

    These fields support traceability only.
    They are not comparison keys and not business outcomes.
    ***********************************************************************************************/
    latest_output_created_ts TIMESTAMP,
    archive_inserted_ts TIMESTAMP,

    /***********************************************************************************************
    Archive controls and final-resolution setting.
    ***********************************************************************************************/
    archive_run_flag BOOLEAN,
    strategy_archive_reset_mode TEXT,
    failed_counteroffer_resolution TEXT,

    /***********************************************************************************************
    Module 1 source mode and lineage.
    ***********************************************************************************************/
    module1_input_source TEXT,
    module1_source_table_name TEXT,

    module1_model_version TEXT,
    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,
    anchor_date DATE,

    /***********************************************************************************************
    Structural run counts.

    duplicate_application_count should be zero for accepted evidence.
    ***********************************************************************************************/
    applications BIGINT,
    distinct_application_id_count BIGINT,
    duplicate_application_count BIGINT,

    /***********************************************************************************************
    Final decision outcome counts.
    ***********************************************************************************************/
    approval_count BIGINT,
    counteroffer_count BIGINT,
    manual_review_count BIGINT,
    decline_count BIGINT,
    offer_count BIGINT,

    /***********************************************************************************************
    Final decision outcome rates.

    simulated_offer_exposure_rate = APPROVE + COUNTEROFFER share.
    ***********************************************************************************************/
    approval_rate NUMERIC,
    counteroffer_rate NUMERIC,
    manual_review_rate NUMERIC,
    decline_rate NUMERIC,
    simulated_offer_exposure_rate NUMERIC,
    approval_share_of_offers NUMERIC,
    counteroffer_share_of_offers NUMERIC,

    /***********************************************************************************************
    Requested and approved exposure metrics.
    ***********************************************************************************************/
    total_requested_amount NUMERIC,
    total_approved_amount NUMERIC,
    approved_amount_capture_rate NUMERIC,

    avg_requested_amount NUMERIC,
    avg_approved_amount_all_apps NUMERIC,
    avg_approved_amount_offer_rows NUMERIC,

    total_exposure_reduction_amount NUMERIC,

    /***********************************************************************************************
    Counteroffer, manual-review, and decline exposure context.
    ***********************************************************************************************/
    counteroffer_requested_amount NUMERIC,
    counteroffer_approved_amount NUMERIC,
    counteroffer_exposure_reduction_amount NUMERIC,
    counteroffer_exposure_reduction_pct_avg NUMERIC,

    manual_review_requested_amount NUMERIC,
    manual_review_requested_expected_loss_amount NUMERIC,
    decline_requested_amount NUMERIC,
    decline_requested_expected_loss_amount NUMERIC,

    /***********************************************************************************************
    Requested and approved affordability metrics.
    ***********************************************************************************************/
    avg_requested_payment_to_income_ratio NUMERIC,
    avg_approved_payment_to_income_ratio_offer_rows NUMERIC,

    /***********************************************************************************************
    Module 3 growth-readiness APR proxy metrics.

    These fields preserve inputs useful for future economics design.

    They are not revenue or profitability metrics.
    ***********************************************************************************************/
    avg_apr_proxy_all_apps NUMERIC,
    avg_apr_proxy_offer_rows NUMERIC,
    requested_amount_weighted_apr_proxy NUMERIC,
    approved_amount_weighted_apr_proxy NUMERIC,
    requested_amount_x_apr_proxy_sum NUMERIC,
    approved_amount_x_apr_proxy_sum NUMERIC,

    /***********************************************************************************************
    Module 3 growth-readiness term metrics.

    loan_term_months may be unavailable or not meaningful for some product types.
    term_missing_or_revolving_count preserves that context.
    ***********************************************************************************************/
    avg_loan_term_months_offer_rows NUMERIC,
    approved_amount_weighted_term_months NUMERIC,
    term_missing_or_revolving_count BIGINT,

    /***********************************************************************************************
    Product mix / exposure composition metrics for future economics interpretation.
    ***********************************************************************************************/
    secured_approved_amount_share NUMERIC,
    unsecured_approved_amount_share NUMERIC,
    revolving_approved_amount_share NUMERIC,
    installment_approved_amount_share NUMERIC,
    mortgage_approved_amount_share NUMERIC,

    product_approved_amount_mix_jsonb JSONB,
    product_approved_expected_loss_mix_jsonb JSONB,
    product_offer_rate_jsonb JSONB,

    /***********************************************************************************************
    Synthetic estimated-risk and LGD metrics.

    estimated_pd remains the SQL field name and is interpreted as synthetic estimated-PD proxy.
    ***********************************************************************************************/
    avg_synthetic_estimated_pd_proxy_all_apps NUMERIC,
    avg_synthetic_estimated_pd_proxy_offer_rows NUMERIC,
    avg_synthetic_estimated_pd_proxy_declined_rows NUMERIC,

    avg_estimated_lgd_all_apps NUMERIC,
    avg_estimated_lgd_offer_rows NUMERIC,

    /***********************************************************************************************
    Requested and approved Expected Loss metrics.
    ***********************************************************************************************/
    total_requested_expected_loss_amount NUMERIC,
    total_approved_expected_loss_amount NUMERIC,
    avg_requested_expected_loss_amount NUMERIC,
    avg_approved_expected_loss_all_apps NUMERIC,
    avg_approved_expected_loss_offer_rows NUMERIC,

    requested_expected_loss_rate NUMERIC,
    approved_expected_loss_rate NUMERIC,
    approved_amount_per_approved_expected_loss_dollar NUMERIC,

    /***********************************************************************************************
    Simulated reason-code story fields.
    ***********************************************************************************************/
    top_primary_reason_family TEXT,
    top_primary_reason_code TEXT,
    top_primary_reason_population_share NUMERIC,

    top_non_approval_primary_reason_family TEXT,
    top_non_approval_primary_reason_code TEXT,
    top_non_approval_reason_population_share NUMERIC,

    top_policy_stop_primary_reason_family TEXT,
    top_policy_stop_primary_reason_code TEXT,
    top_policy_stop_reason_population_share NUMERIC,

    /***********************************************************************************************
    Reason-code movement versus baseline.

    These fields are populated from Section 15 when baseline-relative frontier evidence exists.
    ***********************************************************************************************/
    top_reason_code_delta_driver_family TEXT,
    top_reason_code_delta_driver_code TEXT,
    top_reason_code_delta_driver_baseline_share NUMERIC,
    top_reason_code_delta_driver_strategy_share NUMERIC,
    top_reason_code_delta_population_share NUMERIC,

    /***********************************************************************************************
    Outcome-family reason-code highlights.
    ***********************************************************************************************/
    top_counteroffer_reason_code TEXT,
    top_manual_review_reason_code TEXT,
    top_decline_reason_code TEXT,

    /***********************************************************************************************
    Strategy frontier classification fields from Section 15.
    ***********************************************************************************************/
    frontier_position_type TEXT,
    executive_frontier_quadrant TEXT,
    frontier_interpretation_note TEXT,

    /***********************************************************************************************
    Validation summary rollup fields from Section 14.
    ***********************************************************************************************/
    validation_pass_count BIGINT,
    validation_review_count BIGINT,
    validation_not_applicable_count BIGINT,
    validation_review_items TEXT,
    validation_status_summary_jsonb JSONB,

    /***********************************************************************************************
    Product-level driver fields.
    ***********************************************************************************************/
    top_approved_amount_product TEXT,
    top_approved_amount_product_share NUMERIC,
    top_approved_expected_loss_product TEXT,
    top_approved_expected_loss_product_share NUMERIC,
    top_counteroffer_product TEXT,
    top_decline_product TEXT,
    highest_offer_rate_product TEXT,
    lowest_offer_rate_product TEXT,

    /***********************************************************************************************
    Score-band driver fields.
    ***********************************************************************************************/
    top_approved_amount_score_band TEXT,
    top_approved_expected_loss_score_band TEXT,
    top_counteroffer_score_band TEXT,
    top_decline_score_band TEXT,
    highest_offer_rate_score_band TEXT,
    lowest_offer_rate_score_band TEXT,
    highest_approved_el_rate_score_band TEXT,

    /***********************************************************************************************
    Product × score segment driver fields.
    ***********************************************************************************************/
    top_approved_amount_product_score_segment TEXT,
    top_approved_el_product_score_segment TEXT,
    top_counteroffer_product_score_segment TEXT,
    top_decline_product_score_segment TEXT,
    highest_approved_el_rate_product_score_segment TEXT,

    /***********************************************************************************************
    Baseline-relative segment movement fields.
    ***********************************************************************************************/
    largest_delta_approved_amount_product TEXT,
    largest_delta_approved_el_product TEXT,
    largest_delta_offer_rate_score_band TEXT,
    largest_delta_decline_rate_score_band TEXT,
    largest_delta_approved_el_product_score_segment TEXT,

    /***********************************************************************************************
    Module 3 readiness fields.

    These fields explicitly signal readiness for future economics modeling while preserving the
    boundary that Module 2 does not calculate profitability.
    ***********************************************************************************************/
    module3_growth_inputs_available_flag BOOLEAN,
    module3_growth_input_gap_note TEXT,
    module3_revenue_model_required_flag BOOLEAN,
    module3_boundary_note TEXT
);



/*-----------------------------------------------------------------------------------------------
16.1B Create validation evidence detail table.

Business purpose:
    Persist each Section 14 validation summary row for the current run.

Why this matters:
    The Validation Summary should be traceable to individual SQL evidence rows, not only to a single
    aggregate PASS / REVIEW count.

Patch behavior:
    Registry fields are stored with each validation row so later validation artifacts can reference
    module2_run_id, validation_evidence_group_id, comparison_group_id, and showcase_id directly.
-----------------------------------------------------------------------------------------------*/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_validation_evidence (
    evidence_snapshot_ts TIMESTAMP,

    campaign_registry_required_flag BOOLEAN,
    registry_match_count BIGINT,
    run_registry_match_status TEXT,

    module1_run_id TEXT,
    module2_run_id TEXT,
    run_sequence_number INTEGER,

    showcase_id TEXT,
    showcase_name TEXT,
    comparison_group_id TEXT,
    validation_evidence_group_id TEXT,

    readme_storyline_label TEXT,
    linkedin_post_sequence INTEGER,
    validation_summary_section_hint TEXT,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,

    validation_area TEXT,
    validation_test_name TEXT,
    validation_category TEXT,
    validation_status TEXT,
    observed_value TEXT,
    expected_behavior TEXT,
    interpretation TEXT
);



/*-----------------------------------------------------------------------------------------------
16.1C Create parameter snapshot table.

Business purpose:
    Persist the exact active parameter configuration that produced the current strategy evidence.

Why JSONB:
    Strategy and product-policy parameter tables are temporary and can change across runs.

    JSONB preserves the full parameter payload without requiring one evidence column per parameter.

parameter_snapshot_hash:
    Provides a compact fingerprint of the strategy, product-policy, and story payload.

Patch behavior:
    Registry fields are stored with the parameter snapshot so the exact parameter payload can be tied
    to module2_run_id, showcase_id, comparison_group_id, and validation_evidence_group_id.
-----------------------------------------------------------------------------------------------*/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_parameter_snapshot (
    evidence_snapshot_ts TIMESTAMP,
    evidence_snapshot_id TEXT,

    campaign_registry_required_flag BOOLEAN,
    registry_match_count BIGINT,
    run_registry_match_status TEXT,

    module1_run_id TEXT,
    module2_run_id TEXT,
    run_sequence_number INTEGER,

    showcase_id TEXT,
    showcase_name TEXT,
    comparison_group_id TEXT,
    validation_evidence_group_id TEXT,

    readme_storyline_label TEXT,
    linkedin_post_sequence INTEGER,
    validation_summary_section_hint TEXT,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,

    strategy_params_jsonb JSONB,
    product_policy_params_jsonb JSONB,
    run_story_params_jsonb JSONB,
    parameter_snapshot_hash TEXT
);



/*-----------------------------------------------------------------------------------------------
16.1D Create product × score segment evidence table.

Business purpose:
    Persist segment-level evidence so the executive story can identify which product × score
    intersections drove access, approved exposure, approved Expected Loss, counteroffer behavior, and
    no-offer behavior.

GRAIN:
    one row per current run key
    × product_type_policy_key
    × score_band_policy_key

Patch behavior:
    Registry fields are included so segment-level evidence can be tied directly to campaign run IDs,
    showcase IDs, comparison IDs, and validation evidence groups.

Boundary:
    This is segment evidence, not a new scoring model and not production segmentation.
-----------------------------------------------------------------------------------------------*/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.strategy_run_segment_evidence_summary (
    evidence_snapshot_ts TIMESTAMP,

    campaign_registry_required_flag BOOLEAN,
    registry_match_count BIGINT,
    run_registry_match_status TEXT,

    module1_run_id TEXT,
    module2_run_id TEXT,
    run_sequence_number INTEGER,

    showcase_id TEXT,
    showcase_name TEXT,
    comparison_group_id TEXT,
    validation_evidence_group_id TEXT,

    readme_storyline_label TEXT,
    linkedin_post_sequence INTEGER,
    validation_summary_section_hint TEXT,

    module2_model_version TEXT,
    strategy_set_name TEXT,
    strategy_name TEXT,
    strategy_version TEXT,
    strategy_run_id TEXT,
    strategy_run_ts TIMESTAMP,

    module1_scenario_set_name TEXT,
    module1_scenario_name TEXT,
    population_id TEXT,

    product_type_policy_key TEXT,
    score_band_policy_key TEXT,
    product_score_policy_segment TEXT,

    applications BIGINT,

    approval_count BIGINT,
    counteroffer_count BIGINT,
    manual_review_count BIGINT,
    decline_count BIGINT,
    offer_count BIGINT,

    approval_rate NUMERIC,
    counteroffer_rate NUMERIC,
    manual_review_rate NUMERIC,
    decline_rate NUMERIC,
    simulated_offer_exposure_rate NUMERIC,

    total_requested_amount NUMERIC,
    total_approved_amount NUMERIC,
    approved_amount_capture_rate NUMERIC,

    avg_requested_amount NUMERIC,
    avg_approved_amount_all_apps NUMERIC,
    avg_approved_amount_offer_rows NUMERIC,

    avg_apr_proxy_all_apps NUMERIC,
    avg_apr_proxy_offer_rows NUMERIC,
    requested_amount_weighted_apr_proxy NUMERIC,
    approved_amount_weighted_apr_proxy NUMERIC,

    avg_loan_term_months_offer_rows NUMERIC,
    approved_amount_weighted_term_months NUMERIC,

    avg_synthetic_estimated_pd_proxy_all_apps NUMERIC,
    avg_synthetic_estimated_pd_proxy_offer_rows NUMERIC,
    avg_estimated_lgd_offer_rows NUMERIC,

    total_requested_expected_loss_amount NUMERIC,
    total_approved_expected_loss_amount NUMERIC,
    approved_expected_loss_rate NUMERIC,

    avg_requested_payment_to_income_ratio NUMERIC,
    avg_approved_payment_to_income_ratio_offer_rows NUMERIC,

    top_primary_reason_family TEXT,
    top_primary_reason_code TEXT,
    top_primary_reason_population_share NUMERIC,

    top_non_approval_primary_reason_family TEXT,
    top_non_approval_primary_reason_code TEXT,
    top_non_approval_reason_population_share NUMERIC
);



/*-----------------------------------------------------------------------------------------------
16.1E Evidence table schema hardening for registry-linkage patch.

Business purpose:
    Add registry-linkage columns to evidence tables that may already exist from a prior version of
    Section 16.

Why this is necessary:
    CREATE TABLE IF NOT EXISTS does not modify an existing table.

    Without these ALTER TABLE statements, an older evidence table could exist without the new
    run-ID columns, causing later INSERT statements to fail.

Boundary:
    These statements add columns only when needed.

    They do not delete rows.
    They do not update rows.
    They do not alter strategy outputs.
-----------------------------------------------------------------------------------------------*/

ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS showcase_name TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_validation_evidence
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS showcase_name TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_parameter_snapshot
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;


ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS campaign_registry_required_flag BOOLEAN;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS registry_match_count BIGINT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS run_registry_match_status TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS module1_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS module2_run_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS run_sequence_number INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS showcase_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS showcase_name TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS comparison_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_evidence_group_id TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS readme_storyline_label TEXT;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS linkedin_post_sequence INTEGER;
ALTER TABLE credit_decisioning_sim.strategy_run_segment_evidence_summary
    ADD COLUMN IF NOT EXISTS validation_summary_section_hint TEXT;



/*-----------------------------------------------------------------------------------------------
16.1F Create persistent evidence indexes.

Business purpose:
    Enforce one current evidence row per run key where appropriate and support fast lookup by run key.

Index interpretation:
    strategy_run_evidence_summary:
        unique at the primary evidence run grain.

    strategy_run_validation_evidence:
        non-unique because each run has multiple validation tests.

    strategy_run_parameter_snapshot:
        unique at the primary evidence run grain.

    strategy_run_segment_evidence_summary:
        unique at run key × product × score segment.

Boundary:
    Indexes support evidence-table integrity and performance.
    They do not change strategy outputs.
-----------------------------------------------------------------------------------------------*/

CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_evidence_summary_key
ON credit_decisioning_sim.strategy_run_evidence_summary (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);


CREATE INDEX IF NOT EXISTS idx_m2_strategy_run_validation_evidence_key
ON credit_decisioning_sim.strategy_run_validation_evidence (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_parameter_snapshot_key
ON credit_decisioning_sim.strategy_run_parameter_snapshot (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id
);


CREATE UNIQUE INDEX IF NOT EXISTS idx_m2_strategy_run_segment_evidence_key
ON credit_decisioning_sim.strategy_run_segment_evidence_summary (
    strategy_set_name,
    strategy_name,
    strategy_version,
    module1_scenario_set_name,
    module1_scenario_name,
    population_id,
    product_type_policy_key,
    score_band_policy_key
);



/***************************************************************************************************
SECTION 16.2 — REPLACE CURRENT RUN EVIDENCE ROWS
****************************************************************************************************

BUSINESS PURPOSE:
    Maintain one current evidence record per strategy / Module 1 scenario / population key.

    Section 16.2 answers:

        "Before inserting evidence for the current run, should prior evidence for this same run key
         be cleared so the evidence layer reflects the current accepted run?"

SQL PURPOSE:
    Delete prior evidence rows for the current run key from:
        credit_decisioning_sim.strategy_run_evidence_summary
        credit_decisioning_sim.strategy_run_validation_evidence
        credit_decisioning_sim.strategy_run_parameter_snapshot
        credit_decisioning_sim.strategy_run_segment_evidence_summary

WHY DELETE / INSERT IS USED:
    Strategy slices may be rerun under STRATEGY_SCENARIO_ONLY archive reset behavior.

    Evidence rows should reflect the current accepted version of that strategy slice, not accumulate
    duplicates or stale records for the same practical evidence grain.

DELETE SCOPE:
    Deletes are restricted to the current run key:

        strategy_set_name
        strategy_name
        strategy_version
        module1_scenario_set_name
        module1_scenario_name
        population_id

BOUNDARY:
    Section 16.2 deletes only evidence rows.

    It does not delete latest-run rows.
    It does not delete archive rows.
    It does not delete campaign registry rows.
    It does not delete strategy parameter rows.
    It does not delete product policy parameter rows.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.2A Replace one-row executive evidence for current run key.

Business purpose:
    Remove any prior executive evidence row for the same strategy / scenario / population slice.

SQL logic:
    USING tmp_m2_current_run_key limits the delete to the current completed latest-run key.
-----------------------------------------------------------------------------------------------*/

DELETE FROM credit_decisioning_sim.strategy_run_evidence_summary e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;



/*-----------------------------------------------------------------------------------------------
16.2B Replace validation evidence detail for current run key.

Business purpose:
    Remove prior validation evidence rows so the current Section 14 validation status summary can be
    captured cleanly.

SQL logic:
    This table is one-to-many by validation test, so multiple rows may be deleted for the current run.
-----------------------------------------------------------------------------------------------*/

DELETE FROM credit_decisioning_sim.strategy_run_validation_evidence e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;



/*-----------------------------------------------------------------------------------------------
16.2C Replace parameter snapshot for current run key.

Business purpose:
    Remove prior parameter snapshot so the evidence layer stores the current active strategy /
    product-policy configuration for the rerun.

SQL logic:
    This table should contain one parameter snapshot per run key.
-----------------------------------------------------------------------------------------------*/

DELETE FROM credit_decisioning_sim.strategy_run_parameter_snapshot e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;



/*-----------------------------------------------------------------------------------------------
16.2D Replace product × score segment evidence for current run key.

Business purpose:
    Remove prior segment evidence so the next Section 16 segment insert captures the current accepted
    product × score result profile.

SQL logic:
    This table is one-to-many by product × score segment, so multiple rows may be deleted.
-----------------------------------------------------------------------------------------------*/

DELETE FROM credit_decisioning_sim.strategy_run_segment_evidence_summary e
USING tmp_m2_current_run_key k
WHERE e.strategy_set_name = k.strategy_set_name
  AND e.strategy_name = k.strategy_name
  AND e.strategy_version = k.strategy_version
  AND e.module1_scenario_set_name = k.module1_scenario_set_name
  AND e.module1_scenario_name = k.module1_scenario_name
  AND e.population_id = k.population_id;



/***************************************************************************************************
SECTION 16.3 — CAPTURE CURRENT RUN VALIDATION EVIDENCE DETAIL
****************************************************************************************************

BUSINESS PURPOSE:
    Persist the Section 14 validation status summary for the current run.

    Section 16.3 answers:

        "Which validation checks passed, which require review, and which were not applicable for this
         completed strategy run?"

SQL PURPOSE:
    Insert one row per Section 14 validation status summary row into:

        credit_decisioning_sim.strategy_run_validation_evidence

SOURCE:
    tmp_m2_validation_status_summary

TARGET:
    credit_decisioning_sim.strategy_run_validation_evidence

EVIDENCE GRAIN:
    One row per:
        current run key
        × validation_area
        × validation_test_name

REGISTRY PATCH:
    Each validation evidence row now carries the campaign registry IDs from:

        tmp_m2_current_run_story_params

    This allows validation evidence to be referenced directly by:
        module1_run_id
        module2_run_id
        showcase_id
        comparison_group_id
        validation_evidence_group_id
        readme_storyline_label
        linkedin_post_sequence
        validation_summary_section_hint

VALIDATION STATUS INTERPRETATION:
    PASS:
        The diagnostic expectation was satisfied.

    REVIEW:
        The pattern should be interpreted before documentation.
        REVIEW is not automatically a fail-fast defect.

    NOT_APPLICABLE:
        The test depends on comparison conditions or population conditions not available for the
        current run context.

WHY CROSS JOIN IS USED:
    tmp_m2_current_run_key contains exactly one row after the Section 16.0 gatekeeper.

    tmp_m2_current_run_story_params contains exactly one active row after the Section 16.0 gatekeeper.

    CROSS JOIN attaches the current run identity and registry story identity to every validation
    status row.

BOUNDARY:
    Section 16.3 persists validation evidence only.

    It does not recalculate validation.
    It does not modify the latest-run output.
    It does not modify archive rows.
    It does not modify validation statuses.

***************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
16.3A Insert Section 14 validation status rows for the current run.

Business purpose:
    Preserve the Section 14 validation evidence spine in a persistent table.

SQL logic:
    The single current run key and single story metadata row are cross joined to all validation summary
    rows.

    observed_value, expected_behavior, and interpretation are cast to TEXT so evidence storage is
    stable even if upstream temporary output types vary.
-----------------------------------------------------------------------------------------------*/

INSERT INTO credit_decisioning_sim.strategy_run_validation_evidence (
    evidence_snapshot_ts,

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

    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation
)
SELECT
    CURRENT_TIMESTAMP AS evidence_snapshot_ts,

    /***********************************************************************************************
    Campaign registry / run story fields.
    ***********************************************************************************************/
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

    /***********************************************************************************************
    Current run identity.
    ***********************************************************************************************/
    k.module2_model_version,
    k.strategy_set_name,
    k.strategy_name,
    k.strategy_version,
    k.strategy_run_id,
    k.strategy_run_ts,

    /***********************************************************************************************
    Module 1 scenario / population lineage.
    ***********************************************************************************************/
    k.module1_scenario_set_name,
    k.module1_scenario_name,
    k.population_id,

    /***********************************************************************************************
    Section 14 validation evidence fields.
    ***********************************************************************************************/
    v.validation_area,
    v.validation_test_name,
    v.validation_category,
    v.validation_status,
    v.observed_value::TEXT,
    v.expected_behavior::TEXT,
    v.interpretation::TEXT

FROM tmp_m2_current_run_key k
CROSS JOIN tmp_m2_current_run_story_params s
CROSS JOIN tmp_m2_validation_status_summary v

WHERE s.active_story_flag IS TRUE;



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

REGISTRY PATCH:
    The parameter snapshot now stores registry linkage fields explicitly and also stores the full
    run_story_params_jsonb payload.

    This makes each parameter snapshot traceable to:
        module1_run_id
        module2_run_id
        showcase_id
        comparison_group_id
        validation_evidence_group_id
        readme_storyline_label
        linkedin_post_sequence
        validation_summary_section_hint
        run_registry_match_status

WHY THIS MATTERS:
    The active parameter tables are temporary.

    Without a parameter snapshot, later documentation may know what happened but not exactly which
    thresholds, policy caps, archive controls, counteroffer settings, registry IDs, and story labels
    were active.

WHY JSONB IS USED:
    JSONB preserves the full parameter card without forcing every parameter into a separate evidence
    table column.

    This makes the snapshot robust for review and future documentation while preserving detail.

WHY PRODUCT POLICY SNAPSHOT IS ORDERED:
    jsonb_agg(... ORDER BY product_type) makes the product-policy snapshot deterministic and easier
    to compare across runs.

PARAMETER SNAPSHOT HASH:
    parameter_snapshot_hash is a fingerprint of:
        active strategy parameters,
        product policy parameters,
        and run-story parameters.

    It helps identify whether two evidence rows were created from the same parameter payload.

    It is not a cryptographic governance control.
    It is not a replacement for the full JSONB payload.

EVIDENCE SNAPSHOT ID:
    evidence_snapshot_id includes the current timestamp so each capture event receives a unique
    identifier.

    It is audit metadata.

    It is not the run-key grain and should not replace the strategy / scenario / population key.

MODULE 3 READINESS:
    This snapshot preserves product policy values that may later support:
        growth analysis,
        economics design,
        pricing proxy interpretation,
        exposure strategy,
        product mix review,
        and profitability design in a future Module 3.

    It does not calculate Module 3 economics.

BOUNDARY:
    Section 16.4 persists parameter evidence only.

    It does not modify active parameters.
    It does not modify latest-run output.
    It does not modify archive output.
    It does not recalculate decisions.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.

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

        tmp_m2_current_run_key must contain exactly one row due to the Section 16.0 gatekeeper.
        *******************************************************************************************/
        k.*,

        /*******************************************************************************************
        Current run registry / story metadata.

        tmp_m2_current_run_story_params must contain exactly one active row due to the Section 16.0
        gatekeeper.
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

        Captures the full active strategy card, including strategy identity, source selection,
        archive controls, thresholds, rule controls, decision conventions, and registry requirement.
        *******************************************************************************************/
        (
            SELECT to_jsonb(sp)
            FROM tmp_module2_strategy_params sp
            WHERE sp.active_strategy_flag IS TRUE
            LIMIT 1
        ) AS strategy_params_jsonb,

        /*******************************************************************************************
        Product policy parameter snapshot.

        Captures all product-policy rows in stable product_type order.
        *******************************************************************************************/
        (
            SELECT jsonb_agg(to_jsonb(pp) ORDER BY pp.product_type)
            FROM tmp_module2_product_policy_params pp
        ) AS product_policy_params_jsonb,

        /*******************************************************************************************
        Run-story metadata snapshot.

        Captures the active story helper row used for current evidence capture, including registry
        IDs and fallback-status fields.
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

    Includes the current timestamp to distinguish separate evidence-capture events for the same run
    key.

    This is audit metadata, not the evidence grain.
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
    ***********************************************************************************************/
    strategy_params_jsonb,
    product_policy_params_jsonb,
    run_story_params_jsonb,

    /***********************************************************************************************
    Parameter payload fingerprint.

    This fingerprint supports quick comparison of parameter snapshots across runs.

    The full JSONB payload remains the authoritative evidence.
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
    Section 16.5+ should carry the same registry fields into product × score segment evidence and
    one-row executive evidence summary inserts.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00852 -->


---

<a id="c038-m00854"></a>

### C038-M00854

**Andrew** · 2026-05-09T20:09:16.107000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00854 -->
let's patch section 16.5 and 16.6.  please give me the updated full copy paste with the patch installed:
<!-- END_MESSAGE C038-M00854 -->


**Attachments in export:** `Pasted text(136).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_35.md) · [Next](Part_37.md)
