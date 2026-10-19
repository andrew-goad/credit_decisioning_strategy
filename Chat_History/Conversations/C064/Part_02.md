# Power BI release validation and reporting

## Part 02

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_01.md) · [Next](Part_03.md)

<a id="c064-m00054"></a>

### C064-M00054

**Andrew** · 2026-07-19T15:10:35.591000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00054 -->
application_seq relationship existed
<!-- END_MESSAGE C064-M00054 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00055"></a>

### C064-M00055

**ChatGPT** · 2026-07-19T15:10:37.022676-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00055 -->
Perfect. That explains it.

**Power BI auto-created the relationship on the wrong key.**

It chose:

```text
application_seq
```

instead of

```text
Application_ID
```

This is exactly why I prefer turning Auto Detect off on enterprise models.

---

# Fix it

## Step 1

Click the existing relationship line (the one connecting `application_seq`).

Press:

```text
Delete
```

or right-click it and select:

```text
Delete
```

Confirm the deletion.

There should now be **no relationship** between the two tables.

---

## Step 2

Now create the correct relationship.

Drag

```text
FactReleaseComparison[Application_ID]
```

to

```text
FactReconciliationDetail[Application_ID]
```

Configure:

| Setting | Value |
|---------|-------|
| Cardinality | **One-to-many (1:*)** |
| Cross-filter | **Single** |
| Active | **Yes** |

This one should save immediately.

---

# Why `Application_ID` is the correct key

Your data model is:

```
FactReleaseComparison
--------------------------------
1 row per application
50,000 rows
```

↓

```
FactReconciliationDetail
--------------------------------
1 row per
Application
×
Changed Variable

58,382 rows
```

So

```
Application_ID
```

is the business key.

---

# Why `application_seq` is wrong

Although it *looks* unique inside each release,

it's simply

```
1
2
3
...
50000
```

assigned during generation.

It is **not** the business identifier.

If later you introduce

```
Rate Stress

Growth

Tight Credit

Baseline
```

you will have

```
application_seq = 1
```

four different times.

But

```
Application_ID
```

will still uniquely identify the borrower/application.

This is one of those subtle modeling decisions that separates a robust semantic model from a fragile one.

---

## Another recommendation

Once the correct relationship is created, go to:

```text
File
→ Options and settings
→ Options
→ Current File
→ Data Load
```

and **uncheck**:

```text
Autodetect new relationships after data is loaded
```

For this project, we'll explicitly control every relationship ourselves. It prevents Power BI from making "helpful" guesses like the one it just made.

---

Once the `Application_ID` relationship is active, we'll continue with the DAX measures and build the first QA dashboard. We're very close to having the analytical foundation fully locked down.
<!-- END_MESSAGE C064-M00055 -->


---

<a id="c064-m00056"></a>

### C064-M00056

**Andrew** · 2026-07-19T15:19:38.522000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00056 -->
*No text body is present in the export. This message may contain an image or attachment.*
<!-- END_MESSAGE C064-M00056 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00057"></a>

### C064-M00057

**ChatGPT** · 2026-07-19T15:19:46.043151-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00057 -->
Power BI is rejecting `Measures` because that name is reserved in your current version.

Use a different table name. I recommend:

```text
_Measures
```

The leading underscore keeps it near the top of the field list and clearly identifies it as a technical measure table.

## Fix

1. Close the error dialog.
2. Rename the table to:

```text
_Measures
```

3. Keep the placeholder column as:

```text
Measure_Home
```

4. Right-click `Measure_Home` and select:

```text
Hide in report view
```

Then create all new measures in `_Measures`, not `Measures`.

For example:

```DAX
Total Applications =
COUNTROWS ( FactReleaseComparison )
```

This naming change does not affect any of the DAX formulas. Only the table that stores the measures changes.
<!-- END_MESSAGE C064-M00057 -->


---

<a id="c064-m00059"></a>

### C064-M00059

**Andrew** · 2026-07-19T15:25:52.967000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00059 -->
when you say DAX Total Applications, expected result 50,000 - where do I see that?
<!-- END_MESSAGE C064-M00059 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00060"></a>

### C064-M00060

**ChatGPT** · 2026-07-19T15:25:54.498421-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00060 -->
Excellent question. **You won't see the value in the DAX editor itself.** The DAX formula only defines the measure.

There are three common ways to verify it. The easiest is #1.

## Option 1 (Recommended): Put it on a Card visual

1. Go back to **Report View** (the bar chart icon on the left).
2. On the Visualizations pane, insert a **Card** visual.
3. Drag **Total Applications** from the `_Measures` table onto the card.

You should immediately see:

```text
50,000
```

This is how we'll validate almost all of our measures.

---

## Option 2: Use the Data pane

If you click the measure in the Fields/Data pane, you'll only see its formula—not its evaluated value. So this isn't useful for validation.

---

## Option 3: Use a Table visual

Insert a Table visual and add the measure. It will display:

| Total Applications |
|-------------------:|
| 50,000 |

---

# Going forward

I actually want to change our workflow slightly because it will be faster and easier to debug.

Instead of creating all nine measures and **then** checking them, we'll do this:

1. Create one measure.
2. Drop it on a Card.
3. Verify the number.
4. Move to the next measure.

That way, if something is wrong, we know exactly which measure introduced the problem.

So let's proceed like this:

### Measure 1

```DAX
Total Applications =
COUNTROWS(FactReleaseComparison)
```

**Expected card value:**

```text
50,000
```

### Measure 2

```DAX
Distinct Applications =
DISTINCTCOUNT(FactReleaseComparison[Application_ID])
```

**Expected card value:**

```text
50,000
```

Once both cards show **50,000**, we'll move to **Affected Applications** and **Unaffected Applications**, where we'll validate the critical **21,326 / 28,674** split.

