# Module 2 Decision Simulator Build

## Part 09

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_08.md) · [Next](Part_10.md)

<a id="c038-m00182"></a>

### C038-M00182

**ChatGPT** · 2026-05-06T17:11:20.882882-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00182 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 2 OF 7 START

/***************************************************************************************************
SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION
****************************************************************************************************

BUSINESS PURPOSE:
    Safely consume finalized Module 1 outputs and create the clean Module 2 input foundation.

    Module 2 can consume either:
        1. the Module 1 latest-run table; or
        2. a selected Module 1 scenario archive slice.

    This section is the Module 1 → Module 2 handoff layer.

SQL PURPOSE:
    1. Read the active Module 2 strategy source-selection settings.
    2. Select the correct Module 1 input source:
            credit_decisioning_sim.synthetic_applications
        or:
            credit_decisioning_sim.synthetic_applications_scenario_archive
    3. Normalize upstream Module 1 scenario lineage into Module 2 naming:
            module1_scenario_set_name
            module1_scenario_name
            population_id
    4. Preserve application-level identifiers.
    5. Preserve borrower, product, affordability, requested-structure, and risk-economics fields.
    6. Preserve Module 2 strategy metadata in the staged input.
    7. Alias requested-exposure economics clearly for Module 2:
            requested_monthly_payment_proxy
            requested_payment_to_income_ratio
            requested_expected_loss_amount
    8. Create product_type_policy_key for later product-policy joins.
    9. Validate that every source row maps to exactly one product policy configuration.

WHY MODULE 2 CONSUMES MODULE 1 RATHER THAN REWRITING MODULE 1:
    Module 1 is finalized, validated, and authoritative.

    Module 2 consumes Module 1 outputs as the synthetic applicant and risk foundation.
    Module 2 does not redesign the synthetic population.
    Module 2 does not recalculate estimated_pd.
    Module 2 does not reinterpret Module 1 scenario outputs as forecasts.

WHY LATEST-RUN AND ARCHIVE INPUTS ARE BOTH SUPPORTED:
    LATEST input supports single-strategy development and immediate QA.

    ARCHIVE input supports strategy comparison across completed Module 1 scenario slices while
    preserving upstream Module 1 lineage.

WHY MODULE 1 SCENARIO LINEAGE MUST BE PRESERVED:
    Module 1 scenario fields describe the upstream synthetic population and risk environment.
    Module 2 strategy fields describe the downstream simulated strategy applied to that population.

    These concepts must not be overloaded.

WHY PRODUCT_TYPE MAY NEED A POLICY KEY:
    Module 1 may output product_type in a normalized code format or a display-style format.

    Module 2 policy parameters use normalized product keys:
        MORTGAGE
        HELOC
        AUTO_LOAN
        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

    Section 4 preserves the original product_type and derives product_type_policy_key for later
    strategy joins. Module 1 is not modified.

WHY PRODUCT POLICY VALIDATION HAPPENS BEFORE POLICY RULES:
    Downstream strategy rules are product-aware.

    A missing product policy configuration would make decision logic ambiguous, so Section 4 fails
    before rule flags or decisions are created.

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
        reason codes
        approved_amount
        approved payment
        approved PTI
        approved Expected Loss

WHY PRODUCT-POLICY JOIN IN SECTION 4 IS VALIDATION-ONLY:
    Section 4 confirms product policy configuration availability.

    It does not apply product caps, counteroffer limits, PTI rules, Expected Loss rules, or any
    final strategy treatment.

***************************************************************************************************/



/***************************************************************************************************
SECTION 4.1 — CLEAN RESET OF SECTION 4 STAGING OBJECT
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

***************************************************************************************************/

