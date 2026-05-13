/*
================================================================================
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
MODULE 1: SYNTHETIC APPLICATION & RISK MODELING ENGINE
FILE: module1_synthetic_application_risk_engine_v2.0.sql
VERSION: 2.0 (FINAL VALIDATED RELEASE)
AUTHOR: Andrew R. Goad
TARGET PLATFORM: PostgreSQL
================================================================================

------------------------------------------------------------------------------
0. EXECUTIVE PURPOSE (PLAIN ENGLISH)
------------------------------------------------------------------------------
This script constructs a governed, synthetic credit application population that
can be used to test approval, affordability, segmentation, pricing, and risk
strategy ideas before anything is operationalized.

This is NOT:
  - a dashboard extract
  - a machine learning model
  - a production underwriting engine
  - a customer-level data build using PII

This IS:
  - a parameterized simulation engine
  - a pre-production strategy sandbox
  - a teaching artifact with extensive comments
  - a governed SQL design showing how product structure flows through
    affordability into a synthetic estimated-PD proxy and expected loss (EL)

Core design chain:
  Applications -> Product Structure -> APR -> Payment -> PTI -> estimated-PD proxy -> EL

The build logic is intentionally organized into staged sections covering:
  deterministic population generation, segment assignment, borrower feature
  generation, product structuring, and risk modeling.

------------------------------------------------------------------------------
ESTIMATED-PD PROXY TERMINOLOGY NOTE
------------------------------------------------------------------------------
Throughout this script, fields such as estimated_pd, base_pd,
pd_raw_pre_saturation_v2, pd_after_saturation_v2, and related pd_* diagnostics
represent a synthetic estimated-PD proxy framework.

These fields are designed to support:
  - directional risk ordering
  - segmentation analysis
  - affordability sensitivity testing
  - Expected Loss comparison
  - scenario-based strategy simulation

They are NOT calibrated production probability-of-default estimates.

The use of "pd" in column names is retained for compactness and continuity with
credit-risk terminology, but the modeled output should be interpreted as a
governed estimated-PD proxy rather than an empirically calibrated default
forecast.

-- Naming note:
-- Aliases such as avg_pd and delta_pd are retained for compact output naming.
-- They refer to movement in the synthetic estimated-PD proxy, not calibrated
-- production default probabilities.

------------------------------------------------------------------------------
1. JOB AID / HOW TO USE THIS SCRIPT
------------------------------------------------------------------------------
Purpose:
  This module is designed to be both a working simulation engine and a learning
  artifact. The steps below explain how to operate the script safely and how to
  interpret the parameter block before making changes.

Who this is for:
  - Analysts testing synthetic portfolio behavior
  - Risk strategists evaluating scenario impacts
  - Hiring managers / reviewers reading the logic as a portfolio artifact
  - Future users who want to modify assumptions without rewriting core SQL

How to use this script:

Step A: Review the parameter section in SECTION 2
  Nearly all user-adjustable assumptions are intentionally centralized near the
  top of the script. This is the primary control panel for:
    - population size
    - scenario naming / reproducibility
    - simulation window
    - product mix
    - score mix
    - macro rate environment
    - hard lower / upper bounds
    - baseline LGD assumptions

  Best practice:
    Do not change downstream logic first. Start with SECTION 2 and rerun the QA
    queries before deciding whether structural code changes are necessary.

Step B: Decide whether you are changing the population, the scenario, or both
  The script separates:
    - scenario_name = the strategy / scenario being tested
    - population_id = the deterministic identifier for the synthetic population

  Practical guidance:
    - Keep population_id the same when you want to compare scenarios against the
      same exact synthetic borrower population.
    - Change population_id when you want to generate a different population with
      the same overall assumptions.
    - Change scenario_name whenever the run represents a different strategy,
      environment, or calibration version.

Step C: Modify only the INSERT values in tmp_module1_params
  Most users should not need to edit the table structure or downstream CASE
  logic. In normal usage, changes should be made in the single INSERT statement
  for tmp_module1_params.

  This helps preserve:
    - reproducibility
    - change control
    - easier QA comparison across runs

Step D: Run the script in PostgreSQL
  The script will:
    1. validate assumptions
    2. generate a deterministic synthetic application population
    3. assign product and score segments
    4. generate borrower profile attributes
    5. derive requested amount, APR proxy, payment, and PTI
    6. estimate the synthetic estimated-PD proxy, LGD, and Expected Loss
    7. populate the final output table

Step E: Review the final output table
      credit_decisioning_sim.synthetic_applications

  This table is the primary working output for:
    - downstream decision strategy testing
    - segmentation analysis
    - expected loss review
    - QA / realism validation
    - portfolio artifact demonstration

Step F: Review the QA queries in SECTION 9
  SECTION 9 should always be reviewed after parameter changes. A successful run
  is not the same thing as a realistic run.

  At minimum, review:
    - 9.2 Product mix
    - 9.3 Score band distribution
    - 9.4 Variable profile statistics
    - 9.5 Score band profile summary
    - 9.6 Product profile summary
    - 9.7 PTI bucket summary
    - 9.8 Product x Score band matrix

Step G: Use parameter changes before logic changes
  If outputs look directionally wrong, ask first:
    - Is this a parameter issue?
    - Is this a calibration issue?
    - Or is this truly a logic issue?

  In many cases, realism problems can be corrected by adjusting:
    - product bounds
    - product mix
    - score mix
    - macro rate shift
    - LGD assumptions
  rather than rewriting the engine.

Important operating note:
  This module is intended for controlled, explainable, pre-production simulation.
  It is not a production underwriting model and should not be used as a customer-
  level decision engine without further governance, validation, and policy design.

------------------------------------------------------------------------------
2. DESIGN PRINCIPLES
------------------------------------------------------------------------------
A. PARAMETERIZED OVER HARD-CODED
   Important assumptions are centralized near the top of the script.

B. CORRELATED OVER INDEPENDENT
   Variables are not generated as unrelated random columns. Score band, product,
   DTI, utilization, delinquencies, tradeline depth, APR, PTI, and estimated-PD proxy
   are generated with directional relationships and realistic overlap.

C. EXPLAINABLE OVER OPAQUE
   The estimated-PD proxy is built from documented base bands and multipliers,
   not a black-box fit.

D. DETERMINISTIC OVER NON-REPRODUCIBLE
   This script avoids session-randomized generation for core logic. Instead, it
   uses stable MD5-based pseudo-random values derived from application IDs and
   population_id. Same parameters + same population_id = same portfolio.

E. PRODUCT-AWARE OVER GENERIC
   Requested amount, term, APR proxy, payment logic, LGD, and some risk behavior
   differ by product to preserve realism across lines of business.

------------------------------------------------------------------------------
3. IMPORTANT MODELING NOTES
------------------------------------------------------------------------------
- This module focuses on application-level simulation; downstream decision policy
  execution is handled in subsequent modules.
- The synthetic population aims for directional realism and internal
  consistency. It is NOT calibrated to any institution's proprietary model.
- APR values are burden-estimation proxies, not production offer prices.
- PTI is intentionally treated as the primary affordability bridge into the
  estimated-PD proxy.
- LGD is intentionally simpler than the estimated-PD proxy framework in Module 1.
- Product mix default is designed to resemble a diversified retail bank, but is
  user-adjustable.
- "Revolving Line" is represented using a requested line / limit proxy and a
  minimum-payment assumption rather than an amortizing installment structure.
- Outputs are intended to support controlled scenario comparison, not
  production decisioning without further model governance and validation.
- Important modeling boundary:
    Module 1 intentionally prioritizes explainability and controlled scenario behavior
    over full product-level contractual accuracy.

    Examples:
      -> Revolving payment is a simplified proxy, not a billing engine
      -> APR represents burden estimation, not offer pricing
      -> estimated_pd is a structured synthetic risk proxy, not a fitted production
         default model

    This is by design to support strategy simulation rather than production decisioning.

------------------------------------------------------------------------------
4. V1.0 MODULE VALIDATION NARRATIVE — QUALITY ASSURANCE & CALIBRATION REVIEW
------------------------------------------------------------------------------
SUMMARY:

   Validation confirmed the engine produces a realistic, reproducible, and structurally
   consistent synthetic portfolio suitable for pre-production strategy testing. Detailed
   validation findings are documented below.

VALIDATION:

A. Initial portfolio-grade synthetic application and risk engine

   The baseline validation confirmed that the engine produces a coherent, portfolio-grade
   synthetic population that behaves consistently across core credit risk dimensions. Using
   a 50,000-application test population, we validated that key distributions—including income,
   credit score, DTI, utilization, tradeline depth, and requested amount—exhibit realistic
   central tendencies, dispersion, and tail behavior. Summary statistics (Section 9.4) confirmed
   no pathological compression or runaway outliers after calibration, while cross-sectional
   outputs demonstrated that the portfolio reflects a believable mix of borrower profiles rather
   than artificially segmented cohorts. The presence of controlled overlap between strong and
   weak profiles further validates that the engine avoids deterministic segmentation and instead
   produces a probabilistic, market-like population suitable for strategy testing.
   
B. Deterministic population generation using population_id

   A core validation requirement was reproducibility. The engine successfully demonstrates
   deterministic population generation, where identical parameter configurations and population_id
   inputs produce identical outputs across runs. This was verified by re-running the full script
   multiple times and confirming that aggregate outputs (counts, distributions, and KPI summaries)
   remained stable without drift. The deterministic seed framework ensures that randomness is
   controlled and replayable, which is critical for auditability, scenario comparison, and
   governance. This design enables true pre-production testing workflows, where strategy
   changes—not data volatility—drive outcome differences.
   
C. Product-aware requested amount, APR, payment, PTI, estimated-PD proxy, LGD, and EL logic

   Validation confirmed that the engine’s product-aware architecture is functioning as intended.
   Each product type (Mortgage, Auto, HELOC, Revolving, Personal Loan) exhibits distinct structural
   behavior across exposure, pricing, and risk metrics. Section 9.6 and 9.8 outputs demonstrate that:
   
    - Mortgage and HELOC produce higher balances and longer-term affordability dynamics
    - Revolving products exhibit higher APRs and lower balances
    - Auto and personal loans occupy intermediate structural positions
    
   Critically, these structural differences propagate correctly through downstream calculations.
   Monthly payment proxy, PTI, estimated-PD proxy, LGD, and Expected Loss all vary consistently with
   both product structure and borrower quality, confirming that the model is not simply assigning static
   risk but is instead translating structure into risk in a realistic and explainable way.
   
D. Structured QA / review workflow added in Section 9

   The validation process was guided by a deliberately structured QA framework embedded directly in
   the SQL (Section 9) and designed to evaluate each major stage of the simulation pipeline. This includes:

    - Distribution validation (9.4) to assess central tendency, spread, and tail behavior
    - Score band profiling (9.5) to confirm directional monotonicity across borrower quality
    - Product-level summaries (9.6) to validate structural differentiation
    - PTI bucket analysis (9.7) to confirm affordability-driven risk behavior
    - Cross-sectional product × score matrices (9.8) to ensure interaction effects are preserved
    - Edge-case spot checks (9.9) to validate realistic overlap and non-linear combinations

   This workflow ensures validation is systematic rather than ad hoc—repeatable, interpretable,
   and aligned to business logic—enabling both technical and non-technical stakeholders to assess
   model behavior.

E. Mortgage calibration updated to reduce unrealistic exposure / PTI outcomes

   During the early V1 calibration cycle, before the final V1 mortgage correction, the mortgage product
   exhibited materially unrealistic behavior, with average requested amounts exceeding ~$800K and
   average PTI approaching ~0.88. Row-level inspection further revealed implausible
   combinations (e.g., moderate-income borrowers supporting $1M+ exposures), indicating that the
   requested amount logic was insufficiently constrained relative to income.
   
   To correct this, three targeted adjustments were implemented:

    - Reduced structural scaling sensitivity to income, limiting excessive amplification from the base amount
    - Narrowed stochastic variation, reducing random amplification of extreme exposure outcomes
    - Introduced a score-band-based income multiple cap, anchoring maximum exposure to borrower capacity

   A subsequent refinement introduced a behavioral multiplier on the cap, allowing borrowers to fall below
   their theoretical maximum rather than clustering at the ceiling. Post-calibration validation confirmed:

    - Mortgage average requested amount reduced to ~$340K–$370K
    - Average PTI reduced to ~0.27–0.34
    - Elimination of extreme affordability violations
    - Preservation of score-based differentiation

   This reflects a transition from structurally correct but unrealistic outputs to economically
   plausible portfolio behavior.

FINAL ASSESSMENT:

   The V1.0 engine has successfully passed validation as a portfolio-grade synthetic credit decisioning
   environment, demonstrating strong structural integrity, realistic behavior, and audit-ready reproducibility.

   The enhancements identified during validation were incremental refinements—not foundational issues—and
   are addressed in the V2.0 implementation summary below. This reinforces that V1.0 is both fit for
   demonstration and well-positioned for continued iteration.

------------------------------------------------------------------------------
5. V2.0 ENHANCEMENTS — IMPLEMENTATION SUMMARY
------------------------------------------------------------------------------
Overview:

   V2.0 builds directly on the validated V1 engine by implementing targeted
   refinements identified during validation. These enhancements improve mortgage
   affordability realism, refine estimated-PD proxy dispersion in high-risk segments,
   introduce explicit tail-frequency measurement, strengthen scenario comparability,
   and improve auditability.

   Importantly, these changes are incremental and controlled. The underlying
   architecture, deterministic population generation, and explainable
   multiplier-based estimated-PD proxy framework remain intact.

------------------------------------------------------------------------------

A. Workstream A - Mortgage realism refinement

   V2 introduces a two-stage mortgage refinement framework designed to improve
   realism in high-exposure and high-affordability-pressure scenarios:

    - A2: Amount-to-income tail smoothing
        * evaluates mortgage candidate amount relative to borrower income
        * applies a deterministic taper in the upper exposure tail
        * reduces unrealistic large-balance outcomes while preserving valid
          high-capacity borrowers

    - A3: Provisional PTI-aware affordability overlay
        * computes a provisional mortgage payment and PTI after A2 smoothing
        * applies a targeted dampener only to the hottest affordability rows
        * cleans up residual edge cases without broadly altering the population

   Result:
     Mortgage exposures now exhibit improved upper-tail realism while preserving
     score-based differentiation and valid high-capacity borrower behavior.

------------------------------------------------------------------------------

B. Workstream B - Estimated-PD proxy dispersion improvement

   V2 introduces a soft saturation layer between raw estimated-PD proxy pressure
   and the final governance cap to reduce clustering near the upper bound.

   In V1:
     Raw multiplied estimated-PD proxy values were passed directly into a hard cap (45%),
     resulting in crowding in weak segments.

   In V2:
     - raw estimated-PD proxy is preserved as an audit-visible field
     - a soft saturation transform compresses extreme values before the hard cap
     - the hard cap remains in place as a governance control

   Calibration path:
     - B1 introduced the initial soft saturation architecture
     - B2 strengthened the saturation slopes after validation showed residual
       cap crowding in the weakest segments
     - B3 applies a final light tightening to further reduce cap crowding while
       preserving monotonic score-band ordering and high-risk differentiation

   Result:
     Improved differentiation in high-risk segments while preserving
     monotonic risk ordering and overall portfolio integrity.

------------------------------------------------------------------------------

C. Workstream C - Scenario comparison framework and archive persistence

   V2 now includes a governed scenario archive and comparison QA framework that
   allows multiple completed Module 1 runs to be preserved and compared.

   This framework supports:

     - scenario_set_name for separating comparison families
     - scenario_name for labeling individual runs
     - archive_reset_mode for controlled archive replacement / clearing
     - deterministic population alignment via population_id
     - portfolio-level, segment-level, and matched row-level comparison outputs

   Result:
     Module 1 now supports controlled apples-to-apples scenario comparison while
     preserving its boundary as a synthetic application and risk modeling engine.

------------------------------------------------------------------------------

D. Workstream D - Revolving payment sensitivity enhancement

   V2 now includes a light APR-sensitive revolving payment proxy.

   In earlier versions:
     Revolving monthly payment was modeled as a fixed percentage of requested
     line amount. This was simple and stable, but rate-shock scenarios changed
     revolving APR without changing revolving payment burden or PTI.

   In Workstream D:
     Revolving payment is modeled as a blended proxy consisting of:
       - a base minimum-payment percentage of requested line amount
       - a scaled monthly interest component derived from bounded APR

   Result:
     Rate-shock scenarios now flow through revolving payment burden, PTI,
     the estimated-PD proxy, and Expected Loss in a directionally realistic
     way, while avoiding the complexity of a full credit-card statement-cycle engine.

   Important boundary:
     This is still a simplified affordability proxy. It is not intended to model
     contractual minimum payment rules, fees, grace periods, balance revolve
     behavior, or full card amortization.

------------------------------------------------------------------------------

E. Expanded diagnostic transparency and deterministic traceability

   V2 enhances auditability by exposing intermediate fields across both
   mortgage structuring and estimated-PD proxy layers, including:

     - mortgage candidate amount, income ratios, and smoothing factors
     - provisional mortgage payment and PTI
     - PTI dampener zones and factors
     - raw estimated-PD proxy values, saturation zones, and post-saturation
       estimated-PD proxy values

   This allows full row-level traceability from:
     borrower profile → product structure → affordability → estimated risk and loss outcome

   Result:
     The engine supports transparent validation, explainability, and
     stakeholder review without requiring reverse engineering.

------------------------------------------------------------------------------

F. Performance and execution efficiency improvements

   V2 introduces implementation-level optimizations to improve execution
   performance and reduce memory pressure during large simulation runs.

   Key improvements include:

     - eliminating intermediate MD5 hash text columns and storing only the
       final deterministic uniform variables (u1–u15)

     - staging expensive calculations (e.g., amortizing payment formulas)
       once and reusing them across downstream logic

     - reducing repeated inline expressions within CASE statements

   Design principle:
     These changes do not alter model outputs. They are purely implementation
     optimizations that preserve deterministic behavior and audit visibility
     while improving execution efficiency.
     
------------------------------------------------------------------------------

G. Tail-frequency validation framework (V2 QA enhancement)

   V2 extends the QA framework to explicitly measure the frequency of extreme
   affordability conditions, rather than relying only on percentile-based
   distribution summaries and row-level spot checks.

   In V1:
     Validation relied primarily on:
       - distribution statistics (median, mean, percentiles, maximum values)
       - product and score-band summaries
       - edge-case spot checks

     These checks were effective for identifying broad realism and tail behavior,
     but they did not directly quantify how common high-affordability-stress
     observations were within the portfolio.

   In V2:
     A dedicated tail-frequency QA check has been added to Section 9 to measure:

       - share of applications with PTI > 40%
       - share of applications with PTI > 50%
       - share of applications with PTI > 75%

   Why this matters:
     A realistic synthetic portfolio should contain high-PTI observations.
     However, those observations should remain non-dominant and explainable.

     Excessive concentration in high-PTI ranges may indicate:
       - unrealistic exposure scaling
       - payment miscalibration
       - insufficient affordability controls
       - structural tail artifacts

   Design principle:
     Tail behavior should be:
       - present
       - explainable
       - bounded
       - non-dominant

   Relationship to Workstream A:
     Workstream A improves mortgage upper-tail realism by reducing structurally
     inflated exposure and introducing affordability-aware controls.

     The tail-frequency QA framework provides a quantitative mechanism to
     confirm that those improvements reduce high-affordability-stress prevalence
     without artificially eliminating realistic edge cases.

   Result:
     V2 validation now includes both:
       - distributional realism
           shape, spread, percentiles, and maximum values

       - frequency-based realism
           how often extreme affordability cases occur

     This strengthens auditability and provides a more complete view of
     affordability behavior across the synthetic portfolio.

------------------------------------------------------------------------------

H. Integrated system behavior (V2 synthesis)

   The V2 enhancements are not independent changes; they operate as a coordinated
   system that improves both realism and analytical usability.

   Specifically:

     - Workstream A (mortgage refinement) improves the structural realism of
       exposure and affordability inputs

     - Workstream B (estimated-PD proxy dispersion) improves how estimated risk is
       distributed across those inputs

     - Workstream C (scenario framework) enables these effects to be isolated
       and compared across controlled runs

     - Workstream D (revolving sensitivity) restores the rate transmission path
       from pricing into affordability and risk

     - Tail-frequency validation provides a quantitative check that extreme
       affordability conditions remain present but non-dominant

   Together, these enhancements transform the engine from:

       a structurally realistic simulation

   into:

       a governed, scenario-capable decisioning experiment framework
       with measurable, explainable behavior across structure,
       affordability, and risk.
*/

/*
================================================================================
SECTION 0. SCHEMA SETUP
================================================================================
Purpose:
  Ensure a dedicated schema exists for this simulation and set the working
  namespace for the session.

Why this matters:
  Using a dedicated schema isolates simulation outputs from other database
  objects, reducing the risk of naming collisions and making the project
  easier to manage and review.

SQL teaching note:
  CREATE SCHEMA IF NOT EXISTS:
    - creates the schema only if it does not already exist
    - allows safe reruns without raising errors

  SET search_path:
    - defines where PostgreSQL looks for tables by default
    - by setting:
        credit_decisioning_sim, public
      the script will:
        1. first look in the simulation schema
        2. then fall back to public if needed

  Practical benefit:
    After setting search_path, you can reference tables without fully
    qualifying schema names, while still ensuring outputs land in the
    correct location.
*/

CREATE SCHEMA IF NOT EXISTS credit_decisioning_sim;

SET search_path TO credit_decisioning_sim, public;


/*
================================================================================
SECTION 1. RESET / CLEAN RERUN
================================================================================
Purpose:
  Drop and recreate the final output table so the script can be rerun cleanly.

Why this matters:
  This script is designed to be idempotent, meaning it can be executed multiple
  times without producing inconsistent or duplicated results.

  Without this reset step, rerunning the script could:
    - append duplicate data
    - mix results from different scenarios
    - create confusion during QA and analysis

SQL teaching note:
  DROP TABLE IF EXISTS:
    - removes the table only if it already exists
    - avoids runtime errors on first execution
    - is a standard pattern for repeatable data pipelines

Design principle:
  Always make it obvious that each run produces a fresh, fully regenerated
  portfolio rather than modifying prior outputs.
*/

DROP TABLE IF EXISTS credit_decisioning_sim.synthetic_applications;

-- V2 execution-stability reset:
-- These temporary staging tables are used to break the model build into smaller
-- executable units. They reduce parser/planner pressure versus one giant CTE.
DROP TABLE IF EXISTS tmp_m1_stage_1_population;
DROP TABLE IF EXISTS tmp_m1_stage_2_borrower_profile;
DROP TABLE IF EXISTS tmp_m1_stage_3_product_structuring;
DROP TABLE IF EXISTS tmp_m1_stage_4_risk;

-- Execution note:
-- The tmp_m1_stage_* tables are PostgreSQL temporary tables.
--
-- They are intentionally created and consumed inside the same script execution
-- and the same database session.
--
-- If an individual downstream section is executed by itself, or if the client
-- tool runs later sections in a different session, PostgreSQL may raise:
--
--   ERROR: relation "tmp_m1_stage_1_population" does not exist
--
-- That does not indicate a modeling issue. It means the staged temp table was
-- not available in the current execution context.
--
-- Best practice:
--   Run Sections 0 through 8.5 together for a full model build.
--   Run Section 9 / Section 10 QA after the final output and archive tables
--   have been created.

/*
================================================================================
SECTION 2. USER PARAMETERS
================================================================================
Purpose:
  Centralized control panel for the simulation.

Teaching note:
  This temp table acts like a configuration object inside SQL. Keeping important
  assumptions here avoids hard-coding logic throughout the script and makes the
  engine easier to govern, explain, and recalibrate.

How to think about this section:
  These parameters do not all serve the same purpose. They fall into seven major
  groups:

  1. SCENARIO ARCHIVE / COMPARISON CONTROLS
     Controls how runs are grouped, archived, replaced, or cleared for
     scenario comparison.

  2. RUN IDENTITY / REPRODUCIBILITY
     Controls how the run is labeled and whether the same synthetic population
     is regenerated consistently.

  3. POPULATION SIZE / TIME WINDOW
     Controls how many applications are generated and over what simulated date
     range they are distributed.

  4. MIX ASSUMPTIONS
     Controls portfolio composition by product and score band.

  5. STRUCTURAL LIMITS / BASELINE ECONOMICS
     Controls score bounds, income bounds, utilization bounds, product amount
     ranges, base APR proxies, and LGD assumptions.

  6. MACRO ENVIRONMENT
     Controls broad rate pressure through a configurable basis-point shift.

  7. REVOLVING PAYMENT ASSUMPTIONS
     Controls how revolving line payment burden responds to APR and rate-shock
     scenarios.

Parameter guidance:

A. scenario_name
   What it is:
     A business-facing label for the run or strategy scenario.

   Why it matters:
     This allows users to distinguish one run from another when comparing
     baseline, stress, or alternative strategy scenarios.

   When to change it:
     Change this whenever the run represents a different scenario, such as:
       - BASELINE
       - RATE_STRESS_UP_200BP
       - TIGHTER_CREDIT_BOX
       - CALIBRATION_V2

   Best practice:
     Keep this readable and business-friendly. It should describe the scenario,
     not the underlying randomization mechanics.

B. population_id
   What it is:
     The deterministic identifier for the synthetic population and the effective
     seed input used in the MD5-based pseudo-random generation logic.

   Why it matters:
     This controls reproducibility. If scenario_name changes but population_id
     stays the same, you are testing a new scenario against the same borrowers.
     If population_id changes, you are generating a new synthetic population.

   When to change it:
     - Keep it the same for apples-to-apples scenario comparison
     - Change it when you intentionally want a different population

   Best practice:
     Use values such as:
       - BASE_POPULATION_V1
       - ALT_POPULATION_V1
       - STRESS_POPULATION_V1

C. application_count
   What it is:
     The number of synthetic applications to generate.

   Why it matters:
     Larger populations improve distribution stability and make mix targets
     converge more tightly. Smaller populations are faster to run and easier to
     inspect manually.

   Typical guidance:
     - 5,000 to 10,000 = quick testing / development
     - 25,000 to 50,000 = strong portfolio validation
     - 100,000+ = heavier-scale stress testing

   When to change it:
     Change this when balancing speed versus stability of results.

D. portfolio_start_date / portfolio_end_date / anchor_date
   What they are:
     These fields control the simulated application window and the anchor date
     associated with the run.

   Why they matter:
     They define the date context for the portfolio and help make outputs feel
     like a realistic application population rather than an undated dataset.

   Guidance:
     - portfolio_start_date / portfolio_end_date define the application window
     - anchor_date defines the reporting / run context date
     - keep anchor_date at or after the end of the application window

E. Product mix parameters
     pct_mortgage
     pct_revolving
     pct_auto
     pct_personal_loan
     pct_heloc

   What they are:
     The portfolio composition weights by product.

   Why they matter:
     These are among the highest-impact parameters in the entire script because
     they change the structural makeup of the portfolio. Product mix influences:
       - balance distribution
       - APR distribution
       - payment burden
       - PTI
       - estimated-PD proxy / EL profile

   Validation rule:
     These values must sum to 1.00.

   When to change them:
     Change these when simulating:
       - a diversified retail bank
       - an auto-heavy lender
       - a revolving-focused portfolio
       - a secured lending mix
       - a personal-loan growth strategy

   Practical examples:
     - Increase pct_revolving to simulate higher-yield, higher-LGD portfolios
     - Increase pct_mortgage to simulate larger balances and lower-LGD secured exposure
     - Increase pct_personal_loan to study shorter-term affordability pressure

F. Score mix parameters
     pct_super_prime
     pct_prime
     pct_near_prime
     pct_subprime
     pct_deep_subprime

   What they are:
     The portfolio composition weights by score band.

   Why they matter:
     These control overall borrower quality distribution and strongly affect:
       - delinquency behavior
       - derog / bankruptcy incidence
       - affordability stress
       - estimated-PD proxy and Expected Loss

   Validation rule:
     These values must sum to 1.00.

   When to change them:
     Change these when simulating:
       - tighter underwriting populations
       - growth into weaker credit segments
       - recessionary or adverse selection environments
       - prime-only or near-prime expansion strategies

   Practical examples:
     - Increase pct_subprime / pct_deep_subprime to stress the portfolio
     - Increase pct_super_prime / pct_prime to simulate a higher-credit mix

G. rate_shift_bps
   What it is:
     A macro rate environment adjustment expressed in basis points.

   Why it matters:
     This is the cleanest top-level way to simulate broad rate pressure without
     rewriting product-level APR logic.

   How to interpret:
     - 0    = baseline environment
     - 100  = +1.00%
     - 200  = +2.00%
     - -100 = -1.00%

   When to change it:
     Use this for:
       - rate stress testing
       - lower-rate affordability scenarios
       - macro comparison runs using the same borrower population
       
H. Revolving payment assumptions
     revolving_base_min_payment_pct
     revolving_interest_passthrough_factor

   What they are:
     These parameters control the simplified monthly payment proxy for revolving
     line products.

   Why they matter:
     Revolving products do not amortize like installment loans, but their
     minimum-payment burden is not completely disconnected from APR. A higher
     APR generally increases the interest component of the payment obligation.

   Workstream D design:
     The revolving payment proxy is intentionally modeled as:

       requested_amount
       * (
           revolving_base_min_payment_pct
           + ((base_apr_for_payment_calc / 12.0)
              * revolving_interest_passthrough_factor)
         )

   Plain-English interpretation:
     - revolving_base_min_payment_pct represents a baseline minimum-payment
       percentage of the line amount
     - base_apr_for_payment_calc / 12.0 represents monthly interest pressure
     - revolving_interest_passthrough_factor controls how much of that monthly
       interest pressure flows into the payment proxy

   Why this is not full card modeling:
     This does not model statement balances, transactor / revolver behavior,
     fees, grace periods, promotional rates, utilization-specific payment rules,
     or contractual issuer-specific minimum-payment policies.

   Best practice:
     Keep these values modest. The goal is to make rate scenarios flow through
     revolving PTI directionally, not to turn Module 1 into a full credit-card
     servicing engine.

I. Hard bounds / core limits
     min_credit_score / max_credit_score
     min_income / max_income
     min_dti / max_dti
     min_utilization / max_utilization

   What they are:
     Safety rails that keep generated values inside plausible business ranges.

   Why they matter:
     These are governance controls, not primary modeling levers. They prevent
     the synthetic engine from drifting into values that are mathematically
     possible but economically implausible.

   When to change them:
     Only change these if:
       - the target business line is materially different
       - you are intentionally expanding the simulation domain
       - current bounds are suppressing valid use cases

   Best practice:
     Do not change these casually. If you widen them, review Section 9.4 and
     edge-case queries carefully.

J. Product amount bounds
     min/max for personal, auto, revolving, heloc, mortgage

   What they are:
     Product-specific floor and ceiling values for requested amount generation.

   Why they matter:
     These strongly shape requested amount distributions and therefore payment,
     PTI, estimated-PD proxy, and Expected Loss.

   When to change them:
     Change these when simulating a different institution type or line-of-
     business focus. For example:
       - higher mortgage caps for jumbo-oriented books
       - lower auto caps for mass-market originations
       - tighter revolving limits for conservative portfolios

   Best practice:
     Change amount bounds before changing downstream risk logic. In many cases,
     unrealistic affordability outcomes originate here.

K. Base APR parameters
     base_rate_mortgage
     base_rate_auto
     base_rate_personal
     base_rate_revolving
     base_rate_heloc

   What they are:
     Product-level APR anchor points before borrower risk premium and macro
     rate shift are applied.

   Why they matter:
     These are burden-estimation anchors, not production offer prices. They
     influence payment burden directly and therefore influence PTI, estimated-PD
     proxy, and EL.

   When to change them:
     Change these when:
       - simulating a different market environment
       - aligning the portfolio to a different pricing philosophy
       - recalibrating burden realism by product

   Best practice:
     Make modest changes first. Even small APR changes can materially affect
     payment burden, especially for large-balance secured products.

L. LGD parameters
     lgd_mortgage
     lgd_auto
     lgd_personal
     lgd_revolving
     lgd_heloc

   What they are:
     Product-level loss severity assumptions.

   Why they matter:
     LGD affects Expected Loss directly. In Module 1, LGD is intentionally kept
     simpler than the estimated-PD proxy, but it still materially changes EL outputs.

   When to change them:
     Change these when you want to test different severity assumptions by
     collateral type, recovery environment, or portfolio policy stance.

   Best practice:
     Treat these as scenario levers for Expected Loss rather than as primary
     realism levers for borrower generation.

Recommended workflow after parameter changes:
  1. Rerun the script
  2. Review Section 9 outputs
  3. Confirm:
       - product mix still looks right
       - score mix still looks right
       - PTI behaves sensibly
       - expected loss remains believable
  4. Only after that decide whether deeper logic changes are needed
*/

