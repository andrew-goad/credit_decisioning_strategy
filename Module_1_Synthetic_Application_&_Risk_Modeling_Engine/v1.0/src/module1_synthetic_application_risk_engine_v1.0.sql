/*
================================================================================
ENTERPRISE CREDIT DECISIONING STRATEGY SIMULATOR
MODULE 1: SYNTHETIC APPLICATION & RISK MODELING ENGINE
FILE: module1_synthetic_application_risk_engine.sql
VERSION: 1.0 (BASELINE)
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
    affordability into probability of default (PD) and expected loss (EL)

Core design chain:
  Applications -> Product Structure -> APR -> Payment -> PTI -> PD -> EL

The build logic is intentionally organized into staged sections covering:
  deterministic population generation, segment assignment, borrower feature
  generation, product structuring, and risk modeling.

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
    6. estimate PD, LGD, and Expected Loss
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
   DTI, utilization, delinquencies, tradeline depth, APR, PTI, and PD are
   generated with directional relationships and realistic overlap.

C. EXPLAINABLE OVER OPAQUE
   PD is built from documented base bands and multipliers, not a black-box fit.

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
- PTI is intentionally treated as the primary affordability bridge into PD.
- LGD is intentionally simpler than PD in Module 1.
- Product mix default is designed to resemble a diversified retail bank, but is
  user-adjustable.
- "Revolving Line" is represented using a requested line / limit proxy and a
  minimum-payment assumption rather than an amortizing installment structure.
- Outputs are intended to support controlled scenario comparison, not
  production decisioning without further model governance and validation.

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
   
C. Product-aware requested amount, APR, payment, PTI, PD, LGD, and EL logic

   Validation confirmed that the engine’s product-aware architecture is functioning as intended.
   Each product type (Mortgage, Auto, HELOC, Revolving, Personal Loan) exhibits distinct structural
   behavior across exposure, pricing, and risk metrics. Section 9.6 and 9.8 outputs demonstrate that:
   
    - Mortgage and HELOC produce higher balances and longer-term affordability dynamics
    - Revolving products exhibit higher APRs and lower balances
    - Auto and personal loans occupy intermediate structural positions
    
   Critically, these structural differences propagate correctly through downstream calculations.
   Monthly payment proxy, PTI, PD, LGD, and Expected Loss all vary consistently with both product
   structure and borrower quality, confirming that the model is not simply assigning static risk but
   is instead translating structure into risk in a realistic and explainable way.
   
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

   During initial validation, the mortgage product exhibited materially unrealistic behavior, with
   average requested amounts exceeding ~$800K and average PTI approaching ~0.88. Row-level inspection
   further revealed implausible combinations (e.g., moderate-income borrowers supporting $1M+ exposures),
   indicating that the requested amount logic was insufficiently constrained relative to income.
   
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

   The V1 engine has successfully passed validation as a portfolio-grade synthetic credit
   decisioning environment, demonstrating strong structural integrity, realistic behavior,
   and audit-ready reproducibility. Identified enhancements (see below 5. PLANNED FUTURE
   ENHANCEMENTS) are incremental refinements rather than foundational issues, reinforcing
   that the current version is both fit for demonstration and extensible for future iteration.

------------------------------------------------------------------------------
5. PLANNED FUTURE ENHANCEMENTS (TARGETED FOR V2.0)
------------------------------------------------------------------------------
A. Further refine upper-tail mortgage affordability behavior

   While V1 calibration resolved the primary exposure issue, validation identified that the upper tail of mortgage
   affordability remains somewhat aggressive, particularly for stronger borrower segments. Some edge-case scenarios
   still exhibit elevated PTI levels relative to typical underwriting norms. In V2, we plan to introduce additional
   soft constraints or nonlinear dampening mechanisms to further smooth this tail without artificially truncating
   valid high-capacity borrowers. The goal is to preserve flexibility while improving realism at the extremes.
   
B. Reduce PD cap crowding in weakest product / score combinations

   Validation also revealed that in the weakest segments (particularly deep subprime across multiple products),
   Probability of Default values frequently approach or reach the imposed cap (~0.45). While the cap serves an
   important governance purpose, this clustering reduces differentiation in the high-risk tail. A future enhancement
   will focus on rebalancing multiplier interactions to allow greater dispersion below the cap, ensuring that the
   model retains discriminatory power even in high-risk segments.
   
C. Expand run-comparison documentation and validation commentary

   Finally, while Section 9 provides a robust QA framework, future versions will enhance run-over-run comparison
   capabilities and accompanying documentation. This will include:

    - standardized comparison queries across scenarios
    - clearer attribution of changes to specific parameter adjustments
    - expanded narrative guidance for interpreting differences

   This enhancement will further strengthen the engine’s positioning as a governed decisioning system, supporting
   structured experimentation and stakeholder communication.
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
  These parameters do not all serve the same purpose. They fall into five major
  groups:

  1. RUN IDENTITY / REPRODUCIBILITY
     Controls how the run is labeled and whether the same synthetic population
     is regenerated consistently.

  2. POPULATION SIZE / TIME WINDOW
     Controls how many applications are generated and over what simulated date
     range they are distributed.

  3. MIX ASSUMPTIONS
     Controls portfolio composition by product and score band.

  4. STRUCTURAL LIMITS / BASELINE ECONOMICS
     Controls score bounds, income bounds, utilization bounds, product amount
     ranges, base APR proxies, and LGD assumptions.

  5. MACRO ENVIRONMENT
     Controls broad rate pressure through a configurable basis-point shift.

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
       - PD / EL profile

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
       - PD and Expected Loss

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

H. Hard bounds / core limits
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

I. Product amount bounds
     min/max for personal, auto, revolving, heloc, mortgage

   What they are:
     Product-specific floor and ceiling values for requested amount generation.

   Why they matter:
     These strongly shape requested amount distributions and therefore payment,
     PTI, PD, and Expected Loss.

   When to change them:
     Change these when simulating a different institution type or line-of-
     business focus. For example:
       - higher mortgage caps for jumbo-oriented books
       - lower auto caps for mass-market originations
       - tighter revolving limits for conservative portfolios

   Best practice:
     Change amount bounds before changing downstream risk logic. In many cases,
     unrealistic affordability outcomes originate here.

J. Base APR parameters
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
     influence payment burden directly and therefore influence PTI, PD, and EL.

   When to change them:
     Change these when:
       - simulating a different market environment
       - aligning the portfolio to a different pricing philosophy
       - recalibrating burden realism by product

   Best practice:
     Make modest changes first. Even small APR changes can materially affect
     payment burden, especially for large-balance secured products.

K. LGD parameters
     lgd_mortgage
     lgd_auto
     lgd_personal
     lgd_revolving
     lgd_heloc

   What they are:
     Product-level loss severity assumptions.

   Why they matter:
     LGD affects Expected Loss directly. In Module 1, LGD is intentionally kept
     simpler than PD, but it still materially changes EL outputs.

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
--   INTEGER = counts or whole-number controls
--   DATE    = simulation timing fields
--   NUMERIC = financial amounts, rates, and ratios where decimal precision matters
--
-- Why use a temp table?
-- A temporary table keeps the parameter layer explicit and queryable during the
-- session without creating permanent metadata objects in the target schema.

CREATE TEMP TABLE tmp_module1_params (
    scenario_name               TEXT,          -- business-facing run label, e.g. BASELINE or RATE_STRESS_UP_200BP

    -- population_id:
    -- deterministic identifier for the synthetic population.
    -- Same population_id + same parameters = same borrower population.
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
    'BASELINE',               -- scenario_name:
                              -- business-facing label for the default run

    'BASE_POPULATION_V1',     -- population_id:
                              -- deterministic identity for this borrower population.
                              -- Keep this constant for apples-to-apples scenario comparison.

    50000,                    -- application_count:
                              -- chosen as a balance between runtime and stability.
                              -- ~50k rows is large enough for robust mix / percentile review
                              -- without becoming cumbersome for ordinary portfolio QA.

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
    --   diversified bank portfolio, while still preserving meaningful subprime
    --   and deep-subprime representation for contrast in PD / EL behavior
    0.180000,  -- super-prime
    0.280000,  -- prime
    0.240000,  -- near-prime
    0.180000,  -- subprime
    0.120000,  -- deep-subprime

    0,         -- rate_shift_bps:
               -- baseline environment
               -- examples:
               --   +100 = +1.00%
               --   +200 = +2.00%
               --   -100 = -1.00%

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
    1. the run is large enough to be meaningful
    2. dates are logically ordered
    3. product and score mixes are internally consistent
    4. lower / upper bounds are valid
    5. rate and loss assumptions remain in plausible ranges
    6. the script follows a "fail fast" principle — execution stops immediately
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

    -- These variables store the total product mix weight and total score mix
    -- weight so they can be validated before the simulation runs.
    v_product_mix NUMERIC(12,6);
    v_score_mix   NUMERIC(12,6);
BEGIN
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
       Generate stable MD5 hashes tied to each application_id and population_id
    4. uniforms
       Convert the MD5 outputs into approximately uniform values between 0 and 1

Important concept:
  A hash is not "random" in the usual sense. It is deterministic:
    same input -> same output
    different input -> different output

  That is exactly what this project needs.

SQL teaching note:
  This section uses a CTE pipeline inside:
      CREATE TABLE ... AS
  This pattern allows the script to:
    - build logic step by step
    - make each transformation readable
    - preserve a clean top-to-bottom data engineering flow
*/

