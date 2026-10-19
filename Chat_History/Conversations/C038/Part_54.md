# Module 2 Decision Simulator Build

## Part 54

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_53.md) · [Next](Part_55.md)

<a id="c038-m00998"></a>

### C038-M00998

**ChatGPT** · 2026-05-10T09:52:04.506177-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00998 -->
I recommend replacing **Section 14.17 through Section 14.19** with the version below. I used your current uploaded 14.17–14.19 as the base, then upgraded the commentary to explain what each result means, what to look for, what triggers review, and how the SQL mechanics work. fileciteturn115file10

```sql
/***************************************************************************************************
SECTION 14.17 — FINAL OUTPUT CONVENTION VALIDATION
****************************************************************************************************

BUSINESS PURPOSE:
    Confirm that locked final output conventions hold in the latest-run table.

    Section 14.17 answers:

        "Do final decision flags, simulated offer-exposure flags, approved amount conventions,
         affordability conventions, approved Expected Loss conventions, and reason-code conventions
         reconcile to final decision_outcome?"

SQL PURPOSE:
    1. Produce compact violation counts for final output conventions.
    2. Confirm exactly one final decision flag is TRUE per row.
    3. Confirm final decision flags reconcile to decision_outcome.
    4. Confirm simulated_offer_exposure_flag reconciles to APPROVE and COUNTEROFFER.
    5. Confirm approved amount conventions by final outcome.
    6. Confirm approved monthly payment and approved PTI conventions by final outcome.
    7. Confirm approved Expected Loss conventions by final outcome.
    8. Confirm simulated reason-code completeness.
    9. Confirm simulated reason-family alignment.
    10. Confirm prohibited boundary terminology is not present in simulated reason-code fields.

EXPECTED RESULT:
    All violation counts should be zero.

WHY THIS SECTION IS IMPORTANT:
    Many Section 14 diagnostics are directional. They may require interpretation, but they do not
    necessarily indicate implementation defects.

    Section 14.17 is different.

    This section validates locked output conventions. A nonzero violation count is stronger evidence
    of a possible implementation issue, upstream assumption break, or output-schema problem.

CREDIT RISK INTERPRETATION:
    The final outcome taxonomy is only useful if the economics and flags are coherent.

    APPROVE:
        should preserve requested exposure and requested-exposure Expected Loss.

    COUNTEROFFER:
        should assign positive reduced exposure below requested amount and should satisfy approved
        affordability and approved Expected Loss conventions.

    MANUAL_REVIEW:
        should remain unresolved with NULL approved exposure, NULL approved PTI, and NULL approved
        Expected Loss.

    DECLINE:
        should follow the zero-exposure convention.

    Reason-code fields:
        should explain the simulated outcome without becoming external communication language.

WHAT TO LOOK FOR:
    Every column in this output should be zero.

    If all columns are zero, the final output conventions are internally coherent.

REVIEW TRIGGERS:
    Any nonzero count requires review before Validation Summary, README, LinkedIn, or executive
    narrative claims are drafted.

    The review question should be:

        "Which final outcome convention broke, and does the break come from routing, exposure
         treatment, final resolution, reason-code assignment, or latest-run materialization?"

SQL CONCEPTS TAUGHT IN THIS SECTION:
    COUNT(*) FILTER:
        Counts rows meeting a specific violation condition without filtering the entire result set.

    COALESCE(boolean::INT, 0):
        Converts TRUE / FALSE decision flags into 1 / 0 values so they can be summed.

    IS DISTINCT FROM:
        Performs NULL-safe comparisons. This is important because ordinary <> comparisons do not
        behave intuitively when NULLs are involved.

    IN:
        Tests whether decision_outcome belongs to the simulated positive offer-exposure outcome set.

    BTRIM:
        Treats whitespace-only text as blank for reason-code completeness.

    ILIKE:
        Performs case-insensitive prohibited-term checks.

BOUNDARY:
    Section 14.17 does not modify latest-run rows.
    Section 14.17 does not modify archive rows.
    Section 14.17 does not recalculate decisions.
    Section 14.17 does not reassign reason codes.
    Section 14.17 does not recalculate approved exposure.
    Section 14.17 does not recalculate approved Expected Loss.
    Section 14.17 does not create evidence rows.

***************************************************************************************************/

SELECT
    /***********************************************************************************************
    Final decision flag count convention.

    Expected:
        exactly one final decision flag is TRUE per row.

    SQL mechanics:
        Each Boolean flag is cast to INT:
            TRUE  → 1
            FALSE → 0
            NULL  → handled as 0 through COALESCE

        The sum should equal exactly 1.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE (
            COALESCE(approval_flag::INT, 0)
            + COALESCE(counteroffer_flag::INT, 0)
            + COALESCE(manual_review_flag::INT, 0)
            + COALESCE(decline_flag::INT, 0)
        ) <> 1
    ) AS final_outcome_flag_count_violation_rows,


    /***********************************************************************************************
    Final decision flag alignment convention.

    Expected:
        approval_flag       = TRUE only when decision_outcome = APPROVE.
        counteroffer_flag   = TRUE only when decision_outcome = COUNTEROFFER.
        manual_review_flag  = TRUE only when decision_outcome = MANUAL_REVIEW.
        decline_flag        = TRUE only when decision_outcome = DECLINE.

    Why separate from flag count:
        A row could have exactly one TRUE flag but still have the wrong flag for the final outcome.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE approval_flag IS DISTINCT FROM (decision_outcome = 'APPROVE')
           OR counteroffer_flag IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
           OR manual_review_flag IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
           OR decline_flag IS DISTINCT FROM (decision_outcome = 'DECLINE')
    ) AS final_outcome_flag_alignment_violation_rows,


    /***********************************************************************************************
    Simulated offer-exposure convention.

    Expected:
        TRUE for:
            APPROVE
            COUNTEROFFER

        FALSE for:
            MANUAL_REVIEW
            DECLINE

    Boundary:
        simulated_offer_exposure_flag means simulated positive offer exposure only.

        It does not imply booked exposure, funded exposure, production approval, operational account
        creation, or real applicant treatment.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE simulated_offer_exposure_flag
              IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
    ) AS simulated_offer_exposure_flag_violation_rows,


    /***********************************************************************************************
    APPROVE amount convention.

    Expected:
        approved_amount = requested_amount.

    Credit risk interpretation:
        Final APPROVE preserves the requested structure.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_amount IS DISTINCT FROM requested_amount
    ) AS approve_amount_violation_rows,


    /***********************************************************************************************
    COUNTEROFFER amount convention.

    Expected:
        approved_amount is populated,
        approved_amount is positive,
        approved_amount is less than requested_amount,
        counteroffer_amount equals approved_amount.

    Credit risk interpretation:
        A final COUNTEROFFER is a positive simulated offer-exposure outcome with reduced exposure.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_amount IS NULL
             OR approved_amount <= 0
             OR approved_amount >= requested_amount
             OR counteroffer_amount IS DISTINCT FROM approved_amount
          )
    ) AS counteroffer_amount_violation_rows,


    /***********************************************************************************************
    MANUAL_REVIEW amount convention.

    Expected:
        approved_amount remains NULL.

    Credit risk interpretation:
        MANUAL_REVIEW is unresolved by design.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_amount IS NOT NULL
    ) AS manual_review_amount_violation_rows,


    /***********************************************************************************************
    DECLINE amount convention.

    Expected:
        approved_amount = 0.

    Credit risk interpretation:
        DECLINE follows the zero-exposure convention.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_amount_violation_rows,


    /***********************************************************************************************
    General approved amount sanity checks.

    Expected:
        no negative approved amounts,
        no approved amount above requested amount.

    Why this is useful:
        These checks catch broad economic convention breaks that may not be visible from one outcome
        family alone.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE approved_amount IS NOT NULL
          AND approved_amount < 0
    ) AS negative_approved_amount_rows,

    COUNT(*) FILTER (
        WHERE approved_amount IS NOT NULL
          AND approved_amount > requested_amount
    ) AS approved_amount_above_requested_amount_rows,


    /***********************************************************************************************
    APPROVE payment convention.

    Expected:
        approved_monthly_payment_proxy = requested_monthly_payment_proxy.

    Interpretation:
        Since APPROVE preserves requested exposure, the approved payment proxy should preserve the
        requested payment proxy.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_monthly_payment_proxy IS DISTINCT FROM requested_monthly_payment_proxy
    ) AS approve_payment_violation_rows,


    /***********************************************************************************************
    COUNTEROFFER affordability convention.

    Expected:
        approved_monthly_payment_proxy is populated,
        approved_payment_to_income_ratio is populated,
        approved_payment_to_income_ratio <= counteroffer_target_pti.

    Boundary:
        approved_payment_to_income_ratio is a strategy-simulation affordability proxy, not a
        contractual payment schedule.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_monthly_payment_proxy IS NULL
             OR approved_payment_to_income_ratio IS NULL
             OR approved_payment_to_income_ratio > counteroffer_target_pti
          )
    ) AS counteroffer_affordability_violation_rows,


    /***********************************************************************************************
    MANUAL_REVIEW affordability convention.

    Expected:
        approved payment and approved PTI remain NULL.

    Interpretation:
        MANUAL_REVIEW is unresolved and should not carry approved affordability economics.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND (
                approved_monthly_payment_proxy IS NOT NULL
             OR approved_payment_to_income_ratio IS NOT NULL
          )
    ) AS manual_review_affordability_violation_rows,


    /***********************************************************************************************
    DECLINE affordability convention.

    Expected:
        approved payment proxy = 0,
        approved PTI = 0.

    Interpretation:
        zero approved exposure produces zero approved payment burden by convention.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND (
                approved_monthly_payment_proxy IS DISTINCT FROM 0::NUMERIC
             OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
          )
    ) AS decline_affordability_violation_rows,


    /***********************************************************************************************
    APPROVE Expected Loss convention.

    Expected:
        approved_expected_loss_amount = requested_expected_loss_amount.

    Interpretation:
        APPROVE preserves requested exposure, so approved-exposure Expected Loss should equal
        requested-exposure Expected Loss.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'APPROVE'
          AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
    ) AS approve_expected_loss_violation_rows,


    /***********************************************************************************************
    COUNTEROFFER Expected Loss convention.

    Expected:
        approved_expected_loss_amount is populated,
        approved_expected_loss_amount is non-negative,
        approved_expected_loss_amount <= requested_expected_loss_amount,
        approved_expected_loss_amount <= product_approved_el_cap.

    Interpretation:
        Reduced exposure should not increase approved Expected Loss when estimated_pd and estimated_lgd
        remain unchanged.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'COUNTEROFFER'
          AND (
                approved_expected_loss_amount IS NULL
             OR approved_expected_loss_amount < 0
             OR approved_expected_loss_amount > requested_expected_loss_amount
             OR approved_expected_loss_amount > product_approved_el_cap
          )
    ) AS counteroffer_expected_loss_violation_rows,


    /***********************************************************************************************
    MANUAL_REVIEW Expected Loss convention.

    Expected:
        approved_expected_loss_amount remains NULL.

    Interpretation:
        unresolved manual-review outcomes should not carry approved-exposure Expected Loss.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'MANUAL_REVIEW'
          AND approved_expected_loss_amount IS NOT NULL
    ) AS manual_review_expected_loss_violation_rows,


    /***********************************************************************************************
    DECLINE Expected Loss convention.

    Expected:
        approved_expected_loss_amount = 0.

    Interpretation:
        zero approved exposure produces zero approved-exposure Expected Loss by convention.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE decision_outcome = 'DECLINE'
          AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
    ) AS decline_expected_loss_violation_rows,


    /***********************************************************************************************
    General approved Expected Loss sanity check.

    Expected:
        no negative approved Expected Loss values.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE approved_expected_loss_amount IS NOT NULL
          AND approved_expected_loss_amount < 0
    ) AS negative_approved_expected_loss_rows,


    /***********************************************************************************************
    Reason-code completeness convention.

    Expected:
        primary_reason_code populated,
        primary_reason_family populated,
        triggered_reason_code_list populated,
        reason_code_count populated and at least 1.

    Boundary:
        These are simulated strategy explanation fields only.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE primary_reason_code IS NULL
           OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
           OR primary_reason_family IS NULL
           OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
           OR triggered_reason_code_list IS NULL
           OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
           OR reason_code_count IS NULL
           OR reason_code_count < 1
    ) AS reason_code_completeness_violation_rows,


    /***********************************************************************************************
    Reason-family alignment convention.

    Expected:
        APPROVE       → APPROVAL
        COUNTEROFFER  → COUNTEROFFER
        MANUAL_REVIEW → MANUAL_REVIEW
        DECLINE       → POLICY_STOP
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE (
                decision_outcome = 'APPROVE'
            AND primary_reason_family IS DISTINCT FROM 'APPROVAL'
        )
        OR (
                decision_outcome = 'COUNTEROFFER'
            AND primary_reason_family IS DISTINCT FROM 'COUNTEROFFER'
        )
        OR (
                decision_outcome = 'MANUAL_REVIEW'
            AND primary_reason_family IS DISTINCT FROM 'MANUAL_REVIEW'
        )
        OR (
                decision_outcome = 'DECLINE'
            AND primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
        )
    ) AS reason_family_alignment_violation_rows,


    /***********************************************************************************************
    Prohibited reason-code terminology boundary.

    Expected:
        zero rows.

    Interpretation:
        Simulated strategy explanation codes should not use terms that imply customer notices,
        adverse-action handling, regulatory conclusions, or fair-lending conclusions.
    ***********************************************************************************************/
    COUNT(*) FILTER (
        WHERE COALESCE(primary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%ADVERSE_ACTION%'

           OR COALESCE(primary_reason_code, '') ILIKE '%REGULATORY%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%REGULATORY%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%REGULATORY%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%REGULATORY%'

           OR COALESCE(primary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%CUSTOMER_NOTICE%'

           OR COALESCE(primary_reason_code, '') ILIKE '%FAIR_LENDING%'
           OR COALESCE(secondary_reason_code, '') ILIKE '%FAIR_LENDING%'
           OR COALESCE(tertiary_reason_code, '') ILIKE '%FAIR_LENDING%'
           OR COALESCE(triggered_reason_code_list, '') ILIKE '%FAIR_LENDING%'
    ) AS prohibited_reason_code_boundary_term_rows

FROM credit_decisioning_sim.strategy_decisions;



/***************************************************************************************************
SECTION 14.18 — ARCHIVE AND COMPARISON READINESS RECAP
****************************************************************************************************

BUSINESS PURPOSE:
    Summarize whether the latest-run output is archived and whether matched strategy comparison
    evidence is available for interpretation.

    Section 14.18 answers:

        "Is the current latest-run strategy output ready for archive-backed strategy comparison, and
         did the selected Section 13 comparison preserve matched source-field consistency?"

SQL PURPOSE:
    1. Build a temporary archive-readiness context for the current latest-run slice.
    2. Confirm whether the current latest-run slice is aligned to the archive.
    3. Create temporary NOT_APPLICABLE comparison placeholders only when Section 13 helpers are absent
       in the current session.
    4. Display matched strategy comparison readiness from Section 13 when available.
    5. Display matched source-field consistency from Section 13 when available.

BUSINESS INTERPRETATION:
    Latest-run QA and matched strategy comparison are related but distinct.

    Latest-run QA asks:
        "Is the current strategy output internally coherent?"

    Matched comparison asks:
        "How did one archived strategy differ from another archived strategy on the same Module 1
         scenario and population?"

    Archive and comparison readiness help the reviewer decide whether the current output can support
    strategy frontier interpretation and executive comparison evidence.

WHY SECTION 14.18 CREATES TEMPORARY PLACEHOLDERS:
    Section 14 is primarily a latest-run QA section.

    Formal campaign review should run Section 12 and Section 13 before Section 14 so archive and
    matched comparison evidence are available.

    However, a user may run Section 14 for latest-run QA before matched comparison is ready.

    The placeholders let Section 14.19 still produce a complete validation status summary using
    NOT_APPLICABLE rows instead of failing solely because comparison helper tables are absent.

ARCHIVE BOUNDARY:
    This section does not insert archive rows.
    This section does not delete archive rows.
    This section does not update archive rows.

    Archive persistence remains governed by Section 12.

COMPARISON BOUNDARY:
    This section does not create matched comparison logic.

    Section 13 creates the comparison readiness and matched source-field consistency diagnostics.

    Section 14.18 only recaps those diagnostics for validation evidence.

TIMESTAMP BOUNDARY:
    latest_output_created_ts and archive_inserted_ts are audit metadata.

    They support traceability but are not deterministic strategy-comparison keys.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    Temporary context table:
        tmp_m2_archive_readiness_context gives Section 14 and Section 16 a compact archive-readiness
        row for the current latest-run slice.

    TO_REGCLASS:
        Checks whether archive and comparison helper objects exist.

    DO $$ ... END $$:
        Allows conditional object creation when optional Section 13 helper tables are absent.

    LEFT JOIN:
        Preserves the latest-run slice even when no matching archive slice exists.

    CASE:
        Converts archive count alignment into a readable archive_readiness_status.

READ-ONLY BOUNDARY:
    Section 14.18 does not modify latest-run rows.
    Section 14.18 does not modify archive rows.
    Section 14.18 does not recalculate decisions.
    Section 14.18 does not reassign reason codes.
    Section 14.18 does not recalculate approved exposure.
    Section 14.18 does not recalculate approved Expected Loss.

***************************************************************************************************/



/***************************************************************************************************
SECTION 14.18A — ARCHIVE READINESS CONTEXT SETUP
****************************************************************************************************

PURPOSE:
    Materialize a temporary archive-readiness context for the current latest-run slice.

BUSINESS PURPOSE:
    Show whether the current latest-run strategy / Module 1 scenario / population slice is present in
    the governed archive at the expected row count and application_id count.

EXPECTED INTERPRETATION:
    For formal archived runs with archive_run_flag = TRUE:
        archive_readiness_status should ordinarily be:

            PASS_CURRENT_LATEST_RUN_SLICE_ARCHIVED_AND_ROW_COUNT_ALIGNED

    For development runs with archive_run_flag = FALSE:
        archive_readiness_status may be:

            NOT_APPLICABLE_ARCHIVE_RUN_FLAG_FALSE

    If the archive table is absent:
        archive_readiness_status becomes:

            NOT_APPLICABLE_ARCHIVE_TABLE_NOT_AVAILABLE

REVIEW TRIGGERS:
    REVIEW_CURRENT_LATEST_RUN_SLICE_NOT_FOUND_IN_ARCHIVE:
        Section 12 may not have persisted the current run, or archive_run_flag may not have been
        applied as expected.

    REVIEW_CURRENT_LATEST_RUN_SLICE_ARCHIVE_COUNT_MISMATCH:
        Current latest-run row count and archived slice row count differ.

SQL MECHANICS:
    The temporary table is created first with explicit columns.

    A PL/pgSQL block then checks whether the archive table exists.

    If the archive exists:
        latest-run context is left joined to archive context by the archive replacement key.

    If the archive does not exist:
        the current latest-run context is still captured and labeled NOT_APPLICABLE.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_archive_readiness_context;

CREATE TEMP TABLE tmp_m2_archive_readiness_context (
    archive_run_flag                               BOOLEAN,
    strategy_archive_reset_mode                    TEXT,

    strategy_set_name                              TEXT,
    strategy_name                                  TEXT,
    strategy_version                               TEXT,

    module1_scenario_set_name                      TEXT,
    module1_scenario_name                          TEXT,
    population_id                                  TEXT,

    latest_run_row_count                           BIGINT,
    latest_run_distinct_application_id_count       BIGINT,

    archived_row_count                             BIGINT,
    archived_distinct_application_id_count         BIGINT,

    min_archive_inserted_ts                        TIMESTAMP,
    max_archive_inserted_ts                        TIMESTAMP,

    archive_readiness_status                       TEXT
) ON COMMIT PRESERVE ROWS;


DO $$
DECLARE
    v_archive_table_exists BOOLEAN;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Check whether the governed archive table exists.

    If it does not exist, latest-run QA can still proceed, but archive-readiness status must be
    labeled NOT_APPLICABLE rather than causing a hard failure.
    -------------------------------------------------------------------------------------------*/
    SELECT TO_REGCLASS('credit_decisioning_sim.strategy_decisions_archive') IS NOT NULL
    INTO v_archive_table_exists;

    IF v_archive_table_exists IS TRUE THEN
        /*******************************************************************************************
        Archive exists:
            compare the current latest-run slice to the corresponding archived slice.
        *******************************************************************************************/
        INSERT INTO tmp_m2_archive_readiness_context (
            archive_run_flag,
            strategy_archive_reset_mode,

            strategy_set_name,
            strategy_name,
            strategy_version,

            module1_scenario_set_name,
            module1_scenario_name,
            population_id,

            latest_run_row_count,
            latest_run_distinct_application_id_count,

            archived_row_count,
            archived_distinct_application_id_count,

            min_archive_inserted_ts,
            max_archive_inserted_ts,

            archive_readiness_status
        )
        WITH latest_context AS (
            SELECT
                archive_run_flag,
                strategy_archive_reset_mode,

                strategy_set_name,
                strategy_name,
                strategy_version,

                module1_scenario_set_name,
                module1_scenario_name,
                population_id,

                COUNT(*) AS latest_run_row_count,
                COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count
            FROM credit_decisioning_sim.strategy_decisions
            GROUP BY
                archive_run_flag,
                strategy_archive_reset_mode,
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        ),

        archive_context AS (
            SELECT
                strategy_set_name,
                strategy_name,
                strategy_version,

                module1_scenario_set_name,
                module1_scenario_name,
                population_id,

                COUNT(*) AS archived_row_count,
                COUNT(DISTINCT application_id) AS archived_distinct_application_id_count,

                MIN(archive_inserted_ts) AS min_archive_inserted_ts,
                MAX(archive_inserted_ts) AS max_archive_inserted_ts
            FROM credit_decisioning_sim.strategy_decisions_archive
            GROUP BY
                strategy_set_name,
                strategy_name,
                strategy_version,
                module1_scenario_set_name,
                module1_scenario_name,
                population_id
        )

        SELECT
            l.archive_run_flag,
            l.strategy_archive_reset_mode,

            l.strategy_set_name,
            l.strategy_name,
            l.strategy_version,

            l.module1_scenario_set_name,
            l.module1_scenario_name,
            l.population_id,

            l.latest_run_row_count,
            l.latest_run_distinct_application_id_count,

            COALESCE(a.archived_row_count, 0) AS archived_row_count,
            COALESCE(a.archived_distinct_application_id_count, 0)
                AS archived_distinct_application_id_count,

            a.min_archive_inserted_ts,
            a.max_archive_inserted_ts,

            /***************************************************************************************
            Archive readiness status.

            Interpretation:
                PASS means the current latest-run slice is present in archive at the expected row and
                distinct application count.

                REVIEW means archive state should be reviewed before matched comparison or evidence
                claims.

                NOT_APPLICABLE means archive persistence was intentionally skipped or archive table
                does not exist.
            ***************************************************************************************/
            CASE
                WHEN l.archive_run_flag IS FALSE
                    THEN 'NOT_APPLICABLE_ARCHIVE_RUN_FLAG_FALSE'

                WHEN COALESCE(a.archived_row_count, 0) = 0
                    THEN 'REVIEW_CURRENT_LATEST_RUN_SLICE_NOT_FOUND_IN_ARCHIVE'

                WHEN a.archived_row_count = l.latest_run_row_count
                 AND a.archived_distinct_application_id_count
                        = l.latest_run_distinct_application_id_count
                    THEN 'PASS_CURRENT_LATEST_RUN_SLICE_ARCHIVED_AND_ROW_COUNT_ALIGNED'

                ELSE 'REVIEW_CURRENT_LATEST_RUN_SLICE_ARCHIVE_COUNT_MISMATCH'
            END AS archive_readiness_status

        FROM latest_context l
        LEFT JOIN archive_context a
            ON a.strategy_set_name = l.strategy_set_name
           AND a.strategy_name = l.strategy_name
           AND a.strategy_version = l.strategy_version
           AND a.module1_scenario_set_name = l.module1_scenario_set_name
           AND a.module1_scenario_name = l.module1_scenario_name
           AND a.population_id = l.population_id;

    ELSE
        /*******************************************************************************************
        Archive does not exist:
            still capture the latest-run context and label archive-readiness as NOT_APPLICABLE.
        *******************************************************************************************/
        INSERT INTO tmp_m2_archive_readiness_context (
            archive_run_flag,
            strategy_archive_reset_mode,

            strategy_set_name,
            strategy_name,
            strategy_version,

            module1_scenario_set_name,
            module1_scenario_name,
            population_id,

            latest_run_row_count,
            latest_run_distinct_application_id_count,

            archived_row_count,
            archived_distinct_application_id_count,

            min_archive_inserted_ts,
            max_archive_inserted_ts,

            archive_readiness_status
        )
        SELECT
            archive_run_flag,
            strategy_archive_reset_mode,

            strategy_set_name,
            strategy_name,
            strategy_version,

            module1_scenario_set_name,
            module1_scenario_name,
            population_id,

            COUNT(*) AS latest_run_row_count,
            COUNT(DISTINCT application_id) AS latest_run_distinct_application_id_count,

            NULL::BIGINT AS archived_row_count,
            NULL::BIGINT AS archived_distinct_application_id_count,

            NULL::TIMESTAMP AS min_archive_inserted_ts,
            NULL::TIMESTAMP AS max_archive_inserted_ts,

            'NOT_APPLICABLE_ARCHIVE_TABLE_NOT_AVAILABLE'::TEXT AS archive_readiness_status

        FROM credit_decisioning_sim.strategy_decisions

        GROUP BY
            archive_run_flag,
            strategy_archive_reset_mode,
            strategy_set_name,
            strategy_name,
            strategy_version,
            module1_scenario_set_name,
            module1_scenario_name,
            population_id;
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
14.18B Archive readiness recap.

Business purpose:
    Display whether the current latest-run slice is aligned to the governed archive.

Credit risk interpretation:
    Archive readiness matters because matched strategy comparison and frontier review should use
    completed archived slices, not the replaceable latest-run table alone.

What to look for:
    For formal archived runs:
        archive_readiness_status should be
        PASS_CURRENT_LATEST_RUN_SLICE_ARCHIVED_AND_ROW_COUNT_ALIGNED.

    For development runs where archive_run_flag = FALSE:
        NOT_APPLICABLE_ARCHIVE_RUN_FLAG_FALSE can be acceptable.

Review triggers:
    REVIEW_CURRENT_LATEST_RUN_SLICE_NOT_FOUND_IN_ARCHIVE:
        Archive persistence may not have occurred.

    REVIEW_CURRENT_LATEST_RUN_SLICE_ARCHIVE_COUNT_MISMATCH:
        Archive row count does not align to the latest-run row count.

SQL mechanics:
    This query reads the temporary context table created in 14.18A.

    It does not query or mutate the archive directly.
-----------------------------------------------------------------------------------------------*/

SELECT
    archive_run_flag,
    strategy_archive_reset_mode,

    strategy_set_name,
    strategy_name,
    strategy_version,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    latest_run_row_count,
    latest_run_distinct_application_id_count,

    archived_row_count,
    archived_distinct_application_id_count,

    min_archive_inserted_ts,
    max_archive_inserted_ts,

    archive_readiness_status

FROM tmp_m2_archive_readiness_context;



/***************************************************************************************************
SECTION 14.18C — OPTIONAL COMPARISON-HELPER AVAILABILITY SETUP
****************************************************************************************************

PURPOSE:
    Ensure Section 14 can produce a complete validation status summary even when Section 13 comparison
    helpers are absent in the current session.

BUSINESS PURPOSE:
    Latest-run validation should remain available even if matched comparison is not ready or has not
    been executed.

SQL PURPOSE:
    1. Check for tmp_m2_strategy_comparison_readiness.
    2. Create a NOT_APPLICABLE placeholder if the readiness table is absent.
    3. Check for tmp_m2_strategy_comparison_source_consistency.
    4. Create a NOT_APPLICABLE placeholder if the source-consistency table is absent.

WHY THIS IS SAFE:
    These placeholders are temporary Section 14 helper tables only.

    They do not modify latest-run output.
    They do not modify archive output.
    They do not recalculate comparison metrics.
    They do not create a false "ready" status.

****************************************************************************************************/

DO $$
DECLARE
    v_comparison_readiness_exists BOOLEAN;
    v_source_consistency_exists BOOLEAN;
BEGIN
    /*-------------------------------------------------------------------------------------------
    Optional comparison readiness helper.

    If Section 13 has run, this table should already exist and should be left untouched.

    If Section 13 has not run, create a one-row NOT_APPLICABLE placeholder.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_comparison_readiness'),
        TO_REGCLASS('tmp_m2_strategy_comparison_readiness')
    ) IS NOT NULL
    INTO v_comparison_readiness_exists;

    IF v_comparison_readiness_exists IS DISTINCT FROM TRUE THEN
        EXECUTE $sql$
            CREATE TEMP TABLE tmp_m2_strategy_comparison_readiness
            ON COMMIT PRESERVE ROWS
            AS
            WITH latest_context AS (
                SELECT
                    strategy_set_name,
                    strategy_name,
                    strategy_version,
                    module1_scenario_set_name,
                    module1_scenario_name,
                    population_id
                FROM credit_decisioning_sim.strategy_decisions
                LIMIT 1
            )
            SELECT
                NULL::TEXT AS comparison_group_id,
                'NOT_APPLICABLE_SECTION_13_NOT_RUN'::TEXT AS comparison_set_name,

                NULL::TEXT AS showcase_id,
                NULL::TEXT AS showcase_name,

                NULL::TEXT AS baseline_module2_run_id,
                NULL::TEXT AS challenger_module2_run_id,

                module1_scenario_set_name,
                module1_scenario_name,
                population_id,

                NULL::TEXT AS baseline_strategy_set_name,
                NULL::TEXT AS baseline_strategy_name,
                NULL::TEXT AS baseline_strategy_version,

                NULL::TEXT AS challenger_strategy_set_name,
                NULL::TEXT AS challenger_strategy_name,
                NULL::TEXT AS challenger_strategy_version,

                NULL::BOOLEAN AS same_strategy_selected_flag,

                NULL::BIGINT AS baseline_archived_row_count,
                NULL::BIGINT AS challenger_archived_row_count,

                NULL::BIGINT AS baseline_distinct_application_id_count,
                NULL::BIGINT AS challenger_distinct_application_id_count,

                NULL::BIGINT AS baseline_duplicate_application_row_count,
                NULL::BIGINT AS challenger_duplicate_application_row_count,

                NULL::BIGINT AS matched_application_id_count,
                NULL::BIGINT AS baseline_only_application_id_count,
                NULL::BIGINT AS challenger_only_application_id_count,

                'NOT_APPLICABLE_SECTION_13_NOT_RUN'::TEXT AS readiness_status,

                NULL::TEXT AS expected_comparison_storyline,
                NULL::TEXT AS primary_metric_focus

            FROM latest_context
        $sql$;
    END IF;


    /*-------------------------------------------------------------------------------------------
    Optional source-consistency helper.

    If Section 13 has run, this table should already exist and should be left untouched.

    If Section 13 has not run, create a one-row NOT_APPLICABLE placeholder derived from the
    comparison-readiness helper.
    -------------------------------------------------------------------------------------------*/
    SELECT COALESCE(
        TO_REGCLASS('pg_temp.tmp_m2_strategy_comparison_source_consistency'),
        TO_REGCLASS('tmp_m2_strategy_comparison_source_consistency')
    ) IS NOT NULL
    INTO v_source_consistency_exists;

    IF v_source_consistency_exists IS DISTINCT FROM TRUE THEN
        EXECUTE $sql$
            CREATE TEMP TABLE tmp_m2_strategy_comparison_source_consistency
            ON COMMIT PRESERVE ROWS
            AS
            SELECT
                comparison_group_id,
                comparison_set_name,

                baseline_module2_run_id,
                challenger_module2_run_id,

                module1_scenario_set_name,
                module1_scenario_name,
                population_id,

                readiness_status,

                NULL::BIGINT AS matched_application_count,
                NULL::BIGINT AS source_field_mismatch_count,

                NULL::BIGINT AS product_type_mismatch_count,
                NULL::BIGINT AS score_band_mismatch_count,
                NULL::BIGINT AS credit_score_mismatch_count,
                NULL::BIGINT AS annual_income_mismatch_count,
                NULL::BIGINT AS requested_amount_mismatch_count,
                NULL::BIGINT AS requested_payment_mismatch_count,
                NULL::BIGINT AS requested_pti_mismatch_count,
                NULL::BIGINT AS amount_to_income_mismatch_count,
                NULL::BIGINT AS estimated_pd_mismatch_count,
                NULL::BIGINT AS estimated_lgd_mismatch_count,
                NULL::BIGINT AS requested_expected_loss_mismatch_count,
                NULL::BIGINT AS module1_lineage_mismatch_count,

                'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'::TEXT
                    AS source_consistency_status

            FROM tmp_m2_strategy_comparison_readiness
            LIMIT 1
        $sql$;
    END IF;
END $$;



/*-----------------------------------------------------------------------------------------------
14.18D Matched comparison readiness recap.

Business purpose:
    Display Section 13 comparison-readiness evidence inside the Section 14 validation package.

Credit risk interpretation:
    Matched strategy comparison should compare two archived Module 2 strategy slices on the same
    Module 1 scenario and population.

What to look for:
    readiness_status = READY_FOR_MATCHED_COMPARISON.

Review triggers:
    NOT_READY_* statuses should be reviewed before interpreting baseline / challenger deltas.

    NOT_APPLICABLE_SECTION_13_NOT_RUN means latest-run QA can proceed, but matched comparison evidence
    is not available in the current session.

SQL mechanics:
    This query reads tmp_m2_strategy_comparison_readiness.

    If Section 13 created it, the query displays real Section 13 readiness evidence.

    If Section 13 did not run, Section 14.18C created a NOT_APPLICABLE placeholder.
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,
    showcase_id,
    showcase_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    baseline_strategy_set_name,
    baseline_strategy_name,
    baseline_strategy_version,

    challenger_strategy_set_name,
    challenger_strategy_name,
    challenger_strategy_version,

    same_strategy_selected_flag,

    baseline_archived_row_count,
    challenger_archived_row_count,

    baseline_distinct_application_id_count,
    challenger_distinct_application_id_count,

    baseline_duplicate_application_row_count,
    challenger_duplicate_application_row_count,

    matched_application_id_count,
    baseline_only_application_id_count,
    challenger_only_application_id_count,

    readiness_status,
    expected_comparison_storyline,
    primary_metric_focus

FROM tmp_m2_strategy_comparison_readiness;



/*-----------------------------------------------------------------------------------------------
14.18E Matched source-field consistency recap.

Business purpose:
    Display Section 13 source-field consistency diagnostics inside Section 14.

Credit risk interpretation:
    Matched strategy comparison should isolate Module 2 strategy effects.

    If immutable Module 1 source fields differ between baseline and challenger rows, the comparison
    may reflect population drift, source-selection error, upstream scenario mismatch, or archive
    selection error rather than true Module 2 strategy movement.

Expected:
    source_consistency_status = SOURCE_FIELDS_MATCH when matched comparison is ready.

Review triggers:
    SOURCE_FIELD_MISMATCH_REVIEW_REQUIRED:
        Do not interpret strategy deltas as pure Module 2 strategy movement until the mismatch is
        reviewed.

    NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON:
        Comparison readiness was not established, so source consistency cannot be evaluated.

SQL mechanics:
    This query reads tmp_m2_strategy_comparison_source_consistency.

    If Section 13 created it, the query displays real source-field consistency evidence.

    If Section 13 did not run, Section 14.18C created a NOT_APPLICABLE placeholder.

Boundary:
    This query does not recalculate source fields or compare outcomes. It only reports the Section 13
    source-consistency diagnostic.
-----------------------------------------------------------------------------------------------*/

SELECT
    comparison_group_id,
    comparison_set_name,

    baseline_module2_run_id,
    challenger_module2_run_id,

    module1_scenario_set_name,
    module1_scenario_name,
    population_id,

    readiness_status,

    matched_application_count,
    source_field_mismatch_count,

    product_type_mismatch_count,
    score_band_mismatch_count,
    credit_score_mismatch_count,
    annual_income_mismatch_count,
    requested_amount_mismatch_count,
    requested_payment_mismatch_count,
    requested_pti_mismatch_count,
    amount_to_income_mismatch_count,
    estimated_pd_mismatch_count,
    estimated_lgd_mismatch_count,
    requested_expected_loss_mismatch_count,
    module1_lineage_mismatch_count,

    source_consistency_status

FROM tmp_m2_strategy_comparison_source_consistency;



/***************************************************************************************************
SECTION 14.19 — VALIDATION STATUS SUMMARY TABLE
****************************************************************************************************

BUSINESS PURPOSE:
    Materialize a compact validation status summary that can be consumed by Section 16 evidence
    capture and later documentation.

    Section 14.19 answers:

        "What is the compact validation status across the major latest-run QA areas, and which areas
         require interpretation before documentation?"

SQL PURPOSE:
    1. Create tmp_m2_validation_status_summary.
    2. Summarize latest-run structural integrity.
    3. Summarize decision outcome completeness.
    4. Summarize final flag reconciliation.
    5. Summarize simulated offer-exposure convention.
    6. Summarize approved amount convention.
    7. Summarize approved Expected Loss convention.
    8. Summarize reason-code completeness and reason-family alignment.
    9. Summarize prohibited terminology checks.
    10. Summarize product-level and score-band diagnostic patterns.
    11. Summarize synthetic risk ordering.
    12. Summarize affordability sensitivity.
    13. Summarize counteroffer, manual-review, decline, and mixed-signal diagnostics.
    14. Summarize archive persistence readiness.
    15. Summarize matched comparison readiness.
    16. Summarize matched source-field consistency.

TEMPORARY OUTPUT:
    tmp_m2_validation_status_summary

OUTPUT FIELDS:
    validation_area
    validation_test_name
    validation_category
    validation_status
    observed_value
    expected_behavior
    interpretation

VALIDATION STATUS VALUES:
    PASS:
        Structural or diagnostic expectation is satisfied.

    REVIEW:
        Pattern may be acceptable but should be interpreted before documentation.

    NOT_APPLICABLE:
        Test depends on unavailable archive slices, unavailable comparison parameters, unavailable
        comparison helpers, or non-applicable population conditions.

WHY ORDINARY DIAGNOSTICS DO NOT USE FAIL:
    Critical structural failures should already be handled by earlier fail-fast gatekeepers.

    Section 14.19 is an evidence summary, not an exception-handling layer.

    REVIEW means:
        "Interpret before documentation."

    REVIEW does not automatically mean:
        "The strategy output is invalid."

REVIEW THRESHOLDS USED IN THIS SECTION:
    Product outcome concentration review threshold:
        0.900000

        This means a product where one final outcome accounts for 90% or more of that product's rows
        should be interpreted before documentation.

    Reason-code concentration review threshold:
        0.500000

        This means one primary reason code representing more than 50% of the portfolio should be
        interpreted before documentation.

    Counteroffer concentration review threshold:
        0.350000

        This means counteroffers representing more than 35% of the portfolio should be interpreted
        because the strategy may be heavily dependent on reduced-exposure treatment.

    Manual-review concentration review threshold:
        0.250000

        This means manual reviews representing more than 25% of the portfolio should be interpreted
        because unresolved outcomes may create operational burden.

    Decline concentration review threshold:
        0.500000

        This means declines representing more than 50% of the portfolio should be interpreted,
        especially for non-tightening strategies.

    Mixed-signal / borderline concentration review threshold:
        0.300000

        This means edge-case populations representing more than 30% of the portfolio should be
        interpreted before documentation.

    These thresholds are diagnostic prompts only.

    They are not production policy limits, not regulatory thresholds, and not automatic acceptance or
    rejection criteria.

DOCUMENTATION ROLE:
    This temporary table becomes the validation evidence spine for:
        Section 16 evidence capture,
        future Validation Summary drafting,
        README result interpretation,
        LinkedIn story development,
        and executive review.

SQL CONCEPTS TAUGHT IN THIS SECTION:
    CREATE TEMP TABLE ... AS:
        Materializes the validation status summary as a session-scoped table.

    CTEs:
        Convert complex QA metrics into named, readable intermediate summaries.

    UNION ALL:
        Stacks individual validation rows into one evidence table.

    FORMAT:
        Converts observed metrics into readable text.

    CASE:
        Converts numeric diagnostics into PASS / REVIEW / NOT_APPLICABLE status labels.

    COALESCE:
        Handles missing optional context values safely.

    FILTER:
        Calculates conditional diagnostic counts.

BOUNDARY:
    Section 14.19 creates a temporary validation summary table only.

    It does not modify latest-run output.
    It does not modify archive output.
    It does not change thresholds.
    It does not change strategy parameters.
    It does not change product policy parameters.
    It does not recalculate decisions.
    It does not reassign reason codes.
    It does not recalculate approved exposure.
    It does not recalculate approved Expected Loss.

****************************************************************************************************/

DROP TABLE IF EXISTS tmp_m2_validation_status_summary;

CREATE TEMP TABLE tmp_m2_validation_status_summary
ON COMMIT PRESERVE ROWS
AS
WITH latest AS (
    /***********************************************************************************************
    CTE: latest

    Purpose:
        Build one compact metric row from the latest-run output.

    SQL mechanics:
        Most convention checks are calculated as COUNT(*) FILTER violation counts.

    Interpretation:
        Zero violation counts generally produce PASS rows in the validation summary.
    ***********************************************************************************************/
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT application_id) AS distinct_application_id_count,

        COUNT(*) - COUNT(DISTINCT application_id)
            AS duplicate_application_row_count,

        COUNT(DISTINCT (
            strategy_set_name,
            strategy_name,
            strategy_version
        )) AS distinct_strategy_version_count,

        COUNT(DISTINCT (
            module1_scenario_set_name,
            module1_scenario_name,
            population_id
        )) AS distinct_module1_scenario_population_count,

        COUNT(*) FILTER (
            WHERE decision_outcome IS NULL
               OR decision_outcome NOT IN ('APPROVE', 'COUNTEROFFER', 'MANUAL_REVIEW', 'DECLINE')
        ) AS invalid_decision_outcome_rows,

        COUNT(*) FILTER (
            WHERE (
                COALESCE(approval_flag::INT, 0)
                + COALESCE(counteroffer_flag::INT, 0)
                + COALESCE(manual_review_flag::INT, 0)
                + COALESCE(decline_flag::INT, 0)
            ) <> 1
        ) AS final_flag_count_violation_rows,

        COUNT(*) FILTER (
            WHERE approval_flag IS DISTINCT FROM (decision_outcome = 'APPROVE')
               OR counteroffer_flag IS DISTINCT FROM (decision_outcome = 'COUNTEROFFER')
               OR manual_review_flag IS DISTINCT FROM (decision_outcome = 'MANUAL_REVIEW')
               OR decline_flag IS DISTINCT FROM (decision_outcome = 'DECLINE')
        ) AS final_flag_alignment_violation_rows,

        COUNT(*) FILTER (
            WHERE simulated_offer_exposure_flag
                  IS DISTINCT FROM (decision_outcome IN ('APPROVE', 'COUNTEROFFER'))
        ) AS simulated_offer_exposure_flag_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND approved_amount IS DISTINCT FROM requested_amount
            )
            OR (
                    decision_outcome = 'COUNTEROFFER'
                AND (
                        approved_amount IS NULL
                     OR approved_amount <= 0
                     OR approved_amount >= requested_amount
                     OR counteroffer_amount IS DISTINCT FROM approved_amount
                )
            )
            OR (
                    decision_outcome = 'MANUAL_REVIEW'
                AND approved_amount IS NOT NULL
            )
            OR (
                    decision_outcome = 'DECLINE'
                AND approved_amount IS DISTINCT FROM 0::NUMERIC
            )
            OR (
                    approved_amount IS NOT NULL
                AND approved_amount < 0
            )
            OR (
                    approved_amount IS NOT NULL
                AND approved_amount > requested_amount
            )
        ) AS approved_amount_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND approved_expected_loss_amount IS DISTINCT FROM requested_expected_loss_amount
            )
            OR (
                    decision_outcome = 'COUNTEROFFER'
                AND (
                        approved_expected_loss_amount IS NULL
                     OR approved_expected_loss_amount < 0
                     OR approved_expected_loss_amount > requested_expected_loss_amount
                     OR approved_expected_loss_amount > product_approved_el_cap
                )
            )
            OR (
                    decision_outcome = 'MANUAL_REVIEW'
                AND approved_expected_loss_amount IS NOT NULL
            )
            OR (
                    decision_outcome = 'DECLINE'
                AND approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
            )
            OR (
                    approved_expected_loss_amount IS NOT NULL
                AND approved_expected_loss_amount < 0
            )
        ) AS approved_expected_loss_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE primary_reason_code IS NULL
               OR NULLIF(BTRIM(primary_reason_code), '') IS NULL
               OR primary_reason_family IS NULL
               OR NULLIF(BTRIM(primary_reason_family), '') IS NULL
               OR triggered_reason_code_list IS NULL
               OR NULLIF(BTRIM(triggered_reason_code_list), '') IS NULL
               OR reason_code_count IS NULL
               OR reason_code_count < 1
        ) AS reason_code_completeness_violation_rows,

        COUNT(*) FILTER (
            WHERE (
                    decision_outcome = 'APPROVE'
                AND primary_reason_family IS DISTINCT FROM 'APPROVAL'
            )
            OR (
                    decision_outcome = 'COUNTEROFFER'
                AND primary_reason_family IS DISTINCT FROM 'COUNTEROFFER'
            )
            OR (
                    decision_outcome = 'MANUAL_REVIEW'
                AND primary_reason_family IS DISTINCT FROM 'MANUAL_REVIEW'
            )
            OR (
                    decision_outcome = 'DECLINE'
                AND primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
            )
        ) AS reason_family_alignment_violation_rows,

        COUNT(*) FILTER (
            WHERE COALESCE(primary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%ADVERSE_ACTION%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%ADVERSE_ACTION%'

               OR COALESCE(primary_reason_code, '') ILIKE '%REGULATORY%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%REGULATORY%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%REGULATORY%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%REGULATORY%'

               OR COALESCE(primary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%CUSTOMER_NOTICE%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%CUSTOMER_NOTICE%'

               OR COALESCE(primary_reason_code, '') ILIKE '%FAIR_LENDING%'
               OR COALESCE(secondary_reason_code, '') ILIKE '%FAIR_LENDING%'
               OR COALESCE(tertiary_reason_code, '') ILIKE '%FAIR_LENDING%'
               OR COALESCE(triggered_reason_code_list, '') ILIKE '%FAIR_LENDING%'
        ) AS prohibited_reason_term_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'APPROVE') AS approval_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'COUNTEROFFER') AS counteroffer_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'MANUAL_REVIEW') AS manual_review_count,
        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE') AS decline_count,

        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS simulated_offer_exposure_count,

        COUNT(*) FILTER (WHERE preliminary_decision_outcome = 'COUNTEROFFER')
            AS preliminary_counteroffer_count,

        COUNT(*) FILTER (
            WHERE preliminary_decision_outcome = 'COUNTEROFFER'
              AND counteroffer_feasibility_pass_flag IS TRUE
        ) AS preliminary_counteroffer_feasible_count,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND (
                    counteroffer_feasibility_pass_flag IS DISTINCT FROM TRUE
                 OR approved_payment_to_income_ratio IS NULL
                 OR approved_payment_to_income_ratio > counteroffer_target_pti
                 OR approved_expected_loss_amount IS NULL
                 OR approved_expected_loss_amount > product_approved_el_cap
              )
        ) AS final_counteroffer_diagnostic_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'COUNTEROFFER'
              AND approved_payment_to_income_ratio >= requested_payment_to_income_ratio
        ) AS final_counteroffer_without_pti_improvement_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'MANUAL_REVIEW'
              AND (
                    approved_amount IS NOT NULL
                 OR approved_payment_to_income_ratio IS NOT NULL
                 OR approved_expected_loss_amount IS NOT NULL
              )
        ) AS manual_review_unresolved_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE decision_outcome = 'DECLINE'
              AND (
                    approved_amount IS DISTINCT FROM 0::NUMERIC
                 OR approved_payment_to_income_ratio IS DISTINCT FROM 0::NUMERIC
                 OR approved_expected_loss_amount IS DISTINCT FROM 0::NUMERIC
                 OR primary_reason_family IS DISTINCT FROM 'POLICY_STOP'
              )
        ) AS decline_policy_stop_convention_violation_rows,

        COUNT(*) FILTER (
            WHERE mixed_signal_profile_type IS NOT NULL
              AND mixed_signal_profile_type <> 'NO_MIXED_SIGNAL_PROFILE'
        ) AS mixed_signal_rows,

        COUNT(*) FILTER (WHERE borderline_profile_flag IS TRUE)
            AS borderline_rows

    FROM credit_decisioning_sim.strategy_decisions
),

product_outcome_distribution AS (
    /***********************************************************************************************
    CTE: product_outcome_distribution

    Purpose:
        Measure whether any product is dominated by one final outcome.

    Interpretation:
        High concentration is not automatically wrong, but it should be explained through product
        policy, score mix, affordability, exposure, Expected Loss, and reason-code patterns.
    ***********************************************************************************************/
    SELECT
        product_type_policy_key,
        decision_outcome,
        COUNT(*) AS row_count,
        COUNT(*)::NUMERIC
            / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY product_type_policy_key), 0)
            AS outcome_share_within_product
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY
        product_type_policy_key,
        decision_outcome
),

product_diagnostics AS (
    SELECT
        COUNT(DISTINCT product_type_policy_key) AS product_count,
        MAX(outcome_share_within_product) AS max_product_outcome_share,
        COUNT(*) FILTER (WHERE outcome_share_within_product >= 0.900000)
            AS high_product_outcome_concentration_group_count
    FROM product_outcome_distribution
),

score_rates AS (
    /***********************************************************************************************
    CTE: score_rates

    Purpose:
        Build score-band-level offer-exposure rates for directional score-band review.
    ***********************************************************************************************/
    SELECT
        score_band_policy_key,
        COUNT(*) AS applications,
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)::NUMERIC
            / NULLIF(COUNT(*), 0) AS simulated_offer_exposure_rate
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY score_band_policy_key
),

score_diagnostics AS (
    SELECT
        COUNT(*) AS score_band_count,

        MAX(simulated_offer_exposure_rate) FILTER (
            WHERE score_band_policy_key IN ('SUPER_PRIME', 'PRIME')
        ) AS strongest_score_offer_rate,

        MAX(simulated_offer_exposure_rate) FILTER (
            WHERE score_band_policy_key IN ('SUBPRIME', 'DEEP_SUBPRIME')
        ) AS weakest_score_offer_rate
    FROM score_rates
),

reason_distribution AS (
    /***********************************************************************************************
    CTE: reason_distribution

    Purpose:
        Calculate reason-code concentration across the full latest-run population.
    ***********************************************************************************************/
    SELECT
        primary_reason_code,
        COUNT(*) AS row_count,
        COUNT(*)::NUMERIC / NULLIF(SUM(COUNT(*)) OVER (), 0)
            AS reason_population_share
    FROM credit_decisioning_sim.strategy_decisions
    GROUP BY primary_reason_code
),

reason_diagnostics AS (
    SELECT
        MAX(reason_population_share) AS max_primary_reason_code_share,
        MAX(primary_reason_code) FILTER (
            WHERE reason_population_share = (
                SELECT MAX(reason_population_share)
                FROM reason_distribution
            )
        ) AS top_primary_reason_code
    FROM reason_distribution
),

risk_ordering AS (
    /***********************************************************************************************
    CTE: risk_ordering

    Purpose:
        Compare average synthetic estimated-PD proxy among offer rows versus declined rows.

    Interpretation:
        Offer rows should generally have lower or equal average synthetic estimated-PD proxy than
        declined rows.
    ***********************************************************************************************/
    SELECT
        COUNT(*) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS offer_rows,

        COUNT(*) FILTER (WHERE decision_outcome = 'DECLINE')
            AS decline_rows,

        AVG(estimated_pd) FILTER (WHERE simulated_offer_exposure_flag IS TRUE)
            AS avg_synthetic_estimated_pd_proxy_offer_rows,

        AVG(estimated_pd) FILTER (WHERE decision_outcome = 'DECLINE')
            AS avg_synthetic_estimated_pd_proxy_decline_rows
    FROM credit_decisioning_sim.strategy_decisions
),

affordability_sensitivity AS (
    /***********************************************************************************************
    CTE: affordability_sensitivity

    Purpose:
        Compare approval rates in low / moderate requested PTI buckets versus high / severe requested
        PTI buckets.
    ***********************************************************************************************/
    SELECT
        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
        ) AS low_or_moderate_requested_pti_rows,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
        ) AS high_or_severe_requested_pti_rows,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE requested_pti_bucket IN ('LOW_REQUESTED_PTI', 'MODERATE_REQUESTED_PTI')
            ),
            0
        ) AS low_or_moderate_requested_pti_approval_rate,

        COUNT(*) FILTER (
            WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
              AND decision_outcome = 'APPROVE'
        )::NUMERIC
        / NULLIF(
            COUNT(*) FILTER (
                WHERE requested_pti_bucket IN ('HIGH_REQUESTED_PTI', 'SEVERE_REQUESTED_PTI')
            ),
            0
        ) AS high_or_severe_requested_pti_approval_rate
    FROM credit_decisioning_sim.strategy_decisions
),

archive_readiness AS (
    SELECT *
    FROM tmp_m2_archive_readiness_context
    LIMIT 1
),

comparison_readiness AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_readiness
    LIMIT 1
),

source_consistency AS (
    SELECT *
    FROM tmp_m2_strategy_comparison_source_consistency
    LIMIT 1
)

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation

FROM (
    /***********************************************************************************************
    1. Latest-run structural integrity.
    ***********************************************************************************************/
    SELECT
        'Latest-run structural integrity'::TEXT AS validation_area,
        'Application grain and single-slice scope'::TEXT AS validation_test_name,
        'STRUCTURAL'::TEXT AS validation_category,
        CASE
            WHEN l.total_rows > 0
             AND l.total_rows = l.distinct_application_id_count
             AND l.distinct_strategy_version_count = 1
             AND l.distinct_module1_scenario_population_count = 1
                THEN 'PASS'
            ELSE 'REVIEW'
        END AS validation_status,
        FORMAT(
            'total_rows=%s; distinct_application_id_count=%s; duplicate_application_row_count=%s; distinct_strategy_version_count=%s; distinct_module1_scenario_population_count=%s',
            l.total_rows,
            l.distinct_application_id_count,
            l.duplicate_application_row_count,
            l.distinct_strategy_version_count,
            l.distinct_module1_scenario_population_count
        ) AS observed_value,
        'Latest-run output should contain rows, preserve one row per application_id, contain one Module 2 strategy identity, and contain one Module 1 scenario / population slice.'::TEXT
            AS expected_behavior,
        'Structural scope should be reviewed before interpreting any strategy behavior. Mixed scope or duplicate application_id values can distort all downstream QA outputs.'::TEXT
            AS interpretation
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    2. Decision outcome completeness.
    ***********************************************************************************************/
    SELECT
        'Decision outcome completeness',
        'Final decision_outcome validity',
        'OUTPUT_CONVENTION',
        CASE WHEN l.invalid_decision_outcome_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT('invalid_decision_outcome_rows=%s', l.invalid_decision_outcome_rows),
        'Every row should have decision_outcome populated as APPROVE, COUNTEROFFER, MANUAL_REVIEW, or DECLINE.',
        'Missing or invalid final outcomes prevent reliable decision distribution, exposure, reason-code, and evidence interpretation.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    3. Final flag reconciliation.
    ***********************************************************************************************/
    SELECT
        'Final flag reconciliation',
        'Final decision flags reconcile to decision_outcome',
        'OUTPUT_CONVENTION',
        CASE
            WHEN l.final_flag_count_violation_rows = 0
             AND l.final_flag_alignment_violation_rows = 0
                THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'final_flag_count_violation_rows=%s; final_flag_alignment_violation_rows=%s',
            l.final_flag_count_violation_rows,
            l.final_flag_alignment_violation_rows
        ),
        'Exactly one final decision flag should be TRUE per row and that flag should align to decision_outcome.',
        'Flag reconciliation protects the final four-outcome taxonomy from contradictory row-level labels.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    4. Simulated offer-exposure convention.
    ***********************************************************************************************/
    SELECT
        'Simulated offer-exposure convention',
        'simulated_offer_exposure_flag aligns to APPROVE and COUNTEROFFER',
        'OUTPUT_CONVENTION',
        CASE WHEN l.simulated_offer_exposure_flag_violation_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT(
            'simulated_offer_exposure_flag_violation_rows=%s; simulated_offer_exposure_count=%s',
            l.simulated_offer_exposure_flag_violation_rows,
            l.simulated_offer_exposure_count
        ),
        'simulated_offer_exposure_flag should be TRUE for APPROVE and COUNTEROFFER, and FALSE for MANUAL_REVIEW and DECLINE.',
        'This confirms that positive simulated offer exposure is consistently identified without implying booked or funded exposure.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    5. Approved amount convention.
    ***********************************************************************************************/
    SELECT
        'Approved amount convention',
        'Approved amount rules by final outcome',
        'OUTPUT_CONVENTION',
        CASE WHEN l.approved_amount_convention_violation_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT('approved_amount_convention_violation_rows=%s', l.approved_amount_convention_violation_rows),
        'APPROVE preserves requested amount; COUNTEROFFER reduces exposure; MANUAL_REVIEW remains NULL; DECLINE equals zero.',
        'Approved exposure convention failures are stronger than ordinary diagnostic review items because they can indicate broken final output economics.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    6. Approved Expected Loss convention.
    ***********************************************************************************************/
    SELECT
        'Approved Expected Loss convention',
        'Approved Expected Loss rules by final outcome',
        'OUTPUT_CONVENTION',
        CASE WHEN l.approved_expected_loss_convention_violation_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT(
            'approved_expected_loss_convention_violation_rows=%s',
            l.approved_expected_loss_convention_violation_rows
        ),
        'APPROVE approved EL equals requested EL; COUNTEROFFER approved EL is non-negative and not above requested EL or product cap; MANUAL_REVIEW remains NULL; DECLINE equals zero.',
        'This confirms that approved_expected_loss_amount remains approved-exposure Expected Loss, not requested-exposure Expected Loss.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    7. Reason-code completeness.
    ***********************************************************************************************/
    SELECT
        'Reason-code completeness',
        'Required simulated reason-code fields are populated',
        'EXPLAINABILITY',
        CASE WHEN l.reason_code_completeness_violation_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT('reason_code_completeness_violation_rows=%s', l.reason_code_completeness_violation_rows),
        'Every row should have primary_reason_code, primary_reason_family, triggered_reason_code_list, and reason_code_count >= 1.',
        'Every final simulated outcome should be explainable before documentation or evidence capture.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    8. Reason-code family alignment.
    ***********************************************************************************************/
    SELECT
        'Reason-code family alignment',
        'Primary reason family aligns to final outcome',
        'EXPLAINABILITY',
        CASE WHEN l.reason_family_alignment_violation_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT('reason_family_alignment_violation_rows=%s', l.reason_family_alignment_violation_rows),
        'APPROVE → APPROVAL; COUNTEROFFER → COUNTEROFFER; MANUAL_REVIEW → MANUAL_REVIEW; DECLINE → POLICY_STOP.',
        'Reason-family alignment protects the interpretation of simulated strategy explanation codes.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    9. Prohibited terminology check.
    ***********************************************************************************************/
    SELECT
        'Prohibited terminology check',
        'Reason-code fields avoid external-communication terminology',
        'BOUNDARY_CONTROL',
        CASE WHEN l.prohibited_reason_term_rows = 0 THEN 'PASS' ELSE 'REVIEW' END,
        FORMAT('prohibited_reason_term_rows=%s', l.prohibited_reason_term_rows),
        'Reason-code fields should not contain ADVERSE_ACTION, REGULATORY, CUSTOMER_NOTICE, or FAIR_LENDING.',
        'Simulated strategy explanation codes should not imply customer notices, regulatory conclusions, adverse-action reasons, or fair-lending conclusions.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    10. Product-level strategy distribution.
    ***********************************************************************************************/
    SELECT
        'Product-level strategy distribution',
        'Product outcome concentration review',
        'DIAGNOSTIC',
        CASE
            WHEN p.product_count IS NULL OR p.product_count = 0
                THEN 'NOT_APPLICABLE'
            WHEN p.high_product_outcome_concentration_group_count > 0
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'product_count=%s; max_product_outcome_share=%s; high_product_outcome_concentration_group_count=%s',
            COALESCE(p.product_count, 0),
            COALESCE(ROUND(p.max_product_outcome_share, 6)::TEXT, '<NULL>'),
            COALESCE(p.high_product_outcome_concentration_group_count, 0)
        ),
        'Product-level outcome concentration should be explainable through product policy, score mix, affordability, exposure, Expected Loss, and reason-code patterns.',
        'A product dominated by one outcome is not automatically invalid, but product-level concentration should be interpreted before documentation.'
    FROM product_diagnostics p

    UNION ALL

    /***********************************************************************************************
    11. Score-band strategy distribution.
    ***********************************************************************************************/
    SELECT
        'Score-band strategy distribution',
        'Directional offer-exposure ordering by score band',
        'DIAGNOSTIC',
        CASE
            WHEN s.strongest_score_offer_rate IS NULL
              OR s.weakest_score_offer_rate IS NULL
                THEN 'NOT_APPLICABLE'
            WHEN s.weakest_score_offer_rate > s.strongest_score_offer_rate
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'score_band_count=%s; strongest_score_offer_rate=%s; weakest_score_offer_rate=%s',
            COALESCE(s.score_band_count, 0),
            COALESCE(ROUND(s.strongest_score_offer_rate, 6)::TEXT, '<NULL>'),
            COALESCE(ROUND(s.weakest_score_offer_rate, 6)::TEXT, '<NULL>')
        ),
        'Stronger score bands should generally have simulated offer-exposure rates at or above weaker score bands, subject to realistic overlap.',
        'Score-band exceptions may be valid, but they should be explained through product mix, affordability, DTI, exposure, and reason-code patterns.'
    FROM score_diagnostics s

    UNION ALL

    /***********************************************************************************************
    12. Synthetic risk ordering.
    ***********************************************************************************************/
    SELECT
        'Synthetic risk ordering',
        'Offered versus declined synthetic estimated-risk proxy comparison',
        'DIAGNOSTIC',
        CASE
            WHEN r.offer_rows = 0 OR r.decline_rows = 0
                THEN 'NOT_APPLICABLE'
            WHEN r.avg_synthetic_estimated_pd_proxy_offer_rows
              <= r.avg_synthetic_estimated_pd_proxy_decline_rows
                THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'offer_rows=%s; decline_rows=%s; avg_offer_estimated_pd=%s; avg_decline_estimated_pd=%s',
            r.offer_rows,
            r.decline_rows,
            COALESCE(ROUND(r.avg_synthetic_estimated_pd_proxy_offer_rows, 6)::TEXT, '<NULL>'),
            COALESCE(ROUND(r.avg_synthetic_estimated_pd_proxy_decline_rows, 6)::TEXT, '<NULL>')
        ),
        'Average synthetic estimated-PD proxy should generally be lower among simulated offer-exposure rows than declined rows.',
        'This is directional risk-ordering evidence only; it is not calibrated model validation.'
    FROM risk_ordering r

    UNION ALL

    /***********************************************************************************************
    13. Affordability sensitivity.
    ***********************************************************************************************/
    SELECT
        'Affordability sensitivity',
        'Requested PTI approval-rate sensitivity',
        'DIAGNOSTIC',
        CASE
            WHEN a.low_or_moderate_requested_pti_rows = 0
              OR a.high_or_severe_requested_pti_rows = 0
                THEN 'NOT_APPLICABLE'
            WHEN a.high_or_severe_requested_pti_approval_rate
              <= a.low_or_moderate_requested_pti_approval_rate
                THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'low_or_moderate_pti_rows=%s; high_or_severe_pti_rows=%s; low_or_moderate_approval_rate=%s; high_or_severe_approval_rate=%s',
            a.low_or_moderate_requested_pti_rows,
            a.high_or_severe_requested_pti_rows,
            COALESCE(ROUND(a.low_or_moderate_requested_pti_approval_rate, 6)::TEXT, '<NULL>'),
            COALESCE(ROUND(a.high_or_severe_requested_pti_approval_rate, 6)::TEXT, '<NULL>')
        ),
        'High / severe requested PTI approval rate should generally be less than or equal to low / moderate requested PTI approval rate.',
        'Affordability exceptions should be interpreted through product mix, score mix, income, DTI, exposure, and reason-code patterns.'
    FROM affordability_sensitivity a

    UNION ALL

    /***********************************************************************************************
    14. Counteroffer diagnostics — convention.
    ***********************************************************************************************/
    SELECT
        'Counteroffer diagnostics',
        'Final counteroffer feasibility and affordability conventions',
        'DIAGNOSTIC',
        CASE
            WHEN l.counteroffer_count = 0
                THEN 'NOT_APPLICABLE'
            WHEN l.final_counteroffer_diagnostic_violation_rows = 0
             AND l.final_counteroffer_without_pti_improvement_rows = 0
                THEN 'PASS'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'final_counteroffer_rows=%s; preliminary_counteroffer_rows=%s; feasible_preliminary_counteroffers=%s; final_counteroffer_diagnostic_violation_rows=%s; final_counteroffer_without_pti_improvement_rows=%s',
            l.counteroffer_count,
            l.preliminary_counteroffer_count,
            l.preliminary_counteroffer_feasible_count,
            l.final_counteroffer_diagnostic_violation_rows,
            l.final_counteroffer_without_pti_improvement_rows
        ),
        'Final COUNTEROFFER rows should pass feasibility, reduce exposure, improve or respect affordability, and satisfy approved Expected Loss constraints.',
        'Counteroffer diagnostics help confirm that counteroffer is a governed reduced-exposure treatment, not just a label.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    14b. Counteroffer diagnostics — concentration.
    ***********************************************************************************************/
    SELECT
        'Counteroffer diagnostics',
        'Counteroffer concentration review',
        'DIAGNOSTIC',
        CASE
            WHEN l.total_rows = 0
                THEN 'NOT_APPLICABLE'
            WHEN l.counteroffer_count::NUMERIC / NULLIF(l.total_rows, 0) > 0.350000
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'counteroffer_count=%s; total_rows=%s; counteroffer_rate=%s',
            l.counteroffer_count,
            l.total_rows,
            COALESCE(ROUND(l.counteroffer_count::NUMERIC / NULLIF(l.total_rows, 0), 6)::TEXT, '<NULL>')
        ),
        'Counteroffer concentration above 35% should be interpreted as a diagnostic prompt.',
        'High counteroffer concentration may be valid, but it should be explained through product caps, affordability pressure, approved Expected Loss caps, or counteroffer-first strategy posture.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    15. Manual-review diagnostics.
    ***********************************************************************************************/
    SELECT
        'Manual-review diagnostics',
        'Manual-review unresolved convention and concentration',
        'DIAGNOSTIC',
        CASE
            WHEN l.manual_review_unresolved_convention_violation_rows > 0
                THEN 'REVIEW'
            WHEN l.total_rows > 0
             AND l.manual_review_count::NUMERIC / NULLIF(l.total_rows, 0) > 0.250000
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'manual_review_count=%s; manual_review_rate=%s; manual_review_unresolved_convention_violation_rows=%s',
            l.manual_review_count,
            COALESCE(ROUND(l.manual_review_count::NUMERIC / NULLIF(l.total_rows, 0), 6)::TEXT, '<NULL>'),
            l.manual_review_unresolved_convention_violation_rows
        ),
        'MANUAL_REVIEW should remain unresolved with NULL approved exposure, NULL approved PTI, and NULL approved Expected Loss. High manual-review rates should be interpreted as possible operational burden.',
        'Manual review is not a completed operational review; it is an unresolved simulated strategy outcome.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    16. Decline / policy-stop diagnostics.
    ***********************************************************************************************/
    SELECT
        'Decline / policy-stop diagnostics',
        'Decline zero-exposure and policy-stop reason convention',
        'DIAGNOSTIC',
        CASE
            WHEN l.decline_policy_stop_convention_violation_rows > 0
                THEN 'REVIEW'
            WHEN l.total_rows > 0
             AND l.decline_count::NUMERIC / NULLIF(l.total_rows, 0) > 0.500000
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'decline_count=%s; decline_rate=%s; decline_policy_stop_convention_violation_rows=%s',
            l.decline_count,
            COALESCE(ROUND(l.decline_count::NUMERIC / NULLIF(l.total_rows, 0), 6)::TEXT, '<NULL>'),
            l.decline_policy_stop_convention_violation_rows
        ),
        'DECLINE should have zero approved exposure, zero approved Expected Loss, and POLICY_STOP reason family.',
        'High decline concentration may be expected under tighter strategies, but it should be explained through policy-stop reason codes and strategy posture.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    17. Mixed-signal and edge-case diagnostics.
    ***********************************************************************************************/
    SELECT
        'Mixed-signal and edge-case diagnostics',
        'Mixed-signal and borderline concentration review',
        'DIAGNOSTIC',
        CASE
            WHEN l.total_rows = 0
                THEN 'NOT_APPLICABLE'
            WHEN l.mixed_signal_rows::NUMERIC / NULLIF(l.total_rows, 0) > 0.300000
              OR l.borderline_rows::NUMERIC / NULLIF(l.total_rows, 0) > 0.300000
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'mixed_signal_rows=%s; mixed_signal_rate=%s; borderline_rows=%s; borderline_rate=%s',
            l.mixed_signal_rows,
            COALESCE(ROUND(l.mixed_signal_rows::NUMERIC / NULLIF(l.total_rows, 0), 6)::TEXT, '<NULL>'),
            l.borderline_rows,
            COALESCE(ROUND(l.borderline_rows::NUMERIC / NULLIF(l.total_rows, 0), 6)::TEXT, '<NULL>')
        ),
        'Mixed-signal and borderline cases should remain visible, bounded, and explainable.',
        'Realistic overlap is not automatically a defect; high concentration should be interpreted before documentation.'
    FROM latest l

    UNION ALL

    /***********************************************************************************************
    18. Archive persistence readiness.
    ***********************************************************************************************/
    SELECT
        'Archive persistence readiness',
        'Current latest-run slice archived at expected grain',
        'READINESS',
        CASE
            WHEN ar.archive_readiness_status LIKE 'PASS_%'
                THEN 'PASS'
            WHEN ar.archive_readiness_status LIKE 'NOT_APPLICABLE_%'
                THEN 'NOT_APPLICABLE'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'archive_readiness_status=%s; latest_run_row_count=%s; archived_row_count=%s; latest_distinct_application_id_count=%s; archived_distinct_application_id_count=%s',
            COALESCE(ar.archive_readiness_status, '<NULL>'),
            COALESCE(ar.latest_run_row_count::TEXT, '<NULL>'),
            COALESCE(ar.archived_row_count::TEXT, '<NULL>'),
            COALESCE(ar.latest_run_distinct_application_id_count::TEXT, '<NULL>'),
            COALESCE(ar.archived_distinct_application_id_count::TEXT, '<NULL>')
        ),
        'For formal archived runs, current latest-run slice should be present in archive with matching row count and distinct application_id count.',
        'Archive readiness supports matched comparison, frontier review, and evidence traceability. NOT_APPLICABLE can be acceptable for development runs or non-archived runs.'
    FROM archive_readiness ar

    UNION ALL

    /***********************************************************************************************
    19. Matched strategy comparison readiness.
    ***********************************************************************************************/
    SELECT
        'Matched strategy comparison readiness',
        'Selected baseline / challenger comparison readiness',
        'COMPARISON',
        CASE
            WHEN cr.readiness_status = 'READY_FOR_MATCHED_COMPARISON'
                THEN 'PASS'
            WHEN cr.readiness_status LIKE 'NOT_APPLICABLE_%'
                THEN 'NOT_APPLICABLE'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'readiness_status=%s; matched_application_id_count=%s; baseline_only_application_id_count=%s; challenger_only_application_id_count=%s',
            COALESCE(cr.readiness_status, '<NULL>'),
            COALESCE(cr.matched_application_id_count::TEXT, '<NULL>'),
            COALESCE(cr.baseline_only_application_id_count::TEXT, '<NULL>'),
            COALESCE(cr.challenger_only_application_id_count::TEXT, '<NULL>')
        ),
        'Selected baseline and challenger should be archived, same-scenario, same-population, application_id matched, and free from duplicate archive grain.',
        'If comparison is not ready, latest-run QA may still be valid, but baseline / challenger deltas should not be interpreted as final evidence.'
    FROM comparison_readiness cr

    UNION ALL

    /***********************************************************************************************
    20. Matched source-field consistency.
    ***********************************************************************************************/
    SELECT
        'Matched source-field consistency',
        'Immutable Module 1 source fields match across matched comparison rows',
        'COMPARISON',
        CASE
            WHEN sc.source_consistency_status = 'SOURCE_FIELDS_MATCH'
                THEN 'PASS'
            WHEN sc.source_consistency_status = 'NOT_APPLICABLE_NOT_READY_FOR_MATCHED_COMPARISON'
                THEN 'NOT_APPLICABLE'
            ELSE 'REVIEW'
        END,
        FORMAT(
            'source_consistency_status=%s; matched_application_count=%s; source_field_mismatch_count=%s; product_type_mismatch_count=%s; score_band_mismatch_count=%s; estimated_pd_mismatch_count=%s; requested_expected_loss_mismatch_count=%s; module1_lineage_mismatch_count=%s',
            COALESCE(sc.source_consistency_status, '<NULL>'),
            COALESCE(sc.matched_application_count::TEXT, '<NULL>'),
            COALESCE(sc.source_field_mismatch_count::TEXT, '<NULL>'),
            COALESCE(sc.product_type_mismatch_count::TEXT, '<NULL>'),
            COALESCE(sc.score_band_mismatch_count::TEXT, '<NULL>'),
            COALESCE(sc.estimated_pd_mismatch_count::TEXT, '<NULL>'),
            COALESCE(sc.requested_expected_loss_mismatch_count::TEXT, '<NULL>'),
            COALESCE(sc.module1_lineage_mismatch_count::TEXT, '<NULL>')
        ),
        'Matched baseline and challenger rows should share immutable Module 1 source fields so comparison isolates Module 2 strategy effects.',
        'Source-field mismatch means strategy deltas may reflect source-selection or archive-selection issues rather than pure downstream strategy movement.'
    FROM source_consistency sc

    UNION ALL

    /***********************************************************************************************
    21. Reason-code concentration.
    ***********************************************************************************************/
    SELECT
        'Reason-code concentration',
        'Primary reason-code concentration review',
        'DIAGNOSTIC',
        CASE
            WHEN rd.max_primary_reason_code_share IS NULL
                THEN 'NOT_APPLICABLE'
            WHEN rd.max_primary_reason_code_share > 0.500000
                THEN 'REVIEW'
            ELSE 'PASS'
        END,
        FORMAT(
            'top_primary_reason_code=%s; max_primary_reason_code_share=%s',
            COALESCE(rd.top_primary_reason_code, '<NULL>'),
            COALESCE(ROUND(rd.max_primary_reason_code_share, 6)::TEXT, '<NULL>')
        ),
        'No single primary reason code should dominate the output without interpretation. The 50% threshold is a diagnostic review prompt only.',
        'High reason-code concentration may be valid under focused strategies, but it should be explained through strategy design and portfolio mix.'
    FROM reason_diagnostics rd

) validation_rows;



/*-----------------------------------------------------------------------------------------------
14.19A Display final compact validation status summary.

Business purpose:
    Present the validation status summary in reviewer-friendly order.

What to look for:
    REVIEW rows first:
        These are the items to interpret before documentation.

    NOT_APPLICABLE rows second:
        These usually relate to missing or non-ready archive / comparison context.

    PASS rows last:
        These confirm satisfied expectations.

SQL mechanics:
    ORDER BY uses CASE to sort statuses by review priority rather than alphabetically.

Documentation use:
    This output is the compact validation evidence spine that Section 16 can persist and later
    documentation can cite.
-----------------------------------------------------------------------------------------------*/

SELECT
    validation_area,
    validation_test_name,
    validation_category,
    validation_status,
    observed_value,
    expected_behavior,
    interpretation
FROM tmp_m2_validation_status_summary
ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        WHEN 'PASS' THEN 3
        ELSE 99
    END,
    validation_area,
    validation_test_name;



/*-----------------------------------------------------------------------------------------------
14.19B Validation status distribution.

Business purpose:
    Provide a compact count of PASS, REVIEW, and NOT_APPLICABLE validation summary rows.

What to look for:
    PASS:
        satisfied validation expectations.

    REVIEW:
        items requiring interpretation before documentation.

    NOT_APPLICABLE:
        tests that depend on unavailable or non-ready comparison / archive context.

SQL mechanics:
    GROUP BY validation_status counts the number of tests in each status.

Documentation use:
    This is useful for executive QA rollups and Section 16 evidence capture.
-----------------------------------------------------------------------------------------------*/

SELECT
    validation_status,
    COUNT(*) AS validation_test_count
FROM tmp_m2_validation_status_summary
GROUP BY validation_status
ORDER BY
    CASE validation_status
        WHEN 'REVIEW' THEN 1
        WHEN 'NOT_APPLICABLE' THEN 2
        WHEN 'PASS' THEN 3
        ELSE 99
    END;



/***************************************************************************************************
END OF SECTION 14 — MODULE 2 VALIDATION, QA, AND STRATEGY OUTCOME DIAGNOSTICS

If execution reaches this point:
    1. Final output conventions have been tested through diagnostic violation counts.
    2. Archive readiness has been summarized in tmp_m2_archive_readiness_context.
    3. Matched comparison readiness has been displayed or labeled NOT_APPLICABLE.
    4. Matched source-field consistency has been displayed or labeled NOT_APPLICABLE.
    5. tmp_m2_validation_status_summary exists.
    6. tmp_m2_validation_status_summary contains compact PASS / REVIEW / NOT_APPLICABLE evidence.
    7. Section 16 can consume tmp_m2_validation_status_summary for persistent evidence capture.

No latest-run output rows have been modified.
No archive rows have been modified.
No strategy parameter rows have been modified.
No product policy parameter rows have been modified.
No decision outcomes have been recalculated.
No simulated reason codes have been reassigned.
No approved exposure has been recalculated.
No approved Expected Loss has been recalculated.
No BRD or Validation Summary documentation has been drafted.

Next section:
    Section 15 should create the archive-backed strategy frontier summary and executive comparison
    view, and Section 16 should later persist validation and executive evidence for the completed run.

***************************************************************************************************/
```
<!-- END_MESSAGE C038-M00998 -->


---

<a id="c038-m00999"></a>

### C038-M00999

**Andrew** · 2026-05-10T09:56:54.510000-04:00 · active path

<!-- BEGIN_MESSAGE C038-M00999 -->
let's do one more pass for commentary. Please note that besides the headers we want instructional commentary that details how the sql logic is working. the commentary/headers are supposed to do 3 main things: 1) Advise on the who/what/why/how to run and interpret the code and parameters; 2) teach the credit risk concepts and nuts and bolts; 3) teach how the sql logic is working. folks going through this code should not only understand how to use/interpret but also should learn about credit risk analytics and SQL. this is the elite level we are striving for. besides header comments, we expect in line comments explaining the sql logic and line by line process. here is the section 15 again. if suggested changes, return the full copy paste of those sections in one copy paste block.
<!-- END_MESSAGE C038-M00999 -->


**Attachments in export:** `Pasted text(158).txt`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_53.md) · [Next](Part_55.md)