DO $$
DECLARE
    p RECORD;

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
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;

    IF p.module1_input_source = 'LATEST' THEN
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications';
    ELSIF p.module1_input_source = 'ARCHIVE' THEN
        v_source_table_schema := 'credit_decisioning_sim';
        v_source_table_name := 'synthetic_applications_scenario_archive';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: module1_input_source must be LATEST or ARCHIVE. Found: %.',
            COALESCE(p.module1_input_source, '<NULL>');
    END IF;


    /*-------------------------------------------------------------------------------------------
    Identify Module 1 scenario columns.

    Module 1 latest-run outputs may use scenario_set_name / scenario_name.
    Archive or downstream-normalized outputs may use module1_scenario_set_name / module1_scenario_name.

    Section 4 normalizes both forms into:
        module1_scenario_set_name
        module1_scenario_name
    -------------------------------------------------------------------------------------------*/
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'module1_scenario_set_name'
    ) THEN
        v_scenario_set_col := 'module1_scenario_set_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'scenario_set_name'
    ) THEN
        v_scenario_set_col := 'scenario_set_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain scenario_set_name or module1_scenario_set_name.',
            v_source_table_schema,
            v_source_table_name;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'module1_scenario_name'
    ) THEN
        v_scenario_name_col := 'module1_scenario_name';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'scenario_name'
    ) THEN
        v_scenario_name_col := 'scenario_name';
    ELSE
        RAISE EXCEPTION
            'Module 2 Section 4 failure: selected Module 1 source %.% must contain scenario_name or module1_scenario_name.',
            v_source_table_schema,
            v_source_table_name;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Optional / normalized source expressions.

    If a field is required for Module 2 V1.0 but absent from Module 1, the source expression is set
    to NULL and the local Section 4 gatekeeper fails clearly.

    This avoids silently inventing missing Module 1 data.
    -------------------------------------------------------------------------------------------*/
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
        v_module1_model_version_expr := 'NULL::TEXT';
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
        v_anchor_date_expr := 'NULL::DATE';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'application_seq'
    ) THEN
        v_application_seq_expr := 'src.application_seq::BIGINT';
    ELSE
        v_application_seq_expr := 'NULL::BIGINT';
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
        v_application_date_expr := 'NULL::DATE';
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
        v_base_apr_expr := 'NULL::NUMERIC';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = v_source_table_schema
          AND table_name = v_source_table_name
          AND column_name = 'prequalified_flag'
    ) THEN
        v_prequalified_flag_expr := 'src.prequalified_flag::BOOLEAN';
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
        v_returning_customer_flag_expr := 'src.returning_customer_flag::BOOLEAN';
    ELSE
        v_returning_customer_flag_expr := 'NULL::BOOLEAN';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dynamic source-staging query.

    Dynamic SQL is used only to safely handle:
        selected source table,
        scenario lineage column names,
        optional source-field expressions.

    The output schema is fixed and governed.
    -------------------------------------------------------------------------------------------*/
    v_create_sql := FORMAT($sql$
        CREATE TEMP TABLE tmp_m2_stage_1_source_applications
        ON COMMIT PRESERVE ROWS
        AS
        WITH active_strategy_params AS (
            SELECT *
            FROM tmp_module2_strategy_params
            WHERE active_strategy_flag IS TRUE
            LIMIT 1
        ),

        source_rows AS (
            SELECT
                /***********************************************************************************
                Module 2 strategy metadata.

                These fields are carried from the beginning so every downstream stage preserves both
                upstream Module 1 lineage and downstream Module 2 strategy lineage.

                strategy_run_id and strategy_run_ts are audit metadata. They do not replace the
                archive replacement / rerun key.
                ***********************************************************************************/
                p.module2_model_version,
                p.strategy_set_name,
                p.strategy_name,
                p.strategy_version,
                p.strategy_run_id,
                p.strategy_run_ts,

                /***********************************************************************************
                Module 1 lineage.

                Module 1 scenario metadata describes the synthetic population and upstream risk
                environment.
                ***********************************************************************************/
                %s AS module1_model_version,
                %s AS module1_scenario_set_name,
                %s AS module1_scenario_name,
                src.population_id::TEXT AS population_id,
                %s AS anchor_date,
                p.module1_input_source,
                %L::TEXT AS module1_source_table_name,

                /***********************************************************************************
                Application lineage.
                ***********************************************************************************/
                %s AS application_seq,
                src.application_id::TEXT AS application_id,
                src.applicant_id::TEXT AS applicant_id,
                %s AS application_date,

                /***********************************************************************************
                Product / score fields.

                product_type preserves the original Module 1 value.
                product_type_policy_key is the normalized Module 2 product policy join key.
                ***********************************************************************************/
                src.product_type::TEXT AS product_type,

                CASE
                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('MORTGAGE', 'MORTGAGE_LOAN')
                        THEN 'MORTGAGE'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('HELOC', 'HOME_EQUITY_LINE', 'HOME_EQUITY_LINE_OF_CREDIT')
                        THEN 'HELOC'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN ('AUTO', 'AUTO_LOAN', 'AUTO_FINANCE')
                        THEN 'AUTO_LOAN'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN (
                            'UNSECURED_PERSONAL_LOAN',
                            'PERSONAL_LOAN',
                            'UNSECURED_LOAN',
                            'UNSECURED_INSTALLMENT_LOAN'
                         )
                        THEN 'UNSECURED_PERSONAL_LOAN'

                    WHEN UPPER(REGEXP_REPLACE(BTRIM(src.product_type::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                         IN (
                            'REVOLVING_LINE',
                            'REVOLVING',
                            'CREDIT_CARD',
                            'CREDIT_CARD_LINE',
                            'REVOLVING_CREDIT_LINE'
                         )
                        THEN 'REVOLVING_LINE'

                    ELSE NULL
                END AS product_type_policy_key,

                src.score_band::TEXT AS score_band,
                src.credit_score::INTEGER AS credit_score,

                /***********************************************************************************
                Borrower / behavioral fields.
                ***********************************************************************************/
                src.annual_income::NUMERIC AS annual_income,
                src.debt_to_income_ratio::NUMERIC AS debt_to_income_ratio,
                src.utilization_rate::NUMERIC AS utilization_rate,
                src.tradeline_count::INTEGER AS tradeline_count,
                src.months_since_oldest_trade::INTEGER AS months_since_oldest_trade,
                src.recent_inquiry_count::INTEGER AS recent_inquiry_count,
                src.delinquency_count_12m::INTEGER AS delinquency_count_12m,
                src.major_derogatory_flag::BOOLEAN AS major_derogatory_flag,
                src.bankruptcy_flag::BOOLEAN AS bankruptcy_flag,

                /***********************************************************************************
                Optional relationship / context fields.

                These remain nullable if Module 1 did not surface them.
                ***********************************************************************************/
                %s AS prequalified_flag,
                %s AS returning_customer_flag,

                /***********************************************************************************
                Requested structure from Module 1.
                ***********************************************************************************/
                src.requested_amount::NUMERIC AS requested_amount,
                %s AS loan_term_months,
                %s AS base_apr_for_payment_calc,
                src.monthly_payment_proxy::NUMERIC AS monthly_payment_proxy,
                src.payment_to_income_ratio::NUMERIC AS payment_to_income_ratio,
                src.amount_to_income_ratio::NUMERIC AS amount_to_income_ratio,

                /***********************************************************************************
                Module 2 requested-structure aliases.

                These clarify that the values are based on the original requested structure.
                ***********************************************************************************/
                src.monthly_payment_proxy::NUMERIC AS requested_monthly_payment_proxy,
                src.payment_to_income_ratio::NUMERIC AS requested_payment_to_income_ratio,
                src.expected_loss_amount::NUMERIC AS requested_expected_loss_amount,

                /***********************************************************************************
                Module 1 risk economics.

                estimated_pd remains the finalized Module 1 SQL field and is interpreted as the
                synthetic estimated-PD proxy.

                expected_loss_amount remains available as the original Module 1 requested-exposure
                Expected Loss.
                ***********************************************************************************/
                src.estimated_pd::NUMERIC AS estimated_pd,
                src.estimated_lgd::NUMERIC AS estimated_lgd,
                src.expected_loss_amount::NUMERIC AS expected_loss_amount

            FROM %I.%I src
            CROSS JOIN active_strategy_params p
            WHERE p.module1_input_source = 'LATEST'
               OR (
                    p.module1_input_source = 'ARCHIVE'
                AND %s = p.source_module1_scenario_set_name
                AND %s = p.source_module1_scenario_name
                AND src.population_id::TEXT = p.source_population_id
               )
        ),

        product_policy_match AS (
            SELECT
                product_type,
                COUNT(*) AS product_policy_match_count
            FROM tmp_module2_product_policy_params
            GROUP BY product_type
        )

        SELECT
            sr.*,

            COALESCE(pp.product_policy_match_count, 0) AS product_policy_match_count,

            (
                COALESCE(pp.product_policy_match_count, 0) = 1
            ) AS product_policy_config_found_flag

        FROM source_rows sr
        LEFT JOIN product_policy_match pp
            ON pp.product_type = sr.product_type_policy_key;
    $sql$,
        v_module1_model_version_expr,
        FORMAT('src.%I::TEXT', v_scenario_set_col),
        FORMAT('src.%I::TEXT', v_scenario_name_col),
        v_anchor_date_expr,
        v_source_table_schema || '.' || v_source_table_name,

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

    EXECUTE v_create_sql;
END $$;



/***************************************************************************************************
SECTION 4.3 — LOCAL FAIL-FAST CHECKS FOR SOURCE STAGING
****************************************************************************************************

PURPOSE:
    Protect the decision engine from consuming ambiguous or malformed source input.

These checks are local Section 4 gatekeepers only.

They are not:
    final strategy QA,
    reason-code validation,
    approved-exposure validation,
    archive validation,
    or matched strategy comparison.

***************************************************************************************************/

DO $$
DECLARE
    v_stage_row_count BIGINT;
    v_distinct_application_count BIGINT;
    v_duplicate_application_group_count BIGINT;

    v_scenario_population_count BIGINT;
    v_null_required_field_count BIGINT;
    v_unmapped_product_type_count BIGINT;
    v_missing_product_policy_count BIGINT;
    v_multiple_product_policy_count BIGINT;

    v_strategy_metadata_null_count BIGINT;
    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: staged source table must contain rows.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage_row_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_stage_row_count = 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id must remain unique.

    Module 2 V1.0 expects one staged row per synthetic application for the selected Module 1 source
    slice.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one Module 1 scenario / population slice.

    Multi-scenario processing is intentionally not built in Module 2 V1.0.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Module 2 strategy metadata must be present.

    These fields support traceability through every downstream stage.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required source fields must be populated.

    Optional relationship fields are intentionally excluded:
        prequalified_flag
        returning_customer_flag
    -------------------------------------------------------------------------------------------*/
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
       OR loan_term_months IS NULL
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


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: every product_type must normalize into a supported product_type_policy_key.
    -------------------------------------------------------------------------------------------*/
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
            'Module 2 Section 4 failure: % staged row(s) have product_type values that cannot be normalized to supported Module 2 product policy keys.',
            v_unmapped_product_type_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: every staged product key must map to exactly one product policy row.

    Section 4 does not apply product policy rules. It only validates that product policy
    configuration is available.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_missing_product_policy_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_policy_match_count = 0
       OR product_policy_config_found_flag IS DISTINCT FROM TRUE;

    IF v_missing_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) do not map to a product policy configuration.',
            v_missing_product_policy_count;
    END IF;

    SELECT COUNT(*)
    INTO v_multiple_product_policy_count
    FROM tmp_m2_stage_1_source_applications
    WHERE product_policy_match_count > 1;

    IF v_multiple_product_policy_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: % staged row(s) map to more than one product policy configuration.',
            v_multiple_product_policy_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 4 must not create decision, reason-code, or approved-exposure fields.
    -------------------------------------------------------------------------------------------*/
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

PURPOSE:
    Provide lightweight staging diagnostics for source selection and lineage normalization.

These are Section 4 sanity checks only.

They are not:
    full Module 2 QA,
    final decision validation,
    archive validation,
    or matched strategy comparison.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
4.4.1 Row count and distinct application_id count.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS staged_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_1_source_applications;


/*-----------------------------------------------------------------------------------------------
4.4.2 Module 1 scenario / population lineage.

Expected:
    exactly one row in this output for Module 2 V1.0 single-slice processing.
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
4.4.3 Module 2 strategy metadata carried into source stage.

Expected:
    exactly one strategy identity for the staged run.
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
4.4.4 Source input type and source table.
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

product_type:
    original Module 1 value.

product_type_policy_key:
    normalized Module 2 policy join key.
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
4.4.7 Missing or non-unique product policy configuration count.

Expected:
    zero.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS product_policy_configuration_issue_rows
FROM tmp_m2_stage_1_source_applications
WHERE product_policy_match_count <> 1
   OR product_policy_config_found_flag IS DISTINCT FROM TRUE;


/*-----------------------------------------------------------------------------------------------
4.4.8 Required source-field null count.

Expected:
    zero.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS null_required_source_field_rows
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
   OR loan_term_months IS NULL
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
4.4.9 Alias confirmation: expected_loss_amount → requested_expected_loss_amount.

Expected:
    zero mismatches.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS requested_expected_loss_alias_mismatch_rows
FROM tmp_m2_stage_1_source_applications
WHERE requested_expected_loss_amount IS DISTINCT FROM expected_loss_amount;


/*-----------------------------------------------------------------------------------------------
4.4.10 Alias confirmation: monthly_payment_proxy → requested_monthly_payment_proxy.

Expected:
    zero mismatches.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS requested_monthly_payment_alias_mismatch_rows
FROM tmp_m2_stage_1_source_applications
WHERE requested_monthly_payment_proxy IS DISTINCT FROM monthly_payment_proxy;


/*-----------------------------------------------------------------------------------------------
4.4.11 Alias confirmation: payment_to_income_ratio → requested_payment_to_income_ratio.

Expected:
    zero mismatches.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS requested_pti_alias_mismatch_rows
FROM tmp_m2_stage_1_source_applications
WHERE requested_payment_to_income_ratio IS DISTINCT FROM payment_to_income_ratio;


/*-----------------------------------------------------------------------------------------------
4.4.12 estimated_pd presence check.

Interpretation:
    estimated_pd is preserved as the Module 1 SQL field and interpreted as the synthetic
    estimated-PD proxy.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS rows_with_estimated_pd,
    COUNT(*) FILTER (WHERE estimated_pd IS NULL) AS rows_missing_synthetic_estimated_pd_proxy,
    MIN(estimated_pd) AS min_synthetic_estimated_pd_proxy,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    MAX(estimated_pd) AS max_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_1_source_applications;


/***************************************************************************************************
END OF SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION

If execution reaches this point:
    1. tmp_m2_stage_1_source_applications exists.
    2. It contains one row per application_id.
    3. It contains exactly one Module 1 scenario / population slice.
    4. Module 1 scenario lineage is normalized and preserved.
    5. Module 2 strategy metadata is preserved.
    6. Application and applicant identifiers are preserved.
    7. Borrower, product, requested-structure, affordability, and risk fields are preserved.
    8. product_type_policy_key is created.
    9. Every product_type maps to exactly one product policy row.
    10. expected_loss_amount is aliased as requested_expected_loss_amount.
    11. monthly_payment_proxy is aliased as requested_monthly_payment_proxy.
    12. payment_to_income_ratio is aliased as requested_payment_to_income_ratio.
    13. estimated_pd is preserved as the Module 1 SQL field and interpreted as the synthetic
        estimated-PD proxy.

No decision outcomes have been created.
No decision flags have been created.
No reason codes have been assigned.
No approved amount has been calculated.
No approved payment has been calculated.
No approved PTI has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No archive rows have been inserted.

***************************************************************************************************/

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 2 OF 7 END
```

Ready for next part: say CONTINUE FULL CODE PART 3
<!-- END_MESSAGE C038-M00182 -->


---

<a id="c038-m00184"></a>

### C038-M00184

**Andrew** · 2026-05-06T17:12:12.039000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00184 -->
CONTINUE FULL CODE PART 3
<!-- END_MESSAGE C038-M00184 -->


---

<a id="c038-m00190"></a>

### C038-M00190

**ChatGPT** · 2026-05-06T17:17:29.675350-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00190 -->
```sql
-- >>> MODULE 2 FULL SQL CODE CAPTURE — PART 3 OF 7 START

/***************************************************************************************************
SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Create a non-decisioning strategy segmentation layer that translates continuous and categorical
    Module 1 inputs into policy-readable diagnostic segments.

    Section 5 answers:

        "How should this synthetic applicant be described for strategy-rule interpretation?"

    Section 5 does NOT answer:

        "What is the final simulated strategy outcome?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_1_source_applications.
    2. Preserve all Section 4 source, lineage, and strategy metadata fields.
    3. Attach global strategy thresholds and product-specific policy thresholds.
    4. Derive non-decisioning diagnostic segments:
            strategy_risk_tier
            requested_pti_bucket
            dti_bucket
            requested_exposure_tier
            requested_expected_loss_tier
            score_band_policy_key
            product_score_policy_segment
            mixed_signal_profile_type
            mixed_signal_condition_count
            borderline_profile_flag
    5. Preserve threshold values in the staged data for auditability and later rule interpretation.
    6. Validate that segmentation is populated without creating decisions, flags, reason codes, or
       approved exposure outputs.

WHY SEGMENTATION IS SEPARATED FROM DECISION RULES:
    Segmentation translates raw values into interpretable diagnostic buckets.
    Decision rules convert those diagnostics into trigger flags and final outcomes.

    Keeping these layers separate improves:
        readability,
        auditability,
        QA,
        troubleshooting,
        and future strategy tuning.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field.

    Section 5 uses estimated_pd only as the synthetic estimated-PD proxy input for diagnostic
    segmentation.

    Section 5 does not recalculate estimated_pd.

REQUESTED PTI BOUNDARY:
    requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.

    Approved payment and approved PTI do not exist yet.

DTI BOUNDARY:
    debt_to_income_ratio is an existing-obligation capacity signal.

    In Module 2 V1.0, DTI is not directly fixed by counteroffer exposure reduction.

REQUESTED EXPOSURE VS APPROVED EXPOSURE:
    requested_amount is the original requested exposure from Module 1.

    approved_amount does not exist in Section 5.

REQUESTED EXPECTED LOSS VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount does not exist in Section 5.

MIXED-SIGNAL PROFILE BOUNDARY:
    mixed_signal_profile_type is diagnostic only.

    It does not automatically approve, decline, route to review, or trigger counteroffer.

BORDERLINE PROFILE BOUNDARY:
    borderline_profile_flag uses the governed borderline_threshold_buffer_pct parameter.

    No hidden hardcoded threshold-adjacent buffer is used.

THRESHOLD ATTACHMENT:
    Section 5 carries forward the strategy and product thresholds used for segmentation so later
    stages can be interpreted without reverse-engineering parameter tables.

WHY NO DECISION OUTPUTS ARE CREATED IN SECTION 5:
    Section 5 does not create:
        decision_outcome
        decision_path
        approval_flag
        decline_flag
        manual_review_flag
        counteroffer_flag
        reason codes
        approved_amount
        approved payment
        approved PTI
        approved Expected Loss

***************************************************************************************************/



/***************************************************************************************************
SECTION 5.1 — CLEAN RESET OF SECTION 5 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_2_strategy_segments;



/***************************************************************************************************
SECTION 5.2 — CREATE DERIVED STRATEGY SEGMENTATION TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_2_strategy_segments

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_1_source_applications

OUTPUT:
    All Section 4 fields plus global thresholds, product thresholds, and non-decisioning diagnostic
    segmentation fields.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_2_strategy_segments
ON COMMIT PRESERVE ROWS
AS
WITH active_strategy_params AS (
    SELECT *
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

threshold_enriched AS (
    SELECT
        s.*,

        /*******************************************************************************************
        Global synthetic estimated-risk thresholds.

        estimated_pd is interpreted as the synthetic estimated-PD proxy.
        *******************************************************************************************/
        p.approve_max_estimated_pd_proxy,
        p.counteroffer_max_estimated_pd_proxy,
        p.review_max_estimated_pd_proxy,
        p.decline_min_estimated_pd_proxy,

        /*******************************************************************************************
        Global PTI thresholds.

        Product-specific PTI thresholds are used for product-aware segmentation, but global values are
        retained for strategy transparency.
        *******************************************************************************************/
        p.global_approve_max_pti,
        p.global_review_max_pti,
        p.global_decline_min_pti,

        /*******************************************************************************************
        DTI thresholds.

        DTI remains an existing-obligation capacity signal.
        *******************************************************************************************/
        p.approve_max_dti,
        p.review_max_dti,
        p.decline_min_dti,

        /*******************************************************************************************
        Borderline diagnostic buffer.

        This governed parameter prevents hidden hardcoded threshold-adjacent logic.
        *******************************************************************************************/
        p.borderline_threshold_buffer_pct,

        /*******************************************************************************************
        Section 6 rule-control parameters.

        These are carried forward so rule-trigger logic is transparent in the staged data.
        *******************************************************************************************/
        p.bankruptcy_policy_stop_enabled,
        p.major_derogatory_policy_stop_enabled,
        p.severe_delinquency_policy_stop_enabled,
        p.severe_delinquency_count_threshold,
        p.high_utilization_review_enabled,
        p.high_utilization_review_threshold,
        p.low_score_review_enabled,
        p.low_score_review_threshold,

        /*******************************************************************************************
        Product policy thresholds and controls.
        *******************************************************************************************/
        pp.product_approve_max_pti,
        pp.product_review_max_pti,
        pp.product_decline_min_pti,
        pp.counteroffer_target_pti,

        pp.product_approve_max_requested_el,
        pp.product_review_max_requested_el,
        pp.product_decline_min_requested_el,
        pp.product_approved_el_cap,

        pp.product_min_approved_amount,
        pp.product_max_approved_amount,

        pp.counteroffer_allowed_flag,
        pp.manual_review_allowed_flag,
        pp.product_min_counteroffer_pct,
        pp.product_max_exposure_reduction_pct,
        pp.exposure_assignment_method,
        pp.approved_amount_rounding_increment,

        /*******************************************************************************************
        Requested Expected Loss low / moderate split.

        This uses product_approve_max_requested_el / 2.0 because Section 5 classifies
        requested-exposure Expected Loss.

        product_approved_el_cap is carried forward for later approved-exposure logic but does not
        drive pre-decision requested Expected Loss tiering.
        *******************************************************************************************/
        (pp.product_approve_max_requested_el / 2.0) AS requested_el_low_moderate_split

    FROM tmp_m2_stage_1_source_applications s
    JOIN active_strategy_params p
        ON TRUE
    JOIN tmp_module2_product_policy_params pp
        ON pp.product_type = s.product_type_policy_key
),

score_normalized AS (
    SELECT
        te.*,

        /*******************************************************************************************
        score_band_policy_key.

        Preserve original score_band and create a normalized strategy policy key.

        Module 1 is not modified.
        *******************************************************************************************/
        CASE
            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('SUPER_PRIME', 'SUPERPRIME', 'SP')
                THEN 'SUPER_PRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('PRIME', 'P')
                THEN 'PRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('NEAR_PRIME', 'NEARPRIME', 'NP')
                THEN 'NEAR_PRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('SUBPRIME', 'SUB_PRIME', 'SUB')
                THEN 'SUBPRIME'

            WHEN UPPER(REGEXP_REPLACE(BTRIM(te.score_band::TEXT), '[^A-Za-z0-9]+', '_', 'g'))
                 IN ('DEEP_SUBPRIME', 'DEEP_SUB_PRIME', 'DEEP_SUB', 'DS')
                THEN 'DEEP_SUBPRIME'

            ELSE NULL
        END AS score_band_policy_key

    FROM threshold_enriched te
),

core_segments AS (
    SELECT
        sn.*,

        /*******************************************************************************************
        Synthetic estimated-risk tier.

        Uses estimated_pd as the Module 1 synthetic estimated-PD proxy input.

        Equality handling:
            estimated_pd <= approve_max_estimated_pd_proxy / 2.0
                LOW_SYNTHETIC_RISK

            estimated_pd <= approve_max_estimated_pd_proxy
                MODERATE_SYNTHETIC_RISK

            estimated_pd <= counteroffer_max_estimated_pd_proxy
                ELEVATED_SYNTHETIC_RISK

            estimated_pd < decline_min_estimated_pd_proxy
                HIGH_SYNTHETIC_RISK

            estimated_pd >= decline_min_estimated_pd_proxy
                SEVERE_SYNTHETIC_RISK
        *******************************************************************************************/
        CASE
            WHEN sn.estimated_pd <= (sn.approve_max_estimated_pd_proxy / 2.0)
                THEN 'LOW_SYNTHETIC_RISK'

            WHEN sn.estimated_pd <= sn.approve_max_estimated_pd_proxy
                THEN 'MODERATE_SYNTHETIC_RISK'

            WHEN sn.estimated_pd <= sn.counteroffer_max_estimated_pd_proxy
                THEN 'ELEVATED_SYNTHETIC_RISK'

            WHEN sn.estimated_pd < sn.decline_min_estimated_pd_proxy
                THEN 'HIGH_SYNTHETIC_RISK'

            ELSE 'SEVERE_SYNTHETIC_RISK'
        END AS strategy_risk_tier,


        /*******************************************************************************************
        Requested PTI bucket.

        Uses requested_payment_to_income_ratio from the original Module 1 requested structure.

        Product-specific PTI thresholds are used so affordability segmentation remains product-aware.
        *******************************************************************************************/
        CASE
            WHEN sn.requested_payment_to_income_ratio <= sn.counteroffer_target_pti
                THEN 'LOW_REQUESTED_PTI'

            WHEN sn.requested_payment_to_income_ratio <= sn.product_approve_max_pti
                THEN 'MODERATE_REQUESTED_PTI'

            WHEN sn.requested_payment_to_income_ratio <= sn.product_review_max_pti
                THEN 'ELEVATED_REQUESTED_PTI'

            WHEN sn.requested_payment_to_income_ratio < sn.product_decline_min_pti
                THEN 'HIGH_REQUESTED_PTI'

            ELSE 'SEVERE_REQUESTED_PTI'
        END AS requested_pti_bucket,


        /*******************************************************************************************
        DTI bucket.

        DTI is an existing-obligation capacity signal.

        It is not directly fixed by counteroffer in Module 2 V1.0.
        *******************************************************************************************/
        CASE
            WHEN sn.debt_to_income_ratio <= (sn.approve_max_dti / 2.0)
                THEN 'LOW_DTI'

            WHEN sn.debt_to_income_ratio <= sn.approve_max_dti
                THEN 'MODERATE_DTI'

            WHEN sn.debt_to_income_ratio < sn.review_max_dti
                THEN 'ELEVATED_DTI'

            WHEN sn.debt_to_income_ratio < sn.decline_min_dti
                THEN 'HIGH_DTI'

            ELSE 'SEVERE_DTI'
        END AS dti_bucket,


        /*******************************************************************************************
        Requested exposure tier.

        BELOW_PRODUCT_MINIMUM:
            requested_amount < product_min_approved_amount

        WITHIN_PRODUCT_LIMITS:
            requested_amount is within product minimum and product maximum.

        ABOVE_PRODUCT_APPROVAL_CAP:
            requested_amount exceeds the product maximum, but the product cap can still satisfy the
            governed minimum viable amount after allowed exposure reduction.

        EXTREME_REQUESTED_EXPOSURE:
            requested_amount exceeds the product cap by more than the allowed exposure-reduction
            framework can reasonably address.

        No undocumented magic number is used. The reducibility test uses governed parameters:
            product_min_approved_amount
            product_min_counteroffer_pct
            product_max_exposure_reduction_pct
        *******************************************************************************************/
        CASE
            WHEN sn.requested_amount < sn.product_min_approved_amount
                THEN 'BELOW_PRODUCT_MINIMUM'

            WHEN sn.requested_amount <= sn.product_max_approved_amount
                THEN 'WITHIN_PRODUCT_LIMITS'

            WHEN sn.product_max_approved_amount >= GREATEST(
                    sn.product_min_approved_amount,
                    sn.requested_amount * sn.product_min_counteroffer_pct,
                    sn.requested_amount * (1.0 - sn.product_max_exposure_reduction_pct)
                 )
                THEN 'ABOVE_PRODUCT_APPROVAL_CAP'

            ELSE 'EXTREME_REQUESTED_EXPOSURE'
        END AS requested_exposure_tier,


        /*******************************************************************************************
        Requested Expected Loss tier.

        Uses requested_expected_loss_amount and requested-exposure thresholds.

        product_approved_el_cap is not used for this pre-decision requested Expected Loss tier.
        *******************************************************************************************/
        CASE
            WHEN sn.requested_expected_loss_amount <= sn.requested_el_low_moderate_split
                THEN 'LOW_REQUESTED_EL'

            WHEN sn.requested_expected_loss_amount <= sn.product_approve_max_requested_el
                THEN 'MODERATE_REQUESTED_EL'

            WHEN sn.requested_expected_loss_amount <= sn.product_review_max_requested_el
                THEN 'ELEVATED_REQUESTED_EL'

            WHEN sn.requested_expected_loss_amount < sn.product_decline_min_requested_el
                THEN 'HIGH_REQUESTED_EL'

            ELSE 'SEVERE_REQUESTED_EL'
        END AS requested_expected_loss_tier

    FROM score_normalized sn
),

mixed_signal_conditions AS (
    SELECT
        cs.*,

        /*******************************************************************************************
        Mixed-signal diagnostic conditions.

        These conditions identify realistic strategy QA profiles. They do not assign final decisions.
        *******************************************************************************************/
        (
            cs.score_band_policy_key IN ('SUPER_PRIME', 'PRIME')
            AND cs.requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
        ) AS strong_credit_high_pti_condition,

        (
            cs.score_band_policy_key IN ('SUBPRIME', 'DEEP_SUBPRIME')
            AND cs.requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS weak_credit_low_pti_condition,

        (
            cs.requested_exposure_tier IN ('ABOVE_PRODUCT_APPROVAL_CAP', 'EXTREME_REQUESTED_EXPOSURE')
            AND cs.strategy_risk_tier IN ('LOW_SYNTHETIC_RISK', 'MODERATE_SYNTHETIC_RISK')
        ) AS large_exposure_low_risk_condition,

        (
            cs.strategy_risk_tier IN ('HIGH_SYNTHETIC_RISK', 'SEVERE_SYNTHETIC_RISK')
            AND (
                cs.requested_exposure_tier = 'BELOW_PRODUCT_MINIMUM'
                OR cs.requested_amount <= cs.product_min_approved_amount
            )
        ) AS high_risk_low_exposure_condition,

        (
            cs.dti_bucket IN ('HIGH_DTI', 'SEVERE_DTI')
            AND cs.requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS high_dti_low_requested_pti_condition

    FROM core_segments cs
),

mixed_signal_scored AS (
    SELECT
        msc.*,

        (
            msc.strong_credit_high_pti_condition::INT
            + msc.weak_credit_low_pti_condition::INT
            + msc.large_exposure_low_risk_condition::INT
            + msc.high_risk_low_exposure_condition::INT
            + msc.high_dti_low_requested_pti_condition::INT
        ) AS mixed_signal_condition_count

    FROM mixed_signal_conditions msc
),

borderline_scored AS (
    SELECT
        mss.*,

        /*******************************************************************************************
        Borderline profile flag.

        A row is borderline if it is within the governed percentage buffer of at least one major
        strategy threshold.

        No hidden 5%, 10%, or other ungoverned buffer is embedded. The buffer is controlled by:
            borderline_threshold_buffer_pct

        Threshold families included:
            synthetic estimated-PD proxy thresholds,
            product PTI thresholds,
            DTI thresholds,
            requested Expected Loss thresholds.
        *******************************************************************************************/
        (
            (
                mss.approve_max_estimated_pd_proxy > 0
                AND ABS(mss.estimated_pd - mss.approve_max_estimated_pd_proxy)
                    <= mss.approve_max_estimated_pd_proxy * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.counteroffer_max_estimated_pd_proxy > 0
                AND ABS(mss.estimated_pd - mss.counteroffer_max_estimated_pd_proxy)
                    <= mss.counteroffer_max_estimated_pd_proxy * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.decline_min_estimated_pd_proxy > 0
                AND ABS(mss.estimated_pd - mss.decline_min_estimated_pd_proxy)
                    <= mss.decline_min_estimated_pd_proxy * mss.borderline_threshold_buffer_pct
            )

            OR (
                mss.product_approve_max_pti > 0
                AND ABS(mss.requested_payment_to_income_ratio - mss.product_approve_max_pti)
                    <= mss.product_approve_max_pti * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.product_review_max_pti > 0
                AND ABS(mss.requested_payment_to_income_ratio - mss.product_review_max_pti)
                    <= mss.product_review_max_pti * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.product_decline_min_pti > 0
                AND ABS(mss.requested_payment_to_income_ratio - mss.product_decline_min_pti)
                    <= mss.product_decline_min_pti * mss.borderline_threshold_buffer_pct
            )

            OR (
                mss.approve_max_dti > 0
                AND ABS(mss.debt_to_income_ratio - mss.approve_max_dti)
                    <= mss.approve_max_dti * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.review_max_dti > 0
                AND ABS(mss.debt_to_income_ratio - mss.review_max_dti)
                    <= mss.review_max_dti * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.decline_min_dti > 0
                AND ABS(mss.debt_to_income_ratio - mss.decline_min_dti)
                    <= mss.decline_min_dti * mss.borderline_threshold_buffer_pct
            )

            OR (
                mss.product_approve_max_requested_el > 0
                AND ABS(mss.requested_expected_loss_amount - mss.product_approve_max_requested_el)
                    <= mss.product_approve_max_requested_el * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.product_review_max_requested_el > 0
                AND ABS(mss.requested_expected_loss_amount - mss.product_review_max_requested_el)
                    <= mss.product_review_max_requested_el * mss.borderline_threshold_buffer_pct
            )
            OR (
                mss.product_decline_min_requested_el > 0
                AND ABS(mss.requested_expected_loss_amount - mss.product_decline_min_requested_el)
                    <= mss.product_decline_min_requested_el * mss.borderline_threshold_buffer_pct
            )
        ) AS borderline_profile_flag

    FROM mixed_signal_scored mss
),

final_segments AS (
    SELECT
        bs.*,

        /*******************************************************************************************
        Product × score policy segment.

        This field supports later segment-level QA and product × score strategy matrices.
        *******************************************************************************************/
        bs.product_type_policy_key || '_' || bs.score_band_policy_key
            AS product_score_policy_segment,

        /*******************************************************************************************
        Mixed-signal profile type.

        Priority convention:
            If exactly one mixed-signal condition applies, assign that type.
            If more than one applies, assign MULTIPLE_MIXED_SIGNALS.
            If none applies, assign NO_MIXED_SIGNAL_PROFILE.

        Section 5 does not silently choose one condition over another when multiple conditions apply.
        *******************************************************************************************/
        CASE
            WHEN bs.mixed_signal_condition_count > 1
                THEN 'MULTIPLE_MIXED_SIGNALS'

            WHEN bs.strong_credit_high_pti_condition IS TRUE
                THEN 'STRONG_CREDIT_HIGH_PTI'

            WHEN bs.weak_credit_low_pti_condition IS TRUE
                THEN 'WEAK_CREDIT_LOW_PTI'

            WHEN bs.large_exposure_low_risk_condition IS TRUE
                THEN 'LARGE_EXPOSURE_LOW_RISK'

            WHEN bs.high_risk_low_exposure_condition IS TRUE
                THEN 'HIGH_RISK_LOW_EXPOSURE'

            WHEN bs.high_dti_low_requested_pti_condition IS TRUE
                THEN 'HIGH_DTI_LOW_REQUESTED_PTI'

            ELSE 'NO_MIXED_SIGNAL_PROFILE'
        END AS mixed_signal_profile_type

    FROM borderline_scored bs
)

SELECT *
FROM final_segments;



/***************************************************************************************************
SECTION 5.3 — LOCAL FAIL-FAST CHECKS FOR STRATEGY SEGMENTATION
****************************************************************************************************

PURPOSE:
    Validate that the Section 5 segmentation layer preserved row-level structure and produced
    complete diagnostic segments.

These are local staging gatekeepers only.

They are not:
    final decision validation,
    reason-code validation,
    approved-exposure validation,
    archive validation,
    or full Module 2 QA.

***************************************************************************************************/

DO $$
DECLARE
    v_stage1_count BIGINT;
    v_stage2_count BIGINT;
    v_stage2_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    v_null_segment_count BIGINT;
    v_null_policy_key_count BIGINT;
    v_product_policy_mismatch_count BIGINT;
    v_missing_threshold_count BIGINT;
    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 4 to Section 5.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage1_count
    FROM tmp_m2_stage_1_source_applications;

    SELECT COUNT(*)
    INTO v_stage2_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_count <> v_stage1_count THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: row count changed from Section 4 to Section 5. Stage 1 rows: %, Stage 2 rows: %.',
            v_stage1_count,
            v_stage2_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage2_distinct_app_count
    FROM tmp_m2_stage_2_strategy_segments;

    IF v_stage2_distinct_app_count <> v_stage2_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_2_strategy_segments
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 5 failure: application_id uniqueness was not preserved. Stage 2 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage2_count,
            v_stage2_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required segmentation fields must be populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_segment_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE strategy_risk_tier IS NULL
       OR requested_pti_bucket IS NULL
       OR dti_bucket IS NULL
       OR requested_exposure_tier IS NULL
       OR requested_expected_loss_tier IS NULL
       OR product_score_policy_segment IS NULL
       OR mixed_signal_profile_type IS NULL
       OR mixed_signal_condition_count IS NULL
       OR mixed_signal_condition_count < 0
       OR borderline_profile_flag IS NULL;

    IF v_null_segment_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have null or invalid derived segmentation fields.',
            v_null_segment_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product and score policy keys must be populated.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_policy_key_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE product_type_policy_key IS NULL
       OR score_band_policy_key IS NULL;

    IF v_null_policy_key_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have null product_type_policy_key or score_band_policy_key.',
            v_null_policy_key_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: every row must still have exactly one product policy configuration.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_product_policy_mismatch_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE product_policy_match_count <> 1
       OR product_policy_config_found_flag IS DISTINCT FROM TRUE;

    IF v_product_policy_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) no longer have exactly one product policy configuration.',
            v_product_policy_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: all thresholds needed for segmentation and later rule logic must be available.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_missing_threshold_count
    FROM tmp_m2_stage_2_strategy_segments
    WHERE approve_max_estimated_pd_proxy IS NULL
       OR counteroffer_max_estimated_pd_proxy IS NULL
       OR review_max_estimated_pd_proxy IS NULL
       OR decline_min_estimated_pd_proxy IS NULL

       OR global_approve_max_pti IS NULL
       OR global_review_max_pti IS NULL
       OR global_decline_min_pti IS NULL

       OR approve_max_dti IS NULL
       OR review_max_dti IS NULL
       OR decline_min_dti IS NULL

       OR borderline_threshold_buffer_pct IS NULL

       OR bankruptcy_policy_stop_enabled IS NULL
       OR major_derogatory_policy_stop_enabled IS NULL
       OR severe_delinquency_policy_stop_enabled IS NULL
       OR severe_delinquency_count_threshold IS NULL
       OR high_utilization_review_enabled IS NULL
       OR high_utilization_review_threshold IS NULL
       OR low_score_review_enabled IS NULL
       OR low_score_review_threshold IS NULL

       OR product_approve_max_pti IS NULL
       OR product_review_max_pti IS NULL
       OR product_decline_min_pti IS NULL
       OR counteroffer_target_pti IS NULL

       OR product_approve_max_requested_el IS NULL
       OR product_review_max_requested_el IS NULL
       OR product_decline_min_requested_el IS NULL
       OR product_approved_el_cap IS NULL
       OR requested_el_low_moderate_split IS NULL

       OR product_min_approved_amount IS NULL
       OR product_max_approved_amount IS NULL

       OR counteroffer_allowed_flag IS NULL
       OR manual_review_allowed_flag IS NULL
       OR product_min_counteroffer_pct IS NULL
       OR product_max_exposure_reduction_pct IS NULL
       OR exposure_assignment_method IS NULL
       OR approved_amount_rounding_increment IS NULL;

    IF v_missing_threshold_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: % row(s) have missing threshold or product policy values.',
            v_missing_threshold_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 5 must not create decision, reason-code, or approved-exposure fields.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_2_strategy_segments'::REGCLASS
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
            'Module 2 Section 5 failure: forbidden decision, reason-code, or approved-exposure field(s) were created in segmentation stage.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 5.4 — LOCAL SEGMENTATION SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for Section 5 segmentation.

These are staging diagnostics only.
They should not be interpreted as final strategy validation.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
5.4.1 Row count and distinct application_id count.
-----------------------------------------------------------------------------------------------*/
SELECT
    COUNT(*) AS stage2_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_2_strategy_segments;


/*-----------------------------------------------------------------------------------------------
5.4.2 Count by synthetic estimated-risk tier.
-----------------------------------------------------------------------------------------------*/
SELECT
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY strategy_risk_tier
ORDER BY
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.3 Count by requested PTI bucket.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_pti_bucket
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.4 Count by DTI bucket.
-----------------------------------------------------------------------------------------------*/
SELECT
    dti_bucket,
    COUNT(*) AS row_count,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio
FROM tmp_m2_stage_2_strategy_segments
GROUP BY dti_bucket
ORDER BY
    CASE dti_bucket
        WHEN 'LOW_DTI' THEN 1
        WHEN 'MODERATE_DTI' THEN 2
        WHEN 'ELEVATED_DTI' THEN 3
        WHEN 'HIGH_DTI' THEN 4
        WHEN 'SEVERE_DTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.5 Count by requested exposure tier.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_tier,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_exposure_tier
ORDER BY
    CASE requested_exposure_tier
        WHEN 'BELOW_PRODUCT_MINIMUM' THEN 1
        WHEN 'WITHIN_PRODUCT_LIMITS' THEN 2
        WHEN 'ABOVE_PRODUCT_APPROVAL_CAP' THEN 3
        WHEN 'EXTREME_REQUESTED_EXPOSURE' THEN 4
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.6 Count by requested Expected Loss tier.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_expected_loss_tier,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY requested_expected_loss_tier
ORDER BY
    CASE requested_expected_loss_tier
        WHEN 'LOW_REQUESTED_EL' THEN 1
        WHEN 'MODERATE_REQUESTED_EL' THEN 2
        WHEN 'ELEVATED_REQUESTED_EL' THEN 3
        WHEN 'HIGH_REQUESTED_EL' THEN 4
        WHEN 'SEVERE_REQUESTED_EL' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.7 Count by product × score policy segment.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_score_policy_segment,
    COUNT(*) AS row_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY product_score_policy_segment
ORDER BY product_score_policy_segment;


/*-----------------------------------------------------------------------------------------------
5.4.8 Count by mixed-signal profile type.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    COUNT(*) AS row_count,
    AVG(mixed_signal_condition_count) AS avg_mixed_signal_condition_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY mixed_signal_profile_type
ORDER BY
    CASE mixed_signal_profile_type
        WHEN 'NO_MIXED_SIGNAL_PROFILE' THEN 1
        WHEN 'STRONG_CREDIT_HIGH_PTI' THEN 2
        WHEN 'WEAK_CREDIT_LOW_PTI' THEN 3
        WHEN 'LARGE_EXPOSURE_LOW_RISK' THEN 4
        WHEN 'HIGH_RISK_LOW_EXPOSURE' THEN 5
        WHEN 'HIGH_DTI_LOW_REQUESTED_PTI' THEN 6
        WHEN 'MULTIPLE_MIXED_SIGNALS' THEN 7
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.9 Count by borderline profile flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY borderline_profile_flag
ORDER BY borderline_profile_flag;


/*-----------------------------------------------------------------------------------------------
5.4.10 Product × synthetic estimated-risk tier summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    product_type_policy_key,
    strategy_risk_tier
ORDER BY
    product_type_policy_key,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.11 Score band × synthetic estimated-risk tier summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    score_band_policy_key,
    strategy_risk_tier
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
5.4.12 Requested PTI bucket × synthetic estimated-risk tier summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_2_strategy_segments
GROUP BY
    requested_pti_bucket,
    strategy_risk_tier
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END,
    CASE strategy_risk_tier
        WHEN 'LOW_SYNTHETIC_RISK' THEN 1
        WHEN 'MODERATE_SYNTHETIC_RISK' THEN 2
        WHEN 'ELEVATED_SYNTHETIC_RISK' THEN 3
        WHEN 'HIGH_SYNTHETIC_RISK' THEN 4
        WHEN 'SEVERE_SYNTHETIC_RISK' THEN 5
        ELSE 99
    END;


/***************************************************************************************************
END OF SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER

If execution reaches this point:
    1. tmp_m2_stage_2_strategy_segments exists.
    2. Row count is unchanged from tmp_m2_stage_1_source_applications.
    3. application_id remains unique.
    4. Module 1 lineage is preserved.
    5. Module 2 strategy metadata is preserved.
    6. Product policy thresholds and global strategy thresholds are attached.
    7. estimated_pd is preserved and interpreted as the synthetic estimated-PD proxy.
    8. requested_monthly_payment_proxy is preserved from Module 1 monthly_payment_proxy.
    9. requested_payment_to_income_ratio is preserved from Module 1 payment_to_income_ratio.
    10. requested_expected_loss_amount is preserved from Module 1 expected_loss_amount.
    11. strategy_risk_tier is populated.
    12. requested_pti_bucket is populated.
    13. dti_bucket is populated.
    14. requested_exposure_tier is populated.
    15. requested_expected_loss_tier is populated using requested-exposure thresholds.
    16. score_band_policy_key is populated.
    17. product_score_policy_segment is populated.
    18. mixed_signal_profile_type is populated.
    19. mixed_signal_condition_count is populated.
    20. borderline_profile_flag is populated using governed borderline_threshold_buffer_pct.

No decision_outcome is assigned.
No approval / decline / manual review / counteroffer flags are assigned.
No reason codes are assigned.
No approved_amount is calculated.
No approved_monthly_payment_proxy is calculated.
No approved_payment_to_income_ratio is calculated.
No approved_expected_loss_amount is calculated.
No final latest-run output table is created.
No archive rows are inserted.

***************************************************************************************************/



/***************************************************************************************************
SECTION 6 — RULE FLAG CONSTRUCTION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Convert Section 5 diagnostic segments into deterministic, auditable simulated rule-trigger flags.

    Section 6 answers:

        "Which simulated policy conditions are triggered?"

    Section 6 does NOT answer:

        "What is the final simulated strategy outcome?"

SQL PURPOSE:
    1. Read from tmp_m2_stage_2_strategy_segments.
    2. Preserve all prior source, lineage, strategy metadata, threshold, and segmentation fields.
    3. Create transparent rule-trigger flags across:
            hard simulated policy stops,
            synthetic estimated-risk bands,
            requested affordability,
            DTI capacity,
            requested Expected Loss,
            requested exposure,
            counteroffer candidates,
            manual-review candidates,
            supplemental behavioral review signals,
            clean approval candidate diagnostics.
    4. Create numeric rule-count fields.
    5. Validate flag completeness, count consistency, true banding-family coverage, and no premature
       final outcome / reason / exposure output creation.

WHY RULE FLAGS ARE SEPARATED FROM FINAL DECISION HIERARCHY:
    Multiple simulated policy conditions can validly coexist on the same synthetic applicant.

    Section 6 preserves overlapping triggers.
    Section 7 prioritizes them into preliminary routing.
    Section 9 resolves final decision_outcome after exposure treatment and counteroffer feasibility.

WHY HARD SIMULATED POLICY STOP FLAGS ARE NOT FINAL DECLINES YET:
    Section 6 identifies severe policy-stop trigger conditions.
    Final outcome assignment remains downstream.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
    proxy.

    Section 6 does not recalculate estimated_pd.

REQUESTED PTI BOUNDARY:
    Requested PTI flags use requested_payment_to_income_ratio from the original Module 1 requested
    structure.

    Approved PTI does not exist yet.

DTI BOUNDARY:
    DTI remains an existing-obligation capacity signal.

    It is not directly counteroffer-adjustable in Module 2 V1.0.

REQUESTED EXPECTED LOSS BOUNDARY:
    Requested Expected Loss flags use requested_expected_loss_amount.

    approved_expected_loss_amount does not exist yet.

COUNTEROFFER CANDIDATE BOUNDARY:
    Section 6 identifies counteroffer candidates only.

    It does not calculate:
        approved_amount
        counteroffer_amount
        approved payment
        approved PTI
        approved Expected Loss
        counteroffer feasibility.

MANUAL REVIEW CANDIDATE BOUNDARY:
    Section 6 identifies manual-review candidates only.

    It does not assign MANUAL_REVIEW as final decision_outcome.

CLEAN APPROVAL CANDIDATE BOUNDARY:
    clean_approval_candidate_flag is diagnostic only.

    It does not assign APPROVE.

HIGH-UTILIZATION AND LOW-SCORE REVIEW FLAG BOUNDARY:
    These are strategy diagnostics for simulated review routing.
    They are not production underwriting rules.

REASON-CODE BOUNDARY:
    Section 6 does not assign reason codes.

FINAL OUTCOME BOUNDARY:
    Section 6 does not assign decision_outcome, final decision_path, final flags, approved amount,
    approved payment, approved PTI, or approved Expected Loss.

***************************************************************************************************/



/***************************************************************************************************
SECTION 6.1 — CLEAN RESET OF SECTION 6 STAGING OBJECT
****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_stage_3_rule_flags;



/***************************************************************************************************
SECTION 6.2 — CREATE RULE FLAG STAGING TABLE
****************************************************************************************************

TABLE:
    tmp_m2_stage_3_rule_flags

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

INPUT:
    tmp_m2_stage_2_strategy_segments

OUTPUT:
    All Section 5 fields plus non-final rule trigger flags and trigger count fields.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_3_rule_flags
ON COMMIT PRESERVE ROWS
AS
WITH hard_policy_stop_flags AS (
    SELECT
        s.*,

        /*******************************************************************************************
        Hard simulated policy stop flags.

        These identify severe simulated policy conditions. They do not assign final DECLINE yet.
        *******************************************************************************************/
        (
            s.bankruptcy_policy_stop_enabled IS TRUE
            AND s.bankruptcy_flag IS TRUE
        ) AS bankruptcy_policy_stop_flag,

        (
            s.major_derogatory_policy_stop_enabled IS TRUE
            AND s.major_derogatory_flag IS TRUE
        ) AS major_derogatory_policy_stop_flag,

        (
            s.severe_delinquency_policy_stop_enabled IS TRUE
            AND s.delinquency_count_12m >= s.severe_delinquency_count_threshold
        ) AS severe_delinquency_policy_stop_flag

    FROM tmp_m2_stage_2_strategy_segments s
),

hard_policy_stop_counted AS (
    SELECT
        hps.*,

        (
            hps.bankruptcy_policy_stop_flag
            OR hps.major_derogatory_policy_stop_flag
            OR hps.severe_delinquency_policy_stop_flag
        ) AS hard_policy_stop_flag,

        (
            hps.bankruptcy_policy_stop_flag::INT
            + hps.major_derogatory_policy_stop_flag::INT
            + hps.severe_delinquency_policy_stop_flag::INT
        ) AS hard_policy_stop_count

    FROM hard_policy_stop_flags hps
),

synthetic_risk_flags AS (
    SELECT
        hpsc.*,

        /*******************************************************************************************
        Synthetic estimated-risk band flags.

        These form a true banding family:
            exactly one should be TRUE per row.

        estimated_pd is interpreted as the synthetic estimated-PD proxy.
        *******************************************************************************************/
        (
            hpsc.estimated_pd <= hpsc.approve_max_estimated_pd_proxy
        ) AS synthetic_risk_clean_approval_band_flag,

        (
            hpsc.estimated_pd > hpsc.approve_max_estimated_pd_proxy
            AND hpsc.estimated_pd <= hpsc.counteroffer_max_estimated_pd_proxy
        ) AS synthetic_risk_counteroffer_band_flag,

        (
            hpsc.estimated_pd > hpsc.counteroffer_max_estimated_pd_proxy
            AND hpsc.estimated_pd < hpsc.decline_min_estimated_pd_proxy
        ) AS synthetic_risk_review_band_flag,

        (
            hpsc.estimated_pd >= hpsc.decline_min_estimated_pd_proxy
        ) AS synthetic_risk_decline_trigger_flag

    FROM hard_policy_stop_counted hpsc
),

synthetic_risk_counted AS (
    SELECT
        srf.*,

        (
            srf.synthetic_risk_counteroffer_band_flag::INT
            + srf.synthetic_risk_review_band_flag::INT
            + srf.synthetic_risk_decline_trigger_flag::INT
        ) AS synthetic_risk_trigger_count

    FROM synthetic_risk_flags srf
),

affordability_flags AS (
    SELECT
        src.*,

        /*******************************************************************************************
        Requested affordability flags.

        These use requested_payment_to_income_ratio, not approved PTI.
        Approved PTI does not exist yet.
        *******************************************************************************************/
        (
            src.requested_payment_to_income_ratio <= src.product_approve_max_pti
        ) AS requested_pti_clean_band_flag,

        (
            src.requested_payment_to_income_ratio > src.product_approve_max_pti
        ) AS requested_pti_counteroffer_candidate_flag,

        (
            src.requested_payment_to_income_ratio > src.product_approve_max_pti
            AND src.requested_payment_to_income_ratio < src.product_decline_min_pti
        ) AS requested_pti_review_trigger_flag,

        (
            src.requested_payment_to_income_ratio >= src.product_decline_min_pti
        ) AS requested_pti_decline_trigger_flag

    FROM synthetic_risk_counted src
),

affordability_counted AS (
    SELECT
        af.*,

        (
            af.requested_pti_counteroffer_candidate_flag::INT
            + af.requested_pti_review_trigger_flag::INT
            + af.requested_pti_decline_trigger_flag::INT
        ) AS affordability_trigger_count

    FROM affordability_flags af
),

dti_flags AS (
    SELECT
        ac.*,

        /*******************************************************************************************
        DTI capacity flags.

        These form a true banding family:
            exactly one should be TRUE per row.

        DTI is an existing-obligation capacity signal and is not directly counteroffer-adjustable.
        *******************************************************************************************/
        (
            ac.debt_to_income_ratio <= ac.approve_max_dti
        ) AS dti_clean_band_flag,

        (
            ac.debt_to_income_ratio > ac.approve_max_dti
            AND ac.debt_to_income_ratio < ac.decline_min_dti
        ) AS dti_review_trigger_flag,

        (
            ac.debt_to_income_ratio >= ac.decline_min_dti
        ) AS dti_decline_trigger_flag

    FROM affordability_counted ac
),

dti_counted AS (
    SELECT
        df.*,

        (
            df.dti_review_trigger_flag::INT
            + df.dti_decline_trigger_flag::INT
        ) AS dti_trigger_count

    FROM dti_flags df
),

requested_el_flags AS (
    SELECT
        dc.*,

        /*******************************************************************************************
        Requested Expected Loss flags.

        These use requested_expected_loss_amount from Module 1 requested exposure.

        approved_expected_loss_amount does not exist yet.
        *******************************************************************************************/
        (
            dc.requested_expected_loss_amount <= dc.product_approve_max_requested_el
        ) AS requested_el_clean_band_flag,

        (
            dc.requested_expected_loss_amount > dc.product_approve_max_requested_el
        ) AS requested_el_counteroffer_candidate_flag,

        (
            dc.requested_expected_loss_amount > dc.product_approve_max_requested_el
            AND dc.requested_expected_loss_amount < dc.product_decline_min_requested_el
        ) AS requested_el_review_trigger_flag,

        (
            dc.requested_expected_loss_amount >= dc.product_decline_min_requested_el
        ) AS requested_el_decline_trigger_flag

    FROM dti_counted dc
),

requested_el_counted AS (
    SELECT
        ref.*,

        (
            ref.requested_el_counteroffer_candidate_flag::INT
            + ref.requested_el_review_trigger_flag::INT
            + ref.requested_el_decline_trigger_flag::INT
        ) AS requested_el_trigger_count

    FROM requested_el_flags ref
),

exposure_flags AS (
    SELECT
        rec.*,

        /*******************************************************************************************
        Requested exposure flags.

        Above-cap exposure may be counteroffer-eligible.
        Extreme exposure may later become unresolved review or final no-offer depending on hierarchy
        and configured strategy behavior.

        Section 6 does not calculate counteroffer amount.
        *******************************************************************************************/
        (
            rec.requested_exposure_tier = 'BELOW_PRODUCT_MINIMUM'
        ) AS requested_exposure_below_product_minimum_flag,

        (
            rec.requested_exposure_tier = 'WITHIN_PRODUCT_LIMITS'
        ) AS requested_exposure_within_product_limit_flag,

        (
            rec.requested_exposure_tier = 'ABOVE_PRODUCT_APPROVAL_CAP'
        ) AS requested_exposure_above_product_cap_flag,

        (
            rec.requested_exposure_tier = 'EXTREME_REQUESTED_EXPOSURE'
        ) AS requested_exposure_extreme_flag,

        (
            rec.requested_exposure_tier = 'ABOVE_PRODUCT_APPROVAL_CAP'
        ) AS exposure_counteroffer_candidate_flag,

        (
            rec.requested_exposure_tier IN (
                'BELOW_PRODUCT_MINIMUM',
                'EXTREME_REQUESTED_EXPOSURE'
            )
        ) AS exposure_policy_stop_candidate_flag

    FROM requested_el_counted rec
),

exposure_counted AS (
    SELECT
        ef.*,

        (
            ef.requested_exposure_below_product_minimum_flag::INT
            + ef.requested_exposure_above_product_cap_flag::INT
            + ef.requested_exposure_extreme_flag::INT
            + ef.exposure_policy_stop_candidate_flag::INT
        ) AS exposure_trigger_count

    FROM exposure_flags ef
),

counteroffer_candidate_flags AS (
    SELECT
        ec.*,

        /*******************************************************************************************
        Counteroffer candidate flags.

        These indicate that the row may require reduced-exposure feasibility testing later.

        They do not prove a viable counteroffer exists.
        They do not calculate approved_amount.
        They do not assign COUNTEROFFER as final decision_outcome.
        *******************************************************************************************/
        ec.counteroffer_allowed_flag AS counteroffer_allowed_by_product_flag,

        ec.synthetic_risk_counteroffer_band_flag AS counteroffer_risk_band_eligible_flag,

        ec.requested_pti_counteroffer_candidate_flag AS counteroffer_affordability_candidate_flag,

        ec.exposure_counteroffer_candidate_flag AS counteroffer_exposure_candidate_flag,

        ec.requested_el_counteroffer_candidate_flag AS counteroffer_expected_loss_candidate_flag

    FROM exposure_counted ec
),

counteroffer_candidate_counted AS (
    SELECT
        ccf.*,

        (
            ccf.counteroffer_risk_band_eligible_flag::INT
            + ccf.counteroffer_affordability_candidate_flag::INT
            + ccf.counteroffer_exposure_candidate_flag::INT
            + ccf.counteroffer_expected_loss_candidate_flag::INT
        ) AS counteroffer_candidate_trigger_count,

        (
            ccf.counteroffer_allowed_by_product_flag IS TRUE
            AND (
                ccf.counteroffer_risk_band_eligible_flag
                OR ccf.counteroffer_affordability_candidate_flag
                OR ccf.counteroffer_exposure_candidate_flag
                OR ccf.counteroffer_expected_loss_candidate_flag
            )
        ) AS counteroffer_candidate_flag

    FROM counteroffer_candidate_flags ccf
),

supplemental_behavior_flags AS (
    SELECT
        ccc.*,

        /*******************************************************************************************
        Supplemental behavioral review flags.

        These are strategy diagnostics that may support review routing.

        They are not final outcomes and not reason codes.
        *******************************************************************************************/
        (
            ccc.high_utilization_review_enabled IS TRUE
            AND ccc.utilization_rate >= ccc.high_utilization_review_threshold
        ) AS high_utilization_review_trigger_flag,

        (
            ccc.low_score_review_enabled IS TRUE
            AND ccc.credit_score <= ccc.low_score_review_threshold
        ) AS low_score_review_trigger_flag

    FROM counteroffer_candidate_counted ccc
),

supplemental_behavior_counted AS (
    SELECT
        sbf.*,

        (
            sbf.high_utilization_review_trigger_flag
            OR sbf.low_score_review_trigger_flag
        ) AS supplemental_behavioral_review_trigger_flag,

        (
            sbf.high_utilization_review_trigger_flag::INT
            + sbf.low_score_review_trigger_flag::INT
        ) AS supplemental_behavioral_review_trigger_count

    FROM supplemental_behavior_flags sbf
),

manual_review_candidate_flags AS (
    SELECT
        sbc.*,

        /*******************************************************************************************
        Manual review candidate flags.

        These identify unresolved or intermediate signal patterns.

        They do not assign MANUAL_REVIEW as final decision_outcome.
        *******************************************************************************************/
        sbc.manual_review_allowed_flag AS manual_review_allowed_by_product_flag,

        sbc.synthetic_risk_review_band_flag AS manual_review_risk_trigger_flag,

        sbc.requested_pti_review_trigger_flag AS manual_review_affordability_trigger_flag,

        sbc.dti_review_trigger_flag AS manual_review_dti_trigger_flag,

        sbc.requested_el_review_trigger_flag AS manual_review_expected_loss_trigger_flag,

        (
            sbc.mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
        ) AS manual_review_mixed_signal_trigger_flag,

        sbc.borderline_profile_flag AS manual_review_borderline_trigger_flag

    FROM supplemental_behavior_counted sbc
),

manual_review_candidate_counted AS (
    SELECT
        mrcf.*,

        (
            mrcf.manual_review_risk_trigger_flag::INT
            + mrcf.manual_review_affordability_trigger_flag::INT
            + mrcf.manual_review_dti_trigger_flag::INT
            + mrcf.manual_review_expected_loss_trigger_flag::INT
            + mrcf.manual_review_mixed_signal_trigger_flag::INT
            + mrcf.manual_review_borderline_trigger_flag::INT
            + mrcf.supplemental_behavioral_review_trigger_flag::INT
        ) AS manual_review_candidate_trigger_count,

        (
            mrcf.manual_review_allowed_by_product_flag IS TRUE
            AND (
                mrcf.manual_review_risk_trigger_flag
                OR mrcf.manual_review_affordability_trigger_flag
                OR mrcf.manual_review_dti_trigger_flag
                OR mrcf.manual_review_expected_loss_trigger_flag
                OR mrcf.manual_review_mixed_signal_trigger_flag
                OR mrcf.manual_review_borderline_trigger_flag
                OR mrcf.supplemental_behavioral_review_trigger_flag
            )
        ) AS manual_review_candidate_flag

    FROM manual_review_candidate_flags mrcf
),

clean_approval_diagnostic AS (
    SELECT
        mrcc.*,

        /*******************************************************************************************
        Clean approval candidate flag.

        Diagnostic only.

        This flag is TRUE only when no major trigger family is active and the row appears clean across
        key simulated strategy dimensions.

        It does not assign APPROVE.
        *******************************************************************************************/
        (
            mrcc.hard_policy_stop_flag IS FALSE
            AND mrcc.synthetic_risk_clean_approval_band_flag IS TRUE
            AND mrcc.requested_pti_clean_band_flag IS TRUE
            AND mrcc.dti_clean_band_flag IS TRUE
            AND mrcc.requested_el_clean_band_flag IS TRUE
            AND mrcc.requested_exposure_within_product_limit_flag IS TRUE
            AND mrcc.synthetic_risk_decline_trigger_flag IS FALSE
            AND mrcc.requested_pti_decline_trigger_flag IS FALSE
            AND mrcc.dti_decline_trigger_flag IS FALSE
            AND mrcc.requested_el_decline_trigger_flag IS FALSE
            AND mrcc.requested_exposure_extreme_flag IS FALSE
            AND mrcc.counteroffer_candidate_flag IS FALSE
            AND mrcc.manual_review_candidate_flag IS FALSE
        ) AS clean_approval_candidate_flag

    FROM manual_review_candidate_counted mrcc
),

final_rule_flags AS (
    SELECT
        cad.*,

        /*******************************************************************************************
        True banding-family coverage diagnostics.

        These count fields are intentionally limited to rule families where exactly one band should
        be active per row.

        They do not force mutual exclusivity across broader trigger families because multiple
        simulated policy signals can validly coexist on the same synthetic applicant.
        *******************************************************************************************/
        (
            cad.synthetic_risk_clean_approval_band_flag::INT
            + cad.synthetic_risk_counteroffer_band_flag::INT
            + cad.synthetic_risk_review_band_flag::INT
            + cad.synthetic_risk_decline_trigger_flag::INT
        ) AS synthetic_risk_band_flag_count,

        (
            cad.dti_clean_band_flag::INT
            + cad.dti_review_trigger_flag::INT
            + cad.dti_decline_trigger_flag::INT
        ) AS dti_band_flag_count,

        /*******************************************************************************************
        Total rule trigger count.

        Diagnostic only.

        This is not a reason-code count and not a decision priority rank.
        *******************************************************************************************/
        (
            cad.hard_policy_stop_count
            + cad.synthetic_risk_trigger_count
            + cad.affordability_trigger_count
            + cad.dti_trigger_count
            + cad.requested_el_trigger_count
            + cad.exposure_trigger_count
            + cad.counteroffer_candidate_trigger_count
            + cad.manual_review_candidate_trigger_count
            + cad.supplemental_behavioral_review_trigger_count
        ) AS total_rule_trigger_count

    FROM clean_approval_diagnostic cad
)

SELECT *
FROM final_rule_flags;



/***************************************************************************************************
SECTION 6.3 — LOCAL FAIL-FAST CHECKS FOR RULE FLAG CONSTRUCTION
****************************************************************************************************

PURPOSE:
    Validate the Section 6 rule-trigger layer before preliminary routing is built.

These are local staging gatekeepers only.

They are not:
    final decision validation,
    reason-code validation,
    approved-exposure validation,
    archive validation,
    or full Module 2 QA.

***************************************************************************************************/

DO $$
DECLARE
    v_stage2_count BIGINT;
    v_stage3_count BIGINT;
    v_stage3_distinct_app_count BIGINT;
    v_duplicate_application_count BIGINT;

    v_null_flag_count BIGINT;
    v_null_count_field_count BIGINT;
    v_negative_count_field_count BIGINT;

    v_clean_conflict_count BIGINT;
    v_counteroffer_not_allowed_count BIGINT;
    v_manual_review_not_allowed_count BIGINT;

    v_synthetic_risk_decline_mismatch_count BIGINT;
    v_requested_pti_decline_mismatch_count BIGINT;
    v_dti_decline_mismatch_count BIGINT;
    v_requested_el_decline_mismatch_count BIGINT;

    v_synthetic_risk_band_coverage_violation_count BIGINT;
    v_dti_band_coverage_violation_count BIGINT;

    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 5 to Section 6.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage2_count
    FROM tmp_m2_stage_2_strategy_segments;

    SELECT COUNT(*)
    INTO v_stage3_count
    FROM tmp_m2_stage_3_rule_flags;

    IF v_stage3_count <> v_stage2_count THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: row count changed from Section 5 to Section 6. Stage 2 rows: %, Stage 3 rows: %.',
            v_stage2_count,
            v_stage3_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: application_id remains unique.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(DISTINCT application_id)
    INTO v_stage3_distinct_app_count
    FROM tmp_m2_stage_3_rule_flags;

    IF v_stage3_distinct_app_count <> v_stage3_count THEN
        SELECT COUNT(*)
        INTO v_duplicate_application_count
        FROM (
            SELECT application_id
            FROM tmp_m2_stage_3_rule_flags
            GROUP BY application_id
            HAVING COUNT(*) > 1
        ) d;

        RAISE EXCEPTION
            'Module 2 Section 6 failure: application_id uniqueness was not preserved. Stage 3 rows: %, distinct application_id count: %, duplicate application_id group count: %.',
            v_stage3_count,
            v_stage3_distinct_app_count,
            v_duplicate_application_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: required rule flags must be non-null.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_flag_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE bankruptcy_policy_stop_flag IS NULL
       OR major_derogatory_policy_stop_flag IS NULL
       OR severe_delinquency_policy_stop_flag IS NULL
       OR hard_policy_stop_flag IS NULL

       OR synthetic_risk_clean_approval_band_flag IS NULL
       OR synthetic_risk_counteroffer_band_flag IS NULL
       OR synthetic_risk_review_band_flag IS NULL
       OR synthetic_risk_decline_trigger_flag IS NULL

       OR requested_pti_clean_band_flag IS NULL
       OR requested_pti_counteroffer_candidate_flag IS NULL
       OR requested_pti_review_trigger_flag IS NULL
       OR requested_pti_decline_trigger_flag IS NULL

       OR dti_clean_band_flag IS NULL
       OR dti_review_trigger_flag IS NULL
       OR dti_decline_trigger_flag IS NULL

       OR requested_el_clean_band_flag IS NULL
       OR requested_el_counteroffer_candidate_flag IS NULL
       OR requested_el_review_trigger_flag IS NULL
       OR requested_el_decline_trigger_flag IS NULL

       OR requested_exposure_below_product_minimum_flag IS NULL
       OR requested_exposure_within_product_limit_flag IS NULL
       OR requested_exposure_above_product_cap_flag IS NULL
       OR requested_exposure_extreme_flag IS NULL
       OR exposure_counteroffer_candidate_flag IS NULL
       OR exposure_policy_stop_candidate_flag IS NULL

       OR counteroffer_allowed_by_product_flag IS NULL
       OR counteroffer_risk_band_eligible_flag IS NULL
       OR counteroffer_affordability_candidate_flag IS NULL
       OR counteroffer_exposure_candidate_flag IS NULL
       OR counteroffer_expected_loss_candidate_flag IS NULL
       OR counteroffer_candidate_flag IS NULL

       OR manual_review_allowed_by_product_flag IS NULL
       OR manual_review_risk_trigger_flag IS NULL
       OR manual_review_affordability_trigger_flag IS NULL
       OR manual_review_dti_trigger_flag IS NULL
       OR manual_review_expected_loss_trigger_flag IS NULL
       OR manual_review_mixed_signal_trigger_flag IS NULL
       OR manual_review_borderline_trigger_flag IS NULL
       OR manual_review_candidate_flag IS NULL

       OR high_utilization_review_trigger_flag IS NULL
       OR low_score_review_trigger_flag IS NULL
       OR supplemental_behavioral_review_trigger_flag IS NULL

       OR clean_approval_candidate_flag IS NULL;

    IF v_null_flag_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have null rule-trigger flags.',
            v_null_flag_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: rule count fields must be non-null.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_null_count_field_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE hard_policy_stop_count IS NULL
       OR synthetic_risk_trigger_count IS NULL
       OR affordability_trigger_count IS NULL
       OR dti_trigger_count IS NULL
       OR requested_el_trigger_count IS NULL
       OR exposure_trigger_count IS NULL
       OR counteroffer_candidate_trigger_count IS NULL
       OR manual_review_candidate_trigger_count IS NULL
       OR supplemental_behavioral_review_trigger_count IS NULL
       OR synthetic_risk_band_flag_count IS NULL
       OR dti_band_flag_count IS NULL
       OR total_rule_trigger_count IS NULL;

    IF v_null_count_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have null rule-trigger count fields.',
            v_null_count_field_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: rule count fields must be non-negative.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_negative_count_field_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE hard_policy_stop_count < 0
       OR synthetic_risk_trigger_count < 0
       OR affordability_trigger_count < 0
       OR dti_trigger_count < 0
       OR requested_el_trigger_count < 0
       OR exposure_trigger_count < 0
       OR counteroffer_candidate_trigger_count < 0
       OR manual_review_candidate_trigger_count < 0
       OR supplemental_behavioral_review_trigger_count < 0
       OR synthetic_risk_band_flag_count < 0
       OR dti_band_flag_count < 0
       OR total_rule_trigger_count < 0;

    IF v_negative_count_field_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have negative rule-trigger count fields.',
            v_negative_count_field_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: synthetic estimated-risk band coverage.

    The synthetic estimated-risk flags form a true banding family. Every row must occupy exactly
    one synthetic estimated-risk band.

    This does not prevent synthetic-risk triggers from overlapping with affordability, exposure,
    DTI, hard simulated policy stop, counteroffer, or manual-review candidate triggers.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_band_coverage_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE synthetic_risk_band_flag_count <> 1;

    IF v_synthetic_risk_band_coverage_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) do not occupy exactly one synthetic estimated-risk band.',
            v_synthetic_risk_band_coverage_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: DTI band coverage.

    DTI is also a true capacity banding family. Every row must occupy exactly one DTI band.

    This does not prevent DTI pressure from coexisting with requested PTI pressure, requested
    Expected Loss pressure, exposure pressure, mixed-signal diagnostics, or other trigger families.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_dti_band_coverage_violation_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE dti_band_flag_count <> 1;

    IF v_dti_band_coverage_violation_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) do not occupy exactly one DTI capacity band.',
            v_dti_band_coverage_violation_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: clean approval candidate flag cannot coexist with material trigger families.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_clean_conflict_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE clean_approval_candidate_flag IS TRUE
      AND (
            hard_policy_stop_flag IS TRUE
         OR synthetic_risk_decline_trigger_flag IS TRUE
         OR requested_pti_decline_trigger_flag IS TRUE
         OR dti_decline_trigger_flag IS TRUE
         OR requested_el_decline_trigger_flag IS TRUE
         OR requested_exposure_extreme_flag IS TRUE
         OR counteroffer_candidate_flag IS TRUE
         OR manual_review_candidate_flag IS TRUE
      );

    IF v_clean_conflict_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have clean_approval_candidate_flag conflicting with material triggers.',
            v_clean_conflict_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: counteroffer_candidate_flag cannot be TRUE when product disallows counteroffer.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_counteroffer_not_allowed_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE counteroffer_allowed_by_product_flag IS FALSE
      AND counteroffer_candidate_flag IS TRUE;

    IF v_counteroffer_not_allowed_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have counteroffer_candidate_flag TRUE while counteroffer is not allowed by product.',
            v_counteroffer_not_allowed_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: manual_review_candidate_flag cannot be TRUE when product disallows manual review.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_manual_review_not_allowed_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE manual_review_allowed_by_product_flag IS FALSE
      AND manual_review_candidate_flag IS TRUE;

    IF v_manual_review_not_allowed_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have manual_review_candidate_flag TRUE while manual review is not allowed by product.',
            v_manual_review_not_allowed_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: decline trigger flags must align to threshold equality conventions.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_synthetic_risk_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE estimated_pd >= decline_min_estimated_pd_proxy
      AND synthetic_risk_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_synthetic_risk_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have estimated_pd >= decline_min_estimated_pd_proxy but synthetic_risk_decline_trigger_flag is not TRUE.',
            v_synthetic_risk_decline_mismatch_count;
    END IF;

    SELECT COUNT(*)
    INTO v_requested_pti_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE requested_payment_to_income_ratio >= product_decline_min_pti
      AND requested_pti_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_requested_pti_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have requested PTI >= product_decline_min_pti but requested_pti_decline_trigger_flag is not TRUE.',
            v_requested_pti_decline_mismatch_count;
    END IF;

    SELECT COUNT(*)
    INTO v_dti_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE debt_to_income_ratio >= decline_min_dti
      AND dti_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_dti_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have DTI >= decline_min_dti but dti_decline_trigger_flag is not TRUE.',
            v_dti_decline_mismatch_count;
    END IF;

    SELECT COUNT(*)
    INTO v_requested_el_decline_mismatch_count
    FROM tmp_m2_stage_3_rule_flags
    WHERE requested_expected_loss_amount >= product_decline_min_requested_el
      AND requested_el_decline_trigger_flag IS DISTINCT FROM TRUE;

    IF v_requested_el_decline_mismatch_count > 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 6 failure: % row(s) have requested_expected_loss_amount >= product_decline_min_requested_el but requested_el_decline_trigger_flag is not TRUE.',
            v_requested_el_decline_mismatch_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 6 must not create final decision, reason-code, or approved-exposure fields.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_forbidden_column_count
    FROM pg_attribute
    WHERE attrelid = 'tmp_m2_stage_3_rule_flags'::REGCLASS
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
            'Module 2 Section 6 failure: forbidden final decision, reason-code, or approved-exposure field(s) were created in rule flag stage.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 6.4 — LOCAL RULE-FLAG SANITY CHECKS
