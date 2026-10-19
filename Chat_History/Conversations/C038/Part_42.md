# Module 2 Decision Simulator Build

## Part 42

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_41.md) · [Next](Part_43.md)

<a id="c038-m00907"></a>

### C038-M00907

**ChatGPT** · 2026-05-09T23:23:22.961759-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00907 -->
I recommend replacing Section 4 with the version below. I preserved the functional logic from your current Section 4, strengthened the instructional commentary, and added two small governance hardening checks: Section 4 now explicitly requires the Section 3 source-scope helper and campaign-registry match helper to exist, and Section 4.3 now confirms the staged source agrees with the Section 3 source-selection scope. I used your current Section 4 as the base. fileciteturn82file0

```sql
/***************************************************************************************************
SECTION 4 — MODULE 1 SOURCE SELECTION AND LINEAGE NORMALIZATION
****************************************************************************************************

BUSINESS PURPOSE:
    Safely consume finalized Module 1 outputs and create the clean Module 2 input foundation.

    Section 4 answers:

        "Which Module 1 synthetic applicant population is the current Module 2 strategy run using,
         and has that source been normalized into a stable Module 2 staging shape?"

    This section is the formal Module 1 → Module 2 handoff layer.

    It converts the selected Module 1 latest-run or archive source into a governed Module 2 staging
    table with one row per synthetic application.

SQL PURPOSE:
    1. Read the active Module 2 strategy source-selection settings.
    2. Confirm Section 3 source-scope and registry-match helpers exist.
    3. Select the correct Module 1 input source:
            credit_decisioning_sim.synthetic_applications
        or:
            credit_decisioning_sim.synthetic_applications_scenario_archive
    4. Detect whether the selected source uses raw scenario fields or already-normalized Module 1
       lineage fields.
    5. Normalize upstream Module 1 scenario lineage into Module 2 naming:
            module1_scenario_set_name
            module1_scenario_name
            population_id
    6. Preserve application-level identifiers.
    7. Preserve borrower, product, affordability, requested-structure, and risk-economics fields.
    8. Preserve Module 2 strategy metadata in the staged input.
    9. Alias requested-exposure economics clearly for Module 2:
            requested_monthly_payment_proxy
            requested_payment_to_income_ratio
            requested_expected_loss_amount
    10. Create product_type_policy_key for later product-policy joins.
    11. Validate that every source row maps to exactly one product policy configuration.
    12. Confirm the staged source agrees with the Section 3 source-selection scope.
    13. Confirm that Section 4 does not create decision, reason-code, or approved-exposure fields.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that the selected Module 1 scenario / population is the intended upstream population
        for the current Module 2 strategy.

    Model governance / validation reviewers:
        Confirm that Module 1 lineage is preserved and not overwritten by Module 2 strategy metadata.

    SQL reviewers:
        Confirm that dynamic SQL is used only to handle source-table and column-name variability,
        while the staged output schema remains fixed and governed.

    Portfolio / executive reviewers:
        Confirm that the run is traceable to the correct Module 1 scenario and Module 2 strategy
        before downstream outcomes are interpreted.

WHEN TO RUN THIS SECTION:
    Run Section 4 after:
        Section 2 parameter setup,
        and Section 3 fail-fast strategy / source / product-policy / registry gatekeepers.

    Section 4 should be run before:
        Section 5 segmentation,
        Section 6 rule flags,
        Section 7 preliminary routing,
        Section 8 exposure treatment,
        Section 9 final decision resolution,
        Section 10 reason-code assignment,
        Section 11 latest-run output,
        and all later archive / comparison / QA / evidence sections.

HOW TO INTERPRET THIS SECTION:
    Passing Section 4 means:
        the selected Module 1 source was staged successfully,
        the staged rows are unique at application_id,
        the staged rows represent exactly one Module 1 scenario / population slice,
        product types were normalized to Module 2 policy keys,
        product policy configuration is available,
        requested-structure aliases were created,
        and no decision / approved-exposure / reason-code fields were created too early.

    Passing Section 4 does not mean:
        the strategy has produced outcomes,
        rule flags are valid,
        counteroffer feasibility has been tested,
        final decisions are valid,
        reason codes are complete,
        archive persistence worked,
        or validation has passed.

    Those conclusions are addressed in later sections.

INPUTS:
    tmp_module2_strategy_params
        Active Module 2 strategy parameter card.

    tmp_module2_product_policy_params
        Product-specific strategy and exposure policy parameter card.

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

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

WHY MODULE 2 CONSUMES MODULE 1 RATHER THAN REWRITING MODULE 1:
    Module 1 is finalized, validated, and authoritative for synthetic applicant generation, product
    structure, affordability proxy, estimated-PD proxy, LGD, and requested-exposure Expected Loss.

    Module 2 consumes Module 1 outputs as the synthetic applicant and risk foundation.

    Module 2 does not:
        redesign the synthetic population,
        recalculate estimated_pd,
        reinterpret Module 1 scenario outputs as forecasts,
        replace Module 1 scenario lineage,
        or mutate Module 1 outputs.

CREDIT RISK CONCEPT TAUGHT HERE:
    Credit risk strategy depends on knowing whether observed movement comes from:
        upstream population / scenario changes,
        or downstream strategy changes.

    Module 1 controls the upstream scenario environment.

    Module 2 controls the downstream simulated strategy applied to that environment.

    Section 4 protects that separation.

WHY LATEST-RUN AND ARCHIVE INPUTS ARE BOTH SUPPORTED:
    LATEST input supports:
        single-strategy development,
        smoke testing,
        and immediate QA against the current Module 1 latest-run table.

    ARCHIVE input supports:
        controlled strategy comparison across completed Module 1 scenario slices,
        formal campaign runs,
        and matched analysis where the same Module 1 scenario / population is reused across multiple
        Module 2 strategies.

    For formal scenario / strategy campaigns, ARCHIVE input is preferred because it preserves the
    exact upstream scenario slice used for matched comparison.

WHY MODULE 1 SCENARIO LINEAGE MUST BE PRESERVED:
    Module 1 scenario fields describe the upstream synthetic population and risk environment.

    Module 2 strategy fields describe the downstream simulated strategy applied to that population.

    These concepts must not be overloaded.

    The same Module 2 strategy may be applied to many Module 1 scenarios.
    The same Module 1 scenario may be evaluated under many Module 2 strategies.

WHY CAMPAIGN IDS ARE NOT ADDED TO THIS APPLICANT-GRAIN STAGE:
    Campaign IDs such as module1_run_id, module2_run_id, showcase_id, comparison_group_id, and
    validation_evidence_group_id are evidence-linkage metadata.

    They help connect SQL outputs to the run roadmap and Validation Summary.

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

    Module 2 product policy parameters use normalized product keys:
        MORTGAGE
        HELOC
        AUTO_LOAN
        UNSECURED_PERSONAL_LOAN
        REVOLVING_LINE

    Section 4 preserves the original product_type and derives product_type_policy_key for later
    strategy joins.

    Module 1 is not modified.

WHY PRODUCT POLICY VALIDATION HAPPENS BEFORE POLICY RULES:
    Downstream strategy rules are product-aware.

    A missing product policy configuration would make decision logic ambiguous.

    Section 4 therefore fails before strategy segmentation, rule flags, preliminary routing, exposure
    treatment, or final decisions are created.

WHY REQUESTED-STRUCTURE ALIASES ARE CREATED:
    Module 1 monthly_payment_proxy and payment_to_income_ratio describe the original requested
    structure.

    Module 2 later calculates approved_monthly_payment_proxy and approved_payment_to_income_ratio
    after exposure treatment.

    Creating requested_* aliases now prevents ambiguity:

        monthly_payment_proxy
            original Module 1 field

        requested_monthly_payment_proxy
            Module 2 alias confirming this is requested-structure payment

        approved_monthly_payment_proxy
            calculated later only after exposure treatment

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
        approved payment
        approved PTI
        approved Expected Loss

WHY PRODUCT-POLICY JOIN IN SECTION 4 IS VALIDATION-ONLY:
    Section 4 confirms product policy configuration availability.

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

    `%I` in FORMAT:
        Safely quotes SQL identifiers, such as schema names, table names, and column names.

    `%L` in FORMAT:
        Safely quotes SQL literal values, such as the source table name stored in the staged output.

    CROSS JOIN active_strategy_params:
        Attaches the single active strategy card to every selected source row.

    CASE normalization:
        Converts display-style product labels into governed Module 2 product policy keys.

    LEFT JOIN product_policy_match:
        Validates product policy availability without applying product policy rules yet.

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
        Module 2 strategy metadata,
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

WHY DYNAMIC SQL IS USED:
    Dynamic SQL is used only because the selected source table and scenario column names can vary.

    The output schema is fixed and governed.

    Module 1 source tables may use:
        scenario_set_name / scenario_name

    or:
        module1_scenario_set_name / module1_scenario_name

    Section 4 detects the available source columns and normalizes them into stable Module 2 output
    names.

DYNAMIC SQL BOUNDARY:
    Dynamic SQL does not make the output schema flexible.

    The output schema remains fixed.

    Dynamic SQL only makes source-table and source-column selection flexible enough to support both
    Module 1 latest-run and Module 1 archive sources.

***************************************************************************************************/

DO $$
DECLARE
    /***********************************************************************************************
    Active strategy parameter row.

    Section 3 already validated that exactly one active strategy row exists.
    ***********************************************************************************************/
    p RECORD;

    /***********************************************************************************************
    Source table selected from the active strategy parameter card.

    These variables determine whether the source is Module 1 latest-run output or Module 1 scenario
    archive output.
    ***********************************************************************************************/
    v_source_table_schema TEXT;
    v_source_table_name TEXT;

    /***********************************************************************************************
    Runtime scenario column names.

    Module 1 latest-run and archive outputs may use either raw scenario fields or normalized
    module1_* lineage fields.
    ***********************************************************************************************/
    v_scenario_set_col TEXT;
    v_scenario_name_col TEXT;

    /***********************************************************************************************
    Optional / normalized source field expressions.

    These strings become fragments inside the dynamic CREATE TABLE AS SELECT statement.

    If a required field is absent, the expression becomes NULL and Section 4.3 fails clearly rather
    than silently inventing data.
    ***********************************************************************************************/
    v_module1_model_version_expr TEXT;
    v_anchor_date_expr TEXT;
    v_application_seq_expr TEXT;
    v_application_date_expr TEXT;
    v_loan_term_months_expr TEXT;
    v_base_apr_expr TEXT;
    v_prequalified_flag_expr TEXT;
    v_returning_customer_flag_expr TEXT;

    /***********************************************************************************************
    Dynamic SQL text for the source-stage table creation.
    ***********************************************************************************************/
    v_create_sql TEXT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 3 source-scope helper must exist.

    Business purpose:
        Section 4 should follow Section 3.

        The source-scope helper proves that source selection was validated before source staging.

    SQL mechanics:
        TO_REGCLASS returns NULL when the object does not exist.
        pg_temp is checked because this helper is a temporary table.
    -------------------------------------------------------------------------------------------*/
    IF COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_source_selection_scope'),
        TO_REGCLASS('tmp_m2_source_selection_scope')
    ) IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_source_selection_scope is required. Run Section 3 before Section 4.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 3 campaign registry match helper must exist.

    Business purpose:
        Section 4 does not store campaign IDs at applicant grain, but the registry match should be
        available for review and later Section 16 evidence capture.

    SQL mechanics:
        This protects 4.4.3A from failing late with an undefined table error.
    -------------------------------------------------------------------------------------------*/
    IF COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_campaign_registry_current_run_match'),
        TO_REGCLASS('tmp_m2_campaign_registry_current_run_match')
    ) IS NULL THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_campaign_registry_current_run_match is required. Run Section 3 before Section 4.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Load the active strategy row.

    SQL mechanics:
        SELECT * INTO p stores the row in a PL/pgSQL record variable.

    Why LIMIT 1 is safe:
        Section 3 already validated exactly one active strategy row.
    -------------------------------------------------------------------------------------------*/
    SELECT *
    INTO p
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1;


    /*-------------------------------------------------------------------------------------------
    Resolve the selected Module 1 source table.

    LATEST:
        read credit_decisioning_sim.synthetic_applications.

    ARCHIVE:
        read credit_decisioning_sim.synthetic_applications_scenario_archive.

    Credit risk interpretation:
        The selected source determines the upstream scenario environment before any Module 2 strategy
        logic is applied.
    -------------------------------------------------------------------------------------------*/
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
    Identify Module 1 scenario-set column.

    Module 1 latest-run outputs may use:
        scenario_set_name

    Archive or downstream-normalized outputs may use:
        module1_scenario_set_name

    Section 4 normalizes both forms into:
        module1_scenario_set_name

    SQL mechanics:
        information_schema.columns inspects available columns in the selected source table.

        The detected column name is stored in v_scenario_set_col and later injected into dynamic SQL
        as a safely quoted identifier through FORMAT('%I', ...).
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


    /*-------------------------------------------------------------------------------------------
    Identify Module 1 scenario-name column.

    Module 1 latest-run outputs may use:
        scenario_name

    Archive or downstream-normalized outputs may use:
        module1_scenario_name

    Section 4 normalizes both forms into:
        module1_scenario_name
    -------------------------------------------------------------------------------------------*/
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
    Resolve module1_model_version expression.

    Business purpose:
        Preserve upstream Module 1 engine version in the staged source.

    SQL mechanics:
        If module1_model_version exists, use it.
        Else if model_version exists, use that.
        Else stage NULL and allow Section 4.3 to fail because Module 1 version is required.

    Why not invent a version:
        Section 4 is a staging layer. It should preserve source evidence, not create missing source
        metadata.
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


    /*-------------------------------------------------------------------------------------------
    Resolve anchor_date expression.

    Business purpose:
        Preserve the Module 1 run / scenario anchor date.

    SQL mechanics:
        If anchor_date exists, cast it to DATE.
        Else stage NULL and allow Section 4.3 to fail.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Resolve application_seq expression.

    Business purpose:
        Preserve the Module 1 application sequence when available.

    SQL mechanics:
        If application_seq exists, cast it to BIGINT.
        Else stage NULL and allow Section 4.3 to fail because application sequence is treated as a
        required source lineage field in this Module 2 implementation.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Resolve application_date expression.

    Business purpose:
        Preserve the Module 1 synthetic application date.

    SQL mechanics:
        If application_date exists, cast it to DATE.
        Else stage NULL and allow Section 4.3 to fail.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Resolve loan_term_months expression.

    Business purpose:
        Preserve the product term where Module 1 supplies a term.

    Credit risk interpretation:
        Loan term affects payment burden for amortizing products.

        Revolving products may not have a fixed amortizing term. Section 4.3 therefore allows
        loan_term_months to be NULL for REVOLVING_LINE only.

    SQL mechanics:
        If the source column exists, cast to INTEGER.
        Else stage NULL and allow product-aware validation to determine whether the NULL is acceptable.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Resolve APR proxy expression.

    Business purpose:
        Preserve the Module 1 APR proxy used in payment calculation.

    Credit risk interpretation:
        APR proxy supports the structure-to-affordability path:
            APR → payment → PTI → synthetic estimated-risk proxy → Expected Loss.

    SQL mechanics:
        Module 1 versions may expose the field as:
            base_apr_for_payment_calc
        or:
            base_apr_for_payment_calculation

        Section 4 normalizes both into:
            base_apr_for_payment_calc
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Resolve prequalified_flag expression.

    Business purpose:
        Preserve optional relationship / context information when available.

    Boundary:
        This field remains nullable because not every Module 1 output version must surface it.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Resolve returning_customer_flag expression.

    Business purpose:
        Preserve optional relationship / context information when available.

    Boundary:
        This field remains nullable because not every Module 1 output version must surface it.
    -------------------------------------------------------------------------------------------*/
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

    Business purpose:
        Materialize the selected Module 1 source slice into the canonical Module 2 source-stage
        shape.

    SQL purpose:
        Create tmp_m2_stage_1_source_applications.

    How the SQL works:
        1. active_strategy_params selects the one active strategy card.
        2. source_rows selects applicant-grain Module 1 rows and CROSS JOINs the strategy card.
        3. WHERE logic keeps all rows for LATEST mode, or filters to the selected scenario slice for
           ARCHIVE mode.
        4. product_type_policy_key normalizes Module 1 product labels.
        5. product_policy_match counts product-policy rows by product key.
        6. The final SELECT attaches product-policy match diagnostics.

    Credit risk interpretation:
        This creates the applicant-level foundation used by the rest of Module 2.

        It is not a decisioning section.
        It does not route, approve, decline, or assign reason codes.
    -------------------------------------------------------------------------------------------*/
    v_create_sql := FORMAT($sql$
        CREATE TEMP TABLE tmp_m2_stage_1_source_applications
        ON COMMIT PRESERVE ROWS
        AS
        WITH active_strategy_params AS (
            /***************************************************************************************
            CTE: active_strategy_params

            Purpose:
                Select the single active Module 2 strategy card.

            Why CROSS JOIN later:
                Every selected Module 1 source row should carry the same active Module 2 strategy
                metadata.
            ***************************************************************************************/
            SELECT *
            FROM tmp_module2_strategy_params
            WHERE active_strategy_flag IS TRUE
            LIMIT 1
        ),

        source_rows AS (
            /***************************************************************************************
            CTE: source_rows

            Purpose:
                Select the effective Module 1 source rows and normalize them into the Module 2
                source-stage schema.

            Grain:
                One row per application_id after Section 3 / Section 4 source checks.

            Important:
                This CTE preserves source facts. It does not create strategy outcomes.
            ***************************************************************************************/
            SELECT
                /***********************************************************************************
                Module 2 strategy metadata.

                These fields are carried from the beginning so every downstream stage preserves both
                upstream Module 1 lineage and downstream Module 2 strategy lineage.

                strategy_run_id and strategy_run_ts are audit metadata.

                They do not replace:
                    archive replacement key,
                    matched comparison key,
                    campaign registry key,
                    or application-level grain.
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

                Section 4 normalizes source column names into these stable Module 2 lineage fields.
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

                These fields identify the synthetic application and applicant generated upstream by
                Module 1.
                ***********************************************************************************/
                %s AS application_seq,
                src.application_id::TEXT AS application_id,
                src.applicant_id::TEXT AS applicant_id,
                %s AS application_date,

                /***********************************************************************************
                Product and score fields.

                product_type:
                    original Module 1 value.

                product_type_policy_key:
                    normalized Module 2 policy join key.

                Why normalize:
                    Module 1 may use display-style or alternate product naming.
                    Module 2 product policy rows use governed product keys.
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
                Borrower / behavioral profile.

                These fields are source features from Module 1.

                Section 4 preserves them so Section 5 and Section 6 can build strategy segmentation
                and rule-trigger diagnostics.
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

                These fields describe the original requested application structure before Module 2
                exposure treatment exists.
                ***********************************************************************************/
                src.requested_amount::NUMERIC AS requested_amount,
                %s AS loan_term_months,
                %s AS base_apr_for_payment_calc,
                src.monthly_payment_proxy::NUMERIC AS monthly_payment_proxy,
                src.payment_to_income_ratio::NUMERIC AS payment_to_income_ratio,
                src.amount_to_income_ratio::NUMERIC AS amount_to_income_ratio,

                /***********************************************************************************
                Module 2 requested-structure aliases.

                These aliases clarify that the values are based on the original requested structure.

                Later sections will create approved_* fields only after exposure treatment.
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

                requested_expected_loss_amount is the preferred Module 2 alias for downstream logic.
                ***********************************************************************************/
                src.estimated_pd::NUMERIC AS estimated_pd,
                src.estimated_lgd::NUMERIC AS estimated_lgd,
                src.expected_loss_amount::NUMERIC AS expected_loss_amount

            FROM %I.%I src

            /***************************************************************************************
            CROSS JOIN active_strategy_params:
                There is one active strategy row.
                CROSS JOIN attaches that strategy metadata to every selected Module 1 source row.
            ***************************************************************************************/
            CROSS JOIN active_strategy_params p

            /***************************************************************************************
            Source filter logic.

            LATEST:
                p.module1_input_source = 'LATEST'
                The entire latest-run Module 1 table is consumed after Section 3 confirms it contains
                one scenario / population slice.

            ARCHIVE:
                p.module1_input_source = 'ARCHIVE'
                Only the selected Module 1 scenario set, scenario name, and population_id are
                consumed.
            ***************************************************************************************/
            WHERE p.module1_input_source = 'LATEST'
               OR (
                    p.module1_input_source = 'ARCHIVE'
                AND %s = p.source_module1_scenario_set_name
                AND %s = p.source_module1_scenario_name
                AND src.population_id::TEXT = p.source_population_id
               )
        ),

        product_policy_match AS (
            /***************************************************************************************
            CTE: product_policy_match

            Purpose:
                Count product policy rows by product type.

            Why:
                Section 4 validates product policy availability but does not apply product policy
                rules yet.
            ***************************************************************************************/
            SELECT
                product_type,
                COUNT(*) AS product_policy_match_count
            FROM tmp_module2_product_policy_params
            GROUP BY product_type
        )

        SELECT
            sr.*,

            /***************************************************************************************
            Product-policy match diagnostics.

            product_policy_match_count:
                How many product policy rows matched this normalized product key.

            product_policy_config_found_flag:
                TRUE only when exactly one matching policy row exists.

            These fields support Section 4.3 validation and Section 4.4 review.
            ***************************************************************************************/
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

    /*-------------------------------------------------------------------------------------------
    Execute the dynamic CREATE TEMP TABLE statement.

    SQL mechanics:
        EXECUTE runs the SQL text assembled above.

    Boundary:
        This creates only the Section 4 staging table.
        It does not create decisions, reason codes, approved exposure, latest-run output, archive
        rows, or evidence rows.
    -------------------------------------------------------------------------------------------*/
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
    1. Confirm the staged source table contains rows.
    2. Confirm application_id uniqueness.
    3. Confirm exactly one Module 1 scenario / population slice.
    4. Confirm staged source agrees with Section 3 source-selection scope.
    5. Confirm Module 2 strategy metadata is populated.
    6. Confirm required source and lineage fields are populated.
    7. Confirm every product_type normalizes to a supported product_type_policy_key.
    8. Confirm every staged product key maps to exactly one product policy row.
    9. Confirm Section 4 did not create decision, reason-code, or approved-exposure fields.

WHY THESE CHECKS EXIST:
    Once Section 5 begins, downstream stages assume that:
        the staged source contains one row per application_id,
        exactly one Module 1 scenario / population slice is present,
        Module 2 strategy metadata is populated,
        required Module 1 source fields are available,
        product types normalize to supported policy keys,
        product-policy configuration exists,
        and no decision or approved-exposure fields have been created too early.

CREDIT RISK CONCEPT:
    If source staging is wrong, all downstream strategy conclusions become unreliable.

    For example:
        duplicate applications inflate counts,
        mixed scenarios confound strategy interpretation,
        missing product policy rows break product-aware strategy logic,
        and premature decision fields violate the staged architecture.

SQL MECHANICS:
    This block uses PL/pgSQL because it needs multiple count diagnostics and fail-fast exceptions.

    COUNT(*) checks population sizes.
    COUNT(DISTINCT application_id) checks application-level uniqueness.
    COUNT(DISTINCT (...)) checks scenario / population scope.
    pg_attribute checks that forbidden downstream columns were not created too early.

BOUNDARY:
    These checks are local Section 4 gatekeepers only.

    They are not:
        final strategy QA,
        reason-code validation,
        approved-exposure validation,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        or full Module 2 validation.

***************************************************************************************************/

DO $$
DECLARE
    /***********************************************************************************************
    Row-grain diagnostics.
    ***********************************************************************************************/
    v_stage_row_count BIGINT;
    v_distinct_application_count BIGINT;
    v_duplicate_application_group_count BIGINT;

    /***********************************************************************************************
    Scope and source-selection diagnostics.
    ***********************************************************************************************/
    v_scenario_population_count BIGINT;
    v_source_scope_count BIGINT;
    v_source_scope_mismatch_count BIGINT;

    /***********************************************************************************************
    Required-field and product-policy diagnostics.
    ***********************************************************************************************/
    v_null_required_field_count BIGINT;
    v_unmapped_product_type_count BIGINT;
    v_missing_product_policy_count BIGINT;
    v_multiple_product_policy_count BIGINT;

    /***********************************************************************************************
    Strategy metadata and forbidden-field diagnostics.
    ***********************************************************************************************/
    v_strategy_metadata_null_count BIGINT;
    v_forbidden_column_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Gatekeeper: staged source table must contain rows.

    Business purpose:
        Downstream strategy logic cannot run against an empty applicant population.

    SQL mechanics:
        COUNT(*) returns total staged rows.
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

    Business purpose:
        Module 2 V1.0 expects one staged row per synthetic application for the selected Module 1
        source slice.

    Credit risk interpretation:
        Duplicate application_id rows would duplicate decisions, exposures, approved Expected Loss,
        and reason-code counts later.

    SQL mechanics:
        Compare COUNT(*) to COUNT(DISTINCT application_id).
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

    Business purpose:
        Module 2 V1.0 is a single-slice execution framework.

    Credit risk interpretation:
        Mixing Module 1 scenarios would combine upstream scenario effects with downstream strategy
        effects, weakening comparison discipline.

    SQL mechanics:
        COUNT(DISTINCT (...)) counts distinct scenario / population tuples.
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
    Gatekeeper: Section 3 source-scope helper must contain exactly one row.

    Business purpose:
        Section 4 should stage the same source scope Section 3 validated.

    SQL mechanics:
        Count rows in tmp_m2_source_selection_scope.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_source_scope_count
    FROM tmp_m2_source_selection_scope;

    IF v_source_scope_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 4 failure: tmp_m2_source_selection_scope should contain exactly one row, found %.',
            v_source_scope_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: staged source agrees with Section 3 source-selection scope.

    Business purpose:
        Prevent a user from changing active parameters or source context after Section 3 without
        rerunning Section 3.

    SQL mechanics:
        Compare the one-row source-scope helper against the one-row staged source summary.

        IS DISTINCT FROM is NULL-safe, although these fields should generally be non-null after prior
        checks.
    -------------------------------------------------------------------------------------------*/
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


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Module 2 strategy metadata must be present.

    Business purpose:
        Every downstream stage must remain traceable to the active Module 2 strategy.

    SQL mechanics:
        Count staged rows where required strategy fields are NULL or blank.
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

    Optional relationship fields intentionally excluded:
        prequalified_flag
        returning_customer_flag

    Product-specific term convention:
        loan_term_months is required for fixed-term / term-reference products, but it is not required
        for REVOLVING_LINE.

        Module 1 represents Revolving Line as a revolving exposure without a fixed amortizing term.

        A NULL loan_term_months value for REVOLVING_LINE is therefore expected source behavior, not a
        malformed source row.

        Do not impute a revolving term here. Section 4 preserves Module 1 outputs and normalizes
        lineage for Module 2; it does not rewrite Module 1 product mechanics.

    SQL mechanics:
        This query counts any row with a missing required source or lineage field.
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


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: every product_type must normalize into a supported product_type_policy_key.

    Business purpose:
        Product-aware strategy logic requires a supported product policy key.

    Credit risk interpretation:
        Product type shapes exposure, payment mechanics, LGD, affordability pressure, and
        counteroffer feasibility.

    SQL mechanics:
        Count staged rows whose normalized product key is NULL or outside the supported product set.
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

    Business purpose:
        Product-aware strategy logic requires a single, unambiguous product policy row.

    SQL mechanics:
        product_policy_match_count was created in Section 4.2 from tmp_module2_product_policy_params.
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

    Business purpose:
        Protect the staged architecture.

    Section boundary:
        Section 4 is source staging only.

        Decisions belong later.
        Approved exposure belongs later.
        Reason codes belong later.

    SQL mechanics:
        pg_attribute inspects the physical columns on the temp table.

        If any forbidden downstream field exists, Section 4 fails.
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

BUSINESS PURPOSE:
    Provide lightweight staging diagnostics for source selection and lineage normalization.

    Section 4.4 answers:

        "What did Section 4 stage, and does the staged source look ready for Section 5?"

SQL PURPOSE:
    Display review outputs for:
        row count,
        source-scope alignment,
        Module 1 lineage,
        Module 2 strategy metadata,
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
        product policy rows,
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

SQL mechanics:
    Reads the temporary helper created in Section 3.
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
4.4.3 Module 2 strategy metadata carried into source stage.

Purpose:
    Confirm the downstream Module 2 strategy identity applied to the staged source.

Expected:
    exactly one strategy identity for the staged run.

Interpretation:
    These fields identify the strategy that will be applied to the selected Module 1 population.
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

Expected for formal campaign runs:
    run_registry_match_status = RUN_REGISTRY_MATCHED
    registry_match_count = 1

SQL mechanics:
    Reads the one-row temporary registry match helper from Section 3.
-----------------------------------------------------------------------------------------------*/

SELECT
    campaign_registry_required_flag,
    registry_match_count,
    run_registry_match_status,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_run_id,
    module2_run_id,
    run_sequence_number,

    showcase_id,
    showcase_name,
    comparison_group_id,
    validation_evidence_group_id,

    readme_storyline_label,
    linkedin_post_sequence
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

Interpretation:
    Any nonzero value means a Module 1 product label cannot be joined to a Module 2 product policy
    row and downstream product-aware strategy logic would be ambiguous.
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
4.4.7 Product policy configuration match.

Purpose:
    Confirm every staged product key maps to exactly one product policy configuration.

Expected:
    product_policy_config_found_flag = TRUE for every staged row.
    product_policy_match_count = 1 for each product_type_policy_key.

Boundary:
    This confirms product policy availability only.

    It does not apply product policy rules yet.
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
    Confirm that requested_expected_loss_amount is a direct alias of Module 1 expected_loss_amount.

Expected:
    requested_expected_loss_amount = expected_loss_amount for every row.

Interpretation:
    expected_loss_amount is Module 1 requested-exposure Expected Loss.

    requested_expected_loss_amount is the preferred Module 2 alias for that same value.

Credit risk concept:
    Requested Expected Loss is based on original requested exposure.

    Approved Expected Loss is created later after Module 2 exposure treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE requested_expected_loss_amount IS DISTINCT FROM expected_loss_amount
    ) AS requested_expected_loss_alias_mismatch_rows,
    MIN(requested_expected_loss_amount) AS min_requested_expected_loss_amount,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount,
    MAX(requested_expected_loss_amount) AS max_requested_expected_loss_amount
FROM tmp_m2_stage_1_source_applications;



/*-----------------------------------------------------------------------------------------------
4.4.10 Requested monthly payment alias confirmation.

Purpose:
    Confirm that requested_monthly_payment_proxy is a direct alias of Module 1 monthly_payment_proxy.

Expected:
    requested_monthly_payment_proxy = monthly_payment_proxy for every row.

Interpretation:
    monthly_payment_proxy is the Module 1 requested-structure payment proxy.

    approved_monthly_payment_proxy is calculated later only after exposure treatment.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE requested_monthly_payment_proxy IS DISTINCT FROM monthly_payment_proxy
    ) AS requested_monthly_payment_alias_mismatch_rows,
    MIN(requested_monthly_payment_proxy) AS min_requested_monthly_payment_proxy,
    AVG(requested_monthly_payment_proxy) AS avg_requested_monthly_payment_proxy,
    MAX(requested_monthly_payment_proxy) AS max_requested_monthly_payment_proxy
FROM tmp_m2_stage_1_source_applications;



/*-----------------------------------------------------------------------------------------------
4.4.11 Requested PTI alias confirmation.

Purpose:
    Confirm that requested_payment_to_income_ratio is a direct alias of Module 1
    payment_to_income_ratio.

Expected:
    requested_payment_to_income_ratio = payment_to_income_ratio for every row.

Interpretation:
    payment_to_income_ratio is the Module 1 requested-structure PTI.

    approved_payment_to_income_ratio is calculated later only after exposure treatment.

Credit risk concept:
    PTI is the payment-to-income ratio.

    It links product structure and payment burden to affordability stress.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE requested_payment_to_income_ratio IS DISTINCT FROM payment_to_income_ratio
    ) AS requested_pti_alias_mismatch_rows,
    MIN(requested_payment_to_income_ratio) AS min_requested_payment_to_income_ratio,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    MAX(requested_payment_to_income_ratio) AS max_requested_payment_to_income_ratio
FROM tmp_m2_stage_1_source_applications;



/*-----------------------------------------------------------------------------------------------
4.4.12 estimated_pd availability and synthetic estimated-PD proxy interpretation.

Purpose:
    Confirm estimated_pd is present in the staged source.

Expected:
    rows_missing_synthetic_estimated_pd_proxy = 0.

Boundary:
    estimated_pd remains the SQL field name from Module 1.

    It is interpreted as the synthetic estimated-PD proxy.

    Module 2 does not recalculate it.

Credit risk concept:
    estimated_pd is used as the synthetic estimated-risk input for strategy segmentation and rule
    triggers later.

    It is not recalibrated in Module 2.
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
    4. The staged source aligns to tmp_m2_source_selection_scope from Section 3.
    5. Module 1 scenario lineage is normalized and preserved.
    6. Module 2 strategy metadata is preserved.
    7. Campaign registry match metadata remains available through
       tmp_m2_campaign_registry_current_run_match for Section 16 evidence capture.
    8. Application and applicant identifiers are preserved.
    9. Borrower, product, requested-structure, affordability, and risk fields are preserved.
    10. product_type_policy_key is created.
    11. Every product_type maps to exactly one product policy row.
    12. expected_loss_amount is aliased as requested_expected_loss_amount.
    13. monthly_payment_proxy is aliased as requested_monthly_payment_proxy.
    14. payment_to_income_ratio is aliased as requested_payment_to_income_ratio.
    15. estimated_pd is preserved as the Module 1 SQL field and interpreted as the synthetic
        estimated-PD proxy.

No decision outcomes have been created.
No decision paths have been created.
No decision flags have been created.
No simulated offer-exposure flag has been created.
No reason codes have been assigned.
No approved amount has been calculated.
No approved payment has been calculated.
No approved PTI has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full QA framework has been built.

Next section:
    Section 5 should consume tmp_m2_stage_1_source_applications and create the non-decisioning
    derived strategy segmentation layer.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00907 -->


---

<a id="c038-m00908"></a>

### C038-M00908

**Andrew** · 2026-05-09T23:25:47.918000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00908 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 5 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00908 -->


**Attachments in export:** `Pasted text(143).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c038-m00915"></a>