DROP TABLE IF EXISTS tmp_module1_params;

-- =============================================================================
-- PARAMETER TABLE DEFINITION
-- =============================================================================
-- SQL teaching note:
-- This temporary table acts as a single-row configuration object.
-- Data types are chosen based on intended use:
--   TEXT    = labels / identifiers
--   BOOLEAN = true / false execution switches
--   INTEGER = counts or whole-number controls
--   DATE    = simulation timing fields
--   NUMERIC = financial amounts, rates, and ratios where decimal precision matters
--
-- Why use a temp table?
-- A temporary table keeps the parameter layer explicit and queryable during the
-- session without creating permanent metadata objects in the target schema.
--
-- Workstream C teaching note:
-- Module 1 now supports scenario archiving for comparison analysis. This does
-- not change how the synthetic population is generated. Instead, it adds
-- governance around how completed runs are grouped, preserved, replaced, or
-- cleared from the scenario archive.
--
-- Key distinction:
--   scenario_set_name = comparison family / project grouping
--   scenario_name     = individual run within that comparison family
--
-- Example:
--   scenario_set_name = RATE_STRESS_TESTS
--     scenario_name   = BASELINE_V2
--     scenario_name   = RATE_UP_200BP
--
--   scenario_set_name = CREDIT_TIGHTENING_TESTS
--     scenario_name   = BASELINE_V2
--     scenario_name   = TIGHTER_CREDIT_BOX
--
-- This allows users to maintain multiple scenario studies in one governed
-- archive table without creating separate physical tables for each project.

CREATE TEMP TABLE tmp_module1_params (
    -- scenario_set_name:
    -- comparison family / project grouping for archived scenario runs.
    --
    -- Why this exists:
    -- A user may want one archive grouping for rate stress tests, another for
    -- credit tightening tests, and another for growth strategy tests. Keeping
    -- scenario_set_name separate from scenario_name prevents unrelated scenario
    -- studies from being mixed together.
    --
    -- Practical examples:
    --   MODULE1_V2_BASELINE_SET
    --   RATE_STRESS_TESTS
    --   CREDIT_TIGHTENING_TESTS
    --   GROWTH_STRATEGY_TESTS
    scenario_set_name           TEXT,

    -- scenario_name:
    -- business-facing run label inside the scenario set, e.g.
    -- BASELINE_V2, RATE_UP_200BP, TIGHTER_CREDIT_BOX.
    --
    -- Why this matters:
    -- scenario_name identifies the individual strategy / assumption set being
    -- tested. When population_id is held constant, different scenario_name
    -- values can be compared against the same synthetic borrowers.
    scenario_name               TEXT,

    -- archive_run_flag:
    -- controls whether this completed run should be inserted into the permanent
    -- scenario archive table.
    --
    -- TRUE:
    --   store the latest completed run for scenario comparison.
    --
    -- FALSE:
    --   create only the latest-run output table and do not preserve it in the
    --   scenario archive. Useful for quick development tests.
    archive_run_flag            BOOLEAN,

    -- archive_reset_mode:
    -- controls how much existing archive history is cleared before inserting
    -- the current run.
    --
    -- Valid values:
    --   NONE
    --     Do not delete archive rows before inserting. Best used only when the
    --     current scenario_name is new and has not already been archived.
    --
    --   SCENARIO_ONLY
    --     Delete only this scenario_name within this scenario_set_name and
    --     population_id before inserting. This is the safest default for reruns
    --     because it prevents duplicate scenario rows while preserving other
    --     scenarios in the same comparison family.
    --
    --   SET_ONLY
    --     Delete all scenarios within this scenario_set_name and population_id.
    --     Use when restarting a comparison family while preserving other
    --     unrelated scenario sets.
    --
    --   ALL
    --     Delete the entire archive table before inserting. Use only when
    --     intentionally resetting all archived Module 1 scenario history.
    archive_reset_mode          TEXT,

    -- population_id:
    -- deterministic identifier for the synthetic population.
    -- Same population_id + same parameters = same borrower population.
    --
    -- Workstream C note:
    -- For apples-to-apples scenario comparison, keep population_id constant
    -- across scenarios. That ensures scenario differences are caused by changed
    -- assumptions, not by a different synthetic borrower population.
    population_id               TEXT,

    -- application_count:
    -- number of synthetic applications to generate.
    application_count           INTEGER,

    -- portfolio window / reporting context
    portfolio_start_date        DATE,          -- first date in simulated application window
    portfolio_end_date          DATE,          -- last date in simulated application window
    anchor_date                 DATE,          -- reporting reference date for the run

    -- PRODUCT MIX (must sum to 1.00)
    -- These weights control portfolio composition by product type.
    pct_mortgage                NUMERIC(12,6),
    pct_revolving               NUMERIC(12,6),
    pct_auto                    NUMERIC(12,6),
    pct_personal_loan           NUMERIC(12,6),
    pct_heloc                   NUMERIC(12,6),

    -- SCORE BAND MIX (must sum to 1.00)
    -- These weights control borrower quality composition.
    pct_super_prime             NUMERIC(12,6),
    pct_prime                   NUMERIC(12,6),
    pct_near_prime              NUMERIC(12,6),
    pct_subprime                NUMERIC(12,6),
    pct_deep_subprime           NUMERIC(12,6),

    -- RATE ENVIRONMENT
    -- Basis-point shift applied on top of product base APRs.
    rate_shift_bps              INTEGER,

    -- REVOLVING PAYMENT ASSUMPTIONS
    -- Workstream D:
    -- These parameters allow revolving payment burden to respond to APR while
    -- keeping the logic simple and explainable.
    --
    -- revolving_base_min_payment_pct:
    --   baseline monthly payment percentage applied to requested revolving line
    --   amount before adding the APR-sensitive component.
    --
    -- revolving_interest_passthrough_factor:
    --   scaled share of monthly APR pressure that flows into the payment proxy.
    --   This is intentionally a dampener, not full interest accrual modeling.
    revolving_base_min_payment_pct         NUMERIC(12,6),
    revolving_interest_passthrough_factor  NUMERIC(12,6),

    -- HARD BOUNDS / CORE LIMITS
    -- These are governance rails, not primary business levers.
    min_credit_score            INTEGER,
    max_credit_score            INTEGER,
    min_income                  NUMERIC(18,2),
    max_income                  NUMERIC(18,2),
    min_dti                     NUMERIC(12,4),
    max_dti                     NUMERIC(12,4),
    min_utilization             NUMERIC(12,4),
    max_utilization             NUMERIC(12,4),

    -- PRODUCT AMOUNT BOUNDS
    -- Floor / ceiling values used to generate product-consistent amount anchors.
    min_personal_amt            NUMERIC(18,2),
    max_personal_amt            NUMERIC(18,2),
    min_auto_amt                NUMERIC(18,2),
    max_auto_amt                NUMERIC(18,2),
    min_revolving_amt           NUMERIC(18,2),
    max_revolving_amt           NUMERIC(18,2),
    min_heloc_amt               NUMERIC(18,2),
    max_heloc_amt               NUMERIC(18,2),
    min_mortgage_amt            NUMERIC(18,2),
    max_mortgage_amt            NUMERIC(18,2),

    -- PRODUCT BASE RATES (APR proxies before risk premium and macro shift)
    -- These are affordability anchors, not final pricing offers.
    base_rate_mortgage          NUMERIC(12,6),
    base_rate_auto              NUMERIC(12,6),
    base_rate_personal          NUMERIC(12,6),
    base_rate_revolving         NUMERIC(12,6),
    base_rate_heloc             NUMERIC(12,6),

    -- PRODUCT LGD ASSUMPTIONS
    -- Product-level loss severity assumptions used in expected loss.
    lgd_mortgage                NUMERIC(12,6),
    lgd_auto                    NUMERIC(12,6),
    lgd_personal                NUMERIC(12,6),
    lgd_revolving               NUMERIC(12,6),
    lgd_heloc                   NUMERIC(12,6)
);

-- =============================================================================
-- DEFAULT PARAMETER SET (BASELINE SCENARIO)
-- =============================================================================
-- Teaching note:
-- The values below are not intended to be universally "correct."
-- They are a realistic baseline starting point representing a diversified
-- retail banking portfolio under moderate rate conditions.
--
-- Design philosophy of the baseline:
--   - enough volume for stable QA review
--   - balanced product mix across secured / unsecured / revolving exposure
--   - slightly stronger than average credit quality, but with meaningful risk tail
--   - plausible hard bounds to prevent unrealistic drift
--   - moderate APR and LGD anchors that create usable variation in PTI and EL
--
-- Best practice:
-- Change one parameter family at a time (mix, rates, bounds, LGD, etc.), then
-- rerun Section 9 before deciding whether deeper logic changes are necessary.

INSERT INTO tmp_module1_params VALUES (
    'MODULE1_V2_BASELINE_SET', -- scenario_set_name:
                               -- comparison family / project grouping for archived runs.
                               --
                               -- Why this matters:
                               -- scenario_set_name lets users keep separate scenario studies
                               -- inside one governed archive table without creating separate
                               -- physical tables for every project.
                               --
                               -- Practical examples:
                               --   RATE_STRESS_TESTS
                               --   CREDIT_TIGHTENING_TESTS
                               --   GROWTH_STRATEGY_TESTS
                               --
                               -- Best practice:
                               -- Keep this constant for scenarios that should be compared
                               -- together. Change it when starting a separate comparison family.

    'BASELINE_V2',             -- scenario_name:
                               -- individual run label inside the scenario set.
                               --
                               -- Why this matters:
                               -- scenario_name identifies the specific assumption set being
                               -- tested, such as BASELINE_V2, RATE_UP_200BP, or
                               -- TIGHTER_CREDIT_BOX.
                               --
                               -- Workstream C note:
                               -- For apples-to-apples comparison, run a baseline scenario and
                               -- one or more alternative scenarios under the same
                               -- scenario_set_name and population_id.

    TRUE,                      -- archive_run_flag:
                               -- TRUE  = insert this completed run into the scenario archive
                               -- FALSE = produce only the latest-run output table.
                               --
                               -- Use TRUE for comparison-ready runs.
                               -- Use FALSE for quick development tests that should not be
                               -- preserved in the archive.

    'SCENARIO_ONLY',           -- archive_reset_mode:
                               -- controls how much existing archive history is cleared before
                               -- this run is inserted.
                               --
                               -- Valid values:
                               --   NONE
                               --     preserve existing archive rows. Use only when inserting a
                               --     brand-new scenario_name.
                               --
                               --   SCENARIO_ONLY
                               --     replace only this scenario within the same
                               --     scenario_set_name + population_id. This is the safest
                               --     default for rerunning a scenario.
                               --
                               --   SET_ONLY
                               --     clear all scenarios within this scenario_set_name and
                               --     population_id. Use when restarting a comparison family.
                               --
                               --   ALL
                               --     clear the entire archive table. Use only when intentionally
                               --     resetting all archived scenario history.

    'BASE_POPULATION_V1',      -- population_id:
                               -- deterministic identity for this borrower population.
                               --
                               -- CRITICAL:
                               --   Keep this constant when comparing V1 vs V2, baseline vs
                               --   stress, or any scenario set where you want the exact same
                               --   borrowers.
                               --
                               --   Change this value ONLY when intentionally generating a new
                               --   synthetic population.

    50000,                     -- application_count:
                               -- number of synthetic applications to generate.
                               --
                               -- Guidance:
                               --   500     = smoke test
                               --   5,000   = development validation
                               --   10,000  = stronger calibration review
                               --   50,000  = full portfolio validation

    DATE '2025-01-01',        -- portfolio_start_date:
                              -- beginning of the synthetic application window

    DATE '2025-12-31',        -- portfolio_end_date:
                              -- end of the synthetic application window.
                              -- A full calendar year helps distribute applications naturally.

    DATE '2025-12-31',        -- anchor_date:
                              -- reporting / reference date for the run.
                              -- Keeping this at the end of the window is a clean baseline convention.

    -- diversified bank product mix
    -- rationale:
    --   mortgage provides large-balance secured exposure
    --   revolving provides yield and utilization-driven risk
    --   auto provides mid-term installment structure
    --   personal provides unsecured installment contrast
    --   heloc adds secured revolving exposure
    0.300000,  -- mortgage
    0.250000,  -- revolving
    0.200000,  -- auto
    0.150000,  -- personal loan
    0.100000,  -- heloc

    -- score band default mix
    -- rationale:
    --   slightly weighted toward prime / near-prime, consistent with a typical
    --   diversified bank portfolio, while still preserving meaningful subprime and
    --   deep-subprime representation for contrast in estimated-PD proxy / EL behavior
    0.180000,  -- super-prime
    0.280000,  -- prime
    0.240000,  -- near-prime
    0.180000,  -- subprime
    0.120000,  -- deep-subprime

    0,         -- rate_shift_bps:
               -- macro rate environment adjustment.
               --
               -- Examples:
               --   0    = baseline environment
               --   +100 = +1.00%
               --   +200 = +2.00%
               --   -100 = -1.00%

    0.020000,  -- revolving_base_min_payment_pct:
               -- baseline monthly payment percentage for revolving line.
               --
               -- Why 2.00%?
               -- This provides a stable base payment component before adding
               -- APR-sensitive monthly interest pressure.
               --
               -- Workstream D note:
               -- Earlier versions used a fixed 3.00% revolving payment proxy.
               -- This 2.00% base plus the APR-sensitive component below is
               -- designed to keep baseline payment burden in a similar range
               -- while allowing rate-shock scenarios to move revolving PTI.

    0.500000,  -- revolving_interest_passthrough_factor:
               -- share of monthly APR pressure that flows into the revolving
               -- payment proxy.
               --
               -- Formula component:
               --   (base_apr_for_payment_calc / 12.0)
               --   * revolving_interest_passthrough_factor
               --
               -- Why 0.50?
               -- This allows APR changes to affect revolving payment burden
               -- without treating the proxy as full credit-card interest
               -- accrual or a production billing calculation.

    -- hard bounds / core limits
    -- these are governance rails to keep simulated values inside plausible ranges
    500,       -- min_credit_score:
               -- lower modeled floor for this engine

    850,       -- max_credit_score:
               -- conventional upper bound of modern bureau-style score range

    20000.00,  -- min_income:
               -- entry-level but plausible borrower income floor

    300000.00, -- max_income:
               -- high-income ceiling that still allows meaningful affluent tail
               -- without letting income become unbounded

    0.0500,    -- min_dti:
               -- 5% floor; effectively allows very low leverage without forcing zero-debt rows

    0.7000,    -- max_dti:
               -- 70% ceiling; high stress but still plausible for a simulation tail

    0.0000,    -- min_utilization:
               -- allows fully unused revolving capacity

    0.9500,    -- max_utilization:
               -- allows near-maxed utilization without forcing literal 100%

    -- product amount bounds
    -- these ranges shape the first-stage requested amount anchors by product
    1000.00,   -- min_personal_amt
    50000.00,  -- max_personal_amt: broad unsecured installment range

    5000.00,   -- min_auto_amt
    80000.00,  -- max_auto_amt: supports mass-market through higher-end vehicle lending

    1000.00,   -- min_revolving_amt
    30000.00,  -- max_revolving_amt: reasonable unsecured revolving line range

    10000.00,  -- min_heloc_amt
    250000.00, -- max_heloc_amt: secured revolving borrowing range

    75000.00,  -- min_mortgage_amt: entry-level mortgage size
    1500000.00,-- max_mortgage_amt: supports large / jumbo exposure while still bounded

    -- base APR proxies (before risk premium and macro adjustment)
    -- these are burden-estimation anchors, not production pricing offers
    0.060000,  -- mortgage: lower secured borrowing rate
    0.065000,  -- auto: moderate secured installment rate
    0.110000,  -- personal: higher unsecured installment rate
    0.200000,  -- revolving: highest APR anchor in the baseline mix
    0.080000,  -- heloc: lower secured revolving rate

    -- LGD assumptions
    -- relative severity logic:
    --   mortgage < heloc < auto < personal < revolving
    0.200000,  -- mortgage: low severity due to secured collateral structure
    0.450000,  -- auto: moderate severity
    0.700000,  -- personal: higher severity due to unsecured structure
    0.850000,  -- revolving: highest severity assumption in the baseline set
    0.250000   -- heloc: secured exposure with relatively low severity
);

/*
================================================================================
SECTION 3. VALIDATION GATEKEEPER
================================================================================
Purpose:
  Perform pre-run validation on the parameter set before any synthetic data is
  generated.

Why this section exists:
  This block acts as a control gate. Its purpose is to stop the script early
  when assumptions are logically inconsistent, mathematically invalid, or
  operationally unsafe for downstream simulation.

Business rationale:
  A simulation that runs with bad assumptions can produce outputs that look
  polished but are fundamentally misleading. In governed analytics work, it is
  better to fail immediately with a clear error than to quietly generate an
  unrealistic portfolio.

SQL teaching note:
  This section uses a PL/pgSQL anonymous block:
      DO $$ ... END $$;
  This allows procedural logic inside PostgreSQL, including:
    - variable declaration
    - conditional IF / THEN checks
    - custom exception messages

Validation philosophy:
  The checks below are organized to confirm:
    1. exactly one active parameter set exists
    2. the run is large enough to be meaningful
    3. dates are logically ordered
    4. product and score mixes are internally consistent
    5. lower / upper bounds are valid
    6. rate and loss assumptions remain in plausible ranges
    7. scenario archive controls are valid and intentional
    8. revolving payment proxy assumptions remain governed
    9. the script follows a "fail fast" principle — execution stops immediately
       when invalid assumptions are detected

Important modeling note:
  These checks validate parameter integrity, not portfolio realism. Realism is
  assessed later through the QA workflow in SECTION 9.
*/

DO $$
DECLARE
    -- p holds the single row from tmp_module1_params so the code can refer to
    -- parameters using dot notation (for example: p.application_count).
    p RECORD;

    -- v_param_count confirms that tmp_module1_params behaves as intended:
    -- exactly one configuration row should exist for each run.
    v_param_count INTEGER;

    -- These variables store the total product mix weight and total score mix
    -- weight so they can be validated before the simulation runs.
    v_product_mix NUMERIC(12,6);
    v_score_mix   NUMERIC(12,6);