CREATE TABLE credit_decisioning_sim.synthetic_applications AS
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
        p.scenario_name,
        p.population_id,
        p.portfolio_start_date,
        p.portfolio_end_date,
        p.anchor_date,

        -- Deterministic hash generation:
        -- For each application row, generate multiple independent MD5 hash values.
        --
        -- Why multiple hashes?
        -- Because downstream variables should not all depend on the same single
        -- pseudo-random draw. For example:
        --   u1 might drive date assignment
        --   u2 might drive product assignment
        --   u3 might drive score-band assignment
        --   etc.
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
        md5(b.application_id || '|' || p.population_id || '|u1')  AS h1,
        md5(b.application_id || '|' || p.population_id || '|u2')  AS h2,
        md5(b.application_id || '|' || p.population_id || '|u3')  AS h3,
        md5(b.application_id || '|' || p.population_id || '|u4')  AS h4,
        md5(b.application_id || '|' || p.population_id || '|u5')  AS h5,
        md5(b.application_id || '|' || p.population_id || '|u6')  AS h6,
        md5(b.application_id || '|' || p.population_id || '|u7')  AS h7,
        md5(b.application_id || '|' || p.population_id || '|u8')  AS h8,
        md5(b.application_id || '|' || p.population_id || '|u9')  AS h9,
        md5(b.application_id || '|' || p.population_id || '|u10') AS h10,
        md5(b.application_id || '|' || p.population_id || '|u11') AS h11,
        md5(b.application_id || '|' || p.population_id || '|u12') AS h12,
        md5(b.application_id || '|' || p.population_id || '|u13') AS h13,
        md5(b.application_id || '|' || p.population_id || '|u14') AS h14,
        md5(b.application_id || '|' || p.population_id || '|u15') AS h15
    FROM base_ids b
    CROSS JOIN params p

    -- SQL teaching note:
    -- CROSS JOIN is appropriate here because params contains exactly one row.
    -- This attaches the same run-level parameter values to every generated
    -- application row.
),