****************************************************************************************************

PURPOSE:
    Provide lightweight diagnostics for the Section 6 rule-trigger layer.

These are staging diagnostics only.
They should not be interpreted as final decision validation.

****************************************************************************************************/


/*-----------------------------------------------------------------------------------------------
6.4.1 Count by hard_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    hard_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY hard_policy_stop_flag
ORDER BY hard_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.2 Count by bankruptcy_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    bankruptcy_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY bankruptcy_policy_stop_flag
ORDER BY bankruptcy_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.3 Count by major_derogatory_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    major_derogatory_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY major_derogatory_policy_stop_flag
ORDER BY major_derogatory_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.4 Count by severe_delinquency_policy_stop_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    severe_delinquency_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY severe_delinquency_policy_stop_flag
ORDER BY severe_delinquency_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.5 Count by synthetic_risk_decline_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    synthetic_risk_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY synthetic_risk_decline_trigger_flag
ORDER BY synthetic_risk_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.6 Count by requested_pti_decline_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_pti_decline_trigger_flag
ORDER BY requested_pti_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.7 Count by dti_decline_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    dti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(debt_to_income_ratio) AS avg_debt_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY dti_decline_trigger_flag
ORDER BY dti_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.8 Count by requested_el_decline_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_el_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_el_decline_trigger_flag
ORDER BY requested_el_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.9 Count by requested_exposure_above_product_cap_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_above_product_cap_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_exposure_above_product_cap_flag
ORDER BY requested_exposure_above_product_cap_flag;


/*-----------------------------------------------------------------------------------------------
6.4.10 Count by requested_exposure_extreme_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_exposure_extreme_flag,
    COUNT(*) AS row_count,
    AVG(requested_amount) AS avg_requested_amount
FROM tmp_m2_stage_3_rule_flags
GROUP BY requested_exposure_extreme_flag
ORDER BY requested_exposure_extreme_flag;


/*-----------------------------------------------------------------------------------------------
6.4.11 Count by exposure_counteroffer_candidate_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    exposure_counteroffer_candidate_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY exposure_counteroffer_candidate_flag
ORDER BY exposure_counteroffer_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.12 Count by counteroffer_candidate_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(counteroffer_candidate_trigger_count) AS avg_counteroffer_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY counteroffer_candidate_flag
ORDER BY counteroffer_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.13 Count by manual_review_candidate_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(manual_review_candidate_trigger_count) AS avg_manual_review_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY manual_review_candidate_flag
ORDER BY manual_review_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.14 Count by high_utilization_review_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    high_utilization_review_trigger_flag,
    COUNT(*) AS row_count,
    AVG(utilization_rate) AS avg_utilization_rate
FROM tmp_m2_stage_3_rule_flags
GROUP BY high_utilization_review_trigger_flag
ORDER BY high_utilization_review_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.15 Count by low_score_review_trigger_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    low_score_review_trigger_flag,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score
FROM tmp_m2_stage_3_rule_flags
GROUP BY low_score_review_trigger_flag
ORDER BY low_score_review_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.16 Count by clean_approval_candidate_flag.
-----------------------------------------------------------------------------------------------*/
SELECT
    clean_approval_candidate_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY clean_approval_candidate_flag