BEGIN
    /*
    ============================================================================
    PARAMETER TABLE CARDINALITY CHECK
    ============================================================================
    Purpose:
      Confirm that tmp_module1_params contains exactly one row.

    Why this matters:
      This table is designed to behave like a single configuration object. If it
      contains zero rows, the engine has no assumptions to run with. If it
      contains multiple rows, the script could silently select one row and ignore
      the others, creating ambiguity around which scenario was actually executed.

    Governance principle:
      A simulation run should have one and only one active parameter set.
      Anything else should fail before synthetic data is generated.
    */
    SELECT COUNT(*) INTO v_param_count
    FROM tmp_module1_params;

    IF v_param_count <> 1 THEN
        RAISE EXCEPTION
            'tmp_module1_params must contain exactly one row (found %)',
            v_param_count;
    END IF;

    -- Load the one-row parameter record into variable p.
    -- SQL teaching note:
    -- "SELECT ... INTO" in PL/pgSQL assigns query results into a variable.
    SELECT * INTO p FROM tmp_module1_params;

    -- Sum the product mix weights.
    -- These values are intended to represent proportions of the portfolio and
    -- therefore must add up to approximately 1.00.
    v_product_mix :=
          p.pct_mortgage
        + p.pct_revolving
        + p.pct_auto
        + p.pct_personal_loan
        + p.pct_heloc;

    -- Sum the score-band mix weights.
    -- Like product mix, these values represent portfolio composition and
    -- therefore must also total approximately 1.00.
    v_score_mix :=
          p.pct_super_prime
        + p.pct_prime
        + p.pct_near_prime
        + p.pct_subprime
        + p.pct_deep_subprime;

    -- Ensure the requested population size is positive.
    -- Why this matters:
    -- A zero-row or negative-row portfolio is not meaningful and would break
    -- the purpose of the simulation.
    IF p.application_count <= 0 THEN
        RAISE EXCEPTION
            'Invalid application_count (%): must be > 0',
            p.application_count;
    END IF;

    -- Ensure the simulation window is chronologically valid.
    -- Why this matters:
    -- The portfolio start date should never be later than the portfolio end date.
    IF p.portfolio_start_date > p.portfolio_end_date THEN
        RAISE EXCEPTION
            'Invalid date range: portfolio_start_date (%) must be <= portfolio_end_date (%)',
            p.portfolio_start_date,
            p.portfolio_end_date;
    END IF;

    -- Validate that product mix sums to approximately 1.00.
    -- SQL / analytics note:
    -- We use a tolerance of 0.000010 instead of strict equality because decimal
    -- arithmetic can contain small rounding differences. This is a standard way
    -- to avoid false failures from harmless precision noise.
    IF ABS(v_product_mix - 1.000000) > 0.000010 THEN
        RAISE EXCEPTION
            'Product mix must sum to 1.00 (got %)',
            v_product_mix;
    END IF;

    -- Validate that score-band mix sums to approximately 1.00.
    -- Same tolerance logic as product mix above.
    IF ABS(v_score_mix - 1.000000) > 0.000010 THEN
        RAISE EXCEPTION
            'Score mix must sum to 1.00 (got %)',
            v_score_mix;
    END IF;

    -- Validate score bounds.
    -- Why this matters:
    -- A minimum score must be strictly lower than a maximum score or the
    -- generation logic becomes internally contradictory.
    IF p.min_credit_score >= p.max_credit_score THEN
        RAISE EXCEPTION
            'Credit score bounds invalid: min_credit_score (%) must be < max_credit_score (%)',
            p.min_credit_score,
            p.max_credit_score;
    END IF;

    -- Validate income bounds.
    -- Why this matters:
    -- Income must be positive, and the lower bound must be below the upper bound.
    IF p.min_income <= 0 OR p.min_income >= p.max_income THEN
        RAISE EXCEPTION
            'Income bounds invalid: min_income (%) must be > 0 and < max_income (%)',
            p.min_income,
            p.max_income;
    END IF;

    -- Validate DTI bounds.
    -- Why this matters:
    -- DTI is represented here as a ratio, so:
    --   - it cannot be negative
    --   - the minimum must be lower than the maximum
    --   - the maximum cannot exceed 1.00 (100%) under this module's ratio design
    IF p.min_dti < 0 OR p.min_dti >= p.max_dti OR p.max_dti > 1 THEN
        RAISE EXCEPTION
            'DTI bounds invalid: min_dti (%), max_dti (%) must satisfy 0 <= min < max <= 1',
            p.min_dti,
            p.max_dti;
    END IF;

    -- Validate utilization bounds.
    -- Why this matters:
    -- Utilization is also modeled as a ratio, so the same core logic applies:
    --   - no negative values
    --   - lower bound must be below upper bound
    --   - maximum cannot exceed 1.00 (100%)
    IF p.min_utilization < 0 OR p.min_utilization >= p.max_utilization OR p.max_utilization > 1 THEN
        RAISE EXCEPTION
            'Utilization bounds invalid: min_utilization (%), max_utilization (%) must satisfy 0 <= min < max <= 1',
            p.min_utilization,
            p.max_utilization;
    END IF;

    -- Validate product amount bounds for every product family.
    -- Why this matters:
    -- Each product must have a sensible lower / upper range before requested
    -- amount generation can work correctly.
    IF p.min_personal_amt >= p.max_personal_amt
       OR p.min_auto_amt >= p.max_auto_amt
       OR p.min_revolving_amt >= p.max_revolving_amt
       OR p.min_heloc_amt >= p.max_heloc_amt
       OR p.min_mortgage_amt >= p.max_mortgage_amt THEN
        RAISE EXCEPTION
            'Product amount bounds invalid:
               personal (%–%),
               auto (%–%),
               revolving (%–%),
               heloc (%–%),
               mortgage (%–%)
             Each min must be < max',
            p.min_personal_amt, p.max_personal_amt,
            p.min_auto_amt, p.max_auto_amt,
            p.min_revolving_amt, p.max_revolving_amt,
            p.min_heloc_amt, p.max_heloc_amt,
            p.min_mortgage_amt, p.max_mortgage_amt;
    END IF;

    -- Validate base APR proxy assumptions.
    -- Why this matters:
    -- Base rates are foundational payment-burden inputs. Zero or negative
    -- rates would break the intended affordability logic of this module.
    IF p.base_rate_mortgage <= 0
       OR p.base_rate_auto <= 0
       OR p.base_rate_personal <= 0
       OR p.base_rate_revolving <= 0
       OR p.base_rate_heloc <= 0 THEN
        RAISE EXCEPTION
            'Base rates must be > 0 (mortgage %, auto %, personal %, revolving %, heloc %)',
            p.base_rate_mortgage,
            p.base_rate_auto,
            p.base_rate_personal,
            p.base_rate_revolving,
            p.base_rate_heloc;
    END IF;

    -- Validate LGD assumptions.
    -- Why this matters:
    -- LGD is modeled as a proportion of exposure loss severity, so each value
    -- must be strictly between 0 and 1.
    --   0   = no loss severity, which is not appropriate here
    --   1   = total loss severity, which is also not appropriate as a baseline
    IF p.lgd_mortgage <= 0 OR p.lgd_mortgage >= 1
       OR p.lgd_auto <= 0 OR p.lgd_auto >= 1
       OR p.lgd_personal <= 0 OR p.lgd_personal >= 1
       OR p.lgd_revolving <= 0 OR p.lgd_revolving >= 1
       OR p.lgd_heloc <= 0 OR p.lgd_heloc >= 1 THEN
        RAISE EXCEPTION
            'LGD values must be between 0 and 1 (mortgage %, auto %, personal %, revolving %, heloc %)',
            p.lgd_mortgage,
            p.lgd_auto,
            p.lgd_personal,
            p.lgd_revolving,
            p.lgd_heloc;
    END IF;

    /*
    ============================================================================
    3X. SCENARIO ARCHIVE CONTROL VALIDATION (WORKSTREAM C)
    ============================================================================
    Purpose:
      Validate the scenario archive controls before any synthetic data is generated.

    Why this matters:
      Workstream C introduced scenario archiving so Module 1 can preserve multiple
      completed runs and compare them side by side.

      That archive layer is powerful, but it also introduces operational risk:
        - a misspelled archive_reset_mode could fail to clear prior scenario rows
        - a blank scenario_set_name could mix unrelated scenario families
        - a blank scenario_name could make archive outputs difficult to interpret
        - a null archive_run_flag could silently skip expected persistence

      Because Section 8.5 depends on these controls, they must be validated early
      in the same fail-fast gatekeeper that validates model assumptions.

    Valid archive_reset_mode values:
      NONE:
        Preserve existing archive rows before inserting the current run.

      SCENARIO_ONLY:
        Replace only the current scenario within the current scenario set and
        population. This is the recommended default for reruns.

      SET_ONLY:
        Clear all scenarios within the current scenario set and population.

      ALL:
        Clear the entire scenario archive table.

    Design principle:
      Scenario comparison must be governed, reproducible, and intentional. A
      completed run with ambiguous or incorrectly reset archive state is worse
      than a failed run because it can contaminate downstream comparison outputs.
    */

    IF p.archive_run_flag IS NULL THEN
        RAISE EXCEPTION
            'Invalid archive_run_flag: value cannot be null';
    END IF;

    IF p.scenario_set_name IS NULL OR length(trim(p.scenario_set_name)) = 0 THEN
        RAISE EXCEPTION
            'Invalid scenario_set_name: value cannot be null or blank';
    END IF;

    IF p.scenario_name IS NULL OR length(trim(p.scenario_name)) = 0 THEN
        RAISE EXCEPTION
            'Invalid scenario_name: value cannot be null or blank';
    END IF;

	IF p.archive_reset_mode IS NULL
	   OR p.archive_reset_mode NOT IN ('NONE', 'SCENARIO_ONLY', 'SET_ONLY', 'ALL') THEN
	    RAISE EXCEPTION
	        'Invalid archive_reset_mode (%): must be NONE, SCENARIO_ONLY, SET_ONLY, or ALL',
	        p.archive_reset_mode;
	END IF;

	/*
	================================================================================
	3Y. REVOLVING PAYMENT ASSUMPTION VALIDATION (WORKSTREAM D)
	================================================================================
	Purpose:
	  Enforce governance bounds on the revolving payment proxy parameters
	  introduced in Workstream D.
	
	Why this matters:
	  Workstream D intentionally introduces a light APR-sensitive component into
	  revolving payment behavior so that macro rate scenarios (rate_shift_bps)
	  propagate through:
	
	      APR → monthly payment → PTI → estimated-PD proxy → Expected Loss
	
	  However, unlike installment products, revolving payment behavior is not
	  governed by a single deterministic amortization formula. Instead, it is
	  approximated here using a simplified, parameter-driven proxy.
	
	  Because of this, parameter control is critical. Poor parameter values can
	  distort affordability and risk outputs in ways that are not immediately
	  obvious from aggregate QA metrics.
	
	Model design recap (for context):
	  Revolving payment proxy is defined as:
	
	      requested_amount
	      * (
	          revolving_base_min_payment_pct
	          + ((base_apr_for_payment_calc / 12.0)
	             * revolving_interest_passthrough_factor)
	        )
	
	  Where:
	    - revolving_base_min_payment_pct
	        = baseline minimum-payment percentage of line amount
	
	    - revolving_interest_passthrough_factor
	        = fraction of monthly APR pressure that flows into payment burden
	
	Validation logic (what we are enforcing):
	
	  1. revolving_base_min_payment_pct must be between 0 and 0.10
	
	     Why this range:
	       - Values near 0.02–0.03 approximate typical minimum-payment behavior
	       - Values above ~0.05 begin to behave more like aggressive amortization
	       - Values above 0.10 would imply unrealistically high minimum-payment
	         requirements relative to line amount
	
	     Interpretation:
	       This parameter should remain a *baseline burden anchor*, not a lever for
	       forcing high PTI outcomes.
	
	  2. revolving_interest_passthrough_factor must be between 0 and 1
	
	     Why this range:
	       - 0.00 = APR has no effect on payment (equivalent to pre-Workstream D)
	       - 1.00 = full monthly APR pressure flows into payment proxy
	
	     Why cap at 1.00:
	       A value above 1.00 would imply payment burden increases faster than the
	       underlying interest accrual, which is not economically coherent.
	
	     Practical guidance:
	       - 0.20–0.40 = light sensitivity (subtle scenario propagation)
	       - 0.40–0.60 = moderate sensitivity (recommended range)
	       - 0.60–1.00 = aggressive sensitivity (use cautiously)
	
	Design principle:
	  This validation block protects the model from:
	    - silent parameter misconfiguration
	    - unrealistic payment inflation
	    - unintended distortion of PTI, downstream estimated-PD proxy, and EL behavior
	
	  It ensures that Workstream D remains:
	    - directionally realistic
	    - stable under scenario testing
	    - consistent with the simplified modeling intent of Module 1
	
	Failure behavior:
	  If parameters fall outside acceptable ranges, the script raises an exception
	  and halts execution.
	
	  This is intentional:
	    A failed run is preferable to a completed run with distorted economics.
	
	Best practice:
	  Treat these parameters as governed structural controls, not stress levers.
	  Use rate_shift_bps for macro / rate-environment stress and keep revolving
	  parameters within governed ranges for structural consistency.
	*/
	IF p.revolving_base_min_payment_pct IS NULL
	   OR p.revolving_interest_passthrough_factor IS NULL
	   OR p.revolving_base_min_payment_pct < 0
	   OR p.revolving_base_min_payment_pct > 0.10
	   OR p.revolving_interest_passthrough_factor < 0
	   OR p.revolving_interest_passthrough_factor > 1 THEN
	    RAISE EXCEPTION
	        'Revolving payment assumptions invalid: base_min_payment_pct (%) must be 0-0.10 and interest_passthrough_factor (%) must be 0-1',
	        p.revolving_base_min_payment_pct,
	        p.revolving_interest_passthrough_factor;
	END IF;
END $$;

/*
================================================================================
SECTION 4. BASE APPLICATION SKELETON + DETERMINISTIC SEED VALUES
================================================================================
Purpose:
  Create the base synthetic application population and generate deterministic
  pseudo-random inputs that will drive downstream feature generation.

Why this section matters:
  This is the reproducibility foundation of the entire engine. Every downstream
  field in later sections depends on stable row-level pseudo-random values
  created here.

Teaching note:
  Instead of calling session-randomized functions such as random(), this section
  derives multiple deterministic uniform(0,1) values from MD5 hashes tied to
  application identity and population_id. This makes the simulation reproducible,
  auditable, and stable across reruns.

  In practice, this enables:
    - the same scenario_name + population_id + parameters
      to produce the same synthetic population every time
    - scenario comparisons can be performed on the same exact borrowers
    - QA results are stable and repeatable
    - debugging is possible because outputs do not drift from run to run

Design overview:
  This section works in four stages:
    1. params
       Pull the single parameter row into the CTE chain
    2. base_ids
       Create one application row per synthetic application
    3. seeded
       Attach run context and population identity to each application row
    4. uniforms
       Generate MD5-derived deterministic uniform values directly, without carrying
       intermediate hash text columns downstream

Important concept:
  A hash is not "random" in the usual sense. It is deterministic:
    same input -> same output
    different input -> different output

  That is exactly what this project needs.

SQL teaching note:
  Earlier versions used one long CTE pipeline inside a single:
      CREATE TABLE ... AS

  V2 now uses staged temp-table materialization. This keeps the logic readable
  while giving PostgreSQL smaller executable units.

  This pattern allows the script to:
    - build logic step by step
    - make each transformation readable
    - reduce parser / planner memory pressure
    - isolate execution issues to a specific stage
*/

/*
================================================================================
SECTION 4–5 STAGE MATERIALIZATION
================================================================================
Purpose:
  Build the deterministic population, product assignment, score-band assignment,
  base amount, and term structure as a physical temporary stage.

Why this change exists:
  Earlier V2 builds used one very large CREATE TABLE AS WITH chain spanning
  Sections 4 through 8. That preserved logical readability, but it put heavy
  pressure on PostgreSQL's parser / planner and DBeaver's execution portal.

  The out-of-memory error at only 500 rows shows the issue is statement
  complexity, not portfolio size.

Design principle:
  Materializing stages does not change model logic. It simply gives PostgreSQL
  smaller executable units and allows memory to be released between stages.
*/

CREATE TEMP TABLE tmp_m1_stage_1_population AS
WITH params AS (
    -- params:
    -- Pull the one-row configuration table into the CTE chain so all later
    -- stages can reference the active run settings.
    SELECT * FROM tmp_module1_params
),

base_ids AS (
    SELECT
        -- application_seq:
        -- A simple sequential row counter from 1 to application_count.
        -- This is the base synthetic population size driver.
        gs AS application_seq,

        -- application_id:
        -- Create a stable synthetic application identifier.
        -- LPAD(..., 8, '0') forces an 8-digit zero-padded format such as:
        --   APP-00000001
        --   APP-00000002
        --
        -- Why 8?
        -- It provides a clean, readable identifier length for portfolios in the
        -- thousands to millions without changing formatting.
        'APP-' || LPAD(gs::TEXT, 8, '0') AS application_id,

        -- applicant_id:
        -- A parallel synthetic borrower identifier.
        -- This is currently one-to-one with application_id in Module 1.
        -- Later modules could introduce multiple applications per applicant if
        -- desired.
        'CUST-' || LPAD(gs::TEXT, 8, '0') AS applicant_id
    FROM generate_series(1, (SELECT application_count FROM params)) AS gs

    -- SQL teaching note:
    -- generate_series(start, stop) is a PostgreSQL set-returning function that
    -- creates one row per integer in the requested range.
    --
    -- Here it is used as a synthetic row factory.
),

seeded AS (
    SELECT
        b.*,
        p.scenario_set_name,
        p.scenario_name,
        p.archive_run_flag,
        p.archive_reset_mode,
        p.population_id,
        p.portfolio_start_date,
        p.portfolio_end_date,
        p.anchor_date
    FROM base_ids b
    CROSS JOIN params p

    -- SQL teaching note:
    -- CROSS JOIN is appropriate here because params contains exactly one row.
    -- This attaches the same run-level parameter values to every generated
    -- application row.
    --
    -- Optimization note:
    -- Earlier versions also created h1-h15 MD5 hash text columns in this CTE.
    -- Those hash columns were only needed temporarily to create u1-u15 and were
    -- not needed downstream.
    --
    -- In this optimized version, seeded keeps only the row identity and run
    -- context fields. The MD5 hashes are generated directly inside uniforms
    -- below, converted immediately into numeric uniform values, and then not
    -- carried forward as wide text columns.
    --
    -- Why this matters:
    --   - 15 intermediate MD5 text columns materially widen each working row
    --   - downstream SELECT * patterns carry those unused fields forward
    --   - removing them reduces memory pressure without changing the population
    --
    -- Model impact:
    --   None. The hash input strings are unchanged.
    --   Same application_id + same population_id + same seed label still produce
    --   the same deterministic u1-u15 values.
),