uniforms AS (
    SELECT
        s.*,

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
        ('x' || substr(h1, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u1,
        ('x' || substr(h2, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u2,
        ('x' || substr(h3, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u3,
        ('x' || substr(h4, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u4,
        ('x' || substr(h5, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u5,
        ('x' || substr(h6, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u6,
        ('x' || substr(h7, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u7,
        ('x' || substr(h8, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u8,
        ('x' || substr(h9, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u9,
        ('x' || substr(h10, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u10,
        ('x' || substr(h11, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u11,
        ('x' || substr(h12, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u12,
        ('x' || substr(h13, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u13,
        ('x' || substr(h14, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u14,
        ('x' || substr(h15, 1, 15))::bit(60)::bigint / power(16::numeric, 15) AS u15
    FROM seeded s

    -- Practical interpretation:
    -- These u1-u15 fields are the reusable deterministic “random” drivers for
    -- later sections of the model.
    --
    -- For example, later logic can use:
    --   u2 for product assignment
    --   u3 for score-band assignment
    --   u7 for income scaling
    --   u15 for delinquency behavior
    --
    -- This keeps variability rich, but reproducible.
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
    - PD and expected loss
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
),

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

borrower_profile AS (
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
        -- shopping / credit-seeking behavior and is used later as a PD multiplier.
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
    FROM score_and_product s
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
),

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

  Those answers are critical because PD is not driven only by "credit quality."
  It is also driven by structure:
    borrower quality + product design + payment burden = affordability stress

Teaching note:
  This section is intentionally split into four sub-layers:

    1. apr_and_payment
       Finalize requested amount and construct a raw APR

    2. apr_bounded
       Apply product-level APR floors and ceilings

    3. payment_metrics
       Convert amount + APR + term into a monthly payment proxy

    4. affordability
       Translate payment burden into standardized affordability ratios

Key modeling principle:
  The engine separates:
    - exposure construction
    - pricing construction
    - payment derivation
    - affordability measurement

  This separation is deliberate. It allows users to inspect and recalibrate each
  part of the decisioning chain independently.

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
    - strong downstream contrast in PTI, PD, and Expected Loss
*/

apr_and_payment AS (
    SELECT
        c.*,

        /*
        ========================================================================
        7A. FINAL REQUESTED AMOUNT
        ========================================================================
        Goal:
          Convert the product-specific base amount from Section 5 into a final,
          borrower-aware exposure amount.

        General logic:
          1. Start with requested_amount_base
          2. Apply an income-sensitive scaling factor
          3. Apply a modest random dispersion factor
          4. Enforce product-level minimum / maximum bounds

        Why this is necessary:
          The base amount created in Section 5 is only a product-consistent
          starting point. It does not yet fully reflect borrower capacity.
        */

        round(
            CASE product_type

                /*
                ----------------------------------------------------------------
                UNSECURED PERSONAL LOAN
                ----------------------------------------------------------------
                Formula:
                  requested_amount_base
                  * (0.70 + (annual_income_raw / 100000.0) * 0.35)
                  * (0.90 + u6 * 0.20)

                Hardcoded values explained:
                  0.70
                    = conservative starting multiplier
                    = ensures the base amount is not automatically passed through
                      at full size for every borrower

                  annual_income_raw / 100000.0
                    = scales income relative to a $100k reference point
                    = borrowers near $100k income add about 0.35 of uplift

                  0.35
                    = moderate income sensitivity
                    = personal loans should respond to income, but not as
                      dramatically as mortgage exposure

                  0.90 + u6 * 0.20
                    = random dispersion factor from 0.90 to 1.10
                    = roughly +/-10% around the central scaled amount

                Interpretation:
                  Personal loans are unsecured, so we allow meaningful income
                  sensitivity, but still keep the scaling more conservative than
                  large secured products.
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
                ----------------------------------------------------------------
                AUTO LOAN
                ----------------------------------------------------------------
                Formula:
                  requested_amount_base
                  * (0.80 + (annual_income_raw / 120000.0) * 0.25)
                  * (0.90 + u6 * 0.20)

                Hardcoded values explained:
                  0.80
                    = stronger starting carry-through than personal loans
                    = auto loans are tied to a specific asset purchase and often
                      have somewhat tighter exposure logic

                  120000.0
                    = larger income denominator than personal loans
                    = slows the pace at which amount scales upward with income

                  0.25
                    = lower income sensitivity than personal loans
                    = auto loan sizes are partly constrained by vehicle economics,
                      not just borrower capacity

                  0.90 to 1.10 dispersion
                    = keeps variation present without overpowering the base logic

                Interpretation:
                  Auto exposure should vary by income, but not explode upward as
                  quickly as mortgages or open-ended secured borrowing.
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
                ----------------------------------------------------------------
                REVOLVING LINE
                ----------------------------------------------------------------
                Formula:
                  requested_amount_base
                  * (0.75 + (annual_income_raw / 90000.0) * 0.30)
                  * (0.90 + u6 * 0.20)

                Hardcoded values explained:
                  0.75
                    = moderate base multiplier
                    = revolving lines should be sensitive to income but still
                      constrained because this is line / limit sizing, not
                      amortizing loan balance sizing

                  90000.0
                    = smaller denominator than personal / auto
                    = makes revolving limits somewhat more responsive to income

                  0.30
                    = meaningful, but not excessive, uplift from income

                Interpretation:
                  Revolving limits often scale with borrower capacity, but should
                  still remain bounded and not become mortgage-like in size.
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
                ----------------------------------------------------------------
                HELOC
                ----------------------------------------------------------------
                Formula:
                  requested_amount_base
                  * (0.80 + (annual_income_raw / 140000.0) * 0.35)
                  * (0.90 + u6 * 0.20)

                Hardcoded values explained:
                  0.80
                    = relatively strong base carry-through

                  140000.0
                    = larger denominator than revolving/personal
                    = HELOC scaling responds to income, but in a more measured way

                  0.35
                    = moderate-to-strong sensitivity
                    = HELOCs are secured and can support larger lines than
                      unsecured products

                Interpretation:
                  HELOCs sit between mortgage and revolving behavior:
                    - secured like mortgage
                    - line-like like revolving
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
                ----------------------------------------------------------------
                MORTGAGE
                ----------------------------------------------------------------
                Mortgage uses a dual-constraint design.

                Why mortgage needs special treatment:
                  Mortgage was the product most likely to become unrealistic if
                  left as a simple scaled base amount. Earlier calibration showed
                  that mortgage amounts could become too large relative to income,
                  which then pushed PTI to implausible levels.

                The current design protects against that using:
                  1. an income-multiple cap
                  2. a structured base anchor
                  3. product-level absolute bounds

                The final value is:
                  LEAST(
                    max_mortgage_amt,
                    income_multiple_cap,
                    structured_base_amount
                  )

                That means mortgage is constrained by whichever limit is most
                conservative for the row.
                */
                WHEN 'MORTGAGE' THEN
                    LEAST(
                        max_mortgage_amt,

                        /*
                        Income multiple cap:
                          SUPER_PRIME -> 5.75x income
                          PRIME       -> 5.00x income
                          NEAR_PRIME  -> 4.25x income
                          SUBPRIME    -> 3.50x income
                          DEEP_SUBPRIME -> 2.75x income

                        Why these multiples?
                          They reflect the idea that stronger borrowers can
                          support larger housing exposure relative to income,
                          while weaker borrowers should be constrained more
                          aggressively.

                        Why multiply by (0.70 + u7 * 0.30)?
                          This creates a borrower-specific distance from the cap:
                            - minimum 70% of cap
                            - maximum 100% of cap

                          This prevents too many mortgage rows from clustering
                          right at the maximum borrowing ceiling.
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

                        Hardcoded values explained:
                          0.45
                            = conservative starting share of requested_amount_base

                          annual_income_raw / 250000.0
                            = income scaling relative to a $250k ceiling

                          LEAST(..., 1.0)
                            = prevents extremely high incomes from lifting this
                              multiplier beyond the intended range

                          * 0.30
                            = maximum added uplift from income under this branch

                          0.94 + u6 * 0.12
                            = tighter dispersion range than other products
                            = 0.94 to 1.06, or roughly +/-6%

                        Why tighter dispersion here?
                          Mortgage already has the widest natural amount scale,
                          so it needs less extra randomness than smaller products.
                        */
                        GREATEST(
                            min_mortgage_amt,
                            requested_amount_base
                            * (0.45 + LEAST(annual_income_raw / 250000.0, 1.0) * 0.30)
                            * (0.94 + u6 * 0.12)
                        )
                    )
            END
        ,2) AS requested_amount,

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
        */

        round(
            /*
            1. Product base rate:
               This is the structural pricing anchor from Section 2.
               It represents the product's starting APR level before borrower
               risk and macro shifts are applied.
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

               Hardcoded values explained:
                 SUPER_PRIME: 0.000 + up to 0.010
                 PRIME:       0.010 + up to 0.020
                 NEAR_PRIME:  0.030 + up to 0.030
                 SUBPRIME:    0.060 + up to 0.040
                 DEEP_SUBPRIME: 0.100 + up to 0.050

               Interpretation:
                 - stronger borrowers should price close to the base rate
                 - weaker borrowers should price materially above the base rate
                 - wider ranges in weaker bands create more realistic spread
                   within segment
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
               (u5 - 0.5) * 0.020

               Why this works:
                 u5 is approximately uniform(0,1)
                 subtracting 0.5 centers it around 0
                 multiplying by 0.020 creates a range from about -0.01 to +0.01

               Result:
                 roughly +/- 1 percentage point of idiosyncratic pricing noise
            */
            + ((u5 - 0.5) * 0.020)

            /*
            4. Macro rate shift:
               rate_shift_bps / 10000.0 converts basis points to decimal APR.
               Example:
                 +200 bps -> +0.0200
                 -100 bps -> -0.0100
            */
            + (rate_shift_bps / 10000.0)
        ,6) AS apr_raw
    FROM bankruptcy_and_context c
),

apr_bounded AS (
    SELECT
        a.*,

        /*
        ========================================================================
        7C. APR FLOOR / CEILING ENFORCEMENT
        ========================================================================
        Goal:
          Prevent APR proxies from falling outside plausible product ranges.

        Why this is necessary:
          Even if apr_raw is directionally reasonable, a combination of base rate,
          score premium, random dispersion, and macro shift can still occasionally
          create values that are too low or too high for the intended product.

        Product-specific bounds:
          Mortgage:              4.00% to 10.00%
          Auto:                  5.00% to 22.00%
          Unsecured Personal:    8.00% to 35.00%
          Revolving Line:       15.00% to 35.00%
          HELOC:                 5.00% to 15.00%

        Interpretation:
          These are burden-estimation ranges, not legal/product policy limits.
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
    FROM apr_and_payment a
),

payment_metrics AS (
    SELECT
        a.*,

        /*
        ========================================================================
        7D. MONTHLY PAYMENT DERIVATION
        ========================================================================
        Goal:
          Convert amount + APR + term into a monthly payment proxy.

        Why "proxy"?
          These are simplified payment estimates intended for affordability and
          risk simulation, not production billing calculations.
        */
        round(
            CASE
                /*
                Installment products:
                  Use the standard amortizing payment formula

                  Payment = P * [ r(1+r)^n / ((1+r)^n - 1) ]

                  where:
                    P = principal / requested_amount
                    r = monthly interest rate
                    n = number of months

                Why divide APR by 12.0?
                  Converts annual nominal APR into monthly rate.

                Why use power(1 + r, n)?
                  That is the compound-growth component required for amortization.

                Why guard against NULL or zero term?
                  Installment payment formula is not valid without a positive term.
                */
                WHEN product_type IN ('UNSECURED_PERSONAL_LOAN', 'AUTO_LOAN', 'MORTGAGE') THEN
                    CASE
                        WHEN loan_term_months IS NULL OR loan_term_months = 0 THEN NULL
                        ELSE requested_amount * ((((base_apr_for_payment_calc / 12.0) * power(1 + (base_apr_for_payment_calc / 12.0), loan_term_months))) / (power(1 + (base_apr_for_payment_calc / 12.0), loan_term_months) - 1))
                    END

                /*
                Revolving line:
                  requested_amount * 0.03

                Why 3%?
                  This is a simplified minimum-payment-style proxy. It is not a
                  full card payment model; it is an affordability approximation
                  suitable for stress and comparison logic.
                */
                WHEN product_type = 'REVOLVING_LINE' THEN requested_amount * 0.03

                /*
                HELOC:
                  requested_amount * (APR / 12)

                Why this formula?
                  This approximates an interest-only monthly burden, which is a
                  reasonable simple proxy for HELOC payment burden in Module 1.
                */
                WHEN product_type = 'HELOC' THEN requested_amount * (base_apr_for_payment_calc / 12.0)
            END
        ,2) AS monthly_payment_proxy,

        /*
        amount_to_income_ratio:
          Exposure divided by annual income.

        Why this matters:
          This is a simple size-of-exposure metric that supplements PTI.
          Two borrowers may have similar PTI but very different exposure size
          relative to income.
        */
        round(requested_amount / NULLIF(annual_income_raw,0), 6) AS amount_to_income_ratio
    FROM apr_bounded a
),

affordability AS (
    SELECT
        p.*,

        /*
        annual_income:
          Rounded presentation version of annual_income_raw.
          The raw field is carried earlier for intermediate calculations;
          this rounded field is the cleaner downstream reporting version.
        */
        round(annual_income_raw,2) AS annual_income,

        /*
        ========================================================================
        7E. AFFORDABILITY MEASUREMENT (PTI)
        ========================================================================
        payment_to_income_ratio:
          monthly payment divided by monthly income

        Formula:
          monthly_payment_proxy / (annual_income_raw / 12)

        Why divide annual income by 12?
          PTI is a monthly burden measure, so income must be converted to
          monthly income for an apples-to-apples comparison.

        Why this metric is central:
          PTI is the key affordability bridge in Module 1. It is the most direct
          link between product structure and default pressure.

        SQL teaching note:
          NULLIF(annual_income_raw / 12.0, 0) prevents divide-by-zero errors by
          returning NULL if the denominator were ever zero.
        */
        round(monthly_payment_proxy / NULLIF(annual_income_raw / 12.0,0), 6) AS payment_to_income_ratio

    FROM payment_metrics p
),

/*
================================================================================
SECTION 8. RISK MODELING — PD, LGD, EXPECTED LOSS
================================================================================
Purpose:
  Estimate credit risk outcomes for each application:
    - Probability of Default (PD)
    - Loss Given Default (LGD)
    - Expected Loss (EL)

Why this section matters:
  This is the risk translation layer of the engine.

  Earlier sections established:
    - who the borrower is
    - what product they hold
    - how strong or weak their profile is
    - what payment burden that product creates

  This section converts those inputs into explicit risk outputs.

Teaching note:
  This section uses an explainable, multiplier-based framework instead of
  a black-box statistical fit.

  In plain English, the risk logic works like this:
    1. Start with a base PD by score band
    2. Adjust that base PD up or down using interpretable risk multipliers
    3. Bound the final PD to prevent implausible tails
    4. Attach a product-level LGD assumption
    5. Compute expected loss from amount * PD * LGD

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
  - Why did PD increase?
  - Which borrower dimensions matter most?
  - What happens if PTI worsens but delinquencies remain clean?
  - How does product type affect risk holding other traits constant?

Governance note:
  PD is bounded using:
    LEAST(0.450000, GREATEST(0.005000, ...))

  This prevents:
    - unrealistically low risk
    - runaway high-risk estimates

  Important calibration note:
    During validation, one of the planned future enhancements identified for V2
    was reducing PD cap crowding in the weakest segments. That conclusion came
    directly from the Section 9 review framework below, especially the product ×
    score views and the portfolio-level PD distribution review.
*/

pd_components AS (
    SELECT
        a.*,

        /*
        ========================================================================
        8A. BASE PD BY SCORE BAND
        ========================================================================
        Goal:
          Establish the starting probability of default before row-level
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
          Base PD is not the final answer. It is the starting point.
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
          Because they are layered on top of base PD and other multipliers.
          Oversized multipliers would make the tail collapse into the PD cap too
          quickly, which would reduce interpretability.
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
    FROM affordability a
),

pd_and_loss AS (
    SELECT
        p.*,

        /*
        ========================================================================
        8L. FINAL PD ESTIMATION
        ========================================================================
        Formula:
          estimated_pd =
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
          identical characteristics do not always end with the exact same PD.

        Why floor and cap?
          GREATEST(0.005000, ...) sets a 0.50% floor
          LEAST(0.450000, ...) sets a 45.00% cap

        Why those values?
          0.50% floor:
            prevents unrealistically tiny PD values for strong rows

          45.00% cap:
            prevents runaway tail values from becoming implausible or dominating
            expected loss excessively

        Validation connection:
          The V1 validation narrative in the script header explicitly notes that
          weak-end PD cap crowding remains a future refinement opportunity.
          That finding came from reviewing this capped output across score bands
          and product × score combinations in Section 9.
        */
        round(
            LEAST(
                0.450000,
                GREATEST(
                    0.005000,
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
                )
            )
        ,6) AS estimated_pd,

        /*
        ========================================================================
        8M. LGD ASSIGNMENT
        ========================================================================
        Logic:
          LGD is attached directly by product from the parameter block.

        Why is LGD simpler than PD?
          That was an intentional Module 1 design decision documented in the
          header. PD is the richer behavioral model here; LGD is kept simpler so
          that users can still test expected loss sensitivity without requiring
          a full collateral / recovery simulation engine.
        */
        CASE product_type
            WHEN 'MORTGAGE' THEN lgd_mortgage
            WHEN 'AUTO_LOAN' THEN lgd_auto
            WHEN 'UNSECURED_PERSONAL_LOAN' THEN lgd_personal
            WHEN 'REVOLVING_LINE' THEN lgd_revolving
            WHEN 'HELOC' THEN lgd_heloc
        END AS estimated_lgd
    FROM pd_components p
)

SELECT
    /*
    ============================================================================
    8N. FINAL OUTPUT SHAPE
    ============================================================================
    Purpose:
      Expose both the final business-facing outputs and the underlying model
      components used to create them.

    Why include all the multiplier fields?
      This makes the engine auditable and teachable. A future user can inspect
      not only the final PD, but exactly which factors contributed to it.
    */
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
    estimated_pd,
    estimated_lgd,

    /*
    expected_loss_amount:
      Expected Loss = Exposure * PD * LGD

    Why this matters:
      This is the final portfolio economics metric for Module 1. It translates
      borrower quality and product structure into a loss expectation that can be
      aggregated later for strategy testing.
    */
    round(requested_amount * estimated_pd * estimated_lgd, 2) AS expected_loss_amount,

    -- created_ts:
    -- capture creation time for traceability / rerun auditing
    CURRENT_TIMESTAMP AS created_ts
FROM pd_and_loss
;

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
    - PTI behaves as a meaningful affordability bridge into PD
    - the mortgage calibration materially improved unrealistic exposure / PTI behavior
    - two future enhancements remain visible:
        1. upper-tail mortgage affordability refinement
        2. weak-end PD cap crowding refinement

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

How to use this section:
  The best practice is to review these queries in sequence after any meaningful
  parameter or logic change. Together they answer:
    - Did the engine build the right number of records?
    - Did the target product / score mixes land correctly?
    - Are the distributions plausible?
    - Do stronger borrowers generally look stronger?
    - Do products remain differentiated?
    - Does affordability translate into risk as intended?
    - Are edge cases plausible rather than absurd?

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
        lower PD
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
    = modeled probability of default

  estimated_lgd
    = modeled loss severity if default occurs

  expected_loss_amount
    = requested_amount * estimated_pd * estimated_lgd

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
--   Confirm that the generated score-band mix is reasonably aligned to the
--   configured score distribution assumptions.
--
-- Why this matters:
--   The base risk profile of the whole portfolio starts here. If score-band mix
--   is materially off, all portfolio-level PD and EL summaries will shift.
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
--     should show clear variation without everything collapsing to the floor or cap
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
--     = average modeled default risk / expected loss.
--       These should worsen clearly as score quality weakens.
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
--       lower PD
--       lower expected loss
--
--   - weaker score bands should generally show the opposite pattern
--
-- Example of a healthy story:
--   If PRIME has lower utilization, fewer delinquencies, lower PTI, and lower
--   PD than SUBPRIME, that is a sign the engine is behaving correctly.
--
-- Example of a red flag:
--   If DEEP_SUBPRIME shows better affordability and lower risk than PRIME, the
--   segment logic is probably broken or a calibration change had unintended effects.
--
-- Important nuance:
--   Do not expect every single metric to improve perfectly and mechanically in
--   every query revision. Some overlap is healthy. The goal is realistic average
--   directional movement, not robotic monotonicity.

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
--   - PTI, PD, LGD, and Expected Loss should vary sensibly by product
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
--   in the header: PTI behaves as the intended affordability bridge into PD.
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
--   - average PD should generally rise as PTI worsens
--   - expected loss should generally rise as PTI worsens
--   - some noise is acceptable because exposure size and product still matter
--   - the pattern should be broadly monotonic even if not mathematically perfect
--
-- Example of a healthy story:
--   If the '<5%' bucket has the lowest average PD and the '20%+' bucket has the
--   highest, the affordability bridge is working.
--
-- Example of a red flag:
--   If high-PTI buckets show lower risk than low-PTI buckets, something in the
--   exposure / payment / affordability chain may be broken.

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
--   - the remaining weak-end PD cap crowding that is documented as a V2 target
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
--     = average modeled default probability
--
--   avg_expected_loss
--     = average modeled expected loss
--
-- What to look for:
--   - sensible counts in each cell
--   - products remain differentiated within the same score band
--   - PTI and PD vary in ways that match both score quality and structure
--   - weaker mortgage cells no longer show implausible affordability
--   - extreme-risk cells do not all collapse to the same capped PD level
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
--   If all weak-end cells show nearly identical PD regardless of product or
--   affordability, that may indicate too much PD cap crowding.

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
--   Provide one more quick cross-sectional view for PD and Expected Loss.
--
-- Why this matters:
--   This is a compact diagnostic query that helps reviewers quickly scan where
--   risk concentration lives across the portfolio.
--
-- What to look for:
--   - higher PD in weaker score bands
--   - meaningful product differences
--   - possible evidence of PD cap crowding in the weakest cells
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