This incremental approach is how I typically build enterprise Power BI models because it catches issues immediately rather than after dozens of measures have been written.
<!-- END_MESSAGE C064-M00060 -->


---

<a id="c064-m00061"></a>

### C064-M00061

**Andrew** · 2026-07-19T15:34:40.174000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00061 -->
here are my cards, although they round the thousands with the k suffix added
<!-- END_MESSAGE C064-M00061 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00062"></a>

### C064-M00062

**ChatGPT** · 2026-07-19T15:34:46.136638-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00062 -->
The measures appear to be working correctly. The `K` suffix is only a card formatting setting.

For the QA page, show exact counts so you can verify them directly.

## Change each count card to exact values

Select a card, then in the **Format visual** pane:

1. Open **Callout value**.
2. Find **Display units**.
3. Change it from:

```text
Auto
```

to:

```text
None
```

4. Set **Decimal places** to `0`.

Repeat for:

- Total Applications
- Distinct Applications
- Affected Applications
- Unaffected Applications
- Variable Change Records
- Changed Functional Variables

Leave **Application Change Rate** formatted as a percentage with two decimal places.

Your cards should then display:

| Measure | Expected |
|---|---:|
| Total Applications | 50,000 |
| Distinct Applications | 50,000 |
| Affected Applications | 21,326 |
| Unaffected Applications | 28,674 |
| Application Change Rate | 42.65% |
| Variable Change Records | 58,382 |
| Changed Functional Variables | 7 |

The current rounded values are consistent with those expectations, but exact display is preferable for the model-QA page. On the eventual executive page, we may deliberately use compact values such as `50K` and `58.4K`.

## Next: variable reconciliation table

Add a **Table** visual and place these fields in it:

```text
FactReconciliationDetail[Variable]
_Measures[Variable Change Records]
```

Sort `Variable Change Records` descending.

You should see:

| Variable | Variable Change Records |
|---|---:|
| PAYMENT_TO_INCOME_RATIO | 16,138 |
| MONTHLY_PAYMENT_PROXY | 16,138 |
| EXPECTED_LOSS_AMOUNT | 10,836 |
| ESTIMATED_PD | 7,208 |
| REQUESTED_AMOUNT | 3,686 |
| AMOUNT_TO_INCOME_RATIO | 3,686 |
| MULT_PTI | 690 |

This is the next critical reconciliation checkpoint.
<!-- END_MESSAGE C064-M00062 -->


---

<a id="c064-m00064"></a>

### C064-M00064

**Andrew** · 2026-07-19T15:38:00.748000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00064 -->
I do not see format visual callout value
<!-- END_MESSAGE C064-M00064 -->


---

<a id="c064-m00065"></a>

### C064-M00065

**ChatGPT** · 2026-07-19T15:38:02.562062-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00065 -->
That's because you're likely using the **new Card visual** (introduced in newer Power BI versions). It has different formatting options than the classic Card, and Microsoft moved several settings.

Let's first identify which visual you're using.

## Quick check

Click one of your cards.

On the right side, do you see the **Format** pane with a paint roller icon?

If yes, look for one of these sections:

- **Visual**
- **General**

Under **Visual**, do you see something called:

- **Reference labels**
- **Callout values**
- **Data label**
- **Values**

The exact wording varies by Power BI version.

---

## Easier way (works in every version)

Instead of hunting through the formatting pane:

1. Click one of your cards.
2. On the ribbon, select:

```text
Format
```

or

```text
Visualizations → Format
```

Search for:

```text
Display units
```

If there is a search box in the Format pane, type:

```text
display
```

Power BI will jump directly to that setting.

---

## If you don't want to spend time on this right now...

We can safely ignore it.

The measures are clearly correct:

- ✅ 50K = 50,000
- ✅ 21K = 21,326
- ✅ 29K = 28,674
- ✅ 58K = 58,382
- ✅ 42.65%
- ✅ 7

So the DAX is working exactly as expected.

I'd rather keep the momentum than spend 15 minutes chasing a cosmetic setting.

---

### Can you tell me one thing?

What version of Power BI Desktop are you running?

Go to:

```text
File
→ About
```

or

```text
Help
→ About
```

and tell me the version (or take a screenshot).

That will let me give instructions that match your UI exactly for the rest of the project.
<!-- END_MESSAGE C064-M00065 -->


---

<a id="c064-m00066"></a>

### C064-M00066

**Andrew** · 2026-07-19T15:54:24.817000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00066 -->
reached the end of 15.4 successfully. resolved the display issues.
<!-- END_MESSAGE C064-M00066 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00067"></a>

### C064-M00067

**ChatGPT** · 2026-07-19T15:54:26.233409-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00067 -->
This is a major milestone, and everything on this page looks **exactly right**.

## Model QA Status: PASS ✅

Your dashboard has independently reproduced every critical reconciliation metric.

| Validation | Expected | Actual | Status |
|------------|---------:|-------:|:------:|
| Total Applications | 50,000 | 50,000 | ✅ |
| Distinct Applications | 50,000 | 50,000 | ✅ |
| Affected Applications | 21,326 | 21,326 | ✅ |
| Unaffected Applications | 28,674 | 28,674 | ✅ |
| Application Change Rate | 42.65% | 42.65% | ✅ |
| Variable Change Records | 58,382 | 58,382 | ✅ |
| Changed Functional Variables | 7 | 7 | ✅ |

The variable reconciliation table is also an exact match:

- PAYMENT_TO_INCOME_RATIO → **16,138**
- MONTHLY_PAYMENT_PROXY → **16,138**
- EXPECTED_LOSS_AMOUNT → **10,836**
- ESTIMATED_PD → **7,208**
- REQUESTED_AMOUNT → **3,686**
- AMOUNT_TO_INCOME_RATIO → **3,686**
- MULT_PTI → **690**