uniforms AS (
    SELECT
        s.*,

        -- Deterministic hash generation:
        -- For each application row, generate multiple independent MD5-derived
        -- uniform values.
        --
        -- Why multiple deterministic draws?
        -- Because downstream variables should not all depend on the same single
        -- pseudo-random draw. For example:
        --   u1 might drive date assignment
        --   u2 might drive product assignment
        --   u3 might drive score-band assignment
        --   u7 might drive income scaling
        --   u15 might drive delinquency / jitter behavior
        --
        -- Why append '|u1', '|u2', ... '|u15'?
        -- This intentionally creates different hash inputs from the same base
        -- application_id + population_id, producing multiple independent-looking
        -- deterministic draws for each row.
        --
        -- Why include population_id?
        -- population_id controls which synthetic population is generated.
        -- Keeping it the same preserves the same borrowers across runs.
        -- Changing it creates a new population.
        --
        -- MD5 -> uniform conversion:
        --
        -- Goal:
        -- Convert each hexadecimal MD5 hash into an approximately uniform value
        -- between 0 and 1.
        --
        -- Why use substr(..., 1, 15)?
        -- MD5 returns 32 hex characters. We intentionally take the first 15 hex
        -- characters to create a manageable integer size for conversion.
        --
        -- Why 15 hex characters?
        -- 15 hex characters = 60 bits of information
        -- because each hex character represents 4 bits:
        --   15 * 4 = 60
        --
        -- Why cast to bit(60)::bigint?
        -- This converts the hex-derived value into a 60-bit integer that
        -- PostgreSQL can work with numerically.
        --
        -- Why divide by 16^15?
        -- A 15-character hex string ranges from:
        --   0                to (16^15 - 1)
        -- Dividing by 16^15 rescales that range to approximately:
        --   0.0              to just under 1.0
        --
        -- Result:
        -- Each u# behaves like a deterministic stand-in for a uniform(0,1)
        -- random variable.
        --
        -- Efficiency improvement:
        -- The MD5 hash is still used, but the intermediate h# text value is not
        -- stored as a column. Each hash is generated, converted, and discarded
        -- inside the expression below.
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u1'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u1,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u2'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u2,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u3'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u3,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u4'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u4,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u5'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u5,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u6'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u6,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u7'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u7,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u8'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u8,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u9'),  1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u9,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u10'), 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u10,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u11'), 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u11,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u12'), 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u12,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u13'), 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u13,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u14'), 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u14,
        ('x' || substr(md5(s.application_id || '|' || s.population_id || '|u15'), 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u15

    FROM seeded s

    -- Practical interpretation:
    -- These u1-u15 fields are the reusable deterministic “random” drivers for
    -- later sections of the model.
    --
    -- This keeps variability rich, reproducible, and now more memory efficient.
),

/*
================================================================================
SECTION 5. PRODUCT & SCORE SEGMENT ASSIGNMENT
================================================================================
Purpose:
  Convert deterministic uniform values into core portfolio structure by assigning:
    - application date
    - product type
    - score band
    - initial credit score
    - base requested amount
    - base loan term

Why this section matters:
  This is the first stage where the synthetic population begins to resemble a
  real portfolio rather than a collection of anonymous rows. It introduces the
  structural anchors that downstream borrower feature generation and risk logic
  will build upon.

Teaching note:
  This section demonstrates a common simulation design pattern:
    continuous uniform values -> discrete business segments

  In other words:
    - u1 is used for application timing
    - u2 is used for product assignment
    - u3 is used for score-band assignment
    - u4 is used for score variation within band
    - u5 is used for base amount variation within product
    - u6 is used for term selection and later structural variability

  Splitting these roles across different uniform variables is important because
  it prevents a single pseudo-random driver from controlling too many business
  outcomes at once.

Important concept:
  This section establishes the structural anchors of the portfolio. Later
  sections will add borrower behavior, affordability, and risk on top of these
  core assignments.

Design note:
  Product and score assignment occur early because later sections need these
  segments to drive:
    - income behavior
    - DTI and utilization patterns
    - requested amount scaling
    - APR logic
    - payment structure
    - estimated-PD proxy and expected loss
*/

product_and_core AS (
    SELECT
        u.*,

        -- Carry forward all parameter values needed downstream.
        -- SQL teaching note:
        -- It is often cleaner in long CTE pipelines to attach frequently used
        -- parameters to each row early, rather than repeatedly joining back to
        -- the parameter table later.
        p.pct_mortgage,
        p.pct_revolving,
        p.pct_auto,
        p.pct_personal_loan,
        p.pct_heloc,
        p.pct_super_prime,
        p.pct_prime,
        p.pct_near_prime,
        p.pct_subprime,
        p.pct_deep_subprime,
        p.rate_shift_bps,
        p.revolving_base_min_payment_pct,
        p.revolving_interest_passthrough_factor,
        p.min_credit_score,
        p.max_credit_score,
        p.min_income,
        p.max_income,
        p.min_dti,
        p.max_dti,
        p.min_utilization,
        p.max_utilization,
        p.min_personal_amt, p.max_personal_amt,
        p.min_auto_amt, p.max_auto_amt,
        p.min_revolving_amt, p.max_revolving_amt,
        p.min_heloc_amt, p.max_heloc_amt,
        p.min_mortgage_amt, p.max_mortgage_amt,
        p.base_rate_mortgage,
        p.base_rate_auto,
        p.base_rate_personal,
        p.base_rate_revolving,
        p.base_rate_heloc,
        p.lgd_mortgage,
        p.lgd_auto,
        p.lgd_personal,
        p.lgd_revolving,
        p.lgd_heloc,

        -- application_date:
        -- Spread applications across the configured portfolio date window.
        --
        -- Logic:
        --   u1 is a deterministic uniform(0,1)-like value
        --   (portfolio_end_date - portfolio_start_date) gives the day span
        --   + 1 makes the range inclusive of both start and end dates
        --   floor(...) converts the continuous value into an integer day offset
        --
        -- Why this matters:
        -- This creates a realistic application flow across time rather than
        -- assigning every application to the same date.
        (
          p.portfolio_start_date
          + floor(u.u1 * ((p.portfolio_end_date - p.portfolio_start_date) + 1))::INT
        )::DATE AS application_date,

        -- product_type:
        -- Assign product using cumulative probability thresholds.
        --
        -- Example:
        -- If pct_mortgage = 0.30 and u2 = 0.12, the row becomes MORTGAGE.
        -- If u2 is larger than the mortgage threshold but smaller than the
        -- mortgage + revolving threshold, it becomes REVOLVING_LINE, etc.
        --
        -- Why cumulative assignment?
        -- This is a standard simulation technique for mapping a single uniform
        -- draw into a categorical variable with target proportions.
        CASE
            WHEN u.u2 < p.pct_mortgage THEN 'MORTGAGE'
            WHEN u.u2 < p.pct_mortgage + p.pct_revolving THEN 'REVOLVING_LINE'
            WHEN u.u2 < p.pct_mortgage + p.pct_revolving + p.pct_auto THEN 'AUTO_LOAN'
            WHEN u.u2 < p.pct_mortgage + p.pct_revolving + p.pct_auto + p.pct_personal_loan THEN 'UNSECURED_PERSONAL_LOAN'
            ELSE 'HELOC'
        END AS product_type,

        -- score_band:
        -- Assign score band using the same cumulative probability method.
        --
        -- Why separate product and score assignment?
        -- Product and score should not be hard-coded as the same thing.
        -- A strong portfolio should allow:
        --   - prime auto borrowers
        --   - subprime auto borrowers
        --   - prime revolving borrowers
        --   - near-prime mortgage borrowers
        -- etc.
        --
        -- Correlation between score and later behavior is introduced in later
        -- sections, not forced here through product assignment itself.
        CASE
            WHEN u.u3 < p.pct_super_prime THEN 'SUPER_PRIME'
            WHEN u.u3 < p.pct_super_prime + p.pct_prime THEN 'PRIME'
            WHEN u.u3 < p.pct_super_prime + p.pct_prime + p.pct_near_prime THEN 'NEAR_PRIME'
            WHEN u.u3 < p.pct_super_prime + p.pct_prime + p.pct_near_prime + p.pct_subprime THEN 'SUBPRIME'
            ELSE 'DEEP_SUBPRIME'
        END AS score_band
    FROM uniforms u
    CROSS JOIN params p

    -- SQL teaching note:
    -- CROSS JOIN is safe here because params is a one-row configuration table.
    -- This attaches the active run parameters to every synthetic application row.
),

score_and_product AS (
    SELECT
        c.*,

        -- credit_score:
        -- Convert score band into a specific numeric score inside a predefined
        -- range using u4.
        --
        -- Why these ranges?
        -- They anchor the synthetic portfolio to conventional score segments:
        --   SUPER_PRIME  = 760 to 850  (91 values inclusive of 760)
        --   PRIME        = 700 to 759  (60 values)
        --   NEAR_PRIME   = 640 to 699  (60 values)
        --   SUBPRIME     = 580 to 639  (60 values)
        --   DEEP_SUBPRIME= 500 to 579  (80 values)
        --
        -- Why use floor()?
        -- floor() converts the continuous score draw into an integer score.
        CASE score_band
            WHEN 'SUPER_PRIME' THEN floor(760 + u4 * 91)
            WHEN 'PRIME'       THEN floor(700 + u4 * 60)
            WHEN 'NEAR_PRIME'  THEN floor(640 + u4 * 60)
            WHEN 'SUBPRIME'    THEN floor(580 + u4 * 60)
            ELSE floor(500 + u4 * 80)
        END::INT AS credit_score,

        -- requested_amount_base:
        -- Generate an initial product-specific requested amount anchor before
        -- later income-sensitive and score-sensitive adjustments are applied.
        --
        -- Important concept:
        -- This is NOT the final requested amount.
        -- It is a starting point inside the valid product range.
        --
        -- Why this two-stage design?
        -- First assign a product-consistent base amount.
        -- Later, refine it using borrower capacity and product structure logic.
        CASE product_type
            WHEN 'UNSECURED_PERSONAL_LOAN' THEN round(min_personal_amt + (u5 * (max_personal_amt - min_personal_amt)), 2)
            WHEN 'AUTO_LOAN'               THEN round(min_auto_amt + (u5 * (max_auto_amt - min_auto_amt)), 2)
            WHEN 'REVOLVING_LINE'          THEN round(min_revolving_amt + (u5 * (max_revolving_amt - min_revolving_amt)), 2)
            WHEN 'HELOC'                   THEN round(min_heloc_amt + (u5 * (max_heloc_amt - min_heloc_amt)), 2)
            WHEN 'MORTGAGE'                THEN round(min_mortgage_amt + (u5 * (max_mortgage_amt - min_mortgage_amt)), 2)
        END AS requested_amount_base,

        -- loan_term_months:
        -- Assign a base term structure by product.
        --
        -- Why arrays?
        -- Arrays are a compact SQL way to define a controlled menu of valid
        -- term options. The deterministic uniform value u6 is then used to
        -- select one of those options.
        --
        -- Why these term sets?
        --   Personal Loan: shorter installment structure
        --     [24, 36, 48, 60]
        --   Auto Loan: medium-term installment structure
        --     [36, 48, 60, 72, 84]
        --   Revolving Line: no fixed amortizing term -> NULL
        --   HELOC: longer secured borrowing structure
        --     [120, 180, 240]
        --   Mortgage: long amortization structure
        --     [180, 240, 360]
        --
        -- Why NULL for revolving?
        -- Revolving products do not amortize over a fixed contractual term in
        -- the same way installment products do. Later payment logic handles
        -- this separately using a minimum-payment proxy.
        CASE product_type
            WHEN 'UNSECURED_PERSONAL_LOAN' THEN (ARRAY[24,36,48,60])[1 + floor(u6 * 4)::INT]
            WHEN 'AUTO_LOAN'               THEN (ARRAY[36,48,60,72,84])[1 + floor(u6 * 5)::INT]
            WHEN 'REVOLVING_LINE'          THEN NULL
            WHEN 'HELOC'                   THEN (ARRAY[120,180,240])[1 + floor(u6 * 3)::INT]
            WHEN 'MORTGAGE'                THEN (ARRAY[180,240,360])[1 + floor(u6 * 3)::INT]
        END::INT AS loan_term_months
    FROM product_and_core c
)

SELECT *
FROM score_and_product;

/*
================================================================================
SECTION 6. BORROWER PROFILE FEATURE GENERATION
================================================================================
Purpose:
  Generate borrower-level attributes that define borrower capacity, behavioral
  risk, file maturity, and adverse credit indicators.

Includes:
  - income
  - debt-to-income (DTI)
  - utilization
  - tradeline depth
  - file age
  - inquiry behavior
  - delinquency behavior
  - major derogatory incidence
  - bankruptcy context
  - simple relationship / marketing context flags

Why this section matters:
  This is where the engine begins to feel like a realistic borrower population
  rather than a purely structural product simulation. Product and score were
  assigned in earlier sections; here, those segments are translated into richer
  borrower characteristics.

Teaching note:
  This section introduces correlated realism. Variables are shaped by score
  band and controlled randomness, not generated independently. This creates
  overlap between segments while preserving directional trends.

Important concept:
  Many formulas intentionally include:
    - nonlinear scaling (for example: u^0.65)
    - outlier adjustments
    - min/max bounding
    - discrete caps and floors

  These techniques are used to:
    - avoid unrealistic clustering
    - preserve variability inside each segment
    - allow some "good borrower / bad metric" and "bad borrower / better metric"
      exceptions
    - keep the final portfolio from feeling mechanically segmented

Design note:
  This section is intentionally split into three stages:
    1. borrower_profile
       capacity and file-behavior attributes
    2. behavior_flags
       delinquency and major derog behavior
    3. bankruptcy_and_context
       bankruptcy and lightweight contextual flags

SQL teaching note:
  Later CTEs build on earlier CTEs by referencing prior aliases
  (s -> b -> f). This is a common SQL pipeline pattern for keeping each
  transformation readable and modular.
*/

/*
================================================================================
SECTION 6 STAGE MATERIALIZATION
================================================================================
Purpose:
  Build borrower profile attributes as a separate temporary stage.

Why this matters:
  Section 6 creates borrower capacity, credit behavior, file maturity, and
  adverse-credit indicators. Materializing this stage prevents the full model
  from being planned as one oversized SQL statement.

Design principle:
  This does not change model logic. It only stores the Section 6 output in a
  temporary table so later sections can read from a smaller, stable stage.
*/

CREATE TEMP TABLE tmp_m1_stage_2_borrower_profile AS
WITH borrower_profile AS (
    SELECT
        s.*,

        -- annual_income_raw:
        -- Generate annual income using score-band-specific distributions.
        --
        -- Why use different formulas by score band?
        -- Higher score bands should generally have higher incomes, but not
        -- perfectly so. There should still be overlap across borrower groups.
        --
        -- Why use u7^exponent instead of just u7?
        -- Raising a uniform value to a power changes the shape of the
        -- distribution:
        --   exponent < 1.00  -> more weight toward higher values
        --   exponent = 1.00  -> standard linear spread
        --
        -- Practical meaning here:
        --   SUPER_PRIME uses 0.65 to skew more heavily toward stronger incomes
        --   DEEP_SUBPRIME uses 1.00 to keep the range flatter / less uplifted
        --
        -- Why these base levels and spreads?
        -- They create broad but realistic income bands by score segment:
        --   SUPER_PRIME : base 60k + up to 180k
        --   PRIME       : base 50k + up to 160k
        --   NEAR_PRIME  : base 40k + up to 140k
        --   SUBPRIME    : base 30k + up to 110k
        --   DEEP_SUBPRIME: base 20k + up to 90k
        --
        -- Why LEAST / GREATEST?
        -- These apply governance bounds from Section 2 so that generated values
        -- stay inside the approved income range.
        round(
            LEAST(
                max_income,
                GREATEST(
                    min_income,
                    CASE score_band
                        WHEN 'SUPER_PRIME' THEN (60000 + (u7^0.65) * 180000)
                        WHEN 'PRIME'       THEN (50000 + (u7^0.72) * 160000)
                        WHEN 'NEAR_PRIME'  THEN (40000 + (u7^0.80) * 140000)
                        WHEN 'SUBPRIME'    THEN (30000 + (u7^0.90) * 110000)
                        ELSE                    (20000 + (u7^1.00) * 90000)
                    END
                )
            ), 2
        ) AS annual_income_raw,

        -- debt_to_income_ratio:
        -- Generate DTI with score-band-specific starting ranges plus controlled
        -- upside / downside outlier adjustments.
        --
        -- Why these band starting points?
        -- The script intentionally assumes weaker score bands usually carry
        -- higher debt burden:
        --   SUPER_PRIME  starts at 18%
        --   PRIME        starts at 22%
        --   NEAR_PRIME   starts at 28%
        --   SUBPRIME     starts at 34%
        --   DEEP_SUBPRIME starts at 40%
        --
        -- Why these range widths?
        -- The added widths (0.22 to 0.25) create variation inside each band so
        -- averages differ, but not all rows collapse to the same value.
        --
        -- Why add / subtract outlier adjustments?
        --   u9 < 0.08  -> add 15 percentage points
        --   u9 > 0.93 -> subtract 10 percentage points
        --
        -- These produce realistic exceptions:
        --   - some otherwise strong borrowers have unusually high DTI
        --   - some weaker borrowers still show relatively manageable leverage
        --
        -- Why 0.08 and 0.93?
        -- Roughly 8% and 7% tail conditions create infrequent but visible
        -- outliers without overwhelming the central distribution.
        round(
            LEAST(
                max_dti,
                GREATEST(
                    min_dti,
                    CASE score_band
                        WHEN 'SUPER_PRIME' THEN 0.18 + (u8 * 0.22)
                        WHEN 'PRIME'       THEN 0.22 + (u8 * 0.24)
                        WHEN 'NEAR_PRIME'  THEN 0.28 + (u8 * 0.24)
                        WHEN 'SUBPRIME'    THEN 0.34 + (u8 * 0.24)
                        ELSE                    0.40 + (u8 * 0.25)
                    END
                    + CASE WHEN u9 < 0.08 THEN 0.15 ELSE 0 END
                    - CASE WHEN u9 > 0.93 THEN 0.10 ELSE 0 END
                )
            ), 4
        ) AS debt_to_income_ratio,

        -- utilization_rate:
        -- Generate revolving utilization using score-band-specific base ranges
        -- plus controlled high / low utilization outliers.
        --
        -- Why these starting points?
        -- Utilization is expected to worsen as score quality weakens:
        --   SUPER_PRIME   starts at 8%
        --   PRIME         starts at 15%
        --   NEAR_PRIME    starts at 25%
        --   SUBPRIME      starts at 35%
        --   DEEP_SUBPRIME starts at 45%
        --
        -- Why these widths?
        -- The widths (0.25 to 0.42) allow broad variability and a visibly
        -- heavier upper tail in weaker bands.
        --
        -- Why outlier adjustments?
        --   u11 < 0.05  -> add 20 percentage points
        --   u11 > 0.94 -> subtract 18 percentage points
        --
        -- These allow realistic deviations from the average pattern.
        --
        -- Why cap with min_utilization / max_utilization?
        -- This keeps utilization inside the governance bounds configured in the
        -- parameter section.
        round(
            LEAST(
                max_utilization,
                GREATEST(
                    min_utilization,
                    CASE score_band
                        WHEN 'SUPER_PRIME' THEN 0.08 + (u10 * 0.25)
                        WHEN 'PRIME'       THEN 0.15 + (u10 * 0.30)
                        WHEN 'NEAR_PRIME'  THEN 0.25 + (u10 * 0.35)
                        WHEN 'SUBPRIME'    THEN 0.35 + (u10 * 0.40)
                        ELSE                    0.45 + (u10 * 0.42)
                    END
                    + CASE WHEN u11 < 0.05 THEN 0.20 ELSE 0 END
                    - CASE WHEN u11 > 0.94 THEN 0.18 ELSE 0 END
                )
            ), 4
        ) AS utilization_rate,

        -- tradeline_count:
        -- Generate the number of tradelines (credit file depth / thickness).
        --
        -- Why this matters:
        -- Tradeline count is used later as one indicator of file maturity and
        -- risk uncertainty.
        --
        -- Why these base formulas?
        -- Stronger score bands generally have thicker files:
        --   SUPER_PRIME   starts around 6 trades with up to +12
        --   PRIME         starts around 5 with up to +11
        --   NEAR_PRIME    starts around 3 with up to +10
        --   SUBPRIME      starts around 2 with up to +9
        --   DEEP_SUBPRIME starts around 1 with up to +8
        --
        -- Why add occasional extra trades?
        -- The "CASE WHEN u13 > threshold THEN +7 or +8" logic creates a mild
        -- upper tail so some borrowers have very thick files.
        --
        -- Why different thresholds (0.93, 0.95, 0.96, 0.97, 0.98)?
        -- This makes large-file outliers more common in strong bands and less
        -- common in weak bands.
        --
        -- Why GREATEST(1, ...) and LEAST(25, ...)?
        -- The lower bound of 1 prevents zero-trade records.
        -- The upper bound of 25 prevents implausibly large file depth.
        CASE score_band
            WHEN 'SUPER_PRIME' THEN LEAST(25, GREATEST(1, floor(6 + (u12 * 12))::INT + CASE WHEN u13 > 0.93 THEN 8 ELSE 0 END))
            WHEN 'PRIME'       THEN LEAST(25, GREATEST(1, floor(5 + (u12 * 11))::INT + CASE WHEN u13 > 0.95 THEN 7 ELSE 0 END))
            WHEN 'NEAR_PRIME'  THEN LEAST(25, GREATEST(1, floor(3 + (u12 * 10))::INT + CASE WHEN u13 > 0.96 THEN 7 ELSE 0 END))
            WHEN 'SUBPRIME'    THEN LEAST(25, GREATEST(1, floor(2 + (u12 * 9))::INT + CASE WHEN u13 > 0.97 THEN 7 ELSE 0 END))
            ELSE                    LEAST(25, GREATEST(1, floor(1 + (u12 * 8))::INT + CASE WHEN u13 > 0.98 THEN 7 ELSE 0 END))
        END AS tradeline_count,

        -- months_since_oldest_trade:
        -- Generate file age / credit maturity in months.
        --
        -- Why this matters:
        -- Older files generally indicate more established credit history and
        -- are treated as lower uncertainty in later risk logic.
        --
        -- Why these ranges?
        -- Stronger bands are expected to have older files on average:
        --   SUPER_PRIME   = 48 + up to 260 months
        --   PRIME         = 36 + up to 220 months
        --   NEAR_PRIME    = 24 + up to 180 months
        --   SUBPRIME      = 12 + up to 140 months
        --   DEEP_SUBPRIME =  6 + up to 100 months
        --
        -- These ranges create overlap, but preserve the general pattern that
        -- stronger credit files are often older and more established.
        CASE score_band
            WHEN 'SUPER_PRIME' THEN floor(48 + (u13 * 260))
            WHEN 'PRIME'       THEN floor(36 + (u13 * 220))
            WHEN 'NEAR_PRIME'  THEN floor(24 + (u13 * 180))
            WHEN 'SUBPRIME'    THEN floor(12 + (u13 * 140))
            ELSE                    floor(6  + (u13 * 100))
        END::INT AS months_since_oldest_trade,

        -- recent_inquiry_count_raw:
        -- Generate recent inquiry activity as a simple count.
        --
        -- Why this matters:
        -- Inquiry activity serves as a lightweight indicator of recent credit
        -- shopping / credit-seeking behavior and is used later as an estimated-PD
        -- proxy multiplier.
        --
        -- Why these caps?
        -- Stronger bands generally have fewer inquiries:
        --   SUPER_PRIME   -> 0 to 3
        --   PRIME         -> 0 to 4
        --   NEAR_PRIME    -> 0 to 5
        --   SUBPRIME      -> 0 to 6
        --   DEEP_SUBPRIME -> 0 to 6
        --
        -- Why floor(u14 * N)?
        -- This is a compact SQL method for assigning integer counts from a
        -- deterministic uniform variable.
        CASE
            WHEN score_band = 'SUPER_PRIME' THEN floor(u14 * 4)
            WHEN score_band = 'PRIME'       THEN floor(u14 * 5)
            WHEN score_band = 'NEAR_PRIME'  THEN floor(u14 * 6)
            WHEN score_band = 'SUBPRIME'    THEN floor(u14 * 7)
            ELSE                                 floor(u14 * 7)
        END::INT AS recent_inquiry_count_raw
    FROM tmp_m1_stage_1_population s
),

behavior_flags AS (
    SELECT
        b.*,

        -- delinquency_count_12m:
        -- Assign number of delinquencies in the last 12 months using score-band-
        -- specific cumulative probability ladders.
        --
        -- Why nested CASE statements?
        -- This is a controlled way to map a single uniform value (u15) into a
        -- discrete count distribution with different behavior by score band.
        --
        -- General interpretation:
        --   - stronger bands are heavily concentrated at 0 delinquencies
        --   - weaker bands have progressively larger mass in 1, 2, 3, 4, 5+ buckets
        --
        -- Example for SUPER_PRIME:
        --   u15 < 0.95   -> 0 delinquencies
        --   0.95-0.985   -> 1 delinquency
        --   0.985-0.995  -> 2 delinquencies
        --   > 0.995      -> 3 delinquencies
        --
        -- Why these thresholds?
        -- They intentionally create a very clean strong-credit profile at the
        -- top of the score stack, while the lower bands carry progressively
        -- heavier delinquency tails.
        CASE
            WHEN score_band = 'SUPER_PRIME' THEN
                CASE
                    WHEN u15 < 0.95 THEN 0
                    WHEN u15 < 0.985 THEN 1
                    WHEN u15 < 0.995 THEN 2
                    ELSE 3
                END
            WHEN score_band = 'PRIME' THEN
                CASE
                    WHEN u15 < 0.86 THEN 0
                    WHEN u15 < 0.95 THEN 1
                    WHEN u15 < 0.985 THEN 2
                    WHEN u15 < 0.995 THEN 3
                    ELSE 4
                END
            WHEN score_band = 'NEAR_PRIME' THEN
                CASE
                    WHEN u15 < 0.64 THEN 0
                    WHEN u15 < 0.82 THEN 1
                    WHEN u15 < 0.92 THEN 2
                    WHEN u15 < 0.97 THEN 3
                    WHEN u15 < 0.99 THEN 4
                    ELSE 5
                END
            WHEN score_band = 'SUBPRIME' THEN
                CASE
                    WHEN u15 < 0.32 THEN 0
                    WHEN u15 < 0.55 THEN 1
                    WHEN u15 < 0.74 THEN 2
                    WHEN u15 < 0.87 THEN 3
                    WHEN u15 < 0.95 THEN 4
                    ELSE 5
                END
            ELSE
                CASE
                    WHEN u15 < 0.18 THEN 0
                    WHEN u15 < 0.35 THEN 1
                    WHEN u15 < 0.53 THEN 2
                    WHEN u15 < 0.70 THEN 3
                    WHEN u15 < 0.84 THEN 4
                    ELSE 6
                END
        END::INT AS delinquency_count_12m,

        -- major_derogatory_flag:
        -- Assign a major derogatory event indicator by score band.
        --
        -- Why use score-band-specific probabilities?
        -- Major derogatory events should be very rare in strong bands and much
        -- more common in weaker bands.
        --
        -- Thresholds used:
        --   SUPER_PRIME   -> 0.8%
        --   PRIME         -> 1.8%
        --   NEAR_PRIME    -> 4.5%
        --   SUBPRIME      -> 10.0%
        --   DEEP_SUBPRIME -> 18.0%
        --
        -- Why use u11 here?
        -- Reusing deterministic drivers across related risk dimensions helps
        -- create mild dependence structures without writing a full correlation
        -- matrix. This is a practical SQL simulation approach.
        CASE
            WHEN score_band = 'SUPER_PRIME' THEN (u11 < 0.008)
            WHEN score_band = 'PRIME'       THEN (u11 < 0.018)
            WHEN score_band = 'NEAR_PRIME'  THEN (u11 < 0.045)
            WHEN score_band = 'SUBPRIME'    THEN (u11 < 0.100)
            ELSE                                 (u11 < 0.180)
        END AS major_derogatory_flag
    FROM borrower_profile b
),

bankruptcy_and_context AS (
    SELECT
        f.*,

        -- bankruptcy_flag:
        -- Assign bankruptcy using score band plus major derog context.
        --
        -- Why condition on major_derogatory_flag first?
        -- Bankruptcy is treated as an extreme adverse event. It should be much
        -- more likely when a major derogatory event is already present.
        --
        -- Logic by segment:
        --   SUBPRIME / DEEP_SUBPRIME with major derog -> 32% bankruptcy chance
        --   NEAR_PRIME with major derog              -> 18%
        --   PRIME with major derog                   -> 6%
        --   NEAR_PRIME without major derog           -> 0.3%
        --   otherwise                                -> FALSE
        --
        -- Why no comparable bankruptcy path for strong bands?
        -- In this version of the engine, bankruptcy is intentionally kept very
        -- rare outside weaker / derog-linked populations.
        CASE
            WHEN major_derogatory_flag AND score_band IN ('SUBPRIME','DEEP_SUBPRIME') THEN (u10 < 0.32)
            WHEN major_derogatory_flag AND score_band = 'NEAR_PRIME' THEN (u10 < 0.18)
            WHEN major_derogatory_flag AND score_band = 'PRIME' THEN (u10 < 0.06)
            WHEN NOT major_derogatory_flag AND score_band = 'NEAR_PRIME' THEN (u10 < 0.003)
            ELSE FALSE
        END AS bankruptcy_flag,

        -- prequalified_flag:
        -- Lightweight contextual flag representing whether the borrower appears
        -- to have arrived through a prequalification-style path.
        --
        -- Why 22%?
        -- This is an illustrative portfolio-level rate chosen to create a
        -- meaningful minority segment without dominating the population.
        (u9 < 0.22) AS prequalified_flag,

        -- returning_customer_flag:
        -- Lightweight contextual flag representing whether the borrower is a
        -- repeat / returning customer.
        --
        -- Why 18%?
        -- This creates a visible but minority returning-customer segment for
        -- later scenario work or segmentation analysis.
        (u12 < 0.18) AS returning_customer_flag
    FROM behavior_flags f
)

SELECT *
FROM bankruptcy_and_context;

/*
================================================================================
SECTION 7. PRODUCT STRUCTURING — AMOUNT, APR, PAYMENT, PTI
================================================================================
Purpose:
  Translate borrower characteristics and product type into:
    - requested amount (final exposure)
    - APR proxy
    - monthly payment proxy
    - affordability metrics (PTI and amount-to-income)

Why this section matters:
  This is the financial mechanics layer of the engine.

  Earlier sections answered questions like:
    - Who is the borrower?
    - What product are they applying for?
    - How strong or weak is the underlying credit profile?

  This section answers the next set of questions:
    - How much credit would this borrower reasonably request or receive?
    - At roughly what rate?
    - What monthly payment burden does that imply?
    - How much pressure does that place on income?

  Those answers are critical because estimated-PD proxy is not driven only by "credit quality."
  It is also driven by structure:
    borrower quality + product design + payment burden = affordability stress

Teaching note:
  This section is intentionally split into nine sub-layers:

    1. amount_and_apr_base
       Finalize non-mortgage requested amount, generate the mortgage candidate
       amount, and construct a raw APR

    2. mortgage_tail_smoothing
       Apply V2 A2 mortgage amount-to-income diagnostics and smoothing factors

    3. mortgage_pre_floor
       Preserve the mortgage amount after A2 smoothing but before the A3
       affordability overlay

    4. apr_bounded
       Apply product-level APR floors and ceilings so mortgage provisional PTI
       can use the same bounded APR that final payment logic will use

    5. mortgage_provisional_payment
       Calculate provisional mortgage payment once so A3 logic can reuse it
       without repeating the amortization formula

    6. mortgage_provisional_pti
       Convert provisional mortgage payment into the affordability signal used
       by the A3 overlay

    7. mortgage_pti_overlay
       Apply the V2 A3 provisional PTI-aware dampener only for mortgage rows
       that remain in the hottest affordability zone after A2 smoothing

    8. mortgage_finalized
       Convert the post-A2 / post-A3 mortgage amount into final requested amount
       with mortgage floor / ceiling enforcement

    9. payment_metrics / affordability
       Convert amount + APR + term into payment burden and standardized
       affordability measures

Key modeling principle:
  The engine separates:
    - exposure construction
    - pricing construction
    - payment derivation
    - affordability measurement

  This separation is deliberate. It allows users to inspect and recalibrate each
  part of the decisioning chain independently.

V2 mortgage refinement note:
  Mortgage:
    The mortgage enhancement introduced here consists of two coordinated,
    audit-visible layers:

      - A2 amount-to-income tail smoothing
          * measures candidate mortgage amount relative to borrower income
          * applies a deterministic taper only in the upper exposure tail
          * reduces unrealistic large-balance outcomes while preserving valid
            high-capacity borrowers

      - A3 provisional PTI-aware affordability cleanup
          * evaluates payment burden after A2 smoothing using a provisional PTI
          * applies a smaller, targeted dampener only for the hottest
            affordability rows
          * refines residual high-PTI edge cases without broadly altering the
            mortgage population
 
    Together, these layers preserve the original V1 mortgage candidate logic
    while improving both exposure realism and affordability behavior in the
    upper tail, with full audit visibility from candidate amount through final
    requested amount.
 
  Revolving:
    Workstream D introduces a light APR-sensitive revolving payment proxy.

    Earlier versions used a fixed percentage-of-line payment proxy for revolving
    products. That was stable, but rate-shock scenarios changed revolving APR
    without changing revolving payment burden or PTI.

    Workstream D keeps revolving logic simple while allowing rate scenarios to
    flow through payment burden by using:
      - a base minimum-payment percentage
      - a scaled monthly APR component

    This improves scenario comparison realism without turning Module 1 into a
    full revolving account / statement-cycle engine.   

Why the formulas look different by product:
  A mortgage, auto loan, revolving line, HELOC, and unsecured personal loan do
  not behave the same economically. This section avoids "one formula for all
  products" because that would flatten the portfolio and reduce realism.

How to read the SQL in this section:
  Most product formulas follow this pattern:

    final_amount =
      LEAST(product_max,
        GREATEST(product_min,
          requested_amount_base
          * scaling_factor_from_income
          * dispersion_factor
        )
      )

  In plain English:
    - start with a base amount from Section 5
    - scale it based on borrower capacity
    - add controlled variation
    - force the result to stay inside product bounds

Important concept:
  Many constants in this section are not universal industry rules. They are
  modeling assumptions chosen to create:
    - realistic relative differences by product
    - realistic relative differences by credit band
    - plausible payment burden for a baseline portfolio
    - strong downstream contrast in PTI, estimated-PD proxy, and Expected Loss
*/

/*
================================================================================
SECTION 7 STAGE MATERIALIZATION
================================================================================
Purpose:
  Build requested amount, APR, payment, PTI, mortgage A2 smoothing, A3
  affordability overlay, and Workstream D revolving payment sensitivity as a
  separate temporary stage.
  
Why this matters:
  Section 7 is computationally heavier than earlier sections because it includes
  mortgage amount transformations, APR bounding, amortizing payment math, and
  PTI calculations. Staging it separately reduces statement complexity and
  makes execution failures easier to isolate.
*/

CREATE TEMP TABLE tmp_m1_stage_3_product_structuring AS
WITH amount_and_apr_base AS (
    SELECT
        a.*,

		/*
		========================================================================
		7A. FINAL REQUESTED AMOUNT BASE LAYER
		========================================================================
		Goal:
		  Convert the product-specific base amount from Section 5 into a final,
		  borrower-aware exposure amount.
		
		Design note:
		  For V2, non-mortgage products continue to finalize requested amount
		  directly in this layer.
		
		  Mortgage is handled through a multi-stage, audit-visible refinement flow:
		
		    - candidate amount (existing V1 logic)
		        initial exposure estimate driven by income, product structure,
		        and score-based scaling
		
		    - A2 amount-to-income tail smoothing
		        measures candidate amount relative to borrower income and applies
		        a deterministic taper only in the upper exposure tail
		
		    - A3 provisional PTI-aware overlay
		        evaluates affordability using a provisional payment-to-income (PTI)
		        calculation and applies a smaller, targeted dampener only for the
		        hottest affordability rows remaining after A2 smoothing
		
		    - final requested amount
		        applies product-level floor and ceiling constraints to produce the
		        final governed exposure
		
		Why this matters:
		  This preserves non-mortgage behavior exactly while enhancing mortgage
		  through two coordinated control layers:
		    - structural exposure control (A2)
		    - affordability cleanup (A3)
		
		  The full path from candidate amount through final requested amount remains
		  explicitly visible and auditable at the row level.
		*/

        /*
        ------------------------------------------------------------------------
        NON-MORTGAGE FINAL REQUESTED AMOUNT
        ------------------------------------------------------------------------
        These formulas are unchanged from V1.
        They remain here because no V2 refinement was required for their tail
        behavior at this stage.
        */
        round(
            CASE product_type

                /*
                UNSECURED PERSONAL LOAN
                Formula:
                  requested_amount_base
                  * (0.70 + (annual_income_raw / 100000.0) * 0.35)
                  * (0.90 + u6 * 0.20)

                Why these values:
                  0.70
                    = conservative starting multiplier
                  annual_income_raw / 100000.0
                    = income scaling relative to a $100k reference point
                  0.35
                    = moderate income sensitivity
                  0.90 + u6 * 0.20
                    = +/-10% deterministic dispersion
                */
                WHEN 'UNSECURED_PERSONAL_LOAN' THEN
                    LEAST(
                        max_personal_amt,
                        GREATEST(
                            min_personal_amt,
                            requested_amount_base
                            * (0.70 + (annual_income_raw / 100000.0) * 0.35)
                            * (0.90 + u6 * 0.20)
                        )
                    )

                /*
                AUTO LOAN
                Formula unchanged from V1.
                */
                WHEN 'AUTO_LOAN' THEN
                    LEAST(
                        max_auto_amt,
                        GREATEST(
                            min_auto_amt,
                            requested_amount_base
                            * (0.80 + (annual_income_raw / 120000.0) * 0.25)
                            * (0.90 + u6 * 0.20)
                        )
                    )

                /*
                REVOLVING LINE
                Formula unchanged from V1.
                */
                WHEN 'REVOLVING_LINE' THEN
                    LEAST(
                        max_revolving_amt,
                        GREATEST(
                            min_revolving_amt,
                            requested_amount_base
                            * (0.75 + (annual_income_raw / 90000.0) * 0.30)
                            * (0.90 + u6 * 0.20)
                        )
                    )

                /*
                HELOC
                Formula unchanged from V1.
                */
                WHEN 'HELOC' THEN
                    LEAST(
                        max_heloc_amt,
                        GREATEST(
                            min_heloc_amt,
                            requested_amount_base
                            * (0.80 + (annual_income_raw / 140000.0) * 0.35)
                            * (0.90 + u6 * 0.20)
                        )
                    )

                /*
                MORTGAGE
                In V2, final mortgage requested amount is NOT assigned here.
                Instead, we calculate a mortgage candidate amount using the
                existing V1 logic, then refine it in the next layer.

                Returning NULL here keeps non-mortgage rows finalized while
                mortgage rows flow into the dedicated V2 smoothing path.
                */
                ELSE NULL
            END
        ,2) AS requested_amount_non_mortgage_v2,

        /*
        ------------------------------------------------------------------------
        V2 MORTGAGE CANDIDATE AMOUNT
        ------------------------------------------------------------------------
        This is the preserved V1 mortgage requested amount logic, now broken out
        explicitly as an auditable intermediate field.

        Why this field exists:
          In V1, the mortgage amount was finalized immediately.
          In V2, we preserve the original candidate amount first, then inspect
          whether it sits in a tail zone that should be smoothed.

        This means:
          candidate amount = "what V1 would have produced before V2 smoothing"

        Mortgage candidate design:
          The candidate amount is governed by three controls:
            1. absolute mortgage ceiling
            2. score-band-conditioned income multiple ceiling
            3. structured base anchor

        This is still the correct architecture.
        V2 refines the upper tail AFTER this candidate is formed.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE' THEN
                    LEAST(
                        max_mortgage_amt,

                        /*
                        Income multiple ceiling:
                          SUPER_PRIME -> 5.75x income
                          PRIME       -> 5.00x income
                          NEAR_PRIME  -> 4.25x income
                          SUBPRIME    -> 3.50x income
                          DEEP_SUBPRIME -> 2.75x income

                        Why these values:
                          Stronger borrowers can support larger housing exposure
                          relative to income; weaker borrowers should be more
                          tightly constrained.
                        */
                        (
                            CASE score_band
                                WHEN 'SUPER_PRIME' THEN annual_income_raw * 5.75
                                WHEN 'PRIME'       THEN annual_income_raw * 5.00
                                WHEN 'NEAR_PRIME'  THEN annual_income_raw * 4.25
                                WHEN 'SUBPRIME'    THEN annual_income_raw * 3.50
                                ELSE                    annual_income_raw * 2.75
                            END
                            * (0.70 + u7 * 0.30)
                        ),

                        /*
                        Structured base anchor:
                          requested_amount_base
                          * (0.45 + LEAST(annual_income_raw / 250000.0, 1.0) * 0.30)
                          * (0.94 + u6 * 0.12)

                        Why this still matters in V2:
                          This anchor preserves the product-range-based mortgage
                          structure from V1. It prevents the mortgage amount from
                          being driven only by income multiples and ensures that
                          product-range economics still matter.
                        */
                        GREATEST(
                            min_mortgage_amt,
                            requested_amount_base
                            * (0.45 + LEAST(annual_income_raw / 250000.0, 1.0) * 0.30)
                            * (0.94 + u6 * 0.12)
                        )
                    )
            END
        ,2) AS mortgage_candidate_amount_v2,

        /*
        ========================================================================
        7B. RAW APR CONSTRUCTION
        ========================================================================
        Goal:
          Construct an unbounded APR proxy before later applying product floors
          and ceilings.

        Components:
          1. product base rate
          2. score-band risk premium
          3. small random pricing dispersion
          4. macro rate shift

        V2 note:
          APR logic is unchanged from V1.
        */
        round(
            /*
            1. Product base rate:
               Structural pricing anchor from Section 2.
            */
            CASE product_type
                WHEN 'MORTGAGE' THEN base_rate_mortgage
                WHEN 'AUTO_LOAN' THEN base_rate_auto
                WHEN 'UNSECURED_PERSONAL_LOAN' THEN base_rate_personal
                WHEN 'REVOLVING_LINE' THEN base_rate_revolving
                WHEN 'HELOC' THEN base_rate_heloc
            END

            /*
            2. Score-band risk premium:
               Stronger bands receive lower spreads; weaker bands receive larger
               spreads and wider variability.
            */
            + CASE score_band
                WHEN 'SUPER_PRIME' THEN (0.000 + (u4 * 0.010))
                WHEN 'PRIME'       THEN (0.010 + (u4 * 0.020))
                WHEN 'NEAR_PRIME'  THEN (0.030 + (u4 * 0.030))
                WHEN 'SUBPRIME'    THEN (0.060 + (u4 * 0.040))
                ELSE                    (0.100 + (u4 * 0.050))
              END

            /*
            3. Random pricing dispersion:
               approximately +/-1 percentage point
            */
            + ((u5 - 0.5) * 0.020)

            /*
            4. Macro rate shift:
               basis points converted to decimal APR
            */
            + (rate_shift_bps / 10000.0)
        ,6) AS apr_raw

    FROM tmp_m1_stage_2_borrower_profile a
),

