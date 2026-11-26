-- Original campaign teaching case discovery. Execute as one read-only SELECT in DBeaver.
-- Counts are per question and registered policy pair. Up to four product/score-diverse examples.
-- Use the exact original executions, or the single approved M2-01 refresh if the original is absent.
-- Missing or ambiguous baseline identity leaves the affected pairs unavailable.
-- Use an uncapped results grid. Every registered pair and lesson returns at least one row.
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
,
pairs(pair_id, base_run, test_run, scene_set, scene, population) AS (VALUES
    ('CG01', 'M2-01', 'M2-02', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG02', 'M2-01', 'M2-03', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG03', 'M2-01', 'M2-04', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG04', 'M2-01', 'M2-05', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG05', 'M2-01', 'M2-06', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG06', 'M2-01', 'M2-07', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG07', 'M2-08', 'M2-11', 'MODULE1_V2_BASELINE_SET', 'RATE_UP_200BP', 'BASE_POPULATION_V1'),
    ('CG08', 'M2-10', 'M2-12', 'MODULE1_V2_BASELINE_SET', 'RATE_UP_300BP', 'BASE_POPULATION_V1'),
    ('CG09', 'M2-09', 'M2-13', 'MODULE1_V2_BASELINE_SET', 'RATE_DOWN_200BP', 'BASE_POPULATION_V1'),
    ('CG10', 'M2-16', 'M2-17', 'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1'),
    ('CG11', 'M2-16', 'M2-18', 'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1'),
    ('CG12', 'M2-19', 'M2-20', 'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'CREDIT_STRESS_SCORE_MIX', 'BASE_POPULATION_V1'),
    ('CG13', 'M2-22', 'M2-23', 'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'UNSECURED_GROWTH_MIX', 'BASE_POPULATION_V1'),
    ('CG14', 'M2-25', 'M2-26', 'MODULE1_V2_PORTFOLIO_MIX_SENSITIVITY_SET', 'REVOLVING_LINE_EXPANSION_MIX', 'BASE_POPULATION_V1'),
    ('CG15', 'M2-28', 'M2-29', 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1'),
    ('CG16', 'M2-33', 'M2-34', 'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'UNSECURED_SEVERITY_STRESS', 'BASE_POPULATION_V1'),
    ('CG17', 'M2-35', 'M2-36', 'MODULE1_V2_LGD_SEVERITY_SENSITIVITY_SET', 'BROAD_LGD_STRESS', 'BASE_POPULATION_V1'),
    ('CG18', 'M2-01', 'M2-37', 'MODULE1_V2_BASELINE_SET', 'BASELINE_V2', 'BASE_POPULATION_V1'),
    ('CG19', 'M2-16', 'M2-38', 'MODULE1_V2_CREDIT_BOX_SENSITIVITY_SET', 'NEAR_PRIME_EXPANSION_MIX', 'BASE_POPULATION_V1'),
    ('CG20', 'M2-28', 'M2-39', 'MODULE1_V2_EXPOSURE_INTENSITY_SENSITIVITY_SET', 'HIGH_BALANCE_APPETITE', 'BASE_POPULATION_V1')
),
archive AS MATERIALIZED (
    SELECT e.module2_run_id AS run,
           a.application_id, a.applicant_id, a.module1_scenario_set_name,
           a.module1_scenario_name, a.population_id, a.product_type,
           a.score_band, a.credit_score, a.annual_income,
           a.requested_amount, a.requested_payment_to_income_ratio, a.estimated_pd,
           a.estimated_lgd, a.requested_expected_loss_amount, a.decision_outcome,
           a.approved_amount, a.approved_expected_loss_amount, a.primary_reason_code,
           a.decision_path, a.ordinary_counteroffer_candidate_flag, a.aggressive_counteroffer_requested_structure_override_flag,
           a.debt_to_income_ratio, a.requested_monthly_payment_proxy, a.amount_to_income_ratio
    FROM credit_decisioning_sim.strategy_decisions_archive AS a
    JOIN expected AS e
      ON a.strategy_run_id=e.strategy_run_id
     AND a.strategy_run_ts=e.utc_execution_time::timestamptz
),
-- Validate source counts before joining applicants. Reject duplicate identities on either side.
inventory AS (
    SELECT run, count(*) AS n, count(DISTINCT application_id) AS ids,
           count(DISTINCT (module1_scenario_set_name, module1_scenario_name, population_id)) AS slices,
           min(module1_scenario_set_name) AS scene_set, min(module1_scenario_name) AS scene,
           min(population_id) AS population
    FROM archive GROUP BY run
),
sides AS (
    SELECT p.*, coalesce(b.n,0) AS baseline_rows, coalesce(c.n,0) AS challenger_rows,
           coalesce(b.n=50000 AND c.n=50000 AND b.ids=b.n AND c.ids=c.n
             AND b.slices=1 AND c.slices=1
             AND (b.scene_set,b.scene,b.population)=(p.scene_set,p.scene,p.population)
             AND (c.scene_set,c.scene,c.population)=(p.scene_set,p.scene,p.population),false) AS sides_ready
    FROM pairs p LEFT JOIN inventory b ON b.run=p.base_run
                 LEFT JOIN inventory c ON c.run=p.test_run
),
paired AS MATERIALIZED (
    SELECT p.pair_id, b.application_id, b.product_type AS product, b.score_band,
           b.credit_score, b.annual_income, b.requested_amount, b.requested_payment_to_income_ratio,
           b.estimated_pd, b.estimated_lgd, b.requested_expected_loss_amount,
           b.decision_outcome AS base_outcome, c.decision_outcome AS test_outcome,
           b.approved_amount AS base_amount, c.approved_amount AS test_amount,
           b.approved_expected_loss_amount AS base_el, c.approved_expected_loss_amount AS test_el,
           b.primary_reason_code AS base_reason, c.primary_reason_code AS test_reason,
           b.decision_path AS base_path, c.decision_path AS test_path,
           c.ordinary_counteroffer_candidate_flag AS ordinary_candidate,
           c.aggressive_counteroffer_requested_structure_override_flag AS override_candidate,
           ROW(b.applicant_id,b.product_type,b.score_band,b.credit_score,b.annual_income,b.requested_amount,
               b.debt_to_income_ratio,b.requested_monthly_payment_proxy,b.requested_payment_to_income_ratio,
               b.amount_to_income_ratio,b.estimated_pd,b.estimated_lgd,b.requested_expected_loss_amount)
            IS DISTINCT FROM
           ROW(c.applicant_id,c.product_type,c.score_band,c.credit_score,c.annual_income,c.requested_amount,
               c.debt_to_income_ratio,c.requested_monthly_payment_proxy,c.requested_payment_to_income_ratio,
               c.amount_to_income_ratio,c.estimated_pd,c.estimated_lgd,c.requested_expected_loss_amount)
               AS input_changed
    FROM sides p JOIN archive b ON b.run=p.base_run
                 JOIN archive c ON c.run=p.test_run AND c.application_id=b.application_id
    WHERE p.sides_ready
),
coverage AS (
    SELECT pair_id, count(*) AS matched_ids,
           count(*) FILTER (WHERE input_changed) AS changed_inputs
    FROM paired GROUP BY pair_id
),
qualified AS (
    SELECT p.*, coalesce(q.matched_ids,0) AS matched_ids, q.changed_inputs,
           (p.sides_ready AND coalesce(q.matched_ids,0)=50000 AND q.changed_inputs=0) AS ready
    FROM sides p LEFT JOIN coverage q USING(pair_id)
),
lessons(id, lesson) AS (VALUES
    (1,'New offer'),
    (2,'Lost offer'),
    (3,'Same counteroffer outcome, different amount'),
    (4,'Ordinary counteroffer candidate receives an offer'),
    (5,'Override candidate ends in review'),
    (6,'The reason changes for the same outcome'),
    (7,'An unchanged approval at the requested amount')
),
-- Multiple lessons may match a single application. Partition early by lesson, product and score.
eligible AS (
    SELECT a.*, l.id,
           md5(a.pair_id || '/' || l.id::text || '/' || a.application_id) AS stable_order
    FROM paired a JOIN qualified q ON a.pair_id=q.pair_id AND q.ready
    CROSS JOIN LATERAL (VALUES
       (1, a.base_outcome IN ('MANUAL_REVIEW','DECLINE') AND a.test_outcome IN ('APPROVE','COUNTEROFFER')),
       (2, a.base_outcome IN ('APPROVE','COUNTEROFFER') AND a.test_outcome IN ('MANUAL_REVIEW','DECLINE')),
       (3, a.base_outcome='COUNTEROFFER' AND a.test_outcome='COUNTEROFFER'
           AND a.base_amount IS NOT NULL AND a.test_amount IS NOT NULL AND a.base_amount<>a.test_amount),
       (4, a.test_outcome='COUNTEROFFER' AND a.ordinary_candidate IS TRUE
           AND a.override_candidate IS NOT TRUE AND a.test_amount>0 AND a.test_amount<a.requested_amount),
       (5, a.test_outcome='MANUAL_REVIEW' AND a.override_candidate IS TRUE),
       (6, a.base_outcome=a.test_outcome AND a.base_reason IS NOT NULL
           AND a.test_reason IS NOT NULL AND a.base_reason<>a.test_reason),
       (7, a.base_outcome='APPROVE' AND a.test_outcome='APPROVE'
           AND a.base_amount=a.requested_amount AND a.test_amount=a.requested_amount)
    ) l(id,qualifies) WHERE l.qualifies
),
strata AS (
    SELECT e.*, row_number() OVER (
               PARTITION BY pair_id,id,product,score_band ORDER BY stable_order,application_id) AS within_cell,
           count(*) OVER (PARTITION BY pair_id,id) AS qualifying_applications
    FROM eligible e
),
choices AS (
    SELECT s.*, row_number() OVER (
               PARTITION BY pair_id,id ORDER BY within_cell,stable_order,application_id) AS example_number
    FROM strata s WHERE within_cell<=4
)
SELECT q.pair_id, l.id AS lesson_id, l.lesson, q.base_run AS baseline_run, q.test_run AS challenger_run,
       q.scene_set AS scenario_set, q.scene AS scenario_name, q.population AS population_id,
       q.baseline_rows, q.challenger_rows, q.matched_ids, q.changed_inputs,
       CASE WHEN q.ready THEN 'READY' WHEN NOT q.sides_ready THEN 'CHECK_RUN_IDENTITIES_OR_COUNTS'
            WHEN q.matched_ids<>50000 THEN 'CHECK_ID_MATCHING' ELSE 'CHECK_SOURCE_FIELDS' END AS pair_status,
       CASE WHEN q.ready THEN coalesce(x.qualifying_applications,0) END AS qualifying_applications,
       x.example_number, x.application_id, x.product, x.score_band, x.credit_score, x.annual_income,
       x.requested_amount, x.requested_payment_to_income_ratio, x.estimated_pd, x.estimated_lgd,
       x.requested_expected_loss_amount, x.base_outcome, x.test_outcome, x.base_amount, x.test_amount,
       x.base_el, x.test_el, x.base_reason, x.test_reason, x.base_path, x.test_path,
       x.ordinary_candidate, x.override_candidate
FROM qualified q CROSS JOIN lessons l
LEFT JOIN choices x ON x.pair_id=q.pair_id AND x.id=l.id AND x.example_number<=4
ORDER BY q.pair_id,l.id,x.example_number;