And the status table correctly reconciles:

- Affected → **21,326**
- Unaffected → **28,674**
- Total → **50,000**

This gives us very high confidence that the semantic model is correct.

---

# Now I want to pivot

This QA page has served its purpose.

From here forward, **we're no longer validating data**.

We're building a **portfolio-quality executive analytics application**.

That changes how we think.

Instead of asking:

> "What measures do we need?"

we start asking:

> "If a Wells Fargo Managing Director opened this report for the first time, what would immediately communicate the value of this project?"

---

# I want to build this like an enterprise release dashboard

Instead of a collection of charts, I'd like each page to answer one executive question.

## Page 1 — Executive Release Summary

**Question:**

> What changed between V1 and V2?

Large KPI cards

Executive narrative

Application impact

Variable impact

Workstream summary

---

## Page 2 — Release Impact Explorer

**Question:**

> Which applications changed and why?

Product slicer

Score-band slicer

Application search

Changed field count

V1 → V2 comparison

---

## Page 3 — Variable Analysis

**Question:**

> Which variables changed the most?

Waterfall

Heatmap

Distribution

Increase vs decrease

Product breakdown

---

## Page 4 — Mortgage Realism (Workstream A)

This becomes almost a mini-case study.

Show:

- Requested Amount distribution
- PTI improvement
- Mortgage diagnostics
- Before/After story

---

## Page 5 — PD Dispersion (Workstream B)

Demonstrate

- reduced cap crowding
- improved dispersion
- retained ordering

---

## Page 6 — Technical Validation

The page you'd show another analytics developer.

Relationships

Reconciliation

QA

Counts

Schema additions

---

# Before we build another page...

I think we should improve the semantic model one more time.

Right now everything works.

But the field list is still "developer-friendly."

For example:

```text
Requested_Amount_V1
Requested_Amount_V2
Requested_Amount_Delta
Requested_Amount_Changed
```

repeated dozens of times.

I'd like to organize it like an enterprise model:

```
Measures
-------------------
Executive KPIs

Release KPIs

Mortgage KPIs

PD KPIs

QA KPIs
```

```
FactReleaseComparison
-------------------
Application

Borrower

Product

Affordability

Risk

Diagnostics
```

Everything grouped logically, with hidden helper fields where appropriate.

That will make the report much easier to build and much more polished.

---

# My recommendation for the next session

Rather than immediately creating more visuals, let's spend 30–45 minutes on **semantic model refinement**:

1. Create the remaining dimensions:
   - `DimProduct`
   - `DimScoreBand`
   - `DimVariable`
   - `DimSchemaAddition`
2. Organize display folders for measures.
3. Hide technical/helper columns that shouldn't appear in the field list.
4. Assign proper data categories and formatting.
5. Create a clean, business-friendly field list.

That foundation will make every report page easier to build and will make the PBIX look like it came from an enterprise BI team rather than a prototype.

After that, we'll start building what I think will become a very impressive executive dashboard. I think this project has evolved beyond a simple validation report into something that showcases architecture, governance, analytics, and communication together.
<!-- END_MESSAGE C064-M00067 -->


---

<a id="c064-m00068"></a>

### C064-M00068

**Andrew** · 2026-07-19T15:57:52.542000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00068 -->
sounds good though keep in mind I would like to publish a version of this by morning - and then use this experience to update my resume to include PowerBI - and then communicate updated resume/cover letter to the Wells Fargo HR recruiter ahead of tomorrow's interview. i'm willing to stay up late, but let's do make sure we are working towards an appropriate finish line (can always make it fancier later).
<!-- END_MESSAGE C064-M00068 -->


---

<a id="c064-m00069"></a>

### C064-M00069

**ChatGPT** · 2026-07-19T15:57:55.346370-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00069 -->
Agreed. We should **freeze the finish line now** and optimize for a credible Version 1 by morning—not a perfect enterprise build.

## Morning-ready finish line

A publishable V1 should include only four things:

1. **Executive Summary page**
2. **Variable Analysis page**
3. **Application Explorer page**
4. **Technical QA page** — your existing page, cleaned up and retained as supporting evidence

That is enough to demonstrate:

- Power Query data preparation
- semantic modeling
- DAX
- release validation
- executive storytelling
- drill-down analysis
- governance discipline

We should defer:

- dedicated Mortgage page
- dedicated PD Dispersion page
- elaborate schema dimensions
- heavy display-folder cleanup
- custom themes
- advanced bookmarks/navigation
- exhaustive tooltips
- pixel-perfect styling

Those become V1.1 enhancements.

# Tonight’s build order

## Block 1 — Executive Summary
Target: 60–90 minutes

Create one page answering:

> What changed from Module 1 V1 to V2?

Use:

- 5 KPI cards
- affected vs unaffected visual
- variable-change bar chart
- concise release narrative
- product or score-band impact chart

## Block 2 — Variable Analysis
Target: 45–60 minutes

Answer:

> Which variables changed, in what direction, and by how much?

Use:

- variable change counts
- increase/decrease split
- average absolute delta
- product breakdown
- variable slicer

## Block 3 — Application Explorer
Target: 45–60 minutes

Answer:

> What happened to a specific application?

Use:

- Application ID slicer/search
- basic application profile
- changed-variable table with V1, V2, delta, relative delta
- changed-field count/status

## Block 4 — QA cleanup and publish
Target: 45–60 minutes

- rename QA page
- align visuals
- add titles and source note
- remove obvious empty space
- test filters
- save PBIX
- publish/export screenshots or PDF
- capture 2–3 strong images for portfolio and recruiter communication

## Block 5 — Resume and recruiter communication
After the report is stable:

- add Power BI to toolkit accurately
- add one project bullet grounded in what you actually built
- update cover letter or recruiter message
- prepare a 60–90 second interview explanation

# What we should not claim yet

Do not position yourself as an advanced Power BI developer overnight.

A defensible framing is:

> Built an interactive Power BI release-validation dashboard using Power Query, dimensional modeling, DAX measures, application-level reconciliation, and executive drill-down views across 50,000 matched synthetic credit applications.

That is strong and accurate.

# Immediate next step

Skip dimensions for now. Keep the current two-table model plus `_Measures`.

Create a new page and rename it:

```text
01 | Executive Summary
```

Then create these five cards:

```text
Total Applications
Affected Applications
Application Change Rate
Variable Change Records
Changed Functional Variables
```

Use exact values for now.

Next, add a **100% stacked bar chart**:

```text
Axis:
FactReleaseComparison[Functional_Change_Status]

Values:
_Measures[Total Applications]
```

Then add a **clustered bar chart**:

```text
Y-axis:
FactReconciliationDetail[Variable]

X-axis:
_Measures[Variable Change Records]
```

Sort descending.

Once those are placed, send a screenshot. Then we will add the one segmentation visual and the executive narrative, and Page 1 will be structurally complete.
<!-- END_MESSAGE C064-M00069 -->


---

<a id="c064-m00071"></a>

### C064-M00071

**Andrew** · 2026-07-19T16:17:06.707000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00071 -->
the 100% stacked bar chart seems hard to follow - otherwise this is done
<!-- END_MESSAGE C064-M00071 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00072"></a>

### C064-M00072

**ChatGPT** · 2026-07-19T16:17:08.181918-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00072 -->
I agree. In fact, this is the first place where I think we should intentionally deviate from the original plan.

The **100% stacked bar chart is technically correct, but it tells the wrong story.**

An executive doesn't care that there are two categories. They care that:

> **42.65% of the portfolio changed.**

That's the headline.

---

# Replace it

Delete the 100% stacked bar.

Instead insert a **Donut Chart**.

### Legend

```text
Functional_Change_Status
```

### Values

```text
Total Applications
```

Turn on:

- Category labels
- Percent of total
- Data labels

This will immediately show

```
Affected     42.65%
Unaffected   57.35%
```

That is much easier to understand.

---

# Even better...

I think we can tell an executive story in one glance.

Across the top:

```
50,000
Applications
```

```
21,326
Affected
```

```
42.65%
Change Rate
```

```
58,382
Variable Changes
```

```
7
Variables Updated
```

Then underneath:

LEFT

Donut

```
Portfolio Impact
```

RIGHT

Variable Change Counts

Exactly what you already built.

Now an executive immediately understands

> How much changed?

↓

> What changed?

---

# One thing I'd also change

Move

```
58,382
Variable Change Records
```

to the top row.

I actually think this KPI is *more* interesting than Total Applications.

Suggested top row:

| KPI | Reason |
|------|--------|
| 50,000 Applications | Portfolio size |
| 21,326 Changed | Impact |
| 42.65% | Rate |
| 58,382 Variable Changes | Work performed |
| 7 Variables Updated | Scope |

That tells the whole release story in five numbers.

---

# The variable chart

This one is already good.

I would make only two tweaks.

### 1.

Rename

```
Variable Change Records by Variable
```

to

```
Functional Changes by Variable
```

Much more executive friendly.

---

### 2.

Use friendly names.

Instead of

```
PAYMENT_TO_INCOME_RATIO
```

display

```
Payment-to-Income Ratio
```

Instead of

```
EXPECTED_LOSS_AMOUNT
```

display

```
Expected Loss
```

Instead of

```
MULT_PTI
```

display

```
PTI Multiplier
```

These are small changes, but they make the report feel much more polished.

---

# I think we should stop adding visuals for a few minutes

This page is about **80% complete**.

The remaining 20% isn't more charts—it's presentation.

I suggest we spend the next 30–45 minutes making this one page look like something that could genuinely be shown in a release review.

That includes:

- meaningful title
- executive subtitle
- concise narrative
- consistent spacing
- friendly field names
- polished formatting

A recruiter or hiring manager will judge the report within the first 10–15 seconds. Good presentation multiplies the impact of the solid analytics you've already built.

## My suggested page title

**Module 1 V2.0 Release Validation Summary**

## Subtitle

**Comparison of 50,000 matched synthetic applications between Module 1 V1.0 and V2.0, highlighting application impact, functional changes, and release validation metrics.**

That immediately tells the viewer what they're looking at without requiring any explanation.
<!-- END_MESSAGE C064-M00072 -->


---

<a id="c064-m00073"></a>

### C064-M00073

**Andrew** · 2026-07-19T16:41:34.133000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00073 -->
advice on visual plus how to change & axis data value labels
<!-- END_MESSAGE C064-M00073 -->


**Attachments in export:** `image(122).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00074"></a>

### C064-M00074

**ChatGPT** · 2026-07-19T16:41:35.633587-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00074 -->
This is coming together nicely. More importantly, it already looks like something that belongs in a release review instead of a homework assignment.

I have a few recommendations, ordered by impact.

---

# Overall Rating

**Analytics:** 10/10

**Data model:** 10/10

**Visual design:** 7.5/10

**Executive storytelling:** 7/10

The analytics are already excellent. We just need to elevate the presentation.

---

# 1. The KPI cards

These are good, but they don't look like KPI cards yet.

The blue background is competing with the charts.

I'd actually recommend **white cards** with:

- thin gray border
- subtle shadow
- large black number
- smaller gray subtitle

Much more "Power BI enterprise dashboard."

Example:

```
50,000