mortgage_tail_smoothing AS (
    SELECT
        a.*,

        /*
        ========================================================================
        7C. V2 MORTGAGE TAIL DIAGNOSTICS
        ========================================================================
        Purpose:
          Measure how stretched the mortgage candidate amount is relative to
          borrower income before finalizing requested amount.

        Design choice:
          The trigger metric is candidate amount-to-income ratio:

              mortgage_candidate_amount_v2 / annual_income_raw

        Why use this metric:
          - simple to interpret
          - directly aligned to the mortgage realism issue identified in V1
          - upstream of payment, so it does not introduce circular logic
          - easy to preserve for audit traceability

        Interpretation:
          This is NOT the final amount-to-income ratio for the row.
          It is a mortgage-candidate stress diagnostic used only to decide
          whether tail smoothing should be applied.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE'
                 AND annual_income_raw > 0
                THEN mortgage_candidate_amount_v2 / annual_income_raw
            END
        ,6) AS mortgage_candidate_amt_income_ratio_v2,

        /*
        Mortgage tail zone classification:

          NORMAL:
            ratio <= 3.75
            No smoothing needed

          UPPER_MID_TAIL:
            3.75 < ratio <= 4.75
            Earlier and more visible smoothing begins here

          EXTREME_TAIL:
            ratio > 4.75
            Stronger smoothing is applied to prevent upper-tail affordability
            behavior from remaining too aggressive

        Why explicit zone labels matter:
          These make the V2 logic auditable without forcing a reviewer to infer
          the active regime from raw ratios alone.

        Why these thresholds were tightened in A2:
          The initial V2 implementation was structurally correct but too mild to
          materially change mortgage tail behavior. This recalibration starts
          smoothing earlier and applies stronger compression in the upper tail.

        Important note:
          This is a calibration refinement (A2), not a structural redesign.
        */
        CASE
            WHEN product_type <> 'MORTGAGE' THEN NULL
            WHEN mortgage_candidate_amount_v2 / NULLIF(annual_income_raw, 0) <= 3.75 THEN 'NORMAL'
            WHEN mortgage_candidate_amount_v2 / NULLIF(annual_income_raw, 0) <= 4.75 THEN 'UPPER_MID_TAIL'
            ELSE 'EXTREME_TAIL'
        END AS mortgage_tail_zone_v2,


        /*
        ========================================================================
        7D. V2 MORTGAGE TAIL SMOOTHING FACTOR
        ========================================================================
        Purpose:
          Apply a deterministic taper to mortgage candidate amounts only when
          they enter the upper affordability tail.

        Notation:
          r = mortgage_candidate_amount_v2 / annual_income_raw

        A2-calibrated V2 taper design:

          1. r <= 3.75
             factor = 1.00
             No smoothing

          2. 3.75 < r <= 4.75
             factor tapers linearly from 1.00 down to 0.92

             Formula:
               1.00 - ((r - 3.75) * 0.08)

             Why:
               Over a 1.00x ratio interval, this produces a maximum 8% reduction.
               This is intentionally stronger than the earlier V2 pass because the
               first implementation was too mild to materially reshape mortgage tail
               behavior.

          3. r > 4.75
             factor continues downward from 0.92 at slope 0.04
             with a hard floor at 0.85

             Formula:
               GREATEST(0.85, 0.92 - ((r - 4.75) * 0.04))

             Why:
               This starts extreme-tail compression earlier, increases taper strength,
               and allows more visible differentiation in the highest-stress mortgage
               rows while still preserving at least 85% of candidate amount.

        Interpretation:
          The taper is designed to:
            - leave ordinary mortgage rows unchanged
            - smooth upper-mid tail rows in a controlled way
            - more clearly cool the extreme tail
            - preserve valid high-capacity borrowers rather than truncating them

        Important principle:
          This is a smoothing factor, not a replacement formula.
          We are refining V1's upper tail, not rewriting mortgage sizing.
        */
        round(
            CASE
                WHEN product_type <> 'MORTGAGE' THEN NULL

                /*
                ------------------------------------------------------------------------
                NORMAL ZONE (<= 3.75)
                No smoothing applied
                ------------------------------------------------------------------------
                */
                WHEN mortgage_candidate_amount_v2 / NULLIF(annual_income_raw, 0) <= 3.75
                    THEN 1.000000

                /*
                ------------------------------------------------------------------------
                UPPER-MID TAIL (3.75 to 4.75)
                Stronger linear taper from 1.00 down to 0.92

                Formula:
                  1.00 - ((r - 3.75) * 0.08)

                Why:
                  - Wider impact zone (starts earlier)
                  - Stronger slope than the earlier V2 pass (0.08 vs 0.06)
                  - Produces meaningful but controlled compression
                  - Increases the likelihood that QA summaries will show a visible
                    improvement in upper-tail behavior
                ------------------------------------------------------------------------
                */
                WHEN mortgage_candidate_amount_v2 / NULLIF(annual_income_raw, 0) <= 4.75
                    THEN 1.000000
                         - (
                             (
                               (mortgage_candidate_amount_v2 / NULLIF(annual_income_raw, 0))
                               - 3.75
                             ) * 0.08
                           )

                /*
                ------------------------------------------------------------------------
                EXTREME TAIL (> 4.75)
                Continue taper with stronger slope and lower floor

                Formula:
                  GREATEST(0.85, 0.92 - ((r - 4.75) * 0.04))

                Why:
                  - Earlier entry into extreme zone
                  - Stronger compression
                  - Reduces clustering near upper affordability limits
                  - Still preserves at least 85% of candidate amount
                ------------------------------------------------------------------------
                */
                ELSE GREATEST(
                        0.850000,
                        0.920000
                        - (
                            (
                              (mortgage_candidate_amount_v2 / NULLIF(annual_income_raw, 0))
                              - 4.75
                            ) * 0.04
                          )
                     )
            END
        ,6) AS mortgage_tail_smoothing_factor_v2
	FROM amount_and_apr_base a
),

mortgage_pre_floor AS (
    SELECT
        m.*,

        /*
        ========================================================================
        7E. V2 MORTGAGE PRE-FLOOR AMOUNT AFTER A2 TAIL SMOOTHING
        ========================================================================
        Purpose:
          Preserve the mortgage amount after the A2 amount-to-income taper but
          before any final affordability-aware overlay or mortgage floor /
          ceiling enforcement is applied.

        Why this field matters:
          This is the handoff point between:
            - structural tail smoothing (A2)
            - affordability cleanup (A3)

        In other words:
          mortgage_requested_amount_pre_floor_v2 answers:
            "What mortgage amount remains after the candidate amount has already
             been cooled by the amount-to-income taper?"

        Audit value:
          Reviewers can compare:
            - mortgage_candidate_amount_v2
            - mortgage_tail_smoothing_factor_v2
            - mortgage_requested_amount_pre_floor_v2

          to understand exactly how much reduction occurred before the PTI-aware
          dampener is considered.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE'
                THEN mortgage_candidate_amount_v2 * mortgage_tail_smoothing_factor_v2
            END
        ,2) AS mortgage_requested_amount_pre_floor_v2

    FROM mortgage_tail_smoothing m
),

apr_bounded AS (
    SELECT
        a.*,

        /*
        ========================================================================
        7F. APR FLOOR / CEILING ENFORCEMENT
        ========================================================================
        Goal:
          Prevent APR proxies from falling outside plausible product ranges.

        V2 note:
          APR logic is unchanged from V1.
        */
        round(
            CASE product_type
                WHEN 'MORTGAGE' THEN LEAST(0.100000, GREATEST(0.040000, apr_raw))
                WHEN 'AUTO_LOAN' THEN LEAST(0.220000, GREATEST(0.050000, apr_raw))
                WHEN 'UNSECURED_PERSONAL_LOAN' THEN LEAST(0.350000, GREATEST(0.080000, apr_raw))
                WHEN 'REVOLVING_LINE' THEN LEAST(0.350000, GREATEST(0.150000, apr_raw))
                WHEN 'HELOC' THEN LEAST(0.150000, GREATEST(0.050000, apr_raw))
            END
        ,6) AS base_apr_for_payment_calc
    FROM mortgage_pre_floor a
),

mortgage_provisional_payment AS (
    SELECT
        p.*,

        /*
        ========================================================================
        7G. V2 A3 PROVISIONAL MORTGAGE PAYMENT
        ========================================================================
        Purpose:
          Calculate the provisional mortgage payment once so downstream A3 logic
          can reuse the result instead of repeating the amortization formula
          multiple times.

        Why this section exists:
          A2 successfully improved the strong mortgage tail by smoothing large
          exposure relative to income. However, validation showed that candidate
          amount-to-income alone does not fully capture the hottest affordability
          cases across the mortgage book.

          This A3 layer therefore introduces a narrowly targeted affordability
          cleanup step based on provisional PTI.

        Why this is "provisional":
          This payment is used only to determine whether an additional PTI-aware
          dampener is warranted. It is not yet the final persisted payment proxy
          for the row.

        Formula:
          Standard amortizing-payment formula using:
            - mortgage_requested_amount_pre_floor_v2
            - base_apr_for_payment_calc
            - loan_term_months

        Why this is safe to use now:
          At this stage in the pipeline, APR has already been bounded and
          mortgage term is already assigned, so the provisional payment reflects
          realistic affordability pressure more directly than amount-to-income
          alone.

        Efficiency improvement:
          The amortizing payment formula uses POWER() several times. Earlier A3
          logic repeated this formula across multiple CASE statements. This
          version calculates it once, stores it as an audit field, and reuses it
          downstream.

        Design principle:
          This is a performance optimization only.
          It does not change the mortgage model logic.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE'
                 AND loan_term_months IS NOT NULL
                 AND loan_term_months > 0
                THEN mortgage_requested_amount_pre_floor_v2
                     * (
                         ((base_apr_for_payment_calc / 12.0)
                         * power(1 + (base_apr_for_payment_calc / 12.0), loan_term_months))
                         /
                         (power(1 + (base_apr_for_payment_calc / 12.0), loan_term_months) - 1)
                       )
            END
        ,2) AS mortgage_provisional_monthly_payment_v2

    FROM apr_bounded p
),

mortgage_provisional_pti AS (
    SELECT
        p.*,

        /*
        ========================================================================
        7H. V2 A3 PROVISIONAL MORTGAGE PTI
        ========================================================================
        Purpose:
          Convert the provisional mortgage payment into a provisional
          payment-to-income ratio.

        Definition:
          provisional PTI =
            provisional monthly mortgage payment / monthly income

        Why preserve this field:
          This gives reviewers direct visibility into the affordability signal
          that triggers the A3 overlay.

        Why split this into its own CTE:
          PostgreSQL does not allow a SELECT-list alias to be reused by another
          expression in the same SELECT list. By calculating provisional payment
          first, then provisional PTI here, we avoid repeating the payment
          formula and keep the logic readable.

        Interpretation:
          This is not the final PTI used for portfolio reporting.
          It is the affordability signal used only by the A3 dampener.

        Audit value:
          Reviewers can compare:
            - mortgage_requested_amount_pre_floor_v2
            - mortgage_provisional_monthly_payment_v2
            - mortgage_provisional_pti_v2

          to understand exactly why a row did or did not receive additional
          A3 affordability dampening.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE'
                 AND annual_income_raw > 0
                THEN mortgage_provisional_monthly_payment_v2
                     / NULLIF(annual_income_raw / 12.0, 0)
            END
        ,6) AS mortgage_provisional_pti_v2

    FROM mortgage_provisional_payment p
),

mortgage_pti_overlay AS (
    SELECT
        p.*,

        /*
        ========================================================================
        7I. V2 A3 PTI-AWARE DAMPENER
        ========================================================================
        Purpose:
          Apply a small additional mortgage dampener only for rows whose
          provisional PTI remains unusually hot after A2 amount-to-income
          smoothing.

        Important design principle:
          A3 is NOT a replacement for A2.
          A3 is a small overlay that operates only after the A2 taper and only
          for mortgage rows whose provisional PTI remains unusually hot.

        Modeling philosophy:
          - A2 = primary structural exposure control
          - A3 = light affordability-sensitive cleanup

        Efficiency improvement:
          This CTE now references mortgage_provisional_pti_v2 directly instead
          of recalculating provisional payment and provisional PTI repeatedly.

        Zone design:
          NORMAL:
            provisional PTI <= 0.45
            no additional dampening

          HOT:
            0.45 < provisional PTI <= 0.60
            light cleanup taper from 1.00 to 0.97

          EXTREME_HOT:
            provisional PTI > 0.60
            continue downward from 0.97 with a floor at 0.94

        Why these levels:
          These thresholds are intentionally high. This ensures A3 remains a
          narrow overlay rather than a broad product redesign.

        Modeling note:
          A3 should only affect the hottest affordability edge cases. If many
          ordinary mortgage rows are affected, the overlay is too aggressive.
        */
        CASE
            WHEN product_type <> 'MORTGAGE' THEN NULL
            WHEN mortgage_provisional_pti_v2 <= 0.450000 THEN 'NORMAL'
            WHEN mortgage_provisional_pti_v2 <= 0.600000 THEN 'HOT'
            ELSE 'EXTREME_HOT'
        END AS mortgage_pti_dampener_zone_v2,

        /*
        ------------------------------------------------------------------------
        PTI DAMPENER FACTOR
        ------------------------------------------------------------------------
        This factor is intentionally smaller than the A2 tail factor.

        A3 design:
          1. provisional PTI <= 0.45
             factor = 1.00

          2. 0.45 < provisional PTI <= 0.60
             taper from 1.00 to 0.97

             Formula:
               1.00 - ((pti - 0.45) / 0.15) * 0.03

          3. provisional PTI > 0.60
             continue from 0.97 downward at slope 0.05
             floor at 0.94

             Formula:
               GREATEST(0.94, 0.97 - ((pti - 0.60) * 0.05))

        Why this is intentionally light:
          The primary mortgage refinement should still come from A2.
          A3 only cleans up the rows that remain too hot after A2 has already
          done most of the work.

        Interpretation:
          - 1.000000 means no additional PTI dampening
          - values below 1.000000 mean A3 reduced the A2-smoothed mortgage amount
        */
        round(
            CASE
                WHEN product_type <> 'MORTGAGE' THEN NULL

                WHEN mortgage_provisional_pti_v2 <= 0.450000 THEN
                    1.000000

                WHEN mortgage_provisional_pti_v2 <= 0.600000 THEN
                    1.000000
                    - (((mortgage_provisional_pti_v2 - 0.450000) / 0.150000) * 0.030000)

                ELSE
                    GREATEST(
                        0.940000,
                        0.970000 - ((mortgage_provisional_pti_v2 - 0.600000) * 0.050000)
                    )
            END
        ,6) AS mortgage_pti_dampener_factor_v2,

        /*
        ------------------------------------------------------------------------
        POST-PTI-DAMPENER MORTGAGE AMOUNT
        ------------------------------------------------------------------------
        This is the mortgage amount after both:
          - A2 amount-to-income taper
          - A3 provisional PTI-aware dampening

        Audit significance:
          This field lets reviewers isolate the incremental effect of the A3
          affordability cleanup layer.

        Why non-mortgage rows remain NULL here:
          Non-mortgage requested amounts were already finalized earlier and are
          not part of the A3 mortgage overlay.

        Final handoff:
          mortgage_requested_amount_post_pti_dampener_v2 is not yet the final
          requested_amount. The next CTE still reapplies mortgage product floor /
          ceiling governance rails before producing the final exposure amount.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE'
                THEN mortgage_requested_amount_pre_floor_v2
                     *
                     CASE
                         WHEN mortgage_provisional_pti_v2 <= 0.450000 THEN
                             1.000000

                         WHEN mortgage_provisional_pti_v2 <= 0.600000 THEN
                             1.000000
                             - (((mortgage_provisional_pti_v2 - 0.450000) / 0.150000) * 0.030000)

                         ELSE
                             GREATEST(
                                 0.940000,
                                 0.970000 - ((mortgage_provisional_pti_v2 - 0.600000) * 0.050000)
                             )
                     END
            END
        ,2) AS mortgage_requested_amount_post_pti_dampener_v2

    FROM mortgage_provisional_pti p
),

mortgage_finalized AS (
    SELECT
        p.*,

        /*
        ========================================================================
        7J. FINAL REQUESTED AMOUNT
        ========================================================================
        Logic:
          - Non-mortgage products remain unchanged from V1
          - Mortgage rows now pass through:
                candidate amount
                -> A2 amount-to-income taper
                -> pre-floor amount
                -> A3 provisional PTI overlay
                -> mortgage floor / ceiling enforcement

        Why reapply floor / ceiling at the very end:
          Because neither A2 nor A3 should bypass the product governance rails.

        Important interpretation:
          A3 should only produce incremental cleanup beyond A2. If large parts of
          the mortgage book are being materially changed here, the A3 overlay is
          too strong.
        */
        round(
            CASE
                WHEN product_type = 'MORTGAGE' THEN
                    LEAST(
                        max_mortgage_amt,
                        GREATEST(
                            min_mortgage_amt,
                            mortgage_requested_amount_post_pti_dampener_v2
                        )
                    )
                ELSE requested_amount_non_mortgage_v2
            END
        ,2) AS requested_amount

    FROM mortgage_pti_overlay p
),

payment_metrics AS (
    SELECT
        a.*,

        /*
        ========================================================================
        7K. MONTHLY PAYMENT DERIVATION
        ========================================================================
        Goal:
          Convert amount + APR + term into a monthly payment proxy.

        Why "proxy"?
          These are simplified payment estimates intended for affordability and
          risk simulation, not production billing calculations.

        Product-specific design:
          Installment products:
            Use a standard amortizing-payment formula.

          HELOC:
            Use an interest-only proxy.

          Revolving line:
            Use a blended minimum-payment proxy introduced in Workstream D.

        Workstream D revolving note:
          Earlier versions used a fixed 3% revolving payment proxy:

              requested_amount * 0.03

          That was simple and stable, but it meant rate-shock scenarios changed
          revolving APR without changing revolving payment burden, PTI, estimated-PD proxy,
          or expected loss.

          Workstream D replaces the fixed proxy with:

              requested_amount
              * (
                  revolving_base_min_payment_pct
                  + ((base_apr_for_payment_calc / 12.0)
                     * revolving_interest_passthrough_factor)
                )

          Why this design:
            - preserves a simple minimum-payment concept
            - allows APR and rate-shock scenarios to affect revolving burden
            - avoids full credit-card statement-cycle complexity
            - keeps the transmission path consistent:
                APR -> payment -> PTI -> estimated-PD proxy -> Expected Loss

          Important boundary:
            This is not a production credit-card billing formula. It does not
            model statement balance, fees, grace periods, transactor behavior,
            promotional APRs, or issuer-specific contractual minimum-payment
            rules.
        */
        round(
            CASE
                WHEN product_type IN ('UNSECURED_PERSONAL_LOAN', 'AUTO_LOAN', 'MORTGAGE') THEN
                    CASE
                        WHEN loan_term_months IS NULL OR loan_term_months = 0 THEN NULL
                        ELSE requested_amount *
                            (
                                ((base_apr_for_payment_calc / 12.0)
                                * power(1 + (base_apr_for_payment_calc / 12.0), loan_term_months))
                                /
                                (power(1 + (base_apr_for_payment_calc / 12.0), loan_term_months) - 1)
                            )
                    END

                /*
                ----------------------------------------------------------------
                REVOLVING LINE — WORKSTREAM D APR-SENSITIVE PAYMENT PROXY
                ----------------------------------------------------------------
                Formula:
                  requested_amount
                  * (
                      revolving_base_min_payment_pct
                      + ((base_apr_for_payment_calc / 12.0)
                         * revolving_interest_passthrough_factor)
                    )

                Plain-English interpretation:
                  Base component:
                    requested_amount * revolving_base_min_payment_pct

                  APR-sensitive component:
                    requested_amount
                    * monthly APR
                    * passthrough factor

                Why divide APR by 12?
                  APR is annualized. Payment burden is monthly. Dividing by 12
                  converts the APR proxy into a monthly rate pressure.

                Why use a passthrough factor?
                  Real revolving minimum payments are affected by interest, but
                  they are not simply full APR interest plus principal in this
                  simplified Module 1 design. The passthrough factor lets the
                  model capture directional rate sensitivity without overstating
                  payment burden.

                Expected scenario behavior:
                  In RATE_UP_200BP or similar scenarios, revolving payment,
                  PTI, estimated-PD proxy, and Expected Loss should now move upward modestly
                  instead of remaining flat.
                ----------------------------------------------------------------
                */
                WHEN product_type = 'REVOLVING_LINE' THEN
                    requested_amount
                    * (
                        revolving_base_min_payment_pct
                        + (
                            (base_apr_for_payment_calc / 12.0)
                            * revolving_interest_passthrough_factor
                          )
                      )

                /*
                HELOC:
                  interest-only proxy.
                */
                WHEN product_type = 'HELOC' THEN requested_amount * (base_apr_for_payment_calc / 12.0)
            END
        ,2) AS monthly_payment_proxy,

        /*
        amount_to_income_ratio:
          Final exposure relative to annual income.
          This remains the post-structuring cross-product leverage view.
        */
        round(requested_amount / NULLIF(annual_income_raw,0), 6) AS amount_to_income_ratio
    FROM mortgage_finalized a
),

affordability AS (
    SELECT
        p.*,

        /*
        annual_income:
          Rounded reporting version of annual_income_raw.
        */
        round(annual_income_raw,2) AS annual_income,

        /*
        ========================================================================
        7L. AFFORDABILITY MEASUREMENT (PTI)
        ========================================================================
        payment_to_income_ratio:
          monthly payment divided by monthly income

        V2 note:
          PTI calculation itself is unchanged:
              monthly payment / monthly income

          What changed is how some upstream monthly payments are derived:
            - Mortgage PTI changes through A2/A3 mortgage requested amount logic
            - Revolving PTI can now respond to APR through Workstream D's
              APR-sensitive revolving payment proxy

        Why this matters:
          PTI remains the affordability bridge into the estimated-PD proxy. Improving
          the upstream payment proxy improves the realism of how scenario assumptions
          flow into downstream risk.
        */
        round(monthly_payment_proxy / NULLIF(annual_income_raw / 12.0,0), 6) AS payment_to_income_ratio

    FROM payment_metrics p
)

SELECT *
FROM affordability;

/*
================================================================================
SECTION 8. RISK MODELING — ESTIMATED-PD PROXY, LGD, EXPECTED LOSS
================================================================================
Purpose:
  Estimate synthetic risk and loss outputs for each application:
    - estimated-PD proxy
    - Loss Given Default (LGD)
    - Expected Loss (EL)

Why this section matters:
  This is the risk translation layer of the engine.

  Earlier sections established:
    - who the borrower is
    - what product they hold
    - how strong or weak their profile is
    - what payment burden that product creates

  This section converts those inputs into an explainable estimated-risk proxy
  and Expected Loss output.

Teaching note:
  This section uses an explainable, multiplier-based framework instead of
  a black-box statistical fit or calibrated production default model.

  In plain English, the risk logic works like this:
    1. Start with a base estimated-PD proxy by score band
    2. Adjust that base proxy up or down using interpretable risk multipliers
    3. Apply V2.0 soft saturation to reduce high-end cap crowding
    4. Bound the final estimated-PD proxy using governed floor / cap controls
    5. Attach a product-level LGD assumption
    6. Compute Expected Loss from amount * estimated-PD proxy * LGD

Important boundary:
  estimated_pd is a synthetic estimated-PD proxy. It is designed for scenario
  testing, segmentation analysis, affordability sensitivity, and Expected Loss
  comparison. It is not a calibrated production probability-of-default model.

Why this approach was chosen:
  The goal of Module 1 is not to replicate a proprietary credit model.
  The goal is to build a portfolio-grade, SQL-native, explainable simulation
  engine that demonstrates how credit structure, borrower behavior, and
  affordability can flow into risk outcomes.

Important modeling principle:
  This section intentionally favors:
    - transparency over opacity
    - calibration control over statistical complexity
    - teaching value over black-box optimization

This is especially important for portfolio demonstration purposes because it
allows future users to answer questions like:
  - Why did estimated-PD proxy increase?
  - Which borrower dimensions matter most?
  - What happens if PTI worsens but delinquencies remain clean?
  - How does product type affect risk holding other traits constant?

Governance interpretation:
  ESTIMATED-PD PROXY is bounded using:
    LEAST(0.450000, GREATEST(0.005000, ...))

  This prevents:
    - unrealistically low risk
    - runaway high-risk estimates

  The 45% cap is a simulation guardrail, not a calibrated production default-rate
  ceiling. It prevents runaway multiplier behavior, preserves a bounded severe-
  risk region, and keeps scenario outputs comparable.

  Workstream B does not assert that 45% is an empirical default threshold.
  Instead, it reduces unnecessary crowding near that cap so high-risk rows retain
  more differentiation below the governance ceiling.

  Important calibration note:
    During validation, one of the planned future enhancements identified for V2
    was reducing estimated-PD proxy cap crowding in the weakest segments. That
    conclusion came directly from the Section 9 review framework below, especially
    the product × score views and the portfolio-level estimated-PD proxy distribution
    review.

    B1 introduced the initial soft saturation architecture. B2 strengthened the
    saturation slopes after B1 validation showed that too many weak-end rows still
    reached the hard 45% cap.

    B3 applies one final light tightening after B2 validation showed improvement
    but remaining cap concentration. The objective is not to lower risk broadly;
    it is to preserve more ranking information below the cap while keeping deep
    subprime and other high-risk combinations clearly highest-risk.
*/

/*
================================================================================
SECTION 8 STAGE MATERIALIZATION
================================================================================
Purpose:
  Build estimated-PD proxy components, raw estimated-PD proxy, V2 soft saturation,
  final governed estimated-PD proxy, LGD, and expected loss inputs as a separate
  temporary stage.

Why this matters:
  Section 8 carries the widest audit trail because it includes base estimated-PD
  proxy, multipliers, saturation diagnostics, and final risk outputs. Materializing it
  separately keeps the final output build leaner and more stable.
*/