### C038-M00915

**ChatGPT** · 2026-05-09T23:31:50.547414-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00915 -->
According to a document from 2026-05-10, I recommend replacing Section 5 with the version below. I preserved the core functional logic from your current Section 5, added a small dependency preflight, and strengthened the instructional commentary so the section teaches **how to run it, how to interpret it, the credit risk concepts, and how the SQL logic works**. fileciteturn87file2

```sql
/***************************************************************************************************
SECTION 5 — DERIVED STRATEGY SEGMENTATION LAYER
****************************************************************************************************

BUSINESS PURPOSE:
    Create a non-decisioning strategy segmentation layer that translates continuous and categorical
    Module 1 inputs into policy-readable diagnostic segments.

    Section 5 answers:

        "How should this synthetic applicant be described for strategy-rule interpretation?"

    Section 5 does not answer:

        "What final simulated strategy outcome should this synthetic applicant receive?"

    This section is the applicant-description layer.

    It prepares the borrower, product, requested-affordability, requested-exposure, requested Expected
    Loss, score-band, synthetic estimated-risk, mixed-signal, and borderline context that later
    rule-trigger logic will consume.

SQL PURPOSE:
    1. Confirm required Section 5 dependencies exist.
    2. Read from tmp_m2_stage_1_source_applications.
    3. Preserve all Section 4 source, lineage, and Module 2 strategy metadata fields.
    4. Attach active global strategy thresholds.
    5. Attach product-specific policy thresholds and controls.
    6. Normalize score_band into score_band_policy_key.
    7. Derive non-decisioning diagnostic segments:
            strategy_risk_tier
            requested_pti_bucket
            dti_bucket
            requested_exposure_tier
            requested_expected_loss_tier
            product_score_policy_segment
            mixed_signal_profile_type
            mixed_signal_condition_count
            borderline_profile_flag
    8. Preserve threshold values in the staged data for downstream auditability.
    9. Validate that segmentation is populated without creating decisions, flags, reason codes, or
       approved-exposure outputs.
    10. Provide local staging diagnostics before Section 6 rule-trigger construction.

WHO SHOULD REVIEW THIS SECTION:
    Credit strategy reviewers:
        Confirm that borrower, product, affordability, requested-exposure, and risk profile segments
        are intuitive before they are converted into rule-trigger flags.

    Model governance / validation reviewers:
        Confirm that Section 5 is descriptive only and does not prematurely assign decisions,
        exposure, or reason codes.

    SQL reviewers:
        Confirm that the segmentation logic is staged through readable CTEs, preserves row grain, and
        uses governed thresholds rather than hidden constants.

    Portfolio / executive reviewers:
        Use Section 5 diagnostics to understand what kinds of applicants exist in the selected
        Module 1 scenario before interpreting final strategy outcomes later.

WHEN TO RUN THIS SECTION:
    Run Section 5 after:

        Section 4 — Module 1 Source Selection and Lineage Normalization

    Section 5 should be run before:

        Section 6 — Rule Flag Construction Layer

    Section 5 depends on:
        tmp_m2_stage_1_source_applications
        tmp_module2_strategy_params
        tmp_module2_product_policy_params

HOW TO INTERPRET THIS SECTION:
    Passing Section 5 means:
        every staged applicant has complete segmentation fields,
        row count is preserved from Section 4,
        application_id remains unique,
        score bands normalize to policy keys,
        product policy thresholds are attached,
        and no decision / reason-code / approved-exposure outputs have been created early.

    Passing Section 5 does not mean:
        the applicant is approved,
        the applicant is declined,
        a counteroffer is feasible,
        manual review is assigned,
        reason codes are assigned,
        approved exposure exists,
        approved Expected Loss exists,
        or final strategy validation has passed.

INPUT:
    tmp_m2_stage_1_source_applications

OUTPUT:
    tmp_m2_stage_2_strategy_segments

GRAIN:
    One row per application_id for the selected Module 1 scenario / population and active Module 2
    strategy.

WHY SEGMENTATION IS SEPARATED FROM DECISION RULES:
    Segmentation describes the synthetic applicant profile.

    Decision rules later evaluate that profile and create rule-trigger flags.

    Preliminary routing later prioritizes overlapping rule triggers.

    Exposure treatment later tests approved exposure and counteroffer feasibility.

    Final decision resolution later creates final simulated outcomes.

    Reason-code assignment later explains final outcomes.

    Keeping these layers separate improves:
        readability,
        auditability,
        QA,
        troubleshooting,
        strategy tuning,
        and documentation traceability.

CREDIT RISK CONCEPT — SEGMENTATION IS DESCRIPTION, NOT TREATMENT:
    A risk tier, PTI bucket, DTI bucket, requested exposure tier, or requested Expected Loss tier is a
    way of describing a synthetic applicant.

    It is not a final decision.

    For example:
        HIGH_REQUESTED_PTI means the requested structure has affordability pressure.
        It does not mean the row is declined.

        SEVERE_REQUESTED_EL means requested-exposure Expected Loss is high.
        It does not mean approved Expected Loss will remain high after exposure treatment.

        BORDERLINE_PROFILE means a value is close to a governed threshold.
        It does not mean automatic manual review.

WHY THRESHOLD VALUES ARE ATTACHED:
    Downstream stages should be interpretable without forcing reviewers to reverse-engineer the
    active strategy parameter tables.

    Section 5 therefore carries forward:
        global synthetic estimated-risk thresholds,
        global PTI thresholds,
        DTI thresholds,
        rule-control parameters,
        product PTI thresholds,
        requested Expected Loss thresholds,
        approved Expected Loss caps,
        approved amount limits,
        counteroffer controls,
        and rounding controls.

    This makes later rule flags, preliminary routing, exposure treatment, and final decision resolution
    easier to audit.

ESTIMATED_PD BOUNDARY:
    estimated_pd remains the finalized Module 1 SQL field.

    Section 5 uses estimated_pd only as the synthetic estimated-PD proxy input for diagnostic
    segmentation.

    Section 5 does not recalculate estimated_pd.
    Section 5 does not calibrate estimated_pd.
    Section 5 does not create a new post-decision risk model.

REQUESTED PTI BOUNDARY:
    requested_payment_to_income_ratio is the original requested-structure PTI from Module 1.

    Approved payment and approved PTI do not exist yet.

    Section 5 therefore segments requested affordability pressure, not approved affordability after
    exposure treatment.

DTI BOUNDARY:
    debt_to_income_ratio is an existing-obligation capacity signal.

    In Module 2 V1.0, DTI is not directly fixed by counteroffer exposure reduction because a
    counteroffer changes the requested exposure treatment, not the applicant's existing obligations.

REQUESTED EXPOSURE VS APPROVED EXPOSURE:
    requested_amount is the original requested exposure from Module 1.

    approved_amount does not exist in Section 5.

    Section 5 may describe requested exposure intensity, but it does not assign approved exposure.

REQUESTED EXPECTED LOSS VS APPROVED EXPECTED LOSS:
    requested_expected_loss_amount is requested-exposure Expected Loss carried from Module 1.

    approved_expected_loss_amount does not exist in Section 5.

    Section 5 segments requested-exposure Expected Loss pressure before any approved-exposure
    treatment is calculated.

MIXED-SIGNAL PROFILE BOUNDARY:
    mixed_signal_profile_type is diagnostic only.

    It identifies realistic overlap patterns such as:
        strong credit with high requested PTI,
        weak credit with low requested PTI,
        large exposure with low synthetic estimated-risk,
        high synthetic estimated-risk with low exposure,
        high DTI with low requested PTI.

    It does not automatically approve, decline, route to review, or trigger counteroffer.

BORDERLINE PROFILE BOUNDARY:
    borderline_profile_flag uses the governed borderline_threshold_buffer_pct parameter from Section 2.

    No hidden hardcoded threshold-adjacent buffer is used.

    Borderline status is diagnostic only. It helps later QA and manual-review trigger interpretation
    but does not create a final outcome in Section 5.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the segmentation layer as a session-scoped staging table.

    ON COMMIT PRESERVE ROWS:
        Keeps the staging rows available across transaction boundaries in the same session.

    CTE chain:
        The WITH clause breaks segmentation into readable steps:
            active_strategy_params
            threshold_enriched
            score_normalized
            core_segments
            mixed_signal_conditions
            mixed_signal_scored
            borderline_scored
            final_segments

    JOIN active_strategy_params ON TRUE:
        Attaches the single active strategy parameter card to every staged applicant row.

    JOIN product policy:
        Attaches product-specific thresholds and controls using product_type_policy_key.

    CASE:
        Converts continuous values into readable diagnostic categories.

    REGEXP_REPLACE + UPPER + BTRIM:
        Normalizes score band text into stable policy keys.

    Boolean expressions:
        Create diagnostic mixed-signal conditions and borderline flags.

    ::INT:
        Converts TRUE / FALSE conditions into 1 / 0 so they can be counted.

    NULLIF:
        Used later in diagnostics to avoid unsafe assumptions when denominators can be zero.

WHY NO DECISION OUTPUTS ARE CREATED IN SECTION 5:
    Section 5 does not create:
        decision_outcome
        decision_path
        approval_flag
        decline_flag
        manual_review_flag
        counteroffer_flag
        simulated_offer_exposure_flag
        reason codes
        approved_amount
        approved payment
        approved PTI
        approved Expected Loss

GOVERNANCE ROLE:
    Section 5 makes the strategy-rule input profile transparent.

    It demonstrates separation of concerns:
        Module 1 source values are preserved.
        Strategy thresholds are attached.
        Product policy thresholds are attached.
        Diagnostic segments are created.
        Decision logic remains deferred.

COMMON MISUSE TO AVOID:
    Do not interpret strategy_risk_tier as a final decision.
    Do not interpret requested_pti_bucket as approved affordability.
    Do not interpret dti_bucket as counteroffer-adjusted capacity.
    Do not interpret requested_exposure_tier as approved exposure.
    Do not interpret requested_expected_loss_tier as approved Expected Loss.
    Do not interpret mixed_signal_profile_type as a final route.
    Do not interpret borderline_profile_flag as automatic manual review.
    Do not treat segmentation output as operational applicant treatment.

TESTING RELEVANCE:
    Section 5 local diagnostics help confirm that diagnostic segmentation is complete, stable, and
    aligned to the selected Module 1 population and Module 2 strategy before rule-trigger construction
    begins.

DOWNSTREAM DEPENDENCY:
    Section 6 consumes tmp_m2_stage_2_strategy_segments.

    Downstream rule logic should not read directly from Section 4 when Section 5-derived diagnostic
    fields are needed.

PORTFOLIO ARTIFACT VALUE:
    This section shows that the strategy engine is not a monolithic decision CASE block.

    It demonstrates a mature staged architecture where applicant description, rule triggers,
    preliminary routing, exposure treatment, final outcomes, explanation codes, archive comparison,
    and validation evidence are separated and reviewable.

***************************************************************************************************/



/***************************************************************************************************
SECTION 5.0 — SECTION 5 DEPENDENCY PREFLIGHT
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that the required upstream staging and parameter objects exist before the segmentation
    layer is built.

    Section 5.0 answers:

        "Can Section 5 safely build segmentation from the validated Section 4 source stage and the
         active Section 2 parameter cards?"

SQL PURPOSE:
    1. Confirm tmp_m2_stage_1_source_applications exists.
    2. Confirm tmp_module2_strategy_params exists.
    3. Confirm tmp_module2_product_policy_params exists.
    4. Confirm exactly one active strategy parameter row exists.
    5. Confirm source-stage rows exist.
    6. Confirm product-policy rows exist.

WHY THIS PREFLIGHT EXISTS:
    Section 5 is a transformation layer.

    It should fail with a clear message if the required source-stage or parameter objects are not
    available, rather than producing a lower-level missing-table error or silently building an empty
    segmentation table.

BOUNDARY:
    Section 5.0 does not create segmentation.
    Section 5.0 does not create decisions.
    Section 5.0 does not create reason codes.
    Section 5.0 does not calculate approved exposure.
    Section 5.0 does not modify any persistent table.

***************************************************************************************************/

DO $$
DECLARE
    v_stage1_exists BOOLEAN;
    v_strategy_params_exists BOOLEAN;
    v_product_policy_params_exists BOOLEAN;

    v_active_strategy_count BIGINT;
    v_stage1_row_count BIGINT;
    v_product_policy_row_count BIGINT;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Dependency check: Section 4 source-stage table must exist.

    SQL mechanics:
        TO_REGCLASS checks whether the temporary object exists.

        pg_temp is checked because tmp_m2_stage_1_source_applications is a temporary table.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_stage_1_source_applications'),
        TO_REGCLASS('tmp_m2_stage_1_source_applications')
    ) IS NOT NULL
    INTO v_stage1_exists;

    IF v_stage1_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_m2_stage_1_source_applications is required. Run Section 4 before Section 5.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: active strategy parameter table must exist.

    Section 5 needs the active strategy thresholds and rule-control parameters.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_strategy_params'),
        TO_REGCLASS('tmp_module2_strategy_params')
    ) IS NOT NULL
    INTO v_strategy_params_exists;

    IF v_strategy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_module2_strategy_params is required. Run Section 2 before Section 5.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Dependency check: product policy parameter table must exist.

    Section 5 needs product-specific PTI, requested Expected Loss, approved Expected Loss cap,
    exposure, counteroffer, manual-review, and rounding controls.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_module2_product_policy_params'),
        TO_REGCLASS('tmp_module2_product_policy_params')
    ) IS NOT NULL
    INTO v_product_policy_params_exists;

    IF v_product_policy_params_exists IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_module2_product_policy_params is required. Run Section 2 before Section 5.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: exactly one active strategy parameter row.

    Section 3 already validates this, but Section 5 repeats the check locally so this section fails
    clearly when run out of order.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_active_strategy_count
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE;

    IF v_active_strategy_count <> 1 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: expected exactly one active strategy parameter row, found %.',
            v_active_strategy_count;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: Section 4 source-stage rows must exist.

    Segmentation over an empty applicant set is not useful and usually indicates an upstream source
    selection problem.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage1_row_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_stage1_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: product policy rows must exist.

    Section 3 validates completeness and supported products. Section 5 only confirms the table is
    populated before the product-policy join is attempted.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_product_policy_row_count
    FROM tmp_module2_product_policy_params;

    IF v_product_policy_row_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_module2_product_policy_params contains zero rows.';
    END IF;
END $$;



/***************************************************************************************************
SECTION 5.1 — CLEAN RESET OF SECTION 5 STAGING OBJECT
****************************************************************************************************

BUSINESS PURPOSE:
    Drop the Section 5 segmentation stage before rebuilding it.

SQL PURPOSE:
    Remove only the temporary Section 5 staging table.

WHY THIS MATTERS:
    A partial rerun should not allow stale segmentation rows to remain available to Section 6.

    Section 6 assumes tmp_m2_stage_2_strategy_segments reflects the current:
        Section 4 source stage,
        active Module 2 strategy card,
        and active product policy card.

SQL MECHANICS:
    DROP TABLE IF EXISTS makes the reset rerunnable.

    If the table does not exist, PostgreSQL does not error.

BOUNDARY:
    This drop affects only the temporary Section 5 staging object.

    It does not modify Module 1 outputs.
    It does not modify Module 2 latest-run output.
    It does not modify Module 2 archive output.
    It does not modify evidence tables.
    It does not modify registry tables.

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
    All Section 4 fields plus:
        global strategy thresholds,
        product policy thresholds,
        rule-control parameters,
        normalized score band key,
        diagnostic strategy segmentation fields,
        mixed-signal diagnostics,
        and borderline profile flag.

SQL DESIGN:
    This section uses a CTE chain so the segmentation process is readable and reviewable.

    The chain is:

        active_strategy_params
            selects the one active strategy parameter card.

        threshold_enriched
            attaches global strategy and product policy thresholds to each source row.

        score_normalized
            creates score_band_policy_key.

        core_segments
            creates the main diagnostic segmentation fields.

        mixed_signal_conditions
            creates Boolean diagnostic mixed-signal conditions.

        mixed_signal_scored
            counts how many mixed-signal conditions are present.

        borderline_scored
            creates borderline_profile_flag using the governed threshold buffer.

        final_segments
            creates product_score_policy_segment and mixed_signal_profile_type.

WHY SELECT * IS ACCEPTABLE HERE:
    This is a temporary staging layer, not a permanent output table.

    Section 5 intentionally preserves all prior fields plus segmentation diagnostics for downstream
    rule-trigger construction.

    Permanent output selection is handled later with explicit field selection in Section 11.

***************************************************************************************************/

CREATE TEMP TABLE tmp_m2_stage_2_strategy_segments
ON COMMIT PRESERVE ROWS
AS
WITH active_strategy_params AS (
    /***********************************************************************************************
    CTE: active_strategy_params

    Purpose:
        Select the single active Module 2 strategy parameter row.

    SQL mechanics:
        Section 5.0 confirms exactly one active row exists.

        LIMIT 1 is therefore safe and prevents accidental multiplication if a future ad hoc edit
        introduces malformed parameter state before the preflight catches it.

    Credit risk interpretation:
        This row supplies the global strategy posture:
            synthetic estimated-risk thresholds,
            PTI thresholds,
            DTI thresholds,
            diagnostic buffer,
            and rule-control switches.
    ***********************************************************************************************/
    SELECT *
    FROM tmp_module2_strategy_params
    WHERE active_strategy_flag IS TRUE
    LIMIT 1
),

threshold_enriched AS (
    /***********************************************************************************************
    CTE: threshold_enriched

    Purpose:
        Attach global strategy thresholds and product-specific policy thresholds to every staged
        applicant row.

    SQL mechanics:
        s.* preserves the full Section 4 source-stage row.

        JOIN active_strategy_params p ON TRUE:
            attaches the one active strategy card to every row.

        JOIN tmp_module2_product_policy_params pp:
            attaches the product policy row that matches product_type_policy_key.

    Credit risk interpretation:
        Product policy is attached here because affordability tolerance, requested Expected Loss
        thresholds, approved Expected Loss caps, approved exposure ranges, and counteroffer controls
        vary by product.

    Boundary:
        These thresholds are attached for transparency and downstream use.

        Section 5 does not apply final rules or assign outcomes.
    ***********************************************************************************************/
    SELECT
        s.*,

        /*******************************************************************************************
        Global synthetic estimated-risk thresholds.

        estimated_pd is interpreted as the synthetic estimated-PD proxy.

        These thresholds describe synthetic risk bands used for strategy simulation.
        *******************************************************************************************/
        p.approve_max_estimated_pd_proxy,
        p.counteroffer_max_estimated_pd_proxy,
        p.review_max_estimated_pd_proxy,
        p.decline_min_estimated_pd_proxy,

        /*******************************************************************************************
        Global PTI thresholds.

        Product-specific PTI thresholds are used for product-aware segmentation, but global values
        are retained for strategy transparency.
        *******************************************************************************************/
        p.global_approve_max_pti,
        p.global_review_max_pti,
        p.global_decline_min_pti,

        /*******************************************************************************************
        DTI thresholds.

        DTI remains an existing-obligation capacity signal.

        It is not directly counteroffer-adjusted in Module 2 V1.0.
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

        They do not assign final decisions in Section 5.
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

        These are attached here for downstream transparency.

        Section 5 does not apply final exposure treatment or counteroffer feasibility logic.
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

        Credit risk interpretation:
            requested_expected_loss_amount reflects the original requested exposure.

            approved_expected_loss_amount does not exist yet.
        *******************************************************************************************/
        (pp.product_approve_max_requested_el / 2.0) AS requested_el_low_moderate_split

    FROM tmp_m2_stage_1_source_applications s

    JOIN active_strategy_params p
        ON TRUE

    JOIN tmp_module2_product_policy_params pp
        ON pp.product_type = s.product_type_policy_key
),

score_normalized AS (
    /***********************************************************************************************
    CTE: score_normalized

    Purpose:
        Normalize the original Module 1 score_band field into a stable Module 2 policy key.

    SQL mechanics:
        BTRIM removes leading / trailing spaces.
        REGEXP_REPLACE converts non-alphanumeric runs into underscores.
        UPPER standardizes capitalization.
        CASE maps accepted source variants to governed score-band keys.

    Credit risk interpretation:
        Score band is a borrower-quality segment.

        It is not the same as estimated_pd, but it should generally align directionally with the
        synthetic estimated-PD proxy.

    Boundary:
        Module 1 score_band is preserved.
        Section 5 adds score_band_policy_key for downstream strategy logic and QA.
    ***********************************************************************************************/
    SELECT
        te.*,

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
    /***********************************************************************************************
    CTE: core_segments

    Purpose:
        Create the primary non-decisioning segmentation fields.

    Fields created:
        strategy_risk_tier
        requested_pti_bucket
        dti_bucket
        requested_exposure_tier
        requested_expected_loss_tier

    Boundary:
        These are diagnostic profile categories.

        They do not create rule-trigger flags yet.
        They do not create final decisions.
        They do not create approved exposure.
    ***********************************************************************************************/
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

        SQL mechanics:
            CASE evaluates from top to bottom and returns the first matching condition.

        Credit risk interpretation:
            This creates an interpretable risk tier without recalculating estimated_pd.
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

        Approved PTI does not exist yet.

        Credit risk interpretation:
            PTI is the payment burden relative to income.

            Section 5 describes requested affordability pressure only.
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

        SQL mechanics:
            The CASE expression creates a mutually exclusive descriptive bucket based on governed
            DTI thresholds.
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

        No undocumented magic number is used.

        The reducibility test uses governed parameters:
            product_min_approved_amount
            product_min_counteroffer_pct
            product_max_exposure_reduction_pct

        Boundary:
            This does not assign approved_amount.
            It only describes requested exposure intensity.
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

        Credit risk interpretation:
            Requested Expected Loss is the risk estimate for the original requested structure.

            Approved Expected Loss will be calculated later only after approved exposure exists.
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
    /***********************************************************************************************
    CTE: mixed_signal_conditions

    Purpose:
        Create Boolean diagnostic conditions for realistic overlapping applicant profiles.

    Credit risk interpretation:
        Real credit portfolios are not perfectly separated.

        Strong score applicants can have high requested affordability stress.
        Weak score applicants can request modest exposure with low PTI.
        Low-risk applicants can request large exposure.
        High-risk applicants can request small exposure.
        High DTI can coexist with low requested PTI.

    Boundary:
        These conditions are diagnostic only.

        They do not assign final outcomes.
        They do not assign reason codes.
        They do not create Section 6 rule-trigger flags yet.
    ***********************************************************************************************/
    SELECT
        cs.*,

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
    /***********************************************************************************************
    CTE: mixed_signal_scored

    Purpose:
        Count how many mixed-signal diagnostic conditions are active on each row.

    SQL mechanics:
        TRUE::INT becomes 1.
        FALSE::INT becomes 0.

        Adding those values creates the row-level mixed_signal_condition_count.

    Why count rather than choose immediately:
        Multiple mixed signals can coexist.

        Section 5 preserves that complexity instead of forcing a single explanation too early.
    ***********************************************************************************************/
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
    /***********************************************************************************************
    CTE: borderline_scored

    Purpose:
        Identify rows close to major governed strategy thresholds.

    Credit risk interpretation:
        Borderline cases are analytically important because small threshold changes can move them
        between rule-trigger categories later.

    SQL mechanics:
        ABS(actual_value - threshold_value) <= threshold_value * borderline_threshold_buffer_pct

        This means:
            a row is borderline when a value is within the governed percentage buffer of a threshold.

    Boundary:
        This is diagnostic only.

        Borderline status does not automatically create manual review, counteroffer, decline, or any
        final outcome.
    ***********************************************************************************************/
    SELECT
        mss.*,

        (
            /***************************************************************************************
            Synthetic estimated-PD proxy threshold adjacency.
            ***************************************************************************************/
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

            /***************************************************************************************
            Requested PTI threshold adjacency.
            ***************************************************************************************/
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

            /***************************************************************************************
            DTI threshold adjacency.
            ***************************************************************************************/
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

            /***************************************************************************************
            Requested Expected Loss threshold adjacency.
            ***************************************************************************************/
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
    /***********************************************************************************************
    CTE: final_segments

    Purpose:
        Create final Section 5 diagnostic fields after core segmentation, mixed-signal condition
        scoring, and borderline scoring are available.

    Fields created:
        product_score_policy_segment
        mixed_signal_profile_type

    Boundary:
        These fields support later rule construction, QA, comparison, frontier review, and evidence
        capture.

        They are not final outcomes.
    ***********************************************************************************************/
    SELECT
        bs.*,

        /*******************************************************************************************
        Product × score policy segment.

        This field supports later segment-level QA, matched comparison, strategy frontier, and
        product × score evidence capture.

        SQL mechanics:
            Concatenates normalized product and score policy keys.
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

BUSINESS PURPOSE:
    Confirm that every selected synthetic application can be described consistently before Section 6
    creates rule-trigger flags.

SQL PURPOSE:
    1. Confirm Section 4 source stage still contains rows.
    2. Confirm Section 5 row count equals Section 4 row count.
    3. Confirm application_id remains unique.
    4. Confirm required segmentation fields are populated.
    5. Confirm product and score policy keys are populated.
    6. Confirm product-policy configuration remains one-to-one.
    7. Confirm required thresholds and controls are available.
    8. Confirm Section 5 did not create decision, reason-code, or approved-exposure fields.

LOCAL GATEKEEPER BOUNDARY:
    These are Section 5 staging gatekeepers only.

    They are not:
        final decision validation,
        reason-code validation,
        approved-exposure validation,
        archive validation,
        matched strategy comparison,
        strategy frontier review,
        full Module 2 QA,
        or Validation Summary evidence by themselves.

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
    Gatekeeper: Section 4 source stage must contain rows.

    SQL mechanics:
        COUNT(*) checks the upstream staging population.

    Business interpretation:
        If Stage 1 is empty, segmentation cannot produce a valid profile layer.
    -------------------------------------------------------------------------------------------*/
    SELECT COUNT(*)
    INTO v_stage1_count
    FROM tmp_m2_stage_1_source_applications;

    IF v_stage1_count <= 0 THEN
        RAISE EXCEPTION
            'Module 2 Section 5 failure: tmp_m2_stage_1_source_applications contains zero rows.';
    END IF;


    /*-------------------------------------------------------------------------------------------
    Gatekeeper: row count must be unchanged from Section 4 to Section 5.

    Why this matters:
        Section 5 should add descriptors, not filter applicants or duplicate applicants.

    SQL mechanics:
        Compare Stage 1 row count to Stage 2 row count.
    -------------------------------------------------------------------------------------------*/
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

    Why this matters:
        Duplicate application_id values would duplicate downstream triggers, routes, decisions,
        exposure totals, and Expected Loss totals.

    SQL mechanics:
        Compare row count to COUNT(DISTINCT application_id).
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

    These fields describe the applicant profile.

    They do not determine final outcomes yet.
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

    Business interpretation:
        Product and score band are core strategy dimensions.

        Downstream product × score QA and evidence capture require these keys.
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

    Why this matters:
        Section 5 attaches product thresholds. If product policy mapping is missing or duplicated,
        downstream product-aware rules would be ambiguous.
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

    Business interpretation:
        Missing thresholds would make later rule-trigger flags difficult or impossible to explain.

    SQL mechanics:
        This query counts any row missing a required global strategy, rule-control, product policy,
        or requested Expected Loss split value.
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

    This protects the staged architecture boundary.

    SQL mechanics:
        pg_attribute inspects the physical columns of the temp table.

        If any downstream-only field exists, Section 5 fails.
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

BUSINESS PURPOSE:
    Let reviewers confirm that the diagnostic profile layer is populated and directionally usable
    before rule-trigger construction begins.

SQL PURPOSE:
    Display review outputs for:
        row count,
        application_id uniqueness,
        synthetic estimated-risk tier distribution,
        requested PTI bucket distribution,
        DTI bucket distribution,
        requested exposure tier distribution,
        requested Expected Loss tier distribution,
        product × score segment distribution,
        mixed-signal profile distribution,
        borderline profile distribution,
        product × risk tier distribution,
        score band × risk tier distribution,
        requested PTI bucket × risk tier distribution.

INTERPRETATION:
    These are staging diagnostics only.

    They should not be interpreted as:
        final strategy validation,
        final decision distribution,
        reason-code coverage,
        archive comparison,
        strategy frontier evidence,
        or Validation Summary acceptance.

SQL TEACHING POINT:
    These queries use GROUP BY to summarize diagnostic categories.

    They are not mutating queries.

    They do not alter segmentation results.

****************************************************************************************************/



/*-----------------------------------------------------------------------------------------------
5.4.1 Row count and distinct application_id count.

Expected:
    stage2_row_count = distinct_application_id_count.

Interpretation:
    Confirms the segmentation layer is still one row per application.
-----------------------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS stage2_row_count,
    COUNT(DISTINCT application_id) AS distinct_application_id_count
FROM tmp_m2_stage_2_strategy_segments;



/*-----------------------------------------------------------------------------------------------
5.4.2 Count by synthetic estimated-risk tier.

Interpretation:
    estimated_pd remains the SQL field name and is interpreted as the synthetic estimated-PD proxy.

    The average estimated_pd by tier should generally increase from LOW_SYNTHETIC_RISK toward
    SEVERE_SYNTHETIC_RISK.

Boundary:
    This is a segmentation diagnostic, not a final risk validation.
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

Interpretation:
    This is requested-structure affordability, not approved affordability.

    Approved PTI does not exist yet.
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

Interpretation:
    DTI reflects existing-obligation capacity and is not directly corrected by counteroffer.
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

Interpretation:
    This describes requested exposure relative to product policy limits.

    It does not assign approved_amount.
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

Interpretation:
    This uses requested_expected_loss_amount.

    approved_expected_loss_amount does not exist yet.
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

Interpretation:
    This field supports later product × score strategy QA and evidence capture.

    Product × score segmentation helps prevent portfolio averages from hiding concentrated strategy
    behavior.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_score_policy_segment,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_payment_to_income_ratio) AS avg_requested_payment_to_income_ratio,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
FROM tmp_m2_stage_2_strategy_segments
GROUP BY product_score_policy_segment
ORDER BY product_score_policy_segment;



/*-----------------------------------------------------------------------------------------------
5.4.8 Count by mixed-signal profile type.

Interpretation:
    Mixed-signal profiles are diagnostic only.

    They are not final routes.
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

Interpretation:
    Borderline status means at least one value is threshold-adjacent under the governed buffer.

    It is not automatic manual review.
-----------------------------------------------------------------------------------------------*/

SELECT
    borderline_profile_flag,
    COUNT(*) AS row_count
FROM tmp_m2_stage_2_strategy_segments
GROUP BY borderline_profile_flag
ORDER BY borderline_profile_flag;



/*-----------------------------------------------------------------------------------------------
5.4.10 Product × synthetic estimated-risk tier summary.

Interpretation:
    Helps verify product-level concentration of synthetic estimated-risk tiers.

    This can identify whether a product is naturally carrying more elevated synthetic risk in the
    selected Module 1 scenario.
-----------------------------------------------------------------------------------------------*/

SELECT
    product_type_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(estimated_pd) AS avg_synthetic_estimated_pd_proxy,
    AVG(requested_expected_loss_amount) AS avg_requested_expected_loss_amount
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

Interpretation:
    Helps review directional alignment between score band and synthetic estimated-risk tier.

    Stronger score bands should generally show lower synthetic estimated-risk proxy values, while
    weaker score bands should generally show higher values, while preserving realistic overlap.
-----------------------------------------------------------------------------------------------*/

SELECT
    score_band_policy_key,
    strategy_risk_tier,
    COUNT(*) AS row_count,
    AVG(credit_score) AS avg_credit_score,
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

Interpretation:
    Helps review interaction between requested affordability pressure and synthetic estimated-risk
    segmentation before rule-trigger construction.

    This is especially useful because affordability pressure can increase synthetic risk even when
    score-band quality is relatively strong.
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
    2. Row count is preserved from tmp_m2_stage_1_source_applications.
    3. application_id remains unique.
    4. All Section 4 source and lineage fields are preserved.
    5. Module 2 strategy metadata is preserved.
    6. Global strategy thresholds are attached.
    7. Product policy thresholds and controls are attached.
    8. score_band_policy_key is created.
    9. strategy_risk_tier is created.
    10. requested_pti_bucket is created.
    11. dti_bucket is created.
    12. requested_exposure_tier is created.
    13. requested_expected_loss_tier is created.
    14. product_score_policy_segment is created.
    15. mixed_signal_profile_type and mixed_signal_condition_count are created.
    16. borderline_profile_flag is created using governed borderline_threshold_buffer_pct.
    17. requested_expected_loss_amount remains requested-exposure Expected Loss.
    18. estimated_pd remains the Module 1 SQL field and is interpreted as the synthetic estimated-PD
        proxy.
    19. Section 5 dependency preflight passed.
    20. Section 5 local staging gatekeepers passed.
    21. Section 5 local segmentation diagnostics are available for review.

No final decision outcomes have been created.
No preliminary decision routes have been created.
No decision flags have been created.
No simulated offer-exposure flag has been created.
No simulated reason codes have been assigned.
No approved amount has been calculated.
No counteroffer amount has been calculated.
No approved payment has been calculated.
No approved PTI has been calculated.
No approved Expected Loss has been calculated.
No latest-run strategy decision output has been created.
No archive rows have been inserted.
No evidence rows have been inserted.
No matched comparison has been performed.
No strategy frontier has been calculated.
No full QA framework has been built.

Next section:
    Section 6 should consume tmp_m2_stage_2_strategy_segments and create the non-final rule-trigger
    flag layer.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00915 -->


---

<a id="c038-m00916"></a>

### C038-M00916

**Andrew** · 2026-05-09T23:34:34.891000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00916 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 6 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00916 -->


**Attachments in export:** `Pasted text(144).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_41.md) · [Next](Part_43.md)