Total Applications
```

instead of the large blue blocks.

---

# 2. Donut chart

I like the donut much better.

I would make two small improvements.

### Change title

Instead of

```
Total Applications by Functional_Change_Status
```

I'd use

```
Application Impact
```

Much shorter.

---

### Legend

Instead of

```
Functional_Change_Status
```

rename the field (or use a friendly column) so the legend simply says

```
Status
```

with

```
Affected
Unaffected
```

---

# 3. Variable chart

This is where I'd spend most of our polish.

Instead of

```
Variable Change Records by Variable
```

use

```
Functional Changes by Variable
```

---

## Friendly names

Right now you're showing SQL variable names.

Executives hate those.

Instead use

| Current | Better |
|----------|---------|
| MONTHLY_PAYMENT_PROXY | Monthly Payment |
| PAYMENT_TO_INCOME_RATIO | Payment-to-Income Ratio |
| EXPECTED_LOSS_AMOUNT | Expected Loss |
| ESTIMATED_PD | Estimated PD |
| REQUESTED_AMOUNT | Requested Amount |
| AMOUNT_TO_INCOME_RATIO | Amount-to-Income Ratio |
| MULT_PTI | PTI Multiplier |

That alone will make the report feel much more polished.

---

# 4. Biggest recommendation

I'd actually add one sentence underneath the KPIs.

Something like

> **21,326 of 50,000 applications (42.65%) experienced one or more functional changes between Module 1 V1.0 and V2.0. Most changes were concentrated in payment affordability, estimated risk, and mortgage realism enhancements.**

That's the story.

Without it, viewers have to interpret the charts themselves.

---

# How to change axis labels (friendly names)

There are several ways.

## Option A (what I'd recommend)

Create a small lookup table later.

```
Variable                     Display Name

MONTHLY_PAYMENT_PROXY        Monthly Payment
PAYMENT_TO_INCOME_RATIO      Payment-to-Income Ratio
...
```

Then use Display Name everywhere.

This scales beautifully.

---

## Option B (fastest tonight)

In Power Query:

Duplicate

```
Variable
```

Rename it

```
Variable_Display
```

Then Replace Values:

```
MONTHLY_PAYMENT_PROXY
↓

Monthly Payment
```

etc.

Use

```
Variable_Display
```

on the chart.

For tonight, I'd absolutely choose Option B.

---

# How to change data labels

Select the chart.

Then

```
Format visual
```

↓

```
Data labels
```

Turn ON.

You can configure:

- Position
- Display units
- Decimal places
- Text size

For this chart I'd use

```
Display units = None

Decimal places = 0

Position = Outside end
```

---

# Hide the X-axis

Since every value is already labeled, you don't really need

```
0K
5K
10K
15K
20K
```

I would either:

- make them light gray

or

- hide them completely

This puts all the attention on the bars.

---

# My biggest design suggestion

I actually think the report is missing one thing:

A **headline**.

Something like

# **Module 1 V2.0 Release Validation Summary**

Underneath:

> **Comparison of 50,000 matched synthetic applications between Module 1 V1.0 and V2.0, highlighting application impact and functional release changes.**

That transforms it from "a Power BI page" into "a presentation."

---

## I think we're very close

If I were interviewing someone and they opened **this dashboard**, then clicked into an Application Explorer page showing a single application's V1 vs. V2 changes, I'd be impressed.

We're no longer trying to prove you know Power BI basics—we're demonstrating that you can build an executive-facing analytical product. That's exactly the kind of artifact that can strengthen your discussion with the recruiter and give you concrete examples to reference in tomorrow's interview.
<!-- END_MESSAGE C064-M00074 -->


---

<a id="c064-m00075"></a>

### C064-M00075

**Andrew** · 2026-07-19T17:00:51.715000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00075 -->
i'm fine with Y axis labels how they are for now. how is this visually now? 
<!-- END_MESSAGE C064-M00075 -->


**Attachments in export:** `image(123).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00076"></a>

### C064-M00076

**ChatGPT** · 2026-07-19T17:00:53.410559-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00076 -->
This is a **significant improvement**. If I compare it to where we started two hours ago, I'd say:

- **Analytics quality:** 10/10
- **Visual quality:** 8.8/10
- **Portfolio readiness:** 9.2/10

It now looks like a dashboard that someone actually built to communicate results rather than simply satisfy a technical requirement.

## What's working well

### The KPI strip

This is much cleaner.

The white cards with shadows draw attention to the numbers instead of the background color. They're easy to scan left-to-right, which is exactly how executives consume dashboards.

### The donut chart

This is a big improvement over the 100% stacked bar. The visual immediately answers:

> "How much of the portfolio changed?"

without requiring the viewer to interpret percentages.

### The variable chart

The ordering is intuitive. The story is obvious:

1. Payment logic
2. PTI
3. Expected Loss
4. PD
5. Requested Amount
6. Amount-to-Income
7. PTI Multiplier

That's actually a nice narrative because it mirrors the architecture of the engine.

---

# What I would change before publishing

These are all fairly quick changes.

## 1. Add a page title

Right now the page starts with KPI cards.

I'd add a title above them.

Example:

# **Module 1 V2.0 Release Validation Summary**

Then below it in smaller gray text:

> **Comparison of 50,000 matched synthetic applications across Module 1 V1.0 and V2.0, highlighting application impact and functional release changes.**

That gives viewers immediate context.

---

## 2. Rename the variable chart

Current:

> Variable Change Records by Variable

I'd shorten it to:

> **Functional Changes by Variable**

It's cleaner and reads more naturally.

---

## 3. Remove the legend from the donut

The labels already say:

- Affected
- Unaffected

The legend repeats the same information and consumes valuable space.

Removing it lets you enlarge the donut.

---

## 4. Increase the donut size

After removing the legend, increase the donut by roughly 15–20%.

It becomes the dominant visual on the page.