CREATE TEMP TABLE tmp_m1_stage_4_risk AS
WITH pd_components AS (
    SELECT
        a.*,

        /*
        ========================================================================
        8A. BASE ESTIMATED-PD PROXY BY SCORE BAND
        ========================================================================
        Goal:
          Establish the starting estimated-PD proxy before row-level
          multipliers are applied.

        Why start with score band?
          Score band is the highest-level summary of borrower credit quality in
          this engine. It is the cleanest first anchor for baseline risk.

        Hardcoded values explained:
          SUPER_PRIME   -> 1.00%
          PRIME         -> 2.50%
          NEAR_PRIME    -> 6.00%
          SUBPRIME      -> 14.00%
          DEEP_SUBPRIME -> 26.00%

        Why these values?
          They create a clear monotonic deterioration in baseline risk while
          still leaving room for row-level multipliers to differentiate borrowers
          inside each score band.

        Important concept:
          Base estimated-PD proxy is not the final answer. It is the starting point.
          The rest of this section explains how that starting point is adjusted.
        */
        CASE score_band
            WHEN 'SUPER_PRIME' THEN 0.010000
            WHEN 'PRIME'       THEN 0.025000
            WHEN 'NEAR_PRIME'  THEN 0.060000
            WHEN 'SUBPRIME'    THEN 0.140000
            ELSE                    0.260000
        END AS base_pd,

        /*
        ========================================================================
        8B. DELINQUENCY MULTIPLIER
        ========================================================================
        Logic:
          0 delinquencies -> 1.00
          1 delinquency   -> 1.20
          2 delinquencies -> 1.45
          3 delinquencies -> 1.75
          4+              -> 2.10

        Why this matters:
          Recent delinquency behavior is one of the strongest near-term signals
          of credit stress. The multipliers are intentionally nonlinear:
          deterioration from 0 -> 1 is meaningful, but repeated delinquency
          compounds risk more aggressively.
        */
        CASE
            WHEN delinquency_count_12m = 0 THEN 1.00
            WHEN delinquency_count_12m = 1 THEN 1.20
            WHEN delinquency_count_12m = 2 THEN 1.45
            WHEN delinquency_count_12m = 3 THEN 1.75
            ELSE 2.10
        END AS mult_delinq,

        /*
        ========================================================================
        8C. MAJOR DEROGATORY / BANKRUPTCY MULTIPLIERS
        ========================================================================
        mult_derog:
          1.60 if major derogatory event exists, otherwise 1.00

        mult_bankruptcy:
          1.85 if bankruptcy flag exists, otherwise 1.00

        Why these values?
          Bankruptcy is modeled as more severe than a generic major derogatory
          event, so it receives the larger multiplier.

        Why not make these even larger?
          Because they are layered on top of base estimated-PD proxy and other
          multipliers. Oversized multipliers would make the tail collapse into
          the estimated-PD proxy cap too quickly, which would reduce interpretability.
        */
        CASE WHEN major_derogatory_flag THEN 1.60 ELSE 1.00 END AS mult_derog,
        CASE WHEN bankruptcy_flag THEN 1.85 ELSE 1.00 END AS mult_bankruptcy,

        /*
        ========================================================================
        8D. UTILIZATION MULTIPLIER
        ========================================================================
        Thresholds:
          <10%  -> 0.95
          <30%  -> 1.00
          <50%  -> 1.10
          <75%  -> 1.25
          75%+  -> 1.45

        Why this matters:
          Utilization serves as a balance-pressure indicator. Very low
          utilization can be mildly protective, while high utilization suggests
          revolving stress and reduced liquidity.

        Why these breakpoints?
          They are simple, interpretable utilization buckets that create
          directional worsening without overfitting to a finer grid.
        */
        CASE
            WHEN utilization_rate < 0.10 THEN 0.95
            WHEN utilization_rate < 0.30 THEN 1.00
            WHEN utilization_rate < 0.50 THEN 1.10
            WHEN utilization_rate < 0.75 THEN 1.25
            ELSE 1.45
        END AS mult_util,

        /*
        ========================================================================
        8E. DTI MULTIPLIER
        ========================================================================
        Thresholds:
          <20%  -> 0.95
          <35%  -> 1.00
          <45%  -> 1.10
          <55%  -> 1.25
          55%+  -> 1.45

        Why this matters:
          DTI captures total leverage / obligation burden. This is broader than
          PTI because it includes existing debt obligations, not just the new
          simulated payment.

        Why both DTI and PTI?
          DTI and PTI measure related but different concepts:
            - DTI = total debt burden
            - PTI = burden from the newly structured payment
        */
        CASE
            WHEN debt_to_income_ratio < 0.20 THEN 0.95
            WHEN debt_to_income_ratio < 0.35 THEN 1.00
            WHEN debt_to_income_ratio < 0.45 THEN 1.10
            WHEN debt_to_income_ratio < 0.55 THEN 1.25
            ELSE 1.45
        END AS mult_dti,

        /*
        ========================================================================
        8F. INQUIRY MULTIPLIER
        ========================================================================
        Thresholds:
          <=1 inquiries -> 1.00
          <=3 inquiries -> 1.05
          <=5 inquiries -> 1.12
          6+ inquiries  -> 1.20

        Why this matters:
          Inquiry count is treated as a lightweight signal of recent credit
          seeking. It should influence risk, but much less than delinquency or
          bankruptcy.
        */
        CASE
            WHEN recent_inquiry_count_raw <= 1 THEN 1.00
            WHEN recent_inquiry_count_raw <= 3 THEN 1.05
            WHEN recent_inquiry_count_raw <= 5 THEN 1.12
            ELSE 1.20
        END AS mult_inquiry,

        /*
        ========================================================================
        8G. TRADELINE DEPTH MULTIPLIER
        ========================================================================
        Thresholds:
          1-2 trades   -> 1.12
          3-5 trades   -> 1.05
          6-12 trades  -> 1.00
          13-18 trades -> 1.03
          19+ trades   -> 1.08

        Why this shape?
          This is the mild U-shaped file-depth effect discussed during design.

          Interpretation:
            - very thin files carry more uncertainty
            - moderate / mature files are most stable
            - very heavy files are not automatically "best"; they may signal more
              complex leverage structure, so a mild upward adjustment is allowed

        This is intentionally a mild effect, not a dominant one.
        */
        CASE
            WHEN tradeline_count BETWEEN 1 AND 2 THEN 1.12
            WHEN tradeline_count BETWEEN 3 AND 5 THEN 1.05
            WHEN tradeline_count BETWEEN 6 AND 12 THEN 1.00
            WHEN tradeline_count BETWEEN 13 AND 18 THEN 1.03
            ELSE 1.08
        END AS mult_tradeline,

        /*
        ========================================================================
        8H. FILE AGE MULTIPLIER
        ========================================================================
        Thresholds:
          <12 months -> 1.18
          <24 months -> 1.10
          <60 months -> 1.05
          60+ months -> 1.00

        Why this matters:
          Shorter file history is treated as more uncertain and somewhat riskier.
          Older files are treated as more stable because they represent longer
          observed borrower behavior.
        */
        CASE
            WHEN months_since_oldest_trade < 12 THEN 1.18
            WHEN months_since_oldest_trade < 24 THEN 1.10
            WHEN months_since_oldest_trade < 60 THEN 1.05
            ELSE 1.00
        END AS mult_file_age,

        /*
        ========================================================================
        8I. PTI MULTIPLIER
        ========================================================================
        Thresholds:
          <5%   -> 0.95
          <10%  -> 1.00
          <15%  -> 1.10
          <20%  -> 1.25
          20%+  -> 1.45

        Why this matters:
          PTI is the central affordability bridge in Module 1. It directly
          reflects how burdensome the newly simulated payment is relative to
          borrower income.

        Why this was important in validation:
          One of the key conclusions documented in the header was that PTI behaved
          as intended after mortgage recalibration. Section 9.7 below is designed
          specifically to validate this multiplier structure at the portfolio level.
        */
        CASE
            WHEN payment_to_income_ratio < 0.05 THEN 0.95
            WHEN payment_to_income_ratio < 0.10 THEN 1.00
            WHEN payment_to_income_ratio < 0.15 THEN 1.10
            WHEN payment_to_income_ratio < 0.20 THEN 1.25
            ELSE 1.45
        END AS mult_pti,

        /*
        ========================================================================
        8J. AMOUNT-TO-INCOME MULTIPLIER
        ========================================================================
        Thresholds:
          <0.10 -> 1.00
          <0.30 -> 1.03
          <0.60 -> 1.08
          <1.00 -> 1.15
          1.00+ -> 1.25

        Why this matters:
          PTI captures monthly burden, but amount-to-income captures total
          exposure size relative to annual income. This gives the model another
          lens on leverage intensity.
        */
        CASE
            WHEN amount_to_income_ratio < 0.10 THEN 1.00
            WHEN amount_to_income_ratio < 0.30 THEN 1.03
            WHEN amount_to_income_ratio < 0.60 THEN 1.08
            WHEN amount_to_income_ratio < 1.00 THEN 1.15
            ELSE 1.25
        END AS mult_amt_income,

        /*
        ========================================================================
        8K. PRODUCT MULTIPLIER
        ========================================================================
        Values:
          Mortgage              -> 0.90
          Auto                  -> 1.00
          Unsecured Personal    -> 1.10
          Revolving Line        -> 1.12
          HELOC                 -> 0.95

        Why product matters:
          Product type is not merely a structural label. Different products
          carry different borrower behavior patterns, collateral profiles,
          and usage characteristics.

        Why these relative values?
          - Mortgage receives a modest downward adjustment because it is secured
            and typically underwritten more conservatively
          - HELOC also receives a mild downward adjustment
          - Personal and revolving products receive upward adjustments to reflect
            their generally less protected / more behavior-sensitive nature
        */
        CASE product_type
            WHEN 'MORTGAGE' THEN 0.90
            WHEN 'AUTO_LOAN' THEN 1.00
            WHEN 'UNSECURED_PERSONAL_LOAN' THEN 1.10
            WHEN 'REVOLVING_LINE' THEN 1.12
            WHEN 'HELOC' THEN 0.95
        END AS mult_product
    FROM tmp_m1_stage_3_product_structuring a
),

pd_raw AS (
    SELECT
        p.*,

        /*
        ========================================================================
        8L. RAW ESTIMATED-PD PROXY BEFORE SATURATION / GOVERNANCE CAP
        ========================================================================
        Formula:
          pd_raw_pre_saturation_v2 =
            base_pd
            * mult_delinq
            * mult_derog
            * mult_bankruptcy
            * mult_util
            * mult_dti
            * mult_inquiry
            * mult_tradeline
            * mult_file_age
            * mult_pti
            * mult_amt_income
            * mult_product
            * stochastic_jitter

        Why multiplicative?
          A multiplicative framework is simple, explainable, and preserves the
          idea that multiple stress dimensions can compound risk.

        Why stochastic jitter?
          (0.95 + (u15 * 0.10)) produces a factor from 0.95 to 1.05.

          This adds a small row-level noise term so that borrowers with nearly
          identical characteristics do not always end with the exact same raw
          estimated-PD proxy.

        Why preserve raw estimated-PD proxy separately in V2?
          In V1, the multiplied estimated-PD proxy was passed directly into the final floor / cap:

            LEAST(0.450000, GREATEST(0.005000, raw_pd))

          That created a useful governance rail, but it also caused many
          high-risk rows to crowd near the 45% cap.

          V2 preserves the raw multiplied estimated-PD proxy first so reviewers can
          inspect the unconstrained risk pressure before the soft saturation layer and final
          governance cap are applied.

        Validation connection:
          V1 validation identified weak-end estimated-PD proxy cap crowding as a refinement
          opportunity. This field allows V2 to show exactly how much raw risk
          pressure existed before the new saturation layer reshaped the high-end
          tail.
        */
        round(
            (
                base_pd
                * mult_delinq
                * mult_derog
                * mult_bankruptcy
                * mult_util
                * mult_dti
                * mult_inquiry
                * mult_tradeline
                * mult_file_age
                * mult_pti
                * mult_amt_income
                * mult_product
                * (0.95 + (u15 * 0.10))
            )
        ,6) AS pd_raw_pre_saturation_v2

    FROM pd_components p
),

pd_saturation AS (
    SELECT
        r.*,

        /*
        ========================================================================
        8M. V2 ESTIMATED-PD PROXY SOFT SATURATION LAYER
        ========================================================================
        Purpose:
          Reduce excessive crowding near the hard estimated-PD proxy cap while preserving the
          explainable multiplier-based estimated-PD proxy framework.

        Why this layer exists:
          V1 validation showed that weakest product / score combinations often
          reached or approached the 45% estimated-PD proxy cap. The cap itself is a useful
          governance control, but excessive cap crowding reduces differentiation
          inside the high-risk tail.

        Design principle:
          Do not rewrite the estimated-PD proxy model.
          Do not lower weak-risk borrowers broadly.
          Do not remove the hard cap.

          Instead, reshape the high-end raw estimated-PD proxy tail before the hard cap is
          applied.

        Zone design:
          NORMAL:
            raw estimated-PD proxy <= 0.30
            no saturation needed

          HIGH:
            0.30 < raw estimated-PD proxy <= 0.55
            moderate compression of high-risk growth

          EXTREME:
            raw estimated-PD proxy > 0.55
            stronger compression before the hard cap

        Important interpretation:
          This is a soft saturation layer, not a policy decline rule and not a
          calibrated production default model. It is a simulation control used to
          preserve more ranking information below the cap.
        */
        CASE
            WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN 'NORMAL'
            WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN 'HIGH'
            ELSE 'EXTREME'
        END AS pd_saturation_zone_v2,

		/*
		pd_saturation_factor_v2:
		  The ratio of saturated estimated-PD proxy to raw estimated-PD proxy.
		
		Interpretation:
		  - 1.000000 means no saturation was applied
		  - values below 1.000000 mean high-end raw estimated-PD proxy was compressed
		
		B3 calibration note:
		  B1 introduced the soft saturation architecture. B2 reduced cap crowding, but
		  validation still showed remaining concentration near the 45% hard cap.
		
		  B3 applies a final light tightening while keeping:
		    - the same raw estimated-PD proxy framework
		    - the same zone thresholds
		    - the same final 45% governance cap
		    - the same audit-visible raw and post-saturation estimated-PD proxy fields
		
		Audit interpretation:
		  This factor allows reviewers to see exactly how strongly the B3 saturation
		  layer compressed a row before the final hard floor / cap was applied.
		
		Expected behavior:
		  - fewer rows exactly at estimated_pd = 0.450000
		  - more separation below the cap in the weakest score bands
		  - no break in monotonic risk ordering
		*/
		round(
		    CASE
		        WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN 1.000000
		
		        WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN
		            (
		                0.300000
		                + ((pd_raw_pre_saturation_v2 - 0.300000) * 0.500000)
		            )
		            / NULLIF(pd_raw_pre_saturation_v2, 0)
		
		        ELSE
		            (
		                0.425000
		                + ((pd_raw_pre_saturation_v2 - 0.550000) * 0.150000)
		            )
		            / NULLIF(pd_raw_pre_saturation_v2, 0)
		    END
		,6) AS pd_saturation_factor_v2,

		/*
		pd_after_saturation_v2:
		  Raw estimated-PD proxy after the soft high-end saturation layer, but before the final
		  hard floor / cap is applied.
		
		Formula design:
		  1. raw estimated-PD proxy <= 0.30:
		       unchanged
		
		  2. 0.30 < raw estimated-PD proxy <= 0.55:
		       0.30 + ((raw_pd - 0.30) * 0.50)
		
		  3. raw estimated-PD proxy > 0.55:
		       0.4250 + ((raw_pd - 0.55) * 0.15)
		
		Why these values:
		  B1 used a 0.70 HIGH-zone slope and mapped raw estimated-PD proxy = 0.55 to 0.475.
		  Because final estimated-PD proxy is capped at 0.45, that still left substantial weak-end cap
		  crowding.
		
		  B2 improved the issue by lowering the HIGH-zone slope to 0.55 and the EXTREME
		  slope to 0.20. Validation showed meaningful improvement, but remaining cap
		  concentration was still higher than desired for a polished simulation output.
		
		  B3 uses a 0.50 HIGH-zone slope:
		      0.30 + (0.25 * 0.50) = 0.4250
		
		  This means the top of the HIGH zone now remains comfortably below the hard
		  45% cap, preserving more ranking room before governance capping occurs.
		
		  For the EXTREME zone, B3 starts from 0.4250 and uses a flatter 0.15 slope.
		  This still allows the most severe raw-risk rows to approach or reach the cap,
		  but makes broad cap crowding less likely.
		
		Expected validation result:
		  - materially fewer rows exactly at the estimated-PD proxy governance cap of 0.450000
		  - more spread between roughly 0.35 and 0.45
		  - deep subprime remains the riskiest score band
		  - subprime remains clearly riskier than near-prime
		  - product × score ordering remains directionally coherent
		  - expected loss should decline modestly, not collapse
		*/
		round(
		    CASE
		        WHEN pd_raw_pre_saturation_v2 <= 0.300000 THEN
		            pd_raw_pre_saturation_v2
		
		        WHEN pd_raw_pre_saturation_v2 <= 0.550000 THEN
		            0.300000
		            + ((pd_raw_pre_saturation_v2 - 0.300000) * 0.500000)
		
		        ELSE
		            0.425000
		            + ((pd_raw_pre_saturation_v2 - 0.550000) * 0.150000)
		    END
		,6) AS pd_after_saturation_v2

    FROM pd_raw r
),

pd_and_loss AS (
    SELECT
        s.*,

        /*
        ========================================================================
        8N. FINAL GOVERNED ESTIMATED-PD PROXY ESTIMATION
        ========================================================================
        Purpose:
          Apply the final governance floor and cap after the V2 soft saturation
          layer.

        Final estimated-PD proxy flow:
          raw multiplied estimated-PD proxy
            -> soft saturation
            -> hard floor / cap

        Why floor and cap?
          GREATEST(0.005000, ...) sets a 0.50% floor
          LEAST(0.450000, ...) sets a 45.00% cap

        Why those values?
          0.50% floor:
            prevents unrealistically tiny estimated-PD proxy values for strong rows

          45.00% cap:
            prevents runaway tail values from becoming implausible or dominating
            expected loss excessively

        Why keep the hard cap in V2?
          The 45% cap remains a deliberate governance rail. Workstream B does not
          remove the cap; it reduces unnecessary crowding before the cap by
          reshaping high-end raw estimated-PD proxy values through pd_after_saturation_v2.

        Validation connection:
          The V1 validation narrative identified weak-end estimated-PD proxy cap crowding
          as a future refinement opportunity. This V2 logic directly addresses that
          finding while preserving the original explainable multiplier structure.
        */
        round(
            LEAST(
                0.450000,
                GREATEST(
                    0.005000,
                    pd_after_saturation_v2
                )
            )
        ,6) AS estimated_pd,

        /*
        ========================================================================
        8O. LGD ASSIGNMENT
        ========================================================================
        Logic:
          LGD is attached directly by product from the parameter block.

        Why is LGD simpler than the estimated-PD proxy framework?
          That was an intentional Module 1 design decision documented in the
          header. The estimated-PD proxy framework is the richer behavioral model here;
          LGD is kept simpler so that users can still test expected loss sensitivity
          without requiring a full collateral / recovery simulation engine.
        */
        CASE product_type
            WHEN 'MORTGAGE' THEN lgd_mortgage
            WHEN 'AUTO_LOAN' THEN lgd_auto
            WHEN 'UNSECURED_PERSONAL_LOAN' THEN lgd_personal
            WHEN 'REVOLVING_LINE' THEN lgd_revolving
            WHEN 'HELOC' THEN lgd_heloc
        END AS estimated_lgd

    FROM pd_saturation s
)

SELECT *
FROM pd_and_loss;

/*
================================================================================
FINAL OUTPUT TABLE BUILD
================================================================================
Purpose:
  Create the final permanent output table from the fully materialized risk stage.

Why this exists:
  The model has already been built through smaller, stable temp-table stages.
  This final statement only selects and orders the audit-ready output columns.
*/

CREATE TABLE credit_decisioning_sim.synthetic_applications AS
SELECT
    /*
    ============================================================================
    8P. FINAL OUTPUT SHAPE
    ============================================================================
    Purpose:
      Expose both the final business-facing outputs and the underlying model
      components used to create them.

    Why include all the multiplier and V2 audit fields?
      This makes the engine auditable and teachable. A future user can inspect
      not only the final estimated-PD proxy, but exactly which factors contributed
      to it and how the V2 saturation layer affected high-end raw risk pressure.
    */
    'V2.0' AS model_version,
    scenario_set_name,
    scenario_name,
    population_id,
    anchor_date,
    application_seq,
    application_id,
    applicant_id,
    application_date,
    product_type,
    score_band,
    credit_score,
    annual_income,
    debt_to_income_ratio,
    utilization_rate,
    tradeline_count,
    months_since_oldest_trade,
    recent_inquiry_count_raw AS recent_inquiry_count,
    delinquency_count_12m,
    major_derogatory_flag,
    bankruptcy_flag,
    prequalified_flag,
    returning_customer_flag,
    requested_amount,
    mortgage_candidate_amount_v2,
    mortgage_candidate_amt_income_ratio_v2,
    mortgage_tail_zone_v2,
    mortgage_tail_smoothing_factor_v2,
    mortgage_requested_amount_pre_floor_v2,
    mortgage_provisional_monthly_payment_v2,
    mortgage_provisional_pti_v2,
    mortgage_pti_dampener_zone_v2,
    mortgage_pti_dampener_factor_v2,
    mortgage_requested_amount_post_pti_dampener_v2,
    loan_term_months,
    base_apr_for_payment_calc,
    monthly_payment_proxy,
    payment_to_income_ratio,
    amount_to_income_ratio,
    base_pd,
    mult_delinq,
    mult_derog,
    mult_bankruptcy,
    mult_util,
    mult_dti,
    mult_inquiry,
    mult_tradeline,
    mult_file_age,
    mult_pti,
    mult_amt_income,
    mult_product,
    pd_raw_pre_saturation_v2,
    pd_saturation_zone_v2,
    pd_saturation_factor_v2,
    pd_after_saturation_v2,
    estimated_pd,
    estimated_lgd,

    /*
    expected_loss_amount:
      Expected Loss = Exposure * estimated-PD proxy * LGD

    Why this matters:
      This is the final portfolio economics metric for Module 1. It translates
      borrower quality and product structure into a loss expectation that can be
      aggregated later for strategy testing.
    */
    round(requested_amount * estimated_pd * estimated_lgd, 2) AS expected_loss_amount,

    -- created_ts:
    -- capture creation time for traceability / rerun auditing
    CURRENT_TIMESTAMP AS created_ts
FROM tmp_m1_stage_4_risk
;

/*
================================================================================
FINAL OUTPUT INDEXES
================================================================================
Purpose:
  Improve performance for Section 9 QA queries.

Why these indexes:
  Most validation queries group or filter by product_type, score_band, or both.
  Indexing those fields helps PostgreSQL scan the final output more efficiently.
*/

CREATE INDEX IF NOT EXISTS idx_synth_app_product
ON credit_decisioning_sim.synthetic_applications (product_type);

CREATE INDEX IF NOT EXISTS idx_synth_app_score
ON credit_decisioning_sim.synthetic_applications (score_band);

CREATE INDEX IF NOT EXISTS idx_synth_app_product_score
ON credit_decisioning_sim.synthetic_applications (product_type, score_band);

/*
================================================================================
SECTION 8.5. SCENARIO ARCHIVE / RUN PERSISTENCE
================================================================================
Purpose:
  Preserve completed Module 1 runs in a governed scenario archive so users can
  compare multiple scenarios without losing the latest-run output table.

Why this section exists:
  The primary output table:
      credit_decisioning_sim.synthetic_applications

  intentionally represents the latest completed run.

  That is ideal for single-run QA, but scenario comparison requires preserving
  multiple completed runs side by side. This archive table provides that
  persistence while still keeping the main output table simple.

Key concept:
  scenario_set_name = comparison family / project grouping
  scenario_name     = individual run inside that family
  population_id     = deterministic borrower population

Examples:
  scenario_set_name = RATE_STRESS_TESTS
      scenario_name = BASELINE_V2
      scenario_name = RATE_UP_200BP

  scenario_set_name = CREDIT_TIGHTENING_TESTS
      scenario_name = BASELINE_V2
      scenario_name = TIGHTER_CREDIT_BOX

Why this design matters:
  A single shared archive table is easier to govern than many project-specific
  physical tables. scenario_set_name provides flexibility without table sprawl.

Reset behavior:
  archive_reset_mode controls how much prior archive history is cleared before
  the current run is inserted.

  NONE:
    Preserve prior archive rows.

  SCENARIO_ONLY:
    Replace only the current scenario within the current scenario set and
    population. This is the recommended default for reruns.

  SET_ONLY:
    Clear all scenarios in the current scenario set for the current population.

  ALL:
    Clear the entire archive table. Use only when intentionally starting over.

Audit note:
  The archive stores the final output columns plus scenario_archived_ts. This allows
  reviewers to confirm when a scenario was archived and compare results across
  deterministic runs.
  
Development note:
  If the final output schema changes during future development, recreate or
  alter the archive table so its columns remain aligned with synthetic_applications.
*/

CREATE TABLE IF NOT EXISTS credit_decisioning_sim.synthetic_applications_scenario_archive
(LIKE credit_decisioning_sim.synthetic_applications INCLUDING DEFAULTS);

ALTER TABLE credit_decisioning_sim.synthetic_applications_scenario_archive
ADD COLUMN IF NOT EXISTS scenario_archived_ts TIMESTAMP;

-- Archive reset controller:
-- This DO block reads the current run controls from tmp_module1_params and
-- deletes only the archive rows requested by archive_reset_mode.
DO $$
DECLARE
    p RECORD;
BEGIN
    SELECT * INTO p FROM tmp_module1_params;

    IF p.archive_run_flag = TRUE THEN

        IF p.archive_reset_mode = 'ALL' THEN
            DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive;

        ELSIF p.archive_reset_mode = 'SET_ONLY' THEN
            DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
            WHERE scenario_set_name = p.scenario_set_name
              AND population_id = p.population_id;

        ELSIF p.archive_reset_mode = 'SCENARIO_ONLY' THEN
            DELETE FROM credit_decisioning_sim.synthetic_applications_scenario_archive
            WHERE scenario_set_name = p.scenario_set_name
              AND scenario_name = p.scenario_name
              AND population_id = p.population_id;

        ELSIF p.archive_reset_mode = 'NONE' THEN
            -- Preserve existing archive rows.
            NULL;
        END IF;

    END IF;
END $$;

-- Insert the latest run into the scenario archive only when archive_run_flag is TRUE.
INSERT INTO credit_decisioning_sim.synthetic_applications_scenario_archive
SELECT
    s.*,
    CURRENT_TIMESTAMP AS scenario_archived_ts
FROM credit_decisioning_sim.synthetic_applications s
CROSS JOIN tmp_module1_params p
WHERE p.archive_run_flag = TRUE;

-- Helpful indexes for Section 10 scenario comparison queries.
CREATE INDEX IF NOT EXISTS idx_synth_archive_set_scenario_population
ON credit_decisioning_sim.synthetic_applications_scenario_archive
(scenario_set_name, scenario_name, population_id);

CREATE INDEX IF NOT EXISTS idx_synth_archive_matched_row
ON credit_decisioning_sim.synthetic_applications_scenario_archive
(scenario_set_name, population_id, application_id);

CREATE INDEX IF NOT EXISTS idx_synth_archive_product_score
ON credit_decisioning_sim.synthetic_applications_scenario_archive
(scenario_set_name, scenario_name, population_id, product_type, score_band);