ORDER BY clean_approval_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.17 Product × hard_policy_stop_flag summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    hard_policy_stop_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    product_type_policy_key,
    hard_policy_stop_flag
ORDER BY
    product_type_policy_key,
    hard_policy_stop_flag;


/*-----------------------------------------------------------------------------------------------
6.4.18 Product × counteroffer_candidate_flag summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    product_type_policy_key,
    counteroffer_candidate_flag,
    COUNT(*) AS row_count,
    AVG(counteroffer_candidate_trigger_count) AS avg_counteroffer_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    product_type_policy_key,
    counteroffer_candidate_flag
ORDER BY
    product_type_policy_key,
    counteroffer_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.19 Score band × synthetic risk trigger summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    score_band_policy_key,
    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    score_band_policy_key,
    synthetic_risk_clean_approval_band_flag,
    synthetic_risk_counteroffer_band_flag,
    synthetic_risk_review_band_flag,
    synthetic_risk_decline_trigger_flag
ORDER BY
    CASE score_band_policy_key
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 99
    END,
    synthetic_risk_decline_trigger_flag;


/*-----------------------------------------------------------------------------------------------
6.4.20 Requested PTI bucket × affordability trigger summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    requested_pti_bucket,
    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag,
    COUNT(*) AS row_count,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    requested_pti_bucket,
    requested_pti_counteroffer_candidate_flag,
    requested_pti_review_trigger_flag,
    requested_pti_decline_trigger_flag
ORDER BY
    CASE requested_pti_bucket
        WHEN 'LOW_REQUESTED_PTI' THEN 1
        WHEN 'MODERATE_REQUESTED_PTI' THEN 2
        WHEN 'ELEVATED_REQUESTED_PTI' THEN 3
        WHEN 'HIGH_REQUESTED_PTI' THEN 4
        WHEN 'SEVERE_REQUESTED_PTI' THEN 5
        ELSE 99
    END;


/*-----------------------------------------------------------------------------------------------
6.4.21 Mixed-signal profile × manual review candidate summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    mixed_signal_profile_type,
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(manual_review_candidate_trigger_count) AS avg_manual_review_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    mixed_signal_profile_type,
    manual_review_candidate_flag
ORDER BY
    CASE mixed_signal_profile_type
        WHEN 'NO_MIXED_SIGNAL_PROFILE' THEN 1
        WHEN 'STRONG_CREDIT_HIGH_PTI' THEN 2
        WHEN 'WEAK_CREDIT_LOW_PTI' THEN 3
        WHEN 'LARGE_EXPOSURE_LOW_RISK' THEN 4
        WHEN 'HIGH_RISK_LOW_EXPOSURE' THEN 5
        WHEN 'HIGH_DTI_LOW_REQUESTED_PTI' THEN 6
        WHEN 'MULTIPLE_MIXED_SIGNALS' THEN 7
        ELSE 99
    END,
    manual_review_candidate_flag;


/*-----------------------------------------------------------------------------------------------
6.4.22 Borderline profile × manual review candidate summary.
-----------------------------------------------------------------------------------------------*/
SELECT
    borderline_profile_flag,
    manual_review_candidate_flag,
    COUNT(*) AS row_count,
    AVG(manual_review_candidate_trigger_count) AS avg_manual_review_candidate_trigger_count