---

## 5. Balance the two lower visuals

Right now:

- Donut occupies about **45%**
- Bar chart about **55%**

I'd make them essentially **50/50**.

It gives the page a cleaner visual rhythm.

---

# One enhancement I think is worth adding tonight

This is the only additional visual I'd recommend before publishing.

## Product Impact

Under the KPI row, add a small horizontal bar chart:

**Title**

> **Affected Applications by Product**

Axis:

```text
Product_Type
```

Value:

```text
Affected Applications
```

This immediately answers:

> "Which lending products were most affected?"

That adds another executive insight without much effort.

---

# Something to avoid tonight

Don't spend time trying to make this look like a marketing website.

This is an **analytics artifact**.

A reviewer should think:

> "This looks like something used in a model validation or release review."

not

> "This looks flashy."

You're already much closer to the first.

---

# Thinking about tomorrow's interview

This dashboard also gives you a very nice story to tell if you're asked:

> "Have you used Power BI?"

A truthful answer would be:

> "Yes. As part of my Enterprise Credit Decisioning Strategy Simulator, I built a Power BI release-validation dashboard over two fact tables, using Power Query for transformation, DAX measures for KPIs, semantic modeling, and interactive visuals to reconcile 50,000 matched applications across two releases. The dashboard highlights release impact, variable-level changes, and application-level reconciliation."

That's a strong answer because it's grounded in something you can actually demonstrate.

## My recommendation for tonight

I'd make the following your minimum publishable scope:

- ✅ Finish this Executive Summary page (including title/subtitle and the small layout tweaks above).
- ✅ Build the **Application Explorer** page. That's the differentiator—it shows this isn't just a collection of charts but a true analytical application.
- ⏸ Skip additional specialty pages (Mortgage, PD, etc.) until after the interview.

If you have those two polished pages plus the QA page, you'll have a portfolio piece that supports both your resume update and tomorrow's conversation with the Wells Fargo recruiter.
<!-- END_MESSAGE C064-M00076 -->


---

<a id="c064-m00078"></a>

### C064-M00078

**Andrew** · 2026-07-19T17:20:18.319000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00078 -->
*No text body is present in the export. This message may contain an image or attachment.*
<!-- END_MESSAGE C064-M00078 -->


**Attachments in export:** `image(123).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00079"></a>

### C064-M00079

**ChatGPT** · 2026-07-19T17:20:19.813307-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00079 -->
This is now **portfolio quality**. If you told me this was the first page of an internal Wells Fargo model validation dashboard, I would believe it.

I'd rate it **9.4/10** in its current state.

Now let's make it a **9.8/10** with about 20 minutes of work.

---

# What I really like

### 1. The KPI strip

This is exactly the right density.

Someone can scan it in about three seconds.

```
50,000
↓

21,326

↓

42.65%

↓

58,382

↓

7
```

That's a complete executive summary.

---

### 2. The page title

Excellent.

Exactly the right amount of information.

---

### 3. The subtitle

Also good.

I'd make one tiny wording change.

Current:

> Comparison of 50,000 matched synthetic applications across Module 1 V1.0 and V2.0, highlighting application impact and functional release changes.

I'd shorten it slightly:

> **Comparison of 50,000 matched synthetic applications between Module 1 V1.0 and V2.0, highlighting application impact and functional release changes.**

"Between" reads a little more naturally than "across" here.

---

# Things I'd improve

## 1. Remove the donut legend

The legend duplicates information already displayed by the labels.

Removing it lets you enlarge the donut another 10–15%.

That's a free improvement.

---

## 2. Add one executive insight

Right now the dashboard shows data.

Let's help the viewer interpret it.

I'd add a small text box between the KPI row and the visuals.

Something like:

> **Release Summary:** Module 1 V2.0 affected **21,326 of 50,000** matched applications (**42.65%**) across **7 functional variables**. The largest impacts were concentrated in **Monthly Payment**, **Payment-to-Income Ratio**, **Expected Loss**, and **Estimated PD**, reflecting targeted affordability and risk-model enhancements.

That's only about 35 words, but it dramatically increases executive readability.

---

## 3. The bar chart

I think this is the one place where we should invest another few minutes.

Instead of SQL names:

```
MONTHLY_PAYMENT_PROXY
```

I'd strongly recommend:

```
Monthly Payment
```

Likewise:

```
Payment-to-Income Ratio

Expected Loss

Estimated PD

Requested Amount

Amount-to-Income Ratio

PTI Multiplier
```

That single change makes the report feel much more polished.

---

# The only thing I think is missing

This page answers:

> **How much changed?**

It does **not** yet answer:

> **Where did it change?**

That's why I think the second page should be the Application Explorer.

---

# Application Explorer (Page 2)

This page is what will make people remember the project.

Instead of another dashboard page, imagine something like this:

---

## Left side

Application search

```
Application_ID

APP-00012345
```

---

## Center

Borrower summary

```
Product

Mortgage

Score Band

Prime

Credit Score

718

Annual Income

$143,000
```

---

## Right

Release outcome

```
Changed Fields

5

Status