/*
================================================================================
SECTION 9. QA / REVIEW QUERIES
================================================================================
Purpose:
  Validate whether the generated portfolio behaves as intended.

Why this section matters:
  This section is not an optional appendix. It is the evidence layer that
  supports the conclusions documented in the header of the script.

  In particular, this review framework was used to support the following V1
  validation conclusions:
    - the engine behaves like a portfolio-grade synthetic application and risk engine
    - the score-band and product logic are directionally realistic
    - PTI behaves as a meaningful affordability bridge into estimated-PD proxy
    - the mortgage calibration materially improved unrealistic exposure / PTI behavior

  V1 validation identified two key refinement opportunities that are now
  implemented in V2:

    1. upper-tail mortgage affordability refinement
    2. weak-end estimated-PD proxy cap crowding refinement

  This Section 9 framework has been expanded to validate that those
  enhancements:
    - materially improved mortgage upper-tail realism (A2 + A3)
    - reduced estimated-PD proxy cap crowding while preserving risk ordering

Teaching note:
  Synthetic realism should be tested deliberately. A script that "runs" is not
  automatically a script that produced a plausible portfolio.

  The queries below are organized as a structured review workflow:
    1. Data integrity
    2. Distribution validation
    3. Variable profiling
    4. Segment behavior
    5. Affordability impact
    6. Cross-sectional realism
    7. Edge-case inspection
    8. Tail-frequency validation

How to use this section:
  The best practice is to review these queries in sequence after any meaningful
  parameter or logic change. Together they answer:
    - Did the engine build the right number of records?
    - Did the target product / score mixes land correctly?
    - Are the distributions plausible?
    - Do stronger borrowers generally look stronger?
    - Do products remain differentiated?
    - Does affordability translate into estimated risk as intended?
    - Are edge cases plausible rather than absurd?
    - Is the high-PTI tail present but non-dominant?    

V2 validation focus:
  In addition to core portfolio realism, V2 introduces five specific validation
  objectives:

    - A2 mortgage tail smoothing effectiveness
        * large mortgage exposures should remain plausible relative to income
        * extreme amount-to-income ratios should be reduced but not eliminated

    - A3 PTI-aware affordability cleanup
        * only the highest-PTI mortgage rows should be affected
        * typical mortgage rows should remain unchanged

    - estimated-PD proxy soft saturation behavior
        * fewer rows should cluster at the estimated-PD proxy cap (~0.45)
        * high-risk segments should show improved dispersion below the cap
        * overall risk ordering must remain intact

    - PTI tail frequency validation
        * high-PTI rows should remain present but non-dominant
        * severe affordability-stress rows should not dominate the portfolio
        * V2.0 should demonstrate controlled PTI tail behavior versus V1.0

    - Workstream D revolving payment sensitivity
        * revolving payment should respond to APR movement
        * APR changes should contribute directionally to payment burden
        * the relationship should support APR → payment → PTI → estimated-PD proxy
          transmission without turning Module 1 into a full billing-cycle model

How to interpret "directional realism":
  The goal is not perfection or monotonicity in every single row.
  The goal is that, on average, the portfolio should behave like a believable
  lending population.

  For example:
    - stronger score bands should usually have:
        higher credit scores
        higher income
        lower DTI
        lower utilization
        fewer recent delinquencies
        fewer major derogatory events
        lower bankruptcy rates
        lower PTI
        lower estimated-PD proxy
        lower expected loss

    - weaker score bands should usually show the opposite pattern

  But:
    - some strong borrowers should still look stretched
    - some weaker borrowers should still look manageable
    - products should not collapse into the same behavior
    - not every row should fit a stereotype

  That overlap is a sign of realism, not a flaw.

Plain-English variable guide:
  credit_score
    = broad borrower credit quality summary

  annual_income
    = borrower income capacity

  debt_to_income_ratio (DTI)
    = how much of income is already committed to debt overall

  utilization_rate
    = how heavily revolving credit is being used

  tradeline_count
    = how many credit accounts / trades are on file

  months_since_oldest_trade
    = how seasoned the borrower’s credit file is

  recent_inquiry_count
    = recent credit shopping / application activity

  requested_amount
    = final exposure size

  base_apr_for_payment_calc
    = pricing proxy used for payment burden

  monthly_payment_proxy
    = estimated monthly payment burden

  payment_to_income_ratio (PTI)
    = monthly payment burden divided by monthly income

  amount_to_income_ratio
    = overall exposure size relative to annual income

  estimated_pd
    = synthetic estimated-PD proxy used for scenario testing, segmentation,
      affordability sensitivity, and Expected Loss comparison

  estimated_lgd
    = modeled loss severity if default occurs

  expected_loss_amount
    = requested_amount * estimated_pd * estimated_lgd
    
      where estimated_pd is interpreted as the synthetic estimated-PD proxy.

Reviewer mindset:
  Do not ask:
    "Is every single row perfect?"

  Ask:
    "Does the portfolio, in aggregate and by segment, behave like a governed,
     realistic credit population?"

Interpretation principle:
  A statistically "clean" portfolio can still be unrealistic.
  A realistic portfolio often contains exceptions, overlap, and tails.
  The job of this section is to distinguish healthy realism from broken logic.
*/

-- 9.1 Record count
-- Purpose:
--   Confirm that the final table contains the expected number of applications.
--
-- Why this matters:
--   This is the first integrity check. If record count is wrong, every later
--   distribution and risk summary becomes suspect.
--
-- What success looks like:
--   application_count should exactly match the parameter value from Section 2.
--
-- If this fails:
--   stop here and debug before trusting any later query.

SELECT COUNT(*) AS application_count
FROM credit_decisioning_sim.synthetic_applications;

-- 9.2 Product mix
-- Purpose:
--   Confirm that the generated product distribution is reasonably aligned to
--   the configured product mix assumptions in the parameter block.
--
-- Why this matters:
--   Section 5 assigns product via cumulative probability thresholds. This query
--   verifies that the realized population approximately matches the intended
--   portfolio composition.
--
-- What to look for:
--   - close alignment to configured product mix
--   - no unexpected concentration in any one product
--   - evidence that product assignment is working as designed
--
-- Example interpretation:
--   If the parameter block says mortgage = 30% and revolving = 25%, the
--   realized portfolio should be close to those values, allowing for minor
--   sampling variation.
--
-- What would be suspicious:
--   - a product heavily over- or under-represented
--   - totals far away from the configured mix
--   - a mix that changes unexpectedly after unrelated code edits

SELECT
    product_type,
    COUNT(*) AS applications,
    ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct_of_total
FROM credit_decisioning_sim.synthetic_applications
GROUP BY product_type
ORDER BY applications DESC;

-- 9.3 Score band distribution
-- Purpose:
--   Confirm that the generated score-band mix is reasonably aligned to the configured
--   score distribution assumptions.
--
-- Why this matters:
--   The base risk profile of the whole portfolio starts here. If score-band mix
--   is materially off, all portfolio-level estimated-PD proxy and EL summaries will shift.
--
-- What to look for:
--   - realized score-band shares should be close to the configured shares
--   - the portfolio should not unexpectedly collapse into only strong or weak bands
--
-- Example interpretation:
--   If prime and near-prime are intended to dominate the mix, they should
--   appear as the largest segments here.
--
-- What would be suspicious:
--   - deep subprime suddenly becoming the majority of the file
--   - super-prime disappearing unexpectedly
--   - major drift after changing code unrelated to score assignment

SELECT
    score_band,
    COUNT(*) AS applications,
    ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct_of_total
FROM credit_decisioning_sim.synthetic_applications
GROUP BY score_band
ORDER BY
    CASE score_band
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        ELSE 5
    END;

-- 9.4 Variable profile statistics
-- Purpose:
--   Profile the overall portfolio distribution for key continuous variables.
--
-- Why this matters:
--   This is the main portfolio-shape review. It helps validate the conclusion
--   that V1 behaves like a portfolio-grade synthetic engine rather than a set
--   of disconnected random columns.
--
-- What to look for:
--   - reasonable minimum / maximum values
--   - enough spread to avoid unrealistic compression
--   - medians and means that tell a sensible story about skew
--   - tails that feel plausible rather than chaotic
--   - no obvious evidence of runaway mortgage burden after calibration
--
-- How to read the columns:
--   min_val  = smallest value observed
--   p25      = 25th percentile (lower-quartile marker)
--   median   = midpoint of the distribution
--   mean     = average
--   p75      = 75th percentile (upper-quartile marker)
--   max_val  = largest value observed
--   std_dev  = spread / volatility of the variable
--
-- How to think about this:
--   This query helps answer:
--     "Does each variable look like it belongs in the same portfolio?"
--
-- Examples of healthy patterns:
--   credit_score:
--     should live in a believable range and show broad spread
--
--   annual_income:
--     should show meaningful variation without collapsing to the floor or ceiling
--
--   debt_to_income_ratio:
--     should have a plausible middle, with some stressed tail but not all rows
--     clustered at high values
--
--   utilization_rate:
--     should show low-use, medium-use, and stressed-use borrowers
--
--   requested_amount:
--     should show broad variation by product without absurd portfolio-wide extremes
--
--   payment_to_income_ratio:
--     should not show most rows at extremely high burden levels
--
--   estimated_pd:
--     should show clear variation without excessive clustering at the floor or cap
--
--     V2 expectation:
--       - fewer rows exactly at the 0.45 cap
--       - more dispersion in the high-risk tail
--       - overall distribution still bounded and realistic
--
-- SQL teaching note:
--   UNION ALL is used here to stack multiple one-row variable summaries into
--   one vertically readable profiling table.

SELECT
    'credit_score' AS variable_name,
    COUNT(*) AS n,
    ROUND(MIN(credit_score)::numeric, 2) AS min_val,
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY credit_score))::numeric, 2) AS p25,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY credit_score))::numeric, 2) AS median,
    ROUND(AVG(credit_score)::numeric, 2) AS mean,
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY credit_score))::numeric, 2) AS p75,
    ROUND(MAX(credit_score)::numeric, 2) AS max_val,
    ROUND(STDDEV_POP(credit_score)::numeric, 2) AS std_dev
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'annual_income',
    COUNT(*),
    ROUND(MIN(annual_income)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY annual_income))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY annual_income))::numeric, 2),
    ROUND(AVG(annual_income)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY annual_income))::numeric, 2),
    ROUND(MAX(annual_income)::numeric, 2),
    ROUND(STDDEV_POP(annual_income)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'debt_to_income_ratio',
    COUNT(*),
    ROUND(MIN(debt_to_income_ratio)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY debt_to_income_ratio))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY debt_to_income_ratio))::numeric, 4),
    ROUND(AVG(debt_to_income_ratio)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY debt_to_income_ratio))::numeric, 4),
    ROUND(MAX(debt_to_income_ratio)::numeric, 4),
    ROUND(STDDEV_POP(debt_to_income_ratio)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'utilization_rate',
    COUNT(*),
    ROUND(MIN(utilization_rate)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY utilization_rate))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY utilization_rate))::numeric, 4),
    ROUND(AVG(utilization_rate)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY utilization_rate))::numeric, 4),
    ROUND(MAX(utilization_rate)::numeric, 4),
    ROUND(STDDEV_POP(utilization_rate)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'tradeline_count',
    COUNT(*),
    ROUND(MIN(tradeline_count)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tradeline_count))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY tradeline_count))::numeric, 2),
    ROUND(AVG(tradeline_count)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tradeline_count))::numeric, 2),
    ROUND(MAX(tradeline_count)::numeric, 2),
    ROUND(STDDEV_POP(tradeline_count)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'months_since_oldest_trade',
    COUNT(*),
    ROUND(MIN(months_since_oldest_trade)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY months_since_oldest_trade))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY months_since_oldest_trade))::numeric, 2),
    ROUND(AVG(months_since_oldest_trade)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY months_since_oldest_trade))::numeric, 2),
    ROUND(MAX(months_since_oldest_trade)::numeric, 2),
    ROUND(STDDEV_POP(months_since_oldest_trade)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'recent_inquiry_count',
    COUNT(*),
    ROUND(MIN(recent_inquiry_count)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY recent_inquiry_count))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY recent_inquiry_count))::numeric, 2),
    ROUND(AVG(recent_inquiry_count)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY recent_inquiry_count))::numeric, 2),
    ROUND(MAX(recent_inquiry_count)::numeric, 2),
    ROUND(STDDEV_POP(recent_inquiry_count)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'requested_amount',
    COUNT(*),
    ROUND(MIN(requested_amount)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY requested_amount))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY requested_amount))::numeric, 2),
    ROUND(AVG(requested_amount)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY requested_amount))::numeric, 2),
    ROUND(MAX(requested_amount)::numeric, 2),
    ROUND(STDDEV_POP(requested_amount)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'base_apr_for_payment_calc',
    COUNT(*),
    ROUND(MIN(base_apr_for_payment_calc)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY base_apr_for_payment_calc))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY base_apr_for_payment_calc))::numeric, 4),
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY base_apr_for_payment_calc))::numeric, 4),
    ROUND(MAX(base_apr_for_payment_calc)::numeric, 4),
    ROUND(STDDEV_POP(base_apr_for_payment_calc)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'monthly_payment_proxy',
    COUNT(*),
    ROUND(MIN(monthly_payment_proxy)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY monthly_payment_proxy))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY monthly_payment_proxy))::numeric, 2),
    ROUND(AVG(monthly_payment_proxy)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY monthly_payment_proxy))::numeric, 2),
    ROUND(MAX(monthly_payment_proxy)::numeric, 2),
    ROUND(STDDEV_POP(monthly_payment_proxy)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'payment_to_income_ratio',
    COUNT(*),
    ROUND(MIN(payment_to_income_ratio)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY payment_to_income_ratio))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY payment_to_income_ratio))::numeric, 4),
    ROUND(AVG(payment_to_income_ratio)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY payment_to_income_ratio))::numeric, 4),
    ROUND(MAX(payment_to_income_ratio)::numeric, 4),
    ROUND(STDDEV_POP(payment_to_income_ratio)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'amount_to_income_ratio',
    COUNT(*),
    ROUND(MIN(amount_to_income_ratio)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount_to_income_ratio))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY amount_to_income_ratio))::numeric, 4),
    ROUND(AVG(amount_to_income_ratio)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount_to_income_ratio))::numeric, 4),
    ROUND(MAX(amount_to_income_ratio)::numeric, 4),
    ROUND(STDDEV_POP(amount_to_income_ratio)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'estimated_pd',
    COUNT(*),
    ROUND(MIN(estimated_pd)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY estimated_pd))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY estimated_pd))::numeric, 4),
    ROUND(AVG(estimated_pd)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY estimated_pd))::numeric, 4),
    ROUND(MAX(estimated_pd)::numeric, 4),
    ROUND(STDDEV_POP(estimated_pd)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'estimated_lgd',
    COUNT(*),
    ROUND(MIN(estimated_lgd)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY estimated_lgd))::numeric, 4),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY estimated_lgd))::numeric, 4),
    ROUND(AVG(estimated_lgd)::numeric, 4),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY estimated_lgd))::numeric, 4),
    ROUND(MAX(estimated_lgd)::numeric, 4),
    ROUND(STDDEV_POP(estimated_lgd)::numeric, 4)
FROM credit_decisioning_sim.synthetic_applications

UNION ALL

SELECT
    'expected_loss_amount',
    COUNT(*),
    ROUND(MIN(expected_loss_amount)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY expected_loss_amount))::numeric, 2),
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY expected_loss_amount))::numeric, 2),
    ROUND(AVG(expected_loss_amount)::numeric, 2),
    ROUND((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY expected_loss_amount))::numeric, 2),
    ROUND(MAX(expected_loss_amount)::numeric, 2),
    ROUND(STDDEV_POP(expected_loss_amount)::numeric, 2)
FROM credit_decisioning_sim.synthetic_applications
ORDER BY variable_name;

-- 9.5 Score band profile summary
-- Purpose:
--   Review whether the portfolio behaves directionally as expected across score bands.
--
-- Why this matters:
--   This query supports one of the central V1 validation conclusions:
--   stronger score bands should generally look stronger across multiple
--   dimensions, but overlap should still remain visible.
--
-- Plain-English variable expectations:
--   avg_credit_score
--     = average borrower score in the band.
--       This should obviously step down as the bands weaken.
--
--   avg_income / median_income
--     = average / midpoint borrower income.
--       Stronger score bands should usually earn more on average.
--
--   avg_dti
--     = average share of income already committed to debt.
--       Stronger score bands should usually carry lower debt burden.
--
--   avg_utilization
--     = average share of revolving credit currently being used.
--       Stronger score bands should usually use less of their available credit.
--
--   avg_tradeline_count
--     = average number of credit accounts on file.
--       Stronger score bands should usually have thicker, more established files.
--
--   avg_file_age_months
--     = average age of the oldest trade.
--       Stronger score bands should usually have older, more seasoned credit history.
--
--   avg_recent_inquiries
--     = average number of recent credit applications / shopping events.
--       Stronger score bands should usually show slightly less credit-seeking activity.
--
--   avg_delinquency_count
--     = average number of recent delinquencies.
--       This should rise materially as score bands weaken.
--
--   major_derog_rate
--     = share of borrowers with a serious derogatory credit event.
--       This should be very low in strong bands and much higher in weak bands.
--
--   bankruptcy_rate
--     = share of borrowers with bankruptcy flag.
--       This should be rare overall and concentrated in weaker bands.
--
--   avg_pti
--     = average payment-to-income ratio (new monthly payment burden).
--       Stronger score bands should generally have lower affordability stress.
--
--   avg_amount_to_income
--     = average exposure size relative to income.
--       This should remain plausible and not explode in weaker segments.
--
--   avg_pd / avg_expected_loss
--     = average estimated-PD proxy value / expected loss.
--       These should worsen clearly as score quality weakens.
--       The avg_pd alias is retained for compact QA output naming
--
-- What to look for:
--   - stronger score bands should generally have:
--       higher income
--       lower DTI
--       lower utilization
--       fewer delinquencies
--       lower major derog rates
--       lower bankruptcy rates
--       lower PTI
--       lower estimated-PD proxy
--       lower expected loss
--
--   - weaker score bands should generally show the opposite pattern
--
-- Example of a healthy story:
--   If PRIME has lower utilization, fewer delinquencies, lower PTI, and lower
--   estimated-PD proxy than SUBPRIME, that is a sign the engine is behaving correctly.
--
-- Example of a red flag:
--   If DEEP_SUBPRIME shows better affordability and lower risk than PRIME, the
--   segment logic is probably broken or a calibration change had unintended effects.
--
-- Important nuance:
--   Do not expect every single metric to improve perfectly and mechanically in
--   every query revision. Some overlap is healthy. The goal is realistic average
--   directional movement, not robotic monotonicity.
--
-- V2-specific check:
--   - weaker score bands should still show higher estimated-PD proxy than stronger bands
--   - but estimated-PD proxy should no longer collapse to identical values in the weakest bands
--   - deep subprime should still be riskiest, but with more dispersion

SELECT
    score_band,
    COUNT(*) AS applications,
    ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct_of_total,
    ROUND(AVG(credit_score)::numeric, 2) AS avg_credit_score,
    ROUND(AVG(annual_income)::numeric, 2) AS avg_income,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY annual_income))::numeric, 2) AS median_income,
    ROUND(AVG(debt_to_income_ratio)::numeric, 4) AS avg_dti,
    ROUND(AVG(utilization_rate)::numeric, 4) AS avg_utilization,
    ROUND(AVG(tradeline_count)::numeric, 2) AS avg_tradeline_count,
    ROUND(AVG(months_since_oldest_trade)::numeric, 2) AS avg_file_age_months,
    ROUND(AVG(recent_inquiry_count)::numeric, 2) AS avg_recent_inquiries,
    ROUND(AVG(delinquency_count_12m)::numeric, 2) AS avg_delinquency_count,
    ROUND(AVG(CASE WHEN major_derogatory_flag THEN 1 ELSE 0 END)::numeric, 4) AS major_derog_rate,
    ROUND(AVG(CASE WHEN bankruptcy_flag THEN 1 ELSE 0 END)::numeric, 4) AS bankruptcy_rate,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(amount_to_income_ratio)::numeric, 4) AS avg_amount_to_income,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications
GROUP BY score_band
ORDER BY
    CASE score_band
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        ELSE 5
    END;

-- 9.6 Product profile summary
-- Purpose:
--   Review whether product structure is materially influencing exposure,
--   pricing, affordability, and loss as intended.
--
-- Why this matters:
--   This query supports another core V1 conclusion: the engine is product-aware,
--   not a generic lending simulation with cosmetic product labels.
--
-- Plain-English variable expectations by product:
--   avg_requested_amount / median_requested_amount
--     = average / midpoint exposure size.
--       Mortgage and HELOC should generally be much larger than revolving or
--       unsecured personal loan.
--
--   avg_apr / median_apr
--     = average / midpoint pricing burden.
--       Revolving should generally price highest. Mortgage and HELOC should
--       usually price lower.
--
--   avg_monthly_payment / median_monthly_payment
--     = average / midpoint monthly burden.
--       Mortgage may have larger balances but amortization structure moderates
--       payment differently than revolving or unsecured products.
--
--   avg_pti
--     = average affordability burden from the modeled monthly payment.
--       This is one of the most important product realism checks.
--
--   avg_pd / avg_lgd / avg_expected_loss
--     = average credit risk, loss severity, and expected loss.
--       These should differ meaningfully by product because product structure,
--       pricing, and LGD are intentionally different.
--
-- What to look for:
--   - Mortgage and HELOC should generally show larger balances
--   - Revolving should generally show higher APRs
--   - Auto and Mortgage payment behavior should differ due to term structure
--   - PTI, estimated-PD proxy, LGD, and Expected Loss should vary sensibly by product
--   - the post-calibration mortgage profile should no longer dominate the
--     portfolio unrealistically
--
-- Example of a healthy story:
--   Mortgage might have large requested amounts but moderate average PTI after
--   calibration, while revolving has much smaller balances but higher APRs and
--   different expected loss behavior.
--
-- Example of a red flag:
--   If mortgage still has extreme PTI or requested amounts that dwarf income
--   capacity across the portfolio, that would signal regression versus the V1
--   mortgage calibration conclusion.
--
-- V2 mortgage refinement check:
--   - mortgage average PTI should remain moderate after A2 + A3
--   - extreme PTI outliers should be reduced
--   - large mortgage balances should still exist for strong borrowers
--   - mortgage should not dominate portfolio risk unrealistically

SELECT
    product_type,
    COUNT(*) AS applications,
    ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct_of_total,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY requested_amount))::numeric, 2) AS median_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY base_apr_for_payment_calc))::numeric, 4) AS median_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY monthly_payment_proxy))::numeric, 2) AS median_monthly_payment,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND((PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY payment_to_income_ratio))::numeric, 4) AS median_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(estimated_lgd)::numeric, 4) AS avg_lgd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss,
    ROUND(SUM(expected_loss_amount)::numeric, 2) AS total_expected_loss
FROM credit_decisioning_sim.synthetic_applications
GROUP BY product_type
ORDER BY product_type;

-- 9.7 PTI bucket summary
-- Purpose:
--   Confirm that worsening affordability is associated with worsening risk.
--
-- Why this matters:
--   This query directly supports one of the key validation conclusions documented
--   in the header: PTI behaves as the intended affordability bridge into estimated-PD proxy.
--
-- Plain-English bucket interpretation:
--   PTI < 5%
--     = very light monthly burden relative to income
--
--   5%-9%
--     = manageable burden
--
--   10%-14%
--     = noticeable but still moderate burden
--
--   15%-19%
--     = heavier burden
--
--   20%+
--     = meaningfully stressed affordability
--
-- What to look for:
--   - average estimated-PD proxy should generally rise as PTI worsens
--   - expected loss should generally rise as PTI worsens
--   - some noise is acceptable because exposure size and product still matter
--   - the pattern should be broadly monotonic even if not mathematically perfect
--
-- Example of a healthy story:
--   If the '<5%' bucket has the lowest average estimated-PD proxy and the '20%+' bucket has the
--   highest, the affordability bridge is working.
--
-- Example of a red flag:
--   If high-PTI buckets show lower risk than low-PTI buckets, something in the
--   exposure / payment / affordability chain may be broken.
--
-- V2-specific check:
--   - A3 should slightly reduce the highest-PTI bucket averages
--   - the relative ordering of estimated-PD proxy across PTI buckets must remain intact
--   - high PTI should still correspond to higher risk

SELECT
    CASE
        WHEN payment_to_income_ratio < 0.05 THEN '<5%'
        WHEN payment_to_income_ratio < 0.10 THEN '5%-9%'
        WHEN payment_to_income_ratio < 0.15 THEN '10%-14%'
        WHEN payment_to_income_ratio < 0.20 THEN '15%-19%'
        ELSE '20%+'
    END AS pti_bucket,
    COUNT(*) AS applications,
    ROUND((100.0 * COUNT(*) / SUM(COUNT(*)) OVER ())::numeric, 2) AS pct_of_total,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications
GROUP BY 1
ORDER BY 1;

-- 9.8 Product x Score band matrix
-- Purpose:
--   Review the portfolio at the intersection of product structure and score quality.
--
-- Why this matters:
--   This is one of the most important realism checks in the script because it
--   reveals whether products remain meaningfully differentiated inside each
--   score segment.
--
-- It also helped surface two key validation insights:
--   - the earlier mortgage calibration issue
--   - the remaining weak-end estimated-PD proxy cap crowding that is documented as a V2 target
--
-- How to read this matrix:
--   Each row is one product inside one score band.
--
--   That means you are not just asking:
--     "Are mortgages different from auto loans?"
--
--   You are asking:
--     "Are prime mortgages different from prime auto loans?"
--     "Are subprime mortgages still plausible after calibration?"
--     "Do weaker revolving borrowers look riskier than stronger revolving borrowers?"
--
-- Plain-English variable expectations:
--   applications
--     = how many records landed in the cell
--       There should be enough rows to feel plausible; extremely tiny cells may
--       be hard to interpret.
--
--   avg_requested_amount
--     = average exposure size in that product / score combination
--
--   avg_apr
--     = average pricing level
--
--   avg_monthly_payment
--     = average modeled monthly burden
--
--   avg_pti
--     = average payment burden relative to income
--
--   avg_pd
--     = average estimated-PD proxy value
--
--   avg_expected_loss
--     = average modeled expected loss
--
-- What to look for:
--   - sensible counts in each cell
--   - products remain differentiated within the same score band
--   - PTI and estimated-PD proxy vary in ways that match both score quality and structure
--   - weaker mortgage cells no longer show implausible affordability
--   - extreme-risk cells should no longer collapse to identical estimated-PD proxy values
--   - some cells may still reach the cap, but not all weak-end rows should cluster there
--
-- V2-specific interpretation:
--   - compare weak product × weak score combinations
--   - look for dispersion below 0.45 rather than flat clustering
--
-- Example of a healthy story:
--   Super-prime mortgage should usually look lower-risk and more affordable than
--   deep-subprime mortgage, even if both have large balances.
--
-- Another healthy story:
--   Within the same score band, revolving should usually still look different
--   from mortgage because the product structure is different.
--
-- Example of a red flag:
--   If all weak-end cells show nearly identical estimated-PD proxy regardless of product or
--   affordability, that may indicate too much estimated-PD proxy cap crowding.

SELECT
    product_type,
    score_band,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications
GROUP BY product_type, score_band
ORDER BY
    product_type,
    CASE score_band
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        ELSE 5
    END;

-- 9.9 Mixed-signal spot checks
-- Purpose:
--   Deliberately inspect records that prove the engine allows realistic overlap,
--   rather than generating unrealistically rigid synthetic profiles.
--
-- Why this matters:
--   One of the explicit V1 validation conclusions was that the engine preserves
--   overlap between strong and weak profiles. These spot checks help prove that.
--
-- Teaching note:
--   Summary statistics are powerful, but they can hide weird or unrealistic
--   record-level combinations. These spot checks act as a "sanity lens" on the
--   tails and exceptions.

-- Strong credit but high PTI
-- Why this query exists:
--   Strong borrowers should not all have low PTI. This query verifies that
--   controlled exceptions remain possible.
--
-- What to expect:
--   These rows should exist, but they should not dominate the portfolio.
SELECT *
FROM credit_decisioning_sim.synthetic_applications
WHERE credit_score >= 700
  AND payment_to_income_ratio >= 0.18
ORDER BY payment_to_income_ratio DESC
LIMIT 25;

-- Weaker credit but manageable PTI
-- Why this query exists:
--   Weaker borrowers should not all be uniformly overburdened. This query helps
--   confirm that the portfolio still contains realistic overlap.
--
-- What to expect:
--   These rows should exist, but they should still generally look weaker than
--   strong-band rows on other metrics.
SELECT *
FROM credit_decisioning_sim.synthetic_applications
WHERE credit_score < 640
  AND payment_to_income_ratio < 0.10
ORDER BY credit_score DESC, payment_to_income_ratio ASC
LIMIT 25;

-- Large exposure but manageable affordability
-- Why this query exists:
--   This is the key mortgage calibration spot check. It was especially useful
--   during the review cycle to confirm that large exposure can exist without
--   automatically implying absurd PTI.
--
-- What to expect:
--   You should still see some large-balance rows here, especially for stronger
--   mortgage borrowers, but not absurd combinations that overwhelm income.
SELECT *
FROM credit_decisioning_sim.synthetic_applications
WHERE requested_amount >= 250000
  AND payment_to_income_ratio < 0.15
ORDER BY requested_amount DESC
LIMIT 25;

-- 9.10 Distribution sanity by product and score band
-- Purpose:
--   Provide one more quick cross-sectional view for estimated-PD proxy and Expected Loss.
--
-- Why this matters:
--   This is a compact diagnostic query that helps reviewers quickly scan where
--   risk concentration lives across the portfolio.
--
-- What to look for:
--   - higher estimated-PD proxy in weaker score bands
--   - meaningful product differences
--   - possible evidence of estimated-PD proxy cap crowding in the weakest cells
--
-- Example use:
--   This is a good "quick scan" query if you want one table that tells you
--   where modeled risk is concentrating before drilling deeper into 9.8.