FROM tmp_m2_stage_3_rule_flags
GROUP BY
    borderline_profile_flag,
    manual_review_candidate_flag
ORDER BY
    borderline_profile_flag,
    manual_review_candidate_flag;


/***************************************************************************************************
END OF SECTION 6 — RULE FLAG CONSTRUCTION LAYER

If execution reaches this point:
    1. tmp_m2_stage_3_rule_flags exists.
    2. Row count is unchanged from tmp_m2_stage_2_strategy_segments.
    3. application_id remains unique.
    4. Hard simulated policy stop flags are populated.
    5. Synthetic estimated-risk flags are populated and exactly one risk band is active per row.
    6. Requested PTI flags are populated.
    7. DTI flags are populated and exactly one DTI band is active per row.
    8. Requested Expected Loss flags are populated.
    9. Requested exposure flags are populated.
    10. Counteroffer candidate flags are populated.
    11. Manual review candidate flags are populated.
    12. Supplemental behavioral review flags are populated.
    13. clean_approval_candidate_flag is populated as a diagnostic.
    14. Rule count fields are populated, numeric, non-null, and non-negative.

No final decision_outcome has been created.
No final decision_path has been created.
No final approval / decline / manual review / counteroffer flags have been created.
No simulated_offer_exposure_flag has been created.
No simulated reason codes have been assigned.
No approved_amount has been calculated.
No counteroffer_amount has been calculated.
No approved payment proxy has been calculated.
No approved payment-to-income ratio has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No strategy archive rows have been inserted.

***************************************************************************************************/

-- <<< MODULE 2 FULL SQL CODE CAPTURE — PART 3 OF 7 END
```

Ready for next part: say CONTINUE FULL CODE PART 4
<!-- END_MESSAGE C038-M00190 -->


---

<a id="c038-m00191"></a>

### C038-M00191

**Andrew** · 2026-05-06T17:19:15.607000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00191 -->
CONTINUE FULL CODE PART 4
<!-- END_MESSAGE C038-M00191 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_08.md) · [Next](Part_10.md)