Affected
```

---

## Bottom

| Variable | V1 | V2 | Delta |
|----------|----|----|-------|
| Monthly Payment | ... | ... | ... |
| PTI | ... | ... | ... |
| Expected Loss | ... | ... | ... |

Now you've gone beyond showing metrics—you've demonstrated drill-through, reconciliation, and traceability.

---

# Thinking about tomorrow

If I were the hiring manager and you shared this during the interview, my questions would naturally become:

- "How did you model the data?"
- "How did you validate the measures?"
- "Can you drill into one application?"
- "How did you decide which fields changed?"

Those are excellent questions because they let you talk about your actual work.

---

# My recommendation

I would **stop refining Page 1** after the minor tweaks above.

It is already strong enough.

Your time is much better spent building **one excellent Application Explorer page** than squeezing another 2–3% of polish out of this one.

That second page will differentiate you far more than another chart or another KPI ever could. I think it also gives you a concrete artifact to mention when updating your resume and when speaking with the Wells Fargo recruiter before tomorrow's interview.
<!-- END_MESSAGE C064-M00079 -->


---

<a id="c064-m00080"></a>

### C064-M00080

**Andrew** · 2026-07-19T17:26:35.815000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00080 -->
final for this visual for now. we need to move on to other visuals.
<!-- END_MESSAGE C064-M00080 -->


**Attachments in export:** `image(123).png`. See [attachment inventory](../../Indexes/Attachment_Inventory.csv) for availability.

---

<a id="c064-m00081"></a>

### C064-M00081

**ChatGPT** · 2026-07-19T17:26:37.332344-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00081 -->
I think this is the right call. **Freeze this page.**

For a V1 that needs to support tomorrow's interview, I would not spend another minute polishing it.

**Final assessment: 9.5/10**

The only things I'd change later are cosmetic (friendly variable names, custom theme, maybe icons). None of those will materially improve your interview tomorrow.

---

# Next Priority: Application Explorer

This is the page that separates your work from a typical Power BI exercise.

Right now you've shown:

> **What changed?**

Now we need to show:

> **Exactly how one application changed.**

That's much more memorable.

---

# Page 2 Layout

Rename the new page:

```text
02 | Application Explorer
```

We'll build it in four sections.

```
--------------------------------------------------------------
                APPLICATION EXPLORER
--------------------------------------------------------------

Application Search         Borrower Summary

--------------------------------------------------------------

Changed Fields KPI         Product / Score / Status

--------------------------------------------------------------

                 V1 vs V2 Comparison Table

--------------------------------------------------------------
```

---

# Step 1 — Application slicer

Insert a **Slicer**.

Use:

```text
FactReleaseComparison[Application_ID]
```

Immediately change the slicer to a **Dropdown**.

Turn on:

```text
Search
```

This gives interviewers the ability to type:

```
APP-00012345
```

and immediately drill into a borrower.

---

# Step 2 — Summary cards

Across the top create four cards.

## Product

Use:

```text
Product_Type
```

Card.

---

## Score Band

Use

```text
Score_Band
```

Card.

---

## Credit Score

Use

```text
Credit_Score
```

Card.

---

## Changed Fields

Instead of a measure, use

```text
Changed_Field_Count
```

When one application is selected, the card will show:

```
0

or

2

or

5

etc.
```

Very intuitive.

---

# Step 3 — Status card

Another card:

```text
Functional_Change_Status
```

Should display

```
Affected

or

Unaffected
```

---

# Step 4 — The most important visual

Insert a **Table**.

Use fields from **FactReconciliationDetail**:

```
Variable

Value_V1

Value_V2

Delta_V2_Minus_V1

Relative_Delta
```

Because of the relationship you built, selecting one application on the slicer will automatically filter the table to only the changed variables for that application.

This is where the relationship work pays off.

---

# Step 5 — Add two KPI cards

Using FactReleaseComparison:

```
Requested_Amount_V1

Requested_Amount_V2
```

These let people immediately see if requested amount changed.

---

# Why this page matters

Imagine this interview conversation:

Interviewer:

> "How do I know the dashboard isn't just showing aggregates?"

You respond:

*"Let me search for one application..."*

Type

```
APP-00000037
```

Immediately:

- Product changes
- Score band
- Changed field count
- Status
- Every changed variable
- V1 value
- V2 value
- Delta

That's a much stronger demonstration than another dashboard page.

---

# After that

Once the Application Explorer works, I think we should stop building new functionality.

Instead we'll spend the remaining time on:

1. Final cleanup.
2. Publish the PBIX.
3. Capture portfolio screenshots.
4. Update your resume with an accurate Power BI bullet.
5. Draft the recruiter email for tomorrow.

That gives you a realistic, polished deliverable tonight while keeping the scope under control.
<!-- END_MESSAGE C064-M00081 -->


---

<a id="c064-m00082"></a>

### C064-M00082

**Andrew** · 2026-07-19T17:29:28.470000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00082 -->
Also, before we move on, I think that initial 00 | Model QA doesn't add value - the data is basically the same that we see in 01 | Executive Summary. unless you have other ideas for it later.  thoughts?
<!-- END_MESSAGE C064-M00082 -->


---

<a id="c064-m00083"></a>

### C064-M00083

**ChatGPT** · 2026-07-19T17:29:29.784843-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00083 -->
I actually agree, and I was going to bring this up after seeing the Executive Summary.

The **00 | Model QA** page was valuable during development because it let us validate the semantic model incrementally. But for a portfolio project and tomorrow's interview, it's largely redundant.

I'd think about it this way:

- **Development artifact** → helped us prove the model was correct.
- **Portfolio artifact** → should communicate insight, not just correctness.

## Option 1 (my recommendation): Remove it from the published version

This is what I'd do.

Keep the page in the PBIX while you're building if you find it useful, but **hide it before publishing**.

Power BI lets you right-click the page tab and choose **Hide page**.

That way:
- You still have it for future development.
- Interviewers and GitHub viewers start immediately on the Executive Summary.

---

## Option 2: Repurpose it into a Technical Appendix

If you want a second "technical" page, don't duplicate the Executive Summary. Instead make it something like:

### 99 | Technical Appendix

Include things like:

- Data model diagram (two fact tables + relationship)
- Validation methodology
- Row counts
- Relationship cardinality
- Data refresh assumptions
- Source inventory (V1 raw, V2 raw, reconciliation detail, reconciliation summary)

That page would appeal to analytics managers and model governance reviewers without repeating KPIs.

---

## What I would **not** do

I would not leave a page that simply repeats:

- 50,000
- 21,326
- 42.65%
- 58,382

The Executive Summary already tells that story much better.

---

# Here's the dashboard I'd publish tomorrow

1. **Executive Summary** *(completed)*
2. **Application Explorer** *(we're building now)*
3. **Technical Appendix** *(optional if time permits)*

That's enough.

Remember the goal isn't to demonstrate every Power BI visual—it's to demonstrate that you can build an analytical application around a governed data model.

---

## One more strategic thought

Given your audience tomorrow (Wells Fargo Auto Analytics), I would rather have:

- **2 excellent pages**

than

- **6 average pages**.

The Executive Summary establishes the business impact.

The Application Explorer demonstrates traceability, drill-down, reconciliation, and governed analytics.

Together, those pages align very well with your broader portfolio theme of transparent, audit-ready decision systems.

So my recommendation is:

- **Hide or delete `00 | Model QA`** from the published version.
- Focus the remaining time on making **Application Explorer** excellent.
- If we finish early, add a **Technical Appendix** rather than resurrecting the QA page. I think that's a much stronger narrative for tomorrow's interview.
<!-- END_MESSAGE C064-M00083 -->


---

<a id="c064-m00085"></a>

### C064-M00085

**Andrew** · 2026-07-19T17:41:33.585000-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00085 -->
let's work on the application explorer (which I would hope would focus on the workstream themes and how the changes align to those workstream changes) and decide on the technical appendix later.
<!-- END_MESSAGE C064-M00085 -->


---

<a id="c064-m00086"></a>

### C064-M00086

**ChatGPT** · 2026-07-19T17:41:34.913055-04:00 · active path

<!-- BEGIN_MESSAGE C064-M00086 -->
I like that direction much better.

In fact, I'd make one fairly major change to what I suggested earlier.

## Don't make Page 2 a generic "Application Explorer."

Make it a **Release Impact Explorer**.

That aligns directly with your V2.0 workstreams and tells a much stronger story.

The question the page answers becomes:

> **"Why did this application change between V1.0 and V2.0?"**

That's much more interesting than simply displaying before-and-after values.

---

# Proposed Page 2

## Title

**Application Release Impact Explorer**

Subtitle:

> **Trace individual application changes across Module 1 V2.0 workstreams, highlighting affordability, mortgage realism, and risk-model refinements.**

---

# Layout

```
=========================================================
           Application Release Impact Explorer