SELECT
    product_type,
    score_band,
    COUNT(*) AS applications,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications
GROUP BY product_type, score_band
ORDER BY product_type, score_band;

-- 9.11 Optional quick profile sample
-- Purpose:
--   Provide a small sample of final records for visual inspection.
--
-- Why this matters:
--   Even in a statistically validated portfolio, a quick row-level inspection
--   can still catch odd combinations or formatting issues that summary tables
--   might miss.
--
-- What to use it for:
--   - final "human eyeball" review
--   - debugging unexpected field combinations
--   - confirming output formatting and naming

SELECT *
FROM credit_decisioning_sim.synthetic_applications
ORDER BY application_id
LIMIT 50;

-- 9.12 Estimated-PD proxy saturation diagnostics (V2-specific)
-- Purpose:
--   Quantify how many rows are hitting the estimated-PD proxy cap and how saturation is applied.
--
-- Why this matters:
--   This directly validates the Workstream B objective: reducing cap crowding.
--
-- What to look for:
--   - lower % of rows at exactly the estimated-PD proxy governance cap of 0.45
--     versus the prior baseline
--   - meaningful distribution across saturation zones
--   - most rows should remain in NORMAL zone
--
-- Interpretation:
--   HIGH and EXTREME zones should exist but should not dominate the population.

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE estimated_pd = 0.450000) AS capped_rows,
    ROUND(
        COUNT(*) FILTER (WHERE estimated_pd = 0.450000)::numeric
        / COUNT(*),
        4
    ) AS pct_capped
FROM credit_decisioning_sim.synthetic_applications;

SELECT
    pd_saturation_zone_v2,
    COUNT(*) AS rows,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM credit_decisioning_sim.synthetic_applications
GROUP BY pd_saturation_zone_v2
ORDER BY pd_saturation_zone_v2;

-- 9.13 Mortgage A3 overlay diagnostics (V2-specific)
-- Purpose:
--   Validate that the A3 PTI-aware dampener is narrowly targeted.
--
-- Why this matters:
--   A3 should only affect the hottest affordability rows, not the entire
--   mortgage population.
--
-- What to look for:
--   - most rows should be NORMAL
--   - HOT / EXTREME_HOT should be small but non-zero
--   - average dampener factor should be close to 1.00

SELECT
    mortgage_pti_dampener_zone_v2,
    COUNT(*) AS rows,
    ROUND(AVG(mortgage_pti_dampener_factor_v2), 6) AS avg_factor
FROM credit_decisioning_sim.synthetic_applications
WHERE product_type = 'MORTGAGE'
GROUP BY mortgage_pti_dampener_zone_v2
ORDER BY mortgage_pti_dampener_zone_v2;

-- 9.14 Mortgage transformation trace (A2 + A3 visibility)
-- Purpose:
--   Show how mortgage amounts evolve through A2 and A3 layers.
--
-- Why this matters:
--   Confirms that each step of the mortgage refinement pipeline is working
--   and producing reasonable intermediate values.

SELECT
    product_type,
    score_band,
    ROUND(AVG(mortgage_candidate_amount_v2), 2) AS avg_candidate,
    ROUND(AVG(mortgage_requested_amount_pre_floor_v2), 2) AS avg_after_a2,
    ROUND(AVG(mortgage_requested_amount_post_pti_dampener_v2), 2) AS avg_after_a3,
    ROUND(AVG(requested_amount), 2) AS avg_final
FROM credit_decisioning_sim.synthetic_applications
WHERE product_type = 'MORTGAGE'
GROUP BY product_type, score_band
ORDER BY
    CASE score_band
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        ELSE 5
    END;

/*
================================================================================
9.15 WORKSTREAM D QA — REVOLVING PAYMENT VS APR RELATIONSHIP
================================================================================
Purpose:
  Validate that the Workstream D enhancement is functioning as intended by
  confirming that revolving monthly payment burden now responds to APR.

Why this matters:
  Prior to Workstream D, revolving payment was modeled as a fixed percentage
  of line amount:

      requested_amount * constant %

  This meant:
      APR ↑ → payment unchanged → PTI unchanged → estimated-PD proxy unchanged

  That broke the intended economic transmission path for rate scenarios.

  Workstream D introduces a blended payment proxy:

      payment =
          requested_amount * base_min_payment_pct
        + requested_amount * (APR / 12) * passthrough_factor

  Therefore, we expect:

      APR ↑ → payment ↑ → PTI ↑ → estimated-PD proxy ↑

  This QA section explicitly confirms that the first link in that chain
  (APR → payment) is behaving correctly.

--------------------------------------------------------------------------------
WHAT THIS CHECK DOES
--------------------------------------------------------------------------------
This query measures the statistical relationship between:
  - base_apr_for_payment_calc (independent variable)
  - monthly_payment_proxy     (dependent variable)

For revolving products only.

It computes:
  - correlation between APR and payment
  - average APR
  - average payment
  - observation count

--------------------------------------------------------------------------------
INTERPRETATION GUIDANCE
--------------------------------------------------------------------------------
Correlation (APR vs Payment):

  Expected result:
    Positive correlation (typically moderate strength)

  Why not near 1.0?
    Payment is driven by BOTH:
      - base minimum-payment percentage
      - APR-sensitive component

    So APR should influence payment, but not fully determine it.

  Healthy range (guideline, not strict rule):
    ~0.20 to ~0.70 depending on parameter settings

  If correlation is near 0:
    Workstream D is not functioning (APR is not flowing into payment)

  If correlation is near 1:
    APR is dominating the payment proxy too heavily
    → revisit passthrough factor

--------------------------------------------------------------------------------
IMPORTANT CONTEXT
--------------------------------------------------------------------------------
This is NOT a causality test—it is a sanity check.

Because:
  - requested_amount also drives payment
  - product mix and score mix influence APR distribution

This check simply confirms that:
  APR variation contributes meaningfully to payment variation.

--------------------------------------------------------------------------------
BEST PRACTICE
--------------------------------------------------------------------------------
Run this check:
  - after implementing Workstream D
  - after tuning revolving parameters
  - after major scenario changes (e.g., rate stress)

Look for:
  - stable positive correlation
  - consistent behavior across scenarios

--------------------------------------------------------------------------------
*/

SELECT
    scenario_name,
    population_id,
    COUNT(*) AS revolving_rows,

    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_payment,

    ROUND(
        CORR(base_apr_for_payment_calc, monthly_payment_proxy)::numeric
    ,4) AS apr_payment_correlation

FROM credit_decisioning_sim.synthetic_applications
WHERE product_type = 'REVOLVING_LINE'
GROUP BY
    scenario_name,
    population_id
ORDER BY
    scenario_name;

/*
--------------------------------------------------------------------------------
9.16 REVOLVING PAYMENT BY APR BUCKET
--------------------------------------------------------------------------------
Purpose:
  Provide a directional check showing how average payment changes across
  increasing APR buckets.

Interpretation:
  Payment should generally increase as APR buckets increase, although the pattern
  may not be perfectly monotonic because requested_amount also influences payment.

  This is often easier to interpret than correlation alone and is useful for:
    - presentations
    - executive review
    - debugging parameter behavior
*/

SELECT
    scenario_name,
    population_id,

    CASE
        WHEN base_apr_for_payment_calc < 0.10 THEN '<10%'
        WHEN base_apr_for_payment_calc < 0.15 THEN '10-15%'
        WHEN base_apr_for_payment_calc < 0.20 THEN '15-20%'
        WHEN base_apr_for_payment_calc < 0.25 THEN '20-25%'
        ELSE '25%+'
    END AS apr_bucket,

    COUNT(*) AS rows_in_bucket,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_payment

FROM credit_decisioning_sim.synthetic_applications
WHERE product_type = 'REVOLVING_LINE'
GROUP BY
    scenario_name,
    population_id,
    apr_bucket
ORDER BY
    scenario_name,
    apr_bucket;

/*
================================================================================
9.17 PTI TAIL FREQUENCY CHECK
================================================================================
Purpose:
  Quantify how much of the portfolio falls into high-PTI affordability-stress
  territory.

Why this matters:
  Earlier QA sections profile PTI using percentiles, averages, and maximum values.
  Those statistics are important, but they do not directly answer one critical
  validation question:

      "How common are high-affordability-burden rows?"

  This query provides that missing frequency view.

  It is especially useful for comparing:
    - V1.0 baseline behavior
    - V2.0 final behavior after Workstream A mortgage refinement

  The goal of Workstream A was not to eliminate high-PTI rows entirely. Real
  portfolios contain stretched borrowers and affordability edge cases.

  The goal was to ensure that high-PTI rows are:
    - present but not dominant
    - explainable by product / structure / income interactions
    - not artificially inflated by unrealistic mortgage exposure scaling

Teaching note:
  A high maximum PTI does not necessarily mean the portfolio is broken.
  A small number of high-PTI rows can be realistic.

  What matters is whether the high-PTI tail is controlled in frequency and
  supported by plausible row-level logic.

How to use this query:
  Run this query against:
    1. the V1.0 baseline output
    2. the final V2.0 output

  Then compare:
    - pct_pti_gt_40
    - pct_pti_gt_50
    - pct_pti_gt_75

  These metrics can be cited in the Validation Summary to support statements
  such as:
    "High-PTI observations remain present but non-dominant."

Interpretation guidance:
  pct_pti_gt_40:
    broad high-affordability-stress indicator

  pct_pti_gt_50:
    severe affordability-stress indicator

  pct_pti_gt_75:
    extreme tail indicator; should be rare

What success looks like:
  - high-PTI rows exist
  - severe / extreme PTI rows do not dominate the portfolio
  - V2.0 should show improved or controlled tail behavior versus V1.0
  - the tail should be consistent with the mortgage and payment refinements
    validated elsewhere in Section 9

Important nuance:
  This query does not determine whether every high-PTI row is realistic.
  It measures tail frequency.

  Row-level plausibility should still be reviewed using the mixed-signal spot
  checks in Section 9.9.
*/

SELECT
    COUNT(*) AS total_applications,

    COUNT(*) FILTER (
        WHERE payment_to_income_ratio > 0.40
    ) AS rows_pti_gt_40,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE payment_to_income_ratio > 0.40
        ) / COUNT(*),
        2
    ) AS pct_pti_gt_40,

    COUNT(*) FILTER (
        WHERE payment_to_income_ratio > 0.50
    ) AS rows_pti_gt_50,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE payment_to_income_ratio > 0.50
        ) / COUNT(*),
        2
    ) AS pct_pti_gt_50,

    COUNT(*) FILTER (
        WHERE payment_to_income_ratio > 0.75
    ) AS rows_pti_gt_75,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE payment_to_income_ratio > 0.75
        ) / COUNT(*),
        2
    ) AS pct_pti_gt_75,

    ROUND(MAX(payment_to_income_ratio)::numeric, 4) AS max_pti

FROM credit_decisioning_sim.synthetic_applications;

/*
================================================================================
SECTION 10. SCENARIO COMPARISON QA
================================================================================
Purpose:
  Compare archived Module 1 scenarios within a selected scenario_set_name.

Why this section matters:
  Module 1 is not only a synthetic portfolio generator. With deterministic
  population_id and archived outputs, it becomes a controlled scenario comparison
  engine.

  Section 9 answered:
      "Is this single scenario internally consistent and realistic?"

  Section 10 answers:
      "How do two or more scenarios differ, and where are those differences coming from?"

Important boundary:
  This section does NOT make approval, decline, pricing, or manual review
  decisions. Those belong in later modules.

  Section 10 is strictly diagnostic and comparative.

  It answers:
      What changed between scenarios?
      Where did those changes occur (product, score, affordability)?
      How large are those changes at portfolio and segment levels?

  Later modules will answer:
      What decision should we make because of those changes?

--------------------------------------------------------------------------------
HOW TO USE THIS SECTION
--------------------------------------------------------------------------------
1. Run a baseline scenario with:
       archive_run_flag = TRUE

2. Modify one or more parameters:
       - rate_shift_bps
       - product mix
       - score mix
       - affordability assumptions
       - etc.

3. Change scenario_name to reflect the new assumption set.

4. Keep population_id CONSTANT.
   This is critical for apples-to-apples comparison.

5. Rerun and archive the new scenario.

6. Use the queries below to compare results.

7. Naming note:
    Scenario comparison aliases such as avg_pd, baseline_pd, comparison_pd,
    delta_pd, and rows_pd_increased are retained for compact QA output naming.
    They refer to movement in the synthetic estimated-PD proxy, not calibrated
    production default probabilities.

--------------------------------------------------------------------------------
KEY ANALYTICAL PRINCIPLE
--------------------------------------------------------------------------------
Holding population_id constant ensures that:

  - The same synthetic borrowers appear in every scenario
  - Differences in results are caused by parameter changes
  - NOT by differences in the underlying population

This allows:
  - clean attribution of change
  - true scenario comparison rather than distribution comparison

--------------------------------------------------------------------------------
HOW TO INTERPRET RESULTS
--------------------------------------------------------------------------------
Read Section 10 outputs in layers:

  Layer 1 (10.2):
    Portfolio-level movement
    → "Did risk go up or down overall?"

  Layer 2 (10.3):
    Segment-level movement
    → "Where did the change happen?"

  Layer 3 (10.4):
    Row-level matched comparison
    → "Which borrowers changed and why?"

--------------------------------------------------------------------------------
COMMON PITFALLS TO AVOID
--------------------------------------------------------------------------------
1. Changing population_id between scenarios:
     This invalidates comparisons.

2. Using archive_reset_mode = ALL unintentionally:
     This deletes prior scenarios needed for comparison.

3. Comparing scenarios across different scenario_set_name values:
     These are intended to represent separate analysis families.

4. Interpreting small differences as signal:
     Always look for consistent directional movement across segments.

--------------------------------------------------------------------------------
*/


-- =============================================================================
-- 10.1 SCENARIO ARCHIVE INVENTORY
-- =============================================================================
-- Purpose:
--   Show which scenario sets, scenarios, and populations are available.
--
-- Why this matters:
--   Before comparing anything, confirm:
--     - which scenarios exist
--     - which population_id they use
--     - whether they are directly comparable
--
-- Interpretation guidance:
--   - rows_archived should match application_count for each scenario
--   - multiple scenario_name values under the same scenario_set_name
--     represent a valid comparison group
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS rows_archived,
    MIN(scenario_archived_ts) AS first_archived_ts,
    MAX(scenario_archived_ts) AS last_archived_ts
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;


-- =============================================================================
-- 10.2 PORTFOLIO-LEVEL SCENARIO SUMMARY
-- =============================================================================
-- Purpose:
--   Compare major portfolio metrics across scenarios.
--
-- What this shows:
--   First-order impact of parameter changes.
--
-- Key metrics:
--   avg_requested_amount → exposure level
--   avg_apr              → pricing / rate environment
--   avg_pti              → affordability pressure
--   avg_pd               → estimated-PD proxy level
--   avg_expected_loss    → financial impact
--
-- Interpretation guidance:
--   - If avg_pti increases, expect avg_pd to increase directionally,
--      where avg_pd represents the estimated-PD proxy
--   - If avg_apr increases, payment burden should increase
--   - Expected loss should reflect exposure, estimated-PD proxy, and LGD effects
--
-- Example read:
--   "Scenario B increased avg estimated-PD proxy by +180 bps, driven by a +3.5% increase
--    in PTI and slightly higher APR."
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(base_apr_for_payment_calc)::numeric, 4) AS avg_apr,
    ROUND(AVG(monthly_payment_proxy)::numeric, 2) AS avg_monthly_payment,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(estimated_lgd)::numeric, 4) AS avg_lgd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss,
    ROUND(SUM(expected_loss_amount)::numeric, 2) AS total_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id
ORDER BY
    scenario_set_name,
    population_id,
    scenario_name;


-- =============================================================================
-- 10.3 PRODUCT × SCORE SCENARIO SUMMARY
-- =============================================================================
-- Purpose:
--   Identify where scenario differences concentrate across segments.
--
-- Why this matters:
--   Portfolio averages can hide where risk is actually moving.
--
-- This query answers:
--   - Which product segments changed the most?
--   - Which score bands are driving estimated-risk changes?
--   - Are changes broad-based or concentrated?
--
-- Interpretation guidance:
--   Look for:
--     - consistent increases across all segments → macro effect
--     - isolated spikes (e.g., Subprime Revolving) → targeted sensitivity
--     - divergence between products → structural differences
--
-- Example read:
--   "Most of the estimated-PD proxy increase came from Subprime Revolving and
--    Near Prime Personal Loans, suggesting the rate shift is
--    disproportionately affecting unsecured exposure."
SELECT
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band,
    COUNT(*) AS applications,
    ROUND(AVG(requested_amount)::numeric, 2) AS avg_requested_amount,
    ROUND(AVG(payment_to_income_ratio)::numeric, 4) AS avg_pti,
    ROUND(AVG(estimated_pd)::numeric, 4) AS avg_pd,
    ROUND(AVG(expected_loss_amount)::numeric, 2) AS avg_expected_loss
FROM credit_decisioning_sim.synthetic_applications_scenario_archive
GROUP BY
    scenario_set_name,
    scenario_name,
    population_id,
    product_type,
    score_band
ORDER BY
    scenario_set_name,
    population_id,
    product_type,
    score_band,
    scenario_name;

-- =============================================================================
-- 10.4 MATCHED ROW-LEVEL SCENARIO COMPARISON
-- =============================================================================
-- Purpose:
--   Compare two archived scenarios borrower-by-borrower using the same
--   population_id and application_id.
--
-- Why this matters:
--   Portfolio-level and segment-level summaries show what changed in aggregate.
--   A matched row-level comparison shows how the same synthetic borrowers moved
--   between scenarios.
--
-- Key analytical principle:
--   Because population_id is deterministic, each application_id represents the
--   same synthetic borrower across scenarios when population_id is held constant.
--
-- This allows true apples-to-apples comparison:
--   baseline borrower A  →  comparison borrower A
--   baseline borrower B  →  comparison borrower B
--   baseline borrower C  →  comparison borrower C
--
-- What this query helps answer:
--   - Which individual rows experienced the largest estimated-PD proxy increase?
--   - Which rows experienced the largest expected loss increase?
--   - Did payment burden increase for the same borrowers?
--   - Are changes concentrated in specific products or score bands?
--
-- Important boundary:
--   This is still diagnostic analysis. It does not approve, decline, reprice,
--   or assign treatments. Those decision layers belong in later modules.
--
-- How to use:
--   Update the values in tmp_module1_compare_scenarios below to identify:
--     - the scenario_set_name to compare within
--     - the shared population_id
--     - the baseline scenario
--     - the comparison scenario
--
-- Example:
--   baseline_scenario_name   = BASELINE_V2
--   comparison_scenario_name = RATE_UP_200BP
--
-- Interpretation guidance:
--   Positive deltas mean the comparison scenario increased the metric.
--   Negative deltas mean the comparison scenario reduced the metric.
--
--   For example:
--     delta_pti = +0.0250
--       means the borrower’s payment-to-income burden increased by 2.5
--       percentage points in the comparison scenario.
--
--     delta_pd = +0.0180
--       means the estimated-PD proxy increased by 1.8 percentage points.
--
--     delta_expected_loss = +500.00
--       means expected loss increased by $500 for that matched borrower.

DROP TABLE IF EXISTS tmp_module1_compare_scenarios;

CREATE TEMP TABLE tmp_module1_compare_scenarios AS
SELECT
    'MODULE1_V2_BASELINE_SET'::TEXT AS scenario_set_name,
    'BASE_POPULATION_V1'::TEXT      AS population_id,
    'BASELINE_V2'::TEXT             AS baseline_scenario_name,
    'RATE_UP_200BP'::TEXT           AS comparison_scenario_name;


-- 10.4A Matched row-level delta sample
-- Purpose:
--   Show the largest borrower-level expected loss increases between the baseline
--   and comparison scenarios.
--
-- Why order by delta_expected_loss descending?
--   Expected loss combines:
--     exposure × estimated-PD proxy × LGD
--
--   Sorting by expected loss change highlights the rows with the greatest
--   financial movement, not just the greatest risk-rate movement.
--
-- What to look for:
--   - Are the largest increases concentrated in high-PTI borrowers?
--   - Are they concentrated in weaker score bands?
--   - Are certain products more sensitive than others?
--   - Do estimated-PD proxy and PTI move together in a sensible direction?

SELECT
    b.scenario_set_name,
    b.population_id,
    b.application_id,
    b.applicant_id,

    b.product_type,
    b.score_band,

    b.requested_amount AS baseline_requested_amount,
    c.requested_amount AS comparison_requested_amount,
    ROUND((c.requested_amount - b.requested_amount)::numeric, 2) AS delta_requested_amount,

    b.base_apr_for_payment_calc AS baseline_apr,
    c.base_apr_for_payment_calc AS comparison_apr,
    ROUND((c.base_apr_for_payment_calc - b.base_apr_for_payment_calc)::numeric, 4) AS delta_apr,

    b.monthly_payment_proxy AS baseline_monthly_payment,
    c.monthly_payment_proxy AS comparison_monthly_payment,
    ROUND((c.monthly_payment_proxy - b.monthly_payment_proxy)::numeric, 2) AS delta_monthly_payment,

    b.payment_to_income_ratio AS baseline_pti,
    c.payment_to_income_ratio AS comparison_pti,
    ROUND((c.payment_to_income_ratio - b.payment_to_income_ratio)::numeric, 4) AS delta_pti,

    b.estimated_pd AS baseline_pd,
    c.estimated_pd AS comparison_pd,
    ROUND((c.estimated_pd - b.estimated_pd)::numeric, 4) AS delta_pd,

    b.expected_loss_amount AS baseline_expected_loss,
    c.expected_loss_amount AS comparison_expected_loss,
    ROUND((c.expected_loss_amount - b.expected_loss_amount)::numeric, 2) AS delta_expected_loss

FROM credit_decisioning_sim.synthetic_applications_scenario_archive b
JOIN credit_decisioning_sim.synthetic_applications_scenario_archive c
  ON  b.scenario_set_name = c.scenario_set_name
  AND b.population_id = c.population_id
  AND b.application_id = c.application_id
CROSS JOIN tmp_module1_compare_scenarios p
WHERE b.scenario_set_name = p.scenario_set_name
  AND b.population_id = p.population_id
  AND b.scenario_name = p.baseline_scenario_name
  AND c.scenario_name = p.comparison_scenario_name
ORDER BY
    delta_expected_loss DESC
LIMIT 50;


-- 10.4B Matched row-level delta summary
-- Purpose:
--   Summarize borrower-level movements between the baseline and comparison
--   scenarios.
--
-- Why this matters:
--   The sample query above shows individual high-impact rows. This query
--   summarizes the full matched population.
--
-- What this tells reviewers:
--   - how many borrowers were matched
--   - average metric movement
--   - how many rows increased or decreased in estimated-PD proxy
--   - how many rows increased or decreased in expected loss
--
-- Interpretation guidance:
--   matched_rows should equal application_count when:
--     - both scenarios used the same population_id
--     - both scenarios were fully archived
--     - no scenario rows were accidentally cleared

WITH matched_rows AS (
    SELECT
        b.application_id,
        b.product_type,
        b.score_band,

        c.requested_amount - b.requested_amount AS delta_requested_amount,
        c.base_apr_for_payment_calc - b.base_apr_for_payment_calc AS delta_apr,
        c.monthly_payment_proxy - b.monthly_payment_proxy AS delta_monthly_payment,
        c.payment_to_income_ratio - b.payment_to_income_ratio AS delta_pti,
        c.estimated_pd - b.estimated_pd AS delta_pd,
        c.expected_loss_amount - b.expected_loss_amount AS delta_expected_loss

    FROM credit_decisioning_sim.synthetic_applications_scenario_archive b
    JOIN credit_decisioning_sim.synthetic_applications_scenario_archive c
      ON  b.scenario_set_name = c.scenario_set_name
      AND b.population_id = c.population_id
      AND b.application_id = c.application_id
    CROSS JOIN tmp_module1_compare_scenarios p
    WHERE b.scenario_set_name = p.scenario_set_name
      AND b.population_id = p.population_id
      AND b.scenario_name = p.baseline_scenario_name
      AND c.scenario_name = p.comparison_scenario_name
)

SELECT
    COUNT(*) AS matched_rows,

    ROUND(AVG(delta_requested_amount)::numeric, 2) AS avg_delta_requested_amount,
    ROUND(AVG(delta_apr)::numeric, 4) AS avg_delta_apr,
    ROUND(AVG(delta_monthly_payment)::numeric, 2) AS avg_delta_monthly_payment,
    ROUND(AVG(delta_pti)::numeric, 4) AS avg_delta_pti,
    ROUND(AVG(delta_pd)::numeric, 4) AS avg_delta_pd,
    ROUND(AVG(delta_expected_loss)::numeric, 2) AS avg_delta_expected_loss,

    COUNT(*) FILTER (WHERE delta_pd > 0) AS rows_pd_increased,
    COUNT(*) FILTER (WHERE delta_pd < 0) AS rows_pd_decreased,
    COUNT(*) FILTER (WHERE delta_pd = 0) AS rows_pd_unchanged,

    COUNT(*) FILTER (WHERE delta_expected_loss > 0) AS rows_el_increased,
    COUNT(*) FILTER (WHERE delta_expected_loss < 0) AS rows_el_decreased,
    COUNT(*) FILTER (WHERE delta_expected_loss = 0) AS rows_el_unchanged

FROM matched_rows;


-- 10.4C Matched row-level delta summary by product and score band
-- Purpose:
--   Aggregate matched borrower changes by product and score segment.
--
-- Why this matters:
--   This bridges row-level comparison and executive segment reporting.
--
-- This query answers:
--   - Which product × score cells drove the change?
--   - Did weaker score bands experience larger estimated-PD proxy movement?
--   - Did secured and unsecured products react differently?
--
-- Interpretation guidance:
--   This is often the most useful comparison view for strategy discussion.
--   It shows not only that the scenario changed outcomes, but where the change
--   was concentrated.

WITH matched_rows AS (
    SELECT
        b.application_id,
        b.product_type,
        b.score_band,

        c.requested_amount - b.requested_amount AS delta_requested_amount,
        c.base_apr_for_payment_calc - b.base_apr_for_payment_calc AS delta_apr,
        c.monthly_payment_proxy - b.monthly_payment_proxy AS delta_monthly_payment,
        c.payment_to_income_ratio - b.payment_to_income_ratio AS delta_pti,
        c.estimated_pd - b.estimated_pd AS delta_pd,
        c.expected_loss_amount - b.expected_loss_amount AS delta_expected_loss

    FROM credit_decisioning_sim.synthetic_applications_scenario_archive b
    JOIN credit_decisioning_sim.synthetic_applications_scenario_archive c
      ON  b.scenario_set_name = c.scenario_set_name
      AND b.population_id = c.population_id
      AND b.application_id = c.application_id
    CROSS JOIN tmp_module1_compare_scenarios p
    WHERE b.scenario_set_name = p.scenario_set_name
      AND b.population_id = p.population_id
      AND b.scenario_name = p.baseline_scenario_name
      AND c.scenario_name = p.comparison_scenario_name
)

SELECT
    product_type,
    score_band,
    COUNT(*) AS matched_rows,

    ROUND(AVG(delta_requested_amount)::numeric, 2) AS avg_delta_requested_amount,
    ROUND(AVG(delta_apr)::numeric, 4) AS avg_delta_apr,
    ROUND(AVG(delta_monthly_payment)::numeric, 2) AS avg_delta_monthly_payment,
    ROUND(AVG(delta_pti)::numeric, 4) AS avg_delta_pti,
    ROUND(AVG(delta_pd)::numeric, 4) AS avg_delta_pd,
    ROUND(AVG(delta_expected_loss)::numeric, 2) AS avg_delta_expected_loss,

    ROUND(SUM(delta_expected_loss)::numeric, 2) AS total_delta_expected_loss

FROM matched_rows
GROUP BY
    product_type,
    score_band
ORDER BY
    product_type,
    CASE score_band
        WHEN 'SUPER_PRIME' THEN 1
        WHEN 'PRIME' THEN 2
        WHEN 'NEAR_PRIME' THEN 3
        WHEN 'SUBPRIME' THEN 4
        WHEN 'DEEP_SUBPRIME' THEN 5
        ELSE 6
    END;
