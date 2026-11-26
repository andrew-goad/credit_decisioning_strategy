-- Andrew Goad | Original credit decisioning campaign | DBeaver read-only export
-- Connect to the original PostgreSQL campaign database. This single SELECT makes no changes.
-- Export the entire query result (all rows, no result limit) as UTF-8 CSV with a header.
-- Keep NULL as an empty field, decimal point '.', no number grouping. Do not use the clipboard.
-- The 39 identities below come from the original archive and parameter snapshots at Git 65e7cc8.
-- Use the saved execution time for every run. If M2-01 is absent, use its one approved refresh
-- only when its published May 28 UTC millisecond identifies exactly one physical execution.
-- Retain the selected execution time to six digits. An unresolved baseline returns no export rows.
-- Timestamps crossing the output boundary are UTC. Synthetic IDs repeat across runs by design.
-- Expected: 1,950,000 records, 50,000 application IDs, 39 original runs.
WITH pinned(module2_run_id, strategy_run_id, utc_execution_time) AS (VALUES
    ('M2-01', 'M2-01_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T03:12:23.669632+00:00'),
    ('M2-02', 'M2-02_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN', '2026-05-20T03:29:27.529789+00:00'),
    ('M2-03', 'M2-03_GROWTH_ORIENTED_STRATEGY_V1_0_RUN', '2026-05-20T03:55:37.514212+00:00'),
    ('M2-04', 'M2-04_TIGHTER_AFFORDABILITY_STRATEGY_V1_0_RUN', '2026-05-20T04:11:55.358650+00:00'),
    ('M2-05', 'M2-05_SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY_V1_0_RUN', '2026-05-20T04:25:53.981743+00:00'),
    ('M2-06', 'M2-06_PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY_V1_0_RUN', '2026-05-20T04:34:54.938901+00:00'),
    ('M2-07', 'M2-07_MANUAL_REVIEW_REDUCTION_STRATEGY_V1_0_RUN', '2026-05-20T04:44:40.457578+00:00'),
    ('M2-08', 'M2-08_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T04:53:23.462261+00:00'),
    ('M2-09', 'M2-09_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T05:03:36.315002+00:00'),
    ('M2-10', 'M2-10_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T05:11:48.755833+00:00'),
    ('M2-11', 'M2-11_TIGHTER_AFFORDABILITY_STRATEGY_V1_0_RUN', '2026-05-20T05:20:15.119708+00:00'),
    ('M2-12', 'M2-12_TIGHTER_AFFORDABILITY_STRATEGY_V1_0_RUN', '2026-05-20T05:30:46.091243+00:00'),
    ('M2-13', 'M2-13_GROWTH_ORIENTED_STRATEGY_V1_0_RUN', '2026-05-20T05:39:50.146818+00:00'),
    ('M2-14', 'M2-14_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T05:49:37.420892+00:00'),
    ('M2-15', 'M2-15_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T05:58:52.434469+00:00'),
    ('M2-16', 'M2-16_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T06:08:16.576190+00:00'),
    ('M2-17', 'M2-17_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN', '2026-05-20T11:57:29.377804+00:00'),
    ('M2-18', 'M2-18_SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY_V1_0_RUN', '2026-05-20T12:11:20.364845+00:00'),
    ('M2-19', 'M2-19_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T12:29:02.535772+00:00'),
    ('M2-20', 'M2-20_TIGHTER_SYNTHETIC_RISK_STRATEGY_V1_0_RUN', '2026-05-20T12:41:03.014996+00:00'),
    ('M2-21', 'M2-21_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T12:57:08.060115+00:00'),
    ('M2-22', 'M2-22_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T13:07:32.702595+00:00'),
    ('M2-23', 'M2-23_PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY_V1_0_RUN', '2026-05-20T13:17:23.972129+00:00'),
    ('M2-24', 'M2-24_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T13:28:41.862159+00:00'),
    ('M2-25', 'M2-25_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T13:43:42.048283+00:00'),
    ('M2-26', 'M2-26_PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY_V1_0_RUN', '2026-05-20T13:55:27.311456+00:00'),
    ('M2-27', 'M2-27_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T14:06:48.378795+00:00'),
    ('M2-28', 'M2-28_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T19:01:01.755398+00:00'),
    ('M2-29', 'M2-29_SELECTIVE_COUNTEROFFER_FEASIBILITY_STRATEGY_V1_0_RUN', '2026-05-20T19:10:59.814251+00:00'),
    ('M2-30', 'M2-30_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T19:23:01.673551+00:00'),
    ('M2-31', 'M2-31_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T19:33:48.542340+00:00'),
    ('M2-32', 'M2-32_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T19:45:19.674492+00:00'),
    ('M2-33', 'M2-33_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T19:58:00.708560+00:00'),
    ('M2-34', 'M2-34_PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY_V1_0_RUN', '2026-05-20T23:09:04.851196+00:00'),
    ('M2-35', 'M2-35_BASELINE_STRATEGY_V1_0_RUN', '2026-05-20T23:22:47.543974+00:00'),
    ('M2-36', 'M2-36_PRODUCT_SPECIFIC_GUARDRAIL_STRATEGY_V1_0_RUN', '2026-05-20T23:51:39.771279+00:00'),
    ('M2-37', 'M2-37_AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY_V1_0_RUN', '2026-05-21T00:13:30.041970+00:00'),
    ('M2-38', 'M2-38_AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY_V1_0_RUN', '2026-05-21T00:29:32.928617+00:00'),
    ('M2-39', 'M2-39_AGGRESSIVE_COUNTEROFFER_EXPANSION_STRATEGY_V1_0_RUN', '2026-05-21T02:38:29.186844+00:00')
),
-- BEGIN ORIGINAL CAMPAIGN RUN RESOLUTION
baseline_candidates AS MATERIALIZED (
    SELECT DISTINCT a.strategy_run_ts
    FROM credit_decisioning_sim.strategy_decisions_archive AS a
    WHERE a.strategy_run_id = 'M2-01_BASELINE_STRATEGY_V1_0_RUN'
      AND (a.strategy_run_ts = TIMESTAMPTZ '2026-05-20 03:12:23.669632+00'
           OR (a.strategy_run_ts >= TIMESTAMPTZ '2026-05-28 12:40:03.698000+00'
               AND a.strategy_run_ts < TIMESTAMPTZ '2026-05-28 12:40:03.699000+00'))
),
baseline_authority AS (
    SELECT CASE
             WHEN bool_or(strategy_run_ts = TIMESTAMPTZ '2026-05-20 03:12:23.669632+00')
               THEN TIMESTAMPTZ '2026-05-20 03:12:23.669632+00'
             WHEN count(*) = 1 THEN min(strategy_run_ts)
           END AS selected_ts
    FROM baseline_candidates
),
expected AS (
    SELECT p.module2_run_id, p.strategy_run_id,
           p.utc_execution_time::timestamptz AS original_ts,
           CASE WHEN p.module2_run_id = 'M2-01' THEN b.selected_ts
                ELSE p.utc_execution_time::timestamptz END AS utc_execution_time
    FROM pinned AS p CROSS JOIN baseline_authority AS b
)
-- END ORIGINAL CAMPAIGN RUN RESOLUTION
SELECT
    'ORIGINAL_FULL_DBEAVER_CAMPAIGN' AS sample_reason,
    e.module2_run_id,
    a.strategy_set_name,
    a.strategy_name,
    a.strategy_version,
    a.strategy_run_id,
    to_char(a.strategy_run_ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US') || '+00:00' AS strategy_run_ts,
    a.module1_scenario_set_name,
    a.module1_scenario_name,
    a.population_id,
    a.application_id,
    a.applicant_id,
    to_char(a.application_date, 'YYYY-MM-DD') AS application_date,
    a.product_type,
    a.score_band,
    a.credit_score,
    a.annual_income,
    a.debt_to_income_ratio,
    a.requested_amount,
    a.requested_monthly_payment_proxy,
    a.requested_payment_to_income_ratio,
    a.estimated_pd,
    a.estimated_lgd,
    a.requested_expected_loss_amount,
    a.decision_outcome,
    a.decision_path,
    a.decision_resolution_source,
    a.approval_flag::text AS approval_flag,
    a.counteroffer_flag::text AS counteroffer_flag,
    a.manual_review_flag::text AS manual_review_flag,
    a.decline_flag::text AS decline_flag,
    a.simulated_offer_exposure_flag::text AS simulated_offer_exposure_flag,
    a.approved_amount,
    a.counteroffer_amount,
    a.exposure_reduction_amount,
    a.exposure_reduction_pct,
    a.approved_monthly_payment_proxy,
    a.approved_payment_to_income_ratio,
    a.approved_expected_loss_amount,
    a.approved_el_reduction_amount,
    a.approved_el_reduction_pct,
    a.counteroffer_strategy_variant,
    a.ordinary_counteroffer_candidate_flag::text AS ordinary_counteroffer_candidate_flag,
    a.aggressive_counteroffer_requested_structure_override_flag::text AS aggressive_counteroffer_requested_structure_override_flag,
    a.primary_reason_code,
    a.secondary_reason_code,
    a.tertiary_reason_code,
    a.primary_reason_family,
    a.reason_code_count
FROM credit_decisioning_sim.strategy_decisions_archive AS a
JOIN expected AS e ON a.strategy_run_id = e.strategy_run_id
 AND a.strategy_run_ts = e.utc_execution_time::timestamptz
WHERE (SELECT selected_ts FROM baseline_authority) IS NOT NULL
ORDER BY a.application_id, e.module2_run_id;