=========================================================

Application Search        Product        Score Band

Credit Score              Status         Changed Fields

---------------------------------------------------------

V1 Profile                V2 Profile

---------------------------------------------------------

Changed Variables (table)

---------------------------------------------------------

Workstream Interpretation
```

---

# The key improvement

Instead of merely showing:

```
Monthly Payment

895.87

↓

866.23
```

we explain **why**.

## Workstream Interpretation panel

Imagine a text box like:

---

### Workstream Impact Summary

**Application:** APP-00000037

**Workstreams affecting this application**

✅ **Workstream A — Mortgage Realism**

- Requested amount moderated through affordability-aware mortgage logic.
- Monthly payment decreased.
- Payment-to-Income Ratio improved.

✅ **Workstream B — Estimated PD Dispersion**

- Estimated PD adjusted through revised saturation behavior.
- Expected Loss recalculated accordingly.

No impact detected from:

- Scenario Framework
- Revolving Payment Sensitivity

---

Now you're connecting **technical changes** back to the business design.

That's exactly what your BRD and Validation Summary emphasize. fileciteturn0file1L39-L50 fileciteturn0file4L1-L15

---

# We can automate most of this

We already have everything we need.

For example:

If

```
Requested Amount changed
Monthly Payment changed
PTI changed
```

→ show

> **Mortgage Realism**

If

```
Estimated PD changed
Expected Loss changed
```

→ show

> **Estimated PD Dispersion**

If

```
Mult PTI changed
```

→ show

> **Affordability Translation**

Notice we're not claiming causality beyond what the release actually changed—we're grouping changes according to the documented workstream themes.

---

# The V1 / V2 comparison table

I'd simplify it.

Instead of:

| Variable | V1 | V2 | Delta | Relative Delta |

I'd use:

| Variable | V1 | V2 | Δ |
|----------|---:|---:|---:|

and conditionally format the Δ column:

🟢 Improvement

🔴 Increase

⚪ No change

That reads much faster.

---

# This becomes a story

Executive Summary

↓

> **42.65% of applications changed.**

Application Explorer

↓

> **Here's one application. Here's exactly what changed. Here's why it changed.**

That progression is much more compelling than simply drilling into numbers.

---

# One recommendation

I would **not** expose every single V2 diagnostic field (mortgage candidate amount, damping factor, saturation zone, etc.) on this page.

Those are fantastic technically, but they add cognitive load for a first-time viewer.

Instead:

- Show the **business outcome** first (changed variables and workstream interpretation).
- Keep a collapsible or later **Technical Appendix** where those diagnostics can shine.

That gives you a clean executive experience while still preserving the depth for technical reviewers.

## I think this is now our finish line

By tomorrow morning, I'd aim for:

- ✅ Executive Summary (essentially complete)
- ✅ Release Impact Explorer (focused on workstream interpretation and application-level traceability)
- ⏳ Technical Appendix only if time permits

That scope aligns well with your BRD, the validation narrative, and tomorrow's Wells Fargo interview without overextending into features that won't materially improve the conversation.
<!-- END_MESSAGE C064-M00086 -->


---

[Conversation guide](README.md) · [All messages](MESSAGE_INDEX.md) · [Archive home](../../README.md) · [Previous](Part_01.md) · [Next](Part_03.md)
